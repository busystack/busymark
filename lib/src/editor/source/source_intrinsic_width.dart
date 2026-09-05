import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/busymark_design.dart';
import '../source_highlighter.dart';

/// Resolves the unwrapped Source editor width without laying out the complete
/// document a second time.
class SourceIntrinsicWidthCache {
  static const int _largeFileColumnCap = 4096;

  Object? _document;
  SourceSyntaxLanguage? _language;
  TextStyle? _textStyle;
  StrutStyle? _strutStyle;
  TextScaler? _textScaler;
  Map<String, double> _lineWidths = const {};
  double? _largeFileEstimatedWidth;
  double? _width;
  int _lineMeasureCount = 0;
  bool _usingLargeFileEstimate = false;

  @visibleForTesting
  int get debugLineMeasureCount => _lineMeasureCount;

  @visibleForTesting
  bool get debugUsingLargeFileEstimate => _usingLargeFileEstimate;

  double resolve(
    BuildContext context, {
    required BusyMarkSourceEditingController controller,
    required TextStyle textStyle,
    required StrutStyle? strutStyle,
  }) {
    final document = controller.document;
    final textScaler = MediaQuery.textScalerOf(context);
    final cached = _width;
    if (cached != null &&
        identical(_document, document) &&
        _language == controller.language &&
        _textStyle == textStyle &&
        _strutStyle == strutStyle &&
        _textScaler == textScaler) {
      return cached;
    }

    final configurationChanged =
        _language != controller.language ||
        _textStyle != textStyle ||
        _strutStyle != strutStyle ||
        _textScaler != textScaler;
    if (configurationChanged) {
      _lineWidths = const {};
      _largeFileEstimatedWidth = null;
    }

    final double width;
    if (controller.sourceFeaturesDegraded) {
      _usingLargeFileEstimate = true;
      _lineWidths = const {};
      width = _largeFileEstimatedWidth ??= _estimateLargeFileWidth(
        textStyle: textStyle,
        textScaler: textScaler,
      );
    } else {
      _usingLargeFileEstimate = false;
      final retainedWidths = <String, double>{};
      var maximumLineWidth = 0.0;
      for (final line in document.visibleLineIndex.lines) {
        final lineWidth =
            _lineWidths[line.text] ??
            _measureLine(
              context,
              source: line.text,
              language: controller.language,
              textStyle: textStyle,
              strutStyle: strutStyle,
              textScaler: textScaler,
            );
        retainedWidths[line.text] = lineWidth;
        maximumLineWidth = math.max(maximumLineWidth, lineWidth);
      }
      _lineWidths = retainedWidths;
      width = math
          .max(1, maximumLineWidth + BusyMarkStroke.sourceCursor)
          .toDouble();
    }

    _document = document;
    _language = controller.language;
    _textStyle = textStyle;
    _strutStyle = strutStyle;
    _textScaler = textScaler;
    _width = width;
    return width;
  }

  double _measureLine(
    BuildContext context, {
    required String source,
    required SourceSyntaxLanguage language,
    required TextStyle textStyle,
    required StrutStyle? strutStyle,
    required TextScaler textScaler,
  }) {
    _lineMeasureCount++;
    final painter = TextPainter(
      text: buildBusyMarkReadOnlySourceTextSpan(
        context: context,
        source: source,
        language: language,
        style: textStyle,
      ),
      strutStyle: strutStyle,
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  double _estimateLargeFileWidth({
    required TextStyle textStyle,
    required TextScaler textScaler,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: 'M', style: textStyle),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout();
    final columnWidth = painter.width;
    painter.dispose();
    return math
        .max(1, columnWidth * _largeFileColumnCap + BusyMarkStroke.sourceCursor)
        .toDouble();
  }
}
