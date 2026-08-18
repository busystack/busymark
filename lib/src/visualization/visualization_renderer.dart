import 'dart:async';

import 'visualization_models.dart';

class VisualizationCancellationToken {
  bool _cancelled = false;
  final List<void Function()> _listeners = [];

  bool get isCancelled => _cancelled;

  void cancel() {
    if (_cancelled) {
      return;
    }
    _cancelled = true;
    for (final listener in List.of(_listeners)) {
      listener();
    }
    _listeners.clear();
  }

  void throwIfCancelled() {
    if (_cancelled) {
      throw const VisualizationCancelledException();
    }
  }

  void onCancel(void Function() listener) {
    if (_cancelled) {
      listener();
      return;
    }
    _listeners.add(listener);
  }

  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }
}

class VisualizationCancelledException implements Exception {
  const VisualizationCancelledException();
}

class VisualizationSupersededException implements Exception {
  const VisualizationSupersededException();
}

abstract interface class VisualizationRenderer {
  Set<VisualizationRendererKind> get supportedKinds;

  Future<VisualizationRenderRequest> prepare(
    VisualizationRenderRequest request,
    VisualizationCancellationToken cancellationToken,
  ) async => request;

  Future<VisualizationRenderResult> render(
    VisualizationRenderRequest request,
    VisualizationCancellationToken cancellationToken,
  );
}
