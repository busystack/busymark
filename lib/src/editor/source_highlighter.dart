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
  bool visualMarkdown = false;

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
    final palette = _SourceSyntaxPalette.fromContext(context);
    final styleOverride = visible ? null : _transparentLayoutStyle;
    if (visible &&
        visualMarkdown &&
        _language == SourceSyntaxLanguage.markdown) {
      return _visualMarkdownTextSpan(source, baseStyle, palette);
    }
    return TextSpan(
      style: baseStyle,
      children: switch (_language) {
        SourceSyntaxLanguage.markdown => _highlightMarkdown(
          source,
          baseStyle,
          palette,
          hiddenRanges,
          styleOverride: styleOverride,
        ),
        SourceSyntaxLanguage.xml => _highlightXml(
          source,
          baseStyle,
          palette,
          hiddenRanges,
          styleOverride: styleOverride,
        ),
        SourceSyntaxLanguage.plain => [
          ..._spansFromRanges(
            source,
            const [],
            hiddenRanges,
            baseStyle,
            styleOverride: styleOverride,
          ),
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
  List<_HiddenRange> hiddenRanges, {
  TextStyle Function(TextStyle style)? styleOverride,
}) {
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

    final heading = RegExp(r'^(\s{0,3}#{1,6}(?:\s+|$))(.*)$').firstMatch(line);
    if (heading != null) {
      final marker = heading.group(1)!;
      final content = heading.group(2)!;
      final level = marker.trim().length;
      if (content.isNotEmpty) {
        _addRange(
          ranges,
          lineStart + marker.length,
          lineEnd,
          _markdownHeadingStyle(baseStyle, level),
        );
      }
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

    _addDelimitedInlineMatches(
      ranges,
      lineStart,
      line,
      RegExp(r'`[^`\n]+`'),
      baseStyle.copyWith(
        fontFamily: 'Ubuntu Mono',
        backgroundColor: palette.punctuation.withValues(alpha: 0.10),
      ),
      openingLength: 1,
      closingLength: 1,
    );
    _addLinkLabelMatches(
      ranges,
      lineStart,
      line,
      RegExp(r'!?\[[^\]\n]+\]\([^\)\n]+\)'),
      baseStyle.copyWith(
        color: palette.link,
        decoration: TextDecoration.underline,
      ),
    );
    _addInlineMatches(
      ranges,
      lineStart,
      line,
      RegExp(r'</?[A-Za-z_][^>\n]*>'),
      baseStyle.copyWith(color: palette.tag),
    );
    _addDelimitedInlineMatches(
      ranges,
      lineStart,
      line,
      RegExp(r'(\*\*[^*\n]+\*\*|__[^_\n]+__)'),
      baseStyle.copyWith(fontWeight: FontWeight.w700),
      openingLength: 2,
      closingLength: 2,
    );
    _addSingleDelimiterInlineMatches(
      ranges,
      lineStart,
      line,
      '*',
      baseStyle.copyWith(fontStyle: FontStyle.italic),
    );
    _addSingleDelimiterInlineMatches(
      ranges,
      lineStart,
      line,
      '_',
      baseStyle.copyWith(fontStyle: FontStyle.italic),
    );
    _addDelimitedInlineMatches(
      ranges,
      lineStart,
      line,
      RegExp(r'~~[^~\n]+~~'),
      baseStyle.copyWith(decoration: TextDecoration.lineThrough),
      openingLength: 2,
      closingLength: 2,
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

  return _spansFromRanges(
    source,
    ranges,
    hiddenRanges,
    baseStyle,
    styleOverride: styleOverride,
  );
}

List<TextSpan> _highlightXml(
  String source,
  TextStyle baseStyle,
  _SourceSyntaxPalette palette,
  List<_HiddenRange> hiddenRanges, {
  TextStyle Function(TextStyle style)? styleOverride,
}) {
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

  return _spansFromRanges(
    source,
    ranges,
    hiddenRanges,
    baseStyle,
    styleOverride: styleOverride,
  );
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

void _addDelimitedInlineMatches(
  List<_HighlightRange> ranges,
  int lineStart,
  String line,
  RegExp pattern,
  TextStyle style, {
  required int openingLength,
  required int closingLength,
}) {
  for (final match in pattern.allMatches(line)) {
    final start = match.start + openingLength;
    final end = match.end - closingLength;
    _addRange(ranges, lineStart + start, lineStart + end, style);
  }
}

void _addLinkLabelMatches(
  List<_HighlightRange> ranges,
  int lineStart,
  String line,
  RegExp pattern,
  TextStyle style,
) {
  for (final match in pattern.allMatches(line)) {
    final image = line.startsWith('![', match.start);
    final labelStart = match.start + (image ? 2 : 1);
    final labelEnd = line.indexOf(']', labelStart);
    if (labelEnd > labelStart && labelEnd <= match.end) {
      _addRange(ranges, lineStart + labelStart, lineStart + labelEnd, style);
    }
  }
}

void _addSingleDelimiterInlineMatches(
  List<_HighlightRange> ranges,
  int lineStart,
  String line,
  String marker,
  TextStyle style,
) {
  var index = 0;
  while (index < line.length) {
    final start = _nextSingleDelimiter(line, marker, index);
    if (start < 0) {
      return;
    }
    final end = _nextSingleDelimiter(line, marker, start + 1);
    if (end <= start + 1) {
      index = start + 1;
      continue;
    }
    _addRange(ranges, lineStart + start + 1, lineStart + end, style);
    index = end + 1;
  }
}

int _nextSingleDelimiter(String line, String marker, int start) {
  var index = line.indexOf(marker, start);
  while (index >= 0) {
    final previousIsMarker = index > 0 && line[index - 1] == marker;
    final nextIsMarker = index + 1 < line.length && line[index + 1] == marker;
    if (!previousIsMarker && !nextIsMarker) {
      return index;
    }
    index = line.indexOf(marker, index + 1);
  }
  return -1;
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
  TextStyle baseStyle, {
  TextStyle Function(TextStyle style)? styleOverride,
}) {
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
    final style = highlight?.style;
    spans.add(
      TextSpan(
        text: source.substring(start, end),
        style: hidden
            ? hiddenStyle
            : style == null
            ? null
            : styleOverride?.call(style) ?? style,
      ),
    );
  }
  return spans;
}

TextSpan _visualMarkdownTextSpan(
  String source,
  TextStyle baseStyle,
  _SourceSyntaxPalette palette,
) {
  final spans = <TextSpan>[];
  final lines = source.split('\n');
  var inFence = false;

  for (var index = 0; index < lines.length; index++) {
    final line = lines[index];
    final fence = RegExp(r'^\s*(```|~~~)').firstMatch(line);
    if (fence != null) {
      inFence = !inFence;
      spans.add(
        TextSpan(
          text: line,
          style: baseStyle.copyWith(
            color: palette.keyword,
            fontFamily: 'Ubuntu Mono',
          ),
        ),
      );
    } else if (inFence) {
      spans.add(
        TextSpan(
          text: line,
          style: baseStyle.copyWith(
            color: palette.literal,
            fontFamily: 'Ubuntu Mono',
            backgroundColor: palette.punctuation.withValues(alpha: 0.10),
          ),
        ),
      );
    } else {
      spans.addAll(_visualMarkdownLineSpans(line, baseStyle, palette));
    }
    if (index < lines.length - 1) {
      spans.add(TextSpan(text: '\n', style: baseStyle));
    }
  }

  return TextSpan(style: baseStyle, children: spans);
}

List<TextSpan> _visualMarkdownLineSpans(
  String line,
  TextStyle baseStyle,
  _SourceSyntaxPalette palette,
) {
  final heading = RegExp(r'^(\s{0,3}#{1,6}\s+)(.*)$').firstMatch(line);
  if (heading != null) {
    final marker = heading.group(1)!;
    final content = heading.group(2)!;
    final level = marker.trim().length;
    return [
      TextSpan(text: marker, style: baseStyle),
      ..._visualInlineSpans(
        content,
        _markdownHeadingStyle(baseStyle, level),
        palette,
      ),
    ];
  }

  final list = RegExp(
    r'^(\s{0,8}(?:[-*+]|\d+[.)])\s+)(\[[ xX]\]\s+)?(.*)$',
  ).firstMatch(line);
  if (list != null) {
    final marker = list.group(1)!;
    final task = list.group(2);
    final text = list.group(3)!;
    return [
      TextSpan(
        text: marker,
        style: baseStyle.copyWith(color: palette.punctuation),
      ),
      if (task != null)
        TextSpan(
          text: task,
          style: baseStyle.copyWith(color: palette.keyword),
        ),
      ..._visualInlineSpans(text, baseStyle, palette),
    ];
  }

  final quote = RegExp(r'^(\s{0,3}>\s?)(.*)$').firstMatch(line);
  if (quote != null) {
    return [
      TextSpan(
        text: quote.group(1)!,
        style: baseStyle.copyWith(color: palette.punctuation),
      ),
      ..._visualInlineSpans(
        quote.group(2)!,
        baseStyle.copyWith(color: palette.comment),
        palette,
      ),
    ];
  }

  return _visualInlineSpans(line, baseStyle, palette);
}

List<TextSpan> _visualInlineSpans(
  String source,
  TextStyle baseStyle,
  _SourceSyntaxPalette palette,
) {
  final spans = <TextSpan>[];
  var index = 0;

  void addText(String text, [TextStyle? style]) {
    if (text.isEmpty) {
      return;
    }
    spans.add(TextSpan(text: text, style: style ?? baseStyle));
  }

  while (index < source.length) {
    if (source.startsWith('\\', index) && index + 1 < source.length) {
      addText(source[index]);
      addText(source[index + 1]);
      index += 2;
      continue;
    }

    final code = _delimitedInline(source, index, '`');
    if (code != null) {
      addText(code.opening);
      addText(
        code.inner,
        baseStyle.copyWith(
          fontFamily: 'Ubuntu Mono',
          backgroundColor: palette.punctuation.withValues(alpha: 0.10),
        ),
      );
      addText(code.closing);
      index = code.end;
      continue;
    }

    final link = _visualLinkAt(source, index);
    if (link != null) {
      addText(link.opening);
      addText(
        link.label,
        baseStyle.copyWith(
          color: link.image ? palette.comment : palette.link,
          decoration: link.image ? null : TextDecoration.underline,
        ),
      );
      addText(link.closing);
      index = link.end;
      continue;
    }

    final strong =
        _delimitedInline(source, index, '**') ??
        _delimitedInline(source, index, '__');
    if (strong != null) {
      addText(strong.opening);
      spans.addAll(
        _visualInlineSpans(
          strong.inner,
          baseStyle.copyWith(fontWeight: FontWeight.w700),
          palette,
        ),
      );
      addText(strong.closing);
      index = strong.end;
      continue;
    }

    final strike = _delimitedInline(source, index, '~~');
    if (strike != null) {
      addText(strike.opening);
      spans.addAll(
        _visualInlineSpans(
          strike.inner,
          baseStyle.copyWith(decoration: TextDecoration.lineThrough),
          palette,
        ),
      );
      addText(strike.closing);
      index = strike.end;
      continue;
    }

    final emphasis =
        _delimitedInline(source, index, '*') ??
        _delimitedInline(source, index, '_');
    if (emphasis != null) {
      addText(emphasis.opening);
      spans.addAll(
        _visualInlineSpans(
          emphasis.inner,
          baseStyle.copyWith(fontStyle: FontStyle.italic),
          palette,
        ),
      );
      addText(emphasis.closing);
      index = emphasis.end;
      continue;
    }

    final next = _nextVisualMarkerIndex(source, index + 1);
    addText(source.substring(index, next));
    index = next;
  }

  return spans;
}

int _nextVisualMarkerIndex(String source, int start) {
  var next = source.length;
  for (final marker in const [
    '\\',
    '`',
    '![',
    '[',
    '**',
    '__',
    '~~',
    '*',
    '_',
  ]) {
    final found = source.indexOf(marker, start);
    if (found >= 0 && found < next) {
      next = found;
    }
  }
  return next;
}

TextStyle _markdownHeadingStyle(TextStyle baseStyle, int level) {
  final scale = switch (level) {
    1 => 1.55,
    2 => 1.36,
    3 => 1.22,
    4 => 1.12,
    5 => 1.04,
    _ => 0.98,
  };
  return baseStyle.copyWith(
    fontSize: (baseStyle.fontSize ?? 14) * scale,
    fontWeight: FontWeight.w700,
  );
}

TextStyle _transparentLayoutStyle(TextStyle style) {
  return style.copyWith(
    color: Colors.transparent,
    backgroundColor: Colors.transparent,
    decorationColor: Colors.transparent,
  );
}

_VisualDelimitedInline? _delimitedInline(
  String source,
  int start,
  String marker,
) {
  if (!source.startsWith(marker, start)) {
    return null;
  }
  final contentStart = start + marker.length;
  final end = source.indexOf(marker, contentStart);
  if (end <= contentStart) {
    return null;
  }
  return _VisualDelimitedInline(
    opening: marker,
    inner: source.substring(contentStart, end),
    closing: marker,
    end: end + marker.length,
  );
}

_VisualLink? _visualLinkAt(String source, int start) {
  final image = source.startsWith('![', start);
  if (!image && !source.startsWith('[', start)) {
    return null;
  }
  final labelStart = start + (image ? 2 : 1);
  final labelEnd = source.indexOf(']', labelStart);
  if (labelEnd < 0 ||
      labelEnd + 1 >= source.length ||
      source[labelEnd + 1] != '(') {
    return null;
  }
  final destinationEnd = source.indexOf(')', labelEnd + 2);
  if (destinationEnd < 0) {
    return null;
  }
  return _VisualLink(
    image: image,
    opening: source.substring(start, labelStart),
    label: source.substring(labelStart, labelEnd),
    closing: source.substring(labelEnd, destinationEnd + 1),
    end: destinationEnd + 1,
  );
}

class _VisualDelimitedInline {
  const _VisualDelimitedInline({
    required this.opening,
    required this.inner,
    required this.closing,
    required this.end,
  });

  final String opening;
  final String inner;
  final String closing;
  final int end;
}

class _VisualLink {
  const _VisualLink({
    required this.image,
    required this.opening,
    required this.label,
    required this.closing,
    required this.end,
  });

  final bool image;
  final String opening;
  final String label;
  final String closing;
  final int end;
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
