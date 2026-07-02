import 'package:flutter/material.dart';

import '../../app/busymark_design.dart';
import '../../app/busymark_glyphs.dart';
import '../../app/localization.dart';
import '../application/git_controller.dart';
import '../domain/git_models.dart';

class GitChangesView extends StatefulWidget {
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
  State<GitChangesView> createState() => _GitChangesViewState();
}

class _GitChangesViewState extends State<GitChangesView> {
  late final TextEditingController _commitMessageController;
  var _committing = false;

  @override
  void initState() {
    super.initState();
    _commitMessageController = TextEditingController()
      ..addListener(_handleCommitMessageChanged);
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
    if (snapshot.clean) {
      return Center(child: Text(context.l10n.gitClean));
    }
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: BusyMarkInsets.sidebarList,
            children: [
              _ChangeGroup(
                title: context.l10n.gitConflicts,
                files: snapshot.conflictedFiles,
                selectedPath: widget.state.selectedFilePath,
                onSelectFile: widget.onSelectFile,
                onOpenFile: widget.onOpenFile,
                onConfirmDiscard: widget.onConfirmDiscard,
              ),
              _ChangeGroup(
                title: context.l10n.gitStaged,
                files: snapshot.stagedFiles,
                selectedPath: widget.state.selectedFilePath,
                onSelectFile: widget.onSelectFile,
                onOpenFile: widget.onOpenFile,
                onConfirmDiscard: widget.onConfirmDiscard,
              ),
              _ChangeGroup(
                title: context.l10n.gitChanges,
                files: snapshot.unstagedFiles,
                selectedPath: widget.state.selectedFilePath,
                onSelectFile: widget.onSelectFile,
                onOpenFile: widget.onOpenFile,
                onConfirmDiscard: widget.onConfirmDiscard,
              ),
              _ChangeGroup(
                title: context.l10n.gitUntracked,
                files: snapshot.untrackedFiles,
                selectedPath: widget.state.selectedFilePath,
                onSelectFile: widget.onSelectFile,
                onOpenFile: widget.onOpenFile,
                onConfirmDiscard: widget.onConfirmDiscard,
              ),
              const SizedBox(height: BusyMarkSpacing.xl),
            ],
          ),
        ),
        _CommitPanel(
          controller: _commitMessageController,
          stagedFiles: snapshot.stagedFiles,
          committing: _committing,
          onCommit: _commit,
        ),
      ],
    );
  }

  Future<void> _commit() async {
    if (_committing ||
        _commitMessageController.text.trim().isEmpty ||
        (widget.state.statusSnapshot?.stagedFiles.isEmpty ?? true)) {
      return;
    }
    setState(() => _committing = true);
    try {
      await GitCommitActions.of(context).commit(_commitMessageController.text);
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
  });

  final TextEditingController controller;
  final List<GitFileStatus> stagedFiles;
  final bool committing;
  final Future<void> Function() onCommit;

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
            const SizedBox(height: BusyMarkSpacing.sm),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.control,
                borderRadius: BorderRadius.circular(BusyMarkRadius.md),
                border: Border.all(color: colors.subtleBorder),
              ),
              child: TextField(
                controller: controller,
                minLines: 3,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.all(BusyMarkSpacing.sm),
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: BusyMarkSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    stagedFiles.isEmpty
                        ? context.l10n.gitCommitNoStagedFiles
                        : context.l10n.gitCommitStagedFiles,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.mutedForeground,
                    ),
                  ),
                ),
                const SizedBox(width: BusyMarkSpacing.sm),
                BusyMarkDialogButton(
                  label: context.l10n.gitCommit,
                  suggested: true,
                  onPressed: canCommit ? () => onCommit() : null,
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
