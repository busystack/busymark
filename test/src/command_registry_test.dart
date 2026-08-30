import 'package:busymark/src/app/command_registry.dart';
import 'package:busymark/src/app/busymark_shortcuts.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
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
