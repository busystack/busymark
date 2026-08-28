import 'dart:async';

import 'package:busymark/src/math/math_coordinator.dart';
import 'package:busymark/src/math/math_models.dart';
import 'package:busymark/src/math/math_renderer.dart';
import 'package:busymark/src/math/math_svg_preprocessor.dart';
import 'package:busymark/src/visualization/generated_svg_normalizer.dart';
import 'package:busymark/src/visualization/visualization_renderer.dart';
import 'package:busymark/src/visualization/web_render_host.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

void main() {
  test(
    'renders multiple expressions in one batch and isolates failure',
    () async {
      final host = _MathHost();
      final renderer = MathRenderer(host: host);
      final requests = [
        _request('one', r'\mathbb{R}', blockKey: 'one'),
        _request('bad', r'\frac{', blockKey: 'bad'),
      ];

      final results = await renderer.renderBatch(
        requests,
        VisualizationCancellationToken(),
      );

      expect(host.calls, 1);
      expect(host.batches.single, hasLength(2));
      expect(results[0], isA<RenderedMathResult>());
      expect(results[0].expressionId, 'one');
      expect((results[0] as RenderedMathResult).depth, 2);
      expect(results[1], isA<FailedMathResult>());
      expect(
        (results[1] as FailedMathResult).kind,
        MathRenderErrorKind.invalidTex,
      );
    },
  );

  test(
    'coalesces a large page, caches successes, and rebases local IDs',
    () async {
      final host = _MathHost();
      final coordinator = MathCoordinator(renderer: MathRenderer(host: host));
      addTearDown(coordinator.dispose);
      final requests = [
        for (var index = 0; index < 100; index++)
          _request('expression-$index', 'x_$index', blockKey: 'block-$index'),
      ];

      final first = await coordinator.renderAll(requests);

      expect(host.calls, 1, reason: 'one page must use one WebKit batch');
      expect(first, everyElement(isA<RenderedMathResult>()));
      final firstSvg = (first.first as RenderedMathResult).svg;
      final cached = await coordinator.render(
        _request('cached-instance', 'x_0', blockKey: 'cached-block'),
      );
      expect(host.calls, 1);
      expect(cached, isA<RenderedMathResult>());
      expect((cached as RenderedMathResult).svg, isNot(firstSvg));
      expect(cached.svg, contains('cached-instance'));
    },
  );

  test('deduplicates identical formulas pending in the same batch', () async {
    final host = _MathHost();
    final coordinator = MathCoordinator(renderer: MathRenderer(host: host));
    addTearDown(coordinator.dispose);

    final results = await coordinator.renderAll([
      _request('first-instance', r'\mathbb{R}', blockKey: 'first-block'),
      _request('second-instance', r'\mathbb{R}', blockKey: 'second-block'),
    ]);

    expect(host.calls, 1);
    expect(host.batches.single, hasLength(1));
    final first = results[0] as RenderedMathResult;
    final second = results[1] as RenderedMathResult;
    expect(first.expressionId, 'first-instance');
    expect(second.expressionId, 'second-instance');
    expect(first.svg, isNot(second.svg));
    expect(first.svg, contains('first-instance'));
    expect(second.svg, contains('second-instance'));
  });

  test('discards an obsolete block revision', () async {
    final host = _MathHost(delay: const Duration(milliseconds: 20));
    final coordinator = MathCoordinator(renderer: MathRenderer(host: host));
    addTearDown(coordinator.dispose);

    final obsolete = coordinator.render(
      _request('old', 'x', blockKey: 'same', revision: 1),
    );
    final current = coordinator.render(
      _request('new', 'y', blockKey: 'same', revision: 2),
    );

    await expectLater(obsolete, throwsA(isA<MathSupersededException>()));
    expect(await current, isA<RenderedMathResult>());
    expect(host.batches.single, hasLength(1));
  });

  test('cancels WebKit work after a sole request is superseded', () async {
    final host = _MathHost(
      delay: const Duration(seconds: 1),
      waitForCancellation: true,
    );
    final coordinator = MathCoordinator(renderer: MathRenderer(host: host));
    addTearDown(coordinator.dispose);

    final obsolete = coordinator.render(
      _request('old', 'x', blockKey: 'same', revision: 1),
    );
    await Future<void>.delayed(Duration.zero);
    coordinator.cancel('same');

    await expectLater(obsolete, throwsA(isA<MathSupersededException>()));
    expect(host.sawCancellation, isTrue);
  });

  test('maps timeout and unavailable hosts to local math failures', () async {
    final timeout =
        await MathRenderer(
          host: _ThrowingMathHost(TimeoutException('slow')),
        ).renderBatch([
          _request('timeout', 'x', blockKey: 'timeout'),
        ], VisualizationCancellationToken());
    final unavailable =
        await MathRenderer(
          host: _ThrowingMathHost(StateError('restarting')),
        ).renderBatch([
          _request('unavailable', 'x', blockKey: 'unavailable'),
        ], VisualizationCancellationToken());

    expect(
      (timeout.single as FailedMathResult).kind,
      MathRenderErrorKind.timeout,
    );
    expect(
      (unavailable.single as FailedMathResult).kind,
      MathRenderErrorKind.rendererUnavailable,
    );
  });

  test('rejects oversized input before invoking WebKit', () async {
    final host = _MathHost();
    final renderer = MathRenderer(host: host);

    final result = await renderer.renderBatch([
      _request(
        'large',
        'x' * (busyMarkMaximumMathExpressionCharacters + 1),
        blockKey: 'large',
      ),
    ], VisualizationCancellationToken());

    expect(host.calls, 0);
    expect(
      (result.single as FailedMathResult).kind,
      MathRenderErrorKind.resourceLimit,
    );
  });

  test('extracts baseline style and preserves vector-safe MathJax SVG', () {
    const source = '''
<svg xmlns="http://www.w3.org/2000/svg" width="2ex" height="1.5ex"
  viewBox="0 -1000 2000 1500" style="vertical-align: -0.25ex">
  <defs><path id="MJX-NCM-I-1D465" d="M0 0L20 20"/></defs>
  <use href="#MJX-NCM-I-1D465" fill="currentColor"/>
</svg>
''';
    const preprocessor = MathSvgPreprocessor();

    final prepared = preprocessor.preprocess(source, ex: 8);
    final rebased = preprocessor.rebaseLocalIds(prepared.svg, 'formula-two');

    expect(prepared.depth, 2);
    expect(prepared.svg, isNot(contains('vertical-align')));
    expect(prepared.svg, contains('<defs>'));
    expect(rebased, contains('id="formula-two-0"'));
    expect(rebased, contains('href="#formula-two-0"'));
    expect(rebased, contains('currentColor'));
  });

  test('resolves currentColor without flattening explicit SVG colors', () {
    const source = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 10">
  <path d="M0 0L10 10" fill="currentColor" stroke="#ff0000"/>
  <path d="M10 0L20 10" style="fill:CURRENTCOLOR;stroke:#00ff00"/>
</svg>
''';
    const preprocessor = MathSvgPreprocessor();

    final resolved = preprocessor.resolveCurrentColor(source, '#123456');

    expect(resolved, isNot(contains('currentColor')));
    expect(resolved, isNot(contains('CURRENTCOLOR')));
    expect(resolved, contains('fill="#123456"'));
    expect(resolved, contains('stroke="#ff0000"'));
    expect(resolved, contains('stroke:#00ff00'));
    expect(
      const GeneratedSvgNormalizer().normalize(resolved).vectorSafeSvg,
      isNotNull,
    );
  });

  test('rebases wide MathJax coordinates before secure normalization', () {
    const source = '''
<svg xmlns="http://www.w3.org/2000/svg" width="48ex" height="2.5ex"
  viewBox="0 -750 24000 1250" style="vertical-align: -0.25ex">
  <defs><path id="wide-glyph" d="M0 0L24000 1000"/></defs>
  <use href="#wide-glyph" fill="currentColor"/>
</svg>
''';
    const preprocessor = MathSvgPreprocessor();

    final prepared = preprocessor.preprocess(source, ex: 8);
    final document = XmlDocument.parse(prepared.svg);
    final viewBox = document.rootElement
        .getAttribute('viewBox')!
        .split(' ')
        .map(double.parse)
        .toList();

    expect(viewBox[2], 16000);
    expect(prepared.svg, contains('transform="scale('));
    expect(
      const GeneratedSvgNormalizer().normalize(prepared.svg).vectorSafeSvg,
      isNotNull,
    );
  });
}

MathRenderRequest _request(
  String id,
  String expression, {
  required String blockKey,
  int revision = 1,
}) {
  return MathRenderRequest(
    expressionId: id,
    expression: expression,
    display: false,
    blockKey: blockKey,
    editRevision: revision,
    em: 16,
    ex: 8,
    containerWidth: 800,
  );
}

class _MathHost implements WebRenderHost {
  _MathHost({this.delay = Duration.zero, this.waitForCancellation = false});

  final Duration delay;
  final bool waitForCancellation;
  int calls = 0;
  final List<List<Map<String, Object?>>> batches = [];
  bool sawCancellation = false;

  @override
  Future<Map<Object?, Object?>> renderMathBatch({
    required List<Map<String, Object?>> expressions,
    required VisualizationCancellationToken cancellationToken,
  }) async {
    calls++;
    batches.add(expressions);
    if (waitForCancellation) {
      while (!cancellationToken.isCancelled) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      sawCancellation = true;
    } else if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    cancellationToken.throwIfCancelled();
    return {
      'results': [
        for (final item in expressions)
          if ((item['expression'] as String).contains(r'\frac{'))
            {
              'id': item['id'],
              'error': {
                'code': 'math.invalidTex',
                'message': 'The expression contains invalid TeX.',
              },
            }
          else
            {
              'id': item['id'],
              'svg': _svg(item['svgIdPrefix'] as String),
              'width': 16,
              'height': 12,
              'depth': 2,
            },
      ],
    };
  }

  String _svg(String prefix) =>
      '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 -10 16 12"
 style="vertical-align:-0.25ex">
 <defs><path id="$prefix-path" d="M0 0L10 10"/></defs>
 <use href="#$prefix-path" fill="currentColor"/>
</svg>''';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ThrowingMathHost implements WebRenderHost {
  const _ThrowingMathHost(this.error);

  final Object error;

  @override
  Future<Map<Object?, Object?>> renderMathBatch({
    required List<Map<String, Object?>> expressions,
    required VisualizationCancellationToken cancellationToken,
  }) {
    return Future.error(error);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
