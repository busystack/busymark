import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:system_theme/system_theme.dart';
import 'package:ubuntu_localizations/ubuntu_localizations.dart';

import '../workspace/workspace_controller.dart';
import '../workspace/workspace_safety.dart';
import 'app_router.dart';
import 'app_settings.dart';
import 'app_theme.dart';
import 'busymark_dialogs.dart';
import 'busymark_design.dart';
import 'busymark_glyphs.dart';
import '../platform/linux_header_bar_service.dart';

class BusyMarkApp extends ConsumerWidget {
  const BusyMarkApp({super.key});

  static const _markdownTypes = XTypeGroup(
    label: 'Markdown',
    extensions: <String>['md', 'markdown'],
    mimeTypes: <String>['text/markdown', 'text/x-markdown'],
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final settings = ref.watch(appSettingsControllerProvider);
    return SystemThemeBuilder(
      builder: (context, systemColor) {
        final accent = systemColor.accent;
        return MaterialApp.router(
          title: 'BusyMark',
          debugShowCheckedModeBanner: false,
          theme: buildBusyMarkTheme(
            brightness: Brightness.light,
            accentColor: accent,
          ),
          darkTheme: buildBusyMarkTheme(
            brightness: Brightness.dark,
            accentColor: accent,
          ),
          themeMode: settings.themeMode,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            ...GlobalUbuntuLocalizations.delegates,
          ],
          supportedLocales: const [Locale('en')],
          builder: (context, child) {
            _configureNativeHeaderBar(context, ref);
            return Shortcuts(
              shortcuts: const {
                SingleActivator(LogicalKeyboardKey.keyN, control: true):
                    _NewMarkdownIntent(),
                SingleActivator(LogicalKeyboardKey.keyO, control: true):
                    _OpenWorkspaceIntent(),
                SingleActivator(LogicalKeyboardKey.keyS, control: true):
                    _SaveActiveIntent(),
                SingleActivator(LogicalKeyboardKey.slash, control: true):
                    _KeyboardShortcutsIntent(),
                SingleActivator(LogicalKeyboardKey.keyF, control: true):
                    _OpenSearchIntent(),
                SingleActivator(LogicalKeyboardKey.escape):
                    _CloseSearchIntent(),
              },
              child: Actions(
                actions: {
                  _NewMarkdownIntent: CallbackAction<_NewMarkdownIntent>(
                    onInvoke: (intent) {
                      unawaited(() async {
                        final navigatorContext =
                            rootNavigatorKey.currentContext;
                        if (navigatorContext == null) {
                          return;
                        }
                        final safe = await confirmSafeToContinue(
                          navigatorContext,
                          ref,
                        );
                        if (!safe || !navigatorContext.mounted) {
                          return;
                        }
                        await ref
                            .read(workspaceControllerProvider.notifier)
                            .createMarkdownFile();
                        if (navigatorContext.mounted) {
                          router.go('/workspace');
                        }
                      }());
                      return null;
                    },
                  ),
                  _OpenWorkspaceIntent: CallbackAction<_OpenWorkspaceIntent>(
                    onInvoke: (intent) {
                      final navigatorContext = rootNavigatorKey.currentContext;
                      if (navigatorContext != null) {
                        unawaited(
                          _showOpenChooser(navigatorContext, ref, router),
                        );
                      }
                      return null;
                    },
                  ),
                  _SaveActiveIntent: CallbackAction<_SaveActiveIntent>(
                    onInvoke: (intent) {
                      final state = ref.read(workspaceControllerProvider);
                      final navigatorContext = rootNavigatorKey.currentContext;
                      if (state.workspace != null && navigatorContext != null) {
                        unawaited(
                          saveActiveWithOverwriteConfirmation(
                            navigatorContext,
                            ref,
                          ),
                        );
                      }
                      return null;
                    },
                  ),
                  _KeyboardShortcutsIntent:
                      CallbackAction<_KeyboardShortcutsIntent>(
                        onInvoke: (intent) {
                          final navigatorContext =
                              rootNavigatorKey.currentContext;
                          if (navigatorContext != null) {
                            showBusyMarkKeyboardShortcutsDialog(
                              navigatorContext,
                            );
                          }
                          return null;
                        },
                      ),
                  _OpenSearchIntent: CallbackAction<_OpenSearchIntent>(
                    onInvoke: (intent) {
                      if (ref.read(workspaceControllerProvider).workspace !=
                          null) {
                        final notifier = ref.read(
                          workspaceSearchOpenRequestProvider.notifier,
                        );
                        notifier.state++;
                      }
                      return null;
                    },
                  ),
                  _CloseSearchIntent: CallbackAction<_CloseSearchIntent>(
                    onInvoke: (intent) {
                      if (ref.read(workspaceControllerProvider).workspace !=
                          null) {
                        final notifier = ref.read(
                          workspaceSearchCloseRequestProvider.notifier,
                        );
                        notifier.state++;
                      }
                      return null;
                    },
                  ),
                },
                child: _BusyMarkSearchShortcutHandler(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(BusyMarkRadius.window),
                    ),
                    clipBehavior: Clip.antiAliasWithSaveLayer,
                    child: ColoredBox(
                      color: BusyMarkSurfaceColors.of(context).window,
                      child: child ?? const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            );
          },
          routerConfig: router,
        );
      },
    );
  }

  Future<void> _showOpenChooser(
    BuildContext context,
    WidgetRef ref,
    GoRouter router,
  ) async {
    final headerBar = ref.read(linuxHeaderBarServiceProvider);
    final choice = await showBusyMarkModalDialog<String>(
      context,
      headerBarService: headerBar.isAvailable ? headerBar : null,
      builder: (dialogContext) => BusyMarkDialogShell(
        title: 'Open',
        maxWidth: 520,
        children: [
          BusyMarkGroupedList(
            filled: true,
            children: [
              BusyMarkActionRow(
                title: 'Open Markdown File',
                subtitle: '.md or .markdown',
                leading: const Icon(BusyMarkGlyphs.markdownFile),
                trailing: const Icon(BusyMarkGlyphs.rightArrow),
                onTap: () => Navigator.pop(dialogContext, 'file'),
              ),
              BusyMarkActionRow(
                title: 'Open Folder or Writerside Project',
                subtitle: 'Markdown folder or Writerside-compatible project',
                leading: const Icon(BusyMarkGlyphs.folder),
                trailing: const Icon(BusyMarkGlyphs.rightArrow),
                onTap: () => Navigator.pop(dialogContext, 'folder'),
              ),
            ],
          ),
        ],
      ),
    );
    if (!context.mounted || choice == null) {
      return;
    }
    final path = switch (choice) {
      'file' => await _chooseMarkdownFile(ref),
      'folder' => await _chooseWorkspaceFolder(ref),
      _ => null,
    };
    if (path == null || path.isEmpty || !context.mounted) {
      return;
    }
    if (!await confirmSafeToContinue(context, ref) || !context.mounted) {
      return;
    }
    await ref.read(workspaceControllerProvider.notifier).openPath(path);
    if (context.mounted &&
        ref.read(workspaceControllerProvider).workspace != null) {
      router.go('/workspace');
    }
  }

  Future<String?> _chooseMarkdownFile(WidgetRef ref) async {
    final selected = await openFile(
      acceptedTypeGroups: const [_markdownTypes],
      initialDirectory: _initialDirectory(ref),
      confirmButtonText: 'Open',
    );
    return selected?.path;
  }

  Future<String?> _chooseWorkspaceFolder(WidgetRef ref) {
    return getDirectoryPath(
      initialDirectory: _initialDirectory(ref),
      confirmButtonText: 'Open',
      canCreateDirectories: false,
    );
  }

  String? _initialDirectory(WidgetRef ref) {
    final lastPath = ref.read(appSettingsControllerProvider).lastOpenedPath;
    if (lastPath == null || lastPath.isEmpty) {
      return null;
    }
    return p.extension(lastPath).isEmpty ? lastPath : p.dirname(lastPath);
  }

  void _configureNativeHeaderBar(BuildContext context, WidgetRef ref) {
    final service = ref.watch(linuxHeaderBarServiceProvider);
    if (!service.isAvailable) {
      return;
    }
    final material = MaterialLocalizations.of(context);
    final theme = HeaderBarTheme.fromContext(context);
    final labels = HeaderBarLabels(
      editor: 'Editor',
      source: 'Source',
      preview: 'Preview',
      split: 'Split',
      viewMode: 'View mode',
      search: material.searchFieldLabel,
      refresh: 'Validate',
      menu: 'Main menu',
      sidebar: 'Toggle sidebar',
      back: material.backButtonTooltip,
      save: 'Save',
      settings: 'Settings',
      keyboardShortcuts: 'Keyboard Shortcuts',
      aboutBusyMark: 'About BusyMark',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(() async {
        await service.setSidebarWidth(BusyMarkSizes.sidebarWidth);
        await service.setTheme(theme);
        await service.setLocalizedLabels(labels);
      }());
    });
  }
}

class _BusyMarkSearchShortcutHandler extends ConsumerStatefulWidget {
  const _BusyMarkSearchShortcutHandler({required this.child});

  final Widget child;

  @override
  ConsumerState<_BusyMarkSearchShortcutHandler> createState() =>
      _BusyMarkSearchShortcutHandlerState();
}

class _BusyMarkSearchShortcutHandlerState
    extends ConsumerState<_BusyMarkSearchShortcutHandler> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return false;
    }
    final workspaceOpen =
        ref.read(workspaceControllerProvider).workspace != null;
    if (!workspaceOpen) {
      return false;
    }
    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isControlPressed &&
        event.logicalKey == LogicalKeyboardKey.keyF) {
      ref.read(workspaceSearchOpenRequestProvider.notifier).state++;
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      ref.read(workspaceSearchCloseRequestProvider.notifier).state++;
      return false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _NewMarkdownIntent extends Intent {
  const _NewMarkdownIntent();
}

class _OpenWorkspaceIntent extends Intent {
  const _OpenWorkspaceIntent();
}

class _SaveActiveIntent extends Intent {
  const _SaveActiveIntent();
}

class _KeyboardShortcutsIntent extends Intent {
  const _KeyboardShortcutsIntent();
}

class _OpenSearchIntent extends Intent {
  const _OpenSearchIntent();
}

class _CloseSearchIntent extends Intent {
  const _CloseSearchIntent();
}
