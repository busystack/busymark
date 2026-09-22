import 'package:flutter/material.dart';

import '../../app/busymark_design.dart';
import '../text_format_metadata.dart';
import 'document_format_indicator.dart';

class BusyMarkDocumentStatusBar extends StatelessWidget {
  const BusyMarkDocumentStatusBar({
    super.key,
    required this.format,
    this.spellingLabel,
    this.spellingTooltip,
    this.onSpellingPressed,
  });

  final TextFormatMetadata format;
  final String? spellingLabel;
  final String? spellingTooltip;
  final VoidCallback? onSpellingPressed;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return DecoratedBox(
      key: const ValueKey('document-status-bar'),
      decoration: BoxDecoration(
        color: colors.headerbarFlat,
        border: Border(top: BorderSide(color: colors.subtleBorder)),
      ),
      child: SizedBox(
        height: BusyMarkSizes.documentStatusBarHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: BusyMarkSpacing.xs),
          child: Row(
            children: [
              if (spellingLabel case final label?)
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: _DocumentStatusAction(
                      label: label,
                      tooltip: spellingTooltip,
                      onPressed: onSpellingPressed,
                    ),
                  ),
                )
              else
                const Spacer(),
              BusyMarkDocumentFormatIndicator(format: format),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentStatusAction extends StatelessWidget {
  const _DocumentStatusAction({
    required this.label,
    required this.tooltip,
    required this.onPressed,
  });

  final String label;
  final String? tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    Widget action = Semantics(
      key: const ValueKey('document-spelling-language-status'),
      button: true,
      enabled: onPressed != null,
      child: Material(
        color: BusyMarkLinuxPalette.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(BusyMarkRadius.sm),
          hoverColor: busyMarkRowHoverColor(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BusyMarkSpacing.sm,
              vertical: BusyMarkSpacing.xxs,
            ),
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: colors.mutedForeground),
            ),
          ),
        ),
      ),
    );
    if (tooltip case final message?) {
      action = Tooltip(message: message, child: action);
    }
    return action;
  }
}
