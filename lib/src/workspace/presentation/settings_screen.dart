import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../app/app_settings.dart';
import '../../app/busymark_dialogs.dart';
import '../../app/busymark_design.dart';
import '../../app/busymark_glyphs.dart';
import '../../app/busymark_main_menu.dart';
import '../../app/localization.dart';
import '../../feedback/presentation/feedback_dialog.dart';
import '../../platform/linux_header_bar_service.dart';
import '../workspace_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(appSettingsControllerProvider);
    final controller = ref.watch(appSettingsControllerProvider.notifier);
    final workspaceOpen =
        ref.watch(workspaceControllerProvider).workspace != null;
    final colors = BusyMarkSurfaceColors.of(context);
    final headerBar = ref.watch(linuxHeaderBarServiceProvider);
    final useNativeHeaderBar = headerBar.usesNativeHeaderBar;
    ref.listen(headerBarActionsProvider, (previous, next) {
      next.whenData((event) {
        _handleHeaderBarAction(context, workspaceOpen, headerBar, event.action);
      });
    });
    if (headerBar.isAvailable) {
      _configureHeaderBar(context, headerBar);
    }

    return Scaffold(
      backgroundColor: colors.view,
      appBar: useNativeHeaderBar
          ? null
          : AppBar(
              leadingWidth: 50,
              titleSpacing: 0,
              leading: Center(
                child: BusyMarkHeaderIconButton(
                  tooltip: context.l10n.back,
                  icon: BusyMarkGlyphs.backFor(Directionality.of(context)),
                  onPressed: () =>
                      context.go(workspaceOpen ? '/workspace' : '/'),
                ),
              ),
              title: Text(
                context.l10n.settingsTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              actions: [
                BusyMarkMainMenuButton(
                  onSelected: (action) =>
                      _handleMainMenuAction(context, headerBar, action),
                ),
                const SizedBox(width: BusyMarkSpacing.sm),
              ],
            ),
      body: BusyMarkClamp(
        maxWidth: BusyMarkSizes.settingsWidth,
        margin: EdgeInsets.zero,
        padding: BusyMarkInsets.settingsPage,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BusyMarkGroupedList(
              title: context.l10n.appearance,
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
            BusyMarkGroupedList(
              title: context.l10n.editor,
              filled: true,
              children: [
                BusyMarkSwitchRow(
                  title: context.l10n.autoSave,
                  subtitle: context.l10n.autoSaveDescription,
                  value: settings.autoSave,
                  onChanged: controller.setAutoSave,
                  leading: const Icon(BusyMarkGlyphs.save),
                ),
                BusyMarkSwitchRow(
                  title: context.l10n.wordWrap,
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
            BusyMarkGroupedList(
              title: context.l10n.validation,
              filled: true,
              children: [
                BusyMarkSwitchRow(
                  title: context.l10n.validateOnEdit,
                  value: settings.validateOnEdit,
                  onChanged: controller.setValidateOnEdit,
                  leading: const Icon(BusyMarkGlyphs.diagnostics),
                ),
              ],
            ),
            BusyMarkGroupedList(
              title: l10n.settingsWindowSectionTitle,
              filled: true,
              children: [
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
            BusyMarkGroupedList(
              title: context.l10n.privacy,
              filled: true,
              children: [
                BusyMarkSwitchRow(
                  title: context.l10n.allowRemoteImages,
                  subtitle: context.l10n.allowRemoteImagesDescription,
                  value: settings.allowRemoteImages,
                  onChanged: controller.setAllowRemoteImages,
                  leading: const Icon(BusyMarkGlyphs.image),
                ),
                if (settings.remoteImageAllowedWorkspacePaths.isNotEmpty)
                  BusyMarkActionRow(
                    title: context.l10n.clearRemoteImagePermissions,
                    subtitle:
                        context.l10n.clearRemoteImagePermissionsDescription,
                    leading: const Icon(BusyMarkGlyphs.clearAll),
                    onTap: controller.clearRemoteImageWorkspacePermissions,
                  ),
                if (settings.trustedGitWorkspacePaths.isNotEmpty)
                  BusyMarkActionRow(
                    title: context.l10n.clearGitWorkspaceTrust,
                    subtitle: context.l10n.clearGitWorkspaceTrustDescription,
                    leading: const Icon(BusyMarkGlyphs.clearAll),
                    onTap: controller.clearTrustedGitWorkspaces,
                  ),
              ],
            ),
            BusyMarkGroupedList(
              title: context.l10n.advanced,
              filled: true,
              children: [
                BusyMarkActionRow(
                  title: context.l10n.clearRecentWorkspaces,
                  leading: const Icon(BusyMarkGlyphs.clearAll),
                  destructive: true,
                  onTap: controller.clearRecentWorkspaces,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _configureHeaderBar(
    BuildContext context,
    LinuxHeaderBarService headerBar,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(() async {
        await headerBar.setTitleRange(context.l10n.settings);
        await headerBar.setSidebarVisible(false);
        await headerBar.setSidebarToggleVisible(false);
        await headerBar.setSearchVisible(false);
        await headerBar.setBackVisible(true);
        await headerBar.setDocumentControlsVisible(false);
        await headerBar.setCanRefresh(false);
        await headerBar.setSearchActive(false);
      }());
    });
  }

  void _handleHeaderBarAction(
    BuildContext context,
    bool workspaceOpen,
    LinuxHeaderBarService headerBar,
    HeaderBarAction action,
  ) {
    switch (action) {
      case HeaderBarAction.back:
        context.go(workspaceOpen ? '/workspace' : '/');
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
      case HeaderBarAction.sidebarToggle:
      case HeaderBarAction.search:
      case HeaderBarAction.refresh:
      case HeaderBarAction.save:
      case HeaderBarAction.menu:
      case HeaderBarAction.viewModeEditor:
      case HeaderBarAction.viewModeSource:
      case HeaderBarAction.viewModePreview:
      case HeaderBarAction.viewModeSplit:
        break;
    }
  }

  void _handleMainMenuAction(
    BuildContext context,
    LinuxHeaderBarService headerBar,
    BusyMarkMainMenuAction action,
  ) {
    switch (action) {
      case BusyMarkMainMenuAction.settings:
        break;
      case BusyMarkMainMenuAction.keyboardShortcuts:
        showBusyMarkKeyboardShortcutsDialog(context);
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
    final colors = BusyMarkSurfaceColors.of(context);
    final theme = Theme.of(context);
    final popupTheme = theme.popupMenuTheme;
    final selectedValue = selectedLocaleTag ?? _systemLocaleTag;
    final selectedLabel = _selectedLabel(context, selectedValue);
    final escapeDismiss = BusyMarkPopupEscapeDismissBinding(
      Navigator.of(context, rootNavigator: true),
    );
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: PopupMenuButton<String>(
        tooltip: context.l10n.appLanguage,
        padding: EdgeInsets.zero,
        position: PopupMenuPosition.under,
        offset: const Offset(0, BusyMarkSpacing.xs + BusyMarkSpacing.xxs),
        color: popupTheme.color ?? colors.popover,
        surfaceTintColor: BusyMarkLinuxPalette.transparent,
        elevation: BusyMarkElevation.window,
        shadowColor: colors.shade.withValues(
          alpha: BusyMarkAlpha.languageMenuShadow,
        ),
        shape:
            popupTheme.shape ??
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(BusyMarkRadius.md),
            ),
        constraints: const BoxConstraints(
          minWidth: BusyMarkSizes.languagePopupMinWidth,
          maxWidth: BusyMarkSizes.languagePopupMaxWidth,
        ),
        useRootNavigator: true,
        requestFocus: true,
        onOpened: escapeDismiss.attach,
        onCanceled: escapeDismiss.detach,
        onSelected: (value) {
          escapeDismiss.detach();
          onChanged(value == _systemLocaleTag ? null : value);
        },
        itemBuilder: (context) => [
          _languageMenuItem(
            context,
            value: _systemLocaleTag,
            label: context.l10n.systemLanguage,
            selected: selectedValue == _systemLocaleTag,
          ),
          for (final option in _languageOptions())
            _languageMenuItem(
              context,
              value: option.localeTag,
              label: option.label,
              selected: selectedValue == option.localeTag,
            ),
        ],
        child: _LanguageSelectorButton(label: selectedLabel),
      ),
    );
  }

  PopupMenuItem<String> _languageMenuItem(
    BuildContext context, {
    required String value,
    required String label,
    required bool selected,
  }) {
    final colors = BusyMarkSurfaceColors.of(context);
    return PopupMenuItem<String>(
      value: value,
      height: BusyMarkSizes.popupMenuItemHeight,
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: BusyMarkSpacing.sm),
        child: Row(
          children: [
            SizedBox(
              width: BusyMarkSizes.iconSm,
              child: selected
                  ? Icon(
                      BusyMarkGlyphs.check,
                      size: BusyMarkSizes.iconSm,
                      color: colors.mutedForeground,
                    )
                  : null,
            ),
            const SizedBox(width: BusyMarkSpacing.sm),
            Expanded(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  String _selectedLabel(BuildContext context, String value) {
    if (value == _systemLocaleTag) {
      return context.l10n.systemLanguage;
    }
    return _languageOptions()
        .firstWhere(
          (option) => option.localeTag == value,
          orElse: () => const _LanguageOption('en', 'English'),
        )
        .label;
  }

  List<_LanguageOption> _languageOptions() {
    return const [
      _LanguageOption('en', 'English'),
      _LanguageOption('et', 'Eesti'),
      _LanguageOption('de', 'Deutsch'),
      _LanguageOption('it', 'Italiano'),
      _LanguageOption('nb', 'Norsk'),
      _LanguageOption('fr', 'Français'),
      _LanguageOption('ru', 'Русский'),
      _LanguageOption('uk', 'Українська'),
      _LanguageOption('pl', 'Polski'),
      _LanguageOption('es', 'Español'),
      _LanguageOption('pt', 'Português'),
      _LanguageOption('ar', 'العربية'),
      _LanguageOption('fa', 'فارسی'),
      _LanguageOption('hi', 'हिन्दी'),
    ];
  }
}

class _LanguageSelectorButton extends StatefulWidget {
  const _LanguageSelectorButton({required this.label});

  final String label;

  @override
  State<_LanguageSelectorButton> createState() =>
      _LanguageSelectorButtonState();
}

class _LanguageSelectorButtonState extends State<_LanguageSelectorButton> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final theme = Theme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (!_hovered) {
          setState(() => _hovered = true);
        }
      },
      onExit: (_) {
        if (_hovered) {
          setState(() => _hovered = false);
        }
      },
      child: Container(
        constraints: const BoxConstraints(
          minHeight: BusyMarkSizes.iconButton,
          maxWidth: BusyMarkSizes.languageButtonMaxWidth,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: BusyMarkSpacing.sm,
          vertical: BusyMarkSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: _hovered
              ? colors.controlHover
              : BusyMarkLinuxPalette.transparent,
          borderRadius: BorderRadius.circular(BusyMarkRadius.headerButton),
          border: Border.all(
            color: _hovered
                ? colors.subtleBorder
                : BusyMarkLinuxPalette.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                textAlign: TextAlign.end,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.foreground,
                ),
              ),
            ),
            const SizedBox(width: BusyMarkSpacing.sm),
            Icon(
              BusyMarkGlyphs.downArrow,
              size: BusyMarkSizes.iconSm,
              color: colors.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOption {
  const _LanguageOption(this.localeTag, this.label);

  final String localeTag;
  final String label;
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
    return SegmentedButton<BusyMarkThemeModePreference>(
      showSelectedIcon: false,
      segments: [
        ButtonSegment(
          value: BusyMarkThemeModePreference.system,
          label: _SegmentLabel(context.l10n.systemTheme),
        ),
        ButtonSegment(
          value: BusyMarkThemeModePreference.light,
          label: _SegmentLabel(context.l10n.lightTheme),
        ),
        ButtonSegment(
          value: BusyMarkThemeModePreference.dark,
          label: _SegmentLabel(context.l10n.darkTheme),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (value) => onChanged(value.first),
    );
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
    return SegmentedButton<EditorToolbarPlacement>(
      showSelectedIcon: false,
      segments: [
        ButtonSegment(
          value: EditorToolbarPlacement.topLeft,
          label: _SegmentLabel(context.l10n.topLeft),
        ),
        ButtonSegment(
          value: EditorToolbarPlacement.topRight,
          label: _SegmentLabel(context.l10n.topRight),
        ),
        ButtonSegment(
          value: EditorToolbarPlacement.bottomLeft,
          label: _SegmentLabel(context.l10n.bottomLeft),
        ),
        ButtonSegment(
          value: EditorToolbarPlacement.bottomRight,
          label: _SegmentLabel(context.l10n.bottomRight),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (value) => onChanged(value.first),
    );
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
    return SegmentedButton<EditorToolbarDirection>(
      showSelectedIcon: false,
      segments: [
        ButtonSegment(
          value: EditorToolbarDirection.horizontal,
          label: _SegmentLabel(context.l10n.horizontal),
        ),
        ButtonSegment(
          value: EditorToolbarDirection.vertical,
          label: _SegmentLabel(context.l10n.vertical),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (value) => onChanged(value.first),
    );
  }
}

class _SegmentLabel extends StatelessWidget {
  const _SegmentLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, maxLines: 1, overflow: TextOverflow.ellipsis);
  }
}
