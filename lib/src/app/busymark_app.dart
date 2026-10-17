import '../workspace/recent_presentation.dart';
import '../search/welcome_notes_action.dart';
import '../nextcloud_notes/application/nextcloud_connection.dart';
import '../nextcloud_notes/application/notes_navigation.dart';
import '../nextcloud_notes/presentation/notes_workspace_ui.dart';
import '../references/reference_controller.dart';
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
import '../export/workspace_export_ui.dart';
import '../clipboard/clipboard_history_controller.dart';
import '../git/application/git_controller.dart';
import '../platform/linux_header_bar_service.dart';
import '../platform/gtk_animation_settings_service.dart';
import '../platform/gtk_header_icon_service.dart';
import '../local_history/local_history_controller.dart';
import '../workspace/workspace_controller.dart';
import '../workspace/workspace_model.dart';
import '../workspace/presentation/welcome_screen.dart';
import '../workspace/workspace_safety.dart';
import '../workspace/workspace_tabs.dart';
import '../workspace/workspace_tab_actions.dart';
import 'app_router.dart';
import 'app_locale.dart';
import 'app_settings.dart';
import '../search/search_session.dart';
import '../search/search_activation.dart';
import '../workspace/recent_navigation.dart';
import 'command_registry.dart';
import 'command_shortcuts.dart';
import 'keymap_controller.dart';
import 'shortcut_capture.dart';
import 'app_theme.dart';
import 'busymark_dialogs.dart';
import 'busymark_design.dart';
import 'busymark_search_field.dart';
import 'busymark_glyphs.dart';
import 'busymark_toast.dart';
import 'localization.dart';
import 'system_accent.dart';
import 'window_control_service.dart';
import 'linux/linux_window_host.dart';

final _busyMarkDefaultCommandRegistryProvider =
    Provider<BusyMarkCommandRegistry>((ref) {
      final commandIntents = <String, Intent>{
        for (final id in BusyMarkCommandCatalog.notesWorkspaceCommandIds)
          id: _NotesWorkspaceActionIntent(id),
        BusyMarkCommandIds.newNote: const _NotesActionIntent(
          WelcomeNotesAction.create,
        ),
        BusyMarkCommandIds.browseNotes: const _NotesActionIntent(
          WelcomeNotesAction.browse,
        ),
        BusyMarkCommandIds.newDocument: const _NewWorkspaceIntent(),
        BusyMarkCommandIds.open: const _OpenWorkspaceIntent(),
        BusyMarkCommandIds.save: const _SaveActiveIntent(),
        BusyMarkCommandIds.export: const _ExportIntent(),
        BusyMarkCommandIds.fullScreen: const _ToggleFullScreenIntent(),
        BusyMarkCommandIds.back: const _BackIntent(),
        BusyMarkCommandIds.keyboardShortcuts: const _KeyboardShortcutsIntent(),
        BusyMarkCommandIds.syntaxReference: const _SyntaxReferenceIntent(),
        BusyMarkCommandIds.settings: const _SettingsIntent(),
        BusyMarkCommandIds.nextTab: const _NextTabIntent(),
        BusyMarkCommandIds.previousTab: const _PreviousTabIntent(),
        BusyMarkCommandIds.closeTab: const _CloseTabIntent(),
        BusyMarkCommandIds.closeAllTabs: const _CloseAllTabsIntent(),
        BusyMarkCommandIds.toggleSidebar: const _ToggleSidebarIntent(),
        BusyMarkCommandIds.clipboardHistory:
            const _OpenClipboardHistoryIntent(),
        BusyMarkCommandIds.localHistory: const _OpenLocalHistoryIntent(),
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
      final defaults = BusyMarkCommandCatalog.create(
        executions: {
          for (final id in [
            BusyMarkCommandIds.sidebarFiles,
            BusyMarkCommandIds.sidebarToc,
            BusyMarkCommandIds.sidebarOutline,
            BusyMarkCommandIds.sidebarGit,
          ])
            id: () => ref
                .read(workspaceNavigationCommandProvider.notifier)
                .request(id),
          for (final entry in searchCommandDestinations.entries)
            entry.key: () {
              final search = ref.read(searchSessionProvider.notifier);
              if (entry.value == SearchCategory.localHistory) {
                search.openHistory();
              } else {
                search.open(category: entry.value);
              }
            },
          BusyMarkCommandIds.elementProperties: () => ref
              .read(workspaceControllerProvider.notifier)
              .toggleElementProperties
              ?.call(),
          BusyMarkCommandIds.references: () =>
              ref.read(referencePanelRequestProvider.notifier).request(),
          for (final entry in commandIntents.entries)
            entry.key: () {
              final target = rootNavigatorKey.currentContext;
              if (target != null) {
                Actions.maybeInvoke(target, entry.value);
              }
            },
        },
        enabled: {
          for (final id in BusyMarkCommandCatalog.notesWorkspaceCommandIds)
            id: () =>
                ref.read(searchSessionProvider.notifier).workspaceVisible &&
                ref.read(workspaceControllerProvider).workspace?.isRemote ==
                    true,
          BusyMarkCommandIds.sidebarFiles: () =>
              ref.read(searchSessionProvider.notifier).workspaceVisible &&
              ref.read(workspaceControllerProvider).workspace != null,
          BusyMarkCommandIds.sidebarToc: () =>
              ref.read(searchSessionProvider.notifier).workspaceVisible &&
              ref
                      .read(workspaceControllerProvider)
                      .workspace
                      ?.writersideProject !=
                  null,
          BusyMarkCommandIds.sidebarOutline: () =>
              ref.read(searchSessionProvider.notifier).workspaceVisible &&
              ref.read(workspaceControllerProvider).activeBuffer != null,
          BusyMarkCommandIds.sidebarGit: () =>
              ref.read(searchSessionProvider.notifier).workspaceVisible &&
              ref.read(gitControllerProvider).repositoryInfo != null,
          for (final id in [
            BusyMarkCommandIds.elementProperties,
            BusyMarkCommandIds.references,
            BusyMarkCommandIds.viewEditor,
            BusyMarkCommandIds.viewSource,
            BusyMarkCommandIds.viewReading,
            BusyMarkCommandIds.viewSplit,
            BusyMarkCommandIds.nextTab,
            BusyMarkCommandIds.previousTab,
            BusyMarkCommandIds.closeTab,
            BusyMarkCommandIds.closeAllTabs,
          ])
            id: () =>
                ref.read(searchSessionProvider.notifier).workspaceVisible &&
                ref.read(workspaceControllerProvider).workspace != null,
          for (final entry in searchCommandDestinations.entries)
            entry.key: () => ref
                .read(searchSessionProvider.notifier)
                .categories
                .contains(entry.value),
          BusyMarkCommandIds.save: () =>
              ref.read(searchSessionProvider.notifier).workspaceVisible &&
              ref.read(workspaceControllerProvider).workspace != null,
          BusyMarkCommandIds.export: () =>
              ref.read(searchSessionProvider.notifier).workspaceVisible &&
              canExportWorkspace(ref.read(workspaceControllerProvider)),
          BusyMarkCommandIds.clipboardHistory: () =>
              ref.read(searchSessionProvider.notifier).workspaceVisible &&
              ref.read(workspaceControllerProvider).workspace != null,
          BusyMarkCommandIds.localHistory: () =>
              ref.read(searchSessionProvider.notifier).workspaceVisible &&
              ref.read(workspaceControllerProvider).workspace != null,
          BusyMarkCommandIds.findLocalHistory: () =>
              ref.read(searchSessionProvider.notifier).workspaceVisible &&
              ref.read(workspaceControllerProvider).workspace != null,
        },
      );
      return defaults;
    });

final busyMarkCommandRegistryProvider = Provider<BusyMarkCommandRegistry>((
  ref,
) {
  return effectiveCommandRegistry(
    ref.watch(_busyMarkDefaultCommandRegistryProvider),
    ref.watch(appSettingsControllerProvider.select((s) => s.shortcutOverrides)),
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
    final gtkAnimationsEnabled =
        ref.watch(gtkAnimationsEnabledProvider).asData?.value ??
        ref.watch(initialGtkAnimationsEnabledProvider) ??
        true;
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
        final commandRegistry = ref.watch(busyMarkCommandRegistryProvider);
        final headerBarDefaults = _nativeHeaderBarDefaults(
          context,
          settings,
          commandRegistry,
          fullScreen: windowControls.isFullScreen,
        );
        final appContent = HeaderBarConfigurationDefaults(
          configuration: headerBarDefaults,
          child: _BusyMarkWindowLifecycle(
            child: BusyMarkCommandShortcuts(
              shortcuts: commandRegistry.shortcutIntents(
                excludedIds: searchCommandDestinations.keys.toSet(),
                scopes: const {
                  BusyMarkCommandScope.application,
                  BusyMarkCommandScope.documentView,
                },
                intentFor: BusyMarkCommandIntent.new,
              ),
              child: Actions(
                actions: {
                  _NotesWorkspaceActionIntent:
                      CallbackAction<_NotesWorkspaceActionIntent>(
                        onInvoke: (intent) {
                          final target = rootNavigatorKey.currentContext;
                          final workspace = ref
                              .read(workspaceControllerProvider)
                              .workspace;
                          if (target == null ||
                              !ref
                                  .read(searchSessionProvider.notifier)
                                  .workspaceVisible ||
                              workspace?.isRemote != true) {
                            return null;
                          }
                          switch (intent.commandId) {
                            case BusyMarkCommandIds.syncNotes:
                              unawaited(
                                ref
                                    .read(workspaceControllerProvider.notifier)
                                    .refreshNextcloudNotes(),
                              );
                            case BusyMarkCommandIds.exportNotes:
                              final repository = ref
                                  .read(nextcloudNotesRepositoryProvider)
                                  .value;
                              if (repository == null) return null;
                              unawaited(
                                showNotesExport(target, ref, [
                                  for (final note in repository.notes)
                                    if (note.accountId ==
                                            workspace!.nextcloudAccountId &&
                                        !isNotesRecovery(note))
                                      note.localId,
                                ]),
                              );
                            case BusyMarkCommandIds.importNotesFolder:
                              unawaited(showNotesImport(target, ref));
                            case BusyMarkCommandIds.importNotesFile:
                              unawaited(
                                showNotesImport(target, ref, folder: false),
                              );
                          }
                          return null;
                        },
                      ),
                  BusyMarkCommandIntent: CallbackAction<BusyMarkCommandIntent>(
                    onInvoke: (intent) {
                      if (searchCommandDestinations.containsKey(
                            intent.commandId,
                          ) &&
                          (rootNavigatorKey.currentState?.canPop() ?? false)) {
                        return null;
                      }
                      unawaited(commandRegistry.execute(intent.commandId));
                      return null;
                    },
                  ),
                  _NotesActionIntent: CallbackAction<_NotesActionIntent>(
                    onInvoke: (intent) {
                      final target = rootNavigatorKey.currentContext;
                      if (target != null) {
                        unawaited(
                          performWelcomeNotesAction(target, ref, intent.action),
                        );
                      }
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
                  _ExportIntent: CallbackAction<_ExportIntent>(
                    onInvoke: (intent) {
                      final state = ref.read(workspaceControllerProvider);
                      final navigatorContext = rootNavigatorKey.currentContext;
                      if (navigatorContext != null &&
                          canExportWorkspace(state)) {
                        unawaited(exportWorkspace(navigatorContext, ref));
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
                            openKeyboardShortcutsSettings(navigatorContext);
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
                  _SyntaxReferenceIntent:
                      CallbackAction<_SyntaxReferenceIntent>(
                        onInvoke: (intent) {
                          final navigatorContext =
                              rootNavigatorKey.currentContext;
                          if (navigatorContext != null) {
                            showBusyMarkSyntaxReferenceDialog(navigatorContext);
                          }
                          return null;
                        },
                      ),
                  _OpenClipboardHistoryIntent:
                      CallbackAction<_OpenClipboardHistoryIntent>(
                        onInvoke: (intent) {
                          ref
                              .read(
                                clipboardHistoryOpenRequestProvider.notifier,
                              )
                              .request();
                          return null;
                        },
                      ),
                  _OpenLocalHistoryIntent:
                      CallbackAction<_OpenLocalHistoryIntent>(
                        onInvoke: (intent) {
                          ref
                              .read(localHistoryOpenRequestProvider.notifier)
                              .request();
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
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations:
                  MediaQuery.disableAnimationsOf(context) ||
                  !gtkAnimationsEnabled,
            ),
            child: GtkHeaderIconScope(
              service: ref.watch(gtkHeaderIconServiceProvider),
              child: LinuxWindowHost(
                child: BusyMarkToastOverlay(child: appContent),
              ),
            ),
          ),
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
    final container = ProviderScope.containerOf(context, listen: false);
    final cachedAccounts = container.exists(nextcloudNotesRepositoryProvider)
        ? ref.read(nextcloudNotesRepositoryProvider).value?.accounts
        : null;
    final connectedAccount = container.exists(nextcloudConnectionProvider)
        ? ref.read(nextcloudConnectionProvider).account
        : null;
    final accountLabels = <String, String>{
      for (final account in cachedAccounts ?? [])
        account.id: '${account.loginName} · ${account.server.host}',
      if (connectedAccount != null)
        connectedAccount.id:
            '${connectedAccount.loginName} · ${connectedAccount.server.host}',
    };
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
                      recentResourceTitle(dialogContext, recent),
                    ),
                    subtitle: busyMarkLtrIsolateFor(
                      dialogContext,
                      recentResourceLocation(
                        dialogContext,
                        recent,
                        accountLabel: accountLabels[recent.accountId],
                      ),
                    ),
                    leading: const Icon(BusyMarkGlyphs.history),
                    trailing: Icon(
                      BusyMarkGlyphs.forwardFor(
                        Directionality.of(dialogContext),
                      ),
                    ),
                    onTap: () => Navigator.pop(
                      dialogContext,
                      _OpenRecentResource(recent),
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
    if (choice case _OpenRecentResource(:final resource)) {
      await openRecentResource(context, ref, resource);
      return;
    }
    final path = switch (choice) {
      _OpenMarkdownFile() => await _chooseMarkdownFile(ref),
      _OpenWorkspaceFolder() => await _chooseWorkspaceFolder(ref),
      _OpenRecentResource() => null,
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
    final startsWorkspace =
        settingsReturnTargetForUri(router.routeInformationProvider.value.uri) ==
        SettingsReturnTarget.welcome;
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
        final controller = ref.read(workspaceControllerProvider.notifier);
        if (startsWorkspace) {
          if (!await confirmSafeToContinue(context, ref) || !context.mounted) {
            return;
          }
          if (!await controller.createMarkdownWorkspace()) return;
        } else {
          await controller.createMarkdownFile();
        }
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
      localHistoryRevisionId: ref
          .read(localHistoryControllerProvider)
          .selectedRevisionId,
      localHistoryDocumentName: ref
          .read(localHistoryControllerProvider)
          .selectedDocument
          ?.displayName,
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
      localHistoryRevisionId: ref
          .read(localHistoryControllerProvider)
          .selectedRevisionId,
      localHistoryDocumentName: ref
          .read(localHistoryControllerProvider)
          .selectedDocument
          ?.displayName,
    );
    final activeIndex = activeWorkspaceTabIndex(tabs);
    if (activeIndex < 0) {
      return;
    }
    final activeTab = tabs[activeIndex];
    await closeWorkspaceTab(context, ref, workspace: workspace, tab: activeTab);
  }

  Future<void> _closeAllOpenFileTabs(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final workspace = ref.read(workspaceControllerProvider).workspace;
    if (workspace == null) return;
    await closeAllWorkspaceTabs(context, ref, workspace: workspace);
  }

  Future<void> _activateWorkspaceTab(
    WidgetRef ref,
    WorkspaceTabEntry tab,
  ) async {
    final gitController = ref.read(gitControllerProvider.notifier);
    switch (tab.kind) {
      case WorkspaceTabKind.file:
        ref.read(localHistoryControllerProvider.notifier).clearComparison();
        await ref
            .read(workspaceControllerProvider.notifier)
            .activateDocumentBuffer(tab.bufferId!);
        gitController.deactivateDiffFile();
      case WorkspaceTabKind.gitDiff:
        ref.read(localHistoryControllerProvider.notifier).clearComparison();
        if (tab.path.isEmpty) {
          return;
        }
        await gitController.activateDiffFile(tab.path);
      case WorkspaceTabKind.localHistory:
        return;
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
      WorkspaceKind.nextcloudNotes ||
      WorkspaceKind.writersideModule => true,
    };
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
    String shortcut(String id) => command(id).shortcut?.label ?? '';
    String accelerator(String id) => command(id).shortcut?.gtkAccelerator ?? '';
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
      searchShortcut: '',
      refresh: l10n.validate,
      menu: l10n.mainMenu,
      sidebar: settings.sidebarVisible ? l10n.hideSidebar : l10n.showSidebar,
      sidebarShortcut: shortcut(BusyMarkCommandIds.toggleSidebar),
      back: material.backButtonTooltip,
      backShortcut: shortcut(BusyMarkCommandIds.back),
      save: label(BusyMarkCommandIds.save),
      export: label(BusyMarkCommandIds.export),
      exportShortcut: shortcut(BusyMarkCommandIds.export),
      exportGtkAccelerator: accelerator(BusyMarkCommandIds.export),
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
      syntaxReference: label(BusyMarkCommandIds.syntaxReference),
      syntaxReferenceShortcut: shortcut(BusyMarkCommandIds.syntaxReference),
      syntaxReferenceGtkAccelerator: accelerator(
        BusyMarkCommandIds.syntaxReference,
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
      canExportPdf: false,
      canExportHtml: false,
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
  late final AppLifecycleListener _notesLifecycle;
  late final GoRouter _notesRouter;

  @override
  void initState() {
    super.initState();
    _windowControlService = ref.read(windowControlServiceProvider);
    _notesRouter = ref.read(appRouterProvider);
    _notesRouter.routeInformationProvider.addListener(_notesRouteChanged);
    _notesLifecycle = AppLifecycleListener(
      onStateChange: (state) {
        final controller = ref.read(workspaceControllerProvider.notifier);
        controller.setNotesApplicationVisible(
          state == AppLifecycleState.resumed ||
              state == AppLifecycleState.inactive,
        );
        if (state == AppLifecycleState.resumed) {
          controller.refreshNotesOnFocus();
        }
      },
    );
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
    _notesRouter.routeInformationProvider.removeListener(_notesRouteChanged);
    _notesLifecycle.dispose();
    _windowControlService.unregisterCloseHandler();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  void _notesRouteChanged() {
    if (!mounted) return;
    ref
        .read(workspaceControllerProvider.notifier)
        .setNotesWorkspaceActive(
          _notesRouter.routeInformationProvider.value.uri.path.startsWith(
            '/workspace',
          ),
        );
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
    if (BusyMarkShortcutCapture.suppressing) return true;
    if (event is! KeyDownEvent) {
      return false;
    }
    if (rootNavigatorKey.currentState?.canPop() ?? false) return false;
    final focused = FocusManager.instance.primaryFocus?.context;
    if (focused != null) {
      final editable = focused.findAncestorStateOfType<EditableTextState>();
      if (editable?.widget.controller.value.composing.isValid == true) {
        return false;
      }
    }
    if (event.logicalKey == LogicalKeyboardKey.escape &&
        ref.read(searchSessionProvider).active) {
      ref.read(searchSessionProvider.notifier).close();
      return true;
    }
    final keyboard = HardwareKeyboard.instance;
    // Search delivery precedes Flutter's focus hierarchy. Let the query's
    // DefaultTextEditingShortcuts consume local editing before any reassigned
    // application search command, just as it does for other application actions.
    if (FocusManager.instance.primaryFocus is BusyMarkSearchFocusNode &&
        BusyMarkLocalTextEditingShortcuts.bindings.keys.any(
          (a) => a.accepts(event, keyboard),
        )) {
      return false;
    }
    if (ref.read(searchSessionProvider.notifier).categories.isEmpty) {
      return false;
    }
    final commands = ref.read(busyMarkCommandRegistryProvider);
    if (commands.shortcutAccepts(
      BusyMarkCommandIds.sidebarOutline,
      event,
      keyboard,
    )) {
      unawaited(commands.execute(BusyMarkCommandIds.sidebarOutline));
      return true;
    }
    for (final entry in searchCommandDestinations.entries) {
      if (commands.shortcutAccepts(entry.key, event, keyboard)) {
        unawaited(commands.execute(entry.key));
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      headerBarSearchEventsProvider,
      (_, next) => next.whenData((event) {
        final controller = ref.read(searchSessionProvider.notifier);
        if (!ref.read(searchSessionProvider).active &&
            (event is HeaderBarSearchQueryChanged ||
                event is HeaderBarSearchSubmitted)) {
          controller.open();
        }
        switch (event) {
          case HeaderBarSearchQueryChanged(:final query):
            controller.query(query);
          case HeaderBarSearchSubmitted(:final query):
            controller.query(query);
            unawaited(activateSelectedSearchResult(context, ref));
          case HeaderBarSearchCleared():
            controller.query('');
          case HeaderBarSearchEscapePressed():
            controller.close();
          case HeaderBarSearchFocusChanged():
            break;
        }
      }),
    );
    return widget.child;
  }
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

final class _OpenRecentResource extends _OpenChooserChoice {
  const _OpenRecentResource(this.resource);

  final RecentResource resource;
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

class _ExportIntent extends Intent {
  const _ExportIntent();
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

class _SettingsIntent extends Intent {
  const _SettingsIntent();
}

class _SyntaxReferenceIntent extends Intent {
  const _SyntaxReferenceIntent();
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

class _OpenClipboardHistoryIntent extends Intent {
  const _OpenClipboardHistoryIntent();
}

class _OpenLocalHistoryIntent extends Intent {
  const _OpenLocalHistoryIntent();
}

class _ToggleSidebarIntent extends Intent {
  const _ToggleSidebarIntent();
}

class _DocumentViewModeIntent extends Intent {
  const _DocumentViewModeIntent(this.mode);

  final DocumentViewModePreference mode;
}

class _NotesActionIntent extends Intent {
  const _NotesActionIntent(this.action);
  final WelcomeNotesAction action;
}

class _NotesWorkspaceActionIntent extends Intent {
  const _NotesWorkspaceActionIntent(this.commandId);
  final String commandId;
}
