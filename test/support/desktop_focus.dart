import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Exercise the desktop FocusManager, including in bindings created before the
/// test's platform override. Never replace this with an explicit requestFocus.
void enableDesktopFocusLifecycle(WidgetTester tester) {
  expect(defaultTargetPlatform, TargetPlatform.linux);
  // ignore: invalid_use_of_visible_for_testing_member
  FocusManager.instance.listenToApplicationLifecycleChangesIfSupported();
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
}

Future<void> pumpDesktopFocusCycle(
  WidgetTester tester, {
  required FocusNode target,
  int inactiveFrames = 1,
  required VoidCallback verifyViewport,
}) async {
  expect(FocusManager.instance.primaryFocus, same(target));
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  expect(
    FocusManager.instance.primaryFocus,
    same(FocusManager.instance.rootScope),
  );
  for (var frame = 0; frame < inactiveFrames; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
    verifyViewport();
  }
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  for (var frame = 0; frame < 30; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
    verifyViewport();
  }
  expect(FocusManager.instance.primaryFocus, same(target));
  expect(tester.testTextInput.hasAnyClients, isTrue);
}
