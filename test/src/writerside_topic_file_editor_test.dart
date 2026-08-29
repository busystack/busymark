import 'dart:io';

import 'package:busymark/src/core/busymark_exception.dart';
import 'package:busymark/src/writerside/writerside_model.dart';
import 'package:busymark/src/writerside/writerside_module_service.dart';
import 'package:busymark/src/writerside/writerside_topic_file_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

void main() {
  const editor = WritersideTopicFileEditor();

  test(
    'rename updates topic and start-page references in every tree',
    () async {
      final fixture = await _fixture(
        trees: {
          'guide.tree': '''
<instance-profile id="guide" name="Guide" start-page="guide.md">
  <toc-element topic="guide.md"/>
</instance-profile>
''',
          'admin.tree': '''
<instance-profile id="admin" name="Admin" start-page="other.md">
  <toc-element topic="guide.md"/>
  <toc-element topic="other.md"/>
</instance-profile>
''',
        },
        topics: {'guide.md': '# Guide\n\nBody.\n', 'other.md': '# Other\n'},
      );
      final topic = _topic(fixture.module, 'guide.md');

      final result = await editor.rename(
        module: fixture.module,
        topic: topic,
        newFileName: 'renamed.md',
      );

      expect(File(topic.filePath).existsSync(), isFalse);
      expect(
        File(result.newTopicPath).readAsStringSync(),
        '# Guide\n\nBody.\n',
      );
      expect(result.newTopicFileName, 'renamed.md');
      expect(result.updatedTreePaths, hasLength(2));
      final guideTree = _tree(fixture.root, 'guide.tree');
      final adminTree = _tree(fixture.root, 'admin.tree');
      expect(guideTree.rootElement.getAttribute('start-page'), 'renamed.md');
      expect(_allTopicReferences(guideTree), ['renamed.md']);
      expect(adminTree.rootElement.getAttribute('start-page'), 'other.md');
      expect(_allTopicReferences(adminTree), ['renamed.md', 'other.md']);

      final reloaded = await const WritersideModuleService().load(
        fixture.root.path,
      );
      expect(reloaded.topicByReference('renamed.md')?.title, 'Guide');
      expect(
        reloaded.diagnostics.map((diagnostic) => diagnostic.code),
        isNot(
          anyOf(
            contains('writerside.tree.missing-topic'),
            contains('writerside.tree.missing-start-page'),
          ),
        ),
      );
    },
  );

  test('rename updates a matching XML topic root id', () async {
    final fixture = await _fixture(
      trees: {
        'guide.tree': '''
<instance-profile id="guide" name="Guide" start-page="intro.md">
  <toc-element topic="intro.md"/>
  <toc-element topic="install.topic"/>
</instance-profile>
''',
      },
      topics: {
        'intro.md': '# Intro\n',
        'install.topic': '''
<topic title="Install" id="install">
  <p>Install it.</p>
</topic>
''',
      },
    );
    final topic = _topic(fixture.module, 'install.topic');

    final result = await editor.rename(
      module: fixture.module,
      topic: topic,
      newFileName: 'setup.topic',
    );

    final renamed = XmlDocument.parse(
      File(result.newTopicPath).readAsStringSync(),
    );
    expect(result.updatedXmlTopicId, isTrue);
    expect(renamed.rootElement.getAttribute('id'), 'setup');
    expect(_allTopicReferences(_tree(fixture.root, 'guide.tree')), [
      'intro.md',
      'setup.topic',
    ]);
  });

  test('rename supports Writerside .markdown topics', () async {
    final fixture = await _fixture(
      trees: {
        'guide.tree': '''
<instance-profile id="guide" name="Guide" start-page="guide.markdown">
  <toc-element topic="guide.markdown"/>
</instance-profile>
''',
      },
      topics: {'guide.markdown': '# Guide\n'},
    );
    final topic = _topic(fixture.module, 'guide.markdown');

    final result = await editor.rename(
      module: fixture.module,
      topic: topic,
      newFileName: 'renamed.markdown',
    );

    expect(File(topic.filePath).existsSync(), isFalse);
    expect(File(result.newTopicPath).readAsStringSync(), '# Guide\n');
    expect(
      _tree(fixture.root, 'guide.tree').rootElement.getAttribute('start-page'),
      'renamed.markdown',
    );
    expect(_allTopicReferences(_tree(fixture.root, 'guide.tree')), [
      'renamed.markdown',
    ]);
  });

  test('rename rejects duplicate targets and extension changes', () async {
    final fixture = await _fixture(
      trees: {
        'guide.tree': '''
<instance-profile id="guide" name="Guide" start-page="guide.md">
  <toc-element topic="guide.md"/>
  <toc-element topic="taken.md"/>
  <toc-element topic="nested/setup.md"/>
</instance-profile>
''',
      },
      topics: {
        'guide.md': '# Guide\n',
        'taken.md': '# Taken\n',
        'nested/setup.md': '# Setup\n',
      },
    );
    final topic = _topic(fixture.module, 'guide.md');
    final originalTree = File(
      p.join(fixture.root.path, 'guide.tree'),
    ).readAsStringSync();

    await expectLater(
      editor.rename(
        module: fixture.module,
        topic: topic,
        newFileName: 'taken.md',
      ),
      throwsA(
        isA<BusyMarkException>().having(
          (error) => error.code,
          'code',
          'writerside.topic-file.target-exists',
        ),
      ),
    );
    await expectLater(
      editor.rename(
        module: fixture.module,
        topic: topic,
        newFileName: 'guide.topic',
      ),
      throwsA(
        isA<BusyMarkException>().having(
          (error) => error.code,
          'code',
          'writerside.topic-file.file-extension-mismatch',
        ),
      ),
    );
    await expectLater(
      editor.rename(
        module: fixture.module,
        topic: topic,
        newFileName: 'setup.md',
      ),
      throwsA(
        isA<BusyMarkException>().having(
          (error) => error.code,
          'code',
          'writerside.topic-file.duplicate-target',
        ),
      ),
    );

    expect(File(topic.filePath).existsSync(), isTrue);
    expect(
      File(p.join(fixture.root.path, 'guide.tree')).readAsStringSync(),
      originalTree,
    );
  });

  test(
    'rename preserves a target created concurrently before exclusive create',
    () async {
      final fixture = await _fixture(
        trees: {
          'guide.tree': '''
<instance-profile id="guide" name="Guide" start-page="guide.md">
  <toc-element topic="guide.md"/>
</instance-profile>
''',
        },
        topics: {'guide.md': '# Guide\n'},
      );
      final topic = _topic(fixture.module, 'guide.md');
      final treeFile = File(p.join(fixture.root.path, 'guide.tree'));
      final originalTree = treeFile.readAsStringSync();
      final target = File(p.join(fixture.root.path, 'topics', 'renamed.md'));
      final raceEditor = WritersideTopicFileEditor(
        beforeNewFileCreate: (targetPath) async {
          expect(targetPath, target.path);
          await File(targetPath).writeAsString('concurrent contents\n');
        },
      );

      await expectLater(
        raceEditor.rename(
          module: fixture.module,
          topic: topic,
          newFileName: 'renamed.md',
        ),
        throwsA(isA<FileSystemException>()),
      );

      expect(target.readAsStringSync(), 'concurrent contents\n');
      expect(File(topic.filePath).readAsStringSync(), '# Guide\n');
      expect(treeFile.readAsStringSync(), originalTree);
    },
  );

  test(
    'delete reloads newly configured instances before start-page checks',
    () async {
      final fixture = await _fixture(
        trees: {
          'guide.tree': '''
<instance-profile id="guide" name="Guide" start-page="other.md">
  <toc-element topic="guide.md"/>
  <toc-element topic="other.md"/>
</instance-profile>
''',
        },
        topics: {'guide.md': '# Guide\n', 'other.md': '# Other\n'},
      );
      final staleTopic = _topic(fixture.module, 'guide.md');
      File(p.join(fixture.root.path, 'admin.tree')).writeAsStringSync('''
<instance-profile id="admin" name="Admin" start-page="guide.md">
  <toc-element topic="guide.md"/>
</instance-profile>
''');
      File(p.join(fixture.root.path, 'writerside.cfg')).writeAsStringSync('''
<ihp version="2.0">
  <topics dir="topics"/>
  <instance src="guide.tree"/>
  <instance src="admin.tree"/>
</ihp>
''');

      await expectLater(
        editor.delete(module: fixture.module, topic: staleTopic),
        throwsA(
          isA<BusyMarkException>().having(
            (error) => error.code,
            'code',
            'writerside.topic-file.is-start-page',
          ),
        ),
      );

      expect(File(staleTopic.filePath).existsSync(), isTrue);
      expect(
        File(p.join(fixture.root.path, 'admin.tree')).readAsStringSync(),
        contains('topic="guide.md"'),
      );
    },
  );

  test('rename does not claim a new same-basename nested reference', () async {
    final fixture = await _fixture(
      trees: {
        'guide.tree': '''
<instance-profile id="guide" name="Guide" start-page="other.md">
  <toc-element topic="guide.md"/>
  <toc-element topic="other.md"/>
</instance-profile>
''',
      },
      topics: {'guide.md': '# Guide\n', 'other.md': '# Other\n'},
    );
    final staleTopic = _topic(fixture.module, 'guide.md');
    final nestedTopic = File(
      p.join(fixture.root.path, 'topics', 'nested', 'guide.md'),
    );
    nestedTopic.parent.createSync(recursive: true);
    nestedTopic.writeAsStringSync('# Nested guide\n');
    File(p.join(fixture.root.path, 'guide.tree')).writeAsStringSync('''
<instance-profile id="guide" name="Guide" start-page="other.md">
  <toc-element topic="nested/guide.md"/>
  <toc-element topic="other.md"/>
</instance-profile>
''');

    await editor.rename(
      module: fixture.module,
      topic: staleTopic,
      newFileName: 'renamed.md',
    );

    expect(
      File(p.join(fixture.root.path, 'guide.tree')).readAsStringSync(),
      contains('topic="nested/guide.md"'),
    );
    expect(nestedTopic.readAsStringSync(), '# Nested guide\n');
    expect(
      File(p.join(fixture.root.path, 'topics', 'renamed.md')).existsSync(),
      isTrue,
    );
  });

  test(
    'rename aborts when a concurrent topic changes basename resolution',
    () async {
      final fixture = await _fixture(
        trees: {
          'guide.tree': '''
<instance-profile id="guide" name="Guide" start-page="other.md">
  <toc-element topic="guide.md"/>
  <toc-element topic="other.md"/>
</instance-profile>
''',
        },
        topics: {
          'nested/guide.md': '# Nested guide\n',
          'other.md': '# Other\n',
        },
      );
      final topic = _topic(fixture.module, 'nested/guide.md');
      final tree = File(p.join(fixture.root.path, 'guide.tree'));
      final originalTree = tree.readAsStringSync();
      final concurrentTopic = File(
        p.join(fixture.root.path, 'topics', 'guide.md'),
      );
      final target = File(
        p.join(fixture.root.path, 'topics', 'nested', 'renamed.md'),
      );
      final racingEditor = WritersideTopicFileEditor(
        beforeNewFileCreate: (_) async {
          await concurrentTopic.writeAsString('# Concurrent guide\n');
        },
      );

      await expectLater(
        racingEditor.rename(
          module: fixture.module,
          topic: topic,
          newFileName: 'renamed.md',
        ),
        throwsA(
          isA<BusyMarkException>().having(
            (error) => error.code,
            'code',
            'writerside.topic-file.topic-inventory-changed',
          ),
        ),
      );

      expect(tree.readAsStringSync(), originalTree);
      expect(File(topic.filePath).readAsStringSync(), '# Nested guide\n');
      expect(concurrentTopic.readAsStringSync(), '# Concurrent guide\n');
      expect(target.readAsStringSync(), '# Nested guide\n');
    },
  );

  test(
    'delete aborts when a concurrent topic changes basename resolution',
    () async {
      final fixture = await _fixture(
        trees: {
          'guide.tree': '''
<instance-profile id="guide" name="Guide" start-page="other.md">
  <toc-element topic="guide.md"/>
  <toc-element topic="other.md"/>
</instance-profile>
''',
        },
        topics: {
          'nested/guide.md': '# Nested guide\n',
          'other.md': '# Other\n',
        },
      );
      final topic = _topic(fixture.module, 'nested/guide.md');
      final tree = File(p.join(fixture.root.path, 'guide.tree'));
      final originalTree = tree.readAsStringSync();
      final concurrentTopic = File(
        p.join(fixture.root.path, 'topics', 'guide.md'),
      );
      var inserted = false;
      final racingEditor = WritersideTopicFileEditor(
        beforeTreePublish: (_) async {
          if (!inserted) {
            inserted = true;
            await concurrentTopic.writeAsString('# Concurrent guide\n');
          }
        },
      );

      await expectLater(
        racingEditor.delete(module: fixture.module, topic: topic),
        throwsA(
          isA<BusyMarkException>().having(
            (error) => error.code,
            'code',
            'writerside.topic-file.topic-inventory-changed',
          ),
        ),
      );

      expect(tree.readAsStringSync(), originalTree);
      expect(File(topic.filePath).readAsStringSync(), '# Nested guide\n');
      expect(concurrentTopic.readAsStringSync(), '# Concurrent guide\n');
    },
  );

  test(
    'rename retains target when an applied tree cannot be rolled back',
    () async {
      final fixture = await _fixture(
        trees: {
          'guide.tree': '''
<instance-profile id="guide" name="Guide" start-page="guide.md">
  <toc-element topic="guide.md"/>
</instance-profile>
''',
          'admin.tree': '''
<instance-profile id="admin" name="Admin" start-page="other.md">
  <toc-element topic="guide.md"/>
  <toc-element topic="other.md"/>
</instance-profile>
''',
        },
        topics: {'guide.md': '# Guide\n', 'other.md': '# Other\n'},
      );
      final topic = _topic(fixture.module, 'guide.md');
      var publishCount = 0;
      final racingEditor = WritersideTopicFileEditor(
        beforeTreePublish: (treePath) async {
          publishCount += 1;
          if (publishCount == 2) {
            final file = File(treePath);
            await file.writeAsString(
              '${await file.readAsString()}<!-- second tree changed -->\n',
              flush: true,
            );
          } else if (publishCount == 3) {
            final file = File(treePath);
            await file.writeAsString(
              '${await file.readAsString()}<!-- rollback blocked -->\n',
              flush: true,
            );
          }
        },
      );

      await expectLater(
        racingEditor.rename(
          module: fixture.module,
          topic: topic,
          newFileName: 'renamed.md',
        ),
        throwsA(isA<BusyMarkException>()),
      );

      final renamed = File(p.join(fixture.root.path, 'topics', 'renamed.md'));
      expect(File(topic.filePath).existsSync(), isTrue);
      expect(renamed.readAsStringSync(), '# Guide\n');
      expect(
        File(p.join(fixture.root.path, 'guide.tree')).readAsStringSync(),
        allOf(contains('topic="renamed.md"'), contains('rollback blocked')),
      );
    },
  );

  test(
    'rename preserves topic and instance tree file modes',
    () async {
      final fixture = await _fixture(
        trees: {
          'guide.tree': '''
<instance-profile id="guide" name="Guide" start-page="guide.md">
  <toc-element topic="guide.md"/>
</instance-profile>
''',
        },
        topics: {'guide.md': '# Guide\n'},
      );
      final topic = _topic(fixture.module, 'guide.md');
      final treeFile = File(p.join(fixture.root.path, 'guide.tree'));
      final treeChmod = await Process.run('chmod', ['640', treeFile.path]);
      expect(treeChmod.exitCode, 0, reason: '${treeChmod.stderr}');
      final topicChmod = await Process.run('chmod', ['600', topic.filePath]);
      expect(topicChmod.exitCode, 0, reason: '${topicChmod.stderr}');

      await editor.rename(
        module: fixture.module,
        topic: topic,
        newFileName: 'renamed.md',
      );

      expect((await treeFile.stat()).mode & 0xfff, 0x1a0);
      final renamed = File(p.join(fixture.root.path, 'topics', 'renamed.md'));
      expect((await renamed.stat()).mode & 0xfff, 0x180);
    },
    skip: Platform.isWindows ? 'POSIX file modes only.' : false,
  );

  test(
    'delete removes every TOC entry and promotes children in place',
    () async {
      final fixture = await _fixture(
        trees: {
          'guide.tree': '''
<instance-profile id="guide" name="Guide" start-page="parent.md">
  <toc-element topic="parent.md">
    <toc-element topic="doomed.md">
      <toc-element topic="child-a.md"/>
      <toc-element topic="child-b.md"/>
    </toc-element>
    <toc-element topic="after.md"/>
  </toc-element>
</instance-profile>
''',
          'admin.tree': '''
<instance-profile id="admin" name="Admin" start-page="other.md">
  <toc-element topic="doomed.md">
    <toc-element topic="child-b.md"/>
  </toc-element>
  <toc-element topic="other.md"/>
</instance-profile>
''',
        },
        topics: {
          'parent.md': '# Parent\n',
          'doomed.md': '# Doomed\n',
          'child-a.md': '# Child A\n',
          'child-b.md': '# Child B\n',
          'after.md': '# After\n',
          'other.md': '# Other\n',
        },
      );
      final topic = _topic(fixture.module, 'doomed.md');

      final result = await editor.delete(module: fixture.module, topic: topic);

      expect(File(topic.filePath).existsSync(), isFalse);
      expect(result.removedTocEntries, 2);
      expect(result.updatedTreePaths, hasLength(2));
      final guideTree = _tree(fixture.root, 'guide.tree');
      final parent = guideTree
          .findAllElements('toc-element')
          .singleWhere(
            (element) => element.getAttribute('topic') == 'parent.md',
          );
      expect(_directTopicReferences(parent), [
        'child-a.md',
        'child-b.md',
        'after.md',
      ]);
      expect(
        _directTopicReferences(_tree(fixture.root, 'admin.tree').rootElement),
        ['child-b.md', 'other.md'],
      );
      expect(_allTopicReferences(guideTree), isNot(contains('doomed.md')));
    },
  );

  test('delete rejects a topic used as any instance start page', () async {
    final fixture = await _fixture(
      trees: {
        'guide.tree': '''
<instance-profile id="guide" name="Guide" start-page="other.md">
  <toc-element topic="doomed.md"/>
  <toc-element topic="other.md"/>
</instance-profile>
''',
        'admin.tree': '''
<instance-profile id="admin" name="Admin" start-page="doomed.md">
  <toc-element topic="doomed.md"/>
</instance-profile>
''',
      },
      topics: {'doomed.md': '# Doomed\n', 'other.md': '# Other\n'},
    );
    final topic = _topic(fixture.module, 'doomed.md');
    final originalTrees = {
      for (final name in ['guide.tree', 'admin.tree'])
        name: File(p.join(fixture.root.path, name)).readAsStringSync(),
    };

    await expectLater(
      editor.delete(module: fixture.module, topic: topic),
      throwsA(
        isA<BusyMarkException>().having(
          (error) => error.code,
          'code',
          'writerside.topic-file.is-start-page',
        ),
      ),
    );

    expect(File(topic.filePath).existsSync(), isTrue);
    for (final entry in originalTrees.entries) {
      expect(
        File(p.join(fixture.root.path, entry.key)).readAsStringSync(),
        entry.value,
      );
    }
  });

  test('rename rejects unsafe path components before writing', () async {
    final fixture = await _fixture(
      trees: {
        'guide.tree': '''
<instance-profile id="guide" name="Guide" start-page="guide.md">
  <toc-element topic="guide.md"/>
</instance-profile>
''',
      },
      topics: {'guide.md': '# Guide\n'},
    );
    final topic = _topic(fixture.module, 'guide.md');

    await expectLater(
      editor.rename(
        module: fixture.module,
        topic: topic,
        newFileName: '../escaped.md',
      ),
      throwsA(
        isA<BusyMarkException>().having(
          (error) => error.code,
          'code',
          'writerside.topic-file.file-name-unsafe',
        ),
      ),
    );

    expect(File(topic.filePath).existsSync(), isTrue);
    expect(
      File(p.join(fixture.root.parent.path, 'escaped.md')).existsSync(),
      isFalse,
    );
  });

  test(
    'delete rejects a topic replaced by a symlink without touching its target',
    () async {
      final fixture = await _fixture(
        trees: {
          'guide.tree': '''
<instance-profile id="guide" name="Guide" start-page="other.md">
  <toc-element topic="guide.md"/>
  <toc-element topic="other.md"/>
</instance-profile>
''',
        },
        topics: {'guide.md': '# Guide\n', 'other.md': '# Other\n'},
      );
      final topic = _topic(fixture.module, 'guide.md');
      final outside = await Directory.systemTemp.createTemp(
        'busymark-topic-file-editor-outside-',
      );
      addTearDown(() async {
        if (await outside.exists()) {
          await outside.delete(recursive: true);
        }
      });
      final target = File(p.join(outside.path, 'keep.md'))
        ..writeAsStringSync('# Keep\n');
      await File(topic.filePath).delete();
      await Link(topic.filePath).create(target.path);

      await expectLater(
        editor.delete(module: fixture.module, topic: topic),
        throwsA(
          isA<BusyMarkException>().having(
            (error) => error.code,
            'code',
            'writerside.topic-file.path-unsafe',
          ),
        ),
      );

      expect(target.readAsStringSync(), '# Keep\n');
      expect(
        FileSystemEntity.typeSync(topic.filePath, followLinks: false),
        FileSystemEntityType.link,
      );
    },
    skip: Platform.isWindows ? 'POSIX symlink behavior only.' : false,
  );
}

Future<({Directory root, WritersideModule module})> _fixture({
  required Map<String, String> trees,
  required Map<String, String> topics,
}) async {
  final root = await Directory.systemTemp.createTemp(
    'busymark-topic-file-editor-',
  );
  addTearDown(() async {
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  });
  final topicsDirectory = Directory(p.join(root.path, 'topics'))..createSync();
  final config = StringBuffer('<ihp version="2.0">\n')
    ..writeln('  <topics dir="topics"/>');
  for (final treeName in trees.keys) {
    config.writeln('  <instance src="$treeName"/>');
  }
  config.write('</ihp>\n');
  File(p.join(root.path, 'writerside.cfg')).writeAsStringSync('$config');
  for (final entry in trees.entries) {
    File(
      p.join(root.path, entry.key),
    ).writeAsStringSync(entry.value.trimLeft());
  }
  for (final entry in topics.entries) {
    final file = File(p.join(topicsDirectory.path, entry.key));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(entry.value);
  }
  return (
    root: Directory(await root.resolveSymbolicLinks()),
    module: await const WritersideModuleService().load(root.path),
  );
}

WritersideTopic _topic(WritersideModule module, String fileName) {
  return module.topics.singleWhere((topic) => topic.fileName == fileName);
}

XmlDocument _tree(Directory root, String fileName) {
  return XmlDocument.parse(
    File(p.join(root.path, fileName)).readAsStringSync(),
  );
}

List<String> _allTopicReferences(XmlDocument document) {
  return [
    for (final element in document.findAllElements('toc-element'))
      if (element.getAttribute('topic') case final topic?) topic,
  ];
}

List<String> _directTopicReferences(XmlElement element) {
  return [
    for (final child in element.childElements)
      if (child.name.local == 'toc-element') child.getAttribute('topic')!,
  ];
}
