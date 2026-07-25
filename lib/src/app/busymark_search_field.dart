import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yaru/yaru.dart';

/// Flutter fallback for BusyMark's native Linux search entry.
///
/// Linux header bars use `GtkSearchEntry`. Flutter-owned layouts delegate
/// geometry, icons, focus presentation, and clear behavior to Yaru.
class BusyMarkSearchField extends StatefulWidget {
  const BusyMarkSearchField({
    super.key,
    this.controller,
    this.hintText,
    this.autofocus = false,
    this.focusRequest = 0,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.onEscape,
    this.clearButtonSemanticLabel,
  });

  final TextEditingController? controller;
  final String? hintText;
  final bool autofocus;

  /// Increment this value to focus the Yaru-owned text entry again.
  final int focusRequest;

  final ValueChanged<String>? onChanged;
  final ValueChanged<String?>? onSubmitted;
  final VoidCallback? onClear;
  final VoidCallback? onEscape;
  final String? clearButtonSemanticLabel;

  @override
  State<BusyMarkSearchField> createState() => _BusyMarkSearchFieldState();
}

class _BusyMarkSearchFieldState extends State<BusyMarkSearchField> {
  final _focusScopeNode = FocusScopeNode(
    debugLabel: 'BusyMarkSearchField scope',
  );
  final _yaruKeyboardFocusNode = FocusNode(
    debugLabel: 'BusyMarkSearchField keyboard listener',
    skipTraversal: true,
  );

  @override
  void initState() {
    super.initState();
    if (widget.autofocus) {
      _requestTextFocus();
    }
  }

  @override
  void didUpdateWidget(covariant BusyMarkSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusRequest != widget.focusRequest) {
      _requestTextFocus();
    }
  }

  @override
  void dispose() {
    _focusScopeNode.dispose();
    _yaruKeyboardFocusNode.dispose();
    super.dispose();
  }

  void _requestTextFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      for (final node in _focusScopeNode.traversalDescendants) {
        if (node.canRequestFocus) {
          node.requestFocus();
          return;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape &&
            widget.onEscape != null) {
          widget.onEscape!();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: FocusScope(
        node: _focusScopeNode,
        child: YaruSearchField(
          controller: widget.controller,
          focusNode: _yaruKeyboardFocusNode,
          hintText: widget.hintText,
          autofocus: widget.autofocus,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          onClear: widget.onClear,
          clearIconSemanticLabel:
              widget.clearButtonSemanticLabel ??
              MaterialLocalizations.of(context).clearButtonTooltip,
        ),
      ),
    );
  }
}
