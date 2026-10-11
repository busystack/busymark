/// Validates a Nextcloud installation URL without losing its path prefix.
Uri normalizeNextcloudServer(String input) {
  final value = input.trim();
  final rawPath = RegExp(
    r'^https?://[^/?#]+([^?#]*)',
    caseSensitive: false,
  ).firstMatch(value)?.group(1);
  // Uri.parse removes literal dot segments. Validate the original path before
  // that normalization so a supplied installation prefix cannot move upwards.
  if (rawPath != null &&
      rawPath.split('/').any((part) {
        final decoded = Uri.decodeComponent(
          part.replaceAllMapped(
            RegExp(r'[^\x00-\x7f]+'),
            (m) => Uri.encodeComponent(m[0]!),
          ),
        );
        return decoded == '.' || decoded == '..';
      })) {
    throw const FormatException('Enter a valid HTTPS Nextcloud server URL.');
  }
  final uri = Uri.tryParse(value);
  if (uri == null ||
      !uri.hasAuthority ||
      uri.scheme != 'https' ||
      uri.host.isEmpty ||
      uri.port < 1 ||
      uri.port > 65535 ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment ||
      value.contains(RegExp(r'[\x00-\x20\\]')) ||
      uri.pathSegments.any(
        (part) =>
            part == '.' ||
            part == '..' ||
            part.contains('/') ||
            part.contains('\\') ||
            part.contains(RegExp(r'[\x00-\x1f\x7f]')),
      )) {
    throw const FormatException('Enter a valid HTTPS Nextcloud server URL.');
  }
  // Preserve the installation prefix. Production never permits plaintext auth.
  final path = uri.path.replaceFirst(RegExp(r'/+$'), '');
  return uri.replace(path: path);
}

/// Appends a provider-owned route to an installation URL, including its prefix.
Uri nextcloudEndpoint(
  Uri server,
  String relativePath, {
  Map<String, String>? queryParameters,
}) {
  final base = normalizeNextcloudServer(server.toString());
  if (relativePath.isEmpty ||
      relativePath.startsWith('/') ||
      relativePath.contains('\\') ||
      relativePath.contains('?') ||
      relativePath.contains('#') ||
      relativePath.split('/').any((part) => part == '.' || part == '..')) {
    throw const FormatException('Invalid Nextcloud API route.');
  }
  return base.replace(
    path: '${base.path}/$relativePath',
    queryParameters: queryParameters,
  );
}

bool nextcloudSameOrigin(Uri first, Uri second) =>
    first.scheme == second.scheme &&
    first.host.toLowerCase() == second.host.toLowerCase() &&
    first.port == second.port;

/// Portable web navigation, independent of title/category and local database IDs.
Uri nextcloudNoteUrl(Uri server, int serverId, {bool pretty = false}) {
  if (serverId <= 0) throw ArgumentError.value(serverId, 'serverId');
  return nextcloudEndpoint(
    server,
    '${pretty ? '' : 'index.php/'}apps/notes/note/$serverId',
  );
}

/// Recognizes only this exact installation, with front-controller or pretty URLs.
int? nextcloudNoteId(Uri server, String destination) {
  try {
    final base = normalizeNextcloudServer(server.toString());
    final uri = Uri.tryParse(destination);
    if (uri == null ||
        !uri.hasAuthority ||
        !nextcloudSameOrigin(base, uri) ||
        uri.userInfo.isNotEmpty ||
        destination.contains(RegExp(r'[\x00-\x20\\]'))) {
      return null;
    }
    // Match the encoded path exactly: encoded separators, dot normalization,
    // misleading installation prefixes and route suffixes never alias a note.
    final rawPath = RegExp(
      r'^https://[^/?#]+([^?#]*)',
      caseSensitive: false,
    ).firstMatch(destination)?.group(1);
    if (rawPath == null || rawPath != uri.path) return null;
    for (final route in ['index.php/apps/notes/note/', 'apps/notes/note/']) {
      final prefix = '${base.path}/$route';
      if (!rawPath.startsWith(prefix)) continue;
      final suffix = rawPath.substring(prefix.length);
      if (!RegExp(r'^[1-9][0-9]*$').hasMatch(suffix)) return null;
      return int.tryParse(suffix);
    }
  } on FormatException {
    return null;
  }
  return null;
}

/// Validates a flow URL before sending its token or opening the browser.
Uri nextcloudFlowEndpoint(Uri server, Object? value) {
  if (value is! String) {
    throw const FormatException('The server returned an invalid login URL.');
  }
  normalizeNextcloudServer(server.toString());
  final uri = Uri.tryParse(value);
  if (uri == null ||
      !uri.hasAuthority ||
      !nextcloudSameOrigin(server, uri) ||
      uri.userInfo.isNotEmpty ||
      uri.hasFragment ||
      value.contains(RegExp(r'[\x00-\x20\\]'))) {
    throw const FormatException('The server returned an unsafe login URL.');
  }
  return uri;
}
