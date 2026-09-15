import 'dart:io';

import 'package:busymark/src/writerside/writerside_module_service.dart';
import 'package:busymark/src/writerside/writerside_project.dart';
import 'package:busymark/src/writerside/writerside_web_file_name.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('canonical Writerside web filenames', () {
    test('normalizes runs, edges, case, and Unicode once', () {
      expect(
        WritersideWebFileNameResolver.defaultName(
          'Document_everything.topic',
          disablePreprocessing: false,
        ),
        'document-everything.html',
      );
      expect(
        WritersideWebFileNameResolver.defaultName(
          'My___Awesome.topic',
          disablePreprocessing: false,
        ),
        'my-awesome.html',
      );
      expect(
        WritersideWebFileNameResolver.defaultName(
          '_-Guide--_.topic',
          disablePreprocessing: false,
        ),
        'guide.html',
      );
      expect(
        WritersideWebFileNameResolver.defaultName(
          'Руководство_開始.topic',
          disablePreprocessing: false,
        ),
        'руководство-開始.html',
      );
    });

    test('disabled preprocessing preserves established safe characters', () {
      expect(
        WritersideWebFileNameResolver.defaultName(
          'Document_everything.topic',
          disablePreprocessing: true,
        ),
        'Document_everything.html',
      );
      expect(
        WritersideWebFileNameResolver.defaultName(
          'Guide name.topic',
          disablePreprocessing: true,
        ),
        'Guide-name.html',
      );
    });

    test(
      'resolves exact custom values per instance for Markdown and XML',
      () async {
        final root = await _module(
          trees: {
            'linux.tree': _tree('linux', [
              'conditional.md',
              'conditional.topic',
            ]),
            'windows.tree': _tree('windows', [
              'conditional.md',
              'conditional.topic',
            ]),
          },
          topics: {
            'conditional.md': '''
# Markdown

<web-file-name instance="linux">Keep_CASE.v2.html</web-file-name>
<web-file-name instance="windows">windows-markdown.html</web-file-name>
''',
            'conditional.topic': '''
<topic id="conditional" title="XML">
  <web-file-name instance="linux">linux-xml.html</web-file-name>
  <web-file-name instance="windows">Windows_Exact.HTML</web-file-name>
</topic>
''',
          },
        );
        final module = await const WritersideModuleService().load(root.path);
        final instances = {
          for (final value in module.instances) value.id: value,
        };
        final modules = {'docs': module};
        const resolver = WritersideWebFileNameResolver();

        expect(
          resolver
              .resolve(
                module: module,
                topic: module.topicByReference('conditional.md')!,
                instance: instances['linux']!,
                modulesByOrigin: modules,
              )
              .value,
          'Keep_CASE.v2.html',
        );
        expect(
          resolver
              .resolve(
                module: module,
                topic: module.topicByReference('conditional.md')!,
                instance: instances['windows']!,
                modulesByOrigin: modules,
              )
              .value,
          'windows-markdown.html',
        );
        expect(
          resolver
              .resolve(
                module: module,
                topic: module.topicByReference('conditional.topic')!,
                instance: instances['linux']!,
                modulesByOrigin: modules,
              )
              .value,
          'linux-xml.html',
        );
        expect(
          resolver
              .resolve(
                module: module,
                topic: module.topicByReference('conditional.topic')!,
                instance: instances['windows']!,
                modulesByOrigin: modules,
              )
              .value,
          'Windows_Exact.HTML',
        );
      },
    );
  });

  group('project instance URL diagnostics', () {
    test('diagnoses default/default collision', () async {
      final root = await _module(
        trees: {
          'guide.tree': _tree('guide', ['Guide_A.topic', 'Guide-A.topic']),
        },
        topics: {
          'Guide_A.topic': '<topic id="Guide_A" title="One"/>',
          'Guide-A.topic': '<topic id="Guide-A" title="Two"/>',
        },
      );

      expect(
        await _diagnosticCodes(root.path),
        contains('writerside.web-file-name.collision'),
      );
    });

    test('diagnoses default/custom collision', () async {
      final root = await _module(
        trees: {
          'guide.tree': _tree('guide', ['setup.topic', 'other.topic']),
        },
        topics: {
          'setup.topic': '<topic id="setup" title="Setup"/>',
          'other.topic': '''
<topic id="other" title="Other">
  <web-file-name>setup.html</web-file-name>
</topic>
''',
        },
      );

      expect(
        await _diagnosticCodes(root.path),
        contains('writerside.web-file-name.collision'),
      );
    });

    test('diagnoses custom/custom collision', () async {
      final root = await _module(
        trees: {
          'guide.tree': _tree('guide', ['one.md', 'two.md']),
        },
        topics: {
          'one.md': '# One\n\n<web-file-name>shared.html</web-file-name>\n',
          'two.md': '# Two\n\n<web-file-name>shared.html</web-file-name>\n',
        },
      );

      expect(
        await _diagnosticCodes(root.path),
        contains('writerside.web-file-name.collision'),
      );
    });

    test('allows the same output name in disjoint instances', () async {
      final root = await _module(
        trees: {
          'one.tree': _tree('one', ['one.topic']),
          'two.tree': _tree('two', ['two.topic']),
        },
        topics: {
          'one.topic': '''
<topic id="one" title="One"><web-file-name>shared.html</web-file-name></topic>
''',
          'two.topic': '''
<topic id="two" title="Two"><web-file-name>shared.html</web-file-name></topic>
''',
        },
      );

      expect(
        await _diagnosticCodes(root.path),
        isNot(contains('writerside.web-file-name.collision')),
      );
    });

    test('deduplicates repeated publication of one physical topic', () async {
      final root = await _module(
        trees: {
          'guide.tree': _tree('guide', ['one.topic', 'one.topic']),
        },
        topics: {'one.topic': '<topic id="one" title="One"/>'},
      );

      expect(
        await _diagnosticCodes(root.path),
        isNot(contains('writerside.web-file-name.collision')),
      );
    });

    test('diagnoses a collision with an origin module topic', () async {
      final project = await Directory.systemTemp.createTemp(
        'busymark-web-name-project-',
      );
      addTearDown(() async {
        if (await project.exists()) await project.delete(recursive: true);
      });
      await _module(
        parent: project,
        directoryName: 'main',
        moduleName: 'main',
        trees: {
          'guide.tree': '''
<instance-profile id="guide">
  <toc-element topic="setup.topic"/>
  <toc-element topic="shared.topic" origin="shared"/>
</instance-profile>
''',
        },
        topics: {'setup.topic': '<topic id="setup" title="Setup"/>'},
      );
      await _module(
        parent: project,
        directoryName: 'shared',
        moduleName: 'shared',
        library: true,
        trees: {
          'library.tree': _tree('library', ['shared.topic'], library: true),
        },
        topics: {
          'shared.topic': '''
<topic id="shared" title="Shared">
  <web-file-name>setup.html</web-file-name>
</topic>
''',
        },
      );

      expect(
        await _diagnosticCodes(project.path),
        contains('writerside.web-file-name.collision'),
      );
    });

    test('resolves conditioned names independently in each instance', () async {
      final root = await _module(
        trees: {
          'one.tree': _tree('one', ['conditional.topic', 'first.topic']),
          'two.tree': _tree('two', ['conditional.topic', 'second.topic']),
        },
        topics: {
          'conditional.topic': '''
<topic id="conditional" title="Conditional">
  <web-file-name instance="one">one-special.html</web-file-name>
  <web-file-name instance="two">two-special.html</web-file-name>
</topic>
''',
          'first.topic': '<topic id="first" title="First"/>',
          'second.topic': '<topic id="second" title="Second"/>',
        },
      );

      expect(
        await _diagnosticCodes(root.path),
        isNot(contains('writerside.web-file-name.collision')),
      );
    });

    test('diagnoses invalid custom filenames before export', () async {
      final root = await _module(
        trees: {
          'guide.tree': _tree('guide', ['bad.topic']),
        },
        topics: {
          'bad.topic': '''
<topic id="bad" title="Bad"><web-file-name>../bad.html</web-file-name></topic>
''',
        },
      );

      expect(
        await _diagnosticCodes(root.path),
        contains('writerside.web-file-name.invalid'),
      );
    });
  });
}

Future<Directory> _module({
  Directory? parent,
  String directoryName = 'module',
  String moduleName = 'docs',
  bool library = false,
  required Map<String, String> trees,
  required Map<String, String> topics,
}) async {
  final ownedRoot = parent == null
      ? await Directory.systemTemp.createTemp('busymark-web-name-module-')
      : null;
  final root =
      parent == null
            ? ownedRoot!
            : Directory(p.join(parent.path, directoryName))
        ..createSync();
  if (ownedRoot != null) {
    addTearDown(() async {
      if (await ownedRoot.exists()) await ownedRoot.delete(recursive: true);
    });
  }
  final config = StringBuffer('''
<ihp version="2.0">
  <module name="$moduleName"/>
  <topics dir="topics"/>
''');
  for (final tree in trees.keys) {
    config.writeln('  <instance src="$tree"/>');
  }
  config.write('</ihp>\n');
  File(p.join(root.path, 'writerside.cfg')).writeAsStringSync('$config');
  final topicsDirectory = Directory(p.join(root.path, 'topics'))..createSync();
  for (final entry in trees.entries) {
    final source = library && !entry.value.contains('is-library=')
        ? entry.value.replaceFirst(
            '<instance-profile ',
            '<instance-profile is-library="true" ',
          )
        : entry.value;
    File(p.join(root.path, entry.key)).writeAsStringSync(source);
  }
  for (final entry in topics.entries) {
    File(
      p.join(topicsDirectory.path, entry.key),
    ).writeAsStringSync(entry.value);
  }
  return Directory(await root.resolveSymbolicLinks());
}

String _tree(String id, List<String> topics, {bool library = false}) =>
    '''
<instance-profile id="$id"${library ? ' is-library="true"' : ''}>
${[for (final topic in topics) '  <toc-element topic="$topic"/>'].join('\n')}
</instance-profile>
''';

Future<List<String>> _diagnosticCodes(String root) async => [
  for (final diagnostic in (await const WritersideProjectService().load(
    root,
  )).diagnostics)
    diagnostic.code,
];
