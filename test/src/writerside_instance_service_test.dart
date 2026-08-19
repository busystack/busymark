import 'dart:io';

import 'package:busymark/src/core/busymark_exception.dart';
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

  test(
    'creates and registers an empty help instance with build settings',
    () async {
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
    },
  );

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
    final first = File(p.join(source.path, 'guide', 'intro.md'))
      ..writeAsStringSync('# Imported intro\n\n![Logo](images/logo.png)\n');
    File(
      p.join(source.path, 'guide', 'other.md'),
    ).writeAsStringSync('# Other\n');
    File(
      p.join(source.path, 'guide', 'images', 'logo.png'),
    ).writeAsBytesSync([1, 2, 3]);

    final candidates = await instanceService.discoverMarkdownFiles(source.path);
    expect(candidates.map((candidate) => candidate.relativePath), [
      'guide/intro.md',
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
      p.join(root.path, 'topics', 'guide', 'intro.md'),
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
      File(p.join(root.path, 'topics', 'guide', 'other.md')).existsSync(),
      isFalse,
    );
    final tree = XmlDocument.parse(
      File(p.join(root.path, 'imported.tree')).readAsStringSync(),
    );
    expect(tree.rootElement.getAttribute('start-page'), 'guide/intro.md');
    expect(
      tree.rootElement.childElements.single.getAttribute('topic'),
      'guide/intro.md',
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
