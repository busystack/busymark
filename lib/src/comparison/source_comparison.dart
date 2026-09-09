import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

@immutable
class SourceComparisonInput {
  const SourceComparisonInput({
    required this.id,
    required this.version,
    required this.label,
    required this.source,
  });

  final String id;
  final int version;
  final String label;
  final String source;
}

@immutable
class SourceComparisonRange {
  const SourceComparisonRange(this.start, this.end)
    : assert(start >= 0),
      assert(end >= start);

  final int start;
  final int end;
}

@immutable
class SourceComparisonChange {
  const SourceComparisonChange({
    required this.oldRange,
    required this.currentRange,
    required this.oldText,
    required this.currentText,
    required this.oldIntralineRange,
    required this.currentIntralineRange,
    required this.exact,
  });

  final SourceComparisonRange oldRange;
  final SourceComparisonRange currentRange;
  final String oldText;
  final String currentText;
  final SourceComparisonRange oldIntralineRange;
  final SourceComparisonRange currentIntralineRange;
  final bool exact;
}

@immutable
class SourceComparison {
  const SourceComparison({
    required this.oldInput,
    required this.currentInput,
    required this.changes,
    required this.simplified,
  });

  final SourceComparisonInput oldInput;
  final SourceComparisonInput currentInput;
  final List<SourceComparisonChange> changes;
  final bool simplified;

  bool stillMatches(SourceComparisonInput old, SourceComparisonInput current) =>
      old.id == oldInput.id &&
      old.version == oldInput.version &&
      current.id == currentInput.id &&
      current.version == currentInput.version;
}

SourceComparison compareSource(
  SourceComparisonInput oldInput,
  SourceComparisonInput currentInput, {
  int maximumLcsCells = 2000000,
}) {
  final oldLines = _sourceLines(oldInput.source);
  final currentLines = _sourceLines(currentInput.source);
  final operations = <_DiffOperation>[];
  _diffSegment(
    oldLines,
    0,
    oldLines.length,
    currentLines,
    0,
    currentLines.length,
    operations,
    maximumLcsCells,
  );
  final changes = _changesFromOperations(operations);
  return SourceComparison(
    oldInput: oldInput,
    currentInput: currentInput,
    changes: List.unmodifiable(changes),
    simplified: changes.any((change) => !change.exact),
  );
}

class _SourceLine {
  const _SourceLine(this.text, this.start, this.end);

  final String text;
  final int start;
  final int end;
}

List<_SourceLine> _sourceLines(String source) {
  if (source.isEmpty) return const [];
  final result = <_SourceLine>[];
  var start = 0;
  while (start < source.length) {
    final newline = source.indexOf('\n', start);
    final end = newline < 0 ? source.length : newline + 1;
    result.add(_SourceLine(source.substring(start, end), start, end));
    start = end;
  }
  return result;
}

enum _OperationKind { equal, delete, insert }

class _DiffOperation {
  const _DiffOperation(this.kind, this.line, {this.exact = true});

  final _OperationKind kind;
  final _SourceLine line;
  final bool exact;
}

void _diffSegment(
  List<_SourceLine> oldLines,
  int oldStart,
  int oldEnd,
  List<_SourceLine> currentLines,
  int currentStart,
  int currentEnd,
  List<_DiffOperation> output,
  int maximumLcsCells,
) {
  while (oldStart < oldEnd &&
      currentStart < currentEnd &&
      oldLines[oldStart].text == currentLines[currentStart].text) {
    output.add(_DiffOperation(_OperationKind.equal, oldLines[oldStart]));
    oldStart++;
    currentStart++;
  }
  var suffix = 0;
  while (oldStart < oldEnd - suffix &&
      currentStart < currentEnd - suffix &&
      oldLines[oldEnd - suffix - 1].text ==
          currentLines[currentEnd - suffix - 1].text) {
    suffix++;
  }
  oldEnd -= suffix;
  currentEnd -= suffix;
  if (oldStart == oldEnd || currentStart == currentEnd) {
    for (var index = oldStart; index < oldEnd; index++) {
      output.add(_DiffOperation(_OperationKind.delete, oldLines[index]));
    }
    for (var index = currentStart; index < currentEnd; index++) {
      output.add(_DiffOperation(_OperationKind.insert, currentLines[index]));
    }
  } else {
    final anchors = _patienceAnchors(
      oldLines,
      oldStart,
      oldEnd,
      currentLines,
      currentStart,
      currentEnd,
    );
    if (anchors.isNotEmpty) {
      var previousOld = oldStart;
      var previousCurrent = currentStart;
      for (final anchor in anchors) {
        _diffSegment(
          oldLines,
          previousOld,
          anchor.oldIndex,
          currentLines,
          previousCurrent,
          anchor.currentIndex,
          output,
          maximumLcsCells,
        );
        output.add(
          _DiffOperation(_OperationKind.equal, oldLines[anchor.oldIndex]),
        );
        previousOld = anchor.oldIndex + 1;
        previousCurrent = anchor.currentIndex + 1;
      }
      _diffSegment(
        oldLines,
        previousOld,
        oldEnd,
        currentLines,
        previousCurrent,
        currentEnd,
        output,
        maximumLcsCells,
      );
    } else if ((oldEnd - oldStart) * (currentEnd - currentStart) <=
        maximumLcsCells) {
      _boundedLcs(
        oldLines,
        oldStart,
        oldEnd,
        currentLines,
        currentStart,
        currentEnd,
        output,
      );
    } else {
      for (var index = oldStart; index < oldEnd; index++) {
        output.add(
          _DiffOperation(_OperationKind.delete, oldLines[index], exact: false),
        );
      }
      for (var index = currentStart; index < currentEnd; index++) {
        output.add(
          _DiffOperation(
            _OperationKind.insert,
            currentLines[index],
            exact: false,
          ),
        );
      }
    }
  }
  for (var index = 0; index < suffix; index++) {
    output.add(_DiffOperation(_OperationKind.equal, oldLines[oldEnd + index]));
  }
}

class _Anchor {
  const _Anchor(this.oldIndex, this.currentIndex);

  final int oldIndex;
  final int currentIndex;
}

List<_Anchor> _patienceAnchors(
  List<_SourceLine> oldLines,
  int oldStart,
  int oldEnd,
  List<_SourceLine> currentLines,
  int currentStart,
  int currentEnd,
) {
  final oldCounts = <String, int>{};
  final oldPositions = <String, int>{};
  for (var index = oldStart; index < oldEnd; index++) {
    final text = oldLines[index].text;
    oldCounts[text] = (oldCounts[text] ?? 0) + 1;
    oldPositions[text] = index;
  }
  final currentCounts = <String, int>{};
  final currentPositions = <String, int>{};
  for (var index = currentStart; index < currentEnd; index++) {
    final text = currentLines[index].text;
    currentCounts[text] = (currentCounts[text] ?? 0) + 1;
    currentPositions[text] = index;
  }
  final candidates = <_Anchor>[];
  for (final entry in oldPositions.entries) {
    if (oldCounts[entry.key] == 1 && currentCounts[entry.key] == 1) {
      candidates.add(_Anchor(entry.value, currentPositions[entry.key]!));
    }
  }
  candidates.sort((left, right) => left.oldIndex.compareTo(right.oldIndex));
  if (candidates.isEmpty) return const [];

  final tails = <int>[];
  final tailCandidate = <int>[];
  final previous = List<int>.filled(candidates.length, -1);
  for (var index = 0; index < candidates.length; index++) {
    final value = candidates[index].currentIndex;
    var low = 0;
    var high = tails.length;
    while (low < high) {
      final middle = (low + high) >> 1;
      if (tails[middle] < value) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    if (low > 0) previous[index] = tailCandidate[low - 1];
    if (low == tails.length) {
      tails.add(value);
      tailCandidate.add(index);
    } else {
      tails[low] = value;
      tailCandidate[low] = index;
    }
  }
  final result = <_Anchor>[];
  var index = tailCandidate.last;
  while (index >= 0) {
    result.add(candidates[index]);
    index = previous[index];
  }
  return result.reversed.toList(growable: false);
}

void _boundedLcs(
  List<_SourceLine> oldLines,
  int oldStart,
  int oldEnd,
  List<_SourceLine> currentLines,
  int currentStart,
  int currentEnd,
  List<_DiffOperation> output,
) {
  final oldCount = oldEnd - oldStart;
  final currentCount = currentEnd - currentStart;
  final width = currentCount + 1;
  final table = Uint32List((oldCount + 1) * width);
  for (var old = oldCount - 1; old >= 0; old--) {
    for (var current = currentCount - 1; current >= 0; current--) {
      final cell = old * width + current;
      table[cell] =
          oldLines[oldStart + old].text ==
              currentLines[currentStart + current].text
          ? table[(old + 1) * width + current + 1] + 1
          : math.max(
              table[(old + 1) * width + current],
              table[old * width + current + 1],
            );
    }
  }
  var old = 0;
  var current = 0;
  while (old < oldCount && current < currentCount) {
    final oldLine = oldLines[oldStart + old];
    final currentLine = currentLines[currentStart + current];
    if (oldLine.text == currentLine.text) {
      output.add(_DiffOperation(_OperationKind.equal, oldLine));
      old++;
      current++;
    } else if (table[(old + 1) * width + current] >=
        table[old * width + current + 1]) {
      output.add(_DiffOperation(_OperationKind.delete, oldLine));
      old++;
    } else {
      output.add(_DiffOperation(_OperationKind.insert, currentLine));
      current++;
    }
  }
  while (old < oldCount) {
    output.add(
      _DiffOperation(_OperationKind.delete, oldLines[oldStart + old++]),
    );
  }
  while (current < currentCount) {
    output.add(
      _DiffOperation(
        _OperationKind.insert,
        currentLines[currentStart + current++],
      ),
    );
  }
}

List<SourceComparisonChange> _changesFromOperations(
  List<_DiffOperation> operations,
) {
  final result = <SourceComparisonChange>[];
  var oldOffset = 0;
  var currentOffset = 0;
  var index = 0;
  while (index < operations.length) {
    final operation = operations[index];
    if (operation.kind == _OperationKind.equal) {
      oldOffset += operation.line.text.length;
      currentOffset += operation.line.text.length;
      index++;
      continue;
    }
    final oldStart = oldOffset;
    final currentStart = currentOffset;
    final old = StringBuffer();
    final current = StringBuffer();
    var exact = true;
    while (index < operations.length &&
        operations[index].kind != _OperationKind.equal) {
      final changed = operations[index++];
      exact = exact && changed.exact;
      if (changed.kind == _OperationKind.delete) {
        old.write(changed.line.text);
        oldOffset += changed.line.text.length;
      } else {
        current.write(changed.line.text);
        currentOffset += changed.line.text.length;
      }
    }
    final oldText = old.toString();
    final currentText = current.toString();
    final intraline = _intralineRanges(oldText, currentText);
    result.add(
      SourceComparisonChange(
        oldRange: SourceComparisonRange(oldStart, oldOffset),
        currentRange: SourceComparisonRange(currentStart, currentOffset),
        oldText: oldText,
        currentText: currentText,
        oldIntralineRange: intraline.oldRange,
        currentIntralineRange: intraline.currentRange,
        exact: exact,
      ),
    );
  }
  return result;
}

({SourceComparisonRange oldRange, SourceComparisonRange currentRange})
_intralineRanges(String oldText, String currentText) {
  var prefix = 0;
  final limit = math.min(oldText.length, currentText.length);
  while (prefix < limit &&
      oldText.codeUnitAt(prefix) == currentText.codeUnitAt(prefix)) {
    prefix++;
  }
  prefix = _safeUtf16Boundary(oldText, prefix, backwards: true);
  prefix = math.min(
    prefix,
    _safeUtf16Boundary(currentText, prefix, backwards: true),
  );
  var oldSuffix = oldText.length;
  var currentSuffix = currentText.length;
  while (oldSuffix > prefix &&
      currentSuffix > prefix &&
      oldText.codeUnitAt(oldSuffix - 1) ==
          currentText.codeUnitAt(currentSuffix - 1)) {
    oldSuffix--;
    currentSuffix--;
  }
  oldSuffix = _safeUtf16Boundary(oldText, oldSuffix, backwards: false);
  currentSuffix = _safeUtf16Boundary(
    currentText,
    currentSuffix,
    backwards: false,
  );
  return (
    oldRange: SourceComparisonRange(prefix, oldSuffix),
    currentRange: SourceComparisonRange(prefix, currentSuffix),
  );
}

int _safeUtf16Boundary(String value, int offset, {required bool backwards}) {
  if (offset <= 0 || offset >= value.length) return offset;
  final before = value.codeUnitAt(offset - 1);
  final after = value.codeUnitAt(offset);
  final splitsSurrogate =
      before >= 0xd800 &&
      before <= 0xdbff &&
      after >= 0xdc00 &&
      after <= 0xdfff;
  if (!splitsSurrogate) return offset;
  return backwards ? offset - 1 : offset + 1;
}
