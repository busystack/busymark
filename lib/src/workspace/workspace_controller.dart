import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_settings.dart';
import '../markdown/preview_export.dart';
import '../writerside/writerside_module_service.dart';
import 'workspace_model.dart';
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

  Future<void> openPath(String path) async {
    state = state.copyWith(isLoading: true, clearError: true);
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
    } on Object catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Open failed: $error',
      );
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
      final nextWorkspace = workspace.copyWith(activeFilePath: path);
      final reparsed = await _service.reparseActive(nextWorkspace, text);
      state = state.copyWith(
        workspace: reparsed,
        activeText: text,
        preview: _safePreview(reparsed, text),
        isDirty: false,
        clearError: true,
      );
    } on Object catch (error) {
      state = state.copyWith(errorMessage: 'Could not open file: $error');
    }
  }

  void updateActiveText(String text) {
    state = state.copyWith(activeText: text, isDirty: true);
    _parseDebounce?.cancel();
    _parseDebounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(validateActive());
    });
  }

  Future<void> saveActive() async {
    final workspace = state.workspace;
    final active = workspace?.activeFilePath;
    if (active == null) {
      return;
    }
    try {
      await _service.saveText(active, state.activeText);
      final reparsed = await _service.reparseActive(
        workspace!,
        state.activeText,
      );
      state = state.copyWith(
        workspace: reparsed,
        preview: _safePreview(reparsed, state.activeText),
        isDirty: false,
        clearError: true,
      );
    } on Object catch (error) {
      state = state.copyWith(errorMessage: 'Save failed: $error');
    }
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
        clearError: true,
      );
    } on Object catch (error) {
      state = state.copyWith(errorMessage: 'Validation failed: $error');
    }
  }

  String exportActiveHtml() {
    final workspace = state.workspace;
    final active = workspace?.activeFilePath;
    if (workspace == null || active == null) {
      return '';
    }
    final markdown = _service.markdownParser.parse(
      filePath: active,
      source: state.activeText,
      workspaceRoot: workspace.rootPath,
    );
    return const MarkdownHtmlExporter().export(markdown);
  }

  String exportProjectSummaryJson() {
    final module = state.workspace?.writersideModule;
    if (module == null) {
      return '{}';
    }
    return const WritersideSummaryExporter().export(module);
  }

  String exportDiagnosticsJson() {
    return const DiagnosticReportExporter().exportJson(
      state.workspace?.diagnostics ?? const [],
    );
  }

  PreviewDocument? _safePreview(Workspace workspace, String text) {
    try {
      return _service.buildPreview(workspace, text);
    } on Object {
      return PreviewDocument(
        title: 'Source fallback',
        modeLabel: 'Preview',
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
