import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/busymark_design.dart';
import '../../app/busymark_glyphs.dart';
import '../../app/localization.dart';
import '../../workspace/workspace_model.dart';
import '../application/git_controller.dart';
import '../domain/git_models.dart';
import 'git_changes_view.dart';
import 'git_history_view.dart';

class GitSidebarTab extends ConsumerWidget {
  const GitSidebarTab({
    super.key,
    required this.workspace,
    this.view = GitView.changes,
    required this.onOpenFile,
    required this.onConfirmDiscard,
    required this.onAfterWorkspaceFilesChanged,
    required this.onConfirmSwitchBranch,
    required this.onConfirmPushSetUpstream,
  });

  final Workspace workspace;
  final GitView view;
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
    if (state.selectedView != view) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.selectView(view);
      });
    }
    return GitCommitActions(
      commit: controller.commit,
      child: GitFileActions(
        select: (paths) => controller.stageFiles(paths),
        unselect: (paths) => controller.unstageFiles(paths),
        discard: (paths) async {
          await controller.discardFiles(paths);
          await onAfterWorkspaceFilesChanged();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _RepositoryStrip(state: state),
            if (state.lastError != null)
              _GitMessage(failure: state.lastError!)
            else if (state.lastOperationMessage?.isNotEmpty ?? false)
              _GitOperationMessage(message: state.lastOperationMessage!),
            Expanded(
              child: switch (view) {
                GitView.changes => GitChangesView(
                  state: state,
                  onSelectFile: controller.selectChangedFile,
                  onOpenFile: onOpenFile,
                  onConfirmDiscard: onConfirmDiscard,
                ),
                GitView.history => GitHistoryView(
                  state: state,
                  onSelectCommit: controller.loadCommitDetails,
                  onShowFileDiff: controller.selectCommitFile,
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
  const _RepositoryStrip({required this.state});

  final GitState state;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final repo = state.repositoryInfo!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.sidebar,
        border: Border(bottom: BorderSide(color: colors.sidebarBorder)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BusyMarkSpacing.md),
        child: Text(
          _repositoryDetail(context, repo),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: colors.mutedForeground),
        ),
      ),
    );
  }

  String _repositoryDetail(BuildContext context, GitRepositoryInfo repo) {
    final state = repo.hasConflicts
        ? context.l10n.gitConflicts
        : (repo.aheadCount == 0 && repo.behindCount == 0
              ? context.l10n.gitClean
              : [
                  if (repo.aheadCount > 0)
                    context.l10n.gitAheadCount(repo.aheadCount),
                  if (repo.behindCount > 0)
                    context.l10n.gitBehindCount(repo.behindCount),
                ].join(', '));
    return repo.upstreamBranch == null ? context.l10n.gitNoUpstream : state;
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
      GitFailureCode.noStagedFiles => context.l10n.gitCommitNoSelectedFiles,
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
