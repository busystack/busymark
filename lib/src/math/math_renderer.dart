import 'dart:async';

import '../visualization/generated_svg_normalizer.dart';
import '../visualization/visualization_renderer.dart';
import '../visualization/web_render_host.dart';
import 'math_models.dart';
import 'math_svg_preprocessor.dart';

class MathRenderer {
  const MathRenderer({
    required this.host,
    this.preprocessor = const MathSvgPreprocessor(),
    this.svgNormalizer = const GeneratedSvgNormalizer(
      maximumBytes: busyMarkMaximumMathSvgBytes,
    ),
  });

  final WebRenderHost host;
  final MathSvgPreprocessor preprocessor;
  final GeneratedSvgNormalizer svgNormalizer;

  Future<List<MathRenderResult>> renderBatch(
    List<MathRenderRequest> requests,
    VisualizationCancellationToken cancellationToken,
  ) async {
    if (requests.isEmpty) {
      return const [];
    }
    if (requests.length > busyMarkMaximumMathBatchExpressions ||
        requests.fold<int>(
              0,
              (total, request) => total + request.expression.length,
            ) >
            busyMarkMaximumMathBatchCharacters) {
      return [
        for (final request in requests)
          _failure(request.expressionId, 'math.resourceLimit'),
      ];
    }

    final valid = <MathRenderRequest>[];
    final immediate = <String, MathRenderResult>{};
    for (final request in requests) {
      if (request.expression.isEmpty ||
          request.expression.length > busyMarkMaximumMathExpressionCharacters) {
        immediate[request.expressionId] = _failure(
          request.expressionId,
          request.expression.isEmpty ? 'math.invalidTex' : 'math.resourceLimit',
        );
      } else {
        valid.add(request);
      }
    }
    if (valid.isEmpty) {
      return [for (final request in requests) immediate[request.expressionId]!];
    }

    try {
      final hostIds = <String, MathRenderRequest>{};
      final payload = <Map<String, Object?>>[];
      for (final (index, request) in valid.indexed) {
        final hostId = 'math-$index-${request.cacheKey.substring(0, 12)}';
        hostIds[hostId] = request;
        payload.add({
          'id': hostId,
          'expression': request.expression,
          'display': request.display,
          'em': request.em,
          'ex': request.ex,
          'containerWidth': request.widthBucket,
          'renderProfile': request.renderProfile,
          'svgIdPrefix': 'bm-${request.cacheKey.substring(0, 16)}',
        });
      }
      final response = await host.renderMathBatch(
        expressions: payload,
        cancellationToken: cancellationToken,
      );
      cancellationToken.throwIfCancelled();
      final byExpression = <String, MathRenderResult>{...immediate};
      final rawResults = response['results'];
      if (rawResults is! List<Object?>) {
        throw const WebRenderHostException(
          'math.rendererUnavailable',
          'The MathJax host returned an invalid response.',
        );
      }
      for (final raw in rawResults.whereType<Map<Object?, Object?>>()) {
        final hostId = raw['id'] as String? ?? '';
        final request = hostIds[hostId];
        if (request == null) {
          continue;
        }
        byExpression[request.expressionId] = _decodeResult(request, raw);
      }
      return [
        for (final request in requests)
          byExpression[request.expressionId] ??
              _failure(request.expressionId, 'math.rendererUnavailable'),
      ];
    } on VisualizationCancelledException {
      rethrow;
    } on TimeoutException {
      return [
        for (final request in requests)
          FailedMathResult(
            expressionId: request.expressionId,
            kind: MathRenderErrorKind.timeout,
            code: 'math.timeout',
          ),
      ];
    } on WebRenderHostException catch (error) {
      return [
        for (final request in requests)
          FailedMathResult(
            expressionId: request.expressionId,
            kind: MathRenderErrorKind.rendererUnavailable,
            code: 'math.rendererUnavailable',
            debugDetail: error.toString(),
          ),
      ];
    } on Object catch (error) {
      return [
        for (final request in requests)
          FailedMathResult(
            expressionId: request.expressionId,
            kind: MathRenderErrorKind.rendererUnavailable,
            code: 'math.rendererUnavailable',
            debugDetail: error.toString(),
          ),
      ];
    }
  }

  MathRenderResult _decodeResult(
    MathRenderRequest request,
    Map<Object?, Object?> raw,
  ) {
    final rawError = raw['error'];
    if (rawError is Map<Object?, Object?>) {
      return _failure(
        request.expressionId,
        rawError['code'] as String? ?? 'math.invalidTex',
        debugDetail:
            rawError['detail'] as String? ?? rawError['message'] as String?,
      );
    }
    final source = raw['svg'];
    if (source is! String || source.isEmpty) {
      return _failure(request.expressionId, 'math.rendererUnavailable');
    }
    try {
      final prepared = preprocessor.preprocess(
        source,
        ex: request.ex,
        reportedDepth: (raw['depth'] as num?)?.toDouble(),
      );
      final normalized = svgNormalizer.normalize(prepared.svg);
      final vector = normalized.vectorSafeSvg;
      if (vector == null) {
        return _failure(request.expressionId, 'math.unsafeOutput');
      }
      final width = (raw['width'] as num?)?.toDouble() ?? 1;
      final height = (raw['height'] as num?)?.toDouble() ?? 1;
      final depth = prepared.depth.clamp(0, height).toDouble();
      return RenderedMathResult(
        expressionId: request.expressionId,
        svg: normalized.browserSafeSvg,
        vectorSvg: vector,
        width: width > 0 && width.isFinite ? width : 1,
        height: height > 0 && height.isFinite ? height : 1,
        depth: depth,
        baseline: height - depth,
      );
    } on Object catch (error) {
      return FailedMathResult(
        expressionId: request.expressionId,
        kind: MathRenderErrorKind.unsafeOutput,
        code: 'math.unsafeOutput',
        debugDetail: error.toString(),
      );
    }
  }

  FailedMathResult _failure(
    String expressionId,
    String code, {
    String? debugDetail,
  }) {
    final kind = switch (code) {
      'math.resourceLimit' => MathRenderErrorKind.resourceLimit,
      'math.timeout' => MathRenderErrorKind.timeout,
      'math.unsafeOutput' => MathRenderErrorKind.unsafeOutput,
      'math.cancelled' => MathRenderErrorKind.cancelled,
      'math.rendererUnavailable' => MathRenderErrorKind.rendererUnavailable,
      _ => MathRenderErrorKind.invalidTex,
    };
    return FailedMathResult(
      expressionId: expressionId,
      kind: kind,
      code: code,
      debugDetail: debugDetail,
    );
  }
}
