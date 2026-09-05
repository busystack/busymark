import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

const busyMarkMathJaxVersion = '4.1.3';
const busyMarkMathJaxFontVersion = '4.1.3';
const busyMarkMathPackageProfileVersion = 'busymark-math-v1';
const busyMarkMathMacroProfileVersion = 'busymark-macros-v1';
const busyMarkMathSvgNormalizationVersion = 'generated-svg-v1';
const busyMarkMaximumMathExpressionCharacters = 16 * 1024;
const busyMarkMaximumMathBatchExpressions = 128;
const busyMarkMaximumMathBatchCharacters = 256 * 1024;
const busyMarkMaximumMathSvgBytes = 2 * 1024 * 1024;

@immutable
class MathRenderRequest {
  const MathRenderRequest({
    required this.expressionId,
    required this.expression,
    required this.display,
    required this.blockKey,
    required this.editRevision,
    required this.em,
    required this.ex,
    required this.containerWidth,
    this.renderProfile = 'preview',
  });

  final String expressionId;
  final String expression;
  final bool display;
  final String blockKey;
  final int editRevision;
  final double em;
  final double ex;
  final double containerWidth;
  final String renderProfile;

  // Preview resizes share cache buckets. Exports must use their real geometry.
  double get renderWidth => renderProfile == 'preview'
      ? (containerWidth / 16).round() * 16.0
      : containerWidth;

  String get cacheKey => sha256
      .convert(
        utf8.encode(
          [
            busyMarkMathJaxVersion,
            busyMarkMathJaxFontVersion,
            busyMarkMathPackageProfileVersion,
            busyMarkMathMacroProfileVersion,
            busyMarkMathSvgNormalizationVersion,
            expression,
            '$display',
            renderProfile,
            em.toStringAsFixed(3),
            ex.toStringAsFixed(3),
            renderWidth.toString(),
          ].join('\u0000'),
        ),
      )
      .toString();
}

enum MathRenderErrorKind {
  invalidTex,
  resourceLimit,
  timeout,
  rendererUnavailable,
  unsafeOutput,
  cancelled,
}

sealed class MathRenderResult {
  const MathRenderResult({required this.expressionId});

  final String expressionId;
  bool get isSuccessful => this is RenderedMathResult;
}

@immutable
class RenderedMathResult extends MathRenderResult {
  const RenderedMathResult({
    required super.expressionId,
    required this.svg,
    required this.vectorSvg,
    required this.width,
    required this.height,
    required this.depth,
    required this.baseline,
  });

  final String svg;
  final String vectorSvg;
  final double width;
  final double height;
  final double depth;
  final double baseline;

  RenderedMathResult copyWith({
    String? expressionId,
    String? svg,
    String? vectorSvg,
  }) {
    return RenderedMathResult(
      expressionId: expressionId ?? this.expressionId,
      svg: svg ?? this.svg,
      vectorSvg: vectorSvg ?? this.vectorSvg,
      width: width,
      height: height,
      depth: depth,
      baseline: baseline,
    );
  }
}

@immutable
class FailedMathResult extends MathRenderResult {
  const FailedMathResult({
    required super.expressionId,
    required this.kind,
    required this.code,
    this.debugDetail,
  });

  final MathRenderErrorKind kind;
  final String code;
  final String? debugDetail;
}

class MathSupersededException implements Exception {
  const MathSupersededException();
}
