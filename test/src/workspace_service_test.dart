import 'dart:io';

import 'package:busymark/src/core/busymark_exception.dart';
import 'package:busymark/src/core/path_utils.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:busymark/src/workspace/workspace_service.dart';
import 'package:busymark/src/writerside/writerside_module_service.dart';
import 'package:busymark/src/writerside/writerside_project_creator.dart';
import 'package:busymark/src/writerside/writerside_topic_creator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

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

  test(
    'canonicalizes a workspace opened through a directory symlink',
    () async {
      final base = await Directory.systemTemp.createTemp(
        'busymark-workspace-root-symlink-',
      );
      addTearDown(() async {
        if (await base.exists()) {
          await base.delete(recursive: true);
        }
      });
      final root = Directory(p.join(base.path, 'workspace'))..createSync();
      final rootLink = Link(p.join(base.path, 'workspace-link'))
        ..createSync(root.path);
      final canonicalRoot = await root.resolveSymbolicLinks();

      final workspace = await service.openPath(rootLink.path);
      final createdPath = await service.createFile(
        workspace,
        workspace.rootPath,
        'created.md',
      );

      expect(workspace.rootPath, canonicalRoot);
      expect(createdPath, p.join(canonicalRoot, 'created.md'));
      expect(File(p.join(canonicalRoot, 'created.md')).existsSync(), isTrue);
    },
    skip: Platform.isWindows ? 'POSIX symlink behavior only.' : false,
  );

  test(
    'rejects a workspace root replaced by a symlink after opening',
    () async {
      final base = await Directory.systemTemp.createTemp(
        'busymark-workspace-root-replaced-',
      );
      addTearDown(() async {
        if (await base.exists()) {
          await base.delete(recursive: true);
        }
      });
      final root = Directory(p.join(base.path, 'workspace'))..createSync();
      final outside = Directory(p.join(base.path, 'outside'))..createSync();
      final workspace = await service.openPath(root.path);
      final displacedRoot = p.join(base.path, 'workspace-original');
      await root.rename(displacedRoot);
      await Link(workspace.rootPath).create(outside.path);

      await expectLater(
        service.createFile(workspace, workspace.rootPath, 'escaped.md'),
        throwsA(isA<BusyMarkException>()),
      );

      expect(File(p.join(outside.path, 'escaped.md')).existsSync(), isFalse);
    },
    skip: Platform.isWindows ? 'POSIX symlink behavior only.' : false,
  );

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
        instanceName: 'User Guide',
        topicTitle: 'Getting started',
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
      final preview = parserService.buildPreview(
        workspace,
        activeFile.readAsStringSync(),
      );

      expect(parser.validationFlags, [false]);
      expect(preview?.blocks.map((block) => block.text), ['Intro', 'API']);
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
          instanceName: 'User Guide',
          topicTitle: 'Getting started',
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

  test(
    'creates a topic in the explicitly selected instance and TOC node',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'busymark-workspace-selected-instance-',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      Directory(p.join(root.path, 'topics')).createSync();
      File(p.join(root.path, 'writerside.cfg')).writeAsStringSync('''
<ihp version="2.0">
  <topics dir="topics"/>
  <instance src="first.tree"/>
  <instance src="second.tree"/>
</ihp>
''');
      File(p.join(root.path, 'first.tree')).writeAsStringSync('''
<instance-profile id="first" name="First" start-page="first.md">
  <toc-element topic="first.md"/>
</instance-profile>
''');
      final secondTree = File(p.join(root.path, 'second.tree'))
        ..writeAsStringSync('''
<instance-profile id="second" name="Second" start-page="second.md">
  <toc-element topic="second.md"/>
</instance-profile>
''');
      File(
        p.join(root.path, 'topics', 'first.md'),
      ).writeAsStringSync('# First\n');
      File(
        p.join(root.path, 'topics', 'second.md'),
      ).writeAsStringSync('# Second\n');
      final workspace = await service.openPath(root.path);
      final firstTreeBefore = File(
        p.join(root.path, 'first.tree'),
      ).readAsStringSync();

      final updated = await service.createWritersideTopic(
        workspace,
        const WritersideTopicCreateRequest(
          title: 'Second child',
          fileName: 'second-child.md',
          placement: WritersideTopicCreatePlacement.child,
          referenceTopic: 'second.md',
          referenceTocPath: [0],
        ),
        instanceTreePath: secondTree.path,
      );

      final secondDocument = XmlDocument.parse(secondTree.readAsStringSync());
      final second = secondDocument
          .findAllElements('toc-element')
          .firstWhere(
            (element) => element.getAttribute('topic') == 'second.md',
          );
      expect(
        second.childElements.map((element) => element.getAttribute('topic')),
        contains('second-child.md'),
      );
      expect(
        File(p.join(root.path, 'first.tree')).readAsStringSync(),
        firstTreeBefore,
      );
      expect(
        updated.activeFilePath,
        p.join(root.path, 'topics', 'second-child.md'),
      );
    },
  );

  test(
    'rejects topic creation when the configured instance tree is outside the module',
    () async {
      final base = await Directory.systemTemp.createTemp(
        'busymark-writerside-external-tree-',
      );
      addTearDown(() async {
        if (await base.exists()) {
          await base.delete(recursive: true);
        }
      });
      final root = Directory(p.join(base.path, 'module'))..createSync();
      Directory(p.join(root.path, 'topics')).createSync();
      File(p.join(root.path, 'writerside.cfg')).writeAsStringSync('''
<ihp version="2.0">
  <topics dir="topics"/>
  <instance src="../victim.tree"/>
</ihp>
''');
      final victim = File(p.join(base.path, 'victim.tree'))
        ..writeAsStringSync('''
<instance-profile id="victim" name="Victim" start-page="intro.md">
  <toc-element topic="intro.md"/>
</instance-profile>
''');
      final originalVictimSource = victim.readAsStringSync();
      final workspace = await service.openPath(root.path);

      await expectLater(
        service.createWritersideTopic(
          workspace,
          const WritersideTopicCreateRequest(
            title: 'Escaped topic',
            fileName: 'escaped',
          ),
        ),
        throwsA(isA<BusyMarkException>()),
      );

      expect(victim.readAsStringSync(), originalVictimSource);
      expect(
        File(p.join(root.path, 'topics', 'escaped.md')).existsSync(),
        isFalse,
      );
    },
  );

  test('normalizes portal-style document paths as filesystem paths', () {
    const path = '/run/user/1000/doc/abcdef/smoke.md';

    expect(normalizePath(path), path);
    expect(isPortalDocumentPath(path), isTrue);
  });

  test('saveText writes content and returns the saved file snapshot', () async {
    final directory = await Directory.systemTemp.createTemp(
      'busymark-atomic-save-',
    );
    addTearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });
    final file = File(p.join(directory.path, 'note.md'));

    final snapshot = await service.saveText(file.path, '# Saved\n');

    expect(await file.readAsString(), '# Saved\n');
    expect(snapshot.size, '# Saved\n'.length);
    expect(snapshot.contentHash, hasLength(64));
    final leftovers = await directory
        .list()
        .where((entity) => p.basename(entity.path).contains('busymark-save'))
        .toList();
    expect(leftovers, isEmpty);
  });

  test('file change detection ignores timestamp-only changes', () async {
    final directory = await Directory.systemTemp.createTemp(
      'busymark-metadata-touch-',
    );
    addTearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });
    final file = File(p.join(directory.path, 'note.md'));
    await file.writeAsString('# Unchanged\n');
    final snapshot = await service.fileSnapshot(file.path);

    await file.setLastModified(
      snapshot.modifiedAt.add(const Duration(seconds: 2)),
    );

    expect(await service.fileChangedSince(file.path, snapshot), isFalse);
  });

  test('saveNewText writes a missing file and returns its snapshot', () async {
    final directory = await Directory.systemTemp.createTemp(
      'busymark-new-save-',
    );
    addTearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });
    final file = File(p.join(directory.path, 'note.md'));

    final snapshot = await service.saveNewText(file.path, '# Created\n');

    expect(await file.readAsString(), '# Created\n');
    expect(snapshot.size, '# Created\n'.length);
    expect(snapshot.contentHash, hasLength(64));
  });

  test('saveNewText refuses an existing file without changing it', () async {
    final directory = await Directory.systemTemp.createTemp(
      'busymark-new-save-collision-',
    );
    addTearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });
    final file = File(p.join(directory.path, 'note.md'));
    await file.writeAsString('# Original\n');

    await expectLater(
      service.saveNewText(file.path, '# Replacement\n'),
      throwsA(
        isA<BusyMarkException>().having(
          (error) => error.code,
          'code',
          'workspace.path-already-exists',
        ),
      ),
    );

    expect(await file.readAsString(), '# Original\n');
  });

  test(
    'saveNewText does not replace a file arriving before publication',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'busymark-new-save-race-',
      );
      addTearDown(() async {
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      });
      final file = File(p.join(directory.path, 'note.md'));
      final racingService = WorkspaceService(
        beforeNewFilePublish: (targetPath) async {
          await File(targetPath).writeAsString('# Arrived\n', flush: true);
        },
      );

      await expectLater(
        racingService.saveNewText(file.path, '# Draft\n'),
        throwsA(
          isA<BusyMarkException>().having(
            (error) => error.code,
            'code',
            'workspace.path-already-exists',
          ),
        ),
      );

      expect(await file.readAsString(), '# Arrived\n');
      final leftovers = await directory
          .list()
          .where(
            (entity) => p.basename(entity.path).startsWith('.busymark-save-'),
          )
          .toList();
      expect(leftovers, isEmpty);
    },
    skip: !Platform.isLinux
        ? 'The application currently supports Linux desktop only.'
        : false,
  );

  test(
    'saveNewText does not write inside a directory arriving before publication',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'busymark-new-save-directory-race-',
      );
      addTearDown(() async {
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      });
      final targetDirectory = Directory(p.join(directory.path, 'note.md'));
      final racingService = WorkspaceService(
        beforeNewFilePublish: (targetPath) => Directory(targetPath).create(),
      );

      await expectLater(
        racingService.saveNewText(targetDirectory.path, '# Draft\n'),
        throwsA(
          isA<BusyMarkException>().having(
            (error) => error.code,
            'code',
            'workspace.path-already-exists',
          ),
        ),
      );

      expect(await targetDirectory.exists(), isTrue);
      expect(await targetDirectory.list().toList(), isEmpty);
    },
    skip: !Platform.isLinux
        ? 'The application currently supports Linux desktop only.'
        : false,
  );

  test(
    'saveTextReplacingPath replaces a final symlink without following it',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'busymark-save-as-symlink-',
      );
      addTearDown(() async {
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      });
      final target = File(p.join(directory.path, 'target.md'));
      final link = Link(p.join(directory.path, 'note.md'));
      await target.writeAsString('# Target\n');
      await link.create(target.path);

      final snapshot = await service.saveTextReplacingPath(
        link.path,
        '# Replacement\n',
      );

      expect(
        await FileSystemEntity.type(link.path, followLinks: false),
        FileSystemEntityType.file,
      );
      expect(await File(link.path).readAsString(), '# Replacement\n');
      expect(await target.readAsString(), '# Target\n');
      expect(snapshot.size, '# Replacement\n'.length);
    },
    skip: Platform.isWindows ? 'POSIX symlink behavior only.' : false,
  );

  test(
    'saveText follows file symlinks and preserves target permissions',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'busymark-symlink-save-',
      );
      addTearDown(() async {
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      });
      final target = File(p.join(directory.path, 'target.md'));
      await target.writeAsString('# Original\n');
      final chmod = await Process.run('chmod', ['600', target.path]);
      expect(chmod.exitCode, 0);
      final link = Link(p.join(directory.path, 'link.md'));
      await link.create(target.path);

      final snapshot = await service.saveText(link.path, '# Saved\n');

      expect(
        FileSystemEntity.typeSync(link.path, followLinks: false),
        FileSystemEntityType.link,
      );
      expect(await target.readAsString(), '# Saved\n');
      expect(await File(link.path).readAsString(), '# Saved\n');
      expect((await target.stat()).mode & 0x1ff, 0x180);
      expect(snapshot.size, '# Saved\n'.length);
    },
    skip: Platform.isWindows
        ? 'POSIX symlink and permission behavior only.'
        : false,
  );

  test(
    'createFile rejects a directory reached through an intermediate symlink',
    () async {
      final fixture = await _createWorkspaceSymlinkFixture();
      final outsideDirectory = Directory(p.join(fixture.outside.path, 'nested'))
        ..createSync();
      final escapedFile = File(p.join(outsideDirectory.path, 'escaped.md'));

      await expectLater(
        service.createFile(
          fixture.workspace,
          p.join(fixture.link.path, 'nested'),
          'escaped.md',
        ),
        throwsA(isA<BusyMarkException>()),
      );

      expect(escapedFile.existsSync(), isFalse);
    },
    skip: Platform.isWindows ? 'POSIX symlink behavior only.' : false,
  );

  test(
    'renameEntity rejects a source reached through an intermediate symlink',
    () async {
      final fixture = await _createWorkspaceSymlinkFixture();
      final outsideDirectory = Directory(p.join(fixture.outside.path, 'nested'))
        ..createSync();
      final source = File(p.join(outsideDirectory.path, 'source.md'))
        ..writeAsStringSync('# Outside\n');
      final renamed = File(p.join(outsideDirectory.path, 'renamed.md'));

      await expectLater(
        service.renameEntity(
          fixture.workspace,
          p.join(fixture.link.path, 'nested', 'source.md'),
          'renamed.md',
        ),
        throwsA(isA<BusyMarkException>()),
      );

      expect(source.readAsStringSync(), '# Outside\n');
      expect(renamed.existsSync(), isFalse);
    },
    skip: Platform.isWindows ? 'POSIX symlink behavior only.' : false,
  );

  test(
    'moveEntity rejects a target reached through an intermediate symlink',
    () async {
      final fixture = await _createWorkspaceSymlinkFixture();
      final source = File(p.join(fixture.root.path, 'source.md'))
        ..writeAsStringSync('# Inside\n');
      final outsideDirectory = Directory(
        p.join(fixture.outside.path, 'destination'),
      )..createSync();
      final escapedFile = File(p.join(outsideDirectory.path, 'source.md'));

      await expectLater(
        service.moveEntity(
          fixture.workspace,
          source.path,
          p.join(fixture.link.path, 'destination'),
        ),
        throwsA(isA<BusyMarkException>()),
      );

      expect(source.readAsStringSync(), '# Inside\n');
      expect(escapedFile.existsSync(), isFalse);
    },
    skip: Platform.isWindows ? 'POSIX symlink behavior only.' : false,
  );

  test(
    'deleteEntity rejects a directory reached through an intermediate symlink',
    () async {
      final fixture = await _createWorkspaceSymlinkFixture();
      final victim = Directory(p.join(fixture.outside.path, 'nested', 'victim'))
        ..createSync(recursive: true);
      final sentinel = File(p.join(victim.path, 'keep.md'))
        ..writeAsStringSync('# Keep\n');

      await expectLater(
        service.deleteEntity(
          fixture.workspace,
          p.join(fixture.link.path, 'nested', 'victim'),
        ),
        throwsA(isA<BusyMarkException>()),
      );

      expect(sentinel.readAsStringSync(), '# Keep\n');
    },
    skip: Platform.isWindows ? 'POSIX symlink behavior only.' : false,
  );

  test(
    'deleteEntity removes a final symlink without deleting its target',
    () async {
      final fixture = await _createWorkspaceSymlinkFixture();
      final sentinel = File(p.join(fixture.outside.path, 'keep.md'))
        ..writeAsStringSync('# Keep\n');

      await service.deleteEntity(fixture.workspace, fixture.link.path);

      expect(
        FileSystemEntity.typeSync(fixture.link.path, followLinks: false),
        FileSystemEntityType.notFound,
      );
      expect(sentinel.readAsStringSync(), '# Keep\n');
    },
    skip: Platform.isWindows ? 'POSIX symlink behavior only.' : false,
  );

  test('missing nested mutation paths keep domain-specific errors', () async {
    final root = await Directory.systemTemp.createTemp(
      'busymark-workspace-missing-path-',
    );
    addTearDown(() async {
      if (await root.exists()) {
        await root.delete(recursive: true);
      }
    });
    final workspace = await service.openPath(root.path);
    final missingDirectory = p.join(workspace.rootPath, 'missing', 'nested');

    await expectLater(
      service.createFile(workspace, missingDirectory, 'new.md'),
      throwsA(
        isA<BusyMarkException>().having(
          (error) => error.code,
          'code',
          'workspace.directory-missing',
        ),
      ),
    );
    await expectLater(
      service.deleteEntity(workspace, p.join(missingDirectory, 'old.md')),
      throwsA(
        isA<BusyMarkException>().having(
          (error) => error.code,
          'code',
          'workspace.path-does-not-exist',
        ),
      ),
    );
  });

  test('fileChangedSince treats deleted files as changed', () async {
    final directory = await Directory.systemTemp.createTemp(
      'busymark-conflict-missing-',
    );
    addTearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });
    final file = File(p.join(directory.path, 'note.md'));
    await file.writeAsString('# Original\n');
    final load = await service.loadTextWithSnapshot(file.path);

    await file.delete();

    expect(await service.fileChangedSince(file.path, load.snapshot), isTrue);
  });

  test(
    'fileChangedSince detects content changes with unchanged modified time',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'busymark-conflict-hash-',
      );
      addTearDown(() async {
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      });
      final file = File(p.join(directory.path, 'note.md'));
      await file.writeAsString('# Original\n');
      final load = await service.loadTextWithSnapshot(file.path);

      await file.writeAsString('# External rewrite\n');
      await file.setLastModified(load.snapshot.modifiedAt);

      expect(await service.fileChangedSince(file.path, load.snapshot), isTrue);
    },
  );

  test(
    'folder workspace lists all content except version-control metadata',
    () async {
      final directory = await Directory.systemTemp.createTemp('busymark-scan-');
      await File('${directory.path}/README.md').writeAsString('# Readme\n');
      await Directory('${directory.path}/node_modules').create();
      await File(
        '${directory.path}/node_modules/ignored.md',
      ).writeAsString('# Ignored\n');
      await File('${directory.path}/binary.bin').writeAsBytes([0, 1, 2, 3]);
      await Directory('${directory.path}/empty').create();
      await Directory('${directory.path}/.idea').create();
      await File(
        '${directory.path}/.idea/.gitignore',
      ).writeAsString('/cache\n');
      await Directory('${directory.path}/.git').create();
      await File('${directory.path}/.git/config').writeAsString('[core]\n');

      final workspace = await service.openPath(directory.path);
      final files = workspace.files.map((file) => file.relativePath).toList();
      final directories = workspace.directories
          .map((directory) => directory.relativePath)
          .toList();

      expect(
        files,
        containsAll([
          'README.md',
          'node_modules/ignored.md',
          'binary.bin',
          '.idea/.gitignore',
        ]),
      );
      expect(directories, containsAll(['node_modules', 'empty', '.idea']));
      expect(files, isNot(contains('.git/config')));
      expect(directories, isNot(contains('.git')));
      expect(
        workspace.files
            .singleWhere((file) => file.relativePath == '.idea/.gitignore')
            .kind,
        DocumentKind.gitIgnore,
      );
      expect(
        workspace.files
            .singleWhere((file) => file.relativePath == 'binary.bin')
            .kind,
        DocumentKind.unknown,
      );

      await directory.delete(recursive: true);
    },
  );

  test(
    'folder workspace lists unsupported legacy Markdown extensions',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'busymark-legacy-markdown-',
      );
      await File('${directory.path}/README.md').writeAsString('# Readme\n');
      await File('${directory.path}/legacy.mdown').writeAsString('# Legacy\n');
      await File('${directory.path}/legacy.mkd').writeAsString('# Legacy\n');

      final workspace = await service.openPath(directory.path);
      final relativePaths = workspace.files.map((file) => file.relativePath);

      expect(relativePaths, contains('README.md'));
      expect(relativePaths, containsAll(['legacy.mdown', 'legacy.mkd']));
      expect(
        workspace.files
            .where((file) => file.relativePath.startsWith('legacy.'))
            .map((file) => file.kind),
        everyElement(DocumentKind.unknown),
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
          // Three root directories and the two shallow files consume the
          // traversal budget before the deep subtree is visited.
          scanOptions: const WorkspaceScanOptions(maxTreeEntries: 5),
        );
        final workspace = await limitedService.openPath(directory.path);
        final relativePaths = workspace.files.map((file) => file.relativePath);

        expect(relativePaths, containsAll(['a/guide.md', 'b/guide.md']));
        expect(relativePaths, isNot(contains('z/deep/0.md')));
        expect(workspace.rootPath, await directory.resolveSymbolicLinks());
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

  test(
    'large Writerside topics are listed but not parsed automatically',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'busymark-large-writerside-',
      );
      addTearDown(() => directory.delete(recursive: true));
      Directory(p.join(directory.path, 'topics')).createSync();
      File(p.join(directory.path, 'writerside.cfg')).writeAsStringSync(
        '<ihp><topics dir="topics"/><instance src="ug.tree"/></ihp>',
      );
      File(p.join(directory.path, 'ug.tree')).writeAsStringSync(
        '<instance-profile id="ug" start-page="large.md">'
        '<toc-element topic="large.md"/>'
        '</instance-profile>',
      );
      final largeTopic = File(p.join(directory.path, 'topics', 'large.md'))
        ..writeAsStringSync('# Large\n\n${List.filled(512, 'x').join()}');
      final limitedService = WorkspaceService(
        scanOptions: const WorkspaceScanOptions(maxParsedFileBytes: 256),
      );

      final workspace = await limitedService.openPath(directory.path);

      expect(
        workspace.files.map((file) => file.relativePath),
        contains('topics/large.md'),
      );
      expect(workspace.writersideModule?.instances, hasLength(1));
      expect(workspace.writersideModule?.topics, isEmpty);
      expect(workspace.markdown, isNull);
      expect(workspace.activeFilePath, isNull);
      expect(
        workspace.diagnostics.where(
          (diagnostic) =>
              diagnostic.code == 'workspace.file.too-large' &&
              diagnostic.filePath == largeTopic.path,
        ),
        hasLength(1),
      );
      expect(
        workspace.diagnostics.map((diagnostic) => diagnostic.code),
        isNot(contains('writerside.tree.missing-topic')),
      );
    },
  );

  test('Writerside topic loading honors the document limit', () async {
    final directory = await Directory.systemTemp.createTemp(
      'busymark-writerside-document-limit-',
    );
    addTearDown(() => directory.delete(recursive: true));
    Directory(p.join(directory.path, 'topics')).createSync();
    File(p.join(directory.path, 'writerside.cfg')).writeAsStringSync(
      '<ihp><topics dir="topics"/><instance src="ug.tree"/></ihp>',
    );
    File(p.join(directory.path, 'ug.tree')).writeAsStringSync(
      '<instance-profile id="ug" start-page="a.md">'
      '<toc-element topic="a.md"/>'
      '<toc-element topic="b.md"/>'
      '</instance-profile>',
    );
    File(p.join(directory.path, 'topics', 'a.md')).writeAsStringSync('# A\n');
    final skippedTopic = File(p.join(directory.path, 'topics', 'b.md'))
      ..writeAsStringSync('# B\n');
    final limitedService = WorkspaceService(
      writersideService: const WritersideModuleService(
        scanOptions: WorkspaceScanOptions(maxParsedDocuments: 1),
      ),
    );

    final workspace = await limitedService.openPath(directory.path);

    expect(
      workspace.files.map((file) => file.relativePath),
      containsAll(['topics/a.md', 'topics/b.md']),
    );
    expect(workspace.writersideModule?.topics.map((topic) => topic.fileName), [
      'a.md',
    ]);
    expect(workspace.markdown?.title, 'A');
    expect(
      workspace.diagnostics.where(
        (diagnostic) =>
            diagnostic.code == 'workspace.scan.document-limit' &&
            diagnostic.filePath == skippedTopic.path,
      ),
      hasLength(1),
    );
    expect(
      workspace.diagnostics.map((diagnostic) => diagnostic.code),
      isNot(contains('writerside.tree.missing-topic')),
    );
  });
}

Future<_WorkspaceSymlinkFixture> _createWorkspaceSymlinkFixture() async {
  final base = await Directory.systemTemp.createTemp(
    'busymark-workspace-symlink-escape-',
  );
  addTearDown(() async {
    if (await base.exists()) {
      await base.delete(recursive: true);
    }
  });
  final requestedRoot = Directory(p.join(base.path, 'workspace'))..createSync();
  final root = Directory(await requestedRoot.resolveSymbolicLinks());
  final outside = Directory(p.join(base.path, 'outside'))..createSync();
  final link = Link(p.join(root.path, 'bridge'))..createSync(outside.path);
  final workspace = Workspace(
    id: 'symlink-test',
    rootPath: root.path,
    kind: WorkspaceKind.markdownFolder,
    openedAt: DateTime.now(),
    files: const [],
    diagnostics: const [],
  );
  return _WorkspaceSymlinkFixture(
    root: root,
    outside: outside,
    link: link,
    workspace: workspace,
  );
}

class _WorkspaceSymlinkFixture {
  const _WorkspaceSymlinkFixture({
    required this.root,
    required this.outside,
    required this.link,
    required this.workspace,
  });

  final Directory root;
  final Directory outside;
  final Link link;
  final Workspace workspace;
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
