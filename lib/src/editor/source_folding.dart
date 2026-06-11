import 'source_language.dart';

enum SourceFoldKind { section, list, blockquote, code, xml }

class SourceLineInfo {
  const SourceLineInfo({
    required this.number,
    required this.startOffset,
    required this.endOffset,
    required this.endOffsetIncludingLineBreak,
    required this.text,
  });

  final int number;
  final int startOffset;
  final int endOffset;
  final int endOffsetIncludingLineBreak;
  final String text;
}

class SourceFoldRegion {
  const SourceFoldRegion({
    required this.kind,
    required this.startLine,
    required this.endLine,
    required this.startOffset,
    required this.endOffset,
    required this.hiddenStartOffset,
    required this.hiddenEndOffset,
  });

  final SourceFoldKind kind;
  final int startLine;
  final int endLine;
  final int startOffset;
  final int endOffset;
  final int hiddenStartOffset;
  final int hiddenEndOffset;

  int get foldedLineCount => endLine - startLine;

  String get key => '${kind.name}:$startLine:$endLine:$startOffset:$endOffset';

  bool containsLine(int line) {
    return startLine < line && line <= endLine;
  }
}

class SourceGutterEntry {
  const SourceGutterEntry({
    required this.lineNumber,
    required this.region,
    required this.collapsed,
  });

  final int lineNumber;
  final SourceFoldRegion? region;
  final bool collapsed;

  bool get foldable => region != null;
}

List<SourceLineInfo> sourceLineInfos(String source) {
  if (source.isEmpty) {
    return const [
      SourceLineInfo(
        number: 1,
        startOffset: 0,
        endOffset: 0,
        endOffsetIncludingLineBreak: 0,
        text: '',
      ),
    ];
  }

  final lines = <SourceLineInfo>[];
  var lineStart = 0;
  var lineNumber = 1;
  for (var index = 0; index < source.length; index++) {
    if (source.codeUnitAt(index) != 10) {
      continue;
    }
    lines.add(
      SourceLineInfo(
        number: lineNumber,
        startOffset: lineStart,
        endOffset: index,
        endOffsetIncludingLineBreak: index + 1,
        text: source.substring(lineStart, index),
      ),
    );
    lineStart = index + 1;
    lineNumber++;
  }

  lines.add(
    SourceLineInfo(
      number: lineNumber,
      startOffset: lineStart,
      endOffset: source.length,
      endOffsetIncludingLineBreak: source.length,
      text: source.substring(lineStart),
    ),
  );
  return lines;
}

List<SourceFoldRegion> sourceFoldRegions(
  String source,
  SourceSyntaxLanguage language,
) {
  final lines = sourceLineInfos(source);
  final regions = switch (language) {
    SourceSyntaxLanguage.markdown => _markdownFoldRegions(lines),
    SourceSyntaxLanguage.xml => _xmlFoldRegions(lines),
    SourceSyntaxLanguage.plain => <SourceFoldRegion>[],
  };
  regions.sort((a, b) {
    final start = a.startLine.compareTo(b.startLine);
    if (start != 0) {
      return start;
    }
    return b.endLine.compareTo(a.endLine);
  });
  return regions;
}

List<SourceGutterEntry> sourceGutterEntries(
  String source,
  SourceSyntaxLanguage language,
  Set<String> collapsedRegionKeys,
) {
  final lines = sourceLineInfos(source);
  final regions = sourceFoldRegions(source, language);
  final regionByStartLine = <int, SourceFoldRegion>{};
  for (final region in regions.reversed) {
    regionByStartLine.putIfAbsent(region.startLine, () => region);
  }

  final entries = <SourceGutterEntry>[];
  for (var index = 0; index < lines.length; index++) {
    final lineNumber = lines[index].number;
    final region = regionByStartLine[lineNumber];
    final collapsed =
        region != null && collapsedRegionKeys.contains(region.key);
    entries.add(
      SourceGutterEntry(
        lineNumber: lineNumber,
        region: region,
        collapsed: collapsed,
      ),
    );
    if (collapsed) {
      index += region.foldedLineCount;
    }
  }
  return entries;
}

int visibleSourceLineIndex(
  String source,
  SourceSyntaxLanguage language,
  Set<String> collapsedRegionKeys,
  int lineNumber,
) {
  final entries = sourceGutterEntries(source, language, collapsedRegionKeys);
  for (var index = 0; index < entries.length; index++) {
    if (entries[index].lineNumber >= lineNumber) {
      return index;
    }
  }
  return entries.isEmpty ? 0 : entries.length - 1;
}

int sourceLineNumberForOffset(String source, int offset) {
  final safeOffset = offset.clamp(0, source.length).toInt();
  final lines = sourceLineInfos(source);
  for (final line in lines) {
    if (safeOffset <= line.endOffsetIncludingLineBreak) {
      return line.number;
    }
  }
  return lines.isEmpty ? 1 : lines.last.number;
}

List<SourceFoldRegion> collapsedSourceFoldRegions(
  String source,
  SourceSyntaxLanguage language,
  Set<String> collapsedRegionKeys,
) {
  return [
    for (final region in sourceFoldRegions(source, language))
      if (collapsedRegionKeys.contains(region.key)) region,
  ];
}

SourceFoldRegion? collapsedRegionContainingLine(
  String source,
  SourceSyntaxLanguage language,
  Set<String> collapsedRegionKeys,
  int lineNumber,
) {
  for (final region in collapsedSourceFoldRegions(
    source,
    language,
    collapsedRegionKeys,
  )) {
    if (region.containsLine(lineNumber)) {
      return region;
    }
  }
  return null;
}

List<SourceFoldRegion> _markdownFoldRegions(List<SourceLineInfo> lines) {
  final regions = <SourceFoldRegion>[];
  _addMarkdownHeadingRegions(lines, regions);
  _addMarkdownFenceRegions(lines, regions);
  _addMarkdownListRegions(lines, regions);
  _addMarkdownBlockquoteRegions(lines, regions);
  return regions;
}

void _addMarkdownHeadingRegions(
  List<SourceLineInfo> lines,
  List<SourceFoldRegion> regions,
) {
  final headingPattern = RegExp(r'^\s{0,3}(#{1,6})\s+');
  for (var index = 0; index < lines.length; index++) {
    final heading = headingPattern.firstMatch(lines[index].text);
    if (heading == null) {
      continue;
    }
    final level = heading.group(1)!.length;
    var endIndex = lines.length - 1;
    for (var next = index + 1; next < lines.length; next++) {
      final nextHeading = headingPattern.firstMatch(lines[next].text);
      if (nextHeading != null && nextHeading.group(1)!.length <= level) {
        endIndex = next - 1;
        break;
      }
    }
    _addRegion(
      regions,
      lines,
      kind: SourceFoldKind.section,
      startIndex: index,
      endIndex: endIndex,
    );
  }
}

void _addMarkdownFenceRegions(
  List<SourceLineInfo> lines,
  List<SourceFoldRegion> regions,
) {
  var index = 0;
  while (index < lines.length) {
    final fence = RegExp(r'^\s*(```|~~~)').firstMatch(lines[index].text);
    if (fence == null) {
      index++;
      continue;
    }
    final marker = fence.group(1)!;
    var endIndex = index;
    for (var next = index + 1; next < lines.length; next++) {
      if (RegExp('^\\s*${RegExp.escape(marker)}').hasMatch(lines[next].text)) {
        endIndex = next;
        break;
      }
    }
    _addRegion(
      regions,
      lines,
      kind: SourceFoldKind.code,
      startIndex: index,
      endIndex: endIndex,
    );
    index = endIndex + 1;
  }
}

void _addMarkdownListRegions(
  List<SourceLineInfo> lines,
  List<SourceFoldRegion> regions,
) {
  var index = 0;
  while (index < lines.length) {
    if (!_isMarkdownListLine(lines[index].text)) {
      index++;
      continue;
    }
    var endIndex = index;
    for (var next = index + 1; next < lines.length; next++) {
      final text = lines[next].text;
      if (_isMarkdownListLine(text) ||
          text.trim().isEmpty ||
          text.startsWith('  ') ||
          text.startsWith('\t')) {
        endIndex = next;
        continue;
      }
      break;
    }
    while (endIndex > index && lines[endIndex].text.trim().isEmpty) {
      endIndex--;
    }
    _addRegion(
      regions,
      lines,
      kind: SourceFoldKind.list,
      startIndex: index,
      endIndex: endIndex,
    );
    index = endIndex + 1;
  }
}

void _addMarkdownBlockquoteRegions(
  List<SourceLineInfo> lines,
  List<SourceFoldRegion> regions,
) {
  var index = 0;
  while (index < lines.length) {
    if (!RegExp(r'^\s{0,3}>\s?').hasMatch(lines[index].text)) {
      index++;
      continue;
    }
    var endIndex = index;
    for (var next = index + 1; next < lines.length; next++) {
      if (!RegExp(r'^\s{0,3}>\s?').hasMatch(lines[next].text)) {
        break;
      }
      endIndex = next;
    }
    _addRegion(
      regions,
      lines,
      kind: SourceFoldKind.blockquote,
      startIndex: index,
      endIndex: endIndex,
    );
    index = endIndex + 1;
  }
}

List<SourceFoldRegion> _xmlFoldRegions(List<SourceLineInfo> lines) {
  final regions = <SourceFoldRegion>[];
  for (var index = 0; index < lines.length; index++) {
    final opening = RegExp(
      r'<([A-Za-z_][\w:.-]*)(?:\s|>)(?![^>]*\/>)',
    ).firstMatch(lines[index].text);
    if (opening == null || lines[index].text.trimLeft().startsWith('</')) {
      continue;
    }
    final tag = opening.group(1)!;
    final closingPattern = RegExp('</${RegExp.escape(tag)}>');
    for (var next = index + 1; next < lines.length; next++) {
      if (!closingPattern.hasMatch(lines[next].text)) {
        continue;
      }
      _addRegion(
        regions,
        lines,
        kind: SourceFoldKind.xml,
        startIndex: index,
        endIndex: next,
      );
      break;
    }
  }
  return regions;
}

bool _isMarkdownListLine(String text) {
  return RegExp(r'^\s{0,8}(?:[-*+]|\d+\.)\s+').hasMatch(text);
}

void _addRegion(
  List<SourceFoldRegion> regions,
  List<SourceLineInfo> lines, {
  required SourceFoldKind kind,
  required int startIndex,
  required int endIndex,
}) {
  if (endIndex <= startIndex || startIndex + 1 >= lines.length) {
    return;
  }
  final startLine = lines[startIndex];
  final hiddenStartLine = lines[startIndex + 1];
  final endLine = lines[endIndex];
  if (endLine.endOffsetIncludingLineBreak <= hiddenStartLine.startOffset) {
    return;
  }
  regions.add(
    SourceFoldRegion(
      kind: kind,
      startLine: startLine.number,
      endLine: endLine.number,
      startOffset: startLine.startOffset,
      endOffset: endLine.endOffset,
      hiddenStartOffset: hiddenStartLine.startOffset,
      hiddenEndOffset: endLine.endOffsetIncludingLineBreak,
    ),
  );
}
