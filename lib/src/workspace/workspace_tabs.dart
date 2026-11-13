import '../git/application/shared_git_tabs.dart';
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
    this.comparisonId,
    this.comparisonLabel,
    this.review,
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

  const WorkspaceTabEntry.gitDiff({
    required String path,
    required bool active,
    required String comparisonId,
    String? comparisonLabel,
    required SharedGitReview review,
  }) : this._(
         kind: WorkspaceTabKind.gitDiff,
         path: path,
         active: active,
         comparisonId: comparisonId,
         comparisonLabel: comparisonLabel,
         review: review,
       );

  const WorkspaceTabEntry.localHistory({
    bool active = true,
    required String revisionId,
    required String documentName,
  }) : this._(
         kind: WorkspaceTabKind.localHistory,
         path: documentName,
         bufferId: revisionId,
         active: active,
       );

  final WorkspaceTabKind kind;
  final String path;
  final bool active;
  final String? bufferId;
  final String? untitledName;
  final bool dirty;
  final String? comparisonId, comparisonLabel;
  final SharedGitReview? review;

  String get key => '${kind.name}:${comparisonId ?? bufferId ?? path}';
}

List<WorkspaceTabEntry> workspaceTabEntries({
  required Workspace workspace,
  SharedGitTabs gitTabs = const SharedGitTabs(),
  List<DocumentBuffer>? documentBuffers,
  String? activeBufferId,
  String? localHistoryRevisionId,
  String? localHistoryDocumentName,
}) {
  final diffActive = gitTabs.active != null;
  final localHistoryActive = !diffActive && localHistoryRevisionId != null;
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
    for (final review in gitTabs.entries)
      WorkspaceTabEntry.gitDiff(
        path: review.comparison.path.display,
        comparisonId: review.id,
        review: review,
        comparisonLabel:
            '${review.comparison.left.label} → ${review.comparison.right.label}',
        active: review.id == gitTabs.activeId,
      ),
    if (localHistoryRevisionId != null)
      WorkspaceTabEntry.localHistory(
        active: localHistoryActive,
        revisionId: localHistoryRevisionId,
        documentName: localHistoryDocumentName ?? '',
      ),
  ];
}

int activeWorkspaceTabIndex(List<WorkspaceTabEntry> tabs) {
  return tabs.indexWhere((tab) => tab.active);
}
