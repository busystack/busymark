import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/busymark_design.dart';
import '../../app/busymark_dialogs.dart';
import '../../app/busymark_glyphs.dart';
import '../../app/localization.dart';
import '../../workspace/workspace_model.dart';
import '../../workspace/workspace_controller.dart';
import '../../workspace/workspace_safety.dart';
import '../application/git_controller.dart';
import '../domain/git_models.dart';
import 'git_changes_view.dart';
import 'git_history_view.dart';

class GitSidebarTab extends ConsumerWidget {
  const GitSidebarTab({
    super.key,
    required this.workspace,
    required this.onOpenFile,
    required this.onConfirmDiscard,
    required this.onAfterWorkspaceFilesChanged,
    required this.onConfirmSwitchBranch,
    required this.onConfirmPushSetUpstream,
  });

  final Workspace workspace;
  final ValueChanged<String> onOpenFile;
  final Future<bool> Function(List<GitFileStatus> files) onConfirmDiscard;
  final Future<void> Function() onAfterWorkspaceFilesChanged;
  final Future<bool> Function(String branchName) onConfirmSwitchBranch;
  final Future<bool> Function() onConfirmPushSetUpstream;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gitControllerProvider);
    final hasUnsavedEditorChanges = ref.watch(
      workspaceControllerProvider.select((value) => value.isDirty),
    );
    final controller = ref.read(gitControllerProvider.notifier);
    if (!state.availability.available) {
      return _GitEmptyState(
        icon: BusyMarkGlyphs.warning,
        title: context.l10n.gitUnavailableTitle,
        message: context.l10n.gitUnavailableMessage(
          state.availability.unavailableReason ?? '',
        ),
      );
    }
    if (state.requiresWorkspaceTrust) {
      return _GitEmptyState(
        icon: BusyMarkGlyphs.warning,
        title: context.l10n.gitTrustRequiredTitle,
        message: context.l10n.gitTrustRequiredMessage,
        actionLabel: context.l10n.gitTrustWorkspace,
        onAction: () => controller.trustWorkspace(),
      );
    }
    if (state.repositoryInfo == null) {
      final canInitialize =
          workspace.kind == WorkspaceKind.markdownFolder ||
          workspace.kind == WorkspaceKind.writersideModule;
      return _GitEmptyState(
        icon: BusyMarkGlyphs.tree,
        title: context.l10n.gitNotRepositoryTitle,
        message: context.l10n.gitNotRepositoryMessage,
        actionLabel: canInitialize
            ? context.l10n.gitInitializeRepository
            : null,
        onAction: canInitialize
            ? () => controller.initializeRepository()
            : null,
      );
    }
    if (state.selectedView == GitView.fileHistory &&
        state.scopedFilePath != null &&
        state.scopedFilePath != state.fileHistory.currentPath) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.loadActiveFileHistory();
      });
    }
    return GitCommitActions(
      commit: controller.commit,
      child: GitFileActions(
        select: (paths) => controller.stageFiles(paths),
        unselect: (paths) => controller.unstageFiles(paths),
        rollback: (paths) async {
          await controller.rollbackFiles(paths);
          await onAfterWorkspaceFilesChanged();
        },
        deleteUntracked: (paths) async {
          await controller.deleteUntrackedFiles(paths);
          await onAfterWorkspaceFilesChanged();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.lastError != null)
              _GitMessage(failure: state.lastError!)
            else if (state.lastOperationMessage?.isNotEmpty ?? false)
              _GitOperationMessage(message: state.lastOperationMessage!),
            Expanded(
              child: switch (state.selectedView) {
                GitView.changes => GitChangesView(
                  state: state,
                  onSelectFile: controller.selectChange,
                  onOpenFile: onOpenFile,
                  onConfirmDiscard: onConfirmDiscard,
                  hasUnsavedEditorChanges: hasUnsavedEditorChanges,
                  outsideWorkspacePaths: {
                    for (final file
                        in state.statusSnapshot?.stagedFiles ??
                            const <GitFileStatus>[])
                      if (controller.isOutsideWorkspace(file.repoRelativePath))
                        file.repoRelativePath,
                    for (final file
                        in state.statusSnapshot?.stagedFiles ??
                            const <GitFileStatus>[])
                      if (file.hasStagedRename &&
                          file.originalRepoRelativePath != null &&
                          controller.isOutsideWorkspace(
                            file.originalRepoRelativePath!,
                          ))
                        file.originalRepoRelativePath!,
                  },
                ),
                GitView.fileHistory => GitFileHistoryView(
                  state: state,
                  onSelectCommit: controller.selectFileHistoryCommit,
                  onRestoreVersion: () => _confirmRestoreVersion(
                    context,
                    controller,
                    hasUnsavedEditorChanges,
                  ),
                  onLoadMore: controller.loadMoreFileHistory,
                ),
                GitView.projectHistory => GitProjectHistoryView(
                  state: state,
                  onSelectCommit: controller.selectProjectCommit,
                  onShowFileDiff: controller.selectCommitFile,
                  onResetCurrentBranch: () =>
                      _confirmResetCurrentBranch(context, ref, controller),
                  onLoadMore: controller.loadMoreProjectHistory,
                ),
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRestoreVersion(
    BuildContext context,
    GitController controller,
    bool hasUnsavedEditorChanges,
  ) async {
    if (hasUnsavedEditorChanges || controller.selectedFileHasStagedChanges) {
      await controller.restoreSelectedFileVersion();
      return;
    }
    await controller.compareFileHistoryWithCurrent();
    if (!context.mounted) {
      return;
    }
    final confirmed = await showBusyMarkModalDialog<bool>(
      context,
      builder: (dialogContext) => BusyMarkDialogShell(
        title: dialogContext.l10n.gitConfirmRestoreTitle,
        actions: [
          BusyMarkDialogButton(
            label: MaterialLocalizations.of(dialogContext).cancelButtonLabel,
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          BusyMarkDialogButton(
            label: dialogContext.l10n.gitRestoreVersion,
            suggested: true,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
        children: [Text(dialogContext.l10n.gitConfirmRestoreMessage)],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    if (await controller.restoreSelectedFileVersion()) {
      await onAfterWorkspaceFilesChanged();
    }
  }

  Future<void> _confirmResetCurrentBranch(
    BuildContext context,
    WidgetRef ref,
    GitController controller,
  ) async {
    final state = ref.read(gitControllerProvider);
    final branch = state.repositoryInfo?.currentBranch;
    final selectedHash = state.projectHistory.selectedCommitHash;
    final selectedCommits = [
      for (final entry in state.projectHistory.commits)
        if (entry.fullHash == selectedHash) entry,
    ];
    if (branch == null || selectedCommits.isEmpty) {
      return;
    }
    final commit = selectedCommits.first;
    if (!await confirmSafeToContinue(context, ref) || !context.mounted) {
      return;
    }
    final mode = await showBusyMarkModalDialog<GitResetMode>(
      context,
      builder: (dialogContext) =>
          _GitResetDialog(branch: branch, commit: commit),
    );
    if (mode == null || !context.mounted) {
      return;
    }
    if (await controller.resetCurrentBranchToSelectedCommit(mode)) {
      await onAfterWorkspaceFilesChanged();
    }
  }
}

class _GitResetDialog extends StatefulWidget {
  const _GitResetDialog({required this.branch, required this.commit});

  final String branch;
  final GitCommitSummary commit;

  @override
  State<_GitResetDialog> createState() => _GitResetDialogState();
}

class _GitResetDialogState extends State<_GitResetDialog> {
  GitResetMode? _mode;

  @override
  Widget build(BuildContext context) {
    final commit = widget.commit.shortHash;
    return BusyMarkDialogShell(
      title: context.l10n.gitResetCurrentBranchTitle(widget.branch, commit),
      maxWidth: BusyMarkSizes.dialogWide,
      actions: [
        BusyMarkDialogButton(
          label: context.l10n.cancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        BusyMarkDialogButton(
          label: context.l10n.gitReset,
          destructive: true,
          onPressed: _mode == null
              ? null
              : () => Navigator.of(context).pop(_mode),
        ),
      ],
      children: [
        Text(context.l10n.gitResetCurrentBranchMessage(widget.branch, commit)),
        const SizedBox(height: BusyMarkSpacing.md),
        RadioGroup<GitResetMode>(
          groupValue: _mode,
          onChanged: (mode) => setState(() => _mode = mode),
          child: Column(
            children: [
              for (final mode in GitResetMode.values)
                RadioListTile<GitResetMode>(
                  key: ValueKey('git-reset-mode-${mode.name}'),
                  value: mode,
                  title: Text(_resetModeLabel(context, mode)),
                  subtitle: Text(_resetModeDescription(context, mode)),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _resetModeLabel(BuildContext context, GitResetMode mode) {
    return switch (mode) {
      GitResetMode.soft => context.l10n.gitResetModeSoft,
      GitResetMode.mixed => context.l10n.gitResetModeMixed,
      GitResetMode.hard => context.l10n.gitResetModeHard,
      GitResetMode.keep => context.l10n.gitResetModeKeep,
    };
  }

  String _resetModeDescription(BuildContext context, GitResetMode mode) {
    return switch (mode) {
      GitResetMode.soft => context.l10n.gitResetModeSoftDescription,
      GitResetMode.mixed => context.l10n.gitResetModeMixedDescription,
      GitResetMode.hard => context.l10n.gitResetModeHardDescription,
      GitResetMode.keep => context.l10n.gitResetModeKeepDescription,
    };
  }
}

class _GitMessage extends StatelessWidget {
  const _GitMessage({required this.failure});

  final GitFailure failure;

  @override
  Widget build(BuildContext context) {
    final message = _failureMessage(context, failure);
    final rawMessage = failure.rawMessage.trim();
    return SelectionArea(
      child: BusyMarkStatusBox(
        message: rawMessage.isEmpty ? message : '$message\n$rawMessage',
        kind: _gitFailureStatusKind(failure.code),
      ),
    );
  }

  String _failureMessage(BuildContext context, GitFailure failure) {
    return switch (failure.code) {
      GitFailureCode.unavailable ||
      GitFailureCode.unsupportedVersion => context.l10n.gitErrorUnavailable,
      GitFailureCode.notRepository => context.l10n.gitErrorNotRepository,
      GitFailureCode.invalidPath => context.l10n.gitErrorUnsafePath,
      GitFailureCode.invalidBranchName =>
        context.l10n.gitErrorInvalidBranchName,
      GitFailureCode.invalidCommitMessage =>
        context.l10n.gitCommitMessageRequired,
      GitFailureCode.noStagedFiles => context.l10n.gitCommitNoSelectedFiles,
      GitFailureCode.noRemote => context.l10n.gitErrorNoRemote,
      GitFailureCode.noUpstream => context.l10n.gitErrorNoUpstream,
      GitFailureCode.multipleRemotes => context.l10n.gitErrorMultipleRemotes,
      GitFailureCode.dirtyWorkspace =>
        failure.commandName == 'reset'
            ? context.l10n.gitErrorResetDirtyWorkspace
            : context.l10n.gitErrorDirtyWorkspace,
      GitFailureCode.stagedChanges => context.l10n.gitErrorRestoreStagedFile,
      GitFailureCode.detachedHead => context.l10n.gitErrorResetDetachedHead,
      GitFailureCode.diverged => context.l10n.gitErrorDiverged,
      GitFailureCode.authentication => context.l10n.gitErrorAuthentication,
      GitFailureCode.network => context.l10n.gitErrorNetwork,
      GitFailureCode.conflict => context.l10n.gitErrorConflict,
      GitFailureCode.commandFailed => context.l10n.gitErrorCommandFailed,
    };
  }
}

class _GitOperationMessage extends StatelessWidget {
  const _GitOperationMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return BusyMarkStatusBox(
      message: message,
      kind: BusyMarkStatusKind.success,
    );
  }
}

BusyMarkStatusKind _gitFailureStatusKind(GitFailureCode code) {
  return switch (code) {
    GitFailureCode.noStagedFiles ||
    GitFailureCode.noRemote ||
    GitFailureCode.noUpstream ||
    GitFailureCode.multipleRemotes => BusyMarkStatusKind.information,
    GitFailureCode.dirtyWorkspace ||
    GitFailureCode.stagedChanges ||
    GitFailureCode.detachedHead ||
    GitFailureCode.diverged ||
    GitFailureCode.conflict => BusyMarkStatusKind.warning,
    GitFailureCode.unavailable ||
    GitFailureCode.unsupportedVersion ||
    GitFailureCode.notRepository ||
    GitFailureCode.invalidPath ||
    GitFailureCode.invalidBranchName ||
    GitFailureCode.invalidCommitMessage ||
    GitFailureCode.authentication ||
    GitFailureCode.network ||
    GitFailureCode.commandFailed => BusyMarkStatusKind.error,
  };
}

class _GitEmptyState extends StatelessWidget {
  const _GitEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BusyMarkSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: colors.mutedForeground),
            const SizedBox(height: BusyMarkSpacing.sm),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: BusyMarkSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.mutedForeground),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: BusyMarkSpacing.md),
              BusyMarkPushButton.standard(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
