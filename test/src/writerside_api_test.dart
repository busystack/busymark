import 'dart:convert';
import 'dart:io';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/writerside/writerside_document_renderer.dart';
import 'package:busymark/src/writerside/writerside_document_resolver.dart';
import 'package:busymark/src/writerside/writerside_module_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('io.busystack.busymark/visualization');
  final spec = <String, Object?>{
    'openapi': '3.1.0',
    'info': {'title': 'Pets', 'version': '1'},
    'paths': {
      '/pets': {
        'get': {
          'summary': 'List pets',
          'tags': ['Pet'],
          'responses': {
            '200': {'description': 'Found pets'},
          },
        },
      },
      '/users': {
        'post': {
          'summary': 'Add users',
          'tags': ['User'],
          'responses': {
            '201': {'description': 'User created'},
          },
        },
      },
    },
    'webhooks': {
      'petAdded': {
        'post': {
          'summary': 'Pet added',
          'responses': {
            '200': {'description': 'Accepted'},
          },
        },
      },
    },
    'components': {
      'schemas': {
        'Pet': {
          'type': 'object',
          'properties': {
            'name': {'type': 'string'},
          },
        },
      },
    },
  };
  late Directory root;
  final parsedSources = <String>[];
  setUp(() async {
    parsedSources.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'inspectOpenApi') return {'references': []};
          if (call.method == 'parseOpenApi') {
            parsedSources.add((call.arguments as Map)['source'] as String);
            return {
              'reference': {
                'title': 'Pets',
                'apiVersion': '1',
                'valid': true,
                'document': spec,
              },
            };
          }
          return null;
        });
    root = await Directory.systemTemp.createTemp('busymark-api-');
    await Directory(p.join(root.path, 'topics')).create();
    await Directory(p.join(root.path, 'specifications')).create();
    await File(p.join(root.path, 'writerside.cfg')).writeAsString(
      '<ihp><topics dir="topics"/><instance src="guide.tree"/></ihp>',
    );
    await File(p.join(root.path, 'guide.tree')).writeAsString(
      '<instance-profile id="guide" name="Guide"><toc-element topic="main.topic"/></instance-profile>',
    );
    await File(
      p.join(root.path, 'specifications/api.json'),
    ).writeAsString(jsonEncode(spec));
  });
  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await root.delete(recursive: true);
  });
  Future<(String, ResolvedWritersideDocument)> render(String markup) async {
    await File(
      p.join(root.path, 'topics/main.topic'),
    ).writeAsString('<topic id="main">$markup</topic>');
    final module = await const WritersideModuleService().load(root.path);
    final topic = module.topics.single;
    final resolved = const WritersideDocumentResolver().resolve(
      topic.document,
      WritersideResolveContext(module: module, topic: topic),
    );
    final busy = const WritersideDocumentRenderer().toBusyDocument(
      resolved.document,
    );
    String text(List<BusyBlock> blocks) => blocks
        .map((block) => '${block.plainText}\n${text(block.children)}')
        .join('\n');
    return (text(busy.blocks), resolved);
  }

  test(
    'API tags select operations through the existing OpenAPI parser',
    () async {
      final (text, resolved) = await render(
        '<api-doc openapi-path="api.json" tag="Pet"/>',
      );
      expect(parsedSources.single, jsonEncode(spec));
      expect(resolved.diagnostics, isEmpty);
      expect(text, contains('List pets'));
      expect(text, isNot(contains('Add users')));
    },
  );
  test(
    'API child selectors inherit the specification and preserve sample overrides',
    () async {
      final (text, resolved) = await render(
        '<api-doc openapi-path="api.json"><api-endpoint endpoint="/users" method="POST"><request><sample lang="json">custom request</sample></request></api-endpoint></api-doc>',
      );
      expect(resolved.diagnostics, isEmpty);
      expect(text, contains('Add users'));
      expect(text, contains('custom request'));
      expect(text, isNot(contains('List pets')));
    },
  );
  test('schema and webhook elements are visible', () async {
    final (text, resolved) = await render(
      '<api-schema openapi-path="api.json" name="Pet"/><api-webhook openapi-path="api.json" webhook="petAdded" method="POST"/>',
    );
    expect(resolved.diagnostics, isEmpty);
    expect(text, contains('name'));
    expect(text, contains('Pet added'));
  });
  test(
    'invalid API selection has a visible fallback and source diagnostic',
    () async {
      final (text, resolved) = await render(
        '<api-endpoint openapi-path="api.json" endpoint="/missing" method="GET"/>',
      );
      expect(text, contains('API reference unavailable'));
      expect(
        resolved.diagnostics.single.code,
        'writerside.api.invalid-selection',
      );
      expect(
        resolved.diagnostics.single.sourceSpan!.startOffset,
        '<topic id="main">'.length,
      );
    },
  );
}
