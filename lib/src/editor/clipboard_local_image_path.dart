import 'dart:io';

import 'package:path/path.dart' as p;

const _supportedImageExtensions = {
  '.png',
  '.jpg',
  '.jpeg',
  '.gif',
  '.webp',
  '.svg',
};

/// Returns a supported, existing local image path when [value] can safely be
/// interpreted as one. Callers must keep [value] unchanged for text fallback.
String? busyMarkLocalImagePathFromClipboardText(String value) {
  final detectionValue = value.trim();
  if (detectionValue.isEmpty ||
      detectionValue.contains('\n') ||
      detectionValue.contains('\r')) {
    return null;
  }
  final uri = Uri.tryParse(detectionValue);
  if (uri == null) return null;
  String candidate;
  if (uri.scheme.isEmpty) {
    candidate = detectionValue;
  } else if (uri.scheme == 'file' &&
      uri.authority.isEmpty &&
      !uri.hasQuery &&
      !uri.hasFragment) {
    try {
      candidate = File.fromUri(uri).path;
    } on ArgumentError {
      return null;
    } on UnsupportedError {
      return null;
    }
  } else {
    return null;
  }
  if (!_supportedImageExtensions.contains(
    p.extension(candidate).toLowerCase(),
  )) {
    return null;
  }
  try {
    return File(candidate).existsSync() ? candidate : null;
  } on FileSystemException {
    return null;
  }
}
