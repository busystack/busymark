import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../app/busymark_glyphs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const gtkHeaderIconsChannelName = 'com.busymark.app/gtk_header_icons';
const gtkHeaderIconsChangedChannelName =
    'com.busymark.app/gtk_header_icons_changed';

@immutable
final class GtkHeaderIconAsset {
  const GtkHeaderIconAsset({
    required this.bytes,
    required this.resolvedName,
    required this.scale,
    required this.pixelWidth,
    required this.pixelHeight,
  });

  final Uint8List bytes;
  final String resolvedName;
  final int scale;
  final int pixelWidth;
  final int pixelHeight;
}

enum BusyMarkLinuxHeaderIcon {
  back,
  sidebar,
  search,
  searchEntryFind,
  searchClear,
  mainMenu,
  validate,
  viewEditor,
  viewSource,
  viewPreview,
  viewSplit,
  viewMenuArrow,
}

extension BusyMarkLinuxHeaderIconNames on BusyMarkLinuxHeaderIcon {
  List<String> get gtkNames => switch (this) {
    BusyMarkLinuxHeaderIcon.back => const ['go-previous-symbolic'],
    BusyMarkLinuxHeaderIcon.sidebar => const ['sidebar-show-symbolic'],
    BusyMarkLinuxHeaderIcon.search => const ['system-search-symbolic'],
    BusyMarkLinuxHeaderIcon.searchEntryFind => const ['edit-find-symbolic'],
    BusyMarkLinuxHeaderIcon.searchClear => const ['edit-clear-symbolic'],
    BusyMarkLinuxHeaderIcon.mainMenu => const ['open-menu-symbolic'],
    BusyMarkLinuxHeaderIcon.validate => const ['tools-check-spelling-symbolic'],
    BusyMarkLinuxHeaderIcon.viewEditor => const ['document-edit-symbolic'],
    BusyMarkLinuxHeaderIcon.viewSource => const ['text-x-generic-symbolic'],
    BusyMarkLinuxHeaderIcon.viewPreview => const [
      'view-reader-symbolic',
      'document-open-symbolic',
    ],
    BusyMarkLinuxHeaderIcon.viewSplit => const ['view-dual-symbolic'],
    BusyMarkLinuxHeaderIcon.viewMenuArrow => const ['pan-down-symbolic'],
  };
  bool get directionSensitive =>
      this == BusyMarkLinuxHeaderIcon.back ||
      this == BusyMarkLinuxHeaderIcon.sidebar;
  bool get allowMissing => true;
}

BusyMarkLinuxHeaderIcon? _nativeHeaderIcon(IconData glyph) => switch (glyph) {
  BusyMarkGlyphs.home => BusyMarkLinuxHeaderIcon.back,
  BusyMarkGlyphs.sidebar => BusyMarkLinuxHeaderIcon.sidebar,
  BusyMarkGlyphs.search => BusyMarkLinuxHeaderIcon.search,
  BusyMarkGlyphs.clear => BusyMarkLinuxHeaderIcon.searchClear,
  BusyMarkGlyphs.menuVertical => BusyMarkLinuxHeaderIcon.mainMenu,
  BusyMarkGlyphs.diagnostics => BusyMarkLinuxHeaderIcon.validate,
  BusyMarkGlyphs.editorView => BusyMarkLinuxHeaderIcon.viewEditor,
  BusyMarkGlyphs.sourceView => BusyMarkLinuxHeaderIcon.viewSource,
  BusyMarkGlyphs.previewView => BusyMarkLinuxHeaderIcon.viewPreview,
  BusyMarkGlyphs.splitView => BusyMarkLinuxHeaderIcon.viewSplit,
  _ => null,
};

/// Native symbolic artwork, with the existing Yaru glyph as a test/platform fallback.
class BusyMarkGtkHeaderIcon extends StatelessWidget {
  const BusyMarkGtkHeaderIcon(this.glyph, {super.key});
  final IconData glyph;
  @override
  Widget build(BuildContext context) {
    final icon = _nativeHeaderIcon(glyph);
    final asset = icon == null
        ? null
        : GtkHeaderIconScope.of(
            context,
          ).catalog.assetFor(icon, Directionality.of(context));
    if (asset == null) return Icon(glyph, size: 16);
    return ExcludeSemantics(
      child: Image.memory(
        asset.bytes,
        width: 16,
        height: 16,
        scale: asset.scale.toDouble(),
        color: IconTheme.of(context).color,
        colorBlendMode: BlendMode.srcIn,
        filterQuality: FilterQuality.none,
        gaplessPlayback: true,
      ),
    );
  }
}

final class GtkHeaderIconCatalog {
  GtkHeaderIconCatalog(
    Map<String, GtkHeaderIconAsset> assets, {
    required this.revision,
  }) : assets = UnmodifiableMapView(assets);

  GtkHeaderIconCatalog.empty() : assets = const {}, revision = 0;

  final Map<String, GtkHeaderIconAsset> assets;
  final int revision;

  int? get scale => assets.values.firstOrNull?.scale;

  GtkHeaderIconAsset? assetFor(
    BusyMarkLinuxHeaderIcon icon,
    TextDirection direction,
  ) => assets[_catalogKey(icon, direction)];
}

typedef GtkHeaderIconBatchLoader =
    Future<Object?> Function(List<Map<String, Object>> requests);

/// Cached Linux application-header artwork supplied by GTK's active icon
/// theme. A replacement catalog is published only after its full batch loads.
class GtkHeaderIconService extends ChangeNotifier {
  GtkHeaderIconService({
    MethodChannel methodChannel = const MethodChannel(
      gtkHeaderIconsChannelName,
    ),
    EventChannel changedEvents = const EventChannel(
      gtkHeaderIconsChangedChannelName,
    ),
  }) : _loadBatch = ((requests) =>
           methodChannel.invokeMethod<Object?>('loadIcons', requests)),
       _changedEvents = changedEvents.receiveBroadcastStream();

  @visibleForTesting
  GtkHeaderIconService.testing({
    GtkHeaderIconCatalog? initialCatalog,
    GtkHeaderIconBatchLoader? loadBatch,
    Stream<Object?>? changedEvents,
  }) : _catalog = initialCatalog ?? GtkHeaderIconCatalog.empty(),
       _loadBatch = loadBatch,
       _changedEvents = changedEvents;

  GtkHeaderIconService.fallback() : _loadBatch = null, _changedEvents = null;

  static final fallbackInstance = GtkHeaderIconService.fallback();

  final GtkHeaderIconBatchLoader? _loadBatch;
  final Stream<Object?>? _changedEvents;
  GtkHeaderIconCatalog _catalog = GtkHeaderIconCatalog.empty();
  StreamSubscription<Object?>? _subscription;
  bool _reloadRunning = false;
  int? _queuedRevision;
  int _highestSeenRevision = 0;
  int _reloadCount = 0;
  bool _disposed = false;

  GtkHeaderIconCatalog get catalog => _catalog;

  @visibleForTesting
  int get reloadCount => _reloadCount;

  Future<bool> initialize({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final loadBatch = _loadBatch;
    if (loadBatch == null) return false;
    _subscription ??= _changedEvents?.listen(
      _handleInvalidation,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('GTK header-icon invalidation stream failed: $error');
      },
    );
    _reloadRunning = true;
    try {
      var targetRevision = 0;
      while (true) {
        final loaded = await _loadCatalog(targetRevision).timeout(timeout);
        if (_disposed) return false;
        _catalog = loaded;
        notifyListeners();
        final queued = _queuedRevision;
        _queuedRevision = null;
        if (queued == null || queued <= targetRevision) {
          return loaded.assets.isNotEmpty;
        }
        targetRevision = queued;
      }
    } on Object catch (error) {
      debugPrint('GTK header-icon catalog preload failed: $error');
      return false;
    } finally {
      _reloadRunning = false;
    }
  }

  void _handleInvalidation(Object? event) {
    final revision = switch (event) {
      {'revision': final int value} => value,
      _ => _highestSeenRevision + 1,
    };
    if (revision <= _highestSeenRevision) return;
    _highestSeenRevision = revision;
    if (_reloadRunning) {
      _queuedRevision = revision;
      return;
    }
    unawaited(_reloadFromInvalidation(revision));
  }

  Future<void> _reloadFromInvalidation(int revision) async {
    _reloadRunning = true;
    var targetRevision = revision;
    try {
      while (!_disposed) {
        try {
          final replacement = await _loadCatalog(targetRevision);
          if (_disposed) return;
          _catalog = replacement;
          notifyListeners();
        } on Object catch (error) {
          debugPrint('GTK header-icon catalog refresh failed: $error');
        }
        final queued = _queuedRevision;
        _queuedRevision = null;
        if (queued == null || queued <= targetRevision) break;
        targetRevision = queued;
      }
    } finally {
      _reloadRunning = false;
    }
  }

  Future<GtkHeaderIconCatalog> _loadCatalog(int revision) async {
    final loadBatch = _loadBatch;
    if (loadBatch == null) return GtkHeaderIconCatalog.empty();
    _reloadCount += 1;
    final response = await loadBatch(_requests());
    if (response is! Map) {
      throw const FormatException('GTK header-icon response was not a map.');
    }
    final assets = <String, GtkHeaderIconAsset>{};
    for (final entry in response.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is! String || value is! Map) continue;
      final bytes = value['bytes'];
      final resolvedName = value['resolvedName'];
      final scale = value['scale'];
      final pixelWidth = value['pixelWidth'];
      final pixelHeight = value['pixelHeight'];
      if (bytes is! Uint8List ||
          resolvedName is! String ||
          scale is! int ||
          pixelWidth is! int ||
          pixelHeight is! int ||
          bytes.isEmpty ||
          scale < 1 ||
          pixelWidth < 1 ||
          pixelHeight < 1) {
        continue;
      }
      assets[key] = GtkHeaderIconAsset(
        bytes: bytes,
        resolvedName: resolvedName,
        scale: scale,
        pixelWidth: pixelWidth,
        pixelHeight: pixelHeight,
      );
    }
    if (assets.isEmpty) {
      throw const FormatException('GTK returned no usable header icons.');
    }
    return GtkHeaderIconCatalog(assets, revision: revision);
  }

  static List<Map<String, Object>> _requests() {
    return [
      for (final icon in BusyMarkLinuxHeaderIcon.values)
        for (final direction
            in icon.directionSensitive
                ? TextDirection.values
                : const [TextDirection.ltr])
          {
            'key': _catalogKey(icon, direction),
            'names': icon.gtkNames,
            'direction': direction == TextDirection.rtl ? 'rtl' : 'ltr',
            'allowMissing': icon.allowMissing,
          },
    ];
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription?.cancel());
    _subscription = null;
    super.dispose();
  }
}

String _catalogKey(BusyMarkLinuxHeaderIcon icon, TextDirection direction) {
  final effectiveDirection = icon.directionSensitive
      ? direction
      : TextDirection.ltr;
  return '${icon.name}.${effectiveDirection.name}';
}

final gtkHeaderIconServiceProvider = Provider<GtkHeaderIconService>((ref) {
  final service = GtkHeaderIconService.fallback();
  ref.onDispose(service.dispose);
  return service;
});

class GtkHeaderIconScope extends InheritedNotifier<GtkHeaderIconService> {
  const GtkHeaderIconScope({
    super.key,
    required GtkHeaderIconService service,
    required super.child,
  }) : super(notifier: service);

  static GtkHeaderIconService of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<GtkHeaderIconScope>()
            ?.notifier ??
        GtkHeaderIconService.fallbackInstance;
  }
}

String resolvedNativeHeaderIconName(
  BuildContext context,
  BusyMarkLinuxHeaderIcon icon,
) {
  final asset = GtkHeaderIconScope.of(
    context,
  ).catalog.assetFor(icon, Directionality.of(context));
  return asset?.resolvedName ?? icon.gtkNames.first;
}
