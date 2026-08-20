import '../core/source_span.dart';
import '../markdown/busymark_document.dart';
import '../markdown/markdown_model.dart';
import '../markdown/markdown_parser.dart';
import 'ai_models.dart';

class AiMarkdownEditTarget {
  const AiMarkdownEditTarget({
    required this.scope,
    required this.input,
    required this.replacementStart,
    required this.replacementEnd,
    required this.replacementOriginal,
    this.replacementPrefix = '',
    this.replacementSuffix = '',
    this.trimReplacementOutput = false,
  });

  final AiScope scope;
  final String input;
  final int replacementStart;
  final int replacementEnd;
  final String replacementOriginal;
  final String replacementPrefix;
  final String replacementSuffix;
  final bool trimReplacementOutput;
}

class AiBlockInsertion {
  const AiBlockInsertion({
    required this.offset,
    required this.prefix,
    required this.suffix,
  });

  final int offset;
  final String prefix;
  final String suffix;
}

/// Resolves source-editor AI actions to ranges that cannot split a Markdown
/// block or a protected inline construct.
class AiMarkdownEditResolver {
  const AiMarkdownEditResolver({MarkdownParser parser = const MarkdownParser()})
    : _parser = parser;

  final MarkdownParser _parser;

  AiMarkdownEditTarget resolve({
    required AiFeature feature,
    required String source,
    required int selectionStart,
    required int selectionEnd,
    String filePath = 'ai-source.md',
  }) {
    if (selectionStart < 0 ||
        selectionEnd < selectionStart ||
        selectionEnd > source.length) {
      throw const AiException(
        AiFailureCode.validation,
        'The AI edit range is invalid.',
      );
    }
    final document = _parser.parse(
      filePath: filePath,
      source: source,
      mode: MarkdownMode.gfm,
      validateLocalReferences: false,
    );
    final blocks = _topLevelBlocks(document);
    final hasSelection = selectionStart != selectionEnd;

    if (feature == AiFeature.draft) {
      final insertion = blockInsertion(
        source,
        hasSelection ? selectionEnd : selectionStart,
        blocks: blocks,
      );
      final context = hasSelection
          ? source.substring(selectionStart, selectionEnd)
          : _nearbyContext(source, selectionStart, blocks);
      return AiMarkdownEditTarget(
        scope: AiScope.insertion,
        input: context,
        replacementStart: insertion.offset,
        replacementEnd: insertion.offset,
        replacementOriginal: '',
        replacementPrefix: insertion.prefix,
        replacementSuffix: insertion.suffix,
        trimReplacementOutput: true,
      );
    }

    if (feature == AiFeature.summarize) {
      if (!hasSelection) {
        final insertion = blockInsertion(
          source,
          selectionStart,
          blocks: blocks,
        );
        return AiMarkdownEditTarget(
          scope: AiScope.document,
          input: source,
          replacementStart: insertion.offset,
          replacementEnd: insertion.offset,
          replacementOriginal: '',
          replacementPrefix: insertion.prefix,
          replacementSuffix: insertion.suffix,
          trimReplacementOutput: true,
        );
      }
      _ensureNoHardProtectedSelection(
        document,
        source,
        selectionStart,
        selectionEnd,
      );
      final range = _wholeBlockRange(
        source,
        selectionStart,
        selectionEnd,
        blocks,
      );
      final original = source.substring(range.start, range.end);
      return AiMarkdownEditTarget(
        scope: AiScope.selection,
        input: original,
        replacementStart: range.start,
        replacementEnd: range.end,
        replacementOriginal: original,
      );
    }

    if (!hasSelection) {
      throw const AiException(
        AiFailureCode.validation,
        'Select the Markdown prose to edit first.',
      );
    }

    final range = _safeSelectionRange(
      document,
      source,
      selectionStart,
      selectionEnd,
    );
    final original = source.substring(range.start, range.end);
    return AiMarkdownEditTarget(
      scope: AiScope.selection,
      input: original,
      replacementStart: range.start,
      replacementEnd: range.end,
      replacementOriginal: original,
    );
  }

  AiBlockInsertion blockInsertion(
    String source,
    int requestedOffset, {
    List<BusyBlock>? blocks,
  }) {
    final parsedBlocks =
        blocks ??
        _topLevelBlocks(
          _parser.parse(
            filePath: 'ai-source.md',
            source: source,
            mode: MarkdownMode.gfm,
            validateLocalReferences: false,
          ),
        );
    var offset = requestedOffset.clamp(0, source.length).toInt();
    final frontMatter = _frontMatterRange(source);
    if (frontMatter != null && offset < frontMatter.end) {
      offset = frontMatter.end;
    }
    for (final block in parsedBlocks) {
      final span = block.sourceSpan;
      if (span == null) {
        continue;
      }
      if (offset > span.startOffset && offset < span.endOffset) {
        offset = span.endOffset;
        break;
      }
    }
    if (offset > 0 && offset < source.length && source[offset - 1] != '\n') {
      final newline = source.indexOf('\n', offset);
      offset = newline < 0 ? source.length : newline + 1;
    }
    while (offset < source.length &&
        (source.codeUnitAt(offset) == 0x0a ||
            source.codeUnitAt(offset) == 0x0d)) {
      offset += 1;
    }

    final newline = source.contains('\r\n') ? '\r\n' : '\n';
    final before = source.substring(0, offset);
    final after = source.substring(offset);
    final prefix = before.isEmpty || before.endsWith('$newline$newline')
        ? ''
        : before.endsWith(newline)
        ? newline
        : '$newline$newline';
    final suffix = after.isEmpty || after.startsWith('$newline$newline')
        ? ''
        : after.startsWith(newline)
        ? newline
        : '$newline$newline';
    return AiBlockInsertion(offset: offset, prefix: prefix, suffix: suffix);
  }

  List<BusyBlock> _topLevelBlocks(ParsedMarkdownDocument document) {
    final blocks = [
      for (final block in document.busyDocument.blocks)
        if (block.sourceSpan != null) block,
    ];
    blocks.sort(
      (left, right) =>
          left.sourceSpan!.startOffset.compareTo(right.sourceSpan!.startOffset),
    );
    return blocks;
  }

  String _nearbyContext(String source, int cursor, List<BusyBlock> blocks) {
    BusyBlock? candidate;
    for (final block in blocks) {
      final span = block.sourceSpan!;
      if (cursor >= span.startOffset && cursor <= span.endOffset) {
        candidate = block;
        break;
      }
      if (span.endOffset <= cursor) {
        candidate = block;
      }
    }
    if (candidate == null || _isUnsafeContextBlock(candidate.kind)) {
      return '';
    }
    final span = candidate.sourceSpan!;
    return source.substring(span.startOffset, span.endOffset).trim();
  }

  bool _isUnsafeContextBlock(BusyBlockKind kind) => switch (kind) {
    BusyBlockKind.codeBlock ||
    BusyBlockKind.frontMatter ||
    BusyBlockKind.htmlBlock ||
    BusyBlockKind.table ||
    BusyBlockKind.writersideAdmonition ||
    BusyBlockKind.writersideTabs ||
    BusyBlockKind.writersideProcedure ||
    BusyBlockKind.writersideRawXml => true,
    _ => false,
  };

  _AiSourceRange _wholeBlockRange(
    String source,
    int start,
    int end,
    List<BusyBlock> blocks,
  ) {
    final intersecting = [
      for (final block in blocks)
        if (_intersects(block.sourceSpan!, start, end)) block.sourceSpan!,
    ];
    if (intersecting.isEmpty) {
      return _lineRange(source, start, end);
    }
    return _AiSourceRange(
      intersecting.first.startOffset,
      intersecting.last.endOffset,
    );
  }

  _AiSourceRange _safeSelectionRange(
    ParsedMarkdownDocument document,
    String source,
    int originalStart,
    int originalEnd,
  ) {
    var start = originalStart;
    var end = originalEnd;
    _ensureNoHardProtectedSelection(document, source, start, end);

    final expandable = <SourceSpan>[
      ..._inlineLinkSpans(source),
      ...document.variables.map((variable) => variable.span),
      ..._inlineCodeSpans(source),
      ..._referenceAndFootnoteSpans(source),
    ];
    var changed = true;
    while (changed) {
      changed = false;
      for (final span in expandable) {
        if (!_intersects(span, start, end)) {
          continue;
        }
        final nextStart = start < span.startOffset ? start : span.startOffset;
        final nextEnd = end > span.endOffset ? end : span.endOffset;
        if (nextStart != start || nextEnd != end) {
          start = nextStart;
          end = nextEnd;
          changed = true;
        }
      }
    }
    return _AiSourceRange(start, end);
  }

  void _ensureNoHardProtectedSelection(
    ParsedMarkdownDocument document,
    String source,
    int start,
    int end,
  ) {
    final hardProtected = <SourceSpan>[
      ...document.codeBlocks.map((block) => block.span),
      ...document.xmlBlocks.map((block) => block.span),
      if (_frontMatterRange(source) case final _AiSourceRange range)
        SourceSpan.fromOffsets(
          filePath: 'ai-source.md',
          source: source,
          startOffset: range.start,
          endOffset: range.end,
        ),
      for (final block in document.busyDocument.blocks)
        if (_isUnsafeContextBlock(block.kind) && block.sourceSpan != null)
          block.sourceSpan!,
      ..._rawMarkupSpans(source),
    ];
    for (final span in hardProtected) {
      if (_intersects(span, start, end)) {
        throw const AiException(
          AiFailureCode.validation,
          'This selection intersects protected Markdown. Select complete prose blocks or use the dedicated code action.',
        );
      }
    }
  }

  List<SourceSpan> _inlineCodeSpans(String source) {
    final result = <SourceSpan>[];
    final fenced = _fencedRanges(source);
    var index = 0;
    while (index < source.length) {
      if (_insideAny(index, fenced) || source.codeUnitAt(index) != 0x60) {
        index += 1;
        continue;
      }
      final start = index;
      while (index < source.length && source.codeUnitAt(index) == 0x60) {
        index += 1;
      }
      final marker = '`' * (index - start);
      final closing = source.indexOf(marker, index);
      if (closing < 0 || source.substring(index, closing).contains('\n')) {
        continue;
      }
      result.add(
        SourceSpan.fromOffsets(
          filePath: 'ai-source.md',
          source: source,
          startOffset: start,
          endOffset: closing + marker.length,
        ),
      );
      index = closing + marker.length;
    }
    return result;
  }

  List<SourceSpan> _inlineLinkSpans(String source) {
    final result = <SourceSpan>[];
    final fenced = _fencedRanges(source);
    var index = 0;
    while (index < source.length) {
      final image =
          source.codeUnitAt(index) == 0x21 &&
          index + 1 < source.length &&
          source.codeUnitAt(index + 1) == 0x5b;
      final opening = image ? index + 1 : index;
      if (_insideAny(index, fenced) ||
          source.codeUnitAt(opening) != 0x5b ||
          _isEscaped(source, opening)) {
        index += 1;
        continue;
      }
      final labelEnd = _matchingDelimiter(source, opening, 0x5b, 0x5d);
      if (labelEnd == null || labelEnd + 1 >= source.length) {
        index += 1;
        continue;
      }
      final next = source.codeUnitAt(labelEnd + 1);
      final closing = switch (next) {
        0x28 => _matchingDelimiter(source, labelEnd + 1, 0x28, 0x29),
        0x5b => _matchingDelimiter(source, labelEnd + 1, 0x5b, 0x5d),
        _ => null,
      };
      if (closing == null) {
        index += 1;
        continue;
      }
      result.add(
        SourceSpan.fromOffsets(
          filePath: 'ai-source.md',
          source: source,
          startOffset: index,
          endOffset: closing + 1,
        ),
      );
      index = closing + 1;
    }
    return result;
  }

  int? _matchingDelimiter(
    String source,
    int opening,
    int openingCodeUnit,
    int closingCodeUnit,
  ) {
    var depth = 0;
    for (var index = opening; index < source.length; index += 1) {
      final codeUnit = source.codeUnitAt(index);
      if (codeUnit == 0x0a || codeUnit == 0x0d) {
        return null;
      }
      if (_isEscaped(source, index)) {
        continue;
      }
      if (codeUnit == openingCodeUnit) {
        depth += 1;
      } else if (codeUnit == closingCodeUnit) {
        depth -= 1;
        if (depth == 0) {
          return index;
        }
      }
    }
    return null;
  }

  bool _isEscaped(String source, int offset) {
    var slashes = 0;
    for (
      var index = offset - 1;
      index >= 0 && source.codeUnitAt(index) == 0x5c;
      index -= 1
    ) {
      slashes += 1;
    }
    return slashes.isOdd;
  }

  List<SourceSpan> _rawMarkupSpans(String source) => [
    for (final match in RegExp(r'<[^>\n]+>').allMatches(source))
      SourceSpan.fromOffsets(
        filePath: 'ai-source.md',
        source: source,
        startOffset: match.start,
        endOffset: match.end,
      ),
  ];

  List<SourceSpan> _referenceAndFootnoteSpans(String source) => [
    for (final match in RegExp(
      r'^\s{0,3}\[(?:\^)?[^\]\n]+\]:[^\n]*$',
      multiLine: true,
    ).allMatches(source))
      SourceSpan.fromOffsets(
        filePath: 'ai-source.md',
        source: source,
        startOffset: match.start,
        endOffset: match.end,
      ),
  ];

  List<_AiSourceRange> _fencedRanges(String source) => [
    for (final block
        in _parser
            .parse(
              filePath: 'ai-source.md',
              source: source,
              mode: MarkdownMode.gfm,
              validateLocalReferences: false,
            )
            .codeBlocks)
      _AiSourceRange(block.span.startOffset, block.span.endOffset),
  ];

  _AiSourceRange? _frontMatterRange(String source) {
    final opening = RegExp(r'^---[ \t]*(?:\r?\n)').firstMatch(source);
    if (opening == null) {
      return null;
    }
    final closing = RegExp(
      r'^(?:---|\.\.\.)[ \t]*(?:\r?\n|$)',
      multiLine: true,
    ).firstMatch(source.substring(opening.end));
    if (closing == null) {
      return null;
    }
    return _AiSourceRange(0, opening.end + closing.end);
  }

  bool _insideAny(int offset, List<_AiSourceRange> ranges) =>
      ranges.any((range) => offset >= range.start && offset < range.end);

  bool _intersects(SourceSpan span, int start, int end) =>
      start < span.endOffset && end > span.startOffset;

  _AiSourceRange _lineRange(String source, int start, int end) {
    final lineStart = start == 0 ? 0 : source.lastIndexOf('\n', start - 1) + 1;
    final newline = source.indexOf('\n', end);
    final lineEnd = newline < 0 ? source.length : newline;
    return _AiSourceRange(lineStart, lineEnd);
  }
}

class _AiSourceRange {
  const _AiSourceRange(this.start, this.end);

  final int start;
  final int end;
}
