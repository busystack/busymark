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
import 'package:busymark/src/editor/source/source_editor.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
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
  await File(p.join(root.path, 'topics/authoring-markdown.md')).writeAsString(
    '# Authoring Markdown\n\nText\n\n## Section\n\nNested content\n',
  );
  await File(
    p.join(root.path, 'README.md'),
  ).writeAsString('# Ordinary Markdown\n\nPlain text\n');
  await File(p.join(root.path, 'topics/inspector.topic')).writeAsString(
    '<topic id="inspector" title="Inspector"><p id="caret">Caret A</p><chapter id="b" title="Block B"><chapter id="nested" title="Nested"><p>Nested body</p><code-block id="file" lang="text" src="inspector-sample.txt"/></chapter></chapter><deflist collapsible="true" default-state="expanded"><def title="Term" default-state="inherited"><p>Definition.</p></def></deflist></topic>',
  );
  await File(p.join(root.path, 'topics/inspector-markdown.md')).writeAsString(
    '# Inspector {id="inspector-markdown"}\n\nCaret A\n\n## Block B\n\n### Nested\n\nNested body\n\n```text\n```\n{id="file" src="inspector-sample.txt"}\n',
  );
  await File(
    p.join(root.path, 'topics/inspector-sample.txt'),
  ).writeAsString('first\nsecond\nthird\n');
  await File(
    p.join(root.path, 'topics/inspector-corrections.md'),
  ).writeAsString(
    '# Inspector Corrections\n\nUse `{id="literal-code"}`\n\nUse [**link**](authoring.topic){id="owned-link"}\n\n- First **item**\n- Second item\n\n- [x] Checked task\n- [ ] Unchecked task\n\n> A **note**.\n{style="note"}\n',
  );
  final tree = File(p.join(root.path, 'conformance.tree'));
  await tree.writeAsString(
    (await tree.readAsString()).replaceFirst(
      '</instance-profile>',
      '<toc-element topic="authoring.topic"/><toc-element topic="authoring-markdown.md"/><toc-element topic="inspector.topic" toc-title="Inspector XML"/><toc-element topic="inspector-markdown.md" toc-title="Inspector Markdown"/><toc-element topic="inspector-corrections.md"/></instance-profile>',
    ),
  );
  final defaultsFixture = Directory(
    p.join(fixture.parent.path, 'property_defaults_conformance'),
  );
  final defaultsRoot = Directory('${root.path}-defaults');
  await for (final item in defaultsFixture.list(recursive: true)) {
    final destination = p.join(
      defaultsRoot.path,
      p.relative(item.path, from: defaultsFixture.path),
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
    // Inherited-widget updates must notify their dependants during a build
    // scope. Updating the element directly from this async probe asserts in
    // the debug application and prevents the scaling acceptance check.
    element.owner!.buildScope(element, () {
      element.update(
        MediaQuery(
          data: original.data.copyWith(textScaler: TextScaler.linear(1.5)),
          child: original.child,
        ),
      );
    });
    await _pause();
    _check(
      MediaQuery.textScalerOf(
            _elements((w) => w is BusyMarkWysiwygEditor).single,
          ).scale(14) ==
          21,
      'Linux text scaling applied',
    );
    await _capture(name);
    element.owner!.buildScope(element, () => element.update(original));
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
      for (final suffix
          in Platform.environment['BUSYMARK_PROPERTIES_ONLY'] == '1'
              ? <String>[]
              : ['topic', 'md']) {
        await controller.openActiveFile(
          p.join(
            widget.root.path,
            'topics/${suffix == 'md' ? 'authoring-markdown.md' : 'authoring.topic'}',
          ),
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
        final beforeMenu = _source;
        final selected = (body.widget as TextField).controller!.selection;
        await _tap(
          _elements(
            (w) => w.key == const ValueKey('wysiwyg-writerside-insert'),
          ).single,
        );
        _nativeMenuOpen = true;
        await _native('key', 'Down');
        await _capture('authoring-$suffix-insert-menu');
        await _native('key', 'Escape');
        _nativeMenuOpen = false;
        await _pause();
        stdout.writeln(
          'GTK dismissal: source unchanged=${_source == beforeMenu}; '
          'selection before=$selected after=${(body.widget as TextField).controller!.selection}; '
          'editing focus=${(body.widget as TextField).focusNode!.hasFocus}; '
          'primary focus=${FocusManager.instance.primaryFocus?.debugLabel}',
        );
        _check(
          _source == beforeMenu &&
              (body.widget as TextField).controller!.selection == selected &&
              (body.widget as TextField).focusNode!.hasFocus,
          '$suffix GTK keyboard dismissal preserves source, selection and focus',
        );
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
            (w) => w is BusyMarkComboRow<String> && w.title == 'Collapsible',
          ).single,
        );
        _nativeMenuOpen = true;
        await _tapLabel('Enabled');
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
        stdout.writeln(
          'Saved $suffix: dirty=${ref.read(workspaceControllerProvider).activeBuffer?.isDirty}; '
          'revision=${ref.read(workspaceControllerProvider).activeBuffer?.revision}',
        );
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
        // Use the queued buffer transaction used by the application's tab
        // actions; background validation may refresh buffer metadata here.
        final closingBuffer = ref
            .read(workspaceControllerProvider)
            .activeBuffer!;
        final closed = await controller.closeDocumentBuffer(closingBuffer.id);
        stdout.writeln(
          'Close $suffix: result=$closed; dirty=${closingBuffer.isDirty}; '
          'revision=${closingBuffer.revision}; '
          'content saved=${closingBuffer.text == closingBuffer.lastSavedText}; '
          'current dirty=${ref.read(workspaceControllerProvider).activeBuffer?.isDirty}; '
          'current document=${ref.read(workspaceControllerProvider).activeBuffer?.displayName}; '
          'buffer remains=${ref.read(workspaceControllerProvider).documentBuffers.any((b) => b.id == closingBuffer.id)}; '
          'message=${ref.read(workspaceControllerProvider).message}',
        );
        _check(closed, '$suffix saved buffer closes');
        await controller.openActiveFile(
          p.join(
            widget.root.path,
            'topics/${suffix == 'md' ? 'authoring-markdown.md' : 'authoring.topic'}',
          ),
        );
        await _until(
          () =>
              _elements((w) => w is BusyMarkWysiwygEditor).isNotEmpty &&
              _source == authored,
          '$suffix saved topic reopens',
        );
        _check(
          _source == authored,
          '$suffix reopening from disk preserves authored semantics',
        );
        final variableField = _field('Textproduct');
        await _tap(variableField);
        (variableField.widget as TextField).controller!.selection =
            const TextSelection.collapsed(offset: 6);
        await _pause();
        _check(
          _elements(
            (w) =>
                w is BusyMarkGroupedTextEntry &&
                w.label == 'Variable Reference',
          ).isNotEmpty,
          '$suffix variable reference properties survive reopening',
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
      for (final suffix in ['topic', 'md']) {
        await _native('chord', 'ctrl+shift+1');
        await settings.setElementPropertiesVisible(true);
        await settings.setElementPropertiesWidth(390);
        await controller.openActiveFile(
          p.join(
            widget.root.path,
            'topics/${suffix == 'md' ? 'inspector-markdown.md' : 'inspector.topic'}',
          ),
        );
        await _until(
          () => _elements((w) => w is BusyMarkWysiwygEditor).isNotEmpty,
          'Inspector editor loaded',
        );
        await _tap(_field('Caret A'));
        final caret =
            (_field('Caret A').widget as TextField).controller!.selection;
        if (suffix == 'topic') {
          final editor =
              _elements((w) => w is BusyMarkWysiwygEditor).single.widget
                  as BusyMarkWysiwygEditor;
          final b = editor.document.blocks.first.children.firstWhere(
            (b) => b.attributes['id'] == 'b',
          );
          await _tap(
            _elements(
              (w) => w.key == ValueKey('writerside-inspect-${b.id}'),
            ).single,
          );
          final panel =
              _elements((w) => w is BusyMarkWritersideProperties).single.widget
                  as BusyMarkWritersideProperties;
          _check(
            panel.target!.plainText == 'Block B' &&
                panel.path.last.id == b.id &&
                (_field('Caret A').widget as TextField).controller!.selection ==
                    caret,
            'Inspector identity and ancestry follow B while caret remains in A',
          );
          await _capture('inspector-nested-target');
          final title =
              _elements(
                    (w) => w is BusyMarkGroupedTextEntry && w.label == 'Title',
                  ).single.widget
                  as BusyMarkGroupedTextEntry;
          await _tap(
            _elements(
              (w) => w is TextField && w.controller == title.controller,
            ).single,
          );
          title.controller!.text = 'Installation';
          await _key(PhysicalKeyboardKey.enter, LogicalKeyboardKey.enter);
          _check(
            _source.contains('title="Installation"') &&
                _source.contains('>Caret A</p>'),
            'Explicit inspected B receives the edit',
          );
          _check(
            controller.undoActiveBuffer(),
            'Explicit B property has one undo',
          );
          await _pause();
          _check(
            _source.contains('title="Block B"'),
            'Undo restores inspected B',
          );
        }
        await _native('chord', 'ctrl+shift+2');
        await _until(
          () => _elements((w) => w is BusyMarkSourceEditor).isNotEmpty,
          'Source inspector loaded',
        );
        _check(
          _elements((w) => w is BusyMarkWysiwygEditor).isEmpty,
          'Source inspector has no hidden WYSIWYG',
        );
        final sourceElement =
            _elements((w) => w is BusyMarkSourceEditor).single
                as StatefulElement;
        final sourceState = sourceElement.state as BusyMarkSourceEditorState;
        final codeOffset = suffix == 'topic'
            ? _source.indexOf('<code-block')
            : _source.indexOf('```text');
        sourceState.scrollToOffset(codeOffset);
        await _pause();
        final properties =
            _elements((w) => w is BusyMarkWritersideProperties).single.widget
                as BusyMarkWritersideProperties;
        _check(
          properties.target!.kind == BusyBlockKind.codeBlock &&
              properties.path.any((b) => b.plainText == 'Nested'),
          '$suffix Source caret resolves code and chapter ancestry',
        );
        await _capture('inspector-$suffix-source-code');
        BusyMarkGroupedTextEntry property(String label) =>
            _elements(
                  (w) => w is BusyMarkGroupedTextEntry && w.label == label,
                ).single.widget
                as BusyMarkGroupedTextEntry;
        final id = property('Element ID');
        await _tap(
          _elements(
            (w) => w is TextField && w.controller == id.controller,
          ).single,
        );
        final beforeHistory = ref
            .read(workspaceControllerProvider)
            .activeBuffer!
            .editorState
            .undoState
            .undo
            .length;
        id.controller!.text = 'saved-code';
        await _native('chord', 'ctrl+s');
        await _until(() {
          final current = ref.read(workspaceControllerProvider).activeBuffer;
          return current != null &&
              !current.isDirty &&
              File(
                current.filePath!,
              ).readAsStringSync().contains('id="saved-code"');
        }, '$suffix focused native Save reaches disk');
        final buffer = ref.read(workspaceControllerProvider).activeBuffer!;
        _check(
          (await File(
            buffer.filePath!,
          ).readAsString()).contains('id="saved-code"'),
          '$suffix native Ctrl+S commits focused property before saving',
        );
        _check(
          buffer.editorState.undoState.undo.length == beforeHistory + 1,
          '$suffix property commit records one undo',
        );
        _check(
          buffer.editorState.selection.extentOffset == codeOffset,
          '$suffix Source selection survives property transaction',
        );
        final invalidId = property('Element ID');
        invalidId.focusNode!.requestFocus();
        invalidId.controller!.text = 'invalid id';
        final beforeInvalid = _source;
        await _native('chord', 'ctrl+s');
        await _pause();
        _check(
          _source == beforeInvalid && controller.propertyEdits.hasPending,
          '$suffix invalid draft blocks Save and retains its target',
        );
        await _native('chord', 'ctrl+shift+3');
        await _pause();
        _check(
          _elements((w) => w is BusyMarkSourceEditor).isNotEmpty,
          '$suffix invalid draft cancels view transition',
        );
        await _tap(
          _elements(
                (w) => w is BusyMarkHeaderIconButton && w.tooltip == 'Close',
              )
              .where(
                (e) =>
                    e
                        .findAncestorWidgetOfExactType<
                          BusyMarkWritersideProperties
                        >() !=
                    null,
              )
              .single,
        );
        _check(
          _elements((w) => w is BusyMarkWritersideProperties).isNotEmpty &&
              controller.propertyEdits.hasPending,
          '$suffix invalid draft cancels inspector closure',
        );
        await _capture('inspector-$suffix-invalid-draft');
        invalidId.focusNode!.requestFocus();
        await _pause();
        await _key(PhysicalKeyboardKey.escape, LogicalKeyboardKey.escape);
        _check(
          !controller.propertyEdits.hasPending &&
              invalidId.controller!.text == 'saved-code',
          '$suffix Escape explicitly reverts pending text',
        );
        final extraction = property('Include lines');
        await _tap(
          _elements(
            (w) => w is TextField && w.controller == extraction.controller,
          ).single,
        );
        extraction.controller!.text = '2-3';
        await _key(PhysicalKeyboardKey.enter, LogicalKeyboardKey.enter);
        final emphasis = property('Emphasize displayed lines');
        await _tap(
          _elements(
            (w) => w is TextField && w.controller == emphasis.controller,
          ).single,
        );
        emphasis.controller!.text = '1';
        await _key(PhysicalKeyboardKey.enter, LogicalKeyboardKey.enter);
        await _capture('inspector-$suffix-code-properties');
        _check(await controller.saveActive(), '$suffix Source inspector save');
        _check(
          await controller.closeDocumentBuffer(buffer.id),
          '$suffix Source inspector close',
        );
        await controller.openActiveFile(buffer.filePath!);
        await _native('chord', 'ctrl+shift+2');
        await _until(
          () => _elements((w) => w is BusyMarkSourceEditor).isNotEmpty,
          'Reopened Source inspector',
        );
        final reopened =
            (_elements((w) => w is BusyMarkSourceEditor).single
                        as StatefulElement)
                    .state
                as BusyMarkSourceEditorState;
        reopened.scrollToOffset(
          _source.indexOf(suffix == 'topic' ? '<code-block' : '```text'),
        );
        await _until(
          () => _elements(
            (w) =>
                w is BusyMarkGroupedTextEntry &&
                w.label == 'Element ID' &&
                w.controller?.text == 'saved-code',
          ).isNotEmpty,
          '$suffix reopened Source caret resolves saved code',
        );
        _check(
          property('Element ID').controller!.text == 'saved-code' &&
              property('Include lines').controller!.text == '2-3' &&
              property('Emphasize displayed lines').controller!.text == '1',
          '$suffix saved code properties survive close, reopen and reinspection',
        );
        await _native('chord', 'ctrl+shift+4');
        await _pause();
        await _capture('inspector-$suffix-split');
        await _native('chord', 'ctrl+shift+2');
        await _pause();
        final initial = _source;
        final delayedProperties =
            _elements((w) => w is BusyMarkWritersideProperties).single.widget
                as BusyMarkWritersideProperties;
        final liveSourceState =
            (_elements((w) => w is BusyMarkSourceEditor).single
                        as StatefulElement)
                    .state
                as BusyMarkSourceEditorState;
        liveSourceState.scrollToOffset(
          _source.indexOf(suffix == 'topic' ? '<chapter id="b"' : '## Block B'),
        );
        await _until(
          () => _elements(
            (w) =>
                w is BusyMarkWritersideProperties &&
                w.target?.attributes['element'] != 'code-block' &&
                w.target?.kind != BusyBlockKind.codeBlock,
          ).isNotEmpty,
          '$suffix Source retargets to chapter',
        );
        _check(
          !delayedProperties.onProperty('collapsed-title', 'Delayed result') &&
              _source == initial,
          '$suffix delayed completion rejects a different target in the same unchanged buffer',
        );
        liveSourceState.scrollToOffset(
          _source.indexOf(suffix == 'topic' ? '<code-block' : '```text'),
        );
        await _until(
          () => _elements(
            (w) =>
                w is BusyMarkWritersideProperties &&
                w.target?.kind == BusyBlockKind.codeBlock,
          ).isNotEmpty,
          '$suffix Source restores code target',
        );
        await _tap(
          _elements(
            (w) => w is BusyMarkComboRow<String> && w.title == 'Collapsible',
          ).single,
        );
        _nativeMenuOpen = true;
        await _tapLabel('Enabled');
        await _capture('inspector-$suffix-override');
        await _tap(
          _elements(
            (w) => w is BusyMarkComboRow<String> && w.title == 'Collapsible',
          ).single,
        );
        _nativeMenuOpen = true;
        await _tapLabel('Use default — Disabled');
        _check(
          _source == initial,
          '$suffix reset removes authored collapse and restores source',
        );
        await windowManager.setSize(const Size(800, 900));
        await _capture('inspector-$suffix-narrow-overlay');
        _check(
          ref.read(appSettingsControllerProvider).elementPropertiesWidth == 390,
          'Narrow layout preserves preferred inspector width',
        );
        await windowManager.setSize(const Size(1400, 960));
        await _native('chord', 'ctrl+shift+3');
        await _pause();
        final reading =
            _elements((w) => w is BusyMarkWritersideProperties).single.widget
                as BusyMarkWritersideProperties;
        _check(
          reading.readOnly,
          '$suffix Reading retains validated read-only properties',
        );
        await _capture('inspector-$suffix-reading');
        _check(
          _source == initial,
          '$suffix navigation and Reading leave source unchanged',
        );
        await File(
          p.join(widget.output.path, 'inspector.$suffix'),
        ).writeAsString(_source);
        await _native('chord', 'ctrl+shift+1');
      }
      BusyMarkWritersideProperties inspector() =>
          _elements((w) => w is BusyMarkWritersideProperties).single.widget
              as BusyMarkWritersideProperties;
      BusyMarkComboRow<String> combo(String title) =>
          _elements(
                (w) => w is BusyMarkComboRow<String> && w.title == title,
              ).single.widget
              as BusyMarkComboRow<String>;
      Future<void> chooseCombo(String title, String label) async {
        await _tap(
          _elements(
            (w) => w is BusyMarkComboRow<String> && w.title == title,
          ).single,
        );
        _nativeMenuOpen = true;
        await _tapLabel(label);
      }

      Future<void> propertyText(String label, String value) async {
        final entry =
            _elements(
                  (w) => w is BusyMarkGroupedTextEntry && w.label == label,
                ).single.widget
                as BusyMarkGroupedTextEntry;
        await _tap(
          _elements(
            (w) => w is TextField && w.controller == entry.controller,
          ).single,
        );
        entry.controller!.text = value;
        await _native('chord', 'ctrl+s');
        await _until(
          () => !ref.read(workspaceControllerProvider).activeBuffer!.isDirty,
          'Focused $label saved',
        );
      }

      Future<void> reopenSource() async {
        final buffer = ref.read(workspaceControllerProvider).activeBuffer!;
        _check(await controller.saveActive(), 'Correction saves to buffer');
        _check(
          await controller.closeDocumentBuffer(buffer.id),
          'Correction closes document',
        );
        await controller.openActiveFile(buffer.filePath!);
        await _native('chord', 'ctrl+shift+2');
        await _until(
          () => _elements((w) => w is BusyMarkSourceEditor).isNotEmpty,
          'Correction Source reopened',
        );
      }

      void sourceCaret(int offset) {
        ((_elements((w) => w is BusyMarkSourceEditor).single as StatefulElement)
                    .state
                as BusyMarkSourceEditorState)
            .scrollToOffset(offset);
      }

      await controller.openActiveFile(
        p.join(widget.root.path, 'topics/inspector.topic'),
      );
      await _native('chord', 'ctrl+shift+2');
      await _pause();
      inspector().onTargetSelected('@topic');
      await _pause();
      for (final choice in [
        ('all', 'All titled elements'),
        ('none', 'No navigation'),
        ('default', 'Use default'),
      ]) {
        await chooseCombo('Navigation elements', choice.$2);
        _check(
          combo('Navigation elements').selected == choice.$1,
          'Navigation ${choice.$1} selected after native choice',
        );
        await reopenSource();
        sourceCaret(0);
        await _pause();
        inspector().onTargetSelected('@topic');
        await _pause();
        _check(
          combo('Navigation elements').selected == choice.$1,
          'Navigation ${choice.$1} survives save close reopen',
        );
      }
      await propertyText('Navigation elements', 'chapter,def');
      await reopenSource();
      sourceCaret(0);
      await _pause();
      inspector().onTargetSelected('@topic');
      await _pause();
      _check(
        combo('Navigation elements').selected == 'custom',
        'Custom navigation survives reopening',
      );
      await _capture('inspector-navigation-reopened');
      await controller.openActiveFile(
        p.join(widget.root.path, 'topics/inspector-corrections.md'),
      );
      await _native('chord', 'ctrl+shift+1');
      await _until(
        () => _elements(
          (w) =>
              w is TextField && w.controller?.text == 'Use {id="literal-code"}',
        ).isNotEmpty,
        'Literal inline code Editor loaded',
      );
      await _type(_field('Use {id="literal-code"}'), 'Try {id="literal-code"}');
      await _native('chord', 'ctrl+s');
      await reopenSource();
      _check(
        _source.contains('Try `{id="literal-code"}`'),
        'Ordinary content edit save reopen preserves inline code',
      );
      sourceCaret(_source.indexOf('Try'));
      await _pause();
      _check(
        inspector().target!.attributes['id'] == null,
        'Literal code is not a paragraph ID',
      );
      await _capture('inspector-inline-ownership-reopened');
      sourceCaret(_source.indexOf('Use [') + 1);
      await _pause();
      _check(
        inspector().target!.attributes['id'] == null &&
            inspector().target!.inlines.any(
              (i) => i.attributes['id'] == 'owned-link',
            ),
        'Trailing link attributes belong only to the link',
      );
      sourceCaret(_source.indexOf('- Second'));
      await _pause();
      final beforeItemUndo = ref
          .read(workspaceControllerProvider)
          .activeBuffer!
          .editorState
          .undoState
          .undo
          .length;
      await propertyText('Element ID', 'saved-item');
      _check(
        inspector().target!.attributes['id'] == 'saved-item' &&
            inspector().path.any((b) => b.attributes['element'] == 'list'),
        'Native item conversion retains inspected item and ancestry',
      );
      _check(
        ref
                .read(workspaceControllerProvider)
                .activeBuffer!
                .editorState
                .undoState
                .undo
                .length ==
            beforeItemUndo + 1,
        'Native item property creates exactly one undo operation',
      );
      _check(
        controller.undoActiveBuffer(),
        'Native item conversion undo succeeds',
      );
      await _pause();
      _check(
        _source.contains('- Second item') && !_source.contains('<list'),
        'Undo restores the native list',
      );
      _check(
        controller.redoActiveBuffer(),
        'Native item conversion redo succeeds',
      );
      await _pause();
      await reopenSource();
      sourceCaret(_source.indexOf('<li id="saved-item"'));
      await _pause();
      _check(
        inspector().target!.attributes['id'] == 'saved-item',
        'Item ID survives save close reopen reinspection',
      );
      await _capture('inspector-native-item-reopened');
      sourceCaret(_source.indexOf('- [ ] Unchecked task'));
      await _pause();
      await propertyText('Element ID', 'saved-task');
      await reopenSource();
      sourceCaret(_source.indexOf('<li id="saved-task"'));
      await _pause();
      _check(
        inspector().target!.kind == BusyBlockKind.taskListItem &&
            inspector().target!.attributes['task'] == 'false' &&
            inspector().target!.attributes['id'] == 'saved-task',
        'Task item ID and unchecked state survive property conversion and reopening',
      );
      _check(
        _source.contains('checked="true"') && !_source.contains(' task='),
        'Checked sibling survives without projection metadata in source',
      );
      await _capture('inspector-task-item-reopened');
      sourceCaret(_source.indexOf('> A'));
      await _pause();
      await propertyText('Element ID', 'saved-note');
      await reopenSource();
      sourceCaret(_source.indexOf('> A'));
      await _pause();
      _check(
        inspector().target!.attributes['id'] == 'saved-note' &&
            inspector().target!.attributes['style'] == 'note',
        'Native admonition ID and style survive save close reopen',
      );
      _check(
        _source.contains('> A **note**.\n\n{'),
        'Admonition attributes use the builder-verified blank-line placement',
      );
      await _capture('inspector-admonition-reopened');
      await File(
        p.join(widget.output.path, 'inspector-corrections.md'),
      ).writeAsString(_source);
      await controller.openPath('${widget.root.path}-defaults');
      await controller.openActiveFile(
        p.join('${widget.root.path}-defaults', 'topics/properties.topic'),
      );
      await _native('chord', 'ctrl+shift+2');
      await _until(
        () => _elements((w) => w is BusyMarkSourceEditor).isNotEmpty,
        'Module-default Source document loaded',
      );
      final defaultsSource = _source;
      final defaultsSourceState =
          (_elements((w) => w is BusyMarkSourceEditor).single
                      as StatefulElement)
                  .state
              as BusyMarkSourceEditorState;
      defaultsSourceState.scrollToOffset(
        _source.indexOf('<code-block id="code-block-absent"'),
      );
      await _pause();
      BusyMarkComboRow<String> defaultCombo(String title) =>
          _elements(
                (w) => w is BusyMarkComboRow<String> && w.title == title,
              ).single.widget
              as BusyMarkComboRow<String>;
      _check(
        defaultCombo('Collapsible').labelFor('') == 'Use default — Enabled' &&
            defaultCombo('Published initial state').labelFor('') ==
                'Use default — Expanded',
        'Inspector resolves omitted code properties from module defaults',
      );
      _check(
        _source == defaultsSource &&
            !ref.read(workspaceControllerProvider).activeBuffer!.isDirty,
        'Opening effective defaults is source-neutral',
      );
      await _capture('inspector-module-defaults');
      await _tap(
        _elements(
          (w) => w is BusyMarkComboRow<String> && w.title == 'Collapsible',
        ).single,
      );
      _nativeMenuOpen = true;
      await _tapLabel('Disabled');
      await _native('chord', 'ctrl+s');
      await _pause();
      _check(
        _source
            .substring(
              _source.indexOf('id="code-block-absent"'),
              _source.indexOf('>', _source.indexOf('id="code-block-absent"')),
            )
            .contains('collapsible="false"'),
        'Explicit false overrides the module collapse default',
      );
      await _capture('inspector-module-override');
      await _tap(
        _elements(
          (w) => w is BusyMarkComboRow<String> && w.title == 'Collapsible',
        ).single,
      );
      _nativeMenuOpen = true;
      await _tapLabel('Use default — Enabled');
      _check(
        _source == defaultsSource,
        'Reset removes local override and restores the module default',
      );
      sourceCaret(_source.indexOf('<deflist id="layout-default"'));
      await _pause();
      _check(
        combo('List layout').selected == '' &&
            combo('List layout').labelFor('') == 'Use default — Medium (1:2)',
        'Layout resolves the module medium default',
      );
      await _capture('inspector-module-layout-default');
      await chooseCombo('List layout', 'Wide');
      await reopenSource();
      sourceCaret(_source.indexOf('<deflist id="layout-default"'));
      await _pause();
      _check(
        combo('List layout').selected == 'wide' &&
            combo('List layout').labelFor('') == 'Use default — Medium (1:2)',
        'Layout override survives reopening and retains module reset label',
      );
      await _capture('inspector-module-layout-override');
      await chooseCombo('List layout', 'Use default — Medium (1:2)');
      await reopenSource();
      sourceCaret(_source.indexOf('<deflist id="layout-default"'));
      await _pause();
      _check(
        combo('List layout').selected == '' &&
            combo('List layout').labelFor('') == 'Use default — Medium (1:2)' &&
            _source == defaultsSource,
        'Layout reset removes local override and preserves module default after reopening',
      );
      await _capture('inspector-module-layout-reset');
      await controller.saveActive();
      final resize = _elements((w) => w is GestureDetector).firstWhere((e) {
        Element? ancestor = e;
        while (ancestor != null) {
          if (ancestor.widget.runtimeType.toString() ==
              '_ElementPropertiesResizeHandle') {
            return true;
          }
          Element? parent;
          ancestor.visitAncestorElements((e) {
            parent = e;
            return false;
          });
          ancestor = parent;
        }
        return false;
      });
      final preferredWidth = ref
          .read(appSettingsControllerProvider)
          .elementPropertiesWidth;
      Focus.of(resize).requestFocus();
      await _pause();
      await _native('chord', 'Left');
      _check(
        ref.read(appSettingsControllerProvider).elementPropertiesWidth ==
            preferredWidth + 20,
        'Native keyboard increases inspector width',
      );
      await _native('chord', 'Right');
      _check(
        ref.read(appSettingsControllerProvider).elementPropertiesWidth ==
            preferredWidth,
        'Native keyboard restores preferred inspector width',
      );
      sourceCaret(_source.indexOf('<code-block id="code-block-absent"'));
      await _pause();
      await _tap(
        _elements(
          (w) => w is TextField && w.controller?.text == 'code-block-absent',
        ).single,
      );
      await _native('chord', 'Tab');
      _check(
        FocusManager.instance.primaryFocus?.context
                ?.findAncestorWidgetOfExactType<
                  BusyMarkWritersideProperties
                >() !=
            null,
        'Native Tab traverses inspector controls',
      );
      await _tap(
        _elements(
          (w) => w is BusyMarkHeaderIconButton && w.tooltip == 'Close',
        ).singleWhere(
          (e) =>
              e.findAncestorWidgetOfExactType<BusyMarkWritersideProperties>() !=
              null,
        ),
      );
      await _until(
        () => _elements((w) => w is BusyMarkWritersideProperties).isEmpty,
        'Inspector closes without pending drafts',
      );
      _check(
        FocusManager.instance.primaryFocus?.context
                ?.findAncestorWidgetOfExactType<BusyMarkSourceEditor>() !=
            null,
        'Closing inspector restores Source editor focus',
      );
      await ref
          .read(appSettingsControllerProvider.notifier)
          .setElementPropertiesVisible(true);
      await controller.openPath(widget.root.path);
      await _native('chord', 'ctrl+shift+1');
      await controller.openActiveFile(p.join(widget.root.path, 'README.md'));
      await _until(
        () =>
            _elements((w) => w is BusyMarkWysiwygEditor).isNotEmpty &&
            _elements(
              (w) => w is TextField && w.controller?.text == 'Plain text',
            ).isNotEmpty,
        'Ordinary Markdown Editor available',
      );
      _check(
        _elements(
              (w) => w.key == const ValueKey('wysiwyg-writerside-insert'),
            ).isEmpty &&
            _elements((w) => w is BusyMarkWritersideProperties).isEmpty,
        'Ordinary Markdown has no Writerside controls or properties',
      );
      _check(
        ref.read(appSettingsControllerProvider).elementPropertiesVisible,
        'Inapplicable document preserves inspector visibility preference',
      );
      await _type(_field('Plain text'), 'Edited ordinary text');
      _check(
        _source.contains('# Ordinary Markdown') &&
            _source.contains('Edited ordinary text'),
        'Ordinary Markdown remains visually editable',
      );
      _check(await controller.saveActive(), 'Ordinary Markdown save succeeds');
      await _capture('authoring-ordinary-markdown');
      await File(p.join(widget.output.path, 'generated.topic')).writeAsString(
        await File(
          p.join(widget.root.path, 'topics/authoring.topic'),
        ).readAsString(),
      );
      await File(p.join(widget.output.path, 'generated.md')).writeAsString(
        await File(
          p.join(widget.root.path, 'topics/authoring-markdown.md'),
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
