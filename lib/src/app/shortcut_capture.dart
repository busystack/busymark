import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'shortcut_binding.dart';

/// Intercepts before the focus tree and also gates hardware-level dispatch.
/// After capture closes, held keys must be released before normal dispatch.
abstract final class BusyMarkShortcutCapture {
  static Object? _owner;
  static void Function(BusyMarkKeyBinding)? _onCandidate;
  static VoidCallback? _onCancel;
  static bool _installed = false;
  static bool get suppressing => _installed;

  static void begin(
    Object owner, {
    required void Function(BusyMarkKeyBinding) onCandidate,
    required VoidCallback onCancel,
  }) {
    if (_owner != null && !identical(_owner, owner)) _onCancel?.call();
    _owner = owner;
    _onCandidate = onCandidate;
    _onCancel = onCancel;
    if (!_installed) {
      _installed = true;
      FocusManager.instance.addEarlyKeyEventHandler(_handle);
    }
  }

  static void end(Object owner) {
    if (!identical(_owner, owner)) return;
    _owner = null;
    _onCandidate = null;
    _onCancel = null;
    _releaseIfIdle();
  }

  static void _releaseIfIdle() {
    if (_owner == null &&
        HardwareKeyboard.instance.logicalKeysPressed.isEmpty &&
        _installed) {
      FocusManager.instance.removeEarlyKeyEventHandler(_handle);
      _installed = false;
    }
  }

  static KeyEventResult _handle(KeyEvent event) {
    final focused = FocusManager.instance.primaryFocus?.context;
    final composing =
        focused
            ?.findAncestorStateOfType<EditableTextState>()
            ?.widget
            .controller
            .value
            .composing
            .isValid ==
        true;
    if (_owner != null && event is KeyDownEvent && !composing) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _onCancel?.call();
      } else if (BusyMarkKeyBinding.fromEvent(event) case final binding?) {
        _onCandidate?.call(binding);
      }
    }
    // The event that releases the last captured key is still consumed.
    _releaseIfIdle();
    return KeyEventResult.handled;
  }
}
