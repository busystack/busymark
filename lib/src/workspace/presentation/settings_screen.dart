import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_settings.dart';
import '../../app/busymark_dialogs.dart';
import '../../app/busymark_design.dart';
import '../../app/busymark_glyphs.dart';
import '../../app/localization.dart';
import '../../platform/linux_header_bar_service.dart';
import '../workspace_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsControllerProvider);
    final controller = ref.watch(appSettingsControllerProvider.notifier);
    final workspaceOpen =
        ref.watch(workspaceControllerProvider).workspace != null;
    final colors = BusyMarkSurfaceColors.of(context);
    final headerBar = ref.watch(linuxHeaderBarServiceProvider);
    final useNativeHeaderBar = headerBar.usesNativeHeaderBar;
    ref.listen(headerBarActionsProvider, (previous, next) {
      next.whenData((action) {
        _handleHeaderBarAction(context, workspaceOpen, action);
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
                  icon: BusyMarkGlyphs.back,
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
                BusyMarkHeaderIconButton(
                  tooltip: context.l10n.keyboardShortcuts,
                  icon: BusyMarkGlyphs.keyboard,
                  onPressed: () => showBusyMarkKeyboardShortcutsDialog(context),
                ),
                BusyMarkHeaderIconButton(
                  tooltip: context.l10n.aboutBusyMark,
                  icon: BusyMarkGlyphs.info,
                  onPressed: () => showBusyMarkAboutDialog(context),
                ),
                const SizedBox(width: BusyMarkSpacing.sm),
              ],
            ),
      body: BusyMarkClamp(
        maxWidth: BusyMarkSizes.settingsWidth,
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
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
                  title: context.l10n.wordWrap,
                  value: settings.wordWrap,
                  onChanged: controller.setWordWrap,
                  leading: const Icon(BusyMarkGlyphs.wordWrap),
                ),
                _EditorFontSizeRow(
                  value: settings.editorFontSize,
                  onChanged: controller.setEditorFontSize,
                ),
                _EditorToolbarPlacementRow(
                  selected: settings.editorToolbarPlacement,
                  onChanged: controller.setEditorToolbarPlacement,
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
        await headerBar.setBackVisible(true);
        await headerBar.setDocumentControlsVisible(false);
        await headerBar.setCanRefresh(false);
        await headerBar.setCanSave(false);
        await headerBar.setSearchActive(false);
      }());
    });
  }

  void _handleHeaderBarAction(
    BuildContext context,
    bool workspaceOpen,
    HeaderBarAction action,
  ) {
    switch (action) {
      case HeaderBarAction.back:
        context.go(workspaceOpen ? '/workspace' : '/');
      case HeaderBarAction.aboutBusyMark:
        showBusyMarkAboutDialog(context);
      case HeaderBarAction.keyboardShortcuts:
        showBusyMarkKeyboardShortcutsDialog(context);
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
        if (constraints.maxWidth < 560) {
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
          trailing: SizedBox(width: 256, child: control),
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
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: selectedLocaleTag ?? _systemLocaleTag,
        isExpanded: true,
        onChanged: (value) {
          if (value == null) {
            return;
          }
          onChanged(value == _systemLocaleTag ? null : value);
        },
        items: [
          DropdownMenuItem(
            value: _systemLocaleTag,
            child: Text(context.l10n.systemLanguage),
          ),
          for (final option in _languageOptions(context))
            DropdownMenuItem(
              value: option.localeTag,
              child: Text(option.label),
            ),
        ],
      ),
    );
  }

  List<_LanguageOption> _languageOptions(BuildContext context) {
    return [
      _LanguageOption('en', context.l10n.languageEnglish),
      _LanguageOption('de', context.l10n.languageGerman),
      _LanguageOption('it', context.l10n.languageItalian),
      _LanguageOption('no', context.l10n.languageNorwegian),
      _LanguageOption('fr', context.l10n.languageFrench),
      _LanguageOption('ru', context.l10n.languageRussian),
      _LanguageOption('uk', context.l10n.languageUkrainian),
      _LanguageOption('pl', context.l10n.languagePolish),
      _LanguageOption('es', context.l10n.languageSpanish),
      _LanguageOption('pt', context.l10n.languagePortuguese),
      _LanguageOption('ar', context.l10n.languageArabic),
      _LanguageOption('fa', context.l10n.languagePersian),
      _LanguageOption('hi', context.l10n.languageHindi),
    ];
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
        if (constraints.maxWidth < 560) {
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
          trailing: SizedBox(width: 256, child: control),
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
        if (constraints.maxWidth < 560) {
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
          trailing: SizedBox(width: 260, child: slider),
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
    final control = _EditorToolbarPlacementControl(
      selected: selected,
      onChanged: onChanged,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 620) {
          return Padding(
            padding: const EdgeInsets.all(BusyMarkSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(BusyMarkGlyphs.toolbarPlacement),
                    const SizedBox(width: BusyMarkSpacing.md),
                    Text(context.l10n.editingButtons),
                  ],
                ),
                const SizedBox(height: BusyMarkSpacing.sm),
                control,
              ],
            ),
          );
        }
        return BusyMarkActionRow(
          title: context.l10n.editingButtons,
          subtitle: context.l10n.editingButtonsDescription,
          leading: const Icon(BusyMarkGlyphs.toolbarPlacement),
          trailing: SizedBox(width: 430, child: control),
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

class _SegmentLabel extends StatelessWidget {
  const _SegmentLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, maxLines: 1, overflow: TextOverflow.ellipsis);
  }
}
