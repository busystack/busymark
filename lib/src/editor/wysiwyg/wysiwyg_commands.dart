import '../../markdown/busymark_document.dart';

enum BusyWysiwygBlockCommand {
  paragraph,
  heading1,
  heading2,
  heading3,
  heading4,
  heading5,
  heading6,
  unorderedList,
  orderedList,
  taskList,
  blockquote,
  codeBlock,
  image,
  thematicBreak,
}

enum BusyWysiwygInlineCommand {
  bold,
  italic,
  underline,
  strikethrough,
  code,
  link,
}

/// Whether [block] can safely be replaced by a generic block command.
///
/// Structured and source-preserved blocks need dedicated transformations. A
/// generic conversion only changes the block kind and inline metadata, so
/// applying it to one of those blocks would strand or discard its payload.
bool busyMarkWysiwygCanApplyBlockCommand(
  BusyBlock block,
  BusyWysiwygBlockCommand command,
) {
  if (command == BusyWysiwygBlockCommand.image &&
      block.kind == BusyBlockKind.image &&
      !block.isSourceProtected) {
    return true;
  }
  if (block.preserveRaw ||
      block.isSourceOnly ||
      block.isGenerated ||
      block.isSourceProtected) {
    return false;
  }
  if (block.children.isNotEmpty) {
    final destinationKind = blockKindForCommand(command);
    if (!_hasSafeStructuredConversion(block, destinationKind)) {
      return false;
    }
  }
  return switch (block.kind) {
    BusyBlockKind.paragraph ||
    BusyBlockKind.heading ||
    BusyBlockKind.codeBlock ||
    BusyBlockKind.unorderedListItem ||
    BusyBlockKind.orderedListItem ||
    BusyBlockKind.taskListItem ||
    BusyBlockKind.blockquote => true,
    BusyBlockKind.math ||
    BusyBlockKind.thematicBreak ||
    BusyBlockKind.image ||
    BusyBlockKind.video ||
    BusyBlockKind.table ||
    BusyBlockKind.htmlBlock ||
    BusyBlockKind.writersideAdmonition ||
    BusyBlockKind.writersideTabs ||
    BusyBlockKind.writersideProcedure ||
    BusyBlockKind.writersideRawXml ||
    BusyBlockKind.frontMatter ||
    BusyBlockKind.unknown => false,
  };
}

bool busyMarkWysiwygCanApplyAdmonitionStyle(BusyBlock block) {
  if (block.kind == BusyBlockKind.writersideAdmonition &&
      !block.preserveRaw &&
      !block.isSourceOnly &&
      !block.isGenerated &&
      !block.isSourceProtected) {
    return true;
  }
  return busyMarkWysiwygCanApplyBlockCommand(
    block,
    BusyWysiwygBlockCommand.blockquote,
  );
}

bool _hasSafeStructuredConversion(
  BusyBlock block,
  BusyBlockKind destinationKind,
) {
  final sourceIsList = _isListItemKind(block.kind);
  final destinationIsList = _isListItemKind(destinationKind);
  if (sourceIsList) {
    // List-family conversions share the same inline/children representation.
    // Converting to a quote is handled by an explicit structural transform.
    return destinationIsList || destinationKind == BusyBlockKind.blockquote;
  }
  if (block.kind == BusyBlockKind.blockquote) {
    // The reverse list conversion is also structural: its leading paragraph
    // becomes the list item's own inline content.
    return destinationKind == BusyBlockKind.blockquote || destinationIsList;
  }
  return false;
}

bool _isListItemKind(BusyBlockKind kind) {
  return switch (kind) {
    BusyBlockKind.unorderedListItem ||
    BusyBlockKind.orderedListItem ||
    BusyBlockKind.taskListItem => true,
    _ => false,
  };
}

BusyBlockKind blockKindForCommand(BusyWysiwygBlockCommand command) {
  return switch (command) {
    BusyWysiwygBlockCommand.paragraph => BusyBlockKind.paragraph,
    BusyWysiwygBlockCommand.heading1 ||
    BusyWysiwygBlockCommand.heading2 ||
    BusyWysiwygBlockCommand.heading3 ||
    BusyWysiwygBlockCommand.heading4 ||
    BusyWysiwygBlockCommand.heading5 ||
    BusyWysiwygBlockCommand.heading6 => BusyBlockKind.heading,
    BusyWysiwygBlockCommand.unorderedList => BusyBlockKind.unorderedListItem,
    BusyWysiwygBlockCommand.orderedList => BusyBlockKind.orderedListItem,
    BusyWysiwygBlockCommand.taskList => BusyBlockKind.taskListItem,
    BusyWysiwygBlockCommand.blockquote => BusyBlockKind.blockquote,
    BusyWysiwygBlockCommand.codeBlock => BusyBlockKind.codeBlock,
    BusyWysiwygBlockCommand.image => BusyBlockKind.image,
    BusyWysiwygBlockCommand.thematicBreak => BusyBlockKind.thematicBreak,
  };
}

BusyInlineKind inlineKindForCommand(BusyWysiwygInlineCommand command) {
  return switch (command) {
    BusyWysiwygInlineCommand.bold => BusyInlineKind.strong,
    BusyWysiwygInlineCommand.italic => BusyInlineKind.emphasis,
    BusyWysiwygInlineCommand.underline => BusyInlineKind.underline,
    BusyWysiwygInlineCommand.strikethrough => BusyInlineKind.strikethrough,
    BusyWysiwygInlineCommand.code => BusyInlineKind.code,
    BusyWysiwygInlineCommand.link => BusyInlineKind.link,
  };
}
