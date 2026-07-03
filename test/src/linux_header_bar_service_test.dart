import 'dart:io';

import 'package:busymark/src/platform/linux_header_bar_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'headerbar update retries native channel initialization after early miss',
    () async {
      if (!Platform.isLinux) {
        return;
      }
      TestWidgetsFlutterBinding.ensureInitialized();
      const channel = MethodChannel('com.busymark.test/headerbar-retry');
      final calls = <String>[];
      var initializeAttempts = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call.method);
            if (call.method == 'initialize') {
              initializeAttempts++;
              if (initializeAttempts == 1) {
                throw MissingPluginException();
              }
              return true;
            }
            return null;
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });

      final service = LinuxHeaderBarService(channel: channel);

      await service.initialize();
      await service.setSidebarVisible(false);

      expect(calls, ['initialize', 'initialize', 'setSidebarVisible']);
    },
  );

  test('headerbar forwards text direction updates', () async {
    if (!Platform.isLinux) {
      return;
    }
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('com.busymark.test/headerbar-direction');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'initialize') {
            return true;
          }
          return null;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    final service = LinuxHeaderBarService(channel: channel);

    await service.setTextDirection(TextDirection.rtl);

    expect(calls.map((call) => call.method), [
      'initialize',
      'setTextDirection',
    ]);
    expect(calls.last.arguments, 'rtl');
  });

  test('headerbar action events preserve repeated identical clicks', () async {
    if (!Platform.isLinux) {
      return;
    }
    TestWidgetsFlutterBinding.ensureInitialized();
    const channelName = 'com.busymark.test/headerbar-events';
    const channel = MethodChannel(channelName);
    const codec = StandardMethodCodec();
    final service = LinuxHeaderBarService(channel: channel);
    final events = <HeaderBarActionEvent>[];
    final subscription = service.actionEvents.listen(events.add);

    addTearDown(() async {
      await subscription.cancel();
      channel.setMethodCallHandler(null);
    });

    Future<void> sendNativeAction(String method) {
      return TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            channelName,
            codec.encodeMethodCall(MethodCall(method)),
            (_) {},
          );
    }

    await sendNativeAction('save');
    await sendNativeAction('save');

    expect(events.map((event) => event.action), [
      HeaderBarAction.save,
      HeaderBarAction.save,
    ]);
    expect(events.map((event) => event.sequence), [1, 2]);
    expect(events.first, isNot(events.last));
  });
}
