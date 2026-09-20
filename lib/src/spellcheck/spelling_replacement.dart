import 'package:characters/characters.dart';
import 'package:unorm_dart/unorm_dart.dart' as unicode;

import '../markdown/markdown_model.dart';
import '../workspace/workspace_model.dart';
import 'markdown_spelling_projection.dart';
import 'spelling_projection.dart';
import 'writerside_spelling_projection.dart';

final class SpellingSourceEdit {
  const SpellingSourceEdit({
    required this.start,
    required this.end,
    required this.replacement,
  });

  final int start;
  final int end;
  final String replacement;
}

final class SpellingRichLeafEdit {
  const SpellingRichLeafEdit({
    required this.path,
    required this.start,
    required this.end,
    required this.replacement,
  });

  final List<int> path;
  final int start;
  final int end;
  final String replacement;
}

final class SpellingFieldEdit {
  const SpellingFieldEdit({
    required this.start,
    required this.end,
    required this.replacement,
  });

  final int start;
  final int end;
  final String replacement;
}

final class SpellingReplacementPlan {
  const SpellingReplacementPlan({
    required this.originalWord,
    required this.suggestion,
    required this.sourceEdits,
    required this.richLeafEdits,
    required this.fieldEdits,
    required this.snapshot,
    required this.languageId,
    this.sourceTargetStart,
    this.sourceTargetEnd,
  });

  final String originalWord;
  final String suggestion;
  final List<SpellingSourceEdit> sourceEdits;
  final List<SpellingRichLeafEdit> richLeafEdits;
  final List<SpellingFieldEdit> fieldEdits;
  final SpellingSnapshotIdentity snapshot;
  final String languageId;
  final int? sourceTargetStart;
  final int? sourceTargetEnd;

  String applyToSource(String source) {
    var result = source;
    final edits = [...sourceEdits]
      ..sort((left, right) => right.start.compareTo(left.start));
    for (final edit in edits) {
      if (edit.start < 0 || edit.end < edit.start || edit.end > result.length) {
        throw StateError('Spelling source edit is outside the guarded source.');
      }
      result = result.replaceRange(edit.start, edit.end, edit.replacement);
    }
    if (!_sourceResultMatches(result)) {
      throw StateError(
        'The spelling correction did not preserve the projected source '
        'structure.',
      );
    }
    return result;
  }

  bool _sourceResultMatches(String source) {
    final originalStart = sourceTargetStart;
    final originalEnd = sourceTargetEnd;
    if (originalStart == null || originalEnd == null) return true;
    final start = _translateSourceBoundary(originalStart, sourceEdits);
    final end = _translateSourceBoundary(originalEnd, sourceEdits);
    if (start < 0 || end < start || end > source.length) return false;
    final region = _correctionValidationRegion(
      source,
      start,
      end,
      snapshot.documentKind,
    );
    final validationSource = source.substring(region.start, region.end);
    final localStart = start - region.start;
    final localEnd = end - region.start;
    final projection = switch (snapshot.documentKind) {
      DocumentKind.writersideXmlTopic =>
        const WritersideXmlSpellingProjector().project(
          filePath: 'spelling-validation.topic',
          source: validationSource,
          languageId: languageId,
          snapshot: snapshot,
        ),
      DocumentKind.markdown || DocumentKind.writersideMarkdownTopic =>
        const MarkdownSpellingProjector().project(
          filePath: 'spelling-validation.md',
          source: validationSource,
          mode: snapshot.documentKind == DocumentKind.writersideMarkdownTopic
              ? MarkdownMode.writersideMarkdown
              : MarkdownMode.commonMark,
          languageId: languageId,
          snapshot: snapshot,
        ),
      _ => null,
    };
    if (projection == null) return true;
    for (final run in projection.runs) {
      var logicalStart = 0;
      while (logicalStart <= run.text.length - suggestion.length) {
        final found = run.text.indexOf(suggestion, logicalStart);
        if (found < 0) break;
        final candidate = SpellingOccurrence(
          id: 'validation',
          run: run,
          logicalStart: found,
          logicalEnd: found + suggestion.length,
          word: suggestion,
          outcome: SpellingCheckOutcome.rejected,
        );
        final intervals = candidate.sourceIntervals;
        final trailingGap = intervals.isEmpty || intervals.last.end > localEnd
            ? ''
            : source.substring(intervals.last.end, localEnd);
        final markdownWrapperGap =
            snapshot.documentKind != DocumentKind.writersideXmlTopic &&
            intervals.isNotEmpty &&
            intervals.last.end < localEnd &&
            RegExp(r'^[*_~]+$').hasMatch(trailingGap);
        if (intervals.isNotEmpty &&
            intervals.first.start == localStart &&
            (intervals.last.end == localEnd || markdownWrapperGap)) {
          return true;
        }
        logicalStart = found + 1;
      }
    }
    return false;
  }

  /// Translates the end of the final source edit into the resulting source.
  ///
  /// This is intentionally based on encoded replacements rather than the
  /// Unicode length of [suggestion]: Markdown/XML escaping may make those
  /// lengths different.
  int? get resultingSourceCaret => _resultingCaretForSourceEdits(sourceEdits);

  /// Translates the end of the final editable-field edit into the resulting
  /// field. This is used by Markdown-source fields containing inline math.
  int? get resultingFieldCaret => _resultingCaretForFieldEdits(fieldEdits);
}

({int start, int end}) _correctionValidationRegion(
  String source,
  int targetStart,
  int targetEnd,
  DocumentKind kind,
) {
  var start = targetStart;
  var end = targetEnd;
  if (kind == DocumentKind.markdown ||
      kind == DocumentKind.writersideMarkdownTopic) {
    final before = source.lastIndexOf('\n\n', targetStart);
    start = before < 0 ? 0 : before + 2;
    final after = source.indexOf('\n\n', targetEnd);
    end = after < 0 ? source.length : after;
  } else {
    // An arbitrary XML line is not necessarily a parseable fragment: its
    // owning element may begin or end on another line. Keep full-document XML
    // validation until an element-boundary extractor can prove a smaller
    // region is self-contained.
    start = 0;
    end = source.length;
  }
  return (start: start, end: end);
}

int? _resultingCaretForSourceEdits(List<SpellingSourceEdit> edits) {
  if (edits.isEmpty) return null;
  final sorted = [...edits]
    ..sort((left, right) => left.start.compareTo(right.start));
  var delta = 0;
  var caret = 0;
  for (final edit in sorted) {
    caret = edit.start + delta + edit.replacement.length;
    delta += edit.replacement.length - (edit.end - edit.start);
  }
  return caret;
}

int? _resultingCaretForFieldEdits(List<SpellingFieldEdit> edits) {
  if (edits.isEmpty) return null;
  final sorted = [...edits]
    ..sort((left, right) => left.start.compareTo(right.start));
  var delta = 0;
  var caret = 0;
  for (final edit in sorted) {
    caret = edit.start + delta + edit.replacement.length;
    delta += edit.replacement.length - (edit.end - edit.start);
  }
  return caret;
}

final class SpellingReplacementPlanner {
  const SpellingReplacementPlanner();

  SpellingReplacementPlan build({
    required SpellingOccurrence occurrence,
    required String suggestion,
  }) {
    if (occurrence.outcome != SpellingCheckOutcome.rejected) {
      throw StateError('Only a verified rejected occurrence can be replaced.');
    }
    final atoms = occurrence.atoms.toList(growable: false);
    if (atoms.isEmpty || suggestion.isEmpty) {
      throw StateError('The correction target is not replaceable.');
    }
    if (occurrence.run.text.substring(
          occurrence.logicalStart,
          occurrence.logicalEnd,
        ) !=
        occurrence.word) {
      throw StateError('The correction word no longer matches its projection.');
    }

    final originalClusters = _clusters(occurrence.word);
    final suggestionClusters = _clusters(suggestion);
    if (originalClusters.isEmpty) {
      throw StateError('An empty occurrence cannot be corrected.');
    }
    final ownership = <int>[];
    for (final cluster in originalClusters) {
      final globalOffset = occurrence.logicalStart + cluster.start;
      final owner = atoms.indexWhere(
        (atom) =>
            atom.logicalStart <= globalOffset && atom.logicalEnd > globalOffset,
      );
      if (owner < 0) {
        throw StateError('A grapheme has no mapped authored-source atom.');
      }
      ownership.add(owner);
    }
    final aligned = _align(originalClusters, suggestionClusters);
    final assigned = <int, StringBuffer>{};
    var previousOriginal = -1;
    for (final operation in aligned) {
      switch (operation.kind) {
        case _AlignmentKind.equal:
        case _AlignmentKind.substitute:
          final originalIndex = operation.originalIndex!;
          final owner = ownership[originalIndex];
          assigned
              .putIfAbsent(owner, StringBuffer.new)
              .write(
                operation.kind == _AlignmentKind.equal
                    ? originalClusters[originalIndex].text
                    : suggestionClusters[operation.suggestionIndex!].text,
              );
          previousOriginal = originalIndex;
        case _AlignmentKind.delete:
          previousOriginal = operation.originalIndex!;
        case _AlignmentKind.insert:
          final nextOriginal = operation.originalIndex;
          final ownerIndex = previousOriginal >= 0
              ? previousOriginal
              : (nextOriginal ?? 0).clamp(0, ownership.length - 1);
          assigned
              .putIfAbsent(ownership[ownerIndex], StringBuffer.new)
              .write(suggestionClusters[operation.suggestionIndex!].text);
      }
    }

    final sourceEdits = <SpellingSourceEdit>[];
    final fieldEdits = <SpellingFieldEdit>[];
    final richGroups = <String, _RichEditAccumulator>{};
    for (final (index, atom) in atoms.indexed) {
      final overlapStart = occurrence.logicalStart > atom.logicalStart
          ? occurrence.logicalStart
          : atom.logicalStart;
      final overlapEnd = occurrence.logicalEnd < atom.logicalEnd
          ? occurrence.logicalEnd
          : atom.logicalEnd;
      if (overlapEnd <= overlapStart) continue;
      final localStart = overlapStart - atom.logicalStart;
      final localEnd = overlapEnd - atom.logicalStart;
      final replacement = assigned[index]?.toString() ?? '';

      if (atom.sourceStart >= 0) {
        final mapped = atom.sourceIntervalFor(overlapStart, overlapEnd);
        final linearAtom = switch (atom.transformation) {
          SpellingTransformationKind.identity ||
          SpellingTransformationKind.xmlCdata =>
            atom.sourceEnd - atom.sourceStart == atom.logicalText.length,
          _ => false,
        };
        if (linearAtom) {
          sourceEdits.add(
            SpellingSourceEdit(
              start: mapped!.start,
              end: mapped.end,
              replacement: _encode(replacement, atom.context),
            ),
          );
        } else {
          final rebuilt =
              atom.logicalText.substring(0, localStart) +
              replacement +
              atom.logicalText.substring(localEnd);
          sourceEdits.add(
            SpellingSourceEdit(
              start: atom.sourceStart,
              end: atom.sourceEnd,
              replacement: _encode(rebuilt, atom.context),
            ),
          );
        }
      }

      final path = atom.richLeafPath;
      final fieldStart = atom.fieldStart;
      final fieldEnd = atom.fieldEnd;
      if (path != null && fieldStart != null && fieldEnd != null) {
        final key = path.join('.');
        final accumulator = richGroups.putIfAbsent(
          key,
          () => _RichEditAccumulator(path),
        );
        accumulator.add(
          start: fieldStart + localStart,
          end: fieldStart + localEnd,
          replacement: replacement,
        );
      } else if (fieldStart != null && fieldEnd != null) {
        final mapped = atom.fieldIntervalFor(overlapStart, overlapEnd);
        final linearAtom = switch (atom.transformation) {
          SpellingTransformationKind.identity ||
          SpellingTransformationKind.xmlCdata =>
            fieldEnd - fieldStart == atom.logicalText.length,
          _ => false,
        };
        if (linearAtom) {
          fieldEdits.add(
            SpellingFieldEdit(
              start: mapped!.start,
              end: mapped.end,
              replacement: _encode(replacement, atom.context),
            ),
          );
        } else {
          final rebuilt =
              atom.logicalText.substring(0, localStart) +
              replacement +
              atom.logicalText.substring(localEnd);
          fieldEdits.add(
            SpellingFieldEdit(
              start: fieldStart,
              end: fieldEnd,
              replacement: _encode(rebuilt, atom.context),
            ),
          );
        }
      }
    }
    for (final wrapper in occurrence.run.formattingWrappers) {
      if (!wrapper.removableWhenLogicallyEmpty) continue;
      if (occurrence.logicalStart > wrapper.logicalStart ||
          occurrence.logicalEnd < wrapper.logicalEnd) {
        continue;
      }
      final ownedAtomIndexes = <int>[
        for (final (index, atom) in atoms.indexed)
          if (atom.logicalStart >= wrapper.logicalStart &&
              atom.logicalEnd <= wrapper.logicalEnd)
            index,
      ];
      if (ownedAtomIndexes.isEmpty) continue;
      final remaining = StringBuffer();
      for (final index in ownedAtomIndexes) {
        remaining.write(assigned[index] ?? '');
      }
      if (remaining.isNotEmpty) continue;
      if (wrapper.openingStart >= 0 && wrapper.closingStart >= 0) {
        sourceEdits
          ..add(
            SpellingSourceEdit(
              start: wrapper.openingStart,
              end: wrapper.openingEnd,
              replacement: '',
            ),
          )
          ..add(
            SpellingSourceEdit(
              start: wrapper.closingStart,
              end: wrapper.closingEnd,
              replacement: '',
            ),
          );
      }
      final fieldOpeningStart = wrapper.fieldOpeningStart;
      final fieldOpeningEnd = wrapper.fieldOpeningEnd;
      final fieldClosingStart = wrapper.fieldClosingStart;
      final fieldClosingEnd = wrapper.fieldClosingEnd;
      if (fieldOpeningStart != null &&
          fieldOpeningEnd != null &&
          fieldClosingStart != null &&
          fieldClosingEnd != null) {
        fieldEdits
          ..add(
            SpellingFieldEdit(
              start: fieldOpeningStart,
              end: fieldOpeningEnd,
              replacement: '',
            ),
          )
          ..add(
            SpellingFieldEdit(
              start: fieldClosingStart,
              end: fieldClosingEnd,
              replacement: '',
            ),
          );
      }
    }
    final richEdits = [
      for (final accumulator in richGroups.values) accumulator.build(),
    ]..sort((left, right) => _comparePaths(left.path, right.path));

    final reconstructed = StringBuffer();
    for (var index = 0; index < atoms.length; index++) {
      reconstructed.write(assigned[index] ?? '');
    }
    final reconstructedSuggestion = reconstructed.toString();
    if (unicode.nfc(reconstructedSuggestion) != unicode.nfc(suggestion)) {
      throw StateError(
        'The correction plan produced "$reconstructedSuggestion" instead of '
        'the selected suggestion.',
      );
    }
    final sourceOffsets = occurrence.sourceIntervals;
    return SpellingReplacementPlan(
      originalWord: occurrence.word,
      suggestion: suggestion,
      sourceEdits: _coalesceSourceEdits(sourceEdits),
      richLeafEdits: List.unmodifiable(richEdits),
      fieldEdits: _coalesceFieldEdits(fieldEdits),
      snapshot: occurrence.run.snapshot,
      languageId: occurrence.run.languageId,
      sourceTargetStart: sourceOffsets.isEmpty
          ? null
          : sourceOffsets
                .map((range) => range.start)
                .reduce((left, right) => left < right ? left : right),
      sourceTargetEnd: sourceOffsets.isEmpty
          ? null
          : sourceOffsets
                .map((range) => range.end)
                .reduce((left, right) => left > right ? left : right),
    );
  }
}

int _translateSourceBoundary(int offset, List<SpellingSourceEdit> edits) {
  var translated = offset;
  for (final edit in edits) {
    if (edit.end <= offset) {
      translated += edit.replacement.length - (edit.end - edit.start);
    } else if (edit.start < offset && edit.end > offset) {
      translated = edit.start + edit.replacement.length;
    }
  }
  return translated;
}

List<SpellingFieldEdit> _coalesceFieldEdits(List<SpellingFieldEdit> edits) {
  if (edits.length < 2) return List.unmodifiable(edits);
  final sorted = [...edits]
    ..sort((left, right) => left.start.compareTo(right.start));
  final result = <SpellingFieldEdit>[];
  for (final edit in sorted) {
    final previous = result.lastOrNull;
    if (previous != null && edit.start < previous.end) {
      if (edit.start == previous.start &&
          edit.end == previous.end &&
          edit.replacement == previous.replacement) {
        continue;
      }
      throw StateError('Overlapping spelling source edits are unsafe.');
    }
    if (previous != null && previous.end == edit.start) {
      result[result.length - 1] = SpellingFieldEdit(
        start: previous.start,
        end: edit.end,
        replacement: previous.replacement + edit.replacement,
      );
    } else {
      result.add(edit);
    }
  }
  return List.unmodifiable(result);
}

String _encode(String value, SpellingSourceContext context) {
  return switch (context) {
    SpellingSourceContext.markdownProse => value.replaceAllMapped(
      RegExp(r'([\\`*_{}\[\]()<>#+.!|])'),
      (match) => '\\${match.group(1)}',
    ),
    SpellingSourceContext.markdownTableCell => value.replaceAllMapped(
      RegExp(r'([\\`*_{}\[\]()<>#+.!|])'),
      (match) => '\\${match.group(1)}',
    ),
    SpellingSourceContext.markdownSingleQuotedTitle =>
      value.replaceAll(r'\', r'\\').replaceAll("'", r"\'"),
    SpellingSourceContext.markdownDoubleQuotedTitle =>
      value.replaceAll(r'\', r'\\').replaceAll('"', r'\"'),
    SpellingSourceContext.xmlText =>
      value
          .replaceAll('&', '&amp;')
          .replaceAll('<', '&lt;')
          .replaceAll('>', '&gt;'),
    SpellingSourceContext.xmlSingleQuotedAttribute =>
      value
          .replaceAll('&', '&amp;')
          .replaceAll('<', '&lt;')
          .replaceAll("'", '&apos;'),
    SpellingSourceContext.xmlDoubleQuotedAttribute =>
      value
          .replaceAll('&', '&amp;')
          .replaceAll('<', '&lt;')
          .replaceAll('"', '&quot;'),
    SpellingSourceContext.xmlCdata => value.replaceAll(
      ']]>',
      ']]]]><![CDATA[>',
    ),
  };
}

List<SpellingSourceEdit> _coalesceSourceEdits(List<SpellingSourceEdit> edits) {
  if (edits.length < 2) return List.unmodifiable(edits);
  final sorted = [...edits]
    ..sort((left, right) => left.start.compareTo(right.start));
  final result = <SpellingSourceEdit>[];
  for (final edit in sorted) {
    final previous = result.lastOrNull;
    if (previous != null && previous.end == edit.start) {
      result[result.length - 1] = SpellingSourceEdit(
        start: previous.start,
        end: edit.end,
        replacement: previous.replacement + edit.replacement,
      );
    } else {
      result.add(edit);
    }
  }
  return List.unmodifiable(result);
}

final class _RichEditAccumulator {
  _RichEditAccumulator(this.path);

  final List<int> path;
  int? start;
  int? end;
  final replacement = StringBuffer();

  void add({
    required int start,
    required int end,
    required String replacement,
  }) {
    this.start = this.start == null || start < this.start! ? start : this.start;
    this.end = this.end == null || end > this.end! ? end : this.end;
    this.replacement.write(replacement);
  }

  SpellingRichLeafEdit build() => SpellingRichLeafEdit(
    path: List.unmodifiable(path),
    start: start!,
    end: end!,
    replacement: replacement.toString(),
  );
}

int _comparePaths(List<int> left, List<int> right) {
  for (var index = 0; index < left.length && index < right.length; index++) {
    final result = left[index].compareTo(right[index]);
    if (result != 0) return result;
  }
  return left.length.compareTo(right.length);
}

final class _Cluster {
  const _Cluster(this.text, this.start, this.end);
  final String text;
  final int start;
  final int end;
}

List<_Cluster> _clusters(String text) {
  final result = <_Cluster>[];
  var offset = 0;
  for (final cluster in text.characters) {
    result.add(_Cluster(cluster, offset, offset + cluster.length));
    offset += cluster.length;
  }
  return result;
}

enum _AlignmentKind { equal, substitute, delete, insert }

final class _AlignmentOperation {
  const _AlignmentOperation(
    this.kind, {
    this.originalIndex,
    this.suggestionIndex,
  });
  final _AlignmentKind kind;
  final int? originalIndex;
  final int? suggestionIndex;
}

List<_AlignmentOperation> _align(
  List<_Cluster> original,
  List<_Cluster> suggestion,
) {
  final costs = List.generate(
    original.length + 1,
    (_) => List<int>.filled(suggestion.length + 1, 0),
  );
  for (var index = original.length; index >= 0; index--) {
    costs[index][suggestion.length] = original.length - index;
  }
  for (var index = suggestion.length; index >= 0; index--) {
    costs[original.length][index] = suggestion.length - index;
  }
  for (var i = original.length - 1; i >= 0; i--) {
    for (var j = suggestion.length - 1; j >= 0; j--) {
      if (unicode.nfc(original[i].text) == unicode.nfc(suggestion[j].text)) {
        costs[i][j] = costs[i + 1][j + 1];
      } else {
        final substitute = 1 + costs[i + 1][j + 1];
        final delete = 1 + costs[i + 1][j];
        final insert = 1 + costs[i][j + 1];
        costs[i][j] = [
          substitute,
          delete,
          insert,
        ].reduce((left, right) => left < right ? left : right);
      }
    }
  }
  final operations = <_AlignmentOperation>[];
  var i = 0;
  var j = 0;
  while (i < original.length || j < suggestion.length) {
    if (i < original.length &&
        j < suggestion.length &&
        unicode.nfc(original[i].text) == unicode.nfc(suggestion[j].text)) {
      operations.add(
        _AlignmentOperation(
          _AlignmentKind.equal,
          originalIndex: i,
          suggestionIndex: j,
        ),
      );
      i++;
      j++;
      continue;
    }
    final current = costs[i][j];
    // Deterministic tie-breaking: substitution, then deletion, then insertion.
    if (i < original.length &&
        j < suggestion.length &&
        current == 1 + costs[i + 1][j + 1]) {
      operations.add(
        _AlignmentOperation(
          _AlignmentKind.substitute,
          originalIndex: i,
          suggestionIndex: j,
        ),
      );
      i++;
      j++;
    } else if (i < original.length && current == 1 + costs[i + 1][j]) {
      operations.add(
        _AlignmentOperation(_AlignmentKind.delete, originalIndex: i),
      );
      i++;
    } else {
      operations.add(
        _AlignmentOperation(
          _AlignmentKind.insert,
          originalIndex: i < original.length ? i : null,
          suggestionIndex: j,
        ),
      );
      j++;
    }
  }
  return operations;
}
