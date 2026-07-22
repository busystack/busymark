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
