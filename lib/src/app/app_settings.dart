import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../export/export_options.dart';
import '../spellcheck/spelling_language.dart';
import 'app_locale.dart';
import 'shortcut_binding.dart';

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

class RecentResource {
  const RecentResource({
    required this.path,
    required this.kind,
    required this.lastOpenedAt,
    this.accountId,
    this.accountLabel,
    this.localId,
    this.ownerRoot,
    this.title,
    this.document = false,
  });

  factory RecentResource.fromJson(Map<String, Object?> json) {
    return RecentResource(
      path: json['path']?.toString() ?? '',
      accountId: json['accountId'] as String?,
      accountLabel: json['accountLabel'] as String?,
      localId: json['localId'] as String?,
      ownerRoot: json['ownerRoot'] as String?,
      title: json['title'] as String?,
      document: json['document'] as bool? ?? json['kind'] == 'singleMarkdown',
      kind: json['kind']?.toString() ?? 'unknown',
      lastOpenedAt:
          DateTime.tryParse(json['lastOpenedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final String path;
  final String kind;
  final DateTime lastOpenedAt;
  final String? accountId, accountLabel, localId, ownerRoot, title;
  final bool document;
  bool get isDocument => document || kind == 'singleMarkdown';
  String get identity => accountId == null
      ? p.normalize(p.absolute(path))
      : '$accountId:${localId ?? 'workspace'}';

  Map<String, Object?> toJson() => {
    'path': path,
    'kind': kind,
    if (accountId != null) 'accountId': accountId,
    if (accountLabel != null) 'accountLabel': accountLabel,
    if (localId != null) 'localId': localId,
    if (ownerRoot != null) 'ownerRoot': ownerRoot,
    if (title != null) 'title': title,
    'document': isDocument,
    'lastOpenedAt': lastOpenedAt.toIso8601String(),
  };
}

// Keep the existing JSON representation and key; resource type never affects
// retention. Stable identities are deduplicated after timestamp ordering.
List<RecentResource> _normalizeRecent(Iterable<RecentResource> resources) {
  final ordered = resources.toList()
    ..sort((a, b) => b.lastOpenedAt.compareTo(a.lastOpenedAt));
  final seen = <String>{};
  return ordered.where((r) => seen.add(r.identity)).take(12).toList();
}

class AppSettings {
  const AppSettings({
    required this.themeModePreference,
    required this.localeTag,
    required this.sidebarVisible,
    this.elementPropertiesVisible = false,
    this.elementPropertiesWidth = 320,
    required this.previewVisible,
    required this.documentViewMode,
    required this.editorFontSize,
    required this.wordWrap,
    required this.editorToolbarPlacement,
    required this.editorToolbarDirection,
    required this.autoSave,
    required this.validateOnEdit,
    required this.automaticSpelling,
    required this.defaultSpellingLanguage,
    required this.clipboardHistoryEnabled,
    required this.localHistoryRecordingEnabled,
    required this.localHistoryCheckpointSeconds,
    required this.localHistoryRetentionDays,
    required this.localHistoryMaximumStorageMiB,
    required this.localHistoryExcludedPaths,
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
    this.pdfExportOptions = const PdfExportOptions(),
    this.htmlExportOptions = const HtmlExportOptions(),
    required this.selectedWritersideInstanceIds,
    required this.writersideInstanceIconColors,
    required this.reopenPreviousWorkspaceOnStartup,
    required this.confirmCloseWithUnsavedChanges,
    required this.recentWorkspaces,
    this.lastOpenedPath,
    this.shortcutOverrides = const {},
  });

  factory AppSettings.defaults() {
    return const AppSettings(
      themeModePreference: BusyMarkThemeModePreference.system,
      localeTag: null,
      sidebarVisible: true,
      previewVisible: true,
      documentViewMode: DocumentViewModePreference.editor,
      editorFontSize: 14,
      wordWrap: true,
      editorToolbarPlacement: EditorToolbarPlacement.topLeft,
      editorToolbarDirection: EditorToolbarDirection.horizontal,
      autoSave: true,
      validateOnEdit: true,
      automaticSpelling: true,
      defaultSpellingLanguage: null,
      clipboardHistoryEnabled: true,
      localHistoryRecordingEnabled: true,
      localHistoryCheckpointSeconds: 60,
      localHistoryRetentionDays: 30,
      localHistoryMaximumStorageMiB: 512,
      localHistoryExcludedPaths: [],
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
      reopenPreviousWorkspaceOnStartup: false,
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
      elementPropertiesVisible:
          json['elementPropertiesVisible'] as bool? ??
          defaults.elementPropertiesVisible,
      elementPropertiesWidth:
          (json['elementPropertiesWidth'] as num?)?.toDouble().clamp(
            260,
            600,
          ) ??
          defaults.elementPropertiesWidth,
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
      automaticSpelling:
          json['automaticSpelling'] as bool? ?? defaults.automaticSpelling,
      defaultSpellingLanguage: normalizeSpellingLanguageId(
        json['defaultSpellingLanguage'],
      ),
      clipboardHistoryEnabled:
          json['clipboardHistoryEnabled'] as bool? ??
          defaults.clipboardHistoryEnabled,
      localHistoryRecordingEnabled:
          json['localHistoryRecordingEnabled'] as bool? ??
          defaults.localHistoryRecordingEnabled,
      localHistoryCheckpointSeconds: _boundedInt(
        json['localHistoryCheckpointSeconds'],
        defaults.localHistoryCheckpointSeconds,
        10,
        3600,
      ),
      localHistoryRetentionDays: _boundedInt(
        json['localHistoryRetentionDays'],
        defaults.localHistoryRetentionDays,
        1,
        3650,
      ),
      localHistoryMaximumStorageMiB: _boundedInt(
        json['localHistoryMaximumStorageMiB'],
        defaults.localHistoryMaximumStorageMiB,
        16,
        4096,
      ),
      localHistoryExcludedPaths: _historyExclusionPathListFromJson(
        json['localHistoryExcludedPaths'],
      ),
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
      pdfExportOptions: PdfExportOptions.fromJson(json['pdfExportOptions']),
      htmlExportOptions: HtmlExportOptions.fromJson(json['htmlExportOptions']),
      selectedWritersideInstanceIds: _stringMapFromJson(
        json['selectedWritersideInstanceIds'],
      ),
      writersideInstanceIconColors: _stringMapFromJson(
        json['writersideInstanceIconColors'],
      ),
      reopenPreviousWorkspaceOnStartup:
          json['reopenPreviousWorkspaceOnStartup'] as bool? ??
          defaults.reopenPreviousWorkspaceOnStartup,
      confirmCloseWithUnsavedChanges:
          json['confirmCloseWithUnsavedChanges'] as bool? ??
          defaults.confirmCloseWithUnsavedChanges,
      shortcutOverrides: readShortcutOverrides(json['shortcutOverrides']),
      lastOpenedPath: json['lastOpenedPath']?.toString(),
      recentWorkspaces: recent is List
          ? _normalizeRecent(
              recent
                  .whereType<Map>()
                  .map((item) => item.cast<String, Object?>())
                  .map(RecentResource.fromJson)
                  .where(
                    (item) => item.path.isNotEmpty || item.accountId != null,
                  ),
            )
          : defaults.recentWorkspaces,
    );
  }

  final BusyMarkThemeModePreference themeModePreference;
  final String? localeTag;
  final bool sidebarVisible;
  final bool elementPropertiesVisible;
  final double elementPropertiesWidth;
  final bool previewVisible;
  final DocumentViewModePreference documentViewMode;
  final double editorFontSize;
  final bool wordWrap;
  final EditorToolbarPlacement editorToolbarPlacement;
  final EditorToolbarDirection editorToolbarDirection;
  final bool autoSave;
  final bool validateOnEdit;
  final bool automaticSpelling;
  final String? defaultSpellingLanguage;
  final bool clipboardHistoryEnabled;
  final bool localHistoryRecordingEnabled;
  final int localHistoryCheckpointSeconds;
  final int localHistoryRetentionDays;
  final int localHistoryMaximumStorageMiB;
  final List<String> localHistoryExcludedPaths;
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
  final PdfExportOptions pdfExportOptions;
  final HtmlExportOptions htmlExportOptions;
  final Map<String, String> selectedWritersideInstanceIds;
  final Map<String, String> writersideInstanceIconColors;
  final bool reopenPreviousWorkspaceOnStartup;
  final bool confirmCloseWithUnsavedChanges;
  final String? lastOpenedPath;
  final Map<String, BusyMarkKeyBinding?> shortcutOverrides;
  final List<RecentResource> recentWorkspaces;

  ThemeMode get themeMode => themeModePreference.themeMode;

  Locale? get locale => busyMarkLocaleFromTag(localeTag);

  Map<String, Object?> toJson() => {
    'shortcutOverrides': {
      for (final e in shortcutOverrides.entries) e.key: e.value?.toJson(),
    },
    'themeModePreference': themeModePreference.name,
    'localeTag': localeTag,
    'sidebarVisible': sidebarVisible,
    'elementPropertiesVisible': elementPropertiesVisible,
    'elementPropertiesWidth': elementPropertiesWidth,
    'previewVisible': previewVisible,
    'documentViewMode': documentViewMode.name,
    'editorFontSize': editorFontSize,
    'wordWrap': wordWrap,
    'editorToolbarPlacement': editorToolbarPlacement.name,
    'editorToolbarDirection': editorToolbarDirection.name,
    'autoSave': autoSave,
    'validateOnEdit': validateOnEdit,
    'automaticSpelling': automaticSpelling,
    'defaultSpellingLanguage': defaultSpellingLanguage,
    'clipboardHistoryEnabled': clipboardHistoryEnabled,
    'localHistoryRecordingEnabled': localHistoryRecordingEnabled,
    'localHistoryCheckpointSeconds': localHistoryCheckpointSeconds,
    'localHistoryRetentionDays': localHistoryRetentionDays,
    'localHistoryMaximumStorageMiB': localHistoryMaximumStorageMiB,
    'localHistoryExcludedPaths': localHistoryExcludedPaths,
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
    'pdfExportOptions': pdfExportOptions.toJson(),
    'htmlExportOptions': htmlExportOptions.toJson(),
    'selectedWritersideInstanceIds': selectedWritersideInstanceIds,
    'writersideInstanceIconColors': writersideInstanceIconColors,
    'reopenPreviousWorkspaceOnStartup': reopenPreviousWorkspaceOnStartup,
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
    Map<String, BusyMarkKeyBinding?>? shortcutOverrides,
    BusyMarkThemeModePreference? themeModePreference,
    Object? localeTag = _unset,
    bool? sidebarVisible,
    bool? elementPropertiesVisible,
    double? elementPropertiesWidth,
    bool? previewVisible,
    DocumentViewModePreference? documentViewMode,
    double? editorFontSize,
    bool? wordWrap,
    EditorToolbarPlacement? editorToolbarPlacement,
    EditorToolbarDirection? editorToolbarDirection,
    bool? autoSave,
    bool? validateOnEdit,
    bool? automaticSpelling,
    Object? defaultSpellingLanguage = _unset,
    bool? clipboardHistoryEnabled,
    bool? localHistoryRecordingEnabled,
    int? localHistoryCheckpointSeconds,
    int? localHistoryRetentionDays,
    int? localHistoryMaximumStorageMiB,
    List<String>? localHistoryExcludedPaths,
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
    PdfExportOptions? pdfExportOptions,
    HtmlExportOptions? htmlExportOptions,
    Map<String, String>? selectedWritersideInstanceIds,
    Map<String, String>? writersideInstanceIconColors,
    bool? reopenPreviousWorkspaceOnStartup,
    bool? confirmCloseWithUnsavedChanges,
    String? lastOpenedPath,
    List<RecentResource>? recentWorkspaces,
  }) {
    return AppSettings(
      shortcutOverrides: shortcutOverrides ?? this.shortcutOverrides,
      themeModePreference: themeModePreference ?? this.themeModePreference,
      localeTag: identical(localeTag, _unset)
          ? this.localeTag
          : normalizeBusyMarkLocaleTag(localeTag as String?),
      sidebarVisible: sidebarVisible ?? this.sidebarVisible,
      elementPropertiesVisible:
          elementPropertiesVisible ?? this.elementPropertiesVisible,
      elementPropertiesWidth:
          elementPropertiesWidth ?? this.elementPropertiesWidth,
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
      automaticSpelling: automaticSpelling ?? this.automaticSpelling,
      defaultSpellingLanguage: identical(defaultSpellingLanguage, _unset)
          ? this.defaultSpellingLanguage
          : normalizeSpellingLanguageId(defaultSpellingLanguage),
      clipboardHistoryEnabled:
          clipboardHistoryEnabled ?? this.clipboardHistoryEnabled,
      localHistoryRecordingEnabled:
          localHistoryRecordingEnabled ?? this.localHistoryRecordingEnabled,
      localHistoryCheckpointSeconds:
          localHistoryCheckpointSeconds ?? this.localHistoryCheckpointSeconds,
      localHistoryRetentionDays:
          localHistoryRetentionDays ?? this.localHistoryRetentionDays,
      localHistoryMaximumStorageMiB:
          localHistoryMaximumStorageMiB ?? this.localHistoryMaximumStorageMiB,
      localHistoryExcludedPaths:
          localHistoryExcludedPaths ?? this.localHistoryExcludedPaths,
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
      pdfExportOptions: pdfExportOptions ?? this.pdfExportOptions,
      htmlExportOptions: htmlExportOptions ?? this.htmlExportOptions,
      selectedWritersideInstanceIds:
          selectedWritersideInstanceIds ?? this.selectedWritersideInstanceIds,
      writersideInstanceIconColors:
          writersideInstanceIconColors ?? this.writersideInstanceIconColors,
      reopenPreviousWorkspaceOnStartup:
          reopenPreviousWorkspaceOnStartup ??
          this.reopenPreviousWorkspaceOnStartup,
      confirmCloseWithUnsavedChanges:
          confirmCloseWithUnsavedChanges ?? this.confirmCloseWithUnsavedChanges,
      lastOpenedPath: lastOpenedPath ?? this.lastOpenedPath,
      recentWorkspaces: recentWorkspaces == null
          ? this.recentWorkspaces
          : _normalizeRecent(recentWorkspaces),
    );
  }
}

abstract class LocalSettingsStore {
  Future<Map<String, Object?>> load();
  Future<void> save(Map<String, Object?> json);
}

/// One-use handoff of local preferences read before the first application frame.
/// Bound to the store that acknowledged them; later controller initialization
/// reads the store again instead of reusing a startup snapshot.
class StartupAppSettings {
  StartupAppSettings._(this._store, this._snapshot);

  final LocalSettingsStore _store;
  ({AppSettings settings, String? acknowledgedJson})? _snapshot;

  static Future<StartupAppSettings> load(LocalSettingsStore store) async {
    AppSettings settings;
    String? acknowledgedJson;
    try {
      settings = AppSettings.fromJson(await store.load());
      acknowledgedJson = _canonicalSettingsJson(settings.toJson());
    } on Object {
      // Match the controller's existing failed-load policy. Defaults are usable
      // but are not an acknowledged disk snapshot for write reconciliation.
      settings = AppSettings.defaults();
    }
    return StartupAppSettings._(store, (
      settings: settings,
      acknowledgedJson: acknowledgedJson,
    ));
  }

  ({AppSettings settings, String? acknowledgedJson})? _take(
    LocalSettingsStore store,
  ) {
    final snapshot = _snapshot;
    _snapshot = null;
    return identical(store, _store) ? snapshot : null;
  }
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
    final type = await FileSystemEntity.type(file.path);
    if (type != FileSystemEntityType.file &&
        type != FileSystemEntityType.notFound) {
      throw FileSystemException(
        'Settings path is not a regular file',
        file.path,
      );
    }
    // Other read failures must leave the controller's acknowledged snapshot
    // unset. A notFound type can also mean that the path is inaccessible.
    final String content;
    try {
      content = await file.readAsString();
    } on FileSystemException catch (error) {
      final code = error.osError?.errorCode;
      if (code == 2 || Platform.isWindows && code == 3) {
        return <String, Object?>{};
      }
      rethrow;
    }
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
  AppSettingsController({StartupAppSettings? startupSettings})
    : _startupSettings = startupSettings;

  final StartupAppSettings? _startupSettings;
  bool Function()? processPendingProperties;
  Future<void> setElementPropertiesVisible(bool value) {
    if (!value && processPendingProperties?.call() == false) {
      return Future.value();
    }
    return _mutate((s) => s.copyWith(elementPropertiesVisible: value));
  }

  Future<void> setElementPropertiesWidth(double value) =>
      _mutate((s) => s.copyWith(elementPropertiesWidth: value.clamp(260, 600)));
  late LocalSettingsStore _store;
  Future<void>? _lastSave;
  String? _persistedSettingsJson;
  final _pendingInitialMutations = <AppSettings Function(AppSettings)>[];
  final _pendingInitialPersistence = <Completer<void>>[];
  var _loaded = false;
  late Future<void> _loadFuture;

  @override
  AppSettings build() {
    _store = ref.read(localSettingsStoreProvider);
    final startup = _startupSettings?._take(_store);
    if (startup != null) {
      _loaded = true;
      _persistedSettingsJson = startup.acknowledgedJson;
      _loadFuture = Future<void>.value();
      return startup.settings.copyWith(elementPropertiesVisible: false);
    }
    _loaded = false;
    _persistedSettingsJson = null;
    _loadFuture = _load();
    unawaited(_loadFuture);
    return AppSettings.defaults();
  }

  Future<void> waitUntilLoaded() => _loadFuture;

  Future<void> flushPersistence() async {
    await waitUntilLoaded();
    while (true) {
      final pending = _lastSave;
      await pending;
      if (identical(pending, _lastSave)) return;
    }
  }

  /// Invoked after validation against the current in-memory assignments. All
  /// preferences still use the same ordered writer and settings file.
  bool _trackShortcutSaves = false;
  Future<bool> saveShortcutOverrides(
    Map<String, BusyMarkKeyBinding?> overrides,
  ) {
    _trackShortcutSaves = true;
    final snapshot = Map<String, BusyMarkKeyBinding?>.unmodifiable(overrides);
    if (!_loaded) return _saveShortcutsAfterLoad(snapshot);
    return _save(
      state.copyWith(shortcutOverrides: snapshot),
      reusePersisted: true,
    );
  }

  Future<bool> _saveShortcutsAfterLoad(
    Map<String, BusyMarkKeyBinding?> overrides,
  ) async {
    await waitUntilLoaded();
    if (!ref.mounted) return false;
    return _save(
      state.copyWith(shortcutOverrides: overrides),
      reusePersisted: true,
    );
  }

  Future<bool> retryShortcutSave() async {
    await waitUntilLoaded();
    if (!ref.mounted) return false;
    return _save(state, reusePersisted: true);
  }

  Future<void> setPdfExportOptions(PdfExportOptions options) {
    options.validateOrThrow();
    return _mutate((settings) => settings.copyWith(pdfExportOptions: options));
  }

  Future<void> setHtmlExportOptions(HtmlExportOptions options) {
    options.validateOrThrow();
    return _mutate((settings) => settings.copyWith(htmlExportOptions: options));
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
    if (processPendingProperties?.call() == false) return Future.value();
    return _mutate(
      (settings) => settings.copyWith(
        documentViewMode: mode,
        previewVisible: mode != DocumentViewModePreference.source,
      ),
      reusePersisted: true,
    );
  }

  Future<void> setSidebarVisible(bool enabled) {
    if (state.sidebarVisible != enabled) {
      ref.read(sidebarTransitionGenerationProvider.notifier).increment();
    }
    return _mutate((settings) => settings.copyWith(sidebarVisible: enabled));
  }

  Future<void> setValidateOnEdit(bool enabled) {
    return _mutate((settings) => settings.copyWith(validateOnEdit: enabled));
  }

  Future<void> setAutomaticSpelling(bool enabled) {
    return _mutate((settings) => settings.copyWith(automaticSpelling: enabled));
  }

  Future<void> setDefaultSpellingLanguage(String? languageId) {
    return _mutate(
      (settings) => settings.copyWith(
        defaultSpellingLanguage: normalizeSpellingLanguageId(languageId),
      ),
    );
  }

  Future<void> setClipboardHistoryEnabled(bool enabled) {
    return _mutate(
      (settings) => settings.copyWith(clipboardHistoryEnabled: enabled),
    );
  }

  Future<void> setLocalHistoryRecordingEnabled(bool enabled) {
    return _mutate(
      (settings) => settings.copyWith(localHistoryRecordingEnabled: enabled),
    );
  }

  Future<void> setLocalHistoryCheckpointSeconds(int seconds) {
    return _mutate(
      (settings) => settings.copyWith(
        localHistoryCheckpointSeconds: seconds.clamp(10, 3600),
      ),
    );
  }

  Future<void> setLocalHistoryRetentionDays(int days) {
    return _mutate(
      (settings) =>
          settings.copyWith(localHistoryRetentionDays: days.clamp(1, 3650)),
    );
  }

  Future<void> setLocalHistoryMaximumStorageMiB(int mebibytes) {
    return _mutate(
      (settings) => settings.copyWith(
        localHistoryMaximumStorageMiB: mebibytes.clamp(16, 4096),
      ),
    );
  }

  Future<void> setLocalHistoryExcludedPaths(Iterable<String> paths) {
    final normalized = {
      for (final path in paths)
        if (_normalizedHistoryExclusionPath(path) case final value?) value,
    }.toList()..sort();
    return _mutate(
      (settings) => settings.copyWith(localHistoryExcludedPaths: normalized),
    );
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

  Future<void> setReopenPreviousWorkspaceOnStartup(bool enabled) {
    return _mutate(
      (settings) =>
          settings.copyWith(reopenPreviousWorkspaceOnStartup: enabled),
    );
  }

  Future<void> recordOpenedWorkspace({
    required String path,
    required String kind,
    String? accountId,
    String? title,
  }) {
    return recordRecent(
      RecentResource(
        path: accountId == null ? p.normalize(p.absolute(path)) : '',
        kind: kind,
        accountId: accountId,
        title: title,
        document: kind == 'singleMarkdown',
        lastOpenedAt: DateTime.now(),
      ),
      updateLastOpenedPath: accountId == null,
    );
  }

  Future<void> recordRecent(
    RecentResource resource, {
    bool updateLastOpenedPath = false,
  }) => _mutate((settings) {
    final ordered = [
      resource,
      ...settings.recentWorkspaces.where(
        (r) => r.identity != resource.identity,
      ),
    ];
    final retained = _normalizeRecent(ordered);
    return settings.copyWith(
      recentWorkspaces: retained,
      lastOpenedPath: updateLastOpenedPath
          ? resource.path
          : settings.lastOpenedPath,
    );
  }, propagateFailure: true);

  Future<void> clearRecentWorkspaces() =>
      _mutate((settings) => settings.copyWith(recentWorkspaces: []));

  Future<void> removeRecentWorkspace(String path) => _mutate(
    (settings) => settings.copyWith(
      recentWorkspaces: settings.recentWorkspaces
          .where(
            (r) =>
                r.identity != path &&
                !(r.accountId == null && p.equals(r.path, path)),
          )
          .toList(),
    ),
  );

  Future<void> updateRecentNoteTitles(Map<(String, String), String> titles) {
    if (!state.recentWorkspaces.any(
      (r) =>
          r.accountId != null &&
          r.localId != null &&
          titles[(r.accountId!, r.localId!)] != null &&
          titles[(r.accountId!, r.localId!)] != r.title,
    )) {
      return Future.value();
    }
    return _mutate(
      (settings) => settings.copyWith(
        recentWorkspaces: [
          for (final r in settings.recentWorkspaces)
            if (r.accountId != null &&
                r.localId != null &&
                titles[(r.accountId!, r.localId!)] != null)
              RecentResource(
                path: r.path,
                kind: r.kind,
                lastOpenedAt: r.lastOpenedAt,
                document: r.isDocument,
                accountId: r.accountId,
                accountLabel: r.accountLabel,
                localId: r.localId,
                title: titles[(r.accountId!, r.localId!)],
                ownerRoot: r.ownerRoot,
              )
            else
              r,
        ],
      ),
    );
  }

  Future<void> removeRecentAccount(String accountId) => _mutate(
    (settings) => settings.copyWith(
      recentWorkspaces: settings.recentWorkspaces
          .where((r) => r.accountId != accountId)
          .toList(),
    ),
  );

  Future<void> moveRecentPath(String from, String to) => _mutate(
    (settings) => settings.copyWith(
      recentWorkspaces: [
        for (final r in settings.recentWorkspaces)
          if (r.accountId == null &&
              (p.equals(r.path, from) || p.isWithin(from, r.path)))
            RecentResource(
              path: p.equals(r.path, from)
                  ? to
                  : p.join(to, p.relative(r.path, from: from)),
              kind: r.kind,
              lastOpenedAt: r.lastOpenedAt,
              document: r.isDocument,
              ownerRoot: r.ownerRoot == null
                  ? null
                  : p.equals(r.ownerRoot!, from)
                  ? to
                  : p.isWithin(from, r.ownerRoot!)
                  ? p.join(to, p.relative(r.ownerRoot!, from: from))
                  : r.ownerRoot,
              title: r.title,
            )
          else
            r,
      ],
    ),
  );

  Future<void> _load() async {
    AppSettings loaded;
    try {
      loaded = AppSettings.fromJson(await _store.load());
      _persistedSettingsJson = _canonicalSettingsJson(loaded.toJson());
    } on Object {
      loaded = AppSettings.defaults();
    }
    if (!ref.mounted) {
      for (final completion in _pendingInitialPersistence) {
        completion.completeError(StateError('Settings controller disposed'));
      }
      _pendingInitialPersistence.clear();
      _pendingInitialMutations.clear();
      return;
    }
    // Visibility belongs to this run; retain the preferred inspector width.
    // Explicit requests made during hydration are applied below.
    loaded = loaded.copyWith(elementPropertiesVisible: false);
    final hadPendingInitialMutations = _pendingInitialMutations.isNotEmpty;
    for (final mutation in _pendingInitialMutations) {
      loaded = mutation(loaded);
    }
    _pendingInitialMutations.clear();
    final completions = List<Completer<void>>.of(_pendingInitialPersistence);
    _pendingInitialPersistence.clear();
    _loaded = true;
    state = loaded;
    if (hadPendingInitialMutations) {
      try {
        // Initial actions share one publication, but opening callers retain
        // its authoritative completion/error instead of a dispatch future.
        await _save(loaded, propagateFailure: completions.isNotEmpty);
        for (final completion in completions) {
          completion.complete();
        }
      } on Object catch (error, stack) {
        for (final completion in completions) {
          completion.completeError(error, stack);
        }
      }
    }
  }

  Future<void> _mutate(
    AppSettings Function(AppSettings) mutation, {
    bool propagateFailure = false,
    bool reusePersisted = false,
  }) {
    if (!_loaded) {
      _pendingInitialMutations.add(mutation);
      state = mutation(state);
      if (propagateFailure) {
        final completion = Completer<void>();
        _pendingInitialPersistence.add(completion);
        return completion.future;
      }
      return Future<void>.value();
    }
    return _save(
      mutation(state),
      propagateFailure: propagateFailure,
      reusePersisted: reusePersisted,
    );
  }

  Future<bool> _save(
    AppSettings next, {
    bool propagateFailure = false,
    bool reusePersisted = false,
  }) async {
    if (!ref.mounted) return false;
    state = next;
    final json = next.toJson();
    final encoded = _canonicalSettingsJson(json);
    final previousSave = _lastSave;
    Object? failure;
    StackTrace? failureStack;
    final save = () async {
      await previousSave;
      try {
        // Compare the entire serialized snapshot only after preceding writes
        // settle. Failed loads and writes never acknowledge unpersisted state.
        if (!reusePersisted || encoded != _persistedSettingsJson) {
          await _store.save(json);
          _persistedSettingsJson = encoded;
        }
        return true;
      } on Object catch (error, stack) {
        failure = error;
        failureStack = stack;
        return false;
      }
    }();
    // The queue tail always settles successfully; each caller retains its own
    // outcome/error without preventing the next admitted publication.
    _lastSave = save.then<void>((_) {});
    final succeeded = await save;
    if (ref.mounted &&
        _trackShortcutSaves &&
        mapEquals(state.shortcutOverrides, next.shortcutOverrides)) {
      ref.read(shortcutPersistenceOutcomeProvider.notifier).complete(succeeded);
    }
    if (propagateFailure && failure != null) {
      Error.throwWithStackTrace(failure!, failureStack!);
    }
    return succeeded;
  }
}

class ShortcutPersistenceOutcome extends Notifier<bool?> {
  @override
  bool? build() => null;
  void complete(bool saved) => state = saved;
}

final shortcutPersistenceOutcomeProvider =
    NotifierProvider<ShortcutPersistenceOutcome, bool?>(
      ShortcutPersistenceOutcome.new,
    );

final localSettingsStoreProvider = Provider<LocalSettingsStore>(
  (ref) => const JsonFileLocalSettingsStore(),
);

final sidebarTransitionGenerationProvider =
    NotifierProvider<SidebarTransitionGeneration, int>(
      SidebarTransitionGeneration.new,
    );

class SidebarTransitionGeneration extends Notifier<int> {
  @override
  int build() => 0;
  void increment() => state++;
}

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

int _boundedInt(Object? value, int fallback, int minimum, int maximum) {
  final parsed = value is num ? value.toInt() : int.tryParse('$value');
  return (parsed ?? fallback).clamp(minimum, maximum);
}

List<String> _historyExclusionPathListFromJson(Object? value) {
  if (value is! List) return const [];
  final paths = {
    for (final item in value)
      if (_normalizedHistoryExclusionPath(item?.toString()) case final path?)
        path,
  }.toList()..sort();
  return paths;
}

String? _normalizedHistoryExclusionPath(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  if (!p.isAbsolute(trimmed)) return null;
  return p.normalize(trimmed);
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

// Map insertion order is not a preference change. Lists retain their order,
// including the release target's qualified Recent resources.
String _canonicalSettingsJson(Map<String, Object?> json) =>
    jsonEncode(_canonicalSettingsValue(json));

Object? _canonicalSettingsValue(Object? value) {
  if (value is Map) {
    final keys = value.keys.cast<String>().toList()..sort();
    return {for (final key in keys) key: _canonicalSettingsValue(value[key])};
  }
  if (value is List) return value.map(_canonicalSettingsValue).toList();
  return value;
}
