import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// One editor's focus and virtualized editable lifetime, independent of the
/// viewport. Search fields and other editors do not participate in this scope.
class BusyMarkEditorFocusScope extends InheritedWidget {
  const BusyMarkEditorFocusScope({
    super.key,
    required super.child,
    this.documentId,
  });

  final String? documentId;

  @override
  bool updateShouldNotify(BusyMarkEditorFocusScope oldWidget) => false;
}

/// Intercepts both halves of EditableText's deferred focus reveal: its direct
/// controller scroll, then showOnScreen through its ancestors. The latter ends
/// the operation, so no timer or frame count is involved. A newer editing value
/// or explicit input wins even when Flutter coalesces it with the focus callback.
class BusyMarkEditorFocusRestoration extends StatefulWidget {
  const BusyMarkEditorFocusRestoration({
    super.key,
    required this.focusNode,
    required this.controller,
    required this.builder,
    this.scrollController,
    this.readOnly = false,
  });

  final FocusNode focusNode;
  final TextEditingController controller;
  final BusyMarkCaretScrollController? scrollController;
  final bool readOnly;
  final Widget Function(BuildContext, ScrollController) builder;

  static final _fields = Expando<_EditorFocusRestorationState>();

  /// For purposeful commands that request focus without changing the caret.
  static void reveal(FocusNode node) => _fields[node]?._allowReveal();

  /// Keep one pending editing target mounted without requesting focus. A
  /// deferred selection handoff may outlive the viewport cache while inactive.
  static VoidCallback? retainPendingTarget(FocusNode node) =>
      _fields[node]?._retainPendingTarget();

  static bool ownsDocumentFocus(FocusNode node, String documentId) {
    final field = _fields[node];
    return field?.mounted == true &&
        (field?._scope?.widget as BusyMarkEditorFocusScope?)?.documentId ==
            documentId;
  }

  static bool keepsEditingWhileInactive(FocusNode node) =>
      WidgetsBinding.instance.lifecycleState != null &&
      WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed &&
      (_fields[node]?._retainEditingTarget ?? false);

  @override
  State<BusyMarkEditorFocusRestoration> createState() =>
      _EditorFocusRestorationState();
}

class _EditorFocusRestorationState extends State<BusyMarkEditorFocusRestoration>
    with AutomaticKeepAliveClientMixin {
  late BusyMarkCaretScrollController _scrollController;
  late TextEditingValue _lastValue;
  bool _pendingFocusReveal = false;
  late final bool Function() _suppressFocusReveal = _shouldSuppressFocusReveal;
  bool _intentionalFocus = false;
  bool _retainEditingTarget = false;
  final _pendingTargetRetentions = <Object>{};
  InheritedElement? _scope;

  bool _shouldSuppressFocusReveal() => _pendingFocusReveal;

  @override
  bool get wantKeepAlive =>
      _retainEditingTarget || _pendingTargetRetentions.isNotEmpty;

  VoidCallback _retainPendingTarget() {
    final request = Object();
    _pendingTargetRetentions.add(request);
    updateKeepAlive();
    return () {
      if (_pendingTargetRetentions.remove(request) && mounted) {
        updateKeepAlive();
      }
    };
  }

  @override
  void initState() {
    super.initState();
    _attach();
    FocusManager.instance.addListener(_focusOwnerChanged);
    FocusManager.instance.addEarlyKeyEventHandler(_keyEvent);
  }

  void _attach() {
    _lastValue = widget.controller.value;
    _scrollController =
        widget.scrollController ?? BusyMarkCaretScrollController();
    _scrollController.suppressFocusReveal = _suppressFocusReveal;
    BusyMarkEditorFocusRestoration._fields[widget.focusNode] = this;
    widget.focusNode.addListener(_focusChanged);
    widget.controller.addListener(_valueChanged);
    if (widget.focusNode.hasFocus) _retainEditingTarget = true;
  }

  void _detach(BusyMarkEditorFocusRestoration field) {
    field.focusNode.removeListener(_focusChanged);
    field.controller.removeListener(_valueChanged);
    BusyMarkEditorFocusRestoration._fields[field.focusNode] = null;
    // A document-keyed replacement can attach its new field before this old
    // state is disposed. Do not retire the new owner's shared-controller hook.
    if (identical(
      _scrollController.suppressFocusReveal,
      _suppressFocusReveal,
    )) {
      _scrollController.suppressFocusReveal = null;
    }
    if (field.scrollController == null) _scrollController.dispose();
    _pendingFocusReveal = false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scope = context
        .getElementForInheritedWidgetOfExactType<BusyMarkEditorFocusScope>();
  }

  @override
  void didUpdateWidget(BusyMarkEditorFocusRestoration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.readOnly) _pendingFocusReveal = false;
    if (oldWidget.focusNode != widget.focusNode ||
        oldWidget.controller != widget.controller ||
        oldWidget.scrollController != widget.scrollController) {
      _detach(oldWidget);
      _attach();
    }
  }

  void _focusChanged() {
    if (widget.focusNode.hasFocus) {
      _pendingFocusReveal = !_intentionalFocus && !widget.readOnly;
      _intentionalFocus = false;
      _retainEditingTarget = true;
      updateKeepAlive();
    } else {
      _intentionalFocus = false;
    }
  }

  void _focusOwnerChanged() {
    final owner = FocusManager.instance.primaryFocus;
    final other = owner == null
        ? null
        : BusyMarkEditorFocusRestoration._fields[owner];
    if (_retainEditingTarget &&
        other != null &&
        other != this &&
        identical(other._scope, _scope)) {
      // Keep only this editor's last editing target alive across application
      // suspension, menus and dialogs. Do not retain every visited field.
      _retainEditingTarget = false;
      updateKeepAlive();
    }
  }

  void _allowReveal() {
    _pendingFocusReveal = false;
    _intentionalFocus = !widget.focusNode.hasFocus;
  }

  void _valueChanged() {
    final value = widget.controller.value;
    if (value.text != _lastValue.text ||
        value.selection != _lastValue.selection) {
      _pendingFocusReveal = false;
    }
    // Composing-only platform lifecycle changes are not navigation. Never
    // restore, fabricate or replay a composing range or a text-input message.
    _lastValue = value;
  }

  KeyEventResult _keyEvent(KeyEvent event) {
    if (widget.focusNode.hasFocus &&
        (event is KeyDownEvent || event is KeyRepeatEvent) &&
        !{
          LogicalKeyboardKey.altLeft,
          LogicalKeyboardKey.altRight,
          LogicalKeyboardKey.controlLeft,
          LogicalKeyboardKey.controlRight,
          LogicalKeyboardKey.shiftLeft,
          LogicalKeyboardKey.shiftRight,
          LogicalKeyboardKey.metaLeft,
          LogicalKeyboardKey.metaRight,
        }.contains(event.logicalKey)) {
      _allowReveal();
    }
    return KeyEventResult.ignored;
  }

  bool _consumeFocusReveal() {
    final suppress = _pendingFocusReveal;
    _pendingFocusReveal = false;
    return suppress;
  }

  @override
  void dispose() {
    FocusManager.instance.removeEarlyKeyEventHandler(_keyEvent);
    FocusManager.instance.removeListener(_focusOwnerChanged);
    _detach(widget);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Listener(
      onPointerDown: (_) => _allowReveal(),
      child: _CaretRevealBoundary(
        consume: _consumeFocusReveal,
        child: widget.builder(context, _scrollController),
      ),
    );
  }
}

class BusyMarkCaretScrollController extends ScrollController {
  bool Function()? suppressFocusReveal;

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) => _CaretScrollPosition(
    physics: physics,
    context: context,
    oldPosition: oldPosition,
    initialPixels: initialScrollOffset,
    keepScrollOffset: keepScrollOffset,
    suppress: () => suppressFocusReveal?.call() ?? false,
  );
}

class _CaretScrollPosition extends ScrollPositionWithSingleContext {
  _CaretScrollPosition({
    required super.physics,
    required super.context,
    super.oldPosition,
    super.initialPixels,
    super.keepScrollOffset,
    required this.suppress,
  });
  final bool Function() suppress;

  @override
  Future<void> animateTo(
    double to, {
    required Duration duration,
    required Curve curve,
  }) {
    if (suppress()) return Future<void>.value();
    return super.animateTo(to, duration: duration, curve: curve);
  }

  @override
  void jumpTo(double value) {
    if (!suppress()) super.jumpTo(value);
  }
}

class _CaretRevealBoundary extends SingleChildRenderObjectWidget {
  const _CaretRevealBoundary({required this.consume, required super.child});
  final bool Function() consume;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderCaretRevealBoundary(consume);
  @override
  void updateRenderObject(
    BuildContext context,
    _RenderCaretRevealBoundary renderObject,
  ) => renderObject.consume = consume;
}

class _RenderCaretRevealBoundary extends RenderProxyBox {
  _RenderCaretRevealBoundary(this.consume);
  bool Function() consume;
  @override
  void showOnScreen({
    RenderObject? descendant,
    Rect? rect,
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
  }) {
    if (!consume()) {
      super.showOnScreen(
        descendant: descendant,
        rect: rect,
        duration: duration,
        curve: curve,
      );
    }
  }
}
