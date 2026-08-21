import 'package:busymark/src/ai/ai_models.dart';
import 'package:busymark/src/ai/ai_secret_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('busymark.test/secure_credentials');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return call.method == 'read' ? '  stored-secret  ' : null;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test(
    'reads the provider key through the native credential channel',
    () async {
      const store = FlutterAiSecretStore(channel: channel);

      expect(await store.read(AiProviderKind.gemini), 'stored-secret');
      expect(calls, hasLength(1));
      expect(calls.single.method, 'read');
      expect(calls.single.arguments, {
        'key': 'busymark.ai.provider-key.gemini',
      });
    },
  );

  test('trims a key before securely storing it', () async {
    const store = FlutterAiSecretStore(channel: channel);

    await store.write(AiProviderKind.openAi, '  api-key  ');

    expect(calls.single.method, 'write');
    expect(calls.single.arguments, {
      'key': 'busymark.ai.provider-key.openai',
      'value': 'api-key',
    });
  });

  test('deletes only the selected provider key', () async {
    const store = FlutterAiSecretStore(channel: channel);

    await store.delete(AiProviderKind.gemini);

    expect(calls.single.method, 'delete');
    expect(calls.single.arguments, {'key': 'busymark.ai.provider-key.gemini'});
  });

  test('surfaces the native credential-service failure', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(
        code: 'credential-store-unavailable',
        message: 'The Secret Portal is unavailable.',
      );
    });
    const store = FlutterAiSecretStore(channel: channel);

    await expectLater(
      store.write(AiProviderKind.gemini, 'api-key'),
      throwsA(
        isA<AiException>()
            .having(
              (error) => error.code,
              'code',
              AiFailureCode.invalidConfiguration,
            )
            .having(
              (error) => error.message,
              'message',
              contains('The Secret Portal is unavailable.'),
            ),
      ),
    );
  });
}
