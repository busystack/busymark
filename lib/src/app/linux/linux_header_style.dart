import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../platform/gtk_header_icon_service.dart';
import '../busymark_design.dart';
import 'linux_window_host.dart';

abstract final class BusyMarkLinuxHeaderStyle {
  static const double activeForegroundOpacity = 1;
  static const double inactiveForegroundOpacity = .50;
  static const double disabledActiveForegroundOpacity = .38;
  static const double disabledInactiveForegroundOpacity = .19;
  static const double hoverBackgroundStrength = .07;
  static const double pressedBackgroundStrength = .16;
  static const double selectedBackgroundStrength = .10;
  static const double selectedHoverBackgroundStrength = .13;
  static const double selectedPressedBackgroundStrength = .19;
}

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

Color busyMarkLinuxHeaderForeground(
  BuildContext context, {
  bool disabled = false,
}) {
  final active = LinuxWindowMetricsScope.of(context).windowActive;
  final opacity = switch ((active, disabled)) {
    (true, false) => BusyMarkLinuxHeaderStyle.activeForegroundOpacity,
    (false, false) => BusyMarkLinuxHeaderStyle.inactiveForegroundOpacity,
    (true, true) => BusyMarkLinuxHeaderStyle.disabledActiveForegroundOpacity,
    (false, true) => BusyMarkLinuxHeaderStyle.disabledInactiveForegroundOpacity,
  };
  final foreground = BusyMarkSurfaceColors.of(context).foreground;
  return foreground.withValues(alpha: foreground.a * opacity);
}

WidgetStateProperty<Color?> busyMarkLinuxHeaderControlBackground(
  BuildContext context,
) {
  final foreground = busyMarkLinuxHeaderForeground(context);
  Color layer(double strength) =>
      foreground.withValues(alpha: foreground.a * strength);
  return WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.disabled)) {
      return BusyMarkLinuxPalette.transparent;
    }
    final selected = states.contains(WidgetState.selected);
    final pressed = states.contains(WidgetState.pressed);
    final hovered = states.contains(WidgetState.hovered);
    if (selected && pressed) {
      return layer(BusyMarkLinuxHeaderStyle.selectedPressedBackgroundStrength);
    }
    if (selected && hovered) {
      return layer(BusyMarkLinuxHeaderStyle.selectedHoverBackgroundStrength);
    }
    if (pressed) {
      return layer(BusyMarkLinuxHeaderStyle.pressedBackgroundStrength);
    }
    if (selected) {
      return layer(BusyMarkLinuxHeaderStyle.selectedBackgroundStrength);
    }
    if (hovered) {
      return layer(BusyMarkLinuxHeaderStyle.hoverBackgroundStrength);
    }
    return BusyMarkLinuxPalette.transparent;
  });
}

/// An application-header icon button with neutral GTK-style state layers.
///
/// Selection remains available to semantics and paints a subtle neutral
/// background, but never changes the symbolic icon to the accent color.
class BusyMarkLinuxHeaderIconButton extends StatelessWidget {
  const BusyMarkLinuxHeaderIconButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.nativeIcon,
    this.selected = false,
    this.shortcut,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final BusyMarkLinuxHeaderIcon? nativeIcon;
  final bool selected;
  final String? shortcut;

  @override
  Widget build(BuildContext context) {
    return BusyMarkHeaderIconButton(
      tooltip: tooltip,
      icon: icon,
      nativeIcon: nativeIcon,
      selected: selected,
      shortcut: shortcut,
      foregroundColor: busyMarkLinuxHeaderForeground(context),
      disabledForegroundColor: busyMarkLinuxHeaderForeground(
        context,
        disabled: true,
      ),
      backgroundColor: busyMarkLinuxHeaderControlBackground(context),
      overlayColor: const WidgetStatePropertyAll(
        BusyMarkLinuxPalette.transparent,
      ),
      onPressed: onPressed,
    );
  }
}

class BusyMarkLinuxHeaderControlGroup extends StatelessWidget {
  const BusyMarkLinuxHeaderControlGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return BusyMarkHeaderControlStyleScope(
      foregroundColor: busyMarkLinuxHeaderForeground(context),
      disabledForegroundColor: busyMarkLinuxHeaderForeground(
        context,
        disabled: true,
      ),
      backgroundColor: busyMarkLinuxHeaderControlBackground(context),
      overlayColor: const WidgetStatePropertyAll(
        BusyMarkLinuxPalette.transparent,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0) const SizedBox(width: BusyMarkSpacing.headerInset),
            children[index],
          ],
        ],
      ),
    );
  }
}

TextStyle busyMarkLinuxHeaderTitleStyle(BuildContext context) {
  return Theme.of(context).textTheme.titleSmall!.copyWith(
    fontWeight: FontWeight.w600,
    color: busyMarkLinuxHeaderForeground(context),
  );
}

TextStyle busyMarkLinuxHeaderBrandStyle(BuildContext context) =>
    busyMarkLinuxHeaderTitleStyle(
      context,
    ).copyWith(fontWeight: FontWeight.w700);

enum _BusyMarkLinuxHeaderSlot { leading, title, trailing }

enum BusyMarkLinuxHeaderCenterAllocation {
  centeredBetweenControls,
  fillBetweenControls,
}

/// GTK-style application header geometry with an explicit center allocation.
class BusyMarkLinuxHeaderLayout extends StatelessWidget {
  const BusyMarkLinuxHeaderLayout({
    super.key,
    required this.leading,
    required this.title,
    required this.trailing,
    this.maxContentWidth,
    this.centerAllocation =
        BusyMarkLinuxHeaderCenterAllocation.centeredBetweenControls,
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
    final availableWidth = math.max(0.0, safeRightEdge - safeLeftEdge);
    switch (centerAllocation) {
      case BusyMarkLinuxHeaderCenterAllocation.centeredBetweenControls:
        // Center in the actual control gap, including asymmetric button groups
        // and the space reserved for the window controls.
        final centerX = (safeLeftEdge + safeRightEdge) / 2;
        final titleSize = layoutChild(
          _BusyMarkLinuxHeaderSlot.title,
          BoxConstraints.loose(Size(availableWidth, size.height)),
        );
        positionChild(
          _BusyMarkLinuxHeaderSlot.title,
          Offset(
            centerX - titleSize.width / 2,
            (size.height - titleSize.height) / 2,
          ),
        );
      case BusyMarkLinuxHeaderCenterAllocation.fillBetweenControls:
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
