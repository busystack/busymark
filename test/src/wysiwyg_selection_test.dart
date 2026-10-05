import 'dart:io';

import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_block_widgets.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_document_controller.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_inline_controller.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_session_state.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../support/memory_rich_clipboard.dart';

const _fixture = 'test/fixtures/wysiwyg/selection_boundaries.md';

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pumpAndSettle();
}

Future<void> _drag(
  WidgetTester tester,
  String startText,
  int startOffset,
  String endText,
  int endOffset,
) async {
  Offset point(String text, int offset) {
    final editable = _editable(tester, _field(text));
    return editable.localToGlobal(
      editable.getLocalRectForCaret(TextPosition(offset: offset)).center,
    );
  }

  final start = point(startText, startOffset);
  final end = point(endText, endOffset);
  final gesture = await tester.startGesture(
    start,
    kind: PointerDeviceKind.mouse,
  );
  await gesture.moveTo(end);
  await gesture.up();
  await tester.pumpAndSettle();
}

Finder _field(String text) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.controller?.text == text,
);

RenderEditable _editable(WidgetTester tester, Finder field) => tester
    .state<EditableTextState>(
      find.descendant(of: field, matching: find.byType(EditableText)),
    )
    .renderEditable;

List<Rect> _paintedRects(WidgetTester tester, Finder field) {
  // Record the real selection painter's draw calls, not screenshot pixels.
  final stack = find.ancestor(of: field, matching: find.byType(Stack)).first;
  final overlay = find.descendant(
    of: stack,
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is CustomPaint &&
          widget.painter.runtimeType.toString().contains('SelectionPainter'),
    ),
  );
  if (overlay.evaluate().isEmpty) return [];
  final widget = tester.widget<CustomPaint>(overlay);
  final canvas = TestRecordingCanvas();
  widget.painter!.paint(canvas, tester.getSize(overlay));
  return [
    for (final call in canvas.invocations)
      if (call.invocation.memberName == #drawRect)
        call.invocation.positionalArguments.first as Rect,
  ];
}

void _expectGeometry(WidgetTester tester, Finder field, int start, int end) {
  final editable = _editable(tester, field);
  final expected = editable.getBoxesForSelection(
    TextSelection(baseOffset: start, extentOffset: end),
  );
  final painted = _paintedRects(tester, field);
  expect(painted, hasLength(expected.length));
  for (var index = 0; index < expected.length; index++) {
    final box = expected[index].toRect();
    expect(painted[index].left, closeTo(box.left, 0.01));
    expect(painted[index].right, closeTo(box.right, 0.01));
    expect(painted[index].top, closeTo(box.top, 0.01));
    expect(painted[index].bottom, closeTo(box.bottom, 0.01));
  }
}

Future<void> _mount(
  WidgetTester tester,
  BusyDocument document,
  MemoryRichClipboard clipboard, {
  WysiwygEditorSessionState session = const WysiwygEditorSessionState(),
  BusyMarkWysiwygSessionChanged? onSession,
  double width = 1000,
  double height = 1400,
}) async {
  await tester.binding.setSurfaceSize(Size(width, height));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: BusyMarkWysiwygEditor(
          key: UniqueKey(),
          document: document,
          clipboardService: clipboard,
          initialSessionState: session,
          onSessionChanged: onSession,
          onSourceChanged: (_, _) => fail('Selection must not edit the source'),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });
  final source = File(_fixture).readAsStringSync();
  final document = const MarkdownParser()
      .parse(filePath: 'selection.md', source: source)
      .busyDocument;

  test(
    'reduced fixture uses rendered offsets without Markdown delimiters or block separators',
    () {
      final controller = BusyMarkWysiwygDocumentController(document: document);
      addTearDown(controller.dispose);
      for (final block in document.blocks.where((b) => b.inlines.isNotEmpty)) {
        expect(controller.blockText(block.id), block.plainText);
        expect(controller.blockText(block.id), isNot(endsWith('\n')));
        for (final range in busyInlineStyleRanges(block.inlines)) {
          expect(range.start, greaterThanOrEqualTo(0));
          expect(range.end, lessThanOrEqualTo(block.plainText.length));
        }
      }
      for (final block
          in document.blocks
              .where((b) => b.kind == BusyBlockKind.unorderedListItem)
              .take(2)) {
        expect(block.plainText, isNot(contains('`')));
        final code = busyInlineStyleRanges(block.inlines).single;
        expect(code.kind, BusyInlineKind.code);
        expect(code.start, 0);
        expect(code.end, block.plainText.length);
      }
    },
  );

  testWidgets(
    'Select All: logical range and copy include styled suffixes and table',
    (tester) async {
      final clipboard = MemoryRichClipboard();
      WysiwygEditorSessionState? session;
      await _mount(
        tester,
        document,
        clipboard,
        onSession: (_, s) => session = s,
      );
      final first = tester.widget<TextField>(
        _field(document.blocks.first.plainText),
      );
      first.focusNode!.requestFocus();
      first.controller!.selection = const TextSelection.collapsed(offset: 0);
      await tester.pump();
      await _key(tester, LogicalKeyboardKey.keyA);
      expect(first.controller!.selection.end, first.controller!.text.length);
      await _key(tester, LogicalKeyboardKey.keyA);
      expect(session?.anchorBlockId, document.blocks.first.id);
      expect(session?.anchorOffset, 0);
      expect(session?.extentBlockId, document.blocks.last.id);
      expect(session?.extentOffset, document.blocks.last.plainText.length);
      await _key(tester, LogicalKeyboardKey.keyC);
      expect(
        clipboard.data.text,
        contains('not the final integration result.'),
      );
      expect(clipboard.data.text, contains('/mnt/Media/Linguality/gateway'));
      expect(
        clipboard.data.text,
        contains('/mnt/Media/Linguality/learner_client'),
      );
      expect(clipboard.data.text, contains('A longer body cell'));
      expect(clipboard.data.text, contains('End!'));
      expect(
        clipboard.data.sourceText,
        contains('`/mnt/Media/Linguality/gateway`'),
      );
      expect(
        clipboard.data.sourceText,
        contains('`/mnt/Media/Linguality/learner_client`'),
      );
      expect(
        clipboard.data.sourceText,
        contains('**The client must work before corpus population finishes.**'),
      );
      for (final block in tester.widgetList<BusyMarkWysiwygBlockField>(
        find.byType(BusyMarkWysiwygBlockField),
      )) {
        expect(block.selectionRange?.start, 0);
        expect(block.selectionRange?.end, block.block.plainText.length);
      }
    },
  );

  for (final block in document.blocks.where((b) => b.inlines.isNotEmpty)) {
    testWidgets(
      'multi-block paint matches rendered runs: ${block.id} ${block.kind}',
      (tester) async {
        await _mount(
          tester,
          document,
          MemoryRichClipboard(),
          session: WysiwygEditorSessionState(
            activeBlockId: document.blocks.last.id,
            anchorBlockId: document.blocks.first.id,
            extentBlockId: document.blocks.last.id,
            extentOffset: document.blocks.last.plainText.length,
          ),
        );
        _expectGeometry(
          tester,
          _field(block.plainText),
          0,
          block.plainText.length,
        );
      },
    );
  }

  testWidgets('table cells paint the same selected text as document copy', (
    tester,
  ) async {
    final clipboard = MemoryRichClipboard();
    await _mount(
      tester,
      document,
      clipboard,
      session: WysiwygEditorSessionState(
        activeBlockId: document.blocks.last.id,
        anchorBlockId: document.blocks.first.id,
        extentBlockId: document.blocks.last.id,
        extentOffset: document.blocks.last.plainText.length,
      ),
    );
    await _key(tester, LogicalKeyboardKey.keyC);
    final table = document.blocks.firstWhere(
      (b) => b.kind == BusyBlockKind.table,
    );
    for (final cell in table.children.expand((row) => row.children)) {
      expect(clipboard.data.text, contains(cell.plainText));
      _expectGeometry(tester, _field(cell.plainText), 0, cell.plainText.length);
    }
  });

  testWidgets('repeated Select All keeps the entire document selected', (
    tester,
  ) async {
    final clipboard = MemoryRichClipboard();
    WysiwygEditorSessionState? session;
    await _mount(tester, document, clipboard, onSession: (_, s) => session = s);
    final first = tester.widget<TextField>(
      _field(document.blocks.first.plainText),
    );
    first.focusNode!.requestFocus();
    first.controller!.selection = const TextSelection.collapsed(offset: 0);
    await tester.pump();
    for (var invocation = 0; invocation < 5; invocation++) {
      await _key(tester, LogicalKeyboardKey.keyA);
      if (invocation == 0) continue;
      expect(session?.anchorBlockId, document.blocks.first.id);
      expect(session?.extentBlockId, document.blocks.last.id);
      await _key(tester, LogicalKeyboardKey.keyC);
      expect(clipboard.data.text, contains('Previous paragraph'));
      expect(clipboard.data.text, contains('End!'));
    }
  });

  for (final text in [
    'Before.\n\n| H |\n| --- |\n| Body! |\n',
    '| H |\n| --- |\n| Body! |\n\nAfter.\n',
  ]) {
    testWidgets('Select All includes a table at the document edge: $text', (
      tester,
    ) async {
      final edgeDocument = const MarkdownParser()
          .parse(filePath: 'edge.md', source: text)
          .busyDocument;
      final clipboard = MemoryRichClipboard();
      WysiwygEditorSessionState? session;
      await _mount(
        tester,
        edgeDocument,
        clipboard,
        onSession: (_, s) => session = s,
      );
      final paragraph = edgeDocument.blocks.firstWhere(
        (b) => b.kind == BusyBlockKind.paragraph,
      );
      final field = tester.widget<TextField>(_field(paragraph.plainText));
      field.focusNode!.requestFocus();
      field.controller!.selection = const TextSelection.collapsed(offset: 0);
      await tester.pump();
      await _key(tester, LogicalKeyboardKey.keyA);
      await _key(tester, LogicalKeyboardKey.keyA);
      await _key(tester, LogicalKeyboardKey.keyC);
      expect(session?.anchorBlockId, edgeDocument.blocks.first.id);
      expect(session?.extentBlockId, edgeDocument.blocks.last.id);
      expect(clipboard.data.text, contains('Body!'));
    });
  }

  testWidgets('drag endpoints use the styled rendered coordinate system', (
    tester,
  ) async {
    final clipboard = MemoryRichClipboard();
    WysiwygEditorSessionState? session;
    await _mount(tester, document, clipboard, onSession: (_, s) => session = s);
    final styled = document.blocks[1];
    await _drag(tester, styled.plainText, 20, document.blocks[2].plainText, 8);
    expect(session?.anchorOffset, 20);
    expect(session?.extentOffset, 8);
    await _key(tester, LogicalKeyboardKey.keyC);
    expect(
      clipboard.data.text,
      '${styled.plainText.substring(20)}\n\n${document.blocks[2].plainText.substring(0, 8)}',
    );
  });

  testWidgets(
    'drag from a paragraph into a table copies and selects its cells',
    (tester) async {
      final clipboard = MemoryRichClipboard();
      await _mount(tester, document, clipboard);
      final before = document.blocks[6];
      await _drag(tester, before.plainText, 0, 'A longer body cell', 8);
      await _key(tester, LogicalKeyboardKey.keyC);
      expect(clipboard.data.text, contains('A longer body cell'));
      _expectGeometry(tester, _field('End!'), 0, 4);
    },
  );

  testWidgets(
    'drag across table cells selects the existing complete-table document block',
    (tester) async {
      final clipboard = MemoryRichClipboard();
      await _mount(tester, document, clipboard);
      await _drag(tester, 'Header', 0, 'End!', 4);
      await _key(tester, LogicalKeyboardKey.keyC);
      expect(clipboard.data.text, contains('Header'));
      expect(clipboard.data.text, contains('A longer body cell'));
      expect(clipboard.data.sourceText, contains('| Last row | End! |'));
      _expectGeometry(tester, _field('End!'), 0, 4);
    },
  );

  for (final width in [460.0, 1000.0]) {
    for (final endpoints in [
      (1, 0, 1, document.blocks[1].plainText.length),
      (0, 4, 1, document.blocks[1].plainText.length),
      (1, 0, 2, 8),
      (0, 0, 2, document.blocks[2].plainText.length),
      (2, document.blocks[2].plainText.length, 0, 0),
    ]) {
      testWidgets('paragraph boundary $endpoints at width $width', (
        tester,
      ) async {
        final (anchorIndex, anchorOffset, extentIndex, extentOffset) =
            endpoints;
        final clipboard = MemoryRichClipboard();
        await _mount(
          tester,
          document,
          clipboard,
          width: width,
          session: WysiwygEditorSessionState(
            activeBlockId: document.blocks[extentIndex].id,
            anchorBlockId: document.blocks[anchorIndex].id,
            anchorOffset: anchorOffset,
            extentBlockId: document.blocks[extentIndex].id,
            extentOffset: extentOffset,
          ),
        );
        final middle = document.blocks[1];
        final field = _field(middle.plainText);
        if (anchorIndex == extentIndex) {
          expect(
            tester.widget<TextField>(field).controller!.selection,
            TextSelection(baseOffset: 0, extentOffset: middle.plainText.length),
          );
        } else {
          final model = tester
              .widgetList<BusyMarkWysiwygBlockField>(
                find.byType(BusyMarkWysiwygBlockField),
              )
              .firstWhere((b) => b.block.id == middle.id);
          expect(model.selectionRange?.start, 0);
          expect(model.selectionRange?.end, middle.plainText.length);
          _expectGeometry(tester, field, 0, middle.plainText.length);
          final suffix = _editable(tester, field).getBoxesForSelection(
            TextSelection(
              baseOffset: middle.plainText.length - 1,
              extentOffset: middle.plainText.length,
            ),
          );
          expect(suffix, isNotEmpty);
          for (final glyph in suffix) {
            expect(
              _paintedRects(
                tester,
                field,
              ).any((r) => r.inflate(0.01).contains(glyph.toRect().center)),
              isTrue,
            );
          }
        }
        await _key(tester, LogicalKeyboardKey.keyC);
        expect(clipboard.data.text, contains(middle.plainText));
        expect(
          clipboard.data.text,
          contains('not the final integration result.'),
        );
      });
    }

    testWidgets(
      'all styled runs and list endings repaint after resizing to $width',
      (tester) async {
        await _mount(
          tester,
          document,
          MemoryRichClipboard(),
          session: WysiwygEditorSessionState(
            activeBlockId: document.blocks.last.id,
            anchorBlockId: document.blocks.first.id,
            extentBlockId: document.blocks.last.id,
            extentOffset: document.blocks.last.plainText.length,
          ),
        );
        await tester.binding.setSurfaceSize(Size(width, 1400));
        await tester.pumpAndSettle();
        for (final block in document.blocks.where(
          (b) => b.inlines.isNotEmpty,
        )) {
          _expectGeometry(
            tester,
            _field(block.plainText),
            0,
            block.plainText.length,
          );
        }
      },
    );
  }

  for (final inline in [
    '**Bold** plain!',
    'plain **bold**!',
    '`code` plain!',
    'plain `code`!',
    '[link](https://example.test) plain!',
    '*emphasis* plain!',
  ]) {
    final styled = const MarkdownParser()
        .parse(filePath: 'inline.md', source: 'Before.\n\n$inline\n\nAfter.\n')
        .busyDocument;
    for (final end in [
      2,
      styled.blocks[1].plainText.length - 1,
      styled.blocks[1].plainText.length,
    ]) {
      testWidgets('partial multi-block styled span: $inline end=$end', (
        tester,
      ) async {
        final clipboard = MemoryRichClipboard();
        await _mount(
          tester,
          styled,
          clipboard,
          session: WysiwygEditorSessionState(
            activeBlockId: styled.blocks[1].id,
            anchorBlockId: styled.blocks.first.id,
            anchorOffset: styled.blocks.first.plainText.length,
            extentBlockId: styled.blocks[1].id,
            extentOffset: end,
          ),
        );
        _expectGeometry(tester, _field(styled.blocks[1].plainText), 0, end);
        await _key(tester, LogicalKeyboardKey.keyC);
        expect(
          clipboard.data.text,
          styled.blocks[1].plainText.substring(0, end),
        );
      });
    }
  }

  for (final endpoints in [
    (3, 0, 3, document.blocks[3].plainText.length),
    (4, 0, 4, document.blocks[4].plainText.length),
    (3, 0, 4, document.blocks[4].plainText.length),
    (2, 4, 4, document.blocks[4].plainText.length),
    (3, 0, 6, 9),
    (2, 0, 6, document.blocks[6].plainText.length),
    (5, 0, 5, document.blocks[5].plainText.length),
  ]) {
    testWidgets(
      'list boundary $endpoints includes the final rendered character',
      (tester) async {
        final (anchor, anchorOffset, extent, extentOffset) = endpoints;
        final clipboard = MemoryRichClipboard();
        await _mount(
          tester,
          document,
          clipboard,
          session: WysiwygEditorSessionState(
            activeBlockId: document.blocks[extent].id,
            anchorBlockId: document.blocks[anchor].id,
            anchorOffset: anchorOffset,
            extentBlockId: document.blocks[extent].id,
            extentOffset: extentOffset,
          ),
        );
        final expectedText = <String>[];
        for (var index = anchor; index <= extent; index++) {
          final block = document.blocks[index];
          final start = index == anchor ? anchorOffset : 0;
          final end = index == extent ? extentOffset : block.plainText.length;
          final whole = start == 0 && end == block.plainText.length;
          expectedText.add(
            '${whole && block.kind == BusyBlockKind.unorderedListItem ? '• ' : ''}${block.plainText.substring(start, end)}',
          );
          if (anchor != extent) {
            _expectGeometry(tester, _field(block.plainText), start, end);
          } else {
            expect(
              tester
                  .widget<TextField>(_field(block.plainText))
                  .controller!
                  .selection,
              TextSelection(baseOffset: start, extentOffset: end),
            );
          }
        }
        await _key(tester, LogicalKeyboardKey.keyC);
        expect(clipboard.data.text, expectedText.join('\n\n'));
        for (var index = 3; index <= 4; index++) {
          if (index >= anchor && index <= extent) {
            expect(
              clipboard.data.sourceText,
              contains('`${document.blocks[index].plainText}`'),
            );
          }
        }
      },
    );
  }

  testWidgets(
    'mouse range across paragraph, list, table and paragraph equals Select All',
    (tester) async {
      final clipboard = MemoryRichClipboard();
      await _mount(tester, document, clipboard);
      final first = tester.widget<TextField>(
        _field(document.blocks.first.plainText),
      );
      first.focusNode!.requestFocus();
      first.controller!.selection = const TextSelection.collapsed(offset: 0);
      await tester.pump();
      await _key(tester, LogicalKeyboardKey.keyA);
      await _key(tester, LogicalKeyboardKey.keyA);
      await _key(tester, LogicalKeyboardKey.keyC);
      final selectAllText = clipboard.data.text;
      final selectAllMarkdown = clipboard.data.sourceText;
      await _drag(
        tester,
        document.blocks.first.plainText,
        0,
        document.blocks.last.plainText,
        document.blocks.last.plainText.length,
      );
      await _key(tester, LogicalKeyboardKey.keyC);
      expect(clipboard.data.text, selectAllText);
      expect(clipboard.data.sourceText, selectAllMarkdown);
      for (final block in document.blocks.where((b) => b.inlines.isNotEmpty)) {
        _expectGeometry(
          tester,
          _field(block.plainText),
          0,
          block.plainText.length,
        );
      }
      _expectGeometry(tester, _field('End!'), 0, 4);
    },
  );

  testWidgets(
    'Select All, mouse and keyboard ranges produce equivalent local selection geometry',
    (tester) async {
      final clipboard = MemoryRichClipboard();
      final tiny = const MarkdownParser()
          .parse(
            filePath: 'tiny.md',
            source: 'Before.\n\n**Bold** with `code` and plain!\n\nAfter.\n',
          )
          .busyDocument;
      await _mount(tester, tiny, clipboard);
      final field = tester.widget<TextField>(
        _field(tiny.blocks.first.plainText),
      );
      field.focusNode!.requestFocus();
      field.controller!.selection = const TextSelection.collapsed(offset: 0);
      await tester.pump();
      await _key(tester, LogicalKeyboardKey.keyA);
      await _key(tester, LogicalKeyboardKey.keyA);
      List<(String, int?, int?)> ranges() => [
        for (final b in tester.widgetList<BusyMarkWysiwygBlockField>(
          find.byType(BusyMarkWysiwygBlockField),
        ))
          (b.block.id, b.selectionRange?.start, b.selectionRange?.end),
      ];
      final allRanges = ranges();
      final allGeometry = _paintedRects(
        tester,
        _field(tiny.blocks[1].plainText),
      );
      await _key(tester, LogicalKeyboardKey.keyC);
      final allCopy = clipboard.data.text;
      await _drag(
        tester,
        tiny.blocks.first.plainText,
        0,
        tiny.blocks.last.plainText,
        tiny.blocks.last.plainText.length,
      );
      expect(ranges(), allRanges);
      expect(
        _paintedRects(tester, _field(tiny.blocks[1].plainText)),
        allGeometry,
      );
      await _key(tester, LogicalKeyboardKey.keyC);
      expect(clipboard.data.text, allCopy);
      field.focusNode!.requestFocus();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      field.controller!.selection = const TextSelection.collapsed(offset: 0);
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      for (
        var i = 0;
        i < tiny.blocks.fold<int>(0, (n, b) => n + b.plainText.length) + 2;
        i++
      ) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
      }
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(ranges(), allRanges);
      expect(
        _paintedRects(tester, _field(tiny.blocks[1].plainText)),
        allGeometry,
      );
      await _key(tester, LogicalKeyboardKey.keyC);
      expect(clipboard.data.text, allCopy);
    },
  );

  testWidgets(
    'local table cell selection stays local; subsequent Select All expands to document',
    (tester) async {
      final clipboard = MemoryRichClipboard();
      await _mount(tester, document, clipboard);
      await tester.tap(_field('A longer body cell'));
      final field = tester.widget<TextField>(_field('A longer body cell'));
      field.controller!.selection = const TextSelection(
        baseOffset: 2,
        extentOffset: 8,
      );
      await _key(tester, LogicalKeyboardKey.keyC);
      expect(clipboard.data.text, 'longer');
      expect(_paintedRects(tester, _field('Header')), isEmpty);
      await _key(tester, LogicalKeyboardKey.keyA);
      expect(field.controller!.selection.start, 0);
      expect(field.controller!.selection.end, field.controller!.text.length);
      await _key(tester, LogicalKeyboardKey.keyA);
      await _key(tester, LogicalKeyboardKey.keyC);
      expect(clipboard.data.text, contains('Previous paragraph'));
      expect(clipboard.data.text, contains('End!'));
      _expectGeometry(tester, _field('A longer body cell'), 0, 18);
    },
  );

  testWidgets('table to following paragraph retains complete selected rows', (
    tester,
  ) async {
    final clipboard = MemoryRichClipboard();
    await _mount(tester, document, clipboard);
    await _drag(tester, 'Short', 1, document.blocks.last.plainText, 5);
    await _key(tester, LogicalKeyboardKey.keyC);
    expect(clipboard.data.text, endsWith('\n\nFinal'));
    expect(clipboard.data.text, contains('End!'));
    expect(clipboard.data.text, isNot(contains('Previous paragraph')));
    for (final text in [
      'Header',
      'Longer header',
      'Short',
      'A longer body cell',
      'Last row',
      'End!',
    ]) {
      _expectGeometry(tester, _field(text), 0, text.length);
    }
  });

  testWidgets(
    'document selection survives viewport scrolling and block recreation',
    (tester) async {
      final clipboard = MemoryRichClipboard();
      WysiwygEditorSessionState? session;
      await _mount(
        tester,
        document,
        clipboard,
        height: 400,
        onSession: (_, s) => session = s,
        session: WysiwygEditorSessionState(
          activeBlockId: document.blocks.first.id,
          anchorBlockId: document.blocks.first.id,
          extentBlockId: document.blocks.last.id,
          extentOffset: document.blocks.last.plainText.length,
        ),
      );
      final list = tester.widget<ScrollablePositionedList>(
        find.byType(ScrollablePositionedList),
      );
      for (final index in [0, 3, 6, 8, 1]) {
        list.itemScrollController!.jumpTo(index: index, alignment: 0.1);
        await tester.pumpAndSettle();
        expect(session?.anchorBlockId, document.blocks.first.id);
        expect(session?.extentBlockId, document.blocks.last.id);
        final rendered = tester
            .widgetList<BusyMarkWysiwygBlockField>(
              find.byType(BusyMarkWysiwygBlockField),
            )
            .toList();
        for (final block in rendered.where((b) => b.block.inlines.isNotEmpty)) {
          expect(block.selectionRange?.end, block.block.plainText.length);
          _expectGeometry(
            tester,
            _field(block.block.plainText),
            0,
            block.block.plainText.length,
          );
        }
        await _key(tester, LogicalKeyboardKey.keyC);
        expect(
          clipboard.data.text,
          contains('not the final integration result.'),
        );
        expect(clipboard.data.text, contains('End!'));
      }
    },
  );

  testWidgets('selected table text follows horizontal cell scrolling', (
    tester,
  ) async {
    final longText = 'long cell content ' * 12;
    final scrollDocument = const MarkdownParser()
        .parse(
          filePath: 'scroll.md',
          source: 'Before.\n\n| H |\n| --- |\n| $longText |\n\nAfter.\n',
        )
        .busyDocument;
    await _mount(
      tester,
      scrollDocument,
      MemoryRichClipboard(),
      width: 460,
      session: WysiwygEditorSessionState(
        activeBlockId: scrollDocument.blocks.last.id,
        anchorBlockId: scrollDocument.blocks.first.id,
        extentBlockId: scrollDocument.blocks.last.id,
        extentOffset: scrollDocument.blocks.last.plainText.length,
      ),
    );
    final field = _field(longText.trim());
    final editable = _editable(tester, field);
    final position = editable.offset as ScrollPosition;
    expect(position.maxScrollExtent, greaterThan(0));
    position.jumpTo(position.maxScrollExtent);
    await tester.pumpAndSettle();
    _expectGeometry(tester, field, 0, longText.trim().length);
  });

  testWidgets('drag across a viewport jump resolves the visible extent block', (
    tester,
  ) async {
    WysiwygEditorSessionState? session;
    await _mount(
      tester,
      document,
      MemoryRichClipboard(),
      height: 600,
      onSession: (_, s) => session = s,
    );
    final list = tester.widget<ScrollablePositionedList>(
      find.byType(ScrollablePositionedList),
    );
    list.itemScrollController!.jumpTo(index: 3, alignment: 0.1);
    await tester.pumpAndSettle();
    final start = _editable(tester, _field(document.blocks[3].plainText));
    final startPoint = start.localToGlobal(
      start.getLocalRectForCaret(const TextPosition(offset: 0)).center,
    );
    final gesture = await tester.startGesture(
      startPoint,
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveTo(startPoint + const Offset(0, 40));
    await tester.pumpAndSettle();
    list.itemScrollController!.jumpTo(index: 6, alignment: 0.1);
    await tester.pumpAndSettle();
    final end = _editable(tester, _field(document.blocks.last.plainText));
    final endPoint = end.localToGlobal(
      end.getLocalRectForCaret(const TextPosition(offset: 5)).center,
    );
    for (var step = 1; step <= 10; step++) {
      await gesture.moveTo(Offset.lerp(startPoint, endPoint, step / 10)!);
      await tester.pump(const Duration(milliseconds: 180));
    }
    await gesture.up();
    await tester.pumpAndSettle();
    expect(session?.anchorBlockId, document.blocks[3].id);
    expect(session?.extentBlockId, document.blocks.last.id);
    expect(session?.extentOffset, 5);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
}
