import 'dart:io';

import 'package:busymark/src/core/busymark_exception.dart';
import 'package:busymark/src/writerside/writerside_model.dart';
import 'package:busymark/src/writerside/writerside_topic_creator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

void main() {
  const creator = WritersideTopicCreator();

  Future<Directory> tempModule() async {
    final root = await Directory.systemTemp.createTemp(
      'busymark-writerside-topic-',
    );
    addTearDown(() async {
      if (await root.exists()) {
        await root.delete(recursive: true);
      }
    });
    Directory(p.join(root.path, 'topics')).createSync();
    File(p.join(root.path, 'ug.tree')).writeAsStringSync('''
<?xml version="1.0" encoding="UTF-8"?>
<instance-profile id="ug" name="User Guide" start-page="intro.md">
  <toc-element topic="intro.md"/>
</instance-profile>
''');
    File(p.join(root.path, 'topics', 'intro.md')).writeAsStringSync('''
# Intro
''');
    return Directory(await root.resolveSymbolicLinks());
  }

  test(
    'creates XML child topic and registers it under parent TOC node',
    () async {
      final root = await tempModule();

      final result = await creator.create(
        WritersideTopicCreateTarget(
          rootPath: root.path,
          treePath: p.join(root.path, 'ug.tree'),
          topicsRootDir: 'topics',
          existingTopicIds: {'intro'},
        ),
        const WritersideTopicCreateRequest(
          title: 'Details',
          fileName: 'details',
          format: WritersideTopicFormat.xml,
          placement: WritersideTopicCreatePlacement.child,
          referenceTopic: 'intro.md',
        ),
      );

      final topicSource = File(result.topicPath).readAsStringSync();
      final tree = XmlDocument.parse(
        File(p.join(root.path, 'ug.tree')).readAsStringSync(),
      );
      final intro = tree
          .findAllElements('toc-element')
          .singleWhere(
            (element) => element.getAttribute('topic') == 'intro.md',
          );

      expect(result.topicFileName, 'details.topic');
      expect(topicSource, contains('title="Details"'));
      expect(topicSource, contains('id="details"'));
      expect(
        intro.childElements.map((element) => element.getAttribute('topic')),
        contains('details.topic'),
      );
    },
  );

  test('requires a reference for every non-root placement', () async {
    final root = await tempModule();

    await expectLater(
      creator.create(
        WritersideTopicCreateTarget(
          rootPath: root.path,
          treePath: p.join(root.path, 'ug.tree'),
          topicsRootDir: 'topics',
          existingTopicIds: const {'intro'},
        ),
        const WritersideTopicCreateRequest(
          title: 'Details',
          fileName: 'details',
          placement: WritersideTopicCreatePlacement.sibling,
        ),
      ),
      throwsA(
        isA<BusyMarkException>().having(
          (error) => error.code,
          'code',
          'writerside.topic.reference-missing',
        ),
      ),
    );

    expect(File(p.join(root.path, 'topics', 'details.md')).existsSync(), false);
    expect(
      File(p.join(root.path, 'ug.tree')).readAsStringSync(),
      isNot(contains('details.md')),
    );
  });

  test('creates a child under an exact topic-less TOC node path', () async {
    final root = await tempModule();
    File(p.join(root.path, 'ug.tree')).writeAsStringSync('''
<instance-profile id="ug" name="User Guide" start-page="intro.md">
  <toc-element id="guides" toc-title="Guides">
    <toc-element topic="intro.md"/>
  </toc-element>
</instance-profile>
''');

    await creator.create(
      WritersideTopicCreateTarget(
        rootPath: root.path,
        treePath: p.join(root.path, 'ug.tree'),
        topicsRootDir: 'topics',
        existingTopicIds: const {'intro'},
      ),
      const WritersideTopicCreateRequest(
        title: 'Details',
        fileName: 'details',
        placement: WritersideTopicCreatePlacement.child,
        referenceTocPath: [0],
      ),
    );

    final tree = XmlDocument.parse(
      File(p.join(root.path, 'ug.tree')).readAsStringSync(),
    );
    final guides = tree
        .findAllElements('toc-element')
        .singleWhere((element) => element.getAttribute('id') == 'guides');
    expect(
      guides.childElements.map((element) => element.getAttribute('topic')),
      ['intro.md', 'details.md'],
    );
  });

  test('exact TOC path disambiguates sibling insertion', () async {
    final root = await tempModule();
    File(p.join(root.path, 'ug.tree')).writeAsStringSync('''
<instance-profile id="ug" name="User Guide" start-page="same.md">
  <toc-element id="first" toc-title="First">
    <toc-element topic="same.md"/>
  </toc-element>
  <toc-element id="second" toc-title="Second">
    <toc-element topic="same.md"/>
  </toc-element>
</instance-profile>
''');

    await creator.create(
      WritersideTopicCreateTarget(
        rootPath: root.path,
        treePath: p.join(root.path, 'ug.tree'),
        topicsRootDir: 'topics',
        existingTopicIds: const {'intro'},
      ),
      const WritersideTopicCreateRequest(
        title: 'Details',
        fileName: 'details',
        placement: WritersideTopicCreatePlacement.sibling,
        referenceTopic: 'same.md',
        referenceTocPath: [1, 0],
      ),
    );

    final tree = XmlDocument.parse(
      File(p.join(root.path, 'ug.tree')).readAsStringSync(),
    );
    final sections = tree.rootElement.childElements
        .where((element) => element.name.local == 'toc-element')
        .toList();
    expect(
      sections[0].childElements.map((element) => element.getAttribute('topic')),
      ['same.md'],
    );
    expect(
      sections[1].childElements.map((element) => element.getAttribute('topic')),
      ['same.md', 'details.md'],
    );
  });

  test('rejects an exact TOC path whose expected node has moved', () async {
    final root = await tempModule();
    final treeFile = File(p.join(root.path, 'ug.tree'));
    treeFile.writeAsStringSync('''
<instance-profile id="ug" name="User Guide" start-page="a.md">
  <toc-element id="inserted" topic="inserted.md"/>
  <toc-element id="a" topic="a.md"/>
  <toc-element id="b" topic="b.md"/>
</instance-profile>
''');

    await expectLater(
      creator.create(
        WritersideTopicCreateTarget(
          rootPath: root.path,
          treePath: treeFile.path,
          topicsRootDir: 'topics',
          existingTopicIds: const {'intro'},
        ),
        const WritersideTopicCreateRequest(
          title: 'Details',
          fileName: 'details',
          placement: WritersideTopicCreatePlacement.child,
          referenceTocPath: [1],
          referenceTocIdentity: WritersideTocNodeIdentity(
            id: 'b',
            topicFileName: 'b.md',
            hidden: false,
          ),
        ),
      ),
      throwsA(
        isA<BusyMarkException>().having(
          (error) => error.code,
          'code',
          'writerside.topic.reference-missing',
        ),
      ),
    );

    expect(treeFile.readAsStringSync(), isNot(contains('details.md')));
    expect(File(p.join(root.path, 'topics', 'details.md')).existsSync(), false);
  });

  test(
    'invalid exact TOC path does not fall back to topic reference',
    () async {
      final root = await tempModule();

      await expectLater(
        creator.create(
          WritersideTopicCreateTarget(
            rootPath: root.path,
            treePath: p.join(root.path, 'ug.tree'),
            topicsRootDir: 'topics',
            existingTopicIds: const {'intro'},
          ),
          const WritersideTopicCreateRequest(
            title: 'Details',
            fileName: 'details',
            placement: WritersideTopicCreatePlacement.child,
            referenceTopic: 'intro.md',
            referenceTocPath: [4],
          ),
        ),
        throwsA(
          isA<BusyMarkException>().having(
            (error) => error.code,
            'code',
            'writerside.topic.reference-missing',
          ),
        ),
      );

      expect(
        File(p.join(root.path, 'topics', 'details.md')).existsSync(),
        false,
      );
    },
  );

  test('rejects duplicate topic IDs before writing', () async {
    final root = await tempModule();

    await expectLater(
      creator.create(
        WritersideTopicCreateTarget(
          rootPath: root.path,
          treePath: p.join(root.path, 'ug.tree'),
          topicsRootDir: 'topics',
          existingTopicIds: {'intro'},
        ),
        const WritersideTopicCreateRequest(
          title: 'Other Intro',
          fileName: 'intro.topic',
          format: WritersideTopicFormat.xml,
        ),
      ),
      throwsA(isA<BusyMarkException>()),
    );
    expect(
      File(p.join(root.path, 'topics', 'intro.topic')).existsSync(),
      false,
    );
  });

  test('creates a missing nested topics directory', () async {
    final root = await tempModule();

    final result = await creator.create(
      WritersideTopicCreateTarget(
        rootPath: root.path,
        treePath: p.join(root.path, 'ug.tree'),
        topicsRootDir: p.join('docs', 'topics'),
        existingTopicIds: const {'intro'},
      ),
      const WritersideTopicCreateRequest(title: 'Details', fileName: 'details'),
    );

    expect(Directory(p.join(root.path, 'docs', 'topics')).existsSync(), isTrue);
    expect(result.topicPath, p.join(root.path, 'docs', 'topics', 'details.md'));
    expect(File(result.topicPath).existsSync(), isTrue);
  });

  test(
    'rejects a symlinked topics directory without writing outside',
    () async {
      final root = await tempModule();
      final outside = await Directory.systemTemp.createTemp(
        'busymark-writerside-topic-outside-',
      );
      addTearDown(() async {
        if (await outside.exists()) {
          await outside.delete(recursive: true);
        }
      });
      final topics = Directory(p.join(root.path, 'topics'));
      await topics.delete(recursive: true);
      await Link(topics.path).create(outside.path);
      final escapedTopic = File(p.join(outside.path, 'details.md'));

      await expectLater(
        creator.create(
          WritersideTopicCreateTarget(
            rootPath: root.path,
            treePath: p.join(root.path, 'ug.tree'),
            topicsRootDir: 'topics',
            existingTopicIds: const {'intro'},
          ),
          const WritersideTopicCreateRequest(
            title: 'Details',
            fileName: 'details',
          ),
        ),
        throwsA(isA<BusyMarkException>()),
      );

      expect(escapedTopic.existsSync(), isFalse);
    },
    skip: Platform.isWindows ? 'POSIX symlink behavior only.' : false,
  );

  test(
    'does not overwrite a concurrently changed tree or leave an orphan topic',
    () async {
      final root = await tempModule();
      final treeFile = File(p.join(root.path, 'ug.tree'));
      final externalSource = treeFile.readAsStringSync().replaceFirst(
        'name="User Guide"',
        'name="Externally changed"',
      );
      final racingCreator = WritersideTopicCreator(
        beforeTreePublish: (treePath) async {
          expect(treePath, treeFile.path);
          await treeFile.writeAsString(externalSource, flush: true);
        },
      );

      await expectLater(
        racingCreator.create(
          WritersideTopicCreateTarget(
            rootPath: root.path,
            treePath: treeFile.path,
            topicsRootDir: 'topics',
            existingTopicIds: const {'intro'},
          ),
          const WritersideTopicCreateRequest(
            title: 'Details',
            fileName: 'details',
          ),
        ),
        throwsA(
          isA<BusyMarkException>().having(
            (error) => error.code,
            'code',
            'writerside.topic.tree-changed',
          ),
        ),
      );

      expect(treeFile.readAsStringSync(), externalSource);
      expect(
        File(p.join(root.path, 'topics', 'details.md')).existsSync(),
        isFalse,
      );
      final temporaryFiles = await root
          .list()
          .where(
            (entity) => p
                .basename(entity.path)
                .startsWith('.ug.tree.busymark-topic-create-'),
          )
          .toList();
      expect(temporaryFiles, isEmpty);
    },
  );

  test(
    'rollback preserves a created topic changed by another writer',
    () async {
      final root = await tempModule();
      final treeFile = File(p.join(root.path, 'ug.tree'));
      final topicFile = File(p.join(root.path, 'topics', 'details.md'));
      final originalTree = treeFile.readAsStringSync();
      final externalTree = originalTree.replaceFirst(
        'name="User Guide"',
        'name="Externally changed"',
      );
      const externalTopic = '# External contents\n';
      final racingCreator = WritersideTopicCreator(
        beforeTreePublish: (_) async {
          await topicFile.writeAsString(externalTopic, flush: true);
          await treeFile.writeAsString(externalTree, flush: true);
        },
      );

      await expectLater(
        racingCreator.create(
          WritersideTopicCreateTarget(
            rootPath: root.path,
            treePath: treeFile.path,
            topicsRootDir: 'topics',
            existingTopicIds: const {'intro'},
          ),
          const WritersideTopicCreateRequest(
            title: 'Details',
            fileName: 'details',
          ),
        ),
        throwsA(
          isA<BusyMarkException>().having(
            (error) => error.code,
            'code',
            'writerside.topic.tree-changed',
          ),
        ),
      );

      expect(treeFile.readAsStringSync(), externalTree);
      expect(topicFile.readAsStringSync(), externalTopic);
    },
  );

  test(
    'atomic tree publication preserves its POSIX mode',
    () async {
      final root = await tempModule();
      final treeFile = File(p.join(root.path, 'ug.tree'));
      final chmod = await Process.run('chmod', ['640', treeFile.path]);
      expect(chmod.exitCode, 0, reason: '${chmod.stderr}');
      final originalMode = (await treeFile.stat()).mode & 0xfff;

      await creator.create(
        WritersideTopicCreateTarget(
          rootPath: root.path,
          treePath: treeFile.path,
          topicsRootDir: 'topics',
          existingTopicIds: const {'intro'},
        ),
        const WritersideTopicCreateRequest(
          title: 'Details',
          fileName: 'details',
        ),
      );

      expect((await treeFile.stat()).mode & 0xfff, originalMode);
    },
    skip: Platform.isWindows ? 'POSIX permissions only.' : false,
  );
}
