import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/busymark_markdown_serializer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const serializer = BusyMarkMarkdownSerializer();

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
