import 'package:busymark/src/editor/wysiwyg/wysiwyg_commands.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_document_controller.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/busymark_markdown_serializer.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/markdown/preview_export.dart';
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
