import 'dart:convert';
import 'dart:io';

import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/busymark_glyphs.dart';
import 'package:busymark/src/app/command_registry.dart';
import 'package:busymark/src/app/keymap_controller.dart';
import 'package:busymark/src/app/shortcut_binding.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaru/yaru.dart';

import '../support/native_menu_probe.dart';

const _sidebar = {
  'F': 'Files',
  'T': 'Table of Contents',
  'O': 'Outline',
  'C': 'Commit',
  'G': 'Git Log',
  'L': 'Local History',
  'B': 'Clipboard History',
  'R': 'References',
};
const _content = {'E': 'Editor', 'S': 'Source', 'R': 'Reading', 'D': 'Dual'};

Widget _harness({
  required Widget menu,
  required TextEditingController text,
  required FocusNode focus,
}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: Column(
      children: [
        TextField(controller: text, focusNode: focus, autofocus: true),
        menu,
      ],
    ),
  ),
);

void main() {
  test('selectors own exact combinations and retire every numeric default', () {
    final commands = BusyMarkCommandCatalog.metadata;
    for (final id in [
      'view.editor',
      'view.source',
      'view.reading',
      'view.split',
      'sidebar.files',
      'sidebar.toc',
      'sidebar.outline',
      'sidebar.git',
      'history.local',
      'sidebar.clipboardHistory',
    ]) {
      expect(commands.activators(id), isEmpty, reason: id);
    }
    for (final binding in [
      const BusyMarkKeyBinding(LogicalKeyboardKey.f9),
      const BusyMarkKeyBinding(
        LogicalKeyboardKey.f9,
        control: true,
        shift: true,
      ),
      const BusyMarkKeyBinding(
        LogicalKeyboardKey.f10,
        control: true,
        shift: true,
      ),
    ]) {
      final owners = commands.commands
          .where((c) => defaultBinding(c) == binding)
          .toList();
      expect(owners, hasLength(1));
      expect(commands.conflicts(owners.single.id, binding), isEmpty);
    }
    expect(
      commands[BusyMarkCommandIds.commandPalette]!.shortcut!.label,
      'Ctrl+Shift+P',
    );
    expect(
      commands.commands.where((c) => c.scope == BusyMarkCommandScope.git),
      isEmpty,
    );
  });

  for (final entries in [_sidebar, _content]) {
    for (final entry in entries.entries) {
      testWidgets(
        '${entries == _sidebar ? 'sidebar' : 'content'} ${entry.key} immediately selects ${entry.value} after reordering',
        (tester) async {
          final text = TextEditingController(text: 'Document unchanged');
          final focus = FocusNode();
          final controller = BusyMarkHeaderMenuController();
          addTearDown(text.dispose);
          addTearDown(focus.dispose);
          addTearDown(controller.dispose);
          String? selected;
          await tester.pumpWidget(
            _harness(
              text: text,
              focus: focus,
              menu: BusyMarkHeaderPopupMenuButton<String>(
                controller: controller,
                tooltip: 'Views',
                icon: BusyMarkGlyphs.sidebarViews,
                itemBuilder: (_) => [
                  for (final item in entries.entries.toList().reversed)
                    BusyMarkPopupMenuItem(
                      value: item.value,
                      label: item.value,
                      mnemonic: item.key,
                      shortcut: item.key,
                    ),
                ],
                onSelected: (value) => selected = value,
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(focus.hasFocus, isTrue);
          controller.open();
          await tester.pumpAndSettle();
          expect(focus.hasFocus, isFalse);
          await tester.sendKeyEvent(
            LogicalKeyboardKey.findKeyByKeyId(
              entry.key.toLowerCase().codeUnitAt(0),
            )!,
          );
          await tester.pumpAndSettle();
          expect(selected, entry.value);
          expect(text.text, 'Document unchanged');
          expect(focus.hasFocus, isTrue);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'unavailable mnemonic stays local; arrows, Enter and Escape retain focus',
    (tester) async {
      final text = TextEditingController(text: 'Untouched');
      final focus = FocusNode();
      final controller = BusyMarkHeaderMenuController();
      addTearDown(text.dispose);
      addTearDown(focus.dispose);
      addTearDown(controller.dispose);
      String? selected;
      await tester.pumpWidget(
        _harness(
          text: text,
          focus: focus,
          menu: BusyMarkHeaderPopupMenuButton<String>(
            controller: controller,
            tooltip: 'Views',
            icon: BusyMarkGlyphs.sidebarViews,
            itemBuilder: (_) => [
              BusyMarkPopupMenuItem(
                value: 'toc',
                label: 'Table of Contents',
                mnemonic: 'T',
                enabled: false,
              ),
              BusyMarkPopupMenuItem(
                value: 'files',
                label: 'Files',
                mnemonic: 'F',
              ),
              BusyMarkPopupMenuItem(
                value: 'outline',
                label: 'Outline',
                mnemonic: 'O',
              ),
            ],
            onSelected: (value) => selected = value,
          ),
        ),
      );
      await tester.pumpAndSettle();
      controller.open();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
      await tester.pumpAndSettle();
      expect(selected, isNull);
      expect(find.text('Table of Contents'), findsOneWidget);
      expect(text.text, 'Untouched');
      expect(focus.hasFocus, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        selected,
        'outline',
        reason: 'Down advances from the initially focused enabled Files row',
      );
      expect(focus.hasFocus, isTrue);
      controller.open();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(focus.hasFocus, isTrue);
      expect(text.text, 'Untouched');
    },
  );

  testWidgets(
    'native selector waits for its trigger releases with Num Lock pressed',
    (tester) async {
      final probe = NativeMenuProbe(tester);
      final controller = BusyMarkHeaderMenuController();
      final text = TextEditingController();
      final focus = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(text.dispose);
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        _harness(
          text: text,
          focus: focus,
          menu: BusyMarkHeaderPopupMenuButton<String>.native(
            controller: controller,
            tooltip: 'Sidebar view',
            shortcut: 'F8',
            icon: BusyMarkGlyphs.sidebarViews,
            itemBuilder: (_) => [
              for (final e in _sidebar.entries)
                BusyMarkPopupMenuItem(
                  value: e.value,
                  label: e.value,
                  mnemonic: e.key,
                  shortcut: e.key,
                  enabled: e.key != 'T',
                ),
            ],
            onSelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      // The desktop's Linux keyboard state can report Num Lock as pressed
      // while its lock is enabled. It is unrelated to the opening shortcut.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.numLock);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.f9);
      controller.open(
        shortcuts: const [
          SingleActivator(LogicalKeyboardKey.f9, control: true, shift: true),
        ],
      );
      await tester.pump();
      expect(probe.isOpen, isFalse);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.f9);
      await tester.pump();
      expect(probe.isOpen, isFalse);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      expect(probe.isOpen, isFalse);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(probe.isOpen, isTrue);
      expect(probe.packets.last['focusFirst'], isTrue);
      expect({
        for (final e in probe.entries) e['mnemonic']: e['label'],
      }, _sidebar);
      expect(probe.enabled('Table of Contents'), isFalse);
      expect(find.byTooltip('Sidebar view (F8)'), findsOneWidget);
      expect(BusyMarkGlyphs.sidebarViews, YaruIcons.display_layout);
      probe.close();
      await tester.pumpAndSettle();
      expect(focus.hasFocus, isTrue);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.numLock);
    },
  );

  for (final id in [
    BusyMarkCommandIds.sidebarViewSelector,
    BusyMarkCommandIds.contentViewSelector,
  ]) {
    testWidgets('$id release barrier follows the configured binding', (
      tester,
    ) async {
      const binding = BusyMarkKeyBinding(
        LogicalKeyboardKey.f8,
        alt: true,
        shift: true,
      );
      final commands = BusyMarkCommandCatalog.metadata.withOverrides({
        id: binding,
      });
      final controller = BusyMarkHeaderMenuController();
      final probe = NativeMenuProbe(tester);
      final text = TextEditingController(text: 'Unchanged');
      final focus = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(text.dispose);
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        _harness(
          text: text,
          focus: focus,
          menu: BusyMarkHeaderPopupMenuButton<String>.native(
            controller: controller,
            tooltip: 'Views',
            shortcut: commands[id]!.shortcut!.label,
            icon: BusyMarkGlyphs.sidebarViews,
            itemBuilder: (_) => [
              BusyMarkPopupMenuItem(value: 'source', label: 'Source'),
            ],
            onSelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.numLock);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altRight);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftRight);
      await tester.sendKeyDownEvent(binding.key);
      controller.open(shortcuts: commands.activators(id));
      await tester.pump();
      expect(probe.isOpen, isFalse);
      await tester.sendKeyUpEvent(binding.key);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altRight);
      await tester.pump();
      expect(probe.isOpen, isFalse, reason: 'Right Shift is still held');
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftRight);
      await tester.pumpAndSettle();
      expect(probe.isOpen, isTrue, reason: 'Unrelated keys must not block');
      expect(
        HardwareKeyboard.instance.physicalKeysPressed,
        containsAll([PhysicalKeyboardKey.numLock, PhysicalKeyboardKey.keyA]),
      );
      expect(find.byTooltip('Views (Alt+Shift+F8)'), findsOneWidget);
      probe.close();
      await tester.pumpAndSettle();
      expect(focus.hasFocus, isTrue);
      expect(text.text, 'Unchanged');
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.numLock);
    });
  }

  testWidgets('Linux context-menu keys exclude Ctrl+Shift+F10', (tester) async {
    final keys = BusyMarkContextMenuKeys();
    var opened = 0;
    const event = KeyDownEvent(
      physicalKey: PhysicalKeyboardKey.f10,
      logicalKey: LogicalKeyboardKey.f10,
      timeStamp: Duration.zero,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Focus(
          autofocus: true,
          onKeyEvent: (_, event) => keys.handle(event, () => opened++)
              ? KeyEventResult.handled
              : KeyEventResult.ignored,
          child: const SizedBox(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    expect(isBusyMarkContextMenuKeyEvent(event), isTrue);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.f10);
    expect(opened, 0);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.f10);
    expect(opened, 0, reason: 'GTK must wait for Shift release');
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    expect(opened, 1);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    expect(isBusyMarkContextMenuKeyEvent(event), isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.f10);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(opened, 1, reason: 'Ctrl+Shift+F10 never opens a context menu');
    const menu = KeyDownEvent(
      physicalKey: PhysicalKeyboardKey.contextMenu,
      logicalKey: LogicalKeyboardKey.contextMenu,
      timeStamp: Duration.zero,
    );
    expect(isBusyMarkContextMenuKeyEvent(menu), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
    expect(opened, 2);
  });

  test(
    'every localization exposes selector labels and the renamed Dual view',
    () async {
      for (final locale in AppLocalizations.supportedLocales) {
        final l10n = await AppLocalizations.delegate.load(locale);
        final tag = locale.toString();
        final arb =
            jsonDecode(File('lib/l10n/app_$tag.arb').readAsStringSync()) as Map;
        expect(l10n.split, arb['split']);
        expect(l10n.contentViewMenu, arb['contentViewMenu']);
        expect(l10n.sidebarViewMenu, arb['sidebarViewMenu']);
        expect(l10n.contentViewMenu, isNotEmpty);
        expect(l10n.sidebarViewMenu, isNotEmpty);
        if (locale.languageCode == 'en') {
          expect(l10n.split, 'Dual');
          expect(l10n.contentViewMenu, 'Content view');
          expect(l10n.sidebarViewMenu, 'Sidebar view');
          expect(l10n.showSidebar, 'Show sidebar');
          expect(l10n.hideSidebar, 'Hide sidebar');
        }
      }
    },
  );
}
