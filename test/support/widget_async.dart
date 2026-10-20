import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

/// Drives both Flutter's fake clock and real I/O until an observable result.
Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() complete, {
  required String operation,
  Duration timeout = const Duration(seconds: 10),
  Duration frameStep = const Duration(milliseconds: 1),
  String Function()? diagnostics,
}) async {
  final elapsed = Stopwatch()..start();

  while (!complete()) {
    if (elapsed.elapsed >= timeout) {
      throw TimeoutException(
        '$operation did not complete. deadline exceeded. '
        '${diagnostics?.call() ?? ''}',
      );
    }
    await tester.pump(frameStep);
    if (!complete()) {
      // Advance both clocks: retry/debounce timers may belong to FakeAsync,
      // while filesystem/isolate completions need a real event-loop yield.
      // A zero-delay busy loop burns CPU across parallel test processes and
      // can exhaust a wall-clock deadline without servicing either properly.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 1)),
      );
    }
  }
  await tester.pump();
}
