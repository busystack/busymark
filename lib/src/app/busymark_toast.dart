import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';

import 'busymark_design.dart';
import 'busymark_glyphs.dart';

/// Controls how a toast is ordered when another toast is already visible.
enum BusyMarkToastPriority { normal, high }

/// Hosts native-looking, window-level feedback for short-lived app events.
///
/// The presentation follows the GNOME/Libadwaita toast pattern: one compact,
/// user-dismissible message is overlaid at the bottom center of the window.
class BusyMarkToastOverlay extends StatefulWidget {
  const BusyMarkToastOverlay({super.key, required this.child});

  final Widget child;

  static void show(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 5),
    BusyMarkToastPriority priority = BusyMarkToastPriority.normal,
  }) {
    final host = context
        .dependOnInheritedWidgetOfExactType<_BusyMarkToastScope>()
        ?._state;
    host?._show(
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
      priority: priority,
    );
  }

  static bool maybeShow(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 5),
    BusyMarkToastPriority priority = BusyMarkToastPriority.normal,
  }) {
    final host = context
        .dependOnInheritedWidgetOfExactType<_BusyMarkToastScope>()
        ?._state;
    if (host == null) {
      return false;
    }
    host._show(
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
      priority: priority,
    );
    return true;
  }

  @override
  State<BusyMarkToastOverlay> createState() => _BusyMarkToastOverlayState();
}

class _BusyMarkToastOverlayState extends State<BusyMarkToastOverlay> {
  static const _transitionDuration = Duration(milliseconds: 180);

  final _pending = ListQueue<_BusyMarkToast>();
  _BusyMarkToast? _active;
  Timer? _dismissTimer;
  Timer? _nextToastTimer;
  var _nextId = 0;

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _nextToastTimer?.cancel();
    super.dispose();
  }

  void _show({
    required String message,
    required String? actionLabel,
    required VoidCallback? onAction,
    required Duration duration,
    required BusyMarkToastPriority priority,
  }) {
    final normalizedMessage = message.trim();
    if (normalizedMessage.isEmpty || !mounted) {
      return;
    }
    final toast = _BusyMarkToast(
      id: _nextId++,
      message: normalizedMessage,
      actionLabel: actionLabel?.trim(),
      onAction: onAction,
      duration: duration,
      priority: priority,
    );
    final active = _active;
    if (active == null) {
      _activate(toast);
      return;
    }
    if (active.matches(toast)) {
      setState(() => _active = toast);
      _startDismissTimer(toast);
      return;
    }
    if (priority == BusyMarkToastPriority.high) {
      _pending.addFirst(toast);
    } else {
      _pending.addLast(toast);
    }
  }

  void _activate(_BusyMarkToast toast) {
    _nextToastTimer?.cancel();
    setState(() => _active = toast);
    _startDismissTimer(toast);
  }

  void _startDismissTimer(_BusyMarkToast toast) {
    _dismissTimer?.cancel();
    if (toast.duration <= Duration.zero) {
      return;
    }
    _dismissTimer = Timer(toast.duration, () => _dismiss(toast.id));
  }

  void _dismiss(int id) {
    if (!mounted || _active?.id != id) {
      return;
    }
    _dismissTimer?.cancel();
    setState(() => _active = null);
    _nextToastTimer?.cancel();
    _nextToastTimer = Timer(_transitionDuration, _showNext);
  }

  void _showNext() {
    if (!mounted || _active != null || _pending.isEmpty) {
      return;
    }
    _activate(_pending.removeFirst());
  }

  void _invokeAction(_BusyMarkToast toast) {
    toast.onAction?.call();
    _dismiss(toast.id);
  }

  @override
  Widget build(BuildContext context) {
    final active = _active;
    return _BusyMarkToastScope(
      state: this,
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          Positioned(
            left: BusyMarkSpacing.lg,
            right: BusyMarkSpacing.lg,
            bottom: BusyMarkSpacing.lg,
            child: SafeArea(
              top: false,
              child: Align(
                alignment: Alignment.bottomCenter,
                heightFactor: 1,
                child: AnimatedSwitcher(
                  duration: _transitionDuration,
                  reverseDuration: _transitionDuration,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.15),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: active == null
                      ? const SizedBox.shrink()
                      : _BusyMarkToastSurface(
                          key: ValueKey(active.id),
                          toast: active,
                          onAction: () => _invokeAction(active),
                          onDismiss: () => _dismiss(active.id),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BusyMarkToastScope extends InheritedWidget {
  const _BusyMarkToastScope({required this.state, required super.child});

  final _BusyMarkToastOverlayState state;

  _BusyMarkToastOverlayState get _state => state;

  @override
  bool updateShouldNotify(_BusyMarkToastScope oldWidget) => false;
}

@immutable
class _BusyMarkToast {
  const _BusyMarkToast({
    required this.id,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    required this.duration,
    required this.priority,
  });

  final int id;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duration;
  final BusyMarkToastPriority priority;

  bool matches(_BusyMarkToast other) =>
      message == other.message && actionLabel == other.actionLabel;
}

class _BusyMarkToastSurface extends StatelessWidget {
  const _BusyMarkToastSurface({
    super.key,
    required this.toast,
    required this.onAction,
    required this.onDismiss,
  });

  final _BusyMarkToast toast;
  final VoidCallback onAction;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = BusyMarkSurfaceColors.of(context);
    final actionLabel = toast.actionLabel;
    return Semantics(
      container: true,
      liveRegion: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Material(
          color: BusyMarkLinuxPalette.transparent,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.popover,
              borderRadius: BorderRadius.circular(BusyMarkRadius.lg),
              border: Border.all(color: colors.floatingBorder),
              boxShadow: BusyMarkShadow.nativeCardShadowsFor(context),
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                BusyMarkSpacing.lg,
                BusyMarkSpacing.sm,
                BusyMarkSpacing.sm,
                BusyMarkSpacing.sm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      toast.message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (actionLabel != null && actionLabel.isNotEmpty) ...[
                    const SizedBox(width: BusyMarkSpacing.sm),
                    TextButton(onPressed: onAction, child: Text(actionLabel)),
                  ],
                  const SizedBox(width: BusyMarkSpacing.xs),
                  BusyMarkCompactIconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    icon: BusyMarkGlyphs.windowClose,
                    onPressed: onDismiss,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
