// These are source adapters for BusyMark's supported grammar. Candidates are
// accepted by the existing parser, never by a link-looking regular expression.
// ignore: implementation_imports
import 'package:markdown/src/link_parser.dart' show LinkParser;
// ignore: implementation_imports
import 'package:markdown/src/util.dart' show normalizeLinkLabel;

import '../core/source_span.dart';
import '../markdown/busymark_document.dart';
import '../markdown/markdown_model.dart';
import '../markdown/markdown_parser.dart';
import '../markdown/markdown_source_map.dart';
import '../writerside/writerside_html_reference_scanner.dart';

enum AuthoredReferenceKind {
  link,
  referenceLink,
  htmlLink,
  media,
  htmlMedia,
  topic,
  include,
}

class AuthoredReference {
  const AuthoredReference({
    required this.destination,
    required this.kind,
    required this.occurrence,
    required this.destinationSpan,
    this.label = '',
    this.origin,
    this.moduleId,
  });
  final String destination, label;
  final AuthoredReferenceKind kind;
  final SourceSpan occurrence;
  final SourceSpan? destinationSpan;
  final String? origin, moduleId;
}

({int start, int end})? markdownDestinationRange(
  String source,
  int start,
  int limit,
) {
  while (start < limit && RegExp(r'\s').hasMatch(source[start])) {
    start++;
  }
  if (start >= limit) return null;
  var end = start;
  if (source[start] == '<') {
    start++;
    end = start;
    while (end < limit) {
      if (source[end] == '\\') {
        end += 2;
        continue;
      }
      if (source[end] == '>') return (start: start, end: end);
      end++;
    }
    return null;
  }
  var depth = 0;
  while (end < limit) {
    final char = source[end];
    if (char == '\\') {
      end += 2;
      continue;
    }
    if (char == '(') depth++;
    if (char == ')') {
      if (depth == 0) break;
      depth--;
    }
    if (RegExp(r'\s').hasMatch(char)) break;
    end++;
  }
  return end <= limit ? (start: start, end: end) : null;
}

List<AuthoredReference> markdownReferences({
  required String identity,
  required String source,
  MarkdownMode mode = MarkdownMode.commonMark,
}) {
  final parsed = const MarkdownParser().parse(
    filePath: identity,
    source: source,
    mode: mode,
    validateLocalReferences: false,
  );
  final context = const MarkdownSourceMapper().createInlineParserContext(
    documentSource: source,
    mode: mode,
  );
  final mask = writersideMarkdownLiteralMask(
    source: source,
    protectedRanges: parsed.codeBlocks.map((b) => b.span),
  );
  SourceSpan span(int start, int end) => SourceSpan.fromOffsets(
    filePath: identity,
    source: source,
    startOffset: start,
    endOffset: end,
  );
  final definitions = <String, SourceSpan>{};
  // LinkParser validates balanced/escaped destinations, multiline definitions
  // and titles. A parser probe proves this is the winning declaration, including
  // container/prose/code context and CommonMark's first-definition rule.
  for (final match in RegExp(
    r'\[(?:\\.|[^\]\\]){1,999}\]:',
  ).allMatches(source)) {
    if (mask[match.start]) continue;
    final blank = source.indexOf(RegExp(r'\n[ \t]*\n'), match.start);
    final limit = blank < 0 ? source.length : blank;
    final parser = LinkParser(
      source
          .substring(match.start, limit)
          .replaceAll(RegExp(r'(?<=\n) {0,3}(?:> ?)+'), ''),
    )..parseDefinition();
    if (!parser.valid || parser.label == null) continue;
    final label = normalizeLinkLabel(parser.label!);
    if (definitions.containsKey(label) ||
        !context.referenceDefinitions.containsKey(label)) {
      continue;
    }
    var destinationStart = match.end;
    while (destinationStart < limit &&
        RegExp(r'[\s>]').hasMatch(source[destinationStart])) {
      destinationStart++;
    }
    final range = markdownDestinationRange(source, destinationStart, limit);
    if (range == null) continue;
    var probe = 'https://busymark-reference.invalid/definition';
    while (source.contains(probe)) {
      probe += 'x';
    }
    final candidate = source.replaceRange(range.start, range.end, probe);
    final verified = const MarkdownSourceMapper()
        .createInlineParserContext(documentSource: candidate, mode: mode)
        .referenceDefinitions[label];
    if (verified?.destination == probe) {
      definitions[label] = span(range.start, range.end);
    }
  }
  final result = <AuthoredReference>[];
  final seen = <String>{};
  for (final mapping in context.parsePositionedBlocks(
    source,
    includeCodeBlocks: false,
  )) {
    for (final entry in mapping.ranges.entries) {
      final inline = entry.key;
      final range = entry.value;
      if (inline.destination == null ||
          !{BusyInlineKind.link, BusyInlineKind.image}.contains(inline.kind) ||
          range.start < 0 ||
          range.end > source.length ||
          range.start == range.end ||
          mask.sublist(range.start, range.end).any((v) => v)) {
        continue;
      }
      if (!seen.add('${range.start}:${range.end}')) continue;
      SourceSpan? destination;
      if (range.isReference) {
        final raw = source.substring(range.start, range.end);
        final suffix = RegExp(r'\[([^\]]*)\]$').firstMatch(raw)?.group(1);
        final label = suffix?.isNotEmpty == true
            ? suffix!
            : range.labelStart != null && range.labelEnd != null
            ? source.substring(range.labelStart!, range.labelEnd!)
            : '';
        destination = definitions[normalizeLinkLabel(label)];
      } else if (range.isAutolink) {
        destination = source[range.start] == '<'
            ? span(range.start + 1, range.end - 1)
            : span(range.start, range.end);
      } else if (range.labelEnd != null &&
          range.labelEnd! + 1 < range.end &&
          source[range.labelEnd! + 1] == '(') {
        final found = markdownDestinationRange(
          source,
          range.labelEnd! + 2,
          range.end,
        );
        if (found != null) destination = span(found.start, found.end);
      }
      if (destination == null) {
        continue; // Authored HTML is mapped by its tokenizer below.
      }
      result.add(
        AuthoredReference(
          destination: inline.destination!,
          kind: inline.kind == BusyInlineKind.image
              ? AuthoredReferenceKind.media
              : range.isReference
              ? AuthoredReferenceKind.referenceLink
              : AuthoredReferenceKind.link,
          occurrence: span(range.start, range.end),
          destinationSpan: destination,
          label: inline.text,
        ),
      );
    }
  }
  for (final html
      in const WritersideAuthoredHtmlReferenceScanner().scanMarkdownAnchors(
        filePath: identity,
        source: source,
        protectedSource: mask,
      )) {
    result.add(
      AuthoredReference(
        destination: html.href,
        kind: AuthoredReferenceKind.htmlLink,
        occurrence: html.anchorSpan ?? html.startTagSpan,
        destinationSpan: html.hrefSpan,
        label: html.innerContentSpan == null
            ? ''
            : source.substring(
                html.innerContentSpan!.startOffset,
                html.innerContentSpan!.endOffset,
              ),
        origin: html.origin,
      ),
    );
  }
  for (final media
      in const WritersideAuthoredHtmlReferenceScanner().scanMarkdownMedia(
        filePath: identity,
        source: source,
        protectedSource: mask,
      )) {
    result.add(
      AuthoredReference(
        destination: media.destination,
        kind: AuthoredReferenceKind.htmlMedia,
        occurrence: media.span,
        destinationSpan: media.span,
      ),
    );
  }
  result.sort(
    (a, b) => a.occurrence.startOffset.compareTo(b.occurrence.startOffset),
  );
  return List.unmodifiable(result);
}
