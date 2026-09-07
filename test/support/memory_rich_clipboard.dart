import 'package:busymark/src/platform/rich_clipboard_service.dart';
import 'package:flutter/services.dart';

/// A test clipboard that exposes the OS text representation to existing mocks.
class MemoryRichClipboard extends RichClipboardService {
  RichClipboardData data = const RichClipboardData();
  bool writeSucceeds = true;

  @override
  Future<bool> write(RichClipboardData value) async {
    if (!writeSucceeds) return false;
    await Clipboard.setData(ClipboardData(text: value.text ?? ''));
    data = value;
    return true;
  }

  @override
  Future<RichClipboardData> read() async => data;
}
