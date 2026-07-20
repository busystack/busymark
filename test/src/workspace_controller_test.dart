import 'dart:async';
import 'dart:io';

import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/workspace/workspace_controller.dart';
import 'package:busymark/src/workspace/workspace_message.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:busymark/src/workspace/workspace_service.dart';
import 'package:busymark/src/writerside/writerside_project_creator.dart';
import 'package:busymark/src/writerside/writerside_topic_creator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

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

      final created = p.join(directory.path, 'new.md');
      expect(
        await controller.createWorkspaceFile(directory.path, 'new.md'),
        isTrue,
      );
      expect(File(created).existsSync(), isTrue);
      expect(controller.state.workspace?.activeFilePath, created);

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

  test('validate on edit setting controls live diagnostics only', () async {
    final harness = await _createControllerHarness();
    final settingsController = harness.settingsController;
    await settingsController.setValidateOnEdit(false);
    final controller = harness.controller;

    await controller.openPath('test/fixtures/markdown/other.md');
    controller.updateActiveText('# Changed\n\nVisible preview.');
    await Future<void>.delayed(const Duration(milliseconds: 450));

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
}

Future<_WorkspaceControllerHarness> _createControllerHarness({
  WorkspaceService service = const WorkspaceService(),
}) async {
  final container = ProviderContainer(
    overrides: [
      localSettingsStoreProvider.overrideWithValue(_MemorySettingsStore()),
      workspaceServiceProvider.overrideWithValue(service),
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

  Future<bool> openActiveFile(String path) => _notifier.openActiveFile(path);

  Future<bool> activateNextOpenFileTab() => _notifier.activateNextOpenFileTab();

  Future<bool> activatePreviousOpenFileTab() =>
      _notifier.activatePreviousOpenFileTab();

  Future<bool> closeOpenFileTab(String path) =>
      _notifier.closeOpenFileTab(path);

  Future<bool> closeAllOpenFileTabs() => _notifier.closeAllOpenFileTabs();

  void updateActiveText(
    String text, {
    bool updatePreview = true,
    String? sourceFilePath,
  }) {
    _notifier.updateActiveText(
      text,
      updatePreview: updatePreview,
      sourceFilePath: sourceFilePath,
    );
  }

  Future<bool> saveActive({bool overwriteExternalChanges = false}) =>
      _notifier.saveActive(overwriteExternalChanges: overwriteExternalChanges);

  Future<bool> saveActiveAs(String path, {bool overwriteExisting = false}) =>
      _notifier.saveActiveAs(path, overwriteExisting: overwriteExisting);

  Future<bool> autoSaveActiveIfNeeded() => _notifier.autoSaveActiveIfNeeded();

  Future<bool> discardActiveChanges() => _notifier.discardActiveChanges();

  Future<void> validateActive() => _notifier.validateActive();

  void dispose() {}
}

class _AppSettingsControllerDriver {
  const _AppSettingsControllerDriver(this._container);

  final ProviderContainer _container;

  AppSettingsController get _notifier =>
      _container.read(appSettingsControllerProvider.notifier);

  AppSettings get state => _container.read(appSettingsControllerProvider);

  Future<void> setValidateOnEdit(bool enabled) =>
      _notifier.setValidateOnEdit(enabled);

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
  final validationStarted = Completer<void>();
  final _finishValidation = Completer<void>();
  var _pausedValidation = false;

  @override
  Future<Workspace> openPath(String path) async {
    return Workspace(
      id: rootPath,
      rootPath: rootPath,
      kind: WorkspaceKind.markdownFolder,
      openedAt: DateTime(2026),
      activeFilePath: aPath,
      activeFileSnapshot: _delayedSnapshot('# A\n'),
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
    final text = path == bPath ? '# B\n' : '# A\n';
    return WorkspaceFileLoad(text: text, snapshot: _delayedSnapshot(text));
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
    return _delayedSnapshot(text, savedTexts.length);
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
