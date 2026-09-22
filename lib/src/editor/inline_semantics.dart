import '../markdown/busymark_document.dart';

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
    kind == BusyInlineKind.strong ||
    kind == BusyInlineKind.emphasis ||
    kind == BusyInlineKind.underline ||
    kind == BusyInlineKind.strikethrough ||
    kind == BusyInlineKind.link;

/// Markdown table cells occupy one physical source line. Normalize every
/// platform newline form at the semantic boundary shared by Editor and Source.
String busyMarkNormalizeTableCellText(String text) {
  return text.replaceAll(RegExp(r'\r\n|\r|\n'), ' ');
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
