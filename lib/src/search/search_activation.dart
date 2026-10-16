import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../app/app_settings.dart';
import '../app/busymark_toast.dart';
import '../app/command_registry.dart';
import '../app/localization.dart';
import '../local_history/local_history_controller.dart';
import '../local_history/local_history_models.dart';
import '../nextcloud_notes/application/nextcloud_connection.dart';
import '../nextcloud_notes/application/notes_navigation.dart';
import '../nextcloud_notes/domain/notes_search.dart';
import '../nextcloud_notes/presentation/notes_workspace_ui.dart';
import '../workspace/document_navigation.dart';
import '../workspace/recent_navigation.dart';
import '../workspace/workspace_controller.dart';
import 'search_session.dart';

bool actionEnabled(WidgetRef ref, ActionSearchResult result) {
  final controller = ref.read(searchSessionProvider.notifier);
  final command = result.command;
  final registry = BusyMarkCommandRegistryScope.read(ref.context);
  if (registry == null) return false;
  final workspace = ref.read(workspaceControllerProvider);
  final target = controller.commandTarget;
  if (registry.requiresDocumentTarget(command) &&
      (!controller.workspaceVisible ||
          target?.bufferId == null ||
          target?.isCurrent(workspace) != true)) {
    return false;
  }
  final activeNotesAction =
      controller.workspaceVisible &&
      (workspace.workspace?.isRemote == true ||
          controller.actionAccountId != null) &&
      {
        BusyMarkCommandIds.newNote,
        BusyMarkCommandIds.browseNotes,
      }.contains(command.id);
  if ((registry.requiresWorkspaceTarget(command) || activeNotesAction) &&
      (!controller.workspaceVisible ||
          target?.workspaceId == null ||
          target?.workspaceId != workspace.workspace?.id)) {
    return false;
  }
  if (registry.isContextual(command)) {
    return controller.workspaceVisible &&
        target?.isCurrent(ref.read(workspaceControllerProvider)) == true &&
        registry.canExecuteInContext(command.id, target!.context);
  }
  if (!controller.workspaceVisible &&
      command.scope != BusyMarkCommandScope.application) {
    return false;
  }
  return command.canExecute;
}

Future<void> activateSelectedSearchResult(
  BuildContext context,
  WidgetRef ref,
) async {
  final controller = ref.read(searchSessionProvider.notifier);
  if (!await controller.submit() || !context.mounted) return;
  final state = ref.read(searchSessionProvider);
  if (state.category == SearchCategory.outline) {
    controller.activateOutline?.call();
    return;
  }
  if (state.results.isEmpty) return;
  await activateSearchResult(context, ref, state.results[state.selected]);
}

final _searchActivationProvider = Provider((ref) => _SearchActivation());

class _SearchActivation {
  bool busy = false;
}

Future<void> activateSearchResult(
  BuildContext context,
  WidgetRef ref,
  SidebarSearchResult result, {
  bool source = false,
}) async {
  final guard = ref.read(_searchActivationProvider);
  if (guard.busy) return;
  guard.busy = true;
  final session = ref.read(searchSessionProvider.notifier);
  final snapshot = ref.read(searchSessionProvider);
  final workspace = ref.read(workspaceControllerProvider).workspace;
  final controller = ref.read(workspaceControllerProvider.notifier);
  void unavailable() {
    if (context.mounted) {
      BusyMarkToastOverlay.show(
        context,
        message: context.l10n.commandUnavailableInContext,
      );
    }
  }

  try {
    if (!snapshot.active ||
        !snapshot.results.any((r) => identical(r, result))) {
      unavailable();
      return;
    }
    session.select(snapshot.results.indexWhere((r) => identical(r, result)));
    bool currentRequest() =>
        ref.context.mounted &&
        session.workspaceVisible &&
        ref.read(workspaceControllerProvider).workspace?.id == workspace?.id &&
        ref.read(searchSessionProvider).active &&
        ref.read(searchSessionProvider).requestRevision ==
            snapshot.requestRevision &&
        ref.read(searchSessionProvider).focusRequest == snapshot.focusRequest &&
        ref.read(searchSessionProvider).query == snapshot.query &&
        ref.read(searchSessionProvider).category == snapshot.category &&
        ref.read(searchSessionProvider).recovery == snapshot.recovery &&
        ref.read(searchSessionProvider).historyDocumentId ==
            snapshot.historyDocumentId;
    switch (result) {
      case ActionSearchResult(:final command):
        if (!actionEnabled(ref, result)) {
          unavailable();
          return;
        }
        final registry = BusyMarkCommandRegistryScope.read(context)!;
        final success = await registry.executeInContext(
          command.id,
          session.commandTarget?.context,
        );
        if (success &&
            ref.context.mounted &&
            ref.read(searchSessionProvider).focusRequest ==
                snapshot.focusRequest &&
            ref.read(searchSessionProvider).category == snapshot.category) {
          session.close();
        }
      case RecentSearchResult(:final resource):
        await openRecentResource(context, ref, resource);
      case DocumentSearchResult(
        :final workspaceId,
        :final accountId,
        :final document,
      ):
        if (!session.workspaceVisible || workspace?.id != workspaceId) {
          unavailable();
          return;
        }
        if (accountId != null) {
          final repo = await ref.read(nextcloudNotesRepositoryProvider.future);
          final note = repo.noteById(document.localId!);
          if (!context.mounted ||
              !currentRequest() ||
              ref.read(workspaceControllerProvider).workspace?.id !=
                  workspaceId ||
              note?.accountId != accountId ||
              isNotesRecovery(note!) ||
              repo.isCreationCandidateBinding(note.localId)) {
            unavailable();
            return;
          }
          if (await controller.openNextcloudNote(
            document.localId!,
            acceptNavigation: currentRequest,
          )) {
            if (!currentRequest()) return;
            revealOpenedDocument(ref);
            session.close(restoreFocus: false);
          }
        } else {
          if (!workspace!.files.any(
            (f) => f.absolutePath == document.filePath,
          )) {
            unavailable();
            return;
          }
          if (await controller.openActiveFile(
            document.filePath!,
            acceptNavigation: currentRequest,
          )) {
            if (!currentRequest()) return;
            revealOpenedDocument(ref);
            session.close(restoreFocus: false);
          }
        }
      case TopicSearchResult(:final workspaceId, :final path):
        if (!session.workspaceVisible ||
            workspace?.id != workspaceId ||
            ![
              for (final module
                  in workspace!.writersideProject?.modules ??
                      [
                        if (workspace.writersideModule != null)
                          workspace.writersideModule!,
                      ])
                ...module.topics,
            ].any((t) => p.equals(t.filePath, path))) {
          unavailable();
          return;
        }
        if (await controller.openActiveFile(
          path,
          acceptNavigation: currentRequest,
        )) {
          if (!currentRequest()) return;
          revealOpenedDocument(ref);
          session.close(restoreFocus: false);
        }
      case HistorySearchResult(:final match):
        if (!currentRequest()) return;
        final history = ref.read(localHistoryControllerProvider.notifier);
        final retained = ref.read(localHistoryControllerProvider).snapshot;
        final document = retained.documents
            .where((d) => d.id == match.document.id)
            .firstOrNull;
        if (document == null) {
          unavailable();
          return;
        }
        if (match is LocalHistoryRevisionMatch &&
            !retained.revisions.any(
              (r) =>
                  r.id == match.revision.id &&
                  r.documentId == document.id &&
                  r.checksum == match.revision.checksum,
            )) {
          unavailable();
          return;
        }
        history.inspectRetainedDocument(document.id);
        if (match is LocalHistoryRevisionMatch) {
          await history.selectRevision(
            match.revision.id,
            acceptSelection: currentRequest,
          );
        } else {
          // Metadata matches show the unfiltered retained timeline. They never
          // open a live path, bind a buffer or create a replacement document.
          session.close(restoreFocus: false);
          ref.read(localHistoryOpenRequestProvider.notifier).request();
        }
      case TextSearchResult(:final workspaceId, :final match):
        if (!session.workspaceVisible || workspace?.id != workspaceId) {
          unavailable();
          return;
        }
        if (match.bufferId != null) {
          if (ref.read(workspaceControllerProvider).activeBufferId !=
                  match.bufferId &&
              !await controller.activateDocumentBuffer(
                match.bufferId!,
                acceptNavigation: currentRequest,
              )) {
            return;
          }
        } else if (match.filePath != null) {
          if (!await controller.openActiveFile(
            match.filePath!,
            acceptNavigation: currentRequest,
          )) {
            return;
          }
        } else {
          unavailable();
          return;
        }
        if (!context.mounted ||
            !currentRequest() ||
            ref.read(workspaceControllerProvider).workspace?.id !=
                workspaceId) {
          return;
        }
        final buffer = ref.read(workspaceControllerProvider).activeBuffer;
        if (buffer == null ||
            notesSearchDigest(buffer.text) != match.digest ||
            match.endOffset > buffer.text.length) {
          unavailable();
          return;
        }
        revealOpenedDocument(ref);
        ref
            .read(notesMatchNavigationProvider.notifier)
            .navigate(
              buffer.remoteNote?.localId ?? buffer.filePath ?? buffer.id,
              match.startOffset,
              match.endOffset,
              match.digest,
              accountId: buffer.remoteNote?.accountId,
            );
      case NoteSearchResult(:final accountId, :final hit, :final recovery):
        final repo = await ref.read(nextcloudNotesRepositoryProvider.future);
        final note = repo.noteById(hit.localId);
        if (!context.mounted ||
            !currentRequest() ||
            ref
                    .read(workspaceControllerProvider)
                    .workspace
                    ?.nextcloudAccountId !=
                accountId ||
            note?.accountId != accountId ||
            isNotesRecovery(note!) != recovery) {
          unavailable();
          return;
        }
        if (recovery) {
          session.close(restoreFocus: false);
          await showNotesRecovery(context, ref, note);
          return;
        }
        if (!await controller.openNextcloudNote(
              hit.localId,
              acceptNavigation: currentRequest,
            ) ||
            !context.mounted ||
            !currentRequest()) {
          return;
        }
        final buffer = ref.read(workspaceControllerProvider).activeBuffer;
        if (buffer?.remoteNote?.accountId != accountId ||
            buffer?.remoteNote?.localId != hit.localId ||
            notesSearchDigest(buffer!.text) != hit.digest) {
          unavailable();
          return;
        }
        if (source) {
          controller.updateActiveEditorMode(DocumentViewModePreference.source);
          await ref
              .read(appSettingsControllerProvider.notifier)
              .setDocumentViewMode(DocumentViewModePreference.source);
          if (!context.mounted || !currentRequest()) return;
        }
        revealOpenedDocument(ref);
        if (hit.start != null && hit.end != null) {
          ref
              .read(notesMatchNavigationProvider.notifier)
              .navigate(
                hit.localId,
                hit.start!,
                hit.end!,
                hit.digest,
                accountId: accountId,
              );
        }
    }
  } finally {
    guard.busy = false;
  }
}
