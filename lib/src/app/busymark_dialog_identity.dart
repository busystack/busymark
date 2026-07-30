import 'package:flutter/material.dart';

import 'busymark_design.dart';

/// Native Yaru chrome shared by BusyMark's informational dialogs.
///
/// The title bar stays outside the scroll viewport so its close control remains
/// fixed while long reference content scrolls independently.
class BusyMarkInformationalDialog extends StatelessWidget {
  const BusyMarkInformationalDialog({
    required this.closeLabel,
    required this.maxWidth,
    required this.child,
    this.maxHeight,
    super.key,
  });

  final String closeLabel;
  final double maxWidth;
  final double? maxHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dialogSurface = busyMarkDialogSurfaceColor(context);
    return Dialog(
      backgroundColor: dialogSurface,
      surfaceTintColor: dialogSurface,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: maxHeight ?? double.infinity,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BusyMarkDialogTitleBar(closeSemanticLabel: closeLabel),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(BusyMarkSpacing.lg),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared application identity treatment for informational dialogs.
class BusyMarkDialogIdentity extends StatelessWidget {
  const BusyMarkDialogIdentity({
    required this.visual,
    required this.title,
    super.key,
  });

  static const visualExtent = 128.0;
  static const titleWeight = FontWeight.bold;

  final Widget visual;
  final String title;

  @override
  Widget build(BuildContext context) {
    final titleStyle =
        Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: titleWeight) ??
        const TextStyle(fontWeight: titleWeight);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: BusyMarkSpacing.md),
            child: SizedBox.square(dimension: visualExtent, child: visual),
          ),
        ),
        const SizedBox(height: BusyMarkSpacing.md),
        Text(title, textAlign: TextAlign.center, style: titleStyle),
      ],
    );
  }
}
