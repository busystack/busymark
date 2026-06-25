import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_settings.dart';
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
    StateNotifierProvider<WorkspaceController, WorkspaceState>((ref) {
      return WorkspaceController(
        service: ref.watch(workspaceServiceProvider),
        settingsController: ref.watch(appSettingsControllerProvider.notifier),
      );
    });

final workspaceSearchOpenRequestProvider = StateProvider<int>((ref) => 0);

final workspaceSearchCloseRequestProvider = StateProvider<int>((ref) => 0);

class WorkspaceController extends StateNotifier<WorkspaceState> {
  WorkspaceController({
    required WorkspaceService service,
    required AppSettingsController settingsController,
  }) : _service = service,
       _settingsController = settingsController,
       super(const WorkspaceState());

  final WorkspaceService _service;
  final AppSettingsController _settingsController;
  Timer? _parseDebounce;

  bool get activeDocumentNeedsSaveLocation {
    final workspace = state.workspace;
    return workspace != null &&
        (workspace.kind == WorkspaceKind.untitledMarkdown ||
            workspace.activeFilePath == null);
  }

  Future<void> createMarkdownFile() async {
    _parseDebounce?.cancel();
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
    state = const WorkspaceState(isLoading: true);
    try {
      final workspace = await _service.openPath(path);
      final active = workspace.activeFilePath;
      final text = active == null ? '' : await _service.loadText(active);
      final preview = _safePreview(workspace, text);
      state = WorkspaceState(
        workspace: workspace,
        activeText: text,
        preview: preview,
      );
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
      state = state.copyWith(
        isLoading: false,
        message: WorkspaceMessage(
          WorkspaceMessageCode.openFailed,
          error: error,
        ),
      );
    }
  }

  Future<bool> createWritersideProject(
    WritersideProjectCreateRequest request,
  ) async {
    _parseDebounce?.cancel();
    state = const WorkspaceState(isLoading: true);
    try {
      final workspace = await _service.createWritersideProject(request);
      final active = workspace.activeFilePath;
      final text = active == null ? '' : await _service.loadText(active);
      final preview = _safePreview(workspace, text);
      state = WorkspaceState(
        workspace: workspace,
        activeText: text,
        preview: preview,
      );
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
      state = state.copyWith(
        isLoading: false,
        message: WorkspaceMessage(
          WorkspaceMessageCode.createWritersideProjectFailed,
          error: error,
        ),
      );
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
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      final nextWorkspace = await _service.createWritersideTopic(
        workspace,
        request,
      );
      final active = nextWorkspace.activeFilePath;
      final text = active == null ? '' : await _service.loadText(active);
      state = WorkspaceState(
        workspace: nextWorkspace,
        activeText: text,
        preview: _safePreview(nextWorkspace, text),
      );
      return true;
    } on Object catch (error, stackTrace) {
      stderr.writeln('[BusyMark] Create Writerside topic failed');
      stderr.writeln('[BusyMark]   title: ${request.title}');
      stderr.writeln('[BusyMark]   file name: ${request.fileName}');
      stderr.writeln('[BusyMark]   error: $error');
      stderr.writeln('[BusyMark]   stack trace:\n$stackTrace');
      state = state.copyWith(
        isLoading: false,
        message: WorkspaceMessage(
          WorkspaceMessageCode.createWritersideTopicFailed,
          error: error,
        ),
      );
      return false;
    }
  }

  Future<void> openFile(String path) => openPath(path);

  Future<void> openFolder(String path) => openPath(path);

  Future<void> openActiveFile(String path) async {
    final workspace = state.workspace;
    if (workspace == null) {
      return;
    }
    _parseDebounce?.cancel();
    try {
      final text = await File(path).readAsString();
      final nextWorkspace = workspace.copyWith(
        activeFilePath: path,
        activeFileModifiedAt: await _service.fileModifiedAt(path),
      );
      final reparsed = await _service.reparseActive(nextWorkspace, text);
      state = state.copyWith(
        workspace: reparsed,
        activeText: text,
        preview: _safePreview(reparsed, text),
        isDirty: false,
        clearMessage: true,
      );
    } on Object catch (error, stackTrace) {
      stderr.writeln('[BusyMark] Could not open file: $path');
      stderr.writeln('[BusyMark]   error: $error');
      stderr.writeln('[BusyMark]   stack trace:\n$stackTrace');
      state = state.copyWith(
        message: WorkspaceMessage(
          WorkspaceMessageCode.couldNotOpenFile,
          error: error,
        ),
      );
    }
  }

  void updateActiveText(String text, {bool updatePreview = true}) {
    final workspace = state.workspace;
    state = state.copyWith(
      activeText: text,
      preview: workspace == null || !updatePreview
          ? state.preview
          : _safePreview(workspace, text),
      isDirty: true,
    );
    _parseDebounce?.cancel();
    if (!_settingsController.state.validateOnEdit) {
      return;
    }
    _parseDebounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(validateActive());
    });
  }

  Future<bool> saveActive({bool overwriteExternalChanges = false}) async {
    final workspace = state.workspace;
    final active = workspace?.activeFilePath;
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
          workspace?.activeFileModifiedAt,
        )) {
      state = state.copyWith(
        message: const WorkspaceMessage(
          WorkspaceMessageCode.saveBlockedFileChangedOnDisk,
        ),
      );
      return false;
    }
    try {
      final modifiedAt = await _service.saveText(active, state.activeText);
      final reparsed = await _service.reparseActive(
        workspace!.copyWith(activeFileModifiedAt: modifiedAt),
        state.activeText,
      );
      state = state.copyWith(
        workspace: reparsed.copyWith(activeFileModifiedAt: modifiedAt),
        preview: _safePreview(reparsed, state.activeText),
        isDirty: false,
        clearMessage: true,
      );
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

  Future<bool> saveActiveAs(String path) async {
    final workspace = state.workspace;
    if (workspace == null) {
      return false;
    }
    final text = state.activeText;
    try {
      await _service.saveText(path, text);
      final savedWorkspace = await _service.openPath(path);
      state = WorkspaceState(
        workspace: savedWorkspace,
        activeText: text,
        preview: _safePreview(savedWorkspace, text),
      );
      await _settingsController.recordOpenedWorkspace(
        path: path,
        kind: savedWorkspace.kind.name,
      );
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

  Future<bool> activeFileChangedOnDisk() async {
    final workspace = state.workspace;
    final active = workspace?.activeFilePath;
    if (active == null) {
      return false;
    }
    return _service.fileChangedSince(active, workspace?.activeFileModifiedAt);
  }

  Future<void> validateActive() async {
    final workspace = state.workspace;
    if (workspace == null) {
      return;
    }
    try {
      final reparsed = await _service.reparseActive(
        workspace,
        state.activeText,
      );
      state = state.copyWith(
        workspace: reparsed,
        preview: _safePreview(reparsed, state.activeText),
        clearMessage: true,
      );
    } on Object catch (error) {
      state = state.copyWith(
        message: WorkspaceMessage(
          WorkspaceMessageCode.validationFailed,
          error: error,
        ),
      );
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

  @override
  void dispose() {
    _parseDebounce?.cancel();
    super.dispose();
  }
}
