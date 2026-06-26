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
    return root;
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
}
