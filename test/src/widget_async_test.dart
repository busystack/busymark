import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import '../support/widget_async.dart';

void main() {
  testWidgets('I/O polling also services fake-clock retry timers', (
    tester,
  ) async {
    var completed = false;
    final timer = Timer(
      const Duration(milliseconds: 25),
      () => completed = true,
    );
    addTearDown(timer.cancel);
    await pumpUntil(tester, () => completed, operation: 'delayed retry');
    expect(completed, isTrue);
  });
}
