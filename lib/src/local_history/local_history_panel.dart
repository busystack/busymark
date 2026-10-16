import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:path/path.dart' as p;

import '../app/busymark_design.dart';
import '../app/busymark_glyphs.dart';
import '../search/search_session.dart';
import '../app/busymark_dialogs.dart';
import '../app/localization.dart';
import '../workspace/workspace_controller.dart';
import 'local_history_controller.dart';
import 'local_history_models.dart';

class LocalHistoryPanel extends ConsumerStatefulWidget {
  const LocalHistoryPanel({super.key});

  @override
  ConsumerState<LocalHistoryPanel> createState() => _LocalHistoryPanelState();
}

class _LocalHistoryPanelState extends ConsumerState<LocalHistoryPanel> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _selectActive());
  }

  Future<void> _selectActive({bool preserveLookup = true}) async {
    final history = ref.read(localHistoryControllerProvider);
    if (preserveLookup &&
        (history.browsingDocuments || history.inspectingRetainedDocument)) {
      return;
    }
    final buffer = ref.read(workspaceControllerProvider).activeBuffer;
    if (buffer != null) {
      await ref
          .read(localHistoryControllerProvider.notifier)
          .selectDocumentForBuffer(buffer);
    } else if (!preserveLookup ||
        !ref.read(localHistoryControllerProvider).inspectingRetainedDocument) {
      ref.read(localHistoryControllerProvider.notifier).clearDocumentScope();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(localHistoryControllerProvider);
    final controller = ref.read(localHistoryControllerProvider.notifier);
    final workspaceState = ref.watch(workspaceControllerProvider);
    final activeBuffer = workspaceState.activeBuffer;
    ref.listen<_LocalHistoryEditorScope>(
      workspaceControllerProvider.select(
        (value) => (
          workspaceId: value.workspace?.id,
          bufferId: value.activeBuffer?.id,
          path: value.activeBuffer?.filePath,
          displayName: value.activeBuffer?.displayName,
        ),
      ),
      (previous, next) {
        if (previous == next) return;
        if (next.bufferId == null) {
          final history = ref.read(localHistoryControllerProvider);
          if (!history.browsingDocuments &&
              !history.inspectingRetainedDocument) {
            controller.clearDocumentScope();
          }
          return;
        }
        final buffer = ref.read(workspaceControllerProvider).activeBuffer;
        if (buffer != null) {
          unawaited(controller.selectDocumentForBuffer(buffer));
        }
      },
    );
    final visibleDocuments = [...state.snapshot.documents]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final selected = state.selectedDocument;
    final activeHistoryDocumentId = activeBuffer == null
        ? null
        : controller.documentIdForBuffer(activeBuffer.id);
    final selectedMatchesActive =
        selected != null &&
        activeBuffer != null &&
        (selected.id == activeHistoryDocumentId ||
            (!selected.deleted &&
                selected.currentPath != null &&
                activeBuffer.filePath != null &&
                p.equals(selected.currentPath!, activeBuffer.filePath!)));
    final selectedMatchesVisibleScope =
        state.inspectingRetainedDocument || selectedMatchesActive;
    final visibleRevisions = selectedMatchesVisibleScope
        ? state.selectedRevisions
        : const <LocalHistoryRevisionSummary>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.browsingDocuments || state.inspectingRetainedDocument)
          _LocalHistoryHeader(
            selectedDocument: selected,
            browsingDocuments: state.browsingDocuments,
            inspectingRetainedDocument: state.inspectingRetainedDocument,
            onBack: () => unawaited(_selectActive(preserveLookup: false)),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BusyMarkSpacing.md,
            vertical: BusyMarkSpacing.xs,
          ),
          child: Row(
            textDirection: TextDirection.ltr,
            children: [
              const Spacer(),
              BusyMarkCompactIconButton(
                tooltip: context.l10n.findLocalHistoryEllipsis,
                icon: BusyMarkGlyphs.search,
                onPressed: () => ref
                    .read(searchSessionProvider.notifier)
                    .openHistory(documentId: selected?.id),
              ),
              const SizedBox(width: BusyMarkSpacing.sm),
              BusyMarkHeaderPopupMenuButton<_HistoryAction>(
                key: const ValueKey('local-history-actions-menu'),
                tooltip: context.l10n.actions,
                icon: BusyMarkGlyphs.menuVertical,
                transparent: true,
                borderRadius: BusyMarkRadius.nativeHeaderButton,
                highlightWhenOpen: false,
                itemBuilder: (context) => [
                  BusyMarkPopupMenuItem(
                    value: _HistoryAction.refresh,
                    label: MaterialLocalizations.of(
                      context,
                    ).refreshIndicatorSemanticLabel,
                    icon: BusyMarkGlyphs.refresh,
                    enabled: !state.loading,
                  ),
                  BusyMarkPopupMenuItem(
                    value: _HistoryAction.find,
                    label: context.l10n.findLocalHistoryEllipsis,
                    icon: BusyMarkGlyphs.search,
                  ),
                  const PopupMenuDivider(height: BusyMarkSpacing.sm),
                  BusyMarkPopupMenuItem(
                    value: _HistoryAction.clearDocument,
                    label: context.l10n.localHistoryClearDocument,
                    icon: BusyMarkGlyphs.delete,
                    enabled:
                        selectedMatchesVisibleScope &&
                        state.selectedRevisions.isNotEmpty,
                  ),
                  BusyMarkPopupMenuItem(
                    value: _HistoryAction.clearAll,
                    label: context.l10n.localHistoryClearAll,
                    icon: BusyMarkGlyphs.clearAll,
                    enabled: state.snapshot.revisions.isNotEmpty,
                  ),
                ],
                onSelected: (action) {
                  switch (action) {
                    case _HistoryAction.refresh:
                      unawaited(controller.refresh());
                    case _HistoryAction.find:
                      ref
                          .read(searchSessionProvider.notifier)
                          .openHistory(documentId: selected?.id);
                    case _HistoryAction.clearDocument:
                      final documentId = selected?.id;
                      if (documentId != null) {
                        unawaited(_confirmClear(action, documentId));
                      }
                    case _HistoryAction.clearAll:
                      unawaited(_confirmClear(action, null));
                  }
                },
              ),
            ],
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
          child: state.browsingDocuments
              ? visibleDocuments.isEmpty
                    ? _HistoryEmpty(
                        text: visibleDocuments.isEmpty
                            ? context.l10n.localHistoryNoDocuments
                            : context.l10n.localHistoryNoMatches,
                      )
                    : ListView.builder(
                        key: const ValueKey(
                          'local-history-document-search-results',
                        ),
                        padding: BusyMarkInsets.sidebarList,
                        itemCount: visibleDocuments.length,
                        itemBuilder: (context, index) {
                          final document = visibleDocuments[index];
                          final path =
                              document.currentPath ??
                              document.historicalPaths.lastOrNull;
                          final subtitle = document.deleted
                              ? path == null
                                    ? context.l10n.localHistoryDeleted
                                    : '${context.l10n.localHistoryDeleted} · $path'
                              : path;
                          return BusyMarkSidebarRecordRow<void>(
                            icon: document.deleted
                                ? BusyMarkGlyphs.delete
                                : BusyMarkGlyphs.documentHistory,
                            title: document.displayName,
                            subtitle: subtitle,
                            onTap: () =>
                                controller.inspectRetainedDocument(document.id),
                          );
                        },
                      )
              : state.loading &&
                    state.selectedDocumentId == null &&
                    !state.inspectingRetainedDocument
              ? const Center(child: CircularProgressIndicator())
              : activeBuffer == null && !state.inspectingRetainedDocument
              ? _HistoryEmpty(text: context.l10n.localHistoryNoDocuments)
              : visibleRevisions.isEmpty
              ? _HistoryEmpty(text: context.l10n.localHistoryNoRevisions)
              : ListView.builder(
                  key: ValueKey(
                    'local-history-revisions-${selected?.id ?? 'none'}',
                  ),
                  padding: BusyMarkInsets.sidebarList,
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
                    final locale = Localizations.localeOf(
                      context,
                    ).toLanguageTag();
                    final localTime = revision.capturedAt.toLocal();
                    final timestamp = DateFormat.Hms(locale).format(localTime);
                    final fullTimestamp = DateFormat.yMd(
                      locale,
                    ).add_Hms().format(localTime);
                    final event = _visibleReason(context, revision.reason);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (startsDate)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              BusyMarkSpacing.xs,
                              BusyMarkSpacing.lg,
                              BusyMarkSpacing.xs,
                              BusyMarkSpacing.xs,
                            ),
                            child: Text(
                              MaterialLocalizations.of(
                                context,
                              ).formatFullDate(revision.capturedAt.toLocal()),
                              style: busyMarkSectionHeaderStyle(context),
                            ),
                          ),
                        BusyMarkSidebarRecordRow<void>(
                          icon: BusyMarkGlyphs.history,
                          title: timestamp,
                          subtitle: event,
                          selected: revision.id == state.selectedRevisionId,
                          semanticsLabel: context.l10n.localHistoryRevisionAt(
                            reason,
                            fullTimestamp,
                          ),
                          tooltip: context.l10n.localHistoryRevisionAt(
                            reason,
                            fullTimestamp,
                          ),
                          onTap: () =>
                              unawaited(controller.selectRevision(revision.id)),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _confirmClear(_HistoryAction action, String? documentId) async {
    final controller = ref.read(localHistoryControllerProvider.notifier);
    final confirmed = await showBusyMarkModalDialog<bool>(
      context,
      barrierDismissible: false,
      builder: (dialogContext) => BusyMarkDialogShell(
        title: action == _HistoryAction.clearDocument
            ? dialogContext.l10n.localHistoryClearDocumentTitle
            : dialogContext.l10n.localHistoryClearAllTitle,
        actions: [
          BusyMarkDialogButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            label: dialogContext.l10n.cancel,
          ),
          BusyMarkDialogButton(
            destructive: true,
            onPressed: () => Navigator.pop(dialogContext, true),
            label: dialogContext.l10n.delete,
          ),
        ],
        children: [
          Text(
            action == _HistoryAction.clearAll
                ? '${dialogContext.l10n.localHistoryClearAll}.\n\n'
                      '${dialogContext.l10n.localHistoryClearConfirmation}'
                : dialogContext.l10n.localHistoryClearConfirmation,
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (action == _HistoryAction.clearDocument && documentId != null) {
      await controller.clearDocument(documentId);
    } else {
      await controller.clearAll();
    }
  }
}

typedef _LocalHistoryEditorScope = ({
  String? workspaceId,
  String? bufferId,
  String? path,
  String? displayName,
});

enum _HistoryAction { refresh, find, clearDocument, clearAll }

class _LocalHistoryHeader extends StatelessWidget {
  const _LocalHistoryHeader({
    required this.selectedDocument,
    required this.browsingDocuments,
    required this.inspectingRetainedDocument,
    required this.onBack,
  });

  final LocalHistoryDocument? selectedDocument;
  final bool browsingDocuments;
  final bool inspectingRetainedDocument;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final selectedPath =
        selectedDocument?.currentPath ??
        selectedDocument?.historicalPaths.lastOrNull;
    final title = browsingDocuments
        ? context.l10n.findLocalHistoryEllipsis
        : selectedDocument?.displayName ?? context.l10n.localHistoryNoDocuments;
    final path = inspectingRetainedDocument ? selectedPath : null;
    return Padding(
      key: const ValueKey('local-history-context-header'),
      padding: const EdgeInsets.fromLTRB(
        BusyMarkSpacing.md,
        BusyMarkSpacing.sm,
        BusyMarkSpacing.sm,
        BusyMarkSpacing.xs,
      ),
      child: Row(
        children: [
          BusyMarkHeaderIconButton(
            tooltip: context.l10n.back,
            icon: BusyMarkGlyphs.backFor(Directionality.of(context)),
            transparent: true,
            onPressed: onBack,
          ),
          const SizedBox(width: BusyMarkSpacing.xs),
          Expanded(
            child: Tooltip(
              message: path == null
                  ? title
                  : busyMarkLtrIsolateFor(context, path),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      busyMarkLtrIsolateFor(context, title),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  if (inspectingRetainedDocument &&
                      selectedDocument?.deleted == true) ...[
                    const SizedBox(width: BusyMarkSpacing.xs),
                    Text(
                      context.l10n.localHistoryDeleted,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
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

String? _visibleReason(BuildContext context, LocalHistoryCaptureReason reason) {
  return switch (reason) {
    LocalHistoryCaptureReason.baseline ||
    LocalHistoryCaptureReason.automaticCheckpoint => null,
    _ => _reason(context, reason),
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
  final detail = warning.ownerDisplayName == null
      ? warning.detail ?? ''
      : '${warning.ownerDisplayName}: ${warning.detail ?? ''}';
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
