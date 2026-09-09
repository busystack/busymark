import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../app/busymark_dialogs.dart';
import '../app/busymark_design.dart';
import '../app/busymark_glyphs.dart';
import '../app/localization.dart';
import '../comparison/source_comparison.dart';
import '../workspace/document_buffer.dart';
import '../workspace/workspace_controller.dart';
import '../workspace/workspace_safety.dart';
import 'local_history_controller.dart';
import 'local_history_models.dart';

typedef LocalHistoryComparisonComputer =
    Future<SourceComparison> Function(
      SourceComparisonInput oldInput,
      SourceComparisonInput currentInput,
    );

final localHistoryComparisonComputerProvider =
    Provider<LocalHistoryComparisonComputer>(
      (ref) =>
          (oldInput, currentInput) => Future<SourceComparison>(
            () => compareSource(oldInput, currentInput),
          ),
    );

class LocalHistoryComparisonView extends ConsumerStatefulWidget {
  const LocalHistoryComparisonView({super.key});

  @override
  ConsumerState<LocalHistoryComparisonView> createState() =>
      _LocalHistoryComparisonViewState();
}

class _LocalHistoryComparisonViewState
    extends ConsumerState<LocalHistoryComparisonView> {
  Future<_ComparisonSnapshot?>? _future;
  _ComparisonRequest? _request;

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(localHistoryControllerProvider);
    ref.watch(workspaceControllerProvider);
    final document = history.selectedDocument;
    final revision = history.selectedRevision;
    if (document == null ||
        revision == null ||
        revision.summary.documentId != document.id) {
      return const SizedBox.shrink();
    }
    final matchingBuffer = ref
        .read(workspaceControllerProvider.notifier)
        .localHistoryBufferForDocument(document, revision);
    final request = _ComparisonRequest(
      documentId: document.id,
      revisionId: revision.summary.id,
      revisionVersion: revision.summary.capturedAt.microsecondsSinceEpoch,
      currentBufferId: matchingBuffer?.id,
      currentSourceVersion: matchingBuffer?.revision,
      currentPath: document.currentPath,
    );
    if (_request != request) {
      _request = request;
      _future = _buildSnapshot(document, revision, request);
    }
    return FutureBuilder<_ComparisonSnapshot?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(BusyMarkSpacing.lg),
              child: Text(snapshot.error.toString()),
            ),
          );
        }
        final data = snapshot.data;
        if (data == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final actionsAreCurrent =
            snapshot.connectionState == ConnectionState.done &&
            data.matches(
              request: request,
              revision: revision,
              currentBuffer: matchingBuffer,
            );
        return _ComparisonBody(
          snapshot: data,
          onClose: () => ref
              .read(localHistoryControllerProvider.notifier)
              .clearComparison(),
          onRestoreAll: actionsAreCurrent && data.canRestore
              ? () => _restore(document, revision)
              : null,
          onRestoreChange: actionsAreCurrent && data.canRestoreChange
              ? (change) => _restore(
                  document,
                  revision,
                  comparison: data.comparison,
                  change: change,
                )
              : null,
          onRestoreOriginal:
              actionsAreCurrent &&
                  data.missing &&
                  (document.currentPath ?? revision.summary.historicalPath) !=
                      null
              ? () => _restoreMissing(
                  document,
                  revision,
                  document.currentPath ?? revision.summary.historicalPath!,
                )
              : null,
          onRestoreNewLocation: actionsAreCurrent && data.missing
              ? () => _chooseRestoreLocation(document, revision)
              : null,
        );
      },
    );
  }

  Future<_ComparisonSnapshot?> _buildSnapshot(
    LocalHistoryDocument document,
    LocalHistoryRevision revision,
    _ComparisonRequest request,
  ) async {
    final editorLabel = context.l10n.localHistoryCurrentEditor;
    final diskLabel = context.l10n.localHistoryCurrentDisk;
    final missingLabel = context.l10n.localHistoryMissingFile;
    final revisionLabel = _revisionLabel(context, revision.summary);
    final current = await ref
        .read(workspaceControllerProvider.notifier)
        .localHistoryCurrentSource(document, revision);
    final currentLabel = switch (current.kind) {
      LocalHistoryCurrentSourceKind.editor => editorLabel,
      LocalHistoryCurrentSourceKind.disk => diskLabel,
      LocalHistoryCurrentSourceKind.missing => missingLabel,
    };
    if (!mounted) return null;
    final oldInput = SourceComparisonInput(
      id: revision.summary.id,
      version: revision.summary.capturedAt.microsecondsSinceEpoch,
      label: revisionLabel,
      source: revision.source,
    );
    final currentInput = SourceComparisonInput(
      id: current.id,
      version: current.version,
      label: currentLabel,
      source: current.source,
    );
    final comparison = await ref.read(localHistoryComparisonComputerProvider)(
      oldInput,
      currentInput,
    );
    return _ComparisonSnapshot(
      request: request,
      comparison: comparison,
      missing: current.kind == LocalHistoryCurrentSourceKind.missing,
      canRestore: current.canRestore,
      canRestoreChange:
          current.kind == LocalHistoryCurrentSourceKind.editor &&
          current.canRestore,
    );
  }

  Future<void> _restore(
    LocalHistoryDocument document,
    LocalHistoryRevision revision, {
    SourceComparison? comparison,
    SourceComparisonChange? change,
  }) async {
    await ref
        .read(workspaceControllerProvider.notifier)
        .restoreLocalHistoryRevision(
          document: document,
          revision: revision,
          comparison: comparison,
          change: change,
        );
  }

  Future<void> _chooseRestoreLocation(
    LocalHistoryDocument document,
    LocalHistoryRevision revision,
  ) async {
    final historicalPath =
        document.currentPath ?? revision.summary.historicalPath;
    final extension = p.extension(historicalPath ?? '');
    final location = await getSaveLocation(
      acceptedTypeGroups: [
        XTypeGroup(
          label: context.l10n.source,
          extensions: extension.isEmpty ? null : [extension.substring(1)],
          mimeTypes: extension.isEmpty ? const ['text/plain'] : null,
        ),
      ],
      suggestedName: p.basename(historicalPath ?? document.displayName),
      initialDirectory: historicalPath == null
          ? null
          : p.dirname(historicalPath),
      confirmButtonText: context.l10n.localHistoryRestoreRevision,
    );
    if (location != null && mounted) {
      await _restoreMissing(document, revision, location.path);
    }
  }

  Future<void> _restoreMissing(
    LocalHistoryDocument document,
    LocalHistoryRevision revision,
    String path,
  ) async {
    if (!await confirmSafeToContinue(context, ref) || !mounted) return;
    final controller = ref.read(workspaceControllerProvider.notifier);
    final exists = await controller.localHistoryRestorePathExists(path);
    if (!mounted) return;
    var overwrite = false;
    if (exists) {
      overwrite =
          await showBusyMarkModalDialog<bool>(
            context,
            barrierDismissible: false,
            builder: (dialogContext) => BusyMarkDialogShell(
              title: dialogContext.l10n.overwrite,
              actions: [
                BusyMarkDialogButton(
                  label: dialogContext.l10n.cancel,
                  onPressed: () => Navigator.pop(dialogContext, false),
                ),
                BusyMarkDialogButton(
                  label: dialogContext.l10n.overwrite,
                  destructive: true,
                  onPressed: () => Navigator.pop(dialogContext, true),
                ),
              ],
              children: [Text(dialogContext.l10n.errorPathAlreadyExists(path))],
            ),
          ) ??
          false;
      if (!overwrite || !mounted) return;
    }
    await controller.restoreMissingLocalHistoryRevision(
      document: document,
      revision: revision,
      destinationPath: path,
      overwriteExisting: overwrite,
    );
  }
}

class _ComparisonRequest {
  const _ComparisonRequest({
    required this.documentId,
    required this.revisionId,
    required this.revisionVersion,
    required this.currentBufferId,
    required this.currentSourceVersion,
    required this.currentPath,
  });

  final String documentId;
  final String revisionId;
  final int revisionVersion;
  final String? currentBufferId;
  final int? currentSourceVersion;
  final String? currentPath;

  @override
  bool operator ==(Object other) =>
      other is _ComparisonRequest &&
      other.documentId == documentId &&
      other.revisionId == revisionId &&
      other.revisionVersion == revisionVersion &&
      other.currentBufferId == currentBufferId &&
      other.currentSourceVersion == currentSourceVersion &&
      other.currentPath == currentPath;

  @override
  int get hashCode => Object.hash(
    documentId,
    revisionId,
    revisionVersion,
    currentBufferId,
    currentSourceVersion,
    currentPath,
  );
}

class _ComparisonSnapshot {
  const _ComparisonSnapshot({
    required this.request,
    required this.comparison,
    required this.missing,
    required this.canRestore,
    required this.canRestoreChange,
  });

  final _ComparisonRequest request;
  final SourceComparison comparison;
  final bool missing;
  final bool canRestore;
  final bool canRestoreChange;

  bool matches({
    required _ComparisonRequest request,
    required LocalHistoryRevision revision,
    required DocumentBuffer? currentBuffer,
  }) {
    if (this.request != request ||
        comparison.oldInput.id != revision.summary.id ||
        comparison.oldInput.version !=
            revision.summary.capturedAt.microsecondsSinceEpoch) {
      return false;
    }
    if (currentBuffer == null) return request.currentBufferId == null;
    return comparison.currentInput.id == currentBuffer.id &&
        comparison.currentInput.version == currentBuffer.revision;
  }
}

class _ComparisonBody extends StatelessWidget {
  const _ComparisonBody({
    required this.snapshot,
    required this.onClose,
    required this.onRestoreAll,
    required this.onRestoreChange,
    required this.onRestoreOriginal,
    required this.onRestoreNewLocation,
  });

  final _ComparisonSnapshot snapshot;
  final VoidCallback onClose;
  final VoidCallback? onRestoreAll;
  final ValueChanged<SourceComparisonChange>? onRestoreChange;
  final VoidCallback? onRestoreOriginal;
  final VoidCallback? onRestoreNewLocation;

  @override
  Widget build(BuildContext context) {
    final comparison = snapshot.comparison;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: BusyMarkSurfaceColors.of(context).headerbarFlat,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BusyMarkSpacing.md,
              vertical: BusyMarkSpacing.sm,
            ),
            child: Row(
              children: [
                const Icon(BusyMarkGlyphs.documentHistory),
                const SizedBox(width: BusyMarkSpacing.sm),
                Expanded(
                  child: Text(
                    comparison.oldInput.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.localHistoryRestoreRevision,
                  onPressed: onRestoreAll,
                  icon: const Icon(BusyMarkGlyphs.history),
                ),
                IconButton(
                  tooltip: context.l10n.close,
                  onPressed: onClose,
                  icon: const Icon(BusyMarkGlyphs.windowClose),
                ),
              ],
            ),
          ),
        ),
        if (snapshot.missing)
          _ComparisonNotice(
            text: context.l10n.localHistoryMissingFile,
            actions: [
              if (onRestoreOriginal != null)
                OutlinedButton(
                  onPressed: onRestoreOriginal,
                  child: Text(context.l10n.localHistoryRestoreOriginalLocation),
                ),
              if (onRestoreNewLocation != null)
                OutlinedButton(
                  onPressed: onRestoreNewLocation,
                  child: Text(context.l10n.localHistoryRestoreNewLocation),
                ),
            ],
          ),
        if (comparison.simplified)
          _ComparisonNotice(
            text: context.l10n.localHistoryComparisonSimplified,
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 900) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _SourcePane(
                        label: comparison.oldInput.label,
                        source: comparison.oldInput.source,
                        changes: comparison.changes,
                        removed: true,
                      ),
                    ),
                    VerticalDivider(
                      width: 1,
                      color: BusyMarkSurfaceColors.of(context).subtleBorder,
                    ),
                    Expanded(
                      child: _SourcePane(
                        label: comparison.currentInput.label,
                        source: comparison.currentInput.source,
                        changes: comparison.changes,
                        removed: false,
                      ),
                    ),
                  ],
                );
              }
              return _UnifiedComparisonPane(comparison: comparison);
            },
          ),
        ),
        if (comparison.changes.isNotEmpty)
          SizedBox(
            height: 54,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(BusyMarkSpacing.sm),
              itemCount: comparison.changes.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: BusyMarkSpacing.sm),
              itemBuilder: (context, index) {
                final change = comparison.changes[index];
                return OutlinedButton.icon(
                  onPressed: change.exact && onRestoreChange != null
                      ? () => onRestoreChange!(change)
                      : null,
                  icon: const Icon(BusyMarkGlyphs.undo, size: 16),
                  label: Text(
                    '${context.l10n.localHistoryRestoreChange} ${index + 1}',
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _UnifiedComparisonPane extends StatelessWidget {
  const _UnifiedComparisonPane({required this.comparison});

  final SourceComparison comparison;

  @override
  Widget build(BuildContext context) {
    final changes = [...comparison.changes]
      ..sort((a, b) => a.currentRange.start.compareTo(b.currentRange.start));
    final rows = <Widget>[];
    var currentOffset = 0;
    for (final change in changes) {
      final unchangedEnd = change.currentRange.start.clamp(
        currentOffset,
        comparison.currentInput.source.length,
      );
      if (unchangedEnd > currentOffset) {
        rows.add(
          _UnifiedSourceChunk(
            source: comparison.currentInput.source.substring(
              currentOffset,
              unchangedEnd,
            ),
          ),
        );
      }
      if (change.oldText.isNotEmpty) {
        rows.add(
          _UnifiedSourceChunk(
            marker: '−',
            label: comparison.oldInput.label,
            source: change.oldText,
            background: Theme.of(context).colorScheme.errorContainer,
            emphasis: Theme.of(
              context,
            ).colorScheme.error.withValues(alpha: 0.32),
            intraline: change.oldIntralineRange,
          ),
        );
      }
      if (change.currentText.isNotEmpty) {
        rows.add(
          _UnifiedSourceChunk(
            marker: '+',
            label: comparison.currentInput.label,
            source: change.currentText,
            background: Theme.of(context).colorScheme.primaryContainer,
            emphasis: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.32),
            intraline: change.currentIntralineRange,
          ),
        );
      }
      currentOffset = change.currentRange.end.clamp(
        currentOffset,
        comparison.currentInput.source.length,
      );
    }
    if (currentOffset < comparison.currentInput.source.length) {
      rows.add(
        _UnifiedSourceChunk(
          source: comparison.currentInput.source.substring(currentOffset),
        ),
      );
    }
    if (rows.isEmpty) {
      rows.add(_UnifiedSourceChunk(source: comparison.currentInput.source));
    }
    return ListView(
      padding: const EdgeInsets.all(BusyMarkSpacing.md),
      children: rows,
    );
  }
}

class _UnifiedSourceChunk extends StatelessWidget {
  const _UnifiedSourceChunk({
    required this.source,
    this.marker,
    this.label,
    this.background,
    this.emphasis,
    this.intraline = const SourceComparisonRange(0, 0),
  });

  final String source;
  final String? marker;
  final String? label;
  final Color? background;
  final Color? emphasis;
  final SourceComparisonRange intraline;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace');
    final start = intraline.start.clamp(0, source.length);
    final end = intraline.end.clamp(start, source.length);
    final text = SelectableText.rich(
      TextSpan(
        style: style?.copyWith(backgroundColor: background),
        children: [
          if (start > 0) TextSpan(text: source.substring(0, start)),
          if (end > start)
            TextSpan(
              text: source.substring(start, end),
              style: TextStyle(backgroundColor: emphasis),
            ),
          if (end < source.length) TextSpan(text: source.substring(end)),
        ],
      ),
    );
    if (marker == null || label == null) return text;
    return Semantics(
      label: '$label: $source',
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: BorderDirectional(
            start: BorderSide(
              color: marker == '−'
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
              width: 3,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
            start: BusyMarkSpacing.sm,
            bottom: BusyMarkSpacing.xs,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Text(
                  marker!,
                  style: style?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: BusyMarkSpacing.xs),
              Expanded(child: text),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourcePane extends StatelessWidget {
  const _SourcePane({
    required this.label,
    required this.source,
    required this.changes,
    required this.removed,
  });

  final String label;
  final String source;
  final List<SourceComparisonChange> changes;
  final bool removed;

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: const EdgeInsets.all(BusyMarkSpacing.md),
      child: SelectableText.rich(
        TextSpan(
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
          children: _spans(context),
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(BusyMarkSpacing.sm),
          child: Text(label, style: Theme.of(context).textTheme.labelLarge),
        ),
        Expanded(child: SingleChildScrollView(child: body)),
      ],
    );
  }

  List<InlineSpan> _spans(BuildContext context) {
    final sorted = [...changes]
      ..sort((a, b) {
        final left = removed ? a.oldRange : a.currentRange;
        final right = removed ? b.oldRange : b.currentRange;
        return left.start.compareTo(right.start);
      });
    final result = <InlineSpan>[];
    var offset = 0;
    for (final change in sorted) {
      final range = removed ? change.oldRange : change.currentRange;
      final start = range.start.clamp(offset, source.length);
      final end = range.end.clamp(start, source.length);
      if (start > offset) {
        result.add(TextSpan(text: source.substring(offset, start)));
      }
      if (end > start) {
        final intraline = removed
            ? change.oldIntralineRange
            : change.currentIntralineRange;
        final text = source.substring(start, end);
        final intralineStart = intraline.start.clamp(0, text.length);
        final intralineEnd = intraline.end.clamp(intralineStart, text.length);
        final base = removed
            ? Theme.of(context).colorScheme.errorContainer
            : Theme.of(context).colorScheme.primaryContainer;
        final emphasis = removed
            ? Theme.of(context).colorScheme.error.withValues(alpha: 0.32)
            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.32);
        result.add(
          TextSpan(
            // A semantic replacement label requires non-null text. Empty text
            // keeps copied source exact while the children retain styling.
            text: '',
            style: TextStyle(backgroundColor: base),
            semanticsLabel: removed
                ? context.l10n.localHistoryOlderChange(text)
                : context.l10n.localHistoryCurrentChange(text),
            children: [
              if (intralineStart > 0)
                TextSpan(text: text.substring(0, intralineStart)),
              if (intralineEnd > intralineStart)
                TextSpan(
                  text: text.substring(intralineStart, intralineEnd),
                  style: TextStyle(backgroundColor: emphasis),
                ),
              if (intralineEnd < text.length)
                TextSpan(text: text.substring(intralineEnd)),
            ],
          ),
        );
      }
      offset = end;
    }
    if (offset < source.length) {
      result.add(TextSpan(text: source.substring(offset)));
    }
    if (result.isEmpty) result.add(TextSpan(text: source));
    return result;
  }
}

class _ComparisonNotice extends StatelessWidget {
  const _ComparisonNotice({required this.text, this.actions = const []});

  final String text;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Container(
    color: Theme.of(context).colorScheme.secondaryContainer,
    padding: const EdgeInsets.all(BusyMarkSpacing.sm),
    child: Row(
      children: [
        const Icon(BusyMarkGlyphs.info, size: 18),
        const SizedBox(width: BusyMarkSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: BusyMarkSpacing.sm),
                Wrap(spacing: BusyMarkSpacing.sm, children: actions),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

String _revisionLabel(
  BuildContext context,
  LocalHistoryRevisionSummary revision,
) {
  final local = revision.capturedAt.toLocal();
  final material = MaterialLocalizations.of(context);
  return '${context.l10n.localHistorySelectedRevision} · '
      '${material.formatFullDate(local)} '
      '${material.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
}
