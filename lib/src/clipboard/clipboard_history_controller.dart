import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../app/app_settings.dart';
import '../assets/asset_input_service.dart';
import '../platform/rich_clipboard_service.dart';
import 'clipboard_insertion.dart';
import 'clipboard_models.dart';

class ClipboardHistoryState {
  const ClipboardHistoryState({
    this.entries = const [],
    this.currentClipboard,
    this.refreshing = false,
    this.clipboardAvailable = true,
    this.lastRetentionResult,
  });

  final List<BusyMarkClipboardPayload> entries;
  final BusyMarkClipboardPayload? currentClipboard;
  final bool refreshing;
  final bool clipboardAvailable;
  final ClipboardRetentionResult? lastRetentionResult;

  int get retainedBytes =>
      entries.fold(0, (total, entry) => total + entry.accountedBytes);

  ClipboardHistoryState copyWith({
    List<BusyMarkClipboardPayload>? entries,
    Object? currentClipboard = _unset,
    bool? refreshing,
    bool? clipboardAvailable,
    Object? lastRetentionResult = _unset,
  }) {
    return ClipboardHistoryState(
      entries: entries ?? this.entries,
      currentClipboard: identical(currentClipboard, _unset)
          ? this.currentClipboard
          : currentClipboard as BusyMarkClipboardPayload?,
      refreshing: refreshing ?? this.refreshing,
      clipboardAvailable: clipboardAvailable ?? this.clipboardAvailable,
      lastRetentionResult: identical(lastRetentionResult, _unset)
          ? this.lastRetentionResult
          : lastRetentionResult as ClipboardRetentionResult?,
    );
  }
}

const Object _unset = Object();

final richClipboardServiceProvider = Provider<RichClipboardService>(
  (ref) => busyMarkRichClipboardService,
);

final clipboardAssetInputServiceProvider = Provider<AssetInputService>(
  (ref) => busyMarkAssetInputService,
);

final clipboardHistoryPolicyProvider = Provider<ClipboardHistoryPolicy>(
  (ref) => const ClipboardHistoryPolicy(),
);

final clipboardInsertionRegistryProvider =
    ChangeNotifierProvider<BusyMarkClipboardInsertionRegistry>(
      (ref) => BusyMarkClipboardInsertionRegistry(),
    );

final clipboardHistoryControllerProvider =
    NotifierProvider<ClipboardHistoryController, ClipboardHistoryState>(
      ClipboardHistoryController.new,
    );

final clipboardHistoryOpenRequestProvider =
    NotifierProvider<ClipboardHistoryOpenRequestController, int>(
      ClipboardHistoryOpenRequestController.new,
    );

class ClipboardHistoryOpenRequestController extends Notifier<int> {
  @override
  int build() => 0;

  void request() => state++;
}

class ClipboardHistoryController extends Notifier<ClipboardHistoryState> {
  late RichClipboardService _clipboard;
  late AssetInputService _assetInput;
  late ClipboardHistoryPolicy _policy;
  var _refreshGeneration = 0;

  @override
  ClipboardHistoryState build() {
    _clipboard = ref.read(richClipboardServiceProvider);
    _assetInput = ref.read(clipboardAssetInputServiceProvider);
    _policy = ref.read(clipboardHistoryPolicyProvider);
    return const ClipboardHistoryState();
  }

  bool get collectionEnabled =>
      ref.read(appSettingsControllerProvider).clipboardHistoryEnabled;

  ClipboardRetentionResult retain(BusyMarkClipboardCapture capture) {
    if (!collectionEnabled) {
      state = state.copyWith(
        lastRetentionResult: ClipboardRetentionResult.disabled,
      );
      return ClipboardRetentionResult.disabled;
    }
    if (!capture.isSupported) return ClipboardRetentionResult.oversized;
    final payload = _payload(capture);
    if (payload.accountedBytes > _policy.maximumBytes) {
      state = state.copyWith(
        lastRetentionResult: ClipboardRetentionResult.oversized,
      );
      return ClipboardRetentionResult.oversized;
    }
    final existing = state.entries
        .where((entry) => entry.equivalentTo(payload))
        .firstOrNull;
    final newest = existing ?? payload;
    final retained = <BusyMarkClipboardPayload>[
      newest,
      for (final entry in state.entries)
        if (!identical(entry, existing)) entry,
    ];
    var retainedBytes = retained.fold<int>(
      0,
      (total, entry) => total + entry.accountedBytes,
    );
    while (retained.length > _policy.maximumEntries ||
        retainedBytes > _policy.maximumBytes) {
      retainedBytes -= retained.removeLast().accountedBytes;
    }
    final result = existing == null
        ? ClipboardRetentionResult.retained
        : ClipboardRetentionResult.deduplicated;
    state = state.copyWith(
      entries: List.unmodifiable(retained),
      lastRetentionResult: result,
    );
    return result;
  }

  void remove(String id) {
    state = state.copyWith(
      entries: List.unmodifiable(
        state.entries.where((entry) => entry.id != id),
      ),
      lastRetentionResult: null,
    );
  }

  void clear() {
    _clipboard.discardObsoleteOwnership();
    state = state.copyWith(entries: const [], lastRetentionResult: null);
  }

  Future<void> refreshCurrentClipboard() async {
    final generation = ++_refreshGeneration;
    state = state.copyWith(refreshing: true);
    final first = await _clipboard.read();
    if (generation != _refreshGeneration || !ref.mounted) return;

    BusyMarkClipboardCapture? capture;
    if (first.richFragment != null ||
        first.sourceText != null ||
        first.html != null) {
      capture = BusyMarkClipboardCapture(
        kind: BusyMarkClipboardContentKind.richText,
        text: first.text,
        sourceText: first.sourceText,
        html: first.html,
        richFragment: first.richFragment,
        mediaBytes: first.mediaBytes,
        mediaComplete: first.mediaComplete,
        origin: first.origin,
        external: !first.sessionOwned,
      );
    } else if (first.text != null) {
      capture = BusyMarkClipboardCapture(
        kind: BusyMarkClipboardContentKind.text,
        text: first.text,
        sourceText: first.text,
        origin: first.origin,
        external: !first.sessionOwned,
      );
    } else {
      final image = await _readCurrentImage();
      final second = await _clipboard.read();
      if (generation != _refreshGeneration || !ref.mounted) return;
      // An image read uses the existing asset boundary. Re-read the rich
      // boundary and discard the image if ownership changed in between.
      if (image != null && first.sameExternalIdentity(second)) {
        capture = BusyMarkClipboardCapture(
          kind: BusyMarkClipboardContentKind.image,
          imageBytes: image.bytes,
          imageMimeType: image.mimeType,
          imageDisplayName: image.name,
          external: true,
        );
      }
    }
    state = state.copyWith(
      currentClipboard: capture == null ? null : _payload(capture),
      refreshing: false,
      clipboardAvailable: capture != null,
    );
  }

  /// Makes a transient external item retained only after a successful paste.
  void retainCurrentAfterPaste(BusyMarkClipboardPayload payload) {
    if (!payload.external) return;
    retain(
      BusyMarkClipboardCapture(
        kind: payload.kind,
        text: payload.text,
        sourceText: payload.sourceText,
        html: payload.html,
        richFragment: payload.richFragment,
        mediaBytes: payload.mediaBytes,
        mediaComplete: payload.mediaComplete,
        imageBytes: payload.imageBytes,
        imageMimeType: payload.imageMimeType,
        imageDisplayName: payload.imageDisplayName,
        imageWidth: payload.imageWidth,
        imageHeight: payload.imageHeight,
        origin: payload.origin,
        external: true,
      ),
    );
  }

  BusyMarkClipboardPayload _payload(BusyMarkClipboardCapture capture) {
    return BusyMarkClipboardPayload(
      id: const Uuid().v4(),
      acquiredAt: DateTime.now(),
      kind: capture.kind,
      text: capture.text,
      sourceText: capture.sourceText,
      html: capture.html,
      richFragment: capture.richFragment,
      imageBytes: capture.imageBytes,
      imageMimeType: capture.imageMimeType,
      imageDisplayName: capture.imageDisplayName,
      imageWidth: capture.imageWidth,
      imageHeight: capture.imageHeight,
      origin: capture.origin,
      mediaBytes: capture.mediaBytes,
      mediaComplete: capture.mediaComplete,
      external: capture.external,
    );
  }

  Future<({Uint8List bytes, String mimeType, String name})?>
  _readCurrentImage() async {
    final png = await _assetInput.readClipboardImagePng();
    if (png != null && png.isNotEmpty && png.length <= _policy.maximumBytes) {
      return (bytes: png, mimeType: 'image/png', name: 'clipboard-image.png');
    }
    final files = await _assetInput.readClipboardImageFiles();
    if (files.isEmpty) return null;
    final path = files.first;
    try {
      final file = File(path);
      final size = await file.length();
      if (size <= 0 || size > _policy.maximumBytes) return null;
      final bytes = await file.readAsBytes();
      final extension = p.extension(path).toLowerCase();
      final mimeType = switch (extension) {
        '.jpg' || '.jpeg' => 'image/jpeg',
        '.gif' => 'image/gif',
        '.webp' => 'image/webp',
        '.bmp' => 'image/bmp',
        '.svg' => 'image/svg+xml',
        _ => 'image/png',
      };
      return (bytes: bytes, mimeType: mimeType, name: p.basename(path));
    } on FileSystemException {
      return null;
    }
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
