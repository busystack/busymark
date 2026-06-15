import 'dart:io';

import 'package:path/path.dart' as p;

import 'path_utils.dart';

String? resolveLocalImagePath({
  required String activeFilePath,
  required String destination,
  String? workspaceRoot,
  String? writersideRoot,
  String imagesDir = 'images',
  int maxRecursiveEntries = 10000,
}) {
  final decoded = _decodeImageDestination(destination.trim());
  if (decoded.isEmpty) {
    return null;
  }
  final candidates = <String>[];
  if (p.isAbsolute(decoded)) {
    candidates.add(decoded);
  }
  candidates.add(p.normalize(p.join(p.dirname(activeFilePath), decoded)));
  if (workspaceRoot != null) {
    candidates
      ..add(p.normalize(p.join(workspaceRoot, decoded)))
      ..add(p.normalize(p.join(workspaceRoot, imagesDir, decoded)));
    final projectRoot = writersideRoot ?? p.dirname(workspaceRoot);
    candidates.addAll(
      _writersideImageCandidates(
        rootPath: projectRoot,
        imagesDir: imagesDir,
        activeFilePath: activeFilePath,
        destination: decoded,
      ),
    );
  }
  if (writersideRoot != null) {
    candidates.addAll(
      _writersideImageCandidates(
        rootPath: writersideRoot,
        imagesDir: imagesDir,
        activeFilePath: activeFilePath,
        destination: decoded,
      ),
    );
  }

  for (final candidate in candidates.toSet()) {
    if (File(candidate).existsSync()) {
      return candidate;
    }
  }

  final imagesRoot = _imagesRoot(workspaceRoot, writersideRoot, imagesDir);
  if (imagesRoot == null || p.split(decoded).length > 1) {
    return null;
  }
  return _findImageByBasename(
    imagesRoot: imagesRoot,
    basename: decoded,
    maxEntries: maxRecursiveEntries,
  );
}

bool localImageExists({
  required String activeFilePath,
  required String destination,
  String? workspaceRoot,
  String? writersideRoot,
  String imagesDir = 'images',
}) {
  return resolveLocalImagePath(
        activeFilePath: activeFilePath,
        destination: destination,
        workspaceRoot: workspaceRoot,
        writersideRoot: writersideRoot,
        imagesDir: imagesDir,
      ) !=
      null;
}

List<String> _writersideImageCandidates({
  required String rootPath,
  required String imagesDir,
  required String activeFilePath,
  required String destination,
}) {
  final imagesRoot = p.normalize(p.join(rootPath, imagesDir));
  final activeStem = p.basenameWithoutExtension(activeFilePath);
  final sluggedStem = slugForHeading(activeStem);
  return [
    p.normalize(p.join(imagesRoot, destination)),
    p.normalize(p.join(imagesRoot, activeStem, destination)),
    p.normalize(p.join(imagesRoot, activeStem.toLowerCase(), destination)),
    p.normalize(p.join(imagesRoot, sluggedStem, destination)),
  ];
}

String? _imagesRoot(String? workspaceRoot, String? writersideRoot, String dir) {
  if (writersideRoot != null) {
    return p.normalize(p.join(writersideRoot, dir));
  }
  if (workspaceRoot == null) {
    return null;
  }
  final workspaceImages = Directory(p.normalize(p.join(workspaceRoot, dir)));
  if (workspaceImages.existsSync()) {
    return workspaceImages.path;
  }
  return p.normalize(p.join(p.dirname(workspaceRoot), dir));
}

String? _findImageByBasename({
  required String imagesRoot,
  required String basename,
  required int maxEntries,
}) {
  final root = Directory(imagesRoot);
  if (!root.existsSync()) {
    return null;
  }
  final matches = <String>[];
  var seen = 0;
  try {
    for (final entity in root.listSync(recursive: true, followLinks: false)) {
      seen++;
      if (seen > maxEntries) {
        break;
      }
      if (entity is! File || p.basename(entity.path) != basename) {
        continue;
      }
      matches.add(p.normalize(entity.path));
    }
  } on FileSystemException {
    return null;
  }
  if (matches.isEmpty) {
    return null;
  }
  matches.sort();
  return matches.first;
}

String _decodeImageDestination(String value) {
  final withoutFragment = value.split('#').first;
  try {
    return Uri.decodeComponent(withoutFragment);
  } on FormatException {
    return withoutFragment;
  }
}
