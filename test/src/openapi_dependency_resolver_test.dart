import 'dart:io';
import 'dart:typed_data';

import 'package:busymark/src/visualization/openapi_dependency_resolver.dart';
import 'package:busymark/src/visualization/visualization_models.dart';
import 'package:busymark/src/visualization/visualization_renderer.dart';
import 'package:busymark/src/visualization/web_render_host.dart';
import 'package:busymark/src/visualization/web_visualization_renderer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory workspace;
  late File document;

  setUp(() async {
    workspace = await Directory.systemTemp.createTemp('busymark-openapi-');
    document = File(p.join(workspace.path, 'guide.md'));
    await document.writeAsString('# API');
  });

  tearDown(() async {
    if (await workspace.exists()) {
      await workspace.delete(recursive: true);
    }
  });

  test(
    'resolves local files, hashes them, and terminates circular schemas',
    () async {
      final component = File(p.join(workspace.path, 'components.yaml'));
      const componentSource =
          '''
components:
  schemas:
    Node:
      type: object
      properties:
        child:
          ${r'$ref'}: "#/components/schemas/Node"
''';
      await component.writeAsString(componentSource);
      final host = _ReferenceHost({
        'entry-source': ['components.yaml#/components/schemas/Node'],
        componentSource: ['#/components/schemas/Node'],
      });
      final resolved = await OpenApiDependencyResolver(host: host).resolve(
        _request(document, workspace, 'entry-source'),
        VisualizationCancellationToken(),
      );

      expect(resolved.options.values['openApiEntryId'], 'guide.md');
      expect(resolved.dependencies, hasLength(1));
      expect(resolved.dependencies.single.id, 'components.yaml');
      expect(resolved.dependencies.single.source, componentSource);
      expect(resolved.dependencies.single.hash, hasLength(64));
      expect(host.inspectedSources, ['entry-source', componentSource]);
    },
  );

  test('keeps internal-only references independent of a saved path', () async {
    final host = _ReferenceHost({
      'entry-source': ['#/components/schemas/Node'],
    });
    final request = _request(document, workspace, 'entry-source').copyWith();
    final unsaved = VisualizationRenderRequest(
      blockKey: request.blockKey,
      kind: request.kind,
      source: request.source,
      sourceStartLine: request.sourceStartLine,
      documentPath: '',
      workspaceRoot: '',
      theme: request.theme,
      profile: request.profile,
      engineVersion: request.engineVersion,
      editRevision: request.editRevision,
    );

    final resolved = await OpenApiDependencyResolver(
      host: host,
    ).resolve(unsaved, VisualizationCancellationToken());
    expect(resolved.dependencies, isEmpty);
    expect(resolved.options.values['openApiEntryId'], 'document.openapi');
  });

  test(
    'rejects remote, absolute, malformed, and unsupported references',
    () async {
      for (final reference in [
        'https://example.com/openapi.yaml',
        '/etc/passwd.json',
        r'folder\file.yaml',
        'folder%5Cfile.yaml',
        'components.txt',
        '%ZZ.yaml',
      ]) {
        final host = _ReferenceHost({
          'entry-source': [reference],
        });
        await expectLater(
          OpenApiDependencyResolver(host: host).resolve(
            _request(document, workspace, 'entry-source'),
            VisualizationCancellationToken(),
          ),
          throwsA(isA<OpenApiDependencyException>()),
          reason: reference,
        );
      }
    },
  );

  test('reports an unsaved document that contains a local reference', () async {
    final host = _ReferenceHost({
      'entry-source': ['components.yaml'],
    });
    final request = _request(document, workspace, 'entry-source');
    final unsaved = VisualizationRenderRequest(
      blockKey: request.blockKey,
      kind: request.kind,
      source: request.source,
      sourceStartLine: request.sourceStartLine,
      documentPath: '',
      workspaceRoot: '',
      theme: request.theme,
      profile: request.profile,
      engineVersion: request.engineVersion,
      editRevision: request.editRevision,
    );

    await expectLater(
      OpenApiDependencyResolver(
        host: host,
      ).resolve(unsaved, VisualizationCancellationToken()),
      throwsA(
        isA<OpenApiDependencyException>()
            .having(
              (error) => error.code,
              'code',
              'visualization.openapiUnsavedReference',
            )
            .having((error) => error.line, 'line', 3),
      ),
    );
  });

  test(
    'converts traversal and symlink escapes into typed diagnostics',
    () async {
      final outside = File(
        p.join(
          workspace.parent.path,
          '${p.basename(workspace.path)}-outside.yaml',
        ),
      );
      await outside.writeAsString('{}');
      addTearDown(() async {
        if (await outside.exists()) {
          await outside.delete();
        }
      });

      Future<void> expectUnsafe(String reference) async {
        final host = _ReferenceHost({
          'entry-source': [reference],
        });
        final renderer = WebVisualizationRenderer(host: host);
        final prepared = await renderer.prepare(
          _request(document, workspace, 'entry-source'),
          VisualizationCancellationToken(),
        );
        expect(
          prepared.options.values['preparationErrorCode'],
          'visualization.openapiUnsafeReference',
        );
        expect(prepared.options.values['preparationErrorLine'], 3);
      }

      await expectUnsafe('../outside.yaml');
      if (Platform.isLinux) {
        final link = Link(p.join(workspace.path, 'linked.yaml'));
        await link.create(outside.path);
        await expectUnsafe('linked.yaml');
      }
    },
  );

  test('enforces dependency count and byte limits', () async {
    await File(p.join(workspace.path, 'a.yaml')).writeAsString('a: 1');
    await File(p.join(workspace.path, 'b.yaml')).writeAsString('b: 2');
    final host = _ReferenceHost({
      'entry-source': ['a.yaml', 'b.yaml'],
      'a: 1': const [],
      'b: 2': const [],
    });

    await expectLater(
      OpenApiDependencyResolver(host: host, maximumFiles: 1).resolve(
        _request(document, workspace, 'entry-source'),
        VisualizationCancellationToken(),
      ),
      throwsA(isA<OpenApiDependencyException>()),
    );
    await expectLater(
      OpenApiDependencyResolver(host: host, maximumFileBytes: 2).resolve(
        _request(document, workspace, 'entry-source'),
        VisualizationCancellationToken(),
      ),
      throwsA(isA<OpenApiDependencyException>()),
    );
  });
}

VisualizationRenderRequest _request(
  File document,
  Directory workspace,
  String source,
) {
  return VisualizationRenderRequest(
    blockKey: 'openapi',
    kind: VisualizationRendererKind.openApi,
    source: source,
    sourceStartLine: 1,
    documentPath: document.path,
    workspaceRoot: workspace.path,
    theme: VisualizationTheme.light,
    profile: VisualizationRenderProfile.preview,
    engineVersion: scalarOpenApiParserVersion,
    editRevision: 1,
  );
}

class _ReferenceHost implements WebRenderHost {
  _ReferenceHost(this.references);

  final Map<String, List<String>> references;
  final List<String> inspectedSources = [];

  @override
  Future<Map<Object?, Object?>> renderMathBatch({
    required List<Map<String, Object?>> expressions,
    required VisualizationCancellationToken cancellationToken,
  }) => throw UnimplementedError();

  @override
  Future<void> copyPngToClipboard(Uint8List pngBytes) =>
      throw UnimplementedError();

  @override
  Future<List<OpenApiSourceReference>> inspectOpenApiReferences(
    String source,
    VisualizationCancellationToken cancellationToken,
  ) async {
    cancellationToken.throwIfCancelled();
    inspectedSources.add(source);
    return [
      for (final value in references[source] ?? const <String>[])
        OpenApiSourceReference(value: value, line: 3, column: 7),
    ];
  }

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

  @override
  Future<Uint8List> rasterizeSvg({
    required String svg,
    required double width,
    required double height,
    required double scale,
    required VisualizationCancellationToken cancellationToken,
  }) => throw UnimplementedError();

  @override
  Future<Map<Object?, Object?>> renderMermaid({
    required String source,
    required VisualizationTheme theme,
    required VisualizationCancellationToken cancellationToken,
  }) => throw UnimplementedError();

  @override
  Future<Map<Object?, Object?>> renderPlantUml({
    required String source,
    required VisualizationTheme theme,
    required VisualizationCancellationToken cancellationToken,
  }) => throw UnimplementedError();
}
