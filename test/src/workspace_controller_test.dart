import 'dart:io';

import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/workspace/workspace_controller.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:busymark/src/workspace/workspace_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'records opened Markdown files by file path in recent workspaces',
    () async {
      final settingsStore = _MemorySettingsStore();
      final settingsController = AppSettingsController(settingsStore);
      await Future<void>.delayed(Duration.zero);
      final controller = WorkspaceController(
        service: const WorkspaceService(),
        settingsController: settingsController,
      );

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
    final settingsStore = _MemorySettingsStore();
    final settingsController = AppSettingsController(settingsStore);
    await Future<void>.delayed(Duration.zero);
    final controller = WorkspaceController(
      service: const WorkspaceService(),
      settingsController: settingsController,
    );

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

  test('switching active files reparses outline for the new file', () async {
    final settingsStore = _MemorySettingsStore();
    final settingsController = AppSettingsController(settingsStore);
    await Future<void>.delayed(Duration.zero);
    final controller = WorkspaceController(
      service: const WorkspaceService(),
      settingsController: settingsController,
    );

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

  test('failed open clears stale workspace state', () async {
    final settingsStore = _MemorySettingsStore();
    final settingsController = AppSettingsController(settingsStore);
    await Future<void>.delayed(Duration.zero);
    final controller = WorkspaceController(
      service: const WorkspaceService(),
      settingsController: settingsController,
    );

    await controller.openPath('test/fixtures/markdown/basic.md');
    await controller.openPath('test/fixtures/markdown/does-not-exist.md');

    expect(controller.state.workspace, isNull);
    expect(controller.state.errorMessage, contains('Open failed'));

    controller.dispose();
    settingsController.dispose();
  });

  test('validate on edit setting controls live diagnostics only', () async {
    final settingsStore = _MemorySettingsStore();
    final settingsController = AppSettingsController(settingsStore);
    await Future<void>.delayed(Duration.zero);
    await settingsController.setValidateOnEdit(false);
    final controller = WorkspaceController(
      service: const WorkspaceService(),
      settingsController: settingsController,
    );

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
      final settingsStore = _MemorySettingsStore();
      final settingsController = AppSettingsController(settingsStore);
      await Future<void>.delayed(Duration.zero);
      final controller = WorkspaceController(
        service: const WorkspaceService(),
        settingsController: settingsController,
      );

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
