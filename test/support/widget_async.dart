import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

/// Drives both Flutter's fake clock and real I/O until an observable result.
Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() complete, {
  required String operation,
  Duration timeout = const Duration(seconds: 10),
  Duration frameStep = Duration.zero,
  String Function()? diagnostics,
}) async {
  final elapsed = Stopwatch()..start();
  while (!complete()) {
    if (elapsed.elapsed >= timeout) {
      throw TimeoutException(
        '$operation did not complete. ${diagnostics?.call() ?? ''}',
      );
    }
    await tester.pump(frameStep);
    if (!complete()) {
      // Let file/isolate events run, then flush their FakeAsync continuations
      // on the next pump. Sleeping here adds latency to every I/O boundary.
      await tester.runAsync(() => Future<void>(() {}));
    }
  }
  await tester.pump();
}
