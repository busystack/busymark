import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../app/app_settings.dart';
import '../comparison/source_comparison.dart';
import '../core/debug_log.dart';
import '../core/anchored_path_guard.dart';
import '../core/atomic_file_writer.dart';
import '../core/busymark_temporary_path.dart';
import '../core/busymark_exception.dart';
import '../core/diagnostic.dart';
import '../core/source_span.dart';
import '../core/path_utils.dart' show isTextDocumentationPath;
import '../editor/wysiwyg/wysiwyg_session_state.dart';
import '../markdown/busymark_document.dart';
import '../markdown/document_outline.dart';
import '../markdown/preview_model.dart';
import '../local_history/local_history_controller.dart';
import '../local_history/local_history_models.dart';
import '../nextcloud_notes/domain/notes_models.dart';
import '../nextcloud_notes/domain/notes_conflict.dart';
import '../nextcloud_notes/application/notes_repository.dart';
import '../nextcloud_notes/application/nextcloud_connection.dart';
import '../nextcloud_notes/application/notes_media.dart';
import '../export/markdown_copy_export_service.dart';
import '../writerside/writerside_project_creator.dart';
import '../writerside/writerside_project.dart';
import '../writerside/writerside_model.dart';
import '../writerside/writerside_input_snapshot.dart';
import '../writerside/writerside_instance_service.dart';
import '../writerside/writerside_topic_removal_service.dart';
import '../writerside/writerside_topic_creator.dart';
import '../writerside/writerside_topic_file_editor.dart';
import '../writerside/writerside_toc_editor.dart';
import '../writerside/writerside_title_editor.dart';
import 'document_buffer.dart';
import 'recovery_persistence.dart';
import 'session_persistence.dart';
import 'text_format_metadata.dart';
import 'workspace_model.dart';
import 'workspace_message.dart';
import 'workspace_file_monitor.dart';
import 'workspace_service.dart';

final workspaceServiceProvider = Provider<WorkspaceService>(
  (ref) => const WorkspaceService(),
);

enum LocalHistoryCurrentSourceKind { editor, disk, missing }

class LocalHistoryCurrentSourceSnapshot {
  const LocalHistoryCurrentSourceSnapshot({
    required this.kind,
    required this.id,
    required this.version,
    required this.source,
    required this.canRestore,
  });

  final LocalHistoryCurrentSourceKind kind;
  final String id;
  final int version;
  final String source;
  final bool canRestore;
}

final documentSessionStoreProvider = Provider<DocumentSessionStore>(
  (ref) => _runningUnderFlutterTest
      ? MemoryDocumentSessionStore()
      : JsonDocumentSessionStore(),
);

final documentRecoveryStoreProvider = Provider<DocumentRecoveryStore>(
  (ref) => _runningUnderFlutterTest
      ? MemoryDocumentRecoveryStore()
      : JsonDocumentRecoveryStore(),
);

final _runningUnderFlutterTest = Platform.environment.containsKey(
  'FLUTTER_TEST',
);

final documentPersistenceDelayProvider = Provider<Duration>(
  (ref) => _runningUnderFlutterTest
      ? Duration.zero
      : const Duration(milliseconds: 700),
);

bool _sameRuntimeDiagnostics(List<Diagnostic> left, List<Diagnostic> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index++) {
    if (left[index].code != right[index].code ||
        left[index].filePath != right[index].filePath ||
        left[index].args['runtimeMathKey'] !=
            right[index].args['runtimeMathKey']) {
      return false;
    }
  }
  return true;
}

final workspaceFileMonitorProvider = Provider<WorkspaceFileMonitor>((ref) {
  final monitor = WorkspaceFileMonitor();
  ref.onDispose(() => unawaited(monitor.dispose()));
  return monitor;
});

class _QueuedFileMonitorEvent {
  const _QueuedFileMonitorEvent(this.event, this.workspaceGeneration);

  final WorkspaceFileMonitorEvent event;
  final int workspaceGeneration;
}

final workspaceControllerProvider =
    NotifierProvider<WorkspaceController, WorkspaceState>(
      WorkspaceController.new,
    );

final workspaceSearchOpenRequestProvider =
    NotifierProvider<WorkspaceSearchRequestController, int>(
      WorkspaceSearchRequestController.new,
    );

final workspaceSearchCloseRequestProvider =
    NotifierProvider<WorkspaceSearchRequestController, int>(
      WorkspaceSearchRequestController.new,
    );

/// Identifies the exact editor revision that an asynchronous save-related
/// operation was started for.
///
/// The constructor is private so callers can only obtain a target from the
/// controller that owns the revision counters. Passing the same target through
/// disk checks and confirmation UI prevents a later active tab from inheriting
/// an earlier tab's save or discard approval.
class ActiveDocumentSaveTarget {
  const ActiveDocumentSaveTarget._({
    required this.workspaceId,
    required this.bufferId,
    required this.path,
    required this.documentRevision,
    required this.editRevision,
    required this.snapshot,
    required this.text,
    required this.workspaceKind,
    required this.format,
  });

  final String workspaceId;
  final String bufferId;
  final String? path;
  final int documentRevision;
  final int editRevision;
  final WorkspaceFileSnapshot? snapshot;
  final String text;
  final WorkspaceKind workspaceKind;
  final TextFormatMetadata format;

  bool get needsSaveLocation =>
      path == null && workspaceKind != WorkspaceKind.nextcloudNotes;
}

class SaveAllResult {
  const SaveAllResult({
    this.savedBufferIds = const [],
    this.failedBufferIds = const [],
    this.conflictBufferIds = const [],
    this.normalizationRequiredBufferIds = const [],
  });

  final List<String> savedBufferIds;
  final List<String> failedBufferIds;
  final List<String> conflictBufferIds;
  final List<String> normalizationRequiredBufferIds;

  bool get succeeded =>
      failedBufferIds.isEmpty &&
      conflictBufferIds.isEmpty &&
      normalizationRequiredBufferIds.isEmpty;
}

enum _BufferWriteResult { saved, failed, conflict }

class WorkspaceSearchRequestController extends Notifier<int> {
  @override
  int build() => 0;

  void request() {
    state++;
  }
}

enum ValidationStatus { published, stale, failed, busy, unavailable }

class ValidationOutcome {
  const ValidationOutcome({
    required this.status,
    this.workspaceId,
    this.filePath,
    this.bufferId,
    this.revision,
    this.documentRevision,
  });

  final ValidationStatus status;
  final String? workspaceId;
  final String? filePath;
  final String? bufferId;
  final int? revision;
  final int? documentRevision;
  bool get published => status == ValidationStatus.published;
}

class WorkspaceController extends Notifier<WorkspaceState> {
  static const _autoSaveDelay = Duration(milliseconds: 1500);

  late WorkspaceService _service;
  late AppSettingsController _settingsController;
  late DocumentSessionStore _sessionStore;
  late DocumentRecoveryStore _recoveryStore;
  late WorkspaceFileMonitor _fileMonitor;
  late LocalHistoryController _localHistory;
  NotesRepository? _notesRepository;
  StreamSubscription<void>? _notesSubscription;
  final _remoteSyncTasks = <String, Future<void>>{};
  final _remoteSyncRequested = <String>{};
  final _remoteRetryTimers = <String, Timer>{};
  final _remoteRetryCounts = <String, int>{};
  final _remoteDurabilityWrites = <String, int>{};
  var _restoringLocalHistorySession = false;
  StreamSubscription<WorkspaceFileMonitorEvent>? _fileMonitorSubscription;
  Future<void>? _fileMonitorLifecycle;
  final _pendingFileMonitorEvents = <_QueuedFileMonitorEvent>[];
  Timer? _fileMonitorDrainTimer;
  var _fileMonitorDrainRunning = false;
  final _autoSaveDebounces = <String, Timer>{};
  final _bufferWriteQueues = <String, Future<void>>{};
  Timer? _persistenceDebounce;
  Timer? _workspaceRefreshDebounce;
  var _derivedRefreshRunning = false;
  var _derivedRefreshPending = false;
  var _pendingPreviewRefresh = false;
  var _pendingOutlineRefresh = false;
  _ActivePreviewRevision? _activePreviewRevision;
  var _manualValidationRunning = false;
  var _validationSequence = 0;
  var _editRevision = 0;
  var _activeDocumentRevision = 0;
  // Removal follows workspace/request lifetime, not active-tab navigation.
  var _removalOperationRevision = 0;
  var _workspaceRefreshRevision = 0;
  var _workspaceDiskRevision = 0;
  var _fileMonitorWorkspaceGeneration = 0;
  var _acceptFileMonitorEvents = false;
  _ReconciledFileNotifications? _reconciledNotifications;
  int _preparationsRunning = 0;
  _PendingPreparation? _pendingPreparation;
  int? _acceptedRefreshRevision;
  final _preparedInputs = Expando<_PreparedDocumentInputs>();
  var _workspaceFileOperationDepth = 0;
  int? _fileOperationNavigationRevision;
  final _deferredFileMonitorEvents = <_QueuedFileMonitorEvent>[];
  var _untitledSequence = 0;
  final _removalAuthorizations = <String, _RemovalBufferAuthorization>{};
  final _historyOperationsAwaitingWorkspaceRefresh = <String>{};
  final _saveAsSessionBindings =
      <String, ({String operationId, String workspaceId})>{};
  final _restoredRecoveryOwnerIdsByBuffer = <String, String>{};

  late Future<RecoverySnapshot> _recoveryStart;
  Future<void> _persistenceWrites = Future.value();

  int get editRevision => state.activeBuffer?.revision ?? _editRevision;

  void updateMathRenderDiagnostic({
    required String expressionId,
    required String? code,
    SourceSpan? sourceSpan,
    int? expectedRevision,
    String? expectedFilePath,
  }) {
    final workspace = state.workspace;
    if (workspace == null ||
        (expectedRevision != null &&
            (expectedRevision != editRevision ||
                expectedFilePath != workspace.activeFilePath))) {
      return;
    }
    final filePath =
        sourceSpan?.filePath ??
        workspace.activeFilePath ??
        state.activeBuffer?.identity ??
        workspace.filesystemRootPath ??
        '';
    final runtimeKey = '$filePath\u0000$expressionId';
    final diagnostics = [
      for (final diagnostic in workspace.runtimeDiagnostics)
        if (diagnostic.args['runtimeMathKey'] != runtimeKey) diagnostic,
      if (code != null)
        Diagnostic(
          code: code,
          severity: DiagnosticSeverity.error,
          filePath: filePath,
          sourceSpan: sourceSpan,
          args: {'runtimeMathKey': runtimeKey},
        ),
    ];
    if (_sameRuntimeDiagnostics(workspace.runtimeDiagnostics, diagnostics)) {
      return;
    }
    state = state.copyWith(
      workspace: workspace.copyWith(
        runtimeDiagnostics: List.unmodifiable(diagnostics),
      ),
    );
  }

  @override
  WorkspaceState build() {
    _service = ref.read(workspaceServiceProvider);
    _settingsController = ref.read(appSettingsControllerProvider.notifier);
    _sessionStore = ref.read(documentSessionStoreProvider);
    _recoveryStore = ref.read(documentRecoveryStoreProvider);
    _fileMonitor = ref.read(workspaceFileMonitorProvider);
    _localHistory = ref.read(localHistoryControllerProvider.notifier);
    _localHistory.setDurableStatePersistence(() async {
      if (!ref.mounted || _restoringLocalHistorySession) return false;
      await flushPersistence();
      return true;
    });
    _fileMonitorSubscription = _fileMonitor.events.listen(
      _queueFileMonitorEvent,
    );
    _recoveryStart = _recoveryStore.beginRun();
    ref.listen<AppSettings>(appSettingsControllerProvider, (previous, next) {
      if (!next.autoSave) {
        _cancelAllAutoSaves();
        return;
      }
      if (state.dirtyBuffers.any((buffer) => !buffer.isUntitled)) {
        _scheduleAutoSave();
      }
    });
    ref.onDispose(() {
      _fileMonitorWorkspaceGeneration++;
      _removalOperationRevision++;
      _cancelPendingDerivedRefresh();
      _cancelAllAutoSaves();
      _persistenceDebounce?.cancel();
      _workspaceRefreshDebounce?.cancel();
      _fileMonitorDrainTimer?.cancel();
      _pendingFileMonitorEvents.clear();
      _restoredRecoveryOwnerIdsByBuffer.clear();
      unawaited(_fileMonitorSubscription?.cancel());
      unawaited(_notesSubscription?.cancel());
      for (final timer in _remoteRetryTimers.values) {
        timer.cancel();
      }
    });
    return const WorkspaceState();
  }

  void _queueFileMonitorEvent(WorkspaceFileMonitorEvent event) {
    if (!_acceptFileMonitorEvents) return;
    _queueCapturedFileMonitorEvent(
      _QueuedFileMonitorEvent(event, _fileMonitorWorkspaceGeneration),
    );
  }

  void _queueCapturedFileMonitorEvent(_QueuedFileMonitorEvent event) {
    if (!_fileMonitorOperationIsCurrent(event.workspaceGeneration)) return;
    _pendingFileMonitorEvents.add(event);
    if (_fileMonitorDrainRunning || _fileMonitorDrainTimer != null) return;
    _fileMonitorDrainTimer = Timer(Duration.zero, () {
      _fileMonitorDrainTimer = null;
      unawaited(_drainFileMonitorEvents());
    });
  }

  Future<void> _drainFileMonitorEvents() async {
    if (_fileMonitorDrainRunning) return;
    _fileMonitorDrainRunning = true;
    try {
      while (ref.mounted && _pendingFileMonitorEvents.isNotEmpty) {
        var queued = _pendingFileMonitorEvents.removeAt(0);
        var event = queued.event;
        while (event.kind == WorkspaceFileEventKind.moved &&
            event.destinationPath != null &&
            _pendingFileMonitorEvents.isNotEmpty) {
          // WorkspaceFileMonitor preserves insertion order by source path, so
          // an event in another namespace may sit between two legs of one
          // already-committed move chain. Follow the first queued event whose
          // source is the current destination without consuming unrelated
          // work; otherwise A -> B can be treated as a deletion after the
          // filesystem has already advanced B -> C.
          final nextIndex = _pendingFileMonitorEvents.indexWhere(
            (candidate) =>
                candidate.workspaceGeneration == queued.workspaceGeneration &&
                candidate.event.isDirectory == event.isDirectory &&
                p.equals(candidate.event.path, event.destinationPath!) &&
                (candidate.event.kind == WorkspaceFileEventKind.moved ||
                    candidate.event.kind == WorkspaceFileEventKind.deleted),
          );
          if (nextIndex < 0) break;
          final next = _pendingFileMonitorEvents[nextIndex].event;
          if (next.kind == WorkspaceFileEventKind.moved &&
              next.destinationPath != null) {
            _pendingFileMonitorEvents.removeAt(nextIndex);
            event = WorkspaceFileMonitorEvent(
              kind: WorkspaceFileEventKind.moved,
              path: event.path,
              destinationPath: next.destinationPath,
              isDirectory: event.isDirectory,
            );
          } else if (next.kind == WorkspaceFileEventKind.deleted) {
            _pendingFileMonitorEvents.removeAt(nextIndex);
            event = WorkspaceFileMonitorEvent(
              kind: WorkspaceFileEventKind.deleted,
              path: event.path,
              isDirectory: event.isDirectory,
            );
          } else {
            break;
          }
        }
        await _handleFileMonitorEvent(event, queued.workspaceGeneration);
      }
    } finally {
      _fileMonitorDrainRunning = false;
      if (ref.mounted &&
          _pendingFileMonitorEvents.isNotEmpty &&
          _fileMonitorDrainTimer == null) {
        _fileMonitorDrainTimer = Timer(Duration.zero, () {
          _fileMonitorDrainTimer = null;
          unawaited(_drainFileMonitorEvents());
        });
      }
    }
  }

  Future<NotesRepository> _ensureNotesRepository() async {
    if (_notesRepository case final repository?) return repository;
    final repository = await ref.read(nextcloudNotesRepositoryProvider.future);
    await repository.initialize();
    if (!ref.mounted) throw StateError('Workspace closed');
    _notesRepository = repository;
    bool bindingGuard(String localId, Set<String> ids) =>
        !state.documentBuffers.any(
          (b) =>
              ids.contains(b.remoteNote?.localId) ||
              (b.remoteNote?.localId == localId && b.isDirty),
        );
    repository.addCreationBindingGuard(bindingGuard);
    ref.onDispose(() => repository.removeCreationBindingGuard(bindingGuard));
    _notesSubscription = repository.changes.listen((_) => _notesChanged());
    return repository;
  }

  DocumentBuffer _remoteBuffer(
    NextcloudNote note, {
    DocumentEditorState? editorState,
  }) => DocumentBuffer.nextcloud(
    reference: NextcloudNoteReference(
      accountId: note.accountId,
      localId: note.localId,
    ),
    title: note.title,
    content: note.content,
    revision: note.revision,
    editBase: _notesRepository?.editorBase(note.localId),
    readonly: note.readonly || note.error,
    editorState: editorState ?? const DocumentEditorState(),
  );

  DocumentEditorState _remoteEditorState(
    DocumentBuffer buffer,
    String content,
  ) => buffer.editorState.copyWith(
    selection: buffer.editorState.selection.copyWith(
      baseOffset: buffer.editorState.selection.baseOffset.clamp(
        0,
        content.length,
      ),
      extentOffset: buffer.editorState.selection.extentOffset.clamp(
        0,
        content.length,
      ),
    ),
  );

  void _notesChanged() {
    if (!ref.mounted || state.workspace?.isRemote != true) return;
    final repository = _notesRepository;
    if (repository == null) return;
    var contentChanged = false;
    final buffers = <DocumentBuffer>[];
    for (final buffer in state.documentBuffers) {
      final reference = buffer.remoteNote;
      if (reference == null) {
        buffers.add(buffer);
        continue;
      }
      final note = repository.noteById(reference.localId);
      if (note == null) {
        // Repository deletes only after the remote outcome is established.
        // An editor revision that arrived meanwhile retains its tab for recovery.
        if (buffer.isDirty) buffers.add(buffer);
        continue;
      }
      if (note.syncState == NoteSyncState.deletedRemotely &&
          !note.hasPendingChanges &&
          !buffer.isDirty) {
        continue;
      }
      if (buffer.isDirty) {
        final text = repository.resolvePublishedReferences(
          note.localId,
          buffer.text,
        );
        contentChanged |= text != buffer.text;
        buffers.add(
          buffer.copyWith(
            text: text,
            editorState: _remoteEditorState(buffer, text),
            remoteTitle: note.title,
            readonly: note.readonly || note.error,
            revision: text == buffer.text
                ? buffer.revision
                : math.max(buffer.revision, note.revision) + 1,
          ),
        );
      } else {
        contentChanged |= note.content != buffer.text;
        buffers.add(
          buffer.copyWith(
            text: note.content,
            editorState: _remoteEditorState(buffer, note.content),
            lastSavedText: note.content,
            remoteEditBase: repository.editorBase(note.localId),
            revision: note.content == buffer.text
                ? math.max(buffer.revision, note.revision)
                : math.max(buffer.revision, note.revision) + 1,
            remoteTitle: note.title,
            readonly: note.readonly || note.error,
          ),
        );
      }
    }
    final activeId = buffers.any((b) => b.id == state.activeBufferId)
        ? state.activeBufferId
        : buffers.firstOrNull?.id;
    if (activeId != state.activeBufferId) {
      _cancelPendingDerivedRefresh();
      _invalidateActiveDocumentOperations();
      final workspace = state.workspace!.copyWith(
        markdown: null,
        runtimeDiagnostics: const [],
      );
      state = state.copyWith(
        workspace: workspace,
        documentBuffers: buffers,
        activeBufferId: activeId,
        preview: null,
        liveOutline: null,
      );
      _activePreviewRevision = null;
      if (activeId != null) {
        unawaited(
          _activateBuffer(
            workspace,
            buffers.firstWhere((buffer) => buffer.id == activeId),
            documentBuffers: buffers,
            openFilePaths: const [],
          ).catchError((Object error) {
            _reportNextcloudFailure(error);
            return false;
          }),
        );
      } else {
        _schedulePersistence();
      }
      return;
    }
    state = state.copyWith(documentBuffers: buffers, activeBufferId: activeId);
    if (contentChanged) {
      _requestDerivedRefresh(
        rebuildPreview: _activeModeShowsPreview,
        refreshOutline: !_activeModeShowsPreview,
      );
    }
  }

  Future<bool> openNextcloudWorkspace(
    String accountId, {
    List<DocumentSessionEntry>? restoredTabs,
    String? activeBufferId,
  }) async {
    if (state.hasUnsavedChanges) return false;
    final prior = state;
    final priorRevision = _activeDocumentRevision;
    try {
      final repository = await _ensureNotesRepository();
      if (!repository.accounts.any((account) => account.id == accountId)) {
        return false;
      }
      final settled = await _localHistory.flushAll(prior.documentBuffers);
      if (!ref.mounted ||
          priorRevision != _activeDocumentRevision ||
          !identical(prior.workspace, state.workspace) ||
          state.hasUnsavedChanges) {
        return false;
      }
      _cancelPendingDerivedRefresh();
      _cancelAllAutoSaves();
      _invalidateActiveDocumentOperations();
      await _fileMonitor.stop();
      for (final buffer in prior.documentBuffers) {
        await _localHistory.handleBufferClosed(
          buffer.id,
          historySettled: settled,
        );
      }
      final workspace = Workspace.nextcloudNotes(accountId);
      final buffers = <DocumentBuffer>[];
      for (final tab in restoredTabs ?? const <DocumentSessionEntry>[]) {
        final reference = tab.remoteNote;
        if (reference == null || reference.accountId != accountId) continue;
        final note = repository.noteById(reference.localId);
        if (note != null &&
            (note.syncState != NoteSyncState.deletedRemotely ||
                note.hasPendingChanges)) {
          buffers.add(_remoteBuffer(note, editorState: tab.editorState));
        }
      }
      if (buffers.isEmpty && restoredTabs == null) {
        final first = repository.notes
            .where(
              (note) =>
                  note.accountId == accountId &&
                  (note.syncState != NoteSyncState.deletedRemotely ||
                      note.hasPendingChanges),
            )
            .firstOrNull;
        if (first != null) buffers.add(_remoteBuffer(first));
      }
      state = WorkspaceState(
        workspace: workspace,
        documentBuffers: buffers,
        activeBufferId: buffers.any((buffer) => buffer.id == activeBufferId)
            ? activeBufferId
            : buffers.firstOrNull?.id,
      );
      for (final buffer in buffers) {
        unawaited(_localHistory.observeOpened(buffer));
      }
      if (state.activeBuffer case final buffer?) {
        await _activateBuffer(
          workspace,
          buffer,
          documentBuffers: buffers,
          openFilePaths: const [],
        );
      }
      _schedulePersistence();
      _scheduleRemoteSync(accountId);
      return true;
    } on Object catch (error) {
      if (ref.mounted) {
        state = state.copyWith(
          message: WorkspaceMessage(
            WorkspaceMessageCode.couldNotOpenFile,
            error: error,
          ),
        );
      }
      return false;
    }
  }

  Future<bool> openNextcloudNote(String localId) async {
    final repository = await _ensureNotesRepository();
    final note = repository.noteById(localId);
    final workspace = state.workspace;
    if (note == null ||
        repository.isCreationCandidateBinding(localId) ||
        workspace?.nextcloudAccountId != note.accountId) {
      return false;
    }
    final existing = state.documentBuffers
        .where((buffer) => buffer.remoteNote?.localId == localId)
        .firstOrNull;
    final buffer = existing ?? _remoteBuffer(note);
    if (existing == null) {
      // Navigation validates the live buffer after asynchronous parsing. Publish
      // the new logical tab first so that validation can retain newer edits.
      state = state.copyWith(
        documentBuffers: [...state.documentBuffers, buffer],
      );
    }
    final result = await _activateBuffer(
      workspace!,
      buffer,
      documentBuffers: state.documentBuffers,
      openFilePaths: const [],
    );
    if (result && existing == null) {
      unawaited(_localHistory.observeOpened(buffer));
    }
    return result;
  }

  Future<bool> createNextcloudNote({
    String title = 'New note',
    String category = '',
    String content = '',
  }) async {
    try {
      final accountId = state.workspace?.nextcloudAccountId;
      if (accountId == null) return false;
      final repository = await _ensureNotesRepository();
      final note = await repository.create(
        accountId,
        title: title,
        category: category,
        content: content,
      );
      final opened = await openNextcloudNote(note.localId);
      _scheduleRemoteSync(accountId);
      return opened;
    } on Object catch (error) {
      _reportNextcloudFailure(error);
      return false;
    }
  }

  void _reportNextcloudFailure(Object error) {
    if (ref.mounted) {
      state = state.copyWith(
        message: WorkspaceMessage(
          WorkspaceMessageCode.saveFailed,
          error: error,
        ),
      );
    }
  }

  Future<bool> _saveRemoteBufferSnapshot(
    DocumentBuffer target, {
    bool scheduleSync = true,
    bool captureHistory = true,
  }) async {
    final reference = target.remoteNote;
    if (reference == null) return false;
    _remoteDurabilityWrites.update(
      target.id,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
    try {
      final repository = await _ensureNotesRepository();
      final saved = await repository.save(
        reference.localId,
        content: target.text,
        editorRevision: target.revision,
        editBase: target.remoteEditBase,
      );
      final latest = state.documentBuffers
          .where((b) => b.id == target.id)
          .firstOrNull;
      if (ref.mounted && latest != null && latest.remoteNote == reference) {
        final unchanged =
            latest.revision == target.revision && latest.text == target.text;
        final text = unchanged
            ? saved.content
            : repository.resolvePublishedReferences(
                reference.localId,
                latest.text,
              );
        state = state.copyWith(
          documentBuffers: _replaceBuffer(
            state.documentBuffers,
            latest.copyWith(
              text: text,
              editorState: _remoteEditorState(latest, text),
              lastSavedText: saved.content,
              remoteEditBase: unchanged
                  ? repository.editorBase(reference.localId)
                  : latest.remoteEditBase,
              dirty: text != saved.content,
              revision: unchanged
                  ? saved.revision
                  : math.max(latest.revision, saved.revision + 1),
              remoteTitle: saved.title,
              readonly: saved.readonly || saved.error,
            ),
          ),
        );
        if (text != latest.text) {
          _requestDerivedRefresh(
            rebuildPreview: _activeModeShowsPreview,
            refreshOutline: !_activeModeShowsPreview,
          );
        }
      }
      if (captureHistory) {
        await _localHistory.captureSaved(
          LocalHistoryBufferSnapshot.fromBuffer(
            target.copyWith(text: saved.content, remoteTitle: saved.title),
          ),
        );
      }
      if (scheduleSync) {
        _scheduleRemoteSync(reference.accountId);
      }
      return true;
    } on Object catch (error) {
      if (ref.mounted) {
        state = state.copyWith(
          message: WorkspaceMessage(
            WorkspaceMessageCode.saveFailed,
            error: error,
          ),
        );
      }
      return false;
    } finally {
      final remaining = (_remoteDurabilityWrites[target.id] ?? 1) - 1;
      if (remaining == 0) {
        _remoteDurabilityWrites.remove(target.id);
      } else {
        _remoteDurabilityWrites[target.id] = remaining;
      }
    }
  }

  void _scheduleRemoteSync(String accountId, {bool automaticRetry = false}) {
    if (!ref.mounted) return;
    _remoteRetryTimers.remove(accountId)?.cancel();
    if (!automaticRetry) _remoteRetryCounts.remove(accountId);
    _remoteSyncRequested.add(accountId);
    if (_remoteSyncTasks.containsKey(accountId)) return;
    final task = () async {
      do {
        _remoteSyncRequested.remove(accountId);
        try {
          await (await _ensureNotesRepository()).synchronize(accountId);
        } on Object catch (error) {
          if (ref.mounted && state.workspace?.nextcloudAccountId == accountId) {
            state = state.copyWith(
              message: WorkspaceMessage(
                WorkspaceMessageCode.saveFailed,
                error: error,
              ),
            );
          }
        }
        // An edit committed during the request schedules one more pass. Network
        // failures do not request a pass, so this cannot spin on server locks.
      } while (ref.mounted && _remoteSyncRequested.contains(accountId));
      _remoteSyncTasks.remove(accountId);
      _scheduleRemoteRetry(accountId);
    }();
    _remoteSyncTasks[accountId] = task;
    unawaited(task);
  }

  void _scheduleRemoteRetry(String accountId) {
    if (!ref.mounted || state.workspace?.nextcloudAccountId != accountId) {
      return;
    }
    final repository = _notesRepository;
    if (repository == null) return;
    final accountError = repository.accountError(accountId);
    final retryable =
        accountError?.code == NotesFailureCode.network ||
        accountError?.code == NotesFailureCode.server ||
        repository.notes.any(
          (note) =>
              note.accountId == accountId &&
              note.hasPendingChanges &&
              {
                NoteSyncState.offline,
                NoteSyncState.locked,
                NoteSyncState.pending,
              }.contains(note.syncState),
        );
    if (!retryable) {
      _remoteRetryCounts.remove(accountId);
      return;
    }
    final attempt = _remoteRetryCounts[accountId] ?? 0;
    // Six delayed attempts, then explicit Refresh remains available. Creation
    // uncertainty, conflicts, keyring/authentication and forbidden errors never
    // trigger an automatic retry.
    if (attempt >= 6) return;
    _remoteRetryCounts[accountId] = attempt + 1;
    _remoteRetryTimers[accountId] = Timer(
      Duration(seconds: math.min(300, 5 * (1 << attempt))),
      () {
        _remoteRetryTimers.remove(accountId);
        if (ref.mounted && state.workspace?.nextcloudAccountId == accountId) {
          _scheduleRemoteSync(accountId, automaticRetry: true);
        }
      },
    );
  }

  Future<void> refreshNextcloudNotes() async {
    final account = state.workspace?.nextcloudAccountId;
    if (account != null) {
      _remoteRetryTimers.remove(account)?.cancel();
      _remoteRetryCounts.remove(account);
      await (await _ensureNotesRepository()).synchronize(account);
      _scheduleRemoteRetry(account);
    }
  }

  Future<void> updateNextcloudNoteMetadata(
    String localId, {
    String? title,
    String? category,
    bool? favorite,
  }) async {
    try {
      final repository = await _ensureNotesRepository();
      final buffer = state.documentBuffers
          .where((b) => b.remoteNote?.localId == localId)
          .firstOrNull;
      if (buffer?.isDirty == true &&
          !await _saveRemoteBufferSnapshot(buffer!)) {
        return;
      }
      final note = repository.noteById(localId);
      if (note == null) return;
      await repository.save(
        localId,
        content: note.content,
        title: title,
        category: category,
        favorite: favorite,
      );
      _scheduleRemoteSync(note.accountId);
    } on Object catch (error) {
      _reportNextcloudFailure(error);
    }
  }

  Future<bool> deleteNextcloudNote(String localId) async {
    try {
      final repository = await _ensureNotesRepository();
      final note = repository.noteById(localId);
      if (note == null) return false;
      final buffer = state.documentBuffers
          .where((b) => b.remoteNote?.localId == localId)
          .firstOrNull;
      if (buffer?.isDirty == true &&
          !await _saveRemoteBufferSnapshot(buffer!, scheduleSync: false)) {
        return false;
      }
      if (!await _localHistory.captureBeforeLoss(
        LocalHistoryBufferSnapshot.fromBuffer(buffer ?? _remoteBuffer(note)),
        LocalHistoryCaptureReason.beforeDelete,
      )) {
        return false;
      }
      await repository.delete(localId);
      return true;
    } on Object catch (error) {
      _reportNextcloudFailure(error);
      return false;
    }
  }

  Future<bool> deleteNextcloudAttachment(
    String localId,
    String reference,
  ) async {
    try {
      final repository = await _ensureNotesRepository();
      final note = repository.noteById(localId);
      if (note == null || note.readonly || note.error) return false;
      final buffer = state.documentBuffers
          .where((value) => value.remoteNote?.localId == localId)
          .firstOrNull;
      if (buffer?.isDirty == true &&
          !await _saveRemoteBufferSnapshot(buffer!, scheduleSync: false)) {
        return false;
      }
      if (!await _localHistory.captureBeforeLoss(
        LocalHistoryBufferSnapshot.fromBuffer(buffer ?? _remoteBuffer(note)),
        LocalHistoryCaptureReason.beforeDelete,
      )) {
        return false;
      }
      await repository.deleteAttachment(localId, reference);
      return true;
    } on Object catch (error) {
      _reportNextcloudFailure(error);
      return false;
    }
  }

  Future<void> resolveNextcloudConflict(
    String localId,
    NoteConflictResolution resolution, {
    String? mergedContent,
    Map<NotesMergeAttribute, NotesMergeChoice> metadataChoices = const {},
    int? expectedRevision,
    int? creationCandidateServerId,
    NotesCreationReview? creationReview,
  }) async {
    try {
      final repository = await _ensureNotesRepository();
      if (resolution == NoteConflictResolution.useServerNote) {
        final candidateIds = repository.notes
            .where(
              (n) =>
                  n.accountId == creationReview?.accountId &&
                  n.serverId == creationCandidateServerId,
            )
            .map((n) => n.localId)
            .toSet();
        if (state.documentBuffers.any(
          (b) => candidateIds.contains(b.remoteNote?.localId),
        )) {
          throw const NotesException(
            NotesFailureCode.conflict,
            'Close the downloaded candidate’s editor tabs after preserving their changes, then review again.',
          );
        }
      }
      final buffer = state.documentBuffers
          .where((b) => b.remoteNote?.localId == localId)
          .firstOrNull;
      if (expectedRevision != null &&
          (repository.noteById(localId)?.revision != expectedRevision ||
              buffer?.isDirty == true)) {
        throw const NotesException(
          NotesFailureCode.conflict,
          'New local changes appeared while resolving this note. Review the comparison again.',
        );
      }
      if (buffer?.isDirty == true &&
          !await _saveRemoteBufferSnapshot(buffer!, scheduleSync: false)) {
        return;
      }
      if (buffer != null &&
          !await _localHistory.captureBeforeLoss(
            LocalHistoryBufferSnapshot.fromBuffer(buffer),
            LocalHistoryCaptureReason.beforeRestore,
          )) {
        return;
      }
      await repository.resolveConflict(
        localId,
        resolution,
        mergedContent: mergedContent,
        metadataChoices: metadataChoices,
        expectedRevision: expectedRevision,
        creationCandidateServerId: creationCandidateServerId,
        creationReview: creationReview,
      );
      final accountId = repository.noteById(localId)?.accountId;
      if (accountId != null) _scheduleRemoteSync(accountId);
    } on Object catch (error) {
      _reportNextcloudFailure(error);
    }
  }

  Future<bool> recoverNextcloudHistoryRevision({
    required LocalHistoryDocument document,
    required LocalHistoryRevision revision,
  }) async {
    try {
      final reference = document.remoteNote;
      if (reference == null || revision.summary.documentId != document.id) {
        return false;
      }
      if (state.workspace?.nextcloudAccountId != reference.accountId &&
          !await openNextcloudWorkspace(reference.accountId)) {
        return false;
      }
      final repository = await _ensureNotesRepository();
      final recovered = await repository.recoverAsNew(
        reference.localId,
        title: document.displayName,
        content: revision.source,
      );
      final opened = await openNextcloudNote(recovered.localId);
      _scheduleRemoteSync(reference.accountId);
      return opened;
    } on Object catch (error) {
      _reportNextcloudFailure(error);
      return false;
    }
  }

  /// Called after removal has committed, so session restoration cannot reopen
  /// an account whose durable store and keyring entry have been removed.
  Future<void> closeRemovedNextcloudWorkspace(String accountId) async {
    if (state.workspace?.nextcloudAccountId != accountId) return;
    _cancelPendingDerivedRefresh();
    _cancelAllAutoSaves();
    _invalidateActiveDocumentOperations();
    _remoteSyncRequested.remove(accountId);
    _remoteRetryTimers.remove(accountId)?.cancel();
    _remoteRetryCounts.remove(accountId);
    for (final buffer in state.documentBuffers) {
      await _localHistory.handleBufferClosed(buffer.id, historySettled: true);
    }
    await _fileMonitor.stop();
    state = const WorkspaceState();
    await flushPersistence();
  }

  Future<bool> restorePreviousSession() async {
    if (state.workspace != null) {
      return state.documentBuffers.isNotEmpty;
    }
    final recovery = await _recoveryStart;
    final session = await _sessionStore.load();
    late final List<LocalHistoryPathReconciliation> restoredPathReconciliations;
    late List<LocalHistoryPendingSaveAs> restoredSaveAsOperations;
    late List<DocumentSessionEntry> sessionEntries;
    _restoringLocalHistorySession = true;
    _restoredRecoveryOwnerIdsByBuffer.clear();
    try {
      // The controller's initial refresh is intentionally asynchronous. Load
      // an authoritative snapshot before consuming any durable journal: an
      // early failure must leave the persisted workspace and its obligations
      // untouched for the next startup.
      if (!await _localHistory.refresh()) return false;
      if (session?.pendingLocalHistoryReconciliations.any(
            (operation) => _localHistoryOperationOwnerIsLiveOtherProcess(
              operation.operationId,
            ),
          ) ??
          false) {
        // The owner is still publishing the matching recovery and workspace
        // paths. Do not consume, mirror, or rewrite its shared session. A
        // later startup can reconcile the journal after that owner retires.
        return false;
      }
      _localHistory.restoreRetiredPathReconciliationIds(
        session?.retiredLocalHistoryReconciliationIds ?? const <String>[],
      );
      _localHistory.restoreRetiredDurableWorkOwnerIds(
        session?.retiredLocalHistoryWorkOwnerIds ?? const <String>[],
      );
      if (!await _localHistory.restorePendingClearOperations(
        session?.pendingLocalHistoryClears ??
            const <LocalHistoryPendingClear>[],
      )) {
        return false;
      }
      _localHistory.restorePendingSaveAsOperations(
        session?.pendingLocalHistorySaveAs ??
            const <LocalHistoryPendingSaveAs>[],
      );
      restoredSaveAsOperations = await _resolveRestoredSaveAsOperations(
        session?.pendingLocalHistorySaveAs ??
            const <LocalHistoryPendingSaveAs>[],
      );
      _localHistory.restoreRetainedDetachedCaptures(
        session?.retainedLocalHistoryCaptures ??
            const <LocalHistoryRetainedCapture>[],
      );
      restoredPathReconciliations = await _resolveRestoredPathReconciliations(
        session?.pendingLocalHistoryReconciliations ??
            const <LocalHistoryPathReconciliation>[],
        restoredSaveAsOperations,
      );
      await _localHistory.restorePendingPathReconciliations(
        restoredPathReconciliations,
      );
      // A committed Save As to a new filesystem path can have a committed
      // cleanup operation for a stale destination history owner. Publish that
      // identity-targeted cleanup before resolving the Save As destination;
      // otherwise the stale owner makes every startup reject the recovery.
      final originalSessionEntries =
          session?.tabs ?? const <DocumentSessionEntry>[];
      for (final operation in restoredSaveAsOperations) {
        await _localHistory.recoverCommittedSaveAs(
          operation,
          sourceRetainsUntitledLineage:
              _restoredSaveAsSourceRetainsUntitledLineage(
                operation,
                originalSessionEntries,
              ),
        );
      }
      sessionEntries = _reconcileRestoredSessionEntries(
        originalSessionEntries,
        restoredPathReconciliations,
        restoredSaveAsOperations,
      );
      for (final association
          in session?.pendingLocalHistoryAssociations ??
              const <PendingLocalHistoryAssociation>[]) {
        _localHistory.restorePendingIdentityPromotion(
          LocalHistoryPendingIdentityPromotion(
            bufferId: association.bufferId,
            documentId: association.documentId,
            destinationPath: association.destinationPath,
            displayName: association.displayName,
            acceptedClearEpoch: association.acceptedClearEpoch,
            operationOwnerId: association.operationOwnerId,
          ),
        );
      }
      await _localHistory.flushPendingIdentityPromotions();
      await _localHistory.flushAll(const []);
      for (final entry in sessionEntries) {
        if (entry.localHistoryDocumentId case final documentId?) {
          _localHistory.restoreBufferDocumentIdentity(
            bufferId: entry.id,
            documentId: documentId,
            path: entry.filePath,
          );
        }
      }
      if (session?.nextcloudAccountId case final accountId?) {
        // Restore and settle the durable Local History journal before opening
        // remote tabs. This preserves path/clear obligations even though a
        // Nextcloud workspace has no filesystem recovery payload.
        await _persistRestoredLocalHistoryJournal(
          session!,
          workspacePath: null,
          tabs: sessionEntries,
          recoveryEntries: const [],
          persistRecovery: false,
        );
        final restored = await openNextcloudWorkspace(
          accountId,
          restoredTabs: sessionEntries,
          activeBufferId: session.activeBufferId,
        );
        if (restored) await flushPersistence();
        return restored;
      }
      // Entries are authoritative even if the last shutdown was marked clean.
      // This protects users when close confirmation is disabled while dirty
      // buffers still exist.
      final adoptableRecoveryEntries =
          recovery.entries
              .where(
                (entry) =>
                    !_recoveryStore.ownerIsLiveOtherProcess(entry.ownerId),
              )
              .toList(growable: false)
            ..sort((left, right) {
              bool hasSessionOwner(DocumentRecoveryEntry entry) =>
                  session?.tabs.any(
                    (tab) =>
                        tab.id == entry.id &&
                        (tab.recoveryOwnerId == null ||
                            tab.recoveryOwnerId == entry.ownerId),
                  ) ??
                  false;
              return (hasSessionOwner(right) ? 1 : 0) -
                  (hasSessionOwner(left) ? 1 : 0);
            });
      final recoveryAdoptions = await _recoveryStore.adoptEntries(
        adoptableRecoveryEntries,
      );
      var recoveryAdoptionsCommitted = false;
      sessionEntries = _adoptSessionRecoveryOwnership(
        sessionEntries,
        recoveryAdoptions,
      );
      restoredSaveAsOperations = _adoptSaveAsRecoveryOwnership(
        restoredSaveAsOperations,
        recoveryAdoptions,
      );
      final recoverEntries = await _reconcileRestoredRecoveryEntries(
        recoveryAdoptions,
        session?.tabs ?? const <DocumentSessionEntry>[],
        restoredPathReconciliations,
        restoredSaveAsOperations,
      );
      var persistedWorkspacePath = _reconcileRestoredSessionPath(
        session?.workspacePath,
        restoredPathReconciliations,
        operationIds:
            session?.workspaceLocalHistoryReconciliationIds.toSet() ?? const {},
      );
      for (final operation in restoredSaveAsOperations) {
        final destination = operation.destination.path;
        if (destination == null) continue;
        final activeEntry = session?.tabs
            .where((entry) => entry.id == session.activeBufferId)
            .firstOrNull;
        final sessionOwnsOperation =
            activeEntry?.pendingLocalHistorySaveAsOperationId ==
            operation.operationId;
        if ((persistedWorkspacePath == null && sessionOwnsOperation) ||
            (persistedWorkspacePath != null &&
                sessionOwnsOperation &&
                operation.source.path != null &&
                p.equals(persistedWorkspacePath, operation.source.path!))) {
          persistedWorkspacePath = destination;
        }
      }
      if (session != null) {
        await _persistRestoredLocalHistoryJournal(
          session,
          workspacePath: persistedWorkspacePath,
          tabs: sessionEntries,
          recoveryEntries: recoverEntries,
        );
      }
      final sessionHasRestorableState =
          session != null &&
          (persistedWorkspacePath != null ||
              sessionEntries.isNotEmpty ||
              _localHistory.pendingIdentityPromotions.isNotEmpty ||
              _localHistory.pendingPathReconciliations.isNotEmpty ||
              _localHistory.pendingClearOperations.isNotEmpty ||
              _localHistory.pendingSaveAsOperations.isNotEmpty ||
              _localHistory.retainedDetachedCaptures.isNotEmpty);
      if (!sessionHasRestorableState && recoverEntries.isEmpty) {
        await _recoveryStore.releaseAdoptions(recoveryAdoptions);
        if (session != null) {
          await _persistRestoredLocalHistoryJournal(
            session,
            workspacePath: session.workspacePath,
            tabs: session.tabs,
            recoveryEntries: const [],
            persistRecovery: false,
          );
        }
        if (recovery.readErrors > 0) {
          state = state.copyWith(
            message: WorkspaceMessage(
              WorkspaceMessageCode.recoveryDamaged,
              error: recovery.readErrors,
            ),
          );
        }
        return false;
      }
      final workspacePath =
          persistedWorkspacePath ??
          recoverEntries
              .map((entry) => entry.workspacePath)
              .whereType<String>()
              .firstOrNull ??
          recoverEntries
              .map((entry) => entry.filePath)
              .whereType<String>()
              .firstOrNull;
      try {
        late final Workspace workspace;
        if (workspacePath == null) {
          workspace = _service.createUntitledMarkdown();
        } else if (await _service.pathExists(workspacePath)) {
          workspace = await _service.openPath(workspacePath);
        } else {
          final activeEntry = sessionEntries
              .where((entry) => entry.id == session?.activeBufferId)
              .firstOrNull;
          final activeRecovery = recoverEntries
              .where((entry) => entry.id == session?.activeBufferId)
              .firstOrNull;
          final activePath =
              activeEntry?.filePath ??
              activeRecovery?.filePath ??
              sessionEntries
                  .map((entry) => entry.filePath)
                  .whereType<String>()
                  .firstOrNull ??
              recoverEntries
                  .map((entry) => entry.filePath)
                  .whereType<String>()
                  .firstOrNull;
          final seedText = activeRecovery?.text ?? '';
          final parsed = _service.createUntitledMarkdown(source: seedText);
          final standalone = p.extension(workspacePath).isNotEmpty;
          workspace = Workspace(
            id: 'missing:$workspacePath',
            rootPath: workspacePath,
            kind: standalone
                ? WorkspaceKind.singleMarkdown
                : WorkspaceKind.markdownFolder,
            openedAt: DateTime.now(),
            activeFilePath: activePath,
            openFilePaths: [
              for (final entry in sessionEntries)
                if (entry.filePath != null) entry.filePath!,
              for (final entry in recoverEntries)
                if (entry.filePath != null) entry.filePath!,
            ],
            files: const [],
            diagnostics: parsed.diagnostics,
            markdown: parsed.markdown,
          );
        }
        final buffers = <DocumentBuffer>[];
        final consumedRecoveries = <(String?, String)>{};
        for (final entry in sessionEntries) {
          final ownedById = recoverEntries
              .where(
                (recovery) =>
                    recovery.id == entry.id &&
                    (entry.recoveryOwnerId == null ||
                        recovery.ownerId == entry.recoveryOwnerId),
              )
              .toList(growable: false);
          final ownedByPath = entry.filePath == null
              ? const <DocumentRecoveryEntry>[]
              : recoverEntries
                    .where(
                      (recovery) =>
                          recovery.filePath == entry.filePath &&
                          (entry.recoveryOwnerId == null ||
                              recovery.ownerId == entry.recoveryOwnerId),
                    )
                    .toList(growable: false);
          final recovered = ownedById.length == 1
              ? ownedById.single
              : ownedById.isEmpty && ownedByPath.length == 1
              ? ownedByPath.single
              : null;
          final buffer = await _restoreSessionBuffer(entry, recovered);
          if (buffer != null) {
            buffers.add(buffer);
            if (recovered != null) {
              consumedRecoveries.add((recovered.ownerId, recovered.id));
            }
          }
        }
        for (final recovered in recoverEntries) {
          if (consumedRecoveries.contains((recovered.ownerId, recovered.id))) {
            continue;
          }
          var restoredId = recovered.id;
          var suffix = 1;
          while (buffers.any((buffer) => buffer.id == restoredId)) {
            restoredId = '${recovered.id}:recovered:${suffix++}';
          }
          final pathAlreadyOpen =
              recovered.filePath != null &&
              buffers.any(
                (buffer) =>
                    buffer.filePath != null &&
                    p.equals(buffer.filePath!, recovered.filePath!),
              );
          final buffer = await _restoreRecoveryBuffer(
            recovered,
            idOverride: restoredId,
            detachFromPath: pathAlreadyOpen,
          );
          if (buffer != null) {
            buffers.add(buffer);
          }
        }
        if (buffers.isEmpty) {
          return false;
        }
        final activeId =
            buffers.any((buffer) => buffer.id == session?.activeBufferId)
            ? session!.activeBufferId!
            : buffers.first.id;
        final active = buffers.firstWhere((buffer) => buffer.id == activeId);
        final openPaths = [
          for (final buffer in buffers)
            if (buffer.filePath != null) buffer.filePath!,
        ];
        final nextWorkspace = workspace.copyWith(
          activeFilePath: active.filePath,
          activeFileSnapshot: active.diskSnapshot,
          openFilePaths: openPaths,
        );
        final reparsed = await _reparseWithDocumentBuffers(
          nextWorkspace,
          active,
          buffers: buffers,
        );
        if (!ref.mounted || !_preparedInputsCurrent(reparsed, buffers)) {
          return false;
        }
        state = WorkspaceState(
          workspace: reparsed,
          preview: _safePreview(reparsed, active),
          documentBuffers: buffers,
          activeBufferId: active.id,
          message: recovery.readErrors > 0
              ? WorkspaceMessage(
                  WorkspaceMessageCode.recoveryDamaged,
                  error: recovery.readErrors,
                )
              : recoverEntries.isNotEmpty
              ? WorkspaceMessage(
                  WorkspaceMessageCode.recoveryRestored,
                  error: recoverEntries.length,
                )
              : null,
        );
        for (final entry in sessionEntries) {
          final recoveryOwnerId = entry.recoveryOwnerId;
          if (recoveryOwnerId != null &&
              buffers.any((buffer) => buffer.id == entry.id)) {
            _restoredRecoveryOwnerIdsByBuffer[entry.id] = recoveryOwnerId;
          }
        }
        for (final buffer in buffers) {
          unawaited(_localHistory.observeOpened(buffer));
        }
        _recordActivePreviewRevision();
        _editRevision = active.revision;
        await _startMonitoring(reparsed);
        await _settingsController.setDocumentViewMode(active.editorState.mode);
        await flushPersistence();
        recoveryAdoptionsCommitted = true;
        return true;
      } on Object catch (error, stackTrace) {
        busyMarkDebugLogError(
          '[BusyMark] Session restore failed',
          error,
          stackTrace,
        );
        return false;
      } finally {
        if (!recoveryAdoptionsCommitted) {
          await _recoveryStore.releaseAdoptions(recoveryAdoptions);
          if (session != null) {
            await _persistRestoredLocalHistoryJournal(
              session,
              workspacePath: session.workspacePath,
              tabs: session.tabs,
              recoveryEntries: const [],
              persistRecovery: false,
            );
          }
        }
      }
    } finally {
      // Local History retries may request durable persistence while recovery
      // ownership is adopted and the workspace is still being reconstructed.
      // Keep empty-state persistence suppressed until reconstruction commits
      // or every adoption has been released on failure.
      _restoringLocalHistorySession = false;
    }
  }

  Future<List<LocalHistoryPathReconciliation>>
  _resolveRestoredPathReconciliations(
    Iterable<LocalHistoryPathReconciliation> reconciliations,
    Iterable<LocalHistoryPendingSaveAs> committedSaveAsOperations,
  ) async {
    final resolved = <LocalHistoryPathReconciliation>[];
    for (final reconciliation in reconciliations) {
      // A live owner may already have committed the shared-store mutation but
      // still be publishing newer editor recovery and workspace paths. Leave
      // its journal in the session merge until that owner acknowledges it;
      // consuming it here would retire the only durable relationship between
      // the old recovery path and the committed filesystem operation.
      if (_localHistoryOperationOwnerIsLiveOtherProcess(
        reconciliation.operationId,
      )) {
        // Startup normally returns before reaching this point. Retain a
        // conservative guard in case ownership changes during restoration.
        continue;
      }
      if (reconciliation.phase ==
          LocalHistoryPathReconciliationPhase.committed) {
        resolved.add(reconciliation);
        continue;
      }
      if (reconciliation.phase ==
          LocalHistoryPathReconciliationPhase.prepared) {
        // The execution phase is persisted before the filesystem call, so a
        // prepared operation from a dead owner is known not to have started.
        // A different live BusyMark process may still be between its prepared
        // and executing session writes, so never tombstone that operation.
        if (_localHistoryOperationOwnerIsDefinitelyDead(
          reconciliation.operationId,
        )) {
          await _localHistory.retirePreparedPathReconciliation(
            reconciliation.operationId,
          );
        } else {
          resolved.add(reconciliation);
        }
        continue;
      }
      try {
        final sourceExists = await _service.pathExists(
          reconciliation.sourcePath,
        );
        final commitEvidence = reconciliation.commitEvidenceOperationId;
        final committedBySaveAs =
            commitEvidence != null &&
            committedSaveAsOperations.any(
              (operation) => operation.operationId == commitEvidence,
            );
        final committed = switch (reconciliation.kind) {
          LocalHistoryPathReconciliationKind.deletion =>
            committedBySaveAs || !sourceExists,
          LocalHistoryPathReconciliationKind.remap =>
            !sourceExists &&
                await _service.pathExists(reconciliation.destinationPath!),
        };
        if (committed) {
          resolved.add(
            reconciliation.withPhase(
              LocalHistoryPathReconciliationPhase.committed,
            ),
          );
        } else if (sourceExists) {
          // Execution began but the process stopped before recording its
          // outcome. A same-path replacement is indistinguishable here, so
          // retain the namespace block for deliberate recovery.
          resolved.add(reconciliation);
        } else {
          // The namespace is ambiguous (for example, another process already
          // recreated the source). Keep it blocked for deliberate recovery.
          resolved.add(reconciliation);
        }
      } on Object {
        resolved.add(reconciliation);
      }
    }
    return List.unmodifiable(resolved);
  }

  Future<List<LocalHistoryPendingSaveAs>> _resolveRestoredSaveAsOperations(
    Iterable<LocalHistoryPendingSaveAs> operations,
  ) async {
    final committed = <LocalHistoryPendingSaveAs>[];
    for (final operation in operations) {
      if (_localHistoryOperationOwnerIsLiveOtherProcess(
        operation.operationId,
      )) {
        _localHistory.leavePendingSaveAsOwnedExternally(operation.operationId);
        continue;
      }
      if (operation.phase == LocalHistoryPathReconciliationPhase.prepared) {
        if (_localHistoryOperationOwnerIsDefinitelyDead(
          operation.operationId,
        )) {
          await _localHistory.discardPendingSaveAsRecovery(
            operation.operationId,
          );
        }
        continue;
      }
      if (operation.phase == LocalHistoryPathReconciliationPhase.committed) {
        committed.add(operation);
        continue;
      }
      // `executing` is deliberately retained. The process persisted it before
      // entering the filesystem call, so neither equal nor different current
      // destination bytes prove whether the call committed. Guessing here can
      // steal another process's in-flight journal or publish a false fork.
    }
    return List.unmodifiable(committed);
  }

  bool _localHistoryOperationOwnerIsDefinitelyDead(String operationId) {
    return _localHistory.operationOwnerIsDefinitelyDead(operationId);
  }

  bool _localHistoryOperationOwnerIsLiveOtherProcess(String operationId) {
    return _localHistory.operationOwnerIsLiveOtherProcess(operationId);
  }

  String? _reconcileRestoredSessionPath(
    String? path,
    Iterable<LocalHistoryPathReconciliation> reconciliations, {
    String? documentId,
    String? ownerId,
    Set<String>? operationIds,
  }) {
    if (path == null) return null;
    var result = p.normalize(path);
    for (final reconciliation in reconciliations) {
      if (reconciliation.phase !=
          LocalHistoryPathReconciliationPhase.committed) {
        continue;
      }
      final appliesByOperation =
          operationIds?.contains(reconciliation.operationId) ?? false;
      final appliesByDocument =
          documentId != null && reconciliation.documentIds.contains(documentId);
      final appliesByOwner =
          ownerId != null && reconciliation.ownerIds.contains(ownerId);
      if ((operationIds != null || documentId != null || ownerId != null) &&
          !appliesByOperation &&
          !appliesByDocument &&
          !appliesByOwner) {
        continue;
      }
      switch (reconciliation.kind) {
        case LocalHistoryPathReconciliationKind.remap:
          if (p.equals(result, reconciliation.sourcePath)) {
            result = reconciliation.destinationPath!;
          } else if (p.isWithin(reconciliation.sourcePath, result)) {
            result = p.join(
              reconciliation.destinationPath!,
              p.relative(result, from: reconciliation.sourcePath),
            );
          }
        case LocalHistoryPathReconciliationKind.deletion:
          if (p.equals(result, reconciliation.sourcePath) ||
              reconciliation.recursive &&
                  p.isWithin(reconciliation.sourcePath, result)) {
            return null;
          }
      }
    }
    return result;
  }

  LocalHistoryPathReconciliation? _committedRestoredDeletion(
    String path,
    Iterable<LocalHistoryPathReconciliation> reconciliations, {
    String? documentId,
    String? ownerId,
    Set<String>? operationIds,
  }) => reconciliations
      .where(
        (reconciliation) =>
            reconciliation.phase ==
                LocalHistoryPathReconciliationPhase.committed &&
            reconciliation.kind ==
                LocalHistoryPathReconciliationKind.deletion &&
            ((operationIds?.contains(reconciliation.operationId) ?? false) ||
                documentId != null &&
                    reconciliation.documentIds.contains(documentId) ||
                ownerId != null && reconciliation.ownerIds.contains(ownerId)) &&
            (p.equals(path, reconciliation.sourcePath) ||
                reconciliation.recursive &&
                    p.isWithin(reconciliation.sourcePath, path)),
      )
      .lastOrNull;

  List<DocumentSessionEntry> _reconcileRestoredSessionEntries(
    Iterable<DocumentSessionEntry> entries,
    Iterable<LocalHistoryPathReconciliation> reconciliations,
    Iterable<LocalHistoryPendingSaveAs> saveAsOperations,
  ) {
    final original = entries.toList(growable: false);
    final saveAs = saveAsOperations.toList(growable: false);
    return List.unmodifiable([
      for (final entry in original)
        if (entry.filePath == null ||
            _reconcileRestoredSessionPath(
                  entry.filePath,
                  reconciliations,
                  documentId: entry.localHistoryDocumentId,
                  ownerId: entry.id,
                  operationIds: entry.localHistoryPathReconciliationIds.toSet(),
                ) !=
                null)
          (() {
            final operation = saveAs
                .where(
                  (operation) =>
                      operation.operationId ==
                      entry.pendingLocalHistorySaveAsOperationId,
                )
                .lastOrNull;
            final sourceKeepsUntitled =
                operation != null &&
                _restoredSaveAsSourceRetainsUntitledLineage(
                  operation,
                  original,
                );
            return DocumentSessionEntry(
              id: entry.id,
              filePath:
                  (!sourceKeepsUntitled ? operation?.destination.path : null) ??
                  _reconcileRestoredSessionPath(
                    entry.filePath,
                    reconciliations,
                    documentId: entry.localHistoryDocumentId,
                    ownerId: entry.id,
                    operationIds: entry.localHistoryPathReconciliationIds
                        .toSet(),
                  ),
              untitledName: operation != null && !sourceKeepsUntitled
                  ? null
                  : entry.untitledName,
              editorState: entry.editorState,
              localHistoryDocumentId: entry.localHistoryDocumentId,
              pendingLocalHistorySaveAsOperationId: sourceKeepsUntitled
                  ? null
                  : entry.pendingLocalHistorySaveAsOperationId,
              localHistoryPathReconciliationIds:
                  entry.localHistoryPathReconciliationIds,
              recoveryOwnerId: entry.recoveryOwnerId,
              remoteNote: entry.remoteNote,
            );
          })(),
    ]);
  }

  bool _restoredSaveAsSourceRetainsUntitledLineage(
    LocalHistoryPendingSaveAs operation,
    Iterable<DocumentSessionEntry> entries,
  ) {
    final destinationPath = operation.destination.path;
    if (!operation.firstSaveLineageTransition ||
        !operation.source.untitled ||
        destinationPath == null) {
      return false;
    }
    final sourceEntry = entries
        .where(
          (entry) =>
              entry.id == operation.bufferId &&
              entry.pendingLocalHistorySaveAsOperationId ==
                  operation.operationId,
        )
        .firstOrNull;
    if (sourceEntry == null || sourceEntry.filePath != null) return false;
    return entries.any(
      (entry) =>
          !identical(entry, sourceEntry) &&
          entry.filePath != null &&
          p.equals(entry.filePath!, destinationPath),
    );
  }

  Future<List<DocumentRecoveryEntry>> _reconcileRestoredRecoveryEntries(
    Iterable<DocumentRecoveryAdoption> adoptions,
    Iterable<DocumentSessionEntry> originalSessionEntries,
    Iterable<LocalHistoryPathReconciliation> reconciliations,
    Iterable<LocalHistoryPendingSaveAs> saveAsOperations,
  ) async {
    final result = <DocumentRecoveryEntry>[];
    for (final adoption in adoptions) {
      final entry = adoption.entry;
      final sessionEntry = originalSessionEntries
          .where(
            (candidate) =>
                candidate.id == adoption.sourceId &&
                (candidate.recoveryOwnerId == null ||
                    adoption.sourceOwnerId == null ||
                    candidate.recoveryOwnerId == adoption.sourceOwnerId),
          )
          .firstOrNull;
      final operationIds =
          sessionEntry?.localHistoryPathReconciliationIds.toSet() ?? const {};
      var detachUncapturedDeletionRecovery = false;
      if (entry.filePath case final recoveryPath?) {
        final deletion = _committedRestoredDeletion(
          recoveryPath,
          reconciliations,
          documentId: sessionEntry?.localHistoryDocumentId,
          ownerId: adoption.sourceId,
          operationIds: operationIds,
        );
        if (deletion != null) {
          final sessionDocumentId = sessionEntry?.localHistoryDocumentId;
          final evidenceDocumentIds =
              sessionDocumentId != null &&
                  deletion.documentIds.contains(sessionDocumentId)
              ? <String>[sessionDocumentId]
              : <String>[
                  for (final target in deletion.targets)
                    if (p.equals(target.expectedPath, recoveryPath))
                      target.documentId,
                ];
          final safelyCaptured = await _localHistory.hasExactStoredRevision(
            documentIds: evidenceDocumentIds,
            source: entry.text,
            format: entry.format,
          );
          if (safelyCaptured) {
            // The exact recovery payload is already in the deleted lineage.
            continue;
          }
          // The filesystem deletion committed before this newer editor state
          // reached history. Preserve it as a detached recovery document so
          // startup cannot discard it or recreate a live owner at the deleted
          // pathname.
          detachUncapturedDeletionRecovery = true;
        }
      }
      var workspacePath = _reconcileRestoredRecoveryPath(
        entry.workspacePath,
        reconciliations,
        documentId: sessionEntry?.localHistoryDocumentId,
        ownerId: adoption.sourceId,
        operationIds: operationIds,
      );
      var filePath = _reconcileRestoredRecoveryPath(
        entry.filePath,
        reconciliations,
        documentId: sessionEntry?.localHistoryDocumentId,
        ownerId: adoption.sourceId,
        operationIds: operationIds,
      );
      var untitledName = entry.untitledName;
      var lastSavedText = entry.lastSavedText;
      var diskSnapshot = entry.diskSnapshot;
      if (detachUncapturedDeletionRecovery) {
        filePath = null;
        untitledName = entry.filePath == null
            ? entry.untitledName
            : '${p.basename(entry.filePath!)} (Recovered)';
        diskSnapshot = null;
      }
      final saveAs = saveAsOperations
          .where(
            (operation) =>
                operation.operationId ==
                    sessionEntry?.pendingLocalHistorySaveAsOperationId ||
                operation.recoveryOwnerId != null &&
                    operation.recoveryOwnerId == entry.ownerId &&
                    operation.bufferId == entry.id,
          )
          .lastOrNull;
      final destination = saveAs?.destination.path;
      final sourceKeepsUntitled =
          saveAs != null &&
          _restoredSaveAsSourceRetainsUntitledLineage(
            saveAs,
            originalSessionEntries,
          );
      if (saveAs != null && destination != null && !sourceKeepsUntitled) {
        filePath = destination;
        workspacePath ??= destination;
        untitledName = null;
        lastSavedText = saveAs.destination.source;
        try {
          final bytes = await File(destination).readAsBytes();
          final disk = await _service.loadTextWithSnapshot(destination);
          final exactDestination = _sameBytes(
            bytes,
            saveAs.destination.format.encode(saveAs.destination.source),
          );
          if (exactDestination && entry.text == saveAs.destination.source) {
            // The committed Save As made this formerly dirty/untitled entry
            // clean. Let the reconciled session tab load B normally.
            continue;
          }
          diskSnapshot = exactDestination ? disk.snapshot : null;
        } on Object {
          diskSnapshot = null;
        }
      }
      result.add(
        DocumentRecoveryEntry(
          id: entry.id,
          workspacePath: workspacePath,
          filePath: filePath,
          untitledName: untitledName,
          text: entry.text,
          lastSavedText: lastSavedText,
          diskSnapshot: diskSnapshot,
          format: entry.format,
          editorState: entry.editorState,
          revision: entry.revision,
          ownerId: entry.ownerId,
        ),
      );
    }
    return List.unmodifiable(result);
  }

  List<DocumentSessionEntry> _adoptSessionRecoveryOwnership(
    Iterable<DocumentSessionEntry> entries,
    Iterable<DocumentRecoveryAdoption> adoptions,
  ) => List.unmodifiable([
    for (final entry in entries)
      if (adoptions
              .where(
                (adoption) =>
                    adoption.sourceId == entry.id &&
                    (entry.recoveryOwnerId == null ||
                        adoption.sourceOwnerId == entry.recoveryOwnerId),
              )
              .firstOrNull
          case final adoption?)
        DocumentSessionEntry(
          id: adoption.entry.id,
          filePath: entry.filePath,
          untitledName: entry.untitledName,
          editorState: entry.editorState,
          localHistoryDocumentId: entry.localHistoryDocumentId,
          pendingLocalHistorySaveAsOperationId:
              entry.pendingLocalHistorySaveAsOperationId,
          localHistoryPathReconciliationIds:
              entry.localHistoryPathReconciliationIds,
          recoveryOwnerId: adoption.entry.ownerId,
          remoteNote: entry.remoteNote,
        )
      else
        entry,
  ]);

  List<LocalHistoryPendingSaveAs> _adoptSaveAsRecoveryOwnership(
    Iterable<LocalHistoryPendingSaveAs> operations,
    Iterable<DocumentRecoveryAdoption> adoptions,
  ) => List.unmodifiable([
    for (final operation in operations)
      if (adoptions
              .where(
                (adoption) =>
                    adoption.sourceId == operation.bufferId &&
                    operation.recoveryOwnerId != null &&
                    adoption.sourceOwnerId == operation.recoveryOwnerId,
              )
              .firstOrNull
          case final adoption?)
        operation.withRecoveryIdentity(
          recoveryOwnerId: adoption.entry.ownerId!,
          bufferId: adoption.entry.id,
        )
      else
        operation,
  ]);

  String? _reconcileRestoredRecoveryPath(
    String? path,
    Iterable<LocalHistoryPathReconciliation> reconciliations, {
    String? documentId,
    String? ownerId,
    Set<String>? operationIds,
  }) {
    if (path == null) return null;
    var result = p.normalize(path);
    for (final reconciliation in reconciliations) {
      if (reconciliation.phase !=
              LocalHistoryPathReconciliationPhase.committed ||
          reconciliation.kind != LocalHistoryPathReconciliationKind.remap ||
          !((operationIds?.contains(reconciliation.operationId) ?? false) ||
              documentId != null &&
                  reconciliation.documentIds.contains(documentId) ||
              ownerId != null && reconciliation.ownerIds.contains(ownerId))) {
        continue;
      }
      if (p.equals(result, reconciliation.sourcePath)) {
        result = reconciliation.destinationPath!;
      } else if (p.isWithin(reconciliation.sourcePath, result)) {
        result = p.join(
          reconciliation.destinationPath!,
          p.relative(result, from: reconciliation.sourcePath),
        );
      }
    }
    return result;
  }

  /// Restores startup state when the previous run needs recovery, or when the
  /// user has explicitly enabled clean-session reopening.
  Future<bool> restoreStartupSession({required bool reopenCleanSession}) async {
    final recovery = await _recoveryStart;
    final needsRecovery =
        !recovery.cleanShutdown || recovery.entries.isNotEmpty;
    if (!reopenCleanSession && !needsRecovery) {
      return false;
    }
    return restorePreviousSession();
  }

  Future<void> _persistRestoredLocalHistoryJournal(
    WorkspaceSessionSnapshot original, {
    required String? workspacePath,
    required List<DocumentSessionEntry> tabs,
    required List<DocumentRecoveryEntry> recoveryEntries,
    bool persistRecovery = true,
  }) async {
    // Publish reconciled recovery paths before retiring the journal that made
    // them authoritative. A crash can replay an old journal over new paths;
    // it cannot reconstruct new paths after the only journal is retired.
    if (persistRecovery) {
      await _recoveryStore.writeEntries(recoveryEntries);
    }
    await _sessionStore.save(
      WorkspaceSessionSnapshot(
        workspacePath: workspacePath,
        nextcloudAccountId: original.nextcloudAccountId,
        tabs: tabs,
        activeBufferId: original.activeBufferId,
        workspaceLocalHistoryReconciliationIds:
            original.workspaceLocalHistoryReconciliationIds,
        pendingLocalHistoryAssociations: [
          for (final promotion in _localHistory.pendingIdentityPromotions)
            PendingLocalHistoryAssociation(
              bufferId: promotion.bufferId,
              documentId: promotion.documentId,
              destinationPath: promotion.destinationPath,
              displayName: promotion.displayName,
              acceptedClearEpoch: promotion.acceptedClearEpoch,
              operationOwnerId: promotion.operationOwnerId,
            ),
        ],
        pendingLocalHistoryReconciliations:
            _localHistory.pendingPathReconciliations,
        retiredLocalHistoryReconciliationIds:
            _localHistory.retiredPathReconciliationIds,
        retiredLocalHistoryWorkOwnerIds:
            _localHistory.retiredDurableWorkOwnerIds,
        pendingLocalHistoryClears: _localHistory.pendingClearOperations,
        pendingLocalHistorySaveAs: _localHistory.pendingSaveAsOperations,
        retainedLocalHistoryCaptures: _localHistory.retainedDetachedCaptures,
      ),
    );
  }

  Future<DocumentBuffer?> _restoreSessionBuffer(
    DocumentSessionEntry session,
    DocumentRecoveryEntry? recovery,
  ) async {
    if (recovery != null) {
      return _restoreRecoveryBuffer(recovery, editorState: session.editorState);
    }
    final path = session.filePath;
    if (path == null) {
      return null;
    }
    if (!await _service.pathExists(path)) {
      const text = '';
      return DocumentBuffer(
        id: session.id,
        filePath: path,
        text: text,
        lastSavedText: text,
        dirty: false,
        format: TextFormatMetadata.utf8Lf,
        editorState: session.editorState,
        diskState: DocumentDiskState.deleted,
      );
    }
    final load = await _service.loadTextWithSnapshot(path);
    return _fileBuffer(
      path,
      load,
      id: session.id,
    ).copyWith(editorState: session.editorState);
  }

  Future<DocumentBuffer?> _restoreRecoveryBuffer(
    DocumentRecoveryEntry recovery, {
    DocumentEditorState? editorState,
    String? idOverride,
    bool detachFromPath = false,
  }) async {
    final bufferId = idOverride ?? recovery.id;
    final path = detachFromPath ? null : recovery.filePath;
    if (path == null) {
      return DocumentBuffer.untitled(
        id: bufferId,
        name:
            recovery.untitledName ??
            (recovery.filePath == null
                ? 'Untitled'
                : '${p.basename(recovery.filePath!)} (Recovered)'),
        text: recovery.text,
        mode: (editorState ?? recovery.editorState).mode,
      ).copyWith(
        editorState: editorState ?? recovery.editorState,
        lastSavedText: recovery.lastSavedText,
        // Recovery ownership itself is unsaved state. Even an empty payload
        // may represent an edited-empty document and must pass through the
        // protective-discard boundary before it can be removed.
        dirty: true,
        format: recovery.format,
        revision: recovery.revision,
        recovered: true,
      );
    }
    if (!await _service.pathExists(path)) {
      return DocumentBuffer(
        id: bufferId,
        filePath: path,
        text: recovery.text,
        lastSavedText: recovery.lastSavedText,
        dirty: true,
        diskSnapshot: recovery.diskSnapshot,
        format: recovery.format,
        editorState: editorState ?? recovery.editorState,
        revision: recovery.revision,
        diskState: DocumentDiskState.deleted,
        recovered: true,
      );
    }
    final disk = await _service.loadTextWithSnapshot(path);
    final conflict =
        recovery.diskSnapshot == null ||
        disk.snapshot.differsFrom(recovery.diskSnapshot!);
    return DocumentBuffer(
      id: bufferId,
      filePath: path,
      text: recovery.text,
      lastSavedText: recovery.lastSavedText,
      dirty: true,
      diskSnapshot: recovery.diskSnapshot,
      format: recovery.format,
      editorState: editorState ?? recovery.editorState,
      revision: recovery.revision,
      diskState: conflict
          ? DocumentDiskState.conflict
          : DocumentDiskState.present,
      diskVersionText: conflict ? disk.text : null,
      diskVersionSnapshot: conflict ? disk.snapshot : null,
      recovered: true,
    );
  }

  void _schedulePersistence() {
    _persistenceDebounce?.cancel();
    final delay = ref.read(documentPersistenceDelayProvider);
    if (delay == Duration.zero) {
      unawaited(flushPersistence());
      return;
    }
    _persistenceDebounce = Timer(delay, () => unawaited(flushPersistence()));
  }

  Future<void> flushPersistence() {
    if (!ref.mounted) return Future<void>.value();
    _persistenceDebounce?.cancel();
    final snapshot = state;
    final pendingHistoryAssociations = [
      for (final promotion in _localHistory.pendingIdentityPromotions)
        PendingLocalHistoryAssociation(
          bufferId: promotion.bufferId,
          documentId: promotion.documentId,
          destinationPath: promotion.destinationPath,
          displayName: promotion.displayName,
          acceptedClearEpoch: promotion.acceptedClearEpoch,
          operationOwnerId: promotion.operationOwnerId,
        ),
    ];
    final pendingHistoryReconciliations =
        _localHistory.pendingPathReconciliations;
    final retiredHistoryReconciliationIds =
        _localHistory.retiredPathReconciliationIds;
    final retiredHistoryWorkOwnerIds = _localHistory.retiredDurableWorkOwnerIds;
    final pendingHistoryClears = _localHistory.pendingClearOperations;
    final pendingHistorySaveAs = _localHistory.pendingSaveAsOperations;
    final retainedHistoryCaptures = _localHistory.retainedDetachedCaptures;
    final prior = _persistenceWrites.then<void>((_) {}, onError: (_, _) {});
    final write = prior.then(
      (_) => _persistSnapshot(
        snapshot,
        pendingHistoryAssociations: pendingHistoryAssociations,
        pendingHistoryReconciliations: pendingHistoryReconciliations,
        retiredHistoryReconciliationIds: retiredHistoryReconciliationIds,
        retiredHistoryWorkOwnerIds: retiredHistoryWorkOwnerIds,
        pendingHistoryClears: pendingHistoryClears,
        pendingHistorySaveAs: pendingHistorySaveAs,
        retainedHistoryCaptures: retainedHistoryCaptures,
      ),
    );
    _persistenceWrites = write;
    return write;
  }

  Future<void> _persistPendingHistoryReconciliation() async {
    try {
      await flushPersistence();
    } on Object catch (error, stackTrace) {
      busyMarkDebugLogError(
        '[BusyMark] Pending Local History reconciliation persistence failed',
        error,
        stackTrace,
      );
      _schedulePersistence();
    }
  }

  Future<void> _persistSnapshot(
    WorkspaceState snapshot, {
    required List<PendingLocalHistoryAssociation> pendingHistoryAssociations,
    required List<LocalHistoryPathReconciliation> pendingHistoryReconciliations,
    required List<String> retiredHistoryReconciliationIds,
    required List<String> retiredHistoryWorkOwnerIds,
    required List<LocalHistoryPendingClear> pendingHistoryClears,
    required List<LocalHistoryPendingSaveAs> pendingHistorySaveAs,
    required List<LocalHistoryRetainedCapture> retainedHistoryCaptures,
  }) async {
    await _recoveryStart;
    final workspace = snapshot.workspace;
    if (workspace == null) {
      if (pendingHistoryAssociations.isEmpty &&
          pendingHistoryReconciliations.isEmpty &&
          retiredHistoryReconciliationIds.isEmpty &&
          retiredHistoryWorkOwnerIds.isEmpty &&
          pendingHistoryClears.isEmpty &&
          pendingHistorySaveAs.isEmpty &&
          retainedHistoryCaptures.isEmpty) {
        await _recoveryStore.writeEntries(const []);
        await _sessionStore.clear();
      } else {
        await _recoveryStore.writeEntries(const []);
        await _sessionStore.save(
          WorkspaceSessionSnapshot(
            workspacePath: null,
            tabs: const [],
            activeBufferId: null,
            pendingLocalHistoryAssociations: pendingHistoryAssociations,
            pendingLocalHistoryReconciliations: pendingHistoryReconciliations,
            retiredLocalHistoryReconciliationIds:
                retiredHistoryReconciliationIds,
            retiredLocalHistoryWorkOwnerIds: retiredHistoryWorkOwnerIds,
            pendingLocalHistoryClears: pendingHistoryClears,
            pendingLocalHistorySaveAs: pendingHistorySaveAs,
            retainedLocalHistoryCaptures: retainedHistoryCaptures,
          ),
        );
      }
      return;
    }
    final workspacePath = switch (workspace.kind) {
      WorkspaceKind.untitledMarkdown || WorkspaceKind.nextcloudNotes => null,
      WorkspaceKind.singleMarkdown =>
        snapshot.documentBuffers
            .map((buffer) => buffer.filePath)
            .whereType<String>()
            .firstOrNull,
      WorkspaceKind.markdownFolder ||
      WorkspaceKind.writersideModule => workspace.rootPath,
    };
    // Remote recovery and the outbox share one transactional authority. Never
    // serialize a second pending-content copy into the path-based recovery file.
    for (final buffer in snapshot.documentBuffers) {
      if (buffer.isRemote &&
          buffer.isDirty &&
          !_remoteDurabilityWrites.containsKey(buffer.id)) {
        final saved = await _enqueueBufferWrite(
          buffer.id,
          () => _saveRemoteBufferSnapshot(
            buffer,
            scheduleSync: _settingsController.state.autoSave,
            captureHistory: false,
          ),
        );
        if (!saved) throw StateError('Could not durably store Nextcloud note');
      }
    }
    // Recovery content is the data side of the session transaction. Publish
    // it before a session can retire a Save As/path journal; after a crash an
    // older session may safely coexist with newer recovery, while the reverse
    // ordering could resurrect stale untitled/source content with no journal.
    for (final buffer in snapshot.documentBuffers) {
      if (!buffer.isRemote && (buffer.isDirty || buffer.isUntitled)) {
        _restoredRecoveryOwnerIdsByBuffer[buffer.id] = _recoveryStore.ownerId;
      }
    }
    await _recoveryStore.writeEntries([
      for (final buffer in snapshot.documentBuffers)
        if (!buffer.isRemote && (buffer.isDirty || buffer.isUntitled))
          DocumentRecoveryEntry.fromBuffer(
            buffer,
            workspacePath: workspacePath,
            ownerId: _recoveryStore.ownerId,
          ),
    ]);
    await _sessionStore.save(
      WorkspaceSessionSnapshot(
        workspacePath: workspacePath,
        nextcloudAccountId: workspace.nextcloudAccountId,
        activeBufferId: snapshot.activeBufferId,
        workspaceLocalHistoryReconciliationIds: [
          for (final operation in pendingHistoryReconciliations)
            if (operation.operationId.isNotEmpty &&
                snapshot.documentBuffers.any((buffer) {
                  final documentId = _localHistory.documentIdForBuffer(
                    buffer.id,
                  );
                  return operation.ownerIds.contains(buffer.id) ||
                      documentId != null &&
                          operation.documentIds.contains(documentId);
                }))
              operation.operationId,
        ],
        tabs: [
          for (final buffer in snapshot.documentBuffers)
            DocumentSessionEntry(
              id: buffer.id,
              filePath: buffer.filePath,
              untitledName: buffer.untitledName,
              editorState: buffer.editorState,
              localHistoryDocumentId: _localHistory.documentIdForBuffer(
                buffer.id,
              ),
              pendingLocalHistorySaveAsOperationId:
                  switch (_saveAsSessionBindings[buffer.id]) {
                    final binding?
                        when snapshot.workspace?.id == binding.workspaceId =>
                      binding.operationId,
                    _ => null,
                  },
              localHistoryPathReconciliationIds: [
                for (final operation in pendingHistoryReconciliations)
                  if (operation.operationId.isNotEmpty &&
                      (operation.ownerIds.contains(buffer.id) ||
                          operation.documentIds.contains(
                            _localHistory.documentIdForBuffer(buffer.id),
                          )))
                    operation.operationId,
              ],
              recoveryOwnerId: buffer.isRemote
                  ? null
                  : _restoredRecoveryOwnerIdsByBuffer[buffer.id] ??
                        _recoveryStore.ownerId,
              remoteNote: buffer.remoteNote,
            ),
        ],
        pendingLocalHistoryAssociations: pendingHistoryAssociations,
        pendingLocalHistoryReconciliations: pendingHistoryReconciliations,
        retiredLocalHistoryReconciliationIds: retiredHistoryReconciliationIds,
        retiredLocalHistoryWorkOwnerIds: retiredHistoryWorkOwnerIds,
        pendingLocalHistoryClears: pendingHistoryClears,
        pendingLocalHistorySaveAs: pendingHistorySaveAs,
        retainedLocalHistoryCaptures: retainedHistoryCaptures,
      ),
    );
  }

  Future<void> markCleanShutdown() async {
    await _settleWritesForShutdown();
    final historySettled = await _localHistory.flushAll(state.documentBuffers);
    await flushPersistence();
    if (!historySettled ||
        state.documentBuffers.any(
          (buffer) => buffer.isDirty || buffer.isUntitled,
        )) {
      // Keep the run unclean while recovery data is still needed.
      return;
    }
    await _sessionStore.runIfNoPendingLocalHistoryWork(
      _recoveryStore.markCleanShutdown,
    );
  }

  Future<void> discardRecoveryForShutdown() async {
    await _settleWritesForShutdown();
    final historySettled = await _localHistory.flushAll(state.documentBuffers);
    await flushPersistence();
    await _recoveryStore.clear();
    if (!historySettled) {
      // Preserve the unclean-run marker so the pending association stored in
      // the session is retried on the next launch.
      await _recoveryStore.writeEntries(const []);
    }
  }

  Future<void> _settleWritesForShutdown() async {
    _cancelAllAutoSaves();
    await _drainBufferWrites();
    // A write that retained a newer dirty revision can schedule another
    // debounce while the queue is draining. Shutdown owns the final save or
    // recovery decision, so do not let that timer outlive it.
    _cancelAllAutoSaves();
  }

  Future<void> _startMonitoring(Workspace workspace) async {
    final workspaceGeneration = _fileMonitorWorkspaceGeneration;
    final lifecycle = _runFileMonitorLifecycle(() async {
      if (!_fileMonitorWorkspaceIsCurrent(workspace, workspaceGeneration)) {
        return;
      }
      if (workspace.isRemote ||
          workspace.kind == WorkspaceKind.untitledMarkdown ||
          workspace.rootPath.isEmpty ||
          !Directory(workspace.rootPath).existsSync()) {
        await _fileMonitor.stop();
        return;
      }
      await _fileMonitor.start(
        rootPath: workspace.rootPath,
        openFilePaths: state.documentBuffers
            .map((buffer) => buffer.filePath)
            .whereType<String>(),
      );
      if (_fileMonitorWorkspaceIsCurrent(workspace, workspaceGeneration)) {
        _acceptFileMonitorEvents = true;
      }
    });
    await lifecycle;
  }

  Future<void> _runFileMonitorLifecycle(Future<void> Function() operation) {
    final prior = _fileMonitorLifecycle;
    // Start the first operation in the caller's zone. A synthetic
    // Future.value() created while a widget-test fake clock is active cannot
    // complete for a caller awaiting from runAsync, which would deadlock the
    // first monitor transition. Later transitions still serialize on the
    // real operation tail.
    final result = prior == null
        ? Future.sync(operation)
        : prior.then((_) => operation());
    // A monitor backend failure belongs to the transition that observed it.
    // Keep the serialized tail usable so a later workspace can stop/restart
    // monitoring instead of inheriting one permanently failed Future.
    _fileMonitorLifecycle = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {
        busyMarkDebugLogError(
          '[BusyMark] File monitor lifecycle failed',
          error,
          stackTrace,
        );
      },
    );
    return result;
  }

  Future<void> _handleFileMonitorEvent(
    WorkspaceFileMonitorEvent event,
    int workspaceGeneration,
  ) async {
    if (!_fileMonitorOperationIsCurrent(workspaceGeneration) ||
        state.workspace?.isRemote == true) {
      return;
    }
    if (_workspaceFileOperationDepth > 0) {
      _deferredFileMonitorEvents.add(
        _QueuedFileMonitorEvent(event, workspaceGeneration),
      );
      return;
    }
    final reconcilesHistory =
        event.kind == WorkspaceFileEventKind.moved ||
        event.kind == WorkspaceFileEventKind.deleted;
    final historyTargets = reconcilesHistory
        ? _localHistory.snapshotPathReconciliationTargets(
            event.path,
            recursive: event.isDirectory,
          )
        : null;
    if (await _acknowledgeReconciledNotification(event, workspaceGeneration)) {
      return;
    }
    if (!_fileMonitorOperationIsCurrent(workspaceGeneration)) return;
    _workspaceDiskRevision++;
    _reconciledNotifications = null;
    final matching = state.documentBuffers.where((buffer) {
      final path = buffer.filePath;
      return path != null &&
          (p.equals(path, event.path) ||
              event.isDirectory && p.isWithin(event.path, path) ||
              (event.destinationPath != null &&
                  (p.equals(path, event.destinationPath!) ||
                      event.isDirectory &&
                          p.isWithin(event.destinationPath!, path))));
    }).toList();
    if (event.isDirectory &&
        (event.kind == WorkspaceFileEventKind.moved ||
            event.kind == WorkspaceFileEventKind.deleted)) {
      await _applyExternalDirectoryState(
        event,
        matching,
        historyTargets ?? const <LocalHistoryPathTarget>[],
        workspaceGeneration,
      );
      if (!_fileMonitorOperationIsCurrent(workspaceGeneration)) return;
    } else {
      final sourceMatching = matching.where(
        (buffer) =>
            buffer.filePath != null && p.equals(buffer.filePath!, event.path),
      );
      if (reconcilesHistory && sourceMatching.isEmpty) {
        await _applyExternalClosedFileState(
          event,
          historyTargets ?? const <LocalHistoryPathTarget>[],
          workspaceGeneration,
        );
        if (!_fileMonitorOperationIsCurrent(workspaceGeneration)) return;
      }
      for (final buffer in matching) {
        await _applyExternalFileState(
          buffer,
          event,
          historyTargets: historyTargets,
          workspaceGeneration: workspaceGeneration,
        );
        if (!_fileMonitorOperationIsCurrent(workspaceGeneration)) return;
      }
    }
    final workspaceRoot = state.workspace?.filesystemRootPath;
    if (workspaceRoot == null ||
        ![
          event.path,
          if (event.destinationPath != null) event.destinationPath!,
        ].any(
          (path) =>
              p.equals(workspaceRoot, path) || p.isWithin(workspaceRoot, path),
        )) {
      return;
    }
    _scheduleMonitoredWorkspaceRefresh();
  }

  Map<String, _IncorporatedDiskState> _incorporatedDiskStates(
    Workspace workspace,
    Iterable<DocumentBuffer> buffers,
  ) {
    final result = <String, _IncorporatedDiskState>{};
    for (final module
        in workspace.writersideProject?.modules ?? const <WritersideModule>[]) {
      final snapshot = module.inputSnapshot;
      if (snapshot == null ||
          !snapshot.consistent ||
          !snapshot.discoveryComplete) {
        continue;
      }
      for (final input in snapshot.reads.entries) {
        if (!input.value.override) {
          result[input.key] = (exists: true, hash: input.value.hash);
        }
      }
      for (final input in snapshot.types.entries) {
        if (input.value == FileSystemEntityType.notFound) {
          result[input.key] = (exists: false, hash: null);
        }
      }
    }
    for (final buffer in buffers) {
      final path = buffer.filePath;
      if (path != null &&
          !buffer.isDirty &&
          buffer.diskState == DocumentDiskState.present &&
          buffer.diskSnapshot != null) {
        result[path] = (exists: true, hash: buffer.diskSnapshot!.contentHash);
      }
    }
    return result;
  }

  void _recordReconciledNotifications(
    Workspace original,
    Map<String, _IncorporatedDiskState> before,
  ) {
    final workspace = state.workspace;
    final project = workspace?.writersideProject;
    if (workspace == null ||
        project == null ||
        !project.moduleDiscoveryComplete ||
        project.inputSnapshot?.discoveryComplete != true ||
        project.modules.any(
          (module) =>
              !module.topicDiscoveryComplete ||
              module.inputSnapshot?.discoveryComplete != true,
        ) ||
        workspace.id != original.id ||
        state.isLoading ||
        !_preparedInputsCurrent(workspace, state.documentBuffers) ||
        _acceptedRefreshRevision != _workspaceRefreshRevision) {
      return;
    }
    final after = _incorporatedDiskStates(workspace, state.documentBuffers);
    for (final path in before.keys.where((path) => !after.containsKey(path))) {
      // Absence is evidence only when a completed loader inventory contains
      // the parent directory and did not find this path.
      final inventories = project.modules.expand(
        (m) =>
            m.inputSnapshot?.directories.entries ??
            const <MapEntry<String, List<String>>>[],
      );
      if (inventories.any(
        (dir) =>
            p.equals(dir.key, p.dirname(path)) &&
            !dir.value.any((entry) => entry.startsWith('${p.basename(path)}:')),
      )) {
        after[path] = (exists: false, hash: null);
      }
    }
    final changed = <String, _IncorporatedDiskState>{
      for (final entry in after.entries)
        if (before[entry.key] != entry.value) entry.key: entry.value,
    };
    if (changed.isEmpty || changed.length > 2048) return;
    _reconciledNotifications = _ReconciledFileNotifications(
      workspace.id,
      workspace.rootPath,
      project.modules,
      _workspaceRefreshRevision,
      changed,
      DateTime.now().add(const Duration(seconds: 5)),
    );
  }

  Future<bool> _acknowledgeReconciledNotification(
    WorkspaceFileMonitorEvent event,
    int workspaceGeneration,
  ) async {
    if (!_fileMonitorOperationIsCurrent(workspaceGeneration)) return false;
    final coverage = _reconciledNotifications;
    final workspace = state.workspace;
    if (coverage == null || workspace == null) return false;
    if (coverage.workspaceId != workspace.id ||
        coverage.rootPath != workspace.rootPath ||
        coverage.refreshRevision != _workspaceRefreshRevision ||
        !identical(coverage.modules, workspace.writersideProject?.modules) ||
        DateTime.now().isAfter(coverage.expires)) {
      _reconciledNotifications = null;
      return false;
    }
    final paths = [
      event.path,
      if (event.destinationPath != null) event.destinationPath!,
    ].where((path) => !isBusyMarkTopicStagingPath(path)).toSet();
    if (paths.isEmpty ||
        event.isDirectory ||
        !_preparedInputsCurrent(workspace, state.documentBuffers)) {
      return false;
    }
    final CanonicalPathAnchor anchor;
    try {
      anchor = await captureCanonicalDirectoryAnchor(coverage.rootPath);
    } on Object {
      return false;
    }
    if (!_fileMonitorOperationIsCurrent(workspaceGeneration)) {
      return false;
    }
    for (final path in paths) {
      final incorporated = coverage.states[path];
      if (incorporated == null) return false;
      final matching = state.documentBuffers.where((b) => b.filePath == path);
      // A model overlay alone cannot prove that dirty/conflicted editor state
      // or history has handled an external notification.
      if (matching.any(
        (b) =>
            b.isDirty ||
            (incorporated.exists &&
                (b.diskState != DocumentDiskState.present ||
                    b.diskSnapshot?.contentHash != incorporated.hash)) ||
            (!incorporated.exists && b.diskState != DocumentDiskState.deleted),
      )) {
        return false;
      }
      try {
        final resolution = await resolveAnchoredPath(
          anchor,
          path,
          allowRoot: false,
          allowMissingAncestors: true,
        );
        if (!incorporated.exists) {
          if (resolution.type != FileSystemEntityType.notFound) return false;
        } else {
          if (resolution.type != FileSystemEntityType.file) return false;
          final disk = await _service.fileSnapshot(resolution.path);
          if (disk.contentHash != incorporated.hash ||
              await _service.fileChangedSince(resolution.path, disk)) {
            return false;
          }
        }
      } on Object {
        return false;
      }
      if (!_fileMonitorOperationIsCurrent(workspaceGeneration) ||
          !identical(coverage, _reconciledNotifications) ||
          state.workspace?.id != coverage.workspaceId ||
          !_preparedInputsCurrent(state.workspace!, state.documentBuffers) ||
          !identical(
            coverage.modules,
            state.workspace?.writersideProject?.modules,
          )) {
        return false;
      }
    }
    for (final path in paths) {
      final incorporated = coverage.states[path]!;
      if (state.documentBuffers
          .where((b) => b.filePath == path)
          .any(
            (b) =>
                b.isDirty ||
                (incorporated.exists &&
                    (b.diskState != DocumentDiskState.present ||
                        b.diskSnapshot?.contentHash != incorporated.hash)) ||
                (!incorporated.exists &&
                    b.diskState != DocumentDiskState.deleted),
          )) {
        return false;
      }
    }
    return true;
  }

  void _scheduleMonitoredWorkspaceRefresh() {
    _workspaceRefreshDebounce?.cancel();
    _workspaceRefreshDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!ref.mounted) return;
      // Our own filesystem writes also emit notifications. A background
      // refresh must not invalidate an operation already loading its result.
      if (state.isLoading || _workspaceFileOperationDepth > 0) {
        _scheduleMonitoredWorkspaceRefresh();
        return;
      }
      unawaited(refreshWorkspaceFromDiskPreservingOpenTabs());
    });
  }

  Future<void> _applyExternalFileState(
    DocumentBuffer original,
    WorkspaceFileMonitorEvent event, {
    List<LocalHistoryPathTarget>? historyTargets,
    required int workspaceGeneration,
  }) async {
    if (!_fileMonitorOperationIsCurrent(workspaceGeneration)) return;
    final current = state.documentBuffers
        .where((buffer) => buffer.id == original.id)
        .firstOrNull;
    final path = current?.filePath;
    if (current == null || path == null) {
      return;
    }
    final destinationPath = event.destinationPath;
    if (event.kind == WorkspaceFileEventKind.moved &&
        destinationPath != null &&
        p.equals(path, event.path)) {
      await _applyExternalMove(
        current,
        destinationPath,
        preparedTargets: historyTargets,
        workspaceGeneration: workspaceGeneration,
      );
      return;
    }
    if (event.kind == WorkspaceFileEventKind.deleted) {
      await _applyExternalDeletion(
        current,
        path,
        preparedTargets: historyTargets,
        workspaceGeneration: workspaceGeneration,
      );
      return;
    }
    try {
      final disk = await _service.loadTextWithSnapshot(path);
      var latest = _externalOperationBuffer(
        current,
        path,
        workspaceGeneration: workspaceGeneration,
      );
      if (latest == null) return;
      if (_sameFileSnapshot(current.diskSnapshot, disk.snapshot)) {
        return;
      }
      await _localHistory.capturePath(
        path: path,
        text: disk.text,
        format: disk.format,
        reason: LocalHistoryCaptureReason.externalChange,
      );
      latest = _externalOperationBuffer(
        current,
        path,
        workspaceGeneration: workspaceGeneration,
      );
      if (latest == null) return;
      if (latest.isDirty) {
        _localHistory.observeEdit(
          latest.copyWith(text: latest.lastSavedText),
          latest,
        );
        _updateBufferFromMonitor(
          latest.copyWith(
            diskState: DocumentDiskState.conflict,
            diskVersionText: disk.text,
            diskVersionSnapshot: disk.snapshot,
          ),
          workspaceGeneration: workspaceGeneration,
        );
        return;
      }
      final reloaded = latest.copyWith(
        text: disk.text,
        lastSavedText: disk.text,
        dirty: false,
        diskSnapshot: disk.snapshot,
        format: disk.format,
        revision: latest.revision + 1,
        diskState: DocumentDiskState.present,
        diskVersionText: null,
        diskVersionSnapshot: null,
      );
      _updateBufferFromMonitor(
        reloaded,
        workspaceGeneration: workspaceGeneration,
      );
      if (state.activeBufferId == reloaded.id && state.workspace != null) {
        final workspace = state.workspace!.copyWith(
          activeFileSnapshot: disk.snapshot,
        );
        final reparsed = await _reparseWithDocumentBuffers(workspace, reloaded);
        if (_fileMonitorOperationIsCurrent(workspaceGeneration) &&
            state.activeBufferId == reloaded.id &&
            state.activeBuffer?.revision == reloaded.revision &&
            _preparedInputsCurrent(reparsed, state.documentBuffers)) {
          state = state.copyWith(
            workspace: reparsed,
            preview: _safePreview(reparsed, reloaded),
          );
          _recordActivePreviewRevision();
        }
      }
    } on FileSystemException {
      await _applyExternalDeletion(
        current,
        path,
        preparedTargets: historyTargets,
        workspaceGeneration: workspaceGeneration,
      );
    } on FormatException {
      // Invalid UTF-8 remains on disk and must not replace an editable buffer.
    }
  }

  Future<void> _applyExternalDirectoryState(
    WorkspaceFileMonitorEvent event,
    List<DocumentBuffer> matching,
    List<LocalHistoryPathTarget> historyTargets,
    int workspaceGeneration,
  ) async {
    if (!_fileMonitorOperationIsCurrent(workspaceGeneration)) return;
    final sourcePath = event.path;
    final destinationPath = event.destinationPath;
    final transitions = <LocalHistoryBufferPathTransition>[];
    if (event.kind == WorkspaceFileEventKind.moved && destinationPath != null) {
      for (final buffer in matching) {
        final path = buffer.filePath;
        if (path == null || !p.isWithin(sourcePath, path)) continue;
        transitions.add(
          _localHistory.beginBufferPathTransition(
            bufferId: buffer.id,
            sourcePath: path,
            destinationPath: p.join(
              destinationPath,
              p.relative(path, from: sourcePath),
            ),
          ),
        );
      }
    }
    String? historyOperationId;
    var historyCommitted = false;
    var buffersPublished = false;
    try {
      if (event.kind == WorkspaceFileEventKind.moved &&
          destinationPath != null) {
        historyCommitted = await _localHistory.runStagedPathRemap(
          sourcePath: sourcePath,
          destinationPath: destinationPath,
          preparedTargets: historyTargets,
          filesystemAlreadyCommitted: true,
          filesystemOperation: () async {
            if (!_fileMonitorOperationIsCurrent(workspaceGeneration)) {
              return false;
            }
            final sourceExists = await _service.pathExists(sourcePath);
            if (!_fileMonitorOperationIsCurrent(workspaceGeneration)) {
              return false;
            }
            final destinationExists = await _service.pathExists(
              destinationPath,
            );
            return _fileMonitorOperationIsCurrent(workspaceGeneration) &&
                !sourceExists &&
                destinationExists;
          },
          didCommit: (value) => value,
          onOperationStaged: (value) => historyOperationId = value,
        );
        if (!historyCommitted ||
            !_fileMonitorOperationIsCurrent(workspaceGeneration)) {
          return;
        }
        buffersPublished = true;
        for (final original in matching) {
          final oldPath = original.filePath;
          if (oldPath == null || !p.isWithin(sourcePath, oldPath)) continue;
          final movedPath = p.join(
            destinationPath,
            p.relative(oldPath, from: sourcePath),
          );
          if (!await _applyExternalMove(
            original,
            movedPath,
            reconcileHistory: false,
            workspaceGeneration: workspaceGeneration,
          )) {
            if (!_fileMonitorOperationIsCurrent(workspaceGeneration)) return;
            final live = state.documentBuffers
                .where((buffer) => buffer.id == original.id)
                .firstOrNull;
            // Closing the tab while its destination is loading completes the
            // editor-publication obligation for that member. The stable store
            // lineage was already moved by the directory-wide operation.
            if (live == null ||
                (live.filePath != null &&
                    p.equals(live.filePath!, movedPath))) {
              continue;
            }
            buffersPublished = false;
          }
        }
      } else if (event.kind == WorkspaceFileEventKind.deleted) {
        for (final original in matching) {
          final path = original.filePath;
          if (path == null || !p.isWithin(sourcePath, path)) continue;
          final latest = _externalOperationBuffer(original, path);
          if (!_fileMonitorOperationIsCurrent(workspaceGeneration)) return;
          if (latest == null) continue;
          final protected = await _localHistory.captureBeforeLoss(
            LocalHistoryBufferSnapshot.fromBuffer(latest),
            LocalHistoryCaptureReason.beforeDelete,
          );
          if (!protected) {
            _localHistory.retainBufferWorkAfterCommittedPathLoss(latest.id);
          }
        }
        historyCommitted = await _localHistory.runStagedPathDeletion(
          path: sourcePath,
          recursive: true,
          preparedTargets: historyTargets,
          filesystemAlreadyCommitted: true,
          filesystemOperation: () async {
            if (!_fileMonitorOperationIsCurrent(workspaceGeneration)) {
              return false;
            }
            final exists = await _service.pathExists(sourcePath);
            return _fileMonitorOperationIsCurrent(workspaceGeneration) &&
                !exists;
          },
          didCommit: (value) => value,
          onOperationStaged: (value) => historyOperationId = value,
        );
        if (!historyCommitted ||
            !_fileMonitorOperationIsCurrent(workspaceGeneration)) {
          return;
        }
        for (final original in matching) {
          final path = original.filePath;
          if (path == null || !p.isWithin(sourcePath, path)) continue;
          final latest = _externalOperationBuffer(
            original,
            path,
            workspaceGeneration: workspaceGeneration,
          );
          if (latest != null) {
            _updateBufferFromMonitor(
              latest.copyWith(diskState: DocumentDiskState.deleted),
              workspaceGeneration: workspaceGeneration,
            );
          }
        }
        buffersPublished = true;
      }
      if (buffersPublished) {
        await _localHistory.acknowledgeStagedPathOperation(historyOperationId);
      }
    } finally {
      if (!historyCommitted) {
        await _localHistory.cancelStagedPathOperation(historyOperationId);
      }
      for (final transition in transitions) {
        await _localHistory.finishBufferPathTransition(
          transition,
          committed: buffersPublished,
        );
      }
      await _persistPendingHistoryReconciliation();
    }
  }

  Future<void> _applyExternalClosedFileState(
    WorkspaceFileMonitorEvent event,
    List<LocalHistoryPathTarget> historyTargets,
    int workspaceGeneration,
  ) async {
    if (!_fileMonitorOperationIsCurrent(workspaceGeneration)) return;
    final destinationPath = event.destinationPath;
    String? historyOperationId;
    var committed = false;
    try {
      if (event.kind == WorkspaceFileEventKind.moved &&
          destinationPath != null) {
        committed = await _localHistory.runStagedPathRemap(
          sourcePath: event.path,
          destinationPath: destinationPath,
          preparedTargets: historyTargets,
          filesystemAlreadyCommitted: true,
          filesystemOperation: () async {
            if (!_fileMonitorOperationIsCurrent(workspaceGeneration)) {
              return false;
            }
            final sourceExists = await _service.pathExists(event.path);
            if (!_fileMonitorOperationIsCurrent(workspaceGeneration)) {
              return false;
            }
            final destinationExists = await _service.pathExists(
              destinationPath,
            );
            return _fileMonitorOperationIsCurrent(workspaceGeneration) &&
                !sourceExists &&
                destinationExists;
          },
          didCommit: (value) => value,
          onOperationStaged: (value) => historyOperationId = value,
        );
      } else if (event.kind == WorkspaceFileEventKind.deleted) {
        committed = await _localHistory.runStagedPathDeletion(
          path: event.path,
          recursive: false,
          preparedTargets: historyTargets,
          filesystemAlreadyCommitted: true,
          filesystemOperation: () async {
            if (!_fileMonitorOperationIsCurrent(workspaceGeneration)) {
              return false;
            }
            final exists = await _service.pathExists(event.path);
            return _fileMonitorOperationIsCurrent(workspaceGeneration) &&
                !exists;
          },
          didCommit: (value) => value,
          onOperationStaged: (value) => historyOperationId = value,
        );
      }
      if (committed) {
        await _localHistory.acknowledgeStagedPathOperation(historyOperationId);
      }
    } finally {
      if (!committed) {
        await _localHistory.cancelStagedPathOperation(historyOperationId);
      }
      await _persistPendingHistoryReconciliation();
    }
  }

  DocumentBuffer? _externalOperationBuffer(
    DocumentBuffer anchor,
    String expectedPath, {
    int? workspaceGeneration,
  }) {
    if (!ref.mounted ||
        (workspaceGeneration != null &&
            !_fileMonitorOperationIsCurrent(workspaceGeneration))) {
      return null;
    }
    final current = state.documentBuffers
        .where((buffer) => buffer.id == anchor.id)
        .firstOrNull;
    if (current == null ||
        current.filePath != expectedPath ||
        !_sameFileSnapshot(current.diskSnapshot, anchor.diskSnapshot)) {
      return null;
    }
    return current;
  }

  Future<void> _applyExternalDeletion(
    DocumentBuffer current,
    String path, {
    List<LocalHistoryPathTarget>? preparedTargets,
    required int workspaceGeneration,
  }) async {
    if (!_fileMonitorOperationIsCurrent(workspaceGeneration) ||
        await _service.pathExists(path) ||
        !_fileMonitorOperationIsCurrent(workspaceGeneration)) {
      return;
    }
    var latest = _externalOperationBuffer(
      current,
      path,
      workspaceGeneration: workspaceGeneration,
    );
    if (latest == null) return;
    final protected = await _localHistory.captureBeforeLoss(
      LocalHistoryBufferSnapshot.fromBuffer(latest),
      LocalHistoryCaptureReason.beforeDelete,
    );
    if (!protected) {
      _localHistory.retainBufferWorkAfterCommittedPathLoss(latest.id);
    }
    latest = _externalOperationBuffer(
      current,
      path,
      workspaceGeneration: workspaceGeneration,
    );
    if (latest == null) return;
    if (await _service.pathExists(path) ||
        !_fileMonitorOperationIsCurrent(workspaceGeneration)) {
      _scheduleMonitoredWorkspaceRefresh();
      return;
    }
    String? historyOperationId;
    final committed = await _localHistory.runStagedPathDeletion(
      path: path,
      recursive: false,
      preparedTargets: preparedTargets,
      boundBufferId: protected ? latest.id : null,
      filesystemAlreadyCommitted: true,
      filesystemOperation: () async =>
          _externalOperationBuffer(
                current,
                path,
                workspaceGeneration: workspaceGeneration,
              ) !=
              null &&
          !await _service.pathExists(path) &&
          _fileMonitorOperationIsCurrent(workspaceGeneration),
      didCommit: (value) => value,
      onOperationStaged: (value) => historyOperationId = value,
    );
    if (!committed) {
      _scheduleMonitoredWorkspaceRefresh();
      return;
    }
    final afterHistory = _externalOperationBuffer(
      current,
      path,
      workspaceGeneration: workspaceGeneration,
    );
    if (afterHistory == null) return;
    _updateBufferFromMonitor(
      afterHistory.copyWith(diskState: DocumentDiskState.deleted),
      workspaceGeneration: workspaceGeneration,
    );
    await _localHistory.acknowledgeStagedPathOperation(historyOperationId);
  }

  Future<bool> _applyExternalMove(
    DocumentBuffer current,
    String destinationPath, {
    bool reconcileHistory = true,
    List<LocalHistoryPathTarget>? preparedTargets,
    required int workspaceGeneration,
  }) async {
    if (!_fileMonitorOperationIsCurrent(workspaceGeneration)) return false;
    final oldPath = current.filePath;
    if (oldPath == null) {
      return false;
    }
    final historyTransition = reconcileHistory
        ? _localHistory.beginBufferPathTransition(
            bufferId: current.id,
            sourcePath: oldPath,
            destinationPath: destinationPath,
          )
        : null;
    var historyPathCommitted = false;
    var historyTransitionFinished = false;
    String? historyOperationId;
    var historyOperationCommitted = false;
    try {
      final disk = reconcileHistory
          ? await _localHistory.runStagedPathRemap(
              sourcePath: oldPath,
              destinationPath: destinationPath,
              preparedTargets: preparedTargets,
              boundBufferId: current.id,
              filesystemAlreadyCommitted: true,
              filesystemOperation: () async {
                final loaded = await _service.loadTextWithSnapshot(
                  destinationPath,
                );
                return _externalOperationBuffer(
                          current,
                          oldPath,
                          workspaceGeneration: workspaceGeneration,
                        ) ==
                        null
                    ? null
                    : loaded;
              },
              didCommit: (value) => value != null,
              onOperationStaged: (value) => historyOperationId = value,
            )
          : await _service.loadTextWithSnapshot(destinationPath);
      if (disk == null) return false;
      final contentChanged = !_sameFileSnapshot(
        current.diskSnapshot,
        disk.snapshot,
      );
      historyOperationCommitted = reconcileHistory;
      if (_externalOperationBuffer(
            current,
            oldPath,
            workspaceGeneration: workspaceGeneration,
          ) ==
          null) {
        return false;
      }
      if (contentChanged) {
        await _localHistory.capturePath(
          path: destinationPath,
          text: disk.text,
          format: disk.format,
          reason: LocalHistoryCaptureReason.externalChange,
        );
      }
      final latest = _externalOperationBuffer(
        current,
        oldPath,
        workspaceGeneration: workspaceGeneration,
      );
      if (latest == null) return false;
      final remapped = latest.copyWith(
        filePath: destinationPath,
        text: latest.isDirty || !contentChanged ? latest.text : disk.text,
        lastSavedText: contentChanged && !latest.isDirty
            ? disk.text
            : latest.lastSavedText,
        dirty: latest.isDirty,
        diskSnapshot: contentChanged && !latest.isDirty
            ? disk.snapshot
            : latest.diskSnapshot,
        format: contentChanged && !latest.isDirty ? disk.format : latest.format,
        revision: contentChanged && !latest.isDirty
            ? latest.revision + 1
            : latest.revision,
        diskState: latest.isDirty && contentChanged
            ? DocumentDiskState.conflict
            : DocumentDiskState.present,
        diskVersionText: latest.isDirty && contentChanged ? disk.text : null,
        diskVersionSnapshot: latest.isDirty && contentChanged
            ? disk.snapshot
            : null,
      );
      final workspace = state.workspace;
      final remappedTabs = workspace == null
          ? const <String>[]
          : [
              for (final openPath in workspace.openFilePaths)
                p.equals(openPath, oldPath) ? destinationPath : openPath,
            ];
      final active = state.activeBufferId == latest.id;
      state = state.copyWith(
        documentBuffers: _replaceBuffer(state.documentBuffers, remapped),
        workspace: workspace?.copyWith(
          activeFilePath: active ? destinationPath : workspace.activeFilePath,
          activeFileSnapshot: active
              ? remapped.diskSnapshot
              : workspace.activeFileSnapshot,
          openFilePaths: remappedTabs,
        ),
      );
      historyPathCommitted = true;
      _fileMonitor.updateOpenFilePaths(
        state.documentBuffers
            .map((buffer) => buffer.filePath)
            .whereType<String>(),
      );
      if (historyTransition != null) {
        await _localHistory.finishBufferPathTransition(
          historyTransition,
          committed: true,
        );
        historyTransitionFinished = true;
      }
      if (reconcileHistory) {
        await _localHistory.acknowledgeStagedPathOperation(historyOperationId);
      }
      final derivedWorkspace = state.workspace;
      final derivedOperationRevision = _activeDocumentRevision;
      if (active &&
          derivedWorkspace != null &&
          _canPublishActiveDerivedContent(
            operationRevision: derivedOperationRevision,
            workspaceId: derivedWorkspace.id,
            bufferId: remapped.id,
            path: destinationPath,
            revision: remapped.revision,
            source: remapped.text,
          )) {
        final reparsed = await _reparseWithDocumentBuffers(
          derivedWorkspace,
          remapped,
        );
        if (_preparedInputsCurrent(reparsed, state.documentBuffers) &&
            _canPublishActiveDerivedContent(
              operationRevision: derivedOperationRevision,
              workspaceId: derivedWorkspace.id,
              bufferId: remapped.id,
              path: destinationPath,
              revision: remapped.revision,
              source: remapped.text,
            )) {
          state = state.copyWith(
            workspace: reparsed.copyWith(
              activeFileSnapshot: remapped.diskSnapshot,
              openFilePaths: state.workspace!.openFilePaths,
            ),
            preview: _safePreview(reparsed, remapped),
          );
          _recordActivePreviewRevision();
        }
      }
      _schedulePersistence();
      return true;
    } on FileSystemException {
      if (!reconcileHistory) {
        return _publishExternalMoveAfterHistoryCommit(
          current,
          oldPath,
          destinationPath,
          workspaceGeneration,
        );
      }
      final latest = _externalOperationBuffer(
        current,
        oldPath,
        workspaceGeneration: workspaceGeneration,
      );
      if (latest != null) {
        _updateBufferFromMonitor(
          latest.copyWith(diskState: DocumentDiskState.deleted),
          workspaceGeneration: workspaceGeneration,
        );
      }
      return false;
    } on FormatException {
      if (!reconcileHistory) {
        return _publishExternalMoveAfterHistoryCommit(
          current,
          oldPath,
          destinationPath,
          workspaceGeneration,
        );
      }
      // A single-file reconciliation has not committed history when decoding
      // fails inside its atomic store operation, so retain the old binding.
      return false;
    } finally {
      if (reconcileHistory && !historyOperationCommitted) {
        await _localHistory.cancelStagedPathOperation(historyOperationId);
      }
      if (historyTransition != null && !historyTransitionFinished) {
        await _localHistory.finishBufferPathTransition(
          historyTransition,
          committed: historyPathCommitted,
        );
      }
      await _persistPendingHistoryReconciliation();
    }
  }

  bool _publishExternalMoveAfterHistoryCommit(
    DocumentBuffer original,
    String oldPath,
    String destinationPath,
    int workspaceGeneration,
  ) {
    final latest = _externalOperationBuffer(
      original,
      oldPath,
      workspaceGeneration: workspaceGeneration,
    );
    if (latest == null) return false;
    final remapped = latest.copyWith(
      filePath: destinationPath,
      diskSnapshot: null,
      diskState: DocumentDiskState.changed,
      diskVersionText: null,
      diskVersionSnapshot: null,
    );
    final workspace = state.workspace;
    final active = state.activeBufferId == latest.id;
    state = state.copyWith(
      documentBuffers: _replaceBuffer(state.documentBuffers, remapped),
      workspace: workspace?.copyWith(
        activeFilePath: active ? destinationPath : workspace.activeFilePath,
        activeFileSnapshot: active ? null : workspace.activeFileSnapshot,
        openFilePaths: [
          for (final path in workspace.openFilePaths)
            p.equals(path, oldPath) ? destinationPath : path,
        ],
      ),
    );
    _fileMonitor.updateOpenFilePaths(
      state.documentBuffers
          .map((buffer) => buffer.filePath)
          .whereType<String>(),
    );
    _schedulePersistence();
    _scheduleMonitoredWorkspaceRefresh();
    return true;
  }

  bool _fileMonitorOperationIsCurrent(int workspaceGeneration) =>
      ref.mounted && workspaceGeneration == _fileMonitorWorkspaceGeneration;

  bool _fileMonitorWorkspaceIsCurrent(
    Workspace workspace,
    int workspaceGeneration,
  ) {
    if (!_fileMonitorOperationIsCurrent(workspaceGeneration)) return false;
    final current = state.workspace;
    return current != null && current.id == workspace.id;
  }

  void _invalidateFileMonitorWorkspace() {
    _acceptFileMonitorEvents = false;
    _fileMonitorWorkspaceGeneration++;
    _pendingFileMonitorEvents.clear();
    _deferredFileMonitorEvents.clear();
    _reconciledNotifications = null;
    unawaited(_runFileMonitorLifecycle(_fileMonitor.stop));
  }

  void _updateBufferFromMonitor(
    DocumentBuffer buffer, {
    int? workspaceGeneration,
  }) {
    if (!ref.mounted ||
        (workspaceGeneration != null &&
            !_fileMonitorOperationIsCurrent(workspaceGeneration))) {
      return;
    }
    state = state.copyWith(
      documentBuffers: _replaceBuffer(state.documentBuffers, buffer),
      workspace: state.activeBufferId == buffer.id
          ? state.workspace?.copyWith(activeFileSnapshot: buffer.diskSnapshot)
          : state.workspace,
    );
    _schedulePersistence();
  }

  Future<bool> reloadBufferFromDisk(String bufferId) async {
    final buffer = state.documentBuffers
        .where((candidate) => candidate.id == bufferId)
        .firstOrNull;
    final path = buffer?.filePath;
    if (buffer == null || path == null || !await _service.pathExists(path)) {
      return false;
    }
    if (!_bufferOperationTargetIsCurrent(buffer)) return false;
    if (!await _localHistory.captureBeforeLoss(
      LocalHistoryBufferSnapshot.fromBuffer(buffer),
      LocalHistoryCaptureReason.beforeReload,
    )) {
      return false;
    }
    if (!_bufferOperationTargetIsCurrent(buffer)) return false;
    final disk = await _service.loadTextWithSnapshot(path);
    if (!_bufferOperationTargetIsCurrent(buffer)) return false;
    await _localHistory.capturePath(
      path: path,
      text: disk.text,
      format: disk.format,
      reason: LocalHistoryCaptureReason.externalChange,
      force: false,
    );
    if (!_bufferOperationTargetIsCurrent(buffer)) return false;
    final reloaded = buffer.copyWith(
      text: disk.text,
      lastSavedText: disk.text,
      dirty: false,
      diskSnapshot: disk.snapshot,
      format: disk.format,
      revision: buffer.revision + 1,
      diskState: DocumentDiskState.present,
      diskVersionText: null,
      diskVersionSnapshot: null,
      recovered: false,
    );
    _updateBufferFromMonitor(reloaded);
    final derivedWorkspace = state.workspace;
    final derivedOperationRevision = _activeDocumentRevision;
    if (derivedWorkspace != null &&
        _canPublishActiveDerivedContent(
          operationRevision: derivedOperationRevision,
          workspaceId: derivedWorkspace.id,
          bufferId: reloaded.id,
          path: path,
          revision: reloaded.revision,
          source: reloaded.text,
        )) {
      final workspace = await _reparseWithDocumentBuffers(
        derivedWorkspace.copyWith(activeFileSnapshot: disk.snapshot),
        reloaded,
      );
      if (_preparedInputsCurrent(workspace, state.documentBuffers) &&
          _canPublishActiveDerivedContent(
            operationRevision: derivedOperationRevision,
            workspaceId: derivedWorkspace.id,
            bufferId: reloaded.id,
            path: path,
            revision: reloaded.revision,
            source: reloaded.text,
          )) {
        state = state.copyWith(
          workspace: workspace,
          preview: _safePreview(workspace, reloaded),
        );
        _recordActivePreviewRevision();
      }
    }
    return true;
  }

  bool _bufferOperationTargetIsCurrent(DocumentBuffer target) {
    final current = state.documentBuffers
        .where((buffer) => buffer.id == target.id)
        .firstOrNull;
    return current != null &&
        current.filePath == target.filePath &&
        current.revision == target.revision &&
        current.text == target.text;
  }

  void keepBufferVersion(String bufferId) {
    final buffer = state.documentBuffers
        .where((candidate) => candidate.id == bufferId)
        .firstOrNull;
    if (buffer == null) {
      return;
    }
    _updateBufferFromMonitor(
      buffer.copyWith(
        diskState: buffer.filePath == null
            ? DocumentDiskState.present
            : DocumentDiskState.changed,
        diskVersionText: null,
        diskVersionSnapshot: null,
      ),
    );
  }

  bool get activeDocumentNeedsSaveLocation {
    final workspace = state.workspace;
    return workspace != null && state.activeBuffer?.isUntitled == true;
  }

  ActiveDocumentSaveTarget? captureActiveDocumentSaveTarget() {
    final workspace = state.workspace;
    if (workspace == null) {
      return null;
    }
    final buffer = state.activeBuffer;
    if (buffer == null) {
      return null;
    }
    return ActiveDocumentSaveTarget._(
      workspaceId: workspace.id,
      bufferId: buffer.id,
      path: buffer.filePath,
      documentRevision: _activeDocumentRevision,
      editRevision: buffer.revision,
      snapshot: buffer.diskSnapshot,
      text: buffer.text,
      workspaceKind: workspace.kind,
      format: buffer.format,
    );
  }

  bool isActiveDocumentSaveTargetCurrent(ActiveDocumentSaveTarget target) {
    final workspace = state.workspace;
    return _isCurrentActiveDocument(
          target.documentRevision,
          workspaceId: target.workspaceId,
          bufferId: target.bufferId,
          activeFilePath: target.path,
        ) &&
        workspace != null &&
        state.activeBuffer?.id == target.bufferId &&
        state.activeBuffer?.revision == target.editRevision &&
        state.activeBuffer?.text == target.text &&
        _sameFileSnapshot(state.activeBuffer?.diskSnapshot, target.snapshot);
  }

  /// Starts a document from Welcome, replacing the previous workspace only
  /// after its buffers have been resolved and their history has been flushed.
  Future<bool> createMarkdownWorkspace() async {
    final previous = state;
    final previousOperation = _activeDocumentRevision;
    if (previous.hasUnsavedChanges || previous.isLoading) return false;
    final historySettled = await _localHistory.flushAll(
      previous.documentBuffers,
    );
    if (!ref.mounted) return false;
    final liveBuffers = state.documentBuffers;
    if (_activeDocumentRevision != previousOperation ||
        !identical(state.workspace, previous.workspace) ||
        liveBuffers.length != previous.documentBuffers.length ||
        liveBuffers.indexed.any(
          (entry) => !identical(entry.$2, previous.documentBuffers[entry.$1]),
        )) {
      return false;
    }
    _invalidateFileMonitorWorkspace();
    _cancelPendingDerivedRefresh();
    _cancelAllAutoSaves();
    _invalidateActiveDocumentOperations();
    _removalOperationRevision++;
    _restoredRecoveryOwnerIdsByBuffer.clear();
    state = const WorkspaceState();
    for (final buffer in previous.documentBuffers) {
      await _localHistory.handleBufferClosed(
        buffer.id,
        historySettled: historySettled,
      );
    }
    await createMarkdownFile();
    return true;
  }

  Future<void> createMarkdownFile() async {
    if (state.workspace?.isRemote == true) {
      await createNextcloudNote();
      return;
    }
    _cancelPendingDerivedRefresh();
    final operationRevision = _invalidateActiveDocumentOperations();
    _resetSaveTracking(dirty: true);
    final viewModeChange = _showEditorForNewFile();
    final currentWorkspace = state.workspace;
    final untitledWorkspace = _service.createUntitledMarkdown();
    final sequence = ++_untitledSequence;
    final buffer = DocumentBuffer.untitled(
      id: 'untitled:${DateTime.now().microsecondsSinceEpoch}:$sequence',
      name: 'Untitled $sequence',
      mode:
          _settingsController.state.documentViewMode ==
              DocumentViewModePreference.preview
          ? DocumentViewModePreference.editor
          : _settingsController.state.documentViewMode,
    );
    final buffers = [...state.documentBuffers, buffer];
    final workspace = currentWorkspace == null
        ? untitledWorkspace.copyWith(markdown: null)
        : currentWorkspace.copyWith(
            activeFilePath: null,
            activeFileSnapshot: null,
            markdown: null,
          );
    state = WorkspaceState(
      workspace: workspace,
      preview: _safePreview(workspace, buffer),
      documentBuffers: buffers,
      activeBufferId: buffer.id,
      isLoading: false,
    );
    unawaited(_localHistory.observeOpened(buffer));
    _recordActivePreviewRevision();
    _schedulePersistence();
    await viewModeChange;
    final reparsed = await _reparseWithDocumentBuffers(
      workspace,
      buffer,
      buffers: buffers,
    );
    if (_preparedInputsCurrent(reparsed, state.documentBuffers) &&
        _canPublishActiveDerivedContent(
          operationRevision: operationRevision,
          workspaceId: workspace.id,
          bufferId: buffer.id,
          path: null,
          revision: buffer.revision,
          source: buffer.text,
        )) {
      state = state.copyWith(
        workspace: reparsed,
        preview: _safePreview(reparsed, buffer),
      );
      _recordActivePreviewRevision();
    }
    await _startMonitoring(state.workspace ?? workspace);
  }

  Future<void> openPath(String path) async {
    _invalidateFileMonitorWorkspace();
    _removalOperationRevision++;
    final closingBuffers = state.documentBuffers;
    final historySettled = await _localHistory.flushAll(closingBuffers);
    _cancelPendingDerivedRefresh();
    _cancelAllAutoSaves();
    final operationRevision = _invalidateActiveDocumentOperations();
    _resetSaveTracking();
    _restoredRecoveryOwnerIdsByBuffer.clear();
    state = const WorkspaceState(isLoading: true);
    for (final buffer in closingBuffers) {
      await _localHistory.handleBufferClosed(
        buffer.id,
        historySettled: historySettled,
      );
    }
    try {
      final workspace = await _service.openPath(path);
      final active = workspace.activeFilePath;
      final load = active == null
          ? null
          : await _service.loadTextWithSnapshot(active);
      final text = load?.text ?? '';
      final loadedWorkspace = load == null
          ? workspace
          : workspace.copyWith(activeFileSnapshot: load.snapshot);
      final buffer = load == null || active == null
          ? null
          : _fileBuffer(
              active,
              load,
              mode: _settingsController.state.documentViewMode,
            );
      final preview = buffer == null
          ? null
          : _safePreview(loadedWorkspace, buffer);
      if (!_isCurrentActiveDocumentOperation(operationRevision)) {
        return;
      }
      state = WorkspaceState(
        workspace: loadedWorkspace,
        activeText: text,
        preview: preview,
        documentBuffers: buffer == null ? const [] : [buffer],
        activeBufferId: buffer?.id,
      );
      if (buffer != null) unawaited(_localHistory.observeOpened(buffer));
      _recordActivePreviewRevision();
      if (buffer != null &&
          _writersideSourceMismatch(loadedWorkspace, buffer)) {
        _requestDerivedRefresh(rebuildPreview: true);
      }
      await _startMonitoring(loadedWorkspace);
      _schedulePersistence();
      _resetSaveTracking();
      final recentPath = workspace.kind == WorkspaceKind.singleMarkdown
          ? workspace.activeFilePath ?? workspace.rootPath
          : workspace.rootPath;
      await _settingsController.recordOpenedWorkspace(
        path: recentPath,
        kind: workspace.kind.name,
      );
    } on Object catch (error, stackTrace) {
      busyMarkDebugLogError(
        '[BusyMark] Open failed',
        error,
        stackTrace,
        context: {'path': busyMarkLogPath(path)},
      );
      if (_isCurrentActiveDocumentOperation(operationRevision)) {
        state = state.copyWith(
          isLoading: false,
          message: WorkspaceMessage(
            WorkspaceMessageCode.openFailed,
            error: error,
          ),
        );
      }
    }
  }

  Future<bool> createWritersideProject(
    WritersideProjectCreateRequest request,
  ) async {
    _invalidateFileMonitorWorkspace();
    _removalOperationRevision++;
    final closingBuffers = state.documentBuffers;
    final historySettled = await _localHistory.flushAll(closingBuffers);
    _cancelPendingDerivedRefresh();
    _cancelAllAutoSaves();
    final operationRevision = _invalidateActiveDocumentOperations();
    _resetSaveTracking();
    _restoredRecoveryOwnerIdsByBuffer.clear();
    state = const WorkspaceState(isLoading: true);
    for (final buffer in closingBuffers) {
      await _localHistory.handleBufferClosed(
        buffer.id,
        historySettled: historySettled,
      );
    }
    try {
      final workspace = await _service.createWritersideProject(request);
      final active = workspace.activeFilePath;
      final load = active == null
          ? null
          : await _service.loadTextWithSnapshot(active);
      final text = load?.text ?? '';
      final loadedWorkspace = load == null
          ? workspace
          : workspace.copyWith(activeFileSnapshot: load.snapshot);
      final buffer = load == null || active == null
          ? null
          : _fileBuffer(
              active,
              load,
              mode: _settingsController.state.documentViewMode,
            );
      final preview = buffer == null
          ? null
          : _safePreview(loadedWorkspace, buffer);
      if (!_isCurrentActiveDocumentOperation(operationRevision)) {
        return false;
      }
      state = WorkspaceState(
        workspace: loadedWorkspace,
        activeText: text,
        preview: preview,
        documentBuffers: buffer == null ? const [] : [buffer],
        activeBufferId: buffer?.id,
      );
      if (buffer != null) unawaited(_localHistory.observeOpened(buffer));
      _recordActivePreviewRevision();
      if (buffer != null &&
          _writersideSourceMismatch(loadedWorkspace, buffer)) {
        _requestDerivedRefresh(rebuildPreview: true);
      }
      await _startMonitoring(loadedWorkspace);
      _schedulePersistence();
      _resetSaveTracking();
      await _settingsController.recordOpenedWorkspace(
        path: workspace.rootPath,
        kind: workspace.kind.name,
      );
      return true;
    } on Object catch (error, stackTrace) {
      busyMarkDebugLogError(
        '[BusyMark] Create Writerside project failed',
        error,
        stackTrace,
        context: {
          'parent': busyMarkLogPath(request.parentDirectoryPath),
          'directory': request.directoryName,
        },
      );
      if (_isCurrentActiveDocumentOperation(operationRevision)) {
        state = state.copyWith(
          isLoading: false,
          message: WorkspaceMessage(
            WorkspaceMessageCode.createWritersideProjectFailed,
            error: error,
          ),
        );
      }
      return false;
    }
  }

  Future<bool> createWritersideTopic(
    WritersideTopicCreateRequest request, {
    String? instanceTreePath,
    String? initialSource,
  }) => _runWorkspaceFileOperation((workspace) async {
    final paths = instanceTreePath == null
        ? workspace.writersideModule!.instances
              .map((instance) => instance.sourceTreePath)
              .toList()
        : [instanceTreePath];
    _requireCleanAffectedFiles(workspace, paths);
    final created = await _service.createWritersideTopic(
      workspace,
      request,
      instanceTreePath: instanceTreePath,
      initialSource: initialSource,
      validateBeforePublish: () async =>
          _requireCleanAffectedFiles(workspace, paths),
    );
    return created.topicPath;
  }, openForEditing: true);

  Future<List<WritersideMarkdownImportCandidate>?>
  discoverWritersideMarkdownImport(String sourceDirectoryPath) async {
    try {
      return await _service.discoverWritersideMarkdownImport(
        sourceDirectoryPath,
      );
    } on Object catch (error, stackTrace) {
      busyMarkDebugLogError(
        '[BusyMark] Discover Writerside Markdown import failed',
        error,
        stackTrace,
        context: {'source': busyMarkLogPath(sourceDirectoryPath)},
      );
      state = state.copyWith(
        isLoading: false,
        message: WorkspaceMessage(
          WorkspaceMessageCode.fileOperationFailed,
          error: error,
        ),
      );
      return null;
    }
  }

  Future<bool> addWritersideMarkdownTopics(
    WritersideMarkdownTopicImportRequest request,
  ) => _runWorkspaceFileOperation((workspace) async {
    _requireCleanWritersideProject(workspace);
    final updated = await _service.addWritersideMarkdownTopics(
      workspace,
      request,
      validateBeforePublish: () async =>
          _requireCleanWritersideProject(workspace),
    );
    return updated.activeFilePath;
  }, openForEditing: true);

  Future<WritersideInstanceMutationResult?> createWritersideInstance(
    WritersideInstanceCreateRequest request,
  ) async {
    if (state.isDirty) {
      return null;
    }
    WritersideInstanceMutationResult? result;
    final succeeded = await _runWorkspaceFileOperation((workspace) async {
      result = await _service.createWritersideInstance(workspace, request);
      return result!.firstTopicPath;
    });
    return succeeded ? result : null;
  }

  Future<WritersideInstanceMutationResult?> updateWritersideInstance(
    WritersideInstanceUpdateRequest request,
  ) async {
    if (state.isDirty) {
      return null;
    }
    WritersideInstanceMutationResult? result;
    final activePath = state.workspace?.activeFilePath;
    final succeeded = await _runWorkspaceFileOperation((workspace) async {
      result = await _service.updateWritersideInstance(workspace, request);
      return activePath != null && p.equals(activePath, request.treePath)
          ? result!.treePath
          : null;
    });
    return succeeded ? result : null;
  }

  Future<void> openFile(String path) => openPath(path);

  Future<void> openFolder(String path) => openPath(path);

  Future<bool> openActiveFile(String path) async {
    return _openActiveFile(path);
  }

  Future<bool> activateNextOpenFileTab() => _activateOpenFileTab(1);

  Future<bool> activatePreviousOpenFileTab() => _activateOpenFileTab(-1);

  Future<bool> activateDocumentBuffer(String bufferId) async {
    final workspace = state.workspace;
    final buffer = state.documentBuffers
        .where((candidate) => candidate.id == bufferId)
        .firstOrNull;
    if (workspace == null || buffer == null) {
      return false;
    }
    if (state.activeBufferId == bufferId &&
        workspace.activeFilePath == buffer.filePath) {
      return true;
    }
    return _activateBuffer(
      workspace,
      buffer,
      documentBuffers: state.documentBuffers,
      openFilePaths: workspace.openFilePaths,
    );
  }

  Future<bool> closeActiveOpenFileTab() async {
    final activeFilePath = state.workspace?.activeFilePath;
    if (activeFilePath == null) {
      return false;
    }
    return closeOpenFileTab(activeFilePath);
  }

  Future<bool> closeAllOpenFileTabs() async {
    final workspace = state.workspace;
    if (workspace == null || state.documentBuffers.isEmpty) {
      return false;
    }
    if (state.hasUnsavedChanges) {
      return false;
    }
    final closingBuffers = state.documentBuffers.toList(growable: false);
    final historySettled = await _localHistory.flushAll(closingBuffers);
    final liveBuffers = state.documentBuffers;
    if (!identical(state.workspace, workspace) ||
        liveBuffers.length != closingBuffers.length ||
        liveBuffers.indexed.any(
          (entry) => !identical(entry.$2, closingBuffers[entry.$1]),
        )) {
      return false;
    }
    await _clearOpenFileTabs(workspace);
    for (final buffer in closingBuffers) {
      await _localHistory.handleBufferClosed(
        buffer.id,
        historySettled: historySettled,
      );
    }
    return true;
  }

  Future<bool> createWorkspaceFile(
    String directoryPath,
    String fileName,
  ) async {
    final created = await _runWorkspaceFileOperation((workspace) async {
      return _service.createFile(workspace, directoryPath, fileName);
    });
    if (created) {
      await _showEditorForNewFile();
    }
    return created;
  }

  Future<bool> renameWorkspaceEntity(String path, String newName) async {
    final activeFilePath = state.workspace?.activeFilePath;
    return _runWorkspaceFileOperation((workspace) async {
      final expectedTarget = p.normalize(p.join(p.dirname(path), newName));
      final transitions = _beginLocalHistoryPathTransitions(
        path,
        expectedTarget,
      );
      var committed = false;
      String? historyOperationId;
      try {
        final target = await _localHistory.runStagedPathRemap(
          sourcePath: path,
          destinationPath: expectedTarget,
          filesystemOperation: () =>
              _service.renameEntity(workspace, path, newName),
          didCommit: (_) => true,
          onOperationStaged: (value) => historyOperationId = value,
        );
        committed = true;
        _remapOpenWorkspacePaths(workspace, path, target);
        await _localHistory.acknowledgeStagedPathOperation(historyOperationId);
        return _remapMovedPath(activeFilePath, path, target);
      } finally {
        if (!committed) {
          await _localHistory.cancelStagedPathOperation(historyOperationId);
        }
        await _finishLocalHistoryPathTransitions(
          transitions,
          committed: committed,
        );
      }
    });
  }

  Future<bool> moveWorkspaceEntity(
    String sourcePath,
    String targetDirectoryPath,
  ) async {
    final activeFilePath = state.workspace?.activeFilePath;
    return _runWorkspaceFileOperation((workspace) async {
      final expectedTarget = p.normalize(
        p.join(targetDirectoryPath, p.basename(sourcePath)),
      );
      final transitions = _beginLocalHistoryPathTransitions(
        sourcePath,
        expectedTarget,
      );
      var committed = false;
      String? historyOperationId;
      try {
        final target = await _localHistory.runStagedPathRemap(
          sourcePath: sourcePath,
          destinationPath: expectedTarget,
          filesystemOperation: () =>
              _service.moveEntity(workspace, sourcePath, targetDirectoryPath),
          didCommit: (_) => true,
          onOperationStaged: (value) => historyOperationId = value,
        );
        committed = true;
        _remapOpenWorkspacePaths(workspace, sourcePath, target);
        await _localHistory.acknowledgeStagedPathOperation(historyOperationId);
        return _remapMovedPath(activeFilePath, sourcePath, target);
      } finally {
        if (!committed) {
          await _localHistory.cancelStagedPathOperation(historyOperationId);
        }
        await _finishLocalHistoryPathTransitions(
          transitions,
          committed: committed,
        );
      }
    });
  }

  Future<bool> deleteWorkspaceEntity(String path) async {
    if (!await _protectWorkspaceEntityBeforeDelete(path)) return false;
    String? historyOperationId;
    var committed = false;
    try {
      final deleted = await _runWorkspaceFileOperation((workspace) async {
        committed = await _localHistory.runStagedPathDeletion(
          path: path,
          recursive: true,
          filesystemOperation: () async {
            _authorizeRemovedBuffers(p.normalize(path), workspace);
            await _service.deleteEntity(workspace, path);
            _removalAuthorizations[p.normalize(path)]?.committed = true;
            return true;
          },
          didCommit: (value) => value,
          onOperationStaged: (value) => historyOperationId = value,
        );
        if (committed && historyOperationId != null) {
          _historyOperationsAwaitingWorkspaceRefresh.add(historyOperationId!);
        }
        return null;
      });
      if (deleted) {
        await _localHistory.acknowledgeStagedPathOperation(historyOperationId);
        _historyOperationsAwaitingWorkspaceRefresh.remove(historyOperationId);
      }
      return deleted;
    } finally {
      if (!committed) {
        await _localHistory.cancelStagedPathOperation(historyOperationId);
      }
      _removalAuthorizations.remove(p.normalize(path));
    }
  }

  Future<bool> _protectWorkspaceEntityBeforeDelete(String path) async {
    final historyPolicy = _localHistory.policy;
    if (!historyPolicy.recordingEnabled || historyPolicy.excludes(path)) {
      return true;
    }
    final workspace = state.workspace;
    if (workspace == null) return false;
    final protectedPaths = <String>{};
    for (final buffer in state.documentBuffers) {
      final filePath = buffer.filePath;
      if (filePath == null ||
          !_isEligibleLocalHistoryPath(filePath) ||
          historyPolicy.excludes(filePath) ||
          !(p.equals(filePath, path) || p.isWithin(path, filePath))) {
        continue;
      }
      if (!await _localHistory.captureBeforeLoss(
        LocalHistoryBufferSnapshot.fromBuffer(buffer),
        LocalHistoryCaptureReason.beforeDelete,
      )) {
        return false;
      }
      protectedPaths.add(p.normalize(filePath));
    }
    for (final file in workspace.files) {
      final filePath = file.absolutePath;
      if (protectedPaths.contains(p.normalize(filePath)) ||
          !_isEligibleLocalHistoryPath(filePath) ||
          historyPolicy.excludes(filePath) ||
          !(p.equals(filePath, path) || p.isWithin(path, filePath))) {
        continue;
      }
      try {
        final load = await _service.loadTextWithSnapshot(filePath);
        if (!await _localHistory.capturePathBeforeLoss(
          path: filePath,
          text: load.text,
          format: load.format,
          reason: LocalHistoryCaptureReason.beforeDelete,
        )) {
          return false;
        }
      } on Object {
        return false;
      }
    }
    return true;
  }

  Future<bool> moveWritersideTocEntry({
    required String treePath,
    required List<int> sourcePath,
    required WritersideTopicCreatePlacement placement,
    required List<int>? referencePath,
    WritersideTocNodeIdentity? sourceIdentity,
    WritersideTocNodeIdentity? referenceIdentity,
  }) {
    return _runWorkspaceFileOperation((workspace) async {
      _requireCleanAffectedFiles(workspace, [treePath]);
      await _service.moveWritersideTocEntry(
        workspace,
        treePath: treePath,
        sourcePath: sourcePath,
        placement: placement,
        referencePath: referencePath,
        sourceIdentity: sourceIdentity,
        referenceIdentity: referenceIdentity,
        validateBeforePublish: () async =>
            _requireCleanAffectedFiles(workspace, [treePath]),
      );
      return null;
    });
  }

  void _requireCleanAffectedFiles(Workspace workspace, Iterable<String> paths) {
    if (state.workspace?.id != workspace.id ||
        paths.any(
          (path) => state.dirtyBuffers.any(
            (buffer) =>
                buffer.filePath != null && p.equals(path, buffer.filePath!),
          ),
        )) {
      throw const BusyMarkException('writerside.toc.tree-changed');
    }
  }

  void _requireCleanWritersideProject(Workspace workspace) {
    if (!ref.mounted ||
        state.workspace?.id != workspace.id ||
        state.dirtyBuffers.any(
          (buffer) =>
              buffer.filePath != null &&
              isWritersideProjectPath(workspace, buffer.filePath!),
        )) {
      throw const BusyMarkException(
        'writerside.topic-file.project-buffers-dirty',
      );
    }
  }

  Future<WritersideTitleEditSession?> prepareWritersideTitleEdit({
    required String treePath,
    required List<int> tocPath,
    required WritersideTocNodeIdentity identity,
    required String topicModuleRoot,
    required String topicPath,
  }) async {
    final workspace = state.workspace;
    if (workspace == null) return null;
    try {
      return await _service.prepareWritersideTitleEdit(
        workspace,
        treePath: treePath,
        tocPath: tocPath,
        identity: identity,
        topicModuleRoot: topicModuleRoot,
        topicPath: topicPath,
      );
    } on Object catch (error) {
      state = state.copyWith(
        message: WorkspaceMessage(
          WorkspaceMessageCode.fileOperationFailed,
          error: error,
        ),
      );
      return null;
    }
  }

  Future<bool> duplicateWritersideTopic({
    required String treePath,
    required List<int> tocPath,
    required WritersideTocNodeIdentity identity,
    required String topicPath,
    required String expectedSource,
    required String newName,
  }) => _runWorkspaceFileOperation((workspace) async {
    _requireCleanAffectedFiles(workspace, [treePath, topicPath]);
    return _service.duplicateWritersideTopic(
      workspace,
      treePath: treePath,
      tocPath: tocPath,
      identity: identity,
      topicPath: topicPath,
      expectedSource: expectedSource,
      newName: newName,
      validateBeforePublish: () async =>
          _requireCleanAffectedFiles(workspace, [treePath, topicPath]),
    );
  });

  Future<bool> editWritersideTitles(
    WritersideTitleEditSession session,
    WritersideTitleEdit edit,
  ) => _runWorkspaceFileOperation((workspace) async {
    void validate() => _requireCleanAffectedFiles(workspace, [
      session.topic.filePath,
      session.treePath,
    ]);
    validate();
    await _service.editWritersideTitles(
      session,
      edit,
      validateBeforeCommit: validate,
      onCommitted: (writes, snapshots) {
        state = state.copyWith(
          documentBuffers: [
            for (final buffer in state.documentBuffers)
              if (writes[buffer.filePath] case final write?)
                buffer.copyWith(
                  text: write.text,
                  lastSavedText: write.text,
                  dirty: false,
                  diskSnapshot: snapshots[buffer.filePath],
                  revision: buffer.revision + 1,
                )
              else
                buffer,
          ],
        );
      },
    );
    return null;
  });

  Future<WritersideTocMutationResult?> insertWritersideTocElement({
    required String treePath,
    required WritersideTocInsertRequest request,
    String? expectedTopicPath,
    String? expectedTopicSource,
  }) async {
    WritersideTocMutationResult? result;
    final succeeded = await _runWorkspaceFileOperation((workspace) async {
      _requireCleanAffectedFiles(workspace, [treePath]);
      result = await _service.insertWritersideTocElement(
        workspace,
        treePath: treePath,
        request: request,
        expectedTopicPath: expectedTopicPath,
        expectedTopicSource: expectedTopicSource,
        validateBeforePublish: () async =>
            _requireCleanAffectedFiles(workspace, [treePath]),
      );
      return null;
    });
    return succeeded ? result : null;
  }

  Future<WritersideTocMutationResult?> groupWritersideTocElements({
    required String treePath,
    required List<WritersideTocMoveEntry> entries,
    required String title,
  }) async {
    WritersideTocMutationResult? result;
    final succeeded = await _runWorkspaceFileOperation((workspace) async {
      _requireCleanAffectedFiles(workspace, [treePath]);
      result = await _service.groupWritersideTocElements(
        workspace,
        treePath: treePath,
        entries: entries,
        title: title,
        validateBeforePublish: () async =>
            _requireCleanAffectedFiles(workspace, [treePath]),
      );
      return null;
    });
    return succeeded ? result : null;
  }

  Future<WritersideTocMutationResult?> sortWritersideTocChildren({
    required String treePath,
    required List<int> nodePath,
    required WritersideTocNodeIdentity identity,
  }) async {
    WritersideTocMutationResult? result;
    final succeeded = await _runWorkspaceFileOperation((workspace) async {
      _requireCleanAffectedFiles(workspace, [treePath]);
      result = await _service.sortWritersideTocChildren(
        workspace,
        treePath: treePath,
        nodePath: nodePath,
        identity: identity,
        validateBeforePublish: () async =>
            _requireCleanAffectedFiles(workspace, [treePath]),
      );
      return null;
    });
    return succeeded ? result : null;
  }

  Future<bool> setWritersideHomePage({
    required String treePath,
    required List<int> nodePath,
    required WritersideTocNodeIdentity expectedIdentity,
  }) => _runWorkspaceFileOperation((workspace) async {
    _requireCleanAffectedFiles(workspace, [treePath]);
    await _service.setWritersideHomePage(
      workspace,
      treePath: treePath,
      nodePath: nodePath,
      expectedIdentity: expectedIdentity,
      validateBeforePublish: () async =>
          _requireCleanAffectedFiles(workspace, [treePath]),
    );
    return null;
  });

  Future<WritersideTocMutationResult?> dragWritersideTocEntries({
    required String treePath,
    required WritersideTocBatchMoveRequest request,
  }) async {
    WritersideTocMutationResult? result;
    final success = await _runWorkspaceFileOperation((workspace) async {
      _requireCleanAffectedFiles(workspace, [treePath]);
      result = await _service.dragWritersideTocEntries(
        workspace,
        treePath: treePath,
        request: request,
        validateBeforePublish: () async =>
            _requireCleanAffectedFiles(workspace, [treePath]),
      );
      return null;
    });
    return success ? result : null;
  }

  Future<bool> moveWritersideTocEntries({
    required String treePath,
    required List<WritersideTocMoveEntry> sources,
    required WritersideTopicCreatePlacement placement,
    required List<int>? referencePath,
    WritersideTocNodeIdentity? referenceIdentity,
  }) {
    return _runWorkspaceFileOperation((workspace) async {
      _requireCleanAffectedFiles(workspace, [treePath]);
      await _service.moveWritersideTocEntries(
        workspace,
        treePath: treePath,
        sources: sources,
        placement: placement,
        referencePath: referencePath,
        referenceIdentity: referenceIdentity,
        validateBeforePublish: () async =>
            _requireCleanAffectedFiles(workspace, [treePath]),
      );
      return null;
    });
  }

  Future<bool> removeWritersideTocEntry({
    required String treePath,
    required List<int> nodePath,
    WritersideTocNodeIdentity? expectedIdentity,
  }) {
    return _runWorkspaceFileOperation((workspace) async {
      _requireCleanAffectedFiles(workspace, [treePath]);
      await _service.removeWritersideTocEntry(
        workspace,
        treePath: treePath,
        nodePath: nodePath,
        expectedIdentity: expectedIdentity,
        validateBeforePublish: () async =>
            _requireCleanAffectedFiles(workspace, [treePath]),
      );
      return null;
    });
  }

  Future<bool> removeWritersideTocEntries({
    required String treePath,
    required List<WritersideTocRemovalRequest> requests,
  }) {
    return _runWorkspaceFileOperation((workspace) async {
      _requireCleanAffectedFiles(workspace, [treePath]);
      await _service.removeWritersideTocEntries(
        workspace,
        treePath: treePath,
        requests: requests,
        validateBeforePublish: () async =>
            _requireCleanAffectedFiles(workspace, [treePath]),
      );
      return null;
    });
  }

  Future<bool> renameWritersideTopicFile(
    String topicPath,
    String newFileName, {
    String? topicModuleRoot,
  }) async {
    final workspace = state.workspace;
    if (workspace == null) return false;
    final ownerRoot = topicModuleRoot ?? workspace.writersideModule?.rootPath;
    if (ownerRoot == null) return false;
    final plan = await prepareWritersideTopicRename(
      topicPath,
      newFileName,
      topicModuleRoot: ownerRoot,
    );
    return plan == null ? false : await applyWritersideTopicRename(plan);
  }

  Future<WritersideTopicRenamePlan?> prepareWritersideTopicRename(
    String topicPath,
    String newFileName, {
    required String topicModuleRoot,
  }) async {
    final workspace = state.workspace;
    if (workspace == null) return null;
    try {
      final plan = await _service.prepareWritersideTopicRename(
        workspace,
        topicPath: topicPath,
        newFileName: newFileName,
        topicModuleRoot: topicModuleRoot,
      );
      return plan;
    } on Object catch (error, stackTrace) {
      busyMarkDebugLogError(
        '[BusyMark] Prepare topic rename failed',
        error,
        stackTrace,
        context: {'root': busyMarkLogPath(workspace.rootPath)},
      );
      state = state.copyWith(
        message: WorkspaceMessage(
          WorkspaceMessageCode.fileOperationFailed,
          error: error,
        ),
      );
      return null;
    }
  }

  Future<bool> applyWritersideTopicRename(WritersideTopicRenamePlan plan) {
    final activeFilePath = state.workspace?.activeFilePath;
    return _runWorkspaceFileOperation((workspace) async {
      void validate(Iterable<String> _) =>
          _requireCleanWritersideProject(workspace);
      validate(plan.affectedPaths);
      final transitions = _beginLocalHistoryPathTransitions(
        plan.oldTopicPath,
        plan.newTopicPath,
      );
      var committed = false;
      String? historyOperationId;
      try {
        final result = await _localHistory.runStagedPathRemap(
          sourcePath: plan.oldTopicPath,
          destinationPath: plan.newTopicPath,
          filesystemOperation: () => _service.applyWritersideTopicRename(
            plan,
            validateBeforePublish: validate,
          ),
          didCommit: (_) => true,
          onOperationStaged: (value) => historyOperationId = value,
        );
        final target = result.newTopicPath;
        committed = true;
        _remapOpenWorkspacePaths(workspace, plan.oldTopicPath, target);
        await _localHistory.acknowledgeStagedPathOperation(historyOperationId);
        return _remapMovedPath(activeFilePath, plan.oldTopicPath, target);
      } finally {
        if (!committed) {
          await _localHistory.cancelStagedPathOperation(historyOperationId);
        }
        await _finishLocalHistoryPathTransitions(
          transitions,
          committed: committed,
        );
      }
    });
  }

  Future<bool> deleteWritersideTopicFile(String topicPath) {
    return _runWorkspaceFileOperation((workspace) async {
      await _service.deleteWritersideTopicFile(workspace, topicPath);
      return null;
    });
  }

  Future<WritersideTopicRemovalAnalysis?> analyzeWritersideTopicRemoval({
    required String topicPath,
    required WritersideTopicRemovalMode mode,
    String? treePath,
    List<int>? nodePath,
  }) async {
    final workspace = state.workspace;
    if (workspace == null) {
      return null;
    }
    try {
      return await _service.analyzeWritersideTopicRemoval(
        workspace,
        topicPath: topicPath,
        mode: mode,
        treePath: treePath,
        nodePath: nodePath,
      );
    } on Object catch (error, stackTrace) {
      busyMarkDebugLogError(
        '[BusyMark] Writerside topic removal analysis failed',
        error,
        stackTrace,
        context: {'root': busyMarkLogPath(workspace.rootPath)},
      );
      state = state.copyWith(
        isLoading: false,
        message: WorkspaceMessage(
          WorkspaceMessageCode.fileOperationFailed,
          error: error,
        ),
      );
      return null;
    }
  }

  Future<WritersideTopicRemovalResult?> applyWritersideTopicRemoval(
    WritersideTopicRemovalRequest request,
  ) async {
    final removalRevision = ++_removalOperationRevision;
    final deleting =
        request.analysis.mode == WritersideTopicRemovalMode.safeDeleteFile;
    final deletedPath = p.normalize(request.analysis.topicPath);
    if (deleting && !await _protectWorkspaceEntityBeforeDelete(deletedPath)) {
      return null;
    }
    WritersideTopicRemovalResult? result;
    String? historyOperationId;
    var historyCommitted = false;
    try {
      final success = await _runWorkspaceFileOperation((workspace) async {
        void validate(Iterable<String> _) {
          if (!ref.mounted || removalRevision != _removalOperationRevision) {
            throw const BusyMarkException(
              'writerside.topic-file.project-buffers-dirty',
            );
          }
          _requireCleanWritersideProject(workspace);
          if (deleting) _authorizeRemovedBuffers(deletedPath, workspace);
        }

        validate(const []);
        result = deleting
            ? await _localHistory.runStagedPathDeletion(
                path: deletedPath,
                recursive: false,
                filesystemOperation: () => _service.applyWritersideTopicRemoval(
                  workspace,
                  request,
                  validateBeforeCommit: validate,
                ),
                didCommit: (value) => value?.deletedFile == true,
                onOperationStaged: (value) => historyOperationId = value,
              )
            : await _service.applyWritersideTopicRemoval(
                workspace,
                request,
                validateBeforeCommit: validate,
              );
        if (result?.deletedFile == true) {
          _removalAuthorizations[deletedPath]?.committed = true;
          historyCommitted = true;
          if (historyOperationId != null) {
            // The filesystem and history mutation are committed, but the
            // pre-delete workspace/session still names this tab until the
            // refresh publishes. Keep the durable journal through that
            // boundary so a crash cannot restore a replacement lineage.
            _historyOperationsAwaitingWorkspaceRefresh.add(historyOperationId!);
          }
        }
        return null;
      });
      return success ? result : null;
    } finally {
      if (deleting) {
        if (!historyCommitted) {
          await _localHistory.cancelStagedPathOperation(historyOperationId);
        }
        _removalAuthorizations.remove(deletedPath);
      }
    }
  }

  Future<bool> closeOpenFileTab(String path) => _closeOpenFileTabNow(path);

  Future<bool> _closeOpenFileTabNow(
    String path, {
    DocumentBuffer? discardAuthorization,
    bool? preflushedHistorySettled,
  }) async {
    final workspace = state.workspace;
    if (workspace == null || !workspace.openFilePaths.contains(path)) {
      return false;
    }
    final closingBuffer = state.bufferForPath(path);
    if (discardAuthorization != null &&
        !identical(closingBuffer, discardAuthorization)) {
      return false;
    }
    if (closingBuffer?.isDirty == true && discardAuthorization == null) {
      return false;
    }
    var historySettled = preflushedHistorySettled ?? true;
    if (closingBuffer != null && preflushedHistorySettled == null) {
      historySettled = await _localHistory.flushBuffer(closingBuffer);
      final currentClosingBuffer = state.documentBuffers
          .where((candidate) => candidate.id == closingBuffer.id)
          .firstOrNull;
      if (!identical(currentClosingBuffer, closingBuffer)) {
        if (currentClosingBuffer != null) {
          _scheduleAutoSave(currentClosingBuffer.id);
        }
        return false;
      }
    }
    final closingWorkspace = state.workspace;
    if (closingWorkspace == null ||
        closingWorkspace.id != workspace.id ||
        !closingWorkspace.openFilePaths.contains(path)) {
      return false;
    }
    final closedIndex = closingWorkspace.openFilePaths.indexOf(path);
    final nextOpenFilePaths = [
      for (final openPath in closingWorkspace.openFilePaths)
        if (openPath != path) openPath,
    ];
    final remainingBuffers = [
      for (final buffer in state.documentBuffers)
        if (buffer.filePath != path) buffer,
    ];
    if (nextOpenFilePaths.isEmpty) {
      final nextUntitled = remainingBuffers.firstOrNull;
      if (nextUntitled == null) {
        await _clearOpenFileTabs(closingWorkspace);
        if (closingBuffer != null) {
          await _localHistory.handleBufferClosed(
            closingBuffer.id,
            historySettled: historySettled,
          );
        }
      } else {
        final closed = await _activateBuffer(
          closingWorkspace,
          nextUntitled,
          documentBuffers: remainingBuffers,
          openFilePaths: nextOpenFilePaths,
        );
        if (!closed) return false;
        if (closingBuffer != null) {
          await _localHistory.handleBufferClosed(
            closingBuffer.id,
            historySettled: historySettled,
          );
        }
      }
      return true;
    }
    if (closingWorkspace.activeFilePath != path) {
      state = state.copyWith(
        workspace: closingWorkspace.copyWith(openFilePaths: nextOpenFilePaths),
        documentBuffers: remainingBuffers,
        clearMessage: true,
      );
      if (closingBuffer != null) {
        await _localHistory.handleBufferClosed(
          closingBuffer.id,
          historySettled: historySettled,
        );
      }
      await _validateActive(rebuildPreview: _activeModeShowsPreview);
      return true;
    }
    final nextIndex = closedIndex <= 0
        ? 0
        : math.min(closedIndex - 1, nextOpenFilePaths.length - 1);
    final closed = await _openActiveFile(
      nextOpenFilePaths[nextIndex],
      openFilePaths: nextOpenFilePaths,
      documentBuffers: remainingBuffers,
    );
    if (closed && closingBuffer != null) {
      await _localHistory.handleBufferClosed(
        closingBuffer.id,
        historySettled: historySettled,
      );
    }
    return closed;
  }

  Future<bool> closeDocumentBuffer(
    String bufferId, {
    bool discard = false,
  }) async {
    final closingWorkspace = state.workspace;
    _cancelAutoSave(bufferId);
    return _enqueueBufferWrite(bufferId, () async {
      var closed = false;
      try {
        closed = await _closeDocumentBufferNow(bufferId, discard: discard);
        return closed;
      } finally {
        // A rejected close leaves ordinary dirty work eligible for autosave.
        // Finalize inside the write queue so shutdown's drain and final timer
        // cancellation retain ownership; never schedule in a new workspace.
        if (!closed &&
            ref.mounted &&
            closingWorkspace != null &&
            state.workspace?.id == closingWorkspace.id &&
            state.workspace?.openedAt == closingWorkspace.openedAt) {
          _scheduleAutoSave(bufferId);
        }
      }
    });
  }

  Future<bool> _closeDocumentBufferNow(
    String bufferId, {
    required bool discard,
  }) async {
    final buffer = state.documentBuffers
        .where((candidate) => candidate.id == bufferId)
        .firstOrNull;
    if (buffer == null || (buffer.isDirty && !discard)) {
      return false;
    }
    if (buffer.isDirty &&
        !_localHistory.canDiscardPristineDraft(buffer) &&
        !await _localHistory.captureBeforeLoss(
          LocalHistoryBufferSnapshot.fromBuffer(buffer),
          LocalHistoryCaptureReason.beforeDiscard,
        )) {
      return false;
    }
    final afterProtection = state.documentBuffers
        .where((candidate) => candidate.id == bufferId)
        .firstOrNull;
    if (afterProtection == null ||
        afterProtection.revision != buffer.revision ||
        afterProtection.text != buffer.text ||
        afterProtection.isDirty != buffer.isDirty) {
      return false;
    }
    final historySettled = await _localHistory.flushBuffer(afterProtection);
    final current = state.documentBuffers
        .where((candidate) => candidate.id == bufferId)
        .firstOrNull;
    if (current == null ||
        current.revision != afterProtection.revision ||
        current.text != afterProtection.text ||
        current.isDirty != afterProtection.isDirty) {
      return false;
    }
    if (current.filePath case final path?) {
      return _closeOpenFileTabNow(
        path,
        discardAuthorization: current.isDirty ? current : null,
        preflushedHistorySettled: historySettled,
      );
    }
    final workspace = state.workspace;
    if (workspace == null) {
      return false;
    }
    final remaining = [
      for (final candidate in state.documentBuffers)
        if (candidate.id != bufferId) candidate,
    ];
    if (remaining.isEmpty) {
      if (_supportsOpenFileTabs(workspace)) {
        // The last buffer can be an untitled draft in a folder/project.
        // Discarding that draft closes a view and retains the workspace.
        await _clearOpenFileTabs(workspace);
      } else {
        _removalOperationRevision++;
        state = workspace.isRemote
            ? WorkspaceState(workspace: workspace.copyWith(markdown: null))
            : const WorkspaceState();
        _fileMonitor.updateOpenFilePaths(const <String>[]);
        _schedulePersistence();
      }
      await _localHistory.handleBufferClosed(
        bufferId,
        historySettled: historySettled,
      );
      return true;
    }
    final closed = await _activateBuffer(
      workspace,
      remaining.last,
      documentBuffers: remaining,
      openFilePaths: workspace.openFilePaths,
    );
    if (closed) {
      await _localHistory.handleBufferClosed(
        bufferId,
        historySettled: historySettled,
      );
    }
    return closed;
  }

  Future<bool> _activateOpenFileTab(int delta) async {
    final workspace = state.workspace;
    if (workspace == null || state.documentBuffers.length < 2) {
      return false;
    }
    final activeIndex = state.activeBufferId == null
        ? -1
        : state.documentBuffers.indexWhere(
            (buffer) => buffer.id == state.activeBufferId,
          );
    final nextIndex = activeIndex < 0
        ? 0
        : (activeIndex + delta) % state.documentBuffers.length;
    final normalizedIndex = nextIndex < 0
        ? nextIndex + state.documentBuffers.length
        : nextIndex;
    return activateDocumentBuffer(state.documentBuffers[normalizedIndex].id);
  }

  Future<void> _clearOpenFileTabs(Workspace workspace) async {
    if (!_supportsOpenFileTabs(workspace)) {
      return;
    }
    _cancelPendingDerivedRefresh();
    _removalOperationRevision++;
    _cancelAllAutoSaves();
    _invalidateActiveDocumentOperations();
    _resetSaveTracking();
    final List<Diagnostic> diagnostics = switch (workspace.kind) {
      WorkspaceKind.writersideModule =>
        workspace.writersideModule?.diagnostics ?? const [],
      WorkspaceKind.untitledMarkdown ||
      WorkspaceKind.singleMarkdown ||
      WorkspaceKind.markdownFolder ||
      WorkspaceKind.nextcloudNotes => const [],
    };
    state = state.copyWith(
      workspace: workspace.copyWith(
        activeFilePath: null,
        activeFileModifiedAt: null,
        activeFileSnapshot: null,
        openFilePaths: const [],
        sourceOverrides: const {},
        diagnostics: diagnostics,
        markdown: null,
      ),
      activeText: '',
      preview: null,
      documentBuffers: const [],
      activeBufferId: null,
      clearMessage: true,
    );
    _recordActivePreviewRevision();
    _fileMonitor.updateOpenFilePaths(const <String>[]);
    _schedulePersistence();
    final cleared = state.workspace!;
    final operation = _activeDocumentRevision;
    try {
      final prepared = await _service.withDocumentSources(cleared, const {});
      if (prepared.writersideProject != null &&
          !await prepared.writersideProject!.observedInputsMatchDisk()) {
        throw WritersideInputsChanged(prepared.rootPath);
      }
      if (ref.mounted &&
          operation == _activeDocumentRevision &&
          state.workspace?.id == cleared.id &&
          state.documentBuffers.isEmpty) {
        state = state.copyWith(workspace: prepared);
      }
    } on Object catch (error, stackTrace) {
      busyMarkDebugLogError(
        '[BusyMark] Closed-buffer reconciliation failed',
        error,
        stackTrace,
      );
      if (ref.mounted && state.workspace?.id == cleared.id) {
        _scheduleMonitoredWorkspaceRefresh();
      }
    }
  }

  Future<bool> _openActiveFile(
    String path, {
    List<String>? openFilePaths,
    List<DocumentBuffer>? documentBuffers,
  }) async {
    final workspace = state.workspace;
    if (workspace == null) {
      return false;
    }
    final workspaceId = workspace.id;
    final buffers = documentBuffers ?? state.documentBuffers;
    final existing = buffers
        .where((buffer) => buffer.filePath == path)
        .firstOrNull;
    if (existing != null) {
      final requestedOpenFilePaths =
          openFilePaths ?? _openFileTabPaths(workspace, path);
      if (state.activeBufferId == existing.id &&
          workspace.activeFilePath == existing.filePath &&
          _samePathList(workspace.openFilePaths, requestedOpenFilePaths)) {
        return true;
      }
      return _activateBuffer(
        workspace,
        existing,
        documentBuffers: buffers,
        openFilePaths: requestedOpenFilePaths,
      );
    }
    _cancelPendingDerivedRefresh();
    final operationRevision = _invalidateActiveDocumentOperations();
    final requestedOpenFilePaths =
        openFilePaths ?? _openFileTabPaths(workspace, path);
    final initialOpenPaths = workspace.openFilePaths.toSet();
    final addedOpenPaths = [
      for (final requestedPath in requestedOpenFilePaths)
        if (!initialOpenPaths.contains(requestedPath)) requestedPath,
    ];
    try {
      final load = await _service.loadTextWithSnapshot(path);
      final nextWorkspace = workspace.copyWith(
        activeFilePath: path,
        activeFileSnapshot: load.snapshot,
        openFilePaths: requestedOpenFilePaths,
      );
      if (!_isCurrentActiveDocumentOperation(operationRevision) ||
          state.workspace?.id != workspaceId) {
        return false;
      }
      final buffer = _fileBuffer(
        path,
        load,
        mode: _settingsController.state.documentViewMode,
      );
      _restoredRecoveryOwnerIdsByBuffer.remove(buffer.id);
      var reparsed = await _reparseWithDocumentBuffers(
        nextWorkspace,
        buffer,
        buffers: buffers,
      );
      if (_isCurrentActiveDocumentOperation(operationRevision) &&
          !_preparedInputsCurrent(reparsed, [
            ...state.documentBuffers,
            buffer,
          ])) {
        reparsed = await _reparseWithDocumentBuffers(
          state.workspace ?? nextWorkspace,
          buffer,
          buffers: state.documentBuffers,
        );
      }
      if (!_isCurrentActiveDocumentOperation(operationRevision) ||
          state.workspace?.id != workspaceId) {
        return false;
      }
      final liveBuffers = state.documentBuffers;
      if (liveBuffers.any(
        (candidate) =>
            candidate.id == buffer.id || candidate.filePath == buffer.filePath,
      )) {
        return false;
      }
      final reconciledBuffers = [...liveBuffers, buffer];
      final liveOpenPaths = state.workspace?.openFilePaths ?? const <String>[];
      final reconciledOpenPaths = <String>[
        ...liveOpenPaths,
        for (final addedPath in addedOpenPaths)
          if (!liveOpenPaths.contains(addedPath)) addedPath,
      ];
      final sourcesCurrent = _preparedInputsCurrent(
        reparsed,
        reconciledBuffers,
      );
      final publishedWorkspace =
          (sourcesCurrent
                  ? reparsed
                  : (state.workspace ?? nextWorkspace).copyWith(markdown: null))
              .copyWith(
                activeFilePath: path,
                activeFileSnapshot: load.snapshot,
                openFilePaths: reconciledOpenPaths,
              );
      if (sourcesCurrent) {
        _preparedInputs[publishedWorkspace] = _preparedInputs[reparsed];
      }
      state = state.copyWith(
        workspace: publishedWorkspace,
        activeText: load.text,
        preview: sourcesCurrent
            ? _safePreview(publishedWorkspace, buffer)
            : null,
        documentBuffers: reconciledBuffers,
        activeBufferId: buffer.id,
        clearMessage: true,
      );
      if (!sourcesCurrent) {
        _requestDerivedRefresh(
          rebuildPreview: _activeModeShowsPreview,
          refreshOutline: !_activeModeShowsPreview,
        );
      }
      unawaited(_localHistory.observeOpened(buffer));
      _recordActivePreviewRevision();
      _fileMonitor.updateOpenFilePaths(
        reconciledBuffers
            .map((candidate) => candidate.filePath)
            .whereType<String>(),
      );
      _resetSaveTracking();
      return true;
    } on Object catch (error, stackTrace) {
      busyMarkDebugLogError(
        '[BusyMark] Could not open file',
        error,
        stackTrace,
        context: {'path': busyMarkLogPath(path)},
      );
      if (_isCurrentActiveDocumentOperation(operationRevision)) {
        state = state.copyWith(
          message: WorkspaceMessage(
            WorkspaceMessageCode.couldNotOpenFile,
            error: error,
          ),
        );
      }
      return false;
    }
  }

  Future<bool> _activateBuffer(
    Workspace workspace,
    DocumentBuffer buffer, {
    required List<DocumentBuffer> documentBuffers,
    required List<String> openFilePaths,
  }) async {
    _cancelPendingDerivedRefresh();
    final operationRevision = _invalidateActiveDocumentOperations();
    final workspaceId = workspace.id;
    final targetBufferId = buffer.id;
    final initialBufferIds = state.documentBuffers
        .map((candidate) => candidate.id)
        .toSet();
    final initialBuffersById = {
      for (final candidate in state.documentBuffers) candidate.id: candidate,
    };
    final requestedBufferIds = documentBuffers
        .map((candidate) => candidate.id)
        .toSet();
    final intentionallyRemovedBufferIds = initialBufferIds.difference(
      requestedBufferIds,
    );
    final intentionallyAddedBuffers = [
      for (final candidate in documentBuffers)
        if (!initialBufferIds.contains(candidate.id)) candidate,
    ];
    final initialOpenPaths =
        state.workspace?.openFilePaths.toSet() ?? const <String>{};
    final requestedOpenPaths = openFilePaths.toSet();
    final intentionallyRemovedOpenPaths = initialOpenPaths.difference(
      requestedOpenPaths,
    );
    final intentionallyAddedOpenPaths = [
      for (final path in openFilePaths)
        if (!initialOpenPaths.contains(path)) path,
    ];
    final nextWorkspace = workspace.copyWith(
      activeFilePath: buffer.filePath,
      activeFileSnapshot: buffer.diskSnapshot,
      openFilePaths: openFilePaths,
      markdown: null,
    );
    final displayInputs = _preparedInputs[workspace];
    if (_workspaceFileOperationDepth > 0 &&
        initialBufferIds.contains(targetBufferId) &&
        displayInputs != null &&
        displayInputs.workspaceId == state.workspace?.id &&
        displayInputs.diskRevision == _workspaceDiskRevision &&
        !buffer.isDirty &&
        _sameBufferInputs(
          displayInputs.buffers,
          _sourceBufferInputs(documentBuffers),
        ) &&
        _sameBufferInputs(
          displayInputs.buffers,
          _sourceBufferInputs(state.documentBuffers),
        ) &&
        resolveWorkspaceDocumentContext(workspace, buffer).writersideTopic !=
            null &&
        !_writersideSourceMismatch(workspace, buffer)) {
      // A mutation can temporarily quarantine an input. Navigate the accepted
      // display snapshot; the operation still owns authoritative reconciliation.
      // Carry its original provenance without marking it freshly prepared for
      // this navigation revision or acknowledging any filesystem notification.
      final selected = _service.selectPreparedWritersideDocument(
        nextWorkspace,
        buffer,
      );
      if (selected != null) {
        _preparedInputs[selected] = displayInputs;
        _fileOperationNavigationRevision = _removalOperationRevision;
        state = state.copyWith(
          workspace: selected,
          preview: _safePreview(selected, buffer),
          activeBufferId: buffer.id,
          clearMessage: true,
        );
        _recordActivePreviewRevision();
        _schedulePersistence();
        _editRevision = buffer.revision;
        unawaited(
          _settingsController.setDocumentViewMode(buffer.editorState.mode),
        );
        return true;
      }
    }
    List<DocumentBuffer> currentRequestedBuffers() => [
      for (final live in state.documentBuffers)
        if (!intentionallyRemovedBufferIds.contains(live.id)) live,
      for (final added in intentionallyAddedBuffers)
        if (!state.documentBuffers.any((live) => live.id == added.id)) added,
    ];
    var parsedBuffer = buffer;
    var reparsed = await _reparseWithDocumentBuffers(
      nextWorkspace,
      parsedBuffer,
      buffers: documentBuffers,
    );
    if (!_isCurrentActiveDocumentOperation(operationRevision)) {
      return false;
    }
    if (state.workspace?.id != workspaceId) return false;
    var liveBuffer = state.documentBuffers
        .where((candidate) => candidate.id == targetBufferId)
        .firstOrNull;
    if (liveBuffer == null) return false;
    if (liveBuffer.revision != parsedBuffer.revision ||
        liveBuffer.text != parsedBuffer.text ||
        !_preparedInputsCurrent(reparsed, currentRequestedBuffers())) {
      parsedBuffer = liveBuffer;
      reparsed = await _reparseWithDocumentBuffers(
        nextWorkspace,
        parsedBuffer,
        buffers: currentRequestedBuffers(),
      );
      if (!_isCurrentActiveDocumentOperation(operationRevision) ||
          state.workspace?.id != workspaceId) {
        return false;
      }
      liveBuffer = state.documentBuffers
          .where((candidate) => candidate.id == targetBufferId)
          .firstOrNull;
      if (liveBuffer == null) return false;
    }
    var sourceStayedCurrent =
        liveBuffer.revision == parsedBuffer.revision &&
        liveBuffer.text == parsedBuffer.text;
    final liveBuffers = state.documentBuffers;
    for (final removedId in intentionallyRemovedBufferIds) {
      final before = initialBuffersById[removedId];
      final live = liveBuffers
          .where((candidate) => candidate.id == removedId)
          .firstOrNull;
      if (before != null && live != null && !identical(before, live)) {
        return false;
      }
    }
    final reconciledBuffers = <DocumentBuffer>[
      for (final candidate in liveBuffers)
        if (!intentionallyRemovedBufferIds.contains(candidate.id)) candidate,
      for (final added in intentionallyAddedBuffers)
        if (!liveBuffers.any((candidate) => candidate.id == added.id)) added,
    ];
    final reconciledOpenPaths = <String>[
      for (final path in state.workspace?.openFilePaths ?? const <String>[])
        if (!intentionallyRemovedOpenPaths.contains(path)) path,
      for (final path in intentionallyAddedOpenPaths)
        if (!(state.workspace?.openFilePaths.contains(path) ?? false)) path,
    ];
    sourceStayedCurrent =
        sourceStayedCurrent &&
        _preparedInputsCurrent(reparsed, reconciledBuffers);
    final publishedWorkspace =
        (sourceStayedCurrent
                ? reparsed
                : (state.workspace ?? nextWorkspace).copyWith(markdown: null))
            .copyWith(
              activeFilePath: liveBuffer.filePath,
              activeFileSnapshot: liveBuffer.diskSnapshot,
              openFilePaths: reconciledOpenPaths,
            );
    if (sourceStayedCurrent) {
      _preparedInputs[publishedWorkspace] = _preparedInputs[reparsed];
    }
    state = state.copyWith(
      workspace: publishedWorkspace,
      preview: sourceStayedCurrent
          ? _safePreview(publishedWorkspace, liveBuffer)
          : null,
      documentBuffers: reconciledBuffers,
      activeBufferId: liveBuffer.id,
      clearMessage: true,
    );
    for (final removedId in intentionallyRemovedBufferIds) {
      _restoredRecoveryOwnerIdsByBuffer.remove(removedId);
    }
    for (final added in intentionallyAddedBuffers) {
      _restoredRecoveryOwnerIdsByBuffer.remove(added.id);
    }
    if (sourceStayedCurrent) {
      _recordActivePreviewRevision();
    } else {
      _activePreviewRevision = null;
      _requestDerivedRefresh(
        rebuildPreview: _modeShowsPreview(liveBuffer.editorState.mode),
        refreshOutline: !_modeShowsPreview(liveBuffer.editorState.mode),
      );
    }
    _fileMonitor.updateOpenFilePaths(
      reconciledBuffers
          .map((candidate) => candidate.filePath)
          .whereType<String>(),
    );
    _schedulePersistence();
    _editRevision = liveBuffer.revision;
    unawaited(
      _settingsController.setDocumentViewMode(liveBuffer.editorState.mode),
    );
    return true;
  }

  void updateActiveEditorState(DocumentEditorState editorState) {
    final buffer = state.activeBuffer;
    if (buffer == null) {
      return;
    }
    updateDocumentEditorState(buffer.id, editorState);
  }

  void updateDocumentEditorState(
    String bufferId,
    DocumentEditorState editorState,
  ) {
    final buffer = state.documentBuffers
        .where((candidate) => candidate.id == bufferId)
        .firstOrNull;
    if (buffer == null) {
      return;
    }
    state = state.copyWith(
      documentBuffers: _replaceBuffer(
        state.documentBuffers,
        buffer.copyWith(editorState: editorState),
      ),
    );
    _schedulePersistence();
  }

  bool updateDocumentText(String bufferId, String text) {
    final buffer = state.documentBuffers
        .where((candidate) => candidate.id == bufferId)
        .firstOrNull;
    if (buffer == null || (buffer.isRemote && buffer.readonly)) {
      return false;
    }
    if (state.activeBufferId == bufferId) {
      updateActiveText(text, sourceFilePath: buffer.filePath);
      return true;
    }
    final next = buffer.edited(text);
    if (identical(next, buffer)) {
      return true;
    }
    state = state.copyWith(
      documentBuffers: _replaceBuffer(state.documentBuffers, next),
    );
    _localHistory.observeEdit(buffer, next);
    _schedulePersistence();
    _scheduleAutoSave(next.id);
    return true;
  }

  /// Rebuilds identities from the current editor buffers before navigation or
  /// refactoring; an inactive, unsaved dependency is still authoritative.
  Future<WritersideProjectIndex?> writersideEditorIndex() async {
    var project = state.workspace?.writersideProject;
    if (project == null) return null;
    final buffers = state.documentBuffers;
    for (final module in project.modules.toList()) {
      final loaded = await _service.writersideService.load(
        module.rootPath,
        sourceOverrides: {
          ...module.sourceOverrides,
          for (final buffer in buffers)
            if (buffer.filePath != null &&
                p.isWithin(module.rootPath, buffer.filePath!))
              buffer.filePath!: buffer.text,
        },
      );
      project = project!.withModule(loaded);
    }
    return project!.index;
  }

  /// Stages a rename in normal undoable document buffers. All source ranges
  /// are verified before any buffer is changed, including already dirty tabs.
  Future<bool> applyWritersideRename(List<WritersideRenameEdit> edits) async {
    if (edits.isEmpty) return false;
    final workspaceId = state.workspace?.id;
    final initialBuffers = state.documentBuffers;
    final byPath = <String, List<WritersideRenameEdit>>{};
    for (final edit in edits) {
      byPath.putIfAbsent(edit.filePath, () => []).add(edit);
    }
    final staged = <String, DocumentBuffer>{};
    final previousByBufferId = <String, DocumentBuffer>{};
    for (final entry in byPath.entries) {
      final buffer =
          initialBuffers
              .where((buffer) => buffer.filePath == entry.key)
              .firstOrNull ??
          _fileBuffer(
            entry.key,
            await _service.loadTextWithSnapshot(entry.key),
          );
      var source = buffer.text;
      var previousStart = source.length + 1;
      entry.value.sort(
        (a, b) => b.span.startOffset.compareTo(a.span.startOffset),
      );
      for (final edit in entry.value) {
        final span = edit.span;
        if (edit.expectedText == null ||
            span.startOffset < 0 ||
            span.endOffset > source.length ||
            span.endOffset > previousStart ||
            source.substring(span.startOffset, span.endOffset) !=
                edit.expectedText) {
          return false;
        }
        source = source.replaceRange(
          span.startOffset,
          span.endOffset,
          edit.replacement,
        );
        previousStart = span.startOffset;
      }
      final changed = buffer.edited(source);
      staged[entry.key] = changed;
      previousByBufferId[changed.id] = buffer;
    }
    if (!ref.mounted ||
        state.workspace?.id != workspaceId ||
        initialBuffers.any(
          (initial) =>
              state.documentBuffers
                  .where((current) => current.id == initial.id)
                  .firstOrNull
                  ?.text !=
              initial.text,
        )) {
      return false;
    }
    final buffers = [
      for (final buffer in state.documentBuffers)
        staged.remove(buffer.filePath) ?? buffer,
      ...staged.values,
    ];
    state = state.copyWith(documentBuffers: buffers);
    for (final entry in previousByBufferId.entries) {
      final next = buffers
          .where((buffer) => buffer.id == entry.key)
          .firstOrNull;
      if (next == null || identical(next, entry.value)) continue;
      _localHistory.observeEdit(entry.value, next);
      _scheduleAutoSave(next.id);
    }
    _editRevision = state.activeBuffer?.revision ?? _editRevision;
    _schedulePersistence();
    _fileMonitor.updateOpenFilePaths(
      buffers.map((buffer) => buffer.filePath).whereType<String>(),
    );
    _requestDerivedRefresh(rebuildPreview: true, refreshOutline: true);
    return true;
  }

  void updateActiveEditorMode(DocumentViewModePreference mode) {
    final buffer = state.activeBuffer;
    if (buffer == null || buffer.editorState.mode == mode) {
      return;
    }
    updateActiveEditorState(buffer.editorState.copyWith(mode: mode));
    if (_modeShowsPreview(mode) && _activePreviewIsStale) {
      _requestDerivedRefresh(rebuildPreview: true);
    }
  }

  bool undoActiveBuffer() {
    final buffer = state.activeBuffer;
    if (buffer == null ||
        (buffer.isRemote && buffer.readonly) ||
        buffer.editorState.undoState.undo.isEmpty) {
      return false;
    }
    final undo = buffer.editorState.undoState;
    final target = undo.undo.last;
    final current = DocumentHistoryState(
      text: buffer.text,
      selection: buffer.editorState.selection,
      wysiwygState: buffer.editorState.wysiwygState,
    );
    final next = buffer.copyWith(
      text: target.text,
      dirty: target.text != buffer.lastSavedText || buffer.isUntitled,
      format: buffer.format.copyWith(
        hasFinalNewline: target.text.endsWith('\n'),
      ),
      revision: buffer.revision + 1,
      editorState: buffer.editorState.copyWith(
        selection: target.selection,
        wysiwygState: target.wysiwygState,
        undoState: undo.afterUndo(current),
      ),
    );
    state = state.copyWith(
      documentBuffers: _replaceBuffer(state.documentBuffers, next),
    );
    _localHistory.observeEdit(buffer, next);
    _requestDerivedRefresh(
      rebuildPreview: _activeModeShowsPreview,
      refreshOutline: !_activeModeShowsPreview,
    );
    _schedulePersistence();
    _scheduleAutoSave(next.id);
    return true;
  }

  bool redoActiveBuffer() {
    final buffer = state.activeBuffer;
    if (buffer == null ||
        (buffer.isRemote && buffer.readonly) ||
        buffer.editorState.undoState.redo.isEmpty) {
      return false;
    }
    final undo = buffer.editorState.undoState;
    final target = undo.redo.last;
    final current = DocumentHistoryState(
      text: buffer.text,
      selection: buffer.editorState.selection,
      wysiwygState: buffer.editorState.wysiwygState,
    );
    final next = buffer.copyWith(
      text: target.text,
      dirty: target.text != buffer.lastSavedText || buffer.isUntitled,
      format: buffer.format.copyWith(
        hasFinalNewline: target.text.endsWith('\n'),
      ),
      revision: buffer.revision + 1,
      editorState: buffer.editorState.copyWith(
        selection: target.selection,
        wysiwygState: target.wysiwygState,
        undoState: undo.afterRedo(current),
      ),
    );
    state = state.copyWith(
      documentBuffers: _replaceBuffer(state.documentBuffers, next),
    );
    _localHistory.observeEdit(buffer, next);
    _requestDerivedRefresh(
      rebuildPreview: _activeModeShowsPreview,
      refreshOutline: !_activeModeShowsPreview,
    );
    _schedulePersistence();
    _scheduleAutoSave(next.id);
    return true;
  }

  void updateActiveText(
    String text, {
    String? sourceBufferId,
    String? sourceFilePath,
  }) {
    _updateActiveText(
      text,
      sourceBufferId: sourceBufferId,
      sourceFilePath: sourceFilePath,
      rebuildPreview:
          state.activeBuffer?.editorState.mode !=
          DocumentViewModePreference.source,
    );
  }

  void updateActiveSourceText(
    String text, {
    String? sourceBufferId,
    String? sourceFilePath,
    required TextSelection previousSelection,
    required TextSelection selection,
    String? undoGroup,
  }) {
    _updateActiveText(
      text,
      sourceBufferId: sourceBufferId,
      sourceFilePath: sourceFilePath,
      rebuildPreview: _activeModeShowsPreview,
      previousSelection: previousSelection,
      selection: selection,
      undoGroup: undoGroup,
    );
  }

  /// Applies a serialized WYSIWYG edit without reparsing the whole Markdown
  /// document on every keystroke.
  void updateActiveWysiwygText(
    String text, {
    required BusyDocument document,
    String? sourceBufferId,
    String? sourceFilePath,
    String? undoGroup,
    WysiwygEditorSessionState? previousWysiwygState,
    WysiwygEditorSessionState? wysiwygState,
  }) {
    _updateActiveText(
      text,
      sourceBufferId: sourceBufferId,
      sourceFilePath: sourceFilePath,
      rebuildPreview: false,
      liveOutline: document.outline,
      preserveFinalNewline: true,
      undoGroup: undoGroup,
      previousWysiwygState: previousWysiwygState,
      wysiwygState: wysiwygState,
    );
  }

  Future<bool> selectWritersideContext({
    required String moduleId,
    String? instanceId,
  }) async {
    final workspace = state.workspace;
    if (workspace == null || workspace.kind != WorkspaceKind.writersideModule) {
      return false;
    }
    _cancelPendingDerivedRefresh();
    final operationRevision = _invalidateActiveDocumentOperations();
    try {
      final selected = await _service.selectWritersideContext(
        workspace,
        moduleId: moduleId,
        instanceId: instanceId,
      );
      if (!_isCurrentActiveDocumentOperation(operationRevision)) {
        return false;
      }
      final path = selected.activeFilePath;
      if (path == null) {
        state = state.copyWith(
          workspace: selected,
          preview: null,
          activeBufferId: null,
          clearMessage: true,
        );
        _recordActivePreviewRevision();
        return true;
      }
      final existing = state.documentBuffers
          .where((buffer) => buffer.filePath == path)
          .firstOrNull;
      if (existing != null) {
        return await _activateBuffer(
          selected,
          existing,
          documentBuffers: state.documentBuffers,
          openFilePaths: _openFileTabPaths(selected, path),
        );
      }
      final load = await _service.loadTextWithSnapshot(path);
      if (!_isCurrentActiveDocumentOperation(operationRevision)) {
        return false;
      }
      final nextWorkspace = selected.copyWith(
        activeFileSnapshot: load.snapshot,
        openFilePaths: _openFileTabPaths(selected, path),
      );
      final buffer = _fileBuffer(
        path,
        load,
        mode: _settingsController.state.documentViewMode,
      );
      var reparsed = await _reparseWithDocumentBuffers(nextWorkspace, buffer);
      if (!_isCurrentActiveDocumentOperation(operationRevision)) {
        return false;
      }
      final buffers = [...state.documentBuffers, buffer];
      if (!_preparedInputsCurrent(reparsed, buffers)) {
        reparsed = await _reparseWithDocumentBuffers(
          nextWorkspace,
          buffer,
          buffers: buffers,
        );
        if (!_isCurrentActiveDocumentOperation(operationRevision)) return false;
        if (!_preparedInputsCurrent(reparsed, [
          ...state.documentBuffers,
          buffer,
        ])) {
          return false;
        }
      }
      state = state.copyWith(
        workspace: reparsed,
        preview: _safePreview(reparsed, buffer),
        documentBuffers: buffers,
        activeBufferId: buffer.id,
        clearMessage: true,
      );
      _recordActivePreviewRevision();
      _fileMonitor.updateOpenFilePaths(
        buffers.map((candidate) => candidate.filePath).whereType<String>(),
      );
      _schedulePersistence();
      return true;
    } on Object catch (error, stackTrace) {
      busyMarkDebugLogError(
        '[BusyMark] Could not select Writerside context',
        error,
        stackTrace,
        context: {'module': moduleId, 'instance': instanceId ?? ''},
      );
      return false;
    }
  }

  void _updateActiveText(
    String text, {
    required bool rebuildPreview,
    String? sourceBufferId,
    String? sourceFilePath,
    List<DocumentOutlineHeading>? liveOutline,
    bool preserveFinalNewline = false,
    TextSelection? previousSelection,
    TextSelection? selection,
    String? undoGroup,
    WysiwygEditorSessionState? previousWysiwygState,
    WysiwygEditorSessionState? wysiwygState,
  }) {
    final workspace = state.workspace;
    final activeBuffer = state.activeBuffer;
    if (activeBuffer == null) {
      return;
    }
    if (sourceBufferId != null && activeBuffer.id != sourceBufferId) return;
    final activeEditorPath = workspace == null
        ? activeBuffer.filePath
        : resolveWorkspaceDocumentContext(workspace, activeBuffer).parserPath;
    if (sourceFilePath != null && activeEditorPath != sourceFilePath) return;
    final effectiveText = preserveFinalNewline
        ? _withFinalNewlinePolicy(text, activeBuffer.format.hasFinalNewline)
        : text;
    final nextBuffer = activeBuffer.edited(
      effectiveText,
      undoGroup: undoGroup,
      previousSelection: previousSelection,
      nextSelection: selection,
      previousWysiwygState: previousWysiwygState,
      nextWysiwygState: wysiwygState,
    );
    if (identical(nextBuffer, activeBuffer)) {
      return;
    }
    _localHistory.observeEdit(activeBuffer, nextBuffer);
    _editRevision = nextBuffer.revision;
    state = state.copyWith(
      workspace: workspace?.copyWith(
        runtimeDiagnostics: [
          for (final diagnostic in workspace.runtimeDiagnostics)
            if (diagnostic.filePath != activeEditorPath) diagnostic,
        ],
      ),
      documentBuffers: _replaceBuffer(state.documentBuffers, nextBuffer),
      liveOutline: workspace == null || liveOutline == null
          ? null
          : ActiveDocumentOutline(
              workspaceId: workspace.id,
              bufferId: nextBuffer.id,
              filePath: nextBuffer.filePath,
              source: text,
              headings: liveOutline,
            ),
    );
    _schedulePersistence();
    _requestDerivedRefresh(
      rebuildPreview: rebuildPreview,
      refreshOutline: !rebuildPreview && liveOutline == null,
    );
    _scheduleAutoSave(nextBuffer.id);
  }

  bool get _activeModeShowsPreview {
    final mode = state.activeBuffer?.editorState.mode;
    return mode != null && _modeShowsPreview(mode);
  }

  bool get _activePreviewIsStale {
    final workspace = state.workspace;
    final buffer = state.activeBuffer;
    final revision = _activePreviewRevision;
    return workspace == null ||
        buffer == null ||
        state.preview == null ||
        revision == null ||
        revision.workspaceId != workspace.id ||
        revision.bufferId != buffer.id ||
        revision.revision != buffer.revision;
  }

  void _recordActivePreviewRevision() {
    final workspace = state.workspace;
    final buffer = state.activeBuffer;
    if (workspace == null || buffer == null || state.preview == null) {
      _activePreviewRevision = null;
      return;
    }
    _activePreviewRevision = _ActivePreviewRevision(
      workspaceId: workspace.id,
      bufferId: buffer.id,
      revision: buffer.revision,
    );
  }

  void _requestDerivedRefresh({
    required bool rebuildPreview,
    bool refreshOutline = false,
  }) {
    if (!_settingsController.state.validateOnEdit &&
        !rebuildPreview &&
        !refreshOutline) {
      return;
    }
    _derivedRefreshPending = true;
    _pendingPreviewRefresh = _pendingPreviewRefresh || rebuildPreview;
    _pendingOutlineRefresh = _pendingOutlineRefresh || refreshOutline;
    if (!_derivedRefreshRunning) {
      unawaited(_drainDerivedRefreshes());
    }
  }

  Future<void> _drainDerivedRefreshes() async {
    if (_derivedRefreshRunning || _manualValidationRunning) {
      return;
    }
    _derivedRefreshRunning = true;
    try {
      while (ref.mounted &&
          _derivedRefreshPending &&
          !_manualValidationRunning) {
        _derivedRefreshPending = false;
        final rebuildPreview = _pendingPreviewRefresh;
        final refreshOutline = _pendingOutlineRefresh;
        _pendingPreviewRefresh = false;
        _pendingOutlineRefresh = false;
        if (_settingsController.state.validateOnEdit) {
          await _validateActive(rebuildPreview: rebuildPreview);
        } else if (rebuildPreview) {
          await _refreshActivePreview();
        } else if (refreshOutline) {
          await _refreshActiveOutline();
        }
      }
    } finally {
      _derivedRefreshRunning = false;
      if (ref.mounted && _derivedRefreshPending && !_manualValidationRunning) {
        unawaited(_drainDerivedRefreshes());
      }
    }
  }

  void _cancelPendingDerivedRefresh() {
    _derivedRefreshPending = false;
    _pendingPreviewRefresh = false;
    _pendingOutlineRefresh = false;
  }

  Future<void> _refreshActiveOutline() async {
    final workspace = state.workspace;
    final buffer = state.activeBuffer;
    if (workspace == null || buffer == null) {
      return;
    }
    final workspaceId = workspace.id;
    final activeFilePath = workspace.activeFilePath;
    final bufferId = buffer.id;
    final text = buffer.text;
    final editRevision = buffer.revision;
    final operationRevision = _activeDocumentRevision;
    try {
      final reparsed = await _reparseWithDocumentBuffers(workspace, buffer);
      if (!_preparedInputsCurrent(reparsed, state.documentBuffers) ||
          !_canPublishActiveDerivedContent(
            operationRevision: operationRevision,
            workspaceId: workspaceId,
            bufferId: bufferId,
            path: activeFilePath,
            revision: editRevision,
            source: text,
          )) {
        return;
      }
      state = state.copyWith(
        liveOutline: ActiveDocumentOutline(
          workspaceId: workspaceId,
          bufferId: bufferId,
          filePath: activeFilePath,
          source: text,
          headings: _service.documentOutline(reparsed, buffer),
        ),
      );
    } on Object catch (error, stackTrace) {
      busyMarkDebugLogError(
        '[BusyMark] Could not refresh Source outline',
        error,
        stackTrace,
        context: {'path': busyMarkLogPath(activeFilePath ?? '')},
      );
    }
  }

  Future<void> _refreshActivePreview() async {
    final workspace = state.workspace;
    final buffer = state.activeBuffer;
    if (workspace == null || buffer == null) {
      return;
    }
    final workspaceId = workspace.id;
    final activeFilePath = buffer.filePath;
    final bufferId = buffer.id;
    final text = buffer.text;
    final editRevision = buffer.revision;
    final operationRevision = _activeDocumentRevision;
    try {
      final reparsed = await _reparseWithDocumentBuffers(workspace, buffer);
      final preview = await _service.buildDocumentPreviewAsync(
        reparsed,
        buffer,
      );
      if (!_preparedInputsCurrent(reparsed, state.documentBuffers) ||
          !_canPublishActiveDerivedContent(
            operationRevision: operationRevision,
            workspaceId: workspaceId,
            bufferId: bufferId,
            path: activeFilePath,
            revision: editRevision,
            source: text,
          )) {
        return;
      }
      // Preview remains live when validate-on-edit is disabled, but the parsed
      // workspace (including its diagnostics and persisted document model)
      // must only advance through explicit validation.
      state = state.copyWith(preview: preview);
      _recordActivePreviewRevision();
    } on Object catch (error, stackTrace) {
      busyMarkDebugLogError(
        '[BusyMark] Could not refresh preview',
        error,
        stackTrace,
        context: {'path': busyMarkLogPath(activeFilePath ?? '')},
      );
    }
  }

  Future<bool> autoSaveActiveIfNeeded() async {
    final buffer = state.activeBuffer;
    if (buffer == null) {
      return true;
    }
    _cancelAutoSave(buffer.id);
    return _autoSaveBufferIfNeeded(buffer.id);
  }

  Future<bool> saveActive({
    bool overwriteExternalChanges = false,
    ActiveDocumentSaveTarget? target,
    LineEndingNormalization? mixedLineEndingNormalization,
  }) async {
    final operationTarget = target ?? captureActiveDocumentSaveTarget();
    if (operationTarget == null ||
        !isActiveDocumentSaveTargetCurrent(operationTarget)) {
      return false;
    }
    _cancelAutoSave(operationTarget.bufferId);
    _cancelPendingDerivedRefresh();
    return _enqueueBufferWrite(operationTarget.bufferId, () async {
      // An earlier queued write may have advanced the known disk snapshot.
      // Re-pin that controller-owned snapshot without changing the text or
      // revision approved by this save request.
      final refreshedTarget = _refreshBufferSaveTarget(operationTarget);
      if (refreshedTarget == null) {
        return false;
      }
      return _saveActiveNow(
        refreshedTarget,
        overwriteExternalChanges: overwriteExternalChanges,
        mixedLineEndingNormalization: mixedLineEndingNormalization,
      );
    });
  }

  Future<bool> _saveActiveNow(
    ActiveDocumentSaveTarget target, {
    required bool overwriteExternalChanges,
    required LineEndingNormalization? mixedLineEndingNormalization,
  }) async {
    final remoteBuffer = state.documentBuffers
        .where((buffer) => buffer.id == target.bufferId && buffer.isRemote)
        .firstOrNull;
    if (remoteBuffer != null) {
      return _saveRemoteBufferSnapshot(
        remoteBuffer.copyWith(text: target.text, revision: target.editRevision),
      );
    }
    final active = target.path;
    if (active == null) {
      if (isActiveDocumentSaveTargetCurrent(target)) {
        state = state.copyWith(
          message: const WorkspaceMessage(
            WorkspaceMessageCode.chooseWhereToSaveMarkdown,
          ),
        );
      }
      return false;
    }
    WorkspaceFileSnapshot expectedSnapshot = target.snapshot!;
    if (!overwriteExternalChanges) {
      final changedOnDisk = await _service.fileChangedSince(
        active,
        target.snapshot,
      );
      if (!_isBufferSaveTargetCurrent(target)) {
        return false;
      }
      if (changedOnDisk) {
        state = state.copyWith(
          message: const WorkspaceMessage(
            WorkspaceMessageCode.saveBlockedFileChangedOnDisk,
          ),
        );
        return false;
      }
    } else {
      final current = await _service.loadTextWithSnapshot(active);
      if (!_isBufferSaveTargetCurrent(target)) return false;
      expectedSnapshot = current.snapshot;
      if (target.snapshot == null ||
          current.snapshot.differsFrom(target.snapshot!)) {
        final protected = await _localHistory.capturePathBeforeLoss(
          path: active,
          text: current.text,
          format: current.format,
          reason: LocalHistoryCaptureReason.beforeDiscard,
        );
        if (!protected || !_isBufferSaveTargetCurrent(target)) return false;
      }
    }
    if (!_isBufferSaveTargetCurrent(target)) {
      return false;
    }
    try {
      final snapshot = await _service.saveTextIfUnchanged(
        active,
        target.format.formattedText(
          target.text,
          mixedNormalization: mixedLineEndingNormalization,
        ),
        expectedSnapshot: expectedSnapshot,
      );
      final currentWorkspace = state.workspace;
      final currentBuffer = state.documentBuffers
          .where((buffer) => buffer.id == target.bufferId)
          .firstOrNull;
      if (currentWorkspace == null ||
          currentWorkspace.id != target.workspaceId ||
          currentBuffer == null ||
          currentBuffer.filePath != active) {
        return false;
      }
      final savedFormat =
          target.format.hasMixedLineEndings &&
              mixedLineEndingNormalization != null
          ? target.format.normalized(mixedLineEndingNormalization)
          : target.format;
      final unchanged =
          currentBuffer.revision == target.editRevision &&
          currentBuffer.text == target.text;
      final savedBuffer = currentBuffer.copyWith(
        lastSavedText: target.text,
        dirty: currentBuffer.text != target.text,
        diskSnapshot: snapshot,
        format: unchanged ? savedFormat : currentBuffer.format,
        diskState: DocumentDiskState.present,
        diskVersionText: null,
        diskVersionSnapshot: null,
        recovered: false,
      );
      final remainsActive = state.activeBufferId == target.bufferId;
      final nextWorkspace = remainsActive
          ? currentWorkspace.copyWith(activeFileSnapshot: snapshot)
          : currentWorkspace;
      state = state.copyWith(
        workspace: nextWorkspace,
        documentBuffers: _replaceBuffer(state.documentBuffers, savedBuffer),
        clearMessage: true,
      );
      if (savedBuffer.isDirty) {
        _scheduleAutoSave(target.bufferId);
      }
      _schedulePersistence();
      if (remainsActive && unchanged) {
        await _refreshActiveBufferAfterDiskUpdate(
          bufferId: target.bufferId,
          workspaceId: target.workspaceId,
          text: target.text,
          editRevision: target.editRevision,
          snapshot: snapshot,
        );
      }
      await _localHistory.captureSaved(
        LocalHistoryBufferSnapshot(
          bufferId: target.bufferId,
          displayName: p.basename(active),
          text: target.text,
          format: savedFormat,
          revision: target.editRevision,
          path: active,
        ),
      );
      return true;
    } on Object catch (error) {
      if (ref.mounted &&
          _workspaceContainsBuffer(target.workspaceId, target.bufferId)) {
        state = state.copyWith(
          message: error is AtomicFileChangedException
              ? const WorkspaceMessage(
                  WorkspaceMessageCode.saveBlockedFileChangedOnDisk,
                )
              : WorkspaceMessage(WorkspaceMessageCode.saveFailed, error: error),
        );
      }
      return false;
    }
  }

  Future<void> _refreshActiveBufferAfterDiskUpdate({
    required String bufferId,
    required String workspaceId,
    required String text,
    required int editRevision,
    required WorkspaceFileSnapshot? snapshot,
  }) async {
    final workspace = state.workspace;
    if (workspace == null ||
        workspace.id != workspaceId ||
        state.activeBufferId != bufferId) {
      return;
    }
    final targetBuffer = state.activeBuffer;
    if (targetBuffer == null ||
        targetBuffer.id != bufferId ||
        targetBuffer.revision != editRevision ||
        targetBuffer.text != text) {
      return;
    }
    try {
      final reparsed = await _reparseWithDocumentBuffers(
        workspace,
        targetBuffer,
      );
      final currentWorkspace = state.workspace;
      final currentBuffer = state.documentBuffers
          .where((buffer) => buffer.id == bufferId)
          .firstOrNull;
      if (currentWorkspace == null ||
          currentWorkspace.id != workspaceId ||
          state.activeBufferId != bufferId ||
          currentBuffer == null ||
          currentBuffer.revision != editRevision ||
          currentBuffer.text != text ||
          !_preparedInputsCurrent(reparsed, state.documentBuffers) ||
          !_sameFileSnapshot(currentBuffer.diskSnapshot, snapshot)) {
        return;
      }
      final nextWorkspace = reparsed.copyWith(
        activeFileSnapshot: snapshot,
        openFilePaths: currentWorkspace.openFilePaths,
        files: currentWorkspace.files,
      );
      _preparedInputs[nextWorkspace] = _preparedInputs[reparsed];
      state = state.copyWith(
        workspace: nextWorkspace,
        preview: _safePreview(nextWorkspace, currentBuffer),
      );
      _recordActivePreviewRevision();
    } on Object catch (error, stackTrace) {
      busyMarkDebugLogError(
        '[BusyMark] Document reparse after disk update failed',
        error,
        stackTrace,
      );
    }
  }

  Future<SaveAllResult> saveAll({
    Iterable<String>? bufferIds,
    Map<String, LineEndingNormalization> mixedLineEndingNormalizations =
        const {},
  }) async {
    _cancelAllAutoSaves();
    final saved = <String>[];
    final failed = <String>[];
    final conflicts = <String>[];
    final normalizationRequired = <String>[];
    final includedBufferIds = bufferIds?.toSet();
    final targets = [
      for (final buffer in state.documentBuffers)
        if (buffer.isDirty &&
            !buffer.isUntitled &&
            (includedBufferIds == null ||
                includedBufferIds.contains(buffer.id)))
          buffer,
    ];
    final writes = <({String id, Future<_BufferWriteResult> result})>[];
    for (final target in targets) {
      if (target.format.hasMixedLineEndings &&
          !mixedLineEndingNormalizations.containsKey(target.id)) {
        normalizationRequired.add(target.id);
        continue;
      }
      writes.add((
        id: target.id,
        result: _enqueueBufferWrite(
          target.id,
          () => _saveBufferForSaveAll(
            target,
            mixedLineEndingNormalizations[target.id],
          ),
        ),
      ));
    }
    for (final write in writes) {
      switch (await write.result) {
        case _BufferWriteResult.saved:
          saved.add(write.id);
        case _BufferWriteResult.failed:
          failed.add(write.id);
        case _BufferWriteResult.conflict:
          conflicts.add(write.id);
      }
    }
    _schedulePersistence();
    _scheduleAutoSave();
    return SaveAllResult(
      savedBufferIds: List.unmodifiable(saved),
      failedBufferIds: List.unmodifiable(failed),
      conflictBufferIds: List.unmodifiable(conflicts),
      normalizationRequiredBufferIds: List.unmodifiable(normalizationRequired),
    );
  }

  Future<_BufferWriteResult> _saveBufferForSaveAll(
    DocumentBuffer target,
    LineEndingNormalization? normalization,
  ) async {
    if (target.isRemote) {
      return await _saveRemoteBufferSnapshot(target)
          ? _BufferWriteResult.saved
          : _BufferWriteResult.failed;
    }
    final current = state.documentBuffers
        .where((buffer) => buffer.id == target.id)
        .firstOrNull;
    if (current == null) {
      return _BufferWriteResult.failed;
    }
    if (!current.isDirty && current.text == target.text) {
      return _BufferWriteResult.saved;
    }
    if (current.diskState != DocumentDiskState.present) {
      return _BufferWriteResult.conflict;
    }
    final path = target.filePath!;
    if (await _service.fileChangedSince(path, current.diskSnapshot)) {
      return _BufferWriteResult.conflict;
    }
    try {
      final snapshot = await _service.saveText(
        path,
        target.format.formattedText(
          target.text,
          mixedNormalization: normalization,
        ),
      );
      final latest = state.documentBuffers
          .where((buffer) => buffer.id == target.id)
          .firstOrNull;
      if (latest == null) {
        return _BufferWriteResult.failed;
      }
      final unchanged = latest.revision == target.revision;
      final savedFormat =
          target.format.hasMixedLineEndings && normalization != null
          ? target.format.normalized(normalization)
          : target.format;
      final next = latest.copyWith(
        lastSavedText: target.text,
        dirty: !unchanged,
        diskSnapshot: snapshot,
        format: unchanged ? savedFormat : latest.format,
        diskState: DocumentDiskState.present,
        diskVersionText: null,
        diskVersionSnapshot: null,
        recovered: false,
      );
      state = state.copyWith(
        documentBuffers: _replaceBuffer(state.documentBuffers, next),
        workspace: state.activeBufferId == target.id
            ? state.workspace?.copyWith(activeFileSnapshot: snapshot)
            : state.workspace,
      );
      await _localHistory.captureSaved(
        LocalHistoryBufferSnapshot(
          bufferId: target.id,
          displayName: target.displayName,
          text: target.text,
          format: savedFormat,
          revision: target.revision,
          path: path,
        ),
      );
      return _BufferWriteResult.saved;
    } on Object {
      return _BufferWriteResult.failed;
    }
  }

  Future<bool> saveActiveAs(
    String path, {
    ActiveDocumentSaveTarget? target,
    bool overwriteExisting = false,
    LineEndingNormalization? mixedLineEndingNormalization,
  }) async {
    final operationTarget = target ?? captureActiveDocumentSaveTarget();
    if (operationTarget == null ||
        !isActiveDocumentSaveTargetCurrent(operationTarget)) {
      return false;
    }
    _cancelAutoSave(operationTarget.bufferId);
    _cancelPendingDerivedRefresh();
    return _enqueueBufferWrite(operationTarget.bufferId, () async {
      final refreshedTarget = _refreshBufferSaveTarget(operationTarget);
      if (refreshedTarget == null) {
        return false;
      }
      return _saveActiveAsNow(
        path,
        target: refreshedTarget,
        overwriteExisting: overwriteExisting,
        mixedLineEndingNormalization: mixedLineEndingNormalization,
      );
    });
  }

  Future<bool> _commitSavedAsSourceRecoveryAfterPublication(
    String? operationId,
  ) async {
    if (operationId == null) return false;
    try {
      if (await _localHistory.commitSavedAsSourceRecovery(operationId)) {
        return true;
      }
    } on Object {
      // The destination is already atomically published. The session journal
      // is an independent durable fallback when the controller operation was
      // disposed or its normal persistence write failed at this boundary.
    }
    return _sessionStore.markPendingLocalHistorySaveAsCommitted(operationId);
  }

  Future<bool> _saveActiveAsNow(
    String path, {
    required ActiveDocumentSaveTarget target,
    required bool overwriteExisting,
    required LineEndingNormalization? mixedLineEndingNormalization,
  }) async {
    if (target.workspaceKind == WorkspaceKind.nextcloudNotes) {
      try {
        final buffer = state.documentBuffers
            .where((buffer) => buffer.id == target.bufferId)
            .firstOrNull;
        final reference = buffer?.remoteNote;
        if (reference == null) return false;
        final media = NextcloudDocumentMedia(
          await _ensureNotesRepository(),
          reference.accountId,
          reference.localId,
        );
        await const MarkdownCopyExportService().export(
          source: target.text,
          destinationPath: path,
          media: media.context,
          overwrite: overwriteExisting,
        );
        // Save As exports a copy; it never promotes a remote identity to a path.
        return true;
      } on Object catch (error) {
        state = state.copyWith(
          message: WorkspaceMessage(
            WorkspaceMessageCode.saveFailed,
            error: error,
          ),
        );
        return false;
      }
    }
    bool destinationOwnedByAnotherBuffer() => state.documentBuffers.any(
      (buffer) =>
          buffer.id != target.bufferId &&
          buffer.filePath != null &&
          p.equals(buffer.filePath!, path),
    );
    // One editor owner per filesystem path is a prerequisite for Save As
    // history partitioning. A missing/deleted destination tab can still own
    // dirty recovery and must not be folded into this buffer's cleanup journal.
    if (destinationOwnedByAnotherBuffer()) return false;
    LocalHistoryBufferPathTransition? historyTransition = _localHistory
        .beginBufferPathTransition(
          bufferId: target.bufferId,
          sourcePath: target.path,
          destinationPath: path,
          kind: LocalHistoryBufferPathTransitionKind.saveAs,
        );
    var historyPathCommitted = false;
    var bufferPathPublished = false;
    var historySaveAsStillCurrent = false;
    String? savedAsSourceRecoveryOwner;
    String? destinationCleanupOperationId;
    WorkspaceFileSnapshot? protectedDestinationSnapshot;
    try {
      final destinationExisted =
          overwriteExisting && await _service.pathExists(path);
      if (destinationExisted) {
        try {
          final destination = await _service.loadTextWithSnapshot(path);
          protectedDestinationSnapshot = destination.snapshot;
          if (!await _localHistory.capturePathBeforeLoss(
            path: path,
            text: destination.text,
            format: destination.format,
            reason: LocalHistoryCaptureReason.beforeDiscard,
          )) {
            return false;
          }
        } on Object {
          // Overwrite protection must settle durably before destination bytes
          // can be replaced.
          return false;
        }
      }
      final savedFormat =
          target.format.hasMixedLineEndings &&
              mixedLineEndingNormalization != null
          ? target.format.normalized(mixedLineEndingNormalization)
          : target.format;
      final sourceHistorySnapshot = LocalHistoryBufferSnapshot(
        bufferId: target.bufferId,
        displayName: target.path == null
            ? state.documentBuffers
                      .where((buffer) => buffer.id == target.bufferId)
                      .firstOrNull
                      ?.displayName ??
                  p.basename(path)
            : p.basename(target.path!),
        text: target.text,
        format: target.format,
        revision: target.editRevision,
        path: target.path,
        untitled: target.path == null,
      );
      savedAsSourceRecoveryOwner = await _localHistory
          .stageSavedAsSourceRecovery(
            sourceHistorySnapshot,
            destination: LocalHistoryBufferSnapshot(
              bufferId: target.bufferId,
              displayName: p.basename(path),
              text: target.text,
              format: savedFormat,
              revision: target.editRevision,
              path: path,
            ),
            destinationExisted: destinationExisted,
            recoveryOwnerId: _recoveryStore.ownerId,
          );
      if (savedAsSourceRecoveryOwner case final operationId?) {
        _saveAsSessionBindings[target.bufferId] = (
          operationId: operationId,
          workspaceId: target.workspaceId,
        );
        await flushPersistence();
      }
      if (!await _localHistory.beginSavedAsSourceRecovery(
        savedAsSourceRecoveryOwner,
      )) {
        return false;
      }
      if (destinationOwnedByAnotherBuffer()) return false;
      WorkspaceFileSnapshot? savedSnapshot;
      try {
        if (overwriteExisting) {
          savedSnapshot = await _service.saveTextReplacingPathIfUnchanged(
            path,
            target.format.formattedText(
              target.text,
              mixedNormalization: mixedLineEndingNormalization,
            ),
            expectedSnapshot: protectedDestinationSnapshot!,
            onPublished: () async {
              historyPathCommitted = true;
              historySaveAsStillCurrent =
                  await _commitSavedAsSourceRecoveryAfterPublication(
                    savedAsSourceRecoveryOwner,
                  );
            },
          );
        } else {
          savedSnapshot = await _localHistory.runStagedPathDeletion(
            path: path,
            recursive: false,
            filesystemOperation: () => _service.saveNewText(
              path,
              target.format.formattedText(
                target.text,
                mixedNormalization: mixedLineEndingNormalization,
              ),
              onPublished: () async {
                historyPathCommitted = true;
                historySaveAsStillCurrent =
                    await _commitSavedAsSourceRecoveryAfterPublication(
                      savedAsSourceRecoveryOwner,
                    );
              },
            ),
            didCommit: (_) => true,
            committedAfterError: () async => historyPathCommitted,
            commitEvidenceOperationId: savedAsSourceRecoveryOwner,
            onOperationStaged: (value) => destinationCleanupOperationId = value,
          );
        }
      } on Object {
        if (!historyPathCommitted) rethrow;
        // The atomic file publication is the Save As commit boundary. A
        // failing journal callback or trailing stat must not leave the editor
        // bound to the old path. Recover the published snapshot and continue;
        // unresolved journal persistence remains durable retry work.
        savedSnapshot = (await _service.loadTextWithSnapshot(path)).snapshot;
      }
      historyPathCommitted = true;
      if (destinationCleanupOperationId != null) {
        _historyOperationsAwaitingWorkspaceRefresh.add(
          destinationCleanupOperationId!,
        );
      }
      // The destination may have been opened while the atomic filesystem
      // publication was in flight. Its buffer now owns that path and content;
      // leave the source buffer on its original lineage instead of publishing
      // a second live editor owner for the same file.
      if (destinationOwnedByAnotherBuffer()) return false;
      if (!historySaveAsStillCurrent) {
        try {
          historySaveAsStillCurrent =
              await _commitSavedAsSourceRecoveryAfterPublication(
                savedAsSourceRecoveryOwner,
              );
        } on Object {
          historySaveAsStillCurrent =
              _localHistory
                  .pendingSaveAsOperation(savedAsSourceRecoveryOwner)
                  ?.phase ==
              LocalHistoryPathReconciliationPhase.committed;
        }
      }
      var currentWorkspace = state.workspace;
      var currentBuffer = state.documentBuffers
          .where((buffer) => buffer.id == target.bufferId)
          .firstOrNull;
      if (currentWorkspace == null ||
          currentWorkspace.id != target.workspaceId ||
          currentBuffer == null ||
          currentBuffer.filePath != target.path) {
        return false;
      }
      final replaceWorkspace =
          currentWorkspace.kind == WorkspaceKind.untitledMarkdown;
      Workspace? openedWorkspace;
      if (replaceWorkspace) {
        openedWorkspace = await _service.openPath(path);
      }
      currentWorkspace = state.workspace;
      currentBuffer = state.documentBuffers
          .where((buffer) => buffer.id == target.bufferId)
          .firstOrNull;
      if (currentWorkspace == null ||
          currentWorkspace.id != target.workspaceId ||
          currentBuffer == null ||
          currentBuffer.filePath != target.path) {
        return false;
      }
      // Opening the new path for a first-save workspace is asynchronous. A
      // separate tab may claim the destination while that load is in flight,
      // so validate path ownership at the final editor publication boundary.
      if (destinationOwnedByAnotherBuffer()) return false;
      final hasNewerEdits =
          currentBuffer.revision != target.editRevision ||
          currentBuffer.text != target.text;
      final savedBuffer = currentBuffer.copyWith(
        filePath: path,
        untitledName: null,
        lastSavedText: target.text,
        dirty: hasNewerEdits,
        diskSnapshot: savedSnapshot,
        format: hasNewerEdits ? currentBuffer.format : savedFormat,
        diskState: DocumentDiskState.present,
        diskVersionText: null,
        diskVersionSnapshot: null,
        recovered: false,
      );
      final buffers = _replaceBuffer(state.documentBuffers, savedBuffer);
      final activeBufferId = state.activeBufferId;
      final activeBuffer = buffers
          .where((buffer) => buffer.id == activeBufferId)
          .firstOrNull;
      final tabPaths = [
        for (final buffer in buffers)
          if (buffer.filePath != null) buffer.filePath!,
      ];
      final workspaceBase = openedWorkspace ?? currentWorkspace;
      final savedWorkspace = workspaceBase.copyWith(
        activeFilePath: activeBuffer?.filePath,
        activeFileSnapshot: activeBuffer?.diskSnapshot,
        openFilePaths: tabPaths,
        markdown: activeBuffer?.filePath == null
            ? currentWorkspace.markdown
            : null,
      );
      _cancelPendingDerivedRefresh();
      state = state.copyWith(
        workspace: savedWorkspace,
        documentBuffers: buffers,
        clearMessage: true,
      );
      bufferPathPublished = true;
      final saveAsOperation = _localHistory.pendingSaveAsOperation(
        savedAsSourceRecoveryOwner,
      );
      if (historySaveAsStillCurrent) {
        await _localHistory.captureSavedAs(
          sourceHistorySnapshot,
          path,
          destinationExisted: destinationExisted,
          destinationFormat: savedFormat,
          recordSourceHistory: saveAsOperation?.recordSourceHistory,
          recordDestinationHistory: saveAsOperation?.recordDestinationHistory,
          destinationDocumentId: saveAsOperation?.destinationDocumentId,
          destinationTarget: saveAsOperation?.destinationTarget,
          sourceCaptureId: saveAsOperation?.source.captureId,
          destinationCaptureId: saveAsOperation?.destination.captureId,
          sourceAcceptedClearEpoch: saveAsOperation?.source.acceptedClearEpoch,
          destinationAcceptedClearEpoch:
              saveAsOperation?.destination.acceptedClearEpoch,
          sourceAcceptedAt: saveAsOperation?.source.acceptedAt,
          destinationAcceptedAt: saveAsOperation?.destination.acceptedAt,
          sourceAcceptedDocumentId: saveAsOperation?.source.acceptedDocumentId,
          destinationAcceptedDocumentId:
              saveAsOperation?.destination.acceptedDocumentId,
          saveAsOperationId: savedAsSourceRecoveryOwner,
          firstSaveLineageTransition:
              saveAsOperation?.firstSaveLineageTransition,
        );
        // captureSavedAs has now either persisted the destination revision or
        // durably partitioned every retained source/destination obligation.
        // The earlier fork journal no longer owns that work.
        await _localHistory.completeSavedAsSourceRecovery(
          savedAsSourceRecoveryOwner,
        );
      } else if (saveAsOperation != null &&
          (saveAsOperation.historyCancelled ||
              (!saveAsOperation.recordSourceHistory &&
                  !saveAsOperation.recordDestinationHistory))) {
        // The clear/policy action cancelled revision work, but the published
        // path transition is now represented by the live B-bound session.
        await _localHistory.completeSavedAsSourceRecovery(
          savedAsSourceRecoveryOwner,
        );
      }
      await _localHistory.finishBufferPathTransition(
        historyTransition,
        committed: true,
      );
      historyTransition = null;
      await _localHistory.acknowledgeStagedPathOperation(
        destinationCleanupOperationId,
      );
      _historyOperationsAwaitingWorkspaceRefresh.remove(
        destinationCleanupOperationId,
      );
      await _persistPendingHistoryReconciliation();
      await _startMonitoring(savedWorkspace);
      if (hasNewerEdits) {
        if (state.activeBufferId == savedBuffer.id &&
            _settingsController.state.validateOnEdit) {
          _requestDerivedRefresh(rebuildPreview: _activeModeShowsPreview);
        }
        _scheduleAutoSave(savedBuffer.id);
      } else if (state.activeBufferId == savedBuffer.id) {
        _resetSaveTracking();
      }
      final activeAfterSave = state.activeBuffer;
      if (activeAfterSave != null &&
          (replaceWorkspace || activeAfterSave.id == savedBuffer.id)) {
        await _refreshActiveBufferAfterDiskUpdate(
          bufferId: activeAfterSave.id,
          workspaceId: savedWorkspace.id,
          text: activeAfterSave.text,
          editRevision: activeAfterSave.revision,
          snapshot: activeAfterSave.diskSnapshot,
        );
      }
      await _settingsController.recordOpenedWorkspace(
        path: path,
        kind: savedWorkspace.kind.name,
      );
      _schedulePersistence();
      return true;
    } on Object catch (error) {
      if (ref.mounted &&
          _workspaceContainsBuffer(target.workspaceId, target.bufferId)) {
        state = state.copyWith(
          message: WorkspaceMessage(
            WorkspaceMessageCode.saveFailed,
            error: error,
          ),
        );
      }
      return bufferPathPublished;
    } finally {
      if (ref.mounted) {
        if (!historyPathCommitted) {
          await _localHistory.cancelSavedAsSourceRecovery(
            savedAsSourceRecoveryOwner,
          );
        } else if (_localHistory.pendingSaveAsOperation(
              savedAsSourceRecoveryOwner,
            )
            case final operation?
            when operation.phase ==
                LocalHistoryPathReconciliationPhase.committed) {
          // The filesystem fork is already real. If the originating workspace
          // vanished or a later step failed, transfer both still-enabled sides
          // to detached retry owners now instead of waiting for app restart.
          try {
            final liveSource = state.documentBuffers
                .where((buffer) => buffer.id == target.bufferId)
                .firstOrNull;
            await _localHistory.recoverCommittedSaveAs(
              operation,
              sourceRetainsUntitledLineage:
                  target.path == null && liveSource?.filePath == null,
            );
          } on Object catch (error, stackTrace) {
            busyMarkDebugLogError(
              '[BusyMark] Committed Save As history recovery remains pending',
              error,
              stackTrace,
            );
          }
        }
        final unfinishedTransition = historyTransition;
        if (unfinishedTransition != null) {
          await _localHistory.finishBufferPathTransition(
            unfinishedTransition,
            committed: bufferPathPublished,
          );
        }
        final binding = _saveAsSessionBindings[target.bufferId];
        final operationStillPending =
            savedAsSourceRecoveryOwner != null &&
            _localHistory.pendingSaveAsOperations.any(
              (operation) =>
                  operation.operationId == savedAsSourceRecoveryOwner,
            );
        final originalBufferStillPresent =
            state.workspace?.id == target.workspaceId &&
            state.documentBuffers.any((buffer) => buffer.id == target.bufferId);
        if (binding?.operationId == savedAsSourceRecoveryOwner &&
            (!operationStillPending || !originalBufferStillPresent)) {
          _saveAsSessionBindings.remove(target.bufferId);
          await _persistPendingHistoryReconciliation();
        }
      }
    }
  }

  Future<bool> savePathExists(
    String path, {
    ActiveDocumentSaveTarget? target,
  }) async {
    final operationTarget = target ?? captureActiveDocumentSaveTarget();
    if (operationTarget == null ||
        !isActiveDocumentSaveTargetCurrent(operationTarget)) {
      return false;
    }
    final exists = await _service.pathExists(path);
    if (!isActiveDocumentSaveTargetCurrent(operationTarget)) {
      return false;
    }
    return exists;
  }

  Future<bool> discardActiveChanges({ActiveDocumentSaveTarget? target}) async {
    final operationTarget = target ?? captureActiveDocumentSaveTarget();
    if (operationTarget == null) {
      return state.workspace == null && !state.isDirty;
    }
    if (!isActiveDocumentSaveTargetCurrent(operationTarget)) {
      return false;
    }
    if (!state.isDirty) {
      return true;
    }
    _cancelAutoSave(operationTarget.bufferId);
    _cancelPendingDerivedRefresh();
    return _enqueueBufferWrite(
      operationTarget.bufferId,
      () => _discardBufferChangesNow(operationTarget),
    );
  }

  /// Discards the selected buffers without changing the active document.
  ///
  /// Project-wide refactoring safety uses this to resolve several inactive
  /// Writerside buffers without unmounting the UI that owns the confirmation
  /// workflow between files.
  Future<bool> discardDocumentBuffers(Iterable<String> bufferIds) async {
    final workspace = state.workspace;
    if (workspace == null) return false;
    for (final bufferId in bufferIds.toSet()) {
      final buffer = state.documentBuffers
          .where((candidate) => candidate.id == bufferId)
          .firstOrNull;
      if (buffer == null || !buffer.isDirty) continue;
      final target = ActiveDocumentSaveTarget._(
        workspaceId: workspace.id,
        bufferId: buffer.id,
        path: buffer.filePath,
        documentRevision: _activeDocumentRevision,
        editRevision: buffer.revision,
        snapshot: buffer.diskSnapshot,
        text: buffer.text,
        workspaceKind: workspace.kind,
        format: buffer.format,
      );
      _cancelAutoSave(buffer.id);
      _cancelPendingDerivedRefresh();
      final discarded = await _enqueueBufferWrite(
        buffer.id,
        () => _discardBufferChangesNow(target),
      );
      if (!discarded) return false;
    }
    return true;
  }

  Future<bool> restoreLocalHistoryRevision({
    required LocalHistoryDocument document,
    required LocalHistoryRevision revision,
    SourceComparison? comparison,
    SourceComparisonChange? change,
  }) async {
    if (revision.summary.documentId != document.id) return false;
    final path = document.currentPath ?? revision.summary.historicalPath;
    var buffer = localHistoryBufferForDocument(document, revision);
    if (buffer == null && document.remoteNote != null) {
      if (!await openNextcloudNote(document.remoteNote!.localId)) return false;
      buffer = state.activeBuffer;
    }
    if (buffer == null && path != null && await _service.pathExists(path)) {
      if (!await _openActiveFile(path)) return false;
      buffer = state.activeBuffer;
    } else if (buffer != null && state.activeBufferId != buffer.id) {
      if (!await activateDocumentBuffer(buffer.id)) return false;
      buffer = state.activeBuffer;
    }
    if (buffer == null || (buffer.isRemote && buffer.readonly)) return false;
    final targetId = buffer.id;
    final targetPath = buffer.filePath;
    final targetRevision = buffer.revision;
    final targetText = buffer.text;
    var nextText = change == null
        ? revision.source
        : _restoredRegionText(
            buffer: buffer,
            revision: revision,
            comparison: comparison,
            change: change,
          );
    if (nextText == null || nextText == targetText) return nextText != null;
    if (buffer.remoteNote != null) {
      try {
        nextText = await (await _ensureNotesRepository())
            .prepareRestoredContent(buffer.remoteNote!.localId, nextText);
      } on Object catch (error) {
        state = state.copyWith(
          message: WorkspaceMessage(
            WorkspaceMessageCode.saveFailed,
            error: error,
          ),
        );
        return false;
      }
    }
    if (!await _localHistory.captureProtective(
      LocalHistoryBufferSnapshot.fromBuffer(buffer),
      LocalHistoryCaptureReason.beforeRestore,
    )) {
      return false;
    }
    final current = state.activeBuffer;
    if (current == null ||
        current.id != targetId ||
        current.filePath != targetPath ||
        current.revision != targetRevision ||
        current.text != targetText) {
      return false;
    }
    final nextSelection = change == null
        ? TextSelection.collapsed(offset: nextText.length)
        : TextSelection(
            baseOffset: change.currentRange.start,
            extentOffset: change.currentRange.start + change.oldText.length,
          );
    final restored = current
        .edited(
          nextText,
          previousSelection: current.editorState.selection,
          nextSelection: nextSelection,
        )
        .copyWith(format: current.format);
    _localHistory.observeEdit(current, restored);
    state = state.copyWith(
      documentBuffers: _replaceBuffer(state.documentBuffers, restored),
      clearMessage: true,
    );
    _schedulePersistence();
    _requestDerivedRefresh(
      rebuildPreview: _activeModeShowsPreview,
      refreshOutline: !_activeModeShowsPreview,
    );
    _scheduleAutoSave(restored.id);
    if (restored.isRemote) {
      return _enqueueBufferWrite(
        restored.id,
        () => _saveRemoteBufferSnapshot(restored),
      );
    }
    return true;
  }

  Future<LocalHistoryCurrentSourceSnapshot> localHistoryCurrentSource(
    LocalHistoryDocument document,
    LocalHistoryRevision revision,
  ) async {
    if (revision.summary.documentId != document.id) {
      return LocalHistoryCurrentSourceSnapshot(
        kind: LocalHistoryCurrentSourceKind.missing,
        id: 'mismatch:${document.id}',
        version: 0,
        source: '',
        canRestore: false,
      );
    }
    final buffer = localHistoryBufferForDocument(document, revision);
    if (buffer != null) {
      return LocalHistoryCurrentSourceSnapshot(
        kind: LocalHistoryCurrentSourceKind.editor,
        id: buffer.id,
        version: buffer.revision,
        source: buffer.text,
        canRestore: !buffer.isRemote || !buffer.readonly,
      );
    }
    if (document.remoteNote case final reference?) {
      final cached = (await _ensureNotesRepository()).noteById(
        reference.localId,
      );
      if (cached != null && cached.syncState != NoteSyncState.deletedRemotely) {
        return LocalHistoryCurrentSourceSnapshot(
          kind: LocalHistoryCurrentSourceKind.editor,
          id: reference.identity,
          version: cached.revision,
          source: cached.content,
          canRestore: !cached.readonly && !cached.error,
        );
      }
    }
    final path = document.currentPath ?? revision.summary.historicalPath;
    if (path != null && await _service.pathExists(path)) {
      final loaded = await _service.loadTextWithSnapshot(path);
      return LocalHistoryCurrentSourceSnapshot(
        kind: LocalHistoryCurrentSourceKind.disk,
        id: p.normalize(path),
        version: loaded.snapshot.modifiedAt.microsecondsSinceEpoch,
        source: loaded.text,
        canRestore: document.currentPath != null,
      );
    }
    return LocalHistoryCurrentSourceSnapshot(
      kind: LocalHistoryCurrentSourceKind.missing,
      id: 'missing:${document.id}',
      version: 0,
      source: '',
      canRestore: false,
    );
  }

  Future<bool> restoreMissingLocalHistoryRevision({
    required LocalHistoryDocument document,
    required LocalHistoryRevision revision,
    required String destinationPath,
    required bool overwriteExisting,
  }) async {
    if (revision.summary.documentId != document.id) return false;
    final path = p.normalize(p.absolute(destinationPath));
    final policy = _localHistory.policy;
    if (!policy.recordingEnabled || policy.excludes(path)) {
      await _localHistory.captureProtective(
        LocalHistoryBufferSnapshot(
          bufferId: 'restore-missing:$path',
          displayName: p.basename(path),
          text: '',
          format: revision.format,
          revision: 0,
          path: path,
        ),
        LocalHistoryCaptureReason.beforeRestore,
      );
      return false;
    }
    final existed = await _service.pathExists(path);
    if (existed != overwriteExisting) return false;
    WorkspaceFileSnapshot? createdSnapshot;
    try {
      if (!existed) {
        createdSnapshot = await _service.saveNewFormattedText(
          path,
          '',
          format: revision.format,
        );
      }
      var destination = state.bufferForPath(path);
      if (destination == null) {
        if (!await _openLocalHistoryRestoreDestination(path)) {
          if (createdSnapshot != null) {
            await _rollbackMissingHistoryDestination(
              path,
              null,
              createdSnapshot,
            );
          }
          return false;
        }
        destination = state.bufferForPath(path);
      } else if (state.activeBufferId != destination.id) {
        if (!await activateDocumentBuffer(destination.id)) {
          return false;
        }
        destination = state.bufferForPath(path);
      }
      if (destination == null ||
          destination.filePath == null ||
          !p.equals(destination.filePath!, path) ||
          destination.diskState != DocumentDiskState.present) {
        if (createdSnapshot != null) {
          await _rollbackMissingHistoryDestination(path, null, createdSnapshot);
        }
        return false;
      }
      if (destination.text == revision.source) {
        return true;
      }
      final target = _LocalHistoryRestoreTarget(
        workspaceId: state.workspace?.id,
        bufferId: destination.id,
        path: destination.filePath!,
        revision: destination.revision,
        text: destination.text,
        snapshot: destination.diskSnapshot,
        diskState: destination.diskState,
        format: destination.format,
        editorState: destination.editorState,
      );
      if (!await _localHistory.captureProtective(
        LocalHistoryBufferSnapshot.fromBuffer(destination),
        LocalHistoryCaptureReason.beforeRestore,
      )) {
        if (createdSnapshot != null) {
          await _rollbackMissingHistoryDestination(path, null, createdSnapshot);
        }
        return false;
      }
      if (!_isLocalHistoryRestoreTargetCurrent(target) ||
          await _service.fileChangedSince(path, target.snapshot) ||
          !_isLocalHistoryRestoreTargetCurrent(target)) {
        if (createdSnapshot != null) {
          await _rollbackMissingHistoryDestination(path, null, createdSnapshot);
        }
        return false;
      }
      final current = state.documentBuffers
          .where((buffer) => buffer.id == target.bufferId)
          .firstOrNull!;
      final restored = current
          .edited(
            revision.source,
            previousSelection: current.editorState.selection,
            nextSelection: TextSelection.collapsed(
              offset: revision.source.length,
            ),
          )
          .copyWith(format: current.format);
      _localHistory.observeEdit(current, restored);
      state = state.copyWith(
        documentBuffers: _replaceBuffer(state.documentBuffers, restored),
        clearMessage: true,
      );
      _schedulePersistence();
      if (state.activeBufferId == restored.id) {
        _requestDerivedRefresh(
          rebuildPreview: _activeModeShowsPreview,
          refreshOutline: !_activeModeShowsPreview,
        );
      }
      _scheduleAutoSave(restored.id);
      return true;
    } on Object {
      if (createdSnapshot != null) {
        await _rollbackMissingHistoryDestination(path, null, createdSnapshot);
      }
      return false;
    }
  }

  Future<bool> _openLocalHistoryRestoreDestination(String path) async {
    final workspace = state.workspace;
    final insideCurrentWorkspace =
        workspace != null &&
        !workspace.isRemote &&
        workspace.rootPath.isNotEmpty &&
        (p.equals(workspace.rootPath, path) ||
            p.isWithin(workspace.rootPath, path));
    if (insideCurrentWorkspace) {
      return _openActiveFile(path);
    }
    if (state.hasUnsavedChanges) {
      return false;
    }
    await openPath(path);
    final activePath = state.activeBuffer?.filePath;
    return activePath != null && p.equals(activePath, path);
  }

  bool _isLocalHistoryRestoreTargetCurrent(_LocalHistoryRestoreTarget target) {
    final current = state.documentBuffers
        .where((buffer) => buffer.id == target.bufferId)
        .firstOrNull;
    return current != null &&
        state.workspace?.id == target.workspaceId &&
        current.filePath != null &&
        p.equals(current.filePath!, target.path) &&
        current.revision == target.revision &&
        current.text == target.text &&
        _sameFileSnapshot(current.diskSnapshot, target.snapshot) &&
        current.diskState == target.diskState &&
        identical(current.format, target.format) &&
        identical(current.editorState, target.editorState);
  }

  Future<bool> localHistoryRestorePathExists(String path) {
    return _service.pathExists(p.normalize(p.absolute(path)));
  }

  DocumentBuffer? localHistoryBufferForDocument(
    LocalHistoryDocument document,
    LocalHistoryRevision revision,
  ) {
    if (revision.summary.documentId != document.id) return null;
    if (document.remoteNote case final reference?) {
      return state.documentBuffers
          .where((buffer) => buffer.remoteNote == reference)
          .firstOrNull;
    }
    final boundBufferId = _localHistory.bufferIdForDocument(document.id);
    if (boundBufferId != null) {
      final bound = state.documentBuffers
          .where((buffer) => buffer.id == boundBufferId)
          .firstOrNull;
      if (bound != null) return bound;
    }
    final paths = {
      document.currentPath,
      revision.summary.historicalPath,
    }.whereType<String>();
    for (final path in paths) {
      final pathBuffer = state.bufferForPath(path);
      if (pathBuffer != null) return pathBuffer;
    }
    return null;
  }

  Future<void> _rollbackMissingHistoryDestination(
    String path,
    WorkspaceFileLoad? previous,
    WorkspaceFileSnapshot published,
  ) async {
    try {
      if (await _service.fileChangedSince(path, published)) return;
      if (previous == null) {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } else {
        await _service.saveFormattedTextReplacingPath(
          path,
          previous.text,
          format: previous.format,
        );
      }
    } on Object {
      // The persistent warning from the failed protective/restore operation is
      // more useful than masking the original result with cleanup failure.
    }
  }

  Future<bool> protectPathsBeforeExternalReplacement(
    Iterable<String> paths,
  ) async {
    for (final path in paths.toSet()) {
      if (!_isEligibleLocalHistoryPath(path)) continue;
      final buffer = state.bufferForPath(path);
      if (buffer != null) {
        if (!await _localHistory.captureBeforeLoss(
          LocalHistoryBufferSnapshot.fromBuffer(buffer),
          LocalHistoryCaptureReason.beforeDiscard,
        )) {
          return false;
        }
        if (!_bufferOperationTargetIsCurrent(buffer)) return false;
        continue;
      }
      try {
        final loaded = await _service.loadTextWithSnapshot(path);
        if (!await _localHistory.capturePathBeforeLoss(
          path: path,
          text: loaded.text,
          format: loaded.format,
          reason: LocalHistoryCaptureReason.beforeDiscard,
        )) {
          return false;
        }
        if (await _service.fileChangedSince(path, loaded.snapshot)) {
          return false;
        }
      } on FileSystemException {
        // A path already absent from the working tree has no current source
        // version to protect.
      } on FormatException {
        // Binary or invalid text content is outside Local History's scope.
      }
    }
    return true;
  }

  String? _restoredRegionText({
    required DocumentBuffer buffer,
    required LocalHistoryRevision revision,
    required SourceComparison? comparison,
    required SourceComparisonChange change,
  }) {
    if (comparison == null || !change.exact) return null;
    final oldInput = comparison.oldInput;
    final currentInput = comparison.currentInput;
    if (oldInput.id != revision.summary.id ||
        oldInput.version !=
            revision.summary.capturedAt.microsecondsSinceEpoch ||
        currentInput.id != buffer.id ||
        currentInput.version != buffer.revision ||
        oldInput.source != revision.source ||
        currentInput.source != buffer.text ||
        change.currentRange.end > buffer.text.length ||
        buffer.text.substring(
              change.currentRange.start,
              change.currentRange.end,
            ) !=
            change.currentText) {
      return null;
    }
    return buffer.text.replaceRange(
      change.currentRange.start,
      change.currentRange.end,
      change.oldText,
    );
  }

  Future<bool> _discardBufferChangesNow(
    ActiveDocumentSaveTarget operationTarget,
  ) async {
    final refreshedTarget = _refreshBufferSaveTarget(operationTarget);
    if (refreshedTarget == null) {
      return false;
    }
    final current = state.documentBuffers
        .where((buffer) => buffer.id == refreshedTarget.bufferId)
        .firstOrNull;
    if (current == null) {
      return false;
    }
    if (!current.isDirty) {
      return true;
    }
    if (current.isRemote) {
      if (!await _localHistory.captureBeforeLoss(
        LocalHistoryBufferSnapshot.fromBuffer(current),
        LocalHistoryCaptureReason.beforeDiscard,
      )) {
        return false;
      }
      final latest = state.documentBuffers
          .where((b) => b.id == current.id)
          .firstOrNull;
      if (!identical(latest, current)) return false;
      final cached = (await _ensureNotesRepository()).noteById(
        current.remoteNote!.localId,
      );
      if (cached == null) return false;
      state = state.copyWith(
        documentBuffers: _replaceBuffer(
          state.documentBuffers,
          current.copyWith(
            text: cached.content,
            lastSavedText: cached.content,
            dirty: false,
            revision: math.max(cached.revision, current.revision + 1),
          ),
        ),
      );
      _requestDerivedRefresh(
        rebuildPreview: _activeModeShowsPreview,
        refreshOutline: !_activeModeShowsPreview,
      );
      _schedulePersistence();
      return true;
    }
    if (current.filePath != null &&
        !await _localHistory.captureBeforeLoss(
          LocalHistoryBufferSnapshot.fromBuffer(current),
          LocalHistoryCaptureReason.beforeDiscard,
        )) {
      return false;
    }
    final workspace = state.workspace;
    if (workspace == null || workspace.id != refreshedTarget.workspaceId) {
      return false;
    }
    final active = refreshedTarget.path;
    if (active == null) {
      return _closeDocumentBufferNow(refreshedTarget.bufferId, discard: true);
    }
    try {
      final load = await _service.loadTextWithSnapshot(active);
      if (!_isBufferSaveTargetCurrent(refreshedTarget)) {
        return false;
      }
      final currentBuffer = state.documentBuffers
          .where((buffer) => buffer.id == refreshedTarget.bufferId)
          .firstOrNull;
      if (currentBuffer == null) {
        return false;
      }
      final discardedBuffer = currentBuffer.copyWith(
        text: load.text,
        lastSavedText: load.text,
        dirty: false,
        diskSnapshot: load.snapshot,
        format: load.format,
        revision: currentBuffer.revision + 1,
        diskState: DocumentDiskState.present,
        diskVersionText: null,
        diskVersionSnapshot: null,
        recovered: false,
      );
      final remainsActive = state.activeBufferId == refreshedTarget.bufferId;
      final currentWorkspace = state.workspace;
      if (currentWorkspace == null ||
          currentWorkspace.id != refreshedTarget.workspaceId) {
        return false;
      }
      state = state.copyWith(
        workspace: remainsActive
            ? currentWorkspace.copyWith(activeFileSnapshot: load.snapshot)
            : currentWorkspace,
        documentBuffers: _replaceBuffer(state.documentBuffers, discardedBuffer),
        clearMessage: true,
      );
      _schedulePersistence();
      if (remainsActive) {
        _resetSaveTracking();
        await _refreshActiveBufferAfterDiskUpdate(
          bufferId: discardedBuffer.id,
          workspaceId: refreshedTarget.workspaceId,
          text: load.text,
          editRevision: discardedBuffer.revision,
          snapshot: load.snapshot,
        );
      }
      return true;
    } on Object catch (error, stackTrace) {
      busyMarkDebugLogError(
        '[BusyMark] Discard active changes failed',
        error,
        stackTrace,
        context: {'active': busyMarkLogPath(active)},
      );
      if (_workspaceContainsBuffer(
        refreshedTarget.workspaceId,
        refreshedTarget.bufferId,
      )) {
        state = state.copyWith(
          message: WorkspaceMessage(
            WorkspaceMessageCode.couldNotOpenFile,
            error: error,
          ),
        );
      }
      return false;
    }
  }

  Future<bool> refreshWorkspaceFromDiskPreservingOpenTabs() async {
    final workspace = state.workspace;
    if (workspace == null) {
      return false;
    }
    if (workspace.isRemote) {
      await refreshNextcloudNotes();
      return true;
    }
    final refreshRevision = ++_workspaceRefreshRevision;
    _acceptedRefreshRevision = null;
    _invalidateActiveDocumentOperations();
    _cancelPendingDerivedRefresh();
    _cancelAllAutoSaves();
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      final openTarget = workspace.kind == WorkspaceKind.singleMarkdown
          ? workspace.activeFilePath ?? workspace.rootPath
          : workspace.rootPath;
      final refreshed = await _service.openPath(openTarget);
      if (!_isCurrentWorkspaceRefresh(refreshRevision, workspace.id)) {
        return false;
      }
      final refreshedWorkspace = workspace.kind == WorkspaceKind.singleMarkdown
          ? workspace.copyWith(
              files: _mergedDocumentFiles(workspace.files, refreshed.files),
              diagnostics: refreshed.diagnostics,
              markdown: refreshed.markdown,
            )
          : refreshed;
      final existingFiles = {
        for (final file in refreshed.files) file.absolutePath: file,
      };
      final requestedBuffers = List<DocumentBuffer>.of(state.documentBuffers);
      final replacements = <String, _WorkspaceRefreshBufferReplacement>{};
      for (final requested in requestedBuffers) {
        if (!_isCurrentWorkspaceRefresh(refreshRevision, workspace.id)) {
          return false;
        }
        final path = requested.filePath;
        if (path == null) {
          continue;
        }
        if (_authorizedRemovedBuffer(requested)) {
          continue;
        }
        final exists =
            existingFiles.containsKey(path) || await _service.pathExists(path);
        if (!_isCurrentWorkspaceRefresh(refreshRevision, workspace.id)) {
          return false;
        }
        if (!exists) {
          replacements[requested.id] = _WorkspaceRefreshBufferReplacement(
            requested: requested,
            replacement: requested.copyWith(
              diskState: DocumentDiskState.deleted,
            ),
          );
          continue;
        }
        if (requested.isDirty) {
          continue;
        }
        final load = await _service.loadTextWithSnapshot(path);
        if (!_isCurrentWorkspaceRefresh(refreshRevision, workspace.id)) {
          return false;
        }
        final sourceChanged = requested.text != load.text;
        replacements[requested.id] = _WorkspaceRefreshBufferReplacement(
          requested: requested,
          replacement: requested.copyWith(
            text: load.text,
            lastSavedText: load.text,
            dirty: false,
            diskSnapshot: load.snapshot,
            format: load.format,
            revision: sourceChanged
                ? requested.revision + 1
                : requested.revision,
            diskState: DocumentDiskState.present,
          ),
        );
      }
      if (!_isCurrentWorkspaceRefresh(refreshRevision, workspace.id)) {
        return false;
      }
      var buffers = _reconcileWorkspaceRefreshBuffers(
        _workspaceRefreshLiveBuffers(),
        replacements,
      );
      var activeBuffer = _activeRefreshBuffer(
        buffers,
        state.activeBufferId,
        refreshedWorkspace.activeFilePath,
      );
      if (activeBuffer == null &&
          requestedBuffers.isEmpty &&
          state.documentBuffers.isEmpty &&
          workspace.activeFilePath != null &&
          refreshed.activeFilePath != null) {
        final load = await _service.loadTextWithSnapshot(
          refreshed.activeFilePath!,
        );
        if (!_isCurrentWorkspaceRefresh(refreshRevision, workspace.id) ||
            state.documentBuffers.isNotEmpty) {
          return false;
        }
        activeBuffer = _fileBuffer(
          refreshed.activeFilePath!,
          load,
          mode: _settingsController.state.documentViewMode,
        );
        buffers = [activeBuffer];
      }
      var parseTarget = _WorkspaceRefreshParseTarget(
        bufferId: activeBuffer?.id,
        path: activeBuffer?.filePath,
        revision: activeBuffer?.revision,
        text: activeBuffer?.text ?? '',
        sources: _sourceBufferInputs(buffers),
      );
      var reparsed = await _reparseWorkspaceRefresh(
        refreshedWorkspace,
        buffers,
        activeBuffer,
      );
      if (!_isCurrentWorkspaceRefresh(refreshRevision, workspace.id)) {
        return false;
      }
      await _discardWorkspaceRefreshReplacementsWithStaleDisk(replacements);
      if (!_isCurrentWorkspaceRefresh(refreshRevision, workspace.id)) {
        return false;
      }
      buffers = _reconcileWorkspaceRefreshBuffers(
        _workspaceRefreshLiveBuffers(),
        replacements,
      );
      activeBuffer = _activeRefreshBuffer(
        buffers,
        state.activeBufferId,
        refreshedWorkspace.activeFilePath,
      );
      var finalTarget = _WorkspaceRefreshParseTarget(
        bufferId: activeBuffer?.id,
        path: activeBuffer?.filePath,
        revision: activeBuffer?.revision,
        text: activeBuffer?.text ?? '',
        sources: _sourceBufferInputs(buffers),
      );
      if (finalTarget != parseTarget ||
          !_preparedInputsCurrent(reparsed, buffers)) {
        parseTarget = finalTarget;
        reparsed = await _reparseWorkspaceRefresh(
          refreshedWorkspace,
          buffers,
          activeBuffer,
        );
        if (!_isCurrentWorkspaceRefresh(refreshRevision, workspace.id)) {
          return false;
        }
        await _discardWorkspaceRefreshReplacementsWithStaleDisk(replacements);
        if (!_isCurrentWorkspaceRefresh(refreshRevision, workspace.id)) {
          return false;
        }
        buffers = _reconcileWorkspaceRefreshBuffers(
          _workspaceRefreshLiveBuffers(),
          replacements,
        );
        activeBuffer = _activeRefreshBuffer(
          buffers,
          state.activeBufferId,
          refreshedWorkspace.activeFilePath,
        );
        finalTarget = _WorkspaceRefreshParseTarget(
          bufferId: activeBuffer?.id,
          path: activeBuffer?.filePath,
          revision: activeBuffer?.revision,
          text: activeBuffer?.text ?? '',
          sources: _sourceBufferInputs(buffers),
        );
      }
      final tabPaths = _refreshTabPaths(buffers);
      if (finalTarget == parseTarget &&
          _preparedInputsCurrent(reparsed, buffers)) {
        _acceptedRefreshRevision = refreshRevision;
        final publishedWorkspace = reparsed.copyWith(
          activeFilePath: activeBuffer?.filePath,
          activeFileSnapshot: activeBuffer?.diskSnapshot,
          openFilePaths: tabPaths,
        );
        _preparedInputs[publishedWorkspace] = _preparedInputs[reparsed];
        state = state.copyWith(
          workspace: publishedWorkspace,
          preview: activeBuffer == null
              ? null
              : _safePreview(publishedWorkspace, activeBuffer),
          documentBuffers: buffers,
          activeBufferId: activeBuffer?.id,
          isLoading: false,
          clearMessage: true,
        );
        _recordActivePreviewRevision();
      } else {
        // The active source changed during both reparses. Keep the already
        // current derived state and let the ordinary editor refresh pipeline
        // calculate it from the surviving live buffer.
        state = state.copyWith(
          documentBuffers: buffers,
          isLoading: false,
          clearMessage: true,
        );
        _requestDerivedRefresh(
          rebuildPreview: _activeModeShowsPreview,
          refreshOutline: !_activeModeShowsPreview,
        );
      }
      _fileMonitor.updateOpenFilePaths(tabPaths);
      _schedulePersistence();
      _resetSaveTracking();
      _scheduleAutoSave();
      return true;
    } on Object catch (error, stackTrace) {
      busyMarkDebugLogError(
        '[BusyMark] Workspace refresh failed',
        error,
        stackTrace,
        context: {'root': busyMarkLogPath(workspace.rootPath)},
      );
      if (_isCurrentWorkspaceRefresh(refreshRevision, workspace.id)) {
        state = state.copyWith(
          isLoading: false,
          message: WorkspaceMessage(
            WorkspaceMessageCode.couldNotOpenFile,
            error: error,
          ),
        );
        _scheduleAutoSave();
      }
      return false;
    }
  }

  bool _isCurrentWorkspaceRefresh(int revision, String workspaceId) {
    return ref.mounted &&
        revision == _workspaceRefreshRevision &&
        state.workspace?.id == workspaceId;
  }

  void _authorizeRemovedBuffers(String path, Workspace workspace) {
    _removalAuthorizations[path] = _RemovalBufferAuthorization(workspace.id, [
      for (final b in state.documentBuffers)
        if (b.filePath != null &&
            (p.equals(b.filePath!, path) || p.isWithin(path, b.filePath!)))
          b,
    ]);
  }

  bool _authorizedRemovedBuffer(DocumentBuffer buffer) =>
      _removalAuthorizations.values.any(
        (authorization) =>
            authorization.committed &&
            authorization.workspaceId == state.workspace?.id &&
            authorization.buffers.any(
              (authorized) =>
                  !buffer.isDirty &&
                  _workspaceRefreshRequestStillMatches(buffer, authorized),
            ),
      );

  List<DocumentBuffer> _workspaceRefreshLiveBuffers() => [
    for (final buffer in state.documentBuffers)
      if (!_authorizedRemovedBuffer(buffer))
        // A committed removal authorizes only the captured clean revision.
        // Edits accepted afterwards remain recoverable, including edits made
        // while reconciliation is awaiting model work.
        if (buffer.filePath != null &&
            _removalAuthorizations.entries.any(
              (entry) =>
                  entry.value.committed &&
                  entry.value.workspaceId == state.workspace?.id &&
                  (p.equals(buffer.filePath!, entry.key) ||
                      p.isWithin(entry.key, buffer.filePath!)),
            ))
          buffer.copyWith(diskState: DocumentDiskState.deleted)
        else
          buffer,
  ];

  Future<void> _discardWorkspaceRefreshReplacementsWithStaleDisk(
    Map<String, _WorkspaceRefreshBufferReplacement> replacements,
  ) async {
    for (final entry in replacements.entries.toList(growable: false)) {
      final replacement = entry.value.replacement;
      final path = replacement.filePath;
      final snapshot = replacement.diskSnapshot;
      if (replacement.diskState != DocumentDiskState.present ||
          path == null ||
          snapshot == null) {
        continue;
      }
      if (await _service.fileChangedSince(path, snapshot)) {
        replacements.remove(entry.key);
      }
    }
  }

  Future<Workspace> _reparseWorkspaceRefresh(
    Workspace refreshedWorkspace,
    List<DocumentBuffer> buffers,
    DocumentBuffer? activeBuffer,
  ) async {
    // Use the live selection: another context can be selected while the disk
    // model is loading. Existing input/revision guards still govern publication.
    final live = state.workspace;
    if (live != null && live.id == refreshedWorkspace.id) {
      refreshedWorkspace = _service.preserveWritersideContext(
        refreshedWorkspace,
        live,
      );
    }
    final nextWorkspace = refreshedWorkspace.copyWith(
      activeFilePath: activeBuffer?.filePath,
      activeFileSnapshot: activeBuffer?.diskSnapshot,
      openFilePaths: _refreshTabPaths(buffers),
    );
    if (activeBuffer != null) {
      return _reparseWithDocumentBuffers(
        nextWorkspace,
        activeBuffer,
        buffers: buffers,
      );
    }
    final inputs = _PreparedDocumentInputs(
      _sourceBufferInputs(buffers),
      _workspaceDiskRevision,
      _activeDocumentRevision,
      state.workspace?.id,
    );
    final prepared = await _service.withDocumentSources(nextWorkspace, {
      for (final buffer in buffers)
        if (buffer.filePath != null) buffer.filePath!: buffer.text,
    });
    if (prepared.writersideProject != null &&
        !await prepared.writersideProject!.observedInputsMatchDisk()) {
      return nextWorkspace.copyWith();
    }
    _preparedInputs[prepared] = inputs;
    return prepared;
  }

  Future<bool> _runWorkspaceFileOperation(
    Future<String?> Function(Workspace workspace) operation, {
    bool openForEditing = false,
  }) async {
    final workspace = state.workspace;
    if (workspace == null) {
      return false;
    }
    final before = _incorporatedDiskStates(workspace, state.documentBuffers);
    _reconciledNotifications = null;
    _workspaceFileOperationDepth++;
    var reconciled = false;
    try {
      final preferredActivePath = await operation(workspace);
      await _persistPendingHistoryReconciliation();
      if (!ref.mounted || state.workspace?.id != workspace.id) {
        return false;
      }
      final refreshed = await refreshWorkspaceFromDiskPreservingOpenTabs();
      if (!refreshed) {
        return false;
      }
      await _acknowledgeHistoryOperationsAfterWorkspaceRefresh();
      if (preferredActivePath != null) {
        final opened = await _openActiveFile(preferredActivePath);
        if (opened &&
            openForEditing &&
            state.activeBuffer?.filePath == preferredActivePath &&
            state.activeBuffer?.editorState.mode ==
                DocumentViewModePreference.preview) {
          // Creation opens an editable document without changing the global
          // preference or the view modes of any other open buffers.
          updateActiveEditorMode(DocumentViewModePreference.source);
        }
        reconciled = opened;
        if (opened) _recordReconciledNotifications(workspace, before);
        return opened;
      }
      reconciled = true;
      _recordReconciledNotifications(workspace, before);
      return true;
    } on Object catch (error, stackTrace) {
      busyMarkDebugLogError(
        '[BusyMark] Workspace file operation failed',
        error,
        stackTrace,
        context: {'root': busyMarkLogPath(workspace.rootPath)},
      );
      if (!ref.mounted) {
        return false;
      }
      state = state.copyWith(
        isLoading: false,
        message: WorkspaceMessage(
          WorkspaceMessageCode.fileOperationFailed,
          error: error,
        ),
      );
      return false;
    } finally {
      if (!reconciled) _reconciledNotifications = null;
      _workspaceFileOperationDepth--;
      if (_workspaceFileOperationDepth == 0 && ref.mounted) {
        final navigationRevision = _fileOperationNavigationRevision;
        _fileOperationNavigationRevision = null;
        final current = state.workspace;
        if (navigationRevision == _removalOperationRevision &&
            current != null &&
            !_preparedInputsCurrent(current, state.documentBuffers)) {
          // Failed/rolled-back operations still finish any deferred navigation
          // preparation through the existing bounded derived-work scheduler.
          _requestDerivedRefresh(rebuildPreview: true);
        }
        final pending = List<_QueuedFileMonitorEvent>.of(
          _deferredFileMonitorEvents,
        );
        _deferredFileMonitorEvents.clear();
        // Observe notifications only after reconciliation/opening completes.
        // Own writes then match the refreshed snapshots, while unrelated
        // external changes retain their normal monitoring behavior.
        for (final event in pending) {
          _queueCapturedFileMonitorEvent(event);
        }
      }
    }
  }

  Future<void> _acknowledgeHistoryOperationsAfterWorkspaceRefresh() async {
    for (final operationId in _historyOperationsAwaitingWorkspaceRefresh.toList(
      growable: false,
    )) {
      await _localHistory.acknowledgeStagedPathOperation(operationId);
      _historyOperationsAwaitingWorkspaceRefresh.remove(operationId);
    }
  }

  void _remapOpenWorkspacePaths(
    Workspace operationWorkspace,
    String sourcePath,
    String targetPath,
  ) {
    final current = state.workspace;
    if (current == null || current.id != operationWorkspace.id) {
      return;
    }
    final activeFilePath = current.activeFilePath;
    final remappedActive = _remapMovedPath(
      activeFilePath,
      sourcePath,
      targetPath,
    );
    final remappedTabs = [
      for (final path in current.openFilePaths)
        _remapMovedPath(path, sourcePath, targetPath) ?? path,
    ];
    if (remappedActive == null &&
        _samePathLists(remappedTabs, current.openFilePaths)) {
      return;
    }
    state = state.copyWith(
      workspace: current.copyWith(
        activeFilePath: remappedActive ?? activeFilePath,
        openFilePaths: remappedTabs,
      ),
      documentBuffers: [
        for (final buffer in state.documentBuffers)
          if (_remapMovedPath(buffer.filePath, sourcePath, targetPath)
              case final remapped?)
            buffer.copyWith(filePath: remapped)
          else
            buffer,
      ],
    );
  }

  List<LocalHistoryBufferPathTransition> _beginLocalHistoryPathTransitions(
    String sourcePath,
    String targetPath,
  ) {
    final transitions = <LocalHistoryBufferPathTransition>[];
    for (final buffer in state.documentBuffers) {
      final currentPath = buffer.filePath;
      final destination = _remapMovedPath(currentPath, sourcePath, targetPath);
      if (currentPath == null || destination == null) continue;
      transitions.add(
        _localHistory.beginBufferPathTransition(
          bufferId: buffer.id,
          sourcePath: currentPath,
          destinationPath: destination,
        ),
      );
    }
    return transitions;
  }

  Future<void> _finishLocalHistoryPathTransitions(
    Iterable<LocalHistoryBufferPathTransition> transitions, {
    required bool committed,
  }) async {
    for (final transition in transitions) {
      await _localHistory.finishBufferPathTransition(
        transition,
        committed: committed,
      );
    }
  }

  Future<Workspace> _reparseWithDocumentBuffers(
    Workspace workspace,
    DocumentBuffer target, {
    Iterable<DocumentBuffer>? buffers,
    bool priority = false,
  }) async {
    final sourceBuffers = List<DocumentBuffer>.of(
      buffers ?? state.documentBuffers,
    );
    sourceBuffers.removeWhere(
      (b) =>
          b.id == target.id ||
          target.filePath != null && b.filePath == target.filePath,
    );
    sourceBuffers.add(target);
    final inputs = _PreparedDocumentInputs(
      _sourceBufferInputs(sourceBuffers),
      _workspaceDiskRevision,
      _activeDocumentRevision,
      state.workspace?.id,
    );
    final baseline = _sourceBufferInputs(state.documentBuffers);
    final baselineWorkspaceId = state.workspace?.id;
    final revision = _activeDocumentRevision;
    Future<Workspace> prepare() async {
      // Publication permission and model freshness are separate. Obsolete
      // queued jobs do not start work; running jobs finish without publishing.
      if (!ref.mounted ||
          state.workspace?.id != baselineWorkspaceId ||
          revision != _activeDocumentRevision ||
          !_sameBufferInputs(
            baseline,
            _sourceBufferInputs(state.documentBuffers),
          )) {
        return workspace.copyWith();
      }
      try {
        final prepared = await _service.prepareDocument(workspace, target, {
          for (final buffer in sourceBuffers)
            if (buffer.filePath != null) buffer.filePath!: buffer.text,
        });
        if (prepared.writersideProject != null &&
            !await prepared.writersideProject!.observedInputsMatchDisk()) {
          return workspace.copyWith();
        }
        _preparedInputs[prepared] = inputs;
        return prepared;
      } on WritersideInputsChanged {
        return workspace.copyWith();
      }
    }

    final pending = _PendingPreparation(prepare, workspace);
    if (_preparationsRunning < 2 || priority) {
      _startPreparation(pending);
    } else {
      _pendingPreparation?.completion.complete(
        _pendingPreparation!.fallback.copyWith(),
      );
      _pendingPreparation = pending;
    }
    return pending.completion.future;
  }

  void _startPreparation(_PendingPreparation pending) {
    _preparationsRunning++;
    unawaited(() async {
      try {
        pending.completion.complete(await pending.run());
      } on Object catch (error, stack) {
        pending.completion.completeError(error, stack);
      } finally {
        _preparationsRunning--;
        final next = _pendingPreparation;
        _pendingPreparation = null;
        if (next != null) _startPreparation(next);
      }
    }());
  }

  bool _preparedInputsCurrent(
    Workspace workspace,
    Iterable<DocumentBuffer> buffers,
  ) {
    final prepared = _preparedInputs[workspace];
    return prepared != null &&
        prepared.diskRevision == _workspaceDiskRevision &&
        prepared.operationRevision == _activeDocumentRevision &&
        prepared.workspaceId == state.workspace?.id &&
        _sameBufferInputs(prepared.buffers, _sourceBufferInputs(buffers));
  }

  Future<ValidationOutcome> validateActive() async {
    if (_manualValidationRunning) {
      return const ValidationOutcome(status: ValidationStatus.busy);
    }
    _manualValidationRunning = true;
    // The explicit request covers all edits queued so far. Running automatic
    // work becomes stale; later edits can queue a refresh after this request.
    _cancelPendingDerivedRefresh();
    try {
      return await _validateActive(rebuildPreview: true, priority: true);
    } finally {
      _manualValidationRunning = false;
      if (ref.mounted && _derivedRefreshPending) {
        unawaited(_drainDerivedRefreshes());
      }
    }
  }

  bool isCurrentValidation(ValidationOutcome outcome) =>
      outcome.published &&
      state.workspace?.id == outcome.workspaceId &&
      state.workspace?.activeFilePath == outcome.filePath &&
      state.activeBuffer?.id == outcome.bufferId &&
      editRevision == outcome.revision &&
      _activeDocumentRevision == outcome.documentRevision;

  Future<ValidationOutcome> _validateActive({
    required bool rebuildPreview,
    bool priority = false,
  }) async {
    final workspace = state.workspace;
    final targetBuffer = state.activeBuffer;
    if (workspace == null || targetBuffer == null) {
      return const ValidationOutcome(status: ValidationStatus.unavailable);
    }
    final sequence = ++_validationSequence;
    final buffers = List<DocumentBuffer>.of(state.documentBuffers);
    final bufferId = targetBuffer.id;
    final workspaceId = workspace.id;
    final activeFilePath = targetBuffer.filePath;
    final text = targetBuffer.text;
    final editRevision = targetBuffer.revision;
    final operationRevision = _activeDocumentRevision;
    ValidationOutcome outcome(ValidationStatus status) => ValidationOutcome(
      status: status,
      workspaceId: workspaceId,
      filePath: activeFilePath,
      bufferId: bufferId,
      revision: editRevision,
      documentRevision: operationRevision,
    );
    bool current() =>
        ref.mounted &&
        sequence == _validationSequence &&
        _canPublishActiveDerivedContent(
          operationRevision: operationRevision,
          workspaceId: workspaceId,
          bufferId: bufferId,
          path: activeFilePath,
          revision: editRevision,
          source: text,
        ) &&
        buffers.length == state.documentBuffers.length &&
        buffers.every(
          (buffer) => state.documentBuffers.any(
            (live) =>
                live.id == buffer.id &&
                live.filePath == buffer.filePath &&
                live.revision == buffer.revision &&
                live.text == buffer.text,
          ),
        );
    try {
      final reparsed = await _reparseWithDocumentBuffers(
        workspace,
        targetBuffer,
        buffers: buffers,
        priority: priority,
      );
      final currentWorkspace = state.workspace;
      if (!current() ||
          currentWorkspace == null ||
          !_preparedInputsCurrent(reparsed, state.documentBuffers)) {
        return outcome(ValidationStatus.stale);
      }
      final currentSnapshot = currentWorkspace.activeFileSnapshot;
      final validatedWorkspace = reparsed.copyWith(
        activeFileSnapshot: currentSnapshot,
        openFilePaths: currentWorkspace.openFilePaths,
        files: currentWorkspace.files,
        runtimeDiagnostics: currentWorkspace.runtimeDiagnostics,
      );
      _preparedInputs[validatedWorkspace] = _preparedInputs[reparsed];
      if (rebuildPreview) {
        state = state.copyWith(
          workspace: validatedWorkspace,
          preview: _safePreview(reparsed, targetBuffer),
          clearMessage: true,
        );
        _recordActivePreviewRevision();
      } else {
        state = state.copyWith(
          workspace: validatedWorkspace,
          liveOutline: ActiveDocumentOutline(
            workspaceId: validatedWorkspace.id,
            bufferId: bufferId,
            filePath: targetBuffer.filePath,
            source: text,
            headings: _service.documentOutline(
              validatedWorkspace,
              targetBuffer,
            ),
          ),
          clearMessage: true,
        );
      }
      return outcome(ValidationStatus.published);
    } on Object catch (error) {
      if (current()) {
        state = state.copyWith(
          message: WorkspaceMessage(
            WorkspaceMessageCode.validationFailed,
            error: error,
          ),
        );
        return outcome(ValidationStatus.failed);
      }
      return outcome(ValidationStatus.stale);
    }
  }

  bool _writersideSourceMismatch(Workspace workspace, DocumentBuffer buffer) {
    final context = resolveWorkspaceDocumentContext(workspace, buffer);
    final topic = context.writersideModule?.topics
        .where((topic) => topic.filePath == context.diskPath)
        .firstOrNull;
    return topic != null && topic.document.source != buffer.text;
  }

  PreviewDocument? _safePreview(Workspace workspace, DocumentBuffer buffer) {
    try {
      if (_writersideSourceMismatch(workspace, buffer)) return null;
      return _service.buildDocumentPreview(workspace, buffer);
    } on Object {
      return PreviewDocument(
        title: '',
        modeLabel: '',
        compatibility: '',
        blocks: [PreviewBlock(kind: PreviewBlockKind.code, text: buffer.text)],
      );
    }
  }

  Future<void> _showEditorForNewFile() {
    if (_settingsController.state.documentViewMode !=
        DocumentViewModePreference.preview) {
      return Future<void>.value();
    }
    return _settingsController.setDocumentViewMode(
      DocumentViewModePreference.editor,
    );
  }

  void _scheduleAutoSave([String? bufferId]) {
    if (!_settingsController.state.autoSave) {
      return;
    }
    final targets = bufferId == null
        ? state.dirtyBuffers
        : state.documentBuffers.where((buffer) => buffer.id == bufferId);
    for (final buffer in targets) {
      if (!_canAutoSave(buffer)) {
        continue;
      }
      _cancelAutoSave(buffer.id);
      late final Timer timer;
      timer = Timer(_autoSaveDelay, () {
        if (identical(_autoSaveDebounces[buffer.id], timer)) {
          _autoSaveDebounces.remove(buffer.id);
        }
        unawaited(_autoSaveBufferIfNeeded(buffer.id));
      });
      _autoSaveDebounces[buffer.id] = timer;
    }
  }

  bool _canAutoSave(DocumentBuffer buffer) {
    return buffer.isDirty &&
        !buffer.isUntitled &&
        buffer.diskState == DocumentDiskState.present &&
        !buffer.format.hasMixedLineEndings;
  }

  void _cancelAutoSave(String bufferId) {
    _autoSaveDebounces.remove(bufferId)?.cancel();
  }

  void _cancelAllAutoSaves() {
    for (final timer in _autoSaveDebounces.values) {
      timer.cancel();
    }
    _autoSaveDebounces.clear();
  }

  Future<T> _enqueueBufferWrite<T>(
    String bufferId,
    Future<T> Function() write,
  ) {
    final prior = _bufferWriteQueues[bufferId] ?? Future<void>.value();
    final result = prior.then((_) => write());
    late final Future<void> tail;
    tail = result.then<void>((_) {}, onError: (_, _) {}).whenComplete(() {
      if (identical(_bufferWriteQueues[bufferId], tail)) {
        _bufferWriteQueues.remove(bufferId);
      }
    });
    _bufferWriteQueues[bufferId] = tail;
    return result;
  }

  Future<void> _drainBufferWrites() async {
    while (_bufferWriteQueues.isNotEmpty) {
      await Future.wait(_bufferWriteQueues.values.toList(growable: false));
    }
  }

  Future<bool> _autoSaveBufferIfNeeded(String bufferId) =>
      _enqueueBufferWrite(bufferId, () => _autoSaveBufferNow(bufferId));

  Future<bool> _autoSaveBufferNow(String bufferId) async {
    if (!_settingsController.state.autoSave) {
      return true;
    }
    final target = state.documentBuffers
        .where((buffer) => buffer.id == bufferId)
        .firstOrNull;
    if (target == null || !target.isDirty) {
      return true;
    }
    if (!_canAutoSave(target)) {
      return false;
    }
    if (target.isRemote) return _saveRemoteBufferSnapshot(target);
    final path = target.filePath!;
    if (await _service.fileChangedSince(path, target.diskSnapshot)) {
      return false;
    }
    final beforeWrite = state.documentBuffers
        .where((buffer) => buffer.id == bufferId)
        .firstOrNull;
    if (beforeWrite == null || beforeWrite.revision != target.revision) {
      _scheduleAutoSave(bufferId);
      return false;
    }
    try {
      final snapshot = await _service.saveText(
        path,
        target.format.formattedText(target.text),
      );
      final current = state.documentBuffers
          .where((buffer) => buffer.id == bufferId)
          .firstOrNull;
      if (current == null) {
        return false;
      }
      final next = current.copyWith(
        lastSavedText: target.text,
        dirty: current.text != target.text,
        diskSnapshot: snapshot,
        diskState: DocumentDiskState.present,
        diskVersionText: null,
        diskVersionSnapshot: null,
        recovered: false,
      );
      state = state.copyWith(
        documentBuffers: _replaceBuffer(state.documentBuffers, next),
        workspace: state.activeBufferId == bufferId
            ? state.workspace?.copyWith(activeFileSnapshot: snapshot)
            : state.workspace,
        clearMessage: true,
      );
      _schedulePersistence();
      if (next.isDirty) {
        _scheduleAutoSave(bufferId);
      }
      return true;
    } on Object catch (error) {
      state = state.copyWith(
        message: WorkspaceMessage(
          WorkspaceMessageCode.saveFailed,
          error: error,
        ),
      );
      return false;
    }
  }

  void _resetSaveTracking({bool dirty = false}) {
    _editRevision = dirty ? _editRevision + 1 : 0;
  }

  int _invalidateActiveDocumentOperations() {
    _activeDocumentRevision++;
    return _activeDocumentRevision;
  }

  bool _isCurrentActiveDocumentOperation(int operationRevision) {
    return ref.mounted && operationRevision == _activeDocumentRevision;
  }

  bool _isCurrentActiveDocument(
    int operationRevision, {
    required String? workspaceId,
    required String bufferId,
    required String? activeFilePath,
  }) {
    if (!ref.mounted) return false;
    final workspace = state.workspace;
    return operationRevision == _activeDocumentRevision &&
        workspace != null &&
        workspace.id == workspaceId &&
        workspace.activeFilePath == activeFilePath &&
        state.activeBufferId == bufferId;
  }

  bool _canPublishActiveDerivedContent({
    required int operationRevision,
    required String workspaceId,
    required String bufferId,
    required String? path,
    required int revision,
    required String source,
  }) {
    final buffer = state.activeBuffer;
    return _isCurrentActiveDocument(
          operationRevision,
          workspaceId: workspaceId,
          bufferId: bufferId,
          activeFilePath: path,
        ) &&
        state.activeBufferId == bufferId &&
        buffer != null &&
        buffer.filePath == path &&
        buffer.revision == revision &&
        buffer.text == source;
  }

  bool _workspaceContainsBuffer(String workspaceId, String bufferId) {
    return state.workspace?.id == workspaceId &&
        state.documentBuffers.any((buffer) => buffer.id == bufferId);
  }

  bool _isBufferSaveTargetCurrent(ActiveDocumentSaveTarget target) {
    final workspace = state.workspace;
    final buffer = state.documentBuffers
        .where((candidate) => candidate.id == target.bufferId)
        .firstOrNull;
    return workspace != null &&
        workspace.id == target.workspaceId &&
        workspace.kind == target.workspaceKind &&
        buffer != null &&
        buffer.filePath == target.path &&
        buffer.revision == target.editRevision &&
        buffer.text == target.text &&
        _sameFileSnapshot(buffer.diskSnapshot, target.snapshot);
  }

  ActiveDocumentSaveTarget? _refreshBufferSaveTarget(
    ActiveDocumentSaveTarget target,
  ) {
    final workspace = state.workspace;
    final buffer = state.documentBuffers
        .where((candidate) => candidate.id == target.bufferId)
        .firstOrNull;
    if (workspace == null ||
        workspace.id != target.workspaceId ||
        workspace.kind != target.workspaceKind ||
        buffer == null ||
        buffer.filePath != target.path ||
        buffer.revision != target.editRevision ||
        buffer.text != target.text) {
      return null;
    }
    return ActiveDocumentSaveTarget._(
      workspaceId: target.workspaceId,
      bufferId: target.bufferId,
      path: target.path,
      documentRevision: target.documentRevision,
      editRevision: target.editRevision,
      snapshot: buffer.diskSnapshot,
      text: target.text,
      workspaceKind: target.workspaceKind,
      format: buffer.format,
    );
  }
}

DocumentBuffer _fileBuffer(
  String path,
  WorkspaceFileLoad load, {
  String? id,
  DocumentViewModePreference mode = DocumentViewModePreference.editor,
}) {
  final format =
      load.format.lfCount == 0 &&
          load.format.crlfCount == 0 &&
          load.format.crCount == 0 &&
          load.text.endsWith('\n')
      ? load.format.copyWith(
          lineEnding: DocumentLineEnding.lf,
          hasFinalNewline: true,
        )
      : load.format;
  return DocumentBuffer.file(
    id: id ?? 'file:$path',
    filePath: path,
    text: load.text,
    snapshot: load.snapshot,
    format: format,
    mode: mode,
  );
}

List<DocumentBuffer> _replaceBuffer(
  List<DocumentBuffer> buffers,
  DocumentBuffer replacement,
) {
  return List.unmodifiable([
    for (final buffer in buffers)
      if (buffer.id == replacement.id) replacement else buffer,
  ]);
}

bool _samePathList(List<String> first, List<String> second) {
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index++) {
    if (!p.equals(first[index], second[index])) return false;
  }
  return true;
}

class _WorkspaceRefreshBufferReplacement {
  const _WorkspaceRefreshBufferReplacement({
    required this.requested,
    required this.replacement,
  });

  final DocumentBuffer requested;
  final DocumentBuffer replacement;
}

class _LocalHistoryRestoreTarget {
  const _LocalHistoryRestoreTarget({
    required this.workspaceId,
    required this.bufferId,
    required this.path,
    required this.revision,
    required this.text,
    required this.snapshot,
    required this.diskState,
    required this.format,
    required this.editorState,
  });

  final String? workspaceId;
  final String bufferId;
  final String path;
  final int revision;
  final String text;
  final WorkspaceFileSnapshot? snapshot;
  final DocumentDiskState diskState;
  final TextFormatMetadata format;
  final DocumentEditorState editorState;
}

class _WorkspaceRefreshParseTarget {
  const _WorkspaceRefreshParseTarget({
    required this.bufferId,
    required this.path,
    required this.revision,
    required this.text,
    this.sources = const [],
  });

  final String? bufferId;
  final String? path;
  final int? revision;
  final String text;
  final List<_BufferSourceInput> sources;

  @override
  bool operator ==(Object other) =>
      other is _WorkspaceRefreshParseTarget &&
      other.bufferId == bufferId &&
      other.path == path &&
      other.revision == revision &&
      other.text == text &&
      _sameBufferInputs(sources, other.sources);

  @override
  int get hashCode => Object.hash(bufferId, path, revision, text);
}

List<DocumentBuffer> _reconcileWorkspaceRefreshBuffers(
  List<DocumentBuffer> liveBuffers,
  Map<String, _WorkspaceRefreshBufferReplacement> replacements,
) {
  return List.unmodifiable([
    for (final live in liveBuffers)
      if (replacements[live.id] case final result?)
        if (_workspaceRefreshRequestStillMatches(live, result.requested))
          result.replacement.copyWith(editorState: live.editorState)
        else
          live
      else
        live,
  ]);
}

bool _workspaceRefreshRequestStillMatches(
  DocumentBuffer live,
  DocumentBuffer requested,
) {
  return live.id == requested.id &&
      live.filePath == requested.filePath &&
      live.text == requested.text &&
      live.lastSavedText == requested.lastSavedText &&
      live.dirty == requested.dirty &&
      live.revision == requested.revision &&
      live.diskState == requested.diskState &&
      _sameFileSnapshot(live.diskSnapshot, requested.diskSnapshot);
}

DocumentBuffer? _activeRefreshBuffer(
  List<DocumentBuffer> buffers,
  String? activeBufferId,
  String? refreshedActivePath,
) {
  final active = activeBufferId == null
      ? null
      : buffers.where((buffer) => buffer.id == activeBufferId).firstOrNull;
  if (active != null) return active;
  final refreshed = refreshedActivePath == null
      ? null
      : buffers
            .where(
              (buffer) =>
                  buffer.filePath != null &&
                  p.equals(buffer.filePath!, refreshedActivePath),
            )
            .firstOrNull;
  return refreshed ?? buffers.firstOrNull;
}

List<String> _refreshTabPaths(List<DocumentBuffer> buffers) => [
  for (final buffer in buffers)
    if (buffer.filePath != null) buffer.filePath!,
];

class _ActivePreviewRevision {
  const _ActivePreviewRevision({
    required this.workspaceId,
    required this.bufferId,
    required this.revision,
  });

  final String workspaceId;
  final String bufferId;
  final int revision;
}

bool _modeShowsPreview(DocumentViewModePreference mode) {
  return mode == DocumentViewModePreference.preview ||
      mode == DocumentViewModePreference.split;
}

List<DocumentFile> _mergedDocumentFiles(
  List<DocumentFile> current,
  List<DocumentFile> refreshed,
) {
  final refreshedPaths = {for (final file in refreshed) file.absolutePath};
  return List.unmodifiable([
    for (final file in current)
      if (!refreshedPaths.contains(file.absolutePath)) file,
    ...refreshed,
  ]);
}

String _withFinalNewlinePolicy(String text, bool hasFinalNewline) {
  if (hasFinalNewline) {
    return text.endsWith('\n') ? text : '$text\n';
  }
  return text.replaceFirst(RegExp(r'\n+$'), '');
}

extension _ControllerFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

bool _sameFileSnapshot(
  WorkspaceFileSnapshot? first,
  WorkspaceFileSnapshot? second,
) {
  if (identical(first, second)) {
    return true;
  }
  return first != null && second != null && !first.differsFrom(second);
}

bool _sameBytes(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

bool _isEligibleLocalHistoryPath(String path) {
  final normalized = path.toLowerCase();
  return isTextDocumentationPath(path) ||
      p.basename(path) == '.gitignore' ||
      normalized.endsWith('.css') ||
      normalized.endsWith('.js');
}

List<String> _openFileTabPaths(Workspace workspace, String path) {
  if (workspace.openFilePaths.contains(path)) {
    return workspace.openFilePaths;
  }
  return [...workspace.openFilePaths, path];
}

bool _supportsOpenFileTabs(Workspace workspace) {
  return switch (workspace.kind) {
    WorkspaceKind.singleMarkdown ||
    WorkspaceKind.markdownFolder ||
    WorkspaceKind.writersideModule => true,
    WorkspaceKind.untitledMarkdown || WorkspaceKind.nextcloudNotes => false,
  };
}

String? _remapMovedPath(String? path, String source, String target) {
  if (path == null) {
    return null;
  }
  final normalizedPath = p.normalize(path);
  final normalizedSource = p.normalize(source);
  final normalizedTarget = p.normalize(target);
  if (p.equals(normalizedPath, normalizedSource)) {
    return normalizedTarget;
  }
  if (!p.isWithin(normalizedSource, normalizedPath)) {
    return null;
  }
  return p.normalize(
    p.join(
      normalizedTarget,
      p.relative(normalizedPath, from: normalizedSource),
    ),
  );
}

bool _samePathLists(List<String> first, List<String> second) {
  if (first.length != second.length) {
    return false;
  }
  for (var index = 0; index < first.length; index += 1) {
    if (!p.equals(first[index], second[index])) {
      return false;
    }
  }
  return true;
}

typedef _BufferSourceInput = ({
  String id,
  String? path,
  int revision,
  String text,
});
List<_BufferSourceInput> _sourceBufferInputs(
  Iterable<DocumentBuffer> buffers,
) => [
  for (final b in buffers)
    (id: b.id, path: b.filePath, revision: b.revision, text: b.text),
]..sort((a, b) => a.id.compareTo(b.id));

bool _sameBufferInputs(
  List<_BufferSourceInput> a,
  List<_BufferSourceInput> b,
) =>
    a.length == b.length &&
    List.generate(a.length, (i) => a[i] == b[i]).every((v) => v);

class _PreparedDocumentInputs {
  const _PreparedDocumentInputs(
    this.buffers,
    this.diskRevision,
    this.operationRevision,
    this.workspaceId,
  );
  final List<_BufferSourceInput> buffers;
  final int diskRevision;
  final int operationRevision;
  final String? workspaceId;
}

typedef _IncorporatedDiskState = ({bool exists, String? hash});

class _ReconciledFileNotifications {
  const _ReconciledFileNotifications(
    this.workspaceId,
    this.rootPath,
    this.modules,
    this.refreshRevision,
    this.states,
    this.expires,
  );
  final String workspaceId;
  final String rootPath;
  final List<WritersideModule> modules;
  final int refreshRevision;
  final Map<String, _IncorporatedDiskState> states;
  final DateTime expires;
}

class _PendingPreparation {
  _PendingPreparation(this.run, this.fallback);
  final Future<Workspace> Function() run;
  final Workspace fallback;
  final completion = Completer<Workspace>();
}

class _RemovalBufferAuthorization {
  _RemovalBufferAuthorization(this.workspaceId, this.buffers);
  final String workspaceId;
  final List<DocumentBuffer> buffers;
  bool committed = false;
}
