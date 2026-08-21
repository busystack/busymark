import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:busymark/src/export/markdown_export_document.dart';
import 'package:busymark/src/export/markdown_export_mapper.dart';
import 'package:busymark/src/export/markdown_pdf_export_service.dart';
import 'package:busymark/src/export/markdown_pdf_models.dart';
import 'package:busymark/src/export/markdown_visualization_export.dart';
import 'package:busymark/src/export/openapi_static_export_mapper.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/visualization/visualization_cache.dart';
import 'package:busymark/src/visualization/visualization_coordinator.dart';
import 'package:busymark/src/visualization/visualization_models.dart';
import 'package:busymark/src/visualization/visualization_renderer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory temporaryDirectory;
  late Directory exportRoot;
  late VisualizationCoordinator coordinator;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'busymark-viz-export-',
    );
    exportRoot = await Directory(
      p.join(temporaryDirectory.path, 'export'),
    ).create();
    coordinator = VisualizationCoordinator(
      renderers: [_ExportRenderer()],
      cache: VisualizationCache(
        diskRoot: Directory(p.join(temporaryDirectory.path, 'cache')),
      ),
    );
  });

  tearDown(() async {
    coordinator.dispose();
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test(
    'stages vector/raster assets, maps OpenAPI, and preserves failed source',
    () async {
      final parsed = const MarkdownParser().parse(
        filePath: p.join(temporaryDirectory.path, 'guide.md'),
        source: _allVisualizations,
        workspaceRoot: temporaryDirectory.path,
        validateLocalReferences: false,
      );
      final renderer = MarkdownVisualizationExportRenderer(
        coordinator: coordinator,
      );
      final preparation = await renderer.prepare(
        document: parsed.busyDocument,
        exportRoot: exportRoot,
        documentPath: parsed.filePath,
        workspaceRoot: temporaryDirectory.path,
        cancellationToken: MarkdownPdfCancellationToken(),
      );

      expect(preparation.blockOverrides, hasLength(3));
      expect(preparation.warnings, hasLength(1));
      expect(
        preparation.warnings.single.code,
        MarkdownPdfWarningCode.visualizationRenderFailed,
      );
      final generated = Directory(
        p.join(exportRoot.path, 'generated-assets'),
      ).listSync();
      expect(generated, hasLength(2));
      expect(
        generated.where((item) => item.path.endsWith('.svg')),
        hasLength(1),
      );
      expect(
        generated.where((item) => item.path.endsWith('.png')),
        hasLength(1),
      );
      final svgFile = generated.singleWhere(
        (item) => item.path.endsWith('.svg'),
      );
      expect(
        await File(svgFile.path).readAsString(),
        isNot(contains('<style')),
      );

      final mapped = const MarkdownExportMapper().map(
        parsed.busyDocument,
        blockOverrides: preparation.blockOverrides,
      );
      expect(
        mapped.blocks.map((block) => block.kind),
        containsAll([
          MarkdownExportBlockKind.visualization,
          MarkdownExportBlockKind.openApiReference,
          MarkdownExportBlockKind.code,
        ]),
      );
      final failedPlantUml = mapped.blocks.singleWhere(
        (block) =>
            block.kind == MarkdownExportBlockKind.code &&
            block.attributes['language'] == 'plantuml',
      );
      expect(failedPlantUml.text, contains('@startuml'));
    },
  );

  test(
    'enforces the export block count without failing the document',
    () async {
      final parsed = const MarkdownParser().parse(
        filePath: p.join(temporaryDirectory.path, 'guide.md'),
        source: _allVisualizations,
        validateLocalReferences: false,
      );
      final preparation =
          await MarkdownVisualizationExportRenderer(
            coordinator: coordinator,
            maximumBlocks: 1,
          ).prepare(
            document: parsed.busyDocument,
            exportRoot: exportRoot,
            documentPath: parsed.filePath,
            workspaceRoot: temporaryDirectory.path,
            cancellationToken: MarkdownPdfCancellationToken(),
          );

      expect(preparation.blockOverrides, hasLength(1));
      expect(
        preparation.warnings.map((warning) => warning.code),
        contains(MarkdownPdfWarningCode.visualizationLimitReached),
      );
    },
  );

  test('static OpenAPI export contains selectable reference sections', () {
    const reference = OpenApiReferenceModel(
      title: 'Inventory',
      apiVersion: '2.0',
      specificationVersion: '3.1.0',
      valid: true,
      serverCount: 1,
      pathCount: 1,
      operations: [
        OpenApiOperation(
          method: 'POST',
          path: '/items',
          summary: 'Create item',
          operationId: 'createItem',
          tags: ['Items'],
        ),
      ],
      tags: ['Items'],
      document: {
        'openapi': '3.1.0',
        'info': {
          'title': 'Inventory',
          'version': '2.0',
          'description': 'Inventory API description',
        },
        'servers': [
          {'url': 'https://api.example.test', 'description': 'Demo'},
        ],
        'security': [
          {'bearer': <Object?>[]},
        ],
        'paths': {
          '/items': {
            'post': {
              'summary': 'Create item',
              'operationId': 'createItem',
              'tags': ['Items'],
              'parameters': [
                {
                  'name': 'trace',
                  'in': 'header',
                  'schema': {
                    'type': ['string', 'null'],
                  },
                },
              ],
              'requestBody': {
                'required': true,
                'content': {
                  'application/json': {
                    'schema': {r'$ref': '#/components/schemas/Item'},
                  },
                },
              },
              'responses': {
                '201': {'description': 'Created'},
              },
            },
          },
        },
        'components': {
          'securitySchemes': {
            'bearer': {'type': 'http', 'scheme': 'bearer'},
          },
          'schemas': {
            'Item': {
              'type': 'object',
              'required': ['id'],
              'properties': {
                'id': {'type': 'string', 'format': 'uuid'},
              },
            },
          },
        },
      },
    );

    final block = const OpenApiStaticExportMapper().map(reference);
    final text = _exportText(block);
    expect(block.kind, MarkdownExportBlockKind.openApiReference);
    expect(text, contains('Inventory API Reference'));
    expect(text, contains('Servers'));
    expect(text, contains('POST /items'));
    expect(text, contains('Parameters'));
    expect(text, contains('string | null'));
    expect(text, contains('Request body'));
    expect(text, contains('Responses'));
    expect(text, contains('Security schemes'));
    expect(text, contains('Schemas'));
    expect(text, isNot(contains('Scalar')));
  });

  final typstPath = Platform.environment['BUSYMARK_TYPST_PATH'];
  test(
    'Typst exports generated vector/raster assets and falls back on failure',
    () async {
      final destination = p.join(temporaryDirectory.path, 'visualizations.pdf');
      final service = MarkdownPdfExportService(
        visualizationRenderer: MarkdownVisualizationExportRenderer(
          coordinator: coordinator,
        ),
        templateLoader: () => File('assets/export/markdown.typ').readAsString(),
      );

      final result = await service.export(
        MarkdownPdfExportRequest(
          source: _allVisualizations,
          filePath: p.join(temporaryDirectory.path, 'guide.md'),
          workspaceRoot: temporaryDirectory.path,
          destinationPath: destination,
          options: const MarkdownPdfOptions(),
          overwrite: false,
        ),
      );

      final bytes = await File(destination).readAsBytes();
      expect(bytes.take(5), [0x25, 0x50, 0x44, 0x46, 0x2d]);
      expect(bytes.length, greaterThan(1000));
      expect(
        result.warnings.map((warning) => warning.code),
        contains(MarkdownPdfWarningCode.visualizationRenderFailed),
      );

      final previewRoot = p.join(temporaryDirectory.path, 'pdf-preview');
      final rasterized = await Process.run('pdftoppm', [
        '-f',
        '1',
        '-singlefile',
        '-r',
        '96',
        '-png',
        destination,
        previewRoot,
      ]);
      expect(rasterized.exitCode, 0, reason: rasterized.stderr.toString());
      final previewBytes = await File('$previewRoot.png').readAsBytes();
      final codec = await ui.instantiateImageCodec(previewBytes);
      final frame = await codec.getNextFrame();
      final pixels = await frame.image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      expect(pixels, isNotNull);
      var blueDiagramPixels = 0;
      final rgba = pixels!.buffer.asUint8List();
      for (var index = 0; index + 3 < rgba.length; index += 4) {
        final red = rgba[index];
        final green = rgba[index + 1];
        final blue = rgba[index + 2];
        if (blue > 120 && blue > green + 35 && green > red + 25) {
          blueDiagramPixels++;
        }
      }
      frame.image.dispose();
      codec.dispose();
      expect(
        blueDiagramPixels,
        greaterThan(500),
        reason: 'The styled vector diagram was not visible in the PDF page.',
      );
    },
    skip: typstPath == null || !File(typstPath).existsSync()
        ? 'Set BUSYMARK_TYPST_PATH to run the visualization PDF integration test.'
        : false,
  );
}

const _allVisualizations = r'''
# Visualizations

```mermaid
graph TD; A-->B
```

```plantuml
@startuml
A -> B
@enduml
```

```d2
a -> b
```

```openapi
openapi: 3.1.0
info:
  title: Demo
  version: 1.0.0
paths: {}
```
''';

String _exportText(MarkdownExportBlock block) {
  final buffer = StringBuffer()
    ..write(block.text)
    ..writeAll(block.inlines.map((inline) => inline.text), ' ');
  for (final child in block.children) {
    buffer
      ..write(' ')
      ..write(_exportText(child));
  }
  return buffer.toString();
}

class _ExportRenderer implements VisualizationRenderer {
  static final _png = Uint8List.fromList(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    ),
  );

  @override
  Set<VisualizationRendererKind> get supportedKinds =>
      VisualizationRendererKind.values.toSet();

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
  ) async {
    cancellationToken.throwIfCancelled();
    return switch (request.kind) {
      VisualizationRendererKind.mermaid => const SvgVisualizationResult(
        svg:
            '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 40 20"><style>.n{fill:#2563a5}</style><rect class="n" width="40" height="20"/></svg>''',
        width: 40,
        height: 20,
      ),
      VisualizationRendererKind.plantUml => const FailedVisualizationResult(
        code: 'visualization.invalidPlantUml',
        message: 'Invalid PlantUML',
        retryable: false,
      ),
      VisualizationRendererKind.d2 => RasterVisualizationResult(
        pngBytes: _png,
        width: 1,
        height: 1,
      ),
      VisualizationRendererKind.openApi => const OpenApiVisualizationResult(
        content: 'openapi: 3.1.0',
        reference: OpenApiReferenceModel(
          title: 'Demo',
          apiVersion: '1.0.0',
          specificationVersion: '3.1.0',
          valid: true,
          serverCount: 0,
          pathCount: 0,
          operations: [],
          tags: [],
          document: {
            'openapi': '3.1.0',
            'info': {'title': 'Demo', 'version': '1.0.0'},
            'paths': <String, Object?>{},
          },
        ),
      ),
    };
  }
}
