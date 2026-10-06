import 'dart:convert';

import 'package:http/http.dart' as http;

import 'server_uri.dart';

enum NextcloudCapabilityFailure {
  unsupported,
  unauthorized,
  malformed,
  network,
}

class NextcloudCapabilityException implements Exception {
  const NextcloudCapabilityException(this.code, this.message);
  final NextcloudCapabilityFailure code;
  final String message;
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
    final minors = <int>[];
    if (versions is List) {
      for (final advertised in versions) {
        if (advertised is! String) continue;
        final match = RegExp(r'^1\.(\d+)$').firstMatch(advertised);
        final minor = match == null ? null : int.tryParse(match.group(1)!);
        if (minor != null && minor >= 4) minors.add(minor);
      }
    }
    if (minors.isEmpty) {
      throw const NextcloudCapabilityException(
        NextcloudCapabilityFailure.unsupported,
        'This Nextcloud Notes API is unsupported. BusyMark requires Notes API major version 1 with minor version 4 or later.',
      );
    }
    minors.sort();
    return NotesCapabilities(
      appVersion: version is String ? version : '',
      apiVersion: '1.${minors.last}',
    );
  }
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
  } on Object {
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
  if (response.statusCode != 200) {
    throw const NextcloudCapabilityException(
      NextcloudCapabilityFailure.network,
      'The Nextcloud server could not provide Notes capabilities. Try again later.',
    );
  }
  try {
    return NotesCapabilities.fromOcsJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  } on NextcloudCapabilityException {
    rethrow;
  } on Object {
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
