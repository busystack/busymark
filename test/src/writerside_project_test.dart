import 'dart:io';
import 'dart:convert';

import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:busymark/src/workspace/workspace_service.dart';
import 'package:busymark/src/core/diagnostic.dart';
import 'package:busymark/src/editor/source/source_autocomplete.dart';
import 'package:busymark/src/editor/source/source_document.dart';
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

  test(
    'reparse overlays indexed symbols and preserves unrelated diagnostics',
    () async {
      final fixture = await _ProjectFixture.create();
      addTearDown(fixture.dispose);
      const service = WorkspaceService();
      final workspace = await service.openPath(fixture.path);
      final activePath = workspace.activeFilePath!;
      final unrelatedPath = p.join(
        fixture.path,
        'shared',
        'topics',
        'shared.topic',
      );

      expect(
        workspace.diagnostics.where(
          (diagnostic) =>
              diagnostic.code == 'writerside.index.unresolved-reference' &&
              p.equals(diagnostic.filePath, unrelatedPath),
        ),
        isNotEmpty,
      );
      expect(
        workspace.diagnostics.where(
          (diagnostic) =>
              diagnostic.code ==
                  'writerside.schema.missing-required-attribute' &&
              p.equals(diagnostic.filePath, activePath),
        ),
        isNotEmpty,
      );

      final reparsed = await service.reparseActive(workspace, '''
<topic id="renamed-main" title="Main">
  <include origin="shared-docs" from="shared.topic"
           element-id="shared-note"/>
  <snippet id="active-fixed"><p>Indexed while unsaved.</p></snippet>
</topic>
''');
      final project = reparsed.writersideProject!;
      final moduleId = project.activeModuleId;
      final topicNames = project.index.names(
        WritersideSymbolKind.topic,
        moduleId: moduleId,
      );
      final snippetNames = project.index.names(
        WritersideSymbolKind.snippet,
        moduleId: moduleId,
      );
      final completion = const SourceAutocompleteProvider().suggestions(
        document: SourceDocument(fullText: '<topic><a href="renamed-'),
        fullOffset: '<topic><a href="renamed-'.length,
        context: SourceAutocompleteContext(
          projectIndex: project.index,
          moduleId: moduleId,
        ),
      );

      expect(
        reparsed.writersideModule?.topicByReference('main.topic')?.id,
        'renamed-main',
      );
      expect(topicNames, contains('renamed-main'));
      expect(topicNames, isNot(contains('main')));
      expect(snippetNames, contains('active-fixed'));
      expect(
        completion.map((suggestion) => suggestion.insertText),
        contains('renamed-main'),
      );
      expect(
        reparsed.diagnostics.where(
          (diagnostic) =>
              diagnostic.code == 'writerside.index.unresolved-reference' &&
              p.equals(diagnostic.filePath, unrelatedPath),
        ),
        isNotEmpty,
      );
      expect(
        reparsed.diagnostics.where(
          (diagnostic) =>
              diagnostic.code ==
                  'writerside.schema.missing-required-attribute' &&
              p.equals(diagnostic.filePath, activePath),
        ),
        isEmpty,
      );
    },
  );

  test(
    'reparse of variables updates completion and resolution without reopening',
    () async {
      final fixture = await _ProjectFixture.create();
      addTearDown(fixture.dispose);
      final mainRoot = p.join(fixture.path, 'main');
      final configPath = p.join(mainRoot, 'writerside.cfg');
      final variablesPath = p.join(mainRoot, 'v.list');
      final topicPath = p.join(mainRoot, 'topics', 'main.topic');
      await File(configPath).writeAsString('''
<ihp version="2026.2">
  <module name="main-docs"/>
  <topics dir="topics"/>
  <images dir="images"/>
  <vars src="v.list"/>
  <instance src="guide.tree"/>
</ihp>
''');
      await File(
        variablesPath,
      ).writeAsString('<vars><var name="old-name" value="Old"/></vars>');
      await File(topicPath).writeAsString('''
<topic id="main" title="Main"><p>%live-name%</p></topic>
''');

      const service = WorkspaceService();
      final workspace = await service.openPath(fixture.path);
      final scanDiagnostic = Diagnostic(
        code: 'workspace.scan.skipped',
        severity: DiagnosticSeverity.warning,
        filePath: fixture.path,
      );
      final variableWorkspace = workspace.copyWith(
        activeFilePath: variablesPath,
        markdown: null,
        diagnostics: [...workspace.diagnostics, scanDiagnostic],
      );
      final reparsed = await service.reparseActive(
        variableWorkspace,
        '<vars><var name="live-name" value="Live value"/></vars>',
      );
      final project = reparsed.writersideProject!;
      final module = reparsed.writersideModule!;
      final suggestions = const SourceAutocompleteProvider().suggestions(
        document: SourceDocument(fullText: 'live'),
        fullOffset: 'live'.length,
        context: SourceAutocompleteContext(
          projectIndex: project.index,
          moduleId: project.activeModuleId,
        ),
      );
      final topic = module.topicByReference('main.topic')!;
      final resolved = const WritersideDocumentResolver().resolve(
        topic.document,
        WritersideResolveContext(
          module: module,
          topic: topic,
          instance: project.activeInstance,
          modulesByOrigin: project.modulesByOrigin,
        ),
      );
      final rendered = const WritersideDocumentRenderer().toBusyDocument(
        resolved.document,
        title: resolved.title,
      );

      expect(module.variables.map((variable) => variable.name), ['live-name']);
      expect(
        project.index.names(
          WritersideSymbolKind.variable,
          moduleId: project.activeModuleId,
        ),
        contains('live-name'),
      );
      expect(
        project.index.names(
          WritersideSymbolKind.variable,
          moduleId: project.activeModuleId,
        ),
        isNot(contains('old-name')),
      );
      expect(
        suggestions
            .where(
              (suggestion) =>
                  suggestion.kind == SourceAutocompleteKind.variable,
            )
            .map((suggestion) => suggestion.insertText),
        contains('live-name'),
      );
      expect(
        resolved.diagnostics.map((diagnostic) => diagnostic.code),
        isNot(contains('writerside.variable.unresolved')),
      );
      expect(
        _walkBlocks(rendered.blocks).map((block) => block.plainText).join('\n'),
        contains('Live value'),
      );
      expect(reparsed.diagnostics, contains(scanDiagnostic));
    },
  );

  test('reparse of an instance tree updates active project context', () async {
    final fixture = await _ProjectFixture.create();
    addTearDown(fixture.dispose);
    const service = WorkspaceService();
    final workspace = await service.openPath(fixture.path);
    final treePath = p.join(fixture.path, 'main', 'guide.tree');
    final unrelatedPath = p.join(
      fixture.path,
      'shared',
      'topics',
      'shared.topic',
    );
    final treeWorkspace = workspace.copyWith(
      activeFilePath: treePath,
      markdown: null,
    );

    final reparsed = await service.reparseActive(treeWorkspace, '''
<instance-profile id="live-guide" name="Live Guide"
                  start-page="main.topic">
  <toc-element topic="main.topic"/>
</instance-profile>
''');
    final project = reparsed.writersideProject!;

    expect(reparsed.writersideModule?.instances.single.id, 'live-guide');
    expect(reparsed.writersideModule?.instances.single.name, 'Live Guide');
    expect(project.activeInstanceId, 'live-guide');
    expect(project.activeInstance?.id, 'live-guide');
    expect(
      project.index.names(
        WritersideSymbolKind.instance,
        moduleId: project.activeModuleId,
      ),
      contains('live-guide'),
    );
    expect(
      project.index.names(
        WritersideSymbolKind.instance,
        moduleId: project.activeModuleId,
      ),
      isNot(contains('guide')),
    );
    expect(
      reparsed.diagnostics.where(
        (diagnostic) =>
            diagnostic.code == 'writerside.index.unresolved-reference' &&
            p.equals(diagnostic.filePath, unrelatedPath),
      ),
      isNotEmpty,
    );
  });

  test(
    'BusyMark matches the official builder semantic snapshot for the fixture',
    () async {
      final root = p.absolute('test/fixtures/writerside/conformance_project');
      final expected =
          jsonDecode(
                await File(
                  'test/fixtures/writerside/conformance_semantics.json',
                ).readAsString(),
              )
              as Map;
      final project = await const WritersideProjectService().load(root);
      String normalized(String text) =>
          text.replaceAll(RegExp(r'\s+'), ' ').trim();
      Iterable<BusyInline> inlines(Iterable<BusyInline> values) sync* {
        for (final value in values) {
          yield value;
          yield* inlines(value.children);
        }
      }

      for (final topic in project.activeModule!.topics) {
        final resolved = const WritersideDocumentResolver().resolve(
          topic.document,
          WritersideResolveContext(
            module: project.activeModule!,
            topic: topic,
            instance: project.activeInstance,
          ),
        );
        final document = const WritersideDocumentRenderer().toBusyDocument(
          resolved.document,
        );
        final blocks = _walkBlocks(document.blocks).toList();
        final spans = blocks.expand((block) => inlines(block.inlines)).toList();
        final actual = {
          'paragraphs': document.blocks
              .where((block) => block.kind == BusyBlockKind.paragraph)
              .map((block) => normalized(block.plainText))
              .toList(),
          'quotes': blocks
              .where((block) => block.attributes['style'] == 'quote')
              .map((block) => normalized(block.plainText))
              .toList(),
          'shortcuts': spans
              .where((inline) => inline.attributes['element'] == 'shortcut')
              .map((inline) => inline.text)
              .toList(),
          'tooltips': [
            for (final inline in spans.where(
              (inline) => inline.attributes['element'] == 'tooltip',
            ))
              {
                'text': inline.plainText,
                'summary': inline.attributes['summary'],
              },
          ],
          'tables': [
            for (final table in blocks.where(
              (block) => block.attributes['element'] == 'table',
            ))
              [
                for (final row in table.children)
                  [
                    for (final cell in row.children)
                      {
                        'text': normalized(cell.plainText),
                        'header': cell.attributes['header'] == 'true',
                        'colspan':
                            int.tryParse(cell.attributes['colspan'] ?? '') ?? 1,
                        'rowspan':
                            int.tryParse(cell.attributes['rowspan'] ?? '') ?? 1,
                      },
                  ],
              ],
          ],
          'seealso': [
            for (final category in blocks.where(
              (block) => block.attributes['element'] == 'category',
            ))
              {
                'title': category.attributes['title'],
                'links': [
                  for (final inline
                      in _walkBlocks(category.children)
                          .expand((block) => inlines(block.inlines))
                          .where(
                            (inline) => inline.kind == BusyInlineKind.link,
                          ))
                    {
                      'title': inline.plainText,
                      'topic': p.basenameWithoutExtension(inline.destination!),
                    },
                ],
              },
          ],
        };
        expect(actual, expected['topics'][topic.id], reason: topic.filePath);
      }
    },
  );

  test(
    'conformance fixture preserves source and resolves semantic content',
    () async {
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
    },
  );
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
  <snippet><p>Missing ID before reparse.</p></snippet>
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
  <snippet id="unrelated-diagnostic">
    <include from="missing.topic" element-id="missing-snippet"/>
  </snippet>
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
