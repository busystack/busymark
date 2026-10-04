import 'dart:async';
import 'dart:convert';

import 'package:busymark/src/clipboard/clipboard_insertion.dart';
import 'package:busymark/src/clipboard/clipboard_models.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_block_widgets.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_session_state.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/platform/rich_clipboard_service.dart';
import 'package:busymark/src/workspace/document_buffer.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../support/memory_rich_clipboard.dart';
import '../support/wysiwyg_editable_harness.dart';

const _table =
    '| Header | Longer header |\n| --- | --- |\n| Short | Body text |\n| Last | End! |\n';
const _before = 'Before stays.';
const _after = 'After stays.';
const _surrounded = '$_before\n\n$_table\n$_after\n';
const _protected = '> [guide]: docs.md\n>\n> Original\n\nOutside\n';
const _secondTable =
    '| Second | Other header |\n| --- | --- |\n| Two | Another body |\n| Final | Done! |\n';
const _emptyTable = '|  |  |\n| --- | --- |\n|  |  |\n';
const _fixtures = [
  (name: 'table-only', source: _table),
  (name: 'leading table', source: '$_table\n$_after\n'),
  (name: 'trailing table', source: '$_before\n\n$_table'),
  (name: 'consecutive tables', source: '$_table\n$_secondTable'),
  (name: 'text control', source: 'First.\n\nMiddle.\n\nLast.\n'),
];

class _DelayedClipboard extends MemoryRichClipboard {
  Completer<void>? readGate;
  Completer<void>? writeGate;
  bool readFails = false;
  int reads = 0;
  int writes = 0;

  @override
  Future<RichClipboardData> read() async {
    reads++;
    await readGate?.future;
    return readFails ? const RichClipboardData() : data;
  }

  @override
  Future<bool> write(RichClipboardData value) async {
    writes++;
    await writeGate?.future;
    return super.write(value);
  }
}

Finder _field(String text) =>
    find.byWidgetPredicate((w) => w is TextField && w.controller?.text == text);

EditableTextState _editable(WidgetTester tester, Finder field) =>
    tester.state<EditableTextState>(
      find.descendant(of: field, matching: find.byType(EditableText)),
    );

Offset _caret(WidgetTester tester, String text, int offset) {
  final render = _editable(tester, _field(text)).renderEditable;
  return render.localToGlobal(
    render.getLocalRectForCaret(TextPosition(offset: offset)).center,
  );
}

Future<void> _command(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  bool shift = false,
}) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(key);
  if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pumpAndSettle();
}

Future<WysiwygEditableHarnessState> _mount(
  WidgetTester tester,
  String source,
  MemoryRichClipboard clipboard, {
  WysiwygEditorSessionState session = const WysiwygEditorSessionState(),
  bool externalHistory = false,
  BusyMarkClipboardInsertionRegistry? registry,
}) async {
  await tester.binding.setSurfaceSize(const Size(1000, 1100));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final key = GlobalKey<WysiwygEditableHarnessState>();
  await tester.pumpWidget(
    WysiwygEditableHarness(
      key: key,
      source: source,
      clipboard: clipboard,
      session: session,
      externalHistory: externalHistory,
      insertionRegistry: registry,
    ),
  );
  await tester.pumpAndSettle();
  return key.currentState!;
}

WysiwygEditorSessionState _documentSession(
  BusyDocument document, {
  bool reverse = false,
}) {
  final first = document.blocks.first;
  final last = document.blocks.last;
  return WysiwygEditorSessionState(
    activeBlockId: reverse ? first.id : last.id,
    anchorBlockId: reverse ? last.id : first.id,
    anchorOffset: reverse ? last.plainText.length : 0,
    extentBlockId: reverse ? first.id : last.id,
    extentOffset: reverse ? 0 : last.plainText.length,
    viewportBlockId: first.id,
  );
}

Future<void> _arrow(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  bool shift = false,
  bool control = false,
}) async {
  if (control) await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(key);
  if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  if (control) await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pumpAndSettle();
}

Future<void> _input(
  WidgetTester tester,
  String text, {
  TextRange composing = TextRange.empty,
}) async {
  expect(tester.testTextInput.hasAnyClients, isTrue);
  tester.testTextInput.updateEditingValue(
    TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
      composing: composing,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _oldInput(WidgetTester tester, int client, String text) async {
  // Deliver a real platform text-input message tagged with the old client ID.
  // ignore: deprecated_member_use
  tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    SystemChannels.textInput.name,
    SystemChannels.textInput.codec.encodeMethodCall(
      MethodCall('TextInputClient.updateEditingState', [
        client,
        TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        ).toJSON(),
      ]),
    ),
    (_) {},
  );
  await tester.pumpAndSettle();
}

List<BusyMarkWysiwygBlockField> _selected(WidgetTester tester) => [
  for (final block in tester.widgetList<BusyMarkWysiwygBlockField>(
    find.byType(BusyMarkWysiwygBlockField),
  ))
    if (block.selectionRange != null) block,
];

Future<TestGesture> _startDrag(
  WidgetTester tester, {
  bool table = true,
  int pointer = 71,
}) async {
  final gesture = await tester.startGesture(
    _caret(tester, table ? 'Header' : _before, 0),
    pointer: pointer,
    kind: PointerDeviceKind.mouse,
  );
  await gesture.moveTo(_caret(tester, table ? 'End!' : _after, table ? 4 : 5));
  await tester.pumpAndSettle();
  return gesture;
}

Future<void> _selectTable(WidgetTester tester, {bool selectAll = false}) async {
  if (selectAll) {
    await tester.tap(_field('Header'));
    await _command(tester, LogicalKeyboardKey.keyA);
    await _command(tester, LogicalKeyboardKey.keyA);
  } else {
    final gesture = await _startDrag(tester);
    await gesture.up();
    await tester.pumpAndSettle();
  }
  final selected = _selected(tester);
  expect(selected, hasLength(1));
  expect(selected.single.block.kind, BusyBlockKind.table);
  expect(selected.single.selectionRange!.start, 0);
  expect(selected.single.selectionRange!.end, 0);
}

void _expectTableGeometry(WidgetTester tester) {
  for (final text in [
    'Header',
    'Longer header',
    'Short',
    'Body text',
    'Last',
    'End!',
  ]) {
    final field = _field(text);
    final stack = find.ancestor(of: field, matching: find.byType(Stack)).first;
    final overlay = find.descendant(
      of: stack,
      matching: find.byWidgetPredicate(
        (w) =>
            w is CustomPaint &&
            w.painter.runtimeType.toString().contains('SelectionPainter'),
      ),
    );
    final canvas = TestRecordingCanvas();
    tester
        .widget<CustomPaint>(overlay)
        .painter!
        .paint(canvas, tester.getSize(overlay));
    final rectangles = [
      for (final call in canvas.invocations)
        if (call.invocation.memberName == #drawRect)
          call.invocation.positionalArguments.first as Rect,
    ];
    final expected = _editable(tester, field).renderEditable
        .getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: text.length),
        );
    expect(rectangles, [for (final box in expected) box.toRect()]);
  }
}

void main() {
  _registerLifecycleMatrix();
  _registerRestorationAndTerminalTests();
  setUp(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null),
  );
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null),
  );

  for (final forward in [false, true]) {
    for (final control in [false, true]) {
      testWidgets(
        'ordinary caret navigation preserves table traversal forward=$forward control=$control',
        (tester) async {
          final state = await _mount(
            tester,
            _surrounded,
            MemoryRichClipboard(),
          );
          final origin = forward ? _before : _after;
          final destination = forward ? _after : _before;
          await tester.tap(_field(origin));
          _editable(tester, _field(origin)).widget.controller.selection =
              TextSelection.collapsed(offset: forward ? origin.length : 0);
          await _arrow(
            tester,
            forward
                ? LogicalKeyboardKey.arrowRight
                : LogicalKeyboardKey.arrowLeft,
            control: control,
          );
          final focused = tester
              .widgetList<TextField>(find.byType(TextField))
              .where((field) => field.focusNode!.hasFocus)
              .single;
          expect(focused.controller!.text, destination);
          expect(
            focused.controller!.selection,
            TextSelection.collapsed(offset: forward ? 0 : destination.length),
          );
          expect(_selected(tester), isEmpty);
          expect(state.source, _surrounded);
          expect(state.changes, isEmpty);
          expect(state.editorKey.currentState!.debugUndoSnapshotCount, 0);
        },
      );
    }
  }

  for (final fixture in ['table drag', 'table Select All', 'surrounded drag']) {
    for (final action in [
      'Delete',
      'Backspace',
      'Cut',
      'Enter',
      'plain paste',
      'structured paste',
    ]) {
      testWidgets(
        '$fixture: $action replaces the selected structured block and undoes',
        (tester) async {
          final clipboard = MemoryRichClipboard();
          final original = fixture.startsWith('surrounded')
              ? _surrounded
              : _table;
          final state = await _mount(tester, original, clipboard);
          await _selectTable(tester, selectAll: fixture.endsWith('Select All'));
          _expectTableGeometry(tester);
          final parses = state.parses;
          await _command(tester, LogicalKeyboardKey.keyC);
          expect(clipboard.data.sourceText, contains('| Short | Body text |'));
          expect(
            state.parses,
            parses,
            reason: 'selection/copy must not reparse source',
          );
          switch (action) {
            case 'Delete':
              await tester.sendKeyEvent(LogicalKeyboardKey.delete);
            case 'Backspace':
              await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
            case 'Cut':
              await _command(tester, LogicalKeyboardKey.keyX);
            case 'Enter':
              await tester.sendKeyEvent(LogicalKeyboardKey.enter);
            case 'plain paste':
              clipboard.data = const RichClipboardData(text: 'Replacement 🧭');
              await _command(tester, LogicalKeyboardKey.keyV, shift: true);
            case 'structured paste':
              clipboard.data = const RichClipboardData(
                text: 'Replacement',
                html: '<p><strong>Replacement</strong></p>',
              );
              await _command(tester, LogicalKeyboardKey.keyV);
          }
          await tester.pumpAndSettle();
          expect(
            state.changes,
            hasLength(1),
            reason: '$action must be one accepted document edit',
          );
          expect(
            state.document.blocks.any((b) => b.kind == BusyBlockKind.table),
            isFalse,
          );
          expect(_selected(tester), isEmpty);
          if (fixture.startsWith('surrounded')) {
            expect(state.document.blocks.first.plainText, _before);
            expect(state.document.blocks.last.plainText, _after);
          }
          if (action == 'plain paste') {
            expect(state.source, contains('Replacement 🧭'));
          }
          if (action == 'structured paste') {
            expect(state.source, contains('**Replacement**'));
          }
          final insertedSource = switch (action) {
            'plain paste' => 'Replacement 🧭',
            'structured paste' => '**Replacement**',
            _ => '',
          };
          final expectedSource = fixture.startsWith('surrounded')
              ? insertedSource.isNotEmpty
                    ? '$_before\n\n$insertedSource\n\n$_after\n'
                    : '$_before${action == 'Enter' ? '\n\n\n\n' : '\n\n\n'}$_after\n'
              : insertedSource.isNotEmpty
              ? '$insertedSource\n'
              : action == 'Enter'
              ? '\n'
              : '';
          expect(state.source, expectedSource);
          expect(
            state.document.blocks.every(
              (b) => b.kind == BusyBlockKind.paragraph,
            ),
            isTrue,
          );
          final focused = tester
              .widgetList<TextField>(find.byType(TextField))
              .where((f) => f.focusNode!.hasFocus)
              .single;
          expect(focused.controller!.selection.isValid, isTrue);
          expect(focused.controller!.selection.isCollapsed, isTrue);
          final insertedText = action == 'plain paste'
              ? 'Replacement 🧭'
              : action == 'structured paste'
              ? 'Replacement'
              : '';
          expect(focused.controller!.text, insertedText);
          expect(
            focused.controller!.selection.extentOffset,
            insertedText.length,
          );
          final changed = state.source;
          await _command(tester, LogicalKeyboardKey.keyZ);
          expect(state.source, original);
          expect(
            state.document.blocks.any((b) => b.kind == BusyBlockKind.table),
            isTrue,
          );
          await _command(tester, LogicalKeyboardKey.keyZ, shift: true);
          expect(state.source, changed);
        },
      );
    }
  }

  for (final source in [_table, '$_table\n$_after\n', '$_before\n\n$_table']) {
    for (final arrow in [
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.arrowRight,
    ]) {
      testWidgets(
        'table endpoint arrow collapse: ${source.startsWith('|')} ${source.endsWith('stays.\n')} $arrow',
        (tester) async {
          final state = await _mount(tester, source, MemoryRichClipboard());
          await tester.tap(_field('Header'));
          await _command(tester, LogicalKeyboardKey.keyA);
          await _command(tester, LogicalKeyboardKey.keyA);
          expect(_selected(tester), isNotEmpty);
          await tester.sendKeyEvent(arrow);
          await tester.pumpAndSettle();
          expect(_selected(tester), isEmpty);
          expect(
            tester
                .widgetList<TextField>(find.byType(TextField))
                .where((f) => f.focusNode!.hasFocus),
            hasLength(1),
          );
          expect(state.source, source);
          expect(state.changes, isEmpty);
          expect(state.editorKey.currentState!.debugUndoSnapshotCount, 0);
        },
      );
    }
  }

  testWidgets(
    'table-ended selection accepts actual committed Unicode input once',
    (tester) async {
      final state = await _mount(tester, _table, MemoryRichClipboard());
      await _selectTable(tester, selectAll: true);
      expect(
        tester.testTextInput.isRegistered,
        isTrue,
        reason: 'a table document selection needs a real text input client',
      );
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '🧭',
          selection: TextSelection.collapsed(offset: 2),
        ),
      );
      await tester.pumpAndSettle();
      expect(state.source, '🧭\n');
      expect(state.changes, hasLength(1));
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '🧭 next',
          selection: TextSelection.collapsed(offset: 7),
        ),
      );
      await tester.pumpAndSettle();
      expect(state.source, '🧭 next\n');
      await _command(tester, LogicalKeyboardKey.keyZ);
      await _command(tester, LogicalKeyboardKey.keyZ);
      expect(state.source, _table);
    },
  );

  testWidgets(
    'captured table selection restores highlighting copy and mutation',
    (tester) async {
      final clipboard = MemoryRichClipboard();
      final state = await _mount(tester, _surrounded, clipboard);
      await _selectTable(tester);
      final saved = WysiwygEditorSessionState.fromJson(
        Map<String, Object?>.from(
          jsonDecode(jsonEncode(state.session.toJson())) as Map,
        ),
      );
      state.recreate(saved);
      await tester.pumpAndSettle();
      expect(_selected(tester), hasLength(1));
      _expectTableGeometry(tester);
      await _command(tester, LogicalKeyboardKey.keyC);
      expect(clipboard.data.sourceText, contains('| Short | Body text |'));
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pumpAndSettle();
      expect(
        state.document.blocks.any((b) => b.kind == BusyBlockKind.table),
        isFalse,
      );
      expect(state.document.blocks.first.plainText, _before);
      expect(state.document.blocks.last.plainText, _after);
    },
  );

  for (final table in [false, true]) {
    testWidgets(
      'cancel releases ${table ? 'cross-cell' : 'cross-block'} drag without changing its endpoint',
      (tester) async {
        final state = await _mount(tester, _surrounded, MemoryRichClipboard());
        final gesture = await _startDrag(tester, table: table);
        expect(
          tester
              .widgetList<BusyMarkWysiwygBlockField>(
                find.byType(BusyMarkWysiwygBlockField),
              )
              .any((b) => b.documentSelectionDragging),
          isTrue,
        );
        final saved = state.session.toJson();
        await gesture.cancel();
        await tester.pumpAndSettle();
        expect(
          tester
              .widgetList<BusyMarkWysiwygBlockField>(
                find.byType(BusyMarkWysiwygBlockField),
              )
              .every((b) => !b.documentSelectionDragging),
          isTrue,
        );
        expect(state.session.anchorBlockId, saved['anchorBlockId']);
        expect(state.session.extentBlockId, saved['extentBlockId']);
        expect(state.session.extentOffset, saved['extentOffset']);
        expect(state.changes, isEmpty);
        await tester.tap(_field(_after));
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextField>(_field(_after)).enableInteractiveSelection,
          isTrue,
        );
        expect(_selected(tester), isEmpty);
      },
    );
  }

  testWidgets('unrelated pointer cannot complete an owned document drag', (
    tester,
  ) async {
    final state = await _mount(tester, _surrounded, MemoryRichClipboard());
    final gesture = await _startDrag(tester, table: false, pointer: 91);
    final other = await tester.startGesture(
      _caret(tester, _after, 2),
      pointer: 92,
      kind: PointerDeviceKind.mouse,
    );
    await other.up();
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<BusyMarkWysiwygBlockField>(
            find.byType(BusyMarkWysiwygBlockField),
          )
          .any((b) => b.documentSelectionDragging),
      isTrue,
    );
    await gesture.up();
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<BusyMarkWysiwygBlockField>(
            find.byType(BusyMarkWysiwygBlockField),
          )
          .every((b) => !b.documentSelectionDragging),
      isTrue,
    );
    expect(state.changes, isEmpty);
  });

  for (final action in [
    'Delete',
    'Enter',
    'plain paste',
    'structured paste',
    'typing',
  ]) {
    testWidgets(
      'rejected protected document $action cannot edit a local fallback',
      (tester) async {
        final clipboard = MemoryRichClipboard();
        final state = await _mount(tester, _protected, clipboard);
        await tester.tap(_field('Outside'));
        await _command(tester, LogicalKeyboardKey.keyA);
        await _command(tester, LogicalKeyboardKey.keyA);
        expect(_selected(tester), hasLength(2));
        await _command(tester, LogicalKeyboardKey.keyC);
        expect(clipboard.data.text, contains('Outside'));
        switch (action) {
          case 'Delete':
            await tester.sendKeyEvent(LogicalKeyboardKey.delete);
          case 'Enter':
            await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          case 'plain paste':
            clipboard.data = const RichClipboardData(text: 'Wrong target');
            await _command(tester, LogicalKeyboardKey.keyV, shift: true);
          case 'structured paste':
            clipboard.data = const RichClipboardData(
              text: 'Wrong target',
              html: '<p><b>Wrong target</b></p>',
            );
            await _command(tester, LogicalKeyboardKey.keyV);
          case 'typing':
            tester.testTextInput.updateEditingValue(
              const TextEditingValue(
                text: 'OutsideX',
                selection: TextSelection.collapsed(offset: 8),
              ),
            );
        }
        await tester.pumpAndSettle();
        expect(state.source, _protected);
        expect(state.changes, isEmpty);
        expect(_selected(tester), hasLength(2));
        expect(state.editorKey.currentState!.debugUndoSnapshotCount, 0);
      },
    );
  }

  testWidgets('failed document deletion preserves redo history', (
    tester,
  ) async {
    final state = await _mount(tester, _protected, MemoryRichClipboard());
    await tester.enterText(_field('Outside'), 'Outside!');
    await tester.pumpAndSettle();
    final changed = state.source;
    await _command(tester, LogicalKeyboardKey.keyZ);
    expect(state.source, _protected);
    await _command(tester, LogicalKeyboardKey.keyA);
    await _command(tester, LogicalKeyboardKey.keyA);
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pumpAndSettle();
    expect(state.editorKey.currentState!.debugUndoSnapshotCount, 0);
    await _command(tester, LogicalKeyboardKey.keyZ, shift: true);
    expect(state.source, changed);
  });

  for (final cut in [false, true]) {
    for (final interruption in [
      'failure',
      'selection',
      'document',
      'disposal',
    ]) {
      testWidgets(
        'delayed table ${cut ? 'cut' : 'paste'} is safe after $interruption',
        (tester) async {
          final clipboard = _DelayedClipboard();
          final state = await _mount(tester, _surrounded, clipboard);
          await _selectTable(tester);
          clipboard.data = const RichClipboardData(text: 'Replacement');
          final gate = Completer<void>();
          if (cut) {
            clipboard.writeGate = gate;
          } else {
            clipboard.readGate = gate;
          }
          await _command(
            tester,
            cut ? LogicalKeyboardKey.keyX : LogicalKeyboardKey.keyV,
          );
          expect(cut ? clipboard.writes : clipboard.reads, 1);
          switch (interruption) {
            case 'failure':
              clipboard.writeSucceeds = false;
              clipboard.readFails = true;
            case 'selection':
              await tester.tap(_field(_after));
              await tester.pumpAndSettle();
            case 'document':
              state.replaceSource('New document\n', id: 'new-document');
              await tester.pumpAndSettle();
            case 'disposal':
              await tester.pumpWidget(const SizedBox());
          }
          gate.complete();
          await tester.pumpAndSettle();
          expect(state.changes, isEmpty);
          expect(
            state.source,
            interruption == 'document' ? 'New document\n' : _surrounded,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}

void _registerRestorationAndTerminalTests() {
  for (final key in [
    LogicalKeyboardKey.backspace,
    LogicalKeyboardKey.delete,
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.home,
    LogicalKeyboardKey.end,
  ]) {
    testWidgets('table preedit owns ${key.keyLabel} until committed input', (
      tester,
    ) async {
      final clipboard = MemoryRichClipboard()
        ..data = const RichClipboardData(text: 'Must not paste');
      final state = await _mount(tester, _table, clipboard);
      await _selectTable(tester, selectAll: true);
      await _input(tester, 'ni', composing: const TextRange(start: 0, end: 2));
      await _command(tester, LogicalKeyboardKey.keyV);
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
      expect(state.source, _table);
      expect(state.changes, isEmpty);
      expect(_selected(tester), hasLength(1));
      await _input(tester, '你');
      expect(state.source, '你\n');
      expect(state.changes, hasLength(1));
      expect(state.document.blocks.single.kind, BusyBlockKind.paragraph);
      await _command(tester, LogicalKeyboardKey.keyZ);
      expect(state.source, _table);
    });
  }

  for (final start in [false, true]) {
    testWidgets(
      'a new pointer gesture supersedes deferred table caret start=$start',
      (tester) async {
        final state = await _mount(tester, _table, MemoryRichClipboard());
        await _selectTable(tester, selectAll: true);
        await tester.sendKeyEvent(
          start ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowRight,
        );
        final target = start ? 'End!' : 'Header';
        final gesture = await tester.startGesture(
          _caret(tester, target, 2),
          pointer: 311,
          kind: PointerDeviceKind.mouse,
        );
        await gesture.up();
        await tester.pumpAndSettle();
        final focused = tester
            .widgetList<TextField>(find.byType(TextField))
            .where((field) => field.focusNode!.hasFocus)
            .single;
        expect(focused.controller!.text, target);
        expect(
          focused.controller!.selection,
          const TextSelection.collapsed(offset: 2),
        );
        expect(_selected(tester), isEmpty);
        expect(state.source, _table);
        expect(state.changes, isEmpty);
        expect(state.editorKey.currentState!.debugUndoSnapshotCount, 0);
      },
    );
  }

  for (final cancel in [false, true]) {
    testWidgets(
      'paragraph-ended drag ${cancel ? 'cancel' : 'up'} retains committed text input',
      (tester) async {
        final state = await _mount(tester, _surrounded, MemoryRichClipboard());
        final gesture = await _startDrag(tester, table: false, pointer: 301);
        final saved = state.session;
        if (cancel) {
          await gesture.cancel();
        } else {
          await gesture.up();
        }
        await tester.pumpAndSettle();
        expect(state.session.anchorBlockId, saved.anchorBlockId);
        expect(state.session.anchorOffset, saved.anchorOffset);
        expect(state.session.extentBlockId, saved.extentBlockId);
        expect(state.session.extentOffset, saved.extentOffset);
        expect(state.source, _surrounded);
        expect(_selected(tester), hasLength(3));
        expect(tester.testTextInput.isRegistered, isTrue);
        tester.testTextInput.updateEditingValue(
          const TextEditingValue(
            text: 'After🧭 stays.',
            selection: TextSelection.collapsed(offset: 7),
          ),
        );
        await tester.pumpAndSettle();
        expect(state.source, '🧭 stays.\n');
        expect(state.document.blocks, hasLength(1));
        expect(state.document.blocks.single.kind, BusyBlockKind.paragraph);
        expect(_selected(tester), isEmpty);
        expect(
          tester.widget<TextField>(_field('🧭 stays.')).controller!.selection,
          const TextSelection.collapsed(offset: 2),
        );
        expect(state.editorKey.currentState!.debugUndoSnapshotCount, 1);
        await _command(tester, LogicalKeyboardKey.keyZ);
        expect(state.source, _surrounded);
        await _command(tester, LogicalKeyboardKey.keyZ, shift: true);
        expect(state.source, '🧭 stays.\n');
      },
    );
  }

  for (final phase in ['clipboard preparation', 'open menu']) {
    testWidgets(
      'a table context menu cannot follow a changed document during $phase',
      (tester) async {
        final clipboard = _DelayedClipboard()
          ..data = const RichClipboardData(text: 'Pasted');
        final state = await _mount(tester, _surrounded, clipboard);
        await _selectTable(tester);
        if (phase == 'clipboard preparation') {
          clipboard.readGate = Completer<void>();
        }
        await tester.tap(_field('Body text'), buttons: kSecondaryMouseButton);
        await tester.pumpAndSettle();
        final next = _surrounded.replaceFirst('Before', 'Changed');
        state.replaceSource(next, id: 'new-document');
        await tester.pumpAndSettle();
        expect(_selected(tester), hasLength(1));
        if (phase == 'clipboard preparation') {
          clipboard.readGate!.complete();
          await tester.pumpAndSettle();
          expect(find.text('Cut'), findsNothing);
        } else {
          await tester.tap(find.text('Paste as Plain Text'));
          await tester.pumpAndSettle();
        }
        expect(state.source, next);
        expect(state.changes, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final source in [_table, _surrounded]) {
    testWidgets(
      'structured table fragment replaces selected table surrounded=${source == _surrounded}',
      (tester) async {
        final clipboard = MemoryRichClipboard();
        await _mount(tester, _secondTable, clipboard);
        await tester.tap(_field('Second'));
        await _command(tester, LogicalKeyboardKey.keyA);
        await _command(tester, LogicalKeyboardKey.keyA);
        await _command(tester, LogicalKeyboardKey.keyC);
        final state = await _mount(tester, source, clipboard);
        await _selectTable(tester);
        await _command(tester, LogicalKeyboardKey.keyV);
        expect(
          state.source,
          source == _table
              ? '$_secondTable\n'
              : '$_before\n\n$_secondTable\n\n$_after\n',
        );
        final table = state.document.blocks.singleWhere(
          (b) => b.kind == BusyBlockKind.table,
        );
        expect(
          table.children
              .map((row) => row.children.map((cell) => cell.plainText).toList())
              .toList(),
          [
            ['Second', 'Other header'],
            ['Two', 'Another body'],
            ['Final', 'Done!'],
          ],
        );
        expect(state.changes, hasLength(1));
        expect(_selected(tester), isEmpty);
        final focused = tester
            .widgetList<TextField>(find.byType(TextField))
            .singleWhere((field) => field.focusNode!.hasFocus);
        expect(focused.controller!.text, '');
        expect(
          focused.controller!.selection,
          const TextSelection.collapsed(offset: 0),
        );
        final replacement = state.source;
        await _command(tester, LogicalKeyboardKey.keyZ);
        expect(state.source, source);
        await _command(tester, LogicalKeyboardKey.keyZ, shift: true);
        expect(state.source, replacement);
      },
    );
  }
  for (final fixture in [
    ..._fixtures.take(4),
    (name: 'surrounded', source: _surrounded),
  ]) {
    for (final reverse in [false, true]) {
      testWidgets(
        '${fixture.name} reverse=$reverse switching a reused editor captures outgoing document selection',
        (tester) async {
          final state = await _mount(
            tester,
            fixture.source,
            MemoryRichClipboard(),
          );
          state.recreate(_documentSession(state.document, reverse: reverse));
          await tester.pumpAndSettle();
          final saved = state.session;
          final selectedIds = _selected(tester).map((b) => b.block.id).toList();
          state.replaceSource('Other tab\n', id: 'other');
          await tester.pumpAndSettle();
          final captured = state.sessions['editable']!;
          expect(captured.anchorBlockId, saved.anchorBlockId);
          expect(captured.anchorOffset, saved.anchorOffset);
          expect(captured.extentBlockId, saved.extentBlockId);
          expect(captured.extentOffset, saved.extentOffset);
          state.replaceSource(
            fixture.source,
            id: 'editable',
            restoredSession: captured,
          );
          await tester.pumpAndSettle();
          expect(_selected(tester).map((b) => b.block.id), selectedIds);
          expect(state.session.anchorBlockId, saved.anchorBlockId);
          expect(state.session.extentBlockId, saved.extentBlockId);
          expect(state.changes, isEmpty);
        },
      );
    }
  }
  for (final action in ['Cut', 'Paste', 'Paste as Plain Text']) {
    testWidgets('document context menu $action edits only the selected table', (
      tester,
    ) async {
      final clipboard = MemoryRichClipboard()
        ..data = const RichClipboardData(
          text: 'Replacement',
          html: '<p><strong>Replacement</strong></p>',
        );
      final state = await _mount(tester, _surrounded, clipboard);
      await _selectTable(tester);
      await tester.tap(_field('Body text'), buttons: kSecondaryMouseButton);
      await tester.pumpAndSettle();
      expect(
        _selected(tester),
        hasLength(1),
        reason: 'Right-click must preserve the selected table',
      );
      await tester.tap(find.text(action));
      await tester.pumpAndSettle();
      final inserted = switch (action) {
        'Paste' => '**Replacement**',
        'Paste as Plain Text' => 'Replacement',
        _ => '',
      };
      expect(
        state.source,
        action == 'Cut'
            ? '$_before\n\n\n$_after\n'
            : '$_before\n\n$inserted\n\n$_after\n',
      );
      expect(state.changes, hasLength(1));
      expect(
        state.document.blocks.every((b) => b.kind == BusyBlockKind.paragraph),
        isTrue,
      );
      expect(_selected(tester), isEmpty);
      final focused = tester
          .widgetList<TextField>(find.byType(TextField))
          .singleWhere((field) => field.focusNode!.hasFocus);
      expect(focused.controller!.text, action == 'Cut' ? '' : 'Replacement');
      if (action == 'Cut') {
        expect(clipboard.data.sourceText, contains('| Short | Body text |'));
      }
      await _command(tester, LogicalKeyboardKey.keyZ);
      expect(state.source, _surrounded);
    });
  }
  for (final source in [_table, _surrounded]) {
    testWidgets(
      'undo table deletion restores a real cell caret surrounded=${source == _surrounded}',
      (tester) async {
        final state = await _mount(tester, source, MemoryRichClipboard());
        await _selectTable(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.delete);
        await tester.pumpAndSettle();
        await _command(tester, LogicalKeyboardKey.keyZ);
        expect(state.source, source);
        final fields = tester
            .widgetList<TextField>(find.byType(TextField))
            .where((f) => f.focusNode!.hasFocus);
        expect(fields, hasLength(1));
        expect(fields.single.controller!.text, 'Header');
        expect(
          fields.single.controller!.selection,
          const TextSelection.collapsed(offset: 0),
        );
        await _input(tester, 'Edited header');
        expect(state.source, contains('| Edited header | Longer header |'));
        await _command(tester, LogicalKeyboardKey.keyZ);
        expect(state.source, source);
      },
    );
  }
  for (final cancel in [false, true]) {
    testWidgets(
      'returning to an ordinary collapsed endpoint ${cancel ? 'cancel' : 'up'} restores real typing',
      (tester) async {
        final state = await _mount(tester, _surrounded, MemoryRichClipboard());
        final start = _caret(tester, _before, 3);
        final gesture = await tester.startGesture(
          start,
          pointer: 176,
          kind: PointerDeviceKind.mouse,
        );
        await gesture.moveTo(_caret(tester, _after, 5));
        await tester.pumpAndSettle();
        await gesture.moveTo(start);
        await tester.pumpAndSettle();
        expect(state.session.anchorOffset, 3);
        expect(state.session.extentOffset, 3);
        if (cancel) {
          await gesture.cancel();
        } else {
          await gesture.up();
        }
        await tester.pumpAndSettle();
        expect(_selected(tester), isEmpty);
        expect(state.changes, isEmpty);
        expect(tester.testTextInput.hasAnyClients, isTrue);
        tester.testTextInput.updateEditingValue(
          const TextEditingValue(
            text: 'BefXore stays.',
            selection: TextSelection.collapsed(offset: 4),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          state.source,
          _surrounded.replaceFirst(_before, 'BefXore stays.'),
        );
        expect(state.changes, hasLength(1));
        expect(
          tester
              .widget<TextField>(_field('BefXore stays.'))
              .controller!
              .selection
              .extentOffset,
          4,
        );
      },
    );
  }
  for (final fixture in _fixtures.where((f) => f.name != 'text control')) {
    for (final reverse in [false, true]) {
      testWidgets(
        '${fixture.name} real ${reverse ? 'reverse drag' : 'Select All'} survives workspace session JSON and editor recreation',
        (tester) async {
          final clipboard = MemoryRichClipboard();
          final state = await _mount(tester, fixture.source, clipboard);
          if (reverse && fixture.name != 'table-only') {
            final first = state.document.blocks.first;
            final last = state.document.blocks.last;
            final from = last.kind == BusyBlockKind.table
                ? last.children.last.children.last
                : last;
            final to = first.kind == BusyBlockKind.table
                ? first.children.first.children.first
                : first;
            final gesture = await tester.startGesture(
              _caret(tester, from.plainText, from.plainText.length),
              pointer: 180,
              kind: PointerDeviceKind.mouse,
            );
            await gesture.moveTo(_caret(tester, to.plainText, 0));
            await gesture.up();
            await tester.pumpAndSettle();
          } else {
            await tester.tap(_field('Header'));
            await _command(tester, LogicalKeyboardKey.keyA);
            await _command(tester, LogicalKeyboardKey.keyA);
          }
          final ranges = [
            for (final b in _selected(tester))
              (b.block.id, b.selectionRange!.start, b.selectionRange!.end),
          ];
          expect(ranges, isNotEmpty);
          await _command(tester, LogicalKeyboardKey.keyC);
          final copy = clipboard.data.sourceText;
          final serialized =
              jsonDecode(
                    jsonEncode(
                      DocumentEditorState(wysiwygState: state.session).toJson(),
                    ),
                  )
                  as Map;
          final saved = DocumentEditorState.fromJson(
            Map<String, Object?>.from(serialized),
          ).wysiwygState;
          final before = state.session;
          state.recreate(saved);
          await tester.pumpAndSettle();
          expect([
            for (final b in _selected(tester))
              (b.block.id, b.selectionRange!.start, b.selectionRange!.end),
          ], ranges);
          expect(state.session.anchorBlockId, before.anchorBlockId);
          expect(state.session.extentBlockId, before.extentBlockId);
          _expectTableGeometry(tester);
          await _command(tester, LogicalKeyboardKey.keyC);
          expect(clipboard.data.sourceText, copy);
          expect(state.changes, isEmpty);
          expect(state.editorKey.currentState!.debugUndoSnapshotCount, 0);
          clipboard.data = const RichClipboardData(
            text: 'Restored replacement',
          );
          await _command(tester, LogicalKeyboardKey.keyV, shift: true);
          expect(state.source, 'Restored replacement\n');
          expect(state.document.blocks.single.kind, BusyBlockKind.paragraph);
          await _command(tester, LogicalKeyboardKey.keyZ);
          expect(state.source, fixture.source);
        },
      );
    }
  }

  for (final cellLocal in [false, true]) {
    testWidgets(
      '${cellLocal ? 'cell' : 'paragraph'} local reverse selection restores locally',
      (tester) async {
        final clipboard = MemoryRichClipboard();
        final state = await _mount(tester, _surrounded, clipboard);
        final text = cellLocal ? 'Body text' : _before;
        await tester.tap(_field(text));
        final field = tester.widget<TextField>(_field(text));
        field.controller!.selection = const TextSelection(
          baseOffset: 5,
          extentOffset: 1,
        );
        await tester.pumpAndSettle();
        final saved = WysiwygEditorSessionState.fromJson(
          Map<String, Object?>.from(
            jsonDecode(jsonEncode(state.session.toJson())) as Map,
          ),
        );
        state.recreate(saved);
        await tester.pumpAndSettle();
        expect(_selected(tester), isEmpty);
        final restored = tester.widget<TextField>(_field(text));
        expect(restored.focusNode!.hasFocus, isTrue);
        expect(
          restored.controller!.selection,
          const TextSelection(baseOffset: 5, extentOffset: 1),
        );
        await _command(tester, LogicalKeyboardKey.keyC);
        expect(clipboard.data.text, text.substring(1, 5));
        clipboard.data = const RichClipboardData(text: 'X');
        await _command(tester, LogicalKeyboardKey.keyV, shift: true);
        expect(
          state.document.blocks.where((b) => b.kind == BusyBlockKind.table),
          hasLength(1),
        );
        expect(state.source, contains(text.replaceRange(1, 5, 'X')));
        await _command(tester, LogicalKeyboardKey.keyZ);
        expect(state.source, _surrounded);
      },
    );
  }

  for (final changed in ['removed', 'changed kind', 'changed text']) {
    testWidgets('saved table target $changed uses current-document fallback', (
      tester,
    ) async {
      final state = await _mount(tester, _surrounded, MemoryRichClipboard());
      await _selectTable(tester);
      final saved = state.session;
      final next = switch (changed) {
        'removed' => 'Survivor\n',
        'changed kind' => '$_before\n\nNew paragraph\n\n$_after\n',
        _ => _surrounded.replaceFirst('Body text', 'Current body'),
      };
      state.replaceSource(next);
      await tester.pumpAndSettle();
      state.recreate(saved);
      await tester.pumpAndSettle();
      expect(state.source, next);
      expect(state.changes, isEmpty);
      expect(state.editorKey.currentState!.debugUndoSnapshotCount, 0);
      if (changed == 'changed text') {
        expect(_selected(tester), hasLength(1));
        expect(
          tester
              .widget<TextField>(_field('Current body'))
              .enableInteractiveSelection,
          isTrue,
        );
      } else {
        expect(_selected(tester), isEmpty);
        expect(
          tester
              .widgetList<TextField>(find.byType(TextField))
              .where((f) => f.focusNode!.hasFocus),
          hasLength(1),
        );
      }
      expect(tester.takeException(), isNull);
    });
  }

  for (final table in [false, true]) {
    testWidgets(
      'unrelated move and cancel preserve owned ${table ? 'cell' : 'block'} drag',
      (tester) async {
        final state = await _mount(tester, _surrounded, MemoryRichClipboard());
        final gesture = await _startDrag(tester, table: table, pointer: 191);
        final saved = state.session;
        final position = _caret(tester, _after, 0);
        tester.binding.handlePointerEvent(
          PointerMoveEvent(
            pointer: 192,
            position: position,
            buttons: kPrimaryMouseButton,
            kind: PointerDeviceKind.mouse,
          ),
        );
        tester.binding.handlePointerEvent(
          PointerCancelEvent(
            pointer: 192,
            position: position,
            kind: PointerDeviceKind.mouse,
          ),
        );
        await tester.pumpAndSettle();
        expect(state.session.anchorBlockId, saved.anchorBlockId);
        expect(state.session.extentBlockId, saved.extentBlockId);
        expect(state.session.extentOffset, saved.extentOffset);
        expect(
          tester
              .widgetList<BusyMarkWysiwygBlockField>(
                find.byType(BusyMarkWysiwygBlockField),
              )
              .any((b) => b.documentSelectionDragging),
          isTrue,
        );
        await gesture.cancel();
        await tester.pumpAndSettle();
        expect(
          tester
              .widgetList<TextField>(find.byType(TextField))
              .every((f) => f.enableInteractiveSelection),
          isTrue,
        );
        final local = await tester.startGesture(
          _caret(tester, _after, 1),
          pointer: 193,
          kind: PointerDeviceKind.mouse,
        );
        await local.moveTo(_caret(tester, _after, 5));
        await local.up();
        await tester.pumpAndSettle();
        expect(_selected(tester), isEmpty);
        expect(
          tester.widget<TextField>(_field(_after)).controller!.selection,
          const TextSelection(baseOffset: 1, extentOffset: 5),
        );
        expect(state.changes, isEmpty);
      },
    );
  }
}

void _registerLifecycleMatrix() {
  for (final fixture in [
    (name: 'table-only', source: _table, reverse: false),
    (name: 'leading table', source: '$_table\n$_after\n', reverse: true),
    (name: 'trailing table', source: '$_before\n\n$_table', reverse: false),
    (
      name: 'consecutive tables',
      source: '$_table\n$_secondTable',
      reverse: false,
    ),
  ]) {
    testWidgets(
      '${fixture.name} committed newline and continued typing replace a table-ended selection',
      (tester) async {
        final state = await _mount(
          tester,
          fixture.source,
          MemoryRichClipboard(),
        );
        state.recreate(
          _documentSession(state.document, reverse: fixture.reverse),
        );
        await tester.pumpAndSettle();
        await _input(tester, '\n');
        expect(state.source, '\n');
        expect(state.changes, hasLength(1));
        expect(
          state.document.blocks.where((b) => b.kind == BusyBlockKind.table),
          isEmpty,
        );
        expect(_selected(tester), isEmpty);
        final focused = tester
            .widgetList<TextField>(find.byType(TextField))
            .singleWhere((field) => field.focusNode!.hasFocus);
        expect(
          focused.controller!.selection,
          const TextSelection.collapsed(offset: 0),
        );
        await _input(tester, 'Next');
        expect(state.source, '\nNext\n');
        await _command(tester, LogicalKeyboardKey.keyZ);
        expect(state.source, '\n');
        await _command(tester, LogicalKeyboardKey.keyZ);
        expect(state.source, fixture.source);
      },
    );
  }
  for (final fixture in _fixtures) {
    for (final reverse in [false, true]) {
      for (final movement in [
        (key: LogicalKeyboardKey.arrowLeft, control: false, start: true),
        (key: LogicalKeyboardKey.arrowUp, control: false, start: true),
        (key: LogicalKeyboardKey.arrowRight, control: false, start: false),
        (key: LogicalKeyboardKey.arrowDown, control: false, start: false),
        (key: LogicalKeyboardKey.arrowLeft, control: true, start: true),
        (key: LogicalKeyboardKey.arrowRight, control: true, start: false),
      ]) {
        testWidgets(
          '${fixture.name} reverse=$reverse collapse ${movement.key.keyLabel} control=${movement.control}',
          (tester) async {
            final state = await _mount(
              tester,
              fixture.source,
              MemoryRichClipboard(),
            );
            state.recreate(_documentSession(state.document, reverse: reverse));
            await tester.pumpAndSettle();
            expect(_selected(tester), isNotEmpty);
            await _arrow(tester, movement.key, control: movement.control);
            expect(_selected(tester), isEmpty);
            final edge = movement.start
                ? state.document.blocks.first
                : state.document.blocks.last;
            final target = edge.kind == BusyBlockKind.table
                ? (movement.start
                      ? edge.children.first.children.first
                      : edge.children.last.children.last)
                : edge;
            final focused = tester
                .widgetList<TextField>(find.byType(TextField))
                .where((f) => f.focusNode!.hasFocus)
                .single;
            expect(focused.controller!.text, target.plainText);
            expect(
              focused.controller!.selection,
              TextSelection.collapsed(
                offset: movement.start ? 0 : target.plainText.length,
              ),
            );
            expect(state.source, fixture.source);
            expect(state.changes, isEmpty);
            expect(state.editorKey.currentState!.debugUndoSnapshotCount, 0);
          },
        );
      }
      final tableExtent =
          fixture.name == 'table-only' ||
          fixture.name == 'consecutive tables' ||
          (fixture.name == 'leading table' && reverse) ||
          (fixture.name == 'trailing table' && !reverse);
      if (!tableExtent) continue;
      for (final cancel in [false, true]) {
        testWidgets(
          '${fixture.name} reverse=$reverse composing ${cancel ? 'cancel' : 'commit'} uses real input',
          (tester) async {
            final clipboard = _DelayedClipboard();
            final state = await _mount(tester, fixture.source, clipboard);
            state.recreate(_documentSession(state.document, reverse: reverse));
            await tester.pumpAndSettle();
            await _input(
              tester,
              'n',
              composing: const TextRange(start: 0, end: 1),
            );
            await _input(
              tester,
              'ni',
              composing: const TextRange(start: 0, end: 2),
            );
            await _input(
              tester,
              '你',
              composing: const TextRange(start: 0, end: 1),
            );
            expect(state.source, fixture.source);
            expect(state.changes, isEmpty);
            expect(state.editorKey.currentState!.debugUndoSnapshotCount, 0);
            clipboard.data = const RichClipboardData(text: 'Must not paste');
            await _command(tester, LogicalKeyboardKey.keyV);
            expect(clipboard.reads, 0);
            if (cancel) {
              await _input(tester, '');
              expect(state.source, fixture.source);
              expect(_selected(tester), isNotEmpty);
              expect(state.changes, isEmpty);
              await _command(tester, LogicalKeyboardKey.keyC);
              expect(
                clipboard.data.sourceText,
                contains('| Short | Body text |'),
              );
            } else {
              await _input(tester, '你🧭');
              expect(state.source, '你🧭\n');
              expect(state.changes, hasLength(1));
              expect(
                state.document.blocks.single.kind,
                BusyBlockKind.paragraph,
              );
              expect(_selected(tester), isEmpty);
              await _input(tester, '你🧭');
              expect(
                state.changes,
                hasLength(1),
                reason: 'repeated input must not duplicate replacement',
              );
              await _input(tester, '你🧭 next');
              expect(state.source, '你🧭 next\n');
              final field = tester.widget<TextField>(_field('你🧭 next'));
              expect(field.focusNode!.hasFocus, isTrue);
              expect(
                field.controller!.selection.extentOffset,
                '你🧭 next'.length,
              );
              await _command(tester, LogicalKeyboardKey.keyZ);
              expect(state.source, '你🧭\n');
              await _command(tester, LogicalKeyboardKey.keyZ);
              expect(state.source, fixture.source);
              await _command(tester, LogicalKeyboardKey.keyZ, shift: true);
              expect(state.source, '你🧭\n');
            }
          },
        );
      }
    }
  }

  for (final movement in [
    (
      next: LogicalKeyboardKey.arrowRight,
      previous: LogicalKeyboardKey.arrowLeft,
      word: false,
    ),
    (
      next: LogicalKeyboardKey.arrowRight,
      previous: LogicalKeyboardKey.arrowLeft,
      word: true,
    ),
    (
      next: LogicalKeyboardKey.arrowDown,
      previous: LogicalKeyboardKey.arrowUp,
      word: false,
    ),
  ]) {
    testWidgets(
      'keyboard extension includes consecutive tables and returns to a selected table: $movement',
      (tester) async {
        final clipboard = MemoryRichClipboard();
        final state = await _mount(
          tester,
          '$_table\n$_secondTable\n$_after\n',
          clipboard,
        );
        await _selectTable(tester);
        await _arrow(
          tester,
          movement.next,
          shift: true,
          control: movement.word,
        );
        expect(_selected(tester).map((b) => b.block.kind), [
          BusyBlockKind.table,
          BusyBlockKind.table,
        ]);
        await _command(tester, LogicalKeyboardKey.keyC);
        expect(
          clipboard.data.sourceText,
          contains('| Second | Other header |'),
        );
        await _arrow(
          tester,
          movement.previous,
          shift: true,
          control: movement.word,
        );
        expect(_selected(tester), hasLength(1));
        expect(_selected(tester).single.block.kind, BusyBlockKind.table);
        await _arrow(
          tester,
          movement.next,
          shift: true,
          control: movement.word,
        );
        await _arrow(
          tester,
          movement.next,
          shift: true,
          control: movement.word,
        );
        expect(state.session.extentBlockId, state.document.blocks.last.id);
        expect(state.session.extentOffset, 0);
        expect(
          _selected(tester).where((b) => b.block.kind == BusyBlockKind.table),
          hasLength(2),
        );
        expect(state.changes, isEmpty);
      },
    );
  }

  for (final interruption in [
    'selection',
    'document',
    'same document source',
    'disposal',
  ]) {
    testWidgets('old table input client is rejected after $interruption', (
      tester,
    ) async {
      final state = await _mount(tester, _surrounded, MemoryRichClipboard());
      await _selectTable(tester);
      final client =
          (tester.testTextInput.log
                          .lastWhere(
                            (call) => call.method == 'TextInput.setClient',
                          )
                          .arguments
                      as List)
                  .first
              as int;
      await _input(
        tester,
        'preedit',
        composing: const TextRange(start: 0, end: 7),
      );
      switch (interruption) {
        case 'selection':
          await tester.tap(_field(_after));
          await tester.pumpAndSettle();
        case 'document':
          state.replaceSource('Another\n', id: 'another');
          await tester.pumpAndSettle();
        case 'same document source':
          state.replaceSource('Another\n');
          await tester.pumpAndSettle();
        case 'disposal':
          await tester.pumpWidget(const SizedBox());
      }
      await _oldInput(tester, client, 'Wrong target');
      expect(
        state.source,
        interruption.contains('document') ? 'Another\n' : _surrounded,
      );
      expect(state.changes, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  for (final external in [false, true]) {
    testWidgets('empty table copy deletion undo externalHistory=$external', (
      tester,
    ) async {
      final clipboard = MemoryRichClipboard();
      final state = await _mount(
        tester,
        _emptyTable,
        clipboard,
        externalHistory: external,
      );
      await tester.tap(find.byType(TextField).first);
      await _command(tester, LogicalKeyboardKey.keyA);
      await _command(tester, LogicalKeyboardKey.keyA);
      expect(_selected(tester), hasLength(1));
      await _command(tester, LogicalKeyboardKey.keyC);
      expect(clipboard.data.sourceText, contains('| --- | --- |'));
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pumpAndSettle();
      expect(state.source, '');
      expect(
        state.document.blocks.where((b) => b.kind == BusyBlockKind.table),
        isEmpty,
      );
      expect(state.changes, hasLength(1));
      await _command(tester, LogicalKeyboardKey.keyZ);
      expect(state.source, _emptyTable);
      expect(state.document.blocks.single.kind, BusyBlockKind.table);
      if (external) {
        expect(state.undoCalls, 1);
        expect(state.editorKey.currentState!.debugUndoSnapshotCount, 0);
      }
      await _command(tester, LogicalKeyboardKey.keyZ, shift: true);
      expect(state.source, '');
    });
  }

  testWidgets(
    'clipboard history replaces selected table through document range',
    (tester) async {
      final registry = BusyMarkClipboardInsertionRegistry();
      addTearDown(registry.dispose);
      final state = await _mount(
        tester,
        _surrounded,
        MemoryRichClipboard(),
        registry: registry,
      );
      await _selectTable(tester);
      expect(
        await registry.paste(
          BusyMarkClipboardPayload(
            id: 'history',
            acquiredAt: DateTime.utc(2026),
            kind: BusyMarkClipboardContentKind.text,
            text: 'History replacement',
          ),
          mode: BusyMarkPasteMode.plainText,
        ),
        ClipboardPasteResult.inserted,
      );
      await tester.pumpAndSettle();
      expect(state.source, '$_before\n\nHistory replacement\n\n$_after\n');
      expect(state.document.blocks.map((b) => b.kind), [
        BusyBlockKind.paragraph,
        BusyBlockKind.paragraph,
        BusyBlockKind.paragraph,
      ]);
      expect(_selected(tester), isEmpty);
      await _command(tester, LogicalKeyboardKey.keyZ);
      expect(state.source, _surrounded);
    },
  );

  testWidgets(
    'partial paragraph to table to paragraph replacement preserves outside text and undo',
    (tester) async {
      final clipboard = MemoryRichClipboard();
      final state = await _mount(tester, _surrounded, clipboard);
      final gesture = await tester.startGesture(
        _caret(tester, _before, 6),
        pointer: 115,
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveTo(_caret(tester, _after, 5));
      await gesture.up();
      await tester.pumpAndSettle();
      await _command(tester, LogicalKeyboardKey.keyC);
      expect(clipboard.data.text, startsWith(' stays.'));
      expect(clipboard.data.text, endsWith('After'));
      expect(clipboard.data.text, contains('Body text'));
      clipboard.data = const RichClipboardData(text: 'X');
      await _command(tester, LogicalKeyboardKey.keyV, shift: true);
      expect(state.source, 'BeforeX stays.\n');
      expect(state.document.blocks.single.plainText, 'BeforeX stays.');
      expect(
        tester
            .widget<TextField>(_field('BeforeX stays.'))
            .controller!
            .selection
            .extentOffset,
        7,
      );
      await _command(tester, LogicalKeyboardKey.keyZ);
      expect(state.source, _surrounded);
    },
  );

  testWidgets('cell-local input cut paste and Tab remain local', (
    tester,
  ) async {
    final clipboard = MemoryRichClipboard();
    final state = await _mount(tester, _surrounded, clipboard);
    await tester.tap(_field('Body text'));
    final field = tester.widget<TextField>(_field('Body text'));
    field.controller!.selection = const TextSelection(
      baseOffset: 0,
      extentOffset: 4,
    );
    await _command(tester, LogicalKeyboardKey.keyX);
    expect(state.source, contains('| Short |  text |'));
    expect(
      state.document.blocks.where((b) => b.kind == BusyBlockKind.table),
      hasLength(1),
    );
    clipboard.data = const RichClipboardData(text: 'Cell');
    await _command(tester, LogicalKeyboardKey.keyV, shift: true);
    expect(state.source, contains('| Short | Cell text |'));
    await _input(tester, 'Local 🧭');
    expect(state.source, contains('| Short | Local 🧭 |'));
    expect(state.document.blocks.first.plainText, _before);
    expect(state.document.blocks.last.plainText, _after);
    expect(_selected(tester), isEmpty);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(_field('Last')).focusNode!.hasFocus,
      isTrue,
    );
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(_field('Local 🧭')).focusNode!.hasFocus,
      isTrue,
    );
  });

  for (final terminal in ['up', 'cancel', 'document', 'disposal']) {
    testWidgets('scrolling owned drag terminates safely by $terminal', (
      tester,
    ) async {
      final source =
          '${[for (var i = 0; i < 50; i++) 'Paragraph $i with enough text.'].join('\n\n')}\n';
      final state = await _mount(tester, source, MemoryRichClipboard());
      final list = tester.widget<ScrollablePositionedList>(
        find.byType(ScrollablePositionedList),
      );
      final gesture = await tester.startGesture(
        _caret(tester, 'Paragraph 0 with enough text.', 0),
        pointer: 130,
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveTo(_caret(tester, 'Paragraph 2 with enough text.', 5));
      await tester.pumpAndSettle();
      list.itemScrollController!.jumpTo(index: 35, alignment: 0.1);
      await tester.pumpAndSettle();
      await gesture.moveTo(_caret(tester, 'Paragraph 37 with enough text.', 9));
      await tester.pumpAndSettle();
      expect(state.session.extentBlockId, state.document.blocks[37].id);
      final saved = state.session;
      switch (terminal) {
        case 'up':
          await gesture.up();
        case 'cancel':
          await gesture.cancel();
        case 'document':
          state.replaceSource('Replacement document\n', id: 'replacement');
          await tester.pumpAndSettle();
          await gesture.up();
        case 'disposal':
          await tester.pumpWidget(const SizedBox());
          await gesture.cancel();
      }
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<BusyMarkWysiwygBlockField>(
              find.byType(BusyMarkWysiwygBlockField),
            )
            .every((b) => !b.documentSelectionDragging),
        isTrue,
      );
      expect(state.changes, isEmpty);
      if (terminal == 'cancel') {
        expect(state.session.extentBlockId, saved.extentBlockId);
        expect(state.session.extentOffset, 9);
        expect(
          state.session.viewportBlockId,
          isNot(state.document.blocks.first.id),
        );
      }
      expect(tester.takeException(), isNull);
    }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
  }
}
