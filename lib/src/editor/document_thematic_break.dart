import 'package:flutter/material.dart';

import '../app/busymark_design.dart';

/// Shared thematic-break geometry for Editor and Preview.
///
/// The Editor handle is painted over the line so its editing affordance does
/// not change the document layout.
class BusyMarkDocumentThematicBreak extends StatelessWidget {
  const BusyMarkDocumentThematicBreak({
    super.key,
    this.editable = false,
    this.selected = false,
  });

  final bool editable;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final lineColor = selected
        ? scheme.primary.withValues(alpha: BusyMarkAlpha.thematicBreakSelected)
        : colors.mutedForeground.withValues(alpha: BusyMarkAlpha.thematicBreak);
    final handleColor = selected
        ? scheme.primary
        : colors.mutedForeground.withValues(
            alpha: BusyMarkAlpha.thematicBreakHandle,
          );
    return Padding(
      padding: BusyMarkInsets.documentThematicBreakBlock,
      child: SizedBox(
        height: BusyMarkStroke.thematicBreak,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: lineColor,
                  borderRadius: BorderRadius.circular(BusyMarkRadius.pill),
                ),
              ),
            ),
            if (editable)
              SizedBox(
                width: BusyMarkSizes.thematicBreakHandleWidth,
                height: BusyMarkSizes.markerDot,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: handleColor,
                    borderRadius: BorderRadius.circular(BusyMarkRadius.pill),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
