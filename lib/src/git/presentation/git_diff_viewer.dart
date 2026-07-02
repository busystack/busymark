import 'package:flutter/material.dart';

import '../../app/busymark_design.dart';
import '../../app/busymark_glyphs.dart';
import '../../app/localization.dart';
import '../domain/git_models.dart';

class GitDiffViewer extends StatelessWidget {
  const GitDiffViewer({
    super.key,
    required this.diff,
    required this.hasUnsavedEditorChanges,
    required this.onOpenFile,
    required this.onClose,
  });

  final GitDiff? diff;
  final bool hasUnsavedEditorChanges;
  final ValueChanged<String> onOpenFile;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final diff = this.diff;
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.view),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.headerbarFlat,
              border: Border(bottom: BorderSide(color: colors.subtleBorder)),
            ),
            child: SizedBox(
              height: BusyMarkSizes.paneHeaderHeight,
              child: Row(
                children: [
                  const SizedBox(width: BusyMarkSpacing.md),
                  Icon(
                    BusyMarkGlyphs.documentHistory,
                    size: BusyMarkSizes.iconSm,
                    color: colors.mutedForeground,
                  ),
                  const SizedBox(width: BusyMarkSpacing.sm),
                  Expanded(
                    child: Text(
                      diff?.title.isNotEmpty ?? false
                          ? diff!.title
                          : context.l10n.gitDiff,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  BusyMarkHeaderIconButton(
                    tooltip: context.l10n.close,
                    icon: BusyMarkGlyphs.clear,
                    transparent: true,
                    onPressed: onClose,
                  ),
                  const SizedBox(width: BusyMarkSpacing.xs),
                ],
              ),
            ),
          ),
          if (hasUnsavedEditorChanges)
            _DiffBanner(message: context.l10n.gitUnsavedChangesBanner),
          Expanded(
            child: diff == null || diff.files.isEmpty
                ? Center(child: Text(context.l10n.gitNoDiff))
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: BusyMarkSpacing.xl),
                    itemCount: diff.files.length,
                    itemBuilder: (context, index) {
                      return _DiffFileSection(
                        file: diff.files[index],
                        onOpenFile: onOpenFile,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _DiffBanner extends StatelessWidget {
  const _DiffBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.admonitionWarning,
        border: Border(bottom: BorderSide(color: colors.subtleBorder)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BusyMarkSpacing.lg,
          vertical: BusyMarkSpacing.sm,
        ),
        child: Row(
          children: [
            const Icon(BusyMarkGlyphs.warning, size: BusyMarkSizes.iconSm),
            const SizedBox(width: BusyMarkSpacing.sm),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _DiffFileSection extends StatelessWidget {
  const _DiffFileSection({required this.file, required this.onOpenFile});

  final GitDiffFile file;
  final ValueChanged<String> onOpenFile;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final path = file.newPath ?? file.oldPath ?? '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BusyMarkSpacing.lg,
        BusyMarkSpacing.lg,
        BusyMarkSpacing.lg,
        0,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.panel,
          borderRadius: BorderRadius.circular(BusyMarkRadius.md),
          border: Border.all(color: colors.subtleBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                BusyMarkSpacing.md,
                BusyMarkSpacing.sm,
                BusyMarkSpacing.xs,
                BusyMarkSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      path,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontFamily: BusyMarkTypography.monoFontFamily,
                      ),
                    ),
                  ),
                  Text(
                    context.l10n.gitAdditionsDeletions(
                      file.additions,
                      file.deletions,
                    ),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.mutedForeground,
                    ),
                  ),
                  const SizedBox(width: BusyMarkSpacing.xs),
                  BusyMarkHeaderIconButton(
                    tooltip: context.l10n.gitOpenFile,
                    icon: BusyMarkGlyphs.externalLink,
                    transparent: true,
                    onPressed: path.isEmpty ? null : () => onOpenFile(path),
                  ),
                ],
              ),
            ),
            Divider(
              height: BusyMarkStroke.hairline,
              thickness: BusyMarkStroke.hairline,
              color: colors.subtleBorder,
            ),
            if (file.binary)
              Padding(
                padding: const EdgeInsets.all(BusyMarkSpacing.md),
                child: Text(context.l10n.gitBinaryFile),
              )
            else
              for (final hunk in file.hunks) _DiffHunkView(hunk: hunk),
          ],
        ),
      ),
    );
  }
}

class _DiffHunkView extends StatelessWidget {
  const _DiffHunkView({required this.hunk});

  final GitDiffHunk hunk;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ColoredBox(
          color: colors.control,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BusyMarkSpacing.md,
              vertical: BusyMarkSpacing.xs,
            ),
            child: Text(
              '@@ -${hunk.oldStart},${hunk.oldCount} +${hunk.newStart},${hunk.newCount} @@ ${hunk.heading}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: BusyMarkTypography.monoFontFamily,
                color: colors.mutedForeground,
              ),
            ),
          ),
        ),
        for (final line in hunk.lines) _DiffLineView(line: line),
      ],
    );
  }
}

class _DiffLineView extends StatelessWidget {
  const _DiffLineView({required this.line});

  final GitDiffLine line;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final color = switch (line.kind) {
      GitDiffLineKind.added => colors.admonitionTip,
      GitDiffLineKind.removed => colors.admonitionWarning,
      GitDiffLineKind.context ||
      GitDiffLineKind.header => BusyMarkLinuxPalette.transparent,
    };
    final marker = switch (line.kind) {
      GitDiffLineKind.added => '+',
      GitDiffLineKind.removed => '-',
      GitDiffLineKind.context => ' ',
      GitDiffLineKind.header => '',
    };
    return ColoredBox(
      color: color,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: BusyMarkSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: BusyMarkSizes.sourceGutterWidth,
              child: Text(
                _lineNumberText(line),
                textAlign: TextAlign.right,
                style: _lineTextStyle(context, colors.mutedForeground),
              ),
            ),
            const SizedBox(width: BusyMarkSpacing.sm),
            SizedBox(
              width: 14,
              child: Text(marker, style: _lineTextStyle(context, colors.muted)),
            ),
            Expanded(
              child: SelectableText(
                line.content,
                style: _lineTextStyle(context, colors.foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _lineNumberText(GitDiffLine line) {
    final oldLine = line.oldLineNumber?.toString() ?? '';
    final newLine = line.newLineNumber?.toString() ?? '';
    if (oldLine.isEmpty && newLine.isEmpty) {
      return '';
    }
    return '$oldLine $newLine';
  }

  TextStyle? _lineTextStyle(BuildContext context, Color color) {
    return Theme.of(context).textTheme.bodySmall?.copyWith(
      color: color,
      fontFamily: BusyMarkTypography.monoFontFamily,
      height: BusyMarkTypography.codeLineHeight,
    );
  }
}
