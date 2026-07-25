import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/l10n/generated/app_localizations_de.dart';
import 'package:busymark/l10n/generated/app_localizations_en.dart';
import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/busymark_glyphs.dart';
import 'package:busymark/src/app/busymark_shortcuts.dart';
import 'package:busymark/src/editor/document_callout.dart';
import 'package:busymark/src/editor/document_layout.dart';
import 'package:busymark/src/editor/markdown_image_view.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_block_widgets.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_commands.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_document_controller.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_inline_controller.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_toolbar.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/busymark_markdown_serializer.dart';
import 'package:busymark/src/markdown/document_outline.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/markdown/preview_model.dart';
import 'package:busymark/src/platform/linux_header_bar_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:yaru/yaru.dart';

void main() {
  const parser = MarkdownParser();

  test('WYSIWYG hit testing includes shared document surface borders', () {
    const codeBlock = BusyBlock(id: 'code', kind: BusyBlockKind.codeBlock);

    expect(
      busyMarkWysiwygContentPadding(codeBlock),
      BusyMarkInsets.documentCodeContent,
    );
    expect(
      busyMarkWysiwygTextLayoutInsets(codeBlock),
      const EdgeInsets.all(BusyMarkSpacing.mdPlus + BusyMarkStroke.hairline),
    );
  });

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

  test('linked remote image paragraphs import as editable image blocks', () {
    const imageUrl = 'https://snapcraft.io/busymark/badge.svg';
    const linkUrl = 'https://snapcraft.io/busymark';
    final parsed = parser.parse(
      filePath: 'README.md',
      source: '[![busymark]($imageUrl)]($linkUrl)\n',
    );
    final block = parsed.busyDocument.blocks.single;

    expect(block.kind, BusyBlockKind.image);
    expect(block.attributes['src'], imageUrl);
    expect(block.plainText, 'busymark');
    expect(block.inlines.single.kind, BusyInlineKind.link);
    expect(block.inlines.single.destination, linkUrl);
    expect(block.inlines.single.children.single.kind, BusyInlineKind.image);
    expect(parsed.images.single.destination, imageUrl);
    expect(parsed.links.single.destination, linkUrl);
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

  test('serializer preserves safe raw HTML source byte for byte', () {
    const source =
        '<table>\n'
        '  <caption>Metrics</caption>\n'
        '  <tr><td>A</td></tr>\n'
        '</table>\n';
    final parsed = parser.parse(filePath: 'topic.md', source: source);
    final block = parsed.busyDocument.blocks.single;

    expect(block.kind, BusyBlockKind.htmlBlock);
    expect(block.preserveRaw, isTrue);
    expect(block.dirty, isFalse);
    expect(block.attributes['sourceFormat'], 'html');
    expect(
      const BusyMarkMarkdownSerializer().serialize(parsed.busyDocument),
      source,
    );
  });

  test(
    'serializer preserves unsafe raw HTML source while preview remains raw',
    () {
      const source = '<script>alert(1)</script>\n';
      final parsed = parser.parse(filePath: 'topic.md', source: source);
      final preview = const BusyMarkPreviewBuilder().build(parsed.busyDocument);

      expect(parsed.busyDocument.blocks.single.kind, BusyBlockKind.htmlBlock);
      expect(parsed.busyDocument.blocks.single.preserveRaw, isTrue);
      expect(preview.blocks.single.kind, PreviewBlockKind.raw);
      expect(
        const BusyMarkMarkdownSerializer().serialize(parsed.busyDocument),
        source,
      );
    },
  );

  test(
    'serializer patches dirty blocks without canonicalizing unchanged source',
    () {
      final parsed = parser.parse(
        filePath: 'topic.md',
        source: '# Title\n\nParagraph with   spacing\n\nSecond\n',
      );
      final controller = BusyMarkWysiwygDocumentController(
        document: parsed.busyDocument,
      );
      final secondBlockId = controller.document.blocks.last.id;

      controller.updateBlockText(secondBlockId, 'Changed');

      expect(
        controller.markdown,
        '# Title\n\nParagraph with   spacing\n\nChanged\n',
      );
    },
  );

  test('unrelated edits preserve source-only reference definitions', () {
    for (final source in const [
      '[guide]: docs.md "Title"\nOriginal\n',
      'Before\n\n[guide]: docs.md "Title"\n\nOriginal\n',
      'Original\n\n[guide]: docs.md "Title"\n',
      '[one]: one.md\n[two]: two.md "Two"\nOriginal\n',
      '[guide]:\n  docs.md\n  "Title"\nOriginal\n',
      '[label]:\n[dest]:thing\nOriginal\n',
      '[label]: docs.md "\n[x]: inside title\n"\nOriginal\n',
      '[guide]: docs.md "Title"\r\nOriginal\r\n',
    ]) {
      final parsed = parser.parse(filePath: 'topic.md', source: source);
      final target = parsed.busyDocument.blocks.firstWhere(
        (block) => block.plainText == 'Original',
      );
      final sourceOnlyBlocks = parsed.busyDocument.blocks.where(
        (block) => block.isSourceOnly,
      );
      final controller = BusyMarkWysiwygDocumentController(
        document: parsed.busyDocument,
      );

      expect(sourceOnlyBlocks, isNotEmpty, reason: 'input: $source');
      expect(target.sourceSpan, isNotNull, reason: 'input: $source');
      expect(target.rawSource, 'Original', reason: 'input: $source');

      controller.updateBlockText(target.id, 'Changed');

      expect(
        controller.markdown,
        source.replaceFirst('Original', 'Changed'),
        reason: 'input: $source',
      );
    }
  });

  test('source-only definitions survive scanner and AST count mismatches', () {
    const blockquoteSource =
        '[guide]: docs.md\n\n'
        'Original\n'
        '> Quote\n';
    final blockquoteParsed = parser.parse(
      filePath: 'topic.md',
      source: blockquoteSource,
    );
    final blockquoteTarget = blockquoteParsed.busyDocument.blocks.firstWhere(
      (block) => block.plainText == 'Original',
    );
    final blockquoteController = BusyMarkWysiwygDocumentController(
      document: blockquoteParsed.busyDocument,
    );

    blockquoteController.updateBlockText(blockquoteTarget.id, 'Changed');

    expect(
      blockquoteController.markdown,
      blockquoteSource.replaceFirst('Original', 'Changed'),
    );

    const looseListSource =
        '[guide]: docs.md\n\n'
        '- item\n\n'
        '  continuation\n\n'
        'Original\n';
    final looseListParsed = parser.parse(
      filePath: 'topic.md',
      source: looseListSource,
    );
    final looseListTarget = looseListParsed.busyDocument.blocks.firstWhere(
      (block) => block.plainText == 'Original',
    );
    final looseListController = BusyMarkWysiwygDocumentController(
      document: looseListParsed.busyDocument,
    );

    expect(looseListTarget.sourceSpan, isNull);
    expect(
      looseListParsed.busyDocument.blocks.any((block) => block.isSourceOnly),
      isTrue,
    );

    looseListController.updateBlockText(looseListTarget.id, 'Changed');

    expect(looseListController.markdown, contains('[guide]: docs.md'));
    expect(
      RegExp(
        r'^\[guide\]:',
        multiLine: true,
      ).allMatches(looseListController.markdown),
      hasLength(1),
    );
    expect(looseListController.markdown, contains('Changed'));
  });

  test('preserved reference definitions still resolve after an edit', () {
    const source =
        '[Guide][guide]\n\n'
        '[guide]: docs.md "Title"\n\n'
        'Original\n';
    final parsed = parser.parse(filePath: 'topic.md', source: source);
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );
    final target = controller.document.blocks.firstWhere(
      (block) => block.plainText == 'Original',
    );

    controller.updateBlockText(target.id, 'Changed');

    final reparsed = parser.parse(
      filePath: 'topic.md',
      source: controller.markdown,
    );
    expect(controller.markdown, source.replaceFirst('Original', 'Changed'));
    expect(reparsed.links.map((link) => link.destination), contains('docs.md'));
    expect(
      const BusyMarkPreviewBuilder()
          .build(reparsed.busyDocument)
          .blocks
          .map((block) => block.text),
      isNot(contains('[guide]: docs.md "Title"')),
    );
  });

  test('unrelated edits preserve GFM footnote definitions', () {
    for (final source in const [
      '[^note]: Footnote text\n\nOriginal\n',
      '[^note]: First\n    continued\n\nOriginal\n',
      'Use[^note].\n\n[^note]: Footnote text\n\nOriginal\n',
    ]) {
      final parsed = parser.parse(filePath: 'topic.md', source: source);
      final target = parsed.busyDocument.blocks.firstWhere(
        (block) => block.plainText == 'Original',
      );
      final controller = BusyMarkWysiwygDocumentController(
        document: parsed.busyDocument,
      );

      expect(
        parsed.busyDocument.blocks.any((block) => block.isSourceOnly),
        isTrue,
        reason: 'input: $source',
      );
      expect(target.rawSource, 'Original', reason: 'input: $source');
      if (source.startsWith('Use')) {
        expect(
          parsed.busyDocument.blocks.any((block) => block.isGenerated),
          isTrue,
        );
      }

      controller.updateBlockText(target.id, 'Changed');

      expect(
        controller.markdown,
        source.replaceFirst('Original', 'Changed'),
        reason: 'input: $source',
      );
    }
  });

  test('containers with nested definitions are source-protected', () {
    Iterable<BusyBlock> flatten(BusyBlock block) sync* {
      yield block;
      for (final child in block.children) {
        yield* flatten(child);
      }
    }

    for (final source in const [
      '> [guide]: docs.md\n>\n> Original\n\nOutside\n',
      '- [guide]: docs.md\n  Original\n\nOutside\n',
      '> [^note]: Note\n>\n> Original\n\nOutside\n',
    ]) {
      final parsed = parser.parse(filePath: 'topic.md', source: source);
      final protected = parsed.busyDocument.blocks.firstWhere(
        (block) => block.isSourceProtected,
      );
      final nestedTarget = flatten(
        protected,
      ).firstWhere((block) => block.plainText == 'Original');
      final outside = parsed.busyDocument.blocks.firstWhere(
        (block) => block.plainText == 'Outside',
      );
      final controller = BusyMarkWysiwygDocumentController(
        document: parsed.busyDocument,
      );

      expect(protected.preserveRaw, isTrue, reason: 'input: $source');
      expect(protected.rawSource, contains(']:'), reason: 'input: $source');
      expect(
        flatten(protected).every((block) => block.isSourceProtected),
        isTrue,
        reason: 'input: $source',
      );

      controller.updateBlockText(nestedTarget.id, 'Changed');
      expect(controller.markdown, source, reason: 'input: $source');

      controller.updateBlockText(outside.id, 'Changed outside');
      expect(
        controller.markdown,
        source.replaceFirst('Outside', 'Changed outside'),
        reason: 'input: $source',
      );
    }
  });

  test('scanner mismatches conservatively protect nested definitions', () {
    const source =
        '> [guide]: docs.md\n'
        '>\n'
        '> Original\n\n'
        '- item\n\n'
        '  continuation\n\n'
        'Outside\n';
    final parsed = parser.parse(filePath: 'topic.md', source: source);
    final protectedBlocks = parsed.busyDocument.blocks.where(
      (block) => block.isSourceProtected && !block.isSourceOnly,
    );
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );
    final appended = controller.document.blocks.firstWhere(
      (block) =>
          !block.isSourceOnly && !block.isGenerated && !block.isSourceProtected,
    );

    expect(protectedBlocks, isNotEmpty);
    expect(protectedBlocks.every((block) => block.isGenerated), isTrue);
    expect(
      parsed.busyDocument.blocks.any(
        (block) => block.isSourceOnly && block.rawSource!.contains('[guide]:'),
      ),
      isTrue,
    );

    controller.updateBlockText(appended.id, 'Appended');

    expect(controller.markdown, contains('[guide]: docs.md'));
    expect(controller.markdown, contains('Original'));
    expect(controller.markdown, contains('Outside'));
    expect(controller.markdown, contains('Appended'));
    expect(
      RegExp(r'\[guide\]: docs\.md').allMatches(controller.markdown),
      hasLength(1),
    );
  });

  test('opaque source IDs cannot collide with semantic heading IDs', () {
    const source =
        '# Source only 0\n\n'
        '> [guide]: docs.md\n'
        '>\n'
        '> Original\n\n'
        '- item\n\n'
        '  continuation\n';
    final parsed = parser.parse(filePath: 'topic.md', source: source);
    final opaque = parsed.busyDocument.blocks.firstWhere(
      (block) => block.isSourceOnly,
    );
    final heading = parsed.busyDocument.blocks.firstWhere(
      (block) => block.kind == BusyBlockKind.heading,
    );
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );

    expect(heading.attributes['id'], 'source-only-0');
    expect(opaque.id, isNot(heading.id));

    controller.applyBlockCommand(heading.id, BusyWysiwygBlockCommand.paragraph);
    controller.updateBlockText(opaque.id, 'Erased');

    expect(controller.markdown, source);
  });

  test('full list serialization preserves reference definitions', () {
    const source = '[guide]: docs.md "Title"\n\n- Original\n';
    final parsed = parser.parse(filePath: 'topic.md', source: source);
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );
    final item = controller.document.blocks.firstWhere(
      (block) => block.kind == BusyBlockKind.unorderedListItem,
    );

    controller.updateBlockText(item.id, 'Changed');

    expect(controller.markdown, '[guide]: docs.md "Title"\n\n- Changed\n');
  });

  test('full serialization omits generated footnote output', () {
    const source =
        'Use[^note].\n\n'
        '[^note]: Footnote text\n\n'
        '- Original\n';
    final parsed = parser.parse(filePath: 'topic.md', source: source);
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );
    final item = controller.document.blocks.firstWhere(
      (block) => block.kind == BusyBlockKind.unorderedListItem,
    );

    controller.updateBlockText(item.id, 'Changed');

    expect(controller.markdown, contains('[^note]: Footnote text'));
    expect(
      RegExp(r'\[\^note\]: Footnote text').allMatches(controller.markdown),
      hasLength(1),
    );
    expect(controller.markdown, contains('- Changed'));
    expect(controller.markdown, isNot(contains('\u21a9')));
  });

  test('invalid reference-like prose remains a modeled block', () {
    const source = '[guide] is ordinary prose\n\nOriginal\n';
    final parsed = parser.parse(filePath: 'topic.md', source: source);

    expect(
      parsed.busyDocument.blocks.any((block) => block.isSourceOnly),
      isFalse,
    );
    expect(
      parsed.busyDocument.blocks.first.plainText,
      '[guide] is ordinary prose',
    );
  });

  test('large inline-link documents do not create source-only blocks', () {
    final source = [
      for (var index = 0; index < 2000; index++) '[Link $index](docs.md)\n',
    ].join('\n');

    final parsed = parser.parse(filePath: 'topic.md', source: source);

    expect(
      parsed.busyDocument.blocks.any((block) => block.isSourceOnly),
      isFalse,
    );
    expect(parsed.links, hasLength(2000));
  });

  test('large adjacent definition sets stay distinct and preserved', () {
    final definitions = [
      for (var index = 0; index < 500; index++)
        '[reference-$index]: docs/$index.md',
    ].join('\n');
    final source = '$definitions\nOriginal\n';
    final parsed = parser.parse(filePath: 'topic.md', source: source);
    final target = parsed.busyDocument.blocks.firstWhere(
      (block) => block.plainText == 'Original',
    );
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );

    expect(
      parsed.busyDocument.blocks.where((block) => block.isSourceOnly),
      hasLength(500),
    );

    controller.updateBlockText(target.id, 'Changed');

    expect(controller.markdown, source.replaceFirst('Original', 'Changed'));
  });

  test('destructive selections reject read-only source endpoints', () {
    const source =
        '> [guide]: docs.md\n'
        '>\n'
        '> Original\n\n'
        'After text\n';
    final parsed = parser.parse(filePath: 'topic.md', source: source);
    final protected = parsed.busyDocument.blocks.firstWhere(
      (block) => block.isSourceProtected,
    );
    final after = parsed.busyDocument.blocks.firstWhere(
      (block) => block.plainText == 'After text',
    );
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );

    final result = controller.deleteTextSelection(
      firstBlockId: protected.id,
      firstStartOffset: 0,
      lastBlockId: after.id,
      lastEndOffset: 2,
      removedBlockIds: [protected.id, after.id],
    );

    expect(result, isNull);
    expect(controller.markdown, source);
  });

  test('list indentation cannot attach content to a protected item', () {
    const source =
        '- [guide]: docs.md\n'
        '  Original\n'
        '- Keep me\n'
        '- Edit me\n';
    final parsed = parser.parse(filePath: 'topic.md', source: source);
    final keep = parsed.busyDocument.blocks.firstWhere(
      (block) => block.plainText == 'Keep me',
    );
    final edit = parsed.busyDocument.blocks.firstWhere(
      (block) => block.plainText == 'Edit me',
    );
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );

    controller.indentListItems([keep.id]);
    controller.updateBlockText(edit.id, 'Edited');

    expect(controller.markdown, contains('[guide]: docs.md'));
    expect(controller.markdown, contains('Keep me'));
    expect(controller.markdown, contains('Edited'));
  });

  test('WYSIWYG nested list text edit updates Markdown source', () {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: '- Parent\n  - Child\n',
    );
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );
    final childId = controller.document.blocks.single.children.single.id;

    controller.updateBlockText(childId, 'Changed');

    expect(controller.markdown, '- Parent\n  - Changed\n');
    final reparsed = parser.parse(
      filePath: 'topic.md',
      source: controller.markdown,
    );
    expect(
      reparsed.busyDocument.blocks.single.children.single.plainText,
      'Changed',
    );
  });

  test('WYSIWYG ordered list edits preserve nested children', () {
    for (final (source, expected) in const [
      ('1. Parent\n   - Child\n', '1. Parent\n   - Changed\n'),
      ('100. Parent\n     - Child\n', '100. Parent\n     - Changed\n'),
    ]) {
      final parsed = parser.parse(filePath: 'topic.md', source: source);
      final controller = BusyMarkWysiwygDocumentController(
        document: parsed.busyDocument,
      );
      final childId = controller.document.blocks.single.children.single.id;

      controller.updateBlockText(childId, 'Changed');

      expect(controller.markdown, expected, reason: 'input: $source');
      final reparsed = parser.parse(
        filePath: 'topic.md',
        source: controller.markdown,
      );
      expect(reparsed.busyDocument.blocks, hasLength(1));
      expect(reparsed.busyDocument.blocks.single.children, hasLength(1));
      expect(
        reparsed.busyDocument.blocks.single.children.single.plainText,
        'Changed',
      );
    }
  });

  test('WYSIWYG ordered task edits preserve marker and nested children', () {
    const source = '100. [ ] Parent\n     - Child\n';
    final parsed = parser.parse(filePath: 'topic.md', source: source);
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );
    final parent = controller.document.blocks.single;
    final childId = parent.children.single.id;

    controller.updateBlockText(childId, 'Changed');

    expect(controller.markdown, '100. [ ] Parent\n     - Changed\n');
    final reparsed = parser.parse(
      filePath: 'topic.md',
      source: controller.markdown,
    );
    final reparsedParent = reparsed.busyDocument.blocks.single;
    expect(reparsedParent.kind, BusyBlockKind.taskListItem);
    expect(reparsedParent.attributes['ordered'], 'true');
    expect(reparsedParent.attributes['marker'], '100.');
    expect(reparsedParent.children.single.plainText, 'Changed');
  });

  test('WYSIWYG nested blockquote edit preserves surrounding source', () {
    const source =
        'Before   spacing\n\n'
        '> Original\n\n'
        'After   spacing\n';
    final parsed = parser.parse(filePath: 'topic.md', source: source);
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );
    final quote = controller.document.blocks.firstWhere(
      (block) => block.kind == BusyBlockKind.blockquote,
    );

    controller.updateBlockText(quote.children.single.id, 'Changed');

    expect(
      controller.markdown,
      'Before   spacing\n\n> Changed\n\nAfter   spacing\n',
    );
  });

  test('WYSIWYG cross-block deletion prunes an emptied blockquote', () {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: 'Before\n\n> Quote\n\nAfter\n',
    );
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );
    final before = controller.document.blocks.first;
    final quote = controller.document.blocks[1];
    final quoteParagraph = quote.children.single;
    final after = controller.document.blocks.last;

    final result = controller.deleteTextSelection(
      firstBlockId: before.id,
      firstStartOffset: 0,
      lastBlockId: after.id,
      lastEndOffset: after.plainText.length,
      removedBlockIds: [before.id, quoteParagraph.id, after.id],
    );

    expect(result, isNotNull);
    expect(
      controller.document.blocks,
      isNot(
        contains(
          isA<BusyBlock>().having(
            (block) => block.kind,
            'kind',
            BusyBlockKind.blockquote,
          ),
        ),
      ),
    );
    expect(controller.markdown, isNot(contains('>')));
  });

  test('WYSIWYG nested inline edit updates Markdown source', () {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: '- Parent\n  - Child\n',
    );
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );
    final childId = controller.document.blocks.single.children.single.id;

    controller.applyInlineCommand(
      childId,
      BusyWysiwygInlineCommand.bold,
      0,
      'Child'.length,
    );

    expect(controller.markdown, '- Parent\n  - **Child**\n');
  });

  test('WYSIWYG nested block removal updates Markdown source', () {
    const tableSource =
        '| Name | Value |\n'
        '| --- | --- |\n'
        '| A | B |';
    final controller = BusyMarkWysiwygDocumentController(
      document: BusyDocument(
        filePath: 'topic.md',
        mode: MarkdownMode.commonMark,
        blocks: const [
          BusyBlock(
            id: 'parent',
            kind: BusyBlockKind.unorderedListItem,
            inlines: [BusyInline(kind: BusyInlineKind.text, text: 'Parent')],
            children: [
              BusyBlock(
                id: 'table',
                kind: BusyBlockKind.table,
                rawSource: tableSource,
              ),
            ],
            rawSource:
                '- Parent\n\n'
                '  | Name | Value |\n'
                '  | --- | --- |\n'
                '  | A | B |',
          ),
        ],
      ),
    );

    controller.deleteTable('table');

    expect(controller.document.blocks.single.dirty, isTrue);
    expect(controller.markdown, '- Parent\n');
  });

  test('parser includes setext headings in heading metadata', () {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: 'Title\n=====\n\nSection\n-------\n',
    );

    expect(parsed.headings.map((heading) => (heading.level, heading.text)), [
      (1, 'Title'),
      (2, 'Section'),
    ]);
    expect(parsed.title, 'Title');
    expect(parsed.anchors, containsAll(['title', 'section']));
  });

  test('live document outline follows top-level generated heading order', () {
    const headingAttributes = {'level': '1', 'generatedId': 'true'};
    const nestedHeading = BusyBlock(
      id: 'nested-heading',
      kind: BusyBlockKind.heading,
      inlines: [BusyInline(kind: BusyInlineKind.text, text: 'Same')],
      attributes: headingAttributes,
    );
    const firstHeading = BusyBlock(
      id: 'first-heading',
      kind: BusyBlockKind.heading,
      inlines: [BusyInline(kind: BusyInlineKind.text, text: 'Same')],
      attributes: headingAttributes,
    );
    const secondHeading = BusyBlock(
      id: 'second-heading',
      kind: BusyBlockKind.heading,
      inlines: [BusyInline(kind: BusyInlineKind.text, text: 'Same')],
      attributes: headingAttributes,
    );
    const document = BusyDocument(
      filePath: 'topic.md',
      mode: MarkdownMode.commonMark,
      blocks: [
        BusyBlock(
          id: 'quote',
          kind: BusyBlockKind.blockquote,
          children: [nestedHeading],
        ),
        firstHeading,
        secondHeading,
      ],
    );

    expect(document.outline.map((heading) => heading.id), ['same', 'same-1']);
    expect(document.outline.map((heading) => heading.editorBlockId), [
      'first-heading',
      'second-heading',
    ]);

    final renamed = document.copyWith(
      blocks: [
        document.blocks.first,
        firstHeading.copyWith(
          inlines: const [BusyInline(kind: BusyInlineKind.text, text: 'Other')],
        ),
        secondHeading,
      ],
    );
    expect(renamed.outline.map((heading) => heading.id), ['other', 'same']);
  });

  test('duplicate anchors retain distinct editor block identities', () {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source:
          '# First {id="same"}\n\n'
          '# Second {id="same"}\n',
    );
    final headingBlocks = parsed.busyDocument.blocks
        .where((block) => block.kind == BusyBlockKind.heading)
        .toList();

    expect(headingBlocks.map((block) => block.id).toSet(), hasLength(2));
    expect(
      headingBlocks.map((block) => block.attributes['id']),
      everyElement('same'),
    );
    expect(parsed.busyDocument.outline.map((heading) => heading.id), [
      'same',
      'same',
    ]);
    expect(
      parsed.busyDocument.outline
          .map((heading) => heading.editorBlockId)
          .toSet(),
      hasLength(2),
    );
    expect(
      parsed.diagnostics.map((diagnostic) => diagnostic.code),
      contains('markdown.heading.duplicate-id'),
    );
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
    String? sourceFilePath;

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
              onSourceChanged: (filePath, value) {
                sourceFilePath = filePath;
                markdown = value;
              },
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
    expect(sourceFilePath, 'Untitled.md');
    expect(find.text('Editable text'), findsOneWidget);
  });

  testWidgets('WYSIWYG renders a blockquote around its editable text', (
    tester,
  ) async {
    var markdown = '';
    final parsed = parser.parse(
      filePath: 'topic.md',
      source:
          '> „Code sollte wie gute Prosa lesbar sein.“\n'
          '> — *Martin Fowler*\n',
    );
    final quote = parsed.busyDocument.blocks.single;
    final paragraph = quote.children.single;

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
              onSourceChanged: (_, value) => markdown = value,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final frame = find.byType(BusyMarkDocumentCallout);
    final childField = find.byKey(
      ValueKey('wysiwyg-field-topic.md-${paragraph.id}'),
    );
    final structuralField = find.byKey(
      ValueKey('wysiwyg-field-topic.md-${quote.id}'),
    );
    final quoteIcon = find.descendant(
      of: frame,
      matching: find.byIcon(BusyMarkGlyphs.blockquote),
    );

    expect(frame, findsOneWidget);
    expect(childField, findsOneWidget);
    expect(structuralField, findsNothing);
    expect(
      find.descendant(of: frame, matching: find.byType(TextField)),
      findsOneWidget,
    );
    expect(quoteIcon, findsOneWidget);
    final iconRect = tester.getRect(quoteIcon);
    final fieldRect = tester.getRect(childField);
    expect(
      iconRect.center.dy,
      inInclusiveRange(fieldRect.top, fieldRect.bottom),
    );
    final field = tester.widget<TextField>(childField);
    expect(field.controller!.text, contains('Code sollte wie gute Prosa'));
    expect(field.controller!.text, contains('Martin Fowler'));

    await tester.enterText(childField, 'Changed');
    await tester.pump();

    expect(markdown, startsWith('> '));
    expect(markdown, contains('Changed'));
  });

  testWidgets('WYSIWYG uses one quote frame for multiple quote paragraphs', (
    tester,
  ) async {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: '> First\n>\n> Second\n',
    );

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
              onSourceChanged: (_, _) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final frame = find.byType(BusyMarkDocumentCallout);
    expect(frame, findsOneWidget);
    expect(
      find.descendant(of: frame, matching: find.byType(TextField)),
      findsNWidgets(2),
    );
    expect(
      find.descendant(
        of: frame,
        matching: find.byIcon(BusyMarkGlyphs.blockquote),
      ),
      findsOneWidget,
    );
  });

  testWidgets('WYSIWYG quote frame focuses its first editable child', (
    tester,
  ) async {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: 'Before\n\n> Quote\n',
    );
    final before = parsed.busyDocument.blocks.first;
    final quote = parsed.busyDocument.blocks.last;
    final quoteParagraph = quote.children.single;

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
              toolbarPlacement: EditorToolbarPlacement.bottomLeft,
              onSourceChanged: (_, _) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    TextField fieldFor(String blockId) => tester.widget<TextField>(
      find.byKey(ValueKey('wysiwyg-field-topic.md-$blockId')),
    );
    expect(fieldFor(before.id).focusNode!.hasFocus, isTrue);

    final frame = find.byType(BusyMarkDocumentCallout);
    await tester.tap(
      find.descendant(
        of: frame,
        matching: find.byIcon(BusyMarkGlyphs.blockquote),
      ),
    );
    await tester.pump();

    expect(fieldFor(quoteParagraph.id).focusNode!.hasFocus, isTrue);
  });

  testWidgets('WYSIWYG inherits RTL indentation inside a blockquote', (
    tester,
  ) async {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: '> - مرحبا\n>   - 123\n',
    );
    final quote = parsed.busyDocument.blocks.single;
    final parentItem = quote.children.single;
    final nestedItem = parentItem.children.single;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Scaffold(
            body: SizedBox(
              width: 900,
              height: 640,
              child: BusyMarkWysiwygEditor(
                document: parsed.busyDocument,
                toolbarPlacement: EditorToolbarPlacement.bottomLeft,
                onSourceChanged: (_, _) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    Finder fieldFor(String blockId) =>
        find.byKey(ValueKey('wysiwyg-field-topic.md-$blockId'));
    final parentField = fieldFor(parentItem.id);
    final nestedField = fieldFor(nestedItem.id);
    final parentRect = tester.getRect(parentField);
    final nestedRect = tester.getRect(nestedField);

    expect(
      tester.widget<TextField>(nestedField).textDirection,
      TextDirection.rtl,
    );
    expect(nestedRect.left, closeTo(parentRect.left, 0.1));
    expect(
      nestedRect.right,
      closeTo(parentRect.right - BusyMarkSizes.wysiwygBlockIndent, 0.1),
    );
  });

  testWidgets('WYSIWYG keeps a generated leaf blockquote editable', (
    tester,
  ) async {
    const document = BusyDocument(
      filePath: 'topic.md',
      mode: MarkdownMode.commonMark,
      blocks: [
        BusyBlock(
          id: 'quote',
          kind: BusyBlockKind.blockquote,
          inlines: [BusyInline(kind: BusyInlineKind.text, text: 'Leaf quote')],
          dirty: true,
        ),
      ],
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
              document: document,
              toolbarPlacement: EditorToolbarPlacement.bottomLeft,
              onSourceChanged: (_, value) => markdown = value,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final field = find.byKey(const ValueKey('wysiwyg-field-topic.md-quote'));
    expect(find.byType(BusyMarkDocumentCallout), findsOneWidget);
    expect(field, findsOneWidget);
    expect(tester.widget<TextField>(field).controller!.text, 'Leaf quote');

    await tester.enterText(field, 'Changed');
    await tester.pump();

    expect(markdown, '> Changed\n');
  });

  testWidgets('WYSIWYG hides a definition-only source and preserves it', (
    tester,
  ) async {
    const source = '[guide]: docs.md "Title"\n';
    final parsed = parser.parse(filePath: 'topic.md', source: source);
    var markdown = source;

    expect(
      const BusyMarkPreviewBuilder().build(parsed.busyDocument).blocks,
      isEmpty,
    );

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
              onSourceChanged: (filePath, value) => markdown = value,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.textContaining('[guide]:'), findsNothing);

    await tester.enterText(find.byType(TextField), 'First line');
    await tester.pump();

    expect(markdown, '[guide]: docs.md "Title"\n\nFirst line\n');
  });

  testWidgets('WYSIWYG editor undo and redo restore document edits', (
    tester,
  ) async {
    final parsed = parser.parse(filePath: 'topic.md', source: 'Original\n');
    var markdown = parsed.source;

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
              onSourceChanged: (filePath, value) => markdown = value,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'Changed');
    await tester.pump();

    expect(markdown, 'Changed\n');
    final editedController = tester
        .widget<TextField>(find.byType(TextField).first)
        .controller!;
    editedController.selection = const TextSelection.collapsed(offset: 2);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(markdown, 'Original\n');
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller?.text,
      'Original',
    );
    expect(
      tester
          .widget<TextField>(find.byType(TextField).first)
          .controller
          ?.selection
          .extentOffset,
      2,
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(markdown, 'Changed\n');
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller?.text,
      'Changed',
    );
  });

  testWidgets('WYSIWYG editor replaces document when active file changes', (
    tester,
  ) async {
    final first = parser.parse(
      filePath: 'first.md',
      source: 'First original\n',
    );
    final second = parser.parse(
      filePath: 'second.md',
      source: 'Second original\n',
    );
    var activeDocument = first.busyDocument;

    Widget buildEditor() {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: activeDocument,
              onSourceChanged: (_, _) {},
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildEditor());
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'Unsaved first tab');
    await tester.pump();

    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller?.text,
      'Unsaved first tab',
    );

    activeDocument = second.busyDocument;
    await tester.pumpWidget(buildEditor());
    await tester.pump();

    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller?.text,
      'Second original',
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller?.text,
      'Second original',
    );
  });

  testWidgets('WYSIWYG editor applies heading keyboard shortcuts', (
    tester,
  ) async {
    final parsed = parser.parse(filePath: 'topic.md', source: 'Title\n');
    var markdown = parsed.source;

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
              onSourceChanged: (filePath, value) => markdown = value,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.digit2);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.digit2);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(markdown, '## Title\n');

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.digit0);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.digit0);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(markdown, 'Title\n');
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: parsed.busyDocument,
              onSourceChanged: (_, _) {},
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: parsed.busyDocument,
              toolbarPlacement: EditorToolbarPlacement.bottomLeft,
              onSourceChanged: (_, _) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final firstFieldRect = tester.getRect(find.byType(TextField).at(0));
    final secondFieldRect = tester.getRect(find.byType(TextField).at(1));
    final gesture = await tester.startGesture(
      firstFieldRect.centerLeft + const Offset(1, 0),
    );
    await gesture.moveTo(secondFieldRect.centerLeft + const Offset(80, 0));
    await gesture.up();
    await tester.pump();

    Color? nativeSelectionColorAt(int index) {
      return TextSelectionTheme.of(
        tester.element(find.byType(TextField).at(index)),
      ).selectionColor;
    }

    expect(nativeSelectionColorAt(0), Colors.transparent);
    expect(nativeSelectionColorAt(1), Colors.transparent);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(copiedText, 'First\n\nSecond');
  });

  testWidgets('WYSIWYG click elsewhere clears previous block selection', (
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: parsed.busyDocument,
              toolbarPlacement: EditorToolbarPlacement.bottomLeft,
              onSourceChanged: (_, _) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final firstFieldRect = tester.getRect(find.byType(TextField).at(0));
    final secondFieldRect = tester.getRect(find.byType(TextField).at(1));
    final thirdFieldRect = tester.getRect(find.byType(TextField).at(2));
    final gesture = await tester.startGesture(
      firstFieldRect.centerLeft + const Offset(1, 0),
    );
    await gesture.moveTo(secondFieldRect.centerLeft + const Offset(80, 0));
    await gesture.up();
    await tester.pump();

    await tester.tapAt(thirdFieldRect.centerLeft + const Offset(8, 0));
    await tester.pump();

    copiedText = null;
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(copiedText, isNull);
  });

  testWidgets('WYSIWYG Shift click selects text across paragraphs', (
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: parsed.busyDocument,
              toolbarPlacement: EditorToolbarPlacement.bottomLeft,
              onSourceChanged: (_, _) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final firstField = tester.widget<TextField>(find.byType(TextField).first);
    firstField.controller!.selection = const TextSelection.collapsed(offset: 0);
    final secondFieldRect = tester.getRect(find.byType(TextField).at(1));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.tapAt(secondFieldRect.centerLeft + const Offset(80, 0));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(copiedText, 'First\n\nSecond');
  });

  testWidgets('WYSIWYG Shift drag extends selection across paragraphs', (
    tester,
  ) async {
    const plannerParagraph =
        'Create a new service - planner-service. Spring Boot application. '
        'Use learner-model and other spring boot services as example.';
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: '## Planner Service\n\n$plannerParagraph\n',
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: parsed.busyDocument,
              toolbarPlacement: EditorToolbarPlacement.bottomLeft,
              onSourceChanged: (_, _) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final headingField = tester.widget<TextField>(find.byType(TextField).at(0));
    headingField.focusNode!.requestFocus();
    headingField.controller!.selection = const TextSelection.collapsed(
      offset: 0,
    );
    await tester.pump();

    final headingRect = tester.getRect(find.byType(TextField).at(0));
    final paragraphRect = tester.getRect(find.byType(TextField).at(1));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    final gesture = await tester.startGesture(
      headingRect.centerLeft + const Offset(2, 0),
    );
    await gesture.moveTo(paragraphRect.bottomRight - const Offset(2, 2));
    await gesture.up();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(copiedText, isNotNull);
    expect(copiedText, contains('Planner Service'));
    expect(copiedText, contains('as example.'));
  });

  testWidgets('WYSIWYG Shift drag from heading end hides native selection', (
    tester,
  ) async {
    const heading = 'Planner Service';
    const plannerParagraph =
        'Create a new service - planner-service. Spring Boot application. '
        'Use learner-model and other spring boot services as example.';
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: '## $heading\n\n$plannerParagraph\n',
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: parsed.busyDocument,
              toolbarPlacement: EditorToolbarPlacement.bottomLeft,
              onSourceChanged: (_, _) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final headingField = tester.widget<TextField>(find.byType(TextField).at(0));
    headingField.focusNode!.requestFocus();
    headingField.controller!.selection = TextSelection.collapsed(
      offset: heading.length,
    );
    await tester.pump();

    final headingRect = tester.getRect(find.byType(TextField).at(0));
    final paragraphRect = tester.getRect(find.byType(TextField).at(1));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    final gesture = await tester.startGesture(
      headingRect.centerRight - const Offset(2, 0),
    );
    await gesture.moveTo(paragraphRect.bottomRight - const Offset(2, 2));
    await gesture.up();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();

    Color? nativeSelectionColorAt(int index) {
      return TextSelectionTheme.of(
        tester.element(find.byType(TextField).at(index)),
      ).selectionColor;
    }

    expect(nativeSelectionColorAt(0), Colors.transparent);
    expect(nativeSelectionColorAt(1), Colors.transparent);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(copiedText, plannerParagraph);
  });

  testWidgets('WYSIWYG reverse drag updates selection on pointer up', (
    tester,
  ) async {
    const heading = 'Planner Service';
    const firstParagraph =
        'Create a new service - planner-service. Spring Boot application. '
        'Use learner-model and other spring boot services as example.';
    const secondParagraph =
        'It also has to call learner-model get all candos and to create '
        'schedulers for learner for each cando.';
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: '## $heading\n\n$firstParagraph\n\n$secondParagraph\n',
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: parsed.busyDocument,
              toolbarPlacement: EditorToolbarPlacement.bottomLeft,
              onSourceChanged: (_, _) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final headingRect = tester.getRect(find.byType(TextField).at(0));
    final firstParagraphRect = tester.getRect(find.byType(TextField).at(1));
    final secondParagraphRect = tester.getRect(find.byType(TextField).at(2));
    final gesture = await tester.createGesture(pointer: 42);
    await gesture.down(secondParagraphRect.bottomRight - const Offset(2, 2));
    await gesture.moveTo(firstParagraphRect.centerRight - const Offset(2, 0));
    await gesture.updateWithCustomEvent(
      PointerUpEvent(
        pointer: 42,
        position: headingRect.centerLeft + const Offset(2, 0),
      ),
    );
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(copiedText, contains(heading));
    expect(copiedText, contains('example.'));
    expect(copiedText, contains('cando.'));
  });

  testWidgets('WYSIWYG reverse drag aligns wrapped trailing word highlight', (
    tester,
  ) async {
    const heading = 'Planner Service';
    const firstParagraph =
        'Create a new service - planner-service. Spring Boot application. '
        'Use learner-model and other spring boot services as example.';
    const secondParagraph =
        'It also has to call learner-model get all candos and to create '
        'schedulers for learner for each cando.';
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: '## $heading\n\n$firstParagraph\n\n$secondParagraph\n',
    );
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(textScaler: const TextScaler.linear(1.35)),
            child: child!,
          );
        },
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: parsed.busyDocument,
              toolbarPlacement: EditorToolbarPlacement.bottomLeft,
              onSourceChanged: (_, _) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final headingRect = tester.getRect(find.byType(TextField).at(0));
    final firstParagraphRect = tester.getRect(find.byType(TextField).at(1));
    final secondParagraphRect = tester.getRect(find.byType(TextField).at(2));
    final gesture = await tester.createGesture(pointer: 43);
    await gesture.down(secondParagraphRect.bottomRight - const Offset(2, 2));
    await gesture.moveTo(firstParagraphRect.centerRight - const Offset(2, 0));
    await gesture.updateWithCustomEvent(
      PointerUpEvent(
        pointer: 43,
        position: headingRect.centerLeft + const Offset(2, 0),
      ),
    );
    await tester.pump();

    final textFieldRender = tester.renderObject<RenderObject>(
      find.byType(TextField).at(1),
    );
    final renderEditable = _findRenderEditable(textFieldRender);
    expect(renderEditable, isNotNull);
    final exampleStart = firstParagraph.indexOf('example.');
    final exampleBoxes = renderEditable!.getBoxesForSelection(
      TextSelection(
        baseOffset: exampleStart,
        extentOffset: exampleStart + 'example.'.length,
      ),
    );
    expect(exampleBoxes, isNotEmpty);

    final painterFinder = find.byWidgetPredicate(
      (widget) =>
          widget is CustomPaint &&
          widget.painter.runtimeType.toString() == '_WysiwygSelectionPainter',
    );
    final customPaint = tester.widget<CustomPaint>(painterFinder.at(1));
    final painter = customPaint.painter! as dynamic;
    expect(painter.selectionRange.start, 0);
    expect(painter.selectionRange.end, firstParagraph.length);

    final paintBox = tester.renderObject<RenderBox>(painterFinder.at(1));
    final painterText =
        TextPainter(
          text: TextSpan(
            text: firstParagraph,
            style: painter.style as TextStyle,
          ),
          textDirection: painter.textDirection as TextDirection,
          textScaler: painter.textScaler as TextScaler,
          locale: painter.locale as Locale?,
        )..layout(
          maxWidth: paintBox.size.width - (painter.layoutWidthInset as double),
        );
    final highlightBoxes = painterText.getBoxesForSelection(
      TextSelection(
        baseOffset: exampleStart,
        extentOffset: exampleStart + 'example.'.length,
      ),
    );
    painterText.dispose();

    expect(highlightBoxes, hasLength(exampleBoxes.length));
    final lineTolerance =
        (exampleBoxes.last.bottom - exampleBoxes.last.top) / 3;
    expect(
      (highlightBoxes.last.top - exampleBoxes.last.top).abs(),
      lessThan(lineTolerance),
    );
    expect(
      (highlightBoxes.last.bottom - exampleBoxes.last.bottom).abs(),
      lessThan(lineTolerance),
    );
  });

  testWidgets('WYSIWYG Ctrl+X cuts block selection', (tester) async {
    const source = 'First\n\nSecond\n\nThird\n';
    final parsed = parser.parse(filePath: 'topic.md', source: source);
    var markdown = source;
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: parsed.busyDocument,
              toolbarPlacement: EditorToolbarPlacement.bottomLeft,
              onSourceChanged: (filePath, value) => markdown = value,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final firstFieldRect = tester.getRect(find.byType(TextField).at(0));
    final secondFieldRect = tester.getRect(find.byType(TextField).at(1));
    final gesture = await tester.startGesture(
      firstFieldRect.centerLeft + const Offset(1, 0),
    );
    await gesture.moveTo(secondFieldRect.centerLeft + const Offset(80, 0));
    await gesture.up();
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyX);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyX);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(copiedText, 'First\n\nSecond');
    expect(markdown, contains('Third'));
    expect(markdown, isNot(contains('First')));
    expect(markdown, isNot(contains('Second')));
  });

  testWidgets('WYSIWYG cut paste preserves inline formatting', (tester) async {
    const source = 'Hello **bold** world\n\nTarget\n';
    final parsed = parser.parse(filePath: 'topic.md', source: source);
    var markdown = source;
    String? clipboardText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          final arguments = call.arguments as Map<Object?, Object?>;
          clipboardText = arguments['text'] as String?;
        }
        if (call.method == 'Clipboard.getData') {
          return {'text': clipboardText};
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: parsed.busyDocument,
              onSourceChanged: (filePath, value) => markdown = value,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final firstField = tester.widget<TextField>(find.byType(TextField).at(0));
    firstField.focusNode!.requestFocus();
    firstField.controller!.selection = const TextSelection(
      baseOffset: 6,
      extentOffset: 10,
    );
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyX);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyX);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(clipboardText, 'bold');

    final secondField = tester.widget<TextField>(find.byType(TextField).at(1));
    secondField.focusNode!.requestFocus();
    secondField.controller!.selection = TextSelection.collapsed(
      offset: secondField.controller!.text.length,
    );
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyV);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyV);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(markdown, 'Hello  world\n\nTarget**bold**\n');
  });

  testWidgets('WYSIWYG cut paste preserves whole block formatting', (
    tester,
  ) async {
    const source = '# Title\n\nPara with **bold** text\n\nTail\n';
    final parsed = parser.parse(filePath: 'topic.md', source: source);
    var markdown = source;
    String? clipboardText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          final arguments = call.arguments as Map<Object?, Object?>;
          clipboardText = arguments['text'] as String?;
        }
        if (call.method == 'Clipboard.getData') {
          return {'text': clipboardText};
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: parsed.busyDocument,
              onSourceChanged: (filePath, value) => markdown = value,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final titleField = tester.widget<TextField>(find.byType(TextField).at(0));
    titleField.focusNode!.requestFocus();
    titleField.controller!.selection = TextSelection(
      baseOffset: 0,
      extentOffset: titleField.controller!.text.length,
    );
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyX);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyX);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(clipboardText, 'Title');

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyV);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyV);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(markdown, source);
  });

  testWidgets('WYSIWYG drag selection preserves partial paragraph boundaries', (
    tester,
  ) async {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: 'Alpha first paragraph\n\nBeta second paragraph\n',
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: parsed.busyDocument,
              toolbarPlacement: EditorToolbarPlacement.bottomLeft,
              onSourceChanged: (_, _) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final firstFieldRect = tester.getRect(find.byType(TextField).at(0));
    final secondFieldRect = tester.getRect(find.byType(TextField).at(1));
    final gesture = await tester.startGesture(
      firstFieldRect.centerLeft + const Offset(46, 0),
    );
    await gesture.moveTo(secondFieldRect.centerLeft + const Offset(42, 0));
    await gesture.up();
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(copiedText, isNotNull);
    expect(copiedText, isNot('Alpha first paragraph\n\nBeta second paragraph'));
    expect(copiedText, contains('\n\n'));
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: parsed.busyDocument,
              toolbarPlacement: EditorToolbarPlacement.bottomLeft,
              onSourceChanged: (filePath, value) => markdown = value,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final firstFieldRect = tester.getRect(find.byType(TextField).at(0));
    final secondFieldRect = tester.getRect(find.byType(TextField).at(1));
    final gesture = await tester.startGesture(
      firstFieldRect.centerLeft + const Offset(1, 0),
    );
    await gesture.moveTo(secondFieldRect.centerLeft + const Offset(80, 0));
    await gesture.up();
    await tester.pump();

    await tester.tap(find.byIcon(BusyMarkGlyphs.bold));
    await tester.pump();

    expect(markdown, '**First**\n\n**Second**\n\nThird\n');
  });

  testWidgets(
    'WYSIWYG toolbar toggle stays vertically aligned when collapsed',
    (tester) async {
      final parsed = parser.parse(filePath: 'topic.md', source: 'First\n');

      await tester.pumpWidget(
        MaterialApp(
          theme: buildBusyMarkTheme(
            brightness: Brightness.light,
            accentColor: BusyMarkLinuxPalette.blueAccent,
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 900,
              height: 640,
              child: BusyMarkWysiwygEditor(
                document: parsed.busyDocument,
                onSourceChanged: (_, _) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      YaruIconButton editingToggle(String tooltip) {
        return tester.widget<YaruIconButton>(
          find.byWidgetPredicate(
            (widget) => widget is YaruIconButton && widget.tooltip == tooltip,
          ),
        );
      }

      final colorScheme = Theme.of(
        tester.element(find.byType(BusyMarkWysiwygEditor)),
      ).colorScheme;
      final hideButton = editingToggle('Hide editing buttons');
      expect(
        hideButton.style?.backgroundColor?.resolve(const {}),
        colorScheme.primary,
      );
      expect(
        hideButton.style?.foregroundColor?.resolve(const {}),
        colorScheme.onPrimary,
      );
      final hideRect = tester.getRect(find.byTooltip('Hide editing buttons'));

      await tester.tap(find.byTooltip('Hide editing buttons'));
      await tester.pump();

      final showRect = tester.getRect(find.byTooltip('Show editing buttons'));
      final showButton = editingToggle('Show editing buttons');

      expect(showRect.center.dy, closeTo(hideRect.center.dy, 0.1));
      expect(
        showButton.style?.backgroundColor?.resolve(const {}),
        colorScheme.primary,
      );
      expect(
        showButton.style?.foregroundColor?.resolve(const {}),
        colorScheme.onPrimary,
      );
    },
  );

  testWidgets('editing toolbar reserves its document edge', (tester) async {
    final parsed = parser.parse(filePath: 'topic.md', source: 'First\n');
    expect(
      BusyMarkSizes.wysiwygToolbarClearance,
      BusyMarkSpacing.sm +
          BusyMarkSizes.wysiwygToolbarReserve +
          BusyMarkSpacing.sm,
    );

    Finder editorList() => find.descendant(
      of: find.byType(BusyMarkWysiwygEditor),
      matching: find.byType(ListView),
    );

    for (final direction in EditorToolbarDirection.values) {
      for (final placement in EditorToolbarPlacement.values) {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SizedBox(
                width: 900,
                height: 640,
                child: BusyMarkWysiwygEditor(
                  key: ValueKey('$direction-$placement'),
                  document: parsed.busyDocument,
                  toolbarPlacement: placement,
                  toolbarDirection: direction,
                  onSourceChanged: (_, _) {},
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final expectedLayout = BusyMarkDocumentLayoutSpec.standalone
            .withEditingToolbar(placement: placement, direction: direction);
        final topHorizontalToolbar =
            direction == EditorToolbarDirection.horizontal &&
            (placement == EditorToolbarPlacement.topLeft ||
                placement == EditorToolbarPlacement.topRight);
        final expectedPadding = expectedLayout.scrollPadding;
        expect(
          expectedLayout.minimumInsets.horizontal,
          direction == EditorToolbarDirection.vertical
              ? BusyMarkSizes.wysiwygToolbarClearance + BusyMarkSpacing.xl
              : BusyMarkSpacing.xl * 2,
        );
        expect(editorList(), findsOneWidget);
        expect(tester.widget<ListView>(editorList()).padding, expectedPadding);
        final toolbarScrollView = tester.widget<SingleChildScrollView>(
          find.descendant(
            of: find.byType(BusyMarkWysiwygToolbar),
            matching: find.byType(SingleChildScrollView),
          ),
        );
        expect(
          toolbarScrollView.padding,
          direction == EditorToolbarDirection.horizontal
              ? const EdgeInsets.symmetric(
                  horizontal: BusyMarkSpacing.sm,
                  vertical: BusyMarkSpacing.xs,
                )
              : const EdgeInsets.symmetric(
                  horizontal: BusyMarkSpacing.xs,
                  vertical: BusyMarkSpacing.sm,
                ),
        );
        expect(toolbarScrollView.clipBehavior, Clip.none);
        expect(toolbarScrollView.hitTestBehavior, HitTestBehavior.deferToChild);
        final shownFieldRect = tester.getRect(find.byType(TextField).first);
        if (topHorizontalToolbar) {
          final hideButtonRect = tester.getRect(
            find.byTooltip('Hide editing buttons'),
          );
          expect(shownFieldRect.top, greaterThan(hideButtonRect.bottom));
        }

        await tester.tap(find.byTooltip('Hide editing buttons'));
        await tester.pump();

        expect(tester.widget<ListView>(editorList()).padding, expectedPadding);
        expect(tester.getRect(find.byType(TextField).first), shownFieldRect);
      }
    }
  });

  testWidgets('vertical WYSIWYG toolbar is bounded and extends from its edge', (
    tester,
  ) async {
    final parsed = parser.parse(filePath: 'topic.md', source: 'First\n');

    Future<void> pumpPlacement(EditorToolbarPlacement placement) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 500,
              height: 240,
              child: BusyMarkWysiwygEditor(
                document: parsed.busyDocument,
                toolbarPlacement: placement,
                toolbarDirection: EditorToolbarDirection.vertical,
                onSourceChanged: (_, _) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    Finder toolbarScrollView() => find.descendant(
      of: find.byType(BusyMarkWysiwygToolbar),
      matching: find.byType(SingleChildScrollView),
    );

    await pumpPlacement(EditorToolbarPlacement.topLeft);

    var scrollView = tester.widget<SingleChildScrollView>(toolbarScrollView());
    var scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(BusyMarkWysiwygToolbar),
        matching: find.byType(Scrollable),
      ),
    );
    var toggleRect = tester.getRect(find.byTooltip('Hide editing buttons'));
    var toolbarRect = tester.getRect(toolbarScrollView());
    expect(scrollView.scrollDirection, Axis.vertical);
    expect(scrollable.position.maxScrollExtent, greaterThan(0));
    expect(toolbarRect.height, lessThan(240));
    expect(toolbarRect.top, greaterThanOrEqualTo(toggleRect.bottom));

    await pumpPlacement(EditorToolbarPlacement.bottomLeft);

    scrollView = tester.widget<SingleChildScrollView>(toolbarScrollView());
    scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(BusyMarkWysiwygToolbar),
        matching: find.byType(Scrollable),
      ),
    );
    toggleRect = tester.getRect(find.byTooltip('Hide editing buttons'));
    toolbarRect = tester.getRect(toolbarScrollView());
    expect(scrollView.scrollDirection, Axis.vertical);
    expect(scrollable.position.maxScrollExtent, greaterThan(0));
    expect(toolbarRect.bottom, lessThanOrEqualTo(toggleRect.top));
    expect(tester.takeException(), isNull);
  });

  testWidgets('editing toolbar corners remain physical in LTR and RTL', (
    tester,
  ) async {
    final parsed = parser.parse(filePath: 'topic.md', source: 'First\n');
    const editorWidth = 520.0;
    const editorHeight = 320.0;

    Future<Offset> toggleCenter({
      required EditorToolbarPlacement placement,
      required EditorToolbarDirection toolbarDirection,
      required TextDirection textDirection,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Directionality(
            textDirection: textDirection,
            child: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: editorWidth,
                  height: editorHeight,
                  child: BusyMarkWysiwygEditor(
                    document: parsed.busyDocument,
                    toolbarPlacement: placement,
                    toolbarDirection: toolbarDirection,
                    onSourceChanged: (_, _) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      return tester.getCenter(find.byTooltip('Hide editing buttons'));
    }

    for (final toolbarDirection in EditorToolbarDirection.values) {
      for (final placement in EditorToolbarPlacement.values) {
        final ltr = await toggleCenter(
          placement: placement,
          toolbarDirection: toolbarDirection,
          textDirection: TextDirection.ltr,
        );
        final rtl = await toggleCenter(
          placement: placement,
          toolbarDirection: toolbarDirection,
          textDirection: TextDirection.rtl,
        );

        expect(rtl.dx, closeTo(ltr.dx, 0.1));
        expect(rtl.dy, closeTo(ltr.dy, 0.1));
        final onRight =
            placement == EditorToolbarPlacement.topRight ||
            placement == EditorToolbarPlacement.bottomRight;
        final onBottom =
            placement == EditorToolbarPlacement.bottomLeft ||
            placement == EditorToolbarPlacement.bottomRight;
        expect(ltr.dx, onRight ? greaterThan(260) : lessThan(260));
        expect(ltr.dy, onBottom ? greaterThan(160) : lessThan(160));
      }
    }
  });

  testWidgets(
    'editing toolbar context menu changes placement and direction when shown or hidden',
    (tester) async {
      final parsed = parser.parse(filePath: 'topic.md', source: 'First\n');
      var placement = EditorToolbarPlacement.topLeft;
      var toolbarDirection = EditorToolbarDirection.horizontal;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: SizedBox(
                width: 900,
                height: 360,
                child: BusyMarkWysiwygEditor(
                  document: parsed.busyDocument,
                  toolbarPlacement: placement,
                  toolbarDirection: toolbarDirection,
                  onToolbarPlacementChanged: (value) {
                    setState(() => placement = value);
                  },
                  onToolbarDirectionChanged: (value) {
                    setState(() => toolbarDirection = value);
                  },
                  onSourceChanged: (_, _) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(
        find.byTooltip('Hide editing buttons'),
        buttons: kSecondaryMouseButton,
      );
      await tester.pumpAndSettle();

      final menuItems = find.byWidgetPredicate(
        (widget) => widget is BusyMarkPopupMenuItem,
      );
      BusyMarkPopupMenuItem<dynamic> menuItem(String label) {
        return tester.widget<BusyMarkPopupMenuItem<dynamic>>(
          find.byWidgetPredicate(
            (widget) =>
                widget is BusyMarkPopupMenuItem && widget.label == label,
          ),
        );
      }

      expect(menuItems, findsNWidgets(6));
      expect(menuItem('Top left').checked, isTrue);
      expect(menuItem('Horizontal').checked, isTrue);
      expect(menuItem('Top right').checked, isFalse);
      expect(menuItem('Vertical').checked, isFalse);
      expect(find.byTooltip('Hide editing buttons'), findsOneWidget);
      expect(find.byTooltip('Show editing buttons'), findsNothing);

      await tester.tap(find.text('Bottom right'));
      await tester.pumpAndSettle();
      expect(placement, EditorToolbarPlacement.bottomRight);

      await tester.tap(find.byTooltip('Hide editing buttons'));
      await tester.pump();
      expect(find.byTooltip('Show editing buttons'), findsOneWidget);

      await tester.tap(
        find.byTooltip('Show editing buttons'),
        buttons: kSecondaryMouseButton,
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Show editing buttons'), findsOneWidget);
      expect(find.byTooltip('Hide editing buttons'), findsNothing);
      expect(menuItem('Bottom right').checked, isTrue);
      expect(menuItem('Horizontal').checked, isTrue);

      await tester.tap(find.text('Vertical'));
      await tester.pumpAndSettle();
      expect(toolbarDirection, EditorToolbarDirection.vertical);
      expect(find.byTooltip('Show editing buttons'), findsOneWidget);

      await tester.tap(find.byTooltip('Show editing buttons'));
      await tester.pump();
      final toolbarScrollView = tester.widget<SingleChildScrollView>(
        find.descendant(
          of: find.byType(BusyMarkWysiwygToolbar),
          matching: find.byType(SingleChildScrollView),
        ),
      );
      expect(toolbarScrollView.scrollDirection, Axis.vertical);
    },
  );

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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: parsed.busyDocument,
              toolbarPlacement: EditorToolbarPlacement.bottomLeft,
              onSourceChanged: (filePath, value) => markdown = value,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final firstFieldRect = tester.getRect(find.byType(TextField).at(0));
    final secondFieldRect = tester.getRect(find.byType(TextField).at(1));
    final gesture = await tester.startGesture(
      firstFieldRect.centerLeft + const Offset(1, 0),
    );
    await gesture.moveTo(secondFieldRect.centerLeft + const Offset(80, 0));
    await gesture.up();
    await tester.pump();

    await tester.tap(find.byIcon(BusyMarkGlyphs.unorderedList));
    await tester.pump();

    expect(markdown, '- First\n\n- Second\n\nThird\n');
  });

  testWidgets('WYSIWYG renders safe HTML blocks and edits raw source', (
    tester,
  ) async {
    final l10n = AppLocalizationsEn();
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: '<p>Hello <strong>HTML</strong></p>\n',
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
              onSourceChanged: (filePath, value) => markdown = value,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.renderedHtml), findsOneWidget);
    expect(find.text('Hello HTML'), findsOneWidget);
    expect(find.textContaining('<p>'), findsNothing);

    await tester.tap(find.byIcon(BusyMarkGlyphs.edit));
    await tester.pumpAndSettle();

    expect(find.text(l10n.editHtml), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('wysiwyg-html-source-field')),
      '<p>Changed</p>',
    );
    await tester.tap(find.text(l10n.apply));
    await tester.pumpAndSettle();

    expect(markdown, '<p>Changed</p>\n');
    expect(find.text('Changed'), findsOneWidget);
  });

  testWidgets('WYSIWYG toolbar inserts an HTML block', (tester) async {
    final l10n = AppLocalizationsDe();
    final parsed = parser.parse(filePath: 'topic.md', source: 'Start\n');
    var markdown = '';

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: parsed.busyDocument,
              toolbarPlacement: EditorToolbarPlacement.bottomLeft,
              onSourceChanged: (filePath, value) => markdown = value,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField).first);
    await tester.pump();
    await tester.tap(
      find.byTooltip(
        '${l10n.htmlBlock} (${BusyMarkEditorShortcutLabels.htmlBlock})',
      ),
    );
    await tester.pumpAndSettle();

    final htmlSourceField = find.byKey(
      const ValueKey('wysiwyg-html-source-field'),
    );
    final htmlSourceInput = find.descendant(
      of: htmlSourceField,
      matching: find.byType(EditableText),
    );
    expect(
      tester.widget<EditableText>(htmlSourceInput).controller.text,
      contains(l10n.htmlContentDefault),
    );
    await tester.enterText(htmlSourceField, '<p>Inserted</p>');
    await tester.tap(find.text(l10n.insert));
    await tester.pumpAndSettle();

    expect(markdown, 'Start\n\n<p>Inserted</p>\n');
    expect(find.text(l10n.renderedHtml), findsOneWidget);
    expect(find.text('Inserted'), findsOneWidget);
  });

  testWidgets(
    'WYSIWYG dialog submission is discarded after the active file changes',
    (tester) async {
      final l10n = AppLocalizationsEn();
      final first = parser.parse(filePath: 'first.md', source: 'First\n');
      final second = parser.parse(filePath: 'second.md', source: 'Second\n');
      expect(first.busyDocument.blocks.single.id, 'b0');
      expect(second.busyDocument.blocks.single.id, 'b0');
      var activeDocument = first.busyDocument;
      final emittedSources = <String>[];
      late StateSetter updateHost;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: StatefulBuilder(
            builder: (context, setState) {
              updateHost = setState;
              return Scaffold(
                body: SizedBox(
                  width: 900,
                  height: 640,
                  child: BusyMarkWysiwygEditor(
                    document: activeDocument,
                    toolbarPlacement: EditorToolbarPlacement.bottomLeft,
                    onSourceChanged: (filePath, source) {
                      emittedSources.add('$filePath\n$source');
                    },
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextField).first);
      await tester.tap(
        find.byTooltip(
          '${l10n.htmlBlock} (${BusyMarkEditorShortcutLabels.htmlBlock})',
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('wysiwyg-html-source-field')),
        findsOneWidget,
      );

      updateHost(() => activeDocument = second.busyDocument);
      await tester.pump();
      if (find
          .byKey(const ValueKey('wysiwyg-html-source-field'))
          .evaluate()
          .isNotEmpty) {
        await tester.enterText(
          find.byKey(const ValueKey('wysiwyg-html-source-field')),
          '<p>Stale insertion</p>',
        );
        await tester.tap(find.text(l10n.insert));
      }
      await tester.pumpAndSettle();

      expect(emittedSources, isEmpty);
      expect(find.text('Second'), findsOneWidget);
      expect(find.text('Stale insertion'), findsNothing);
    },
  );

  testWidgets(
    'WYSIWYG dialog submission is discarded after document generation changes',
    (tester) async {
      final l10n = AppLocalizationsEn();
      final original = parser.parse(filePath: 'topic.md', source: 'Original\n');
      final replacement = parser.parse(
        filePath: 'topic.md',
        source: 'Externally replaced\n',
      );
      expect(original.busyDocument.blocks.single.id, 'b0');
      expect(replacement.busyDocument.blocks.single.id, 'b0');
      var activeDocument = original.busyDocument;
      final emittedSources = <String>[];
      late StateSetter updateHost;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: StatefulBuilder(
            builder: (context, setState) {
              updateHost = setState;
              return Scaffold(
                body: SizedBox(
                  width: 900,
                  height: 640,
                  child: BusyMarkWysiwygEditor(
                    document: activeDocument,
                    toolbarPlacement: EditorToolbarPlacement.bottomLeft,
                    onSourceChanged: (filePath, source) {
                      emittedSources.add('$filePath\n$source');
                    },
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextField).first);
      await tester.tap(
        find.byTooltip(
          '${l10n.htmlBlock} (${BusyMarkEditorShortcutLabels.htmlBlock})',
        ),
      );
      await tester.pumpAndSettle();

      updateHost(() => activeDocument = replacement.busyDocument);
      await tester.pump();
      if (find
          .byKey(const ValueKey('wysiwyg-html-source-field'))
          .evaluate()
          .isNotEmpty) {
        await tester.enterText(
          find.byKey(const ValueKey('wysiwyg-html-source-field')),
          '<p>Stale insertion</p>',
        );
        await tester.tap(find.text(l10n.insert));
      }
      await tester.pumpAndSettle();

      expect(emittedSources, isEmpty);
      expect(find.text('Externally replaced'), findsOneWidget);
      expect(find.text('Stale insertion'), findsNothing);
    },
  );

  testWidgets('WYSIWYG dialogs stop app-level tab navigation shortcuts', (
    tester,
  ) async {
    final l10n = AppLocalizationsEn();
    final parsed = parser.parse(filePath: 'topic.md', source: 'Start\n');
    var tabNavigationCount = 0;

    await tester.pumpWidget(
      Shortcuts(
        shortcuts: <ShortcutActivator, Intent>{
          BusyMarkAppShortcutActivators.nextTab: const _TestTabIntent(),
          BusyMarkAppShortcutActivators.previousTab: const _TestTabIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            _TestTabIntent: CallbackAction<_TestTabIntent>(
              onInvoke: (_) {
                tabNavigationCount += 1;
                return null;
              },
            ),
          },
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SizedBox(
                width: 900,
                height: 640,
                child: BusyMarkWysiwygEditor(
                  document: parsed.busyDocument,
                  toolbarPlacement: EditorToolbarPlacement.bottomLeft,
                  onSourceChanged: (_, _) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField).first);
    await tester.tap(
      find.byTooltip(
        '${l10n.htmlBlock} (${BusyMarkEditorShortcutLabels.htmlBlock})',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(l10n.editHtml), findsOneWidget);

    await _pressControlShortcut(tester, LogicalKeyboardKey.tab);
    await _pressControlShortcut(tester, LogicalKeyboardKey.tab, shift: true);

    expect(tabNavigationCount, 0);
    expect(find.text(l10n.editHtml), findsOneWidget);
  });

  testWidgets('WYSIWYG dialogs activate the native headerbar barrier', (
    tester,
  ) async {
    if (!Platform.isLinux) {
      return;
    }
    const channel = MethodChannel('com.busymark.test/wysiwyg-modal-barrier');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return call.method == 'initialize' ? true : null;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });
    final headerBarService = LinuxHeaderBarService(channel: channel);
    await headerBarService.initialize();
    final l10n = AppLocalizationsEn();
    final parsed = parser.parse(filePath: 'topic.md', source: 'Start\n');

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
              toolbarPlacement: EditorToolbarPlacement.bottomLeft,
              headerBarService: headerBarService,
              onSourceChanged: (_, _) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField).first);
    await tester.tap(
      find.byTooltip(
        '${l10n.htmlBlock} (${BusyMarkEditorShortcutLabels.htmlBlock})',
      ),
    );
    await tester.pumpAndSettle();

    expect(
      calls.where((call) => call.method == 'setModalBarrierVisible').last,
      isA<MethodCall>().having((call) => call.arguments, 'arguments', true),
    );

    await tester.tap(find.text(l10n.cancel));
    await tester.pumpAndSettle();

    expect(
      calls.where((call) => call.method == 'setModalBarrierVisible').last,
      isA<MethodCall>().having((call) => call.arguments, 'arguments', false),
    );
  });

  testWidgets('WYSIWYG typing preserves existing inline formatting', (
    tester,
  ) async {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: 'Hello **bold** world\n',
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
              onSourceChanged: (filePath, value) => markdown = value,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'Hello bold! world');
    await tester.pump();

    expect(markdown, 'Hello **bold!** world\n');
  });

  testWidgets('WYSIWYG Backspace at block start merges with previous block', (
    tester,
  ) async {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: 'First\n\nSecond\n',
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
              onSourceChanged: (filePath, value) => markdown = value,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final secondField = tester.widget<TextField>(find.byType(TextField).at(1));
    secondField.focusNode!.requestFocus();
    secondField.controller!.selection = const TextSelection.collapsed(
      offset: 0,
    );
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();

    expect(markdown, 'FirstSecond\n');
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('WYSIWYG Ctrl+A twice selects all text for deletion', (
    tester,
  ) async {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: 'First\n\nSecond\n\nThird\n',
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
              onSourceChanged: (filePath, value) => markdown = value,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    TextField fieldAt(int index) {
      return tester.widget<TextField>(find.byType(TextField).at(index));
    }

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(fieldAt(0).controller!.selection.start, 0);
    expect(fieldAt(0).controller!.selection.end, 'First'.length);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(
      TextSelectionTheme.of(
        tester.element(find.byType(TextField).at(0)),
      ).selectionColor,
      Colors.transparent,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();

    expect(markdown, isEmpty);
    expect(find.byType(TextField), findsOneWidget);
    expect(fieldAt(0).controller!.text, isEmpty);
  });

  testWidgets(
    'WYSIWYG select-all deletion preserves source-protected definitions',
    (tester) async {
      const protectedSource =
          '> [guide]: docs.md\n'
          '>\n'
          '> Original\n';
      final parsed = parser.parse(
        filePath: 'topic.md',
        source: 'Before\n\n$protectedSource\nAfter\n',
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
                onSourceChanged: (filePath, value) => markdown = value,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(TextField), findsNWidgets(2));
      final firstField = tester.widget<TextField>(find.byType(TextField).first);
      firstField.focusNode!.requestFocus();
      await tester.pump();

      for (var attempt = 0; attempt < 2; attempt++) {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pump();
      }

      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();

      expect(markdown, contains(protectedSource));
      expect(
        RegExp(r'^> \[guide\]:', multiLine: true).allMatches(markdown),
        hasLength(1),
      );
    },
  );

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

  test('WYSIWYG text edits preserve inline ranges where possible', () {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: 'Hello **bold** world\n',
    );
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );
    final blockId = controller.document.blocks.first.id;

    controller.updateBlockText(blockId, 'Hello bold! world');

    expect(controller.markdown, 'Hello **bold!** world\n');
  });

  test(
    'WYSIWYG inline command toggles selected mark without dropping links',
    () {
      final parsed = parser.parse(
        filePath: 'topic.md',
        source: '**Alpha** [Beta](target.md)\n',
      );
      final controller = BusyMarkWysiwygDocumentController(
        document: parsed.busyDocument,
      );
      final blockId = controller.document.blocks.first.id;

      controller.applyInlineCommand(
        blockId,
        BusyWysiwygInlineCommand.italic,
        6,
        10,
      );
      controller.applyInlineCommand(
        blockId,
        BusyWysiwygInlineCommand.bold,
        0,
        5,
      );

      expect(controller.markdown, 'Alpha [*Beta*](target.md)\n');
    },
  );

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

  test('serializer chooses inline code delimiters that preserve backticks', () {
    for (final (payload, expected) in const [
      ('left ` right', '``left ` right``\n'),
      ('`edge`', '`` `edge` ``\n'),
      (' padded ', '`  padded  `\n'),
      ('   ', '`   `\n'),
      ('a `` b', '```a `` b```\n'),
    ]) {
      final document = BusyDocument(
        filePath: 'topic.md',
        mode: MarkdownMode.gfm,
        blocks: [
          BusyBlock(
            id: 'paragraph',
            kind: BusyBlockKind.paragraph,
            inlines: [BusyInline(kind: BusyInlineKind.code, text: payload)],
            dirty: true,
          ),
        ],
      );

      final markdown = const BusyMarkMarkdownSerializer().serialize(document);

      expect(markdown, expected, reason: 'payload: "$payload"');
      final reparsed = parser.parse(filePath: 'topic.md', source: markdown);
      final code = reparsed.busyDocument.blocks.single.inlines.singleWhere(
        (inline) => inline.kind == BusyInlineKind.code,
      );
      expect(code.text, payload);
    }
  });

  test(
    'serializer preserves fenced code delimiters and trailing whitespace',
    () {
      const payload = 'before\n```\nafter  ';
      const document = BusyDocument(
        filePath: 'topic.md',
        mode: MarkdownMode.gfm,
        blocks: [
          BusyBlock(
            id: 'code',
            kind: BusyBlockKind.codeBlock,
            inlines: [BusyInline(kind: BusyInlineKind.text, text: payload)],
            attributes: {'language': 'text'},
            dirty: true,
          ),
        ],
      );

      final markdown = const BusyMarkMarkdownSerializer().serialize(document);

      expect(markdown, '````text\nbefore\n```\nafter  \n````\n');
      final reparsed = parser.parse(filePath: 'topic.md', source: markdown);
      expect(reparsed.busyDocument.blocks, hasLength(1));
      expect(reparsed.busyDocument.blocks.single.kind, BusyBlockKind.codeBlock);
      expect(reparsed.busyDocument.blocks.single.plainText, payload);
      expect(reparsed.codeBlocks, hasLength(1));
      expect(reparsed.codeBlocks.single.language, 'text');
      expect(reparsed.codeBlocks.single.content, '$payload\n');
    },
  );

  test('parser preserves meaningful trailing fenced-code whitespace', () {
    const source = '```\nline  \n\n```\n';
    final parsed = parser.parse(filePath: 'topic.md', source: source);
    final block = parsed.busyDocument.blocks.single;

    expect(block.plainText, 'line  \n');

    final serialized = const BusyMarkMarkdownSerializer().serialize(
      parsed.busyDocument.copyWith(blocks: [block.copyWith(dirty: true)]),
    );
    expect(serialized, source);
    expect(
      parser
          .parse(filePath: 'topic.md', source: serialized)
          .busyDocument
          .blocks
          .single
          .plainText,
      'line  \n',
    );
  });

  test('parser closes dynamic code fences only with a matching delimiter', () {
    const source =
        '````dart\n'
        '~~~\n'
        '```\n'
        '# Hidden\n'
        '%secret%\n'
        '<script>alert(1)</script>\n'
        'after\n'
        '`````\n'
        '# Visible\n';

    final parsed = parser.parse(filePath: 'topic.md', source: source);

    expect(parsed.busyDocument.blocks, hasLength(2));
    expect(parsed.busyDocument.blocks.first.kind, BusyBlockKind.codeBlock);
    expect(
      parsed.busyDocument.blocks.first.plainText,
      '~~~\n```\n# Hidden\n%secret%\n<script>alert(1)</script>\nafter',
    );
    expect(parsed.codeBlocks, hasLength(1));
    expect(parsed.codeBlocks.single.language, 'dart');
    expect(
      parsed.codeBlocks.single.content,
      '~~~\n```\n# Hidden\n%secret%\n<script>alert(1)</script>\nafter\n',
    );
    expect(parsed.headings.map((heading) => heading.text), ['Visible']);
    expect(parsed.variables, isEmpty);
    expect(parsed.xmlBlocks, isEmpty);
    expect(
      parsed.diagnostics.map((diagnostic) => diagnostic.code),
      isNot(contains('markdown.raw-html.unsafe')),
    );
  });

  test('parser does not treat indented code as a fenced block', () {
    const source = '    ```\n# Visible\n    ```\n';

    final parsed = parser.parse(filePath: 'topic.md', source: source);

    expect(parsed.codeBlocks, isEmpty);
    expect(parsed.headings.map((heading) => heading.text), ['Visible']);
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
    var markdown = '';
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 900,
              height: 640,
              child: BusyMarkWysiwygEditor(
                document: document,
                toolbarPlacement: EditorToolbarPlacement.bottomLeft,
                workspaceRoot: topicsDir.path,
                writersideRoot: temp.path,
                imagesDir: 'images',
                onSourceChanged: (filePath, value) => markdown = value,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Image), findsOneWidget);
      expect(find.text('rpi_1.jpg'), findsNothing);
      expect(find.byType(TextField), findsNothing);

      await tester.tap(find.byKey(const ValueKey('wysiwyg-image-block-image')));
      await tester.pumpAndSettle();

      expect(find.text('Image'), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);
      expect(find.byType(BusyMarkDialogShell), findsOneWidget);
      expect(find.byType(BusyMarkFloatingTextEntry), findsNWidgets(2));
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.byType(BusyMarkDialogButton), findsNWidgets(3));
      expect(find.byType(AlertDialog), findsNothing);
      final dialogRect = tester.getRect(find.byType(BusyMarkDialogShell));
      final sourceEntryRect = tester.getRect(
        find.byKey(BusyMarkImageDialogKeys.source),
      );
      final altEntryRect = tester.getRect(
        find.byKey(BusyMarkImageDialogKeys.alt),
      );
      final chooseRect = tester.getRect(
        find.byKey(BusyMarkImageDialogKeys.choose),
      );
      expect(dialogRect.width, lessThanOrEqualTo(BusyMarkSizes.dialogCompact));
      expect(
        sourceEntryRect.left - dialogRect.left,
        closeTo(BusyMarkSpacing.lg, 0.1),
      );
      expect(
        altEntryRect.left - dialogRect.left,
        closeTo(BusyMarkSpacing.lg, 0.1),
      );
      expect(
        dialogRect.right - chooseRect.right,
        closeTo(BusyMarkSpacing.lg, 0.1),
      );
      final sourceField = find.descendant(
        of: find.byKey(BusyMarkImageDialogKeys.source),
        matching: find.byType(EditableText),
      );
      final altField = find.descendant(
        of: find.byKey(BusyMarkImageDialogKeys.alt),
        matching: find.byType(EditableText),
      );
      expect(
        tester.widget<EditableText>(sourceField).controller.text,
        'rpi_1.jpg',
      );
      expect(
        tester.widget<EditableText>(altField).controller.text,
        'Raspberry Pi',
      );

      await tester.enterText(sourceField, 'images/updated.png');
      await tester.enterText(altField, 'Updated alt');
      await tester.tap(find.byKey(BusyMarkImageDialogKeys.submit));
      await tester.pumpAndSettle();

      expect(markdown, '![Updated alt](images/updated.png)\n');
    } finally {
      temp.deleteSync(recursive: true);
    }
  });

  testWidgets('WYSIWYG editor renders absolute local image paths', (
    tester,
  ) async {
    final workspace = Directory.systemTemp.createTempSync(
      'busymark_wysiwyg_image_workspace_',
    );
    final outside = Directory.systemTemp.createTempSync(
      'busymark_wysiwyg_image_outside_',
    );
    try {
      final image = File('${outside.path}/example.jpg')
        ..writeAsBytesSync(
          base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAFgwJ/l8Kz3wAAAABJRU5ErkJggg==',
          ),
        );
      final documentPath = '${workspace.path}/topic.md';
      final parsed = parser.parse(
        filePath: documentPath,
        workspaceRoot: workspace.path,
        source: '![example.jpg](${image.path})\n',
      );

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
                workspaceRoot: workspace.path,
                onSourceChanged: (_, _) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Image), findsOneWidget);
      expect(find.textContaining(image.path), findsNothing);
    } finally {
      workspace.deleteSync(recursive: true);
      outside.deleteSync(recursive: true);
    }
  });

  testWidgets('WYSIWYG editor renders linked remote image blocks', (
    tester,
  ) async {
    const imageUrl = 'https://example.com/remote.png';
    final previousHttpClientProvider = debugNetworkImageHttpClientProvider;
    final parsed = parser.parse(
      filePath: 'README.md',
      source: '[![busymark]($imageUrl)](https://snapcraft.io/busymark)\n',
    );

    try {
      debugNetworkImageHttpClientProvider = () => _FakeImageHttpClient();
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
                allowRemoteImages: true,
                onSourceChanged: (_, _) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final imageView = tester.widget<MarkdownImageView>(
        find.byType(MarkdownImageView),
      );
      expect(imageView.source, imageUrl);
      expect(imageView.alt, 'busymark');
      expect(find.byType(Image), findsOneWidget);
      expect(find.text(imageUrl), findsNothing);
      expect(find.byType(TextField), findsNothing);
    } finally {
      debugNetworkImageHttpClientProvider = previousHttpClientProvider;
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: parsed.busyDocument,
              onSourceChanged: (filePath, value) => markdown = value,
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

  testWidgets('WYSIWYG Enter carries active inline style to next paragraph', (
    tester,
  ) async {
    final parsed = parser.parse(filePath: 'topic.md', source: '**Bold**\n');
    var markdown = parsed.source;

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
              onSourceChanged: (filePath, value) => markdown = value,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final firstField = tester.widget<TextField>(find.byType(TextField).first);
    firstField.focusNode!.requestFocus();
    firstField.controller!.selection = const TextSelection.collapsed(offset: 4);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    await tester.enterText(find.byType(TextField).at(1), 'Next');
    await tester.pump();

    expect(markdown, '**Bold**\n\n**Next**\n');
  });

  testWidgets('WYSIWYG Enter at paragraph end preserves inner bold span', (
    tester,
  ) async {
    const sentence =
        'Users can do the following activities: input - reading, listening; '
        'output - writing, speaking, choosing (e.g. correct word for empty '
        'spot in a sentence). these activities should absolutely be mixed '
        '(interleaved), rather than strictly grouped (blocked).';
    final parsed = parser.parse(filePath: 'topic.md', source: '$sentence\n');
    var markdown = parsed.source;

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
              onSourceChanged: (filePath, value) => markdown = value,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField).first);
    final groupedStart = sentence.indexOf('grouped');
    final groupedEnd = groupedStart + 'grouped'.length;
    field.focusNode!.requestFocus();
    field.controller!.selection = TextSelection(
      baseOffset: groupedStart,
      extentOffset: groupedEnd,
    );

    await tester.tap(find.byIcon(BusyMarkGlyphs.bold));
    await tester.pump();

    field.controller!.selection = TextSelection.collapsed(
      offset: sentence.length,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(markdown, '${sentence.replaceFirst('grouped', '**grouped**')}\n');
    final context = tester.element(find.byType(TextField).first);
    final span = field.controller!.buildTextSpan(
      context: context,
      style: DefaultTextStyle.of(context).style,
      withComposing: false,
    );
    expect(_spanStyleForText(span, 'grouped')?.fontWeight, FontWeight.w700);
  });

  testWidgets('WYSIWYG newline text edit preserves inner bold span', (
    tester,
  ) async {
    const sentence =
        'Users can do the following activities: input - reading, listening; '
        'output - writing, speaking, choosing (e.g. correct word for empty '
        'spot in a sentence). these activities should absolutely be mixed '
        '(interleaved), rather than strictly grouped (blocked).';
    final parsed = parser.parse(filePath: 'topic.md', source: '$sentence\n');
    var markdown = parsed.source;

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
              onSourceChanged: (filePath, value) => markdown = value,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField).first);
    final groupedStart = sentence.indexOf('grouped');
    field.focusNode!.requestFocus();
    field.controller!.selection = TextSelection(
      baseOffset: groupedStart,
      extentOffset: groupedStart + 'grouped'.length,
    );

    await tester.tap(find.byIcon(BusyMarkGlyphs.bold));
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, '$sentence\n');
    await tester.pump();

    expect(markdown, '${sentence.replaceFirst('grouped', '**grouped**')}\n');
    final updatedField = tester.widget<TextField>(find.byType(TextField).first);
    final context = tester.element(find.byType(TextField).first);
    final span = updatedField.controller!.buildTextSpan(
      context: context,
      style: DefaultTextStyle.of(context).style,
      withComposing: false,
    );
    expect(_spanStyleForText(span, 'grouped')?.fontWeight, FontWeight.w700);
  });

  testWidgets('WYSIWYG text input newlines become Markdown paragraphs', (
    tester,
  ) async {
    final parsed = parser.parse(filePath: 'topic.md', source: 'First\n');
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
              onSourceChanged: (filePath, value) => markdown = value,
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 640,
            child: BusyMarkWysiwygEditor(
              document: parsed.busyDocument,
              onSourceChanged: (_, _) {},
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

    controller.applyBlockCommand(blockId, BusyWysiwygBlockCommand.heading6);
    expect(controller.markdown, '###### Title\n');

    controller.applyBlockCommand(blockId, BusyWysiwygBlockCommand.taskList);
    expect(controller.markdown, '- [ ] Title\n');
  });

  test('WYSIWYG extended toolbar commands serialize Markdown', () {
    final parsed = parser.parse(filePath: 'topic.md', source: 'Alpha Beta\n');
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );
    final blockId = parsed.busyDocument.blocks.first.id;

    controller.insertInlineImage(
      blockId,
      selectionStart: 6,
      selectionEnd: 10,
      source: 'images/logo.png',
      alt: 'Logo',
      fallbackAltText: 'Image',
    );
    expect(controller.markdown, 'Alpha ![Logo](images/logo.png)\n');

    final hardBreakParsed = parser.parse(
      filePath: 'topic.md',
      source: 'Alpha Beta\n',
    );
    final hardBreakController = BusyMarkWysiwygDocumentController(
      document: hardBreakParsed.busyDocument,
    );
    final hardBreakBlockId = hardBreakParsed.busyDocument.blocks.first.id;

    hardBreakController.insertHardBreak(hardBreakBlockId, 5);
    expect(hardBreakController.markdown, 'Alpha  \n Beta\n');
  });

  test('WYSIWYG table and code language commands serialize Markdown', () {
    final parsed = parser.parse(filePath: 'topic.md', source: 'Intro\n');
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );
    final blockId = parsed.busyDocument.blocks.first.id;

    controller.insertTableAfter(
      blockId,
      columns: 2,
      rows: 1,
      headerTextForColumn: (column) => 'Header $column',
      cellText: 'Cell',
    );

    expect(
      controller.markdown,
      'Intro\n\n'
      '| Header 1 | Header 2 |\n'
      '| --- | --- |\n'
      '| Cell | Cell |\n',
    );

    final tableId = controller.document.blocks
        .singleWhere((block) => block.kind == BusyBlockKind.table)
        .id;
    final table = controller.document.blocks.singleWhere(
      (block) => block.kind == BusyBlockKind.table,
    );
    controller.updateTableCellText(
      table.id,
      table.children.first.children.first.id,
      'Name',
    );
    expect(
      controller.markdown,
      'Intro\n\n'
      '| Name | Header 2 |\n'
      '| --- | --- |\n'
      '| Cell | Cell |\n',
    );
    controller.replaceTable(
      tableId,
      columns: 3,
      rows: 1,
      headerTextForColumn: (column) => 'Header $column',
      cellText: 'Cell',
    );
    expect(
      controller.markdown,
      'Intro\n\n'
      '| Name | Header 2 | Header 3 |\n'
      '| --- | --- | --- |\n'
      '| Cell | Cell | Cell |\n',
    );

    final parsedTable = parser.parse(
      filePath: 'topic.md',
      source:
          '| Header 1 | Header 2 |\n'
          '| --- | --- |\n'
          '| Cell | Cell |\n',
    );
    final parsedTableController = BusyMarkWysiwygDocumentController(
      document: parsedTable.busyDocument,
    );
    final parsedTableBlock = parsedTableController.document.blocks.singleWhere(
      (block) => block.kind == BusyBlockKind.table,
    );
    final parsedHeaderCellId =
        parsedTableBlock.children.first.children.first.id;
    parsedTableController.updateTableCellText(
      parsedTableBlock.id,
      parsedHeaderCellId,
      'Name',
    );
    expect(parsedTableController.blockText(parsedHeaderCellId), 'Name');
    expect(
      parsedTableController.markdown,
      '| Name | Header 2 |\n'
      '| --- | --- |\n'
      '| Cell | Cell |\n',
    );

    final codeParsed = parser.parse(
      filePath: 'topic.md',
      source: 'print(1);\n',
    );
    final codeController = BusyMarkWysiwygDocumentController(
      document: codeParsed.busyDocument,
    );
    final codeBlockId = codeParsed.busyDocument.blocks.first.id;

    codeController.applyCodeBlockLanguage(codeBlockId, 'dart');
    expect(codeController.markdown, '```dart\nprint(1);\n```\n');
  });

  test('WYSIWYG table cell pipes round-trip without shifting columns', () {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source:
          '| First | Final |\n'
          '| --- | --- |\n'
          '| left | keep |\n',
    );
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );
    final table = controller.document.blocks.single;
    final firstBodyCell = table.children[1].children.first;

    controller.updateTableCellText(table.id, firstBodyCell.id, 'left | right');

    expect(
      controller.markdown,
      '| First | Final |\n'
      '| --- | --- |\n'
      r'| left \| right | keep |'
      '\n',
    );
    final reparsed = parser.parse(
      filePath: 'topic.md',
      source: controller.markdown,
    );
    final reparsedRow = reparsed.busyDocument.blocks.single.children[1];
    expect(reparsedRow.children, hasLength(2));
    expect(reparsedRow.children.map((cell) => cell.plainText), [
      'left | right',
      'keep',
    ]);
  });

  test('table escaping protects pipes inside formatted cell content', () {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source:
          '| First | Final |\n'
          '| --- | --- |\n'
          r'| `a\|b` and **x\|y** | keep |'
          '\n',
    );
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );
    final table = controller.document.blocks.single;

    controller.updateTableCellText(
      table.id,
      table.children.first.children.first.id,
      'Changed',
    );

    final reparsed = parser.parse(
      filePath: 'topic.md',
      source: controller.markdown,
    );
    final cells = reparsed.busyDocument.blocks.single.children[1].children;
    expect(cells, hasLength(2));
    expect(cells.first.plainText, 'a|b and x|y');
    expect(cells.last.plainText, 'keep');
    expect(
      cells.first.inlines.where((inline) => inline.kind == BusyInlineKind.code),
      hasLength(1),
    );
    expect(
      cells.first.inlines.where(
        (inline) => inline.kind == BusyInlineKind.strong,
      ),
      hasLength(1),
    );
  });

  test('table code preserves a backslash immediately before a pipe', () {
    const payload = r'a\|b';
    const document = BusyDocument(
      filePath: 'topic.md',
      mode: MarkdownMode.gfm,
      blocks: [
        BusyBlock(
          id: 'table',
          kind: BusyBlockKind.table,
          dirty: true,
          children: [
            BusyBlock(
              id: 'header',
              kind: BusyBlockKind.table,
              children: [
                BusyBlock(
                  id: 'header-first',
                  kind: BusyBlockKind.paragraph,
                  inlines: [
                    BusyInline(kind: BusyInlineKind.text, text: 'First'),
                  ],
                ),
                BusyBlock(
                  id: 'header-final',
                  kind: BusyBlockKind.paragraph,
                  inlines: [
                    BusyInline(kind: BusyInlineKind.text, text: 'Final'),
                  ],
                ),
              ],
            ),
            BusyBlock(
              id: 'body',
              kind: BusyBlockKind.table,
              children: [
                BusyBlock(
                  id: 'body-first',
                  kind: BusyBlockKind.paragraph,
                  inlines: [
                    BusyInline(kind: BusyInlineKind.code, text: payload),
                  ],
                ),
                BusyBlock(
                  id: 'body-final',
                  kind: BusyBlockKind.paragraph,
                  inlines: [
                    BusyInline(kind: BusyInlineKind.text, text: 'keep'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );

    final markdown = const BusyMarkMarkdownSerializer().serialize(document);
    final rendered = md.markdownToHtml(
      markdown,
      extensionSet: md.ExtensionSet.gitHubWeb,
    );
    final reparsed = parser.parse(filePath: 'topic.md', source: markdown);
    final cells = reparsed.busyDocument.blocks.single.children[1].children;

    expect(markdown, contains('<code>&#97;&#92;&#124;&#98;</code>'));
    expect(markdown, isNot(contains('&amp;#')));
    expect(rendered, contains(r'<code>a\|b</code>'));
    expect(cells, hasLength(2));
    expect(cells.first.inlines.single.kind, BusyInlineKind.code);
    expect(cells.first.inlines.single.text, payload);
    expect(cells.last.plainText, 'keep');
  });

  test('WYSIWYG table row and column commands serialize Markdown', () {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source:
          '| Header 1 | Header 2 |\n'
          '| --- | --- |\n'
          '| Cell | Cell |\n',
    );
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );
    String tableId() => controller.document.blocks
        .singleWhere((block) => block.kind == BusyBlockKind.table)
        .id;

    controller.insertTableRow(tableId(), 1, after: false);
    expect(
      controller.markdown,
      '| Header 1 | Header 2 |\n'
      '| --- | --- |\n'
      '|  |  |\n'
      '| Cell | Cell |\n',
    );

    controller.insertTableColumn(tableId(), 0, after: true);
    expect(
      controller.markdown,
      '| Header 1 |  | Header 2 |\n'
      '| --- | --- | --- |\n'
      '|  |  |  |\n'
      '| Cell |  | Cell |\n',
    );

    controller.deleteTableColumn(tableId(), 1);
    expect(
      controller.markdown,
      '| Header 1 | Header 2 |\n'
      '| --- | --- |\n'
      '|  |  |\n'
      '| Cell | Cell |\n',
    );

    controller.deleteTableRow(tableId(), 1);
    expect(
      controller.markdown,
      '| Header 1 | Header 2 |\n'
      '| --- | --- |\n'
      '| Cell | Cell |\n',
    );

    controller.deleteTableRow(tableId(), 0);
    expect(
      controller.markdown,
      '| Cell | Cell |\n'
      '| --- | --- |\n',
    );

    controller.deleteTable(tableId());
    expect(controller.markdown, '');
  });

  testWidgets('WYSIWYG table cells are formatted and editable', (tester) async {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source:
          'Intro\n\n'
          '| Header 1 | Header 2 |\n'
          '| --- | --- |\n'
          '| Cell | Cell |\n',
    );
    var markdown = '';
    final widgetTable = parsed.busyDocument.blocks.singleWhere(
      (block) => block.kind == BusyBlockKind.table,
    );
    final headerCellId = widgetTable.children.first.children.first.id;
    final bodyCellId = widgetTable.children[1].children.first.id;

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
              onSourceChanged: (filePath, value) => markdown = value,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(Table), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(5));
    expect(find.text('| Header 1 | Header 2 |'), findsNothing);
    expect(find.byTooltip('Delete table'), findsOneWidget);
    expect(find.byTooltip('Column 1'), findsOneWidget);
    expect(find.byTooltip('Column 2'), findsOneWidget);
    expect(find.byTooltip('Row 1'), findsOneWidget);
    expect(find.byTooltip('Row 2'), findsOneWidget);

    final headerField = tester.widget<TextField>(
      find.byKey(ValueKey(headerCellId)),
    );
    final bodyField = tester.widget<TextField>(
      find.byKey(ValueKey(bodyCellId)),
    );
    expect(headerField.onChanged, isNotNull);
    expect(bodyField.onChanged, isNotNull);

    headerField.onChanged!('Name');
    await tester.pump();
    bodyField.onChanged!('Alice');
    await tester.pump();

    expect(
      markdown,
      'Intro\n\n'
      '| Name | Header 2 |\n'
      '| --- | --- |\n'
      '| Alice | Cell |\n',
    );
  });

  test('WYSIWYG list indent outdent and task toggle commands serialize', () {
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: '- Parent\n- Child\n',
    );
    final controller = BusyMarkWysiwygDocumentController(
      document: parsed.busyDocument,
    );
    final childId = parsed.busyDocument.blocks[1].id;

    controller.indentListItems([childId]);
    expect(controller.markdown, '- Parent\n  - Child\n');

    controller.outdentListItems([childId]);
    expect(controller.markdown, '- Parent\n\n- Child\n');

    final taskParsed = parser.parse(
      filePath: 'topic.md',
      source: '- [ ] Todo\n',
    );
    final taskController = BusyMarkWysiwygDocumentController(
      document: taskParsed.busyDocument,
    );
    final taskId = taskParsed.busyDocument.blocks.first.id;

    taskController.toggleTaskChecked([taskId]);
    expect(taskController.markdown, '- [x] Todo\n');
  });
}

TextStyle? _spanStyleForText(InlineSpan span, String text) {
  if (span is TextSpan) {
    if ((span.text ?? '').contains(text)) {
      return span.style;
    }
    final children = span.children;
    if (children != null) {
      for (final child in children) {
        final style = _spanStyleForText(child, text);
        if (style != null) {
          return style;
        }
      }
    }
  }
  return null;
}

RenderEditable? _findRenderEditable(RenderObject root) {
  if (root is RenderEditable) {
    return root;
  }
  RenderEditable? result;
  root.visitChildren((child) {
    result ??= _findRenderEditable(child);
  });
  return result;
}

Future<void> _pressControlShortcut(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  bool shift = false,
}) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  if (shift) {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  }
  await tester.sendKeyDownEvent(key);
  await tester.sendKeyUpEvent(key);
  if (shift) {
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  }
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pump();
}

class _TestTabIntent extends Intent {
  const _TestTabIntent();
}

class _FakeImageHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeImageRequest();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeImageRequest implements HttpClientRequest {
  @override
  HttpHeaders get headers => _FakeImageHeaders();

  @override
  Future<HttpClientResponse> close() async => _FakeImageResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeImageHeaders implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeImageResponse extends Stream<List<int>>
    implements HttpClientResponse {
  static final _bytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAFgwJ/l8Kz3wAAAABJRU5ErkJggg==',
  );

  @override
  int get statusCode => HttpStatus.ok;

  @override
  int get contentLength => _bytes.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_bytes]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
