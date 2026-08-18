import 'package:flutter/material.dart';
import 'package:yaru/yaru.dart';

import '../../app/busymark_design.dart';
import '../../app/busymark_glyphs.dart';
import '../../app/localization.dart';
import '../../editor/source/source_read_only_view.dart';
import '../../editor/source_language.dart';
import '../domain/git_models.dart';

class GitDiffViewer extends StatefulWidget {
  const GitDiffViewer({
    super.key,
    required this.diff,
    required this.hasUnsavedEditorChanges,
    required this.onOpenFile,
    required this.onClose,
    this.openFilePath,
    this.showHeader = true,
    this.showFileHeaders = true,
    this.showCloseButton = true,
    this.showFileActions = true,
    this.showHunkHeaders = true,
    this.editorFontSize = BusyMarkTypography.defaultFontSize,
    this.showChangeNavigator = false,
    this.changeNavigatorController,
  });

  final GitDiff? diff;
  final bool hasUnsavedEditorChanges;
  final ValueChanged<String> onOpenFile;
  final VoidCallback onClose;
  final String? openFilePath;
  final bool showHeader;
  final bool showFileHeaders;
  final bool showCloseButton;
  final bool showFileActions;
  final bool showHunkHeaders;
  final double editorFontSize;
  final bool showChangeNavigator;
  final GitDiffChangeNavigatorController? changeNavigatorController;

  @override
  State<GitDiffViewer> createState() => _GitDiffViewerState();
}

class GitDiffChangeNavigatorController {
  ValueChanged<int>? _onJumpToChange;

  void jumpToChange(int index) {
    _onJumpToChange?.call(index);
  }

  void _attach(ValueChanged<int> onJumpToChange) {
    _onJumpToChange = onJumpToChange;
  }

  void _detach(ValueChanged<int> onJumpToChange) {
    if (identical(_onJumpToChange, onJumpToChange)) {
      _onJumpToChange = null;
    }
  }
}

class _GitDiffViewerState extends State<GitDiffViewer> {
  final _scrollController = ScrollController();
  final _changeKeys = <int, GlobalKey>{};
  late final ValueChanged<int> _jumpToChangeIndexHandler;
  int _currentChangeIndex = 0;
  String? _initialScrollToken;

  @override
  void initState() {
    super.initState();
    _jumpToChangeIndexHandler = _jumpToChangeIndex;
    widget.changeNavigatorController?._attach(_jumpToChangeIndexHandler);
  }

  @override
  void didUpdateWidget(covariant GitDiffViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.changeNavigatorController !=
        widget.changeNavigatorController) {
      oldWidget.changeNavigatorController?._detach(_jumpToChangeIndexHandler);
      widget.changeNavigatorController?._attach(_jumpToChangeIndexHandler);
    }
  }

  @override
  void dispose() {
    widget.changeNavigatorController?._detach(_jumpToChangeIndexHandler);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final diff = widget.diff;
    final changeCount = gitDiffSourceChangeCount(diff);
    final changeNavigationEnabled =
        widget.showChangeNavigator || widget.changeNavigatorController != null;
    if (_currentChangeIndex >= changeCount) {
      _currentChangeIndex = 0;
    }
    if (diff != null && changeNavigationEnabled && changeCount > 0) {
      _scheduleInitialScroll(diff);
    }
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.view),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showHeader)
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
                    if (widget.showCloseButton) ...[
                      BusyMarkHeaderIconButton(
                        tooltip: context.l10n.close,
                        icon: BusyMarkGlyphs.clear,
                        transparent: true,
                        onPressed: widget.onClose,
                      ),
                      const SizedBox(width: BusyMarkSpacing.xs),
                    ] else
                      const SizedBox(width: BusyMarkSpacing.md),
                  ],
                ),
              ),
            ),
          if (widget.hasUnsavedEditorChanges)
            _DiffBanner(message: context.l10n.gitUnsavedChangesBanner),
          if (widget.showChangeNavigator && changeCount > 0)
            _SourceDiffChangeNavigator(
              currentIndex: _currentChangeIndex,
              total: changeCount,
              onPrevious: () => _jumpToChange(changeCount, -1),
              onNext: () => _jumpToChange(changeCount, 1),
            ),
          Expanded(
            child: diff == null || diff.files.isEmpty
                ? Center(child: Text(context.l10n.gitNoDiff))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: BusyMarkSpacing.xl),
                    itemCount: diff.files.length,
                    itemBuilder: (context, index) {
                      final file = diff.files[index];
                      return _DiffFileSection(
                        file: file,
                        snapshot: diff.fileSnapshots[file.displayPath],
                        changeIndexOffset: _changeIndexOffset(
                          diff.files,
                          index,
                        ),
                        changeKeys: changeNavigationEnabled
                            ? _changeKeys
                            : null,
                        openFilePath: widget.openFilePath,
                        onOpenFile: widget.onOpenFile,
                        showHeader: widget.showFileHeaders,
                        showActions: widget.showFileActions,
                        showHunkHeaders: widget.showHunkHeaders,
                        editorFontSize: widget.editorFontSize,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _jumpToChange(int changeCount, int direction) {
    if (changeCount == 0) {
      return;
    }
    final nextIndex =
        (_currentChangeIndex + direction + changeCount) % changeCount;
    _setCurrentChangeIndex(nextIndex);
  }

  void _jumpToChangeIndex(int index) {
    final changeCount = gitDiffSourceChangeCount(widget.diff);
    if (changeCount == 0) {
      return;
    }
    final nextIndex = index.clamp(0, changeCount - 1);
    _setCurrentChangeIndex(nextIndex);
  }

  void _setCurrentChangeIndex(int index) {
    setState(() {
      _currentChangeIndex = index;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _changeKeys[index]?.currentContext;
      if (context == null) {
        return;
      }
      Scrollable.ensureVisible(
        context,
        duration: BusyMarkMotion.scroll,
        curve: Curves.easeOutCubic,
        alignment: 0.12,
      );
    });
  }

  void _scheduleInitialScroll(GitDiff diff) {
    final token = gitDiffChangeNavigationToken(diff);
    if (_initialScrollToken == token) {
      return;
    }
    _initialScrollToken = token;
    _currentChangeIndex = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _initialScrollToken != token) {
        return;
      }
      _jumpToChangeIndex(0);
    });
  }
}

String gitDiffChangeNavigationToken(GitDiff diff, [Object? qualifier]) {
  final buffer = StringBuffer()
    ..write(qualifier)
    ..write('\u0000')
    ..write(diff.title)
    ..write('\u0000')
    ..write(diff.rawPatch.hashCode)
    ..write('\u0000')
    ..write(diff.files.length);
  for (final file in diff.files) {
    buffer
      ..write('\u0000')
      ..write(file.oldPath)
      ..write('>')
      ..write(file.newPath)
      ..write(':')
      ..write(file.hunks.length);
    for (final hunk in file.hunks) {
      buffer
        ..write(':')
        ..write(hunk.oldStart)
        ..write(',')
        ..write(hunk.oldCount)
        ..write('>')
        ..write(hunk.newStart)
        ..write(',')
        ..write(hunk.newCount);
    }
  }
  return buffer.toString();
}

int gitDiffSourceChangeCount(GitDiff? diff) {
  if (diff == null) {
    return 0;
  }
  return diff.files.fold<int>(0, (count, file) => count + file.hunks.length);
}

int _changeIndexOffset(List<GitDiffFile> files, int fileIndex) {
  var offset = 0;
  for (var index = 0; index < fileIndex; index += 1) {
    offset += files[index].hunks.length;
  }
  return offset;
}

class _SourceDiffChangeNavigator extends StatelessWidget {
  const _SourceDiffChangeNavigator({
    required this.currentIndex,
    required this.total,
    required this.onPrevious,
    required this.onNext,
  });

  final int currentIndex;
  final int total;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.headerbarFlat,
        border: Border(bottom: BorderSide(color: colors.subtleBorder)),
      ),
      child: SizedBox(
        height: BusyMarkSizes.paneHeaderHeight,
        child: Row(
          children: [
            const SizedBox(width: BusyMarkSpacing.md),
            Text(
              '${currentIndex + 1} / $total',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.mutedForeground,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const Spacer(),
            BusyMarkHeaderIconButton(
              tooltip: context.l10n.sourceSearchPreviousMatch,
              icon: YaruIcons.pan_up,
              transparent: true,
              onPressed: onPrevious,
            ),
            BusyMarkHeaderIconButton(
              tooltip: context.l10n.sourceSearchNextMatch,
              icon: BusyMarkGlyphs.downArrow,
              transparent: true,
              onPressed: onNext,
            ),
            const SizedBox(width: BusyMarkSpacing.xs),
          ],
        ),
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
  const _DiffFileSection({
    required this.file,
    required this.snapshot,
    required this.changeIndexOffset,
    required this.changeKeys,
    required this.openFilePath,
    required this.onOpenFile,
    required this.showHeader,
    required this.showActions,
    required this.showHunkHeaders,
    required this.editorFontSize,
  });

  final GitDiffFile file;
  final String? snapshot;
  final int changeIndexOffset;
  final Map<int, GlobalKey>? changeKeys;
  final String? openFilePath;
  final ValueChanged<String> onOpenFile;
  final bool showHeader;
  final bool showActions;
  final bool showHunkHeaders;
  final double editorFontSize;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final path = file.newPath ?? file.oldPath ?? '';
    final pathChanged =
        file.oldPath != null &&
        file.newPath != null &&
        file.oldPath != file.newPath;
    final pathLabel = pathChanged ? '${file.oldPath} → ${file.newPath}' : path;
    final showPathHeader = showHeader || pathChanged;
    final language = sourceSyntaxLanguageForPath(path);
    final sourceBody = file.binary
        ? Padding(
            padding: const EdgeInsets.all(BusyMarkSpacing.md),
            child: Text(
              file.binarySize == null
                  ? context.l10n.gitBinaryFile
                  : context.l10n.gitBinaryFileInfo(file.binarySize!),
            ),
          )
        : BusyMarkReadOnlySourceLines(
            language: language,
            textStyle: TextStyle(
              fontFamily: BusyMarkTypography.monoFontFamily,
              fontFamilyFallback: BusyMarkTypography.monoFontFamilyFallback,
              fontSize: editorFontSize,
              height: BusyMarkTypography.codeLineHeight,
              leadingDistribution: TextLeadingDistribution.even,
            ),
            padding: const EdgeInsets.only(
              bottom: BusyMarkSourceEditorMetrics.paddingBottom,
            ),
            lines: _diffSourceLines(
              file,
              snapshot,
              changeIndexOffset,
              showHunkHeaders: showHunkHeaders,
              formatHunkRange: context.l10n.gitDiffHunkRange,
              noLinesText: context.l10n.gitDiffNoLines,
            ),
            changeKeys: changeKeys,
          );
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.view),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showPathHeader) ...[
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
                          pathLabel,
                          textDirection: TextDirection.ltr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                fontFamily: BusyMarkTypography.monoFontFamily,
                                fontFamilyFallback:
                                    BusyMarkTypography.monoFontFamilyFallback,
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
                      if (showActions && openFilePath != null)
                        BusyMarkHeaderIconButton(
                          tooltip: context.l10n.gitOpenFile,
                          icon: BusyMarkGlyphs.externalLink,
                          transparent: true,
                          onPressed: () => onOpenFile(openFilePath!),
                        ),
                    ],
                  ),
                ),
                Divider(
                  height: BusyMarkStroke.hairline,
                  thickness: BusyMarkStroke.hairline,
                  color: colors.subtleBorder,
                ),
              ],
              sourceBody,
            ],
          ),
          if (!showPathHeader && showActions && openFilePath != null)
            Positioned(
              top: BusyMarkSpacing.xs,
              right: BusyMarkSpacing.xs,
              child: BusyMarkHeaderIconButton(
                tooltip: context.l10n.gitOpenFile,
                icon: BusyMarkGlyphs.externalLink,
                transparent: true,
                onPressed: () => onOpenFile(openFilePath!),
              ),
            ),
        ],
      ),
    );
  }
}

List<BusyMarkReadOnlySourceLine> _diffSourceLines(
  GitDiffFile file,
  String? snapshot,
  int changeIndexOffset, {
  required bool showHunkHeaders,
  required String Function(String oldRange, String newRange) formatHunkRange,
  required String noLinesText,
}) {
  if (snapshot == null) {
    return [
      for (final (index, hunk) in file.hunks.indexed)
        ..._diffHunkLines(
          hunk,
          changeIndexOffset + index,
          showHeader: showHunkHeaders,
          formatHunkRange: formatHunkRange,
          noLinesText: noLinesText,
        ),
    ];
  }
  return _fullFileUnifiedLines(file, snapshot, changeIndexOffset);
}

List<BusyMarkReadOnlySourceLine> _fullFileUnifiedLines(
  GitDiffFile file,
  String snapshot,
  int changeIndexOffset,
) {
  final snapshotLines = _sourceLines(snapshot);
  if (file.status == GitDiffFileStatus.deleted) {
    return [
      for (final (index, line) in snapshotLines.indexed)
        BusyMarkReadOnlySourceLine(
          text: line,
          oldLineNumber: index + 1,
          tone: BusyMarkReadOnlySourceLineTone.removed,
          changeTargetIndex: index == 0 ? changeIndexOffset : null,
        ),
    ];
  }
  if (file.status == GitDiffFileStatus.added) {
    return [
      for (final (index, line) in snapshotLines.indexed)
        BusyMarkReadOnlySourceLine(
          text: line,
          newLineNumber: index + 1,
          tone: BusyMarkReadOnlySourceLineTone.added,
          changeTargetIndex: index == 0 ? changeIndexOffset : null,
        ),
    ];
  }

  final removedBeforeNewLine = <int, List<_RemovedSourceLine>>{};
  final addedNewLines = <int, int>{};
  final explicitOldLineByNewLine = <int, int>{};

  for (final (hunkIndex, hunk) in file.hunks.indexed) {
    final pendingRemoved = <_RemovedSourceLine>[];

    void flushRemoved(int anchorNewLine) {
      if (pendingRemoved.isEmpty) {
        return;
      }
      removedBeforeNewLine
          .putIfAbsent(anchorNewLine, () => <_RemovedSourceLine>[])
          .addAll(pendingRemoved);
      pendingRemoved.clear();
    }

    for (final line in hunk.lines) {
      switch (line.kind) {
        case GitDiffLineKind.removed:
          pendingRemoved.add(
            _RemovedSourceLine(line, changeIndexOffset + hunkIndex),
          );
          break;
        case GitDiffLineKind.added:
          flushRemoved(line.newLineNumber ?? hunk.newStart);
          if (line.newLineNumber case final newLine?) {
            addedNewLines[newLine] = changeIndexOffset + hunkIndex;
          }
          break;
        case GitDiffLineKind.context:
          flushRemoved(line.newLineNumber ?? hunk.newStart);
          final oldLine = line.oldLineNumber;
          final newLine = line.newLineNumber;
          if (oldLine != null && newLine != null) {
            explicitOldLineByNewLine[newLine] = oldLine;
          }
          break;
        case GitDiffLineKind.header:
          break;
      }
    }
    flushRemoved(hunk.newStart + hunk.newCount);
  }

  final lines = <BusyMarkReadOnlySourceLine>[];
  for (final (index, line) in snapshotLines.indexed) {
    final newLine = index + 1;
    for (final removed
        in removedBeforeNewLine[newLine] ?? const <_RemovedSourceLine>[]) {
      lines.add(
        BusyMarkReadOnlySourceLine(
          text: removed.line.content,
          oldLineNumber: removed.line.oldLineNumber,
          tone: BusyMarkReadOnlySourceLineTone.removed,
          changeTargetIndex: removed.changeTargetIndex,
        ),
      );
    }
    final addedChangeIndex = addedNewLines[newLine];
    final added = addedChangeIndex != null;
    lines.add(
      BusyMarkReadOnlySourceLine(
        text: line,
        oldLineNumber: added
            ? null
            : explicitOldLineByNewLine[newLine] ??
                  _oldLineForNewLine(file.hunks, newLine),
        newLineNumber: newLine,
        tone: added
            ? BusyMarkReadOnlySourceLineTone.added
            : BusyMarkReadOnlySourceLineTone.normal,
        changeTargetIndex: addedChangeIndex,
      ),
    );
  }
  for (final removed
      in removedBeforeNewLine[snapshotLines.length + 1] ??
          const <_RemovedSourceLine>[]) {
    lines.add(
      BusyMarkReadOnlySourceLine(
        text: removed.line.content,
        oldLineNumber: removed.line.oldLineNumber,
        tone: BusyMarkReadOnlySourceLineTone.removed,
        changeTargetIndex: removed.changeTargetIndex,
      ),
    );
  }
  return lines;
}

class _RemovedSourceLine {
  const _RemovedSourceLine(this.line, this.changeTargetIndex);

  final GitDiffLine line;
  final int changeTargetIndex;
}

int _oldLineForNewLine(List<GitDiffHunk> hunks, int newLine) {
  var delta = 0;
  final sorted = [...hunks]..sort((a, b) => a.newStart.compareTo(b.newStart));
  for (final hunk in sorted) {
    if (newLine >= hunk.newStart + hunk.newCount) {
      delta += hunk.newCount - hunk.oldCount;
      continue;
    }
    break;
  }
  return newLine - delta;
}

List<String> _sourceLines(String source) {
  final lines = source.split('\n');
  if (lines.isNotEmpty && lines.last.isEmpty) {
    lines.removeLast();
  }
  return lines;
}

List<BusyMarkReadOnlySourceLine> _diffHunkLines(
  GitDiffHunk hunk,
  int changeTargetIndex, {
  required bool showHeader,
  required String Function(String oldRange, String newRange) formatHunkRange,
  required String noLinesText,
}) {
  var targetAssigned = false;
  int? lineTarget() {
    if (showHeader || targetAssigned) {
      return null;
    }
    targetAssigned = true;
    return changeTargetIndex;
  }

  return [
    if (showHeader)
      BusyMarkReadOnlySourceLine(
        text: gitDiffHunkRangeText(
          hunk,
          format: formatHunkRange,
          noLinesText: noLinesText,
        ),
        tone: BusyMarkReadOnlySourceLineTone.header,
        language: SourceSyntaxLanguage.plain,
        changeTargetIndex: changeTargetIndex,
      ),
    for (final line in hunk.lines)
      BusyMarkReadOnlySourceLine(
        text: line.content,
        oldLineNumber: line.oldLineNumber,
        newLineNumber: line.newLineNumber,
        tone: _diffLineTone(line.kind),
        changeTargetIndex: lineTarget(),
      ),
  ];
}

String gitDiffHunkRangeText(
  GitDiffHunk hunk, {
  required String Function(String oldRange, String newRange) format,
  required String noLinesText,
}) {
  final oldRange = _gitDiffLineRangeText(
    hunk.oldStart,
    hunk.oldCount,
    noLinesText,
  );
  final newRange = _gitDiffLineRangeText(
    hunk.newStart,
    hunk.newCount,
    noLinesText,
  );
  return format(oldRange, newRange);
}

String _gitDiffLineRangeText(int start, int count, String noLinesText) {
  if (count <= 0) {
    return noLinesText;
  }
  if (count == 1) {
    return '$start';
  }
  return '$start-${start + count - 1}';
}

BusyMarkReadOnlySourceLineTone _diffLineTone(GitDiffLineKind kind) {
  return switch (kind) {
    GitDiffLineKind.added => BusyMarkReadOnlySourceLineTone.added,
    GitDiffLineKind.removed => BusyMarkReadOnlySourceLineTone.removed,
    GitDiffLineKind.context ||
    GitDiffLineKind.header => BusyMarkReadOnlySourceLineTone.normal,
  };
}
