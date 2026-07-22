import 'package:flutter/material.dart';

import '../app/busymark_design.dart';
import 'document_surface.dart';

enum BusyMarkDocumentCodeBlockVariant { document, embedded }

TextStyle busyMarkDocumentCodeTextStyle(BuildContext context, {Color? color}) {
  return (Theme.of(context).textTheme.bodyMedium ?? const TextStyle()).copyWith(
    color: color,
    fontFamily: BusyMarkTypography.monoFontFamily,
    fontFamilyFallback: BusyMarkTypography.monoFontFamilyFallback,
    height: BusyMarkTypography.codeLineHeight,
  );
}

/// Shared code-block presentation used by every document view.
///
/// Editor and Preview deliberately supply different children (an editable
/// field and rendered text), but use this single frame for spacing and style.
class BusyMarkDocumentCodeBlock extends StatelessWidget {
  const BusyMarkDocumentCodeBlock({
    super.key,
    required this.child,
    this.backgroundColor,
    this.margin,
    this.variant = BusyMarkDocumentCodeBlockVariant.document,
    this.onTap,
  });

  final Widget child;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? margin;
  final BusyMarkDocumentCodeBlockVariant variant;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final embedded = variant == BusyMarkDocumentCodeBlockVariant.embedded;
    return BusyMarkDocumentSurface(
      margin:
          margin ??
          (embedded
              ? const EdgeInsets.symmetric(vertical: BusyMarkSpacing.xs)
              : BusyMarkInsets.documentCodeBlock),
      padding: BusyMarkInsets.documentCodeContent,
      backgroundColor: backgroundColor ?? (embedded ? colors.view : null),
      borderRadius: embedded ? BusyMarkRadius.sm : BusyMarkRadius.md,
      onTap: onTap,
      child: child,
    );
  }
}
