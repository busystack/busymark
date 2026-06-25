import 'dart:io';

import 'package:busymark/src/writerside/writerside_module_service.dart';
import 'package:busymark/src/writerside/writerside_parsers.dart';
import 'package:busymark/src/writerside/writerside_project_creator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  const creator = WritersideProjectCreator();
  const moduleService = WritersideModuleService();
  const configParser = WritersideConfigParser();

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
        ),
      );

      expect(Directory(result.rootPath).existsSync(), isTrue);
      expect(
        File(p.join(result.rootPath, 'writerside.cfg')).existsSync(),
        isTrue,
      );
      expect(
        File(p.join(result.rootPath, 'user-guide.tree')).existsSync(),
        isTrue,
      );
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

  test('escapes XML-sensitive project names in writerside.cfg', () async {
    final parent = await tempParent();
    final result = await creator.create(
      WritersideProjectCreateRequest(
        parentDirectoryPath: parent.path,
        projectName: 'A & B <Docs>',
        directoryName: 'xml-docs',
      ),
    );
    final configPath = p.join(result.rootPath, 'writerside.cfg');

    final config = configParser.parse(
      configPath,
      File(configPath).readAsStringSync(),
    );

    expect(config.moduleName, 'A & B <Docs>');
    expect(config.diagnostics, isEmpty);
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
          ),
        ),
        throwsA(isA<FileSystemException>()),
      );

      expect(existingConfig.readAsStringSync(), 'existing config');
      expect(Directory(p.join(target.path, 'topics')).existsSync(), isFalse);
    },
  );
}
