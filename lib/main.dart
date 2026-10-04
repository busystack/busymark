import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'src/app/busymark_app.dart';
import 'src/app/startup_path.dart';
import 'src/app/system_accent.dart';
import 'src/git/application/git_controller.dart';
import 'src/git/data/git_cli_gateway.dart';
import 'src/platform/linux_header_bar_service.dart';
import 'src/platform/linux_gtk_accent_service.dart';
import 'src/spellcheck/spelling_release_smoke.dart';
import 'src/visualization/visualization_release_smoke.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await LinuxHeaderBarService.instance.initialize();
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
  runApp(
    ProviderScope(
      overrides: [
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
