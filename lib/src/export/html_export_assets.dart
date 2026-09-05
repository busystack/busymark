import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';
import '../visualization/generated_svg_normalizer.dart';
import 'markdown_export_assets.dart';
import 'html_export_models.dart';

/// One export's immutable, validated asset snapshot, keyed by content.
class HtmlExportAssets {
  HtmlExportAssets({
    required this.directory,
    required this.urlDirectory,
    required this.allowedRoots,
    required this.token,
    required this.warnings,
    this.limits = const HtmlExportLimits(),
  });
  final Directory directory;
  final String urlDirectory;
  final List<String> allowedRoots;
  final HtmlExportCancellationToken token;
  final List<HtmlExportWarning> warnings;
  final HtmlExportLimits limits;
  final Map<String, String?> _references = {};
  final Set<String> filenames = {};
  int _total = 0;

  Future<String?> local(
    String reference, {
    required String sourcePath,
    List<String> searchRoots = const [],
    int line = 1,
    bool download = false,
  }) async {
    token.check();
    final key =
        '$sourcePath\u0000${searchRoots.join('\u0000')}\u0000$download\u0000$reference';
    if (_references.containsKey(key)) return _references[key];
    String? result;
    try {
      final uri = Uri.tryParse(reference);
      if (uri == null ||
          (uri.hasScheme && uri.scheme != 'file') ||
          uri.hasAuthority) {
        throw const HtmlExportException(
          'Remote or unsupported resource was not packaged.',
        );
      }
      final path = uri.scheme == 'file'
          ? uri.toFilePath()
          : Uri.decodeComponent(uri.path);
      final candidates = p.isAbsolute(path)
          ? [path]
          : [
              p.join(p.dirname(sourcePath), path),
              for (final root in searchRoots) p.join(root, path),
            ];
      File? found;
      for (final candidate in candidates) {
        try {
          final canonical = await File(candidate).resolveSymbolicLinks();
          if (!allowedRoots.any((root) => p.isWithin(root, canonical))) {
            continue;
          }
          if (await FileSystemEntity.type(canonical, followLinks: false) ==
              FileSystemEntityType.file) {
            found = File(canonical);
            break;
          }
        } on FileSystemException {
          /* Try the next configured root. */
        }
      }
      if (found == null) {
        throw const HtmlExportException(
          'Resource is missing or outside the allowed source roots.',
        );
      }
      if (await found.length() > limits.assetBytes) {
        throw const HtmlExportException(
          'Resource exceeds the asset size limit.',
        );
      }
      final bytes = await found.readAsBytes();
      result = await bytesAsset(
        bytes,
        p.extension(found.path).toLowerCase(),
        download: download,
      );
    } on Object catch (error) {
      token.check();
      warnings.add(
        HtmlExportWarning(
          'asset.unavailable',
          '${p.basename(reference)}: ${error is HtmlExportException ? error.message : 'Resource could not be read.'}',
          sourcePath: sourcePath,
          line: line,
        ),
      );
    }
    _references[key] = result;
    return result;
  }

  Future<String> bytesAsset(
    List<int> input,
    String extension, {
    bool download = false,
  }) async {
    token.check();
    if (extension == '.jpeg') extension = '.jpg';
    var bytes = input;
    if (extension == '.svg') bytes = utf8.encode(safeSvg(utf8.decode(input)));
    final signature = const MarkdownExportAssetStager().hasExpectedFormat(
      bytes,
      extension,
    );
    final media =
        (extension == '.webp' &&
            bytes.length > 12 &&
            ascii.decode(bytes.sublist(0, 4), allowInvalid: true) == 'RIFF' &&
            ascii.decode(bytes.sublist(8, 12), allowInvalid: true) == 'WEBP') ||
        (extension == '.mp4' &&
            bytes.length > 12 &&
            ascii.decode(bytes.sublist(4, 8), allowInvalid: true) == 'ftyp') ||
        (extension == '.webm' &&
            bytes.length > 4 &&
            bytes[0] == 0x1a &&
            bytes[1] == 0x45 &&
            bytes[2] == 0xdf &&
            bytes[3] == 0xa3);
    final attachment =
        download &&
        const {
          '.pdf',
          '.zip',
          '.txt',
          '.csv',
          '.json',
          '.yaml',
          '.yml',
        }.contains(extension);
    if (!signature && !media && !attachment) {
      throw const HtmlExportException(
        'Unsupported or invalid resource format.',
      );
    }
    if (bytes.length > limits.assetBytes) {
      throw const HtmlExportException('Resource exceeds the asset size limit.');
    }
    final name = '${sha256.convert(bytes)}$extension';
    if (!filenames.contains(name)) {
      if (filenames.length >= limits.assets ||
          _total + bytes.length > limits.totalAssetBytes) {
        throw const HtmlExportException('The export asset limit was reached.');
      }
      await directory.create(recursive: true);
      await File(p.join(directory.path, name)).writeAsBytes(bytes, flush: true);
      filenames.add(name);
      _total += bytes.length;
    }
    return '${Uri.encodeComponent(urlDirectory)}/${Uri.encodeComponent(name)}';
  }

  static String safeSvg(String source) {
    // Reject active SVG before normalizing. Never silently accept a stripped script.
    if (RegExp(
      r'<!DOCTYPE|<!ENTITY|<\?xml-stylesheet',
      caseSensitive: false,
    ).hasMatch(source)) {
      throw const HtmlExportException('Unsafe SVG declaration.');
    }
    final doc = XmlDocument.parse(source);
    const tags = {
      'svg',
      'g',
      'defs',
      'path',
      'rect',
      'circle',
      'ellipse',
      'line',
      'polyline',
      'polygon',
      'text',
      'tspan',
      'textPath',
      'title',
      'desc',
      'use',
      'symbol',
      'clipPath',
      'mask',
      'linearGradient',
      'radialGradient',
      'stop',
      'marker',
      'pattern',
      'style',
      'filter',
      'feGaussianBlur',
      'feOffset',
      'feBlend',
      'feColorMatrix',
      'feComposite',
      'feFlood',
      'feMerge',
      'feMergeNode',
    };
    final elements = [
      doc.rootElement,
      ...doc.rootElement.descendants.whereType<XmlElement>(),
    ];
    if (elements.length > 50000) {
      throw const HtmlExportException('SVG is too complex.');
    }
    for (final el in elements) {
      if (!tags.contains(el.name.local)) {
        throw const HtmlExportException('Unsafe or unsupported SVG element.');
      }
      for (final a in el.attributes) {
        final name = a.name.local.toLowerCase();
        if (name.startsWith('on') ||
            name == 'base' ||
            ((name == 'href' || name == 'src') && !a.value.startsWith('#'))) {
          throw const HtmlExportException(
            'SVG contains an active or external reference.',
          );
        }
        if ({
          'style',
          'fill',
          'stroke',
          'filter',
          'clip-path',
          'mask',
          'cursor',
          'font-family',
          'marker-start',
          'marker-mid',
          'marker-end',
        }.contains(name)) {
          _safeCss(a.value);
        }
      }
      if (el.name.local == 'style') _safeCss(el.innerText);
    }
    final normalized = const GeneratedSvgNormalizer().normalize(source);
    final safe = normalized.vectorSafeSvg;
    if (safe == null || normalized.hasForeignObject) {
      throw const HtmlExportException(
        'SVG cannot be packaged as a standalone image.',
      );
    }
    return safe;
  }

  static void _safeCss(String value) {
    if (value.contains('\\') ||
        RegExp(
          r'@|expression\s*\(|-moz-binding|javascript:',
          caseSensitive: false,
        ).hasMatch(value)) {
      throw const HtmlExportException('Unsafe SVG CSS.');
    }
    for (final match in RegExp(
      r'''url\(\s*['"]?([^)'"\s]+)''',
      caseSensitive: false,
    ).allMatches(value)) {
      if (!match.group(1)!.startsWith('#')) {
        throw const HtmlExportException('SVG references an external resource.');
      }
    }
  }
}
