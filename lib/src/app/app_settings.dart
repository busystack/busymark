import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_locale.dart';

enum BusyMarkThemeModePreference { system, light, dark }

enum DocumentViewModePreference { editor, source, preview, split }

enum AiProviderPreference { disabled, ollamaLocal, openAi, gemini }

enum AiModelRoutingPreference { automatic, fixed }

enum EditorToolbarPlacement { topLeft, topRight, bottomLeft, bottomRight }

enum EditorToolbarDirection { horizontal, vertical }

enum WritersideInstanceIconColor {
  automatic,
  blue,
  green,
  orange,
  purple,
  red,
  teal,
  yellow,
}

const Object _unset = Object();

extension BusyMarkThemeModePreferenceX on BusyMarkThemeModePreference {
  ThemeMode get themeMode {
    return switch (this) {
      BusyMarkThemeModePreference.system => ThemeMode.system,
      BusyMarkThemeModePreference.light => ThemeMode.light,
      BusyMarkThemeModePreference.dark => ThemeMode.dark,
    };
  }
}

class RecentWorkspace {
  const RecentWorkspace({
    required this.path,
    required this.kind,
    required this.lastOpenedAt,
  });

  factory RecentWorkspace.fromJson(Map<String, Object?> json) {
    return RecentWorkspace(
      path: json['path']?.toString() ?? '',
      kind: json['kind']?.toString() ?? 'unknown',
      lastOpenedAt:
          DateTime.tryParse(json['lastOpenedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final String path;
  final String kind;
  final DateTime lastOpenedAt;

  Map<String, Object?> toJson() => {
    'path': path,
    'kind': kind,
    'lastOpenedAt': lastOpenedAt.toIso8601String(),
  };
}

class AppSettings {
  const AppSettings({
    required this.themeModePreference,
    required this.localeTag,
    required this.sidebarVisible,
    required this.previewVisible,
    required this.documentViewMode,
    required this.editorFontSize,
    required this.wordWrap,
    required this.editorToolbarPlacement,
    required this.editorToolbarDirection,
    required this.autoSave,
    required this.validateOnEdit,
    required this.aiProviderPreference,
    required this.aiOllamaEndpoint,
    required this.aiOllamaModel,
    required this.aiOpenAiModel,
    required this.aiGeminiModel,
    required this.aiModelRoutingPreference,
    required this.aiCloudProviderConsentIds,
    required this.allowRemoteImages,
    required this.remoteImageAllowedWorkspacePaths,
    required this.trustedGitWorkspacePaths,
    required this.selectedWritersideInstanceIds,
    required this.writersideInstanceIconColors,
    required this.confirmCloseWithUnsavedChanges,
    required this.recentWorkspaces,
    this.lastOpenedPath,
  });

  factory AppSettings.defaults() {
    return const AppSettings(
      themeModePreference: BusyMarkThemeModePreference.system,
      localeTag: null,
      sidebarVisible: true,
      previewVisible: true,
      documentViewMode: DocumentViewModePreference.split,
      editorFontSize: 14,
      wordWrap: true,
      editorToolbarPlacement: EditorToolbarPlacement.topLeft,
      editorToolbarDirection: EditorToolbarDirection.horizontal,
      autoSave: true,
      validateOnEdit: true,
      aiProviderPreference: AiProviderPreference.disabled,
      aiOllamaEndpoint: 'http://127.0.0.1:11434',
      aiOllamaModel: '',
      aiOpenAiModel: 'gpt-5.6-terra',
      aiGeminiModel: 'gemini-3.6-flash',
      aiModelRoutingPreference: AiModelRoutingPreference.automatic,
      aiCloudProviderConsentIds: [],
      allowRemoteImages: false,
      remoteImageAllowedWorkspacePaths: [],
      trustedGitWorkspacePaths: [],
      selectedWritersideInstanceIds: {},
      writersideInstanceIconColors: {},
      confirmCloseWithUnsavedChanges: true,
      recentWorkspaces: [],
    );
  }

  factory AppSettings.fromJson(Map<String, Object?> json) {
    final defaults = AppSettings.defaults();
    final recent = json['recentWorkspaces'];
    final storedPreviewVisible = json['previewVisible'] as bool?;
    final documentViewMode = _enumFromName(
      DocumentViewModePreference.values,
      json['documentViewMode'],
      storedPreviewVisible == false
          ? DocumentViewModePreference.source
          : defaults.documentViewMode,
    );
    return AppSettings(
      themeModePreference: _enumFromName(
        BusyMarkThemeModePreference.values,
        json['themeModePreference'],
        defaults.themeModePreference,
      ),
      localeTag: normalizeBusyMarkLocaleTag(json['localeTag']?.toString()),
      sidebarVisible:
          json['sidebarVisible'] as bool? ?? defaults.sidebarVisible,
      previewVisible: documentViewMode != DocumentViewModePreference.source,
      documentViewMode: documentViewMode,
      editorFontSize:
          (json['editorFontSize'] as num?)?.toDouble() ??
          defaults.editorFontSize,
      wordWrap: json['wordWrap'] as bool? ?? defaults.wordWrap,
      editorToolbarPlacement: _enumFromName(
        EditorToolbarPlacement.values,
        json['editorToolbarPlacement'],
        defaults.editorToolbarPlacement,
      ),
      editorToolbarDirection: _enumFromName(
        EditorToolbarDirection.values,
        json['editorToolbarDirection'],
        defaults.editorToolbarDirection,
      ),
      autoSave: json['autoSave'] as bool? ?? defaults.autoSave,
      validateOnEdit:
          json['validateOnEdit'] as bool? ?? defaults.validateOnEdit,
      aiProviderPreference: _enumFromName(
        AiProviderPreference.values,
        json['aiProviderPreference'],
        defaults.aiProviderPreference,
      ),
      aiOllamaEndpoint:
          json['aiOllamaEndpoint']?.toString() ?? defaults.aiOllamaEndpoint,
      aiOllamaModel:
          json['aiOllamaModel']?.toString() ?? defaults.aiOllamaModel,
      aiOpenAiModel:
          json['aiOpenAiModel']?.toString() ?? defaults.aiOpenAiModel,
      aiGeminiModel:
          json['aiGeminiModel']?.toString() ?? defaults.aiGeminiModel,
      aiModelRoutingPreference: _enumFromName(
        AiModelRoutingPreference.values,
        json['aiModelRoutingPreference'],
        defaults.aiModelRoutingPreference,
      ),
      aiCloudProviderConsentIds: _stringListFromJson(
        json['aiCloudProviderConsentIds'],
      ),
      allowRemoteImages:
          json['allowRemoteImages'] as bool? ?? defaults.allowRemoteImages,
      remoteImageAllowedWorkspacePaths: _workspacePathListFromJson(
        json['remoteImageAllowedWorkspacePaths'],
      ),
      trustedGitWorkspacePaths: _gitWorkspacePathListFromJson(
        json['trustedGitWorkspacePaths'],
      ),
      selectedWritersideInstanceIds: _stringMapFromJson(
        json['selectedWritersideInstanceIds'],
      ),
      writersideInstanceIconColors: _stringMapFromJson(
        json['writersideInstanceIconColors'],
      ),
      confirmCloseWithUnsavedChanges:
          json['confirmCloseWithUnsavedChanges'] as bool? ??
          defaults.confirmCloseWithUnsavedChanges,
      lastOpenedPath: json['lastOpenedPath']?.toString(),
      recentWorkspaces: recent is List
          ? recent
                .whereType<Map>()
                .map((item) => item.cast<String, Object?>())
                .map(RecentWorkspace.fromJson)
                .where((item) => item.path.isNotEmpty)
                .toList()
          : defaults.recentWorkspaces,
    );
  }

  final BusyMarkThemeModePreference themeModePreference;
  final String? localeTag;
  final bool sidebarVisible;
  final bool previewVisible;
  final DocumentViewModePreference documentViewMode;
  final double editorFontSize;
  final bool wordWrap;
  final EditorToolbarPlacement editorToolbarPlacement;
  final EditorToolbarDirection editorToolbarDirection;
  final bool autoSave;
  final bool validateOnEdit;
  final AiProviderPreference aiProviderPreference;
  final String aiOllamaEndpoint;
  final String aiOllamaModel;
  final String aiOpenAiModel;
  final String aiGeminiModel;
  final AiModelRoutingPreference aiModelRoutingPreference;
  final List<String> aiCloudProviderConsentIds;
  final bool allowRemoteImages;
  final List<String> remoteImageAllowedWorkspacePaths;
  final List<String> trustedGitWorkspacePaths;
  final Map<String, String> selectedWritersideInstanceIds;
  final Map<String, String> writersideInstanceIconColors;
  final bool confirmCloseWithUnsavedChanges;
  final String? lastOpenedPath;
  final List<RecentWorkspace> recentWorkspaces;

  ThemeMode get themeMode => themeModePreference.themeMode;

  Locale? get locale => busyMarkLocaleFromTag(localeTag);

  Map<String, Object?> toJson() => {
    'themeModePreference': themeModePreference.name,
    'localeTag': localeTag,
    'sidebarVisible': sidebarVisible,
    'previewVisible': previewVisible,
    'documentViewMode': documentViewMode.name,
    'editorFontSize': editorFontSize,
    'wordWrap': wordWrap,
    'editorToolbarPlacement': editorToolbarPlacement.name,
    'editorToolbarDirection': editorToolbarDirection.name,
    'autoSave': autoSave,
    'validateOnEdit': validateOnEdit,
    'aiProviderPreference': aiProviderPreference.name,
    'aiOllamaEndpoint': aiOllamaEndpoint,
    'aiOllamaModel': aiOllamaModel,
    'aiOpenAiModel': aiOpenAiModel,
    'aiGeminiModel': aiGeminiModel,
    'aiModelRoutingPreference': aiModelRoutingPreference.name,
    'aiCloudProviderConsentIds': aiCloudProviderConsentIds,
    'allowRemoteImages': allowRemoteImages,
    'remoteImageAllowedWorkspacePaths': remoteImageAllowedWorkspacePaths,
    'trustedGitWorkspacePaths': trustedGitWorkspacePaths,
    'selectedWritersideInstanceIds': selectedWritersideInstanceIds,
    'writersideInstanceIconColors': writersideInstanceIconColors,
    'confirmCloseWithUnsavedChanges': confirmCloseWithUnsavedChanges,
    'lastOpenedPath': lastOpenedPath,
    'recentWorkspaces': recentWorkspaces.map((item) => item.toJson()).toList(),
  };

  bool allowsRemoteImagesForWorkspace(String? workspacePath) {
    if (allowRemoteImages) {
      return true;
    }
    final key = _normalizedWorkspacePath(workspacePath);
    return key != null && remoteImageAllowedWorkspacePaths.contains(key);
  }

  bool trustsGitWorkspace(String? workspacePath) {
    return trustedGitWorkspacePath(workspacePath) != null;
  }

  String? selectedWritersideInstanceId(String workspacePath) {
    return selectedWritersideInstanceIds[_normalizedWorkspacePath(
      workspacePath,
    )];
  }

  WritersideInstanceIconColor writersideInstanceIconColor(
    String workspacePath,
    String instanceId,
  ) {
    final workspace = _normalizedWorkspacePath(workspacePath);
    if (workspace == null) {
      return WritersideInstanceIconColor.automatic;
    }
    return _enumFromName(
      WritersideInstanceIconColor.values,
      writersideInstanceIconColors['$workspace::$instanceId'],
      WritersideInstanceIconColor.automatic,
    );
  }

  /// Returns the canonical, trusted path that is safe to pass to Git.
  ///
  /// Callers should use this returned value for command execution instead of
  /// resolving [workspacePath] again after the trust check.
  String? trustedGitWorkspacePath(String? workspacePath) {
    final key = _normalizedGitWorkspacePath(workspacePath);
    return key != null && trustedGitWorkspacePaths.contains(key) ? key : null;
  }

  AppSettings copyWith({
    BusyMarkThemeModePreference? themeModePreference,
    Object? localeTag = _unset,
    bool? sidebarVisible,
    bool? previewVisible,
    DocumentViewModePreference? documentViewMode,
    double? editorFontSize,
    bool? wordWrap,
    EditorToolbarPlacement? editorToolbarPlacement,
    EditorToolbarDirection? editorToolbarDirection,
    bool? autoSave,
    bool? validateOnEdit,
    AiProviderPreference? aiProviderPreference,
    String? aiOllamaEndpoint,
    String? aiOllamaModel,
    String? aiOpenAiModel,
    String? aiGeminiModel,
    AiModelRoutingPreference? aiModelRoutingPreference,
    List<String>? aiCloudProviderConsentIds,
    bool? allowRemoteImages,
    List<String>? remoteImageAllowedWorkspacePaths,
    List<String>? trustedGitWorkspacePaths,
    Map<String, String>? selectedWritersideInstanceIds,
    Map<String, String>? writersideInstanceIconColors,
    bool? confirmCloseWithUnsavedChanges,
    String? lastOpenedPath,
    List<RecentWorkspace>? recentWorkspaces,
  }) {
    return AppSettings(
      themeModePreference: themeModePreference ?? this.themeModePreference,
      localeTag: identical(localeTag, _unset)
          ? this.localeTag
          : normalizeBusyMarkLocaleTag(localeTag as String?),
      sidebarVisible: sidebarVisible ?? this.sidebarVisible,
      previewVisible: previewVisible ?? this.previewVisible,
      documentViewMode: documentViewMode ?? this.documentViewMode,
      editorFontSize: editorFontSize ?? this.editorFontSize,
      wordWrap: wordWrap ?? this.wordWrap,
      editorToolbarPlacement:
          editorToolbarPlacement ?? this.editorToolbarPlacement,
      editorToolbarDirection:
          editorToolbarDirection ?? this.editorToolbarDirection,
      autoSave: autoSave ?? this.autoSave,
      validateOnEdit: validateOnEdit ?? this.validateOnEdit,
      aiProviderPreference: aiProviderPreference ?? this.aiProviderPreference,
      aiOllamaEndpoint: aiOllamaEndpoint ?? this.aiOllamaEndpoint,
      aiOllamaModel: aiOllamaModel ?? this.aiOllamaModel,
      aiOpenAiModel: aiOpenAiModel ?? this.aiOpenAiModel,
      aiGeminiModel: aiGeminiModel ?? this.aiGeminiModel,
      aiModelRoutingPreference:
          aiModelRoutingPreference ?? this.aiModelRoutingPreference,
      aiCloudProviderConsentIds:
          aiCloudProviderConsentIds ?? this.aiCloudProviderConsentIds,
      allowRemoteImages: allowRemoteImages ?? this.allowRemoteImages,
      remoteImageAllowedWorkspacePaths:
          remoteImageAllowedWorkspacePaths ??
          this.remoteImageAllowedWorkspacePaths,
      trustedGitWorkspacePaths:
          trustedGitWorkspacePaths ?? this.trustedGitWorkspacePaths,
      selectedWritersideInstanceIds:
          selectedWritersideInstanceIds ?? this.selectedWritersideInstanceIds,
      writersideInstanceIconColors:
          writersideInstanceIconColors ?? this.writersideInstanceIconColors,
      confirmCloseWithUnsavedChanges:
          confirmCloseWithUnsavedChanges ?? this.confirmCloseWithUnsavedChanges,
      lastOpenedPath: lastOpenedPath ?? this.lastOpenedPath,
      recentWorkspaces: recentWorkspaces ?? this.recentWorkspaces,
    );
  }
}

abstract class LocalSettingsStore {
  Future<Map<String, Object?>> load();
  Future<void> save(Map<String, Object?> json);
}

class JsonFileLocalSettingsStore implements LocalSettingsStore {
  const JsonFileLocalSettingsStore({
    String? settingsFilePathOverride,
    Future<void> Function(File stagedFile, File targetFile)? beforePublish,
  }) : _settingsFilePathOverride = settingsFilePathOverride,
       _beforePublish = beforePublish;

  final String? _settingsFilePathOverride;
  final Future<void> Function(File stagedFile, File targetFile)? _beforePublish;

  @override
  Future<Map<String, Object?>> load() async {
    final file = await _settingsFile();
    if (!await file.exists()) {
      return <String, Object?>{};
    }
    final content = await file.readAsString();
    if (content.trim().isEmpty) {
      return <String, Object?>{};
    }
    return (jsonDecode(content) as Map).cast<String, Object?>();
  }

  @override
  Future<void> save(Map<String, Object?> json) async {
    final file = await _settingsFile();
    final content = const JsonEncoder.withIndent('  ').convert(json);
    await file.parent.create(recursive: true);
    // Keep staging on the target filesystem so publication is one atomic
    // directory-entry replacement after the complete JSON has been flushed.
    final stagingDirectory = await file.parent.createTemp(
      '.busymark-settings-',
    );
    final stagedFile = File(p.join(stagingDirectory.path, 'settings.json'));
    try {
      await stagedFile.writeAsString(content, flush: true);
      await _beforePublish?.call(stagedFile, file);
      await stagedFile.rename(file.path);
    } finally {
      try {
        if (await stagedFile.exists()) {
          await stagedFile.delete();
        }
      } on Object {
        // Cleanup must not hide the original save result or error.
      }
      try {
        if (await stagingDirectory.exists()) {
          await stagingDirectory.delete(recursive: true);
        }
      } on Object {
        // Cleanup must not turn a successful atomic replacement into a failure.
      }
    }
  }

  Future<File> _settingsFile() async {
    final override = _settingsFilePathOverride;
    if (override != null) {
      return File(override);
    }
    final directory = await getApplicationSupportDirectory();
    return File(p.join(directory.path, 'settings.json'));
  }
}

class AppSettingsController extends Notifier<AppSettings> {
  late LocalSettingsStore _store;
  Future<void>? _lastSave;
  final _pendingInitialMutations = <AppSettings Function(AppSettings)>[];
  var _loaded = false;

  @override
  AppSettings build() {
    _store = ref.read(localSettingsStoreProvider);
    unawaited(_load());
    return AppSettings.defaults();
  }

  Future<void> setThemeModePreference(BusyMarkThemeModePreference preference) {
    return _mutate(
      (settings) => settings.copyWith(themeModePreference: preference),
    );
  }

  Future<void> setLocaleTag(String? localeTag) {
    return _mutate(
      (settings) =>
          settings.copyWith(localeTag: normalizeBusyMarkLocaleTag(localeTag)),
    );
  }

  Future<void> setEditorFontSize(double size) {
    return _mutate(
      (settings) => settings.copyWith(editorFontSize: size.clamp(11, 24)),
    );
  }

  Future<void> setWordWrap(bool enabled) {
    return _mutate((settings) => settings.copyWith(wordWrap: enabled));
  }

  Future<void> setEditorToolbarPlacement(EditorToolbarPlacement placement) {
    return _mutate(
      (settings) => settings.copyWith(editorToolbarPlacement: placement),
    );
  }

  Future<void> setEditorToolbarDirection(EditorToolbarDirection direction) {
    return _mutate(
      (settings) => settings.copyWith(editorToolbarDirection: direction),
    );
  }

  Future<void> setAutoSave(bool enabled) {
    return _mutate((settings) => settings.copyWith(autoSave: enabled));
  }

  Future<void> setPreviewVisible(bool enabled) {
    return setDocumentViewMode(
      enabled
          ? DocumentViewModePreference.split
          : DocumentViewModePreference.source,
    );
  }

  Future<void> setDocumentViewMode(DocumentViewModePreference mode) {
    return _mutate(
      (settings) => settings.copyWith(
        documentViewMode: mode,
        previewVisible: mode != DocumentViewModePreference.source,
      ),
    );
  }

  Future<void> setSidebarVisible(bool enabled) {
    return _mutate((settings) => settings.copyWith(sidebarVisible: enabled));
  }

  Future<void> setValidateOnEdit(bool enabled) {
    return _mutate((settings) => settings.copyWith(validateOnEdit: enabled));
  }

  Future<void> setAiProviderPreference(AiProviderPreference preference) {
    return _mutate(
      (settings) => settings.copyWith(aiProviderPreference: preference),
    );
  }

  Future<void> setAiOllamaEndpoint(String endpoint) {
    return _mutate(
      (settings) => settings.copyWith(aiOllamaEndpoint: endpoint.trim()),
    );
  }

  Future<void> setAiOllamaModel(String model) {
    return _mutate(
      (settings) => settings.copyWith(aiOllamaModel: model.trim()),
    );
  }

  Future<void> setAiOpenAiModel(String model) {
    return _mutate(
      (settings) => settings.copyWith(aiOpenAiModel: model.trim()),
    );
  }

  Future<void> setAiGeminiModel(String model) {
    return _mutate(
      (settings) => settings.copyWith(aiGeminiModel: model.trim()),
    );
  }

  Future<void> setAiModelRoutingPreference(
    AiModelRoutingPreference preference,
  ) {
    return _mutate(
      (settings) => settings.copyWith(aiModelRoutingPreference: preference),
    );
  }

  Future<void> grantAiCloudProviderConsent(String providerId) {
    final normalized = providerId.trim();
    if (normalized.isEmpty) {
      return Future<void>.value();
    }
    return _mutate((settings) {
      final ids = {normalized, ...settings.aiCloudProviderConsentIds}.toList()
        ..sort();
      return settings.copyWith(aiCloudProviderConsentIds: ids);
    });
  }

  Future<void> setAllowRemoteImages(bool enabled) {
    return _mutate((settings) => settings.copyWith(allowRemoteImages: enabled));
  }

  Future<void> allowRemoteImagesForWorkspace(String workspacePath) {
    final key = _normalizedWorkspacePath(workspacePath);
    if (key == null) {
      return Future<void>.value();
    }
    return _mutate((settings) {
      final allowed = {
        key,
        ...settings.remoteImageAllowedWorkspacePaths,
      }.toList()..sort();
      return settings.copyWith(remoteImageAllowedWorkspacePaths: allowed);
    });
  }

  Future<void> clearRemoteImageWorkspacePermissions() {
    return _mutate(
      (settings) => settings.copyWith(remoteImageAllowedWorkspacePaths: []),
    );
  }

  Future<void> trustGitWorkspace(String workspacePath) {
    final key = _normalizedGitWorkspacePath(workspacePath);
    if (key == null) {
      return Future<void>.value();
    }
    return _mutate((settings) {
      final trusted = {key, ...settings.trustedGitWorkspacePaths}.toList()
        ..sort();
      return settings.copyWith(trustedGitWorkspacePaths: trusted);
    });
  }

  Future<void> clearTrustedGitWorkspaces() {
    return _mutate(
      (settings) => settings.copyWith(trustedGitWorkspacePaths: []),
    );
  }

  Future<void> selectWritersideInstance(
    String workspacePath,
    String instanceId,
  ) {
    final workspace = _normalizedWorkspacePath(workspacePath);
    final id = instanceId.trim();
    if (workspace == null || id.isEmpty) {
      return Future<void>.value();
    }
    return _mutate((settings) {
      final selected = Map<String, String>.of(
        settings.selectedWritersideInstanceIds,
      )..[workspace] = id;
      return settings.copyWith(selectedWritersideInstanceIds: selected);
    });
  }

  Future<void> setWritersideInstanceIconColor(
    String workspacePath,
    String instanceId,
    WritersideInstanceIconColor color,
  ) {
    final workspace = _normalizedWorkspacePath(workspacePath);
    final id = instanceId.trim();
    if (workspace == null || id.isEmpty) {
      return Future<void>.value();
    }
    return _mutate((settings) {
      final colors = Map<String, String>.of(
        settings.writersideInstanceIconColors,
      );
      final key = '$workspace::$id';
      if (color == WritersideInstanceIconColor.automatic) {
        colors.remove(key);
      } else {
        colors[key] = color.name;
      }
      return settings.copyWith(writersideInstanceIconColors: colors);
    });
  }

  Future<void> renameWritersideInstancePreferences(
    String workspacePath,
    String oldId,
    String newId,
  ) {
    final workspace = _normalizedWorkspacePath(workspacePath);
    if (workspace == null || oldId == newId) {
      return Future<void>.value();
    }
    return _mutate((settings) {
      final selected = Map<String, String>.of(
        settings.selectedWritersideInstanceIds,
      );
      if (selected[workspace] == oldId) {
        selected[workspace] = newId;
      }
      final colors = Map<String, String>.of(
        settings.writersideInstanceIconColors,
      );
      final oldKey = '$workspace::$oldId';
      final color = colors.remove(oldKey);
      if (color != null) {
        colors['$workspace::$newId'] = color;
      }
      return settings.copyWith(
        selectedWritersideInstanceIds: selected,
        writersideInstanceIconColors: colors,
      );
    });
  }

  Future<void> setConfirmCloseWithUnsavedChanges(bool enabled) {
    return _mutate(
      (settings) => settings.copyWith(confirmCloseWithUnsavedChanges: enabled),
    );
  }

  Future<void> recordOpenedWorkspace({
    required String path,
    required String kind,
  }) {
    final openedAt = DateTime.now();
    return _mutate((settings) {
      final recent = [
        RecentWorkspace(path: path, kind: kind, lastOpenedAt: openedAt),
        ...settings.recentWorkspaces.where((item) => item.path != path),
      ].take(12).toList();
      return settings.copyWith(lastOpenedPath: path, recentWorkspaces: recent);
    });
  }

  Future<void> clearRecentWorkspaces() {
    return _mutate((settings) => settings.copyWith(recentWorkspaces: []));
  }

  Future<void> _load() async {
    AppSettings loaded;
    try {
      loaded = AppSettings.fromJson(await _store.load());
    } on Object {
      loaded = AppSettings.defaults();
    }
    final hadPendingInitialMutations = _pendingInitialMutations.isNotEmpty;
    for (final mutation in _pendingInitialMutations) {
      loaded = mutation(loaded);
    }
    _pendingInitialMutations.clear();
    _loaded = true;
    state = loaded;
    if (hadPendingInitialMutations) {
      await _save(loaded);
    }
  }

  Future<void> _mutate(AppSettings Function(AppSettings) mutation) {
    if (!_loaded) {
      _pendingInitialMutations.add(mutation);
      state = mutation(state);
      return Future<void>.value();
    }
    return _save(mutation(state));
  }

  Future<void> _save(AppSettings next) async {
    state = next;
    final json = next.toJson();
    final previousSave = _lastSave;
    final save = () async {
      await previousSave;
      try {
        await _store.save(json);
      } on Object {
        // Keep the in-memory preference even when local persistence is unavailable.
      }
    }();
    _lastSave = save;
    await save;
  }
}

final localSettingsStoreProvider = Provider<LocalSettingsStore>(
  (ref) => const JsonFileLocalSettingsStore(),
);

final appSettingsControllerProvider =
    NotifierProvider<AppSettingsController, AppSettings>(
      AppSettingsController.new,
    );

T _enumFromName<T extends Enum>(List<T> values, Object? name, T fallback) {
  if (name == null) {
    return fallback;
  }
  for (final value in values) {
    if (value.name == name.toString()) {
      return value;
    }
  }
  return fallback;
}

List<String> _workspacePathListFromJson(Object? value) {
  if (value is! List) {
    return const [];
  }
  final paths = {
    for (final item in value)
      if (_normalizedWorkspacePath(item?.toString()) case final path?) path,
  }.toList()..sort();
  return paths;
}

List<String> _gitWorkspacePathListFromJson(Object? value) {
  if (value is! List) {
    return const [];
  }
  final paths = {
    for (final item in value)
      if (_normalizedStoredGitWorkspacePath(item?.toString()) case final path?)
        path,
  }.toList()..sort();
  return paths;
}

Map<String, String> _stringMapFromJson(Object? value) {
  if (value is! Map) {
    return const {};
  }
  return Map.unmodifiable({
    for (final entry in value.entries)
      if (entry.key.toString().trim().isNotEmpty &&
          entry.value.toString().trim().isNotEmpty)
        entry.key.toString(): entry.value.toString(),
  });
}

List<String> _stringListFromJson(Object? value) {
  if (value is! List) {
    return const [];
  }
  final values = {
    for (final item in value)
      if ((item?.toString().trim() ?? '').isNotEmpty) item.toString().trim(),
  }.toList()..sort();
  return values;
}

String? _normalizedWorkspacePath(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return p.normalize(trimmed);
}

String? _normalizedGitWorkspacePath(String? value) {
  final absolute = _normalizedStoredGitWorkspacePath(value);
  if (absolute == null) {
    return null;
  }
  try {
    final type = FileSystemEntity.typeSync(absolute, followLinks: false);
    final entity = switch (type) {
      FileSystemEntityType.directory => Directory(absolute),
      FileSystemEntityType.link => Link(absolute),
      FileSystemEntityType.file => File(absolute),
      _ => null,
    };
    return entity == null
        ? absolute
        : p.normalize(entity.resolveSymbolicLinksSync());
  } on FileSystemException {
    return absolute;
  }
}

String? _normalizedStoredGitWorkspacePath(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  return p.normalize(p.absolute(value));
}
