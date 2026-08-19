import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'ai_models.dart';

abstract interface class AiSecretStore {
  Future<String?> read(AiProviderKind provider);
  Future<void> write(AiProviderKind provider, String secret);
  Future<void> delete(AiProviderKind provider);
}

class FlutterAiSecretStore implements AiSecretStore {
  const FlutterAiSecretStore({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  static const _prefix = 'busymark.ai.provider-key.';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(AiProviderKind provider) async {
    try {
      final value = await _storage.read(key: _key(provider));
      final normalized = value?.trim() ?? '';
      return normalized.isEmpty ? null : normalized;
    } on Object {
      throw const AiException(
        AiFailureCode.invalidConfiguration,
        'BusyMark could not access the system credential store.',
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
      await _storage.write(key: _key(provider), value: normalized);
    } on Object {
      throw const AiException(
        AiFailureCode.invalidConfiguration,
        'BusyMark could not save the API key in the system credential store.',
      );
    }
  }

  @override
  Future<void> delete(AiProviderKind provider) async {
    try {
      await _storage.delete(key: _key(provider));
    } on Object {
      throw const AiException(
        AiFailureCode.invalidConfiguration,
        'BusyMark could not remove the API key from the system credential store.',
      );
    }
  }

  String _key(AiProviderKind provider) => '$_prefix${provider.id}';
}
