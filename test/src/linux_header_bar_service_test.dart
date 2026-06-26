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
}
