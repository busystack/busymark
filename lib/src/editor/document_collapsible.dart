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
    this.framed = false,
    this.toggleOnHeaderTap = true,
    this.margin = const EdgeInsets.symmetric(vertical: BusyMarkSpacing.xs),
  });

  final Widget header;
  final Widget child;
  final String kindLabel;
  final bool initiallyExpanded;
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

  @override
  void didUpdateWidget(BusyMarkDocumentCollapsible oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initiallyExpanded != widget.initiallyExpanded) {
      _expanded = widget.initiallyExpanded;
    }
  }

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final tooltip = _expanded
        ? context.l10n.collapseKind(widget.kindLabel)
        : context.l10n.expandKind(widget.kindLabel);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _header(context, colors, tooltip),
        if (_expanded) widget.child,
      ],
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
    final icon = _expanded
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
      expanded: _expanded,
      label: tooltip,
      child: InkWell(
        onTap: _toggle,
        borderRadius: BorderRadius.circular(BusyMarkRadius.sm),
        child: row,
      ),
    );
  }
}
