import 'dart:async';
import 'dart:convert';

import 'package:busymark/src/clipboard/clipboard_insertion.dart';
import 'package:busymark/src/clipboard/clipboard_models.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_block_widgets.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:busymark/src/app/busymark_dialogs.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_session_state.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/platform/rich_clipboard_service.dart';
import 'package:busymark/src/workspace/document_buffer.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:busymark/src/visualization/visualization_providers.dart';
import 'package:busymark/src/visualization/visualization_renderer.dart';
import 'package:busymark/src/visualization/web_render_host.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../support/memory_rich_clipboard.dart';
import '../support/desktop_focus.dart';
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

class _LifecycleMathHost implements WebRenderHost {
  @override
  Future<Map<Object?, Object?>> renderMathBatch({
    required List<Map<String, Object?>> expressions,
    required VisualizationCancellationToken cancellationToken,
  }) async => {
    'results': [
      for (final expression in expressions)
        {
          'id': expression['id'],
          'svg':
              '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 14"><path d="M0 0L10 10"/></svg>',
          'width': 20,
          'height': 14,
          'depth': 2,
        },
    ],
  };
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
  bool renderMath = false,
  BusyMarkClipboardInsertionRegistry? registry,
}) async {
  await tester.binding.setSurfaceSize(const Size(1000, 1100));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final key = GlobalKey<WysiwygEditableHarnessState>();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (renderMath)
          webRenderHostProvider.overrideWithValue(_LifecycleMathHost()),
      ],
      child: WysiwygEditableHarness(
        key: key,
        source: source,
        clipboard: clipboard,
        session: session,
        externalHistory: externalHistory,
        insertionRegistry: registry,
      ),
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
  testWidgets(
    'short table input after desktop return reveals the original cell',
    (tester) async {
      enableDesktopFocusLifecycle(tester);
      final source =
          'Before.\n\n| Header | Other |\n| --- | --- |\n| Focus cell | Body |\n\n${List.generate(100, (i) => 'Reading $i ${'words ' * 20}').join('\n\n')}\n';
      final state = await _mount(tester, source, MemoryRichClipboard());
      final field = tester.widget<TextField>(_field('Focus cell'));
      field.focusNode!.requestFocus();
      field.controller!.selection = const TextSelection.collapsed(offset: 5);
      await tester.pumpAndSettle();
      final scrollable = Scrollable.of(
        tester.element(_field('Focus cell')),
        axis: Axis.vertical,
      );
      // Beyond the package's two-viewport cache, not only outside the screen.
      scrollable.position.jumpTo(5000);
      await tester.pumpAndSettle();
      final reading = scrollable.position.pixels;
      for (var cycle = 0; cycle < 4; cycle++) {
        await pumpDesktopFocusCycle(
          tester,
          target: field.focusNode!,
          inactiveFrames: cycle == 2 ? 90 : 1,
          verifyViewport: () =>
              expect(scrollable.position.pixels, closeTo(reading, 0.1)),
        );
      }
      expect(state.session.viewportEditingOffset, lessThan(-4000));
      expect(() => jsonEncode(state.session.toJson()), returnsNormally);
      final readingField = find
          .byWidgetPredicate(
            (w) =>
                w is TextField &&
                w.controller?.text.startsWith('Reading ') == true,
          )
          .evaluate()
          .firstWhere((e) {
            final top = tester.getTopLeft(find.byWidget(e.widget)).dy;
            return top > 100 && top < 900;
          });
      final readingText = (readingField.widget as TextField).controller!.text;
      final readingTop = tester.getTopLeft(_field(readingText)).dy;
      state.recreate(
        WysiwygEditorSessionState.fromJson(state.session.toJson()),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(_field(readingText)).dy,
        closeTo(readingTop, 0.1),
      );
      expect(tester.testTextInput.hasAnyClients, isTrue);
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'Focusz cell',
          selection: TextSelection.collapsed(offset: 6),
        ),
      );
      await tester.pumpAndSettle();
      expect(state.source, contains('| Focusz cell |'));
      expect(_caret(tester, 'Focusz cell', 6).dy, inInclusiveRange(0, 1100));
      expect(
        Scrollable.of(
          tester.element(_field('Focusz cell')),
          axis: Axis.vertical,
        ).position.pixels,
        lessThan(reading - 100),
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );

  testWidgets('queued toolbar restoration respects application suspension', (
    tester,
  ) async {
    enableDesktopFocusLifecycle(tester);
    final state = await _mount(
      tester,
      'Original target.\n',
      MemoryRichClipboard(),
    );
    final field = tester.widget<TextField>(_field('Original target.'));
    state.editorKey.currentState!.restoreEditingFocus();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pumpAndSettle();
    expect(
      FocusManager.instance.primaryFocus,
      same(FocusManager.instance.rootScope),
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus, same(field.focusNode));
    expect(tester.testTextInput.hasAnyClients, isTrue);
    expect(state.changes, isEmpty);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets(
    'table Tab deliberately reveals the next cell after passive restoration',
    (tester) async {
      enableDesktopFocusLifecycle(tester);
      final cells = List.generate(12, (i) => 'Cell $i ${'wide ' * 20}'.trim());
      final table =
          '|${List.generate(12, (i) => 'Head $i').join('|')}|\n'
          '|${List.filled(12, '---').join('|')}|\n'
          '|${cells.join('|')}|\n';
      final source =
          '$table\n${List.generate(100, (i) => 'Reading $i ${'words ' * 30}').join('\n\n')}\n';
      final state = await _mount(tester, source, MemoryRichClipboard());
      final first = tester.widget<TextField>(_field(cells.first));
      final next = tester.widget<TextField>(_field(cells[1]));
      final nextEditable = _editable(tester, _field(cells[1]));
      first.focusNode!.requestFocus();
      first.controller!.selection = const TextSelection.collapsed(offset: 0);
      await tester.pumpAndSettle();
      final vertical = Scrollable.of(
        tester.element(_field(cells.first)),
        axis: Axis.vertical,
      ).position;
      final horizontal = next.scrollController!.position;
      expect(horizontal.maxScrollExtent, greaterThan(100));
      // Compare the intentional reveal with a fresh Tab, rather than assuming
      // that the framework's caret/pixel rounding necessarily chooses zero.
      horizontal.jumpTo(horizontal.maxScrollExtent);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      final freshHorizontal = horizontal.pixels;
      first.focusNode!.requestFocus();
      await tester.pumpAndSettle();
      horizontal.jumpTo(horizontal.maxScrollExtent);
      vertical.jumpTo(2000);
      await tester.pumpAndSettle();
      final reading = vertical.pixels;
      final cellReading = horizontal.pixels;
      await pumpDesktopFocusCycle(
        tester,
        target: first.focusNode!,
        verifyViewport: () {
          expect(vertical.pixels, closeTo(reading, 0.1));
          expect(horizontal.pixels, closeTo(cellReading, 0.1));
        },
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus, same(next.focusNode));
      expect(nextEditable.mounted, isTrue);
      final caret = nextEditable.renderEditable.localToGlobal(
        nextEditable.renderEditable
            .getLocalRectForCaret(const TextPosition(offset: 0))
            .center,
      );
      expect(caret.dx, inInclusiveRange(0, 1000));
      expect(caret.dy, inInclusiveRange(0, 1100));
      expect(horizontal.pixels, closeTo(freshHorizontal, 0.1));
      expect(state.changes, isEmpty);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );

  for (final inactive in [false, true]) {
    testWidgets(
      'document refresh preserves an existing competing focus owner inactive=$inactive',
      (tester) async {
        enableDesktopFocusLifecycle(tester);
        final state = await _mount(
          tester,
          'Original target.\n',
          MemoryRichClipboard(),
        );
        final saved = state.session;
        final other = FocusNode(
          debugLabel: 'Existing search or inspector input',
        );
        final overlay = Overlay.of(
          tester.element(find.byType(BusyMarkWysiwygEditor)),
        );
        final entry = OverlayEntry(
          builder: (_) => Positioned(
            left: 0,
            top: 0,
            width: 200,
            height: 40,
            child: Material(child: TextField(focusNode: other)),
          ),
        );
        overlay.insert(entry);
        await tester.pumpAndSettle();
        other.requestFocus();
        await tester.pumpAndSettle();
        if (inactive) {
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.inactive,
          );
        }
        state.replaceSource('Replacement target.\n', restoredSession: saved);
        await tester.pumpAndSettle();
        if (inactive) {
          expect(
            FocusManager.instance.primaryFocus,
            same(FocusManager.instance.rootScope),
          );
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
          await tester.pumpAndSettle();
        }
        expect(FocusManager.instance.primaryFocus, same(other));
        tester.testTextInput.updateEditingValue(
          const TextEditingValue(
            text: 'search continues',
            selection: TextSelection.collapsed(offset: 16),
          ),
        );
        await tester.pumpAndSettle();
        expect(state.changes, isEmpty);
        expect(state.source, 'Replacement target.\n');
        entry.remove();
        await tester.pumpAndSettle();
        entry.dispose();
        other.dispose();
      },
      variant: TargetPlatformVariant.only(TargetPlatform.linux),
    );
  }

  for (final navigation in [false, true]) {
    testWidgets(
      'new input wins while passive reveal is pending navigation=$navigation',
      (tester) async {
        enableDesktopFocusLifecycle(tester);
        final paragraphs = List.generate(
          100,
          (i) => 'Paragraph $i ${'reading words ' * 12}'.trimRight(),
        );
        final state = await _mount(
          tester,
          '${paragraphs.join('\n\n')}\n',
          MemoryRichClipboard(),
        );
        final field = tester.widget<TextField>(_field(paragraphs.first));
        field.controller!.selection = const TextSelection.collapsed(offset: 3);
        await tester.pumpAndSettle();
        final scrollable = tester.state<ScrollableState>(
          find
              .descendant(
                of: find.byType(ScrollablePositionedList),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        scrollable.position.jumpTo(5000);
        await tester.pumpAndSettle();
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        await tester.pump();
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.idle();
        if (navigation) {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
          await tester.pumpAndSettle();
          expect(
            field.controller!.selection,
            const TextSelection.collapsed(offset: 4),
          );
          expect(
            _caret(tester, paragraphs.first, 4).dy,
            inInclusiveRange(0, 1100),
          );
        } else {
          scrollable.position.pointerScroll(200);
          final offset = scrollable.position.pixels;
          for (var frame = 0; frame < 30; frame++) {
            await tester.pump(const Duration(milliseconds: 16));
            expect(scrollable.position.pixels, closeTo(offset, 0.1));
          }
        }
        expect(state.changes, isEmpty);
        expect(state.editorKey.currentState!.debugUndoSnapshotCount, 0);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.linux),
    );
  }

  for (final nested in [false, true]) {
    testWidgets(
      'session retains partial tall paragraph geometry nested=$nested',
      (tester) async {
        final text = List.generate(
          500,
          (i) => 'paragraph words $i for reading',
        ).join(' ');
        final source = nested ? '> $text\n\nAfter.\n' : '$text\n\nAfter.\n';
        final state = await _mount(tester, source, MemoryRichClipboard());
        final scrollable = tester.state<ScrollableState>(
          find
              .descendant(
                of: find.byType(ScrollablePositionedList),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        scrollable.position.jumpTo(2300.25);
        await tester.pumpAndSettle();
        final top = tester.getTopLeft(_field(text)).dy;
        expect(top, lessThan(-2000));
        state.recreate(
          WysiwygEditorSessionState.fromJson(state.session.toJson()),
        );
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(_field(text)).dy, closeTo(top, 0.1));
        expect(state.changes, isEmpty);
        expect(tester.testTextInput.hasAnyClients, isTrue);
      },
    );
  }

  for (final reverse in [false, true]) {
    testWidgets(
      'desktop cross-block selection retains endpoints reverse=$reverse and replaces with composition',
      (tester) async {
        enableDesktopFocusLifecycle(tester);
        final paragraphs = List.generate(
          100,
          (i) => 'Paragraph $i ${'reading words ' * 12}'.trimRight(),
        );
        final original = '${paragraphs.join('\n\n')}\n';
        final state = await _mount(tester, original, MemoryRichClipboard());
        final gesture = await tester.startGesture(
          _caret(tester, paragraphs[reverse ? 2 : 0], reverse ? 9 : 5),
          kind: PointerDeviceKind.mouse,
        );
        await gesture.moveTo(
          _caret(tester, paragraphs[reverse ? 0 : 2], reverse ? 5 : 9),
        );
        await gesture.up();
        await tester.pumpAndSettle();
        final session = state.session;
        final targetText = paragraphs[reverse ? 0 : 2];
        final field = tester.widget<TextField>(_field(targetText));
        final scrollable = tester.state<ScrollableState>(
          find
              .descendant(
                of: find.byType(ScrollablePositionedList),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        scrollable.position.jumpTo(5000);
        await tester.pumpAndSettle();
        final offset = scrollable.position.pixels;
        await pumpDesktopFocusCycle(
          tester,
          target: field.focusNode!,
          inactiveFrames: 90,
          verifyViewport: () {
            expect(scrollable.position.pixels, closeTo(offset, 0.1));
            expect(state.session.anchorBlockId, session.anchorBlockId);
            expect(state.session.extentBlockId, session.extentBlockId);
            expect(state.session.anchorOffset, session.anchorOffset);
            expect(state.session.extentOffset, session.extentOffset);
          },
        );
        expect(state.changes, isEmpty);
        final caret = field.controller!.selection.extentOffset;
        tester.testTextInput.updateEditingValue(
          TextEditingValue(
            text: targetText.replaceRange(caret, caret, 'ni'),
            selection: TextSelection.collapsed(offset: caret + 2),
            composing: TextRange(start: caret, end: caret + 2),
          ),
        );
        await tester.pumpAndSettle();
        final expected =
            '${paragraphs.first.substring(0, 5)}你${paragraphs[2].substring(9)}';
        tester.testTextInput.updateEditingValue(
          TextEditingValue(
            text: expected,
            selection: const TextSelection.collapsed(offset: 6),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          state.source,
          '${[expected, ...paragraphs.skip(3)].join('\n\n')}\n',
        );
        expect(_caret(tester, expected, 6).dy, inInclusiveRange(0, 1100));
        final changed = state.source;
        await _command(tester, LogicalKeyboardKey.keyZ);
        expect(state.source, isNot(changed));
        await _command(tester, LogicalKeyboardKey.keyZ, shift: true);
        expect(state.source, changed);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.linux),
    );
  }

  testWidgets('dismissed dialog preserves a table cell selection', (
    tester,
  ) async {
    final state = await _mount(tester, _table, MemoryRichClipboard());
    final field = tester.widget<TextField>(_field('Body text'));
    field.focusNode!.requestFocus();
    await tester.pumpAndSettle();
    field.controller!.selection = const TextSelection(
      baseOffset: 7,
      extentOffset: 2,
    );
    await tester.pumpAndSettle();
    final dialog = showBusyMarkModalDialog<void>(
      tester.element(find.byType(BusyMarkWysiwygEditor)),
      builder: (_) => const AlertDialog(content: Text('Cancel cell dialog')),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await dialog;
    expect(
      field.controller!.selection,
      const TextSelection(baseOffset: 7, extentOffset: 2),
    );
    expect(field.focusNode!.hasFocus, isTrue);
    expect(state.changes, isEmpty);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('desktop math source remains mounted across prolonged inactivity', (
    tester,
  ) async {
    enableDesktopFocusLifecycle(tester);
    const math = r'Focus $x^2$ target';
    final state = await _mount(
      tester,
      '$math\n\n${List.generate(100, (i) => 'Reading $i ${'words ' * 20}'.trimRight()).join('\n\n')}\n',
      MemoryRichClipboard(),
      renderMath: true,
    );
    tester
        .widget<ScrollablePositionedList>(find.byType(ScrollablePositionedList))
        .itemScrollController!
        .jumpTo(index: 0);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        ValueKey('wysiwyg-rendered-math-${state.document.blocks.first.id}'),
      ),
    );
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(_field(math));
    field.controller!.selection = const TextSelection.collapsed(offset: 3);
    await tester.pumpAndSettle();
    final scrollable = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byType(ScrollablePositionedList),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    scrollable.position.jumpTo(5000);
    await tester.pumpAndSettle();
    final offset = scrollable.position.pixels;
    await pumpDesktopFocusCycle(
      tester,
      target: field.focusNode!,
      inactiveFrames: 90,
      verifyViewport: () {
        expect(scrollable.position.pixels, closeTo(offset, 0.1));
        expect(field.focusNode!.context?.mounted, isTrue);
        expect(
          field.controller!.selection,
          const TextSelection.collapsed(offset: 3),
        );
      },
    );
    expect(state.changes, isEmpty);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('queued editor focus restoration respects a newer focus owner', (
    tester,
  ) async {
    final state = await _mount(
      tester,
      'Original target.\n',
      MemoryRichClipboard(),
    );
    final other = FocusNode(
      debugLabel: 'Competing search or inspector control',
    );
    final overlay = Overlay.of(
      tester.element(find.byType(BusyMarkWysiwygEditor)),
    );
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: 0,
        top: 0,
        width: 200,
        height: 40,
        child: Material(child: TextField(focusNode: other)),
      ),
    );
    overlay.insert(entry);
    await tester.pumpAndSettle();
    state.editorKey.currentState!.restoreEditingFocus();
    other.requestFocus();
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus, same(other));
    entry.remove();
    await tester.pumpAndSettle();
    entry.dispose();
    other.dispose();
    expect(state.changes, isEmpty);
  });

  testWidgets(
    'session recreation preserves reading with an offscreen caret and immediate input',
    (tester) async {
      final paragraphs = List.generate(
        100,
        (i) => 'Paragraph $i ${'reading words ' * 12}'.trimRight(),
      );
      final state = await _mount(
        tester,
        '${paragraphs.join('\n\n')}\n',
        MemoryRichClipboard(),
      );
      final field = tester.widget<TextField>(_field(paragraphs.first));
      field.controller!.selection = const TextSelection(
        baseOffset: 10,
        extentOffset: 5,
      );
      await tester.pumpAndSettle();
      final list = tester.widget<ScrollablePositionedList>(
        find.byType(ScrollablePositionedList),
      );
      final scrollable = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byType(ScrollablePositionedList),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      scrollable.position.jumpTo(5000);
      await tester.pumpAndSettle();
      final index = list.itemPositionsNotifier!.itemPositions.value
          .firstWhere((p) => p.itemLeadingEdge > 0 && p.itemLeadingEdge < 0.8)
          .index;
      final top = tester.getTopLeft(_field(paragraphs[index])).dy;
      final saved = WysiwygEditorSessionState.fromJson(state.session.toJson());
      state.recreate(saved);
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(_field(paragraphs[index])).dy,
        closeTo(top, 0.1),
      );
      expect(state.session.anchorOffset, 10);
      expect(state.session.extentOffset, 5);
      expect(tester.testTextInput.hasAnyClients, isTrue);
      tester.testTextInput.updateEditingValue(
        TextEditingValue(
          text: paragraphs.first.replaceRange(5, 10, 'Z'),
          selection: const TextSelection.collapsed(offset: 6),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        state.source,
        startsWith(paragraphs.first.replaceRange(5, 10, 'Z')),
      );
      expect(state.changes, hasLength(1));
    },
  );

  testWidgets(
    'canceled nested menu preserves the offscreen caret and viewport',
    (tester) async {
      final paragraphs = List.generate(
        100,
        (i) => 'Paragraph $i ${'reading words ' * 12}'.trimRight(),
      );
      final state = await _mount(
        tester,
        '${paragraphs.join('\n\n')}\n',
        MemoryRichClipboard(),
      );
      final field = tester.widget<TextField>(_field(paragraphs.first));
      field.controller!.selection = const TextSelection.collapsed(offset: 3);
      await tester.pumpAndSettle();
      final scrollable = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byType(ScrollablePositionedList),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      scrollable.position.jumpTo(5000);
      await tester.pumpAndSettle();
      final offset = scrollable.position.pixels;
      final menu = showBusyMarkMenu<String>(
        context: tester.element(find.byType(BusyMarkWysiwygEditor)),
        anchorRect: const Rect.fromLTWH(100, 100, 10, 10),
        focusFirst: true,
        items: const [
          BusyMarkSubmenuItem(
            label: 'Choices',
            items: [PopupMenuItem(value: 'edit', child: Text('Edit'))],
          ),
        ],
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      for (var frame = 0; frame < 30; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(scrollable.position.pixels, closeTo(offset, 0.1));
      }
      expect(await menu, isNull);
      expect(field.focusNode!.hasFocus, isTrue);
      expect(
        field.controller!.selection,
        const TextSelection.collapsed(offset: 3),
      );
      expect(state.changes, isEmpty);
    },
  );

  for (final kind in ['list', 'code', 'table']) {
    testWidgets(
      'desktop $kind preserves selection and inner and document scroll',
      (tester) async {
        enableDesktopFocusLifecycle(tester);
        final text = 'Focus target ${'long text ' * 60}'.trimRight();
        final first = switch (kind) {
          'list' => '- $text\n',
          'code' => '```text\n$text\n```\n',
          _ => '| Header | Other |\n| --- | --- |\n| $text | Body |\n',
        };
        final source =
            '$first\n${List.generate(100, (i) => 'Reading $i ${'words ' * 20}'.trimRight()).join('\n\n')}\n';
        final state = await _mount(tester, source, MemoryRichClipboard());
        final field = tester.widget<TextField>(_field(text));
        field.focusNode!.requestFocus();
        await tester.pumpAndSettle();
        field.controller!.selection = const TextSelection(
          baseOffset: 10,
          extentOffset: 4,
        );
        await tester.pumpAndSettle();
        if (kind == 'table') field.scrollController!.jumpTo(150);
        final scrollable = tester.state<ScrollableState>(
          find
              .descendant(
                of: find.byType(ScrollablePositionedList),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        scrollable.position.jumpTo(5000);
        await tester.pumpAndSettle();
        final offset = scrollable.position.pixels;
        final innerOffset = field.scrollController!.offset;
        await pumpDesktopFocusCycle(
          tester,
          target: field.focusNode!,
          inactiveFrames: 90,
          verifyViewport: () {
            expect(scrollable.position.pixels, closeTo(offset, 0.1));
            expect(field.scrollController!.offset, closeTo(innerOffset, 0.1));
            expect(
              field.controller!.selection,
              const TextSelection(baseOffset: 10, extentOffset: 4),
            );
          },
        );
        expect(state.changes, isEmpty);
        tester.testTextInput.updateEditingValue(
          TextEditingValue(
            text: text.replaceRange(4, 10, 'Z'),
            selection: const TextSelection.collapsed(offset: 5),
          ),
        );
        await tester.pumpAndSettle();
        expect(state.source, contains(text.replaceRange(4, 10, 'Z')));
        expect(state.changes, hasLength(1));
        expect(scrollable.position.pixels, lessThan(offset - 100));
      },
      variant: TargetPlatformVariant.only(TargetPlatform.linux),
    );
  }

  for (final below in [false, true]) {
    for (final inactiveFrames in [1, 90]) {
      testWidgets(
        'desktop return preserves offscreen caret below=$below inactive=$inactiveFrames',
        (tester) async {
          enableDesktopFocusLifecycle(tester);
          final paragraphs = List.generate(
            100,
            (i) => 'Paragraph $i ${'reading words ' * 12}'.trimRight(),
          );
          final state = await _mount(
            tester,
            '${paragraphs.join('\n\n')}\n',
            MemoryRichClipboard(),
          );
          final list = tester.widget<ScrollablePositionedList>(
            find.byType(ScrollablePositionedList),
          );
          final targetIndex = below ? 70 : 0;
          list.itemScrollController!.jumpTo(index: targetIndex);
          await tester.pumpAndSettle();
          final field = tester.widget<TextField>(
            _field(paragraphs[targetIndex]),
          );
          field.focusNode!.requestFocus();
          field.controller!.selection = const TextSelection.collapsed(
            offset: 5,
          );
          await tester.pumpAndSettle();
          final scrollable = tester.state<ScrollableState>(
            find
                .descendant(
                  of: find.byType(ScrollablePositionedList),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          scrollable.position.jumpTo(
            scrollable.position.pixels + (below ? -5000 : 5000),
          );
          await tester.pumpAndSettle();
          final readingIndex = list.itemPositionsNotifier!.itemPositions.value
              .firstWhere(
                (p) => p.itemLeadingEdge > 0 && p.itemLeadingEdge < 0.8,
              )
              .index;
          final top = tester.getTopLeft(_field(paragraphs[readingIndex])).dy;
          final selection = field.controller!.selection;
          final saved = state.session;
          for (var cycle = 0; cycle < 3; cycle++) {
            await pumpDesktopFocusCycle(
              tester,
              target: field.focusNode!,
              inactiveFrames: inactiveFrames,
              verifyViewport: () {
                expect(_field(paragraphs[readingIndex]), findsOneWidget);
                expect(
                  tester.getTopLeft(_field(paragraphs[readingIndex])).dy,
                  closeTo(top, 0.1),
                );
                expect(field.controller!.selection, selection);
              },
            );
          }
          expect(state.session.activeBlockId, saved.activeBlockId);
          expect(state.changes, isEmpty);
          expect(state.undoSources, isEmpty);
          tester.testTextInput.updateEditingValue(
            TextEditingValue(
              text: paragraphs[targetIndex].replaceRange(5, 5, 'Z'),
              selection: const TextSelection.collapsed(offset: 6),
            ),
          );
          await tester.pumpAndSettle();
          expect(state.changes, hasLength(1));
          expect(
            state.source,
            contains(paragraphs[targetIndex].replaceRange(5, 5, 'Z')),
          );
          final caret = _caret(
            tester,
            paragraphs[targetIndex].replaceRange(5, 5, 'Z'),
            6,
          );
          expect(caret.dy, inInclusiveRange(0, 1100));
        },
        variant: TargetPlatformVariant.only(TargetPlatform.linux),
      );
    }
  }

  testWidgets(
    'dismissed dialog preserves the offscreen editing target and viewport',
    (tester) async {
      final paragraphs = List.generate(
        100,
        (i) => 'Paragraph $i ${'words ' * 20}'.trimRight(),
      );
      final state = await _mount(
        tester,
        '${paragraphs.join('\n\n')}\n',
        MemoryRichClipboard(),
      );
      final field = tester.widget<TextField>(_field(paragraphs.first));
      field.controller!.selection = const TextSelection(
        baseOffset: 10,
        extentOffset: 4,
      );
      await tester.pumpAndSettle();
      final scrollable = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byType(ScrollablePositionedList),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      scrollable.position.jumpTo(5000);
      await tester.pumpAndSettle();
      final pixels = scrollable.position.pixels;
      final result = showBusyMarkModalDialog<void>(
        tester.element(find.byType(BusyMarkWysiwygEditor)),
        builder: (context) =>
            const AlertDialog(content: Text('Cancel this dialog')),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(scrollable.position.pixels, closeTo(pixels, 0.1));
      }
      await result;
      expect(field.focusNode!.hasFocus, isTrue);
      expect(
        field.controller!.selection,
        const TextSelection(baseOffset: 10, extentOffset: 4),
      );
      expect(state.changes, isEmpty);
      expect(tester.testTextInput.hasAnyClients, isTrue);
    },
  );

  testWidgets('session preserves position well inside an oversized block', (
    tester,
  ) async {
    final text = List.generate(
      180,
      (i) => 'line $i has enough text for the viewport',
    ).join('\n');
    final state = await _mount(
      tester,
      '```text\n$text\n```\n\nAfter.\n',
      MemoryRichClipboard(),
    );
    final field = tester.widget<TextField>(_field(text));
    field.focusNode!.unfocus();
    await tester.pumpAndSettle();
    final scrollable = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byType(ScrollablePositionedList),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    scrollable.position.jumpTo(2300);
    await tester.pumpAndSettle();
    final top = tester.getTopLeft(_field(text)).dy;
    expect(top, lessThan(-1000));
    final saved = WysiwygEditorSessionState.fromJson(state.session.toJson());
    state.recreate(saved);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(_field(text)).dy, closeTo(top, 0.1));
    expect(state.changes, isEmpty);
  });

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

  for (final fixture in [
    (name: 'paragraphs', source: '$_before\n\nMiddle selected.\n\n$_after\n'),
    (name: 'mixed paragraph', source: _surrounded),
    (
      name: 'list extent',
      source: '$_before\n\n- Middle selected.\n- $_after\n',
    ),
    (name: 'table extent control', source: '$_before\n\n$_table'),
  ]) {
    for (final reverse in [false, true]) {
      for (final lifecycle in ['recreate', 'reuse']) {
        for (final externalHistory in [false, true]) {
          testWidgets(
            'restored direct input ${fixture.name} reverse=$reverse lifecycle=$lifecycle external=$externalHistory',
            (tester) async {
              final state = await _mount(
                tester,
                fixture.source,
                MemoryRichClipboard(),
                externalHistory: externalHistory,
              );
              final tableEdge = fixture.name == 'table extent control';
              final lastText = tableEdge ? 'End!' : _after;
              final lastOffset = tableEdge ? 4 : 5;
              final gesture = await tester.startGesture(
                _caret(
                  tester,
                  reverse ? lastText : _before,
                  reverse ? lastOffset : 6,
                ),
                pointer: 301,
                kind: PointerDeviceKind.mouse,
              );
              await gesture.moveTo(
                _caret(
                  tester,
                  reverse ? _before : lastText,
                  reverse ? 6 : lastOffset,
                ),
              );
              await gesture.up();
              await tester.pumpAndSettle();
              final saved = DocumentEditorState.fromJson(
                Map<String, Object?>.from(
                  jsonDecode(
                        jsonEncode(
                          DocumentEditorState(
                            wysiwygState: state.session,
                          ).toJson(),
                        ),
                      )
                      as Map,
                ),
              ).wysiwygState;
              final ranges = [
                for (final b in _selected(tester))
                  (b.block.id, b.selectionRange!.start, b.selectionRange!.end),
              ];
              if (lifecycle == 'recreate') {
                state.recreate(saved);
              } else {
                state.replaceSource(
                  'Other document remains.\n',
                  id: 'other',
                  restoredSession: const WysiwygEditorSessionState(),
                );
                await tester.pumpAndSettle();
                state.replaceSource(
                  fixture.source,
                  id: 'editable',
                  restoredSession: saved,
                );
              }
              await tester.pumpAndSettle();
              expect(state.session.anchorBlockId, saved.anchorBlockId);
              expect(state.session.extentBlockId, saved.extentBlockId);
              expect(state.session.anchorOffset, saved.anchorOffset);
              expect(state.session.extentOffset, saved.extentOffset);
              expect([
                for (final b in _selected(tester))
                  (b.block.id, b.selectionRange!.start, b.selectionRange!.end),
              ], ranges);
              expect(state.changes, isEmpty);
              expect(state.parses, lifecycle == 'recreate' ? 1 : 3);
              expect(state.editorKey.currentState!.debugUndoSnapshotCount, 0);
              final tableInput = tableEdge && !reverse;
              final extentText = reverse ? _before : _after;
              final extentOffset = reverse ? 6 : 5;
              if (!tableInput) {
                final field = tester.widget<TextField>(_field(extentText));
                expect(
                  field.focusNode!.hasFocus,
                  isTrue,
                  reason: 'restored extent must own ordinary input',
                );
                expect(
                  tester.testTextInput.editingState,
                  field.controller!.value.toJSON(),
                );
              }
              expect(tester.testTextInput.hasAnyClients, isTrue);
              const committed = '你🧭';
              tester.testTextInput.updateEditingValue(
                TextEditingValue(
                  text: tableInput
                      ? committed
                      : extentText.replaceRange(
                          extentOffset,
                          extentOffset,
                          committed,
                        ),
                  selection: TextSelection.collapsed(
                    offset: tableInput
                        ? committed.length
                        : extentOffset + committed.length,
                  ),
                ),
              );
              await tester.pumpAndSettle();
              final suffix = tableEdge ? '' : ' stays.';
              final replaced = 'Before$committed$suffix';
              expect(state.source, '$replaced\n');
              expect(
                state.document.blocks.single.kind,
                BusyBlockKind.paragraph,
              );
              expect(state.document.blocks.single.plainText, replaced);
              expect(state.changes, hasLength(1));
              expect(_selected(tester), isEmpty);
              final field = tester.widget<TextField>(_field(replaced));
              expect(field.focusNode!.hasFocus, isTrue);
              expect(
                field.controller!.selection.extentOffset,
                6 + committed.length,
              );
              final continued = 'Before$committed next$suffix';
              tester.testTextInput.updateEditingValue(
                TextEditingValue(
                  text: continued,
                  selection: TextSelection.collapsed(
                    offset: 6 + committed.length + 5,
                  ),
                ),
              );
              await tester.pumpAndSettle();
              expect(state.source, '$continued\n');
              expect(state.changes, hasLength(2));
              await _command(tester, LogicalKeyboardKey.keyZ);
              expect(state.source, '$replaced\n');
              await _command(tester, LogicalKeyboardKey.keyZ);
              expect(state.source, fixture.source);
              await _command(tester, LogicalKeyboardKey.keyZ, shift: true);
              expect(state.source, '$replaced\n');
              await _command(tester, LogicalKeyboardKey.keyZ, shift: true);
              expect(state.source, '$continued\n');
            },
          );
        }
      }
    }
  }

  for (final mixed in [false, true]) {
    for (final reverse in [false, true]) {
      for (final cancel in [false, true]) {
        testWidgets(
          'restored ordinary composition matches fresh mixed=$mixed reverse=$reverse cancel=$cancel',
          (tester) async {
            final source = mixed
                ? _surrounded
                : '$_before\n\nMiddle selected.\n\n$_after\n';
            final traces = <List<Object?>>[];
            for (final restored in [false, true]) {
              await tester.pumpWidget(const SizedBox());
              final state = await _mount(tester, source, MemoryRichClipboard());
              final gesture = await tester.startGesture(
                _caret(tester, reverse ? _after : _before, reverse ? 5 : 6),
                pointer: 302,
                kind: PointerDeviceKind.mouse,
              );
              await gesture.moveTo(
                _caret(tester, reverse ? _before : _after, reverse ? 6 : 5),
              );
              await gesture.up();
              await tester.pumpAndSettle();
              if (restored) {
                state.recreate(
                  WysiwygEditorSessionState.fromJson(
                    Map<String, Object?>.from(
                      jsonDecode(jsonEncode(state.session.toJson())) as Map,
                    ),
                  ),
                );
                await tester.pumpAndSettle();
              }
              expect(state.changes, isEmpty);
              final extent = reverse ? _before : _after;
              final offset = reverse ? 6 : 5;
              expect(
                tester.widget<TextField>(_field(extent)).focusNode!.hasFocus,
                isTrue,
              );
              expect(tester.testTextInput.hasAnyClients, isTrue);
              final trace = <Object?>[];
              for (final preedit in ['n', 'ni', cancel ? '' : '你🧭']) {
                final initial = state.changes.isEmpty;
                final text = initial
                    ? extent.replaceRange(offset, offset, preedit)
                    : 'Before$preedit stays.';
                final caret = initial
                    ? offset + preedit.length
                    : 6 + preedit.length;
                tester.testTextInput.updateEditingValue(
                  TextEditingValue(
                    text: text,
                    selection: TextSelection.collapsed(offset: caret),
                    composing: preedit == 'n' || preedit == 'ni'
                        ? TextRange(start: initial ? offset : 6, end: caret)
                        : TextRange.empty,
                  ),
                );
                await tester.pumpAndSettle();
                final focused = tester
                    .widgetList<TextField>(find.byType(TextField))
                    .singleWhere((f) => f.focusNode!.hasFocus);
                trace.add((
                  state.source,
                  state.changes.length,
                  _selected(tester).length,
                  focused.controller!.value,
                  state.editorKey.currentState!.debugUndoSnapshotCount,
                ));
              }
              final finalText = cancel ? 'Before stays.' : 'Before你🧭 stays.';
              expect(state.source, '$finalText\n');
              expect(state.document.blocks.single.plainText, finalText);
              expect(_selected(tester), isEmpty);
              // Ordinary fields accept preedit immediately. Cancellation removes
              // that preedit locally; it does not resurrect the selected blocks.
              expect(state.changes.first, 'Beforen stays.\n');
              final accepted = state.changes.length;
              final focused = tester.widget<TextField>(_field(finalText));
              tester.testTextInput.updateEditingValue(
                focused.controller!.value,
              );
              await tester.pumpAndSettle();
              expect(state.changes, hasLength(accepted));
              await _command(tester, LogicalKeyboardKey.keyZ);
              trace.add(state.source);
              await _command(tester, LogicalKeyboardKey.keyZ, shift: true);
              expect(state.source, '$finalText\n');
              traces.add(trace);
            }
            expect(
              traces.last,
              traces.first,
              reason:
                  'restoration must preserve the ordinary-field composition contract',
            );
          },
        );
      }
    }
  }

  for (final cell in [false, true]) {
    testWidgets(
      'restored local ${cell ? 'cell' : 'paragraph'} accepts immediate Unicode input',
      (tester) async {
        final state = await _mount(tester, _surrounded, MemoryRichClipboard());
        final text = cell ? 'Body text' : _before;
        await tester.tap(_field(text));
        tester.widget<TextField>(_field(text)).controller!.selection =
            const TextSelection(baseOffset: 5, extentOffset: 1);
        await tester.pumpAndSettle();
        state.recreate(
          WysiwygEditorSessionState.fromJson(
            Map<String, Object?>.from(
              jsonDecode(jsonEncode(state.session.toJson())) as Map,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(_selected(tester), isEmpty);
        final field = tester.widget<TextField>(_field(text));
        expect(field.focusNode!.hasFocus, isTrue);
        expect(tester.testTextInput.hasAnyClients, isTrue);
        expect(
          tester.testTextInput.editingState,
          field.controller!.value.toJSON(),
        );
        final next = text.replaceRange(1, 5, '你🧭');
        tester.testTextInput.updateEditingValue(
          TextEditingValue(
            text: next,
            selection: const TextSelection.collapsed(offset: 4),
          ),
        );
        await tester.pumpAndSettle();
        expect(state.source, _surrounded.replaceFirst(text, next));
        expect(
          state.document.blocks.where((b) => b.kind == BusyBlockKind.table),
          hasLength(1),
        );
        expect(state.changes, hasLength(1));
        expect(
          tester
              .widget<TextField>(_field(next))
              .controller!
              .selection
              .extentOffset,
          4,
        );
        await _command(tester, LogicalKeyboardKey.keyZ);
        expect(state.source, _surrounded);
        await _command(tester, LogicalKeyboardKey.keyZ, shift: true);
        expect(state.source, _surrounded.replaceFirst(text, next));
      },
    );
  }

  for (final superseded in [
    'caret',
    'range',
    'document',
    'tab replacement',
    'disposal',
  ]) {
    testWidgets(
      'restored input focus is superseded by $superseded before handoff',
      (tester) async {
        const source = 'Before stays.\n\nMiddle selected.\n\nAfter stays.\n';
        final state = await _mount(tester, source, MemoryRichClipboard());
        final gesture = await tester.startGesture(
          _caret(tester, _before, 6),
          pointer: 303,
          kind: PointerDeviceKind.mouse,
        );
        await gesture.moveTo(_caret(tester, _after, 5));
        await gesture.up();
        await tester.pumpAndSettle();
        final saved = state.session;
        state.recreate(saved);
        // This frame installs the restored range and queues its guarded handoff.
        // Supersede it before the next frame runs that handoff.
        await tester.pump();
        switch (superseded) {
          case 'caret':
            await tester.tapAt(_caret(tester, 'Middle selected.', 7));
          case 'range':
            final newer = await tester.startGesture(
              _caret(tester, 'Middle selected.', 2),
              pointer: 304,
              kind: PointerDeviceKind.mouse,
            );
            await newer.moveTo(_caret(tester, _before, 3));
            await newer.up();
          case 'document':
            state.replaceSource(
              'Current document.\n',
              id: 'current',
              restoredSession: const WysiwygEditorSessionState(),
            );
          case 'tab replacement':
            state.replaceSource(
              'Current document.\n',
              id: 'current',
              restoredSession: const WysiwygEditorSessionState(),
            );
            state.recreate(const WysiwygEditorSessionState());
          case 'disposal':
            await tester.pumpWidget(const SizedBox());
        }
        await tester.pumpAndSettle();
        expect(state.changes, isEmpty);
        expect(tester.takeException(), isNull);
        if (superseded == 'disposal') {
          expect(tester.testTextInput.hasAnyClients, isFalse);
          return;
        }
        final target = superseded == 'caret'
            ? 'Middle selected.'
            : superseded == 'range'
            ? _before
            : 'Current document.';
        final field = tester.widget<TextField>(_field(target));
        expect(field.focusNode!.hasFocus, isTrue);
        expect(tester.testTextInput.hasAnyClients, isTrue);
        expect(
          tester.testTextInput.editingState,
          field.controller!.value.toJSON(),
        );
        if (superseded == 'range') {
          expect(state.session.anchorBlockId, state.document.blocks[1].id);
          expect(state.session.extentBlockId, state.document.blocks.first.id);
          expect(state.session.extentOffset, 3);
        } else {
          expect(_selected(tester), isEmpty);
        }
        final offset = field.controller!.selection.extentOffset;
        tester.testTextInput.updateEditingValue(
          TextEditingValue(
            text: target.replaceRange(offset, offset, 'X'),
            selection: TextSelection.collapsed(offset: offset + 1),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          state.source,
          superseded == 'range'
              ? 'BefXddle selected.\n\nAfter stays.\n'
              : (superseded == 'caret'
                    ? source.replaceFirst(
                        target,
                        target.replaceRange(offset, offset, 'X'),
                      )
                    : '${target.replaceRange(offset, offset, 'X')}\n'),
        );
        expect(state.changes, hasLength(1));
      },
    );
  }

  testWidgets('restored ordinary input retains a scrolled viewport', (
    tester,
  ) async {
    final paragraphs = [
      for (var i = 0; i < 50; i++) 'Paragraph $i with enough text.',
    ];
    final source = '${paragraphs.join('\n\n')}\n';
    final state = await _mount(tester, source, MemoryRichClipboard());
    final list = tester.widget<ScrollablePositionedList>(
      find.byType(ScrollablePositionedList),
    );
    final gesture = await tester.startGesture(
      _caret(tester, paragraphs.first, 5),
      pointer: 305,
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveTo(_caret(tester, paragraphs[2], 5));
    await tester.pumpAndSettle();
    list.itemScrollController!.jumpTo(index: 35, alignment: 0.1);
    await tester.pumpAndSettle();
    await gesture.moveTo(_caret(tester, paragraphs[37], 9));
    await gesture.up();
    await tester.pumpAndSettle();
    final saved = WysiwygEditorSessionState.fromJson(
      Map<String, Object?>.from(
        jsonDecode(jsonEncode(state.session.toJson())) as Map,
      ),
    );
    final parses = state.parses;
    state.recreate(saved);
    await tester.pumpAndSettle();
    expect(state.session.viewportBlockId, saved.viewportBlockId);
    expect(
      state.session.viewportAlignment,
      closeTo(saved.viewportAlignment, 0.01),
    );
    expect(state.session.anchorBlockId, saved.anchorBlockId);
    expect(state.session.extentBlockId, saved.extentBlockId);
    final field = tester.widget<TextField>(_field(paragraphs[37]));
    expect(field.focusNode!.hasFocus, isTrue);
    expect(tester.testTextInput.hasAnyClients, isTrue);
    expect(tester.testTextInput.editingState, field.controller!.value.toJSON());
    expect(state.changes, isEmpty);
    expect(state.parses, parses);
    tester.testTextInput.updateEditingValue(
      TextEditingValue(
        text: paragraphs[37].replaceRange(9, 9, '你🧭'),
        selection: const TextSelection.collapsed(offset: 12),
      ),
    );
    await tester.pumpAndSettle();
    final replacement =
        '${paragraphs.first.substring(0, 5)}你🧭${paragraphs[37].substring(9)}';
    expect(
      state.source,
      '${[replacement, ...paragraphs.skip(38)].join('\n\n')}\n',
    );
    expect(state.changes, hasLength(1));
  });

  testWidgets('restored ordinary input uses clamped session offsets', (
    tester,
  ) async {
    final state = await _mount(
      tester,
      '$_before\n\n$_after\n',
      MemoryRichClipboard(),
    );
    await tester.tap(_field(_before));
    await _command(tester, LogicalKeyboardKey.keyA);
    await _command(tester, LogicalKeyboardKey.keyA);
    final json = Map<String, Object?>.from(
      jsonDecode(jsonEncode(state.session.toJson())) as Map,
    );
    json['anchorOffset'] = -10;
    json['extentOffset'] = 10000;
    state.recreate(WysiwygEditorSessionState.fromJson(json));
    await tester.pumpAndSettle();
    expect(state.session.anchorOffset, 0);
    expect(state.session.extentOffset, _after.length);
    final field = tester.widget<TextField>(_field(_after));
    expect(field.focusNode!.hasFocus, isTrue);
    expect(tester.testTextInput.editingState, field.controller!.value.toJSON());
    expect(state.changes, isEmpty);
    await _input(tester, '$_after你🧭');
    expect(state.source, '你🧭\n');
    expect(state.changes, hasLength(1));
  });
}
