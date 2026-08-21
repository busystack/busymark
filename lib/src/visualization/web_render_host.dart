import 'dart:async';

import 'package:flutter/services.dart';

import 'visualization_models.dart';
import 'visualization_renderer.dart';

var _nextWebRenderRequestId = 0;

class OpenApiSourceReference {
  const OpenApiSourceReference({required this.value, this.line, this.column});

  factory OpenApiSourceReference.fromJson(Map<Object?, Object?> json) {
    return OpenApiSourceReference(
      value: json['value'] as String? ?? '',
      line: (json['line'] as num?)?.toInt(),
      column: (json['column'] as num?)?.toInt(),
    );
  }

  final String value;
  final int? line;
  final int? column;
}

abstract interface class WebRenderHost {
  Future<Map<Object?, Object?>> renderMathBatch({
    required List<Map<String, Object?>> expressions,
    required VisualizationCancellationToken cancellationToken,
  });

  Future<Map<Object?, Object?>> renderMermaid({
    required String source,
    required VisualizationTheme theme,
    required VisualizationCancellationToken cancellationToken,
  });

  Future<Map<Object?, Object?>> renderPlantUml({
    required String source,
    required VisualizationTheme theme,
    required VisualizationCancellationToken cancellationToken,
  });

  Future<List<OpenApiSourceReference>> inspectOpenApiReferences(
    String source,
    VisualizationCancellationToken cancellationToken,
  );

  Future<Map<Object?, Object?>> parseOpenApi({
    required String entryId,
    required String source,
    required List<VisualizationDependency> dependencies,
    required VisualizationCancellationToken cancellationToken,
  });

  Future<Uint8List> rasterizeSvg({
    required String svg,
    required double width,
    required double height,
    required double scale,
    required VisualizationCancellationToken cancellationToken,
  });

  Future<void> copyPngToClipboard(Uint8List pngBytes);

  Future<void> openOpenApiReference({
    required String title,
    required String entryId,
    required String source,
    required List<VisualizationDependency> dependencies,
    required VisualizationTheme theme,
  });
}

class PlatformWebRenderHost implements WebRenderHost {
  const PlatformWebRenderHost({
    MethodChannel channel = const MethodChannel(
      'io.busystack.busymark/visualization',
    ),
    this.renderTimeout = const Duration(seconds: 20),
    this.rasterTimeout = const Duration(seconds: 20),
    this.mathTimeout = const Duration(seconds: 10),
  }) : _channel = channel;

  final MethodChannel _channel;
  final Duration renderTimeout;
  final Duration rasterTimeout;
  final Duration mathTimeout;

  @override
  Future<Map<Object?, Object?>> renderMathBatch({
    required List<Map<String, Object?>> expressions,
    required VisualizationCancellationToken cancellationToken,
  }) {
    return _invokeMap(
      'renderMathBatch',
      {'expressions': expressions},
      mathTimeout,
      cancellationToken,
    );
  }

  /// Release verification hook. The Linux runner accepts this operation only
  /// when `BUSYMARK_RELEASE_SMOKE=1` is present in its environment.
  Future<void> terminateWebProcessForReleaseSmoke() async {
    await _channel
        .invokeMethod<void>('terminateWebProcessForReleaseSmoke')
        .timeout(renderTimeout);
  }

  @override
  Future<Map<Object?, Object?>> renderMermaid({
    required String source,
    required VisualizationTheme theme,
    required VisualizationCancellationToken cancellationToken,
  }) {
    return _invokeMap(
      'renderMermaid',
      {'source': source, 'theme': theme.name},
      renderTimeout,
      cancellationToken,
    );
  }

  @override
  Future<Map<Object?, Object?>> renderPlantUml({
    required String source,
    required VisualizationTheme theme,
    required VisualizationCancellationToken cancellationToken,
  }) {
    return _invokeMap(
      'renderPlantUml',
      {'source': source, 'theme': theme.name},
      renderTimeout,
      cancellationToken,
    );
  }

  @override
  Future<List<OpenApiSourceReference>> inspectOpenApiReferences(
    String source,
    VisualizationCancellationToken cancellationToken,
  ) async {
    final response = await _invokeMap(
      'inspectOpenApi',
      {'source': source},
      renderTimeout,
      cancellationToken,
    );
    return List.unmodifiable(
      (response['references'] as List<Object?>? ?? const [])
          .whereType<Map<Object?, Object?>>()
          .map(OpenApiSourceReference.fromJson)
          .where((reference) => reference.value.isNotEmpty),
    );
  }

  @override
  Future<Map<Object?, Object?>> parseOpenApi({
    required String entryId,
    required String source,
    required List<VisualizationDependency> dependencies,
    required VisualizationCancellationToken cancellationToken,
  }) {
    return _invokeMap(
      'parseOpenApi',
      {
        'entryId': entryId,
        'source': source,
        'dependencies': [
          for (final dependency in dependencies)
            {'id': dependency.id, 'source': dependency.source},
        ],
      },
      renderTimeout,
      cancellationToken,
    );
  }

  @override
  Future<Uint8List> rasterizeSvg({
    required String svg,
    required double width,
    required double height,
    required double scale,
    required VisualizationCancellationToken cancellationToken,
  }) async {
    final requestId = _requestId();
    final arguments = {
      'requestId': requestId,
      'svg': svg,
      'width': width,
      'height': height,
      'scale': scale,
    };
    final result = await _invokeCancellable(
      requestId: requestId,
      cancellationToken: cancellationToken,
      timeout: rasterTimeout,
      operation: () =>
          _channel.invokeMethod<Object?>('rasterizeSvg', arguments),
    );
    if (result is Uint8List) {
      return result;
    }
    if (result is List<int>) {
      return Uint8List.fromList(result);
    }
    throw const WebRenderHostException(
      'visualization.invalidHostResponse',
      'The WebKit host returned invalid raster data.',
    );
  }

  @override
  Future<void> copyPngToClipboard(Uint8List pngBytes) {
    return _channel.invokeMethod<void>('copyVisualizationImage', {
      'png': pngBytes,
    });
  }

  @override
  Future<void> openOpenApiReference({
    required String title,
    required String entryId,
    required String source,
    required List<VisualizationDependency> dependencies,
    required VisualizationTheme theme,
  }) async {
    await _channel.invokeMethod<void>('openOpenApiReference', {
      'title': title,
      'entryId': entryId,
      'source': source,
      'theme': theme.name,
      'dependencies': [
        for (final dependency in dependencies)
          {'id': dependency.id, 'source': dependency.source},
      ],
    });
  }

  Future<Map<Object?, Object?>> _invokeMap(
    String method,
    Map<String, Object?> arguments,
    Duration timeout,
    VisualizationCancellationToken cancellationToken,
  ) async {
    final requestId = _requestId();
    final result = await _invokeCancellable(
      requestId: requestId,
      cancellationToken: cancellationToken,
      timeout: timeout,
      operation: () => _channel.invokeMethod<Object?>(method, {
        ...arguments,
        'requestId': requestId,
      }),
    );
    if (result is Map<Object?, Object?>) {
      return result;
    }
    throw const WebRenderHostException(
      'visualization.invalidHostResponse',
      'The WebKit host returned an invalid response.',
    );
  }

  String _requestId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${_nextWebRenderRequestId++}';

  Future<T?> _invokeCancellable<T>({
    required String requestId,
    required VisualizationCancellationToken cancellationToken,
    required Duration timeout,
    required Future<T?> Function() operation,
  }) async {
    cancellationToken.throwIfCancelled();
    void cancel() => _cancelBestEffort(requestId);
    cancellationToken.onCancel(cancel);
    try {
      final result = await operation().timeout(timeout);
      cancellationToken.throwIfCancelled();
      return result;
    } on TimeoutException {
      cancel();
      rethrow;
    } finally {
      cancellationToken.removeListener(cancel);
    }
  }

  void _cancelBestEffort(String requestId) {
    unawaited(
      _channel
          .invokeMethod<void>('cancelRender', {'requestId': requestId})
          .catchError((Object _) {}),
    );
  }
}

class WebRenderHostException implements Exception {
  const WebRenderHostException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => '$code: $message';
}
