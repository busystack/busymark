import '../markdown/busymark_document.dart';
import 'spelling_projection.dart';
import 'spelling_text_patterns.dart';

final class SpellingInlineProjection {
  const SpellingInlineProjection({
    required this.text,
    required this.atoms,
    String? tokenizationContext,
    this.tokenizationContextStart = 0,
  }) : _tokenizationContext = tokenizationContext;

  final String text;
  final List<SpellingSourceAtom> atoms;
  final String? _tokenizationContext;
  String get tokenizationContext => _tokenizationContext ?? text;
  final int tokenizationContextStart;
}

final class _PendingInlineProjection {
  const _PendingInlineProjection({
    required this.text,
    required this.atoms,
    required this.tokenizationContextStart,
  });

  final String text;
  final List<SpellingSourceAtom> atoms;
  final int tokenizationContextStart;
}

/// Projects editable rich-text leaves while keeping a stable tree address for
/// every emitted atom. Formatting and link containers are transparent; code,
/// math, variables, and embedded HTML form barriers and are omitted.
List<SpellingInlineProjection> projectSpellingInlineRuns({
  required List<BusyInline> inlines,
  required int sourceBase,
  SpellingSourceContext context = SpellingSourceContext.markdownProse,
  SpellingMappedImageDescription? Function(
    BusyInline image,
    SpellingMappedImageDescription? parent,
  )?
  imageDescriptionFor,
}) {
  final pendingRuns = <_PendingInlineProjection>[];
  var text = StringBuffer();
  final tokenizationContext = StringBuffer();
  int? tokenizationContextStart;
  var atoms = <SpellingSourceAtom>[];
  var fieldOffset = 0;

  void flush() {
    if (text.isNotEmpty && text.toString().trim().isNotEmpty) {
      pendingRuns.add(
        _PendingInlineProjection(
          text: text.toString(),
          atoms: List.unmodifiable(atoms),
          tokenizationContextStart: tokenizationContextStart!,
        ),
      );
    }
    text = StringBuffer();
    atoms = [];
    tokenizationContextStart = null;
  }

  void barrier() {
    flush();
    if (tokenizationContext.isNotEmpty &&
        !tokenizationContext.toString().endsWith(' ')) {
      tokenizationContext.write(' ');
    }
  }

  void emitLeaf(
    BusyInline inline,
    List<int> path, {
    String? logicalText,
    String? tokenizationText,
    SpellingTransformationKind transformation =
        SpellingTransformationKind.identity,
    SpellingSourceContext? sourceContext,
  }) {
    final fieldValue = inline.text;
    if (logicalText == null &&
        (fieldValue.contains('\n') || fieldValue.contains('\r'))) {
      var cursor = 0;
      for (final breakMatch in RegExp(r'\r\n|\r|\n').allMatches(fieldValue)) {
        if (breakMatch.start > cursor) {
          emitLeaf(
            inline.copyWith(
              text: fieldValue.substring(cursor, breakMatch.start),
            ),
            path,
            sourceContext: sourceContext,
          );
        }
        emitLeaf(
          inline.copyWith(text: breakMatch.group(0)!),
          path,
          logicalText: ' ',
          tokenizationText: '\n',
          transformation: SpellingTransformationKind.lineBreak,
          sourceContext: sourceContext,
        );
        cursor = breakMatch.end;
      }
      if (cursor < fieldValue.length) {
        emitLeaf(
          inline.copyWith(text: fieldValue.substring(cursor)),
          path,
          sourceContext: sourceContext,
        );
      }
      return;
    }
    final value = logicalText ?? fieldValue;
    if (value.isEmpty) return;
    tokenizationContextStart ??= tokenizationContext.length;
    final logicalStart = text.length;
    text.write(value);
    tokenizationContext.write(tokenizationText ?? value);
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
        context: sourceContext ?? context,
      ),
    );
    fieldOffset += fieldValue.length;
  }

  void visit(
    BusyInline inline,
    List<int> path, {
    List<int>? imageFieldPath,
    SpellingMappedImageDescription? imageOwner,
  }) {
    if (inline.kind == BusyInlineKind.link &&
        (inline.attributes['id']?.startsWith('fnref-') ?? false) &&
        (inline.destination?.startsWith('#fn-') ?? false)) {
      barrier();
      fieldOffset += inline.plainText.length;
      return;
    }
    switch (inline.kind) {
      case BusyInlineKind.math:
      case BusyInlineKind.html:
      case BusyInlineKind.writersideControl:
      case BusyInlineKind.writersidePath:
      case BusyInlineKind.writersideUiPath:
      case BusyInlineKind.writersideShortcut:
      case BusyInlineKind.writersideVariable:
      case BusyInlineKind.unknown:
        barrier();
        fieldOffset += inline.plainText.length;
        return;
      case BusyInlineKind.code:
        if (imageFieldPath != null) {
          emitLeaf(
            inline,
            imageFieldPath,
            sourceContext: SpellingSourceContext.markdownCodeSpan,
          );
        } else {
          barrier();
          fieldOffset += inline.plainText.length;
        }
        return;
      case BusyInlineKind.image:
        barrier();
        final description = imageDescriptionFor?.call(inline, imageOwner);
        if (description != null) {
          for (final child in description.inlines) {
            visit(
              child,
              path,
              imageFieldPath: imageFieldPath ?? path,
              imageOwner: description,
            );
          }
          barrier();
          return;
        }
        var cursor = 0;
        for (final address in spellingPlainAddress.allMatches(inline.text)) {
          if (address.start > cursor) {
            emitLeaf(
              inline.copyWith(
                text: inline.text.substring(cursor, address.start),
              ),
              imageFieldPath ?? path,
            );
          }
          barrier();
          fieldOffset += address.end - address.start;
          cursor = address.end;
        }
        if (cursor < inline.text.length) {
          emitLeaf(
            inline.copyWith(text: inline.text.substring(cursor)),
            imageFieldPath ?? path,
          );
        }
        barrier();
        return;
      case BusyInlineKind.softBreak:
      case BusyInlineKind.hardBreak:
        emitLeaf(
          inline,
          imageFieldPath ?? path,
          logicalText: ' ',
          tokenizationText: '\n',
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
          var cursor = 0;
          for (final address in spellingPlainAddress.allMatches(inline.text)) {
            if (address.start > cursor) {
              emitLeaf(
                inline.copyWith(
                  text: inline.text.substring(cursor, address.start),
                ),
                imageFieldPath ?? path,
              );
            }
            barrier();
            fieldOffset += address.end - address.start;
            cursor = address.end;
          }
          if (cursor < inline.text.length) {
            emitLeaf(
              inline.copyWith(text: inline.text.substring(cursor)),
              imageFieldPath ?? path,
            );
          }
          return;
        }
        for (final (index, child) in inline.children.indexed) {
          visit(
            child,
            [...path, index],
            imageFieldPath: imageFieldPath,
            imageOwner: imageOwner,
          );
        }
    }
  }

  for (final (index, inline) in inlines.indexed) {
    visit(inline, [index]);
  }
  flush();
  final contextText = tokenizationContext.toString();
  return List.unmodifiable([
    for (final run in pendingRuns)
      SpellingInlineProjection(
        text: run.text,
        atoms: run.atoms,
        tokenizationContext: contextText,
        tokenizationContextStart: run.tokenizationContextStart,
      ),
  ]);
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
