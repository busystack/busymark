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
  final allowedRoots = _canonicalAllowedImageRoots(
    workspaceRoot: workspaceRoot,
    writersideRoot: writersideRoot,
    imagesDir: imagesDir,
  );
  if (allowedRoots.isEmpty) {
    return null;
  }
  final candidates = <String>[];
  if (p.isAbsolute(decoded)) {
    candidates.add(decoded);
  } else {
    candidates.add(p.normalize(p.join(p.dirname(activeFilePath), decoded)));
    if (workspaceRoot != null) {
      candidates
        ..add(p.normalize(p.join(workspaceRoot, decoded)))
        ..add(p.normalize(p.join(workspaceRoot, imagesDir, decoded)));
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
  }

  for (final candidate in candidates.toSet()) {
    final resolved = _canonicalExistingFileWithinAllowedRoots(
      candidate,
      allowedRoots,
    );
    if (resolved != null) {
      return resolved;
    }
  }

  final imagesRoot = _imagesRoot(workspaceRoot, writersideRoot, imagesDir);
  if (imagesRoot == null || p.split(decoded).length > 1) {
    return null;
  }
  return _findImageByBasename(
    imagesRoot: imagesRoot,
    allowedRoots: allowedRoots,
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

List<String> _canonicalAllowedImageRoots({
  required String? workspaceRoot,
  required String? writersideRoot,
  required String imagesDir,
}) {
  final roots = <String>[];
  if (workspaceRoot != null) {
    final canonical = _canonicalExistingDirectory(workspaceRoot);
    if (canonical != null) {
      roots.add(canonical);
    }
  }
  if (writersideRoot != null) {
    final canonical = _canonicalExistingDirectory(
      p.join(writersideRoot, imagesDir),
    );
    if (canonical != null) {
      roots.add(canonical);
    }
  }
  return roots.toSet().toList();
}

String? _canonicalExistingDirectory(String path) {
  try {
    final directory = Directory(p.normalize(p.absolute(path)));
    if (!directory.existsSync()) {
      return null;
    }
    return p.normalize(directory.resolveSymbolicLinksSync());
  } on FileSystemException {
    return null;
  }
}

String? _canonicalExistingFileWithinAllowedRoots(
  String path,
  List<String> allowedRoots,
) {
  try {
    final file = File(p.normalize(p.absolute(path)));
    if (!file.existsSync()) {
      return null;
    }
    final canonical = p.normalize(file.resolveSymbolicLinksSync());
    if (!_isWithinAnyRoot(canonical, allowedRoots)) {
      return null;
    }
    final type = FileSystemEntity.typeSync(canonical, followLinks: false);
    return type == FileSystemEntityType.file ? canonical : null;
  } on FileSystemException {
    return null;
  }
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
    return _canonicalExistingDirectory(p.join(writersideRoot, dir));
  }
  if (workspaceRoot == null) {
    return null;
  }
  final workspaceImages = Directory(p.normalize(p.join(workspaceRoot, dir)));
  if (workspaceImages.existsSync()) {
    return _canonicalExistingDirectory(workspaceImages.path);
  }
  return null;
}

String? _findImageByBasename({
  required String imagesRoot,
  required List<String> allowedRoots,
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
      final resolved = _canonicalExistingFileWithinAllowedRoots(
        entity.path,
        allowedRoots,
      );
      if (resolved != null) {
        matches.add(resolved);
      }
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

bool _isWithinAnyRoot(String candidate, Iterable<String> roots) {
  return roots.any(
    (root) => p.equals(root, candidate) || p.isWithin(root, candidate),
  );
}

String _decodeImageDestination(String value) {
  final withoutFragment = value.split('#').first;
  try {
    return Uri.decodeComponent(withoutFragment);
  } on FormatException {
    return withoutFragment;
  }
}
