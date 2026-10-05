import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/busymark_markdown_serializer.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_document_controller.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_commands.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_inline_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const serializer = BusyMarkMarkdownSerializer();

  test(
    'partially formatted URL source offsets and text atoms survive save and edit',
    () {
      const parser = MarkdownParser();
      const url = 'https://example.com/path';
      const prefix = 'https://example.com';
      const source = '[https://example.co&#109;**/path**]($url)';
      final controller = BusyMarkWysiwygDocumentController(
        document: parser.parse(filePath: 'topic.md', source: '').busyDocument,
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
        expect(serializer.serializeInlineFragment(block.inlines), source);
        for (var offset = 0; offset <= url.length; offset++) {
          final result = serializer.serializeInlineFragmentWithOffsets(
            block.inlines,
            textOffset: offset,
          );
          expect(result.source, source);
          final expectedOffset = offset == 0
              ? 0
              : offset == url.length
              ? source.length
              : offset < prefix.length
              ? offset + 1
              : offset == prefix.length
              ? offset + 6
              : offset + 8;
          expect(result.sourceOffset, expectedOffset, reason: 'offset $offset');
          expect(result.textAtoms, hasLength(url.length));
          for (var index = 0; index < url.length; index++) {
            final atom = result.textAtoms[index];
            final start = index < prefix.length - 1
                ? index + 1
                : index == prefix.length - 1
                ? index + 1
                : index + 8;
            final end = index == prefix.length - 1 ? start + 6 : start + 1;
            expect((atom.textStart, atom.textEnd), (index, index + 1));
            expect((atom.sourceStart, atom.sourceEnd), (start, end));
            expect(atom.text, url[index]);
            expect(atom.escaped, index == prefix.length - 1);
            expect(
              source.substring(start, end),
              atom.escaped ? '&#109;' : atom.text,
            );
          }
        }
      }

      check(controller.document.blocks.first);
      final saved = parser
          .parse(filePath: 'topic.md', source: controller.markdown)
          .busyDocument;
      check(saved.blocks.single);
      final reopened = BusyMarkWysiwygDocumentController(document: saved);
      addTearDown(reopened.dispose);
      reopened.updateBlockText(saved.blocks.single.id, '$url!');
      final reparsed = parser
          .parse(filePath: 'topic.md', source: reopened.markdown)
          .busyDocument
          .blocks
          .single;
      expect(reparsed.plainText, '$url!');
      expect(
        busyInlineStyleRanges(reparsed.inlines)
            .where((range) => range.kind == BusyInlineKind.link)
            .every((range) => range.destination == url),
        isTrue,
      );
      expect(
        busyInlineStyleRanges(
          reparsed.inlines,
        ).where((range) => range.kind == BusyInlineKind.strong).isNotEmpty,
        isTrue,
      );
    },
  );

  test(
    'URL punctuation beside surrounding formatting retains literal and style boundaries',
    () {
      const parser = MarkdownParser();
      const url = 'https://example.com';
      const link = BusyInline(
        kind: BusyInlineKind.link,
        text: url,
        destination: url,
        attributes: {busyMarkBareUrlAttribute: 'true'},
        children: [BusyInline(kind: BusyInlineKind.text, text: url)],
      );
      for (final suffix in ['*', '_', '~', '**', '__', '~~', '*_~']) {
        final literal = BusyInline(kind: BusyInlineKind.text, text: suffix);
        for (final inside in [false, true]) {
          final inlines = [
            BusyInline(
              kind: BusyInlineKind.strong,
              text: '',
              children: [link, if (inside) literal],
            ),
            if (!inside) literal,
          ];
          final source = serializer.serializeInlineFragment(inlines);
          final parsed = parser.parseInlineFragment(source: source);
          expect(
            parsed.map((inline) => inline.plainText).join(),
            '$url$suffix',
            reason: source,
          );
          final ranges = busyInlineStyleRanges(parsed);
          final links = ranges.where(
            (range) => range.kind == BusyInlineKind.link,
          );
          expect(links.single.destination, url, reason: source);
          final bold = ranges
              .where((range) => range.kind == BusyInlineKind.strong)
              .toList();
          expect(bold.first.start, 0);
          expect(
            bold.last.end,
            inside ? url.length + suffix.length : url.length,
            reason: source,
          );
          for (var offset = 0; offset <= url.length + suffix.length; offset++) {
            final result = serializer.serializeInlineFragmentWithOffsets(
              inlines,
              textOffset: offset,
            );
            expect(result.source, source);
            expect(
              result.textAtoms.map((atom) => atom.text).join(),
              '$url$suffix',
            );
            if (offset == 0) expect(result.sourceOffset, 0);
            if (offset == url.length + suffix.length) {
              expect(result.sourceOffset, source.length);
            }
            for (final atom in result.textAtoms) {
              expect(
                source.substring(atom.sourceStart, atom.sourceEnd),
                atom.escaped ? '\\${atom.text}' : atom.text,
              );
            }
          }
          for (final mode in [
            MarkdownMode.commonMark,
            MarkdownMode.writersideMarkdown,
          ]) {
            final original = BusyMarkWysiwygDocumentController(
              document: BusyDocument(
                filePath: 'topic.md',
                mode: mode,
                blocks: [
                  BusyBlock(
                    id: 'paragraph',
                    kind: BusyBlockKind.paragraph,
                    inlines: inlines,
                    dirty: true,
                  ),
                ],
              ),
            );
            final reopened = BusyMarkWysiwygDocumentController(
              document: parser
                  .parse(
                    filePath: 'topic.md',
                    source: original.markdown,
                    mode: mode,
                  )
                  .busyDocument,
            );
            addTearDown(original.dispose);
            addTearDown(reopened.dispose);
            const changed = 'https://other.com';
            for (final controller in [original, reopened]) {
              controller.updateBlockText(
                controller.document.blocks.single.id,
                '$changed$suffix',
              );
              final links = busyInlineStyleRanges(
                controller.document.blocks.single.inlines,
              ).where((range) => range.kind == BusyInlineKind.link).toList();
              expect((links.first.start, links.last.end), (0, changed.length));
              expect(
                links.every(
                  (range) => range.destination == (inside ? url : changed),
                ),
                isTrue,
                reason: '$mode $suffix inside=$inside: $source',
              );
            }
            expect(original.markdown, reopened.markdown);
          }
        }
      }
    },
  );

  test(
    'surrounding formatting commits the same URL editing semantics as reopening',
    () {
      const parser = MarkdownParser();
      const url = 'https://example.com';
      const changed = 'https://other.com';
      for (final mode in [
        MarkdownMode.commonMark,
        MarkdownMode.writersideMarkdown,
      ]) {
        for (final suffix in ['*', '_', '~', '*_~', '<', '*<']) {
          for (final formatBeforeEnter in [false, true]) {
            final original = BusyMarkWysiwygDocumentController(
              document: parser
                  .parse(filePath: 'topic.md', source: '', mode: mode)
                  .busyDocument,
            );
            addTearDown(original.dispose);
            final id = original.document.blocks.single.id;
            original.updateBlockText(id, '$url$suffix');
            void format() => original.applyInlineCommand(
              id,
              BusyWysiwygInlineCommand.bold,
              0,
              url.length + suffix.length,
            );
            if (formatBeforeEnter) format();
            original.applyEnterAt(id, url.length + suffix.length);
            if (!formatBeforeEnter) format();
            final source = original.markdown;
            final reopened = BusyMarkWysiwygDocumentController(
              document: parser
                  .parse(filePath: 'topic.md', source: source, mode: mode)
                  .busyDocument,
            );
            addTearDown(reopened.dispose);
            original.updateBlockText(id, '$changed$suffix');
            reopened.updateBlockText(
              reopened.document.blocks.single.id,
              '$changed$suffix',
            );
            BusyInlineStyleRange link(
              BusyMarkWysiwygDocumentController controller,
            ) => busyInlineStyleRanges(
              controller.document.blocks.first.inlines,
            ).where((range) => range.kind == BusyInlineKind.link).single;
            expect(
              link(original).destination,
              link(reopened).destination,
              reason:
                  '$mode $suffix formatBeforeEnter=$formatBeforeEnter: $source',
            );
            expect(original.markdown.trim(), reopened.markdown.trim());
            expect(original.document.blocks.first.plainText, '$changed$suffix');
            expect(link(original).destination, url);
            expect(
              link(original).attributes.containsKey(busyMarkBareUrlAttribute),
              isFalse,
            );
            expect(
              link(reopened).attributes.containsKey(busyMarkBareUrlAttribute),
              isFalse,
            );
            for (final controller in [original, reopened]) {
              final block = controller.document.blocks.first;
              final bold = busyInlineStyleRanges(
                block.inlines,
              ).where((range) => range.kind == BusyInlineKind.strong).toList();
              expect(
                (bold.first.start, bold.last.end),
                (0, changed.length + suffix.length),
              );
              for (var offset = 0; offset < block.plainText.length; offset++) {
                expect(
                  bold.any(
                    (range) => range.start <= offset && range.end > offset,
                  ),
                  isTrue,
                );
              }
              final reparsed = parser
                  .parse(
                    filePath: 'topic.md',
                    source: controller.markdown,
                    mode: mode,
                  )
                  .busyDocument
                  .blocks
                  .single;
              expect(reparsed.plainText, '$changed$suffix');
              final links = busyInlineStyleRanges(
                reparsed.inlines,
              ).where((range) => range.kind == BusyInlineKind.link).toList();
              expect((links.first.start, links.last.end), (0, changed.length));
              expect(links.every((range) => range.destination == url), isTrue);
              final ordinary = serializer.serializeInlineFragment(
                block.inlines,
              );
              for (var offset = 0; offset <= block.plainText.length; offset++) {
                final result = serializer.serializeInlineFragmentWithOffsets(
                  block.inlines,
                  textOffset: offset,
                );
                expect(result.source, ordinary);
                if (offset == 0) expect(result.sourceOffset, 0);
                if (offset == block.plainText.length) {
                  expect(result.sourceOffset, ordinary.length);
                }
                expect(
                  result.textAtoms.map((atom) => atom.text).join(),
                  block.plainText,
                );
                for (final atom in result.textAtoms) {
                  final unit = ordinary.substring(
                    atom.sourceStart,
                    atom.sourceEnd,
                  );
                  expect(
                    unit,
                    atom.escaped
                        ? atom.text == 'h'
                              ? '&#104;'
                              : '\\${atom.text}'
                        : atom.text,
                  );
                }
              }
            }
          }
        }
      }
    },
  );

  test(
    'bare URL trailing literal punctuation survives serialization and reparse',
    () {
      const parser = MarkdownParser();
      const url = 'https://example.com';
      // Source units specify the authored span of each visible suffix
      // character, including references and escaped literal HTML delimiters.
      const suffixes = <String, List<String>>{
        '*': ['*'],
        '_': ['_'],
        '~': ['~'],
        '**': ['*', '*'],
        '__': ['_', '_'],
        '~~': ['~', '~'],
        '*_~': ['*', '_', '~'],
        '<': ['<'],
        '*<': ['*', '<'],
        '<tag>': ['<', '&#116;', 'a', 'g', '>'],
        '*<b>literal</b>': [
          '*',
          '<',
          '&#98;',
          '>',
          'l',
          'i',
          't',
          'e',
          'r',
          'a',
          'l',
          r'\<',
          '/',
          'b',
          '>',
        ],
        '<b>a</b><i>b</i>': [
          '<',
          '&#98;',
          '>',
          'a',
          r'\<',
          '/',
          'b',
          '>',
          r'\<',
          'i',
          '>',
          'b',
          r'\<',
          '/',
          'i',
          '>',
        ],
        '<https://other.com>': [
          '<',
          '&#104;',
          't',
          't',
          'p',
          's',
          ':',
          '/',
          '/',
          'o',
          't',
          'h',
          'e',
          'r',
          '.',
          'c',
          'o',
          'm',
          '>',
        ],
      };
      for (final mode in [
        MarkdownMode.commonMark,
        MarkdownMode.writersideMarkdown,
      ]) {
        for (final entry in suffixes.entries) {
          final suffix = entry.key;
          final text = '$url$suffix';
          final units = [...url.split(''), ...entry.value];
          final source = units.join();
          final boundaries = <int>[0];
          for (final unit in units) {
            boundaries.add(boundaries.last + unit.length);
          }
          final controller = BusyMarkWysiwygDocumentController(
            document: parser
                .parse(filePath: 'topic.md', source: '', mode: mode)
                .busyDocument,
          );
          addTearDown(controller.dispose);
          final id = controller.document.blocks.single.id;
          controller.updateBlockText(id, text);
          controller.applyEnterAt(id, text.length);
          final block = controller.document.blocks.first;
          void check(BusyBlock block) {
            expect(block.plainText, text, reason: '$mode $suffix');
            final ranges = busyInlineStyleRanges(block.inlines);
            final link = ranges
                .where((range) => range.kind == BusyInlineKind.link)
                .single;
            expect((link.start, link.end), (0, url.length));
            expect(link.destination, url);
            expect(link.attributes[busyMarkBareUrlAttribute], 'true');
            expect(
              ranges.where((range) => range.kind != BusyInlineKind.link),
              isEmpty,
            );
            expect(serializer.serializeInlineFragment(block.inlines), source);
            for (var offset = 0; offset <= text.length; offset++) {
              final result = serializer.serializeInlineFragmentWithOffsets(
                block.inlines,
                textOffset: offset,
              );
              expect(result.source, source);
              expect(
                result.sourceOffset,
                boundaries[offset],
                reason: '$mode $suffix offset $offset',
              );
              expect(result.textAtoms, hasLength(text.length));
              for (var index = 0; index < text.length; index++) {
                final atom = result.textAtoms[index];
                expect((atom.textStart, atom.textEnd), (index, index + 1));
                expect(
                  (atom.sourceStart, atom.sourceEnd),
                  (boundaries[index], boundaries[index + 1]),
                );
                expect(atom.text, text[index]);
                expect(atom.escaped, units[index].length != 1);
                expect(
                  source.substring(atom.sourceStart, atom.sourceEnd),
                  units[index],
                );
              }
            }
          }

          check(block);
          expect(controller.markdown, '$source\n\n');
          final saved = parser
              .parse(
                filePath: 'topic.md',
                source: controller.markdown,
                mode: mode,
              )
              .busyDocument;
          check(saved.blocks.single);
          // Inline parsing and another save cycle must also retain the literal
          // HTML-looking text rather than introduce formatting or another link.
          check(
            block.copyWith(
              inlines: parser.parseInlineFragment(source: source, mode: mode),
            ),
          );
          final reopened = BusyMarkWysiwygDocumentController(document: saved);
          addTearDown(reopened.dispose);
          reopened.updateBlockText(
            reopened.document.blocks.single.id,
            '$url/path$suffix',
          );
          final edited = parser
              .parse(
                filePath: 'topic.md',
                source: reopened.markdown,
                mode: mode,
              )
              .busyDocument
              .blocks
              .single;
          expect(edited.plainText, '$url/path$suffix');
          expect(
            busyInlineStyleRanges(edited.inlines)
                .where((range) => range.kind == BusyInlineKind.link)
                .single
                .destination,
            '$url/path',
          );
        }
      }
    },
  );

  for (final mode in [
    MarkdownMode.commonMark,
    MarkdownMode.writersideMarkdown,
  ]) {
    for (final suffix in ['&copy;', '&amp;', '&amp;*<tag>']) {
      test(
        'bare URL character-reference suffix round-trips in $mode: $suffix',
        () {
          const parser = MarkdownParser();
          const url = 'https://example.com';
          const linkSource = '[$url]($url)';
          final suffixUnits = [
            for (final character in suffix.split(''))
              if ('&*<'.contains(character)) '\\$character' else character,
          ];
          final source = '$linkSource${suffixUnits.join()}';
          final text = '$url$suffix';
          final controller = BusyMarkWysiwygDocumentController(
            document: parser
                .parse(filePath: 'topic.md', source: '', mode: mode)
                .busyDocument,
          );
          addTearDown(controller.dispose);
          final id = controller.document.blocks.single.id;
          controller.updateBlockText(id, text);
          final next = controller.applyEnterAt(id, text.length)!;
          expect(next.offset, 0);

          void check(BusyBlock block) {
            expect(block.plainText, text);
            final ranges = busyInlineStyleRanges(block.inlines);
            final link = ranges
                .where((range) => range.kind == BusyInlineKind.link)
                .single;
            expect(
              (link.start, link.end, link.destination),
              (0, url.length, url),
            );
            expect(
              ranges.where((range) => range.kind != BusyInlineKind.link),
              isEmpty,
            );
            expect(block.plainText.substring(link.end), suffix);
            expect(serializer.serializeInlineFragment(block.inlines), source);
            final suffixBoundaries = [linkSource.length];
            for (final unit in suffixUnits) {
              suffixBoundaries.add(suffixBoundaries.last + unit.length);
            }
            for (var offset = 0; offset <= text.length; offset++) {
              final result = serializer.serializeInlineFragmentWithOffsets(
                block.inlines,
                textOffset: offset,
              );
              expect(result.source, source);
              expect(
                result.sourceOffset,
                offset == 0
                    ? 0
                    : offset < url.length
                    ? offset + 1
                    : suffixBoundaries[offset - url.length],
              );
              expect(result.textAtoms, hasLength(text.length));
              for (var index = 0; index < text.length; index++) {
                final atom = result.textAtoms[index];
                final start = index < url.length
                    ? index + 1
                    : suffixBoundaries[index - url.length];
                final end = index < url.length
                    ? start + 1
                    : suffixBoundaries[index - url.length + 1];
                expect((atom.textStart, atom.textEnd), (index, index + 1));
                expect((atom.sourceStart, atom.sourceEnd), (start, end));
                expect(atom.text, text[index]);
                expect(atom.escaped, end - start > 1);
                expect(
                  source.substring(start, end),
                  index < url.length
                      ? text[index]
                      : suffixUnits[index - url.length],
                );
              }
            }
          }

          // Check the live extent before demonstrating the saved-source failure.
          final live = controller.document.blocks.first;
          final liveLink = busyInlineStyleRanges(
            live.inlines,
          ).where((range) => range.kind == BusyInlineKind.link).single;
          expect(
            (liveLink.start, liveLink.end, liveLink.destination),
            (0, url.length, url),
          );
          expect(live.plainText, text);
          final saved = parser
              .parse(
                filePath: 'topic.md',
                source: controller.markdown,
                mode: mode,
              )
              .busyDocument;
          check(saved.blocks.single);
          check(live);
          expect(controller.markdown, '$source\n\n');
          check(
            live.copyWith(
              inlines: parser.parseInlineFragment(source: source, mode: mode),
            ),
          );
          final reopened = BusyMarkWysiwygDocumentController(document: saved);
          addTearDown(reopened.dispose);
          expect(reopened.markdown, controller.markdown);
        },
      );
    }
  }

  for (final mode in [
    MarkdownMode.commonMark,
    MarkdownMode.writersideMarkdown,
  ]) {
    test(
      'unrecognized URL source preserves literal text and metadata in $mode',
      () {
        const parser = MarkdownParser();
        const text = 'https://example.com*';
        const source = r'&#104;ttps://example.com\*';
        final units = [
          '&#104;',
          ...text.substring(1, text.length - 1).split(''),
          r'\*',
        ];
        final boundaries = [0];
        for (final unit in units) {
          boundaries.add(boundaries.last + unit.length);
        }
        final controller = BusyMarkWysiwygDocumentController(
          document: parser
              .parse(filePath: 'topic.md', source: '', mode: mode)
              .busyDocument,
        );
        addTearDown(controller.dispose);
        final id = controller.document.blocks.single.id;
        controller.updateBlockText(id, text);
        void check(BusyBlock block) {
          expect(block.plainText, text);
          expect(busyInlineStyleRanges(block.inlines), isEmpty);
          for (var offset = 0; offset <= text.length; offset++) {
            final result = serializer.serializeInlineFragmentWithOffsets(
              block.inlines,
              textOffset: offset,
            );
            expect(result.source, source);
            expect(result.sourceOffset, boundaries[offset]);
            expect(result.textAtoms, hasLength(text.length));
            for (var index = 0; index < text.length; index++) {
              final atom = result.textAtoms[index];
              expect((atom.textStart, atom.textEnd), (index, index + 1));
              expect(
                (atom.sourceStart, atom.sourceEnd),
                (boundaries[index], boundaries[index + 1]),
              );
              expect(atom.text, text[index]);
              expect(atom.escaped, units[index].length > 1);
              expect(
                source.substring(atom.sourceStart, atom.sourceEnd),
                units[index],
              );
            }
          }
        }

        check(controller.document.blocks.single);
        expect(controller.markdown, '$source\n');
        check(
          parser
              .parse(
                filePath: 'topic.md',
                source: controller.markdown,
                mode: mode,
              )
              .busyDocument
              .blocks
              .single,
        );
        check(
          controller.document.blocks.single.copyWith(
            inlines: parser.parseInlineFragment(source: source, mode: mode),
          ),
        );
      },
    );
  }

  test('descendant whitespace preservation prevents ancestor trimming', () {
    const preserved = {busyMarkPreserveTextWhitespaceAttribute: 'true'};
    const whitespace = BusyBlock(
      id: 'whitespace',
      kind: BusyBlockKind.paragraph,
      inlines: [BusyInline(kind: BusyInlineKind.text, text: '   ')],
      attributes: preserved,
      dirty: true,
    );
    const document = BusyDocument(
      filePath: 'topic.md',
      mode: MarkdownMode.commonMark,
      blocks: [
        BusyBlock(
          id: 'list',
          kind: BusyBlockKind.unorderedListItem,
          inlines: [BusyInline(kind: BusyInlineKind.text, text: 'Parent')],
          children: [whitespace],
          dirty: true,
        ),
        BusyBlock(
          id: 'quote',
          kind: BusyBlockKind.blockquote,
          children: [
            BusyBlock(
              id: 'quote-text',
              kind: BusyBlockKind.paragraph,
              inlines: [BusyInline(kind: BusyInlineKind.text, text: 'Quoted')],
              dirty: true,
            ),
            whitespace,
          ],
          dirty: true,
        ),
      ],
    );

    final source = serializer.serialize(document);

    expect(source, contains('- Parent\n\n     '));
    expect(source, contains('> Quoted\n>\n>    '));
    expect(source, endsWith('>    \n'));
    expect(source, isNot(contains(busyMarkPreserveTextWhitespaceAttribute)));
  });

  test('ordinary and metadata inline emission are byte-identical', () {
    final fixtures =
        <
          ({
            List<BusyInline> inlines,
            bool tableCell,
            bool atBlockStart,
            bool readableBreaks,
          })
        >[
          (
            inlines: const [
              BusyInline(
                kind: BusyInlineKind.link,
                text: 'https://example.com/a_b?q=x&next=y',
                destination: 'https://example.com/a_b?q=x&next=y',
                attributes: {busyMarkBareUrlAttribute: 'true'},
                children: [
                  BusyInline(
                    kind: BusyInlineKind.text,
                    text: 'https://example.com/a_b?q=x&next=y',
                  ),
                ],
              ),
            ],
            tableCell: false,
            atBlockStart: true,
            readableBreaks: true,
          ),
          (
            inlines: const [
              BusyInline(
                kind: BusyInlineKind.link,
                text: 'https://example.com/a_b?q=x&next=y',
                destination: 'https://example.com/a_b?q=x&next=y',
                attributes: {busyMarkBareUrlAttribute: 'true'},
              ),
            ],
            tableCell: true,
            atBlockStart: false,
            readableBreaks: true,
          ),
          (
            inlines: const [
              BusyInline(kind: BusyInlineKind.text, text: 'plain'),
            ],
            tableCell: false,
            atBlockStart: false,
            readableBreaks: true,
          ),
          (
            inlines: const [
              BusyInline(kind: BusyInlineKind.text, text: '!'),
              BusyInline(
                kind: BusyInlineKind.link,
                text: 'link',
                destination: 'https://example.test',
                attributes: {'title': 'A title'},
                children: [BusyInline(kind: BusyInlineKind.text, text: 'link')],
              ),
            ],
            tableCell: false,
            atBlockStart: false,
            readableBreaks: true,
          ),
          (
            inlines: const [
              BusyInline(
                kind: BusyInlineKind.strong,
                text: 'bold and italic',
                children: [
                  BusyInline(kind: BusyInlineKind.text, text: 'bold '),
                  BusyInline(
                    kind: BusyInlineKind.emphasis,
                    text: 'and italic',
                    children: [
                      BusyInline(kind: BusyInlineKind.text, text: 'and italic'),
                    ],
                  ),
                ],
              ),
            ],
            tableCell: false,
            atBlockStart: false,
            readableBreaks: true,
          ),
          (
            inlines: const [
              BusyInline(kind: BusyInlineKind.text, text: 'left'),
              BusyInline(kind: BusyInlineKind.hardBreak, text: '\n'),
              BusyInline(kind: BusyInlineKind.hardBreak, text: '\n'),
              BusyInline(kind: BusyInlineKind.text, text: 'right'),
            ],
            tableCell: false,
            atBlockStart: false,
            readableBreaks: true,
          ),
          (
            inlines: const [
              BusyInline(
                kind: BusyInlineKind.underline,
                text: 'left\nright',
                children: [
                  BusyInline(kind: BusyInlineKind.text, text: 'left'),
                  BusyInline(kind: BusyInlineKind.hardBreak, text: '\n'),
                  BusyInline(kind: BusyInlineKind.text, text: 'right'),
                ],
              ),
            ],
            tableCell: false,
            atBlockStart: false,
            readableBreaks: true,
          ),
          (
            inlines: const [
              BusyInline(kind: BusyInlineKind.text, text: 'a|b'),
              BusyInline(kind: BusyInlineKind.code, text: 'c|d'),
            ],
            tableCell: true,
            atBlockStart: false,
            readableBreaks: false,
          ),
          (
            inlines: const [
              BusyInline(kind: BusyInlineKind.text, text: '# literal heading'),
            ],
            tableCell: false,
            atBlockStart: true,
            readableBreaks: true,
          ),
          (
            inlines: const [
              BusyInline(
                kind: BusyInlineKind.image,
                text: 'alt',
                destination: 'image.png',
              ),
              BusyInline(kind: BusyInlineKind.math, text: r'x + y'),
              BusyInline(kind: BusyInlineKind.writersideVariable, text: 'name'),
            ],
            tableCell: false,
            atBlockStart: false,
            readableBreaks: true,
          ),
        ];

    for (final fixture in fixtures) {
      final ordinary = serializer.serializeInlineFragment(
        fixture.inlines,
        tableCell: fixture.tableCell,
        atBlockStart: fixture.atBlockStart,
        readableHardBreakRuns: fixture.readableBreaks,
      );
      final textLength = fixture.inlines.fold<int>(
        0,
        (length, inline) => length + inline.plainText.length,
      );
      final metadata = serializer.serializeInlineFragmentWithOffsets(
        fixture.inlines,
        textOffset: textLength ~/ 2,
        tableCell: fixture.tableCell,
        atBlockStart: fixture.atBlockStart,
        readableHardBreakRuns: fixture.readableBreaks,
      );

      expect(metadata.source, ordinary, reason: fixture.toString());
      expect(metadata.sourceOffset, inInclusiveRange(0, ordinary.length));
    }
  });

  test(
    'bare URL offsets and text atoms stay exact through Enter, edit and save/reparse',
    () {
      const parser = MarkdownParser();
      for (final mode in [
        MarkdownMode.commonMark,
        MarkdownMode.writersideMarkdown,
      ]) {
        const url = 'https://example.com';
        final controller = BusyMarkWysiwygDocumentController(
          document: parser
              .parse(filePath: 'topic.md', source: '', mode: mode)
              .busyDocument,
        );
        addTearDown(controller.dispose);
        final id = controller.document.blocks.single.id;
        controller.updateBlockText(id, url);
        controller.applyEnterAt(id, url.length);
        void check(BusyBlock block, String expected) {
          expect(block.inlines.single.kind, BusyInlineKind.link);
          expect(
            block.inlines.single.attributes[busyMarkBareUrlAttribute],
            'true',
          );
          expect(block.inlines.single.destination, expected);
          expect(serializer.serializeInlineFragment(block.inlines), expected);
          for (var offset = 0; offset <= expected.length; offset++) {
            final result = serializer.serializeInlineFragmentWithOffsets(
              block.inlines,
              textOffset: offset,
            );
            expect(result.source, expected);
            expect(result.sourceOffset, offset);
            expect(result.textAtoms, hasLength(expected.length));
            for (var index = 0; index < result.textAtoms.length; index++) {
              final atom = result.textAtoms[index];
              expect((atom.textStart, atom.textEnd), (index, index + 1));
              expect((atom.sourceStart, atom.sourceEnd), (index, index + 1));
              expect(atom.text, expected[index]);
              expect(atom.inlinePath, [0, 0]);
              expect(atom.escaped, isFalse);
            }
          }
        }

        check(controller.document.blocks.first, url);
        expect(controller.markdown, '$url\n\n');
        const edited = '$url/a_b?q=x&next=y#part';
        controller.updateBlockText(id, edited);
        check(controller.document.blocks.first, edited);
        expect(controller.markdown, '$edited\n\n');
        final saved = parser
            .parse(
              filePath: 'topic.md',
              source: controller.markdown,
              mode: mode,
            )
            .busyDocument;
        check(saved.blocks.single, edited);
        final reopened = BusyMarkWysiwygDocumentController(document: saved);
        addTearDown(reopened.dispose);
        reopened.updateBlockText(saved.blocks.single.id, '$edited/new');
        check(reopened.document.blocks.single, '$edited/new');
        expect(reopened.markdown, '$edited/new\n\n');
        // A second Enter is idempotent and preserves the imported source form.
        reopened.applyEnterAt(saved.blocks.single.id, '$edited/new'.length);
        check(reopened.document.blocks.first, '$edited/new');
        expect(reopened.markdown, '$edited/new\n\n');
      }
    },
  );

  test(
    'bare leaf links use raw URL positions and explicit equal-label links retain delimiters',
    () {
      const url = 'https://example.com/a_b?q=x&next=y';
      for (final bare in [false, true]) {
        for (final withChildren in [false, true]) {
          final inlines = [
            BusyInline(
              kind: BusyInlineKind.link,
              text: url,
              destination: url,
              attributes: bare
                  ? const {busyMarkBareUrlAttribute: 'true'}
                  : const {},
              children: withChildren
                  ? const [BusyInline(kind: BusyInlineKind.text, text: url)]
                  : const [],
            ),
          ];
          final expected = bare
              ? url
              : r'[https://example.com/a\_b?q=x\&next=y](https://example.com/a_b?q=x&next=y)';
          final ordinary = serializer.serializeInlineFragment(inlines);
          expect(ordinary, expected);
          for (final offset in [0, 1, 8, url.length]) {
            final result = serializer.serializeInlineFragmentWithOffsets(
              inlines,
              textOffset: offset,
            );
            expect(result.source, ordinary);
            if (bare) {
              expect(result.sourceOffset, offset);
            }
            if (!bare && withChildren && offset == 8) {
              expect(result.sourceOffset, 9);
            }
            expect(result.textAtoms.first.sourceStart, bare ? 0 : 1);
            expect(
              result.textAtoms.last.sourceEnd,
              bare ? url.length : url.length + 3,
            );
            if (bare) {
              expect(result.textAtoms.every((atom) => !atom.escaped), isTrue);
            }
          }
        }
      }
    },
  );

  test('grouped breaks retain distinct source provenance in one traversal', () {
    const first = BusyMarkInlineLineBreakOffset(textOffset: 1);
    const second = BusyMarkInlineLineBreakOffset(textOffset: 2);
    var traversals = 0;
    var visitedNodes = 0;
    debugBusyMarkInlineSerializationTraversal = (_) => traversals += 1;
    debugBusyMarkInlineSerializationVisitedNodes = (value) {
      visitedNodes = value;
    };
    addTearDown(() {
      debugBusyMarkInlineSerializationTraversal = null;
      debugBusyMarkInlineSerializationVisitedNodes = null;
    });

    final result = serializer.serializeInlineFragmentWithOffsets(
      const [
        BusyInline(kind: BusyInlineKind.text, text: 'A'),
        BusyInline(kind: BusyInlineKind.hardBreak, text: '\n'),
        BusyInline(kind: BusyInlineKind.hardBreak, text: '\n'),
        BusyInline(kind: BusyInlineKind.text, text: 'B'),
      ],
      textOffset: 2,
      lineBreakOffsets: const [first, second],
      readableHardBreakRuns: true,
    );

    expect(traversals, 1);
    expect(visitedNodes, 4);
    expect(result.lineBreakSourceOffsets.keys, containsAll([first, second]));
    expect(
      result.lineBreakSourceOffsets[first],
      isNot(result.lineBreakSourceOffsets[second]),
    );
    expect(result.source, 'A\n<br>\n<br>\nB');
  });

  test('text-leaf atoms use interior spans and exclude delimiters', () {
    final result = serializer.serializeInlineFragmentWithOffsets(const [
      BusyInline(
        kind: BusyInlineKind.strong,
        text: 'mispel',
        children: [BusyInline(kind: BusyInlineKind.text, text: 'mispel')],
      ),
      BusyInline(kind: BusyInlineKind.text, text: 'led'),
    ], textOffset: 4);

    expect(result.source, '**mispel**led');
    expect(result.textAtoms.map((atom) => atom.text).join(), 'mispelled');
    expect(
      [
        for (final atom in result.textAtoms)
          result.source.substring(atom.sourceStart, atom.sourceEnd),
      ].join(),
      'mispelled',
    );
    expect(result.textAtoms.first.inlinePath, [0, 0]);
    expect(result.textAtoms.last.inlinePath, [1]);
  });

  test('table escaping translates leaf spans without changing source', () {
    const inlines = [BusyInline(kind: BusyInlineKind.text, text: 'a|b')];
    final ordinary = serializer.serializeInlineFragment(
      inlines,
      tableCell: true,
    );
    final result = serializer.serializeInlineFragmentWithOffsets(
      inlines,
      textOffset: 2,
      tableCell: true,
    );

    expect(result.source, ordinary);
    expect(result.source, r'a\|b');
    final pipe = result.textAtoms.singleWhere((atom) => atom.text == '|');
    expect(result.source.substring(pipe.sourceStart, pipe.sourceEnd), r'\|');
    expect(pipe.escaped, isTrue);
  });
}
