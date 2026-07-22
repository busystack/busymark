import 'dart:io';

import 'package:path/path.dart' as p;

/// A canonical directory boundary captured before path validation.
///
/// [requestedRootPath] preserves the path spelling supplied by the caller so
/// descendant paths can be rebased onto [rootPath]. Commands must use the
/// canonical [rootPath] returned here rather than resolving the requested path
/// again after validation.
class CanonicalPathAnchor {
  const CanonicalPathAnchor._({
    required this.requestedRootPath,
    required this.rootPath,
  });

  final String requestedRootPath;
  final String rootPath;
}

class AnchoredPathResolution {
  const AnchoredPathResolution({
    required this.anchor,
    required this.path,
    required this.type,
  });

  final CanonicalPathAnchor anchor;
  final String path;
  final FileSystemEntityType type;
}

enum AnchoredPathViolationReason {
  rootNotDirectory,
  outsideRoot,
  rootReplacement,
  symlinkComponent,
  nonDirectoryAncestor,
  missingAncestor,
}

class AnchoredPathViolation implements Exception {
  const AnchoredPathViolation({required this.reason, required this.path});

  final AnchoredPathViolationReason reason;
  final String path;

  @override
  String toString() => 'Unsafe anchored path ($reason): $path';
}

Future<CanonicalPathAnchor> captureCanonicalDirectoryAnchor(
  String rootPath,
) async {
  final requestedRoot = _absoluteNormalized(rootPath);
  final type = await FileSystemEntity.type(requestedRoot);
  if (type != FileSystemEntityType.directory) {
    throw AnchoredPathViolation(
      reason: AnchoredPathViolationReason.rootNotDirectory,
      path: requestedRoot,
    );
  }
  final canonicalRoot = p.normalize(
    await Directory(requestedRoot).resolveSymbolicLinks(),
  );
  final canonicalType = await FileSystemEntity.type(
    canonicalRoot,
    followLinks: false,
  );
  if (canonicalType != FileSystemEntityType.directory) {
    throw AnchoredPathViolation(
      reason: AnchoredPathViolationReason.rootNotDirectory,
      path: canonicalRoot,
    );
  }
  return CanonicalPathAnchor._(
    requestedRootPath: requestedRoot,
    rootPath: canonicalRoot,
  );
}

/// Rebases [candidatePath] onto a captured canonical directory and rejects
/// every existing symlink below that directory.
///
/// Missing final components are allowed so callers can validate create
/// targets. A recursive directory create can opt into missing ancestors, but
/// every existing ancestor is still checked.
Future<AnchoredPathResolution> resolveAnchoredPath(
  CanonicalPathAnchor anchor,
  String candidatePath, {
  required bool allowRoot,
  bool allowFinalSymlink = false,
  bool allowMissingAncestors = false,
}) async {
  final rootType = await FileSystemEntity.type(
    anchor.rootPath,
    followLinks: false,
  );
  if (rootType != FileSystemEntityType.directory) {
    throw AnchoredPathViolation(
      reason: AnchoredPathViolationReason.rootReplacement,
      path: anchor.rootPath,
    );
  }

  final candidate = _absoluteNormalized(candidatePath);
  final relative = _relativeToAnchor(anchor, candidate);
  if (relative == null) {
    throw AnchoredPathViolation(
      reason: AnchoredPathViolationReason.outsideRoot,
      path: candidate,
    );
  }
  if (relative == '.' && !allowRoot) {
    throw AnchoredPathViolation(
      reason: AnchoredPathViolationReason.outsideRoot,
      path: candidate,
    );
  }

  final resolved = relative == '.'
      ? anchor.rootPath
      : p.normalize(p.join(anchor.rootPath, relative));
  if (!_isInsideOrEqual(anchor.rootPath, resolved)) {
    throw AnchoredPathViolation(
      reason: AnchoredPathViolationReason.outsideRoot,
      path: resolved,
    );
  }
  if (relative == '.') {
    return AnchoredPathResolution(
      anchor: anchor,
      path: resolved,
      type: rootType,
    );
  }

  var current = anchor.rootPath;
  var currentType = rootType;
  final components = p.split(relative);
  for (var index = 0; index < components.length; index += 1) {
    current = p.join(current, components[index]);
    currentType = await FileSystemEntity.type(current, followLinks: false);
    final isFinal = index == components.length - 1;
    if (currentType == FileSystemEntityType.link &&
        !(isFinal && allowFinalSymlink)) {
      throw AnchoredPathViolation(
        reason: AnchoredPathViolationReason.symlinkComponent,
        path: current,
      );
    }
    if (!isFinal &&
        currentType != FileSystemEntityType.directory &&
        currentType != FileSystemEntityType.notFound) {
      throw AnchoredPathViolation(
        reason: AnchoredPathViolationReason.nonDirectoryAncestor,
        path: current,
      );
    }
    if (!isFinal &&
        currentType == FileSystemEntityType.notFound &&
        !allowMissingAncestors) {
      throw AnchoredPathViolation(
        reason: AnchoredPathViolationReason.missingAncestor,
        path: current,
      );
    }
  }
  return AnchoredPathResolution(
    anchor: anchor,
    path: resolved,
    type: currentType,
  );
}

String? _relativeToAnchor(CanonicalPathAnchor anchor, String candidate) {
  for (final root in [anchor.requestedRootPath, anchor.rootPath]) {
    if (_isInsideOrEqual(root, candidate)) {
      return p.normalize(p.relative(candidate, from: root));
    }
  }
  return null;
}

bool _isInsideOrEqual(String root, String path) {
  return p.equals(root, path) || p.isWithin(root, path);
}

String _absoluteNormalized(String path) {
  return p.normalize(p.isAbsolute(path) ? path : p.absolute(path));
}
