class WysiwygEditorSessionState {
  const WysiwygEditorSessionState({
    this.activeBlockId,
    this.anchorBlockId,
    this.anchorOffset = 0,
    this.extentBlockId,
    this.extentOffset = 0,
    this.viewportBlockId,
    this.viewportAlignment = 0,
  });

  final String? activeBlockId;
  final String? anchorBlockId;
  final int anchorOffset;
  final String? extentBlockId;
  final int extentOffset;
  final String? viewportBlockId;
  final double viewportAlignment;

  Map<String, Object?> toJson() => {
    'activeBlockId': activeBlockId,
    'anchorBlockId': anchorBlockId,
    'anchorOffset': anchorOffset,
    'extentBlockId': extentBlockId,
    'extentOffset': extentOffset,
    'viewportBlockId': viewportBlockId,
    'viewportAlignment': viewportAlignment,
  };

  factory WysiwygEditorSessionState.fromJson(Map<String, Object?> json) {
    return WysiwygEditorSessionState(
      activeBlockId: json['activeBlockId']?.toString(),
      anchorBlockId: json['anchorBlockId']?.toString(),
      anchorOffset: (json['anchorOffset'] as num?)?.toInt() ?? 0,
      extentBlockId: json['extentBlockId']?.toString(),
      extentOffset: (json['extentOffset'] as num?)?.toInt() ?? 0,
      viewportBlockId: json['viewportBlockId']?.toString(),
      viewportAlignment: (json['viewportAlignment'] as num?)?.toDouble() ?? 0,
    );
  }
}
