import '../core/source_span.dart';
import '../markdown/busymark_document.dart';
import '../markdown/markdown_model.dart';
import '../markdown/markdown_parser.dart';
import 'ai_models.dart';

class AiMarkdownEditTarget {
  const AiMarkdownEditTarget({
    required this.scope,
    required this.editTarget,
    required this.editContext,
    required this.input,
    required this.replacementStart,
    required this.replacementEnd,
    required this.replacementOriginal,
    this.replacementPrefix = '',
    this.replacementSuffix = '',
    this.trimReplacementOutput = false,
  });

  final AiScope scope;
  final AiEditTargetKind editTarget;
  final AiEditContextKind editContext;
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

/// Resolves the target and disclosed context selected by the user to exact
/// Markdown source ranges.
class AiMarkdownEditResolver {
  const AiMarkdownEditResolver({MarkdownParser parser = const MarkdownParser()})
    : _parser = parser;

  final MarkdownParser _parser;

  AiMarkdownEditTarget resolve({
    required AiEditTargetKind editTarget,
    required AiEditContextKind editContext,
    required String source,
    required int selectionStart,
    required int selectionEnd,
    required int anchorOffset,
    String filePath = 'ai-source.md',
  }) {
    if (selectionStart < 0 ||
        selectionEnd < selectionStart ||
        selectionEnd > source.length ||
        anchorOffset < 0 ||
        anchorOffset > source.length) {
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
    final targetRange = switch (editTarget) {
      AiEditTargetKind.selection =>
        hasSelection
            ? _safeSelectionRange(
                document,
                source,
                selectionStart,
                selectionEnd,
              )
            : throw const AiException(
                AiFailureCode.validation,
                'Select the Markdown content to replace first.',
              ),
      AiEditTargetKind.block => _blockRangeAt(blocks, anchorOffset),
      AiEditTargetKind.section => _sectionRangeAt(blocks, anchorOffset),
      AiEditTargetKind.document => _AiSourceRange(0, source.length),
      AiEditTargetKind.insertAfterBlock => _blockRangeAt(
        blocks,
        anchorOffset,
        allowPreviousAtBoundary: true,
      ),
    };
    final contextRange = switch (editContext) {
      AiEditContextKind.none => null,
      AiEditContextKind.selection =>
        hasSelection
            ? _AiSourceRange(selectionStart, selectionEnd)
            : throw const AiException(
                AiFailureCode.validation,
                'Select content before sharing the selection as AI context.',
              ),
      AiEditContextKind.block => _blockRangeAt(blocks, anchorOffset),
      AiEditContextKind.section => _sectionRangeAt(blocks, anchorOffset),
      AiEditContextKind.document => _AiSourceRange(0, source.length),
    };
    final input = contextRange == null
        ? ''
        : source.substring(contextRange.start, contextRange.end);
    if (editTarget == AiEditTargetKind.insertAfterBlock) {
      final insertion = blockInsertion(source, targetRange.end, blocks: blocks);
      return AiMarkdownEditTarget(
        scope: AiScope.markdownEdit,
        editTarget: editTarget,
        editContext: editContext,
        input: input,
        replacementStart: insertion.offset,
        replacementEnd: insertion.offset,
        replacementOriginal: '',
        replacementPrefix: insertion.prefix,
        replacementSuffix: insertion.suffix,
        trimReplacementOutput: true,
      );
    }
    final original = source.substring(targetRange.start, targetRange.end);
    return AiMarkdownEditTarget(
      scope: AiScope.markdownEdit,
      editTarget: editTarget,
      editContext: editContext,
      input: input,
      replacementStart: targetRange.start,
      replacementEnd: targetRange.end,
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

  _AiSourceRange _blockRangeAt(
    List<BusyBlock> blocks,
    int anchor, {
    bool allowPreviousAtBoundary = false,
  }) {
    BusyBlock? candidate;
    for (final block in blocks) {
      final span = block.sourceSpan!;
      if (anchor >= span.startOffset && anchor <= span.endOffset) {
        candidate = block;
        break;
      }
      if (allowPreviousAtBoundary && span.endOffset <= anchor) {
        candidate = block;
      }
    }
    if (candidate == null) {
      throw const AiException(
        AiFailureCode.validation,
        'Place the cursor inside the Markdown block to use.',
      );
    }
    final span = candidate.sourceSpan!;
    return _AiSourceRange(span.startOffset, span.endOffset);
  }

  _AiSourceRange _sectionRangeAt(List<BusyBlock> blocks, int anchor) {
    var headingIndex = -1;
    for (var index = 0; index < blocks.length; index += 1) {
      final block = blocks[index];
      final span = block.sourceSpan!;
      if (span.startOffset > anchor) {
        break;
      }
      if (block.kind == BusyBlockKind.heading) {
        headingIndex = index;
      }
    }
    if (headingIndex < 0) {
      throw const AiException(
        AiFailureCode.validation,
        'Place the cursor in a Markdown section that starts with a heading.',
      );
    }
    final heading = blocks[headingIndex];
    final level = int.tryParse(heading.attributes['level'] ?? '') ?? 1;
    var end = blocks.last.sourceSpan!.endOffset;
    for (final block in blocks.skip(headingIndex + 1)) {
      if (block.kind != BusyBlockKind.heading) {
        continue;
      }
      final nextLevel = int.tryParse(block.attributes['level'] ?? '') ?? 1;
      if (nextLevel <= level) {
        end = block.sourceSpan!.startOffset;
        break;
      }
    }
    return _AiSourceRange(heading.sourceSpan!.startOffset, end);
  }

  _AiSourceRange _safeSelectionRange(
    ParsedMarkdownDocument document,
    String source,
    int originalStart,
    int originalEnd,
  ) {
    final protected = <SourceSpan>[
      ...document.codeBlocks.map((block) => block.span),
      ...document.xmlBlocks.map((block) => block.span),
      if (_frontMatterRange(source) case final _AiSourceRange range)
        SourceSpan.fromOffsets(
          filePath: 'ai-source.md',
          source: source,
          startOffset: range.start,
          endOffset: range.end,
        ),
      ..._rawMarkupSpans(source),
      ..._inlineLinkSpans(source),
      ...document.variables.map((variable) => variable.span),
      ..._inlineCodeSpans(source),
      ..._referenceAndFootnoteSpans(source),
    ];
    for (final span in protected) {
      if (_intersects(span, originalStart, originalEnd) &&
          (originalStart > span.startOffset || originalEnd < span.endOffset)) {
        throw const AiException(
          AiFailureCode.validation,
          'The selected target cuts through protected Markdown. Select the complete construct or choose another target.',
        );
      }
    }
    return _AiSourceRange(originalStart, originalEnd);
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
}

class _AiSourceRange {
  const _AiSourceRange(this.start, this.end);

  final int start;
  final int end;
}
