import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:busymark/src/export/html_export_models.dart';
import 'package:busymark/src/export/html_export_service.dart';
import 'package:busymark/src/math/math_coordinator.dart';
import 'package:busymark/src/math/math_renderer.dart';
import 'package:busymark/src/visualization/visualization_cache.dart';
import 'package:busymark/src/visualization/visualization_coordinator.dart';
import 'package:busymark/src/visualization/visualization_models.dart';
import 'package:busymark/src/visualization/visualization_renderer.dart';
import 'package:busymark/src/visualization/web_render_host.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'HTML uses unique occurrence jobs, standalone math and diagram/static API engines',
    () async {
      final root = await Directory.systemTemp.createTemp('html-rich-');
      addTearDown(() => root.delete(recursive: true));
      final host = _MathHost();
      final math = MathCoordinator(renderer: MathRenderer(host: host));
      addTearDown(math.dispose);
      final renderer = _Diagrams();
      final visualization = VisualizationCoordinator(
        renderers: [renderer],
        cache: VisualizationCache(
          diskRoot: Directory(p.join(root.path, 'cache')),
        ),
      );
      addTearDown(visualization.dispose);
      final service = HtmlExportService(
        math: math,
        visualization: visualization,
      );
      final result = await service.exportMarkdown(
        MarkdownHtmlExportRequest(
          source: r'''# Rich $H$

Inline $x^2$ and $\alpha$.

$$
\int_0^1 x dx
$$

```mermaid
graph LR; A-->B
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
```

## After API
''',
          filePath: p.join(root.path, 'source.md'),
          workspaceRoot: root.path,
          destinationPath: p.join(root.path, 'out.html'),
        ),
      );
      expect(result.warnings, isEmpty);
      final doc = html.parse(await File(result.entryPointPath).readAsString());
      expect(doc.querySelectorAll('.math-inline').length, 3);
      expect(doc.querySelectorAll('.math-display').length, 1);
      expect(doc.querySelectorAll('img').length, 7);
      expect(doc.body!.text, contains('Test API'));
      final outline = doc
          .querySelectorAll('.outline a')
          .map((e) => e.text)
          .toList();
      expect(outline.last, 'After API');
      expect(
        outline.indexWhere((e) => e.contains('Test API')),
        lessThan(outline.indexOf('After API')),
      );
      expect(
        renderer.requests.map((r) => r.profile),
        everyElement(VisualizationRenderProfile.html),
      );
      expect(renderer.requests.map((r) => r.blockKey).toSet().length, 4);
      expect(
        host.requests.map((r) => r['renderProfile']),
        everyElement('html'),
      );
      expect(host.requests.first['em'], closeTo(39.1, .0001));
      expect(host.requests.skip(1).map((r) => r['em']), everyElement(17.0));
      for (final file in await Directory(
        result.assetsPath!,
      ).list().where((f) => f.path.endsWith('.svg')).toList()) {
        final svg = await File(file.path).readAsString();
        expect(svg, isNot(contains('currentColor')));
        expect(svg, isNot(contains('http://localhost')));
      }
    },
  );

  test(
    'custom HTML metrics and embedded rich assets stay self-contained',
    () async {
      final root = await Directory.systemTemp.createTemp('html-rich-options-');
      addTearDown(() => root.delete(recursive: true));
      final host = _MathHost();
      final math = MathCoordinator(renderer: MathRenderer(host: host));
      addTearDown(math.dispose);
      final visualization = VisualizationCoordinator(
        renderers: [_Diagrams()],
        cache: VisualizationCache(
          diskRoot: Directory(p.join(root.path, 'cache')),
        ),
      );
      addTearDown(visualization.dispose);
      const options = HtmlExportOptions(
        baseFontSize: 22,
        contentMaxWidth: 1100,
        packaging: HtmlPackaging.singleFile,
      );
      final result =
          await HtmlExportService(
            math: math,
            visualization: visualization,
          ).exportMarkdown(
            MarkdownHtmlExportRequest(
              source:
                  r'# Heading $h$'
                  '\n\n'
                  r'Inline $x$'
                  '\n\n'
                  r'$$d$$'
                  '\n\n```mermaid\ngraph LR; A-->B\n```',
              filePath: p.join(root.path, 'source.md'),
              workspaceRoot: root.path,
              destinationPath: p.join(root.path, 'out.html'),
              options: options,
            ),
          );
      expect(result.warnings, isEmpty);
      expect(result.assetsPath, isNull);
      final doc = html.parse(await File(result.entryPointPath).readAsString());
      expect(doc.querySelectorAll('img'), hasLength(4));
      expect(
        doc.querySelectorAll('img').map((e) => e.attributes['src']),
        everyElement(startsWith('data:image/svg+xml;base64,')),
      );
      expect(
        host.requests.map((r) => r['containerWidth']),
        everyElement(968.0),
      );
      expect(host.requests.first['em'], options.headingFontSize(1));
      expect(host.requests.skip(1).map((r) => r['em']), everyElement(22.0));
    },
  );

  test('all diagram dependencies are captured before rendering begins', () async {
    final root = await Directory.systemTemp.createTemp('html-dependencies-');
    addTearDown(() => root.delete(recursive: true));
    final dependency = File(p.join(root.path, 'schema.json'));
    await dependency.writeAsString('original dependency');
    final renderer = _Diagrams(dependency: dependency);
    final coordinator = VisualizationCoordinator(
      renderers: [renderer],
      cache: VisualizationCache(
        diskRoot: Directory(p.join(root.path, 'cache')),
      ),
    );
    addTearDown(coordinator.dispose);
    final result = await HtmlExportService(visualization: coordinator)
        .exportMarkdown(
          MarkdownHtmlExportRequest(
            source:
                '```mermaid\ngraph LR; A-->B\n```\n\n```openapi\nopenapi: 3.1.0\n```',
            filePath: p.join(root.path, 'source.md'),
            workspaceRoot: root.path,
            destinationPath: p.join(root.path, 'out.html'),
          ),
          onProgress: (_, _) =>
              dependency.writeAsStringSync('later dependency'),
        );
    expect(result.warnings, isEmpty);
    expect(renderer.preparations, 2);
    expect(
      renderer.requests.map((r) => r.options.values['captured']),
      everyElement('original dependency'),
    );
  });

  test(
    'cancelling an active render retains existing output and removes staging',
    () async {
      final root = await Directory.systemTemp.createTemp('html-render-cancel-');
      addTearDown(() => root.delete(recursive: true));
      final destination = File(p.join(root.path, 'out.html'));
      await destination.writeAsString('Previous usable output');
      final renderer = _Diagrams(hang: true);
      final coordinator = VisualizationCoordinator(
        renderers: [renderer],
        cache: VisualizationCache(
          diskRoot: Directory(p.join(root.path, 'cache')),
        ),
      );
      addTearDown(coordinator.dispose);
      final token = HtmlExportCancellationToken();
      final pending = HtmlExportService(visualization: coordinator)
          .exportMarkdown(
            MarkdownHtmlExportRequest(
              source: '```d2\na -> b\n```',
              filePath: p.join(root.path, 'source.md'),
              workspaceRoot: root.path,
              destinationPath: destination.path,
              overwrite: true,
            ),
            cancellationToken: token,
          );
      final expectation = expectLater(
        pending,
        throwsA(
          isA<HtmlExportException>().having(
            (e) => e.cancelled,
            'cancelled',
            isTrue,
          ),
        ),
      );
      for (var i = 0; i < 200 && renderer.requests.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      expect(renderer.requests, isNotEmpty);
      token.cancel();
      await expectation;
      expect(await destination.readAsString(), 'Previous usable output');
      expect(
        await root
            .list()
            .where((f) => p.basename(f.path).startsWith('.busymark-html-'))
            .length,
        0,
      );
    },
  );

  test(
    'render timeout is bounded and cancellation interrupts a pending job',
    () async {
      final root = await Directory.systemTemp.createTemp('html-timeout-');
      addTearDown(() => root.delete(recursive: true));
      final renderer = _Diagrams(hang: true);
      final coordinator = VisualizationCoordinator(
        renderers: [renderer],
        cache: VisualizationCache(
          diskRoot: Directory(p.join(root.path, 'cache')),
        ),
      );
      addTearDown(coordinator.dispose);
      final service = HtmlExportService(
        visualization: coordinator,
        limits: const HtmlExportLimits(
          renderTimeout: Duration(milliseconds: 50),
        ),
      );
      final result = await service.exportMarkdown(
        MarkdownHtmlExportRequest(
          source: '```d2\na -> b\n```',
          filePath: p.join(root.path, 'source.md'),
          workspaceRoot: root.path,
          destinationPath: p.join(root.path, 'out.html'),
        ),
      );
      expect(result.warnings.single.code, 'render.failed');
      expect(
        await File(result.entryPointPath).readAsString(),
        contains('a -&gt; b'),
      );
    },
  );
}

class _MathHost implements WebRenderHost {
  final requests = <Map<String, Object?>>[];
  @override
  Future<Map<Object?, Object?>> renderMathBatch({
    required List<Map<String, Object?>> expressions,
    required VisualizationCancellationToken cancellationToken,
  }) async {
    requests.addAll(expressions);
    return {
      'results': [
        for (final e in expressions)
          {
            'id': e['id'],
            'svg':
                r'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 -10 30 14" data-latex="\int"><defs><path id="glyph" d="M0 0L10 10L20 0"/></defs><use href="#glyph" fill="currentColor"/></svg>',
            'width': 30,
            'height': 14,
            'depth': 2,
          },
      ],
    };
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Diagrams implements VisualizationRenderer {
  _Diagrams({this.hang = false, this.dependency});
  final File? dependency;
  int preparations = 0;
  final bool hang;
  final requests = <VisualizationRenderRequest>[];
  @override
  Set<VisualizationRendererKind> get supportedKinds =>
      VisualizationRendererKind.values.toSet();
  @override
  Future<VisualizationRenderRequest> prepare(
    VisualizationRenderRequest r,
    VisualizationCancellationToken t,
  ) async {
    preparations++;
    return dependency == null
        ? r
        : r.copyWith(
            options: VisualizationRendererOptions({
              'captured': await dependency!.readAsString(),
            }),
          );
  }

  @override
  Future<VisualizationRenderResult> render(
    VisualizationRenderRequest r,
    VisualizationCancellationToken t,
  ) async {
    requests.add(r);
    if (hang) {
      final c = Completer<VisualizationRenderResult>();
      t.onCancel(
        () => c.completeError(const VisualizationCancelledException()),
      );
      return c.future;
    }
    if (r.kind == VisualizationRendererKind.openApi) {
      return const OpenApiVisualizationResult(
        content: 'openapi: 3.1.0',
        reference: OpenApiReferenceModel(
          title: 'Test API',
          apiVersion: '1',
          specificationVersion: '3.1.0',
          valid: true,
          serverCount: 0,
          pathCount: 0,
          operations: [],
          tags: [],
          document: {
            'openapi': '3.1.0',
            'info': {'title': 'Test API', 'version': '1'},
            'paths': <String, Object?>{},
          },
        ),
      );
    }
    if (r.kind == VisualizationRendererKind.d2) {
      return RasterVisualizationResult(
        pngBytes: Uint8List.fromList(
          base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
          ),
        ),
        width: 1,
        height: 1,
      );
    }
    return const SvgVisualizationResult(
      svg:
          '<svg xmlns="http://www.w3.org/2000/svg" width="40" height="20"><rect width="40" height="20" fill="blue"/></svg>',
      width: 40,
      height: 20,
    );
  }
}
