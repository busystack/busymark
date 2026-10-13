import 'dart:async';
import 'dart:io';

import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/editor/wysiwyg/writerside_editing_adapter.dart';
import 'package:busymark/src/editor/wysiwyg/writerside_properties.dart';
import 'package:busymark/src/editor/wysiwyg/writerside_inspector_target.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_inline_controller.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_session_state.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/platform/native_menu_service.dart';
import 'package:busymark/src/writerside/writerside_project.dart';
import 'package:busymark/src/writerside/writerside_effective_properties.dart';
import 'package:busymark/src/writerside/writerside_model.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_document_controller.dart';
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
  testWidgets(
    'navigation selection represents authored declarations after reopening',
    (tester) async {
      var c = BusyMarkWysiwygDocumentController(document: _document(true));
      addTearDown(() => c.dispose());
      Future<BusyMarkComboRow<String>> show() async {
        final document = c.document;
        await tester.pumpWidget(
          _app(
            BusyMarkWritersideProperties(
              document: document,
              target: document.blocks.first,
              path: [document.blocks.first],
              topicSelected: true,
              onClose: () {},
              onTargetSelected: (_) {},
              onProperty: (_, _) => true,
              onHeadingText: (_) => true,
              onTopicProperty: (name, value) => name == '@navigation'
                  ? value == 'default'
                        ? c.resetTopicNavigation()
                        : value == 'none'
                        ? c.updateTopicNavigation('for', 'none')
                        : c.resetTopicNavigation() &&
                              c.updateTopicNavigation('for', '')
                  : c.updateTopicNavigation(name, value),
              onManageItem: (_, _, _) {},
            ),
          ),
        );
        final section = find.widgetWithText(ListTile, 'Topic navigation');
        if (find
            .byWidgetPredicate(
              (w) => w is BusyMarkComboRow<String> && w.values.contains('all'),
            )
            .evaluate()
            .isEmpty) {
          await tester.ensureVisible(section);
          await tester.tap(section);
          await tester.pumpAndSettle();
        }
        return tester.widget<BusyMarkComboRow<String>>(
          find.byWidgetPredicate(
            (w) => w is BusyMarkComboRow<String> && w.values.contains('all'),
          ),
        );
      }

      for (final option in ['all', 'none', 'default']) {
        (await show()).onSelected(option);
        final saved = c.markdown;
        c.dispose();
        c = BusyMarkWysiwygDocumentController(
          document: _document(true, source: saved),
        );
        expect((await show()).selected, option, reason: saved);
      }
      expect(c.updateTopicNavigation('for', 'chapter,def'), isTrue);
      final saved = c.markdown;
      c.dispose();
      c = BusyMarkWysiwygDocumentController(
        document: _document(true, source: saved),
      );
      expect((await show()).selected, 'custom');
    },
  );
  testWidgets('definition layout displays module default and reset origin', (
    tester,
  ) async {
    final c = BusyMarkWysiwygDocumentController(
      document: _document(
        true,
        source:
            '<topic id="a" title="Title"><deflist type="wide"><def title="Term"><p>Body</p></def></deflist></topic>',
      ),
    );
    addTearDown(c.dispose);
    const effective = WritersideEffectiveProperties(
      settings: WritersideSettingsConfig(
        defaultProperties: [
          WritersideDefaultProperty(
            elementName: 'deflist',
            propertyName: 'type',
            value: 'medium',
          ),
        ],
      ),
    );
    Future<BusyMarkComboRow<String>> show() async {
      final document = _document(true, source: c.markdown);
      final list = document.blocks.first.children.single;
      await tester.pumpWidget(
        _app(
          BusyMarkWritersideProperties(
            document: document,
            target: list,
            path: [document.blocks.first, list],
            topicSelected: false,
            effectiveProperties: effective,
            onClose: () {},
            onTargetSelected: (_) {},
            onProperty: (name, value) => c.updateWritersideProperty(
              c.document.blocks.first.children.single.id,
              name,
              value,
            ),
            onHeadingText: (_) => true,
            onTopicProperty: (_, _) => true,
            onManageItem: (_, _, _) {},
          ),
        ),
      );
      return tester.widget<BusyMarkComboRow<String>>(
        find.byWidgetPredicate(
          (w) =>
              w is BusyMarkComboRow<String> && w.title == 'List layout (type)',
        ),
      );
    }

    final layout = await show();
    expect(layout.selected, 'wide');
    expect(layout.labelFor(''), 'Use default');
    layout.onSelected('');
    final reset = await show();
    expect(reset.selected, '');
    expect(reset.labelFor(''), 'Use default');
    expect(c.markdown, isNot(contains('type=')));
    expect(
      find.byWidgetPredicate(
        (w) => w is Text && w.data == 'Default: Medium (1:2) · Module',
      ),
      findsOneWidget,
    );
    expect(reset.tooltip, 'Effective: Medium (1:2) — module default');
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.hint == 'Effective: Medium (1:2) — module default',
      ),
      findsOneWidget,
    );
  });
  testWidgets('XML title control retains authored absence and child title', (
    tester,
  ) async {
    final document = _document(
      true,
      source:
          '<topic id="a" title="Topic"><chapter id="c"><title instance="web">Install <b>now</b></title><p>Body</p></chapter></topic>',
    );
    final chapter = document.blocks.first.children.single;
    String? committedName;
    String? committedValue;
    await tester.pumpWidget(
      _app(
        BusyMarkWritersideProperties(
          document: document,
          target: chapter,
          path: [document.blocks.first, chapter],
          topicSelected: false,
          onClose: () {},
          onTargetSelected: (_) {},
          onProperty: (name, value) {
            committedName = name;
            committedValue = value;
            return true;
          },
          onHeadingText: (_) => throw StateError('XML title is an attribute'),
          onTopicProperty: (_, _) => true,
          onManageItem: (_, _, _) => true,
        ),
      ),
    );
    final field = find.descendant(
      of: find.byKey(
        ValueKey('writerside-property-a.topic-element-${chapter.id}-title'),
      ),
      matching: find.byType(TextField),
    );
    expect(field, findsOneWidget);
    expect(tester.widget<TextField>(field).controller!.text, isEmpty);
    await tester.enterText(field, 'Default title');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(committedName, 'title');
    expect(committedValue, 'Default title');
    expect(chapter.children.first.attributes['instance'], 'web');
    expect(chapter.children.first.rawSource, contains('<b>now</b>'));
  });

  testWidgets('inactive published values remain inspectable and removable', (
    tester,
  ) async {
    final document = _document(
      true,
      source:
          '<topic id="a" title="Topic"><code-block collapsible="false" default-state="expanded" collapsed-title="Details">code</code-block></topic>',
    );
    final code = document.blocks.first.children.single;
    final removed = <String>[];
    await tester.pumpWidget(
      _app(
        BusyMarkWritersideProperties(
          document: document,
          target: code,
          path: [document.blocks.first, code],
          topicSelected: false,
          onClose: () {},
          onTargetSelected: (_) {},
          onProperty: (name, value) {
            if (value == null) removed.add(name);
            return true;
          },
          onHeadingText: (_) => true,
          onTopicProperty: (_, _) => true,
          onManageItem: (_, _, _) => true,
        ),
      ),
    );
    final state = tester.widget<BusyMarkComboRow<String>>(
      find.byWidgetPredicate(
        (w) =>
            w is BusyMarkComboRow<String> &&
            w.title == 'Published initial state (default-state)',
      ),
    );
    expect(state.enabled, isFalse);
    expect(state.selected, 'expanded');
    final title = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(
          ValueKey(
            'writerside-property-a.topic-element-${code.id}-collapsed-title',
          ),
        ),
        matching: find.byType(TextField),
      ),
    );
    expect(title.readOnly, isTrue);
    expect(title.controller!.text, 'Details');
    final reset = find.byWidgetPredicate(
      (w) => w is BusyMarkHeaderIconButton && w.tooltip == 'Use default',
    );
    expect(reset, findsNWidgets(2));
    tester.widget<BusyMarkHeaderIconButton>(reset.first).onPressed!();
    tester.widget<BusyMarkHeaderIconButton>(reset.last).onPressed!();
    expect(removed, ['default-state', 'collapsed-title']);
  });

  testWidgets(
    'reset option describes the default after removing a local override',
    (tester) async {
      final document = const WritersideEditingAdapter().parseXml(
        filePath: 't.topic',
        source:
            '<topic id="t" title="Topic"><code-block collapsible="true" default-state="expanded"/></topic>',
      )!;
      final code = document.blocks.first.children.single;
      await tester.pumpWidget(
        _app(
          BusyMarkWritersideProperties(
            document: document,
            target: code,
            path: [document.blocks.first, code],
            topicSelected: false,
            onClose: () {},
            onTargetSelected: (_) {},
            onProperty: (_, _) => true,
            onHeadingText: (_) => true,
            onTopicProperty: (_, _) => true,
            onManageItem: (_, _, _) => true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final collapse = tester.widget<BusyMarkComboRow<String>>(
        find.byWidgetPredicate(
          (w) =>
              w is BusyMarkComboRow<String> &&
              w.title == 'Collapsible (collapsible)',
        ),
      );
      final state = tester.widget<BusyMarkComboRow<String>>(
        find.byWidgetPredicate(
          (w) =>
              w is BusyMarkComboRow<String> &&
              w.title == 'Published initial state (default-state)',
        ),
      );
      expect(collapse.selected, 'true');
      expect(collapse.labelFor(''), 'Use default');
      expect(state.selected, 'expanded');
      expect(state.labelFor(''), 'Use default');
    },
  );

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
  Future<void> mount(
    WidgetTester tester,
    BusyMarkWysiwygEditor editor, {
    bool openProperties = true,
  }) async {
    tester.view.resetPhysicalSize();
    tester.view.physicalSize = const Size(1100, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(editor));
    await tester.pumpAndSettle();
    if (openProperties) {
      await tester.tap(find.byTooltip('Element Properties').first);
      await tester.pumpAndSettle();
    }
  }

  testWidgets(
    'selection leaves the inspector closed and hosted language opens the workspace target',
    (tester) async {
      final doc = _document(
        true,
        source:
            '<topic id="a" title="Title"><code-block lang="dart">print(1);</code-block></topic>',
      );
      var opened = 0;
      String? inspected;
      var explicit = false;
      await mount(
        tester,
        BusyMarkWysiwygEditor(
          document: doc,
          onSourceChanged: (_, _) {},
          onInspectElement:
              (_, id, _, requested, multiple, {bool revisionRefresh = false}) {
                inspected = id;
                explicit = requested;
              },
          onPropertiesRequested: () => opened++,
        ),
        openProperties: false,
      );
      await tester.tap(_textField('print(1);'));
      await tester.pumpAndSettle();
      expect(find.byType(BusyMarkWritersideProperties), findsNothing);
      expect(opened, 0);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(opened, 1);
      expect(explicit, isTrue);
      expect(inspected, doc.blocks.first.children.single.id);
      expect(find.byType(BusyMarkWritersideProperties), findsNothing);
    },
  );
  testWidgets(
    'shortcut action edits preserve literal content through undo redo and reopen',
    (tester) async {
      const original =
          '<topic id="a" title="Title"><p>Press <shortcut key="\$Save">Ctrl+S</shortcut> <b>now</b>.</p></topic>';
      var saved = original;
      await mount(
        tester,
        BusyMarkWysiwygEditor(
          document: _document(true, source: original),
          onSourceChanged: (_, source) => saved = source,
        ),
      );
      final body = _textField('Press Ctrl+S now.');
      await tester.tap(body);
      tester.widget<TextField>(body).controller!.selection =
          const TextSelection.collapsed(offset: 8);
      await tester.pumpAndSettle();
      final entry = find.descendant(
        of: find.byWidgetPredicate(
          (w) => w is BusyMarkGroupedTextEntry && w.label == 'Action ID (key)',
        ),
        matching: find.byType(TextField),
      );
      await tester.enterText(entry, '\$Copy');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(saved, contains('key="\$Copy"'));
      expect(saved, contains('>Ctrl+S</shortcut>'));
      expect(saved, contains('<b>now</b>'));
      final changed = saved;
      await tester.tap(_textField('Press Ctrl+S now.'));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(saved, original);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(saved, changed);
      final reopened = _document(
        true,
        source: saved,
      ).blocks.first.children.single;
      expect(reopened.plainText, 'Press Ctrl+S now.');
      expect(
        busyInlineReferenceRanges(reopened.inlines)
            .firstWhere((r) => r.kind == BusyInlineKind.writersideShortcut)
            .attributes['key'],
        '\$Copy',
      );
    },
  );
  for (final xml in [true, false]) {
    testWidgets(
      '${xml ? "XML" : "Markdown"} inspector edits a complete mixed-format link through undo redo and reopen',
      (tester) async {
        final original = xml
            ? '<topic id="a" title="Title"><p>Before <a href="old.topic">Read <b>guide</b></a> and <a href="old.topic">Other</a>.</p></topic>'
            : '# Title\n\nBefore [Read **guide**][ref] and [Other][ref].\n\n[ref]: old.topic "Keep title"\n';
        var saved = original;
        await mount(
          tester,
          BusyMarkWysiwygEditor(
            document: _document(xml, source: original),
            onSourceChanged: (_, source) => saved = source,
          ),
        );
        final body = _textField('Before Read guide and Other.');
        await tester.tap(body);
        // Inside the unformatted segment, then inside the bold segment: both
        // selections expose the same owning link, without changing styling.
        for (final caret in [9, 15]) {
          tester
              .widget<TextField>(_textField('Before Read guide and Other.'))
              .controller!
              .selection = TextSelection.collapsed(
            offset: caret,
          );
          await tester.pumpAndSettle();
          expect(
            find.byWidgetPredicate(
              (w) =>
                  w is BusyMarkGroupedTextEntry &&
                  w.label == 'Link target (href)',
            ),
            findsOneWidget,
          );
        }
        final entry = find.descendant(
          of: find.byWidgetPredicate(
            (w) =>
                w is BusyMarkGroupedTextEntry &&
                w.label == 'Link target (href)',
          ),
          matching: find.byType(TextField),
        );
        await tester.enterText(entry, 'new.topic#details');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        expect(
          saved,
          contains(
            xml
                ? 'href="new.topic#details"'
                : '[Read **guide**](new.topic#details "Keep title")',
          ),
        );
        expect(saved, contains(xml ? 'Read <b>guide</b>' : 'Read **guide**'));
        expect(
          saved,
          contains(xml ? '<a href="old.topic">Other</a>' : '[Other][ref]'),
        );
        final changed = saved;
        await tester.tap(_textField('Before Read guide and Other.'));
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pumpAndSettle();
        expect(saved, original);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pumpAndSettle();
        expect(saved, changed);
        await tester.runAsync(() async {
          final dir = await Directory.systemTemp.createTemp('mixed-link-');
          try {
            final file = File('${dir.path}/a.${xml ? 'topic' : 'md'}');
            await file.writeAsString(saved);
            final reopened = BusyMarkWysiwygDocumentController(
              document: _document(xml, source: await file.readAsString()),
            );
            try {
              final block = xml
                  ? reopened.document.blocks.first.children.single
                  : reopened.document.blocks.firstWhere(
                      (b) => b.plainText.startsWith('Before'),
                    );
              final owners = busyInlineReferenceRanges(block.inlines);
              expect(owners, hasLength(2));
              expect(
                owners.first.end - owners.first.start,
                'Read guide'.length,
              );
              expect(owners.first.destination, 'new.topic#details');
              expect(
                busyInlineStyleRanges(
                  block.inlines,
                ).where((r) => r.kind == BusyInlineKind.link),
                hasLength(3),
              );
              final target = WritersideInspectorTarget.fromSelection(
                bufferId: 'b',
                revision: 2,
                source: saved,
                document: reopened.document,
                blockId: block.id,
                inline: owners.first,
              );
              final offset = saved.indexOf(xml ? '<a href' : '[Read');
              expect(target.sourceLocation, offset);
              final sourceTarget = WritersideInspectorTarget.fromSource(
                bufferId: 'b',
                revision: 2,
                source: saved,
                document: reopened.document,
                selection: TextSelection.collapsed(offset: offset + 3),
              );
              expect(sourceTarget.inline?.start, owners.first.start);
              expect(sourceTarget.inline?.end, owners.first.end);
            } finally {
              reopened.dispose();
            }
          } finally {
            await dir.delete(recursive: true);
          }
        });
      },
    );
  }
  Future<void> insert(WidgetTester tester, String label) async {
    await tester.pumpAndSettle();
    labels.add(label);
    await tester.tap(find.byKey(const ValueKey('wysiwyg-writerside-insert')));
    await tester.pumpAndSettle();
  }

  for (final xml in [false, true]) {
    testWidgets(
      '${xml ? 'XML' : 'Markdown'} canceled native menu restores editing focus and selection',
      (tester) async {
        final changes = <String>[];
        await mount(
          tester,
          BusyMarkWysiwygEditor(
            document: _document(xml),
            onSourceChanged: (_, source) => changes.add(source),
          ),
        );
        await tester.tap(_textField('Text'));
        final field = tester.widget<TextField>(_textField('Text'));
        const selection = TextSelection(baseOffset: 0, extentOffset: 4);
        field.controller!.selection = selection;
        await tester.pumpAndSettle();
        binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
          call,
        ) async {
          if (call.method == 'show') {
            // GTK owns keyboard focus while its menu is open. Its dismissal
            // returns a null selection without invoking a toolbar command.
            FocusManager.instance.primaryFocus?.unfocus();
            return null;
          }
          return true;
        });
        await tester.tap(
          find.byKey(const ValueKey('wysiwyg-writerside-insert')),
        );
        await tester.pumpAndSettle();
        expect(field.focusNode!.hasFocus, isTrue);
        expect(field.controller!.selection, selection);
        expect(changes, isEmpty);
      },
    );
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
            ValueKey(
              'writerside-property-a.${xml ? 'topic' : 'md'}-document-switcher-label',
            ),
          ),
          matching: find.byType(TextField),
        );
        if (entry().evaluate().isEmpty) {
          await tester.ensureVisible(find.widgetWithText(ListTile, 'Advanced'));
          await tester.tap(find.widgetWithText(ListTile, 'Advanced'));
          await tester.pumpAndSettle();
        }
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
        if (entry().evaluate().isEmpty) {
          await tester.tap(find.widgetWithText(ListTile, 'Advanced'));
          await tester.pumpAndSettle();
        }
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
    expect(find.text('Keyboard layout (force-layout)'), findsOneWidget);
    expect(find.text('List layout (type)'), findsNothing);
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
      expect(find.text('Collapsible (collapsible)'), findsOneWidget);
      expect(source, isEmpty);
      final collapseRow = tester.widget<BusyMarkComboRow<String>>(
        find.byWidgetPredicate(
          (w) =>
              w is BusyMarkComboRow<String> &&
              w.title == 'Collapsible (collapsible)',
        ),
      );
      collapseRow.onSelected('true');
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
  testWidgets('stale native cancellation cannot focus the switched buffer', (
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
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    result.complete(null);
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(_textField('Text')).focusNode!.hasFocus,
      isFalse,
    );
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
        ValueKey(
          'writerside-property-a.topic-element-${props.target!.id}-language',
        ),
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
      await tester.tap(_textField('print(1);'));
      await tester.pumpAndSettle();
      final property = find.byKey(
        const ValueKey('writerside-property-a.topic-element-xml-1-language'),
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
      expect(tester.widget<TextField>(entry).controller!.text, 'python');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('document or element changed'),
        findsOneWidget,
      );
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
        expect(find.text('Writerside'), findsNothing);
        expect(
          find.byKey(const ValueKey('wysiwyg-writerside-insert')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('wysiwyg-writerside-semantic')),
          findsOneWidget,
        );
        await tester.ensureVisible(
          find.byKey(const ValueKey('wysiwyg-writerside-properties')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('wysiwyg-writerside-properties')),
        );
        await tester.pumpAndSettle();
        expect(find.byType(BusyMarkWritersideProperties), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
