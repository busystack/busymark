import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../ai/ai_edit_ui.dart';
import '../../ai/ai_models.dart';
import '../../app/busymark_design.dart';
import '../../app/busymark_dialogs.dart';
import '../../app/busymark_glyphs.dart';
import '../../app/busymark_toast.dart';
import '../../app/localization.dart';
import '../../workspace/workspace_model.dart';
import '../../workspace/workspace_controller.dart';
import '../../workspace/workspace_safety.dart';
import '../application/git_controller.dart';
import '../domain/git_models.dart';
import 'git_author_identity_dialog.dart';
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
    ref.listen<GitState>(gitControllerProvider, (previous, next) {
      final failure = next.lastError;
      if (failure != null && !identical(failure, previous?.lastError)) {
        if (failure.code == GitFailureCode.authorIdentity) {
          return;
        }
        _showGitFailureToast(context, failure);
        return;
      }
      final message = next.lastOperationMessage?.trim();
      if (message != null &&
          message.isNotEmpty &&
          message != previous?.lastOperationMessage?.trim()) {
        BusyMarkToastOverlay.show(context, message: message);
      }
    });
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
      commit: (message) =>
          _commitWithIdentityRecovery(context, ref, controller, message),
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
            Expanded(
              child: switch (state.selectedView) {
                GitView.changes => GitChangesView(
                  state: state,
                  onSelectFile: controller.selectChange,
                  onOpenFile: onOpenFile,
                  onConfirmDiscard: onConfirmDiscard,
                  hasUnsavedEditorChanges: hasUnsavedEditorChanges,
                  canOpenFile: (file) => _canOpenGitFile(workspace, file),
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
                  onDraftCommitMessage: () =>
                      _draftCommitMessage(context, ref, controller),
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

  Future<String?> _draftCommitMessage(
    BuildContext context,
    WidgetRef ref,
    GitController controller,
  ) async {
    final stagedDiff = await controller.stagedDiffForAi();
    if (stagedDiff == null || !context.mounted) {
      return null;
    }
    final provider = await chooseBusyMarkAiProvider(context, ref);
    if (provider == null || !context.mounted) {
      return null;
    }
    final repository = ref.read(gitControllerProvider).repositoryInfo;
    return showBusyMarkAiProposal(
      context,
      ref,
      AiEditInvocation(
        feature: AiFeature.draftCommitMessage,
        scope: AiScope.gitDiff,
        input: stagedDiff.patch,
        replacementOriginal: '',
        sourceRevision: 0,
        targetId: 'git-commit:${repository?.rootPath ?? 'repository'}',
        documentPath: null,
        contentFormat: AiContentFormat.plainText,
        enforceDocumentRevision: false,
      ),
      providerKind: provider,
      validateBeforeApply: () =>
          controller.stagedDiffMatches(stagedDiff.fingerprint),
      staleMessage: context.l10n.gitAiStagedChangesChanged,
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

bool _canOpenGitFile(Workspace workspace, GitFileStatus status) {
  final matching = workspace.files
      .where((file) => file.absolutePath == status.absolutePath)
      .firstOrNull;
  final kind = matching?.kind;
  if (kind != null) {
    return switch (kind) {
      DocumentKind.markdown ||
      DocumentKind.writersideMarkdownTopic ||
      DocumentKind.writersideXmlTopic ||
      DocumentKind.tree ||
      DocumentKind.config ||
      DocumentKind.variables ||
      DocumentKind.categories ||
      DocumentKind.gitIgnore ||
      DocumentKind.resource => true,
      DocumentKind.image || DocumentKind.unknown => false,
    };
  }
  final normalized = status.repoRelativePath.toLowerCase();
  return normalized.endsWith('.md') ||
      normalized.endsWith('.markdown') ||
      normalized.endsWith('.topic') ||
      normalized.endsWith('.tree') ||
      normalized.endsWith('.cfg') ||
      normalized.endsWith('.list') ||
      normalized.endsWith('.xml') ||
      normalized.endsWith('.css') ||
      normalized.endsWith('.js') ||
      normalized.endsWith('/.gitignore') ||
      normalized == '.gitignore';
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

String _gitFailureMessage(BuildContext context, GitFailure failure) {
  return switch (failure.code) {
    GitFailureCode.unavailable ||
    GitFailureCode.unsupportedVersion => context.l10n.gitErrorUnavailable,
    GitFailureCode.notRepository => context.l10n.gitErrorNotRepository,
    GitFailureCode.invalidPath => context.l10n.gitErrorUnsafePath,
    GitFailureCode.invalidBranchName => context.l10n.gitErrorInvalidBranchName,
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
    GitFailureCode.authorIdentity => context.l10n.gitErrorAuthorIdentity,
    GitFailureCode.authentication => context.l10n.gitErrorAuthentication,
    GitFailureCode.network => context.l10n.gitErrorNetwork,
    GitFailureCode.conflict => context.l10n.gitErrorConflict,
    GitFailureCode.commandFailed => context.l10n.gitErrorCommandFailed,
  };
}

Future<bool> _commitWithIdentityRecovery(
  BuildContext context,
  WidgetRef ref,
  GitController controller,
  String message,
) async {
  if (await controller.commit(message)) {
    return true;
  }
  final failure = ref.read(gitControllerProvider).lastError;
  if (failure?.code != GitFailureCode.authorIdentity || !context.mounted) {
    return false;
  }
  final identity = await showGitAuthorIdentityDialog(context);
  if (identity == null || !context.mounted) {
    return false;
  }
  final configured = await controller.configureAuthorIdentity(
    name: identity.name,
    email: identity.email,
    globally: identity.globally,
  );
  if (!configured || !context.mounted) {
    return false;
  }
  return controller.commit(message);
}

void _showGitFailureToast(BuildContext context, GitFailure failure) {
  final summary = _gitFailureMessage(context, failure);
  final rawMessage = failure.rawMessage.trim();
  final firstDetail = rawMessage
      .split('\n')
      .map((line) => line.trim())
      .firstWhere((line) => line.isNotEmpty, orElse: () => '');
  BusyMarkToastOverlay.show(
    context,
    message: firstDetail.isEmpty ? summary : '$summary\n$firstDetail',
    actionLabel: rawMessage.isEmpty ? null : context.l10n.copy,
    onAction: rawMessage.isEmpty
        ? null
        : () => Clipboard.setData(ClipboardData(text: rawMessage)),
    duration: const Duration(seconds: 8),
    priority: BusyMarkToastPriority.high,
  );
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
