import '../../markdown/busymark_document.dart';

enum BusyWysiwygBlockCommand {
  paragraph,
  heading1,
  heading2,
  heading3,
  unorderedList,
  orderedList,
  taskList,
  blockquote,
  codeBlock,
  image,
  thematicBreak,
}

enum BusyWysiwygInlineCommand { bold, italic, strikethrough, code, link }

BusyBlockKind blockKindForCommand(BusyWysiwygBlockCommand command) {
  return switch (command) {
    BusyWysiwygBlockCommand.paragraph => BusyBlockKind.paragraph,
    BusyWysiwygBlockCommand.heading1 ||
    BusyWysiwygBlockCommand.heading2 ||
    BusyWysiwygBlockCommand.heading3 => BusyBlockKind.heading,
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
    BusyWysiwygInlineCommand.strikethrough => BusyInlineKind.strikethrough,
    BusyWysiwygInlineCommand.code => BusyInlineKind.code,
    BusyWysiwygInlineCommand.link => BusyInlineKind.link,
  };
}
