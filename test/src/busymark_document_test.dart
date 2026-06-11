import 'package:busymark/src/editor/wysiwyg/wysiwyg_commands.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_document_controller.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_inline_controller.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/busymark_markdown_serializer.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/markdown/preview_export.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = MarkdownParser();

  test('package markdown AST imports into BusyDocument core blocks', () {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: '''
# Title

Paragraph with **bold** and [link](docs.md).

![Logo](logo.png)

```dart
void main() {}
```

- Bullet
1. Ordered
- [x] Done

| Name | Value |
| --- | --- |
| A | B |
''',
    );
    final blocks = parsed.busyDocument.blocks;

    expect(blocks.any((block) => block.kind == BusyBlockKind.heading), isTrue);
    expect(
      blocks.any(
        (block) =>
            block.kind == BusyBlockKind.paragraph &&
            block.inlines.any((inline) => inline.kind == BusyInlineKind.strong),
      ),
      isTrue,
    );
    expect(blocks.any((block) => block.kind == BusyBlockKind.image), isTrue);
    expect(
      blocks.any((block) => block.kind == BusyBlockKind.codeBlock),
      isTrue,
    );
    expect(
      blocks.map((block) => block.kind),
      containsAll([
        BusyBlockKind.unorderedListItem,
        BusyBlockKind.orderedListItem,
        BusyBlockKind.taskListItem,
        BusyBlockKind.table,
      ]),
    );
  });

  test('serializer emits Markdown source for edited semantic blocks', () {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: '# Title\n\nParagraph\n',
    );
    final markdown = const BusyMarkMarkdownSerializer().serialize(
      parsed.busyDocument.copyWith(
        blocks: [
          parsed.busyDocument.blocks.first.copyWith(
            inlines: const [
              BusyInline(kind: BusyInlineKind.text, text: 'Changed'),
            ],
            dirty: true,
          ),
        ],
      ),
    );

    expect(markdown, '# Changed\n');
  });

  test('serializer preserves unchanged raw blocks', () {
    const raw = '<custom attr="keep">Do not flatten</custom>';
    final document = BusyDocument(
      filePath: 'topic.md',
      mode: MarkdownMode.writersideMarkdown,
      blocks: const [
        BusyBlock(
          id: 'raw',
          kind: BusyBlockKind.writersideRawXml,
          rawSource: raw,
          preserveRaw: true,
        ),
      ],
    );

    expect(const BusyMarkMarkdownSerializer().serialize(document), '$raw\n');
  });

  test('HTML export blocks unsafe links and image URLs', () {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: '[bad](javascript:alert(1))\n\n![bad](data:text/html,evil)\n',
    );
    final html = const MarkdownHtmlExporter().export(parsed);

    expect(html, isNot(contains('javascript:')));
    expect(html, isNot(contains('data:text')));
  });

  test('preview and WYSIWYG use the same semantic document', () {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: '# Title\n\nParagraph with **bold**.\n',
    );
    final preview = const BusyMarkPreviewBuilder().build(parsed.busyDocument);

    expect(preview.blocks.first.text, 'Title');
    expect(
      preview.blocks.last.inlines.map((inline) => inline.kind),
      contains(PreviewInlineKind.strong),
    );
  });

  test('WYSIWYG text edit updates Markdown source', () {
    final parsed = parser.parse(filePath: 'topic.md', source: 'Original\n');
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );
    final blockId = parsed.busyDocument.blocks.first.id;

    controller.updateBlockText(blockId, 'Changed');

    expect(controller.markdown, 'Changed\n');
  });

  test('WYSIWYG empty documents have one editable paragraph', () {
    final parsed = parser.parse(filePath: 'Untitled.md', source: '');
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );
    final block = controller.document.blocks.single;

    expect(block.kind, BusyBlockKind.paragraph);

    controller.updateBlockText(block.id, 'First line');

    expect(controller.markdown, 'First line\n');
  });

  testWidgets('WYSIWYG editor accepts typing in an empty document', (
    tester,
  ) async {
    final parsed = parser.parse(filePath: 'Untitled.md', source: '');
    var markdown = '';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: parsed.busyDocument,
              onSourceChanged: (value) => markdown = value,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      tester
          .widget<TextField>(find.byType(TextField).first)
          .focusNode
          ?.hasFocus,
      isTrue,
    );

    await tester.enterText(find.byType(TextField).first, 'Editable text');
    await tester.pump();

    expect(markdown, 'Editable text\n');
    expect(find.text('Editable text'), findsOneWidget);
  });

  testWidgets('WYSIWYG arrow keys move focus between paragraphs', (
    tester,
  ) async {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: 'First\n\nSecond\n',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: parsed.busyDocument,
              onSourceChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    TextField fieldAt(int index) {
      return tester.widget<TextField>(find.byType(TextField).at(index));
    }

    expect(fieldAt(0).focusNode?.hasFocus, isTrue);
    expect(fieldAt(0).controller?.selection.extentOffset, 0);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(fieldAt(1).focusNode?.hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();

    expect(fieldAt(0).focusNode?.hasFocus, isTrue);
  });

  test('WYSIWYG inline ranges do not duplicate formatted text', () {
    final parsed = parser.parse(filePath: 'topic.md', source: '**source**\n');
    final block = parsed.busyDocument.blocks.single;
    final ranges = busyInlineStyleRanges(block.inlines);

    expect(block.plainText, 'source');
    expect(ranges, hasLength(1));
    expect(ranges.single.start, 0);
    expect(ranges.single.end, 'source'.length);
    expect(ranges.single.kind, BusyInlineKind.strong);
  });

  test('WYSIWYG inline commands serialize bold italic and links', () {
    final parsed = parser.parse(filePath: 'topic.md', source: 'Alpha Beta\n');
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );
    final blockId = parsed.busyDocument.blocks.first.id;

    controller.applyInlineCommand(blockId, BusyWysiwygInlineCommand.bold, 0, 5);
    expect(controller.markdown, '**Alpha** Beta\n');

    final reparsed = parser.parse(filePath: 'topic.md', source: 'Alpha Beta\n');
    final linkController = BusyMarkWysiwygDocumentController(
      document: reparsed.busyDocument,
    );
    final linkBlockId = reparsed.busyDocument.blocks.first.id;
    linkController.applyInlineCommand(
      linkBlockId,
      BusyWysiwygInlineCommand.link,
      6,
      10,
      destination: 'target.md',
    );

    expect(linkController.markdown, 'Alpha [Beta](target.md)\n');
  });

  test('WYSIWYG inline commands preserve existing sibling formatting', () {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: 'Attached source archive\n',
    );
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );
    final blockId = parsed.busyDocument.blocks.first.id;

    controller.applyInlineCommand(
      blockId,
      BusyWysiwygInlineCommand.bold,
      'Attached source '.length,
      'Attached source archive'.length,
    );
    controller.applyInlineCommand(
      blockId,
      BusyWysiwygInlineCommand.italic,
      'Attached '.length,
      'Attached source'.length,
    );

    expect(controller.markdown, 'Attached *source* **archive**\n');
  });

  test('WYSIWYG image command serializes a real image block', () {
    final parsed = parser.parse(filePath: 'topic.md', source: 'Image here\n');
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );
    final blockId = parsed.busyDocument.blocks.first.id;

    controller.applyImageBlock(
      blockId,
      source: 'images/example.png',
      alt: 'Example image',
    );

    expect(controller.markdown, '![Example image](images/example.png)\n');
  });

  test('WYSIWYG block commands serialize headings and lists', () {
    final parsed = parser.parse(filePath: 'topic.md', source: 'Title\n');
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );
    final blockId = parsed.busyDocument.blocks.first.id;

    controller.applyBlockCommand(blockId, BusyWysiwygBlockCommand.heading2);
    expect(controller.markdown, '## Title\n');

    controller.applyBlockCommand(blockId, BusyWysiwygBlockCommand.taskList);
    expect(controller.markdown, '- [ ] Title\n');
  });
}
