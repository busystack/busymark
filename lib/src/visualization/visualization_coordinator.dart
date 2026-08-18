import 'dart:async';

import 'visualization_cache.dart';
import 'visualization_models.dart';
import 'visualization_renderer.dart';

class VisualizationCoordinator {
  VisualizationCoordinator({
    required Iterable<VisualizationRenderer> renderers,
    VisualizationCache? cache,
    this.maximumConcurrentRenders = 2,
  }) : cache = cache ?? VisualizationCache() {
    if (maximumConcurrentRenders < 1) {
      throw ArgumentError.value(
        maximumConcurrentRenders,
        'maximumConcurrentRenders',
        'Must be at least one.',
      );
    }
    for (final renderer in renderers) {
      for (final kind in renderer.supportedKinds) {
        if (_renderers.containsKey(kind)) {
          throw ArgumentError('More than one renderer supports ${kind.name}.');
        }
        _renderers[kind] = renderer;
      }
    }
  }

  final VisualizationCache cache;
  final int maximumConcurrentRenders;
  final Map<VisualizationRendererKind, VisualizationRenderer> _renderers = {};
  final Map<String, VisualizationCancellationToken> _activeTokens = {};
  final Map<String, int> _latestRevisions = {};
  final Map<String, VisualizationRenderResult> _lastSuccessful = {};
  final List<_QueuedRender> _queue = [];
  var _running = 0;
  var _disposed = false;

  VisualizationRenderResult? lastSuccessfulFor(String blockKey) =>
      _lastSuccessful[blockKey];

  Future<VisualizationRenderResult> render(
    VisualizationRenderRequest request,
  ) async {
    if (_disposed) {
      throw StateError('VisualizationCoordinator has been disposed.');
    }
    final latestRevision = _latestRevisions[request.blockKey];
    if (latestRevision != null && request.editRevision < latestRevision) {
      throw const VisualizationSupersededException();
    }
    _latestRevisions[request.blockKey] = request.editRevision;
    _activeTokens.remove(request.blockKey)?.cancel();
    final token = VisualizationCancellationToken();
    _activeTokens[request.blockKey] = token;

    final renderer = _renderers[request.kind];
    if (renderer == null) {
      if (identical(_activeTokens[request.blockKey], token)) {
        _activeTokens.remove(request.blockKey);
      }
      return FailedVisualizationResult(
        code: 'visualization.rendererUnavailable',
        message: '${request.kind.displayName} is not available in this build.',
        retryable: false,
      );
    }

    try {
      final prepared = await renderer.prepare(request, token);
      _throwIfSuperseded(prepared, token);
      final cached = await cache.get(prepared.cacheKey);
      _throwIfSuperseded(prepared, token);
      if (cached != null) {
        if (cached.isSuccessful) {
          _lastSuccessful[prepared.blockKey] = cached;
        }
        return cached;
      }

      final completer = Completer<VisualizationRenderResult>();
      _queue.add(
        _QueuedRender(
          request: prepared,
          renderer: renderer,
          token: token,
          completer: completer,
        ),
      );
      _queue.sort(
        (left, right) => _priority(
          left.request.priority,
        ).compareTo(_priority(right.request.priority)),
      );
      _drain();
      return await completer.future;
    } on VisualizationCancelledException {
      throw const VisualizationSupersededException();
    } on VisualizationSupersededException {
      rethrow;
    } on Object catch (error) {
      return FailedVisualizationResult(
        code: 'visualization.preparationFailure',
        message: error.toString(),
      );
    } finally {
      if (identical(_activeTokens[request.blockKey], token)) {
        _activeTokens.remove(request.blockKey);
      }
    }
  }

  void cancel(String blockKey) {
    _latestRevisions.remove(blockKey);
    _activeTokens.remove(blockKey)?.cancel();
  }

  void clearLastSuccessful(String blockKey) {
    _lastSuccessful.remove(blockKey);
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
    for (final queued in _queue) {
      if (!queued.completer.isCompleted) {
        queued.completer.completeError(const VisualizationCancelledException());
      }
    }
    _queue.clear();
  }

  void _drain() {
    while (!_disposed &&
        _running < maximumConcurrentRenders &&
        _queue.isNotEmpty) {
      final queued = _queue.removeAt(0);
      if (queued.token.isCancelled) {
        if (!queued.completer.isCompleted) {
          queued.completer.completeError(
            const VisualizationSupersededException(),
          );
        }
        continue;
      }
      _running++;
      unawaited(_execute(queued));
    }
  }

  Future<void> _execute(_QueuedRender queued) async {
    try {
      _throwIfSuperseded(queued.request, queued.token);
      final result = await queued.renderer.render(queued.request, queued.token);
      _throwIfSuperseded(queued.request, queued.token);
      if (result.isSuccessful) {
        _lastSuccessful[queued.request.blockKey] = result;
        await cache.put(queued.request.cacheKey, result);
      }
      _throwIfSuperseded(queued.request, queued.token);
      if (!queued.completer.isCompleted) {
        queued.completer.complete(result);
      }
    } on VisualizationCancelledException {
      if (!queued.completer.isCompleted) {
        queued.completer.completeError(
          const VisualizationSupersededException(),
        );
      }
    } on VisualizationSupersededException catch (error, stackTrace) {
      if (!queued.completer.isCompleted) {
        queued.completer.completeError(error, stackTrace);
      }
    } on Object catch (error) {
      if (!queued.completer.isCompleted) {
        queued.completer.complete(
          FailedVisualizationResult(
            code: 'visualization.rendererFailure',
            message: error.toString(),
          ),
        );
      }
    } finally {
      _running--;
      _drain();
    }
  }

  void _throwIfSuperseded(
    VisualizationRenderRequest request,
    VisualizationCancellationToken token,
  ) {
    token.throwIfCancelled();
    if (_latestRevisions[request.blockKey] != request.editRevision ||
        !identical(_activeTokens[request.blockKey], token)) {
      throw const VisualizationSupersededException();
    }
  }
}

class _QueuedRender {
  const _QueuedRender({
    required this.request,
    required this.renderer,
    required this.token,
    required this.completer,
  });

  final VisualizationRenderRequest request;
  final VisualizationRenderer renderer;
  final VisualizationCancellationToken token;
  final Completer<VisualizationRenderResult> completer;
}

int _priority(VisualizationRenderPriority priority) => switch (priority) {
  VisualizationRenderPriority.export => -1,
  VisualizationRenderPriority.visible => 0,
  VisualizationRenderPriority.nearVisible => 1,
  VisualizationRenderPriority.background => 2,
};
