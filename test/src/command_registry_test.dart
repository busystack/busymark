import 'package:busymark/src/app/command_shortcuts.dart';
import 'package:busymark/src/app/keymap_controller.dart';
import 'package:busymark/src/app/shortcut_binding.dart';
import 'package:busymark/src/app/command_registry.dart';
import 'package:busymark/src/app/busymark_shortcuts.dart';
import 'package:busymark/src/search/search_session.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  test(
    'tree browsing and Source line movement can share a combination within one scope',
    () {
      final registry =
          effectiveCommandRegistry(BusyMarkCommandCatalog.metadata, {
            'tree.renameSelection': const BusyMarkKeyBinding(
              LogicalKeyboardKey.f8,
            ),
            'tree.moveLineUp': const BusyMarkKeyBinding(LogicalKeyboardKey.f8),
          });
      expect(registry['tree.renameSelection']!.shortcut!.label, 'F8');
      expect(registry['tree.moveLineUp']!.shortcut!.label, 'F8');
      expect(
        registry.conflicts(
          'tree.moveLineUp',
          const BusyMarkKeyBinding(LogicalKeyboardKey.f8),
        ),
        isEmpty,
      );
    },
  );

  test(
    'effective overrides resolve simultaneously without serialized-order winners',
    () {
      final defaults = BusyMarkCommandCatalog.metadata;
      const bold = BusyMarkKeyBinding(LogicalKeyboardKey.keyS, control: true);
      const save = BusyMarkKeyBinding(LogicalKeyboardKey.f8);
      for (final map in [
        {'editor.bold': bold, 'file.save': save},
        {'file.save': save, 'editor.bold': bold},
      ]) {
        final registry = effectiveCommandRegistry(defaults, map);
        expect(registry['editor.bold']!.shortcut!.label, 'Ctrl+S');
        expect(registry['file.save']!.shortcut!.label, 'F8');
      }
      for (final map in [
        {'editor.bold': save, 'file.save': save},
        {'file.save': save, 'editor.bold': save},
        {'editor.bold': save, 'file.save': save, 'editor.italic': bold},
      ]) {
        final registry = effectiveCommandRegistry(defaults, map);
        expect(registry['editor.bold']!.shortcut!.label, 'Ctrl+B');
        expect(registry['file.save']!.shortcut!.label, 'Ctrl+S');
        expect(registry['editor.italic']!.shortcut!.label, 'Ctrl+I');
      }
    },
  );

  test('Writerside Editor and Source operations have separate receivers', () {
    final registry = effectiveCommandRegistry(BusyMarkCommandCatalog.metadata, {
      'writerside.uiControl': const BusyMarkKeyBinding(
        LogicalKeyboardKey.f7,
        alt: true,
      ),
    });
    expect(registry['writerside.uiControl']!.shortcut!.label, 'Alt+F7');
    expect(registry['source.usages']!.shortcut!.label, 'Alt+F7');
    expect(
      registry.conflicts(
        'writerside.uiControl',
        const BusyMarkKeyBinding(LogicalKeyboardKey.f7, alt: true),
      ),
      isEmpty,
    );
    expect(
      registry
          .conflicts(
            'editor.bold',
            const BusyMarkKeyBinding(LogicalKeyboardKey.f7, alt: true),
          )
          .map((c) => c.id),
      containsAll(['source.usages', 'writerside.uiControl']),
    );
    final reassigned =
        effectiveCommandRegistry(BusyMarkCommandCatalog.metadata, {
          'text.paste': null,
          'writerside.uiControl': const BusyMarkKeyBinding(
            LogicalKeyboardKey.keyV,
            control: true,
          ),
        });
    const paste = SingleActivator(LogicalKeyboardKey.keyV, control: true);
    expect(
      reassigned.blockedDefaultIntents({
        BusyMarkCommandScope.editor,
        BusyMarkCommandScope.textEditing,
      }),
      contains(paste),
    );
    expect(
      reassigned.blockedDefaultIntents({
        BusyMarkCommandScope.editor,
        BusyMarkCommandScope.wysiwyg,
        BusyMarkCommandScope.textEditing,
      }),
      isNot(contains(paste)),
    );
  });

  test(
    'resource-exclusive Notes and local Source receivers can reuse a binding',
    () {
      final registry =
          effectiveCommandRegistry(BusyMarkCommandCatalog.metadata, {
            'notes.sync': const BusyMarkKeyBinding(
              LogicalKeyboardKey.keyY,
              control: true,
              alt: true,
            ),
            'source.declaration': const BusyMarkKeyBinding(
              LogicalKeyboardKey.keyY,
              control: true,
              alt: true,
            ),
          });
      expect(registry['notes.sync']!.shortcut!.label, 'Ctrl+Alt+Y');
      expect(registry['source.declaration']!.shortcut!.label, 'Ctrl+Alt+Y');
      expect(
        BusyMarkCommandRegistry.contextsOverlap(
          registry['notes.sync']!,
          registry['source.declaration']!,
        ),
        isFalse,
      );
      expect(
        BusyMarkCommandRegistry.contextsOverlap(
          registry['notes.sync']!,
          registry['tree.deleteSelection']!,
        ),
        isFalse,
      );
      expect(
        BusyMarkCommandRegistry.contextsOverlap(
          registry['notes.sync']!,
          registry['tree.moveLineUp']!,
        ),
        isFalse,
      );
      expect(
        BusyMarkCommandRegistry.contextsOverlap(
          registry['notes.sync']!,
          registry['editor.bold']!,
        ),
        isTrue,
      );
      expect(
        registry['notes.sync']!.resourceContext,
        BusyMarkCommandResourceContext.notesWorkspace,
      );
      expect(
        registry['source.declaration']!.resourceContext,
        BusyMarkCommandResourceContext.localWorkspace,
      );
    },
  );

  test('conflicts reflect receiving contexts and all default aliases', () {
    final registry = effectiveCommandRegistry(
      BusyMarkCommandCatalog.metadata,
      {},
    );
    expect(
      registry
          .conflicts(
            'editor.italic',
            const BusyMarkKeyBinding(LogicalKeyboardKey.keyS, control: true),
          )
          .map((c) => c.id),
      ['file.save'],
    );
    expect(
      registry
          .conflicts(
            'file.save',
            const BusyMarkKeyBinding(LogicalKeyboardKey.numpad3, control: true),
          )
          .map((c) => c.id),
      ['sidebar.outline'],
    );
    expect(
      BusyMarkCommandRegistry.contextsOverlap(
        registry['tree.deleteSelection']!,
        registry['editor.bold']!,
      ),
      isFalse,
    );
    expect(
      BusyMarkCommandRegistry.contextsOverlap(
        registry['tree.moveLineUp']!,
        registry['editor.bold']!,
      ),
      isTrue,
    );
    final custom = effectiveCommandRegistry(BusyMarkCommandCatalog.metadata, {
      'sidebar.outline': const BusyMarkKeyBinding(LogicalKeyboardKey.f12),
      'view.source': null,
    });
    expect(custom.activators('sidebar.outline'), hasLength(1));
    expect(
      BusyMarkKeyBinding.fromActivator(
        custom.activators('sidebar.outline').single as SingleActivator,
      ),
      const BusyMarkKeyBinding(LogicalKeyboardKey.f12),
    );
    expect(custom.activators('view.source'), isEmpty);
    expect(custom['view.source']!.shortcut, isNull);
    expect(
      custom.blockedDefaultIntents({BusyMarkCommandScope.documentView}),
      contains(
        const SingleActivator(
          LogicalKeyboardKey.digit2,
          control: true,
          shift: true,
        ),
      ),
    );
  });
  test(
    'logical key serialization and GTK syntax do not depend on badge parsing',
    () {
      for (final key in [
        LogicalKeyboardKey.comma,
        LogicalKeyboardKey.f12,
        LogicalKeyboardKey.numpad7,
        const LogicalKeyboardKey(0xe9),
      ]) {
        final binding = BusyMarkKeyBinding(key, control: true, alt: true);
        expect(BusyMarkKeyBinding.fromJson(binding.toJson()), binding);
        expect(binding.gtkAccelerator, startsWith('<Primary><Alt>'));
      }
      expect(
        const BusyMarkKeyBinding(
          LogicalKeyboardKey.comma,
          control: true,
        ).gtkAccelerator,
        '<Primary>comma',
      );
      expect(
        const BusyMarkKeyBinding(
          LogicalKeyboardKey(0xe9),
          control: true,
        ).gtkAccelerator,
        '<Primary>U+00E9',
      );
      expect(
        const BusyMarkKeyBinding(
          LogicalKeyboardKey(0x26),
          control: true,
        ).gtkAccelerator,
        '<Primary>U+0026',
      );
      expect(
        BusyMarkKeyBinding.fromJson({
          'key': LogicalKeyboardKey.controlLeft.keyId,
        }),
        isNull,
      );
      expect(BusyMarkKeyBinding.fromJson({'key': 0x85}), isNull);
      final defaults = BusyMarkCommandCatalog.metadata;
      expect(
        shortcutAssignmentAllowed(
          defaults['file.save']!,
          const BusyMarkKeyBinding(LogicalKeyboardKey.keyA),
        ),
        isFalse,
      );
      expect(
        shortcutConfigurable(defaults['text.insertIndentation']!),
        isFalse,
      );
    },
  );

  test(
    'search destinations exclude ordinary Outline and History navigation',
    () {
      expect(searchCommandDestinations, {
        'search.find': SearchCategory.file,
        'search.workspace': SearchCategory.workspace,
        'search.headings': SearchCategory.outline,
        'workspace.quickOpen': SearchCategory.documents,
        'search.topics': SearchCategory.topics,
        'search.recent': SearchCategory.recent,
        'history.findLocal': SearchCategory.localHistory,
        'view.commandPalette': SearchCategory.actions,
      });
      expect(searchCommandDestinations.containsKey('sidebar.outline'), isFalse);
      expect(searchCommandDestinations.containsKey('history.local'), isFalse);
    },
  );
  test(
    'retired defaults block platform aliases while allowing explicit reassignment to a receiver',
    () {
      final defaults = BusyMarkCommandCatalog.metadata;
      final unassigned = effectiveCommandRegistry(defaults, {
        'text.paste': null,
      });
      final blocked = unassigned.blockedDefaultIntents({
        BusyMarkCommandScope.textEditing,
        BusyMarkCommandScope.editor,
      });
      expect(
        blocked,
        contains(const SingleActivator(LogicalKeyboardKey.keyV, control: true)),
      );
      expect(
        blocked,
        contains(const SingleActivator(LogicalKeyboardKey.insert, shift: true)),
      );
      expect(unassigned.activators('text.paste'), isEmpty);
      final reassigned = effectiveCommandRegistry(defaults, {
        'text.paste': null,
        'file.save': const BusyMarkKeyBinding(
          LogicalKeyboardKey.keyV,
          control: true,
        ),
      });
      expect(
        reassigned.blockedDefaultIntents({
          BusyMarkCommandScope.editor,
          BusyMarkCommandScope.textEditing,
        }),
        isNot(
          contains(
            const SingleActivator(LogicalKeyboardKey.keyV, control: true),
          ),
        ),
      );
      expect(reassigned['file.save']!.shortcut!.label, 'Ctrl+V');
    },
  );
  testWidgets(
    'disabled contextual shortcuts consume keys without executing a fallback action',
    (tester) async {
      var enabled = false, invoked = 0, fallthrough = 0;
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xff000000),
          builder: (_, child) => Shortcuts(
            shortcuts: const {
              SingleActivator(LogicalKeyboardKey.keyK, control: true):
                  ActivateIntent(),
            },
            child: Actions(
              actions: {
                ActivateIntent: CallbackAction<ActivateIntent>(
                  onInvoke: (_) {
                    fallthrough++;
                    return null;
                  },
                ),
              },
              child: BusyMarkCommandShortcuts(
                shortcuts: const {
                  SingleActivator(LogicalKeyboardKey.keyK, control: true):
                      BusyMarkContextCommandIntent('editor.bold'),
                },
                child: Actions(
                  actions: {
                    BusyMarkContextCommandIntent: BusyMarkContextCommandAction(
                      isCommandEnabled: (_) => enabled,
                      onCommand: (_) => invoked++,
                    ),
                  },
                  child: const Focus(autofocus: true, child: SizedBox()),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      Future<void> press() async {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pump();
      }

      await press();
      expect(invoked, 0);
      expect(fallthrough, 0);
      enabled = true;
      await press();
      expect(invoked, 1);
      expect(fallthrough, 0);
    },
  );
  test('document and workspace command targets are explicit', () {
    final registry = BusyMarkCommandCatalog.metadata;
    for (final id in [
      'search.find',
      'file.save',
      'file.export',
      'tabs.close',
      'sidebar.outline',
      'editor.bold',
    ]) {
      expect(
        registry.requiresDocumentTarget(registry[id]!),
        isTrue,
        reason: id,
      );
    }
    for (final id in [
      'history.local',
      'history.findLocal',
      'sidebar.files',
      'sidebar.git',
      'tabs.next',
      'tabs.closeAll',
      'notes.sync',
      'notes.export',
      'notes.importFolder',
      'notes.importFile',
    ]) {
      expect(
        registry.requiresWorkspaceTarget(registry[id]!),
        isTrue,
        reason: id,
      );
    }
    for (final id in [
      'notes.sync',
      'notes.export',
      'notes.importFolder',
      'notes.importFile',
    ]) {
      expect(registry[id], isNotNull);
      expect(registry[id]!.shortcut, isNull);
    }
    for (final id in [
      'history.local',
      'history.findLocal',
      'file.open',
      'file.newDocument',
      'notes.create',
      'help.keyboardShortcuts',
    ]) {
      expect(
        registry.requiresDocumentTarget(registry[id]!),
        isFalse,
        reason: id,
      );
    }
  });
  test('all agreed search shortcuts have no cross-scope collision', () {
    final registry = BusyMarkCommandCatalog.metadata;
    expect(registry['help.keyboardShortcuts'], isNotNull);
    expect(registry['help.keyboardShortcuts']!.shortcut, isNull);
    expect(registry.activators('help.keyboardShortcuts'), isEmpty);
    const expected = {
      'search.find': 'Ctrl+F',
      'search.workspace': 'Ctrl+Shift+F',
      'sidebar.outline': 'Ctrl+3',
      'workspace.quickOpen': 'Ctrl+P',
      'search.topics': 'Ctrl+Shift+T',
      'search.recent': 'Ctrl+Alt+O',
      'view.commandPalette': 'Ctrl+Shift+P',
      'search.headings': 'Ctrl+Alt+H',
      'history.findLocal': 'Ctrl+Alt+Y',
    };
    for (final entry in expected.entries) {
      expect(registry[entry.key]?.shortcut?.label, entry.value);
      final activator = registry[entry.key]!.shortcut!.activator;
      expect(
        registry.commands
            .where((c) => c.shortcut?.activator == activator)
            .map((c) => c.id),
        [entry.key],
      );
    }
    for (final id in [
      'writerside.insertProcedure',
      'writerside.insertTabs',
      'writerside.insertDefinitionList',
      'writerside.insertInclude',
      'writerside.insertVariable',
      'writerside.insertVideo',
      'writerside.insertTldr',
      'writerside.insertConvertListToProcedure',
      'writerside.tip',
      'writerside.note',
      'writerside.warning',
      'writerside.quote',
      'writerside.uiControl',
      'writerside.filePath',
      'writerside.uiPath',
      'writerside.shortcut',
    ]) {
      expect(registry[id]?.execute, isNotNull, reason: id);
    }
  });
  test('catalog includes every editor command with an executable callback', () {
    final registry = BusyMarkCommandCatalog.create();

    for (final action in BusyMarkEditorShortcutAction.values) {
      final command = registry['editor.${action.name}'];
      expect(command, isNotNull, reason: action.name);
      expect(command!.execute, isNotNull, reason: action.name);
    }
  });

  BusyMarkCommand command(
    String id, {
    BusyMarkShortcutDefinition? shortcut,
    BusyMarkCommandScope scope = BusyMarkCommandScope.application,
  }) {
    return BusyMarkCommand(
      id: id,
      label: (_) => id,
      category: (_) => 'Test',
      scope: scope,
      shortcut: shortcut,
    );
  }

  test('catalog exposes stable unique IDs for all migrated shortcuts', () {
    final registry = BusyMarkCommandCatalog.create();

    expect(registry.commands, isNotEmpty);
    expect(BusyMarkCommandIds.textPastePlainText, 'text.pastePlainText');
    final pastePlainText = registry[BusyMarkCommandIds.textPastePlainText];
    expect(pastePlainText, isNotNull);
    expect(pastePlainText?.scope, BusyMarkCommandScope.textEditing);
    expect(pastePlainText?.shortcut?.label, 'Ctrl+Shift+V');
    expect(pastePlainText?.execute, isNotNull);
    expect(registry[BusyMarkCommandIds.save]?.shortcut?.label, 'Ctrl+S');
    expect(
      registry[BusyMarkCommandIds.commandPalette]?.shortcut?.label,
      'Ctrl+Shift+P',
    );
    expect(BusyMarkCommandIds.syntaxReference, 'help.syntaxReference');
    expect(
      registry[BusyMarkCommandIds.syntaxReference]?.shortcut?.label,
      'Ctrl+Alt+M',
    );
    expect(
      registry[BusyMarkCommandIds.localHistory]?.shortcut?.label,
      'Ctrl+5',
    );
    expect(
      registry[BusyMarkCommandIds.clipboardHistory]?.shortcut?.label,
      'Ctrl+6',
    );
    expect(
      registry[BusyMarkCommandIds.localHistory]?.scope,
      BusyMarkCommandScope.application,
    );
    expect(
      registry[BusyMarkCommandIds.clipboardHistory]?.scope,
      BusyMarkCommandScope.application,
    );
    expect(
      registry.commands.map((command) => command.id).toSet().length,
      registry.commands.length,
    );
    expect(registry[BusyMarkCommandIds.editorRefineWithAi]?.execute, isNotNull);
    expect(
      registry[BusyMarkCommandIds.editorRefineWithAi]?.disabledReason,
      isNotNull,
    );
  });

  test('rejects duplicate command IDs', () {
    expect(
      () => BusyMarkCommandRegistry([
        command('test.duplicate'),
        command('test.duplicate'),
      ]),
      throwsA(isA<BusyMarkCommandRegistryValidationException>()),
    );
  });

  test('rejects shortcut conflicts in the same command scope', () {
    const shortcut = BusyMarkShortcutDefinition(
      label: 'Ctrl+J',
      activator: SingleActivator(LogicalKeyboardKey.keyJ, control: true),
    );

    expect(
      () => BusyMarkCommandRegistry([
        command('test.first', shortcut: shortcut),
        command('test.second', shortcut: shortcut),
      ]),
      throwsA(isA<BusyMarkCommandRegistryValidationException>()),
    );
  });

  test('allows the same shortcut in distinct focus scopes', () {
    const shortcut = BusyMarkShortcutDefinition(
      label: 'Ctrl+J',
      activator: SingleActivator(LogicalKeyboardKey.keyJ, control: true),
    );

    expect(
      () => BusyMarkCommandRegistry([
        command('test.first', shortcut: shortcut),
        command(
          'test.second',
          shortcut: shortcut,
          scope: BusyMarkCommandScope.editor,
        ),
      ]),
      returnsNormally,
    );
  });

  test('executes only visible enabled bound commands', () async {
    var calls = 0;
    final registry = BusyMarkCommandRegistry([
      BusyMarkCommand(
        id: 'test.run',
        label: (_) => 'Run',
        category: (_) => 'Test',
        scope: BusyMarkCommandScope.application,
        execute: () => calls++,
      ),
      BusyMarkCommand(
        id: 'test.disabled',
        label: (_) => 'Disabled',
        category: (_) => 'Test',
        scope: BusyMarkCommandScope.application,
        enabled: () => false,
        execute: () => calls++,
      ),
    ]);

    expect(await registry.execute('test.run'), isTrue);
    expect(await registry.execute('test.disabled'), isFalse);
    expect(await registry.execute('test.missing'), isFalse);
    expect(calls, 1);
  });

  testWidgets('contextual commands execute against the captured editor', (
    tester,
  ) async {
    final registry = BusyMarkCommandCatalog.create();
    var calls = 0;
    late BuildContext editorContext;
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Actions(
          actions: {
            BusyMarkContextCommandIntent: BusyMarkContextCommandAction(
              isCommandEnabled: (id) => id == 'editor.bold',
              onCommand: (_) => calls++,
            ),
          },
          child: Focus(
            focusNode: focusNode,
            child: Builder(
              builder: (context) {
                editorContext = context;
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );
    focusNode.requestFocus();
    await tester.pump();

    expect(registry.canExecuteInContext('editor.bold', editorContext), isTrue);
    expect(
      registry.canExecuteInContext('editor.italic', editorContext),
      isFalse,
    );
    expect(await registry.executeInContext('editor.bold', editorContext), true);
    expect(calls, 1);
  });
}
