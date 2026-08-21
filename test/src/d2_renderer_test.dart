import 'dart:io';
import 'dart:typed_data';

import 'package:busymark/src/visualization/d2_renderer.dart';
import 'package:busymark/src/visualization/visualization_models.dart';
import 'package:busymark/src/visualization/visualization_renderer.dart';
import 'package:busymark/src/visualization/web_render_host.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('D2 source policy', () {
    const policy = D2SourcePolicy();

    test('rejects imports and icon assets with source locations', () {
      final import = policy.validate('a -> @shared.yaml\n');
      final icon = policy.validate('a: { icon: ./private.svg }\n');

      expect(import?.code, 'visualization.d2ImportsDisabled');
      expect(import?.line, 1);
      expect(import?.column, 6);
      expect(icon?.code, 'visualization.d2ExternalAssetsDisabled');
    });

    test(
      'does not treat comments, quoted labels, or block strings as imports',
      () {
        expect(
          policy.validate('''
# @ignored.yaml
label: "author@example.test"
description: |md
  Contact @support inside Markdown.
|
"icon: ./not-an-asset.svg": value
'''),
          isNull,
        );
      },
    );
  });

  test(
    'returns normalized vector SVG for browser-independent output',
    () async {
      final runner = _FakeD2Runner(
        stdout: Uint8List.fromList(
          '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 10">
  <style>.node { fill: red; }</style><rect class="node" width="20" height="10" />
</svg>
'''
              .codeUnits,
        ),
      );
      final host = _RasterHost();
      final renderer = D2VisualizationRenderer(
        webRenderHost: host,
        locator: const D2ExecutableLocator(
          environment: {'BUSYMARK_D2_PATH': '/bin/true'},
        ),
        commandRunner: runner,
      );

      final result = await renderer.render(
        _request(),
        VisualizationCancellationToken(),
      );
      expect(result, isA<SvgVisualizationResult>());
      expect((result as SvgVisualizationResult).svg, isNot(contains('<style')));
      expect(result.svg, contains('fill="#f00"'));
      expect(host.rasterCalls, 0);
    },
  );

  test('rasterizes foreignObject output at PDF resolution', () async {
    final runner = _FakeD2Runner(
      stdout: Uint8List.fromList(
        '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 10">
  <foreignObject width="20" height="10"><div xmlns="http://www.w3.org/1999/xhtml">Text</div></foreignObject>
</svg>
'''
            .codeUnits,
      ),
    );
    final host = _RasterHost();
    final renderer = D2VisualizationRenderer(
      webRenderHost: host,
      locator: const D2ExecutableLocator(
        environment: {'BUSYMARK_D2_PATH': '/bin/true'},
      ),
      commandRunner: runner,
    );

    final result = await renderer.render(
      _request(profile: VisualizationRenderProfile.pdf),
      VisualizationCancellationToken(),
    );
    expect(result, isA<RasterVisualizationResult>());
    expect((result as RasterVisualizationResult).width, 60);
    expect(result.height, 30);
    expect(host.lastScale, 3);
  });

  test(
    'rasterizes browser CSS that cannot be preserved in vector form',
    () async {
      final runner = _FakeD2Runner(
        stdout: Uint8List.fromList(
          '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 10">
  <style>
    @font-face { font-family: local; src: url(data:font/woff2;base64,AAAA); }
    text { font-family: local; }
  </style>
  <text>Styled</text>
</svg>
'''
              .codeUnits,
        ),
      );
      final host = _RasterHost();
      final renderer = D2VisualizationRenderer(
        webRenderHost: host,
        locator: const D2ExecutableLocator(
          environment: {'BUSYMARK_D2_PATH': '/bin/true'},
        ),
        commandRunner: runner,
      );

      final result = await renderer.render(
        _request(),
        VisualizationCancellationToken(),
      );

      expect(result, isA<RasterVisualizationResult>());
      expect(host.rasterCalls, 1);
      expect(host.lastSvg, contains('data:font/woff2;base64,AAAA'));
    },
  );

  test('maps D2 diagnostics and renderer limits to typed results', () async {
    final invalid = D2VisualizationRenderer(
      webRenderHost: _RasterHost(),
      locator: const D2ExecutableLocator(
        environment: {'BUSYMARK_D2_PATH': '/bin/true'},
      ),
      commandRunner: _FakeD2Runner(
        exitCode: 1,
        stderr: 'err: -:2:3: unexpected token\n',
      ),
    );
    final invalidResult = await invalid.render(
      _request(),
      VisualizationCancellationToken(),
    );
    expect(invalidResult, isA<FailedVisualizationResult>());
    expect(invalidResult.diagnostics.single.line, 2);
    expect(invalidResult.diagnostics.single.column, 3);

    final limited = D2VisualizationRenderer(
      webRenderHost: _RasterHost(),
      maximumSourceCharacters: 2,
    );
    expect(
      await limited.render(_request(), VisualizationCancellationToken()),
      isA<UnsupportedVisualizationResult>(),
    );
  });

  test('locates only executable files at deterministic bundle paths', () async {
    final directory = await Directory.systemTemp.createTemp(
      'busymark-d2-locator-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final executable = File('${directory.path}/d2');
    await executable.writeAsString('not executable');
    expect(
      D2ExecutableLocator(
        environment: {'BUSYMARK_D2_PATH': executable.path},
        resolvedExecutable: '/missing/busymark',
      ).locate(),
      isNull,
    );
    if (Platform.isLinux) {
      expect(
        (await Process.run('chmod', ['700', executable.path])).exitCode,
        0,
      );
      expect(
        D2ExecutableLocator(
          environment: {'BUSYMARK_D2_PATH': executable.path},
        ).locate(),
        executable.path,
      );
    }
  });

  final bundledD2 = Platform.environment['BUSYMARK_D2_PATH'];
  test(
    'bundled D2 CLI renders stdin to stdout without a shell',
    () async {
      final result = await const DartD2CommandRunner().render(
        executable: bundledD2!,
        source: 'a -> b\n',
        theme: VisualizationTheme.light,
        cancellationToken: VisualizationCancellationToken(),
      );
      expect(result.exitCode, 0);
      expect(String.fromCharCodes(result.stdout), contains('<svg'));
    },
    skip: bundledD2 == null || !File(bundledD2).existsSync()
        ? 'Set BUSYMARK_D2_PATH to run the bundled D2 integration test.'
        : false,
  );
}

VisualizationRenderRequest _request({
  VisualizationRenderProfile profile = VisualizationRenderProfile.preview,
}) {
  return VisualizationRenderRequest(
    blockKey: 'd2',
    kind: VisualizationRendererKind.d2,
    source: 'a -> b',
    sourceStartLine: 1,
    documentPath: '/workspace/guide.md',
    workspaceRoot: '/workspace',
    theme: VisualizationTheme.light,
    profile: profile,
    engineVersion: d2EngineVersion,
    editRevision: 1,
  );
}

class _FakeD2Runner implements D2CommandRunner {
  _FakeD2Runner({this.exitCode = 0, Uint8List? stdout, this.stderr = ''})
    : stdout = stdout ?? Uint8List(0);

  final int exitCode;
  final Uint8List stdout;
  final String stderr;

  @override
  Future<D2ProcessResult> render({
    required String executable,
    required String source,
    required VisualizationTheme theme,
    required VisualizationCancellationToken cancellationToken,
  }) async {
    cancellationToken.throwIfCancelled();
    return D2ProcessResult(exitCode: exitCode, stdout: stdout, stderr: stderr);
  }
}

class _RasterHost implements WebRenderHost {
  var rasterCalls = 0;
  double? lastScale;
  String? lastSvg;

  @override
  Future<Map<Object?, Object?>> renderMathBatch({
    required List<Map<String, Object?>> expressions,
    required VisualizationCancellationToken cancellationToken,
  }) => throw UnimplementedError();

  @override
  Future<void> copyPngToClipboard(Uint8List pngBytes) async {}

  @override
  Future<Uint8List> rasterizeSvg({
    required String svg,
    required double width,
    required double height,
    required double scale,
    required VisualizationCancellationToken cancellationToken,
  }) async {
    rasterCalls++;
    lastScale = scale;
    lastSvg = svg;
    return Uint8List.fromList([137, 80, 78, 71]);
  }

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
