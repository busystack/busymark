import '../markdown/markdown_fence.dart';
import 'source_language.dart';
import 'source/source_line_index.dart';

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
  return [
    for (final line in SourceLineIndex(source).lines)
      SourceLineInfo(
        number: line.number,
        startOffset: line.startOffset,
        endOffset: line.endOffset,
        endOffsetIncludingLineBreak: line.endOffsetIncludingLineBreak,
        text: line.text,
      ),
  ];
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
  final fencedLines = _addMarkdownFenceRegions(lines, regions);
  _addMarkdownHeadingRegions(lines, regions, fencedLines);
  _addMarkdownListRegions(lines, regions, fencedLines);
  _addMarkdownBlockquoteRegions(lines, regions, fencedLines);
  return regions;
}

void _addMarkdownHeadingRegions(
  List<SourceLineInfo> lines,
  List<SourceFoldRegion> regions,
  List<bool> fencedLines,
) {
  final headingPattern = RegExp(r'^\s{0,3}(#{1,6})\s+');
  for (var index = 0; index < lines.length; index++) {
    final heading = fencedLines[index]
        ? null
        : headingPattern.firstMatch(lines[index].text);
    if (heading == null) {
      continue;
    }
    final level = heading.group(1)!.length;
    var endIndex = lines.length - 1;
    for (var next = index + 1; next < lines.length; next++) {
      final nextHeading = fencedLines[next]
          ? null
          : headingPattern.firstMatch(lines[next].text);
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

List<bool> _addMarkdownFenceRegions(
  List<SourceLineInfo> lines,
  List<SourceFoldRegion> regions,
) {
  final fencedLines = List<bool>.filled(lines.length, false);
  var index = 0;
  while (index < lines.length) {
    final fence = MarkdownFence.parse(lines[index].text);
    if (fence == null) {
      index++;
      continue;
    }
    var endIndex = index;
    for (var next = index + 1; next < lines.length; next++) {
      fencedLines[next] = true;
      if (fence.closes(lines[next].text)) {
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
    if (endIndex == index) {
      for (var next = index + 1; next < lines.length; next++) {
        fencedLines[next] = true;
      }
      break;
    }
    index = endIndex + 1;
  }
  return fencedLines;
}

void _addMarkdownListRegions(
  List<SourceLineInfo> lines,
  List<SourceFoldRegion> regions,
  List<bool> fencedLines,
) {
  var index = 0;
  while (index < lines.length) {
    if (fencedLines[index] || !_isMarkdownListLine(lines[index].text)) {
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
  List<bool> fencedLines,
) {
  var index = 0;
  while (index < lines.length) {
    if (fencedLines[index] ||
        !RegExp(r'^\s{0,3}>\s?').hasMatch(lines[index].text)) {
      index++;
      continue;
    }
    var endIndex = index;
    for (var next = index + 1; next < lines.length; next++) {
      if (fencedLines[next] ||
          !RegExp(r'^\s{0,3}>\s?').hasMatch(lines[next].text)) {
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
  final stack = <({String tag, int lineIndex})>[];
  final lexicalState = _XmlLexicalState();
  for (var index = 0; index < lines.length; index++) {
    final text = _xmlStructuralText(lines[index].text, lexicalState);
    for (final tag in _xmlTagsInLine(text)) {
      if (tag.selfClosing || tag.declaration) {
        continue;
      }
      if (!tag.closing) {
        stack.add((tag: tag.name, lineIndex: index));
        continue;
      }
      if (stack.isEmpty) {
        continue;
      }
      final opening = stack.removeLast();
      if (opening.tag != tag.name) {
        stack.clear();
        continue;
      }
      if (opening.lineIndex < index) {
        _addRegion(
          regions,
          lines,
          kind: SourceFoldKind.xml,
          startIndex: opening.lineIndex,
          endIndex: index,
        );
      }
    }
  }
  return regions;
}

class _XmlLexicalState {
  bool inComment = false;
  bool inCdata = false;
}

String _xmlStructuralText(String line, _XmlLexicalState state) {
  final visible = StringBuffer();
  var offset = 0;
  while (offset < line.length) {
    if (state.inComment) {
      final end = line.indexOf('-->', offset);
      if (end < 0) {
        return visible.toString();
      }
      state.inComment = false;
      offset = end + 3;
      continue;
    }
    if (state.inCdata) {
      final end = line.indexOf(']]>', offset);
      if (end < 0) {
        return visible.toString();
      }
      state.inCdata = false;
      offset = end + 3;
      continue;
    }
    final commentStart = line.indexOf('<!--', offset);
    final cdataStart = line.indexOf('<![CDATA[', offset);
    final excludedStart = switch ((commentStart, cdataStart)) {
      (-1, -1) => -1,
      (-1, _) => cdataStart,
      (_, -1) => commentStart,
      _ => commentStart < cdataStart ? commentStart : cdataStart,
    };
    if (excludedStart < 0) {
      visible.write(line.substring(offset));
      break;
    }
    visible.write(line.substring(offset, excludedStart));
    if (excludedStart == commentStart) {
      state.inComment = true;
      offset = excludedStart + 4;
    } else {
      state.inCdata = true;
      offset = excludedStart + 9;
    }
  }
  return visible.toString();
}

Iterable<({String name, bool closing, bool selfClosing, bool declaration})>
_xmlTagsInLine(String line) sync* {
  for (final match in RegExp(r'<[^>]+>').allMatches(line)) {
    final text = match.group(0)!;
    if (text.startsWith('<!--')) {
      continue;
    }
    final declaration =
        text.startsWith('<?') || text.startsWith('<!') || text.startsWith('<!');
    final name = RegExp(r'^</?\s*([A-Za-z_][\w:.-]*)').firstMatch(text);
    if (name == null) {
      continue;
    }
    yield (
      name: name.group(1)!,
      closing: text.startsWith('</'),
      selfClosing: text.endsWith('/>'),
      declaration: declaration,
    );
  }
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
