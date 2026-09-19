import 'dart:math' as math;

import 'package:markdown/markdown.dart' as md;
import 'package:xml/xml.dart';

import '../core/path_utils.dart';
import 'busymark_document.dart';
import 'markdown_fence.dart';
import 'markdown_front_matter.dart';
import 'markdown_model.dart';
import 'math_syntax.dart';
import 'raw_html_adapter.dart';
import 'raw_html_policy.dart';
import 'writerside_variable_syntax.dart';
import '../writerside/writerside_schema.dart';

const _rawHtmlAdapter = RawHtmlAdapter();

const _sourceMappingStartAttribute = 'data-busymark-source-start';
const _sourceMappingEndAttribute = 'data-busymark-source-end';
const _sourceMappingOpeningAttribute = 'data-busymark-source-opening';
const _sourceMappingClosingAttribute = 'data-busymark-source-closing';
const _sourceMappingLabelStartAttribute = 'data-busymark-source-label-start';
const _sourceMappingLabelEndAttribute = 'data-busymark-source-label-end';
const _sourceMappingAutolinkAttribute = 'data-busymark-source-autolink';
const _sourceMappingReferenceAttribute = 'data-busymark-source-reference';
const _sourceMappingLineBreakAttribute = 'data-busymark-source-line-break';

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
  }) : ranges = Map.unmodifiable(ranges);

  final List<BusyInline> inlines;
  final Map<BusyInline, BusyMarkMappedInlineRange> ranges;
}

String _decodeMarkdownAttribute(String value) => value
    .replaceAll('&#92;', '\\')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&amp;', '&');

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
}) {
  element.attributes[_sourceMappingStartAttribute] = '$start';
  element.attributes[_sourceMappingEndAttribute] = '$end';
  if (opening != null) {
    element.attributes[_sourceMappingOpeningAttribute] = opening;
  }
  if (closing != null) {
    element.attributes[_sourceMappingClosingAttribute] = closing;
  }
  if (labelStart != null) {
    element.attributes[_sourceMappingLabelStartAttribute] = '$labelStart';
  }
  if (labelEnd != null) {
    element.attributes[_sourceMappingLabelEndAttribute] = '$labelEnd';
  }
  if (isAutolink) {
    element.attributes[_sourceMappingAutolinkAttribute] = 'true';
  }
  if (isReference) {
    element.attributes[_sourceMappingReferenceAttribute] = 'true';
  }
  if (isSourceLineBreak) {
    element.attributes[_sourceMappingLineBreakAttribute] = 'true';
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

class _SourceMappingLineBreakSyntax extends md.InlineSyntax {
  _SourceMappingLineBreakSyntax() : super('\n', startCharacter: 0x0a);

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final element = md.Element('busymark-source-line-break', [md.Text('\n')]);
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
) => [
  emailSyntax,
  _SourceMappingAutolinkSyntax(),
  _SourceMappingLinkSyntax(),
  _SourceMappingDelimiterSyntax.asterisk(),
  _SourceMappingDelimiterSyntax.underscore(),
  _SourceMappingDelimiterSyntax.strikethrough(),
  _SourceMappingHardLineBreakSyntax(),
  _SourceMappingLineBreakSyntax(),
];

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
    final inlines = const MarkdownAstAdapter()._inlinesFromNodes(
      _mappingDocument.parseInline(originalSource),
      sourceMappings: ranges,
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
    return const MarkdownAstAdapter()._inlinesFromNodes(
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
      final originalInlines = const MarkdownAstAdapter()._inlinesFromNodes(
        _mappingDocument.parseInline(buffer.toString()),
        sourceMappings: originalRanges,
      );
      parseInvocations += 1;
      final semanticInlines = const MarkdownAstAdapter()._inlinesFromNodes(
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
    final inlines = const MarkdownAstAdapter()._inlinesFromNodes(
      _mappingDocument.parseInline(source),
      sourceMappings: ranges,
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
        );
      }
      return result;
    }

    return BusyMarkMappedInlineParse(
      inlines: [for (final inline in inlines) reconcile(inline)],
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
            final projected = projection.lineBreakAt(inlineRange!.end - 1);
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
        );
      }
      return BusyMarkMappedInlineParse(inlines: mapped.inlines, ranges: ranges);
    }
    return null;
  }
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

class MarkdownAstAdapter {
  const MarkdownAstAdapter();

  /// Parses Markdown in an inline-only context, such as a table cell.
  ///
  /// Block markers at the beginning of [source] remain literal because the
  /// block grammar is deliberately never invoked.
  List<BusyInline> parseInlineFragment({
    required String source,
    required MarkdownMode mode,
  }) {
    if (source.isEmpty) {
      return const [];
    }
    final document = busyMarkMarkdownDocument(mode);
    return _inlinesFromNodes(document.parseInline(source));
  }

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

  BusyDocument parse({
    required String filePath,
    required String source,
    required MarkdownMode mode,
    String? title,
    bool preserveHtmlSemantics = false,
  }) {
    final frontMatter = _extractFrontMatter(source);
    final imageAttributes = _imageAttributeBlocks(source);
    final markdownSource = frontMatter == null
        ? source
        : source.substring(frontMatter.endOffset).trimLeft();
    var blockIndex = 0;
    final blocks = <BusyBlock>[
      if (frontMatter != null)
        BusyBlock(
          id: 'front-matter',
          kind: BusyBlockKind.frontMatter,
          rawSource: frontMatter.raw,
          preserveRaw: true,
          attributes: frontMatter.values,
        ),
      ...(preserveHtmlSemantics ? _blocksForHtml : _blocksFromMarkdownSource)(
        markdownSource,
        nextId: () => 'b${blockIndex++}',
        mode: mode,
      ),
    ];
    return BusyDocument(
      filePath: filePath,
      mode: mode,
      title: title,
      blocks: _applyImageAttributes(blocks, imageAttributes),
      frontMatter: frontMatter?.values ?? const {},
      rawFrontMatter: frontMatter?.raw,
      source: source,
    );
  }

  /// Use the existing grammar in two phases so definitions on either side of
  /// a raw HTML block share one reference context. No source text is changed.
  List<BusyBlock> _blocksForHtml(
    String source, {
    required String Function() nextId,
    required MarkdownMode mode,
  }) {
    final document = busyMarkMarkdownDocument(mode);
    final nodes = <md.Node>[];
    for (final segment in _rawHtmlAwareSegments(source, mode)) {
      if (segment.rawHtml) {
        nodes.add(
          md.Element.empty('busymark-export-raw')
            ..attributes['source'] = segment.text,
        );
      } else {
        final text = _protectProseHyphenLines(
          _protectImageDestinationsWithSpaces(segment.text),
        );
        nodes.addAll(
          md.BlockParser(
            text.split('\n').map(md.Line.new).toList(),
            document,
          ).parseLines(),
        );
      }
    }
    void parseInlines(List<md.Node> children) {
      for (var i = 0; i < children.length; i++) {
        final node = children[i];
        if (node is md.UnparsedContent) {
          final parsed = document.parseInline(node.textContent);
          children.replaceRange(i, i + 1, parsed);
          i += parsed.length - 1;
        } else if (node is md.Element && node.children != null) {
          parseInlines(node.children!);
        }
      }
    }

    parseInlines(nodes);
    final footnotes = <md.Element>[];
    final body = <md.Node>[];
    for (final node in nodes) {
      if (node is md.Element && node.footnoteLabel != null) {
        final label = node.footnoteLabel!;
        final count = document.footnoteReferences[label] ?? 0;
        if (count == 0) continue;
        final returns = md.Element('p', [
          for (var i = 0; i < count; i++)
            md.Element.text('a', i == 0 ? '↩' : '↩${i + 1}')
              ..attributes['href'] =
                  '#fnref-${Uri.encodeComponent(label)}${i == 0 ? '' : '-${i + 1}'}',
        ]);
        node.children?.add(returns);
        footnotes.add(node);
      } else {
        body.add(node);
      }
    }
    footnotes.sort(
      (a, b) => document.footnoteLabels
          .indexOf(a.footnoteLabel!.toLowerCase())
          .compareTo(
            document.footnoteLabels.indexOf(b.footnoteLabel!.toLowerCase()),
          ),
    );
    if (footnotes.isNotEmpty) {
      body.add(
        md.Element('section', [md.Element('ol', footnotes)])
          ..attributes['class'] = 'footnotes',
      );
    }
    final blocks = [
      for (final node in body)
        if (node is md.Element && node.tag == 'busymark-export-raw')
          BusyBlock(
            id: nextId(),
            kind: BusyBlockKind.htmlBlock,
            rawSource: node.attributes['source'],
            preserveRaw: true,
            attributes: const {'sourceFormat': 'html'},
          )
        else
          ..._blocksFromNode(node, nextId: nextId, mode: mode),
    ];
    return mode == MarkdownMode.writersideMarkdown
        ? _attachWritersideCodeAttributes(blocks)
        : blocks;
  }

  List<BusyBlock> _blocksFromMarkdownSource(
    String source, {
    required String Function() nextId,
    required MarkdownMode mode,
  }) {
    final blocks = <BusyBlock>[];
    for (final segment in _rawHtmlAwareSegments(source, mode)) {
      if (segment.rawHtml) {
        if (mode == MarkdownMode.writersideMarkdown) {
          final writerside = _writersideBlockFromText(
            segment.text,
            nextId: nextId,
            allowVideo: true,
          );
          if (writerside != null) {
            blocks.add(writerside);
            continue;
          }
        }
        final customTag = RegExp(
          r'^\s*<([A-Za-z][A-Za-z0-9_-]*)\b',
        ).firstMatch(segment.text)?.group(1)?.toLowerCase();
        if (customTag != null && _writersideBlockTag(customTag)) {
          blocks.add(
            BusyBlock(
              id: nextId(),
              kind: BusyBlockKind.htmlBlock,
              rawSource: segment.text.trimRight(),
              preserveRaw: true,
              attributes: const {'sourceFormat': 'html'},
            ),
          );
          continue;
        }
        final html = _rawHtmlAdapter.parseRawHtmlBlock(segment.text, nextId);
        if (html != null) {
          blocks.add(
            BusyBlock(
              id: nextId(),
              kind: BusyBlockKind.htmlBlock,
              children: html.safe ? html.blocks : const [],
              rawSource: segment.text.trimRight(),
              preserveRaw: true,
              attributes: const {'sourceFormat': 'html'},
            ),
          );
          continue;
        }
      }
      blocks.addAll(_blocksFromMarkdownSegment(segment.text, nextId, mode));
    }
    return blocks;
  }

  List<BusyBlock> _blocksFromMarkdownSegment(
    String source,
    String Function() nextId,
    MarkdownMode mode,
  ) {
    if (source.trim().isEmpty) {
      return const [];
    }
    final packageSource = _protectProseHyphenLines(
      _protectImageDestinationsWithSpaces(source),
    );
    final document = busyMarkMarkdownDocument(mode);
    final nodes = document.parse(packageSource);
    final blocks = [
      for (final node in nodes)
        ..._blocksFromNode(node, nextId: nextId, mode: mode),
    ];
    return mode == MarkdownMode.writersideMarkdown
        ? _attachWritersideCodeAttributes(blocks)
        : blocks;
  }

  List<BusyBlock> _applyImageAttributes(
    List<BusyBlock> blocks,
    List<Map<String, String>> imageAttributes,
  ) {
    var imageIndex = 0;
    BusyBlock visit(BusyBlock block) {
      final children = block.children.map(visit).toList();
      if (block.kind == BusyBlockKind.image &&
          imageIndex < imageAttributes.length) {
        return block.copyWith(
          children: children,
          attributes: {...block.attributes, ...imageAttributes[imageIndex++]},
        );
      }
      return children.isEmpty ? block : block.copyWith(children: children);
    }

    return blocks.map(visit).toList();
  }

  List<BusyBlock> _blocksFromNode(
    md.Node node, {
    required String Function() nextId,
    required MarkdownMode mode,
  }) {
    if (node is md.Text) {
      final rawText = node.text;
      final text = rawText.trim();
      if (text.isEmpty) {
        return const [];
      }
      if (mode == MarkdownMode.writersideMarkdown) {
        final writerside = _writersideBlockFromText(
          rawText,
          nextId: nextId,
          allowVideo: true,
        );
        if (writerside != null) {
          return [writerside];
        }
      }
      final html = _rawHtmlAdapter.parseRawHtmlBlock(rawText, nextId);
      if (html != null) {
        return [
          BusyBlock(
            id: nextId(),
            kind: BusyBlockKind.htmlBlock,
            children: html.safe ? html.blocks : const [],
            rawSource: rawText,
            preserveRaw: true,
            attributes: const {'sourceFormat': 'html'},
          ),
        ];
      }
      return [
        BusyBlock(
          id: nextId(),
          kind: BusyBlockKind.paragraph,
          inlines: [BusyInline(kind: BusyInlineKind.text, text: text)],
        ),
      ];
    }
    if (node is! md.Element) {
      return [
        BusyBlock(
          id: nextId(),
          kind: BusyBlockKind.unknown,
          rawSource: node.textContent,
          preserveRaw: true,
        ),
      ];
    }

    final tag = node.tag.toLowerCase();
    final children = node.children ?? const <md.Node>[];
    if (tag == busyMarkMathBlockTag) {
      return [
        BusyBlock(
          id: nextId(),
          kind: BusyBlockKind.math,
          inlines: [
            BusyInline(
              kind: BusyInlineKind.math,
              text:
                  node.attributes[busyMarkMathExpressionAttribute] ??
                  node.textContent,
              attributes: node.attributes,
            ),
          ],
          attributes: node.attributes,
        ),
      ];
    }
    if (_headingLevel(tag) case final level?) {
      final rawText = node.textContent.trim();
      final attrId = _attributeValue(rawText, 'id');
      final trailingAttributes = mode == MarkdownMode.writersideMarkdown
          ? _trailingAttributeBlock(rawText)
          : const <String, String>{};
      final hasSupportedAttributeBlock =
          attrId != null || trailingAttributes.isNotEmpty;
      final text = hasSupportedAttributeBlock
          ? _stripTrailingAttributeBlock(rawText)
          : rawText;
      final anchorId = attrId ?? slugForHeading(text);
      final parsedInlines = _inlinesFromNodes(children);
      return [
        BusyBlock(
          id: nextId(),
          kind: BusyBlockKind.heading,
          inlines: hasSupportedAttributeBlock
              ? _stripTrailingAttributeInline(parsedInlines)
              : parsedInlines,
          attributes: {
            'level': '$level',
            'id': anchorId,
            'generatedId': '${attrId == null}',
            ...trailingAttributes,
          },
        ),
      ];
    }

    if (tag == 'p') {
      final writerside = mode == MarkdownMode.writersideMarkdown
          ? _writersideBlockFromText(
              node.textContent,
              nextId: nextId,
              allowVideo: true,
            )
          : null;
      if (writerside != null) {
        return [writerside];
      }
      final inlines = _inlinesFromNodes(children);
      final imageBlock = _imageBlockFromParagraph(node, inlines, nextId);
      if (imageBlock != null) {
        return [imageBlock];
      }
      return [
        BusyBlock(
          id: nextId(),
          kind: BusyBlockKind.paragraph,
          inlines: _normalizeSoftBreaks(inlines),
        ),
      ];
    }

    if (tag == 'pre') {
      final code = children.whereType<md.Element>().firstWhere(
        (element) => element.tag == 'code',
        orElse: () => md.Element.text('code', node.textContent),
      );
      final className = code.attributes['class'] ?? '';
      final language = className.startsWith('language-')
          ? className.substring('language-'.length)
          : '';
      final normalizedLanguage = language.trim().toLowerCase();
      final mathSourceForm = switch (normalizedLanguage) {
        'math' => BusyMathSourceForm.mathFence,
        'tex' when mode == MarkdownMode.writersideMarkdown =>
          BusyMathSourceForm.writersideTexFence,
        _ => null,
      };
      if (mathSourceForm != null) {
        final expression = _codeBlockText(code.textContent);
        return [
          BusyBlock(
            id: nextId(),
            kind: BusyBlockKind.math,
            inlines: [
              BusyInline(
                kind: BusyInlineKind.math,
                text: expression,
                attributes: {
                  busyMarkMathExpressionAttribute: expression,
                  busyMarkMathDisplayAttribute: 'true',
                  busyMarkMathSourceFormAttribute: mathSourceForm.name,
                },
              ),
            ],
            attributes: {
              busyMarkMathExpressionAttribute: expression,
              busyMarkMathDisplayAttribute: 'true',
              busyMarkMathSourceFormAttribute: mathSourceForm.name,
              'language': normalizedLanguage,
            },
          ),
        ];
      }
      return [
        BusyBlock(
          id: nextId(),
          kind: BusyBlockKind.codeBlock,
          inlines: [
            BusyInline(
              kind: BusyInlineKind.text,
              text: _codeBlockText(code.textContent),
            ),
          ],
          attributes: {
            if (language.isNotEmpty) 'language': language,
            if (node.attributes['data-metadata'] case final metadata?)
              'metadata': metadata,
          },
        ),
      ];
    }

    if (tag == 'ul' || tag == 'ol') {
      return _listBlocksFromNode(
        node,
        ordered: tag == 'ol',
        nextId: nextId,
        mode: mode,
      );
    }

    if (tag == 'blockquote') {
      var blocks = [
        for (final child in children)
          ..._blocksFromNode(child, nextId: nextId, mode: mode),
      ];
      final attributes = <String, String>{};
      if (mode == MarkdownMode.writersideMarkdown) {
        final admonition = _writersideBlockquoteAdmonition(blocks);
        blocks = admonition.blocks;
        attributes.addAll({
          busyMarkWritersideAdmonitionAttribute: 'true',
          busyMarkWritersideAdmonitionSourceFormAttribute: 'blockquote',
          'style': admonition.style.name,
        });
      }
      return [
        BusyBlock(
          id: nextId(),
          kind: BusyBlockKind.blockquote,
          inlines: mode == MarkdownMode.writersideMarkdown
              ? const <BusyInline>[]
              : blocks.isEmpty
              ? _inlinesFromNodes(children)
              : const <BusyInline>[],
          children: blocks,
          attributes: attributes,
        ),
      ];
    }

    if (tag == 'hr') {
      return [BusyBlock(id: nextId(), kind: BusyBlockKind.thematicBreak)];
    }

    if (tag == 'table') {
      final tableRows = _tableRows(node, nextId);
      return [
        if (_tableCaption(node, nextId) case final caption?) caption,
        BusyBlock(id: nextId(), kind: BusyBlockKind.table, children: tableRows),
      ];
    }

    if (tag == 'section' && node.attributes['class'] == 'footnotes') {
      return [
        BusyBlock(
          id: nextId(),
          kind: BusyBlockKind.unknown,
          inlines: _inlinesFromNodes(children),
          rawSource: node.textContent,
          // Retain the parser-generated structure for semantic HTML export.
          // Source serialization and preview continue to use the existing fields.
          attributes: {
            'html-footnotes': md.renderToHtml([node]),
          },
          preserveRaw: true,
          isGenerated: true,
        ),
      ];
    }

    if (mode == MarkdownMode.writersideMarkdown && _writersideBlockTag(tag)) {
      if (tag == 'code-block') {
        return [
          _writersideCodeBlock(
            text: node.textContent,
            attributes: node.attributes,
            rawSource: node.textContent,
            nextId: nextId,
          ),
        ];
      }
      return [
        BusyBlock(
          id: nextId(),
          kind: _writersideKind(tag),
          inlines: _inlinesFromNodes(children),
          attributes: {
            ...node.attributes,
            'element': tag,
            if (_writersideAdmonitionTag(tag)) ...{
              busyMarkWritersideAdmonitionAttribute: 'true',
              busyMarkWritersideAdmonitionSourceFormAttribute: 'element',
              'style': tag,
            },
          },
          rawSource: node.textContent,
          preserveRaw: !_editableWritersideTag(tag),
        ),
      ];
    }

    // These names remain protected custom HTML outside Writerside mode. They
    // deliberately receive neither Writerside kinds nor Writerside attributes.
    if (_writersideBlockTag(tag)) {
      return [
        BusyBlock(
          id: nextId(),
          kind: BusyBlockKind.htmlBlock,
          rawSource: node.textContent,
          preserveRaw: true,
          attributes: const {'sourceFormat': 'html'},
        ),
      ];
    }

    if (isUnsafeHtmlTag(tag)) {
      return [
        BusyBlock(
          id: nextId(),
          kind: BusyBlockKind.htmlBlock,
          rawSource: node.textContent,
          preserveRaw: true,
        ),
      ];
    }

    return [
      BusyBlock(
        id: nextId(),
        kind: BusyBlockKind.unknown,
        inlines: _inlinesFromNodes(children),
        rawSource: node.textContent,
        preserveRaw: true,
      ),
    ];
  }

  List<BusyBlock> _listBlocksFromNode(
    md.Element node, {
    required bool ordered,
    required String Function() nextId,
    required MarkdownMode mode,
  }) {
    final result = <BusyBlock>[];
    final items =
        node.children?.whereType<md.Element>().where(
          (child) => child.tag == 'li',
        ) ??
        const Iterable<md.Element>.empty();
    var number = int.tryParse(node.attributes['start'] ?? '') ?? 1;
    for (final item in items) {
      final itemChildren = item.children ?? const <md.Node>[];
      final checked = _taskChecked(itemChildren);
      final contentChildren = _withoutTaskCheckbox(itemChildren);
      final nestedBlocks = <BusyBlock>[];
      final inlineNodes = <md.Node>[];
      var hasPrimaryContent = false;
      for (final child in contentChildren) {
        final blockChild =
            child is md.Element &&
            (child.tag == 'ul' ||
                child.tag == 'ol' ||
                child.tag == 'blockquote' ||
                child.tag == 'pre' ||
                child.tag == 'table' ||
                child.tag == 'hr' ||
                RegExp(r'^h[1-6]$').hasMatch(child.tag) ||
                (child.tag == 'p' &&
                    (hasPrimaryContent || nestedBlocks.isNotEmpty)));
        if (blockChild) {
          nestedBlocks.addAll(
            _blocksFromNode(child, nextId: nextId, mode: mode),
          );
        } else {
          inlineNodes.add(child);
          hasPrimaryContent = true;
        }
      }
      final attributes = {
        'ordered': '$ordered',
        'marker': ordered ? '$number.' : '-',
        if (checked != null) 'task': '$checked',
      };
      result.add(
        BusyBlock(
          id: nextId(),
          kind: checked == null
              ? ordered
                    ? BusyBlockKind.orderedListItem
                    : BusyBlockKind.unorderedListItem
              : BusyBlockKind.taskListItem,
          inlines: _normalizeSoftBreaks(_inlinesFromNodes(inlineNodes)),
          children: nestedBlocks,
          attributes: attributes,
        ),
      );
      number++;
    }
    return result;
  }

  List<BusyInline> _inlinesFromNodes(
    Iterable<md.Node> nodes, {
    Map<BusyInline, BusyMarkMappedInlineRange>? sourceMappings,
  }) {
    return [
      for (final node in nodes)
        ..._inlineFromNode(node, sourceMappings: sourceMappings),
    ];
  }

  List<BusyInline> _inlineFromNode(
    md.Node node, {
    Map<BusyInline, BusyMarkMappedInlineRange>? sourceMappings,
  }) {
    if (node is md.Element &&
        node.attributes[writersideLiteralPercentAttribute] == 'true') {
      return const [
        BusyInline(
          kind: BusyInlineKind.text,
          text: '%',
          attributes: {'ignore-vars': 'true'},
        ),
      ];
    }
    if (node is md.Text) {
      if (node.text.isEmpty) {
        return const [];
      }
      final htmlInlines = _rawHtmlAdapter.parseRawHtmlInlineFragment(node.text);
      if (htmlInlines != null) {
        return htmlInlines;
      }
      return [BusyInline(kind: BusyInlineKind.text, text: node.text)];
    }
    if (node is! md.Element) {
      return [BusyInline(kind: BusyInlineKind.unknown, text: node.textContent)];
    }
    final tag = node.tag.toLowerCase();
    final children = _inlinesFromNodes(
      node.children ?? const <md.Node>[],
      sourceMappings: sourceMappings,
    );
    final text = node.textContent;
    final inlines = switch (tag) {
      busyMarkMathInlineTag => [
        BusyInline(
          kind: BusyInlineKind.math,
          text:
              node.attributes[busyMarkMathExpressionAttribute] ??
              node.textContent,
          attributes: node.attributes,
        ),
      ],
      'strong' || 'b' => [
        BusyInline(kind: BusyInlineKind.strong, text: text, children: children),
      ],
      'em' || 'i' => [
        BusyInline(
          kind: BusyInlineKind.emphasis,
          text: text,
          children: children,
        ),
      ],
      'u' => [
        BusyInline(
          kind: BusyInlineKind.underline,
          text: text,
          children: children,
        ),
      ],
      'del' || 's' => [
        BusyInline(
          kind: BusyInlineKind.strikethrough,
          text: text,
          children: children,
        ),
      ],
      'code' => [BusyInline(kind: BusyInlineKind.code, text: text)],
      'a' => [
        BusyInline(
          kind: BusyInlineKind.link,
          text: text,
          destination: node.attributes['href'],
          children: children,
          attributes: {
            for (final entry in node.attributes.entries)
              if (!entry.key.startsWith('data-busymark-source-'))
                entry.key: entry.value,
            if (node.attributes['title'] case final title?)
              'title': _decodeMarkdownAttribute(title),
          },
        ),
      ],
      'img' => [
        BusyInline(
          kind: BusyInlineKind.image,
          text: node.attributes['alt'] ?? '',
          destination: node.attributes['src'],
          attributes: node.attributes,
        ),
      ],
      'br' => const [BusyInline(kind: BusyInlineKind.hardBreak, text: '\n')],
      'var' => [
        BusyInline(
          kind: BusyInlineKind.writersideVariable,
          text: text,
          attributes: node.attributes,
        ),
      ],
      _ when isUnsafeHtmlTag(tag) => [
        BusyInline(kind: BusyInlineKind.html, text: text),
      ],
      _ => [
        if (children.isEmpty)
          BusyInline(kind: BusyInlineKind.text, text: text)
        else
          ...children,
      ],
    };
    if (sourceMappings != null && inlines.length == 1) {
      final mappedStart = int.tryParse(
        node.attributes[_sourceMappingStartAttribute] ?? '',
      );
      final mappedEnd = int.tryParse(
        node.attributes[_sourceMappingEndAttribute] ?? '',
      );
      if (mappedStart != null && mappedEnd != null) {
        sourceMappings[inlines.single] = BusyMarkMappedInlineRange(
          start: mappedStart,
          end: mappedEnd,
          opening: node.attributes[_sourceMappingOpeningAttribute],
          closing: node.attributes[_sourceMappingClosingAttribute],
          labelStart: int.tryParse(
            node.attributes[_sourceMappingLabelStartAttribute] ?? '',
          ),
          labelEnd: int.tryParse(
            node.attributes[_sourceMappingLabelEndAttribute] ?? '',
          ),
          isAutolink:
              node.attributes[_sourceMappingAutolinkAttribute] == 'true',
          isReference:
              node.attributes[_sourceMappingReferenceAttribute] == 'true',
          isSourceLineBreak:
              node.attributes[_sourceMappingLineBreakAttribute] == 'true',
        );
      }
    }
    return inlines;
  }

  BusyBlock? _imageBlockFromParagraph(
    md.Element paragraph,
    List<BusyInline> inlines,
    String Function() nextId,
  ) {
    final images = _imageInlines(inlines).toList(growable: false);
    if (images.length != 1) {
      return null;
    }
    final imageInline = images.single;
    final plain = paragraph.textContent.trim();
    final attributeText = plain.replaceFirst(imageInline.text, '').trim();
    if (inlines.length > 2 ||
        (attributeText.isNotEmpty && !attributeText.startsWith('{'))) {
      return null;
    }
    return BusyBlock(
      id: nextId(),
      kind: BusyBlockKind.image,
      inlines: [_imageBlockInline(inlines, imageInline)],
      attributes: {
        ...imageInline.attributes,
        if (imageInline.destination case final destination?) 'src': destination,
        ..._parseAttributeBlock(attributeText),
      },
    );
  }

  BusyInline _imageBlockInline(
    List<BusyInline> inlines,
    BusyInline imageInline,
  ) {
    final firstInline = inlines.firstOrNull;
    if (firstInline != null &&
        firstInline.kind == BusyInlineKind.link &&
        _imageInlines([firstInline]).length == 1) {
      return firstInline;
    }
    return imageInline;
  }

  Iterable<BusyInline> _imageInlines(Iterable<BusyInline> inlines) sync* {
    for (final inline in inlines) {
      if (inline.kind == BusyInlineKind.image) {
        yield inline;
      }
      yield* _imageInlines(inline.children);
    }
  }

  List<BusyBlock> _tableRows(md.Element table, String Function() nextId) {
    final rows = <BusyBlock>[];

    void addRow(md.Element row, {required bool sectionHeader}) {
      final cells =
          row.children
              ?.whereType<md.Element>()
              .where((cell) => cell.tag == 'th' || cell.tag == 'td')
              .toList() ??
          const <md.Element>[];
      if (cells.isEmpty) {
        return;
      }
      final allHeaderCells = cells.every((cell) => cell.tag == 'th');
      rows.add(
        BusyBlock(
          id: nextId(),
          kind: BusyBlockKind.table,
          attributes: {'header': '${sectionHeader || allHeaderCells}'},
          children: [
            for (final cell in cells)
              BusyBlock(
                id: nextId(),
                kind: BusyBlockKind.paragraph,
                inlines: _inlinesFromNodes(cell.children ?? const []),
                attributes: _tableCellAttributes(cell),
              ),
          ],
        ),
      );
    }

    for (final child
        in table.children?.whereType<md.Element>() ?? const <md.Element>[]) {
      final tag = child.tag.toLowerCase();
      if (tag == 'tr') {
        addRow(child, sectionHeader: false);
      } else if (tag == 'thead' || tag == 'tbody' || tag == 'tfoot') {
        for (final row
            in child.children?.whereType<md.Element>() ??
                const <md.Element>[]) {
          if (row.tag == 'tr') {
            addRow(row, sectionHeader: tag == 'thead');
          }
        }
      }
    }
    return rows;
  }

  BusyBlock? _tableCaption(md.Element table, String Function() nextId) {
    final caption = table.children
        ?.whereType<md.Element>()
        .where((child) => child.tag == 'caption')
        .firstOrNull;
    if (caption == null) {
      return null;
    }
    return BusyBlock(
      id: nextId(),
      kind: BusyBlockKind.paragraph,
      inlines: _inlinesFromNodes(caption.children ?? const []),
      attributes: const {'htmlTag': 'caption'},
    );
  }

  Map<String, String> _tableCellAttributes(md.Element cell) {
    return {
      'cell': cell.tag,
      for (final name in ['align', 'colspan', 'rowspan', 'scope'])
        if (cell.attributes[name] case final value?) name: value,
    };
  }

  BusyBlock? _writersideBlockFromText(
    String value, {
    required String Function() nextId,
    required bool allowVideo,
  }) {
    try {
      final fragment = XmlDocumentFragment.parse(value.trim());
      final elements = fragment.children.whereType<XmlElement>().toList();
      if (elements.length == 1 &&
          !fragment.children.whereType<XmlText>().any(
            (node) => node.value.trim().isNotEmpty,
          )) {
        final element = elements.single;
        final tag = element.name.local.toLowerCase();
        if (_writersideBlockTag(tag) && (tag != 'video' || allowVideo)) {
          final text = tag == 'code-block'
              ? element.innerText
                    .replaceFirst(RegExp(r'^\n'), '')
                    .replaceFirst(RegExp(r'\n\s*$'), '')
              : element.innerText.trim();
          final attributes = <String, String>{
            'element': tag,
            for (final attribute in element.attributes)
              attribute.name.local: attribute.value,
            if (tag == 'code-block' && element.getAttribute('lang') != null)
              'language': element.getAttribute('lang')!,
          };
          if (tag == 'code-block') {
            return _writersideCodeBlock(
              text: text,
              attributes: attributes,
              rawSource: value,
              nextId: nextId,
            );
          }
          return BusyBlock(
            id: nextId(),
            kind: _writersideKind(tag),
            inlines: text.isEmpty
                ? const []
                : [BusyInline(kind: BusyInlineKind.text, text: text)],
            attributes: {
              ...attributes,
              if (_writersideAdmonitionTag(tag)) ...{
                busyMarkWritersideAdmonitionAttribute: 'true',
                busyMarkWritersideAdmonitionSourceFormAttribute: 'element',
                'style': tag,
              },
            },
            rawSource: value,
            preserveRaw: !_editableWritersideTag(tag),
          );
        }
      }
    } on Object {
      // The established paired-tag fallback below remains tolerant while the
      // Markdown topic is being edited.
    }
    final match = RegExp(
      r'^\s*<([A-Za-z][A-Za-z0-9_-]*)\b([^>]*)>(.*?)</\1>\s*$',
      dotAll: true,
    ).firstMatch(value);
    if (match == null) {
      return null;
    }
    final tag = match.group(1)!.toLowerCase();
    if (!_writersideBlockTag(tag)) {
      return null;
    }
    final rawText = match.group(3)!.trim();
    final attributes = <String, String>{
      'element': tag,
      ..._parseAttributePairs(match.group(2)!),
    };
    if (tag == 'code-block') {
      final language = attributes['lang'];
      return _writersideCodeBlock(
        text: busyMarkDecodeXmlMathText(rawText),
        attributes: {...attributes, if (language != null) 'language': language},
        rawSource: value,
        nextId: nextId,
      );
    }
    return BusyBlock(
      id: nextId(),
      kind: _writersideKind(tag),
      inlines: [BusyInline(kind: BusyInlineKind.text, text: rawText)],
      attributes: {
        ...attributes,
        if (_writersideAdmonitionTag(tag)) ...{
          busyMarkWritersideAdmonitionAttribute: 'true',
          busyMarkWritersideAdmonitionSourceFormAttribute: 'element',
          'style': tag,
        },
      },
      rawSource: value,
      preserveRaw: !_editableWritersideTag(tag),
    );
  }

  BusyBlock _writersideCodeBlock({
    required String text,
    required Map<String, String> attributes,
    required String rawSource,
    required String Function() nextId,
  }) {
    final language = (attributes['language'] ?? attributes['lang'] ?? '')
        .trim();
    final normalizedLanguage = language.toLowerCase();
    final commonAttributes = <String, String>{
      ...attributes,
      'element': 'code-block',
      if (language.isNotEmpty) ...{'lang': language, 'language': language},
      busyMarkWritersideCodeBlockSourceFormAttribute:
          busyMarkWritersideCodeBlockElementSourceForm,
    };
    if (normalizedLanguage == 'tex') {
      return BusyBlock(
        id: nextId(),
        kind: BusyBlockKind.math,
        inlines: [
          BusyInline(
            kind: BusyInlineKind.math,
            text: text,
            attributes: {
              busyMarkMathExpressionAttribute: text,
              busyMarkMathDisplayAttribute: 'true',
              busyMarkMathSourceFormAttribute:
                  BusyMathSourceForm.writersideTexElement.name,
            },
          ),
        ],
        attributes: {
          ...commonAttributes,
          busyMarkMathExpressionAttribute: text,
          busyMarkMathDisplayAttribute: 'true',
          busyMarkMathSourceFormAttribute:
              BusyMathSourceForm.writersideTexElement.name,
        },
        rawSource: rawSource,
        preserveRaw: false,
      );
    }
    return BusyBlock(
      id: nextId(),
      kind: BusyBlockKind.codeBlock,
      inlines: text.isEmpty
          ? const []
          : [BusyInline(kind: BusyInlineKind.text, text: text)],
      attributes: commonAttributes,
      rawSource: rawSource,
      preserveRaw: false,
    );
  }

  int? _headingLevel(String tag) {
    if (!RegExp(r'^h[1-6]$').hasMatch(tag)) {
      return null;
    }
    return int.parse(tag.substring(1));
  }

  List<BusyInline> _normalizeSoftBreaks(List<BusyInline> inlines) {
    final result = <BusyInline>[];
    for (final inline in inlines) {
      if (inline.kind == BusyInlineKind.text && inline.text.contains('\n')) {
        final parts = inline.text.split('\n');
        for (var i = 0; i < parts.length; i++) {
          if (parts[i].isNotEmpty) {
            result.add(BusyInline(kind: BusyInlineKind.text, text: parts[i]));
          }
          if (i < parts.length - 1) {
            result.add(
              const BusyInline(kind: BusyInlineKind.softBreak, text: ' '),
            );
          }
        }
      } else {
        result.add(inline);
      }
    }
    return result;
  }

  List<BusyInline> _stripTrailingAttributeInline(List<BusyInline> inlines) {
    if (inlines.isEmpty) {
      return inlines;
    }
    final text = inlines.map((inline) => inline.plainText).join();
    final stripped = _stripTrailingAttributeBlock(text);
    if (stripped == text) {
      return inlines;
    }
    return [BusyInline(kind: BusyInlineKind.text, text: stripped)];
  }

  bool? _taskChecked(List<md.Node> children) {
    for (final child in children) {
      if (child is md.Element && child.tag == 'input') {
        return child.attributes['checked'] == 'true';
      }
      if (child is md.Element && child.children != null) {
        final nested = _taskChecked(child.children!);
        if (nested != null) {
          return nested;
        }
      }
    }
    return null;
  }

  List<md.Node> _withoutTaskCheckbox(List<md.Node> children) {
    return [
      for (final child in children)
        if (child is md.Element && child.tag == 'input')
          ...const <md.Node>[]
        else if (child is md.Element && child.children != null)
          md.Element(child.tag, _withoutTaskCheckbox(child.children!))
            ..attributes.addAll(child.attributes)
        else
          child,
    ];
  }

  String _stripTrailingAttributeBlock(String value) {
    return value.replaceFirst(RegExp(r'\s*\{[^}]+\}\s*$'), '').trim();
  }

  Map<String, String> _trailingAttributeBlock(String value) {
    final match = RegExp(r'(\{[^{}]+\})\s*$').firstMatch(value);
    return match == null ? const {} : _parseAttributeBlock(match.group(1)!);
  }

  List<BusyBlock> _attachWritersideCodeAttributes(List<BusyBlock> blocks) {
    final result = <BusyBlock>[];
    var index = 0;
    while (index < blocks.length) {
      final block = blocks[index];
      if (block.kind == BusyBlockKind.codeBlock && index + 1 < blocks.length) {
        final attributeBlock = blocks[index + 1];
        final attributes = attributeBlock.kind == BusyBlockKind.paragraph
            ? _standaloneAttributeBlock(attributeBlock.plainText)
            : const <String, String>{};
        if (busyMarkWritersideIsCollapsible(attributes) ||
            (attributes['src']?.trim().isNotEmpty ?? false)) {
          result.add(
            block.copyWith(attributes: {...block.attributes, ...attributes}),
          );
          index += 2;
          continue;
        }
      }
      result.add(block);
      index += 1;
    }
    return result;
  }

  Map<String, String> _standaloneAttributeBlock(String value) {
    final trimmed = value.trim();
    if (!RegExp(r'^\{[^{}]+\}$').hasMatch(trimmed)) {
      return const {};
    }
    return _parseAttributeBlock(trimmed);
  }

  String? _attributeValue(String raw, String key) {
    return RegExp('$key\\s*=\\s*"([^"]+)"').firstMatch(raw)?.group(1);
  }

  Map<String, String> _parseAttributeBlock(String raw) {
    final trimmed = raw.trim();
    if (!trimmed.startsWith('{') || !trimmed.endsWith('}')) {
      return const {};
    }
    return _parseAttributePairs(trimmed.substring(1, trimmed.length - 1));
  }

  Map<String, String> _parseAttributePairs(String raw) {
    final attributes = <String, String>{};
    for (final match in RegExp(
      r'([A-Za-z_:][-A-Za-z0-9_:.]*)\s*=\s*"([^"]*)"',
    ).allMatches(raw)) {
      attributes[match.group(1)!] = match.group(2)!;
    }
    return attributes;
  }

  String _protectImageDestinationsWithSpaces(String source) {
    final buffer = StringBuffer();
    var index = 0;
    while (index < source.length) {
      final imageStart = source.indexOf('![', index);
      if (imageStart == -1) {
        buffer.write(source.substring(index));
        break;
      }
      buffer.write(source.substring(index, imageStart));
      final labelEnd = _findClosingDelimiter(
        source,
        imageStart + 2,
        open: '[',
        close: ']',
      );
      if (labelEnd == -1 ||
          labelEnd + 1 >= source.length ||
          source.codeUnitAt(labelEnd + 1) != 0x28) {
        buffer.write(source.substring(imageStart, imageStart + 2));
        index = imageStart + 2;
        continue;
      }
      final destinationStart = labelEnd + 2;
      final destinationEnd = _findClosingDelimiter(
        source,
        destinationStart,
        open: '(',
        close: ')',
      );
      if (destinationEnd == -1) {
        buffer.write(source.substring(imageStart));
        break;
      }
      final rawDestination = source.substring(destinationStart, destinationEnd);
      buffer
        ..write(source.substring(imageStart, destinationStart))
        ..write(_protectImageDestination(rawDestination))
        ..write(')');
      index = destinationEnd + 1;
    }
    return buffer.toString();
  }

  int _findClosingDelimiter(
    String source,
    int start, {
    required String open,
    required String close,
  }) {
    var depth = 0;
    var escaped = false;
    for (var index = start; index < source.length; index += 1) {
      final char = source[index];
      if (escaped) {
        escaped = false;
        continue;
      }
      if (char == '\\') {
        escaped = true;
        continue;
      }
      if (char == open) {
        depth += 1;
        continue;
      }
      if (char != close) {
        continue;
      }
      if (depth == 0) {
        return index;
      }
      depth -= 1;
    }
    return -1;
  }

  String _protectImageDestination(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty || !RegExp(r'\s').hasMatch(trimmed)) {
      return raw;
    }
    if (trimmed.startsWith('<') && trimmed.endsWith('>')) {
      return raw;
    }
    final leading = raw.substring(0, raw.indexOf(trimmed));
    final trailing = raw.substring(leading.length + trimmed.length);
    final titled = RegExp(
      r'''^(.+?)(\s+(?:"[^"]*"|'[^']*'|\([^)]*\)))$''',
    ).firstMatch(trimmed);
    if (titled != null && _looksLikeImageDestination(titled.group(1)!)) {
      return '$leading${_encodeImageDestinationWhitespace(titled.group(1)!)}'
          '${titled.group(2)!}$trailing';
    }
    if (!_looksLikeImageDestination(trimmed)) {
      return raw;
    }
    return '$leading${_encodeImageDestinationWhitespace(trimmed)}$trailing';
  }

  bool _looksLikeImageDestination(String value) {
    var path = value.trim();
    if (path.startsWith('<') && path.endsWith('>')) {
      path = path.substring(1, path.length - 1);
    }
    path = path.split('#').first.split('?').first;
    try {
      path = Uri.decodeComponent(path);
    } on FormatException {
      // Keep the original path for the extension check.
    }
    return RegExp(
      r'\.(?:avif|bmp|gif|ico|jpe?g|png|svg|tiff?|webp)$',
      caseSensitive: false,
    ).hasMatch(path);
  }

  String _encodeImageDestinationWhitespace(String value) {
    return value.replaceAllMapped(RegExp(r'[ \t]'), (match) {
      return match.group(0) == '\t' ? '%09' : '%20';
    });
  }

  List<Map<String, String>> _imageAttributeBlocks(String source) {
    return [
      for (final match in RegExp(
        r'!\[[^\]]*\]\([^)]+\)\s*(\{[^}]+\})',
      ).allMatches(source))
        _parseAttributeBlock(match.group(1)!),
    ];
  }

  bool _writersideBlockTag(String tag) {
    return WritersideSchema.isMarkdownSemanticBlock(tag);
  }

  bool _editableWritersideTag(String tag) {
    return _writersideAdmonitionTag(tag);
  }

  bool _writersideAdmonitionTag(String tag) {
    return busyAdmonitionStyleFromName(tag) != null;
  }

  BusyBlockKind _writersideKind(String tag) {
    return switch (tag) {
      'note' ||
      'tip' ||
      'warning' ||
      'quote' => BusyBlockKind.writersideAdmonition,
      'tabs' || 'tab' => BusyBlockKind.writersideTabs,
      'procedure' => BusyBlockKind.writersideProcedure,
      'video' => BusyBlockKind.video,
      _ => BusyBlockKind.writersideRawXml,
    };
  }

  ({BusyAdmonitionStyle style, List<BusyBlock> blocks})
  _writersideBlockquoteAdmonition(List<BusyBlock> blocks) {
    for (var index = blocks.length - 1; index >= 0; index -= 1) {
      final block = blocks[index];
      if (block.kind != BusyBlockKind.paragraph || block.inlines.isEmpty) {
        continue;
      }
      final match = RegExp(r'\s*\{([^{}]*)\}\s*$').firstMatch(block.plainText);
      if (match == null) {
        break;
      }
      final style = busyAdmonitionStyleFromName(
        _parseAttributePairs(match.group(1)!)['style'],
      );
      if (style == null) {
        break;
      }
      final cleaned = _takeInlinePrefix(block.inlines, match.start);
      final updated = [...blocks];
      if (cleaned.isEmpty && block.children.isEmpty) {
        updated.removeAt(index);
      } else {
        updated[index] = block.copyWith(inlines: cleaned);
      }
      return (style: style, blocks: updated);
    }
    return (style: BusyAdmonitionStyle.tip, blocks: blocks);
  }

  List<BusyInline> _takeInlinePrefix(List<BusyInline> inlines, int length) {
    if (length <= 0) {
      return const [];
    }
    final result = <BusyInline>[];
    var remaining = length;
    for (final inline in inlines) {
      final inlineLength = inline.plainText.length;
      if (inlineLength == 0) {
        result.add(inline);
        continue;
      }
      if (remaining >= inlineLength) {
        result.add(inline);
        remaining -= inlineLength;
        continue;
      }
      if (remaining > 0) {
        if (inline.children.isEmpty) {
          result.add(
            inline.copyWith(text: inline.text.substring(0, remaining)),
          );
        } else {
          result.add(
            inline.copyWith(
              children: _takeInlinePrefix(inline.children, remaining),
            ),
          );
        }
      }
      break;
    }
    while (result.isNotEmpty &&
        (result.last.kind == BusyInlineKind.softBreak ||
            result.last.kind == BusyInlineKind.hardBreak)) {
      result.removeLast();
    }
    final last = result.lastOrNull;
    if (last != null &&
        last.children.isEmpty &&
        last.kind == BusyInlineKind.text &&
        last.text.trimRight() != last.text) {
      final trimmed = last.text.trimRight();
      if (trimmed.isEmpty) {
        result.removeLast();
      } else {
        result[result.length - 1] = last.copyWith(text: trimmed);
      }
    }
    return result;
  }

  _FrontMatter? _extractFrontMatter(String source) {
    final closing = frontMatterClosing(source);
    if (closing == null) {
      return null;
    }
    final end = frontMatterEndOffset(source);
    final raw = source.substring(0, end);
    final body = source.substring(4, closing.start);
    final values = <String, String>{};
    for (final line in body.split('\n')) {
      final match = RegExp(
        r'^\s*([A-Za-z0-9_-]+)\s*:\s*(.+?)\s*$',
      ).firstMatch(line);
      if (match != null) {
        values[match.group(1)!] = match
            .group(2)!
            .replaceAll(RegExp(r'''^["']|["']$'''), '');
      }
    }
    return _FrontMatter(raw: raw, endOffset: end, values: values);
  }

  String _protectProseHyphenLines(String source) {
    final lines = source.split('\n');
    for (var i = 1; i < lines.length; i++) {
      if (lines[i].trim() != '---') {
        continue;
      }
      final previous = lines[i - 1].trim();
      if (previous.contains(':')) {
        lines[i] = '\n${r'\---'}\n';
      }
    }
    return lines.join('\n');
  }

  List<_MarkdownSourceSegment> _rawHtmlAwareSegments(
    String source,
    MarkdownMode mode,
  ) {
    final lines = _markdownSourceLines(source);
    final segments = <_MarkdownSourceSegment>[];
    var segmentStart = 0;
    var index = 0;
    MarkdownFence? fence;

    while (index < lines.length) {
      final line = lines[index].line;
      if (fence != null) {
        if (fence.closes(line)) {
          fence = null;
        }
        index += 1;
        continue;
      }

      fence = MarkdownFence.parse(line);
      if (fence != null) {
        index += 1;
        continue;
      }

      if (mode == MarkdownMode.writersideMarkdown &&
          RegExp(
            r'^\s{0,3}<math(?:\s|/?>)',
            caseSensitive: false,
          ).hasMatch(line)) {
        index += 1;
        continue;
      }

      final writersideEndIndex = _writersideContainerEndIndex(lines, index);
      if (writersideEndIndex != null) {
        final startOffset = lines[index].offset;
        final endOffset = lines[writersideEndIndex - 1].endOffset;
        if (segmentStart < startOffset) {
          segments.add(
            _MarkdownSourceSegment(
              text: source.substring(segmentStart, startOffset),
              rawHtml: false,
            ),
          );
        }
        segments.add(
          _MarkdownSourceSegment(
            text: source.substring(startOffset, endOffset),
            rawHtml: true,
          ),
        );
        segmentStart = endOffset;
        index = writersideEndIndex;
        continue;
      }

      final htmlEndIndex = _rawHtmlContainerEndIndex(lines, index);
      if (htmlEndIndex == null) {
        index += 1;
        continue;
      }

      final startOffset = lines[index].offset;
      final endOffset = lines[htmlEndIndex - 1].endOffset;
      if (segmentStart < startOffset) {
        segments.add(
          _MarkdownSourceSegment(
            text: source.substring(segmentStart, startOffset),
            rawHtml: false,
          ),
        );
      }
      segments.add(
        _MarkdownSourceSegment(
          text: source.substring(startOffset, endOffset),
          rawHtml: true,
        ),
      );
      segmentStart = endOffset;
      index = htmlEndIndex;
    }

    if (segmentStart < source.length) {
      segments.add(
        _MarkdownSourceSegment(
          text: source.substring(segmentStart),
          rawHtml: false,
        ),
      );
    }
    return segments;
  }

  List<_MarkdownSourceLine> _markdownSourceLines(String source) {
    final lines = <_MarkdownSourceLine>[];
    var offset = 0;
    for (final rawLine in source.split(RegExp('(?<=\n)'))) {
      lines.add(_MarkdownSourceLine(rawLine: rawLine, offset: offset));
      offset += rawLine.length;
    }
    return lines;
  }

  int? _rawHtmlContainerEndIndex(
    List<_MarkdownSourceLine> lines,
    int startIndex,
  ) {
    final tag = _rawHtmlContainerOpeningTag(lines[startIndex].line);
    if (tag == null) {
      return null;
    }

    var balance = 0;
    for (var index = startIndex; index < lines.length; index += 1) {
      balance += _rawHtmlTagBalance(lines[index].line, tag);
      if (balance <= 0 && index > startIndex || balance == 0) {
        return index + 1;
      }
    }
    return null;
  }

  int? _writersideContainerEndIndex(
    List<_MarkdownSourceLine> lines,
    int startIndex,
  ) {
    final match = RegExp(
      r'^\s{0,3}<([A-Za-z][A-Za-z0-9_-]*)\b',
    ).firstMatch(lines[startIndex].line);
    final tag = match?.group(1)?.toLowerCase();
    if (tag == null || !_writersideBlockTag(tag)) {
      return null;
    }
    var balance = 0;
    for (var index = startIndex; index < lines.length; index += 1) {
      balance += _rawHtmlTagBalance(lines[index].line, tag);
      if (balance <= 0) {
        return index + 1;
      }
    }
    return null;
  }

  String? _rawHtmlContainerOpeningTag(String line) {
    final match = RegExp(
      r'^\s{0,3}<([A-Za-z][A-Za-z0-9_-]*)\b',
    ).firstMatch(line);
    if (match == null) {
      return null;
    }
    final tag = match.group(1)!.toLowerCase();
    if (voidHtmlTags.contains(tag)) {
      return null;
    }
    if (!isSafeBlockHtmlTag(tag) && !isUnsafeHtmlTag(tag)) {
      return null;
    }
    return tag;
  }

  int _rawHtmlTagBalance(String line, String tag) {
    final pattern = RegExp(
      '</?\\s*${RegExp.escape(tag)}(?=\\s|>|/)',
      caseSensitive: false,
    );
    var balance = 0;
    for (final match in pattern.allMatches(line)) {
      final closing = line.startsWith('</', match.start);
      if (closing) {
        balance -= 1;
        continue;
      }
      if (_rawHtmlTagLooksSelfClosing(line, match.start)) {
        continue;
      }
      balance += 1;
    }
    return balance;
  }

  bool _rawHtmlTagLooksSelfClosing(String line, int start) {
    final end = line.indexOf('>', start);
    if (end == -1) {
      return false;
    }
    return line.substring(start, end + 1).trimRight().endsWith('/>');
  }

  String _codeBlockText(String text) {
    // package:markdown appends one structural LF to non-empty code blocks.
    return text.endsWith('\n') ? text.substring(0, text.length - 1) : text;
  }
}

class _MarkdownSourceSegment {
  const _MarkdownSourceSegment({required this.text, required this.rawHtml});

  final String text;
  final bool rawHtml;
}

class _MarkdownSourceLine {
  const _MarkdownSourceLine({required this.rawLine, required this.offset});

  final String rawLine;
  final int offset;

  int get endOffset => offset + rawLine.length;

  String get line => rawLine.endsWith('\n')
      ? rawLine.substring(0, rawLine.length - 1)
      : rawLine;
}

class _FrontMatter {
  const _FrontMatter({
    required this.raw,
    required this.endOffset,
    required this.values,
  });

  final String raw;
  final int endOffset;
  final Map<String, String> values;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
