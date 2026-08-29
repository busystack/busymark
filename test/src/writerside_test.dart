import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:busymark/src/core/diagnostic.dart';
import 'package:busymark/src/core/path_utils.dart';
import 'package:busymark/src/markdown/preview_model.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:busymark/src/workspace/workspace_service.dart';
import 'package:busymark/src/writerside/writerside_module_service.dart';
import 'package:busymark/src/writerside/writerside_model.dart';
import 'package:busymark/src/writerside/writerside_parsers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const configParser = WritersideConfigParser();
  const treeParser = WritersideTreeParser();
  const moduleService = WritersideModuleService();
  const workspaceService = WorkspaceService();

  bool isError(Diagnostic diagnostic) =>
      diagnostic.severity == DiagnosticSeverity.error;

  test('parses writerside.cfg directories and registered instances', () {
    final path = 'test/fixtures/writerside/basic_project/writerside.cfg';
    final config = configParser.parse(path, File(path).readAsStringSync());

    expect(config.topicsDir, 'topics');
    expect(config.imagesDir, 'images');
    expect(config.varsFile, 'v.list');
    expect(config.categoriesFile, 'c.list');
    expect(config.instanceSources, contains('user-guide.tree'));
  });

  test('parses documented full writerside.cfg metadata', () {
    final config = configParser.parse('writerside.cfg', '''
<ihp version="2.0">
  <settings>
    <caps style="title" for="toc-element"/>
    <default-property element-name="img" property-name="border-effect" value="line"/>
    <disable-web-name-preprocessing>true</disable-web-name-preprocessing>
    <smart-ignore-vars>true</smart-ignore-vars>
    <wrs-supernova use-version="2.1.1477-p3867"/>
  </settings>
  <module name="Docs"/>
  <topics dir="topics"/>
  <topics dir="reference"/>
  <images dir="assets" version="main" web-path="/img/"/>
  <api-specifications dir="openapi"/>
  <build-config dir="build-cfg"/>
  <snippets src="code-snippets"/>
  <vars src="v.list"/>
  <categories src="c.list"/>
  <instance-groups src="instance-groups.xml"/>
  <instance src="ug.tree" web-path="/user/" version="main" keymaps-mode="none"/>
</ihp>
''');

    expect(config.version, '2.0');
    expect(config.moduleName, 'Docs');
    expect(config.topicsDirs, ['topics', 'reference']);
    expect(config.imageRoots.single.dir, 'assets');
    expect(config.imageRoots.single.version, 'main');
    expect(config.imageRoots.single.webPath, '/img/');
    expect(config.apiSpecificationsDir, 'openapi');
    expect(config.apiSpecificationsExplicit, isTrue);
    expect(config.buildConfigDir, 'build-cfg');
    expect(config.buildConfigExplicit, isTrue);
    expect(config.snippetsDir, 'code-snippets');
    expect(config.varsFile, 'v.list');
    expect(config.categoriesFile, 'c.list');
    expect(config.instanceGroupsFile, 'instance-groups.xml');
    expect(config.instances.single.src, 'ug.tree');
    expect(config.instances.single.webPath, '/user/');
    expect(config.instances.single.version, 'main');
    expect(config.instances.single.keymapsMode, 'none');
    expect(config.settings.capsRules.single.style, 'title');
    expect(config.settings.capsRules.single.target, 'toc-element');
    expect(config.settings.defaultProperties.single.elementName, 'img');
    expect(
      config.settings.defaultProperties.single.propertyName,
      'border-effect',
    );
    expect(config.settings.defaultProperties.single.value, 'line');
    expect(config.settings.disableWebNamePreprocessing, isTrue);
    expect(config.settings.smartIgnoreVars, isTrue);
    expect(config.settings.wrsSupernovaUseVersion, '2.1.1477-p3867');
    expect(config.diagnostics.where(isError), isEmpty);
  });

  test('parses documented config defaults', () {
    final config = configParser.parse('writerside.cfg', '''
<ihp><instance src="ug.tree"/></ihp>
''');

    expect(config.topicsDir, 'topics');
    expect(config.topicsDirs, ['topics']);
    expect(config.imagesDir, 'images');
    expect(config.imagesDirs, ['images']);
    expect(config.buildConfigDir, 'cfg');
    expect(config.buildConfigExplicit, isFalse);
    expect(config.apiSpecificationsDir, 'specifications');
    expect(config.apiSpecificationsExplicit, isFalse);
    expect(config.varsFile, isNull);
    expect(config.categoriesFile, isNull);
    expect(config.instanceSources, ['ug.tree']);
  });

  test('parses attribute defaults for present config elements', () {
    final config = configParser.parse('writerside.cfg', '''
<ihp>
  <topics/>
  <images/>
  <build-config/>
  <api-specifications/>
  <vars/>
  <categories/>
  <instance src="ug.tree"/>
</ihp>
''');

    expect(config.topicsDir, 'topics');
    expect(config.imagesDir, 'images');
    expect(config.buildConfigDir, 'cfg');
    expect(config.buildConfigExplicit, isTrue);
    expect(config.apiSpecificationsDir, 'specifications');
    expect(config.apiSpecificationsExplicit, isTrue);
    expect(config.varsFile, 'v.list');
    expect(config.categoriesFile, 'c.list');
  });

  test('parses documented topic title overrides and web file names', () {
    const topicParser = WritersideTopicParser();
    final markdownTopic = topicParser.parseMarkdown(
      filePath: '/tmp/topics/intro.md',
      topicsRoot: '/tmp/topics',
      source: '''
# Intro

<title instance="user-guide">Guide Intro</title>
<web-file-name>intro-page.html</web-file-name>
''',
    );
    final xmlTopic = topicParser.parseXml(
      filePath: '/tmp/topics/install.topic',
      topicsRoot: '/tmp/topics',
      source: '''
<topic id="install" title="Install">
  <title instance="admin-guide">Admin Install</title>
  <web-file-name>install-page.html</web-file-name>
  <p>Install the product.</p>
</topic>
''',
    );

    expect(markdownTopic.title, 'Intro');
    expect(markdownTopic.titleOverrides.single.instance, 'user-guide');
    expect(markdownTopic.titleOverrides.single.title, 'Guide Intro');
    expect(markdownTopic.webFileName, 'intro-page.html');
    expect(xmlTopic.title, 'Install');
    expect(xmlTopic.titleOverrides.single.instance, 'admin-guide');
    expect(xmlTopic.titleOverrides.single.title, 'Admin Install');
    expect(xmlTopic.webFileName, 'install-page.html');
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
    'Writerside topic XML exposes semantic math to the shared preview',
    () async {
      final workspace = await workspaceService.openPath(
        'test/fixtures/writerside/basic_project',
      );
      final topicPath = p.normalize(
        p.absolute('test/fixtures/writerside/basic_project/topics/math.topic'),
      );
      final source = File(topicPath).readAsStringSync();
      final preview = workspaceService.buildPreview(
        workspace.copyWith(activeFilePath: topicPath),
        source,
      );

      final math = preview!.blocks
          .expand((block) => block.inlines)
          .where((inline) => inline.kind == PreviewInlineKind.math)
          .single;
      expect(math.text, r'e^{i\pi}+1=0 \land x < y');
      expect(math.attributes['mathSourceForm'], 'writersideElement');
      expect(source, contains(r'<math>e^{i\pi}+1=0 \land x &lt; y</math>'));
    },
  );

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

  test('does not parse a Writerside config above the byte limit', () async {
    final root = await Directory.systemTemp.createTemp(
      'busymark-writerside-large-config-',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final config = File(p.join(root.path, 'writerside.cfg'))
      ..writeAsStringSync(
        '<ihp><module name="${List.filled(128, 'x').join()}"/></ihp>',
      );
    const limitedService = WritersideModuleService(
      scanOptions: WorkspaceScanOptions(maxParsedFileBytes: 64),
    );

    final module = await limitedService.load(root.path);

    expect(module.config.moduleName, isNull);
    expect(
      module.diagnostics.where(
        (diagnostic) =>
            diagnostic.code == 'workspace.file.too-large' &&
            diagnostic.filePath == config.path,
      ),
      hasLength(1),
    );
  });

  test('rejects configured paths outside the module root', () async {
    final parent = await Directory.systemTemp.createTemp(
      'busymark-writerside-config-escape-',
    );
    addTearDown(() => parent.deleteSync(recursive: true));
    final root = Directory(p.join(parent.path, 'module'))..createSync();
    final outside = Directory(p.join(parent.path, 'outside'))..createSync();
    Directory(p.join(outside.path, 'topics')).createSync();
    Directory(p.join(outside.path, 'images')).createSync();
    File(
      p.join(outside.path, 'topics', 'secret.md'),
    ).writeAsStringSync('# Outside\n');
    File(p.join(outside.path, 'ug.tree')).writeAsStringSync('''
<instance-profile id="ug" name="Outside" start-page="secret.md">
  <toc-element topic="secret.md"/>
</instance-profile>
''');
    File(p.join(outside.path, 'v.list')).writeAsStringSync('''
<vars><var name="outside">secret</var></vars>
''');
    File(p.join(outside.path, 'c.list')).writeAsStringSync('''
<categories><category id="outside" name="Outside"/></categories>
''');
    File(p.join(root.path, 'writerside.cfg')).writeAsStringSync('''
<ihp version="2.0">
  <topics dir="../outside/topics"/>
  <images dir="../outside/images"/>
  <build-config dir="../outside/build"/>
  <api-specifications dir="../outside/api"/>
  <snippets src="../outside/snippets"/>
  <resources src="../outside/resources.xml" dir="../outside/resources"/>
  <vars src="../outside/v.list"/>
  <categories src="../outside/c.list"/>
  <instance-groups src="../outside/groups.xml"/>
  <instance src="../outside/ug.tree"/>
</ihp>
''');

    final module = await moduleService.load(root.path);
    final workspace = await workspaceService.openPath(root.path);
    final unsafeDiagnostics = module.diagnostics.where(
      (diagnostic) => diagnostic.code == 'writerside.config.path-unsafe',
    );

    expect(unsafeDiagnostics, hasLength(12));
    expect(
      unsafeDiagnostics.map((diagnostic) => diagnostic.args['reason']).toSet(),
      {'outsideRoot'},
    );
    expect(module.topics, isEmpty);
    expect(module.instances, isEmpty);
    expect(module.variables, isEmpty);
    expect(module.categories, isEmpty);
    expect(module.effectiveImagesDir, 'images');
    expect(workspace.activeFilePath, isNull);
  });

  test(
    'rejects a configured topic root reached through a symlink',
    () async {
      final parent = await Directory.systemTemp.createTemp(
        'busymark-writerside-config-symlink-',
      );
      addTearDown(() => parent.deleteSync(recursive: true));
      final root = Directory(p.join(parent.path, 'module'))..createSync();
      final outside = Directory(p.join(parent.path, 'outside'))..createSync();
      final outsideTopic = File(p.join(outside.path, 'secret.md'))
        ..writeAsStringSync('# Outside\n');
      await Link(p.join(root.path, 'topics')).create(outside.path);
      File(p.join(root.path, 'writerside.cfg')).writeAsStringSync('''
<ihp version="2.0">
  <topics dir="topics"/>
</ihp>
''');

      final module = await moduleService.load(root.path);

      expect(
        module.topics.map((topic) => topic.filePath),
        isNot(contains(outsideTopic.path)),
      );
      expect(
        module.diagnostics.where(
          (diagnostic) =>
              diagnostic.code == 'writerside.config.path-unsafe' &&
              diagnostic.args['reason'] == 'symlinkComponent',
        ),
        isNotEmpty,
      );
    },
    skip: Platform.isWindows ? 'POSIX symlink behavior only.' : false,
  );

  test(
    'rejects a Writerside config file reached through a symlink',
    () async {
      final parent = await Directory.systemTemp.createTemp(
        'busymark-writerside-config-file-symlink-',
      );
      addTearDown(() => parent.deleteSync(recursive: true));
      final root = Directory(p.join(parent.path, 'module'))..createSync();
      final outsideConfig = File(p.join(parent.path, 'outside.cfg'))
        ..writeAsStringSync('''
<ihp version="2.0">
  <module name="Outside"/>
</ihp>
''');
      await Link(
        p.join(root.path, 'writerside.cfg'),
      ).create(outsideConfig.path);

      final module = await moduleService.load(root.path);

      expect(module.config.moduleName, isNull);
      expect(
        module.diagnostics.where(
          (diagnostic) =>
              diagnostic.code == 'writerside.config.path-unsafe' &&
              diagnostic.args['kind'] == 'config' &&
              diagnostic.args['reason'] == 'symlinkComponent',
        ),
        isNotEmpty,
      );
    },
    skip: Platform.isWindows ? 'POSIX symlink behavior only.' : false,
  );

  test('loads project.ihp as an equivalent Writerside config file', () async {
    final root = await Directory.systemTemp.createTemp('busymark-project-ihp-');
    addTearDown(() => root.deleteSync(recursive: true));
    Directory(p.join(root.path, 'topics')).createSync();
    Directory(p.join(root.path, 'images')).createSync();
    File(p.join(root.path, 'project.ihp')).writeAsStringSync('''
<ihp version="2.0">
  <topics dir="topics"/>
  <images dir="images"/>
  <instance src="ug.tree"/>
</ihp>
''');
    File(p.join(root.path, 'ug.tree')).writeAsStringSync('''
<instance-profile id="ug" name="User Guide" start-page="intro.md">
  <toc-element topic="intro.md"/>
</instance-profile>
''');
    File(p.join(root.path, 'topics', 'intro.md')).writeAsStringSync('''
# Intro
''');

    final module = await moduleService.load(root.path);
    final workspace = await workspaceService.openPath(root.path);

    expect(module.config.configFileName, 'project.ihp');
    expect(module.instances.single.name, 'User Guide');
    expect(workspace.kind, WorkspaceKind.writersideModule);
    expect(
      module.diagnostics.map((item) => item.code),
      isNot(
        contains(
          'writerside.config.'
          'legacy-project-'
          'ihp-unsupported',
        ),
      ),
    );
  });

  test('loads topics from multiple configured topic roots', () async {
    final root = await Directory.systemTemp.createTemp(
      'busymark-multi-topics-',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    Directory(p.join(root.path, 'topics')).createSync();
    Directory(p.join(root.path, 'reference')).createSync();
    Directory(p.join(root.path, 'images')).createSync();
    File(p.join(root.path, 'writerside.cfg')).writeAsStringSync('''
<ihp version="2.0">
  <topics dir="topics"/>
  <topics dir="reference"/>
  <images dir="images"/>
  <instance src="ug.tree"/>
</ihp>
''');
    File(p.join(root.path, 'ug.tree')).writeAsStringSync('''
<instance-profile id="ug" name="User Guide" start-page="intro.md">
  <toc-element topic="intro.md"/>
  <toc-element topic="api.md"/>
</instance-profile>
''');
    File(
      p.join(root.path, 'topics', 'intro.md'),
    ).writeAsStringSync('# Intro\n');
    File(p.join(root.path, 'reference', 'api.md')).writeAsStringSync('# API\n');

    final module = await moduleService.load(root.path);

    expect(module.topicsByFileName.keys, containsAll(['intro.md', 'api.md']));
    expect(module.topicByReference('api.md')?.title, 'API');
    expect(
      module.diagnostics.map((item) => item.code),
      isNot(contains('writerside.tree.missing-topic')),
    );
    expect(
      module.diagnostics.map((item) => item.code),
      isNot(contains('writerside.tree.missing-start-page')),
    );
  });

  test('resolves exact topic reference before basename fallback', () async {
    final root = await Directory.systemTemp.createTemp(
      'busymark-exact-topic-reference-',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    Directory(
      p.join(root.path, 'topics', 'section'),
    ).createSync(recursive: true);
    Directory(p.join(root.path, 'images')).createSync();
    File(p.join(root.path, 'writerside.cfg')).writeAsStringSync('''
<ihp version="2.0">
  <topics dir="topics"/>
  <images dir="images"/>
  <instance src="ug.tree"/>
</ihp>
''');
    File(p.join(root.path, 'ug.tree')).writeAsStringSync('''
<instance-profile id="ug" name="User Guide" start-page="intro.md">
  <toc-element topic="intro.md"/>
  <toc-element topic="section/intro.md"/>
</instance-profile>
''');
    File(p.join(root.path, 'topics', 'intro.md')).writeAsStringSync('''
# Intro
''');
    File(p.join(root.path, 'topics', 'section', 'intro.md')).writeAsStringSync(
      '''
# Section Intro
''',
    );

    final module = await moduleService.load(root.path);

    expect(module.topicByReference('intro.md')?.title, 'Intro');
    expect(module.topicByReference('section/intro.md')?.title, 'Section Intro');
    expect(
      module.diagnostics.map((item) => item.code),
      isNot(contains('writerside.topic.ambiguous-reference')),
    );
  });

  test('reports duplicate topic IDs in a help module', () async {
    final root = await Directory.systemTemp.createTemp(
      'busymark-duplicate-topic-id-',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    Directory(
      p.join(root.path, 'topics', 'section'),
    ).createSync(recursive: true);
    Directory(p.join(root.path, 'images')).createSync();
    File(p.join(root.path, 'writerside.cfg')).writeAsStringSync('''
<ihp version="2.0">
  <topics dir="topics"/>
  <images dir="images"/>
  <instance src="ug.tree"/>
</ihp>
''');
    File(p.join(root.path, 'ug.tree')).writeAsStringSync('''
<instance-profile id="ug" name="User Guide" start-page="intro.md">
  <toc-element topic="intro.md"/>
</instance-profile>
''');
    File(p.join(root.path, 'topics', 'intro.md')).writeAsStringSync('''
# Intro
''');
    File(p.join(root.path, 'topics', 'section', 'intro.md')).writeAsStringSync(
      '''
# Other Intro
''',
    );

    final module = await moduleService.load(root.path);

    expect(
      module.diagnostics.map((item) => item.code),
      contains('writerside.topic.duplicate-id'),
    );
  });

  test(
    'reports ambiguous basename fallback after exact matching misses',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'busymark-basename-topic-ambiguity-',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      Directory(
        p.join(root.path, 'topics', 'guide'),
      ).createSync(recursive: true);
      Directory(p.join(root.path, 'topics', 'api')).createSync(recursive: true);
      Directory(p.join(root.path, 'images')).createSync();
      File(p.join(root.path, 'writerside.cfg')).writeAsStringSync('''
<ihp version="2.0">
  <topics dir="topics"/>
  <images dir="images"/>
  <instance src="ug.tree"/>
</ihp>
''');
      File(p.join(root.path, 'ug.tree')).writeAsStringSync('''
<instance-profile id="ug" name="User Guide" start-page="guide/intro.md">
  <toc-element topic="intro.md"/>
</instance-profile>
''');
      File(p.join(root.path, 'topics', 'guide', 'intro.md')).writeAsStringSync(
        '''
# Guide Intro
''',
      );
      File(p.join(root.path, 'topics', 'api', 'intro.md')).writeAsStringSync('''
# API Intro
''');

      final module = await moduleService.load(root.path);

      expect(
        module.diagnostics.map((item) => item.code),
        contains('writerside.topic.ambiguous-reference'),
      );
      expect(module.topicByReference('intro.md'), isNull);
    },
  );

  test('resolves Markdown links across configured topic roots', () async {
    final root = await Directory.systemTemp.createTemp(
      'busymark-cross-root-link-',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    Directory(p.join(root.path, 'topics')).createSync();
    Directory(p.join(root.path, 'reference')).createSync();
    Directory(p.join(root.path, 'images')).createSync();
    File(p.join(root.path, 'writerside.cfg')).writeAsStringSync('''
<ihp version="2.0">
  <topics dir="topics"/>
  <topics dir="reference"/>
  <images dir="images"/>
  <instance src="ug.tree"/>
</ihp>
''');
    File(p.join(root.path, 'ug.tree')).writeAsStringSync('''
<instance-profile id="ug" name="User Guide" start-page="intro.md">
  <toc-element topic="intro.md"/>
  <toc-element topic="api.md"/>
</instance-profile>
''');
    File(p.join(root.path, 'topics', 'intro.md')).writeAsStringSync('''
# Intro

[API](api.md)
''');
    File(p.join(root.path, 'reference', 'api.md')).writeAsStringSync('''
# API
''');

    final module = await moduleService.load(root.path);

    expect(module.topicByReference('api.md')?.title, 'API');
    expect(
      module.diagnostics.map((item) => item.code),
      isNot(contains('markdown.link.unresolved-target')),
    );
  });

  test(
    'reports ambiguous basename topic references deterministically',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'busymark-ambiguous-topic-',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      Directory(p.join(root.path, 'topics')).createSync();
      Directory(p.join(root.path, 'reference')).createSync();
      Directory(p.join(root.path, 'images')).createSync();
      File(p.join(root.path, 'writerside.cfg')).writeAsStringSync('''
<ihp version="2.0">
  <topics dir="topics"/>
  <topics dir="reference"/>
  <images dir="images"/>
  <instance src="ug.tree"/>
</ihp>
''');
      File(p.join(root.path, 'ug.tree')).writeAsStringSync('''
<instance-profile id="ug" name="User Guide" start-page="intro.md">
  <toc-element topic="intro.md"/>
</instance-profile>
''');
      File(
        p.join(root.path, 'topics', 'intro.md'),
      ).writeAsStringSync('# Intro\n');
      File(
        p.join(root.path, 'reference', 'intro.md'),
      ).writeAsStringSync('# Other Intro\n');

      final module = await moduleService.load(root.path);

      expect(
        module.diagnostics.map((item) => item.code),
        contains('writerside.topic.ambiguous-reference'),
      );
      expect(module.topicByReference('intro.md'), isNull);
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

  test('resolves local images from secondary configured image roots', () async {
    final root = await Directory.systemTemp.createTemp(
      'busymark-writerside-images-',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    Directory(p.join(root.path, 'topics')).createSync();
    Directory(p.join(root.path, 'images')).createSync();
    Directory(p.join(root.path, 'assets')).createSync();
    File(p.join(root.path, 'writerside.cfg')).writeAsStringSync('''
<ihp version="2.0">
  <topics dir="topics"/>
  <images dir="images"/>
  <images dir="assets" web-path="/img/" version="main"/>
  <instance src="ug.tree"/>
</ihp>
''');
    File(p.join(root.path, 'ug.tree')).writeAsStringSync('''
<instance-profile id="ug" name="User Guide" start-page="intro.md">
  <toc-element topic="intro.md"/>
</instance-profile>
''');
    File(p.join(root.path, 'topics', 'intro.md')).writeAsStringSync('''
# Intro

![Alt](logo.png)
''');
    File(p.join(root.path, 'assets', 'logo.png')).writeAsBytesSync([0]);

    final module = await moduleService.load(root.path);

    expect(module.config.imagesDirs, ['images', 'assets']);
    expect(module.config.imageRoots.last.webPath, '/img/');
    expect(module.config.imageRoots.last.version, 'main');
    expect(
      module.diagnostics.map((item) => item.code),
      isNot(contains('markdown.image.missing-file')),
    );
  });

  test('parses the documented instance tree elements and attributes', () {
    final instance = treeParser.parse('/project/guide.tree', '''
<instance-profile id="guide" name="Guide" start-page="intro.md" status="eap">
  <toc-element topic="intro.md" id="intro" toc-title="Introduction"
      hidden="true" wip="true" instance="guide" filter="desktop"
      accepts-web-file-names="old.html" accepts-web-file-names-ref="legacy"/>
  <toc-element ref="admin.md" in="admin"/>
  <toc-element toc-title="Moved" hidden="true"
      accepts-web-file-names="moved.html"
      target-for-accept-web-file-names="https://example.com/new"/>
  <include from="library.tree" element-id="shared"
      instance="@public" use-filter="empty,desktop"/>
  <snippet id="local" instance="guide" filter="desktop">
    <toc-element topic="local.md"/>
  </snippet>
</instance-profile>
''');

    expect(instance.status, 'eap');
    expect(instance.treeEntries, hasLength(5));
    final intro = instance.treeEntries.first as TocNode;
    expect(intro.topicFileName, 'intro.md');
    expect(intro.tocTitle, 'Introduction');
    expect(intro.hidden, isTrue);
    expect(intro.workInProgress, isTrue);
    expect(intro.instanceCondition, 'guide');
    expect(intro.customFilter, 'desktop');
    expect(intro.acceptsWebFileNames, 'old.html');
    expect(intro.acceptsWebFileNamesRef, 'legacy');
    expect(intro.sourceTocPath, [0]);
    final reference = instance.treeEntries[1] as TocNode;
    expect(reference.referenceTopicFileName, 'admin.md');
    expect(reference.referenceInstanceId, 'admin');
    final redirect = instance.treeEntries[2] as TocNode;
    expect(redirect.targetForAcceptWebFileNames, 'https://example.com/new');
    final include = instance.treeEntries[3] as WritersideTocInclude;
    expect(include.from, 'library.tree');
    expect(include.elementId, 'shared');
    expect(include.instanceCondition, '@public');
    expect(include.useFilters, ['empty', 'desktop']);
    final snippet = instance.treeEntries[4] as WritersideTocSnippet;
    expect(snippet.id, 'local');
    expect(snippet.entries.single, isA<TocNode>());
    expect(instance.diagnostics.where(isError), isEmpty);
  });

  test(
    'resolves registered TOC libraries, filters, groups, and cross-instance refs',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'busymark-writerside-instances-',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      Directory(p.join(root.path, 'topics')).createSync();
      File(p.join(root.path, 'writerside.cfg')).writeAsStringSync('''
<ihp version="2.0">
  <topics dir="topics"/>
  <instance-groups src="instance-groups.xml"/>
  <instance src="library.tree"/>
  <instance src="guide.tree" version="2026.2" web-path="/guide/"/>
  <instance src="admin.tree"/>
</ihp>
''');
      File(p.join(root.path, 'instance-groups.xml')).writeAsStringSync('''
<instance-groups><group id="public" instances="guide"/></instance-groups>
''');
      File(p.join(root.path, 'library.tree')).writeAsStringSync('''
<instance-profile id="library" name="Shared TOC" is-library="true">
  <snippet id="shared">
    <toc-element topic="common.md"/>
    <toc-element topic="desktop.md" filter="desktop"/>
    <toc-element topic="admin-only.md" instance="admin"/>
  </snippet>
</instance-profile>
''');
      File(p.join(root.path, 'guide.tree')).writeAsStringSync('''
<instance-profile id="guide" name="Guide" start-page="intro.md">
  <toc-element topic="intro.md" wip="true"/>
  <include from="library.tree" element-id="shared"
      instance="@public" use-filter="empty,desktop"/>
  <toc-element ref="admin.md" in="admin"/>
</instance-profile>
''');
      File(p.join(root.path, 'admin.tree')).writeAsStringSync('''
<instance-profile id="admin" name="Admin" start-page="admin.md">
  <toc-element topic="admin.md"/>
</instance-profile>
''');
      for (final name in const [
        'intro.md',
        'common.md',
        'desktop.md',
        'admin-only.md',
        'admin.md',
      ]) {
        File(
          p.join(root.path, 'topics', name),
        ).writeAsStringSync('# ${p.basenameWithoutExtension(name)}\n');
      }

      final module = await moduleService.load(root.path);
      final workspace = await workspaceService.openPath(root.path);
      final guide = module.instances.singleWhere(
        (instance) => instance.id == 'guide',
      );
      final library = module.instances.singleWhere(
        (instance) => instance.id == 'library',
      );

      expect(guide.version, '2026.2');
      expect(guide.webPath, '/guide/');
      expect(
        guide.navigationTocRoots
            .expand((node) => node.flatten())
            .map((node) => node.topicReference)
            .whereType<String>(),
        ['intro.md', 'common.md', 'desktop.md', 'admin.md'],
      );
      final included = guide.navigationTocRoots[1];
      expect(included.topicFileName, 'common.md');
      expect(included.included, isTrue);
      expect(included.canEditStructure, isFalse);
      expect(guide.tocRoots.map((node) => node.topicReference), [
        'intro.md',
        'admin.md',
      ]);
      expect(library.isLibrary, isTrue);
      expect(library.navigationTocRoots.single.id, 'shared');
      expect(
        library.navigationTocRoots.single.children.map(
          (node) => node.topicFileName,
        ),
        ['common.md', 'desktop.md'],
      );
      expect(workspace.activeFilePath, p.join(root.path, 'topics', 'intro.md'));
      expect(
        module.diagnostics.map((diagnostic) => diagnostic.code),
        isNot(
          anyOf(
            contains('writerside.tree.unresolved-include-source'),
            contains('writerside.tree.unresolved-include-element'),
            contains('writerside.tree.missing-reference-topic'),
          ),
        ),
      );
    },
  );

  test('reports circular reusable tree includes without recursing', () async {
    final root = await Directory.systemTemp.createTemp(
      'busymark-writerside-circular-tree-',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    Directory(p.join(root.path, 'topics')).createSync();
    File(p.join(root.path, 'writerside.cfg')).writeAsStringSync('''
<ihp><topics dir="topics"/><instance src="guide.tree"/><instance src="library.tree"/></ihp>
''');
    File(p.join(root.path, 'guide.tree')).writeAsStringSync('''
<instance-profile id="guide" name="Guide" start-page="intro.md">
  <toc-element topic="intro.md"/>
  <include from="library.tree" element-id="loop"/>
</instance-profile>
''');
    File(p.join(root.path, 'library.tree')).writeAsStringSync('''
<instance-profile id="library" name="Library" is-library="true">
  <snippet id="loop"><include from="library.tree" element-id="loop"/></snippet>
</instance-profile>
''');
    File(
      p.join(root.path, 'topics', 'intro.md'),
    ).writeAsStringSync('# Intro\n');

    final module = await moduleService.load(root.path);

    expect(
      module.diagnostics.map((diagnostic) => diagnostic.code),
      contains('writerside.tree.circular-include'),
    );
    final guide = module.instances.first;
    expect(guide.navigationTocRoots, hasLength(2));
    expect(guide.navigationTocRoots.last.includeResolutionError, 'circular');
  });

  test(
    'included content still requires a regular instance home page',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'busymark-writerside-included-home-',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      Directory(p.join(root.path, 'topics')).createSync();
      File(p.join(root.path, 'writerside.cfg')).writeAsStringSync('''
<ihp><topics dir="topics"/><instance src="guide.tree"/><instance src="library.tree"/></ihp>
''');
      File(p.join(root.path, 'guide.tree')).writeAsStringSync('''
<instance-profile id="guide" name="Guide">
  <include from="library.tree" element-id="shared"/>
</instance-profile>
''');
      File(p.join(root.path, 'library.tree')).writeAsStringSync('''
<instance-profile id="library" name="Library" is-library="true">
  <snippet id="shared"><toc-element topic="common.md"/></snippet>
</instance-profile>
''');
      File(
        p.join(root.path, 'topics', 'common.md'),
      ).writeAsStringSync('# Common\n');

      final module = await moduleService.load(root.path);

      expect(
        module.diagnostics.map((diagnostic) => diagnostic.code),
        contains('writerside.tree.missing-start-page'),
      );
    },
  );

  test('ignores status-specific values for general instance settings', () {
    const parser = WritersideBuildProfilesParser();
    final profiles = parser.parse('cfg/buildprofiles.xml', '''
<buildprofiles>
  <variables>
    <noindex-content status="release">false</noindex-content>
    <noindex-content>true</noindex-content>
  </variables>
  <build-profile instance="guide">
    <variables>
      <offline-docs status="eap">true</offline-docs>
      <offline-docs>false</offline-docs>
    </variables>
  </build-profile>
</buildprofiles>
''');

    expect(profiles.globalValues.noindexContent, isTrue);
    expect(profiles.valuesFor('guide').offlineDocs, isFalse);
  });

  test('instance demo is a valid openable Writerside module', () async {
    final module = await moduleService.load('demo/writerside-instances');

    expect(module.instances.map((instance) => instance.id), [
      'guide',
      'admin',
      'shared',
    ]);
    expect(module.instances.last.isLibrary, isTrue);
    expect(module.instances.first.allowSearchEngineIndexing, isTrue);
    expect(module.instances[1].offlineArtifact, isTrue);
    expect(module.diagnostics.where(isError), isEmpty);
  });
}
