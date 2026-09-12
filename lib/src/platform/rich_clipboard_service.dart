import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../clipboard/clipboard_models.dart';

const richClipboardChannelName = 'com.busymark.app/rich_clipboard';
const busyMarkClipboardTokenMimeType = 'application/x-busymark-token';
const maxRichClipboardBytes = 16 * 1024 * 1024;
const maxRichClipboardOwnershipBytes = 64 * 1024 * 1024;
const maxRichClipboardOwnershipEntries = 128;

class RichClipboardData {
  const RichClipboardData({
    this.text,
    this.html,
    this.sourceText,
    this.richFragment,
    this.sessionOwned = false,
    this.token,
    this.generation,
    this.origin,
    this.mediaBytes = const {},
    this.mediaComplete = true,
  });

  final String? text;
  final String? html;
  final String? sourceText;
  final String? richFragment;
  final bool sessionOwned;
  final String? token;
  final int? generation;
  final BusyMarkClipboardOrigin? origin;
  final Map<String, Uint8List> mediaBytes;
  final bool mediaComplete;

  Map<String, String> toPlatformMap(String ownershipToken) => {
    if (text != null) 'text': text!,
    if (html != null) 'html': html!,
    'token': ownershipToken,
  };

  /// Used to reject an image obtained through the separate native image
  /// boundary if the clipboard owner changed between the two reads.
  bool sameExternalIdentity(RichClipboardData other) =>
      generation != null &&
      generation == other.generation &&
      token == other.token &&
      text == other.text &&
      html == other.html;
}

/// One write publishes all representations of the same immutable selection.
/// The platform owns the data, including after the originating Editor closes.
class RichClipboardService {
  RichClipboardService({
    MethodChannel channel = const MethodChannel(richClipboardChannelName),
    String Function()? createToken,
    int maximumOwnershipBytes = maxRichClipboardOwnershipBytes,
  }) : _channel = channel,
       _createToken = createToken ?? const Uuid().v4,
       _maximumOwnershipBytes = maximumOwnershipBytes,
       assert(maximumOwnershipBytes > 0);

  final MethodChannel _channel;
  final String Function() _createToken;
  final int _maximumOwnershipBytes;
  final Map<String, _OwnedRichClipboardData> _knownPayloads = {};
  Future<void>? _pendingWrite;

  @visibleForTesting
  int get retainedOwnershipBytes => _uniqueOwnershipBytes();

  @visibleForTesting
  int get retainedOwnershipEntries => _knownPayloads.length;

  /// Releases obsolete process-owned representations while preserving the
  /// newest token so an ordinary paste of the current clipboard remains rich.
  void discardObsoleteOwnership() {
    if (_knownPayloads.length <= 1) return;
    final newest = _knownPayloads.entries.last;
    _knownPayloads
      ..clear()
      ..[newest.key] = newest.value;
  }

  Future<bool> write(RichClipboardData data) {
    final result = _pendingWrite?.then((_) => _write(data)) ?? _write(data);
    final pending = result.then<void>((_) {});
    _pendingWrite = pending;
    unawaited(
      pending.whenComplete(() {
        if (identical(_pendingWrite, pending)) _pendingWrite = null;
      }),
    );
    return result;
  }

  Future<bool> _write(RichClipboardData data) async {
    final token = _createToken();
    try {
      final success =
          await _channel.invokeMethod<bool>(
            'write',
            data.toPlatformMap(token),
          ) ??
          false;
      if (success) _remember(token, data);
      return success;
    } on MissingPluginException {
      // Unsupported hosts can still exchange plain text. Never recover rich
      // data from a text-equality cache: a different copy may contain that text.
      try {
        await Clipboard.setData(ClipboardData(text: data.text ?? ''));
        // ClipboardData cannot publish the ownership token. Do not remember a
        // rich association that can never be proven on the next read.
        return true;
      } on PlatformException {
        return false;
      } on MissingPluginException {
        return false;
      }
    } on PlatformException {
      return false;
    }
  }

  Future<RichClipboardData> read() async {
    await _pendingWrite;
    try {
      final value = await _channel
          .invokeMapMethod<String, dynamic>('read')
          .timeout(const Duration(seconds: 5));
      String? field(String name) =>
          value?[name] is String ? value![name] as String : null;
      final generation = value?['generation'] is int
          ? value!['generation'] as int
          : null;
      final token = field('token');
      final known = token == null ? null : _knownPayloads[token]?.data;
      if (known == null) {
        return RichClipboardData(
          text: field('text'),
          html: field('html'),
          token: token,
          generation: generation,
        );
      }
      return RichClipboardData(
        text: field('text') ?? known.text,
        html: field('html') ?? known.html,
        sourceText: known.sourceText,
        richFragment: known.richFragment,
        sessionOwned: true,
        token: token,
        generation: generation,
        origin: known.origin,
        mediaBytes: known.mediaBytes,
        mediaComplete: known.mediaComplete,
      );
    } on MissingPluginException {
      return RichClipboardData(text: await readPlainText());
    } on PlatformException {
      return const RichClipboardData();
    } on TimeoutException {
      return const RichClipboardData();
    }
  }

  void _remember(String token, RichClipboardData data) {
    _OwnedRichClipboardData? owned;
    for (final candidate in _knownPayloads.values) {
      if (candidate.equivalentTo(data)) {
        owned = candidate;
        break;
      }
    }
    owned ??= _OwnedRichClipboardData.copyOf(data);
    _knownPayloads[token] = owned;
    // Preserve the newest/current token. Obsolete ownership data is bounded by
    // both token count and unique payload bytes. Equivalent repeated copies
    // share one immutable media snapshot instead of copying it per token.
    while (_knownPayloads.length > 1 &&
        (_knownPayloads.length > maxRichClipboardOwnershipEntries ||
            _uniqueOwnershipBytes() > _maximumOwnershipBytes)) {
      _knownPayloads.remove(_knownPayloads.keys.first);
    }
  }

  int _uniqueOwnershipBytes() {
    final unique = HashSet<_OwnedRichClipboardData>.identity();
    var bytes = 0;
    for (final value in _knownPayloads.values) {
      if (unique.add(value)) bytes += value.accountedBytes;
    }
    return bytes;
  }

  Future<String?> readPlainText() async {
    await _pendingWrite;
    try {
      return (await Clipboard.getData(
        Clipboard.kTextPlain,
      ).timeout(const Duration(seconds: 5)))?.text;
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    } on TimeoutException {
      return null;
    }
  }
}

class _OwnedRichClipboardData {
  _OwnedRichClipboardData.copyOf(RichClipboardData source)
    : data = RichClipboardData(
        text: source.text,
        html: source.html,
        sourceText: source.sourceText,
        richFragment: source.richFragment,
        sessionOwned: true,
        origin: source.origin,
        mediaBytes: _copyMediaBytes(source.mediaBytes),
        mediaComplete: source.mediaComplete,
      ),
      accountedBytes = _ownershipBytes(source);

  final RichClipboardData data;
  final int accountedBytes;

  bool equivalentTo(RichClipboardData other) =>
      data.text == other.text &&
      data.html == other.html &&
      data.sourceText == other.sourceText &&
      data.richFragment == other.richFragment &&
      data.origin?.documentId == other.origin?.documentId &&
      data.origin?.documentName == other.origin?.documentName &&
      data.origin?.documentPath == other.origin?.documentPath &&
      data.mediaComplete == other.mediaComplete &&
      _sameMediaBytes(data.mediaBytes, other.mediaBytes);
}

int _ownershipBytes(RichClipboardData data) {
  var bytes = 0;
  for (final value in [
    data.text,
    data.html,
    data.sourceText,
    data.richFragment,
    data.origin?.documentId,
    data.origin?.documentName,
    data.origin?.documentPath,
  ]) {
    if (value != null) bytes += utf8.encode(value).length;
  }
  for (final entry in data.mediaBytes.entries) {
    bytes += utf8.encode(entry.key).length + entry.value.lengthInBytes;
  }
  return bytes;
}

bool _sameMediaBytes(
  Map<String, Uint8List> first,
  Map<String, Uint8List> second,
) {
  if (first.length != second.length) return false;
  for (final entry in first.entries) {
    if (!listEquals(entry.value, second[entry.key])) return false;
  }
  return true;
}

Map<String, Uint8List> _copyMediaBytes(Map<String, Uint8List> values) =>
    Map.unmodifiable({
      for (final entry in values.entries)
        entry.key: Uint8List.fromList(entry.value),
    });

final busyMarkRichClipboardService = RichClipboardService();
