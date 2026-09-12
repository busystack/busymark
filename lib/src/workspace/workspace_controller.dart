import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../app/app_settings.dart';
import '../comparison/source_comparison.dart';
import '../core/debug_log.dart';
import '../core/diagnostic.dart';
import '../core/source_span.dart';
import '../core/path_utils.dart' show isTextDocumentationPath;
import '../markdown/busymark_document.dart';
import '../markdown/document_outline.dart';
import '../markdown/preview_model.dart';
import '../local_history/local_history_controller.dart';
import '../local_history/local_history_models.dart';
import '../writerside/writerside_project_creator.dart';
import '../writerside/writerside_project.dart';
import '../writerside/writerside_instance_service.dart';
import '../writerside/writerside_topic_removal_service.dart';
import '../writerside/writerside_topic_creator.dart';
import '../writerside/writerside_toc_editor.dart';
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

  bool get needsSaveLocation => path == null;
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

class WorkspaceController extends Notifier<WorkspaceState> {
  static const _autoSaveDelay = Duration(milliseconds: 1500);

  late WorkspaceService _service;
  late AppSettingsController _settingsController;
  late DocumentSessionStore _sessionStore;
  late DocumentRecoveryStore _recoveryStore;
  late WorkspaceFileMonitor _fileMonitor;
  late LocalHistoryController _localHistory;
  StreamSubscription<WorkspaceFileMonitorEvent>? _fileMonitorSubscription;
  final _autoSaveDebounces = <String, Timer>{};
  final _bufferWriteQueues = <String, Future<void>>{};
  Timer? _persistenceDebounce;
  Timer? _workspaceRefreshDebounce;
  var _derivedRefreshRunning = false;
  var _derivedRefreshPending = false;
  var _pendingPreviewRefresh = false;
  var _pendingOutlineRefresh = false;
  _ActivePreviewRevision? _activePreviewRevision;
  var _editRevision = 0;
  var _activeDocumentRevision = 0;
  var _workspaceRefreshRevision = 0;
  var _untitledSequence = 0;
  final _intentionallyRemovedPaths = <String>{};
  late Future<RecoverySnapshot> _recoveryStart;
  Future<void> _persistenceWrites = Future.value();

  int get editRevision => state.activeBuffer?.revision ?? _editRevision;

  void updateMathRenderDiagnostic({
    required String expressionId,
    required String? code,
    SourceSpan? sourceSpan,
  }) {
    final workspace = state.workspace;
    if (workspace == null) {
      return;
    }
    final filePath =
        sourceSpan?.filePath ?? workspace.activeFilePath ?? workspace.rootPath;
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
    _fileMonitorSubscription = _fileMonitor.events.listen(
      (event) => unawaited(_handleFileMonitorEvent(event)),
    );
    _recoveryStart = _recoveryStore.beginRun();
    ref.listen<AppSettings>(appSettingsControllerProvider, (previous, next) {
      if (!next.autoSave) {
        _cancelAllAutoSaves();
        return;
      }
      if (state.dirtyBuffers.any((buffer) => buffer.filePath != null)) {
        _scheduleAutoSave();
      }
    });
    ref.onDispose(() {
      _cancelPendingDerivedRefresh();
      _cancelAllAutoSaves();
      _persistenceDebounce?.cancel();
      _workspaceRefreshDebounce?.cancel();
      unawaited(_fileMonitorSubscription?.cancel());
    });
    return const WorkspaceState();
  }

  Future<bool> restorePreviousSession() async {
    if (state.workspace != null) {
      return state.documentBuffers.isNotEmpty;
    }
    final recovery = await _recoveryStart;
    final session = await _sessionStore.load();
    for (final association
        in session?.pendingLocalHistoryAssociations ??
            const <PendingLocalHistoryAssociation>[]) {
      _localHistory.restorePendingIdentityPromotion(
        LocalHistoryPendingIdentityPromotion(
          bufferId: association.bufferId,
          documentId: association.documentId,
          destinationPath: association.destinationPath,
          displayName: association.displayName,
        ),
      );
    }
    await _localHistory.flushPendingIdentityPromotions();
    // Entries are authoritative even if the last shutdown was marked clean.
    // This protects users when close confirmation is disabled while dirty
    // buffers still exist.
    final recoverEntries = recovery.entries;
    if (session == null && recoverEntries.isEmpty) {
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
        session?.workspacePath ??
        recoverEntries
            .map((entry) => entry.workspacePath)
            .whereType<String>()
            .firstOrNull ??
        recoverEntries
            .map((entry) => entry.filePath)
            .whereType<String>()
            .firstOrNull;
    final sessionEntries = session?.tabs ?? const <DocumentSessionEntry>[];
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
      final recoveryById = {
        for (final entry in recoverEntries) entry.id: entry,
      };
      final recoveryByPath = {
        for (final entry in recoverEntries)
          if (entry.filePath != null) entry.filePath!: entry,
      };
      final buffers = <DocumentBuffer>[];
      for (final entry in sessionEntries) {
        final recovered =
            recoveryById[entry.id] ??
            (entry.filePath == null ? null : recoveryByPath[entry.filePath]);
        final buffer = await _restoreSessionBuffer(entry, recovered);
        if (buffer != null) {
          buffers.add(buffer);
        }
      }
      for (final recovered in recoverEntries) {
        if (buffers.any((buffer) => buffer.id == recovered.id)) {
          continue;
        }
        final buffer = await _restoreRecoveryBuffer(recovered);
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
      final reparsed = await _service.reparseActive(nextWorkspace, active.text);
      state = WorkspaceState(
        workspace: reparsed,
        preview: _safePreview(reparsed, active.text),
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
      for (final buffer in buffers) {
        unawaited(_localHistory.observeOpened(buffer));
      }
      _recordActivePreviewRevision();
      _editRevision = active.revision;
      await _startMonitoring(reparsed);
      await _settingsController.setDocumentViewMode(active.editorState.mode);
      _schedulePersistence();
      return true;
    } on Object catch (error, stackTrace) {
      busyMarkDebugLogError(
        '[BusyMark] Session restore failed',
        error,
        stackTrace,
      );
      return false;
    }
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
  }) async {
    final path = recovery.filePath;
    if (path == null) {
      return DocumentBuffer.untitled(
        id: recovery.id,
        name: recovery.untitledName ?? 'Untitled',
        text: recovery.text,
        mode: (editorState ?? recovery.editorState).mode,
      ).copyWith(
        editorState: editorState ?? recovery.editorState,
        format: recovery.format,
        revision: recovery.revision,
        recovered: true,
      );
    }
    if (!await _service.pathExists(path)) {
      return DocumentBuffer(
        id: recovery.id,
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
      id: recovery.id,
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
    if (_runningUnderFlutterTest) {
      unawaited(flushPersistence());
      return;
    }
    _persistenceDebounce = Timer(
      const Duration(milliseconds: 700),
      () => unawaited(flushPersistence()),
    );
  }

  Future<void> flushPersistence() {
    _persistenceDebounce?.cancel();
    final snapshot = state;
    final prior = _persistenceWrites.then<void>((_) {}, onError: (_, _) {});
    final write = prior.then((_) => _persistSnapshot(snapshot));
    _persistenceWrites = write;
    return write;
  }

  Future<void> _persistSnapshot(WorkspaceState snapshot) async {
    await _recoveryStart;
    final workspace = snapshot.workspace;
    final pendingHistoryAssociations = [
      for (final promotion in _localHistory.pendingIdentityPromotions)
        PendingLocalHistoryAssociation(
          bufferId: promotion.bufferId,
          documentId: promotion.documentId,
          destinationPath: promotion.destinationPath,
          displayName: promotion.displayName,
        ),
    ];
    if (workspace == null) {
      await _recoveryStore.writeEntries(const []);
      if (pendingHistoryAssociations.isEmpty) {
        await _sessionStore.clear();
      } else {
        await _sessionStore.save(
          WorkspaceSessionSnapshot(
            workspacePath: null,
            tabs: const [],
            activeBufferId: null,
            pendingLocalHistoryAssociations: pendingHistoryAssociations,
          ),
        );
      }
      return;
    }
    final workspacePath = switch (workspace.kind) {
      WorkspaceKind.untitledMarkdown => null,
      WorkspaceKind.singleMarkdown =>
        snapshot.documentBuffers
            .map((buffer) => buffer.filePath)
            .whereType<String>()
            .firstOrNull,
      WorkspaceKind.markdownFolder ||
      WorkspaceKind.writersideModule => workspace.rootPath,
    };
    await _recoveryStore.writeEntries([
      for (final buffer in snapshot.documentBuffers)
        if (buffer.isDirty || buffer.isUntitled)
          DocumentRecoveryEntry.fromBuffer(
            buffer,
            workspacePath: workspacePath,
          ),
    ]);
    await _sessionStore.save(
      WorkspaceSessionSnapshot(
        workspacePath: workspacePath,
        activeBufferId: snapshot.activeBufferId,
        tabs: [
          for (final buffer in snapshot.documentBuffers)
            DocumentSessionEntry(
              id: buffer.id,
              filePath: buffer.filePath,
              untitledName: buffer.untitledName,
              editorState: buffer.editorState,
            ),
        ],
        pendingLocalHistoryAssociations: pendingHistoryAssociations,
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
    await _recoveryStore.markCleanShutdown();
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
    if (workspace.kind == WorkspaceKind.untitledMarkdown ||
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
  }

  Future<void> _handleFileMonitorEvent(WorkspaceFileMonitorEvent event) async {
    if (!ref.mounted) return;
    final matching = state.documentBuffers.where((buffer) {
      final path = buffer.filePath;
      return path != null &&
          (p.equals(path, event.path) ||
              (event.destinationPath != null &&
                  p.equals(path, event.destinationPath!)));
    }).toList();
    for (final buffer in matching) {
      await _applyExternalFileState(buffer, event);
      if (!ref.mounted) return;
    }
    final workspaceRoot = state.workspace?.rootPath;
    if (workspaceRoot == null ||
        (!p.equals(workspaceRoot, event.path) &&
            !p.isWithin(workspaceRoot, event.path))) {
      return;
    }
    _scheduleMonitoredWorkspaceRefresh();
  }

  void _scheduleMonitoredWorkspaceRefresh() {
    _workspaceRefreshDebounce?.cancel();
    _workspaceRefreshDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!ref.mounted) return;
      // Our own filesystem writes also emit notifications. A background
      // refresh must not invalidate an operation already loading its result.
      if (state.isLoading) {
        _scheduleMonitoredWorkspaceRefresh();
        return;
      }
      unawaited(refreshWorkspaceFromDiskPreservingOpenTabs());
    });
  }

  Future<void> _applyExternalFileState(
    DocumentBuffer original,
    WorkspaceFileMonitorEvent event,
  ) async {
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
      await _applyExternalMove(current, destinationPath);
      return;
    }
    if (event.kind == WorkspaceFileEventKind.deleted &&
        !await _service.pathExists(path)) {
      var latest = _externalOperationBuffer(current, path);
      if (latest == null) return;
      await _localHistory.captureBeforeLoss(
        LocalHistoryBufferSnapshot.fromBuffer(latest),
        LocalHistoryCaptureReason.beforeDelete,
      );
      latest = _externalOperationBuffer(current, path);
      if (latest == null) return;
      await _localHistory.markDeleted(path, recursive: false);
      latest = _externalOperationBuffer(current, path);
      if (latest == null) return;
      _updateBufferFromMonitor(
        latest.copyWith(diskState: DocumentDiskState.deleted),
      );
      return;
    }
    try {
      final disk = await _service.loadTextWithSnapshot(path);
      var latest = _externalOperationBuffer(current, path);
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
      latest = _externalOperationBuffer(current, path);
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
      _updateBufferFromMonitor(reloaded);
      if (state.activeBufferId == reloaded.id && state.workspace != null) {
        final workspace = state.workspace!.copyWith(
          activeFileSnapshot: disk.snapshot,
        );
        final reparsed = await _service.reparseActive(workspace, disk.text);
        if (state.activeBufferId == reloaded.id &&
            state.activeBuffer?.revision == reloaded.revision) {
          state = state.copyWith(
            workspace: reparsed,
            preview: _safePreview(reparsed, disk.text),
          );
          _recordActivePreviewRevision();
        }
      }
    } on FileSystemException {
      final latest = _externalOperationBuffer(current, path);
      if (latest == null) return;
      await _localHistory.markDeleted(path, recursive: false);
      final afterHistory = _externalOperationBuffer(current, path);
      if (afterHistory == null) return;
      _updateBufferFromMonitor(
        afterHistory.copyWith(diskState: DocumentDiskState.deleted),
      );
    } on FormatException {
      // Invalid UTF-8 remains on disk and must not replace an editable buffer.
    }
  }

  DocumentBuffer? _externalOperationBuffer(
    DocumentBuffer anchor,
    String expectedPath,
  ) {
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

  Future<void> _applyExternalMove(
    DocumentBuffer current,
    String destinationPath,
  ) async {
    final oldPath = current.filePath;
    if (oldPath == null) {
      return;
    }
    final historyTransition = _localHistory.beginBufferPathTransition(
      bufferId: current.id,
      sourcePath: oldPath,
      destinationPath: destinationPath,
    );
    var historyPathCommitted = false;
    var historyTransitionFinished = false;
    try {
      final disk = await _service.loadTextWithSnapshot(destinationPath);
      if (_externalOperationBuffer(current, oldPath) == null) return;
      final contentChanged = !_sameFileSnapshot(
        current.diskSnapshot,
        disk.snapshot,
      );
      await _localHistory.remapPath(oldPath, destinationPath);
      if (_externalOperationBuffer(current, oldPath) == null) return;
      if (contentChanged) {
        await _localHistory.capturePath(
          path: destinationPath,
          text: disk.text,
          format: disk.format,
          reason: LocalHistoryCaptureReason.externalChange,
        );
      }
      final latest = _externalOperationBuffer(current, oldPath);
      if (latest == null) return;
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
      await _localHistory.finishBufferPathTransition(
        historyTransition,
        committed: true,
      );
      historyTransitionFinished = true;
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
        final reparsed = await _service.reparseActive(
          derivedWorkspace,
          remapped.text,
        );
        if (_canPublishActiveDerivedContent(
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
            preview: _safePreview(reparsed, remapped.text),
          );
          _recordActivePreviewRevision();
        }
      }
      _schedulePersistence();
    } on FileSystemException {
      final latest = _externalOperationBuffer(current, oldPath);
      if (latest != null) {
        _updateBufferFromMonitor(
          latest.copyWith(diskState: DocumentDiskState.deleted),
        );
      }
    } on FormatException {
      // Keep the old buffer and path when the move target cannot be decoded.
    } finally {
      if (!historyTransitionFinished) {
        await _localHistory.finishBufferPathTransition(
          historyTransition,
          committed: historyPathCommitted,
        );
      }
    }
  }

  void _updateBufferFromMonitor(DocumentBuffer buffer) {
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
      final workspace = await _service.reparseActive(
        derivedWorkspace.copyWith(activeFileSnapshot: disk.snapshot),
        disk.text,
      );
      if (_canPublishActiveDerivedContent(
        operationRevision: derivedOperationRevision,
        workspaceId: derivedWorkspace.id,
        bufferId: reloaded.id,
        path: path,
        revision: reloaded.revision,
        source: reloaded.text,
      )) {
        state = state.copyWith(
          workspace: workspace,
          preview: _safePreview(workspace, disk.text),
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
    return workspace != null && state.activeBuffer?.filePath == null;
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
          activeFilePath: target.path,
        ) &&
        workspace != null &&
        state.activeBuffer?.id == target.bufferId &&
        state.activeBuffer?.revision == target.editRevision &&
        state.activeBuffer?.text == target.text &&
        _sameFileSnapshot(state.activeBuffer?.diskSnapshot, target.snapshot);
  }

  Future<void> createMarkdownFile() async {
    _cancelPendingDerivedRefresh();
    _invalidateActiveDocumentOperations();
    _resetSaveTracking(dirty: true);
    final viewModeChange = _showEditorForNewFile();
    final currentWorkspace = state.workspace;
    final untitledWorkspace = _service.createUntitledMarkdown();
    final workspace = currentWorkspace == null
        ? untitledWorkspace
        : currentWorkspace.copyWith(
            activeFilePath: null,
            activeFileSnapshot: null,
            markdown: untitledWorkspace.markdown,
          );
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
    state = WorkspaceState(
      workspace: workspace,
      preview: _safePreview(workspace, ''),
      documentBuffers: [...state.documentBuffers, buffer],
      activeBufferId: buffer.id,
      isLoading: false,
    );
    unawaited(_localHistory.observeOpened(buffer));
    _recordActivePreviewRevision();
    await _startMonitoring(workspace);
    _schedulePersistence();
    await viewModeChange;
  }

  Future<void> openPath(String path) async {
    await _localHistory.flushAll(state.documentBuffers);
    _cancelPendingDerivedRefresh();
    _cancelAllAutoSaves();
    final operationRevision = _invalidateActiveDocumentOperations();
    _resetSaveTracking();
    state = const WorkspaceState(isLoading: true);
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
      final preview = _safePreview(loadedWorkspace, text);
      if (!_isCurrentActiveDocumentOperation(operationRevision)) {
        return;
      }
      final buffer = load == null || active == null
          ? null
          : _fileBuffer(
              active,
              load,
              mode: _settingsController.state.documentViewMode,
            );
      state = WorkspaceState(
        workspace: loadedWorkspace,
        activeText: text,
        preview: preview,
        documentBuffers: buffer == null ? const [] : [buffer],
        activeBufferId: buffer?.id,
      );
      if (buffer != null) unawaited(_localHistory.observeOpened(buffer));
      _recordActivePreviewRevision();
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
    await _localHistory.flushAll(state.documentBuffers);
    _cancelPendingDerivedRefresh();
    _cancelAllAutoSaves();
    final operationRevision = _invalidateActiveDocumentOperations();
    _resetSaveTracking();
    state = const WorkspaceState(isLoading: true);
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
      final preview = _safePreview(loadedWorkspace, text);
      if (!_isCurrentActiveDocumentOperation(operationRevision)) {
        return false;
      }
      final buffer = load == null || active == null
          ? null
          : _fileBuffer(
              active,
              load,
              mode: _settingsController.state.documentViewMode,
            );
      state = WorkspaceState(
        workspace: loadedWorkspace,
        activeText: text,
        preview: preview,
        documentBuffers: buffer == null ? const [] : [buffer],
        activeBufferId: buffer?.id,
      );
      if (buffer != null) unawaited(_localHistory.observeOpened(buffer));
      _recordActivePreviewRevision();
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
  }) async {
    final workspace = state.workspace;
    if (workspace == null) {
      return false;
    }
    _cancelPendingDerivedRefresh();
    _cancelAllAutoSaves();
    final operationRevision = _invalidateActiveDocumentOperations();
    _resetSaveTracking();
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      final nextWorkspace = await _service.createWritersideTopic(
        workspace,
        request,
        instanceTreePath: instanceTreePath,
      );
      final active = nextWorkspace.activeFilePath;
      final load = active == null
          ? null
          : await _service.loadTextWithSnapshot(active);
      final text = load?.text ?? '';
      final loadedWorkspace = load == null
          ? nextWorkspace
          : nextWorkspace.copyWith(activeFileSnapshot: load.snapshot);
      final openFilePaths = _retainedOpenFileTabPaths(
        current: workspace,
        refreshed: loadedWorkspace,
        activeFilePath: active,
      );
      final tabbedWorkspace = loadedWorkspace.copyWith(
        openFilePaths: openFilePaths,
      );
      if (!_isCurrentActiveDocumentOperation(operationRevision)) {
        return false;
      }
      final existing = active == null ? null : state.bufferForPath(active);
      final buffer =
          existing ??
          (load == null || active == null
              ? null
              : _fileBuffer(
                  active,
                  load,
                  mode: _settingsController.state.documentViewMode,
                ));
      final buffers = buffer == null
          ? state.documentBuffers
          : existing != null
          ? state.documentBuffers
          : [...state.documentBuffers, buffer];
      state = WorkspaceState(
        workspace: tabbedWorkspace,
        activeText: text,
        preview: _safePreview(tabbedWorkspace, text),
        documentBuffers: buffers,
        activeBufferId: buffer?.id,
      );
      if (buffer != null && existing == null) {
        unawaited(_localHistory.observeOpened(buffer));
      }
      _recordActivePreviewRevision();
      await _startMonitoring(tabbedWorkspace);
      _schedulePersistence();
      _resetSaveTracking();
      return true;
    } on Object catch (error, stackTrace) {
      busyMarkDebugLogError(
        '[BusyMark] Create Writerside topic failed',
        error,
        stackTrace,
        context: {'title': request.title, 'file name': request.fileName},
      );
      if (_isCurrentActiveDocumentOperation(operationRevision)) {
        state = state.copyWith(
          isLoading: false,
          message: WorkspaceMessage(
            WorkspaceMessageCode.createWritersideTopicFailed,
            error: error,
          ),
        );
      }
      return false;
    }
  }

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
    _clearOpenFileTabs(workspace);
    for (final buffer in closingBuffers) {
      _localHistory.handleBufferClosed(
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
      final target = await _service.renameEntity(workspace, path, newName);
      final transitions = _beginLocalHistoryPathTransitions(path, target);
      var committed = false;
      try {
        await _localHistory.remapPath(path, target);
        _remapOpenWorkspacePaths(workspace, path, target);
        committed = true;
        return _remapMovedPath(activeFilePath, path, target);
      } finally {
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
      final target = await _service.moveEntity(
        workspace,
        sourcePath,
        targetDirectoryPath,
      );
      final transitions = _beginLocalHistoryPathTransitions(sourcePath, target);
      var committed = false;
      try {
        await _localHistory.remapPath(sourcePath, target);
        _remapOpenWorkspacePaths(workspace, sourcePath, target);
        committed = true;
        return _remapMovedPath(activeFilePath, sourcePath, target);
      } finally {
        await _finishLocalHistoryPathTransitions(
          transitions,
          committed: committed,
        );
      }
    });
  }

  Future<bool> deleteWorkspaceEntity(String path) async {
    if (!await _protectWorkspaceEntityBeforeDelete(path)) return false;
    _intentionallyRemovedPaths.add(p.normalize(path));
    try {
      final deleted = await _runWorkspaceFileOperation((workspace) async {
        await _service.deleteEntity(workspace, path);
        return null;
      });
      if (deleted) {
        await _localHistory.markDeleted(path, recursive: true);
      }
      return deleted;
    } finally {
      _intentionallyRemovedPaths.remove(p.normalize(path));
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
        if (!await _localHistory.capturePath(
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
      await _service.moveWritersideTocEntry(
        workspace,
        treePath: treePath,
        sourcePath: sourcePath,
        placement: placement,
        referencePath: referencePath,
        sourceIdentity: sourceIdentity,
        referenceIdentity: referenceIdentity,
      );
      return null;
    });
  }

  Future<bool> moveWritersideTocEntries({
    required String treePath,
    required List<WritersideTocMoveEntry> sources,
    required WritersideTopicCreatePlacement placement,
    required List<int>? referencePath,
    WritersideTocNodeIdentity? referenceIdentity,
  }) {
    return _runWorkspaceFileOperation((workspace) async {
      await _service.moveWritersideTocEntries(
        workspace,
        treePath: treePath,
        sources: sources,
        placement: placement,
        referencePath: referencePath,
        referenceIdentity: referenceIdentity,
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
      await _service.removeWritersideTocEntry(
        workspace,
        treePath: treePath,
        nodePath: nodePath,
        expectedIdentity: expectedIdentity,
      );
      return null;
    });
  }

  Future<bool> removeWritersideTocEntries({
    required String treePath,
    required List<WritersideTocRemovalRequest> requests,
  }) {
    return _runWorkspaceFileOperation((workspace) async {
      await _service.removeWritersideTocEntries(
        workspace,
        treePath: treePath,
        requests: requests,
      );
      return null;
    });
  }

  Future<bool> renameWritersideTopicFile(String topicPath, String newFileName) {
    final activeFilePath = state.workspace?.activeFilePath;
    return _runWorkspaceFileOperation((workspace) async {
      final target = await _service.renameWritersideTopicFile(
        workspace,
        topicPath,
        newFileName,
      );
      final transitions = _beginLocalHistoryPathTransitions(topicPath, target);
      var committed = false;
      try {
        await _localHistory.remapPath(topicPath, target);
        _remapOpenWorkspacePaths(workspace, topicPath, target);
        committed = true;
        return _remapMovedPath(activeFilePath, topicPath, target);
      } finally {
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
    final workspace = state.workspace;
    if (workspace == null) {
      return null;
    }
    try {
      final result = await _service.applyWritersideTopicRemoval(
        workspace,
        request,
      );
      if (!await refreshWorkspaceFromDiskPreservingOpenTabs()) {
        return null;
      }
      return result;
    } on Object catch (error, stackTrace) {
      busyMarkDebugLogError(
        '[BusyMark] Writerside topic removal failed',
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
        _clearOpenFileTabs(closingWorkspace);
        if (closingBuffer != null) {
          _localHistory.handleBufferClosed(
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
          _localHistory.handleBufferClosed(
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
        _localHistory.handleBufferClosed(
          closingBuffer.id,
          historySettled: historySettled,
        );
      }
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
      _localHistory.handleBufferClosed(
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
    _cancelAutoSave(bufferId);
    return _enqueueBufferWrite(
      bufferId,
      () => _closeDocumentBufferNow(bufferId, discard: discard),
    );
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
      if (afterProtection != null) _scheduleAutoSave(afterProtection.id);
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
      if (current != null) _scheduleAutoSave(current.id);
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
      state = const WorkspaceState();
      _fileMonitor.updateOpenFilePaths(const <String>[]);
      _schedulePersistence();
      _localHistory.handleBufferClosed(
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
      _localHistory.handleBufferClosed(
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

  void _clearOpenFileTabs(Workspace workspace) {
    if (!_supportsOpenFileTabs(workspace)) {
      return;
    }
    _cancelPendingDerivedRefresh();
    _cancelAllAutoSaves();
    _invalidateActiveDocumentOperations();
    _resetSaveTracking();
    final List<Diagnostic> diagnostics = switch (workspace.kind) {
      WorkspaceKind.writersideModule =>
        workspace.writersideModule?.diagnostics ?? const [],
      WorkspaceKind.untitledMarkdown ||
      WorkspaceKind.singleMarkdown ||
      WorkspaceKind.markdownFolder => const [],
    };
    state = state.copyWith(
      workspace: workspace.copyWith(
        activeFilePath: null,
        activeFileModifiedAt: null,
        activeFileSnapshot: null,
        openFilePaths: const [],
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
      final reparsed = await _service.reparseActive(nextWorkspace, load.text);
      if (!_isCurrentActiveDocumentOperation(operationRevision) ||
          state.workspace?.id != workspaceId) {
        return false;
      }
      final buffer = _fileBuffer(
        path,
        load,
        mode: _settingsController.state.documentViewMode,
      );
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
      final publishedWorkspace = reparsed.copyWith(
        openFilePaths: reconciledOpenPaths,
      );
      state = state.copyWith(
        workspace: publishedWorkspace,
        activeText: load.text,
        preview: _safePreview(publishedWorkspace, load.text),
        documentBuffers: reconciledBuffers,
        activeBufferId: buffer.id,
        clearMessage: true,
      );
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
      markdown: buffer.filePath == null ? workspace.markdown : null,
    );
    var parsedBuffer = buffer;
    var reparsed = await _service.reparseActive(
      nextWorkspace,
      parsedBuffer.text,
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
        liveBuffer.text != parsedBuffer.text) {
      parsedBuffer = liveBuffer;
      reparsed = await _service.reparseActive(nextWorkspace, parsedBuffer.text);
      if (!_isCurrentActiveDocumentOperation(operationRevision) ||
          state.workspace?.id != workspaceId) {
        return false;
      }
      liveBuffer = state.documentBuffers
          .where((candidate) => candidate.id == targetBufferId)
          .firstOrNull;
      if (liveBuffer == null) return false;
    }
    final sourceStayedCurrent =
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
    final publishedWorkspace = (sourceStayedCurrent ? reparsed : nextWorkspace)
        .copyWith(
          activeFilePath: liveBuffer.filePath,
          activeFileSnapshot: liveBuffer.diskSnapshot,
          openFilePaths: reconciledOpenPaths,
        );
    state = state.copyWith(
      workspace: publishedWorkspace,
      preview: sourceStayedCurrent
          ? _safePreview(publishedWorkspace, liveBuffer.text)
          : null,
      documentBuffers: reconciledBuffers,
      activeBufferId: liveBuffer.id,
      clearMessage: true,
    );
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
    if (buffer == null) {
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
    if (buffer == null || buffer.editorState.undoState.undo.isEmpty) {
      return false;
    }
    final undo = buffer.editorState.undoState;
    final target = undo.undo.last;
    final current = DocumentHistoryState(
      text: buffer.text,
      selection: buffer.editorState.selection,
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
    if (buffer == null || buffer.editorState.undoState.redo.isEmpty) {
      return false;
    }
    final undo = buffer.editorState.undoState;
    final target = undo.redo.last;
    final current = DocumentHistoryState(
      text: buffer.text,
      selection: buffer.editorState.selection,
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

  void updateActiveText(String text, {String? sourceFilePath}) {
    _updateActiveText(
      text,
      sourceFilePath: sourceFilePath,
      rebuildPreview:
          state.activeBuffer?.editorState.mode !=
          DocumentViewModePreference.source,
    );
  }

  void updateActiveSourceText(
    String text, {
    String? sourceFilePath,
    required TextSelection previousSelection,
    required TextSelection selection,
    String? undoGroup,
  }) {
    _updateActiveText(
      text,
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
    String? sourceFilePath,
    String? undoGroup,
  }) {
    _updateActiveText(
      text,
      sourceFilePath: sourceFilePath,
      rebuildPreview: false,
      liveOutline: document.outline,
      preserveFinalNewline: true,
      undoGroup: undoGroup,
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
      final reparsed = await _service.reparseActive(nextWorkspace, load.text);
      if (!_isCurrentActiveDocumentOperation(operationRevision)) {
        return false;
      }
      final buffer = _fileBuffer(
        path,
        load,
        mode: _settingsController.state.documentViewMode,
      );
      final buffers = [...state.documentBuffers, buffer];
      state = state.copyWith(
        workspace: reparsed,
        preview: _safePreview(reparsed, load.text),
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
    String? sourceFilePath,
    List<DocumentOutlineHeading>? liveOutline,
    bool preserveFinalNewline = false,
    TextSelection? previousSelection,
    TextSelection? selection,
    String? undoGroup,
  }) {
    final workspace = state.workspace;
    final activeEditorPath =
        workspace?.activeFilePath ?? workspace?.markdown?.filePath;
    if (sourceFilePath != null && activeEditorPath != sourceFilePath) {
      return;
    }
    final activeBuffer = state.activeBuffer;
    if (activeBuffer == null) {
      return;
    }
    final effectiveText = preserveFinalNewline
        ? _withFinalNewlinePolicy(text, activeBuffer.format.hasFinalNewline)
        : text;
    final nextBuffer = activeBuffer.edited(
      effectiveText,
      undoGroup: undoGroup,
      previousSelection: previousSelection,
      nextSelection: selection,
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
              filePath: workspace.activeFilePath,
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
    if (_derivedRefreshRunning) {
      return;
    }
    _derivedRefreshRunning = true;
    try {
      while (ref.mounted && _derivedRefreshPending) {
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
      if (ref.mounted && _derivedRefreshPending) {
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
      final overlaid = await _service.withWritersideSources(workspace, {
        for (final buffer in state.documentBuffers)
          if (buffer.filePath != null &&
              buffer.filePath != workspace.activeFilePath &&
              buffer.dirty)
            buffer.filePath!: buffer.text,
      });
      final reparsed = await _service.reparseActive(overlaid, text);
      if (!_isCurrentActiveDocument(
            operationRevision,
            workspaceId: workspaceId,
            activeFilePath: activeFilePath,
          ) ||
          state.activeBuffer?.id != bufferId ||
          state.activeText != text ||
          state.activeBuffer?.revision != editRevision) {
        return;
      }
      state = state.copyWith(
        liveOutline: ActiveDocumentOutline(
          workspaceId: workspaceId,
          filePath: activeFilePath,
          source: text,
          headings: _service.activeDocumentOutline(reparsed),
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
    if (workspace == null) {
      return;
    }
    final workspaceId = workspace.id;
    final activeFilePath = workspace.activeFilePath;
    final text = state.activeText;
    final editRevision = state.activeBuffer?.revision ?? _editRevision;
    final operationRevision = _activeDocumentRevision;
    try {
      final overlaid = await _service.withWritersideSources(workspace, {
        for (final buffer in state.documentBuffers)
          if (buffer.filePath != null &&
              buffer.filePath != workspace.activeFilePath &&
              buffer.dirty)
            buffer.filePath!: buffer.text,
      });
      final reparsed = await _service.reparseActive(overlaid, text);
      final preview = await _service.buildPreviewAsync(reparsed, text);
      if (!_isCurrentActiveDocument(
            operationRevision,
            workspaceId: workspaceId,
            activeFilePath: activeFilePath,
          ) ||
          state.activeText != text ||
          state.activeBuffer?.revision != editRevision) {
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
    }
    if (!_isBufferSaveTargetCurrent(target)) {
      return false;
    }
    try {
      final snapshot = await _service.saveText(
        active,
        target.format.formattedText(
          target.text,
          mixedNormalization: mixedLineEndingNormalization,
        ),
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
      if (_workspaceContainsBuffer(target.workspaceId, target.bufferId)) {
        state = state.copyWith(
          message: WorkspaceMessage(
            WorkspaceMessageCode.saveFailed,
            error: error,
          ),
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
    try {
      final overlaid = await _service.withWritersideSources(workspace, {
        for (final buffer in state.documentBuffers)
          if (buffer.filePath != null &&
              buffer.filePath != workspace.activeFilePath &&
              buffer.dirty)
            buffer.filePath!: buffer.text,
      });
      final reparsed = await _service.reparseActive(overlaid, text);
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
          !_sameFileSnapshot(currentBuffer.diskSnapshot, snapshot)) {
        return;
      }
      final nextWorkspace = reparsed.copyWith(
        activeFileSnapshot: snapshot,
        openFilePaths: currentWorkspace.openFilePaths,
        files: currentWorkspace.files,
      );
      state = state.copyWith(
        workspace: nextWorkspace,
        preview: _safePreview(nextWorkspace, text),
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
    Map<String, LineEndingNormalization> mixedLineEndingNormalizations =
        const {},
  }) async {
    _cancelAllAutoSaves();
    final saved = <String>[];
    final failed = <String>[];
    final conflicts = <String>[];
    final normalizationRequired = <String>[];
    final targets = [
      for (final buffer in state.documentBuffers)
        if (buffer.isDirty && buffer.filePath != null) buffer,
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

  Future<bool> _saveActiveAsNow(
    String path, {
    required ActiveDocumentSaveTarget target,
    required bool overwriteExisting,
    required LineEndingNormalization? mixedLineEndingNormalization,
  }) async {
    LocalHistoryBufferPathTransition? historyTransition = _localHistory
        .beginBufferPathTransition(
          bufferId: target.bufferId,
          sourcePath: target.path,
          destinationPath: path,
          kind: LocalHistoryBufferPathTransitionKind.saveAs,
        );
    var historyPathCommitted = false;
    try {
      final destinationExisted =
          overwriteExisting && await _service.pathExists(path);
      if (destinationExisted) {
        try {
          final destination = await _service.loadTextWithSnapshot(path);
          if (!await _localHistory.capturePathBeforeLoss(
            path: path,
            text: destination.text,
            format: destination.format,
            reason: LocalHistoryCaptureReason.beforeDiscard,
          )) {
            return false;
          }
        } on Object {
          // The save result remains truthful. Local History exposes its own
          // persistent status warning when capture fails.
        }
      }
      late final WorkspaceFileSnapshot savedSnapshot;
      if (overwriteExisting) {
        savedSnapshot = await _service.saveTextReplacingPath(
          path,
          target.format.formattedText(
            target.text,
            mixedNormalization: mixedLineEndingNormalization,
          ),
        );
      } else {
        savedSnapshot = await _service.saveNewText(
          path,
          target.format.formattedText(
            target.text,
            mixedNormalization: mixedLineEndingNormalization,
          ),
        );
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
      final hasNewerEdits =
          currentBuffer.revision != target.editRevision ||
          currentBuffer.text != target.text;
      final savedFormat =
          target.format.hasMixedLineEndings &&
              mixedLineEndingNormalization != null
          ? target.format.normalized(mixedLineEndingNormalization)
          : target.format;
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
      historyPathCommitted = true;
      await _localHistory.captureSavedAs(
        LocalHistoryBufferSnapshot(
          bufferId: target.bufferId,
          displayName: target.path == null
              ? state.documentBuffers
                        .where((buffer) => buffer.id == target.bufferId)
                        .firstOrNull
                        ?.displayName ??
                    p.basename(path)
              : p.basename(target.path!),
          text: target.text,
          format: savedFormat,
          revision: target.editRevision,
          path: target.path,
          untitled: target.path == null,
        ),
        path,
        destinationExisted: destinationExisted,
      );
      await _localHistory.finishBufferPathTransition(
        historyTransition,
        committed: true,
      );
      historyTransition = null;
      await _startMonitoring(savedWorkspace);
      if (hasNewerEdits) {
        if (state.activeBufferId == savedBuffer.id &&
            _settingsController.state.validateOnEdit) {
          unawaited(_validateActive(rebuildPreview: _activeModeShowsPreview));
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
      if (_workspaceContainsBuffer(target.workspaceId, target.bufferId)) {
        state = state.copyWith(
          message: WorkspaceMessage(
            WorkspaceMessageCode.saveFailed,
            error: error,
          ),
        );
      }
      return false;
    } finally {
      final unfinishedTransition = historyTransition;
      if (unfinishedTransition != null) {
        await _localHistory.finishBufferPathTransition(
          unfinishedTransition,
          committed: historyPathCommitted,
        );
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

  Future<bool> restoreLocalHistoryRevision({
    required LocalHistoryDocument document,
    required LocalHistoryRevision revision,
    SourceComparison? comparison,
    SourceComparisonChange? change,
  }) async {
    if (revision.summary.documentId != document.id) return false;
    final path = document.currentPath ?? revision.summary.historicalPath;
    var buffer = localHistoryBufferForDocument(document, revision);
    if (buffer == null && path != null && await _service.pathExists(path)) {
      if (!await _openActiveFile(path)) return false;
      buffer = state.activeBuffer;
    } else if (buffer != null && state.activeBufferId != buffer.id) {
      if (!await activateDocumentBuffer(buffer.id)) return false;
      buffer = state.activeBuffer;
    }
    if (buffer == null) return false;
    final targetId = buffer.id;
    final targetPath = buffer.filePath;
    final targetRevision = buffer.revision;
    final targetText = buffer.text;
    final nextText = change == null
        ? revision.source
        : _restoredRegionText(
            buffer: buffer,
            revision: revision,
            comparison: comparison,
            change: change,
          );
    if (nextText == null || nextText == targetText) return nextText != null;
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
        canRestore: true,
      );
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
    final refreshRevision = ++_workspaceRefreshRevision;
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
        if (_intentionallyRemovedPaths.any(
          (removed) => p.equals(path, removed) || p.isWithin(removed, path),
        )) {
          continue;
        }
        final exists = workspace.kind == WorkspaceKind.singleMarkdown
            ? await _service.pathExists(path)
            : existingFiles.containsKey(path);
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
      );
      if (finalTarget != parseTarget) {
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
        );
      }
      final tabPaths = _refreshTabPaths(buffers);
      if (finalTarget == parseTarget) {
        final publishedWorkspace = reparsed.copyWith(
          activeFilePath: activeBuffer?.filePath,
          activeFileSnapshot: activeBuffer?.diskSnapshot,
          openFilePaths: tabPaths,
        );
        state = state.copyWith(
          workspace: publishedWorkspace,
          preview: activeBuffer == null
              ? null
              : _safePreview(publishedWorkspace, activeBuffer.text),
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

  List<DocumentBuffer> _workspaceRefreshLiveBuffers() => [
    for (final buffer in state.documentBuffers)
      if (buffer.filePath == null ||
          !_intentionallyRemovedPaths.any(
            (removed) =>
                p.equals(buffer.filePath!, removed) ||
                p.isWithin(removed, buffer.filePath!),
          ))
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
  ) {
    final nextWorkspace = refreshedWorkspace.copyWith(
      activeFilePath: activeBuffer?.filePath,
      activeFileSnapshot: activeBuffer?.diskSnapshot,
      openFilePaths: _refreshTabPaths(buffers),
    );
    return activeBuffer == null
        ? Future.value(nextWorkspace.copyWith(markdown: null))
        : _service.reparseActive(nextWorkspace, activeBuffer.text);
  }

  Future<bool> _runWorkspaceFileOperation(
    Future<String?> Function(Workspace workspace) operation,
  ) async {
    final workspace = state.workspace;
    if (workspace == null) {
      return false;
    }
    try {
      final preferredActivePath = await operation(workspace);
      final refreshed = await refreshWorkspaceFromDiskPreservingOpenTabs();
      if (!refreshed) {
        return false;
      }
      if (preferredActivePath != null) {
        return await _openActiveFile(preferredActivePath);
      }
      return true;
    } on Object catch (error, stackTrace) {
      busyMarkDebugLogError(
        '[BusyMark] Workspace file operation failed',
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
      return false;
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

  Future<void> validateActive() => _validateActive(rebuildPreview: true);

  Future<void> _validateActive({required bool rebuildPreview}) async {
    final workspace = state.workspace;
    if (workspace == null) {
      return;
    }
    final workspaceId = workspace.id;
    final activeFilePath = workspace.activeFilePath;
    final text = state.activeText;
    final editRevision = state.activeBuffer?.revision ?? _editRevision;
    final operationRevision = _activeDocumentRevision;
    try {
      final overlaid = await _service.withWritersideSources(workspace, {
        for (final buffer in state.documentBuffers)
          if (buffer.filePath != null &&
              buffer.filePath != workspace.activeFilePath &&
              buffer.dirty)
            buffer.filePath!: buffer.text,
      });
      final reparsed = await _service.reparseActive(overlaid, text);
      final currentWorkspace = state.workspace;
      if (!_isCurrentActiveDocument(
            operationRevision,
            workspaceId: workspaceId,
            activeFilePath: activeFilePath,
          ) ||
          currentWorkspace == null ||
          state.activeText != text ||
          state.activeBuffer?.revision != editRevision) {
        return;
      }
      final currentSnapshot = currentWorkspace.activeFileSnapshot;
      final validatedWorkspace = reparsed.copyWith(
        activeFileSnapshot: currentSnapshot,
        openFilePaths: currentWorkspace.openFilePaths,
        files: currentWorkspace.files,
      );
      if (rebuildPreview) {
        state = state.copyWith(
          workspace: validatedWorkspace,
          preview: _safePreview(reparsed, text),
          clearMessage: true,
        );
        _recordActivePreviewRevision();
      } else {
        state = state.copyWith(
          workspace: validatedWorkspace,
          liveOutline: ActiveDocumentOutline(
            workspaceId: validatedWorkspace.id,
            filePath: validatedWorkspace.activeFilePath,
            source: text,
            headings: _service.activeDocumentOutline(validatedWorkspace),
          ),
          clearMessage: true,
        );
      }
    } on Object catch (error) {
      if (_isCurrentActiveDocument(
            operationRevision,
            workspaceId: workspaceId,
            activeFilePath: activeFilePath,
          ) &&
          state.activeText == text &&
          state.activeBuffer?.revision == editRevision) {
        state = state.copyWith(
          message: WorkspaceMessage(
            WorkspaceMessageCode.validationFailed,
            error: error,
          ),
        );
      }
    }
  }

  PreviewDocument? _safePreview(Workspace workspace, String text) {
    try {
      return _service.buildPreview(workspace, text);
    } on Object {
      return PreviewDocument(
        title: '',
        modeLabel: '',
        compatibility: '',
        blocks: [PreviewBlock(kind: PreviewBlockKind.code, text: text)],
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
        buffer.filePath != null &&
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
    required String? activeFilePath,
  }) {
    if (!ref.mounted) return false;
    final workspace = state.workspace;
    return operationRevision == _activeDocumentRevision &&
        workspace != null &&
        workspace.id == workspaceId &&
        workspace.activeFilePath == activeFilePath;
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
  });

  final String? bufferId;
  final String? path;
  final int? revision;
  final String text;

  @override
  bool operator ==(Object other) =>
      other is _WorkspaceRefreshParseTarget &&
      other.bufferId == bufferId &&
      other.path == path &&
      other.revision == revision &&
      other.text == text;

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
    WorkspaceKind.untitledMarkdown => false,
  };
}

List<String> _retainedOpenFileTabPaths({
  required Workspace current,
  required Workspace refreshed,
  required String? activeFilePath,
}) {
  final availablePaths = {
    for (final file in refreshed.files) file.absolutePath,
  };
  final retained = [
    for (final path in current.openFilePaths)
      if (availablePaths.contains(path)) path,
  ];
  if (activeFilePath == null || retained.contains(activeFilePath)) {
    return retained;
  }
  return [...retained, activeFilePath];
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
