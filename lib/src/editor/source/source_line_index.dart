import 'dart:math' as math;

class SourceLine {
  const SourceLine({
    required this.number,
    required this.startOffset,
    required this.endOffset,
    required this.endOffsetIncludingLineBreak,
    required this.text,
    required this.lineBreak,
  });

  final int number;
  final int startOffset;
  final int endOffset;
  final int endOffsetIncludingLineBreak;
  final String text;
  final String lineBreak;

  bool get hasLineBreak => lineBreak.isNotEmpty;
}

class SourceLineIndex {
  SourceLineIndex(String source) : source = source {
    _lines = _buildLines(source);
  }

  final String source;
  late final List<SourceLine> _lines;

  List<SourceLine> get lines => _lines;

  int get lineCount => _lines.length;

  SourceLine lineAt(int oneBasedLineNumber) {
    final index = (oneBasedLineNumber - 1).clamp(0, _lines.length - 1);
    return _lines[index];
  }

  SourceLine lineAtOffset(int offset) {
    return lineAt(lineNumberAtOffset(offset));
  }

  int lineNumberAtOffset(int offset) {
    if (_lines.isEmpty) {
      return 1;
    }
    final safeOffset = offset.clamp(0, source.length).toInt();
    var low = 0;
    var high = _lines.length - 1;
    while (low <= high) {
      final mid = (low + high) >> 1;
      final line = _lines[mid];
      if (safeOffset < line.startOffset) {
        high = mid - 1;
      } else if (safeOffset >= line.endOffsetIncludingLineBreak &&
          mid < _lines.length - 1) {
        low = mid + 1;
      } else {
        return line.number;
      }
    }
    return math.max(1, math.min(_lines.length, low + 1));
  }

  int offsetForLine(int oneBasedLineNumber) {
    if (oneBasedLineNumber <= 1) {
      return 0;
    }
    if (oneBasedLineNumber > _lines.length) {
      return source.length;
    }
    return _lines[oneBasedLineNumber - 1].startOffset;
  }

  static List<SourceLine> _buildLines(String source) {
    if (source.isEmpty) {
      return const [
        SourceLine(
          number: 1,
          startOffset: 0,
          endOffset: 0,
          endOffsetIncludingLineBreak: 0,
          text: '',
          lineBreak: '',
        ),
      ];
    }

    final lines = <SourceLine>[];
    var lineStart = 0;
    var lineNumber = 1;
    var index = 0;
    while (index < source.length) {
      final unit = source.codeUnitAt(index);
      if (unit != 10 && unit != 13) {
        index++;
        continue;
      }
      final breakStart = index;
      var breakEnd = index + 1;
      if (unit == 13 &&
          breakEnd < source.length &&
          source.codeUnitAt(breakEnd) == 10) {
        breakEnd++;
      }
      lines.add(
        SourceLine(
          number: lineNumber,
          startOffset: lineStart,
          endOffset: breakStart,
          endOffsetIncludingLineBreak: breakEnd,
          text: source.substring(lineStart, breakStart),
          lineBreak: source.substring(breakStart, breakEnd),
        ),
      );
      lineStart = breakEnd;
      lineNumber++;
      index = breakEnd;
    }

    lines.add(
      SourceLine(
        number: lineNumber,
        startOffset: lineStart,
        endOffset: source.length,
        endOffsetIncludingLineBreak: source.length,
        text: source.substring(lineStart),
        lineBreak: '',
      ),
    );
    return lines;
  }
}
