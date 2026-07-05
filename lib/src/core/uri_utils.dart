const _launchableExternalUriSchemes = {'http', 'https', 'mailto', 'tel'};
const _remoteResourceUriSchemes = {'http', 'https'};

Uri? parseSchemedUri(String value) {
  final uri = Uri.tryParse(value.trim());
  return uri != null && uri.hasScheme ? uri : null;
}

bool hasUriScheme(String value) => parseSchemedUri(value) != null;

bool isLaunchableExternalUriScheme(String scheme) {
  return _launchableExternalUriSchemes.contains(scheme.toLowerCase());
}

bool isLaunchableExternalUri(Uri uri) {
  return uri.hasScheme && isLaunchableExternalUriScheme(uri.scheme);
}

bool isRemoteResourceUriScheme(String scheme) {
  return _remoteResourceUriSchemes.contains(scheme.toLowerCase());
}
