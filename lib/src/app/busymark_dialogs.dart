import 'package:flutter/material.dart';

import '../platform/linux_header_bar_service.dart';
import 'busymark_design.dart';

Color busyMarkModalBarrierColor(BuildContext context) {
  return Theme.of(context).colorScheme.scrim.withValues(alpha: 0.32);
}

Future<T?> showBusyMarkModalDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  LinuxHeaderBarService? headerBarService,
}) async {
  final barrierColor = busyMarkModalBarrierColor(context);
  await headerBarService?.setModalBarrierVisible(true);
  if (!context.mounted) {
    await headerBarService?.setModalBarrierVisible(false);
    return null;
  }
  try {
    return await showDialog<T>(
      context: context,
      barrierColor: barrierColor,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        child: BusyMarkModalEditorSurface(child: builder(dialogContext)),
      ),
    );
  } finally {
    await headerBarService?.setModalBarrierVisible(false);
  }
}

class BusyMarkModalEditorSurface extends StatelessWidget {
  const BusyMarkModalEditorSurface({
    super.key,
    required this.child,
    this.maxWidth = 860,
    this.maxHeight,
  });

  final Widget child;
  final double maxWidth;
  final double? maxHeight;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(BusyMarkRadius.lg),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: maxHeight ?? MediaQuery.sizeOf(context).height * 0.86,
        ),
        child: ColoredBox(color: colors.dialog, child: child),
      ),
    );
  }
}
