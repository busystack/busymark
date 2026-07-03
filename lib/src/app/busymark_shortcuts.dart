import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class BusyMarkShortcutDefinition {
  const BusyMarkShortcutDefinition({
    required this.label,
    required this.activator,
  });

  final String label;
  final ShortcutActivator activator;
}

enum BusyMarkAppShortcutAction {
  newDocument,
  open,
  save,
  find,
  keyboardShortcuts,
  markdownAndHtml,
  settings,
  nextTab,
  previousTab,
  closeTab,
  closeAllTabs,
  toggleSidebar,
}

abstract final class BusyMarkAppShortcuts {
  const BusyMarkAppShortcuts._();

  static const newDocumentLabel = 'Ctrl+N';
  static const openLabel = 'Ctrl+O';
  static const saveLabel = 'Ctrl+S';
  static const findLabel = 'Ctrl+F';
  static const keyboardShortcutsLabel = 'Ctrl+Shift+/';
  static const markdownAndHtmlLabel = 'Ctrl+Shift+M';
  static const settingsLabel = 'Ctrl+Alt+S';
  static const nextTabLabel = 'Ctrl+Tab';
  static const previousTabLabel = 'Ctrl+Shift+Tab';
  static const closeTabLabel = 'Ctrl+W';
  static const closeAllTabsLabel = 'Ctrl+Shift+W';
  static const toggleSidebarLabel = 'F9';

  static const newDocument = BusyMarkShortcutDefinition(
    label: newDocumentLabel,
    activator: SingleActivator(LogicalKeyboardKey.keyN, control: true),
  );
  static const open = BusyMarkShortcutDefinition(
    label: openLabel,
    activator: SingleActivator(LogicalKeyboardKey.keyO, control: true),
  );
  static const save = BusyMarkShortcutDefinition(
    label: saveLabel,
    activator: SingleActivator(LogicalKeyboardKey.keyS, control: true),
  );
  static const find = BusyMarkShortcutDefinition(
    label: findLabel,
    activator: SingleActivator(LogicalKeyboardKey.keyF, control: true),
  );
  static const keyboardShortcuts = BusyMarkShortcutDefinition(
    label: keyboardShortcutsLabel,
    activator: SingleActivator(
      LogicalKeyboardKey.slash,
      control: true,
      shift: true,
    ),
  );
  static const markdownAndHtml = BusyMarkShortcutDefinition(
    label: markdownAndHtmlLabel,
    activator: SingleActivator(
      LogicalKeyboardKey.keyM,
      control: true,
      shift: true,
    ),
  );
  static const settings = BusyMarkShortcutDefinition(
    label: settingsLabel,
    activator: SingleActivator(
      LogicalKeyboardKey.keyS,
      control: true,
      alt: true,
    ),
  );
  static const nextTab = BusyMarkShortcutDefinition(
    label: nextTabLabel,
    activator: SingleActivator(LogicalKeyboardKey.tab, control: true),
  );
  static const previousTab = BusyMarkShortcutDefinition(
    label: previousTabLabel,
    activator: SingleActivator(
      LogicalKeyboardKey.tab,
      control: true,
      shift: true,
    ),
  );
  static const closeTab = BusyMarkShortcutDefinition(
    label: closeTabLabel,
    activator: SingleActivator(LogicalKeyboardKey.keyW, control: true),
  );
  static const closeAllTabs = BusyMarkShortcutDefinition(
    label: closeAllTabsLabel,
    activator: SingleActivator(
      LogicalKeyboardKey.keyW,
      control: true,
      shift: true,
    ),
  );
  static const toggleSidebar = BusyMarkShortcutDefinition(
    label: toggleSidebarLabel,
    activator: SingleActivator(LogicalKeyboardKey.f9),
  );

  static const definitions =
      <BusyMarkAppShortcutAction, BusyMarkShortcutDefinition>{
        BusyMarkAppShortcutAction.newDocument: newDocument,
        BusyMarkAppShortcutAction.open: open,
        BusyMarkAppShortcutAction.save: save,
        BusyMarkAppShortcutAction.find: find,
        BusyMarkAppShortcutAction.keyboardShortcuts: keyboardShortcuts,
        BusyMarkAppShortcutAction.markdownAndHtml: markdownAndHtml,
        BusyMarkAppShortcutAction.settings: settings,
        BusyMarkAppShortcutAction.nextTab: nextTab,
        BusyMarkAppShortcutAction.previousTab: previousTab,
        BusyMarkAppShortcutAction.closeTab: closeTab,
        BusyMarkAppShortcutAction.closeAllTabs: closeAllTabs,
        BusyMarkAppShortcutAction.toggleSidebar: toggleSidebar,
      };
}

abstract final class BusyMarkAppShortcutLabels {
  const BusyMarkAppShortcutLabels._();

  static const newDocument = BusyMarkAppShortcuts.newDocumentLabel;
  static const open = BusyMarkAppShortcuts.openLabel;
  static const save = BusyMarkAppShortcuts.saveLabel;
  static const find = BusyMarkAppShortcuts.findLabel;
  static const keyboardShortcuts = BusyMarkAppShortcuts.keyboardShortcutsLabel;
  static const markdownAndHtml = BusyMarkAppShortcuts.markdownAndHtmlLabel;
  static const settings = BusyMarkAppShortcuts.settingsLabel;
  static const nextTab = BusyMarkAppShortcuts.nextTabLabel;
  static const previousTab = BusyMarkAppShortcuts.previousTabLabel;
  static const closeTab = BusyMarkAppShortcuts.closeTabLabel;
  static const closeAllTabs = BusyMarkAppShortcuts.closeAllTabsLabel;
}

abstract final class BusyMarkAppShortcutActivators {
  const BusyMarkAppShortcutActivators._();

  static ShortcutActivator get newDocument =>
      BusyMarkAppShortcuts.newDocument.activator;
  static ShortcutActivator get open => BusyMarkAppShortcuts.open.activator;
  static ShortcutActivator get save => BusyMarkAppShortcuts.save.activator;
  static ShortcutActivator get find => BusyMarkAppShortcuts.find.activator;
  static ShortcutActivator get keyboardShortcuts =>
      BusyMarkAppShortcuts.keyboardShortcuts.activator;
  static ShortcutActivator get markdownAndHtml =>
      BusyMarkAppShortcuts.markdownAndHtml.activator;
  static ShortcutActivator get settings =>
      BusyMarkAppShortcuts.settings.activator;
  static ShortcutActivator get nextTab =>
      BusyMarkAppShortcuts.nextTab.activator;
  static ShortcutActivator get previousTab =>
      BusyMarkAppShortcuts.previousTab.activator;
  static ShortcutActivator get closeTab =>
      BusyMarkAppShortcuts.closeTab.activator;
  static ShortcutActivator get closeAllTabs =>
      BusyMarkAppShortcuts.closeAllTabs.activator;
  static ShortcutActivator get toggleSidebar =>
      BusyMarkAppShortcuts.toggleSidebar.activator;
}

enum BusyMarkTextEditingShortcutAction {
  selectAll,
  cut,
  copy,
  paste,
  pastePlainText,
  undo,
  redo,
  clearSelection,
}

abstract final class BusyMarkTextEditingShortcuts {
  const BusyMarkTextEditingShortcuts._();

  static const selectAllLabel = 'Ctrl+A';
  static const cutLabel = 'Ctrl+X';
  static const copyLabel = 'Ctrl+C';
  static const pasteLabel = 'Ctrl+V';
  static const pastePlainTextLabel = 'Ctrl+Shift+V';
  static const undoLabel = 'Ctrl+Z';
  static const redoLabel = 'Ctrl+Shift+Z';
  static const clearSelectionLabel = 'Esc';

  static const selectAll = BusyMarkShortcutDefinition(
    label: selectAllLabel,
    activator: SingleActivator(LogicalKeyboardKey.keyA, control: true),
  );
  static const cut = BusyMarkShortcutDefinition(
    label: cutLabel,
    activator: SingleActivator(LogicalKeyboardKey.keyX, control: true),
  );
  static const copy = BusyMarkShortcutDefinition(
    label: copyLabel,
    activator: SingleActivator(LogicalKeyboardKey.keyC, control: true),
  );
  static const paste = BusyMarkShortcutDefinition(
    label: pasteLabel,
    activator: SingleActivator(LogicalKeyboardKey.keyV, control: true),
  );
  static const pastePlainText = BusyMarkShortcutDefinition(
    label: pastePlainTextLabel,
    activator: SingleActivator(
      LogicalKeyboardKey.keyV,
      control: true,
      shift: true,
    ),
  );
  static const undo = BusyMarkShortcutDefinition(
    label: undoLabel,
    activator: SingleActivator(LogicalKeyboardKey.keyZ, control: true),
  );
  static const redo = BusyMarkShortcutDefinition(
    label: redoLabel,
    activator: SingleActivator(
      LogicalKeyboardKey.keyZ,
      control: true,
      shift: true,
    ),
  );
  static const clearSelection = BusyMarkShortcutDefinition(
    label: clearSelectionLabel,
    activator: SingleActivator(LogicalKeyboardKey.escape),
  );

  static const definitions =
      <BusyMarkTextEditingShortcutAction, BusyMarkShortcutDefinition>{
        BusyMarkTextEditingShortcutAction.selectAll: selectAll,
        BusyMarkTextEditingShortcutAction.cut: cut,
        BusyMarkTextEditingShortcutAction.copy: copy,
        BusyMarkTextEditingShortcutAction.paste: paste,
        BusyMarkTextEditingShortcutAction.pastePlainText: pastePlainText,
        BusyMarkTextEditingShortcutAction.undo: undo,
        BusyMarkTextEditingShortcutAction.redo: redo,
        BusyMarkTextEditingShortcutAction.clearSelection: clearSelection,
      };
}

abstract final class BusyMarkTextEditingShortcutLabels {
  const BusyMarkTextEditingShortcutLabels._();

  static const selectAll = BusyMarkTextEditingShortcuts.selectAllLabel;
  static const cut = BusyMarkTextEditingShortcuts.cutLabel;
  static const copy = BusyMarkTextEditingShortcuts.copyLabel;
  static const paste = BusyMarkTextEditingShortcuts.pasteLabel;
  static const pastePlainText =
      BusyMarkTextEditingShortcuts.pastePlainTextLabel;
  static const undo = BusyMarkTextEditingShortcuts.undoLabel;
  static const redo = BusyMarkTextEditingShortcuts.redoLabel;
  static const clearSelection =
      BusyMarkTextEditingShortcuts.clearSelectionLabel;
}

abstract final class BusyMarkTextEditingShortcutActivators {
  const BusyMarkTextEditingShortcutActivators._();

  static ShortcutActivator get selectAll =>
      BusyMarkTextEditingShortcuts.selectAll.activator;
  static ShortcutActivator get cut =>
      BusyMarkTextEditingShortcuts.cut.activator;
  static ShortcutActivator get copy =>
      BusyMarkTextEditingShortcuts.copy.activator;
  static ShortcutActivator get paste =>
      BusyMarkTextEditingShortcuts.paste.activator;
  static ShortcutActivator get pastePlainText =>
      BusyMarkTextEditingShortcuts.pastePlainText.activator;
  static ShortcutActivator get undo =>
      BusyMarkTextEditingShortcuts.undo.activator;
  static ShortcutActivator get redo =>
      BusyMarkTextEditingShortcuts.redo.activator;
  static ShortcutActivator get clearSelection =>
      BusyMarkTextEditingShortcuts.clearSelection.activator;
}

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
  htmlBlock,
  thematicBreak,
  hardLineBreak,
  pastePlainText,
}

abstract final class BusyMarkEditorShortcuts {
  const BusyMarkEditorShortcuts._();

  static const textStyleLabel = 'Ctrl+Shift+0-6';
  static const boldLabel = 'Ctrl+B';
  static const italicLabel = 'Ctrl+I';
  static const underlineLabel = 'Ctrl+U';
  static const strikethroughLabel = 'Alt+Shift+5';
  static const inlineCodeLabel = 'Ctrl+E';
  static const linkLabel = 'Ctrl+K';
  static const paragraphLabel = 'Ctrl+Shift+0';
  static const heading1Label = 'Ctrl+Shift+1';
  static const heading2Label = 'Ctrl+Shift+2';
  static const heading3Label = 'Ctrl+Shift+3';
  static const heading4Label = 'Ctrl+Shift+4';
  static const heading5Label = 'Ctrl+Shift+5';
  static const heading6Label = 'Ctrl+Shift+6';
  static const orderedListLabel = 'Ctrl+Shift+7';
  static const unorderedListLabel = 'Ctrl+Shift+8';
  static const taskListLabel = 'Ctrl+Shift+9';
  static const toggleTaskLabel = 'Ctrl+Shift+X';
  static const indentLabel = 'Ctrl+]';
  static const outdentLabel = 'Ctrl+[';
  static const blockquoteLabel = 'Ctrl+Shift+.';
  static const codeBlockLabel = 'Ctrl+Alt+C';
  static const codeBlockLanguageLabel = 'Ctrl+Alt+G';
  static const imageLabel = 'Ctrl+Alt+I';
  static const inlineImageLabel = 'Ctrl+Alt+Shift+I';
  static const tableLabel = 'Ctrl+Shift+T';
  static const htmlBlockLabel = 'Ctrl+Alt+H';
  static const thematicBreakLabel = 'Ctrl+Alt+R';
  static const hardLineBreakLabel = 'Shift+Enter';

  static const bold = BusyMarkShortcutDefinition(
    label: boldLabel,
    activator: SingleActivator(LogicalKeyboardKey.keyB, control: true),
  );
  static const italic = BusyMarkShortcutDefinition(
    label: italicLabel,
    activator: SingleActivator(LogicalKeyboardKey.keyI, control: true),
  );
  static const underline = BusyMarkShortcutDefinition(
    label: underlineLabel,
    activator: SingleActivator(LogicalKeyboardKey.keyU, control: true),
  );
  static const strikethrough = BusyMarkShortcutDefinition(
    label: strikethroughLabel,
    activator: SingleActivator(
      LogicalKeyboardKey.digit5,
      alt: true,
      shift: true,
    ),
  );
  static const inlineCode = BusyMarkShortcutDefinition(
    label: inlineCodeLabel,
    activator: SingleActivator(LogicalKeyboardKey.keyE, control: true),
  );
  static const link = BusyMarkShortcutDefinition(
    label: linkLabel,
    activator: SingleActivator(LogicalKeyboardKey.keyK, control: true),
  );
  static const paragraph = BusyMarkShortcutDefinition(
    label: paragraphLabel,
    activator: SingleActivator(
      LogicalKeyboardKey.digit0,
      control: true,
      shift: true,
    ),
  );
  static const heading1 = BusyMarkShortcutDefinition(
    label: heading1Label,
    activator: SingleActivator(
      LogicalKeyboardKey.digit1,
      control: true,
      shift: true,
    ),
  );
  static const heading2 = BusyMarkShortcutDefinition(
    label: heading2Label,
    activator: SingleActivator(
      LogicalKeyboardKey.digit2,
      control: true,
      shift: true,
    ),
  );
  static const heading3 = BusyMarkShortcutDefinition(
    label: heading3Label,
    activator: SingleActivator(
      LogicalKeyboardKey.digit3,
      control: true,
      shift: true,
    ),
  );
  static const heading4 = BusyMarkShortcutDefinition(
    label: heading4Label,
    activator: SingleActivator(
      LogicalKeyboardKey.digit4,
      control: true,
      shift: true,
    ),
  );
  static const heading5 = BusyMarkShortcutDefinition(
    label: heading5Label,
    activator: SingleActivator(
      LogicalKeyboardKey.digit5,
      control: true,
      shift: true,
    ),
  );
  static const heading6 = BusyMarkShortcutDefinition(
    label: heading6Label,
    activator: SingleActivator(
      LogicalKeyboardKey.digit6,
      control: true,
      shift: true,
    ),
  );
  static const orderedList = BusyMarkShortcutDefinition(
    label: orderedListLabel,
    activator: SingleActivator(
      LogicalKeyboardKey.digit7,
      control: true,
      shift: true,
    ),
  );
  static const unorderedList = BusyMarkShortcutDefinition(
    label: unorderedListLabel,
    activator: SingleActivator(
      LogicalKeyboardKey.digit8,
      control: true,
      shift: true,
    ),
  );
  static const taskList = BusyMarkShortcutDefinition(
    label: taskListLabel,
    activator: SingleActivator(
      LogicalKeyboardKey.digit9,
      control: true,
      shift: true,
    ),
  );
  static const toggleTask = BusyMarkShortcutDefinition(
    label: toggleTaskLabel,
    activator: SingleActivator(
      LogicalKeyboardKey.keyX,
      control: true,
      shift: true,
    ),
  );
  static const indent = BusyMarkShortcutDefinition(
    label: indentLabel,
    activator: SingleActivator(LogicalKeyboardKey.bracketRight, control: true),
  );
  static const outdent = BusyMarkShortcutDefinition(
    label: outdentLabel,
    activator: SingleActivator(LogicalKeyboardKey.bracketLeft, control: true),
  );
  static const blockquote = BusyMarkShortcutDefinition(
    label: blockquoteLabel,
    activator: SingleActivator(
      LogicalKeyboardKey.period,
      control: true,
      shift: true,
    ),
  );
  static const codeBlock = BusyMarkShortcutDefinition(
    label: codeBlockLabel,
    activator: SingleActivator(
      LogicalKeyboardKey.keyC,
      control: true,
      alt: true,
    ),
  );
  static const codeBlockLanguage = BusyMarkShortcutDefinition(
    label: codeBlockLanguageLabel,
    activator: SingleActivator(
      LogicalKeyboardKey.keyG,
      control: true,
      alt: true,
    ),
  );
  static const image = BusyMarkShortcutDefinition(
    label: imageLabel,
    activator: SingleActivator(
      LogicalKeyboardKey.keyI,
      control: true,
      alt: true,
    ),
  );
  static const inlineImage = BusyMarkShortcutDefinition(
    label: inlineImageLabel,
    activator: SingleActivator(
      LogicalKeyboardKey.keyI,
      control: true,
      alt: true,
      shift: true,
    ),
  );
  static const table = BusyMarkShortcutDefinition(
    label: tableLabel,
    activator: SingleActivator(
      LogicalKeyboardKey.keyT,
      control: true,
      shift: true,
    ),
  );
  static const htmlBlock = BusyMarkShortcutDefinition(
    label: htmlBlockLabel,
    activator: SingleActivator(
      LogicalKeyboardKey.keyH,
      control: true,
      alt: true,
    ),
  );
  static const thematicBreak = BusyMarkShortcutDefinition(
    label: thematicBreakLabel,
    activator: SingleActivator(
      LogicalKeyboardKey.keyR,
      control: true,
      alt: true,
    ),
  );
  static const hardLineBreak = BusyMarkShortcutDefinition(
    label: hardLineBreakLabel,
    activator: SingleActivator(LogicalKeyboardKey.enter, shift: true),
  );
  static const pastePlainText = BusyMarkTextEditingShortcuts.pastePlainText;

  static const definitions =
      <BusyMarkEditorShortcutAction, BusyMarkShortcutDefinition>{
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
        BusyMarkEditorShortcutAction.htmlBlock: htmlBlock,
        BusyMarkEditorShortcutAction.thematicBreak: thematicBreak,
        BusyMarkEditorShortcutAction.hardLineBreak: hardLineBreak,
        BusyMarkEditorShortcutAction.pastePlainText: pastePlainText,
      };
}

abstract final class BusyMarkEditorShortcutLabels {
  const BusyMarkEditorShortcutLabels._();

  static const textStyle = BusyMarkEditorShortcuts.textStyleLabel;
  static const bold = BusyMarkEditorShortcuts.boldLabel;
  static const italic = BusyMarkEditorShortcuts.italicLabel;
  static const underline = BusyMarkEditorShortcuts.underlineLabel;
  static const strikethrough = BusyMarkEditorShortcuts.strikethroughLabel;
  static const inlineCode = BusyMarkEditorShortcuts.inlineCodeLabel;
  static const link = BusyMarkEditorShortcuts.linkLabel;
  static const paragraph = BusyMarkEditorShortcuts.paragraphLabel;
  static const heading1 = BusyMarkEditorShortcuts.heading1Label;
  static const heading2 = BusyMarkEditorShortcuts.heading2Label;
  static const heading3 = BusyMarkEditorShortcuts.heading3Label;
  static const heading4 = BusyMarkEditorShortcuts.heading4Label;
  static const heading5 = BusyMarkEditorShortcuts.heading5Label;
  static const heading6 = BusyMarkEditorShortcuts.heading6Label;
  static const orderedList = BusyMarkEditorShortcuts.orderedListLabel;
  static const unorderedList = BusyMarkEditorShortcuts.unorderedListLabel;
  static const taskList = BusyMarkEditorShortcuts.taskListLabel;
  static const toggleTask = BusyMarkEditorShortcuts.toggleTaskLabel;
  static const indent = BusyMarkEditorShortcuts.indentLabel;
  static const outdent = BusyMarkEditorShortcuts.outdentLabel;
  static const blockquote = BusyMarkEditorShortcuts.blockquoteLabel;
  static const codeBlock = BusyMarkEditorShortcuts.codeBlockLabel;
  static const codeBlockLanguage =
      BusyMarkEditorShortcuts.codeBlockLanguageLabel;
  static const image = BusyMarkEditorShortcuts.imageLabel;
  static const inlineImage = BusyMarkEditorShortcuts.inlineImageLabel;
  static const table = BusyMarkEditorShortcuts.tableLabel;
  static const htmlBlock = BusyMarkEditorShortcuts.htmlBlockLabel;
  static const thematicBreak = BusyMarkEditorShortcuts.thematicBreakLabel;
  static const hardLineBreak = BusyMarkEditorShortcuts.hardLineBreakLabel;
  static const pastePlainText =
      BusyMarkTextEditingShortcuts.pastePlainTextLabel;
}

abstract final class BusyMarkEditorShortcutActivators {
  const BusyMarkEditorShortcutActivators._();

  static Map<ShortcutActivator, Intent> intentMap(
    Intent Function(BusyMarkEditorShortcutAction action) intentFor,
  ) {
    return {
      for (final entry in BusyMarkEditorShortcuts.definitions.entries)
        entry.value.activator: intentFor(entry.key),
    };
  }

  static BusyMarkEditorShortcutAction? actionForKeyEvent(
    KeyEvent event,
    HardwareKeyboard keyboard,
  ) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return null;
    }
    for (final entry in BusyMarkEditorShortcuts.definitions.entries) {
      if (entry.value.activator.accepts(event, keyboard)) {
        return entry.key;
      }
    }
    return null;
  }

  static ShortcutActivator get bold => BusyMarkEditorShortcuts.bold.activator;
  static ShortcutActivator get italic =>
      BusyMarkEditorShortcuts.italic.activator;
  static ShortcutActivator get underline =>
      BusyMarkEditorShortcuts.underline.activator;
  static ShortcutActivator get link => BusyMarkEditorShortcuts.link.activator;
  static ShortcutActivator get inlineCode =>
      BusyMarkEditorShortcuts.inlineCode.activator;
  static ShortcutActivator get strikethrough =>
      BusyMarkEditorShortcuts.strikethrough.activator;
  static ShortcutActivator get paragraph =>
      BusyMarkEditorShortcuts.paragraph.activator;
  static ShortcutActivator get heading1 =>
      BusyMarkEditorShortcuts.heading1.activator;
  static ShortcutActivator get heading2 =>
      BusyMarkEditorShortcuts.heading2.activator;
  static ShortcutActivator get heading3 =>
      BusyMarkEditorShortcuts.heading3.activator;
  static ShortcutActivator get heading4 =>
      BusyMarkEditorShortcuts.heading4.activator;
  static ShortcutActivator get heading5 =>
      BusyMarkEditorShortcuts.heading5.activator;
  static ShortcutActivator get heading6 =>
      BusyMarkEditorShortcuts.heading6.activator;
  static ShortcutActivator get orderedList =>
      BusyMarkEditorShortcuts.orderedList.activator;
  static ShortcutActivator get unorderedList =>
      BusyMarkEditorShortcuts.unorderedList.activator;
  static ShortcutActivator get taskList =>
      BusyMarkEditorShortcuts.taskList.activator;
  static ShortcutActivator get toggleTask =>
      BusyMarkEditorShortcuts.toggleTask.activator;
  static ShortcutActivator get indent =>
      BusyMarkEditorShortcuts.indent.activator;
  static ShortcutActivator get outdent =>
      BusyMarkEditorShortcuts.outdent.activator;
  static ShortcutActivator get blockquote =>
      BusyMarkEditorShortcuts.blockquote.activator;
  static ShortcutActivator get codeBlock =>
      BusyMarkEditorShortcuts.codeBlock.activator;
  static ShortcutActivator get codeBlockLanguage =>
      BusyMarkEditorShortcuts.codeBlockLanguage.activator;
  static ShortcutActivator get image => BusyMarkEditorShortcuts.image.activator;
  static ShortcutActivator get inlineImage =>
      BusyMarkEditorShortcuts.inlineImage.activator;
  static ShortcutActivator get table => BusyMarkEditorShortcuts.table.activator;
  static ShortcutActivator get htmlBlock =>
      BusyMarkEditorShortcuts.htmlBlock.activator;
  static ShortcutActivator get thematicBreak =>
      BusyMarkEditorShortcuts.thematicBreak.activator;
  static ShortcutActivator get hardLineBreak =>
      BusyMarkEditorShortcuts.hardLineBreak.activator;
  static ShortcutActivator get pastePlainText =>
      BusyMarkEditorShortcuts.pastePlainText.activator;
}

enum BusyMarkSidebarShortcutAction { files, toc, outline, git }

abstract final class BusyMarkSidebarShortcuts {
  const BusyMarkSidebarShortcuts._();

  static const filesLabel = 'Ctrl+1';
  static const tocLabel = 'Ctrl+2';
  static const outlineLabel = 'Ctrl+3';
  static const gitLabel = 'Ctrl+4';

  static const toggleSidebar = BusyMarkAppShortcuts.toggleSidebar;
  static const files = BusyMarkShortcutDefinition(
    label: filesLabel,
    activator: SingleActivator(LogicalKeyboardKey.digit1, control: true),
  );
  static const toc = BusyMarkShortcutDefinition(
    label: tocLabel,
    activator: SingleActivator(LogicalKeyboardKey.digit2, control: true),
  );
  static const outline = BusyMarkShortcutDefinition(
    label: outlineLabel,
    activator: SingleActivator(LogicalKeyboardKey.digit3, control: true),
  );
  static const git = BusyMarkShortcutDefinition(
    label: gitLabel,
    activator: SingleActivator(LogicalKeyboardKey.digit4, control: true),
  );

  static const definitions =
      <BusyMarkSidebarShortcutAction, BusyMarkShortcutDefinition>{
        BusyMarkSidebarShortcutAction.files: files,
        BusyMarkSidebarShortcutAction.toc: toc,
        BusyMarkSidebarShortcutAction.outline: outline,
        BusyMarkSidebarShortcutAction.git: git,
      };
}

abstract final class BusyMarkSidebarShortcutLabels {
  const BusyMarkSidebarShortcutLabels._();

  static const toggleSidebar = BusyMarkAppShortcuts.toggleSidebarLabel;
  static const files = BusyMarkSidebarShortcuts.filesLabel;
  static const toc = BusyMarkSidebarShortcuts.tocLabel;
  static const outline = BusyMarkSidebarShortcuts.outlineLabel;
  static const git = BusyMarkSidebarShortcuts.gitLabel;
}

abstract final class BusyMarkSidebarShortcutActivators {
  const BusyMarkSidebarShortcutActivators._();

  static ShortcutActivator get toggleSidebar =>
      BusyMarkSidebarShortcuts.toggleSidebar.activator;
  static ShortcutActivator get files =>
      BusyMarkSidebarShortcuts.files.activator;
  static ShortcutActivator get toc => BusyMarkSidebarShortcuts.toc.activator;
  static ShortcutActivator get outline =>
      BusyMarkSidebarShortcuts.outline.activator;
  static ShortcutActivator get git => BusyMarkSidebarShortcuts.git.activator;

  static BusyMarkSidebarShortcutAction? actionForKeyEvent(
    KeyEvent event,
    HardwareKeyboard keyboard,
  ) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return null;
    }
    if (!keyboard.isControlPressed ||
        keyboard.isShiftPressed ||
        keyboard.isAltPressed ||
        keyboard.isMetaPressed) {
      return null;
    }
    return switch (event.logicalKey) {
      LogicalKeyboardKey.digit1 ||
      LogicalKeyboardKey.numpad1 => BusyMarkSidebarShortcutAction.files,
      LogicalKeyboardKey.digit2 ||
      LogicalKeyboardKey.numpad2 => BusyMarkSidebarShortcutAction.toc,
      LogicalKeyboardKey.digit3 ||
      LogicalKeyboardKey.numpad3 => BusyMarkSidebarShortcutAction.outline,
      LogicalKeyboardKey.digit4 ||
      LogicalKeyboardKey.numpad4 => BusyMarkSidebarShortcutAction.git,
      _ => null,
    };
  }
}
