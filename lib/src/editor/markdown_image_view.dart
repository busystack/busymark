import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart' as xml;

import '../app/busymark_design.dart';
import '../app/busymark_glyphs.dart';
import '../app/localization.dart';
import '../core/local_image_resolver.dart';

class MarkdownImageView extends StatelessWidget {
  const MarkdownImageView({
    super.key,
    required this.source,
    required this.alt,
    required this.activeFilePath,
    required this.workspaceRoot,
    required this.writersideRoot,
    required this.imagesDir,
    this.width,
    this.height,
    this.maxWidth = 760,
    this.maxHeight,
  });

  final String source;
  final String alt;
  final String activeFilePath;
  final String? workspaceRoot;
  final String? writersideRoot;
  final String imagesDir;
  final double? width;
  final double? height;
  final double maxWidth;
  final double? maxHeight;

  @override
  Widget build(BuildContext context) {
    final trimmedSource = source.trim();
    final image = _imageForSource(context, trimmedSource);
    return DefaultTextStyle.merge(
      style: const TextStyle(
        decoration: TextDecoration.none,
        fontStyle: FontStyle.normal,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: maxHeight ?? double.infinity,
        ),
        child:
            image ??
            _MarkdownImagePlaceholder(
              source: trimmedSource,
              alt: alt,
              height: height ?? 120,
            ),
      ),
    );
  }

  Widget? _imageForSource(BuildContext context, String source) {
    if (source.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(source);
    if (uri != null && uri.hasScheme) {
      if (uri.scheme == 'file') {
        final resolvedPath = resolveLocalImagePath(
          activeFilePath: activeFilePath,
          destination: File.fromUri(uri).path,
          workspaceRoot: workspaceRoot,
          writersideRoot: writersideRoot,
          imagesDir: imagesDir,
        );
        if (resolvedPath == null) {
          return null;
        }
        return _fileImage(File(resolvedPath), source, _isSvgPath(resolvedPath));
      }
      if (uri.scheme == 'http' || uri.scheme == 'https') {
        if (_isSvgPath(uri.path)) {
          return _networkSvg(source);
        }
        return Image.network(
          source,
          width: width,
          height: height,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          errorBuilder: (context, error, stackTrace) =>
              _MarkdownImagePlaceholder(
                source: source,
                alt: alt,
                height: height ?? 120,
              ),
        );
      }
      return null;
    }
    final resolvedPath = resolveLocalImagePath(
      activeFilePath: activeFilePath,
      destination: source,
      workspaceRoot: workspaceRoot,
      writersideRoot: writersideRoot,
      imagesDir: imagesDir,
    );
    if (resolvedPath == null) {
      return null;
    }
    return _fileImage(File(resolvedPath), source, _isSvgPath(resolvedPath));
  }

  Widget _fileImage(File file, String source, bool svg) {
    if (!file.existsSync()) {
      return _MarkdownImagePlaceholder(
        source: source,
        alt: alt,
        height: height ?? 120,
      );
    }
    if (svg) {
      final svg = _readLocalSvgForFlutter(file);
      if (svg == null) {
        return _MarkdownImagePlaceholder(
          source: source,
          alt: alt,
          height: height ?? 120,
        );
      }
      final badge = svg.badge;
      if (badge != null) {
        return _SvgBadgeView(data: badge, width: width, height: height);
      }
      return _svgPicture(svg.source, source);
    }
    return Image.file(
      file,
      width: width,
      height: height,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      errorBuilder: (context, error, stackTrace) => _MarkdownImagePlaceholder(
        source: source,
        alt: alt,
        height: height ?? 120,
      ),
    );
  }

  Widget _networkSvg(String source) {
    return _NetworkSvgImage(
      source: source,
      alt: alt,
      width: width,
      height: height,
    );
  }

  Widget _svgPicture(String svgSource, String source) {
    return SvgPicture.string(
      svgSource,
      width: width,
      height: height,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      errorBuilder: (context, error, stackTrace) => _MarkdownImagePlaceholder(
        source: source,
        alt: alt,
        height: height ?? 120,
      ),
    );
  }
}

bool _isSvgPath(String value) {
  final path = value.split('#').first.split('?').first;
  return p.extension(path).toLowerCase() == '.svg';
}

class _NetworkSvgImage extends StatefulWidget {
  const _NetworkSvgImage({
    required this.source,
    required this.alt,
    required this.width,
    required this.height,
  });

  final String source;
  final String alt;
  final double? width;
  final double? height;

  @override
  State<_NetworkSvgImage> createState() => _NetworkSvgImageState();
}

class _NetworkSvgImageState extends State<_NetworkSvgImage> {
  late Future<_SvgImageSource?> _svgSource;

  @override
  void initState() {
    super.initState();
    _svgSource = _loadNetworkSvgForFlutter(widget.source);
  }

  @override
  void didUpdateWidget(covariant _NetworkSvgImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) {
      _svgSource = _loadNetworkSvgForFlutter(widget.source);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_SvgImageSource?>(
      future: _svgSource,
      builder: (context, snapshot) {
        final svg = snapshot.data;
        if (snapshot.connectionState == ConnectionState.done && svg != null) {
          final badge = svg.badge;
          if (badge != null) {
            return _SvgBadgeView(
              data: badge,
              width: widget.width,
              height: widget.height,
            );
          }
          return SvgPicture.string(
            svg.source,
            width: widget.width,
            height: widget.height,
            fit: BoxFit.contain,
            alignment: Alignment.center,
            errorBuilder: (context, error, stackTrace) =>
                _MarkdownImagePlaceholder(
                  source: widget.source,
                  alt: widget.alt,
                  height: widget.height ?? 120,
                ),
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return SizedBox(height: widget.height ?? _defaultRemoteSvgHeight);
        }
        return _MarkdownImagePlaceholder(
          source: widget.source,
          alt: widget.alt,
          height: widget.height ?? 120,
        );
      },
    );
  }
}

_SvgImageSource? _readLocalSvgForFlutter(File file) {
  try {
    final source = file.readAsStringSync();
    final sanitized = _svgForFlutter(source);
    if (sanitized == null) {
      return null;
    }
    return _SvgImageSource(
      source: sanitized,
      badge:
          _SvgBadgeData.tryParse(source) ?? _SvgBadgeData.tryParse(sanitized),
    );
  } on Object {
    return null;
  }
}

Future<_SvgImageSource?> _loadNetworkSvgForFlutter(String source) async {
  final uri = Uri.tryParse(source);
  if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
    return null;
  }
  final client = HttpClient();
  try {
    final request = await client.getUrl(uri).timeout(_networkSvgTimeout);
    final response = await request.close().timeout(_networkSvgTimeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }
    final expectedLength = response.contentLength;
    if (expectedLength > _maxSvgBytes) {
      return null;
    }
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in response.timeout(_networkSvgTimeout)) {
      bytes.add(chunk);
      if (bytes.length > _maxSvgBytes) {
        return null;
      }
    }
    final rawSource = utf8.decode(bytes.takeBytes());
    final sanitized = _svgForFlutter(rawSource);
    if (sanitized == null) {
      return null;
    }
    return _SvgImageSource(
      source: sanitized,
      badge:
          _SvgBadgeData.tryParse(rawSource) ??
          _SvgBadgeData.tryParse(sanitized),
    );
  } on Object {
    return null;
  } finally {
    client.close(force: true);
  }
}

class _SvgImageSource {
  const _SvgImageSource({required this.source, required this.badge});

  final String source;
  final _SvgBadgeData? badge;
}

class _SvgBadgeData {
  const _SvgBadgeData({
    required this.width,
    required this.height,
    required this.radius,
    required this.icon,
    required this.segments,
  });

  final double width;
  final double height;
  final double radius;
  final _SvgBadgeIcon? icon;
  final List<_SvgBadgeSegment> segments;

  static _SvgBadgeData? tryParse(String source) {
    try {
      final document = xml.XmlDocument.parse(source);
      final root = document.rootElement;
      if (root.name.local != 'svg') {
        return null;
      }
      final width = _parseSvgNumber(root.getAttribute('width'));
      final height = _parseSvgNumber(root.getAttribute('height'));
      if (width == null || height == null || height > 32) {
        return null;
      }

      final labels = root.descendants
          .whereType<xml.XmlElement>()
          .where((element) => element.name.local == 'text')
          .where(_isVisibleBadgeText)
          .map((element) => element.innerText.trim())
          .where((label) => label.isNotEmpty)
          .toList(growable: false);
      if (labels.length < 2) {
        return null;
      }

      final rects =
          root.descendants
              .whereType<xml.XmlElement>()
              .where((element) => element.name.local == 'rect')
              .where((element) => !_hasAncestorNamed(element, 'clipPath'))
              .map((element) => _SvgBadgeRect.tryParse(element))
              .whereType<_SvgBadgeRect>()
              .where((rect) => rect.width > 0)
              .toList()
            ..sort((a, b) => a.x.compareTo(b.x));
      if (rects.length < 2) {
        return null;
      }

      final segments = <_SvgBadgeSegment>[];
      for (var i = 0; i < labels.length && i < rects.length; i += 1) {
        segments.add(
          _SvgBadgeSegment(
            x: rects[i].x,
            width: rects[i].width,
            color: rects[i].color,
            label: labels[i],
          ),
        );
      }
      if (segments.length < 2) {
        return null;
      }

      return _SvgBadgeData(
        width: width,
        height: height,
        radius: _badgeRadius(root),
        icon: _badgeIcon(root),
        segments: segments,
      );
    } on Object {
      return null;
    }
  }
}

class _SvgBadgeIcon {
  const _SvgBadgeIcon({
    required this.source,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final String source;
  final double x;
  final double y;
  final double width;
  final double height;
}

class _SvgBadgeSegment {
  const _SvgBadgeSegment({
    required this.x,
    required this.width,
    required this.color,
    required this.label,
  });

  final double x;
  final double width;
  final Color color;
  final String label;
}

class _SvgBadgeRect {
  const _SvgBadgeRect({
    required this.x,
    required this.width,
    required this.color,
  });

  final double x;
  final double width;
  final Color color;

  static _SvgBadgeRect? tryParse(xml.XmlElement element) {
    final fill = element.getAttribute('fill');
    if (fill == null || fill.startsWith('url(')) {
      return null;
    }
    final color = _parseSvgColor(fill);
    final width = _parseSvgNumber(element.getAttribute('width'));
    if (color == null || width == null) {
      return null;
    }
    return _SvgBadgeRect(
      x: _parseSvgNumber(element.getAttribute('x')) ?? 0,
      width: width,
      color: color,
    );
  }
}

class _SvgBadgeView extends StatelessWidget {
  const _SvgBadgeView({
    required this.data,
    required this.width,
    required this.height,
  });

  final _SvgBadgeData data;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final badge = SizedBox(
      width: data.width,
      height: data.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(data.radius),
        child: Stack(
          children: [
            for (final segment in data.segments)
              Positioned(
                left: segment.x,
                top: 0,
                width: segment.width,
                height: data.height,
                child: ColoredBox(
                  color: segment.color,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: _badgeTextLeftPadding(data.icon, segment),
                      right: _badgeHorizontalPadding,
                    ),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          segment.label,
                          maxLines: 1,
                          style: TextStyle(
                            color: BusyMarkLinuxPalette.white,
                            fontSize: data.height * 0.55,
                            fontStyle: FontStyle.normal,
                            fontWeight: FontWeight.normal,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (data.icon case final icon?)
              Positioned(
                left: icon.x,
                top: icon.y,
                width: icon.width,
                height: icon.height,
                child: SvgPicture.string(
                  icon.source,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                ),
              ),
          ],
        ),
      ),
    );
    if (width == null && height == null) {
      return badge;
    }
    return SizedBox(
      width: width ?? data.width,
      height: height ?? data.height,
      child: FittedBox(fit: BoxFit.contain, child: badge),
    );
  }
}

double _badgeTextLeftPadding(_SvgBadgeIcon? icon, _SvgBadgeSegment segment) {
  if (icon == null ||
      icon.x < segment.x ||
      icon.x >= segment.x + segment.width) {
    return _badgeHorizontalPadding;
  }
  return icon.x + icon.width + _badgeIconTextGap - segment.x;
}

bool _isVisibleBadgeText(xml.XmlElement element) {
  final fillOpacity = _parseSvgNumber(element.getAttribute('fill-opacity'));
  if (fillOpacity != null && fillOpacity < 1) {
    return false;
  }
  final opacity = _parseSvgNumber(element.getAttribute('opacity'));
  return opacity == null || opacity > 0;
}

bool _hasAncestorNamed(xml.XmlElement element, String name) {
  for (var node = element.parent; node != null; node = node.parent) {
    if (node is xml.XmlElement && node.name.local == name) {
      return true;
    }
  }
  return false;
}

double _badgeRadius(xml.XmlElement root) {
  for (final rect in root.descendants.whereType<xml.XmlElement>()) {
    if (rect.name.local != 'rect') {
      continue;
    }
    final radius = _parseSvgNumber(rect.getAttribute('rx'));
    if (radius != null && radius > 0) {
      return radius;
    }
  }
  return 3;
}

_SvgBadgeIcon? _badgeIcon(xml.XmlElement root) {
  for (final image in root.descendants.whereType<xml.XmlElement>()) {
    if (image.name.local != 'image') {
      continue;
    }
    final href = _imageHref(image);
    if (href == null) {
      continue;
    }
    final embeddedSvg = _decodeEmbeddedSvgDataUri(href);
    if (embeddedSvg == null) {
      continue;
    }
    final iconSource = _svgIconForFlutter(embeddedSvg);
    if (iconSource == null) {
      continue;
    }
    final width = _parseSvgNumber(image.getAttribute('width'));
    final height = _parseSvgNumber(image.getAttribute('height'));
    if (width == null || height == null || width <= 0 || height <= 0) {
      continue;
    }
    return _SvgBadgeIcon(
      source: iconSource,
      x: _parseSvgNumber(image.getAttribute('x')) ?? 0,
      y: _parseSvgNumber(image.getAttribute('y')) ?? 0,
      width: width,
      height: height,
    );
  }
  return null;
}

String? _svgIconForFlutter(String source) {
  try {
    final document = xml.XmlDocument.parse(source);
    final root = document.rootElement;
    if (root.name.local != 'svg') {
      return null;
    }
    final unsupported = root.descendants
        .whereType<xml.XmlElement>()
        .where(
          (element) =>
              element.name.local == 'style' || element.name.local == 'defs',
        )
        .toList();
    for (final element in unsupported) {
      element.remove();
    }
    for (final path in root.descendants.whereType<xml.XmlElement>()) {
      if (path.name.local != 'path') {
        continue;
      }
      if (path.getAttribute('fill') == null) {
        path.setAttribute('fill', '#fff');
      }
      path.removeAttribute('class');
    }
    return document.toXmlString();
  } on Object {
    return null;
  }
}

Color? _parseSvgColor(String value) {
  final trimmed = value.trim();
  if (!trimmed.startsWith('#')) {
    return null;
  }
  final hex = trimmed.substring(1);
  if (hex.length == 3) {
    final r = hex[0] * 2;
    final g = hex[1] * 2;
    final b = hex[2] * 2;
    return _parseSvgColor('#$r$g$b');
  }
  if (hex.length == 6) {
    final rgb = int.tryParse(hex, radix: 16);
    return rgb == null ? null : BusyMarkLinuxPalette.fromArgb(0xFF000000 | rgb);
  }
  if (hex.length == 8) {
    final argb = int.tryParse(hex, radix: 16);
    return argb == null ? null : BusyMarkLinuxPalette.fromArgb(argb);
  }
  return null;
}

String? _svgForFlutter(String source) {
  if (!source.toLowerCase().contains('<image')) {
    return source;
  }
  try {
    final document = xml.XmlDocument.parse(source);
    var changed = false;
    final images = document.descendants
        .whereType<xml.XmlElement>()
        .where((element) => element.name.local == 'image')
        .toList();

    for (final image in images) {
      final href = _imageHref(image);
      if (href == null) {
        continue;
      }
      final embeddedSvg = _decodeEmbeddedSvgDataUri(href);
      if (embeddedSvg != null) {
        final inlineSvg = _inlineEmbeddedSvg(image, embeddedSvg);
        if (inlineSvg != null) {
          image.replace(inlineSvg);
        } else {
          image.remove();
        }
        changed = true;
        continue;
      }
      if (_isUnsupportedSvgImageReference(href)) {
        image.remove();
        changed = true;
      }
    }

    return changed ? document.toXmlString() : source;
  } on Object {
    return null;
  }
}

String? _imageHref(xml.XmlElement element) {
  return element.getAttribute('href', namespaceUri: '*') ??
      element.getAttribute('href') ??
      element.getAttribute('xlink:href');
}

String? _decodeEmbeddedSvgDataUri(String href) {
  final trimmed = href.trim();
  final lower = trimmed.toLowerCase();
  if (!lower.startsWith('data:')) {
    return null;
  }
  final comma = trimmed.indexOf(',');
  if (comma < 0) {
    return null;
  }
  final metadata = lower.substring(5, comma).replaceAll(RegExp(r'\s+'), '');
  final metadataParts = metadata.split(';');
  if (metadataParts.isEmpty || metadataParts.first != 'image/svg+xml') {
    return null;
  }
  final payload = trimmed.substring(comma + 1);
  try {
    if (metadataParts.contains('base64')) {
      return utf8.decode(base64.decode(payload));
    }
    return Uri.decodeComponent(payload);
  } on Object {
    return null;
  }
}

xml.XmlElement? _inlineEmbeddedSvg(xml.XmlElement image, String embeddedSvg) {
  try {
    final document = xml.XmlDocument.parse(embeddedSvg);
    final svg = document.rootElement;
    if (svg.name.local != 'svg') {
      return null;
    }
    final x = _parseSvgNumber(image.getAttribute('x')) ?? 0;
    final y = _parseSvgNumber(image.getAttribute('y')) ?? 0;
    final width =
        _parseSvgNumber(image.getAttribute('width')) ??
        _parseSvgNumber(svg.getAttribute('width'));
    final height =
        _parseSvgNumber(image.getAttribute('height')) ??
        _parseSvgNumber(svg.getAttribute('height'));
    final viewBox =
        _parseSvgViewBox(svg.getAttribute('viewBox')) ??
        _SvgViewBox(0, 0, width, height);
    if (width == null ||
        height == null ||
        viewBox.width == null ||
        viewBox.height == null ||
        viewBox.width == 0 ||
        viewBox.height == 0) {
      return null;
    }
    final transform = [
      if (x != 0 || y != 0) 'translate($x $y)',
      'scale(${width / viewBox.width!} ${height / viewBox.height!})',
      if (viewBox.x != 0 || viewBox.y != 0)
        'translate(${-viewBox.x} ${-viewBox.y})',
    ].join(' ');
    return xml.XmlElement.tag(
      'g',
      attributes: [xml.XmlAttribute(xml.XmlName.parts('transform'), transform)],
      children: svg.children.map((node) => node.copy()),
      isSelfClosing: false,
    );
  } on Object {
    return null;
  }
}

double? _parseSvgNumber(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty || trimmed.endsWith('%')) {
    return null;
  }
  final normalized = trimmed.endsWith('px')
      ? trimmed.substring(0, trimmed.length - 2)
      : trimmed;
  return double.tryParse(normalized);
}

_SvgViewBox? _parseSvgViewBox(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  final parts = trimmed
      .split(RegExp(r'[\s,]+'))
      .map(double.tryParse)
      .toList(growable: false);
  if (parts.length != 4 || parts.any((part) => part == null)) {
    return null;
  }
  return _SvgViewBox(parts[0]!, parts[1]!, parts[2], parts[3]);
}

class _SvgViewBox {
  const _SvgViewBox(this.x, this.y, this.width, this.height);

  final double x;
  final double y;
  final double? width;
  final double? height;
}

bool _isUnsupportedSvgImageReference(String href) {
  final trimmed = href.trim().toLowerCase();
  if (!trimmed.startsWith('data:')) {
    return true;
  }
  final comma = trimmed.indexOf(',');
  if (comma < 0) {
    return true;
  }
  final metadata = trimmed.substring(5, comma).replaceAll(RegExp(r'\s+'), '');
  final mimeType = metadata.split(';').first;
  return !_supportedSvgImageMimeTypes.contains(mimeType);
}

const _supportedSvgImageMimeTypes = {
  'image/png',
  'image/jpeg',
  'image/jpg',
  'image/webp',
  'image/gif',
  'image/bmp',
};

const _networkSvgTimeout = Duration(seconds: 10);
const _maxSvgBytes = 1024 * 1024;
const _defaultRemoteSvgHeight = 24.0;
const _badgeHorizontalPadding = 4.0;
const _badgeIconTextGap = 4.0;

class _MarkdownImagePlaceholder extends StatelessWidget {
  const _MarkdownImagePlaceholder({
    required this.source,
    required this.alt,
    required this.height,
  });

  final String source;
  final String alt;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final label = source.isEmpty
        ? context.l10n.noImageSource
        : alt.trim().isEmpty
        ? source
        : '$alt\n$source';
    return SizedBox(
      height: height,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(BusyMarkSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                BusyMarkGlyphs.imageMissing,
                size: BusyMarkSizes.iconMd,
                color: colors.mutedForeground,
              ),
              const SizedBox(height: BusyMarkSpacing.xs),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.mutedForeground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
