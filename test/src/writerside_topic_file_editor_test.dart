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

  test(
    'rename refactors links, includes, ref entries, and leaves unrelated text',
    () async {
      final fixture = await _fixture(
        trees: {
          'guide.tree': '''
<instance-profile id="guide" start-page="guide.md">
  <toc-element topic="guide.md"/>
</instance-profile>
''',
          'other.tree': '''
<instance-profile id="other" start-page="other.topic">
  <toc-element ref="guide.md" in="guide"/>
  <toc-element topic="other.topic"
               target-for-accept-web-filenames="guide.md"
               target-for-accept-web-file-names="https://example.com/guide.md"/>
</instance-profile>
''',
        },
        topics: {
          'guide.md': '# Guide\n\n<a id="part"/>\n',
          'other.md': '# Other\n',
          'links.md': '''
# Links

Example: `[sample](guide.md)`; guide.md appears before [guide.md](guide.md), [again](guide.md), and [part](guide.md#part).

[Other](other.md "[example](guide.md)") and [Guide](guide.md).

[not a link](guide.md unexpected) and [Guide](guide.md).

Comment: <!-- [fake](guide.md) --> and [Guide again](guide.md).

Literal guide.md must stay literal.
''',
          'other.topic': '''
<topic id="other" title="Other">
  <include from="guide.md" element-id="part"/>
  <a href="guide.md#part">Guide</a>
  <p instance="guide">Same-named instance</p>
</topic>
''',
        },
      );
      final topic = _topic(fixture.module, 'guide.md');

      await editor.rename(
        module: fixture.module,
        topic: topic,
        newFileName: 'setup.md',
      );

      final links = File(
        p.join(fixture.root.path, 'topics', 'links.md'),
      ).readAsStringSync();
      expect(
        links,
        contains(
          'Example: `[sample](guide.md)`; guide.md appears before '
          '[guide.md](setup.md), '
          '[again](setup.md), and [part](setup.md#part).',
        ),
      );
      expect(links, contains('[part](setup.md#part)'));
      expect(
        links,
        contains(
          '[Other](other.md "[example](guide.md)") and '
          '[Guide](setup.md).',
        ),
      );
      expect(
        links,
        contains('[not a link](guide.md unexpected) and [Guide](setup.md).'),
      );
      expect(
        links,
        contains(
          'Comment: <!-- [fake](guide.md) --> and [Guide again](setup.md).',
        ),
      );
      expect(links, contains('Literal guide.md must stay literal.'));
      final other = File(
        p.join(fixture.root.path, 'topics', 'other.topic'),
      ).readAsStringSync();
      expect(other, contains('from="setup.md"'));
      expect(other, contains('element-id="part"'));
      expect(other, contains('href="setup.md#part"'));
      expect(other, contains('instance="guide"'));
      final otherTree = _tree(fixture.root, 'other.tree');
      expect(
        otherTree.findAllElements('toc-element').first.getAttribute('ref'),
        'setup.md',
      );
      final externalRedirect = otherTree.findAllElements('toc-element').last;
      expect(
        externalRedirect.getAttribute('target-for-accept-web-filenames'),
        'guide.md',
      );
      expect(
        externalRedirect.getAttribute('target-for-accept-web-file-names'),
        'https://example.com/guide.md',
      );
    },
  );

  test(
    'rename ignores link-shaped text in image titles and HTML attributes',
    () async {
      final fixture = await _fixture(
        trees: {
          'guide.tree': '''
<instance-profile id="guide" start-page="guide.md">
  <toc-element topic="guide.md"/>
</instance-profile>
''',
        },
        topics: {
          'guide.md': '# Guide\n',
          'links.md': '''
# Links

![Screenshot](image.png "[example](guide.md)") and [Guide](guide.md).

Text <span title="[example](guide.md)">label</span> and [Guide](guide.md).
''',
        },
      );

      await editor.rename(
        module: fixture.module,
        topic: _topic(fixture.module, 'guide.md'),
        newFileName: 'setup.md',
      );

      final linksPath = p.join(fixture.root.path, 'topics', 'links.md');
      expect(File(linksPath).readAsStringSync(), '''
# Links

![Screenshot](image.png "[example](guide.md)") and [Guide](setup.md).

Text <span title="[example](guide.md)">label</span> and [Guide](setup.md).
''');
      final reloaded = await const WritersideModuleService().load(
        fixture.root.path,
      );
      expect(
        _topic(reloaded, 'links.md').links.map((link) => link.destination),
        ['setup.md', 'setup.md'],
      );
    },
  );

  test(
    'rename binds reference links outside image titles and HTML attributes',
    () async {
      final fixture = await _fixture(
        trees: {
          'guide.tree': '''
<instance-profile id="guide" start-page="guide.md">
  <toc-element topic="guide.md"/>
</instance-profile>
''',
        },
        topics: {
          'guide.md': '# Guide\n',
          'image-links.md': '''
# Image links

![Screenshot](image.png "[example][fake]") and [Guide][real].

[fake]: guide.md
[real]: guide.md
''',
          'html-links.md': '''
# HTML links

Text <span title="[example][fake]">label</span> and [Guide][real].

[fake]: guide.md
[real]: guide.md
''',
        },
      );

      await editor.rename(
        module: fixture.module,
        topic: _topic(fixture.module, 'guide.md'),
        newFileName: 'setup.md',
      );

      final imageLinks = File(
        p.join(fixture.root.path, 'topics', 'image-links.md'),
      ).readAsStringSync();
      expect(imageLinks, '''
# Image links

![Screenshot](image.png "[example][fake]") and [Guide][real].

[fake]: guide.md
[real]: setup.md
''');
      final htmlLinks = File(
        p.join(fixture.root.path, 'topics', 'html-links.md'),
      ).readAsStringSync();
      expect(htmlLinks, '''
# HTML links

Text <span title="[example][fake]">label</span> and [Guide][real].

[fake]: guide.md
[real]: setup.md
''');

      final reloaded = await const WritersideModuleService().load(
        fixture.root.path,
      );
      expect(
        _topic(reloaded, 'image-links.md').links.single.destination,
        'setup.md',
      );
      expect(
        _topic(reloaded, 'html-links.md').links.single.destination,
        'setup.md',
      );
    },
  );

  test(
    'rename binds exact HTML hrefs outside Markdown link and image titles',
    () async {
      final fixture = await _fixture(
        trees: {
          'guide.tree': '''
<instance-profile id="guide" start-page="guide.md">
  <toc-element topic="guide.md"/>
</instance-profile>
''',
        },
        topics: {
          'guide.md': '# Guide\n',
          'links.md': '''
# Links

![Screenshot](image.png "<a href='guide.md'>Example</a>") and [Guide](guide.md).

[Other](other.md "<a href='guide.md'>Example</a>") and [Guide](guide.md).

Text <a data-href="keep.md" href="guide.md">Guide</a>.

Text <a title="A > B" href="guide.md">Guide</a>.

Text <a href='guide.md' title='A > B'>Guide</a>.

Text <a href=guide.md data-note=keep>Guide</a>.

Text <a HREF="guide.md" DATA-HREF="keep.md">Guide</a>.

Text <a title="A&nbsp;B" href="guide.md">Guide</a>.
''',
        },
      );

      await editor.rename(
        module: fixture.module,
        topic: _topic(fixture.module, 'guide.md'),
        newFileName: 'setup.md',
      );

      final linksPath = p.join(fixture.root.path, 'topics', 'links.md');
      expect(File(linksPath).readAsStringSync(), '''
# Links

![Screenshot](image.png "<a href='guide.md'>Example</a>") and [Guide](setup.md).

[Other](other.md "<a href='guide.md'>Example</a>") and [Guide](setup.md).

Text <a data-href="keep.md" href="setup.md">Guide</a>.

Text <a title="A > B" href="setup.md">Guide</a>.

Text <a href='setup.md' title='A > B'>Guide</a>.

Text <a href=setup.md data-note=keep>Guide</a>.

Text <a HREF="setup.md" DATA-HREF="keep.md">Guide</a>.

Text <a title="A&nbsp;B" href="setup.md">Guide</a>.
''');
      final reloaded = await const WritersideModuleService().load(
        fixture.root.path,
      );
      expect(
        _topic(reloaded, 'links.md').links.map((link) => link.destination),
        [
          'setup.md',
          'other.md',
          'setup.md',
          'setup.md',
          'setup.md',
          'setup.md',
          'setup.md',
          'setup.md',
          'setup.md',
        ],
      );
    },
  );

  test(
    'rename follows origin across modules without touching a local namesake',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'busymark-topic-file-project-',
      );
      addTearDown(() => root.delete(recursive: true));
      Future<WritersideModule> writeModule({
        required String directory,
        required String moduleName,
        required String tree,
        required Map<String, String> topics,
      }) async {
        final moduleRoot = await Directory(
          p.join(root.path, directory),
        ).create();
        final topicRoot = await Directory(
          p.join(moduleRoot.path, 'topics'),
        ).create();
        await File(p.join(moduleRoot.path, 'writerside.cfg')).writeAsString('''
<ihp><module name="$moduleName"/><topics dir="topics"/><instance src="guide.tree"/></ihp>
''');
        await File(p.join(moduleRoot.path, 'guide.tree')).writeAsString(tree);
        for (final entry in topics.entries) {
          await File(
            p.join(topicRoot.path, entry.key),
          ).writeAsString(entry.value);
        }
        return const WritersideModuleService().load(moduleRoot.path);
      }

      final main = await writeModule(
        directory: 'main',
        moduleName: 'main',
        tree: '''
<instance-profile id="guide" start-page="guide.md">
  <toc-element topic="guide.md"/>
  <toc-element topic="guide.md" origin="shared"/>
</instance-profile>
''',
        topics: {
          'guide.md': '# Local namesake\n',
          'links.md': '''
# Links

Text <a title="A > B" href="guide.md" origin="shared">Shared</a>.
''',
        },
      );
      final shared = await writeModule(
        directory: 'shared',
        moduleName: 'shared',
        tree: '''
<instance-profile id="guide" start-page="guide.md"><toc-element topic="guide.md"/></instance-profile>
''',
        topics: {'guide.md': '# Shared guide\n'},
      );

      await editor.rename(
        module: shared,
        topic: _topic(shared, 'guide.md'),
        newFileName: 'setup.md',
        projectModules: [main, shared],
      );

      expect(
        File(p.join(main.rootPath, 'topics', 'guide.md')).readAsStringSync(),
        '# Local namesake\n',
      );
      expect(
        File(p.join(main.rootPath, 'topics', 'links.md')).readAsStringSync(),
        contains('title="A > B" href="setup.md" origin="shared"'),
      );
      final reloadedMain = await const WritersideModuleService().load(
        main.rootPath,
      );
      expect(
        _topic(reloadedMain, 'links.md').links.single.destination,
        'setup.md',
      );
      final mainTree = XmlDocument.parse(
        File(p.join(main.rootPath, 'guide.tree')).readAsStringSync(),
      );
      expect(
        mainTree
            .findAllElements('toc-element')
            .map((element) => element.getAttribute('topic')),
        ['guide.md', 'setup.md'],
      );
      expect(
        File(p.join(shared.rootPath, 'topics', 'guide.md')).existsSync(),
        isFalse,
      );
      expect(
        File(p.join(shared.rootPath, 'topics', 'setup.md')).existsSync(),
        isTrue,
      );
    },
  );

  test(
    'renaming a local namesake preserves origin-qualified Markdown XML links',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'busymark-topic-file-project-reverse-',
      );
      addTearDown(() => root.delete(recursive: true));
      Future<WritersideModule> writeModule({
        required String directory,
        required String moduleName,
        required String tree,
        required Map<String, String> topics,
      }) async {
        final moduleRoot = await Directory(
          p.join(root.path, directory),
        ).create();
        final topicRoot = await Directory(
          p.join(moduleRoot.path, 'topics'),
        ).create();
        await File(p.join(moduleRoot.path, 'writerside.cfg')).writeAsString('''
<ihp><module name="$moduleName"/><topics dir="topics"/><instance src="guide.tree"/></ihp>
''');
        await File(p.join(moduleRoot.path, 'guide.tree')).writeAsString(tree);
        for (final entry in topics.entries) {
          await File(
            p.join(topicRoot.path, entry.key),
          ).writeAsString(entry.value);
        }
        return const WritersideModuleService().load(moduleRoot.path);
      }

      final main = await writeModule(
        directory: 'main',
        moduleName: 'main',
        tree: '''
<instance-profile id="guide" start-page="guide.md">
  <toc-element topic="guide.md"/>
  <toc-element topic="guide.md" origin="shared"/>
</instance-profile>
''',
        topics: {
          'guide.md': '# Local guide\n',
          'links.md': '''
# Links

Shared: <a href="guide.md" origin="shared">Shared</a>; local: [Local](guide.md).

<include from="guide.md" element-id="part"/>
''',
        },
      );
      final shared = await writeModule(
        directory: 'shared',
        moduleName: 'shared',
        tree: '''
<instance-profile id="guide" start-page="guide.md"><toc-element topic="guide.md"/></instance-profile>
''',
        topics: {'guide.md': '# Shared guide\n'},
      );

      await editor.rename(
        module: main,
        topic: _topic(main, 'guide.md'),
        newFileName: 'setup.md',
        projectModules: [main, shared],
      );

      final links = File(
        p.join(main.rootPath, 'topics', 'links.md'),
      ).readAsStringSync();
      expect(
        links,
        contains(
          'href="guide.md" origin="shared">Shared</a>; '
          'local: [Local](setup.md)',
        ),
      );
      expect(links, contains('from="setup.md" element-id="part"'));
      final mainTree = XmlDocument.parse(
        File(p.join(main.rootPath, 'guide.tree')).readAsStringSync(),
      );
      expect(
        mainTree
            .findAllElements('toc-element')
            .map((element) => element.getAttribute('topic')),
        ['setup.md', 'guide.md'],
      );
      expect(
        File(p.join(shared.rootPath, 'topics', 'guide.md')).readAsStringSync(),
        '# Shared guide\n',
      );
    },
  );

  test('rename supports unquoted origin-qualified raw HTML links', () async {
    final root = await Directory.systemTemp.createTemp(
      'busymark-topic-file-project-unbound-origin-',
    );
    addTearDown(() => root.delete(recursive: true));
    Future<WritersideModule> writeModule({
      required String directory,
      required String moduleName,
      required String tree,
      required Map<String, String> topics,
    }) async {
      final moduleRoot = await Directory(p.join(root.path, directory)).create();
      final topicRoot = await Directory(
        p.join(moduleRoot.path, 'topics'),
      ).create();
      await File(p.join(moduleRoot.path, 'writerside.cfg')).writeAsString('''
<ihp><module name="$moduleName"/><topics dir="topics"/><instance src="guide.tree"/></ihp>
''');
      await File(p.join(moduleRoot.path, 'guide.tree')).writeAsString(tree);
      for (final entry in topics.entries) {
        await File(
          p.join(topicRoot.path, entry.key),
        ).writeAsString(entry.value);
      }
      return const WritersideModuleService().load(moduleRoot.path);
    }

    final main = await writeModule(
      directory: 'main',
      moduleName: 'main',
      tree: '''
<instance-profile id="guide" start-page="links.md">
  <toc-element topic="links.md"/>
  <toc-element topic="guide.md" origin="shared"/>
</instance-profile>
''',
      topics: {
        'links.md': '''
# Links

Text <a href=guide.md origin=shared>Shared guide</a>.
''',
      },
    );
    final shared = await writeModule(
      directory: 'shared',
      moduleName: 'shared',
      tree: '''
<instance-profile id="guide" start-page="guide.md">
  <toc-element topic="guide.md"/>
</instance-profile>
''',
      topics: {'guide.md': '# Shared guide\n'},
    );
    await editor.rename(
      module: shared,
      topic: _topic(shared, 'guide.md'),
      newFileName: 'setup.md',
      projectModules: [main, shared],
    );

    final linkPath = p.join(main.rootPath, 'topics', 'links.md');
    expect(File(linkPath).readAsStringSync(), '''
# Links

Text <a href=setup.md origin=shared>Shared guide</a>.
''');
    expect(
      File(p.join(shared.rootPath, 'topics', 'guide.md')).existsSync(),
      isFalse,
    );
    expect(
      File(p.join(shared.rootPath, 'topics', 'setup.md')).existsSync(),
      isTrue,
    );
    final reloadedMain = await const WritersideModuleService().load(
      main.rootPath,
    );
    expect(
      _topic(reloadedMain, 'links.md').links.single.destination,
      'setup.md',
    );
  });

  test('rename updates shared Markdown reference definitions once', () async {
    final fixture = await _fixture(
      trees: {
        'guide.tree': '''
<instance-profile id="guide" start-page="guide.md">
  <toc-element topic="guide.md"/>
</instance-profile>
''',
      },
      topics: {
        'guide.md': '# Guide\n',
        'references.md': '''
# References

Full [Guide][g] and repeated [again][g].
Collapsed [Guide][] and shortcut [Guide].
Inline code label: [`Guide`](guide.md).
Following-line destination: [Guide][next].

[g]: guide.md
[guide]: guide.md
[next]:
  guide.md
''',
      },
    );

    await editor.rename(
      module: fixture.module,
      topic: _topic(fixture.module, 'guide.md'),
      newFileName: 'setup.md',
    );

    final references = File(
      p.join(fixture.root.path, 'topics', 'references.md'),
    ).readAsStringSync();
    expect(references, contains('Full [Guide][g] and repeated [again][g].'));
    expect(references, contains('Collapsed [Guide][] and shortcut [Guide].'));
    expect(references, contains('Inline code label: [`Guide`](setup.md).'));
    expect(references, contains('Following-line destination: [Guide][next].'));
    expect(
      RegExp(r'^\[g\]: setup\.md$', multiLine: true).allMatches(references),
      hasLength(1),
    );
    expect(
      RegExp(r'^\[guide\]: setup\.md$', multiLine: true).allMatches(references),
      hasLength(1),
    );
    expect(references, contains('[next]:\n  setup.md'));
    expect(references, isNot(contains(']: guide.md')));
  });

  test('rename preserves escapes required by a Markdown destination', () async {
    final fixture = await _fixture(
      trees: {
        'guide.tree': '''
<instance-profile id="guide" start-page="api(tools/guide.md">
  <toc-element topic="api(tools/guide.md"/>
</instance-profile>
''',
      },
      topics: {
        'api(tools/guide.md': '# Guide\n',
        'links.md': '''
# Links

[Guide](api\\(tools/guide.md)
''',
      },
    );

    await editor.rename(
      module: fixture.module,
      topic: _topic(fixture.module, 'api(tools/guide.md'),
      newFileName: 'setup.md',
    );

    final linksPath = p.join(fixture.root.path, 'topics', 'links.md');
    expect(
      File(linksPath).readAsStringSync(),
      contains(r'[Guide](api\(tools/setup.md)'),
    );
    final reloaded = await const WritersideModuleService().load(
      fixture.root.path,
    );
    expect(
      _topic(reloaded, 'links.md').links.single.destination,
      'api(tools/setup.md',
    );
  });

  test('rename rewrites an XML-encoded topic destination', () async {
    final fixture = await _fixture(
      trees: {
        'guide.tree': '''
<instance-profile id="guide" start-page="guide.md">
  <toc-element topic="guide.md"/>
</instance-profile>
''',
      },
      topics: {
        'guide.md': '# Guide\n',
        'links.topic': '''
<topic id="links" title="Links">
  <a href="guide&#46;md">Guide</a>
</topic>
''',
      },
    );

    await editor.rename(
      module: fixture.module,
      topic: _topic(fixture.module, 'guide.md'),
      newFileName: 'setup.md',
    );

    final linksPath = p.join(fixture.root.path, 'topics', 'links.topic');
    final linksSource = File(linksPath).readAsStringSync();
    expect(linksSource, contains('href="setup.md"'));
    expect(
      XmlDocument.parse(
        linksSource,
      ).findAllElements('a').single.getAttribute('href'),
      'setup.md',
    );
  });

  test('rename escapes decoded XML attribute replacements', () async {
    final fixture = await _fixture(
      trees: {
        'guide.tree': '''
<instance-profile id="guide" start-page="api&amp;tools/guide.md">
  <toc-element topic="api&amp;tools/guide.md"/>
</instance-profile>
''',
      },
      topics: {
        'api&tools/guide.md': '# Guide\n',
        'links.topic': '''
<topic id="links" title="Links">
  <a href="api&amp;tools/guide.md">Guide</a>
</topic>
''',
      },
    );

    final result = await editor.rename(
      module: fixture.module,
      topic: _topic(fixture.module, 'api&tools/guide.md'),
      newFileName: 'setup.md',
    );

    expect(
      p.normalize(result.newTopicPath),
      p.normalize(p.join(fixture.root.path, 'topics', 'api&tools', 'setup.md')),
    );
    final linksSource = File(
      p.join(fixture.root.path, 'topics', 'links.topic'),
    ).readAsStringSync();
    expect(linksSource, contains('href="api&amp;tools/setup.md"'));
    expect(
      XmlDocument.parse(
        linksSource,
      ).findAllElements('a').single.getAttribute('href'),
      'api&tools/setup.md',
    );
    expect(
      _tree(fixture.root, 'guide.tree').rootElement.getAttribute('start-page'),
      'api&tools/setup.md',
    );
  });

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

  test('rename preserves topic and instance tree file modes', () async {
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
  }, skip: Platform.isWindows ? 'POSIX file modes only.' : false);

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
