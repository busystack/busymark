import 'dart:async';
import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../ai/ai_models.dart';
import '../../ai/ai_configuration.dart';
import '../../ai/ai_policy.dart';
import '../../ai/ai_providers.dart';
import '../../app/app_router.dart';
import '../../app/app_settings.dart';
import '../../app/app_locale.dart';
import '../../app/busymark_dialogs.dart';
import '../../app/busymark_design.dart';
import '../../app/busymark_glyphs.dart';
import '../../app/busymark_main_menu.dart';
import '../../app/busymark_shortcuts.dart';
import '../../app/busymark_toast.dart';
import '../../app/localization.dart';
import '../../app/window_control_service.dart';
import '../../core/atomic_file_writer.dart';
import '../../feedback/presentation/feedback_dialog.dart';
import '../../platform/linux_header_bar_service.dart';
import '../../spellcheck/spelling_catalog.dart';
import '../../spellcheck/spelling_session_controller.dart';
import '../../spellcheck/spelling_word_store.dart';
import '../workspace_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({
    required this.returnTarget,
    this.initialPage = SettingsPage.appearance,
    super.key,
  });

  final SettingsReturnTarget returnTarget;
  final SettingsPage initialPage;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late SettingsPage _page = widget.initialPage;
  bool _showSpellingDictionaries = false;
  String? _preparedSpellingWorkspaceId;
  bool _preparingSpelling = false;

  @override
  void didUpdateWidget(covariant SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPage != widget.initialPage) {
      _page = widget.initialPage;
      _showSpellingDictionaries = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(appSettingsControllerProvider);
    final controller = ref.read(appSettingsControllerProvider.notifier);
    final spelling = ref.watch(spellingSessionControllerProvider);
    final workspace = ref.watch(
      workspaceControllerProvider.select((state) => state.workspace),
    );
    final spellingCatalog = spelling.catalog;
    final importedDictionaries =
        spellingCatalog?.installations
            .where((entry) => entry.imported)
            .toList(growable: false) ??
        const <SpellingDictionaryInstallation>[];
    final invalidImportedDictionaries =
        spellingCatalog?.invalidInstallations
            .where(
              (entry) =>
                  entry.kind == SpellingDictionaryInstallationKind.imported,
            )
            .toList(growable: false) ??
        const <SpellingInvalidDictionaryInstallation>[];
    _prepareSpellingSettings(spelling, workspace?.id);
    final colors = BusyMarkSurfaceColors.of(context);
    final headerBar = ref.watch(linuxHeaderBarServiceProvider);
    final useNativeHeaderBar = headerBar.usesNativeHeaderBar;
    final title = _showSpellingDictionaries
        ? l10n.spellingDictionaries
        : _settingsPageLabel(context, _page);
    ref.listen(headerBarActionsProvider, (previous, next) {
      next.whenData((event) {
        _handleHeaderBarAction(context, headerBar, event.action);
      });
    });
    final pageBody = _showSpellingDictionaries
        ? _SpellingDictionariesPage(
            catalog: spellingCatalog,
            status: spelling.dictionaryInstallStatus,
            importedDictionaries: importedDictionaries,
            invalidImportedDictionaries: invalidImportedDictionaries,
            onImport: () =>
                unawaited(_importSpellingDictionary(context, spelling)),
            onInstall: (resource) => unawaited(
              _installSpellingDictionary(context, spelling, resource.id),
            ),
            onRemoveDownloaded: (resource) => unawaited(
              _removeDownloadedSpellingDictionary(
                context,
                spelling,
                resource.id,
              ),
            ),
            onCancel: spelling.cancelDictionaryInstallation,
            onRetry: () =>
                unawaited(_retrySpellingDictionary(context, spelling)),
            onRemoveImported: (entry) => unawaited(
              _removeImportedSpellingDictionary(context, spelling, entry.id),
            ),
            onRemoveInvalid: (entry) => unawaited(
              _removeInvalidSpellingDictionary(context, spelling, entry),
            ),
          )
        : switch (_page) {
            SettingsPage.appearance => BusyMarkGroupedList(
              title: l10n.appearance,
              filled: true,
              children: [
                _LanguageRow(
                  selectedLocaleTag: settings.localeTag,
                  onChanged: controller.setLocaleTag,
                ),
                _ThemeModeRow(
                  selected: settings.themeModePreference,
                  onChanged: controller.setThemeModePreference,
                ),
              ],
            ),
            SettingsPage.editor => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BusyMarkGroupedList(
                  title: l10n.editor,
                  filled: true,
                  children: [
                    BusyMarkSwitchRow(
                      title: l10n.autoSave,
                      subtitle: l10n.autoSaveDescription,
                      value: settings.autoSave,
                      onChanged: controller.setAutoSave,
                      leading: const Icon(BusyMarkGlyphs.save),
                    ),
                    BusyMarkSwitchRow(
                      title: l10n.wordWrap,
                      subtitle: l10n.wordWrapDescription,
                      value: settings.wordWrap,
                      onChanged: controller.setWordWrap,
                      leading: Icon(
                        BusyMarkGlyphs.wordWrapFor(Directionality.of(context)),
                      ),
                    ),
                    _EditorFontSizeRow(
                      value: settings.editorFontSize,
                      onChanged: controller.setEditorFontSize,
                    ),
                  ],
                ),
                BusyMarkGroupedList(
                  title: l10n.settingsEditingButtonsSectionTitle,
                  filled: true,
                  children: [
                    _EditorToolbarPlacementRow(
                      selected: settings.editorToolbarPlacement,
                      onChanged: controller.setEditorToolbarPlacement,
                    ),
                    _EditorToolbarDirectionRow(
                      selected: settings.editorToolbarDirection,
                      onChanged: controller.setEditorToolbarDirection,
                    ),
                  ],
                ),
                BusyMarkGroupedList(
                  title: l10n.spelling,
                  filled: true,
                  children: [
                    BusyMarkSwitchRow(
                      title: l10n.automaticSpelling,
                      value: settings.automaticSpelling,
                      onChanged: controller.setAutomaticSpelling,
                      leading: const Icon(BusyMarkGlyphs.diagnostics),
                    ),
                    _SpellingLanguageRow(
                      title: l10n.defaultSpellingLanguage,
                      selected: settings.defaultSpellingLanguage,
                      catalogEntries: spelling.catalog?.entries ?? const [],
                      unsetLabel: l10n.chooseSpellingLanguage,
                      onChanged: (value) => unawaited(
                        _setDefaultSpellingLanguage(
                          context,
                          spelling,
                          controller,
                          value,
                        ),
                      ),
                    ),
                    _SpellingLanguageRow(
                      title: l10n.projectSpellingLanguage,
                      selected: spelling.projectWords.projectLanguage,
                      catalogEntries: spelling.catalog?.entries ?? const [],
                      unsetLabel: l10n.inheritSpellingLanguage,
                      enabled: spelling.hasProjectScope,
                      onChanged: (value) => unawaited(
                        _setProjectSpellingLanguage(context, spelling, value),
                      ),
                    ),
                  ],
                ),
                BusyMarkGroupedList(
                  title: l10n.settingsDictionariesSectionTitle,
                  filled: true,
                  children: [
                    BusyMarkActionRow(
                      key: const ValueKey('settings-spelling-dictionaries'),
                      title: l10n.spellingDictionaries,
                      subtitle: l10n.spellingDictionariesDescription,
                      leading: const Icon(BusyMarkGlyphs.symbols),
                      trailing: Icon(
                        BusyMarkGlyphs.forwardFor(Directionality.of(context)),
                      ),
                      onTap: _openSpellingDictionaries,
                    ),
                    _SpellingWordStoreRow(
                      title: l10n.personalSpellingDictionary,
                      snapshot: spelling.personalWords,
                      onRemove: spelling.removePersonalWord,
                    ),
                    _SpellingWordStoreRow(
                      title: l10n.projectSpellingDictionary,
                      snapshot: spelling.projectWords,
                      enabled: spelling.hasProjectScope,
                      onRemove: spelling.removeProjectWord,
                    ),
                  ],
                ),
              ],
            ),
            SettingsPage.validation => BusyMarkGroupedList(
              title: l10n.validation,
              filled: true,
              children: [
                BusyMarkSwitchRow(
                  title: l10n.validateOnEdit,
                  value: settings.validateOnEdit,
                  onChanged: controller.setValidateOnEdit,
                  leading: const Icon(BusyMarkGlyphs.diagnostics),
                ),
              ],
            ),
            SettingsPage.history => BusyMarkGroupedList(
              title: l10n.settingsHistory,
              filled: true,
              children: [
                BusyMarkSwitchRow(
                  title: l10n.settingsClipboardHistoryTitle,
                  subtitle: l10n.settingsClipboardHistoryDescription,
                  value: settings.clipboardHistoryEnabled,
                  onChanged: controller.setClipboardHistoryEnabled,
                  leading: const Icon(BusyMarkGlyphs.copy),
                ),
                BusyMarkSwitchRow(
                  title: l10n.settingsLocalHistoryTitle,
                  subtitle: l10n.settingsLocalHistoryDescription,
                  value: settings.localHistoryRecordingEnabled,
                  onChanged: controller.setLocalHistoryRecordingEnabled,
                  leading: const Icon(BusyMarkGlyphs.documentHistory),
                ),
                _HistoryNumberRow(
                  title: l10n.settingsHistoryCheckpoint,
                  value: settings.localHistoryCheckpointSeconds,
                  choices: const [30, 60, 120, 300, 600],
                  format: l10n.settingsSecondsValue,
                  enabled: settings.localHistoryRecordingEnabled,
                  onChanged: controller.setLocalHistoryCheckpointSeconds,
                ),
                _HistoryNumberRow(
                  title: l10n.settingsHistoryRetention,
                  value: settings.localHistoryRetentionDays,
                  choices: const [7, 30, 90, 365],
                  format: l10n.settingsDaysValue,
                  enabled: settings.localHistoryRecordingEnabled,
                  onChanged: controller.setLocalHistoryRetentionDays,
                ),
                _HistoryNumberRow(
                  title: l10n.settingsHistoryStorage,
                  value: settings.localHistoryMaximumStorageMiB,
                  choices: const [128, 256, 512, 1024, 2048, 4096],
                  format: l10n.settingsMebibytesValue,
                  enabled: settings.localHistoryRecordingEnabled,
                  onChanged: controller.setLocalHistoryMaximumStorageMiB,
                ),
                BusyMarkActionRow(
                  title: l10n.settingsHistoryExcludedPaths,
                  subtitle: settings.localHistoryExcludedPaths.isEmpty
                      ? l10n.settingsHistoryExcludedPathsHint
                      : settings.localHistoryExcludedPaths.join('\n'),
                  leading: const Icon(BusyMarkGlyphs.folder),
                  onTap: () => _editHistoryExcludedPaths(
                    context,
                    settings.localHistoryExcludedPaths,
                    controller.setLocalHistoryExcludedPaths,
                  ),
                ),
              ],
            ),
            SettingsPage.ai => const _AiSettingsPage(),
            SettingsPage.window => BusyMarkGroupedList(
              title: l10n.settingsWindowSectionTitle,
              filled: true,
              children: [
                BusyMarkSwitchRow(
                  title: l10n.settingsReopenWorkspaceOnStartupTitle,
                  subtitle: l10n.settingsReopenWorkspaceOnStartupDescription,
                  value: settings.reopenPreviousWorkspaceOnStartup,
                  onChanged: controller.setReopenPreviousWorkspaceOnStartup,
                  leading: const Icon(BusyMarkGlyphs.history),
                ),
                BusyMarkSwitchRow(
                  title: l10n.settingsConfirmCloseWithUnsavedChangesTitle,
                  subtitle:
                      l10n.settingsConfirmCloseWithUnsavedChangesDescription,
                  value: settings.confirmCloseWithUnsavedChanges,
                  onChanged: controller.setConfirmCloseWithUnsavedChanges,
                  leading: const Icon(BusyMarkGlyphs.warning),
                ),
              ],
            ),
            SettingsPage.privacy => BusyMarkGroupedList(
              title: l10n.privacy,
              filled: true,
              children: [
                BusyMarkSwitchRow(
                  title: l10n.allowRemoteImages,
                  subtitle: l10n.allowRemoteImagesDescription,
                  value: settings.allowRemoteImages,
                  onChanged: controller.setAllowRemoteImages,
                  leading: const Icon(BusyMarkGlyphs.image),
                ),
                if (settings.remoteImageAllowedWorkspacePaths.isNotEmpty)
                  BusyMarkActionRow(
                    title: l10n.clearRemoteImagePermissions,
                    subtitle: l10n.clearRemoteImagePermissionsDescription,
                    leading: const Icon(BusyMarkGlyphs.clearAll),
                    onTap: controller.clearRemoteImageWorkspacePermissions,
                  ),
                if (settings.trustedGitWorkspacePaths.isNotEmpty)
                  BusyMarkActionRow(
                    title: l10n.clearGitWorkspaceTrust,
                    subtitle: l10n.clearGitWorkspaceTrustDescription,
                    leading: const Icon(BusyMarkGlyphs.clearAll),
                    onTap: controller.clearTrustedGitWorkspaces,
                  ),
              ],
            ),
            SettingsPage.advanced => BusyMarkGroupedList(
              title: l10n.advanced,
              filled: true,
              children: [
                BusyMarkActionRow(
                  title: l10n.clearRecentWorkspaces,
                  leading: const Icon(BusyMarkGlyphs.clearAll),
                  destructive: true,
                  onTap: controller.clearRecentWorkspaces,
                ),
              ],
            ),
          };

    return LayoutBuilder(
      builder: (context, constraints) {
        final showSidebar =
            !_showSpellingDictionaries &&
            constraints.maxWidth >= BusyMarkSizes.settingsSidebarBreakpoint;
        final headerConfiguration = HeaderBarConfigurationDefaults.of(context)
            .copyWith(
              title: title,
              viewMode: AppViewMode.editor,
              searchQuery: '',
              canRefresh: false,
              documentControlsVisible: false,
              searchActive: false,
              searchVisible: false,
              sidebarVisible: showSidebar,
              sidebarToggleVisible: false,
              backVisible: true,
            );
        final content = ColoredBox(
          key: const ValueKey('settings-content-surface'),
          color: colors.view,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!useNativeHeaderBar)
                _SettingsFallbackHeader(
                  title: title,
                  onBack: _goBack,
                  onMenuSelected: (action) =>
                      _handleMainMenuAction(context, headerBar, action),
                ),
              if (!_showSpellingDictionaries && !showSidebar)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    BusyMarkSpacing.lg,
                    BusyMarkSpacing.md,
                    BusyMarkSpacing.lg,
                    0,
                  ),
                  child: _SettingsPageSelector(
                    selected: _page,
                    onSelected: _selectPage,
                  ),
                ),
              Expanded(
                child: BusyMarkClamp(
                  maxWidth: BusyMarkSizes.settingsWidth,
                  margin: EdgeInsets.zero,
                  padding: BusyMarkInsets.settingsPage,
                  scrollable: !_showSpellingDictionaries,
                  child: pageBody,
                ),
              ),
            ],
          ),
        );
        final body = showSidebar
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: BusyMarkSizes.sidebarWidth,
                    child: _SettingsSidebar(
                      selected: _page,
                      onSelected: _selectPage,
                    ),
                  ),
                  Expanded(child: content),
                ],
              )
            : content;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) _goBack();
          },
          child: HeaderBarConfigurationPublisher(
            synchronizer: headerBar.configurationSynchronizer,
            configuration: headerConfiguration,
            enabled: headerBar.isAvailable,
            child: Scaffold(backgroundColor: colors.view, body: body),
          ),
        );
      },
    );
  }

  void _prepareSpellingSettings(
    SpellingSessionController spelling,
    String? workspaceId,
  ) {
    if (_preparingSpelling ||
        (_preparedSpellingWorkspaceId == workspaceId &&
            spelling.catalog != null)) {
      return;
    }
    _preparingSpelling = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await spelling.prepareSettings(
          ref.read(workspaceControllerProvider).workspace,
        );
        _preparedSpellingWorkspaceId = workspaceId;
      } finally {
        _preparingSpelling = false;
        if (mounted) setState(() {});
      }
    });
  }

  void _goBack() {
    if (_showSpellingDictionaries) {
      setState(() => _showSpellingDictionaries = false);
      return;
    }
    context.go(widget.returnTarget.location);
  }

  void _openSpellingDictionaries() {
    setState(() => _showSpellingDictionaries = true);
  }

  void _selectPage(SettingsPage page) {
    if (_page != page || _showSpellingDictionaries) {
      setState(() {
        _page = page;
        _showSpellingDictionaries = false;
      });
    }
    final router = GoRouter.maybeOf(context);
    final uri = router?.state.uri;
    if (router == null || uri == null || uri.path != settingsRoutePath) {
      return;
    }
    if (uri.queryParameters['page'] == settingsPageRouteValue(page)) {
      return;
    }
    unawaited(
      router.replace(
        uri
            .replace(
              queryParameters: {
                ...uri.queryParameters,
                'page': settingsPageRouteValue(page),
              },
            )
            .toString(),
      ),
    );
  }

  void _handleHeaderBarAction(
    BuildContext context,
    LinuxHeaderBarService headerBar,
    HeaderBarAction action,
  ) {
    switch (action) {
      case HeaderBarAction.back:
        _goBack();
      case HeaderBarAction.aboutBusyMark:
        showBusyMarkAboutDialog(context);
      case HeaderBarAction.keyboardShortcuts:
        showBusyMarkKeyboardShortcutsDialog(context);
      case HeaderBarAction.syntaxReference:
        showBusyMarkSyntaxReferenceDialog(context);
      case HeaderBarAction.reportIssue:
        showBusyMarkFeedbackDialog(
          context,
          headerBarService: headerBar.isAvailable ? headerBar : null,
        );
      case HeaderBarAction.settings:
        _selectPage(SettingsPage.appearance);
      case HeaderBarAction.sidebarToggle:
      case HeaderBarAction.search:
      case HeaderBarAction.refresh:
      case HeaderBarAction.save:
      case HeaderBarAction.export:
      case HeaderBarAction.fullScreen:
      case HeaderBarAction.menu:
      case HeaderBarAction.viewModeEditor:
      case HeaderBarAction.viewModeSource:
      case HeaderBarAction.viewModePreview:
      case HeaderBarAction.viewModeSplit:
      case HeaderBarAction.sidebarFiles:
      case HeaderBarAction.sidebarToc:
      case HeaderBarAction.sidebarOutline:
      case HeaderBarAction.sidebarGit:
      case HeaderBarAction.sidebarLocalHistory:
      case HeaderBarAction.sidebarClipboardHistory:
        break;
    }
  }

  void _handleMainMenuAction(
    BuildContext context,
    LinuxHeaderBarService headerBar,
    BusyMarkMainMenuAction action,
  ) {
    switch (action) {
      case BusyMarkMainMenuAction.export:
        return;
      case BusyMarkMainMenuAction.fullScreen:
        unawaited(ref.read(windowControlServiceProvider).toggleFullScreen());
      case BusyMarkMainMenuAction.settings:
        _selectPage(SettingsPage.appearance);
      case BusyMarkMainMenuAction.keyboardShortcuts:
        showBusyMarkKeyboardShortcutsDialog(context);
      case BusyMarkMainMenuAction.commandPalette:
        return;
      case BusyMarkMainMenuAction.syntaxReference:
        showBusyMarkSyntaxReferenceDialog(context);
      case BusyMarkMainMenuAction.reportIssue:
        showBusyMarkFeedbackDialog(
          context,
          headerBarService: headerBar.isAvailable ? headerBar : null,
        );
      case BusyMarkMainMenuAction.aboutBusyMark:
        showBusyMarkAboutDialog(context);
    }
  }
}

class _SpellingLanguageRow extends StatefulWidget {
  const _SpellingLanguageRow({
    required this.title,
    required this.selected,
    required this.catalogEntries,
    required this.unsetLabel,
    required this.onChanged,
    this.enabled = true,
  });

  final String title;
  final String? selected;
  final List<SpellingDictionaryEntry> catalogEntries;
  final String unsetLabel;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  State<_SpellingLanguageRow> createState() => _SpellingLanguageRowState();
}

class _SpellingLanguageRowState extends State<_SpellingLanguageRow> {
  static const _unset = '';
  late final Future<List<({String id, String label})>> _catalog =
      _loadCatalog();

  Future<List<({String id, String label})>> _loadCatalog() async {
    final source = await rootBundle.loadString(
      'assets/spelling/dictionaries.json',
    );
    final decoded = jsonDecode(source);
    final values = decoded is Map ? decoded['dictionaries'] : null;
    if (values is! List) return const [];
    return [
      for (final value in values.whereType<Map>())
        if (value['id'] case final String id when id.trim().isNotEmpty)
          (
            id: id,
            label: value['label']?.toString().trim().isNotEmpty == true
                ? value['label'].toString()
                : id,
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<({String id, String label})>>(
      future: _catalog,
      builder: (context, snapshot) {
        final dictionariesById = {
          for (final entry in snapshot.data ?? const []) entry.id: entry,
          for (final entry in widget.catalogEntries)
            entry.id: (id: entry.id, label: entry.label),
        };
        final dictionaries = dictionariesById.values.toList()
          ..sort((left, right) => left.label.compareTo(right.label));
        final selected = widget.selected ?? _unset;
        final selectedLabel = dictionaries
            .where((entry) => entry.id == widget.selected)
            .map((entry) => entry.label)
            .firstOrNull;
        return BusyMarkActionRow(
          title: widget.title,
          enabled: widget.enabled,
          leading: const Icon(BusyMarkGlyphs.symbols),
          trailing: SizedBox(
            width: BusyMarkSizes.controlRowWidth,
            child: BusyMarkPopupSelector<String>(
              value: selected,
              label: selectedLabel ?? widget.unsetLabel,
              tooltip: widget.title,
              enabled:
                  widget.enabled &&
                  snapshot.connectionState == ConnectionState.done,
              options: [
                BusyMarkPopupSelectorOption(
                  value: _unset,
                  label: widget.unsetLabel,
                ),
                for (final dictionary in dictionaries)
                  BusyMarkPopupSelectorOption(
                    value: dictionary.id,
                    label: dictionary.label,
                  ),
              ],
              onSelected: (value) {
                widget.onChanged(value == _unset ? null : value);
              },
            ),
          ),
        );
      },
    );
  }
}

class _SpellingDictionaryResourceRow extends StatelessWidget {
  const _SpellingDictionaryResourceRow({
    required this.resource,
    required this.installed,
    required this.status,
    required this.onInstall,
    required this.onRemove,
    required this.onCancel,
    required this.onRetry,
  });

  final SpellingDictionaryResource resource;
  final bool installed;
  final SpellingDictionaryInstallStatus? status;
  final VoidCallback onInstall;
  final VoidCallback onRemove;
  final VoidCallback onCancel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final active = status?.resourceId == resource.resourceId ? status : null;
    final size = _formatDictionarySize(resource.downloadSize);
    final subtitle = switch (active?.phase) {
      SpellingDictionaryInstallPhase.downloading =>
        context.l10n.spellingDictionaryDownloading(size),
      SpellingDictionaryInstallPhase.validating =>
        context.l10n.spellingDictionaryValidating,
      SpellingDictionaryInstallPhase.failed =>
        context.l10n.spellingDictionaryInstallFailed,
      null =>
        installed
            ? context.l10n.spellingDictionaryInstalled
            : context.l10n.spellingDictionaryNotInstalledWithSize(size),
    };
    final progress = active?.phase == SpellingDictionaryInstallPhase.downloading
        ? active?.progress
        : null;
    final action = switch (active?.phase) {
      SpellingDictionaryInstallPhase.downloading ||
      SpellingDictionaryInstallPhase.validating => onCancel,
      SpellingDictionaryInstallPhase.failed => onRetry,
      null => installed ? onRemove : onInstall,
    };
    final icon = switch (active?.phase) {
      SpellingDictionaryInstallPhase.downloading ||
      SpellingDictionaryInstallPhase.validating => BusyMarkGlyphs.windowClose,
      SpellingDictionaryInstallPhase.failed => BusyMarkGlyphs.refresh,
      null => installed ? BusyMarkGlyphs.delete : BusyMarkGlyphs.pull,
    };
    final tooltip = switch (active?.phase) {
      SpellingDictionaryInstallPhase.downloading ||
      SpellingDictionaryInstallPhase.validating =>
        context.l10n.cancelSpellingDictionaryInstall,
      SpellingDictionaryInstallPhase.failed =>
        context.l10n.retrySpellingDictionaryInstall,
      null =>
        installed
            ? context.l10n.removeSpellingDictionary
            : context.l10n.installSpellingDictionary,
    };
    return BusyMarkActionRow(
      title: resource.label,
      subtitleWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
          if (active != null &&
              active.phase != SpellingDictionaryInstallPhase.failed)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: LinearProgressIndicator(value: progress),
            ),
        ],
      ),
      leading: const Icon(BusyMarkGlyphs.symbols),
      trailing: BusyMarkCompactIconButton(
        tooltip: tooltip,
        icon: icon,
        foregroundColor: installed && active == null
            ? Theme.of(context).colorScheme.error
            : null,
        onPressed: action,
      ),
      onTap: action,
      destructive: installed && active == null,
    );
  }
}

class _SpellingDictionariesPage extends StatelessWidget {
  const _SpellingDictionariesPage({
    required this.catalog,
    required this.status,
    required this.importedDictionaries,
    required this.invalidImportedDictionaries,
    required this.onImport,
    required this.onInstall,
    required this.onRemoveDownloaded,
    required this.onCancel,
    required this.onRetry,
    required this.onRemoveImported,
    required this.onRemoveInvalid,
  });

  final SpellingDictionaryCatalog? catalog;
  final SpellingDictionaryInstallStatus? status;
  final List<SpellingDictionaryInstallation> importedDictionaries;
  final List<SpellingInvalidDictionaryInstallation> invalidImportedDictionaries;
  final VoidCallback onImport;
  final ValueChanged<SpellingDictionaryResource> onInstall;
  final ValueChanged<SpellingDictionaryResource> onRemoveDownloaded;
  final VoidCallback onCancel;
  final VoidCallback onRetry;
  final ValueChanged<SpellingDictionaryInstallation> onRemoveImported;
  final ValueChanged<SpellingInvalidDictionaryInstallation> onRemoveInvalid;

  @override
  Widget build(BuildContext context) {
    final resources =
        catalog?.availableEntries ?? const <SpellingDictionaryResource>[];
    final itemCount =
        1 +
        resources.length +
        importedDictionaries.length +
        invalidImportedDictionaries.length;
    return BusyMarkRichList(
      key: const ValueKey('spelling-dictionaries-list'),
      padding: EdgeInsets.zero,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == 0) {
          return BusyMarkActionRow(
            key: const ValueKey('import-spelling-dictionary'),
            title: context.l10n.importSpellingDictionary,
            leading: const Icon(BusyMarkGlyphs.add),
            onTap: onImport,
          );
        }
        var collectionIndex = index - 1;
        if (collectionIndex < resources.length) {
          final resource = resources[collectionIndex];
          return _SpellingDictionaryResourceRow(
            resource: resource,
            installed:
                catalog?.installationForResource(
                  resource.resourceId,
                  kind: SpellingDictionaryInstallationKind.downloaded,
                ) !=
                null,
            status: status,
            onInstall: () => onInstall(resource),
            onRemove: () => onRemoveDownloaded(resource),
            onCancel: onCancel,
            onRetry: onRetry,
          );
        }
        collectionIndex -= resources.length;
        if (collectionIndex < importedDictionaries.length) {
          final entry = importedDictionaries[collectionIndex];
          return BusyMarkActionRow(
            title: entry.label,
            subtitle: entry.id,
            leading: const Icon(BusyMarkGlyphs.symbols),
            trailing: const Icon(BusyMarkGlyphs.delete),
            destructive: true,
            onTap: () => onRemoveImported(entry),
          );
        }
        collectionIndex -= importedDictionaries.length;
        final entry = invalidImportedDictionaries[collectionIndex];
        return BusyMarkActionRow(
          title: entry.id ?? entry.resourceId ?? entry.directoryPath,
          subtitle: entry.error,
          leading: const Icon(BusyMarkGlyphs.warning),
          trailing: const Icon(BusyMarkGlyphs.delete),
          destructive: true,
          onTap: () => onRemoveInvalid(entry),
        );
      },
    );
  }
}

String _formatDictionarySize(int bytes) {
  final mebibytes = bytes / (1024 * 1024);
  return mebibytes >= 10
      ? '${mebibytes.toStringAsFixed(0)} MiB'
      : '${mebibytes.toStringAsFixed(1)} MiB';
}

Future<void> _setDefaultSpellingLanguage(
  BuildContext context,
  SpellingSessionController spelling,
  AppSettingsController controller,
  String? languageId,
) async {
  if (languageId != null &&
      !await _offerSpellingDictionaryInstall(context, spelling, languageId)) {
    return;
  }
  if (context.mounted) {
    await controller.setDefaultSpellingLanguage(languageId);
  }
}

Future<void> _setProjectSpellingLanguage(
  BuildContext context,
  SpellingSessionController spelling,
  String? languageId,
) async {
  if (languageId != null &&
      !await _offerSpellingDictionaryInstall(context, spelling, languageId)) {
    return;
  }
  if (!context.mounted) return;
  try {
    await spelling.setProjectLanguage(languageId);
  } on Object catch (error) {
    if (context.mounted) _showSpellingSettingsFailure(context, error);
  }
}

class _SpellingWordStoreRow extends StatelessWidget {
  const _SpellingWordStoreRow({
    required this.title,
    required this.snapshot,
    required this.onRemove,
    this.enabled = true,
  });

  final String title;
  final SpellingWordStoreSnapshot snapshot;
  final bool enabled;
  final Future<void> Function(String languageId, String word) onRemove;

  @override
  Widget build(BuildContext context) {
    final count = snapshot.wordsByLanguage.values.fold<int>(
      0,
      (total, words) => total + words.length,
    );
    return BusyMarkActionRow(
      title: title,
      subtitle: count == 0 ? context.l10n.noResults : count.toString(),
      enabled: enabled,
      leading: const Icon(BusyMarkGlyphs.symbols),
      onTap: () =>
          unawaited(_showSpellingWords(context, title, snapshot, onRemove)),
    );
  }
}

Future<void> _importSpellingDictionary(
  BuildContext context,
  SpellingSessionController spelling,
) async {
  final selected = await openFiles(
    acceptedTypeGroups: [
      XTypeGroup(
        label: context.l10n.spelling,
        extensions: const ['aff', 'dic'],
      ),
    ],
  );
  if (!context.mounted || selected.isEmpty) return;
  final affFiles = selected
      .where((file) => file.path.toLowerCase().endsWith('.aff'))
      .toList(growable: false);
  final dicFiles = selected
      .where((file) => file.path.toLowerCase().endsWith('.dic'))
      .toList(growable: false);
  if (affFiles.length != 1 || dicFiles.length != 1) {
    _showSpellingSettingsFailure(context);
    return;
  }
  final languageController = TextEditingController();
  final languageId = await showBusyMarkModalDialog<String>(
    context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      title: Text(dialogContext.l10n.importSpellingDictionary),
      content: TextField(
        controller: languageController,
        autofocus: true,
        textCapitalization: TextCapitalization.none,
        decoration: InputDecoration(
          labelText: dialogContext.l10n.language,
          hintText: 'en-US',
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) Navigator.pop(dialogContext, value);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(dialogContext.l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            final value = languageController.text.trim();
            if (value.isNotEmpty) Navigator.pop(dialogContext, value);
          },
          child: Text(dialogContext.l10n.save),
        ),
      ],
    ),
  );
  languageController.dispose();
  if (!context.mounted || languageId == null) return;
  try {
    await spelling.importDictionary(
      affPath: affFiles.single.path,
      dicPath: dicFiles.single.path,
      languageId: languageId,
      displayLabel: languageId,
    );
  } on Object {
    if (context.mounted) _showSpellingSettingsFailure(context);
  }
}

Future<void> _removeImportedSpellingDictionary(
  BuildContext context,
  SpellingSessionController spelling,
  String languageId,
) async {
  try {
    await spelling.removeImportedDictionary(languageId);
  } on Object {
    if (context.mounted) _showSpellingSettingsFailure(context);
  }
}

Future<void> _removeInvalidSpellingDictionary(
  BuildContext context,
  SpellingSessionController spelling,
  SpellingInvalidDictionaryInstallation installation,
) async {
  try {
    await spelling.removeInvalidDictionary(installation);
  } on Object {
    if (context.mounted) _showSpellingSettingsFailure(context);
  }
}

Future<void> _installSpellingDictionary(
  BuildContext context,
  SpellingSessionController spelling,
  String languageId,
) async {
  try {
    await spelling.installDictionary(languageId);
  } on Object {
    if (context.mounted) _showSpellingSettingsFailure(context);
  }
}

Future<bool> _offerSpellingDictionaryInstall(
  BuildContext context,
  SpellingSessionController spelling,
  String languageId,
) async {
  final catalog = spelling.catalog;
  if (catalog?.installedById(languageId) != null) return true;
  final resource = catalog?.availableById(languageId);
  if (resource == null) return false;
  final accepted = await showBusyMarkModalDialog<bool>(
    context,
    builder: (dialogContext) => BusyMarkDialogShell(
      title: dialogContext.l10n.spellingDictionaryNotInstalled,
      actions: [
        BusyMarkDialogButton(
          label: dialogContext.l10n.cancel,
          onPressed: () => Navigator.pop(dialogContext, false),
        ),
        BusyMarkDialogButton(
          label: dialogContext.l10n.installSpellingDictionary,
          suggested: true,
          onPressed: () => Navigator.pop(dialogContext, true),
        ),
      ],
      children: [
        Text(
          dialogContext.l10n.spellingDictionaryInstallPrompt(
            resource.label,
            _formatDictionarySize(resource.downloadSize),
          ),
        ),
      ],
    ),
  );
  if (accepted != true || !context.mounted) return false;
  try {
    await spelling.installDictionary(languageId);
  } on Object catch (error) {
    if (context.mounted) _showSpellingSettingsFailure(context, error);
    return false;
  }
  return spelling.catalog?.installedById(languageId) != null;
}

Future<void> _retrySpellingDictionary(
  BuildContext context,
  SpellingSessionController spelling,
) async {
  try {
    await spelling.retryDictionaryInstallation();
  } on Object {
    if (context.mounted) _showSpellingSettingsFailure(context);
  }
}

Future<void> _removeDownloadedSpellingDictionary(
  BuildContext context,
  SpellingSessionController spelling,
  String languageId,
) async {
  try {
    await spelling.removeDownloadedDictionary(languageId);
  } on Object {
    if (context.mounted) _showSpellingSettingsFailure(context);
  }
}

Future<void> _showSpellingWords(
  BuildContext context,
  String title,
  SpellingWordStoreSnapshot snapshot,
  Future<void> Function(String languageId, String word) remove,
) async {
  final words = [
    for (final entry in snapshot.wordsByLanguage.entries)
      for (final word in entry.value) (language: entry.key, word: word.display),
  ];
  await showBusyMarkModalDialog<void>(
    context,
    builder: (dialogContext) => BusyMarkDialogShell(
      title: title,
      actions: [
        BusyMarkDialogButton(
          label: dialogContext.l10n.close,
          onPressed: () => Navigator.pop(dialogContext),
        ),
      ],
      children: [
        if (words.isEmpty) Text(dialogContext.l10n.noResults),
        for (final entry in words)
          BusyMarkActionRow(
            title: entry.word,
            subtitle: entry.language,
            leading: const Icon(BusyMarkGlyphs.symbols),
            trailing: const Icon(BusyMarkGlyphs.delete),
            tooltip: dialogContext.l10n.removeAction,
            destructive: true,
            onTap: () async {
              try {
                await remove(entry.language, entry.word);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              } on Object catch (error) {
                if (dialogContext.mounted) {
                  _showSpellingSettingsFailure(dialogContext, error);
                }
              }
            },
          ),
      ],
    ),
  );
}

void _showSpellingSettingsFailure(BuildContext context, [Object? error]) {
  if (error is AtomicFileChangedException && error.recoveryPath != null) {
    final recoveryPath = error.recoveryPath!;
    BusyMarkToastOverlay.show(
      context,
      message: context.l10n.spellingDictionaryRecoveryConflict,
      actionLabel: context.l10n.copyPath,
      onAction: () =>
          unawaited(Clipboard.setData(ClipboardData(text: recoveryPath))),
      duration: Duration.zero,
      priority: BusyMarkToastPriority.high,
    );
    return;
  }
  BusyMarkToastOverlay.show(
    context,
    message: context.l10n.commandUnavailableInContext,
    priority: BusyMarkToastPriority.high,
  );
}

class _HistoryNumberRow extends StatelessWidget {
  const _HistoryNumberRow({
    required this.title,
    required this.value,
    required this.choices,
    required this.format,
    required this.enabled,
    required this.onChanged,
  });

  final String title;
  final int value;
  final List<int> choices;
  final String Function(int value) format;
  final bool enabled;
  final Future<void> Function(int value) onChanged;

  @override
  Widget build(BuildContext context) {
    final values = {...choices, value}.toList()..sort();
    return BusyMarkActionRow(
      title: title,
      enabled: enabled,
      leading: const Icon(BusyMarkGlyphs.history),
      trailing: DropdownButton<int>(
        value: value,
        onChanged: enabled
            ? (next) {
                if (next != null) unawaited(onChanged(next));
              }
            : null,
        items: [
          for (final choice in values)
            DropdownMenuItem(value: choice, child: Text(format(choice))),
        ],
      ),
    );
  }
}

Future<void> _editHistoryExcludedPaths(
  BuildContext context,
  List<String> current,
  Future<void> Function(Iterable<String>) save,
) async {
  final controller = TextEditingController(text: current.join('\n'));
  final result = await showBusyMarkModalDialog<String>(
    context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      title: Text(dialogContext.l10n.settingsHistoryExcludedPaths),
      content: SizedBox(
        width: BusyMarkSizes.settingsWidth,
        child: TextField(
          controller: controller,
          autofocus: true,
          minLines: 6,
          maxLines: 12,
          decoration: InputDecoration(
            hintText: dialogContext.l10n.settingsHistoryExcludedPathsHint,
            border: const OutlineInputBorder(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(dialogContext.l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, controller.text),
          child: Text(dialogContext.l10n.save),
        ),
      ],
    ),
  );
  controller.dispose();
  if (result != null) {
    await save(result.split(RegExp(r'\r?\n')));
  }
}

enum SettingsPage {
  appearance,
  editor,
  validation,
  history,
  ai,
  window,
  privacy,
  advanced,
}

SettingsPage settingsPageFromRouteValue(String? value) {
  return switch (value) {
    'editor' => SettingsPage.editor,
    'validation' => SettingsPage.validation,
    'history' => SettingsPage.history,
    'ai' => SettingsPage.ai,
    'window' => SettingsPage.window,
    'privacy' => SettingsPage.privacy,
    'advanced' => SettingsPage.advanced,
    _ => SettingsPage.appearance,
  };
}

String settingsPageRouteValue(SettingsPage page) => page.name;

String _settingsPageLabel(BuildContext context, SettingsPage page) {
  final l10n = context.l10n;
  return switch (page) {
    SettingsPage.appearance => l10n.appearance,
    SettingsPage.editor => l10n.editor,
    SettingsPage.validation => l10n.validation,
    SettingsPage.history => l10n.settingsHistory,
    SettingsPage.ai => l10n.ai,
    SettingsPage.window => l10n.settingsWindowSectionTitle,
    SettingsPage.privacy => l10n.privacy,
    SettingsPage.advanced => l10n.advanced,
  };
}

IconData _settingsPageIcon(SettingsPage page) {
  return switch (page) {
    SettingsPage.appearance => BusyMarkGlyphs.appearance,
    SettingsPage.editor => BusyMarkGlyphs.editorView,
    SettingsPage.validation => BusyMarkGlyphs.diagnostics,
    SettingsPage.history => BusyMarkGlyphs.documentHistory,
    SettingsPage.ai => BusyMarkGlyphs.ai,
    SettingsPage.window => BusyMarkGlyphs.desktop,
    SettingsPage.privacy => BusyMarkGlyphs.privacy,
    SettingsPage.advanced => BusyMarkGlyphs.settings,
  };
}

class _SettingsSidebar extends StatelessWidget {
  const _SettingsSidebar({required this.selected, required this.onSelected});

  final SettingsPage selected;
  final ValueChanged<SettingsPage> onSelected;

  @override
  Widget build(BuildContext context) {
    return BusyMarkSidebarSurface(
      child: BusyMarkSidebarNavigation(
        children: [
          for (final page in SettingsPage.values)
            BusyMarkSidebarNavigationTile(
              key: ValueKey('settings-navigation-${page.name}'),
              selected: page == selected,
              leading: Icon(_settingsPageIcon(page)),
              title: Text(_settingsPageLabel(context, page)),
              onTap: () => onSelected(page),
            ),
        ],
      ),
    );
  }
}

class _SettingsPageSelector extends StatelessWidget {
  const _SettingsPageSelector({
    required this.selected,
    required this.onSelected,
  });

  final SettingsPage selected;
  final ValueChanged<SettingsPage> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('settings-page-selector'),
      width: double.infinity,
      child: BusyMarkMenuButton<SettingsPage>(
        tooltip: _settingsPageLabel(context, selected),
        fallbackMenuWidth: BusyMarkSizes.languagePopupMaxWidth,
        items: [
          for (final page in SettingsPage.values)
            BusyMarkPopupMenuItem<SettingsPage>(
              value: page,
              label: _settingsPageLabel(context, page),
              icon: _settingsPageIcon(page),
              checked: page == selected,
              trailingCheck: true,
            ),
        ],
        onSelected: onSelected,
        triggerBuilder: (context, trigger) {
          return trigger.anchor(
            child: Tooltip(
              message: _settingsPageLabel(context, selected),
              child: Semantics(
                expanded: trigger.isOpen,
                child: BusyMarkPushButton.standard(
                  onPressed: trigger.onPressed,
                  focusNode: trigger.focusNode,
                  child: Row(
                    children: [
                      Icon(_settingsPageIcon(selected)),
                      const SizedBox(width: BusyMarkSpacing.sm),
                      Expanded(
                        child: Text(
                          _settingsPageLabel(context, selected),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(BusyMarkGlyphs.downArrow),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SettingsFallbackHeader extends StatelessWidget {
  const _SettingsFallbackHeader({
    required this.title,
    required this.onBack,
    required this.onMenuSelected,
  });

  final String title;
  final VoidCallback onBack;
  final ValueChanged<BusyMarkMainMenuAction> onMenuSelected;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return Material(
      color: colors.window,
      child: SizedBox(
        height: BusyMarkSizes.toolbarHeight,
        child: Row(
          children: [
            const SizedBox(width: BusyMarkSpacing.sm),
            BusyMarkHeaderIconButton(
              tooltip: context.l10n.back,
              icon: BusyMarkGlyphs.backFor(Directionality.of(context)),
              shortcut: BusyMarkAppShortcutLabels.back,
              onPressed: onBack,
            ),
            const SizedBox(width: BusyMarkSpacing.sm),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            BusyMarkMainMenuButton(onSelected: onMenuSelected),
            const SizedBox(width: BusyMarkSpacing.sm),
          ],
        ),
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.selectedLocaleTag,
    required this.onChanged,
  });

  final String? selectedLocaleTag;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final control = _LanguageControl(
      selectedLocaleTag: selectedLocaleTag,
      onChanged: onChanged,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < BusyMarkSizes.settingsControlBreakpoint) {
          return Padding(
            padding: const EdgeInsets.all(BusyMarkSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(BusyMarkGlyphs.symbols),
                    const SizedBox(width: BusyMarkSpacing.md),
                    Expanded(child: Text(context.l10n.appLanguage)),
                  ],
                ),
                const SizedBox(height: BusyMarkSpacing.sm),
                control,
              ],
            ),
          );
        }
        return BusyMarkActionRow(
          title: context.l10n.appLanguage,
          leading: const Icon(BusyMarkGlyphs.symbols),
          trailing: SizedBox(
            width: BusyMarkSizes.controlRowWidth,
            child: control,
          ),
        );
      },
    );
  }
}

class _LanguageControl extends StatelessWidget {
  const _LanguageControl({
    required this.selectedLocaleTag,
    required this.onChanged,
  });

  static const _systemLocaleTag = 'system';

  final String? selectedLocaleTag;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedValue = selectedLocaleTag ?? _systemLocaleTag;
    final selectedLabel = _selectedLabel(context, selectedValue);
    return BusyMarkPopupSelector<String>(
      value: selectedValue,
      label: selectedLabel,
      tooltip: context.l10n.appLanguage,
      options: [
        BusyMarkPopupSelectorOption(
          value: _systemLocaleTag,
          label: context.l10n.systemLanguage,
        ),
        for (final option in busyMarkLocaleOptions)
          BusyMarkPopupSelectorOption(value: option.tag, label: option.endonym),
      ],
      onSelected: (value) {
        onChanged(value == _systemLocaleTag ? null : value);
      },
    );
  }

  String _selectedLabel(BuildContext context, String value) {
    if (value == _systemLocaleTag) {
      return context.l10n.systemLanguage;
    }
    return busyMarkLocaleOptions
        .firstWhere(
          (option) => option.tag == value,
          orElse: () => const BusyMarkLocaleOption(
            locale: Locale('en'),
            endonym: 'English',
          ),
        )
        .endonym;
  }
}

class _ThemeModeRow extends StatelessWidget {
  const _ThemeModeRow({required this.selected, required this.onChanged});

  final BusyMarkThemeModePreference selected;
  final ValueChanged<BusyMarkThemeModePreference> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final control = _ThemeModeControl(
          selected: selected,
          onChanged: onChanged,
        );
        if (constraints.maxWidth < BusyMarkSizes.settingsControlBreakpoint) {
          return Padding(
            padding: const EdgeInsets.all(BusyMarkSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(BusyMarkGlyphs.appearance),
                    const SizedBox(width: BusyMarkSpacing.md),
                    Text(context.l10n.theme),
                  ],
                ),
                const SizedBox(height: BusyMarkSpacing.sm),
                control,
              ],
            ),
          );
        }
        return BusyMarkActionRow(
          title: context.l10n.theme,
          leading: const Icon(BusyMarkGlyphs.appearance),
          trailing: SizedBox(
            width: BusyMarkSizes.controlRowWidth,
            child: control,
          ),
        );
      },
    );
  }
}

class _ThemeModeControl extends StatelessWidget {
  const _ThemeModeControl({required this.selected, required this.onChanged});

  final BusyMarkThemeModePreference selected;
  final ValueChanged<BusyMarkThemeModePreference> onChanged;

  @override
  Widget build(BuildContext context) {
    return BusyMarkPopupSelector<BusyMarkThemeModePreference>(
      value: selected,
      label: _label(context, selected),
      tooltip: context.l10n.theme,
      options: [
        BusyMarkPopupSelectorOption(
          value: BusyMarkThemeModePreference.system,
          label: context.l10n.systemTheme,
        ),
        BusyMarkPopupSelectorOption(
          value: BusyMarkThemeModePreference.light,
          label: context.l10n.lightTheme,
        ),
        BusyMarkPopupSelectorOption(
          value: BusyMarkThemeModePreference.dark,
          label: context.l10n.darkTheme,
        ),
      ],
      onSelected: onChanged,
    );
  }

  String _label(BuildContext context, BusyMarkThemeModePreference preference) {
    return switch (preference) {
      BusyMarkThemeModePreference.system => context.l10n.systemTheme,
      BusyMarkThemeModePreference.light => context.l10n.lightTheme,
      BusyMarkThemeModePreference.dark => context.l10n.darkTheme,
    };
  }
}

class _EditorFontSizeRow extends StatelessWidget {
  const _EditorFontSizeRow({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final slider = Slider(
      value: value,
      min: 11,
      max: 24,
      divisions: 13,
      label: value.toStringAsFixed(0),
      onChanged: onChanged,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < BusyMarkSizes.settingsControlBreakpoint) {
          return Padding(
            padding: const EdgeInsets.all(BusyMarkSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(BusyMarkGlyphs.font),
                    const SizedBox(width: BusyMarkSpacing.md),
                    Expanded(
                      child: Text(
                        context.l10n.editorFontSize,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    Text(value.toStringAsFixed(0)),
                  ],
                ),
                slider,
              ],
            ),
          );
        }
        return BusyMarkActionRow(
          title: context.l10n.editorFontSize,
          subtitle: value.toStringAsFixed(0),
          leading: const Icon(BusyMarkGlyphs.font),
          trailing: SizedBox(
            width: BusyMarkSizes.sliderRowWidth,
            child: slider,
          ),
        );
      },
    );
  }
}

class _EditorToolbarPlacementRow extends StatelessWidget {
  const _EditorToolbarPlacementRow({
    required this.selected,
    required this.onChanged,
  });

  final EditorToolbarPlacement selected;
  final ValueChanged<EditorToolbarPlacement> onChanged;

  @override
  Widget build(BuildContext context) {
    return _EditorToolbarSettingRow(
      title: context.l10n.editingButtonsPosition,
      subtitle: context.l10n.editingButtonsPositionDescription,
      icon: BusyMarkGlyphs.toolbarPlacement,
      controlWidth: BusyMarkSizes.toolbarPlacementRowWidth,
      breakpoint: BusyMarkSizes.toolbarPlacementBreakpoint,
      control: _EditorToolbarPlacementControl(
        selected: selected,
        onChanged: onChanged,
      ),
    );
  }
}

class _EditorToolbarDirectionRow extends StatelessWidget {
  const _EditorToolbarDirectionRow({
    required this.selected,
    required this.onChanged,
  });

  final EditorToolbarDirection selected;
  final ValueChanged<EditorToolbarDirection> onChanged;

  @override
  Widget build(BuildContext context) {
    return _EditorToolbarSettingRow(
      title: context.l10n.editingButtonsDirection,
      subtitle: context.l10n.editingButtonsDirectionDescription,
      icon: BusyMarkGlyphs.menuHorizontal,
      controlWidth: BusyMarkSizes.controlRowWidth,
      breakpoint: BusyMarkSizes.settingsControlBreakpoint,
      control: _EditorToolbarDirectionControl(
        selected: selected,
        onChanged: onChanged,
      ),
    );
  }
}

class _EditorToolbarSettingRow extends StatelessWidget {
  const _EditorToolbarSettingRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.control,
    required this.controlWidth,
    required this.breakpoint,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget control;
  final double controlWidth;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return Padding(
            padding: const EdgeInsets.all(BusyMarkSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(icon),
                    const SizedBox(width: BusyMarkSpacing.md),
                    Expanded(child: Text(title)),
                  ],
                ),
                const SizedBox(height: BusyMarkSpacing.sm),
                control,
              ],
            ),
          );
        }
        return BusyMarkActionRow(
          title: title,
          subtitle: subtitle,
          leading: Icon(icon),
          trailing: SizedBox(width: controlWidth, child: control),
        );
      },
    );
  }
}

class _EditorToolbarPlacementControl extends StatelessWidget {
  const _EditorToolbarPlacementControl({
    required this.selected,
    required this.onChanged,
  });

  final EditorToolbarPlacement selected;
  final ValueChanged<EditorToolbarPlacement> onChanged;

  @override
  Widget build(BuildContext context) {
    return BusyMarkPopupSelector<EditorToolbarPlacement>(
      value: selected,
      label: _label(context, selected),
      tooltip: context.l10n.editingButtonsPosition,
      options: [
        BusyMarkPopupSelectorOption(
          value: EditorToolbarPlacement.topLeft,
          label: context.l10n.topLeft,
        ),
        BusyMarkPopupSelectorOption(
          value: EditorToolbarPlacement.topRight,
          label: context.l10n.topRight,
        ),
        BusyMarkPopupSelectorOption(
          value: EditorToolbarPlacement.bottomLeft,
          label: context.l10n.bottomLeft,
        ),
        BusyMarkPopupSelectorOption(
          value: EditorToolbarPlacement.bottomRight,
          label: context.l10n.bottomRight,
        ),
      ],
      onSelected: onChanged,
    );
  }

  String _label(BuildContext context, EditorToolbarPlacement placement) {
    return switch (placement) {
      EditorToolbarPlacement.topLeft => context.l10n.topLeft,
      EditorToolbarPlacement.topRight => context.l10n.topRight,
      EditorToolbarPlacement.bottomLeft => context.l10n.bottomLeft,
      EditorToolbarPlacement.bottomRight => context.l10n.bottomRight,
    };
  }
}

class _EditorToolbarDirectionControl extends StatelessWidget {
  const _EditorToolbarDirectionControl({
    required this.selected,
    required this.onChanged,
  });

  final EditorToolbarDirection selected;
  final ValueChanged<EditorToolbarDirection> onChanged;

  @override
  Widget build(BuildContext context) {
    return BusyMarkPopupSelector<EditorToolbarDirection>(
      value: selected,
      label: _label(context, selected),
      tooltip: context.l10n.editingButtonsDirection,
      options: [
        BusyMarkPopupSelectorOption(
          value: EditorToolbarDirection.horizontal,
          label: context.l10n.horizontal,
        ),
        BusyMarkPopupSelectorOption(
          value: EditorToolbarDirection.vertical,
          label: context.l10n.vertical,
        ),
      ],
      onSelected: onChanged,
    );
  }

  String _label(BuildContext context, EditorToolbarDirection direction) {
    return switch (direction) {
      EditorToolbarDirection.horizontal => context.l10n.horizontal,
      EditorToolbarDirection.vertical => context.l10n.vertical,
    };
  }
}

class _AiSettingsPage extends ConsumerStatefulWidget {
  const _AiSettingsPage();

  @override
  ConsumerState<_AiSettingsPage> createState() => _AiSettingsPageState();
}

class _AiSettingsPageState extends ConsumerState<_AiSettingsPage> {
  late final TextEditingController _endpointController;
  late final TextEditingController _apiKeyController;
  late AiProviderKind _configurationProvider;
  final Map<AiProviderKind, List<AiModelInfo>> _modelsByProvider = {};
  String? _status;
  BusyMarkStatusKind _statusKind = BusyMarkStatusKind.information;
  var _testing = false;
  var _credentialConfigured = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(appSettingsControllerProvider);
    _configurationProvider =
        settings.defaultAiProviderKind ?? AiProviderKind.ollamaLocal;
    _endpointController = TextEditingController(
      text: settings.aiOllamaEndpoint,
    );
    _apiKeyController = TextEditingController();
    unawaited(_loadCredentialState(_configurationProvider));
  }

  @override
  void dispose() {
    _endpointController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsControllerProvider);
    final controller = ref.read(appSettingsControllerProvider.notifier);
    final enabled = settings.defaultAiProviderKind != null;
    final providerKind = _configurationProvider;
    final local = providerKind == AiProviderKind.ollamaLocal;
    final cloud = providerKind.isCloud;
    final provider = ref
        .watch(aiProviderRegistryProvider)
        .require(providerKind);
    final selectedModel = settings.selectedAiModel(providerKind);
    final modelNames = <String>{
      if (selectedModel.isNotEmpty) selectedModel,
      for (final values in provider.capabilities.recommendedModels.values)
        ...values,
      for (final model
          in _modelsByProvider[providerKind] ?? const <AiModelInfo>[])
        model.name,
    }.toList(growable: false);
    final usage = ref.watch(aiMonthlyUsageProvider).value;
    return BusyMarkGroupedList(
      title: context.l10n.ai,
      filled: true,
      children: [
        BusyMarkActionRow(
          title: context.l10n.aiDefaultProvider,
          leading: const Icon(BusyMarkGlyphs.ai),
          trailing: SizedBox(
            width: BusyMarkSizes.controlRowWidth,
            child: BusyMarkPopupSelector<AiProviderPreference>(
              value: settings.aiProviderPreference,
              label: _providerLabel(settings.aiProviderPreference),
              tooltip: context.l10n.aiDefaultProvider,
              options: [
                BusyMarkPopupSelectorOption(
                  value: AiProviderPreference.disabled,
                  label: context.l10n.aiDisabled,
                ),
                BusyMarkPopupSelectorOption(
                  value: AiProviderPreference.ollamaLocal,
                  label: context.l10n.aiLocalOllama,
                ),
                BusyMarkPopupSelectorOption(
                  value: AiProviderPreference.openAi,
                  label: AiProviderKind.openAi.displayName,
                ),
                BusyMarkPopupSelectorOption(
                  value: AiProviderPreference.gemini,
                  label: AiProviderKind.gemini.displayName,
                ),
              ],
              onSelected: (preference) =>
                  unawaited(_selectDefaultProvider(preference)),
            ),
          ),
        ),
        BusyMarkActionRow(
          title: context.l10n.aiConfigureProvider,
          leading: const Icon(BusyMarkGlyphs.settings),
          trailing: SizedBox(
            width: BusyMarkSizes.controlRowWidth,
            child: BusyMarkPopupSelector<AiProviderKind>(
              value: providerKind,
              label: _providerKindLabel(providerKind),
              tooltip: context.l10n.aiConfigureProvider,
              options: [
                for (final kind in AiProviderKind.values)
                  BusyMarkPopupSelectorOption(
                    value: kind,
                    label: _providerKindLabel(kind),
                  ),
              ],
              onSelected: !_testing
                  ? (kind) => unawaited(_selectConfigurationProvider(kind))
                  : (_) {},
            ),
          ),
        ),
        if (local)
          BusyMarkGroupedTextEntry(
            key: const ValueKey('ai-ollama-endpoint'),
            label: context.l10n.aiOllamaEndpoint,
            controller: _endpointController,
            enabled: !_testing,
            textInputAction: TextInputAction.done,
            onSubmitted: _saveEndpoint,
          ),
        if (cloud) ...[
          BusyMarkGroupedTextEntry(
            key: ValueKey('ai-api-key-${providerKind.id}'),
            label: context.l10n.aiApiKey,
            hintText: _credentialConfigured
                ? context.l10n.aiApiKeyStoredHint
                : context.l10n.aiApiKeyEnterHint,
            controller: _apiKeyController,
            enabled: !_testing,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => unawaited(_saveApiKey(providerKind)),
          ),
          BusyMarkActionRow(
            title: _credentialConfigured
                ? context.l10n.aiReplaceApiKey
                : context.l10n.aiSaveApiKey,
            leading: const Icon(BusyMarkGlyphs.check),
            onTap: !_testing && _apiKeyController.text.trim().isNotEmpty
                ? () => _saveApiKey(providerKind)
                : null,
          ),
          if (_credentialConfigured)
            BusyMarkActionRow(
              title: context.l10n.aiRemoveApiKey,
              leading: const Icon(BusyMarkGlyphs.delete),
              onTap: !_testing ? () => _removeApiKey(providerKind) : null,
            ),
        ],
        if (enabled)
          BusyMarkActionRow(
            title: context.l10n.aiModelRouting,
            leading: const Icon(BusyMarkGlyphs.ai),
            trailing: SizedBox(
              width: BusyMarkSizes.controlRowWidth,
              child: BusyMarkPopupSelector<AiModelRoutingPreference>(
                value: settings.aiModelRoutingPreference,
                label:
                    settings.aiModelRoutingPreference ==
                        AiModelRoutingPreference.automatic
                    ? context.l10n.aiAutomaticRouting
                    : context.l10n.aiFixedModelRouting,
                tooltip: context.l10n.aiModelRouting,
                options: [
                  BusyMarkPopupSelectorOption(
                    value: AiModelRoutingPreference.automatic,
                    label: context.l10n.aiAutomaticRouting,
                  ),
                  BusyMarkPopupSelectorOption(
                    value: AiModelRoutingPreference.fixed,
                    label: context.l10n.aiFixedModelRouting,
                  ),
                ],
                onSelected: controller.setAiModelRoutingPreference,
              ),
            ),
          ),
        BusyMarkActionRow(
          title: local
              ? context.l10n.aiOllamaModel
              : context.l10n.aiPreferredModel,
          leading: const Icon(BusyMarkGlyphs.ai),
          trailing: SizedBox(
            width: BusyMarkSizes.controlRowWidth,
            child: modelNames.isEmpty
                ? Text(
                    selectedModel.isEmpty
                        ? context.l10n.aiNoModels
                        : selectedModel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                : BusyMarkPopupSelector<String>(
                    value: selectedModel.isEmpty
                        ? modelNames.first
                        : selectedModel,
                    label: selectedModel.isEmpty
                        ? modelNames.first
                        : selectedModel,
                    tooltip: local
                        ? context.l10n.aiOllamaModel
                        : context.l10n.aiPreferredModel,
                    options: [
                      for (final model in modelNames)
                        BusyMarkPopupSelectorOption(value: model, label: model),
                    ],
                    onSelected: (model) =>
                        _saveSelectedModel(providerKind, model),
                  ),
          ),
        ),
        BusyMarkActionRow(
          title: _testing
              ? context.l10n.aiTestingConnection
              : context.l10n.aiTestConnection,
          leading: _testing
              ? const SizedBox.square(
                  dimension: BusyMarkSizes.iconSm,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(BusyMarkGlyphs.refresh),
          onTap: !_testing && (!cloud || _credentialConfigured)
              ? _testConnection
              : null,
        ),
        if (usage != null)
          BusyMarkActionRow(
            title: context.l10n.aiUsageThisMonth(
              usage.requests,
              usage.inputTokens,
              usage.outputTokens,
            ),
            leading: const Icon(BusyMarkGlyphs.info),
          ),
        if (_status != null)
          Padding(
            padding: const EdgeInsets.all(BusyMarkSpacing.md),
            child: BusyMarkStatusBox(message: _status!, kind: _statusKind),
          ),
      ],
    );
  }

  Future<void> _testConnection() async {
    final l10n = context.l10n;
    setState(() {
      _testing = true;
      _status = null;
    });
    final settingsController = ref.read(appSettingsControllerProvider.notifier);
    final cancellationToken = AiCancellationToken();
    final totalTestDeadline = Timer(
      const Duration(minutes: 5),
      cancellationToken.cancel,
    );
    try {
      var settings = ref.read(appSettingsControllerProvider);
      final providerKind = _configurationProvider;
      if (providerKind.isCloud && !settings.hasCloudConsent(providerKind)) {
        final confirmed = await _confirmCloudConsent(providerKind);
        if (!confirmed) {
          return;
        }
        settings = ref.read(appSettingsControllerProvider);
      }
      if (providerKind == AiProviderKind.ollamaLocal) {
        final endpoint = AiPolicy.validateLocalOllamaEndpoint(
          _endpointController.text,
        );
        await settingsController.setAiOllamaEndpoint(endpoint.origin);
        settings = ref.read(appSettingsControllerProvider);
      }
      final provider = ref
          .read(aiProviderRegistryProvider)
          .require(providerKind);
      final models = await provider.listModels(
        cancellationToken: cancellationToken,
      );
      final selected = settings.selectedAiModel(providerKind);
      final candidates =
          selected.isNotEmpty && models.any((model) => model.name == selected)
          ? [selected]
          : [for (final model in models) model.name];
      if (candidates.isEmpty) {
        throw AiException(
          AiFailureCode.invalidConfiguration,
          l10n.aiNoCompatibleModels,
        );
      }
      AiHealthResult? health;
      AiException? lastFailure;
      for (final model in candidates) {
        try {
          health = await provider.checkHealth(
            model: model,
            cancellationToken: cancellationToken,
          );
          break;
        } on AiException catch (error) {
          lastFailure = error;
          if (selected.isNotEmpty) {
            rethrow;
          }
        }
      }
      if (health == null) {
        throw lastFailure ??
            AiException(
              AiFailureCode.invalidConfiguration,
              l10n.aiNoCompatibleModels,
            );
      }
      await _saveSelectedModel(providerKind, health.model.name);
      if (!mounted) {
        return;
      }
      setState(() {
        _modelsByProvider[providerKind] = health!.models;
        final verified = l10n.aiGenerationVerified(
          health.model.displayName ?? health.model.name,
          health.models.length,
        );
        _status = health.coldStartDuration == null
            ? verified
            : '$verified\n${l10n.aiColdStartObserved}';
        _statusKind = BusyMarkStatusKind.success;
      });
    } on AiException catch (error) {
      if (mounted) {
        setState(() {
          _status = error.message;
          _statusKind = BusyMarkStatusKind.error;
        });
      }
    } on Object {
      if (mounted) {
        setState(() {
          _status = context.l10n.aiConnectionFailed;
          _statusKind = BusyMarkStatusKind.error;
        });
      }
    } finally {
      totalTestDeadline.cancel();
      await cancellationToken.dispose();
      if (mounted) {
        setState(() => _testing = false);
      }
    }
  }

  Future<void> _selectDefaultProvider(AiProviderPreference preference) async {
    final kind = switch (preference) {
      AiProviderPreference.disabled => null,
      AiProviderPreference.ollamaLocal => AiProviderKind.ollamaLocal,
      AiProviderPreference.openAi => AiProviderKind.openAi,
      AiProviderPreference.gemini => AiProviderKind.gemini,
    };
    final settings = ref.read(appSettingsControllerProvider);
    if (kind?.isCloud == true && !settings.hasCloudConsent(kind!)) {
      if (!await _confirmCloudConsent(kind) || !mounted) {
        return;
      }
    }
    await ref
        .read(appSettingsControllerProvider.notifier)
        .setAiProviderPreference(preference);
    if (!mounted) {
      return;
    }
  }

  Future<void> _selectConfigurationProvider(AiProviderKind provider) async {
    if (provider == _configurationProvider) {
      return;
    }
    _apiKeyController.clear();
    setState(() {
      _configurationProvider = provider;
      _status = null;
      _credentialConfigured = false;
    });
    await _loadCredentialState(provider);
  }

  Future<void> _loadCredentialState(AiProviderKind kind) async {
    if (!kind.isCloud) {
      if (mounted && _configurationProvider == kind) {
        setState(() => _credentialConfigured = false);
      }
      return;
    }
    try {
      final stored = await ref.read(aiSecretStoreProvider).read(kind);
      if (mounted && _configurationProvider == kind) {
        setState(() => _credentialConfigured = stored != null);
      }
    } on AiException catch (error) {
      if (mounted && _configurationProvider == kind) {
        setState(() {
          _status = error.message;
          _statusKind = BusyMarkStatusKind.error;
        });
      }
    }
  }

  Future<void> _saveApiKey(AiProviderKind provider) async {
    try {
      await ref
          .read(aiSecretStoreProvider)
          .write(provider, _apiKeyController.text);
      if (mounted && _configurationProvider == provider) {
        _apiKeyController.clear();
        setState(() {
          _credentialConfigured = true;
          _status = context.l10n.aiCredentialSaved;
          _statusKind = BusyMarkStatusKind.success;
        });
      }
    } on AiException catch (error) {
      if (mounted && _configurationProvider == provider) {
        setState(() {
          _status = error.message;
          _statusKind = BusyMarkStatusKind.error;
        });
      }
    }
  }

  Future<void> _removeApiKey(AiProviderKind provider) async {
    try {
      await ref.read(aiSecretStoreProvider).delete(provider);
      if (mounted && _configurationProvider == provider) {
        _apiKeyController.clear();
        setState(() {
          _credentialConfigured = false;
          _status = context.l10n.aiCredentialRemoved;
          _statusKind = BusyMarkStatusKind.success;
        });
      }
    } on AiException catch (error) {
      if (mounted && _configurationProvider == provider) {
        setState(() {
          _status = error.message;
          _statusKind = BusyMarkStatusKind.error;
        });
      }
    }
  }

  Future<void> _saveSelectedModel(AiProviderKind provider, String model) {
    final controller = ref.read(appSettingsControllerProvider.notifier);
    return switch (provider) {
      AiProviderKind.ollamaLocal => controller.setAiOllamaModel(model),
      AiProviderKind.openAi => controller.setAiOpenAiModel(model),
      AiProviderKind.gemini => controller.setAiGeminiModel(model),
    };
  }

  String _providerLabel(AiProviderPreference preference) =>
      switch (preference) {
        AiProviderPreference.disabled => context.l10n.aiDisabled,
        AiProviderPreference.ollamaLocal => context.l10n.aiLocalOllama,
        AiProviderPreference.openAi => 'OpenAI',
        AiProviderPreference.gemini => 'Google Gemini',
      };

  String _providerKindLabel(AiProviderKind provider) => switch (provider) {
    AiProviderKind.ollamaLocal => context.l10n.aiLocalOllama,
    AiProviderKind.openAi => 'OpenAI',
    AiProviderKind.gemini => 'Google Gemini',
  };

  Future<bool> _confirmCloudConsent(AiProviderKind provider) async {
    final confirmed = await showBusyMarkModalDialog<bool>(
      context,
      builder: (dialogContext) => BusyMarkDialogShell(
        title: dialogContext.l10n.aiCloudConsentTitle(provider.displayName),
        actions: [
          BusyMarkDialogButton(
            label: dialogContext.l10n.cancel,
            onPressed: () => Navigator.pop(dialogContext, false),
          ),
          BusyMarkDialogButton(
            label: dialogContext.l10n.aiCloudConsentEnable(
              provider.displayName,
            ),
            suggested: true,
            onPressed: () => Navigator.pop(dialogContext, true),
          ),
        ],
        children: [Text(dialogContext.l10n.aiCloudConsentMessage)],
      ),
    );
    if (confirmed != true || !mounted) {
      return false;
    }
    await ref
        .read(appSettingsControllerProvider.notifier)
        .grantAiCloudProviderConsent(provider.id);
    return mounted;
  }

  Future<void> _saveEndpoint(String value) async {
    try {
      final endpoint = AiPolicy.validateLocalOllamaEndpoint(value);
      _endpointController.text = endpoint.origin;
      await ref
          .read(appSettingsControllerProvider.notifier)
          .setAiOllamaEndpoint(endpoint.origin);
      if (mounted) {
        setState(() => _status = null);
      }
    } on AiException catch (error) {
      if (mounted) {
        setState(() {
          _status = error.message;
          _statusKind = BusyMarkStatusKind.error;
        });
      }
    }
  }
}
