import 'dart:async';
import 'dart:collection';

import 'visualization_cache.dart';
import 'visualization_models.dart';
import 'visualization_renderer.dart';

class VisualizationCoordinator {
  VisualizationCoordinator({
    required Iterable<VisualizationRenderer> renderers,
    VisualizationCache? cache,
    this.maximumConcurrentRenders = 2,
    this.maximumLastSuccessfulEntries = 128,
  }) : cache = cache ?? VisualizationCache() {
    if (maximumConcurrentRenders < 1) {
      throw ArgumentError.value(
        maximumConcurrentRenders,
        'maximumConcurrentRenders',
        'Must be at least one.',
      );
    }
    if (maximumLastSuccessfulEntries < 1) {
      throw ArgumentError.value(
        maximumLastSuccessfulEntries,
        'maximumLastSuccessfulEntries',
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
  final int maximumLastSuccessfulEntries;
  final Map<VisualizationRendererKind, VisualizationRenderer> _renderers = {};
  final Map<String, VisualizationCancellationToken> _activeTokens = {};
  final Map<String, int> _latestRevisions = {};
  final LinkedHashMap<String, VisualizationRenderResult> _lastSuccessful =
      LinkedHashMap();
  final List<_QueuedRender> _queue = [];
  var _running = 0;
  var _disposed = false;

  VisualizationRenderResult? lastSuccessfulFor(String blockKey) {
    final result = _lastSuccessful.remove(blockKey);
    if (result != null) {
      _lastSuccessful[blockKey] = result;
    }
    return result;
  }

  /// Freeze renderer dependencies before a long-running export starts. The
  /// opaque result can only be rendered by this coordinator.
  Future<CapturedVisualizationRequest> capture(
    VisualizationRenderRequest request,
    VisualizationCancellationToken token,
  ) async {
    if (_disposed) {
      throw StateError('VisualizationCoordinator has been disposed.');
    }
    final renderer = _renderers[request.kind];
    if (renderer == null) {
      throw StateError('The visualization renderer is unavailable.');
    }
    final prepared = await renderer.prepare(request, token);
    token.throwIfCancelled();
    return CapturedVisualizationRequest._(this, prepared);
  }

  Future<VisualizationRenderResult> renderCaptured(
    CapturedVisualizationRequest captured,
  ) {
    if (!identical(captured._owner, this)) {
      throw ArgumentError(
        'The captured request belongs to another coordinator.',
      );
    }
    return _render(captured.request, captured: true);
  }

  Future<VisualizationRenderResult> render(
    VisualizationRenderRequest request,
  ) => _render(request);

  Future<VisualizationRenderResult> _render(
    VisualizationRenderRequest request, {
    bool captured = false,
  }) async {
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
      final prepared = captured
          ? request
          : await renderer.prepare(request, token);
      _throwIfSuperseded(prepared, token);
      final cached = await cache.get(prepared.cacheKey);
      _throwIfSuperseded(prepared, token);
      if (cached != null) {
        if (cached.isSuccessful) {
          _rememberLastSuccessful(prepared.blockKey, cached);
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
    _latestRevisions.clear();
    _lastSuccessful.clear();
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
        _rememberLastSuccessful(queued.request.blockKey, result);
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

  void _rememberLastSuccessful(
    String blockKey,
    VisualizationRenderResult result,
  ) {
    _lastSuccessful.remove(blockKey);
    _lastSuccessful[blockKey] = result;
    while (_lastSuccessful.length > maximumLastSuccessfulEntries) {
      _lastSuccessful.remove(_lastSuccessful.keys.first);
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

/// An in-memory snapshot of validated renderer inputs and local dependencies.
class CapturedVisualizationRequest {
  const CapturedVisualizationRequest._(this._owner, this.request);
  final VisualizationCoordinator _owner;
  final VisualizationRenderRequest request;
}
