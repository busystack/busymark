import 'package:busymark/src/visualization/generated_svg_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const normalizer = GeneratedSvgNormalizer();

  test('inlines safe generated CSS into a vector-only SVG', () {
    final result = normalizer.normalize('''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 50">
  <style>.node { fill: #fff; stroke: #123456; stroke-width: 2px; }</style>
  <rect class="node" width="100" height="50" />
</svg>
''');

    expect(result.hasForeignObject, isFalse);
    expect(result.width, 100);
    expect(result.height, 50);
    expect(result.vectorSafeSvg, isNot(contains('<style')));
    expect(result.vectorSafeSvg, contains('fill="#fff"'));
    expect(result.vectorSafeSvg, contains('stroke="#123456"'));
  });

  test('keeps sanitized foreignObject only in the browser raster input', () {
    final result = normalizer.normalize('''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 50">
  <foreignObject width="100" height="50">
    <div xmlns="http://www.w3.org/1999/xhtml" onclick="alert(1)">
      <script>alert(1)</script><a href="https://example.com">Text</a>
    </div>
  </foreignObject>
</svg>
''');

    expect(result.hasForeignObject, isTrue);
    expect(result.vectorSafeSvg, isNull);
    expect(result.browserSafeSvg, contains('foreignObject'));
    expect(result.browserSafeSvg, isNot(contains('<script')));
    expect(result.browserSafeSvg, isNot(contains('onclick')));
    expect(result.browserSafeSvg, isNot(contains('https://example.com')));
  });

  test('removes SVG and CSS animations', () {
    final result = normalizer.normalize('''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 10">
  <style>
    @keyframes pulse { from { opacity: 0; } to { opacity: 1; } }
    rect { animation: pulse 1s infinite; transition: opacity 1s; fill: red; }
  </style>
  <rect width="10" height="10"><animate attributeName="x" /></rect>
</svg>
''');

    expect(result.browserSafeSvg.toLowerCase(), isNot(contains('@keyframes')));
    expect(result.browserSafeSvg.toLowerCase(), isNot(contains('animation:')));
    expect(result.browserSafeSvg.toLowerCase(), isNot(contains('transition:')));
    expect(result.browserSafeSvg.toLowerCase(), isNot(contains('<animate')));
    expect(result.vectorSafeSvg, contains('fill="#f00"'));
  });

  test('rejects remote, executable, and escaped CSS URLs', () {
    for (final css in [
      '.node { fill: url(https://example.com/a.svg); }',
      '.node { fill: url(javascript:alert(1)); }',
      r'.node { fill: u\72l(https://example.com/a.svg); }',
      '@import "https://example.com/a.css";',
    ]) {
      expect(
        () => normalizer.normalize('''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 10">
  <style>$css</style><rect class="node" width="10" height="10" />
</svg>
'''),
        throwsA(isA<GeneratedSvgException>()),
        reason: css,
      );
    }
  });

  test(
    'allows embedded D2-style fonts but rejects remote image attributes',
    () {
      final result = normalizer.normalize('''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 10">
  <style>
    @font-face { font-family: local; src: url(data:font/woff2;base64,AAAA); }
    text { font-family: local; }
  </style>
  <image href="https://example.com/tracker.png" />
  <text>Safe</text>
</svg>
''');

      expect(result.browserSafeSvg, contains('data:font/woff2;base64,AAAA'));
      expect(result.browserSafeSvg, isNot(contains('tracker.png')));
      expect(
        result.vectorSafeSvg,
        isNull,
        reason: 'Embedded fonts must be rendered by the browser, not dropped.',
      );
    },
  );

  test('requires rasterization for CSS the vector inliner cannot preserve', () {
    for (final style in [
      '.group > .node { fill: red; }',
      '[data-kind="node"] { fill: red; }',
      '.node:first-child { fill: red; }',
      '.node { transform: translate(1px); }',
      '@media screen { .node { fill: red; } }',
    ]) {
      final result = normalizer.normalize('''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 10">
  <style>$style</style>
  <g class="group"><rect class="node" data-kind="node" width="10" height="10" /></g>
</svg>
''');

      expect(result.browserSafeSvg, contains('<style'), reason: style);
      expect(result.vectorSafeSvg, isNull, reason: style);
    }
  });

  test('preserves safe browser-only inline CSS and rasterizes it', () {
    final result = normalizer.normalize('''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 10">
  <rect width="10" height="10"
    style="transform:translate(1px);background-color:#fff;fill:red" />
</svg>
''');

    expect(result.browserSafeSvg, contains('transform:translate(1px)'));
    expect(result.browserSafeSvg, contains('background-color:#fff'));
    expect(result.browserSafeSvg, contains('fill:#f00'));
    expect(result.vectorSafeSvg, isNull);
  });

  test('removes unsafe URLs from inline CSS', () {
    final result = normalizer.normalize('''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 10">
  <rect width="10" height="10"
    style="fill:red;filter:url(https://example.com/filter.svg)" />
</svg>
''');

    expect(result.browserSafeSvg, contains('fill:#f00'));
    expect(result.browserSafeSvg, isNot(contains('example.com')));
    expect(result.vectorSafeSvg, isNotNull);
  });

  test(
    'does not claim a vector result when CSS cascade resolution is needed',
    () {
      final result = normalizer.normalize('''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 10">
  <style>.node { fill: red; } .selected { fill: blue; }</style>
  <rect class="node selected" width="10" height="10" />
</svg>
''');

      expect(result.vectorSafeSvg, isNull);
      expect(result.browserSafeSvg, contains('.selected'));
    },
  );

  test(
    'rejects declarations, excessive complexity, and invalid dimensions',
    () {
      expect(
        () => normalizer.normalize(
          '<!DOCTYPE svg><svg xmlns="http://www.w3.org/2000/svg"/>',
        ),
        throwsA(isA<GeneratedSvgException>()),
      );
      expect(
        () => const GeneratedSvgNormalizer(
          maximumElements: 1,
        ).normalize('<svg xmlns="http://www.w3.org/2000/svg"><g/></svg>'),
        throwsA(isA<GeneratedSvgException>()),
      );
      expect(
        () => normalizer.normalize(
          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 0 10"/>',
        ),
        throwsA(isA<GeneratedSvgException>()),
      );
    },
  );

  test('applies the size limit to UTF-8 bytes', () {
    expect(
      () => const GeneratedSvgNormalizer(maximumBytes: 65).normalize(
        '<svg xmlns="http://www.w3.org/2000/svg"><text>éééé</text></svg>',
      ),
      throwsA(isA<GeneratedSvgException>()),
    );
  });
}
