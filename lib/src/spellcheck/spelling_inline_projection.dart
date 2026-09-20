import '../markdown/busymark_document.dart';
import 'spelling_projection.dart';

final class SpellingInlineProjection {
  const SpellingInlineProjection({required this.text, required this.atoms});

  final String text;
  final List<SpellingSourceAtom> atoms;
}

/// Projects editable rich-text leaves while keeping a stable tree address for
/// every emitted atom. Formatting and link containers are transparent; code,
/// math, variables, and embedded HTML form barriers and are omitted.
List<SpellingInlineProjection> projectSpellingInlineRuns({
  required List<BusyInline> inlines,
  required int sourceBase,
  SpellingSourceContext context = SpellingSourceContext.markdownProse,
}) {
  final runs = <SpellingInlineProjection>[];
  var text = StringBuffer();
  var atoms = <SpellingSourceAtom>[];
  var fieldOffset = 0;

  void flush() {
    if (text.isNotEmpty && text.toString().trim().isNotEmpty) {
      runs.add(
        SpellingInlineProjection(
          text: text.toString(),
          atoms: List.unmodifiable(atoms),
        ),
      );
    }
    text = StringBuffer();
    atoms = [];
  }

  void emitLeaf(
    BusyInline inline,
    List<int> path, {
    String? logicalText,
    SpellingTransformationKind transformation =
        SpellingTransformationKind.identity,
  }) {
    final fieldValue = inline.text;
    final value = logicalText ?? fieldValue;
    if (value.isEmpty) return;
    final logicalStart = text.length;
    text.write(value);
    atoms.add(
      SpellingSourceAtom(
        logicalText: value,
        logicalStart: logicalStart,
        logicalEnd: text.length,
        // Current-source locations are added from serializer metadata. A
        // negative interval cannot be mistaken for a source offset meanwhile.
        sourceStart: sourceBase < 0 ? -1 : sourceBase + fieldOffset,
        sourceEnd: sourceBase < 0
            ? -1
            : sourceBase + fieldOffset + fieldValue.length,
        fieldStart: fieldOffset,
        fieldEnd: fieldOffset + fieldValue.length,
        richLeafPath: List.unmodifiable(path),
        transformation: transformation,
        context: context,
      ),
    );
    fieldOffset += fieldValue.length;
  }

  void visit(BusyInline inline, List<int> path) {
    switch (inline.kind) {
      case BusyInlineKind.math:
      case BusyInlineKind.code:
      case BusyInlineKind.html:
      case BusyInlineKind.writersideVariable:
      case BusyInlineKind.unknown:
        flush();
        fieldOffset += inline.plainText.length;
        return;
      case BusyInlineKind.image:
        flush();
        emitLeaf(inline, path);
        flush();
        return;
      case BusyInlineKind.softBreak:
      case BusyInlineKind.hardBreak:
        emitLeaf(
          inline,
          path,
          logicalText: ' ',
          transformation: SpellingTransformationKind.lineBreak,
        );
        return;
      case BusyInlineKind.text:
      case BusyInlineKind.strong:
      case BusyInlineKind.emphasis:
      case BusyInlineKind.underline:
      case BusyInlineKind.strikethrough:
      case BusyInlineKind.link:
        if (inline.children.isEmpty) {
          emitLeaf(inline, path);
          return;
        }
        for (final (index, child) in inline.children.indexed) {
          visit(child, [...path, index]);
        }
    }
  }

  for (final (index, inline) in inlines.indexed) {
    visit(inline, [index]);
  }
  flush();
  return List.unmodifiable(runs);
}

SpellingInlineProjection projectSpellingInlines({
  required List<BusyInline> inlines,
  required int sourceBase,
  SpellingSourceContext context = SpellingSourceContext.markdownProse,
}) {
  final runs = projectSpellingInlineRuns(
    inlines: inlines,
    sourceBase: sourceBase,
    context: context,
  );
  if (runs.isEmpty) {
    return const SpellingInlineProjection(text: '', atoms: []);
  }
  if (runs.length == 1) return runs.single;
  final text = StringBuffer();
  final atoms = <SpellingSourceAtom>[];
  for (final run in runs) {
    if (text.isNotEmpty) text.write(' ');
    final base = text.length;
    text.write(run.text);
    for (final atom in run.atoms) {
      atoms.add(
        SpellingSourceAtom(
          logicalText: atom.logicalText,
          logicalStart: base + atom.logicalStart,
          logicalEnd: base + atom.logicalEnd,
          sourceStart: atom.sourceStart,
          sourceEnd: atom.sourceEnd,
          fieldStart: atom.fieldStart,
          fieldEnd: atom.fieldEnd,
          richLeafPath: atom.richLeafPath,
          transformation: atom.transformation,
          context: atom.context,
        ),
      );
    }
  }
  return SpellingInlineProjection(text: text.toString(), atoms: atoms);
}
