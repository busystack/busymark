import 'dart:math' as math;
import 'dart:async';

class SourceLocation {
  const SourceLocation({
    required this.offset,
    required this.line,
    required this.column,
  });

  final int offset;
  final int line;
  final int column;

  Map<String, Object?> toJson() => {
    'offset': offset,
    'line': line,
    'column': column,
  };
}

class SourceSpan {
  const SourceSpan({
    required this.filePath,
    required this.startOffset,
    required this.endOffset,
    required this.startLine,
    required this.startColumn,
    required this.endLine,
    required this.endColumn,
  });

  factory SourceSpan.fromOffsets({
    required String filePath,
    required String source,
    required int startOffset,
    required int endOffset,
  }) {
    final safeStart = startOffset.clamp(0, source.length);
    final safeEnd = math.max(safeStart, endOffset.clamp(0, source.length));
    final mapper = SourceLocationMapper.forSource(source);
    final start = mapper.locationForOffset(safeStart);
    final end = mapper.locationForOffset(safeEnd);
    return SourceSpan(
      filePath: filePath,
      startOffset: safeStart,
      endOffset: safeEnd,
      startLine: start.line,
      startColumn: start.column,
      endLine: end.line,
      endColumn: end.column,
    );
  }

  factory SourceSpan.entireFile(String filePath, String source) {
    return SourceSpan.fromOffsets(
      filePath: filePath,
      source: source,
      startOffset: 0,
      endOffset: source.length,
    );
  }

  final String filePath;
  final int startOffset;
  final int endOffset;
  final int startLine;
  final int startColumn;
  final int endLine;
  final int endColumn;

  Map<String, Object?> toJson() => {
    'file': filePath,
    'startOffset': startOffset,
    'endOffset': endOffset,
    'startLine': startLine,
    'startColumn': startColumn,
    'endLine': endLine,
    'endColumn': endColumn,
  };
}

class SourceLocationMapper {
  static final _zoneKey = Object();

  /// Share location maps across helpers and nested parsers for one parse only.
  static T withSource<T>(String source, T Function() parse) {
    if (Zone.current[_zoneKey] != null) return parse();
    return runZoned(
      parse,
      zoneValues: {_zoneKey: <String, SourceLocationMapper>{}},
    );
  }

  static SourceLocationMapper forSource(String source) {
    final maps = Zone.current[_zoneKey] as Map<String, SourceLocationMapper>?;
    return maps?.putIfAbsent(source, () => SourceLocationMapper(source)) ??
        SourceLocationMapper(source);
  }

  SourceLocationMapper(String source) : _source = source {
    _lineStarts = <int>[0];
    for (var i = 0; i < source.length; i++) {
      if (source.codeUnitAt(i) == 10) {
        _lineStarts.add(i + 1);
      }
    }
  }

  final String _source;
  late final List<int> _lineStarts;

  SourceLocation locationForOffset(int offset) {
    final safeOffset = offset.clamp(0, _source.length);
    var low = 0;
    var high = _lineStarts.length - 1;
    while (low <= high) {
      final mid = (low + high) >> 1;
      if (_lineStarts[mid] <= safeOffset) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    final lineIndex = math.max(0, high);
    return SourceLocation(
      offset: safeOffset,
      line: lineIndex + 1,
      column: safeOffset - _lineStarts[lineIndex] + 1,
    );
  }
}
