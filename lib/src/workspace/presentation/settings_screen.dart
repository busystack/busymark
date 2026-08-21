import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import '../../app/localization.dart';
import '../../app/window_control_service.dart';
import '../../feedback/presentation/feedback_dialog.dart';
import '../../platform/linux_header_bar_service.dart';

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

  @override
  void didUpdateWidget(covariant SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPage != widget.initialPage) {
      _page = widget.initialPage;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(appSettingsControllerProvider);
    final controller = ref.read(appSettingsControllerProvider.notifier);
    final colors = BusyMarkSurfaceColors.of(context);
    final headerBar = ref.watch(linuxHeaderBarServiceProvider);
    final useNativeHeaderBar = headerBar.usesNativeHeaderBar;
    final title = _settingsPageLabel(context, _page);
    ref.listen(headerBarActionsProvider, (previous, next) {
      next.whenData((event) {
        _handleHeaderBarAction(context, headerBar, event.action);
      });
    });
    final pageBody = switch (_page) {
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
      SettingsPage.editor => BusyMarkGroupedList(
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
      SettingsPage.ai => const _AiSettingsPage(),
      SettingsPage.window => BusyMarkGroupedList(
        title: l10n.settingsWindowSectionTitle,
        filled: true,
        children: [
          BusyMarkSwitchRow(
            title: l10n.settingsConfirmCloseWithUnsavedChangesTitle,
            subtitle: l10n.settingsConfirmCloseWithUnsavedChangesDescription,
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
              if (!showSidebar)
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

        return HeaderBarConfigurationPublisher(
          synchronizer: headerBar.configurationSynchronizer,
          configuration: headerConfiguration,
          enabled: headerBar.isAvailable,
          child: Scaffold(backgroundColor: colors.view, body: body),
        );
      },
    );
  }

  void _goBack() {
    context.go(widget.returnTarget.location);
  }

  void _selectPage(SettingsPage page) {
    if (_page != page) {
      setState(() => _page = page);
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
      case HeaderBarAction.markdownAndHtml:
        showBusyMarkMarkdownHtmlDialog(context);
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
      case HeaderBarAction.exportPdf:
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
        break;
    }
  }

  void _handleMainMenuAction(
    BuildContext context,
    LinuxHeaderBarService headerBar,
    BusyMarkMainMenuAction action,
  ) {
    switch (action) {
      case BusyMarkMainMenuAction.exportPdf:
      case BusyMarkMainMenuAction.generateMarkdownToc:
        break;
      case BusyMarkMainMenuAction.fullScreen:
        unawaited(ref.read(windowControlServiceProvider).toggleFullScreen());
      case BusyMarkMainMenuAction.settings:
        _selectPage(SettingsPage.appearance);
      case BusyMarkMainMenuAction.keyboardShortcuts:
        showBusyMarkKeyboardShortcutsDialog(context);
      case BusyMarkMainMenuAction.commandPalette:
        return;
      case BusyMarkMainMenuAction.markdownAndHtml:
        showBusyMarkMarkdownHtmlDialog(context);
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

enum SettingsPage {
  appearance,
  editor,
  validation,
  ai,
  window,
  privacy,
  advanced,
}

SettingsPage settingsPageFromRouteValue(String? value) {
  return switch (value) {
    'editor' => SettingsPage.editor,
    'validation' => SettingsPage.validation,
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
  List<AiModelInfo> _models = const [];
  String? _status;
  BusyMarkStatusKind _statusKind = BusyMarkStatusKind.information;
  var _testing = false;
  var _credentialConfigured = false;

  @override
  void initState() {
    super.initState();
    _endpointController = TextEditingController(
      text: ref.read(appSettingsControllerProvider).aiOllamaEndpoint,
    );
    _apiKeyController = TextEditingController();
    unawaited(_loadCredentialState());
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
    final providerKind = settings.aiProviderKind;
    final enabled = providerKind != null;
    final local = providerKind == AiProviderKind.ollamaLocal;
    final cloud = providerKind?.isCloud ?? false;
    final provider = providerKind == null
        ? null
        : ref.watch(aiProviderRegistryProvider).require(providerKind);
    final selectedModel = providerKind == null
        ? ''
        : settings.selectedAiModel(providerKind);
    final modelNames = <String>{
      if (selectedModel.isNotEmpty) selectedModel,
      if (provider != null)
        for (final values in provider.capabilities.recommendedModels.values)
          ...values,
      for (final model in _models) model.name,
    }.toList(growable: false);
    final usage = ref.watch(aiMonthlyUsageProvider).value;
    return BusyMarkGroupedList(
      title: context.l10n.ai,
      filled: true,
      children: [
        Padding(
          padding: const EdgeInsets.all(BusyMarkSpacing.md),
          child: BusyMarkStatusBox(
            message: _privacyDescription(providerKind),
            kind: BusyMarkStatusKind.information,
          ),
        ),
        BusyMarkActionRow(
          title: context.l10n.aiProvider,
          leading: const Icon(BusyMarkGlyphs.ai),
          trailing: SizedBox(
            width: BusyMarkSizes.controlRowWidth,
            child: BusyMarkPopupSelector<AiProviderPreference>(
              value: settings.aiProviderPreference,
              label: _providerLabel(settings.aiProviderPreference),
              tooltip: context.l10n.aiProvider,
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
                  unawaited(_selectProvider(preference)),
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
            key: ValueKey('ai-api-key-${providerKind!.id}'),
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
                    onSelected: enabled
                        ? (model) => _saveSelectedModel(providerKind, model)
                        : (_) {},
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
          onTap: enabled && !_testing && (!cloud || _credentialConfigured)
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
      final providerKind = settings.aiProviderKind;
      if (providerKind == null) {
        throw AiException(
          AiFailureCode.invalidConfiguration,
          l10n.aiEnableProvider,
        );
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
        _models = health!.models;
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

  Future<void> _selectProvider(AiProviderPreference preference) async {
    final kind = switch (preference) {
      AiProviderPreference.disabled => null,
      AiProviderPreference.ollamaLocal => AiProviderKind.ollamaLocal,
      AiProviderPreference.openAi => AiProviderKind.openAi,
      AiProviderPreference.gemini => AiProviderKind.gemini,
    };
    final settings = ref.read(appSettingsControllerProvider);
    if (kind?.isCloud == true && !settings.hasCloudConsent(kind!)) {
      final confirmed = await showBusyMarkModalDialog<bool>(
        context,
        builder: (dialogContext) => BusyMarkDialogShell(
          title: dialogContext.l10n.aiCloudConsentTitle(kind.displayName),
          actions: [
            BusyMarkDialogButton(
              label: dialogContext.l10n.cancel,
              onPressed: () => Navigator.pop(dialogContext, false),
            ),
            BusyMarkDialogButton(
              label: dialogContext.l10n.aiCloudConsentEnable(kind.displayName),
              suggested: true,
              onPressed: () => Navigator.pop(dialogContext, true),
            ),
          ],
          children: [Text(dialogContext.l10n.aiCloudConsentMessage)],
        ),
      );
      if (confirmed != true || !mounted) {
        return;
      }
      await ref
          .read(appSettingsControllerProvider.notifier)
          .grantAiCloudProviderConsent(kind.id);
    }
    await ref
        .read(appSettingsControllerProvider.notifier)
        .setAiProviderPreference(preference);
    if (!mounted) {
      return;
    }
    _apiKeyController.clear();
    setState(() {
      _models = const [];
      _status = null;
      _credentialConfigured = false;
    });
    await _loadCredentialState();
  }

  Future<void> _loadCredentialState() async {
    final kind = ref.read(appSettingsControllerProvider).aiProviderKind;
    if (kind?.isCloud != true) {
      if (mounted) {
        setState(() => _credentialConfigured = false);
      }
      return;
    }
    try {
      final stored = await ref.read(aiSecretStoreProvider).read(kind!);
      if (mounted &&
          ref.read(appSettingsControllerProvider).aiProviderKind == kind) {
        setState(() => _credentialConfigured = stored != null);
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

  Future<void> _saveApiKey(AiProviderKind provider) async {
    try {
      await ref
          .read(aiSecretStoreProvider)
          .write(provider, _apiKeyController.text);
      if (mounted) {
        _apiKeyController.clear();
        setState(() {
          _credentialConfigured = true;
          _status = context.l10n.aiCredentialSaved;
          _statusKind = BusyMarkStatusKind.success;
        });
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

  Future<void> _removeApiKey(AiProviderKind provider) async {
    try {
      await ref.read(aiSecretStoreProvider).delete(provider);
      if (mounted) {
        _apiKeyController.clear();
        setState(() {
          _credentialConfigured = false;
          _status = context.l10n.aiCredentialRemoved;
          _statusKind = BusyMarkStatusKind.success;
        });
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

  String _privacyDescription(AiProviderKind? provider) => switch (provider) {
    null => context.l10n.aiPrivacyDisabled,
    AiProviderKind.ollamaLocal => context.l10n.aiPrivacyLocal,
    AiProviderKind.openAi ||
    AiProviderKind.gemini => context.l10n.aiPrivacyCloud(provider.displayName),
  };

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
