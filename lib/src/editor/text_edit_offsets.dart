/// Maps unchanged UTF-16 code units through a platform text edit.
///
/// The supplied offsets must be sorted. A known selection disambiguates a
/// replacement whose edges contain the same characters as the inserted text.
/// A null result means that a complex edit exceeded the alignment budget.
List<int>? busyMarkMapUnchangedTextOffsets(
  String previous,
  String next,
  List<int> offsets, {
  ({int start, int end})? replacedSelection,
}) {
  if (previous == next || offsets.isEmpty) return offsets;
  final delta = next.length - previous.length;
  var start = 0;
  var oldEnd = previous.length;
  final selection = replacedSelection;
  if (selection != null &&
      selection.start >= 0 &&
      selection.end <= previous.length &&
      selection.end - selection.start + delta >= 0 &&
      next.startsWith(previous.substring(0, selection.start)) &&
      next.endsWith(previous.substring(selection.end))) {
    start = selection.start;
    oldEnd = selection.end;
    return [
      for (final offset in offsets)
        if (offset < start) offset else if (offset >= oldEnd) offset + delta,
    ];
  }

  while (start < previous.length &&
      start < next.length &&
      previous.codeUnitAt(start) == next.codeUnitAt(start)) {
    start++;
  }
  while (oldEnd > start &&
      oldEnd + delta > start &&
      previous.codeUnitAt(oldEnd - 1) == next.codeUnitAt(oldEnd + delta - 1)) {
    oldEnd--;
  }
  final retained = <int>[];
  final changed = <int>[];
  for (final offset in offsets) {
    if (offset < start) {
      retained.add(offset);
    } else if (offset < oldEnd) {
      changed.add(offset);
    }
  }
  final newEnd = oldEnd + delta;
  if (changed.isNotEmpty && newEnd > start) {
    final trackedUnits = {
      for (final offset in changed) previous.codeUnitAt(offset),
    };
    var candidate = start;
    while (candidate < newEnd &&
        !trackedUnits.contains(next.codeUnitAt(candidate))) {
      candidate++;
    }
    if (candidate < newEnd) {
      final matched = _alignChangedText(
        previous,
        next,
        start,
        oldEnd,
        newEnd,
        changed,
      );
      if (matched == null) return null;
      retained.addAll(matched);
    }
  }
  retained.addAll([
    for (final offset in offsets)
      if (offset >= oldEnd) offset + delta,
  ]);
  return retained;
}

// Myers alignment follows matching text between disjoint edits. Bound both
// the edit distance and comparisons so platform input cannot stall the UI.
List<int>? _alignChangedText(
  String previous,
  String next,
  int start,
  int oldEnd,
  int newEnd,
  List<int> tracked,
) {
  const maxDistance = 64;
  var remainingComparisons = 1 << 20;
  final oldLength = oldEnd - start;
  final newLength = newEnd - start;
  if ((oldLength - newLength).abs() > maxDistance) return null;
  final trace = <List<int>>[];
  for (var distance = 0; distance <= maxDistance; distance++) {
    final previousWave = trace.lastOrNull;
    final wave = List<int>.filled(distance + 1, 0);
    trace.add(wave);
    for (var index = 0; index <= distance; index++) {
      final diagonal = 2 * index - distance;
      final priorIndex = previousWave == null
          ? index
          : _precedingDiagonal(previousWave, index);
      var x = (previousWave?[priorIndex] ?? 0) + (priorIndex == index ? 0 : 1);
      var y = x - diagonal;
      while (x < oldLength && y < newLength) {
        if (--remainingComparisons < 0) return null;
        if (previous.codeUnitAt(start + x) != next.codeUnitAt(start + y)) break;
        x++;
        y++;
      }
      wave[index] = x;
      if (x == oldLength && y == newLength) {
        final matched = <int>[];
        var trackedIndex = tracked.length - 1;
        var currentIndex = index;
        for (var step = distance; step >= 0 && trackedIndex >= 0; step--) {
          final priorWave = step == 0 ? null : trace[step - 1];
          final priorIndex = priorWave == null
              ? 0
              : _precedingDiagonal(priorWave, currentIndex);
          final priorX = priorWave?[priorIndex] ?? 0;
          final matchStart =
              priorX + (step > 0 && priorIndex != currentIndex ? 1 : 0);
          while (trackedIndex >= 0 &&
              tracked[trackedIndex] >= start + matchStart) {
            final offset = tracked[trackedIndex--];
            if (offset < start + x) matched.add(offset + y - x);
          }
          if (step == 0) break;
          x = priorX;
          y = priorX - (2 * priorIndex - (step - 1));
          currentIndex = priorIndex;
        }
        return matched.reversed.toList();
      }
    }
  }
  return null;
}

int _precedingDiagonal(List<int> wave, int index) {
  if (index == 0) return 0;
  if (index == wave.length) return index - 1;
  return wave[index - 1] < wave[index] ? index : index - 1;
}
