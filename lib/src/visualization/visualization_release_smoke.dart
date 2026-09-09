import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:path/path.dart' as p;

import '../export/markdown_pdf_export_service.dart';
import '../export/html_release_smoke.dart';
import '../export/markdown_pdf_models.dart';
import '../export/markdown_math_export.dart';
import '../export/markdown_visualization_export.dart';
import '../math/math_coordinator.dart';
import '../math/math_models.dart';
import '../math/math_renderer.dart';
import 'd2_renderer.dart';
import 'visualization_cache.dart';
import 'visualization_coordinator.dart';
import 'visualization_models.dart';
import 'visualization_renderer.dart';
import 'web_render_host.dart';
import 'web_visualization_renderer.dart';

const visualizationReleaseSmokeArgument = '--visualization-release-smoke=';

String? visualizationReleaseSmokeReportPath(
  Iterable<String> arguments, {
  Map<String, String>? environment,
}) {
  if ((environment ?? Platform.environment)['BUSYMARK_RELEASE_SMOKE'] != '1') {
    return null;
  }
  for (final argument in arguments) {
    if (argument.startsWith(visualizationReleaseSmokeArgument)) {
      final path = argument.substring(visualizationReleaseSmokeArgument.length);
      return path.trim().isEmpty ? null : path;
    }
  }
  return null;
}

Future<int> runVisualizationReleaseSmoke(String reportPath) async {
  final reportFile = File(p.normalize(p.absolute(reportPath)));
  await reportFile.parent.create(recursive: true);
  final workingDirectory = await Directory.systemTemp.createTemp(
    'busymark-visualization-release-smoke-',
  );
  final host = const PlatformWebRenderHost(
    renderTimeout: Duration(seconds: 45),
    rasterTimeout: Duration(seconds: 45),
  );
  final coordinator = VisualizationCoordinator(
    renderers: [
      WebVisualizationRenderer(host: host),
      D2VisualizationRenderer(webRenderHost: host),
    ],
    cache: VisualizationCache(
      diskRoot: Directory(p.join(workingDirectory.path, 'cache')),
    ),
    maximumConcurrentRenders: 1,
  );
  final mathCoordinator = MathCoordinator(renderer: MathRenderer(host: host));
  final checks = <String, Object?>{};
  Future<void> checkpoint(String phase) async {
    await _writeReport(reportFile, {
      'ok': null,
      'phase': phase,
      'checks': checks,
    });
  }

  try {
    await checkpoint('rendering Mermaid');
    final rawMermaid = await host.renderMermaid(
      source: 'flowchart LR\n  source[Markdown] --> preview[Preview]',
      theme: VisualizationTheme.light,
      cancellationToken: VisualizationCancellationToken(),
    );
    final rawMermaidSvg = rawMermaid['svg'];
    if (rawMermaidSvg is! String || !rawMermaidSvg.contains('<svg')) {
      throw StateError('Mermaid browser engine did not return SVG.');
    }
    await File(
      p.join(reportFile.parent.path, 'visualization-smoke-mermaid.svg'),
    ).writeAsString(rawMermaidSvg, flush: true);
    final mermaid = await _render(
      coordinator,
      workingDirectory,
      blockKey: 'release-smoke-mermaid',
      kind: VisualizationRendererKind.mermaid,
      source: 'flowchart LR\n  source[Markdown] --> preview[Preview]',
    );
    checks['mermaidFormat'] = await _expectDiagram(host, mermaid, 'Mermaid');

    await checkpoint('rendering sequential NewCM math');
    final doubleStruck = await _renderMath(
      mathCoordinator,
      expression: r'\mathbb{R}',
      key: 'release-smoke-mathbb',
    );
    final calligraphic = await _renderMath(
      mathCoordinator,
      expression: r'\mathcal{L}',
      key: 'release-smoke-mathcal',
    );
    final scientific = await _renderMath(
      mathCoordinator,
      expression:
          r'\ce{2H2 + O2 -> 2H2O}\quad '
          r'\Braket{\psi|\phi}+\cancel{x}+\upalpha+a\coloneqq b+\units{m}',
      key: 'release-smoke-scientific',
      display: true,
    );
    final bold = await _renderMath(
      mathCoordinator,
      expression: r'\boldsymbol{\alpha}',
      key: 'release-smoke-boldsymbol',
    );
    final cases = await _renderMath(
      mathCoordinator,
      expression: r'f(x)=\begin{cases}x&x>0\\0&x\leq0\end{cases}',
      key: 'release-smoke-cases',
      display: true,
    );
    final generatedSymbol = await _renderMath(
      mathCoordinator,
      expression: r'90\degree',
      key: 'release-smoke-gensymb',
    );
    final emphasizedEquation = await _renderMath(
      mathCoordinator,
      expression: r'\begin{empheq}{align}E&=mc^2\end{empheq}',
      key: 'release-smoke-empheq',
      display: true,
    );
    final ams = await _renderMath(
      mathCoordinator,
      expression: r'\begin{align}a&=b\end{align}',
      key: 'release-smoke-ams',
      display: true,
    );
    for (final entry in <String, MathRenderResult>{
      'double-struck': doubleStruck,
      'calligraphic': calligraphic,
      'scientific profile': scientific,
      'boldsymbol': bold,
      'cases': cases,
      'gensymb': generatedSymbol,
      'empheq': emphasizedEquation,
      'AMS': ams,
    }.entries) {
      final name = entry.key;
      final result = entry.value;
      if (result is! RenderedMathResult || !result.vectorSvg.contains('<svg')) {
        final detail = result is FailedMathResult
            ? '${result.code}: ${result.debugDetail ?? result.code}'
            : result.runtimeType.toString();
        throw StateError(
          'MathJax did not render the $name expression: $detail',
        );
      }
    }
    checks['mathJaxVersion'] = busyMarkMathJaxVersion;
    checks['mathJaxFontVersion'] = busyMarkMathJaxFontVersion;
    checks['newCmSequential'] = true;
    checks['mathVectorSvg'] = true;

    await checkpoint('checking independent formula state and partial failure');
    final macroDefinition = await _renderMath(
      mathCoordinator,
      expression: r'\newcommand{\busyisolated}{z}\busyisolated',
      key: 'release-smoke-macro-definition',
    );
    final leakedMacro = await _renderMath(
      mathCoordinator,
      expression: r'\busyisolated',
      key: 'release-smoke-macro-isolation',
    );
    final validAfterFailure = await _renderMath(
      mathCoordinator,
      expression: r'\sqrt{x^2+y^2}',
      key: 'release-smoke-after-failure',
    );
    if (macroDefinition is! RenderedMathResult ||
        leakedMacro is! FailedMathResult ||
        leakedMacro.kind != MathRenderErrorKind.invalidTex ||
        validAfterFailure is! RenderedMathResult) {
      throw StateError('Math expression isolation or partial failure failed.');
    }
    checks['mathExpressionIsolation'] = true;
    checks['mathPartialFailure'] = true;

    await checkpoint('terminating and recovering WebKit');
    await host.terminateWebProcessForReleaseSmoke();
    checks['webKitRecovery'] = true;

    final mathAfterRecovery = await _renderMath(
      mathCoordinator,
      expression: r'\mathbb{R}\oplus\mathcal{L}',
      key: 'release-smoke-math-recovery',
    );
    if (mathAfterRecovery is! RenderedMathResult) {
      throw StateError('MathJax did not recover with the WebKit process.');
    }
    checks['mathWebKitRecovery'] = true;

    await checkpoint('rendering PlantUML after recovery');
    final plantUml = await _render(
      coordinator,
      workingDirectory,
      blockKey: 'release-smoke-plantuml',
      kind: VisualizationRendererKind.plantUml,
      source: '@startuml\nAlice -> Bob: Offline\n@enduml',
    );
    checks['plantUmlFormat'] = await _expectDiagram(host, plantUml, 'PlantUML');

    await checkpoint('rasterizing D2 CSS');
    await _expectRaster(
      await _render(
        coordinator,
        workingDirectory,
        blockKey: 'release-smoke-d2-css',
        kind: VisualizationRendererKind.d2,
        source: 'source -> output',
      ),
      'D2 styled SVG',
    );
    checks['d2CssRaster'] = true;

    await checkpoint('rasterizing D2 foreignObject');
    await _expectRaster(
      await _render(
        coordinator,
        workingDirectory,
        blockKey: 'release-smoke-d2-foreign-object',
        kind: VisualizationRendererKind.d2,
        source: 'source: |md\n  **Offline** rendering\n|\nsource -> output',
      ),
      'D2 foreignObject SVG',
    );
    checks['d2ForeignObjectRaster'] = true;

    await checkpoint('parsing OpenAPI');
    final openApi = await _render(
      coordinator,
      workingDirectory,
      blockKey: 'release-smoke-openapi',
      kind: VisualizationRendererKind.openApi,
      source: _openApiSource,
    );
    if (openApi is! OpenApiVisualizationResult ||
        !openApi.reference.valid ||
        openApi.reference.operationCount != 1) {
      throw StateError('OpenAPI did not produce a valid reference model.');
    }
    checks['openApiReference'] = true;

    await checkpoint('exporting visualization PDF with Typst');
    final pdfPath = p.join(reportFile.parent.path, 'visualization-smoke.pdf');
    final export =
        await MarkdownPdfExportService(
          visualizationRenderer: MarkdownVisualizationExportRenderer(
            coordinator: coordinator,
          ),
          mathRenderer: MarkdownMathExportRenderer(
            coordinator: mathCoordinator,
          ),
        ).export(
          MarkdownPdfExportRequest(
            source: _pdfSource,
            filePath: p.join(workingDirectory.path, 'visualization-smoke.md'),
            workspaceRoot: workingDirectory.path,
            destinationPath: pdfPath,
            options: const PdfExportOptions(),
            overwrite: true,
          ),
        );
    final pdfBytes = await File(pdfPath).readAsBytes();
    final embeddedImages = RegExp(
      r'/Subtype\s*/Image',
    ).allMatches(latin1.decode(pdfBytes, allowInvalid: true)).length;
    if (export.warnings.isNotEmpty ||
        pdfBytes.length < 1000 ||
        ascii.decode(pdfBytes.take(5).toList()) != '%PDF-' ||
        embeddedImages < 2) {
      throw StateError(
        'Typst visualization export failed: ${export.warnings.map((warning) => warning.destination).join('; ')}',
      );
    }
    checks['typstPdf'] = true;
    checks['pdfEmbeddedImages'] = embeddedImages;
    checks['pdfPath'] = pdfPath;

    final customizedPdf =
        await MarkdownPdfExportService(
          visualizationRenderer: MarkdownVisualizationExportRenderer(
            coordinator: coordinator,
          ),
          mathRenderer: MarkdownMathExportRenderer(
            coordinator: mathCoordinator,
          ),
        ).export(
          MarkdownPdfExportRequest(
            source: _pdfSource,
            filePath: p.join(workingDirectory.path, 'visualization-smoke.md'),
            workspaceRoot: workingDirectory.path,
            destinationPath: p.join(reportFile.parent.path, 'customized.pdf'),
            overwrite: true,
            options: const PdfExportOptions(
              pageSize: PdfPageSize.custom,
              customWidthMm: 240,
              customHeightMm: 320,
              margin: PdfMarginPreset.custom,
              customMargins: PdfMargins(
                top: 18,
                right: 20,
                bottom: 25,
                left: 30,
              ),
              bodyTypography: ExportBodyTypography.sansSerif,
              bodyFontSize: 14,
              codeFontSize: 11,
              content: ExportContentOptions(
                includeToc: true,
                tocDepth: 3,
                numberHeadings: true,
              ),
              accentColor: '#7651a8',
              header: PdfRunningText.documentTitle,
              footer: PdfRunningText.documentTitle,
              pageNumbers: PdfPageNumberPosition.bottomRight,
              showHeaderFooterOnFirstPage: false,
            ),
          ),
        );
    if (customizedPdf.warnings.isNotEmpty) {
      throw StateError(
        'Customized PDF: ${customizedPdf.warnings.map((w) => w.destination).join('; ')}',
      );
    }
    checks['customPdfPath'] = customizedPdf.destinationPath;

    await checkpoint('exporting offline HTML documents');
    checks.addAll(
      await runHtmlReleaseSmoke(
        sourceRoot: workingDirectory,
        outputRoot: reportFile.parent,
        math: mathCoordinator,
        visualization: coordinator,
      ),
    );

    await _writeReport(reportFile, {'ok': true, 'checks': checks});
    return 0;
  } on Object catch (error, stackTrace) {
    await _writeReport(reportFile, {
      'ok': false,
      'checks': checks,
      'error': error.toString(),
      'stackTrace': stackTrace.toString(),
    });
    return 1;
  } finally {
    coordinator.dispose();
    mathCoordinator.dispose();
    try {
      await workingDirectory.delete(recursive: true);
    } on FileSystemException {
      // The report already records the product-path result.
    }
  }
}

Future<MathRenderResult> _renderMath(
  MathCoordinator coordinator, {
  required String expression,
  required String key,
  bool display = false,
}) {
  return coordinator.render(
    MathRenderRequest(
      expressionId: key,
      expression: expression,
      display: display,
      blockKey: key,
      editRevision: 1,
      em: 16,
      ex: 8,
      containerWidth: 720,
      renderProfile: 'release-smoke',
    ),
  );
}

Future<VisualizationRenderResult> _render(
  VisualizationCoordinator coordinator,
  Directory workingDirectory, {
  required String blockKey,
  required VisualizationRendererKind kind,
  required String source,
}) {
  return coordinator.render(
    VisualizationRenderRequest(
      blockKey: blockKey,
      kind: kind,
      source: source,
      sourceStartLine: 1,
      documentPath: p.join(workingDirectory.path, 'visualization-smoke.md'),
      workspaceRoot: workingDirectory.path,
      theme: VisualizationTheme.light,
      profile: VisualizationRenderProfile.preview,
      engineVersion: kind.engineVersion,
      editRevision: 1,
    ),
  );
}

Future<String> _expectDiagram(
  WebRenderHost host,
  VisualizationRenderResult result,
  String renderer,
) async {
  return switch (result) {
    SvgVisualizationResult(:final svg, :final width, :final height)
        when svg.isNotEmpty =>
      _validateSvg(
        host,
        svg: svg,
        width: width,
        height: height,
        renderer: renderer,
      ),
    RasterVisualizationResult(:final pngBytes) => await _validatePng(
      pngBytes,
      renderer,
    ),
    _ => throw StateError('$renderer did not produce an image: $result'),
  };
}

Future<String> _validateSvg(
  WebRenderHost host, {
  required String svg,
  required double width,
  required double height,
  required String renderer,
}) async {
  final png = await host.rasterizeSvg(
    svg: svg,
    width: width,
    height: height,
    scale: 1,
    cancellationToken: VisualizationCancellationToken(),
  );
  await _validatePng(png, renderer);
  return 'svg';
}

Future<void> _expectRaster(
  VisualizationRenderResult result,
  String renderer,
) async {
  if (result is! RasterVisualizationResult) {
    throw StateError('$renderer did not produce raster PNG: $result');
  }
  await _validatePng(result.pngBytes, renderer);
}

Future<String> _validatePng(List<int> pngBytes, String renderer) async {
  final codec = await ui.instantiateImageCodec(Uint8List.fromList(pngBytes));
  final frame = await codec.getNextFrame();
  try {
    final image = frame.image;
    if (image.width < 10 || image.height < 10) {
      throw StateError(
        '$renderer produced an undersized PNG: ${image.width}x${image.height}.',
      );
    }
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (bytes == null) {
      throw StateError('$renderer PNG pixels could not be read.');
    }
    final rgba = bytes.buffer.asUint8List();
    var visiblePixels = 0;
    for (var index = 3; index < rgba.length; index += 4) {
      if (rgba[index] != 0) {
        visiblePixels++;
      }
    }
    if (visiblePixels < 100) {
      throw StateError(
        '$renderer produced a visually empty PNG: $visiblePixels visible pixels.',
      );
    }
    return 'png';
  } finally {
    frame.image.dispose();
    codec.dispose();
  }
}

Future<void> _writeReport(File reportFile, Map<String, Object?> report) async {
  await reportFile.writeAsString(jsonEncode(report), flush: true);
}

const _openApiSource = '''
openapi: 3.1.0
info:
  title: BusyMark release smoke
  version: 1.0.0
paths:
  /status:
    get:
      responses:
        '200':
          description: Ready
''';

const _pdfSource =
    '''
# Visualization release smoke

Inline math remains in the sentence: \$x^2\$, \$\\frac{a}{b}\$, and \$\\Braket{\\psi|\\phi}\$.

\$\$
\\ce{2H2 + O2 -> 2H2O}
\$\$

```mermaid
flowchart LR
  source[Markdown] --> preview[Preview]
```

```plantuml
@startuml
Alice -> Bob: Offline
@enduml
```

```d2
source: |md
  **Offline** rendering
|
source -> output
```

```openapi
$_openApiSource```
''';
