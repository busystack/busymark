import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:system_theme/system_theme.dart';
import 'package:ubuntu_localizations/ubuntu_localizations.dart';

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
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(BusyMarkRadius.window),
              ),
              clipBehavior: Clip.antiAliasWithSaveLayer,
              child: ColoredBox(
                color: BusyMarkSurfaceColors.of(context).window,
                child: child ?? const SizedBox.shrink(),
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
