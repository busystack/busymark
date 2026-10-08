import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../git/application/git_controller.dart';
import '../local_history/local_history_controller.dart';
import 'workspace_controller.dart';
import 'workspace_model.dart';
import 'workspace_safety.dart';
import 'workspace_tabs.dart';

// All tab-closing entry points share this guard, including keyboard commands.
// The controller is the workspace owner's identity, independent of tab widgets.
final _closing = Expando<bool>();

List<WorkspaceTabEntry> _tabs(WidgetRef ref, WorkspaceState state) {
  final workspace = state.workspace;
  if (workspace == null) return const [];
  final history = ref.read(localHistoryControllerProvider);
  return workspaceTabEntries(
    workspace: workspace,
    gitState: ref.read(gitControllerProvider),
    documentBuffers: state.documentBuffers,
    activeBufferId: state.activeBufferId,
    localHistoryRevisionId: history.selectedRevisionId,
    localHistoryDocumentName: history.selectedDocument?.displayName,
  );
}

bool _sameWorkspace(Workspace workspace, WorkspaceState state) =>
    state.workspace?.id == workspace.id &&
    state.workspace?.openedAt == workspace.openedAt;

bool _tabSurvivedFirstSave(
  Workspace workspace,
  WorkspaceState state,
  WorkspaceTabEntry tab,
) =>
    workspace.kind == WorkspaceKind.untitledMarkdown &&
    state.workspace?.kind == WorkspaceKind.singleMarkdown &&
    tab.kind == WorkspaceTabKind.file &&
    tab.path.isEmpty &&
    state.documentBuffers.any(
      (buffer) =>
          buffer.id == tab.bufferId &&
          buffer.filePath != null &&
          buffer.filePath!.isNotEmpty,
    );

/// Validates a tab captured before an asynchronous menu was presented.
bool isWorkspaceTabCurrent(
  WidgetRef ref,
  Workspace workspace,
  WorkspaceTabEntry tab,
) {
  if (!ref.context.mounted) return false;
  final state = ref.read(workspaceControllerProvider);
  return (_sameWorkspace(workspace, state) ||
          _tabSurvivedFirstSave(workspace, state, tab)) &&
      _tabs(ref, state).any((candidate) => candidate.key == tab.key);
}

/// Closes the specified view without selecting it before confirmation.
Future<bool> closeWorkspaceTab(
  BuildContext context,
  WidgetRef ref, {
  required Workspace workspace,
  required WorkspaceTabEntry tab,
}) => _closeTabs(context, ref, workspace: workspace, clicked: tab);

/// Keeps the specified document and its editor session, then activates it.
Future<bool> closeOtherWorkspaceTabs(
  BuildContext context,
  WidgetRef ref, {
  required Workspace workspace,
  required WorkspaceTabEntry retainedTab,
}) => retainedTab.kind != WorkspaceTabKind.file
    ? Future.value(false)
    : _closeTabs(
        context,
        ref,
        workspace: workspace,
        clicked: retainedTab,
        retain: true,
      );

/// Closes captured views while preserving the controller's workspace lifecycle.
Future<bool> closeAllWorkspaceTabs(
  BuildContext context,
  WidgetRef ref, {
  required Workspace workspace,
}) => _closeTabs(context, ref, workspace: workspace);

Future<bool> _closeTabs(
  BuildContext context,
  WidgetRef ref, {
  required Workspace workspace,
  WorkspaceTabEntry? clicked,
  bool retain = false,
}) async {
  if (!context.mounted || !ref.context.mounted) return false;
  final controller = ref.read(workspaceControllerProvider.notifier);
  if (_closing[controller] == true) return false;
  final initial = ref.read(workspaceControllerProvider);
  if (!_sameWorkspace(workspace, initial) &&
      (clicked == null ||
          !_tabSurvivedFirstSave(workspace, initial, clicked))) {
    return false;
  }
  final tabs = _tabs(ref, initial);
  if (clicked != null && !tabs.any((tab) => tab.key == clicked.key)) {
    return false;
  }
  final targets = [
    for (final tab in tabs)
      if (clicked == null ||
          (retain ? tab.key != clicked.key : tab.key == clicked.key))
        tab,
  ];
  if (targets.isEmpty) return false;
  final bufferIds = {
    for (final tab in targets)
      if (tab.kind == WorkspaceTabKind.file) tab.bufferId!,
  };
  // Capture controllers before destructive awaits. Callers must supply a ref
  // owned by WorkspaceScreen or the app, never the disappearing tab strip.
  final git = ref.read(gitControllerProvider.notifier);
  final history = ref.read(localHistoryControllerProvider.notifier);
  var operationWorkspace = initial.workspace!;
  var documentsFinished = false;
  bool currentWorkspace() {
    if (!context.mounted || !ref.context.mounted) return false;
    final live = ref.read(workspaceControllerProvider);
    if (retain) {
      if (!live.documentBuffers.any(
        (buffer) => buffer.id == clicked!.bufferId,
      )) {
        return false;
      }
      final revision = ref
          .read(localHistoryControllerProvider)
          .selectedRevisionId;
      // A new comparison cannot be cleared merely to activate the retained
      // document. Stop if it replaced the captured comparison during a wait.
      if (revision != null &&
          !targets.any(
            (tab) =>
                tab.kind == WorkspaceTabKind.localHistory &&
                tab.bufferId == revision,
          )) {
        return false;
      }
    }
    final current = live.workspace;
    if (current?.id == operationWorkspace.id &&
        current?.openedAt == operationWorkspace.openedAt) {
      return true;
    }
    // First Save As replaces an untitled workspace, preserving buffer IDs.
    // Require a surviving original draft that acquired a local path.
    if (operationWorkspace.kind == WorkspaceKind.untitledMarkdown &&
        current?.kind == WorkspaceKind.singleMarkdown &&
        initial.documentBuffers.any(
          (original) =>
              original.isUntitled &&
              live.documentBuffers.any(
                (buffer) => buffer.id == original.id && buffer.filePath != null,
              ),
        )) {
      operationWorkspace = current!;
      return true;
    }
    // Authorized discard/closing of the last pathless local buffer can return
    // to Welcome. There is no document removal left to perform in that case.
    return current == null &&
        operationWorkspace.kind == WorkspaceKind.untitledMarkdown &&
        live.documentBuffers.isEmpty;
  }

  _closing[controller] = true;
  try {
    if (!await confirmSafeToCloseDocumentBuffers(context, ref, bufferIds) ||
        !currentWorkspace()) {
      return false;
    }
    var live = ref.read(workspaceControllerProvider);
    if (live.documentBuffers.any(
      (buffer) => bufferIds.contains(buffer.id) && buffer.isDirty,
    )) {
      return false;
    }
    if (clicked == null) {
      // The local bulk API owns history flushing and folder/project empty
      // state. It must never see documents opened after target capture.
      if (live.documentBuffers.any(
        (buffer) => !bufferIds.contains(buffer.id),
      )) {
        return false;
      }
      if (live.documentBuffers.isNotEmpty &&
          switch (live.workspace!.kind) {
            WorkspaceKind.singleMarkdown ||
            WorkspaceKind.markdownFolder ||
            WorkspaceKind.writersideModule => true,
            WorkspaceKind.untitledMarkdown ||
            WorkspaceKind.nextcloudNotes => false,
          }) {
        if (!await controller.closeAllOpenFileTabs() || !currentWorkspace()) {
          return false;
        }
        documentsFinished = true;
      }
    }
    if (!documentsFinished) {
      for (final id in bufferIds) {
        if (!currentWorkspace()) return false;
        live = ref.read(workspaceControllerProvider);
        final buffer = live.documentBuffers
            .where((buffer) => buffer.id == id)
            .firstOrNull;
        // Discard can already have removed an untitled/deleted buffer.
        if (buffer == null) continue;
        if (buffer.isDirty) return false;
        final closed = await controller.closeDocumentBuffer(id);
        if (!currentWorkspace()) return false;
        if (!closed &&
            ref
                .read(workspaceControllerProvider)
                .documentBuffers
                .any((buffer) => buffer.id == id)) {
          return false;
        }
      }
    }
    if (!currentWorkspace()) return false;
    final gitTargets = targets
        .where((tab) => tab.kind == WorkspaceTabKind.gitDiff)
        .toList();
    final liveGit = ref.read(gitControllerProvider);
    if (gitTargets.isNotEmpty) {
      final paths = gitTargets.map((tab) => tab.path).toSet();
      if (liveGit.openDiffFilePaths.every(paths.contains) &&
          (liveGit.openDiffFilePaths.isNotEmpty || paths.contains(''))) {
        git.clearSelection();
      } else {
        for (final path in paths) {
          if (path.isNotEmpty) git.closeDiffFile(path);
        }
      }
    }
    final revisionId = ref
        .read(localHistoryControllerProvider)
        .selectedRevisionId;
    if (targets.any(
      (tab) =>
          tab.kind == WorkspaceTabKind.localHistory &&
          tab.bufferId == revisionId,
    )) {
      history.clearComparison();
    }
    if (retain) {
      if (!await controller.activateDocumentBuffer(clicked!.bufferId!) ||
          !currentWorkspace()) {
        return false;
      }
      git.deactivateDiffFile();
    }
    return true;
  } finally {
    _closing[controller] = false;
  }
}
