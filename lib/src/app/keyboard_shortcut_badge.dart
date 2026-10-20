import 'package:flutter/material.dart';
import 'busymark_design.dart';

class BusyMarkKeyboardShortcutBadge extends StatelessWidget {
  const BusyMarkKeyboardShortcutBadge(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.control,
        borderRadius: BorderRadius.circular(BusyMarkRadius.sm),
        border: Border.all(color: colors.subtleBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BusyMarkSpacing.sm,
          vertical: BusyMarkSpacing.xxs,
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            // Let a narrow/scaled badge wrap between modifiers, rather than
            // splitting a name such as Shift. Identity never comes from text.
            label.replaceAll('+', '+\u200B'),
            semanticsLabel: label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontFamily: BusyMarkTypography.monoFontFamily,
              fontFamilyFallback: BusyMarkTypography.monoFontFamilyFallback,
              color: colors.foreground,
            ),
          ),
        ),
      ),
    );
  }
}
