import 'dart:io';

import 'package:path/path.dart' as p;

import 'atomic_file_exceptions.dart';
import 'linux_file_identity.dart';

enum SaveDestinationKind { file, fileOrSymbolicLink, directory }

/// The entry reviewed for one save operation. A missing target only permits
/// no-replace publication. Existing entries must match at publication time.
final class SaveDestination {
  SaveDestination._(
    this.path,
    this._parent,
    this._entry,
    this._linkTarget,
    this._referent,
  );

  final String path;
  final String _parent;
  final LinuxFileVersion? _entry;
  final String? _linkTarget;
  final LinuxFileVersion? _referent;

  bool get replacesExisting => _entry != null;

  static String withSuffix(
    String path,
    String? suffix, {
    bool onlyWhenMissing = false,
  }) {
    if (suffix == null) return path;
    final extension = p.extension(path);
    if (extension.toLowerCase() == suffix.toLowerCase() ||
        (onlyWhenMissing && extension.isNotEmpty)) {
      return path;
    }
    return '$path$suffix';
  }

  static SaveDestination inspect(
    String path, {
    SaveDestinationKind kind = SaveDestinationKind.file,
  }) {
    path = p.normalize(p.absolute(path));
    final parent = LinuxFileIdentity.version(
      p.dirname(path),
      followLinks: true,
    );
    if (parent == null || (parent.mode & 0xf000) != 0x4000) {
      throw FileSystemException('Unsupported save destination folder', path);
    }
    final type = FileSystemEntity.typeSync(path, followLinks: false);
    if (type == FileSystemEntityType.notFound) {
      return SaveDestination._(path, parent.identity, null, null, null);
    }
    final entry = LinuxFileIdentity.version(path);
    final fileType = (entry?.mode ?? 0) & 0xf000;
    final expectedType = kind == SaveDestinationKind.directory
        ? 0x4000
        : 0x8000;
    if (fileType == expectedType) {
      return SaveDestination._(path, parent.identity, entry, null, null);
    }
    if (kind == SaveDestinationKind.fileOrSymbolicLink && fileType == 0xa000) {
      final linkTarget = Link(path).targetSync();
      final referent = LinuxFileIdentity.version(path, followLinks: true);
      if (referent != null && referent.mode & 0xf000 == 0x8000) {
        return SaveDestination._(
          path,
          parent.identity,
          entry,
          linkTarget,
          referent,
        );
      }
    }
    throw FileSystemException('Unsupported save destination', path);
  }

  void requireCurrent(String destination) {
    if (!p.equals(path, p.normalize(p.absolute(destination))) ||
        !_matches(path, displaced: false)) {
      throw AtomicFileChangedException(destination);
    }
  }

  bool acceptsDisplaced(String stagedPath) =>
      replacesExisting && _matches(stagedPath, displaced: true);

  bool _matches(String candidate, {required bool displaced}) {
    try {
      if (LinuxFileIdentity.version(
            p.dirname(path),
            followLinks: true,
          )?.identity !=
          _parent) {
        return false;
      }
      if (_entry == null) {
        return FileSystemEntity.typeSync(candidate, followLinks: false) ==
            FileSystemEntityType.notFound;
      }
      final current = LinuxFileIdentity.version(candidate);
      if (current == null ||
          current.identity != _entry.identity ||
          current.mode != _entry.mode ||
          current.size != _entry.size ||
          current.modified != _entry.modified ||
          (!displaced && current.changed != _entry.changed)) {
        return false;
      }
      final linkTarget = _linkTarget;
      if (linkTarget == null) return true;
      return Link(candidate).targetSync() == linkTarget &&
          LinuxFileIdentity.version(
                p.isAbsolute(linkTarget)
                    ? linkTarget
                    : p.join(p.dirname(path), linkTarget),
                followLinks: true,
              ) ==
              _referent;
    } on FileSystemException {
      return false;
    }
  }
}
