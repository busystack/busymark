import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'src/app/busymark_app.dart';
import 'package:busymark/src/app/startup_path.dart';
import 'src/app/system_accent.dart';
import 'src/platform/linux_header_bar_service.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await LinuxHeaderBarService.instance.initialize();
  var initialAccent = busyMarkDefaultAccentColor;
  if (Platform.isLinux) {
    initialAccent =
        await const LinuxPortalAppearance().readAccentColor() ??
        busyMarkDefaultAccentColor;
  }
  runApp(
    ProviderScope(
      overrides: [
        startupPathProvider.overrideWithValue(args.isEmpty ? null : args.first),
        initialSystemAccentColorProvider.overrideWithValue(initialAccent),
      ],
      child: const BusyMarkApp(),
    ),
  );
}
