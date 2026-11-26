import '../markdown/busymark_document.dart';
import 'text_edit_offsets.dart';

/// Whether two inline wrappers carry the same semantic context independently
/// of their child content.
bool busyMarkSameInlineSemantics(BusyInline left, BusyInline right) =>
    left.kind == right.kind &&
    left.destination == right.destination &&
    left.attributes.length == right.attributes.length &&
    left.attributes.entries.every(
      (entry) => right.attributes[entry.key] == entry.value,
    );

bool busyMarkIsInheritedInlineContext(BusyInlineKind kind) =>
    busyMarkIsSemanticInline(kind) ||
    kind == BusyInlineKind.writersideVariable ||
    kind == BusyInlineKind.strong ||
    kind == BusyInlineKind.emphasis ||
    kind == BusyInlineKind.underline ||
    kind == BusyInlineKind.strikethrough ||
    kind == BusyInlineKind.link;

final _tableCellLineEnding = RegExp(r'\r\n|\r|\n');

/// A cell can contain existing semantic breaks (serialized as HTML). New
/// platform line endings are normalized to spaces inside the edited cell.
Iterable<Match> busyMarkNewTableCellLineBreaks(
  String text, {
  String previousText = '',
}) {
  final existing = [
    for (final match in _tableCellLineEnding.allMatches(previousText))
      match.start,
  ];
  final retained =
      busyMarkMapUnchangedTextOffsets(previousText, text, existing)?.toSet() ??
      const <int>{};
  return _tableCellLineEnding
      .allMatches(text)
      .where((match) => !retained.contains(match.start));
}

String busyMarkNormalizeTableCellText(String text, {String previousText = ''}) {
  final result = StringBuffer();
  var start = 0;
  for (final match in busyMarkNewTableCellLineBreaks(
    text,
    previousText: previousText,
  )) {
    result.write(text.substring(start, match.start));
    result.write(' ');
    start = match.end;
  }
  return start == 0 ? text : (result..write(text.substring(start))).toString();
}

/// Flattens clipboard blocks into the one inline stream accepted by a table
/// cell while retaining supported inline styles.
List<BusyInline> busyMarkTableCellInlinesFromBlocks(
  Iterable<BusyBlock> blocks,
) {
  BusyInline normalize(BusyInline inline) =>
      inline.kind == BusyInlineKind.hardBreak ||
          inline.kind == BusyInlineKind.softBreak
      ? const BusyInline(kind: BusyInlineKind.text, text: ' ')
      : inline.copyWith(
          text: busyMarkNormalizeTableCellText(inline.text),
          children: [for (final child in inline.children) normalize(child)],
        );
  final inlines = <BusyInline>[];
  void append(BusyBlock block) {
    if (inlines.isNotEmpty) {
      inlines.add(const BusyInline(kind: BusyInlineKind.text, text: ' '));
    }
    inlines.addAll(block.inlines.map(normalize));
    for (final child in block.children) {
      append(child);
    }
  }

  for (final block in blocks) {
    append(block);
  }
  return inlines;
}
