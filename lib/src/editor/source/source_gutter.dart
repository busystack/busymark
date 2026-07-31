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
    diagnosticsByLine
        .putIfAbsent(diagnostic.fullLine, () => <SourceDiagnosticMarker>[])
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
                final layouts = sourceLineLayoutEntries(
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
                final activeLine = sourceLineNumberForOffset(
                  controller.fullText,
                  controller.visibleOffsetToFullOffset(
                    controller.selection.extentOffset,
                  ),
                );
                final scrollOffset = safeScrollOffset(scrollController);
                final children = <Widget>[];
                for (final layout in layouts) {
                  final top = layout.top - scrollOffset;
                  if (top < -lineHeight || top > constraints.maxHeight) {
                    continue;
                  }
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
  final linesByFullLine = {
    for (final line in controller.document.lineIndex.lines) line.number: line,
  };
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
  linesByFullLine.clear();
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
