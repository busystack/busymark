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
  return SourceLineIndex(source).lineNumberAtOffset(safeOffset);
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
  for (final tag in _xmlTags(lines)) {
    if (tag.selfClosing) {
      continue;
    }
    if (!tag.closing) {
      stack.add((tag: tag.name, lineIndex: tag.startLineIndex));
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
    if (opening.lineIndex < tag.endLineIndex) {
      _addRegion(
        regions,
        lines,
        kind: SourceFoldKind.xml,
        startIndex: opening.lineIndex,
        endIndex: tag.endLineIndex,
      );
    }
  }
  return regions;
}

enum _XmlScanMode {
  text,
  tag,
  comment,
  cdata,
  processingInstruction,
  declaration,
  declarationComment,
}

Iterable<
  ({
    String name,
    bool closing,
    bool selfClosing,
    int startLineIndex,
    int endLineIndex,
  })
>
_xmlTags(List<SourceLineInfo> lines) sync* {
  var mode = _XmlScanMode.text;
  var quote = 0;
  var declarationBracketDepth = 0;
  var tagStartLineIndex = 0;
  var tagText = StringBuffer();

  for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
    final line = lines[lineIndex].text;
    var offset = 0;
    while (offset < line.length) {
      switch (mode) {
        case _XmlScanMode.text:
          if (line.codeUnitAt(offset) != 60) {
            offset++;
            continue;
          }
          if (line.startsWith('<!--', offset)) {
            mode = _XmlScanMode.comment;
            offset += 4;
          } else if (line.startsWith('<![CDATA[', offset)) {
            mode = _XmlScanMode.cdata;
            offset += 9;
          } else if (line.startsWith('<?', offset)) {
            mode = _XmlScanMode.processingInstruction;
            offset += 2;
          } else if (line.startsWith('<!', offset)) {
            mode = _XmlScanMode.declaration;
            quote = 0;
            declarationBracketDepth = 0;
            offset += 2;
          } else {
            mode = _XmlScanMode.tag;
            quote = 0;
            tagStartLineIndex = lineIndex;
            tagText = StringBuffer('<');
            offset++;
          }
        case _XmlScanMode.tag:
          final unit = line.codeUnitAt(offset);
          tagText.writeCharCode(unit);
          offset++;
          if (quote != 0) {
            if (unit == quote) {
              quote = 0;
            }
            continue;
          }
          if (unit == 34 || unit == 39) {
            quote = unit;
            continue;
          }
          if (unit != 62) {
            continue;
          }
          final parsed = _parseXmlTag(tagText.toString());
          mode = _XmlScanMode.text;
          if (parsed != null) {
            yield (
              name: parsed.name,
              closing: parsed.closing,
              selfClosing: parsed.selfClosing,
              startLineIndex: tagStartLineIndex,
              endLineIndex: lineIndex,
            );
          }
        case _XmlScanMode.comment:
          final end = line.indexOf('-->', offset);
          if (end < 0) {
            offset = line.length;
          } else {
            mode = _XmlScanMode.text;
            offset = end + 3;
          }
        case _XmlScanMode.cdata:
          final end = line.indexOf(']]>', offset);
          if (end < 0) {
            offset = line.length;
          } else {
            mode = _XmlScanMode.text;
            offset = end + 3;
          }
        case _XmlScanMode.processingInstruction:
          final end = line.indexOf('?>', offset);
          if (end < 0) {
            offset = line.length;
          } else {
            mode = _XmlScanMode.text;
            offset = end + 2;
          }
        case _XmlScanMode.declaration:
          if (line.startsWith('<!--', offset)) {
            mode = _XmlScanMode.declarationComment;
            offset += 4;
            continue;
          }
          final unit = line.codeUnitAt(offset);
          offset++;
          if (quote != 0) {
            if (unit == quote) {
              quote = 0;
            }
          } else if (unit == 34 || unit == 39) {
            quote = unit;
          } else if (unit == 91) {
            declarationBracketDepth++;
          } else if (unit == 93 && declarationBracketDepth > 0) {
            declarationBracketDepth--;
          } else if (unit == 62 && declarationBracketDepth == 0) {
            mode = _XmlScanMode.text;
          }
        case _XmlScanMode.declarationComment:
          final end = line.indexOf('-->', offset);
          if (end < 0) {
            offset = line.length;
          } else {
            mode = _XmlScanMode.declaration;
            offset = end + 3;
          }
      }
    }
    if (mode == _XmlScanMode.tag) {
      tagText.writeln();
    }
  }
}

({String name, bool closing, bool selfClosing})? _parseXmlTag(String text) {
  final match = RegExp(
    r'^<(/?)\s*([A-Za-z_][A-Za-z0-9_.:-]*)',
  ).firstMatch(text);
  if (match == null) {
    return null;
  }
  final closing = match.group(1)!.isNotEmpty;
  return (
    name: match.group(2)!,
    closing: closing,
    selfClosing: !closing && RegExp(r'/\s*>$').hasMatch(text),
  );
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
