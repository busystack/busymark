import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' show Bidi;

/// Resolves document block direction consistently in Editor and Preview.
TextDirection busyMarkDocumentTextDirection({
  required String text,
  required TextDirection fallback,
  String? explicitDirection,
  bool technical = false,
}) {
  switch (explicitDirection?.trim().toLowerCase()) {
    case 'ltr':
      return TextDirection.ltr;
    case 'rtl':
      return TextDirection.rtl;
    case 'auto':
      return _firstStrongTextDirection(text) ?? fallback;
  }
  if (technical) {
    return TextDirection.ltr;
  }
  return _firstStrongTextDirection(text) ?? fallback;
}

TextDirection? _firstStrongTextDirection(String text) {
  if (Bidi.startsWithRtl(text)) {
    return TextDirection.rtl;
  }
  if (Bidi.startsWithLtr(text)) {
    return TextDirection.ltr;
  }
  return null;
}

/// Inline HTML direction establishes a separate bidi scope inside a paragraph.
({String open, String close})? busyMarkInlineDirectionControls(
  Map<String, String> attributes,
) {
  final direction = attributes['dir'];
  if (attributes['htmlTag'] == null || direction == null) return null;
  if (attributes['htmlTag'] == 'bdo' && direction != 'auto') {
    return (
      open: direction == 'rtl' ? '\u2067\u202e' : '\u2066\u202d',
      close: '\u202c\u2069',
    );
  }
  return (
    open: switch (direction) {
      'ltr' => '\u2066',
      'rtl' => '\u2067',
      _ => '\u2068',
    },
    close: '\u2069',
  );
}
