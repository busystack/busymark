import 'package:flutter/material.dart';

import '../app/busymark_design.dart';
import '../app/busymark_glyphs.dart';

/// Shared list marker geometry for Editor and Preview.
class BusyMarkDocumentListMarker extends StatelessWidget {
  const BusyMarkDocumentListMarker({
    super.key,
    this.ordered = false,
    this.marker,
    this.task,
  });

  final bool ordered;
  final String? marker;
  final bool? task;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final taskState = task;
    final markerWidget = taskState != null
        ? Icon(
            taskState ? BusyMarkGlyphs.checkedBox : BusyMarkGlyphs.task,
            size: BusyMarkSizes.iconSm,
            color: colors.mutedForeground,
          )
        : ordered
        ? Text(
            marker ?? '1.',
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.mutedForeground,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          )
        : Padding(
            padding: const EdgeInsets.only(
              top: BusyMarkSizes.listMarkerTopInset,
            ),
            child: SizedBox.square(
              dimension: BusyMarkSizes.markerDot,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.mutedForeground,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
    return SizedBox(
      width: BusyMarkSizes.documentListMarkerWidth,
      child: Padding(
        padding: const EdgeInsets.only(
          top: BusyMarkSizes.documentListMarkerTopInset,
        ),
        child: markerWidget,
      ),
    );
  }
}

EdgeInsets busyMarkDocumentListItemPadding({
  required bool listRunEnd,
  required bool endsWithNestedList,
}) {
  return EdgeInsets.only(
    top: BusyMarkSpacing.xs,
    bottom: listRunEnd && !endsWithNestedList
        ? BusyMarkSpacing.md
        : BusyMarkSpacing.xs,
  );
}
