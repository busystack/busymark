import 'package:flutter/services.dart';

import 'ai_models.dart';

abstract interface class AiSecretStore {
  Future<String?> read(AiProviderKind provider);
  Future<void> write(AiProviderKind provider, String secret);
  Future<void> delete(AiProviderKind provider);
}

class FlutterAiSecretStore implements AiSecretStore {
  const FlutterAiSecretStore({MethodChannel channel = _defaultChannel})
    : _channel = channel;

  static const _prefix = 'busymark.ai.provider-key.';
  static const _defaultChannel = MethodChannel(
    'com.busymark.app/secure_credentials',
  );

  final MethodChannel _channel;

  @override
  Future<String?> read(AiProviderKind provider) async {
    try {
      final value = await _channel.invokeMethod<String>('read', {
        'key': _key(provider),
      });
      final normalized = value?.trim() ?? '';
      return normalized.isEmpty ? null : normalized;
    } on Object catch (error) {
      throw AiException(
        AiFailureCode.invalidConfiguration,
        _failureMessage('BusyMark could not access secure credentials.', error),
      );
    }
  }

  @override
  Future<void> write(AiProviderKind provider, String secret) async {
    final normalized = secret.trim();
    if (normalized.isEmpty) {
      throw const AiException(
        AiFailureCode.invalidConfiguration,
        'Enter an API key first.',
      );
    }
    try {
      await _channel.invokeMethod<void>('write', {
        'key': _key(provider),
        'value': normalized,
      });
    } on Object catch (error) {
      throw AiException(
        AiFailureCode.invalidConfiguration,
        _failureMessage('BusyMark could not save the API key securely.', error),
      );
    }
  }

  @override
  Future<void> delete(AiProviderKind provider) async {
    try {
      await _channel.invokeMethod<void>('delete', {'key': _key(provider)});
    } on Object catch (error) {
      throw AiException(
        AiFailureCode.invalidConfiguration,
        _failureMessage(
          'BusyMark could not remove the securely stored API key.',
          error,
        ),
      );
    }
  }

  String _key(AiProviderKind provider) => '$_prefix${provider.id}';

  static String _failureMessage(String summary, Object error) {
    if (error case PlatformException(message: final message?)) {
      final normalized = message.trim();
      if (normalized.isNotEmpty) {
        return '$summary $normalized';
      }
    }
    return summary;
  }
}
