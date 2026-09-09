import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../app/busymark_design.dart';
import '../app/busymark_glyphs.dart';
import '../app/busymark_search_field.dart';
import '../app/busymark_dialogs.dart';
import '../app/localization.dart';
import '../workspace/workspace_controller.dart';
import 'local_history_controller.dart';
import 'local_history_models.dart';

class LocalHistoryPanel extends ConsumerStatefulWidget {
  const LocalHistoryPanel({this.focusSearchRequest = 0, super.key});

  final int focusSearchRequest;

  @override
  ConsumerState<LocalHistoryPanel> createState() => _LocalHistoryPanelState();
}

class _LocalHistoryPanelState extends ConsumerState<LocalHistoryPanel> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _selectActive());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectActive() async {
    if (ref.read(localHistoryControllerProvider).findingDocuments) return;
    final buffer = ref.read(workspaceControllerProvider).activeBuffer;
    if (buffer != null) {
      await ref
          .read(localHistoryControllerProvider.notifier)
          .selectDocumentForBuffer(buffer);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(localHistoryControllerProvider);
    final controller = ref.read(localHistoryControllerProvider.notifier);
    final documents = [...state.snapshot.documents]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final visibleDocuments =
        state.findingDocuments && state.searchQuery.isNotEmpty
        ? documents
              .where(
                (document) => state.documentSearchMatches.contains(document.id),
              )
              .toList(growable: false)
        : documents;
    final selected = state.selectedDocument;
    final visibleRevisions = state.selectedRevisions
        .where(state.revisionVisible)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            BusyMarkSpacing.md,
            BusyMarkSpacing.sm,
            BusyMarkSpacing.md,
            BusyMarkSpacing.xs,
          ),
          child: Row(
            children: [
              Expanded(
                child: PopupMenuButton<String>(
                  tooltip: context.l10n.localHistory,
                  enabled: documents.isNotEmpty,
                  onSelected: controller.selectDocument,
                  itemBuilder: (context) => [
                    for (final document in documents)
                      PopupMenuItem(
                        value: document.id,
                        child: _DocumentLabel(document: document),
                      ),
                  ],
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    child: Row(
                      children: [
                        const Icon(BusyMarkGlyphs.documentHistory, size: 18),
                        const SizedBox(width: BusyMarkSpacing.sm),
                        Expanded(
                          child: selected == null
                              ? Text(context.l10n.localHistoryNoDocuments)
                              : _DocumentLabel(document: selected),
                        ),
                        const Icon(BusyMarkGlyphs.downArrow, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: MaterialLocalizations.of(
                  context,
                ).refreshIndicatorSemanticLabel,
                onPressed: state.loading ? null : controller.refresh,
                icon: state.loading
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(BusyMarkGlyphs.refresh),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BusyMarkSpacing.md,
            vertical: BusyMarkSpacing.xs,
          ),
          child: BusyMarkSearchField(
            controller: _searchController,
            focusRequest: widget.focusSearchRequest,
            hintText: context.l10n.localHistorySearchHint,
            onChanged: (value) => unawaited(controller.search(value)),
          ),
        ),
        if (state.warning != null)
          Padding(
            padding: const EdgeInsets.all(BusyMarkSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(BusyMarkGlyphs.warning, size: 18),
                const SizedBox(width: BusyMarkSpacing.sm),
                Expanded(
                  child: Text(
                    localizeLocalHistoryWarning(context, state.warning!),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: state.findingDocuments
              ? visibleDocuments.isEmpty
                    ? _HistoryEmpty(
                        text: documents.isEmpty
                            ? context.l10n.localHistoryNoDocuments
                            : context.l10n.localHistoryNoMatches,
                      )
                    : ListView.builder(
                        itemCount: visibleDocuments.length,
                        itemBuilder: (context, index) {
                          final document = visibleDocuments[index];
                          final path =
                              document.currentPath ??
                              document.historicalPaths.lastOrNull;
                          return Semantics(
                            button: true,
                            child: ListTile(
                              leading: Icon(
                                document.deleted
                                    ? BusyMarkGlyphs.delete
                                    : BusyMarkGlyphs.documentHistory,
                              ),
                              title: Text(document.displayName),
                              subtitle: path == null
                                  ? null
                                  : Text(
                                      path,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                              trailing: document.deleted
                                  ? Text(context.l10n.localHistoryDeleted)
                                  : null,
                              onTap: () =>
                                  controller.selectDocument(document.id),
                            ),
                          );
                        },
                      )
              : selected == null
              ? _HistoryEmpty(text: context.l10n.localHistoryNoDocuments)
              : visibleRevisions.isEmpty
              ? _HistoryEmpty(
                  text: state.searchQuery.isEmpty
                      ? context.l10n.localHistoryNoRevisions
                      : context.l10n.localHistoryNoMatches,
                )
              : ListView.builder(
                  itemCount: visibleRevisions.length,
                  itemBuilder: (context, index) {
                    final revision = visibleRevisions[index];
                    final previous = index == 0
                        ? null
                        : visibleRevisions[index - 1];
                    final startsDate =
                        previous == null ||
                        !_sameDate(previous.capturedAt, revision.capturedAt);
                    final reason = _reason(context, revision.reason);
                    final timestamp = DateFormat.yMd(
                      Localizations.localeOf(context).toLanguageTag(),
                    ).add_Hms().format(revision.capturedAt.toLocal());
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (startsDate)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              BusyMarkSpacing.md,
                              BusyMarkSpacing.md,
                              BusyMarkSpacing.md,
                              BusyMarkSpacing.xs,
                            ),
                            child: Text(
                              MaterialLocalizations.of(
                                context,
                              ).formatFullDate(revision.capturedAt.toLocal()),
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
                        Semantics(
                          selected: revision.id == state.selectedRevisionId,
                          button: true,
                          label: context.l10n.localHistoryRevisionAt(
                            reason,
                            timestamp,
                          ),
                          excludeSemantics: true,
                          child: ListTile(
                            selected: revision.id == state.selectedRevisionId,
                            leading: const Icon(BusyMarkGlyphs.history),
                            title: Text(reason),
                            subtitle: Text(timestamp),
                            onTap: () => unawaited(
                              controller.selectRevision(revision.id),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
        if (selected != null)
          Padding(
            padding: const EdgeInsets.all(BusyMarkSpacing.sm),
            child: PopupMenuButton<_ClearAction>(
              tooltip: context.l10n.actions,
              onSelected: (action) => _confirmClear(action, selected.id),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _ClearAction.document,
                  child: Text(context.l10n.localHistoryClearDocument),
                ),
                PopupMenuItem(
                  value: _ClearAction.all,
                  child: Text(context.l10n.localHistoryClearAll),
                ),
              ],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(BusyMarkGlyphs.menuHorizontal),
                  const SizedBox(width: BusyMarkSpacing.xs),
                  Text(context.l10n.actions),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmClear(_ClearAction action, String documentId) async {
    final confirmed = await showBusyMarkModalDialog<bool>(
      context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          action == _ClearAction.document
              ? dialogContext.l10n.localHistoryClearDocumentTitle
              : dialogContext.l10n.localHistoryClearAllTitle,
        ),
        content: Text(dialogContext.l10n.localHistoryClearConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dialogContext.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(dialogContext.l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final controller = ref.read(localHistoryControllerProvider.notifier);
    if (action == _ClearAction.document) {
      await controller.clearDocument(documentId);
    } else {
      await controller.clearAll();
    }
  }
}

enum _ClearAction { document, all }

class _DocumentLabel extends StatelessWidget {
  const _DocumentLabel({required this.document});

  final LocalHistoryDocument document;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message:
          document.currentPath ?? document.historicalPaths.lastOrNull ?? '',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Text(
              document.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (document.deleted) ...[
            const SizedBox(width: BusyMarkSpacing.xs),
            Text(
              context.l10n.localHistoryDeleted,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _HistoryEmpty extends StatelessWidget {
  const _HistoryEmpty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(BusyMarkSpacing.lg),
      child: Text(text, textAlign: TextAlign.center),
    ),
  );
}

String _reason(BuildContext context, LocalHistoryCaptureReason reason) {
  final l10n = context.l10n;
  return switch (reason) {
    LocalHistoryCaptureReason.baseline => l10n.localHistoryReasonBaseline,
    LocalHistoryCaptureReason.saved => l10n.localHistoryReasonSaved,
    LocalHistoryCaptureReason.automaticCheckpoint =>
      l10n.localHistoryReasonAutomaticCheckpoint,
    LocalHistoryCaptureReason.beforeReload =>
      l10n.localHistoryReasonBeforeReload,
    LocalHistoryCaptureReason.beforeDiscard =>
      l10n.localHistoryReasonBeforeDiscard,
    LocalHistoryCaptureReason.beforeRestore =>
      l10n.localHistoryReasonBeforeRestore,
    LocalHistoryCaptureReason.beforeDelete =>
      l10n.localHistoryReasonBeforeDelete,
    LocalHistoryCaptureReason.externalChange =>
      l10n.localHistoryReasonExternalChange,
  };
}

bool _sameDate(DateTime left, DateTime right) {
  final localLeft = left.toLocal();
  final localRight = right.toLocal();
  return localLeft.year == localRight.year &&
      localLeft.month == localRight.month &&
      localLeft.day == localRight.day;
}

String localizeLocalHistoryWarning(
  BuildContext context,
  LocalHistoryWarning warning,
) {
  final l10n = context.l10n;
  final detail = warning.detail ?? '';
  return switch (warning.kind) {
    LocalHistoryWarningKind.indexRebuilt =>
      l10n.localHistoryWarningIndexRebuilt,
    LocalHistoryWarningKind.unsupportedFormat =>
      l10n.localHistoryWarningUnsupportedFormat(detail),
    LocalHistoryWarningKind.unavailable => l10n.localHistoryWarningUnavailable(
      detail,
    ),
    LocalHistoryWarningKind.recordingDisabled =>
      l10n.localHistoryWarningRecordingDisabled,
    LocalHistoryWarningKind.pathChange => l10n.localHistoryWarningPathChange(
      detail,
    ),
    LocalHistoryWarningKind.deletedPath => l10n.localHistoryWarningDeletedPath(
      detail,
    ),
    LocalHistoryWarningKind.revisionMissing =>
      l10n.localHistoryWarningRevisionMissing,
    LocalHistoryWarningKind.revisionRead =>
      l10n.localHistoryWarningRevisionRead(detail),
    LocalHistoryWarningKind.capture => l10n.localHistoryWarningCapture(detail),
  };
}
