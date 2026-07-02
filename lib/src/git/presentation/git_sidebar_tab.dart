import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/busymark_design.dart';
import '../../app/busymark_dialogs.dart';
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
        select: (paths) => controller.stageFiles(paths),
        unselect: (paths) => controller.unstageFiles(paths),
        discard: (paths) async {
          await controller.discardFiles(paths);
          await onAfterWorkspaceFilesChanged();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _RepositoryStrip(
              state: state,
              onLoadBranches: controller.loadBranches,
              onSelectView: controller.selectView,
              onCreateBranch: () async {
                final branchName = await _showCreateBranchDialog(context);
                if (branchName == null) {
                  return;
                }
                await controller.createBranch(branchName);
              },
              onSwitchBranch: (branchName) async {
                if (!await onConfirmSwitchBranch(branchName)) {
                  return;
                }
                await controller.switchBranch(branchName);
                if (ref.read(gitControllerProvider).lastError == null) {
                  await onAfterWorkspaceFilesChanged();
                }
              },
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
    required this.onLoadBranches,
    required this.onSelectView,
    required this.onCreateBranch,
    required this.onSwitchBranch,
    required this.onPull,
    required this.onPush,
  });

  final GitState state;
  final Future<List<GitBranch>> Function() onLoadBranches;
  final ValueChanged<GitView> onSelectView;
  final Future<void> Function() onCreateBranch;
  final Future<void> Function(String branchName) onSwitchBranch;
  final Future<void> Function() onPull;
  final Future<void> Function() onPush;

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
        color: colors.sidebar,
        border: Border(bottom: BorderSide(color: colors.sidebarBorder)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BusyMarkSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  BusyMarkGlyphs.branch,
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
                BusyMarkHeaderPopupMenuButton<_BranchMenuAction>(
                  tooltip: context.l10n.gitBranches,
                  icon: BusyMarkGlyphs.branch,
                  transparent: true,
                  itemBuilder: (context) async {
                    final newBranchLabel = context.l10n.gitNewBranch;
                    final pullLabel = context.l10n.gitPull;
                    final pushLabel = context.l10n.gitPush;
                    final branches = await onLoadBranches();
                    return [
                      BusyMarkPopupMenuItem(
                        value: const _PullBranchMenuAction(),
                        label: pullLabel,
                        icon: BusyMarkGlyphs.pull,
                        enabled: repo.upstreamBranch != null,
                      ),
                      BusyMarkPopupMenuItem(
                        value: const _PushBranchMenuAction(),
                        label: pushLabel,
                        icon: BusyMarkGlyphs.push,
                        enabled: repo.hasRemote,
                      ),
                      BusyMarkPopupMenuItem(
                        value: const _CreateBranchMenuAction(),
                        label: newBranchLabel,
                        icon: BusyMarkGlyphs.newDocument,
                      ),
                      const PopupMenuDivider(height: BusyMarkSpacing.sm),
                      for (final branch in branches)
                        BusyMarkPopupMenuItem(
                          value: _SwitchBranchMenuAction(branch.name),
                          label: branch.name,
                          icon: BusyMarkGlyphs.branch,
                          checked: branch.current,
                          trailingCheck: true,
                        ),
                    ];
                  },
                  onSelected: (action) {
                    unawaited(_handleBranchAction(action));
                  },
                ),
                BusyMarkHeaderPopupMenuButton<GitView>(
                  tooltip: _gitViewLabel(context, state.selectedView),
                  icon: _gitViewIcon(state.selectedView),
                  transparent: true,
                  itemBuilder: (context) => [
                    for (final view in GitView.values)
                      BusyMarkPopupMenuItem(
                        value: view,
                        label: _gitViewLabel(context, view),
                        icon: _gitViewIcon(view),
                        checked: view == state.selectedView,
                        trailingCheck: true,
                      ),
                  ],
                  onSelected: onSelectView,
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
          ],
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

  Future<void> _handleBranchAction(_BranchMenuAction action) async {
    switch (action) {
      case _SwitchBranchMenuAction(:final branchName):
        if (branchName == state.repositoryInfo?.currentBranch) {
          return;
        }
        await onSwitchBranch(branchName);
      case _CreateBranchMenuAction():
        await onCreateBranch();
      case _PullBranchMenuAction():
        await onPull();
      case _PushBranchMenuAction():
        await onPush();
    }
  }
}

String _gitViewLabel(BuildContext context, GitView view) {
  return switch (view) {
    GitView.changes => context.l10n.gitChanges,
    GitView.history => context.l10n.gitHistory,
  };
}

IconData _gitViewIcon(GitView view) {
  return switch (view) {
    GitView.changes => BusyMarkGlyphs.checklist,
    GitView.history => BusyMarkGlyphs.history,
  };
}

sealed class _BranchMenuAction {
  const _BranchMenuAction();
}

final class _SwitchBranchMenuAction extends _BranchMenuAction {
  const _SwitchBranchMenuAction(this.branchName);

  final String branchName;
}

final class _CreateBranchMenuAction extends _BranchMenuAction {
  const _CreateBranchMenuAction();
}

final class _PullBranchMenuAction extends _BranchMenuAction {
  const _PullBranchMenuAction();
}

final class _PushBranchMenuAction extends _BranchMenuAction {
  const _PushBranchMenuAction();
}

Future<String?> _showCreateBranchDialog(BuildContext context) {
  return showBusyMarkModalDialog<String>(
    context,
    builder: (context) => const _CreateBranchDialog(),
  );
}

class _CreateBranchDialog extends StatefulWidget {
  const _CreateBranchDialog();

  @override
  State<_CreateBranchDialog> createState() => _CreateBranchDialogState();
}

class _CreateBranchDialogState extends State<_CreateBranchDialog> {
  late final TextEditingController _controller;

  bool get _canCreate => _controller.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController()..addListener(_handleChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BusyMarkDialogShell(
      title: context.l10n.gitCreateBranch,
      maxWidth: BusyMarkSizes.dialogCompact,
      actions: [
        BusyMarkDialogButton(
          label: context.l10n.cancel,
          onPressed: () => Navigator.pop(context),
        ),
        BusyMarkDialogButton(
          label: context.l10n.gitCreateBranch,
          suggested: true,
          onPressed: _canCreate ? _submit : null,
        ),
      ],
      children: [
        BusyMarkFloatingTextEntry(
          label: context.l10n.gitBranchName,
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
        ),
      ],
    );
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      return;
    }
    Navigator.pop(context, value);
  }

  void _handleChanged() {
    setState(() {});
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
