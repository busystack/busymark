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
    required this.validateOnEdit,
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
      validateOnEdit: true,
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
      validateOnEdit:
          json['validateOnEdit'] as bool? ?? defaults.validateOnEdit,
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
  final bool validateOnEdit;
  final bool confirmCloseWithUnsavedChanges;
  final String? lastOpenedPath;
  final List<RecentWorkspace> recentWorkspaces;

  ThemeMode get themeMode => themeModePreference.themeMode;

  Locale? get locale => _localeFromTag(localeTag);

  Map<String, Object?> toJson() => {
    'themeModePreference': themeModePreference.name,
    'localeTag': localeTag,
    'sidebarVisible': sidebarVisible,
    'previewVisible': previewVisible,
    'documentViewMode': documentViewMode.name,
    'editorFontSize': editorFontSize,
    'wordWrap': wordWrap,
    'editorToolbarPlacement': editorToolbarPlacement.name,
    'validateOnEdit': validateOnEdit,
    'confirmCloseWithUnsavedChanges': confirmCloseWithUnsavedChanges,
    'lastOpenedPath': lastOpenedPath,
    'recentWorkspaces': recentWorkspaces.map((item) => item.toJson()).toList(),
  };

  AppSettings copyWith({
    BusyMarkThemeModePreference? themeModePreference,
    Object? localeTag = _unset,
    bool? sidebarVisible,
    bool? previewVisible,
    DocumentViewModePreference? documentViewMode,
    double? editorFontSize,
    bool? wordWrap,
    EditorToolbarPlacement? editorToolbarPlacement,
    bool? validateOnEdit,
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
      validateOnEdit: validateOnEdit ?? this.validateOnEdit,
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

class AppSettingsController extends StateNotifier<AppSettings> {
  AppSettingsController(this._store) : super(AppSettings.defaults()) {
    unawaited(_load());
  }

  final LocalSettingsStore _store;

  Future<void> setThemeModePreference(BusyMarkThemeModePreference preference) {
    return _save(state.copyWith(themeModePreference: preference));
  }

  Future<void> setLocaleTag(String? localeTag) {
    return _save(state.copyWith(localeTag: localeTag));
  }

  Future<void> setEditorFontSize(double size) {
    return _save(state.copyWith(editorFontSize: size.clamp(11, 24)));
  }

  Future<void> setWordWrap(bool enabled) {
    return _save(state.copyWith(wordWrap: enabled));
  }

  Future<void> setEditorToolbarPlacement(EditorToolbarPlacement placement) {
    return _save(state.copyWith(editorToolbarPlacement: placement));
  }

  Future<void> setPreviewVisible(bool enabled) {
    return setDocumentViewMode(
      enabled
          ? DocumentViewModePreference.split
          : DocumentViewModePreference.source,
    );
  }

  Future<void> setDocumentViewMode(DocumentViewModePreference mode) {
    return _save(
      state.copyWith(
        documentViewMode: mode,
        previewVisible: mode != DocumentViewModePreference.source,
      ),
    );
  }

  Future<void> setSidebarVisible(bool enabled) {
    return _save(state.copyWith(sidebarVisible: enabled));
  }

  Future<void> setValidateOnEdit(bool enabled) {
    return _save(state.copyWith(validateOnEdit: enabled));
  }

  Future<void> setConfirmCloseWithUnsavedChanges(bool enabled) {
    return _save(state.copyWith(confirmCloseWithUnsavedChanges: enabled));
  }

  Future<void> recordOpenedWorkspace({
    required String path,
    required String kind,
  }) {
    final recent = [
      RecentWorkspace(path: path, kind: kind, lastOpenedAt: DateTime.now()),
      ...state.recentWorkspaces.where((item) => item.path != path),
    ].take(12).toList();
    return _save(
      state.copyWith(lastOpenedPath: path, recentWorkspaces: recent),
    );
  }

  Future<void> clearRecentWorkspaces() {
    return _save(state.copyWith(recentWorkspaces: []));
  }

  Future<void> _load() async {
    try {
      state = AppSettings.fromJson(await _store.load());
    } on Object {
      state = AppSettings.defaults();
    }
  }

  Future<void> _save(AppSettings next) async {
    state = next;
    try {
      await _store.save(next.toJson());
    } on Object {
      // Keep the in-memory preference even when local persistence is unavailable.
    }
  }
}

final localSettingsStoreProvider = Provider<LocalSettingsStore>(
  (ref) => const JsonFileLocalSettingsStore(),
);

final appSettingsControllerProvider =
    StateNotifierProvider<AppSettingsController, AppSettings>((ref) {
      return AppSettingsController(ref.watch(localSettingsStoreProvider));
    });

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

String? _localeTagFromJson(Object? value) {
  if (value == null) {
    return null;
  }
  final tag = value.toString().trim();
  return tag.isEmpty ? null : tag;
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
