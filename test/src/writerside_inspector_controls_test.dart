import 'dart:async';
import 'dart:io';
import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/editor/wysiwyg/writerside_editing_adapter.dart';
import 'package:busymark/src/editor/wysiwyg/writerside_properties.dart';
import 'package:busymark/src/editor/wysiwyg/writerside_property_session.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_document_controller.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_inline_controller.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

BusyDocument parse(String source, bool xml) => xml
    ? const WritersideEditingAdapter().parseXml(
        filePath: 'a.topic',
        source: source,
      )!
    : const MarkdownParser()
          .parse(
            filePath: 'a.md',
            source: source,
            mode: MarkdownMode.writersideMarkdown,
            validateLocalReferences: false,
          )
          .busyDocument;
Iterable<BusyBlock> walk(List<BusyBlock> blocks) sync* {
  for (final b in blocks) {
    yield b;
    yield* walk(b.children);
  }
}

Widget app(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: Align(
      alignment: Alignment.centerRight,
      child: SizedBox(width: 390, child: child),
    ),
  ),
);
Finder field(String label) => find.descendant(
  of: find.byWidgetPredicate(
    (w) => w is BusyMarkGroupedTextEntry && w.label == label,
  ),
  matching: find.byType(TextField),
);
Future<void> edit(WidgetTester tester, String label, String value) async {
  await tester.ensureVisible(field(label));
  await tester.enterText(field(label), value);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}

void main() {
  for (final xml in [true, false]) {
    testWidgets(
      '${xml ? "XML" : "Markdown"} inspector edits the named reference attributes and reopens them',
      (tester) async {
        final original = xml
            ? '<topic id="a" title="Title"><p>Before <a href="old.topic" origin="old"><b>Guide</b></a> after.</p><p><img src="logo.png" alt="Logo" preview-src="old.png"/></p><p>Press <shortcut key="\$Save" from-keymap-of="old">Ctrl+S</shortcut>.</p><include id="own" from="old.topic" element-id="old-fragment" origin="old"/></topic>'
            : '# Title\n\nBefore [**Guide**](old.topic){origin="old"} after.\n\n![Logo](logo.png){preview-src="old.png"}\n\nPress <shortcut key="\$Save" from-keymap-of="old">Ctrl+S</shortcut>.\n\n<include id="own" from="old.topic" element-id="old-fragment" origin="old"/>\n';
        var c = BusyMarkWysiwygDocumentController(
          document: parse(original, xml),
        );
        addTearDown(() => c.dispose());
        final session = WritersidePropertySession();
        addTearDown(session.dispose);
        BusyInlineKind? kind;
        BusyBlock selected() => walk(c.document.blocks).firstWhere(
          (b) => kind == null
              ? b.attributes['element'] == 'include'
              : busyInlineReferenceRanges(b.inlines).any((r) => r.kind == kind),
        );
        Future<void> show(BusyInlineKind? next) async {
          session.transition();
          kind = next;
          await tester.pumpWidget(
            app(
              StatefulBuilder(
                builder: (context, refresh) {
                  final block = selected();
                  final inline = kind == null
                      ? null
                      : busyInlineReferenceRanges(
                          block.inlines,
                        ).firstWhere((r) => r.kind == kind);
                  bool apply(bool Function() change) {
                    final result = change();
                    if (result) refresh(() {});
                    return result;
                  }

                  return BusyMarkWritersideProperties(
                    document: c.document,
                    path: c.elementPath(block.id),
                    target: block,
                    topicSelected: false,
                    session: session,
                    inlineTarget: inline,
                    onClose: () {},
                    onTargetSelected: (_) {},
                    onHeadingText: (_) => false,
                    onTopicProperty: (_, _) => false,
                    onManageItem: (_, _, _) {},
                    onProperty: (name, value) => apply(
                      () => c.updateWritersideProperty(block.id, name, value),
                    ),
                    onInlineProperty: (name, value) => apply(
                      () => c.updateInlineReference(
                        block.id,
                        inline!,
                        name,
                        value,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
          await tester.pumpAndSettle();
        }

        await show(null);
        await edit(tester, 'Included element (element-id)', 'new-fragment');
        expect(selected().attributes['id'], 'own');
        await edit(tester, 'Topic (from)', 'new.topic');
        await edit(tester, 'Help module (origin)', 'new-module');
        await show(BusyInlineKind.image);
        await edit(tester, 'Preview image (preview-src)', 'new-preview.gif');
        expect(
          busyInlineReferenceRanges(selected().inlines).single.destination,
          'logo.png',
        );
        await show(BusyInlineKind.writersideShortcut);
        await edit(tester, 'Action ID (key)', '\$Copy');
        expect(selected().plainText, 'Press Ctrl+S.');
        await edit(
          tester,
          'Keymap help instance (from-keymap-of)',
          'other-instance',
        );
        await show(BusyInlineKind.link);
        await edit(tester, 'Link target (href)', 'new.topic#anchor');
        await edit(tester, 'Help module (origin)', 'new-module');
        expect(selected().plainText, 'Before Guide after.');
        await tester.runAsync(() async {
          final directory = await Directory.systemTemp.createTemp(
            'inspector-controls-',
          );
          addTearDown(() => directory.delete(recursive: true));
          final file = File('${directory.path}/a.${xml ? 'topic' : 'md'}');
          await file.writeAsString(c.markdown);
          expect(c.markdown, contains(xml ? '<b>Guide</b>' : '**Guide**'));
          c.dispose();
          c = BusyMarkWysiwygDocumentController(
            document: parse(await file.readAsString(), xml),
          );
        });
        await show(null);
        expect(selected().attributes, containsPair('id', 'own'));
        expect(
          selected().attributes,
          containsPair('element-id', 'new-fragment'),
        );
        expect(selected().attributes, containsPair('from', 'new.topic'));
        await show(BusyInlineKind.image);
        final image = busyInlineReferenceRanges(selected().inlines).single;
        expect(image.destination, 'logo.png');
        expect(image.attributes['preview-src'], 'new-preview.gif');
        await show(BusyInlineKind.writersideShortcut);
        final shortcut = busyInlineReferenceRanges(selected().inlines).single;
        expect(shortcut.attributes['key'], '\$Copy');
        expect(shortcut.attributes['from-keymap-of'], 'other-instance');
        expect(selected().plainText, 'Press Ctrl+S.');
        await show(BusyInlineKind.link);
        final link = busyInlineReferenceRanges(
          selected().inlines,
        ).firstWhere((r) => r.kind == BusyInlineKind.link);
        expect(link.destination, 'new.topic#anchor');
        expect(link.attributes['origin'], 'new-module');
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'one source-file field handles chooser cancellation, selection and removal',
    (tester) async {
      var c = BusyMarkWysiwygDocumentController(
        document: parse(
          '<topic id="a" title="Title"><code-block lang="dart"/></topic>',
          true,
        ),
      );
      addTearDown(() => c.dispose());
      final session = WritersidePropertySession();
      addTearDown(session.dispose);
      var choice = Completer<String?>();
      late StateSetter redraw;
      await tester.pumpWidget(
        app(
          StatefulBuilder(
            builder: (context, refresh) {
              redraw = refresh;
              final code = c.document.blocks.first.children.single;
              return BusyMarkWritersideProperties(
                document: c.document,
                path: [c.document.blocks.first, code],
                target: code,
                topicSelected: false,
                session: session,
                onChooseCodeSource: () => choice.future,
                onClose: () {},
                onTargetSelected: (_) {},
                onHeadingText: (_) => false,
                onTopicProperty: (_, _) => false,
                onManageItem: (_, _, _) {},
                onProperty: (name, value) {
                  final result = c.updateWritersideProperty(
                    code.id,
                    name,
                    value,
                  );
                  if (result) refresh(() {});
                  return result;
                },
              );
            },
          ),
        ),
      );
      expect(field('Source file (src)'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is BusyMarkComboRow<String> && w.values.contains('file'),
        ),
        findsNothing,
      );
      final initial = c.markdown;
      await tester.tap(find.byTooltip('Open'));
      await tester.pump();
      choice.complete(null);
      await tester.pumpAndSettle();
      expect(c.markdown, initial);
      choice = Completer<String?>();
      await tester.tap(find.byTooltip('Open'));
      await tester.pump();
      redraw(() {});
      await tester.pump();
      choice.complete('../snippets/sample.dart');
      await tester.pumpAndSettle();
      expect(c.markdown, contains('src="../snippets/sample.dart"'));
      await tester.tap(find.byTooltip('Remove'));
      await tester.pumpAndSettle();
      expect(c.markdown, initial);
      await edit(tester, 'Source file (src)', 'sample.dart');
      expect(c.markdown, contains('src="sample.dart"'));
      expect(c.document.blocks.first.children.single.plainText, isEmpty);
      final code = c.document.blocks.first.children.single;
      c.updateBlockText(code.id, 'Authored code');
      redraw(() {});
      await tester.pumpAndSettle();
      await edit(tester, 'Source file (src)', 'another.dart');
      expect(
        c.document.blocks.first.children.single.plainText,
        'Authored code',
      );
      expect(c.markdown, contains('src="sample.dart"'));
      expect(session.hasPending, isTrue);
      session.revertAll();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Remove'));
      await tester.pumpAndSettle();
      expect(
        c.document.blocks.first.children.single.plainText,
        'Authored code',
      );
      expect(c.markdown, isNot(contains('src=')));
    },
  );
  testWidgets(
    'delayed file choice keeps its captured mutation after a target replacement',
    (tester) async {
      var c = BusyMarkWysiwygDocumentController(
        document: parse(
          '<topic id="a" title="Title"><code-block lang="dart"/></topic>',
          true,
        ),
      );
      addTearDown(() => c.dispose());
      var generation = 0;
      final choice = Completer<String?>();
      final session = WritersidePropertySession();
      addTearDown(session.dispose);
      late StateSetter redraw;
      await tester.pumpWidget(
        app(
          StatefulBuilder(
            builder: (context, refresh) {
              redraw = refresh;
              final captured = generation;
              final code = c.document.blocks.first.children.single;
              return BusyMarkWritersideProperties(
                document: c.document,
                path: [c.document.blocks.first, code],
                target: code,
                topicSelected: false,
                session: session,
                onChooseCodeSource: () => choice.future,
                onClose: () {},
                onTargetSelected: (_) {},
                onHeadingText: (_) => false,
                onTopicProperty: (_, _) => false,
                onManageItem: (_, _, _) {},
                onProperty: (name, value) => captured != generation
                    ? session.reject(WritersidePropertyRejection.stale)
                    : c.updateWritersideProperty(code.id, name, value),
              );
            },
          ),
        ),
      );
      await tester.tap(find.byTooltip('Open'));
      await tester.pump();
      c.dispose();
      c = BusyMarkWysiwygDocumentController(
        document: parse(
          '<topic id="a" title="Title"><code-block lang="sql"/></topic>',
          true,
        ),
      );
      generation++;
      redraw(() {});
      await tester.pump();
      final replacement = c.markdown;
      choice.complete('old-target.dart');
      await tester.pumpAndSettle();
      expect(c.markdown, replacement);
      expect(session.feedback, WritersidePropertyRejection.stale);
      expect(session.hasPending, isTrue);
    },
  );
  testWidgets(
    'Show in Source and target/close actions validate pending drafts',
    (tester) async {
      final doc = parse(
        '<topic id="a" title="Title"><p id="body">Text</p></topic>',
        true,
      );
      final session = WritersidePropertySession();
      addTearDown(session.dispose);
      var navigation = 0, closes = 0, targets = 0;
      await tester.pumpWidget(
        app(
          BusyMarkWritersideProperties(
            document: doc,
            path: doc.blocks,
            target: doc.blocks.first,
            topicSelected: true,
            session: session,
            onSourceLocation: () => navigation++,
            onClose: () => closes++,
            onTargetSelected: (_) => targets++,
            onProperty: (_, _) => false,
            onHeadingText: (_) => false,
            onTopicProperty: (_, _) => false,
            onManageItem: (_, _, _) {},
          ),
        ),
      );
      await tester.enterText(field('Element ID (id)'), 'invalid id');
      await tester.ensureVisible(find.text('Show in Source'));
      await tester.tap(find.text('Show in Source'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      tester
          .widget<BusyMarkComboRow<String>>(
            find.byType(BusyMarkComboRow<String>).first,
          )
          .onSelected('@topic');
      expect(navigation, 0);
      expect(closes, 0);
      expect(targets, 0);
      expect(session.hasPending, isTrue);
      session.revertAll();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show in Source'));
      await tester.pumpAndSettle();
      expect(navigation, 1);
      expect(doc.source, contains('id="a"'));
    },
  );
}
