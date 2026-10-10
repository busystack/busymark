import 'dart:async';
import 'dart:io';

import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/editor/wysiwyg/writerside_editing_adapter.dart';
import 'package:busymark/src/editor/wysiwyg/writerside_properties.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_inline_controller.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_session_state.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/platform/native_menu_service.dart';
import 'package:busymark/src/writerside/writerside_project.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

BusyDocument _document(bool xml, {String? source}) => xml
    ? const WritersideEditingAdapter().parseXml(
        filePath: 'a.topic',
        source: source ?? '<topic id="a" title="Title"><p>Text</p></topic>',
      )!
    : const MarkdownParser()
          .parse(
            filePath: 'a.md',
            source: source ?? '# Title\n\nText\n',
            mode: MarkdownMode.writersideMarkdown,
            validateLocalReferences: false,
          )
          .busyDocument;

Widget _app(
  Widget child, {
  Brightness brightness = Brightness.light,
  TextDirection direction = TextDirection.ltr,
  double scale = 1,
}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: ThemeData(brightness: brightness),
  home: Directionality(
    textDirection: direction,
    child: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: Scaffold(body: child),
    ),
  ),
);

Finder _contentFields() => find.byWidgetPredicate(
  (w) => w is TextField && w.controller is BusyMarkWysiwygTextController,
);
Finder _textField(String text) => _contentFields()
    .evaluate()
    .where((e) => (e.widget as TextField).controller!.text == text)
    .map((e) => find.byWidget(e.widget))
    .first;

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(nativeMenuChannelName);
  final labels = <String>[];
  final presentations = <List<dynamic>>[];
  setUp(() {
    labels.clear();
    presentations.clear();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method != 'show') return true;
      final entries = (call.arguments as Map)['entries'] as List<dynamic>;
      presentations.add(entries);
      if (labels.isEmpty) return null;
      final label = labels.removeAt(0);
      final selected = entries.indexWhere((e) => e['label'] == label);
      expect(
        selected,
        greaterThanOrEqualTo(0),
        reason: 'Native menu must offer $label',
      );
      expect(entries[selected]['enabled'], isTrue);
      return selected;
    });
  });
  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });
  Future<void> mount(WidgetTester tester, BusyMarkWysiwygEditor editor) async {
    tester.view.resetPhysicalSize();
    tester.view.physicalSize = const Size(1100, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(editor));
    await tester.pumpAndSettle();
  }

  Future<void> insert(WidgetTester tester, String label) async {
    await tester.pumpAndSettle();
    labels.add(label);
    await tester.tap(find.byKey(const ValueKey('wysiwyg-writerside-insert')));
    await tester.pumpAndSettle();
  }

  for (final xml in [false, true]) {
    for (final label in ['Procedure', 'Tabs', 'Definition List', 'TLDR']) {
      testWidgets(
        '${xml ? 'XML' : 'Markdown'} inserts and edits $label through native menu',
        (tester) async {
          var source = '';
          await mount(
            tester,
            BusyMarkWysiwygEditor(
              document: _document(xml),
              onSourceChanged: (_, s) => source = s,
            ),
          );
          await tester.tap(_textField('Text'));
          await insert(tester, label);
          expect(presentations, isNotEmpty);
          await tester.enterText(_textField(''), 'Edited content');
          await tester.pumpAndSettle();
          expect(source, contains('Edited content'));
          final parsed = _document(xml, source: source);
          expect(parsed.isXmlTopic, xml);
          expect(
            source,
            contains(
              '</${{'Procedure': 'procedure', 'Tabs': 'tabs', 'Definition List': 'deflist', 'TLDR': 'tldr'}[label]}>',
            ),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
    for (final label in [
      'UI Control',
      'File / Path',
      'UI Path',
      'Keyboard Shortcuts',
    ]) {
      testWidgets(
        '${xml ? 'XML' : 'Markdown'} applies $label and restores undo',
        (tester) async {
          var source = '';
          await mount(
            tester,
            BusyMarkWysiwygEditor(
              document: _document(xml),
              onSourceChanged: (_, s) => source = s,
            ),
          );
          final field = _textField('Text');
          await tester.tap(field);
          tester.widget<TextField>(field).controller!.selection =
              const TextSelection(baseOffset: 0, extentOffset: 4);
          await tester.pumpAndSettle();
          labels.add(label);
          await tester.tap(find.byTooltip('Semantic formatting'));
          await tester.pumpAndSettle();
          final tag = {
            'UI Control': 'control',
            'File / Path': 'path',
            'UI Path': 'ui-path',
            'Keyboard Shortcuts': 'shortcut',
          }[label];
          expect(source, contains('<$tag>Text</$tag>'));
          await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
          await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
          await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
          await tester.pumpAndSettle();
          expect(source, isNot(contains('<$tag>')));
          await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
          await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
          await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
          await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
          await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
          await tester.pumpAndSettle();
          expect(source, contains('<$tag>Text</$tag>'));
        },
      );
    }
  }
  testWidgets('video insertion draft and cancellation do not modify source', (
    tester,
  ) async {
    var source = '';
    await mount(
      tester,
      BusyMarkWysiwygEditor(
        document: _document(true),
        onSourceChanged: (_, s) => source = s,
      ),
    );
    await tester.tap(_textField('Text'));
    await insert(tester, 'Video');
    expect(source, isEmpty);
    final entry = find.byKey(const ValueKey('writerside-video-source'));
    final field = find.descendant(of: entry, matching: find.byType(TextField));
    await tester.enterText(field, 'https://youtu.be/cancelled');
    await tester.tap(
      find.descendant(
        of: find.byType(BusyMarkWritersideProperties),
        matching: find.byTooltip('Close'),
      ),
    );
    await tester.pumpAndSettle();
    expect(source, isEmpty);
    await insert(tester, 'Video');
    await tester.enterText(field, 'https://youtu.be/example');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(source, contains('<video src="https://youtu.be/example"/>'));
  });
  testWidgets(
    'include native picker offers authored reusable elements and omits root-only topics',
    (tester) async {
      final root = await tester.runAsync(() async {
        final root = await Directory.systemTemp.createTemp(
          'busymark-authoring-picker-',
        );
        await Directory('${root.path}/topics').create();
        await File('${root.path}/writerside.cfg').writeAsString(
          '<ihp><topics dir="topics"/><instance src="main.tree"/></ihp>',
        );
        await File('${root.path}/main.tree').writeAsString(
          '<instance-profile id="main" name="Main" start-page="current.topic"><toc-element topic="current.topic"/><toc-element topic="library.topic"/><toc-element topic="empty.topic"/></instance-profile>',
        );
        await File('${root.path}/topics/current.topic').writeAsString(
          '<topic id="current" title="Current"><p>Text</p></topic>',
        );
        await File('${root.path}/topics/library.topic').writeAsString(
          '<topic id="library" title="Library"><snippet id="shared"><p>Owned by library</p></snippet></topic>',
        );
        await File('${root.path}/topics/empty.topic').writeAsString(
          '<topic id="empty" title="Empty"><p>No reusable identifier</p></topic>',
        );
        return root;
      });
      addTearDown(() => root!.delete(recursive: true));
      final project = (await tester.runAsync(
        () => const WritersideProjectService().load(root!.path),
      ))!;
      var saved = '';
      await mount(
        tester,
        BusyMarkWysiwygEditor(
          document: const WritersideEditingAdapter().parseXml(
            filePath: '${root!.path}/topics/current.topic',
            source: '<topic id="current" title="Current"><p>Text</p></topic>',
          )!,
          writersideProjectIndex: project.index,
          writersideModuleId: project.index.modulesById.keys.single,
          onSourceChanged: (_, value) => saved = value,
        ),
      );
      await tester.tap(_textField('Text'));
      labels.addAll(['Include Reusable Content', 'library.topic', 'shared']);
      await tester.tap(find.byKey(const ValueKey('wysiwyg-writerside-insert')));
      await tester.pumpAndSettle();
      expect(presentations[1].map((e) => e['label']), ['library.topic']);
      expect(presentations[2].map((e) => e['label']), ['shared']);
      expect(
        saved,
        contains('<include from="library.topic" element-id="shared"/>'),
      );
      expect(saved, isNot(contains('Owned by library')));
    },
  );
  testWidgets(
    'variable native picker uses module and lexical scope, inserts reference',
    (tester) async {
      const index = WritersideProjectIndex(
        symbols: [
          WritersideSymbol(
            name: 'product',
            qualifiedName: 'm:product',
            kind: WritersideSymbolKind.variable,
            moduleId: 'm',
            filePath: 'v.list',
          ),
          WritersideSymbol(
            name: 'wrong',
            qualifiedName: 'other:wrong',
            kind: WritersideSymbolKind.variable,
            moduleId: 'other',
            filePath: 'other/v.list',
          ),
        ],
        references: [],
        diagnostics: [],
      );
      var source = '';
      await mount(
        tester,
        BusyMarkWysiwygEditor(
          document: _document(true),
          writersideProjectIndex: index,
          writersideModuleId: 'm',
          onSourceChanged: (_, s) => source = s,
        ),
      );
      await tester.tap(_textField('Text'));
      await tester.pumpAndSettle();
      labels.addAll(['Variable Reference', 'product']);
      await tester.tap(find.byKey(const ValueKey('wysiwyg-writerside-insert')));
      await tester.pumpAndSettle();
      expect(presentations.last.map((e) => e['label']), ['product']);
      expect(source, contains('%product%'));
    },
  );
  for (final xml in [false, true]) {
    testWidgets(
      '${xml ? 'XML' : 'Markdown'} Topic Properties preserve a quoted label through undo and reopen',
      (tester) async {
        const label = r'''Author's: "Desktop" \ Keys''';
        final original = _document(xml).source;
        var saved = '';
        await mount(
          tester,
          BusyMarkWysiwygEditor(
            document: _document(xml),
            documentId: 'original',
            onSourceChanged: (_, source) => saved = source,
          ),
        );
        final field = _textField('Text');
        await tester.tap(field);
        tester.widget<TextField>(field).controller!.selection =
            const TextSelection.collapsed(offset: 2);
        await tester.pumpAndSettle();
        Future<void> selectTopic() async {
          labels.add('Topic Properties');
          await tester.tap(
            find.byWidgetPredicate(
              (w) =>
                  w is BusyMarkComboRow<String> && w.values.contains('@topic'),
            ),
          );
          await tester.pumpAndSettle();
        }

        await selectTopic();
        expect(
          tester
              .widget<TextField>(_textField('Text'))
              .controller!
              .selection
              .baseOffset,
          2,
        );
        expect(saved, isEmpty);
        Finder entry() => find.descendant(
          of: find.byKey(
            const ValueKey('writerside-property-topic-switcher-label'),
          ),
          matching: find.byType(TextField),
        );
        await tester.enterText(entry(), label);
        expect(saved, isEmpty);
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        expect(
          _document(xml, source: saved).frontMatter['switcher-label'] ??
              _document(
                xml,
                source: saved,
              ).blocks.first.attributes['switcher-label'],
          label,
        );
        final authored = saved;
        await tester.tap(_textField('Text'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<BusyMarkWritersideProperties>(
                find.byType(BusyMarkWritersideProperties),
              )
              .topicSelected,
          isFalse,
        );
        expect(saved, authored);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pumpAndSettle();
        expect(saved, original);
        await tester.pumpWidget(
          _app(
            BusyMarkWysiwygEditor(
              document: _document(xml, source: authored),
              documentId: 'reopened',
              onSourceChanged: (_, source) => saved = source,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(_textField('Text'));
        await tester.pumpAndSettle();
        await selectTopic();
        expect(tester.widget<TextField>(entry()).controller!.text, label);
      },
    );
  }
  testWidgets('returning to a table cell retargets Topic Properties', (
    tester,
  ) async {
    var edits = 0;
    await mount(
      tester,
      BusyMarkWysiwygEditor(
        document: _document(
          false,
          source: '# Title\n\n## Section\n\n| Header |\n| --- |\n| Cell |\n',
        ),
        onSourceChanged: (_, _) => edits++,
      ),
    );
    await tester.tap(_textField('Cell'));
    await tester.pumpAndSettle();
    labels.add('Topic Properties');
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is BusyMarkComboRow<String> && w.values.contains('@topic'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(_textField('Cell'));
    await tester.pumpAndSettle();
    final properties = tester.widget<BusyMarkWritersideProperties>(
      find.byType(BusyMarkWritersideProperties),
    );
    expect(properties.topicSelected, isFalse);
    expect(properties.target!.kind, BusyBlockKind.table);
    expect(edits, 0);
  });
  testWidgets('shortcut reference properties identify keyboard layout', (
    tester,
  ) async {
    await mount(
      tester,
      BusyMarkWysiwygEditor(
        document: _document(
          true,
          source:
              '<topic id="a" title="Title"><p><shortcut key="\$Save" force-layout="Linux">Save</shortcut></p></topic>',
        ),
        onSourceChanged: (_, _) {},
      ),
    );
    final field = _textField('Save');
    await tester.tap(field);
    tester.widget<TextField>(field).controller!.selection =
        const TextSelection.collapsed(offset: 2);
    await tester.pumpAndSettle();
    expect(find.text('Keyboard layout'), findsOneWidget);
    expect(find.text('List layout'), findsNothing);
  });
  testWidgets(
    'chapter properties are available before collapse and local expansion is source-neutral',
    (tester) async {
      var source = '';
      await mount(
        tester,
        BusyMarkWysiwygEditor(
          document: _document(
            true,
            source:
                '<topic id="a" title="Title"><chapter title="Chapter" id="chapter"><p>Nested</p></chapter></topic>',
          ),
          onSourceChanged: (_, s) => source = s,
        ),
      );
      await tester.tap(_textField('Chapter'));
      await tester.pumpAndSettle();
      expect(find.text('Collapsible'), findsOneWidget);
      expect(source, isEmpty);
      final switchRow = find.byWidgetPredicate(
        (w) => w is BusyMarkSwitchRow && w.title == 'Collapsible',
      );
      await tester.tap(switchRow);
      await tester.pumpAndSettle();
      expect(source, contains('collapsible="true"'));
      final before = source;
      await tester.tap(find.byTooltip('Expand Chapter'));
      await tester.pumpAndSettle();
      expect(source, before);
      await tester.tap(_textField('Nested'));
      await tester.pumpAndSettle();
      final props = tester.widget<BusyMarkWritersideProperties>(
        find.byType(BusyMarkWritersideProperties),
      );
      expect(props.target!.plainText, 'Nested');
      expect(props.path.map((b) => b.attributes['element']), [
        'topic',
        'chapter',
        'p',
      ]);
    },
  );
  testWidgets('stale native response cannot edit the switched buffer', (
    tester,
  ) async {
    final result = Completer<int?>();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) => call.method == 'show' ? result.future : Future.value(true),
    );
    var edits = 0;
    Widget editor(String id) => _app(
      BusyMarkWysiwygEditor(
        document: _document(true),
        documentId: id,
        onSourceChanged: (_, _) => edits++,
      ),
    );
    await tester.pumpWidget(editor('first'));
    await tester.pumpAndSettle();
    await tester.tap(_textField('Text'));
    await tester.tap(find.byKey(const ValueKey('wysiwyg-writerside-insert')));
    await tester.pump();
    await tester.pumpWidget(editor('second'));
    await tester.pumpAndSettle();
    result.complete(0);
    await tester.pumpAndSettle();
    expect(edits, 0);
  });
  testWidgets(
    'XML source navigation finds repeated semantic text after real edits and reveals local content',
    (tester) async {
      const source =
          '<topic id="a" title="Title"><chapter title="Chapter" collapsible="true"><p>Save <!-- Save --> <control>Save</control></p></chapter></topic>';
      final document = _document(true, source: source);
      var saved = '';
      BusyMarkWysiwygEditor editor(int request, int offset) =>
          BusyMarkWysiwygEditor(
            document: document,
            documentId: 'same',
            scrollRequest: request,
            scrollToSourceRange: BusyMarkWysiwygSourceRange(
              startOffset: offset,
              endOffset: offset + 4,
            ),
            onSourceChanged: (_, s) => saved = s,
          );
      await mount(tester, editor(1, source.indexOf('<control>') + 9));
      expect(saved, isEmpty);
      final field = _textField('Save  Save');
      expect(
        tester.widget<TextField>(field).controller!.selection,
        const TextSelection(baseOffset: 6, extentOffset: 10),
      );
      await tester.enterText(field, 'Before Save  Save');
      await tester.pumpAndSettle();
      expect(saved, contains('<control>Save</control>'));
      final afterEdit = saved;
      await tester.pumpWidget(_app(editor(2, saved.indexOf('<control>') + 9)));
      await tester.pumpAndSettle();
      final updated = _textField('Before Save  Save');
      expect(
        tester.widget<TextField>(updated).controller!.selection,
        const TextSelection(baseOffset: 13, extentOffset: 17),
      );
      expect(saved, afterEdit);
    },
  );
  for (final xml in [false, true]) {
    testWidgets(
      '${xml ? 'XML' : 'Markdown'} contextual list conversion preserves hierarchy and is one undo action',
      (tester) async {
        final source = xml
            ? '<topic id="a" title="Title"><list type="decimal"><li><p>First</p><list type="bullet"><li><p>Choice</p></li></list></li><li><p>Second</p></li></list></topic>'
            : '# Title\n\n1. First\n   - Choice\n2. Second\n';
        var saved = '';
        await mount(
          tester,
          BusyMarkWysiwygEditor(
            document: _document(xml, source: source),
            onSourceChanged: (_, s) => saved = s,
          ),
        );
        await tester.tap(_textField('First'));
        await insert(tester, 'Convert List to Procedure');
        expect(saved, contains('<procedure'));
        expect(saved, contains('First'));
        expect(saved, contains('Choice'));
        expect(saved, contains('Second'));
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pumpAndSettle();
        expect(saved, source);
      },
    );
  }
  testWidgets(
    'code properties preserve source attributes, keep their target and undo together',
    (tester) async {
      const original =
          '<topic id="a" title="Title"><chapter title="Chapter"><code-block lang="dart" src="sample.dart" id="code" instance="web">print(1);</code-block><p>Other</p></chapter></topic>';
      var saved = '';
      await mount(
        tester,
        BusyMarkWysiwygEditor(
          document: _document(true, source: original),
          onSourceChanged: (_, s) => saved = s,
        ),
      );
      final field = find.byWidgetPredicate(
        (w) => w is TextField && w.controller?.text == 'print(1);',
      );
      await tester.tap(field);
      await tester.pumpAndSettle();
      final props = tester.widget<BusyMarkWritersideProperties>(
        find.byType(BusyMarkWritersideProperties),
      );
      expect(props.target!.attributes['id'], 'code');
      final entry = find.byKey(
        ValueKey('writerside-property-${props.target!.id}-language'),
      );
      final language = find.descendant(
        of: entry,
        matching: find.byType(TextField),
      );
      await tester.enterText(language, 'kotlin');
      await tester.pumpAndSettle();
      expect(saved, isEmpty);
      expect(
        tester
            .widget<BusyMarkWritersideProperties>(
              find.byType(BusyMarkWritersideProperties),
            )
            .target!
            .attributes['id'],
        'code',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(saved, contains('lang="kotlin"'));
      expect(saved, contains('src="sample.dart"'));
      expect(saved, contains('instance="web"'));
      await tester.tap(field);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(saved, original);
    },
  );
  testWidgets(
    'a property draft cannot apply to a replacement element in the same buffer',
    (tester) async {
      const first =
          '<topic id="a" title="Title"><code-block lang="dart" id="old">print(1);</code-block></topic>';
      const replaced =
          '<topic id="a" title="Title"><code-block lang="sql" id="replacement">SELECT 1;</code-block></topic>';
      var edits = 0;
      BusyMarkWysiwygEditor editor(String source) => BusyMarkWysiwygEditor(
        document: _document(true, source: source),
        documentId: 'same-buffer',
        initialSessionState: const WysiwygEditorSessionState(
          activeBlockId: 'xml-1',
        ),
        onSourceChanged: (_, _) => edits++,
      );
      await mount(tester, editor(first));
      final property = find.byKey(
        const ValueKey('writerside-property-xml-1-language'),
      );
      final entry = find.descendant(
        of: property,
        matching: find.byType(TextField),
      );
      await tester.enterText(entry, 'python');
      await tester.pumpAndSettle();
      expect(edits, 0);
      await tester.pumpWidget(_app(editor(replaced)));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(entry).controller!.text, 'sql');
      expect(edits, 0);
    },
  );
  for (final direction in EditorToolbarDirection.values) {
    testWidgets(
      'narrow dark RTL scaled $direction authoring controls remain usable',
      (tester) async {
        tester.view.physicalSize = const Size(620, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          _app(
            BusyMarkWysiwygEditor(
              document: _document(true),
              toolbarDirection: direction,
              onSourceChanged: (_, _) {},
            ),
            brightness: Brightness.dark,
            direction: TextDirection.rtl,
            scale: 1.5,
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('wysiwyg-writerside-group')),
          findsOneWidget,
        );
        expect(find.byType(BusyMarkWritersideProperties), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
