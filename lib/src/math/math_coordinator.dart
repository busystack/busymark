import 'dart:async';

import '../visualization/visualization_renderer.dart';
import 'math_cache.dart';
import 'math_models.dart';
import 'math_renderer.dart';
import 'math_svg_preprocessor.dart';

class MathCoordinator {
  MathCoordinator({
    required this.renderer,
    MathRenderCache? cache,
    this.preprocessor = const MathSvgPreprocessor(),
  }) : cache = cache ?? MathRenderCache();

  final MathRenderer renderer;
  final MathRenderCache cache;
  final MathSvgPreprocessor preprocessor;
  final List<_PendingMathRender> _pending = [];
  final Map<String, int> _latestRevisions = {};
  final Map<String, VisualizationCancellationToken> _activeTokens = {};
  var _flushScheduled = false;
  var _disposed = false;
  var _instanceSequence = 0;

  Future<MathRenderResult> render(MathRenderRequest request) {
    if (_disposed) {
      throw StateError('MathCoordinator has been disposed.');
    }
    final latest = _latestRevisions[request.blockKey];
    if (latest != null && request.editRevision < latest) {
      return Future.error(const MathSupersededException());
    }
    _latestRevisions[request.blockKey] = request.editRevision;
    _activeTokens.remove(request.blockKey)?.cancel();
    final token = VisualizationCancellationToken();
    _activeTokens[request.blockKey] = token;

    final cached = cache.get(request.cacheKey);
    if (cached != null) {
      _activeTokens.remove(request.blockKey);
      return Future.value(_forInstance(cached, request));
    }
    final completer = Completer<MathRenderResult>();
    _pending.add(
      _PendingMathRender(request: request, token: token, completer: completer),
    );
    if (!_flushScheduled) {
      _flushScheduled = true;
      scheduleMicrotask(_flush);
    }
    return completer.future;
  }

  Future<List<MathRenderResult>> renderAll(
    Iterable<MathRenderRequest> requests,
  ) {
    return Future.wait([for (final request in requests) render(request)]);
  }

  void cancel(String blockKey) {
    _latestRevisions.remove(blockKey);
    _activeTokens.remove(blockKey)?.cancel();
  }

  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    for (final token in _activeTokens.values) {
      token.cancel();
    }
    _activeTokens.clear();
    for (final item in _pending) {
      if (!item.completer.isCompleted) {
        item.completer.completeError(const MathSupersededException());
      }
    }
    _pending.clear();
  }

  Future<void> _flush() async {
    _flushScheduled = false;
    if (_disposed) {
      return;
    }
    while (_pending.isNotEmpty) {
      final batch = <_PendingMathRender>[];
      var aggregateCharacters = 0;
      for (final item in _pending) {
        if (batch.length >= busyMarkMaximumMathBatchExpressions ||
            (batch.isNotEmpty &&
                aggregateCharacters + item.request.expression.length >
                    busyMarkMaximumMathBatchCharacters)) {
          break;
        }
        batch.add(item);
        aggregateCharacters += item.request.expression.length;
      }
      _pending.removeRange(0, batch.length);
      final active = batch.where((item) => !item.token.isCancelled).toList();
      for (final item in batch.where((item) => item.token.isCancelled)) {
        _supersede(item);
      }
      if (active.isEmpty) {
        continue;
      }
      final batchToken = VisualizationCancellationToken();
      void cancelBatchWhenObsolete() {
        if (active.every((item) => item.token.isCancelled)) {
          batchToken.cancel();
        }
      }

      for (final item in active) {
        item.token.onCancel(cancelBatchWhenObsolete);
      }
      try {
        final results = await renderer.renderBatch([
          for (final item in active) item.request,
        ], batchToken);
        for (var index = 0; index < active.length; index++) {
          final item = active[index];
          if (_isSuperseded(item)) {
            _supersede(item);
            continue;
          }
          final result = results[index];
          if (result is RenderedMathResult) {
            cache.put(item.request.cacheKey, result);
          }
          if (!item.completer.isCompleted) {
            item.completer.complete(
              result is RenderedMathResult
                  ? _forInstance(result, item.request)
                  : result,
            );
          }
          if (identical(_activeTokens[item.request.blockKey], item.token)) {
            _activeTokens.remove(item.request.blockKey);
          }
        }
      } on VisualizationCancelledException {
        for (final item in active) {
          _supersede(item);
        }
      } on Object catch (error, stackTrace) {
        for (final item in active) {
          if (!item.completer.isCompleted) {
            item.completer.completeError(error, stackTrace);
          }
        }
      } finally {
        for (final item in active) {
          item.token.removeListener(cancelBatchWhenObsolete);
        }
      }
    }
  }

  bool _isSuperseded(_PendingMathRender item) {
    return item.token.isCancelled ||
        _latestRevisions[item.request.blockKey] != item.request.editRevision ||
        !identical(_activeTokens[item.request.blockKey], item.token);
  }

  void _supersede(_PendingMathRender item) {
    if (!item.completer.isCompleted) {
      item.completer.completeError(const MathSupersededException());
    }
  }

  RenderedMathResult _forInstance(
    RenderedMathResult result,
    MathRenderRequest request,
  ) {
    final prefix =
        'bm-${request.expressionId}-${request.editRevision}-${_instanceSequence++}';
    return result.copyWith(
      expressionId: request.expressionId,
      svg: preprocessor.rebaseLocalIds(result.svg, prefix),
      vectorSvg: preprocessor.rebaseLocalIds(result.vectorSvg, prefix),
    );
  }
}

class _PendingMathRender {
  const _PendingMathRender({
    required this.request,
    required this.token,
    required this.completer,
  });

  final MathRenderRequest request;
  final VisualizationCancellationToken token;
  final Completer<MathRenderResult> completer;
}
