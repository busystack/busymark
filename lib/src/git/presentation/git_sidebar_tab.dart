import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/busymark_design.dart';
import '../../app/busymark_glyphs.dart';
import '../../app/localization.dart';
import '../../workspace/workspace_model.dart';
import '../application/git_controller.dart';
import '../domain/git_models.dart';
import 'git_branches_view.dart';
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
    final controller = ref.read(gitControllerProvider.notifier);
    if (!state.availability.available) {
      return _GitEmptyState(
        icon: BusyMarkGlyphs.warning,
        title: context.l10n.gitUnavailableTitle,
        message: context.l10n.gitUnavailableMessage(
          state.availability.unsupportedReason ?? '',
        ),
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
    return GitCommitActions(
      commit: controller.commit,
      child: GitFileActions(
        stage: (paths) => controller.stageFiles(paths),
        unstage: (paths) => controller.unstageFiles(paths),
        discard: (paths) async {
          await controller.discardFiles(paths);
          await onAfterWorkspaceFilesChanged();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _RepositoryStrip(
              state: state,
              onRefresh: controller.refresh,
              onFetch: controller.fetch,
              onPull: () async {
                await controller.pullFastForwardOnly();
                await onAfterWorkspaceFilesChanged();
              },
              onPush: () async {
                final repo = state.repositoryInfo;
                final allowSetUpstream =
                    repo?.upstreamBranch == null &&
                    await onConfirmPushSetUpstream();
                await controller.push(allowSetUpstream: allowSetUpstream);
              },
            ),
            if (state.lastError != null)
              _GitMessage(failure: state.lastError!)
            else if (state.lastOperationMessage?.isNotEmpty ?? false)
              _GitOperationMessage(message: state.lastOperationMessage!),
            Padding(
              padding: BusyMarkInsets.sidebarTabs,
              child: SegmentedButton<GitView>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: GitView.changes,
                    label: Text(context.l10n.gitChanges),
                  ),
                  ButtonSegment(
                    value: GitView.history,
                    label: Text(context.l10n.gitHistory),
                  ),
                  ButtonSegment(
                    value: GitView.branches,
                    label: Text(context.l10n.gitBranches),
                  ),
                ],
                selected: {state.selectedView},
                onSelectionChanged: (value) =>
                    controller.selectView(value.first),
              ),
            ),
            Expanded(
              child: switch (state.selectedView) {
                GitView.changes => GitChangesView(
                  state: state,
                  onSelectFile: controller.selectChangedFile,
                  onOpenFile: onOpenFile,
                  onConfirmDiscard: onConfirmDiscard,
                ),
                GitView.history => GitHistoryView(
                  state: state,
                  onLoadProjectHistory: () => controller.loadProjectHistory(),
                  onLoadFileHistory: () {
                    final active = workspace.activeFilePath;
                    if (active != null) {
                      controller.loadFileHistory(active);
                    }
                  },
                  onSelectCommit: controller.loadCommitDetails,
                ),
                GitView.branches => GitBranchesView(
                  state: state,
                  onCreateBranch: controller.createBranch,
                  onSwitchBranch: (branchName) async {
                    if (!await onConfirmSwitchBranch(branchName)) {
                      return;
                    }
                    await controller.switchBranch(branchName);
                    if (ref.read(gitControllerProvider).lastError == null) {
                      await onAfterWorkspaceFilesChanged();
                    }
                  },
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RepositoryStrip extends StatelessWidget {
  const _RepositoryStrip({
    required this.state,
    required this.onRefresh,
    required this.onFetch,
    required this.onPull,
    required this.onPush,
  });

  final GitState state;
  final VoidCallback onRefresh;
  final VoidCallback onFetch;
  final VoidCallback onPull;
  final VoidCallback onPush;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final repo = state.repositoryInfo!;
    final branch =
        repo.currentBranch ??
        (repo.detachedHeadCommit == null
            ? context.l10n.gitDetachedHead
            : context.l10n.gitDetachedHeadAt(repo.detachedHeadCommit!));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.secondarySidebar,
        border: Border(bottom: BorderSide(color: colors.subtleBorder)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BusyMarkSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  BusyMarkGlyphs.tree,
                  size: BusyMarkSizes.iconSm,
                  color: colors.mutedForeground,
                ),
                const SizedBox(width: BusyMarkSpacing.sm),
                Expanded(
                  child: Text(
                    branch,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                BusyMarkHeaderIconButton(
                  tooltip: context.l10n.gitRefresh,
                  icon: BusyMarkGlyphs.redo,
                  transparent: true,
                  onPressed: state.isRefreshing ? null : onRefresh,
                ),
              ],
            ),
            const SizedBox(height: BusyMarkSpacing.xs),
            Text(
              _repositoryDetail(context, repo),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: colors.mutedForeground),
            ),
            const SizedBox(height: BusyMarkSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: repo.hasRemote ? onFetch : null,
                    child: Text(context.l10n.gitFetch),
                  ),
                ),
                const SizedBox(width: BusyMarkSpacing.xs),
                Expanded(
                  child: OutlinedButton(
                    onPressed: repo.upstreamBranch == null ? null : onPull,
                    child: Text(context.l10n.gitPull),
                  ),
                ),
                const SizedBox(width: BusyMarkSpacing.xs),
                Expanded(
                  child: OutlinedButton(
                    onPressed: repo.hasRemote ? onPush : null,
                    child: Text(context.l10n.gitPush),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _repositoryDetail(BuildContext context, GitRepositoryInfo repo) {
    final upstream = repo.upstreamBranch ?? context.l10n.gitNoUpstream;
    final state = repo.hasConflicts
        ? context.l10n.gitConflicts
        : (repo.aheadCount == 0 && repo.behindCount == 0
              ? context.l10n.gitClean
              : context.l10n.gitAheadBehind(repo.aheadCount, repo.behindCount));
    return '$upstream - $state';
  }
}

class _GitMessage extends StatelessWidget {
  const _GitMessage({required this.failure});

  final GitFailure failure;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.admonitionWarning,
        border: Border(bottom: BorderSide(color: colors.subtleBorder)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BusyMarkSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(BusyMarkGlyphs.warning, size: BusyMarkSizes.iconSm),
                const SizedBox(width: BusyMarkSpacing.sm),
                Expanded(child: Text(_failureMessage(context, failure))),
              ],
            ),
            if (failure.rawMessage.trim().isNotEmpty) ...[
              const SizedBox(height: BusyMarkSpacing.xs),
              SelectableText(
                failure.rawMessage.trim(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: BusyMarkTypography.monoFontFamily,
                ),
              ),
            ],
          ],
        ),
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
      GitFailureCode.noStagedFiles => context.l10n.gitCommitNoStagedFiles,
      GitFailureCode.noRemote => context.l10n.gitErrorNoRemote,
      GitFailureCode.noUpstream => context.l10n.gitErrorNoUpstream,
      GitFailureCode.multipleRemotes => context.l10n.gitErrorMultipleRemotes,
      GitFailureCode.dirtyWorkspace => context.l10n.gitErrorDirtyWorkspace,
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
    final colors = BusyMarkSurfaceColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.admonitionTip,
        border: Border(bottom: BorderSide(color: colors.subtleBorder)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BusyMarkSpacing.sm),
        child: Text(message, maxLines: 4, overflow: TextOverflow.ellipsis),
      ),
    );
  }
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
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
