import 'package:flutter/foundation.dart';

import '../../core/path_utils.dart';
import '../../markdown/busymark_document.dart';
import '../../markdown/busymark_markdown_serializer.dart';
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

  void updateBlockText(String blockId, String text) {
    _replaceBlock(
      blockId,
      (block) => block.copyWith(
        inlines: [BusyInline(kind: BusyInlineKind.text, text: text)],
        dirty: true,
      ),
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
    final replacements = <BusyBlock>[
      block.copyWith(
        inlines: _textInlines(parts.first),
        preserveRaw: false,
        dirty: true,
      ),
      for (final (index, part) in parts.skip(1).indexed)
        BusyBlock(
          id: _nextGeneratedBlockId(_newBlockPrefixFor(block.kind)),
          kind: _splitKindFor(block.kind),
          inlines: _textInlines(part),
          attributes: _splitAttributesFor(
            block,
            _splitKindFor(block.kind),
            orderedOffset: index + 1,
          ),
          dirty: true,
        ),
    ];
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

  String? splitBlockAt(String blockId, int offset) {
    final block = blockById(blockId);
    if (block == null) {
      return null;
    }
    final text = block.plainText;
    final safeOffset = offset.clamp(0, text.length).toInt();
    final leftText = text.substring(0, safeOffset);
    final rightText = text.substring(safeOffset);
    final nextBlockId = _nextGeneratedBlockId(_newBlockPrefixFor(block.kind));
    final nextKind = _splitKindFor(block.kind);
    final currentBlock = block.copyWith(
      inlines: _textInlines(leftText),
      preserveRaw: false,
      dirty: true,
    );
    final nextBlock = BusyBlock(
      id: nextBlockId,
      kind: nextKind,
      inlines: _textInlines(rightText),
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
    return [
      for (final block in blocks)
        if (block.id == blockId)
          replace(block)
        else
          block.copyWith(
            children: _replaceInBlocks(block.children, blockId, replace),
          ),
    ];
  }

  List<BusyBlock> _replaceBlockWithMany(
    List<BusyBlock> blocks,
    String blockId,
    List<BusyBlock> replacements,
  ) {
    return [
      for (final block in blocks)
        if (block.id == blockId)
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

  List<BusyBlock> _insertBlocksAfter(
    List<BusyBlock> blocks,
    String blockId,
    List<BusyBlock> insertedBlocks,
  ) {
    return [
      for (final block in blocks) ...[
        block.copyWith(
          children: _insertBlocksAfter(block.children, blockId, insertedBlocks),
        ),
        if (block.id == blockId) ...insertedBlocks,
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
        if (blockIds.contains(block.id))
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
}

class BusyWysiwygTextSplitResult {
  const BusyWysiwygTextSplitResult({
    required this.blockId,
    required this.offset,
  });

  final String blockId;
  final int offset;
}

List<BusyInline> _textInlines(String text) {
  return [BusyInline(kind: BusyInlineKind.text, text: text)];
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
    (block) => block.kind != BusyBlockKind.frontMatter,
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
    BusyInlineKind.strikethrough => 3,
    BusyInlineKind.code => 4,
    BusyInlineKind.image => 5,
    _ => 6,
  };
}
