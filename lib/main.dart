import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:yaru/yaru.dart';

import 'src/app/busymark_app.dart';
import 'src/app/startup_path.dart';
import 'src/app/system_accent.dart';
import 'src/git/application/git_controller.dart';
import 'src/git/data/git_cli_gateway.dart';
import 'src/platform/gtk_animation_settings_service.dart';
import 'src/platform/gtk_window_preferences_service.dart';
import 'src/platform/gtk_header_icon_service.dart';
import 'src/platform/linux_gtk_accent_service.dart';
import 'src/spellcheck/spelling_release_smoke.dart';
import 'src/visualization/visualization_release_smoke.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  if (Platform.isLinux) await YaruWindow.ensureInitialized();
  if (visualizationReleaseSmokeReportPath(args) case final reportPath?) {
    exit(await runVisualizationReleaseSmoke(reportPath));
  }
  if (spellingReleaseSmokeReportPath(args) case final reportPath?) {
    exit(await runSpellingReleaseSmoke(reportPath));
  }
  final accentCoordinator = LinuxAccentCoordinator(
    sources: Platform.isLinux
        ? [const LinuxGtkAccentService(), const LinuxPortalAppearance()]
        : [],
  );
  await accentCoordinator.initialize();
  final chrome = await Future.wait<Object?>([
    const GtkAnimationSettingsService().getAnimationsEnabled(),
    const GtkWindowPreferencesService().load(),
  ]);
  final headerIcons = GtkHeaderIconService();
  await headerIcons.initialize();
  runApp(
    ProviderScope(
      overrides: [
        initialGtkAnimationsEnabledProvider.overrideWithValue(
          chrome[0] as bool?,
        ),
        initialGtkWindowPreferencesProvider.overrideWithValue(
          chrome[1] as GtkWindowPreferences?,
        ),
        gtkHeaderIconServiceProvider.overrideWith((ref) {
          ref.onDispose(headerIcons.dispose);
          return headerIcons;
        }),
        startupPathProvider.overrideWithValue(args.isEmpty ? null : args.first),
        initialSystemAccentColorProvider.overrideWithValue(
          accentCoordinator.color,
        ),
        linuxAccentCoordinatorProvider.overrideWith((ref) {
          ref.onDispose(() => unawaited(accentCoordinator.dispose()));
          return accentCoordinator;
        }),
        gitRepositoryGatewayProvider.overrideWithValue(const GitCliGateway()),
      ],
      child: const BusyMarkApp(),
    ),
  );
}
