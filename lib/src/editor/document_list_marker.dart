import 'package:flutter/material.dart';

import '../app/busymark_design.dart';
import '../app/busymark_glyphs.dart';
import 'document_surface.dart';

/// Shared list marker geometry for Editor and Preview.
class BusyMarkDocumentListMarker extends StatelessWidget {
  const BusyMarkDocumentListMarker({
    super.key,
    this.ordered = false,
    this.marker,
    this.task,
    this.hidden = false,
    this.onTaskChanged,
    this.taskTooltip,
  }) : assert(onTaskChanged == null || task != null);

  final bool ordered;
  final String? marker;
  final bool? task;
  final bool hidden;
  final ValueChanged<bool>? onTaskChanged;
  final String? taskTooltip;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final taskState = task;
    final markerWidget = hidden
        ? const SizedBox.shrink()
        : taskState != null
        ? _taskMarker(context, colors, taskState)
        : ordered
        ? Text(
            marker ?? '1.',
            textAlign: TextAlign.end,
            maxLines: 1,
            softWrap: false,
            style:
                busyMarkDocumentBodyTextStyle(
                  context,
                  color: colors.foreground,
                ).copyWith(
                  fontWeight: FontWeight.w600,
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

  Widget _taskMarker(
    BuildContext context,
    BusyMarkSurfaceColors colors,
    bool taskState,
  ) {
    final foreground = taskState
        ? Theme.of(context).colorScheme.primary
        : colors.foreground;
    final onChanged = onTaskChanged;
    if (onChanged == null) {
      return SizedBox.square(
        dimension: BusyMarkSizes.compactIconButton,
        child: Center(
          child: Icon(
            taskState ? BusyMarkGlyphs.checkedBox : BusyMarkGlyphs.task,
            size: BusyMarkSizes.iconSm,
            color: foreground,
          ),
        ),
      );
    }
    void toggle() => onChanged(!taskState);
    final tooltip = taskTooltip ?? '';
    return Semantics(
      container: true,
      checked: taskState,
      enabled: true,
      label: tooltip.isEmpty ? null : tooltip,
      onTap: toggle,
      child: ExcludeSemantics(
        child: BusyMarkCompactIconButton(
          tooltip: tooltip,
          icon: taskState ? BusyMarkGlyphs.checkedBox : BusyMarkGlyphs.task,
          size: BusyMarkSizes.compactIconButton,
          glyphSize: BusyMarkSizes.iconSm,
          foregroundColor: foreground,
          onPressed: toggle,
        ),
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
