import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_settings.dart';
import '../../app/busymark_dialogs.dart';
import '../../app/busymark_design.dart';
import '../../app/busymark_glyphs.dart';
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
      _configureHeaderBar(headerBar);
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
                  tooltip: 'Back',
                  icon: BusyMarkGlyphs.back,
                  onPressed: () =>
                      context.go(workspaceOpen ? '/workspace' : '/'),
                ),
              ),
              title: Text(
                'BusyMark Settings',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              actions: [
                BusyMarkHeaderIconButton(
                  tooltip: 'Keyboard Shortcuts',
                  icon: BusyMarkGlyphs.keyboard,
                  onPressed: () => showBusyMarkKeyboardShortcutsDialog(context),
                ),
                BusyMarkHeaderIconButton(
                  tooltip: 'About BusyMark',
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
              title: 'Appearance',
              filled: true,
              children: [
                _ThemeModeRow(
                  selected: settings.themeModePreference,
                  onChanged: controller.setThemeModePreference,
                ),
              ],
            ),
            BusyMarkGroupedList(
              title: 'Editor',
              filled: true,
              children: [
                BusyMarkSwitchRow(
                  title: 'Word wrap',
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
              title: 'Validation',
              filled: true,
              children: [
                BusyMarkSwitchRow(
                  title: 'Validate on edit',
                  value: settings.validateOnEdit,
                  onChanged: controller.setValidateOnEdit,
                  leading: const Icon(BusyMarkGlyphs.diagnostics),
                ),
              ],
            ),
            BusyMarkGroupedList(
              title: 'Advanced',
              filled: true,
              children: [
                BusyMarkActionRow(
                  title: 'Clear recent workspaces',
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

  void _configureHeaderBar(LinuxHeaderBarService headerBar) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(() async {
        await headerBar.setTitleRange('Settings');
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
      case HeaderBarAction.printDocument:
      case HeaderBarAction.menu:
      case HeaderBarAction.viewModeEditor:
      case HeaderBarAction.viewModeSource:
      case HeaderBarAction.viewModePreview:
      case HeaderBarAction.viewModeSplit:
        break;
    }
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
        if (constraints.maxWidth < 560) {
          return Padding(
            padding: const EdgeInsets.all(BusyMarkSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(BusyMarkGlyphs.appearance),
                    SizedBox(width: BusyMarkSpacing.md),
                    Text('Theme'),
                  ],
                ),
                const SizedBox(height: BusyMarkSpacing.sm),
                control,
              ],
            ),
          );
        }
        return BusyMarkActionRow(
          title: 'Theme',
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
      segments: const [
        ButtonSegment(
          value: BusyMarkThemeModePreference.system,
          label: _SegmentLabel('System'),
        ),
        ButtonSegment(
          value: BusyMarkThemeModePreference.light,
          label: _SegmentLabel('Light'),
        ),
        ButtonSegment(
          value: BusyMarkThemeModePreference.dark,
          label: _SegmentLabel('Dark'),
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
                        'Editor font size',
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
          title: 'Editor font size',
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
                const Row(
                  children: [
                    Icon(BusyMarkGlyphs.toolbarPlacement),
                    SizedBox(width: BusyMarkSpacing.md),
                    Text('Editing buttons'),
                  ],
                ),
                const SizedBox(height: BusyMarkSpacing.sm),
                control,
              ],
            ),
          );
        }
        return BusyMarkActionRow(
          title: 'Editing buttons',
          subtitle: 'Choose where the floating editor controls appear',
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
      segments: const [
        ButtonSegment(
          value: EditorToolbarPlacement.topLeft,
          label: _SegmentLabel('Top left'),
        ),
        ButtonSegment(
          value: EditorToolbarPlacement.topRight,
          label: _SegmentLabel('Top right'),
        ),
        ButtonSegment(
          value: EditorToolbarPlacement.bottomLeft,
          label: _SegmentLabel('Bottom left'),
        ),
        ButtonSegment(
          value: EditorToolbarPlacement.bottomRight,
          label: _SegmentLabel('Bottom right'),
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
