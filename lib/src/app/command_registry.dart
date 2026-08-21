import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

class BusyMarkContextCommandIntent extends Intent {
  const BusyMarkContextCommandIntent(this.commandId);

  final String commandId;
}

class BusyMarkContextCommandAction
    extends Action<BusyMarkContextCommandIntent> {
  BusyMarkContextCommandAction({
    required this.isCommandEnabled,
    required this.onCommand,
  });

  final bool Function(String commandId) isCommandEnabled;
  final void Function(String commandId) onCommand;

  @override
  bool isEnabled(BusyMarkContextCommandIntent intent) {
    return isCommandEnabled(intent.commandId);
  }

  @override
  Object? invoke(BusyMarkContextCommandIntent intent) {
    onCommand(intent.commandId);
    return null;
  }
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
    this.disabledReason,
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
  final BusyMarkCommandDescription? disabledReason;
  final BusyMarkCommandCallback? execute;
  final BusyMarkCommandPredicate enabled;
  final BusyMarkCommandPredicate visible;

  bool get canExecute => execute != null && enabled();

  static bool _always() => true;
}

class BusyMarkCommandRegistryScope extends InheritedWidget {
  const BusyMarkCommandRegistryScope({
    super.key,
    required this.registry,
    required super.child,
  });

  final BusyMarkCommandRegistry registry;

  static BusyMarkCommandRegistry? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<BusyMarkCommandRegistryScope>()
        ?.registry;
  }

  static BusyMarkCommandRegistry? read(BuildContext context) {
    final widget = context
        .getElementForInheritedWidgetOfExactType<BusyMarkCommandRegistryScope>()
        ?.widget;
    return widget is BusyMarkCommandRegistryScope ? widget.registry : null;
  }

  @override
  bool updateShouldNotify(BusyMarkCommandRegistryScope oldWidget) {
    return !identical(registry, oldWidget.registry);
  }
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

  bool canExecuteInContext(String id, BuildContext? contextTarget) {
    final command = _byId[id];
    if (command == null || command.execute == null) {
      return false;
    }
    if (!_isContextual(command) || contextTarget == null) {
      return command.enabled();
    }
    final action = Actions.maybeFind<BusyMarkContextCommandIntent>(
      contextTarget,
    );
    return action?.isEnabled(BusyMarkContextCommandIntent(id)) ?? false;
  }

  Future<bool> executeInContext(String id, BuildContext? contextTarget) async {
    final command = _byId[id];
    if (command == null || !canExecuteInContext(id, contextTarget)) {
      return false;
    }
    if (_isContextual(command) && contextTarget != null) {
      Actions.maybeInvoke(contextTarget, BusyMarkContextCommandIntent(id));
      return true;
    }
    await command.execute!();
    return true;
  }

  bool _isContextual(BusyMarkCommand command) {
    return command.scope == BusyMarkCommandScope.editor ||
        command.scope == BusyMarkCommandScope.textEditing;
  }

  bool shortcutAccepts(String id, KeyEvent event, HardwareKeyboard keyboard) {
    return _byId[id]?.shortcut?.activator.accepts(event, keyboard) ?? false;
  }

  String? matchingCommandId(
    KeyEvent event,
    HardwareKeyboard keyboard, {
    required BusyMarkCommandScope scope,
  }) {
    for (final command in commands) {
      if (command.scope == scope &&
          command.shortcut?.activator.accepts(event, keyboard) == true) {
        return command.id;
      }
    }
    return null;
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
  static const textPastePlainText = 'text.pastePlainText';
  static const textUndo = 'text.undo';
  static const textRedo = 'text.redo';
  static const textInsertIndentation = 'text.insertIndentation';
  static const textOutdentSource = 'text.outdentSource';
  static const textEscape = 'text.escape';
  static const editorRefineWithAi = 'editor.refineWithAi';
  static const sidebarFiles = 'sidebar.files';
  static const sidebarToc = 'sidebar.toc';
  static const sidebarOutline = 'sidebar.outline';
  static const sidebarGit = 'sidebar.git';
  static const treeDeleteSelection = 'tree.deleteSelection';
}

abstract final class BusyMarkCommandCatalog {
  static final BusyMarkCommandRegistry metadata = create();

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
      BusyMarkShortcutDefinition? shortcut,
      BusyMarkCommandDescription? description,
    }) {
      final contextual =
          scope == BusyMarkCommandScope.editor ||
          scope == BusyMarkCommandScope.textEditing;
      return BusyMarkCommand(
        id: id,
        label: label,
        category: category,
        scope: scope,
        shortcut: shortcut,
        description: description,
        disabledReason: (context) => context.l10n.commandUnavailableInContext,
        execute:
            executions[id] ??
            (contextual ? () => _executeContextCommand(id) : null),
        enabled:
            enabled[id] ??
            (contextual
                ? () => _contextCommandAvailable(id)
                : BusyMarkCommand._always),
        visible: visible[id] ?? BusyMarkCommand._always,
      );
    }

    final commands = <BusyMarkCommand>[
      for (final action in BusyMarkAppShortcutAction.values)
        command(
          id: _appId(action),
          label: (context) => _appLabel(context, action),
          category: (context) => _appCategory(context, action),
          scope: BusyMarkCommandScope.application,
          shortcut: BusyMarkAppShortcuts.definitions[action],
          description: (context) => _appDescription(context, action),
        ),
      for (final action in BusyMarkDocumentViewShortcutAction.values)
        command(
          id: switch (action) {
            BusyMarkDocumentViewShortcutAction.editor =>
              BusyMarkCommandIds.viewEditor,
            BusyMarkDocumentViewShortcutAction.source =>
              BusyMarkCommandIds.viewSource,
            BusyMarkDocumentViewShortcutAction.reading =>
              BusyMarkCommandIds.viewReading,
            BusyMarkDocumentViewShortcutAction.split =>
              BusyMarkCommandIds.viewSplit,
          },
          label: (context) => _viewLabel(context, action),
          category: (context) => context.l10n.viewMode,
          scope: BusyMarkCommandScope.documentView,
          shortcut: BusyMarkDocumentViewShortcuts.definitions[action],
        ),
      for (final action in BusyMarkTextEditingShortcutAction.values)
        command(
          id: 'text.${action.name}',
          label: (context) => _textLabel(context, action),
          category: (context) => context.l10n.shortcutGroupTextEditing,
          scope: BusyMarkCommandScope.textEditing,
          shortcut: BusyMarkTextEditingShortcuts.definitions[action],
          description: (context) => _textDescription(context, action),
        ),
      for (final action in BusyMarkEditorShortcutAction.values)
        command(
          id: 'editor.${action.name}',
          label: (context) => _editorLabel(context, action),
          category: (context) => _editorCategory(context, action),
          scope: BusyMarkCommandScope.editor,
          shortcut: BusyMarkEditorShortcuts.definitions[action],
          description: (context) => _editorDescription(context, action),
        ),
      for (final action in BusyMarkSidebarShortcutAction.values)
        command(
          id: 'sidebar.${action.name}',
          label: (context) => _sidebarLabel(context, action),
          category: (context) => context.l10n.shortcutGroupSidebar,
          scope: BusyMarkCommandScope.sidebar,
          shortcut: BusyMarkSidebarShortcuts.definitions[action],
        ),
      for (final action in BusyMarkTreeShortcutAction.values)
        command(
          id: 'tree.${action.name}',
          label: (context) => context.l10n.delete,
          category: (context) => context.l10n.shortcutGroupSidebar,
          scope: BusyMarkCommandScope.tree,
          shortcut: BusyMarkTreeShortcuts.definitions[action],
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

  static BuildContext? get _focusedContext =>
      FocusManager.instance.primaryFocus?.context;

  static bool _contextCommandAvailable(String commandId) {
    final context = _focusedContext;
    final action = context == null
        ? null
        : Actions.maybeFind<BusyMarkContextCommandIntent>(context);
    return action?.isEnabled(BusyMarkContextCommandIntent(commandId)) ?? false;
  }

  static void _executeContextCommand(String commandId) {
    final context = _focusedContext;
    if (context != null) {
      Actions.maybeInvoke(context, BusyMarkContextCommandIntent(commandId));
    }
  }
}
