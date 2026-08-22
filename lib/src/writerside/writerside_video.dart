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

enum WritersideVideoPlaybackKind { localFile, youtube, vimeo }

class WritersideVideoPlaybackSource {
  const WritersideVideoPlaybackSource({
    required this.kind,
    required this.value,
  });

  final WritersideVideoPlaybackKind kind;
  final String value;
}

/// Resolves an authored Writerside source to the minimal trusted value needed
/// by the native player. Hosted services are reduced to a validated video ID;
/// local media is reduced to a canonical file path.
WritersideVideoPlaybackSource? resolveWritersideVideoPlaybackSource({
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
    return resolveWritersideHostedVideoSource(value);
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
  return resolved == null
      ? null
      : WritersideVideoPlaybackSource(
          kind: WritersideVideoPlaybackKind.localFile,
          value: resolved,
        );
}

/// Reduces a supported hosted Writerside URL to a validated provider and ID.
/// Query strings and authored paths are never forwarded to the native player.
WritersideVideoPlaybackSource? resolveWritersideHostedVideoSource(
  String source,
) {
  final parsed = Uri.tryParse(source.trim());
  if (parsed == null ||
      parsed.scheme.toLowerCase() != 'https' ||
      parsed.userInfo.isNotEmpty ||
      parsed.host.isEmpty) {
    return null;
  }
  final youtubeId = _youtubeVideoId(parsed);
  if (youtubeId != null) {
    return WritersideVideoPlaybackSource(
      kind: WritersideVideoPlaybackKind.youtube,
      value: youtubeId,
    );
  }
  final vimeoId = _vimeoVideoId(parsed);
  if (vimeoId != null) {
    return WritersideVideoPlaybackSource(
      kind: WritersideVideoPlaybackKind.vimeo,
      value: vimeoId,
    );
  }
  return null;
}

/// Resolves a Writerside video source without granting arbitrary URL schemes
/// or local filesystem access outside the document's existing media roots.
Uri? resolveWritersideVideoUri({
  required String source,
  required String activeFilePath,
  required String? workspaceRoot,
  required String? writersideRoot,
  required String imagesDir,
}) {
  final playback = resolveWritersideVideoPlaybackSource(
    source: source,
    activeFilePath: activeFilePath,
    workspaceRoot: workspaceRoot,
    writersideRoot: writersideRoot,
    imagesDir: imagesDir,
  );
  if (playback == null) {
    return null;
  }
  return playback.kind == WritersideVideoPlaybackKind.localFile
      ? Uri.file(playback.value)
      : Uri.parse(source.trim());
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

String? _youtubeVideoId(Uri uri) {
  if (!_youtubeHost(uri.host)) {
    return null;
  }
  final segments = uri.pathSegments.where((part) => part.isNotEmpty).toList();
  String? candidate;
  if (uri.host.toLowerCase() == 'youtu.be') {
    candidate = segments.firstOrNull;
  } else if (uri.path == '/watch') {
    candidate = uri.queryParameters['v'];
  } else if (segments.length >= 2 &&
      const {'embed', 'shorts', 'v'}.contains(segments.first)) {
    candidate = segments[1];
  }
  return candidate != null &&
          RegExp(r'^[A-Za-z0-9_-]{6,64}$').hasMatch(candidate)
      ? candidate
      : null;
}

String? _vimeoVideoId(Uri uri) {
  if (!_vimeoHost(uri.host)) {
    return null;
  }
  final candidate = uri.pathSegments
      .where((part) => RegExp(r'^\d{1,20}$').hasMatch(part))
      .lastOrNull;
  return candidate;
}

bool _youtubeHost(String host) {
  final value = host.toLowerCase();
  return value == 'youtu.be' ||
      value == 'youtube.com' ||
      value.endsWith('.youtube.com') ||
      value == 'youtube-nocookie.com' ||
      value.endsWith('.youtube-nocookie.com');
}

bool _vimeoHost(String host) {
  final value = host.toLowerCase();
  return value == 'vimeo.com' || value.endsWith('.vimeo.com');
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

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;

  T? get lastOrNull => isEmpty ? null : last;
}
