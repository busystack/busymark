import 'dart:async';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import '../app/busymark_design.dart';
import '../app/busymark_glyphs.dart';
import '../app/localization.dart';
import '../writerside/writerside_video.dart';
import 'markdown_image_view.dart';

typedef BusyMarkVideoLauncher = Future<bool> Function(Uri uri);

class BusyMarkWritersideVideoView extends StatelessWidget {
  const BusyMarkWritersideVideoView({
    super.key,
    required this.source,
    required this.previewSource,
    required this.activeFilePath,
    required this.workspaceRoot,
    required this.writersideRoot,
    required this.imagesDir,
    required this.allowRemoteImages,
    this.onRemoteImageBlocked,
    this.onOpenFailed,
    this.launcher,
    this.width,
    this.height,
    this.miniPlayer = false,
    this.borderEffect = 'none',
  });

  final String source;
  final String? previewSource;
  final String activeFilePath;
  final String? workspaceRoot;
  final String? writersideRoot;
  final String imagesDir;
  final bool allowRemoteImages;
  final VoidCallback? onRemoteImageBlocked;
  final VoidCallback? onOpenFailed;
  final BusyMarkVideoLauncher? launcher;
  final double? width;
  final double? height;
  final bool miniPlayer;
  final String borderEffect;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final poster = writersideVideoPreviewSource(source, previewSource);
    final target = resolveWritersideVideoUri(
      source: source,
      activeFilePath: activeFilePath,
      workspaceRoot: workspaceRoot,
      writersideRoot: writersideRoot,
      imagesDir: imagesDir,
    );
    final radius = borderEffect == 'rounded'
        ? BusyMarkRadius.md
        : BusyMarkRadius.sm;
    final border = borderEffect == 'line' || borderEffect == 'rounded'
        ? Border.all(color: colors.subtleBorder)
        : null;
    final effectiveWidth = width?.clamp(160, 840).toDouble();
    final effectiveHeight = height?.clamp(90, 600).toDouble();
    final card = AspectRatio(
      aspectRatio: effectiveWidth != null && effectiveHeight != null
          ? effectiveWidth / effectiveHeight
          : 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Material(
          color: colors.panel,
          child: InkWell(
            onTap: target == null ? onOpenFailed : () => _open(target),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (poster.isNotEmpty)
                  MarkdownImageView(
                    source: poster,
                    alt: context.l10n.videoPreview,
                    activeFilePath: activeFilePath,
                    workspaceRoot: workspaceRoot,
                    writersideRoot: writersideRoot,
                    imagesDir: imagesDir,
                    allowRemoteImages: allowRemoteImages,
                    onRemoteImageBlocked: onRemoteImageBlocked,
                    maxWidth: 840,
                  )
                else
                  Center(
                    child: Icon(
                      BusyMarkGlyphs.video,
                      size: 48,
                      color: colors.mutedForeground,
                    ),
                  ),
                Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.view.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.subtleBorder),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(BusyMarkSpacing.smPlus),
                      child: Icon(
                        BusyMarkGlyphs.play,
                        color: target == null
                            ? colors.mutedForeground
                            : colors.foreground,
                      ),
                    ),
                  ),
                ),
                if (!miniPlayer)
                  Align(
                    alignment: AlignmentDirectional.bottomStart,
                    child: Container(
                      color: colors.panel.withValues(alpha: 0.9),
                      padding: const EdgeInsets.symmetric(
                        horizontal: BusyMarkSpacing.sm,
                        vertical: BusyMarkSpacing.xs,
                      ),
                      child: Text(
                        _videoLabel(source, target),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.mutedForeground,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    return Semantics(
      button: true,
      enabled: target != null,
      label: target == null
          ? context.l10n.videoUnavailable
          : context.l10n.openVideo,
      child: Tooltip(
        message: target == null
            ? context.l10n.videoUnavailable
            : context.l10n.openVideo,
        child: Container(
          width: effectiveWidth,
          height: effectiveHeight,
          constraints: BoxConstraints(
            maxWidth: effectiveWidth ?? 706,
            maxHeight: effectiveHeight ?? 397.125,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: border,
          ),
          clipBehavior: Clip.antiAlias,
          child: card,
        ),
      ),
    );
  }

  Future<void> _open(Uri target) async {
    final launch =
        launcher ??
        (uri) => launchUrl(uri, mode: LaunchMode.externalApplication);
    try {
      if (!await launch(target)) {
        onOpenFailed?.call();
      }
    } on Object {
      onOpenFailed?.call();
    }
  }
}

String _videoLabel(String source, Uri? target) {
  final host = target?.host.toLowerCase() ?? '';
  if (host == 'youtu.be' || host.contains('youtube')) {
    return 'YouTube';
  }
  if (host.contains('vimeo')) {
    return 'Vimeo';
  }
  final value = source.trim();
  return value.isEmpty ? '' : p.basename(value.split('?').first);
}
