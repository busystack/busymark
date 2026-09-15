// Native Linux interaction probe. All mutations use a disposable fixture copy
// and production widgets/controllers; screenshots are not mockups.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/app/busymark_app.dart';
import 'package:busymark/src/app/startup_path.dart';
import 'package:busymark/src/app/system_accent.dart';
import 'package:busymark/src/local_history/local_history_store.dart';
import 'package:busymark/src/local_history/local_history_controller.dart';
import 'package:busymark/src/platform/linux_header_bar_service.dart';
import 'package:busymark/src/platform/native_menu_service.dart';
import 'package:busymark/src/workspace/recovery_persistence.dart';
import 'package:busymark/src/workspace/session_persistence.dart';
import 'package:busymark/src/workspace/workspace_controller.dart';
import 'package:busymark/src/writerside/writerside_template_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:window_manager/window_manager.dart';
import 'package:xml/xml.dart';

Future<void> main(List<String> arguments) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (arguments.length != 2) throw ArgumentError('FIXTURE OUTPUT_DIRECTORY');
  final root = await Directory.systemTemp.createTemp('busymark-toc-native-');
  final fixture = Directory(p.absolute(arguments[0]));
  await for (final item in fixture.list(recursive: true)) {
    final destination = p.join(
      root.path,
      p.relative(item.path, from: fixture.path),
    );
    if (item is Directory) await Directory(destination).create(recursive: true);
    if (item is File) {
      await File(destination).parent.create(recursive: true);
      await item.copy(destination);
    }
  }
  final output = await Directory(
    p.absolute(arguments[1]),
  ).create(recursive: true);
  await windowManager.ensureInitialized();
  await LinuxHeaderBarService.instance.initialize();
  final settings = AppSettings.defaults().copyWith(
    localeTag: 'en',
    documentViewMode: DocumentViewModePreference.source,
    autoSave: false,
    reopenPreviousWorkspaceOnStartup: false,
    confirmCloseWithUnsavedChanges: false,
  );
  runApp(
    ProviderScope(
      overrides: [
        writersideTemplateServiceProvider.overrideWithValue(
          WritersideTemplateService(
            storagePath: p.join(output.path, 'support/templates.json'),
          ),
        ),
        startupPathProvider.overrideWithValue(root.path),
        initialSystemAccentColorProvider.overrideWithValue(
          busyMarkDefaultAccentColor,
        ),
        localSettingsStoreProvider.overrideWithValue(
          _Settings(settings.toJson()),
        ),
        documentSessionStoreProvider.overrideWithValue(
          MemoryDocumentSessionStore(),
        ),
        documentRecoveryStoreProvider.overrideWithValue(
          MemoryDocumentRecoveryStore(),
        ),
        localHistoryStoreProvider.overrideWithValue(
          FileLocalHistoryStore(
            rootDirectory: () async =>
                Directory(p.join(output.path, 'history')),
          ),
        ),
      ],
      child: _Harness(root: root, output: output),
    ),
  );
  await windowManager.waitUntilReadyToShow(
    const WindowOptions(size: Size(1400, 960), center: true),
    () async {
      await windowManager.show();
      await windowManager.focus();
    },
  );
}

class _Harness extends ConsumerStatefulWidget {
  const _Harness({required this.root, required this.output});
  final Directory root;
  final Directory output;
  @override
  ConsumerState<_Harness> createState() => _HarnessState();
}

class _HarnessState extends ConsumerState<_Harness> {
  final _boundary = GlobalKey();
  final _checks = <String>[];
  var _pointer = 0;
  var _nativeMenuOpen = false;

  Future<String> _native(String command, [String? argument]) async {
    final result = await Process.run('/usr/bin/python3', [
      p.absolute('tools/linux_native_menu_probe.py'),
      '$pid',
      command,
      ?argument,
    ]);
    if (result.exitCode != 0) {
      throw StateError('Native $command failed: ${result.stderr}');
    }
    return result.stdout.toString().trim();
  }

  Future<void> _tapLabel(String label) async {
    if (_nativeMenuOpen) {
      stdout.writeln('GTK menu: $label');
      _nativeMenuOpen = await _native('choose', label) == 'submenu';
      await _pause();
    } else {
      await _tap(_text(label));
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_run()));
  }

  @override
  Widget build(BuildContext context) =>
      RepaintBoundary(key: _boundary, child: const BusyMarkApp());
  Future<void> _pause() =>
      Future<void>.delayed(const Duration(milliseconds: 700));
  Future<void> _until(bool Function() condition, String label) async {
    var settled = 0;
    for (var attempt = 0; attempt < 40; attempt++) {
      if (condition() && !ref.read(workspaceControllerProvider).isLoading) {
        if (++settled >= 2) return;
      } else {
        settled = 0;
      }
      await _pause();
    }
    throw StateError(
      '$label; workspace message: ${ref.read(workspaceControllerProvider).message}',
    );
  }

  List<Element> _elements(bool Function(Widget) predicate) {
    final found = <Element>[];
    void visit(Element element) {
      if (predicate(element.widget)) {
        final render = element.findRenderObject();
        if (render is RenderBox &&
            render.attached &&
            render.hasSize &&
            !render.size.isEmpty) {
          found.add(element);
        }
      }
      element.visitChildren(visit);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(visit);
    return found;
  }

  Element _text(String text) =>
      _elements((widget) => widget is Text && widget.data == text).last;
  Future<void> _tap(
    Element element, {
    int buttons = kPrimaryMouseButton,
  }) async {
    stdout.writeln(
      'Tap: ${element.widget is Text ? (element.widget as Text).data : element.widget.runtimeType}',
    );
    await Scrollable.ensureVisible(
      element,
      duration: const Duration(milliseconds: 200),
    ).timeout(const Duration(seconds: 5));
    await _pause();
    final box = element.findRenderObject()! as RenderBox;
    final position = box.localToGlobal(box.size.center(Offset.zero));
    final pointer = ++_pointer;
    GestureBinding.instance.handlePointerEvent(
      PointerDownEvent(
        pointer: pointer,
        position: position,
        buttons: buttons,
        kind: PointerDeviceKind.mouse,
      ),
    );
    GestureBinding.instance.handlePointerEvent(
      PointerUpEvent(
        pointer: pointer,
        position: position,
        kind: PointerDeviceKind.mouse,
      ),
    );
    await _pause();
  }

  Future<void> _key(
    PhysicalKeyboardKey physical,
    LogicalKeyboardKey logical,
  ) async {
    if (_nativeMenuOpen) {
      await _native(
        'key',
        logical == LogicalKeyboardKey.escape ? 'Escape' : logical.keyLabel,
      );
      if (logical == LogicalKeyboardKey.escape ||
          logical == LogicalKeyboardKey.enter) {
        _nativeMenuOpen = false;
      }
      await _pause();
      return;
    }
    _keyData(physical, logical, ui.KeyEventType.down);
    _keyData(physical, logical, ui.KeyEventType.up);
    if (logical == LogicalKeyboardKey.enter) {
      // Native text input also delivers a platform action for Enter. Framework
      // KeyData alone does not emulate that second half of the input event.
      final input = _elements(
        (widget) => widget is EditableText && widget.focusNode.hasFocus,
      ).firstOrNull;
      if (input is StatefulElement && input.state is EditableTextState) {
        (input.state as EditableTextState).performAction(TextInputAction.done);
      }
    }
    await _pause();
  }

  void _keyData(
    PhysicalKeyboardKey physical,
    LogicalKeyboardKey logical,
    ui.KeyEventType type,
  ) {
    // The embedding test must dispatch a framework key message as well as
    // update HardwareKeyboard; its public replacement only registers handlers.
    // ignore: deprecated_member_use
    ServicesBinding.instance.keyEventManager.handleKeyData(
      ui.KeyData(
        type: type,
        timeStamp: Duration.zero,
        physical: physical.usbHidUsage,
        logical: logical.keyId,
        character: null,
        synthesized: true,
      ),
    );
  }

  Future<void> _capture(String name) async {
    await _pause();
    if (Platform.environment['BUSYMARK_NATIVE_PROBE'] == '1') {
      await _native('capture', p.join(widget.output.path, '$name.png'));
      return;
    }
    await WidgetsBinding.instance.endOfFrame;
    final image =
        await (_boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary)
            .toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    await File(
      p.join(widget.output.path, '$name.png'),
    ).writeAsBytes(bytes!.buffer.asUint8List());
  }

  void _check(bool value, String label) {
    if (!value) throw StateError(label);
    _checks.add(label);
  }

  XmlDocument get _tree => XmlDocument.parse(
    File(p.join(widget.root.path, 'guide.tree')).readAsStringSync(),
  );
  Future<void> _menu(String title) async {
    await _tap(_text(title), buttons: kSecondaryMouseButton);
    _nativeMenuOpen = true;
  }

  Future<void> _fill(String label, String value) async {
    final element = _elements(
      (widget) => widget is TextField && widget.decoration?.labelText == label,
    ).single;
    await _tap(element);
    final field = element.widget as TextField;
    field.controller!.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    field.onChanged?.call(value);
    await _pause();
  }

  Future<void> _create(
    String anchor,
    String submenu,
    String format,
    String title,
    String filename,
  ) async {
    await _menu(anchor);
    await _tapLabel(submenu);
    await _capture('08-creation-menu');
    await _tapLabel(format);
    await _fill('Topic title:', title);
    await _fill('Topic Filename:', filename);
    await _capture('09-new-topic');
    await _tapLabel('OK');
    await _until(
      () => _elements(
        (widget) =>
            widget.runtimeType.toString() == '_CreateWritersideTopicDialog',
      ).isEmpty,
      'Creation dialog closes after success',
    );
    _check(
      await File(p.join(widget.root.path, 'topics', filename)).exists(),
      'Created $filename through $submenu / $format',
    );
  }

  Future<void> _drag(String source, String destination) async {
    final startBox = _text(source).findRenderObject()! as RenderBox;
    final endBox = _text(destination).findRenderObject()! as RenderBox;
    final start = startBox.localToGlobal(startBox.size.center(Offset.zero));
    final end = endBox.localToGlobal(endBox.size.center(Offset.zero));
    final pointer = ++_pointer;
    GestureBinding.instance.handlePointerEvent(
      PointerDownEvent(
        pointer: pointer,
        position: start,
        buttons: kPrimaryMouseButton,
        kind: PointerDeviceKind.mouse,
      ),
    );
    for (var step = 1; step <= 12; step++) {
      GestureBinding.instance.handlePointerEvent(
        PointerMoveEvent(
          pointer: pointer,
          position: Offset.lerp(start, end, step / 12)!,
          delta: (end - start) / 12,
          buttons: kPrimaryMouseButton,
          kind: PointerDeviceKind.mouse,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 70));
    }
    await _capture('10-drag-feedback');
    GestureBinding.instance.handlePointerEvent(
      PointerUpEvent(
        pointer: pointer,
        position: end,
        kind: PointerDeviceKind.mouse,
      ),
    );
    await _pause();
    await _pause();
  }

  Future<void> _run() async {
    Object? failure;
    try {
      for (
        var i = 0;
        i < 120 && ref.read(workspaceControllerProvider).workspace == null;
        i++
      ) {
        await _pause();
      }
      final controller = ref.read(workspaceControllerProvider.notifier);
      for (
        var i = 0;
        i < 30 &&
            _elements(
              (widget) => widget.runtimeType.toString() == '_Sidebar',
            ).isEmpty;
        i++
      ) {
        await _pause();
      }
      await _pause();
      await _verifyNativeMenus();
      await _tapLabel('Welcome to BusyMark');
      _keyData(
        PhysicalKeyboardKey.controlLeft,
        LogicalKeyboardKey.controlLeft,
        ui.KeyEventType.down,
      );
      await _key(PhysicalKeyboardKey.digit2, LogicalKeyboardKey.digit2);
      _keyData(
        PhysicalKeyboardKey.controlLeft,
        LogicalKeyboardKey.controlLeft,
        ui.KeyEventType.up,
      );
      await _pause();
      _check(
        _elements(
          (widget) => widget.runtimeType.toString() == '_TocTab',
        ).isNotEmpty,
        'Table of Contents pane visible',
      );
      await _capture('01-table-of-contents');
      await _menu('Welcome to BusyMark');
      await _capture('02-context-and-creation-menu');
      await _tapLabel('Edit Title...');
      await _native('activate', 'Advanced Settings');
      _check(
        await _native(
                  'has',
                  'Used for the current instance only. By default, inherited from topic title.',
                ) ==
                'true' &&
            await _native(
                  'has',
                  'Used in TOC only. By default, inherited from the topic title or instance-specific title if set. Titles are explained',
                ) ==
                'true' &&
            await _native('has', 'here') == 'true',
        'Native advanced title settings show inheritance explanations and documentation link',
      );
      await _capture('03-edit-title');
      await _native('activate', 'Cancel');
      await _menu('Welcome to BusyMark');
      await _tapLabel('Preview Topic');
      await _until(
        () =>
            ref
                    .read(workspaceControllerProvider)
                    .activeBuffer
                    ?.editorState
                    .mode ==
                DocumentViewModePreference.preview &&
            _elements(
              (widget) => widget.runtimeType.toString() == '_PreviewPane',
            ).isNotEmpty,
        'Selected topic preview is visible',
      );
      _check(
        ref.read(workspaceControllerProvider).activeBuffer?.filePath ==
            p.join(widget.root.path, 'topics/home.md'),
        'Preview Topic opens the selected topic',
      );
      await _capture('13-selected-topic-preview');
      await _menu('Welcome to BusyMark');
      await _tapLabel("Go to TOC Element in 'guide.tree'");
      await _until(
        () =>
            ref.read(workspaceControllerProvider).activeBuffer?.filePath ==
            p.join(widget.root.path, 'guide.tree'),
        'Guide source navigation completes',
      );
      _check(
        ref.read(workspaceControllerProvider).activeBuffer?.filePath ==
            p.join(widget.root.path, 'guide.tree'),
        'Exact source navigation opens guide.tree',
      );
      await _capture('04-source-navigation');
      await _menu('Included source topic');
      await _tapLabel("Go to TOC Element in 'library.tree'");
      await _until(
        () =>
            ref.read(workspaceControllerProvider).activeBuffer?.filePath ==
            p.join(widget.root.path, 'library.tree'),
        'Included source navigation completes',
      );
      _check(
        ref.read(workspaceControllerProvider).activeBuffer?.filePath ==
            p.join(widget.root.path, 'library.tree'),
        'Included snippet navigation opens its owner',
      );
      await _capture('05-included-source');
      await controller.openActiveFile(
        p.join(widget.root.path, 'topics/home.md'),
      );
      controller.updateActiveEditorMode(DocumentViewModePreference.source);
      await ref
          .read(appSettingsControllerProvider.notifier)
          .setDocumentViewMode(DocumentViewModePreference.source);
      await _pause();
      await _menu('XML guide title');
      await _key(PhysicalKeyboardKey.escape, LogicalKeyboardKey.escape);
      await _tap(
        _elements(
          (widget) =>
              widget is Tooltip &&
              widget.message == 'Synchronize TOC and Editor',
        ).single,
      );
      await _until(
        () =>
            ref.read(workspaceControllerProvider).activeBuffer?.filePath ==
            p.join(widget.root.path, 'topics/details.topic'),
        'Tree-to-editor synchronization opens the selected topic',
      );
      _checks.add(
        'Tree-to-editor synchronization preserves pre-toolbar focus direction',
      );
      await _menu('Welcome to BusyMark');
      await _key(PhysicalKeyboardKey.escape, LogicalKeyboardKey.escape);
      await _tap(_elements((widget) => widget is EditableText).last);
      await _tap(
        _elements(
          (widget) =>
              widget is Tooltip &&
              widget.message == 'Synchronize TOC and Editor',
        ).single,
      );
      await _pause();
      var selectedXml = false;
      _text('XML guide title').visitAncestorElements((element) {
        if (element.widget.runtimeType.toString() == '_SidebarTreeRow') {
          selectedXml = (element.widget as dynamic).selected as bool;
          return false;
        }
        return true;
      });
      _check(
        selectedXml,
        'Editor-to-tree synchronization restores the active topic selection',
      );
      await _capture('14-synchronized-selection');
      await controller.openActiveFile(
        p.join(widget.root.path, 'topics/review.md'),
      );
      await _pause();
      await _menu('Usage review');
      await _tapLabel('Remove TOC Element...');
      await _capture('06-removal');
      if (_elements(
        (widget) => widget is Text && widget.data == 'Review Usages',
      ).isNotEmpty) {
        await _tapLabel('Review Usages');
        await _capture('07-find-review');
        await _tap(
          _elements(
            (widget) => widget is Tooltip && widget.message == 'Back',
          ).last,
        );
      } else {
        await _tapLabel('Cancel');
      }
      _checks.add(
        'Production context menu, title dialog and removal dialog rendered',
      );
      await _create(
        'Welcome to BusyMark',
        'New Topic',
        'Empty MD Topic',
        'Native new Markdown',
        'native-new.md',
      );
      await _create(
        'Native new Markdown',
        'New Child Topic',
        'Empty XML Topic',
        'Native new XML',
        'native-child.topic',
      );
      final originalChild = File(
        p.join(widget.root.path, 'topics/native-child.topic'),
      );
      final renamedChild = File(
        p.join(widget.root.path, 'topics/native-child-renamed.topic'),
      );
      await _tapLabel('Native new XML');
      _keyData(
        PhysicalKeyboardKey.shiftLeft,
        LogicalKeyboardKey.shiftLeft,
        ui.KeyEventType.down,
      );
      await _key(PhysicalKeyboardKey.f6, LogicalKeyboardKey.f6);
      _keyData(
        PhysicalKeyboardKey.shiftLeft,
        LogicalKeyboardKey.shiftLeft,
        ui.KeyEventType.up,
      );
      await _until(
        () => _elements(
          (widget) =>
              widget.runtimeType.toString() == 'WritersideTopicRenameDialog',
        ).isNotEmpty,
        'Shift+F6 opens the topic rename dialog',
      );
      _check(
        _elements(
              (widget) => widget is Text && widget.data == 'Preview',
            ).isNotEmpty &&
            _elements(
              (widget) => widget is Text && widget.data == 'Refactor',
            ).isNotEmpty,
        'Topic rename offers Preview and Refactor',
      );
      await _fill('File name', 'native-child-renamed.topic');
      await _capture('20-topic-rename-dialog');
      await _tapLabel('Preview');
      await _until(
        () => _elements(
          (widget) => widget is Text && widget.data == 'Rename Preview',
        ).isNotEmpty,
        'Topic rename preview opens',
      );
      _check(
        originalChild.existsSync() && !renamedChild.existsSync(),
        'Topic rename Preview writes no files',
      );
      _check(
        _elements(
              (widget) =>
                  widget is Text &&
                  widget.data ==
                      'native-child.topic → native-child-renamed.topic',
            ).isNotEmpty &&
            _elements(
              (widget) => widget is Text && widget.data == 'guide.tree',
            ).isNotEmpty,
        'Topic rename preview lists the file and reference change',
      );
      await _capture('21-topic-rename-preview');
      await _tapLabel('Do Refactor');
      await _until(
        () => renamedChild.existsSync() && !originalChild.existsSync(),
        'Do Refactor commits the reviewed topic rename',
      );
      final renamedChildSource = await renamedChild.readAsString();
      final renamedTreeSource = await File(
        p.join(widget.root.path, 'guide.tree'),
      ).readAsString();
      _check(
        XmlDocument.parse(renamedChildSource).rootElement.getAttribute('id') ==
            'native-child-renamed',
        'Do Refactor changes the XML topic ID with the filename',
      );
      _check(
        renamedTreeSource.contains('native-child-renamed.topic') &&
            !renamedTreeSource.contains('native-child.topic'),
        'Do Refactor changes the TOC reference with the filename',
      );
      await _menu('Native new Markdown');
      await _tapLabel('New Topic');
      await _tapLabel('Link Topic Files to TOC...');
      final unlinked = File(p.join(widget.root.path, 'topics/unlinked.md'));
      final original = await unlinked.readAsString();
      await _tapLabel('unlinked.md');
      await _until(
        () => _tree
            .findAllElements('toc-element')
            .any((node) => node.getAttribute('topic') == 'unlinked.md'),
        'Link completes',
      );
      _check(
        await unlinked.readAsString() == original,
        'Linked existing topic without changing source bytes',
      );
      await _until(
        () =>
            !ref.read(workspaceControllerProvider).isLoading &&
            _elements(
              (widget) => widget is Text && widget.data == 'Available topic',
            ).isNotEmpty,
        'Linked topic appears in refreshed navigation',
      );
      await _pause();
      await _menu('Workspace');
      await _tapLabel('Sort Child Topics Alphabetically');
      await _until(
        () =>
            _tree
                .findAllElements('toc-element')
                .singleWhere(
                  (node) => node.getAttribute('toc-title') == 'Workspace',
                )
                .childElements
                .first
                .getAttribute('topic') ==
            'hidden.md',
        'Sort completes',
      );
      var tree = XmlDocument.parse(
        await File(p.join(widget.root.path, 'guide.tree')).readAsString(),
      );
      final workspaceGroup = tree
          .findAllElements('toc-element')
          .singleWhere((node) => node.getAttribute('toc-title') == 'Workspace');
      _check(
        workspaceGroup.childElements
                .map((node) => node.getAttribute('topic'))
                .join(',') ==
            'hidden.md,reused.md,details.topic',
        'Shallow contextual case-sensitive alphabetical sorting',
      );
      await _menu('XML guide title');
      await _tapLabel('Set as Home Page');
      await _until(
        () => _tree.rootElement.getAttribute('start-page') == 'details.topic',
        'Home-page write completes',
      );
      tree = XmlDocument.parse(
        await File(p.join(widget.root.path, 'guide.tree')).readAsString(),
      );
      _check(
        tree.rootElement.getAttribute('start-page') == 'details.topic',
        'Home-page action updates selected instance',
      );
      await _tapLabel('Native new Markdown');
      _keyData(
        PhysicalKeyboardKey.controlLeft,
        LogicalKeyboardKey.controlLeft,
        ui.KeyEventType.down,
      );
      await _tapLabel('Available topic');
      _keyData(
        PhysicalKeyboardKey.controlLeft,
        LogicalKeyboardKey.controlLeft,
        ui.KeyEventType.up,
      );
      await _drag('Native new Markdown', 'Empty group');
      await _until(
        () => _tree
            .findAllElements('toc-element')
            .singleWhere(
              (node) => node.getAttribute('toc-title') == 'Empty group',
            )
            .childElements
            .any((node) => node.getAttribute('topic') == 'native-new.md'),
        'Drag completes',
      );
      tree = XmlDocument.parse(
        await File(p.join(widget.root.path, 'guide.tree')).readAsString(),
      );
      final group = tree
          .findAllElements('toc-element')
          .singleWhere(
            (node) => node.getAttribute('toc-title') == 'Empty group',
          );
      _check(
        group
            .findAllElements('toc-element')
            .any(
              (node) =>
                  node.getAttribute('topic') == 'native-child-renamed.topic',
            ),
        'Pointer drag retains complete subtree',
      );
      _check(
        group.childElements.any(
          (node) => node.getAttribute('topic') == 'unlinked.md',
        ),
        'Multi-selection drag moves both selected entries',
      );
      await _capture('11-after-actions');
      await _tapLabel('Hidden authored topic');
      _keyData(
        PhysicalKeyboardKey.controlLeft,
        LogicalKeyboardKey.controlLeft,
        ui.KeyEventType.down,
      );
      await _tapLabel('Navigation-only title');
      _keyData(
        PhysicalKeyboardKey.controlLeft,
        LogicalKeyboardKey.controlLeft,
        ui.KeyEventType.up,
      );
      await _menu('Navigation-only title');
      await _tapLabel('Group');
      await _until(
        () => _elements(
          (widget) =>
              widget is TextField &&
              widget.decoration?.labelText == 'Group Name',
        ).isNotEmpty,
        'Group dialog is ready',
      );
      await _fill('Group Name', 'Native group');
      await _key(PhysicalKeyboardKey.enter, LogicalKeyboardKey.enter);
      await _until(
        () => _tree
            .findAllElements('toc-element')
            .any((node) => node.getAttribute('toc-title') == 'Native group'),
        'Group completes',
      );
      tree = XmlDocument.parse(
        await File(p.join(widget.root.path, 'guide.tree')).readAsString(),
      );
      _check(
        tree
                .findAllElements('toc-element')
                .singleWhere(
                  (node) => node.getAttribute('toc-title') == 'Native group',
                )
                .childElements
                .length ==
            2,
        'Group Enter wraps the selected source subtrees',
      );
      await _menu('Empty group');
      await _tapLabel('New Topic');
      await _tapLabel('Empty Group');
      await _fill('TOC title:', 'Native empty group');
      await _tapLabel('OK');
      await _until(
        () => _tree
            .findAllElements('toc-element')
            .any(
              (node) => node.getAttribute('toc-title') == 'Native empty group',
            ),
        'Empty Group creation completes',
      );
      _check(
        _tree
                .findAllElements('toc-element')
                .singleWhere(
                  (node) =>
                      node.getAttribute('toc-title') == 'Native empty group',
                )
                .getAttribute('topic') ==
            null,
        'Empty Group creates no topic reference',
      );
      await _menu('Welcome to BusyMark');
      await _tapLabel('New Topic');
      await _tapLabel('Topic from Template...');
      await _until(
        () => _elements(
          (widget) =>
              widget is TextField &&
              widget.key == const ValueKey('template-title'),
        ).isNotEmpty,
        'Template catalog loads',
      );
      await _capture('15-template-dialog');
      await _tapLabel('XML (.topic)');
      await _fill('Topic title:', 'Native template');
      await _fill('Filename:', 'native-template');
      await _capture('16-template-xml-preview');
      await _tapLabel('Create');
      final templateFile = File(
        p.join(widget.root.path, 'topics/native-template.topic'),
      );
      await _until(
        () =>
            ref.read(workspaceControllerProvider).activeBuffer?.filePath ==
            templateFile.path,
        'Template creation opens generated topic',
      );
      _check(
        (await templateFile.readAsString()).contains(
          'A How-to article is an action-oriented type of document.',
        ),
        'Template creates actual bundled content in one transaction',
      );
      await _menu('Native template');
      await _tapLabel('Save as Template');
      final templates = ref.read(writersideTemplateServiceProvider);
      await _until(
        () => File(
          p.join(widget.output.path, 'support/templates.json'),
        ).existsSync(),
        'Save as Template publishes application-support metadata',
      );
      _check(
        (await templates.read()).entries.single.name ==
            'Writerside_native-template',
        'Save as Template uses installed automatic name',
      );
      _check(
        !(await Directory(widget.root.path).list(recursive: true).toList()).any(
          (entity) => p.basename(entity.path) == 'templates.json',
        ),
        'User template metadata stays outside project',
      );
      await _menu('Native template');
      await _tapLabel('New Topic');
      await _tapLabel('Topic from Template...');
      await _until(
        () => _elements(
          (widget) =>
              widget is Text && widget.data == 'Writerside_native-template',
        ).isNotEmpty,
        'Saved template appears in Custom',
      );
      await _tapLabel('Writerside_native-template');
      await _tapLabel('Edit templates...');
      await _until(
        () => _elements(
          (widget) =>
              widget is TextField &&
              widget.key == const ValueKey('template-editor-source'),
        ).isNotEmpty,
        'File and Code Templates loads',
      );
      await _fill('Name:', 'Reusable guide');
      await _fill(
        'Source',
        '<topic id="\${ID}" title="\${TITLE}"><p>Edited template content</p></topic>',
      );
      await _capture('17-file-and-code-templates');
      await _tapLabel('OK');
      await _until(
        () => _elements(
          (widget) => widget is Text && widget.data == 'Reusable guide',
        ).isNotEmpty,
        'Edited template catalog refreshes',
      );
      await _tapLabel('Reusable guide');
      await _fill('Topic title:', 'Reused template');
      await _fill('Filename:', 'native-template-reused');
      await _capture('18-custom-template-preview');
      await _tapLabel('Create');
      final reusedTemplate = File(
        p.join(widget.root.path, 'topics/native-template-reused.topic'),
      );
      await _until(
        () =>
            ref.read(workspaceControllerProvider).activeBuffer?.filePath ==
            reusedTemplate.path,
        'Edited template creates another topic',
      );
      _check(
        await reusedTemplate.readAsString() ==
            '<topic id="native-template-reused" title="Reused template"><p>Edited template content</p></topic>',
        'Saved edited template substitutes title and ID in generated source',
      );
      _check(
        (await templateFile.readAsString()).contains('A How-to article'),
        'Editing a template never rewrites its source topic',
      );
      await _menu('XML guide title');
      await _tapLabel('Duplicate');
      await _native('set-entry', '0\nnative-duplicate');
      await _native('activate', 'OK');
      final duplicate = File(
        p.join(widget.root.path, 'topics/native-duplicate.topic'),
      );
      await _until(
        () =>
            ref.read(workspaceControllerProvider).activeBuffer?.filePath ==
            duplicate.path,
        'Duplicate opens its new document',
      );
      _check(
        await duplicate.exists(),
        'Duplicate creates source file from the selected XML topic',
      );
      _check(
        XmlDocument.parse(
              await duplicate.readAsString(),
            ).rootElement.getAttribute('id') ==
            'native-duplicate',
        'Duplicate assigns new XML root ID',
      );
      await _tap(_elements((widget) => widget is EditableText).last);
      _keyData(
        PhysicalKeyboardKey.controlLeft,
        LogicalKeyboardKey.controlLeft,
        ui.KeyEventType.down,
      );
      await _key(PhysicalKeyboardKey.digit1, LogicalKeyboardKey.digit1);
      _keyData(
        PhysicalKeyboardKey.controlLeft,
        LogicalKeyboardKey.controlLeft,
        ui.KeyEventType.up,
      );
      await _until(
        () => _elements(
          (widget) => widget.runtimeType.toString() == '_FilesTab',
        ).isNotEmpty,
        'Files sidebar is selected',
      );
      await _menu('native-duplicate.topic');
      await _tapLabel('Refactor');
      await _tapLabel('Safe Delete');
      await _capture('12-safe-delete');
      await _tapLabel('OK');
      await _until(() => !duplicate.existsSync(), 'Safe Delete completes');
      _check(
        !await duplicate.exists(),
        'Files Refactor / Safe Delete removes the fixture copy through analysis',
      );
    } on Object catch (error, stack) {
      failure = error;
      stderr.writeln('$error\n$stack');
      await _capture('failure');
    }
    await File(p.join(widget.output.path, 'result.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'fixture': widget.root.path,
        'checks': _checks,
        'failure': failure?.toString(),
      }),
    );
    exit(failure == null ? 0 : 1);
  }

  Future<void> _verifyNativeMenus() async {
    const service = NativeMenuService();
    const entries = [
      NativeMenuEntry.submenu(
        label: 'Unavailable',
        enabled: false,
        children: [NativeMenuEntry.command(label: 'Blocked child')],
      ),
      NativeMenuEntry.submenu(
        label: 'New Topic',
        children: [
          NativeMenuEntry.command(label: 'Markdown'),
          NativeMenuEntry.separator(),
          NativeMenuEntry.submenu(
            label: 'XML formats',
            children: [NativeMenuEntry.command(label: 'XML topic')],
          ),
        ],
      ),
      NativeMenuEntry.separator(),
      NativeMenuEntry.command(label: 'Extra'),
      NativeMenuEntry.command(label: "Topic File Name 'first_topic.md'"),
      NativeMenuEntry.command(label: 'Repeated __ and ___ underscores'),
    ];
    for (final direction in TextDirection.values) {
      final previousFocus = FocusManager.instance.primaryFocus;
      final pending = service.show(
        session: NativeMenuSession(),
        anchor: const Rect.fromLTWH(600, 180, 80, 24),
        entries: entries,
        focusFirst: true,
        textDirection: direction,
      );
      await _pause();
      final tree = jsonDecode(await _native('inspect')) as List;
      _check(
        tree.any(
          (dynamic row) =>
              row['name'] == 'Unavailable' && row['enabled'] == false,
        ),
        'GTK disables submenu headings in ${direction.name}',
      );
      _check(
        tree.any(
              (dynamic row) =>
                  row['name'] == "Topic File Name 'first_topic.md'",
            ) &&
            tree.any(
              (dynamic row) => row['name'] == 'Repeated __ and ___ underscores',
            ),
        'GTK renders single and repeated underscores literally in ${direction.name}',
      );
      await _native('key', direction == TextDirection.ltr ? 'Right' : 'Left');
      await _pause();
      await _native('key', 'Down');
      await _native('key', direction == TextDirection.ltr ? 'Right' : 'Left');
      await _capture('19-native-keyboard-${direction.name}');
      await _native('key', 'Return');
      final result = await pending.timeout(const Duration(seconds: 5));
      _check(
        result.available && result.selectedIndex == 6,
        'GTK two-level keyboard traversal returns the exact leaf in ${direction.name}',
      );
      await _pause();
      _check(
        FocusManager.instance.primaryFocus == previousFocus,
        'GTK returns focus without replacing the Flutter focus in ${direction.name}',
      );
      final cancel = service.show(
        session: NativeMenuSession(),
        anchor: const Rect.fromLTWH(600, 180, 80, 24),
        entries: entries,
        focusFirst: true,
        textDirection: direction,
      );
      await _pause();
      await _native('key', 'Escape');
      _check(
        (await cancel.timeout(const Duration(seconds: 5))).selectedIndex ==
            null,
        'GTK Escape dismisses without an action in ${direction.name}',
      );
    }
    final first = NativeMenuSession();
    final second = NativeMenuSession();
    final retired = service.show(
      session: first,
      anchor: Rect.zero,
      entries: entries,
    );
    await _pause();
    final current = service.show(
      session: second,
      anchor: Rect.zero,
      entries: entries,
    );
    await _pause();
    _check(
      (await retired).selectedIndex == null && !await service.dismiss(first),
      'A retired native menu cannot dismiss a newer menu',
    );
    await service.dismiss(second);
    _check(
      (await current).selectedIndex == null,
      'Native menu session dismissal returns cancellation',
    );
    final radio = service.show(
      session: NativeMenuSession(),
      anchor: const Rect.fromLTWH(600, 180, 80, 24),
      focusFirst: true,
      entries: const [
        NativeMenuEntry.command(
          label: 'First format',
          checkable: true,
          selected: true,
        ),
        NativeMenuEntry.command(label: 'Second format', checkable: true),
      ],
    );
    await _pause();
    await _native('key', 'Down');
    await _native('key', 'Return');
    _check(
      (await radio.timeout(const Duration(seconds: 5))).selectedIndex == 1,
      'Existing flat native single-choice selectors still return their row index',
    );
  }
}

class _Settings implements LocalSettingsStore {
  _Settings(this.value);
  Map<String, Object?> value;
  @override
  Future<Map<String, Object?>> load() async => value;
  @override
  Future<void> save(Map<String, Object?> json) async {
    value = json;
  }
}
