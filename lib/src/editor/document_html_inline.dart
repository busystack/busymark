import 'package:material_ui/material_ui.dart';

import '../markdown/semantic_html_inline.dart';
import 'document_text_direction.dart';

TextStyle busyMarkHtmlInlineTextStyle(
  BuildContext context,
  String tag,
  TextStyle base,
) {
  final theme = Theme.of(context);
  return switch (tag) {
    'mark' => base.copyWith(
      color: theme.colorScheme.onTertiaryContainer,
      backgroundColor: theme.colorScheme.tertiaryContainer,
    ),
    'sub' => base.copyWith(fontFeatures: [const FontFeature.subscripts()]),
    'sup' ||
    'rt' => base.copyWith(fontFeatures: [const FontFeature.superscripts()]),
    'small' => base.copyWith(
      fontSize:
          (base.fontSize ?? theme.textTheme.bodyMedium?.fontSize ?? 14) * .8,
    ),
    'cite' || 'var' => base.copyWith(fontStyle: FontStyle.italic),
    'ins' => base.copyWith(decoration: TextDecoration.underline),
    'kbd' || 'samp' => base.copyWith(fontFamily: 'monospace'),
    _ => base,
  };
}

InlineSpan? busyMarkRenderedHtmlInline(
  BuildContext context,
  Map<String, String> attributes,
  TextStyle? baseStyle,
  List<InlineSpan> Function(TextStyle?) content,
) {
  final tag = semanticHtmlInlineTag(attributes);
  if (tag == null) return null;
  // Parentheses in <rp> are only for consumers without ruby support. An
  // annotation remains visually distinct when drawn on Flutter's text line.
  if (tag == 'rp' || tag == 'wbr') return const TextSpan();
  final style = busyMarkHtmlInlineTextStyle(
    context,
    tag,
    baseStyle ?? DefaultTextStyle.of(context).style,
  );
  final direction = busyMarkInlineDirectionControls(attributes);
  return TextSpan(
    style: style,
    children: [
      if (direction != null) TextSpan(text: direction.open),
      if (tag == 'q') const TextSpan(text: '“'),
      ...content(style),
      if (tag == 'q') const TextSpan(text: '”'),
      if (direction != null) TextSpan(text: direction.close),
    ],
  );
}
