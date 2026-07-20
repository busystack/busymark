import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/busymark_design.dart';
import '../markdown/markdown_fence.dart';
import 'source/source_document.dart';
import 'source/source_hidden_ranges.dart';
import 'source/source_search.dart';
import 'source_folding.dart';
import 'source_language.dart';

export 'source_language.dart';

TextSpan buildBusyMarkReadOnlySourceTextSpan({
  required BuildContext context,
  required String source,
  required SourceSyntaxLanguage language,
  TextStyle? style,
  Color? foreground,
}) {
  final colors = BusyMarkSurfaceColors.of(context);
  final baseStyle = (style ?? DefaultTextStyle.of(context).style).copyWith(
    color: foreground ?? colors.foreground,
    backgroundColor: BusyMarkLinuxPalette.transparent,
  );
  if (source.isEmpty || source.length > 300000) {
    return TextSpan(text: source, style: baseStyle);
  }
  final palette = BusyMarkSyntaxColors.of(context);
  return TextSpan(
    style: baseStyle,
    children: switch (language) {
      SourceSyntaxLanguage.markdown => _highlightMarkdown(
        source,
        baseStyle,
        palette,
        const <_HiddenRange>[],
      ),
      SourceSyntaxLanguage.xml => _highlightXml(
        source,
        baseStyle,
        palette,
        const <_HiddenRange>[],
      ),
      SourceSyntaxLanguage.plain => _spansFromRanges(
        source,
        const <_HighlightRange>[],
        const <_HiddenRange>[],
        baseStyle,
      ),
    },
  );
}

class BusyMarkSourceEditingController extends TextEditingController {
  BusyMarkSourceEditingController({
    String? text,
    SourceSyntaxLanguage language = SourceSyntaxLanguage.markdown,
    this.onFullTextChanged,
  }) : _language = language,
       _document = SourceDocument(fullText: text ?? '') {
    super.value = TextEditingValue(text: _document.visibleText);
  }

  SourceSyntaxLanguage _language;
  List<SourceFoldRegion> _foldedRegions = const [];
  SourceDocument _document;
  SourceVisibleEdit? lastVisibleEdit;
  SourceSearchResult _searchResult = SourceSearchResult.empty;
  void Function(String fullText, SourceVisibleEdit? edit)? onFullTextChanged;
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

  SourceDocument get document => _document;

  bool get sourceFeaturesDegraded => super.text.length > 300000;

  SourceSearchResult get searchResult => _searchResult;

  String get fullText => _document.fullText;

  set fullText(String value) {
    setFullText(value);
  }

  @override
  set text(String value) {
    setFullText(value);
  }

  TextSelection get fullSelection {
    return _document.visibleSelectionToFullSelection(selection);
  }

  set fullSelection(TextSelection value) {
    selection = _document.fullSelectionToVisibleSelection(value);
  }

  int fullOffsetToVisibleOffset(int offset) {
    return _document.fullOffsetToVisibleOffset(offset);
  }

  int visibleOffsetToFullOffset(
    int offset, {
    SourceHiddenAffinity affinity = SourceHiddenAffinity.downstream,
  }) {
    return _document.visibleOffsetToFullOffset(offset, affinity: affinity);
  }

  void setFullText(String value, {TextSelection? fullSelection}) {
    final selectionSnapshot = fullSelection ?? this.fullSelection;
    _document = _createDocument(value, _foldedRegions);
    lastVisibleEdit = null;
    super.value = TextEditingValue(
      text: _document.visibleText,
      selection: _document.fullSelectionToVisibleSelection(selectionSnapshot),
    );
  }

  void setFullEditingValue(TextEditingValue value) {
    _foldedRegions = _preserveFoldedRegionsForFullReplacement(
      _foldedRegions,
      _document.fullText,
      value.text,
    );
    _document = _createDocument(value.text, _foldedRegions);
    lastVisibleEdit = null;
    super.value = TextEditingValue(
      text: _document.visibleText,
      selection: _document.fullSelectionToVisibleSelection(value.selection),
    );
    onFullTextChanged?.call(_document.fullText, null);
  }

  void setFoldedRegions(Iterable<SourceFoldRegion> regions) {
    final fullSelectionSnapshot = fullSelection;
    final normalized = _normalizedFoldRegions(regions);
    if (_foldRegionsEqual(_foldedRegions, normalized)) {
      return;
    }
    _foldedRegions = normalized;
    _document = _createDocument(_document.fullText, _foldedRegions);
    super.value = TextEditingValue(
      text: _document.visibleText,
      selection: _document.fullSelectionToVisibleSelection(
        fullSelectionSnapshot,
      ),
    );
  }

  void clearFoldedRegions() {
    if (_foldedRegions.isEmpty) {
      return;
    }
    final fullSelectionSnapshot = fullSelection;
    _foldedRegions = const [];
    _document = _createDocument(_document.fullText, _foldedRegions);
    super.value = TextEditingValue(
      text: _document.visibleText,
      selection: _document.fullSelectionToVisibleSelection(
        fullSelectionSnapshot,
      ),
    );
  }

  void setSearchResult(SourceSearchResult result) {
    if (_searchResult == result) {
      return;
    }
    _searchResult = result;
    notifyListeners();
  }

  @override
  set value(TextEditingValue newValue) {
    final hasTextChanged = newValue.text != super.value.text;
    if (!hasTextChanged) {
      super.value = newValue;
      return;
    }

    final oldDocument = _document;
    final edit = oldDocument.describeVisibleEdit(newValue.text);
    final nextFullText = oldDocument.fullText.replaceRange(
      edit.fullStart,
      edit.fullEnd,
      edit.replacement,
    );
    final affectedKeys = {
      for (final range in oldDocument.hiddenRanges.hiddenRangesIntersecting(
        edit.fullStart,
        edit.fullEnd,
      ))
        if (range.key != null) range.key!,
    };
    _foldedRegions = _preserveFoldedRegionsAfterVisibleEdit(
      _foldedRegions,
      edit,
      affectedKeys,
    );
    _document = _createDocument(nextFullText, _foldedRegions);
    lastVisibleEdit = edit;
    final selection = TextSelection(
      baseOffset: newValue.selection.baseOffset
          .clamp(0, _document.visibleText.length)
          .toInt(),
      extentOffset: newValue.selection.extentOffset
          .clamp(0, _document.visibleText.length)
          .toInt(),
      affinity: newValue.selection.affinity,
      isDirectional: newValue.selection.isDirectional,
    );
    super.value = TextEditingValue(
      text: _document.visibleText,
      selection: selection,
      composing: TextRange.empty,
    );
    onFullTextChanged?.call(_document.fullText, edit);
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
      hideCollapsedStartLines: !renderText,
    );
  }

  TextSpan buildSourceTextSpan({
    required BuildContext context,
    TextStyle? style,
    bool visible = true,
    bool hideCollapsedStartLines = false,
  }) {
    final colors = BusyMarkSurfaceColors.of(context);
    final baseStyle = (style ?? DefaultTextStyle.of(context).style).copyWith(
      color: visible ? colors.foreground : BusyMarkLinuxPalette.transparent,
      backgroundColor: BusyMarkLinuxPalette.transparent,
    );
    final source = super.text;
    if (source.isEmpty || source.length > 300000) {
      return TextSpan(text: source, style: baseStyle);
    }
    final hiddenRanges = hideCollapsedStartLines
        ? _collapsedStartLineHiddenRanges()
        : const <_HiddenRange>[];
    final palette = BusyMarkSyntaxColors.of(context);
    final styleOverride = visible ? null : _transparentLayoutStyle;
    final searchRanges = visible
        ? _searchHighlightRanges(source, baseStyle, colors, _searchResult)
        : const <_HighlightRange>[];
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
          overlayRanges: searchRanges,
          styleOverride: styleOverride,
        ),
        SourceSyntaxLanguage.xml => _highlightXml(
          source,
          baseStyle,
          palette,
          hiddenRanges,
          overlayRanges: searchRanges,
          styleOverride: styleOverride,
        ),
        SourceSyntaxLanguage.plain => [
          ..._spansFromRanges(
            source,
            searchRanges,
            hiddenRanges,
            baseStyle,
            styleOverride: styleOverride,
          ),
        ],
      },
    );
  }

  SourceDocument _createDocument(
    String fullText,
    Iterable<SourceFoldRegion> foldedRegions,
  ) {
    return SourceDocument(
      fullText: fullText,
      hiddenRanges: SourceHiddenRanges(
        ranges: [
          for (final region in foldedRegions)
            SourceHiddenRange(
              start: region.hiddenStartOffset,
              end: region.hiddenEndOffset,
              key: region.key,
            ),
        ],
        textLength: fullText.length,
      ),
    );
  }

  List<_HiddenRange> _collapsedStartLineHiddenRanges() {
    final ranges = <_HiddenRange>[];
    for (final region in _foldedRegions) {
      final line = _document.lineIndex.lineAt(region.startLine);
      if (line.endOffset <= line.startOffset) {
        continue;
      }
      final visibleStart = _document.fullOffsetToVisibleOffset(
        line.startOffset,
      );
      final visibleEnd = _document.fullOffsetToVisibleOffset(line.endOffset);
      if (visibleEnd > visibleStart) {
        ranges.add(
          _HiddenRange(visibleStart, visibleEnd, preserveLayout: true),
        );
      }
    }
    return ranges;
  }
}

class _HighlightRange {
  const _HighlightRange(this.start, this.end, this.style, {this.priority = 0});

  final int start;
  final int end;
  final TextStyle style;
  final int priority;

  bool overlaps(int otherStart, int otherEnd) {
    return start < otherEnd && otherStart < end;
  }
}

class _HiddenRange {
  const _HiddenRange(this.start, this.end, {this.preserveLayout = false});

  final int start;
  final int end;
  final bool preserveLayout;

  bool contains(int otherStart, int otherEnd) {
    return start <= otherStart && otherEnd <= end;
  }
}

List<TextSpan> _highlightMarkdown(
  String source,
  TextStyle baseStyle,
  BusyMarkSyntaxColors palette,
  List<_HiddenRange> hiddenRanges, {
  Iterable<_HighlightRange> overlayRanges = const [],
  TextStyle Function(TextStyle style)? styleOverride,
}) {
  final ranges = <_HighlightRange>[];
  final blockMarkerStyle = baseStyle.copyWith(color: palette.keyword);
  final inlineMarkerStyle = baseStyle.copyWith(color: palette.punctuation);
  final linkDestinationStyle = baseStyle.copyWith(color: palette.string);
  var offset = 0;
  MarkdownFence? openFence;
  var fenceLanguage = '';
  var inFrontMatter = source.startsWith('---\n') || source == '---';

  for (final line in source.split('\n')) {
    final lineStart = offset;
    final lineEnd = lineStart + line.length;
    final trimmed = line.trimLeft();

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

    final activeFence = openFence;
    if (activeFence != null) {
      if (!activeFence.closes(line)) {
        final highlighted = _addFencedCodeLineRanges(
          ranges,
          lineStart,
          line,
          fenceLanguage,
          baseStyle,
          palette,
        );
        if (!highlighted && line.isNotEmpty) {
          _addRange(
            ranges,
            lineStart,
            lineEnd,
            baseStyle.copyWith(color: palette.literal),
          );
        }
      } else {
        _addRange(
          ranges,
          lineStart,
          lineEnd,
          baseStyle.copyWith(color: palette.keyword),
        );
        openFence = null;
        fenceLanguage = '';
      }
      offset = lineEnd + 1;
      continue;
    }

    final openingFence = MarkdownFence.parse(line);
    if (openingFence != null) {
      _addRange(
        ranges,
        lineStart,
        lineEnd,
        baseStyle.copyWith(color: palette.keyword),
      );
      openFence = openingFence;
      fenceLanguage = _normalizedFenceLanguage(openingFence.language ?? '');
      offset = lineEnd + 1;
      continue;
    }

    final heading = RegExp(r'^(\s{0,3}#{1,6}(?:\s+|$))(.*)$').firstMatch(line);
    if (heading != null) {
      final marker = heading.group(1)!;
      final content = heading.group(2)!;
      final level = marker.trim().length;
      _addRange(ranges, lineStart, lineStart + marker.length, blockMarkerStyle);
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
        blockMarkerStyle,
      );
    }

    final listMarker = RegExp(r'^\s*(?:[-*+]|\d+\.)\s+').firstMatch(line);
    if (listMarker != null) {
      _addRange(
        ranges,
        lineStart,
        lineStart + listMarker.end,
        blockMarkerStyle,
      );
    }

    final taskMarker = RegExp(
      r'^\s*(?:[-*+]|\d+\.)\s+(\[[ xX]\])\s+',
    ).firstMatch(line);
    if (taskMarker != null) {
      final checkbox = taskMarker.group(1)!;
      final checkboxStart = line.indexOf(checkbox, listMarker?.end ?? 0);
      if (checkboxStart >= 0) {
        _addRange(
          ranges,
          lineStart + checkboxStart,
          lineStart + checkboxStart + checkbox.length,
          inlineMarkerStyle,
        );
      }
    }

    final thematicBreak = RegExp(
      r'^\s{0,3}(?:(?:[-*_])\s*){3,}$',
    ).firstMatch(line);
    if (thematicBreak != null) {
      _addRange(ranges, lineStart, lineEnd, blockMarkerStyle);
    }

    _addDelimitedInlineMatches(
      ranges,
      lineStart,
      line,
      RegExp(r'`[^`\n]+`'),
      baseStyle.copyWith(
        fontFamily: BusyMarkTypography.monoFontFamily,
        backgroundColor: palette.punctuation.withValues(
          alpha: BusyMarkAlpha.sourceSyntaxBackground,
        ),
      ),
      openingLength: 1,
      closingLength: 1,
      markerStyle: inlineMarkerStyle,
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
      inlineMarkerStyle,
      linkDestinationStyle,
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
      markerStyle: inlineMarkerStyle,
    );
    _addSingleDelimiterInlineMatches(
      ranges,
      lineStart,
      line,
      '*',
      baseStyle.copyWith(fontStyle: FontStyle.italic),
      markerStyle: inlineMarkerStyle,
    );
    _addSingleDelimiterInlineMatches(
      ranges,
      lineStart,
      line,
      '_',
      baseStyle.copyWith(fontStyle: FontStyle.italic),
      markerStyle: inlineMarkerStyle,
    );
    _addDelimitedInlineMatches(
      ranges,
      lineStart,
      line,
      RegExp(r'~~[^~\n]+~~'),
      baseStyle.copyWith(decoration: TextDecoration.lineThrough),
      openingLength: 2,
      closingLength: 2,
      markerStyle: inlineMarkerStyle,
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

  ranges.addAll(overlayRanges);
  return _spansFromRanges(
    source,
    ranges,
    hiddenRanges,
    baseStyle,
    styleOverride: styleOverride,
  );
}

bool _addFencedCodeLineRanges(
  List<_HighlightRange> ranges,
  int lineStart,
  String line,
  String rawLanguage,
  TextStyle baseStyle,
  BusyMarkSyntaxColors palette,
) {
  final before = ranges.length;
  final language = _normalizedFenceLanguage(rawLanguage);
  if (_xmlCodeLanguages.contains(language)) {
    _addXmlRanges(ranges, line, lineStart, baseStyle, palette);
    return ranges.length > before;
  }

  final commentStyle = baseStyle.copyWith(color: palette.comment);
  final keywordStyle = baseStyle.copyWith(color: palette.keyword);
  final stringStyle = baseStyle.copyWith(color: palette.string);
  final literalStyle = baseStyle.copyWith(color: palette.literal);
  final attributeStyle = baseStyle.copyWith(color: palette.attribute);
  final tagStyle = baseStyle.copyWith(color: palette.tag);
  final punctuationStyle = baseStyle.copyWith(color: palette.punctuation);

  if (language == 'json') {
    _addInlineMatches(
      ranges,
      lineStart,
      line,
      RegExp(r'"(?:\\.|[^"\\])*"(?=\s*:)'),
      attributeStyle,
    );
  }

  _addCodeStringRanges(ranges, lineStart, line, language, stringStyle);
  _addCodeCommentRanges(ranges, lineStart, line, language, commentStyle);

  _addInlineMatches(
    ranges,
    lineStart,
    line,
    RegExp(r'\b\d+(?:\.\d+)?(?:[eE][+-]?\d+)?\b'),
    literalStyle,
  );

  final keywords = _codeKeywords(language);
  for (final word in RegExp(r'\b[A-Za-z_][A-Za-z0-9_]*\b').allMatches(line)) {
    final token = word.group(0)!;
    final style = _codeLiterals.contains(token.toLowerCase())
        ? literalStyle
        : keywords.contains(token)
        ? keywordStyle
        : null;
    if (style != null) {
      _addRange(ranges, lineStart + word.start, lineStart + word.end, style);
    }
  }

  for (final type in RegExp(r'\b[A-Z][A-Za-z0-9_]*\b').allMatches(line)) {
    _addRange(ranges, lineStart + type.start, lineStart + type.end, tagStyle);
  }

  for (final function in RegExp(
    r'\b[A-Za-z_][A-Za-z0-9_]*\b(?=\s*\()',
  ).allMatches(line)) {
    final token = function.group(0)!;
    if (!keywords.contains(token) &&
        !_codeLiterals.contains(token.toLowerCase())) {
      _addRange(
        ranges,
        lineStart + function.start,
        lineStart + function.end,
        attributeStyle,
      );
    }
  }

  _addInlineMatches(
    ranges,
    lineStart,
    line,
    RegExp(r'[{}()\[\],.;:+\-*/%=<>!&|?]+'),
    punctuationStyle,
  );

  return ranges.length > before;
}

String _normalizedFenceLanguage(String value) {
  var language = value.trim().toLowerCase();
  if (language.startsWith('language-')) {
    language = language.substring('language-'.length);
  }
  return switch (language) {
    'c++' => 'cpp',
    'c#' || 'cs' => 'csharp',
    'htm' => 'html',
    'js' || 'jsx' => 'javascript',
    'kt' => 'kotlin',
    'py' => 'python',
    'sh' || 'bash' || 'zsh' => 'shell',
    'ts' || 'tsx' => 'typescript',
    'yml' => 'yaml',
    'topic' => 'xml',
    _ => language,
  };
}

void _addCodeStringRanges(
  List<_HighlightRange> ranges,
  int lineStart,
  String line,
  String language,
  TextStyle style,
) {
  final pattern = language == 'json'
      ? RegExp(r'"(?:\\.|[^"\\])*"')
      : RegExp(
          "\"(?:\\\\.|[^\"\\\\])*\"|'(?:\\\\.|[^'\\\\])*'|`(?:\\\\.|[^`\\\\])*`",
        );
  _addInlineMatches(ranges, lineStart, line, pattern, style);
}

void _addCodeCommentRanges(
  List<_HighlightRange> ranges,
  int lineStart,
  String line,
  String language,
  TextStyle style,
) {
  for (final block in RegExp(r'/\*.*?(?:\*/|$)').allMatches(line)) {
    _addRange(ranges, lineStart + block.start, lineStart + block.end, style);
  }

  for (final marker in _lineCommentMarkers(language)) {
    var searchStart = 0;
    while (searchStart < line.length) {
      final index = line.indexOf(marker, searchStart);
      if (index < 0) {
        break;
      }
      final globalIndex = lineStart + index;
      if (_positionInsideRange(ranges, globalIndex)) {
        searchStart = index + marker.length;
        continue;
      }
      _addRange(ranges, globalIndex, lineStart + line.length, style);
      break;
    }
  }
}

List<String> _lineCommentMarkers(String language) {
  return switch (language) {
    'json' || 'xml' || 'html' => const [],
    'python' || 'ruby' || 'shell' || 'yaml' => const ['#'],
    'sql' => const ['--'],
    _ => const ['//'],
  };
}

Set<String> _codeKeywords(String language) {
  return switch (language) {
    'dart' => _dartKeywords,
    'python' => _pythonKeywords,
    'shell' => _shellKeywords,
    'yaml' => _yamlKeywords,
    _ => _cLikeKeywords,
  };
}

bool _positionInsideRange(List<_HighlightRange> ranges, int offset) {
  for (final range in ranges) {
    if (range.start <= offset && offset < range.end) {
      return true;
    }
  }
  return false;
}

const _xmlCodeLanguages = {'html', 'xml'};

const _codeLiterals = {'false', 'nil', 'none', 'null', 'true', 'undefined'};

const _cLikeKeywords = {
  'abstract',
  'as',
  'async',
  'await',
  'break',
  'case',
  'catch',
  'class',
  'const',
  'continue',
  'default',
  'do',
  'else',
  'enum',
  'export',
  'extends',
  'final',
  'finally',
  'for',
  'from',
  'function',
  'if',
  'implements',
  'import',
  'in',
  'interface',
  'is',
  'let',
  'new',
  'package',
  'private',
  'protected',
  'public',
  'return',
  'static',
  'switch',
  'throw',
  'try',
  'type',
  'var',
  'void',
  'while',
};

const _dartKeywords = {
  ..._cLikeKeywords,
  'assert',
  'covariant',
  'deferred',
  'dynamic',
  'extension',
  'external',
  'factory',
  'get',
  'late',
  'library',
  'mixin',
  'operator',
  'part',
  'required',
  'sealed',
  'set',
  'show',
  'sync',
  'typedef',
  'with',
  'yield',
};

const _pythonKeywords = {
  'and',
  'as',
  'assert',
  'async',
  'await',
  'break',
  'class',
  'continue',
  'def',
  'del',
  'elif',
  'else',
  'except',
  'finally',
  'for',
  'from',
  'global',
  'if',
  'import',
  'in',
  'is',
  'lambda',
  'nonlocal',
  'not',
  'or',
  'pass',
  'raise',
  'return',
  'try',
  'while',
  'with',
  'yield',
};

const _shellKeywords = {
  'case',
  'do',
  'done',
  'elif',
  'else',
  'esac',
  'fi',
  'for',
  'function',
  'if',
  'in',
  'select',
  'then',
  'until',
  'while',
};

const _yamlKeywords = {'false', 'no', 'null', 'off', 'on', 'true', 'yes'};

List<TextSpan> _highlightXml(
  String source,
  TextStyle baseStyle,
  BusyMarkSyntaxColors palette,
  List<_HiddenRange> hiddenRanges, {
  Iterable<_HighlightRange> overlayRanges = const [],
  TextStyle Function(TextStyle style)? styleOverride,
}) {
  final ranges = <_HighlightRange>[];
  _addXmlRanges(ranges, source, 0, baseStyle, palette);
  ranges.addAll(overlayRanges);

  return _spansFromRanges(
    source,
    ranges,
    hiddenRanges,
    baseStyle,
    styleOverride: styleOverride,
  );
}

void _addXmlRanges(
  List<_HighlightRange> ranges,
  String source,
  int sourceOffset,
  TextStyle baseStyle,
  BusyMarkSyntaxColors palette,
) {
  final commentStyle = baseStyle.copyWith(color: palette.comment);
  final tagStyle = baseStyle.copyWith(color: palette.tag);
  final attributeStyle = baseStyle.copyWith(color: palette.attribute);
  final stringStyle = baseStyle.copyWith(color: palette.string);
  final punctuationStyle = baseStyle.copyWith(color: palette.punctuation);

  for (final comment in RegExp(r'<!--[\s\S]*?-->').allMatches(source)) {
    _addRange(
      ranges,
      sourceOffset + comment.start,
      sourceOffset + comment.end,
      commentStyle,
    );
  }

  for (final tag in RegExp(r'</?[^>]+/?>').allMatches(source)) {
    final text = tag.group(0)!;
    if (text.startsWith('<!--')) {
      continue;
    }
    _addRange(
      ranges,
      sourceOffset + tag.start,
      sourceOffset + tag.start + 1,
      punctuationStyle,
    );
    if (text.startsWith('</')) {
      _addRange(
        ranges,
        sourceOffset + tag.start + 1,
        sourceOffset + tag.start + 2,
        punctuationStyle,
      );
    }
    _addRange(
      ranges,
      sourceOffset + tag.end - 1,
      sourceOffset + tag.end,
      punctuationStyle,
    );
    if (text.endsWith('/>') && tag.end - 2 > tag.start) {
      _addRange(
        ranges,
        sourceOffset + tag.end - 2,
        sourceOffset + tag.end - 1,
        punctuationStyle,
      );
    }

    final name = RegExp(r'^</?\s*([A-Za-z_][\w:.-]*)').firstMatch(text);
    if (name != null) {
      final nameText = name.group(1)!;
      final nameOffset = text.indexOf(nameText, name.start);
      if (nameOffset >= 0) {
        _addRange(
          ranges,
          sourceOffset + tag.start + nameOffset,
          sourceOffset + tag.start + nameOffset + nameText.length,
          tagStyle,
        );
      }
    }

    for (final attr in RegExp(
      r'([A-Za-z_:][\w:.-]*)(?=\s*=)',
    ).allMatches(text)) {
      _addRange(
        ranges,
        sourceOffset + tag.start + attr.start,
        sourceOffset + tag.start + attr.end,
        attributeStyle,
      );
    }
    for (final literal in RegExp("\"[^\"\\n]*\"|'[^'\\n]*'").allMatches(text)) {
      _addRange(
        ranges,
        sourceOffset + tag.start + literal.start,
        sourceOffset + tag.start + literal.end,
        stringStyle,
      );
    }
  }
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
  TextStyle? markerStyle,
}) {
  for (final match in pattern.allMatches(line)) {
    final start = match.start + openingLength;
    final end = match.end - closingLength;
    if (markerStyle != null) {
      _addRange(
        ranges,
        lineStart + match.start,
        lineStart + start,
        markerStyle,
      );
      _addRange(ranges, lineStart + end, lineStart + match.end, markerStyle);
    }
    _addRange(ranges, lineStart + start, lineStart + end, style);
  }
}

void _addLinkLabelMatches(
  List<_HighlightRange> ranges,
  int lineStart,
  String line,
  RegExp pattern,
  TextStyle labelStyle,
  TextStyle markerStyle,
  TextStyle destinationStyle,
) {
  for (final match in pattern.allMatches(line)) {
    final image = line.startsWith('![', match.start);
    final labelStart = match.start + (image ? 2 : 1);
    final labelEnd = line.indexOf(']', labelStart);
    if (labelEnd > labelStart && labelEnd <= match.end) {
      final destinationStart = labelEnd + 2;
      final destinationEnd = match.end - 1;
      _addRange(
        ranges,
        lineStart + match.start,
        lineStart + labelStart,
        markerStyle,
      );
      _addRange(
        ranges,
        lineStart + labelStart,
        lineStart + labelEnd,
        labelStyle,
      );
      if (destinationStart <= destinationEnd && destinationEnd <= match.end) {
        _addRange(
          ranges,
          lineStart + labelEnd,
          lineStart + destinationStart,
          markerStyle,
        );
        _addRange(
          ranges,
          lineStart + destinationStart,
          lineStart + destinationEnd,
          destinationStyle,
        );
        _addRange(
          ranges,
          lineStart + destinationEnd,
          lineStart + match.end,
          markerStyle,
        );
      }
    }
  }
}

void _addSingleDelimiterInlineMatches(
  List<_HighlightRange> ranges,
  int lineStart,
  String line,
  String marker,
  TextStyle style, {
  TextStyle? markerStyle,
}) {
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
    if (markerStyle != null) {
      _addRange(ranges, lineStart + start, lineStart + start + 1, markerStyle);
      _addRange(ranges, lineStart + end, lineStart + end + 1, markerStyle);
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
  TextStyle style, {
  int priority = 0,
}) {
  if (start < 0 || end <= start) {
    return;
  }
  ranges.add(_HighlightRange(start, end, style, priority: priority));
}

List<_HighlightRange> _searchHighlightRanges(
  String source,
  TextStyle baseStyle,
  BusyMarkSurfaceColors colors,
  SourceSearchResult result,
) {
  if (source.isEmpty || result.matches.isEmpty) {
    return const [];
  }
  final ranges = <_HighlightRange>[];
  final matchBackground = Color.alphaBlend(
    BusyMarkLinuxPalette.yellow.withValues(alpha: 0.32),
    colors.view,
  );
  final currentBackground = Color.alphaBlend(
    colors.controlActive.withValues(alpha: 0.42),
    colors.view,
  );
  final matchStyle = baseStyle.copyWith(backgroundColor: matchBackground);
  final currentStyle = baseStyle.copyWith(backgroundColor: currentBackground);
  final currentIndex = result.currentMatchIndex;
  for (final (index, match) in result.matches.indexed) {
    if (match.hidden || match.visibleEnd <= match.visibleStart) {
      continue;
    }
    ranges.add(
      _HighlightRange(
        match.visibleStart.clamp(0, source.length).toInt(),
        match.visibleEnd.clamp(0, source.length).toInt(),
        index == currentIndex ? currentStyle : matchStyle,
        priority: index == currentIndex ? 100 : 90,
      ),
    );
  }
  return ranges;
}

List<TextSpan> _spansFromRanges(
  String source,
  List<_HighlightRange> ranges,
  List<_HiddenRange> hiddenRanges,
  TextStyle baseStyle, {
  TextStyle Function(TextStyle style)? styleOverride,
}) {
  final sortedRanges = [...ranges]
    ..sort((a, b) {
      final start = a.start.compareTo(b.start);
      if (start != 0) {
        return start;
      }
      return a.priority.compareTo(b.priority);
    });
  final sortedHiddenRanges = [...hiddenRanges]
    ..sort((a, b) => a.start.compareTo(b.start));
  final hiddenStyle = baseStyle.copyWith(
    color: BusyMarkLinuxPalette.transparent,
    fontSize: BusyMarkTypography.hiddenLayoutFontSize,
    height: BusyMarkTypography.hiddenLayoutHeight,
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
    _HiddenRange? hiddenRange;
    for (final range in sortedHiddenRanges) {
      if (range.contains(start, end)) {
        hiddenRange = range;
        break;
      }
    }
    final highlights = <_HighlightRange>[];
    for (final range in sortedRanges) {
      if (range.start <= start && end <= range.end) {
        highlights.add(range);
      }
    }
    highlights.sort((a, b) => a.priority.compareTo(b.priority));
    final style = _mergeHighlightStyles(baseStyle, highlights);
    final visibleStyle = style == null
        ? baseStyle
        : styleOverride?.call(style) ?? style;
    spans.add(
      TextSpan(
        text: source.substring(start, end),
        style: hiddenRange == null
            ? style == null
                  ? null
                  : visibleStyle
            : hiddenRange.preserveLayout
            ? _transparentLayoutStyle(baseStyle)
            : hiddenStyle,
      ),
    );
  }
  return spans;
}

TextStyle? _mergeHighlightStyles(
  TextStyle baseStyle,
  List<_HighlightRange> highlights,
) {
  if (highlights.isEmpty) {
    return null;
  }
  var style = baseStyle;
  for (final highlight in highlights) {
    style = style.merge(highlight.style);
  }
  return style;
}

TextSpan _visualMarkdownTextSpan(
  String source,
  TextStyle baseStyle,
  BusyMarkSyntaxColors palette,
) {
  final spans = <TextSpan>[];
  final lines = source.split('\n');
  MarkdownFence? openFence;

  for (var index = 0; index < lines.length; index++) {
    final line = lines[index];
    final activeFence = openFence;
    final closesFence = activeFence?.closes(line) ?? false;
    final openingFence = activeFence == null ? MarkdownFence.parse(line) : null;
    if (closesFence || openingFence != null) {
      openFence = closesFence ? null : openingFence;
      spans.add(
        TextSpan(
          text: line,
          style: baseStyle.copyWith(
            color: palette.keyword,
            fontFamily: BusyMarkTypography.monoFontFamily,
          ),
        ),
      );
    } else if (activeFence != null) {
      spans.add(
        TextSpan(
          text: line,
          style: baseStyle.copyWith(
            color: palette.literal,
            fontFamily: BusyMarkTypography.monoFontFamily,
            backgroundColor: palette.punctuation.withValues(
              alpha: BusyMarkAlpha.sourceSyntaxBackground,
            ),
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
  BusyMarkSyntaxColors palette,
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
  BusyMarkSyntaxColors palette,
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
          fontFamily: BusyMarkTypography.monoFontFamily,
          backgroundColor: palette.punctuation.withValues(
            alpha: BusyMarkAlpha.sourceSyntaxBackground,
          ),
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
  final scale = BusyMarkTypography.markdownHeadingScale(level);
  return baseStyle.copyWith(
    fontSize:
        (baseStyle.fontSize ?? BusyMarkTypography.defaultFontSize) * scale,
    fontWeight: FontWeight.w700,
  );
}

TextStyle _transparentLayoutStyle(TextStyle style) {
  return style.copyWith(
    color: BusyMarkLinuxPalette.transparent,
    backgroundColor: BusyMarkLinuxPalette.transparent,
    decorationColor: BusyMarkLinuxPalette.transparent,
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

bool _foldRegionsEqual(
  List<SourceFoldRegion> left,
  List<SourceFoldRegion> right,
) {
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index++) {
    final a = left[index];
    final b = right[index];
    if (a.kind != b.kind ||
        a.startLine != b.startLine ||
        a.endLine != b.endLine ||
        a.startOffset != b.startOffset ||
        a.endOffset != b.endOffset ||
        a.hiddenStartOffset != b.hiddenStartOffset ||
        a.hiddenEndOffset != b.hiddenEndOffset) {
      return false;
    }
  }
  return true;
}

List<SourceFoldRegion> _preserveFoldedRegionsAfterVisibleEdit(
  Iterable<SourceFoldRegion> regions,
  SourceVisibleEdit edit,
  Set<String> affectedKeys,
) {
  final result = <SourceFoldRegion>[];
  for (final region in regions) {
    if (affectedKeys.contains(region.key)) {
      continue;
    }
    if (edit.fullEnd <= region.startOffset) {
      result.add(
        _shiftFoldRegion(
          region,
          offsetDelta: edit.fullDelta,
          lineDelta: edit.lineDelta,
        ),
      );
      continue;
    }
    if (region.startOffset <= edit.fullStart &&
        edit.fullEnd <= region.hiddenStartOffset) {
      result.add(_shiftFoldRegionAfterStartLineEdit(region, edit));
      continue;
    }
    if (edit.fullStart >= region.hiddenEndOffset) {
      result.add(region);
      continue;
    }
  }
  return _normalizedFoldRegions(result);
}

List<SourceFoldRegion> _preserveFoldedRegionsForFullReplacement(
  Iterable<SourceFoldRegion> regions,
  String oldText,
  String newText,
) {
  final edit = _fullReplacementEdit(oldText, newText);
  return _preserveFoldedRegionsAfterVisibleEdit(regions, edit, const {});
}

SourceVisibleEdit _fullReplacementEdit(String oldText, String newText) {
  var start = 0;
  final shortest = math.min(oldText.length, newText.length);
  while (start < shortest &&
      oldText.codeUnitAt(start) == newText.codeUnitAt(start)) {
    start++;
  }
  var oldEnd = oldText.length;
  var newEnd = newText.length;
  while (oldEnd > start &&
      newEnd > start &&
      oldText.codeUnitAt(oldEnd - 1) == newText.codeUnitAt(newEnd - 1)) {
    oldEnd--;
    newEnd--;
  }
  return SourceVisibleEdit(
    visibleStart: start,
    visibleEnd: oldEnd,
    fullStart: start,
    fullEnd: oldEnd,
    replacement: newText.substring(start, newEnd),
    replacedFullText: oldText.substring(start, oldEnd),
  );
}

SourceFoldRegion _shiftFoldRegion(
  SourceFoldRegion region, {
  required int offsetDelta,
  required int lineDelta,
}) {
  if (offsetDelta == 0 && lineDelta == 0) {
    return region;
  }
  return SourceFoldRegion(
    kind: region.kind,
    startLine: region.startLine + lineDelta,
    endLine: region.endLine + lineDelta,
    startOffset: region.startOffset + offsetDelta,
    endOffset: region.endOffset + offsetDelta,
    hiddenStartOffset: region.hiddenStartOffset + offsetDelta,
    hiddenEndOffset: region.hiddenEndOffset + offsetDelta,
  );
}

SourceFoldRegion _shiftFoldRegionAfterStartLineEdit(
  SourceFoldRegion region,
  SourceVisibleEdit edit,
) {
  if (edit.fullDelta == 0 && edit.lineDelta == 0) {
    return region;
  }
  return SourceFoldRegion(
    kind: region.kind,
    startLine: region.startLine,
    endLine: region.endLine + edit.lineDelta,
    startOffset: region.startOffset,
    endOffset: region.endOffset + edit.fullDelta,
    hiddenStartOffset: region.hiddenStartOffset + edit.fullDelta,
    hiddenEndOffset: region.hiddenEndOffset + edit.fullDelta,
  );
}
