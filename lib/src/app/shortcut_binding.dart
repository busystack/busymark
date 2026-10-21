import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// A layout-aware logical key, independent of localized presentation text.
@immutable
class BusyMarkKeyBinding {
  const BusyMarkKeyBinding(
    this.key, {
    this.control = false,
    this.shift = false,
    this.alt = false,
    this.meta = false,
  });
  final LogicalKeyboardKey key;
  final bool control, shift, alt, meta;

  static final modifierKeys = {
    LogicalKeyboardKey.controlLeft,
    LogicalKeyboardKey.controlRight,
    LogicalKeyboardKey.shiftLeft,
    LogicalKeyboardKey.shiftRight,
    LogicalKeyboardKey.altLeft,
    LogicalKeyboardKey.altRight,
    LogicalKeyboardKey.metaLeft,
    LogicalKeyboardKey.metaRight,
    LogicalKeyboardKey.control,
    LogicalKeyboardKey.shift,
    LogicalKeyboardKey.alt,
    LogicalKeyboardKey.meta,
    LogicalKeyboardKey.altGraph,
    LogicalKeyboardKey.compose,
  };

  static BusyMarkKeyBinding? fromJson(Object? value) {
    if (value is! Map) return null;
    final id = value['key'];
    if (id is! int || id < 0 || id > 0x2ffffffff) return null;
    for (final name in ['control', 'shift', 'alt', 'meta']) {
      if (value[name] != null && value[name] is! bool) return null;
    }
    final known = LogicalKeyboardKey.findKeyByKeyId(id);
    if (known == null &&
        !(id >= 0x20 &&
            id <= 0x10ffff &&
            !(id >= 0x7f && id <= 0x9f) &&
            !(id >= 0xd800 && id <= 0xdfff))) {
      return null;
    }
    final key = known ?? LogicalKeyboardKey(id);
    if (modifierKeys.contains(key) || key == LogicalKeyboardKey.unidentified) {
      return null;
    }
    return BusyMarkKeyBinding(
      key,
      control: value['control'] == true,
      shift: value['shift'] == true,
      alt: value['alt'] == true,
      meta: value['meta'] == true,
    );
  }

  factory BusyMarkKeyBinding.fromActivator(SingleActivator value) =>
      BusyMarkKeyBinding(
        value.trigger,
        control: value.control,
        shift: value.shift,
        alt: value.alt,
        meta: value.meta,
      );

  static BusyMarkKeyBinding? fromEvent(KeyEvent event) {
    if (event is! KeyDownEvent ||
        modifierKeys.contains(event.logicalKey) ||
        event.logicalKey == LogicalKeyboardKey.unidentified) {
      return null;
    }
    final keyboard = HardwareKeyboard.instance;
    final binding = BusyMarkKeyBinding(
      event.logicalKey,
      control: keyboard.isControlPressed,
      shift: keyboard.isShiftPressed,
      alt: keyboard.isAltPressed,
      meta: keyboard.isMetaPressed,
    );
    return fromJson(binding.toJson());
  }

  SingleActivator get activator => SingleActivator(
    key,
    control: control,
    shift: shift,
    alt: alt,
    meta: meta,
    includeRepeats: false,
  );
  Map<String, Object> toJson() => {
    'key': key.keyId,
    'control': control,
    'shift': shift,
    'alt': alt,
    'meta': meta,
  };
  String get label => [
    if (control) 'Ctrl',
    if (alt) 'Alt',
    if (shift) 'Shift',
    if (meta) 'Super',
    key == LogicalKeyboardKey.escape ? 'Esc' : key.keyLabel,
  ].join('+');

  /// Native metadata uses GDK names for functional keys. Unicode scalar
  /// notation is resolved through GDK by the existing menu bridge.
  String get gtkAccelerator {
    final name =
        _gtkNames[key] ??
        (key.keyId < 0x100000000
            ? (!RegExp(r'^[a-zA-Z0-9]$').hasMatch(key.keyLabel)
                  ? 'U+${key.keyId.toRadixString(16).toUpperCase().padLeft(4, '0')}'
                  : key.keyLabel.toLowerCase())
            : key.keyLabel.replaceAll(' ', '_'));
    return '${control ? '<Primary>' : ''}${alt ? '<Alt>' : ''}'
        '${shift ? '<Shift>' : ''}${meta ? '<Super>' : ''}$name';
  }

  bool get hasKnownSystemConflict =>
      meta ||
      (alt && {LogicalKeyboardKey.tab, LogicalKeyboardKey.f4}.contains(key)) ||
      (control &&
          alt &&
          (key == LogicalKeyboardKey.delete ||
              key.keyId >= LogicalKeyboardKey.f1.keyId &&
                  key.keyId <= LogicalKeyboardKey.f12.keyId));

  @override
  bool operator ==(Object other) =>
      other is BusyMarkKeyBinding &&
      key == other.key &&
      control == other.control &&
      shift == other.shift &&
      alt == other.alt &&
      meta == other.meta;
  @override
  int get hashCode => Object.hash(key, control, shift, alt, meta);
}

final _gtkNames = <LogicalKeyboardKey, String>{
  LogicalKeyboardKey.escape: 'Escape',
  LogicalKeyboardKey.enter: 'Return',
  LogicalKeyboardKey.arrowLeft: 'Left',
  LogicalKeyboardKey.arrowRight: 'Right',
  LogicalKeyboardKey.arrowUp: 'Up',
  LogicalKeyboardKey.arrowDown: 'Down',
  LogicalKeyboardKey.pageUp: 'Page_Up',
  LogicalKeyboardKey.pageDown: 'Page_Down',
  LogicalKeyboardKey.backspace: 'BackSpace',
  LogicalKeyboardKey.space: 'space',
  LogicalKeyboardKey.comma: 'comma',
  LogicalKeyboardKey.period: 'period',
  LogicalKeyboardKey.slash: 'slash',
  LogicalKeyboardKey.backslash: 'backslash',
  LogicalKeyboardKey.semicolon: 'semicolon',
  LogicalKeyboardKey.quote: 'apostrophe',
  LogicalKeyboardKey.bracketLeft: 'bracketleft',
  LogicalKeyboardKey.bracketRight: 'bracketright',
  LogicalKeyboardKey.minus: 'minus',
  LogicalKeyboardKey.equal: 'equal',
  LogicalKeyboardKey.backquote: 'grave',
  LogicalKeyboardKey.numpad0: 'KP_0',
  LogicalKeyboardKey.numpad1: 'KP_1',
  LogicalKeyboardKey.numpad2: 'KP_2',
  LogicalKeyboardKey.numpad3: 'KP_3',
  LogicalKeyboardKey.numpad4: 'KP_4',
  LogicalKeyboardKey.numpad5: 'KP_5',
  LogicalKeyboardKey.numpad6: 'KP_6',
  LogicalKeyboardKey.numpad7: 'KP_7',
  LogicalKeyboardKey.numpad8: 'KP_8',
  LogicalKeyboardKey.numpad9: 'KP_9',
  LogicalKeyboardKey.numpadEnter: 'KP_Enter',
  LogicalKeyboardKey.numpadAdd: 'KP_Add',
  LogicalKeyboardKey.numpadSubtract: 'KP_Subtract',
  LogicalKeyboardKey.numpadMultiply: 'KP_Multiply',
  LogicalKeyboardKey.numpadDivide: 'KP_Divide',
  LogicalKeyboardKey.numpadDecimal: 'KP_Decimal',
};

/// Missing entries use defaults; null entries explicitly unassign a command.
Map<String, BusyMarkKeyBinding?> readShortcutOverrides(Object? value) {
  if (value is! Map) return const {};
  return Map.unmodifiable({
    for (final entry in value.entries)
      if (entry.key is String &&
          RegExp(
            r'^[a-z][A-Za-z0-9]*(?:\.[a-z][A-Za-z0-9]*)+$',
          ).hasMatch(entry.key as String))
        if (entry.value == null)
          entry.key as String: null
        else if (BusyMarkKeyBinding.fromJson(entry.value) case final binding?)
          entry.key as String: binding,
  });
}
