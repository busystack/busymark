import 'dart:io';

import 'package:busymark/src/platform/linux_header_bar_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'always-on-top retries native channel initialization after early miss',
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
              return false;
            }
            if (call.method == 'setAlwaysOnTop') {
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
      final applied = await service.setAlwaysOnTop(true);

      expect(calls, ['initialize', 'initialize', 'setAlwaysOnTop']);
      expect(applied, isTrue);
    },
  );

  test('always-on-top reports unsupported native response', () async {
    if (!Platform.isLinux) {
      return;
    }
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('com.busymark.test/headerbar-unsupported');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'initialize') {
            return false;
          }
          if (call.method == 'setAlwaysOnTop') {
            return false;
          }
          return null;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    final service = LinuxHeaderBarService(channel: channel);

    expect(await service.setAlwaysOnTop(true), isFalse);
  });

  test('always-on-top support is reported by native channel', () async {
    if (!Platform.isLinux) {
      return;
    }
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('com.busymark.test/headerbar-support');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'initialize') {
            return false;
          }
          if (call.method == 'isAlwaysOnTopSupported') {
            return false;
          }
          return null;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    final service = LinuxHeaderBarService(channel: channel);

    expect(await service.isAlwaysOnTopSupported(), isFalse);
  });
}
