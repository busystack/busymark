import 'dart:async';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../clipboard/clipboard_models.dart';

const richClipboardChannelName = 'com.busymark.app/rich_clipboard';
const busyMarkClipboardTokenMimeType = 'application/x-busymark-token';
const maxRichClipboardBytes = 16 * 1024 * 1024;

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
  }) : _channel = channel,
       _createToken = createToken ?? const Uuid().v4;

  final MethodChannel _channel;
  final String Function() _createToken;
  final Map<String, RichClipboardData> _knownPayloads = {};
  Future<void>? _pendingWrite;

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
      final known = token == null ? null : _knownPayloads[token];
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
    _knownPayloads[token] = RichClipboardData(
      text: data.text,
      html: data.html,
      sourceText: data.sourceText,
      richFragment: data.richFragment,
      sessionOwned: true,
      token: token,
      origin: data.origin,
      mediaBytes: _copyMediaBytes(data.mediaBytes),
      mediaComplete: data.mediaComplete,
    );
    // Tokens only identify current-session immutable payloads. Bound stale
    // ownership records independently from Clipboard History retention.
    while (_knownPayloads.length > 128) {
      _knownPayloads.remove(_knownPayloads.keys.first);
    }
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

Map<String, Uint8List> _copyMediaBytes(Map<String, Uint8List> values) =>
    Map.unmodifiable({
      for (final entry in values.entries)
        entry.key: Uint8List.fromList(entry.value),
    });

final busyMarkRichClipboardService = RichClipboardService();
