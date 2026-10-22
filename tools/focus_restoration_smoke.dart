// Native focus acceptance entry point. Use only disposable, synthetic files and
// an isolated desktop/profile. All lifecycle events and text input come from
// the real GTK embedder. Measurements contain geometry and counts, never text.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:busymark/main.dart' as application;
import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/editor/source/source_editor.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:busymark/src/workspace/workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.length != 3) {
    throw ArgumentError(
      'DISPOSABLE_DOCUMENT OUTPUT_DIRECTORY editor|source|split|table',
    );
  }
  final binding = _Binding();
  await application.main([arguments[0]]);
  final output = Directory(arguments[1]);
  await output.create(recursive: true);
  unawaited(_Driver(binding, output, arguments[2]).run());
}

class _Binding extends WidgetsFlutterBinding {
  final root = GlobalKey();
  @override
  Widget wrapWithDefaultView(Widget rootWidget) =>
      super.wrapWithDefaultView(RepaintBoundary(key: root, child: rootWidget));
}

class _Driver with WidgetsBindingObserver {
  _Driver(this.binding, this.output, this.mode);
  final _Binding binding;
  final Directory output;
  final String mode;
  final frames = <Map<String, Object?>>[];
  TextField? target;
  ScrollPosition? position;
  bool recording = false;
  bool finished = false;
  int phase = 0;
  Element? readingAnchor;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    File('${output.path}/lifecycle').writeAsStringSync(state.name);
  }

  double? topOf(Element? element) {
    final render = element?.mounted == true
        ? element!.findRenderObject()
        : null;
    if (render is! RenderBox || !render.hasSize) return null;
    final top = render.localToGlobal(Offset.zero).dy;
    return top.isFinite ? top : null;
  }

  ScrollPosition? get currentPosition {
    if (mode == 'source' || mode == 'split') {
      return target?.scrollController?.hasClients == true
          ? target!.scrollController!.position
          : null;
    }
    final context = target?.focusNode?.context;
    return context == null
        ? null
        : Scrollable.maybeOf(context, axis: Axis.vertical)?.position;
  }

  List<Element> elements(bool Function(Widget) predicate, [Element? root]) {
    final result = <Element>[];
    void visit(Element e) {
      if (predicate(e.widget)) result.add(e);
      e.visitChildren(visit);
    }

    final context = binding.root.currentContext;
    if (context != null) visit(root ?? context as Element);
    return result;
  }

  Future<void> waitFor(bool Function() condition) async {
    final end = DateTime.now().add(const Duration(seconds: 45));
    while (!condition()) {
      if (DateTime.now().isAfter(end)) {
        throw StateError('Native prerequisite timed out in phase $phase');
      }
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
  }

  Future<void> signal(String value) =>
      File('${output.path}/$value').writeAsString('').then((_) {});
  Future<void> proceed(String value) =>
      waitFor(() => File('${output.path}/$value').existsSync());

  Map<String, Object?> measure(Duration stamp) => {
    'frameUs': stamp.inMicroseconds,
    'phase': phase,
    'lifecycle': binding.lifecycleState?.name,
    'focus': identical(FocusManager.instance.primaryFocus, target?.focusNode),
    'attached': target?.focusNode?.context?.mounted == true,
    'pixels': position?.pixels,
    'currentPixels': currentPosition?.pixels,
    'samePosition': identical(position, currentPosition),
    'readingAnchorY': topOf(readingAnchor),
    'targetY': topOf(target?.focusNode?.context as Element?),
    'base': target?.controller?.selection.baseOffset,
    'extent': target?.controller?.selection.extentOffset,
  };

  Future<void> run() async {
    try {
      await waitFor(
        () => elements(
          (w) => w is BusyMarkWysiwygEditor || w is BusyMarkSourceEditor,
        ).isNotEmpty,
      );
      final editor = elements(
        (w) => w is BusyMarkWysiwygEditor || w is BusyMarkSourceEditor,
      ).first;
      final container = ProviderScope.containerOf(editor, listen: false);
      final workspace = container.read(workspaceControllerProvider.notifier);
      if (mode == 'source' || mode == 'split') {
        workspace.updateActiveEditorMode(
          mode == 'source'
              ? DocumentViewModePreference.source
              : DocumentViewModePreference.split,
        );
        await waitFor(
          () => elements((w) => w is BusyMarkSourceEditor).isNotEmpty,
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 600));
      final fieldElements = elements(
        (w) => w is TextField && w.controller != null,
      );
      final fieldElement = mode == 'table'
          ? fieldElements.singleWhere(
              (e) => (e.widget as TextField).controller!.text == 'Focus cell',
            )
          : (mode == 'source' || mode == 'split')
          ? elements(
              (w) => w is TextField,
              elements((w) => w is BusyMarkSourceEditor).single,
            ).single
          : fieldElements.firstWhere(
              (e) => (e.widget as TextField).controller!.text.startsWith(
                'Focus target',
              ),
            );
      target = fieldElement.widget as TextField;
      target!.focusNode!.requestFocus();
      target!.controller!.selection = const TextSelection.collapsed(offset: 5);
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (mode == 'source' || mode == 'split') {
        position = target!.scrollController!.position;
      } else {
        final list = elements((w) => w is ScrollablePositionedList).single;
        position =
            (elements((w) => w is Scrollable, list).first as StatefulElement)
                    .state
                is ScrollableState
            ? ((elements((w) => w is Scrollable, list).first as StatefulElement)
                          .state
                      as ScrollableState)
                  .position
            : null;
      }
      if (position == null) throw StateError('Missing production viewport');
      position!.jumpTo(position!.pixels + 1900);
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (mode != 'source' && mode != 'split') {
        readingAnchor =
            elements(
                  (w) =>
                      w is TextField &&
                      w.controller?.text.startsWith('Reading paragraph') ==
                          true,
                )
                .where(
                  (element) =>
                      topOf(element) != null &&
                      topOf(element)! > 100 &&
                      topOf(element)! < 800,
                )
                .firstOrNull;
        if (readingAnchor == null) {
          throw StateError('Missing visible reading anchor');
        }
      }
      final readingTop = topOf(readingAnchor);
      final original = container
          .read(workspaceControllerProvider)
          .activeBuffer!;
      final source = original.text;
      final undoCount = original.editorState.undoState.undo.length;
      final redoCount = original.editorState.undoState.redo.length;
      final revision = workspace.editRevision;
      final selection = target!.controller!.selection;
      final insertionOffset = mode == 'source' || mode == 'split'
          ? selection.extentOffset
          : source.indexOf(target!.controller!.text) + selection.extentOffset;
      if (insertionOffset < selection.extentOffset) {
        throw StateError(
          'Synthetic target does not have an authored source position',
        );
      }
      final expectedInput = source.replaceRange(
        insertionOffset,
        insertionOffset,
        'z',
      );
      final offset = position!.pixels;
      binding.addPersistentFrameCallback((stamp) {
        if (recording && !finished) frames.add(measure(stamp));
      });
      recording = true;
      binding.addObserver(this);
      didChangeAppLifecycleState(binding.lifecycleState!);
      // The supervisor performs real window switches, a prolonged interval,
      // minimize/restore, and window-chrome reactivation before signalling.
      await signal('ready');
      var restoredWindow = false;
      await waitFor(() {
        if (!restoredWindow &&
            File('${output.path}/restore-window').existsSync()) {
          restoredWindow = true;
          unawaited(() async {
            await windowManager.restore();
            await windowManager.show();
            await windowManager.focus();
            await signal('window-restored');
          }());
        }
        return File('${output.path}/returned').existsSync();
      });
      await Future<void>.delayed(const Duration(milliseconds: 600));
      final current = container.read(workspaceControllerProvider).activeBuffer!;
      final passiveChecks = {
        'viewport': frames.every(
          (f) =>
              f['currentPixels'] is num &&
              ((f['currentPixels'] as num).toDouble() - offset).abs() < 0.1,
        ),
        'readingGeometry':
            readingAnchor == null ||
            frames.every(
              (f) =>
                  f['readingAnchorY'] is num &&
                  ((f['readingAnchorY'] as num).toDouble() - readingTop!)
                          .abs() <
                      0.1,
            ),
        'suspended': frames.any(
          (f) => f['lifecycle'] != 'resumed' && f['focus'] == false,
        ),
        'focus': identical(
          FocusManager.instance.primaryFocus,
          target!.focusNode,
        ),
        'selection': target!.controller!.selection == selection,
        'bytes': current.text == source,
        'undo': current.editorState.undoState.undo.length == undoCount,
        'redo': current.editorState.undoState.redo.length == redoCount,
        'dirty': current.dirty == original.dirty,
        'revision': workspace.editRevision == revision,
      };
      phase = 1;
      await File(
        '${output.path}/passive.json',
      ).writeAsString(jsonEncode(passiveChecks));
      await signal('type-ready');
      await proceed('typed');
      await Future<void>.delayed(const Duration(milliseconds: 600));
      final edited = container.read(workspaceControllerProvider).activeBuffer!;
      final targetTop = topOf(target?.focusNode?.context as Element?);
      final inputChecks = {
        'inputAtOriginalTarget': edited.text == expectedInput,
        'reveal': (currentPosition?.pixels ?? double.infinity) < offset - 100,
        'targetVisible': targetTop != null && targetTop >= 0 && targetTop < 900,
      };
      await File('${output.path}/result.json').writeAsString(
        jsonEncode({'passive': passiveChecks, 'input': inputChecks}),
      );
      await File(
        '${output.path}/frames.json',
      ).writeAsString(jsonEncode(frames));
      finished = true;
      await signal('done');
    } catch (error, stack) {
      finished = true;
      await File('${output.path}/error.txt').writeAsString('$error\n$stack');
      await signal('done');
    } finally {
      binding.removeObserver(this);
    }
  }
}
