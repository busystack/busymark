import 'dart:math' as math;

enum SourceHiddenAffinity { downstream, upstream }

class SourceTextRange {
  const SourceTextRange(this.start, this.end);

  final int start;
  final int end;

  int get length => end - start;

  bool get isCollapsed => start == end;

  bool intersects(SourceTextRange other) {
    return start < other.end && other.start < end;
  }

  bool containsOffset(int offset) {
    return start <= offset && offset < end;
  }

  @override
  String toString() => 'SourceTextRange($start, $end)';
}

class SourceMappedRange {
  const SourceMappedRange({
    required this.range,
    required this.clippedByHiddenRange,
  });

  final SourceTextRange range;
  final bool clippedByHiddenRange;
}

class SourceHiddenRange {
  const SourceHiddenRange({required this.start, required this.end, this.key});

  final int start;
  final int end;
  final String? key;

  int get length => end - start;

  bool get isEmpty => length <= 0;

  SourceTextRange get textRange => SourceTextRange(start, end);

  SourceHiddenRange clampTo(int textLength) {
    final safeStart = start.clamp(0, textLength).toInt();
    final safeEnd = end.clamp(safeStart, textLength).toInt();
    return SourceHiddenRange(start: safeStart, end: safeEnd, key: key);
  }

  SourceHiddenRange shift(int delta, {int lineDelta = 0}) {
    return SourceHiddenRange(start: start + delta, end: end + delta, key: key);
  }

  bool intersects(int otherStart, int otherEnd) {
    return start < otherEnd && otherStart < end;
  }

  bool containsOffset(int offset) {
    return start <= offset && offset < end;
  }

  @override
  String toString() => 'SourceHiddenRange($start, $end, key: $key)';
}

class SourceHiddenRanges {
  factory SourceHiddenRanges({
    required Iterable<SourceHiddenRange> ranges,
    required int textLength,
  }) {
    final normalized = normalize(ranges, textLength: textLength);
    return SourceHiddenRanges._(
      ranges: normalized,
      textLength: textLength,
      hiddenCharactersBeforeRanges: _hiddenCharactersBefore(normalized),
    );
  }

  const SourceHiddenRanges.empty()
    : ranges = const [],
      textLength = 0,
      _hiddenCharactersBeforeRanges = const [0];

  const SourceHiddenRanges._({
    required this.ranges,
    required this.textLength,
    required List<int> hiddenCharactersBeforeRanges,
  }) : _hiddenCharactersBeforeRanges = hiddenCharactersBeforeRanges;

  final List<SourceHiddenRange> ranges;
  final int textLength;
  final List<int> _hiddenCharactersBeforeRanges;

  bool get isEmpty => ranges.isEmpty;

  bool get isNotEmpty => ranges.isNotEmpty;

  int get hiddenLength => _hiddenCharactersBeforeRanges.last;

  int get visibleLength => math.max(0, textLength - hiddenLength);

  static List<SourceHiddenRange> normalize(
    Iterable<SourceHiddenRange> ranges, {
    required int textLength,
  }) {
    final sorted =
        [
          for (final range in ranges)
            if (!range.clampTo(textLength).isEmpty) range.clampTo(textLength),
        ]..sort((a, b) {
          final byStart = a.start.compareTo(b.start);
          if (byStart != 0) {
            return byStart;
          }
          return b.end.compareTo(a.end);
        });

    final normalized = <SourceHiddenRange>[];
    for (final range in sorted) {
      if (normalized.isEmpty) {
        normalized.add(range);
        continue;
      }
      final previous = normalized.last;
      if (range.start <= previous.end) {
        normalized[normalized.length - 1] = SourceHiddenRange(
          start: previous.start,
          end: math.max(previous.end, range.end),
          key: previous.key ?? range.key,
        );
      } else {
        normalized.add(range);
      }
    }
    return List.unmodifiable(normalized);
  }

  static List<int> _hiddenCharactersBefore(List<SourceHiddenRange> ranges) {
    final result = List<int>.filled(ranges.length + 1, 0);
    var sum = 0;
    for (var index = 1; index <= ranges.length; index++) {
      sum += ranges[index - 1].length;
      result[index] = sum;
    }
    return List.unmodifiable(result);
  }

  String visibleTextFor(String fullText) {
    if (ranges.isEmpty || fullText.isEmpty) {
      return fullText;
    }
    final buffer = StringBuffer();
    var fullOffset = 0;
    for (final range in ranges) {
      if (fullOffset < range.start) {
        buffer.write(fullText.substring(fullOffset, range.start));
      }
      fullOffset = range.end;
    }
    if (fullOffset < fullText.length) {
      buffer.write(fullText.substring(fullOffset));
    }
    return buffer.toString();
  }

  int fullToVisibleOffset(int fullOffset) {
    final safeOffset = fullOffset.clamp(0, textLength).toInt();
    var hiddenBefore = 0;
    for (var index = 0; index < ranges.length; index++) {
      final range = ranges[index];
      if (safeOffset < range.start) {
        return safeOffset - hiddenBefore;
      }
      if (safeOffset <= range.end) {
        return range.start - hiddenBefore;
      }
      hiddenBefore = _hiddenCharactersBeforeRanges[index + 1];
    }
    return safeOffset - hiddenBefore;
  }

  int visibleToFullOffset(
    int visibleOffset, {
    SourceHiddenAffinity affinity = SourceHiddenAffinity.downstream,
  }) {
    final safeOffset = visibleOffset.clamp(0, visibleLength).toInt();
    var hiddenBefore = 0;
    for (var index = 0; index < ranges.length; index++) {
      final range = ranges[index];
      final collapseOffset = range.start - hiddenBefore;
      if (safeOffset < collapseOffset) {
        return safeOffset + hiddenBefore;
      }
      if (safeOffset == collapseOffset) {
        return switch (affinity) {
          SourceHiddenAffinity.downstream => range.start,
          SourceHiddenAffinity.upstream => range.end,
        };
      }
      hiddenBefore = _hiddenCharactersBeforeRanges[index + 1];
    }
    return safeOffset + hiddenBefore;
  }

  SourceMappedRange fullRangeToVisibleRange(int start, int end) {
    final safeStart = start.clamp(0, textLength).toInt();
    final safeEnd = end.clamp(safeStart, textLength).toInt();
    final range = SourceTextRange(
      fullToVisibleOffset(safeStart),
      fullToVisibleOffset(safeEnd),
    );
    return SourceMappedRange(
      range: range,
      clippedByHiddenRange: hiddenRangesIntersecting(
        safeStart,
        safeEnd,
      ).isNotEmpty,
    );
  }

  SourceMappedRange visibleRangeToFullRange(int start, int end) {
    final safeStart = start.clamp(0, visibleLength).toInt();
    final safeEnd = end.clamp(safeStart, visibleLength).toInt();
    final fullStart = visibleToFullOffset(
      safeStart,
      affinity: SourceHiddenAffinity.downstream,
    );
    final fullEnd = visibleToFullOffset(
      safeEnd,
      affinity: SourceHiddenAffinity.upstream,
    );
    return SourceMappedRange(
      range: SourceTextRange(fullStart, fullEnd),
      clippedByHiddenRange: hiddenRangesIntersecting(
        fullStart,
        fullEnd,
      ).isNotEmpty,
    );
  }

  bool isFullOffsetHidden(int offset) {
    return hiddenRangeContainingFullOffset(offset) != null;
  }

  SourceHiddenRange? hiddenRangeContainingFullOffset(int offset) {
    final safeOffset = offset.clamp(0, textLength).toInt();
    for (final range in ranges) {
      if (range.containsOffset(safeOffset)) {
        return range;
      }
      if (range.start > safeOffset) {
        return null;
      }
    }
    return null;
  }

  List<SourceHiddenRange> hiddenRangesIntersecting(int start, int end) {
    final safeStart = start.clamp(0, textLength).toInt();
    final safeEnd = end.clamp(safeStart, textLength).toInt();
    if (safeStart == safeEnd) {
      return [
        for (final range in ranges)
          if (safeStart == range.start || safeStart == range.end) range,
      ];
    }
    return [
      for (final range in ranges)
        if (range.intersects(safeStart, safeEnd)) range,
    ];
  }
}
