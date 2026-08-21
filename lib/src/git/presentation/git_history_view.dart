import 'package:flutter/material.dart';

import '../../app/busymark_design.dart';
import '../../app/busymark_glyphs.dart';
import '../../app/localization.dart';
import '../application/git_controller.dart';
import '../domain/git_models.dart';

class GitFileHistoryView extends StatelessWidget {
  const GitFileHistoryView({
    super.key,
    required this.state,
    required this.onSelectCommit,
    required this.onRestoreVersion,
    required this.onLoadMore,
  });

  final GitState state;
  final ValueChanged<String> onSelectCommit;
  final VoidCallback onRestoreVersion;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final history = state.fileHistory;
    if (state.scopedFilePath == null || history.currentPath == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(BusyMarkSpacing.lg),
          child: Text(
            context.l10n.gitFileHistoryRequiresOpenFile,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (history.entries.isEmpty) {
      return Center(child: Text(context.l10n.gitNoHistory));
    }
    return ListView(
      padding: BusyMarkInsets.sidebarList,
      children: [
        for (final entry in history.entries)
          _CommitRow(
            selected: entry.commit.fullHash == history.selectedCommitHash,
            shortHash: entry.commit.shortHash,
            subject: entry.commit.subject,
            authorName: entry.commit.authorName,
            date: entry.commit.authorDate,
            trailing: entry.commit.fullHash == history.selectedCommitHash
                ? _FileHistoryCommitMenu(
                    canRestore: entry.newPath != null,
                    onRestoreVersion: onRestoreVersion,
                  )
                : null,
            onTap: () => onSelectCommit(entry.commit.fullHash),
          ),
        if (history.hasMore)
          _LoadMoreButton(
            loading: history.isLoadingMore,
            onPressed: onLoadMore,
          ),
      ],
    );
  }
}

class GitProjectHistoryView extends StatelessWidget {
  const GitProjectHistoryView({
    super.key,
    required this.state,
    required this.onSelectCommit,
    required this.onShowFileDiff,
    required this.onResetCurrentBranch,
    required this.onLoadMore,
  });

  final GitState state;
  final ValueChanged<String> onSelectCommit;
  final ValueChanged<String> onShowFileDiff;
  final VoidCallback onResetCurrentBranch;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final project = state.projectHistory;
    final history = project.commits;
    return history.isEmpty
        ? Center(child: Text(context.l10n.gitNoHistory))
        : ListView(
            padding: BusyMarkInsets.sidebarList,
            children: [
              for (final commit in history) ...[
                Builder(
                  builder: (context) {
                    final selected =
                        commit.fullHash == project.selectedCommitHash;
                    final showFileMenu =
                        selected &&
                        (project.details?.changedFiles.isNotEmpty ?? false);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _CommitRow(
                          selected: selected,
                          shortHash: commit.shortHash,
                          subject: commit.subject,
                          authorName: commit.authorName,
                          date: commit.authorDate,
                          trailing: selected
                              ? _ProjectHistoryCommitMenu(
                                  canReset:
                                      state.repositoryInfo?.currentBranch !=
                                      null,
                                  onResetCurrentBranch: onResetCurrentBranch,
                                )
                              : null,
                          onTap: () => onSelectCommit(commit.fullHash),
                        ),
                        if (showFileMenu)
                          _CommitFileMenu(
                            files: project.details!.changedFiles,
                            selectedPath: project.selectedFilePath,
                            onShowFileDiff: onShowFileDiff,
                          ),
                      ],
                    );
                  },
                ),
              ],
              if (project.hasMore)
                _LoadMoreButton(
                  loading: project.isLoadingMore,
                  onPressed: onLoadMore,
                ),
            ],
          );
  }
}

enum _ProjectHistoryCommitAction { resetCurrentBranch }

class _ProjectHistoryCommitMenu extends StatelessWidget {
  const _ProjectHistoryCommitMenu({
    required this.canReset,
    required this.onResetCurrentBranch,
  });

  final bool canReset;
  final VoidCallback onResetCurrentBranch;

  @override
  Widget build(BuildContext context) {
    return BusyMarkHeaderPopupMenuButton<_ProjectHistoryCommitAction>(
      tooltip: context.l10n.gitCommitActions,
      icon: BusyMarkGlyphs.menuHorizontal,
      transparent: true,
      itemBuilder: (context) => [
        BusyMarkPopupMenuItem(
          value: _ProjectHistoryCommitAction.resetCurrentBranch,
          label: context.l10n.gitResetCurrentBranchToHere,
          icon: BusyMarkGlyphs.undo,
          enabled: canReset,
        ),
      ],
      onSelected: (action) {
        switch (action) {
          case _ProjectHistoryCommitAction.resetCurrentBranch:
            onResetCurrentBranch();
        }
      },
    );
  }
}

enum _FileHistoryCommitAction { restoreVersion }

class _FileHistoryCommitMenu extends StatelessWidget {
  const _FileHistoryCommitMenu({
    required this.canRestore,
    required this.onRestoreVersion,
  });

  final bool canRestore;
  final VoidCallback onRestoreVersion;

  @override
  Widget build(BuildContext context) {
    return BusyMarkHeaderPopupMenuButton<_FileHistoryCommitAction>(
      tooltip: context.l10n.fileActions,
      icon: BusyMarkGlyphs.menuHorizontal,
      transparent: true,
      itemBuilder: (context) => [
        BusyMarkPopupMenuItem(
          value: _FileHistoryCommitAction.restoreVersion,
          label: context.l10n.gitRestoreVersion,
          icon: BusyMarkGlyphs.undo,
          enabled: canRestore,
        ),
      ],
      onSelected: (action) {
        switch (action) {
          case _FileHistoryCommitAction.restoreVersion:
            onRestoreVersion();
        }
      },
    );
  }
}

class _LoadMoreButton extends StatelessWidget {
  const _LoadMoreButton({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(BusyMarkSpacing.sm),
      child: BusyMarkPushButton.standard(
        onPressed: loading ? null : onPressed,
        child: Text(context.l10n.gitLoadMore),
      ),
    );
  }
}

enum _CommitFileAction { showDiff }

Future<_CommitFileAction?> _showCommitFileMenu(
  BuildContext context,
  Offset position,
) {
  return showBusyMarkContextMenu<_CommitFileAction>(
    context,
    position,
    items: [
      BusyMarkPopupMenuItem(
        value: _CommitFileAction.showDiff,
        label: context.l10n.gitShowDiff,
        icon: BusyMarkGlyphs.preview,
      ),
    ],
  );
}

class _CommitFileMenu extends StatelessWidget {
  const _CommitFileMenu({
    required this.files,
    required this.selectedPath,
    required this.onShowFileDiff,
  });

  final List<GitDiffFile> files;
  final String? selectedPath;
  final ValueChanged<String> onShowFileDiff;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: BusyMarkSpacing.lg,
        bottom: BusyMarkSpacing.xs,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: BorderDirectional(
            start: BorderSide(color: colors.subtleBorder),
          ),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: BusyMarkSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final file in files)
                _CommitFileRow(
                  file: file,
                  selected:
                      selectedPath != null && file.matchesPath(selectedPath!),
                  onShowDiff: () {
                    final path = file.displayPath;
                    if (path.isNotEmpty) {
                      onShowFileDiff(path);
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommitFileRow extends StatelessWidget {
  const _CommitFileRow({
    required this.file,
    required this.selected,
    required this.onShowDiff,
  });

  final GitDiffFile file;
  final bool selected;
  final VoidCallback onShowDiff;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final path = file.displayPath;
    final pathLabel =
        file.oldPath != null &&
            file.newPath != null &&
            file.oldPath != file.newPath
        ? '${file.oldPath} → ${file.newPath}'
        : path;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BusyMarkStroke.hairline),
      child: Material(
        color: selected
            ? busyMarkSelectedBackground(context)
            : BusyMarkLinuxPalette.transparent,
        borderRadius: BorderRadius.circular(BusyMarkRadius.sm),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          hoverColor: busyMarkRowHoverColor(context),
          onTap: path.isEmpty ? null : onShowDiff,
          onSecondaryTapUp: path.isEmpty
              ? null
              : (details) async {
                  final action = await _showCommitFileMenu(
                    context,
                    details.globalPosition,
                  );
                  if (action == _CommitFileAction.showDiff) {
                    onShowDiff();
                  }
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BusyMarkSpacing.sm,
              vertical: BusyMarkSpacing.xs,
            ),
            child: Row(
              children: [
                Icon(
                  BusyMarkGlyphs.document,
                  size: BusyMarkSizes.iconSm,
                  color: colors.mutedForeground,
                ),
                const SizedBox(width: BusyMarkSpacing.xs),
                Expanded(
                  child: Text(
                    pathLabel,
                    textDirection: TextDirection.ltr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: BusyMarkTypography.monoFontFamily,
                      fontFamilyFallback:
                          BusyMarkTypography.monoFontFamilyFallback,
                    ),
                  ),
                ),
                const SizedBox(width: BusyMarkSpacing.xs),
                Text(
                  context.l10n.gitAdditionsDeletions(
                    file.additions,
                    file.deletions,
                  ),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CommitRow extends StatelessWidget {
  const _CommitRow({
    required this.selected,
    required this.shortHash,
    required this.subject,
    required this.authorName,
    required this.date,
    required this.onTap,
    this.trailing,
  });

  final bool selected;
  final String shortHash;
  final String subject;
  final String authorName;
  final DateTime date;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
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
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(BusyMarkSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: BusyMarkSpacing.xs),
                      Text(
                        '${busyMarkLtrIsolateFor(context, shortHash)} - '
                        '${busyMarkBidiIsolateFor(context, authorName)} - '
                        '${busyMarkBidiIsolateFor(context, MaterialLocalizations.of(context).formatShortDate(date.toLocal()))}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.mutedForeground,
                          fontFamily: BusyMarkTypography.monoFontFamily,
                          fontFamilyFallback:
                              BusyMarkTypography.monoFontFamilyFallback,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: BusyMarkSpacing.xs),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
