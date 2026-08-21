import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app/busymark_design.dart';
import '../app/localization.dart';
import 'math_models.dart';
import 'math_providers.dart';

var _nextMathWidgetInstance = 0;

class BusyMarkInlineMath extends StatelessWidget {
  const BusyMarkInlineMath({
    super.key,
    required this.expression,
    required this.expressionId,
    required this.editRevision,
    required this.textStyle,
    this.containerWidth = BusyMarkSizes.documentContentWidth,
    this.onFailure,
  });

  final String expression;
  final String expressionId;
  final int editRevision;
  final TextStyle textStyle;
  final double containerWidth;
  final ValueChanged<FailedMathResult>? onFailure;

  @override
  Widget build(BuildContext context) {
    final fontSize =
        textStyle.fontSize ?? DefaultTextStyle.of(context).style.fontSize ?? 16;
    return _MathFormula(
      expression: expression,
      expressionId: expressionId,
      editRevision: editRevision,
      display: false,
      em: fontSize,
      ex: fontSize / 2,
      containerWidth: containerWidth,
      textStyle: textStyle,
      onFailure: onFailure,
    );
  }
}

class BusyMarkDisplayMath extends StatelessWidget {
  const BusyMarkDisplayMath({
    super.key,
    required this.expression,
    required this.expressionId,
    required this.editRevision,
    this.onFailure,
  });

  final String expression;
  final String expressionId;
  final int editRevision;
  final ValueChanged<FailedMathResult>? onFailure;

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style;
    final fontSize = style.fontSize ?? 16;
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : BusyMarkSizes.documentContentWidth;
        return _MathFormula(
          expression: expression,
          expressionId: expressionId,
          editRevision: editRevision,
          display: true,
          em: fontSize,
          ex: fontSize / 2,
          containerWidth: availableWidth,
          textStyle: style,
          onFailure: onFailure,
        );
      },
    );
  }
}

class _MathFormula extends ConsumerStatefulWidget {
  const _MathFormula({
    required this.expression,
    required this.expressionId,
    required this.editRevision,
    required this.display,
    required this.em,
    required this.ex,
    required this.containerWidth,
    required this.textStyle,
    this.onFailure,
  });

  final String expression;
  final String expressionId;
  final int editRevision;
  final bool display;
  final double em;
  final double ex;
  final double containerWidth;
  final TextStyle textStyle;
  final ValueChanged<FailedMathResult>? onFailure;

  @override
  ConsumerState<_MathFormula> createState() => _MathFormulaState();
}

class _MathFormulaState extends ConsumerState<_MathFormula> {
  late final String _blockKey = 'math-widget-${_nextMathWidgetInstance++}';
  late final _coordinator = ref.read(mathCoordinatorProvider);
  Future<MathRenderResult>? _render;

  @override
  void initState() {
    super.initState();
    _scheduleRender();
  }

  @override
  void didUpdateWidget(covariant _MathFormula oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expression != widget.expression ||
        oldWidget.display != widget.display ||
        oldWidget.editRevision != widget.editRevision ||
        oldWidget.em != widget.em ||
        oldWidget.ex != widget.ex ||
        oldWidget.containerWidth != widget.containerWidth) {
      _scheduleRender();
    }
  }

  @override
  void dispose() {
    _coordinator.cancel(_blockKey);
    super.dispose();
  }

  void _scheduleRender() {
    _render = _coordinator.render(
      MathRenderRequest(
        expressionId: widget.expressionId,
        expression: widget.expression,
        display: widget.display,
        blockKey: _blockKey,
        editRevision: widget.editRevision,
        em: widget.em,
        ex: widget.ex,
        containerWidth: widget.containerWidth,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MathRenderResult>(
      future: _render,
      builder: (context, snapshot) {
        final result = snapshot.data;
        if (result is RenderedMathResult) {
          return _rendered(context, result);
        }
        if (result is FailedMathResult) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) widget.onFailure?.call(result);
          });
        }
        return _fallback(context, failed: result is FailedMathResult);
      },
    );
  }

  Widget _rendered(BuildContext context, RenderedMathResult result) {
    final foreground =
        widget.textStyle.color ?? DefaultTextStyle.of(context).style.color;
    final picture = Semantics(
      image: true,
      label: widget.expression,
      child: ExcludeSemantics(
        child: SvgPicture.string(
          result.svg,
          width: result.width,
          height: result.height,
          fit: BoxFit.fill,
          colorFilter: foreground == null
              ? null
              : ColorFilter.mode(foreground, BlendMode.srcIn),
        ),
      ),
    );
    if (!widget.display) {
      return Baseline(
        baseline: result.baseline,
        baselineType: TextBaseline.alphabetic,
        child: SizedBox(
          width: math.max(1, result.width),
          height: math.max(1, result.height),
          child: picture,
        ),
      );
    }
    final formula = SizedBox(
      width: math.max(1, result.width),
      height: math.max(1, result.height),
      child: picture,
    );
    if (result.width <= widget.containerWidth) {
      return Center(child: formula);
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: formula,
    );
  }

  Widget _fallback(BuildContext context, {required bool failed}) {
    final colors = BusyMarkSurfaceColors.of(context);
    final style = widget.textStyle.copyWith(
      fontFamily: BusyMarkTypography.monoFontFamily,
      color: failed
          ? Theme.of(context).colorScheme.error
          : colors.mutedForeground,
      backgroundColor: failed ? colors.admonitionWarning : colors.control,
    );
    final fallback = !widget.display
        ? Text(
            widget.expression,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )
        : Container(
            width: double.infinity,
            padding: BusyMarkInsets.documentCodeBlock,
            color: failed ? colors.admonitionWarning : colors.control,
            child: SelectableText(widget.expression, style: style),
          );
    return failed
        ? Tooltip(message: context.l10n.mathRenderFailed, child: fallback)
        : fallback;
  }
}
