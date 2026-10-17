import 'shortcut_binding.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class BusyMarkShortcutDefinition {
  const BusyMarkShortcutDefinition({
    required this.label,
    required this.activator,
    String? gtkAccelerator,
  }) : _gtkAccelerator = gtkAccelerator;

  final String label;
  final ShortcutActivator activator;

  /// GTK accelerator syntax for native controls that render this command.
  ///
  /// This is deliberately separate from [label]: GTK parses strings such as
  /// `<Primary>comma`, then formats the visible label for the current desktop.
  final String? _gtkAccelerator;
  String? get gtkAccelerator =>
      _gtkAccelerator ??
      switch (activator) {
        final SingleActivator value => BusyMarkKeyBinding.fromActivator(
          value,
        ).gtkAccelerator,
        _ => null,
      };
}

enum BusyMarkAppShortcutAction {
  newDocument,
  open,
  save,
  export,
  fullScreen,
  back,
  search,
  keyboardShortcuts,
  commandPalette,
  quickOpen,
  syntaxReference,
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
  static const exportLabel = 'Ctrl+Shift+E';
  static const fullScreenLabel = 'F11';
  static const backLabel = 'Alt+Left';
  static const searchLabel = 'Ctrl+F';
  static const keyboardShortcutsLabel = 'Ctrl+Alt+K';
  static const quickOpenLabel = 'Ctrl+P';
  static const quickOpenGtkAccelerator = '<Primary>p';
  static const quickOpen = BusyMarkShortcutDefinition(
    label: quickOpenLabel,
    activator: SingleActivator(LogicalKeyboardKey.keyP, control: true),
    gtkAccelerator: quickOpenGtkAccelerator,
  );

  static const commandPaletteLabel = 'Ctrl+Shift+P';
  static const syntaxReferenceLabel = 'Ctrl+Alt+M';
  static const settingsLabel = 'Ctrl+Alt+S';
  static const nextTabLabel = 'Ctrl+Tab';
  static const previousTabLabel = 'Ctrl+Shift+Tab';
  static const closeTabLabel = 'Ctrl+W';
  static const closeAllTabsLabel = 'Ctrl+Shift+W';
  static const toggleSidebarLabel = 'F9';

  static const newDocumentGtkAccelerator = '<Primary>n';
  static const openGtkAccelerator = '<Primary>o';
  static const saveGtkAccelerator = '<Primary>s';
  static const exportGtkAccelerator = '<Primary><Shift>e';
  static const fullScreenGtkAccelerator = 'F11';
  static const backGtkAccelerator = '<Alt>Left';
  static const searchGtkAccelerator = '<Primary>f';
  static const keyboardShortcutsGtkAccelerator = '<Primary><Alt>k';
  static const commandPaletteGtkAccelerator = '<Primary><Shift>p';
  static const syntaxReferenceGtkAccelerator = '<Primary><Alt>m';
  static const settingsGtkAccelerator = '<Primary><Alt>s';
  static const nextTabGtkAccelerator = '<Primary>Tab';
  static const previousTabGtkAccelerator = '<Primary><Shift>Tab';
  static const closeTabGtkAccelerator = '<Primary>w';
  static const closeAllTabsGtkAccelerator = '<Primary><Shift>w';
  static const toggleSidebarGtkAccelerator = 'F9';

  static const newDocument = BusyMarkShortcutDefinition(
    label: newDocumentLabel,
    activator: SingleActivator(LogicalKeyboardKey.keyN, control: true),
    gtkAccelerator: newDocumentGtkAccelerator,
  );
  static const open = BusyMarkShortcutDefinition(
    label: openLabel,
    activator: SingleActivator(LogicalKeyboardKey.keyO, control: true),
    gtkAccelerator: openGtkAccelerator,
  );
  static const save = BusyMarkShortcutDefinition(
    label: saveLabel,
    activator: SingleActivator(LogicalKeyboardKey.keyS, control: true),
    gtkAccelerator: saveGtkAccelerator,
  );
  static const export = BusyMarkShortcutDefinition(
    label: exportLabel,
    activator: SingleActivator(
      LogicalKeyboardKey.keyE,
      control: true,
      shift: true,
    ),
    gtkAccelerator: exportGtkAccelerator,
  );
  static const fullScreen = BusyMarkShortcutDefinition(
    label: fullScreenLabel,
    activator: SingleActivator(LogicalKeyboardKey.f11, includeRepeats: false),
    gtkAccelerator: fullScreenGtkAccelerator,
  );
  static const back = BusyMarkShortcutDefinition(
    label: backLabel,
    activator: SingleActivator(
      LogicalKeyboardKey.arrowLeft,
      alt: true,
      includeRepeats: false,
    ),
    gtkAccelerator: backGtkAccelerator,
  );
  static const search = BusyMarkShortcutDefinition(
    label: searchLabel,
    activator: SingleActivator(LogicalKeyboardKey.keyF, control: true),
    gtkAccelerator: searchGtkAccelerator,
  );
  static const keyboardShortcuts = BusyMarkShortcutDefinition(
    label: keyboardShortcutsLabel,
    activator: SingleActivator(
      LogicalKeyboardKey.keyK,
      control: true,
      alt: true,
    ),
    gtkAccelerator: keyboardShortcutsGtkAccelerator,
  );
  static const commandPalette = BusyMarkShortcutDefinition(
    label: commandPaletteLabel,
    activator: SingleActivator(
      LogicalKeyboardKey.keyP,
      control: true,
      shift: true,
    ),
    gtkAccelerator: commandPaletteGtkAccelerator,
  );
  static const syntaxReference = BusyMarkShortcutDefinition(
    label: syntaxReferenceLabel,
    activator: SingleActivator(
      LogicalKeyboardKey.keyM,
      control: true,
      alt: true,
    ),
    gtkAccelerator: syntaxReferenceGtkAccelerator,
  );
  static const settings = BusyMarkShortcutDefinition(
    label: settingsLabel,
    activator: SingleActivator(
      LogicalKeyboardKey.keyS,
      control: true,
      alt: true,
    ),
    gtkAccelerator: settingsGtkAccelerator,
  );
  static const nextTab = BusyMarkShortcutDefinition(
    label: nextTabLabel,
    activator: SingleActivator(LogicalKeyboardKey.tab, control: true),
    gtkAccelerator: nextTabGtkAccelerator,
  );
  static const previousTab = BusyMarkShortcutDefinition(
    label: previousTabLabel,
    activator: SingleActivator(
      LogicalKeyboardKey.tab,
      control: true,
      shift: true,
    ),
    gtkAccelerator: previousTabGtkAccelerator,
  );
  static const closeTab = BusyMarkShortcutDefinition(
    label: closeTabLabel,
    activator: SingleActivator(LogicalKeyboardKey.keyW, control: true),
    gtkAccelerator: closeTabGtkAccelerator,
  );
  static const closeAllTabs = BusyMarkShortcutDefinition(
    label: closeAllTabsLabel,
    activator: SingleActivator(
      LogicalKeyboardKey.keyW,
      control: true,
      shift: true,
    ),
    gtkAccelerator: closeAllTabsGtkAccelerator,
  );
  static const toggleSidebar = BusyMarkShortcutDefinition(
    label: toggleSidebarLabel,
    activator: SingleActivator(LogicalKeyboardKey.f9),
    gtkAccelerator: toggleSidebarGtkAccelerator,
  );

  static const definitions =
      <BusyMarkAppShortcutAction, BusyMarkShortcutDefinition>{
        BusyMarkAppShortcutAction.newDocument: newDocument,
        BusyMarkAppShortcutAction.open: open,
        BusyMarkAppShortcutAction.save: save,
        BusyMarkAppShortcutAction.export: export,
        BusyMarkAppShortcutAction.fullScreen: fullScreen,
        BusyMarkAppShortcutAction.back: back,
        BusyMarkAppShortcutAction.search: search,
        BusyMarkAppShortcutAction.keyboardShortcuts: keyboardShortcuts,
        BusyMarkAppShortcutAction.commandPalette: commandPalette,
        BusyMarkAppShortcutAction.quickOpen: quickOpen,
        BusyMarkAppShortcutAction.syntaxReference: syntaxReference,
        BusyMarkAppShortcutAction.settings: settings,
        BusyMarkAppShortcutAction.nextTab: nextTab,
        BusyMarkAppShortcutAction.previousTab: previousTab,
        BusyMarkAppShortcutAction.closeTab: closeTab,
        BusyMarkAppShortcutAction.closeAllTabs: closeAllTabs,
        BusyMarkAppShortcutAction.toggleSidebar: toggleSidebar,
      };
}

enum BusyMarkDocumentViewShortcutAction { editor, source, reading, split }

abstract final class BusyMarkDocumentViewShortcuts {
  const BusyMarkDocumentViewShortcuts._();

  static const editorLabel = 'Ctrl+Shift+1';
  static const sourceLabel = 'Ctrl+Shift+2';
  static const readingLabel = 'Ctrl+Shift+3';
  static const splitLabel = 'Ctrl+Shift+4';

  static const editorGtkAccelerator = '<Primary><Shift>1';
  static const sourceGtkAccelerator = '<Primary><Shift>2';
  static const readingGtkAccelerator = '<Primary><Shift>3';
  static const splitGtkAccelerator = '<Primary><Shift>4';

  static const editor = BusyMarkShortcutDefinition(
    label: editorLabel,
    activator: SingleActivator(
      LogicalKeyboardKey.digit1,
      control: true,
      shift: true,
    ),
    gtkAccelerator: editorGtkAccelerator,
  );
  static const source = BusyMarkShortcutDefinition(
    label: sourceLabel,
    activator: SingleActivator(
      LogicalKeyboardKey.digit2,
      control: true,
      shift: true,
    ),
    gtkAccelerator: sourceGtkAccelerator,
  );
  static const reading = BusyMarkShortcutDefinition(
    label: readingLabel,
    activator: SingleActivator(
      LogicalKeyboardKey.digit3,
      control: true,
      shift: true,
    ),
    gtkAccelerator: readingGtkAccelerator,
  );
  static const split = BusyMarkShortcutDefinition(
    label: splitLabel,
    activator: SingleActivator(
      LogicalKeyboardKey.digit4,
      control: true,
      shift: true,
    ),
    gtkAccelerator: splitGtkAccelerator,
  );

  static const definitions =
      <BusyMarkDocumentViewShortcutAction, BusyMarkShortcutDefinition>{
        BusyMarkDocumentViewShortcutAction.editor: editor,
        BusyMarkDocumentViewShortcutAction.source: source,
        BusyMarkDocumentViewShortcutAction.reading: reading,
        BusyMarkDocumentViewShortcutAction.split: split,
      };
}

enum BusyMarkTextEditingShortcutAction {
  selectAll,
  cut,
  copy,
  paste,
  pastePlainText,
  undo,
  redo,
  insertIndentation,
  outdentSource,
  escape,
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
  static const insertIndentationLabel = 'Tab';
  static const outdentSourceLabel = 'Shift+Tab';
  static const escapeLabel = 'Esc';

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
  static const insertIndentation = BusyMarkShortcutDefinition(
    label: insertIndentationLabel,
    activator: SingleActivator(LogicalKeyboardKey.tab),
  );
  static const outdentSource = BusyMarkShortcutDefinition(
    label: outdentSourceLabel,
    activator: SingleActivator(LogicalKeyboardKey.tab, shift: true),
  );
  static const escape = BusyMarkShortcutDefinition(
    label: escapeLabel,
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
        BusyMarkTextEditingShortcutAction.insertIndentation: insertIndentation,
        BusyMarkTextEditingShortcutAction.outdentSource: outdentSource,
        BusyMarkTextEditingShortcutAction.escape: escape,
      };
}

enum BusyMarkEditorShortcutAction {
  refineWithAi,
  copyPlainText,
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
}

abstract final class BusyMarkEditorShortcuts {
  const BusyMarkEditorShortcuts._();

  static const refineWithAiLabel = 'Ctrl+G';
  static const copyPlainTextLabel = 'Ctrl+Shift+C';
  static const textStyleLabel = 'Ctrl+Alt+0-6';
  static const boldLabel = 'Ctrl+B';
  static const italicLabel = 'Ctrl+I';
  static const underlineLabel = 'Ctrl+U';
  static const strikethroughLabel = 'Alt+Shift+5';
  static const inlineCodeLabel = 'Ctrl+Shift+`';
  static const linkLabel = 'Ctrl+K';
  static const paragraphLabel = 'Ctrl+Alt+0';
  static const heading1Label = 'Ctrl+Alt+1';
  static const heading2Label = 'Ctrl+Alt+2';
  static const heading3Label = 'Ctrl+Alt+3';
  static const heading4Label = 'Ctrl+Alt+4';
  static const heading5Label = 'Ctrl+Alt+5';
  static const heading6Label = 'Ctrl+Alt+6';
  static const orderedListLabel = 'Ctrl+Shift+7';
  static const unorderedListLabel = 'Ctrl+Shift+8';
  static const taskListLabel = 'Ctrl+Shift+9';
  static const indentLabel = 'Ctrl+]';
  static const outdentLabel = 'Ctrl+[';
  static const blockquoteLabel = 'Ctrl+Shift+Q';
  static const codeBlockLabel = 'Ctrl+Shift+K';
  static const imageLabel = 'Ctrl+Shift+I';
  static const thematicBreakLabel = 'Ctrl+Shift+-';
  static const hardLineBreakLabel = 'Shift+Enter';

  static const refineWithAi = BusyMarkShortcutDefinition(
    label: refineWithAiLabel,
    activator: SingleActivator(LogicalKeyboardKey.keyG, control: true),
  );
  static const copyPlainText = BusyMarkShortcutDefinition(
    label: copyPlainTextLabel,
    activator: SingleActivator(
      LogicalKeyboardKey.keyC,
      control: true,
      shift: true,
    ),
  );
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
    activator: SingleActivator(
      LogicalKeyboardKey.backquote,
      control: true,
      shift: true,
    ),
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
      alt: true,
    ),
  );
  static const heading1 = BusyMarkShortcutDefinition(
    label: heading1Label,
    activator: SingleActivator(
      LogicalKeyboardKey.digit1,
      control: true,
      alt: true,
    ),
  );
  static const heading2 = BusyMarkShortcutDefinition(
    label: heading2Label,
    activator: SingleActivator(
      LogicalKeyboardKey.digit2,
      control: true,
      alt: true,
    ),
  );
  static const heading3 = BusyMarkShortcutDefinition(
    label: heading3Label,
    activator: SingleActivator(
      LogicalKeyboardKey.digit3,
      control: true,
      alt: true,
    ),
  );
  static const heading4 = BusyMarkShortcutDefinition(
    label: heading4Label,
    activator: SingleActivator(
      LogicalKeyboardKey.digit4,
      control: true,
      alt: true,
    ),
  );
  static const heading5 = BusyMarkShortcutDefinition(
    label: heading5Label,
    activator: SingleActivator(
      LogicalKeyboardKey.digit5,
      control: true,
      alt: true,
    ),
  );
  static const heading6 = BusyMarkShortcutDefinition(
    label: heading6Label,
    activator: SingleActivator(
      LogicalKeyboardKey.digit6,
      control: true,
      alt: true,
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
      LogicalKeyboardKey.keyQ,
      control: true,
      shift: true,
    ),
  );
  static const codeBlock = BusyMarkShortcutDefinition(
    label: codeBlockLabel,
    activator: SingleActivator(
      LogicalKeyboardKey.keyK,
      control: true,
      shift: true,
    ),
  );
  static const image = BusyMarkShortcutDefinition(
    label: imageLabel,
    activator: SingleActivator(
      LogicalKeyboardKey.keyI,
      control: true,
      shift: true,
    ),
  );
  static const thematicBreak = BusyMarkShortcutDefinition(
    label: thematicBreakLabel,
    activator: SingleActivator(
      LogicalKeyboardKey.minus,
      control: true,
      shift: true,
    ),
  );
  static const hardLineBreak = BusyMarkShortcutDefinition(
    label: hardLineBreakLabel,
    activator: SingleActivator(LogicalKeyboardKey.enter, shift: true),
  );
  static const definitions =
      <BusyMarkEditorShortcutAction, BusyMarkShortcutDefinition>{
        BusyMarkEditorShortcutAction.refineWithAi: refineWithAi,
        BusyMarkEditorShortcutAction.copyPlainText: copyPlainText,
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
        BusyMarkEditorShortcutAction.indent: indent,
        BusyMarkEditorShortcutAction.outdent: outdent,
        BusyMarkEditorShortcutAction.blockquote: blockquote,
        BusyMarkEditorShortcutAction.codeBlock: codeBlock,
        BusyMarkEditorShortcutAction.image: image,
        BusyMarkEditorShortcutAction.thematicBreak: thematicBreak,
        BusyMarkEditorShortcutAction.hardLineBreak: hardLineBreak,
      };
}

enum BusyMarkSidebarShortcutAction {
  files,
  toc,
  outline,
  git,
  localHistory,
  clipboardHistory,
}

abstract final class BusyMarkSidebarShortcuts {
  const BusyMarkSidebarShortcuts._();

  static const filesLabel = 'Ctrl+1';
  static const tocLabel = 'Ctrl+2';
  static const outlineLabel = 'Ctrl+3';
  static const gitLabel = 'Ctrl+4';
  static const localHistoryLabel = 'Ctrl+5';
  static const clipboardHistoryLabel = 'Ctrl+6';

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
  static const localHistory = BusyMarkShortcutDefinition(
    label: localHistoryLabel,
    activator: SingleActivator(LogicalKeyboardKey.digit5, control: true),
  );
  static const clipboardHistory = BusyMarkShortcutDefinition(
    label: clipboardHistoryLabel,
    activator: SingleActivator(LogicalKeyboardKey.digit6, control: true),
  );

  static const definitions =
      <BusyMarkSidebarShortcutAction, BusyMarkShortcutDefinition>{
        BusyMarkSidebarShortcutAction.files: files,
        BusyMarkSidebarShortcutAction.toc: toc,
        BusyMarkSidebarShortcutAction.outline: outline,
        BusyMarkSidebarShortcutAction.git: git,
        BusyMarkSidebarShortcutAction.localHistory: localHistory,
        BusyMarkSidebarShortcutAction.clipboardHistory: clipboardHistory,
      };
}

enum BusyMarkTreeShortcutAction { deleteSelection }

abstract final class BusyMarkTreeShortcuts {
  const BusyMarkTreeShortcuts._();

  static const deleteSelectionLabel = 'Delete';

  static const deleteSelection = BusyMarkShortcutDefinition(
    label: deleteSelectionLabel,
    activator: SingleActivator(LogicalKeyboardKey.delete),
  );

  static const definitions =
      <BusyMarkTreeShortcutAction, BusyMarkShortcutDefinition>{
        BusyMarkTreeShortcutAction.deleteSelection: deleteSelection,
      };
}
