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
    await sendNativeAction('reportIssue');
    await sendNativeAction('sidebarFiles');
    await sendNativeAction('sidebarToc');
    await sendNativeAction('sidebarOutline');
    await sendNativeAction('sidebarGit');
    await sendNativeAction('sidebarHistory');

    expect(events.map((event) => event.action), [
      HeaderBarAction.save,
      HeaderBarAction.save,
      HeaderBarAction.reportIssue,
      HeaderBarAction.sidebarFiles,
      HeaderBarAction.sidebarToc,
      HeaderBarAction.sidebarOutline,
      HeaderBarAction.sidebarGit,
      HeaderBarAction.sidebarHistory,
    ]);
    expect(events.map((event) => event.sequence), [1, 2, 3, 4, 5, 6, 7, 8]);
    expect(events.first, isNot(events.last));
  });

  test(
    'native search events and focus request keep semantic meaning',
    () async {
      if (!Platform.isLinux) {
        return;
      }
      TestWidgetsFlutterBinding.ensureInitialized();
      const channelName = 'com.busymark.test/headerbar-search-events';
      const channel = MethodChannel(channelName);
      const codec = StandardMethodCodec();
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return switch (call.method) {
              'initialize' || 'focusSearch' => true,
              _ => null,
            };
          });
      final service = LinuxHeaderBarService(channel: channel);
      final events = <HeaderBarSearchEvent>[];
      final subscription = service.searchEvents.listen(events.add);

      addTearDown(() async {
        await subscription.cancel();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
        channel.setMethodCallHandler(null);
      });

      Future<void> sendNativeEvent(String method, [Object? arguments]) {
        return TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
              channelName,
              codec.encodeMethodCall(MethodCall(method, arguments)),
              (_) {},
            );
      }

      expect(await service.focusSearch(), isTrue);
      expect(calls.map((call) => call.method), ['initialize', 'focusSearch']);

      await sendNativeEvent('searchQueryChanged', 'draft');
      await sendNativeEvent('searchSubmitted', 'draft');
      await sendNativeEvent('searchFocusChanged', true);
      await sendNativeEvent('searchCleared');
      await sendNativeEvent('searchEscapePressed');

      expect(events, hasLength(5));
      expect((events[0] as HeaderBarSearchQueryChanged).query, 'draft');
      expect((events[1] as HeaderBarSearchSubmitted).query, 'draft');
      expect((events[2] as HeaderBarSearchFocusChanged).focused, isTrue);
      expect(events[3], isA<HeaderBarSearchCleared>());
      expect(events[4], isA<HeaderBarSearchEscapePressed>());
    },
  );
}
