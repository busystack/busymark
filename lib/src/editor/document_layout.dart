import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/app_settings.dart';
import '../app/busymark_design.dart';

/// The document canvas shared by the editable and rendered document views.
///
/// [minimumInsets] are physical so document chrome and its reserved space stay
/// on the same edge when the surrounding application is right-to-left.
@immutable
class BusyMarkDocumentLayoutSpec {
  const BusyMarkDocumentLayoutSpec({
    required this.minimumInsets,
    this.maxContentWidth,
  });

  static const standalone = BusyMarkDocumentLayoutSpec(
    minimumInsets: EdgeInsets.fromLTRB(
      BusyMarkSpacing.xl,
      BusyMarkSourceEditorMetrics.paddingTop,
      BusyMarkSpacing.xl,
      BusyMarkSizes.iconButton,
    ),
    maxContentWidth: BusyMarkSizes.documentContentWidth,
  );

  /// The fluid document canvas used beside Source in Split view.
  ///
  /// Source's line-number gutter is intentionally excluded: it is editor
  /// chrome and has no counterpart in Preview.
  static const splitPreview = BusyMarkDocumentLayoutSpec(
    minimumInsets: EdgeInsets.fromLTRB(
      BusyMarkSpacing.xl,
      BusyMarkSourceEditorMetrics.paddingTop,
      BusyMarkSpacing.xl,
      BusyMarkSizes.iconButton,
    ),
  );

  final EdgeInsets minimumInsets;
  final double? maxContentWidth;

  EdgeInsets get scrollPadding =>
      EdgeInsets.only(top: minimumInsets.top, bottom: minimumInsets.bottom);

  /// Reserves the toolbar lane on the edge where editing controls appear.
  ///
  /// Applying the same spec to standalone Editor and Preview prevents the
  /// document from moving when the user changes view mode.
  BusyMarkDocumentLayoutSpec withEditingToolbar({
    required EditorToolbarPlacement placement,
    required EditorToolbarDirection direction,
  }) {
    final left =
        direction == EditorToolbarDirection.vertical &&
            (placement == EditorToolbarPlacement.topLeft ||
                placement == EditorToolbarPlacement.bottomLeft)
        ? math.max(minimumInsets.left, BusyMarkSizes.wysiwygToolbarClearance)
        : minimumInsets.left;
    final top =
        direction == EditorToolbarDirection.horizontal &&
            (placement == EditorToolbarPlacement.topLeft ||
                placement == EditorToolbarPlacement.topRight)
        ? math.max(minimumInsets.top, BusyMarkSizes.wysiwygToolbarClearance)
        : minimumInsets.top;
    final right =
        direction == EditorToolbarDirection.vertical &&
            (placement == EditorToolbarPlacement.topRight ||
                placement == EditorToolbarPlacement.bottomRight)
        ? math.max(minimumInsets.right, BusyMarkSizes.wysiwygToolbarClearance)
        : minimumInsets.right;
    final bottom =
        direction == EditorToolbarDirection.horizontal &&
            (placement == EditorToolbarPlacement.bottomLeft ||
                placement == EditorToolbarPlacement.bottomRight)
        ? math.max(minimumInsets.bottom, BusyMarkSizes.wysiwygToolbarClearance)
        : minimumInsets.bottom;
    return BusyMarkDocumentLayoutSpec(
      minimumInsets: EdgeInsets.fromLTRB(left, top, right, bottom),
      maxContentWidth: maxContentWidth,
    );
  }
}

/// Applies a document layout spec without duplicating centering and width
/// calculations in the Editor and Preview renderers.
class BusyMarkDocumentContentFrame extends StatelessWidget {
  const BusyMarkDocumentContentFrame({
    super.key,
    required this.layout,
    required this.child,
    this.contentKey,
  });

  final BusyMarkDocumentLayoutSpec layout;
  final Widget child;
  final Key? contentKey;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final paneWidth = constraints.maxWidth;
        final minimumLeft = math.min(layout.minimumInsets.left, paneWidth);
        final minimumRight = math.min(
          layout.minimumInsets.right,
          math.max(0, paneWidth - minimumLeft),
        );
        final availableWidth = math.max(
          0,
          paneWidth - minimumLeft - minimumRight,
        );
        final maxContentWidth = layout.maxContentWidth;
        final contentWidth = maxContentWidth == null
            ? availableWidth
            : math.min(maxContentWidth, availableWidth);
        final centeredLeft = (paneWidth - contentWidth) / 2;
        final maximumLeft = paneWidth - minimumRight - contentWidth;
        final contentLeft = centeredLeft
            .clamp(minimumLeft, maximumLeft)
            .toDouble();
        final contentRight = paneWidth - contentLeft - contentWidth;
        return Padding(
          padding: EdgeInsets.only(left: contentLeft, right: contentRight),
          child: SizedBox(
            key: contentKey,
            width: double.infinity,
            child: child,
          ),
        );
      },
    );
  }
}
