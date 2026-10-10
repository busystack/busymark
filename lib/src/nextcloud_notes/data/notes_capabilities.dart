import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'server_uri.dart';
import 'notes_api_client.dart' show retryAfter;

enum NextcloudCapabilityFailure {
  unsupported,
  unauthorized,
  malformed,
  network,
  rejected,
  forbidden,
  throttled,
}

class NextcloudCapabilityException implements Exception {
  const NextcloudCapabilityException(
    this.code,
    this.message, {
    this.statusCode,
    this.retryNotBefore,
  });
  final NextcloudCapabilityFailure code;
  final String message;
  final int? statusCode;
  final DateTime? retryNotBefore;
  @override
  String toString() => message;
}

class NotesCapabilities {
  const NotesCapabilities({required this.appVersion, required this.apiVersion});
  final String appVersion;
  final String apiVersion;

  factory NotesCapabilities.fromOcsJson(Map<String, dynamic> json) {
    final ocs = json['ocs'];
    if (ocs is! Map || ocs['data'] is! Map) {
      throw const NextcloudCapabilityException(
        NextcloudCapabilityFailure.malformed,
        'The Nextcloud server returned invalid capabilities.',
      );
    }
    final meta = ocs['meta'];
    if (meta is! Map || ![100, 200].contains(meta['statuscode'])) {
      throw const NextcloudCapabilityException(
        NextcloudCapabilityFailure.malformed,
        'The Nextcloud server did not return successful capabilities.',
      );
    }
    final capabilities = (ocs['data'] as Map)['capabilities'];
    final notes = capabilities is Map ? capabilities['notes'] : null;
    if (notes is! Map) {
      throw const NextcloudCapabilityException(
        NextcloudCapabilityFailure.unsupported,
        'The Notes app is unavailable on this Nextcloud server. BusyMark requires Notes API 1.4 or later in major version 1.',
      );
    }
    final version = notes['version'];
    final versions = notes['api_version'];
    if (versions is! List ||
        (versions.isNotEmpty &&
            !versions.any(
              (v) => v is String && RegExp(r'^\d+\.\d+$').hasMatch(v.trim()),
            ))) {
      throw const NextcloudCapabilityException(
        NextcloudCapabilityFailure.malformed,
        'The Nextcloud server returned invalid Notes API versions.',
      );
    }
    final supported = parseNotesApiVersions(versions);
    if (supported == null) {
      throw const NextcloudCapabilityException(
        NextcloudCapabilityFailure.unsupported,
        'This Nextcloud Notes API is unsupported. BusyMark requires Notes API major version 1 with minor version 4 or later.',
      );
    }
    return NotesCapabilities(
      appVersion: version is String ? version : '',
      apiVersion: supported,
    );
  }
}

/// Shared OCS/header boundary. Application versions are separate evidence.
String? parseNotesApiVersions(Iterable<dynamic> versions) {
  final minors = <int>[];
  for (final version in versions) {
    if (version is! String) continue;
    final match = RegExp(r'^1\.(\d+)$').firstMatch(version.trim());
    final minor = match == null ? null : int.tryParse(match.group(1)!);
    if (minor != null && minor >= 4) minors.add(minor);
  }
  if (minors.isEmpty) return null;
  minors.sort();
  return '1.${minors.last}';
}

String nextcloudAuthorization(String loginName, String appPassword) =>
    'Basic ${base64Encode(utf8.encode('$loginName:$appPassword'))}';

Future<NotesCapabilities> fetchNotesCapabilities({
  required http.Client client,
  required Uri server,
  required String loginName,
  required String appPassword,
}) async {
  final request =
      http.Request(
          'GET',
          nextcloudEndpoint(
            server,
            'ocs/v2.php/cloud/capabilities',
            queryParameters: {'format': 'json'},
          ),
        )
        ..followRedirects = false
        ..headers.addAll({
          'Accept': 'application/json',
          'OCS-APIRequest': 'true',
          'User-Agent': 'BusyMark Nextcloud Notes',
          'Authorization': nextcloudAuthorization(loginName, appPassword),
        });
  http.Response response;
  try {
    response = await http.Response.fromStream(
      await client.send(request).timeout(const Duration(seconds: 30)),
    ).timeout(const Duration(seconds: 30));
  } on TimeoutException {
    throw const NextcloudCapabilityException(
      NextcloudCapabilityFailure.network,
      'The Nextcloud capabilities request timed out.',
    );
  } on IOException {
    throw const NextcloudCapabilityException(
      NextcloudCapabilityFailure.network,
      'The Nextcloud capabilities endpoint is unreachable.',
    );
  } on http.ClientException {
    throw const NextcloudCapabilityException(
      NextcloudCapabilityFailure.network,
      'BusyMark could not verify the Nextcloud Notes capabilities. Check your connection and try again.',
    );
  }
  if (response.statusCode == 401) {
    throw const NextcloudCapabilityException(
      NextcloudCapabilityFailure.unauthorized,
      'Nextcloud rejected the app password. Reconnect to authorize BusyMark again.',
    );
  }
  if (response.statusCode >= 300 && response.statusCode < 400) {
    throw const NextcloudCapabilityException(
      NextcloudCapabilityFailure.malformed,
      'The Nextcloud capabilities endpoint redirected. Reconnect using the canonical server URL.',
    );
  }
  if (response.statusCode == 429) {
    final value = response.headers.entries
        .where((e) => e.key.toLowerCase() == 'retry-after')
        .firstOrNull
        ?.value;
    throw NextcloudCapabilityException(
      NextcloudCapabilityFailure.throttled,
      'Nextcloud requested a pause before checking capabilities.',
      statusCode: 429,
      retryNotBefore: retryAfter(value, DateTime.now()),
    );
  }
  if (response.statusCode == 403) {
    throw const NextcloudCapabilityException(
      NextcloudCapabilityFailure.forbidden,
      'Nextcloud does not permit capability checks.',
      statusCode: 403,
    );
  }
  if (response.statusCode >= 400 && response.statusCode < 500) {
    throw NextcloudCapabilityException(
      NextcloudCapabilityFailure.rejected,
      'The capability endpoint rejected the request (HTTP ${response.statusCode}).',
      statusCode: response.statusCode,
    );
  }
  if (response.statusCode != 200) {
    throw const NextcloudCapabilityException(
      NextcloudCapabilityFailure.network,
      'The Nextcloud server could not provide Notes capabilities. Try again later.',
    );
  }
  try {
    final json = jsonDecode(response.body);
    if (json is! Map<String, dynamic>) throw const FormatException();
    return NotesCapabilities.fromOcsJson(json);
  } on NextcloudCapabilityException {
    rethrow;
  } on FormatException {
    throw const NextcloudCapabilityException(
      NextcloudCapabilityFailure.malformed,
      'The Nextcloud server returned invalid capabilities.',
    );
  }
}

/// The developer manual explicitly permits local removal if revocation fails.
Future<bool> revokeNextcloudAppPassword({
  required http.Client client,
  required Uri server,
  required String loginName,
  required String appPassword,
}) async {
  final request =
      http.Request(
          'DELETE',
          nextcloudEndpoint(server, 'ocs/v2.php/core/apppassword'),
        )
        ..followRedirects = false
        ..headers.addAll({
          'Accept': 'application/json',
          'OCS-APIRequest': 'true',
          'Authorization': nextcloudAuthorization(loginName, appPassword),
        });
  try {
    final response = await client
        .send(request)
        .timeout(const Duration(seconds: 10));
    await response.stream.drain<void>().timeout(const Duration(seconds: 10));
    return response.statusCode == 200;
  } on Object {
    return false;
  }
}
