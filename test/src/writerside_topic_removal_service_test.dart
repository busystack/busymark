import 'dart:io';

import 'package:busymark/src/core/busymark_exception.dart';
import 'package:busymark/src/writerside/writerside_model.dart';
import 'package:busymark/src/writerside/writerside_module_service.dart';
import 'package:busymark/src/writerside/writerside_topic_removal_service.dart';
import 'package:busymark/src/workspace/workspace_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

void main() {
  const service = WritersideTopicRemovalService();

  test(
    'analysis finds every tree, topic link, include, and start page',
    () async {
      final fixture = await _fixture(
        trees: {
          'guide.tree': '''
<instance-profile id="guide" name="Guide" start-page="home.md">
  <toc-element topic="home.md"/>
  <toc-element topic="doomed.md">
    <toc-element topic="child.md"/>
  </toc-element>
  <toc-element topic="referrer.md"/>
</instance-profile>
''',
          'unconfigured.tree': '''
<instance-profile id="library" name="Library" is-library="true">
  <toc-element topic="doomed.md"/>
</instance-profile>
''',
        },
        configuredTrees: const ['guide.tree'],
        topics: {
          'home.md': '# Home\n',
          'doomed.md': '# Doomed\n\n<snippet id="part">Reusable.</snippet>\n',
          'child.md': '# Child\n',
          'referrer.md': '''
# Referrer

Read [the old topic](doomed.md).

<include from="doomed.md" element-id="part"/>
''',
        },
      );
      final analysis = await service.analyze(
        module: fixture.module,
        topicPath: _topic(fixture.module, 'doomed.md').filePath,
        mode: WritersideTopicRemovalMode.safeDeleteFile,
        selectedTreePath: p.join(fixture.root.path, 'guide.tree'),
        selectedNodePath: const [1],
      );

      expect(
        analysis.usages.where(
          (usage) => usage.kind == WritersideTopicUsageKind.tocElement,
        ),
        hasLength(2),
      );
      expect(
        analysis.usages.where(
          (usage) => usage.kind == WritersideTopicUsageKind.topicLink,
        ),
        hasLength(1),
      );
      expect(
        analysis.usages.where(
          (usage) => usage.kind == WritersideTopicUsageKind.include,
        ),
        hasLength(1),
      );
      expect(analysis.childCount, 1);
      expect(analysis.isStartPage, isFalse);
      expect(analysis.canUpdateUsagesAutomatically, isTrue);
    },
  );

  test(
    'remove promotes children, updates usages, adds redirect, and keeps file',
    () async {
      final fixture = await _fixture(
        trees: {
          'guide.tree': '''
<instance-profile id="guide" name="Guide" start-page="home.md">
  <toc-element topic="home.md"/>
  <toc-element topic="doomed.md">
    <toc-element topic="child.md"/>
  </toc-element>
  <toc-element topic="replacement.md"/>
  <toc-element topic="referrer.md"/>
</instance-profile>
''',
        },
        configuredTrees: const ['guide.tree'],
        topics: {
          'home.md': '# Home\n',
          'doomed.md': '# Doomed\n\n<snippet id="part">Reusable.</snippet>\n',
          'child.md': '# Child\n',
          'replacement.md': '# Replacement\n',
          'referrer.md': '''
# Referrer

Read [the old topic](doomed.md).

<include from="doomed.md" element-id="part"/>
''',
        },
      );
      final doomed = _topic(fixture.module, 'doomed.md');
      final analysis = await service.analyze(
        module: fixture.module,
        topicPath: doomed.filePath,
        mode: WritersideTopicRemovalMode.removeFromInstance,
        selectedTreePath: p.join(fixture.root.path, 'guide.tree'),
        selectedNodePath: const [1],
      );
      final redirect = analysis.redirectTargets.singleWhere(
        (target) => target.topicFileName == 'replacement.md',
      );

      final result = await service.apply(
        WritersideTopicRemovalRequest(
          analysis: analysis,
          updateUsagesAutomatically: true,
          redirectTarget: redirect,
        ),
      );

      expect(File(doomed.filePath).existsSync(), isTrue);
      expect(result.deletedFile, isFalse);
      expect(result.promotedChildren, 1);
      expect(result.redirectAdded, isTrue);
      final tree = XmlDocument.parse(
        File(p.join(fixture.root.path, 'guide.tree')).readAsStringSync(),
      );
      expect(_topics(tree), isNot(contains('doomed.md')));
      expect(_topics(tree), contains('child.md'));
      final replacement = tree
          .findAllElements('toc-element')
          .singleWhere(
            (element) => element.getAttribute('topic') == 'replacement.md',
          );
      expect(
        replacement.getAttribute('accepts-web-file-names'),
        contains('doomed.html'),
      );
      final referrer = File(
        p.join(fixture.root.path, 'topics', 'referrer.md'),
      ).readAsStringSync();
      expect(referrer, contains('Read the old topic.'));
      expect(referrer, isNot(contains('<include')));
    },
  );

  test('safe delete updates all usages and removes every TOC occurrence', () async {
    final fixture = await _fixture(
      trees: {
        'guide.tree': '''
<instance-profile id="guide" name="Guide" start-page="home.md">
  <toc-element topic="home.md"/>
  <toc-element topic="doomed.md"/>
  <toc-element topic="replacement.md"/>
  <toc-element topic="referrer.md"/>
</instance-profile>
''',
        'unconfigured.tree': '''
<instance-profile id="library" name="Library" is-library="true">
  <toc-element topic="doomed.md"/>
  <toc-element topic="replacement.md"/>
</instance-profile>
''',
        'untouched.tree':
            '<instance-profile id="plain" name="Plain"><toc-element topic="home.md"/></instance-profile>',
      },
      configuredTrees: const ['guide.tree'],
      topics: {
        'home.md': '# Home\n',
        'doomed.md': '# Doomed\n',
        'replacement.md': '# Replacement\n',
        'referrer.md': '# Referrer\n\n[Old](doomed.md)\n',
      },
    );
    final doomed = _topic(fixture.module, 'doomed.md');
    final analysis = await service.analyze(
      module: fixture.module,
      topicPath: doomed.filePath,
      mode: WritersideTopicRemovalMode.safeDeleteFile,
    );
    final redirect = analysis.redirectTargets.singleWhere(
      (target) => target.topicFileName == 'replacement.md',
    );

    final result = await service.apply(
      WritersideTopicRemovalRequest(
        analysis: analysis,
        updateUsagesAutomatically: true,
        redirectTarget: redirect,
      ),
    );

    expect(result.deletedFile, isTrue);
    expect(File(doomed.filePath).existsSync(), isFalse);
    expect(
      File(
        p.join(fixture.root.path, 'topics', 'referrer.md'),
      ).readAsStringSync(),
      contains('Old'),
    );
    for (final name in ['guide.tree', 'unconfigured.tree']) {
      final tree = _tree(fixture.root, name);
      expect(_topics(tree), isNot(contains('doomed.md')));
      final replacement = tree
          .findAllElements('toc-element')
          .singleWhere(
            (element) => element.getAttribute('topic') == 'replacement.md',
          );
      expect(
        replacement.getAttribute('accepts-web-file-names'),
        contains('doomed.html'),
      );
    }
    expect(
      File(p.join(fixture.root.path, 'untouched.tree')).readAsStringSync(),
      '<instance-profile id="plain" name="Plain"><toc-element topic="home.md"/></instance-profile>',
    );
  });

  test(
    'redirect to a promoted child is written to the promoted copy',
    () async {
      final fixture = await _fixture(
        trees: {
          'guide.tree': '''
<instance-profile id="guide" name="Guide" start-page="home.md">
  <toc-element topic="home.md"/>
  <toc-element topic="doomed.md">
    <toc-element topic="child.md"/>
  </toc-element>
</instance-profile>
''',
        },
        configuredTrees: const ['guide.tree'],
        topics: {
          'home.md': '# Home\n',
          'doomed.md': '# Doomed\n',
          'child.md': '# Child\n',
        },
      );
      final doomed = _topic(fixture.module, 'doomed.md');
      final analysis = await service.analyze(
        module: fixture.module,
        topicPath: doomed.filePath,
        mode: WritersideTopicRemovalMode.removeFromInstance,
        selectedTreePath: p.join(fixture.root.path, 'guide.tree'),
        selectedNodePath: const [1],
      );
      final child = analysis.redirectTargets.singleWhere(
        (target) => target.topicFileName == 'child.md',
      );

      final result = await service.apply(
        WritersideTopicRemovalRequest(
          analysis: analysis,
          redirectTarget: child,
        ),
      );

      expect(result.redirectAdded, isTrue);
      final tree = _tree(fixture.root, 'guide.tree');
      final promotedChild = tree
          .findAllElements('toc-element')
          .singleWhere(
            (element) => element.getAttribute('topic') == 'child.md',
          );
      expect(
        promotedChild.getAttribute('accepts-web-file-names'),
        'doomed.html',
      );
    },
  );

  test('malformed XML topics make usage analysis fail closed', () async {
    final fixture = await _fixture(
      trees: {
        'guide.tree': '''
<instance-profile id="guide" name="Guide">
  <toc-element topic="doomed.md"/>
</instance-profile>
''',
      },
      configuredTrees: const ['guide.tree'],
      topics: {
        'doomed.md': '# Doomed\n',
        'broken.topic':
            '<topic id="broken" title="Broken"><a href="doomed.md">Old</topic>',
      },
    );
    final doomed = _topic(fixture.module, 'doomed.md');

    await expectLater(
      service.analyze(
        module: fixture.module,
        topicPath: doomed.filePath,
        mode: WritersideTopicRemovalMode.safeDeleteFile,
      ),
      throwsA(
        isA<BusyMarkException>().having(
          (error) => error.code,
          'code',
          'writerside.topic-removal.scan-failed',
        ),
      ),
    );
    expect(File(doomed.filePath).existsSync(), isTrue);
  });

  test(
    'single-quoted includes without element-id are found and removed',
    () async {
      final fixture = await _fixture(
        trees: {
          'guide.tree': '''
<instance-profile id="guide" name="Guide">
  <toc-element topic="doomed.md"/>
  <toc-element topic="referrer.md"/>
</instance-profile>
''',
        },
        configuredTrees: const ['guide.tree'],
        topics: {
          'doomed.md': '# Doomed\n',
          'referrer.md': "# Referrer\n\n<include from='doomed.md'/>\n",
        },
      );
      final doomed = _topic(fixture.module, 'doomed.md');
      final analysis = await service.analyze(
        module: fixture.module,
        topicPath: doomed.filePath,
        mode: WritersideTopicRemovalMode.safeDeleteFile,
      );

      expect(
        analysis.usages.where(
          (usage) => usage.kind == WritersideTopicUsageKind.include,
        ),
        hasLength(1),
      );
      await service.apply(
        WritersideTopicRemovalRequest(
          analysis: analysis,
          updateUsagesAutomatically: true,
        ),
      );
      expect(
        File(
          p.join(fixture.root.path, 'topics', 'referrer.md'),
        ).readAsStringSync(),
        isNot(contains('<include')),
      );
    },
  );

  test(
    'variable-expanded links are analyzed and the variables file is stale-checked',
    () async {
      final fixture = await _fixture(
        trees: {
          'guide.tree': '''
<instance-profile id="guide" name="Guide">
  <toc-element topic="doomed.md"/>
  <toc-element topic="referrer.md"/>
</instance-profile>
''',
        },
        configuredTrees: const ['guide.tree'],
        variables: '<vars><var name="target" value="doomed.md"/></vars>',
        topics: {
          'doomed.md': '# Doomed\n',
          'referrer.md': '# Referrer\n\n[Old](%target%)\n',
        },
      );
      final doomed = _topic(fixture.module, 'doomed.md');
      expect(fixture.module.variables.map((variable) => variable.value), [
        'doomed.md',
      ]);
      expect(
        _topic(
          fixture.module,
          'referrer.md',
        ).links.map((link) => link.destination),
        ['%25target%25'],
      );
      final analysis = await service.analyze(
        module: fixture.module,
        topicPath: doomed.filePath,
        mode: WritersideTopicRemovalMode.safeDeleteFile,
      );
      expect(
        analysis.usages.where(
          (usage) => usage.kind == WritersideTopicUsageKind.topicLink,
        ),
        hasLength(1),
      );

      File(
        p.join(fixture.root.path, 'v.list'),
      ).writeAsStringSync('<vars><var name="target" value="other.md"/></vars>');
      await expectLater(
        service.apply(
          WritersideTopicRemovalRequest(
            analysis: analysis,
            updateUsagesAutomatically: true,
          ),
        ),
        throwsA(isA<BusyMarkException>()),
      );
      expect(File(doomed.filePath).existsSync(), isTrue);
    },
  );

  test(
    'ambiguous references block deletion without changing any file',
    () async {
      final fixture = await _fixture(
        trees: {
          'guide.tree': '''
<instance-profile id="guide" name="Guide">
  <toc-element topic="one/doomed.md"/>
  <toc-element topic="referrer.md"/>
</instance-profile>
''',
        },
        configuredTrees: const ['guide.tree'],
        topics: {
          'one/doomed.md': '# First\n',
          'two/doomed.md': '# Second\n',
          'referrer.md': '# Referrer\n\n[Old](doomed.md)\n',
        },
      );
      final doomed = _topic(fixture.module, 'one/doomed.md');
      final before = <String, String>{
        for (final path in [
          p.join(fixture.root.path, 'guide.tree'),
          p.join(fixture.root.path, 'topics', 'one', 'doomed.md'),
          p.join(fixture.root.path, 'topics', 'referrer.md'),
        ])
          path: File(path).readAsStringSync(),
      };
      final analysis = await service.analyze(
        module: fixture.module,
        topicPath: doomed.filePath,
        mode: WritersideTopicRemovalMode.safeDeleteFile,
      );
      expect(analysis.canUpdateUsagesAutomatically, isFalse);

      await expectLater(
        service.apply(
          WritersideTopicRemovalRequest(
            analysis: analysis,
            updateUsagesAutomatically: true,
          ),
        ),
        throwsA(isA<BusyMarkException>()),
      );
      for (final entry in before.entries) {
        expect(File(entry.key).readAsStringSync(), entry.value);
      }
    },
  );

  test(
    'old web file names follow Writerside normalization and exact overrides',
    () async {
      final fixture = await _fixture(
        trees: {
          'guide.tree': '''
<instance-profile id="guide" name="Guide">
  <toc-element topic="Document_everything.topic"/>
  <toc-element topic="custom.topic"/>
</instance-profile>
''',
        },
        configuredTrees: const ['guide.tree'],
        topics: {
          'Document_everything.topic':
              '<topic id="Document_everything" title="Document everything"/>',
          'custom.topic': '''
<topic id="custom" title="Custom">
  <web-file-name>Exact_Name</web-file-name>
</topic>
''',
        },
      );

      final normalized = await service.analyze(
        module: fixture.module,
        topicPath: _topic(fixture.module, 'Document_everything.topic').filePath,
        mode: WritersideTopicRemovalMode.safeDeleteFile,
      );
      final custom = await service.analyze(
        module: fixture.module,
        topicPath: _topic(fixture.module, 'custom.topic').filePath,
        mode: WritersideTopicRemovalMode.safeDeleteFile,
      );
      expect(normalized.oldWebFileName, 'document-everything.html');
      expect(custom.oldWebFileName, 'Exact_Name');

      File(p.join(fixture.root.path, 'writerside.cfg')).writeAsStringSync('''
<ihp version="2.0">
  <topics dir="topics"/>
  <instance src="guide.tree"/>
  <settings><disable-web-name-preprocessing>true</disable-web-name-preprocessing></settings>
</ihp>
''');
      final preprocessingDisabled = await service.analyze(
        module: fixture.module,
        topicPath: _topic(
          fixture.module,
          'Document_everything.topic',
        ).filePath,
        mode: WritersideTopicRemovalMode.safeDeleteFile,
      );
      expect(
        preprocessingDisabled.oldWebFileName,
        'Document_everything.html',
      );
    },
  );

  test('existing redirect rules block conflicting redirects', () async {
    final fixture = await _fixture(
      trees: {
        'guide.tree': '''
<instance-profile id="guide" name="Guide">
  <toc-element topic="doomed.md"/>
  <toc-element topic="replacement.md"/>
  <toc-element topic="existing.md" accepts-web-file-names-ref="existing-rule"/>
</instance-profile>
''',
      },
      configuredTrees: const ['guide.tree'],
      topics: {
        'doomed.md': '# Doomed\n',
        'replacement.md': '# Replacement\n',
        'existing.md': '# Existing\n',
      },
    );
    File(p.join(fixture.root.path, 'redirection-rules.xml')).writeAsStringSync(
      '''
<redirection-rules>
  <rule id="existing-rule"><accepts>doomed.html</accepts></rule>
</redirection-rules>
''',
    );
    final doomed = _topic(fixture.module, 'doomed.md');
    final analysis = await service.analyze(
      module: fixture.module,
      topicPath: doomed.filePath,
      mode: WritersideTopicRemovalMode.safeDeleteFile,
    );
    final replacement = analysis.redirectTargets.singleWhere(
      (target) => target.topicFileName == 'replacement.md',
    );
    final treePath = p.join(fixture.root.path, 'guide.tree');
    final treeBefore = File(treePath).readAsStringSync();

    await expectLater(
      service.apply(
        WritersideTopicRemovalRequest(
          analysis: analysis,
          redirectTarget: replacement,
        ),
      ),
      throwsA(
        isA<BusyMarkException>().having(
          (error) => error.code,
          'code',
          'writerside.topic-removal.redirect-invalid',
        ),
      ),
    );
    expect(File(treePath).readAsStringSync(), treeBefore);
    expect(File(doomed.filePath).existsSync(), isTrue);
  });

  test(
    'remaining start-page and cross-instance usages prevent orphan status',
    () async {
      final fixture = await _fixture(
        trees: {
          'guide.tree': '''
<instance-profile id="guide" name="Guide" start-page="home.md">
  <toc-element topic="home.md"/>
  <toc-element topic="doomed.md"/>
</instance-profile>
''',
          'other.tree': '''
<instance-profile id="other" name="Other">
  <toc-element topic="doomed.md"/>
</instance-profile>
''',
        },
        configuredTrees: const ['guide.tree', 'other.tree'],
        topics: {'home.md': '# Home\n', 'doomed.md': '# Doomed\n'},
      );
      final doomed = _topic(fixture.module, 'doomed.md');
      final analysis = await service.analyze(
        module: fixture.module,
        topicPath: doomed.filePath,
        mode: WritersideTopicRemovalMode.removeFromInstance,
        selectedTreePath: p.join(fixture.root.path, 'guide.tree'),
        selectedNodePath: const [1],
      );

      final result = await service.apply(
        WritersideTopicRemovalRequest(analysis: analysis),
      );
      expect(result.orphaned, isFalse);
      expect(File(doomed.filePath).existsSync(), isTrue);
    },
  );

  test(
    'start-page and stale analyses fail closed without deleting the topic',
    () async {
      final fixture = await _fixture(
        trees: {
          'guide.tree': '''
<instance-profile id="guide" name="Guide" start-page="doomed.md">
  <toc-element topic="doomed.md"/>
</instance-profile>
''',
        },
        configuredTrees: const ['guide.tree'],
        topics: {'doomed.md': '# Doomed\n'},
      );
      final doomed = _topic(fixture.module, 'doomed.md');
      final analysis = await service.analyze(
        module: fixture.module,
        topicPath: doomed.filePath,
        mode: WritersideTopicRemovalMode.safeDeleteFile,
      );
      expect(analysis.isStartPage, isTrue);
      await expectLater(
        service.apply(
          WritersideTopicRemovalRequest(
            analysis: analysis,
            updateUsagesAutomatically: true,
          ),
        ),
        throwsA(isA<BusyMarkException>()),
      );
      expect(File(doomed.filePath).existsSync(), isTrue);

      final removeAnalysis = await service.analyze(
        module: fixture.module,
        topicPath: doomed.filePath,
        mode: WritersideTopicRemovalMode.removeFromInstance,
        selectedTreePath: p.join(fixture.root.path, 'guide.tree'),
        selectedNodePath: const [0],
      );
      expect(removeAnalysis.isStartPage, isTrue);
      expect(removeAnalysis.canUpdateUsagesAutomatically, isFalse);
      await expectLater(
        service.apply(WritersideTopicRemovalRequest(analysis: removeAnalysis)),
        throwsA(isA<BusyMarkException>()),
      );
      expect(File(doomed.filePath).existsSync(), isTrue);

      File(p.join(fixture.root.path, 'guide.tree')).writeAsStringSync('''
<instance-profile id="guide" name="Guide" start-page="doomed.md">
  <toc-element topic="doomed.md" toc-title="Changed"/>
</instance-profile>
''');
      await expectLater(
        service.apply(WritersideTopicRemovalRequest(analysis: analysis)),
        throwsA(isA<BusyMarkException>()),
      );
      expect(File(doomed.filePath).existsSync(), isTrue);
    },
  );

  test('generic Files deletion cannot bypass Writerside Safe Delete', () async {
    final fixture = await _fixture(
      trees: {
        'guide.tree': '''
<instance-profile id="guide" name="Guide" start-page="home.md">
  <toc-element topic="home.md"/>
  <toc-element topic="doomed.md"/>
</instance-profile>
''',
      },
      configuredTrees: const ['guide.tree'],
      topics: {'home.md': '# Home\n', 'doomed.md': '# Doomed\n'},
    );
    const workspaceService = WorkspaceService();
    final workspace = await workspaceService.openPath(fixture.root.path);
    final doomedPath = _topic(fixture.module, 'doomed.md').filePath;

    await expectLater(
      workspaceService.deleteEntity(workspace, doomedPath),
      throwsA(
        isA<BusyMarkException>().having(
          (error) => error.code,
          'code',
          'writerside.topic-removal.safe-delete-required',
        ),
      ),
    );
    expect(File(doomedPath).existsSync(), isTrue);

    await expectLater(
      workspaceService.deleteEntity(
        workspace,
        p.join(fixture.root.path, 'topics'),
      ),
      throwsA(
        isA<BusyMarkException>().having(
          (error) => error.code,
          'code',
          'writerside.topic-removal.safe-delete-required',
        ),
      ),
    );
    expect(Directory(p.join(fixture.root.path, 'topics')).existsSync(), isTrue);
  });
}

Future<({Directory root, WritersideModule module})> _fixture({
  required Map<String, String> trees,
  required List<String> configuredTrees,
  required Map<String, String> topics,
  String? variables,
}) async {
  final root = await Directory.systemTemp.createTemp('busymark-topic-removal-');
  addTearDown(() async {
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  });
  final topicsDirectory = Directory(p.join(root.path, 'topics'))..createSync();
  final config = StringBuffer('<ihp version="2.0">\n')
    ..writeln('  <topics dir="topics"/>');
  for (final treeName in configuredTrees) {
    config.writeln('  <instance src="$treeName"/>');
  }
  if (variables != null) {
    config.writeln('  <vars src="v.list"/>');
  }
  config.write('</ihp>\n');
  File(p.join(root.path, 'writerside.cfg')).writeAsStringSync('$config');
  if (variables != null) {
    File(p.join(root.path, 'v.list')).writeAsStringSync(variables);
  }
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
  final canonicalRoot = Directory(await root.resolveSymbolicLinks());
  return (
    root: canonicalRoot,
    module: await const WritersideModuleService().load(canonicalRoot.path),
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

List<String> _topics(XmlDocument document) {
  return [
    for (final element in document.findAllElements('toc-element'))
      if (element.getAttribute('topic') case final topic?) topic,
  ];
}
