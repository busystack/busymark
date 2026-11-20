import 'package:flutter/widgets.dart';

/// Permission from a creation action to claim the newly mounted input field.
final class BusyMarkDeferredEditorFocus with WidgetsBindingObserver {
  BusyMarkDeferredEditorFocus() {
    FocusManager.instance.applyFocusChangesIfNeeded();
    _initialFocus = FocusManager.instance.primaryFocus;
    _openingGeneration = _modalGeneration;
    if (_resumed) {
      _pending = true;
      FocusManager.instance.addListener(_focusChanged);
      WidgetsBinding.instance.addObserver(this);
    }
  }

  static int _modalGeneration = 0;

  static void modalOpened() => _modalGeneration++;
  late final int _openingGeneration;
  late final FocusNode? _initialFocus;
  bool _pending = false;

  bool get isPending => _pending && _openingGeneration == _modalGeneration;

  bool get _resumed =>
      WidgetsBinding.instance.lifecycleState == null ||
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  void _focusChanged() {
    final current = FocusManager.instance.primaryFocus;
    if (current != null &&
        current != _initialFocus &&
        current is! FocusScopeNode) {
      cancel();
    }
  }

  bool consume(BuildContext context) {
    FocusManager.instance.applyFocusChangesIfNeeded();
    final allowed =
        _pending &&
        _resumed &&
        _openingGeneration == _modalGeneration &&
        ModalRoute.of(context)?.isCurrent != false;
    cancel();
    return allowed;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) cancel();
  }

  void cancel() {
    if (!_pending) return;
    _pending = false;
    FocusManager.instance.removeListener(_focusChanged);
    WidgetsBinding.instance.removeObserver(this);
  }
}
