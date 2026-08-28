import 'dart:io';

import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/editor/document_callout.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_document_controller.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:busymark/src/export/markdown_export_document.dart';
import 'package:busymark/src/export/markdown_export_mapper.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/busymark_markdown_serializer.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/markdown/preview_model.dart';
import 'package:busymark/src/workspace/workspace_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  const parser = MarkdownParser();
  const previewBuilder = BusyMarkPreviewBuilder();

  test('Writerside blockquotes become typed admonitions and round-trip', () {
    const source = '''> Default **tip**.

> A *note*.
{style="note"}

> Warning text. {style="warning"}

> Quoted text.
{style="quote"}
''';
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: source,
      mode: MarkdownMode.writersideMarkdown,
      validateLocalReferences: false,
    );
    final blocks = parsed.busyDocument.blocks;

    expect(blocks, hasLength(4));
    expect(blocks.map((block) => block.kind), {BusyBlockKind.blockquote});
    expect(blocks.map((block) => block.attributes['style']), [
      'tip',
      'note',
      'warning',
      'quote',
    ]);
    expect(
      blocks.every(
        (block) =>
            block.attributes[busyMarkWritersideAdmonitionAttribute] == 'true',
      ),
      isTrue,
    );
    expect(blocks[1].children.single.plainText, 'A note.');
    expect(blocks[2].children.single.plainText, 'Warning text.');
    expect(
      blocks[1].children.single.inlines.map((inline) => inline.kind),
      contains(BusyInlineKind.emphasis),
    );

    final preview = previewBuilder.build(parsed.busyDocument);
    expect(preview.blocks.map((block) => block.kind), [
      PreviewBlockKind.admonition,
      PreviewBlockKind.admonition,
      PreviewBlockKind.admonition,
      PreviewBlockKind.quote,
    ]);
    expect(
      const BusyMarkMarkdownSerializer().serialize(parsed.busyDocument),
      source,
    );
  });

  test('ordinary Markdown blockquotes do not acquire Writerside semantics', () {
    const source = '> Text {style="warning"}\n';
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: source,
      mode: MarkdownMode.commonMark,
      validateLocalReferences: false,
    );
    final block = parsed.busyDocument.blocks.single;
    final preview = previewBuilder.build(parsed.busyDocument).blocks.single;

    expect(block.attributes[busyMarkWritersideAdmonitionAttribute], isNull);
    expect(block.children.single.plainText, 'Text {style="warning"}');
    expect(preview.kind, PreviewBlockKind.quote);
  });

  test(
    'semantic admonition elements include quote and preserve attributes',
    () {
      const source = '''<tip>
Helpful advice.
</tip>

<note title="Known issue">Important.</note>

<warning>Danger.</warning>

<quote>Neutral quotation.</quote>
''';
      final parsed = parser.parse(
        filePath: 'topic.md',
        source: source,
        mode: MarkdownMode.writersideMarkdown,
        validateLocalReferences: false,
      );
      final blocks = parsed.busyDocument.blocks;

      expect(blocks, hasLength(4));
      expect(
        blocks.every(
          (block) => block.kind == BusyBlockKind.writersideAdmonition,
        ),
        isTrue,
      );
      expect(blocks.map((block) => block.attributes['style']), [
        'tip',
        'note',
        'warning',
        'quote',
      ]);
      expect(
        previewBuilder.build(parsed.busyDocument).blocks.last.kind,
        PreviewBlockKind.quote,
      );
      expect(
        const BusyMarkMarkdownSerializer().serialize(parsed.busyDocument),
        source,
      );

      final controller = BusyMarkWysiwygDocumentController(
        document: parsed.busyDocument,
      );
      controller.applyAdmonitionStyle(
        blocks[1].id,
        BusyAdmonitionStyle.warning,
      );
      final edited = controller.markdown;
      expect(
        edited,
        contains('<warning title="Known issue">Important.</warning>'),
      );
      final reparsed = parser.parse(
        filePath: 'topic.md',
        source: edited,
        mode: MarkdownMode.writersideMarkdown,
        validateLocalReferences: false,
      );
      expect(reparsed.busyDocument.blocks[1].attributes['style'], 'warning');
    },
  );

  test('admonition editing emits source that reparses semantically', () {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: 'Important information.\n',
      mode: MarkdownMode.writersideMarkdown,
      validateLocalReferences: false,
    );
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );

    controller.applyAdmonitionStyle(
      parsed.busyDocument.blocks.single.id,
      BusyAdmonitionStyle.warning,
    );
    final source = controller.markdown;
    expect(source, '> Important information.\n{style="warning"}\n');

    final reparsed = parser.parse(
      filePath: 'topic.md',
      source: source,
      mode: MarkdownMode.writersideMarkdown,
      validateLocalReferences: false,
    );
    expect(reparsed.busyDocument.blocks.single.attributes['style'], 'warning');
    expect(
      previewBuilder.build(reparsed.busyDocument).blocks.single.kind,
      PreviewBlockKind.admonition,
    );
  });

  test('editing inside an existing admonition changes its outer type', () {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: '> Existing note.\n{style="note"}\n',
      mode: MarkdownMode.writersideMarkdown,
      validateLocalReferences: false,
    );
    final admonition = parsed.busyDocument.blocks.single;
    final child = admonition.children.single;
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );

    final targetId = controller.admonitionTargetId(child.id);
    expect(targetId, admonition.id);
    controller.applyAdmonitionStyle(targetId, BusyAdmonitionStyle.warning);

    expect(controller.markdown, '> Existing note.\n{style="warning"}\n');
    expect(controller.markdown, isNot(contains('> >')));
  });

  testWidgets('WYSIWYG Admonition menu applies the selected type', (
    tester,
  ) async {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: 'Important information.\n',
      mode: MarkdownMode.writersideMarkdown,
      validateLocalReferences: false,
    );
    var markdown = '';
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: parsed.busyDocument,
              onSourceChanged: (_, source) => markdown = source,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byTooltip('Admonition'), findsOneWidget);
    await tester.tap(find.byTooltip('Admonition'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Warning'));
    await tester.pumpAndSettle();

    expect(markdown, contains('{style="warning"}'));
    expect(find.byType(BusyMarkDocumentAdmonition), findsOneWidget);
    final reparsed = parser.parse(
      filePath: 'topic.md',
      source: markdown,
      mode: MarkdownMode.writersideMarkdown,
      validateLocalReferences: false,
    );
    expect(reparsed.busyDocument.blocks.single.attributes['style'], 'warning');
  });

  testWidgets('ordinary Markdown does not show the Writerside editing menu', (
    tester,
  ) async {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: 'Paragraph.\n',
      validateLocalReferences: false,
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BusyMarkWysiwygEditor(
            document: parsed.busyDocument,
            onSourceChanged: (_, _) {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byTooltip('Admonition'), findsNothing);
  });

  test(
    'Writerside .topic preview keeps content inside its admonition',
    () async {
      final root = Directory.systemTemp.createTempSync('busymark-admonition-');
      addTearDown(() => root.deleteSync(recursive: true));
      final topics = Directory(p.join(root.path, 'topics'))..createSync();
      File(p.join(root.path, 'writerside.cfg')).writeAsStringSync('''
<ihp>
  <module name="Admonition test"/>
  <topics dir="topics"/>
  <images dir="images"/>
  <instance src="guide.tree"/>
</ihp>
''');
      File(p.join(root.path, 'guide.tree')).writeAsStringSync('''
<instance-profile id="guide" name="Guide" start-page="admonitions.topic">
  <toc-element topic="admonitions.topic"/>
</instance-profile>
''');
      const source = '''<topic id="admonitions" title="Admonitions">
  <tip><p>Use <b>safe</b> mode with <math>x &lt; y</math>.</p></tip>
  <note>Known limitation.</note>
  <warning>Data can be lost.</warning>
  <quote>Neutral quotation.</quote>
</topic>''';
      final topicPath = p.join(topics.path, 'admonitions.topic');
      File(topicPath).writeAsStringSync(source);

      const service = WorkspaceService();
      final workspace = await service.openPath(root.path);
      final preview = service.buildPreview(
        workspace.copyWith(activeFilePath: topicPath),
        source,
      )!;
      final callouts = preview.blocks.where(
        (block) =>
            block.kind == PreviewBlockKind.admonition ||
            block.kind == PreviewBlockKind.quote,
      );

      expect(callouts.map((block) => block.text), [
        'Use safe mode with x < y.',
        'Known limitation.',
        'Data can be lost.',
        'Neutral quotation.',
      ]);
      expect(
        preview.blocks.where(
          (block) => block.text == 'Use safe mode with x < y.',
        ),
        hasLength(1),
      );
      final tip = callouts.first;
      expect(
        tip.inlines.map((inline) => inline.kind),
        containsAll([PreviewInlineKind.strong, PreviewInlineKind.math]),
      );
      expect(
        tip.inlines
            .singleWhere((inline) => inline.kind == PreviewInlineKind.math)
            .text,
        'x < y',
      );
    },
  );

  test('PDF export keeps admonitions semantic and quotes neutral', () {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: '''> Helpful.

> Important.
{style="note"}

> Quoted.
{style="quote"}
''',
      mode: MarkdownMode.writersideMarkdown,
      validateLocalReferences: false,
    );
    final exported = const MarkdownExportMapper().map(parsed.busyDocument);

    expect(exported.blocks.map((block) => block.kind), [
      MarkdownExportBlockKind.admonition,
      MarkdownExportBlockKind.admonition,
      MarkdownExportBlockKind.blockquote,
    ]);
    expect(exported.blocks[0].attributes['style'], 'tip');
    expect(exported.blocks[1].attributes['style'], 'note');
  });
}
