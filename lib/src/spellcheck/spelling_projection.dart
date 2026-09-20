import '../workspace/workspace_model.dart';

enum SpellingTransformationKind {
  identity,
  markdownEscape,
  entity,
  lineBreak,
  xmlCdata,
  serializerEscape,
}

enum SpellingSourceContext {
  markdownProse,
  markdownTableCell,
  markdownSingleQuotedTitle,
  markdownDoubleQuotedTitle,
  xmlText,
  xmlSingleQuotedAttribute,
  xmlDoubleQuotedAttribute,
  xmlCdata,
}

/// Identifies the exact document version against which a projection was made.
final class SpellingSnapshotIdentity {
  const SpellingSnapshotIdentity({
    required this.bufferId,
    required this.contentRevision,
    required this.documentKind,
    required this.contextGeneration,
  });

  final String bufferId;
  final int contentRevision;
  final DocumentKind documentKind;
  final int contextGeneration;

  @override
  bool operator ==(Object other) =>
      other is SpellingSnapshotIdentity &&
      other.bufferId == bufferId &&
      other.contentRevision == contentRevision &&
      other.documentKind == documentKind &&
      other.contextGeneration == contextGeneration;

  @override
  int get hashCode =>
      Object.hash(bufferId, contentRevision, documentKind, contextGeneration);
}

sealed class SpellingEditorTarget {
  const SpellingEditorTarget();
}

final class SpellingSourceTarget extends SpellingEditorTarget {
  const SpellingSourceTarget({required this.filePath});

  final String filePath;
}

final class SpellingRichBlockTarget extends SpellingEditorTarget {
  const SpellingRichBlockTarget({
    required this.blockId,
    required this.documentGeneration,
  });

  final String blockId;
  final int documentGeneration;
}

final class SpellingRichTableCellTarget extends SpellingEditorTarget {
  const SpellingRichTableCellTarget({
    required this.tableBlockId,
    required this.cellId,
    required this.documentGeneration,
  });

  final String tableBlockId;
  final String cellId;
  final int documentGeneration;
}

/// One indivisible authored representation of logical prose.
///
/// A Markdown entity, for example, is represented by a single atom whose
/// source interval can be longer than its logical text. Replacement planning
/// therefore never overwrites part of an encoded atom.
final class SpellingSourceAtom {
  const SpellingSourceAtom({
    required this.logicalText,
    required this.logicalStart,
    required this.logicalEnd,
    required this.sourceStart,
    required this.sourceEnd,
    required this.transformation,
    required this.context,
    this.fieldStart,
    this.fieldEnd,
    this.richLeafPath,
  });

  final String logicalText;
  final int logicalStart;
  final int logicalEnd;
  final int sourceStart;
  final int sourceEnd;
  final int? fieldStart;
  final int? fieldEnd;
  final List<int>? richLeafPath;
  final SpellingTransformationKind transformation;
  final SpellingSourceContext context;

  bool intersectsLogical(int start, int end) =>
      logicalStart < end && logicalEnd > start;
}

final class SpellingProseRun {
  const SpellingProseRun({
    required this.id,
    required this.text,
    required this.languageId,
    required this.atoms,
    required this.target,
    required this.snapshot,
    this.complete = true,
  });

  final String id;
  final String text;
  final String languageId;
  final List<SpellingSourceAtom> atoms;
  final SpellingEditorTarget target;
  final SpellingSnapshotIdentity snapshot;
  final bool complete;

  bool get hasValidMapping {
    if (atoms.isEmpty) return text.isEmpty;
    final reconstructed = StringBuffer();
    var offset = 0;
    for (final atom in atoms) {
      if (atom.logicalStart != offset || atom.logicalEnd < atom.logicalStart) {
        return false;
      }
      reconstructed.write(atom.logicalText);
      offset = atom.logicalEnd;
    }
    return offset == text.length && reconstructed.toString() == text;
  }
}

enum SpellingCheckOutcome { accepted, rejected, unchecked }

final class SpellingOccurrence {
  const SpellingOccurrence({
    required this.id,
    required this.run,
    required this.logicalStart,
    required this.logicalEnd,
    required this.word,
    required this.outcome,
    this.error,
  });

  final String id;
  final SpellingProseRun run;
  final int logicalStart;
  final int logicalEnd;
  final String word;
  final SpellingCheckOutcome outcome;
  final String? error;

  Iterable<SpellingSourceAtom> get atoms => run.atoms.where(
    (atom) => atom.intersectsLogical(logicalStart, logicalEnd),
  );

  int? get sourceStart {
    final offsets = atoms
        .where((atom) => atom.sourceStart >= 0 && atom.sourceEnd >= 0)
        .map((atom) => atom.sourceStart);
    return offsets.isEmpty ? null : offsets.reduce((a, b) => a < b ? a : b);
  }

  int? get sourceEnd {
    final offsets = atoms
        .where((atom) => atom.sourceStart >= 0 && atom.sourceEnd >= 0)
        .map((atom) => atom.sourceEnd);
    return offsets.isEmpty ? null : offsets.reduce((a, b) => a > b ? a : b);
  }

  int? get fieldStart {
    final offsets = atoms.map((atom) => atom.fieldStart).whereType<int>();
    return offsets.isEmpty ? null : offsets.reduce((a, b) => a < b ? a : b);
  }

  int? get fieldEnd {
    final offsets = atoms.map((atom) => atom.fieldEnd).whereType<int>();
    return offsets.isEmpty ? null : offsets.reduce((a, b) => a > b ? a : b);
  }
}

final class SpellingProjectionResult {
  const SpellingProjectionResult({
    required this.runs,
    required this.complete,
    this.message,
  });

  final List<SpellingProseRun> runs;
  final bool complete;
  final String? message;
}
