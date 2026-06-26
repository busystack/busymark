import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path/path.dart' as p;

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
    return ConstrainedBox(
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
    );
  }

  Widget? _imageForSource(BuildContext context, String source) {
    if (source.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(source);
    if (uri != null && uri.hasScheme) {
      if (uri.scheme == 'file') {
        return _fileImage(File.fromUri(uri), source, _isSvgPath(uri.path));
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
      return SvgPicture.file(
        file,
        width: width,
        height: height,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        placeholderBuilder: (context) => _MarkdownImagePlaceholder(
          source: source,
          alt: alt,
          height: height ?? 120,
        ),
      );
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
    return SvgPicture.network(
      source,
      width: width,
      height: height,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      placeholderBuilder: (context) => _MarkdownImagePlaceholder(
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
