import '../git/application/git_controller.dart';
import 'workspace_model.dart';

enum WorkspaceTabKind { file, gitDiff }

class WorkspaceTabEntry {
  const WorkspaceTabEntry._({
    required this.kind,
    required this.path,
    required this.active,
  });

  const WorkspaceTabEntry.file({required String path, required bool active})
    : this._(kind: WorkspaceTabKind.file, path: path, active: active);

  const WorkspaceTabEntry.gitDiff({required String path, required bool active})
    : this._(kind: WorkspaceTabKind.gitDiff, path: path, active: active);

  final WorkspaceTabKind kind;
  final String path;
  final bool active;

  String get key => '${kind.name}:$path';
}

List<WorkspaceTabEntry> workspaceTabEntries({
  required Workspace workspace,
  required GitState gitState,
}) {
  final diffActive = gitState.selectedDiffForDisplay != null;
  return [
    for (final path in workspace.openFilePaths)
      WorkspaceTabEntry.file(
        path: path,
        active: !diffActive && path == workspace.activeFilePath,
      ),
    for (final path in gitState.openDiffFilePaths)
      WorkspaceTabEntry.gitDiff(
        path: path,
        active: diffActive && path == gitState.selectedCommitFilePath,
      ),
    if (gitState.openDiffFilePaths.isEmpty && diffActive)
      const WorkspaceTabEntry.gitDiff(path: '', active: true),
  ];
}

int activeWorkspaceTabIndex(List<WorkspaceTabEntry> tabs) {
  return tabs.indexWhere((tab) => tab.active);
}
