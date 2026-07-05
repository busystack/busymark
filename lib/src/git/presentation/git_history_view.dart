import 'package:flutter/material.dart';

import '../../app/busymark_design.dart';
import '../../app/busymark_glyphs.dart';
import '../../app/localization.dart';
import '../application/git_controller.dart';
import '../domain/git_models.dart';

class GitHistoryView extends StatelessWidget {
  const GitHistoryView({
    super.key,
    required this.state,
    required this.onSelectCommit,
    required this.onShowFileDiff,
  });

  final GitState state;
  final ValueChanged<String> onSelectCommit;
  final ValueChanged<String> onShowFileDiff;

  @override
  Widget build(BuildContext context) {
    final history = state.history;
    return history.isEmpty
        ? Center(child: Text(context.l10n.gitNoHistory))
        : ListView.builder(
            padding: BusyMarkInsets.sidebarList,
            itemCount: history.length,
            itemBuilder: (context, index) {
              final commit = history[index];
              final selected = commit.fullHash == state.selectedCommitHash;
              final showFileMenu =
                  selected &&
                  state.historyFilePath == null &&
                  (state.selectedDiff?.files.isNotEmpty ?? false);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CommitRow(
                    selected: selected,
                    shortHash: commit.shortHash,
                    subject: commit.subject,
                    authorName: commit.authorName,
                    date: commit.authorDate,
                    onTap: () => onSelectCommit(commit.fullHash),
                  ),
                  if (showFileMenu)
                    _CommitFileMenu(
                      files: state.selectedDiff!.files,
                      selectedPath: state.selectedCommitFilePath,
                      onShowFileDiff: onShowFileDiff,
                    ),
                ],
              );
            },
          );
  }
}

enum _CommitFileAction { showDiff }

const _showDiffLabel = 'Show diff';

Future<_CommitFileAction?> _showCommitFileMenu(
  BuildContext context,
  Offset position,
) {
  final navigator = Navigator.of(context, rootNavigator: true);
  final overlay = navigator.overlay?.context.findRenderObject();
  if (overlay is! RenderBox) {
    return Future.value(null);
  }
  final theme = Theme.of(context);
  final colors = BusyMarkSurfaceColors.of(context);
  final popupTheme = theme.popupMenuTheme;
  return showMenu<_CommitFileAction>(
    context: context,
    useRootNavigator: true,
    position: RelativeRect.fromLTRB(
      position.dx,
      position.dy,
      overlay.size.width - position.dx,
      overlay.size.height - position.dy,
    ),
    items: const [
      BusyMarkPopupMenuItem(
        value: _CommitFileAction.showDiff,
        label: _showDiffLabel,
        icon: BusyMarkGlyphs.preview,
      ),
    ],
    color: popupTheme.color ?? colors.popover,
    surfaceTintColor: BusyMarkLinuxPalette.transparent,
    elevation: BusyMarkElevation.popover,
    shadowColor: colors.shade,
    constraints: const BoxConstraints.tightFor(
      width: BusyMarkSizes.popupMenuMinWidth,
    ),
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
          onSecondaryTapDown: path.isEmpty
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
                    path,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: BusyMarkTypography.monoFontFamily,
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
  });

  final bool selected;
  final String shortHash;
  final String subject;
  final String authorName;
  final DateTime date;
  final VoidCallback onTap;

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
                  '$shortHash - $authorName - ${MaterialLocalizations.of(context).formatShortDate(date.toLocal())}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.mutedForeground,
                    fontFamily: BusyMarkTypography.monoFontFamily,
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
