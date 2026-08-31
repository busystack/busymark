import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../app/app_settings.dart';
import '../core/debug_log.dart';
import '../core/diagnostic.dart';
import '../core/source_span.dart';
import '../markdown/busymark_document.dart';
import '../markdown/document_outline.dart';
import '../markdown/preview_model.dart';
import '../writerside/writerside_project_creator.dart';
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
  StreamSubscription<WorkspaceFileMonitorEvent>? _fileMonitorSubscription;
  final _autoSaveDebounces = <String, Timer>{};
  final _bufferWriteQueues = <String, Future<void>>{};
  Timer? _persistenceDebounce;
  Timer? _workspaceRefreshDebounce;
  var _derivedRefreshRunning = false;
  var _derivedRefreshPending = false;
  var _pendingPreviewRefresh = false;
  var _editRevision = 0;
  var _activeDocumentRevision = 0;
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
    return _fileBuffer(path, load).copyWith(editorState: session.editorState);
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
    if (workspace == null) {
      await _recoveryStore.writeEntries(const []);
      await _sessionStore.clear();
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
      ),
    );
  }

  Future<void> markCleanShutdown() async {
    await _settleWritesForShutdown();
    await flushPersistence();
    if (state.documentBuffers.any(
      (buffer) => buffer.isDirty || buffer.isUntitled,
    )) {
      // Keep the run unclean while recovery data is still needed.
      return;
    }
    await _recoveryStore.markCleanShutdown();
  }

  Future<void> discardRecoveryForShutdown() async {
    await _settleWritesForShutdown();
    await flushPersistence();
    await _recoveryStore.clear();
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
    final matching = state.documentBuffers.where((buffer) {
      final path = buffer.filePath;
      return path != null &&
          (p.equals(path, event.path) ||
              (event.destinationPath != null &&
                  p.equals(path, event.destinationPath!)));
    }).toList();
    for (final buffer in matching) {
      await _applyExternalFileState(buffer, event);
    }
    final workspaceRoot = state.workspace?.rootPath;
    if (workspaceRoot == null ||
        (!p.equals(workspaceRoot, event.path) &&
            !p.isWithin(workspaceRoot, event.path))) {
      return;
    }
    _workspaceRefreshDebounce?.cancel();
    _workspaceRefreshDebounce = Timer(
      const Duration(milliseconds: 250),
      () => unawaited(refreshWorkspaceFromDiskPreservingOpenTabs()),
    );
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
      _updateBufferFromMonitor(
        current.copyWith(diskState: DocumentDiskState.deleted),
      );
      return;
    }
    try {
      final disk = await _service.loadTextWithSnapshot(path);
      if (_sameFileSnapshot(current.diskSnapshot, disk.snapshot)) {
        return;
      }
      if (current.isDirty) {
        _updateBufferFromMonitor(
          current.copyWith(
            diskState: DocumentDiskState.conflict,
            diskVersionText: disk.text,
            diskVersionSnapshot: disk.snapshot,
          ),
        );
        return;
      }
      final reloaded = current.copyWith(
        text: disk.text,
        lastSavedText: disk.text,
        dirty: false,
        diskSnapshot: disk.snapshot,
        format: disk.format,
        revision: current.revision + 1,
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
        }
      }
    } on FileSystemException {
      _updateBufferFromMonitor(
        current.copyWith(diskState: DocumentDiskState.deleted),
      );
    } on FormatException {
      // Invalid UTF-8 remains on disk and must not replace an editable buffer.
    }
  }

  Future<void> _applyExternalMove(
    DocumentBuffer current,
    String destinationPath,
  ) async {
    final oldPath = current.filePath;
    if (oldPath == null) {
      return;
    }
    try {
      final disk = await _service.loadTextWithSnapshot(destinationPath);
      final contentChanged = !_sameFileSnapshot(
        current.diskSnapshot,
        disk.snapshot,
      );
      final remapped = current.copyWith(
        filePath: destinationPath,
        text: current.isDirty || !contentChanged ? current.text : disk.text,
        lastSavedText: contentChanged && !current.isDirty
            ? disk.text
            : current.lastSavedText,
        dirty: current.isDirty,
        diskSnapshot: contentChanged && !current.isDirty
            ? disk.snapshot
            : current.diskSnapshot,
        format: contentChanged && !current.isDirty
            ? disk.format
            : current.format,
        revision: contentChanged && !current.isDirty
            ? current.revision + 1
            : current.revision,
        diskState: current.isDirty && contentChanged
            ? DocumentDiskState.conflict
            : DocumentDiskState.present,
        diskVersionText: current.isDirty && contentChanged ? disk.text : null,
        diskVersionSnapshot: current.isDirty && contentChanged
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
      final active = state.activeBufferId == current.id;
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
      _fileMonitor.updateOpenFilePaths(
        state.documentBuffers
            .map((buffer) => buffer.filePath)
            .whereType<String>(),
      );
      if (active && state.workspace != null) {
        final reparsed = await _service.reparseActive(
          state.workspace!,
          remapped.text,
        );
        if (state.activeBufferId == current.id &&
            state.activeBuffer?.filePath == destinationPath) {
          state = state.copyWith(
            workspace: reparsed.copyWith(
              activeFileSnapshot: remapped.diskSnapshot,
              openFilePaths: remappedTabs,
            ),
            preview: _safePreview(reparsed, remapped.text),
          );
        }
      }
      _schedulePersistence();
    } on FileSystemException {
      _updateBufferFromMonitor(
        current.copyWith(diskState: DocumentDiskState.deleted),
      );
    } on FormatException {
      // Keep the old buffer and path when the move target cannot be decoded.
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
    final disk = await _service.loadTextWithSnapshot(path);
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
    if (state.activeBufferId == bufferId && state.workspace != null) {
      final workspace = await _service.reparseActive(
        state.workspace!.copyWith(activeFileSnapshot: disk.snapshot),
        disk.text,
      );
      state = state.copyWith(
        workspace: workspace,
        preview: _safePreview(workspace, disk.text),
      );
    }
    return true;
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
    await _startMonitoring(workspace);
    _schedulePersistence();
    await viewModeChange;
  }

  Future<void> openPath(String path) async {
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
    _clearOpenFileTabs(workspace);
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
      _remapOpenWorkspacePaths(workspace, path, target);
      return _remapMovedPath(activeFilePath, path, target);
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
      _remapOpenWorkspacePaths(workspace, sourcePath, target);
      return _remapMovedPath(activeFilePath, sourcePath, target);
    });
  }

  Future<bool> deleteWorkspaceEntity(String path) async {
    _intentionallyRemovedPaths.add(p.normalize(path));
    try {
      return await _runWorkspaceFileOperation((workspace) async {
        await _service.deleteEntity(workspace, path);
        return null;
      });
    } finally {
      _intentionallyRemovedPaths.remove(p.normalize(path));
    }
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
      _remapOpenWorkspacePaths(workspace, topicPath, target);
      return _remapMovedPath(activeFilePath, topicPath, target);
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

  Future<bool> closeOpenFileTab(String path) async {
    final workspace = state.workspace;
    if (workspace == null || !workspace.openFilePaths.contains(path)) {
      return false;
    }
    final closingBuffer = state.bufferForPath(path);
    if (closingBuffer?.isDirty == true) {
      return false;
    }
    final closedIndex = workspace.openFilePaths.indexOf(path);
    final nextOpenFilePaths = [
      for (final openPath in workspace.openFilePaths)
        if (openPath != path) openPath,
    ];
    final remainingBuffers = [
      for (final buffer in state.documentBuffers)
        if (buffer.filePath != path) buffer,
    ];
    if (nextOpenFilePaths.isEmpty) {
      final nextUntitled = remainingBuffers.firstOrNull;
      if (nextUntitled == null) {
        _clearOpenFileTabs(workspace);
      } else {
        await _activateBuffer(
          workspace,
          nextUntitled,
          documentBuffers: remainingBuffers,
          openFilePaths: nextOpenFilePaths,
        );
      }
      return true;
    }
    if (workspace.activeFilePath != path) {
      state = state.copyWith(
        workspace: workspace.copyWith(openFilePaths: nextOpenFilePaths),
        documentBuffers: remainingBuffers,
        clearMessage: true,
      );
      return true;
    }
    final nextIndex = closedIndex <= 0
        ? 0
        : math.min(closedIndex - 1, nextOpenFilePaths.length - 1);
    return _openActiveFile(
      nextOpenFilePaths[nextIndex],
      openFilePaths: nextOpenFilePaths,
      documentBuffers: remainingBuffers,
    );
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
    if (buffer.filePath case final path?) {
      if (buffer.isDirty) {
        state = state.copyWith(
          documentBuffers: _replaceBuffer(
            state.documentBuffers,
            buffer.copyWith(dirty: false),
          ),
        );
      }
      return closeOpenFileTab(path);
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
      return true;
    }
    return _activateBuffer(
      workspace,
      remaining.last,
      documentBuffers: remaining,
      openFilePaths: workspace.openFilePaths,
    );
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
    final buffers = documentBuffers ?? state.documentBuffers;
    final existing = buffers
        .where((buffer) => buffer.filePath == path)
        .firstOrNull;
    if (existing != null) {
      return _activateBuffer(
        workspace,
        existing,
        documentBuffers: buffers,
        openFilePaths: openFilePaths ?? _openFileTabPaths(workspace, path),
      );
    }
    _cancelPendingDerivedRefresh();
    final operationRevision = _invalidateActiveDocumentOperations();
    try {
      final load = await _service.loadTextWithSnapshot(path);
      final nextWorkspace = workspace.copyWith(
        activeFilePath: path,
        activeFileSnapshot: load.snapshot,
        openFilePaths: openFilePaths ?? _openFileTabPaths(workspace, path),
      );
      if (!_isCurrentActiveDocumentOperation(operationRevision)) {
        return false;
      }
      final reparsed = await _service.reparseActive(nextWorkspace, load.text);
      if (!_isCurrentActiveDocumentOperation(operationRevision)) {
        return false;
      }
      final buffer = _fileBuffer(
        path,
        load,
        mode: _settingsController.state.documentViewMode,
      );
      state = state.copyWith(
        workspace: reparsed,
        activeText: load.text,
        preview: _safePreview(reparsed, load.text),
        documentBuffers: [...buffers, buffer],
        activeBufferId: buffer.id,
        clearMessage: true,
      );
      _fileMonitor.updateOpenFilePaths(
        [
          ...buffers,
          buffer,
        ].map((candidate) => candidate.filePath).whereType<String>(),
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
    final nextWorkspace = workspace.copyWith(
      activeFilePath: buffer.filePath,
      activeFileSnapshot: buffer.diskSnapshot,
      openFilePaths: openFilePaths,
      markdown: buffer.filePath == null ? workspace.markdown : null,
    );
    final reparsed = await _service.reparseActive(nextWorkspace, buffer.text);
    if (!_isCurrentActiveDocumentOperation(operationRevision)) {
      return false;
    }
    state = state.copyWith(
      workspace: reparsed,
      preview: _safePreview(reparsed, buffer.text),
      documentBuffers: documentBuffers,
      activeBufferId: buffer.id,
      clearMessage: true,
    );
    _fileMonitor.updateOpenFilePaths(
      documentBuffers
          .map((candidate) => candidate.filePath)
          .whereType<String>(),
    );
    _schedulePersistence();
    _editRevision = buffer.revision;
    unawaited(_settingsController.setDocumentViewMode(buffer.editorState.mode));
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
    _schedulePersistence();
    return true;
  }

  void updateActiveEditorMode(DocumentViewModePreference mode) {
    final buffer = state.activeBuffer;
    if (buffer == null || buffer.editorState.mode == mode) {
      return;
    }
    updateActiveEditorState(buffer.editorState.copyWith(mode: mode));
  }

  bool undoActiveBuffer() {
    final buffer = state.activeBuffer;
    if (buffer == null || buffer.editorState.undoState.undo.isEmpty) {
      return false;
    }
    final undo = buffer.editorState.undoState;
    final text = undo.undo.last;
    final next = buffer.copyWith(
      text: text,
      dirty: text != buffer.lastSavedText || buffer.isUntitled,
      format: buffer.format.copyWith(hasFinalNewline: text.endsWith('\n')),
      revision: buffer.revision + 1,
      editorState: buffer.editorState.copyWith(
        undoState: undo.afterUndo(buffer.text),
      ),
    );
    state = state.copyWith(
      documentBuffers: _replaceBuffer(state.documentBuffers, next),
    );
    _requestDerivedRefresh(rebuildPreview: true);
    _schedulePersistence();
    return true;
  }

  bool redoActiveBuffer() {
    final buffer = state.activeBuffer;
    if (buffer == null || buffer.editorState.undoState.redo.isEmpty) {
      return false;
    }
    final undo = buffer.editorState.undoState;
    final text = undo.redo.last;
    final next = buffer.copyWith(
      text: text,
      dirty: text != buffer.lastSavedText || buffer.isUntitled,
      format: buffer.format.copyWith(hasFinalNewline: text.endsWith('\n')),
      revision: buffer.revision + 1,
      editorState: buffer.editorState.copyWith(
        undoState: undo.afterRedo(buffer.text),
      ),
    );
    state = state.copyWith(
      documentBuffers: _replaceBuffer(state.documentBuffers, next),
    );
    _requestDerivedRefresh(rebuildPreview: true);
    _schedulePersistence();
    return true;
  }

  void updateActiveText(String text, {String? sourceFilePath}) {
    _updateActiveText(
      text,
      sourceFilePath: sourceFilePath,
      rebuildPreview: true,
    );
  }

  /// Applies a serialized WYSIWYG edit without reparsing the whole Markdown
  /// document on every keystroke.
  void updateActiveWysiwygText(
    String text, {
    required BusyDocument document,
    String? sourceFilePath,
  }) {
    _updateActiveText(
      text,
      sourceFilePath: sourceFilePath,
      rebuildPreview: false,
      liveOutline: document.outline,
      preserveFinalNewline: true,
    );
  }

  /// Rebuilds derived preview data after leaving WYSIWYG mode without creating
  /// another edit revision for text that is already in state.
  void refreshActivePreview({String? sourceFilePath}) {
    final workspace = state.workspace;
    final activeEditorPath =
        workspace?.activeFilePath ?? workspace?.markdown?.filePath;
    if (workspace == null ||
        (sourceFilePath != null && activeEditorPath != sourceFilePath)) {
      return;
    }
    _requestDerivedRefresh(rebuildPreview: true);
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
        return true;
      }
      final existing = state.documentBuffers
          .where((buffer) => buffer.filePath == path)
          .firstOrNull;
      if (existing != null) {
        return _activateBuffer(
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
    final nextBuffer = activeBuffer.edited(effectiveText);
    if (identical(nextBuffer, activeBuffer)) {
      return;
    }
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
    _requestDerivedRefresh(rebuildPreview: rebuildPreview);
    _scheduleAutoSave(nextBuffer.id);
  }

  void _requestDerivedRefresh({required bool rebuildPreview}) {
    if (!_settingsController.state.validateOnEdit && !rebuildPreview) {
      return;
    }
    _derivedRefreshPending = true;
    _pendingPreviewRefresh = _pendingPreviewRefresh || rebuildPreview;
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
      while (_derivedRefreshPending) {
        _derivedRefreshPending = false;
        final rebuildPreview = _pendingPreviewRefresh;
        _pendingPreviewRefresh = false;
        if (_settingsController.state.validateOnEdit) {
          await validateActive();
        } else if (rebuildPreview) {
          await _refreshActivePreview();
        }
      }
    } finally {
      _derivedRefreshRunning = false;
      if (_derivedRefreshPending) {
        unawaited(_drainDerivedRefreshes());
      }
    }
  }

  void _cancelPendingDerivedRefresh() {
    _derivedRefreshPending = false;
    _pendingPreviewRefresh = false;
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
      final reparsed = await _service.reparseActive(workspace, text);
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
      final reparsed = await _service.reparseActive(workspace, text);
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
    try {
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
      await _startMonitoring(savedWorkspace);
      if (hasNewerEdits) {
        if (state.activeBufferId == savedBuffer.id &&
            _settingsController.state.validateOnEdit) {
          unawaited(validateActive());
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
    final operationRevision = _invalidateActiveDocumentOperations();
    _cancelPendingDerivedRefresh();
    _cancelAllAutoSaves();
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      final openTarget = workspace.kind == WorkspaceKind.singleMarkdown
          ? workspace.activeFilePath ?? workspace.rootPath
          : workspace.rootPath;
      final refreshed = await _service.openPath(openTarget);
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
      final buffers = <DocumentBuffer>[];
      for (final buffer in state.documentBuffers) {
        final path = buffer.filePath;
        if (path == null) {
          buffers.add(buffer);
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
        if (!exists) {
          buffers.add(buffer.copyWith(diskState: DocumentDiskState.deleted));
          continue;
        }
        if (buffer.isDirty) {
          buffers.add(buffer);
          continue;
        }
        final load = await _service.loadTextWithSnapshot(path);
        buffers.add(
          buffer.copyWith(
            text: load.text,
            lastSavedText: load.text,
            dirty: false,
            diskSnapshot: load.snapshot,
            format: load.format,
            diskState: DocumentDiskState.present,
          ),
        );
      }
      var activeBuffer = buffers
          .where((buffer) => buffer.id == state.activeBufferId)
          .firstOrNull;
      activeBuffer ??= buffers.firstOrNull;
      if (activeBuffer == null && refreshed.activeFilePath != null) {
        final load = await _service.loadTextWithSnapshot(
          refreshed.activeFilePath!,
        );
        activeBuffer = _fileBuffer(
          refreshed.activeFilePath!,
          load,
          mode: _settingsController.state.documentViewMode,
        );
        buffers.add(activeBuffer);
      }
      final active = activeBuffer?.filePath;
      final tabPaths = [
        for (final buffer in buffers)
          if (buffer.filePath != null) buffer.filePath!,
      ];
      final nextWorkspace = refreshedWorkspace.copyWith(
        activeFilePath: active,
        activeFileSnapshot: activeBuffer?.diskSnapshot,
        openFilePaths: tabPaths,
      );
      final reparsed = activeBuffer == null
          ? nextWorkspace.copyWith(markdown: null)
          : await _service.reparseActive(nextWorkspace, activeBuffer.text);
      if (!_isCurrentActiveDocumentOperation(operationRevision)) {
        return false;
      }
      state = WorkspaceState(
        workspace: reparsed,
        activeText: activeBuffer?.text ?? '',
        preview: activeBuffer == null
            ? null
            : _safePreview(reparsed, activeBuffer.text),
        documentBuffers: buffers,
        activeBufferId: activeBuffer?.id,
      );
      _fileMonitor.updateOpenFilePaths(tabPaths);
      _schedulePersistence();
      _resetSaveTracking();
      return true;
    } on Object catch (error, stackTrace) {
      busyMarkDebugLogError(
        '[BusyMark] Workspace refresh failed',
        error,
        stackTrace,
        context: {'root': busyMarkLogPath(workspace.rootPath)},
      );
      if (_isCurrentActiveDocumentOperation(operationRevision)) {
        state = state.copyWith(
          isLoading: false,
          message: WorkspaceMessage(
            WorkspaceMessageCode.couldNotOpenFile,
            error: error,
          ),
        );
      }
      return false;
    }
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

  Future<void> validateActive() async {
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
      final reparsed = await _service.reparseActive(workspace, text);
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
      state = state.copyWith(
        workspace: reparsed.copyWith(
          activeFileSnapshot: currentSnapshot,
          openFilePaths: currentWorkspace.openFilePaths,
          files: currentWorkspace.files,
        ),
        preview: _safePreview(reparsed, text),
        clearMessage: true,
      );
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
    return operationRevision == _activeDocumentRevision;
  }

  bool _isCurrentActiveDocument(
    int operationRevision, {
    required String? workspaceId,
    required String? activeFilePath,
  }) {
    final workspace = state.workspace;
    return operationRevision == _activeDocumentRevision &&
        workspace != null &&
        workspace.id == workspaceId &&
        workspace.activeFilePath == activeFilePath;
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
    id: 'file:$path',
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
