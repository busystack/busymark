import 'dart:async';
import 'dart:io';

import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/core/source_span.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/workspace/document_buffer.dart';
import 'package:busymark/src/workspace/recovery_persistence.dart';
import 'package:busymark/src/workspace/session_persistence.dart';
import 'package:busymark/src/workspace/workspace_controller.dart';
import 'package:busymark/src/workspace/workspace_file_monitor.dart';
import 'package:busymark/src/workspace/workspace_message.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:busymark/src/workspace/workspace_service.dart';
import 'package:busymark/src/writerside/writerside_project_creator.dart';
import 'package:busymark/src/writerside/writerside_topic_creator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

void main() {
  test(
    'records opened Markdown files by file path in recent workspaces',
    () async {
      final harness = await _createControllerHarness();
      final settingsController = harness.settingsController;
      final controller = harness.controller;

      await controller.openPath('test/fixtures/markdown/basic.md');

      expect(controller.state.workspace?.kind, WorkspaceKind.singleMarkdown);
      expect(
        settingsController.state.recentWorkspaces.first.path,
        endsWith('test/fixtures/markdown/basic.md'),
      );
      expect(
        settingsController.state.recentWorkspaces.first.kind,
        'singleMarkdown',
      );

      controller.dispose();
      settingsController.dispose();
    },
  );

  test('records opened folders by folder path in recent workspaces', () async {
    final harness = await _createControllerHarness();
    final settingsController = harness.settingsController;
    final controller = harness.controller;

    await controller.openPath('test/fixtures/markdown');

    expect(controller.state.workspace?.kind, WorkspaceKind.markdownFolder);
    expect(
      settingsController.state.recentWorkspaces.first.path,
      endsWith('test/fixtures/markdown'),
    );
    expect(
      settingsController.state.recentWorkspaces.first.kind,
      'markdownFolder',
    );

    controller.dispose();
    settingsController.dispose();
  });

  test(
    'workspace file operations refresh and preserve active moved files',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'busymark-file-ops-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final first = File(p.join(directory.path, 'first.md'))
        ..writeAsStringSync('# First\n');
      final docs = Directory(p.join(directory.path, 'docs'))..createSync();
      File(p.join(docs.path, 'existing.md')).writeAsStringSync('# Existing\n');
      final harness = await _createControllerHarness();
      final settingsController = harness.settingsController;
      final controller = harness.controller;

      await controller.openPath(directory.path);
      await settingsController.setDocumentViewMode(
        DocumentViewModePreference.preview,
      );

      final created = p.join(directory.path, 'new.md');
      expect(
        await controller.createWorkspaceFile(directory.path, 'new.md'),
        isTrue,
      );
      expect(File(created).existsSync(), isTrue);
      expect(controller.state.workspace?.activeFilePath, created);
      expect(
        settingsController.state.documentViewMode,
        DocumentViewModePreference.editor,
      );

      final renamed = p.join(directory.path, 'renamed.md');
      expect(
        await controller.renameWorkspaceEntity(created, 'renamed.md'),
        isTrue,
      );
      expect(File(created).existsSync(), isFalse);
      expect(File(renamed).existsSync(), isTrue);
      expect(controller.state.workspace?.activeFilePath, renamed);

      final moved = p.join(docs.path, 'renamed.md');
      expect(await controller.moveWorkspaceEntity(renamed, docs.path), isTrue);
      expect(File(renamed).existsSync(), isFalse);
      expect(File(moved).existsSync(), isTrue);
      expect(controller.state.workspace?.activeFilePath, moved);

      expect(await controller.deleteWorkspaceEntity(moved), isTrue);
      expect(File(moved).existsSync(), isFalse);
      expect(controller.state.workspace?.activeFilePath, isNot(moved));
      expect([
        first.path,
        p.join(docs.path, 'existing.md'),
      ], contains(controller.state.workspace?.activeFilePath));

      controller.dispose();
      settingsController.dispose();
    },
  );

  test(
    'creates an unsaved Markdown file without adding it to recent',
    () async {
      final harness = await _createControllerHarness();
      final settingsController = harness.settingsController;
      final controller = harness.controller;

      await controller.createMarkdownFile();

      expect(controller.state.workspace?.kind, WorkspaceKind.untitledMarkdown);
      expect(controller.state.workspace?.activeFilePath, isNull);
      expect(controller.state.workspace?.markdown?.filePath, isEmpty);
      expect(controller.state.isDirty, isTrue);
      expect(settingsController.state.recentWorkspaces, isEmpty);

      controller.dispose();
      settingsController.dispose();
    },
  );

  test('new Markdown files leave preview mode for editor mode', () async {
    final harness = await _createControllerHarness();
    final settingsController = harness.settingsController;
    final controller = harness.controller;

    await settingsController.setDocumentViewMode(
      DocumentViewModePreference.preview,
    );
    await controller.createMarkdownFile();

    expect(
      settingsController.state.documentViewMode,
      DocumentViewModePreference.editor,
    );

    controller.dispose();
    settingsController.dispose();
  });

  test('new Markdown files preserve non-preview view modes', () async {
    for (final mode in <DocumentViewModePreference>[
      DocumentViewModePreference.editor,
      DocumentViewModePreference.source,
      DocumentViewModePreference.split,
    ]) {
      final harness = await _createControllerHarness();
      final settingsController = harness.settingsController;
      final controller = harness.controller;

      await settingsController.setDocumentViewMode(mode);
      await controller.createMarkdownFile();

      expect(settingsController.state.documentViewMode, mode);

      controller.dispose();
      settingsController.dispose();
    }
  });

  test('discarding an untitled Markdown file clears the workspace', () async {
    final harness = await _createControllerHarness();
    final settingsController = harness.settingsController;
    final controller = harness.controller;

    await controller.createMarkdownFile();
    controller.updateActiveText('# Draft\n');

    expect(await controller.discardActiveChanges(), isTrue);
    expect(controller.state.workspace, isNull);
    expect(controller.state.activeText, isEmpty);
    expect(controller.state.isDirty, isFalse);

    controller.dispose();
    settingsController.dispose();
  });

  test(
    'discarding a saved file reloads disk text and clears dirty state',
    () async {
      final harness = await _createControllerHarness();
      final settingsController = harness.settingsController;
      final controller = harness.controller;

      await controller.openPath('test/fixtures/markdown/basic.md');
      final savedText = controller.state.activeText;
      controller.updateActiveText('# Dirty\n');

      expect(await controller.discardActiveChanges(), isTrue);
      expect(controller.state.activeText, savedText);
      expect(controller.state.isDirty, isFalse);
      expect(controller.state.workspace?.activeFileSnapshot, isNotNull);

      controller.dispose();
      settingsController.dispose();
    },
  );

  test('creates a Writerside project and records it as recent', () async {
    final parent = await Directory.systemTemp.createTemp(
      'busymark-controller-create-',
    );
    final harness = await _createControllerHarness();
    final settingsController = harness.settingsController;
    final controller = harness.controller;

    final created = await controller.createWritersideProject(
      WritersideProjectCreateRequest(
        parentDirectoryPath: parent.path,
        projectName: 'Docs',
        directoryName: 'docs',
        instanceName: 'User Guide',
        topicTitle: 'Getting started',
      ),
    );

    final rootPath = p.join(parent.path, 'docs');
    expect(created, isTrue);
    expect(controller.state.workspace?.kind, WorkspaceKind.writersideModule);
    expect(controller.state.activeText, contains('# Getting started'));
    expect(controller.state.preview, isNotNull);
    expect(settingsController.state.recentWorkspaces.first.path, rootPath);
    expect(
      settingsController.state.recentWorkspaces.first.kind,
      'writersideModule',
    );

    controller.dispose();
    settingsController.dispose();
    await parent.delete(recursive: true);
  });

  test(
    'creates a Writerside topic and opens it without changing recents',
    () async {
      final parent = await Directory.systemTemp.createTemp(
        'busymark-controller-create-topic-',
      );
      final harness = await _createControllerHarness();
      final settingsController = harness.settingsController;
      final controller = harness.controller;
      await controller.createWritersideProject(
        WritersideProjectCreateRequest(
          parentDirectoryPath: parent.path,
          projectName: 'Docs',
          directoryName: 'docs',
          instanceName: 'User Guide',
          topicTitle: 'Getting started',
        ),
      );
      final recentCount = settingsController.state.recentWorkspaces.length;

      final created = await controller.createWritersideTopic(
        const WritersideTopicCreateRequest(
          title: 'API Reference',
          fileName: 'api-reference.md',
        ),
      );

      final topicPath = p.join(
        parent.path,
        'docs',
        'topics',
        'api-reference.md',
      );
      expect(created, isTrue);
      expect(controller.state.workspace?.activeFilePath, topicPath);
      expect(controller.state.activeText, contains('# API Reference'));
      expect(controller.state.preview, isNotNull);
      expect(settingsController.state.recentWorkspaces, hasLength(recentCount));

      controller.dispose();
      settingsController.dispose();
      await parent.delete(recursive: true);
    },
  );

  test(
    'topic TOC actions refresh the workspace and preserve file state',
    () async {
      final parent = await Directory.systemTemp.createTemp(
        'busymark-controller-topic-actions-',
      );
      final harness = await _createControllerHarness();
      final settingsController = harness.settingsController;
      final controller = harness.controller;
      await controller.createWritersideProject(
        WritersideProjectCreateRequest(
          parentDirectoryPath: parent.path,
          projectName: 'Docs',
          directoryName: 'docs',
          instanceName: 'User Guide',
          topicTitle: 'Getting started',
        ),
      );
      await controller.createWritersideTopic(
        const WritersideTopicCreateRequest(
          title: 'Secondary',
          fileName: 'secondary.md',
        ),
      );
      final rootPath = p.join(parent.path, 'docs');
      final treePath = p.join(rootPath, 'user-guide.tree');
      final startPath = p.join(rootPath, 'topics', 'getting-started.md');
      final secondaryPath = p.join(rootPath, 'topics', 'secondary.md');
      expect(await controller.openActiveFile(startPath), isTrue);
      expect(
        controller.state.workspace?.openFilePaths,
        contains(secondaryPath),
      );

      expect(
        await controller.moveWritersideTocEntry(
          treePath: treePath,
          sourcePath: const [1],
          placement: WritersideTopicCreatePlacement.child,
          referencePath: const [0],
        ),
        isTrue,
      );
      var tree = XmlDocument.parse(File(treePath).readAsStringSync());
      var first = tree.rootElement.childElements
          .where((element) => element.name.local == 'toc-element')
          .first;
      expect(first.childElements.single.getAttribute('topic'), 'secondary.md');
      expect(controller.state.workspace?.activeFilePath, startPath);

      expect(
        await controller.renameWritersideTopicFile(secondaryPath, 'renamed.md'),
        isTrue,
      );
      final renamedPath = p.join(rootPath, 'topics', 'renamed.md');
      tree = XmlDocument.parse(File(treePath).readAsStringSync());
      first = tree.rootElement.childElements
          .where((element) => element.name.local == 'toc-element')
          .first;
      expect(first.childElements.single.getAttribute('topic'), 'renamed.md');
      expect(controller.state.workspace?.activeFilePath, startPath);
      expect(controller.state.workspace?.openFilePaths, contains(renamedPath));
      expect(
        controller.state.workspace?.openFilePaths,
        isNot(contains(secondaryPath)),
      );
      expect(File(renamedPath).existsSync(), isTrue);

      expect(
        await controller.removeWritersideTocEntry(
          treePath: treePath,
          nodePath: const [0, 0],
        ),
        isTrue,
      );
      expect(File(renamedPath).existsSync(), isTrue);
      expect(File(treePath).readAsStringSync(), isNot(contains('renamed.md')));

      expect(await controller.deleteWritersideTopicFile(renamedPath), isTrue);
      expect(File(renamedPath).existsSync(), isFalse);

      controller.dispose();
      settingsController.dispose();
      await parent.delete(recursive: true);
    },
  );

  test('save as writes a new Markdown file and records it as recent', () async {
    final directory = await Directory.systemTemp.createTemp(
      'busymark-save-as-',
    );
    final file = File('${directory.path}/created.md');
    final harness = await _createControllerHarness();
    final settingsController = harness.settingsController;
    final controller = harness.controller;

    await controller.createMarkdownFile();
    controller.updateActiveText('# Created\n\nDraft text.');

    expect(await controller.saveActiveAs(file.path), isTrue);
    expect(await file.readAsString(), '# Created\n\nDraft text.');
    expect(controller.state.workspace?.kind, WorkspaceKind.singleMarkdown);
    expect(controller.state.workspace?.activeFilePath, file.path);
    expect(controller.state.isDirty, isFalse);
    expect(settingsController.state.recentWorkspaces.first.path, file.path);

    controller.dispose();
    settingsController.dispose();
    await directory.delete(recursive: true);
  });

  test(
    'save as refuses an existing file unless overwrite is explicit',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'busymark-save-as-existing-',
      );
      final file = File('${directory.path}/existing.md');
      await file.writeAsString('# Existing\n');
      final harness = await _createControllerHarness();
      final settingsController = harness.settingsController;
      final controller = harness.controller;

      await controller.createMarkdownFile();
      controller.updateActiveText('# Draft\n');

      expect(await controller.saveActiveAs(file.path), isFalse);
      expect(await file.readAsString(), '# Existing\n');
      expect(controller.state.workspace?.kind, WorkspaceKind.untitledMarkdown);
      expect(controller.state.isDirty, isTrue);
      expect(controller.state.message?.code, WorkspaceMessageCode.saveFailed);

      expect(
        await controller.saveActiveAs(file.path, overwriteExisting: true),
        isTrue,
      );
      expect(await file.readAsString(), '# Draft\n');

      controller.dispose();
      settingsController.dispose();
      await directory.delete(recursive: true);
    },
  );

  test(
    'save as explicit overwrite replaces the final symlink only',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'busymark-save-as-symlink-',
      );
      final target = File('${directory.path}/target.md');
      final link = Link('${directory.path}/note.md');
      await target.writeAsString('# Target\n');
      await link.create(target.path);
      final harness = await _createControllerHarness();
      final settingsController = harness.settingsController;
      final controller = harness.controller;

      await controller.createMarkdownFile();
      controller.updateActiveText('# Draft\n');

      expect(
        await controller.saveActiveAs(link.path, overwriteExisting: true),
        isTrue,
      );
      expect(
        await FileSystemEntity.type(link.path, followLinks: false),
        FileSystemEntityType.file,
      );
      expect(await File(link.path).readAsString(), '# Draft\n');
      expect(await target.readAsString(), '# Target\n');

      controller.dispose();
      settingsController.dispose();
      await directory.delete(recursive: true);
    },
    skip: Platform.isWindows ? 'POSIX symlink behavior only.' : false,
  );

  test(
    'save as preserves source edits for an untitled Markdown file',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'busymark-save-as-source-',
      );
      final file = File('${directory.path}/created.md');
      final harness = await _createControllerHarness();
      final settingsController = harness.settingsController;
      final controller = harness.controller;
      const editedText = '# Created\n\nDraft text.';

      await controller.createMarkdownFile();
      controller.updateActiveText(editedText, sourceFilePath: '');

      expect(controller.state.activeText, editedText);
      expect(await controller.saveActiveAs(file.path), isTrue);
      expect(await file.readAsString(), editedText);
      expect(controller.state.activeText, editedText);
      expect(controller.state.workspace?.activeFilePath, file.path);
      expect(controller.state.isDirty, isFalse);

      controller.dispose();
      settingsController.dispose();
      await directory.delete(recursive: true);
    },
  );

  test('save as preserves edits made while writing the file', () async {
    final directory = await Directory.systemTemp.createTemp(
      'busymark-save-as-edit-during-write-',
    );
    final file = File(p.join(directory.path, 'created.md'));
    final service = _DelayedSaveAsWorkspaceService(pauseWrite: true);
    final harness = await _createControllerHarness(service: service);
    final settingsController = harness.settingsController;
    final controller = harness.controller;

    await controller.createMarkdownFile();
    controller.updateActiveText('# First draft\n');

    final save = controller.saveActiveAs(file.path);
    await service.writeStarted.future;
    controller.updateActiveText('# Newer draft\n');
    service.releaseWrite();

    expect(await save, isTrue);
    expect(await file.readAsString(), '# First draft\n');
    expect(controller.state.workspace?.activeFilePath, file.path);
    expect(controller.state.activeText, '# Newer draft\n');
    expect(controller.state.isDirty, isTrue);

    expect(await controller.saveActive(), isTrue);
    expect(await file.readAsString(), '# Newer draft\n');
    expect(controller.state.isDirty, isFalse);

    controller.dispose();
    settingsController.dispose();
    await directory.delete(recursive: true);
  });

  test('save as preserves edits made while reopening the file', () async {
    final directory = await Directory.systemTemp.createTemp(
      'busymark-save-as-edit-during-open-',
    );
    final file = File(p.join(directory.path, 'created.md'));
    final service = _DelayedSaveAsWorkspaceService(pauseOpen: true);
    final harness = await _createControllerHarness(service: service);
    final settingsController = harness.settingsController;
    final controller = harness.controller;

    await controller.createMarkdownFile();
    controller.updateActiveText('# First draft\n');

    final save = controller.saveActiveAs(file.path);
    await service.openStarted.future;
    controller.updateActiveText('# Newer draft\n');
    service.releaseOpen();

    expect(await save, isTrue);
    expect(await file.readAsString(), '# First draft\n');
    expect(controller.state.workspace?.activeFilePath, file.path);
    expect(controller.state.activeText, '# Newer draft\n');
    expect(controller.state.isDirty, isTrue);

    expect(await controller.saveActive(), isTrue);
    expect(await file.readAsString(), '# Newer draft\n');
    expect(controller.state.isDirty, isFalse);

    controller.dispose();
    settingsController.dispose();
    await directory.delete(recursive: true);
  });

  test('switching active files reparses outline for the new file', () async {
    final harness = await _createControllerHarness();
    final settingsController = harness.settingsController;
    final controller = harness.controller;

    await controller.openPath('test/fixtures/markdown');
    final otherFile = controller.state.workspace!.files.singleWhere(
      (file) => file.relativePath == 'other.md',
    );

    await controller.openActiveFile(otherFile.absolutePath);

    expect(controller.state.workspace?.activeFilePath, otherFile.absolutePath);
    expect(
      controller.state.workspace?.markdown?.filePath,
      otherFile.absolutePath,
    );
    expect(controller.state.workspace?.markdown?.title, 'Other');
    expect(
      controller.state.workspace?.markdown?.headings.map(
        (heading) => heading.text,
      ),
      contains('Target'),
    );

    controller.dispose();
    settingsController.dispose();
  });

  test(
    'stale validation after save and tab switch does not restore previous file',
    () async {
      final service = _DelayedValidationWorkspaceService();
      final harness = await _createControllerHarness(service: service);
      final settingsController = harness.settingsController;
      final controller = harness.controller;

      await controller.openPath(service.rootPath);
      controller.updateActiveText('# Dirty A\n');

      final validation = controller.validateActive();
      await service.validationStarted.future;

      expect(await controller.saveActive(), isTrue);
      expect(await controller.openActiveFile(service.bPath), isTrue);
      controller.updateActiveText('# Dirty B\n');
      expect(await controller.saveActive(), isTrue);

      expect(controller.state.workspace?.activeFilePath, service.bPath);
      expect(controller.state.activeText, '# Dirty B\n');
      expect(service.savedTexts, ['# Dirty A\n', '# Dirty B\n']);

      service.finishValidation();
      await validation;

      expect(controller.state.workspace?.activeFilePath, service.bPath);
      expect(controller.state.activeText, '# Dirty B\n');

      controller.dispose();
      settingsController.dispose();
    },
  );

  test(
    'validation completing after save preserves the saved snapshot',
    () async {
      final service = _DelayedValidationWorkspaceService();
      final harness = await _createControllerHarness(service: service);
      final settingsController = harness.settingsController;
      final controller = harness.controller;
      await settingsController.setValidateOnEdit(false);

      await controller.openPath(service.rootPath);
      controller.updateActiveText('# Dirty A\n');
      final validation = controller.validateActive();
      await service.validationStarted.future;

      expect(await controller.saveActive(), isTrue);
      final savedSnapshot = controller.state.workspace!.activeFileSnapshot!;
      expect(savedSnapshot.contentHash, '# Dirty A\n');

      service.finishValidation();
      await validation;

      final finalSnapshot = controller.state.workspace!.activeFileSnapshot!;
      expect(finalSnapshot.contentHash, savedSnapshot.contentHash);
      expect(finalSnapshot.modifiedAt, savedSnapshot.modifiedAt);

      controller.updateActiveText('# Dirty A again\n');
      expect(await controller.saveActive(), isTrue);
      expect(
        controller.state.message?.code,
        isNot(WorkspaceMessageCode.saveBlockedFileChangedOnDisk),
      );

      controller.dispose();
      settingsController.dispose();
    },
  );

  test(
    'stale text update from previous file cannot dirty active tab',
    () async {
      final service = _DelayedValidationWorkspaceService();
      final harness = await _createControllerHarness(service: service);
      final settingsController = harness.settingsController;
      final controller = harness.controller;

      await controller.openPath(service.rootPath);
      expect(await controller.openActiveFile(service.bPath), isTrue);

      controller.updateActiveText('# Stale A\n', sourceFilePath: service.aPath);

      expect(controller.state.workspace?.activeFilePath, service.bPath);
      expect(controller.state.activeText, '# B\n');
      expect(controller.state.isDirty, isFalse);
      expect(await controller.autoSaveActiveIfNeeded(), isTrue);
      expect(service.savedTexts, isEmpty);

      controller.dispose();
      settingsController.dispose();
    },
  );

  test('folder workspaces track open file tabs without duplicates', () async {
    final harness = await _createControllerHarness();
    final settingsController = harness.settingsController;
    final controller = harness.controller;

    await controller.openPath('test/fixtures/markdown');
    final initialPath = controller.state.workspace!.activeFilePath!;
    final otherFile = controller.state.workspace!.files.singleWhere(
      (file) => file.relativePath == 'other.md',
    );

    expect(controller.state.workspace?.openFilePaths, [initialPath]);

    await controller.openActiveFile(otherFile.absolutePath);
    await controller.openActiveFile(initialPath);

    expect(controller.state.workspace?.activeFilePath, initialPath);
    expect(controller.state.workspace?.openFilePaths, [
      initialPath,
      otherFile.absolutePath,
    ]);

    controller.dispose();
    settingsController.dispose();
  });

  test('Save All writes every dirty file-backed buffer', () async {
    final directory = await Directory.systemTemp.createTemp(
      'busymark-save-all-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final first = File(p.join(directory.path, 'a.md'))
      ..writeAsStringSync('# A\n');
    final second = File(p.join(directory.path, 'b.md'))
      ..writeAsStringSync('# B\n');
    final harness = await _createControllerHarness();
    final settingsController = harness.settingsController;
    final controller = harness.controller;

    await controller.openPath(directory.path);
    controller.updateActiveText('# Edited A\n');
    expect(await controller.openActiveFile(second.path), isTrue);
    controller.updateActiveText('# Edited B\n');

    final result = await controller.saveAll();

    expect(result.savedBufferIds, hasLength(2));
    expect(result.failedBufferIds, isEmpty);
    expect(result.conflictBufferIds, isEmpty);
    expect(controller.state.dirtyBuffers, isEmpty);
    expect(controller.state.workspace?.activeFilePath, second.path);
    expect(first.readAsStringSync(), '# Edited A\n');
    expect(second.readAsStringSync(), '# Edited B\n');

    controller.dispose();
    settingsController.dispose();
  });

  test('closing active file tabs selects a neighboring tab', () async {
    final harness = await _createControllerHarness();
    final settingsController = harness.settingsController;
    final controller = harness.controller;

    await controller.openPath('test/fixtures/markdown');
    final initialPath = controller.state.workspace!.activeFilePath!;
    final otherFile = controller.state.workspace!.files.singleWhere(
      (file) => file.relativePath == 'other.md',
    );
    final linksFile = controller.state.workspace!.files.singleWhere(
      (file) => file.relativePath == 'links_images.md',
    );

    await controller.openActiveFile(otherFile.absolutePath);
    await controller.openActiveFile(linksFile.absolutePath);
    await controller.closeOpenFileTab(otherFile.absolutePath);

    expect(controller.state.workspace?.activeFilePath, linksFile.absolutePath);
    expect(controller.state.workspace?.openFilePaths, [
      initialPath,
      linksFile.absolutePath,
    ]);

    await controller.closeOpenFileTab(linksFile.absolutePath);

    expect(controller.state.workspace?.activeFilePath, initialPath);
    expect(controller.state.workspace?.openFilePaths, [initialPath]);

    await controller.closeOpenFileTab(initialPath);

    expect(controller.state.workspace?.activeFilePath, isNull);
    expect(controller.state.workspace?.activeFileSnapshot, isNull);
    expect(controller.state.workspace?.openFilePaths, isEmpty);
    expect(controller.state.activeText, isEmpty);
    expect(controller.state.preview, isNull);
    expect(controller.state.isDirty, isFalse);

    controller.dispose();
    settingsController.dispose();
  });

  test('activating sibling file tabs wraps around the open tabs', () async {
    final harness = await _createControllerHarness();
    final settingsController = harness.settingsController;
    final controller = harness.controller;

    await controller.openPath('test/fixtures/markdown');
    final initialPath = controller.state.workspace!.activeFilePath!;
    final otherFile = controller.state.workspace!.files.singleWhere(
      (file) => file.relativePath == 'other.md',
    );
    final linksFile = controller.state.workspace!.files.singleWhere(
      (file) => file.relativePath == 'links_images.md',
    );

    await controller.openActiveFile(otherFile.absolutePath);
    await controller.openActiveFile(linksFile.absolutePath);

    expect(controller.state.workspace?.activeFilePath, linksFile.absolutePath);

    await controller.activateNextOpenFileTab();

    expect(controller.state.workspace?.activeFilePath, initialPath);

    await controller.activatePreviousOpenFileTab();

    expect(controller.state.workspace?.activeFilePath, linksFile.absolutePath);

    await controller.activatePreviousOpenFileTab();

    expect(controller.state.workspace?.activeFilePath, otherFile.absolutePath);

    controller.dispose();
    settingsController.dispose();
  });

  test('closing all file tabs clears the active editor state', () async {
    final harness = await _createControllerHarness();
    final settingsController = harness.settingsController;
    final controller = harness.controller;

    await controller.openPath('test/fixtures/markdown');
    final otherFile = controller.state.workspace!.files.singleWhere(
      (file) => file.relativePath == 'other.md',
    );
    final linksFile = controller.state.workspace!.files.singleWhere(
      (file) => file.relativePath == 'links_images.md',
    );

    await controller.openActiveFile(otherFile.absolutePath);
    await controller.openActiveFile(linksFile.absolutePath);

    await controller.closeAllOpenFileTabs();

    expect(controller.state.workspace?.activeFilePath, isNull);
    expect(controller.state.workspace?.activeFileModifiedAt, isNull);
    expect(controller.state.workspace?.activeFileSnapshot, isNull);
    expect(controller.state.workspace?.openFilePaths, isEmpty);
    expect(controller.state.workspace?.markdown, isNull);
    expect(controller.state.workspace?.diagnostics, isEmpty);
    expect(controller.state.activeText, isEmpty);
    expect(controller.state.preview, isNull);
    expect(controller.state.isDirty, isFalse);

    controller.dispose();
    settingsController.dispose();
  });

  test('failed open clears stale workspace state', () async {
    final harness = await _createControllerHarness();
    final settingsController = harness.settingsController;
    final controller = harness.controller;

    await controller.openPath('test/fixtures/markdown/basic.md');
    await controller.openPath('test/fixtures/markdown/does-not-exist.md');

    expect(controller.state.workspace, isNull);
    expect(controller.state.message?.code, WorkspaceMessageCode.openFailed);

    controller.dispose();
    settingsController.dispose();
  });

  test(
    'math renderer failures become source-linked runtime diagnostics',
    () async {
      final harness = await _createControllerHarness();
      final controller = harness.controller;
      await controller.openPath('test/fixtures/markdown/basic.md');
      final path = controller.state.workspace!.activeFilePath!;
      final span = SourceSpan.fromOffsets(
        filePath: path,
        source: controller.state.activeText,
        startOffset: 0,
        endOffset: 4,
      );

      controller.updateMathRenderDiagnostic(
        expressionId: 'inline-b0-i0',
        code: 'math.invalidTex',
        sourceSpan: span,
      );

      final workspace = controller.state.workspace!;
      expect(workspace.runtimeDiagnostics.single.code, 'math.invalidTex');
      expect(workspace.runtimeDiagnostics.single.sourceSpan, same(span));
      expect(
        workspace.allDiagnostics,
        contains(workspace.runtimeDiagnostics.single),
      );

      controller.updateMathRenderDiagnostic(
        expressionId: 'inline-b0-i0',
        code: null,
        sourceSpan: span,
      );
      expect(controller.state.workspace!.runtimeDiagnostics, isEmpty);

      controller.updateMathRenderDiagnostic(
        expressionId: 'inline-b0-i0',
        code: 'math.invalidTex',
        sourceSpan: span,
      );
      controller.updateActiveText('${controller.state.activeText}\n');
      expect(controller.state.workspace!.runtimeDiagnostics, isEmpty);
      await _waitFor(
        () =>
            controller.state.workspace?.markdown?.source ==
            controller.state.activeText,
      );
    },
  );

  test('validate on edit setting controls live diagnostics only', () async {
    final harness = await _createControllerHarness();
    final settingsController = harness.settingsController;
    await settingsController.setValidateOnEdit(false);
    final controller = harness.controller;

    await controller.openPath('test/fixtures/markdown/other.md');
    controller.updateActiveText('# Changed\n\nVisible preview.');
    await Future<void>.delayed(Duration.zero);

    expect(controller.state.workspace?.markdown?.title, 'Other');
    expect(controller.state.preview?.blocks.map((block) => block.text), [
      'Changed',
      'Visible preview.',
    ]);

    controller.dispose();
    settingsController.dispose();
  });

  test('auto save waits for an idle delay before writing', () async {
    final service = _AutosaveWorkspaceService();
    final harness = await _createControllerHarness(service: service);
    final settingsController = harness.settingsController;
    final controller = harness.controller;

    await controller.openPath(service.path);
    controller.updateActiveText('# Draft\n');
    await Future<void>.delayed(const Duration(milliseconds: 500));

    expect(service.savedTexts, isEmpty);
    expect(controller.state.isDirty, isTrue);

    await Future<void>.delayed(const Duration(milliseconds: 1200));

    expect(service.savedTexts, ['# Draft\n']);
    expect(controller.state.isDirty, isFalse);

    controller.dispose();
    settingsController.dispose();
  });

  test(
    'auto save preserves dirty state when edits happen during save',
    () async {
      final service = _AutosaveWorkspaceService(pauseFirstSave: true);
      final harness = await _createControllerHarness(service: service);
      final settingsController = harness.settingsController;
      final controller = harness.controller;

      await controller.openPath(service.path);
      controller.updateActiveText('# First\n');
      final firstSave = controller.autoSaveActiveIfNeeded();
      await service.firstSaveStarted.future;

      controller.updateActiveText('# Second\n');
      service.releaseFirstSave();

      expect(await firstSave, isTrue);
      expect(service.savedTexts, ['# First\n']);
      expect(controller.state.isDirty, isTrue);

      expect(await controller.autoSaveActiveIfNeeded(), isTrue);
      expect(service.savedTexts, ['# First\n', '# Second\n']);
      expect(controller.state.isDirty, isFalse);

      controller.dispose();
      settingsController.dispose();
    },
  );

  test('overlapping manual save writes the newer requested revision', () async {
    final service = _AutosaveWorkspaceService(pauseFirstSave: true);
    final harness = await _createControllerHarness(service: service);
    final settingsController = harness.settingsController;
    final controller = harness.controller;

    await settingsController.setAutoSave(false);
    await controller.openPath(service.path);
    controller.updateActiveText('# First\n');
    final firstSave = controller.saveActive();
    await service.firstSaveStarted.future;

    controller.updateActiveText('# Second\n');
    final secondSave = controller.saveActive();
    service.releaseFirstSave();

    expect(await firstSave, isTrue);
    expect(await secondSave, isTrue);
    expect(service.savedTexts, ['# First\n', '# Second\n']);
    expect(controller.state.isDirty, isFalse);

    controller.dispose();
    settingsController.dispose();
  });

  test(
    'save refuses to overwrite external file changes without force',
    () async {
      final directory = await Directory.systemTemp.createTemp('busymark-save-');
      final file = File('${directory.path}/note.md');
      await file.writeAsString('# Original\n');
      final harness = await _createControllerHarness();
      final settingsController = harness.settingsController;
      final controller = harness.controller;

      await controller.openPath(file.path);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await file.writeAsString('# External\n');
      controller.updateActiveText('# BusyMark\n');

      expect(await controller.saveActive(), isFalse);
      expect(await file.readAsString(), '# External\n');
      expect(
        await controller.saveActive(overwriteExternalChanges: true),
        isTrue,
      );
      expect(await file.readAsString(), '# BusyMark\n');

      controller.dispose();
      settingsController.dispose();
      await directory.delete(recursive: true);
    },
  );

  test('save treats a deleted active file as an external conflict', () async {
    final directory = await Directory.systemTemp.createTemp(
      'busymark-save-missing-',
    );
    final file = File('${directory.path}/note.md');
    await file.writeAsString('# Original\n');
    final harness = await _createControllerHarness();
    final settingsController = harness.settingsController;
    final controller = harness.controller;

    await controller.openPath(file.path);
    await file.delete();
    controller.updateActiveText('# BusyMark\n');

    expect(await controller.saveActive(), isFalse);
    expect(
      controller.state.message?.code,
      WorkspaceMessageCode.saveBlockedFileChangedOnDisk,
    );
    expect(await file.exists(), isFalse);

    controller.dispose();
    settingsController.dispose();
    await directory.delete(recursive: true);
  });

  test('save detects external rewrites with unchanged modified time', () async {
    final directory = await Directory.systemTemp.createTemp(
      'busymark-save-hash-',
    );
    final file = File('${directory.path}/note.md');
    await file.writeAsString('# Original\n');
    final harness = await _createControllerHarness();
    final settingsController = harness.settingsController;
    final controller = harness.controller;

    await controller.openPath(file.path);
    final loadedSnapshot = controller.state.workspace!.activeFileSnapshot!;
    await file.writeAsString('# External rewrite\n');
    await file.setLastModified(loadedSnapshot.modifiedAt);
    controller.updateActiveText('# BusyMark\n');

    expect(await controller.saveActive(), isFalse);
    expect(await file.readAsString(), '# External rewrite\n');
    expect(
      controller.state.message?.code,
      WorkspaceMessageCode.saveBlockedFileChangedOnDisk,
    );

    controller.dispose();
    settingsController.dispose();
    await directory.delete(recursive: true);
  });

  test('saving preserves a manually removed final newline', () async {
    final directory = await Directory.systemTemp.createTemp(
      'busymark-final-newline-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File(p.join(directory.path, 'note.md'));
    await file.writeAsString('Saved\n');
    final harness = await _createControllerHarness();

    await harness.controller.openPath(file.path);
    harness.controller.updateActiveText('Saved');

    expect(await harness.controller.saveActive(), isTrue);
    expect(await file.readAsString(), 'Saved');
    expect(
      harness.controller.state.activeBuffer?.format.hasFinalNewline,
      false,
    );
  });

  test('WYSIWYG list edits preserve a missing final newline', () async {
    final directory = await Directory.systemTemp.createTemp(
      'busymark-wysiwyg-final-newline-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File(p.join(directory.path, 'note.md'));
    await file.writeAsString('- original');
    final harness = await _createControllerHarness();

    await harness.controller.openPath(file.path);
    final document = harness.controller.state.workspace!.markdown!.busyDocument;
    harness.controller.updateActiveWysiwygText(
      '- changed\n',
      document: document,
      sourceFilePath: file.path,
    );

    expect(harness.controller.state.activeBuffer?.text, '- changed');
    expect(
      harness.controller.state.activeBuffer?.format.hasFinalNewline,
      isFalse,
    );
    expect(await harness.controller.saveActive(), isTrue);
    expect(await file.readAsString(), '- changed');
  });

  test(
    'Keep Mine retains the conflict snapshot until explicit overwrite',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'busymark-keep-mine-',
      );
      addTearDown(() => directory.delete(recursive: true));
      File(p.join(directory.path, 'a.md')).writeAsStringSync('Original\n');
      File(p.join(directory.path, 'b.md')).writeAsStringSync('Other\n');
      final monitor = WorkspaceFileMonitor(
        debounce: const Duration(milliseconds: 10),
      );
      addTearDown(monitor.dispose);
      final harness = await _createControllerHarness(fileMonitor: monitor);

      await harness.controller.openPath(directory.path);
      final path = harness.controller.state.activeBuffer!.filePath!;
      final originalSnapshot =
          harness.controller.state.activeBuffer!.diskSnapshot;
      harness.controller.updateActiveText('Mine\n');
      await File(path).writeAsString('External\n');
      await _waitFor(
        () => harness.controller.state.activeBuffer?.hasConflict == true,
      );

      harness.controller.keepBufferVersion(
        harness.controller.state.activeBuffer!.id,
      );

      expect(
        harness.controller.state.activeBuffer?.diskSnapshot,
        same(originalSnapshot),
      );
      expect(
        harness.controller.state.activeBuffer?.diskState,
        DocumentDiskState.changed,
      );
      expect(await harness.controller.saveActive(), isFalse);
      expect(await File(path).readAsString(), 'External\n');
    },
  );

  test('external file moves remap the open document buffer', () async {
    final directory = await Directory.systemTemp.createTemp(
      'busymark-external-move-',
    );
    addTearDown(() => directory.delete(recursive: true));
    File(p.join(directory.path, 'a.md')).writeAsStringSync('A\n');
    File(p.join(directory.path, 'b.md')).writeAsStringSync('B\n');
    final monitor = WorkspaceFileMonitor(
      debounce: const Duration(milliseconds: 10),
    );
    addTearDown(monitor.dispose);
    final harness = await _createControllerHarness(fileMonitor: monitor);

    await harness.controller.openPath(directory.path);
    final oldPath = harness.controller.state.activeBuffer!.filePath!;
    final newPath = p.join(directory.path, 'moved.md');
    await File(oldPath).rename(newPath);
    await _waitFor(
      () => harness.controller.state.activeBuffer?.filePath == newPath,
    );

    expect(harness.controller.state.workspace?.activeFilePath, newPath);
    expect(
      harness.controller.state.workspace?.openFilePaths,
      contains(newPath),
    );
    expect(
      harness.controller.state.activeBuffer?.diskState,
      DocumentDiskState.present,
    );
  });

  test('restored sessions retain tabs whose files are missing', () async {
    final directory = await Directory.systemTemp.createTemp(
      'busymark-missing-session-file-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final missingPath = p.join(directory.path, 'missing.md');
    final sessionStore = MemoryDocumentSessionStore()
      ..value = WorkspaceSessionSnapshot(
        workspacePath: directory.path,
        activeBufferId: 'missing',
        tabs: [
          DocumentSessionEntry(
            id: 'missing',
            filePath: missingPath,
            untitledName: null,
            editorState: const DocumentEditorState(),
          ),
        ],
      );
    final harness = await _createControllerHarness(sessionStore: sessionStore);

    expect(await harness.controller.restorePreviousSession(), isTrue);
    expect(harness.controller.state.activeBuffer?.filePath, missingPath);
    expect(harness.controller.state.activeBuffer?.text, isEmpty);
    expect(harness.controller.state.activeBuffer?.deletedOnDisk, isTrue);
  });

  test('restored standalone sessions retain a missing document', () async {
    final directory = await Directory.systemTemp.createTemp(
      'busymark-missing-standalone-session-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final missingPath = p.join(directory.path, 'missing.md');
    final sessionStore = MemoryDocumentSessionStore()
      ..value = WorkspaceSessionSnapshot(
        workspacePath: missingPath,
        activeBufferId: 'missing',
        tabs: [
          DocumentSessionEntry(
            id: 'missing',
            filePath: missingPath,
            untitledName: null,
            editorState: const DocumentEditorState(),
          ),
        ],
      );
    final harness = await _createControllerHarness(sessionStore: sessionStore);

    expect(await harness.controller.restorePreviousSession(), isTrue);
    expect(
      harness.controller.state.workspace?.kind,
      WorkspaceKind.singleMarkdown,
    );
    expect(harness.controller.state.activeBuffer?.filePath, missingPath);
    expect(harness.controller.state.activeBuffer?.text, isEmpty);
    expect(harness.controller.state.activeBuffer?.deletedOnDisk, isTrue);
  });

  test('clean marker cannot hide remaining recovery entries', () async {
    final recoveryStore = MemoryDocumentRecoveryStore();
    final sessionStore = MemoryDocumentSessionStore();
    final recoveredBuffer = DocumentBuffer.untitled(
      id: 'untitled:recovered',
      name: 'Recovered',
      text: 'Unsaved recovery',
    );
    recoveryStore.value = RecoverySnapshot(
      cleanShutdown: true,
      entries: [
        DocumentRecoveryEntry.fromBuffer(recoveredBuffer, workspacePath: null),
      ],
    );
    final harness = await _createControllerHarness(
      sessionStore: sessionStore,
      recoveryStore: recoveryStore,
    );

    expect(await harness.controller.restorePreviousSession(), isTrue);
    expect(harness.controller.state.activeBuffer?.recovered, isTrue);
    expect(
      harness.controller.state.message?.code,
      WorkspaceMessageCode.recoveryRestored,
    );

    await harness.controller.markCleanShutdown();
    expect(recoveryStore.value.cleanShutdown, isFalse);
    expect(recoveryStore.value.entries, isNotEmpty);
  });

  test(
    'recovery text remains restorable when the later session save fails',
    () async {
      final recoveryStore = MemoryDocumentRecoveryStore();
      final sessionStore = _FailingDocumentSessionStore();
      final harness = await _createControllerHarness(
        sessionStore: sessionStore,
        recoveryStore: recoveryStore,
      );

      await harness.controller.createMarkdownFile();
      harness.controller.updateActiveText('Latest unsaved text');
      await harness.controller.flushPersistence();

      // Simulate an older or absent recovery file immediately before the
      // persistence attempt whose session write fails.
      await recoveryStore.writeEntries(const []);
      sessionStore.failSave = true;

      await expectLater(
        harness.controller.flushPersistence(),
        throwsA(isA<StateError>()),
      );

      expect(recoveryStore.value.entries, hasLength(1));
      expect(recoveryStore.value.entries.single.text, 'Latest unsaved text');

      final restored = await _createControllerHarness(
        sessionStore: MemoryDocumentSessionStore(),
        recoveryStore: recoveryStore,
      );
      expect(await restored.controller.restorePreviousSession(), isTrue);
      expect(restored.controller.state.activeText, 'Latest unsaved text');
      expect(restored.controller.state.activeBuffer?.recovered, isTrue);
    },
  );
}

Future<void> _waitFor(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 3));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out waiting for workspace state');
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

Future<_WorkspaceControllerHarness> _createControllerHarness({
  WorkspaceService service = const WorkspaceService(),
  WorkspaceFileMonitor? fileMonitor,
  DocumentSessionStore? sessionStore,
  DocumentRecoveryStore? recoveryStore,
}) async {
  final container = ProviderContainer(
    overrides: [
      localSettingsStoreProvider.overrideWithValue(_MemorySettingsStore()),
      workspaceServiceProvider.overrideWithValue(service),
      if (fileMonitor != null)
        workspaceFileMonitorProvider.overrideWithValue(fileMonitor),
      if (sessionStore != null)
        documentSessionStoreProvider.overrideWithValue(sessionStore),
      if (recoveryStore != null)
        documentRecoveryStoreProvider.overrideWithValue(recoveryStore),
    ],
  );
  addTearDown(container.dispose);
  container.read(appSettingsControllerProvider.notifier);
  container.read(workspaceControllerProvider.notifier);
  await Future<void>.delayed(Duration.zero);
  return _WorkspaceControllerHarness(container);
}

class _WorkspaceControllerHarness {
  _WorkspaceControllerHarness(this._container);

  final ProviderContainer _container;

  late final controller = _WorkspaceControllerDriver(_container);
  late final settingsController = _AppSettingsControllerDriver(_container);
}

class _WorkspaceControllerDriver {
  const _WorkspaceControllerDriver(this._container);

  final ProviderContainer _container;

  WorkspaceController get _notifier =>
      _container.read(workspaceControllerProvider.notifier);

  WorkspaceState get state => _container.read(workspaceControllerProvider);

  Future<void> openPath(String path) => _notifier.openPath(path);

  Future<void> createMarkdownFile() => _notifier.createMarkdownFile();

  Future<bool> createWorkspaceFile(String directoryPath, String fileName) =>
      _notifier.createWorkspaceFile(directoryPath, fileName);

  Future<bool> renameWorkspaceEntity(String path, String newName) =>
      _notifier.renameWorkspaceEntity(path, newName);

  Future<bool> moveWorkspaceEntity(String sourcePath, String targetDirectory) =>
      _notifier.moveWorkspaceEntity(sourcePath, targetDirectory);

  Future<bool> deleteWorkspaceEntity(String path) =>
      _notifier.deleteWorkspaceEntity(path);

  Future<bool> createWritersideProject(
    WritersideProjectCreateRequest request,
  ) => _notifier.createWritersideProject(request);

  Future<bool> createWritersideTopic(WritersideTopicCreateRequest request) =>
      _notifier.createWritersideTopic(request);

  Future<bool> moveWritersideTocEntry({
    required String treePath,
    required List<int> sourcePath,
    required WritersideTopicCreatePlacement placement,
    required List<int>? referencePath,
  }) => _notifier.moveWritersideTocEntry(
    treePath: treePath,
    sourcePath: sourcePath,
    placement: placement,
    referencePath: referencePath,
  );

  Future<bool> removeWritersideTocEntry({
    required String treePath,
    required List<int> nodePath,
  }) => _notifier.removeWritersideTocEntry(
    treePath: treePath,
    nodePath: nodePath,
  );

  Future<bool> renameWritersideTopicFile(
    String topicPath,
    String newFileName,
  ) => _notifier.renameWritersideTopicFile(topicPath, newFileName);

  Future<bool> deleteWritersideTopicFile(String topicPath) =>
      _notifier.deleteWritersideTopicFile(topicPath);

  Future<bool> openActiveFile(String path) => _notifier.openActiveFile(path);

  Future<bool> activateNextOpenFileTab() => _notifier.activateNextOpenFileTab();

  Future<bool> activatePreviousOpenFileTab() =>
      _notifier.activatePreviousOpenFileTab();

  Future<bool> closeOpenFileTab(String path) =>
      _notifier.closeOpenFileTab(path);

  Future<bool> closeAllOpenFileTabs() => _notifier.closeAllOpenFileTabs();

  void updateActiveText(String text, {String? sourceFilePath}) {
    _notifier.updateActiveText(text, sourceFilePath: sourceFilePath);
  }

  void updateActiveWysiwygText(
    String text, {
    required BusyDocument document,
    String? sourceFilePath,
  }) {
    _notifier.updateActiveWysiwygText(
      text,
      document: document,
      sourceFilePath: sourceFilePath,
    );
  }

  void updateMathRenderDiagnostic({
    required String expressionId,
    required String? code,
    SourceSpan? sourceSpan,
  }) {
    _notifier.updateMathRenderDiagnostic(
      expressionId: expressionId,
      code: code,
      sourceSpan: sourceSpan,
    );
  }

  Future<bool> saveActive({bool overwriteExternalChanges = false}) =>
      _notifier.saveActive(overwriteExternalChanges: overwriteExternalChanges);

  Future<bool> saveActiveAs(String path, {bool overwriteExisting = false}) =>
      _notifier.saveActiveAs(path, overwriteExisting: overwriteExisting);

  Future<SaveAllResult> saveAll() => _notifier.saveAll();

  Future<bool> autoSaveActiveIfNeeded() => _notifier.autoSaveActiveIfNeeded();

  Future<bool> discardActiveChanges() => _notifier.discardActiveChanges();

  void keepBufferVersion(String bufferId) =>
      _notifier.keepBufferVersion(bufferId);

  Future<void> validateActive() => _notifier.validateActive();

  Future<bool> restorePreviousSession() => _notifier.restorePreviousSession();

  Future<void> markCleanShutdown() => _notifier.markCleanShutdown();

  Future<void> flushPersistence() => _notifier.flushPersistence();

  void dispose() {}
}

class _AppSettingsControllerDriver {
  const _AppSettingsControllerDriver(this._container);

  final ProviderContainer _container;

  AppSettingsController get _notifier =>
      _container.read(appSettingsControllerProvider.notifier);

  AppSettings get state => _container.read(appSettingsControllerProvider);

  Future<void> setDocumentViewMode(DocumentViewModePreference mode) =>
      _notifier.setDocumentViewMode(mode);

  Future<void> setValidateOnEdit(bool enabled) =>
      _notifier.setValidateOnEdit(enabled);

  Future<void> setAutoSave(bool enabled) => _notifier.setAutoSave(enabled);

  void dispose() {}
}

class _MemorySettingsStore implements LocalSettingsStore {
  Map<String, Object?> value = <String, Object?>{};

  @override
  Future<Map<String, Object?>> load() async => value;

  @override
  Future<void> save(Map<String, Object?> json) async {
    value = json;
  }
}

class _FailingDocumentSessionStore extends MemoryDocumentSessionStore {
  bool failSave = false;

  @override
  Future<void> save(WorkspaceSessionSnapshot snapshot) {
    if (failSave) {
      throw StateError('simulated session save failure');
    }
    return super.save(snapshot);
  }
}

class _DelayedSaveAsWorkspaceService extends WorkspaceService {
  _DelayedSaveAsWorkspaceService({
    this.pauseWrite = false,
    this.pauseOpen = false,
  });

  final bool pauseWrite;
  final bool pauseOpen;
  final writeStarted = Completer<void>();
  final openStarted = Completer<void>();
  final _releaseWrite = Completer<void>();
  final _releaseOpen = Completer<void>();

  @override
  Future<WorkspaceFileSnapshot> saveNewText(String path, String text) async {
    writeStarted.complete();
    if (pauseWrite) {
      await _releaseWrite.future;
    }
    return super.saveNewText(path, text);
  }

  @override
  Future<Workspace> openPath(String path) async {
    openStarted.complete();
    if (pauseOpen) {
      await _releaseOpen.future;
    }
    return super.openPath(path);
  }

  void releaseWrite() {
    if (!_releaseWrite.isCompleted) {
      _releaseWrite.complete();
    }
  }

  void releaseOpen() {
    if (!_releaseOpen.isCompleted) {
      _releaseOpen.complete();
    }
  }
}

class _AutosaveWorkspaceService extends WorkspaceService {
  _AutosaveWorkspaceService({this.pauseFirstSave = false});

  final bool pauseFirstSave;
  final path = '/tmp/busymark-autosave.md';
  final savedTexts = <String>[];
  final firstSaveStarted = Completer<void>();
  final _releaseFirstSave = Completer<void>();

  @override
  Future<Workspace> openPath(String path) async {
    return Workspace(
      id: path,
      rootPath: path,
      kind: WorkspaceKind.singleMarkdown,
      openedAt: DateTime(2026),
      activeFilePath: path,
      activeFileSnapshot: WorkspaceFileSnapshot(
        modifiedAt: _autosaveInitialModifiedAt,
        size: 11,
        contentHash: 'initial',
      ),
      files: [
        DocumentFile(
          absolutePath: path,
          relativePath: 'autosave.md',
          kind: DocumentKind.markdown,
          size: 11,
          lastModified: _autosaveInitialModifiedAt,
        ),
      ],
      diagnostics: const [],
    );
  }

  @override
  Future<WorkspaceFileLoad> loadTextWithSnapshot(String path) async {
    return WorkspaceFileLoad(
      text: '# Initial\n',
      snapshot: WorkspaceFileSnapshot(
        modifiedAt: _autosaveInitialModifiedAt,
        size: 11,
        contentHash: 'initial',
      ),
    );
  }

  @override
  Future<bool> fileChangedSince(
    String path,
    WorkspaceFileSnapshot? knownSnapshot,
  ) async {
    return false;
  }

  @override
  Future<WorkspaceFileSnapshot> saveText(String path, String text) async {
    savedTexts.add(text);
    if (pauseFirstSave && savedTexts.length == 1) {
      firstSaveStarted.complete();
      await _releaseFirstSave.future;
    } else if (!firstSaveStarted.isCompleted) {
      firstSaveStarted.complete();
    }
    return WorkspaceFileSnapshot(
      modifiedAt: DateTime(2026, 1, savedTexts.length + 1),
      size: text.length,
      contentHash: text,
    );
  }

  @override
  Future<Workspace> reparseActive(Workspace workspace, String source) async {
    return workspace.copyWith(diagnostics: const []);
  }

  void releaseFirstSave() {
    if (!_releaseFirstSave.isCompleted) {
      _releaseFirstSave.complete();
    }
  }
}

class _DelayedValidationWorkspaceService extends WorkspaceService {
  final rootPath = '/tmp/busymark-delayed-validation';
  late final aPath = p.join(rootPath, 'a.md');
  late final bPath = p.join(rootPath, 'b.md');
  final savedTexts = <String>[];
  final _documents = <String, String>{};
  final _snapshots = <String, WorkspaceFileSnapshot>{};
  final validationStarted = Completer<void>();
  final _finishValidation = Completer<void>();
  var _pausedValidation = false;

  void _ensureDocuments() {
    _documents.putIfAbsent(aPath, () => '# A\n');
    _documents.putIfAbsent(bPath, () => '# B\n');
    _snapshots.putIfAbsent(aPath, () => _delayedSnapshot(_documents[aPath]!));
    _snapshots.putIfAbsent(bPath, () => _delayedSnapshot(_documents[bPath]!));
  }

  @override
  Future<Workspace> openPath(String path) async {
    _ensureDocuments();
    return Workspace(
      id: rootPath,
      rootPath: rootPath,
      kind: WorkspaceKind.markdownFolder,
      openedAt: DateTime(2026),
      activeFilePath: aPath,
      activeFileSnapshot: _snapshots[aPath],
      openFilePaths: [aPath],
      files: [
        DocumentFile(
          absolutePath: aPath,
          relativePath: 'a.md',
          kind: DocumentKind.markdown,
          size: 4,
          lastModified: _delayedInitialModifiedAt,
        ),
        DocumentFile(
          absolutePath: bPath,
          relativePath: 'b.md',
          kind: DocumentKind.markdown,
          size: 4,
          lastModified: _delayedInitialModifiedAt,
        ),
      ],
      diagnostics: const [],
    );
  }

  @override
  Future<WorkspaceFileLoad> loadTextWithSnapshot(String path) async {
    _ensureDocuments();
    return WorkspaceFileLoad(
      text: _documents[path]!,
      snapshot: _snapshots[path]!,
    );
  }

  @override
  Future<bool> fileChangedSince(
    String path,
    WorkspaceFileSnapshot? knownSnapshot,
  ) async {
    _ensureDocuments();
    final current = _snapshots[path];
    return knownSnapshot == null ||
        current == null ||
        current.differsFrom(knownSnapshot);
  }

  @override
  Future<WorkspaceFileSnapshot> saveText(String path, String text) async {
    savedTexts.add(text);
    final snapshot = _delayedSnapshot(text, savedTexts.length);
    _documents[path] = text;
    _snapshots[path] = snapshot;
    return snapshot;
  }

  @override
  Future<Workspace> reparseActive(Workspace workspace, String source) async {
    if (!_pausedValidation && source == '# Dirty A\n') {
      _pausedValidation = true;
      validationStarted.complete();
      await _finishValidation.future;
    }
    return workspace.copyWith(diagnostics: const []);
  }

  void finishValidation() {
    if (!_finishValidation.isCompleted) {
      _finishValidation.complete();
    }
  }
}

WorkspaceFileSnapshot _delayedSnapshot(String text, [int revision = 0]) {
  return WorkspaceFileSnapshot(
    modifiedAt: DateTime(2026, 2, revision + 1),
    size: text.length,
    contentHash: text,
  );
}

final _autosaveInitialModifiedAt = DateTime(2026);
final _delayedInitialModifiedAt = DateTime(2026, 2);
