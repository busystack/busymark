import 'dart:io';

import 'package:busymark/src/core/busymark_exception.dart';
import 'package:busymark/src/core/path_utils.dart';
import 'package:busymark/src/writerside/writerside_instance_service.dart';
import 'package:busymark/src/writerside/writerside_model.dart';
import 'package:busymark/src/writerside/writerside_module_service.dart';
import 'package:busymark/src/writerside/writerside_topic_creator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

void main() {
  const moduleService = WritersideModuleService();
  const instanceService = WritersideInstanceService();

  test('creates and registers an empty instance with build settings', () async {
    final root = await _project();
    addTearDown(() => root.deleteSync(recursive: true));
    final module = await moduleService.load(root.path);

    final result = await instanceService.create(
      module: module,
      request: const WritersideInstanceCreateRequest(
        settings: WritersideInstanceSettings(
          name: 'Administrator Guide',
          id: 'admin',
          version: '2.0',
          webPath: '/admin/',
          status: WritersideInstanceStatus.eap,
          allowSearchEngineIndexing: true,
          offlineArtifact: true,
        ),
      ),
    );

    expect(result.treePath, p.join(root.path, 'admin.tree'));
    final config = XmlDocument.parse(
      File(p.join(root.path, 'writerside.cfg')).readAsStringSync(),
    );
    final entry = config.rootElement.childElements
        .where((element) => element.name.local == 'instance')
        .last;
    expect(entry.getAttribute('src'), 'admin.tree');
    expect(entry.getAttribute('version'), '2.0');
    expect(entry.getAttribute('web-path'), '/admin/');

    final tree = XmlDocument.parse(File(result.treePath).readAsStringSync());
    expect(tree.rootElement.getAttribute('id'), 'admin');
    expect(tree.rootElement.getAttribute('name'), 'Administrator Guide');
    expect(tree.rootElement.getAttribute('status'), 'eap');
    expect(tree.rootElement.getAttribute('start-page'), isNull);
    expect(tree.rootElement.childElements, isEmpty);

    final refreshed = await moduleService.load(root.path);
    final created = refreshed.instances.singleWhere(
      (instance) => instance.id == 'admin',
    );
    expect(created.version, '2.0');
    expect(created.webPath, '/admin/');
    expect(created.allowSearchEngineIndexing, isTrue);
    expect(created.offlineArtifact, isTrue);
    expect(
      created.diagnostics.map((diagnostic) => diagnostic.code),
      isNot(contains('writerside.tree.missing-start-page')),
    );
  });

  test('creates a non-publishing TOC library instance', () async {
    final root = await _project();
    addTearDown(() => root.deleteSync(recursive: true));

    await instanceService.create(
      module: await moduleService.load(root.path),
      request: const WritersideInstanceCreateRequest(
        settings: WritersideInstanceSettings(
          name: 'Shared sections',
          id: 'shared',
        ),
        isLibrary: true,
      ),
    );

    final tree = XmlDocument.parse(
      File(p.join(root.path, 'shared.tree')).readAsStringSync(),
    );
    expect(tree.rootElement.getAttribute('is-library'), 'true');
    expect(tree.rootElement.getAttribute('start-page'), isNull);
    expect(
      (await moduleService.load(root.path)).instances.last.isLibrary,
      isTrue,
    );
  });

  test('imports selected Markdown and its referenced local media', () async {
    final root = await _project();
    final source = await Directory.systemTemp.createTemp(
      'busymark-instance-import-',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    addTearDown(() => source.deleteSync(recursive: true));
    Directory(
      p.join(source.path, 'guide', 'images'),
    ).createSync(recursive: true);
    final first = File(p.join(source.path, 'guide', 'imported-intro.md'))
      ..writeAsStringSync('''# Imported intro

![Logo](images/logo.png)

<video src="images/demo.mp4"
       preview-src="images/demo.png"/>
''');
    File(
      p.join(source.path, 'guide', 'other.md'),
    ).writeAsStringSync('# Other\n');
    File(
      p.join(source.path, 'guide', 'images', 'logo.png'),
    ).writeAsBytesSync([1, 2, 3]);
    File(
      p.join(source.path, 'guide', 'images', 'demo.mp4'),
    ).writeAsBytesSync([4, 5, 6]);
    File(
      p.join(source.path, 'guide', 'images', 'demo.png'),
    ).writeAsBytesSync([7, 8, 9]);

    final candidates = await instanceService.discoverMarkdownFiles(source.path);
    expect(candidates.map((candidate) => candidate.relativePath), [
      'guide/imported-intro.md',
      'guide/other.md',
    ]);
    expect(candidates.first.title, 'Imported intro');

    final result = await instanceService.create(
      module: await moduleService.load(root.path),
      request: WritersideInstanceCreateRequest(
        settings: const WritersideInstanceSettings(
          name: 'Imported Guide',
          id: 'imported',
        ),
        importRootPath: source.path,
        importedMarkdownPaths: [first.path],
      ),
    );

    expect(
      result.firstTopicPath,
      p.join(root.path, 'topics', 'guide', 'imported-intro.md'),
    );
    expect(
      File(result.firstTopicPath!).readAsStringSync(),
      contains('# Imported'),
    );
    expect(
      File(
        p.join(root.path, 'topics', 'guide', 'images', 'logo.png'),
      ).readAsBytesSync(),
      [1, 2, 3],
    );
    expect(
      File(
        p.join(root.path, 'topics', 'guide', 'images', 'demo.mp4'),
      ).readAsBytesSync(),
      [4, 5, 6],
    );
    expect(
      File(
        p.join(root.path, 'topics', 'guide', 'images', 'demo.png'),
      ).readAsBytesSync(),
      [7, 8, 9],
    );
    expect(
      File(p.join(root.path, 'topics', 'guide', 'other.md')).existsSync(),
      isFalse,
    );
    final tree = XmlDocument.parse(
      File(p.join(root.path, 'imported.tree')).readAsStringSync(),
    );
    expect(
      tree.rootElement.getAttribute('start-page'),
      'guide/imported-intro.md',
    );
    expect(
      tree.rootElement.childElements.single.getAttribute('topic'),
      'guide/imported-intro.md',
    );
  });

  test(
    'renames an instance and refactors documented project references',
    () async {
      final root = await _project();
      addTearDown(() => root.deleteSync(recursive: true));
      File(p.join(root.path, 'other.tree')).writeAsStringSync('''
<instance-profile id="other" name="Other" start-page="intro.md">
  <toc-element ref="intro.md" in="guide" instance="guide,!ignored"/>
  <include from="guide.tree" element-id="shared"/>
</instance-profile>
''');
      File(p.join(root.path, 'topics', 'conditional.md')).writeAsStringSync('''
# Conditional

<title instance="guide">Guide title</title>

Text {instance="!guide,other"}

`<title instance="guide">Example</title>`

```xml
<title instance="guide">Example</title>
```
''');
      Directory(p.join(root.path, 'cfg')).createSync();
      File(p.join(root.path, 'cfg', 'buildprofiles.xml')).writeAsStringSync('''
<buildprofiles>
  <icons><local-src instance="guide">instance-icons</local-src></icons>
  <build-profile instance="guide">
    <variables><product-web-url>https://example.test</product-web-url></variables>
  </build-profile>
  <property-bundles>
    <property-file instance="guide">guide.properties</property-file>
  </property-bundles>
</buildprofiles>
''');
      File(p.join(root.path, 'instance-groups.xml')).writeAsStringSync('''
<instance-groups><group id="all" instances="guide,other"/></instance-groups>
''');
      File(p.join(root.path, 'publish.sh')).writeAsStringSync('build guide\n');
      final config = File(p.join(root.path, 'writerside.cfg'));
      config.writeAsStringSync(
        config.readAsStringSync().replaceFirst(
          '<instance src="guide.tree"/>',
          '<instance-groups src="instance-groups.xml"/>\n'
              '  <instance src="guide.tree"/>\n'
              '  <instance src="other.tree"/>',
        ),
      );
      final module = await moduleService.load(root.path);
      final guide = module.instances.singleWhere(
        (instance) => instance.id == 'guide',
      );

      final result = await instanceService.update(
        module: module,
        request: WritersideInstanceUpdateRequest(
          treePath: guide.sourceTreePath,
          settings: const WritersideInstanceSettings(
            name: 'Product Guide',
            id: 'product',
            status: WritersideInstanceStatus.deprecated,
          ),
        ),
      );

      expect(result.treePath, p.join(root.path, 'product.tree'));
      expect(File(p.join(root.path, 'guide.tree')).existsSync(), isFalse);
      final otherTree = File(
        p.join(root.path, 'other.tree'),
      ).readAsStringSync();
      expect(otherTree, contains('in="product"'));
      expect(otherTree, contains('instance="product,!ignored"'));
      expect(otherTree, contains('from="product.tree"'));
      final markdown = File(
        p.join(root.path, 'topics', 'conditional.md'),
      ).readAsStringSync();
      expect(
        markdown,
        contains('<title instance="product">Guide title</title>'),
      );
      expect(markdown, contains('{instance="!product,other"}'));
      expect(
        '<title instance="guide">Example</title>'.allMatches(markdown),
        hasLength(2),
      );
      expect(
        File(p.join(root.path, 'instance-groups.xml')).readAsStringSync(),
        contains('instances="product,other"'),
      );
      final buildProfiles = File(
        p.join(root.path, 'cfg', 'buildprofiles.xml'),
      ).readAsStringSync();
      expect('instance="product"'.allMatches(buildProfiles), hasLength(3));
      expect(buildProfiles, isNot(contains('instance="guide"')));
      expect(
        File(p.join(root.path, 'publish.sh')).readAsStringSync(),
        'build guide\n',
      );
      final refreshed = await moduleService.load(root.path);
      final renamed = refreshed.instances.singleWhere(
        (instance) => instance.id == 'product',
      );
      expect(renamed.name, 'Product Guide');
      expect(renamed.status, 'deprecated');
    },
  );

  test(
    'first topic added to an empty instance becomes its home page',
    () async {
      final root = await _project();
      addTearDown(() => root.deleteSync(recursive: true));
      await instanceService.create(
        module: await moduleService.load(root.path),
        request: const WritersideInstanceCreateRequest(
          settings: WritersideInstanceSettings(name: 'Empty', id: 'empty'),
        ),
      );
      final module = await moduleService.load(root.path);
      const creator = WritersideTopicCreator();

      await creator.create(
        WritersideTopicCreateTarget(
          rootPath: root.path,
          treePath: p.join(root.path, 'empty.tree'),
          topicsRootDir: 'topics',
          existingTopicIds: {for (final topic in module.topics) topic.id},
        ),
        const WritersideTopicCreateRequest(
          title: 'First page',
          fileName: 'first-page.md',
          format: WritersideTopicFormat.markdown,
          placement: WritersideTopicCreatePlacement.root,
        ),
      );

      final tree = XmlDocument.parse(
        File(p.join(root.path, 'empty.tree')).readAsStringSync(),
      );
      expect(tree.rootElement.getAttribute('start-page'), 'first-page.md');
    },
  );

  test(
    'invalid project XML blocks an instance ID refactor without changing files',
    () async {
      final root = await _project();
      addTearDown(() => root.deleteSync(recursive: true));
      final config = File(p.join(root.path, 'writerside.cfg'));
      final tree = File(p.join(root.path, 'guide.tree'));
      final originalConfig = config.readAsStringSync();
      final originalTree = tree.readAsStringSync();
      File(
        p.join(root.path, 'unreadable.tree'),
      ).writeAsStringSync('<instance-profile');

      await expectLater(
        instanceService.update(
          module: await moduleService.load(root.path),
          request: WritersideInstanceUpdateRequest(
            treePath: tree.path,
            settings: const WritersideInstanceSettings(
              name: 'Product Guide',
              id: 'product',
            ),
          ),
        ),
        throwsA(
          isA<BusyMarkException>().having(
            (error) => error.code,
            'code',
            'writerside.instance.configuration-invalid',
          ),
        ),
      );

      expect(config.readAsStringSync(), originalConfig);
      expect(tree.readAsStringSync(), originalTree);
      expect(File(p.join(root.path, 'product.tree')).existsSync(), isFalse);
    },
  );

  test(
    'concurrent config change prevents every instance publication',
    () async {
      final root = await _project();
      addTearDown(() => root.deleteSync(recursive: true));
      final config = File(p.join(root.path, 'writerside.cfg'));
      final service = WritersideInstanceService(
        beforePublish: () async => config.writeAsString(
          '${config.readAsStringSync()}<!-- concurrent -->\n',
        ),
      );

      await expectLater(
        service.create(
          module: await moduleService.load(root.path),
          request: const WritersideInstanceCreateRequest(
            settings: WritersideInstanceSettings(
              name: 'Blocked',
              id: 'blocked',
            ),
          ),
        ),
        throwsA(anything),
      );

      expect(File(p.join(root.path, 'blocked.tree')).existsSync(), isFalse);
      expect(config.readAsStringSync(), contains('concurrent'));
    },
  );

  group('existing-instance Markdown topic import', () {
    test(
      'copies selected topics, media, and inserts root entries in order',
      () async {
        final root = await _project();
        final source = await Directory.systemTemp.createTemp(
          'busymark-topic-import-',
        );
        addTearDown(() => root.deleteSync(recursive: true));
        addTearDown(() => source.deleteSync(recursive: true));
        Directory(
          p.join(source.path, 'nested', 'media'),
        ).createSync(recursive: true);
        final one = File(p.join(source.path, 'one.md'))
          ..writeAsStringSync('# One\n\n![shared](nested/media/shared.png)\n');
        File(p.join(source.path, 'skip.md')).writeAsStringSync('# Skip\n');
        final two = File(p.join(source.path, 'nested', 'two.md'))
          ..writeAsStringSync('''# Two

<video src="media/video.mp4" preview-src="media/shared.png"/>
''');
        File(
          p.join(source.path, 'nested', 'media', 'shared.png'),
        ).writeAsBytesSync([1, 2, 3]);
        File(
          p.join(source.path, 'nested', 'media', 'video.mp4'),
        ).writeAsBytesSync([4, 5, 6]);

        final result = await instanceService.addMarkdownTopics(
          module: await moduleService.load(root.path),
          request: WritersideMarkdownTopicImportRequest(
            sourceRootPath: source.path,
            selectedMarkdownPaths: [one.path, two.path],
            treePath: p.join(root.path, 'guide.tree'),
            placement: WritersideTopicCreatePlacement.root,
          ),
        );

        expect(result.importedTopicPaths, [
          p.join(root.path, 'topics', 'one.md'),
          p.join(root.path, 'topics', 'nested', 'two.md'),
        ]);
        expect(result.firstTopicPath, result.importedTopicPaths.first);
        expect(
          File(result.importedTopicPaths[0]).readAsBytesSync(),
          one.readAsBytesSync(),
        );
        expect(
          File(result.importedTopicPaths[1]).readAsBytesSync(),
          two.readAsBytesSync(),
        );
        expect(
          File(p.join(root.path, 'topics', 'skip.md')).existsSync(),
          isFalse,
        );
        expect(
          File(
            p.join(root.path, 'topics', 'nested', 'media', 'shared.png'),
          ).readAsBytesSync(),
          [1, 2, 3],
        );
        expect(
          File(
            p.join(root.path, 'topics', 'nested', 'media', 'video.mp4'),
          ).readAsBytesSync(),
          [4, 5, 6],
        );
        final updatedTree = XmlDocument.parse(
          File(result.treePath).readAsStringSync(),
        );
        final topics = updatedTree.rootElement.childElements
            .where((element) => element.name.local == 'toc-element')
            .map((element) => element.getAttribute('topic'));
        expect(topics, ['intro.md', 'one.md', 'nested/two.md']);
        expect(updatedTree.rootElement.getAttribute('start-page'), 'intro.md');
      },
    );

    test(
      'inserts several siblings after the exact reference in list order',
      () async {
        final root = await _project();
        final source = await Directory.systemTemp.createTemp(
          'busymark-topic-import-',
        );
        addTearDown(() => root.deleteSync(recursive: true));
        addTearDown(() => source.deleteSync(recursive: true));
        final tree = File(p.join(root.path, 'guide.tree'))
          ..writeAsStringSync('''
<instance-profile id="guide" name="Guide" start-page="a.md">
  <toc-element id="a" topic="a.md"/>
  <toc-element id="b" topic="b.md"/>
  <toc-element id="c" topic="c.md"/>
</instance-profile>
''');
        final paths = <String>[];
        for (final name in ['one', 'two', 'three']) {
          paths.add(
            (File(
              p.join(source.path, '$name.md'),
            )..writeAsStringSync('# $name\n')).path,
          );
        }

        await instanceService.addMarkdownTopics(
          module: await moduleService.load(root.path),
          request: WritersideMarkdownTopicImportRequest(
            sourceRootPath: source.path,
            selectedMarkdownPaths: paths,
            treePath: tree.path,
            placement: WritersideTopicCreatePlacement.sibling,
            referenceTocPath: const [1],
            referenceTocIdentity: const WritersideTocNodeIdentity(
              id: 'b',
              topicFileName: 'b.md',
              hidden: false,
            ),
          ),
        );

        expect(
          XmlDocument.parse(tree.readAsStringSync()).rootElement.childElements
              .map((element) => element.getAttribute('topic')),
          ['a.md', 'b.md', 'one.md', 'two.md', 'three.md', 'c.md'],
        );
      },
    );

    test(
      'initializes only the first imported topic as the start page',
      () async {
        final root = await _project();
        final source = await Directory.systemTemp.createTemp(
          'busymark-topic-import-',
        );
        addTearDown(() => root.deleteSync(recursive: true));
        addTearDown(() => source.deleteSync(recursive: true));
        final tree = File(p.join(root.path, 'guide.tree'))
          ..writeAsStringSync('<instance-profile id="guide" name="Guide"/>\n');
        final one = File(p.join(source.path, 'one.md'))
          ..writeAsStringSync('# One\n');
        final two = File(p.join(source.path, 'two.md'))
          ..writeAsStringSync('# Two\n');

        await instanceService.addMarkdownTopics(
          module: await moduleService.load(root.path),
          request: WritersideMarkdownTopicImportRequest(
            sourceRootPath: source.path,
            selectedMarkdownPaths: [one.path, two.path],
            treePath: tree.path,
            placement: WritersideTopicCreatePlacement.root,
          ),
        );

        expect(
          XmlDocument.parse(
            tree.readAsStringSync(),
          ).rootElement.getAttribute('start-page'),
          'one.md',
        );
      },
    );

    test(
      'rejects batch, existing-ID, target, and invalid-name conflicts',
      () async {
        Future<void> verify(
          Future<void> Function(Directory root, Directory source) action,
        ) async {
          final root = await _project();
          final source = await Directory.systemTemp.createTemp(
            'busymark-topic-import-',
          );
          addTearDown(() => root.deleteSync(recursive: true));
          addTearDown(() => source.deleteSync(recursive: true));
          final tree = File(p.join(root.path, 'guide.tree'));
          final originalTree = tree.readAsStringSync();
          await action(root, source);
          expect(tree.readAsStringSync(), originalTree);
        }

        await verify((root, source) async {
          Directory(p.join(source.path, 'a')).createSync();
          Directory(p.join(source.path, 'b')).createSync();
          final first = File(p.join(source.path, 'a', 'guide.md'))
            ..writeAsStringSync('# A\n');
          final second = File(p.join(source.path, 'b', 'guide.md'))
            ..writeAsStringSync('# B\n');
          await expectLater(
            instanceService.addMarkdownTopics(
              module: await moduleService.load(root.path),
              request: WritersideMarkdownTopicImportRequest(
                sourceRootPath: source.path,
                selectedMarkdownPaths: [first.path, second.path],
                treePath: p.join(root.path, 'guide.tree'),
                placement: WritersideTopicCreatePlacement.root,
              ),
            ),
            throwsA(
              isA<BusyMarkException>().having(
                (error) => error.code,
                'code',
                'writerside.topic.id-exists',
              ),
            ),
          );
          expect(
            File(p.join(root.path, 'topics', 'a', 'guide.md')).existsSync(),
            false,
          );
        });

        await verify((root, source) async {
          File(
            p.join(root.path, 'topics', 'guide.topic'),
          ).writeAsStringSync('<topic id="guide" title="Guide"/>');
          final imported = File(p.join(source.path, 'guide.md'))
            ..writeAsStringSync('# Guide\n');
          await expectLater(
            instanceService.addMarkdownTopics(
              module: await moduleService.load(root.path),
              request: WritersideMarkdownTopicImportRequest(
                sourceRootPath: source.path,
                selectedMarkdownPaths: [imported.path],
                treePath: p.join(root.path, 'guide.tree'),
                placement: WritersideTopicCreatePlacement.root,
              ),
            ),
            throwsA(
              isA<BusyMarkException>().having(
                (error) => error.code,
                'code',
                'writerside.topic.id-exists',
              ),
            ),
          );
        });

        await verify((root, source) async {
          final imported = File(p.join(source.path, 'intro.md'))
            ..writeAsStringSync('# Replacement\n');
          await expectLater(
            instanceService.addMarkdownTopics(
              module: await moduleService.load(root.path),
              request: WritersideMarkdownTopicImportRequest(
                sourceRootPath: source.path,
                selectedMarkdownPaths: [imported.path],
                treePath: p.join(root.path, 'guide.tree'),
                placement: WritersideTopicCreatePlacement.root,
              ),
            ),
            throwsA(isA<BusyMarkException>()),
          );
          expect(
            File(p.join(root.path, 'topics', 'intro.md')).readAsStringSync(),
            '# Intro\n',
          );
        });

        await verify((root, source) async {
          final imported = File(p.join(source.path, 'bad name.md'))
            ..writeAsStringSync('# Bad\n');
          await expectLater(
            instanceService.addMarkdownTopics(
              module: await moduleService.load(root.path),
              request: WritersideMarkdownTopicImportRequest(
                sourceRootPath: source.path,
                selectedMarkdownPaths: [imported.path],
                treePath: p.join(root.path, 'guide.tree'),
                placement: WritersideTopicCreatePlacement.root,
              ),
            ),
            throwsA(
              isA<BusyMarkException>().having(
                (error) => error.args['path'],
                'source path',
                imported.path,
              ),
            ),
          );
        });
      },
    );

    test('accepts a Unicode topic filename', () async {
      final root = await _project();
      final source = await Directory.systemTemp.createTemp(
        'busymark-topic-import-',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      addTearDown(() => source.deleteSync(recursive: true));
      final imported = File(p.join(source.path, '開始.md'))
        ..writeAsStringSync('# 開始\n');

      await instanceService.addMarkdownTopics(
        module: await moduleService.load(root.path),
        request: WritersideMarkdownTopicImportRequest(
          sourceRootPath: source.path,
          selectedMarkdownPaths: [imported.path],
          treePath: p.join(root.path, 'guide.tree'),
          placement: WritersideTopicCreatePlacement.root,
        ),
      );

      expect(File(p.join(root.path, 'topics', '開始.md')).existsSync(), true);
    });

    test(
      'rejects a stale reference identity without publishing files',
      () async {
        final root = await _project();
        final source = await Directory.systemTemp.createTemp(
          'busymark-topic-import-',
        );
        addTearDown(() => root.deleteSync(recursive: true));
        addTearDown(() => source.deleteSync(recursive: true));
        final imported = File(p.join(source.path, 'one.md'))
          ..writeAsStringSync('# One\n');
        final tree = File(p.join(root.path, 'guide.tree'));
        final originalTree = tree.readAsStringSync();

        await expectLater(
          instanceService.addMarkdownTopics(
            module: await moduleService.load(root.path),
            request: WritersideMarkdownTopicImportRequest(
              sourceRootPath: source.path,
              selectedMarkdownPaths: [imported.path],
              treePath: tree.path,
              placement: WritersideTopicCreatePlacement.sibling,
              referenceTocPath: const [0],
              referenceTocIdentity: const WritersideTocNodeIdentity(
                topicFileName: 'different.md',
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
        expect(File(p.join(root.path, 'topics', 'one.md')).existsSync(), false);
        expect(tree.readAsStringSync(), originalTree);
      },
    );

    test('discovered-but-unparsed topic basename blocks import', () async {
      final root = await _project();
      final source = await Directory.systemTemp.createTemp(
        'busymark-topic-import-',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      addTearDown(() => source.deleteSync(recursive: true));
      File(p.join(root.path, 'topics', 'guide.topic')).writeAsStringSync(
        '<topic id="guide" title="Guide">${'<p>x</p>' * 200}</topic>',
      );
      final imported = File(p.join(source.path, 'guide.md'))
        ..writeAsStringSync('# Guide\n');
      const limitedModuleService = WritersideModuleService(
        scanOptions: WorkspaceScanOptions(maxParsedDocuments: 0),
      );
      const limitedService = WritersideInstanceService(
        moduleService: limitedModuleService,
      );
      final module = await limitedModuleService.load(root.path);
      expect(module.unparsedTopicReferences, contains('guide.topic'));

      await expectLater(
        limitedService.addMarkdownTopics(
          module: module,
          request: WritersideMarkdownTopicImportRequest(
            sourceRootPath: source.path,
            selectedMarkdownPaths: [imported.path],
            treePath: p.join(root.path, 'guide.tree'),
            placement: WritersideTopicCreatePlacement.root,
          ),
        ),
        throwsA(
          isA<BusyMarkException>().having(
            (error) => error.code,
            'code',
            'writerside.topic.id-exists',
          ),
        ),
      );
    });

    test('fails closed when semantic topic discovery is incomplete', () async {
      final root = await _project();
      final source = await Directory.systemTemp.createTemp(
        'busymark-topic-import-',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      addTearDown(() => source.deleteSync(recursive: true));
      final imported = File(p.join(source.path, 'one.md'))
        ..writeAsStringSync('# One\n');
      const limitedModuleService = WritersideModuleService(
        scanOptions: WorkspaceScanOptions(maxTreeEntries: 1),
      );
      const limitedService = WritersideInstanceService(
        moduleService: limitedModuleService,
      );

      await expectLater(
        limitedService.addMarkdownTopics(
          module: await limitedModuleService.load(root.path),
          request: WritersideMarkdownTopicImportRequest(
            sourceRootPath: source.path,
            selectedMarkdownPaths: [imported.path],
            treePath: p.join(root.path, 'guide.tree'),
            placement: WritersideTopicCreatePlacement.root,
          ),
        ),
        throwsA(
          isA<BusyMarkException>().having(
            (error) => error.code,
            'code',
            'writerside.topic.discovery-incomplete',
          ),
        ),
      );
      expect(File(p.join(root.path, 'topics', 'one.md')).existsSync(), false);
    });

    test(
      'revalidates IDs before publishing and leaves no partial import',
      () async {
        final root = await _project();
        final source = await Directory.systemTemp.createTemp(
          'busymark-topic-import-',
        );
        addTearDown(() => root.deleteSync(recursive: true));
        addTearDown(() => source.deleteSync(recursive: true));
        final imported = File(p.join(source.path, 'guide.md'))
          ..writeAsStringSync('# Guide\n\n![x](image.png)\n');
        File(p.join(source.path, 'image.png')).writeAsBytesSync([1]);
        final tree = File(p.join(root.path, 'guide.tree'));
        final originalTree = tree.readAsStringSync();
        final concurrent = File(p.join(root.path, 'topics', 'guide.topic'));
        final service = WritersideInstanceService(
          beforePublish: () async => concurrent.writeAsString(
            '<topic id="guide" title="Concurrent"/>',
          ),
        );

        await expectLater(
          service.addMarkdownTopics(
            module: await moduleService.load(root.path),
            request: WritersideMarkdownTopicImportRequest(
              sourceRootPath: source.path,
              selectedMarkdownPaths: [imported.path],
              treePath: tree.path,
              placement: WritersideTopicCreatePlacement.root,
            ),
          ),
          throwsA(
            isA<BusyMarkException>().having(
              (error) => error.code,
              'code',
              'writerside.topic.id-exists',
            ),
          ),
        );
        expect(concurrent.existsSync(), true);
        expect(
          File(p.join(root.path, 'topics', 'guide.md')).existsSync(),
          false,
        );
        expect(
          File(p.join(root.path, 'topics', 'image.png')).existsSync(),
          false,
        );
        expect(tree.readAsStringSync(), originalTree);
      },
    );

    test('allows an unrelated topic created before publication', () async {
      final root = await _project();
      final source = await Directory.systemTemp.createTemp(
        'busymark-topic-import-',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      addTearDown(() => source.deleteSync(recursive: true));
      final imported = File(p.join(source.path, 'guide.md'))
        ..writeAsStringSync('# Guide\n');
      final unrelated = File(p.join(root.path, 'topics', 'unrelated.topic'));
      final service = WritersideInstanceService(
        beforePublish: () async => unrelated.writeAsString(
          '<topic id="unrelated" title="Unrelated"/>',
        ),
      );

      final result = await service.addMarkdownTopics(
        module: await moduleService.load(root.path),
        request: WritersideMarkdownTopicImportRequest(
          sourceRootPath: source.path,
          selectedMarkdownPaths: [imported.path],
          treePath: p.join(root.path, 'guide.tree'),
          placement: WritersideTopicCreatePlacement.root,
        ),
      );

      expect(File(result.firstTopicPath).existsSync(), true);
      expect(unrelated.existsSync(), true);
    });
  });

  test(
    'new-instance import rejects existing and selected-batch topic IDs',
    () async {
      final root = await _project();
      final source = await Directory.systemTemp.createTemp(
        'busymark-instance-import-',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      addTearDown(() => source.deleteSync(recursive: true));
      File(
        p.join(root.path, 'topics', 'guide.topic'),
      ).writeAsStringSync('<topic id="guide" title="Guide"/>');
      final imported = File(p.join(source.path, 'guide.md'))
        ..writeAsStringSync('# Guide\n');
      final config = File(p.join(root.path, 'writerside.cfg'));
      final originalConfig = config.readAsStringSync();

      await expectLater(
        instanceService.create(
          module: await moduleService.load(root.path),
          request: WritersideInstanceCreateRequest(
            settings: const WritersideInstanceSettings(
              name: 'Imported',
              id: 'imported',
            ),
            importRootPath: source.path,
            importedMarkdownPaths: [imported.path],
          ),
        ),
        throwsA(
          isA<BusyMarkException>().having(
            (error) => error.code,
            'code',
            'writerside.topic.id-exists',
          ),
        ),
      );
      expect(config.readAsStringSync(), originalConfig);
      expect(File(p.join(root.path, 'imported.tree')).existsSync(), false);
      expect(File(p.join(root.path, 'topics', 'guide.md')).existsSync(), false);

      Directory(p.join(source.path, 'a')).createSync();
      Directory(p.join(source.path, 'b')).createSync();
      final first = File(p.join(source.path, 'a', 'same.md'))
        ..writeAsStringSync('# A\n');
      final second = File(p.join(source.path, 'b', 'same.md'))
        ..writeAsStringSync('# B\n');
      await expectLater(
        instanceService.create(
          module: await moduleService.load(root.path),
          request: WritersideInstanceCreateRequest(
            settings: const WritersideInstanceSettings(
              name: 'Imported',
              id: 'imported',
            ),
            importRootPath: source.path,
            importedMarkdownPaths: [first.path, second.path],
          ),
        ),
        throwsA(
          isA<BusyMarkException>().having(
            (error) => error.code,
            'code',
            'writerside.topic.id-exists',
          ),
        ),
      );
    },
  );

  test('new-instance import rejects an invalid topic filename', () async {
    final root = await _project();
    final source = await Directory.systemTemp.createTemp(
      'busymark-instance-import-',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    addTearDown(() => source.deleteSync(recursive: true));
    final imported = File(p.join(source.path, 'bad name.md'))
      ..writeAsStringSync('# Invalid\n');
    final config = File(p.join(root.path, 'writerside.cfg'));
    final originalConfig = config.readAsStringSync();

    await expectLater(
      instanceService.create(
        module: await moduleService.load(root.path),
        request: WritersideInstanceCreateRequest(
          settings: const WritersideInstanceSettings(
            name: 'Invalid import',
            id: 'invalid-import',
          ),
          importRootPath: source.path,
          importedMarkdownPaths: [imported.path],
        ),
      ),
      throwsA(
        isA<BusyMarkException>()
            .having(
              (error) => error.code,
              'code',
              'writerside.topic-file.file-name-invalid',
            )
            .having((error) => error.args['path'], 'path', imported.path),
      ),
    );
    expect(config.readAsStringSync(), originalConfig);
    expect(File(p.join(root.path, 'invalid-import.tree')).existsSync(), false);
  });

  test('new-instance import fails closed on incomplete discovery', () async {
    final root = await _project();
    final source = await Directory.systemTemp.createTemp(
      'busymark-instance-import-',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    addTearDown(() => source.deleteSync(recursive: true));
    final imported = File(p.join(source.path, 'fresh.md'))
      ..writeAsStringSync('# Fresh\n');
    const limitedModuleService = WritersideModuleService(
      scanOptions: WorkspaceScanOptions(maxTreeEntries: 1),
    );
    const limitedService = WritersideInstanceService(
      moduleService: limitedModuleService,
    );
    final config = File(p.join(root.path, 'writerside.cfg'));
    final originalConfig = config.readAsStringSync();

    await expectLater(
      limitedService.create(
        module: await limitedModuleService.load(root.path),
        request: WritersideInstanceCreateRequest(
          settings: const WritersideInstanceSettings(
            name: 'Incomplete import',
            id: 'incomplete-import',
          ),
          importRootPath: source.path,
          importedMarkdownPaths: [imported.path],
        ),
      ),
      throwsA(
        isA<BusyMarkException>().having(
          (error) => error.code,
          'code',
          'writerside.topic.discovery-incomplete',
        ),
      ),
    );
    expect(config.readAsStringSync(), originalConfig);
    expect(
      File(p.join(root.path, 'incomplete-import.tree')).existsSync(),
      false,
    );
    expect(File(p.join(root.path, 'topics', 'fresh.md')).existsSync(), false);
  });
}

Future<Directory> _project() async {
  final root = await Directory.systemTemp.createTemp(
    'busymark-instance-service-',
  );
  Directory(p.join(root.path, 'topics')).createSync();
  File(p.join(root.path, 'writerside.cfg')).writeAsStringSync('''
<?xml version="1.0" encoding="UTF-8"?>
<ihp version="2.0">
  <topics dir="topics"/>
  <build-config dir="cfg"/>
  <instance src="guide.tree"/>
</ihp>
''');
  File(p.join(root.path, 'guide.tree')).writeAsStringSync('''
<instance-profile id="guide" name="Guide" start-page="intro.md">
  <snippet id="shared"><toc-element topic="intro.md"/></snippet>
  <toc-element topic="intro.md"/>
</instance-profile>
''');
  File(p.join(root.path, 'topics', 'intro.md')).writeAsStringSync('# Intro\n');
  return root;
}
