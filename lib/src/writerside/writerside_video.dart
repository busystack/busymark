import 'package:path/path.dart' as p;

import '../core/local_image_resolver.dart';

const busyMarkWritersideVideoExtensions = {
  '.avi',
  '.m4v',
  '.mkv',
  '.mov',
  '.mp4',
  '.ogv',
  '.webm',
};

/// Resolves a Writerside video source without granting arbitrary URL schemes
/// or local filesystem access outside the document's existing media roots.
Uri? resolveWritersideVideoUri({
  required String source,
  required String activeFilePath,
  required String? workspaceRoot,
  required String? writersideRoot,
  required String imagesDir,
}) {
  final value = source.trim();
  if (value.isEmpty) {
    return null;
  }
  final parsed = Uri.tryParse(value);
  if (parsed != null && parsed.hasScheme) {
    if (parsed.scheme.toLowerCase() != 'https' ||
        !isSupportedWritersideVideoHost(parsed.host)) {
      return null;
    }
    return parsed;
  }
  if (p.isAbsolute(value) ||
      !busyMarkWritersideVideoExtensions.contains(
        p.extension(value.split('?').first.split('#').first).toLowerCase(),
      )) {
    return null;
  }
  final resolved = resolveLocalMediaPath(
    activeFilePath: activeFilePath,
    destination: value,
    workspaceRoot: workspaceRoot,
    writersideRoot: writersideRoot,
    imagesDir: imagesDir,
  );
  return resolved == null ? null : Uri.file(resolved);
}

bool isSupportedWritersideVideoHost(String host) {
  final value = host.trim().toLowerCase();
  return value == 'youtu.be' ||
      value == 'youtube.com' ||
      value.endsWith('.youtube.com') ||
      value == 'youtube-nocookie.com' ||
      value.endsWith('.youtube-nocookie.com') ||
      value == 'vimeo.com' ||
      value.endsWith('.vimeo.com');
}

String writersideVideoPreviewSource(String source, String? previewSource) {
  final explicit = previewSource?.trim() ?? '';
  if (explicit.isNotEmpty) {
    return explicit;
  }
  final value = source.trim();
  final uri = Uri.tryParse(value);
  if (value.isEmpty || (uri != null && uri.hasScheme)) {
    return '';
  }
  final suffixStart = value.indexOf(RegExp(r'[?#]'));
  final path = suffixStart < 0 ? value : value.substring(0, suffixStart);
  return p.setExtension(path, '.png');
}

double? busyMarkVideoDimension(String? value) {
  if (value == null) {
    return null;
  }
  final number = RegExp(
    r'^\s*([0-9]+(?:\.[0-9]+)?)',
  ).firstMatch(value)?.group(1);
  final parsed = number == null ? null : double.tryParse(number);
  return parsed == null || parsed <= 0 ? null : parsed;
}
