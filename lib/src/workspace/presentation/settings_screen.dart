import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_settings.dart';
import '../../app/busymark_design.dart';
import '../../platform/linux_header_bar_service.dart';
import '../workspace_controller.dart';
import 'welcome_screen.dart';

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
                  icon: Icons.arrow_back,
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
                  leading: const Icon(Icons.wrap_text),
                ),
                _EditorFontSizeRow(
                  value: settings.editorFontSize,
                  onChanged: controller.setEditorFontSize,
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
                  leading: const Icon(Icons.fact_check_outlined),
                ),
              ],
            ),
            BusyMarkGroupedList(
              title: 'Advanced',
              filled: true,
              children: [
                BusyMarkActionRow(
                  title: 'Clear recent workspaces',
                  leading: const Icon(Icons.clear_all),
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
      case HeaderBarAction.settings:
      case HeaderBarAction.sidebarToggle:
      case HeaderBarAction.search:
      case HeaderBarAction.refresh:
      case HeaderBarAction.save:
      case HeaderBarAction.menu:
      case HeaderBarAction.exportPreview:
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
                    Icon(Icons.contrast_outlined),
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
          leading: const Icon(Icons.contrast_outlined),
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
          label: Text('System'),
        ),
        ButtonSegment(
          value: BusyMarkThemeModePreference.light,
          label: Text('Light'),
        ),
        ButtonSegment(
          value: BusyMarkThemeModePreference.dark,
          label: Text('Dark'),
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
                    const Icon(Icons.format_size),
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
          leading: const Icon(Icons.format_size),
          trailing: SizedBox(width: 260, child: slider),
        );
      },
    );
  }
}
