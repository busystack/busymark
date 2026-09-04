import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:yaru/yaru.dart';

import '../../app/busymark_design.dart';
import '../../app/localization.dart';
import '../../core/diagnostic.dart';
import '../../core/diagnostic_localizations.dart';
import '../source_highlighter.dart';
import '../source_folding.dart';
import 'source_diagnostics.dart';
import 'source_document.dart';
import 'source_line_index.dart';

const sourceTextHeightBehavior = TextHeightBehavior(
  applyHeightToFirstAscent: true,
  applyHeightToLastDescent: true,
  leadingDistribution: TextLeadingDistribution.even,
);

class SourceGutterLine {
  const SourceGutterLine({
    required this.fullLine,
    required this.visibleLine,
    required this.foldRegion,
    required this.collapsed,
    required this.diagnostics,
  });

  final int fullLine;
  final int visibleLine;
  final SourceFoldRegion? foldRegion;
  final bool collapsed;
  final List<SourceDiagnosticMarker> diagnostics;

  bool get foldable => foldRegion != null;
}

List<SourceGutterLine> sourceGutterModel({
  required SourceDocument document,
  required List<SourceFoldRegion> foldRegions,
  required Set<String> collapsedRegionKeys,
  Iterable<SourceDiagnosticMarker> diagnostics = const [],
}) {
  final regionByStartLine = <int, SourceFoldRegion>{};
  for (final region in foldRegions.reversed) {
    regionByStartLine.putIfAbsent(region.startLine, () => region);
  }
  final diagnosticsByLine = <int, List<SourceDiagnosticMarker>>{};
  for (final diagnostic in diagnostics) {
    var displayLine = diagnostic.fullLine;
    if (diagnostic.hidden) {
      final visibleCollapsedOwner = foldRegions
          .where(
            (region) =>
                collapsedRegionKeys.contains(region.key) &&
                region.containsLine(diagnostic.fullLine) &&
                document.visibleLineForFullLine(region.startLine) != null,
          )
          .fold<SourceFoldRegion?>(null, (current, candidate) {
            if (current == null || candidate.startLine > current.startLine) {
              return candidate;
            }
            return current;
          });
      displayLine = visibleCollapsedOwner?.startLine ?? displayLine;
    }
    diagnosticsByLine
        .putIfAbsent(displayLine, () => <SourceDiagnosticMarker>[])
        .add(diagnostic);
  }

  final result = <SourceGutterLine>[];
  for (final fullLine in document.lineIndex.lines) {
    final visibleLine = document.visibleLineForFullLine(fullLine.number);
    if (visibleLine == null) {
      continue;
    }
    final region = regionByStartLine[fullLine.number];
    result.add(
      SourceGutterLine(
        fullLine: fullLine.number,
        visibleLine: visibleLine.number,
        foldRegion: region,
        collapsed: region != null && collapsedRegionKeys.contains(region.key),
        diagnostics: List.unmodifiable(
          diagnosticsByLine[fullLine.number] ??
              const <SourceDiagnosticMarker>[],
        ),
      ),
    );
  }
  return List.unmodifiable(result);
}

class BusyMarkSourceGutter extends StatelessWidget {
  const BusyMarkSourceGutter({
    super.key,
    required this.controller,
    required this.scrollController,
    required this.lineHeight,
    required this.textStyle,
    required this.strutStyle,
    required this.textWidth,
    required this.foldRegions,
    required this.collapsedRegionKeys,
    required this.diagnosticMarkers,
    required this.onToggleFold,
    required this.layoutCache,
  });

  final BusyMarkSourceEditingController controller;
  final ScrollController scrollController;
  final double lineHeight;
  final TextStyle textStyle;
  final StrutStyle? strutStyle;
  final double textWidth;
  final List<SourceFoldRegion> foldRegions;
  final Set<String> collapsedRegionKeys;
  final List<SourceDiagnosticMarker> diagnosticMarkers;
  final ValueChanged<SourceFoldRegion> onToggleFold;
  final SourceLineLayoutCache layoutCache;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.view),
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return AnimatedBuilder(
              animation: Listenable.merge([controller, scrollController]),
              builder: (context, _) {
                final layouts = layoutCache.resolve(
                  context,
                  controller: controller,
                  foldRegions: foldRegions,
                  collapsedRegionKeys: collapsedRegionKeys,
                  textStyle: textStyle,
                  strutStyle: strutStyle,
                  lineHeight: lineHeight,
                  textWidth: textWidth,
                  diagnostics: diagnosticMarkers,
                );
                final activeLine = controller.document.lineIndex
                    .lineNumberAtOffset(
                      controller.visibleOffsetToFullOffset(
                        controller.selection.extentOffset,
                      ),
                    );
                final scrollOffset = safeScrollOffset(scrollController);
                final children = <Widget>[];
                final visibleRange = sourceVisibleLayoutRange(
                  layouts,
                  scrollOffset: scrollOffset,
                  viewportHeight: constraints.maxHeight,
                  overscan: lineHeight,
                );
                for (final layout in layouts.sublist(
                  visibleRange.start,
                  visibleRange.end,
                )) {
                  final top = layout.top - scrollOffset;
                  final line = layout.gutterLine;
                  children.add(
                    Positioned(
                      top: top,
                      left: 0,
                      right: 0,
                      height: lineHeight,
                      child: _SourceGutterRow(
                        line: line,
                        active: line.fullLine == activeLine,
                        lineHeight: lineHeight,
                        textStyle: textStyle,
                        onToggleFold: onToggleFold,
                      ),
                    ),
                  );
                }
                return Stack(children: children);
              },
            );
          },
        ),
      ),
    );
  }
}

class _SourceGutterRow extends StatelessWidget {
  const _SourceGutterRow({
    required this.line,
    required this.active,
    required this.lineHeight,
    required this.textStyle,
    required this.onToggleFold,
  });

  static const double _foldButtonSize = BusyMarkSizes.sourceFoldButton;
  static const double _foldButtonRightInset =
      BusyMarkSizes.sourceFoldButtonRightInset;

  final SourceGutterLine line;
  final bool active;
  final double lineHeight;
  final TextStyle textStyle;
  final ValueChanged<SourceFoldRegion> onToggleFold;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final region = line.foldRegion;
    final activeColor = colors.foreground.withValues(
      alpha: BusyMarkAlpha.sourceCollapsedLine,
    );
    final numberStyle = textStyle.copyWith(
      color: active ? colors.foreground : colors.mutedForeground,
      fontSize:
          (textStyle.fontSize ?? BusyMarkTypography.defaultFontSize) *
          BusyMarkTypography.sourceLineNumberScale,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: active ? activeColor : BusyMarkLinuxPalette.transparent,
      ),
      child: SizedBox(
        height: lineHeight,
        child: Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  '${line.fullLine}',
                  textDirection: TextDirection.ltr,
                  style: numberStyle,
                ),
              ),
            ),
            if (line.diagnostics.isNotEmpty)
              Positioned(
                left: BusyMarkSpacing.xxs,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _SourceDiagnosticMarkerDot(
                    diagnostics: line.diagnostics,
                  ),
                ),
              ),
            Positioned(
              top: 0,
              right: _foldButtonRightInset,
              width: _foldButtonSize,
              height: lineHeight,
              child: Align(
                alignment: Alignment.center,
                child: region == null
                    ? const SizedBox.shrink()
                    : _SourceFoldButton(
                        region: region,
                        collapsed: line.collapsed,
                        onToggleFold: onToggleFold,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceFoldButton extends StatelessWidget {
  const _SourceFoldButton({
    required this.region,
    required this.collapsed,
    required this.onToggleFold,
  });

  final SourceFoldRegion region;
  final bool collapsed;
  final ValueChanged<SourceFoldRegion> onToggleFold;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return BusyMarkCompactIconButton(
      tooltip: collapsed
          ? context.l10n.expandKind(_foldKindLabel(context, region.kind))
          : context.l10n.collapseKind(_foldKindLabel(context, region.kind)),
      size: _SourceGutterRow._foldButtonSize,
      glyphSize: 12,
      foregroundColor: colors.mutedForeground,
      onPressed: () => onToggleFold(region),
      icon: collapsed ? YaruIcons.pan_end : YaruIcons.pan_down,
    );
  }
}

class _SourceDiagnosticMarkerDot extends StatelessWidget {
  const _SourceDiagnosticMarkerDot({required this.diagnostics});

  final List<SourceDiagnosticMarker> diagnostics;

  @override
  Widget build(BuildContext context) {
    final primary = diagnostics.reduce((a, b) {
      return a.diagnostic.severity.rank >= b.diagnostic.severity.rank ? a : b;
    });
    final message = diagnostics
        .map((marker) => localizeDiagnostic(context, marker.diagnostic))
        .join('\n');
    return Tooltip(
      message: message,
      child: SizedBox.square(
        dimension: 6,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: sourceDiagnosticColorForSeverity(
              context,
              primary.diagnostic.severity,
            ),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class SourceLineLayoutEntry {
  const SourceLineLayoutEntry({
    required this.gutterLine,
    required this.top,
    required this.height,
  });

  const SourceLineLayoutEntry.empty()
    : gutterLine = const SourceGutterLine(
        fullLine: 1,
        visibleLine: 1,
        foldRegion: null,
        collapsed: false,
        diagnostics: <SourceDiagnosticMarker>[],
      ),
      top = 0,
      height = 0;

  final SourceGutterLine gutterLine;
  final double top;
  final double height;
}

/// Retains expensive full-document text geometry while only the viewport's
/// scroll offset changes. Text edits, folding, diagnostics, typography, or
/// width changes naturally invalidate the cached entries.
class SourceLineLayoutCache {
  SourceDocument? _document;
  SourceSyntaxLanguage? _language;
  List<SourceFoldRegion>? _foldRegions;
  Set<String> _collapsedRegionKeys = const {};
  TextStyle? _textStyle;
  StrutStyle? _strutStyle;
  double? _lineHeight;
  double? _textWidth;
  TextScaler? _textScaler;
  List<SourceDiagnosticMarker>? _diagnostics;
  List<SourceLineLayoutEntry>? _entries;

  List<SourceLineLayoutEntry> resolve(
    BuildContext context, {
    required BusyMarkSourceEditingController controller,
    required List<SourceFoldRegion> foldRegions,
    required Set<String> collapsedRegionKeys,
    required TextStyle textStyle,
    required StrutStyle? strutStyle,
    required double lineHeight,
    required double textWidth,
    required List<SourceDiagnosticMarker> diagnostics,
  }) {
    final textScaler = MediaQuery.textScalerOf(context);
    final cached = _entries;
    final geometryMatches =
        cached != null &&
        _language == controller.language &&
        _textStyle == textStyle &&
        _strutStyle == strutStyle &&
        _lineHeight == lineHeight &&
        _textWidth == textWidth &&
        _textScaler == textScaler &&
        _setEquals(_collapsedRegionKeys, collapsedRegionKeys);
    if (geometryMatches) {
      final document = controller.document;
      if (identical(_document, document)) {
        if (identical(_foldRegions, foldRegions) &&
            identical(_diagnostics, diagnostics)) {
          return cached;
        }
        final updated = _entriesWithCurrentGutterModel(
          cached,
          document: document,
          foldRegions: foldRegions,
          collapsedRegionKeys: collapsedRegionKeys,
          diagnostics: diagnostics,
        );
        _remember(
          controller: controller,
          foldRegions: foldRegions,
          collapsedRegionKeys: collapsedRegionKeys,
          textStyle: textStyle,
          strutStyle: strutStyle,
          lineHeight: lineHeight,
          textWidth: textWidth,
          textScaler: textScaler,
          diagnostics: diagnostics,
          entries: updated,
        );
        return updated;
      }
      final incremental = _incrementalEntries(
        context,
        controller: controller,
        previousDocument: _document,
        previousEntries: cached,
        foldRegions: foldRegions,
        collapsedRegionKeys: collapsedRegionKeys,
        textStyle: textStyle,
        strutStyle: strutStyle,
        lineHeight: lineHeight,
        textWidth: textWidth,
        diagnostics: diagnostics,
      );
      if (incremental != null) {
        _remember(
          controller: controller,
          foldRegions: foldRegions,
          collapsedRegionKeys: collapsedRegionKeys,
          textStyle: textStyle,
          strutStyle: strutStyle,
          lineHeight: lineHeight,
          textWidth: textWidth,
          textScaler: textScaler,
          diagnostics: diagnostics,
          entries: incremental,
        );
        return incremental;
      }
    }
    final entries = sourceLineLayoutEntries(
      context,
      controller: controller,
      foldRegions: foldRegions,
      collapsedRegionKeys: collapsedRegionKeys,
      textStyle: textStyle,
      strutStyle: strutStyle,
      lineHeight: lineHeight,
      textWidth: textWidth,
      diagnostics: diagnostics,
    );
    _remember(
      controller: controller,
      foldRegions: foldRegions,
      collapsedRegionKeys: collapsedRegionKeys,
      textStyle: textStyle,
      strutStyle: strutStyle,
      lineHeight: lineHeight,
      textWidth: textWidth,
      textScaler: textScaler,
      diagnostics: diagnostics,
      entries: entries,
    );
    return entries;
  }

  void _remember({
    required BusyMarkSourceEditingController controller,
    required List<SourceFoldRegion> foldRegions,
    required Set<String> collapsedRegionKeys,
    required TextStyle textStyle,
    required StrutStyle? strutStyle,
    required double lineHeight,
    required double textWidth,
    required TextScaler textScaler,
    required List<SourceDiagnosticMarker> diagnostics,
    required List<SourceLineLayoutEntry> entries,
  }) {
    _document = controller.document;
    _language = controller.language;
    _foldRegions = foldRegions;
    _collapsedRegionKeys = Set.unmodifiable(collapsedRegionKeys);
    _textStyle = textStyle;
    _strutStyle = strutStyle;
    _lineHeight = lineHeight;
    _textWidth = textWidth;
    _textScaler = textScaler;
    _diagnostics = diagnostics;
    _entries = entries;
  }
}

bool _setEquals(Set<String> left, Set<String> right) {
  return left.length == right.length && left.containsAll(right);
}

({int start, int end}) sourceVisibleLayoutRange(
  List<SourceLineLayoutEntry> layouts, {
  required double scrollOffset,
  required double viewportHeight,
  double overscan = 0,
}) {
  if (layouts.isEmpty || viewportHeight <= 0) {
    return (start: 0, end: 0);
  }
  final minimum = math.max(0, scrollOffset - overscan);
  final maximum = scrollOffset + viewportHeight + overscan;
  var low = 0;
  var high = layouts.length;
  while (low < high) {
    final middle = (low + high) >> 1;
    final entry = layouts[middle];
    if (entry.top + entry.height < minimum) {
      low = middle + 1;
    } else {
      high = middle;
    }
  }
  final start = low;
  low = start;
  high = layouts.length;
  while (low < high) {
    final middle = (low + high) >> 1;
    if (layouts[middle].top <= maximum) {
      low = middle + 1;
    } else {
      high = middle;
    }
  }
  return (start: start, end: low);
}

List<SourceLineLayoutEntry> _entriesWithCurrentGutterModel(
  List<SourceLineLayoutEntry> entries, {
  required SourceDocument document,
  required List<SourceFoldRegion> foldRegions,
  required Set<String> collapsedRegionKeys,
  required Iterable<SourceDiagnosticMarker> diagnostics,
}) {
  final gutterLines = sourceGutterModel(
    document: document,
    foldRegions: foldRegions,
    collapsedRegionKeys: collapsedRegionKeys,
    diagnostics: diagnostics,
  );
  if (gutterLines.length != entries.length) {
    return entries;
  }
  return List<SourceLineLayoutEntry>.generate(
    entries.length,
    (index) => SourceLineLayoutEntry(
      gutterLine: gutterLines[index],
      top: entries[index].top,
      height: entries[index].height,
    ),
    growable: false,
  );
}

List<SourceLineLayoutEntry>? _incrementalEntries(
  BuildContext context, {
  required BusyMarkSourceEditingController controller,
  required SourceDocument? previousDocument,
  required List<SourceLineLayoutEntry> previousEntries,
  required List<SourceFoldRegion> foldRegions,
  required Set<String> collapsedRegionKeys,
  required TextStyle textStyle,
  required StrutStyle? strutStyle,
  required double lineHeight,
  required double textWidth,
  required Iterable<SourceDiagnosticMarker> diagnostics,
}) {
  final edit = controller.lastVisibleEdit;
  if (previousDocument == null ||
      previousDocument.hasHiddenRanges ||
      controller.document.hasHiddenRanges ||
      edit == null ||
      previousEntries.length != previousDocument.lineIndex.lineCount ||
      edit.fullStart < 0 ||
      edit.fullEnd < edit.fullStart ||
      edit.fullEnd > previousDocument.fullText.length ||
      controller.fullText.length !=
          previousDocument.fullText.length + edit.fullDelta) {
    return null;
  }
  final previousPrefix = previousDocument.fullText.substring(0, edit.fullStart);
  final previousSuffix = previousDocument.fullText.substring(edit.fullEnd);
  if (!controller.fullText.startsWith(previousPrefix) ||
      !controller.fullText.endsWith(previousSuffix)) {
    return null;
  }

  final previousStartLine = previousDocument.lineIndex.lineNumberAtOffset(
    edit.fullStart,
  );
  final previousEndLine = previousDocument.lineIndex.lineNumberAtOffset(
    edit.fullEnd,
  );
  final document = controller.document;
  final nextEndLine = document.lineIndex.lineNumberAtOffset(
    edit.fullStart + edit.replacement.length,
  );
  if (controller.language == SourceSyntaxLanguage.markdown &&
      (_markdownEditCanChangeLayout(
            previousDocument,
            previousStartLine,
            previousEndLine,
          ) ||
          _markdownEditCanChangeLayout(
            document,
            previousStartLine,
            nextEndLine,
          ))) {
    return null;
  }
  final gutterLines = sourceGutterModel(
    document: document,
    foldRegions: foldRegions,
    collapsedRegionKeys: collapsedRegionKeys,
    diagnostics: diagnostics,
  );
  if (gutterLines.length != document.lineIndex.lineCount) {
    return null;
  }

  final result = <SourceLineLayoutEntry>[];
  var top = previousEntries.first.top;
  for (var lineNumber = 1; lineNumber <= gutterLines.length; lineNumber++) {
    final double height;
    final double advance;
    if (lineNumber < previousStartLine) {
      height = previousEntries[lineNumber - 1].height;
      advance = _sourceLineAdvance(previousEntries, lineNumber - 1);
    } else if (lineNumber <= nextEndLine) {
      final measurement = _measureSourceLogicalLine(
        context,
        document.lineIndex.lineAt(lineNumber),
        textStyle: textStyle,
        strutStyle: strutStyle,
        lineHeight: lineHeight,
        textWidth: textWidth,
      );
      height = measurement.height;
      advance = measurement.advance;
    } else {
      final previousLineNumber = lineNumber + previousEndLine - nextEndLine;
      if (previousLineNumber < 1 ||
          previousLineNumber > previousEntries.length) {
        return null;
      }
      height = previousEntries[previousLineNumber - 1].height;
      advance = _sourceLineAdvance(previousEntries, previousLineNumber - 1);
    }
    result.add(
      SourceLineLayoutEntry(
        gutterLine: gutterLines[lineNumber - 1],
        top: top,
        height: height,
      ),
    );
    top += advance;
  }
  return result;
}

bool _markdownEditCanChangeLayout(
  SourceDocument document,
  int startLine,
  int endLine,
) {
  for (var lineNumber = startLine; lineNumber <= endLine; lineNumber++) {
    if (lineNumber < 1 || lineNumber > document.lineIndex.lineCount) {
      continue;
    }
    final text = document.lineIndex.lineAt(lineNumber).text;
    // These characters can introduce a heading, emphasis, inline code, or a
    // fence whose layout rules affect this line or later lines. Falling back
    // to the full painter keeps incremental geometry exactly equivalent.
    if (text.contains(RegExp(r'[#*_`~]'))) {
      return true;
    }
  }
  return false;
}

double _sourceLineAdvance(List<SourceLineLayoutEntry> entries, int index) {
  if (index + 1 >= entries.length) {
    return entries[index].height;
  }
  return entries[index + 1].top - entries[index].top;
}

({double height, double advance}) _measureSourceLogicalLine(
  BuildContext context,
  SourceLine line, {
  required TextStyle textStyle,
  required StrutStyle? strutStyle,
  required double lineHeight,
  required double textWidth,
}) {
  final painter = TextPainter(
    text: TextSpan(text: '${line.text}\n ', style: textStyle),
    strutStyle: strutStyle,
    textDirection: TextDirection.ltr,
    textHeightBehavior: sourceTextHeightBehavior,
    textScaler: MediaQuery.textScalerOf(context),
  )..layout(minWidth: math.max(1, textWidth), maxWidth: math.max(1, textWidth));
  final top = sourceTextTopForOffset(painter, 0);
  final nextTop = sourceTextTopForOffset(painter, line.text.length + 1);
  final advance = nextTop - top;
  final height = math.max(lineHeight, advance);
  painter.dispose();
  return (height: height, advance: advance);
}

List<SourceLineLayoutEntry> sourceLineLayoutEntries(
  BuildContext context, {
  required BusyMarkSourceEditingController controller,
  required List<SourceFoldRegion> foldRegions,
  required Set<String> collapsedRegionKeys,
  required TextStyle textStyle,
  required StrutStyle? strutStyle,
  required double lineHeight,
  required double textWidth,
  Iterable<SourceDiagnosticMarker> diagnostics = const [],
}) {
  final gutterLines = sourceGutterModel(
    document: controller.document,
    foldRegions: foldRegions,
    collapsedRegionKeys: collapsedRegionKeys,
    diagnostics: diagnostics,
  );
  final layouts = <SourceLineLayoutEntry>[];
  final painter = sourceTextPainter(
    context,
    controller: controller,
    textStyle: textStyle,
    strutStyle: strutStyle,
    textWidth: textWidth,
    hideCollapsedStartLines: true,
  );
  for (final line in gutterLines) {
    final visibleLine = controller.document.visibleLineForFullLine(
      line.fullLine,
    );
    final top =
        BusyMarkSourceEditorMetrics.paddingTop +
        (visibleLine == null
            ? 0
            : sourceTextTopForOffset(painter, visibleLine.startOffset));
    final height = visibleLine == null
        ? lineHeight
        : sourceTextHeightForLine(
            painter,
            controller.document.visibleLineIndex,
            visibleLine,
            lineHeight,
          );
    layouts.add(
      SourceLineLayoutEntry(
        gutterLine: SourceGutterLine(
          fullLine: line.fullLine,
          visibleLine: line.visibleLine,
          foldRegion: line.foldRegion,
          collapsed: line.collapsed,
          diagnostics: line.diagnostics,
        ),
        top: top,
        height: height,
      ),
    );
  }
  painter.dispose();
  return layouts;
}

TextPainter sourceTextPainter(
  BuildContext context, {
  required BusyMarkSourceEditingController controller,
  required TextStyle textStyle,
  required StrutStyle? strutStyle,
  required double textWidth,
  bool hideCollapsedStartLines = false,
}) {
  return TextPainter(
    text: controller.buildSourceTextSpan(
      context: context,
      style: textStyle,
      hideCollapsedStartLines: hideCollapsedStartLines,
    ),
    strutStyle: strutStyle,
    textDirection: TextDirection.ltr,
    textHeightBehavior: sourceTextHeightBehavior,
    textScaler: MediaQuery.textScalerOf(context),
  )..layout(minWidth: math.max(1, textWidth), maxWidth: math.max(1, textWidth));
}

double sourceTextTopForOffset(TextPainter painter, int offset) {
  return painter.getOffsetForCaret(TextPosition(offset: offset), Rect.zero).dy;
}

double sourceTextHeightForLine(
  TextPainter painter,
  SourceLineIndex visibleLineIndex,
  SourceLine line,
  double fallback,
) {
  final top = sourceTextTopForOffset(painter, line.startOffset);
  if (line.number < visibleLineIndex.lineCount) {
    final nextLine = visibleLineIndex.lineAt(line.number + 1);
    final nextTop = sourceTextTopForOffset(painter, nextLine.startOffset);
    if (nextTop > top) {
      return math.max(fallback, nextTop - top);
    }
  }
  final metrics = painter.computeLineMetrics();
  for (final metric in metrics) {
    final metricTop = metric.baseline - metric.ascent;
    if (top >= metricTop - 0.5 && top < metricTop + metric.height + 0.5) {
      return math.max(fallback, metric.height);
    }
  }
  return fallback;
}

ScrollPosition? safeScrollPosition(ScrollController controller) {
  return controller.positions.isEmpty ? null : controller.positions.last;
}

double safeScrollOffset(ScrollController controller) {
  return safeScrollPosition(controller)?.pixels ?? 0.0;
}

double safeMaxScrollExtent(ScrollController controller) {
  return safeScrollPosition(controller)?.maxScrollExtent ?? 0.0;
}

Color sourceDiagnosticColorForSeverity(
  BuildContext context,
  DiagnosticSeverity severity,
) {
  return switch (severity) {
    DiagnosticSeverity.error => busyMarkStatusColor(
      context,
      BusyMarkStatusKind.error,
    ),
    DiagnosticSeverity.warning => busyMarkStatusColor(
      context,
      BusyMarkStatusKind.warning,
    ),
    DiagnosticSeverity.info => busyMarkStatusColor(
      context,
      BusyMarkStatusKind.information,
    ),
    DiagnosticSeverity.hint => BusyMarkSurfaceColors.of(context).muted,
  };
}

String _foldKindLabel(BuildContext context, SourceFoldKind kind) {
  return switch (kind) {
    SourceFoldKind.section => context.l10n.foldKindSection,
    SourceFoldKind.list => context.l10n.foldKindList,
    SourceFoldKind.blockquote => context.l10n.foldKindQuote,
    SourceFoldKind.code => context.l10n.codeBlock,
    SourceFoldKind.xml => context.l10n.foldKindTag,
  };
}
