import 'package:flutter/material.dart';

import '../../app/busymark_design.dart';
import '../../app/busymark_glyphs.dart';
import '../../app/localization.dart';
import '../application/git_controller.dart';
import '../domain/git_models.dart';
import 'git_file_status_colors.dart';

class GitChangesView extends StatefulWidget {
  const GitChangesView({
    super.key,
    required this.state,
    required this.onSelectFile,
    required this.onOpenFile,
    required this.onConfirmDiscard,
    this.hasUnsavedEditorChanges = false,
    this.outsideWorkspacePaths = const {},
    this.onDraftCommitMessage,
    this.canOpenFile,
  });

  final GitState state;
  final ValueChanged<GitChangeSelection> onSelectFile;
  final ValueChanged<String> onOpenFile;
  final Future<bool> Function(List<GitFileStatus> files) onConfirmDiscard;
  final bool hasUnsavedEditorChanges;
  final Set<String> outsideWorkspacePaths;
  final Future<String?> Function()? onDraftCommitMessage;
  final bool Function(GitFileStatus file)? canOpenFile;

  @override
  State<GitChangesView> createState() => _GitChangesViewState();
}

class _GitChangesViewState extends State<GitChangesView> {
  late final TextEditingController _commitMessageController;
  var _committing = false;
  var _drafting = false;

  @override
  void initState() {
    super.initState();
    _commitMessageController = TextEditingController()
      ..addListener(_handleCommitMessageChanged);
  }

  @override
  void didUpdateWidget(GitChangesView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final workspaceChanged =
        oldWidget.state.attachedWorkspace?.id !=
        widget.state.attachedWorkspace?.id;
    final repositoryChanged =
        oldWidget.state.repositoryInfo?.rootPath !=
        widget.state.repositoryInfo?.rootPath;
    if (workspaceChanged || repositoryChanged) {
      _commitMessageController.clear();
    }
  }

  @override
  void dispose() {
    _commitMessageController
      ..removeListener(_handleCommitMessageChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.state.statusSnapshot;
    if (snapshot == null) {
      return Center(child: Text(context.l10n.gitNoChanges));
    }
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: BusyMarkInsets.sidebarList,
            children: [
              if (snapshot.clean)
                Padding(
                  padding: const EdgeInsets.all(BusyMarkSpacing.lg),
                  child: Text(
                    context.l10n.gitNoChanges,
                    textAlign: TextAlign.center,
                  ),
                )
              else ...[
                _ChangeGroup(
                  kind: _ChangeGroupKind.conflicts,
                  title: context.l10n.gitConflicts,
                  files: snapshot.conflictedFiles,
                  selectedChange: widget.state.selectedChange,
                  onSelectFile: widget.onSelectFile,
                  onOpenFile: widget.onOpenFile,
                  onConfirmDiscard: widget.onConfirmDiscard,
                  canOpenFile: widget.canOpenFile,
                ),
                _ChangeGroup(
                  kind: _ChangeGroupKind.staged,
                  title: context.l10n.gitStaged,
                  files: snapshot.stagedFiles,
                  selectedChange: widget.state.selectedChange,
                  onSelectFile: widget.onSelectFile,
                  onOpenFile: widget.onOpenFile,
                  onConfirmDiscard: widget.onConfirmDiscard,
                  outsideWorkspacePaths: widget.outsideWorkspacePaths,
                  canOpenFile: widget.canOpenFile,
                ),
                _ChangeGroup(
                  kind: _ChangeGroupKind.unstaged,
                  title: context.l10n.gitUnstaged,
                  files: snapshot.unstagedFiles,
                  selectedChange: widget.state.selectedChange,
                  onSelectFile: widget.onSelectFile,
                  onOpenFile: widget.onOpenFile,
                  onConfirmDiscard: widget.onConfirmDiscard,
                  canOpenFile: widget.canOpenFile,
                ),
                _ChangeGroup(
                  kind: _ChangeGroupKind.untracked,
                  title: context.l10n.gitUntracked,
                  files: snapshot.untrackedFiles,
                  selectedChange: widget.state.selectedChange,
                  onSelectFile: widget.onSelectFile,
                  onOpenFile: widget.onOpenFile,
                  onConfirmDiscard: widget.onConfirmDiscard,
                  canOpenFile: widget.canOpenFile,
                ),
              ],
              const SizedBox(height: BusyMarkSpacing.xl),
            ],
          ),
        ),
        _CommitPanel(
          controller: _commitMessageController,
          stagedFiles: snapshot.stagedFiles,
          hasUnsavedEditorChanges: widget.hasUnsavedEditorChanges,
          committing: _committing,
          onCommit: _commit,
          onDraftCommitMessage: widget.onDraftCommitMessage == null
              ? null
              : _draftCommitMessage,
          drafting: _drafting,
        ),
      ],
    );
  }

  Future<void> _draftCommitMessage() async {
    final callback = widget.onDraftCommitMessage;
    if (callback == null || _drafting || _committing) {
      return;
    }
    setState(() => _drafting = true);
    try {
      final proposal = await callback();
      if (mounted && proposal != null) {
        _commitMessageController
          ..text = proposal.trim()
          ..selection = TextSelection.collapsed(offset: proposal.trim().length);
      }
    } finally {
      if (mounted) {
        setState(() => _drafting = false);
      }
    }
  }

  Future<void> _commit() async {
    if (_committing ||
        _commitMessageController.text.trim().isEmpty ||
        (widget.state.statusSnapshot?.stagedFiles.isEmpty ?? true)) {
      return;
    }
    setState(() => _committing = true);
    try {
      final succeeded = await GitCommitActions.of(
        context,
      ).commit(_commitMessageController.text);
      if (succeeded && mounted) {
        _commitMessageController.clear();
      }
    } finally {
      if (mounted) {
        setState(() => _committing = false);
      }
    }
  }

  void _handleCommitMessageChanged() {
    setState(() {});
  }
}

class _CommitPanel extends StatelessWidget {
  const _CommitPanel({
    required this.controller,
    required this.stagedFiles,
    required this.committing,
    required this.onCommit,
    required this.hasUnsavedEditorChanges,
    required this.drafting,
    this.onDraftCommitMessage,
  });

  final TextEditingController controller;
  final List<GitFileStatus> stagedFiles;
  final bool committing;
  final Future<void> Function() onCommit;
  final bool hasUnsavedEditorChanges;
  final bool drafting;
  final Future<void> Function()? onDraftCommitMessage;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final canCommit =
        !committing &&
        stagedFiles.isNotEmpty &&
        controller.text.trim().isNotEmpty;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.secondarySidebar,
        border: Border(top: BorderSide(color: colors.subtleBorder)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BusyMarkSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.gitCommitMessage,
              style: busyMarkSectionHeaderStyle(context),
            ),
            if (hasUnsavedEditorChanges) ...[
              const SizedBox(height: BusyMarkSpacing.sm),
              BusyMarkStatusBox(
                message: context.l10n.gitUnsavedChangesBanner,
                kind: BusyMarkStatusKind.warning,
              ),
            ],
            const SizedBox(height: BusyMarkSpacing.sm),
            TextField(
              controller: controller,
              minLines: 3,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.all(BusyMarkSpacing.sm),
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: BusyMarkSpacing.sm),
            if (onDraftCommitMessage != null) ...[
              BusyMarkPushButton.standard(
                onPressed: !committing && !drafting && stagedFiles.isNotEmpty
                    ? () => onDraftCommitMessage!()
                    : null,
                child: Text(
                  drafting
                      ? context.l10n.aiDrafting
                      : context.l10n.aiDraftWithAi,
                ),
              ),
              const SizedBox(height: BusyMarkSpacing.sm),
            ],
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.gitStagedFileCount(stagedFiles.length),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.mutedForeground,
                    ),
                  ),
                ),
                const SizedBox(width: BusyMarkSpacing.sm),
                BusyMarkPushButton.suggested(
                  onPressed: canCommit ? () => onCommit() : null,
                  child: Text(context.l10n.gitCommit),
                ),
              ],
            ),
          ],
        ),
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

  final Future<bool> Function(String message) commit;

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
    required this.kind,
    required this.title,
    required this.files,
    required this.selectedChange,
    required this.onSelectFile,
    required this.onOpenFile,
    required this.onConfirmDiscard,
    this.outsideWorkspacePaths = const {},
    this.canOpenFile,
  });

  final _ChangeGroupKind kind;
  final String title;
  final List<GitFileStatus> files;
  final GitChangeSelection? selectedChange;
  final ValueChanged<GitChangeSelection> onSelectFile;
  final ValueChanged<String> onOpenFile;
  final Future<bool> Function(List<GitFileStatus> files) onConfirmDiscard;
  final Set<String> outsideWorkspacePaths;
  final bool Function(GitFileStatus file)? canOpenFile;

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
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: busyMarkSectionHeaderStyle(context),
            ),
          ),
          for (final file in files)
            _ChangedFileRow(
              file: file,
              kind: kind,
              status: _statusFor(file),
              selected: _selectionFor(file) == selectedChange,
              outsideWorkspace:
                  outsideWorkspacePaths.contains(file.repoRelativePath) ||
                  (_renamedForGroup(file) &&
                      file.originalRepoRelativePath != null &&
                      outsideWorkspacePaths.contains(
                        file.originalRepoRelativePath,
                      )),
              canOpen:
                  file.hasWorkingTreeFile && (canOpenFile?.call(file) ?? true),
              onSelect: () {
                if (kind == _ChangeGroupKind.conflicts) {
                  onOpenFile(file.repoRelativePath);
                } else {
                  onSelectFile(_selectionFor(file)!);
                }
              },
              onSelectionChanged: (selected) {
                final actions = GitFileActions.of(context);
                if (selected) {
                  actions.select(_pathsFor(file));
                } else {
                  actions.unselect(_pathsFor(file));
                }
              },
              onOpen: () => onOpenFile(file.repoRelativePath),
              onRollback: () async {
                final actions = GitFileActions.of(context);
                if (await onConfirmDiscard([file])) {
                  actions.rollback(_rollbackPathsFor(file));
                }
              },
              onDelete: () async {
                final actions = GitFileActions.of(context);
                if (await onConfirmDiscard([file])) {
                  actions.deleteUntracked([file.repoRelativePath]);
                }
              },
            ),
        ],
      ),
    );
  }

  GitChangeSelection? _selectionFor(GitFileStatus file) {
    final comparison = switch (kind) {
      _ChangeGroupKind.staged => GitComparisonType.staged,
      _ChangeGroupKind.unstaged => GitComparisonType.unstaged,
      _ChangeGroupKind.untracked => GitComparisonType.untracked,
      _ChangeGroupKind.conflicts => null,
    };
    return comparison == null
        ? null
        : GitChangeSelection(
            path: file.repoRelativePath,
            comparison: comparison,
            originalRepoRelativePath: _renamedForGroup(file)
                ? file.originalRepoRelativePath
                : null,
          );
  }

  List<String> _pathsFor(GitFileStatus file) {
    final originalPath = file.originalRepoRelativePath;
    return [
      if (_renamedForGroup(file) &&
          originalPath != null &&
          originalPath != file.repoRelativePath)
        originalPath,
      file.repoRelativePath,
    ];
  }

  List<String> _rollbackPathsFor(GitFileStatus file) {
    final originalPath = file.originalRepoRelativePath;
    return [
      if ((file.hasStagedRename || file.hasUnstagedRename) &&
          originalPath != null &&
          originalPath != file.repoRelativePath)
        originalPath,
      file.repoRelativePath,
    ];
  }

  bool _renamedForGroup(GitFileStatus file) {
    return switch (kind) {
      _ChangeGroupKind.staged => file.hasStagedRename,
      _ChangeGroupKind.unstaged => file.hasUnstagedRename,
      _ChangeGroupKind.conflicts || _ChangeGroupKind.untracked => false,
    };
  }

  GitFileChangeStatus _statusFor(GitFileStatus file) {
    return switch (kind) {
      _ChangeGroupKind.conflicts => GitFileChangeStatus.unmerged,
      _ChangeGroupKind.staged => file.indexStatus,
      _ChangeGroupKind.unstaged => file.workTreeStatus,
      _ChangeGroupKind.untracked => GitFileChangeStatus.untracked,
    };
  }
}

enum _ChangeGroupKind { conflicts, staged, unstaged, untracked }

class GitFileActions extends InheritedWidget {
  const GitFileActions({
    super.key,
    required this.select,
    required this.unselect,
    required this.rollback,
    required this.deleteUntracked,
    required super.child,
  });

  final void Function(List<String> paths) select;
  final void Function(List<String> paths) unselect;
  final void Function(List<String> paths) rollback;
  final void Function(List<String> paths) deleteUntracked;

  static GitFileActions of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<GitFileActions>()!;
  }

  @override
  bool updateShouldNotify(GitFileActions oldWidget) {
    return select != oldWidget.select ||
        unselect != oldWidget.unselect ||
        rollback != oldWidget.rollback ||
        deleteUntracked != oldWidget.deleteUntracked;
  }
}

class _ChangedFileRow extends StatelessWidget {
  const _ChangedFileRow({
    required this.file,
    required this.kind,
    required this.status,
    required this.selected,
    required this.outsideWorkspace,
    required this.canOpen,
    required this.onSelect,
    required this.onSelectionChanged,
    required this.onOpen,
    required this.onRollback,
    required this.onDelete,
  });

  final GitFileStatus file;
  final _ChangeGroupKind kind;
  final GitFileChangeStatus status;
  final bool selected;
  final bool outsideWorkspace;
  final bool canOpen;
  final VoidCallback onSelect;
  final ValueChanged<bool> onSelectionChanged;
  final VoidCallback onOpen;
  final VoidCallback onRollback;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final isGroupRename =
        status == GitFileChangeStatus.renamed &&
        file.originalRepoRelativePath != null &&
        file.originalRepoRelativePath != file.repoRelativePath;
    final displayPath = isGroupRename
        ? '${file.originalRepoRelativePath} → ${file.repoRelativePath}'
        : file.repoRelativePath;
    final directory = isGroupRename
        ? ''
        : _directoryLabel(file.repoRelativePath);
    final statusColor = busyMarkVcsFileStatusColor(
      context,
      busyMarkVcsFileColorForChangeStatus(status),
    );
    final canRollback =
        kind == _ChangeGroupKind.staged || kind == _ChangeGroupKind.unstaged;
    final canDelete = kind == _ChangeGroupKind.untracked;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BusyMarkStroke.hairline),
      child: Material(
        key: ValueKey('git-change-${kind.name}-${file.repoRelativePath}'),
        color: selected
            ? busyMarkSelectedBackground(context)
            : BusyMarkLinuxPalette.transparent,
        borderRadius: BorderRadius.circular(BusyMarkRadius.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          hoverColor: busyMarkRowHoverColor(context),
          onTap: kind != _ChangeGroupKind.conflicts || canOpen
              ? onSelect
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BusyMarkSpacing.sm,
              vertical: BusyMarkSpacing.xs,
            ),
            child: Row(
              children: [
                if (kind == _ChangeGroupKind.conflicts)
                  Icon(
                    BusyMarkGlyphs.warning,
                    size: BusyMarkSizes.iconSm,
                    color: statusColor,
                  )
                else
                  BusyMarkCheckbox(
                    value: kind == _ChangeGroupKind.staged,
                    tooltip: kind == _ChangeGroupKind.staged
                        ? context.l10n.gitRemoveFromCommit
                        : context.l10n.gitSelectForCommit,
                    onChanged: (value) {
                      if (kind == _ChangeGroupKind.staged && value == false) {
                        onSelectionChanged(false);
                      } else if (kind != _ChangeGroupKind.staged &&
                          value == true) {
                        onSelectionChanged(true);
                      }
                    },
                  ),
                const SizedBox(width: BusyMarkSpacing.xs),
                _StatusBadge(status: status, color: statusColor),
                const SizedBox(width: BusyMarkSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isGroupRename ? displayPath : _fileName(displayPath),
                        textDirection: TextDirection.ltr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: statusColor),
                      ),
                      if (directory.isNotEmpty)
                        Text(
                          directory,
                          textDirection: TextDirection.ltr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: colors.mutedForeground),
                        ),
                      if (outsideWorkspace)
                        Text(
                          context.l10n.gitOutsideWorkspace,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: colors.mutedForeground),
                        ),
                    ],
                  ),
                ),
                if (canOpen || canRollback || canDelete)
                  BusyMarkHeaderPopupMenuButton<_FileAction>(
                    tooltip: context.l10n.fileActions,
                    icon: BusyMarkGlyphs.menuHorizontal,
                    transparent: true,
                    itemBuilder: (context) => [
                      if (canOpen)
                        BusyMarkPopupMenuItem(
                          value: _FileAction.open,
                          label: context.l10n.gitOpenFile,
                          icon: BusyMarkGlyphs.externalLink,
                        ),
                      if (canRollback)
                        BusyMarkPopupMenuItem(
                          value: _FileAction.rollback,
                          label: context.l10n.gitDiscard,
                          icon: BusyMarkGlyphs.undo,
                        ),
                      if (canDelete)
                        BusyMarkPopupMenuItem(
                          value: _FileAction.delete,
                          label: context.l10n.delete,
                          icon: BusyMarkGlyphs.delete,
                        ),
                    ],
                    onSelected: (action) {
                      switch (action) {
                        case _FileAction.open:
                          onOpen();
                        case _FileAction.rollback:
                          onRollback();
                        case _FileAction.delete:
                          onDelete();
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

enum _FileAction { open, rollback, delete }

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.color});

  final GitFileChangeStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _statusLabel(context),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(BusyMarkRadius.sm),
          border: Border.all(color: color.withValues(alpha: 0.42)),
        ),
        child: SizedBox(
          width: 24,
          height: 22,
          child: Center(
            child: Text(
              _statusCode(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _statusCode() {
    return switch (status) {
      GitFileChangeStatus.added => 'A',
      GitFileChangeStatus.deleted => 'D',
      GitFileChangeStatus.renamed => 'R',
      GitFileChangeStatus.copied => 'C',
      GitFileChangeStatus.untracked => '?',
      GitFileChangeStatus.unmerged => '!',
      GitFileChangeStatus.ignored => 'I',
      GitFileChangeStatus.typeChanged => 'T',
      GitFileChangeStatus.unmodified ||
      GitFileChangeStatus.modified ||
      GitFileChangeStatus.unknown => 'M',
    };
  }

  String _statusLabel(BuildContext context) {
    return switch (status) {
      GitFileChangeStatus.added => context.l10n.gitStatusAdded,
      GitFileChangeStatus.deleted => context.l10n.gitStatusDeleted,
      GitFileChangeStatus.renamed => context.l10n.gitStatusRenamed,
      GitFileChangeStatus.copied => context.l10n.gitStatusCopied,
      GitFileChangeStatus.untracked => context.l10n.gitStatusUntracked,
      GitFileChangeStatus.unmerged => context.l10n.gitStatusConflicted,
      GitFileChangeStatus.ignored => context.l10n.gitStatusIgnored,
      GitFileChangeStatus.typeChanged => context.l10n.gitStatusTypeChanged,
      GitFileChangeStatus.unmodified ||
      GitFileChangeStatus.modified => context.l10n.gitStatusModified,
      GitFileChangeStatus.unknown => context.l10n.gitStatusUnknown,
    };
  }
}
