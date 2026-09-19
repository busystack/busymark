import 'package:busymark/src/markdown/markdown_source_structure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
}
