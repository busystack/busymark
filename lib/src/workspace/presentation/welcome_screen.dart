import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:busymark/src/app/startup_path.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

import '../../app/app_settings.dart';
import '../../app/busymark_dialogs.dart';
import '../../app/busymark_design.dart';
import '../../platform/linux_header_bar_service.dart';
import '../workspace_controller.dart';
import '../workspace_safety.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  static const _markdownTypes = XTypeGroup(
    label: 'Markdown',
    extensions: <String>['md', 'markdown'],
    mimeTypes: <String>['text/markdown', 'text/x-markdown'],
  );
  var _startupPathConsumed = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workspaceControllerProvider);
    final settings = ref.watch(appSettingsControllerProvider);
    final colors = BusyMarkSurfaceColors.of(context);
    final headerBar = ref.watch(linuxHeaderBarServiceProvider);
    final useNativeHeaderBar = headerBar.usesNativeHeaderBar;
    ref.listen(headerBarActionsProvider, (previous, next) {
      next.whenData((action) {
        _handleHeaderBarAction(context, action);
      });
    });
    if (headerBar.isAvailable) {
      _configureHeaderBar(headerBar);
    }
    final startupPath = ref.watch(startupPathProvider);
    if (!_startupPathConsumed &&
        startupPath != null &&
        startupPath.isNotEmpty) {
      _startupPathConsumed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_openPath(startupPath));
        }
      });
    }

    return Scaffold(
      backgroundColor: colors.view,
      appBar: useNativeHeaderBar
          ? null
          : AppBar(
              leadingWidth: 0,
              titleSpacing: BusyMarkSpacing.lg,
              title: Text(
                'BusyMark',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              actions: [
                BusyMarkHeaderIconButton(
                  tooltip: 'Settings',
                  icon: Icons.settings_outlined,
                  onPressed: () => context.go('/settings'),
                ),
                BusyMarkHeaderIconButton(
                  tooltip: 'About BusyMark',
                  icon: Icons.info_outline,
                  onPressed: () => showBusyMarkAboutDialog(context),
                ),
                const SizedBox(width: BusyMarkSpacing.sm),
              ],
            ),
      body: BusyMarkClamp(
        maxWidth: 760,
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BusyMarkGroupedList(
              title: 'Open',
              filled: true,
              children: [
                BusyMarkActionRow(
                  title: 'Open Markdown File',
                  subtitle: '.md or .markdown',
                  leading: const Icon(Icons.description_outlined),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _chooseMarkdownFile,
                ),
                BusyMarkActionRow(
                  title: 'Open Folder or Writerside Project',
                  subtitle: 'Markdown folder or Writerside-compatible project',
                  leading: const Icon(Icons.folder_outlined),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _chooseDirectory('Open'),
                ),
              ],
            ),
            if (state.isLoading) ...[
              const SizedBox(height: BusyMarkSpacing.lg),
              const LinearProgressIndicator(),
            ],
            if (state.errorMessage != null) ...[
              const SizedBox(height: BusyMarkSpacing.lg),
              _WelcomeMessage(message: state.errorMessage!),
            ],
            if (settings.recentWorkspaces.isNotEmpty)
              BusyMarkGroupedList(
                title: 'Recent',
                filled: true,
                children: [
                  for (final recent in settings.recentWorkspaces)
                    BusyMarkActionRow(
                      title: _displayPath(recent.path),
                      subtitle: recent.path,
                      leading: const Icon(Icons.history),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        await _openPath(recent.path);
                      },
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
        await headerBar.setTitleRange('BusyMark');
        await headerBar.setSidebarVisible(false);
        await headerBar.setSidebarToggleVisible(false);
        await headerBar.setBackVisible(false);
        await headerBar.setDocumentControlsVisible(false);
        await headerBar.setCanRefresh(false);
        await headerBar.setCanSave(false);
        await headerBar.setSearchActive(false);
      }());
    });
  }

  void _handleHeaderBarAction(BuildContext context, HeaderBarAction action) {
    switch (action) {
      case HeaderBarAction.settings:
        context.go('/settings');
      case HeaderBarAction.aboutBusyMark:
        showBusyMarkAboutDialog(context);
      case HeaderBarAction.back:
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

  String _displayPath(String path) {
    final name = p.basename(path);
    return name.isEmpty ? path : name;
  }

  Future<void> _chooseMarkdownFile() async {
    final selected = await openFile(
      acceptedTypeGroups: const [_markdownTypes],
      initialDirectory: _initialDirectory(),
      confirmButtonText: 'Open',
    );
    final path = selected?.path;
    if (path == null) {
      return;
    }
    await _openPath(path);
  }

  Future<void> _chooseDirectory(String confirmButtonText) async {
    final path = await getDirectoryPath(
      initialDirectory: _initialDirectory(),
      confirmButtonText: confirmButtonText,
      canCreateDirectories: false,
    );
    if (path == null) {
      return;
    }
    await _openPath(path);
  }

  String? _initialDirectory() {
    final settings = ref.read(appSettingsControllerProvider);
    final lastPath = settings.lastOpenedPath;
    if (lastPath == null || lastPath.isEmpty) {
      return null;
    }
    final extension = p.extension(lastPath);
    return extension.isEmpty ? lastPath : p.dirname(lastPath);
  }

  Future<void> _openPath(String path) async {
    if (path.isEmpty) {
      return;
    }
    final safe = await confirmSafeToContinue(context, ref);
    if (!safe) {
      return;
    }
    await ref.read(workspaceControllerProvider.notifier).openPath(path);
    if (!mounted) {
      return;
    }
    final workspace = ref.read(workspaceControllerProvider).workspace;
    if (workspace != null) {
      context.go('/workspace');
    }
  }
}

class _WelcomeMessage extends StatelessWidget {
  const _WelcomeMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.admonitionWarning,
        borderRadius: BorderRadius.circular(BusyMarkRadius.md),
        border: Border.all(color: colors.subtleBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BusyMarkSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber_outlined),
            const SizedBox(width: BusyMarkSpacing.sm),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

void showBusyMarkAboutDialog(BuildContext context) {
  final headerBar = LinuxHeaderBarService.instance;
  unawaited(
    showBusyMarkModalDialog<void>(
      context,
      headerBarService: headerBar.isAvailable ? headerBar : null,
      builder: (context) => const _BusyMarkAboutDialog(),
    ),
  );
}

class _BusyMarkAboutDialog extends StatelessWidget {
  const _BusyMarkAboutDialog();

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BusyMark',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: BusyMarkSpacing.xs),
                Text(
                  'Version 0.1.0',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Text(
              'BusyMark is an open-source application for reading, editing, and exporting Markdown files and Writerside-compatible projects.',
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
