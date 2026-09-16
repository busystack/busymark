import 'dart:io';

import 'package:busymark/src/core/busymark_exception.dart';
import 'package:busymark/src/core/path_utils.dart';
import 'package:busymark/src/writerside/writerside_model.dart';
import 'package:busymark/src/writerside/writerside_module_service.dart';
import 'package:busymark/src/writerside/writerside_project.dart';
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

  test('file-size-skipped topics make removal fail closed', () async {
    final fixture = await _fixture(
      trees: {
        'guide.tree':
            '<instance-profile id="guide"><toc-element topic="doomed.md"/></instance-profile>',
      },
      configuredTrees: const ['guide.tree'],
      topics: {
        'doomed.md': '# Doomed\n',
        'reference.md':
            '# Reference\n\n[Old](doomed.md)\n${List.filled(512, 'x').join()}',
      },
    );
    final target = p.join(fixture.root.path, 'topics', 'doomed.md');
    final reference = p.join(fixture.root.path, 'topics', 'reference.md');
    final before = File(reference).readAsStringSync();
    final limited = WritersideTopicRemovalService(
      moduleService: const WritersideModuleService(
        scanOptions: WorkspaceScanOptions(maxParsedFileBytes: 256),
      ),
    );

    await expectLater(
      limited.analyze(
        projectRoot: fixture.root.path,
        topicPath: target,
        mode: WritersideTopicRemovalMode.safeDeleteFile,
      ),
      throwsA(isA<BusyMarkException>()),
    );
    expect(File(target).existsSync(), isTrue);
    expect(File(reference).readAsStringSync(), before);
  });

  test('document-count-skipped topics make removal fail closed', () async {
    final fixture = await _fixture(
      trees: {
        'guide.tree':
            '<instance-profile id="guide"><toc-element topic="a-doomed.md"/></instance-profile>',
      },
      configuredTrees: const ['guide.tree'],
      topics: {
        'a-doomed.md': '# Doomed\n',
        'z-reference.md': '# Reference\n\n[Old](a-doomed.md)\n',
      },
    );
    final target = p.join(fixture.root.path, 'topics', 'a-doomed.md');
    final reference = p.join(fixture.root.path, 'topics', 'z-reference.md');
    final before = File(reference).readAsStringSync();
    final limited = WritersideTopicRemovalService(
      moduleService: const WritersideModuleService(
        scanOptions: WorkspaceScanOptions(maxParsedDocuments: 1),
      ),
    );

    await expectLater(
      limited.analyze(
        projectRoot: fixture.root.path,
        topicPath: target,
        mode: WritersideTopicRemovalMode.safeDeleteFile,
      ),
      throwsA(isA<BusyMarkException>()),
    );
    expect(File(target).existsSync(), isTrue);
    expect(File(reference).readAsStringSync(), before);
  });

  test('unreadable topic contents make removal fail closed', () async {
    final fixture = await _fixture(
      trees: {
        'guide.tree':
            '<instance-profile id="guide"><toc-element topic="doomed.md"/></instance-profile>',
      },
      configuredTrees: const ['guide.tree'],
      topics: {'doomed.md': '# Doomed\n', 'unreadable.md': '# Placeholder\n'},
    );
    final target = p.join(fixture.root.path, 'topics', 'doomed.md');
    final unreadable = File(
      p.join(fixture.root.path, 'topics', 'unreadable.md'),
    )..writeAsBytesSync([0xff, 0xfe, 0xfd]);
    final before = unreadable.readAsBytesSync();

    await expectLater(
      service.analyze(
        projectRoot: fixture.root.path,
        topicPath: target,
        mode: WritersideTopicRemovalMode.safeDeleteFile,
      ),
      throwsA(isA<BusyMarkException>()),
    );
    expect(File(target).existsSync(), isTrue);
    expect(unreadable.readAsBytesSync(), before);
  });

  test('topic-root traversal truncation makes removal fail closed', () async {
    final fixture = await _fixture(
      trees: {
        'guide.tree':
            '<instance-profile id="guide"><toc-element topic="doomed.md"/></instance-profile>',
      },
      configuredTrees: const ['guide.tree'],
      topics: {
        'doomed.md': '# Doomed\n',
        'deep/reference.md': '# Reference\n\n[Old](../doomed.md)\n',
      },
    );
    final target = p.join(fixture.root.path, 'topics', 'doomed.md');
    final limitedModuleService = const WritersideModuleService(
      scanOptions: WorkspaceScanOptions(maxTreeEntries: 2),
    );
    final incompleteModule = await limitedModuleService.load(fixture.root.path);
    final incompleteProject = WritersideProject(
      rootPath: fixture.root.path,
      modules: [incompleteModule],
      activeModuleId: null,
      activeInstanceId: null,
      index: WritersideProjectIndex.build([incompleteModule]),
      diagnostics: incompleteModule.diagnostics,
    );

    await expectLater(
      service.analyze(
        project: incompleteProject,
        topicPath: target,
        mode: WritersideTopicRemovalMode.safeDeleteFile,
      ),
      throwsA(isA<BusyMarkException>()),
    );
    expect(File(target).existsSync(), isTrue);
  });

  test('incomplete project-module discovery makes removal fail closed', () async {
    final fixture = await _fixture(
      trees: {
        'guide.tree':
            '<instance-profile id="guide"><toc-element topic="doomed.md"/></instance-profile>',
      },
      configuredTrees: const ['guide.tree'],
      topics: {'doomed.md': '# Doomed\n'},
    );
    final target = p.join(fixture.root.path, 'topics', 'doomed.md');
    final limited = WritersideTopicRemovalService(
      projectService: const WritersideProjectService(
        scanOptions: WorkspaceScanOptions(maxTreeEntries: 1),
      ),
    );

    await expectLater(
      limited.analyze(
        projectRoot: fixture.root.path,
        topicPath: target,
        mode: WritersideTopicRemovalMode.safeDeleteFile,
      ),
      throwsA(
        isA<BusyMarkException>().having(
          (error) => error.code,
          'code',
          'writerside.topic-file.project-discovery-incomplete',
        ),
      ),
    );
    expect(File(target).existsSync(), isTrue);
  });

  test('tree directory enumeration failure makes removal fail closed', () async {
    final fixture = await _fixture(
      trees: {
        'guide.tree':
            '<instance-profile id="guide"><toc-element topic="doomed.md"/></instance-profile>',
      },
      configuredTrees: const ['guide.tree'],
      topics: {'doomed.md': '# Doomed\n'},
    );
    final target = p.join(fixture.root.path, 'topics', 'doomed.md');
    Stream<FileSystemEntity> failListing(
      Directory directory, {
      required bool followLinks,
    }) async* {
      throw FileSystemException('listing failed', directory.path);
    }

    final failing = WritersideTopicRemovalService(
      treeDirectoryLister: failListing,
    );
    await expectLater(
      failing.analyze(
        projectRoot: fixture.root.path,
        topicPath: target,
        mode: WritersideTopicRemovalMode.safeDeleteFile,
      ),
      throwsA(isA<BusyMarkException>()),
    );
    expect(File(target).existsSync(), isTrue);
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
    'Safe Delete finds and unlinks authored HTML anchors without literal false positives',
    () async {
      const referrerSource = '''
# Referrer

Read <a href="doomed.md">the old topic</a>.

Read <a href='doomed.md'>the single-quoted topic</a>.

Read <a class="external-ish" href=doomed.md title="Old">the unquoted topic</a>.

Read <a href="doomed.md#part"><strong>the old section</strong></a>.

Read <a href="doomed.md?mode=x#part">the queried section</a>.

<a href="doomed.md">One</a>

<a href="doomed.md">Two</a>

- Read <a href="doomed.md">the list topic</a>.

> Read <a href="doomed.md">the quoted topic</a>.

<a data-href="doomed.md">Not a topic link</a>

<a href="https://example.com/doomed.md">External</a>

![Image](image.png "<a href='doomed.md'>Image title</a>")

[Other](other.md "<a href='doomed.md'>Link title</a>")

`<a href="doomed.md">Inline example</a>`

<!-- <a href="doomed.md">Comment example</a> -->

```html
<a href="doomed.md">Fenced example</a>
```
''';
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
          'doomed.md': '# Doomed\n\n<snippet id="part">Part.</snippet>\n',
          'referrer.md': referrerSource,
        },
      );
      final doomed = _topic(fixture.module, 'doomed.md');
      final referrerPath = p.join(fixture.root.path, 'topics', 'referrer.md');
      final analysis = await service.analyze(
        module: fixture.module,
        topicPath: doomed.filePath,
        mode: WritersideTopicRemovalMode.safeDeleteFile,
      );
      final links = analysis.usages
          .where((usage) => usage.kind == WritersideTopicUsageKind.topicLink)
          .toList();

      expect(links, hasLength(9));
      expect(links.every((usage) => usage.relevant), isTrue);
      expect(
        links.map((usage) => usage.canUpdateAutomatically),
        everyElement(isTrue),
      );
      expect(
        links.map(
          (usage) => referrerSource.substring(
            usage.span!.startOffset,
            usage.span!.endOffset,
          ),
        ),
        [
          'doomed.md',
          'doomed.md',
          'doomed.md',
          'doomed.md#part',
          'doomed.md?mode=x#part',
          'doomed.md',
          'doomed.md',
          'doomed.md',
          'doomed.md',
        ],
      );
      expect(
        links.map((usage) => usage.span!.startOffset).toSet(),
        hasLength(9),
      );

      final result = await service.apply(
        WritersideTopicRemovalRequest(
          analysis: analysis,
          updateUsagesAutomatically: true,
        ),
      );

      expect(result.deletedFile, isTrue);
      expect(File(doomed.filePath).existsSync(), isFalse);
      expect(File(referrerPath).readAsStringSync(), '''
# Referrer

Read the old topic.

Read the single-quoted topic.

Read the unquoted topic.

Read <strong>the old section</strong>.

Read the queried section.

One

Two

- Read the list topic.

> Read the quoted topic.

<a data-href="doomed.md">Not a topic link</a>

<a href="https://example.com/doomed.md">External</a>

![Image](image.png "<a href='doomed.md'>Image title</a>")

[Other](other.md "<a href='doomed.md'>Link title</a>")

`<a href="doomed.md">Inline example</a>`

<!-- <a href="doomed.md">Comment example</a> -->

```html
<a href="doomed.md">Fenced example</a>
```
''');
      final reloaded = await const WritersideProjectService().load(
        fixture.root.path,
      );
      expect(
        reloaded.index.references.where(
          (reference) =>
              reference.kind == WritersideSymbolKind.topic &&
              reference.value.startsWith('doomed.md'),
        ),
        isEmpty,
      );
    },
  );

  test(
    'malformed authored HTML anchors are manual Safe Delete blockers',
    () async {
      final fixture = await _fixture(
        trees: {
          'guide.tree': '''
<instance-profile id="guide">
  <toc-element topic="doomed.md"/>
  <toc-element topic="referrer.md"/>
</instance-profile>
''',
        },
        configuredTrees: const ['guide.tree'],
        topics: {
          'doomed.md': '# Doomed\n',
          'referrer.md': '# Referrer\n\nRead <a href="doomed.md">unfinished.\n',
        },
      );
      final doomed = _topic(fixture.module, 'doomed.md');
      final before = File(doomed.filePath).readAsStringSync();
      final analysis = await service.analyze(
        module: fixture.module,
        topicPath: doomed.filePath,
        mode: WritersideTopicRemovalMode.safeDeleteFile,
      );
      final usage = analysis.usages.singleWhere(
        (candidate) => candidate.kind == WritersideTopicUsageKind.topicLink,
      );

      expect(usage.reference, 'doomed.md');
      expect(usage.canUpdateAutomatically, isFalse);
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
      expect(File(doomed.filePath).readAsStringSync(), before);
    },
  );

  test(
    'authored HTML variable hrefs are expanded and ambiguity blocks',
    () async {
      Future<WritersideTopicRemovalAnalysis> analyzeWithVariables(
        String variables,
      ) async {
        final fixture = await _fixture(
          trees: {
            'guide.tree': '''
<instance-profile id="guide">
  <toc-element topic="doomed.md"/>
  <toc-element topic="other.md"/>
  <toc-element topic="referrer.md"/>
</instance-profile>
''',
          },
          configuredTrees: const ['guide.tree'],
          variables: variables,
          topics: {
            'doomed.md': '# Doomed\n',
            'other.md': '# Other\n',
            'referrer.md': '# Referrer\n\n<a href="%target%">Target</a>\n',
          },
        );
        return service.analyze(
          module: fixture.module,
          topicPath: _topic(fixture.module, 'doomed.md').filePath,
          mode: WritersideTopicRemovalMode.safeDeleteFile,
        );
      }

      final unique = await analyzeWithVariables(
        '<vars><var name="target" value="doomed.md"/></vars>',
      );
      expect(
        unique.usages
            .singleWhere(
              (usage) => usage.kind == WritersideTopicUsageKind.topicLink,
            )
            .canUpdateAutomatically,
        isTrue,
      );
      final ambiguous = await analyzeWithVariables('''
<vars>
  <var name="target" value="doomed.md"/>
  <var name="target" value="other.md"/>
</vars>
''');
      expect(
        ambiguous.usages
            .singleWhere(
              (usage) => usage.kind == WritersideTopicUsageKind.topicLink,
            )
            .canUpdateAutomatically,
        isFalse,
      );
      expect(ambiguous.canUpdateUsagesAutomatically, isFalse);
    },
  );

  test(
    'authored HTML relevance follows its conditioned Markdown chapter',
    () async {
      final fixture = await _fixture(
        trees: {
          'user.tree': '''
<instance-profile id="user">
  <toc-element topic="referrer.md"/>
  <toc-element topic="doomed.md"/>
</instance-profile>
''',
          'admin.tree': '''
<instance-profile id="admin">
  <toc-element topic="referrer.md"/>
  <toc-element topic="doomed.md"/>
</instance-profile>
''',
        },
        configuredTrees: const ['user.tree', 'admin.tree'],
        topics: {
          'doomed.md': '# Doomed\n',
          'referrer.md': '''
# Referrer

## Admin {instance="admin"}

Read <a href="doomed.md">the admin topic</a>.
''',
        },
      );
      final target = _topic(fixture.module, 'doomed.md').filePath;
      final user = await service.analyze(
        module: fixture.module,
        topicPath: target,
        mode: WritersideTopicRemovalMode.removeFromInstance,
        selectedTreePath: p.join(fixture.root.path, 'user.tree'),
        selectedNodePath: const [1],
      );
      final admin = await service.analyze(
        module: fixture.module,
        topicPath: target,
        mode: WritersideTopicRemovalMode.removeFromInstance,
        selectedTreePath: p.join(fixture.root.path, 'admin.tree'),
        selectedNodePath: const [1],
      );

      expect(
        user.usages
            .singleWhere(
              (usage) => usage.kind == WritersideTopicUsageKind.topicLink,
            )
            .relevant,
        isFalse,
      );
      expect(
        admin.usages
            .singleWhere(
              (usage) => usage.kind == WritersideTopicUsageKind.topicLink,
            )
            .relevant,
        isTrue,
      );
    },
  );

  test('automatic HTML unlinking permits project-wide orphan status', () async {
    final fixture = await _fixture(
      trees: {
        'guide.tree': '''
<instance-profile id="guide">
  <toc-element topic="referrer.md"/>
  <toc-element topic="doomed.md"/>
</instance-profile>
''',
      },
      configuredTrees: const ['guide.tree'],
      topics: {
        'doomed.md': '# Doomed\n',
        'referrer.md': '# Referrer\n\n<a href="doomed.md">Old</a>\n',
      },
    );
    final target = _topic(fixture.module, 'doomed.md');
    final analysis = await service.analyze(
      module: fixture.module,
      topicPath: target.filePath,
      mode: WritersideTopicRemovalMode.removeFromInstance,
      selectedTreePath: p.join(fixture.root.path, 'guide.tree'),
      selectedNodePath: const [1],
    );

    final result = await service.apply(
      WritersideTopicRemovalRequest(
        analysis: analysis,
        updateUsagesAutomatically: true,
      ),
    );

    expect(result.orphaned, isTrue);
    expect(File(target.filePath).existsSync(), isTrue);
    expect(
      File(
        p.join(fixture.root.path, 'topics', 'referrer.md'),
      ).readAsStringSync(),
      '# Referrer\n\nOld\n',
    );
  });

  test('a surviving authored HTML link suppresses orphan status', () async {
    final fixture = await _fixture(
      trees: {
        'user.tree': '''
<instance-profile id="user">
  <toc-element topic="referrer.md"/>
  <toc-element topic="doomed.md"/>
</instance-profile>
''',
      },
      configuredTrees: const ['user.tree'],
      topics: {
        'doomed.md': '# Doomed\n',
        'referrer.md': '''
# Referrer

## Other instance {instance="admin"}

<a href="doomed.md">Old</a>
''',
      },
    );
    final target = _topic(fixture.module, 'doomed.md');
    final analysis = await service.analyze(
      module: fixture.module,
      topicPath: target.filePath,
      mode: WritersideTopicRemovalMode.removeFromInstance,
      selectedTreePath: p.join(fixture.root.path, 'user.tree'),
      selectedNodePath: const [1],
    );
    final link = analysis.usages.singleWhere(
      (usage) => usage.kind == WritersideTopicUsageKind.topicLink,
    );
    expect(link.relevant, isFalse);

    final result = await service.apply(
      WritersideTopicRemovalRequest(
        analysis: analysis,
        updateUsagesAutomatically: true,
      ),
    );

    expect(result.orphaned, isFalse);
    expect(File(target.filePath).existsSync(), isTrue);
    expect(
      File(
        p.join(fixture.root.path, 'topics', 'referrer.md'),
      ).readAsStringSync(),
      contains('<a href="doomed.md">Old</a>'),
    );
  });

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
        topicPath: _topic(fixture.module, 'Document_everything.topic').filePath,
        mode: WritersideTopicRemovalMode.safeDeleteFile,
      );
      expect(preprocessingDisabled.oldWebFileName, 'Document_everything.html');
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

  test('redirect preserves direct and rule-based accepted aliases', () async {
    final fixture = await _fixture(
      trees: {
        'guide.tree': '''
<instance-profile id="guide" name="Guide">
  <toc-element topic="doomed.md"
      accepts-web-file-names="older.html,legacy.html"
      accepts-web-file-names-ref="legacy-rule"/>
  <toc-element topic="replacement.md"/>
</instance-profile>
''',
      },
      configuredTrees: const ['guide.tree'],
      topics: {'doomed.md': '# Doomed\n', 'replacement.md': '# Replacement\n'},
    );
    File(p.join(fixture.root.path, 'redirection-rules.xml')).writeAsStringSync(
      '''
<redirection-rules>
  <rule id="legacy-rule"><accepts>very-old.html,oldest.html</accepts></rule>
</redirection-rules>
''',
    );
    final analysis = await service.analyze(
      module: fixture.module,
      topicPath: _topic(fixture.module, 'doomed.md').filePath,
      mode: WritersideTopicRemovalMode.removeFromInstance,
      selectedTreePath: p.join(fixture.root.path, 'guide.tree'),
      selectedNodePath: const [0],
    );
    final replacement = analysis.redirectTargets.singleWhere(
      (target) => target.topicFileName == 'replacement.md',
    );

    await service.apply(
      WritersideTopicRemovalRequest(
        analysis: analysis,
        redirectTarget: replacement,
      ),
    );
    final destination = _tree(
      fixture.root,
      'guide.tree',
    ).findAllElements('toc-element').single;
    expect(
      destination.getAttribute('accepts-web-file-names')!.split(',').toSet(),
      containsAll({
        'doomed.html',
        'older.html',
        'legacy.html',
        'very-old.html',
        'oldest.html',
      }),
    );
  });

  test('a transferred redirect alias collision fails before writes', () async {
    final fixture = await _fixture(
      trees: {
        'guide.tree': '''
<instance-profile id="guide" name="Guide">
  <toc-element topic="doomed.md" accepts-web-file-names="legacy.html"/>
  <toc-element topic="replacement.md"/>
  <toc-element topic="existing.md" accepts-web-file-names="legacy.html"/>
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
    final treePath = p.join(fixture.root.path, 'guide.tree');
    final before = File(treePath).readAsStringSync();
    final target = _topic(fixture.module, 'doomed.md');
    final analysis = await service.analyze(
      module: fixture.module,
      topicPath: target.filePath,
      mode: WritersideTopicRemovalMode.removeFromInstance,
      selectedTreePath: treePath,
      selectedNodePath: const [0],
    );
    final replacement = analysis.redirectTargets.singleWhere(
      (candidate) => candidate.topicFileName == 'replacement.md',
    );

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
    expect(File(treePath).readAsStringSync(), before);
    expect(File(target.filePath).existsSync(), isTrue);
  });

  test('redirect sources use each host instance web filename', () async {
    final fixture = await _fixture(
      trees: {
        'user.tree': '''
<instance-profile id="user" name="User">
  <toc-element topic="doomed.topic"/>
  <toc-element topic="replacement.md"/>
</instance-profile>
''',
        'admin.tree': '''
<instance-profile id="admin" name="Admin">
  <toc-element topic="doomed.topic"/>
  <toc-element topic="replacement.md"/>
</instance-profile>
''',
      },
      configuredTrees: const ['user.tree', 'admin.tree'],
      topics: {
        'doomed.topic': '''
<topic id="doomed" title="Doomed">
  <web-file-name instance="user">old-user.html</web-file-name>
  <web-file-name instance="admin">old-admin.html</web-file-name>
</topic>
''',
        'replacement.md': '# Replacement\n',
      },
    );
    final target = _topic(fixture.module, 'doomed.topic');
    final analysis = await service.analyze(
      module: fixture.module,
      topicPath: target.filePath,
      mode: WritersideTopicRemovalMode.safeDeleteFile,
    );
    final namesByTree = {
      for (final source in analysis.redirectSources)
        p.basename(source.treePath): source.acceptedWebFileNames.toSet(),
    };
    expect(namesByTree['user.tree'], contains('old-user.html'));
    expect(namesByTree['admin.tree'], contains('old-admin.html'));
    final replacement = analysis.redirectTargets.singleWhere(
      (candidate) => candidate.topicFileName == 'replacement.md',
    );

    await service.apply(
      WritersideTopicRemovalRequest(
        analysis: analysis,
        redirectTarget: replacement,
      ),
    );
    expect(File(target.filePath).existsSync(), isFalse);
    for (final entry in {
      'user.tree': 'old-user.html',
      'admin.tree': 'old-admin.html',
    }.entries) {
      final destination = _tree(
        fixture.root,
        entry.key,
      ).findAllElements('toc-element').single;
      expect(
        destination.getAttribute('accepts-web-file-names'),
        contains(entry.value),
      );
    }
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

  test('remove-from-instance relevance respects document conditions', () async {
    final fixture = await _fixture(
      trees: {
        'user.tree': '''
<instance-profile id="user" name="User">
  <toc-element topic="referrer.topic"/>
  <toc-element topic="doomed.md"/>
</instance-profile>
''',
        'admin.tree': '''
<instance-profile id="admin" name="Admin">
  <toc-element topic="referrer.topic"/>
  <toc-element topic="doomed.md"/>
</instance-profile>
''',
      },
      configuredTrees: const ['user.tree', 'admin.tree'],
      topics: {
        'doomed.md': '# Doomed\n',
        'referrer.topic': '''
<topic id="referrer" title="Referrer">
  <a href="doomed.md" instance="admin">Admin link</a>
  <section instance="admin">
    <include from="doomed.md" element-id="part"/>
  </section>
</topic>
''',
      },
    );
    final target = _topic(fixture.module, 'doomed.md').filePath;

    final user = await service.analyze(
      module: fixture.module,
      topicPath: target,
      mode: WritersideTopicRemovalMode.removeFromInstance,
      selectedTreePath: p.join(fixture.root.path, 'user.tree'),
      selectedNodePath: const [1],
    );
    final admin = await service.analyze(
      module: fixture.module,
      topicPath: target,
      mode: WritersideTopicRemovalMode.removeFromInstance,
      selectedTreePath: p.join(fixture.root.path, 'admin.tree'),
      selectedNodePath: const [1],
    );
    final userLink = user.usages.singleWhere(
      (usage) => usage.kind == WritersideTopicUsageKind.topicLink,
    );
    final adminLink = admin.usages.singleWhere(
      (usage) => usage.kind == WritersideTopicUsageKind.topicLink,
    );
    final userInclude = user.usages.singleWhere(
      (usage) => usage.kind == WritersideTopicUsageKind.include,
    );
    final adminInclude = admin.usages.singleWhere(
      (usage) => usage.kind == WritersideTopicUsageKind.include,
    );

    expect(userLink.relevant, isFalse);
    expect(adminLink.relevant, isTrue);
    expect(userInclude.relevant, isFalse);
    expect(adminInclude.relevant, isTrue);
  });

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

  test(
    'project analysis finds origin links, includes, cards, and ref TOC nodes',
    () async {
      final fixture = await _projectFixture(
        mainTree: '''
<instance-profile id="guide" name="Guide">
  <toc-element topic="guide.md"/>
</instance-profile>
''',
        sharedTree: '''
<instance-profile id="shared" name="Shared">
  <toc-element ref="guide.md" in="guide" origin="main"/>
  <toc-element topic="references.topic"/>
</instance-profile>
''',
        sharedTopic: '''
<topic id="references" title="References">
  <a href="guide.md" origin="main">Guide</a>
  <include from="guide.md" origin="main" element-id="part"/>
  <card href="guide.md" origin="main"><title>Guide</title></card>
</topic>
''',
      );
      final project = await const WritersideProjectService().load(
        fixture.root.path,
        preferredModuleRoot: fixture.mainRoot,
      );
      final target = project.modulesByOrigin['main']!.topics.single;
      final analysis = await service.analyze(
        project: project,
        projectRoot: fixture.root.path,
        topicPath: target.filePath,
        mode: WritersideTopicRemovalMode.safeDeleteFile,
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
      final card = analysis.usages.singleWhere(
        (usage) => usage.kind == WritersideTopicUsageKind.otherTopicReference,
      );
      expect(card.canUpdateAutomatically, isFalse);
      expect(analysis.canUpdateUsagesAutomatically, isFalse);
    },
  );

  test('authored Markdown HTML anchors resolve origin project-wide', () async {
    final fixture = await _projectFixture(
      mainTree: '''
<instance-profile id="guide"><toc-element topic="guide.md"/></instance-profile>
''',
      sharedTree: '''
<instance-profile id="shared"><toc-element topic="references.md"/></instance-profile>
''',
      sharedTopicFileName: 'references.md',
      sharedTopic: '''
# References

Main: <a href="guide.md" origin="main">Main guide</a>.

Other: <a href="guide.md" origin="other">Other guide</a>.
''',
    );
    final otherRoot = p.join(fixture.root.path, 'other');
    Directory(p.join(otherRoot, 'topics')).createSync(recursive: true);
    File(p.join(otherRoot, 'writerside.cfg')).writeAsStringSync('''
<ihp><module name="other"/><topics dir="topics"/><instance src="other.tree"/></ihp>
''');
    File(p.join(otherRoot, 'other.tree')).writeAsStringSync(
      '<instance-profile id="other"><toc-element topic="guide.md"/></instance-profile>\n',
    );
    File(
      p.join(otherRoot, 'topics', 'guide.md'),
    ).writeAsStringSync('# Other guide\n');
    final project = await const WritersideProjectService().load(
      fixture.root.path,
      preferredModuleRoot: fixture.mainRoot,
    );
    final target = project.modulesByOrigin['main']!.topics.single;
    final analysis = await service.analyze(
      project: project,
      projectRoot: fixture.root.path,
      topicPath: target.filePath,
      mode: WritersideTopicRemovalMode.safeDeleteFile,
    );
    final links = analysis.usages.where(
      (usage) => usage.kind == WritersideTopicUsageKind.topicLink,
    );

    expect(links, hasLength(1));
    expect(links.single.reference, 'guide.md');
    expect(links.single.canUpdateAutomatically, isTrue);
    await service.apply(
      WritersideTopicRemovalRequest(
        analysis: analysis,
        updateUsagesAutomatically: true,
      ),
    );
    expect(
      File(
        p.join(fixture.sharedRoot, 'topics', 'references.md'),
      ).readAsStringSync(),
      '''
# References

Main: Main guide.

Other: <a href="guide.md" origin="other">Other guide</a>.
''',
    );
  });

  test('safe delete updates automatic cross-module origin usages', () async {
    final fixture = await _projectFixture(
      mainTree: '''
<instance-profile id="guide" name="Guide">
  <toc-element topic="guide.md"/>
</instance-profile>
''',
      sharedTree: '''
<instance-profile id="shared" name="Shared">
  <toc-element topic="guide.md" origin="main"/>
  <toc-element ref="guide.md" in="guide" origin="main"/>
  <toc-element topic="references.topic"/>
</instance-profile>
''',
      sharedTopic: '''
<topic id="references" title="References">
  <p><a href="guide.md" origin="main">Guide text</a></p>
  <include from="guide.md" origin="main" element-id="part"/>
</topic>
''',
    );
    final project = await const WritersideProjectService().load(
      fixture.root.path,
      preferredModuleRoot: fixture.mainRoot,
    );
    final target = project.modulesByOrigin['main']!.topics.single;
    final analysis = await service.analyze(
      project: project,
      topicPath: target.filePath,
      mode: WritersideTopicRemovalMode.safeDeleteFile,
    );
    expect(analysis.canUpdateUsagesAutomatically, isTrue);

    await service.apply(
      WritersideTopicRemovalRequest(
        analysis: analysis,
        updateUsagesAutomatically: true,
      ),
    );
    expect(File(target.filePath).existsSync(), isFalse);
    final sharedSource = File(
      p.join(fixture.sharedRoot, 'topics', 'references.topic'),
    ).readAsStringSync();
    expect(sharedSource, contains('Guide text'));
    expect(sharedSource, isNot(contains('href="guide.md"')));
    expect(sharedSource, isNot(contains('<include')));
    expect(
      File(p.join(fixture.sharedRoot, 'shared.tree')).readAsStringSync(),
      isNot(contains('guide.md')),
    );
  });

  test(
    'selected ref node uses removal workflow and promotes its children',
    () async {
      final fixture = await _fixture(
        trees: {
          'guide.tree': '''
<instance-profile id="guide" name="Guide">
  <toc-element ref="doomed.md" in="guide">
    <toc-element topic="child.md"/>
  </toc-element>
</instance-profile>
''',
        },
        configuredTrees: const ['guide.tree'],
        topics: {'doomed.md': '# Doomed\n', 'child.md': '# Child\n'},
      );
      final doomed = _topic(fixture.module, 'doomed.md');
      final analysis = await service.analyze(
        module: fixture.module,
        topicPath: doomed.filePath,
        mode: WritersideTopicRemovalMode.removeFromInstance,
        selectedTreePath: p.join(fixture.root.path, 'guide.tree'),
        selectedNodePath: const [0],
      );
      expect(analysis.relevantUsages.single.reference, 'doomed.md');

      final result = await service.apply(
        WritersideTopicRemovalRequest(analysis: analysis),
      );
      expect(result.deletedFile, isFalse);
      expect(result.promotedChildren, 1);
      final tree = _tree(fixture.root, 'guide.tree');
      expect(
        tree.findAllElements('toc-element').single.getAttribute('topic'),
        'child.md',
      );
    },
  );

  test(
    'semantic tree scan includes hidden/build trees and excludes VCS metadata',
    () async {
      final fixture = await _fixture(
        trees: {
          'guide.tree': '''
<instance-profile id="guide" name="Guide"><toc-element topic="doomed.md"/></instance-profile>
''',
          'build/reusable.tree': '''
<instance-profile id="build" name="Build"><toc-element topic="doomed.md"/></instance-profile>
''',
          '.internal/shared.tree': '''
<instance-profile id="hidden" name="Hidden"><toc-element topic="doomed.md"/></instance-profile>
''',
          '.git/ignored.tree': '''
<instance-profile id="git" name="Git"><toc-element topic="doomed.md"/></instance-profile>
''',
          '.hg/ignored.tree': '''
<instance-profile id="hg" name="Hg"><toc-element topic="doomed.md"/></instance-profile>
''',
          '.svn/ignored.tree': '''
<instance-profile id="svn" name="Svn"><toc-element topic="doomed.md"/></instance-profile>
''',
        },
        configuredTrees: const ['guide.tree'],
        topics: {'doomed.md': '# Doomed\n'},
      );
      final analysis = await service.analyze(
        module: fixture.module,
        topicPath: _topic(fixture.module, 'doomed.md').filePath,
        mode: WritersideTopicRemovalMode.safeDeleteFile,
      );
      final treePaths = analysis.usages
          .where((usage) => usage.kind == WritersideTopicUsageKind.tocElement)
          .map((usage) => p.relative(usage.filePath, from: fixture.root.path))
          .toSet();
      expect(
        treePaths,
        containsAll([
          'guide.tree',
          'build/reusable.tree',
          '.internal/shared.tree',
        ]),
      );
      expect(treePaths, isNot(contains('.git/ignored.tree')));
      expect(treePaths, isNot(contains('.hg/ignored.tree')));
      expect(treePaths, isNot(contains('.svn/ignored.tree')));
    },
  );

  test('a new module after analysis makes the reviewed plan stale', () async {
    final fixture = await _projectFixture(
      mainTree: '''
<instance-profile id="guide" name="Guide"><toc-element topic="guide.md"/></instance-profile>
''',
      sharedTree: '''
<instance-profile id="shared" name="Shared"/>
''',
      sharedTopic: '<topic id="references" title="References"/>',
    );
    final project = await const WritersideProjectService().load(
      fixture.root.path,
      preferredModuleRoot: fixture.mainRoot,
    );
    final target = project.modulesByOrigin['main']!.topics.single;
    final analysis = await service.analyze(
      project: project,
      topicPath: target.filePath,
      mode: WritersideTopicRemovalMode.safeDeleteFile,
    );
    final lateRoot = Directory(p.join(fixture.root.path, 'late'))..createSync();
    Directory(p.join(lateRoot.path, 'topics')).createSync();
    File(p.join(lateRoot.path, 'writerside.cfg')).writeAsStringSync(
      '<ihp><module name="late"/><topics dir="topics"/></ihp>',
    );
    File(p.join(lateRoot.path, 'topics', 'late.topic')).writeAsStringSync(
      '<topic id="late"><a href="guide.md" origin="main">Guide</a></topic>',
    );

    await expectLater(
      service.apply(WritersideTopicRemovalRequest(analysis: analysis)),
      throwsA(isA<BusyMarkException>()),
    );
    expect(File(target.filePath).existsSync(), isTrue);
  });

  test(
    'cross-module failure rolls back BusyMark edits without overwriting a concurrent edit',
    () async {
      final fixture = await _projectFixture(
        mainTree: '''
<instance-profile id="guide" name="Guide"><toc-element topic="guide.md"/></instance-profile>
''',
        sharedTree: '''
<instance-profile id="shared" name="Shared">
  <toc-element topic="guide.md" origin="main"/>
  <toc-element topic="references.topic"/>
</instance-profile>
''',
        sharedTopic: '''
<topic id="references" title="References">
  <a href="guide.md" origin="main">Guide</a>
</topic>
''',
      );
      final project = await const WritersideProjectService().load(
        fixture.root.path,
        preferredModuleRoot: fixture.mainRoot,
      );
      final target = project.modulesByOrigin['main']!.topics.single;
      final analysis = await service.analyze(
        project: project,
        topicPath: target.filePath,
        mode: WritersideTopicRemovalMode.safeDeleteFile,
      );
      final mutablePaths = <String>[
        p.join(fixture.mainRoot, 'guide.tree'),
        p.join(fixture.sharedRoot, 'shared.tree'),
        p.join(fixture.sharedRoot, 'topics', 'references.topic'),
      ];
      final originals = {
        for (final path in mutablePaths) path: File(path).readAsStringSync(),
      };
      String? concurrentlyEdited;

      await expectLater(
        service.apply(
          WritersideTopicRemovalRequest(
            analysis: analysis,
            updateUsagesAutomatically: true,
          ),
          validateBeforeCommit: (_) {
            if (concurrentlyEdited != null) return;
            for (final entry in originals.entries) {
              if (File(entry.key).readAsStringSync() == entry.value) continue;
              concurrentlyEdited = entry.key;
              File(entry.key).writeAsStringSync('<!-- concurrent edit -->\n');
              throw const BusyMarkException('test.concurrent-edit');
            }
          },
        ),
        throwsA(isA<BusyMarkException>()),
      );

      expect(concurrentlyEdited, isNotNull);
      expect(
        File(concurrentlyEdited!).readAsStringSync(),
        '<!-- concurrent edit -->\n',
      );
      for (final entry in originals.entries) {
        if (entry.key == concurrentlyEdited) continue;
        expect(File(entry.key).readAsStringSync(), entry.value);
      }
      expect(File(target.filePath).existsSync(), isTrue);
    },
  );
}

Future<({Directory root, String mainRoot, String sharedRoot})> _projectFixture({
  required String mainTree,
  required String sharedTree,
  required String sharedTopic,
  String sharedTopicFileName = 'references.topic',
}) async {
  final root = await Directory.systemTemp.createTemp(
    'busymark-removal-project-',
  );
  addTearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });
  final mainRoot = p.join(root.path, 'main');
  final sharedRoot = p.join(root.path, 'shared');
  Directory(p.join(mainRoot, 'topics')).createSync(recursive: true);
  Directory(p.join(sharedRoot, 'topics')).createSync(recursive: true);
  File(p.join(mainRoot, 'writerside.cfg')).writeAsStringSync(
    '<ihp><module name="main"/><topics dir="topics"/><instance src="guide.tree"/></ihp>',
  );
  File(p.join(sharedRoot, 'writerside.cfg')).writeAsStringSync(
    '<ihp><module name="shared"/><topics dir="topics"/><instance src="shared.tree"/></ihp>',
  );
  File(p.join(mainRoot, 'guide.tree')).writeAsStringSync(mainTree.trimLeft());
  File(
    p.join(sharedRoot, 'shared.tree'),
  ).writeAsStringSync(sharedTree.trimLeft());
  File(
    p.join(mainRoot, 'topics', 'guide.md'),
  ).writeAsStringSync('# Guide\n\n<snippet id="part">Reusable.</snippet>\n');
  File(
    p.join(sharedRoot, 'topics', sharedTopicFileName),
  ).writeAsStringSync(sharedTopic.trimLeft());
  final canonicalRoot = Directory(await root.resolveSymbolicLinks());
  return (
    root: canonicalRoot,
    mainRoot: p.join(canonicalRoot.path, 'main'),
    sharedRoot: p.join(canonicalRoot.path, 'shared'),
  );
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
    final file = File(p.join(root.path, entry.key));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(entry.value.trimLeft());
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
