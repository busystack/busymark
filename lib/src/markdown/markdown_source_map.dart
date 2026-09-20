import 'dart:math' as math;

import 'package:markdown/markdown.dart' as md;

import 'busymark_document.dart';
import 'markdown_ast_adapter.dart';
import 'markdown_model.dart';
import 'markdown_source_annotation.dart';
import 'math_syntax.dart';

export 'markdown_source_annotation.dart';

void _setSourceMappingAttributes(
  md.Element element, {
  required int start,
  required int end,
  String? opening,
  String? closing,
  int? labelStart,
  int? labelEnd,
  bool isAutolink = false,
  bool isReference = false,
  bool isSourceLineBreak = false,
  int? sourceLineBreakOffset,
}) {
  element.attributes[busyMarkSourceMappingStartAttribute] = '$start';
  element.attributes[busyMarkSourceMappingEndAttribute] = '$end';
  if (opening != null) {
    element.attributes[busyMarkSourceMappingOpeningAttribute] = opening;
  }
  if (closing != null) {
    element.attributes[busyMarkSourceMappingClosingAttribute] = closing;
  }
  if (labelStart != null) {
    element.attributes[busyMarkSourceMappingLabelStartAttribute] =
        '$labelStart';
  }
  if (labelEnd != null) {
    element.attributes[busyMarkSourceMappingLabelEndAttribute] = '$labelEnd';
  }
  if (isAutolink) {
    element.attributes[busyMarkSourceMappingAutolinkAttribute] = 'true';
  }
  if (isReference) {
    element.attributes[busyMarkSourceMappingReferenceAttribute] = 'true';
  }
  if (isSourceLineBreak) {
    element.attributes[busyMarkSourceMappingLineBreakAttribute] = 'true';
  }
  if (sourceLineBreakOffset != null) {
    element.attributes[busyMarkSourceMappingLineBreakOffsetAttribute] =
        '$sourceLineBreakOffset';
  }
}

class _SourceMappingDelimiterPosition {
  _SourceMappingDelimiterPosition(this.start, this.end);

  int start;
  int end;
}

class _SourceMappingDelimiterSyntax extends md.DelimiterSyntax {
  _SourceMappingDelimiterSyntax.asterisk()
    : super(
        r'\*+',
        requiresDelimiterRun: true,
        allowIntraWord: true,
        tags: [md.DelimiterTag('em', 1), md.DelimiterTag('strong', 2)],
        startCharacter: 0x2a,
      );

  _SourceMappingDelimiterSyntax.underscore()
    : super(
        '_+',
        requiresDelimiterRun: true,
        tags: [md.DelimiterTag('em', 1), md.DelimiterTag('strong', 2)],
        startCharacter: 0x5f,
      );

  _SourceMappingDelimiterSyntax.strikethrough()
    : super(
        '~+',
        requiresDelimiterRun: true,
        allowIntraWord: true,
        tags: [md.DelimiterTag('del', 1), md.DelimiterTag('del', 2)],
        startCharacter: 0x7e,
      );

  final Expando<_SourceMappingDelimiterPosition> _positions = Expando();

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final runLength = match.group(0)!.length;
    final matchStart = parser.pos;
    final matchEnd = parser.pos + runLength;
    final text = md.Text(parser.source.substring(matchStart, matchEnd));
    final delimiter = md.DelimiterRun.tryParse(
      parser,
      matchStart,
      matchEnd,
      syntax: this,
      node: text,
      allowIntraWord: allowIntraWord,
      tags: List.of(tags ?? const []),
    );
    if (delimiter == null) {
      parser.advanceBy(runLength);
      return false;
    }
    _positions[delimiter] = _SourceMappingDelimiterPosition(
      matchStart,
      matchEnd,
    );
    parser.pushDelimiter(delimiter);
    parser.addNode(text);
    return true;
  }

  @override
  Iterable<md.Node>? close(
    md.InlineParser parser,
    md.Delimiter opener,
    md.Delimiter closer, {
    required String tag,
    required List<md.Node> Function() getChildren,
  }) {
    final indicatorLength = opener is md.DelimiterRun
        ? opener.tags
              .lastWhere(
                (candidate) =>
                    candidate.tag == tag &&
                    opener.length >= candidate.indicatorLength &&
                    closer.length >= candidate.indicatorLength,
              )
              .indicatorLength
        : 1;
    final openerPosition = _positions[opener];
    final closerPosition = _positions[closer];
    final element = md.Element(tag, getChildren());
    if (openerPosition != null && closerPosition != null) {
      // CommonMark consumes opening delimiters from the right edge of their
      // run, and closing delimiters from the left edge. Any unused characters
      // on the other side remain literal source outside this element.
      final openingStart = openerPosition.end - indicatorLength;
      final closingEnd = closerPosition.start + indicatorLength;
      final opening = parser.source.substring(openingStart, openerPosition.end);
      final closing = parser.source.substring(closerPosition.start, closingEnd);
      _setSourceMappingAttributes(
        element,
        start: openingStart,
        end: closingEnd,
        opening: opening,
        closing: closing,
      );
      openerPosition.end = openingStart;
      closerPosition.start += indicatorLength;
    }
    return [element];
  }
}

class _SourceMappingLinkSyntax extends md.LinkSyntax {
  @override
  Iterable<md.Node>? close(
    md.InlineParser parser,
    covariant md.SimpleDelimiter opener,
    md.Delimiter? closer, {
    String? tag,
    required List<md.Node> Function() getChildren,
  }) {
    final labelEnd = parser.pos;
    final result = super.close(
      parser,
      opener,
      closer,
      tag: tag,
      getChildren: getChildren,
    );
    if (result == null) return null;
    final nodes = result.toList(growable: false);
    final isReference =
        labelEnd + 1 >= parser.source.length ||
        parser.source.codeUnitAt(labelEnd + 1) != 0x28;
    for (final node in nodes.whereType<md.Element>()) {
      if (node.tag != 'a') continue;
      _setSourceMappingAttributes(
        node,
        start: opener.endPos - 1,
        end: parser.pos + 1,
        labelStart: opener.endPos,
        labelEnd: labelEnd,
        isReference: isReference,
      );
    }
    return nodes;
  }
}

class _SourceMappingAutolinkSyntax extends md.InlineSyntax {
  _SourceMappingAutolinkSyntax()
    : super(r'<(([a-zA-Z][a-zA-Z\-\+\.]+):(?://)?[^\s>]*)>');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final start = parser.pos;
    final parsed = md.Document(
      encodeHtml: parser.encodeHtml,
    ).parseInline(match[0]!);
    if (parsed.singleOrNull case md.Element anchor) {
      _setSourceMappingAttributes(
        anchor,
        start: start,
        end: start + match[0]!.length,
        labelStart: start + 1,
        labelEnd: start + match[0]!.length - 1,
        isAutolink: true,
      );
      parser.addNode(anchor);
      return true;
    }
    return false;
  }
}

class _SourceMappingEmailAutolinkSyntax extends md.InlineSyntax {
  _SourceMappingEmailAutolinkSyntax() : super(r'<([^\s<>@]+@[^\s<>@]+)>');

  Map<String, BusyInline> _approvedOriginals = const {};

  void approveOriginals(Map<String, BusyInline> originals) {
    _approvedOriginals = Map.unmodifiable(originals);
  }

  String _rangeKey(int start, int end) => '$start:$end';

  @override
  bool tryMatch(md.InlineParser parser, [int? startMatchPos]) {
    startMatchPos ??= parser.pos;
    final match = pattern.matchAsPrefix(parser.source, startMatchPos);
    if (match == null) return false;
    final start = parser.pos;
    final parsed = md.Document(
      encodeHtml: parser.encodeHtml,
    ).parseInline(match[0]!);
    final parsedAnchor = parsed.singleOrNull;
    final approved =
        _approvedOriginals[_rangeKey(start, start + match[0]!.length)];
    md.Element? anchor;
    if (parsedAnchor is md.Element && parsedAnchor.tag == 'a') {
      anchor = parsedAnchor;
    } else if (approved != null) {
      anchor = md.Element.text('a', match[1]!);
      anchor.attributes.addAll(approved.attributes);
    }
    if (approved != null && anchor != null) {
      anchor.attributes['href'] =
          approved.destination ?? approved.attributes['href'] ?? '';
    }
    if (anchor == null || anchor.tag != 'a') return false;
    parser.writeText();
    _setSourceMappingAttributes(
      anchor,
      start: start,
      end: start + match[0]!.length,
      labelStart: start + 1,
      labelEnd: start + match[0]!.length - 1,
      isAutolink: true,
    );
    parser.addNode(anchor);
    parser.consume(match[0]!.length);
    return true;
  }

  @override
  bool onMatch(md.InlineParser parser, Match match) =>
      throw UnsupportedError('tryMatch performs authoritative email mapping');
}

class _SourceMappingHardLineBreakSyntax extends md.LineBreakSyntax {
  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final element = md.Element.empty('br');
    _setSourceMappingAttributes(
      element,
      start: parser.pos,
      end: match.end,
      isSourceLineBreak: true,
    );
    parser.addNode(element);
    return true;
  }
}

List<md.InlineSyntax> _sourceMappingInlineSyntaxes(
  _SourceMappingEmailAutolinkSyntax emailSyntax,
) {
  return [
    emailSyntax,
    _SourceMappingAutolinkSyntax(),
    _SourceMappingLinkSyntax(),
    _SourceMappingDelimiterSyntax.asterisk(),
    _SourceMappingDelimiterSyntax.underscore(),
    _SourceMappingDelimiterSyntax.strikethrough(),
    _SourceMappingHardLineBreakSyntax(),
  ];
}

class BusyMarkInlineParserContext {
  BusyMarkInlineParserContext._({
    required md.Document document,
    required md.Document mappingDocument,
    required Map<String, md.LinkReference> referenceDefinitions,
    required _SourceMappingEmailAutolinkSyntax emailSyntax,
  }) : _document = document,
       _mappingDocument = mappingDocument,
       _referenceDefinitions = referenceDefinitions,
       _emailSyntax = emailSyntax;

  final md.Document _document;
  final md.Document _mappingDocument;
  final Map<String, md.LinkReference> _referenceDefinitions;
  final _SourceMappingEmailAutolinkSyntax _emailSyntax;

  int parseInvocations = 0;

  void _addReferenceLabelMarkerVariants(
    md.Document document,
    String source,
    Iterable<String> markers,
  ) {
    final markerList = markers.where((marker) => marker.isNotEmpty).toList();
    if (markerList.isEmpty || _referenceDefinitions.isEmpty) return;
    final original = StringBuffer();
    final insertions = <({int offset, String marker})>[];
    var sourceOffset = 0;
    while (sourceOffset < source.length) {
      String? matchedMarker;
      for (final marker in markerList) {
        if (source.startsWith(marker, sourceOffset)) {
          matchedMarker = marker;
          break;
        }
      }
      if (matchedMarker != null) {
        insertions.add((offset: original.length, marker: matchedMarker));
        sourceOffset += matchedMarker.length;
      } else {
        original.writeCharCode(source.codeUnitAt(sourceOffset));
        sourceOffset += 1;
      }
    }
    if (insertions.isEmpty) return;

    final originalSource = original.toString();
    final ranges = Map<BusyInline, BusyMarkMappedInlineRange>.identity();
    parseInvocations += 1;
    final inlines = const MarkdownAstAdapter().convertInlineNodes(
      _mappingDocument.parseInline(originalSource),
      sourceMappings: ranges,
      mappingSource: originalSource,
    );

    void addVariants(List<BusyInline> siblings) {
      for (final inline in siblings) {
        final range = ranges[inline];
        final labelStart = range?.labelStart;
        final labelEnd = range?.labelEnd;
        if (inline.kind == BusyInlineKind.link &&
            labelStart != null &&
            labelEnd != null) {
          final originalLabel = originalSource.substring(labelStart, labelEnd);
          final normalizedLabel = busyMarkParserReferenceLabel(originalLabel);
          final reference = normalizedLabel == null
              ? null
              : _referenceDefinitions[normalizedLabel];
          final labelInsertions = insertions
              .where(
                (insertion) =>
                    insertion.offset >= labelStart &&
                    insertion.offset <= labelEnd,
              )
              .toList(growable: false);
          if (reference != null && labelInsertions.isNotEmpty) {
            final markedLabel = StringBuffer();
            var offset = labelStart;
            for (final insertion in labelInsertions) {
              markedLabel.write(
                originalSource.substring(offset, insertion.offset),
              );
              markedLabel.write(insertion.marker);
              offset = insertion.offset;
            }
            markedLabel.write(originalSource.substring(offset, labelEnd));
            final label = markedLabel.toString();
            final normalizedMarkedLabel = busyMarkParserReferenceLabel(label);
            if (normalizedMarkedLabel != null) {
              document.linkReferences[normalizedMarkedLabel] = md.LinkReference(
                label,
                reference.destination,
                reference.title,
              );
            }
          }
        }
        addVariants(inline.children);
      }
    }

    addVariants(inlines);
  }

  List<BusyInline> parse(
    String source, {
    Iterable<String> ignoredReferenceLabelMarkers = const [],
  }) {
    _addReferenceLabelMarkerVariants(
      _document,
      source,
      ignoredReferenceLabelMarkers,
    );
    parseInvocations += 1;
    return const MarkdownAstAdapter().convertInlineNodes(
      _document.parseInline(source),
    );
  }

  BusyMarkMappedInlineParse parseMapped(
    String source, {
    Iterable<String> ignoredReferenceLabelMarkers = const [],
  }) {
    final markers = ignoredReferenceLabelMarkers
        .where((marker) => marker.isNotEmpty)
        .toList(growable: false);
    BusyMarkMappedInlineParse? original;
    final originalSemantics = Map<BusyInline, BusyInline>.identity();
    List<({int start, int end})> markerSpans = const [];
    if (markers.isNotEmpty) {
      final buffer = StringBuffer();
      final spans = <({int start, int end})>[];
      var offset = 0;
      while (offset < source.length) {
        final marker = markers.firstWhere(
          (candidate) => source.startsWith(candidate, offset),
          orElse: () => '',
        );
        if (marker.isEmpty) {
          buffer.writeCharCode(source.codeUnitAt(offset));
          offset += 1;
        } else {
          spans.add((start: offset, end: offset + marker.length));
          offset += marker.length;
        }
      }
      markerSpans = spans;
      _emailSyntax.approveOriginals(const {});
      parseInvocations += 1;
      final originalRanges =
          Map<BusyInline, BusyMarkMappedInlineRange>.identity();
      final originalInlines = const MarkdownAstAdapter().convertInlineNodes(
        _mappingDocument.parseInline(buffer.toString()),
        sourceMappings: originalRanges,
        mappingSource: buffer.toString(),
      );
      parseInvocations += 1;
      final semanticInlines = const MarkdownAstAdapter().convertInlineNodes(
        _document.parseInline(buffer.toString()),
      );

      bool sameStructuralIdentity(BusyInline positioned, BusyInline semantic) {
        if (positioned.kind != semantic.kind ||
            positioned.plainText != semantic.plainText ||
            positioned.destination != semantic.destination ||
            positioned.attributes.length != semantic.attributes.length) {
          return false;
        }
        for (final entry in positioned.attributes.entries) {
          if (semantic.attributes[entry.key] != entry.value) return false;
        }
        return true;
      }

      String structuralKey(BusyInline inline) {
        final attributes = inline.attributes.entries.toList()
          ..sort((left, right) => left.key.compareTo(right.key));
        final buffer = StringBuffer('${inline.kind.index};')
          ..write('${inline.plainText.length}:${inline.plainText};')
          ..write(
            inline.destination == null
                ? '-;'
                : '${inline.destination!.length}:${inline.destination};',
          );
        for (final attribute in attributes) {
          buffer
            ..write('${attribute.key.length}:${attribute.key}=')
            ..write('${attribute.value.length}:${attribute.value};');
        }
        return buffer.toString();
      }

      void associateOriginals(
        List<BusyInline> positioned,
        List<BusyInline> semantic,
      ) {
        final semanticByIdentity = <String, List<BusyInline>>{};
        for (final semanticInline in semantic) {
          semanticByIdentity
              .putIfAbsent(structuralKey(semanticInline), () => [])
              .add(semanticInline);
        }
        final consumedByIdentity = <String, int>{};
        for (final positionedInline in positioned) {
          final identity = structuralKey(positionedInline);
          final candidates = semanticByIdentity[identity];
          final candidateIndex = consumedByIdentity[identity] ?? 0;
          if (candidates == null || candidateIndex >= candidates.length) {
            continue;
          }
          final semanticInline = candidates[candidateIndex];
          consumedByIdentity[identity] = candidateIndex + 1;
          if (!sameStructuralIdentity(positionedInline, semanticInline)) {
            continue;
          }
          if (originalRanges.containsKey(positionedInline)) {
            originalSemantics[positionedInline] = semanticInline;
          }
          associateOriginals(
            positionedInline.children,
            semanticInline.children,
          );
        }
      }

      associateOriginals(originalInlines, semanticInlines);
      original = BusyMarkMappedInlineParse(
        inlines: originalInlines,
        ranges: originalRanges,
      );

      int markedOffsetForOriginal(int originalOffset, {required bool end}) {
        var inserted = 0;
        for (final span in markerSpans) {
          final insertionOffset = span.start - inserted;
          if (insertionOffset > originalOffset ||
              (!end && insertionOffset == originalOffset)) {
            break;
          }
          inserted += span.end - span.start;
        }
        return originalOffset + inserted;
      }

      final approvedEmails = <String, BusyInline>{};
      for (final entry in originalRanges.entries) {
        final semantic = originalSemantics[entry.key];
        final range = entry.value;
        if (semantic == null ||
            !range.isAutolink ||
            !(semantic.destination?.startsWith('mailto:') ?? false)) {
          continue;
        }
        final start = markedOffsetForOriginal(range.start, end: false);
        final end = markedOffsetForOriginal(range.end, end: true);
        approvedEmails['$start:$end'] = semantic;
      }
      _emailSyntax.approveOriginals(approvedEmails);
    } else {
      _emailSyntax.approveOriginals(const {});
    }
    _addReferenceLabelMarkerVariants(_mappingDocument, source, markers);
    parseInvocations += 1;
    final ranges = Map<BusyInline, BusyMarkMappedInlineRange>.identity();
    final inlines = const MarkdownAstAdapter().convertInlineNodes(
      _mappingDocument.parseInline(source),
      sourceMappings: ranges,
      mappingSource: source,
      ignoredPositionMarkers: markers,
    );
    if (original == null) {
      return BusyMarkMappedInlineParse(inlines: inlines, ranges: ranges);
    }

    int originalOffsetFor(int markedOffset) {
      var removed = 0;
      for (final span in markerSpans) {
        if (markedOffset <= span.start) break;
        removed += math.min(markedOffset, span.end) - span.start;
      }
      return markedOffset - removed;
    }

    String key(BusyInline inline, BusyMarkMappedInlineRange range) =>
        '${inline.kind.index}:${range.start}:${range.end}';
    final originalsByRange = <String, BusyInline>{};
    for (final entry in original.ranges.entries) {
      final semantic = originalSemantics[entry.key];
      if (semantic != null) {
        originalsByRange[key(entry.key, entry.value)] = semantic;
      }
    }
    final reconciledRanges =
        Map<BusyInline, BusyMarkMappedInlineRange>.identity();

    BusyInline reconcile(BusyInline mapped) {
      final mappedRange = ranges[mapped];
      BusyInline? semantic;
      if (mappedRange != null) {
        final originalRange = BusyMarkMappedInlineRange(
          start: originalOffsetFor(mappedRange.start),
          end: originalOffsetFor(mappedRange.end),
        );
        semantic = originalsByRange[key(mapped, originalRange)];
      }
      final children = [for (final child in mapped.children) reconcile(child)];
      final result = mapped.copyWith(
        destination: semantic?.destination,
        attributes: semantic?.attributes,
        children: mapped.children.isEmpty ? mapped.children : children,
      );
      if (mappedRange != null) {
        reconciledRanges[result] = BusyMarkMappedInlineRange(
          start: mappedRange.start,
          end: mappedRange.end,
          opening: mappedRange.opening,
          closing: mappedRange.closing,
          labelStart: mappedRange.labelStart,
          labelEnd: mappedRange.labelEnd,
          lineBreaks: mappedRange.lineBreaks,
          originalInline: semantic,
          isAutolink: mappedRange.isAutolink,
          isReference: mappedRange.isReference,
          isSourceLineBreak: mappedRange.isSourceLineBreak,
          sourceLineBreakOffset: mappedRange.sourceLineBreakOffset,
        );
      }
      return result;
    }

    final reconciled = [for (final inline in inlines) reconcile(inline)];
    final complete = markers.every(
      (marker) => reconciled.any((inline) => inline.plainText.contains(marker)),
    );
    if (!complete ||
        !_sameSemanticsIgnoringMarkers(reconciled, original.inlines, markers)) {
      final originalRangesWithSemantics =
          Map<BusyInline, BusyMarkMappedInlineRange>.identity();
      for (final entry in original.ranges.entries) {
        final range = entry.value;
        originalRangesWithSemantics[entry.key] = BusyMarkMappedInlineRange(
          start: range.start,
          end: range.end,
          opening: range.opening,
          closing: range.closing,
          labelStart: range.labelStart,
          labelEnd: range.labelEnd,
          lineBreaks: range.lineBreaks,
          originalInline: originalSemantics[entry.key],
          isAutolink: range.isAutolink,
          isReference: range.isReference,
          isSourceLineBreak: range.isSourceLineBreak,
          sourceLineBreakOffset: range.sourceLineBreakOffset,
        );
      }
      return BusyMarkMappedInlineParse(
        inlines: original.inlines,
        ranges: originalRangesWithSemantics,
        positionRecordsComplete: false,
      );
    }
    return BusyMarkMappedInlineParse(
      inlines: reconciled,
      ranges: reconciledRanges,
    );
  }

  /// Runs the block grammar first, then maps its logical inline content back
  /// to [source]. Container markers therefore remain source structure rather
  /// than becoming semantic inline text.
  BusyMarkMappedInlineParse? parseMappedBlock(
    String source, {
    required int sourceStart,
    required int sourceEnd,
    Iterable<String> ignoredReferenceLabelMarkers = const [],
  }) {
    final markers = ignoredReferenceLabelMarkers
        .where((marker) => marker.isNotEmpty)
        .toList(growable: false);
    if (markers.isEmpty) return null;
    final sourceLines = _mappedSourceLines(source);
    if (sourceLines.isEmpty) return null;
    final nodes = md.BlockParser([
      for (final line in sourceLines) md.Line(line.content),
    ], _mappingDocument).parseLines();
    final candidates = <md.UnparsedContent>[];

    void findUnparsed(Iterable<md.Node> values) {
      for (final node in values) {
        if (node is md.UnparsedContent) {
          if (markers.every(node.textContent.contains)) candidates.add(node);
        } else if (node is md.Element && node.children != null) {
          findUnparsed(node.children!);
        }
      }
    }

    findUnparsed(nodes);
    for (final candidate in candidates) {
      final projection = _MappedBlockInlineProjection.tryCreate(
        source,
        sourceLines,
        candidate.textContent,
        markers.first,
      );
      if (projection == null ||
          !markers.every((marker) {
            final offset = candidate.textContent.indexOf(marker);
            if (offset < 0) return false;
            final rawOffset = projection.rawStartFor(offset);
            return rawOffset >= sourceStart && rawOffset <= sourceEnd;
          })) {
        continue;
      }
      final mapped = parseMapped(
        candidate.textContent,
        ignoredReferenceLabelMarkers: markers,
      );
      final ranges = Map<BusyInline, BusyMarkMappedInlineRange>.identity();
      for (final entry in mapped.ranges.entries) {
        final range = entry.value;
        final lineBreaks = <BusyMarkMappedSourceLineBreak>[];

        void collectLineBreaks(BusyInline inline, int textOffset) {
          final inlineRange = mapped.ranges[inline];
          if (inlineRange?.isSourceLineBreak ?? false) {
            final projected = projection.lineBreakAt(
              inlineRange!.sourceLineBreakOffset ?? inlineRange.end - 1,
            );
            if (projected != null) {
              lineBreaks.add(
                BusyMarkMappedSourceLineBreak(
                  textOffset: textOffset,
                  lineEnding: projected.lineEnding,
                  continuationPrefix: projected.continuationPrefix,
                  sourceOffset: projected.sourceOffset,
                ),
              );
            }
            return;
          }
          var childOffset = textOffset;
          for (final child in inline.children) {
            collectLineBreaks(child, childOffset);
            childOffset += child.plainText.length;
          }
        }

        collectLineBreaks(entry.key, 0);
        ranges[entry.key] = BusyMarkMappedInlineRange(
          start: projection.rawStartFor(range.start),
          end: projection.rawEndFor(range.end),
          opening: range.opening,
          closing: range.closing,
          labelStart: range.labelStart == null
              ? null
              : projection.rawStartFor(range.labelStart!),
          labelEnd: range.labelEnd == null
              ? null
              : projection.rawStartFor(range.labelEnd!),
          lineBreaks: lineBreaks,
          originalInline: range.originalInline,
          isAutolink: range.isAutolink,
          isReference: range.isReference,
          isSourceLineBreak: range.isSourceLineBreak,
          sourceLineBreakOffset: range.sourceLineBreakOffset == null
              ? null
              : projection.rawStartFor(range.sourceLineBreakOffset!),
        );
      }
      return BusyMarkMappedInlineParse(
        inlines: mapped.inlines,
        ranges: ranges,
        positionRecordsComplete: mapped.positionRecordsComplete,
      );
    }
    return null;
  }
}

bool _sameSemanticsIgnoringMarkers(
  List<BusyInline> left,
  List<BusyInline> right,
  List<String> markers,
) {
  String clean(String value) {
    var result = value;
    for (final marker in markers) {
      result = result.replaceAll(marker, '');
    }
    return result;
  }

  String encodeValue(String? value) =>
      value == null ? '-' : '${value.length}:$value';

  late String Function(List<BusyInline>) encodeSiblings;

  String encodeInline(BusyInline inline) {
    final attributes = inline.attributes.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    final children = encodeSiblings(inline.children);
    final text = inline.children.isEmpty ? clean(inline.text) : '';
    return '${inline.kind.index};${encodeValue(text)};'
        '${encodeValue(inline.destination)};'
        '${attributes.map((entry) => '${encodeValue(entry.key)}=${encodeValue(entry.value)}').join()};'
        '{$children}';
  }

  encodeSiblings = (List<BusyInline> inlines) {
    final result = StringBuffer();
    String? pendingText;
    Map<String, String>? pendingAttributes;

    void flushText() {
      if (pendingText == null) return;
      result.write(
        encodeInline(
          BusyInline(
            kind: BusyInlineKind.text,
            text: pendingText!,
            attributes: pendingAttributes!,
          ),
        ),
      );
      pendingText = null;
      pendingAttributes = null;
    }

    for (final inline in inlines) {
      if (inline.kind == BusyInlineKind.text && inline.children.isEmpty) {
        final text = clean(inline.text);
        if (text.isEmpty) continue;
        if (pendingText != null &&
            _sameStringMap(pendingAttributes!, inline.attributes)) {
          pendingText = '$pendingText$text';
        } else {
          flushText();
          pendingText = text;
          pendingAttributes = inline.attributes;
        }
      } else {
        flushText();
        result.write(encodeInline(inline));
      }
    }
    flushText();
    return result.toString();
  };

  return encodeSiblings(left) == encodeSiblings(right);
}

bool _sameStringMap(Map<String, String> left, Map<String, String> right) {
  if (left.length != right.length) return false;
  return left.entries.every((entry) => right[entry.key] == entry.value);
}

class _MappedSourceLine {
  const _MappedSourceLine({
    required this.content,
    required this.contentStart,
    required this.contentEnd,
    required this.end,
  });

  final String content;
  final int contentStart;
  final int contentEnd;
  final int end;
}

List<_MappedSourceLine> _mappedSourceLines(String source) {
  final lines = <_MappedSourceLine>[];
  var start = 0;
  while (start < source.length) {
    var contentEnd = start;
    while (contentEnd < source.length &&
        source.codeUnitAt(contentEnd) != 0x0a &&
        source.codeUnitAt(contentEnd) != 0x0d) {
      contentEnd += 1;
    }
    var end = contentEnd;
    if (end < source.length) {
      if (source.codeUnitAt(end) == 0x0d &&
          end + 1 < source.length &&
          source.codeUnitAt(end + 1) == 0x0a) {
        end += 2;
      } else {
        end += 1;
      }
    }
    lines.add(
      _MappedSourceLine(
        content: source.substring(start, contentEnd),
        contentStart: start,
        contentEnd: contentEnd,
        end: end,
      ),
    );
    start = end;
  }
  return lines;
}

class _MappedBlockInlineProjection {
  _MappedBlockInlineProjection({
    required this.source,
    required this.rawOffsets,
    required this.logicalLineStarts,
    required this.sourceLines,
    required this.firstSourceLine,
  });

  static _MappedBlockInlineProjection? tryCreate(
    String source,
    List<_MappedSourceLine> sourceLines,
    String logicalSource,
    String anchor,
  ) {
    if (logicalSource.isEmpty) return null;
    final logicalLines = logicalSource.split('\n');
    final logicalAnchor = logicalSource.indexOf(anchor);
    final rawAnchor = source.indexOf(anchor);
    if (logicalAnchor < 0 || rawAnchor < 0) return null;
    final logicalAnchorLine = '\n'
        .allMatches(logicalSource.substring(0, logicalAnchor))
        .length;
    final rawAnchorLine = sourceLines.indexWhere(
      (line) => rawAnchor >= line.contentStart && rawAnchor < line.end,
    );
    final firstSourceLine = rawAnchorLine - logicalAnchorLine;
    if (rawAnchorLine < 0 ||
        firstSourceLine < 0 ||
        firstSourceLine + logicalLines.length > sourceLines.length) {
      return null;
    }

    final positions = <int>[];
    for (var index = 0; index < logicalLines.length; index++) {
      final logicalLine = logicalLines[index];
      final sourceLine = sourceLines[firstSourceLine + index];
      final position = sourceLine.content.indexOf(logicalLine);
      if (position < 0) return null;
      positions.add(sourceLine.contentStart + position);
    }

    final rawOffsets = <int>[];
    final logicalLineStarts = <int>[];
    for (var index = 0; index < logicalLines.length; index++) {
      logicalLineStarts.add(rawOffsets.length);
      final lineStart = positions[index];
      for (
        var character = 0;
        character < logicalLines[index].length;
        character++
      ) {
        rawOffsets.add(lineStart + character);
      }
      if (index + 1 < logicalLines.length) {
        final sourceLine = sourceLines[firstSourceLine + index];
        if (sourceLine.end == sourceLine.contentEnd) return null;
        rawOffsets.add(sourceLine.end - 1);
      }
    }
    if (rawOffsets.length != logicalSource.length) return null;
    return _MappedBlockInlineProjection(
      source: source,
      rawOffsets: rawOffsets,
      logicalLineStarts: logicalLineStarts,
      sourceLines: sourceLines,
      firstSourceLine: firstSourceLine,
    );
  }

  final String source;
  final List<int> rawOffsets;
  final List<int> logicalLineStarts;
  final List<_MappedSourceLine> sourceLines;
  final int firstSourceLine;
  late final Map<int, BusyMarkMappedSourceLineBreak>
  _lineBreaksByLogicalOffset = _createLineBreaksByLogicalOffset();

  int rawStartFor(int offset) {
    if (offset < rawOffsets.length) return rawOffsets[offset];
    return rawOffsets.last + 1;
  }

  int rawEndFor(int offset) {
    if (offset <= 0) return rawOffsets.first;
    return rawOffsets[offset - 1] + 1;
  }

  BusyMarkMappedSourceLineBreak? lineBreakAt(int logicalOffset) {
    return _lineBreaksByLogicalOffset[logicalOffset];
  }

  Map<int, BusyMarkMappedSourceLineBreak> _createLineBreaksByLogicalOffset() {
    final result = <int, BusyMarkMappedSourceLineBreak>{};
    for (var line = 0; line + 1 < logicalLineStarts.length; line++) {
      final newlineOffset = logicalLineStarts[line + 1] - 1;
      final sourceLine = sourceLines[firstSourceLine + line];
      final nextLogicalOffset = newlineOffset + 1;
      final nextRawOffset = rawOffsets[nextLogicalOffset];
      result[newlineOffset] = BusyMarkMappedSourceLineBreak(
        textOffset: newlineOffset,
        lineEnding: source.substring(sourceLine.contentEnd, sourceLine.end),
        continuationPrefix: source.substring(sourceLine.end, nextRawOffset),
        sourceOffset: sourceLine.contentEnd,
      );
    }
    return Map.unmodifiable(result);
  }
}

class MarkdownSourceMapper {
  const MarkdownSourceMapper();

  BusyMarkInlineParserContext createInlineParserContext({
    required String documentSource,
    required MarkdownMode mode,
  }) {
    final referenceDocument = busyMarkMarkdownDocument(mode)
      ..parse(documentSource);
    final document = busyMarkMarkdownDocument(mode)
      ..linkReferences.addAll(referenceDocument.linkReferences);
    final emailSyntax = _SourceMappingEmailAutolinkSyntax();
    final mappingDocument = busyMarkMarkdownDocument(
      mode,
      leadingInlineSyntaxes: _sourceMappingInlineSyntaxes(emailSyntax),
    )..linkReferences.addAll(referenceDocument.linkReferences);
    return BusyMarkInlineParserContext._(
      document: document,
      mappingDocument: mappingDocument,
      referenceDefinitions: Map.unmodifiable(referenceDocument.linkReferences),
      emailSyntax: emailSyntax,
    );
  }
}
