class WysiwygEditorSessionState {
  const WysiwygEditorSessionState({
    this.activeBlockId,
    this.activeCellId,
    this.anchorBlockId,
    this.anchorOffset = 0,
    this.extentBlockId,
    this.extentOffset = 0,
    this.viewportBlockId,
    this.viewportAlignment = 0,
    this.viewportOffset = 0,
    this.viewportEditingOffset,
    this.viewportLayoutSignature,
    this.sourceSignature,
    this.sourceBindings = const {},
  });

  final String? activeBlockId;
  final String? activeCellId;
  final String? anchorBlockId;
  final int anchorOffset;
  final String? extentBlockId;
  final int extentOffset;
  final String? viewportBlockId;
  final double viewportAlignment;

  /// Logical pixels clipped from the leading edge of [viewportBlockId]. Old
  /// sessions without this field retain their original alignment semantics.
  final double viewportOffset;

  /// The retained editing block's leading edge relative to the viewport. This
  /// lets an unchanged session mount that one editable and scroll naturally,
  /// preserving its input client even when the reading anchor is far away.
  final double? viewportEditingOffset;
  final String? viewportLayoutSignature;

  // Writerside authoring IDs can differ after an exact saved source is reparsed.
  // Bind caret/viewport locations to that representation, never to an ordinal.
  final String? sourceSignature;
  final Map<String, ({int start, int end, String kind, String tag})>
  sourceBindings;

  Map<String, Object?> toJson() => {
    'activeBlockId': activeBlockId,
    'activeCellId': activeCellId,
    'anchorBlockId': anchorBlockId,
    'anchorOffset': anchorOffset,
    'extentBlockId': extentBlockId,
    'extentOffset': extentOffset,
    'viewportBlockId': viewportBlockId,
    'viewportAlignment': viewportAlignment,
    if (viewportOffset != 0) 'viewportOffset': viewportOffset,
    if (viewportEditingOffset != null)
      'viewportEditingOffset': viewportEditingOffset,
    if (viewportLayoutSignature != null)
      'viewportLayoutSignature': viewportLayoutSignature,
    if (sourceSignature != null) 'sourceSignature': sourceSignature,
    if (sourceBindings.isNotEmpty)
      'sourceBindings': {
        for (final entry in sourceBindings.entries)
          entry.key: {
            'start': entry.value.start,
            'end': entry.value.end,
            'kind': entry.value.kind,
            'tag': entry.value.tag,
          },
      },
  };

  factory WysiwygEditorSessionState.fromJson(Map<String, Object?> json) {
    return WysiwygEditorSessionState(
      activeBlockId: json['activeBlockId']?.toString(),
      activeCellId: json['activeCellId']?.toString(),
      anchorBlockId: json['anchorBlockId']?.toString(),
      anchorOffset: (json['anchorOffset'] as num?)?.toInt() ?? 0,
      extentBlockId: json['extentBlockId']?.toString(),
      extentOffset: (json['extentOffset'] as num?)?.toInt() ?? 0,
      viewportBlockId: json['viewportBlockId']?.toString(),
      viewportAlignment: (json['viewportAlignment'] as num?)?.toDouble() ?? 0,
      viewportOffset: (json['viewportOffset'] as num?)?.toDouble() ?? 0,
      viewportEditingOffset: (json['viewportEditingOffset'] as num?)
          ?.toDouble(),
      viewportLayoutSignature: json['viewportLayoutSignature'] as String?,
      sourceSignature: json['sourceSignature'] as String?,
      sourceBindings: {
        if (json['sourceBindings'] case final Map bindings)
          for (final entry in bindings.entries)
            if (entry.key is String)
              if (entry.value case {
                'start': final num start,
                'end': final num end,
                'kind': final String kind,
                'tag': final String tag,
              })
                entry.key as String: (
                  start: start.toInt(),
                  end: end.toInt(),
                  kind: kind,
                  tag: tag,
                ),
      },
    );
  }
}
