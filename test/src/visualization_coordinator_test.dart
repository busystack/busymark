import 'dart:async';
import 'dart:io';

import 'package:busymark/src/visualization/visualization_cache.dart';
import 'package:busymark/src/visualization/visualization_coordinator.dart';
import 'package:busymark/src/visualization/visualization_models.dart';
import 'package:busymark/src/visualization/visualization_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory cacheDirectory;

  setUp(() async {
    cacheDirectory = await Directory.systemTemp.createTemp(
      'busymark-viz-coordinator-',
    );
  });

  tearDown(() async {
    if (await cacheDirectory.exists()) {
      await cacheDirectory.delete(recursive: true);
    }
  });

  test(
    'rejects a superseded render even when its engine finishes last',
    () async {
      final renderer = _ControlledRenderer();
      final coordinator = _coordinator(renderer, cacheDirectory);
      addTearDown(coordinator.dispose);

      final oldFuture = coordinator.render(_request(revision: 1));
      await renderer.waitForStarts(1);
      final newFuture = coordinator.render(_request(revision: 2));
      await renderer.waitForStarts(2);

      renderer.complete(2, _svg('new'));
      expect((await newFuture as SvgVisualizationResult).svg, contains('new'));
      renderer.complete(1, _svg('old'));
      await expectLater(
        oldFuture,
        throwsA(isA<VisualizationSupersededException>()),
      );
      expect(
        (coordinator.lastSuccessfulFor('block') as SvgVisualizationResult).svg,
        contains('new'),
      );
    },
  );

  test('retains the last successful render after invalid source', () async {
    final renderer = _ControlledRenderer();
    final coordinator = _coordinator(renderer, cacheDirectory);
    addTearDown(coordinator.dispose);

    final validFuture = coordinator.render(_request(revision: 1));
    await renderer.waitForStarts(1);
    renderer.complete(1, _svg('valid'));
    await validFuture;

    final invalidFuture = coordinator.render(
      _request(revision: 2, source: 'invalid source'),
    );
    await renderer.waitForStarts(2);
    renderer.complete(
      2,
      const FailedVisualizationResult(
        code: 'visualization.invalidSource',
        message: 'invalid',
      ),
    );

    expect(await invalidFuture, isA<FailedVisualizationResult>());
    expect(
      (coordinator.lastSuccessfulFor('block') as SvgVisualizationResult).svg,
      contains('valid'),
    );
  });

  test('limits concurrency and gives export work queue priority', () async {
    final renderer = _ControlledRenderer();
    final coordinator = _coordinator(
      renderer,
      cacheDirectory,
      maximumConcurrentRenders: 1,
    );
    addTearDown(coordinator.dispose);

    final active = coordinator.render(
      _request(blockKey: 'active', revision: 1),
    );
    await renderer.waitForStarts(1);
    final background = coordinator.render(
      _request(
        blockKey: 'background',
        revision: 1,
        priority: VisualizationRenderPriority.background,
      ),
    );
    final visible = coordinator.render(
      _request(
        blockKey: 'visible',
        revision: 1,
        priority: VisualizationRenderPriority.visible,
      ),
    );
    final export = coordinator.render(
      _request(
        blockKey: 'export',
        revision: 1,
        priority: VisualizationRenderPriority.export,
      ),
    );

    renderer.complete(1, _svg('active'));
    await active;
    await renderer.waitForStarts(2);
    expect(renderer.startedBlockKeys[1], 'export');
    renderer.completeByBlock('export', _svg('export'));
    await export;
    await renderer.waitForStarts(3);
    expect(renderer.startedBlockKeys[2], 'visible');
    renderer.completeByBlock('visible', _svg('visible'));
    await visible;
    await renderer.waitForStarts(4);
    expect(renderer.startedBlockKeys[3], 'background');
    renderer.completeByBlock('background', _svg('background'));
    await background;
  });

  test('reuses a successful content-addressed cache entry', () async {
    final renderer = _ControlledRenderer();
    final coordinator = _coordinator(renderer, cacheDirectory);
    addTearDown(coordinator.dispose);

    final first = coordinator.render(_request(revision: 1));
    await renderer.waitForStarts(1);
    renderer.complete(1, _svg('cached'));
    await first;
    expect(
      await coordinator.render(_request(revision: 2)),
      isA<SvgVisualizationResult>(),
    );
    expect(renderer.startedBlockKeys, hasLength(1));
  });

  test(
    'validates concurrency and returns a typed unavailable result',
    () async {
      expect(
        () => VisualizationCoordinator(
          renderers: const [],
          maximumConcurrentRenders: 0,
        ),
        throwsArgumentError,
      );
      final coordinator = VisualizationCoordinator(
        renderers: const [],
        cache: VisualizationCache(diskRoot: cacheDirectory),
      );
      addTearDown(coordinator.dispose);

      final result = await coordinator.render(_request(revision: 1));
      expect(result, isA<FailedVisualizationResult>());
      expect((result as FailedVisualizationResult).retryable, isFalse);
    },
  );
}

VisualizationCoordinator _coordinator(
  VisualizationRenderer renderer,
  Directory cacheDirectory, {
  int maximumConcurrentRenders = 2,
}) {
  return VisualizationCoordinator(
    renderers: [renderer],
    maximumConcurrentRenders: maximumConcurrentRenders,
    cache: VisualizationCache(diskRoot: cacheDirectory),
  );
}

VisualizationRenderRequest _request({
  String blockKey = 'block',
  String source = 'graph TD; A-->B',
  required int revision,
  VisualizationRenderPriority priority = VisualizationRenderPriority.visible,
}) {
  return VisualizationRenderRequest(
    blockKey: blockKey,
    kind: VisualizationRendererKind.mermaid,
    source: source,
    sourceStartLine: 1,
    documentPath: '/workspace/guide.md',
    workspaceRoot: '/workspace',
    theme: VisualizationTheme.light,
    profile: VisualizationRenderProfile.preview,
    engineVersion: mermaidEngineVersion,
    editRevision: revision,
    priority: priority,
  );
}

SvgVisualizationResult _svg(String label) => SvgVisualizationResult(
  svg: '<svg viewBox="0 0 10 10"><text>$label</text></svg>',
  width: 10,
  height: 10,
);

class _ControlledRenderer implements VisualizationRenderer {
  final _started = StreamController<void>.broadcast();
  final Map<int, Completer<VisualizationRenderResult>> _byRevision = {};
  final Map<String, Completer<VisualizationRenderResult>> _byBlock = {};
  final List<String> startedBlockKeys = [];

  @override
  Set<VisualizationRendererKind> get supportedKinds => const {
    VisualizationRendererKind.mermaid,
  };

  @override
  Future<VisualizationRenderRequest> prepare(
    VisualizationRenderRequest request,
    VisualizationCancellationToken cancellationToken,
  ) async {
    cancellationToken.throwIfCancelled();
    return request;
  }

  @override
  Future<VisualizationRenderResult> render(
    VisualizationRenderRequest request,
    VisualizationCancellationToken cancellationToken,
  ) {
    final completer = Completer<VisualizationRenderResult>();
    _byRevision[request.editRevision] = completer;
    _byBlock[request.blockKey] = completer;
    startedBlockKeys.add(request.blockKey);
    _started.add(null);
    return completer.future;
  }

  Future<void> waitForStarts(int count) async {
    while (startedBlockKeys.length < count) {
      await _started.stream.first;
    }
  }

  void complete(int revision, VisualizationRenderResult result) {
    _byRevision[revision]!.complete(result);
  }

  void completeByBlock(String blockKey, VisualizationRenderResult result) {
    _byBlock[blockKey]!.complete(result);
  }
}
