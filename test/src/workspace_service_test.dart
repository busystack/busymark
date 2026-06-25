import 'dart:io';

import 'package:busymark/src/core/path_utils.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:busymark/src/workspace/workspace_service.dart';
import 'package:busymark/src/writerside/writerside_project_creator.dart';
import 'package:busymark/src/writerside/writerside_topic_creator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  const service = WorkspaceService();

  test('opens a single Markdown file workspace', () async {
    final workspace = await service.openPath('test/fixtures/markdown/basic.md');

    expect(workspace.kind, WorkspaceKind.singleMarkdown);
    expect(workspace.markdown?.title, 'Basic Markdown');
    expect(workspace.activeFilePath, isNotNull);
  });

  test('opens a Markdown file from a file URI path', () async {
    final file = File('test/fixtures/markdown/basic.md');
    final workspace = await service.openPath(file.absolute.uri.toString());

    expect(workspace.kind, WorkspaceKind.singleMarkdown);
    expect(workspace.activeFilePath, file.absolute.path);
    expect(workspace.markdown?.title, 'Basic Markdown');
  });

  test('opens a generic Markdown folder workspace', () async {
    final workspace = await service.openPath('test/fixtures/markdown');

    expect(workspace.kind, WorkspaceKind.markdownFolder);
    expect(
      workspace.files.where((item) => item.relativePath.endsWith('.md')),
      isNotEmpty,
    );
  });

  test('opens a Writerside module workspace', () async {
    final workspace = await service.openPath(
      'test/fixtures/writerside/basic_project',
    );

    expect(workspace.kind, WorkspaceKind.writersideModule);
    expect(workspace.writersideModule?.instances.single.name, 'User Guide');
    expect(workspace.activeFilePath, endsWith('intro.md'));
  });

  test('creates and opens a Writerside starter project', () async {
    final parent = await Directory.systemTemp.createTemp(
      'busymark-workspace-create-',
    );
    addTearDown(() async {
      if (await parent.exists()) {
        await parent.delete(recursive: true);
      }
    });

    final workspace = await service.createWritersideProject(
      WritersideProjectCreateRequest(
        parentDirectoryPath: parent.path,
        projectName: 'Docs',
        directoryName: 'docs',
      ),
    );

    expect(workspace.kind, WorkspaceKind.writersideModule);
    expect(
      workspace.activeFilePath,
      endsWith(p.join('topics', 'getting-started.md')),
    );
    expect(File(workspace.activeFilePath!).existsSync(), isTrue);
    expect(workspace.markdown?.title, 'Getting started');
    expect(
      workspace.diagnostics.where((item) => item.severity.name == 'error'),
      isEmpty,
    );
  });

  test(
    'reparses and previews Writerside Markdown without generic link validation',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'busymark-workspace-writerside-links-',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
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
      final activeFile = File(p.join(root.path, 'topics', 'intro.md'))
        ..writeAsStringSync('''
# Intro

[API](api.md)
''');
      File(p.join(root.path, 'reference', 'api.md')).writeAsStringSync('''
# API
''');
      final parser = _RecordingMarkdownParser();
      final parserService = WorkspaceService(markdownParser: parser);
      final workspace = await parserService.openPath(root.path);

      final reparsed = await parserService.reparseActive(
        workspace,
        activeFile.readAsStringSync(),
      );
      parserService.buildPreview(workspace, activeFile.readAsStringSync());

      expect(parser.validationFlags, [false, false]);
      expect(
        reparsed.diagnostics.map((diagnostic) => diagnostic.code),
        isNot(contains('markdown.link.unresolved-target')),
      );
    },
  );

  test(
    'creates a Writerside Markdown topic and registers it in the TOC',
    () async {
      final parent = await Directory.systemTemp.createTemp(
        'busymark-workspace-create-topic-',
      );
      addTearDown(() async {
        if (await parent.exists()) {
          await parent.delete(recursive: true);
        }
      });
      final workspace = await service.createWritersideProject(
        WritersideProjectCreateRequest(
          parentDirectoryPath: parent.path,
          projectName: 'Docs',
          directoryName: 'docs',
        ),
      );

      final updated = await service.createWritersideTopic(
        workspace,
        const WritersideTopicCreateRequest(
          title: 'Install BusyMark',
          fileName: 'install',
        ),
      );

      final topicPath = p.join(updated.rootPath, 'topics', 'install.md');
      final treeSource = File(
        p.join(updated.rootPath, 'user-guide.tree'),
      ).readAsStringSync();

      expect(updated.activeFilePath, topicPath);
      expect(File(topicPath).existsSync(), isTrue);
      expect(
        File(topicPath).readAsStringSync(),
        startsWith('# Install BusyMark'),
      );
      expect(treeSource, contains('topic="install.md"'));
      expect(updated.markdown?.title, 'Install BusyMark');
      expect(
        updated.diagnostics.where((item) => item.severity.name == 'error'),
        isEmpty,
      );
    },
  );

  test('normalizes portal-style document paths as filesystem paths', () {
    const path = '/run/user/1000/doc/abcdef/smoke.md';

    expect(normalizePath(path), path);
    expect(isPortalDocumentPath(path), isTrue);
  });

  test(
    'folder scan skips generated directories and binary resources',
    () async {
      final directory = await Directory.systemTemp.createTemp('busymark-scan-');
      await File('${directory.path}/README.md').writeAsString('# Readme\n');
      await Directory('${directory.path}/node_modules').create();
      await File(
        '${directory.path}/node_modules/ignored.md',
      ).writeAsString('# Ignored\n');
      await File('${directory.path}/binary.bin').writeAsBytes([0, 1, 2, 3]);

      final workspace = await service.openPath(directory.path);

      expect(
        workspace.files.map((file) => file.relativePath),
        contains('README.md'),
      );
      expect(
        workspace.files.map((file) => file.relativePath),
        isNot(contains('node_modules/ignored.md')),
      );
      expect(
        workspace.files.map((file) => file.relativePath),
        isNot(contains('binary.bin')),
      );

      await directory.delete(recursive: true);
    },
  );

  test(
    'limited folder scan prefers shallow siblings before deep subtree',
    () async {
      final directory = await Directory.systemTemp.createTemp('busymark-wide-');
      try {
        await Directory(p.join(directory.path, 'a')).create();
        await File(
          p.join(directory.path, 'a', 'guide.md'),
        ).writeAsString('# A\n');
        await Directory(p.join(directory.path, 'b')).create();
        await File(
          p.join(directory.path, 'b', 'guide.md'),
        ).writeAsString('# B\n');
        await Directory(
          p.join(directory.path, 'z', 'deep'),
        ).create(recursive: true);
        for (var index = 0; index < 8; index += 1) {
          await File(
            p.join(directory.path, 'z', 'deep', '$index.md'),
          ).writeAsString('# Deep $index\n');
        }

        final limitedService = WorkspaceService(
          scanOptions: const WorkspaceScanOptions(maxTreeEntries: 2),
        );
        final workspace = await limitedService.openPath(directory.path);
        final relativePaths = workspace.files.map((file) => file.relativePath);

        expect(relativePaths, containsAll(['a/guide.md', 'b/guide.md']));
        expect(relativePaths, isNot(contains('z/deep/0.md')));
        expect(workspace.rootPath, directory.path);
        expect(workspace.kind, WorkspaceKind.markdownFolder);
        expect(
          workspace.diagnostics.map((diagnostic) => diagnostic.code),
          contains('workspace.scan.skipped'),
        );
      } finally {
        await directory.delete(recursive: true);
      }
    },
  );

  test('invalid UTF-8 Markdown does not fail the whole workspace', () async {
    final directory = await Directory.systemTemp.createTemp(
      'busymark-invalid-',
    );
    await File('${directory.path}/good.md').writeAsString('# Good\n');
    await File('${directory.path}/bad.md').writeAsBytes([0xff, 0xfe, 0xfd]);

    final workspace = await service.openPath(directory.path);

    expect(
      workspace.files.map((file) => file.relativePath),
      contains('bad.md'),
    );
    expect(
      workspace.diagnostics.map((diagnostic) => diagnostic.code),
      contains('workspace.file.read-failed'),
    );

    await directory.delete(recursive: true);
  });

  test(
    'large Markdown files are listed but not parsed automatically',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'busymark-large-',
      );
      await File(
        '${directory.path}/large.md',
      ).writeAsString('# Large\n\nBody\n');
      final limitedService = WorkspaceService(
        scanOptions: const WorkspaceScanOptions(maxParsedFileBytes: 8),
      );

      final workspace = await limitedService.openPath(directory.path);

      expect(
        workspace.files.map((file) => file.relativePath),
        contains('large.md'),
      );
      expect(
        workspace.diagnostics.map((diagnostic) => diagnostic.code),
        contains('workspace.file.too-large'),
      );
      expect(workspace.markdown, isNull);

      await directory.delete(recursive: true);
    },
  );
}

class _RecordingMarkdownParser extends MarkdownParser {
  _RecordingMarkdownParser();

  final List<bool> validationFlags = [];

  @override
  ParsedMarkdownDocument parse({
    required String filePath,
    required String source,
    MarkdownMode mode = MarkdownMode.commonMark,
    String? workspaceRoot,
    bool validateLocalReferences = true,
  }) {
    validationFlags.add(validateLocalReferences);
    return super.parse(
      filePath: filePath,
      source: source,
      mode: mode,
      workspaceRoot: workspaceRoot,
      validateLocalReferences: validateLocalReferences,
    );
  }
}
