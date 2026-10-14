import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/editor/wysiwyg/writerside_editing_adapter.dart';
import 'package:busymark/src/editor/wysiwyg/writerside_inspector_target.dart';
import 'package:busymark/src/editor/wysiwyg/writerside_properties.dart';
import 'package:busymark/src/editor/wysiwyg/writerside_property_session.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_document_controller.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/writerside/writerside_schema.dart';
import 'package:busymark/src/writerside/writerside_parsers.dart';
import 'package:busymark/src/writerside/writerside_property_validation.dart';
import 'package:busymark/src/writerside/writerside_effective_properties.dart';
import 'package:busymark/src/writerside/writerside_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

BusyDocument parse(String source, {bool xml = true, String? file}) => xml
    ? const WritersideEditingAdapter().parseXml(
        filePath: file ?? 'identity.topic',
        source: source,
      )!
    : const MarkdownParser()
          .parse(
            filePath: file ?? 'identity.md',
            source: source,
            mode: MarkdownMode.writersideMarkdown,
            validateLocalReferences: false,
          )
          .busyDocument;
Iterable<BusyBlock> walk(List<BusyBlock> blocks) sync* {
  for (final block in blocks) {
    yield block;
    yield* walk(block.children);
  }
}

Finder entry(String label) => find.descendant(
  of: find.byWidgetPredicate(
    (w) => w is BusyMarkGroupedTextEntry && w.label == label,
  ),
  matching: find.byType(TextField),
);
Future<void> edit(WidgetTester tester, String label, String value) async {
  await tester.ensureVisible(entry(label));
  await tester.enterText(entry(label), value);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}

Future<void> section(WidgetTester tester, String title) async {
  final tile = find.byWidgetPredicate(
    (w) => w is TextButton && w.key == ValueKey('writerside-disclosure-$title'),
  );
  await tester.ensureVisible(tile);
  await tester.tap(tile);
  await tester.pumpAndSettle();
}

List<String> fields(WidgetTester tester) => tester
    .widgetList<BusyMarkGroupedTextEntry>(find.byType(BusyMarkGroupedTextEntry))
    .map((w) => w.label)
    .toList();

void main() {
  for (final rtl in [false, true]) {
    testWidgets(
      'minimum-width scaled enum units retain values, help and native editing (RTL=$rtl)',
      (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final c = BusyMarkWysiwygDocumentController(
          document: parse('# Topic\n\n## Chapter\n', xml: false),
        );
        final session = WritersidePropertySession();
        addTearDown(c.dispose);
        addTearDown(session.dispose);
        final original = c.markdown;
        await tester.pumpWidget(
          harness(
            c,
            session,
            'chapter',
            width: 260,
            direction: rtl ? TextDirection.rtl : TextDirection.ltr,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Collapsible (collapsible)'), findsOneWidget);
        expect(find.text('Use default'), findsOneWidget);
        expect(find.text('Default: Disabled'), findsOneWidget);
        final caption = tester.getRect(find.text('Collapsible (collapsible)'));
        final value = tester.getRect(find.text('Use default'));
        expect(value.top, greaterThanOrEqualTo(caption.bottom));
        expect(value.width, lessThanOrEqualTo(228));
        expect(tester.takeException(), isNull);
        final hints = tester
            .widgetList<Semantics>(find.byType(Semantics))
            .map((w) => w.properties.hint ?? '')
            .join('\n');
        expect(hints, contains('Effective: Disabled — built-in default'));
        expect(c.markdown, original);
        await tester.tap(find.text('Collapsible (collapsible)'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Enabled'));
        await tester.pumpAndSettle();
        expect(c.markdown, contains('collapsible="true"'));
        expect(c.document.blocks.last.attributes['collapsible'], 'true');
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final sample in [
    (true, 'topic', '<topic id="identity" title="Default"/>', false),
    (
      true,
      'topic',
      '<topic id="identity" title="Default" help-id="help"/>',
      true,
    ),
    (
      true,
      'chapter',
      '<topic id="identity" title="Default"><chapter id="chapter" title="Chapter"/></topic>',
      false,
    ),
    (
      true,
      'p',
      '<topic id="identity" title="Default" switcher-label="Other"><p id="p">Body</p></topic>',
      false,
    ),
    (false, 'topic', '# Topic\n\nBody\n', false),
    (false, 'topic', '---\nswitcher-label: Output\n---\n# Topic\n', true),
    (
      false,
      'chapter',
      '---\nswitcher-label: Other\n---\n# Topic\n\n## Chapter\n',
      false,
    ),
    (false, 'topic', '# Topic {id="explicit"}\n', true),
    (false, 'chapter', '# Topic\n\n## Chapter {title="Override"}\n', true),
    (
      true,
      'topic',
      '<topic id="identity" title="Default" unknown="preserved"/>',
      true,
    ),
  ]) {
    testWidgets('Advanced status follows authored owner: $sample', (
      tester,
    ) async {
      final c = BusyMarkWysiwygDocumentController(
        document: parse(sample.$3, xml: sample.$1),
      );
      final session = WritersidePropertySession();
      addTearDown(c.dispose);
      addTearDown(session.dispose);
      final original = c.markdown;
      await tester.pumpWidget(harness(c, session, sample.$2));
      await tester.pumpAndSettle();
      expect(
        find.text('Authored settings present'),
        sample.$4 ? findsOneWidget : findsNothing,
      );
      await section(tester, 'Advanced');
      expect(c.markdown, original);
      expect(session.hasPending, isFalse);
      // Dividers separate property units, never plain captions or notices.
      for (final group in tester.widgetList<BusyMarkGroupedList>(
        find.byType(BusyMarkGroupedList),
      )) {
        expect(
          group.children.any((w) => w is Text || w is TextButton),
          isFalse,
        );
      }
      if (sample.$2 == 'topic') {
        final groups = tester.widgetList<BusyMarkGroupedList>(
          find.byType(BusyMarkGroupedList),
        );
        expect(
          groups.where((g) => g.title == 'Document settings'),
          hasLength(1),
        );
        expect(
          groups.where((g) => g.title == 'Heading attributes'),
          sample.$1 ? isEmpty : hasLength(1),
        );
        final identity = tester.widget<BusyMarkActionRow>(
          find.byWidgetPredicate(
            (w) => w is BusyMarkActionRow && w.title == 'Topic ID',
          ),
        );
        expect(identity.onTap, isNull);
        expect(identity.subtitleWidget, isA<SelectableText>());
        final details = find.text(
          'The pinned builder does not publish topic H1 attributes: inline attributes render literally and separate-line attributes are ignored. These belong to the heading, not the XML root.',
        );
        expect(details, findsNothing);
        if (!sample.$1) {
          expect(find.text('Not published by this builder.'), findsWidgets);
          final hints = tester
              .widgetList<Semantics>(find.byType(Semantics))
              .map((w) => w.properties.hint ?? '')
              .join('\n');
          expect(
            hints,
            contains('These belong to the heading, not the XML root.'),
          );
        }
      }
    });
  }
  testWidgets(
    'mixed native item properties explain protection and keep parent access',
    (tester) async {
      final c = BusyMarkWysiwygDocumentController(
        document: parse('# Topic\n\n- [x] Done\n- Plain\n', xml: false),
      );
      final session = WritersidePropertySession();
      addTearDown(c.dispose);
      addTearDown(session.dispose);
      final original = c.markdown;
      await tester.pumpWidget(harness(c, session, 'li'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'This element is protected. Edit its source to change properties.',
        ),
        findsOneWidget,
      );
      expect(
        tester.widget<TextField>(entry('Element anchor (id)')).readOnly,
        isTrue,
      );
      final selector = tester.widget<BusyMarkComboRow<String>>(
        find.byWidgetPredicate(
          (w) => w is BusyMarkComboRow<String> && w.title == 'Element',
        ),
      );
      expect(selector.values, contains(c.document.blocks[1].id));
      expect(c.markdown, original);
      expect(session.hasPending, isFalse);
    },
  );
  for (final format in ['xml', 'embedded', 'native']) {
    testWidgets(
      '$format list form edits the container and retains item ownership',
      (tester) async {
        final c = BusyMarkWysiwygDocumentController(
          document: parse(
            format == 'xml'
                ? '<topic id="identity" title="Topic"><list type="decimal" start="7"><li id="item"><p>Item</p></li></list></topic>'
                : format == 'embedded'
                ? '# Topic\n\n<list type="decimal" start="7"><li id="item"><p>Item</p></li></list>\n'
                : '# Topic\n\n7. Item\n8. Sibling\n',
            xml: format == 'xml',
          ),
        );
        final session = WritersidePropertySession();
        addTearDown(c.dispose);
        addTearDown(session.dispose);
        await tester.pumpWidget(harness(c, session, 'list'));
        await tester.pumpAndSettle();
        expect(fields(tester).toSet(), {
          'Element anchor (id)',
          'Starting number (start)',
          'Columns (columns)',
        });
        final types = tester.widget<BusyMarkComboRow<String>>(
          find.byWidgetPredicate(
            (w) =>
                w is BusyMarkComboRow<String> && w.title == 'List type (type)',
          ),
        );
        expect(types.values.toSet(), {
          '',
          'bullet',
          'decimal',
          'alpha-lower',
          'checkbox',
          'none',
        });
        expect(types.labelFor('alpha-lower'), 'Lettered list');
        expect(types.labelFor('checkbox'), 'Checkbox list');
        final original = c.markdown;
        expect(entry('Filter (filter)'), findsNothing);
        await section(tester, 'Advanced');
        expect(entry('Filter (filter)'), findsOneWidget);
        expect(entry('Help instances (instance)'), findsOneWidget);
        expect(c.markdown, original);
        await edit(tester, 'Element anchor (id)', 'list-anchor');
        await edit(tester, 'Columns (columns)', '2');
        final owner = walk(
          c.document.blocks,
        ).singleWhere((b) => b.attributes['element'] == 'list');
        expect(owner.attributes['id'], 'list-anchor');
        expect(owner.attributes['columns'], '2');
        expect(
          owner.children.first.attributes['id'],
          format == 'native' ? isNull : 'item',
        );
        final reopened = parse(c.markdown, xml: format == 'xml');
        final saved = walk(
          reopened.blocks,
        ).singleWhere((b) => b.attributes['element'] == 'list');
        expect(saved.attributes['id'], 'list-anchor');
        expect(saved.attributes['columns'], '2');
        expect(
          saved.children.first.plainText,
          format == 'native' ? 'Item' : '',
        );
        if (format == 'native') expect(c.markdown, isNot(contains('<list')));
      },
    );
  }
  testWidgets(
    'Advanced survives a temporary stale-target view and stays bound to its document',
    (tester) async {
      final c = BusyMarkWysiwygDocumentController(
        document: parse('# Topic\n\n## Heading\n', xml: false),
      );
      final session = WritersidePropertySession();
      final bucket = PageStorageBucket();
      addTearDown(c.dispose);
      addTearDown(session.dispose);
      final target = c.document.blocks[1];
      Future<void> show({
        bool visible = true,
        String identity = 'buffer-a',
      }) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: PageStorage(
                bucket: bucket,
                child: visible
                    ? BusyMarkWritersideProperties(
                        documentIdentity: identity,
                        document: c.document,
                        path: c.elementPath(target.id),
                        target: target,
                        topicSelected: false,
                        session: session,
                        onTargetSelected: (_) {},
                        onClose: () {},
                        onProperty: (_, _) => true,
                        onHeadingText: (_) => true,
                        onTopicProperty: (_, _) => true,
                        onManageItem: (_, _, _) {},
                      )
                    : const Text('Selection unavailable'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      Finder caps() => find.byWidgetPredicate(
        (w) =>
            w is BusyMarkComboRow<String> && w.title == 'Capitalization (caps)',
      );
      await show();
      expect(caps(), findsNothing);
      await section(tester, 'Advanced');
      expect(caps(), findsOneWidget);
      expect(
        tester.widget<BusyMarkComboRow<String>>(caps()).subtitle,
        'Default: As written',
      );
      await show(visible: false);
      expect(find.text('Selection unavailable'), findsOneWidget);
      await show();
      expect(caps(), findsOneWidget);
      await show(identity: 'buffer-b');
      expect(caps(), findsNothing);
      await show();
      expect(caps(), findsOneWidget);
      expect(c.markdown, '# Topic\n\n## Heading\n');
    },
  );
  testWidgets(
    'normal H2 presentation keeps generated anchor derived through focus, help, save and overrides',
    (tester) async {
      const heading = '2. Diagnosed cause and source map';
      const source = '# Topic\n\n## $heading\n\nBody.\n';
      final c = BusyMarkWysiwygDocumentController(
        document: parse(source, xml: false),
      );
      final session = WritersidePropertySession();
      addTearDown(c.dispose);
      addTearDown(session.dispose);
      Future<void> show() async {
        await tester.pumpWidget(harness(c, session, 'chapter'));
        await tester.pumpAndSettle();
      }

      await show();
      final selector = tester.widget<BusyMarkComboRow<String>>(
        find.byWidgetPredicate(
          (w) => w is BusyMarkComboRow<String> && w.title == 'Element',
        ),
      );
      expect(selector.labelFor(selector.selected), 'Chapter');
      expect(
        find.text('Select a single element to inspect its properties.'),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('writerside-properties-identity')),
        findsNothing,
      );
      expect(fields(tester), ['Heading text', 'Element anchor (id)']);
      expect(
        tester.widget<TextField>(entry('Element anchor (id)')).controller!.text,
        isEmpty,
      );
      expect(
        find.text('Generated anchor; setting a value authors an override.'),
        findsNothing,
      );
      final generated = find.byKey(
        const ValueKey('writerside-generated-anchor'),
      );
      expect(
        tester.widget<SelectableText>(generated).data,
        'Generated: 2-diagnosed-cause-and-source-map',
      );
      final group = tester
          .element(generated)
          .findAncestorWidgetOfExactType<BusyMarkGroupedList>()!;
      expect(group.children.whereType<SelectableText>(), isEmpty);
      expect(group.children.whereType<Text>(), isEmpty);
      await tester.tap(entry('Element anchor (id)'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.f1);
      await tester.pump();
      expect(
        find.text('Generated anchor; setting a value authors an override.'),
        findsOneWidget,
      );
      expect(session.flush(), isTrue);
      expect(c.markdown, source);
      await tester.pump(const Duration(seconds: 3));
      await tester.tap(entry('Heading text'));
      await tester.pumpAndSettle();
      expect(c.markdown, source);
      await section(tester, 'Advanced');
      await section(tester, 'Advanced');
      expect(c.markdown, source);
      await edit(tester, 'Element anchor (id)', 'cause-map');
      expect(c.markdown, contains('id="cause-map"'));
      expect(generated, findsNothing);
      await edit(tester, 'Element anchor (id)', '');
      expect(c.markdown, source);
      // The workspace reparses published source before exposing derived IDs.
      c.replaceDocument(parse(c.markdown, xml: false));
      await show();
      expect(generated, findsOneWidget);
      final reopened = BusyMarkWysiwygDocumentController(
        document: parse(c.markdown, xml: false),
      );
      addTearDown(reopened.dispose);
      await tester.pumpWidget(harness(reopened, session, 'chapter'));
      await tester.pumpAndSettle();
      expect(generated, findsOneWidget);
      expect(reopened.markdown, source);
    },
  );
  testWidgets(
    'long generated anchor wraps at minimum and desktop widths with text scaling',
    (tester) async {
      final longHeading = List.filled(14, 'documentation').join(' ');
      final c = BusyMarkWysiwygDocumentController(
        document: parse('# Topic\n\n## $longHeading\n', xml: false),
      );
      final session = WritersidePropertySession();
      addTearDown(c.dispose);
      addTearDown(session.dispose);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      tester.view.devicePixelRatio = 1;
      for (final width in [260.0, 390.0]) {
        tester.view.physicalSize = Size(width, 1500);
        tester.platformDispatcher.textScaleFactorTestValue = 1.6;
        await tester.pumpWidget(harness(c, session, 'chapter'));
        await tester.pumpAndSettle();
        final generated = find.byKey(
          const ValueKey('writerside-generated-anchor'),
        );
        await tester.ensureVisible(generated);
        final text = tester.widget<SelectableText>(generated);
        expect(
          text.data,
          'Generated: ${List.filled(14, 'documentation').join('-')}',
        );
        expect(text.maxLines, isNull);
        expect(tester.getSize(generated).height, greaterThan(32));
        expect(tester.takeException(), isNull);
        expect(c.markdown, isNot(contains('id=')));
      }
    },
  );
  testWidgets(
    'effective subtitles are compact and provenance remains in semantics',
    (tester) async {
      final semantics = tester.ensureSemantics();
      const module = WritersideEffectiveProperties(
        settings: WritersideSettingsConfig(
          defaultProperties: [
            WritersideDefaultProperty(
              elementName: 'chapter',
              propertyName: 'collapsible',
              value: 'true',
            ),
          ],
        ),
      );
      for (final row in [
        (
          attrs: '',
          effective: const WritersideEffectiveProperties(),
          selected: '',
          summary: 'Default: Disabled',
          origin: 'built-in default',
        ),
        (
          attrs: '',
          effective: module,
          selected: '',
          summary: 'Default: Enabled · Module',
          origin: 'module default',
        ),
        (
          attrs: ' collapsible="true"',
          effective: module,
          selected: 'true',
          summary: null,
          origin: 'element override',
        ),
        (
          attrs: ' collapsible="%collapse%"',
          effective: const WritersideEffectiveProperties(
            variables: {'collapse': 'true'},
          ),
          selected: '%collapse%',
          summary: 'Resolved: Enabled',
          origin: 'element override',
        ),
        (
          attrs: ' collapsible="%unknown%"',
          effective: const WritersideEffectiveProperties(),
          selected: '%unknown%',
          summary: 'Unresolved',
          origin: 'unresolved',
        ),
      ]) {
        final c = BusyMarkWysiwygDocumentController(
          document: parse(
            '<topic id="identity" title="Topic"><chapter title="Chapter"${row.attrs}><p>Body</p></chapter></topic>',
          ),
        );
        final session = WritersidePropertySession();
        await tester.pumpWidget(
          harness(c, session, 'chapter', effective: row.effective),
        );
        await tester.pumpAndSettle();
        final finder = find.byWidgetPredicate(
          (w) =>
              w is BusyMarkComboRow<String> &&
              w.title == 'Collapsible (collapsible)',
        );
        final combo = tester.widget<BusyMarkComboRow<String>>(finder);
        expect(combo.selected, row.selected);
        expect(combo.subtitle, row.summary);
        expect(combo.labelFor(''), 'Use default');
        expect(combo.tooltip, contains(row.origin));
        expect(
          tester.getSemantics(finder).getSemanticsData().hint,
          contains(row.origin),
        );
        expect(
          find.byWidgetPredicate(
            (w) => w is Text && w.data?.startsWith('Effective:') == true,
          ),
          findsNothing,
        );
        await tester.pumpWidget(const SizedBox());
        session.dispose();
        c.dispose();
      }
      final c = BusyMarkWysiwygDocumentController(
        document: parse(
          '<topic id="identity" title="Topic"><deflist collapsible="true" default-state="expanded"><def title="Term" default-state="inherited"><p>Body</p></def></deflist></topic>',
        ),
      );
      final session = WritersidePropertySession();
      addTearDown(c.dispose);
      addTearDown(session.dispose);
      await tester.pumpWidget(harness(c, session, 'def'));
      await tester.pumpAndSettle();
      final state = tester.widget<BusyMarkComboRow<String>>(
        find.byWidgetPredicate(
          (w) =>
              w is BusyMarkComboRow<String> &&
              w.title == 'Published initial state (default-state)',
        ),
      );
      expect(state.selected, 'inherited');
      expect(state.subtitle, 'Resolved: Expanded');
      expect(state.tooltip, contains('parent element'));
      semantics.dispose();
    },
  );
  test(
    'formal authoring sets are independent of preservation capabilities',
    () {
      expect(WritersideSchema.attributesFor('topic').toSet(), {
        'title',
        'id',
        'help-id',
        'switcher-label',
        'ignore-vars',
        'is-library',
        'last-modified',
      });
      expect(WritersideSchema.attributesFor('p').toSet(), {
        'id',
        'switcher-key',
        'filter',
        'help-id',
        'ignore-vars',
        'instance',
      });
      expect(WritersideSchema.attributesFor('chapter').toSet(), {
        'title',
        'id',
        'level',
        'caps',
        'collapsible',
        'default-state',
        'switcher-key',
        'filter',
        'help-id',
        'ignore-vars',
        'instance',
      });
      expect(WritersideSchema.attributesFor('li'), contains('checked'));
      expect(WritersideSchema.valuesFor('table', 'sticky-header'), {
        'true',
        'false',
      });
      expect(WritersideSchema.valuesFor('table', 'sortable'), {
        'true',
        'false',
      });
      expect(WritersideSchema.valuesFor('td', 'sortable'), {'true', 'false'});
      expect(
        WritersideSchema.attributesFor('code-block'),
        contains('emphasize-lines'),
      );
      for (final name in ['filter', 'instance', 'switcher-key']) {
        expect(validateWritersideProperty('topic', name, 'value'), isNotNull);
        expect(
          WritersideSchema.preservedAttributesFor('topic'),
          contains(name),
        );
      }
    },
  );
  test(
    'unsupported root attributes survive default-title edits; identity is not scalar',
    () {
      const source =
          '<topic id="mismatch" title="Before" filter="legacy" instance="web" switcher-key="One" odd="keep"><!--keep--><title instance="web">Formatted <b>title</b></title><p>Body</p></topic>';
      final c = BusyMarkWysiwygDocumentController(document: parse(source));
      addTearDown(c.dispose);
      final root = c.document.blocks.first;
      for (final name in ['filter', 'instance', 'switcher-key', 'id']) {
        expect(c.updateWritersideProperty(root.id, name, 'new'), isFalse);
      }
      expect(c.updateWritersideProperty(root.id, 'title', 'After'), isTrue);
      for (final retained in [
        'id="mismatch"',
        'filter="legacy"',
        'instance="web"',
        'switcher-key="One"',
        'odd="keep"',
        '<!--keep-->',
        '<b>title</b>',
      ]) {
        expect(c.markdown, contains(retained));
      }
      expect(c.markdown, contains('title="After"'));
    },
  );
  test(
    'logical topic resolves one H1 and missing/unsaved identity stays absent',
    () {
      final d = parse('# First {id="anchor"}\n\n# Later\n', xml: false);
      final headings = d.blocks
          .where((b) => b.kind == BusyBlockKind.heading)
          .toList();
      final first = WritersideInspectorTarget.fromSelection(
        bufferId: 'b',
        revision: 1,
        source: d.source!,
        document: d,
        blockId: headings.first.id,
      );
      final later = WritersideInspectorTarget.fromSelection(
        bufferId: 'b',
        revision: 1,
        source: d.source!,
        document: d,
        blockId: headings.last.id,
      );
      expect(first.topic, isTrue);
      expect(later.topic, isFalse);
      expect(first.block!.attributes['id'], 'anchor');
      expect(first.document.filePath, 'identity.md');
      final missing = parse('Body only\n', xml: false, file: '');
      expect(
        WritersideInspectorTarget.fromTopic(
          bufferId: 'b',
          revision: 1,
          source: missing.source!,
          document: missing,
        ).block,
        isNull,
      );
    },
  );
  test(
    'navigation insertion/reset preserve CRLF, comments, formatting and unrelated front matter',
    () {
      const source =
          '---\r\ncustom: "keep"\r\n---\r\n\r\n# Heading\r\n\r\n<!--Keep-->\r\n\r\nBody **formatted** [link](other.md).\r\n';
      final c = BusyMarkWysiwygDocumentController(
        document: parse(source, xml: false),
      );
      addTearDown(c.dispose);
      expect(
        c.setTopicNavigation(
          present: true,
          forElements: 'chapter,tab',
          depth: '2',
        ),
        isTrue,
      );
      final inserted = c.markdown;
      expect(
        inserted.replaceFirst(
          '\r\n\r\n<show-structure for="chapter,tab" depth="2"/>',
          '',
        ),
        source,
      );
      expect(inserted.replaceAll('\r\n', '').contains('\n'), isFalse);
      expect(c.resetTopicNavigation(), isTrue);
      expect(
        c.markdown.replaceFirst(
          '# Heading\r\n\r\n\r\n\r\n',
          '# Heading\r\n\r\n',
        ),
        source,
      );
    },
  );
  test('topic instance title metadata never owns a Markdown chapter title', () {
    const source =
        '# Topic\n\n<title instance="web">Topic web</title>\n\n## Chapter\n\n<title instance="web">Chapter web</title>\n';
    final topic = const WritersideTopicParser().parseMarkdown(
      filePath: 'identity.md',
      topicsRoot: '.',
      source: source,
    );
    expect(topic.titleOverrides.map((v) => v.title), ['Topic web']);
    expect(topic.document.topicTitleElements.map((v) => v.plainText), [
      'Topic web',
    ]);
    expect(topic.document.source, source);
  });
  test('reopened Markdown navigation retains its authored owner', () {
    final source =
        '# Heading {id="anchor"}\n\n<show-structure for="chapter,procedure,tab,def" depth="2"/>\n\n## Chapter\n\nBody\n';
    final d = parse(source, xml: false);
    final c = BusyMarkWysiwygDocumentController(document: d);
    addTearDown(c.dispose);
    expect(c.resetTopicNavigation(), isTrue);
    expect(
      c.markdown,
      source.replaceFirst(
        '<show-structure for="chapter,procedure,tab,def" depth="2"/>',
        '',
      ),
    );
    final reopened = BusyMarkWysiwygDocumentController(
      document: parse(c.markdown, xml: false),
    );
    expect(reopened.setTopicNavigation(present: true, depth: '2'), isTrue);
    expect(reopened.markdown, contains('depth="2"'));
    reopened.dispose();
  });
  for (final xml in [true, false]) {
    test(
      'navigation ${xml ? "XML" : "Markdown"}: distinct states, compound config, protection',
      () {
        final c = BusyMarkWysiwygDocumentController(
          document: parse(
            xml
                ? '<topic id="identity" title="Title"><p>Body</p></topic>'
                : '# Title\n\nBody\n',
            xml: xml,
          ),
        );
        addTearDown(c.dispose);
        expect(c.setTopicNavigation(present: true), isTrue);
        expect(c.markdown, contains('<show-structure/>'));
        expect(
          c.setTopicNavigation(present: true, forElements: 'none'),
          isTrue,
        );
        expect(c.markdown, contains('for="none"'));
        expect(c.setTopicNavigation(present: true, depth: '2'), isTrue);
        expect(c.markdown, contains('depth="2"'));
        expect(c.markdown, isNot(contains('for=')));
        expect(
          c.setTopicNavigation(
            present: true,
            forElements: 'chapter,procedure,tab,def',
            depth: '3',
          ),
          isTrue,
        );
        final saved = c.markdown;
        expect(c.setTopicNavigation(present: true, depth: 'oops'), isFalse);
        expect(c.markdown, saved);
        expect(
          c.setTopicNavigation(present: true, forElements: 'paragraph'),
          isFalse,
        );
        expect(c.markdown, saved);
        expect(c.setTopicNavigation(present: false), isTrue);
        expect(c.markdown, isNot(contains('show-structure')));
        for (final markup in [
          '<show-structure instance="web"/>',
          '<show-structure/><show-structure/>',
        ]) {
          final protected = BusyMarkWysiwygDocumentController(
            document: parse(
              xml
                  ? '<topic id="identity" title="Title">$markup<p>Body</p></topic>'
                  : '# Title\n\n$markup\n',
              xml: xml,
            ),
          );
          expect(
            protected.setTopicNavigation(present: true, forElements: 'none'),
            isFalse,
          );
          expect(protected.markdown, contains(markup));
          protected.dispose();
        }
      },
    );
  }
  for (final tag in ['topic', 'chapter', 'p']) {
    testWidgets(
      '$tag primary fields and Advanced have independently specified owners',
      (tester) async {
        final c = BusyMarkWysiwygDocumentController(
          document: parse(
            '<topic id="identity" title="Topic"><chapter id="chapter-anchor" title="Chapter" collapsible="true" default-state="collapsed"><p id="paragraph-anchor" filter="public" instance="web" ignore-vars="true">A long paragraph.</p></chapter></topic>',
          ),
        );
        addTearDown(c.dispose);
        final session = WritersidePropertySession();
        addTearDown(session.dispose);
        await tester.pumpWidget(harness(c, session, tag));
        final before = c.markdown;
        final selector = tester.widget<BusyMarkComboRow<String>>(
          find.byWidgetPredicate(
            (w) => w is BusyMarkComboRow<String> && w.title == 'Element',
          ),
        );
        expect(
          selector.labelFor(selector.selected),
          tag == 'p'
              ? 'Paragraph'
              : tag == 'topic'
              ? 'Topic Properties'
              : 'Chapter',
        );
        expect(
          find.text('Select a single element to inspect its properties.'),
          findsNothing,
        );
        expect(
          fields(tester),
          tag == 'topic'
              ? ['Default title (title)']
              : tag == 'chapter'
              ? ['Default title (title)', 'Element anchor (id)']
              : ['Element anchor (id)'],
        );
        expect(find.text('Advanced'), findsOneWidget);
        expect(
          find.text('Topic navigation'),
          tag == 'topic' ? findsOneWidget : findsNothing,
        );
        expect(
          find.text('Authored settings present'),
          tag == 'p' ? findsOneWidget : findsNothing,
        );
        await section(tester, 'Advanced');
        final actual = fields(tester).toSet();
        expect(
          actual,
          tag == 'topic'
              ? {
                  'Default title (title)',
                  'Switcher label (switcher-label)',
                  'Context help ID (help-id)',
                  'Last modified (last-modified)',
                }
              : tag == 'chapter'
              ? {
                  'Default title (title)',
                  'Element anchor (id)',
                  'Filter (filter)',
                  'Context help ID (help-id)',
                  'Help instances (instance)',
                  'Switcher key (switcher-key)',
                }
              : {
                  'Element anchor (id)',
                  'Filter (filter)',
                  'Context help ID (help-id)',
                  'Help instances (instance)',
                  'Switcher key (switcher-key)',
                },
        );
        expect(c.markdown, before);
        if (tag == 'topic') {
          expect(
            find.byKey(const ValueKey('writerside-topic-id')),
            findsOneWidget,
          );
          await edit(tester, 'Default title (title)', 'Changed topic');
          expect(c.markdown, contains('id="identity"'));
        } else {
          await edit(tester, 'Help instances (instance)', '!web,desktop');
          final block = walk(
            c.document.blocks,
          ).firstWhere((b) => b.attributes['element'] == tag);
          expect(block.attributes['instance'], '!web,desktop');
          expect(c.document.blocks.first.attributes['id'], 'identity');
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'Markdown filename, heading text, heading anchor and title override stay distinct',
    (tester) async {
      final c = BusyMarkWysiwygDocumentController(
        document: parse(
          '# Heading words {id="different-anchor"}\n\n## Chapter words {id="chapter" title="Published override"}\n\nBody\n',
          xml: false,
        ),
      );
      addTearDown(c.dispose);
      final session = WritersidePropertySession();
      addTearDown(session.dispose);
      await tester.pumpWidget(harness(c, session, 'topic'));
      expect(
        tester
            .widget<SelectableText>(
              find.byKey(const ValueKey('writerside-topic-id')),
            )
            .data,
        'identity',
      );
      expect(fields(tester), ['Heading text']);
      await edit(tester, 'Heading text', 'New heading words');
      expect(c.document.filePath, 'identity.md');
      expect(c.markdown, contains('id="different-anchor"'));
      await section(tester, 'Advanced');
      await edit(tester, 'Element anchor (id)', 'new-anchor');
      expect(c.markdown, contains('id="new-anchor"'));
      expect(c.document.filePath, 'identity.md');
      session.transition();
      await tester.pumpWidget(harness(c, session, 'chapter'));
      await edit(tester, 'Heading text', 'New chapter words');
      expect(c.markdown, contains('title="Published override"'));
      if (entry('Title override (title)').evaluate().isEmpty) {
        await section(tester, 'Advanced');
      }
      await edit(tester, 'Title override (title)', 'New published override');
      expect(c.markdown, contains('New chapter words'));
      expect(c.markdown, contains('title="New published override"'));
      final reopened = parse(c.markdown, xml: false);
      expect(
        reopened.blocks
            .where((b) => b.kind == BusyBlockKind.heading)
            .last
            .attributes['title'],
        'New published override',
      );
    },
  );
  testWidgets(
    'paragraph has one concise identity and complete accessible content',
    (tester) async {
      final c = BusyMarkWysiwygDocumentController(
        document: parse(
          '<topic id="identity" title="Topic"><p id="body">First line<br/>Second line.</p></topic>',
        ),
      );
      addTearDown(c.dispose);
      final session = WritersidePropertySession();
      addTearDown(session.dispose);
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(harness(c, session, 'p'));
      final selector = tester.widget<BusyMarkComboRow<String>>(
        find.byWidgetPredicate(
          (w) => w is BusyMarkComboRow<String> && w.values.contains('@topic'),
        ),
      );
      expect(selector.labelFor(selector.selected), 'Paragraph');
      final excerpt = find.byKey(
        const ValueKey('writerside-properties-identity'),
      );
      expect(tester.widget<Text>(excerpt).maxLines, 2);
      expect(
        tester.getSemantics(excerpt).label,
        contains('First line\nSecond line.'),
      );
      expect(
        c.markdown,
        '<topic id="identity" title="Topic"><p id="body">First line<br/>Second line.</p></topic>',
      );
      semantics.dispose();
    },
  );
  testWidgets(
    'Custom from every preset keeps drafts compound and refuses invalid transitions',
    (tester) async {
      final c = BusyMarkWysiwygDocumentController(
        document: parse('<topic id="identity" title="Title"/>'),
      );
      addTearDown(c.dispose);
      final session = WritersidePropertySession();
      addTearDown(session.dispose);
      var publications = 0;
      await tester.pumpWidget(
        harness(c, session, 'topic', onPublished: () => publications++),
      );
      await section(tester, 'Topic navigation');
      BusyMarkComboRow<String> combo() => tester.widget(
        find.byWidgetPredicate(
          (w) => w is BusyMarkComboRow<String> && w.values.contains('custom'),
        ),
      );
      for (final preset in ['default', 'all', 'none']) {
        combo().onSelected(preset);
        await tester.pumpAndSettle();
        final before = c.markdown;
        combo().onSelected('custom');
        await tester.pumpAndSettle();
        expect(combo().selected, 'custom');
        expect(c.markdown, before);
        combo().onSelected(preset);
        await tester.pumpAndSettle();
      }
      combo().onSelected('custom');
      await tester.pumpAndSettle();
      final start = publications;
      await tester.enterText(
        entry('Navigation elements (for)'),
        'chapter,tab,def',
      );
      await tester.enterText(entry('Navigation depth (depth)'), 'bad');
      expect(session.flush(), isFalse);
      expect(publications, start);
      expect(session.hasPending, isTrue);
      await section(tester, 'Topic navigation');
      expect(entry('Navigation depth (depth)'), findsOneWidget);
      await tester.enterText(entry('Navigation depth (depth)'), '2');
      expect(session.flush(), isTrue);
      await tester.pumpAndSettle();
      expect(publications, start + 1);
      expect(c.markdown, contains('for="chapter,tab,def" depth="2"'));
    },
  );
}

Widget harness(
  BusyMarkWysiwygDocumentController c,
  WritersidePropertySession session,
  String tag, {
  VoidCallback? onPublished,
  double? width,
  TextDirection? direction,
  WritersideEffectiveProperties effective =
      const WritersideEffectiveProperties(),
}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: StatefulBuilder(
      builder: (context, refresh) {
        final block = tag == 'topic'
            ? (c.document.isXmlTopic
                  ? c.document.blocks.first
                  : WritersideEditingAdapter.topicHeading(c.document))
            : walk(c.document.blocks).firstWhere(
                (b) =>
                    b.attributes['element'] == tag ||
                    tag == 'li' &&
                        WritersideEditingAdapter.tagForBlock(b) == 'li' ||
                    tag == 'chapter' &&
                        b.kind == BusyBlockKind.heading &&
                        b.attributes['level'] != '1',
              );
        bool apply(bool Function() change) {
          final ok = change();
          if (ok) {
            onPublished?.call();
            refresh(() {});
          }
          return ok;
        }

        return SizedBox(
          width: width,
          child: Directionality(
            textDirection: direction ?? Directionality.of(context),
            child: BusyMarkWritersideProperties(
              effectiveProperties: effective,
              document: c.document,
              target: block,
              path: block == null ? [] : c.elementPath(block.id),
              topicSelected: tag == 'topic',
              session: session,
              onClose: () {},
              onTargetSelected: (_) {},
              onManageItem: (_, _, _) {},
              onProperty: (name, value) => apply(
                () => c.updateWritersideProperty(block!.id, name, value),
              ),
              onHeadingText: (text) => apply(() {
                c.updateBlockText(block!.id, text);
                return true;
              }),
              onTopicProperty: (name, value) =>
                  apply(() => c.updateTopicSwitcherLabel(value)),
              onNavigation: (present, elements, depth) => apply(
                () => c.setTopicNavigation(
                  present: present,
                  forElements: elements,
                  depth: depth,
                ),
              ),
            ),
          ),
        );
      },
    ),
  ),
);
