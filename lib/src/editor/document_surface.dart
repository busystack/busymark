import 'package:flutter/material.dart';

import '../app/busymark_design.dart';

/// Shared prose typography for editable and rendered document views.
TextStyle busyMarkDocumentBodyTextStyle(BuildContext context, {Color? color}) {
  return (Theme.of(context).textTheme.bodyMedium ?? const TextStyle()).copyWith(
    color: color,
    height: BusyMarkTypography.bodyLineHeight,
  );
}

/// Shared heading typography for editable and rendered document views.
TextStyle busyMarkDocumentHeadingTextStyle(BuildContext context, int? level) {
  final effectiveLevel = level != null && level >= 1 && level <= 6 ? level : 6;
  final bodyStyle = busyMarkDocumentBodyTextStyle(context);
  final bodySize = bodyStyle.fontSize ?? BusyMarkTypography.defaultFontSize;
  return bodyStyle.copyWith(
    fontSize:
        bodySize * BusyMarkTypography.markdownHeadingScale(effectiveLevel),
    fontWeight: FontWeight.w700,
    height: BusyMarkTypography.markdownHeadingLineHeight(effectiveLevel),
  );
}

/// Resolves the actual child inset of [BusyMarkDocumentSurface].
///
/// Flutter includes a decorated container's border dimensions in addition to
/// its explicit padding. Text hit testing must use the same combined inset.
EdgeInsets busyMarkDocumentSurfaceLayoutInsets(EdgeInsets contentPadding) {
  return EdgeInsets.fromLTRB(
    contentPadding.left + BusyMarkStroke.hairline,
    contentPadding.top + BusyMarkStroke.hairline,
    contentPadding.right + BusyMarkStroke.hairline,
    contentPadding.bottom + BusyMarkStroke.hairline,
  );
}

/// Shared frame for rendered and editable document blocks.
///
/// Document views provide the content while this component owns the surface
/// geometry. That keeps Editor, Preview, and embedded renderers visually in
/// sync without coupling their editing behavior.
class BusyMarkDocumentSurface extends StatelessWidget {
  const BusyMarkDocumentSurface({
    super.key,
    required this.child,
    required this.margin,
    required this.padding,
    this.backgroundColor,
    this.borderRadius = BusyMarkRadius.md,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final double borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final frame = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? colors.panel,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: colors.subtleBorder,
          width: BusyMarkStroke.hairline,
        ),
      ),
      child: child,
    );
    final tapHandler = onTap;
    return tapHandler == null
        ? frame
        : GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: tapHandler,
            child: frame,
          );
  }
}
