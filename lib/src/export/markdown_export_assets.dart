import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart' as xml;

import '../core/local_image_resolver.dart';
import '../core/uri_utils.dart';
import 'markdown_export_document.dart';
import 'markdown_pdf_models.dart';

class MarkdownExportAssetResult {
  const MarkdownExportAssetResult({
    required this.assets,
    required this.warnings,
  });

  /// Original Markdown destination to a safe path relative to the export root.
  final Map<String, String> assets;
  final List<MarkdownPdfWarning> warnings;
}

class MarkdownExportAssetStager {
  const MarkdownExportAssetStager({
    this.maxAssetBytes = 16 * 1024 * 1024,
    this.maxTotalBytes = 64 * 1024 * 1024,
    this.maxAssets = 128,
  });

  final int maxAssetBytes;
  final int maxTotalBytes;
  final int maxAssets;

  Future<MarkdownExportAssetResult> stage({
    required MarkdownExportDocument document,
    required Directory exportRoot,
    required String activeFilePath,
    required String workspaceRoot,
    required MarkdownPdfCancellationToken cancellationToken,
  }) async {
    final assetDirectory = Directory(p.join(exportRoot.path, 'assets'));
    await assetDirectory.create();
    final assets = <String, String>{};
    final warnings = <MarkdownPdfWarning>[];
    var totalBytes = 0;
    var processedAssets = 0;

    for (final destination in document.imageDestinations.toSet()) {
      cancellationToken.throwIfCancelled();
      if (processedAssets >= maxAssets) {
        warnings.add(
          MarkdownPdfWarning(
            MarkdownPdfWarningCode.imageLimitReached,
            destination,
          ),
        );
        continue;
      }
      processedAssets++;
      final uri = parseSchemedUri(destination);
      if (uri != null && isRemoteResourceUriScheme(uri.scheme)) {
        warnings.add(
          MarkdownPdfWarning(
            MarkdownPdfWarningCode.remoteImageSkipped,
            destination,
          ),
        );
        continue;
      }
      if (uri != null && uri.scheme.toLowerCase() != 'file') {
        warnings.add(
          MarkdownPdfWarning(
            MarkdownPdfWarningCode.imageUnsupported,
            destination,
          ),
        );
        continue;
      }

      final resolverDestination = uri?.scheme.toLowerCase() == 'file'
          ? _fileUriPath(uri!)
          : destination;
      final resolved = resolverDestination == null
          ? null
          : resolveLocalImagePath(
              activeFilePath: activeFilePath,
              destination: resolverDestination,
              workspaceRoot: workspaceRoot.isEmpty ? null : workspaceRoot,
            );
      if (resolved == null) {
        warnings.add(
          MarkdownPdfWarning(MarkdownPdfWarningCode.imageNotFound, destination),
        );
        continue;
      }
      final extension = p.extension(resolved).toLowerCase();
      if (!const {
        '.png',
        '.jpg',
        '.jpeg',
        '.gif',
        '.svg',
      }.contains(extension)) {
        warnings.add(
          MarkdownPdfWarning(
            MarkdownPdfWarningCode.imageUnsupported,
            destination,
          ),
        );
        continue;
      }
      try {
        final size = await File(resolved).length();
        if (size > maxAssetBytes || totalBytes + size > maxTotalBytes) {
          warnings.add(
            MarkdownPdfWarning(
              MarkdownPdfWarningCode.imageTooLarge,
              destination,
            ),
          );
          continue;
        }
        final bytes = await File(resolved).readAsBytes();
        cancellationToken.throwIfCancelled();
        if (!hasExpectedFormat(bytes, extension)) {
          warnings.add(
            MarkdownPdfWarning(
              MarkdownPdfWarningCode.imageUnsupported,
              destination,
            ),
          );
          continue;
        }
        final name = '${sha256.convert(bytes)}$extension';
        final relativePath = p.posix.join('assets', name);
        final target = File(p.join(assetDirectory.path, name));
        if (!await target.exists()) {
          await target.writeAsBytes(bytes, flush: true);
          totalBytes += bytes.length;
        }
        assets[destination] = relativePath;
      } on Object {
        warnings.add(
          MarkdownPdfWarning(
            MarkdownPdfWarningCode.imageReadFailed,
            destination,
          ),
        );
      }
    }
    return MarkdownExportAssetResult(
      assets: Map.unmodifiable(assets),
      warnings: List.unmodifiable(warnings),
    );
  }

  String? _fileUriPath(Uri uri) {
    try {
      return uri.toFilePath();
    } on UnsupportedError {
      return null;
    }
  }

  /// Shared signature validation for offline export backends.
  bool hasExpectedFormat(List<int> bytes, String extension) {
    bool startsWith(List<int> signature) {
      if (bytes.length < signature.length) {
        return false;
      }
      for (var index = 0; index < signature.length; index++) {
        if (bytes[index] != signature[index]) {
          return false;
        }
      }
      return true;
    }

    return switch (extension) {
      '.png' => startsWith(const [
        0x89,
        0x50,
        0x4e,
        0x47,
        0x0d,
        0x0a,
        0x1a,
        0x0a,
      ]),
      '.jpg' || '.jpeg' => startsWith(const [0xff, 0xd8, 0xff]),
      '.gif' => startsWith('GIF8'.codeUnits),
      '.svg' => _looksLikeSafeSvg(bytes),
      _ => false,
    };
  }

  bool _looksLikeSafeSvg(List<int> bytes) {
    try {
      final source = utf8.decode(bytes);
      final normalizedSource = source.toLowerCase();
      if (normalizedSource.contains('<!doctype') ||
          normalizedSource.contains('<!entity') ||
          normalizedSource.contains('<?xml-stylesheet') ||
          normalizedSource.contains('@import')) {
        return false;
      }

      final document = xml.XmlDocument.parse(source);
      final root = document.rootElement;
      if (root.name.local.toLowerCase() != 'svg') {
        return false;
      }

      const blockedElements = {
        'script',
        'foreignobject',
        'iframe',
        'object',
        'embed',
        'audio',
        'video',
        'style',
        'link',
      };
      for (final element in <xml.XmlElement>[
        root,
        ...root.descendants.whereType<xml.XmlElement>(),
      ]) {
        if (blockedElements.contains(element.name.local.toLowerCase())) {
          return false;
        }
        for (final attribute in element.attributes) {
          final name = attribute.name.local.toLowerCase();
          final value = attribute.value.trim();
          if (name.startsWith('on') ||
              ((name == 'href' || name == 'src') &&
                  !_isSafeSvgReference(value)) ||
              !_hasOnlyLocalCssUrls(value)) {
            return false;
          }
        }
      }
      return true;
    } on Object {
      return false;
    }
  }

  bool _isSafeSvgReference(String value) {
    final normalized = value.toLowerCase();
    return value.isEmpty ||
        value.startsWith('#') ||
        normalized.startsWith('data:image/png;base64,') ||
        normalized.startsWith('data:image/jpeg;base64,') ||
        normalized.startsWith('data:image/gif;base64,');
  }

  bool _hasOnlyLocalCssUrls(String value) {
    for (final match in RegExp(
      r'''url\(\s*(['"]?)(.*?)\1\s*\)''',
      caseSensitive: false,
    ).allMatches(value)) {
      if (!(match.group(2) ?? '').trim().startsWith('#')) {
        return false;
      }
    }
    return true;
  }
}
