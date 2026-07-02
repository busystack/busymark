import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

enum BusyMarkEditorShortcutAction {
  bold,
  italic,
  underline,
  strikethrough,
  inlineCode,
  link,
  paragraph,
  heading1,
  heading2,
  heading3,
  heading4,
  heading5,
  heading6,
  orderedList,
  unorderedList,
  taskList,
  toggleTask,
  indent,
  outdent,
  blockquote,
  codeBlock,
  codeBlockLanguage,
  image,
  inlineImage,
  table,
  thematicBreak,
  hardLineBreak,
  pastePlainText,
}

class BusyMarkEditorShortcutLabels {
  const BusyMarkEditorShortcutLabels._();

  static const textStyle = 'Ctrl+Shift+0-6';
  static const bold = 'Ctrl+B';
  static const italic = 'Ctrl+I';
  static const underline = 'Ctrl+U';
  static const strikethrough = 'Alt+Shift+5';
  static const inlineCode = 'Ctrl+E';
  static const link = 'Ctrl+K';
  static const paragraph = 'Ctrl+Shift+0';
  static const heading1 = 'Ctrl+Shift+1';
  static const heading2 = 'Ctrl+Shift+2';
  static const heading3 = 'Ctrl+Shift+3';
  static const heading4 = 'Ctrl+Shift+4';
  static const heading5 = 'Ctrl+Shift+5';
  static const heading6 = 'Ctrl+Shift+6';
  static const orderedList = 'Ctrl+Shift+7';
  static const unorderedList = 'Ctrl+Shift+8';
  static const taskList = 'Ctrl+Shift+9';
  static const toggleTask = 'Ctrl+Shift+X';
  static const indent = 'Ctrl+]';
  static const outdent = 'Ctrl+[';
  static const blockquote = 'Ctrl+Shift+.';
  static const codeBlock = 'Ctrl+Alt+C';
  static const codeBlockLanguage = 'Ctrl+Alt+G';
  static const image = 'Ctrl+Alt+I';
  static const inlineImage = 'Ctrl+Alt+Shift+I';
  static const table = 'Ctrl+Shift+T';
  static const thematicBreak = 'Ctrl+Alt+R';
  static const hardLineBreak = 'Shift+Enter';
}

class BusyMarkEditorShortcutActivators {
  const BusyMarkEditorShortcutActivators._();

  static const actionActivators =
      <BusyMarkEditorShortcutAction, ShortcutActivator>{
        BusyMarkEditorShortcutAction.bold: bold,
        BusyMarkEditorShortcutAction.italic: italic,
        BusyMarkEditorShortcutAction.underline: underline,
        BusyMarkEditorShortcutAction.strikethrough: strikethrough,
        BusyMarkEditorShortcutAction.inlineCode: inlineCode,
        BusyMarkEditorShortcutAction.link: link,
        BusyMarkEditorShortcutAction.paragraph: paragraph,
        BusyMarkEditorShortcutAction.heading1: heading1,
        BusyMarkEditorShortcutAction.heading2: heading2,
        BusyMarkEditorShortcutAction.heading3: heading3,
        BusyMarkEditorShortcutAction.heading4: heading4,
        BusyMarkEditorShortcutAction.heading5: heading5,
        BusyMarkEditorShortcutAction.heading6: heading6,
        BusyMarkEditorShortcutAction.orderedList: orderedList,
        BusyMarkEditorShortcutAction.unorderedList: unorderedList,
        BusyMarkEditorShortcutAction.taskList: taskList,
        BusyMarkEditorShortcutAction.toggleTask: toggleTask,
        BusyMarkEditorShortcutAction.indent: indent,
        BusyMarkEditorShortcutAction.outdent: outdent,
        BusyMarkEditorShortcutAction.blockquote: blockquote,
        BusyMarkEditorShortcutAction.codeBlock: codeBlock,
        BusyMarkEditorShortcutAction.codeBlockLanguage: codeBlockLanguage,
        BusyMarkEditorShortcutAction.image: image,
        BusyMarkEditorShortcutAction.inlineImage: inlineImage,
        BusyMarkEditorShortcutAction.table: table,
        BusyMarkEditorShortcutAction.thematicBreak: thematicBreak,
        BusyMarkEditorShortcutAction.hardLineBreak: hardLineBreak,
        BusyMarkEditorShortcutAction.pastePlainText: pastePlainText,
      };

  static Map<ShortcutActivator, Intent> intentMap(
    Intent Function(BusyMarkEditorShortcutAction action) intentFor,
  ) {
    return {
      for (final entry in actionActivators.entries)
        entry.value: intentFor(entry.key),
    };
  }

  static BusyMarkEditorShortcutAction? actionForKeyEvent(
    KeyEvent event,
    HardwareKeyboard keyboard,
  ) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return null;
    }
    for (final entry in actionActivators.entries) {
      if (entry.value.accepts(event, keyboard)) {
        return entry.key;
      }
    }
    return null;
  }

  static const bold = SingleActivator(LogicalKeyboardKey.keyB, control: true);
  static const italic = SingleActivator(LogicalKeyboardKey.keyI, control: true);
  static const underline = SingleActivator(
    LogicalKeyboardKey.keyU,
    control: true,
  );
  static const link = SingleActivator(LogicalKeyboardKey.keyK, control: true);
  static const inlineCode = SingleActivator(
    LogicalKeyboardKey.keyE,
    control: true,
  );
  static const strikethrough = SingleActivator(
    LogicalKeyboardKey.digit5,
    alt: true,
    shift: true,
  );
  static const paragraph = SingleActivator(
    LogicalKeyboardKey.digit0,
    control: true,
    shift: true,
  );
  static const heading1 = SingleActivator(
    LogicalKeyboardKey.digit1,
    control: true,
    shift: true,
  );
  static const heading2 = SingleActivator(
    LogicalKeyboardKey.digit2,
    control: true,
    shift: true,
  );
  static const heading3 = SingleActivator(
    LogicalKeyboardKey.digit3,
    control: true,
    shift: true,
  );
  static const heading4 = SingleActivator(
    LogicalKeyboardKey.digit4,
    control: true,
    shift: true,
  );
  static const heading5 = SingleActivator(
    LogicalKeyboardKey.digit5,
    control: true,
    shift: true,
  );
  static const heading6 = SingleActivator(
    LogicalKeyboardKey.digit6,
    control: true,
    shift: true,
  );
  static const orderedList = SingleActivator(
    LogicalKeyboardKey.digit7,
    control: true,
    shift: true,
  );
  static const unorderedList = SingleActivator(
    LogicalKeyboardKey.digit8,
    control: true,
    shift: true,
  );
  static const taskList = SingleActivator(
    LogicalKeyboardKey.digit9,
    control: true,
    shift: true,
  );
  static const toggleTask = SingleActivator(
    LogicalKeyboardKey.keyX,
    control: true,
    shift: true,
  );
  static const indent = SingleActivator(
    LogicalKeyboardKey.bracketRight,
    control: true,
  );
  static const outdent = SingleActivator(
    LogicalKeyboardKey.bracketLeft,
    control: true,
  );
  static const blockquote = SingleActivator(
    LogicalKeyboardKey.period,
    control: true,
    shift: true,
  );
  static const codeBlock = SingleActivator(
    LogicalKeyboardKey.keyC,
    control: true,
    alt: true,
  );
  static const codeBlockLanguage = SingleActivator(
    LogicalKeyboardKey.keyG,
    control: true,
    alt: true,
  );
  static const image = SingleActivator(
    LogicalKeyboardKey.keyI,
    control: true,
    alt: true,
  );
  static const inlineImage = SingleActivator(
    LogicalKeyboardKey.keyI,
    control: true,
    alt: true,
    shift: true,
  );
  static const table = SingleActivator(
    LogicalKeyboardKey.keyT,
    control: true,
    shift: true,
  );
  static const thematicBreak = SingleActivator(
    LogicalKeyboardKey.keyR,
    control: true,
    alt: true,
  );
  static const hardLineBreak = SingleActivator(
    LogicalKeyboardKey.enter,
    shift: true,
  );
  static const pastePlainText = SingleActivator(
    LogicalKeyboardKey.keyV,
    control: true,
    shift: true,
  );
}

class BusyMarkSidebarShortcutLabels {
  const BusyMarkSidebarShortcutLabels._();

  static const toggleSidebar = 'F9';
  static const files = 'Ctrl+1';
  static const toc = 'Ctrl+2';
  static const outline = 'Ctrl+3';
  static const git = 'Ctrl+4';
}
