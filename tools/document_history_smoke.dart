// Native Linux document-history acceptance. All typing and Undo/Redo below use
// XTest through GTK. Controllers only set up modes/tabs and invoke app commands.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:busymark/main.dart' as application;
import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/editor/source/source_editor.dart';
import 'package:busymark/src/editor/source_highlighter.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_inline_controller.dart';
import 'package:busymark/src/local_history/local_history_controller.dart';
import 'package:busymark/src/local_history/local_history_models.dart';
import 'package:busymark/src/workspace/document_buffer.dart';
import 'package:busymark/src/workspace/workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main(List<String> args) async {
  if (args.length != 1 ||
      Platform.environment['BUSYMARK_HISTORY_DISPOSABLE'] != '1') {
    throw ArgumentError(
      'Requires OUTPUT_DIRECTORY and BUSYMARK_HISTORY_DISPOSABLE=1 on a disposable X11 display',
    );
  }
  final root = Directory(args.single).absolute;
  final data = Platform.environment['XDG_DATA_HOME'] ?? '';
  if (!data.startsWith('${root.path}/') ||
      Platform.environment['GDK_BACKEND'] != 'x11') {
    throw ArgumentError(
      'Application support and the X11 display must be isolated',
    );
  }
  await root.create(recursive: true);
  _NativeTrace.file = File('${root.path}/platform.jsonl');
  _HistoryProbeBinding();
  HardwareKeyboard.instance.addHandler((event) {
    _NativeTrace.write({
      'event': 'key',
      'down': event is KeyDownEvent,
      'up': event is KeyUpEvent,
      'logical': event.logicalKey.keyLabel,
      'control': HardwareKeyboard.instance.isControlPressed,
      'shift': HardwareKeyboard.instance.isShiftPressed,
    });
    return false;
  });
  final initial = File('${root.path}/source.md');
  await initial.writeAsString('abc');
  await File('${root.path}/editor.md').writeAsString('abc');
  await File('${root.path}/other.md').writeAsString('other');
  await application.main([initial.path]);
  unawaited(_Driver(root).run());
}

class _NativeTrace {
  static late File file;
  static final clock = Stopwatch()..start();
  static void write(Map<String, Object?> event) => file.writeAsStringSync(
    '${jsonEncode({'elapsedUs': clock.elapsedMicroseconds, ...event})}\n',
    mode: FileMode.append,
  );
}

// Observe the production text-input channel while forwarding every request.
class _HistoryProbeBinding extends WidgetsFlutterBinding {
  @override
  BinaryMessenger createBinaryMessenger() =>
      _HistoryProbeMessenger(super.createBinaryMessenger());
}

class _HistoryProbeMessenger extends BinaryMessenger {
  _HistoryProbeMessenger(this.delegate);
  final BinaryMessenger delegate;
  void record(String direction, String channel, ByteData? message) {
    if (channel != SystemChannels.textInput.name || message == null) return;
    final call = SystemChannels.textInput.codec.decodeMethodCall(message);
    if (const {
      'TextInput.setClient',
      'TextInput.clearClient',
      'TextInput.setEditingState',
      'TextInput.show',
      'TextInput.hide',
      'TextInputClient.updateEditingState',
      'TextInputClient.updateEditingStateWithDeltas',
      'TextInputClient.performAction',
    }.contains(call.method)) {
      _NativeTrace.write({
        'direction': direction,
        'method': call.method,
        'arguments': call.arguments,
      });
    }
  }

  @override
  Future<ByteData?>? send(String channel, ByteData? message) {
    record('out', channel, message);
    return delegate.send(channel, message);
  }

  @override
  void setMessageHandler(String channel, MessageHandler? handler) =>
      delegate.setMessageHandler(
        channel,
        handler == null
            ? null
            : (message) {
                record('in', channel, message);
                return handler(message);
              },
      );
  @override
  Future<void> handlePlatformMessage(
    String channel,
    ByteData? data,
    ui.PlatformMessageResponseCallback? callback,
  ) async {
    ServicesBinding.instance.channelBuffers.push(
      channel,
      data,
      callback ?? (_) {},
    );
  }
}

class _Driver {
  _Driver(this.root);
  final Directory root;
  final checks = <String>[];
  late ProviderContainer container;
  WorkspaceController get controller =>
      container.read(workspaceControllerProvider.notifier);
  DocumentBuffer get buffer =>
      container.read(workspaceControllerProvider).activeBuffer!;

  Iterable<Element> elements() sync* {
    final all = <Element>[];
    void visit(Element e) {
      all.add(e);
      e.visitChildren(visit);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(visit);
    yield* all;
  }

  TextField get field => elements()
      .map((e) => e.widget)
      .whereType<TextField>()
      .firstWhere(
        (f) =>
            f.controller is BusyMarkSourceEditingController ||
            f.controller is BusyMarkWysiwygTextController,
      );

  Future<void> until(bool Function() condition, String operation) async {
    final timeout = Stopwatch()..start();
    while (!condition()) {
      if (timeout.elapsed > const Duration(seconds: 25)) {
        throw StateError(
          'Timeout: $operation; source=${buffer.text} '
          'visible=${field.controller!.text} focus=${field.focusNode!.hasPrimaryFocus} '
          'revision=${buffer.revision}',
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  void check(bool condition, String name) {
    if (!condition) {
      throw StateError(
        '$name; buffer=${buffer.text} visible=${field.controller!.text}',
      );
    }
    checks.add(name);
    stdout.writeln('PASS $name');
  }

  Future<void> focusEnd() async {
    field.focusNode!.requestFocus();
    field.controller!.selection = TextSelection.collapsed(
      offset: field.controller!.text.length,
    );
    await windowManager.focus();
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  Future<void> key(List<String> keys) async {
    await _recordInput('before', keys);
    final result = await Process.run('python3', ['-c', _nativeKeys, ...keys]);
    if (result.exitCode != 0) throw StateError('XTest: ${result.stderr}');
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await _recordInput('after', keys);
  }

  Future<void> _recordInput(String phase, List<String> keys) async {
    final source = elements()
        .whereType<StatefulElement>()
        .map((e) => e.state)
        .whereType<BusyMarkSourceEditorState>()
        .firstOrNull;
    final event = {
      'phase': phase,
      'keys': keys,
      'source': buffer.text,
      'revision': buffer.revision,
      'visible': field.controller!.text,
      'selectionBase': field.controller!.selection.baseOffset,
      'selectionExtent': field.controller!.selection.extentOffset,
      'focus': field.focusNode!.hasPrimaryFocus,
      'readOnly': field.readOnly,
      'bufferReadOnly': buffer.readonly,
      'filePath': buffer.filePath,
      'editorPath': source?.widget.filePath,
      'publicationSource': source?.publicationBase.source,
      'publicationRevision': source?.publicationBase.revision,
    };
    await File('${root.path}/input.jsonl').writeAsString(
      '${jsonEncode(event)}\n',
      mode: FileMode.append,
      flush: true,
    );
  }

  Future<void> text(String expected) async {
    await until(
      () => buffer.text == expected && field.controller!.text == expected,
      'text $expected',
    );
    final rich = elements()
        .map((e) => e.widget)
        .whereType<BusyMarkWysiwygEditor>()
        .firstOrNull;
    if (rich != null) {
      check(
        rich.document.source == expected,
        'rich projection agrees with buffer',
      );
      final state = elements()
          .whereType<StatefulElement>()
          .map((e) => e.state)
          .whereType<BusyMarkWysiwygEditorState>()
          .first;
      check(
        state.serializedSource == expected,
        'rich serialization agrees with buffer',
      );
    }
  }

  Future<void> undo(String expected) async {
    await key(['Control_L', 'z']);
    await text(expected);
  }

  Future<void> redo(String expected) async {
    await key(['Control_L', 'Shift_L', 'z']);
    await text(expected);
  }

  Future<void> mode(DocumentViewModePreference mode) async {
    controller.updateActiveEditorMode(mode);
    await container
        .read(appSettingsControllerProvider.notifier)
        .setDocumentViewMode(mode);
    await until(
      () => elements().any(
        (e) => mode == DocumentViewModePreference.source
            ? e.widget is BusyMarkSourceEditor
            : e.widget is BusyMarkWysiwygEditor,
      ),
      'mode ${mode.name}',
    );
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }

  Future<void> saved(String expected) async {
    await until(() => !buffer.isDirty, 'autosave');
    check(
      await File(buffer.filePath!).readAsString() == expected,
      'saved bytes equal $expected',
    );
  }

  Future<void> run() async {
    Object? failure;
    try {
      await until(
        () => elements().any(
          (e) =>
              e.widget is BusyMarkWysiwygEditor ||
              e.widget is BusyMarkSourceEditor,
        ),
        'initial editor',
      );
      final editor = elements().firstWhere(
        (e) =>
            e.widget is BusyMarkWysiwygEditor ||
            e.widget is BusyMarkSourceEditor,
      );
      container = ProviderScope.containerOf(editor, listen: false);
      final settings = container.read(appSettingsControllerProvider.notifier);
      await settings.setAutoSave(false);
      await settings.setValidateOnEdit(false);
      for (final editingMode in [
        DocumentViewModePreference.source,
        DocumentViewModePreference.editor,
      ]) {
        final name = editingMode.name;
        final path =
            '${root.path}/${name == 'source' ? 'source' : 'editor'}.md';
        if (buffer.filePath != path) await controller.openActiveFile(path);
        await mode(editingMode);
        await text('abc');
        await focusEnd();
        await key(['x']);
        await text('abcx');
        await key(['y']);
        await text('abcxy');
        // Native/JIT work can cross the real idle boundary on a loaded host.
        // Traverse each actual transaction, then verify the known baseline.
        final latestTypingBaseline =
            buffer.editorState.undoState.undo.last.text;
        while (buffer.editorState.undoState.undo.isNotEmpty) {
          await undo(buffer.editorState.undoState.undo.last.text);
        }
        await text('abc');
        var revision = buffer.revision;
        final exhausted = buffer.editorState.undoState;
        for (var i = 0; i < 3; i++) {
          await key(['Control_L', 'z']);
        }
        check(
          buffer.revision == revision &&
              identical(buffer.editorState.undoState, exhausted) &&
              buffer.text == 'abc',
          '$name exhausted Undo is unchanged',
        );
        while (buffer.editorState.undoState.redo.isNotEmpty) {
          await redo(buffer.editorState.undoState.redo.last.text);
        }
        await text('abcxy');
        revision = buffer.revision;
        for (var i = 0; i < 3; i++) {
          await key(['Control_L', 'Shift_L', 'z']);
        }
        check(
          buffer.revision == revision && buffer.text == 'abcxy',
          '$name exhausted Redo is unchanged',
        );
        for (var i = 0; i < 5; i++) {
          await undo(latestTypingBaseline);
          await redo('abcxy');
        }
        check(true, '$name native rapid alternation');

        controller.updateActiveEditorMode(DocumentViewModePreference.preview);
        await settings.setDocumentViewMode(DocumentViewModePreference.preview);
        await until(
          () => !elements().any(
            (e) =>
                e.widget is BusyMarkSourceEditor ||
                e.widget is BusyMarkWysiwygEditor,
          ),
          'reading mode',
        );
        await mode(editingMode);
        await focusEnd();
        await key(['z']);
        await text('abcxyz');
        await undo('abcxy');
        await redo('abcxyz');
        check(true, '$name remount keeps the earlier session');
        final id = buffer.id;
        await controller.openActiveFile('${root.path}/other.md');
        await controller.activateDocumentBuffer(id);
        await text('abcxyz');
        await focusEnd();
        await key(['q']);
        await text('abcxyzq');
        await undo('abcxyz');
        check(true, '$name tab return creates a separate transaction');

        await settings.setAutoSave(true);
        await focusEnd();
        await key(['k']);
        await text('abcxyzk');
        await undo('abcxyz');
        await key(['v']);
        await text('abcxyzv');
        await saved('abcxyzv');
        final history = container.read(localHistoryControllerProvider.notifier);
        check(
          await history.flushAll(
            container.read(workspaceControllerProvider).documentBuffers,
          ),
          '$name history settled',
        );
        final store = container.read(localHistoryStoreProvider);
        var snapshot = await store.load();
        LocalHistoryRevision? protected;
        for (final summary in snapshot.revisions) {
          final candidate = await store.readRevision(summary.id);
          if (candidate?.source == 'abcxyzk') protected = candidate;
        }
        check(protected != null, '$name original pre-Undo work persisted');
        check(
          await controller.closeDocumentBuffer(id),
          '$name closes saved branch',
        );
        await controller.openActiveFile(path);
        await mode(editingMode);
        await text('abcxyzv');
        snapshot = await store.load();
        final historyDocument = snapshot.documents.firstWhere(
          (d) => d.id == protected!.summary.documentId,
        );
        check(
          await controller.restoreLocalHistoryRevision(
            document: historyDocument,
            revision: protected!,
          ),
          '$name Local History restores original work',
        );
        await text('abcxyzk');
        await focusEnd();
        await undo('abcxyzv');
        await redo('abcxyzk');
        check(true, '$name restore is one native undo/redo boundary');

        await settings.setAutoSave(false);
        await focusEnd();
        await key(['r']);
        await text('abcxyzkr');
        await key(['Left']);
        await key(['Right']);
        await key(['s']);
        await text('abcxyzkrs');
        await undo('abcxyzkr'); // Dirty, with both stacks populated.
        await File(path).writeAsString('disk replacement');
        await until(
          () => buffer.hasConflict,
          'monitor reports the external conflict',
        );
        check(
          await controller.reloadBufferFromDisk(buffer.id),
          '$name reload succeeds',
        );
        await text('disk replacement');
        revision = buffer.revision;
        await key(['Control_L', 'Shift_L', 'z']);
        check(
          buffer.revision == revision && buffer.text == 'disk replacement',
          '$name reload invalidates old redo',
        );
        await focusEnd();
        await undo('abcxyzkr');
        await redo('disk replacement');
        check(true, '$name displaced source survives reload');
        await controller.saveActive();
      }
      await controller.markCleanShutdown();
    } catch (error, stack) {
      failure = error;
      stderr.writeln('$error\n$stack');
    }
    await File('${root.path}/result.json').writeAsString(
      jsonEncode({
        'passed': failure == null,
        'checks': checks,
        'failure': failure?.toString(),
      }),
      flush: true,
    );
    exit(failure == null ? 0 : 1);
  }
}

const _nativeKeys = r'''
import ctypes as C, ctypes.util, os, sys, time
x=C.CDLL(ctypes.util.find_library('X11')); t=C.CDLL(ctypes.util.find_library('Xtst'))
x.XOpenDisplay.argtypes=[C.c_char_p]; x.XOpenDisplay.restype=C.c_void_p
x.XStringToKeysym.argtypes=[C.c_char_p]; x.XStringToKeysym.restype=C.c_ulong
x.XKeysymToKeycode.argtypes=[C.c_void_p,C.c_ulong]; x.XKeysymToKeycode.restype=C.c_uint
x.XSync.argtypes=[C.c_void_p,C.c_int]; x.XCloseDisplay.argtypes=[C.c_void_p]
t.XTestFakeKeyEvent.argtypes=[C.c_void_p,C.c_uint,C.c_int,C.c_ulong]
d=x.XOpenDisplay(os.environ['DISPLAY'].encode())
if not d: raise RuntimeError('No disposable X11 display')
try:
 codes=[x.XKeysymToKeycode(d,x.XStringToKeysym(k.encode())) for k in sys.argv[1:]]
 for code,pressed in [(c,1) for c in codes]+[(c,0) for c in reversed(codes)]:
  if not code or not t.XTestFakeKeyEvent(d,code,pressed,0): raise RuntimeError('Native key failed')
  x.XSync(d,0)
  time.sleep(0.015)
 x.XSync(d,0)
finally: x.XCloseDisplay(d)
''';
