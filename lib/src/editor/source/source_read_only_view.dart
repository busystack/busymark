import 'package:flutter/material.dart';

import '../../app/busymark_design.dart';
import '../source_highlighter.dart';
import 'source_gutter.dart';

enum BusyMarkReadOnlySourceLineTone { normal, added, removed, header }

class BusyMarkReadOnlySourceLine {
  const BusyMarkReadOnlySourceLine({
    required this.text,
    this.oldLineNumber,
    this.newLineNumber,
    this.tone = BusyMarkReadOnlySourceLineTone.normal,
    this.language,
    this.changeTargetIndex,
  });

  final String text;
  final int? oldLineNumber;
  final int? newLineNumber;
  final BusyMarkReadOnlySourceLineTone tone;
  final SourceSyntaxLanguage? language;
  final int? changeTargetIndex;
}

class BusyMarkReadOnlySourceLines extends StatelessWidget {
  const BusyMarkReadOnlySourceLines({
    super.key,
    required this.lines,
    required this.language,
    this.textStyle,
    this.padding = EdgeInsets.zero,
    this.changeKeys,
  });

  final List<BusyMarkReadOnlySourceLine> lines;
  final SourceSyntaxLanguage language;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry padding;
  final Map<int, GlobalKey>? changeKeys;

  @override
  Widget build(BuildContext context) {
    final effectiveTextStyle =
        textStyle ??
        Theme.of(context).textTheme.bodySmall?.copyWith(
          fontFamily: BusyMarkTypography.monoFontFamily,
          fontFamilyFallback: BusyMarkTypography.monoFontFamilyFallback,
          height: BusyMarkTypography.codeLineHeight,
          leadingDistribution: TextLeadingDistribution.even,
        ) ??
        const TextStyle(
          fontFamily: BusyMarkTypography.monoFontFamily,
          fontFamilyFallback: BusyMarkTypography.monoFontFamilyFallback,
          fontSize: BusyMarkTypography.defaultFontSize,
          height: BusyMarkTypography.codeLineHeight,
          leadingDistribution: TextLeadingDistribution.even,
        );
    final keyedTargets = <int>{};
    return SelectionArea(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final line in lines)
              _lineRow(line, effectiveTextStyle, keyedTargets),
          ],
        ),
      ),
    );
  }

  Widget _lineRow(
    BusyMarkReadOnlySourceLine line,
    TextStyle textStyle,
    Set<int> keyedTargets,
  ) {
    final row = BusyMarkReadOnlySourceLineRow(
      line: line,
      language: line.language ?? language,
      textStyle: textStyle,
    );
    final targetIndex = line.changeTargetIndex;
    final keys = changeKeys;
    if (targetIndex == null || keys == null || !keyedTargets.add(targetIndex)) {
      return row;
    }
    return KeyedSubtree(
      key: keys.putIfAbsent(targetIndex, GlobalKey.new),
      child: row,
    );
  }
}

class BusyMarkReadOnlySourceLineRow extends StatelessWidget {
  const BusyMarkReadOnlySourceLineRow({
    super.key,
    required this.line,
    required this.language,
    required this.textStyle,
  });

  static const gutterWidth = BusyMarkSizes.sourceGutterWidth + 28;

  final BusyMarkReadOnlySourceLine line;
  final SourceSyntaxLanguage language;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final foreground = line.tone == BusyMarkReadOnlySourceLineTone.header
        ? colors.mutedForeground
        : colors.foreground;
    return ColoredBox(
      color: _backgroundColor(colors),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: line.tone == BusyMarkReadOnlySourceLineTone.header
              ? BusyMarkSpacing.xs
              : 0,
        ),
        child: Row(
          textDirection: TextDirection.ltr,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: gutterWidth,
              child: _ReadOnlySourceLineNumbers(
                oldLineNumber: line.oldLineNumber,
                newLineNumber: line.newLineNumber,
                style: _gutterStyle(context, colors),
              ),
            ),
            Container(
              width: BusyMarkStroke.hairline,
              constraints: BoxConstraints(
                minHeight:
                    (textStyle.fontSize ?? BusyMarkTypography.defaultFontSize) *
                    BusyMarkTypography.codeLineHeight,
              ),
              color: colors.subtleBorder,
            ),
            const SizedBox(width: BusyMarkSourceEditorMetrics.paddingLeft),
            Expanded(
              child: Text.rich(
                buildBusyMarkReadOnlySourceTextSpan(
                  context: context,
                  source: line.text.isEmpty ? ' ' : line.text,
                  language: language,
                  style: textStyle,
                  foreground: foreground,
                ),
                textDirection: TextDirection.ltr,
                textHeightBehavior: sourceTextHeightBehavior,
                textScaler: MediaQuery.textScalerOf(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _backgroundColor(BusyMarkSurfaceColors colors) {
    return switch (line.tone) {
      BusyMarkReadOnlySourceLineTone.added => colors.admonitionTip,
      BusyMarkReadOnlySourceLineTone.removed => colors.admonitionWarning,
      BusyMarkReadOnlySourceLineTone.header => colors.control,
      BusyMarkReadOnlySourceLineTone.normal => BusyMarkLinuxPalette.transparent,
    };
  }

  TextStyle _gutterStyle(BuildContext context, BusyMarkSurfaceColors colors) {
    return textStyle.copyWith(
      color: colors.mutedForeground,
      fontSize:
          (textStyle.fontSize ?? BusyMarkTypography.defaultFontSize) *
          BusyMarkTypography.sourceLineNumberScale,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}

class _ReadOnlySourceLineNumbers extends StatelessWidget {
  const _ReadOnlySourceLineNumbers({
    required this.oldLineNumber,
    required this.newLineNumber,
    required this.style,
  });

  final int? oldLineNumber;
  final int? newLineNumber;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _ReadOnlySourceLineNumber(oldLineNumber, style)),
        Expanded(child: _ReadOnlySourceLineNumber(newLineNumber, style)),
      ],
    );
  }
}

class _ReadOnlySourceLineNumber extends StatelessWidget {
  const _ReadOnlySourceLineNumber(this.lineNumber, this.style);

  final int? lineNumber;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BusyMarkSpacing.xs),
      child: Text(
        lineNumber?.toString() ?? '',
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.right,
        style: style,
        overflow: TextOverflow.clip,
        softWrap: false,
      ),
    );
  }
}
