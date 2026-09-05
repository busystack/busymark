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

final _markdownHeadingPattern = RegExp(r'^(\s{0,3}#{1,6}(?:\s+|$))(.*)$');
final _markdownInlineCodePattern = RegExp(r'`[^`\n]+`');
final _markdownStrongPattern = RegExp(r'(\*\*[^*\n]+\*\*|__[^_\n]+__)');
final _markdownBlockquotePattern = RegExp(r'^\s{0,3}>\s?');
final _markdownListMarkerPattern = RegExp(r'^\s*(?:[-*+]|\d+\.)\s+');
final _markdownTaskMarkerPattern = RegExp(
  r'^\s*(?:[-*+]|\d+\.)\s+(\[[ xX]\])\s+',
);
final _markdownThematicBreakPattern = RegExp(r'^\s{0,3}(?:(?:[-*_])\s*){3,}$');
final _markdownLinkPattern = RegExp(r'!?\[[^\]\n]+\]\([^\)\n]+\)');
final _markdownInlineHtmlPattern = RegExp(r'</?[A-Za-z_][^>\n]*>');
final _markdownStrikethroughPattern = RegExp(r'~~[^~\n]+~~');
final _jsonAttributePattern = RegExp(r'"(?:\\.|[^"\\])*"(?=\s*:)');
final _codeNumberPattern = RegExp(r'\b\d+(?:\.\d+)?(?:[eE][+-]?\d+)?\b');
final _codeWordPattern = RegExp(r'\b[A-Za-z_][A-Za-z0-9_]*\b');
final _codeTypePattern = RegExp(r'\b[A-Z][A-Za-z0-9_]*\b');
final _codeFunctionPattern = RegExp(r'\b[A-Za-z_][A-Za-z0-9_]*\b(?=\s*\()');
final _codePunctuationPattern = RegExp(r'[{}()\[\],.;:+\-*/%=<>!&|?]+');
final _jsonStringPattern = RegExp(r'"(?:\\.|[^"\\])*"');
final _codeStringPattern = RegExp(
  "\"(?:\\\\.|[^\"\\\\])*\"|'(?:\\\\.|[^'\\\\])*'|`(?:\\\\.|[^`\\\\])*`",
);
final _codeBlockCommentPattern = RegExp(r'/\*.*?(?:\*/|$)');
final _xmlCommentPattern = RegExp(r'<!--[\s\S]*?-->');
final _xmlTagPattern = RegExp(r'</?[^>]+/?>');
final _xmlTagNamePattern = RegExp(r'^</?\s*([A-Za-z_][\w:.-]*)');
final _xmlAttributePattern = RegExp(r'([A-Za-z_:][\w:.-]*)(?=\s*=)');
final _xmlLiteralPattern = RegExp("\"[^\"\\n]*\"|'[^'\\n]*'");
final _visualMarkdownHeadingPattern = RegExp(r'^(\s{0,3}#{1,6}\s+)(.*)$');
final _visualMarkdownListPattern = RegExp(
  r'^(\s{0,8}(?:[-*+]|\d+[.)])\s+)(\[[ xX]\]\s+)?(.*)$',
);
final _visualMarkdownQuotePattern = RegExp(r'^(\s{0,3}>\s?)(.*)$');

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
  TextSelection? lastFullSelectionBeforeEdit;
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

  TextRange get fullComposing {
    return _visibleComposingToFullRange(value.composing);
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
    final visibleSelection = _document.fullSelectionToVisibleSelection(
      selectionSnapshot,
    );
    super.value = TextEditingValue(
      text: _document.visibleText,
      selection: _selectionWithLineEndAffinity(
        visibleSelection,
        _document.visibleText,
      ),
    );
  }

  void setFullEditingValue(TextEditingValue value) {
    lastFullSelectionBeforeEdit = fullSelection;
    _foldedRegions = _preserveFoldedRegionsForFullReplacement(
      _foldedRegions,
      _document.fullText,
      value.text,
    );
    _document = _createDocument(value.text, _foldedRegions);
    lastVisibleEdit = null;
    final visibleSelection = _document.fullSelectionToVisibleSelection(
      value.selection,
    );
    super.value = TextEditingValue(
      text: _document.visibleText,
      selection: _selectionWithLineEndAffinity(
        visibleSelection,
        _document.visibleText,
      ),
      composing: _fullComposingToVisibleRange(value.composing),
    );
    onFullTextChanged?.call(_document.fullText, null);
  }

  void setFoldedRegions(Iterable<SourceFoldRegion> regions) {
    final fullSelectionSnapshot = fullSelection;
    final fullComposingSnapshot = _visibleComposingToFullRange(
      super.value.composing,
    );
    final normalized = _normalizedFoldRegions(regions);
    if (_foldRegionsEqual(_foldedRegions, normalized)) {
      return;
    }
    _foldedRegions = normalized;
    _document = _createDocument(_document.fullText, _foldedRegions);
    final visibleSelection = _document.fullSelectionToVisibleSelection(
      fullSelectionSnapshot,
    );
    super.value = TextEditingValue(
      text: _document.visibleText,
      selection: _selectionWithLineEndAffinity(
        visibleSelection,
        _document.visibleText,
      ),
      composing: _fullComposingToVisibleRange(fullComposingSnapshot),
    );
  }

  void clearFoldedRegions() {
    if (_foldedRegions.isEmpty) {
      return;
    }
    final fullSelectionSnapshot = fullSelection;
    final fullComposingSnapshot = _visibleComposingToFullRange(
      super.value.composing,
    );
    _foldedRegions = const [];
    _document = _createDocument(_document.fullText, _foldedRegions);
    final visibleSelection = _document.fullSelectionToVisibleSelection(
      fullSelectionSnapshot,
    );
    super.value = TextEditingValue(
      text: _document.visibleText,
      selection: _selectionWithLineEndAffinity(
        visibleSelection,
        _document.visibleText,
      ),
      composing: _fullComposingToVisibleRange(fullComposingSnapshot),
    );
  }

  TextRange _visibleComposingToFullRange(TextRange range) {
    if (!range.isValid) {
      return TextRange.empty;
    }
    return TextRange(
      start: _document.visibleOffsetToFullOffset(
        range.start,
        affinity: SourceHiddenAffinity.downstream,
      ),
      end: _document.visibleOffsetToFullOffset(
        range.end,
        affinity: SourceHiddenAffinity.upstream,
      ),
    );
  }

  TextRange _fullComposingToVisibleRange(TextRange range) {
    if (!range.isValid) {
      return TextRange.empty;
    }
    return TextRange(
      start: _document.fullOffsetToVisibleOffset(range.start),
      end: _document.fullOffsetToVisibleOffset(range.end),
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
      super.value = newValue.copyWith(
        selection: _selectionWithLineEndAffinity(
          newValue.selection,
          newValue.text,
        ),
      );
      return;
    }

    lastFullSelectionBeforeEdit = fullSelection;
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
    final hiddenRanges = _hiddenRangesFor(nextFullText, _foldedRegions);
    _document = SourceDocument.afterVisibleEdit(
      previous: oldDocument,
      fullText: nextFullText,
      hiddenRanges: hiddenRanges,
      edit: edit,
    );
    lastVisibleEdit = edit;
    final selection = _projectIncomingSelection(
      oldDocument: oldDocument,
      nextDocument: _document,
      edit: edit,
      incomingValue: newValue,
    );
    final composing = _projectIncomingComposingRange(
      oldDocument: oldDocument,
      nextDocument: _document,
      edit: edit,
      incomingValue: newValue,
    );
    super.value = TextEditingValue(
      text: _document.visibleText,
      selection: selection,
      composing: composing,
    );
    onFullTextChanged?.call(_document.fullText, edit);
  }

  TextSelection _projectIncomingSelection({
    required SourceDocument oldDocument,
    required SourceDocument nextDocument,
    required SourceVisibleEdit edit,
    required TextEditingValue incomingValue,
  }) {
    final incoming = incomingValue.selection;
    if (!incoming.isValid) {
      return TextSelection.collapsed(offset: nextDocument.visibleText.length);
    }
    if (incomingValue.text == nextDocument.visibleText) {
      return _selectionWithLineEndAffinity(
        incoming.copyWith(
          baseOffset: incoming.baseOffset
              .clamp(0, nextDocument.visibleText.length)
              .toInt(),
          extentOffset: incoming.extentOffset
              .clamp(0, nextDocument.visibleText.length)
              .toInt(),
        ),
        nextDocument.visibleText,
      );
    }
    return _selectionWithLineEndAffinity(
      incoming.copyWith(
        baseOffset: _projectIncomingVisibleOffset(
          oldDocument: oldDocument,
          nextDocument: nextDocument,
          edit: edit,
          incomingOffset: incoming.baseOffset,
          affinity: SourceHiddenAffinity.downstream,
        ),
        extentOffset: _projectIncomingVisibleOffset(
          oldDocument: oldDocument,
          nextDocument: nextDocument,
          edit: edit,
          incomingOffset: incoming.extentOffset,
          affinity: SourceHiddenAffinity.upstream,
        ),
      ),
      nextDocument.visibleText,
    );
  }

  TextRange _projectIncomingComposingRange({
    required SourceDocument oldDocument,
    required SourceDocument nextDocument,
    required SourceVisibleEdit edit,
    required TextEditingValue incomingValue,
  }) {
    final incoming = incomingValue.composing;
    if (!incoming.isValid) {
      return TextRange.empty;
    }
    if (incomingValue.text == nextDocument.visibleText) {
      return TextRange(
        start: incoming.start.clamp(0, nextDocument.visibleText.length).toInt(),
        end: incoming.end.clamp(0, nextDocument.visibleText.length).toInt(),
      );
    }
    final start = _projectIncomingVisibleOffset(
      oldDocument: oldDocument,
      nextDocument: nextDocument,
      edit: edit,
      incomingOffset: incoming.start,
      affinity: SourceHiddenAffinity.downstream,
    );
    final end = _projectIncomingVisibleOffset(
      oldDocument: oldDocument,
      nextDocument: nextDocument,
      edit: edit,
      incomingOffset: incoming.end,
      affinity: SourceHiddenAffinity.upstream,
    );
    return TextRange(start: math.min(start, end), end: math.max(start, end));
  }

  int _projectIncomingVisibleOffset({
    required SourceDocument oldDocument,
    required SourceDocument nextDocument,
    required SourceVisibleEdit edit,
    required int incomingOffset,
    required SourceHiddenAffinity affinity,
  }) {
    final safeOffset = incomingOffset
        .clamp(
          0,
          edit.visibleStart +
              edit.replacement.length +
              (oldDocument.visibleText.length - edit.visibleEnd),
        )
        .toInt();
    final replacementEnd = edit.visibleStart + edit.replacement.length;
    late final int fullOffset;
    if (safeOffset <= edit.visibleStart) {
      fullOffset = safeOffset == edit.visibleStart
          ? edit.fullStart
          : oldDocument.visibleOffsetToFullOffset(
              safeOffset,
              affinity: affinity,
            );
    } else if (safeOffset <= replacementEnd) {
      fullOffset = edit.fullStart + safeOffset - edit.visibleStart;
    } else {
      final oldVisibleOffset =
          safeOffset -
          edit.replacement.length +
          (edit.visibleEnd - edit.visibleStart);
      final oldFullOffset = oldDocument.visibleOffsetToFullOffset(
        oldVisibleOffset,
        affinity: affinity,
      );
      fullOffset = oldFullOffset >= edit.fullEnd
          ? oldFullOffset + edit.fullDelta
          : oldFullOffset;
    }
    return nextDocument
        .fullOffsetToVisibleOffset(fullOffset)
        .clamp(0, nextDocument.visibleText.length)
        .toInt();
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
    if (!visible) {
      return TextSpan(
        style: baseStyle,
        children: _language == SourceSyntaxLanguage.markdown
            ? _layoutOnlyMarkdownSpans(
                source,
                baseStyle,
                hiddenRanges,
                styleOverride: _transparentLayoutStyle,
              )
            : _spansFromRanges(
                source,
                const <_HighlightRange>[],
                hiddenRanges,
                baseStyle,
                styleOverride: _transparentLayoutStyle,
              ),
      );
    }
    final palette = BusyMarkSyntaxColors.of(context);
    final searchRanges = _searchHighlightRanges(
      source,
      baseStyle,
      colors,
      _searchResult,
    );
    if (visualMarkdown && _language == SourceSyntaxLanguage.markdown) {
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
        ),
        SourceSyntaxLanguage.xml => _highlightXml(
          source,
          baseStyle,
          palette,
          hiddenRanges,
          overlayRanges: searchRanges,
        ),
        SourceSyntaxLanguage.plain => [
          ..._spansFromRanges(source, searchRanges, hiddenRanges, baseStyle),
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
      hiddenRanges: _hiddenRangesFor(fullText, foldedRegions),
    );
  }

  SourceHiddenRanges _hiddenRangesFor(
    String fullText,
    Iterable<SourceFoldRegion> foldedRegions,
  ) {
    return SourceHiddenRanges(
      ranges: [
        for (final region in foldedRegions)
          SourceHiddenRange(
            start: region.hiddenStartOffset,
            end: region.hiddenEndOffset,
            key: region.key,
          ),
      ],
      textLength: fullText.length,
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

List<TextSpan> _layoutOnlyMarkdownSpans(
  String source,
  TextStyle baseStyle,
  List<_HiddenRange> hiddenRanges, {
  required TextStyle Function(TextStyle style) styleOverride,
}) {
  final ranges = <_HighlightRange>[];
  var offset = 0;
  MarkdownFence? openFence;
  var inFrontMatter = source.startsWith('---\n') || source == '---';
  for (final line in source.split('\n')) {
    final lineStart = offset;
    final lineEnd = lineStart + line.length;
    if (inFrontMatter) {
      if (lineStart > 0 && line.trim() == '---') {
        inFrontMatter = false;
      }
      offset = lineEnd + 1;
      continue;
    }
    final activeFence = openFence;
    if (activeFence != null) {
      if (activeFence.closes(line)) {
        openFence = null;
      }
      offset = lineEnd + 1;
      continue;
    }
    final openingFence = MarkdownFence.parse(line);
    if (openingFence != null) {
      openFence = openingFence;
      offset = lineEnd + 1;
      continue;
    }
    final heading = _markdownHeadingPattern.firstMatch(line);
    if (heading != null) {
      final marker = heading.group(1)!;
      final content = heading.group(2)!;
      if (content.isNotEmpty) {
        _addRange(
          ranges,
          lineStart + marker.length,
          lineEnd,
          _markdownHeadingStyle(baseStyle, marker.trim().length),
        );
      }
      offset = lineEnd + 1;
      continue;
    }
    _addDelimitedInlineMatches(
      ranges,
      lineStart,
      line,
      _markdownInlineCodePattern,
      baseStyle.copyWith(fontFamily: BusyMarkTypography.monoFontFamily),
      openingLength: 1,
      closingLength: 1,
      markerStyle: baseStyle,
    );
    _addDelimitedInlineMatches(
      ranges,
      lineStart,
      line,
      _markdownStrongPattern,
      baseStyle.copyWith(fontWeight: FontWeight.w700),
      openingLength: 2,
      closingLength: 2,
      markerStyle: baseStyle,
    );
    _addSingleDelimiterInlineMatches(
      ranges,
      lineStart,
      line,
      '*',
      baseStyle.copyWith(fontStyle: FontStyle.italic),
      markerStyle: baseStyle,
    );
    _addSingleDelimiterInlineMatches(
      ranges,
      lineStart,
      line,
      '_',
      baseStyle.copyWith(fontStyle: FontStyle.italic),
      markerStyle: baseStyle,
    );
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

TextSelection _selectionWithLineEndAffinity(
  TextSelection selection,
  String text,
) {
  if (!selection.isValid || !selection.isCollapsed) {
    return selection;
  }
  final offset = selection.extentOffset;
  if (offset < 0 || offset >= text.length) {
    return selection;
  }
  final nextUnit = text.codeUnitAt(offset);
  if (nextUnit != 10 && nextUnit != 13) {
    return selection;
  }
  return selection.copyWith(affinity: TextAffinity.upstream);
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
  var inDisplayMath = false;

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

    if (inDisplayMath) {
      _addRange(
        ranges,
        lineStart,
        lineEnd,
        baseStyle.copyWith(color: palette.literal),
      );
      if (line.trimRight().endsWith(r'$$')) {
        inDisplayMath = false;
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

    final displayStart = RegExp(r'^\s{0,3}\$\$').firstMatch(line);
    if (displayStart != null) {
      _addRange(
        ranges,
        lineStart,
        lineEnd,
        baseStyle.copyWith(color: palette.literal),
      );
      final remainder = line.substring(displayStart.end);
      inDisplayMath = !remainder.contains(r'$$');
      offset = lineEnd + 1;
      continue;
    }

    final heading = _markdownHeadingPattern.firstMatch(line);
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

    final blockquote = _markdownBlockquotePattern.firstMatch(line);
    if (blockquote != null) {
      _addRange(
        ranges,
        lineStart,
        lineStart + blockquote.end,
        blockMarkerStyle,
      );
    }

    final listMarker = _markdownListMarkerPattern.firstMatch(line);
    if (listMarker != null) {
      _addRange(
        ranges,
        lineStart,
        lineStart + listMarker.end,
        blockMarkerStyle,
      );
    }

    final taskMarker = _markdownTaskMarkerPattern.firstMatch(line);
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

    final thematicBreak = _markdownThematicBreakPattern.firstMatch(line);
    if (thematicBreak != null) {
      _addRange(ranges, lineStart, lineEnd, blockMarkerStyle);
    }

    _addDelimitedInlineMatches(
      ranges,
      lineStart,
      line,
      _markdownInlineCodePattern,
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
    _addMarkdownInlineMathRanges(
      ranges,
      lineStart,
      line,
      baseStyle.copyWith(color: palette.literal),
      inlineMarkerStyle,
    );
    _addLinkLabelMatches(
      ranges,
      lineStart,
      line,
      _markdownLinkPattern,
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
      _markdownInlineHtmlPattern,
      baseStyle.copyWith(color: palette.tag),
    );
    _addDelimitedInlineMatches(
      ranges,
      lineStart,
      line,
      _markdownStrongPattern,
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
      _markdownStrikethroughPattern,
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

void _addMarkdownInlineMathRanges(
  List<_HighlightRange> ranges,
  int lineStart,
  String line,
  TextStyle expressionStyle,
  TextStyle markerStyle,
) {
  var index = 0;
  while (index < line.length) {
    final start = line.indexOf(r'$', index);
    if (start < 0) return;
    final globalStart = lineStart + start;
    if (_isEscapedAt(line, start) ||
        _positionInsideRange(ranges, globalStart) ||
        (start + 1 < line.length && line[start + 1] == r'$')) {
      index = start + 1;
      continue;
    }
    final github = start + 1 < line.length && line[start + 1] == '`';
    final closeToken = github ? '`\$' : r'$';
    var close = line.indexOf(closeToken, start + (github ? 2 : 1));
    while (close >= 0 && !github && _isEscapedAt(line, close)) {
      close = line.indexOf(closeToken, close + 1);
    }
    if (close < 0 || close == start + 1) {
      index = start + 1;
      continue;
    }
    final end = close + closeToken.length;
    if ((!github && _positionInsideRange(ranges, lineStart + close)) ||
        (!github && _looksLikeCurrencyRange(line, start, close))) {
      index = end;
      continue;
    }
    final openingLength = github ? 2 : 1;
    _addRange(
      ranges,
      globalStart,
      globalStart + openingLength,
      markerStyle,
      priority: 10,
    );
    _addRange(
      ranges,
      globalStart + openingLength,
      lineStart + close,
      expressionStyle,
      priority: 10,
    );
    _addRange(
      ranges,
      lineStart + close,
      lineStart + end,
      markerStyle,
      priority: 10,
    );
    index = end;
  }
}

bool _isEscapedAt(String source, int offset) {
  var backslashes = 0;
  for (var index = offset - 1; index >= 0 && source[index] == r'\'; index--) {
    backslashes++;
  }
  return backslashes.isOdd;
}

bool _looksLikeCurrencyRange(String line, int start, int close) {
  if (start + 1 >= close ||
      !RegExp(r'\d').hasMatch(line[start + 1]) ||
      close + 1 >= line.length ||
      !RegExp(r'\d').hasMatch(line[close + 1])) {
    return false;
  }
  return true;
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
  if (_visualizationCodeLanguages.contains(language)) {
    _addVisualizationCodeLineRanges(
      ranges,
      lineStart,
      line,
      language,
      baseStyle,
      palette,
    );
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
      _jsonAttributePattern,
      attributeStyle,
    );
  }

  _addCodeStringRanges(ranges, lineStart, line, language, stringStyle);
  _addCodeCommentRanges(ranges, lineStart, line, language, commentStyle);

  _addInlineMatches(ranges, lineStart, line, _codeNumberPattern, literalStyle);

  final keywords = _codeKeywords(language);
  for (final word in _codeWordPattern.allMatches(line)) {
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

  for (final type in _codeTypePattern.allMatches(line)) {
    _addRange(ranges, lineStart + type.start, lineStart + type.end, tagStyle);
  }

  for (final function in _codeFunctionPattern.allMatches(line)) {
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
    _codePunctuationPattern,
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
    'puml' => 'plantuml',
    'oas' || 'swagger' => 'openapi',
    _ => language,
  };
}

void _addVisualizationCodeLineRanges(
  List<_HighlightRange> ranges,
  int lineStart,
  String line,
  String language,
  TextStyle baseStyle,
  BusyMarkSyntaxColors palette,
) {
  final commentStyle = baseStyle.copyWith(color: palette.comment);
  final keywordStyle = baseStyle.copyWith(color: palette.keyword);
  final stringStyle = baseStyle.copyWith(color: palette.string);
  final literalStyle = baseStyle.copyWith(color: palette.literal);
  final attributeStyle = baseStyle.copyWith(color: palette.attribute);
  final punctuationStyle = baseStyle.copyWith(color: palette.punctuation);

  _addCodeStringRanges(ranges, lineStart, line, language, stringStyle);
  for (final marker in switch (language) {
    'mermaid' => const ['%%'],
    'plantuml' => const ["'"],
    'd2' || 'openapi' => const ['#'],
    _ => const <String>[],
  }) {
    final index = line.indexOf(marker);
    if (index >= 0 && !_positionInsideRange(ranges, lineStart + index)) {
      _addRange(
        ranges,
        lineStart + index,
        lineStart + line.length,
        commentStyle,
      );
    }
  }

  if (language == 'plantuml') {
    _addInlineMatches(
      ranges,
      lineStart,
      line,
      RegExp(r'(?<!\w)[@!]\w+'),
      keywordStyle,
    );
    _addInlineMatches(
      ranges,
      lineStart,
      line,
      RegExp(r'/\*.*?\*/|/\x27.*?\x27/'),
      commentStyle,
    );
  }

  if (language == 'd2' || language == 'openapi') {
    _addInlineMatches(
      ranges,
      lineStart,
      line,
      RegExp(r'(?<![\w-])(?:[A-Za-z_][\w.-]*|"[^"]+")(?=\s*:)'),
      attributeStyle,
    );
  }
  if (language == 'openapi') {
    _addInlineMatches(
      ranges,
      lineStart,
      line,
      _jsonAttributePattern,
      attributeStyle,
    );
  }

  _addInlineMatches(ranges, lineStart, line, _codeNumberPattern, literalStyle);
  final keywords = _visualizationKeywords(language);
  for (final word in _codeWordPattern.allMatches(line)) {
    final token = word.group(0)!;
    if (keywords.contains(token) ||
        keywords.contains(token.toLowerCase()) ||
        _codeLiterals.contains(token.toLowerCase())) {
      _addRange(
        ranges,
        lineStart + word.start,
        lineStart + word.end,
        _codeLiterals.contains(token.toLowerCase())
            ? literalStyle
            : keywordStyle,
      );
    }
  }
  _addInlineMatches(
    ranges,
    lineStart,
    line,
    RegExp(r'--?>|<--?|<->|==>|\.\.|[{}\[\]():;,|]'),
    punctuationStyle,
  );
}

Set<String> _visualizationKeywords(String language) => switch (language) {
  'mermaid' => _mermaidKeywords,
  'plantuml' => _plantUmlKeywords,
  'd2' => _d2Keywords,
  'openapi' => _openApiKeywords,
  _ => const {},
};

void _addCodeStringRanges(
  List<_HighlightRange> ranges,
  int lineStart,
  String line,
  String language,
  TextStyle style,
) {
  final pattern = language == 'json' ? _jsonStringPattern : _codeStringPattern;
  _addInlineMatches(ranges, lineStart, line, pattern, style);
}

void _addCodeCommentRanges(
  List<_HighlightRange> ranges,
  int lineStart,
  String line,
  String language,
  TextStyle style,
) {
  for (final block in _codeBlockCommentPattern.allMatches(line)) {
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

const _visualizationCodeLanguages = {'mermaid', 'plantuml', 'd2', 'openapi'};

const _mermaidKeywords = {
  'flowchart',
  'graph',
  'sequenceDiagram',
  'classDiagram',
  'stateDiagram',
  'stateDiagram-v2',
  'erDiagram',
  'journey',
  'gantt',
  'pie',
  'requirementDiagram',
  'gitGraph',
  'mindmap',
  'timeline',
  'quadrantChart',
  'xychart-beta',
  'block-beta',
  'packet-beta',
  'architecture-beta',
  'kanban',
  'participant',
  'actor',
  'class',
  'state',
  'subgraph',
  'end',
  'note',
  'loop',
  'alt',
  'else',
  'opt',
  'par',
  'and',
  'rect',
  'activate',
  'deactivate',
};

const _plantUmlKeywords = {
  'actor',
  'agent',
  'artifact',
  'boundary',
  'card',
  'class',
  'cloud',
  'component',
  'control',
  'database',
  'entity',
  'enum',
  'file',
  'folder',
  'frame',
  'interface',
  'node',
  'package',
  'participant',
  'queue',
  'rectangle',
  'stack',
  'state',
  'storage',
  'usecase',
  'abstract',
  'annotation',
  'circle',
  'diamond',
  'object',
  'map',
  'json',
  'yaml',
  'start',
  'stop',
  'if',
  'then',
  'else',
  'elseif',
  'endif',
  'while',
  'endwhile',
  'repeat',
  'fork',
  'end',
  'note',
  'legend',
  'title',
  'skinparam',
};

const _d2Keywords = {
  'direction',
  'shape',
  'style',
  'label',
  'tooltip',
  'link',
  'near',
  'constraint',
  'grid-rows',
  'grid-columns',
  'classes',
  'vars',
  'layers',
  'scenarios',
  'steps',
};

const _openApiKeywords = {
  'openapi',
  'swagger',
  'info',
  'servers',
  'paths',
  'components',
  'security',
  'tags',
  'externalDocs',
  'get',
  'put',
  'post',
  'delete',
  'options',
  'head',
  'patch',
  'trace',
  'parameters',
  'requestBody',
  'responses',
  'callbacks',
  'schemas',
  'securitySchemes',
};

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

  for (final comment in _xmlCommentPattern.allMatches(source)) {
    _addRange(
      ranges,
      sourceOffset + comment.start,
      sourceOffset + comment.end,
      commentStyle,
    );
  }

  for (final tag in _xmlTagPattern.allMatches(source)) {
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

    final name = _xmlTagNamePattern.firstMatch(text);
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

    for (final attr in _xmlAttributePattern.allMatches(text)) {
      _addRange(
        ranges,
        sourceOffset + tag.start + attr.start,
        sourceOffset + tag.start + attr.end,
        attributeStyle,
      );
    }
    for (final literal in _xmlLiteralPattern.allMatches(text)) {
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
  void addMatch(int index, SourceSearchMatch match) {
    if (match.hidden || match.visibleEnd <= match.visibleStart) {
      return;
    }
    final isCurrent = result.firstMatchIndex + index == currentIndex;
    ranges.add(
      _HighlightRange(
        match.visibleStart.clamp(0, source.length).toInt(),
        match.visibleEnd.clamp(0, source.length).toInt(),
        isCurrent ? currentStyle : matchStyle,
        priority: isCurrent ? 100 : 90,
      ),
    );
  }

  final highlightCount = math.min(
    result.matches.length,
    sourceInteractiveSearchMatchLimit,
  );
  for (var index = 0; index < highlightCount; index++) {
    addMatch(index, result.matches[index]);
  }
  final currentLocalIndex = currentIndex == null
      ? -1
      : currentIndex - result.firstMatchIndex;
  if (currentLocalIndex >= highlightCount &&
      currentLocalIndex < result.matches.length) {
    addMatch(currentLocalIndex, result.matches[currentLocalIndex]);
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
  final hiddenStyle = baseStyle.copyWith(
    color: BusyMarkLinuxPalette.transparent,
    fontSize: BusyMarkTypography.hiddenLayoutFontSize,
    height: BusyMarkTypography.hiddenLayoutHeight,
    letterSpacing: 0,
    wordSpacing: 0,
  );
  final boundaries = <int>{0, source.length};
  final highlightStarts = <int, List<_HighlightRange>>{};
  final highlightEnds = <int, List<_HighlightRange>>{};
  for (final range in ranges) {
    final start = range.start.clamp(0, source.length).toInt();
    final end = range.end.clamp(start, source.length).toInt();
    if (end <= start) {
      continue;
    }
    boundaries
      ..add(start)
      ..add(end);
    (highlightStarts[start] ??= []).add(range);
    (highlightEnds[end] ??= []).add(range);
  }
  final hiddenStarts = <int, List<_HiddenRange>>{};
  final hiddenEnds = <int, List<_HiddenRange>>{};
  for (final range in hiddenRanges) {
    final start = range.start.clamp(0, source.length).toInt();
    final end = range.end.clamp(start, source.length).toInt();
    if (end <= start) {
      continue;
    }
    boundaries
      ..add(start)
      ..add(end);
    (hiddenStarts[start] ??= []).add(range);
    (hiddenEnds[end] ??= []).add(range);
  }
  final sortedBoundaries = boundaries.toList()..sort();
  final spans = <TextSpan>[];
  final activeHighlights = <_HighlightRange>[];
  final activeHiddenRanges = <_HiddenRange>[];
  for (var index = 0; index < sortedBoundaries.length - 1; index++) {
    final start = sortedBoundaries[index];
    final end = sortedBoundaries[index + 1];
    if (end <= start) {
      continue;
    }
    for (final range in highlightEnds[start] ?? const <_HighlightRange>[]) {
      activeHighlights.remove(range);
    }
    for (final range in hiddenEnds[start] ?? const <_HiddenRange>[]) {
      activeHiddenRanges.remove(range);
    }
    activeHighlights.addAll(
      highlightStarts[start] ?? const <_HighlightRange>[],
    );
    activeHiddenRanges.addAll(hiddenStarts[start] ?? const <_HiddenRange>[]);
    activeHighlights.sort((a, b) {
      final priority = a.priority.compareTo(b.priority);
      return priority != 0 ? priority : a.start.compareTo(b.start);
    });
    activeHiddenRanges.sort((a, b) => a.start.compareTo(b.start));
    final hiddenRange = activeHiddenRanges.firstOrNull;
    final style = _mergeHighlightStyles(baseStyle, activeHighlights);
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
  final heading = _visualMarkdownHeadingPattern.firstMatch(line);
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

  final list = _visualMarkdownListPattern.firstMatch(line);
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

  final quote = _visualMarkdownQuotePattern.firstMatch(line);
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
