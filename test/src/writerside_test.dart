import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:busymark/src/writerside/writerside_module_service.dart';
import 'package:busymark/src/writerside/writerside_parsers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const configParser = WritersideConfigParser();
  const treeParser = WritersideTreeParser();
  const moduleService = WritersideModuleService();

  test('parses writerside.cfg directories and registered instances', () {
    final path = 'test/fixtures/writerside/basic_project/writerside.cfg';
    final config = configParser.parse(path, File(path).readAsStringSync());

    expect(config.topicsDir, 'topics');
    expect(config.imagesDir, 'images');
    expect(config.varsFile, 'v.list');
    expect(config.categoriesFile, 'c.list');
    expect(config.instanceSources, contains('user-guide.tree'));
  });

  test('parses .tree metadata and TOC hierarchy', () {
    final path = 'test/fixtures/writerside/basic_project/user-guide.tree';
    final instance = treeParser.parse(path, File(path).readAsStringSync());

    expect(instance.id, 'user-guide');
    expect(instance.name, 'User Guide');
    expect(instance.startPage, 'intro.md');
    expect(instance.topicFileSet, containsAll(['intro.md', 'install.topic']));
  });

  test(
    'loads basic Writerside project with topics and no missing topic diagnostics',
    () async {
      final module = await moduleService.load(
        'test/fixtures/writerside/basic_project',
      );

      expect(module.instances.single.name, 'User Guide');
      expect(
        module.topicsByFileName.keys,
        containsAll(['intro.md', 'install.topic']),
      );
      expect(module.variables.single.name, 'product');
      expect(module.categories.single.id, 'getting-started');
      expect(
        module.diagnostics.map((item) => item.code),
        isNot(contains('writerside.tree.missing-topic')),
      );
    },
  );

  test(
    'broken Writerside project produces deterministic diagnostics',
    () async {
      final module = await moduleService.load(
        'test/fixtures/writerside/broken_project',
      );
      final codes = module.diagnostics.map((item) => item.code).toSet();

      expect(
        codes,
        containsAll([
          'writerside.config.missing-instance-tree',
          'writerside.tree.missing-start-page',
          'writerside.tree.duplicate-topic',
          'writerside.tree.missing-topic',
          'writerside.topic.missing-title',
          'markdown.image.missing-file',
          'writerside.variable.unresolved',
          'writerside.include.unresolved-source',
          'writerside.topic.root-id-mismatch',
          'writerside.topic.duplicate-element-id',
        ]),
      );
    },
  );

  test(
    'resolves basename images in nested Writerside image directories',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'busymark-writerside-',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      Directory(p.join(root.path, 'topics')).createSync();
      Directory(
        p.join(root.path, 'images', 'methodology', 'orchestrator-devices'),
      ).createSync(recursive: true);
      File(p.join(root.path, 'writerside.cfg')).writeAsStringSync('''
<ihp version="2.0">
  <topics dir="topics"/>
  <images dir="images"/>
  <instance src="srs.tree"/>
</ihp>
''');
      File(p.join(root.path, 'srs.tree')).writeAsStringSync('''
<instance-profile id="srs" name="SRS" start-page="CHIP-Tool.md">
  <toc-element topic="CHIP-Tool.md"/>
</instance-profile>
''');
      File(p.join(root.path, 'topics', 'CHIP-Tool.md')).writeAsStringSync('''
# CHIP-Tool

![Alt Text](rpi_1.jpg){thumbnail="true" width="500"}
''');
      File(
        p.join(
          root.path,
          'images',
          'methodology',
          'orchestrator-devices',
          'rpi_1.jpg',
        ),
      ).writeAsBytesSync([0]);

      final module = await moduleService.load(root.path);

      expect(
        module.diagnostics.map((item) => item.code),
        isNot(contains('markdown.image.missing-file')),
      );
    },
  );
}
