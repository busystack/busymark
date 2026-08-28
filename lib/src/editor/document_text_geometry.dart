import 'dart:ui' show BoxHeightStyle, BoxWidthStyle;

/// Text-layout geometry shared by editable and rendered document views.
///
/// Flutter's editable renderer keeps a one-pixel gap beside the caret in
/// addition to [editableCursorWidth]. Rendered text reserves the same trailing
/// extent so Editor and Preview make identical wrapping decisions.
abstract final class BusyMarkDocumentTextGeometry {
  static const double editableCursorWidth = 2.0;
  static const double editableCaretGap = 1.0;
  static const double editableLayoutInset =
      editableCaretGap + editableCursorWidth;

  /// Uses the complete text strut so selection has balanced breathing room
  /// above capitals and below descenders in both Source and Editor views.
  static const BoxHeightStyle selectionHeightStyle = BoxHeightStyle.strut;
  static const BoxWidthStyle selectionWidthStyle = BoxWidthStyle.tight;
  static const double fallbackSelectionAlpha = 0.40;
}
