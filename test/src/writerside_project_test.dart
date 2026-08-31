import 'dart:io';

import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:busymark/src/workspace/workspace_service.dart';
import 'package:busymark/src/core/diagnostic.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/writerside/writerside_document_renderer.dart';
import 'package:busymark/src/writerside/writerside_document_resolver.dart';
import 'package:busymark/src/writerside/writerside_document_serializer.dart';
import 'package:busymark/src/writerside/writerside_project.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test(
    'discovers modules, indexes symbols, and resolves origin references',
    () async {
      final fixture = await _ProjectFixture.create();
      addTearDown(fixture.dispose);
      final project = await const WritersideProjectService().load(fixture.path);

      expect(project.modules, hasLength(2));
      expect(
        project.modulesByOrigin.keys,
        containsAll(['main-docs', 'shared-docs']),
      );
      expect(
        project.index.names(WritersideSymbolKind.snippet),
        contains('shared-note'),
      );
      expect(
        project.index.names(WritersideSymbolKind.image),
        contains('logo.svg'),
      );
      expect(
        project.index.names(WritersideSymbolKind.resource),
        contains('sample.json'),
      );
      expect(
        project.index.names(WritersideSymbolKind.apiSpecification),
        contains('service.yaml'),
      );
      final snippet = project.index.symbols.singleWhere(
        (symbol) =>
            symbol.kind == WritersideSymbolKind.snippet &&
            symbol.name == 'shared-note',
      );
      final rename = project.index.safeRenameEdits(snippet, 'renamed-note');
      expect(rename, hasLength(2));
      expect(
        rename.map((edit) => edit.replacement),
        everyElement('renamed-note'),
      );

      final main = project.modulesByOrigin['main-docs']!;
      final topic = main.topicByReference('main.topic')!;
      final resolved = const WritersideDocumentResolver().resolve(
        topic.document,
        WritersideResolveContext(
          module: main,
          topic: topic,
          instance: main.instances.single,
          modulesByOrigin: project.modulesByOrigin,
        ),
      );
      final rendered = const WritersideDocumentRenderer().toBusyDocument(
        resolved.document,
        title: resolved.title,
      );
      expect(
        rendered.blocks.map((block) => block.plainText).join('\n'),
        contains('Shared module content'),
      );
    },
  );

  test(
    'workspace promotes a parent directory to a multi-module project',
    () async {
      final fixture = await _ProjectFixture.create();
      addTearDown(fixture.dispose);

      final workspace = await const WorkspaceService().openPath(fixture.path);

      expect(workspace.kind, WorkspaceKind.writersideModule);
      expect(workspace.writersideProject?.modules, hasLength(2));
      expect(workspace.writersideModule, isNotNull);
    },
  );

  test(
    'workspace module and instance selection changes active context',
    () async {
      final fixture = await _ProjectFixture.create();
      addTearDown(fixture.dispose);
      const service = WorkspaceService();
      final workspace = await service.openPath(fixture.path);

      final selected = await service.selectWritersideContext(
        workspace,
        moduleId: 'shared-docs',
        instanceId: 'guide',
      );

      expect(selected.writersideProject?.activeModuleId, 'shared-docs');
      expect(selected.writersideProject?.activeInstanceId, 'guide');
      expect(selected.writersideModule?.config.moduleName, 'shared-docs');
      expect(selected.activeFilePath, endsWith('shared.topic'));
    },
  );

  test('BusyMark processes the same fixture as the official builder', () async {
    final root = p.join(
      Directory.current.path,
      'test',
      'fixtures',
      'writerside',
      'conformance_project',
    );
    final project = await const WritersideProjectService().load(root);
    final module = project.activeModule!;
    final instance = project.activeInstance!;
    final renderedText = StringBuffer();
    final diagnostics = <Diagnostic>[];

    for (final topic in module.topics) {
      expect(
        const WritersideDocumentSerializer().serialize(topic.document),
        topic.document.source,
      );
      final resolved = const WritersideDocumentResolver().resolve(
        topic.document,
        WritersideResolveContext(
          module: module,
          topic: topic,
          instance: instance,
          modulesByOrigin: project.modulesByOrigin,
        ),
      );
      diagnostics.addAll(resolved.diagnostics);
      final rendered = const WritersideDocumentRenderer().toBusyDocument(
        resolved.document,
        title: resolved.title,
      );
      for (final block in _walkBlocks(rendered.blocks)) {
        renderedText.writeln(block.plainText);
      }
    }

    expect(
      diagnostics.where(
        (diagnostic) => diagnostic.severity == DiagnosticSeverity.error,
      ),
      isEmpty,
    );
    expect(renderedText.toString(), contains('Lossless semantic quote'));
    expect(renderedText.toString(), contains('Reusable semantic content'));
    expect(renderedText.toString(), contains('BusyMark'));
  });
}

Iterable<BusyBlock> _walkBlocks(Iterable<BusyBlock> blocks) sync* {
  for (final block in blocks) {
    yield block;
    yield* _walkBlocks(block.children);
  }
}

class _ProjectFixture {
  const _ProjectFixture(this.directory);

  final Directory directory;
  String get path => directory.path;

  static Future<_ProjectFixture> create() async {
    final root = await Directory.systemTemp.createTemp(
      'busymark-writerside-project-',
    );
    await _writeModule(
      root: root,
      directoryName: 'main',
      moduleName: 'main-docs',
      topicName: 'main.topic',
      topic: '''
<topic id="main" title="Main">
  <include origin="shared-docs" from="shared.topic"
           element-id="shared-note"/>
</topic>
''',
    );
    await _writeModule(
      root: root,
      directoryName: 'shared',
      moduleName: 'shared-docs',
      topicName: 'shared.topic',
      topic: '''
<topic id="shared" title="Shared">
  <snippet id="shared-note"><note>Shared module content</note></snippet>
</topic>
''',
    );
    return _ProjectFixture(root);
  }

  static Future<void> _writeModule({
    required Directory root,
    required String directoryName,
    required String moduleName,
    required String topicName,
    required String topic,
  }) async {
    final module = await Directory(p.join(root.path, directoryName)).create();
    final topics = await Directory(p.join(module.path, 'topics')).create();
    final images = await Directory(p.join(module.path, 'images')).create();
    final resources = await Directory(
      p.join(module.path, 'resources'),
    ).create();
    final specifications = await Directory(
      p.join(module.path, 'specifications'),
    ).create();
    await File(p.join(module.path, 'writerside.cfg')).writeAsString('''
<ihp version="2026.2">
  <module name="$moduleName"/>
  <topics dir="topics"/>
  <images dir="images"/>
  <resources dir="resources"/>
  <api-specifications dir="specifications"/>
  <instance src="guide.tree"/>
</ihp>
''');
    await File(p.join(module.path, 'guide.tree')).writeAsString('''
<instance-profile id="guide" name="Guide" start-page="$topicName">
  <toc-element topic="$topicName"/>
</instance-profile>
''');
    await File(p.join(topics.path, topicName)).writeAsString(topic);
    await File(p.join(images.path, 'logo.svg')).writeAsString('<svg/>');
    await File(p.join(resources.path, 'sample.json')).writeAsString('{}');
    await File(
      p.join(specifications.path, 'service.yaml'),
    ).writeAsString('openapi: 3.1.0\n');
  }

  Future<void> dispose() => directory.delete(recursive: true);
}
