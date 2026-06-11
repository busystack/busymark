import 'package:flutter/foundation.dart';

import '../../core/path_utils.dart';
import '../../markdown/busymark_document.dart';
import '../../markdown/busymark_markdown_serializer.dart';
import 'wysiwyg_commands.dart';

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
      final selected = text.substring(safeStart, safeEnd);
      final inlineKind = inlineKindForCommand(command);
      return block.copyWith(
        inlines: [
          if (safeStart > 0)
            BusyInline(
              kind: BusyInlineKind.text,
              text: text.substring(0, safeStart),
            ),
          BusyInline(
            kind: inlineKind,
            text: selected,
            destination: command == BusyWysiwygInlineCommand.link
                ? destination
                : null,
            children: inlineKind == BusyInlineKind.code
                ? const []
                : [BusyInline(kind: BusyInlineKind.text, text: selected)],
          ),
          if (safeEnd < text.length)
            BusyInline(
              kind: BusyInlineKind.text,
              text: text.substring(safeEnd),
            ),
        ],
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
