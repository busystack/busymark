import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

enum BusyMarkThemeModePreference { system, light, dark }

enum DocumentViewModePreference { editor, source, preview, split }

enum EditorToolbarPlacement { topLeft, topRight, bottomLeft, bottomRight }

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
    required this.autoSave,
    required this.validateOnEdit,
    required this.allowRemoteImages,
    required this.remoteImageAllowedWorkspacePaths,
    required this.trustedGitWorkspacePaths,
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
      autoSave: true,
      validateOnEdit: true,
      allowRemoteImages: false,
      remoteImageAllowedWorkspacePaths: [],
      trustedGitWorkspacePaths: [],
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
      localeTag: _localeTagFromJson(json['localeTag']),
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
      autoSave: json['autoSave'] as bool? ?? defaults.autoSave,
      validateOnEdit:
          json['validateOnEdit'] as bool? ?? defaults.validateOnEdit,
      allowRemoteImages:
          json['allowRemoteImages'] as bool? ?? defaults.allowRemoteImages,
      remoteImageAllowedWorkspacePaths: _workspacePathListFromJson(
        json['remoteImageAllowedWorkspacePaths'],
      ),
      trustedGitWorkspacePaths: _gitWorkspacePathListFromJson(
        json['trustedGitWorkspacePaths'],
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
  final bool autoSave;
  final bool validateOnEdit;
  final bool allowRemoteImages;
  final List<String> remoteImageAllowedWorkspacePaths;
  final List<String> trustedGitWorkspacePaths;
  final bool confirmCloseWithUnsavedChanges;
  final String? lastOpenedPath;
  final List<RecentWorkspace> recentWorkspaces;

  ThemeMode get themeMode => themeModePreference.themeMode;

  Locale? get locale => _localeFromTag(_normalizeLocaleTag(localeTag));

  Map<String, Object?> toJson() => {
    'themeModePreference': themeModePreference.name,
    'localeTag': localeTag,
    'sidebarVisible': sidebarVisible,
    'previewVisible': previewVisible,
    'documentViewMode': documentViewMode.name,
    'editorFontSize': editorFontSize,
    'wordWrap': wordWrap,
    'editorToolbarPlacement': editorToolbarPlacement.name,
    'autoSave': autoSave,
    'validateOnEdit': validateOnEdit,
    'allowRemoteImages': allowRemoteImages,
    'remoteImageAllowedWorkspacePaths': remoteImageAllowedWorkspacePaths,
    'trustedGitWorkspacePaths': trustedGitWorkspacePaths,
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
    bool? autoSave,
    bool? validateOnEdit,
    bool? allowRemoteImages,
    List<String>? remoteImageAllowedWorkspacePaths,
    List<String>? trustedGitWorkspacePaths,
    bool? confirmCloseWithUnsavedChanges,
    String? lastOpenedPath,
    List<RecentWorkspace>? recentWorkspaces,
  }) {
    return AppSettings(
      themeModePreference: themeModePreference ?? this.themeModePreference,
      localeTag: identical(localeTag, _unset)
          ? this.localeTag
          : localeTag as String?,
      sidebarVisible: sidebarVisible ?? this.sidebarVisible,
      previewVisible: previewVisible ?? this.previewVisible,
      documentViewMode: documentViewMode ?? this.documentViewMode,
      editorFontSize: editorFontSize ?? this.editorFontSize,
      wordWrap: wordWrap ?? this.wordWrap,
      editorToolbarPlacement:
          editorToolbarPlacement ?? this.editorToolbarPlacement,
      autoSave: autoSave ?? this.autoSave,
      validateOnEdit: validateOnEdit ?? this.validateOnEdit,
      allowRemoteImages: allowRemoteImages ?? this.allowRemoteImages,
      remoteImageAllowedWorkspacePaths:
          remoteImageAllowedWorkspacePaths ??
          this.remoteImageAllowedWorkspacePaths,
      trustedGitWorkspacePaths:
          trustedGitWorkspacePaths ?? this.trustedGitWorkspacePaths,
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
  const JsonFileLocalSettingsStore();

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
    await file.parent.create(recursive: true);
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
  }

  Future<File> _settingsFile() async {
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
          settings.copyWith(localeTag: _normalizeLocaleTag(localeTag)),
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

String? _localeTagFromJson(Object? value) {
  if (value == null) {
    return null;
  }
  final tag = value.toString().trim();
  return _normalizeLocaleTag(tag);
}

String? _normalizeLocaleTag(String? tag) {
  if (tag == null) {
    return null;
  }
  final trimmed = tag.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  if (trimmed == 'no') {
    return 'nb';
  }
  if (trimmed.startsWith('no_') || trimmed.startsWith('no-')) {
    return 'nb${trimmed.substring(2)}';
  }
  return trimmed;
}

Locale? _localeFromTag(String? tag) {
  if (tag == null || tag.isEmpty) {
    return null;
  }
  final parts = tag.split(RegExp('[-_]'));
  if (parts.length == 1) {
    return Locale(parts.first);
  }
  if (parts.length == 2) {
    return Locale(parts.first, parts.last);
  }
  return Locale.fromSubtags(
    languageCode: parts[0],
    scriptCode: parts[1].isEmpty ? null : parts[1],
    countryCode: parts[2].isEmpty ? null : parts[2],
  );
}
