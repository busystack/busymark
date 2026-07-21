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
import '../git/application/git_controller.dart';
import '../platform/linux_header_bar_service.dart';
import '../workspace/workspace_controller.dart';
import '../workspace/workspace_model.dart';
import '../workspace/workspace_safety.dart';
import '../workspace/workspace_tabs.dart';
import 'app_router.dart';
import 'app_settings.dart';
import 'busymark_shortcuts.dart';
import 'app_theme.dart';
import 'busymark_dialogs.dart';
import 'busymark_design.dart';
import 'busymark_glyphs.dart';
import 'localization.dart';
import 'system_accent.dart';
import 'window_control_service.dart';

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
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        ...GlobalUbuntuLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        _configureNativeHeaderBar(context, ref, settings);
        return _BusyMarkWindowLifecycle(
          child: Shortcuts(
            shortcuts: {
              BusyMarkAppShortcutActivators.newDocument:
                  const _NewMarkdownIntent(),
              BusyMarkAppShortcutActivators.open: const _OpenWorkspaceIntent(),
              BusyMarkAppShortcutActivators.save: const _SaveActiveIntent(),
              BusyMarkAppShortcutActivators.keyboardShortcuts:
                  const _KeyboardShortcutsIntent(),
              BusyMarkAppShortcutActivators.settings: const _SettingsIntent(),
              BusyMarkAppShortcutActivators.markdownAndHtml:
                  const _MarkdownAndHtmlIntent(),
              BusyMarkAppShortcutActivators.nextTab: const _NextTabIntent(),
              BusyMarkAppShortcutActivators.previousTab:
                  const _PreviousTabIntent(),
              BusyMarkAppShortcutActivators.closeTab: const _CloseTabIntent(),
              BusyMarkAppShortcutActivators.closeAllTabs:
                  const _CloseAllTabsIntent(),
              BusyMarkAppShortcutActivators.find: const _OpenSearchIntent(),
              BusyMarkAppShortcutActivators.toggleSidebar:
                  const _ToggleSidebarIntent(),
              BusyMarkDocumentViewShortcutActivators.editor:
                  const _DocumentViewModeIntent(
                    DocumentViewModePreference.editor,
                  ),
              BusyMarkDocumentViewShortcutActivators.source:
                  const _DocumentViewModeIntent(
                    DocumentViewModePreference.source,
                  ),
              BusyMarkDocumentViewShortcutActivators.preview:
                  const _DocumentViewModeIntent(
                    DocumentViewModePreference.preview,
                  ),
              BusyMarkDocumentViewShortcutActivators.split:
                  const _DocumentViewModeIntent(
                    DocumentViewModePreference.split,
                  ),
            },
            child: Actions(
              actions: {
                _NewMarkdownIntent: CallbackAction<_NewMarkdownIntent>(
                  onInvoke: (intent) {
                    unawaited(() async {
                      final navigatorContext = rootNavigatorKey.currentContext;
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
                          showBusyMarkKeyboardShortcutsDialog(navigatorContext);
                        }
                        return null;
                      },
                    ),
                _SettingsIntent: CallbackAction<_SettingsIntent>(
                  onInvoke: (intent) {
                    final navigatorContext = rootNavigatorKey.currentContext;
                    if (navigatorContext != null) {
                      GoRouter.of(navigatorContext).go('/settings');
                    }
                    return null;
                  },
                ),
                _MarkdownAndHtmlIntent: CallbackAction<_MarkdownAndHtmlIntent>(
                  onInvoke: (intent) {
                    final navigatorContext = rootNavigatorKey.currentContext;
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
                        _activateOpenFileTab(navigatorContext, ref, next: true),
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
                      unawaited(_closeActiveOpenFileTab(navigatorContext, ref));
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
                          router.routeInformationProvider.value.uri.path == '/',
                    );
                    return null;
                  },
                ),
                _DocumentViewModeIntent:
                    CallbackAction<_DocumentViewModeIntent>(
                      onInvoke: (intent) {
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
          ),
        );
      },
      routerConfig: router,
    );
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
    final workspace = ref.read(workspaceControllerProvider).workspace;
    final gitState = ref.read(gitControllerProvider);
    if (workspace == null) {
      return;
    }
    final tabs = workspaceTabEntries(workspace: workspace, gitState: gitState);
    if (tabs.length < 2) {
      return;
    }
    if (!await saveOrConfirmSafeToChangeActiveFile(context, ref) ||
        !context.mounted) {
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
    final workspace = ref.read(workspaceControllerProvider).workspace;
    final gitState = ref.read(gitControllerProvider);
    if (workspace == null) {
      return;
    }
    final tabs = workspaceTabEntries(workspace: workspace, gitState: gitState);
    final activeIndex = activeWorkspaceTabIndex(tabs);
    if (activeIndex < 0) {
      return;
    }
    final activeTab = tabs[activeIndex];
    if (activeTab.kind == WorkspaceTabKind.file) {
      if (!await saveOrConfirmSafeToChangeActiveFile(context, ref) ||
          !context.mounted) {
        return;
      }
    }
    await _closeWorkspaceTab(ref, activeTab);
  }

  Future<void> _closeAllOpenFileTabs(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final workspace = ref.read(workspaceControllerProvider).workspace;
    final gitState = ref.read(gitControllerProvider);
    if (workspace == null ||
        workspaceTabEntries(workspace: workspace, gitState: gitState).isEmpty) {
      return;
    }
    if (!await saveOrConfirmSafeToChangeActiveFile(context, ref) ||
        !context.mounted) {
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
            .openActiveFile(tab.path);
        gitController.deactivateDiffFile();
      case WorkspaceTabKind.gitDiff:
        if (tab.path.isEmpty) {
          return;
        }
        gitController.selectCommitFile(tab.path);
    }
  }

  Future<void> _closeWorkspaceTab(WidgetRef ref, WorkspaceTabEntry tab) async {
    final gitController = ref.read(gitControllerProvider.notifier);
    switch (tab.kind) {
      case WorkspaceTabKind.file:
        await ref
            .read(workspaceControllerProvider.notifier)
            .closeOpenFileTab(tab.path);
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

  void _configureNativeHeaderBar(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) {
    final service = ref.watch(linuxHeaderBarServiceProvider);
    if (!service.isAvailable) {
      return;
    }
    final material = MaterialLocalizations.of(context);
    final l10n = context.l10n;
    final theme = HeaderBarTheme.fromContext(context);
    final textDirection = Directionality.maybeOf(context) ?? TextDirection.ltr;
    final labels = HeaderBarLabels(
      editor: l10n.editor,
      source: l10n.source,
      preview: l10n.preview,
      split: l10n.split,
      viewMode: l10n.viewMode,
      editorShortcut: BusyMarkDocumentViewShortcutLabels.editor,
      sourceShortcut: BusyMarkDocumentViewShortcutLabels.source,
      previewShortcut: BusyMarkDocumentViewShortcutLabels.preview,
      splitShortcut: BusyMarkDocumentViewShortcutLabels.split,
      search: material.searchFieldLabel,
      refresh: l10n.validate,
      menu: l10n.mainMenu,
      sidebar: settings.sidebarVisible ? l10n.hideSidebar : l10n.showSidebar,
      sidebarShortcut: BusyMarkSidebarShortcutLabels.toggleSidebar,
      back: material.backButtonTooltip,
      save: l10n.save,
      settings: l10n.settings,
      settingsShortcut: BusyMarkAppShortcutLabels.settings,
      keyboardShortcuts: l10n.keyboardShortcuts,
      keyboardShortcutsShortcut: BusyMarkAppShortcutLabels.keyboardShortcuts,
      markdownAndHtml: l10n.markdownAndHtml,
      markdownAndHtmlShortcut: BusyMarkAppShortcutLabels.markdownAndHtml,
      aboutBusyMark: l10n.aboutBusyMark,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(() async {
        await service.setTextDirection(textDirection);
        await service.setSidebarWidth(BusyMarkSizes.sidebarWidth);
        await service.setTheme(theme);
        await service.setLocalizedLabels(labels);
      }());
    });
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
      await ref
          .read(workspaceControllerProvider.notifier)
          .autoSaveActiveIfNeeded();
      workspace = ref.read(workspaceControllerProvider);
    }
    await _windowControlService.handleCloseRequest(
      hasUnsavedChanges: workspace.hasUnsavedChanges,
      confirmCloseWithUnsavedChanges: settings.confirmCloseWithUnsavedChanges,
      showCloseDialog: () => _showWindowCloseDialog(context),
      saveChanges: () => saveActiveWithOverwriteConfirmation(context, ref),
    );
  }

  Future<WindowCloseAction?> _showWindowCloseDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final headerBar = ref.read(linuxHeaderBarServiceProvider);
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
        children: [Text(_closeUnsavedChangesMessage(context))],
      ),
    );
  }

  String _closeUnsavedChangesMessage(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.read(workspaceControllerProvider);
    if (!state.hasUnsavedChanges) {
      return l10n.closeUnsavedChangesMultipleMessage(0);
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
    if (keyboard.isControlPressed &&
        event.logicalKey == LogicalKeyboardKey.keyF) {
      ref.read(workspaceSearchOpenRequestProvider.notifier).request();
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
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

class _NewMarkdownIntent extends Intent {
  const _NewMarkdownIntent();
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

class _SaveActiveIntent extends Intent {
  const _SaveActiveIntent();
}

class _KeyboardShortcutsIntent extends Intent {
  const _KeyboardShortcutsIntent();
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
