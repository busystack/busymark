import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:system_theme/system_theme.dart';
import 'package:ubuntu_localizations/ubuntu_localizations.dart';

import '../workspace/workspace_controller.dart';
import '../workspace/workspace_safety.dart';
import 'app_router.dart';
import 'app_settings.dart';
import 'app_theme.dart';
import 'busymark_design.dart';
import '../platform/linux_header_bar_service.dart';

class BusyMarkApp extends ConsumerWidget {
  const BusyMarkApp({super.key});

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
                SingleActivator(LogicalKeyboardKey.keyS, control: true):
                    _SaveActiveIntent(),
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
                },
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
            );
          },
          routerConfig: router,
        );
      },
    );
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
      exportPreview: 'Export Preview',
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

class _NewMarkdownIntent extends Intent {
  const _NewMarkdownIntent();
}

class _SaveActiveIntent extends Intent {
  const _SaveActiveIntent();
}
