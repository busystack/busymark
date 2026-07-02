import 'package:flutter/material.dart';

import '../../app/busymark_design.dart';
import '../../app/busymark_glyphs.dart';
import '../../app/localization.dart';
import '../application/git_controller.dart';
import '../domain/git_models.dart';
import 'git_commit_dialog.dart';

class GitChangesView extends StatelessWidget {
  const GitChangesView({
    super.key,
    required this.state,
    required this.onSelectFile,
    required this.onOpenFile,
    required this.onConfirmDiscard,
  });

  final GitState state;
  final ValueChanged<String> onSelectFile;
  final ValueChanged<String> onOpenFile;
  final Future<bool> Function(List<GitFileStatus> files) onConfirmDiscard;

  @override
  Widget build(BuildContext context) {
    final snapshot = state.statusSnapshot;
    if (snapshot == null) {
      return Center(child: Text(context.l10n.gitNoChanges));
    }
    if (snapshot.clean) {
      return Center(child: Text(context.l10n.gitClean));
    }
    return ListView(
      padding: BusyMarkInsets.sidebarList,
      children: [
        _RepositoryActions(state: state),
        _ChangeGroup(
          title: context.l10n.gitConflicts,
          files: snapshot.conflictedFiles,
          selectedPath: state.selectedFilePath,
          onSelectFile: onSelectFile,
          onOpenFile: onOpenFile,
          onConfirmDiscard: onConfirmDiscard,
        ),
        _ChangeGroup(
          title: context.l10n.gitStaged,
          files: snapshot.stagedFiles,
          selectedPath: state.selectedFilePath,
          onSelectFile: onSelectFile,
          onOpenFile: onOpenFile,
          onConfirmDiscard: onConfirmDiscard,
        ),
        _ChangeGroup(
          title: context.l10n.gitChanges,
          files: snapshot.unstagedFiles,
          selectedPath: state.selectedFilePath,
          onSelectFile: onSelectFile,
          onOpenFile: onOpenFile,
          onConfirmDiscard: onConfirmDiscard,
        ),
        _ChangeGroup(
          title: context.l10n.gitUntracked,
          files: snapshot.untrackedFiles,
          selectedPath: state.selectedFilePath,
          onSelectFile: onSelectFile,
          onOpenFile: onOpenFile,
          onConfirmDiscard: onConfirmDiscard,
        ),
        const SizedBox(height: BusyMarkSpacing.xl),
      ],
    );
  }
}

class _RepositoryActions extends StatelessWidget {
  const _RepositoryActions({required this.state});

  final GitState state;

  @override
  Widget build(BuildContext context) {
    final staged = state.statusSnapshot?.stagedFiles ?? const [];
    return Padding(
      padding: const EdgeInsets.only(bottom: BusyMarkSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: staged.isEmpty
                  ? null
                  : () => _showCommitDialog(context, staged),
              icon: const Icon(BusyMarkGlyphs.check),
              label: Text(context.l10n.gitCommit),
            ),
          ),
        ],
      ),
    );
  }

  void _showCommitDialog(BuildContext context, List<GitFileStatus> staged) {
    showDialog<void>(
      context: context,
      builder: (context) => GitCommitDialog(
        stagedFiles: staged,
        onCommit: (message) => GitCommitActions.of(context).commit(message),
      ),
    );
  }
}

class GitCommitActions extends InheritedWidget {
  const GitCommitActions({
    super.key,
    required this.commit,
    required super.child,
  });

  final Future<void> Function(String message) commit;

  static GitCommitActions of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<GitCommitActions>()!;
  }

  @override
  bool updateShouldNotify(GitCommitActions oldWidget) {
    return commit != oldWidget.commit;
  }
}

class _ChangeGroup extends StatelessWidget {
  const _ChangeGroup({
    required this.title,
    required this.files,
    required this.selectedPath,
    required this.onSelectFile,
    required this.onOpenFile,
    required this.onConfirmDiscard,
  });

  final String title;
  final List<GitFileStatus> files;
  final String? selectedPath;
  final ValueChanged<String> onSelectFile;
  final ValueChanged<String> onOpenFile;
  final Future<bool> Function(List<GitFileStatus> files) onConfirmDiscard;

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: BusyMarkSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: BusyMarkInsets.sectionLabel,
            child: Text(title, style: busyMarkSectionHeaderStyle(context)),
          ),
          for (final file in files)
            _ChangedFileRow(
              file: file,
              selected: file.repoRelativePath == selectedPath,
              onSelect: () => onSelectFile(file.repoRelativePath),
              onOpen: () => onOpenFile(file.repoRelativePath),
              onDiscard: () async {
                final actions = GitFileActions.of(context);
                if (await onConfirmDiscard([file])) {
                  actions.discard([file.repoRelativePath]);
                }
              },
            ),
        ],
      ),
    );
  }
}

class GitFileActions extends InheritedWidget {
  const GitFileActions({
    super.key,
    required this.stage,
    required this.unstage,
    required this.discard,
    required super.child,
  });

  final void Function(List<String> paths) stage;
  final void Function(List<String> paths) unstage;
  final void Function(List<String> paths) discard;

  static GitFileActions of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<GitFileActions>()!;
  }

  @override
  bool updateShouldNotify(GitFileActions oldWidget) {
    return stage != oldWidget.stage ||
        unstage != oldWidget.unstage ||
        discard != oldWidget.discard;
  }
}

class _ChangedFileRow extends StatelessWidget {
  const _ChangedFileRow({
    required this.file,
    required this.selected,
    required this.onSelect,
    required this.onOpen,
    required this.onDiscard,
  });

  final GitFileStatus file;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onOpen;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final directory = _directoryLabel(file.repoRelativePath);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BusyMarkStroke.hairline),
      child: Material(
        color: selected
            ? busyMarkSelectedBackground(context)
            : BusyMarkLinuxPalette.transparent,
        borderRadius: BorderRadius.circular(BusyMarkRadius.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          hoverColor: busyMarkRowHoverColor(context),
          onTap: onSelect,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BusyMarkSpacing.sm,
              vertical: BusyMarkSpacing.xs,
            ),
            child: Row(
              children: [
                _StatusBadge(file: file),
                const SizedBox(width: BusyMarkSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _fileName(file.repoRelativePath),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (directory.isNotEmpty)
                        Text(
                          directory,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: colors.mutedForeground),
                        ),
                    ],
                  ),
                ),
                BusyMarkHeaderPopupMenuButton<_FileAction>(
                  tooltip: context.l10n.gitFileActions,
                  icon: BusyMarkGlyphs.menuHorizontal,
                  transparent: true,
                  itemBuilder: (context) => [
                    if (!file.staged || file.conflicted)
                      BusyMarkPopupMenuItem(
                        value: _FileAction.stage,
                        label: file.conflicted
                            ? context.l10n.gitStageResolved
                            : context.l10n.gitStage,
                        icon: BusyMarkGlyphs.check,
                      ),
                    if (file.staged)
                      BusyMarkPopupMenuItem(
                        value: _FileAction.unstage,
                        label: context.l10n.gitUnstage,
                        icon: BusyMarkGlyphs.undo,
                      ),
                    BusyMarkPopupMenuItem(
                      value: _FileAction.open,
                      label: context.l10n.gitOpenFile,
                      icon: BusyMarkGlyphs.externalLink,
                    ),
                    BusyMarkPopupMenuItem(
                      value: _FileAction.discard,
                      label: context.l10n.gitDiscard,
                      icon: BusyMarkGlyphs.delete,
                    ),
                  ],
                  onSelected: (action) {
                    final actions = GitFileActions.of(context);
                    switch (action) {
                      case _FileAction.stage:
                        actions.stage([file.repoRelativePath]);
                      case _FileAction.unstage:
                        actions.unstage([file.repoRelativePath]);
                      case _FileAction.open:
                        onOpen();
                      case _FileAction.discard:
                        onDiscard();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _fileName(String path) {
    final parts = path.split('/');
    return parts.isEmpty ? path : parts.last;
  }

  String _directoryLabel(String path) {
    final parts = path.split('/');
    if (parts.length <= 1) {
      return '';
    }
    return parts.take(parts.length - 1).join('/');
  }
}

enum _FileAction { stage, unstage, open, discard }

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.file});

  final GitFileStatus file;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final colors = BusyMarkSurfaceColors.of(context);
    final foreground = file.conflicted ? colorScheme.error : colors.foreground;
    return Tooltip(
      message: _statusLabel(context),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: file.conflicted ? colorScheme.errorContainer : colors.control,
          borderRadius: BorderRadius.circular(BusyMarkRadius.sm),
          border: Border.all(color: colors.subtleBorder),
        ),
        child: SizedBox(
          width: 24,
          height: 22,
          child: Center(
            child: Text(
              _statusCode(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _statusCode() {
    return switch (file.category) {
      GitFileStatusCategory.added => 'A',
      GitFileStatusCategory.deleted => 'D',
      GitFileStatusCategory.renamed => 'R',
      GitFileStatusCategory.copied => 'C',
      GitFileStatusCategory.untracked => '?',
      GitFileStatusCategory.conflicted => '!',
      GitFileStatusCategory.ignored => 'I',
      GitFileStatusCategory.typeChanged => 'T',
      GitFileStatusCategory.modified || GitFileStatusCategory.unknown => 'M',
    };
  }

  String _statusLabel(BuildContext context) {
    return switch (file.category) {
      GitFileStatusCategory.added => context.l10n.gitStatusAdded,
      GitFileStatusCategory.deleted => context.l10n.gitStatusDeleted,
      GitFileStatusCategory.renamed => context.l10n.gitStatusRenamed,
      GitFileStatusCategory.copied => context.l10n.gitStatusCopied,
      GitFileStatusCategory.untracked => context.l10n.gitStatusUntracked,
      GitFileStatusCategory.conflicted => context.l10n.gitStatusConflicted,
      GitFileStatusCategory.ignored => context.l10n.gitStatusIgnored,
      GitFileStatusCategory.typeChanged => context.l10n.gitStatusTypeChanged,
      GitFileStatusCategory.modified => context.l10n.gitStatusModified,
      GitFileStatusCategory.unknown => context.l10n.gitStatusUnknown,
    };
  }
}
