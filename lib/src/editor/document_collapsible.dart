import 'package:flutter/material.dart';

import '../app/busymark_design.dart';
import '../app/busymark_glyphs.dart';
import '../app/localization.dart';

/// Shared Writerside collapsible presentation for Editor and Preview.
class BusyMarkDocumentCollapsible extends StatefulWidget {
  const BusyMarkDocumentCollapsible({
    super.key,
    required this.header,
    required this.child,
    required this.kindLabel,
    this.initiallyExpanded = false,
    this.expanded,
    this.onExpansionChanged,
    this.framed = false,
    this.toggleOnHeaderTap = true,
    this.margin = const EdgeInsets.symmetric(vertical: BusyMarkSpacing.xs),
  });

  final Widget header;
  final Widget child;
  final String kindLabel;
  final bool initiallyExpanded;
  final bool? expanded;
  final ValueChanged<bool>? onExpansionChanged;
  final bool framed;
  final bool toggleOnHeaderTap;
  final EdgeInsetsGeometry margin;

  @override
  State<BusyMarkDocumentCollapsible> createState() =>
      _BusyMarkDocumentCollapsibleState();
}

class _BusyMarkDocumentCollapsibleState
    extends State<BusyMarkDocumentCollapsible> {
  late bool _expanded = widget.initiallyExpanded;

  bool get _effectiveExpanded => widget.expanded ?? _expanded;

  @override
  void didUpdateWidget(BusyMarkDocumentCollapsible oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expanded == null &&
        oldWidget.initiallyExpanded != widget.initiallyExpanded) {
      _expanded = widget.initiallyExpanded;
    }
  }

  void _toggle() {
    final next = !_effectiveExpanded;
    widget.onExpansionChanged?.call(next);
    if (widget.expanded == null) {
      setState(() => _expanded = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final expanded = _effectiveExpanded;
    final tooltip = expanded
        ? context.l10n.collapseKind(widget.kindLabel)
        : context.l10n.expandKind(widget.kindLabel);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [_header(context, colors, tooltip), if (expanded) widget.child],
    );
    if (!widget.framed) {
      return Padding(padding: widget.margin, child: content);
    }
    return Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        color: colors.panel,
        borderRadius: BorderRadius.circular(BusyMarkRadius.md),
        border: Border.all(
          color: colors.subtleBorder,
          width: BusyMarkStroke.hairline,
        ),
      ),
      child: content,
    );
  }

  Widget _header(
    BuildContext context,
    BusyMarkSurfaceColors colors,
    String tooltip,
  ) {
    final icon = _effectiveExpanded
        ? BusyMarkGlyphs.downArrow
        : BusyMarkGlyphs.collapsedTreeArrowFor(Directionality.of(context));
    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BusyMarkSpacing.xs,
        vertical: BusyMarkSpacing.xs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (widget.toggleOnHeaderTap)
            Tooltip(
              message: tooltip,
              child: Icon(
                icon,
                size: BusyMarkSizes.iconSm,
                color: colors.mutedForeground,
              ),
            )
          else
            IconButton(
              tooltip: tooltip,
              onPressed: _toggle,
              icon: Icon(icon),
              iconSize: BusyMarkSizes.iconSm,
              visualDensity: VisualDensity.compact,
            ),
          const SizedBox(width: BusyMarkSpacing.sm),
          Expanded(child: widget.header),
        ],
      ),
    );
    if (!widget.toggleOnHeaderTap) {
      return row;
    }
    return Semantics(
      button: true,
      expanded: _effectiveExpanded,
      label: tooltip,
      child: InkWell(
        onTap: _toggle,
        borderRadius: BorderRadius.circular(BusyMarkRadius.sm),
        child: row,
      ),
    );
  }
}
