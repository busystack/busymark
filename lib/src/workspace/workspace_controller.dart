import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../app/app_settings.dart';
import '../core/debug_log.dart';
import '../core/diagnostic.dart';
import '../markdown/busymark_document.dart';
import '../markdown/document_outline.dart';
import '../markdown/preview_model.dart';
import '../writerside/writerside_project_creator.dart';
import '../writerside/writerside_topic_removal_service.dart';
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
    required this.path,
    required this.documentRevision,
    required this.editRevision,
    required this.snapshot,
    required this.text,
    required this.workspaceKind,
  });

  final String workspaceId;
  final String? path;
  final int documentRevision;
  final int editRevision;
  final WorkspaceFileSnapshot? snapshot;
  final String text;
  final WorkspaceKind workspaceKind;

  bool get needsSaveLocation =>
      workspaceKind == WorkspaceKind.untitledMarkdown || path == null;
}

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
  Timer? _autoSaveDebounce;
  Future<bool>? _activeSave;
  ActiveDocumentSaveTarget? _activeSaveTarget;
  var _derivedRefreshRunning = false;
  var _derivedRefreshPending = false;
  var _pendingPreviewRefresh = false;
  var _editRevision = 0;
  var _activeDocumentRevision = 0;

  int get editRevision => _editRevision;

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
      _cancelPendingDerivedRefresh();
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

  ActiveDocumentSaveTarget? captureActiveDocumentSaveTarget() {
    final workspace = state.workspace;
    if (workspace == null) {
      return null;
    }
    return ActiveDocumentSaveTarget._(
      workspaceId: workspace.id,
      path: workspace.activeFilePath,
      documentRevision: _activeDocumentRevision,
      editRevision: _editRevision,
      snapshot: workspace.activeFileSnapshot,
      text: state.activeText,
      workspaceKind: workspace.kind,
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
        _editRevision == target.editRevision &&
        state.activeText == target.text &&
        _sameFileSnapshot(workspace.activeFileSnapshot, target.snapshot);
  }

  Future<void> createMarkdownFile() async {
    _cancelPendingDerivedRefresh();
    _autoSaveDebounce?.cancel();
    _invalidateActiveDocumentOperations();
    _resetSaveTracking(dirty: true);
    final viewModeChange = _showEditorForNewFile();
    final workspace = _service.createUntitledMarkdown();
    state = WorkspaceState(
      workspace: workspace,
      preview: _safePreview(workspace, ''),
      isDirty: true,
      isLoading: false,
    );
    await viewModeChange;
  }

  Future<void> openPath(String path) async {
    _cancelPendingDerivedRefresh();
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
    _autoSaveDebounce?.cancel();
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
      state = WorkspaceState(
        workspace: tabbedWorkspace,
        activeText: text,
        preview: _safePreview(tabbedWorkspace, text),
      );
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
    return _runWorkspaceFileOperation((workspace) async {
      await _service.deleteEntity(workspace, path);
      return null;
    });
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
    _cancelPendingDerivedRefresh();
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
    _cancelPendingDerivedRefresh();
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

  void _updateActiveText(
    String text, {
    required bool rebuildPreview,
    String? sourceFilePath,
    List<DocumentOutlineHeading>? liveOutline,
  }) {
    final workspace = state.workspace;
    final activeEditorPath =
        workspace?.activeFilePath ?? workspace?.markdown?.filePath;
    if (sourceFilePath != null && activeEditorPath != sourceFilePath) {
      return;
    }
    _editRevision++;
    state = state.copyWith(
      activeText: text,
      liveOutline: workspace == null || liveOutline == null
          ? null
          : ActiveDocumentOutline(
              workspaceId: workspace.id,
              filePath: workspace.activeFilePath,
              source: text,
              headings: liveOutline,
            ),
      isDirty: true,
    );
    _requestDerivedRefresh(rebuildPreview: rebuildPreview);
    _scheduleAutoSave();
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
    final editRevision = _editRevision;
    final operationRevision = _activeDocumentRevision;
    try {
      final preview = await _service.buildPreviewAsync(workspace, text);
      if (!_isCurrentActiveDocument(
            operationRevision,
            workspaceId: workspaceId,
            activeFilePath: activeFilePath,
          ) ||
          state.activeText != text ||
          _editRevision != editRevision) {
        return;
      }
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
    _autoSaveDebounce?.cancel();
    if (!_settingsController.state.autoSave || !state.isDirty) {
      return true;
    }
    if (!_canAutoSaveActive()) {
      return false;
    }
    return saveActive();
  }

  Future<bool> saveActive({
    bool overwriteExternalChanges = false,
    ActiveDocumentSaveTarget? target,
  }) async {
    final operationTarget = target ?? captureActiveDocumentSaveTarget();
    if (operationTarget == null ||
        !isActiveDocumentSaveTargetCurrent(operationTarget)) {
      return false;
    }
    _autoSaveDebounce?.cancel();
    _cancelPendingDerivedRefresh();
    final inFlight = _activeSave;
    if (inFlight != null) {
      if (_sameSaveTarget(_activeSaveTarget, operationTarget)) {
        return inFlight;
      }
      final completed = await inFlight;
      // The preceding save may have advanced the controller-owned disk
      // snapshot. Re-pin only that snapshot; document and edit identity must
      // still match the queued request.
      final refreshedTarget = _refreshActiveDocumentSaveTarget(operationTarget);
      if (refreshedTarget == null) {
        return false;
      }
      if (!state.isDirty && completed) {
        return completed;
      }
      return saveActive(
        overwriteExternalChanges: overwriteExternalChanges,
        target: refreshedTarget,
      );
    }
    late final Future<bool> operation;
    operation = _saveActiveNow(
      operationTarget,
      overwriteExternalChanges: overwriteExternalChanges,
    );
    _activeSave = operation;
    _activeSaveTarget = operationTarget;
    unawaited(
      operation.whenComplete(() {
        if (identical(_activeSave, operation)) {
          _activeSave = null;
          _activeSaveTarget = null;
        }
      }),
    );
    return operation;
  }

  Future<bool> _saveActiveNow(
    ActiveDocumentSaveTarget target, {
    required bool overwriteExternalChanges,
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
      if (!isActiveDocumentSaveTargetCurrent(target)) {
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
    if (!isActiveDocumentSaveTargetCurrent(target)) {
      return false;
    }
    try {
      final snapshot = await _service.saveText(active, target.text);
      final currentWorkspace = state.workspace;
      if (!_isCurrentActiveDocument(
            target.documentRevision,
            workspaceId: target.workspaceId,
            activeFilePath: active,
          ) ||
          currentWorkspace == null) {
        return false;
      }
      final reparsed = await _service.reparseActive(
        currentWorkspace.copyWith(activeFileSnapshot: snapshot),
        target.text,
      );
      final latestWorkspace = state.workspace;
      if (!_isCurrentActiveDocument(
            target.documentRevision,
            workspaceId: target.workspaceId,
            activeFilePath: active,
          ) ||
          latestWorkspace == null) {
        return false;
      }
      if (_editRevision == target.editRevision &&
          state.activeText == target.text) {
        final nextWorkspace = reparsed.copyWith(
          activeFileSnapshot: snapshot,
          openFilePaths: latestWorkspace.openFilePaths,
          files: latestWorkspace.files,
        );
        state = state.copyWith(
          workspace: nextWorkspace,
          preview: _safePreview(nextWorkspace, target.text),
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
        target.documentRevision,
        workspaceId: target.workspaceId,
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

  Future<bool> saveActiveAs(
    String path, {
    ActiveDocumentSaveTarget? target,
    bool overwriteExisting = false,
  }) async {
    final operationTarget = target ?? captureActiveDocumentSaveTarget();
    if (operationTarget == null ||
        !isActiveDocumentSaveTargetCurrent(operationTarget)) {
      return false;
    }
    _autoSaveDebounce?.cancel();
    _cancelPendingDerivedRefresh();
    final operationRevision = _invalidateActiveDocumentOperations();
    try {
      if (overwriteExisting) {
        await _service.saveTextReplacingPath(path, operationTarget.text);
      } else {
        await _service.saveNewText(path, operationTarget.text);
      }
      if (!_isSaveAsSourceDocumentCurrent(operationRevision, operationTarget)) {
        return false;
      }
      final savedWorkspace = await _service.openPath(path);
      if (!_isSaveAsSourceDocumentCurrent(operationRevision, operationTarget)) {
        return false;
      }
      final latestText = state.activeText;
      final hasNewerEdits =
          _editRevision != operationTarget.editRevision ||
          latestText != operationTarget.text;
      _cancelPendingDerivedRefresh();
      state = WorkspaceState(
        workspace: savedWorkspace,
        activeText: hasNewerEdits ? latestText : operationTarget.text,
        preview: _safePreview(
          savedWorkspace,
          hasNewerEdits ? latestText : operationTarget.text,
        ),
        isDirty: hasNewerEdits,
      );
      if (hasNewerEdits) {
        if (_settingsController.state.validateOnEdit) {
          unawaited(validateActive());
        }
        _scheduleAutoSave();
      } else {
        _resetSaveTracking();
      }
      await _settingsController.recordOpenedWorkspace(
        path: path,
        kind: savedWorkspace.kind.name,
      );
      return true;
    } on Object catch (error) {
      if (_isSaveAsSourceDocumentCurrent(operationRevision, operationTarget)) {
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
    _autoSaveDebounce?.cancel();
    _cancelPendingDerivedRefresh();
    final workspace = state.workspace;
    if (workspace == null) {
      return false;
    }
    final active = operationTarget.path;
    final operationRevision = _invalidateActiveDocumentOperations();
    if (workspace.kind == WorkspaceKind.untitledMarkdown || active == null) {
      state = const WorkspaceState();
      _resetSaveTracking();
      return true;
    }
    try {
      final load = await _service.loadTextWithSnapshot(active);
      if (!_isPinnedOperationCurrent(operationRevision, operationTarget)) {
        return false;
      }
      final nextWorkspace = workspace.copyWith(
        activeFileSnapshot: load.snapshot,
      );
      final reparsed = await _service.reparseActive(nextWorkspace, load.text);
      if (!_isPinnedOperationCurrent(operationRevision, operationTarget)) {
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
      busyMarkDebugLogError(
        '[BusyMark] Discard active changes failed',
        error,
        stackTrace,
        context: {'active': busyMarkLogPath(active)},
      );
      if (_isPinnedOperationCurrent(operationRevision, operationTarget)) {
        state = state.copyWith(
          isDirty: true,
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
    if (workspace == null || state.isDirty) {
      return false;
    }
    final operationRevision = _invalidateActiveDocumentOperations();
    _cancelPendingDerivedRefresh();
    _autoSaveDebounce?.cancel();
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      final openTarget = workspace.kind == WorkspaceKind.singleMarkdown
          ? workspace.activeFilePath ?? workspace.rootPath
          : workspace.rootPath;
      final refreshed = await _service.openPath(openTarget);
      final existingFiles = {
        for (final file in refreshed.files) file.absolutePath: file,
      };
      final retainedTabs = [
        for (final path in workspace.openFilePaths)
          if (existingFiles.containsKey(path)) path,
      ];
      final previousActive = workspace.activeFilePath;
      final active =
          previousActive != null && existingFiles.containsKey(previousActive)
          ? previousActive
          : retainedTabs.isNotEmpty
          ? retainedTabs.first
          : refreshed.activeFilePath;
      final load = active == null
          ? null
          : await _service.loadTextWithSnapshot(active);
      final tabPaths = _supportsOpenFileTabs(refreshed)
          ? _retainedOpenFileTabPaths(
              current: workspace,
              refreshed: refreshed,
              activeFilePath: active,
            )
          : active == null
          ? const <String>[]
          : <String>[active];
      final nextWorkspace = refreshed.copyWith(
        activeFilePath: active,
        activeFileSnapshot: load?.snapshot,
        openFilePaths: tabPaths,
      );
      final reparsed = load == null
          ? nextWorkspace.copyWith(markdown: null)
          : await _service.reparseActive(nextWorkspace, load.text);
      if (!_isCurrentActiveDocumentOperation(operationRevision)) {
        return false;
      }
      state = WorkspaceState(
        workspace: reparsed,
        activeText: load?.text ?? '',
        preview: load == null ? null : _safePreview(reparsed, load.text),
      );
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

  Future<void> _showEditorForNewFile() {
    if (_settingsController.state.documentViewMode !=
        DocumentViewModePreference.preview) {
      return Future<void>.value();
    }
    return _settingsController.setDocumentViewMode(
      DocumentViewModePreference.editor,
    );
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

  bool _isPinnedOperationCurrent(
    int operationRevision,
    ActiveDocumentSaveTarget target,
  ) {
    final workspace = state.workspace;
    return _isCurrentActiveDocument(
          operationRevision,
          workspaceId: target.workspaceId,
          activeFilePath: target.path,
        ) &&
        workspace != null &&
        _editRevision == target.editRevision &&
        state.activeText == target.text &&
        _sameFileSnapshot(workspace.activeFileSnapshot, target.snapshot);
  }

  bool _isSaveAsSourceDocumentCurrent(
    int operationRevision,
    ActiveDocumentSaveTarget target,
  ) {
    final workspace = state.workspace;
    return _isCurrentActiveDocument(
          operationRevision,
          workspaceId: target.workspaceId,
          activeFilePath: target.path,
        ) &&
        workspace != null &&
        _sameFileSnapshot(workspace.activeFileSnapshot, target.snapshot);
  }

  bool _sameSaveTarget(
    ActiveDocumentSaveTarget? first,
    ActiveDocumentSaveTarget second,
  ) {
    return first != null &&
        first.workspaceId == second.workspaceId &&
        first.path == second.path &&
        first.documentRevision == second.documentRevision &&
        first.editRevision == second.editRevision &&
        first.text == second.text &&
        first.workspaceKind == second.workspaceKind &&
        _sameFileSnapshot(first.snapshot, second.snapshot);
  }

  ActiveDocumentSaveTarget? _refreshActiveDocumentSaveTarget(
    ActiveDocumentSaveTarget target,
  ) {
    final workspace = state.workspace;
    if (!_isCurrentActiveDocument(
          target.documentRevision,
          workspaceId: target.workspaceId,
          activeFilePath: target.path,
        ) ||
        workspace == null ||
        _editRevision != target.editRevision ||
        state.activeText != target.text ||
        workspace.kind != target.workspaceKind) {
      return null;
    }
    return ActiveDocumentSaveTarget._(
      workspaceId: target.workspaceId,
      path: target.path,
      documentRevision: target.documentRevision,
      editRevision: target.editRevision,
      snapshot: workspace.activeFileSnapshot,
      text: target.text,
      workspaceKind: target.workspaceKind,
    );
  }
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
