import 'package:flutter/material.dart';

import '../app/busymark_design.dart';
import '../app/busymark_glyphs.dart';
import 'document_surface.dart';

/// Shared Writerside admonition presentation for Editor and Preview.
class BusyMarkDocumentAdmonition extends StatelessWidget {
  const BusyMarkDocumentAdmonition({
    super.key,
    required this.style,
    required this.child,
    this.margin = BusyMarkInsets.documentCalloutBlock,
    this.onTap,
  });

  final String? style;
  final Widget child;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return BusyMarkDocumentCallout(
      icon: switch (style) {
        'warning' => BusyMarkGlyphs.warning,
        'tip' => BusyMarkGlyphs.tip,
        _ => BusyMarkGlyphs.info,
      },
      backgroundColor: switch (style) {
        'warning' => colors.admonitionWarning,
        'tip' => colors.admonitionTip,
        _ => colors.admonitionNote,
      },
      margin: margin,
      onTap: onTap,
      child: child,
    );
  }
}

/// Shared document surface for quotes, admonitions, and similar callouts.
///
/// The component owns its visual geometry so editable and rendered document
/// views cannot drift by choosing different icon, padding, or border values.
class BusyMarkDocumentCallout extends StatelessWidget {
  const BusyMarkDocumentCallout({
    super.key,
    required this.icon,
    required this.child,
    this.backgroundColor,
    this.margin = BusyMarkInsets.documentCalloutBlock,
    this.onTap,
  });

  final IconData icon;
  final Widget child;
  final Color? backgroundColor;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return BusyMarkDocumentSurface(
      margin: margin,
      padding: BusyMarkInsets.documentCalloutContent,
      backgroundColor: backgroundColor,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: BusyMarkSizes.iconMd),
          const SizedBox(width: BusyMarkSpacing.sm),
          Expanded(child: child),
        ],
      ),
    );
  }
}
