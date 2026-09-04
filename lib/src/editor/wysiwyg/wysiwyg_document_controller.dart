import 'package:flutter/foundation.dart';

import '../../core/path_utils.dart';
import '../../core/source_span.dart';
import '../../markdown/busymark_document.dart';
import '../../markdown/busymark_markdown_serializer.dart';
import '../../markdown/markdown_model.dart';
import '../../markdown/markdown_parser.dart';
import '../../markdown/math_syntax.dart';
import '../../markdown/raw_html_adapter.dart';
import 'wysiwyg_commands.dart';
import 'wysiwyg_inline_controller.dart';

/// Markdown table cells are represented by one source line. Normalize all
/// platform newline forms at the model boundary so programmatic callers cannot
/// create content that the table serializer cannot faithfully represent.
String busyMarkNormalizeTableCellText(String text) {
  return text.replaceAll(RegExp(r'\r\n|\r|\n'), ' ');
}

BusyBlock busyMarkWysiwygImmutableBlockSnapshot(BusyBlock block) {
  BusyInline snapshotInline(BusyInline inline) {
    return BusyInline(
      kind: inline.kind,
      text: inline.text,
      destination: inline.destination,
      children: List.unmodifiable([
        for (final child in inline.children) snapshotInline(child),
      ]),
      attributes: Map.unmodifiable(inline.attributes),
    );
  }

  return BusyBlock(
    id: block.id,
    kind: block.kind,
    inlines: List.unmodifiable([
      for (final inline in block.inlines) snapshotInline(inline),
    ]),
    children: List.unmodifiable([
      for (final child in block.children)
        busyMarkWysiwygImmutableBlockSnapshot(child),
    ]),
    attributes: Map.unmodifiable(block.attributes),
    rawSource: block.rawSource,
    sourceSpan: block.sourceSpan,
    preserveRaw: block.preserveRaw,
    isSourceOnly: block.isSourceOnly,
    isGenerated: block.isGenerated,
    isSourceProtected: block.isSourceProtected,
    dirty: block.dirty,
  );
}

class BusyMarkWysiwygDocumentController extends ChangeNotifier {
  BusyMarkWysiwygDocumentController({
    required BusyDocument document,
    BusyMarkMarkdownSerializer serializer = const BusyMarkMarkdownSerializer(),
  }) : _document = _ensureEditableDocument(document),
       _serializer = serializer;

  BusyDocument _document;
  final BusyMarkMarkdownSerializer _serializer;
  int _generatedBlockIndex = 0;

  BusyDocument get document => _document;

  String get markdown => _serializer.serialize(_document);

  void replaceDocument(BusyDocument document) {
    _document = _ensureEditableDocument(document);
    notifyListeners();
  }

  String blockText(String blockId) {
    final block = blockById(blockId);
    return block == null ? '' : busyMarkWysiwygEditableText(block);
  }

  String _sourceWithBlockStructure(BusyBlock block, String source) {
    final prefix = switch (block.kind) {
      BusyBlockKind.heading =>
        '${'#' * (int.tryParse(block.attributes['level'] ?? '') ?? 1)} ',
      BusyBlockKind.unorderedListItem =>
        '${block.attributes['marker'] ?? '-'} ',
      BusyBlockKind.orderedListItem => '${block.attributes['marker'] ?? '1.'} ',
      BusyBlockKind.taskListItem =>
        '${block.attributes['ordered'] == 'true' ? block.attributes['marker'] ?? '1.' : '-'} '
            '[${block.attributes['task'] == 'true' ? 'x' : ' '}] ',
      BusyBlockKind.blockquote => '> ',
      _ => '',
    };
    return '$prefix$source';
  }

  void updateMathSource(String blockId, String source) {
    final current = blockById(blockId);
    if (current == null) {
      return;
    }
    final parsed = const MarkdownParser().parse(
      filePath: _document.filePath,
      source: _sourceWithBlockStructure(current, source),
      mode: _document.mode,
      validateLocalReferences: false,
    );
    final parsedBlocks = parsed.busyDocument.blocks
        .where(
          (block) =>
              block.kind != BusyBlockKind.frontMatter && !block.isSourceOnly,
        )
        .toList(growable: false);
    final replacements = parsedBlocks.isEmpty
        ? [
            BusyBlock(
              id: current.id,
              kind: BusyBlockKind.paragraph,
              inlines: [BusyInline(kind: BusyInlineKind.text, text: source)],
              sourceSpan: current.sourceSpan,
              dirty: true,
            ),
          ]
        : [
            for (final (index, parsedBlock) in parsedBlocks.indexed)
              BusyBlock(
                id: index == 0
                    ? current.id
                    : _nextGeneratedBlockId('math-edit'),
                kind: parsedBlock.kind,
                inlines: parsedBlock.inlines,
                children: index == 0 ? current.children : parsedBlock.children,
                attributes: _mathEditedBlockAttributes(
                  current,
                  parsedBlock,
                  firstReplacement: index == 0,
                ),
                rawSource: parsedBlock.rawSource,
                sourceSpan: index == 0 ? current.sourceSpan : null,
                preserveRaw: false,
                dirty: true,
              ),
          ];
    _document = _document.copyWith(
      blocks: _replaceBlockWithMany(_document.blocks, blockId, replacements),
    );
    notifyListeners();
  }

  ({int selectionStart, int selectionEnd})? insertInlineMath(
    String blockId,
    int selectionStart,
    int selectionEnd, {
    String fallbackExpression = 'x',
  }) {
    final current = blockById(blockId);
    if (current == null || busyMarkWysiwygBlockContainsMath(current)) {
      return null;
    }
    final text = current.plainText;
    final rawStart = selectionStart < selectionEnd
        ? selectionStart
        : selectionEnd;
    final rawEnd = selectionStart < selectionEnd
        ? selectionEnd
        : selectionStart;
    final start = rawStart.clamp(0, text.length).toInt();
    final end = rawEnd.clamp(start, text.length).toInt();
    final rawExpression = start == end
        ? fallbackExpression
        : text.substring(start, end);
    final parts = _inlineMathExpressionParts(rawExpression);
    if (parts == null) {
      return null;
    }
    final collapsed = start == end;
    final contentStart = collapsed ? start : start + parts.leading.length;
    final contentEnd = collapsed ? end : end - parts.trailing.length;
    final partition = _partitionInlinesForReplacement(
      current.inlines,
      contentStart,
      contentEnd,
    );
    final before = [
      ...partition.before,
      if (collapsed && parts.leading.isNotEmpty)
        BusyInline(kind: BusyInlineKind.text, text: parts.leading),
    ];
    final after = [
      if (collapsed && parts.trailing.isNotEmpty)
        BusyInline(kind: BusyInlineKind.text, text: parts.trailing),
      ...partition.after,
    ];
    BusyInline? math;
    List<BusyInline>? inlines;
    for (final form in const [
      BusyMathSourceForm.dollarInline,
      BusyMathSourceForm.githubDollarBacktick,
    ]) {
      final candidate = _inlineMath(parts.expression, form);
      final candidateInlines = [...before, candidate, ...after];
      if (_serializedInlineMathParses(
        candidateInlines,
        mode: _document.mode,
        serializer: _serializer,
      )) {
        math = candidate;
        inlines = candidateInlines;
        break;
      }
    }
    if (math == null || inlines == null) {
      return null;
    }
    final updated = current.copyWith(
      inlines: inlines,
      attributes: _attributesAfterInlineMathEdit(current, inlines),
      preserveRaw: false,
      dirty: true,
    );
    _document = _document.copyWith(
      blocks: _replaceInBlocks(_document.blocks, blockId, (_) => updated),
    );
    final prefixSource = _serializer.serializeBlock(
      BusyBlock(
        id: 'wysiwyg-math-prefix',
        kind: BusyBlockKind.paragraph,
        inlines: before,
        dirty: true,
      ),
    );
    final form = busyMathSourceFormFromName(
      math.attributes[busyMarkMathSourceFormAttribute],
    );
    final openingLength = form == BusyMathSourceForm.githubDollarBacktick
        ? 2
        : 1;
    notifyListeners();
    return (
      selectionStart: prefixSource.length + openingLength,
      selectionEnd:
          prefixSource.length + openingLength + parts.expression.length,
    );
  }

  ({String source, int selectionStart, int selectionEnd})?
  buildInlineMathSourceInsertion(
    String blockId,
    String source,
    int selectionStart,
    int selectionEnd, {
    String fallbackExpression = 'x',
  }) {
    final current = blockById(blockId);
    if (current == null) {
      return null;
    }
    final rawStart = selectionStart < selectionEnd
        ? selectionStart
        : selectionEnd;
    final rawEnd = selectionStart < selectionEnd
        ? selectionEnd
        : selectionStart;
    final start = rawStart.clamp(0, source.length).toInt();
    final end = rawEnd.clamp(start, source.length).toInt();
    final collapsed = start == end;
    final rawExpression = collapsed
        ? fallbackExpression
        : source.substring(start, end);
    final parts = _inlineMathExpressionParts(rawExpression);
    if (parts == null) {
      return null;
    }
    final replaceStart = collapsed ? start : start + parts.leading.length;
    final replaceEnd = collapsed ? end : end - parts.trailing.length;
    final existing = _parseMathEditSource(current, source);
    final existingMath = _mathInlineCount(existing);
    for (final form in const [
      BusyMathSourceForm.dollarInline,
      BusyMathSourceForm.githubDollarBacktick,
    ]) {
      final mathSource = _inlineMathSource(parts.expression, form);
      final replacement = collapsed
          ? '${parts.leading}$mathSource${parts.trailing}'
          : mathSource;
      final candidate = source.replaceRange(
        replaceStart,
        replaceEnd,
        replacement,
      );
      final parsed = _parseMathEditSource(current, candidate);
      final validationExpression = _uniqueMathValidationExpression(
        source,
        parts.expression,
      );
      final validationSource = _inlineMathSource(validationExpression, form);
      final validationReplacement = collapsed
          ? '${parts.leading}$validationSource${parts.trailing}'
          : validationSource;
      final validationCandidate = source.replaceRange(
        replaceStart,
        replaceEnd,
        validationReplacement,
      );
      final validationParsed = _parseMathEditSource(
        current,
        validationCandidate,
      );
      final expectedInlines = _singleEditableBlockInlines(validationParsed);
      final actualInlines = _singleEditableBlockInlines(parsed);
      if (_mathInlineCount(validationParsed) != existingMath + 1 ||
          _matchingMathInlineCount(
                validationParsed,
                expression: validationExpression,
                form: form,
              ) !=
              1 ||
          expectedInlines == null ||
          actualInlines == null ||
          !_inlineListsSemanticallyEqual(
            _replaceValidationMath(
              expectedInlines,
              validationExpression: validationExpression,
              expression: parts.expression,
              form: form,
            ),
            actualInlines,
          )) {
        continue;
      }
      final expressionStart =
          replaceStart +
          (collapsed ? parts.leading.length : 0) +
          (form == BusyMathSourceForm.githubDollarBacktick ? 2 : 1);
      return (
        source: candidate,
        selectionStart: expressionStart,
        selectionEnd: expressionStart + parts.expression.length,
      );
    }
    return null;
  }

  BusyDocument _parseMathEditSource(BusyBlock current, String source) {
    return const MarkdownParser()
        .parse(
          filePath: _document.filePath,
          source: _sourceWithBlockStructure(current, source),
          mode: _document.mode,
          validateLocalReferences: false,
        )
        .busyDocument;
  }

  String? insertDisplayMathAfter(String blockId, {String expression = 'x'}) {
    if (blockById(blockId) == null) {
      return null;
    }
    final mathId = _nextGeneratedBlockId('math');
    final paragraphId = _nextGeneratedBlockId('paragraph');
    _document = _document.copyWith(
      blocks: _insertBlocksAfter(_document.blocks, blockId, [
        BusyBlock(
          id: mathId,
          kind: BusyBlockKind.math,
          inlines: [
            BusyInline(
              kind: BusyInlineKind.math,
              text: expression,
              attributes: {
                busyMarkMathExpressionAttribute: expression,
                busyMarkMathDisplayAttribute: 'true',
                busyMarkMathSourceFormAttribute:
                    BusyMathSourceForm.doubleDollarDisplay.name,
              },
            ),
          ],
          attributes: {
            busyMarkMathExpressionAttribute: expression,
            busyMarkMathDisplayAttribute: 'true',
            busyMarkMathSourceFormAttribute:
                BusyMathSourceForm.doubleDollarDisplay.name,
          },
          rawSource: '\$\$\n$expression\n\$\$',
          preserveRaw: false,
          dirty: true,
        ),
        BusyBlock(
          id: paragraphId,
          kind: BusyBlockKind.paragraph,
          inlines: _textInlines(''),
          attributes: const {busyMarkPreserveEmptyParagraphAttribute: 'true'},
          dirty: true,
        ),
      ]),
    );
    notifyListeners();
    return mathId;
  }

  BusyBlock? blockById(String blockId) {
    for (final block in _flatten(_document.blocks)) {
      if (block.id == blockId) {
        return block;
      }
    }
    return null;
  }

  String admonitionTargetId(String blockId) {
    String? target;

    void visit(List<BusyBlock> blocks, BusyBlock? enclosingAdmonition) {
      for (final block in blocks) {
        final isAdmonition =
            block.kind == BusyBlockKind.writersideAdmonition ||
            block.attributes[busyMarkWritersideAdmonitionAttribute] == 'true';
        final nextEnclosing = isAdmonition ? block : enclosingAdmonition;
        if (block.id == blockId) {
          target = nextEnclosing?.id ?? blockId;
          return;
        }
        visit(block.children, nextEnclosing);
        if (target != null) {
          return;
        }
      }
    }

    visit(_document.blocks, null);
    return target ?? blockId;
  }

  void updateBlockText(
    String blockId,
    String text, {
    Iterable<BusyInlineKind> activeInlineKinds = const [],
  }) {
    _replaceBlock(
      blockId,
      (block) => _blockWithEditedText(
        block,
        text,
        activeInlineKinds: activeInlineKinds,
      ),
    );
  }

  void updateTableCellText(String tableBlockId, String cellId, String text) {
    final acceptedText = busyMarkNormalizeTableCellText(text);
    var changed = false;
    _document = _document.copyWith(
      blocks: _replaceInBlocks(_document.blocks, tableBlockId, (block) {
        if (block.kind != BusyBlockKind.table) {
          return block;
        }
        final rows = <BusyBlock>[];
        for (final row in block.children) {
          var rowChanged = false;
          final cells = <BusyBlock>[];
          for (final cell in row.children) {
            if (cell.id == cellId) {
              cells.add(_tableCellWithEditedSource(cell, acceptedText));
              rowChanged = true;
              changed = true;
            } else {
              cells.add(cell);
            }
          }
          rows.add(
            rowChanged ? row.copyWith(children: cells, dirty: true) : row,
          );
        }
        if (!changed) {
          return block;
        }
        return block.copyWith(children: rows, preserveRaw: false, dirty: true);
      }),
    );
    if (changed) {
      notifyListeners();
    }
  }

  BusyBlock _tableCellWithEditedSource(BusyBlock cell, String source) {
    final parsed = const MarkdownParser().parse(
      filePath: _document.filePath,
      source: '$source\n',
      mode: _document.mode,
      validateLocalReferences: false,
    );
    final parsedBlock = parsed.busyDocument.blocks
        .where(
          (block) =>
              block.kind != BusyBlockKind.frontMatter && !block.isSourceOnly,
        )
        .firstOrNull;
    final inlines = parsedBlock?.inlines;
    return cell.copyWith(
      inlines: inlines == null || inlines.isEmpty
          ? _textInlines(source)
          : inlines,
      preserveRaw: false,
      dirty: true,
    );
  }

  BusyWysiwygTextSplitResult? replaceBlockTextWithParagraphs(
    String blockId,
    String text,
    int cursorOffset,
  ) {
    final normalizedText = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    if (!normalizedText.contains('\n')) {
      return null;
    }
    final block = blockById(blockId);
    if (block == null || !_shouldSplitNewlines(block.kind)) {
      return null;
    }
    if (_isListItemKind(block.kind) && normalizedText.trim().isEmpty) {
      _replaceBlockWithParagraph(blockId);
      return BusyWysiwygTextSplitResult(blockId: blockId, offset: 0);
    }
    final parts = normalizedText.split('\n');
    final safeOffset = cursorOffset.clamp(0, normalizedText.length).toInt();
    final textBeforeCursor = normalizedText.substring(0, safeOffset);
    final focusIndex = '\n'
        .allMatches(textBeforeCursor)
        .length
        .clamp(0, parts.length - 1)
        .toInt();
    final lastLineStart = textBeforeCursor.lastIndexOf('\n') + 1;
    final focusOffset = safeOffset - lastLineStart;
    final ranges = _remapRangesForTextEdit(
      oldText: block.plainText,
      newText: normalizedText,
      ranges: busyInlineStyleRanges(block.inlines),
    );
    final replacements = <BusyBlock>[];
    var lineStart = 0;
    for (final (index, part) in parts.indexed) {
      final lineEnd = lineStart + part.length;
      final inlines = _inlinesFromStyleRanges(
        part,
        _styleRangesForSlice(ranges, lineStart, lineEnd),
      );
      if (index == 0) {
        replacements.add(
          block.copyWith(
            inlines: inlines,
            attributes: _attributesForText(block.attributes, block.kind, part),
            preserveRaw: false,
            dirty: true,
          ),
        );
      } else {
        final splitKind = _splitKindFor(block.kind);
        replacements.add(
          BusyBlock(
            id: _nextGeneratedBlockId(_newBlockPrefixFor(block.kind)),
            kind: splitKind,
            inlines: inlines,
            attributes: _attributesForText(
              _splitAttributesFor(block, splitKind, orderedOffset: index),
              splitKind,
              part,
            ),
            dirty: true,
          ),
        );
      }
      lineStart = lineEnd + 1;
    }
    _document = _document.copyWith(
      blocks: _replaceBlockWithMany(_document.blocks, blockId, replacements),
    );
    notifyListeners();
    return BusyWysiwygTextSplitResult(
      blockId: replacements[focusIndex].id,
      offset: focusOffset
          .clamp(0, replacements[focusIndex].plainText.length)
          .toInt(),
    );
  }

  void applyBlockCommand(String blockId, BusyWysiwygBlockCommand command) {
    final block = blockById(blockId);
    if (block == null || !busyMarkWysiwygCanApplyBlockCommand(block, command)) {
      return;
    }
    if (command == BusyWysiwygBlockCommand.thematicBreak) {
      insertThematicBreakAfter(blockId);
      return;
    }
    final blocks = _replaceInBlocks(
      _document.blocks,
      blockId,
      (block) => _blockWithCommand(block, command),
    );
    _document = _document.copyWith(
      blocks: command == BusyWysiwygBlockCommand.orderedList
          ? _normalizeOrderedListMarkers(blocks)
          : blocks,
    );
    notifyListeners();
  }

  void applyBlockCommandToBlocks(
    Iterable<String> blockIds,
    BusyWysiwygBlockCommand command,
  ) {
    final ids = blockIds.toList();
    if (ids.isEmpty) {
      return;
    }
    final eligibleIds = ids.where((id) {
      final block = blockById(id);
      return block != null &&
          busyMarkWysiwygCanApplyBlockCommand(block, command);
    }).toList();
    if (eligibleIds.isEmpty) {
      return;
    }
    if (command == BusyWysiwygBlockCommand.thematicBreak) {
      insertThematicBreakAfter(eligibleIds.last);
      return;
    }
    final idSet = eligibleIds.toSet();
    final replaced = _replaceBlocksByIds(_document.blocks, idSet, (block) {
      return _blockWithCommand(block, command);
    });
    _document = _document.copyWith(
      blocks: command == BusyWysiwygBlockCommand.orderedList
          ? _normalizeOrderedListMarkers(replaced)
          : replaced,
    );
    notifyListeners();
  }

  void applyAdmonitionStyle(String blockId, BusyAdmonitionStyle style) {
    final block = blockById(blockId);
    if (block == null || !busyMarkWysiwygCanApplyAdmonitionStyle(block)) {
      return;
    }
    _document = _document.copyWith(
      blocks: _replaceInBlocks(
        _document.blocks,
        blockId,
        (block) => _blockWithAdmonitionStyle(block, style),
      ),
    );
    notifyListeners();
  }

  void applyAdmonitionStyleToBlocks(
    Iterable<String> blockIds,
    BusyAdmonitionStyle style,
  ) {
    final ids = {
      for (final id in blockIds)
        if (blockById(id) case final block?
            when busyMarkWysiwygCanApplyAdmonitionStyle(block))
          id,
    };
    if (ids.isEmpty) {
      return;
    }
    _document = _document.copyWith(
      blocks: _replaceBlocksByIds(
        _document.blocks,
        ids,
        (block) => _blockWithAdmonitionStyle(block, style),
      ),
    );
    notifyListeners();
  }

  void applyImageBlock(
    String blockId, {
    required String source,
    required String alt,
  }) {
    final block = blockById(blockId);
    if (block == null ||
        !busyMarkWysiwygCanApplyBlockCommand(
          block,
          BusyWysiwygBlockCommand.image,
        )) {
      return;
    }
    final trimmedSource = source.trim();
    final trimmedAlt = alt.trim();
    if (trimmedSource.isEmpty) {
      return;
    }
    _replaceBlock(
      blockId,
      (block) => block.copyWith(
        kind: BusyBlockKind.image,
        inlines: [
          BusyInline(
            kind: BusyInlineKind.image,
            text: trimmedAlt,
            destination: trimmedSource,
            attributes: {'src': trimmedSource, 'alt': trimmedAlt},
          ),
        ],
        attributes: {...block.attributes, 'src': trimmedSource},
        dirty: true,
      ),
    );
  }

  void insertInlineImage(
    String blockId, {
    required int selectionStart,
    required int selectionEnd,
    required String source,
    required String alt,
    required String fallbackAltText,
  }) {
    final trimmedSource = source.trim();
    if (trimmedSource.isEmpty) {
      return;
    }
    _replaceBlock(blockId, (block) {
      final text = block.plainText;
      final start = selectionStart
          .clamp(0, text.length)
          .toInt()
          .clamp(0, text.length);
      final end = selectionEnd
          .clamp(start, text.length)
          .toInt()
          .clamp(start, text.length);
      final selectedText = text.substring(start, end).trim();
      final altText = alt.trim().isNotEmpty
          ? alt.trim()
          : selectedText.isNotEmpty
          ? selectedText
          : fallbackAltText;
      final nextText = text.replaceRange(start, end, altText);
      final ranges =
          _styleRangesForReplacement(
            ranges: busyInlineStyleRanges(block.inlines),
            selectionStart: start,
            selectionEnd: end,
            replacementLength: altText.length,
          )..add(
            BusyInlineStyleRange(
              start: start,
              end: start + altText.length,
              kind: BusyInlineKind.image,
              destination: trimmedSource,
            ),
          );
      return block.copyWith(
        inlines: _inlinesFromStyleRangesWithHardBreaks(nextText, ranges),
        preserveRaw: false,
        dirty: true,
      );
    });
  }

  void insertHardBreak(String blockId, int offset) {
    _replaceBlock(blockId, (block) {
      final text = block.plainText;
      final safeOffset = offset.clamp(0, text.length).toInt();
      final nextText = text.replaceRange(safeOffset, safeOffset, '\n');
      final ranges = _styleRangesForReplacement(
        ranges: busyInlineStyleRanges(block.inlines),
        selectionStart: safeOffset,
        selectionEnd: safeOffset,
        replacementLength: 1,
      );
      return block.copyWith(
        inlines: _inlinesFromStyleRangesWithHardBreaks(nextText, ranges),
        preserveRaw: false,
        dirty: true,
      );
    });
  }

  String? insertTableAfter(
    String blockId, {
    required int columns,
    required int rows,
    required String Function(int columnNumber) headerTextForColumn,
    required String cellText,
  }) {
    if (blockById(blockId) == null) {
      return null;
    }
    final paragraphId = _nextGeneratedBlockId('paragraph');
    final tableBlock = _generatedTableBlock(
      id: _nextGeneratedBlockId('table'),
      columns: columns,
      rows: rows,
      headerTextForColumn: headerTextForColumn,
      cellText: cellText,
    );
    _document = _document.copyWith(
      blocks: _insertBlocksAfter(_document.blocks, blockId, [
        tableBlock,
        BusyBlock(
          id: paragraphId,
          kind: BusyBlockKind.paragraph,
          inlines: _textInlines(''),
          dirty: true,
        ),
      ]),
    );
    notifyListeners();
    return paragraphId;
  }

  String? insertRawHtmlBlockAfter(String blockId, String rawSource) {
    if (blockById(blockId) == null) {
      return null;
    }
    final paragraphId = _nextGeneratedBlockId('paragraph');
    _document = _document.copyWith(
      blocks: _insertBlocksAfter(_document.blocks, blockId, [
        _rawHtmlBlock(
          id: _nextGeneratedBlockId('html'),
          rawSource: rawSource,
          dirty: true,
        ),
        BusyBlock(
          id: paragraphId,
          kind: BusyBlockKind.paragraph,
          inlines: _textInlines(''),
          dirty: true,
        ),
      ]),
    );
    notifyListeners();
    return paragraphId;
  }

  void updateRawHtmlBlock(String blockId, String rawSource) {
    _replaceBlock(blockId, (block) {
      if (block.kind != BusyBlockKind.htmlBlock) {
        return block;
      }
      return _rawHtmlBlock(
        id: block.id,
        rawSource: rawSource,
        dirty: true,
      ).copyWith(sourceSpan: block.sourceSpan);
    });
  }

  void replaceTable(
    String blockId, {
    required int columns,
    required int rows,
    required String Function(int columnNumber) headerTextForColumn,
    required String cellText,
  }) {
    _replaceBlock(blockId, (block) {
      if (block.kind != BusyBlockKind.table) {
        return block;
      }
      return _generatedTableBlock(
        id: block.id,
        columns: columns,
        rows: rows,
        headerTextForColumn: headerTextForColumn,
        cellText: cellText,
        template: block,
      );
    });
  }

  void insertTableRow(
    String tableBlockId,
    int rowIndex, {
    required bool after,
  }) {
    _replaceBlock(tableBlockId, (block) {
      if (block.kind != BusyBlockKind.table) {
        return block;
      }
      final rows = block.children;
      final columnCount = _tableColumnCount(block);
      final safeRow = rows.isEmpty
          ? 0
          : rowIndex.clamp(0, rows.length - 1).toInt();
      final insertIndex = rows.isEmpty ? 0 : safeRow + (after ? 1 : 0);
      final alignments = [
        for (var column = 0; column < columnCount; column++)
          _tableColumnAlignment(block, column),
      ];
      final nextRows = [...rows]
        ..insert(
          insertIndex.clamp(0, rows.length).toInt(),
          _newTableRow(columnCount, alignments: alignments),
        );
      return block.copyWith(
        children: _normalizedTableRows(nextRows),
        preserveRaw: false,
        dirty: true,
      );
    });
  }

  void deleteTableRow(String tableBlockId, int rowIndex) {
    final table = blockById(tableBlockId);
    if (table == null || table.kind != BusyBlockKind.table) {
      return;
    }
    final rows = table.children;
    if (rows.length <= 1) {
      deleteTable(tableBlockId);
      return;
    }
    _replaceBlock(tableBlockId, (block) {
      if (block.kind != BusyBlockKind.table) {
        return block;
      }
      final safeRow = rowIndex.clamp(0, block.children.length - 1).toInt();
      final nextRows = [
        for (final (index, row) in block.children.indexed)
          if (index != safeRow) row,
      ];
      return block.copyWith(
        children: _normalizedTableRows(nextRows),
        preserveRaw: false,
        dirty: true,
      );
    });
  }

  void insertTableColumn(
    String tableBlockId,
    int columnIndex, {
    required bool after,
  }) {
    _replaceBlock(tableBlockId, (block) {
      if (block.kind != BusyBlockKind.table) {
        return block;
      }
      final columnCount = _tableColumnCount(block);
      final safeColumn = columnIndex.clamp(0, columnCount - 1).toInt();
      final insertIndex = safeColumn + (after ? 1 : 0);
      final rows = [
        for (final row in block.children)
          row.copyWith(
            children: _cellsPaddedTo(row, columnCount)
              ..insert(
                insertIndex.clamp(0, columnCount).toInt(),
                _newTableCell(),
              ),
            dirty: true,
          ),
      ];
      return block.copyWith(
        children: _normalizedTableRows(rows),
        preserveRaw: false,
        dirty: true,
      );
    });
  }

  void deleteTableColumn(String tableBlockId, int columnIndex) {
    final table = blockById(tableBlockId);
    if (table == null || table.kind != BusyBlockKind.table) {
      return;
    }
    final columnCount = _tableColumnCount(table);
    if (columnCount <= 1) {
      deleteTable(tableBlockId);
      return;
    }
    _replaceBlock(tableBlockId, (block) {
      if (block.kind != BusyBlockKind.table) {
        return block;
      }
      final safeColumn = columnIndex.clamp(0, columnCount - 1).toInt();
      final rows = [
        for (final row in block.children)
          row.copyWith(
            children: [
              for (final (index, cell) in _cellsPaddedTo(
                row,
                columnCount,
              ).indexed)
                if (index != safeColumn) cell,
            ],
            dirty: true,
          ),
      ];
      return block.copyWith(
        children: _normalizedTableRows(rows),
        preserveRaw: false,
        dirty: true,
      );
    });
  }

  BusyTableAlignment tableColumnAlignment(
    String tableBlockId,
    int columnIndex,
  ) {
    final table = blockById(tableBlockId);
    if (table == null || table.kind != BusyBlockKind.table) {
      return BusyTableAlignment.unspecified;
    }
    return _tableColumnAlignment(table, columnIndex);
  }

  void setTableColumnAlignment(
    String tableBlockId,
    int columnIndex,
    BusyTableAlignment alignment,
  ) {
    _replaceBlock(tableBlockId, (block) {
      if (block.kind != BusyBlockKind.table) {
        return block;
      }
      final columnCount = _tableColumnCount(block);
      final safeColumn = columnIndex.clamp(0, columnCount - 1).toInt();
      final attribute = busyTableAlignmentAttribute(alignment);
      return block.copyWith(
        children: [
          for (final row in block.children)
            row.copyWith(
              children: [
                for (final (index, cell) in _cellsPaddedTo(
                  row,
                  columnCount,
                ).indexed)
                  if (index == safeColumn)
                    cell.copyWith(
                      attributes: {
                        for (final entry in cell.attributes.entries)
                          if (entry.key != 'align') entry.key: entry.value,
                        if (attribute != null) 'align': attribute,
                      },
                      dirty: true,
                    )
                  else
                    cell,
              ],
              dirty: true,
            ),
        ],
        preserveRaw: false,
        dirty: true,
      );
    });
  }

  void deleteTable(String tableBlockId) {
    final nextDocument = BusyDocument(
      filePath: _document.filePath,
      mode: _document.mode,
      title: _document.title,
      blocks: _removeBlockById(_document.blocks, tableBlockId),
      diagnostics: _document.diagnostics,
      frontMatter: _document.frontMatter,
      rawFrontMatter: _document.rawFrontMatter,
    );
    _document = nextDocument.copyWith(
      source: _serializer.serialize(nextDocument),
    );
    notifyListeners();
  }

  BusyBlock _rawHtmlBlock({
    required String id,
    required String rawSource,
    required bool dirty,
  }) {
    final result = const RawHtmlAdapter().parseRawHtmlBlock(
      rawSource,
      () => _nextGeneratedBlockId('html'),
    );
    return BusyBlock(
      id: id,
      kind: BusyBlockKind.htmlBlock,
      children: result?.safe == true ? result!.blocks : const [],
      attributes: const {'sourceFormat': 'html'},
      rawSource: rawSource,
      preserveRaw: true,
      dirty: dirty,
    );
  }

  BusyBlock _generatedTableBlock({
    required String id,
    required int columns,
    required int rows,
    required String Function(int columnNumber) headerTextForColumn,
    required String cellText,
    BusyBlock? template,
  }) {
    final safeColumns = columns.clamp(1, 12).toInt();
    final safeRows = rows.clamp(1, 50).toInt();
    BusyBlock tableRow(int rowIndex) {
      final header = rowIndex == 0;
      return BusyBlock(
        id: _nextGeneratedBlockId('table-row'),
        kind: BusyBlockKind.table,
        attributes: {'header': '$header'},
        children: [
          for (var column = 0; column < safeColumns; column++)
            BusyBlock(
              id: _nextGeneratedBlockId('table-cell'),
              kind: BusyBlockKind.paragraph,
              inlines: _textInlines(
                _tableCellText(template, rowIndex, column) ??
                    (header ? headerTextForColumn(column + 1) : cellText),
              ),
              attributes: {
                'cell': header ? 'th' : 'td',
                if (template != null)
                  if (busyTableAlignmentAttribute(
                        _tableColumnAlignment(template, column),
                      )
                      case final alignment?)
                    'align': alignment,
              },
              dirty: true,
            ),
        ],
        dirty: true,
      );
    }

    final tableBlock = BusyBlock(
      id: id,
      kind: BusyBlockKind.table,
      children: [
        tableRow(0),
        for (var row = 0; row < safeRows; row++) tableRow(row + 1),
      ],
      dirty: true,
    );
    return tableBlock.copyWith(
      rawSource: _serializer.serializeBlock(tableBlock),
    );
  }

  BusyBlock _newTableRow(
    int columns, {
    List<BusyTableAlignment> alignments = const [],
  }) {
    return BusyBlock(
      id: _nextGeneratedBlockId('table-row'),
      kind: BusyBlockKind.table,
      children: [
        for (var column = 0; column < columns; column++)
          _newTableCell(
            alignment: column < alignments.length
                ? alignments[column]
                : BusyTableAlignment.unspecified,
          ),
      ],
      dirty: true,
    );
  }

  BusyBlock _newTableCell({
    BusyTableAlignment alignment = BusyTableAlignment.unspecified,
  }) {
    return BusyBlock(
      id: _nextGeneratedBlockId('table-cell'),
      kind: BusyBlockKind.paragraph,
      inlines: _textInlines(''),
      attributes: {
        if (busyTableAlignmentAttribute(alignment) case final value?)
          'align': value,
      },
      dirty: true,
    );
  }

  BusyTableAlignment _tableColumnAlignment(BusyBlock table, int column) {
    for (final row in table.children) {
      if (column >= row.children.length) {
        continue;
      }
      final alignment = busyTableAlignmentFromAttribute(
        row.children[column].attributes['align'],
      );
      if (alignment != BusyTableAlignment.unspecified) {
        return alignment;
      }
    }
    return BusyTableAlignment.unspecified;
  }

  int _tableColumnCount(BusyBlock table) {
    var count = 1;
    for (final row in table.children) {
      if (row.children.length > count) {
        count = row.children.length;
      }
    }
    return count;
  }

  List<BusyBlock> _cellsPaddedTo(BusyBlock row, int columnCount) {
    return [
      ...row.children,
      for (var index = row.children.length; index < columnCount; index++)
        _newTableCell(),
    ];
  }

  List<BusyBlock> _normalizedTableRows(List<BusyBlock> rows) {
    return [
      for (final (rowIndex, row) in rows.indexed)
        row.copyWith(
          attributes: {...row.attributes, 'header': '${rowIndex == 0}'},
          children: [
            for (final cell in row.children)
              cell.copyWith(
                attributes: {
                  ...cell.attributes,
                  'cell': rowIndex == 0 ? 'th' : 'td',
                },
                dirty: true,
              ),
          ],
          dirty: true,
        ),
    ];
  }

  void applyCodeBlockLanguage(String blockId, String language) {
    final trimmedLanguage = language.trim();
    _replaceBlock(blockId, (block) {
      final attributes = {...block.attributes}
        ..remove('level')
        ..remove('id')
        ..remove('generatedId');
      if (trimmedLanguage.isEmpty) {
        attributes.remove('language');
      } else {
        attributes['language'] = trimmedLanguage;
      }
      return block.copyWith(
        kind: BusyBlockKind.codeBlock,
        attributes: attributes,
        preserveRaw: false,
        dirty: true,
      );
    });
  }

  void toggleTaskChecked(Iterable<String> blockIds) {
    final ids = blockIds.toSet();
    if (ids.isEmpty) {
      return;
    }
    _document = _document.copyWith(
      blocks: _replaceBlocksByIds(_document.blocks, ids, (block) {
        if (block.kind != BusyBlockKind.taskListItem) {
          return block;
        }
        final checked = block.attributes['task'] == 'true';
        return block.copyWith(
          attributes: {...block.attributes, 'task': '${!checked}'},
          dirty: true,
        );
      }),
    );
    notifyListeners();
  }

  bool indentListItems(Iterable<String> blockIds) {
    final ids = blockIds.toSet();
    if (ids.isEmpty) {
      return false;
    }
    var changed = false;
    List<BusyBlock> visit(List<BusyBlock> blocks) {
      final result = <BusyBlock>[];
      for (final block in blocks) {
        if (block.isSourceProtected) {
          result.add(block);
          continue;
        }
        final updated = block.copyWith(children: visit(block.children));
        if (ids.contains(updated.id) &&
            _isListItemKind(updated.kind) &&
            result.isNotEmpty &&
            _isListItemKind(result.last.kind) &&
            !result.last.isSourceProtected) {
          final parent = result.removeLast();
          final indented = _numberIndentedListItem(
            updated.copyWith(dirty: true),
            parent.children,
          );
          result.add(
            parent.copyWith(
              children: [...parent.children, indented],
              dirty: true,
            ),
          );
          changed = true;
        } else {
          result.add(updated);
        }
      }
      return result;
    }

    final blocks = visit(_document.blocks);
    if (!changed) {
      return false;
    }
    _document = _document.copyWith(
      blocks: _normalizeOrderedListMarkers(blocks),
    );
    notifyListeners();
    return true;
  }

  bool outdentListItems(Iterable<String> blockIds) {
    final ids = blockIds.toSet();
    if (ids.isEmpty) {
      return false;
    }
    var changed = false;

    _OutdentResult visitChildren(List<BusyBlock> blocks) {
      final kept = <BusyBlock>[];
      final outdented = <BusyBlock>[];
      for (final block in blocks) {
        if (block.isSourceProtected) {
          kept.add(block);
          continue;
        }
        final childResult = visitChildren(block.children);
        final updated = block.copyWith(children: childResult.kept);
        if (ids.contains(updated.id) && _isListItemKind(updated.kind)) {
          outdented.add(updated.copyWith(dirty: true));
          outdented.addAll(childResult.outdented);
          changed = true;
        } else {
          kept.add(updated);
          kept.addAll(childResult.outdented);
        }
      }
      return _OutdentResult(kept: kept, outdented: outdented);
    }

    final result = <BusyBlock>[];
    for (final block in _document.blocks) {
      if (block.isSourceProtected) {
        result.add(block);
        continue;
      }
      final childResult = visitChildren(block.children);
      result.add(
        block.copyWith(
          children: childResult.kept,
          dirty: childResult.outdented.isEmpty ? block.dirty : true,
        ),
      );
      result.addAll(childResult.outdented);
    }
    if (!changed) {
      return false;
    }
    _document = _document.copyWith(
      blocks: _normalizeOrderedListMarkers(result),
    );
    notifyListeners();
    return true;
  }

  String? splitBlockAt(String blockId, int offset) {
    final block = blockById(blockId);
    if (block == null) {
      return null;
    }
    final text = block.plainText;
    final safeOffset = offset.clamp(0, text.length).toInt();
    final leftText = text.substring(0, safeOffset);
    final rightText = text.substring(safeOffset);
    final ranges = busyInlineStyleRanges(block.inlines);
    final nextBlockId = _nextGeneratedBlockId(_newBlockPrefixFor(block.kind));
    final nextKind = _splitKindFor(block.kind);
    final currentBlock = BusyBlock(
      id: block.id,
      kind: block.kind,
      inlines: _inlinesFromStyleRanges(
        leftText,
        _styleRangesForSlice(ranges, 0, safeOffset),
      ),
      children: block.children,
      attributes: _attributesForText(block.attributes, block.kind, leftText),
      dirty: true,
    );
    final nextBlock = BusyBlock(
      id: nextBlockId,
      kind: nextKind,
      inlines: _inlinesFromStyleRanges(
        rightText,
        _styleRangesForSlice(ranges, safeOffset, text.length),
      ),
      attributes: _attributesForText(
        _splitAttributesFor(block, nextKind, orderedOffset: 1),
        nextKind,
        rightText,
      ),
      dirty: true,
    );
    _document = _document.copyWith(
      blocks: _replaceBlockWithMany(_document.blocks, blockId, [
        currentBlock,
        nextBlock,
      ]),
    );
    notifyListeners();
    return nextBlockId;
  }

  BusyWysiwygTextSplitResult? applyEnterAt(String blockId, int offset) {
    final block = blockById(blockId);
    if (block == null) {
      return null;
    }
    if (_isListItemKind(block.kind) && block.plainText.trim().isEmpty) {
      _replaceBlockWithParagraph(blockId);
      return BusyWysiwygTextSplitResult(blockId: blockId, offset: 0);
    }
    final nextBlockId = splitBlockAt(blockId, offset);
    if (nextBlockId == null) {
      return null;
    }
    return BusyWysiwygTextSplitResult(blockId: nextBlockId, offset: 0);
  }

  BusyWysiwygTextSplitResult? applyBackspaceAtStart(String blockId) {
    final blocks = _document.blocks;
    final index = blocks.indexWhere((block) => block.id == blockId);
    if (index <= 0) {
      return null;
    }
    final previous = blocks[index - 1];
    final current = blocks[index];
    if (!_isMergeableTextBlock(previous) || !_isMergeableTextBlock(current)) {
      return null;
    }
    final previousText = previous.plainText;
    final currentText = current.plainText;
    if (currentText.isEmpty) {
      final updatedPrevious = _withoutSourceSpan(previous, dirty: true);
      _document = _document.copyWith(
        blocks: [
          ...blocks.take(index - 1),
          updatedPrevious,
          ...blocks.skip(index + 1),
        ],
      );
      notifyListeners();
      return BusyWysiwygTextSplitResult(
        blockId: previous.id,
        offset: previousText.length,
      );
    }
    final mergedText = '$previousText$currentText';
    final previousRanges = busyInlineStyleRanges(previous.inlines);
    final currentRanges = [
      for (final range in busyInlineStyleRanges(current.inlines))
        BusyInlineStyleRange(
          start: range.start + previousText.length,
          end: range.end + previousText.length,
          kind: range.kind,
          destination: range.destination,
        ),
    ];
    final merged = BusyBlock(
      id: previous.id,
      kind: previous.kind,
      inlines: _inlinesFromStyleRanges(mergedText, [
        ...previousRanges,
        ...currentRanges,
      ]),
      children: previous.children,
      attributes: previous.attributes,
      dirty: true,
    );
    _document = _document.copyWith(
      blocks: [...blocks.take(index - 1), merged, ...blocks.skip(index + 1)],
    );
    notifyListeners();
    return BusyWysiwygTextSplitResult(
      blockId: merged.id,
      offset: previousText.length,
    );
  }

  BusyWysiwygTextSplitResult? deleteTextSelection({
    required String firstBlockId,
    required int firstStartOffset,
    required String lastBlockId,
    required int lastEndOffset,
    required Iterable<String> removedBlockIds,
  }) {
    final firstBlock = blockById(firstBlockId);
    final lastBlock = blockById(lastBlockId);
    if (firstBlock == null || lastBlock == null) {
      return null;
    }
    final firstText = firstBlock.plainText;
    final lastText = lastBlock.plainText;
    final firstStart = firstStartOffset.clamp(0, firstText.length).toInt();
    final lastEnd = lastEndOffset.clamp(0, lastText.length).toInt();
    final removedIds = removedBlockIds.toSet();
    final firstReadOnly = _isReadOnlySelectionEndpoint(firstBlock);
    final lastReadOnly = _isReadOnlySelectionEndpoint(lastBlock);
    if (firstBlockId == lastBlockId) {
      if (firstReadOnly &&
          firstStart == 0 &&
          lastEnd == firstText.length &&
          removedIds.contains(firstBlockId) &&
          !firstBlock.isSourceProtected) {
        _document = _document.copyWith(
          blocks: _replaceInBlocks(
            _document.blocks,
            firstBlockId,
            (block) => BusyBlock(
              id: block.id,
              kind: BusyBlockKind.paragraph,
              inlines: _textInlines(''),
              attributes: const {
                busyMarkPreserveEmptyParagraphAttribute: 'true',
              },
              dirty: true,
            ),
          ),
        );
        notifyListeners();
        return BusyWysiwygTextSplitResult(blockId: firstBlockId, offset: 0);
      }
      if (firstReadOnly) {
        return null;
      }
      if (lastEnd <= firstStart) {
        return null;
      }
      final nextText =
          firstText.substring(0, firstStart) + firstText.substring(lastEnd);
      _document = _document.copyWith(
        blocks: _replaceInBlocks(
          _document.blocks,
          firstBlockId,
          (block) => _blockWithEditedText(block, nextText),
        ),
      );
      notifyListeners();
      return BusyWysiwygTextSplitResult(
        blockId: firstBlockId,
        offset: firstStart,
      );
    }

    final completeFirstReadOnly =
        firstReadOnly &&
        firstStart == 0 &&
        removedIds.contains(firstBlockId) &&
        !firstBlock.isSourceProtected;
    final completeLastReadOnly =
        lastReadOnly &&
        lastEnd == lastText.length &&
        removedIds.contains(lastBlockId) &&
        !lastBlock.isSourceProtected;
    if ((firstReadOnly && !completeFirstReadOnly) ||
        (lastReadOnly && !completeLastReadOnly)) {
      return null;
    }

    final mergedText =
        firstText.substring(0, firstStart) + lastText.substring(lastEnd);
    final removeIds = removedIds.where((id) => id != firstBlockId).toSet();
    _document = _document.copyWith(
      blocks: _removeBlocksByIds(
        _replaceInBlocks(
          _document.blocks,
          firstBlockId,
          (block) => completeFirstReadOnly
              ? BusyBlock(
                  id: block.id,
                  kind: BusyBlockKind.paragraph,
                  inlines: _textInlines(mergedText),
                  attributes: _attributesForText(
                    const {},
                    BusyBlockKind.paragraph,
                    mergedText,
                  ),
                  dirty: true,
                )
              : _blockWithEditedText(block, mergedText),
        ),
        removeIds,
      ),
    );
    notifyListeners();
    return BusyWysiwygTextSplitResult(
      blockId: firstBlockId,
      offset: firstStart,
    );
  }

  BusyWysiwygTextSplitResult? insertStyledBlocksAtSelection({
    required String blockId,
    required int selectionStart,
    required int selectionEnd,
    required List<BusyWysiwygStyledBlock> blocks,
  }) {
    if (blocks.isEmpty) {
      return null;
    }
    final block = blockById(blockId);
    if (block == null || block.preserveRaw) {
      return null;
    }
    final text = block.plainText;
    final start = selectionStart.clamp(0, text.length).toInt();
    final end = selectionEnd.clamp(start, text.length).toInt();
    final oldRanges = busyInlineStyleRanges(block.inlines);
    final beforeText = text.substring(0, start);
    final afterText = text.substring(end);
    final beforeRanges = _styleRangesForSlice(oldRanges, 0, start);
    final afterRanges = _styleRangesForSlice(oldRanges, end, text.length);

    if (blocks.any(_requiresCompleteBlockInsertion)) {
      return _insertCompleteBlocksAtSelection(
        block: block,
        blockId: blockId,
        beforeText: beforeText,
        afterText: afterText,
        beforeRanges: beforeRanges,
        afterRanges: afterRanges,
        blocks: blocks,
      );
    }

    final replacements = <BusyBlock>[];
    if (blocks.length == 1) {
      final inserted = blocks.single;
      final nextText = beforeText + inserted.text + afterText;
      final nextRanges = [
        ...beforeRanges,
        ..._shiftStyleRanges(inserted.ranges, beforeText.length),
        ..._shiftStyleRanges(
          afterRanges,
          beforeText.length + inserted.text.length,
        ),
      ];
      replacements.add(
        block.copyWith(
          kind: beforeText.isEmpty && afterText.isEmpty
              ? inserted.kind
              : block.kind,
          attributes: beforeText.isEmpty && afterText.isEmpty
              ? inserted.attributes
              : block.attributes,
          inlines: _inlinesFromStyleRanges(nextText, nextRanges),
          preserveRaw: false,
          dirty: true,
        ),
      );
      _document = _document.copyWith(
        blocks: _replaceBlockWithMany(_document.blocks, blockId, replacements),
      );
      notifyListeners();
      return BusyWysiwygTextSplitResult(
        blockId: blockId,
        offset: beforeText.length + inserted.text.length,
      );
    }

    final first = blocks.first;
    final firstText = beforeText + first.text;
    replacements.add(
      block.copyWith(
        kind: beforeText.isEmpty ? first.kind : block.kind,
        attributes: beforeText.isEmpty ? first.attributes : block.attributes,
        inlines: _inlinesFromStyleRanges(firstText, [
          ...beforeRanges,
          ..._shiftStyleRanges(first.ranges, beforeText.length),
        ]),
        preserveRaw: false,
        dirty: true,
      ),
    );

    for (final inserted in blocks.skip(1).take(blocks.length - 2)) {
      replacements.add(_styledBlockToBusyBlock(inserted));
    }

    final last = blocks.last;
    final lastText = last.text + afterText;
    final lastBlock = _styledBlockToBusyBlock(
      last,
      text: lastText,
      ranges: [
        ...last.ranges,
        ..._shiftStyleRanges(afterRanges, last.text.length),
      ],
    );
    replacements.add(lastBlock);

    _document = _document.copyWith(
      blocks: _replaceBlockWithMany(_document.blocks, blockId, replacements),
    );
    notifyListeners();
    return BusyWysiwygTextSplitResult(
      blockId: lastBlock.id,
      offset: last.text.length,
    );
  }

  BusyWysiwygTextSplitResult _insertCompleteBlocksAtSelection({
    required BusyBlock block,
    required String blockId,
    required String beforeText,
    required String afterText,
    required List<BusyInlineStyleRange> beforeRanges,
    required List<BusyInlineStyleRange> afterRanges,
    required List<BusyWysiwygStyledBlock> blocks,
  }) {
    final replacements = <BusyBlock>[];
    var originalIdAvailable = true;
    if (beforeText.isNotEmpty) {
      replacements.add(
        block.copyWith(
          inlines: _inlinesFromStyleRanges(beforeText, beforeRanges),
          attributes: _attributesForText(
            block.attributes,
            block.kind,
            beforeText,
          ),
          preserveRaw: false,
          dirty: true,
        ),
      );
      originalIdAvailable = false;
    }
    for (final styled in blocks) {
      replacements.add(
        _styledBlockToBusyBlock(
          styled,
          rootId: originalIdAvailable ? block.id : null,
        ),
      );
      originalIdAvailable = false;
    }
    late final BusyBlock focusBlock;
    if (afterText.isNotEmpty) {
      focusBlock = BusyBlock(
        id: originalIdAvailable ? block.id : _nextGeneratedBlockId('paragraph'),
        kind: BusyBlockKind.paragraph,
        inlines: _inlinesFromStyleRanges(afterText, afterRanges),
        dirty: true,
      );
      replacements.add(focusBlock);
    } else {
      focusBlock = BusyBlock(
        id: _nextGeneratedBlockId('paragraph'),
        kind: BusyBlockKind.paragraph,
        inlines: _textInlines(''),
        attributes: const {busyMarkPreserveEmptyParagraphAttribute: 'true'},
        dirty: true,
      );
      replacements.add(focusBlock);
    }
    _document = _document.copyWith(
      blocks: _replaceBlockWithMany(_document.blocks, blockId, replacements),
    );
    notifyListeners();
    return BusyWysiwygTextSplitResult(blockId: focusBlock.id, offset: 0);
  }

  BusyWysiwygTextSplitResult? replaceTextSelectionWithStyledBlocks({
    required String firstBlockId,
    required int firstStartOffset,
    required String lastBlockId,
    required int lastEndOffset,
    required Iterable<String> removedBlockIds,
    required List<BusyWysiwygStyledBlock> blocks,
  }) {
    final staged = BusyMarkWysiwygDocumentController(document: _document);
    final deletion = staged.deleteTextSelection(
      firstBlockId: firstBlockId,
      firstStartOffset: firstStartOffset,
      lastBlockId: lastBlockId,
      lastEndOffset: lastEndOffset,
      removedBlockIds: removedBlockIds,
    );
    if (deletion == null) {
      staged.dispose();
      return null;
    }
    final result = staged.insertStyledBlocksAtSelection(
      blockId: deletion.blockId,
      selectionStart: deletion.offset,
      selectionEnd: deletion.offset,
      blocks: blocks,
    );
    if (result == null) {
      staged.dispose();
      return null;
    }
    _document = staged.document;
    staged.dispose();
    notifyListeners();
    return result;
  }

  String? insertThematicBreakAfter(String blockId) {
    if (blockById(blockId) == null) {
      return null;
    }
    final paragraphId = _nextGeneratedBlockId('paragraph');
    final breakBlock = BusyBlock(
      id: _nextGeneratedBlockId('thematic-break'),
      kind: BusyBlockKind.thematicBreak,
      dirty: true,
    );
    final paragraphBlock = BusyBlock(
      id: paragraphId,
      kind: BusyBlockKind.paragraph,
      inlines: _textInlines(''),
      dirty: true,
    );
    _document = _document.copyWith(
      blocks: _insertBlocksAfter(_document.blocks, blockId, [
        breakBlock,
        paragraphBlock,
      ]),
    );
    notifyListeners();
    return paragraphId;
  }

  void applyInlineCommand(
    String blockId,
    BusyWysiwygInlineCommand command,
    int selectionStart,
    int selectionEnd, {
    String? destination,
  }) {
    if (selectionStart == selectionEnd) {
      return;
    }
    final start = selectionStart < selectionEnd ? selectionStart : selectionEnd;
    final end = selectionStart < selectionEnd ? selectionEnd : selectionStart;
    _replaceBlock(
      blockId,
      (block) => _blockWithInlineCommand(
        block,
        command,
        start,
        end,
        destination: destination,
      ),
    );
  }

  void applyInlineCommandToBlocks(
    Iterable<String> blockIds,
    BusyWysiwygInlineCommand command, {
    String? destination,
  }) {
    final idSet = blockIds.toSet();
    if (idSet.isEmpty) {
      return;
    }
    _document = _document.copyWith(
      blocks: _replaceBlocksByIds(_document.blocks, idSet, (block) {
        final length = block.plainText.length;
        if (length == 0) {
          return block;
        }
        return _blockWithInlineCommand(
          block,
          command,
          0,
          length,
          destination: destination,
        );
      }),
    );
    notifyListeners();
  }

  void _replaceBlock(String blockId, BusyBlock Function(BusyBlock) replace) {
    _document = _document.copyWith(
      blocks: _replaceInBlocks(_document.blocks, blockId, replace),
    );
    notifyListeners();
  }

  void _replaceBlockWithParagraph(String blockId) {
    _replaceBlock(
      blockId,
      (block) => BusyBlock(
        id: block.id,
        kind: BusyBlockKind.paragraph,
        inlines: _textInlines(''),
        attributes: const {busyMarkPreserveEmptyParagraphAttribute: 'true'},
        dirty: true,
      ),
    );
  }

  List<BusyBlock> _replaceInBlocks(
    List<BusyBlock> blocks,
    String blockId,
    BusyBlock Function(BusyBlock) replace,
  ) {
    for (var index = 0; index < blocks.length; index += 1) {
      final block = blocks[index];
      if (block.isSourceProtected) {
        continue;
      }
      if (block.id == blockId) {
        return [
          ...blocks.take(index),
          replace(block),
          ...blocks.skip(index + 1),
        ];
      }
      if (block.children.isEmpty) {
        continue;
      }
      final children = _replaceInBlocks(block.children, blockId, replace);
      if (identical(children, block.children)) {
        continue;
      }
      return [
        ...blocks.take(index),
        block.copyWith(children: children),
        ...blocks.skip(index + 1),
      ];
    }
    return blocks;
  }

  List<BusyBlock> _replaceBlockWithMany(
    List<BusyBlock> blocks,
    String blockId,
    List<BusyBlock> replacements,
  ) {
    return [
      for (final block in blocks)
        if (block.isSourceProtected)
          block
        else if (block.id == blockId)
          ...replacements
        else
          block.copyWith(
            children: _replaceBlockWithMany(
              block.children,
              blockId,
              replacements,
            ),
          ),
    ];
  }

  List<BusyBlock> _removeBlockById(List<BusyBlock> blocks, String blockId) {
    return _removeBlocksByIds(blocks, {blockId});
  }

  List<BusyBlock> _removeBlocksByIds(List<BusyBlock> blocks, Set<String> ids) {
    if (ids.isEmpty) {
      return blocks;
    }
    var changed = false;
    final result = <BusyBlock>[];
    for (final block in blocks) {
      if (block.isSourceProtected) {
        result.add(block);
        continue;
      }
      if (ids.contains(block.id)) {
        changed = true;
        continue;
      }
      final children = _removeBlocksByIds(block.children, ids);
      if (identical(children, block.children)) {
        result.add(block);
        continue;
      }
      changed = true;
      if (block.kind == BusyBlockKind.blockquote &&
          block.children.isNotEmpty &&
          children.isEmpty &&
          block.inlines.isEmpty) {
        continue;
      }
      result.add(
        block.copyWith(children: children, preserveRaw: false, dirty: true),
      );
    }
    return changed ? result : blocks;
  }

  List<BusyBlock> _insertBlocksAfter(
    List<BusyBlock> blocks,
    String blockId,
    List<BusyBlock> insertedBlocks,
  ) {
    return [
      for (final block in blocks) ...[
        if (block.isSourceProtected)
          block
        else ...[
          block.copyWith(
            children: _insertBlocksAfter(
              block.children,
              blockId,
              insertedBlocks,
            ),
          ),
          if (block.id == blockId) ...insertedBlocks,
        ],
      ],
    ];
  }

  List<BusyBlock> _replaceBlocksByIds(
    List<BusyBlock> blocks,
    Set<String> blockIds,
    BusyBlock Function(BusyBlock) replace,
  ) {
    final result = <BusyBlock>[];
    for (final block in blocks) {
      if (block.isSourceProtected) {
        result.add(block);
        continue;
      }
      var updated = blockIds.contains(block.id) ? replace(block) : block;
      final children = _replaceBlocksByIds(updated.children, blockIds, replace);
      if (!identical(children, updated.children)) {
        updated = updated.copyWith(children: children);
      }
      result.add(updated);
    }
    return result;
  }

  Iterable<BusyBlock> _flatten(List<BusyBlock> blocks) sync* {
    for (final block in blocks) {
      yield block;
      yield* _flatten(block.children);
    }
  }

  bool _isReadOnlySelectionEndpoint(BusyBlock block) {
    return block.preserveRaw ||
        block.isSourceOnly ||
        block.isGenerated ||
        block.isSourceProtected ||
        block.kind == BusyBlockKind.table ||
        block.kind == BusyBlockKind.thematicBreak;
  }

  String _nextGeneratedBlockId(String prefix) {
    final existingIds = {
      for (final block in _flatten(_document.blocks)) block.id,
    };
    late String id;
    do {
      _generatedBlockIndex++;
      id = '$prefix-$_generatedBlockIndex';
    } while (existingIds.contains(id));
    return id;
  }

  BusyBlock _styledBlockToBusyBlock(
    BusyWysiwygStyledBlock styled, {
    String? text,
    List<BusyInlineStyleRange>? ranges,
    String? rootId,
  }) {
    final completeBlock = styled.completeBlock;
    if (completeBlock != null && _requiresCompleteBlockInsertion(styled)) {
      return _cloneClipboardBlock(completeBlock, rootId: rootId);
    }
    final kind = styled.kind;
    final blockText = text ?? styled.text;
    return BusyBlock(
      id: rootId ?? _nextGeneratedBlockId(_newBlockPrefixFor(kind)),
      kind: kind,
      inlines: _inlinesFromStyleRanges(blockText, ranges ?? styled.ranges),
      attributes: _attributesForText(styled.attributes, kind, blockText),
      preserveRaw: false,
      dirty: true,
    );
  }

  BusyBlock _cloneClipboardBlock(BusyBlock block, {String? rootId}) {
    return BusyBlock(
      id: rootId ?? _nextGeneratedBlockId(_newBlockPrefixFor(block.kind)),
      kind: block.kind,
      inlines: List.unmodifiable(block.inlines),
      children: List.unmodifiable([
        for (final child in block.children) _cloneClipboardBlock(child),
      ]),
      attributes: Map.unmodifiable(block.attributes),
      rawSource: block.rawSource,
      preserveRaw: block.preserveRaw,
      isSourceOnly: block.isSourceOnly,
      isGenerated: block.isGenerated,
      isSourceProtected: block.isSourceProtected,
      dirty: true,
    );
  }
}

class BusyWysiwygTextSplitResult {
  const BusyWysiwygTextSplitResult({
    required this.blockId,
    required this.offset,
  });

  final String blockId;
  final int offset;
}

class BusyWysiwygStyledBlock {
  const BusyWysiwygStyledBlock({
    required this.kind,
    required this.text,
    required this.ranges,
    this.attributes = const {},
    this.completeBlock,
  });

  final BusyBlockKind kind;
  final String text;
  final List<BusyInlineStyleRange> ranges;
  final Map<String, String> attributes;
  final BusyBlock? completeBlock;
}

bool _requiresCompleteBlockInsertion(BusyWysiwygStyledBlock styled) {
  final block = styled.completeBlock;
  return block != null &&
      !busyMarkWysiwygCanApplyBlockCommand(
        block,
        BusyWysiwygBlockCommand.paragraph,
      );
}

class _OutdentResult {
  const _OutdentResult({required this.kept, required this.outdented});

  final List<BusyBlock> kept;
  final List<BusyBlock> outdented;
}

List<BusyInline> _textInlines(String text) {
  return [BusyInline(kind: BusyInlineKind.text, text: text)];
}

String? _tableCellText(BusyBlock? table, int row, int column) {
  if (table == null || row < 0 || column < 0 || row >= table.children.length) {
    return null;
  }
  final rowBlock = table.children[row];
  if (column >= rowBlock.children.length) {
    return null;
  }
  final text = rowBlock.children[column].plainText;
  return text.isEmpty ? null : text;
}

List<BusyInline> _nonEmptyInlines(List<BusyInline> inlines) {
  return [
    for (final inline in inlines)
      if (inline.kind != BusyInlineKind.text || inline.text.isNotEmpty) inline,
  ];
}

List<BusyInline> _inlinesFromStyleRangesWithHardBreaks(
  String text,
  List<BusyInlineStyleRange> ranges,
) {
  if (!text.contains('\n')) {
    return _inlinesFromStyleRanges(text, ranges);
  }
  final inlines = <BusyInline>[];
  var offset = 0;
  for (final match in RegExp(r'\n').allMatches(text)) {
    if (match.start > offset) {
      inlines.addAll(
        _nonEmptyInlines(
          _inlinesFromStyleRanges(
            text.substring(offset, match.start),
            _styleRangesForSlice(ranges, offset, match.start),
          ),
        ),
      );
    }
    inlines.add(const BusyInline(kind: BusyInlineKind.hardBreak, text: '\n'));
    offset = match.end;
  }
  if (offset < text.length) {
    inlines.addAll(
      _nonEmptyInlines(
        _inlinesFromStyleRanges(
          text.substring(offset),
          _styleRangesForSlice(ranges, offset, text.length),
        ),
      ),
    );
  }
  return inlines.isEmpty ? _textInlines('') : inlines;
}

List<BusyInlineStyleRange> _styleRangesForReplacement({
  required List<BusyInlineStyleRange> ranges,
  required int selectionStart,
  required int selectionEnd,
  required int replacementLength,
}) {
  final selectedLength = selectionEnd - selectionStart;
  final delta = replacementLength - selectedLength;
  final replacementEnd = selectionStart + replacementLength;
  return [
    for (final range in ranges) ...[
      if (range.end <= selectionStart)
        range
      else if (range.start >= selectionEnd)
        BusyInlineStyleRange(
          start: range.start + delta,
          end: range.end + delta,
          kind: range.kind,
          destination: range.destination,
        )
      else ...[
        if (range.start < selectionStart)
          BusyInlineStyleRange(
            start: range.start,
            end: selectionStart,
            kind: range.kind,
            destination: range.destination,
          ),
        if (range.end > selectionEnd)
          BusyInlineStyleRange(
            start: replacementEnd,
            end: range.end + delta,
            kind: range.kind,
            destination: range.destination,
          ),
      ],
    ],
  ];
}

Map<String, String> _splitAttributesFor(
  BusyBlock block,
  BusyBlockKind kind, {
  int orderedOffset = 0,
}) {
  final attributes = {...block.attributes};
  if (kind != BusyBlockKind.heading) {
    attributes.remove('level');
    attributes.remove('id');
    attributes.remove('generatedId');
  }
  if (kind == BusyBlockKind.orderedListItem) {
    attributes['ordered'] = 'true';
    attributes['marker'] = _incrementOrderedMarker(
      block.attributes['marker'],
      orderedOffset,
    );
  }
  return attributes;
}

Map<String, String> _attributesForText(
  Map<String, String> attributes,
  BusyBlockKind kind,
  String text,
) {
  final updated = {...attributes}
    ..remove(busyMarkPreserveEmptyParagraphAttribute);
  if (kind == BusyBlockKind.paragraph && text.isEmpty) {
    updated[busyMarkPreserveEmptyParagraphAttribute] = 'true';
  }
  return updated;
}

Map<String, String> _mathEditedBlockAttributes(
  BusyBlock current,
  BusyBlock parsed, {
  required bool firstReplacement,
}) {
  final attributes = {...parsed.attributes};
  if (firstReplacement &&
      current.kind == BusyBlockKind.heading &&
      parsed.kind == BusyBlockKind.heading &&
      current.attributes['generatedId'] == 'false') {
    final explicitId = current.attributes['id'];
    if (explicitId != null && explicitId.isNotEmpty) {
      attributes['id'] = explicitId;
      attributes['generatedId'] = 'false';
    }
  }
  return attributes;
}

Map<String, String> _attributesAfterInlineMathEdit(
  BusyBlock block,
  List<BusyInline> inlines,
) {
  final attributes = {...block.attributes};
  if (block.kind == BusyBlockKind.heading &&
      attributes['generatedId'] != 'false') {
    attributes['id'] = slugForHeading(
      inlines.map((inline) => inline.plainText).join().trim(),
    );
    attributes['generatedId'] = 'true';
  }
  return attributes;
}

({List<BusyInline> before, List<BusyInline> after})
_partitionInlinesForReplacement(List<BusyInline> inlines, int start, int end) {
  final before = <BusyInline>[];
  final after = <BusyInline>[];
  var offset = 0;
  for (final inline in inlines) {
    final length = inline.plainText.length;
    final inlineEnd = offset + length;
    if (length == 0) {
      // Text selections cannot address zero-width semantic nodes. Keep each
      // one on a deterministic side of the replacement instead of silently
      // treating it as selected content.
      (offset <= start ? before : after).add(inline);
    } else if (inlineEnd <= start) {
      before.add(inline);
    } else if (offset >= end) {
      after.add(inline);
    } else {
      final localStart = (start - offset).clamp(0, length).toInt();
      final localEnd = (end - offset).clamp(localStart, length).toInt();
      final partition = _partitionInlineForReplacement(
        inline,
        localStart,
        localEnd,
      );
      if (partition.before != null) {
        before.add(partition.before!);
      }
      if (partition.after != null) {
        after.add(partition.after!);
      }
    }
    offset = inlineEnd;
  }
  return (before: before, after: after);
}

({BusyInline? before, BusyInline? after}) _partitionInlineForReplacement(
  BusyInline inline,
  int start,
  int end,
) {
  final length = inline.plainText.length;
  if (inline.children.isNotEmpty) {
    final partition = _partitionInlinesForReplacement(
      inline.children,
      start,
      end,
    );
    return (
      before: partition.before.isEmpty
          ? null
          : inline.copyWith(
              text: partition.before.map((child) => child.plainText).join(),
              children: partition.before,
            ),
      after: partition.after.isEmpty
          ? null
          : inline.copyWith(
              text: partition.after.map((child) => child.plainText).join(),
              children: partition.after,
            ),
    );
  }
  return (
    before: start == 0
        ? null
        : inline.copyWith(text: inline.text.substring(0, start)),
    after: end == length
        ? null
        : inline.copyWith(text: inline.text.substring(end)),
  );
}

({String expression, String leading, String trailing})?
_inlineMathExpressionParts(String value) {
  if (value.contains('\n') || value.contains('\r')) {
    return null;
  }
  final withoutLeading = value.trimLeft();
  final leadingLength = value.length - withoutLeading.length;
  final expression = withoutLeading.trimRight();
  if (expression.isEmpty) {
    return null;
  }
  return (
    expression: expression,
    leading: value.substring(0, leadingLength),
    trailing: withoutLeading.substring(expression.length),
  );
}

BusyInline _inlineMath(String expression, BusyMathSourceForm form) {
  return BusyInline(
    kind: BusyInlineKind.math,
    text: expression,
    attributes: {
      busyMarkMathExpressionAttribute: expression,
      busyMarkMathDisplayAttribute: 'false',
      busyMarkMathSourceFormAttribute: form.name,
    },
  );
}

String _inlineMathSource(String expression, BusyMathSourceForm form) {
  return form == BusyMathSourceForm.githubDollarBacktick
      ? '\$`$expression`\$'
      : '\$$expression\$';
}

bool _serializedInlineMathParses(
  List<BusyInline> inlines, {
  required MarkdownMode mode,
  required BusyMarkMarkdownSerializer serializer,
}) {
  final source = serializer.serializeBlock(
    BusyBlock(
      id: 'wysiwyg-inline-math-validation',
      kind: BusyBlockKind.paragraph,
      inlines: inlines,
      dirty: true,
    ),
  );
  final parsed = const MarkdownParser()
      .parse(
        filePath: 'wysiwyg-inline-math-validation.md',
        source: source,
        mode: mode,
        validateLocalReferences: false,
      )
      .busyDocument;
  final parsedInlines = _singleEditableBlockInlines(parsed);
  return parsedInlines != null &&
      _inlineListsSemanticallyEqual(inlines, parsedInlines);
}

List<BusyInline>? _singleEditableBlockInlines(BusyDocument document) {
  final blocks = document.blocks
      .where(
        (block) =>
            block.kind != BusyBlockKind.frontMatter && !block.isSourceOnly,
      )
      .toList(growable: false);
  return blocks.length == 1 ? blocks.single.inlines : null;
}

String _uniqueMathValidationExpression(String source, String expression) {
  var value = 'BusyMarkMathValidationToken';
  while (source.contains(value) || expression.contains(value)) {
    value += 'X';
  }
  return value;
}

List<BusyInline> _replaceValidationMath(
  List<BusyInline> inlines, {
  required String validationExpression,
  required String expression,
  required BusyMathSourceForm form,
}) {
  return [
    for (final inline in inlines)
      if (inline.kind == BusyInlineKind.math &&
          inline.text == validationExpression &&
          inline.attributes[busyMarkMathSourceFormAttribute] == form.name)
        _inlineMath(expression, form)
      else if (inline.children.isNotEmpty)
        inline.copyWith(
          children: _replaceValidationMath(
            inline.children,
            validationExpression: validationExpression,
            expression: expression,
            form: form,
          ),
        )
      else
        inline,
  ];
}

bool _inlineListsSemanticallyEqual(
  List<BusyInline> expected,
  List<BusyInline> actual,
) {
  final expectedNodes = _coalescedInlineNodes(expected);
  final actualNodes = _coalescedInlineNodes(actual);
  if (expectedNodes.length != actualNodes.length) {
    return false;
  }
  for (var index = 0; index < expectedNodes.length; index++) {
    final left = expectedNodes[index];
    final right = actualNodes[index];
    if (left.kind != right.kind ||
        left.text != right.text ||
        left.destination != right.destination ||
        !_inlineListsSemanticallyEqual(left.children, right.children)) {
      return false;
    }
    if (left.kind == BusyInlineKind.math &&
        left.attributes[busyMarkMathSourceFormAttribute] !=
            right.attributes[busyMarkMathSourceFormAttribute]) {
      return false;
    }
  }
  return true;
}

List<BusyInline> _coalescedInlineNodes(List<BusyInline> inlines) {
  final result = <BusyInline>[];
  for (final inline in inlines) {
    if (inline.kind == BusyInlineKind.text &&
        inline.children.isEmpty &&
        result.isNotEmpty &&
        result.last.kind == BusyInlineKind.text &&
        result.last.children.isEmpty) {
      result[result.length - 1] = result.last.copyWith(
        text: '${result.last.text}${inline.text}',
      );
    } else {
      result.add(inline);
    }
  }
  return result;
}

int _mathInlineCount(BusyDocument document) {
  return _walkInlines(
    document.blocks,
  ).where((inline) => inline.kind == BusyInlineKind.math).length;
}

int _matchingMathInlineCount(
  BusyDocument document, {
  required String expression,
  BusyMathSourceForm? form,
}) {
  return _walkInlines(document.blocks).where((inline) {
    return inline.kind == BusyInlineKind.math &&
        inline.text == expression &&
        (form == null ||
            inline.attributes[busyMarkMathSourceFormAttribute] == form.name);
  }).length;
}

Iterable<BusyInline> _walkInlines(Iterable<BusyBlock> blocks) sync* {
  for (final block in blocks) {
    yield* _walkInlineNodes(block.inlines);
    yield* _walkInlines(block.children);
  }
}

Iterable<BusyInline> _walkInlineNodes(Iterable<BusyInline> inlines) sync* {
  for (final inline in inlines) {
    yield inline;
    yield* _walkInlineNodes(inline.children);
  }
}

bool _shouldSplitNewlines(BusyBlockKind kind) {
  return switch (kind) {
    BusyBlockKind.paragraph ||
    BusyBlockKind.heading ||
    BusyBlockKind.unorderedListItem ||
    BusyBlockKind.orderedListItem ||
    BusyBlockKind.taskListItem => true,
    _ => false,
  };
}

BusyBlockKind _splitKindFor(BusyBlockKind kind) {
  return switch (kind) {
    BusyBlockKind.heading => BusyBlockKind.paragraph,
    _ => kind,
  };
}

String _newBlockPrefixFor(BusyBlockKind kind) {
  return switch (kind) {
    BusyBlockKind.unorderedListItem => 'unordered-list-item',
    BusyBlockKind.orderedListItem => 'ordered-list-item',
    BusyBlockKind.taskListItem => 'task-list-item',
    _ => 'paragraph',
  };
}

bool _isListItemKind(BusyBlockKind kind) {
  return switch (kind) {
    BusyBlockKind.unorderedListItem ||
    BusyBlockKind.orderedListItem ||
    BusyBlockKind.taskListItem => true,
    _ => false,
  };
}

bool _isMergeableTextBlock(BusyBlock block) {
  if (block.preserveRaw) {
    return false;
  }
  return switch (block.kind) {
    BusyBlockKind.paragraph ||
    BusyBlockKind.heading ||
    BusyBlockKind.unorderedListItem ||
    BusyBlockKind.orderedListItem ||
    BusyBlockKind.taskListItem ||
    BusyBlockKind.blockquote => true,
    _ => false,
  };
}

BusyBlock _blockWithEditedText(
  BusyBlock block,
  String nextText, {
  Iterable<BusyInlineKind> activeInlineKinds = const [],
}) {
  final oldText = block.plainText;
  final oldRanges = busyInlineStyleRanges(block.inlines);
  final nextRanges = _remapRangesForTextEdit(
    oldText: oldText,
    newText: nextText,
    ranges: oldRanges,
  );
  if (oldText.isEmpty && nextText.isNotEmpty) {
    for (final kind in _typingInlineKinds(activeInlineKinds)) {
      nextRanges.add(
        BusyInlineStyleRange(start: 0, end: nextText.length, kind: kind),
      );
    }
  }
  return block.copyWith(
    inlines: _inlinesFromStyleRanges(nextText, nextRanges),
    attributes: _attributesForText(block.attributes, block.kind, nextText),
    preserveRaw: false,
    dirty: true,
  );
}

BusyBlock _withoutSourceSpan(BusyBlock block, {required bool dirty}) {
  return BusyBlock(
    id: block.id,
    kind: block.kind,
    inlines: block.inlines,
    children: block.children,
    attributes: block.attributes,
    rawSource: block.rawSource,
    preserveRaw: block.preserveRaw,
    isSourceOnly: block.isSourceOnly,
    isGenerated: block.isGenerated,
    isSourceProtected: block.isSourceProtected,
    dirty: dirty,
  );
}

BusyBlock _blockWithCommand(BusyBlock block, BusyWysiwygBlockCommand command) {
  final kind = blockKindForCommand(command);
  final attributes = {...block.attributes}
    ..remove('ordered')
    ..remove('marker')
    ..remove('task')
    ..remove(busyMarkWritersideAdmonitionAttribute)
    ..remove(busyMarkWritersideAdmonitionSourceFormAttribute)
    ..remove('style')
    ..remove(busyMarkPreserveEmptyParagraphAttribute);
  if (block.kind == BusyBlockKind.writersideAdmonition) {
    attributes.remove('element');
  }
  if (command == BusyWysiwygBlockCommand.heading1) {
    attributes['level'] = '1';
  } else if (command == BusyWysiwygBlockCommand.heading2) {
    attributes['level'] = '2';
  } else if (command == BusyWysiwygBlockCommand.heading3) {
    attributes['level'] = '3';
  } else if (command == BusyWysiwygBlockCommand.heading4) {
    attributes['level'] = '4';
  } else if (command == BusyWysiwygBlockCommand.heading5) {
    attributes['level'] = '5';
  } else if (command == BusyWysiwygBlockCommand.heading6) {
    attributes['level'] = '6';
  } else {
    attributes
      ..remove('level')
      ..remove('id')
      ..remove('generatedId');
  }
  if (kind == BusyBlockKind.heading) {
    final text = block.plainText.trim();
    attributes['id'] = slugForHeading(text);
    attributes['generatedId'] = 'true';
  }
  if (kind == BusyBlockKind.orderedListItem) {
    attributes['ordered'] = 'true';
    attributes['marker'] = _orderedMarker(block) ?? '1.';
  }
  if (kind == BusyBlockKind.unorderedListItem) {
    attributes['ordered'] = 'false';
    attributes['marker'] = '-';
  }
  if (kind == BusyBlockKind.taskListItem) {
    attributes['ordered'] = 'false';
    attributes['marker'] = '-';
    attributes['task'] = block.attributes['task'] ?? 'false';
  }
  return block.copyWith(kind: kind, attributes: attributes, dirty: true);
}

BusyBlock _blockWithAdmonitionStyle(
  BusyBlock block,
  BusyAdmonitionStyle style,
) {
  final semanticElement = block.kind == BusyBlockKind.writersideAdmonition;
  final attributes = {...block.attributes}
    ..remove('ordered')
    ..remove('marker')
    ..remove('task')
    ..remove('level')
    ..remove('id')
    ..remove('generatedId')
    ..remove(busyMarkPreserveEmptyParagraphAttribute)
    ..[busyMarkWritersideAdmonitionAttribute] = 'true'
    ..[busyMarkWritersideAdmonitionSourceFormAttribute] = semanticElement
        ? 'element'
        : 'blockquote'
    ..['style'] = style.name;
  if (semanticElement) {
    attributes['element'] = style.name;
  } else {
    attributes.remove('element');
  }
  return block.copyWith(
    kind: semanticElement
        ? BusyBlockKind.writersideAdmonition
        : BusyBlockKind.blockquote,
    attributes: attributes,
    preserveRaw: false,
    dirty: true,
  );
}

BusyBlock _numberIndentedListItem(
  BusyBlock block,
  List<BusyBlock> existingSiblings,
) {
  if (!_isOrderedListBlock(block)) {
    return block;
  }
  final previous = existingSiblings.lastOrNull;
  final previousMarker = previous == null || !_isOrderedListBlock(previous)
      ? null
      : _orderedMarkerParts(previous.attributes['marker']);
  final marker = previousMarker == null
      ? '1.'
      : '${previousMarker.number + 1}${previousMarker.suffix}';
  return _withOrderedMarker(block, marker);
}

List<BusyBlock> _normalizeOrderedListMarkers(List<BusyBlock> blocks) {
  var changed = false;
  var nextNumber = 0;
  var suffix = '.';
  final result = <BusyBlock>[];
  for (final block in blocks) {
    var updated = block;
    if (!block.preserveRaw && !block.isSourceProtected) {
      final children = _normalizeOrderedListMarkers(block.children);
      if (!identical(children, block.children)) {
        updated = block.copyWith(children: children);
        changed = true;
      }
    }
    if (updated.preserveRaw || updated.isSourceProtected) {
      nextNumber = 0;
      suffix = '.';
      result.add(updated);
      continue;
    }
    if (_isOrderedListBlock(updated)) {
      if (nextNumber == 0) {
        final firstMarker = _orderedMarkerParts(updated.attributes['marker']);
        nextNumber = firstMarker?.number ?? 1;
        suffix = firstMarker?.suffix ?? '.';
      }
      final marker = '$nextNumber$suffix';
      if (updated.attributes['marker'] != marker ||
          updated.attributes['ordered'] != 'true') {
        updated = _withOrderedMarker(updated, marker);
        changed = true;
      }
      nextNumber += 1;
    } else {
      nextNumber = 0;
      suffix = '.';
    }
    result.add(updated);
  }
  return changed ? result : blocks;
}

BusyBlock _withOrderedMarker(BusyBlock block, String marker) {
  return block.copyWith(
    attributes: {...block.attributes, 'ordered': 'true', 'marker': marker},
    preserveRaw: false,
    dirty: true,
  );
}

bool _isOrderedListBlock(BusyBlock block) {
  return block.kind == BusyBlockKind.orderedListItem ||
      (block.kind == BusyBlockKind.taskListItem &&
          block.attributes['ordered'] == 'true');
}

String? _orderedMarker(BusyBlock block) {
  if (!_isOrderedListBlock(block)) {
    return null;
  }
  final marker = _orderedMarkerParts(block.attributes['marker']);
  return marker == null ? null : '${marker.number}${marker.suffix}';
}

({int number, String suffix})? _orderedMarkerParts(String? marker) {
  final match = RegExp(r'^(\d+)([.)])$').firstMatch(marker?.trim() ?? '');
  if (match == null) {
    return null;
  }
  final number = int.tryParse(match.group(1) ?? '');
  if (number == null) {
    return null;
  }
  return (number: number, suffix: match.group(2) ?? '.');
}

BusyBlock _blockWithInlineCommand(
  BusyBlock block,
  BusyWysiwygInlineCommand command,
  int selectionStart,
  int selectionEnd, {
  String? destination,
}) {
  final text = block.plainText;
  final safeStart = selectionStart.clamp(0, text.length).toInt();
  final safeEnd = selectionEnd.clamp(safeStart, text.length).toInt();
  final inlineKind = inlineKindForCommand(command);
  final existingRanges = busyInlineStyleRanges(block.inlines);
  final removeExistingStyle =
      command != BusyWysiwygInlineCommand.link &&
      _selectionCoveredByKind(existingRanges, inlineKind, safeStart, safeEnd);
  final ranges = [
    for (final range in existingRanges)
      ..._preservedRangeParts(
        range,
        removeKind:
            removeExistingStyle || command == BusyWysiwygInlineCommand.link
            ? inlineKind
            : null,
        selectionStart: safeStart,
        selectionEnd: safeEnd,
      ),
    if (!removeExistingStyle)
      BusyInlineStyleRange(
        start: safeStart,
        end: safeEnd,
        kind: inlineKind,
        destination: command == BusyWysiwygInlineCommand.link
            ? destination
            : null,
      ),
  ];
  return block.copyWith(
    inlines: _inlinesFromStyleRanges(text, ranges),
    dirty: true,
  );
}

List<BusyInlineStyleRange> _remapRangesForTextEdit({
  required String oldText,
  required String newText,
  required List<BusyInlineStyleRange> ranges,
}) {
  if (oldText == newText) {
    return ranges;
  }
  final prefix = _commonPrefixLength(oldText, newText);
  final suffix = _commonSuffixLength(oldText, newText, prefix);
  final oldEditStart = prefix;
  final oldEditEnd = oldText.length - suffix;
  final newEditEnd = newText.length - suffix;
  final delta = newText.length - oldText.length;
  final mapped = <BusyInlineStyleRange>[];

  for (final range in ranges) {
    if (range.end < oldEditStart) {
      mapped.add(range);
      continue;
    }
    if (range.start > oldEditEnd) {
      mapped.add(
        BusyInlineStyleRange(
          start: range.start + delta,
          end: range.end + delta,
          kind: range.kind,
          destination: range.destination,
        ),
      );
      continue;
    }

    final insertionTouchesRange =
        oldEditStart == oldEditEnd &&
        range.start <= oldEditStart &&
        range.end >= oldEditStart;
    final overlapsReplacedText =
        oldEditStart < oldEditEnd &&
        range.start < oldEditEnd &&
        range.end > oldEditStart;
    if (!insertionTouchesRange && !overlapsReplacedText) {
      if (range.end <= oldEditStart) {
        mapped.add(range);
      } else {
        mapped.add(
          BusyInlineStyleRange(
            start: range.start + delta,
            end: range.end + delta,
            kind: range.kind,
            destination: range.destination,
          ),
        );
      }
      continue;
    }

    final start = range.start < oldEditStart ? range.start : oldEditStart;
    final end = range.end > oldEditEnd ? range.end + delta : newEditEnd;
    if (end > start) {
      mapped.add(
        BusyInlineStyleRange(
          start: start,
          end: end,
          kind: range.kind,
          destination: range.destination,
        ),
      );
    }
  }
  return mapped;
}

Set<BusyInlineKind> _typingInlineKinds(Iterable<BusyInlineKind> kinds) {
  return {
    for (final kind in kinds)
      if (_isTypingInlineKind(kind)) kind,
  };
}

bool _isTypingInlineKind(BusyInlineKind kind) {
  return switch (kind) {
    BusyInlineKind.strong ||
    BusyInlineKind.emphasis ||
    BusyInlineKind.underline ||
    BusyInlineKind.strikethrough ||
    BusyInlineKind.code => true,
    _ => false,
  };
}

int _commonPrefixLength(String left, String right) {
  final limit = left.length < right.length ? left.length : right.length;
  var index = 0;
  while (index < limit && left.codeUnitAt(index) == right.codeUnitAt(index)) {
    index++;
  }
  return index;
}

int _commonSuffixLength(String left, String right, int prefixLength) {
  final leftRemaining = left.length - prefixLength;
  final rightRemaining = right.length - prefixLength;
  final limit = leftRemaining < rightRemaining ? leftRemaining : rightRemaining;
  var count = 0;
  while (count < limit &&
      left.codeUnitAt(left.length - count - 1) ==
          right.codeUnitAt(right.length - count - 1)) {
    count++;
  }
  return count;
}

String _incrementOrderedMarker(String? marker, int offset) {
  final match = RegExp(r'^(\d+)([.)])?$').firstMatch(marker?.trim() ?? '');
  if (match == null) {
    return '${offset + 1}.';
  }
  final value = int.tryParse(match.group(1) ?? '') ?? 1;
  final suffix = match.group(2) ?? '.';
  return '${value + offset}$suffix';
}

BusyDocument _ensureEditableDocument(BusyDocument document) {
  final withBlankParagraphs = _restoreSourceBlankParagraphs(document);
  final hasEditableBlock = withBlankParagraphs.blocks.any(
    (block) =>
        block.kind != BusyBlockKind.frontMatter &&
        !block.isSourceOnly &&
        !block.isSourceProtected,
  );
  if (hasEditableBlock) {
    return withBlankParagraphs;
  }
  return withBlankParagraphs.copyWith(
    blocks: [
      ...withBlankParagraphs.blocks,
      const BusyBlock(
        id: 'empty-paragraph',
        kind: BusyBlockKind.paragraph,
        inlines: [BusyInline(kind: BusyInlineKind.text, text: '')],
      ),
    ],
  );
}

BusyDocument _restoreSourceBlankParagraphs(BusyDocument document) {
  final source = document.source;
  if (source == null ||
      document.blocks.any(
        (block) =>
            block.kind == BusyBlockKind.paragraph && block.plainText.isEmpty,
      )) {
    return document;
  }
  final frontMatterBlocks = document.blocks
      .where((block) => block.kind == BusyBlockKind.frontMatter)
      .toList();
  final sourceBlocks = document.blocks
      .where(
        (block) =>
            block.kind != BusyBlockKind.frontMatter && !block.isGenerated,
      )
      .toList();
  final generatedBlocks = document.blocks
      .where((block) => block.isGenerated)
      .toList();
  if (sourceBlocks.isEmpty) {
    if (document.rawFrontMatter != null || source.trim().isNotEmpty) {
      return document;
    }
    final blankOffsets = <int>[
      0,
      for (final match in '\n'.allMatches(source)) match.end,
    ];
    return document.copyWith(
      blocks: [
        ...frontMatterBlocks,
        for (final (index, offset) in blankOffsets.indexed)
          _sourceBlankParagraph(document, offset, index),
        ...generatedBlocks,
      ],
    );
  }
  if (sourceBlocks.any((block) => block.sourceSpan == null)) {
    return document;
  }

  final expanded = <BusyBlock>[];
  var previousEnd = document.rawFrontMatter?.length ?? 0;
  for (final (index, block) in sourceBlocks.indexed) {
    final span = block.sourceSpan!;
    if (span.startOffset < previousEnd || span.endOffset > source.length) {
      return document;
    }
    final gap = source.substring(previousEnd, span.startOffset);
    if (gap.trim().isNotEmpty) {
      return document;
    }
    // Two newlines are the ordinary Markdown block boundary. Every newline
    // after that represents another blank paragraph in the rich editor.
    final baselineNewlines = index == 0 && document.rawFrontMatter == null
        ? 0
        : 2;
    final blankOffsets = _extraBlankLineOffsets(
      gap,
      startOffset: previousEnd,
      baselineNewlines: baselineNewlines,
    );
    for (final (blankIndex, offset) in blankOffsets.indexed) {
      expanded.add(_sourceBlankParagraph(document, offset, blankIndex));
    }
    expanded.add(block);
    previousEnd = span.endOffset;
  }

  final trailing = source.substring(previousEnd);
  if (trailing.trim().isNotEmpty) {
    return document;
  }
  final trailingBlankOffsets = _extraBlankLineOffsets(
    trailing,
    startOffset: previousEnd,
    baselineNewlines: 1,
  );
  for (final (blankIndex, offset) in trailingBlankOffsets.indexed) {
    expanded.add(_sourceBlankParagraph(document, offset, blankIndex));
  }
  if (expanded.length == sourceBlocks.length) {
    return document;
  }
  return document.copyWith(
    blocks: [...frontMatterBlocks, ...expanded, ...generatedBlocks],
  );
}

List<int> _extraBlankLineOffsets(
  String gap, {
  required int startOffset,
  required int baselineNewlines,
}) {
  final newlineOffsets = [
    for (final match in '\n'.allMatches(gap)) startOffset + match.start,
  ];
  if (newlineOffsets.length <= baselineNewlines) {
    return const [];
  }
  final lineStarts = <int>[
    startOffset,
    for (final offset in newlineOffsets) offset + 1,
  ];
  return [
    for (var index = baselineNewlines; index < newlineOffsets.length; index++)
      lineStarts[index],
  ];
}

BusyBlock _sourceBlankParagraph(BusyDocument document, int offset, int index) {
  return BusyBlock(
    id: '\u0000source-blank:$offset:$index',
    kind: BusyBlockKind.paragraph,
    inlines: const [BusyInline(kind: BusyInlineKind.text, text: '')],
    attributes: const {busyMarkPreserveEmptyParagraphAttribute: 'true'},
    rawSource: '',
    sourceSpan: SourceSpan.fromOffsets(
      filePath: document.filePath,
      source: document.source ?? '',
      startOffset: offset,
      endOffset: offset,
    ),
  );
}

bool _selectionCoveredByKind(
  List<BusyInlineStyleRange> ranges,
  BusyInlineKind kind,
  int start,
  int end,
) {
  if (end <= start) {
    return false;
  }
  var offset = start;
  final matching =
      ranges
          .where(
            (range) =>
                range.kind == kind && range.end > start && range.start < end,
          )
          .toList()
        ..sort((a, b) => a.start.compareTo(b.start));
  for (final range in matching) {
    if (range.start > offset) {
      return false;
    }
    if (range.end > offset) {
      offset = range.end;
    }
    if (offset >= end) {
      return true;
    }
  }
  return false;
}

List<BusyInlineStyleRange> _preservedRangeParts(
  BusyInlineStyleRange range, {
  required BusyInlineKind? removeKind,
  required int selectionStart,
  required int selectionEnd,
}) {
  if (removeKind == null ||
      range.kind != removeKind ||
      range.end <= selectionStart ||
      range.start >= selectionEnd) {
    return [range];
  }
  return [
    if (range.start < selectionStart)
      BusyInlineStyleRange(
        start: range.start,
        end: selectionStart,
        kind: range.kind,
        destination: range.destination,
      ),
    if (range.end > selectionEnd)
      BusyInlineStyleRange(
        start: selectionEnd,
        end: range.end,
        kind: range.kind,
        destination: range.destination,
      ),
  ];
}

List<BusyInline> _inlinesFromStyleRanges(
  String text,
  List<BusyInlineStyleRange> ranges,
) {
  if (text.isEmpty) {
    return const [BusyInline(kind: BusyInlineKind.text, text: '')];
  }
  final normalized = _normalizedStyleRanges(ranges, text.length);
  final boundaries = <int>{0, text.length};
  for (final range in normalized) {
    boundaries
      ..add(range.start)
      ..add(range.end);
  }
  final sortedBoundaries = boundaries.toList()..sort();
  final segments = [
    for (var index = 0; index < sortedBoundaries.length - 1; index++)
      if (sortedBoundaries[index + 1] > sortedBoundaries[index])
        _inlineForSegment(
          text.substring(sortedBoundaries[index], sortedBoundaries[index + 1]),
          _activeStyleRangesForSegment(
            normalized,
            sortedBoundaries[index],
            sortedBoundaries[index + 1],
          ),
        ),
  ];
  return _mergeAdjacentInlineStyles(segments);
}

List<BusyInline> _mergeAdjacentInlineStyles(List<BusyInline> inlines) {
  final merged = <BusyInline>[];
  for (final sourceInline in inlines) {
    final inline = sourceInline.children.isEmpty
        ? sourceInline
        : sourceInline.copyWith(
            children: _mergeAdjacentInlineStyles(sourceInline.children),
          );
    if (merged.isEmpty || !_canMergeInlineStyles(merged.last, inline)) {
      merged.add(inline);
      continue;
    }
    final previous = merged.removeLast();
    if (inline.kind == BusyInlineKind.text) {
      merged.add(previous.copyWith(text: previous.text + inline.text));
      continue;
    }
    final children = _mergeAdjacentInlineStyles([
      ...previous.children,
      ...inline.children,
    ]);
    merged.add(
      previous.copyWith(
        text: children.map((child) => child.plainText).join(),
        children: children,
      ),
    );
  }
  return merged;
}

bool _canMergeInlineStyles(BusyInline left, BusyInline right) {
  if (left.kind != right.kind || left.destination != right.destination) {
    return false;
  }
  if (left.kind == BusyInlineKind.text) {
    return left.children.isEmpty && right.children.isEmpty;
  }
  return left.children.isNotEmpty &&
      right.children.isNotEmpty &&
      switch (left.kind) {
        BusyInlineKind.strong ||
        BusyInlineKind.emphasis ||
        BusyInlineKind.underline ||
        BusyInlineKind.strikethrough ||
        BusyInlineKind.link => true,
        _ => false,
      };
}

List<BusyInlineStyleRange> _styleRangesForSlice(
  List<BusyInlineStyleRange> ranges,
  int start,
  int end,
) {
  if (end <= start) {
    return const [];
  }
  return [
    for (final range in ranges)
      if (range.end > start && range.start < end)
        BusyInlineStyleRange(
          start: (range.start < start ? start : range.start) - start,
          end: (range.end > end ? end : range.end) - start,
          kind: range.kind,
          destination: range.destination,
        ),
  ];
}

List<BusyInlineStyleRange> _shiftStyleRanges(
  List<BusyInlineStyleRange> ranges,
  int offset,
) {
  if (offset == 0) {
    return ranges;
  }
  return [
    for (final range in ranges)
      BusyInlineStyleRange(
        start: range.start + offset,
        end: range.end + offset,
        kind: range.kind,
        destination: range.destination,
      ),
  ];
}

List<BusyInlineStyleRange> _normalizedStyleRanges(
  List<BusyInlineStyleRange> ranges,
  int textLength,
) {
  return [
    for (final range in ranges)
      if (range.end > range.start)
        BusyInlineStyleRange(
          start: range.start.clamp(0, textLength).toInt(),
          end: range.end.clamp(0, textLength).toInt(),
          kind: range.kind,
          destination: range.destination,
        ),
  ].where((range) => range.end > range.start).toList();
}

List<BusyInlineStyleRange> _activeStyleRangesForSegment(
  List<BusyInlineStyleRange> ranges,
  int start,
  int end,
) {
  final byKind = <BusyInlineKind, BusyInlineStyleRange>{};
  for (final range in ranges) {
    if (range.start <= start && range.end >= end) {
      byKind[range.kind] = range;
    }
  }
  return byKind.values.toList()..sort(_compareStyleRanges);
}

BusyInline _inlineForSegment(String text, List<BusyInlineStyleRange> styles) {
  var inline = BusyInline(kind: BusyInlineKind.text, text: text);
  for (final style in styles.reversed) {
    inline = BusyInline(
      kind: style.kind,
      text: inline.plainText,
      destination: style.destination,
      children:
          style.kind == BusyInlineKind.code ||
              style.kind == BusyInlineKind.image
          ? const []
          : [inline],
    );
  }
  return inline;
}

int _compareStyleRanges(BusyInlineStyleRange a, BusyInlineStyleRange b) {
  return _stylePriority(a.kind).compareTo(_stylePriority(b.kind));
}

int _stylePriority(BusyInlineKind kind) {
  return switch (kind) {
    BusyInlineKind.link => 0,
    BusyInlineKind.strong => 1,
    BusyInlineKind.emphasis => 2,
    BusyInlineKind.underline => 3,
    BusyInlineKind.strikethrough => 4,
    BusyInlineKind.code => 5,
    BusyInlineKind.image => 6,
    _ => 7,
  };
}
