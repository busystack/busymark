import 'dart:async';
import 'dart:convert';

import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_clipboard_fragment.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_clipboard_html.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_document_controller.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_inline_controller.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/platform/rich_clipboard_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;

const _source =
    '# Issues\n\n**When** selecting all, keep *formatting*.\n\n- [ ] First task\n- [x] Second task\n';
const _parser = MarkdownParser();

WysiwygClipboardFragment _fragment(
  String source, {
  String path = '/source/topic.md',
}) {
  final document = _parser
      .parse(
        filePath: path,
        source: source,
        mode: MarkdownMode.writersideMarkdown,
      )
      .busyDocument;
  return WysiwygClipboardFragment(
    mode: document.mode,
    sourcePath: path,
    blocks: [
      for (final block in document.blocks)
        BusyWysiwygStyledBlock(
          kind: block.kind,
          text: block.plainText,
          ranges: busyInlineStyleRanges(block.inlines),
          attributes: block.attributes,
          completeBlock: busyMarkWysiwygImmutableBlockSnapshot(block),
        ),
    ],
  );
}

String _insert(
  WysiwygClipboardFragment fragment, {
  String source = 'Target\n',
}) {
  final target = _parser
      .parse(filePath: '/destination/topic.md', source: source)
      .busyDocument;
  final controller = BusyMarkWysiwygDocumentController(document: target);
  final result = controller.insertStyledBlocksAtSelection(
    blockId: target.blocks.first.id,
    selectionStart: 0,
    selectionEnd: target.blocks.first.plainText.length,
    blocks: fragment.blocks,
  );
  expect(result, isNotNull);
  final output = controller.markdown;
  controller.dispose();
  return output;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'native fragment preserves formatting and structured blocks through JSON',
    () {
      const source =
          '$_source\n- Parent\n  - **Child**\n\n| A | B |\n| --- | --- |\n| one | **two** |\n\n```dart\nfinal x = 1;\n```\n';
      final decoded = WysiwygClipboardFragment.decode(
        _fragment(source).encode(),
      )!;
      final output = _insert(decoded);
      expect(output, contains('# Issues'));
      expect(output, contains('**When**'));
      expect(output, contains('- [ ] First task'));
      expect(output, contains('- [x] Second task'));
      expect(output, contains('**Child**'));
      expect(output, contains('| one | **two** |'));
      expect(output, contains('```dart\nfinal x = 1;\n```'));
    },
  );

  test(
    'fragment rejects invalid versions, ranges, kinds, and excessive nesting',
    () {
      for (final change in <void Function(Map<String, dynamic>)>[
        (map) => map['version'] = 99,
        (map) => map['mode'] = 'nonexistent',
        (map) => map['blocks'][0]['kind'] = 'nonexistent',
        (map) => map['blocks'][0]['ranges'] = [
          {'start': -1, 'end': 500, 'kind': 'strong'},
        ],
        (map) => map['blocks'][0]['completeBlock']['inlines'] = null,
      ]) {
        final map =
            jsonDecode(_fragment(_source).encode()) as Map<String, dynamic>;
        change(map);
        expect(WysiwygClipboardFragment.decode(jsonEncode(map)), isNull);
      }
      expect(
        WysiwygClipboardFragment.decode('${'[' * 200}0${']' * 200}'),
        isNull,
      );
      expect(WysiwygClipboardFragment.decode('not json'), isNull);
    },
  );

  test('relative links are rebased for another document', () {
    final fragment = _fragment('[Guide](guide.md#section)\n');
    expect(
      _insert(fragment.rebase('/destination/topic.md')),
      contains('../source/guide.md#section'),
    );
    expect(fragment.rebase('/source/topic.md'), same(fragment));
  });

  test('inline images retain their source media path between projects', () {
    final original = _fragment('Before ![Alt](diagram.png) after\n');
    final fragment = WysiwygClipboardFragment(
      blocks: original.blocks,
      mode: original.mode,
      sourcePath: original.sourcePath,
      mediaPaths: const {'diagram.png': '/source/images/diagram.png'},
    );
    final decoded = WysiwygClipboardFragment.decode(fragment.encode())!;
    expect(
      _insert(decoded.rebase('/destination/topic.md')),
      contains('![Alt](/source/images/diagram.png)'),
    );
    expect(
      const WysiwygClipboardHtml().encode(decoded),
      contains('src="file:///source/images/diagram.png"'),
    );
  });

  test('Writerside structure survives the fragment and insertion', () {
    const source =
        '<note><p>Keep <b>this</b> note.</p></note>\n\n'
        '<tabs><tab title="First"><p>Tab content</p></tab></tabs>\n';
    final decoded = WysiwygClipboardFragment.decode(
      _fragment(source).encode(),
    )!;
    final output = _insert(decoded);
    expect(output, contains('<note>'));
    expect(output, contains('this'));
    expect(output, contains('<tabs>'));
    expect(output, contains('title="First"'));
    expect(output, contains('Tab content'));
  });

  test(
    'styled table-cell insertion preserves emphasis and table structure',
    () {
      final document = _parser
          .parse(
            filePath: '/destination/topic.md',
            source: '| A | B |\n| --- | --- |\n| before after | keep |\n',
          )
          .busyDocument;
      final table = document.blocks.single;
      final cell = table.children.last.children.first;
      final controller = BusyMarkWysiwygDocumentController(document: document);
      final offset = controller.insertStyledInlinesInTableCell(
        tableBlockId: table.id,
        cellId: cell.id,
        selectionStart: 7,
        selectionEnd: 7,
        blocks: _fragment('**Bold**\n\n*Italic*\n').blocks,
      );
      expect(offset, 18);
      expect(
        controller.markdown,
        contains('| before **Bold** *Italic*after | keep |'),
      );
      expect(controller.document.blocks.single.kind, BusyBlockKind.table);
      controller.dispose();
    },
  );

  test(
    'clipboard service serializes writes and reads the latest result',
    () async {
      const channel = MethodChannel('test/rich_clipboard_order');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final gate = Completer<void>();
      final started = Completer<void>();
      final writes = <String>[];
      var data = <String, dynamic>{};
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'write') {
          final value = Map<String, dynamic>.from(call.arguments as Map);
          writes.add(value['text'] as String);
          if (writes.length == 1) {
            started.complete();
            await gate.future;
          }
          data = value;
          return true;
        }
        return data;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      final service = RichClipboardService(channel: channel);
      final first = service.write(const RichClipboardData(text: 'first'));
      await started.future;
      final second = service.write(
        const RichClipboardData(text: 'second', html: '<b>second</b>'),
      );
      final read = service.read();
      expect(writes, ['first']);
      gate.complete();
      expect(await first, isTrue);
      expect(await second, isTrue);
      expect((await read).html, '<b>second</b>');
      expect(writes, ['first', 'second']);
    },
  );

  test('clipboard HTML carries headings, emphasis, tasks, tables, and code', () {
    const source =
        '$_source\n| A | B |\n| --- | --- |\n| one | **two** |\n\n```dart\nx < 3\n```\n';
    final encoded = const WysiwygClipboardHtml().encode(_fragment(source));
    final dom = html.parse(encoded);
    expect(dom.querySelector('h1')!.text, 'Issues');
    expect(dom.querySelector('strong')!.text, 'When');
    expect(dom.querySelector('em')!.text, 'formatting');
    expect(dom.querySelectorAll('li').map((e) => e.text), [
      '☐ First task',
      '☑ Second task',
    ]);
    expect(dom.querySelectorAll('table'), hasLength(1));
    expect(dom.querySelector('pre code')!.text, 'x < 3');
    expect(dom.querySelectorAll('script,input'), isEmpty);
    final decoded = const WysiwygClipboardHtml().decode(
      encoded,
      mode: MarkdownMode.writersideMarkdown,
    )!;
    expect(_insert(decoded), contains('- [x] Second task'));
  });

  test('clipboard fragment serializes its selected structure as Markdown', () {
    final markdown = _fragment(_source).markdown;
    expect(markdown, contains('# Issues'));
    expect(markdown, contains('**When**'));
    expect(markdown, contains('- [ ] First task'));
    expect(markdown, contains('- [x] Second task'));
  });

  test('HTML normalization preserves supported CSS and checkbox state safely', () {
    const source =
        '<html><head><style>p{color:red}</style></head><body>'
        '<h1>Title</h1><p><span style="font-weight:700;font-style:italic;text-decoration:underline">Mixed</span>'
        '<a href="javascript:alert(1)" onclick="alert(2)">label</a><script>bad()</script></p>'
        '<ul><li><input type="checkbox" checked>Done</li></ul></body></html>';
    final decoded = const WysiwygClipboardHtml().decode(
      source,
      mode: MarkdownMode.gfm,
    )!;
    final output = _insert(decoded);
    expect(output, contains('# Title'));
    expect(output, contains('Mixed'));
    expect(output, contains('- [x] Done'));
    expect(output, isNot(contains('javascript')));
    expect(output, isNot(contains('bad()')));
    final ranges = decoded.blocks
        .expand((block) => block.ranges)
        .map((range) => range.kind)
        .toSet();
    expect(
      ranges,
      containsAll([
        BusyInlineKind.strong,
        BusyInlineKind.emphasis,
        BusyInlineKind.underline,
      ]),
    );
  });

  group('Editor clipboard', () {
    late Map<String, dynamic> systemData;
    late Completer<void>? readGate;
    late Completer<void>? writeGate;
    late bool failWrite;
    const channel = MethodChannel(richClipboardChannelName);
    setUp(() {
      systemData = {};
      readGate = null;
      writeGate = null;
      failWrite = false;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'write') {
          await writeGate?.future;
          if (failWrite) throw PlatformException(code: 'clipboard.unavailable');
          systemData = Map<String, dynamic>.from(call.arguments as Map);
          return true;
        }
        if (call.method == 'read') {
          await readGate?.future;
          return Map<String, dynamic>.from(systemData);
        }
        return null;
      });
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          systemData = Map<String, dynamic>.from(call.arguments as Map);
        }
        if (call.method == 'Clipboard.getData') {
          return {'text': systemData['text']};
        }
        if (call.method == 'Clipboard.hasStrings') {
          return {'value': systemData['text'] != null};
        }
        return null;
      });
    });
    tearDown(() {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, null);
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    });

    Future<void> key(
      WidgetTester tester,
      LogicalKeyboardKey key, {
      bool shift = false,
    }) async {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(key);
      if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
    }

    Future<void> mount(
      WidgetTester tester,
      String id,
      String source,
      ValueChanged<String> changed,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: BusyMarkWysiwygEditor(
              key: ValueKey(id),
              clipboardService: RichClipboardService(),
              document: _parser
                  .parse(
                    filePath: '/$id.md',
                    source: source,
                    mode: MarkdownMode.writersideMarkdown,
                  )
                  .busyDocument,
              onSourceChanged: (_, value) => changed(value),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(find.byType(TextField).first);
      field.focusNode!.requestFocus();
      field.controller!.selection = const TextSelection.collapsed(offset: 0);
      await tester.pump();
    }

    Future<void> copyAll(WidgetTester tester, {String source = _source}) async {
      await mount(tester, 'origin', source, (_) {});
      await key(tester, LogicalKeyboardKey.keyA);
      await key(tester, LogicalKeyboardKey.keyA);
      await key(tester, LogicalKeyboardKey.keyC);
    }

    testWidgets('fresh Editor restores system clipboard formatting and undo', (
      tester,
    ) async {
      await copyAll(tester);
      expect(systemData.keys, containsAll(['text', 'html', 'fragment']));
      expect(systemData['text'], contains('[ ] First task'));
      var result = '';
      await mount(tester, 'destination', 'Target\n', (value) => result = value);
      await key(tester, LogicalKeyboardKey.keyA);
      await key(tester, LogicalKeyboardKey.keyV);
      expect(result, contains('# Issues'));
      expect(result, contains('**When**'));
      expect(result, contains('- [x] Second task'));
      await key(tester, LogicalKeyboardKey.keyZ);
      expect(result, 'Target\n');
      await key(tester, LogicalKeyboardKey.keyZ, shift: true);
      expect(result, contains('**When**'));
    });

    testWidgets('copy all does not duplicate nested list children', (
      tester,
    ) async {
      await copyAll(
        tester,
        source: 'Before\n\n- Parent\n  - **Child**\n\nAfter\n',
      );
      var result = '';
      await mount(tester, 'destination', 'Target\n', (value) => result = value);
      await key(tester, LogicalKeyboardKey.keyA);
      await key(tester, LogicalKeyboardKey.keyV);
      expect(RegExp('Child').allMatches(result), hasLength(1));
      expect(result, contains('  - **Child**'));
    });

    testWidgets('whole-document copy preserves a structured blockquote', (
      tester,
    ) async {
      await copyAll(
        tester,
        source: 'Before\n\n> First\n>\n> **Second**\n\nAfter\n',
      );
      var result = '';
      await mount(tester, 'destination', 'Target\n', (value) => result = value);
      await key(tester, LogicalKeyboardKey.keyA);
      await key(tester, LogicalKeyboardKey.keyV);
      expect(result, contains('> First'));
      expect(result, contains('> **Second**'));
      expect(RegExp('Second').allMatches(result), hasLength(1));
    });

    testWidgets('right-click opens the menu for a whole-document selection', (
      tester,
    ) async {
      await mount(tester, 'issues', _source, (_) {});
      await key(tester, LogicalKeyboardKey.keyA);
      await key(tester, LogicalKeyboardKey.keyA);

      await tester.tap(
        find.widgetWithText(TextField, 'When selecting all, keep formatting.'),
        buttons: kSecondaryMouseButton,
      );
      await tester.pumpAndSettle();

      for (final label in [
        'Cut',
        'Copy',
        'Copy Plain Text',
        'Paste',
        'Select all',
      ]) {
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is BusyMarkPopupMenuItem && widget.label == label,
          ),
          findsOneWidget,
        );
      }
      await tester.tap(find.text('Copy'));
      await tester.pumpAndSettle();
      expect(systemData.keys, containsAll(['text', 'html', 'fragment']));
      expect(systemData['text'], contains('[ ] First task'));
    });

    testWidgets('Copy Plain Text strips formatting in another Editor', (
      tester,
    ) async {
      await mount(tester, 'issues', _source, (_) {});
      await key(tester, LogicalKeyboardKey.keyA);
      await key(tester, LogicalKeyboardKey.keyA);
      await key(tester, LogicalKeyboardKey.keyC, shift: true);

      expect(systemData.keys, ['text']);
      expect(systemData['text'], startsWith('Issues'));
      expect(
        systemData['text'],
        contains('When selecting all, keep formatting.'),
      );
      expect(systemData['text'], contains('[ ] First task'));
      expect(systemData['text'], isNot(contains('# Issues')));
      expect(systemData['text'], isNot(contains('**When**')));

      var result = '';
      await mount(tester, 'destination', 'Target\n', (value) => result = value);
      await key(tester, LogicalKeyboardKey.keyA);
      await key(tester, LogicalKeyboardKey.keyV);
      expect(result, contains('Issues'));
      expect(result, contains('When selecting all, keep formatting.'));
      expect(result, isNot(contains('# Issues')));
      expect(result, isNot(contains('**When**')));
      expect(result, isNot(contains('- [x] Second task')));
    });

    testWidgets('document selection menu can copy plain text', (tester) async {
      await mount(tester, 'issues', _source, (_) {});
      await key(tester, LogicalKeyboardKey.keyA);
      await key(tester, LogicalKeyboardKey.keyA);
      await tester.tap(
        find.widgetWithText(TextField, 'When selecting all, keep formatting.'),
        buttons: kSecondaryMouseButton,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Copy Plain Text'));
      await tester.pumpAndSettle();
      expect(systemData.keys, ['text']);
      expect(systemData['text'], startsWith('Issues'));
      expect(systemData['text'], isNot(contains('**When**')));
    });

    testWidgets(
      'partial inline copy keeps formatting inside another paragraph',
      (tester) async {
        await mount(tester, 'origin', 'A **bold** word\n', (_) {});
        final field = tester.widget<TextField>(find.byType(TextField).first);
        field.controller!.selection = const TextSelection(
          baseOffset: 2,
          extentOffset: 6,
        );
        await key(tester, LogicalKeyboardKey.keyC);
        var result = '';
        await mount(
          tester,
          'destination',
          'Before after\n',
          (value) => result = value,
        );
        tester
            .widget<TextField>(find.byType(TextField).first)
            .controller!
            .selection = const TextSelection.collapsed(
          offset: 7,
        );
        await key(tester, LogicalKeyboardKey.keyV);
        expect(result, 'Before **bold**after\n');
      },
    );

    testWidgets('cut transfers formatting before deleting the selection', (
      tester,
    ) async {
      var origin = 'A **bold** word\n';
      await mount(tester, 'origin', origin, (value) => origin = value);
      tester
          .widget<TextField>(find.byType(TextField).first)
          .controller!
          .selection = const TextSelection(
        baseOffset: 2,
        extentOffset: 6,
      );

      await key(tester, LogicalKeyboardKey.keyX);
      expect(origin, 'A  word\n');
      expect(systemData.keys, containsAll(['text', 'html', 'fragment']));
      expect(systemData['text'], 'bold');
      expect(systemData['html'], contains('<strong>bold</strong>'));

      var destination = '';
      await mount(
        tester,
        'destination',
        'Before after\n',
        (value) => destination = value,
      );
      tester
          .widget<TextField>(find.byType(TextField).first)
          .controller!
          .selection = const TextSelection.collapsed(
        offset: 7,
      );
      await key(tester, LogicalKeyboardKey.keyV);
      expect(destination, 'Before **bold**after\n');
    });

    testWidgets('malformed native fragment falls back to HTML', (tester) async {
      systemData = {
        'fragment': '{"version":99}',
        'html': '<p><b>Fallback</b></p>',
        'text': 'Fallback',
      };
      var result = '';
      await mount(tester, 'destination', 'Target\n', (value) => result = value);
      await key(tester, LogicalKeyboardKey.keyA);
      await key(tester, LogicalKeyboardKey.keyV);
      expect(result, '**Fallback**\n');
    });

    testWidgets('HTML-only clipboard imports into a fresh Editor', (
      tester,
    ) async {
      systemData = {
        'html': '<h1>Other app</h1><p><b>Bold</b></p>',
        'text': 'Other app\nBold',
      };
      var result = '';
      await mount(tester, 'destination', 'Target\n', (value) => result = value);
      await key(tester, LogicalKeyboardKey.keyA);
      await key(tester, LogicalKeyboardKey.keyV);
      expect(result, contains('# Other app'));
      expect(result, contains('**Bold**'));
    });

    testWidgets('Ctrl+Shift+V is not an Editor paste command', (tester) async {
      await copyAll(tester);
      var result = 'Target\n';
      await mount(tester, 'destination', result, (value) => result = value);
      await key(tester, LogicalKeyboardKey.keyA);
      await key(tester, LogicalKeyboardKey.keyV, shift: true);
      expect(result, 'Target\n');
    });

    testWidgets('failed clipboard write leaves cut selection intact', (
      tester,
    ) async {
      var result = _source;
      await mount(tester, 'origin', _source, (value) => result = value);
      await key(tester, LogicalKeyboardKey.keyA);
      await key(tester, LogicalKeyboardKey.keyA);
      failWrite = true;
      await key(tester, LogicalKeyboardKey.keyX);
      expect(result, _source);
      expect(systemData, isEmpty);
    });

    testWidgets('paste does not edit a destination changed during the read', (
      tester,
    ) async {
      systemData = {'text': 'Pasted', 'html': '<p><b>Pasted</b></p>'};
      var result = 'Target\n';
      await mount(tester, 'destination', result, (value) => result = value);
      readGate = Completer<void>();
      await key(tester, LogicalKeyboardKey.keyV);
      await tester.enterText(find.byType(TextField).first, 'Changed');
      readGate!.complete();
      await tester.pumpAndSettle();
      expect(result, 'Changed\n');
    });

    testWidgets('cut does not delete a selection changed during the write', (
      tester,
    ) async {
      var result = 'Target\n';
      await mount(tester, 'origin', result, (value) => result = value);
      await key(tester, LogicalKeyboardKey.keyA);
      writeGate = Completer<void>();
      await key(tester, LogicalKeyboardKey.keyX);
      final field = tester.widget<TextField>(find.byType(TextField).first);
      field.controller!.selection = const TextSelection.collapsed(offset: 0);
      writeGate!.complete();
      await tester.pumpAndSettle();
      expect(result, 'Target\n');
      expect(systemData['text'], 'Target');
    });

    testWidgets('paste is cancelled when the destination Editor is replaced', (
      tester,
    ) async {
      systemData = {'html': '<p><b>Pasted</b></p>', 'text': 'Pasted'};
      await mount(tester, 'destination', 'Target\n', (_) {});
      readGate = Completer<void>();
      await key(tester, LogicalKeyboardKey.keyV);
      var result = 'Other\n';
      await mount(tester, 'other', result, (value) => result = value);
      readGate!.complete();
      await tester.pumpAndSettle();
      expect(result, 'Other\n');
    });
  });
}
