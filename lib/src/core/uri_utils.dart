const _blockedExternalUriSchemes = {'javascript', 'data', 'vbscript'};

Uri? parseSchemedUri(String value) {
  final uri = Uri.tryParse(value.trim());
  return uri != null && uri.hasScheme ? uri : null;
}

bool hasUriScheme(String value) => parseSchemedUri(value) != null;

bool isBlockedExternalUriScheme(String scheme) {
  return _blockedExternalUriSchemes.contains(scheme.toLowerCase());
}

bool isLaunchableExternalUri(Uri uri) {
  return uri.hasScheme && !isBlockedExternalUriScheme(uri.scheme);
}
