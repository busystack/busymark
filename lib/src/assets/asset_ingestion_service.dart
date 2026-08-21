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
  });

  final String absolutePath;
  final String markdownPath;
  final String mimeType;
  final bool reusedExisting;
  final AssetIngestionOrigin origin;
}

class AssetIngestionService {
  const AssetIngestionService({this.maximumAssetBytes = 100 * 1024 * 1024});

  final int maximumAssetBytes;

  Future<IngestedAsset> ingestFile({
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
    return ingestBytes(
      bytes: await source.readAsBytes(),
      suggestedFileName: p.basename(source.path),
      request: request,
      origin: origin,
    );
  }

  Future<IngestedAsset> ingestBytes({
    required Uint8List bytes,
    required String suggestedFileName,
    required AssetIngestionRequest request,
    required AssetIngestionOrigin origin,
  }) async {
    if (request.documentFilePath.trim().isEmpty) {
      throw const AssetSaveRequiredException();
    }
    if (bytes.isEmpty || bytes.length > maximumAssetBytes) {
      throw const AssetIngestionException(
        'asset.invalid-size',
        'The image is empty or exceeds the supported size limit.',
      );
    }
    final imageType = _detectImageType(bytes);
    if (imageType == null) {
      throw const AssetIngestionException(
        'asset.invalid-image-type',
        'The selected file is not a supported PNG, JPEG, GIF, WebP, or SVG image.',
      );
    }
    final destination = await _destinationDirectory(request);
    final contentHash = sha256.convert(bytes).toString();
    final existing = await _identicalAsset(
      destination,
      bytes.length,
      contentHash,
    );
    late final File published;
    var reused = existing != null;
    if (existing != null) {
      published = existing;
    } else {
      final stem = _safeStem(p.basenameWithoutExtension(suggestedFileName));
      published = await _publishUnique(
        destination,
        stem: stem,
        extension: imageType.extension,
        bytes: bytes,
      );
      reused = false;
    }
    return IngestedAsset(
      absolutePath: published.path,
      markdownPath: p
          .relative(published.path, from: p.dirname(request.documentFilePath))
          .replaceAll(p.separator, '/'),
      mimeType: imageType.mimeType,
      reusedExisting: reused,
      origin: origin,
    );
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
      final stat = await entity.stat();
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
    late File target;
    while (true) {
      final name = suffix == 1
          ? '$stem.$extension'
          : '$stem-$suffix.$extension';
      target = File(p.join(directory.path, name));
      if (!await target.exists()) {
        break;
      }
      suffix++;
    }
    final staging = File(
      p.join(
        directory.path,
        '.busymark-asset-$pid-${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
    try {
      await staging.writeAsBytes(bytes, flush: true);
      return await staging.rename(target.path);
    } finally {
      if (await staging.exists()) {
        await staging.delete();
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

  _DetectedImageType? _detectImageType(Uint8List bytes) {
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0d &&
        bytes[5] == 0x0a &&
        bytes[6] == 0x1a &&
        bytes[7] == 0x0a) {
      return const _DetectedImageType('png', 'image/png');
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      return const _DetectedImageType('jpg', 'image/jpeg');
    }
    if (bytes.length >= 6) {
      final signature = ascii.decode(bytes.sublist(0, 6), allowInvalid: true);
      if (signature == 'GIF87a' || signature == 'GIF89a') {
        return const _DetectedImageType('gif', 'image/gif');
      }
    }
    if (bytes.length >= 12 &&
        ascii.decode(bytes.sublist(0, 4), allowInvalid: true) == 'RIFF' &&
        ascii.decode(bytes.sublist(8, 12), allowInvalid: true) == 'WEBP') {
      return const _DetectedImageType('webp', 'image/webp');
    }
    try {
      final source = utf8.decode(bytes);
      final document = xml.XmlDocument.parse(
        source.startsWith('\uFEFF') ? source.substring(1) : source,
      );
      if (document.rootElement.name.local.toLowerCase() == 'svg') {
        return const _DetectedImageType('svg', 'image/svg+xml');
      }
    } on Object {
      // Binary or malformed XML is not SVG.
    }
    return null;
  }
}

class _DetectedImageType {
  const _DetectedImageType(this.extension, this.mimeType);

  final String extension;
  final String mimeType;
}
