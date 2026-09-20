import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart' as xml;

enum AssetIngestionOrigin {
  imagePicker,
  screenshotPaste,
  clipboardImageFile,
  dragAndDrop,
}

enum AssetWorkspaceKind { writerside, markdownWorkspace, standalone }

class AssetIngestionException implements Exception {
  const AssetIngestionException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}

class AssetSaveRequiredException extends AssetIngestionException {
  const AssetSaveRequiredException()
    : super(
        'asset.document-save-required',
        'Save the document before adding an image.',
      );
}

class AssetIngestionRequest {
  const AssetIngestionRequest({
    required this.documentFilePath,
    required this.workspaceKind,
    this.workspaceRoot,
    this.writersideRoot,
    this.imagesDir = 'images',
  });

  final String documentFilePath;
  final AssetWorkspaceKind workspaceKind;
  final String? workspaceRoot;
  final String? writersideRoot;
  final String imagesDir;
}

class IngestedAsset {
  const IngestedAsset({
    required this.absolutePath,
    required this.markdownPath,
    required this.mimeType,
    required this.reusedExisting,
    required this.origin,
    this.publicationId,
  });

  final String absolutePath;
  final String markdownPath;
  final String mimeType;
  final bool reusedExisting;
  final AssetIngestionOrigin origin;

  /// Identifies a publication that is provisional until the caller commits
  /// the document reference. Reused, already-committed assets have no ID.
  final String? publicationId;
}

class AssetIngestionHooks {
  const AssetIngestionHooks({
    this.afterDestinationReserved,
    this.afterPublication,
    this.beforeCommit,
    this.beforeRollback,
    this.afterRollback,
  });

  final Future<void> Function(String path)? afterDestinationReserved;
  final Future<void> Function(IngestedAsset asset)? afterPublication;
  final Future<void> Function(IngestedAsset asset)? beforeCommit;
  final Future<void> Function(IngestedAsset asset)? beforeRollback;
  final Future<void> Function(IngestedAsset asset)? afterRollback;
}

class IngestedAssetSnapshot {
  const IngestedAssetSnapshot({required this.asset, required this.bytes});

  final IngestedAsset asset;
  final Uint8List bytes;
}

class AssetIngestionService {
  const AssetIngestionService({
    this.maximumAssetBytes = 100 * 1024 * 1024,
    this.hooks,
  });

  final int maximumAssetBytes;
  final AssetIngestionHooks? hooks;

  static final Map<String, _AssetDirectoryLock> _directoryOperations = {};
  static final Map<String, String> _provisionalPublications = {};
  static var _nextPublicationId = 0;

  Future<IngestedAsset> ingestFile({
    required String sourcePath,
    required AssetIngestionRequest request,
    required AssetIngestionOrigin origin,
  }) async {
    return (await ingestFileSnapshot(
      sourcePath: sourcePath,
      request: request,
      origin: origin,
    )).asset;
  }

  /// Ingests one immutable read of [sourcePath] and returns that exact read.
  ///
  /// Callers that need to retain or otherwise reuse the inserted content must
  /// use [bytes] instead of reopening a path that may have changed meanwhile.
  Future<IngestedAssetSnapshot> ingestFileSnapshot({
    required String sourcePath,
    required AssetIngestionRequest request,
    required AssetIngestionOrigin origin,
  }) async {
    final source = File(p.normalize(p.absolute(sourcePath)));
    final stat = await source.stat();
    if (stat.type != FileSystemEntityType.file) {
      throw const AssetIngestionException(
        'asset.source-not-file',
        'The selected image is not a regular file.',
      );
    }
    if (stat.size <= 0 || stat.size > maximumAssetBytes) {
      throw const AssetIngestionException(
        'asset.invalid-size',
        'The image is empty or exceeds the supported size limit.',
      );
    }
    final bytes = await source.readAsBytes();
    final asset = await ingestBytes(
      bytes: bytes,
      suggestedFileName: p.basename(source.path),
      request: request,
      origin: origin,
    );
    return IngestedAssetSnapshot(asset: asset, bytes: bytes);
  }

  Future<IngestedAsset> ingestBytes({
    required Uint8List bytes,
    required String suggestedFileName,
    required AssetIngestionRequest request,
    required AssetIngestionOrigin origin,
  }) async {
    _validateBytes(bytes, request: request);
    final imageType = _detectImageType(bytes);
    if (imageType == null) {
      throw const AssetIngestionException(
        'asset.invalid-image-type',
        'The selected file is not a supported PNG, JPEG, GIF, WebP, or SVG image.',
      );
    }
    return _publishBytes(
      bytes: bytes,
      suggestedFileName: suggestedFileName,
      request: request,
      origin: origin,
      type: imageType,
    );
  }

  /// Restores media captured from a rich clipboard fragment.
  ///
  /// Rich fragments can own both images and local Writerside videos. Ordinary
  /// image ingestion remains image-only; this broader boundary is reserved for
  /// restoring those already-captured media snapshots.
  Future<IngestedAsset> ingestMediaBytes({
    required Uint8List bytes,
    required String suggestedFileName,
    required AssetIngestionRequest request,
    required AssetIngestionOrigin origin,
  }) async {
    _validateBytes(bytes, request: request);
    final type = _detectImageType(bytes) ?? _videoType(suggestedFileName);
    if (type == null) {
      throw const AssetIngestionException(
        'asset.invalid-media-type',
        'The retained file is not a supported image or video.',
      );
    }
    return _publishBytes(
      bytes: bytes,
      suggestedFileName: suggestedFileName,
      request: request,
      origin: origin,
      type: type,
    );
  }

  bool canIngestMediaBytes({
    required Uint8List bytes,
    required String suggestedFileName,
  }) =>
      bytes.isNotEmpty &&
      bytes.length <= maximumAssetBytes &&
      (_videoType(suggestedFileName) != null ||
          _detectImageType(bytes) != null);

  void _validateBytes(
    Uint8List bytes, {
    required AssetIngestionRequest request,
  }) {
    if (request.documentFilePath.trim().isEmpty) {
      throw const AssetSaveRequiredException();
    }
    if (bytes.isEmpty || bytes.length > maximumAssetBytes) {
      throw const AssetIngestionException(
        'asset.invalid-size',
        'The file is empty or exceeds the supported size limit.',
      );
    }
  }

  Future<IngestedAsset> _publishBytes({
    required Uint8List bytes,
    required String suggestedFileName,
    required AssetIngestionRequest request,
    required AssetIngestionOrigin origin,
    required _DetectedAssetType type,
  }) async {
    final destination = await _destinationDirectory(request);
    final result = await _withDirectoryOperation(destination.path, () async {
      final contentHash = sha256.convert(bytes).toString();
      final existing = await _identicalAsset(
        destination,
        bytes.length,
        contentHash,
      );
      late final File published;
      String? publicationId;
      final reused = existing != null;
      if (existing != null) {
        published = existing;
      } else {
        final stem = _safeStem(p.basenameWithoutExtension(suggestedFileName));
        published = await _publishUnique(
          destination,
          stem: stem,
          extension: type.extension,
          bytes: bytes,
        );
        publicationId =
            '$pid-${DateTime.now().microsecondsSinceEpoch}-'
            '${_nextPublicationId++}';
        _provisionalPublications[published.path] = publicationId;
      }
      return IngestedAsset(
        absolutePath: published.path,
        markdownPath: p
            .relative(published.path, from: p.dirname(request.documentFilePath))
            .replaceAll(p.separator, '/'),
        mimeType: type.mimeType,
        reusedExisting: reused,
        origin: origin,
        publicationId: publicationId,
      );
    });
    await hooks?.afterPublication?.call(result);
    return result;
  }

  /// Makes a provisional publication reusable and transfers its lifetime to
  /// the successfully inserted document reference.
  Future<void> commit(IngestedAsset asset) async {
    final publicationId = asset.publicationId;
    if (publicationId == null) return;
    await hooks?.beforeCommit?.call(asset);
    if (_provisionalPublications[asset.absolutePath] == publicationId) {
      _provisionalPublications.remove(asset.absolutePath);
    }
  }

  Future<void> commitAll(Iterable<IngestedAsset> assets) async {
    for (final asset in assets) {
      await commit(asset);
    }
  }

  /// Removes [asset] only while this exact provisional publication still owns
  /// the path. A reused or already-committed asset is never deleted.
  Future<void> rollback(IngestedAsset asset) async {
    final publicationId = asset.publicationId;
    if (publicationId == null) return;
    await hooks?.beforeRollback?.call(asset);
    if (_provisionalPublications[asset.absolutePath] == publicationId) {
      final file = File(asset.absolutePath);
      try {
        if (file.existsSync()) file.deleteSync();
        _provisionalPublications.remove(asset.absolutePath);
      } on FileSystemException {
        // Retain the provisional ownership record. This prevents a failed
        // cleanup from making the uncommitted file reusable by another edit.
      }
    }
    await hooks?.afterRollback?.call(asset);
  }

  Future<void> rollbackAll(Iterable<IngestedAsset> assets) async {
    for (final asset in assets) {
      await rollback(asset);
    }
  }

  static Future<T> _withDirectoryOperation<T>(
    String directoryPath,
    Future<T> Function() operation,
  ) {
    final key = p.normalize(p.absolute(directoryPath));
    final lock = _directoryOperations.putIfAbsent(key, _AssetDirectoryLock.new);
    return lock.run(operation, () {
      if (identical(_directoryOperations[key], lock)) {
        _directoryOperations.remove(key);
      }
    });
  }

  Future<Directory> _destinationDirectory(AssetIngestionRequest request) async {
    final documentPath = p.normalize(p.absolute(request.documentFilePath));
    late final String allowedRootPath;
    late final String destinationPath;
    switch (request.workspaceKind) {
      case AssetWorkspaceKind.writerside:
        final writersideRoot = request.writersideRoot;
        if (writersideRoot == null || writersideRoot.trim().isEmpty) {
          throw const AssetIngestionException(
            'asset.writerside-root-missing',
            'The Writerside project image directory is unavailable.',
          );
        }
        final relativeImagesDir = _safeRelativeDirectory(request.imagesDir);
        allowedRootPath = p.normalize(p.absolute(writersideRoot));
        destinationPath = p.join(allowedRootPath, relativeImagesDir);
      case AssetWorkspaceKind.markdownWorkspace:
        final workspaceRoot = request.workspaceRoot;
        if (workspaceRoot == null || workspaceRoot.trim().isEmpty) {
          throw const AssetIngestionException(
            'asset.workspace-root-missing',
            'The workspace image directory is unavailable.',
          );
        }
        allowedRootPath = p.normalize(p.absolute(workspaceRoot));
        destinationPath = p.join(allowedRootPath, 'images');
      case AssetWorkspaceKind.standalone:
        allowedRootPath = p.dirname(documentPath);
        destinationPath = p.join(allowedRootPath, 'images');
    }
    final allowedRoot = Directory(allowedRootPath);
    if (!await allowedRoot.exists()) {
      throw const AssetIngestionException(
        'asset.destination-root-missing',
        'The document asset root no longer exists.',
      );
    }
    final canonicalRoot = p.normalize(await allowedRoot.resolveSymbolicLinks());
    final destination = Directory(destinationPath);
    await destination.create(recursive: true);
    final canonicalDestination = p.normalize(
      await destination.resolveSymbolicLinks(),
    );
    if (!p.equals(canonicalRoot, canonicalDestination) &&
        !p.isWithin(canonicalRoot, canonicalDestination)) {
      throw const AssetIngestionException(
        'asset.destination-outside-workspace',
        'The configured image directory resolves outside the project.',
      );
    }
    return Directory(canonicalDestination);
  }

  String _safeRelativeDirectory(String value) {
    final normalized = p.normalize(value.trim());
    if (normalized.isEmpty ||
        normalized == '.' ||
        p.isAbsolute(normalized) ||
        normalized == '..' ||
        normalized.startsWith('..${p.separator}')) {
      throw const AssetIngestionException(
        'asset.images-dir-invalid',
        'The configured Writerside images directory is invalid.',
      );
    }
    return normalized;
  }

  Future<File?> _identicalAsset(
    Directory directory,
    int size,
    String expectedHash,
  ) async {
    var inspected = 0;
    await for (final entity in directory.list(followLinks: false)) {
      if (++inspected > 10000) {
        break;
      }
      if (entity is! File) {
        continue;
      }
      if (_provisionalPublications.containsKey(entity.path)) {
        continue;
      }
      late final FileStat stat;
      try {
        stat = await entity.stat();
      } on FileSystemException {
        continue;
      }
      if (stat.size != size) {
        continue;
      }
      final digest = sha256.convert(await entity.readAsBytes()).toString();
      if (digest == expectedHash) {
        return entity;
      }
    }
    return null;
  }

  Future<File> _publishUnique(
    Directory directory, {
    required String stem,
    required String extension,
    required Uint8List bytes,
  }) async {
    var suffix = 1;
    while (true) {
      final name = suffix == 1
          ? '$stem.$extension'
          : '$stem-$suffix.$extension';
      final target = File(p.join(directory.path, name));
      RandomAccessFile? reservation;
      try {
        await target.create(exclusive: true);
      } on FileSystemException {
        if (await target.exists()) {
          suffix++;
          continue;
        }
        rethrow;
      }
      try {
        reservation = await target.open(mode: FileMode.writeOnly);
      } catch (_) {
        try {
          if (await target.exists()) await target.delete();
        } on FileSystemException {
          // Preserve the original open failure.
        }
        rethrow;
      }
      try {
        await hooks?.afterDestinationReserved?.call(target.path);
        await reservation.writeFrom(bytes);
        await reservation.flush();
        await reservation.close();
        reservation = null;
        return target;
      } catch (_) {
        await reservation?.close();
        try {
          if (await target.exists()) await target.delete();
        } on FileSystemException {
          // Preserve the original publication failure.
        }
        rethrow;
      }
    }
  }

  String _safeStem(String value) {
    final sanitized = value
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^[.\-_]+|[.\-_]+$'), '');
    if (sanitized.isEmpty) {
      return 'image';
    }
    return sanitized.length <= 80 ? sanitized : sanitized.substring(0, 80);
  }

  _DetectedAssetType? _detectImageType(Uint8List bytes) {
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0d &&
        bytes[5] == 0x0a &&
        bytes[6] == 0x1a &&
        bytes[7] == 0x0a) {
      return const _DetectedAssetType('png', 'image/png');
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      return const _DetectedAssetType('jpg', 'image/jpeg');
    }
    if (bytes.length >= 6) {
      final signature = ascii.decode(bytes.sublist(0, 6), allowInvalid: true);
      if (signature == 'GIF87a' || signature == 'GIF89a') {
        return const _DetectedAssetType('gif', 'image/gif');
      }
    }
    if (bytes.length >= 12 &&
        ascii.decode(bytes.sublist(0, 4), allowInvalid: true) == 'RIFF' &&
        ascii.decode(bytes.sublist(8, 12), allowInvalid: true) == 'WEBP') {
      return const _DetectedAssetType('webp', 'image/webp');
    }
    try {
      final source = utf8.decode(bytes);
      final document = xml.XmlDocument.parse(
        source.startsWith('\uFEFF') ? source.substring(1) : source,
      );
      if (document.rootElement.name.local.toLowerCase() == 'svg') {
        return const _DetectedAssetType('svg', 'image/svg+xml');
      }
    } on Object {
      // Binary or malformed XML is not SVG.
    }
    return null;
  }

  _DetectedAssetType? _videoType(String suggestedFileName) =>
      switch (p.extension(suggestedFileName).toLowerCase()) {
        '.avi' => const _DetectedAssetType('avi', 'video/x-msvideo'),
        '.m4v' => const _DetectedAssetType('m4v', 'video/x-m4v'),
        '.mkv' => const _DetectedAssetType('mkv', 'video/x-matroska'),
        '.mov' => const _DetectedAssetType('mov', 'video/quicktime'),
        '.mp4' => const _DetectedAssetType('mp4', 'video/mp4'),
        '.ogv' => const _DetectedAssetType('ogv', 'video/ogg'),
        '.webm' => const _DetectedAssetType('webm', 'video/webm'),
        _ => null,
      };
}

class _AssetDirectoryLock {
  var _locked = false;
  final _waiters = <Completer<void>>[];

  Future<T> run<T>(
    Future<T> Function() operation,
    void Function() onIdle,
  ) async {
    if (_locked) {
      final waiter = Completer<void>();
      _waiters.add(waiter);
      await waiter.future;
    } else {
      _locked = true;
    }
    try {
      return await operation();
    } finally {
      if (_waiters.isNotEmpty) {
        _waiters.removeAt(0).complete();
      } else {
        _locked = false;
        onIdle();
      }
    }
  }
}

class _DetectedAssetType {
  const _DetectedAssetType(this.extension, this.mimeType);

  final String extension;
  final String mimeType;
}
