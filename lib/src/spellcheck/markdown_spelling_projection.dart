import 'dart:math' as math;

import 'package:html/parser.dart' as html;

import '../core/source_span.dart';
import '../markdown/busymark_document.dart';
import '../markdown/markdown_fence.dart';
import '../markdown/markdown_model.dart';
import '../markdown/markdown_parser.dart';
import '../markdown/markdown_source_map.dart';
import '../markdown/markdown_source_structure.dart';
import 'spelling_projection.dart';
import 'spelling_text_patterns.dart';

final class MarkdownSpellingProjector {
  const MarkdownSpellingProjector({this.parser = const MarkdownParser()});

  final MarkdownParser parser;

  SpellingProjectionResult project({
    required String filePath,
    required String source,
    required MarkdownMode mode,
    required String languageId,
    required SpellingSnapshotIdentity snapshot,
    SpellingSourceContext proseContext = SpellingSourceContext.markdownProse,
  }) {
    final parsed = parser.parse(
      filePath: filePath,
      source: source,
      mode: mode,
      validateLocalReferences: false,
    );
    final chunks = parser.positionedSourceChunks(
      filePath: filePath,
      source: source,
      mode: mode,
    );
    final inlineParser = const MarkdownSourceMapper().createInlineParserContext(
      documentSource: source,
      mode: mode,
    );
    final excludedBlockSpans = <SourceSpan>[
      ...parsed.codeBlocks.map((block) => block.span),
      for (final block in _walkBlocks(parsed.busyDocument.blocks))
        if ((block.kind == BusyBlockKind.math ||
                block.kind == BusyBlockKind.codeBlock) &&
            block.sourceSpan != null)
          block.sourceSpan!,
    ];
    final fencedCodeSpans = _fencedCodeSpans(
      source,
      parsed.busyDocument.blocks,
    );
    final recognizedAttributeSpans = <_SourceInterval>[];
    for (final block in _walkBlocks(parsed.busyDocument.blocks)) {
      final span = block.sourceSpan;
      if (block.kind != BusyBlockKind.heading || span == null) continue;
      final raw = source
          .substring(span.startOffset, span.endOffset)
          .trimRight();
      final trailing = RegExp(r'[ \t]+\{[^{}]*\}$').firstMatch(raw);
      if (trailing != null &&
          _isRecognizedHeadingAttribute(
            raw.substring(trailing.start).trim(),
            block.attributes,
          )) {
        recognizedAttributeSpans.add(
          _SourceInterval(
            span.startOffset + trailing.start,
            span.startOffset + trailing.end,
          ),
        );
      }
    }
    final footnoteLabels = <String>{};
    void collectFootnotes(BusyInline inline) {
      final destination = inline.destination;
      if (inline.kind == BusyInlineKind.link &&
          (inline.attributes['id']?.startsWith('fnref-') ?? false) &&
          destination != null &&
          destination.startsWith('#fn-')) {
        footnoteLabels.add(
          Uri.decodeComponent(destination.substring(4)).toLowerCase(),
        );
      }
      for (final child in inline.children) {
        collectFootnotes(child);
      }
    }

    for (final block in _walkBlocks(parsed.busyDocument.blocks)) {
      for (final inline in block.inlines) {
        collectFootnotes(inline);
      }
    }
    final tables = [
      for (final block in _walkBlocks(parsed.busyDocument.blocks))
        if (block.kind == BusyBlockKind.table &&
            !block.attributes.containsKey('header'))
          block,
    ];
    final runs = <SpellingProseRun>[];
    final imageDescriptions = <SpellingMappedImageDescription>[];
    final multilineHtmlSpans = _multilineHtmlSpans(source, 0, source.length);
    var complete = true;
    var sequence = 0;

    void addMapped(
      int mappedStart,
      int mappedEnd,
      BusyMarkMappedInlineParse mapped, {
      required int sourceBase,
      required int sourceLimit,
      required bool stripBlockSyntax,
      required SpellingSourceContext context,
    }) {
      final multilineHtml = multilineHtmlSpans;
      final imageLabels =
          <
            ({
              BusyMarkMappedInlineParse mapped,
              int sourceBase,
              List<_MappedImageCode> codes,
            })
          >[];
      void collectImageLabels(BusyMarkMappedInlineParse parent, int base) {
        for (final entry in parent.ranges.entries) {
          if (entry.key.kind != BusyInlineKind.image ||
              entry.value.labelStart == null ||
              entry.value.labelEnd == null) {
            continue;
          }
          final labelStart = base + entry.value.labelStart!;
          final labelEnd = base + entry.value.labelEnd!;
          final reparsed = _parseMappedImageLabel(
            inlineParser,
            source.substring(labelStart, labelEnd),
            sourceBase: labelStart,
            positionedBreaks: [
              for (final lineBreak in parent.positionedLineBreaks)
                if (lineBreak.sourceOffset case final offset?)
                  if (base + offset >= labelStart &&
                      base +
                              offset +
                              lineBreak.lineEnding.length +
                              lineBreak.continuationPrefix.length <=
                          labelEnd)
                    BusyMarkMappedSourceLineBreak(
                      textOffset: lineBreak.textOffset,
                      lineEnding: lineBreak.lineEnding,
                      continuationPrefix: lineBreak.continuationPrefix,
                      sourceOffset: base + offset - labelStart,
                    ),
            ],
          );
          if (!reparsed.mapped.positionRecordsComplete) complete = false;
          if (reparsed.mapped.imageDescriptionText != entry.key.plainText) {
            complete = false;
          }
          if (identical(parent, mapped)) {
            final semanticInlines = _imageFieldInlines(
              reparsed.mapped,
              source.substring(labelStart, labelEnd),
            );
            if (semanticInlines.map((inline) => inline.plainText).join() !=
                entry.key.plainText) {
              complete = false;
            } else {
              imageDescriptions.add(
                SpellingMappedImageDescription(
                  sourceStart: base + entry.value.start,
                  sourceEnd: base + entry.value.end,
                  alternativeText: entry.key.plainText,
                  destination: entry.key.destination,
                  inlines: semanticInlines,
                ),
              );
            }
          }
          final label = (
            mapped: reparsed.mapped,
            sourceBase: labelStart,
            codes: reparsed.codes,
          );
          imageLabels.add(label);
          collectImageLabels(label.mapped, label.sourceBase);
        }
      }

      collectImageLabels(mapped, sourceBase);
      final formattingSyntax = <_SourceInterval>[
        ..._formattingSyntaxSpans([mapped], sourceBase: sourceBase),
        for (final label in imageLabels)
          ..._formattingSyntaxSpans([
            label.mapped,
          ], sourceBase: label.sourceBase),
      ]..sort((left, right) => left.start.compareTo(right.start));
      final opaqueSyntax = <_SourceInterval>[
        ..._opaqueSyntaxSpans([mapped], sourceBase: sourceBase),
        for (final label in imageLabels)
          ..._opaqueSyntaxSpans(
            [label.mapped],
            sourceBase: label.sourceBase,
            excludedKinds: {
              BusyInlineKind.math,
              BusyInlineKind.writersideVariable,
            },
          ),
        for (final span in excludedBlockSpans)
          if (span.startOffset < sourceLimit && span.endOffset > sourceBase)
            _SourceInterval(span.startOffset, span.endOffset),
        for (final span in fencedCodeSpans)
          if (span.start < sourceLimit && span.end > sourceBase) span,
        if (mode == MarkdownMode.writersideMarkdown)
          for (final variable in parsed.variables)
            if (variable.span.startOffset < sourceLimit &&
                variable.span.endOffset > sourceBase)
              _SourceInterval(
                variable.span.startOffset,
                variable.span.endOffset,
              ),
        for (final html in multilineHtml)
          _SourceInterval(html.opaqueStart, html.opaqueEnd),
      ]..sort((left, right) => left.start.compareTo(right.start));
      final opaqueSemanticBreaks = <int, int>{
        for (final entry in mapped.ranges.entries)
          if (_opaqueInlineKinds.contains(entry.key.kind))
            sourceBase + entry.value.start: '\n'
                .allMatches(entry.key.plainText)
                .length,
        for (final label in imageLabels)
          for (final entry in label.mapped.ranges.entries)
            if (entry.key.kind == BusyInlineKind.math ||
                entry.key.kind == BusyInlineKind.writersideVariable)
              label.sourceBase + entry.value.start: '\n'
                  .allMatches(entry.key.plainText)
                  .length,
      };
      final imageCodeSyntax = <_MappedImageCode>[
        for (final label in imageLabels) ...label.codes,
      ];
      final positionedLineBreaks = [
        for (final lineBreak in mapped.positionedLineBreaks)
          if (lineBreak.sourceOffset != null)
            BusyMarkMappedSourceLineBreak(
              textOffset: lineBreak.textOffset,
              lineEnding: lineBreak.lineEnding,
              continuationPrefix: lineBreak.continuationPrefix,
              sourceOffset: sourceBase + lineBreak.sourceOffset!,
            ),
      ];
      final hardBreakSyntax = <_SourceInterval>[
        for (final entry in mapped.ranges.entries)
          if (entry.key.kind == BusyInlineKind.hardBreak)
            _SourceInterval(
              sourceBase + entry.value.start,
              sourceBase + entry.value.end,
            ),
        for (final label in imageLabels)
          for (final entry in label.mapped.ranges.entries)
            if (entry.key.kind == BusyInlineKind.hardBreak &&
                !entry.value.isRawHtmlText)
              _SourceInterval(
                label.sourceBase + entry.value.start,
                label.sourceBase + entry.value.end,
              ),
      ];
      final scanner = _MarkdownProseScanner(
        source: source,
        start: mappedStart,
        end: mappedEnd,
        context: context,
        stripBlockSyntax: stripBlockSyntax,
        footnoteLabels: footnoteLabels,
        formattingSyntax: formattingSyntax,
        formattingWrappers: [
          ..._formattingWrappers([mapped], sourceBase: sourceBase),
          for (final label in imageLabels)
            ..._formattingWrappers([
              label.mapped,
            ], sourceBase: label.sourceBase),
        ],
        opaqueSyntax: opaqueSyntax,
        opaqueSemanticBreaks: opaqueSemanticBreaks,
        imageCodeSyntax: imageCodeSyntax,
        positionedLineBreaks: positionedLineBreaks,
        hardBreakSyntax: hardBreakSyntax,
        recognizedLinks: {
          for (final entry in mapped.ranges.entries)
            if (entry.key.kind == BusyInlineKind.link ||
                entry.key.kind == BusyInlineKind.image)
              if (entry.value.labelStart != null &&
                  entry.value.labelEnd != null)
                sourceBase + entry.value.start: _RecognizedLinkOccurrence(
                  isImage: entry.key.kind == BusyInlineKind.image,
                  semanticLabelText: entry.key.plainText,
                  end: sourceBase + entry.value.end,
                  labelStart: sourceBase + entry.value.labelStart!,
                  labelEnd: sourceBase + entry.value.labelEnd!,
                  titleStart: entry.value.titleStart == null
                      ? null
                      : sourceBase + entry.value.titleStart!,
                  titleEnd: entry.value.titleEnd == null
                      ? null
                      : sourceBase + entry.value.titleEnd!,
                  titleDelimiter: entry.value.titleDelimiter,
                ),
          for (final label in imageLabels)
            for (final entry in label.mapped.ranges.entries)
              if (entry.key.kind == BusyInlineKind.link ||
                  entry.key.kind == BusyInlineKind.image)
                if (entry.value.labelStart != null &&
                    entry.value.labelEnd != null)
                  label.sourceBase +
                      entry.value.start: _RecognizedLinkOccurrence(
                    isImage: entry.key.kind == BusyInlineKind.image,
                    semanticLabelText: entry.key.plainText,
                    end: label.sourceBase + entry.value.end,
                    labelStart: label.sourceBase + entry.value.labelStart!,
                    labelEnd: label.sourceBase + entry.value.labelEnd!,
                    titleStart: entry.value.titleStart == null
                        ? null
                        : label.sourceBase + entry.value.titleStart!,
                    titleEnd: entry.value.titleEnd == null
                        ? null
                        : label.sourceBase + entry.value.titleEnd!,
                    titleDelimiter: entry.value.titleDelimiter,
                  ),
        },
        recognizedAttributeSpans: recognizedAttributeSpans,
      );
      final groups =
          <_EmissionGroup>[
            ...scanner.scan(),
            for (final html in multilineHtml)
              if (html.tagStart >= mappedStart && html.tagStart < mappedEnd)
                for (final attribute in html.readableAttributes)
                  ..._MarkdownProseScanner(
                    source: source,
                    start: attribute.start,
                    end: attribute.end,
                    context: attribute.context,
                    stripBlockSyntax: false,
                    interpretHtmlSyntax: false,
                  ).scan(),
          ]..sort((left, right) {
            final leftStart = left.atoms.firstOrNull?.sourceStart ?? 0;
            final rightStart = right.atoms.firstOrNull?.sourceStart ?? 0;
            return leftStart.compareTo(rightStart);
          });
      complete = complete && scanner.complete;
      for (final group in groups) {
        if (group.text.trim().isEmpty) continue;
        final run = SpellingProseRun(
          id: 'markdown:${sequence++}:$mappedStart',
          text: group.text,
          languageId: languageId,
          atoms: List.unmodifiable(group.atoms),
          target: SpellingSourceTarget(filePath: filePath),
          snapshot: snapshot,
          formattingWrappers: group.formattingWrappers,
          complete: scanner.complete,
          tokenizationContext: group.tokenizationContext,
          tokenizationContextStart: group.tokenizationContextStart,
        );
        if (!run.hasValidMapping) {
          complete = false;
          continue;
        }
        runs.add(run);
      }
    }

    void addScanned(
      int start,
      int end, {
      required SpellingSourceContext context,
      bool stripBlockSyntax = true,
    }) {
      if (start < 0 || end > source.length || end <= start) {
        complete = false;
        return;
      }
      final slice = source.substring(start, end);
      final mapped = stripBlockSyntax
          ? inlineParser.parsePositionedBlocks(slice)
          : [inlineParser.parseMapped(slice)];
      if (stripBlockSyntax && mapped.isNotEmpty) {
        for (final semanticLeaf in mapped) {
          final leafStart = semanticLeaf.sourceStart;
          final leafEnd = semanticLeaf.sourceEnd;
          if (leafStart == null || leafEnd == null) {
            complete = false;
            continue;
          }
          if (leafEnd <= leafStart) continue;
          addMapped(
            start + leafStart,
            start + leafEnd,
            semanticLeaf,
            sourceBase: start,
            sourceLimit: end,
            stripBlockSyntax: true,
            context: context,
          );
        }
        return;
      }
      if (stripBlockSyntax && mapped.isEmpty) return;
      addMapped(
        start,
        end,
        mapped.single,
        sourceBase: start,
        sourceLimit: end,
        stripBlockSyntax: false,
        context: context,
      );
    }

    final consumedTables = <String>{};
    for (final chunk in chunks) {
      if (chunk.sourceOnly ||
          excludedBlockSpans.any((span) => _contains(span, chunk.span)) ||
          fencedCodeSpans.any(
            (span) =>
                span.start <= chunk.span.startOffset &&
                span.end >= chunk.span.endOffset,
          ) ||
          _startsExcludedBlock(chunk.rawSource)) {
        continue;
      }
      if (chunk.rawSource.trimLeft().startsWith(r'$$')) {
        final local = parser
            .parse(
              filePath: filePath,
              source: chunk.rawSource,
              mode: mode,
              validateLocalReferences: false,
            )
            .busyDocument
            .blocks;
        if (local.length == 1 && local.single.kind == BusyBlockKind.math) {
          continue;
        }
      }
      var table = tables.where((candidate) {
        final span = candidate.sourceSpan;
        return span != null && _sameSpan(span, chunk.span);
      }).firstOrNull;
      if (table == null &&
          tables.any((candidate) => candidate.sourceSpan == null) &&
          chunk.rawSource.contains('|')) {
        // A document-wide AST/scanner mismatch can omit spans from otherwise
        // ordinary tables. Reparse the already-positioned slice to establish
        // its structure; never match a table to source by its cell text.
        final local = parser
            .parse(
              filePath: filePath,
              source: chunk.rawSource,
              mode: mode,
              validateLocalReferences: false,
            )
            .busyDocument
            .blocks;
        if (local.length == 1 && local.single.kind == BusyBlockKind.table) {
          table = local.single.copyWith(sourceSpan: chunk.span);
        }
      }
      if (table != null) {
        if (!consumedTables.add(
          '${chunk.span.startOffset}:${chunk.span.endOffset}',
        )) {
          continue;
        }
        final regions = busyMarkMarkdownTableCellRegions(
          source: source,
          table: table,
        );
        if (regions.isEmpty && table.children.isNotEmpty) complete = false;
        for (final region in regions) {
          addScanned(
            region.span.startOffset,
            region.span.endOffset,
            context: SpellingSourceContext.markdownTableCell,
            stripBlockSyntax: false,
          );
        }
        continue;
      }
      addScanned(
        chunk.span.startOffset,
        chunk.span.endOffset,
        context: proseContext,
      );
    }
    return SpellingProjectionResult(
      runs: List.unmodifiable(runs),
      complete: complete,
      message: complete ? null : 'Some Markdown regions could not be mapped.',
      imageDescriptions: List.unmodifiable(
        imageDescriptions..sort(
          (left, right) => left.sourceStart.compareTo(right.sourceStart),
        ),
      ),
    );
  }
}

List<BusyInline> _imageFieldInlines(
  BusyMarkMappedInlineParse parsed,
  String raw,
) {
  BusyInline convert(BusyInline inline) {
    final range = parsed.ranges[inline];
    if (range?.isRawHtmlText ?? false) {
      return BusyInline(
        kind: BusyInlineKind.text,
        text: raw.substring(range!.start, range.end),
      );
    }
    if (inline.kind == BusyInlineKind.hardBreak) {
      return const BusyInline(kind: BusyInlineKind.text, text: '');
    }
    if (inline.kind == BusyInlineKind.code) return inline;
    if (inline.children.isEmpty) return inline;
    return inline.copyWith(
      children: [for (final child in inline.children) convert(child)],
    );
  }

  return List.unmodifiable([
    for (final inline in parsed.inlines) convert(inline),
  ]);
}

Iterable<BusyBlock> _walkBlocks(Iterable<BusyBlock> blocks) sync* {
  for (final block in blocks) {
    yield block;
    yield* _walkBlocks(block.children);
  }
}

bool _contains(SourceSpan outer, SourceSpan inner) =>
    outer.startOffset <= inner.startOffset &&
    outer.endOffset >= inner.endOffset;

bool _sameSpan(SourceSpan left, SourceSpan right) =>
    left.startOffset == right.startOffset && left.endOffset == right.endOffset;

bool _isRecognizedHeadingAttribute(
  String rawAttribute,
  Map<String, String> parsedAttributes,
) {
  // The heading parser records recognized values in the block attributes.
  // Tie that evidence to this exact trailing source expression: an attribute
  // elsewhere in the heading must not hide a later literal brace expression.
  for (final match in RegExp(
    r'([A-Za-z_:][-A-Za-z0-9_:.]*)\s*=\s*"([^"]*)"',
  ).allMatches(rawAttribute)) {
    final name = match.group(1)!;
    final value = html.parseFragment(match.group(2)!).text ?? '';
    if (name == 'id') {
      if (parsedAttributes['generatedId'] == 'false' &&
          parsedAttributes['id'] == value) {
        return true;
      }
    } else if (name != 'level' &&
        name != 'generatedId' &&
        parsedAttributes[name] == value) {
      return true;
    }
  }
  return false;
}

bool _startsExcludedBlock(String raw) {
  final trimmed = raw.trimLeft().replaceFirst(RegExp(r'^(?:>[ \t]*)+'), '');
  return RegExp(
    r'^(?:<!--|<\?xml\b|<!DOCTYPE\b)',
    caseSensitive: false,
  ).hasMatch(trimmed);
}

List<_SourceInterval> _fencedCodeSpans(String source, List<BusyBlock> blocks) {
  final spans = <_SourceInterval>[];
  MarkdownFence? openFence;
  var fenceStart = 0;
  var containerEnd = source.length;
  var activePrefixes = <({bool quote, int width})>[];
  final quotePrefix = RegExp(r'^ {0,3}>[ \t]?');
  final listPrefix = RegExp(r'^ {0,3}(?:[-+*]|\d+[.)])[ \t]+');

  String expandTabsForFenceScan(String line) {
    final expanded = StringBuffer();
    var column = 0;
    for (final unit in line.codeUnits) {
      if (unit == 0x09) {
        final spaces = 4 - column % 4;
        for (var index = 0; index < spaces; index++) {
          expanded.write(' ');
        }
        column += spaces;
      } else {
        expanded.writeCharCode(unit);
        column++;
      }
    }
    return expanded.toString();
  }

  String? consumePrefixes(
    String line,
    List<({bool quote, int width})> prefixes,
  ) {
    var remaining = line;
    for (var index = 0; index < prefixes.length; index++) {
      final prefix = prefixes[index];
      if (prefix.quote) {
        final match = quotePrefix.firstMatch(remaining);
        if (match == null) return null;
        remaining = remaining.substring(match.end);
      } else {
        if (remaining.length < prefix.width ||
            !RegExp(
              r'^[ \t]*$',
            ).hasMatch(remaining.substring(0, prefix.width))) {
          // A blank line may omit the list's content indentation. A quote
          // deeper in the container route still needs its own marker.
          if (remaining.trim().isEmpty &&
              !prefixes.skip(index + 1).any((next) => next.quote)) {
            return '';
          }
          return null;
        }
        remaining = remaining.substring(prefix.width);
      }
    }
    return remaining;
  }

  var offset = 0;
  for (final rawLine in source.split(RegExp('(?<=\n)'))) {
    if (openFence != null && offset >= containerEnd) {
      spans.add(_SourceInterval(fenceStart, containerEnd));
      openFence = null;
    }
    var line = rawLine;
    if (line.endsWith('\n')) line = line.substring(0, line.length - 1);
    if (line.endsWith('\r')) line = line.substring(0, line.length - 1);
    // Expand only for fence classification; interval offsets remain in source.
    final candidateLine = expandTabsForFenceScan(line);
    final activeFence = openFence;
    if (activeFence != null) {
      final content = consumePrefixes(candidateLine, activePrefixes);
      if (content == null) {
        spans.add(_SourceInterval(fenceStart, offset));
        openFence = null;
      } else if (activeFence.closes(content)) {
        spans.add(
          _SourceInterval(
            fenceStart,
            math.min(containerEnd, offset + rawLine.length),
          ),
        );
        openFence = null;
        offset += rawLine.length;
        continue;
      } else {
        offset += rawLine.length;
        continue;
      }
    }
    if (openFence == null) {
      var openingCandidate = candidateLine;
      final openingPrefixes = <({bool quote, int width})>[];
      while (true) {
        final quote = quotePrefix.firstMatch(openingCandidate);
        if (quote != null) {
          openingPrefixes.add((quote: true, width: quote.end));
          openingCandidate = openingCandidate.substring(quote.end);
          continue;
        }
        final list = listPrefix.firstMatch(openingCandidate);
        if (list != null) {
          openingPrefixes.add((quote: false, width: list.end));
          openingCandidate = openingCandidate.substring(list.end);
          continue;
        }
        break;
      }
      final opening = MarkdownFence.parse(openingCandidate);
      if (opening != null) {
        openFence = opening;
        fenceStart = offset;
        activePrefixes = openingPrefixes;
        containerEnd = source.length;
        for (final block in _walkBlocks(blocks)) {
          final span = block.sourceSpan;
          if (span != null &&
              (block.kind == BusyBlockKind.blockquote ||
                  block.kind == BusyBlockKind.unorderedListItem ||
                  block.kind == BusyBlockKind.orderedListItem) &&
              span.startOffset <= offset &&
              span.endOffset > offset &&
              span.endOffset < containerEnd) {
            containerEnd = span.endOffset;
          }
        }
      }
    }
    offset += rawLine.length;
  }
  if (openFence != null) spans.add(_SourceInterval(fenceStart, containerEnd));
  return List.unmodifiable(spans);
}

_ParsedImageLabel _parseMappedImageLabel(
  BusyMarkInlineParserContext parser,
  String raw, {
  required int sourceBase,
  required List<BusyMarkMappedSourceLineBreak> positionedBreaks,
}) {
  // The positioned block parse identifies exactly which continuation bytes
  // were structural. Keep separate start and end coordinates so a range that
  // ends at a newline does not acquire the following container prefix.
  final breakByOffset = {
    for (final lineBreak in positionedBreaks)
      if (lineBreak.sourceOffset case final offset?) offset: lineBreak,
  };
  final logical = StringBuffer();
  final rawStarts = <int>[];
  final rawEnds = <int>[];
  final inheritedBreaks = <BusyMarkMappedSourceLineBreak>[];
  var positionsComplete = true;
  var cursor = 0;
  while (cursor < raw.length) {
    final lineBreak = breakByOffset[cursor];
    if (lineBreak != null) {
      final syntax = '${lineBreak.lineEnding}${lineBreak.continuationPrefix}';
      if (!raw.startsWith(syntax, cursor)) {
        positionsComplete = false;
      } else {
        inheritedBreaks.add(
          BusyMarkMappedSourceLineBreak(
            textOffset: rawStarts.length,
            lineEnding: lineBreak.lineEnding,
            continuationPrefix: lineBreak.continuationPrefix,
            sourceOffset: cursor,
          ),
        );
        rawStarts.add(cursor);
        rawEnds.add(cursor + lineBreak.lineEnding.length);
        logical.write('\n');
        cursor += syntax.length;
        continue;
      }
    }
    final lineEnding = raw.startsWith('\r\n', cursor)
        ? '\r\n'
        : raw.codeUnitAt(cursor) == 0x0d
        ? '\r'
        : raw.codeUnitAt(cursor) == 0x0a
        ? '\n'
        : null;
    rawStarts.add(cursor);
    if (lineEnding == null) {
      logical.writeCharCode(raw.codeUnitAt(cursor));
      cursor++;
    } else {
      logical.write('\n');
      cursor += lineEnding.length;
    }
    rawEnds.add(cursor);
  }
  final logicalSource = logical.toString();
  final mapped = parser.parseMapped(logicalSource);
  int rawStartFor(int offset) =>
      offset < rawStarts.length ? rawStarts[offset] : raw.length;
  int rawEndFor(int offset) => offset == 0 ? 0 : rawEnds[offset - 1];

  BusyMarkMappedSourceLineBreak translateBreak(
    BusyMarkMappedSourceLineBreak value,
  ) {
    final offset = value.sourceOffset;
    final rawOffset = offset == null ? null : rawStartFor(offset);
    final inherited = inheritedBreaks
        .where((breakValue) => breakValue.sourceOffset == rawOffset)
        .firstOrNull;
    return BusyMarkMappedSourceLineBreak(
      textOffset: value.textOffset,
      lineEnding:
          inherited?.lineEnding ??
          (offset == null
              ? value.lineEnding
              : raw.substring(rawStartFor(offset), rawEndFor(offset + 1))),
      continuationPrefix:
          inherited?.continuationPrefix ?? value.continuationPrefix,
      sourceOffset: rawOffset,
    );
  }

  final ranges = Map<BusyInline, BusyMarkMappedInlineRange>.identity();
  final codes = <_MappedImageCode>[];
  for (final entry in mapped.ranges.entries) {
    final range = entry.value;
    ranges[entry.key] = BusyMarkMappedInlineRange(
      start: rawStartFor(range.start),
      end: rawEndFor(range.end),
      opening: range.opening,
      closing: range.closing,
      labelStart: range.labelStart == null
          ? null
          : rawStartFor(range.labelStart!),
      labelEnd: range.labelEnd == null ? null : rawStartFor(range.labelEnd!),
      titleStart: range.titleStart == null
          ? null
          : rawStartFor(range.titleStart!),
      titleEnd: range.titleEnd == null ? null : rawStartFor(range.titleEnd!),
      titleDelimiter: range.titleDelimiter,
      lineBreaks: range.lineBreaks.map(translateBreak).toList(),
      originalInline: range.originalInline,
      isAutolink: range.isAutolink,
      isReference: range.isReference,
      isSourceLineBreak: range.isSourceLineBreak,
      isRawHtmlText: range.isRawHtmlText,
      sourceLineBreakOffset: range.sourceLineBreakOffset == null
          ? null
          : rawStartFor(range.sourceLineBreakOffset!),
    );
    if (entry.key.kind != BusyInlineKind.code || range.isRawHtmlText) continue;
    final units = <({String text, int start, int end, bool lineBreak})>[
      for (var offset = range.start; offset < range.end; offset++)
        (
          text: logicalSource.substring(offset, offset + 1),
          start: sourceBase + rawStartFor(offset),
          end:
              sourceBase +
              (logicalSource.codeUnitAt(offset) == 0x0a
                  ? rawStartFor(offset + 1)
                  : rawEndFor(offset + 1)),
          lineBreak: logicalSource.codeUnitAt(offset) == 0x0a,
        ),
    ];
    codes.add(
      _MappedImageCode(
        start: sourceBase + rawStartFor(range.start),
        end: sourceBase + rawEndFor(range.end),
        semanticText: entry.key.plainText,
        units: units,
      ),
    );
  }
  return _ParsedImageLabel(
    mapped: BusyMarkMappedInlineParse(
      inlines: mapped.inlines,
      ranges: ranges,
      positionedLineBreaks: inheritedBreaks,
      positionRecordsComplete:
          mapped.positionRecordsComplete && positionsComplete,
      imageDescriptionText: mapped.imageDescriptionText,
      sourceStart: mapped.sourceStart == null
          ? null
          : rawStartFor(mapped.sourceStart!),
      sourceEnd: mapped.sourceEnd == null ? null : rawEndFor(mapped.sourceEnd!),
    ),
    codes: codes,
  );
}

final class _ParsedImageLabel {
  const _ParsedImageLabel({required this.mapped, required this.codes});

  final BusyMarkMappedInlineParse mapped;
  final List<_MappedImageCode> codes;
}

final class _EmissionGroup {
  const _EmissionGroup({
    required this.text,
    required this.atoms,
    required this.formattingWrappers,
    required this.tokenizationContext,
    required this.tokenizationContextStart,
  });
  final String text;
  final List<SpellingSourceAtom> atoms;
  final List<SpellingFormattingWrapper> formattingWrappers;
  final String tokenizationContext;
  final int tokenizationContextStart;
}

final class _PendingEmissionGroup {
  const _PendingEmissionGroup({
    required this.text,
    required this.atoms,
    required this.formattingWrappers,
    required this.tokenizationContextStart,
  });

  final String text;
  final List<SpellingSourceAtom> atoms;
  final List<SpellingFormattingWrapper> formattingWrappers;
  final int tokenizationContextStart;
}

final class _RecognizedLinkOccurrence {
  const _RecognizedLinkOccurrence({
    required this.isImage,
    required this.semanticLabelText,
    required this.end,
    required this.labelStart,
    required this.labelEnd,
    required this.titleStart,
    required this.titleEnd,
    required this.titleDelimiter,
  });

  final bool isImage;
  final String semanticLabelText;
  final int end;
  final int labelStart;
  final int labelEnd;
  final int? titleStart;
  final int? titleEnd;
  final String? titleDelimiter;
}

final class _MappedImageCode {
  const _MappedImageCode({
    required this.start,
    required this.end,
    required this.semanticText,
    required this.units,
  });

  final int start;
  final int end;
  final String semanticText;
  final List<({String text, int start, int end, bool lineBreak})> units;
}

final class _MarkdownProseScanner {
  _MarkdownProseScanner({
    required this.source,
    required this.start,
    required this.end,
    required this.context,
    required this.stripBlockSyntax,
    this.interpretHtmlSyntax = true,
    this.formattingSyntax = const [],
    this.formattingWrappers = const [],
    this.opaqueSyntax = const [],
    this.opaqueSemanticBreaks = const {},
    this.imageCodeSyntax = const [],
    this.positionedLineBreaks = const [],
    this.hardBreakSyntax = const [],
    this.recognizedLinks = const {},
    this.recognizedAttributeSpans = const [],
    this.footnoteLabels = const {},
  });

  final String source;
  final int start;
  final int end;
  final SpellingSourceContext context;
  final bool stripBlockSyntax;
  final bool interpretHtmlSyntax;
  final Set<String> footnoteLabels;
  final List<_SourceInterval> formattingSyntax;
  final List<_RawFormattingWrapper> formattingWrappers;
  final List<_SourceInterval> opaqueSyntax;
  final Map<int, int> opaqueSemanticBreaks;
  final List<_MappedImageCode> imageCodeSyntax;
  final List<BusyMarkMappedSourceLineBreak> positionedLineBreaks;
  final List<_SourceInterval> hardBreakSyntax;
  final Map<int, _RecognizedLinkOccurrence> recognizedLinks;
  final List<_SourceInterval> recognizedAttributeSpans;
  final List<Object> _groups = [];
  StringBuffer _text = StringBuffer();
  final StringBuffer _tokenizationContext = StringBuffer();
  List<SpellingSourceAtom> _atoms = [];
  int? _tokenizationContextStart;
  int? _opaqueEnd;
  int? _consumedLinkEnd;
  bool _inImageLabel = false;
  bool complete = true;

  List<_EmissionGroup> scan() {
    final lines = _lines();
    for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final line = lines[lineIndex];
      var contentStart = line.start;
      var contentEnd = line.contentEnd;
      // Positioned leaves already start after their first block prefix. Do
      // not reinterpret heading text such as "2. Paragraphs" as a list item.
      // Continuation lines still carry their authored container prefixes.
      if (stripBlockSyntax &&
          (lineIndex > 0 ||
              start == 0 ||
              source.codeUnitAt(start - 1) == 0x0a)) {
        final rawLine = source.substring(contentStart, contentEnd);
        if (_isSetextOrThematic(rawLine)) {
          _barrier();
          continue;
        }
        final prefix = _blockPrefix.firstMatch(rawLine);
        contentStart += prefix?.end ?? 0;
        var isAtxHeading = false;
        if (source.startsWith('#', contentStart)) {
          final heading = RegExp(
            r'^#{1,6}[ \t]+',
          ).firstMatch(source.substring(contentStart, contentEnd));
          contentStart += heading?.end ?? 0;
          isAtxHeading = heading != null;
        }
        while (contentEnd > contentStart &&
            _horizontalWhitespace(source.codeUnitAt(contentEnd - 1))) {
          contentEnd--;
        }
        final closingHeading = RegExp(
          r'[ \t]+#+$',
        ).firstMatch(source.substring(contentStart, contentEnd));
        if (isAtxHeading && closingHeading != null) {
          contentEnd = contentStart + closingHeading.start;
        }
      }
      for (final attributes in recognizedAttributeSpans) {
        if (attributes.end == contentEnd && attributes.start >= contentStart) {
          contentEnd = attributes.start;
          break;
        }
      }
      if (contentEnd > contentStart) _scanInline(contentStart, contentEnd);
      if (lineIndex + 1 < lines.length &&
          _text.length > 0 &&
          !(_consumedLinkEnd != null &&
              lines[lineIndex + 1].start < _consumedLinkEnd!)) {
        final next = lines[lineIndex + 1];
        _emit(
          ' ',
          line.contentEnd,
          next.start,
          SpellingTransformationKind.lineBreak,
          tokenizationLogical: '\n',
        );
      }
    }
    _flush();
    final tokenizationContext = _tokenizationContext.toString();
    return List.unmodifiable([
      for (final group in _groups)
        if (group is _PendingEmissionGroup)
          _EmissionGroup(
            text: group.text,
            atoms: group.atoms,
            formattingWrappers: group.formattingWrappers,
            tokenizationContext: tokenizationContext,
            tokenizationContextStart: group.tokenizationContextStart,
          )
        else
          group as _EmissionGroup,
    ]);
  }

  void _scanInline(int rangeStart, int rangeEnd) {
    var cursor = rangeStart;
    while (cursor < rangeEnd) {
      if (_consumedLinkEnd case final linkEnd? when cursor < linkEnd) {
        cursor = math.min(rangeEnd, linkEnd);
        continue;
      }
      if (_opaqueEnd case final opaqueEnd? when cursor < opaqueEnd) {
        _barrier();
        cursor = math.min(rangeEnd, opaqueEnd);
        if (cursor >= opaqueEnd) _opaqueEnd = null;
        continue;
      }
      final imageCode = _imageCodeAt(cursor);
      if (imageCode != null && imageCode.end <= rangeEnd) {
        _scanImageCode(imageCode);
        cursor = imageCode.end;
        continue;
      }
      final formattingEnd = _formattingEndAt(cursor);
      if (formattingEnd != null) {
        cursor = formattingEnd;
        continue;
      }
      final opaqueEnd = _opaqueEndAt(cursor);
      if (opaqueEnd != null) {
        _barrier();
        cursor = math.min(rangeEnd, opaqueEnd);
        continue;
      }
      if (interpretHtmlSyntax &&
          !_inImageLabel &&
          source.startsWith('<!--', cursor)) {
        final close = source.indexOf('-->', cursor + 4);
        _barrier();
        _opaqueEnd = close < 0 || close >= end ? end : close + 3;
        if (close < 0 || close >= end) complete = false;
        continue;
      }
      var address = spellingPlainAddress.matchAsPrefix(source, cursor);
      // A link label's boundary can fall inside a greedy URL match (the next
      // character is its closing bracket). Recheck only that bounded label.
      var addressEnd = address?.end;
      if (address != null && address.end > rangeEnd) {
        address = spellingPlainAddress.matchAsPrefix(
          source.substring(cursor, rangeEnd),
        );
        addressEnd = address == null ? null : cursor + address.end;
      }
      if (address != null) {
        _barrier();
        cursor = addressEnd!;
        continue;
      }
      final unit = source.codeUnitAt(cursor);
      if (unit == 0x5c &&
          cursor + 1 < rangeEnd &&
          _commonMarkEscapableAsciiPunctuation(source.codeUnitAt(cursor + 1))) {
        final escaped = source.substring(cursor + 1, cursor + 2);
        _emit(
          escaped,
          cursor,
          cursor + 2,
          SpellingTransformationKind.markdownEscape,
        );
        cursor += 2;
        continue;
      }
      if (unit == 0x26) {
        final entity = _entity.matchAsPrefix(source, cursor);
        if (entity != null && entity.end <= rangeEnd) {
          final raw = entity.group(0)!;
          final decoded = html.parseFragment(raw).text ?? '';
          if (decoded != raw && decoded.isNotEmpty) {
            _emit(
              decoded,
              cursor,
              entity.end,
              SpellingTransformationKind.entity,
            );
            cursor = entity.end;
            continue;
          }
        }
      }
      if (unit == 0x21 &&
          cursor + 1 < rangeEnd &&
          source.codeUnitAt(cursor + 1) == 0x5b) {
        final imageEnd = _scanLinkOrImage(cursor, rangeEnd, image: true);
        if (imageEnd != null) {
          cursor = imageEnd;
          continue;
        }
      }
      if (unit == 0x5b) {
        final linkEnd = _scanLinkOrImage(cursor, rangeEnd, image: false);
        if (linkEnd != null) {
          cursor = linkEnd;
          continue;
        }
      }
      if (interpretHtmlSyntax && !_inImageLabel && unit == 0x3c) {
        final tagCandidate = _isHtmlTagCandidate(cursor);
        final autolinkCandidate = _isAutolinkCandidate(cursor);
        if (tagCandidate || autolinkCandidate) {
          final close = _htmlTagEnd(cursor);
          if (close < 0) {
            if (tagCandidate) complete = false;
          } else {
            final raw = source.substring(cursor, close + 1);
            if (_autolink.hasMatch(raw) || _emailAutolink.hasMatch(raw)) {
              _barrier();
              if (close >= rangeEnd) _opaqueEnd = close + 1;
              cursor = math.min(rangeEnd, close + 1);
              continue;
            }
            final parsedTag = RegExp(
              r'^<\s*(/?)\s*([A-Za-z][A-Za-z0-9:-]*)\b',
            ).firstMatch(raw);
            final closingTag = parsedTag?.group(1)?.isNotEmpty ?? false;
            final tag = parsedTag?.group(2)?.toLowerCase();
            if (!closingTag &&
                tag != null &&
                _opaqueHtmlElements.contains(tag) &&
                !raw.trimRight().endsWith('/>')) {
              final closing = RegExp(
                '</\\s*${RegExp.escape(tag)}\\s*>',
                caseSensitive: false,
              ).firstMatch(source.substring(close + 1, end));
              _barrier();
              if (closing == null) {
                complete = false;
                _opaqueEnd = end;
              } else {
                _opaqueEnd = close + 1 + closing.end;
              }
              continue;
            }
            final semanticBoundary =
                tag == 'br' ||
                tag == 'hr' ||
                tag != null && _blockHtmlElements.contains(tag);
            if (semanticBoundary) _barrier();
            if (!closingTag) _scanHumanReadableAttributes(cursor, close + 1);
            if (semanticBoundary) _barrier();
            if (close >= rangeEnd) _opaqueEnd = close + 1;
            cursor = math.min(rangeEnd, close + 1);
            continue;
          }
        }
      }
      final rune = _codePointAt(source, cursor);
      final width = rune > 0xffff ? 2 : 1;
      _emit(
        source.substring(cursor, cursor + width),
        cursor,
        cursor + width,
        SpellingTransformationKind.identity,
      );
      cursor += width;
    }
  }

  _MappedImageCode? _imageCodeAt(int offset) {
    for (final code in imageCodeSyntax) {
      if (code.start == offset) return code;
    }
    return null;
  }

  void _scanImageCode(_MappedImageCode code) {
    var contentStart = code.start;
    while (contentStart < code.end && source.codeUnitAt(contentStart) == 0x60) {
      contentStart++;
    }
    final markerLength = contentStart - code.start;
    final contentEnd = code.end - markerLength;
    if (markerLength == 0 ||
        contentEnd < contentStart ||
        source.substring(contentEnd, code.end) !=
            source.substring(code.start, contentStart)) {
      complete = false;
      return;
    }

    final units = code.units;
    var first = markerLength;
    var last = units.length - markerLength;
    if (last <= first ||
        first >= units.length ||
        units.first.start != code.start ||
        units.last.end != code.end ||
        units[first].start != contentStart ||
        units[last - 1].end != contentEnd) {
      complete = false;
      return;
    }
    String logical() => units
        .skip(first)
        .take(last - first)
        .map((unit) => unit.lineBreak ? ' ' : unit.text)
        .join();
    if (logical() != code.semanticText &&
        last - first >= 2 &&
        (units[first].lineBreak || units[first].text == ' ') &&
        (units[last - 1].lineBreak || units[last - 1].text == ' ')) {
      first++;
      last--;
    }
    if (logical() != code.semanticText) {
      complete = false;
      return;
    }

    var textStart = -1;
    var textEnd = -1;
    final text = StringBuffer();
    void flushText() {
      if (text.isEmpty) return;
      _emit(
        text.toString(),
        textStart,
        textEnd,
        SpellingTransformationKind.identity,
        sourceContext: SpellingSourceContext.markdownCodeSpan,
      );
      text.clear();
    }

    for (var index = first; index < last; index++) {
      final unit = units[index];
      if (unit.lineBreak) {
        flushText();
        _emit(
          ' ',
          unit.start,
          unit.end,
          SpellingTransformationKind.lineBreak,
          tokenizationLogical: ' ',
          sourceContext: SpellingSourceContext.markdownCodeSpan,
        );
      } else {
        if (text.isEmpty) textStart = unit.start;
        textEnd = unit.end;
        text.write(unit.text);
      }
    }
    flushText();
  }

  bool _isHtmlTagCandidate(int start) {
    if (start + 1 >= end) return false;
    final tail = source.substring(start, math.min(end, start + 128));
    return RegExp(r'^</?[A-Za-z][A-Za-z0-9:-]*(?:\s|/?>|$)').hasMatch(tail) ||
        RegExp(r'^<(?:!|\?)').hasMatch(tail);
  }

  bool _isAutolinkCandidate(int start) {
    if (start + 1 >= end) return false;
    final tail = source.substring(start, math.min(end, start + 256));
    return RegExp(r'^<[A-Za-z][A-Za-z0-9+.-]*:').hasMatch(tail) ||
        RegExp(r'^<[^\s<>@]+@').hasMatch(tail);
  }

  int _htmlTagEnd(int start) {
    int? quote;
    for (var cursor = start + 1; cursor < end; cursor++) {
      final unit = source.codeUnitAt(cursor);
      if (quote != null) {
        if (unit == quote) quote = null;
      } else if (unit == 0x22 || unit == 0x27) {
        quote = unit;
      } else if (unit == 0x3e) {
        return cursor;
      }
    }
    return -1;
  }

  int? _scanLinkOrImage(int cursor, int rangeEnd, {required bool image}) {
    final recognized = recognizedLinks[cursor];
    final opening = cursor + (image ? 1 : 0);
    if (recognized == null) {
      final labelEnd = _matchingBracket(opening, rangeEnd, 0x5b, 0x5d);
      if (labelEnd != null && !image) {
        final label = source.substring(opening + 1, labelEnd);
        if (label.startsWith('^') &&
            footnoteLabels.contains(label.substring(1).toLowerCase())) {
          _barrier();
          return labelEnd + 1;
        }
      }
      return null;
    }
    if (recognized.end > end ||
        recognized.labelStart < opening + 1 ||
        recognized.labelEnd < recognized.labelStart ||
        recognized.labelEnd > recognized.end) {
      complete = false;
      return null;
    }
    if (image) _barrier();
    final wasInImageLabel = _inImageLabel;
    _inImageLabel = _inImageLabel || image;
    try {
      _scanMappedLabel(recognized);
    } finally {
      _inImageLabel = wasInImageLabel;
    }
    if (image) _barrier();
    final titleStart = recognized.titleStart;
    final titleEnd = recognized.titleEnd;
    if (titleStart != null && titleEnd != null && titleEnd > titleStart) {
      final titleContext = switch (recognized.titleDelimiter) {
        "'" => SpellingSourceContext.markdownSingleQuotedTitle,
        '(' => SpellingSourceContext.markdownParenthesizedTitle,
        _ => SpellingSourceContext.markdownDoubleQuotedTitle,
      };
      final scanner = _MarkdownProseScanner(
        source: source,
        start: titleStart,
        end: titleEnd,
        context: titleContext,
        stripBlockSyntax: false,
        interpretHtmlSyntax: false,
      );
      _groups.addAll(scanner.scan());
      complete = complete && scanner.complete;
    }
    _consumedLinkEnd = recognized.end;
    return recognized.end;
  }

  void _scanMappedLabel(_RecognizedLinkOccurrence recognized) {
    final labelStart = recognized.labelStart;
    final labelEnd = recognized.labelEnd;
    var cursor = labelStart;
    var semanticCursor = 0;
    final breaks = positionedLineBreaks.where((lineBreak) {
      final offset = lineBreak.sourceOffset;
      return offset != null && offset >= labelStart && offset < labelEnd;
    }).toList()..sort((a, b) => a.sourceOffset!.compareTo(b.sourceOffset!));
    var breakIndex = 0;
    while (cursor < labelEnd) {
      // Mapped children own their internal line boundaries. Traverse them
      // before interpreting the next physical boundary as label prose.
      while (breakIndex < breaks.length &&
          breaks[breakIndex].sourceOffset! < cursor) {
        breakIndex++;
      }
      final nextBreak = breakIndex < breaks.length
          ? breaks[breakIndex].sourceOffset
          : null;
      ({
        int start,
        int end,
        int semanticBreaks,
        bool? image,
        _MappedImageCode? imageCode,
        bool inlineBreak,
      })?
      owner;
      for (final span in opaqueSyntax) {
        if (span.start < cursor ||
            span.end > labelEnd ||
            span.start >= labelEnd ||
            (nextBreak != null && span.start > nextBreak)) {
          continue;
        }
        if (owner == null || span.start < owner.start) {
          owner = (
            start: span.start,
            end: span.end,
            semanticBreaks: opaqueSemanticBreaks[span.start] ?? 0,
            image: null,
            imageCode: null,
            inlineBreak: false,
          );
        }
      }
      for (final code in imageCodeSyntax) {
        if (code.start < cursor ||
            code.end > labelEnd ||
            (nextBreak != null && code.start > nextBreak)) {
          continue;
        }
        if (owner == null || code.start < owner.start) {
          owner = (
            start: code.start,
            end: code.end,
            semanticBreaks: 0,
            image: null,
            imageCode: code,
            inlineBreak: false,
          );
        }
      }
      for (final span in hardBreakSyntax) {
        if (span.start < cursor ||
            span.end > labelEnd ||
            (nextBreak != null && span.start > nextBreak) ||
            RegExp(r'\r|\n').hasMatch(source.substring(span.start, span.end))) {
          continue;
        }
        if (owner == null || span.start < owner.start) {
          owner = (
            start: span.start,
            end: span.end,
            semanticBreaks: 1,
            image: null,
            imageCode: null,
            inlineBreak: true,
          );
        }
      }
      for (final entry in recognizedLinks.entries) {
        final nested = entry.value;
        if (entry.key < cursor ||
            nested.end > labelEnd ||
            entry.key >= labelEnd ||
            (nextBreak != null && entry.key > nextBreak)) {
          continue;
        }
        if (owner == null || entry.key < owner.start) {
          owner = (
            start: entry.key,
            end: nested.end,
            semanticBreaks: '\n'.allMatches(nested.semanticLabelText).length,
            image: nested.isImage,
            imageCode: null,
            inlineBreak: false,
          );
        }
      }
      if (owner != null) {
        if (cursor < owner.start) _scanInline(cursor, owner.start);
        if (owner.imageCode case final code?) {
          _scanImageCode(code);
        } else if (owner.inlineBreak) {
          _emit(
            ' ',
            owner.start,
            owner.end,
            SpellingTransformationKind.lineBreak,
            tokenizationLogical: '\n',
          );
        } else if (owner.image case final image?) {
          if (_scanLinkOrImage(owner.start, owner.end, image: image) !=
              owner.end) {
            complete = false;
            return;
          }
        } else {
          _scanInline(owner.start, owner.end);
        }
        for (var index = 0; index < owner.semanticBreaks; index++) {
          final semanticBreak = recognized.semanticLabelText.indexOf(
            '\n',
            semanticCursor,
          );
          if (semanticBreak < 0) {
            complete = false;
            return;
          }
          semanticCursor = semanticBreak + 1;
        }
        cursor = owner.end;
        continue;
      }
      if (breakIndex >= breaks.length) {
        // Unmapped raw line boundaries must not silently enter logical prose.
        if (RegExp(r'\r|\n').hasMatch(source.substring(cursor, labelEnd))) {
          complete = false;
          return;
        }
        _scanInline(cursor, labelEnd);
        cursor = labelEnd;
        break;
      }
      final lineBreak = breaks[breakIndex++];
      final breakStart = lineBreak.sourceOffset!;
      final nextStart =
          breakStart +
          lineBreak.lineEnding.length +
          lineBreak.continuationPrefix.length;
      _SourceInterval? hardBreak;
      for (final span in hardBreakSyntax) {
        if (span.start >= cursor &&
            span.start <= breakStart &&
            span.end >= breakStart + lineBreak.lineEnding.length) {
          hardBreak = span;
          break;
        }
      }
      if (nextStart > labelEnd || breakStart < cursor) {
        complete = false;
        return;
      }
      final semanticBreak = recognized.isImage && hardBreak != null
          ? -1
          : recognized.semanticLabelText.indexOf('\n', semanticCursor);
      if (semanticBreak < 0 && (!recognized.isImage || hardBreak == null)) {
        complete = false;
        return;
      }
      var contentEnd = hardBreak?.start ?? breakStart;
      if (hardBreak == null) {
        // The parser can omit whitespace immediately before a soft break.
        // Retain exactly the authored suffix that remains in its label text.
        var rawWhitespaceStart = contentEnd;
        while (rawWhitespaceStart > cursor &&
            (source.codeUnitAt(rawWhitespaceStart - 1) == 0x20 ||
                source.codeUnitAt(rawWhitespaceStart - 1) == 0x09)) {
          rawWhitespaceStart--;
        }
        var semanticWhitespaceStart = semanticBreak;
        while (semanticWhitespaceStart > semanticCursor &&
            (recognized.semanticLabelText.codeUnitAt(
                      semanticWhitespaceStart - 1,
                    ) ==
                    0x20 ||
                recognized.semanticLabelText.codeUnitAt(
                      semanticWhitespaceStart - 1,
                    ) ==
                    0x09)) {
          semanticWhitespaceStart--;
        }
        final rawCount = contentEnd - rawWhitespaceStart;
        final semanticCount = semanticBreak - semanticWhitespaceStart;
        contentEnd -= math.max(0, rawCount - semanticCount);
      }
      if (cursor < contentEnd) _scanInline(cursor, contentEnd);
      if (!recognized.isImage || hardBreak == null) {
        _emit(
          ' ',
          contentEnd,
          nextStart,
          SpellingTransformationKind.lineBreak,
          tokenizationLogical: '\n',
        );
      }
      if (semanticBreak >= 0) semanticCursor = semanticBreak + 1;
      cursor = nextStart;
    }
    if (recognized.semanticLabelText.indexOf('\n', semanticCursor) >= 0) {
      complete = false;
    }
  }

  void _scanHumanReadableAttributes(int tagStart, int tagEnd) {
    final raw = source.substring(tagStart, tagEnd);
    for (final match in _humanAttribute.allMatches(raw)) {
      final name = match.group(1)!.toLowerCase();
      if (!_humanAttributeNames.contains(name)) continue;
      final quote = match.group(2)!;
      final value = match.group(3)!;
      // The capture ends with the closing quote, so this is the exact quoted
      // value boundary even when [value] also occurs in the attribute name or
      // in an earlier attribute.
      final valueStart = tagStart + match.end - 1 - value.length;
      final savedContext = quote == "'"
          ? SpellingSourceContext.xmlSingleQuotedAttribute
          : SpellingSourceContext.xmlDoubleQuotedAttribute;
      final scanner = _MarkdownProseScanner(
        source: source,
        start: valueStart,
        end: valueStart + value.length,
        context: savedContext,
        stripBlockSyntax: false,
        interpretHtmlSyntax: false,
      );
      _groups.addAll(scanner.scan());
      complete = complete && scanner.complete;
    }
  }

  void _emit(
    String logical,
    int sourceStart,
    int sourceEnd,
    SpellingTransformationKind transformation, {
    String? tokenizationLogical,
    SpellingSourceContext? sourceContext,
  }) {
    if (logical.isEmpty) return;
    _tokenizationContextStart ??= _tokenizationContext.length;
    final logicalStart = _text.length;
    _text.write(logical);
    _tokenizationContext.write(tokenizationLogical ?? logical);
    _atoms.add(
      SpellingSourceAtom(
        logicalText: logical,
        logicalStart: logicalStart,
        logicalEnd: _text.length,
        sourceStart: sourceStart,
        sourceEnd: sourceEnd,
        transformation: transformation,
        context: sourceContext ?? context,
      ),
    );
  }

  void _barrier() {
    _flush();
    if (_tokenizationContext.isNotEmpty &&
        !_tokenizationContext.toString().endsWith(' ')) {
      _tokenizationContext.write(' ');
    }
  }

  void _flush() {
    if (_text.isNotEmpty) {
      final wrappers = <SpellingFormattingWrapper>[];
      for (final wrapper in formattingWrappers) {
        final contained = _atoms
            .where(
              (atom) =>
                  atom.sourceStart >= wrapper.contentStart &&
                  atom.sourceEnd <= wrapper.contentEnd,
            )
            .toList(growable: false);
        if (contained.isEmpty) continue;
        wrappers.add(
          SpellingFormattingWrapper(
            logicalStart: contained.first.logicalStart,
            logicalEnd: contained.last.logicalEnd,
            openingStart: wrapper.opening.start,
            openingEnd: wrapper.opening.end,
            closingStart: wrapper.closing.start,
            closingEnd: wrapper.closing.end,
            structuralKind: wrapper.kind,
            removableWhenLogicallyEmpty:
                !opaqueSyntax.any(
                  (opaque) =>
                      opaque.start < wrapper.contentEnd &&
                      opaque.end > wrapper.contentStart,
                ) &&
                _coversSourceRange(wrapper.contentStart, wrapper.contentEnd, [
                  for (final atom in contained)
                    _SourceInterval(atom.sourceStart, atom.sourceEnd),
                  for (final syntax in formattingSyntax)
                    if (syntax.start < wrapper.contentEnd &&
                        syntax.end > wrapper.contentStart)
                      syntax,
                ]),
          ),
        );
      }
      _groups.add(
        _PendingEmissionGroup(
          text: _text.toString(),
          atoms: _atoms,
          formattingWrappers: List.unmodifiable(wrappers),
          tokenizationContextStart: _tokenizationContextStart!,
        ),
      );
    }
    _text = StringBuffer();
    _atoms = [];
    _tokenizationContextStart = null;
  }

  List<({int start, int contentEnd})> _lines({int? from, int? until}) {
    final result = <({int start, int contentEnd})>[];
    var cursor = from ?? start;
    final rangeEnd = until ?? end;
    while (cursor < rangeEnd) {
      var contentEnd = cursor;
      while (contentEnd < rangeEnd &&
          source.codeUnitAt(contentEnd) != 0x0a &&
          source.codeUnitAt(contentEnd) != 0x0d) {
        contentEnd++;
      }
      result.add((start: cursor, contentEnd: contentEnd));
      if (contentEnd >= rangeEnd) break;
      cursor = contentEnd + 1;
      if (source.codeUnitAt(contentEnd) == 0x0d &&
          cursor < rangeEnd &&
          source.codeUnitAt(cursor) == 0x0a) {
        cursor++;
      }
    }
    return result;
  }

  int? _formattingEndAt(int offset) {
    for (final span in formattingSyntax) {
      if (span.start == offset) return span.end;
      if (span.start > offset) return null;
    }
    return null;
  }

  int? _opaqueEndAt(int offset) {
    for (final span in opaqueSyntax) {
      if (offset >= span.start && offset < span.end) return span.end;
      if (span.start > offset) return null;
    }
    return null;
  }

  int? _matchingBracket(int start, int end, int opening, int closing) {
    if (start >= end || source.codeUnitAt(start) != opening) return null;
    var depth = 0;
    for (var cursor = start; cursor < end; cursor++) {
      if (source.codeUnitAt(cursor) == 0x5c) {
        cursor++;
        continue;
      }
      final unit = source.codeUnitAt(cursor);
      if (unit == opening) depth++;
      if (unit == closing && --depth == 0) return cursor;
    }
    return null;
  }
}

final class _SourceInterval {
  const _SourceInterval(this.start, this.end);

  final int start;
  final int end;
}

final class _MultilineHtmlSpan {
  const _MultilineHtmlSpan({
    required this.tagStart,
    required this.opaqueStart,
    required this.opaqueEnd,
    required this.readableAttributes,
  });

  final int tagStart;
  final int opaqueStart;
  final int opaqueEnd;
  final List<_HtmlReadableAttribute> readableAttributes;
}

final class _HtmlReadableAttribute {
  const _HtmlReadableAttribute({
    required this.start,
    required this.end,
    required this.context,
  });

  final int start;
  final int end;
  final SpellingSourceContext context;
}

List<_MultilineHtmlSpan> _multilineHtmlSpans(
  String source,
  int start,
  int end,
) {
  final result = <_MultilineHtmlSpan>[];
  var cursor = start;
  while (cursor < end) {
    final opening = source.indexOf('<', cursor);
    if (opening < 0 || opening >= end) break;
    var precedingBackslashes = 0;
    for (
      var index = opening - 1;
      index >= start && source.codeUnitAt(index) == 0x5c;
      index--
    ) {
      precedingBackslashes++;
    }
    if (precedingBackslashes.isOdd) {
      cursor = opening + 1;
      continue;
    }
    final candidate = RegExp(
      r'^</?[A-Za-z][A-Za-z0-9:-]*(?:\s|/?>|$)',
    ).hasMatch(source.substring(opening, math.min(end, opening + 128)));
    if (!candidate) {
      cursor = opening + 1;
      continue;
    }
    int? quote;
    var close = -1;
    for (var index = opening + 1; index < end; index++) {
      final unit = source.codeUnitAt(index);
      if (quote != null) {
        if (unit == quote) quote = null;
      } else if (unit == 0x22 || unit == 0x27) {
        quote = unit;
      } else if (unit == 0x3e) {
        close = index;
        break;
      }
    }
    if (close < 0) break;
    final raw = source.substring(opening, close + 1);
    if (!raw.contains(RegExp(r'[\r\n]'))) {
      cursor = close + 1;
      continue;
    }
    final parsed = RegExp(
      r'^<\s*(/?)\s*([A-Za-z][A-Za-z0-9:-]*)\b',
    ).firstMatch(raw);
    final closing = parsed?.group(1)?.isNotEmpty ?? false;
    final tag = parsed?.group(2)?.toLowerCase();
    var opaqueEnd = close + 1;
    if (!closing &&
        tag != null &&
        _opaqueHtmlElements.contains(tag) &&
        !raw.trimRight().endsWith('/>')) {
      final closingMatch = RegExp(
        '</\\s*${RegExp.escape(tag)}\\s*>',
        caseSensitive: false,
      ).firstMatch(source.substring(close + 1, end));
      opaqueEnd = closingMatch == null ? end : close + 1 + closingMatch.end;
    }
    final attributes = <_HtmlReadableAttribute>[];
    if (!closing && (tag == null || !_opaqueHtmlElements.contains(tag))) {
      for (final match in _humanAttribute.allMatches(raw)) {
        if (!_humanAttributeNames.contains(match.group(1)!.toLowerCase())) {
          continue;
        }
        final value = match.group(3)!;
        final valueStart = opening + match.end - 1 - value.length;
        attributes.add(
          _HtmlReadableAttribute(
            start: valueStart,
            end: valueStart + value.length,
            context: match.group(2) == "'"
                ? SpellingSourceContext.xmlSingleQuotedAttribute
                : SpellingSourceContext.xmlDoubleQuotedAttribute,
          ),
        );
      }
    }
    result.add(
      _MultilineHtmlSpan(
        tagStart: opening,
        opaqueStart: opening,
        opaqueEnd: opaqueEnd,
        readableAttributes: List.unmodifiable(attributes),
      ),
    );
    cursor = opaqueEnd;
  }
  return List.unmodifiable(result);
}

final class _RawFormattingWrapper {
  const _RawFormattingWrapper({
    required this.kind,
    required this.opening,
    required this.contentStart,
    required this.contentEnd,
    required this.closing,
  });

  final String kind;
  final _SourceInterval opening;
  final int contentStart;
  final int contentEnd;
  final _SourceInterval closing;
}

List<_SourceInterval> _formattingSyntaxSpans(
  Iterable<BusyMarkMappedInlineParse> parses, {
  required int sourceBase,
}) {
  final spans = <_SourceInterval>[];
  for (final parse in parses) {
    for (final entry in parse.ranges.entries) {
      if (!_formattingInlineKinds.contains(entry.key.kind)) continue;
      final range = entry.value;
      final opening = range.opening;
      final closing = range.closing;
      if (opening != null && opening.isNotEmpty) {
        spans.add(
          _SourceInterval(
            sourceBase + range.start,
            sourceBase + range.start + opening.length,
          ),
        );
      }
      if (closing != null && closing.isNotEmpty) {
        spans.add(
          _SourceInterval(
            sourceBase + range.end - closing.length,
            sourceBase + range.end,
          ),
        );
      }
    }
  }
  spans.sort((left, right) => left.start.compareTo(right.start));
  return List.unmodifiable(spans);
}

List<_RawFormattingWrapper> _formattingWrappers(
  Iterable<BusyMarkMappedInlineParse> parses, {
  required int sourceBase,
}) {
  final wrappers = <_RawFormattingWrapper>[];
  for (final parse in parses) {
    for (final entry in parse.ranges.entries) {
      if (!_formattingInlineKinds.contains(entry.key.kind)) continue;
      final range = entry.value;
      final opening = range.opening;
      final closing = range.closing;
      if (opening == null ||
          opening.isEmpty ||
          closing == null ||
          closing.isEmpty) {
        continue;
      }
      final openingStart = sourceBase + range.start;
      final openingEnd = openingStart + opening.length;
      final closingEnd = sourceBase + range.end;
      final closingStart = closingEnd - closing.length;
      if (openingEnd > closingStart) continue;
      wrappers.add(
        _RawFormattingWrapper(
          kind: entry.key.kind.name,
          opening: _SourceInterval(openingStart, openingEnd),
          contentStart: openingEnd,
          contentEnd: closingStart,
          closing: _SourceInterval(closingStart, closingEnd),
        ),
      );
    }
  }
  wrappers.sort(
    (left, right) => left.opening.start.compareTo(right.opening.start),
  );
  return List.unmodifiable(wrappers);
}

List<_SourceInterval> _opaqueSyntaxSpans(
  Iterable<BusyMarkMappedInlineParse> parses, {
  required int sourceBase,
  Set<BusyInlineKind> excludedKinds = _opaqueInlineKinds,
}) {
  final spans = <_SourceInterval>[];
  for (final parse in parses) {
    for (final entry in parse.ranges.entries) {
      if (!excludedKinds.contains(entry.key.kind)) continue;
      final range = entry.value;
      spans.add(
        _SourceInterval(sourceBase + range.start, sourceBase + range.end),
      );
    }
  }
  spans.sort((left, right) => left.start.compareTo(right.start));
  return List.unmodifiable(spans);
}

const _formattingInlineKinds = {
  BusyInlineKind.strong,
  BusyInlineKind.emphasis,
  BusyInlineKind.strikethrough,
  BusyInlineKind.underline,
};

const _opaqueInlineKinds = {
  BusyInlineKind.code,
  BusyInlineKind.math,
  BusyInlineKind.writersideVariable,
};

const _opaqueHtmlElements = {'code', 'pre', 'script', 'style'};

const _blockHtmlElements = {
  'address',
  'article',
  'aside',
  'blockquote',
  'body',
  'details',
  'dialog',
  'div',
  'dl',
  'dt',
  'dd',
  'fieldset',
  'figcaption',
  'figure',
  'footer',
  'form',
  'h1',
  'h2',
  'h3',
  'h4',
  'h5',
  'h6',
  'header',
  'html',
  'li',
  'main',
  'nav',
  'ol',
  'p',
  'section',
  'summary',
  'table',
  'tbody',
  'td',
  'tfoot',
  'th',
  'thead',
  'tr',
  'ul',
};

bool _commonMarkEscapableAsciiPunctuation(int unit) =>
    (unit >= 0x21 && unit <= 0x2f) ||
    (unit >= 0x3a && unit <= 0x40) ||
    (unit >= 0x5b && unit <= 0x60) ||
    (unit >= 0x7b && unit <= 0x7e);

bool _horizontalWhitespace(int unit) => unit == 0x20 || unit == 0x09;

bool _coversSourceRange(int start, int end, List<_SourceInterval> intervals) {
  if (start >= end) return true;
  final ordered = [...intervals]
    ..sort((left, right) => left.start.compareTo(right.start));
  var cursor = start;
  for (final interval in ordered) {
    if (interval.end <= cursor || interval.start >= end) continue;
    if (interval.start > cursor) return false;
    cursor = math.max(cursor, interval.end);
    if (cursor >= end) return true;
  }
  return false;
}

bool _isSetextOrThematic(String line) {
  final trimmed = line.trim();
  return RegExp(r'^(?:=+|-+)$').hasMatch(trimmed) ||
      RegExp(r'^(?:\*\s*){3,}$').hasMatch(trimmed) ||
      RegExp(r'^(?:_\s*){3,}$').hasMatch(trimmed);
}

final RegExp _blockPrefix = RegExp(
  r'^[ \t]{0,3}(?:(?:>[ \t]?)+)?(?:(?:[-+*]|\d+[.)])[ \t]+(?:\[[ xX]\][ \t]+)?)?',
);
final RegExp _entity = RegExp(
  r'&(?:#[0-9]{1,7}|#[xX][0-9A-Fa-f]{1,6}|[A-Za-z][A-Za-z0-9]{1,31});',
);
final RegExp _autolink = RegExp(r'^<[A-Za-z][A-Za-z0-9+.-]*:[^ <>]*>$');
final RegExp _emailAutolink = RegExp(r'^<[^ <>@]+@[^ <>@]+>$');
final RegExp _humanAttribute = RegExp(
  r'''\b([A-Za-z_:][-A-Za-z0-9_:.]*)\s*=\s*(["'])(.*?)\2''',
  dotAll: true,
);
const _humanAttributeNames = {
  'alt',
  'title',
  'summary',
  'tooltip',
  'switcher-label',
};

int _codePointAt(String value, int offset) {
  final first = value.codeUnitAt(offset);
  if (first >= 0xd800 && first <= 0xdbff && offset + 1 < value.length) {
    final second = value.codeUnitAt(offset + 1);
    if (second >= 0xdc00 && second <= 0xdfff) {
      return 0x10000 + ((first - 0xd800) << 10) + second - 0xdc00;
    }
  }
  return first;
}
