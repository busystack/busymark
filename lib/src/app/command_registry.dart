import 'dart:async';

import 'package:flutter/material.dart';

import 'busymark_shortcuts.dart';
import 'localization.dart';

typedef BusyMarkCommandCallback = FutureOr<void> Function();
typedef BusyMarkCommandPredicate = bool Function();
typedef BusyMarkCommandLabel = String Function(BuildContext context);
typedef BusyMarkCommandDescription = String? Function(BuildContext context);

class BusyMarkCommandIntent extends Intent {
  const BusyMarkCommandIntent(this.commandId);

  final String commandId;
}

enum BusyMarkCommandScope {
  application,
  documentView,
  textEditing,
  editor,
  sidebar,
  tree,
}

@immutable
class BusyMarkCommand {
  const BusyMarkCommand({
    required this.id,
    required this.label,
    required this.category,
    required this.scope,
    this.shortcut,
    this.description,
    this.execute,
    this.enabled = _always,
    this.visible = _always,
  });

  final String id;
  final BusyMarkCommandLabel label;
  final BusyMarkCommandLabel category;
  final BusyMarkCommandScope scope;
  final BusyMarkShortcutDefinition? shortcut;
  final BusyMarkCommandDescription? description;
  final BusyMarkCommandCallback? execute;
  final BusyMarkCommandPredicate enabled;
  final BusyMarkCommandPredicate visible;

  bool get canExecute => execute != null && enabled();

  static bool _always() => true;
}

class BusyMarkCommandRegistryValidationException implements Exception {
  const BusyMarkCommandRegistryValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BusyMarkCommandRegistry {
  BusyMarkCommandRegistry(Iterable<BusyMarkCommand> commands)
    : commands = List.unmodifiable(commands) {
    _validate(this.commands);
    _byId = {for (final command in this.commands) command.id: command};
  }

  final List<BusyMarkCommand> commands;
  late final Map<String, BusyMarkCommand> _byId;

  BusyMarkCommand? operator [](String id) => _byId[id];

  List<BusyMarkCommand> visibleCommands() => [
    for (final command in commands)
      if (command.visible()) command,
  ];

  Future<bool> execute(String id) async {
    final command = _byId[id];
    if (command == null || !command.canExecute) {
      return false;
    }
    await command.execute!();
    return true;
  }

  Map<ShortcutActivator, Intent> shortcutIntents({
    required Set<BusyMarkCommandScope> scopes,
    required Intent Function(String commandId) intentFor,
  }) {
    return {
      for (final command in commands)
        if (scopes.contains(command.scope) && command.shortcut != null)
          command.shortcut!.activator: intentFor(command.id),
    };
  }

  static void _validate(List<BusyMarkCommand> commands) {
    final ids = <String>{};
    final shortcuts = <(BusyMarkCommandScope, ShortcutActivator), String>{};
    for (final command in commands) {
      if (!RegExp(
        r'^[a-z][A-Za-z0-9]*(?:\.[a-z][A-Za-z0-9]*)+$',
      ).hasMatch(command.id)) {
        throw BusyMarkCommandRegistryValidationException(
          'Invalid command ID: ${command.id}',
        );
      }
      if (!ids.add(command.id)) {
        throw BusyMarkCommandRegistryValidationException(
          'Duplicate command ID: ${command.id}',
        );
      }
      final shortcut = command.shortcut;
      if (shortcut == null) {
        continue;
      }
      final key = (command.scope, shortcut.activator);
      if (shortcuts[key] case final existing?) {
        throw BusyMarkCommandRegistryValidationException(
          'Shortcut conflict in ${command.scope.name}: $existing and ${command.id}',
        );
      }
      shortcuts[key] = command.id;
    }
  }
}

abstract final class BusyMarkCommandIds {
  static const newDocument = 'file.newDocument';
  static const open = 'file.open';
  static const save = 'file.save';
  static const exportPdf = 'file.exportPdf';
  static const fullScreen = 'view.fullScreen';
  static const back = 'navigation.back';
  static const search = 'search.find';
  static const keyboardShortcuts = 'help.keyboardShortcuts';
  static const commandPalette = 'view.commandPalette';
  static const markdownAndHtml = 'help.markdownAndHtml';
  static const settings = 'application.settings';
  static const nextTab = 'tabs.next';
  static const previousTab = 'tabs.previous';
  static const closeTab = 'tabs.close';
  static const closeAllTabs = 'tabs.closeAll';
  static const toggleSidebar = 'view.toggleSidebar';
  static const viewEditor = 'view.editor';
  static const viewSource = 'view.source';
  static const viewReading = 'view.reading';
  static const viewSplit = 'view.split';
  static const textSelectAll = 'text.selectAll';
  static const textCut = 'text.cut';
  static const textCopy = 'text.copy';
  static const textPaste = 'text.paste';
  static const editorRefineWithAi = 'editor.refineWithAi';
}

abstract final class BusyMarkCommandCatalog {
  static BusyMarkCommandRegistry create({
    Map<String, BusyMarkCommandCallback> executions = const {},
    Map<String, BusyMarkCommandPredicate> enabled = const {},
    Map<String, BusyMarkCommandPredicate> visible = const {},
  }) {
    BusyMarkCommand command({
      required String id,
      required BusyMarkCommandLabel label,
      required BusyMarkCommandLabel category,
      required BusyMarkCommandScope scope,
      required BusyMarkShortcutDefinition shortcut,
      BusyMarkCommandDescription? description,
    }) {
      return BusyMarkCommand(
        id: id,
        label: label,
        category: category,
        scope: scope,
        shortcut: shortcut,
        description: description,
        execute: executions[id],
        enabled: enabled[id] ?? BusyMarkCommand._always,
        visible: visible[id] ?? BusyMarkCommand._always,
      );
    }

    final commands = <BusyMarkCommand>[
      for (final entry in BusyMarkAppShortcuts.definitions.entries)
        command(
          id: _appId(entry.key),
          label: (context) => _appLabel(context, entry.key),
          category: (context) => _appCategory(context, entry.key),
          scope: BusyMarkCommandScope.application,
          shortcut: entry.value,
          description: (context) => _appDescription(context, entry.key),
        ),
      for (final entry in BusyMarkDocumentViewShortcuts.definitions.entries)
        command(
          id: switch (entry.key) {
            BusyMarkDocumentViewShortcutAction.editor =>
              BusyMarkCommandIds.viewEditor,
            BusyMarkDocumentViewShortcutAction.source =>
              BusyMarkCommandIds.viewSource,
            BusyMarkDocumentViewShortcutAction.reading =>
              BusyMarkCommandIds.viewReading,
            BusyMarkDocumentViewShortcutAction.split =>
              BusyMarkCommandIds.viewSplit,
          },
          label: (context) => _viewLabel(context, entry.key),
          category: (context) => context.l10n.viewMode,
          scope: BusyMarkCommandScope.documentView,
          shortcut: entry.value,
        ),
      for (final entry in BusyMarkTextEditingShortcuts.definitions.entries)
        command(
          id: 'text.${entry.key.name}',
          label: (context) => _textLabel(context, entry.key),
          category: (context) => context.l10n.shortcutGroupTextEditing,
          scope: BusyMarkCommandScope.textEditing,
          shortcut: entry.value,
          description: (context) => _textDescription(context, entry.key),
        ),
      for (final entry in BusyMarkEditorShortcuts.definitions.entries)
        command(
          id: 'editor.${entry.key.name}',
          label: (context) => _editorLabel(context, entry.key),
          category: (context) => _editorCategory(context, entry.key),
          scope: BusyMarkCommandScope.editor,
          shortcut: entry.value,
          description: (context) => _editorDescription(context, entry.key),
        ),
      for (final entry in BusyMarkSidebarShortcuts.definitions.entries)
        command(
          id: 'sidebar.${entry.key.name}',
          label: (context) => _sidebarLabel(context, entry.key),
          category: (context) => context.l10n.shortcutGroupSidebar,
          scope: BusyMarkCommandScope.sidebar,
          shortcut: entry.value,
        ),
      for (final entry in BusyMarkTreeShortcuts.definitions.entries)
        command(
          id: 'tree.${entry.key.name}',
          label: (context) => context.l10n.delete,
          category: (context) => context.l10n.shortcutGroupSidebar,
          scope: BusyMarkCommandScope.tree,
          shortcut: entry.value,
          description: (context) =>
              context.l10n.shortcutDeleteTreeItemDescription,
        ),
    ];
    return BusyMarkCommandRegistry(commands);
  }

  static String _appId(BusyMarkAppShortcutAction action) => switch (action) {
    BusyMarkAppShortcutAction.newDocument => BusyMarkCommandIds.newDocument,
    BusyMarkAppShortcutAction.open => BusyMarkCommandIds.open,
    BusyMarkAppShortcutAction.save => BusyMarkCommandIds.save,
    BusyMarkAppShortcutAction.exportPdf => BusyMarkCommandIds.exportPdf,
    BusyMarkAppShortcutAction.fullScreen => BusyMarkCommandIds.fullScreen,
    BusyMarkAppShortcutAction.back => BusyMarkCommandIds.back,
    BusyMarkAppShortcutAction.search => BusyMarkCommandIds.search,
    BusyMarkAppShortcutAction.keyboardShortcuts =>
      BusyMarkCommandIds.keyboardShortcuts,
    BusyMarkAppShortcutAction.commandPalette =>
      BusyMarkCommandIds.commandPalette,
    BusyMarkAppShortcutAction.markdownAndHtml =>
      BusyMarkCommandIds.markdownAndHtml,
    BusyMarkAppShortcutAction.settings => BusyMarkCommandIds.settings,
    BusyMarkAppShortcutAction.nextTab => BusyMarkCommandIds.nextTab,
    BusyMarkAppShortcutAction.previousTab => BusyMarkCommandIds.previousTab,
    BusyMarkAppShortcutAction.closeTab => BusyMarkCommandIds.closeTab,
    BusyMarkAppShortcutAction.closeAllTabs => BusyMarkCommandIds.closeAllTabs,
    BusyMarkAppShortcutAction.toggleSidebar => BusyMarkCommandIds.toggleSidebar,
  };

  static String _appLabel(
    BuildContext context,
    BusyMarkAppShortcutAction action,
  ) => switch (action) {
    BusyMarkAppShortcutAction.newDocument => context.l10n.shortcutNewDocument,
    BusyMarkAppShortcutAction.open => context.l10n.open,
    BusyMarkAppShortcutAction.save => context.l10n.save,
    BusyMarkAppShortcutAction.exportPdf => context.l10n.exportAsPdf,
    BusyMarkAppShortcutAction.fullScreen => context.l10n.fullScreen,
    BusyMarkAppShortcutAction.back => context.l10n.back,
    BusyMarkAppShortcutAction.search => context.l10n.search,
    BusyMarkAppShortcutAction.keyboardShortcuts =>
      context.l10n.keyboardShortcuts,
    BusyMarkAppShortcutAction.commandPalette => context.l10n.commandPalette,
    BusyMarkAppShortcutAction.markdownAndHtml => context.l10n.markdownAndHtml,
    BusyMarkAppShortcutAction.settings => context.l10n.settings,
    BusyMarkAppShortcutAction.nextTab => context.l10n.shortcutNextTab,
    BusyMarkAppShortcutAction.previousTab => context.l10n.shortcutPreviousTab,
    BusyMarkAppShortcutAction.closeTab => context.l10n.shortcutCloseTab,
    BusyMarkAppShortcutAction.closeAllTabs => context.l10n.shortcutCloseAllTabs,
    BusyMarkAppShortcutAction.toggleSidebar => context.l10n.toggleSidebar,
  };

  static String _appCategory(
    BuildContext context,
    BusyMarkAppShortcutAction action,
  ) => switch (action) {
    BusyMarkAppShortcutAction.nextTab ||
    BusyMarkAppShortcutAction.previousTab ||
    BusyMarkAppShortcutAction.closeTab ||
    BusyMarkAppShortcutAction.closeAllTabs => context.l10n.tabs,
    BusyMarkAppShortcutAction.toggleSidebar =>
      context.l10n.shortcutGroupSidebar,
    _ => context.l10n.shortcutGroupGeneral,
  };

  static String _viewLabel(
    BuildContext context,
    BusyMarkDocumentViewShortcutAction action,
  ) => switch (action) {
    BusyMarkDocumentViewShortcutAction.editor => context.l10n.editor,
    BusyMarkDocumentViewShortcutAction.source => context.l10n.source,
    BusyMarkDocumentViewShortcutAction.reading => context.l10n.reading,
    BusyMarkDocumentViewShortcutAction.split => context.l10n.split,
  };

  static String? _appDescription(
    BuildContext context,
    BusyMarkAppShortcutAction action,
  ) => switch (action) {
    BusyMarkAppShortcutAction.newDocument =>
      context.l10n.shortcutNewDocumentDescription,
    BusyMarkAppShortcutAction.open => context.l10n.shortcutOpenDescription,
    BusyMarkAppShortcutAction.save => context.l10n.shortcutSaveDescription,
    BusyMarkAppShortcutAction.exportPdf =>
      context.l10n.shortcutExportPdfDescription,
    BusyMarkAppShortcutAction.search => context.l10n.shortcutSearchDescription,
    BusyMarkAppShortcutAction.keyboardShortcuts =>
      context.l10n.shortcutKeyboardShortcutsDescription,
    BusyMarkAppShortcutAction.markdownAndHtml =>
      context.l10n.shortcutMarkdownAndHtmlDescription,
    BusyMarkAppShortcutAction.settings =>
      context.l10n.shortcutSettingsDescription,
    BusyMarkAppShortcutAction.nextTab =>
      context.l10n.shortcutNextTabDescription,
    BusyMarkAppShortcutAction.previousTab =>
      context.l10n.shortcutPreviousTabDescription,
    BusyMarkAppShortcutAction.closeTab =>
      context.l10n.shortcutCloseTabDescription,
    BusyMarkAppShortcutAction.closeAllTabs =>
      context.l10n.shortcutCloseAllTabsDescription,
    _ => null,
  };

  static String _textLabel(
    BuildContext context,
    BusyMarkTextEditingShortcutAction action,
  ) => switch (action) {
    BusyMarkTextEditingShortcutAction.selectAll => context.l10n.selectAll,
    BusyMarkTextEditingShortcutAction.cut => context.l10n.cut,
    BusyMarkTextEditingShortcutAction.copy => context.l10n.copy,
    BusyMarkTextEditingShortcutAction.paste => context.l10n.paste,
    BusyMarkTextEditingShortcutAction.pastePlainText =>
      context.l10n.pasteWithoutFormatting,
    BusyMarkTextEditingShortcutAction.undo => context.l10n.undo,
    BusyMarkTextEditingShortcutAction.redo => context.l10n.redo,
    BusyMarkTextEditingShortcutAction.insertIndentation =>
      context.l10n.shortcutInsertIndentation,
    BusyMarkTextEditingShortcutAction.outdentSource =>
      context.l10n.shortcutOutdentSource,
    BusyMarkTextEditingShortcutAction.escape => context.l10n.shortcutEscape,
  };

  static String _editorLabel(
    BuildContext context,
    BusyMarkEditorShortcutAction action,
  ) => switch (action) {
    BusyMarkEditorShortcutAction.refineWithAi => context.l10n.aiRefineWithAi,
    BusyMarkEditorShortcutAction.bold => context.l10n.bold,
    BusyMarkEditorShortcutAction.italic => context.l10n.italic,
    BusyMarkEditorShortcutAction.underline => context.l10n.underline,
    BusyMarkEditorShortcutAction.strikethrough => context.l10n.strikethrough,
    BusyMarkEditorShortcutAction.inlineCode => context.l10n.inlineCode,
    BusyMarkEditorShortcutAction.link => context.l10n.link,
    BusyMarkEditorShortcutAction.paragraph => context.l10n.paragraph,
    BusyMarkEditorShortcutAction.heading1 => context.l10n.heading1,
    BusyMarkEditorShortcutAction.heading2 => context.l10n.heading2,
    BusyMarkEditorShortcutAction.heading3 => context.l10n.heading3,
    BusyMarkEditorShortcutAction.heading4 => context.l10n.heading4,
    BusyMarkEditorShortcutAction.heading5 => context.l10n.heading5,
    BusyMarkEditorShortcutAction.heading6 => context.l10n.heading6,
    BusyMarkEditorShortcutAction.orderedList => context.l10n.numberedList,
    BusyMarkEditorShortcutAction.unorderedList => context.l10n.bulletedList,
    BusyMarkEditorShortcutAction.taskList => context.l10n.checklist,
    BusyMarkEditorShortcutAction.toggleTask => context.l10n.checklist,
    BusyMarkEditorShortcutAction.indent => context.l10n.indentListItem,
    BusyMarkEditorShortcutAction.outdent => context.l10n.outdentListItem,
    BusyMarkEditorShortcutAction.blockquote => context.l10n.blockquote,
    BusyMarkEditorShortcutAction.codeBlock => context.l10n.codeBlock,
    BusyMarkEditorShortcutAction.codeBlockLanguage => context.l10n.language,
    BusyMarkEditorShortcutAction.image => context.l10n.image,
    BusyMarkEditorShortcutAction.inlineImage => context.l10n.inlineImage,
    BusyMarkEditorShortcutAction.table => context.l10n.table,
    BusyMarkEditorShortcutAction.htmlBlock => context.l10n.htmlBlock,
    BusyMarkEditorShortcutAction.thematicBreak => context.l10n.thematicBreak,
    BusyMarkEditorShortcutAction.hardLineBreak => context.l10n.hardLineBreak,
    BusyMarkEditorShortcutAction.pastePlainText =>
      context.l10n.pasteWithoutFormatting,
  };

  static String? _textDescription(
    BuildContext context,
    BusyMarkTextEditingShortcutAction action,
  ) => switch (action) {
    BusyMarkTextEditingShortcutAction.selectAll =>
      context.l10n.shortcutSelectAllDescription,
    BusyMarkTextEditingShortcutAction.cut =>
      context.l10n.shortcutCutDescription,
    BusyMarkTextEditingShortcutAction.copy =>
      context.l10n.shortcutCopyDescription,
    BusyMarkTextEditingShortcutAction.paste =>
      context.l10n.shortcutPasteDescription,
    BusyMarkTextEditingShortcutAction.pastePlainText =>
      context.l10n.shortcutPastePlainTextDescription,
    BusyMarkTextEditingShortcutAction.undo =>
      context.l10n.shortcutUndoDescription,
    BusyMarkTextEditingShortcutAction.redo =>
      context.l10n.shortcutRedoDescription,
    BusyMarkTextEditingShortcutAction.insertIndentation =>
      context.l10n.shortcutInsertIndentationDescription,
    BusyMarkTextEditingShortcutAction.outdentSource =>
      context.l10n.shortcutOutdentSourceDescription,
    BusyMarkTextEditingShortcutAction.escape =>
      context.l10n.shortcutEscapeDescription,
  };

  static String? _editorDescription(
    BuildContext context,
    BusyMarkEditorShortcutAction action,
  ) => switch (action) {
    BusyMarkEditorShortcutAction.bold => context.l10n.shortcutBoldDescription,
    BusyMarkEditorShortcutAction.italic =>
      context.l10n.shortcutItalicDescription,
    BusyMarkEditorShortcutAction.underline =>
      context.l10n.shortcutUnderlineDescription,
    BusyMarkEditorShortcutAction.link => context.l10n.shortcutLinkDescription,
    BusyMarkEditorShortcutAction.inlineCode =>
      context.l10n.shortcutInlineCodeDescription,
    BusyMarkEditorShortcutAction.strikethrough =>
      context.l10n.shortcutStrikethroughDescription,
    BusyMarkEditorShortcutAction.paragraph =>
      context.l10n.shortcutParagraphDescription,
    BusyMarkEditorShortcutAction.heading1 =>
      context.l10n.shortcutHeading1Description,
    BusyMarkEditorShortcutAction.heading2 =>
      context.l10n.shortcutHeading2Description,
    BusyMarkEditorShortcutAction.heading3 =>
      context.l10n.shortcutHeading3Description,
    BusyMarkEditorShortcutAction.heading4 =>
      context.l10n.shortcutHeading4Description,
    BusyMarkEditorShortcutAction.heading5 =>
      context.l10n.shortcutHeading5Description,
    BusyMarkEditorShortcutAction.heading6 =>
      context.l10n.shortcutHeading6Description,
    BusyMarkEditorShortcutAction.orderedList =>
      context.l10n.shortcutNumberedListDescription,
    BusyMarkEditorShortcutAction.unorderedList =>
      context.l10n.shortcutBulletedListDescription,
    BusyMarkEditorShortcutAction.taskList =>
      context.l10n.shortcutChecklistDescription,
    _ => null,
  };

  static String _editorCategory(
    BuildContext context,
    BusyMarkEditorShortcutAction action,
  ) => switch (action) {
    BusyMarkEditorShortcutAction.bold ||
    BusyMarkEditorShortcutAction.italic ||
    BusyMarkEditorShortcutAction.underline ||
    BusyMarkEditorShortcutAction.strikethrough ||
    BusyMarkEditorShortcutAction.inlineCode ||
    BusyMarkEditorShortcutAction.link => context.l10n.shortcutGroupFormatting,
    BusyMarkEditorShortcutAction.orderedList ||
    BusyMarkEditorShortcutAction.unorderedList ||
    BusyMarkEditorShortcutAction.taskList ||
    BusyMarkEditorShortcutAction.toggleTask ||
    BusyMarkEditorShortcutAction.indent ||
    BusyMarkEditorShortcutAction.outdent => context.l10n.shortcutGroupLists,
    BusyMarkEditorShortcutAction.image ||
    BusyMarkEditorShortcutAction.inlineImage ||
    BusyMarkEditorShortcutAction.table ||
    BusyMarkEditorShortcutAction.htmlBlock ||
    BusyMarkEditorShortcutAction.thematicBreak ||
    BusyMarkEditorShortcutAction.hardLineBreak => context.l10n.insert,
    _ => context.l10n.shortcutGroupBlocks,
  };

  static String _sidebarLabel(
    BuildContext context,
    BusyMarkSidebarShortcutAction action,
  ) => switch (action) {
    BusyMarkSidebarShortcutAction.files => context.l10n.files,
    BusyMarkSidebarShortcutAction.toc => context.l10n.toc,
    BusyMarkSidebarShortcutAction.outline => context.l10n.outline,
    BusyMarkSidebarShortcutAction.git => context.l10n.git,
  };
}
