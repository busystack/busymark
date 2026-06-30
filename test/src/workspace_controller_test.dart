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

    expect(controller.state.workspace?.activeFilePath, initialPath);
    expect(controller.state.workspace?.openFilePaths, [initialPath]);

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

Future<_WorkspaceControllerHarness> _createControllerHarness() async {
  final container = ProviderContainer(
    overrides: [
      localSettingsStoreProvider.overrideWithValue(_MemorySettingsStore()),
      workspaceServiceProvider.overrideWithValue(const WorkspaceService()),
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

  Future<bool> createWritersideProject(
    WritersideProjectCreateRequest request,
  ) => _notifier.createWritersideProject(request);

  Future<bool> createWritersideTopic(WritersideTopicCreateRequest request) =>
      _notifier.createWritersideTopic(request);

  Future<void> openActiveFile(String path) => _notifier.openActiveFile(path);

  Future<void> closeOpenFileTab(String path) =>
      _notifier.closeOpenFileTab(path);

  void updateActiveText(String text, {bool updatePreview = true}) {
    _notifier.updateActiveText(text, updatePreview: updatePreview);
  }

  Future<bool> saveActive({bool overwriteExternalChanges = false}) =>
      _notifier.saveActive(overwriteExternalChanges: overwriteExternalChanges);

  Future<bool> saveActiveAs(String path) => _notifier.saveActiveAs(path);

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
