import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/assets/document_media_context.dart';
import 'package:busymark/src/app/busymark_glyphs.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_commands.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_document_controller.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_inline_controller.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_session_state.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/workspace/document_buffer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/memory_rich_clipboard.dart';

void main() {
  const parser = MarkdownParser();
  _structuralBoundaryRegressions(parser);
  _hardBreakAnchorRegressions(parser);

  test(
    'formatting a URL suffix retains the complete live link and round trips',
    () {
      const url = 'https://example.com/path';
      const prefix = 'https://example.com';
      for (final mode in [
        MarkdownMode.commonMark,
        MarkdownMode.writersideMarkdown,
      ]) {
        final controller = BusyMarkWysiwygDocumentController(
          document: parser
              .parse(filePath: 'topic.md', source: '', mode: mode)
              .busyDocument,
        );
        addTearDown(controller.dispose);
        final id = controller.document.blocks.single.id;
        controller.updateBlockText(id, url);
        controller.applyEnterAt(id, url.length);
        controller.applyInlineCommand(
          id,
          BusyWysiwygInlineCommand.bold,
          prefix.length,
          url.length,
        );
        void check(BusyBlock block) {
          expect(block.plainText, url);
          final ranges = busyInlineStyleRanges(block.inlines);
          final links = ranges
              .where((range) => range.kind == BusyInlineKind.link)
              .toList();
          expect(links, isNotEmpty);
          expect(links.first.start, 0);
          expect(links.last.end, url.length);
          expect(links.every((range) => range.destination == url), isTrue);
          final bold = ranges
              .where((range) => range.kind == BusyInlineKind.strong)
              .single;
          expect((bold.start, bold.end), (prefix.length, url.length));
        }

        check(controller.document.blocks.first);
        expect(
          controller.document.blocks.first.inlines.single.attributes
              .containsKey(busyMarkBareUrlAttribute),
          isFalse,
        );
        expect(
          controller.markdown,
          '[https://example.co&#109;**/path**]($url)\n\n',
        );
        check(
          parser
              .parse(
                filePath: 'topic.md',
                source: controller.markdown,
                mode: mode,
              )
              .busyDocument
              .blocks
              .first,
        );
        final saved = parser
            .parse(
              filePath: 'topic.md',
              source: controller.markdown,
              mode: mode,
            )
            .busyDocument;
        final reopened = BusyMarkWysiwygDocumentController(document: saved);
        addTearDown(reopened.dispose);
        controller.updateBlockText(id, '$url/new');
        reopened.updateBlockText(saved.blocks.single.id, '$url/new');
        expect(controller.markdown.trim(), reopened.markdown.trim());
        for (final edited in [
          controller.document.blocks.first,
          reopened.document.blocks.first,
        ]) {
          expect(edited.plainText, '$url/new');
          expect(edited.inlines.single.destination, url);
        }
      }
    },
  );

  test(
    'Enter URL recognition preserves formatting, literal syntax, anchors, breaks and descendants',
    () {
      const url = 'https://example.com/a_b?q=one&next=two';
      const literal = '*literal* _literal_ `literal` <tag> &copy;';
      const strong = BusyInline(
        kind: BusyInlineKind.strong,
        text: 'bold',
        attributes: {'retained': 'strong'},
        children: [BusyInline(kind: BusyInlineKind.text, text: 'bold')],
      );
      const image = BusyInline(
        kind: BusyInlineKind.image,
        text: '',
        destination: 'image.png',
        attributes: {'retained': 'image'},
      );
      const child = BusyBlock(
        id: 'child',
        kind: BusyBlockKind.paragraph,
        inlines: [BusyInline(kind: BusyInlineKind.text, text: 'Child')],
      );
      const block = BusyBlock(
        id: 'paragraph',
        kind: BusyBlockKind.paragraph,
        attributes: {'retained': 'block'},
        children: [child],
        inlines: [
          strong,
          image,
          BusyInline(
            kind: BusyInlineKind.text,
            text: ' $literal',
            attributes: {'retained': 'text'},
          ),
          BusyInline(
            kind: BusyInlineKind.hardBreak,
            text: '\n',
            attributes: {'retained': 'break'},
          ),
          BusyInline(kind: BusyInlineKind.text, text: url),
        ],
      );
      final controller = BusyMarkWysiwygDocumentController(
        document: const BusyDocument(
          filePath: 'topic.md',
          mode: MarkdownMode.commonMark,
          blocks: [block],
        ),
      );
      addTearDown(controller.dispose);
      controller.applyEnterAt(block.id, block.plainText.length);
      final completed = controller.document.blocks.first;
      expect(completed.plainText, block.plainText);
      expect(completed.children.single, same(child));
      expect(completed.attributes['retained'], 'block');
      expect(completed.inlines.first, same(strong));
      expect(completed.inlines[1], same(image));
      expect(completed.inlines[2].attributes['retained'], 'text');
      expect(completed.inlines[3].kind, BusyInlineKind.hardBreak);
      expect(completed.inlines[3].attributes['retained'], 'break');
      expect(completed.inlines.last.kind, BusyInlineKind.link);
      expect(completed.inlines.last.destination, url);
      final ranges = busyInlineStyleRanges(completed.inlines);
      expect(
        ranges.where((range) => range.kind == BusyInlineKind.link).single.start,
        block.plainText.length - url.length,
      );
      expect(
        ranges.where((range) => range.kind == BusyInlineKind.strong).single.end,
        4,
      );
      final reparsed = parser
          .parse(filePath: 'topic.md', source: controller.markdown)
          .busyDocument;
      expect(reparsed.blocks.first.plainText, block.plainText);
      expect(
        busyInlineStyleRanges(reparsed.blocks.first.inlines)
            .where((range) => range.kind == BusyInlineKind.link)
            .single
            .destination,
        url,
      );
      expect(controller.markdown, contains('![](image.png)'));
      expect(controller.markdown, contains('  \n$url'));
    },
  );

  test(
    'Enter recognition preserves formatting within a URL and does not enter math fields',
    () {
      const url = 'https://example.com/path';
      const formatted = BusyBlock(
        id: 'formatted',
        kind: BusyBlockKind.paragraph,
        inlines: [
          BusyInline(
            kind: BusyInlineKind.strong,
            text: 'prefix $url suffix',
            attributes: {'retained': 'value'},
            children: [
              BusyInline(kind: BusyInlineKind.text, text: 'prefix $url suffix'),
            ],
          ),
        ],
      );
      final controller = BusyMarkWysiwygDocumentController(
        document: const BusyDocument(
          filePath: 'topic.md',
          mode: MarkdownMode.commonMark,
          blocks: [formatted],
        ),
      );
      addTearDown(controller.dispose);
      controller.applyEnterAt(formatted.id, formatted.plainText.length);
      var block = controller.document.blocks.first;
      expect(block.plainText, formatted.plainText);
      final link = block.inlines.single.children.singleWhere(
        (inline) => inline.kind == BusyInlineKind.link,
      );
      expect(link.destination, url);
      expect(block.inlines.single.kind, BusyInlineKind.strong);
      expect(block.inlines.single.attributes['retained'], 'value');
      controller.updateBlockText(block.id, 'prefix $url/new suffix');
      block = controller.document.blocks.first;
      expect(
        busyInlineStyleRanges(block.inlines)
            .where((range) => range.kind == BusyInlineKind.link)
            .single
            .destination,
        '$url/new',
      );
      final reloaded = parser
          .parse(filePath: 'topic.md', source: controller.markdown)
          .busyDocument
          .blocks
          .first;
      expect(reloaded.plainText, block.plainText);
      expect(
        busyInlineStyleRanges(reloaded.inlines)
            .where((range) => range.kind == BusyInlineKind.link)
            .single
            .destination,
        '$url/new',
      );

      const math = BusyBlock(
        id: 'math',
        kind: BusyBlockKind.paragraph,
        inlines: [
          BusyInline(kind: BusyInlineKind.math, text: 'x'),
          BusyInline(kind: BusyInlineKind.text, text: ' $url'),
        ],
      );
      final mathController = BusyMarkWysiwygDocumentController(
        document: const BusyDocument(
          filePath: 'math.md',
          mode: MarkdownMode.commonMark,
          blocks: [math],
        ),
      );
      addTearDown(mathController.dispose);
      mathController.applyEnterAt(math.id, math.plainText.length);
      expect(
        busyInlineStyleRanges(mathController.document.blocks.first.inlines),
        isEmpty,
      );
      expect(
        mathController.document.blocks.first.inlines.first.kind,
        BusyInlineKind.math,
      );
    },
  );

  test('text whitespace preservation metadata follows pasted whitespace', () {
    final document = parser
        .parse(filePath: 'topic.md', source: 'Target\n')
        .busyDocument;
    final blockId = document.blocks.single.id;
    final controller = BusyMarkWysiwygDocumentController(document: document);

    controller.updateBlockText(
      blockId,
      'Target ',
      preserveTextWhitespace: true,
    );
    expect(
      controller
          .blockById(blockId)!
          .attributes[busyMarkPreserveTextWhitespaceAttribute],
      'true',
    );
    expect(controller.markdown, 'Target \n');

    controller.updateBlockText(blockId, 'Changed ');
    expect(
      controller
          .blockById(blockId)!
          .attributes[busyMarkPreserveTextWhitespaceAttribute],
      'true',
    );
    expect(controller.markdown, 'Changed \n');

    controller.updateBlockText(blockId, 'Changed');
    expect(
      controller.blockById(blockId)!.attributes,
      isNot(contains(busyMarkPreserveTextWhitespaceAttribute)),
    );
    expect(controller.markdown, 'Changed\n');

    controller.updateBlockText(blockId, 'Ordinary ');
    expect(
      controller.blockById(blockId)!.attributes,
      isNot(contains(busyMarkPreserveTextWhitespaceAttribute)),
    );

    controller.updateBlockText(
      blockId,
      'Replacement',
      preserveTextWhitespace: true,
    );
    expect(
      controller.blockById(blockId)!.attributes,
      isNot(contains(busyMarkPreserveTextWhitespaceAttribute)),
    );
  });

  test('paste-only whitespace keeps list descendants exactly once', () {
    for (final source in const [
      '- Parent\n  - Child\n    - Grandchild\n',
      '1. Parent\n   1. Child\n      1. Grandchild\n',
      '- [ ] Parent\n  - [x] Child\n    - [ ] Grandchild\n',
    ]) {
      for (final replacement in const ['\n', ' \n ']) {
        final document = parser
            .parse(filePath: 'topic.md', source: source)
            .busyDocument;
        final parent = document.blocks.single;
        final controller = BusyMarkWysiwygDocumentController(
          document: document,
        );
        final result = controller.replaceBlockTextWithParagraphs(
          parent.id,
          replacement,
          replacement.length,
          preserveTextWhitespace: true,
          allowListExit: false,
        );

        expect(result, isNotNull, reason: '$source / $replacement');
        final descendants = _blocksDepthFirst(controller.document.blocks)
            .where(
              (block) =>
                  block.plainText == 'Child' || block.plainText == 'Grandchild',
            )
            .toList();
        expect(descendants.map((block) => block.plainText), [
          'Child',
          'Grandchild',
        ]);
        final reparsed = parser
            .parse(filePath: 'topic.md', source: controller.markdown)
            .busyDocument;
        expect(
          _blocksDepthFirst(reparsed.blocks)
              .where(
                (block) =>
                    block.plainText == 'Child' ||
                    block.plainText == 'Grandchild',
              )
              .map((block) => block.plainText),
          ['Child', 'Grandchild'],
          reason: controller.markdown,
        );
      }
    }
  });

  testWidgets(
    'plain whitespace paste keeps list descendants through Undo and Redo',
    (tester) async {
      var clipboardText = '';
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async =>
            call.method == 'Clipboard.getData' ? {'text': clipboardText} : null,
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

      for (final (caseIndex, source) in const [
        '- Parent\n  - Child\n    - Grandchild\n',
        '1. Parent\n   1. Child\n      1. Grandchild\n',
        '- [ ] Parent\n  - [x] Child\n    - [ ] Grandchild\n',
      ].indexed) {
        for (final (replacementIndex, replacement) in const [
          '\n',
          ' \n ',
        ].indexed) {
          clipboardText = replacement;
          final document = parser
              .parse(filePath: 'topic.md', source: source)
              .busyDocument;
          final parent = document.blocks.single;
          var markdown = source;
          await tester.pumpWidget(
            _app(
              BusyMarkWysiwygEditor(
                key: ValueKey('whitespace-$caseIndex-$replacementIndex'),
                document: document,
                initialSessionState: WysiwygEditorSessionState(
                  activeBlockId: parent.id,
                  anchorBlockId: parent.id,
                  anchorOffset: 0,
                  extentBlockId: parent.id,
                  extentOffset: parent.plainText.length,
                ),
                onSourceChanged: (_, value) => markdown = value,
              ),
            ),
          );
          await tester.pump();
          final field = tester.widget<TextField>(find.byType(TextField).first);
          expect(field.controller?.text, 'Parent');
          field.focusNode!.requestFocus();
          field.controller!.selection = TextSelection(
            baseOffset: 0,
            extentOffset: parent.plainText.length,
          );

          await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
          await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
          await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
          await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
          await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
          await tester.pump();
          await tester.pump();

          final pasted = markdown;
          expect(pasted, isNot(source), reason: '$source / $replacement');
          expect(
            tester
                .widgetList<TextField>(find.byType(TextField))
                .where((field) => field.controller?.text == 'Child'),
            hasLength(1),
          );
          expect(
            tester
                .widgetList<TextField>(find.byType(TextField))
                .where((field) => field.controller?.text == 'Grandchild'),
            hasLength(1),
          );
          final reparsed = parser
              .parse(filePath: 'topic.md', source: pasted)
              .busyDocument;
          expect(
            _blocksDepthFirst(reparsed.blocks)
                .where(
                  (block) =>
                      block.plainText == 'Child' ||
                      block.plainText == 'Grandchild',
                )
                .map((block) => block.plainText),
            ['Child', 'Grandchild'],
          );

          await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
          await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
          await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
          await tester.pump();
          expect(markdown, source);

          await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
          await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
          await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
          await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
          await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
          await tester.pump();
          expect(markdown, pasted);
          expect(RegExp('Child').allMatches(markdown), hasLength(1));
          expect(RegExp('Grandchild').allMatches(markdown), hasLength(1));

          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        }
      }
    },
  );

  test(
    'replacement scope distinguishes a heading field from its document block',
    () {
      BusyWysiwygStyledBlock boldX() => const BusyWysiwygStyledBlock(
        kind: BusyBlockKind.paragraph,
        text: 'X',
        ranges: [
          BusyInlineStyleRange(start: 0, end: 1, kind: BusyInlineKind.strong),
        ],
      );

      final fieldDocument = parser
          .parse(filePath: 'topic.md', source: '## Old\n')
          .busyDocument;
      final field = BusyMarkWysiwygDocumentController(document: fieldDocument);
      final fieldHeading = fieldDocument.blocks.single;
      field.insertStyledBlocksAtSelection(
        blockId: fieldHeading.id,
        selectionStart: 0,
        selectionEnd: fieldHeading.plainText.length,
        blocks: [boldX()],
        replacementScope: BusyWysiwygReplacementScope.fieldContent,
      );
      expect(field.document.blocks.single.kind, BusyBlockKind.heading);
      expect(field.markdown, '## **X**\n');

      final rangeDocument = parser
          .parse(filePath: 'topic.md', source: '## Old\n')
          .busyDocument;
      final range = BusyMarkWysiwygDocumentController(document: rangeDocument);
      final rangeHeading = rangeDocument.blocks.single;
      range.replaceTextSelectionWithStyledBlocks(
        firstBlockId: rangeHeading.id,
        firstStartOffset: 0,
        lastBlockId: rangeHeading.id,
        lastEndOffset: rangeHeading.plainText.length,
        removedBlockIds: [rangeHeading.id],
        blocks: [boldX()],
        replacementScope: BusyWysiwygReplacementScope.documentRange,
      );
      expect(range.document.blocks.single.kind, BusyBlockKind.paragraph);
      expect(range.document.blocks.single.attributes, isNot(contains('level')));
      expect(range.markdown, '**X**\n');
      final reparsed = parser
          .parse(filePath: 'topic.md', source: range.markdown)
          .busyDocument;
      expect(reparsed.blocks.single.kind, BusyBlockKind.paragraph);

      final listDocument = parser
          .parse(
            filePath: 'topic.md',
            source: '- Parent\n  - Child\n    - Grandchild\n',
          )
          .busyDocument;
      final list = BusyMarkWysiwygDocumentController(document: listDocument);
      final parent = listDocument.blocks.single;
      list.replaceTextSelectionWithStyledBlocks(
        firstBlockId: parent.id,
        firstStartOffset: 0,
        lastBlockId: parent.id,
        lastEndOffset: parent.plainText.length,
        removedBlockIds: [parent.id],
        blocks: [boldX()],
        replacementScope: BusyWysiwygReplacementScope.documentRange,
      );
      expect(list.document.blocks.first.kind, BusyBlockKind.paragraph);
      expect(list.document.blocks.first.attributes, isNot(contains('marker')));
      expect(list.document.blocks.last.plainText, 'Child');
      expect(list.document.blocks.last.children.single.plainText, 'Grandchild');
      final listReparsed = parser
          .parse(filePath: 'topic.md', source: list.markdown)
          .busyDocument;
      expect(
        _blocksDepthFirst(listReparsed.blocks).map((block) => block.plainText),
        ['X', 'Child', 'Grandchild'],
      );
    },
  );

  test('complete blocks inserted in list content retain every descendant', () {
    final insertedSources = [
      '## Heading\n',
      '- Inserted\n',
      '```text\ncode\n```\n',
    ];
    for (final insertedSource in insertedSources) {
      final insertedBlock = parser
          .parse(filePath: 'clip.md', source: insertedSource)
          .busyDocument
          .blocks
          .single;
      for (final offset in [0, 3, 6]) {
        final original = parser
            .parse(
              filePath: 'topic.md',
              source: '- Parent\n  - Child\n    - Grandchild\n',
            )
            .busyDocument;
        final root = original.blocks.single;
        final childId = root.children.single.id;
        final controller = BusyMarkWysiwygDocumentController(
          document: original,
        );
        final result = controller.insertStyledBlocksAtSelection(
          blockId: root.id,
          selectionStart: offset,
          selectionEnd: offset,
          blocks: [
            BusyWysiwygStyledBlock(
              kind: insertedBlock.kind,
              text: insertedBlock.plainText,
              ranges: const [],
              attributes: insertedBlock.attributes,
              completeBlock: busyMarkWysiwygImmutableBlockSnapshot(
                insertedBlock,
              ),
            ),
          ],
        );

        expect(result, isNotNull);
        final updated = controller.document.blocks.single;
        expect(updated.id, root.id);
        expect(
          updated.children.where((block) => block.id == childId),
          hasLength(1),
        );
        expect(updated.children.last.id, childId);
        expect(updated.children.last.children.single.plainText, 'Grandchild');
        expect(
          updated.children.where(
            (block) =>
                block.kind == insertedBlock.kind &&
                block.plainText == insertedBlock.plainText,
          ),
          hasLength(1),
        );
      }
    }
  });

  test(
    'generic block commands cannot convert tables or preserved raw blocks',
    () {
      final parsed = parser.parse(
        filePath: 'topic.md',
        source:
            '| A | B |\n| --- | --- |\n| one | two |\n\n<script>x</script>\n',
      );
      final table = parsed.busyDocument.blocks.firstWhere(
        (block) => block.kind == BusyBlockKind.table,
      );
      final raw = parsed.busyDocument.blocks.firstWhere(
        (block) => block.preserveRaw,
      );
      final controller = BusyMarkWysiwygDocumentController(
        document: parsed.busyDocument,
      );
      final original = controller.markdown;

      for (final command in BusyWysiwygBlockCommand.values) {
        expect(busyMarkWysiwygCanApplyBlockCommand(table, command), isFalse);
        expect(busyMarkWysiwygCanApplyBlockCommand(raw, command), isFalse);
        controller.applyBlockCommand(table.id, command);
        controller.applyBlockCommand(raw.id, command);
        expect(controller.markdown, original, reason: command.name);
      }
      controller.applyAdmonitionStyle(table.id, BusyAdmonitionStyle.warning);
      controller.applyAdmonitionStyle(raw.id, BusyAdmonitionStyle.warning);
      expect(controller.markdown, original);
    },
  );

  test('nested list-to-blockquote conversion preserves parent text', () {
    final document = parser
        .parse(filePath: 'topic.md', source: '- parent\n  - child\n')
        .busyDocument;
    final parent = document.blocks.single;
    expect(parent.children, isNotEmpty);
    final controller = BusyMarkWysiwygDocumentController(document: document);

    expect(
      busyMarkWysiwygCanApplyBlockCommand(
        parent,
        BusyWysiwygBlockCommand.heading1,
      ),
      isFalse,
    );
    expect(
      busyMarkWysiwygCanApplyBlockCommand(
        parent,
        BusyWysiwygBlockCommand.orderedList,
      ),
      isTrue,
    );
    controller.applyBlockCommand(parent.id, BusyWysiwygBlockCommand.blockquote);

    final quote = controller.blockById(parent.id)!;
    expect(quote.kind, BusyBlockKind.blockquote);
    expect(quote.inlines, isEmpty);
    expect(quote.children.first.kind, BusyBlockKind.paragraph);
    expect(quote.children.first.plainText, 'parent');
    expect(quote.children.last.plainText, 'child');
    expect(controller.markdown, '> parent\n>\n> - child\n');

    controller.applyBlockCommand(
      parent.id,
      BusyWysiwygBlockCommand.unorderedList,
    );
    final restoredList = controller.blockById(parent.id)!;
    expect(restoredList.plainText, 'parent');
    expect(restoredList.children.single.plainText, 'child');
    expect(controller.markdown, '- parent\n  - child\n');
  });

  test('every admonition style preserves nested list parent text', () {
    for (final style in BusyAdmonitionStyle.values) {
      final document = parser
          .parse(filePath: 'topic.md', source: '- parent\n  - child\n')
          .busyDocument;
      final parent = document.blocks.single;
      final controller = BusyMarkWysiwygDocumentController(document: document);

      controller.applyAdmonitionStyle(parent.id, style);

      final admonition = controller.blockById(parent.id)!;
      expect(admonition.kind, BusyBlockKind.blockquote, reason: style.name);
      expect(admonition.attributes['style'], style.name, reason: style.name);
      expect(admonition.children.first.plainText, 'parent', reason: style.name);
      expect(admonition.children.last.plainText, 'child', reason: style.name);
      expect(controller.markdown, contains('> parent'), reason: style.name);
      expect(controller.markdown, contains('child'), reason: style.name);
    }
  });

  test('Backspace merge preserves the current list item descendants', () {
    final document = parser
        .parse(filePath: 'topic.md', source: '- first\n- second\n  - child\n')
        .busyDocument;
    final first = document.blocks.first;
    final second = document.blocks.last;
    expect(second.children.single.plainText, 'child');
    final controller = BusyMarkWysiwygDocumentController(document: document);

    final result = controller.applyBackspaceAtStart(second.id);

    expect(result?.blockId, first.id);
    expect(result?.offset, 'first'.length);
    final merged = controller.document.blocks.single;
    expect(merged.plainText, 'firstsecond');
    expect(merged.children.single.plainText, 'child');
    expect(controller.markdown, '- firstsecond\n  - child\n');
  });

  test('Backspace merge preserves descendants of an empty list item', () {
    final document = parser
        .parse(filePath: 'topic.md', source: '- first\n-\n  - child\n')
        .busyDocument;
    final first = document.blocks.first;
    final emptyParent = document.blocks.last;
    expect(emptyParent.plainText, isEmpty);
    expect(emptyParent.children.single.plainText, 'child');
    final controller = BusyMarkWysiwygDocumentController(document: document);

    final result = controller.applyBackspaceAtStart(emptyParent.id);

    expect(result?.blockId, first.id);
    expect(result?.offset, 'first'.length);
    final merged = controller.document.blocks.single;
    expect(merged.plainText, 'first');
    expect(merged.children.single.plainText, 'child');
    expect(controller.markdown, '- first\n  - child\n');
  });

  test('Backspace rejects a merge that cannot represent descendants', () {
    final document = parser
        .parse(filePath: 'topic.md', source: 'intro\n\n- second\n  - child\n')
        .busyDocument;
    final nestedItem = document.blocks.last;
    final controller = BusyMarkWysiwygDocumentController(document: document);
    final originalMarkdown = controller.markdown;

    final result = controller.applyBackspaceAtStart(nestedItem.id);

    expect(result, isNull);
    expect(controller.markdown, originalMarkdown);
    expect(
      controller.blockById(nestedItem.id)?.children.single.plainText,
      'child',
    );
  });

  test('complete clipboard snapshots reconstruct a table transactionally', () {
    final tableDocument = parser
        .parse(
          filePath: 'table.md',
          source: '| A | B |\n| --- | --- |\n| one | **two** |\n',
        )
        .busyDocument;
    final table = tableDocument.blocks.single;
    final targetDocument = parser
        .parse(filePath: 'target.md', source: 'Target\n')
        .busyDocument;
    final controller = BusyMarkWysiwygDocumentController(
      document: targetDocument,
    );
    final target = controller.document.blocks.single;
    final snapshot = busyMarkWysiwygImmutableBlockSnapshot(table);
    final result = controller.insertStyledBlocksAtSelection(
      blockId: target.id,
      selectionStart: 0,
      selectionEnd: target.plainText.length,
      blocks: [
        BusyWysiwygStyledBlock(
          kind: table.kind,
          text: table.plainText,
          ranges: const [],
          attributes: table.attributes,
          completeBlock: snapshot,
        ),
      ],
    );

    expect(result, isNotNull);
    final pasted = controller.document.blocks.first;
    expect(pasted.kind, BusyBlockKind.table);
    expect(pasted.children, hasLength(2));
    expect(pasted.children.last.children.last.plainText, 'two');
    expect(controller.markdown, contains('| one | **two** |'));
    expect(() => snapshot.children.add(table), throwsUnsupportedError);
    expect(() => snapshot.attributes['bad'] = 'value', throwsUnsupportedError);
  });

  testWidgets('same-editor cut and paste preserves complete tables', (
    tester,
  ) async {
    const source =
        'Before\n\n| A | B |\n| --- | --- |\n| one | **two** |\n\nAfter\n';
    final document = parser
        .parse(filePath: 'topic.md', source: source)
        .busyDocument;
    var markdown = source;
    String? clipboardText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboardText =
              (call.arguments as Map<Object?, Object?>)['text'] as String?;
        } else if (call.method == 'Clipboard.getData') {
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
      _app(
        BusyMarkWysiwygEditor(
          clipboardService: MemoryRichClipboard(),
          document: document,
          onSourceChanged: (_, value) => markdown = value,
        ),
      ),
    );
    await tester.pump();
    final first = tester.widget<TextField>(find.byType(TextField).first);
    first.focusNode!.requestFocus();
    await tester.pump();

    Future<void> shortcut(LogicalKeyboardKey key) async {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(key);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
    }

    await shortcut(LogicalKeyboardKey.keyA);
    await shortcut(LogicalKeyboardKey.keyA);
    await shortcut(LogicalKeyboardKey.keyX);
    expect(markdown, isNot(contains('| one |')));
    await shortcut(LogicalKeyboardKey.keyV);
    await tester.pump();

    expect(markdown, contains('| A | B |'));
    expect(markdown, contains('| one | **two** |'));
    expect(markdown, contains('Before'));
    expect(markdown, contains('After'));
  });

  test('table cell edits normalize every newline form before updating', () {
    final document = parser
        .parse(filePath: 'topic.md', source: '| A |\n| --- |\n| value |\n')
        .busyDocument;
    final controller = BusyMarkWysiwygDocumentController(document: document);
    final table = document.blocks.single;
    final cell = table.children.last.children.single;

    controller.updateTableCellText(table.id, cell.id, 'A\n\nB\r\nC\rD');

    expect(controller.blockById(cell.id)?.plainText, 'A  B C D');
    expect(controller.markdown, contains('| A  B C D |'));
  });

  test('table cell edits preserve block-marker prefixes as literal text', () {
    for (final value in const ['# title', '- item', '1. item', '> quote']) {
      final document = parser
          .parse(filePath: 'topic.md', source: '| A |\n| --- |\n| value |\n')
          .busyDocument;
      final controller = BusyMarkWysiwygDocumentController(document: document);
      final table = document.blocks.single;
      final cell = table.children.last.children.single;

      controller.updateTableCellText(table.id, cell.id, value);

      expect(controller.blockById(cell.id)?.plainText, value, reason: value);
      expect(controller.markdown, contains('| $value |'), reason: value);
    }
  });

  test('ordinary table cell edits preserve formatting and links', () {
    final document = parser
        .parse(
          filePath: 'topic.md',
          source:
              '| Value |\n'
              '| --- |\n'
              '| **bold** and [link](https://example.com) tail |\n',
        )
        .busyDocument;
    final controller = BusyMarkWysiwygDocumentController(document: document);
    final table = document.blocks.single;
    final cell = table.children.last.children.single;

    controller.updateTableCellText(table.id, cell.id, '${cell.plainText}!');

    final edited = controller.blockById(cell.id)!;
    expect(
      edited.inlines.where((inline) => inline.kind == BusyInlineKind.strong),
      hasLength(1),
    );
    final link = edited.inlines.singleWhere(
      (inline) => inline.kind == BusyInlineKind.link,
    );
    expect(link.destination, 'https://example.com');
    expect(
      controller.markdown,
      '| Value |\n'
      '| --- |\n'
      '| **bold** and [link](https://example.com) tail! |\n',
    );
  });

  test('ordinary cell edits retain toolbar-applied formatting', () {
    final document = parser
        .parse(filePath: 'topic.md', source: '| Value |\n| --- |\n| cell |\n')
        .busyDocument;
    final controller = BusyMarkWysiwygDocumentController(document: document);
    final table = document.blocks.single;
    final cell = table.children.last.children.single;
    controller.applyInlineCommand(
      cell.id,
      BusyWysiwygInlineCommand.bold,
      0,
      cell.plainText.length,
    );

    controller.updateTableCellText(table.id, cell.id, 'cell!');

    expect(controller.markdown, '| Value |\n| --- |\n| **cell!** |\n');
  });

  test('structural edits preserve empty-alt inline images', () {
    BusyMarkWysiwygDocumentController open(String source) {
      return BusyMarkWysiwygDocumentController(
        document: parser
            .parse(filePath: 'topic.md', source: source)
            .busyDocument,
      );
    }

    final split = open('Before ![](image.png) after.\n');
    final splitBlock = split.document.blocks.single;
    split.applyEnterAt(splitBlock.id, splitBlock.plainText.length);
    expect(split.markdown, 'Before ![](image.png) after.\n\n');
    expect(
      split.document.blocks.first.inlines.where(
        (inline) => inline.kind == BusyInlineKind.image,
      ),
      hasLength(1),
    );

    final formatted = open('Before ![](image.png) after.\n');
    final formattedBlock = formatted.document.blocks.single;
    formatted.applyInlineCommand(
      formattedBlock.id,
      BusyWysiwygInlineCommand.bold,
      0,
      'Before'.length,
    );
    expect(formatted.markdown, '**Before** ![](image.png) after.\n');

    final merged = open('Lead\n\nBefore ![](image.png) after.\n');
    final current = merged.document.blocks.last;
    merged.applyBackspaceAtStart(current.id);
    expect(merged.markdown, 'LeadBefore ![](image.png) after.\n');
  });

  test('structural edits preserve existing hard line breaks', () {
    BusyMarkWysiwygDocumentController open(String source) {
      return BusyMarkWysiwygDocumentController(
        document: parser
            .parse(filePath: 'topic.md', source: source)
            .busyDocument,
      );
    }

    final split = open('Alpha  \nBeta\n');
    final splitBlock = split.document.blocks.single;
    split.applyEnterAt(splitBlock.id, splitBlock.plainText.length);
    expect(split.markdown, 'Alpha  \nBeta\n\n');

    final formatted = open('Alpha  \nBeta\n');
    final formattedBlock = formatted.document.blocks.single;
    formatted.applyInlineCommand(
      formattedBlock.id,
      BusyWysiwygInlineCommand.bold,
      0,
      'Alpha'.length,
    );
    expect(formatted.markdown, '**Alpha**  \nBeta\n');

    final merged = open('Lead\n\nAlpha  \nBeta\n');
    merged.applyBackspaceAtStart(merged.document.blocks.last.id);
    expect(merged.markdown, 'LeadAlpha  \nBeta\n');
  });

  test('editing preserves a literal bang before an inline link', () {
    final document = parser
        .parse(
          filePath: 'topic.md',
          source:
              r'\![guide](guide.md) tail'
              '\n',
        )
        .busyDocument;
    final controller = BusyMarkWysiwygDocumentController(document: document);
    final block = document.blocks.single;

    controller.updateBlockText(block.id, '${block.plainText} extended');

    expect(
      controller.markdown,
      r'\![guide](guide.md) tail extended'
      '\n',
    );
    final reparsed = parser.parse(
      filePath: 'topic.md',
      source: controller.markdown,
    );
    expect(reparsed.images, isEmpty);
    expect(reparsed.links, hasLength(1));
  });

  test('editing escapes block syntax at the start of a list item', () {
    final document = parser
        .parse(filePath: 'topic.md', source: '- \\# label\n')
        .busyDocument;
    final controller = BusyMarkWysiwygDocumentController(document: document);
    final item = document.blocks.single;

    controller.updateBlockText(item.id, '# label edited');

    expect(controller.markdown, '- \\# label edited\n');
    final reparsed = parser.parse(
      filePath: 'topic.md',
      source: controller.markdown,
    );
    expect(reparsed.busyDocument.blocks.single.plainText, '# label edited');
    expect(reparsed.busyDocument.blocks.single.children, isEmpty);
  });

  testWidgets('table field edits preserve rendered formatting and links', (
    tester,
  ) async {
    final document = parser
        .parse(
          filePath: 'topic.md',
          source:
              '| Value |\n'
              '| --- |\n'
              '| **bold** and [link](https://example.com) tail |\n',
        )
        .busyDocument;
    final cell = document.blocks.single.children.last.children.single;
    var markdown = '';
    await tester.pumpWidget(
      _app(
        BusyMarkWysiwygEditor(
          document: document,
          onSourceChanged: (_, value) => markdown = value,
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byKey(ValueKey(cell.id)), '${cell.plainText}!');
    await tester.pump();

    expect(markdown, contains('**bold**'));
    expect(markdown, contains('[link](https://example.com)'));
  });

  testWidgets('table fields reject multiline input and reconcile the model', (
    tester,
  ) async {
    final document = parser
        .parse(filePath: 'topic.md', source: '| A |\n| --- |\n| value |\n')
        .busyDocument;
    final table = document.blocks.single;
    final cell = table.children.last.children.single;
    var markdown = '';
    await tester.pumpWidget(
      _app(
        BusyMarkWysiwygEditor(
          document: document,
          onSourceChanged: (_, value) => markdown = value,
        ),
      ),
    );
    await tester.pump();

    final finder = find.byKey(ValueKey(cell.id));
    await tester.enterText(finder, 'A\n\nB');
    await tester.pump();
    final field = tester.widget<TextField>(finder);

    expect(field.maxLines, 1);
    expect(field.controller?.text, 'AB');
    expect(markdown, contains('| AB |'));
  });

  testWidgets('table fields preserve block-marker-prefixed cell values', (
    tester,
  ) async {
    final document = parser
        .parse(filePath: 'topic.md', source: '| A |\n| --- |\n| value |\n')
        .busyDocument;
    final table = document.blocks.single;
    final cell = table.children.last.children.single;
    var markdown = '';
    await tester.pumpWidget(
      _app(
        BusyMarkWysiwygEditor(
          document: document,
          onSourceChanged: (_, value) => markdown = value,
        ),
      ),
    );
    await tester.pump();

    final finder = find.byKey(ValueKey(cell.id));
    for (final value in const ['# title', '- item', '1. item', '> quote']) {
      await tester.enterText(finder, value);
      await tester.pump();

      expect(
        tester.widget<TextField>(finder).controller?.text,
        value,
        reason: value,
      );
      expect(markdown, contains('| $value |'), reason: value);
    }
  });

  testWidgets('exact source ranges select repeated text and table cells', (
    tester,
  ) async {
    const source =
        'same same Case case cat scatter cat a1 a222\n\n'
        '| A | B |\n| --- | --- |\n| first | needle |\n';
    final document = parser
        .parse(filePath: 'topic.md', source: source)
        .busyDocument;
    final table = document.blocks.last;
    final needleCell = table.children.last.children.last;
    var request = 1;

    Widget editor(BusyMarkWysiwygSourceRange range) => _app(
      BusyMarkWysiwygEditor(
        document: document,
        scrollRequest: request,
        scrollToSourceRange: range,
        onSourceChanged: (_, _) {},
      ),
    );

    Future<void> expectParagraphRange(int start, int end) async {
      await tester.pumpWidget(
        editor(BusyMarkWysiwygSourceRange(startOffset: start, endOffset: end)),
      );
      await tester.pump();
      await tester.pump();
      final paragraph = tester.widget<TextField>(find.byType(TextField).first);
      expect(
        paragraph.controller?.selection,
        TextSelection(baseOffset: start, extentOffset: end),
      );
      request++;
    }

    // Repeated literal: navigate to the second occurrence.
    await expectParagraphRange(5, 9);
    // Case-sensitive result: preserve the exact uppercase occurrence.
    final uppercaseStart = source.indexOf('Case');
    await expectParagraphRange(uppercaseStart, uppercaseStart + 4);
    // Whole-word result: skip "cat" inside "scatter".
    final wholeWordStart = source.lastIndexOf('cat', source.indexOf(' a1'));
    await expectParagraphRange(wholeWordStart, wholeWordStart + 3);
    // Regex result: use the actual match length, not the pattern length.
    final regexStart = source.indexOf('a222');
    await expectParagraphRange(regexStart, regexStart + 4);

    final needleStart = source.indexOf('needle');
    await tester.pumpWidget(
      editor(
        BusyMarkWysiwygSourceRange(
          startOffset: needleStart,
          endOffset: needleStart + 'needle'.length,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    final cellField = tester.widget<TextField>(
      find.byKey(ValueKey(needleCell.id)),
    );
    expect(
      cellField.controller?.selection,
      const TextSelection(baseOffset: 0, extentOffset: 6),
    );
  });

  testWidgets('exact source navigation rebases spans after earlier edits', (
    tester,
  ) async {
    const source = 'alpha\n\nneedle\n';
    final document = parser
        .parse(filePath: 'topic.md', source: source)
        .busyDocument;
    late StateSetter rebuild;
    var markdown = source;
    var request = 0;
    BusyMarkWysiwygSourceRange? range;

    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return BusyMarkWysiwygEditor(
              document: document,
              scrollRequest: request,
              scrollToSourceRange: range,
              onSourceChanged: (_, value) => markdown = value,
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'alpha expanded');
    await tester.pump();

    final needleStart = markdown.indexOf('needle');
    rebuild(() {
      request++;
      range = BusyMarkWysiwygSourceRange(
        startOffset: needleStart,
        endOffset: needleStart + 6,
      );
    });
    await tester.pump();
    await tester.pump();

    final needle = tester.widget<TextField>(find.byType(TextField).at(1));
    expect(
      needle.controller?.selection,
      const TextSelection(baseOffset: 0, extentOffset: 6),
    );
  });

  testWidgets('source navigation expands collapsed Writerside ancestors', (
    tester,
  ) async {
    const source = '''## Details {collapsible="true"}

Hidden needle.
''';
    final document = parser
        .parse(
          filePath: 'topic.md',
          source: source,
          mode: MarkdownMode.writersideMarkdown,
          validateLocalReferences: false,
        )
        .busyDocument;
    final start = source.indexOf('needle');

    await tester.pumpWidget(
      _app(
        BusyMarkWysiwygEditor(
          document: document,
          scrollRequest: 1,
          scrollToSourceRange: BusyMarkWysiwygSourceRange(
            startOffset: start,
            endOffset: start + 6,
          ),
          onSourceChanged: (_, _) {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('Hidden needle.'), findsOneWidget);
    final hiddenField = tester.widget<TextField>(
      find.widgetWithText(TextField, 'Hidden needle.'),
    );
    expect(
      hiddenField.controller?.selection,
      const TextSelection(baseOffset: 7, extentOffset: 13),
    );
  });

  testWidgets('outline navigation expands a collapsed heading ancestor', (
    tester,
  ) async {
    const source = '''## Details {collapsible="true"}

### Hidden heading

Body.
''';
    final document = parser
        .parse(
          filePath: 'topic.md',
          source: source,
          mode: MarkdownMode.writersideMarkdown,
          validateLocalReferences: false,
        )
        .busyDocument;
    final hiddenHeading = document.blocks.firstWhere(
      (block) => block.plainText == 'Hidden heading',
    );

    await tester.pumpWidget(
      _app(
        BusyMarkWysiwygEditor(
          document: document,
          scrollRequest: 1,
          scrollToBlockId: hiddenHeading.id,
          onSourceChanged: (_, _) {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('Hidden heading'), findsOneWidget);
  });

  testWidgets('table cells own shortcuts, formatting, and restored selection', (
    tester,
  ) async {
    final document = parser
        .parse(filePath: 'topic.md', source: '| A |\n| --- |\n| cell |\n')
        .busyDocument;
    final table = document.blocks.single;
    final cell = table.children.last.children.single;
    var markdown = '';
    WysiwygEditorSessionState? session;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async =>
          call.method == 'Clipboard.getData' ? {'text': 'new\nline'} : null,
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    await tester.pumpWidget(
      _app(
        BusyMarkWysiwygEditor(
          document: document,
          initialSessionState: WysiwygEditorSessionState(
            activeBlockId: table.id,
            activeCellId: cell.id,
            anchorBlockId: cell.id,
            anchorOffset: 0,
            extentBlockId: cell.id,
            extentOffset: 4,
          ),
          onSessionChanged: (_, value) => session = value,
          onSourceChanged: (_, value) => markdown = value,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final finder = find.byKey(ValueKey(cell.id));
    var field = tester.widget<TextField>(finder);
    expect(
      field.controller?.selection,
      const TextSelection(baseOffset: 0, extentOffset: 4),
    );
    final blockquoteButton = tester
        .widgetList<BusyMarkHeaderIconButton>(
          find.byType(BusyMarkHeaderIconButton),
        )
        .firstWhere((button) => button.icon == BusyMarkGlyphs.blockquote);
    expect(blockquoteButton.onPressed, isNull);
    await tester.tap(find.byIcon(BusyMarkGlyphs.bold));
    await tester.pump();
    expect(markdown, contains('**cell**'));

    field = tester.widget<TextField>(finder);
    field.focusNode!.requestFocus();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(
      field.controller?.selection,
      const TextSelection(baseOffset: 0, extentOffset: 4),
    );
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    await tester.pump();
    expect(markdown, contains('| **new line** |'));
    expect(session?.activeBlockId, table.id);
    expect(session?.activeCellId, cell.id);
    expect(session?.anchorBlockId, cell.id);
    expect(session?.extentBlockId, cell.id);
  });

  test('external undo groups continuous typing but not transactions', () {
    final initial = DocumentBuffer.untitled(id: 'one', name: 'one.md');
    final first = initial.edited('a', undoGroup: 'typing-1');
    final second = first.edited('ab', undoGroup: 'typing-1');
    final transaction = second.edited('ab\n', undoGroup: null);

    expect(first.editorState.undoState.undo.map((state) => state.text), ['']);
    expect(second.editorState.undoState.undo.map((state) => state.text), ['']);
    expect(transaction.editorState.undoState.undo.map((state) => state.text), [
      '',
      'ab',
    ]);
  });

  testWidgets('external history coalesces editor typing without local copies', (
    tester,
  ) async {
    final document = parser
        .parse(filePath: 'topic.md', source: 'a\n')
        .busyDocument;
    final key = GlobalKey();
    var buffer = DocumentBuffer.untitled(
      id: 'one',
      name: 'one.md',
      text: 'a\n',
    );
    final groups = <String?>[];

    await tester.pumpWidget(
      _app(
        BusyMarkWysiwygEditor(
          key: key,
          document: document,
          useExternalUndoHistory: true,
          onSourceChanged: (_, _) {},
          onTransactionalSourceChanged: (_, value, group) {
            groups.add(group);
            buffer = buffer.edited(value, undoGroup: group);
          },
        ),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'ab');
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'abc');
    await tester.pump();

    expect(groups, hasLength(2));
    expect(groups.first, isNotNull);
    expect(groups.last, groups.first);
    expect(buffer.editorState.undoState.undo.map((state) => state.text), [
      'a\n',
    ]);
    final dynamic state = tester.state(find.byType(BusyMarkWysiwygEditor));
    expect(state.debugUndoSnapshotCount, 0);
  });

  testWidgets('undo controllers are disposed when blocks disappear', (
    tester,
  ) async {
    final key = GlobalKey();
    final first = parser
        .parse(filePath: 'topic.md', source: 'One\n\nTwo\n')
        .busyDocument;
    final second = parser
        .parse(filePath: 'topic.md', source: 'One\n')
        .busyDocument;

    Widget editor(BusyDocument document) => _app(
      BusyMarkWysiwygEditor(
        key: key,
        document: document,
        onSourceChanged: (_, _) {},
      ),
    );

    await tester.pumpWidget(editor(first));
    await tester.pump();
    final dynamic state = tester.state(find.byType(BusyMarkWysiwygEditor));
    expect(state.debugUndoControllerCount, 2);

    await tester.pumpWidget(editor(second));
    await tester.pump();
    expect(state.debugUndoControllerCount, 1);
  });
}

void _hardBreakAnchorRegressions(MarkdownParser parser) {
  group('explicit line-break anchors', () {
    const fixtures = [
      (
        name: 'existing hard break',
        source: 'a  \n![](first.png)b\n',
        text: 'a\nb',
        objects: 1,
      ),
      (
        name: 'consecutive hard breaks',
        source: 'a\n<br>\n<br>\n![](first.png)b\n',
        text: 'a\n\nb',
        objects: 1,
      ),
      (
        name: 'objects before at and after the caret',
        source:
            '![](first.png)a![](second.png)  \n![](third.png)![](fourth.png)b![](last.png)\n',
        text: 'a\nb',
        objects: 5,
      ),
      (
        name: 'formatted objects after existing break',
        source: '**a  \n![](first.png)![](second.png)b**![](third.png)c\n',
        text: 'a\nbc',
        objects: 3,
      ),
      (
        name: 'formatted objects at shared offsets on either side',
        source:
            '**a![](first.png)![](second.png)**  \n*![](third.png)![](fourth.png)b*\n',
        text: 'a\nb',
        objects: 4,
      ),
    ];
    for (final mode in [
      MarkdownMode.commonMark,
      MarkdownMode.gfm,
      MarkdownMode.writersideMarkdown,
    ]) {
      for (final fixture in fixtures) {
        for (final count in [1, 2]) {
          for (var offset = 1; offset < fixture.text.length; offset++) {
            test(
              '${mode.name} ${fixture.name} count=$count offset=$offset',
              () {
                final document = parser
                    .parse(
                      filePath: 'breaks.md',
                      source: fixture.source,
                      mode: mode,
                    )
                    .busyDocument;
                final block = document.blocks.single;
                expect(block.plainText, fixture.text);
                final anchors = _individualImageAnchors(block);
                expect(anchors, hasLength(fixture.objects));
                final safeOffset = offset.clamp(0, fixture.text.length);
                final expected = [
                  for (final anchor in anchors)
                    [
                      anchor.offset <= safeOffset
                          ? anchor.offset
                          : anchor.offset + count,
                      _inlineSignatures([anchor.inline]),
                    ],
                ];
                final controller = BusyMarkWysiwygDocumentController(
                  document: document,
                );
                addTearDown(controller.dispose);
                if (count == 1) {
                  controller.insertHardBreak(block.id, offset);
                } else {
                  controller.insertBlankLine(block.id, offset);
                }
                final expectedText = fixture.text.replaceRange(
                  safeOffset,
                  safeOffset,
                  '\n' * count,
                );
                void check(BusyBlock edited) {
                  expect(edited.plainText, expectedText);
                  expect(_anchoredInlineSignatures(edited), expected);
                }

                check(controller.document.blocks.single);
                final saved = controller.markdown;
                controller.rebaseCommittedSource(saved);
                expect(controller.markdown, saved);
                check(controller.document.blocks.single);
                final reopened = parser
                    .parse(filePath: 'breaks.md', source: saved, mode: mode)
                    .busyDocument;
                check(reopened.blocks.single);
              },
            );
          }
        }
      }
    }

    for (final count in [1, 2]) {
      testWidgets('toolbar count=$count publishes once and restores history', (
        tester,
      ) async {
        const original = '**a  \n![](first.png)![](second.png)b**\n';
        final document = parser
            .parse(filePath: 'breaks.md', source: original)
            .busyDocument;
        final before = document.blocks.single;
        final originalAnchors = _anchoredInlineSignatures(before);
        final expected = [
          for (final anchor in _individualImageAnchors(before))
            [
              anchor.offset + count,
              _inlineSignatures([anchor.inline]),
            ],
        ];
        BusyDocument live = document;
        var source = original;
        var publications = 0;
        await tester.pumpWidget(
          _app(
            BusyMarkWysiwygEditor(
              document: document,
              onDocumentChanged: (value) => live = value,
              onSourceChanged: (_, value) {
                source = value;
                publications++;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        final field = tester.widget<TextField>(
          find.widgetWithText(TextField, 'a\nb'),
        );
        field.focusNode!.requestFocus();
        field.controller!.selection = const TextSelection.collapsed(offset: 1);
        await tester.pump();
        final button = find.byWidgetPredicate(
          (w) =>
              w is BusyMarkHeaderIconButton &&
              w.icon ==
                  (count == 1
                      ? BusyMarkGlyphs.hardBreak
                      : BusyMarkGlyphs.blankLine),
        );
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(publications, 1);
        final editedSource = source;
        expect(_anchoredInlineSignatures(live.blocks.single), expected);
        expect(field.controller!.text, 'a${'\n' * (count + 1)}b');
        expect(field.focusNode!.hasFocus, isTrue);
        expect(
          field.controller!.selection,
          TextSelection.collapsed(offset: 1 + count),
        );
        expect(
          (tester.state(find.byType(BusyMarkWysiwygEditor)) as dynamic)
              .debugUndoSnapshotCount,
          1,
        );
        expect(
          _anchoredInlineSignatures(
            parser
                .parse(filePath: 'breaks.md', source: editedSource)
                .busyDocument
                .blocks
                .single,
          ),
          expected,
        );
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pumpAndSettle();
        expect(source, original);
        expect(_anchoredInlineSignatures(live.blocks.single), originalAnchors);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pumpAndSettle();
        expect(source, editedSource);
        expect(_anchoredInlineSignatures(live.blocks.single), expected);
      });
    }
  });
}

List<Object?> _anchoredInlineSignatures(BusyBlock block) => [
  for (final anchor in _individualImageAnchors(block))
    [
      anchor.offset,
      _inlineSignatures([anchor.inline]),
    ],
];

List<BusyInlineSemanticAnchor> _individualImageAnchors(BusyBlock block) {
  final anchors = <BusyInlineSemanticAnchor>[];
  var offset = 0;
  void visit(BusyInline inline, List<BusyInline> ancestors) {
    if (inline.kind == BusyInlineKind.image) {
      var wrapped = inline;
      for (final ancestor in ancestors.reversed) {
        wrapped = ancestor.copyWith(text: '', children: [wrapped]);
      }
      anchors.add(BusyInlineSemanticAnchor(offset: offset, inline: wrapped));
      offset += inline.plainText.length;
    } else if (inline.children.isNotEmpty) {
      for (final child in inline.children) {
        visit(child, [...ancestors, inline]);
      }
    } else {
      offset += inline.plainText.length;
    }
  }

  for (final inline in block.inlines) {
    visit(inline, const []);
  }
  return anchors;
}

void _structuralBoundaryRegressions(MarkdownParser parser) {
  group('structural boundaries', () {
    test(
      'ordinary edits preserve formatting around zero-width inline objects on reopen',
      () {
        final document = parser
            .parse(
              filePath: 'image.md',
              source: '**a![](first.png)![](second.png)b**![](third.png)c\n',
            )
            .busyDocument;
        final block = document.blocks.single;
        expect(block.plainText, 'abc');
        final expected = busyInlineSemanticAnchors(
          block.inlines,
        ).map((a) => _inlineSignatures([a.inline])).toList();
        expect(expected, hasLength(3));
        final controller = BusyMarkWysiwygDocumentController(
          document: document,
        );
        addTearDown(controller.dispose);
        controller.updateBlockText(block.id, 'abcX');
        final saved = controller.markdown;
        final reopened = parser
            .parse(filePath: 'image.md', source: saved)
            .busyDocument
            .blocks
            .single;
        expect(reopened.plainText, 'abcX', reason: saved);
        expect(
          busyInlineSemanticAnchors(
            reopened.inlines,
          ).map((a) => _inlineSignatures([a.inline])).toList(),
          expected,
          reason: saved,
        );
      },
    );

    test(
      'Writerside Backspace inverse after source publication removes the inserted paragraph source',
      () {
        const source =
            '# Topic\n\n## About the job {id="job" collapsible="true" default-state="expanded"}\n\nBody.\n';
        final controller = BusyMarkWysiwygDocumentController(
          document: parser
              .parse(
                filePath: 'topic.md',
                source: source,
                mode: MarkdownMode.writersideMarkdown,
              )
              .busyDocument,
        );
        addTearDown(controller.dispose);
        final heading = controller.document.blocks.singleWhere(
          (b) => b.plainText == 'About the job',
        );
        final entered = controller.applyEnterAt(heading.id, 0)!;
        expect(entered.blockId, heading.id);
        controller.rebaseCommittedSource(controller.markdown);
        final result = controller.applyBackspaceAtStart(heading.id);
        expect(result?.blockId, heading.id);
        expect(
          controller.document.blocks.where(
            (b) => b.kind == BusyBlockKind.paragraph && b.plainText.isEmpty,
          ),
          isEmpty,
        );
        expect(controller.markdown, source);
        controller.rebaseCommittedSource(controller.markdown);
        expect(controller.markdown, source);
        expect(
          controller.blockById(heading.id)!.attributes['collapsible'],
          'true',
        );
      },
    );

    for (final icon in [BusyMarkGlyphs.hardBreak, BusyMarkGlyphs.blankLine]) {
      testWidgets('read-only line-break toolbar $icon cannot create history', (
        tester,
      ) async {
        final document = parser
            .parse(filePath: 'heading.md', source: '## About the job\n')
            .busyDocument;
        var publications = 0;
        await tester.pumpWidget(
          _app(
            DocumentReadOnlyScope(
              readOnly: true,
              child: BusyMarkWysiwygEditor(
                document: document,
                onSourceChanged: (_, _) => publications++,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final field = tester.widget<TextField>(
          find.widgetWithText(TextField, 'About the job'),
        );
        field.focusNode!.requestFocus();
        field.controller!.selection = const TextSelection.collapsed(offset: 3);
        await tester.pump();
        final button = find.byWidgetPredicate(
          (w) => w is BusyMarkHeaderIconButton && w.icon == icon,
        );
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(publications, 0);
        expect(
          (tester.state(find.byType(BusyMarkWysiwygEditor)) as dynamic)
              .debugUndoSnapshotCount,
          0,
        );
        expect(field.controller!.text, 'About the job');
      });
    }

    testWidgets(
      'read-only Enter cannot create structural history or disturb focus',
      (tester) async {
        final document = parser
            .parse(filePath: 'heading.md', source: '## About the job\n')
            .busyDocument;
        var publications = 0;
        await tester.pumpWidget(
          _app(
            DocumentReadOnlyScope(
              readOnly: true,
              child: BusyMarkWysiwygEditor(
                document: document,
                onSourceChanged: (_, _) => publications++,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final field = tester.widget<TextField>(
          find.widgetWithText(TextField, 'About the job'),
        );
        field.focusNode!.requestFocus();
        field.controller!.selection = const TextSelection.collapsed(offset: 0);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(publications, 0);
        expect(
          (tester.state(find.byType(BusyMarkWysiwygEditor)) as dynamic)
              .debugUndoSnapshotCount,
          0,
        );
        expect(field.focusNode!.hasFocus, isTrue);
        expect(
          field.controller!.selection,
          const TextSelection.collapsed(offset: 0),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
        expect(
          field.controller!.selection,
          const TextSelection.collapsed(offset: 1),
        );
      },
    );

    test('table cells reject document-block splitting and sibling merging', () {
      final document = parser
          .parse(
            filePath: 'table.md',
            source: '| A | B |\n| --- | --- |\n| one | two |\n',
          )
          .busyDocument;
      final cell = document.blocks.single.children.last.children.last;
      final controller = BusyMarkWysiwygDocumentController(document: document);
      addTearDown(controller.dispose);
      final before = controller.markdown;
      expect(controller.applyBackspaceAtStart(cell.id), isNull);
      expect(controller.applyEnterAt(cell.id, 0), isNull);
      expect(controller.markdown, before);
    });

    for (final scope in BusyWysiwygReplacementScope.values) {
      for (final end in [5, 13]) {
        test(
          'range replacement newline scope=$scope end=$end is position-aware',
          () {
            final document = parser
                .parse(
                  filePath: 'heading.md',
                  source: '## About the job {id="job"}\n',
                )
                .busyDocument;
            final heading = document.blocks.single;
            final controller = BusyMarkWysiwygDocumentController(
              document: document,
            );
            addTearDown(controller.dispose);
            final result = controller.replaceTextSelectionWithText(
              firstBlockId: heading.id,
              firstStartOffset: 0,
              lastBlockId: heading.id,
              lastEndOffset: end,
              removedBlockIds: [heading.id],
              replacementText: '\n',
              activeInlineKinds: const [],
              preserveTextWhitespace: true,
              replacementScope: scope,
            );
            expect(result, isNotNull);
            if (end == 13) {
              expect(
                controller.document.blocks.map((b) => b.kind),
                everyElement(BusyBlockKind.paragraph),
              );
            } else {
              expect(controller.document.blocks.last.id, heading.id);
              expect(
                controller.document.blocks.last.kind,
                BusyBlockKind.heading,
              );
              expect(controller.document.blocks.last.plainText, ' the job');
            }
          },
        );
      }
    }

    testWidgets(
      'rejected text-input list exit cannot fall back to a local newline',
      (tester) async {
        final document = parser
            .parse(
              filePath: 'topic.md',
              mode: MarkdownMode.writersideMarkdown,
              source: '- Parent\n\n{id="owner"}\n',
            )
            .busyDocument;
        var publications = 0;
        await tester.pumpWidget(
          _app(
            BusyMarkWysiwygEditor(
              document: document,
              onSourceChanged: (_, _) => publications++,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final field = tester.widget<TextField>(
          find.widgetWithText(TextField, 'Parent'),
        );
        field.focusNode!.requestFocus();
        field.controller!.selection = const TextSelection(
          baseOffset: 0,
          extentOffset: 6,
        );
        await tester.pump();
        tester.testTextInput.updateEditingValue(
          const TextEditingValue(
            text: '\n',
            selection: TextSelection.collapsed(offset: 1),
          ),
        );
        await tester.pumpAndSettle();
        expect(publications, 0);
        expect(field.controller!.text, 'Parent');
        expect(
          field.controller!.selection,
          const TextSelection(baseOffset: 0, extentOffset: 6),
        );
        expect(
          (tester.state(find.byType(BusyMarkWysiwygEditor)) as dynamic)
              .debugUndoSnapshotCount,
          0,
        );
      },
    );

    for (final selectedEnd in [5, 15]) {
      testWidgets(
        'local selection Enter at heading prefix $selectedEnd is one edit',
        (tester) async {
          final document = parser
              .parse(filePath: 'heading.md', source: '## About the job\n')
              .busyDocument;
          final heading = document.blocks.single;
          BusyDocument? live;
          var publications = 0;
          await tester.pumpWidget(
            _app(
              BusyMarkWysiwygEditor(
                document: document,
                onDocumentChanged: (value) => live = value,
                onSourceChanged: (_, _) => publications++,
              ),
            ),
          );
          await tester.pumpAndSettle();
          final field = tester.widget<TextField>(
            find.byKey(ValueKey('wysiwyg-field-heading.md-${heading.id}')),
          );
          field.focusNode!.requestFocus();
          field.controller!.selection = TextSelection(
            baseOffset: 0,
            extentOffset: selectedEnd.clamp(0, heading.plainText.length),
          );
          await tester.pump();
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pumpAndSettle();
          expect(publications, 1);
          if (selectedEnd < heading.plainText.length) {
            expect(live!.blocks.last.id, heading.id);
            expect(live!.blocks.last.kind, BusyBlockKind.heading);
            expect(
              live!.blocks.last.plainText,
              heading.plainText.substring(selectedEnd),
            );
          } else {
            expect(
              live!.blocks.where((b) => b.kind == BusyBlockKind.heading),
              isEmpty,
            );
          }
        },
      );
    }

    testWidgets('rejected Enter over attributed sole list member is atomic', (
      tester,
    ) async {
      final document = parser
          .parse(
            filePath: 'topic.md',
            mode: MarkdownMode.writersideMarkdown,
            source: '- Parent\n\n{id="owner"}\n',
          )
          .busyDocument;
      final member = _blocksDepthFirst(
        document.blocks,
      ).singleWhere((b) => b.plainText == 'Parent');
      BusyDocument? live;
      var publications = 0;
      await tester.pumpWidget(
        _app(
          BusyMarkWysiwygEditor(
            document: document,
            onDocumentChanged: (value) => live = value,
            onSourceChanged: (_, _) => publications++,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(
        find.byKey(ValueKey('wysiwyg-field-topic.md-${member.id}')),
      );
      field.focusNode!.requestFocus();
      field.controller!.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 6,
      );
      await tester.pump();
      final beforeUndo =
          (tester.state(find.byType(BusyMarkWysiwygEditor)) as dynamic)
              .debugUndoSnapshotCount;
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(publications, 0);
      expect(live, isNull);
      expect(field.controller!.text, 'Parent');
      expect(
        field.controller!.selection,
        const TextSelection(baseOffset: 0, extentOffset: 6),
      );
      expect(
        (tester.state(find.byType(BusyMarkWysiwygEditor)) as dynamic)
            .debugUndoSnapshotCount,
        beforeUndo,
      );
      // A later edit publishes the model too: do not mask a staged deletion.
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'Parent!',
          selection: TextSelection.collapsed(offset: 7),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        _blocksDepthFirst(live!.blocks).where((b) => b.plainText == 'Parent!'),
        hasLength(1),
      );
    });

    test(
      'property publication followed by nested split preserves source and edited properties',
      () {
        final controller = BusyMarkWysiwygDocumentController(
          document: parser
              .parse(
                filePath: 'topic.md',
                mode: MarkdownMode.writersideMarkdown,
                source: '# Topic\n\n> AlphaBeta\n\n{id="quote"}\n',
              )
              .busyDocument,
        );
        addTearDown(controller.dispose);
        final quote = controller.document.blocks.last;
        final paragraph = quote.children.single;
        expect(
          controller.updateWritersideProperty(quote.id, 'id', 'changed'),
          isTrue,
        );
        final committed = controller.markdown;
        controller.rebaseCommittedSource(committed);
        controller.applyEnterAt(paragraph.id, 5);
        final saved = controller.markdown;
        expect(saved, contains('> Alpha\n>\n> Beta'));
        expect(saved, contains('id="changed"'));
        controller.rebaseCommittedSource(saved);
        expect(controller.markdown, saved);
      },
    );

    test(
      'protected and generated blocks reject direct structural operations',
      () {
        final parsed = parser
            .parse(filePath: 'heading.md', source: '## About\n')
            .busyDocument;
        for (final block in [
          parsed.blocks.single.copyWith(isSourceProtected: true),
          parsed.blocks.single.copyWith(isSourceOnly: true),
          parsed.blocks.single.copyWith(isGenerated: true),
          parsed.blocks.single.copyWith(preserveRaw: true),
        ]) {
          final controller = BusyMarkWysiwygDocumentController(
            document: parsed.copyWith(blocks: [block]),
          );
          addTearDown(controller.dispose);
          final before = controller.document;
          expect(controller.applyEnterAt(block.id, 0), isNull);
          expect(
            controller.replaceBlockTextWithParagraphs(block.id, '\nAbout', 1),
            isNull,
          );
          expect(controller.document, same(before));
        }
      },
    );

    test('semantic-only list item cannot exit and discard its object', () {
      final document = parser
          .parse(filePath: 'list.md', source: '- ![](image.png)\n')
          .busyDocument;
      final item = document.blocks.single;
      expect(item.plainText, isEmpty);
      for (final input in [false, true]) {
        final controller = BusyMarkWysiwygDocumentController(
          document: document,
        );
        addTearDown(controller.dispose);
        if (input) {
          controller.replaceBlockTextWithParagraphs(item.id, '\n', 1);
        } else {
          controller.applyEnterAt(item.id, 0);
        }
        expect(controller.markdown, contains('![](image.png)'));
        expect(
          busyInlineSemanticAnchors(controller.blockById(item.id)!.inlines),
          hasLength(1),
        );
      }
    });

    for (final later in [false, true]) {
      for (final mode in MarkdownMode.values) {
        for (var level = 1; level <= 6; level++) {
          for (final path in ['Enter', 'text input', 'paste']) {
            test(
              '$mode H$level start via $path retains heading identity later=$later',
              () {
                final document = parser
                    .parse(
                      filePath: 'heading.md',
                      mode: mode,
                      source:
                          '${later ? 'Introduction\n\n' : ''}${'#' * level} **About** ![](image.png)the job {id="job"}\n',
                    )
                    .busyDocument;
                final heading = document.blocks.last;
                final controller = BusyMarkWysiwygDocumentController(
                  document: document,
                );
                addTearDown(controller.dispose);
                final result = path == 'Enter'
                    ? controller.applyEnterAt(heading.id, 0)
                    : controller.replaceBlockTextWithParagraphs(
                        heading.id,
                        '\n${heading.plainText}',
                        1,
                        allowListExit: path != 'paste',
                        preserveTextWhitespace: path == 'paste',
                      );
                expect(result?.blockId, heading.id);
                expect(result?.offset, 0);
                expect(
                  controller.document.blocks
                      .skip(later ? 1 : 0)
                      .map((b) => b.kind),
                  [BusyBlockKind.paragraph, BusyBlockKind.heading],
                );
                final kept = controller.blockById(heading.id)!;
                expect(kept.attributes['level'], '$level');
                expect(kept.attributes['id'], 'job');
                expect(kept.attributes['generatedId'], 'false');
                expect(
                  _inlineSignatures(kept.inlines),
                  _inlineSignatures(heading.inlines),
                );
                final paragraph = controller.document.blocks[later ? 1 : 0];
                expect(paragraph.id, isNot(heading.id));
                expect(paragraph.plainText, isEmpty);
                expect(busyInlineSemanticAnchors(paragraph.inlines), isEmpty);
                expect(paragraph.attributes, isNot(contains('id')));
                final saved = controller.markdown;
                controller.rebaseCommittedSource(saved);
                expect(controller.markdown, saved);
                final reopened = parser
                    .parse(filePath: 'heading.md', source: saved, mode: mode)
                    .busyDocument;
                expect(reopened.blocks.last.kind, BusyBlockKind.heading);
                expect(reopened.blocks.last.attributes['level'], '$level');
                expect(
                  _inlineSignatures(reopened.blocks.last.inlines),
                  _inlineSignatures(heading.inlines),
                );
              },
            );
          }
        }
      }
    }

    for (final mode in MarkdownMode.values) {
      for (var level = 1; level <= 6; level++) {
        for (final offset in [3, 6]) {
          test(
            '$mode H$level heading middle/end $offset keeps existing split semantics',
            () {
              final document = parser
                  .parse(
                    filePath: 'heading.md',
                    mode: mode,
                    source: '${'#' * level} abcdef\n',
                  )
                  .busyDocument;
              for (final input in [false, true]) {
                final controller = BusyMarkWysiwygDocumentController(
                  document: document,
                );
                addTearDown(controller.dispose);
                final heading = document.blocks.single;
                final result = input
                    ? controller.replaceBlockTextWithParagraphs(
                        heading.id,
                        'abcdef'.replaceRange(offset, offset, '\n'),
                        offset + 1,
                      )
                    : controller.applyEnterAt(heading.id, offset);
                expect(controller.document.blocks.first.id, heading.id);
                expect(
                  controller.document.blocks.first.kind,
                  BusyBlockKind.heading,
                );
                expect(
                  controller.document.blocks.first.plainText,
                  'abcdef'.substring(0, offset),
                );
                expect(
                  controller.document.blocks.last.kind,
                  BusyBlockKind.paragraph,
                );
                expect(
                  controller.document.blocks.last.plainText,
                  'abcdef'.substring(offset),
                );
                expect(result?.blockId, controller.document.blocks.last.id);
              }
            },
          );
        }
      }
    }

    for (final offset in [0, 3, 6]) {
      test('Writerside heading attributes stay with heading at $offset', () {
        for (final input in [false, true]) {
          final document = parser
              .parse(
                filePath: 'topic.md',
                mode: MarkdownMode.writersideMarkdown,
                source:
                    '# Topic\n\n## abcdef {id="section" collapsible="true" default-state="expanded"}\n',
              )
              .busyDocument;
          final heading = document.blocks.last;
          final controller = BusyMarkWysiwygDocumentController(
            document: document,
          );
          addTearDown(controller.dispose);
          if (input) {
            controller.replaceBlockTextWithParagraphs(
              heading.id,
              'abcdef'.replaceRange(offset, offset, '\n'),
              offset + 1,
            );
          } else {
            controller.applyEnterAt(heading.id, offset);
          }
          final paragraph = controller.document.blocks.singleWhere(
            (b) => b.kind == BusyBlockKind.paragraph,
          );
          for (final key in [
            'id',
            'level',
            'generatedId',
            'collapsible',
            'default-state',
            'busymark-writerside-source-attributes',
            'busymark-property-edits',
          ]) {
            expect(paragraph.attributes, isNot(contains(key)), reason: key);
          }
          final saved = controller.markdown;
          expect('collapsible='.allMatches(saved), hasLength(1));
          expect('default-state='.allMatches(saved), hasLength(1));
          controller.rebaseCommittedSource(saved);
          expect(controller.markdown, saved);
          final reopened = parser
              .parse(
                filePath: 'topic.md',
                source: saved,
                mode: MarkdownMode.writersideMarkdown,
              )
              .busyDocument;
          final section = reopened.blocks.singleWhere(
            (b) => b.attributes['id'] == 'section',
          );
          expect(section.kind, BusyBlockKind.heading);
          expect(section.attributes['collapsible'], 'true');
          expect(section.attributes['default-state'], 'expanded');
        }
      });
    }

    for (final nested in [false, true]) {
      test(
        'Backspace removes only the empty preceding paragraph nested=$nested',
        () {
          final source = nested
              ? '> Clear\n>\n> ## **About** ![](image.png)job {id="job"}\n'
              : 'Clear\n\n## **About** ![](image.png)job {id="job"}\n';
          final document = parser
              .parse(filePath: 'heading.md', source: source)
              .busyDocument;
          final siblings = nested
              ? document.blocks.single.children
              : document.blocks;
          final paragraph = siblings.first;
          final heading = siblings.last;
          final controller = BusyMarkWysiwygDocumentController(
            document: document,
          );
          addTearDown(controller.dispose);
          controller.updateBlockText(paragraph.id, '');
          final result = controller.applyBackspaceAtStart(heading.id);
          expect(result?.blockId, heading.id);
          expect(result?.offset, 0);
          final kept = controller.blockById(heading.id)!;
          expect(kept.kind, BusyBlockKind.heading);
          expect(kept.attributes['id'], 'job');
          expect(
            _inlineSignatures(kept.inlines),
            _inlineSignatures(heading.inlines),
          );
          expect(controller.blockById(paragraph.id), isNull);
          final reopened = parser
              .parse(filePath: 'heading.md', source: controller.markdown)
              .busyDocument;
          expect(
            _blocksDepthFirst(
              reopened.blocks,
            ).where((b) => b.kind == BusyBlockKind.heading),
            hasLength(1),
          );
        },
      );
    }

    for (final marker in ['-', '1.', '- [ ]']) {
      for (final input in [false, true]) {
        for (final clear in [false, true]) {
          test(
            'list $marker start input=$input clear=$clear retains parent subtree',
            () {
              final indent = marker == '1.' ? '   ' : '  ';
              final document = parser
                  .parse(
                    filePath: 'list.md',
                    source:
                        '$marker Parent\n$indent- Child\n$indent  - Grandchild\n',
                  )
                  .busyDocument;
              final parent = document.blocks.single;
              final controller = BusyMarkWysiwygDocumentController(
                document: document,
              );
              addTearDown(controller.dispose);
              if (clear) controller.updateBlockText(parent.id, '');
              final result = input
                  ? controller.replaceBlockTextWithParagraphs(
                      parent.id,
                      '\n${clear ? '' : parent.plainText}',
                      1,
                    )
                  : controller.applyEnterAt(parent.id, 0);
              expect(result?.blockId, parent.id);
              expect(controller.document.blocks.last.id, parent.id);
              expect(controller.document.blocks.first.children, isEmpty);
              final kept = controller.blockById(parent.id)!;
              expect(kept.kind, parent.kind);
              expect(kept.children.single.id, parent.children.single.id);
              expect(_blocksDepthFirst(kept.children).map((b) => b.plainText), [
                'Child',
                'Grandchild',
              ]);
              final saved = controller.markdown;
              final reopened = parser
                  .parse(filePath: 'list.md', source: saved)
                  .busyDocument;
              expect(
                _blocksDepthFirst(
                  reopened.blocks,
                ).where((b) => b.plainText == 'Child'),
                hasLength(1),
                reason: saved,
              );
              expect(
                _blocksDepthFirst(
                  reopened.blocks,
                ).where((b) => b.plainText == 'Grandchild'),
                hasLength(1),
                reason: saved,
              );
              expect(
                reopened.blocks.last.children.single.plainText,
                'Child',
                reason: saved,
              );
            },
          );
        }
      }
    }

    for (final operation in ['newline', 'hard break', 'blank line']) {
      for (final offset in [0, 1, 2, 3]) {
        test('$operation preserves ordered inline objects at $offset', () {
          final document = parser
              .parse(
                filePath: 'image.md',
                source: '**a![](first.png)![](second.png)b**![](third.png)c\n',
              )
              .busyDocument;
          final block = document.blocks.single;
          expect(block.plainText, 'abc');
          expect(
            busyInlineStyleRanges(
              block.inlines,
            ).where((r) => r.kind == BusyInlineKind.strong),
            isNotEmpty,
          );
          final expected = busyInlineSemanticAnchors(
            block.inlines,
          ).map((a) => _inlineSignatures([a.inline])).toList();
          expect(expected, hasLength(3));
          final controller = BusyMarkWysiwygDocumentController(
            document: document,
          );
          addTearDown(controller.dispose);
          switch (operation) {
            case 'newline':
              controller.replaceBlockTextWithParagraphs(
                block.id,
                block.plainText.replaceRange(offset, offset, '\n'),
                offset + 1,
                allowListExit: false,
              );
            case 'hard break':
              controller.insertHardBreak(block.id, offset);
            case 'blank line':
              controller.insertBlankLine(block.id, offset);
          }
          final objects = [
            for (final b in controller.document.blocks)
              ...busyInlineSemanticAnchors(
                b.inlines,
              ).map((a) => _inlineSignatures([a.inline])),
          ];
          expect(objects, expected);
          var precedingText = 0;
          final actualOffsets = <int>[];
          for (final fragment in controller.document.blocks) {
            actualOffsets.addAll(
              busyInlineSemanticAnchors(
                fragment.inlines,
              ).map((a) => precedingText + a.offset),
            );
            precedingText +=
                fragment.plainText.length + (operation == 'newline' ? 1 : 0);
          }
          final insertedLength = operation == 'blank line' ? 2 : 1;
          expect(
            actualOffsets,
            busyInlineSemanticAnchors(block.inlines).map(
              (a) => a.offset <= offset ? a.offset : a.offset + insertedLength,
            ),
          );
          final saved = controller.markdown;
          final reopened = parser
              .parse(filePath: 'image.md', source: saved)
              .busyDocument;
          expect(
            [
              for (final b in reopened.blocks)
                ...busyInlineSemanticAnchors(
                  b.inlines,
                ).map((a) => _inlineSignatures([a.inline])),
            ],
            expected,
            reason: saved,
          );
        });
      }
    }

    testWidgets(
      'physical Enter at heading start keeps focus, publishes once and undoes',
      (tester) async {
        final document = parser
            .parse(
              filePath: 'header_test_text.md',
              source: '## About the job\n',
            )
            .busyDocument;
        final heading = document.blocks.single;
        var publications = 0;
        var source = document.source!;
        BusyDocument? live;
        await tester.pumpWidget(
          _app(
            BusyMarkWysiwygEditor(
              document: document,
              onDocumentChanged: (value) => live = value,
              onSourceChanged: (_, value) {
                source = value;
                publications++;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        final field = tester.widget<TextField>(
          find.byKey(
            ValueKey('wysiwyg-field-header_test_text.md-${heading.id}'),
          ),
        );
        field.focusNode!.requestFocus();
        field.controller!.selection = const TextSelection.collapsed(offset: 0);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(publications, 1);
        expect(live!.blocks.map((b) => b.kind), [
          BusyBlockKind.paragraph,
          BusyBlockKind.heading,
        ]);
        final kept = tester.widget<TextField>(
          find.byKey(
            ValueKey('wysiwyg-field-header_test_text.md-${heading.id}'),
          ),
        );
        expect(kept.focusNode!.hasFocus, isTrue);
        expect(
          kept.controller!.selection,
          const TextSelection.collapsed(offset: 0),
        );
        expect(source, contains('## About the job'));
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pumpAndSettle();
        expect(source, '## About the job\n');
        expect(live!.blocks, hasLength(1));
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pumpAndSettle();
        expect(live!.blocks.map((b) => b.kind), [
          BusyBlockKind.paragraph,
          BusyBlockKind.heading,
        ]);
      },
    );
  });
}

List<Object?> _inlineSignatures(List<BusyInline> inlines) => [
  for (final inline in inlines)
    [
      inline.kind,
      inline.text,
      inline.destination,
      inline.attributes,
      _inlineSignatures(inline.children),
    ],
];

Iterable<BusyBlock> _blocksDepthFirst(Iterable<BusyBlock> blocks) sync* {
  for (final block in blocks) {
    yield block;
    yield* _blocksDepthFirst(block.children);
  }
}

Widget _app(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SizedBox(width: 900, height: 640, child: child)),
  );
}
