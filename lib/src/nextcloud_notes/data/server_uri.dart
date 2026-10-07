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
        final decoded = Uri.decodeComponent(part);
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
