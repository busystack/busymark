import 'dart:io';

import 'package:busymark/src/core/busymark_exception.dart';
import 'package:busymark/src/writerside/writerside_module_service.dart';
import 'package:busymark/src/writerside/writerside_parsers.dart';
import 'package:busymark/src/writerside/writerside_project_creator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  const creator = WritersideProjectCreator();
  const moduleService = WritersideModuleService();
  const configParser = WritersideConfigParser();
  const treeParser = WritersideTreeParser();

  Future<Directory> tempParent() async {
    final directory = await Directory.systemTemp.createTemp(
      'busymark-writerside-create-',
    );
    addTearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });
    return directory;
  }

  test(
    'creates starter project scaffold and loads without diagnostics',
    () async {
      final parent = await tempParent();

      final result = await creator.create(
        WritersideProjectCreateRequest(
          parentDirectoryPath: parent.path,
          projectName: 'Docs',
          directoryName: 'docs',
          instanceName: 'User Guide',
          topicTitle: 'Getting started',
        ),
      );

      expect(Directory(result.rootPath).existsSync(), isTrue);
      expect(result.configPath, p.join(result.rootPath, 'writerside.cfg'));
      expect(result.treePath, p.join(result.rootPath, 'user-guide.tree'));
      expect(File(result.configPath).existsSync(), isTrue);
      expect(File(result.treePath).existsSync(), isTrue);
      expect(Directory(p.join(result.rootPath, 'topics')).existsSync(), isTrue);
      expect(Directory(p.join(result.rootPath, 'images')).existsSync(), isTrue);
      expect(Directory(p.join(result.rootPath, 'cfg')).existsSync(), isTrue);
      expect(
        File(
          p.join(result.rootPath, 'topics', 'getting-started.md'),
        ).existsSync(),
        isTrue,
      );

      final module = await moduleService.load(result.rootPath);

      expect(module.instances, hasLength(1));
      expect(module.instances.single.name, 'User Guide');
      expect(module.instances.single.startPage, 'getting-started.md');
      expect(module.topicsByFileName.keys, contains('getting-started.md'));
      expect(module.diagnostics, isEmpty);
    },
  );

  test(
    'creates starter project with Unicode directory and instance ID',
    () async {
      final parent = await tempParent();

      final result = await creator.create(
        WritersideProjectCreateRequest(
          parentDirectoryPath: parent.path,
          projectName: 'Документация API',
          directoryName: 'документация-api',
          instanceName: 'Руководство администратора',
          instanceId: 'руководство-администратора',
          topicTitle: 'Getting started',
        ),
      );

      expect(result.rootPath, p.join(parent.path, 'документация-api'));
      expect(
        result.treePath,
        p.join(result.rootPath, 'руководство-администратора.tree'),
      );
      expect(File(result.treePath).existsSync(), isTrue);

      final module = await moduleService.load(result.rootPath);

      expect(module.instances, hasLength(1));
      expect(module.instances.single.id, 'руководство-администратора');
      expect(module.instances.single.name, 'Руководство администратора');
      expect(module.diagnostics, isEmpty);
    },
  );

  test('escapes XML-sensitive project names in writerside.cfg', () async {
    final parent = await tempParent();
    final result = await creator.create(
      WritersideProjectCreateRequest(
        parentDirectoryPath: parent.path,
        projectName: 'A & B <Docs>',
        directoryName: 'xml-docs',
        instanceName: 'Guide "Main" & More',
        topicTitle: 'Getting started',
      ),
    );

    final config = configParser.parse(
      result.configPath,
      File(result.configPath).readAsStringSync(),
    );
    final tree = treeParser.parse(
      result.treePath,
      File(result.treePath).readAsStringSync(),
    );

    expect(config.moduleName, 'A & B <Docs>');
    expect(tree.name, 'Guide "Main" & More');
    expect(config.diagnostics, isEmpty);
    expect(tree.diagnostics, isEmpty);
  });

  test('sanitizes start topic title as plain Markdown heading text', () async {
    final parent = await tempParent();
    final titles = [
      '%product%',
      '[Bad](missing.md)',
      'Bad\n# Other',
      '<script>alert(1)</script>',
    ];

    for (final (index, title) in titles.indexed) {
      final result = await creator.create(
        WritersideProjectCreateRequest(
          parentDirectoryPath: parent.path,
          projectName: 'Docs $index',
          directoryName: 'docs-$index',
          instanceName: 'User Guide',
          topicTitle: title,
        ),
      );

      final source = File(
        p.join(result.rootPath, 'topics', 'getting-started.md'),
      ).readAsStringSync();
      final module = await moduleService.load(result.rootPath);

      expect(source, startsWith('# '));
      expect(
        module.diagnostics.map((item) => item.code),
        isNot(
          containsAll([
            'writerside.variable.unresolved',
            'markdown.link.unresolved-target',
            'markdown.image.missing-file',
            'markdown.raw-html.unsafe',
            'writerside.topic.h1-converted-to-chapter',
          ]),
        ),
      );
      expect(module.diagnostics, isEmpty);
    }
  });

  test(
    'rejects existing non-empty target directory and does not overwrite files',
    () async {
      final parent = await tempParent();
      final target = Directory(p.join(parent.path, 'docs'))..createSync();
      final existingConfig = File(p.join(target.path, 'writerside.cfg'))
        ..writeAsStringSync('existing config');

      await expectLater(
        creator.create(
          WritersideProjectCreateRequest(
            parentDirectoryPath: parent.path,
            projectName: 'Docs',
            directoryName: 'docs',
            instanceName: 'User Guide',
            topicTitle: 'Getting started',
          ),
        ),
        throwsA(isA<BusyMarkException>()),
      );

      expect(existingConfig.readAsStringSync(), 'existing config');
      expect(Directory(p.join(target.path, 'topics')).existsSync(), isFalse);
    },
  );

  test('rejects unsafe create request names before writing files', () async {
    final parent = await tempParent();

    for (final directoryName in [
      '../docs',
      '/tmp/docs',
      'docs/name',
      r'docs\name',
      '.',
      '..',
    ]) {
      await expectLater(
        creator.create(
          WritersideProjectCreateRequest(
            parentDirectoryPath: parent.path,
            projectName: 'Docs',
            directoryName: directoryName,
            instanceName: 'User Guide',
            topicTitle: 'Getting started',
          ),
        ),
        throwsA(anything),
      );
    }

    for (final topicFileName in ['../intro.md', 'intro.txt', '/tmp/intro.md']) {
      await expectLater(
        creator.create(
          WritersideProjectCreateRequest(
            parentDirectoryPath: parent.path,
            projectName: 'Docs',
            directoryName: 'safe-$topicFileName'.replaceAll(
              RegExp(r'[^a-z0-9_-]'),
              '-',
            ),
            instanceName: 'User Guide',
            topicTitle: 'Getting started',
            topicFileName: topicFileName,
          ),
        ),
        throwsA(anything),
      );
    }

    for (final instanceId in ['User Guide', '1guide', 'guide!']) {
      await expectLater(
        creator.create(
          WritersideProjectCreateRequest(
            parentDirectoryPath: parent.path,
            projectName: 'Docs',
            directoryName: 'safe-$instanceId'.replaceAll(
              RegExp(r'[^a-z0-9_-]'),
              '-',
            ),
            instanceName: 'User Guide',
            instanceId: instanceId,
            topicTitle: 'Getting started',
          ),
        ),
        throwsA(anything),
      );
    }

    expect(parent.listSync(), isEmpty);
  });
}
