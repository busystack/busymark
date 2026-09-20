import 'busymark_document.dart';

const busyMarkSourceMappingStartAttribute = 'data-busymark-source-start';
const busyMarkSourceMappingEndAttribute = 'data-busymark-source-end';
const busyMarkSourceMappingOpeningAttribute = 'data-busymark-source-opening';
const busyMarkSourceMappingClosingAttribute = 'data-busymark-source-closing';
const busyMarkSourceMappingLabelStartAttribute =
    'data-busymark-source-label-start';
const busyMarkSourceMappingLabelEndAttribute = 'data-busymark-source-label-end';
const busyMarkSourceMappingAutolinkAttribute = 'data-busymark-source-autolink';
const busyMarkSourceMappingReferenceAttribute =
    'data-busymark-source-reference';
const busyMarkSourceMappingLineBreakAttribute =
    'data-busymark-source-line-break';
const busyMarkSourceMappingLineBreakOffsetAttribute =
    'data-busymark-source-line-break-offset';

class BusyMarkMappedInlineRange {
  const BusyMarkMappedInlineRange({
    required this.start,
    required this.end,
    this.opening,
    this.closing,
    this.labelStart,
    this.labelEnd,
    this.lineBreaks = const [],
    this.originalInline,
    this.isAutolink = false,
    this.isReference = false,
    this.isSourceLineBreak = false,
    this.sourceLineBreakOffset,
  });

  final int start;
  final int end;
  final String? opening;
  final String? closing;
  final int? labelStart;
  final int? labelEnd;
  final List<BusyMarkMappedSourceLineBreak> lineBreaks;
  final BusyInline? originalInline;
  final bool isAutolink;
  final bool isReference;
  final bool isSourceLineBreak;
  final int? sourceLineBreakOffset;
}

class BusyMarkMappedSourceLineBreak {
  const BusyMarkMappedSourceLineBreak({
    required this.textOffset,
    required this.lineEnding,
    required this.continuationPrefix,
    this.sourceOffset,
  });

  final int textOffset;
  final String lineEnding;
  final String continuationPrefix;
  final int? sourceOffset;
}

class BusyMarkMappedInlineParse {
  BusyMarkMappedInlineParse({
    required this.inlines,
    required Map<BusyInline, BusyMarkMappedInlineRange> ranges,
    this.positionRecordsComplete = true,
  }) : ranges = Map.unmodifiable(ranges);

  final List<BusyInline> inlines;
  final Map<BusyInline, BusyMarkMappedInlineRange> ranges;
  final bool positionRecordsComplete;
}
