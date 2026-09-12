import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yaru/yaru.dart';

/// Flutter counterpart to BusyMark's native Linux `GtkSearchEntry`.
///
/// The native entry cannot be embedded in Flutter-owned layouts. This uses the
/// Yaru input theme shared by the rest of the application instead of
/// [YaruSearchField], whose borderless pill geometry is intended for Flutter
/// title bars rather than GTK-style entries inside a sidebar.
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

  /// Increment this value to focus the themed text entry again.
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
  late TextEditingController _controller;
  late bool _textIsEmpty;
  final _focusNode = FocusNode(debugLabel: 'BusyMarkSearchField text entry');

  @override
  void initState() {
    super.initState();
    _attachController();
  }

  @override
  void didUpdateWidget(covariant BusyMarkSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _controller.removeListener(_handleControllerChanged);
      if (oldWidget.controller == null) {
        _controller.dispose();
      }
      _attachController();
    }
    if (oldWidget.focusRequest != widget.focusRequest) {
      _requestTextFocus();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  void _attachController() {
    _controller = widget.controller ?? TextEditingController();
    _textIsEmpty = _controller.text.isEmpty;
    _controller.addListener(_handleControllerChanged);
  }

  void _handleControllerChanged() {
    final textIsEmpty = _controller.text.isEmpty;
    if (textIsEmpty != _textIsEmpty) {
      setState(() => _textIsEmpty = textIsEmpty);
    }
  }

  void _requestTextFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  void _clear() {
    final hadText = _controller.text.isNotEmpty;
    final onClear = widget.onClear;
    if (onClear != null) {
      onClear();
    }
    _controller.clear();
    if (onClear == null && hadText) {
      // TextField does not report programmatic controller changes through
      // onChanged, so keep onChanged-only search owners in sync.
      widget.onChanged?.call('');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clearLabel =
        widget.clearButtonSemanticLabel ??
        MaterialLocalizations.of(context).clearButtonTooltip;
    return Focus(
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          _clear();
          widget.onEscape?.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: SizedBox(
        height: kYaruTitleBarItemHeight,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: widget.autofocus,
          textInputAction: TextInputAction.search,
          textAlignVertical: TextAlignVertical.center,
          cursorWidth: 1,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          decoration: InputDecoration(
            hintText: widget.hintText,
            filled: true,
            fillColor: theme.colorScheme.surface,
            prefixIcon: const Icon(YaruIcons.search),
            prefixIconConstraints: const BoxConstraints.tightFor(
              width: kYaruTitleBarItemHeight,
            ),
            suffixIcon: _textIsEmpty
                ? null
                : IconButton(
                    tooltip: clearLabel,
                    onPressed: _clear,
                    icon: const Icon(YaruIcons.edit_clear),
                  ),
            suffixIconConstraints: const BoxConstraints.tightFor(
              width: kYaruTitleBarItemHeight,
            ),
          ),
        ),
      ),
    );
  }
}
