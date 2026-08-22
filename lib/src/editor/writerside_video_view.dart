import 'dart:async';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../app/busymark_design.dart';
import '../app/busymark_glyphs.dart';
import '../app/localization.dart';
import '../writerside/writerside_video.dart';
import 'markdown_image_view.dart';
import 'writerside_video_player_host.dart';

class BusyMarkWritersideVideoView extends StatefulWidget {
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
    this.playerHost = const PlatformWritersideVideoPlayerHost(),
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
  final WritersideVideoPlayerHost playerHost;
  final double? width;
  final double? height;
  final bool miniPlayer;
  final String borderEffect;

  @override
  State<BusyMarkWritersideVideoView> createState() =>
      _BusyMarkWritersideVideoViewState();
}

class _BusyMarkWritersideVideoViewState
    extends State<BusyMarkWritersideVideoView> {
  static int _nextPlayerId = 0;

  final _playerBodyKey = GlobalKey();
  late final String _playerId = 'writerside-video-${_nextPlayerId++}';
  Timer? _layoutTimer;
  Rect? _lastRect;
  bool _starting = false;
  bool _playing = false;
  bool _syncing = false;
  int _generation = 0;

  @override
  void didUpdateWidget(BusyMarkWritersideVideoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source ||
        oldWidget.activeFilePath != widget.activeFilePath ||
        oldWidget.workspaceRoot != widget.workspaceRoot ||
        oldWidget.writersideRoot != widget.writersideRoot ||
        oldWidget.imagesDir != widget.imagesDir ||
        oldWidget.miniPlayer != widget.miniPlayer) {
      _stopPlayer(updateState: false);
      _starting = false;
      _playing = false;
    }
  }

  @override
  void dispose() {
    _generation += 1;
    _layoutTimer?.cancel();
    unawaited(widget.playerHost.hide(_playerId));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final poster = writersideVideoPreviewSource(
      widget.source,
      widget.previewSource,
    );
    final target = resolveWritersideVideoPlaybackSource(
      source: widget.source,
      activeFilePath: widget.activeFilePath,
      workspaceRoot: widget.workspaceRoot,
      writersideRoot: widget.writersideRoot,
      imagesDir: widget.imagesDir,
    );
    final radius = widget.borderEffect == 'rounded'
        ? BusyMarkRadius.md
        : BusyMarkRadius.sm;
    final border =
        widget.borderEffect == 'line' || widget.borderEffect == 'rounded'
        ? Border.all(color: colors.subtleBorder)
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = _videoSize(constraints.maxWidth);
        final body = _playing || _starting
            ? ColoredBox(
                key: _playerBodyKey,
                color: BusyMarkLinuxPalette.black,
                child: _starting
                    ? const Center(child: CircularProgressIndicator())
                    : const SizedBox.expand(),
              )
            : _posterCard(context, target, poster);
        return Align(
          alignment: AlignmentDirectional.centerStart,
          child: Semantics(
            button: !_playing,
            enabled: target != null,
            label: target == null
                ? context.l10n.videoUnavailable
                : context.l10n.openVideo,
            child: Tooltip(
              message: target == null
                  ? context.l10n.videoUnavailable
                  : context.l10n.openVideo,
              child: Container(
                width: size.width,
                height: size.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  border: border,
                ),
                clipBehavior: Clip.antiAlias,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: body,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _posterCard(
    BuildContext context,
    WritersideVideoPlaybackSource? target,
    String poster,
  ) {
    final colors = BusyMarkSurfaceColors.of(context);
    return Material(
      color: colors.panel,
      child: InkWell(
        onTap: target == null
            ? widget.onOpenFailed
            : () => _startPlayer(target),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (poster.isNotEmpty)
              MarkdownImageView(
                source: poster,
                alt: context.l10n.videoPreview,
                activeFilePath: widget.activeFilePath,
                workspaceRoot: widget.workspaceRoot,
                writersideRoot: widget.writersideRoot,
                imagesDir: widget.imagesDir,
                allowRemoteImages: widget.allowRemoteImages,
                onRemoteImageBlocked: widget.onRemoteImageBlocked,
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
            if (!widget.miniPlayer)
              Align(
                alignment: AlignmentDirectional.bottomStart,
                child: Container(
                  color: colors.panel.withValues(alpha: 0.9),
                  padding: const EdgeInsets.symmetric(
                    horizontal: BusyMarkSpacing.sm,
                    vertical: BusyMarkSpacing.xs,
                  ),
                  child: Text(
                    _videoLabel(widget.source, target),
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
    );
  }

  Size _videoSize(double availableWidth) {
    const defaultWidth = 700.0;
    const defaultAspectRatio = 16 / 9;
    final naturalWidth =
        widget.width ??
        (widget.height == null
            ? defaultWidth
            : widget.height! * defaultAspectRatio);
    final naturalHeight =
        widget.height ??
        (widget.width == null
            ? defaultWidth / defaultAspectRatio
            : widget.width! / defaultAspectRatio);
    final scale = availableWidth.isFinite && naturalWidth > availableWidth
        ? availableWidth / naturalWidth
        : 1.0;
    return Size(naturalWidth * scale, naturalHeight * scale);
  }

  Future<void> _startPlayer(WritersideVideoPlaybackSource source) async {
    if (_starting || _playing) {
      return;
    }
    final generation = ++_generation;
    setState(() => _starting = true);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || generation != _generation) {
      return;
    }
    final rect = _visiblePlayerRect();
    if (rect == null) {
      setState(() => _starting = false);
      widget.onOpenFailed?.call();
      return;
    }
    try {
      final shown = await widget.playerHost.show(
        WritersideVideoPlayerRequest(
          playerId: _playerId,
          source: source,
          rect: rect,
          miniPlayer: widget.miniPlayer,
          playLabel: context.l10n.openVideo,
          pauseLabel: context.l10n.pauseVideo,
          borderEffect: const {'line', 'rounded'}.contains(widget.borderEffect)
              ? widget.borderEffect
              : 'none',
        ),
      );
      if (!mounted || generation != _generation) {
        if (shown) {
          await widget.playerHost.hide(_playerId);
        }
        return;
      }
      if (!shown) {
        setState(() => _starting = false);
        widget.onOpenFailed?.call();
        return;
      }
      _lastRect = rect;
      setState(() {
        _starting = false;
        _playing = true;
      });
      _layoutTimer?.cancel();
      _layoutTimer = Timer.periodic(
        const Duration(milliseconds: 80),
        (_) => _syncPlayerRect(),
      );
    } on Object {
      if (mounted && generation == _generation) {
        setState(() => _starting = false);
        widget.onOpenFailed?.call();
      }
    }
  }

  Future<void> _syncPlayerRect() async {
    if (!_playing || !mounted || _syncing) {
      return;
    }
    final rect = _visiblePlayerRect();
    if (rect == null) {
      _stopPlayer();
      return;
    }
    final previous = _lastRect;
    if (previous != null && _rectNear(previous, rect)) {
      return;
    }
    _lastRect = rect;
    _syncing = true;
    try {
      if (!await widget.playerHost.update(_playerId, rect) && mounted) {
        _stopPlayer();
      }
    } on Object {
      if (mounted) {
        _stopPlayer();
      }
    } finally {
      _syncing = false;
    }
  }

  Rect? _visiblePlayerRect() {
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) {
      return null;
    }
    final bodyContext = _playerBodyKey.currentContext;
    final box = bodyContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) {
      return null;
    }
    final rect = box.localToGlobal(Offset.zero) & box.size;
    final windowRect = Offset.zero & MediaQuery.sizeOf(context);
    if (!_containsRect(windowRect, rect)) {
      return null;
    }
    final scrollable = Scrollable.maybeOf(context);
    final viewport = scrollable?.context.findRenderObject();
    if (viewport is RenderBox && viewport.attached && viewport.hasSize) {
      final viewportRect = viewport.localToGlobal(Offset.zero) & viewport.size;
      if (!_containsRect(viewportRect, rect)) {
        return null;
      }
    }
    return rect;
  }

  void _stopPlayer({bool updateState = true}) {
    _generation += 1;
    _layoutTimer?.cancel();
    _layoutTimer = null;
    _lastRect = null;
    _syncing = false;
    unawaited(widget.playerHost.hide(_playerId));
    if (updateState && mounted) {
      setState(() {
        _starting = false;
        _playing = false;
      });
    }
  }
}

bool _containsRect(Rect outer, Rect inner) {
  const tolerance = 0.5;
  return inner.left >= outer.left - tolerance &&
      inner.top >= outer.top - tolerance &&
      inner.right <= outer.right + tolerance &&
      inner.bottom <= outer.bottom + tolerance;
}

bool _rectNear(Rect first, Rect second) {
  const tolerance = 0.5;
  return (first.left - second.left).abs() < tolerance &&
      (first.top - second.top).abs() < tolerance &&
      (first.width - second.width).abs() < tolerance &&
      (first.height - second.height).abs() < tolerance;
}

String _videoLabel(String source, WritersideVideoPlaybackSource? target) {
  return switch (target?.kind) {
    WritersideVideoPlaybackKind.youtube => 'YouTube',
    WritersideVideoPlaybackKind.vimeo => 'Vimeo',
    WritersideVideoPlaybackKind.localFile => p.basename(target!.value),
    null => p.basename(source.trim().split('?').first),
  };
}
