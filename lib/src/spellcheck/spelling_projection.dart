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

  /// Maps a logical subrange through this atom without widening a linear
  /// representation (plain text and CDATA) to the complete atom. Encoded
  /// units remain indivisible because replacing only part of an entity or an
  /// escape would corrupt its authored representation.
  SpellingMappedInterval? sourceIntervalFor(int start, int end) =>
      _mappedIntervalFor(
        start,
        end,
        mappedStart: sourceStart,
        mappedEnd: sourceEnd,
      );

  SpellingMappedInterval? fieldIntervalFor(int start, int end) {
    final startOffset = fieldStart;
    final endOffset = fieldEnd;
    if (startOffset == null || endOffset == null) return null;
    return _mappedIntervalFor(
      start,
      end,
      mappedStart: startOffset,
      mappedEnd: endOffset,
    );
  }

  SpellingMappedInterval? _mappedIntervalFor(
    int start,
    int end, {
    required int mappedStart,
    required int mappedEnd,
  }) {
    if (mappedStart < 0 || mappedEnd < mappedStart) return null;
    final overlapStart = start > logicalStart ? start : logicalStart;
    final overlapEnd = end < logicalEnd ? end : logicalEnd;
    if (overlapEnd <= overlapStart) return null;
    final linear = switch (transformation) {
      SpellingTransformationKind.identity ||
      SpellingTransformationKind.xmlCdata =>
        mappedEnd - mappedStart == logicalEnd - logicalStart,
      _ => false,
    };
    return SpellingMappedInterval(
      start: linear ? mappedStart + overlapStart - logicalStart : mappedStart,
      end: linear ? mappedStart + overlapEnd - logicalStart : mappedEnd,
    );
  }
}

final class SpellingMappedInterval {
  const SpellingMappedInterval({required this.start, required this.end});

  final int start;
  final int end;

  bool contains(int offset) => offset >= start && offset < end;
}

/// Authored delimiters surrounding a formatted logical interval.
///
/// These intervals let an exact source correction remove an emphasis-like
/// container when deleting its complete contents. They are deliberately kept
/// separate from text atoms: delimiters produce no logical characters.
final class SpellingFormattingWrapper {
  const SpellingFormattingWrapper({
    required this.logicalStart,
    required this.logicalEnd,
    required this.openingStart,
    required this.openingEnd,
    required this.closingStart,
    required this.closingEnd,
    this.removableWhenLogicallyEmpty = true,
    this.fieldOpeningStart,
    this.fieldOpeningEnd,
    this.fieldClosingStart,
    this.fieldClosingEnd,
    this.structuralKind,
  });

  final int logicalStart;
  final int logicalEnd;
  final int openingStart;
  final int openingEnd;
  final int closingStart;
  final int closingEnd;
  final bool removableWhenLogicallyEmpty;
  final int? fieldOpeningStart;
  final int? fieldOpeningEnd;
  final int? fieldClosingStart;
  final int? fieldClosingEnd;
  final String? structuralKind;
}

final class SpellingProseRun {
  const SpellingProseRun({
    required this.id,
    required this.text,
    required this.languageId,
    required this.atoms,
    required this.target,
    required this.snapshot,
    this.formattingWrappers = const [],
    this.complete = true,
    String? tokenizationContext,
    this.tokenizationContextStart = 0,
  }) : _tokenizationContext = tokenizationContext;

  final String id;
  final String text;
  final String languageId;
  final List<SpellingSourceAtom> atoms;
  final SpellingEditorTarget target;
  final SpellingSnapshotIdentity snapshot;
  final List<SpellingFormattingWrapper> formattingWrappers;
  final bool complete;
  final String? _tokenizationContext;

  /// Semantic prose surrounding [text], used only to classify token edges.
  /// Context-only characters never participate in source replacement.
  String get tokenizationContext => _tokenizationContext ?? text;

  /// UTF-16 interval occupied by [text] inside [tokenizationContext].
  final int tokenizationContextStart;
  int get tokenizationContextEnd => tokenizationContextStart + text.length;

  bool get hasValidMapping {
    if (tokenizationContextStart < 0 ||
        tokenizationContextEnd > tokenizationContext.length ||
        !_sameTokenizationCore(
          tokenizationContext.substring(
            tokenizationContextStart,
            tokenizationContextEnd,
          ),
          text,
        )) {
      return false;
    }
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

bool _sameTokenizationCore(String context, String text) {
  if (context.length != text.length) return false;
  for (var index = 0; index < text.length; index++) {
    final contextUnit = context.codeUnitAt(index);
    final textUnit = text.codeUnitAt(index);
    if (contextUnit == textUnit) continue;
    if ((contextUnit == 0x0a || contextUnit == 0x0d) && textUnit == 0x20) {
      continue;
    }
    return false;
  }
  return true;
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

  List<SpellingMappedInterval> get sourceIntervals => _coalesceIntervals([
    for (final atom in atoms)
      if (atom.sourceIntervalFor(logicalStart, logicalEnd) case final range?)
        range,
  ]);

  List<SpellingMappedInterval> get fieldIntervals => _coalesceIntervals([
    for (final atom in atoms)
      if (atom.fieldIntervalFor(logicalStart, logicalEnd) case final range?)
        range,
  ]);

  int? get sourceStart {
    final offsets = sourceIntervals.map((range) => range.start);
    return offsets.isEmpty ? null : offsets.reduce((a, b) => a < b ? a : b);
  }

  int? get sourceEnd {
    final offsets = sourceIntervals.map((range) => range.end);
    return offsets.isEmpty ? null : offsets.reduce((a, b) => a > b ? a : b);
  }

  int? get fieldStart {
    final offsets = fieldIntervals.map((range) => range.start);
    return offsets.isEmpty ? null : offsets.reduce((a, b) => a < b ? a : b);
  }

  int? get fieldEnd {
    final offsets = fieldIntervals.map((range) => range.end);
    return offsets.isEmpty ? null : offsets.reduce((a, b) => a > b ? a : b);
  }
}

List<SpellingMappedInterval> _coalesceIntervals(
  List<SpellingMappedInterval> intervals,
) {
  if (intervals.length < 2) return List.unmodifiable(intervals);
  intervals.sort((left, right) => left.start.compareTo(right.start));
  final result = <SpellingMappedInterval>[];
  for (final interval in intervals) {
    final previous = result.lastOrNull;
    if (previous != null && interval.start <= previous.end) {
      result[result.length - 1] = SpellingMappedInterval(
        start: previous.start,
        end: interval.end > previous.end ? interval.end : previous.end,
      );
    } else {
      result.add(interval);
    }
  }
  return List.unmodifiable(result);
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
