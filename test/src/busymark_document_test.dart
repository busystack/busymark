import 'dart:convert';
import 'dart:io';

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

  testWidgets('WYSIWYG drag selection can copy multiple paragraphs', (
    tester,
  ) async {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: 'First\n\nSecond\n\nThird\n',
    );
    String? copiedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          final arguments = call.arguments as Map<Object?, Object?>;
          copiedText = arguments['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

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

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(TextField).at(0)),
    );
    await gesture.moveTo(tester.getCenter(find.byType(TextField).at(1)));
    await gesture.up();
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(copiedText, 'First\n\nSecond');
  });

  testWidgets('WYSIWYG toolbar bold applies to selected paragraphs', (
    tester,
  ) async {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: 'First\n\nSecond\n\nThird\n',
    );
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

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(TextField).at(0)),
    );
    await gesture.moveTo(tester.getCenter(find.byType(TextField).at(1)));
    await gesture.up();
    await tester.pump();

    await tester.tap(find.byIcon(Icons.format_bold));
    await tester.pump();

    expect(markdown, '**First**\n\n**Second**\n\nThird\n');
  });

  testWidgets('WYSIWYG toolbar list applies to selected paragraphs', (
    tester,
  ) async {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: 'First\n\nSecond\n\nThird\n',
    );
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

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(TextField).at(0)),
    );
    await gesture.moveTo(tester.getCenter(find.byType(TextField).at(1)));
    await gesture.up();
    await tester.pump();

    await tester.tap(find.byIcon(Icons.format_list_bulleted));
    await tester.pump();

    expect(markdown, '- First\n\n- Second\n\nThird\n');
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

  test('WYSIWYG inline code command serializes selected text', () {
    final parsed = parser.parse(filePath: 'topic.md', source: 'Alpha Beta\n');
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );
    final blockId = parsed.busyDocument.blocks.first.id;

    controller.applyInlineCommand(
      blockId,
      BusyWysiwygInlineCommand.code,
      6,
      10,
    );

    expect(controller.markdown, 'Alpha `Beta`\n');
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

  test('WYSIWYG block commands apply to multiple selected blocks', () {
    final parsed = parser.parse(filePath: 'topic.md', source: 'One\n\nTwo\n');
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );
    final blockIds = controller.document.blocks.map((block) => block.id);

    controller.applyBlockCommandToBlocks(
      blockIds,
      BusyWysiwygBlockCommand.orderedList,
    );

    expect(controller.document.blocks[0].attributes['marker'], '1.');
    expect(controller.document.blocks[1].attributes['marker'], '2.');
    expect(controller.markdown, '1. One\n\n2. Two\n');
  });

  test('WYSIWYG inline commands apply to multiple selected blocks', () {
    final parsed = parser.parse(filePath: 'topic.md', source: 'One\n\nTwo\n');
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );
    final blockIds = controller.document.blocks.map((block) => block.id);

    controller.applyInlineCommandToBlocks(
      blockIds,
      BusyWysiwygInlineCommand.bold,
    );

    expect(controller.markdown, '**One**\n\n**Two**\n');
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

  testWidgets('WYSIWYG editor renders Writerside images by basename', (
    tester,
  ) async {
    final temp = Directory.systemTemp.createTempSync('busymark_wysiwyg_image_');
    try {
      final topicsDir = Directory('${temp.path}/topics')..createSync();
      final imagesDir = Directory('${temp.path}/images')..createSync();
      File('${imagesDir.path}/rpi_1.jpg').writeAsBytesSync(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAFgwJ/l8Kz3wAAAABJRU5ErkJggg==',
        ),
      );
      final document = BusyDocument(
        filePath: '${topicsDir.path}/topic.md',
        mode: MarkdownMode.writersideMarkdown,
        blocks: const [
          BusyBlock(
            id: 'image',
            kind: BusyBlockKind.image,
            inlines: [
              BusyInline(
                kind: BusyInlineKind.image,
                text: 'Raspberry Pi',
                destination: 'rpi_1.jpg',
              ),
            ],
            attributes: {'src': 'rpi_1.jpg'},
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 900,
              height: 640,
              child: BusyMarkWysiwygEditor(
                document: document,
                workspaceRoot: topicsDir.path,
                writersideRoot: temp.path,
                imagesDir: 'images',
                onSourceChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Image), findsOneWidget);
      expect(find.text('rpi_1.jpg'), findsNothing);
    } finally {
      temp.deleteSync(recursive: true);
    }
  });

  test('WYSIWYG Enter splits one block into separate Markdown paragraphs', () {
    final parsed = parser.parse(filePath: 'topic.md', source: 'FirstSecond\n');
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );
    final blockId = parsed.busyDocument.blocks.first.id;

    final nextBlockId = controller.splitBlockAt(blockId, 'First'.length);

    expect(nextBlockId, isNotNull);
    expect(controller.markdown, 'First\n\nSecond\n');
  });

  test('WYSIWYG Enter in unordered list creates next item then exits list', () {
    final parsed = parser.parse(filePath: 'topic.md', source: '- First\n');
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );
    final blockId = parsed.busyDocument.blocks.first.id;

    final nextItem = controller.applyEnterAt(blockId, 'First'.length);

    expect(nextItem, isNotNull);
    expect(
      controller.document.blocks.map((block) => block.kind),
      containsAllInOrder([
        BusyBlockKind.unorderedListItem,
        BusyBlockKind.unorderedListItem,
      ]),
    );
    expect(controller.markdown, '- First\n\n-\n');

    final paragraph = controller.applyEnterAt(nextItem!.blockId, 0);

    expect(paragraph?.blockId, nextItem.blockId);
    expect(controller.document.blocks[1].kind, BusyBlockKind.paragraph);
    expect(controller.markdown, '- First\n');
  });

  test('WYSIWYG Enter in ordered list creates next numbered item', () {
    final parsed = parser.parse(filePath: 'topic.md', source: '1. First\n');
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );
    final blockId = parsed.busyDocument.blocks.first.id;

    final nextItem = controller.applyEnterAt(blockId, 'First'.length);

    expect(nextItem, isNotNull);
    expect(controller.document.blocks[1].kind, BusyBlockKind.orderedListItem);
    expect(controller.document.blocks[1].attributes['marker'], '2.');
    expect(controller.markdown, '1. First\n\n2.\n');
  });

  test('WYSIWYG thematic break inserts after current block', () {
    final parsed = parser.parse(filePath: 'topic.md', source: 'Intro\n');
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );
    final blockId = parsed.busyDocument.blocks.first.id;

    controller.insertThematicBreakAfter(blockId);

    expect(controller.markdown, 'Intro\n\n---\n');
  });

  testWidgets('WYSIWYG Enter key creates a new paragraph block', (
    tester,
  ) async {
    final parsed = parser.parse(filePath: 'topic.md', source: 'FirstSecond\n');
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

    final firstField = tester.widget<TextField>(find.byType(TextField).first);
    firstField.controller!.selection = const TextSelection.collapsed(offset: 5);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(markdown, 'First\n\nSecond\n');
    expect(find.byType(TextField), findsNWidgets(2));
    expect(
      tester
          .widget<TextField>(find.byType(TextField).at(1))
          .focusNode
          ?.hasFocus,
      isTrue,
    );
  });

  testWidgets('WYSIWYG text input newlines become Markdown paragraphs', (
    tester,
  ) async {
    final parsed = parser.parse(filePath: 'topic.md', source: 'First\n');
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

    await tester.enterText(find.byType(TextField).first, 'First\nSecond');
    await tester.pump();

    expect(markdown, 'First\n\nSecond\n');
    expect(find.byType(TextField), findsNWidgets(2));
  });

  testWidgets('WYSIWYG editor lazily builds large documents', (tester) async {
    final source = List.generate(
      500,
      (index) => 'Paragraph ${index + 1}',
    ).join('\n\n');
    final parsed = parser.parse(filePath: 'topic.md', source: source);

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

    expect(find.byType(TextField).evaluate().length, lessThan(80));
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
