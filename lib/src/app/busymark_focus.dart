// BusyMark-owned focus presentation. Git retains its own feature primitives.
// Flutter's traditional highlight mode includes mouse input. Track modality
// separately without changing focus ownership, traversal, or global strategy.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yaru/yaru.dart';

abstract final class BusyMarkFocusStyle {
  static Color color(ColorScheme scheme, {bool highContrast = false}) =>
      scheme.onSurface.withValues(alpha: highContrast ? 1 : .65);

  static InputDecorationThemeData inputs(
    InputDecorationThemeData base,
    ColorScheme scheme, {
    bool highContrast = false,
  }) => base.copyWith(
    focusedBorder: base.focusedBorder?.copyWith(
      borderSide: BorderSide(
        color: color(scheme, highContrast: highContrast),
        width: kYaruFocusBorderWidth,
      ),
    ),
  );
}

class _InputModality extends ChangeNotifier {
  static final instance = _InputModality();
  bool keyboard = true;
  int _users = 0;
  void attach() {
    if (_users++ != 0) return;
    GestureBinding.instance.pointerRouter.addGlobalRoute(_pointer);
    HardwareKeyboard.instance.addHandler(_key);
  }

  void detach() {
    if (--_users != 0) return;
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_pointer);
    HardwareKeyboard.instance.removeHandler(_key);
    keyboard = true;
  }

  void _set(bool value) {
    if (keyboard == value) return;
    keyboard = value;
    notifyListeners();
  }

  void _pointer(PointerEvent event) {
    if (event is PointerDownEvent) _set(false);
  }

  bool _key(KeyEvent event) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) _set(true);
    return false;
  }
}

/// Input focus and visual focus are independent. A mouse-selected row keeps
/// its focus node; the next keyboard event immediately reveals its indicator.
class BusyMarkFocusIndicator extends StatefulWidget {
  const BusyMarkFocusIndicator({
    super.key,
    required this.child,
    this.borderRadius,
    this.borderStrokeAlign = BorderSide.strokeAlignInside,
    this.enabled = true,
    this.editing = false,
  });
  final Widget child;
  final BorderRadiusGeometry? borderRadius;
  final double borderStrokeAlign;
  final bool enabled, editing;
  @override
  State<BusyMarkFocusIndicator> createState() => _BusyMarkFocusIndicatorState();
}

class _BusyMarkFocusIndicatorState extends State<BusyMarkFocusIndicator> {
  bool _focused = false;
  final _modality = _InputModality.instance;
  @override
  void initState() {
    super.initState();
    _modality.attach();
    _modality.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _modality.removeListener(_changed);
    _modality.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible =
        widget.enabled && _focused && (widget.editing || _modality.keyboard);
    final color = BusyMarkFocusStyle.color(
      Theme.of(context).colorScheme,
      highContrast: MediaQuery.highContrastOf(context),
    );
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onFocusChange: (focused) => setState(() => _focused = focused),
      child: YaruFocusBorder.primary(
        focused: true,
        onFocusChange: (_) {},
        borderColor: visible ? color : color.withValues(alpha: 0),
        borderWidth: kYaruFocusBorderWidth,
        borderRadius: widget.borderRadius,
        borderStrokeAlign: widget.borderStrokeAlign,
        child: widget.child,
      ),
    );
  }
}

/// Let Flutter observe every trigger release before a native menu grabs keys.
final class BusyMarkContextMenuKeys {
  VoidCallback? _open;
  bool _triggerReleased = false, _awaitingShift = false;

  bool handle(KeyEvent event, VoidCallback? open) {
    final keyboard = HardwareKeyboard.instance;
    final key = event.logicalKey;
    final trigger =
        !keyboard.isControlPressed &&
        !keyboard.isAltPressed &&
        !keyboard.isMetaPressed &&
        (key == LogicalKeyboardKey.contextMenu && !keyboard.isShiftPressed ||
            key == LogicalKeyboardKey.f10 && keyboard.isShiftPressed);
    if (event is KeyDownEvent) {
      clear();
      if (!trigger || open == null) return false;
      _open = open;
      _awaitingShift = key == LogicalKeyboardKey.f10;
      return true;
    }
    if (_open == null) return false;
    if (event is KeyRepeatEvent) return true;
    if (event is! KeyUpEvent) return false;
    if (key == LogicalKeyboardKey.f10 ||
        key == LogicalKeyboardKey.contextMenu) {
      _triggerReleased = true;
    }
    // The aggregate mask can clear before the concrete Shift-up reaches the
    // Flutter view. Waiting only for F10-up still races a native GTK grab.
    if ((key == LogicalKeyboardKey.shiftLeft ||
            key == LogicalKeyboardKey.shiftRight) &&
        !keyboard.isShiftPressed) {
      _awaitingShift = false;
    }
    if (_triggerReleased && !_awaitingShift) {
      final action = _open!;
      clear();
      action();
    }
    return true;
  }

  void clear() {
    _open = null;
    _triggerReleased = false;
    _awaitingShift = false;
  }
}
