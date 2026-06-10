import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:system_theme/system_theme.dart';

import 'src/app/busymark_app.dart';
import 'src/platform/linux_header_bar_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LinuxHeaderBarService.instance.initialize();
  await SystemTheme.accentColor.load();
  runApp(const ProviderScope(child: BusyMarkApp()));
}
