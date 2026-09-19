import 'package:busymark/src/markdown/markdown_source_structure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('source line bounds treat offsets as insertion positions', () {
    void expectBounds(String source, int offset, int start, int end) {
      final bounds = busyMarkSourceLineBounds(source, offset);
      expect(
        (bounds.start, bounds.end),
        (start, end),
        reason: '$offset:$source',
      );
    }

    expectBounds('', 0, 0, 0);
    expectBounds('\nright', 0, 0, 0);
    expectBounds('\nright', 1, 1, 6);
    expectBounds('left\nright', 4, 0, 4);
    expectBounds('left\nright', 5, 5, 10);
    expectBounds('right', 5, 0, 5);
    expectBounds('right\n', 6, 6, 6);
    expectBounds('\r\nright', 0, 0, 1);
    expectBounds('\r\nright', 2, 2, 7);
  });

  test('table cell spans respect meaningful outer pipes and escaping', () {
    List<String> cells(String row) => [
      for (final span in busyMarkMarkdownTableCellSpans(row))
        row.substring(span.start, span.end),
    ];

    expect(cells('  | cell |'), ['cell']);
    expect(cells(' \t | cell |  '), ['cell']);
    expect(cells('| | value |'), ['', 'value']);
    expect(cells('||'), ['']);
    expect(cells(r'| left\|right | next |'), [r'left\|right', 'next']);
  });

  test('escaped terminal pipes remain in the final cell source span', () {
    void expectSpans(
      String row,
      List<({int start, int end, String text})> expected,
    ) {
      final spans = busyMarkMarkdownTableCellSpans(row);
      expect(
        [
          for (final span in spans)
            (
              start: span.start,
              end: span.end,
              text: row.substring(span.start, span.end),
            ),
        ],
        expected,
        reason: row,
      );
    }

    expectSpans(r'A | B\|', [
      (start: 0, end: 1, text: 'A'),
      (start: 4, end: 7, text: r'B\|'),
    ]);
    expectSpans(r'| B\|', [(start: 2, end: 5, text: r'B\|')]);
    expectSpans(r'| B\|  ', [(start: 2, end: 5, text: r'B\|')]);
    expectSpans(r'| B\| |', [(start: 2, end: 5, text: r'B\|')]);
    expectSpans(r'  | B\|', [(start: 4, end: 7, text: r'B\|')]);

    // Odd backslash runs escape the pipe. Even runs leave it as a delimiter.
    expectSpans(r'A | B\\\|', [
      (start: 0, end: 1, text: 'A'),
      (start: 4, end: 9, text: r'B\\\|'),
    ]);
    expectSpans(r'A | B\\|', [
      (start: 0, end: 1, text: 'A'),
      (start: 4, end: 7, text: r'B\\'),
    ]);

    expectSpans('| A | B |', [
      (start: 2, end: 3, text: 'A'),
      (start: 6, end: 7, text: 'B'),
    ]);
    expectSpans('A | B', [
      (start: 0, end: 1, text: 'A'),
      (start: 4, end: 5, text: 'B'),
    ]);
    expectSpans('| |', [(start: 2, end: 2, text: '')]);
  });
}
