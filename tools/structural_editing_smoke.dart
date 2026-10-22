// Native acceptance entry point: production app, editors, source publication,
// history and saving. Only disposable fixtures/profiles may be used.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:busymark/main.dart' as application;
import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/busymark_glyphs.dart';
import 'package:busymark/src/app/keymap_controller.dart';
import 'package:busymark/src/app/shortcut_binding.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_block_widgets.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_inline_controller.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/workspace/workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.length != 2 ||
      Platform.environment['BUSYMARK_STRUCTURAL_ACCEPTANCE'] != '1') {
    throw ArgumentError(
      'Use structural_editing_native.py with a disposable desktop',
    );
  }
  final binding = _Binding();
  final fixtures = Directory(arguments[0]);
  await application.main(['${fixtures.path}/markdown/header_test_text.md']);
  unawaited(_Driver(binding, fixtures, Directory(arguments[1])).run());
}

class _Binding extends WidgetsFlutterBinding {
  final root = GlobalKey();
  @override
  Widget wrapWithDefaultView(Widget rootWidget) =>
      super.wrapWithDefaultView(RepaintBoundary(key: root, child: rootWidget));
}

class _Driver {
  _Driver(this.binding, this.fixtures, this.output);
  final _Binding binding;
  final Directory fixtures;
  final Directory output;
  final checks = <String>[];
  late ProviderContainer container;
  WorkspaceController get workspace =>
      container.read(workspaceControllerProvider.notifier);
  String get source => container.read(workspaceControllerProvider).activeText;

  List<Element> elements(bool Function(Widget) predicate) {
    final found = <Element>[];
    void visit(Element element) {
      if (predicate(element.widget)) found.add(element);
      element.visitChildren(visit);
    }

    final root = binding.root.currentContext;
    if (root != null) visit(root as Element);
    return found;
  }

  Future<void> waitFor(bool Function() condition, String label) async {
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (!condition()) {
      if (DateTime.now().isAfter(deadline)) {
        throw StateError('Timed out: $label');
      }
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
  }

  Future<void> settle() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    binding.scheduleFrame();
    await binding.endOfFrame;
  }

  void check(bool value, String label) {
    if (!value) throw StateError(label);
    checks.add(label);
    stdout.writeln('structural acceptance: $label');
  }

  Future<void> native(List<String> chord) async {
    final result = await Process.run('/usr/bin/python3', [
      'tools/structural_editing_native.py',
      '--key',
      '$pid',
      ...chord,
    ]);
    if (result.exitCode != 0) {
      throw StateError('Native input: ${result.stderr}');
    }
    await settle();
  }

  TextField field(String text) => elements(
    (w) => w is TextField && w.controller?.text == text,
  ).map((e) => e.widget as TextField).single;
  BusyBlock block(String id) => elements(
    (w) => w is BusyMarkWysiwygBlockField && w.block.id == id,
  ).map((e) => (e.widget as BusyMarkWysiwygBlockField).block).single;
  BusyBlock namedBlock(String text) => elements(
    (w) => w is BusyMarkWysiwygBlockField && w.block.plainText == text,
  ).map((e) => (e.widget as BusyMarkWysiwygBlockField).block).single;

  Future<TextField> focus(
    String text, {
    int offset = 0,
    bool selectAll = false,
  }) async {
    final target = field(text);
    target.focusNode!.requestFocus();
    target.controller!.selection = selectAll
        ? TextSelection(baseOffset: 0, extentOffset: text.length)
        : TextSelection.collapsed(offset: offset);
    await settle();
    return target;
  }

  Future<void> open(String path) async {
    if (!await workspace.openActiveFile(path)) {
      throw StateError('Could not open fixture within its workspace: $path');
    }
    workspace.updateActiveEditorMode(DocumentViewModePreference.editor);
    await waitFor(
      () =>
          elements(
            (w) => w is BusyMarkWysiwygEditor && w.document.filePath == path,
          ).isNotEmpty &&
          container.read(workspaceControllerProvider).activeBuffer?.filePath ==
              path,
      'open $path',
    );
    await settle();
  }

  Future<void> capture(String name) async {
    final boundary =
        binding.root.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    await File(
      '${output.path}/$name.png',
    ).writeAsBytes(bytes.buffer.asUint8List());
    image.dispose();
  }

  Future<void> saveAndReopen(String name) async {
    final saved = source;
    final file = File(
      container.read(workspaceControllerProvider).activeBuffer!.filePath!,
    );
    await native(['Control_L', 's']);
    await waitFor(
      () =>
          file.readAsStringSync() == saved &&
          !container.read(workspaceControllerProvider).activeBuffer!.isDirty,
      '$name native save',
    );
    await File(
      '${output.path}/$name-saved${file.path.endsWith('.topic') ? '.topic' : '.md'}',
    ).writeAsString(file.readAsStringSync());
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    final closeObservations = <Map<String, Object?>>[];
    while (true) {
      final captured = container
          .read(workspaceControllerProvider)
          .activeBuffer!;
      if (captured.text != saved ||
          captured.isDirty ||
          captured.filePath != file.path) {
        throw StateError('$name saved buffer changed before close');
      }
      if (await workspace.closeActiveOpenFileTab()) break;
      final current = container.read(workspaceControllerProvider).activeBuffer;
      closeObservations.add({
        'sameBufferSnapshot': identical(captured, current),
        'sameId': current?.id == captured.id,
        'sameRevision': current?.revision == captured.revision,
        'sameBytes': current?.text == saved,
        'dirty': current?.isDirty,
      });
      // A session report can replace the captured immutable buffer during the
      // real History flush. Respect that rejection; retry only unchanged saved
      // content after another actual frame, never a changed target or edit.
      if (current?.id != captured.id ||
          current?.text != saved ||
          current?.isDirty != false ||
          identical(captured, current) ||
          DateTime.now().isAfter(deadline)) {
        await File(
          '${output.path}/$name-close.json',
        ).writeAsString(jsonEncode(closeObservations));
        throw StateError(
          '$name close rejected without an unchanged replacement snapshot',
        );
      }
      await settle();
    }
    await File(
      '${output.path}/$name-close.json',
    ).writeAsString(jsonEncode(closeObservations));
    check(true, '$name close saved buffer');
    await open(file.path);
    check(source == saved, '$name reopened bytes');
  }

  Future<void> heading(String path, String name) async {
    await open(path);
    final original = source;
    final target = await focus('About the job');
    final before = namedBlock('About the job');
    if (name == 'writerside') {
      check(
        before.attributes['collapsible'] == 'true' &&
            before.attributes['default-state'] == 'expanded',
        'Writerside authored fixture mode',
      );
    }
    final undo = container
        .read(workspaceControllerProvider)
        .activeBuffer!
        .editorState
        .undoState
        .undo
        .length;
    await native(['Return']);
    final kept = namedBlock('About the job');
    check(
      kept.id == before.id &&
          kept.kind == BusyBlockKind.heading &&
          kept.attributes['level'] == '2',
      '$name heading identity and level',
    );
    for (final key in ['id', 'generatedId', 'collapsible', 'default-state']) {
      check(
        kept.attributes[key] == before.attributes[key],
        '$name heading $key',
      );
    }
    check(
      field('About the job').focusNode == target.focusNode &&
          target.focusNode!.hasFocus &&
          target.controller!.selection.extentOffset == 0,
      '$name caret and focus',
    );
    check(
      container
              .read(workspaceControllerProvider)
              .activeBuffer!
              .editorState
              .undoState
              .undo
              .length ==
          undo + 1,
      '$name one undo operation',
    );
    check(
      elements(
        (w) =>
            w is BusyMarkWysiwygBlockField &&
            w.block.kind == BusyBlockKind.paragraph &&
            w.block.plainText.isEmpty &&
            !w.block.attributes.containsKey('collapsible'),
      ).isNotEmpty,
      '$name ordinary preceding paragraph',
    );
    await capture('$name-enter');
    await native(['BackSpace']);
    check(source == original, '$name immediate Backspace inverse source');
    check(
      namedBlock('About the job').id == before.id,
      '$name immediate Backspace inverse identity',
    );
    await native(['Return']);
    final entered = source;
    await native(['Control_L', 'z']);
    check(source == original, '$name undo');
    await native(['Control_L', 'Shift_L', 'z']);
    check(
      source == entered &&
          namedBlock('About the job').kind == BusyBlockKind.heading,
      '$name redo source and heading',
    );
    check(
      elements(
        (w) =>
            w is BusyMarkWysiwygBlockField &&
            w.block.kind == BusyBlockKind.paragraph &&
            w.block.plainText.isEmpty,
      ).isEmpty,
      '$name redo respects transient blank-paragraph lifecycle',
    );
    await native(['Control_L', 'z']);
    await native(['Return']);
    await native(['z']);
    check(
      source.contains('## zAbout the job'),
      '$name native typing in original heading',
    );
    final saved = source;
    for (final mode in [
      DocumentViewModePreference.source,
      DocumentViewModePreference.preview,
      DocumentViewModePreference.split,
      DocumentViewModePreference.editor,
    ]) {
      workspace.updateActiveEditorMode(mode);
      await settle();
      check(source == saved, '$name ${mode.name} source');
    }
    await saveAndReopen(name);
    final reopened = namedBlock('zAbout the job');
    check(
      reopened.kind == BusyBlockKind.heading &&
          reopened.attributes['level'] == '2' &&
          reopened.attributes['collapsible'] ==
              before.attributes['collapsible'],
      '$name reopened heading properties',
    );
  }

  Future<void> lists() async {
    var sequence = 0;
    for (final label in ['Parent', 'Ordered parent', 'Task parent']) {
      for (final clear in [false, true]) {
        final name = 'list-${sequence++}';
        final file = await File(
          '${fixtures.path}/markdown/lists.md',
        ).copy('${fixtures.path}/markdown/$name.md');
        await open(file.path);
        final before = namedBlock(label);
        final target = await focus(label, selectAll: clear);
        if (clear) {
          await native(['BackSpace']);
          check(
            block(before.id).plainText.isEmpty,
            '$name cleared only parent caption',
          );
        }
        await native(['Return']);
        final parent = block(before.id);
        check(
          parent.kind == before.kind &&
              _descendants(parent).map((b) => b.id).join(',') ==
                  _descendants(before).map((b) => b.id).join(','),
          '$name parent/subtree identity',
        );
        check(
          target.focusNode!.hasFocus &&
              target.controller!.selection.extentOffset == 0,
          '$name focus retained',
        );
        await native(['z']);
        check(
          block(before.id).plainText == 'z${clear ? '' : label}',
          '$name original parent receives input',
        );
        await saveAndReopen(name);
        final reparsed = const MarkdownParser()
            .parse(filePath: file.path, source: source)
            .busyDocument;
        final reopenedParent = _walk(
          reparsed.blocks,
        ).singleWhere((b) => b.plainText == 'z${clear ? '' : label}');
        check(
          _descendants(reopenedParent).map((b) => b.plainText).join('\u0000') ==
              _descendants(before).map((b) => b.plainText).join('\u0000'),
          '$name reopened subtree stays with parent in order',
        );
        if (label == 'Task parent') {
          check(
            _walk(
                  reparsed.blocks,
                ).where((b) => b.kind == BusyBlockKind.taskListItem).length ==
                4,
            '$name empty task keeps checkbox semantics',
          );
        }
        for (final child in [
          'Child',
          'Grandchild',
          'Ordered child',
          'Ordered grandchild',
          'Task child',
          'Task grandchild',
        ]) {
          check(
            _walk(reparsed.blocks).where((b) => b.plainText == child).length ==
                1,
            '$name $child exactly once after reopening',
          );
        }
        await capture(name);
      }
    }
  }

  Future<void> images() async {
    final file = '${fixtures.path}/markdown/inline-objects.md';
    await open(file);
    final before = source;
    final expected = _objects(namedBlock('abc'));
    await focus('abc', offset: 1);
    await native(['Shift_L', 'Return']);
    check(
      _objects(namedBlock('a\nbc')) == expected,
      'image Shift-Enter preserves objects and formatting',
    );
    check(
      field('a\nbc').focusNode!.hasFocus &&
          field('a\nbc').controller!.selection.extentOffset == 2,
      'image hard-break caret and focus',
    );
    await native(['Control_L', 'z']);
    check(source == before, 'image hard-break undo');
    final current = container
        .read(appSettingsControllerProvider)
        .shortcutOverrides;
    final configured = await container
        .read(keymapControllerProvider.notifier)
        .update(
          'editor.hardLineBreak',
          const BusyMarkKeyBinding(LogicalKeyboardKey.f8),
          expected: current,
        );
    check(
      configured.status == KeymapUpdateStatus.saved,
      'configured hard-break shortcut',
    );
    await focus('abc', offset: 1);
    await native(['F8']);
    check(
      _objects(namedBlock('a\nbc')) == expected,
      'configured hard-break preserves objects',
    );
    await native(['Control_L', 'z']);
    await focus('abc', offset: 1);
    final button = elements(
      (w) =>
          w is BusyMarkHeaderIconButton && w.icon == BusyMarkGlyphs.blankLine,
    ).single;
    final render = button.findRenderObject()! as RenderBox;
    final point = render.localToGlobal(render.size.center(Offset.zero));
    final click = await Process.run('/usr/bin/python3', [
      'tools/structural_editing_native.py',
      '--click',
      '$pid',
      '${point.dx}',
      '${point.dy}',
    ]);
    if (click.exitCode != 0) throw StateError('${click.stderr}');
    await settle();
    check(
      _objects(namedBlock('a\n\nbc')) == expected,
      'native blank-line toolbar preserves objects',
    );
    check(
      field('a\n\nbc').focusNode!.hasFocus &&
          field('a\n\nbc').controller!.selection.extentOffset == 3,
      'image blank-line caret and focus',
    );
    await saveAndReopen('images');
    check(
      _objects(namedBlock('a\n\nbc')) == expected,
      'saved/reopened objects retain order, destinations and formatting',
    );
    await capture('images');
  }

  Future<void> run() async {
    var passed = false;
    String? error;
    try {
      await waitFor(
        () => elements((w) => w is BusyMarkWysiwygEditor).isNotEmpty,
        'production app startup',
      );
      container = ProviderScope.containerOf(
        elements((w) => w is BusyMarkWysiwygEditor).single,
      );
      final settings = container.read(appSettingsControllerProvider.notifier);
      await settings.setAutoSave(false);
      await settings.setAutomaticSpelling(false);
      await settings.setDocumentViewMode(DocumentViewModePreference.editor);
      await heading(
        '${fixtures.path}/markdown/header_test_text.md',
        'markdown',
      );
      // openPath selects a workspace; openActiveFile opens a topic within it.
      // Keep the project context that determines Writerside Markdown mode.
      await workspace.openPath('${fixtures.path}/writerside');
      await heading(
        '${fixtures.path}/writerside/topics/structure.md',
        'writerside',
      );
      await workspace.openPath('${fixtures.path}/markdown');
      await lists();
      await images();
      passed = true;
    } catch (exception, stack) {
      error = '$exception\n$stack';
    }
    await File('${output.path}/result.json').writeAsString(
      const JsonEncoder.withIndent(
        '  ',
      ).convert({'passed': passed, 'checks': checks, 'error': error}),
    );
    // Exit through the production close listener with all test edits saved.
    if (!passed) {
      stderr.writeln(error);
      if (checks.isNotEmpty) {
        await File('${output.path}/failure-source.md').writeAsString(source);
      }
      exit(1);
    }
    await windowManager.close();
  }
}

Iterable<BusyBlock> _walk(Iterable<BusyBlock> blocks) sync* {
  for (final block in blocks) {
    yield block;
    yield* _walk(block.children);
  }
}

Iterable<BusyBlock> _descendants(BusyBlock block) => _walk(block.children);
String _objects(BusyBlock block) => jsonEncode([
  for (final anchor in busyInlineSemanticAnchors(block.inlines))
    _inline(anchor.inline),
]);
Object _inline(BusyInline inline) => [
  inline.kind.name,
  inline.text,
  inline.destination,
  inline.attributes,
  [for (final child in inline.children) _inline(child)],
];
