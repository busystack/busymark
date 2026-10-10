// Production Linux authoring smoke harness. Mutates only a disposable fixture.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/app/busymark_app.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/startup_path.dart';
import 'package:busymark/src/app/system_accent.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:busymark/src/editor/wysiwyg/writerside_properties.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_inline_controller.dart';
import 'package:busymark/src/local_history/local_history_store.dart';
import 'package:busymark/src/local_history/local_history_controller.dart';
import 'package:busymark/src/platform/linux_header_bar_service.dart';
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

Future<void> main(List<String> arguments) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (arguments.length != 2) throw ArgumentError('FIXTURE OUTPUT_DIRECTORY');
  final root = await Directory.systemTemp.createTemp(
    'busymark-authoring-native-',
  );
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
  await File(p.join(root.path, 'topics/authoring.topic')).writeAsString(
    '<topic id="authoring" title="Authoring XML"><p>Text</p><chapter id="section" title="Section"><p>Nested content</p><code-block lang="dart">print(1);</code-block></chapter></topic>',
  );
  await File(p.join(root.path, 'topics/authoring.md')).writeAsString(
    '# Authoring Markdown\n\nText\n\n## Section\n\nNested content\n',
  );
  final tree = File(p.join(root.path, 'conformance.tree'));
  await tree.writeAsString(
    (await tree.readAsString()).replaceFirst(
      '</instance-profile>',
      '<toc-element topic="authoring.topic"/><toc-element topic="authoring.md"/></instance-profile>',
    ),
  );
  final output = await Directory(
    p.absolute(arguments[1]),
  ).create(recursive: true);
  await windowManager.ensureInitialized();
  await LinuxHeaderBarService.instance.initialize();
  final settings = AppSettings.defaults().copyWith(
    localeTag: 'en',
    themeModePreference: BusyMarkThemeModePreference.light,
    documentViewMode: DocumentViewModePreference.editor,
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

  Future<String> _native(
    String command, [
    String? argument,
    String? secondArgument,
  ]) async {
    final result = await Process.run('/usr/bin/python3', [
      p.absolute('tools/linux_native_menu_probe.py'),
      '$pid',
      command,
      ?argument,
      ?secondArgument,
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

  Element _field(String text) => _elements(
    (w) =>
        w is TextField &&
        w.controller is BusyMarkWysiwygTextController &&
        w.controller!.text == text,
  ).first;
  Future<void> _choose(String key, List<String> labels) async {
    await _tap(_elements((w) => w.key == ValueKey(key)).single);
    _nativeMenuOpen = true;
    for (final label in labels) {
      _nativeMenuOpen = true;
      await _tapLabel(label);
    }
    _check(!_nativeMenuOpen, 'GTK menu completed: ${labels.join(" / ")}');
  }

  Future<void> _type(Element e, String text) async {
    await _tap(e);
    final field = e.widget as TextField;
    field.controller!.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    field.onChanged?.call(text);
    await _pause();
  }

  String get _source => ref.read(workspaceControllerProvider).activeText;
  Future<void> _captureScaled(String name) async {
    // Exercise the actual Linux window at accessibility text scaling. GTK's
    // DPI setting does not change Flutter's text scaler on this embedding.
    Element? media;
    _elements((w) => w is BusyMarkWysiwygEditor).single.visitAncestorElements((
      e,
    ) {
      if (e.widget is MediaQuery) {
        media = e;
        return false;
      }
      return true;
    });
    final element = media!;
    final original = element.widget as MediaQuery;
    element.update(
      MediaQuery(
        data: original.data.copyWith(textScaler: TextScaler.linear(1.5)),
        child: original.child,
      ),
    );
    await _pause();
    _check(
      MediaQuery.textScalerOf(
            _elements((w) => w is BusyMarkWysiwygEditor).single,
          ).scale(14) ==
          21,
      'Linux text scaling applied',
    );
    await _capture(name);
    element.update(original);
    await _pause();
  }

  Future<void> _run() async {
    Object? failure;
    try {
      await _until(
        () =>
            ref.read(workspaceControllerProvider).workspace?.rootPath ==
            widget.root.path,
        'Fixture workspace loaded',
      );
      final controller = ref.read(workspaceControllerProvider.notifier);
      final settings = ref.read(appSettingsControllerProvider.notifier);
      for (final suffix in ['topic', 'md']) {
        await controller.openActiveFile(
          p.join(widget.root.path, 'topics/authoring.$suffix'),
        );
        await _until(
          () => _elements((w) => w is BusyMarkWysiwygEditor).isNotEmpty,
          'Editor available for $suffix',
        );
        await _pause();
        final body = _field('Text');
        stdout.writeln(
          'Native text scale: ${MediaQuery.textScalerOf(body).scale(14) / 14}',
        );
        await _tap(body);
        (body.widget as TextField).controller!.selection = const TextSelection(
          baseOffset: 0,
          extentOffset: 4,
        );
        await _pause();
        await _choose('wysiwyg-writerside-semantic', ['UI Control']);
        _check(
          _source.contains('<control>Text</control>'),
          '$suffix semantic formatting authors control',
        );
        _keyData(
          PhysicalKeyboardKey.controlLeft,
          LogicalKeyboardKey.controlLeft,
          ui.KeyEventType.down,
        );
        await _key(PhysicalKeyboardKey.keyZ, LogicalKeyboardKey.keyZ);
        _keyData(
          PhysicalKeyboardKey.controlLeft,
          LogicalKeyboardKey.controlLeft,
          ui.KeyEventType.up,
        );
        _check(
          !_source.contains('<control>'),
          '$suffix semantic action undo is one buffer operation',
        );
        _keyData(
          PhysicalKeyboardKey.controlLeft,
          LogicalKeyboardKey.controlLeft,
          ui.KeyEventType.down,
        );
        _keyData(
          PhysicalKeyboardKey.shiftLeft,
          LogicalKeyboardKey.shiftLeft,
          ui.KeyEventType.down,
        );
        await _key(PhysicalKeyboardKey.keyZ, LogicalKeyboardKey.keyZ);
        _keyData(
          PhysicalKeyboardKey.shiftLeft,
          LogicalKeyboardKey.shiftLeft,
          ui.KeyEventType.up,
        );
        _keyData(
          PhysicalKeyboardKey.controlLeft,
          LogicalKeyboardKey.controlLeft,
          ui.KeyEventType.up,
        );
        _check(
          _source.contains('<control>Text</control>'),
          '$suffix semantic redo preserves type',
        );
        await _choose('wysiwyg-writerside-insert', ['Procedure']);
        await _type(_field(''), 'Step content');
        _check(
          _source.contains('<procedure') && _source.contains('Step content'),
          '$suffix inserted procedure is visually editable',
        );
        await _tap(_field('Text'));
        await _choose('wysiwyg-writerside-insert', ['Tabs']);
        await _type(_field(''), 'Tab content');
        _check(
          _source.contains('Tab content'),
          '$suffix inserted tab is visually editable',
        );
        await _tap(_field('Text'));
        await _choose('wysiwyg-writerside-insert', ['Definition List']);
        await _type(_field(''), 'Definition content');
        await _tap(_field('Text'));
        await _choose('wysiwyg-writerside-insert', ['TLDR']);
        await _type(_field(''), 'Summary content');
        await _tap(_field('Text'));
        final beforeVideo = _source;
        await _choose('wysiwyg-writerside-insert', ['Video']);
        _check(_source == beforeVideo, '$suffix video draft is source-neutral');
        final videoEntry = _elements(
          (w) => w is BusyMarkGroupedTextEntry && w.label == 'Source',
        ).single;
        await _tap(videoEntry);
        final videoField = videoEntry.widget as BusyMarkGroupedTextEntry;
        videoField.controller!.text = 'https://youtu.be/BeJu9bMPLGU';
        videoField.focusNode!.requestFocus();
        await _pause();
        await _key(PhysicalKeyboardKey.enter, LogicalKeyboardKey.enter);
        _check(
          _source.contains('<video src="https://youtu.be/BeJu9bMPLGU"/>'),
          '$suffix video source is authored',
        );
        await _tap(_field('Text'));
        await _choose('wysiwyg-writerside-insert', [
          'Include Reusable Content',
          'features.topic',
          'shared-conformance',
        ]);
        _check(
          _source.contains('element-id="shared-conformance"'),
          '$suffix include remains authored reference',
        );
        await _tap(_field('Text'));
        (_field('Text').widget as TextField).controller!.selection =
            const TextSelection.collapsed(offset: 4);
        await _pause();
        await _choose('wysiwyg-writerside-insert', [
          'Variable Reference',
          'product',
        ]);
        _check(
          _source.contains('%product%'),
          '$suffix variable remains authored reference',
        );
        const switcherLabel = r'''Author's: "Desktop" \ Keys''';
        final beforeLabel = _source;
        final selectedField = _field('Textproduct').widget as TextField;
        final selection = selectedField.controller!.selection;
        Future<void> topicProperties() async {
          await _tap(
            _elements(
              (w) =>
                  w is BusyMarkComboRow<String> && w.values.contains('@topic'),
            ).single,
          );
          _nativeMenuOpen = true;
          await _tapLabel('Topic Properties');
          _check(!_nativeMenuOpen, '$suffix GTK Topic Properties selected');
        }

        await topicProperties();
        _check(
          _source == beforeLabel &&
              selectedField.controller!.selection == selection,
          '$suffix opening Topic Properties preserves source and selection',
        );
        BusyMarkGroupedTextEntry labelEntry() =>
            _elements(
                  (w) =>
                      w is BusyMarkGroupedTextEntry &&
                      w.label == 'Switcher label',
                ).single.widget
                as BusyMarkGroupedTextEntry;
        final labelField = labelEntry();
        labelField.controller!.text = switcherLabel;
        labelField.focusNode!.requestFocus();
        await _pause();
        _check(
          _source == beforeLabel,
          '$suffix switcher label draft is source-neutral',
        );
        await _key(PhysicalKeyboardKey.enter, LogicalKeyboardKey.enter);
        _check(
          _source != beforeLabel && _source.contains('switcher-label'),
          '$suffix switcher label property is authored',
        );
        await _tap(_field('Section'));
        final before = _source;
        await _capture('authoring-$suffix-light');
        await _tap(
          _elements(
            (w) => w is BusyMarkSwitchRow && w.title == 'Collapsible',
          ).single,
        );
        _check(
          _source != before && _source.contains('collapsible="true"'),
          '$suffix ordinary section exposes collapse properties',
        );
        final authored = _source;
        await _tap(
          _elements(
            (w) =>
                w is BusyMarkHeaderIconButton &&
                    w.tooltip == 'Expand Chapter' ||
                w is IconButton && w.tooltip == 'Expand Section',
          ).single,
        );
        _check(
          _source == authored,
          '$suffix local disclosure is source-neutral',
        );
        _check(await controller.saveActive(), '$suffix save succeeds');
        controller.updateActiveEditorMode(DocumentViewModePreference.source);
        await settings.setDocumentViewMode(DocumentViewModePreference.source);
        await _pause();
        _check(
          _elements((w) => w is BusyMarkWysiwygEditor).isEmpty,
          '$suffix Source switch',
        );
        controller.updateActiveEditorMode(DocumentViewModePreference.editor);
        await settings.setDocumentViewMode(DocumentViewModePreference.editor);
        await _pause();
        _check(
          _source == authored,
          '$suffix Source to Editor preserves source',
        );
        await topicProperties();
        _check(
          labelEntry().controller!.text == switcherLabel,
          '$suffix switcher label survives save and Source to Editor',
        );
        await _tap(_field('Section'));
        _check(
          !(_elements((w) => w is BusyMarkWritersideProperties).single.widget
                  as BusyMarkWritersideProperties)
              .topicSelected,
          '$suffix returning to the same content retargets properties',
        );
        await settings.setThemeModePreference(BusyMarkThemeModePreference.dark);
        await settings.setEditorToolbarDirection(
          EditorToolbarDirection.vertical,
        );
        await windowManager.setSize(const Size(800, 900));
        await _capture('authoring-$suffix-dark-narrow-vertical');
        await settings.setLocaleTag('ar');
        await _capture('authoring-$suffix-rtl');
        await _captureScaled('authoring-$suffix-rtl-scaled');
        await settings.setLocaleTag('en');
        await settings.setThemeModePreference(
          BusyMarkThemeModePreference.light,
        );
        await settings.setEditorToolbarDirection(
          EditorToolbarDirection.horizontal,
        );
        await windowManager.setSize(const Size(1400, 960));
      }
      await File(p.join(widget.output.path, 'generated.topic')).writeAsString(
        await File(
          p.join(widget.root.path, 'topics/authoring.topic'),
        ).readAsString(),
      );
      await File(p.join(widget.output.path, 'generated.md')).writeAsString(
        await File(
          p.join(widget.root.path, 'topics/authoring.md'),
        ).readAsString(),
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
