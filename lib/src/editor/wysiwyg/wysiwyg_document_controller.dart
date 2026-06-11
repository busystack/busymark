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

  BusyDocument get document => _document;

  String get markdown => _serializer.serialize(_document);

  void replaceDocument(BusyDocument document) {
    _document = _ensureEditableDocument(document);
    notifyListeners();
  }

  String blockText(String blockId) {
    final block = _blockById(blockId);
    return block?.plainText ?? '';
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

  void applyBlockCommand(String blockId, BusyWysiwygBlockCommand command) {
    _replaceBlock(blockId, (block) {
      final kind = blockKindForCommand(command);
      final attributes = {...block.attributes};
      if (command == BusyWysiwygBlockCommand.heading1) {
        attributes['level'] = '1';
      } else if (command == BusyWysiwygBlockCommand.heading2) {
        attributes['level'] = '2';
      } else if (command == BusyWysiwygBlockCommand.heading3) {
        attributes['level'] = '3';
      } else {
        attributes.remove('level');
      }
      if (kind == BusyBlockKind.heading) {
        final text = block.plainText.trim();
        attributes['id'] = slugForHeading(text);
        attributes['generatedId'] = 'true';
      }
      if (kind == BusyBlockKind.orderedListItem) {
        attributes['ordered'] = 'true';
        attributes['marker'] = attributes['marker'] ?? '1.';
      }
      if (kind == BusyBlockKind.unorderedListItem) {
        attributes['ordered'] = 'false';
        attributes['marker'] = '-';
      }
      if (kind == BusyBlockKind.taskListItem) {
        attributes['ordered'] = 'false';
        attributes['marker'] = '-';
        attributes['task'] = attributes['task'] ?? 'false';
      }
      return block.copyWith(kind: kind, attributes: attributes, dirty: true);
    });
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
    _replaceBlock(blockId, (block) {
      final text = block.plainText;
      final safeStart = start.clamp(0, text.length);
      final safeEnd = end.clamp(safeStart, text.length);
      final inlineKind = inlineKindForCommand(command);
      final existingRanges = busyInlineStyleRanges(block.inlines);
      final removeExistingStyle =
          command != BusyWysiwygInlineCommand.link &&
          _selectionCoveredByKind(
            existingRanges,
            inlineKind,
            safeStart,
            safeEnd,
          );
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
    });
  }

  BusyBlock? _blockById(String blockId) {
    for (final block in _flatten(_document.blocks)) {
      if (block.id == blockId) {
        return block;
      }
    }
    return null;
  }

  void _replaceBlock(String blockId, BusyBlock Function(BusyBlock) replace) {
    _document = _document.copyWith(
      blocks: _replaceInBlocks(_document.blocks, blockId, replace),
    );
    notifyListeners();
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

  Iterable<BusyBlock> _flatten(List<BusyBlock> blocks) sync* {
    for (final block in blocks) {
      yield block;
      yield* _flatten(block.children);
    }
  }
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
