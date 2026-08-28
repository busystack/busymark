import 'dart:math' as math;
import 'dart:typed_data';

import 'package:busymark/src/visualization/d2_renderer.dart';
import 'package:busymark/src/visualization/visualization_models.dart';
import 'package:busymark/src/visualization/visualization_renderer.dart';
import 'package:busymark/src/visualization/web_render_host.dart';
import 'package:busymark/src/visualization/web_visualization_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cases = <_RasterCase>[
    _RasterCase(
      name: 'wide preview',
      profile: VisualizationRenderProfile.preview,
      logicalWidth: 5000,
      logicalHeight: 1000,
      pixelWidth: 8192,
      pixelHeight: 1639,
    ),
    _RasterCase(
      name: 'wide PDF',
      profile: VisualizationRenderProfile.pdf,
      logicalWidth: 3000,
      logicalHeight: 1000,
      pixelWidth: 8192,
      pixelHeight: 2731,
    ),
    _RasterCase(
      name: 'area-constrained PDF',
      profile: VisualizationRenderProfile.pdf,
      logicalWidth: 3000,
      logicalHeight: 3000,
      pixelWidth: 8000,
      pixelHeight: 8000,
    ),
  ];

  for (final rasterCase in cases) {
    test(
      '${rasterCase.name} fits identically through D2 and WebKit renderers',
      () async {
        final svg = rasterCase.svg;
        final d2Host = _LimitEnforcingRasterHost(svg);
        final d2Renderer = D2VisualizationRenderer(
          webRenderHost: d2Host,
          locator: const D2ExecutableLocator(
            environment: {'BUSYMARK_D2_PATH': '/bin/true'},
          ),
          commandRunner: _SvgD2Runner(svg),
        );
        final d2Result = await d2Renderer.render(
          _request(VisualizationRendererKind.d2, rasterCase.profile),
          VisualizationCancellationToken(),
        );

        final webHost = _LimitEnforcingRasterHost(svg);
        final webRenderer = WebVisualizationRenderer(host: webHost);
        final webResult = await webRenderer.render(
          _request(VisualizationRendererKind.mermaid, rasterCase.profile),
          VisualizationCancellationToken(),
        );

        for (final result in [d2Result, webResult]) {
          expect(result, isA<RasterVisualizationResult>());
          final raster = result as RasterVisualizationResult;
          expect(raster.width, rasterCase.pixelWidth);
          expect(raster.height, rasterCase.pixelHeight);
          expect(raster.width, lessThanOrEqualTo(8192));
          expect(raster.height, lessThanOrEqualTo(8192));
          expect(raster.width * raster.height, lessThanOrEqualTo(64000000));
        }
        final d2Raster = d2Result as RasterVisualizationResult;
        final webRaster = webResult as RasterVisualizationResult;
        expect(d2Raster.width, d2Host.pixelWidth);
        expect(d2Raster.height, d2Host.pixelHeight);
        expect(webRaster.width, webHost.pixelWidth);
        expect(webRaster.height, webHost.pixelHeight);
        expect(d2Host.lastScale, closeTo(webHost.lastScale!, 1e-12));
      },
    );
  }
}

VisualizationRenderRequest _request(
  VisualizationRendererKind kind,
  VisualizationRenderProfile profile,
) {
  return VisualizationRenderRequest(
    blockKey: kind.name,
    kind: kind,
    source: 'diagram source',
    sourceStartLine: 1,
    documentPath: '/workspace/guide.md',
    workspaceRoot: '/workspace',
    theme: VisualizationTheme.light,
    profile: profile,
    engineVersion: kind.engineVersion,
    editRevision: 1,
  );
}

class _RasterCase {
  const _RasterCase({
    required this.name,
    required this.profile,
    required this.logicalWidth,
    required this.logicalHeight,
    required this.pixelWidth,
    required this.pixelHeight,
  });

  final String name;
  final VisualizationRenderProfile profile;
  final int logicalWidth;
  final int logicalHeight;
  final int pixelWidth;
  final int pixelHeight;

  String get svg =>
      '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $logicalWidth $logicalHeight">
  <foreignObject width="$logicalWidth" height="$logicalHeight"><div xmlns="http://www.w3.org/1999/xhtml">Text</div></foreignObject>
</svg>
''';
}

class _SvgD2Runner implements D2CommandRunner {
  const _SvgD2Runner(this.svg);

  final String svg;

  @override
  Future<D2ProcessResult> render({
    required String executable,
    required String source,
    required VisualizationTheme theme,
    required VisualizationCancellationToken cancellationToken,
  }) async {
    cancellationToken.throwIfCancelled();
    return D2ProcessResult(
      exitCode: 0,
      stdout: Uint8List.fromList(svg.codeUnits),
      stderr: '',
    );
  }
}

class _LimitEnforcingRasterHost implements WebRenderHost {
  _LimitEnforcingRasterHost(this.svg);

  final String svg;
  double? lastScale;
  int? pixelWidth;
  int? pixelHeight;

  @override
  Future<Map<Object?, Object?>> renderMathBatch({
    required List<Map<String, Object?>> expressions,
    required VisualizationCancellationToken cancellationToken,
  }) => throw UnimplementedError();

  @override
  Future<Uint8List> rasterizeSvg({
    required String svg,
    required double width,
    required double height,
    required double scale,
    required VisualizationCancellationToken cancellationToken,
  }) async {
    cancellationToken.throwIfCancelled();
    final actualWidth = math.max(1, (width * scale).ceil());
    final actualHeight = math.max(1, (height * scale).ceil());
    if (actualWidth > 8192 ||
        actualHeight > 8192 ||
        actualWidth * actualHeight > 64000000) {
      throw StateError('Raster dimensions exceed the production host limit.');
    }
    lastScale = scale;
    pixelWidth = actualWidth;
    pixelHeight = actualHeight;
    return Uint8List.fromList([137, 80, 78, 71]);
  }

  @override
  Future<Map<Object?, Object?>> renderMermaid({
    required String source,
    required VisualizationTheme theme,
    required VisualizationCancellationToken cancellationToken,
  }) async {
    cancellationToken.throwIfCancelled();
    return {'svg': svg, 'diagnostics': const []};
  }

  @override
  Future<Map<Object?, Object?>> renderPlantUml({
    required String source,
    required VisualizationTheme theme,
    required VisualizationCancellationToken cancellationToken,
  }) => renderMermaid(
    source: source,
    theme: theme,
    cancellationToken: cancellationToken,
  );

  @override
  Future<void> copyPngToClipboard(Uint8List pngBytes) async {}

  @override
  Future<List<OpenApiSourceReference>> inspectOpenApiReferences(
    String source,
    VisualizationCancellationToken cancellationToken,
  ) => throw UnimplementedError();

  @override
  Future<void> openOpenApiReference({
    required String title,
    required String entryId,
    required String source,
    required List<VisualizationDependency> dependencies,
    required VisualizationTheme theme,
  }) => throw UnimplementedError();

  @override
  Future<Map<Object?, Object?>> parseOpenApi({
    required String entryId,
    required String source,
    required List<VisualizationDependency> dependencies,
    required VisualizationCancellationToken cancellationToken,
  }) => throw UnimplementedError();
}
