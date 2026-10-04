import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/busymark_markdown_serializer.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_document_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const serializer = BusyMarkMarkdownSerializer();

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
