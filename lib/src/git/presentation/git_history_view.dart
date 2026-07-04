import 'package:flutter/material.dart';

import '../../app/busymark_design.dart';
import '../../app/busymark_glyphs.dart';
import '../../app/localization.dart';
import '../application/git_controller.dart';

class GitHistoryView extends StatelessWidget {
  const GitHistoryView({
    super.key,
    required this.state,
    required this.onLoadProjectHistory,
    required this.onLoadFileHistory,
    required this.onSelectCommit,
  });

  final GitState state;
  final VoidCallback onLoadProjectHistory;
  final VoidCallback onLoadFileHistory;
  final ValueChanged<String> onSelectCommit;

  @override
  Widget build(BuildContext context) {
    final history = state.history;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            BusyMarkSpacing.sm,
            BusyMarkSpacing.sm,
            BusyMarkSpacing.sm,
            BusyMarkSpacing.xs,
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onLoadProjectHistory,
                  icon: const Icon(BusyMarkGlyphs.history),
                  label: Text(
                    context.l10n.gitProjectHistory,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: BusyMarkSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: state.scopedFilePath == null
                      ? null
                      : onLoadFileHistory,
                  icon: const Icon(BusyMarkGlyphs.documentHistory),
                  label: Text(
                    context.l10n.gitFileHistory,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: history.isEmpty
              ? Center(child: Text(context.l10n.gitNoHistory))
              : ListView.builder(
                  padding: BusyMarkInsets.sidebarList,
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final commit = history[index];
                    return _CommitRow(
                      selected: commit.fullHash == state.selectedCommitHash,
                      shortHash: commit.shortHash,
                      subject: commit.subject,
                      authorName: commit.authorName,
                      date: commit.authorDate,
                      onTap: () => onSelectCommit(commit.fullHash),
                    );
                  },
                ),
        ),
      ],
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
