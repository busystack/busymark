import 'dart:math' as math;

import 'package:html/parser.dart' as html;

import '../core/source_span.dart';
import '../markdown/busymark_document.dart';
import '../markdown/markdown_model.dart';
import '../markdown/markdown_parser.dart';
import '../markdown/markdown_source_map.dart';
import '../markdown/markdown_source_structure.dart';
import 'spelling_projection.dart';

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
    final codeSpans = <SourceSpan>[
      ...parsed.codeBlocks.map((block) => block.span),
      for (final block in _walkBlocks(parsed.busyDocument.blocks))
        if (block.kind == BusyBlockKind.math && block.sourceSpan != null)
          block.sourceSpan!,
    ];
    final tables = [
      for (final block in _walkBlocks(parsed.busyDocument.blocks))
        if (block.kind == BusyBlockKind.table &&
            !block.attributes.containsKey('header'))
          block,
    ];
    final runs = <SpellingProseRun>[];
    var complete = true;
    var sequence = 0;

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
      final formattingSyntax = _formattingSyntaxSpans(
        mapped,
        sourceBase: start,
      );
      final opaqueSyntax = <_SourceInterval>[
        ..._opaqueSyntaxSpans(mapped, sourceBase: start),
        if (mode == MarkdownMode.writersideMarkdown)
          for (final variable in parsed.variables)
            if (variable.span.startOffset < end &&
                variable.span.endOffset > start)
              _SourceInterval(
                variable.span.startOffset,
                variable.span.endOffset,
              ),
      ]..sort((left, right) => left.start.compareTo(right.start));
      final scanner = _MarkdownProseScanner(
        source: source,
        start: start,
        end: end,
        context: context,
        stripBlockSyntax: stripBlockSyntax,
        formattingSyntax: formattingSyntax,
        formattingWrappers: _formattingWrappers(mapped, sourceBase: start),
        opaqueSyntax: opaqueSyntax,
      );
      final groups = scanner.scan();
      complete = complete && scanner.complete;
      for (final group in groups) {
        if (group.text.trim().isEmpty) continue;
        final run = SpellingProseRun(
          id: 'markdown:${sequence++}:$start',
          text: group.text,
          languageId: languageId,
          atoms: List.unmodifiable(group.atoms),
          target: SpellingSourceTarget(filePath: filePath),
          snapshot: snapshot,
          formattingWrappers: group.formattingWrappers,
          complete: scanner.complete,
        );
        if (!run.hasValidMapping) {
          complete = false;
          continue;
        }
        runs.add(run);
      }
    }

    final consumedTables = <String>{};
    for (final chunk in chunks) {
      if (chunk.sourceOnly ||
          codeSpans.any((span) => _contains(span, chunk.span)) ||
          _startsExcludedBlock(chunk.rawSource)) {
        continue;
      }
      final table = tables.where((candidate) {
        final span = candidate.sourceSpan;
        return span != null && _sameSpan(span, chunk.span);
      }).firstOrNull;
      if (table != null) {
        if (!consumedTables.add(table.id)) continue;
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
    );
  }
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

bool _startsExcludedBlock(String raw) {
  final trimmed = raw.trimLeft();
  return RegExp(r'^(?:```|~~~|\$\$)').hasMatch(trimmed) ||
      RegExp(
        r'^(?:<!--|<\?xml\b|<!DOCTYPE\b)',
        caseSensitive: false,
      ).hasMatch(trimmed);
}

final class _EmissionGroup {
  const _EmissionGroup({
    required this.text,
    required this.atoms,
    required this.formattingWrappers,
  });
  final String text;
  final List<SpellingSourceAtom> atoms;
  final List<SpellingFormattingWrapper> formattingWrappers;
}

final class _MarkdownProseScanner {
  _MarkdownProseScanner({
    required this.source,
    required this.start,
    required this.end,
    required this.context,
    required this.stripBlockSyntax,
    this.formattingSyntax = const [],
    this.formattingWrappers = const [],
    this.opaqueSyntax = const [],
  });

  final String source;
  final int start;
  final int end;
  final SpellingSourceContext context;
  final bool stripBlockSyntax;
  final List<_SourceInterval> formattingSyntax;
  final List<_RawFormattingWrapper> formattingWrappers;
  final List<_SourceInterval> opaqueSyntax;
  final List<_EmissionGroup> _groups = [];
  StringBuffer _text = StringBuffer();
  List<SpellingSourceAtom> _atoms = [];
  int? _opaqueEnd;
  bool complete = true;

  List<_EmissionGroup> scan() {
    final lines = _lines();
    for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final line = lines[lineIndex];
      var contentStart = line.start;
      var contentEnd = line.contentEnd;
      if (stripBlockSyntax) {
        final rawLine = source.substring(contentStart, contentEnd);
        if (_isSetextOrThematic(rawLine)) {
          _barrier();
          continue;
        }
        final prefix = _blockPrefix.firstMatch(rawLine);
        contentStart += prefix?.end ?? 0;
        if (source.startsWith('#', contentStart)) {
          final heading = RegExp(
            r'^#{1,6}[ \t]+',
          ).firstMatch(source.substring(contentStart, contentEnd));
          contentStart += heading?.end ?? 0;
        }
        while (contentEnd > contentStart &&
            _horizontalWhitespace(source.codeUnitAt(contentEnd - 1))) {
          contentEnd--;
        }
        final closingHeading = RegExp(
          r'[ \t]+#+$',
        ).firstMatch(source.substring(contentStart, contentEnd));
        if (closingHeading != null) {
          contentEnd = contentStart + closingHeading.start;
        }
        final attributes = RegExp(
          r'[ \t]+\{[^{}]*\}$',
        ).firstMatch(source.substring(contentStart, contentEnd));
        if (attributes != null) {
          contentEnd = contentStart + attributes.start;
        }
      }
      if (contentEnd > contentStart) _scanInline(contentStart, contentEnd);
      if (lineIndex + 1 < lines.length && _text.length > 0) {
        final next = lines[lineIndex + 1];
        _emit(
          ' ',
          line.contentEnd,
          next.start,
          SpellingTransformationKind.lineBreak,
        );
      }
    }
    _flush();
    return List.unmodifiable(_groups);
  }

  void _scanInline(int rangeStart, int rangeEnd) {
    var cursor = rangeStart;
    while (cursor < rangeEnd) {
      if (_opaqueEnd case final opaqueEnd? when cursor < opaqueEnd) {
        _barrier();
        cursor = math.min(rangeEnd, opaqueEnd);
        if (cursor >= opaqueEnd) _opaqueEnd = null;
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
      if (source.startsWith('<!--', cursor)) {
        final close = source.indexOf('-->', cursor + 4);
        _barrier();
        _opaqueEnd = close < 0 || close >= end ? end : close + 3;
        if (close < 0 || close >= end) complete = false;
        continue;
      }
      final plainUrl = _plainUrl.matchAsPrefix(source, cursor);
      if (plainUrl != null && plainUrl.end <= rangeEnd) {
        _barrier();
        cursor = plainUrl.end;
        continue;
      }
      final plainEmail = _plainEmail.matchAsPrefix(source, cursor);
      if (plainEmail != null && plainEmail.end <= rangeEnd) {
        _barrier();
        cursor = plainEmail.end;
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
      if (unit == 0x24) {
        final count = _runLength(cursor, rangeEnd, 0x24).clamp(1, 2);
        final delimiter = r'$' * count;
        final close = source.indexOf(delimiter, cursor + count);
        if (close >= 0 && close < end) {
          _barrier();
          _opaqueEnd = close + count;
          continue;
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
      if (unit == 0x3c) {
        final close = source.indexOf('>', cursor + 1);
        if (close >= 0 && close < rangeEnd) {
          final raw = source.substring(cursor, close + 1);
          if (_autolink.hasMatch(raw) || _emailAutolink.hasMatch(raw)) {
            _barrier();
            cursor = close + 1;
            continue;
          }
          _scanHumanReadableAttributes(cursor, close + 1);
          cursor = close + 1;
          continue;
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

  int? _scanLinkOrImage(int cursor, int rangeEnd, {required bool image}) {
    final opening = cursor + (image ? 1 : 0);
    final labelEnd = _matchingBracket(opening, rangeEnd, 0x5b, 0x5d);
    if (labelEnd == null) return null;
    final afterLabel = labelEnd + 1;
    var syntaxEnd = afterLabel;
    int? titleStart;
    int? titleEnd;
    SpellingSourceContext? titleContext;
    if (afterLabel < rangeEnd && source.codeUnitAt(afterLabel) == 0x28) {
      final destinationEnd = _matchingBracket(afterLabel, rangeEnd, 0x28, 0x29);
      if (destinationEnd == null) return null;
      syntaxEnd = destinationEnd + 1;
      final inside = source.substring(afterLabel + 1, destinationEnd);
      final title = RegExp(r'''(?:^|\s)(["'])(.*?)\1\s*$''').firstMatch(inside);
      if (title != null) {
        titleContext = title.group(1) == "'"
            ? SpellingSourceContext.markdownSingleQuotedTitle
            : SpellingSourceContext.markdownDoubleQuotedTitle;
        // The value ends immediately before the closing quote. Derive its
        // range from those parsed boundaries rather than searching for its
        // contents, which may also occur in the destination.
        titleStart = afterLabel + 1 + title.end - 1 - title.group(2)!.length;
        titleEnd = titleStart + title.group(2)!.length;
      }
    } else if (afterLabel < rangeEnd && source.codeUnitAt(afterLabel) == 0x5b) {
      final referenceEnd = source.indexOf(']', afterLabel + 1);
      if (referenceEnd < 0 || referenceEnd >= rangeEnd) return null;
      syntaxEnd = referenceEnd + 1;
    } else if (image) {
      return null;
    }

    if (image) _barrier();
    _scanInline(opening + 1, labelEnd);
    if (image) _barrier();
    if (titleStart != null && titleEnd != null && titleEnd > titleStart) {
      _barrier();
      final scanner = _MarkdownProseScanner(
        source: source,
        start: titleStart,
        end: titleEnd,
        context: titleContext!,
        stripBlockSyntax: false,
      );
      _groups.addAll(scanner.scan());
      complete = complete && scanner.complete;
      _barrier();
    }
    return syntaxEnd;
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
      _barrier();
      final scanner = _MarkdownProseScanner(
        source: source,
        start: valueStart,
        end: valueStart + value.length,
        context: savedContext,
        stripBlockSyntax: false,
      );
      _groups.addAll(scanner.scan());
      complete = complete && scanner.complete;
      _barrier();
    }
  }

  void _emit(
    String logical,
    int sourceStart,
    int sourceEnd,
    SpellingTransformationKind transformation,
  ) {
    if (logical.isEmpty) return;
    final logicalStart = _text.length;
    _text.write(logical);
    _atoms.add(
      SpellingSourceAtom(
        logicalText: logical,
        logicalStart: logicalStart,
        logicalEnd: _text.length,
        sourceStart: sourceStart,
        sourceEnd: sourceEnd,
        transformation: transformation,
        context: context,
      ),
    );
  }

  void _barrier() => _flush();

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
          ),
        );
      }
      _groups.add(
        _EmissionGroup(
          text: _text.toString(),
          atoms: _atoms,
          formattingWrappers: List.unmodifiable(wrappers),
        ),
      );
    }
    _text = StringBuffer();
    _atoms = [];
  }

  List<({int start, int contentEnd})> _lines() {
    final result = <({int start, int contentEnd})>[];
    var cursor = start;
    while (cursor < end) {
      var contentEnd = cursor;
      while (contentEnd < end &&
          source.codeUnitAt(contentEnd) != 0x0a &&
          source.codeUnitAt(contentEnd) != 0x0d) {
        contentEnd++;
      }
      result.add((start: cursor, contentEnd: contentEnd));
      if (contentEnd >= end) break;
      cursor = contentEnd + 1;
      if (source.codeUnitAt(contentEnd) == 0x0d &&
          cursor < end &&
          source.codeUnitAt(cursor) == 0x0a) {
        cursor++;
      }
    }
    return result;
  }

  int _runLength(int start, int end, int unit) {
    var cursor = start;
    while (cursor < end && source.codeUnitAt(cursor) == unit) {
      cursor++;
    }
    return cursor - start;
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

final class _RawFormattingWrapper {
  const _RawFormattingWrapper({
    required this.opening,
    required this.contentStart,
    required this.contentEnd,
    required this.closing,
  });

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
}) {
  final spans = <_SourceInterval>[];
  for (final parse in parses) {
    for (final entry in parse.ranges.entries) {
      if (!_opaqueInlineKinds.contains(entry.key.kind)) continue;
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

bool _commonMarkEscapableAsciiPunctuation(int unit) =>
    (unit >= 0x21 && unit <= 0x2f) ||
    (unit >= 0x3a && unit <= 0x40) ||
    (unit >= 0x5b && unit <= 0x60) ||
    (unit >= 0x7b && unit <= 0x7e);

bool _horizontalWhitespace(int unit) => unit == 0x20 || unit == 0x09;

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
final RegExp _plainUrl = RegExp(
  r'''(?:https?|ftp)://[^\s<>()]+|www\.[^\s<>()]+''',
  caseSensitive: false,
);
final RegExp _plainEmail = RegExp(
  r'''[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}''',
);
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
