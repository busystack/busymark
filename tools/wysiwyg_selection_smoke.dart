// Native Linux selection acceptance probe. Reads a disposable document copy,
// drives production key/pointer handlers, and uses the real Linux clipboard.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_block_widgets.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_session_state.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/platform/rich_clipboard_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main(List<String> arguments) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (arguments.length != 2) {
    throw ArgumentError('INPUT_MARKDOWN OUTPUT_DIRECTORY');
  }
  final root = await Directory.systemTemp.createTemp('busymark-selection-');
  final copy = await File(arguments[0]).copy('${root.path}/selection.md');
  final output = await Directory(arguments[1]).create(recursive: true);
  final document = const MarkdownParser()
      .parse(filePath: copy.path, source: await copy.readAsString())
      .busyDocument;
  await windowManager.ensureInitialized();
  await windowManager.setSize(const Size(1100, 950));
  runApp(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: _Probe(document: document, output: output),
    ),
  );
}

class _Probe extends StatefulWidget {
  const _Probe({required this.document, required this.output});
  final BusyDocument document;
  final Directory output;
  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  final _boundary = GlobalKey();
  final _clipboard = RichClipboardService();
  final _reports = <Map<String, Object?>>[];
  WysiwygEditorSessionState _session = const WysiwygEditorSessionState();
  int _pointer = 100;
  int _edits = 0;

  @override
  void initState() {
    super.initState();
    unawaited(Future<void>.delayed(const Duration(seconds: 2), _run));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: RepaintBoundary(
      key: _boundary,
      child: BusyMarkWysiwygEditor(
        document: widget.document,
        clipboardService: _clipboard,
        onSessionChanged: (_, session) => _session = session,
        onSourceChanged: (_, _) => _edits++,
      ),
    ),
  );

  List<Element> _elements(bool Function(Widget) predicate, [Element? root]) {
    final result = <Element>[];
    void visit(Element element) {
      if (predicate(element.widget)) result.add(element);
      element.visitChildren(visit);
    }

    visit(root ?? _boundary.currentContext! as Element);
    return result;
  }

  Element _field(String text) =>
      _elements((w) => w is TextField && w.controller?.text == text).single;

  RenderEditable _editable(Element field) =>
      ((_elements((w) => w is EditableText, field).single as StatefulElement)
                  .state
              as EditableTextState)
          .renderEditable;

  Future<void> _pause() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    await WidgetsBinding.instance.endOfFrame;
  }

  void _keyData(
    PhysicalKeyboardKey physical,
    LogicalKeyboardKey logical,
    ui.KeyEventType type,
  ) {
    // Dispatch framework key messages as well as updating HardwareKeyboard.
    // Synthesized events dispatch immediately without a native raw key event.
    // ignore: deprecated_member_use
    ServicesBinding.instance.keyEventManager.handleKeyData(
      ui.KeyData(
        timeStamp: Duration.zero,
        type: type,
        physical: physical.usbHidUsage,
        logical: logical.keyId,
        character: null,
        synthesized: true,
      ),
    );
  }

  Future<void> _key(
    PhysicalKeyboardKey physical,
    LogicalKeyboardKey logical,
  ) async {
    _keyData(
      PhysicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.controlLeft,
      ui.KeyEventType.down,
    );
    _keyData(physical, logical, ui.KeyEventType.down);
    _keyData(physical, logical, ui.KeyEventType.up);
    _keyData(
      PhysicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.controlLeft,
      ui.KeyEventType.up,
    );
    await _pause();
  }

  Future<void> _jump(int index) async {
    final list =
        _elements((w) => w is ScrollablePositionedList).single.widget
            as ScrollablePositionedList;
    list.itemScrollController!.jumpTo(index: index, alignment: 0.1);
    await _pause();
  }

  Future<void> _capture(String label) async {
    await _pause();
    final image =
        await (_boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary)
            .toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    await File(
      '${widget.output.path}/$label.png',
    ).writeAsBytes(data!.buffer.asUint8List());
  }

  Future<String?> _record(
    String label, {
    ({String anchorId, int anchorOffset, String extentId, int extentOffset})?
    expectedRange,
    String? expectedCopy,
    List<String> needles = const [],
    String? localFieldText,
    TextSelection? localSelection,
  }) async {
    await _key(PhysicalKeyboardKey.keyC, LogicalKeyboardKey.keyC);
    final copied = await _clipboard.read();
    await File(
      '${widget.output.path}/$label-clipboard.txt',
    ).writeAsString(copied.text ?? '');
    await File(
      '${widget.output.path}/$label-clipboard.md',
    ).writeAsString(copied.sourceText ?? '');
    final geometry = <Map<String, Object?>>[];
    for (final blockElement in _elements(
      (w) => w is BusyMarkWysiwygBlockField,
    )) {
      final block = blockElement.widget as BusyMarkWysiwygBlockField;
      final range = block.selectionRange;
      if (range == null) continue;
      for (final fieldElement in _elements(
        (w) => w is TextField,
        blockElement,
      )) {
        final field = fieldElement.widget as TextField;
        final editable = _editable(fieldElement);
        Element? stack;
        fieldElement.visitAncestorElements((element) {
          if (element.widget is Stack) {
            stack = element;
            return false;
          }
          return true;
        });
        final overlays = _elements(
          (w) =>
              w is CustomPaint &&
              w.painter.runtimeType.toString().contains('SelectionPainter'),
          stack,
        );
        final canvas = _RectCanvas();
        if (overlays.isNotEmpty) {
          final overlay = overlays.single;
          (overlay.widget as CustomPaint).painter!.paint(
            canvas,
            (overlay.findRenderObject()! as RenderBox).size,
          );
        }
        final start = block.block.kind == BusyBlockKind.table ? 0 : range.start;
        final end = block.block.kind == BusyBlockKind.table
            ? field.controller!.text.length
            : range.end;
        final expected = editable.getBoxesForSelection(
          TextSelection(baseOffset: start, extentOffset: end),
        );
        final match =
            expected.length == canvas.rects.length &&
            [
              for (
                var i = 0;
                i < expected.length && i < canvas.rects.length;
                i++
              )
                (expected[i].toRect().left - canvas.rects[i].left).abs() <
                        0.1 &&
                    (expected[i].toRect().right - canvas.rects[i].right).abs() <
                        0.1 &&
                    (expected[i].toRect().top - canvas.rects[i].top).abs() <
                        0.1 &&
                    (expected[i].toRect().bottom - canvas.rects[i].bottom)
                            .abs() <
                        0.1,
            ].every((value) => value);
        geometry.add({
          'block': block.block.id,
          'kind': block.block.kind.name,
          'localStart': start,
          'localEnd': end,
          'textLength': field.controller!.text.length,
          'sourceLength': block.block.rawSource?.length,
          'blockTextLength': block.block.plainText.length,
          'renderedLength': editable.text?.toPlainText().length,
          'actualRects': canvas.rects
              .map((r) => [r.left, r.top, r.right, r.bottom])
              .toList(),
          'expectedRects': expected
              .map((b) => [b.left, b.top, b.right, b.bottom])
              .toList(),
          'geometryMatches': match,
          'copiedCompleteText': copied.text?.contains(field.controller!.text),
        });
      }
    }
    final local = localFieldText == null
        ? null
        : (_field(localFieldText).widget as TextField).controller!.selection;
    final checks = {
      'logicalRange':
          expectedRange == null ||
          (_session.anchorBlockId == expectedRange.anchorId &&
              _session.anchorOffset == expectedRange.anchorOffset &&
              _session.extentBlockId == expectedRange.extentId &&
              _session.extentOffset == expectedRange.extentOffset),
      'localRange': localSelection == null || local == localSelection,
      'clipboard':
          (expectedCopy == null || copied.text == expectedCopy) &&
          needles.every((needle) => copied.text?.contains(needle) == true),
      'geometry': geometry.every((entry) => entry['geometryMatches'] == true),
      'documentHighlightPresent': localFieldText != null || geometry.isNotEmpty,
    };
    _reports.add({
      'case': label,
      'logicalSelection': _session.toJson(),
      'clipboardLength': copied.text?.length,
      'localFieldSelection': local == null ? null : [local.start, local.end],
      'checks': checks,
      'geometry': geometry,
    });
    await _capture(label);
    stdout.writeln('$label: $checks');
    return copied.text;
  }

  Offset _caret(String text, int offset) {
    final editable = _editable(_field(text));
    return editable.localToGlobal(
      editable.getLocalRectForCaret(TextPosition(offset: offset)).center,
    );
  }

  Future<void> _drag(
    String startText,
    int startOffset,
    String endText,
    int endOffset, {
    int? scrollTo,
  }) async {
    final start = _caret(startText, startOffset);
    final pointer = ++_pointer;
    final viewId = View.of(context).viewId;
    GestureBinding.instance.handlePointerEvent(
      PointerDownEvent(
        viewId: viewId,
        pointer: pointer,
        position: start,
        buttons: kPrimaryMouseButton,
        kind: PointerDeviceKind.mouse,
      ),
    );
    // Start the local drag and allow its normal focus/caret reveal to settle
    // before locating the destination in the current viewport.
    var previous = start + const Offset(24, 0);
    GestureBinding.instance.handlePointerEvent(
      PointerMoveEvent(
        viewId: viewId,
        pointer: pointer,
        position: previous,
        delta: const Offset(24, 0),
        buttons: kPrimaryMouseButton,
        kind: PointerDeviceKind.mouse,
      ),
    );
    await _pause();
    if (scrollTo != null) {
      await _pause();
      // Establish a document selection before scrolling, as in a continued
      // drag through adjacent blocks followed by a wheel/viewport change.
      GestureBinding.instance.handlePointerEvent(
        PointerMoveEvent(
          viewId: viewId,
          pointer: pointer,
          position: start + const Offset(0, 70),
          delta: const Offset(0, 70),
          buttons: kPrimaryMouseButton,
          kind: PointerDeviceKind.mouse,
        ),
      );
      await _pause();
      await _jump(scrollTo);
    }
    final end = _caret(endText, endOffset);
    for (var step = 1; step <= 10; step++) {
      final position = Offset.lerp(start, end, step / 10)!;
      GestureBinding.instance.handlePointerEvent(
        PointerMoveEvent(
          viewId: viewId,
          pointer: pointer,
          position: position,
          delta: position - previous,
          buttons: kPrimaryMouseButton,
          kind: PointerDeviceKind.mouse,
        ),
      );
      previous = position;
      await _pause();
    }
    GestureBinding.instance.handlePointerEvent(
      PointerUpEvent(
        viewId: viewId,
        pointer: pointer,
        position: end,
        kind: PointerDeviceKind.mouse,
      ),
    );
    await _pause();
  }

  Future<void> _run() async {
    Object? failure;
    try {
      final blocks = widget.document.blocks;
      ({String anchorId, int anchorOffset, String extentId, int extentOffset})
      range(
        BusyBlock anchor,
        int anchorOffset,
        BusyBlock extent,
        int extentOffset,
      ) => (
        anchorId: anchor.id,
        anchorOffset: anchorOffset,
        extentId: extent.id,
        extentOffset: extentOffset,
      );
      final first = blocks.firstWhere((b) => b.inlines.isNotEmpty);
      final firstField = _field(first.plainText).widget as TextField;
      firstField.focusNode!.requestFocus();
      firstField.controller!.selection = const TextSelection.collapsed(
        offset: 0,
      );
      await _pause();
      await _key(PhysicalKeyboardKey.keyA, LogicalKeyboardKey.keyA);
      await _record(
        '01-local-select-all',
        expectedCopy: first.plainText,
        localFieldText: first.plainText,
        localSelection: TextSelection(
          baseOffset: 0,
          extentOffset: first.plainText.length,
        ),
      );
      await _key(PhysicalKeyboardKey.keyA, LogicalKeyboardKey.keyA);
      final globalRange = range(
        blocks.first,
        0,
        blocks.last,
        blocks.last.plainText.length,
      );
      final globalCopy = await _record(
        '02-document-select-all',
        expectedRange: globalRange,
        needles: const [
          '/mnt/Media/Linguality/gateway',
          '/mnt/Media/Linguality/learner_client',
          'not the final integration result.',
        ],
      );
      await _key(PhysicalKeyboardKey.keyA, LogicalKeyboardKey.keyA);
      await _record(
        '03-repeat-select-all',
        expectedRange: globalRange,
        expectedCopy: globalCopy,
      );
      await _key(PhysicalKeyboardKey.keyA, LogicalKeyboardKey.keyA);
      final paragraphIndex = blocks.indexWhere(
        (b) => b.plainText.contains(
          'The client must work before corpus population finishes.',
        ),
      );
      await _jump(paragraphIndex - 1);
      final paragraph = blocks[paragraphIndex];
      await _record(
        '04-scroll-selection',
        expectedRange: globalRange,
        expectedCopy: globalCopy,
      );
      final preceding = blocks[paragraphIndex - 1];
      final following = blocks[paragraphIndex + 1];
      await _drag(
        preceding.plainText,
        0,
        following.plainText,
        following.plainText.length,
      );
      await _record(
        '05-paragraph-drag',
        expectedRange: range(
          preceding,
          0,
          following,
          following.plainText.length,
        ),
        expectedCopy:
            '${preceding.plainText}\n\n${paragraph.plainText}\n\n${following.plainText}',
      );
      await _drag(
        paragraph.plainText,
        0,
        paragraph.plainText,
        paragraph.plainText.length,
      );
      await _record(
        '06-paragraph-alone',
        expectedCopy: paragraph.plainText,
        localFieldText: paragraph.plainText,
        localSelection: TextSelection(
          baseOffset: 0,
          extentOffset: paragraph.plainText.length,
        ),
      );
      final listIndex = blocks.indexWhere(
        (b) => b.plainText == '/mnt/Media/Linguality/gateway',
      );
      await _jump(listIndex - 1);
      await _drag(
        blocks[listIndex - 1].plainText,
        0,
        blocks[listIndex + 2].plainText,
        blocks[listIndex + 2].plainText.length,
      );
      await _record(
        '07-list-drag',
        expectedRange: range(
          blocks[listIndex - 1],
          0,
          blocks[listIndex + 2],
          blocks[listIndex + 2].plainText.length,
        ),
        needles: [
          '/mnt/Media/Linguality/gateway',
          '/mnt/Media/Linguality/learner_client',
          blocks[listIndex + 2].plainText,
        ],
      );
      final tableIndex = blocks.indexWhere(
        (b) => b.kind == BusyBlockKind.table,
      );
      await _jump(tableIndex - 1);
      await _drag(
        blocks[tableIndex - 1].plainText,
        0,
        blocks[tableIndex + 1].plainText,
        blocks[tableIndex + 1].plainText.length,
      );
      final table = blocks[tableIndex];
      final cells = table.children.expand((row) => row.children).toList();
      final tableRange = range(
        blocks[tableIndex - 1],
        0,
        blocks[tableIndex + 1],
        blocks[tableIndex + 1].plainText.length,
      );
      final tableCopy = await _record(
        '08-table-drag',
        expectedRange: tableRange,
        needles: [for (final cell in cells) cell.plainText],
      );
      await windowManager.setSize(const Size(760, 950));
      await _pause();
      await _record(
        '09-rewrapped-selection',
        expectedRange: tableRange,
        expectedCopy: tableCopy,
      );
      await _jump(listIndex - 1);
      await _drag(
        blocks[listIndex - 1].plainText,
        0,
        following.plainText,
        following.plainText.length,
        scrollTo: paragraphIndex,
      );
      await _record(
        '10-drag-with-scroll',
        expectedRange: range(
          blocks[listIndex - 1],
          0,
          following,
          following.plainText.length,
        ),
        needles: [
          paragraph.plainText,
          '/mnt/Media/Linguality/gateway',
          '/mnt/Media/Linguality/learner_client',
          for (final cell in cells) cell.plainText,
        ],
      );
      await _jump(paragraphIndex);
      await _drag(paragraph.plainText, 55, following.plainText, 17);
      await _record(
        '11-styled-drag-endpoints',
        expectedRange: range(paragraph, 55, following, 17),
        expectedCopy:
            '${paragraph.plainText.substring(55)}\n\n${following.plainText.substring(0, 17)}',
      );
      await _jump(tableIndex);
      await _drag(cells.first.plainText, 1, cells.first.plainText, 3);
      await _record(
        '12-cell-local-drag',
        expectedCopy: cells.first.plainText.substring(1, 3),
        localFieldText: cells.first.plainText,
        localSelection: const TextSelection(baseOffset: 1, extentOffset: 3),
      );
      await _drag(
        cells.first.plainText,
        0,
        cells.last.plainText,
        cells.last.plainText.length,
      );
      await _record(
        '13-cross-cell-drag',
        expectedRange: range(table, 0, table, 0),
        needles: [for (final cell in cells) cell.plainText],
      );
    } catch (error, stack) {
      failure = '$error\n$stack';
      stderr.writeln(failure);
    }
    await File('${widget.output.path}/report.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'failure': failure?.toString(),
        'edits': _edits,
        'cases': _reports,
      }),
    );
    final checksPass = _reports.every(
      (report) => (report['checks'] as Map<String, bool>).values.every(
        (value) => value,
      ),
    );
    exit(failure == null && _edits == 0 && checksPass ? 0 : 1);
  }
}

class _RectCanvas implements Canvas {
  final rects = <Rect>[];
  @override
  void drawRect(Rect rect, Paint paint) => rects.add(rect);
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
