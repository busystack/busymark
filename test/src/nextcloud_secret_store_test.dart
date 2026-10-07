import 'package:busymark/src/nextcloud_notes/data/notes_secret_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('busymark.test/nextcloud_credentials');
  const account = 'f85b9c8d-bc26-4cc9-920c-7f7765597f19';
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return call.method == 'read' ? ' exact password ' : null;
    });
  });
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test(
    'reads exact app password in dedicated stable account namespace',
    () async {
      const store = FlutterNextcloudSecretStore(channel: channel);
      expect(await store.read(account), ' exact password ');
      expect(calls.single.arguments, {
        'key': 'busymark.nextcloud.account-password.$account',
      });
    },
  );

  test('writes and deletes only the selected account secret', () async {
    const store = FlutterNextcloudSecretStore(channel: channel);
    await store.write(account, ' exact password ');
    expect(calls.single.arguments, {
      'key': 'busymark.nextcloud.account-password.$account',
      'value': ' exact password ',
    });
    await store.delete(account);
    expect(calls.last.method, 'delete');
    expect(calls.last.arguments, {
      'key': 'busymark.nextcloud.account-password.$account',
    });
  });

  test(
    'rejects app passwords that cannot be stored as an exact C string',
    () async {
      const store = FlutterNextcloudSecretStore(channel: channel);
      await expectLater(
        store.write(account, 'secret\u0000suffix'),
        throwsA(isA<NextcloudCredentialException>()),
      );
      expect(calls, isEmpty);
    },
  );

  test(
    'rejects caller-controlled keys and non-random UUIDs before native calls',
    () async {
      const store = FlutterNextcloudSecretStore(channel: channel);
      for (final id in [
        'openai',
        '../secret',
        '',
        'f85b9c8d-bc26-1cc9-920c-7f7765597f19',
      ]) {
        await expectLater(
          store.write(id, 'password'),
          throwsA(isA<NextcloudCredentialException>()),
        );
      }
      expect(calls, isEmpty);
    },
  );

  test('unavailable keyring fails safely without plaintext fallback', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => throw PlatformException(
        code: 'credential-store-unavailable',
        message: 'native error includes secret',
      ),
    );
    const store = FlutterNextcloudSecretStore(channel: channel);
    for (final operation in [
      () => store.read(account),
      () => store.write(account, 'password'),
      () => store.delete(account),
    ]) {
      await expectLater(
        operation(),
        throwsA(
          isA<NextcloudCredentialException>().having(
            (error) => error.message,
            'safe message',
            isNot(contains('native error')),
          ),
        ),
      );
    }
  });
}
