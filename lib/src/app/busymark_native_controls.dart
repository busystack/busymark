// BusyMark-owned native controls built from the pinned public Flutter/Yaru APIs.
// These small generic mechanisms intentionally have no Git dependency.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yaru/yaru.dart';
import 'busymark_design.dart';
import 'busymark_glyphs.dart';

enum BusyMarkNativeActionRole { inline, standard, suggested, destructive }

class BusyMarkNativeActionButton extends StatefulWidget {
  const BusyMarkNativeActionButton({
    super.key,
    required this.role,
    required this.child,
    required this.onPressed,
    this.compact = false,
  });

  final BusyMarkNativeActionRole role;
  final Widget child;
  final VoidCallback? onPressed;
  final bool compact;

  @override
  State<BusyMarkNativeActionButton> createState() =>
      BusyMarkNativeActionButtonState();
}

class BusyMarkNativeActionButtonState
    extends State<BusyMarkNativeActionButton> {
  final _focusNode = FocusNode(debugLabel: 'BusyMark action');
  var _hovered = false;
  var _pressed = false;
  var _focused = false;
  var _hasFocus = false;

  Set<WidgetState> get _states => {
    if (widget.onPressed == null) WidgetState.disabled,
    if (_hovered) WidgetState.hovered,
    if (_pressed) WidgetState.pressed,
    if (_focused) WidgetState.focused,
  };

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  void _activate() {
    if (widget.onPressed != null) widget.onPressed!();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final theme = Theme.of(context);
    final style = switch (widget.role) {
      // Match BusyMarkPushButton.flat: native neutral foreground, never the
      // accent/link foreground from the application's text-button theme.
      BusyMarkNativeActionRole.inline => theme.textButtonTheme.style?.copyWith(
        foregroundColor: theme.outlinedButtonTheme.style?.foregroundColor,
        iconColor: theme.outlinedButtonTheme.style?.iconColor,
      ),
      BusyMarkNativeActionRole.destructive =>
        theme.filledButtonTheme.style?.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? colors.disabledControl
                : BusyMarkDestructiveButtonStyle.background(theme),
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? colors.disabledForeground
                : BusyMarkDestructiveButtonStyle.foreground(theme),
          ),
        ),
      BusyMarkNativeActionRole.standard => theme.filledButtonTheme.style,
      BusyMarkNativeActionRole.suggested => theme.elevatedButtonTheme.style,
    };
    final states = _states;
    final enabled = widget.onPressed != null;
    final foreground = enabled
        ? style?.foregroundColor?.resolve(states) ?? colors.foreground
        : colors.disabledForeground;
    final baseBackground = style?.backgroundColor?.resolve(states);
    final fallbackOverlay = !enabled
        ? null
        : _pressed
        ? colors.controlActive
        : _hovered || (_focused)
        ? colors.controlHover
        : null;
    final overlay = style?.overlayColor?.resolve(states) ?? fallbackOverlay;
    final background = Color.alphaBlend(
      overlay ?? Theme.of(context).colorScheme.surface.withValues(alpha: 0),
      baseBackground ??
          Theme.of(context).colorScheme.surface.withValues(alpha: 0),
    );
    final resolvedShape =
        style?.shape?.resolve(states) ??
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kYaruButtonRadius),
        );
    final side = style?.side?.resolve(states);
    final shape = side != null
        ? resolvedShape.copyWith(side: side)
        : resolvedShape;
    final radius = resolvedShape is RoundedRectangleBorder
        ? resolvedShape.borderRadius
        : BorderRadius.circular(kYaruButtonRadius);
    final padding = widget.compact
        ? const EdgeInsets.symmetric(
            horizontal: BusyMarkSpacing.md,
            vertical: BusyMarkSpacing.xs,
          )
        : const EdgeInsets.symmetric(
            horizontal: BusyMarkSpacing.lg,
            vertical: BusyMarkSpacing.sm,
          );
    final minimum =
        style?.minimumSize?.resolve(states) ??
        const Size(kYaruButtonHeight, kYaruButtonHeight);
    final maximum =
        style?.maximumSize?.resolve(states) ??
        const Size(double.infinity, double.infinity);
    final fixed = style?.fixedSize?.resolve(states);
    final constraints = fixed == null
        ? BoxConstraints(
            minWidth: minimum.width,
            minHeight: widget.compact
                ? kYaruTitleBarItemHeight
                : minimum.height,
            maxWidth: maximum.width,
            maxHeight: maximum.height,
          )
        : BoxConstraints.tight(fixed);
    final textStyle = theme.textTheme.bodyMedium!.merge(
      style?.textStyle?.resolve(states),
    );
    final content = DefaultTextStyle(
      style: textStyle.copyWith(color: foreground),
      child: IconTheme.merge(
        data: IconThemeData(
          color: style?.iconColor?.resolve(states) ?? foreground,
          size: style?.iconSize?.resolve(states),
        ),
        child: Padding(padding: padding, child: widget.child),
      ),
    );
    final painted = DecoratedBox(
      decoration: ShapeDecoration(color: background, shape: shape),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: ConstrainedBox(
          constraints: constraints,
          child: Center(widthFactor: 1, heightFactor: 1, child: content),
        ),
      ),
    );
    final action = Semantics(
      button: true,
      enabled: enabled,
      focusable: enabled,
      focused: enabled ? _hasFocus : null,
      onFocus: enabled ? _focusNode.requestFocus : null,
      onTap: enabled ? _activate : null,
      child: FocusableActionDetector(
        // Keep the name, role, enabled state and focus action on one node.
        includeFocusSemantics: false,
        focusNode: _focusNode,
        enabled: enabled,
        onFocusChange: (focused) {
          if (_hasFocus != focused) {
            setState(() {
              _hasFocus = focused;
            });
          }
        },
        mouseCursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _activate();
              return null;
            },
          ),
        },
        onShowFocusHighlight: (focused) {
          if (_focused != focused) setState(() => _focused = focused);
        },
        child: MouseRegion(
          onEnter: (_) {
            if (enabled && !_hovered) setState(() => _hovered = true);
          },
          onExit: (_) {
            if (_hovered || _pressed) {
              setState(() {
                _hovered = false;
                _pressed = false;
              });
            }
          },
          child: GestureDetector(
            // The outer node owns the semantic action and the label together.
            excludeFromSemantics: true,
            behavior: HitTestBehavior.opaque,
            onTap: enabled ? _activate : null,
            onTapDown: enabled
                ? (_) {
                    // Match the approved host secondary control: pointer
                    // activation preserves the previous keyboard-focus owner.
                    // Tab and the semantic Focus action still focus this node.
                    _setPressed(true);
                  }
                : null,
            onTapUp: enabled ? (_) => _setPressed(false) : null,
            onTapCancel: enabled ? () => _setPressed(false) : null,
            child: painted,
          ),
        ),
      ),
    );
    return YaruTheme.maybeOf(context)?.focusBorders != false
        ? BusyMarkFocusIndicator(
            borderRadius: radius,
            enabled: enabled,
            child: action,
          )
        : action;
  }
}

class BusyMarkNativeTextEntry extends StatefulWidget {
  const BusyMarkNativeTextEntry({
    super.key,
    required this.label,
    this.hintText,
    this.controller,
    this.focusNode,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.obscureText = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.expands = false,
    this.minLines,
    this.maxLines = 1,
    this.scrollController,
    this.undoController,
    this.textStyle,
    this.textDirection,
    this.textAlign = TextAlign.start,
    this.leading,
    this.trailing,
    this.dense = false,
    this.contentPadding,
    this.textAlignVertical,
    this.alignLabelWithHint = false,
    this.contextMenuBuilder,
    this.onChanged,
    this.onSubmitted,
  });

  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final bool obscureText;
  final bool autocorrect;
  final bool enableSuggestions;
  final bool expands;
  final int? minLines;
  final int? maxLines;
  final ScrollController? scrollController;
  final UndoHistoryController? undoController;
  final TextStyle? textStyle;
  final TextDirection? textDirection;
  final TextAlign textAlign;
  final Widget? leading, trailing;
  final bool dense, alignLabelWithHint;
  final EdgeInsetsGeometry? contentPadding;
  final TextAlignVertical? textAlignVertical;
  final EditableTextContextMenuBuilder? contextMenuBuilder;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<BusyMarkNativeTextEntry> createState() =>
      _BusyMarkNativeTextEntryState();
}

class _BusyMarkNativeTextEntryState extends State<BusyMarkNativeTextEntry>
    implements TextSelectionGestureDetectorBuilderDelegate {
  TextEditingController? _ownedController;
  FocusNode? _ownedFocusNode;
  @override
  final editableTextKey = GlobalKey<EditableTextState>();
  @override
  bool get forcePressEnabled => false;
  @override
  bool get selectionEnabled => widget.enabled;
  late final _gestures = TextSelectionGestureDetectorBuilder(delegate: this);

  TextEditingController get _controller =>
      widget.controller ?? (_ownedController ??= TextEditingController());
  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownedFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(BusyMarkNativeTextEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onTextChanged);
      widget.controller?.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onTextChanged);
    _ownedController?.dispose();
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  void _submit() {
    final composing = _controller.value.composing;
    if (composing.isValid && !composing.isCollapsed) return;
    widget.onSubmitted?.call(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final enabled = widget.enabled;
    final selectionTheme = Theme.of(context).textSelectionTheme;
    final style = (widget.textStyle ?? Theme.of(context).textTheme.bodyMedium)!
        .copyWith(
          color: enabled
              ? (widget.textStyle?.color ?? colors.foreground)
              : colors.disabledForeground,
        );
    final editable = EditableText(
      key: editableTextKey,
      controller: _controller,
      focusNode: _focusNode,
      readOnly: widget.readOnly || !enabled,
      autofocus: enabled && widget.autofocus,
      obscureText: widget.obscureText,
      autocorrect: widget.autocorrect,
      enableSuggestions: widget.enableSuggestions,
      style: style,
      cursorColor:
          selectionTheme.cursorColor ?? Theme.of(context).colorScheme.primary,
      rendererIgnoresPointer: true,
      selectionControls: desktopTextSelectionHandleControls,
      backgroundCursorColor: colors.mutedForeground,
      selectionColor:
          selectionTheme.selectionColor ??
          Theme.of(context).colorScheme.primary.withValues(alpha: .25),
      expands: widget.expands,
      minLines: widget.expands ? null : widget.minLines,
      maxLines: widget.expands ? null : widget.maxLines,
      scrollController: widget.scrollController,
      undoController: widget.undoController,
      textDirection: widget.textDirection,
      textAlign: widget.textAlign,
      contextMenuBuilder: widget.contextMenuBuilder,
      onChanged: enabled
          ? (value) {
              setState(() {});
              widget.onChanged?.call(value);
            }
          : null,
      onSubmitted: enabled ? widget.onSubmitted : null,
    );
    // Native search entries use an inline placeholder. The semantic label
    // persists while typing, without a second permanent toolbar line.
    final label = widget.label.trim();
    final hint = widget.hintText ?? (widget.dense ? label : null);
    final editor = Stack(
      alignment: AlignmentDirectional(
        -1,
        widget.textAlignVertical?.y ?? (widget.alignLabelWithHint ? -1 : 0),
      ),
      children: [
        if (hint != null && hint.isNotEmpty && _controller.text.isEmpty)
          IgnorePointer(
            child: ExcludeSemantics(
              // The persistent field label names the editor. The placeholder
              // is visual guidance, not a second accessible field name.
              child: Text(
                hint,
                maxLines: widget.maxLines == 1 ? 1 : null,
                overflow: widget.maxLines == 1 ? TextOverflow.ellipsis : null,
                style: style.copyWith(color: colors.mutedForeground),
              ),
            ),
          ),
        editable,
      ],
    );
    final content = Column(
      mainAxisSize: widget.expands ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.dense && label.isNotEmpty) ...[
          ExcludeSemantics(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: enabled
                    ? colors.mutedForeground
                    : colors.disabledForeground,
              ),
            ),
          ),
          const SizedBox(height: BusyMarkSpacing.xs),
        ],
        if (widget.expands) Expanded(child: editor) else editor,
      ],
    );
    final inputTheme = Theme.of(context).inputDecorationTheme;
    final radius = BorderRadius.circular(
      widget.dense ? kYaruButtonRadius : kYaruContainerRadius,
    );
    final surface = ListenableBuilder(
      listenable: _focusNode,
      builder: (context, _) => YaruBorderContainer(
        color: widget.dense
            ? Theme.of(context).colorScheme.surface
            : BusyMarkSurfaceColors.of(context).panel,
        border: Border.fromBorderSide(
          (_focusNode.hasFocus
                      ? inputTheme.focusedBorder
                      : widget.dense && enabled
                      ? inputTheme.enabledBorder
                      : widget.dense
                      ? inputTheme.disabledBorder
                      : null)
                  ?.borderSide ??
              BorderSide(color: colors.divider),
        ),
        borderRadius: radius,
        constraints: BoxConstraints(
          minHeight: widget.dense ? kYaruTitleBarItemHeight : 0,
        ),
        padding:
            widget.contentPadding ??
            const EdgeInsets.symmetric(
              horizontal: BusyMarkSpacing.sm,
              vertical: BusyMarkSpacing.xs,
            ),
        child: Row(
          crossAxisAlignment: widget.expands
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            if (widget.leading != null) ...[
              widget.leading!,
              const SizedBox(width: BusyMarkSpacing.sm),
            ],
            Expanded(child: content),
            if (widget.trailing != null) ...[
              const SizedBox(width: BusyMarkSpacing.xs),
              widget.trailing!,
            ],
          ],
        ),
      ),
    );
    final interactive = Semantics(
      label: label.isEmpty ? null : label,
      enabled: enabled,
      child: IgnorePointer(
        ignoring: !enabled,
        child: ExcludeFocus(
          excluding: !enabled,
          child: _gestures.buildGestureDetector(
            behavior: HitTestBehavior.translucent,
            child: surface,
          ),
        ),
      ),
    );
    if (!enabled || widget.onSubmitted == null) return interactive;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): _submit,
        const SingleActivator(LogicalKeyboardKey.numpadEnter): _submit,
      },
      child: interactive,
    );
  }
}

/// Native application dialog surface for ordinary BusyMark features.
class BusyMarkNativeDialogShell extends StatelessWidget {
  const BusyMarkNativeDialogShell({
    super.key,
    required this.title,
    this.maxWidth = BusyMarkSizes.dialogWide,
    this.children = const [],
    this.actions = const [],
  });
  final String title;
  final double maxWidth;
  final List<Widget> children, actions;
  @override
  Widget build(BuildContext context) => Semantics(
    scopesRoute: true,
    namesRoute: true,
    explicitChildNodes: true,
    label: title,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BusyMarkSizes.modalHorizontalInset,
          vertical: BusyMarkSizes.modalVerticalInset,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight:
                MediaQuery.sizeOf(context).height *
                BusyMarkSizes.modalMaxHeightFraction,
          ),
          child: YaruBorderContainer(
            color: BusyMarkSurfaceColors.of(context).dialog,
            borderRadius: BorderRadius.circular(BusyMarkRadius.window),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: maxWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(BusyMarkSpacing.headerInset),
                    child: Row(
                      children: [
                        const SizedBox(width: BusyMarkSizes.iconButton),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        BusyMarkHeaderIconButton(
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).closeButtonTooltip,
                          icon: BusyMarkGlyphs.windowClose,
                          onPressed: () {
                            if (ModalRoute.of(context)?.isCurrent == true) {
                              Navigator.maybePop(context);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(BusyMarkSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: children,
                      ),
                    ),
                  ),
                  if (actions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(BusyMarkSpacing.lg),
                      child: OverflowBar(
                        alignment: MainAxisAlignment.end,
                        spacing: BusyMarkSpacing.sm,
                        overflowSpacing: BusyMarkSpacing.sm,
                        children: actions,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Labelled native dialog action, preserving the application's semantic roles.
class BusyMarkNativeDialogButton extends StatelessWidget {
  const BusyMarkNativeDialogButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.suggested = false,
    this.destructive = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool suggested, destructive;
  @override
  Widget build(BuildContext context) => BusyMarkNativeActionButton(
    role: destructive
        ? BusyMarkNativeActionRole.destructive
        : suggested
        ? BusyMarkNativeActionRole.suggested
        : BusyMarkNativeActionRole.standard,
    onPressed: onPressed,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: BusyMarkSizes.iconSm),
          const SizedBox(width: BusyMarkSpacing.sm),
        ],
        Flexible(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    ),
  );
}
