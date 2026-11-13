// Headless production-widget diagnostic using official Flutter key simulation.
// This deliberately has no native menu plugin and is NOT GTK/OS acceptance.
// Build/run instructions: docs/development/view-selector-dispatch-investigation.md.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/core/debug_log.dart';
import 'package:busymark/src/app/app_router.dart';
import 'package:busymark/src/app/busymark_app.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/keyboard_shortcut_badge.dart';
import 'package:busymark/src/app/command_registry.dart';
import 'package:busymark/src/app/keymap_controller.dart';
import 'package:busymark/src/app/shortcut_binding.dart';
import 'package:busymark/src/app/startup_path.dart';
import 'package:busymark/src/app/system_accent.dart';
import 'package:busymark/src/workspace/workspace_controller.dart';

class _DiagnosticBinding extends WidgetsFlutterBinding
    with TestDefaultBinaryMessengerBinding {}

void log(String stage, Object? data) =>
    stdout.writeln(jsonEncode({'stage': stage, 'data': data}));
Future<void> pause([int ms = 400]) =>
    Future<void>.delayed(Duration(milliseconds: ms));
List<T> widgets<T extends Widget>() {
  final result = <T>[];
  void visit(Element e) {
    if (e.widget is T) result.add(e.widget as T);
    e.visitChildren(visit);
  }

  WidgetsBinding.instance.rootElement?.visitChildren(visit);
  return result;
}

Future<void> key(
  LogicalKeyboardKey logical,
  PhysicalKeyboardKey physical,
  ui.KeyEventType type,
) async {
  final handled = type == ui.KeyEventType.down
      ? await simulateKeyDownEvent(
          logical,
          physicalKey: physical,
          platform: 'linux',
        )
      : await simulateKeyUpEvent(
          logical,
          physicalKey: physical,
          platform: 'linux',
        );
  log('key', {'key': logical.keyLabel, 'type': type.name, 'handled': handled});
  await pause(30);
}

Future<void> chord(
  LogicalKeyboardKey logical,
  PhysicalKeyboardKey physical,
) async {
  await key(
    LogicalKeyboardKey.controlLeft,
    PhysicalKeyboardKey.controlLeft,
    ui.KeyEventType.down,
  );
  await key(
    LogicalKeyboardKey.shiftLeft,
    PhysicalKeyboardKey.shiftLeft,
    ui.KeyEventType.down,
  );
  await key(logical, physical, ui.KeyEventType.down);
  await key(logical, physical, ui.KeyEventType.up);
  await key(
    LogicalKeyboardKey.shiftLeft,
    PhysicalKeyboardKey.shiftLeft,
    ui.KeyEventType.up,
  );
  await key(
    LogicalKeyboardKey.controlLeft,
    PhysicalKeyboardKey.controlLeft,
    ui.KeyEventType.up,
  );
  await pause();
}

void require(bool condition, String message) {
  if (!condition) throw StateError(message);
}

Future<void> waitFor(bool Function() condition) async {
  for (var i = 0; i < 100; i++) {
    if (condition()) return;
    await pause(50);
  }
  throw StateError('Diagnostic condition timed out');
}

Future<void> main() async {
  require(
    Platform.environment['XDG_DATA_HOME']?.contains('selector-dispatch') ==
        true,
    'Use an isolated XDG_DATA_HOME as documented; never run against the desktop profile.',
  );
  log(
    'qualification',
    'Headless simulated keys only; native acceptance is still required.',
  );
  Timer(const Duration(seconds: 60), () => exit(2));
  debugBusyMarkLogging = true;
  _DiagnosticBinding();
  final root = Directory.systemTemp.createTempSync('bm-clean-dispatch-probe-');
  final file = File('${root.path}/document.md')
    ..writeAsStringSync('# Diagnostic\n\nContent.\n');
  final store = JsonFileLocalSettingsStore(
    settingsFilePathOverride: '${root.path}/profile/settings.json',
  );
  await store.save(
    AppSettings.defaults()
        .copyWith(
          autoSave: false,
          documentViewMode: DocumentViewModePreference.source,
        )
        .toJson(),
  );
  final startup = await StartupAppSettings.load(store);
  final container = ProviderContainer(
    overrides: [
      linuxAccentPlatformProvider.overrideWithValue(false),
      localSettingsStoreProvider.overrideWithValue(store),
      appSettingsControllerProvider.overrideWith(
        () => AppSettingsController(startupSettings: startup),
      ),
      startupPathProvider.overrideWithValue(file.path),
    ],
  );
  container.listen(
    workspaceNavigationCommandProvider,
    (_, next) => log('workspace-request', next?.$1),
  );
  runApp(
    UncontrolledProviderScope(container: container, child: const BusyMarkApp()),
  );
  for (var i = 0; i < 40; i++) {
    await pause(100);
    if (container.read(workspaceControllerProvider).activeBuffer != null) break;
  }
  await pause();
  final registry = container.read(busyMarkCommandRegistryProvider);
  log('workspace', {
    'active': container.read(workspaceControllerProvider).activeBuffer != null,
  });
  log('bindings', {
    for (final id in [
      BusyMarkCommandIds.sidebarViewSelector,
      BusyMarkCommandIds.contentViewSelector,
    ])
      id: {
        'binding': registry[id]?.shortcut?.label,
        'enabled': registry[id]?.canExecute,
      },
  });
  log(
    'menus',
    widgets<BusyMarkHeaderPopupMenuButton>()
        .map((w) => {'tooltip': w.tooltip, 'controller': w.controller != null})
        .toList(),
  );
  await chord(LogicalKeyboardKey.f9, PhysicalKeyboardKey.f9);
  log('after-sidebar', {
    'toastTexts': widgets<Text>()
        .map((w) => w.data)
        .whereType<String>()
        .where((s) => s.toLowerCase().contains('menu'))
        .toList(),
  });
  for (final choice in [
    (
      LogicalKeyboardKey.keyE,
      PhysicalKeyboardKey.keyE,
      DocumentViewModePreference.editor,
    ),
    (
      LogicalKeyboardKey.keyS,
      PhysicalKeyboardKey.keyS,
      DocumentViewModePreference.source,
    ),
    (
      LogicalKeyboardKey.keyR,
      PhysicalKeyboardKey.keyR,
      DocumentViewModePreference.preview,
    ),
    (
      LogicalKeyboardKey.keyD,
      PhysicalKeyboardKey.keyD,
      DocumentViewModePreference.split,
    ),
  ]) {
    await chord(LogicalKeyboardKey.f10, PhysicalKeyboardKey.f10);
    final labels = widgets<BusyMarkPopupMenuItem>()
        .map((w) => w.label)
        .toList();
    log('after-content', {'items': labels});
    require(
      labels.join(',') == 'Editor,Source,Reading,Dual',
      'Wrong Content selector or context-menu conflict',
    );
    await key(choice.$1, choice.$2, ui.KeyEventType.down);
    await key(choice.$1, choice.$2, ui.KeyEventType.up);
    await pause();
    final actual = container
        .read(appSettingsControllerProvider)
        .documentViewMode;
    log('after-mnemonic', {
      'key': choice.$1.keyLabel,
      'view': actual.name,
      'text': container.read(workspaceControllerProvider).activeText,
    });
    if (actual != choice.$3) {
      throw StateError('Content mnemonic failed: ${choice.$1.keyLabel}');
    }
  }
  final source = widgets<TextField>().firstWhere(
    (w) =>
        (w.controller?.text.startsWith('# Diagnostic') ?? false) &&
        w.focusNode?.canRequestFocus == true,
  );
  source.focusNode?.requestFocus();
  await pause();
  log('source-focus', {
    'hasFocus': source.focusNode?.hasFocus,
    'primary': FocusManager.instance.primaryFocus?.debugLabel,
  });
  await key(
    LogicalKeyboardKey.shiftLeft,
    PhysicalKeyboardKey.shiftLeft,
    ui.KeyEventType.down,
  );
  await key(
    LogicalKeyboardKey.f10,
    PhysicalKeyboardKey.f10,
    ui.KeyEventType.down,
  );
  await key(
    LogicalKeyboardKey.f10,
    PhysicalKeyboardKey.f10,
    ui.KeyEventType.up,
  );
  await key(
    LogicalKeyboardKey.shiftLeft,
    PhysicalKeyboardKey.shiftLeft,
    ui.KeyEventType.up,
  );
  await waitFor(
    () => widgets<BusyMarkPopupMenuItem>().any((w) => w.label == 'Select all'),
  );
  log(
    'shift-f10-context',
    widgets<BusyMarkPopupMenuItem>().map((w) => w.label).toList(),
  );
  await key(
    LogicalKeyboardKey.escape,
    PhysicalKeyboardKey.escape,
    ui.KeyEventType.down,
  );
  await key(
    LogicalKeyboardKey.escape,
    PhysicalKeyboardKey.escape,
    ui.KeyEventType.up,
  );
  await pause();
  require(
    source.focusNode?.hasFocus == true,
    'Shift+F10 dismissal lost source focus',
  );
  await chord(LogicalKeyboardKey.f10, PhysicalKeyboardKey.f10);
  require(
    widgets<BusyMarkPopupMenuItem>().map((w) => w.label).join(',') ==
        'Editor,Source,Reading,Dual',
    'Ctrl+Shift+F10 opened a text context menu',
  );
  await key(
    LogicalKeyboardKey.escape,
    PhysicalKeyboardKey.escape,
    ui.KeyEventType.down,
  );
  await key(
    LogicalKeyboardKey.escape,
    PhysicalKeyboardKey.escape,
    ui.KeyEventType.up,
  );
  await pause();
  require(
    source.focusNode?.hasFocus == true,
    'Content selector dismissal lost source focus',
  );
  await key(
    LogicalKeyboardKey.contextMenu,
    PhysicalKeyboardKey.contextMenu,
    ui.KeyEventType.down,
  );
  await key(
    LogicalKeyboardKey.contextMenu,
    PhysicalKeyboardKey.contextMenu,
    ui.KeyEventType.up,
  );
  await waitFor(
    () => widgets<BusyMarkPopupMenuItem>().any((w) => w.label == 'Select all'),
  );
  log(
    'menu-key-context',
    widgets<BusyMarkPopupMenuItem>().map((w) => w.label).toList(),
  );
  await key(
    LogicalKeyboardKey.escape,
    PhysicalKeyboardKey.escape,
    ui.KeyEventType.down,
  );
  await key(
    LogicalKeyboardKey.escape,
    PhysicalKeyboardKey.escape,
    ui.KeyEventType.up,
  );
  await pause();
  require(
    source.focusNode?.hasFocus == true,
    'Menu-key dismissal lost source focus',
  );
  container
      .read(appRouterProvider)
      .go('/settings?returnTo=workspace&page=keyboardShortcuts');
  await pause();
  Future<Map<String, String>> readBadges() async {
    ScrollableState? settingsScroll;
    void resetScroll(Element e) {
      if (e is StatefulElement && e.state is ScrollableState) {
        final candidate = e.state as ScrollableState;
        if (candidate.position.hasContentDimensions &&
            (settingsScroll == null ||
                candidate.position.maxScrollExtent >
                    settingsScroll!.position.maxScrollExtent)) {
          settingsScroll = candidate;
        }
      }
      e.visitChildren(resetScroll);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(resetScroll);
    settingsScroll?.position.jumpTo(0);
    await pause(100);
    final badges = <String, String>{};
    for (var i = 0; i < 60; i++) {
      for (final row in widgets<BusyMarkActionRow>()) {
        final rowKey = row.key;
        if (rowKey is ValueKey<String> &&
            [
              'shortcut-edit-view.sidebarSelector',
              'shortcut-edit-view.contentSelector',
              'shortcut-edit-view.editor',
              'shortcut-edit-sidebar.files',
            ].contains(rowKey.value)) {
          final trailing = row.trailing;
          if (trailing is ConstrainedBox &&
              trailing.child is BusyMarkKeyboardShortcutBadge) {
            badges[rowKey.value] =
                (trailing.child as BusyMarkKeyboardShortcutBadge).label;
          }
        }
      }
      if (badges.length == 4) break;
      ScrollableState? scroll;
      void find(Element e) {
        if (e is StatefulElement && e.state is ScrollableState) {
          final candidate = e.state as ScrollableState;
          if (candidate.position.hasContentDimensions &&
              (scroll == null ||
                  candidate.position.maxScrollExtent >
                      scroll!.position.maxScrollExtent)) {
            scroll = candidate;
          }
        }
        e.visitChildren(find);
      }

      WidgetsBinding.instance.rootElement?.visitChildren(find);
      if (scroll == null) break;
      final position = scroll!.position;
      position.jumpTo(
        (position.pixels + 400).clamp(0, position.maxScrollExtent),
      );
      await pause(100);
    }
    return badges;
  }

  final badges = await readBadges();
  log('settings-badges', badges);
  require(
    badges['shortcut-edit-view.sidebarSelector'] == 'Ctrl+Shift+F9',
    'Sidebar Settings badge incorrect',
  );
  require(
    badges['shortcut-edit-view.contentSelector'] == 'Ctrl+Shift+F10',
    'Content Settings badge incorrect',
  );
  final keymap = container.read(keymapControllerProvider.notifier);
  for (final assignment in [
    (BusyMarkCommandIds.save, const BusyMarkKeyBinding(LogicalKeyboardKey.f12)),
    (
      BusyMarkCommandIds.sidebarViewSelector,
      const BusyMarkKeyBinding(LogicalKeyboardKey.f6),
    ),
    (
      BusyMarkCommandIds.contentViewSelector,
      const BusyMarkKeyBinding(LogicalKeyboardKey.f8),
    ),
  ]) {
    final result = await keymap.update(
      assignment.$1,
      assignment.$2,
      expected: container.read(appSettingsControllerProvider).shortcutOverrides,
    );
    require(
      result.status == KeymapUpdateStatus.saved,
      'Could not save isolated shortcut override',
    );
  }
  await pause();
  final remapped = await readBadges();
  log('settings-remapped', remapped);
  require(
    remapped['shortcut-edit-view.sidebarSelector'] == 'F6',
    'Sidebar custom binding absent',
  );
  require(
    remapped['shortcut-edit-view.contentSelector'] == 'F8',
    'Content custom binding absent',
  );
  final clear = await keymap.update(
    BusyMarkCommandIds.contentViewSelector,
    null,
    expected: container.read(appSettingsControllerProvider).shortcutOverrides,
  );
  require(
    clear.status == KeymapUpdateStatus.saved,
    'Could not save explicit null override',
  );
  await pause();
  final unassigned = await readBadges();
  log('settings-explicit-null', unassigned);
  require(
    unassigned['shortcut-edit-view.contentSelector'] == 'Unassigned',
    'Explicit null must remain unassigned',
  );
  require(
    unassigned['shortcut-edit-view.sidebarSelector'] == 'F6',
    'Other selector override was reset',
  );
  require(
    container
            .read(busyMarkCommandRegistryProvider)[BusyMarkCommandIds.save]
            ?.shortcut
            ?.label ==
        'F12',
    'Unrelated Save override was reset',
  );
  require(
    container.read(workspaceControllerProvider).activeText ==
        '# Diagnostic\n\nContent.\n',
    'Mnemonic changed the document',
  );
  log(
    'result',
    'PASS: headless dispatch, content mnemonics, text contexts, focus and effective Settings; native acceptance untested.',
  );
  exit(0);
}
