import 'dart:async';

import 'package:flutter/services.dart';

const richClipboardChannelName = 'com.busymark.app/rich_clipboard';
const busyMarkClipboardMimeType = 'application/x-busymark-fragment+json';
const maxRichClipboardBytes = 16 * 1024 * 1024;

class RichClipboardData {
  const RichClipboardData({this.text, this.html, this.fragment});

  final String? text;
  final String? html;
  final String? fragment;

  Map<String, String> toMap() => {
    if (text != null) 'text': text!,
    if (html != null) 'html': html!,
    if (fragment != null) 'fragment': fragment!,
  };
}

/// One write publishes all representations of the same immutable selection.
/// The platform owns the data, including after the originating Editor closes.
class RichClipboardService {
  RichClipboardService({
    MethodChannel channel = const MethodChannel(richClipboardChannelName),
  }) : _channel = channel;

  final MethodChannel _channel;
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
    try {
      return await _channel.invokeMethod<bool>('write', data.toMap()) ?? false;
    } on MissingPluginException {
      // Unsupported hosts can still exchange plain text. Never recover rich
      // data from a text-equality cache: a different copy may contain that text.
      try {
        await Clipboard.setData(ClipboardData(text: data.text ?? ''));
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
      return RichClipboardData(
        text: field('text'),
        html: field('html'),
        fragment: field('fragment'),
      );
    } on MissingPluginException {
      return RichClipboardData(text: await readPlainText());
    } on PlatformException {
      return const RichClipboardData();
    } on TimeoutException {
      return const RichClipboardData();
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

final busyMarkRichClipboardService = RichClipboardService();
