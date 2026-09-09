import 'dart:async';

import 'package:busymark/src/platform/native_menu_service.dart';
import 'package:busymark/src/platform/rich_clipboard_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(nativeMenuChannelName);
  const clipboardChannel = MethodChannel(richClipboardChannelName);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  setUp(() {
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => throw MissingPluginException(),
    );
    messenger.setMockMethodCallHandler(
      clipboardChannel,
      (_) async => throw MissingPluginException(),
    );
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    messenger.setMockMethodCallHandler(clipboardChannel, null);
  });
  await testMain();
}
