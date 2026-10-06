import 'dart:convert';

import 'package:flutter/services.dart';

abstract interface class NextcloudSecretStore {
  Future<String?> read(String accountId);
  Future<void> write(String accountId, String appPassword);
  Future<void> delete(String accountId);
}

class NextcloudCredentialException implements Exception {
  const NextcloudCredentialException(this.message);
  final String message;
  @override
  String toString() => message;
}

class FlutterNextcloudSecretStore implements NextcloudSecretStore {
  const FlutterNextcloudSecretStore({MethodChannel channel = _defaultChannel})
    : _channel = channel;

  static const _defaultChannel = MethodChannel(
    'com.busymark.app/secure_credentials',
  );
  static final _accountId = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );
  final MethodChannel _channel;

  static String credentialKey(String accountId) {
    if (!_accountId.hasMatch(accountId)) {
      throw const NextcloudCredentialException(
        'The Nextcloud account identifier is invalid.',
      );
    }
    return 'busymark.nextcloud.account-password.$accountId';
  }

  @override
  Future<String?> read(String accountId) async {
    final key = credentialKey(accountId);
    try {
      final secret = await _channel.invokeMethod<String>('read', {'key': key});
      return secret == null || secret.isEmpty ? null : secret;
    } on Object {
      throw const NextcloudCredentialException(
        'BusyMark could not access the desktop keyring. Unlock the keyring and reconnect Nextcloud.',
      );
    }
  }

  @override
  Future<void> write(String accountId, String appPassword) async {
    final key = credentialKey(accountId);
    if (appPassword.isEmpty ||
        appPassword.contains('\u0000') ||
        utf8.encode(appPassword).length > 16384) {
      throw const NextcloudCredentialException(
        'The Nextcloud app password is invalid.',
      );
    }
    try {
      await _channel.invokeMethod<void>('write', {
        'key': key,
        'value': appPassword,
      });
    } on Object {
      throw const NextcloudCredentialException(
        'BusyMark could not save the Nextcloud app password in the desktop keyring. Unlock the keyring and try again.',
      );
    }
  }

  @override
  Future<void> delete(String accountId) async {
    final key = credentialKey(accountId);
    try {
      await _channel.invokeMethod<void>('delete', {'key': key});
    } on Object {
      throw const NextcloudCredentialException(
        'BusyMark could not remove the Nextcloud app password from the desktop keyring. Unlock the keyring and try again.',
      );
    }
  }
}
