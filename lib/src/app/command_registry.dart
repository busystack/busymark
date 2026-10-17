import '../editor/wysiwyg/wysiwyg_commands.dart';
import '../markdown/busymark_document.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'busymark_shortcuts.dart';
import 'shortcut_binding.dart';
import 'shortcut_capture.dart';
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
    this.captureTarget,
  });

  final bool Function(String commandId) isCommandEnabled;
  final void Function(String commandId) onCommand;
  final BusyMarkContextCommandSnapshot Function()? captureTarget;

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

/// Editors capture their actual selection before the query receives focus.
/// Validation reads that editor again; it never restores a different selection.
class BusyMarkContextCommandSnapshot {
  const BusyMarkContextCommandSnapshot(this._validate);
  final bool Function() _validate;
  bool get isCurrent => _validate();
}

enum BusyMarkCommandScope {
  application,
  documentView,
  textEditing,
  editor,
  sidebar,
  tree,
  sourceSymbol,
  wysiwyg,
}

enum BusyMarkCommandResourceContext { any, localWorkspace, notesWorkspace }

@immutable
class BusyMarkCommand {
  const BusyMarkCommand({
    required this.id,
    required this.label,
    required this.category,
    required this.scope,
    this.shortcut,
    this.defaultYieldsToOverrides = false,
    this.resourceContext = BusyMarkCommandResourceContext.any,
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
  final bool defaultYieldsToOverrides;
  final BusyMarkCommandResourceContext resourceContext;

  BusyMarkCommand withShortcut(BusyMarkShortcutDefinition? value) =>
      BusyMarkCommand(
        id: id,
        label: label,
        category: category,
        scope: scope,
        shortcut: value,
        defaultYieldsToOverrides: defaultYieldsToOverrides,
        resourceContext: resourceContext,
        description: description,
        disabledReason: disabledReason,
        execute: execute,
        enabled: enabled,
        visible: visible,
      );
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
    for (final c in this.commands) {
      _aliases[c.id] = _defaultAliases(c);
    }
    _compileKeyCandidates();
  }

  final List<BusyMarkCommand> commands;
  final Map<String, List<ShortcutActivator>> _aliases = {};
  final Map<(BusyMarkCommandScope, LogicalKeyboardKey), List<String>>
  _keyCandidates = {};
  void _compileKeyCandidates() {
    _keyCandidates.clear();
    for (final c in commands) {
      for (final activator in activators(c.id)) {
        for (final trigger in activator.triggers ?? <LogicalKeyboardKey>[]) {
          (_keyCandidates[(c.scope, trigger)] ??= []).add(c.id);
        }
      }
    }
  }

  final Map<String, BusyMarkCommand> _replacedDefaults = {};
  final Map<String, List<ShortcutActivator>> _retiredBindings = {};
  final Map<int, List<ShortcutActivator>> _blockedBindings = {};
  List<ShortcutActivator> _blockedFor(Set<BusyMarkCommandScope> scopes) {
    final key = scopes.fold(0, (int bits, scope) => bits | 1 << scope.index);
    return _blockedBindings.putIfAbsent(key, () {
      final receivers = {
        ...scopes,
        BusyMarkCommandScope.application,
        BusyMarkCommandScope.documentView,
        BusyMarkCommandScope.sidebar,
      };
      bool replaced(BusyMarkCommand old, ShortcutActivator retired) =>
          commands.any(
            (c) =>
                receivers.contains(c.scope) &&
                contextsOverlap(old, c) &&
                activators(c.id).any(
                  (a) => a is SingleActivator && retired is SingleActivator
                      ? BusyMarkKeyBinding.fromActivator(a) ==
                            BusyMarkKeyBinding.fromActivator(retired)
                      : a == retired,
                ),
          );
      return [
        for (final c in _replacedDefaults.values)
          if (scopes.contains(c.scope))
            for (final a in _retiredBindings[c.id] ?? <ShortcutActivator>[])
              if (!replaced(c, a)) a,
      ];
    });
  }

  Map<ShortcutActivator, Intent> blockedDefaultIntents(
    Set<BusyMarkCommandScope> scopes,
  ) => {
    for (final a in _blockedFor(scopes))
      a: const DoNothingAndStopPropagationIntent(),
  };
  bool blocksReplacedDefault(
    KeyEvent event,
    HardwareKeyboard keyboard,
    Set<BusyMarkCommandScope> scopes,
  ) => _blockedFor(scopes).any((a) => a.accepts(event, keyboard));
  List<ShortcutActivator> activators(String id) => [
    if (_byId[id]?.shortcut case final value?) value.activator,
    ...?_aliases[id],
  ];

  BusyMarkCommandRegistry withOverrides(
    Map<String, BusyMarkKeyBinding?> overrides,
  ) {
    final result = BusyMarkCommandRegistry([
      for (final command in commands)
        if (!overrides.containsKey(command.id))
          command
        else
          command.withShortcut(switch (overrides[command.id]) {
            final binding? => BusyMarkShortcutDefinition(
              label: binding.label,
              activator: binding.activator,
              gtkAccelerator: binding.gtkAccelerator,
            ),
            _ => null,
          }),
    ]);
    result._aliases.clear();
    for (final command in result.commands) {
      if (overrides.containsKey(command.id)) {
        result._replacedDefaults[command.id] = this[command.id]!;
        result._retiredBindings[command.id] = activators(command.id);
      } else {
        result._aliases[command.id] = _defaultAliases(command);
      }
    }
    result._compileKeyCandidates();
    return result;
  }

  Map<ShortcutActivator, Intent> bindingIntents(String id, Intent intent) => {
    for (final activator in activators(id)) activator: intent,
  };

  /// Actual receiving contexts overlap across scopes. Tree browsing is the one
  /// disjoint document context; line movement edits the Source .tree buffer.
  static bool contextsOverlap(BusyMarkCommand a, BusyMarkCommand b) {
    if (a.resourceContext != BusyMarkCommandResourceContext.any &&
        b.resourceContext != BusyMarkCommandResourceContext.any &&
        a.resourceContext != b.resourceContext) {
      return false;
    }
    bool global(BusyMarkCommand c) => {
      BusyMarkCommandScope.application,
      BusyMarkCommandScope.documentView,
      BusyMarkCommandScope.sidebar,
    }.contains(c.scope);
    bool treeOnly(BusyMarkCommand c) =>
        c.id == BusyMarkCommandIds.treeDeleteSelection ||
        c.id == BusyMarkCommandIds.treeRenameSelection;
    if (global(a) || global(b)) return true;
    bool sourceOnly(BusyMarkCommand c) =>
        c.scope == BusyMarkCommandScope.sourceSymbol ||
        c.id == BusyMarkCommandIds.treeMoveLineUp ||
        c.id == BusyMarkCommandIds.treeMoveLineDown;
    if (a.scope == BusyMarkCommandScope.wysiwyg && sourceOnly(b) ||
        b.scope == BusyMarkCommandScope.wysiwyg && sourceOnly(a)) {
      return false;
    }
    if (treeOnly(a) || treeOnly(b)) {
      return treeOnly(a) && treeOnly(b);
    }
    return true;
  }

  List<BusyMarkCommand> conflicts(String id, BusyMarkKeyBinding binding) {
    final command = this[id];
    if (command == null) return const [];
    return [
      for (final other in commands)
        if (other.id != id &&
            contextsOverlap(command, other) &&
            activators(other.id).whereType<SingleActivator>().any(
              (a) => BusyMarkKeyBinding.fromActivator(a) == binding,
            ))
          other,
    ];
  }

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
    if (!isContextual(command) || contextTarget == null) {
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
    if (isContextual(command) && contextTarget != null) {
      Actions.maybeInvoke(contextTarget, BusyMarkContextCommandIntent(id));
      return true;
    }
    await command.execute!();
    return true;
  }

  bool isContextual(BusyMarkCommand command) {
    return command.scope == BusyMarkCommandScope.editor ||
        command.scope == BusyMarkCommandScope.wysiwyg ||
        command.scope == BusyMarkCommandScope.textEditing ||
        command.scope == BusyMarkCommandScope.sourceSymbol ||
        command.scope == BusyMarkCommandScope.tree ||
        command.id == BusyMarkCommandIds.treeMoveLineUp ||
        command.id == BusyMarkCommandIds.treeMoveLineDown;
  }

  bool requiresDocumentTarget(BusyMarkCommand command) =>
      isContextual(command) ||
      command.scope == BusyMarkCommandScope.documentView ||
      const {
        BusyMarkCommandIds.search,
        BusyMarkCommandIds.save,
        BusyMarkCommandIds.export,
        BusyMarkCommandIds.closeTab,
        BusyMarkCommandIds.elementProperties,
        BusyMarkCommandIds.references,
        BusyMarkCommandIds.sidebarOutline,
      }.contains(command.id);

  bool requiresWorkspaceTarget(BusyMarkCommand command) =>
      command.scope == BusyMarkCommandScope.sidebar ||
      const {
        BusyMarkCommandIds.localHistory,
        BusyMarkCommandIds.findLocalHistory,
        BusyMarkCommandIds.syncNotes,
        BusyMarkCommandIds.exportNotes,
        BusyMarkCommandIds.importNotesFolder,
        BusyMarkCommandIds.importNotesFile,
        BusyMarkCommandIds.nextTab,
        BusyMarkCommandIds.previousTab,
        BusyMarkCommandIds.closeAllTabs,
      }.contains(command.id);

  bool shortcutAccepts(String id, KeyEvent event, HardwareKeyboard keyboard) {
    return !BusyMarkShortcutCapture.suppressing &&
        activators(id).any((a) => a.accepts(event, keyboard));
  }

  String? matchingCommandId(
    KeyEvent event,
    HardwareKeyboard keyboard, {
    required BusyMarkCommandScope scope,
  }) {
    if (BusyMarkShortcutCapture.suppressing) return null;
    for (final id in _keyCandidates[(scope, event.logicalKey)] ?? <String>[]) {
      if (shortcutAccepts(id, event, keyboard)) return id;
    }
    return null;
  }

  Map<ShortcutActivator, Intent> shortcutIntents({
    required Set<BusyMarkCommandScope> scopes,
    required Intent Function(String commandId) intentFor,
    Set<String> excludedIds = const {},
  }) {
    return {
      for (final command in commands)
        if (scopes.contains(command.scope) &&
            command.shortcut != null &&
            !excludedIds.contains(command.id))
          for (final activator in activators(command.id))
            activator: intentFor(command.id),
    };
  }

  static void _validate(List<BusyMarkCommand> commands) {
    final ids = <String>{};
    final shortcuts = <(BusyMarkCommandScope, Object), List<BusyMarkCommand>>{};
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
      final activator = shortcut.activator;
      final key = (
        command.scope,
        activator is SingleActivator
            ? BusyMarkKeyBinding.fromActivator(activator)
            : activator,
      );
      final existing = shortcuts[key] ??= [];
      for (final other in existing) {
        if (contextsOverlap(command, other)) {
          throw BusyMarkCommandRegistryValidationException(
            'Shortcut conflict in ${command.scope.name}: ${other.id} and ${command.id}',
          );
        }
      }
      existing.add(command);
    }
  }
}

abstract final class BusyMarkCommandIds {
  static const newDocument = 'file.newDocument';
  static const open = 'file.open';
  static const save = 'file.save';
  static const export = 'file.export';
  static const fullScreen = 'view.fullScreen';
  static const back = 'navigation.back';
  static const search = 'search.find';
  static const searchWorkspace = 'search.workspace';
  static const searchHeadings = 'search.headings';
  static const searchTopics = 'search.topics';
  static const searchRecent = 'search.recent';
  static const newNote = 'notes.create';
  static const browseNotes = 'notes.browse';
  static const syncNotes = 'notes.sync';
  static const exportNotes = 'notes.export';
  static const importNotesFolder = 'notes.importFolder';
  static const importNotesFile = 'notes.importFile';
  static const keyboardShortcuts = 'help.keyboardShortcuts';
  static const quickOpen = 'workspace.quickOpen';
  static const commandPalette = 'view.commandPalette';
  static const syntaxReference = 'help.syntaxReference';
  static const settings = 'application.settings';
  static const nextTab = 'tabs.next';
  static const previousTab = 'tabs.previous';
  static const closeTab = 'tabs.close';
  static const closeAllTabs = 'tabs.closeAll';
  static const toggleSidebar = 'view.toggleSidebar';
  static const elementProperties = 'view.elementProperties';
  static const viewEditor = 'view.editor';
  static const viewSource = 'view.source';
  static const viewReading = 'view.reading';
  static const viewSplit = 'view.split';
  static const textSelectAll = 'text.selectAll';
  static const textCut = 'text.cut';
  static const textCopy = 'text.copy';
  static const editorCopyPlainText = 'editor.copyPlainText';
  static const textPaste = 'text.paste';
  static const textPastePlainText = 'text.pastePlainText';
  static const textUndo = 'text.undo';
  static const textRedo = 'text.redo';
  static const textInsertIndentation = 'text.insertIndentation';
  static const textOutdentSource = 'text.outdentSource';
  static const textEscape = 'text.escape';
  static const editorRefineWithAi = 'editor.refineWithAi';
  static const checkSpelling = 'spelling.check';
  static const references = 'sidebar.references';
  static const sidebarFiles = 'sidebar.files';
  static const sidebarToc = 'sidebar.toc';
  static const sidebarOutline = 'sidebar.outline';
  static const sidebarGit = 'sidebar.git';
  static const clipboardHistory = 'sidebar.clipboardHistory';
  static const localHistory = 'history.local';
  static const findLocalHistory = 'history.findLocal';
  static const sourceDeclaration = 'source.declaration';
  static const sourceUsages = 'source.usages';
  static const sourceRename = 'source.rename';
  static const treeRenameSelection = 'tree.renameSelection';
  static const treeDeleteSelection = 'tree.deleteSelection';
  static const treeMoveLineUp = 'tree.moveLineUp';
  static const treeMoveLineDown = 'tree.moveLineDown';
}

abstract final class BusyMarkCommandCatalog {
  static const notesWorkspaceCommandIds = <String>{
    BusyMarkCommandIds.syncNotes,
    BusyMarkCommandIds.exportNotes,
    BusyMarkCommandIds.importNotesFolder,
    BusyMarkCommandIds.importNotesFile,
  };
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
      bool defaultYieldsToOverrides = false,
      BusyMarkCommandDescription? description,
    }) {
      final contextual =
          scope == BusyMarkCommandScope.editor ||
          scope == BusyMarkCommandScope.wysiwyg ||
          scope == BusyMarkCommandScope.textEditing ||
          scope == BusyMarkCommandScope.sourceSymbol ||
          scope == BusyMarkCommandScope.tree ||
          id == BusyMarkCommandIds.treeMoveLineUp ||
          id == BusyMarkCommandIds.treeMoveLineDown;
      return BusyMarkCommand(
        id: id,
        label: label,
        category: category,
        scope: scope,
        shortcut: shortcut,
        defaultYieldsToOverrides: defaultYieldsToOverrides,
        resourceContext: notesWorkspaceCommandIds.contains(id)
            ? BusyMarkCommandResourceContext.notesWorkspace
            : scope == BusyMarkCommandScope.sourceSymbol ||
                  const {
                    BusyMarkCommandIds.treeDeleteSelection,
                    BusyMarkCommandIds.treeRenameSelection,
                    BusyMarkCommandIds.treeMoveLineUp,
                    BusyMarkCommandIds.treeMoveLineDown,
                  }.contains(id)
            ? BusyMarkCommandResourceContext.localWorkspace
            : BusyMarkCommandResourceContext.any,
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
      command(
        id: BusyMarkCommandIds.sourceDeclaration,
        label: (c) => c.l10n.goToDeclaration,
        category: (c) => 'Writerside',
        scope: BusyMarkCommandScope.sourceSymbol,
        shortcut: const BusyMarkShortcutDefinition(
          label: 'Ctrl+B',
          activator: SingleActivator(LogicalKeyboardKey.keyB, control: true),
        ),
      ),
      command(
        id: BusyMarkCommandIds.sourceUsages,
        label: (c) => c.l10n.findUsages,
        category: (c) => 'Writerside',
        scope: BusyMarkCommandScope.sourceSymbol,
        shortcut: const BusyMarkShortcutDefinition(
          label: 'Alt+F7',
          activator: SingleActivator(LogicalKeyboardKey.f7, alt: true),
        ),
      ),
      command(
        id: BusyMarkCommandIds.sourceRename,
        label: (c) => c.l10n.rename,
        category: (c) => 'Writerside',
        scope: BusyMarkCommandScope.sourceSymbol,
        shortcut: const BusyMarkShortcutDefinition(
          label: 'Shift+F6',
          activator: SingleActivator(LogicalKeyboardKey.f6, shift: true),
        ),
      ),
      command(
        id: BusyMarkCommandIds.newNote,
        label: (c) => c.l10n.nextcloudNewNote,
        category: (c) => c.l10n.nextcloudNotes,
        scope: BusyMarkCommandScope.application,
      ),
      command(
        id: BusyMarkCommandIds.browseNotes,
        label: (c) => c.l10n.browseNotes,
        category: (c) => c.l10n.nextcloudNotes,
        scope: BusyMarkCommandScope.application,
      ),
      command(
        id: BusyMarkCommandIds.syncNotes,
        label: (c) => c.l10n.notesSync,
        category: (c) => c.l10n.nextcloudNotes,
        scope: BusyMarkCommandScope.application,
      ),
      command(
        id: BusyMarkCommandIds.exportNotes,
        label: (c) => c.l10n.notesExport,
        category: (c) => c.l10n.nextcloudNotes,
        scope: BusyMarkCommandScope.application,
      ),
      command(
        id: BusyMarkCommandIds.importNotesFolder,
        label: (c) => '${c.l10n.notesImport} · ${c.l10n.folder}',
        category: (c) => c.l10n.nextcloudNotes,
        scope: BusyMarkCommandScope.application,
      ),
      command(
        id: BusyMarkCommandIds.importNotesFile,
        label: (c) => '${c.l10n.notesImport} · ${c.l10n.fileTypeMarkdown}',
        category: (c) => c.l10n.nextcloudNotes,
        scope: BusyMarkCommandScope.application,
      ),
      for (final entry in writersideCommands.entries)
        command(
          id: entry.key,
          label: (context) => writersideCommandLabel(context, entry.value),
          category: (context) => 'Writerside',
          scope: BusyMarkCommandScope.wysiwyg,
        ),
      command(
        id: BusyMarkCommandIds.searchWorkspace,
        label: (context) => context.l10n.searchInWorkspace,
        category: (c) => c.l10n.search,
        scope: BusyMarkCommandScope.application,
        shortcut: const BusyMarkShortcutDefinition(
          label: 'Ctrl+Shift+F',
          activator: SingleActivator(
            LogicalKeyboardKey.keyF,
            control: true,
            shift: true,
          ),
          gtkAccelerator: '<Primary><Shift>f',
        ),
      ),
      command(
        id: BusyMarkCommandIds.searchHeadings,
        label: (c) => c.l10n.searchHeadingsCommand,
        category: (c) => c.l10n.search,
        scope: BusyMarkCommandScope.application,
        defaultYieldsToOverrides: true,
        shortcut: const BusyMarkShortcutDefinition(
          label: 'Ctrl+Shift+H',
          activator: SingleActivator(
            LogicalKeyboardKey.keyH,
            control: true,
            shift: true,
          ),
          gtkAccelerator: '<Primary><Shift>h',
        ),
      ),
      command(
        id: BusyMarkCommandIds.searchTopics,
        label: (context) => context.l10n.searchTopicsCommand,
        category: (c) => c.l10n.search,
        scope: BusyMarkCommandScope.application,
        shortcut: const BusyMarkShortcutDefinition(
          label: 'Ctrl+Shift+T',
          activator: SingleActivator(
            LogicalKeyboardKey.keyT,
            control: true,
            shift: true,
          ),
          gtkAccelerator: '<Primary><Shift>t',
        ),
      ),
      command(
        id: BusyMarkCommandIds.searchRecent,
        label: (context) => context.l10n.searchRecentCommand,
        category: (c) => c.l10n.search,
        scope: BusyMarkCommandScope.application,
        defaultYieldsToOverrides: true,
        shortcut: const BusyMarkShortcutDefinition(
          label: 'Ctrl+Shift+R',
          activator: SingleActivator(
            LogicalKeyboardKey.keyR,
            control: true,
            shift: true,
          ),
          gtkAccelerator: '<Primary><Shift>r',
        ),
      ),
      command(
        id: BusyMarkCommandIds.elementProperties,
        label: (context) => context.l10n.wsElementProperties,
        category: (context) => context.l10n.viewMode,
        scope: BusyMarkCommandScope.documentView,
      ),
      command(
        id: BusyMarkCommandIds.references,
        label: (context) => context.l10n.references,
        category: (context) => context.l10n.shortcutGroupSidebar,
        scope: BusyMarkCommandScope.sidebar,
      ),
      for (final action in BusyMarkAppShortcutAction.values)
        command(
          id: _appId(action),
          label: (context) => _appLabel(context, action),
          category: (context) => _appCategory(context, action),
          scope: BusyMarkCommandScope.application,
          shortcut: BusyMarkAppShortcuts.definitions[action],
          defaultYieldsToOverrides:
              action == BusyMarkAppShortcutAction.quickOpen,
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
      command(
        id: BusyMarkCommandIds.treeMoveLineUp,
        label: (context) => context.l10n.tocMoveLineUp,
        category: (context) => context.l10n.toc,
        scope: BusyMarkCommandScope.tree,
        shortcut: const BusyMarkShortcutDefinition(
          label: 'Ctrl+Shift+Home',
          activator: SingleActivator(
            LogicalKeyboardKey.home,
            control: true,
            shift: true,
          ),
        ),
      ),
      command(
        id: BusyMarkCommandIds.treeMoveLineDown,
        label: (context) => context.l10n.tocMoveLineDown,
        category: (context) => context.l10n.toc,
        scope: BusyMarkCommandScope.tree,
        shortcut: const BusyMarkShortcutDefinition(
          label: 'Ctrl+Shift+End',
          activator: SingleActivator(
            LogicalKeyboardKey.end,
            control: true,
            shift: true,
          ),
        ),
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
      command(
        id: BusyMarkCommandIds.checkSpelling,
        label: (context) => context.l10n.checkSpelling,
        category: (context) => context.l10n.shortcutGroupTextEditing,
        scope: BusyMarkCommandScope.editor,
        shortcut: const BusyMarkShortcutDefinition(
          label: 'F7',
          activator: SingleActivator(
            LogicalKeyboardKey.f7,
            includeRepeats: false,
          ),
          gtkAccelerator: 'F7',
        ),
      ),
      for (final action in BusyMarkSidebarShortcutAction.values)
        command(
          id: _sidebarId(action),
          label: (context) => _sidebarLabel(context, action),
          category: (context) => context.l10n.shortcutGroupSidebar,
          scope: switch (action) {
            BusyMarkSidebarShortcutAction.localHistory ||
            BusyMarkSidebarShortcutAction.clipboardHistory =>
              BusyMarkCommandScope.application,
            _ => BusyMarkCommandScope.sidebar,
          },
          shortcut: BusyMarkSidebarShortcuts.definitions[action],
          description: (context) => _sidebarDescription(context, action),
        ),
      command(
        id: BusyMarkCommandIds.treeRenameSelection,
        label: (c) => c.l10n.rename,
        category: (c) => c.l10n.shortcutGroupSidebar,
        scope: BusyMarkCommandScope.tree,
        shortcut: const BusyMarkShortcutDefinition(
          label: 'Shift+F6',
          activator: SingleActivator(LogicalKeyboardKey.f6, shift: true),
        ),
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
      command(
        id: BusyMarkCommandIds.findLocalHistory,
        defaultYieldsToOverrides: true,
        shortcut: const BusyMarkShortcutDefinition(
          label: 'Ctrl+Shift+L',
          activator: SingleActivator(
            LogicalKeyboardKey.keyL,
            control: true,
            shift: true,
          ),
          gtkAccelerator: '<Primary><Shift>l',
        ),
        label: (context) => context.l10n.findLocalHistoryEllipsis,
        category: (context) => context.l10n.search,
        scope: BusyMarkCommandScope.application,
        description: (context) => context.l10n.findLocalHistoryDescription,
      ),
    ];
    return BusyMarkCommandRegistry(commands);
  }

  static String _appId(BusyMarkAppShortcutAction action) => switch (action) {
    BusyMarkAppShortcutAction.newDocument => BusyMarkCommandIds.newDocument,
    BusyMarkAppShortcutAction.open => BusyMarkCommandIds.open,
    BusyMarkAppShortcutAction.save => BusyMarkCommandIds.save,
    BusyMarkAppShortcutAction.export => BusyMarkCommandIds.export,
    BusyMarkAppShortcutAction.fullScreen => BusyMarkCommandIds.fullScreen,
    BusyMarkAppShortcutAction.back => BusyMarkCommandIds.back,
    BusyMarkAppShortcutAction.search => BusyMarkCommandIds.search,
    BusyMarkAppShortcutAction.quickOpen => BusyMarkCommandIds.quickOpen,
    BusyMarkAppShortcutAction.keyboardShortcuts =>
      BusyMarkCommandIds.keyboardShortcuts,
    BusyMarkAppShortcutAction.commandPalette =>
      BusyMarkCommandIds.commandPalette,
    BusyMarkAppShortcutAction.syntaxReference =>
      BusyMarkCommandIds.syntaxReference,
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
    BusyMarkAppShortcutAction.export => context.l10n.export,
    BusyMarkAppShortcutAction.fullScreen => context.l10n.fullScreen,
    BusyMarkAppShortcutAction.back => context.l10n.back,
    BusyMarkAppShortcutAction.search => context.l10n.searchInDocument,
    BusyMarkAppShortcutAction.quickOpen => context.l10n.searchDocumentsCommand,
    BusyMarkAppShortcutAction.keyboardShortcuts =>
      context.l10n.keyboardShortcuts,
    BusyMarkAppShortcutAction.commandPalette =>
      context.l10n.searchActionsCommand,
    BusyMarkAppShortcutAction.syntaxReference => context.l10n.syntaxReference,
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
    BusyMarkAppShortcutAction.search ||
    BusyMarkAppShortcutAction.quickOpen ||
    BusyMarkAppShortcutAction.commandPalette => context.l10n.search,
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
    BusyMarkAppShortcutAction.export => null,
    BusyMarkAppShortcutAction.search => context.l10n.shortcutSearchDescription,
    BusyMarkAppShortcutAction.keyboardShortcuts =>
      context.l10n.shortcutKeyboardShortcutsDescription,
    BusyMarkAppShortcutAction.syntaxReference =>
      context.l10n.shortcutSyntaxReferenceDescription,
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
      context.l10n.clipboardPastePlainText,
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
    BusyMarkEditorShortcutAction.copyPlainText => context.l10n.copyPlainText,
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
    BusyMarkEditorShortcutAction.copyPlainText =>
      context.l10n.shortcutGroupTextEditing,
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
    BusyMarkSidebarShortcutAction.localHistory =>
      context.l10n.localHistoryEllipsis,
    BusyMarkSidebarShortcutAction.clipboardHistory =>
      context.l10n.clipboardHistory,
  };

  static String _sidebarId(BusyMarkSidebarShortcutAction action) =>
      switch (action) {
        BusyMarkSidebarShortcutAction.files => BusyMarkCommandIds.sidebarFiles,
        BusyMarkSidebarShortcutAction.toc => BusyMarkCommandIds.sidebarToc,
        BusyMarkSidebarShortcutAction.outline =>
          BusyMarkCommandIds.sidebarOutline,
        BusyMarkSidebarShortcutAction.git => BusyMarkCommandIds.sidebarGit,
        BusyMarkSidebarShortcutAction.localHistory =>
          BusyMarkCommandIds.localHistory,
        BusyMarkSidebarShortcutAction.clipboardHistory =>
          BusyMarkCommandIds.clipboardHistory,
      };

  static String? _sidebarDescription(
    BuildContext context,
    BusyMarkSidebarShortcutAction action,
  ) => switch (action) {
    BusyMarkSidebarShortcutAction.localHistory =>
      context.l10n.localHistoryDescription,
    BusyMarkSidebarShortcutAction.clipboardHistory =>
      context.l10n.clipboardHistoryDescription,
    _ => null,
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

/// The same typed commands used by the consolidated Writerside toolbar.
final writersideCommands = <String, BusyWritersideToolbarCommand>{
  for (final command in BusyWritersideInsertCommand.values)
    writersideToolbarCommandId(BusyWritersideToolbarInsert(command)):
        BusyWritersideToolbarInsert(command),
  for (final style in BusyAdmonitionStyle.values)
    writersideToolbarCommandId(BusyWritersideToolbarAdmonition(style)):
        BusyWritersideToolbarAdmonition(style),
  for (final command in [
    BusyWysiwygInlineCommand.uiControl,
    BusyWysiwygInlineCommand.filePath,
    BusyWysiwygInlineCommand.uiPath,
    BusyWysiwygInlineCommand.shortcut,
  ])
    writersideToolbarCommandId(BusyWritersideToolbarSemantic(command)):
        BusyWritersideToolbarSemantic(command),
};
String writersideToolbarCommandId(
  BusyWritersideToolbarCommand value,
) => switch (value) {
  BusyWritersideToolbarInsert(:final command) =>
    'writerside.insert${command.name[0].toUpperCase()}${command.name.substring(1)}',
  BusyWritersideToolbarAdmonition(:final style) => 'writerside.${style.name}',
  BusyWritersideToolbarSemantic(:final command) => 'writerside.${command.name}',
};
String writersideCommandLabel(
  BuildContext context,
  BusyWritersideToolbarCommand command,
) => switch (command) {
  BusyWritersideToolbarInsert(:final command) => switch (command) {
    BusyWritersideInsertCommand.procedure => context.l10n.procedure,
    BusyWritersideInsertCommand.tabs => context.l10n.tabs,
    BusyWritersideInsertCommand.definitionList => context.l10n.wsDefinitionList,
    BusyWritersideInsertCommand.include => context.l10n.wsIncludeContent,
    BusyWritersideInsertCommand.variable => context.l10n.wsVariableReference,
    BusyWritersideInsertCommand.video => context.l10n.video,
    BusyWritersideInsertCommand.tldr => context.l10n.wsTldr,
    BusyWritersideInsertCommand.convertListToProcedure =>
      context.l10n.wsConvertList,
  },
  BusyWritersideToolbarAdmonition(:final style) => switch (style) {
    BusyAdmonitionStyle.tip => context.l10n.tip,
    BusyAdmonitionStyle.note => context.l10n.note,
    BusyAdmonitionStyle.warning => context.l10n.warning,
    BusyAdmonitionStyle.quote => context.l10n.quote,
  },
  BusyWritersideToolbarSemantic(:final command) => switch (command) {
    BusyWysiwygInlineCommand.uiControl => context.l10n.wsUiControl,
    BusyWysiwygInlineCommand.filePath => context.l10n.wsFilePath,
    BusyWysiwygInlineCommand.uiPath => context.l10n.wsUiPath,
    _ => context.l10n.keyboardShortcuts,
  },
};

final _keypadAliases = <LogicalKeyboardKey, LogicalKeyboardKey>{
  LogicalKeyboardKey.digit0: LogicalKeyboardKey.numpad0,
  LogicalKeyboardKey.digit1: LogicalKeyboardKey.numpad1,
  LogicalKeyboardKey.digit2: LogicalKeyboardKey.numpad2,
  LogicalKeyboardKey.digit3: LogicalKeyboardKey.numpad3,
  LogicalKeyboardKey.digit4: LogicalKeyboardKey.numpad4,
  LogicalKeyboardKey.digit5: LogicalKeyboardKey.numpad5,
  LogicalKeyboardKey.digit6: LogicalKeyboardKey.numpad6,
};

List<ShortcutActivator> _defaultAliases(BusyMarkCommand command) {
  final shortcut = command.shortcut;
  if (shortcut == null) return const [];
  final aliases = <ShortcutActivator>[
    ...?const <String, List<ShortcutActivator>>{
      BusyMarkCommandIds.textCopy: [
        SingleActivator(LogicalKeyboardKey.insert, control: true),
      ],
      BusyMarkCommandIds.textCut: [
        SingleActivator(LogicalKeyboardKey.delete, shift: true),
      ],
      BusyMarkCommandIds.textPaste: [
        SingleActivator(LogicalKeyboardKey.insert, shift: true),
      ],
    }[command.id],
  ];
  final a = shortcut.activator;
  if (a is SingleActivator &&
      (command.scope == BusyMarkCommandScope.sidebar ||
          command.id == BusyMarkCommandIds.localHistory ||
          command.id == BusyMarkCommandIds.clipboardHistory)) {
    final key = _keypadAliases[a.trigger];
    if (key != null) {
      aliases.add(
        SingleActivator(
          key,
          control: a.control,
          shift: a.shift,
          alt: a.alt,
          meta: a.meta,
          includeRepeats: false,
        ),
      );
    }
  }
  return aliases;
}
