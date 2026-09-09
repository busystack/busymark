import 'dart:async';

import 'package:flutter/foundation.dart';

import 'clipboard_models.dart';

abstract interface class BusyMarkClipboardInsertionTarget {
  String get documentId;
  String get documentName;
  String? get documentPath;
  bool get editable;

  Future<ClipboardPasteResult> paste(
    BusyMarkClipboardPayload payload, {
    required bool plainText,
  });

  void requestEditorFocus();
}

/// Holds only the currently mounted document surface. Registrations remove
/// themselves by identity, so a retiring editor cannot unregister its
/// replacement or leave a disposed controller reachable from session state.
class BusyMarkClipboardInsertionRegistry extends ChangeNotifier {
  BusyMarkClipboardInsertionTarget? _target;
  bool _notificationScheduled = false;
  bool _disposed = false;

  BusyMarkClipboardInsertionTarget? get target => _target;

  void register(BusyMarkClipboardInsertionTarget target) {
    if (identical(_target, target)) return;
    _target = target;
    _scheduleNotification();
  }

  void unregister(BusyMarkClipboardInsertionTarget target) {
    if (!identical(_target, target)) return;
    _target = null;
    _scheduleNotification();
  }

  void _scheduleNotification() {
    if (_notificationScheduled || _disposed) return;
    _notificationScheduled = true;
    scheduleMicrotask(() {
      _notificationScheduled = false;
      if (!_disposed) notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<ClipboardPasteResult> paste(
    BusyMarkClipboardPayload payload, {
    bool plainText = false,
  }) async {
    final captured = _target;
    if (captured == null || !captured.editable) {
      return ClipboardPasteResult.unavailable;
    }
    final result = await captured.paste(payload, plainText: plainText);
    if (result == ClipboardPasteResult.inserted &&
        identical(_target, captured)) {
      captured.requestEditorFocus();
    }
    return result;
  }
}
