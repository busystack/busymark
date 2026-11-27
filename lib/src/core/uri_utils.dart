const _launchableExternalUriSchemes = {'http', 'https', 'mailto', 'tel'};
const _remoteResourceUriSchemes = {'http', 'https'};
final _attachmentId = RegExp(r'^[A-Za-z0-9_-]+:[A-Za-z0-9_-]+:[A-Za-z0-9_-]+$');

bool isBusyMarkAttachmentUri(Uri uri) =>
    uri.scheme == 'busymark-attachment' &&
    !uri.hasAuthority &&
    _attachmentId.hasMatch(uri.path);

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

bool isRemoteImageSource(String? source) {
  final scheme = source == null ? null : Uri.tryParse(source.trim())?.scheme;
  return scheme == 'http' || scheme == 'https';
}

/// Carries a reference's query and fragment when replacing its resource path.
Uri withReferenceSuffix(Uri replacement, Uri reference) => replacement.replace(
  query: reference.hasQuery ? reference.query : null,
  fragment: reference.hasFragment ? reference.fragment : null,
);
