import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:busymark/src/app/app_router.dart';
import 'package:busymark/src/app/busymark_app.dart';
import 'package:busymark/src/app/command_registry.dart';
import 'package:busymark/src/git/application/shared_git_integration.dart';
import 'package:busymark/src/local_history/local_history_controller.dart';
import 'package:busymark/main.dart' as application;

Future<void> main(List<String> args) async {
  print('FOLLOWUP ARGS $args');
  WidgetsFlutterBinding.ensureInitialized();
  HardwareKeyboard.instance.addHandler((event) {
    print(
      'FOLLOWUP KEY $event ctrl=${HardwareKeyboard.instance.isControlPressed} '
      'shift=${HardwareKeyboard.instance.isShiftPressed} '
      'focus=${FocusManager.instance.primaryFocus}',
    );
    if (event.logicalKey == LogicalKeyboardKey.tab && event is KeyDownEvent) {
      final context = rootNavigatorKey.currentContext;
      if (context != null) {
        final container = ProviderScope.containerOf(context, listen: false);
        final commands = container.read(busyMarkCommandRegistryProvider);
        print(
          'FOLLOWUP ROUTE next=${commands[BusyMarkCommandIds.nextTab]?.canExecute} '
          'matches=${commands.shortcutAccepts(BusyMarkCommandIds.nextTab, event, HardwareKeyboard.instance)} '
          'action=${Actions.maybeFind<BusyMarkCommandIntent>(context)} '
          'alt=${HardwareKeyboard.instance.isAltPressed} meta=${HardwareKeyboard.instance.isMetaPressed}',
        );
        Future<void>.delayed(const Duration(milliseconds: 300), () {
          print(
            'FOLLOWUP TABS ${container.read(sharedGitReviewProvider).map((key, value) => MapEntry(key, value.activeId))} '
            'history=${container.read(localHistoryControllerProvider).selectedRevisionId}',
          );
        });
      }
    }
    return false;
  });
  await application.main(args);
}
