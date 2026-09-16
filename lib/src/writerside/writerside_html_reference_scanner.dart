// HtmlParser exposes its tokenizer but does not expose per-attribute source
// spans through its public DOM API. Keep authored-reference discovery on the
// same tokenizer used by Rename Topic File.
// ignore: implementation_imports
import 'package:html/src/token.dart' show EndTagToken, StartTagToken;
// ignore: implementation_imports
import 'package:html/src/tokenizer.dart' show HtmlTokenizer;

import '../core/source_span.dart';
import '../markdown/busymark_document.dart';
import '../markdown/markdown_ast_adapter.dart';
import '../markdown/markdown_model.dart';

enum WritersideHtmlAttributeQuote { doubleQuoted, singleQuoted, unquoted }

class WritersideAuthoredHtmlAnchorReference {
  const WritersideAuthoredHtmlAnchorReference({
    required this.href,
    required this.authoredHref,
    required this.hrefSpan,
    required this.startTagSpan,
    required this.quote,
    this.origin,
    this.anchorSpan,
    this.innerContentSpan,
    this.structurallySafe = false,
  });

  /// The tokenizer-decoded destination used for semantic resolution.
  final String href;

  /// The exact source spelling of the href value, excluding its quotes.
  final String authoredHref;
  final String? origin;
  final SourceSpan hrefSpan;
  final SourceSpan startTagSpan;
  final SourceSpan? anchorSpan;
  final SourceSpan? innerContentSpan;
  final WritersideHtmlAttributeQuote quote;

  /// Whether the scanner proved that one complete authored anchor can be
  /// replaced by its exact inner source without losing surrounding markup.
  final bool structurallySafe;
}

class WritersideAuthoredHtmlReferenceScanner {
  const WritersideAuthoredHtmlReferenceScanner();

  List<WritersideAuthoredHtmlAnchorReference> scanMarkdownAnchors({
    required String filePath,
    required String source,
    required List<bool> protectedSource,
  }) {
    if (protectedSource.length != source.length) {
      throw ArgumentError.value(
        protectedSource.length,
        'protectedSource',
        'The Markdown literal mask must match the source length.',
      );
    }
    final completed = <WritersideAuthoredHtmlAnchorReference>[];
    final open = <_OpenHtmlAnchor>[];
    final tokenizer = HtmlTokenizer(
      source,
      generateSpans: true,
      attributeSpans: true,
    );
    while (tokenizer.moveNext()) {
      final token = tokenizer.current;
      if (token is StartTagToken && token.name == 'a') {
        final tagSpan = token.span;
        if (tagSpan == null ||
            _rangeIsProtected(
              protectedSource,
              tagSpan.start.offset,
              tagSpan.end.offset,
            )) {
          continue;
        }
        if (open.isNotEmpty) {
          for (final pending in open) {
            pending.structurallySafe = false;
          }
        }
        final pending = _openAnchor(
          filePath: filePath,
          source: source,
          token: token,
        );
        if (token.selfClosing) {
          if (pending.reference != null) completed.add(pending.reference!);
          continue;
        }
        open.add(pending);
        continue;
      }
      if (token is! EndTagToken || token.name != 'a') continue;
      final endSpan = token.span;
      if (endSpan == null ||
          _rangeIsProtected(
            protectedSource,
            endSpan.start.offset,
            endSpan.end.offset,
          ) ||
          open.isEmpty) {
        continue;
      }
      final pending = open.removeLast();
      if (open.isNotEmpty) {
        pending.structurallySafe = false;
        for (final ancestor in open) {
          ancestor.structurallySafe = false;
        }
      }
      final reference = pending.reference;
      if (reference == null) continue;
      final bodyStart = reference.startTagSpan.endOffset;
      final bodyEnd = endSpan.start.offset;
      final anchorEnd = endSpan.end.offset;
      final safe =
          pending.structurallySafe &&
          bodyStart <= bodyEnd &&
          anchorEnd <= source.length &&
          !_rangeIsProtected(protectedSource, bodyStart, anchorEnd);
      completed.add(
        WritersideAuthoredHtmlAnchorReference(
          href: reference.href,
          authoredHref: reference.authoredHref,
          origin: reference.origin,
          hrefSpan: reference.hrefSpan,
          startTagSpan: reference.startTagSpan,
          quote: reference.quote,
          anchorSpan: SourceSpan.fromOffsets(
            filePath: filePath,
            source: source,
            startOffset: reference.startTagSpan.startOffset,
            endOffset: anchorEnd,
          ),
          innerContentSpan: SourceSpan.fromOffsets(
            filePath: filePath,
            source: source,
            startOffset: bodyStart,
            endOffset: bodyEnd,
          ),
          structurallySafe: safe,
        ),
      );
    }
    for (final pending in open) {
      if (pending.reference case final reference?) completed.add(reference);
    }
    final rendered = _renderedAnchorIndexes(
      filePath: filePath,
      source: source,
      references: completed,
    );
    for (var index = completed.length - 1; index >= 0; index--) {
      if (!rendered.contains(index)) completed.removeAt(index);
    }
    completed.sort(
      (left, right) =>
          left.hrefSpan.startOffset.compareTo(right.hrefSpan.startOffset),
    );
    return List.unmodifiable(completed);
  }

  Set<int> _renderedAnchorIndexes({
    required String filePath,
    required String source,
    required List<WritersideAuthoredHtmlAnchorReference> references,
  }) {
    if (references.isEmpty) return const {};
    final probes = <int, String>{};
    var probed = source;
    for (var index = references.length - 1; index >= 0; index--) {
      var probe = 'busymark-html-reference-$index.invalid';
      while (source.contains(probe)) {
        probe = 'x$probe';
      }
      probes[index] = probe;
      final span = references[index].hrefSpan;
      probed = probed.replaceRange(span.startOffset, span.endOffset, probe);
    }
    final document = const MarkdownAstAdapter().parse(
      filePath: filePath,
      source: probed,
      mode: MarkdownMode.writersideMarkdown,
    );
    final renderedDestinations = <String>{};
    void visitInline(BusyInline inline) {
      if (inline.kind == BusyInlineKind.link && inline.destination != null) {
        renderedDestinations.add(inline.destination!);
      }
      for (final child in inline.children) {
        visitInline(child);
      }
    }

    void visitBlock(BusyBlock block) {
      for (final inline in block.inlines) {
        visitInline(inline);
      }
      for (final child in block.children) {
        visitBlock(child);
      }
    }

    for (final block in document.blocks) {
      visitBlock(block);
    }
    return {
      for (final entry in probes.entries)
        if (renderedDestinations.contains(entry.value)) entry.key,
    };
  }

  _OpenHtmlAnchor _openAnchor({
    required String filePath,
    required String source,
    required StartTagToken token,
  }) {
    final tagSpan = token.span!;
    final attributes = token.attributeSpans;
    final href = attributes
        ?.where((attribute) => attribute.name == 'href')
        .firstOrNull;
    final hrefStart = href?.startValue;
    final hrefEnd = href?.endValue;
    final destination = href?.value;
    if (href == null ||
        hrefStart == null ||
        hrefEnd == null ||
        hrefStart < tagSpan.start.offset ||
        hrefEnd > tagSpan.end.offset ||
        hrefStart >= hrefEnd ||
        destination == null ||
        destination.isEmpty) {
      return _OpenHtmlAnchor(reference: null);
    }
    final quote = switch (hrefStart > tagSpan.start.offset
        ? source[hrefStart - 1]
        : null) {
      '"' when hrefEnd < tagSpan.end.offset && source[hrefEnd] == '"' =>
        WritersideHtmlAttributeQuote.doubleQuoted,
      "'" when hrefEnd < tagSpan.end.offset && source[hrefEnd] == "'" =>
        WritersideHtmlAttributeQuote.singleQuoted,
      _ => WritersideHtmlAttributeQuote.unquoted,
    };
    final origin = token.data['origin']?.trim();
    return _OpenHtmlAnchor(
      reference: WritersideAuthoredHtmlAnchorReference(
        href: destination,
        authoredHref: source.substring(hrefStart, hrefEnd),
        origin: origin?.isEmpty == true ? null : origin,
        hrefSpan: SourceSpan.fromOffsets(
          filePath: filePath,
          source: source,
          startOffset: hrefStart,
          endOffset: hrefEnd,
        ),
        startTagSpan: SourceSpan.fromOffsets(
          filePath: filePath,
          source: source,
          startOffset: tagSpan.start.offset,
          endOffset: tagSpan.end.offset,
        ),
        quote: quote,
      ),
    );
  }
}

/// Builds the literal mask shared by topic rename and topic removal.
///
/// Fenced code ranges come from BusyMark's Markdown parser. Inline code and
/// comments are protected here so HTML tokenization cannot promote examples
/// into authored topic references.
List<bool> writersideMarkdownLiteralMask({
  required String source,
  Iterable<SourceSpan> protectedRanges = const [],
}) {
  final protected = List<bool>.filled(source.length, false);
  void protect(int start, int end) {
    final safeStart = start.clamp(0, source.length);
    final safeEnd = end.clamp(safeStart, source.length);
    for (var index = safeStart; index < safeEnd; index++) {
      protected[index] = true;
    }
  }

  for (final range in protectedRanges) {
    protect(range.startOffset, range.endOffset);
  }
  for (final comment in RegExp(r'<!--[\s\S]*?(?:-->|$)').allMatches(source)) {
    protect(comment.start, comment.end);
  }
  for (var cursor = 0; cursor < source.length; cursor++) {
    if (protected[cursor] ||
        source[cursor] != '`' ||
        _isEscapedMarkdownCharacter(source, cursor)) {
      continue;
    }
    var delimiterLength = 1;
    while (cursor + delimiterLength < source.length &&
        source[cursor + delimiterLength] == '`') {
      delimiterLength++;
    }
    var closing = cursor + delimiterLength;
    while (closing < source.length) {
      if (!protected[closing] && source[closing] == '`') {
        var runLength = 1;
        while (closing + runLength < source.length &&
            source[closing + runLength] == '`') {
          runLength++;
        }
        if (runLength == delimiterLength) break;
        closing += runLength;
      } else {
        closing++;
      }
    }
    if (closing < source.length) {
      protect(cursor, closing + delimiterLength);
      cursor = closing + delimiterLength - 1;
    }
  }
  return protected;
}

class _OpenHtmlAnchor {
  _OpenHtmlAnchor({required this.reference});

  final WritersideAuthoredHtmlAnchorReference? reference;
  bool structurallySafe = true;
}

bool _rangeIsProtected(List<bool> protected, int start, int end) {
  final safeStart = start.clamp(0, protected.length);
  final safeEnd = end.clamp(safeStart, protected.length);
  for (var index = safeStart; index < safeEnd; index++) {
    if (protected[index]) return true;
  }
  return false;
}

bool _isEscapedMarkdownCharacter(String source, int offset) {
  var slashCount = 0;
  for (var index = offset - 1; index >= 0 && source[index] == '\\'; index--) {
    slashCount++;
  }
  return slashCount.isOdd;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
