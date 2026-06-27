import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:system_theme/system_theme.dart';
import 'package:window_manager/window_manager.dart';

import 'src/app/busymark_app.dart';
import 'package:busymark/src/app/startup_path.dart';
import 'src/app/system_accent.dart';
import 'src/platform/linux_header_bar_service.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await LinuxHeaderBarService.instance.initialize();
  await SystemTheme.accentColor.load();
  if (Platform.isLinux) {
    final accent = await const LinuxPortalAppearance().readAccentColor();
    if (accent != null) {
      SystemTheme.fallbackColor = accent;
      SystemTheme.accentColor.accent = accent;
    }
  }
  runApp(
    ProviderScope(
      overrides: [
        startupPathProvider.overrideWithValue(args.isEmpty ? null : args.first),
      ],
      child: const BusyMarkApp(),
    ),
  );
}
