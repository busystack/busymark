import 'dart:async';

import 'package:busymark/src/platform/native_menu_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(nativeMenuChannelName);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  setUp(() {
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => throw MissingPluginException(),
    );
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });
  await testMain();
}
