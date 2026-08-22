import 'package:flutter/material.dart';

import '../../app/busymark_design.dart';
import '../../app/localization.dart';
import '../text_format_metadata.dart';

/// Compact active-document format status for the pane header.
///
/// Encoding and final-newline details stay available without recreating the
/// old full-width footer. A BOM is included in the visible label because its
/// presence is otherwise impossible to infer from the editor text.
class BusyMarkDocumentFormatIndicator extends StatelessWidget {
  const BusyMarkDocumentFormatIndicator({super.key, required this.format});

  final TextFormatMetadata format;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final lineEnding = switch (format.lineEnding) {
      DocumentLineEnding.none || DocumentLineEnding.lf => 'LF',
      DocumentLineEnding.crlf => 'CRLF',
      DocumentLineEnding.mixed => 'LF/CRLF',
    };
    final encoding = format.hasUtf8Bom ? 'UTF-8 BOM' : 'UTF-8';
    final label = format.hasUtf8Bom ? 'BOM · $lineEnding' : lineEnding;
    final details = format.hasFinalNewline
        ? context.l10n.documentFormatWithFinalNewline(encoding, lineEnding)
        : context.l10n.documentFormatWithoutFinalNewline(encoding, lineEnding);

    return Tooltip(
      message: details,
      child: Semantics(
        label: details,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: BusyMarkSpacing.xs),
          child: Text(
            label,
            maxLines: 1,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.mutedForeground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
