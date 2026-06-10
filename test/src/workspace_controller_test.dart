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
