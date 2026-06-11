import 'package:flutter/material.dart';

import '../app/busymark_design.dart';
import 'source_folding.dart';
import 'source_language.dart';

export 'source_language.dart';

class BusyMarkSourceEditingController extends TextEditingController {
  BusyMarkSourceEditingController({
    super.text,
    SourceSyntaxLanguage language = SourceSyntaxLanguage.markdown,
  }) : _language = language;

  SourceSyntaxLanguage _language;
  List<SourceFoldRegion> _foldedRegions = const [];
  bool renderText = true;

  SourceSyntaxLanguage get language => _language;

  set language(SourceSyntaxLanguage value) {
    if (_language == value) {
      return;
    }
    _language = value;
    notifyListeners();
  }

  List<SourceFoldRegion> get foldedRegions => _foldedRegions;

  void setFoldedRegions(Iterable<SourceFoldRegion> regions) {
    _foldedRegions = _normalizedFoldRegions(regions);
  }

  void clearFoldedRegions() {
    _foldedRegions = const [];
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    return buildSourceTextSpan(
      context: context,
      style: style,
      visible: renderText,
    );
  }

  TextSpan buildSourceTextSpan({
    required BuildContext context,
    TextStyle? style,
    bool visible = true,
  }) {
    final colors = BusyMarkSurfaceColors.of(context);
    final baseStyle = (style ?? DefaultTextStyle.of(context).style).copyWith(
      color: visible ? colors.foreground : Colors.transparent,
      backgroundColor: Colors.transparent,
    );
    final source = text;
    if (source.isEmpty || source.length > 300000) {
      return TextSpan(text: source, style: baseStyle);
    }
    final hiddenRanges = _foldedRegions
        .map(
          (region) =>
              _HiddenRange(region.hiddenStartOffset, region.hiddenEndOffset),
        )
        .toList();
    if (!visible) {
      return TextSpan(
        style: baseStyle,
        children: _spansFromRanges(source, const [], hiddenRanges, baseStyle),
      );
    }
    final palette = _SourceSyntaxPalette.fromContext(context);
    return TextSpan(
      style: baseStyle,
      children: switch (_language) {
        SourceSyntaxLanguage.markdown => _highlightMarkdown(
          source,
          baseStyle,
          palette,
          hiddenRanges,
        ),
        SourceSyntaxLanguage.xml => _highlightXml(
          source,
          baseStyle,
          palette,
          hiddenRanges,
        ),
        SourceSyntaxLanguage.plain => [
          ..._spansFromRanges(source, const [], hiddenRanges, baseStyle),
        ],
      },
    );
  }
}

class _SourceSyntaxPalette {
  const _SourceSyntaxPalette({
    required this.heading,
    required this.keyword,
    required this.tag,
    required this.attribute,
    required this.string,
    required this.literal,
    required this.link,
    required this.comment,
    required this.punctuation,
  });

  factory _SourceSyntaxPalette.fromContext(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return _SourceSyntaxPalette(
      heading: dark ? const Color(0xFF99C1F1) : const Color(0xFF1A5FB4),
      keyword: dark ? const Color(0xFFFFBE6F) : const Color(0xFF9C6B00),
      tag: dark ? const Color(0xFF8FF0A4) : const Color(0xFF2A7B43),
      attribute: dark ? const Color(0xFFF9F06B) : const Color(0xFF865E00),
      string: dark ? const Color(0xFFF66151) : const Color(0xFFC01C28),
      literal: dark ? const Color(0xFFDC8ADD) : const Color(0xFF813D9C),
      link: dark ? const Color(0xFF62A0EA) : const Color(0xFF1C71D8),
      comment: colors.mutedForeground.withValues(alpha: dark ? 0.82 : 0.76),
      punctuation: colors.mutedForeground,
    );
  }

  final Color heading;
  final Color keyword;
  final Color tag;
  final Color attribute;
  final Color string;
  final Color literal;
  final Color link;
  final Color comment;
  final Color punctuation;
}

class _HighlightRange {
  const _HighlightRange(this.start, this.end, this.style);

  final int start;
  final int end;
  final TextStyle style;

  bool overlaps(int otherStart, int otherEnd) {
    return start < otherEnd && otherStart < end;
  }
}

class _HiddenRange {
  const _HiddenRange(this.start, this.end);

  final int start;
  final int end;

  bool contains(int otherStart, int otherEnd) {
    return start <= otherStart && otherEnd <= end;
  }
}

List<TextSpan> _highlightMarkdown(
  String source,
  TextStyle baseStyle,
  _SourceSyntaxPalette palette,
  List<_HiddenRange> hiddenRanges,
) {
  final ranges = <_HighlightRange>[];
  var offset = 0;
  var inFence = false;
  var inFrontMatter = source.startsWith('---\n') || source == '---';

  for (final line in source.split('\n')) {
    final lineStart = offset;
    final lineEnd = lineStart + line.length;
    final trimmed = line.trimLeft();
    final fence = RegExp(r'^\s*(```|~~~)').hasMatch(line);

    if (inFrontMatter) {
      _addRange(
        ranges,
        lineStart,
        lineEnd,
        baseStyle.copyWith(color: palette.comment),
      );
      if (lineStart > 0 && line.trim() == '---') {
        inFrontMatter = false;
      }
      offset = lineEnd + 1;
      continue;
    }

    if (inFence || fence) {
      _addRange(
        ranges,
        lineStart,
        lineEnd,
        baseStyle.copyWith(color: fence ? palette.keyword : palette.literal),
      );
      if (fence) {
        inFence = !inFence;
      }
      offset = lineEnd + 1;
      continue;
    }

    final heading = RegExp(r'^\s{0,3}#{1,6}\s').firstMatch(line);
    if (heading != null) {
      _addRange(
        ranges,
        lineStart,
        lineEnd,
        baseStyle.copyWith(color: palette.heading, fontWeight: FontWeight.w700),
      );
      offset = lineEnd + 1;
      continue;
    }

    final blockquote = RegExp(r'^\s{0,3}>\s?').firstMatch(line);
    if (blockquote != null) {
      _addRange(
        ranges,
        lineStart,
        lineStart + blockquote.end,
        baseStyle.copyWith(color: palette.keyword),
      );
    }

    final listMarker = RegExp(r'^\s*(?:[-*+]|\d+\.)\s+').firstMatch(line);
    if (listMarker != null) {
      _addRange(
        ranges,
        lineStart,
        lineStart + listMarker.end,
        baseStyle.copyWith(color: palette.keyword),
      );
    }

    _addInlineMatches(
      ranges,
      lineStart,
      line,
      RegExp(r'`[^`\n]+`'),
      baseStyle.copyWith(color: palette.literal),
    );
    _addInlineMatches(
      ranges,
      lineStart,
      line,
      RegExp(r'!?\[[^\]\n]+\]\([^\)\n]+\)'),
      baseStyle.copyWith(color: palette.link),
    );
    _addInlineMatches(
      ranges,
      lineStart,
      line,
      RegExp(r'</?[A-Za-z_][^>\n]*>'),
      baseStyle.copyWith(color: palette.tag),
    );
    _addInlineMatches(
      ranges,
      lineStart,
      line,
      RegExp(r'(\*\*[^*\n]+\*\*|__[^_\n]+__|\*[^*\n]+\*|_[^_\n]+_)'),
      baseStyle.copyWith(color: palette.keyword),
    );

    if (trimmed.startsWith('<!--')) {
      _addRange(
        ranges,
        lineStart + line.indexOf('<!--'),
        lineEnd,
        baseStyle.copyWith(color: palette.comment),
      );
    }
    offset = lineEnd + 1;
  }

  return _spansFromRanges(source, ranges, hiddenRanges, baseStyle);
}

List<TextSpan> _highlightXml(
  String source,
  TextStyle baseStyle,
  _SourceSyntaxPalette palette,
  List<_HiddenRange> hiddenRanges,
) {
  final ranges = <_HighlightRange>[];
  final commentStyle = baseStyle.copyWith(color: palette.comment);
  final tagStyle = baseStyle.copyWith(color: palette.tag);
  final attributeStyle = baseStyle.copyWith(color: palette.attribute);
  final stringStyle = baseStyle.copyWith(color: palette.string);
  final punctuationStyle = baseStyle.copyWith(color: palette.punctuation);

  for (final comment in RegExp(r'<!--[\s\S]*?-->').allMatches(source)) {
    _addRange(ranges, comment.start, comment.end, commentStyle);
  }

  for (final tag in RegExp(r'</?[^>]+/?>').allMatches(source)) {
    final text = tag.group(0)!;
    if (text.startsWith('<!--')) {
      continue;
    }
    _addRange(ranges, tag.start, tag.start + 1, punctuationStyle);
    if (text.startsWith('</')) {
      _addRange(ranges, tag.start + 1, tag.start + 2, punctuationStyle);
    }
    _addRange(ranges, tag.end - 1, tag.end, punctuationStyle);
    if (text.endsWith('/>') && tag.end - 2 > tag.start) {
      _addRange(ranges, tag.end - 2, tag.end - 1, punctuationStyle);
    }

    final name = RegExp(r'^</?\s*([A-Za-z_][\w:.-]*)').firstMatch(text);
    if (name != null) {
      final nameText = name.group(1)!;
      final nameOffset = text.indexOf(nameText, name.start);
      if (nameOffset >= 0) {
        _addRange(
          ranges,
          tag.start + nameOffset,
          tag.start + nameOffset + nameText.length,
          tagStyle,
        );
      }
    }

    for (final attr in RegExp(
      r'([A-Za-z_:][\w:.-]*)(?=\s*=)',
    ).allMatches(text)) {
      _addRange(
        ranges,
        tag.start + attr.start,
        tag.start + attr.end,
        attributeStyle,
      );
    }
    for (final literal in RegExp("\"[^\"\\n]*\"|'[^'\\n]*'").allMatches(text)) {
      _addRange(
        ranges,
        tag.start + literal.start,
        tag.start + literal.end,
        stringStyle,
      );
    }
  }

  return _spansFromRanges(source, ranges, hiddenRanges, baseStyle);
}

void _addInlineMatches(
  List<_HighlightRange> ranges,
  int lineStart,
  String line,
  RegExp pattern,
  TextStyle style,
) {
  for (final match in pattern.allMatches(line)) {
    _addRange(ranges, lineStart + match.start, lineStart + match.end, style);
  }
}

void _addRange(
  List<_HighlightRange> ranges,
  int start,
  int end,
  TextStyle style,
) {
  if (start < 0 || end <= start) {
    return;
  }
  for (final range in ranges) {
    if (range.overlaps(start, end)) {
      return;
    }
  }
  ranges.add(_HighlightRange(start, end, style));
}

List<TextSpan> _spansFromRanges(
  String source,
  List<_HighlightRange> ranges,
  List<_HiddenRange> hiddenRanges,
  TextStyle baseStyle,
) {
  final sortedRanges = [...ranges]..sort((a, b) => a.start.compareTo(b.start));
  final sortedHiddenRanges = [...hiddenRanges]
    ..sort((a, b) => a.start.compareTo(b.start));
  final hiddenStyle = baseStyle.copyWith(
    color: Colors.transparent,
    fontSize: 0.01,
    height: 0.01,
    letterSpacing: 0,
    wordSpacing: 0,
  );
  final boundaries = <int>{0, source.length};
  for (final range in sortedRanges) {
    boundaries.add(range.start.clamp(0, source.length).toInt());
    boundaries.add(range.end.clamp(0, source.length).toInt());
  }
  for (final range in sortedHiddenRanges) {
    boundaries.add(range.start.clamp(0, source.length).toInt());
    boundaries.add(range.end.clamp(0, source.length).toInt());
  }
  final sortedBoundaries = boundaries.toList()..sort();
  final spans = <TextSpan>[];
  for (var index = 0; index < sortedBoundaries.length - 1; index++) {
    final start = sortedBoundaries[index];
    final end = sortedBoundaries[index + 1];
    if (end <= start) {
      continue;
    }
    final hidden = sortedHiddenRanges.any(
      (range) => range.contains(start, end),
    );
    _HighlightRange? highlight;
    for (final range in sortedRanges) {
      if (range.start <= start && end <= range.end) {
        highlight = range;
        break;
      }
    }
    spans.add(
      TextSpan(
        text: source.substring(start, end),
        style: hidden ? hiddenStyle : highlight?.style,
      ),
    );
  }
  return spans;
}

List<SourceFoldRegion> _normalizedFoldRegions(
  Iterable<SourceFoldRegion> regions,
) {
  final sorted = [...regions]
    ..sort((a, b) => a.hiddenStartOffset.compareTo(b.hiddenStartOffset));
  final normalized = <SourceFoldRegion>[];
  var hiddenUntil = -1;
  for (final region in sorted) {
    if (region.hiddenStartOffset < hiddenUntil) {
      continue;
    }
    normalized.add(region);
    hiddenUntil = region.hiddenEndOffset;
  }
  return normalized;
}
