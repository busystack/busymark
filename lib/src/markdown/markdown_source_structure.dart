import '../core/source_span.dart';
import 'busymark_document.dart';

class BusyMarkMarkdownTableCellRegion {
  const BusyMarkMarkdownTableCellRegion({
    required this.table,
    required this.cell,
    required this.row,
    required this.column,
    required this.span,
  });

  final BusyBlock table;
  final BusyBlock cell;
  final int row;
  final int column;
  final SourceSpan span;
}

/// Maps modeled Markdown table cells back to their exact source content spans.
/// Pipes escaped with a backslash remain cell content rather than delimiters.
List<BusyMarkMarkdownTableCellRegion> busyMarkMarkdownTableCellRegions({
  required String source,
  required BusyBlock table,
}) {
  final tableSpan = table.sourceSpan;
  if (tableSpan == null ||
      tableSpan.startOffset < 0 ||
      tableSpan.endOffset > source.length) {
    return const [];
  }
  final raw = source.substring(tableSpan.startOffset, tableSpan.endOffset);
  final lines = <({String text, int offset})>[];
  var offset = 0;
  for (final rawLine in raw.split(RegExp('(?<=\n)'))) {
    var text = rawLine;
    if (text.endsWith('\n')) text = text.substring(0, text.length - 1);
    if (text.endsWith('\r')) text = text.substring(0, text.length - 1);
    lines.add((text: text, offset: offset));
    offset += rawLine.length;
  }
  final regions = <BusyMarkMarkdownTableCellRegion>[];
  for (final (rowIndex, row) in table.children.indexed) {
    final lineIndex = rowIndex == 0 ? 0 : rowIndex + 1;
    if (lineIndex >= lines.length) break;
    final line = lines[lineIndex];
    final spans = _markdownTableCellSpans(line.text);
    for (final (column, cell) in row.children.indexed) {
      if (column >= spans.length) break;
      final local = spans[column];
      regions.add(
        BusyMarkMarkdownTableCellRegion(
          table: table,
          cell: cell,
          row: rowIndex,
          column: column,
          span: SourceSpan.fromOffsets(
            filePath: tableSpan.filePath,
            source: source,
            startOffset: tableSpan.startOffset + line.offset + local.start,
            endOffset: tableSpan.startOffset + line.offset + local.end,
          ),
        ),
      );
    }
  }
  return regions;
}

List<({int start, int end})> _markdownTableCellSpans(String line) {
  final delimiters = <int>[];
  var escaped = false;
  for (var index = 0; index < line.length; index++) {
    final codeUnit = line.codeUnitAt(index);
    if (codeUnit == 0x5c && !escaped) {
      escaped = true;
      continue;
    }
    if (codeUnit == 0x7c && !escaped) delimiters.add(index);
    escaped = false;
  }
  final boundaries = <int>[0, ...delimiters, line.length];
  final spans = <({int start, int end})>[];
  for (var index = 0; index < boundaries.length - 1; index++) {
    if (index == 0 && delimiters.isNotEmpty && delimiters.first == 0) {
      continue;
    }
    if (index == boundaries.length - 2 &&
        delimiters.isNotEmpty &&
        delimiters.last == line.length - 1) {
      continue;
    }
    var start = boundaries[index] + (index == 0 ? 0 : 1);
    var end = boundaries[index + 1];
    while (start < end && _horizontalWhitespace(line.codeUnitAt(start))) {
      start++;
    }
    while (end > start && _horizontalWhitespace(line.codeUnitAt(end - 1))) {
      end--;
    }
    spans.add((start: start, end: end));
  }
  return spans;
}

bool _horizontalWhitespace(int codeUnit) =>
    codeUnit == 0x20 || codeUnit == 0x09;
