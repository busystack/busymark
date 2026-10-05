import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../busymark_design.dart';
import 'linux_window_host.dart';

class LinuxPageHeaderInsetsScope extends InheritedWidget {
  const LinuxPageHeaderInsetsScope({
    super.key,
    required this.leftObstruction,
    required this.rightObstruction,
    required super.child,
  });

  final double leftObstruction;
  final double rightObstruction;

  static const _fallback = LinuxPageHeaderInsetsScope(
    leftObstruction: 0,
    rightObstruction: 0,
    child: SizedBox.shrink(),
  );

  static LinuxPageHeaderInsetsScope of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<LinuxPageHeaderInsetsScope>() ??
      _fallback;

  @override
  bool updateShouldNotify(LinuxPageHeaderInsetsScope oldWidget) =>
      leftObstruction != oldWidget.leftObstruction ||
      rightObstruction != oldWidget.rightObstruction;
}

TextStyle busyMarkLinuxHeaderTitleStyle(BuildContext context) {
  final colors = BusyMarkSurfaceColors.of(context);
  final active = LinuxWindowMetricsScope.of(context).windowActive;
  return Theme.of(context).textTheme.titleSmall!.copyWith(
    fontWeight: FontWeight.w600,
    color: colors.foreground.withValues(alpha: active ? 1 : .5),
  );
}

TextStyle busyMarkLinuxHeaderBrandStyle(BuildContext context) =>
    busyMarkLinuxHeaderTitleStyle(
      context,
    ).copyWith(fontWeight: FontWeight.w700);

enum _BusyMarkLinuxHeaderSlot { leading, title, trailing }

enum BusyMarkLinuxHeaderCenterAllocation { centered, fillBetweenControls }

/// GTK-style application header geometry with an explicit center allocation.
class BusyMarkLinuxHeaderLayout extends StatelessWidget {
  const BusyMarkLinuxHeaderLayout({
    super.key,
    required this.leading,
    required this.title,
    required this.trailing,
    this.maxContentWidth,
    this.centerAllocation = BusyMarkLinuxHeaderCenterAllocation.centered,
  });

  final Widget leading;
  final Widget title;
  final Widget trailing;
  final double? maxContentWidth;
  final BusyMarkLinuxHeaderCenterAllocation centerAllocation;

  @override
  Widget build(BuildContext context) {
    final insets = LinuxPageHeaderInsetsScope.of(context);
    final direction = Directionality.of(context);
    return SizedBox(
      height: BusyMarkSizes.toolbarHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const LinuxTitlebarGestureRegion(child: SizedBox.expand()),
          CustomMultiChildLayout(
            delegate: _BusyMarkLinuxHeaderLayoutDelegate(
              direction: direction,
              leftObstruction: insets.leftObstruction,
              rightObstruction: insets.rightObstruction,
              maxContentWidth: maxContentWidth,
              centerAllocation: centerAllocation,
            ),
            children: [
              LayoutId(id: _BusyMarkLinuxHeaderSlot.leading, child: leading),
              LayoutId(id: _BusyMarkLinuxHeaderSlot.title, child: title),
              LayoutId(id: _BusyMarkLinuxHeaderSlot.trailing, child: trailing),
            ],
          ),
        ],
      ),
    );
  }
}

class _BusyMarkLinuxHeaderLayoutDelegate extends MultiChildLayoutDelegate {
  _BusyMarkLinuxHeaderLayoutDelegate({
    required this.direction,
    required this.leftObstruction,
    required this.rightObstruction,
    required this.maxContentWidth,
    required this.centerAllocation,
  });

  final TextDirection direction;
  final double leftObstruction;
  final double rightObstruction;
  final double? maxContentWidth;
  final BusyMarkLinuxHeaderCenterAllocation centerAllocation;

  @override
  void performLayout(Size size) {
    final centeredInset = maxContentWidth == null
        ? 0.0
        : math.max(0.0, (size.width - maxContentWidth!) / 2);
    final leftInset = math.max(
      leftObstruction + BusyMarkSpacing.headerInset,
      centeredInset,
    );
    final rightInset = math.max(
      rightObstruction + BusyMarkSpacing.headerInset,
      centeredInset,
    );
    final sideConstraints = BoxConstraints.loose(
      Size(math.max(0, size.width - leftInset - rightInset), size.height),
    );
    final leadingSize = layoutChild(
      _BusyMarkLinuxHeaderSlot.leading,
      sideConstraints,
    );
    final trailingSize = layoutChild(
      _BusyMarkLinuxHeaderSlot.trailing,
      sideConstraints,
    );

    late final Offset leadingOffset;
    late final Offset trailingOffset;
    late final double leftOccupiedEdge;
    late final double rightOccupiedEdge;
    if (direction == TextDirection.ltr) {
      leadingOffset = Offset(leftInset, (size.height - leadingSize.height) / 2);
      trailingOffset = Offset(
        size.width - rightInset - trailingSize.width,
        (size.height - trailingSize.height) / 2,
      );
      leftOccupiedEdge = leadingOffset.dx + leadingSize.width;
      rightOccupiedEdge = trailingOffset.dx;
    } else {
      leadingOffset = Offset(
        size.width - rightInset - leadingSize.width,
        (size.height - leadingSize.height) / 2,
      );
      trailingOffset = Offset(
        leftInset,
        (size.height - trailingSize.height) / 2,
      );
      leftOccupiedEdge = trailingOffset.dx + trailingSize.width;
      rightOccupiedEdge = leadingOffset.dx;
    }
    positionChild(_BusyMarkLinuxHeaderSlot.leading, leadingOffset);
    positionChild(_BusyMarkLinuxHeaderSlot.trailing, trailingOffset);

    final safeLeftEdge = leftOccupiedEdge + BusyMarkSpacing.headerInset;
    final safeRightEdge = rightOccupiedEdge - BusyMarkSpacing.headerInset;
    switch (centerAllocation) {
      case BusyMarkLinuxHeaderCenterAllocation.centered:
        final centerX = size.width / 2;
        final availableWidth = math.max(0.0, safeRightEdge - safeLeftEdge);
        final minimumHalfWidth =
            math.min(BusyMarkSizes.headerTitleMinWidth, availableWidth) / 2;
        // Clamp continuously into the safe control gap as the sidebar moves.
        // Wide headers keep absolute centering; narrow headers keep a readable
        // title without jumping between two allocation policies.
        final titleCenter = availableWidth == 0
            ? (safeLeftEdge + safeRightEdge) / 2
            : centerX
                  .clamp(
                    safeLeftEdge + minimumHalfWidth,
                    safeRightEdge - minimumHalfWidth,
                  )
                  .toDouble();
        final safeHalfWidth = math.max(
          0.0,
          math.min(titleCenter - safeLeftEdge, safeRightEdge - titleCenter),
        );
        final titleSize = layoutChild(
          _BusyMarkLinuxHeaderSlot.title,
          BoxConstraints.loose(Size(safeHalfWidth * 2, size.height)),
        );
        positionChild(
          _BusyMarkLinuxHeaderSlot.title,
          Offset(
            titleCenter - titleSize.width / 2,
            (size.height - titleSize.height) / 2,
          ),
        );
      case BusyMarkLinuxHeaderCenterAllocation.fillBetweenControls:
        final availableWidth = math.max(0.0, safeRightEdge - safeLeftEdge);
        final titleSize = layoutChild(
          _BusyMarkLinuxHeaderSlot.title,
          BoxConstraints(
            minWidth: availableWidth,
            maxWidth: availableWidth,
            minHeight: 0,
            maxHeight: size.height,
          ),
        );
        positionChild(
          _BusyMarkLinuxHeaderSlot.title,
          Offset(safeLeftEdge, (size.height - titleSize.height) / 2),
        );
    }
  }

  @override
  bool shouldRelayout(_BusyMarkLinuxHeaderLayoutDelegate oldDelegate) =>
      direction != oldDelegate.direction ||
      leftObstruction != oldDelegate.leftObstruction ||
      rightObstruction != oldDelegate.rightObstruction ||
      maxContentWidth != oldDelegate.maxContentWidth ||
      centerAllocation != oldDelegate.centerAllocation;
}

class BusyMarkLinuxHeaderTitle extends StatelessWidget {
  const BusyMarkLinuxHeaderTitle(this.text, {super.key, this.brand = false});

  final String text;
  final bool brand;

  @override
  Widget build(BuildContext context) {
    return LinuxTitlebarGestureRegion(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: BusyMarkSpacing.md),
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: brand
              ? busyMarkLinuxHeaderBrandStyle(context)
              : busyMarkLinuxHeaderTitleStyle(context),
        ),
      ),
    );
  }
}
