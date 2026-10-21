import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/notes_models.dart';
import 'nextcloud_connection.dart';

enum NotesSettingsFailure {
  buffersNotSaved,
  operation,
  stale,
  pendingNotes,
  pendingAttachments,
}

enum NotesSettingsPhase { loading, ready, saving, saved, failed }

class NotesSettingsState {
  const NotesSettingsState({
    this.accountId,
    this.original,
    this.draft,
    this.phase = NotesSettingsPhase.loading,
    this.error,
    this.normalized = false,
    this.failure,
    this.refreshFailed = false,
    this.cause,
    this.refreshing = false,
  });
  final String? accountId;
  final NotesSettings? original;
  final NotesSettings? draft;
  final NotesSettingsPhase phase;
  final String? error;
  final bool normalized;
  final NotesSettingsFailure? failure;
  final bool refreshFailed;
  final Object? cause;
  final bool refreshing;
  Map<String, String> get patch => {
    if (draft != null &&
        original != null &&
        draft!.notesPath != original!.notesPath)
      'notesPath': draft!.notesPath,
    if (draft != null &&
        original != null &&
        draft!.fileSuffix != original!.fileSuffix)
      'fileSuffix': draft!.fileSuffix,
  };
  bool get dirty => patch.isNotEmpty;
  bool get busy =>
      phase == NotesSettingsPhase.loading || phase == NotesSettingsPhase.saving;
}

final notesSettingsProvider =
    NotifierProvider.autoDispose<NotesSettingsController, NotesSettingsState>(
      NotesSettingsController.new,
    );

class NotesSettingsController extends Notifier<NotesSettingsState> {
  int _generation = 0;
  bool _disposed = false;
  @override
  NotesSettingsState build() {
    ref.onDispose(() {
      _disposed = true;
      _generation++;
    });
    return const NotesSettingsState();
  }

  Future<void> load(String id, {bool discard = false}) async {
    if (state.accountId == id &&
        (state.phase == NotesSettingsPhase.saving ||
            (state.dirty && !discard))) {
      return;
    }
    final generation = ++_generation;
    final previous = state;
    state = NotesSettingsState(
      accountId: id,
      original: previous.original,
      draft: previous.draft,
    );
    try {
      final repository = await ref.read(
        nextcloudNotesRepositoryProvider.future,
      );
      await repository.maintainCapabilities(id);
      if (_disposed ||
          generation != _generation ||
          repository.accountById(id) == null) {
        return;
      }
      final settings = await repository.reconcileSettings(id);
      if (_disposed ||
          generation != _generation ||
          repository.accountById(id) == null) {
        return;
      }
      state = NotesSettingsState(
        accountId: id,
        original: settings,
        draft: settings,
        phase: NotesSettingsPhase.ready,
      );
    } on Object catch (error) {
      if (_disposed || generation != _generation) return;
      state = NotesSettingsState(
        accountId: id,
        original: previous.original,
        draft: previous.draft,
        phase: NotesSettingsPhase.failed,
        error: error.toString(),
        cause: error,
        failure: NotesSettingsFailure.operation,
      );
    }
  }

  void edit({String? notesPath, String? fileSuffix}) {
    final draft = state.draft;
    if (draft == null || state.busy) return;
    state = NotesSettingsState(
      accountId: state.accountId,
      original: state.original,
      draft: NotesSettings(
        notesPath: notesPath ?? draft.notesPath,
        fileSuffix: fileSuffix ?? draft.fileSuffix,
      ),
      phase: NotesSettingsPhase.ready,
      refreshing: state.refreshing,
    );
  }

  void cancel() {
    if (state.busy) return;
    state = NotesSettingsState(
      accountId: state.accountId,
      original: state.original,
      draft: state.original,
      phase: NotesSettingsPhase.ready,
    );
  }

  Future<bool> save({required Future<bool> Function() preserveBuffers}) async {
    final id = state.accountId;
    final original = state.original;
    final patch = state.patch;
    if (id == null || original == null || patch.isEmpty || state.busy) {
      return false;
    }
    final generation = ++_generation;
    final draft = state.draft;
    state = NotesSettingsState(
      accountId: id,
      original: original,
      draft: draft,
      phase: NotesSettingsPhase.saving,
    );
    try {
      if (!await preserveBuffers()) {
        if (!_disposed && generation == _generation) {
          state = NotesSettingsState(
            accountId: id,
            original: original,
            draft: draft,
            phase: NotesSettingsPhase.failed,
            failure: NotesSettingsFailure.buffersNotSaved,
          );
        }
        return false;
      }
      if (_disposed || generation != _generation) return false;
      final repository = await ref.read(
        nextcloudNotesRepositoryProvider.future,
      );
      final result = await repository.changeSettings(id, original, patch);
      if (_disposed ||
          generation != _generation ||
          repository.accountById(id) == null) {
        return false;
      }
      state = NotesSettingsState(
        accountId: id,
        original: result,
        draft: result,
        phase: NotesSettingsPhase.saved,
        refreshing: true,
        normalized: patch.entries.any((e) => result.toJson()[e.key] != e.value),
      );
      // Checkpoint invalidation is durable before this authoritative read.
      var refreshFailed = false;
      try {
        await repository.synchronize(id, allowWrites: false);
      } on Object {
        refreshFailed = true;
      }
      if (_disposed || generation != _generation) return false;
      // The acknowledged response is already the baseline. Refresh owns only
      // its progress/warning, never input entered since that acknowledgement.
      state = NotesSettingsState(
        accountId: state.accountId,
        original: state.original,
        draft: state.draft,
        phase: state.phase,
        normalized: state.normalized,
        error: state.error,
        cause: state.cause,
        failure: state.failure,
        refreshFailed: refreshFailed,
      );
      return state.accountId == id && !state.dirty;
    } on Object catch (error) {
      if (!_disposed && generation == _generation) {
        state = NotesSettingsState(
          accountId: id,
          original: original,
          draft: draft,
          phase: NotesSettingsPhase.failed,
          error: error.toString(),
          cause: error,
          failure: switch (error) {
            NotesSettingsConflict(reason: NotesSettingsConflictReason.stale) =>
              NotesSettingsFailure.stale,
            NotesSettingsConflict(
              reason: NotesSettingsConflictReason.pendingNotes,
            ) =>
              NotesSettingsFailure.pendingNotes,
            NotesSettingsConflict(
              reason: NotesSettingsConflictReason.pendingAttachments,
            ) =>
              NotesSettingsFailure.pendingAttachments,
            _ => NotesSettingsFailure.operation,
          },
        );
      }
      return false;
    }
  }
}
