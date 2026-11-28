import 'package:flutter/services.dart';

import '../ai/ai_models.dart' show AiProviderKind;
import '../ai/ai_secret_store.dart';
import 'speech_provider.dart';

class SpeechCredentials {
  const SpeechCredentials({
    AiSecretStore aiStore = const FlutterAiSecretStore(),
  }) : _aiStore = aiStore;

  static const _channel = MethodChannel('com.busymark.app/secure_credentials');
  static const _elevenLabsKey = 'busymark.speech.provider-key.elevenlabs';
  final AiSecretStore _aiStore;

  AiProviderKind? _aiProvider(SpeechBackend backend) => switch (backend) {
    SpeechBackend.openai => AiProviderKind.openAi,
    SpeechBackend.gemini => AiProviderKind.gemini,
    _ => null,
  };

  Future<String?> read(SpeechBackend backend) async {
    final aiProvider = _aiProvider(backend);
    if (aiProvider != null) return _aiStore.read(aiProvider);
    final key = (await _invoke<String>(backend, 'read'))?.trim();
    return key == null || key.isEmpty ? null : key;
  }

  Future<void> write(SpeechBackend backend, String secret) async {
    final aiProvider = _aiProvider(backend);
    final value = secret.trim();
    if (value.isEmpty || value.contains(RegExp(r'[\x00-\x1f\x7f]'))) {
      throw const AiCredentialException(
        AiCredentialIssue.invalidKey,
        'Enter a valid speech API key.',
      );
    }
    if (aiProvider != null) return _aiStore.write(aiProvider, value);
    await _invoke<void>(backend, 'write', value);
  }

  Future<void> delete(SpeechBackend backend) async {
    final aiProvider = _aiProvider(backend);
    if (aiProvider != null) return _aiStore.delete(aiProvider);
    await _invoke<void>(backend, 'delete');
  }

  Future<T?> _invoke<T>(
    SpeechBackend backend,
    String method, [
    String? value,
  ]) async {
    if (backend != SpeechBackend.elevenLabs) {
      throw ArgumentError.value(
        backend,
        'backend',
        'No provider key is needed.',
      );
    }
    try {
      return await _channel.invokeMethod<T>(method, {
        'key': _elevenLabsKey,
        if (value != null) 'value': value,
      });
    } on Object {
      throw const AiCredentialException(
        AiCredentialIssue.storeUnavailable,
        'BusyMark could not access the secure credential service.',
      );
    }
  }
}
