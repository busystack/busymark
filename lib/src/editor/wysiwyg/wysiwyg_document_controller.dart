import 'package:flutter/foundation.dart';

import '../../core/path_utils.dart';
import '../../markdown/busymark_document.dart';
import '../../markdown/busymark_markdown_serializer.dart';
import '../../markdown/raw_html_adapter.dart';
import 'wysiwyg_commands.dart';
import 'wysiwyg_inline_controller.dart';

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
    return block?.plainText ?? '';
  }

  BusyBlock? blockById(String blockId) {
    for (final block in _flatten(_document.blocks)) {
      if (block.id == blockId) {
        return block;
      }
    }
    return null;
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
              cells.add(_blockWithEditedText(cell, text));
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
          block.copyWith(inlines: inlines, preserveRaw: false, dirty: true),
        );
      } else {
        replacements.add(
          BusyBlock(
            id: _nextGeneratedBlockId(_newBlockPrefixFor(block.kind)),
            kind: _splitKindFor(block.kind),
            inlines: inlines,
            attributes: _splitAttributesFor(
              block,
              _splitKindFor(block.kind),
              orderedOffset: index,
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
    if (command == BusyWysiwygBlockCommand.thematicBreak) {
      insertThematicBreakAfter(blockId);
      return;
    }
    _replaceBlock(blockId, (block) => _blockWithCommand(block, command));
  }

  void applyBlockCommandToBlocks(
    Iterable<String> blockIds,
    BusyWysiwygBlockCommand command,
  ) {
    final ids = blockIds.toList();
    if (ids.isEmpty) {
      return;
    }
    if (command == BusyWysiwygBlockCommand.thematicBreak) {
      insertThematicBreakAfter(ids.last);
      return;
    }
    final idSet = ids.toSet();
    var orderedIndex = 0;
    _document = _document.copyWith(
      blocks: _replaceBlocksByIds(_document.blocks, idSet, (block) {
        final orderedNumber = command == BusyWysiwygBlockCommand.orderedList
            ? ++orderedIndex
            : null;
        return _blockWithCommand(block, command, orderedNumber: orderedNumber);
      }),
    );
    notifyListeners();
  }

  void applyImageBlock(
    String blockId, {
    required String source,
    required String alt,
  }) {
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
      final nextRows = [...rows]
        ..insert(
          insertIndex.clamp(0, rows.length).toInt(),
          _newTableRow(columnCount),
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
              attributes: {'cell': header ? 'th' : 'td'},
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

  BusyBlock _newTableRow(int columns) {
    return BusyBlock(
      id: _nextGeneratedBlockId('table-row'),
      kind: BusyBlockKind.table,
      children: [
        for (var column = 0; column < columns; column++) _newTableCell(),
      ],
      dirty: true,
    );
  }

  BusyBlock _newTableCell() {
    return BusyBlock(
      id: _nextGeneratedBlockId('table-cell'),
      kind: BusyBlockKind.paragraph,
      inlines: _textInlines(''),
      dirty: true,
    );
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

  void indentListItems(Iterable<String> blockIds) {
    final ids = blockIds.toSet();
    if (ids.isEmpty) {
      return;
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
          result.add(
            parent.copyWith(
              children: [...parent.children, updated.copyWith(dirty: true)],
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
      return;
    }
    _document = _document.copyWith(blocks: blocks);
    notifyListeners();
  }

  void outdentListItems(Iterable<String> blockIds) {
    final ids = blockIds.toSet();
    if (ids.isEmpty) {
      return;
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
      return;
    }
    _document = _document.copyWith(blocks: result);
    notifyListeners();
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
      attributes: block.attributes,
      dirty: true,
    );
    final nextBlock = BusyBlock(
      id: nextBlockId,
      kind: nextKind,
      inlines: _inlinesFromStyleRanges(
        rightText,
        _styleRangesForSlice(ranges, safeOffset, text.length),
      ),
      attributes: _splitAttributesFor(block, nextKind, orderedOffset: 1),
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
      _document = _document.copyWith(
        blocks: [...blocks.take(index), ...blocks.skip(index + 1)],
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
    if (_isReadOnlySelectionEndpoint(firstBlock) ||
        _isReadOnlySelectionEndpoint(lastBlock)) {
      return null;
    }
    final firstText = firstBlock.plainText;
    final lastText = lastBlock.plainText;
    final firstStart = firstStartOffset.clamp(0, firstText.length).toInt();
    final lastEnd = lastEndOffset.clamp(0, lastText.length).toInt();
    if (firstBlockId == lastBlockId) {
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

    final mergedText =
        firstText.substring(0, firstStart) + lastText.substring(lastEnd);
    final removeIds = removedBlockIds.where((id) => id != firstBlockId).toSet();
    _document = _document.copyWith(
      blocks: _removeBlocksByIds(
        _replaceInBlocks(
          _document.blocks,
          firstBlockId,
          (block) => _blockWithEditedText(block, mergedText),
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
    return [
      for (final block in blocks)
        if (block.isSourceProtected)
          block
        else if (blockIds.contains(block.id))
          replace(block)
        else
          block.copyWith(
            children: _replaceBlocksByIds(block.children, blockIds, replace),
          ),
    ];
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
  }) {
    final kind = styled.kind;
    return BusyBlock(
      id: _nextGeneratedBlockId(_newBlockPrefixFor(kind)),
      kind: kind,
      inlines: _inlinesFromStyleRanges(
        text ?? styled.text,
        ranges ?? styled.ranges,
      ),
      attributes: styled.attributes,
      preserveRaw: false,
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
  });

  final BusyBlockKind kind;
  final String text;
  final List<BusyInlineStyleRange> ranges;
  final Map<String, String> attributes;
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
    preserveRaw: false,
    dirty: true,
  );
}

BusyBlock _blockWithCommand(
  BusyBlock block,
  BusyWysiwygBlockCommand command, {
  int? orderedNumber,
}) {
  final kind = blockKindForCommand(command);
  final attributes = {...block.attributes}
    ..remove('ordered')
    ..remove('marker')
    ..remove('task');
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
    attributes['marker'] = orderedNumber == null
        ? block.attributes['marker'] ?? '1.'
        : '$orderedNumber.';
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
  final hasEditableBlock = document.blocks.any(
    (block) =>
        block.kind != BusyBlockKind.frontMatter &&
        !block.isSourceOnly &&
        !block.isSourceProtected,
  );
  if (hasEditableBlock) {
    return document;
  }
  return document.copyWith(
    blocks: [
      ...document.blocks,
      const BusyBlock(
        id: 'empty-paragraph',
        kind: BusyBlockKind.paragraph,
        inlines: [BusyInline(kind: BusyInlineKind.text, text: '')],
      ),
    ],
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
  return [
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
