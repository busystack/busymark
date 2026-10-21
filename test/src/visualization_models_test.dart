import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:busymark/src/visualization/visualization_cache.dart';
import 'package:busymark/src/visualization/visualization_models.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('visualization fence classification', () {
    test(
      'recognizes canonical names and aliases without changing spelling',
      () {
        final expectations = <String, VisualizationRendererKind>{
          'MerMAID': VisualizationRendererKind.mermaid,
          'PlantUML': VisualizationRendererKind.plantUml,
          'PUML': VisualizationRendererKind.plantUml,
          'd2': VisualizationRendererKind.d2,
          'OpenAPI': VisualizationRendererKind.openApi,
          'OAS': VisualizationRendererKind.openApi,
          'Swagger': VisualizationRendererKind.openApi,
        };

        for (final entry in expectations.entries) {
          final descriptor = VisualizationDescriptor.forFenceLanguage(
            entry.key,
          );
          expect(descriptor.kind, entry.value, reason: entry.key);
          expect(descriptor.originalLanguage, entry.key, reason: entry.key);
          expect(
            descriptor.canonicalLanguage,
            entry.value.canonicalFence,
            reason: entry.key,
          );
        }
        expect(
          VisualizationDescriptor.maybeForFenceLanguage('javascript'),
          isNull,
        );
      },
    );
  });

  test('preserves dependency diagnostic source locations', () {
    const diagnostic = VisualizationDiagnostic(
      code: 'visualization.invalidOpenApi',
      message: 'Invalid response',
      severity: VisualizationDiagnosticSeverity.error,
      sourceId: 'openapi/components.yaml',
      sourceLine: 14,
      sourceColumn: 7,
    );

    final decoded = VisualizationDiagnostic.fromJson(diagnostic.toJson());
    expect(decoded.sourceId, diagnostic.sourceId);
    expect(decoded.sourceLine, 14);
    expect(decoded.sourceColumn, 7);
    expect(decoded.line, isNull);
  });

  group('visualization cache keys', () {
    test('canonicalizes options and dependency order', () {
      final first = _request(
        options: const VisualizationRendererOptions({
          'z': 1,
          'nested': {'b': true, 'a': false},
        }),
        dependencies: const [
          VisualizationDependency(id: 'b.yaml', hash: 'b', source: 'B'),
          VisualizationDependency(id: 'a.yaml', hash: 'a', source: 'A'),
        ],
      );
      final second = _request(
        options: const VisualizationRendererOptions({
          'nested': {'a': false, 'b': true},
          'z': 1,
        }),
        dependencies: const [
          VisualizationDependency(id: 'a.yaml', hash: 'a', source: 'A'),
          VisualizationDependency(id: 'b.yaml', hash: 'b', source: 'B'),
        ],
      );

      expect(first.cacheKey, second.cacheKey);
    });

    test(
      'invalidates on engine, source, theme, profile, option, and dependency',
      () {
        final base = _request();
        final keys = {
          base.cacheKey,
          _request(engineVersion: 'next').cacheKey,
          _request(source: 'graph TD; B-->C').cacheKey,
          _request(theme: VisualizationTheme.dark).cacheKey,
          _request(profile: VisualizationRenderProfile.pdf).cacheKey,
          _request(
            options: const VisualizationRendererOptions({'layout': 'elk'}),
          ).cacheKey,
          _request(
            dependencies: const [
              VisualizationDependency(
                id: 'a.yaml',
                hash: 'changed',
                source: '',
              ),
            ],
          ).cacheKey,
        };

        expect(keys, hasLength(7));
      },
    );

    test('invalidates entries produced by the previous render pipeline', () {
      final request = _request();
      final legacyKey = sha256
          .convert(
            utf8.encode(
              jsonEncode({
                'renderer': request.kind.name,
                'engineVersion': request.engineVersion,
                'source': request.source,
                'theme': request.theme.name,
                'profile': request.profile.name,
                'options': request.options.canonicalValues,
                'sanitizerVersion': visualizationSanitizerVersion,
                'dependencies': const <Object?>[],
              }),
            ),
          )
          .toString();

      expect(request.cacheKey, isNot(legacyKey));
    });
  });

  group('visualization disk cache', () {
    late Directory directory;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('busymark-viz-cache-');
    });

    tearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    test('round-trips SVG, raster, and structured OpenAPI successes', () async {
      final writer = VisualizationCache(diskRoot: directory);
      const svg = SvgVisualizationResult(
        svg: '<svg viewBox="0 0 10 20"/>',
        width: 10,
        height: 20,
      );
      final raster = RasterVisualizationResult(
        pngBytes: Uint8List.fromList([137, 80, 78, 71]),
        width: 2,
        height: 3,
        pixelRatio: 2,
      );
      const openApi = OpenApiVisualizationResult(
        content: 'openapi: 3.1.0',
        entryId: 'guide.md',
        dependencies: [
          VisualizationDependency(id: 'parts.yaml', hash: 'hash', source: '{}'),
        ],
        reference: OpenApiReferenceModel(
          title: 'Demo',
          apiVersion: '1',
          specificationVersion: '3.1.0',
          valid: true,
          serverCount: 0,
          pathCount: 0,
          operations: [],
          tags: [],
          document: {'openapi': '3.1.0'},
        ),
      );

      await writer.put('svg', svg);
      await writer.put('raster', raster);
      await writer.put('openapi', openApi);
      final reader = VisualizationCache(diskRoot: directory);

      final readSvg = await reader.get('svg') as SvgVisualizationResult;
      final readRaster =
          await reader.get('raster') as RasterVisualizationResult;
      final readOpenApi =
          await reader.get('openapi') as OpenApiVisualizationResult;
      expect(readSvg.svg, svg.svg);
      expect(readRaster.pngBytes, raster.pngBytes);
      expect(readRaster.pixelRatio, 2);
      expect(readOpenApi.reference.title, 'Demo');
      expect(readOpenApi.dependencies.single.id, 'parts.yaml');
    });

    test('does not persist failures and repairs malformed entries', () async {
      final cache = VisualizationCache(diskRoot: directory);
      await cache.put(
        'failure',
        const FailedVisualizationResult(code: 'failed', message: 'failed'),
      );
      expect(await directory.list(followLinks: false).isEmpty, isTrue);

      final broken = File('${directory.path}/broken.json');
      await broken.writeAsString('{broken');
      expect(await cache.get('broken'), isNull);
      expect(await broken.exists(), isFalse);

      const replacement = SvgVisualizationResult(
        svg: '<svg viewBox="0 0 1 1"/>',
        width: 1,
        height: 1,
      );
      await cache.put('broken', replacement);
      final repaired = await VisualizationCache(
        diskRoot: directory,
      ).get('broken');
      expect(repaired, isA<SvgVisualizationResult>());
      expect((repaired! as SvgVisualizationResult).svg, replacement.svg);
    });

    for (final byteLimited in [false, true]) {
      test(
        'concurrent publication trims a full cache by '
        '${byteLimited ? 'bytes' : 'entry count'} and preserves other files',
        () async {
          const result = SvgVisualizationResult(
            svg: '<svg viewBox="0 0 10 20"/>',
            width: 10,
            height: 20,
          );
          await VisualizationCache(diskRoot: directory).put('template', result);
          final templateFile = File('${directory.path}/template.json');
          final template = jsonDecode(await templateFile.readAsString()) as Map;
          await templateFile.delete();
          var recordBytes = 0;
          for (var i = 0; i < 300; i++) {
            final key = 'old${i.toString().padLeft(3, '0')}';
            final encoded = jsonEncode({...template, 'key': key});
            recordBytes = utf8.encode(encoded).length;
            File('${directory.path}/$key.json')
              ..writeAsStringSync(encoded)
              ..setLastModifiedSync(
                DateTime.utc(2020).add(Duration(seconds: i)),
              );
          }
          final unrelated = File('${directory.path}/metadata')
            ..writeAsStringSync('keep');
          final nested = Directory('${directory.path}/nested')..createSync();
          final nestedFile = File('${nested.path}/keep.json')
            ..writeAsStringSync('keep nested');
          final outside = File(
            '${directory.parent.path}/outside-${directory.uri.pathSegments.where((s) => s.isNotEmpty).last}',
          )..writeAsStringSync('keep outside');
          addTearDown(() async {
            if (await outside.exists()) await outside.delete();
          });
          Link? link;
          if (!Platform.isWindows) {
            link = Link('${directory.path}/linked.json')
              ..createSync(outside.path);
          }

          final cache = VisualizationCache(
            diskRoot: directory,
            maximumDiskBytes: byteLimited
                ? recordBytes * 10
                : 256 * 1024 * 1024,
          );
          await Future.wait([
            for (var i = 0; i < 8; i++)
              cache.put('new${i.toString().padLeft(3, '0')}', result),
          ]);
          final files = directory
              .listSync(followLinks: false)
              .whereType<File>()
              .where((file) => file.path.endsWith('.json'))
              .toList();
          final expectedCount = byteLimited ? 10 : 256;
          expect(files, hasLength(expectedCount));
          expect(
            files.fold<int>(0, (sum, file) => sum + file.lengthSync()),
            lessThanOrEqualTo(cache.maximumDiskBytes),
          );
          final firstRetained = 308 - expectedCount;
          expect(
            File(
              '${directory.path}/old${(firstRetained - 1).toString().padLeft(3, '0')}.json',
            ).existsSync(),
            isFalse,
          );
          expect(
            File(
              '${directory.path}/old${firstRetained.toString().padLeft(3, '0')}.json',
            ).existsSync(),
            isTrue,
          );
          final reader = VisualizationCache(diskRoot: directory);
          for (var i = 0; i < 8; i++) {
            expect(
              await reader.get('new${i.toString().padLeft(3, '0')}'),
              isA<SvgVisualizationResult>(),
            );
          }
          expect(unrelated.readAsStringSync(), 'keep');
          expect(nestedFile.readAsStringSync(), 'keep nested');
          expect(outside.readAsStringSync(), 'keep outside');
          if (link != null) expect(link.existsSync(), isTrue);
        },
      );
    }

    test('a failed maintenance scan does not poison subsequent puts', () async {
      if (Platform.isWindows) return;
      const result = SvgVisualizationResult(
        svg: '<svg viewBox="0 0 1 1"/>',
        width: 1,
        height: 1,
      );
      final cache = VisualizationCache(
        diskRoot: directory,
        maximumDiskEntries: 1,
      );
      try {
        expect(
          (await Process.run('chmod', ['300', directory.path])).exitCode,
          0,
        );
        // Creation/rename are allowed, but listing the directory is not.
        expect(directory.listSync, throwsA(isA<FileSystemException>()));
        await cache.put('first', result);
        expect(await cache.get('first'), isA<SvgVisualizationResult>());
        File(
          '${directory.path}/first.json',
        ).setLastModifiedSync(DateTime.utc(2020));
      } finally {
        expect(
          (await Process.run('chmod', ['700', directory.path])).exitCode,
          0,
        );
      }
      await cache.put('second', result);
      expect(File('${directory.path}/first.json').existsSync(), isFalse);
      expect(
        await VisualizationCache(diskRoot: directory).get('second'),
        isA<SvgVisualizationResult>(),
      );
    });

    test('derives the XDG cache path without changing the environment', () {
      final cache = VisualizationCache(
        environment: const {'XDG_CACHE_HOME': '/tmp/custom-cache'},
      );
      expect(
        cache.diskRoot.path,
        '/tmp/custom-cache/busymark/visualizations/v1',
      );
    });
  });
}

VisualizationRenderRequest _request({
  String source = 'graph TD; A-->B',
  String engineVersion = mermaidEngineVersion,
  VisualizationTheme theme = VisualizationTheme.light,
  VisualizationRenderProfile profile = VisualizationRenderProfile.preview,
  VisualizationRendererOptions options = const VisualizationRendererOptions({}),
  List<VisualizationDependency> dependencies = const [],
}) {
  return VisualizationRenderRequest(
    blockKey: 'block',
    kind: VisualizationRendererKind.mermaid,
    source: source,
    sourceStartLine: 1,
    documentPath: '/workspace/guide.md',
    workspaceRoot: '/workspace',
    theme: theme,
    profile: profile,
    engineVersion: engineVersion,
    editRevision: 1,
    options: options,
    dependencies: dependencies,
  );
}
