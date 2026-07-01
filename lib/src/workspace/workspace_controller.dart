import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_settings.dart';
import '../core/diagnostic.dart';
import '../markdown/preview_model.dart';
import '../writerside/writerside_project_creator.dart';
import '../writerside/writerside_topic_creator.dart';
import 'workspace_model.dart';
import 'workspace_message.dart';
import 'workspace_service.dart';

final workspaceServiceProvider = Provider<WorkspaceService>(
  (ref) => const WorkspaceService(),
);

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
  Timer? _parseDebounce;
  Timer? _autoSaveDebounce;
  Future<bool>? _activeSave;
  var _editRevision = 0;
  var _activeDocumentRevision = 0;

  @override
  WorkspaceState build() {
    _service = ref.read(workspaceServiceProvider);
    _settingsController = ref.read(appSettingsControllerProvider.notifier);
    ref.listen<AppSettings>(appSettingsControllerProvider, (previous, next) {
      if (!next.autoSave) {
        _autoSaveDebounce?.cancel();
        return;
      }
      if (state.isDirty) {
        _scheduleAutoSave();
      }
    });
    ref.onDispose(() {
      _parseDebounce?.cancel();
      _autoSaveDebounce?.cancel();
    });
    return const WorkspaceState();
  }

  bool get activeDocumentNeedsSaveLocation {
    final workspace = state.workspace;
    return workspace != null &&
        (workspace.kind == WorkspaceKind.untitledMarkdown ||
            workspace.activeFilePath == null);
  }

  Future<void> createMarkdownFile() async {
    _parseDebounce?.cancel();
    _autoSaveDebounce?.cancel();
    _invalidateActiveDocumentOperations();
    _resetSaveTracking(dirty: true);
    final workspace = _service.createUntitledMarkdown();
    state = WorkspaceState(
      workspace: workspace,
      preview: _safePreview(workspace, ''),
      isDirty: true,
      isLoading: false,
    );
  }

  Future<void> openPath(String path) async {
    _parseDebounce?.cancel();
    _autoSaveDebounce?.cancel();
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
      state = WorkspaceState(
        workspace: loadedWorkspace,
        activeText: text,
        preview: preview,
      );
      _resetSaveTracking();
      final recentPath = workspace.kind == WorkspaceKind.singleMarkdown
          ? workspace.activeFilePath ?? workspace.rootPath
          : workspace.rootPath;
      await _settingsController.recordOpenedWorkspace(
        path: recentPath,
        kind: workspace.kind.name,
      );
    } on Object catch (error, stackTrace) {
      stderr.writeln('[BusyMark] Open failed for path: $path');
      stderr.writeln('[BusyMark]   error: $error');
      stderr.writeln('[BusyMark]   stack trace:\n$stackTrace');
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
    _parseDebounce?.cancel();
    _autoSaveDebounce?.cancel();
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
      state = WorkspaceState(
        workspace: loadedWorkspace,
        activeText: text,
        preview: preview,
      );
      _resetSaveTracking();
      await _settingsController.recordOpenedWorkspace(
        path: workspace.rootPath,
        kind: workspace.kind.name,
      );
      return true;
    } on Object catch (error, stackTrace) {
      stderr.writeln('[BusyMark] Create Writerside project failed');
      stderr.writeln('[BusyMark]   parent: ${request.parentDirectoryPath}');
      stderr.writeln('[BusyMark]   directory: ${request.directoryName}');
      stderr.writeln('[BusyMark]   error: $error');
      stderr.writeln('[BusyMark]   stack trace:\n$stackTrace');
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
    WritersideTopicCreateRequest request,
  ) async {
    final workspace = state.workspace;
    if (workspace == null) {
      return false;
    }
    _parseDebounce?.cancel();
    _autoSaveDebounce?.cancel();
    final operationRevision = _invalidateActiveDocumentOperations();
    _resetSaveTracking();
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      final nextWorkspace = await _service.createWritersideTopic(
        workspace,
        request,
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
      state = WorkspaceState(
        workspace: tabbedWorkspace,
        activeText: text,
        preview: _safePreview(tabbedWorkspace, text),
      );
      _resetSaveTracking();
      return true;
    } on Object catch (error, stackTrace) {
      stderr.writeln('[BusyMark] Create Writerside topic failed');
      stderr.writeln('[BusyMark]   title: ${request.title}');
      stderr.writeln('[BusyMark]   file name: ${request.fileName}');
      stderr.writeln('[BusyMark]   error: $error');
      stderr.writeln('[BusyMark]   stack trace:\n$stackTrace');
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

  Future<void> openFile(String path) => openPath(path);

  Future<void> openFolder(String path) => openPath(path);

  Future<bool> openActiveFile(String path) async {
    final workspace = state.workspace;
    if (workspace?.activeFilePath != path && !await autoSaveActiveIfNeeded()) {
      return false;
    }
    return _openActiveFile(path);
  }

  Future<bool> activateNextOpenFileTab() => _activateOpenFileTab(1);

  Future<bool> activatePreviousOpenFileTab() => _activateOpenFileTab(-1);

  Future<bool> closeActiveOpenFileTab() async {
    final activeFilePath = state.workspace?.activeFilePath;
    if (activeFilePath == null) {
      return false;
    }
    return closeOpenFileTab(activeFilePath);
  }

  Future<bool> closeAllOpenFileTabs() async {
    final workspace = state.workspace;
    if (workspace == null || workspace.openFilePaths.isEmpty) {
      return false;
    }
    if (!await autoSaveActiveIfNeeded()) {
      return false;
    }
    _clearOpenFileTabs(workspace);
    return true;
  }

  Future<bool> closeOpenFileTab(String path) async {
    final workspace = state.workspace;
    if (workspace == null ||
        !_supportsOpenFileTabs(workspace) ||
        !workspace.openFilePaths.contains(path)) {
      return false;
    }
    final closedIndex = workspace.openFilePaths.indexOf(path);
    final nextOpenFilePaths = [
      for (final openPath in workspace.openFilePaths)
        if (openPath != path) openPath,
    ];
    if (workspace.activeFilePath == path && !await autoSaveActiveIfNeeded()) {
      return false;
    }
    if (nextOpenFilePaths.isEmpty) {
      _clearOpenFileTabs(workspace);
      return true;
    }
    if (workspace.activeFilePath != path) {
      state = state.copyWith(
        workspace: workspace.copyWith(openFilePaths: nextOpenFilePaths),
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
    );
  }

  Future<bool> _activateOpenFileTab(int delta) async {
    final workspace = state.workspace;
    if (workspace == null ||
        !_supportsOpenFileTabs(workspace) ||
        workspace.openFilePaths.length < 2) {
      return false;
    }
    final activeFilePath = workspace.activeFilePath;
    final activeIndex = activeFilePath == null
        ? -1
        : workspace.openFilePaths.indexOf(activeFilePath);
    final nextIndex = activeIndex < 0
        ? 0
        : (activeIndex + delta) % workspace.openFilePaths.length;
    final normalizedIndex = nextIndex < 0
        ? nextIndex + workspace.openFilePaths.length
        : nextIndex;
    return openActiveFile(workspace.openFilePaths[normalizedIndex]);
  }

  void _clearOpenFileTabs(Workspace workspace) {
    if (!_supportsOpenFileTabs(workspace)) {
      return;
    }
    _parseDebounce?.cancel();
    _autoSaveDebounce?.cancel();
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
      isDirty: false,
      clearMessage: true,
    );
  }

  Future<bool> _openActiveFile(
    String path, {
    List<String>? openFilePaths,
  }) async {
    final workspace = state.workspace;
    if (workspace == null) {
      return false;
    }
    _parseDebounce?.cancel();
    _autoSaveDebounce?.cancel();
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
      state = state.copyWith(
        workspace: reparsed,
        activeText: load.text,
        preview: _safePreview(reparsed, load.text),
        isDirty: false,
        clearMessage: true,
      );
      _resetSaveTracking();
      return true;
    } on Object catch (error, stackTrace) {
      stderr.writeln('[BusyMark] Could not open file: $path');
      stderr.writeln('[BusyMark]   error: $error');
      stderr.writeln('[BusyMark]   stack trace:\n$stackTrace');
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

  void updateActiveText(String text, {bool updatePreview = true}) {
    final workspace = state.workspace;
    _editRevision++;
    state = state.copyWith(
      activeText: text,
      preview: workspace == null || !updatePreview
          ? state.preview
          : _safePreview(workspace, text),
      isDirty: true,
    );
    _parseDebounce?.cancel();
    if (!_settingsController.state.validateOnEdit) {
      _scheduleAutoSave();
      return;
    }
    _parseDebounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(validateActive());
    });
    _scheduleAutoSave();
  }

  Future<bool> autoSaveActiveIfNeeded() async {
    _autoSaveDebounce?.cancel();
    if (!_settingsController.state.autoSave || !state.isDirty) {
      return true;
    }
    if (!_canAutoSaveActive()) {
      return false;
    }
    return saveActive();
  }

  Future<bool> saveActive({bool overwriteExternalChanges = false}) async {
    _autoSaveDebounce?.cancel();
    _parseDebounce?.cancel();
    final inFlight = _activeSave;
    if (inFlight != null) {
      final completed = await inFlight;
      if (!state.isDirty) {
        return completed;
      }
      return saveActive(overwriteExternalChanges: overwriteExternalChanges);
    }
    late final Future<bool> operation;
    operation = _saveActiveNow(
      overwriteExternalChanges: overwriteExternalChanges,
    );
    _activeSave = operation;
    unawaited(
      operation.whenComplete(() {
        if (identical(_activeSave, operation)) {
          _activeSave = null;
        }
      }),
    );
    return operation;
  }

  Future<bool> _saveActiveNow({required bool overwriteExternalChanges}) async {
    final workspace = state.workspace;
    final active = workspace?.activeFilePath;
    final workspaceId = workspace?.id;
    final operationRevision = _activeDocumentRevision;
    if (active == null) {
      state = state.copyWith(
        message: const WorkspaceMessage(
          WorkspaceMessageCode.chooseWhereToSaveMarkdown,
        ),
      );
      return false;
    }
    if (!overwriteExternalChanges &&
        await _service.fileChangedSince(
          active,
          workspace?.activeFileSnapshot,
        )) {
      if (!_isCurrentActiveDocument(
        operationRevision,
        workspaceId: workspaceId,
        activeFilePath: active,
      )) {
        return true;
      }
      state = state.copyWith(
        message: const WorkspaceMessage(
          WorkspaceMessageCode.saveBlockedFileChangedOnDisk,
        ),
      );
      return false;
    }
    if (!_isCurrentActiveDocument(
      operationRevision,
      workspaceId: workspaceId,
      activeFilePath: active,
    )) {
      return true;
    }
    final revisionAtSaveStart = _editRevision;
    final textAtSaveStart = state.activeText;
    try {
      final snapshot = await _service.saveText(active, textAtSaveStart);
      final currentWorkspace = state.workspace;
      if (!_isCurrentActiveDocument(
            operationRevision,
            workspaceId: workspaceId,
            activeFilePath: active,
          ) ||
          currentWorkspace == null) {
        return true;
      }
      final reparsed = await _service.reparseActive(
        currentWorkspace.copyWith(activeFileSnapshot: snapshot),
        textAtSaveStart,
      );
      final latestWorkspace = state.workspace;
      if (!_isCurrentActiveDocument(
            operationRevision,
            workspaceId: workspaceId,
            activeFilePath: active,
          ) ||
          latestWorkspace == null) {
        return true;
      }
      if (_editRevision == revisionAtSaveStart) {
        final nextWorkspace = reparsed.copyWith(
          activeFileSnapshot: snapshot,
          openFilePaths: latestWorkspace.openFilePaths,
          files: latestWorkspace.files,
        );
        state = state.copyWith(
          workspace: nextWorkspace,
          preview: _safePreview(nextWorkspace, textAtSaveStart),
          isDirty: false,
          clearMessage: true,
        );
      } else {
        state = state.copyWith(
          workspace: latestWorkspace.copyWith(activeFileSnapshot: snapshot),
          isDirty: true,
          clearMessage: true,
        );
        _scheduleAutoSave();
      }
      return true;
    } on Object catch (error) {
      if (_isCurrentActiveDocument(
        operationRevision,
        workspaceId: workspaceId,
        activeFilePath: active,
      )) {
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

  Future<bool> saveActiveAs(String path) async {
    _autoSaveDebounce?.cancel();
    _parseDebounce?.cancel();
    final workspace = state.workspace;
    if (workspace == null) {
      return false;
    }
    final operationRevision = _invalidateActiveDocumentOperations();
    final text = state.activeText;
    try {
      await _service.saveText(path, text);
      final savedWorkspace = await _service.openPath(path);
      if (!_isCurrentActiveDocumentOperation(operationRevision)) {
        return false;
      }
      state = WorkspaceState(
        workspace: savedWorkspace,
        activeText: text,
        preview: _safePreview(savedWorkspace, text),
      );
      _resetSaveTracking();
      await _settingsController.recordOpenedWorkspace(
        path: path,
        kind: savedWorkspace.kind.name,
      );
      return true;
    } on Object catch (error) {
      if (_isCurrentActiveDocumentOperation(operationRevision)) {
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

  Future<bool> activeFileChangedOnDisk() async {
    final workspace = state.workspace;
    final active = workspace?.activeFilePath;
    if (active == null) {
      return false;
    }
    return _service.fileChangedSince(active, workspace?.activeFileSnapshot);
  }

  Future<void> validateActive() async {
    final workspace = state.workspace;
    if (workspace == null) {
      return;
    }
    final workspaceId = workspace.id;
    final activeFilePath = workspace.activeFilePath;
    final text = state.activeText;
    final editRevision = _editRevision;
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
          _editRevision != editRevision) {
        return;
      }
      state = state.copyWith(
        workspace: reparsed,
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
          _editRevision == editRevision) {
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

  void _scheduleAutoSave() {
    _autoSaveDebounce?.cancel();
    if (!_settingsController.state.autoSave || !_canAutoSaveActive()) {
      return;
    }
    _autoSaveDebounce = Timer(_autoSaveDelay, () {
      unawaited(autoSaveActiveIfNeeded());
    });
  }

  bool _canAutoSaveActive() {
    final workspace = state.workspace;
    return workspace != null && workspace.activeFilePath != null;
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
}

List<String> _openFileTabPaths(Workspace workspace, String path) {
  if (workspace.openFilePaths.contains(path)) {
    return workspace.openFilePaths;
  }
  return [...workspace.openFilePaths, path];
}

bool _supportsOpenFileTabs(Workspace workspace) {
  return switch (workspace.kind) {
    WorkspaceKind.markdownFolder || WorkspaceKind.writersideModule => true,
    WorkspaceKind.untitledMarkdown || WorkspaceKind.singleMarkdown => false,
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
