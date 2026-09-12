import '../git/application/git_controller.dart';
import 'document_buffer.dart';
import 'workspace_model.dart';

enum WorkspaceTabKind { file, gitDiff, localHistory }

class WorkspaceTabEntry {
  const WorkspaceTabEntry._({
    required this.kind,
    required this.path,
    required this.active,
    this.bufferId,
    this.untitledName,
    this.dirty = false,
  });

  const WorkspaceTabEntry.file({
    required String path,
    required bool active,
    String? bufferId,
    String? untitledName,
    bool dirty = false,
  }) : this._(
         kind: WorkspaceTabKind.file,
         path: path,
         active: active,
         bufferId: bufferId,
         untitledName: untitledName,
         dirty: dirty,
       );

  const WorkspaceTabEntry.gitDiff({required String path, required bool active})
    : this._(kind: WorkspaceTabKind.gitDiff, path: path, active: active);

  const WorkspaceTabEntry.localHistory({
    required String revisionId,
    required String documentName,
  }) : this._(
         kind: WorkspaceTabKind.localHistory,
         path: documentName,
         bufferId: revisionId,
         active: true,
       );

  final WorkspaceTabKind kind;
  final String path;
  final bool active;
  final String? bufferId;
  final String? untitledName;
  final bool dirty;

  String get key => '${kind.name}:${bufferId ?? path}';
}

List<WorkspaceTabEntry> workspaceTabEntries({
  required Workspace workspace,
  required GitState gitState,
  List<DocumentBuffer>? documentBuffers,
  String? activeBufferId,
  String? localHistoryRevisionId,
  String? localHistoryDocumentName,
}) {
  final diffActive = gitState.selectedDiffForDisplay != null;
  final localHistoryActive = localHistoryRevisionId != null;
  return [
    if (documentBuffers != null)
      for (final buffer in documentBuffers)
        WorkspaceTabEntry.file(
          path: buffer.filePath ?? '',
          bufferId: buffer.id,
          untitledName: buffer.untitledName,
          dirty: buffer.isDirty,
          active:
              !diffActive && !localHistoryActive && buffer.id == activeBufferId,
        )
    else
      for (final path in workspace.openFilePaths)
        WorkspaceTabEntry.file(
          path: path,
          active:
              !diffActive &&
              !localHistoryActive &&
              path == workspace.activeFilePath,
        ),
    for (final path in gitState.openDiffFilePaths)
      WorkspaceTabEntry.gitDiff(
        path: path,
        active:
            !localHistoryActive &&
            diffActive &&
            path == gitState.selectedCommitFilePath,
      ),
    if (gitState.openDiffFilePaths.isEmpty && diffActive && !localHistoryActive)
      const WorkspaceTabEntry.gitDiff(path: '', active: true),
    if (localHistoryRevisionId != null)
      WorkspaceTabEntry.localHistory(
        revisionId: localHistoryRevisionId,
        documentName: localHistoryDocumentName ?? '',
      ),
  ];
}

int activeWorkspaceTabIndex(List<WorkspaceTabEntry> tabs) {
  return tabs.indexWhere((tab) => tab.active);
}
