import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:ubuntu_localizations/ubuntu_localizations.dart';

import '../../l10n/generated/app_localizations.dart';
import '../export/markdown_pdf_export_ui.dart';
import '../git/application/git_controller.dart';
import '../platform/linux_header_bar_service.dart';
import '../workspace/workspace_controller.dart';
import '../workspace/workspace_model.dart';
import '../workspace/presentation/welcome_screen.dart';
import '../workspace/workspace_safety.dart';
import '../workspace/workspace_tabs.dart';
import 'app_router.dart';
import 'app_locale.dart';
import 'app_settings.dart';
import 'command_palette.dart';
import 'command_registry.dart';
import 'app_theme.dart';
import 'busymark_dialogs.dart';
import 'busymark_design.dart';
import 'busymark_glyphs.dart';
import 'localization.dart';
import 'system_accent.dart';
import 'window_control_service.dart';

final busyMarkCommandRegistryProvider = Provider<BusyMarkCommandRegistry>((
  ref,
) {
  final commandIntents = <String, Intent>{
    BusyMarkCommandIds.newDocument: const _NewWorkspaceIntent(),
    BusyMarkCommandIds.open: const _OpenWorkspaceIntent(),
    BusyMarkCommandIds.save: const _SaveActiveIntent(),
    BusyMarkCommandIds.exportPdf: const _ExportPdfIntent(),
    BusyMarkCommandIds.fullScreen: const _ToggleFullScreenIntent(),
    BusyMarkCommandIds.back: const _BackIntent(),
    BusyMarkCommandIds.search: const _OpenSearchIntent(),
    BusyMarkCommandIds.keyboardShortcuts: const _KeyboardShortcutsIntent(),
    BusyMarkCommandIds.commandPalette: const _CommandPaletteIntent(),
    BusyMarkCommandIds.markdownAndHtml: const _MarkdownAndHtmlIntent(),
    BusyMarkCommandIds.settings: const _SettingsIntent(),
    BusyMarkCommandIds.nextTab: const _NextTabIntent(),
    BusyMarkCommandIds.previousTab: const _PreviousTabIntent(),
    BusyMarkCommandIds.closeTab: const _CloseTabIntent(),
    BusyMarkCommandIds.closeAllTabs: const _CloseAllTabsIntent(),
    BusyMarkCommandIds.toggleSidebar: const _ToggleSidebarIntent(),
    BusyMarkCommandIds.viewEditor: const _DocumentViewModeIntent(
      DocumentViewModePreference.editor,
    ),
    BusyMarkCommandIds.viewSource: const _DocumentViewModeIntent(
      DocumentViewModePreference.source,
    ),
    BusyMarkCommandIds.viewReading: const _DocumentViewModeIntent(
      DocumentViewModePreference.preview,
    ),
    BusyMarkCommandIds.viewSplit: const _DocumentViewModeIntent(
      DocumentViewModePreference.split,
    ),
  };
  return BusyMarkCommandCatalog.create(
    executions: {
      for (final entry in commandIntents.entries)
        entry.key: () {
          final target = rootNavigatorKey.currentContext;
          if (target != null) {
            Actions.maybeInvoke(target, entry.value);
          }
        },
    },
    enabled: {
      BusyMarkCommandIds.save: () =>
          ref.read(workspaceControllerProvider).workspace != null,
      BusyMarkCommandIds.exportPdf: () =>
          canExportWorkspacePdf(ref.read(workspaceControllerProvider)),
      BusyMarkCommandIds.search: () =>
          ref.read(workspaceControllerProvider).workspace != null,
    },
  );
});

class BusyMarkApp extends ConsumerWidget {
  const BusyMarkApp({super.key});

  XTypeGroup _markdownTypes(BuildContext context) => XTypeGroup(
    label: context.l10n.fileTypeMarkdown,
    extensions: <String>['md', 'markdown'],
    mimeTypes: <String>['text/markdown', 'text/x-markdown'],
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final settings = ref.watch(appSettingsControllerProvider);
    final windowControls = ref.watch(windowControlServiceProvider);
    ref.listen(headerBarActionsProvider, (previous, next) {
      next.whenData((event) {
        if (event.action == HeaderBarAction.fullScreen) {
          unawaited(windowControls.toggleFullScreen());
        }
      });
    });
    final fallbackAccent = ref.watch(initialSystemAccentColorProvider);
    final accent = ref
        .watch(systemAccentColorProvider)
        .when(
          data: (color) => color,
          error: (_, _) => fallbackAccent,
          loading: () => fallbackAccent,
        );
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
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
      locale: settings.locale,
      localeListResolutionCallback: resolveBusyMarkLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        ...GlobalUbuntuLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        final commandRegistry = ref.read(busyMarkCommandRegistryProvider);
        final headerBarDefaults = _nativeHeaderBarDefaults(
          context,
          settings,
          commandRegistry,
          fullScreen: windowControls.isFullScreen,
        );
        final appContent = HeaderBarConfigurationDefaults(
          configuration: headerBarDefaults,
          child: _BusyMarkWindowLifecycle(
            child: Shortcuts(
              shortcuts: commandRegistry.shortcutIntents(
                scopes: const {
                  BusyMarkCommandScope.application,
                  BusyMarkCommandScope.documentView,
                },
                intentFor: BusyMarkCommandIntent.new,
              ),
              child: Actions(
                actions: {
                  BusyMarkCommandIntent: CallbackAction<BusyMarkCommandIntent>(
                    onInvoke: (intent) {
                      unawaited(commandRegistry.execute(intent.commandId));
                      return null;
                    },
                  ),
                  _NewWorkspaceIntent: CallbackAction<_NewWorkspaceIntent>(
                    onInvoke: (intent) {
                      final navigatorContext = rootNavigatorKey.currentContext;
                      if (navigatorContext != null) {
                        unawaited(
                          _showNewChooser(navigatorContext, ref, router),
                        );
                      }
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
                  _ExportPdfIntent: CallbackAction<_ExportPdfIntent>(
                    onInvoke: (intent) {
                      final state = ref.read(workspaceControllerProvider);
                      final navigatorContext = rootNavigatorKey.currentContext;
                      if (navigatorContext != null &&
                          canExportWorkspacePdf(state)) {
                        unawaited(exportWorkspaceToPdf(navigatorContext, ref));
                      }
                      return null;
                    },
                  ),
                  _ToggleFullScreenIntent:
                      CallbackAction<_ToggleFullScreenIntent>(
                        onInvoke: (intent) {
                          unawaited(windowControls.toggleFullScreen());
                          return null;
                        },
                      ),
                  _BackIntent: CallbackAction<_BackIntent>(
                    onInvoke: (intent) {
                      unawaited(_navigateBack(ref, router));
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
                  _CommandPaletteIntent: CallbackAction<_CommandPaletteIntent>(
                    onInvoke: (intent) {
                      final navigatorContext = rootNavigatorKey.currentContext;
                      if (navigatorContext != null) {
                        unawaited(
                          showBusyMarkCommandPalette(
                            navigatorContext,
                            commandRegistry,
                          ),
                        );
                      }
                      return null;
                    },
                  ),
                  _SettingsIntent: CallbackAction<_SettingsIntent>(
                    onInvoke: (intent) {
                      final navigatorContext = rootNavigatorKey.currentContext;
                      if (navigatorContext != null) {
                        GoRouter.of(navigatorContext).go(
                          settingsLocationForUri(
                            router.routeInformationProvider.value.uri,
                          ),
                        );
                      }
                      return null;
                    },
                  ),
                  _MarkdownAndHtmlIntent:
                      CallbackAction<_MarkdownAndHtmlIntent>(
                        onInvoke: (intent) {
                          final navigatorContext =
                              rootNavigatorKey.currentContext;
                          if (navigatorContext != null) {
                            showBusyMarkMarkdownHtmlDialog(navigatorContext);
                          }
                          return null;
                        },
                      ),
                  _NextTabIntent: CallbackAction<_NextTabIntent>(
                    onInvoke: (intent) {
                      final navigatorContext = rootNavigatorKey.currentContext;
                      if (navigatorContext != null) {
                        unawaited(
                          _activateOpenFileTab(
                            navigatorContext,
                            ref,
                            next: true,
                          ),
                        );
                      }
                      return null;
                    },
                  ),
                  _PreviousTabIntent: CallbackAction<_PreviousTabIntent>(
                    onInvoke: (intent) {
                      final navigatorContext = rootNavigatorKey.currentContext;
                      if (navigatorContext != null) {
                        unawaited(
                          _activateOpenFileTab(
                            navigatorContext,
                            ref,
                            next: false,
                          ),
                        );
                      }
                      return null;
                    },
                  ),
                  _CloseTabIntent: CallbackAction<_CloseTabIntent>(
                    onInvoke: (intent) {
                      final navigatorContext = rootNavigatorKey.currentContext;
                      if (navigatorContext != null) {
                        unawaited(
                          _closeActiveOpenFileTab(navigatorContext, ref),
                        );
                      }
                      return null;
                    },
                  ),
                  _CloseAllTabsIntent: CallbackAction<_CloseAllTabsIntent>(
                    onInvoke: (intent) {
                      final navigatorContext = rootNavigatorKey.currentContext;
                      if (navigatorContext != null) {
                        unawaited(_closeAllOpenFileTabs(navigatorContext, ref));
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
                        notifier.request();
                      }
                      return null;
                    },
                  ),
                  _ToggleSidebarIntent: CallbackAction<_ToggleSidebarIntent>(
                    onInvoke: (intent) {
                      _toggleSidebar(
                        ref,
                        allowWithoutWorkspace:
                            router.routeInformationProvider.value.uri.path ==
                            '/',
                      );
                      return null;
                    },
                  ),
                  _DocumentViewModeIntent:
                      CallbackAction<_DocumentViewModeIntent>(
                        onInvoke: (intent) {
                          ref
                              .read(workspaceControllerProvider.notifier)
                              .updateActiveEditorMode(intent.mode);
                          unawaited(
                            ref
                                .read(appSettingsControllerProvider.notifier)
                                .setDocumentViewMode(intent.mode),
                          );
                          return null;
                        },
                      ),
                },
                child: _BusyMarkSearchShortcutHandler(
                  child: ColoredBox(
                    color: BusyMarkSurfaceColors.of(context).window,
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
        );
        return BusyMarkCommandRegistryScope(
          registry: commandRegistry,
          child: appContent,
        );
      },
      routerConfig: router,
    );
  }

  Future<void> _navigateBack(WidgetRef ref, GoRouter router) async {
    final uri = router.routeInformationProvider.value.uri;
    if (uri.path == settingsRoutePath) {
      router.go(SettingsReturnTarget.fromSettingsUri(uri).location);
      return;
    }
    if (uri.path != '/workspace') {
      return;
    }
    final navigatorContext = rootNavigatorKey.currentContext;
    if (navigatorContext == null ||
        !await confirmSafeToContinue(navigatorContext, ref) ||
        !navigatorContext.mounted) {
      return;
    }
    router.go('/');
  }

  Future<void> _showOpenChooser(
    BuildContext context,
    WidgetRef ref,
    GoRouter router,
  ) async {
    final headerBar = ref.read(linuxHeaderBarServiceProvider);
    final recentWorkspaces = ref
        .read(appSettingsControllerProvider)
        .recentWorkspaces;
    final choice = await showBusyMarkModalDialog<_OpenChooserChoice>(
      context,
      headerBarService: headerBar.isAvailable ? headerBar : null,
      builder: (dialogContext) => BusyMarkDialogShell(
        title: context.l10n.open,
        maxWidth: BusyMarkSizes.dialog,
        children: [
          BusyMarkGroupedList(
            filled: true,
            children: [
              BusyMarkActionRow(
                title: context.l10n.openMarkdownFile,
                subtitle: context.l10n.markdownFileExtensions,
                leading: const Icon(BusyMarkGlyphs.markdownFile),
                trailing: Icon(
                  BusyMarkGlyphs.forwardFor(Directionality.of(dialogContext)),
                ),
                onTap: () =>
                    Navigator.pop(dialogContext, const _OpenMarkdownFile()),
              ),
              BusyMarkActionRow(
                title: context.l10n.openFolderOrWritersideProject,
                subtitle: context.l10n.markdownFolderOrWritersideProject,
                leading: const Icon(BusyMarkGlyphs.folder),
                trailing: Icon(
                  BusyMarkGlyphs.forwardFor(Directionality.of(dialogContext)),
                ),
                onTap: () =>
                    Navigator.pop(dialogContext, const _OpenWorkspaceFolder()),
              ),
            ],
          ),
          if (recentWorkspaces.isNotEmpty)
            BusyMarkGroupedList(
              title: context.l10n.recent,
              filled: true,
              children: [
                for (final recent in recentWorkspaces)
                  BusyMarkActionRow(
                    title: busyMarkLtrIsolateFor(
                      dialogContext,
                      _displayPath(recent.path),
                    ),
                    subtitle: busyMarkLtrIsolateFor(dialogContext, recent.path),
                    leading: const Icon(BusyMarkGlyphs.history),
                    trailing: Icon(
                      BusyMarkGlyphs.forwardFor(
                        Directionality.of(dialogContext),
                      ),
                    ),
                    onTap: () => Navigator.pop(
                      dialogContext,
                      _OpenRecentWorkspace(recent.path),
                    ),
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
      _OpenMarkdownFile() => await _chooseMarkdownFile(ref),
      _OpenWorkspaceFolder() => await _chooseWorkspaceFolder(ref),
      _OpenRecentWorkspace(:final path) => path,
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

  Future<void> _showNewChooser(
    BuildContext context,
    WidgetRef ref,
    GoRouter router,
  ) async {
    final headerBar = ref.read(linuxHeaderBarServiceProvider);
    final choice = await showBusyMarkModalDialog<_NewChooserChoice>(
      context,
      headerBarService: headerBar.isAvailable ? headerBar : null,
      builder: (dialogContext) => BusyMarkDialogShell(
        title: context.l10n.create,
        maxWidth: BusyMarkSizes.dialog,
        children: [
          BusyMarkGroupedList(
            filled: true,
            children: [
              BusyMarkActionRow(
                title: context.l10n.createMarkdownFile,
                subtitle: context.l10n.createMarkdownFileDescription,
                leading: const Icon(BusyMarkGlyphs.newDocument),
                trailing: Icon(
                  BusyMarkGlyphs.forwardFor(Directionality.of(dialogContext)),
                ),
                onTap: () =>
                    Navigator.pop(dialogContext, const _CreateMarkdownFile()),
              ),
              BusyMarkActionRow(
                title: context.l10n.createWritersideProject,
                subtitle: context.l10n.createWritersideProjectDescription,
                leading: const Icon(BusyMarkGlyphs.writersideProject),
                trailing: Icon(
                  BusyMarkGlyphs.forwardFor(Directionality.of(dialogContext)),
                ),
                onTap: () => Navigator.pop(
                  dialogContext,
                  const _CreateWritersideProject(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (choice == null || !context.mounted) {
      return;
    }
    switch (choice) {
      case _CreateMarkdownFile():
        await ref
            .read(workspaceControllerProvider.notifier)
            .createMarkdownFile();
        if (context.mounted) {
          router.go('/workspace');
        }
      case _CreateWritersideProject():
        if (!await confirmSafeToContinue(context, ref) || !context.mounted) {
          return;
        }
        await _createWritersideProject(context, ref, router);
    }
  }

  Future<void> _createWritersideProject(
    BuildContext context,
    WidgetRef ref,
    GoRouter router,
  ) async {
    final parentPath = await getDirectoryPath(
      initialDirectory: _initialDirectory(ref),
      confirmButtonText: context.l10n.chooseLocation,
      canCreateDirectories: true,
    );
    if (parentPath == null || !context.mounted) {
      return;
    }
    final headerBar = ref.read(linuxHeaderBarServiceProvider);
    final created = await showBusyMarkModalEditorDialog<bool>(
      context,
      headerBarService: headerBar.isAvailable ? headerBar : null,
      maxWidth: BusyMarkSizes.dialogWide,
      builder: (context) => BusyMarkCreateWritersideProjectDialog(
        parentDirectoryPath: parentPath,
        onCreate: (request) => ref
            .read(workspaceControllerProvider.notifier)
            .createWritersideProject(request),
        message: () => ref.read(workspaceControllerProvider).message,
      ),
    );
    if (created == true && context.mounted) {
      router.go('/workspace');
    }
  }

  Future<String?> _chooseMarkdownFile(WidgetRef ref) async {
    final context = rootNavigatorKey.currentContext;
    if (context == null) {
      return null;
    }
    final selected = await openFile(
      acceptedTypeGroups: [_markdownTypes(context)],
      initialDirectory: _initialDirectory(ref),
      confirmButtonText: context.l10n.open,
    );
    return selected?.path;
  }

  Future<void> _activateOpenFileTab(
    BuildContext context,
    WidgetRef ref, {
    required bool next,
  }) async {
    final workspaceState = ref.read(workspaceControllerProvider);
    final workspace = workspaceState.workspace;
    final gitState = ref.read(gitControllerProvider);
    if (workspace == null) {
      return;
    }
    final tabs = workspaceTabEntries(
      workspace: workspace,
      gitState: gitState,
      documentBuffers: workspaceState.documentBuffers,
      activeBufferId: workspaceState.activeBufferId,
    );
    if (tabs.length < 2) {
      return;
    }
    final activeIndex = activeWorkspaceTabIndex(tabs);
    final nextIndex = activeIndex < 0
        ? 0
        : (activeIndex + (next ? 1 : -1)) % tabs.length;
    final normalizedIndex = nextIndex < 0 ? nextIndex + tabs.length : nextIndex;
    await _activateWorkspaceTab(ref, tabs[normalizedIndex]);
  }

  Future<void> _closeActiveOpenFileTab(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final workspaceState = ref.read(workspaceControllerProvider);
    final workspace = workspaceState.workspace;
    final gitState = ref.read(gitControllerProvider);
    if (workspace == null) {
      return;
    }
    final tabs = workspaceTabEntries(
      workspace: workspace,
      gitState: gitState,
      documentBuffers: workspaceState.documentBuffers,
      activeBufferId: workspaceState.activeBufferId,
    );
    final activeIndex = activeWorkspaceTabIndex(tabs);
    if (activeIndex < 0) {
      return;
    }
    final activeTab = tabs[activeIndex];
    if (activeTab.kind == WorkspaceTabKind.file) {
      if (activeTab.dirty &&
          (!await confirmSafeToCloseActiveDocument(context, ref) ||
              !context.mounted)) {
        return;
      }
    }
    await _closeWorkspaceTab(ref, activeTab);
  }

  Future<void> _closeAllOpenFileTabs(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final workspaceState = ref.read(workspaceControllerProvider);
    final workspace = workspaceState.workspace;
    final gitState = ref.read(gitControllerProvider);
    if (workspace == null ||
        workspaceTabEntries(
          workspace: workspace,
          gitState: gitState,
          documentBuffers: workspaceState.documentBuffers,
          activeBufferId: workspaceState.activeBufferId,
        ).isEmpty) {
      return;
    }
    if (!await confirmSafeToContinue(context, ref) || !context.mounted) {
      return;
    }
    await ref.read(workspaceControllerProvider.notifier).closeAllOpenFileTabs();
    ref.read(gitControllerProvider.notifier).clearSelection();
  }

  Future<void> _activateWorkspaceTab(
    WidgetRef ref,
    WorkspaceTabEntry tab,
  ) async {
    final gitController = ref.read(gitControllerProvider.notifier);
    switch (tab.kind) {
      case WorkspaceTabKind.file:
        await ref
            .read(workspaceControllerProvider.notifier)
            .activateDocumentBuffer(tab.bufferId!);
        gitController.deactivateDiffFile();
      case WorkspaceTabKind.gitDiff:
        if (tab.path.isEmpty) {
          return;
        }
        await gitController.activateDiffFile(tab.path);
    }
  }

  Future<void> _closeWorkspaceTab(WidgetRef ref, WorkspaceTabEntry tab) async {
    final gitController = ref.read(gitControllerProvider.notifier);
    switch (tab.kind) {
      case WorkspaceTabKind.file:
        await ref
            .read(workspaceControllerProvider.notifier)
            .closeDocumentBuffer(tab.bufferId!);
        gitController.deactivateDiffFile();
      case WorkspaceTabKind.gitDiff:
        if (tab.path.isEmpty) {
          gitController.clearSelection();
        } else {
          gitController.closeDiffFile(tab.path);
        }
    }
  }

  Future<String?> _chooseWorkspaceFolder(WidgetRef ref) async {
    final context = rootNavigatorKey.currentContext;
    if (context == null) {
      return null;
    }
    return getDirectoryPath(
      initialDirectory: _initialDirectory(ref),
      confirmButtonText: context.l10n.open,
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

  String _displayPath(String path) {
    final name = p.basename(path);
    return name.isEmpty ? path : name;
  }

  void _toggleSidebar(WidgetRef ref, {required bool allowWithoutWorkspace}) {
    final workspace = ref.read(workspaceControllerProvider).workspace;
    if (workspace == null && !allowWithoutWorkspace) {
      return;
    }
    if (workspace != null && !_hasWorkspaceSidebar(workspace.kind)) {
      return;
    }
    final settings = ref.read(appSettingsControllerProvider);
    final visible = !settings.sidebarVisible;
    if (!visible) {
      _clearGitDetailSelection(ref);
    }
    unawaited(
      ref
          .read(appSettingsControllerProvider.notifier)
          .setSidebarVisible(visible),
    );
  }

  bool _hasWorkspaceSidebar(WorkspaceKind kind) {
    return switch (kind) {
      WorkspaceKind.untitledMarkdown ||
      WorkspaceKind.singleMarkdown ||
      WorkspaceKind.markdownFolder ||
      WorkspaceKind.writersideModule => true,
    };
  }

  void _clearGitDetailSelection(WidgetRef ref) {
    final gitState = ref.read(gitControllerProvider);
    if (gitState.selectedDiff != null ||
        gitState.selectedFilePath != null ||
        gitState.selectedCommitHash != null ||
        gitState.selectedCommitFilePath != null ||
        gitState.openDiffFilePaths.isNotEmpty) {
      ref.read(gitControllerProvider.notifier).clearSelection();
    }
  }

  HeaderBarConfiguration _nativeHeaderBarDefaults(
    BuildContext context,
    AppSettings settings,
    BusyMarkCommandRegistry commandRegistry, {
    required bool fullScreen,
  }) {
    final material = MaterialLocalizations.of(context);
    final l10n = context.l10n;
    final theme = HeaderBarTheme.fromContext(context);
    final textDirection = Directionality.maybeOf(context) ?? TextDirection.ltr;
    BusyMarkCommand command(String id) => commandRegistry[id]!;
    String label(String id) => command(id).label(context);
    String shortcut(String id) => command(id).shortcut!.label;
    String accelerator(String id) => command(id).shortcut!.gtkAccelerator!;
    final labels = HeaderBarLabels(
      editor: label(BusyMarkCommandIds.viewEditor),
      source: label(BusyMarkCommandIds.viewSource),
      preview: label(BusyMarkCommandIds.viewReading),
      split: label(BusyMarkCommandIds.viewSplit),
      viewMode: l10n.viewMode,
      editorShortcut: shortcut(BusyMarkCommandIds.viewEditor),
      editorGtkAccelerator: accelerator(BusyMarkCommandIds.viewEditor),
      sourceShortcut: shortcut(BusyMarkCommandIds.viewSource),
      sourceGtkAccelerator: accelerator(BusyMarkCommandIds.viewSource),
      previewShortcut: shortcut(BusyMarkCommandIds.viewReading),
      previewGtkAccelerator: accelerator(BusyMarkCommandIds.viewReading),
      splitShortcut: shortcut(BusyMarkCommandIds.viewSplit),
      splitGtkAccelerator: accelerator(BusyMarkCommandIds.viewSplit),
      search: material.searchFieldLabel,
      searchShortcut: shortcut(BusyMarkCommandIds.search),
      refresh: l10n.validate,
      menu: l10n.mainMenu,
      sidebar: settings.sidebarVisible ? l10n.hideSidebar : l10n.showSidebar,
      sidebarShortcut: shortcut(BusyMarkCommandIds.toggleSidebar),
      back: material.backButtonTooltip,
      backShortcut: shortcut(BusyMarkCommandIds.back),
      save: label(BusyMarkCommandIds.save),
      exportPdf: label(BusyMarkCommandIds.exportPdf),
      exportPdfShortcut: shortcut(BusyMarkCommandIds.exportPdf),
      exportPdfGtkAccelerator: accelerator(BusyMarkCommandIds.exportPdf),
      fullScreen: label(BusyMarkCommandIds.fullScreen),
      fullScreenShortcut: shortcut(BusyMarkCommandIds.fullScreen),
      fullScreenGtkAccelerator: accelerator(BusyMarkCommandIds.fullScreen),
      settings: label(BusyMarkCommandIds.settings),
      settingsShortcut: shortcut(BusyMarkCommandIds.settings),
      settingsGtkAccelerator: accelerator(BusyMarkCommandIds.settings),
      keyboardShortcuts: label(BusyMarkCommandIds.keyboardShortcuts),
      keyboardShortcutsShortcut: shortcut(BusyMarkCommandIds.keyboardShortcuts),
      keyboardShortcutsGtkAccelerator: accelerator(
        BusyMarkCommandIds.keyboardShortcuts,
      ),
      markdownAndHtml: label(BusyMarkCommandIds.markdownAndHtml),
      markdownAndHtmlShortcut: shortcut(BusyMarkCommandIds.markdownAndHtml),
      markdownAndHtmlGtkAccelerator: accelerator(
        BusyMarkCommandIds.markdownAndHtml,
      ),
      reportIssue: l10n.reportIssue,
      aboutBusyMark: l10n.aboutBusyMark,
    );
    return HeaderBarConfiguration(
      title: l10n.appTitle,
      viewMode: AppViewMode.editor,
      searchQuery: '',
      textDirection: textDirection,
      canRefresh: false,
      documentControlsVisible: false,
      searchActive: false,
      searchVisible: false,
      sidebarVisible: false,
      sidebarToggleVisible: false,
      backVisible: false,
      fullScreen: fullScreen,
      modalBarrierDepth: 0,
      sidebarWidth: BusyMarkSizes.sidebarWidth,
      labels: labels,
      theme: theme,
    );
  }
}

class _BusyMarkWindowLifecycle extends ConsumerStatefulWidget {
  const _BusyMarkWindowLifecycle({required this.child});

  final Widget child;

  @override
  ConsumerState<_BusyMarkWindowLifecycle> createState() =>
      _BusyMarkWindowLifecycleState();
}

class _BusyMarkWindowLifecycleState
    extends ConsumerState<_BusyMarkWindowLifecycle> {
  late final WindowControlService _windowControlService;

  @override
  void initState() {
    super.initState();
    _windowControlService = ref.read(windowControlServiceProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _windowControlService.registerCloseHandler(_handleWindowClose);
      unawaited(_windowControlService.initialize());
    });
  }

  @override
  void dispose() {
    _windowControlService.unregisterCloseHandler();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  Future<void> _handleWindowClose() async {
    final context = rootNavigatorKey.currentContext ?? this.context;
    if (!context.mounted) {
      return;
    }
    final settings = ref.read(appSettingsControllerProvider);
    var workspace = ref.read(workspaceControllerProvider);
    if (settings.autoSave && workspace.hasUnsavedChanges) {
      await ref.read(workspaceControllerProvider.notifier).saveAll();
      workspace = ref.read(workspaceControllerProvider);
    }
    final controller = ref.read(workspaceControllerProvider.notifier);
    await _windowControlService.handleCloseRequest(
      hasUnsavedChanges: workspace.hasUnsavedChanges,
      confirmCloseWithUnsavedChanges: settings.confirmCloseWithUnsavedChanges,
      showCloseDialog: () => _showWindowCloseDialog(context),
      saveChanges: () => _saveAllDirtyDocuments(context),
      beforeClose: controller.markCleanShutdown,
      discardChanges: controller.discardRecoveryForShutdown,
    );
  }

  Future<bool> _saveAllDirtyDocuments(BuildContext context) async {
    final controller = ref.read(workspaceControllerProvider.notifier);
    final dirtyIds = [
      for (final buffer
          in ref.read(workspaceControllerProvider).documentBuffers)
        if (buffer.isDirty) buffer.id,
    ];
    for (final bufferId in dirtyIds) {
      if (!await controller.activateDocumentBuffer(bufferId) ||
          !context.mounted ||
          !await saveActiveWithOverwriteConfirmation(context, ref)) {
        return false;
      }
    }
    return !ref.read(workspaceControllerProvider).hasUnsavedChanges;
  }

  Future<WindowCloseAction?> _showWindowCloseDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final headerBar = ref.read(linuxHeaderBarServiceProvider);
    final dirtyBuffers = ref.read(workspaceControllerProvider).dirtyBuffers;
    return showBusyMarkModalDialog<WindowCloseAction>(
      context,
      headerBarService: headerBar.isAvailable ? headerBar : null,
      builder: (context) => BusyMarkDialogShell(
        title: l10n.closeUnsavedChangesTitle,
        maxWidth: BusyMarkSizes.dialog,
        actions: [
          BusyMarkDialogButton(
            label: l10n.closeUnsavedChangesCancel,
            icon: BusyMarkGlyphs.clear,
            onPressed: () => Navigator.pop(context, WindowCloseAction.cancel),
          ),
          BusyMarkDialogButton(
            label: l10n.closeUnsavedChangesDiscard,
            icon: BusyMarkGlyphs.delete,
            destructive: true,
            onPressed: () => Navigator.pop(context, WindowCloseAction.discard),
          ),
          BusyMarkDialogButton(
            label: l10n.closeUnsavedChangesSave,
            icon: BusyMarkGlyphs.save,
            suggested: true,
            onPressed: () => Navigator.pop(context, WindowCloseAction.save),
          ),
        ],
        children: [
          Text(_closeUnsavedChangesMessage(context)),
          const SizedBox(height: BusyMarkSpacing.md),
          BusyMarkGroupedList(
            filled: true,
            children: [
              for (final buffer in dirtyBuffers)
                BusyMarkActionRow(
                  title: buffer.displayName,
                  subtitle: buffer.filePath,
                  leading: const Icon(BusyMarkGlyphs.document),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _closeUnsavedChangesMessage(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.read(workspaceControllerProvider);
    final count = state.dirtyBuffers.length;
    if (count != 1) {
      return l10n.closeUnsavedChangesMultipleMessage(count);
    }
    return l10n.closeUnsavedChangesSingleMessage;
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
    final commands =
        BusyMarkCommandRegistryScope.read(context) ??
        BusyMarkCommandCatalog.metadata;
    if (commands.shortcutAccepts(BusyMarkCommandIds.search, event, keyboard)) {
      if (rootNavigatorKey.currentState?.canPop() ?? false) {
        return false;
      }
      ref.read(workspaceSearchOpenRequestProvider.notifier).request();
      return true;
    }
    if (commands.shortcutAccepts(
      BusyMarkCommandIds.textEscape,
      event,
      keyboard,
    )) {
      if (rootNavigatorKey.currentState?.canPop() ?? false) {
        return false;
      }
      ref.read(workspaceSearchCloseRequestProvider.notifier).request();
      return false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _NewWorkspaceIntent extends Intent {
  const _NewWorkspaceIntent();
}

class _OpenWorkspaceIntent extends Intent {
  const _OpenWorkspaceIntent();
}

sealed class _OpenChooserChoice {
  const _OpenChooserChoice();
}

final class _OpenMarkdownFile extends _OpenChooserChoice {
  const _OpenMarkdownFile();
}

final class _OpenWorkspaceFolder extends _OpenChooserChoice {
  const _OpenWorkspaceFolder();
}

final class _OpenRecentWorkspace extends _OpenChooserChoice {
  const _OpenRecentWorkspace(this.path);

  final String path;
}

sealed class _NewChooserChoice {
  const _NewChooserChoice();
}

final class _CreateMarkdownFile extends _NewChooserChoice {
  const _CreateMarkdownFile();
}

final class _CreateWritersideProject extends _NewChooserChoice {
  const _CreateWritersideProject();
}

class _SaveActiveIntent extends Intent {
  const _SaveActiveIntent();
}

class _ExportPdfIntent extends Intent {
  const _ExportPdfIntent();
}

class _ToggleFullScreenIntent extends Intent {
  const _ToggleFullScreenIntent();
}

class _BackIntent extends Intent {
  const _BackIntent();
}

class _KeyboardShortcutsIntent extends Intent {
  const _KeyboardShortcutsIntent();
}

class _CommandPaletteIntent extends Intent {
  const _CommandPaletteIntent();
}

class _SettingsIntent extends Intent {
  const _SettingsIntent();
}

class _MarkdownAndHtmlIntent extends Intent {
  const _MarkdownAndHtmlIntent();
}

class _NextTabIntent extends Intent {
  const _NextTabIntent();
}

class _PreviousTabIntent extends Intent {
  const _PreviousTabIntent();
}

class _CloseTabIntent extends Intent {
  const _CloseTabIntent();
}

class _CloseAllTabsIntent extends Intent {
  const _CloseAllTabsIntent();
}

class _OpenSearchIntent extends Intent {
  const _OpenSearchIntent();
}

class _ToggleSidebarIntent extends Intent {
  const _ToggleSidebarIntent();
}

class _DocumentViewModeIntent extends Intent {
  const _DocumentViewModeIntent(this.mode);

  final DocumentViewModePreference mode;
}
