import 'package:busymark/src/platform/native_menu_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'show serializes native menu presentation and returns its selection',
    () async {
      const channel = MethodChannel('busymark/test/native-menu');
      MethodCall? call;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (value) async {
            call = value;
            return 2;
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });

      final session = NativeMenuSession();
      final result = await const NativeMenuService(channel: channel).show(
        session: session,
        anchor: const Rect.fromLTWH(12, 34, 56, 78),
        entries: const [
          NativeMenuEntry.command(
            label: 'Open',
            iconName: 'document-open-symbolic',
            shortcut: 'Ctrl+O',
            checkable: true,
            selected: true,
          ),
          NativeMenuEntry.separator(),
          NativeMenuEntry.command(label: 'Disabled', enabled: false),
        ],
        focusFirst: true,
        preferAbove: true,
      );

      expect(result.available, isTrue);
      expect(result.selectedIndex, 2);
      expect(call?.method, 'show');
      expect(call?.arguments, {
        'sessionId': session.id,
        'anchor': {'x': 12.0, 'y': 34.0, 'width': 56.0, 'height': 78.0},
        'entries': [
          {
            'label': 'Open',
            'icon': 'document-open-symbolic',
            'shortcut': 'Ctrl+O',
            'enabled': true,
            'checkable': true,
            'selected': true,
            'separator': false,
          },
          {
            'label': '',
            'enabled': false,
            'checkable': false,
            'selected': false,
            'separator': true,
          },
          {
            'label': 'Disabled',
            'enabled': false,
            'checkable': false,
            'selected': false,
            'separator': false,
          },
        ],
        'focusFirst': true,
        'preferredPosition': 'top',
      });
    },
  );

  test('dismiss is scoped to the native menu session', () async {
    const channel = MethodChannel('busymark/test/native-menu-dismiss');
    MethodCall? call;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (value) async {
          call = value;
          return true;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    final session = NativeMenuSession();
    final dismissed = await const NativeMenuService(
      channel: channel,
    ).dismiss(session);

    expect(dismissed, isTrue);
    expect(call?.method, 'dismiss');
    expect(call?.arguments, {'sessionId': session.id});
  });

  test(
    'missing native host reports unavailable for a themed fallback',
    () async {
      const channel = MethodChannel('busymark/test/native-menu-missing');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (_) async => throw MissingPluginException(),
          );
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });

      final result = await const NativeMenuService(channel: channel).show(
        session: NativeMenuSession(),
        anchor: Rect.zero,
        entries: const [NativeMenuEntry.command(label: 'Fallback')],
      );

      expect(result.available, isFalse);
      expect(result.selectedIndex, isNull);
    },
  );
}
