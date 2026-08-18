import 'markdown_model.dart';

/// A lossless editor for one heading section in a Markdown source document.
///
/// A section starts at its heading and ends immediately before the next
/// heading at the same or a higher rank. Descendant headings therefore travel
/// with the section during copy, cut, delete, and sibling moves.
class MarkdownSectionEditor {
  const MarkdownSectionEditor._({
    required this.source,
    required this.headings,
    required this.headingIndex,
    required this.sectionEndIndex,
    required this.startOffset,
    required this.endOffset,
    required this.previousSiblingIndex,
    required this.nextSiblingIndex,
  });

  factory MarkdownSectionEditor.fromHeadings({
    required String source,
    required List<MarkdownHeading> headings,
    required int headingIndex,
  }) {
    if (headingIndex < 0 || headingIndex >= headings.length) {
      throw RangeError.index(headingIndex, headings, 'headingIndex');
    }
    _validateHeadingOffsets(source, headings);

    final level = headings[headingIndex].level;
    final sectionEndIndex = _sectionEndIndex(headings, headingIndex);
    final startOffset = headings[headingIndex].span.startOffset;
    final endOffset = sectionEndIndex < headings.length
        ? headings[sectionEndIndex].span.startOffset
        : source.length;
    int? previousSiblingIndex;
    for (var index = headingIndex - 1; index >= 0; index -= 1) {
      final candidateLevel = headings[index].level;
      if (candidateLevel < level) {
        break;
      }
      if (candidateLevel == level) {
        previousSiblingIndex = index;
        break;
      }
    }
    final nextSiblingIndex =
        sectionEndIndex < headings.length &&
            headings[sectionEndIndex].level == level
        ? sectionEndIndex
        : null;

    return MarkdownSectionEditor._(
      source: source,
      headings: headings,
      headingIndex: headingIndex,
      sectionEndIndex: sectionEndIndex,
      startOffset: startOffset,
      endOffset: endOffset,
      previousSiblingIndex: previousSiblingIndex,
      nextSiblingIndex: nextSiblingIndex,
    );
  }

  final String source;
  final List<MarkdownHeading> headings;
  final int headingIndex;
  final int sectionEndIndex;
  final int startOffset;
  final int endOffset;
  final int? previousSiblingIndex;
  final int? nextSiblingIndex;

  int get level => headings[headingIndex].level;

  String get sectionText => source.substring(startOffset, endOffset);

  bool get canPromote => level > 1;

  bool get canDemote {
    for (var index = headingIndex; index < sectionEndIndex; index += 1) {
      if (headings[index].level >= 6) {
        return false;
      }
    }
    return true;
  }

  bool get canMoveUp => previousSiblingIndex != null;

  bool get canMoveDown => nextSiblingIndex != null;

  String withoutSection() => source.replaceRange(startOffset, endOffset, '');

  String? promote() => canPromote ? _changeLevels(-1) : null;

  String? demote() => canDemote ? _changeLevels(1) : null;

  String? moveUp() {
    final previousIndex = previousSiblingIndex;
    if (previousIndex == null) {
      return null;
    }
    final previousStart = headings[previousIndex].span.startOffset;
    final previousSection = source.substring(previousStart, startOffset);
    return source.replaceRange(
      previousStart,
      endOffset,
      '$sectionText$previousSection',
    );
  }

  String? moveDown() {
    final nextIndex = nextSiblingIndex;
    if (nextIndex == null) {
      return null;
    }
    final nextEndIndex = _sectionEndIndex(headings, nextIndex);
    final nextEndOffset = nextEndIndex < headings.length
        ? headings[nextEndIndex].span.startOffset
        : source.length;
    final nextSection = source.substring(endOffset, nextEndOffset);
    return source.replaceRange(
      startOffset,
      nextEndOffset,
      '$nextSection$sectionText',
    );
  }

  String? _changeLevels(int delta) {
    final replacements = <_SourceReplacement>[];
    for (var index = headingIndex; index < sectionEndIndex; index += 1) {
      final heading = headings[index];
      final nextLevel = heading.level + delta;
      if (nextLevel < 1 || nextLevel > 6) {
        return null;
      }
      final replacement = _headingLevelReplacement(source, heading, nextLevel);
      if (replacement == null) {
        return null;
      }
      replacements.add(replacement);
    }
    replacements.sort((left, right) => right.start.compareTo(left.start));
    var result = source;
    for (final replacement in replacements) {
      result = result.replaceRange(
        replacement.start,
        replacement.end,
        replacement.text,
      );
    }
    return result;
  }
}

int _sectionEndIndex(List<MarkdownHeading> headings, int headingIndex) {
  final level = headings[headingIndex].level;
  var index = headingIndex + 1;
  while (index < headings.length && headings[index].level > level) {
    index += 1;
  }
  return index;
}

void _validateHeadingOffsets(String source, List<MarkdownHeading> headings) {
  var previousOffset = -1;
  for (final heading in headings) {
    final offset = heading.span.startOffset;
    if (offset < 0 || offset > source.length || offset <= previousOffset) {
      throw ArgumentError.value(
        headings,
        'headings',
        'Heading offsets must be ordered and inside the source.',
      );
    }
    previousOffset = offset;
  }
}

_SourceReplacement? _headingLevelReplacement(
  String source,
  MarkdownHeading heading,
  int nextLevel,
) {
  final start = heading.span.startOffset;
  final firstLineEnd = _lineContentEnd(source, start);
  final firstLine = source.substring(start, firstLineEnd);
  final atx = RegExp(r'^([ \t]{0,3})(#{1,6})(?=[ \t]|$)').firstMatch(firstLine);
  if (atx != null) {
    final markerStart = start + atx.group(1)!.length;
    return _SourceReplacement(
      start: markerStart,
      end: markerStart + atx.group(2)!.length,
      text: _repeatCharacter('#', nextLevel),
    );
  }

  final firstBreak = source.indexOf('\n', start);
  if (firstBreak < 0) {
    return null;
  }
  final underlineStart = firstBreak + 1;
  final underlineEnd = _lineContentEnd(source, underlineStart);
  final underline = source.substring(underlineStart, underlineEnd);
  final setext = RegExp(r'^([ \t]{0,3})(=+|-+)([ \t]*)$').firstMatch(underline);
  if (setext == null) {
    return null;
  }
  if (nextLevel <= 2) {
    final marker = nextLevel == 1 ? '=' : '-';
    final markerLength = setext.group(2)!.length;
    final markerStart = underlineStart + setext.group(1)!.length;
    return _SourceReplacement(
      start: markerStart,
      end: markerStart + markerLength,
      text: _repeatCharacter(marker, markerLength),
    );
  }

  final indent = RegExp(r'^[ \t]{0,3}').firstMatch(firstLine)!.group(0)!;
  final content = firstLine.substring(indent.length).trimRight();
  return _SourceReplacement(
    start: start,
    end: underlineEnd,
    text: '$indent${_repeatCharacter('#', nextLevel)} $content',
  );
}

String _repeatCharacter(String character, int count) =>
    List<String>.filled(count, character).join();

int _lineContentEnd(String source, int start) {
  final lineFeed = source.indexOf('\n', start);
  var end = lineFeed < 0 ? source.length : lineFeed;
  if (end > start && source.codeUnitAt(end - 1) == 13) {
    end -= 1;
  }
  return end;
}

class _SourceReplacement {
  const _SourceReplacement({
    required this.start,
    required this.end,
    required this.text,
  });

  final int start;
  final int end;
  final String text;
}
