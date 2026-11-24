import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/localization.dart';
import '../../nextcloud_notes/application/nextcloud_connection.dart';
import '../../nextcloud_notes/domain/notes_models.dart';
import '../../nextcloud_notes/presentation/notes_sidebar.dart';
import '../document_buffer.dart';

import '../../app/busymark_design.dart';
import '../text_format_metadata.dart';
import 'document_format_indicator.dart';

class BusyMarkDocumentStatusBar extends StatelessWidget {
  const BusyMarkDocumentStatusBar({
    super.key,
    required this.format,
    this.saveStatus,
    this.spellingLabel,
    this.spellingTooltip,
    this.onSpellingPressed,
  });

  final TextFormatMetadata format;
  final DocumentSaveStatus? saveStatus;
  final String? spellingLabel;
  final String? spellingTooltip;
  final VoidCallback? onSpellingPressed;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return DecoratedBox(
      key: const ValueKey('document-status-bar'),
      decoration: BoxDecoration(
        color: colors.headerbarFlat,
        border: Border(top: BorderSide(color: colors.subtleBorder)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: BusyMarkSizes.documentStatusBarHeight,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: BusyMarkSpacing.xs),
          child: Row(
            children: [
              if (spellingLabel case final label?)
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    heightFactor: 1,
                    child: _DocumentStatusAction(
                      label: label,
                      tooltip: spellingTooltip,
                      onPressed: onSpellingPressed,
                    ),
                  ),
                )
              else
                const Spacer(),
              if (saveStatus case final status?)
                Expanded(
                  flex: 3,
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    heightFactor: 1,
                    child: _SaveStatusIndicator(status: status),
                  ),
                ),
              BusyMarkDocumentFormatIndicator(format: format),
            ],
          ),
        ),
      ),
    );
  }
}

class DocumentSaveStatus {
  const DocumentSaveStatus(this.label, {this.compactLabel, this.details});

  final String label;
  final String? compactLabel;
  final String? details;

  static DocumentSaveStatus forBuffer(
    BuildContext context,
    WidgetRef ref,
    DocumentBuffer buffer, {
    required bool pendingProperties,
  }) {
    final l10n = context.l10n;
    final phase = buffer.currentSaveActivity?.phase;
    if (!buffer.isRemote) {
      if (buffer.deletedOnDisk || phase == DocumentSavePhase.missing) {
        return DocumentSaveStatus(
          l10n.documentFileMissing,
          details: l10n.externalFileDeleted,
        );
      }
      if (buffer.hasConflict ||
          buffer.diskState == DocumentDiskState.changed ||
          phase == DocumentSavePhase.conflict) {
        return DocumentSaveStatus(
          l10n.documentSaveConflict,
          details: l10n.fileChangedOnDisk,
        );
      }
    }
    if (!pendingProperties && phase == DocumentSavePhase.saving) {
      return DocumentSaveStatus(l10n.documentSaving);
    }
    if (phase == DocumentSavePhase.failed) {
      return DocumentSaveStatus(l10n.documentSaveFailed);
    }
    if (buffer.isUntitled) return DocumentSaveStatus(l10n.documentNotSaved);
    if (pendingProperties || buffer.isDirty || buffer.recovered) {
      return DocumentSaveStatus(l10n.documentModified);
    }
    if (buffer.remoteNote case final reference?) {
      return _noteSaveStatus(context, ref, reference, buffer.lastSavedText);
    }
    return buffer.diskSnapshot == null
        ? DocumentSaveStatus(l10n.documentSaveUnverified)
        : DocumentSaveStatus(l10n.documentSaved);
  }
}

final _pendingNoteAttachmentsProvider = FutureProvider.autoDispose
    .family<bool, NextcloudNote>((ref, note) async {
      ref.watch(nextcloudNotesChangesProvider);
      final repository = await ref.watch(
        nextcloudNotesRepositoryProvider.future,
      );
      return repository.hasPendingAttachmentWork(note);
    });

DocumentSaveStatus _noteSaveStatus(
  BuildContext context,
  WidgetRef ref,
  NextcloudNoteReference reference,
  String savedText,
) {
  ref.watch(nextcloudNotesChangesProvider);
  final repository = ref.watch(nextcloudNotesRepositoryProvider).value;
  final note = repository?.noteById(reference.localId);
  final l10n = context.l10n;
  if (note == null ||
      note.accountId != reference.accountId ||
      note.content != savedText) {
    return DocumentSaveStatus(l10n.documentSaveUnverified);
  }
  if (nextcloudMetadataNeedsReview(note) ||
      note.syncState == NoteSyncState.conflict) {
    return DocumentSaveStatus(l10n.documentSaveConflict);
  }
  DocumentSaveStatus local(String label, {String? details}) =>
      DocumentSaveStatus(
        '${l10n.documentSavedLocally} · $label',
        compactLabel: label,
        details: details,
      );
  final accountError = repository!.accountError(note.accountId)?.code;
  if (note.creationAttempt != null && note.syncState != NoteSyncState.syncing) {
    return DocumentSaveStatus(l10n.nextcloudCreationUncertain);
  }
  switch (note.syncState) {
    case NoteSyncState.syncing:
      return local('${l10n.nextcloudSyncing}…');
    case NoteSyncState.offline:
      return local(
        l10n.nextcloudOffline,
        details: note.hasPendingChanges ? l10n.documentSyncPending : null,
      );
    case NoteSyncState.synced:
    case NoteSyncState.pending:
      if (accountError == NotesFailureCode.network) {
        return local(
          l10n.nextcloudOffline,
          details: note.hasPendingChanges ? l10n.documentSyncPending : null,
        );
      }
      if (note.failureCode != null ||
          (accountError != null && note.hasPendingChanges)) {
        return local(l10n.documentSyncFailed);
      }
      if (note.hasPendingChanges || note.syncState == NoteSyncState.pending) {
        return local(l10n.documentSyncPending);
      }
      final pending = ref.watch(_pendingNoteAttachmentsProvider(note));
      if (pending.hasError) return local(l10n.documentSyncFailed);
      return !pending.isLoading && pending.value == false
          ? DocumentSaveStatus(l10n.nextcloudSynced)
          : local(l10n.documentSyncPending);
    default:
      return DocumentSaveStatus(nextcloudSyncLabel(context, note.syncState));
  }
}

class _SaveStatusIndicator extends StatelessWidget {
  const _SaveStatusIndicator({required this.status});

  final DocumentSaveStatus status;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: BusyMarkSurfaceColors.of(context).mutedForeground,
    );
    final description = status.details == null
        ? status.label
        : '${status.label} · ${status.details}';
    return Tooltip(
      message: description,
      excludeFromSemantics: true,
      child: Semantics(
        label: description,
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: BusyMarkSpacing.xs),
          child: LayoutBuilder(
            builder: (context, constraints) {
              var label = status.label;
              if (status.compactLabel case final compact?) {
                final painter = TextPainter(
                  text: TextSpan(text: label, style: style),
                  textScaler: MediaQuery.textScalerOf(context),
                  textDirection: Directionality.of(context),
                  maxLines: 1,
                )..layout(maxWidth: constraints.maxWidth);
                if (painter.didExceedMaxLines) label = compact;
                painter.dispose();
              }
              return Text(
                label,
                key: const ValueKey('document-save-status'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DocumentStatusAction extends StatelessWidget {
  const _DocumentStatusAction({
    required this.label,
    required this.tooltip,
    required this.onPressed,
  });

  final String label;
  final String? tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    Widget action = Semantics(
      key: const ValueKey('document-spelling-language-status'),
      button: true,
      enabled: onPressed != null,
      child: Material(
        color: BusyMarkLinuxPalette.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(BusyMarkRadius.sm),
          hoverColor: busyMarkRowHoverColor(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BusyMarkSpacing.sm,
              vertical: BusyMarkSpacing.xxs,
            ),
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: colors.mutedForeground),
            ),
          ),
        ),
      ),
    );
    if (tooltip case final message?) {
      action = Tooltip(message: message, child: action);
    }
    return action;
  }
}
