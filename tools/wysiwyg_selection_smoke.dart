// Native Linux selection acceptance probe. Reads a disposable document copy,
// drives production key/pointer handlers, and uses the real Linux clipboard.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:busymark/main.dart' as application;
import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_block_widgets.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_session_state.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/platform/rich_clipboard_service.dart';
import 'package:busymark/src/workspace/workspace_controller.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.length == 3 && arguments.first == '--application') {
    final binding = _ApplicationProbeBinding();
    await application.main([arguments[1]]);
    unawaited(
      Future<void>.delayed(const Duration(seconds: 2), () async {
        await _ApplicationProbeDriver(
          boundary: binding.boundary,
          fixture: File(arguments[1]),
          output: await Directory(arguments[2]).create(recursive: true),
        ).run();
      }),
    );
    return;
  }
  _ProbeBinding();
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

// Observe the real client ID while forwarding every platform request. Text
// updates below are delivered on the engine's incoming text-input channel;
// clipboard requests still reach the Linux plugin unchanged.
class _ProbeBinding extends WidgetsFlutterBinding {
  @override
  BinaryMessenger createBinaryMessenger() =>
      _ProbeMessenger(super.createBinaryMessenger());
}

class _ApplicationProbeBinding extends _ProbeBinding {
  final boundary = GlobalKey();

  @override
  Widget wrapWithDefaultView(Widget rootWidget) => super.wrapWithDefaultView(
    RepaintBoundary(key: boundary, child: rootWidget),
  );
}

class _ProbeMessenger extends BinaryMessenger {
  _ProbeMessenger(this.delegate);
  final BinaryMessenger delegate;
  static int? clientId;

  @override
  Future<ByteData?>? send(String channel, ByteData? message) {
    if (channel == SystemChannels.textInput.name && message != null) {
      final call = SystemChannels.textInput.codec.decodeMethodCall(message);
      if (call.method == 'TextInput.setClient') {
        clientId = (call.arguments as List).first as int;
      }
      if (call.method == 'TextInput.clearClient') clientId = null;
    }
    return delegate.send(channel, message);
  }

  @override
  void setMessageHandler(String channel, MessageHandler? handler) =>
      delegate.setMessageHandler(channel, handler);

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
  late BusyDocument _liveDocument = widget.document;
  late String _liveSource = widget.document.source ?? '';
  var _editorKey = UniqueKey();
  bool _editableMode = false;
  int _acceptedEdits = 0;
  int _syntheticParses = 0;
  WysiwygEditorSessionState _initialSession = const WysiwygEditorSessionState();

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
        key: _editorKey,
        document: _liveDocument,
        clipboardService: _clipboard,
        initialSessionState: _initialSession,
        onSessionChanged: (_, session) => _session = session,
        onSourceChanged: (_, value) {
          if (!_editableMode) {
            _edits++;
            return;
          }
          _acceptedEdits++;
          setState(() {
            _liveSource = value;
            _syntheticParses++;
            _liveDocument = const MarkdownParser()
                .parse(filePath: _liveDocument.filePath, source: value)
                .busyDocument;
          });
        },
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

  Future<void> _pause() => _ProbeInput.pause();

  void _keyData(
    PhysicalKeyboardKey physical,
    LogicalKeyboardKey logical,
    ui.KeyEventType type,
  ) {
    _ProbeInput.keyData(physical, logical, type);
  }

  Future<void> _key(
    PhysicalKeyboardKey physical,
    LogicalKeyboardKey logical, {
    bool shift = false,
  }) => _ProbeInput.command(physical, logical, shift: shift);

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
    bool cancel = false,
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
      cancel
          ? PointerCancelEvent(
              viewId: viewId,
              pointer: pointer,
              position: start,
              kind: PointerDeviceKind.mouse,
            )
          : PointerUpEvent(
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
      await _runEditableCases();
    } catch (error, stack) {
      failure = '$error\n$stack';
      stderr.writeln(failure);
    }
    await File('${widget.output.path}/report.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'failure': failure?.toString(),
        'edits': _edits,
        'acceptedSyntheticEdits': _acceptedEdits,
        'syntheticParses': _syntheticParses,
        'inputMethod':
            'framework-dispatched key/pointer events and engine-channel text-input editing updates; real Linux clipboard',
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

  static const _syntheticTable =
      '| Header | Longer header |\n| --- | --- |\n| Short | Body text |\n| Last | End! |\n';

  Future<void> _setSynthetic(
    String source, {
    WysiwygEditorSessionState session = const WysiwygEditorSessionState(),
  }) async {
    setState(() {
      _editableMode = true;
      _liveSource = source;
      _syntheticParses++;
      _liveDocument = const MarkdownParser()
          .parse(filePath: '${widget.output.path}/synthetic.md', source: source)
          .busyDocument;
      _editorKey = UniqueKey();
      _initialSession = session;
      _session = const WysiwygEditorSessionState();
    });
    await _pause();
    await _pause();
  }

  Future<void> _selectSyntheticTable() async {
    final field = _field('Header').widget as TextField;
    field.focusNode!.requestFocus();
    field.controller!.selection = const TextSelection.collapsed(offset: 0);
    await _pause();
    await _key(PhysicalKeyboardKey.keyA, LogicalKeyboardKey.keyA);
    await _key(PhysicalKeyboardKey.keyA, LogicalKeyboardKey.keyA);
  }

  Future<void> _press(
    PhysicalKeyboardKey physical,
    LogicalKeyboardKey logical,
  ) async {
    _keyData(physical, logical, ui.KeyEventType.down);
    _keyData(physical, logical, ui.KeyEventType.up);
    await _pause();
  }

  Future<void> _deliverText(
    String text, {
    TextRange composing = TextRange.empty,
    int? caretOffset,
  }) => _ProbeInput.deliverText(
    text,
    composing: composing,
    caretOffset: caretOffset,
  );

  Future<void> _recordEdit(
    String label,
    String expectedSource,
    int expectedEdits, {
    String? caretText,
    int? caretOffset,
    bool selectionCleared = true,
  }) async {
    final focused = _elements(
      (w) => w is TextField && w.focusNode?.hasFocus == true,
    );
    final field = focused.singleOrNull?.widget as TextField?;
    final checks = {
      'source': _liveSource == expectedSource,
      'editCount': _acceptedEdits == expectedEdits,
      'selection':
          selectionCleared ==
          _elements(
            (w) => w is BusyMarkWysiwygBlockField && w.selectionRange != null,
          ).isEmpty,
      'caret':
          caretText == null ||
          (field?.controller?.text == caretText &&
              field?.controller?.selection.extentOffset == caretOffset),
      'parsedStructure':
          caretText == null ||
          _liveDocument.blocks.every((b) => b.kind == BusyBlockKind.paragraph),
    };
    _reports.add({
      'case': label,
      'checks': checks,
      'acceptedSource': _liveSource,
      'blocks': [
        for (final b in _liveDocument.blocks)
          {'kind': b.kind.name, 'text': b.plainText, 'rows': b.children.length},
      ],
      'logicalSelection': _session.toJson(),
      'acceptedEdits': _acceptedEdits,
      'caretText': field?.controller?.text,
      'caretOffset': field?.controller?.selection.extentOffset,
    });
    await _capture(label);
    stdout.writeln('$label: $checks');
    if (checks.values.any((v) => !v)) {
      throw StateError('$label failed: $checks');
    }
  }

  Future<void> _undoSynthetic(String label, String source) async {
    final expectedEdits = _acceptedEdits + 1;
    await _key(PhysicalKeyboardKey.keyZ, LogicalKeyboardKey.keyZ);
    await _recordEdit('$label-undo', source, expectedEdits);
  }

  Future<void> _runEditableCases() async {
    await windowManager.setSize(const Size(1100, 950));
    await _setSynthetic(_syntheticTable);
    await _selectSyntheticTable();
    final table = _liveDocument.blocks.single;
    final range = (
      anchorId: table.id,
      anchorOffset: 0,
      extentId: table.id,
      extentOffset: 0,
    );
    await _record(
      '14-synthetic-table-select-all',
      expectedRange: range,
      needles: ['Header', 'Body text', 'End!'],
    );
    final parses = _syntheticParses;
    await _drag('Header', 0, 'End!', 4, cancel: true);
    if (_elements(
      (w) => w is BusyMarkWysiwygBlockField && w.documentSelectionDragging,
    ).isNotEmpty) {
      throw StateError('Cancelled table drag retained ownership');
    }
    if (_syntheticParses != parses) {
      throw StateError('Selection reparsed the synthetic source');
    }
    await _record(
      '15-synthetic-table-cancel',
      expectedRange: range,
      needles: ['Body text', 'End!'],
    );
    final cancelled = _session;
    setState(() {
      _initialSession = WysiwygEditorSessionState.fromJson(
        Map<String, Object?>.from(
          jsonDecode(jsonEncode(cancelled.toJson())) as Map,
        ),
      );
      _editorKey = UniqueKey();
    });
    await _pause();
    await _pause();
    await _record(
      '16-restored-table-selection',
      expectedRange: range,
      needles: ['Header', 'Body text', 'End!'],
    );

    for (final action in [
      'cut',
      'delete',
      'backspace',
      'enter',
      'plain-paste',
      'structured-paste',
    ]) {
      await _selectSyntheticTable();
      final edits = _acceptedEdits + 1;
      var expectedSource = '';
      var caret = '';
      switch (action) {
        case 'cut':
          await _key(PhysicalKeyboardKey.keyX, LogicalKeyboardKey.keyX);
        case 'delete':
          await _press(PhysicalKeyboardKey.delete, LogicalKeyboardKey.delete);
        case 'backspace':
          await _press(
            PhysicalKeyboardKey.backspace,
            LogicalKeyboardKey.backspace,
          );
        case 'enter':
          expectedSource = '\n';
          await _press(PhysicalKeyboardKey.enter, LogicalKeyboardKey.enter);
        case 'plain-paste':
          caret = 'Pasted 🧭';
          expectedSource = '$caret\n';
          if (!await _clipboard.write(RichClipboardData(text: caret))) {
            throw StateError('Linux clipboard write failed');
          }
          await _key(
            PhysicalKeyboardKey.keyV,
            LogicalKeyboardKey.keyV,
            shift: true,
          );
        case 'structured-paste':
          caret = 'Structured';
          expectedSource = '**Structured**\n';
          if (!await _clipboard.write(
            const RichClipboardData(
              text: 'Structured',
              html: '<p><strong>Structured</strong></p>',
            ),
          )) {
            throw StateError('Linux rich clipboard write failed');
          }
          await _key(PhysicalKeyboardKey.keyV, LogicalKeyboardKey.keyV);
      }
      if (action == 'cut') {
        final data = await _clipboard.read();
        if (data.sourceText?.contains('| Short | Body text |') != true) {
          throw StateError('Linux cut omitted table structure');
        }
      }
      await _recordEdit(
        '17-table-$action',
        expectedSource,
        edits,
        caretText: caret,
        caretOffset: caret.length,
      );
      await _undoSynthetic('17-table-$action', _syntheticTable);
    }

    await _selectSyntheticTable();
    final preeditEdits = _acceptedEdits;
    await _deliverText('n', composing: const TextRange(start: 0, end: 1));
    await _deliverText('ni', composing: const TextRange(start: 0, end: 2));
    await _recordEdit(
      '18-table-input-preedit',
      _syntheticTable,
      preeditEdits,
      selectionCleared: false,
    );
    await _press(PhysicalKeyboardKey.backspace, LogicalKeyboardKey.backspace);
    await _press(PhysicalKeyboardKey.delete, LogicalKeyboardKey.delete);
    await _press(PhysicalKeyboardKey.enter, LogicalKeyboardKey.enter);
    await _recordEdit(
      '18-table-composition-keys',
      _syntheticTable,
      preeditEdits,
      selectionCleared: false,
    );
    await _deliverText('');
    await _recordEdit(
      '19-table-input-cancel',
      _syntheticTable,
      preeditEdits,
      selectionCleared: false,
    );
    await _deliverText('你', composing: const TextRange(start: 0, end: 1));
    await _deliverText('你🧭');
    await _recordEdit(
      '20-table-input-commit',
      '你🧭\n',
      preeditEdits + 1,
      caretText: '你🧭',
      caretOffset: 3,
    );
    await _deliverText('你🧭 next');
    await _recordEdit(
      '21-table-input-continued',
      '你🧭 next\n',
      preeditEdits + 2,
      caretText: '你🧭 next',
      caretOffset: 8,
    );
    await _undoSynthetic('21-table-input-continued', '你🧭\n');
    await _undoSynthetic('20-table-input-commit', _syntheticTable);

    const surrounded = 'Before stays.\n\n$_syntheticTable\nAfter stays.\n';
    await _setSynthetic(surrounded);
    await _drag('Before stays.', 6, 'After stays.', 5, cancel: true);
    if (_elements(
      (w) => w is BusyMarkWysiwygBlockField && w.documentSelectionDragging,
    ).isNotEmpty) {
      throw StateError('Cancelled cross-block drag retained ownership');
    }
    await _record(
      '22-paragraph-table-paragraph-cancel',
      expectedRange: (
        anchorId: _liveDocument.blocks.first.id,
        anchorOffset: 6,
        extentId: _liveDocument.blocks.last.id,
        extentOffset: 5,
      ),
      needles: ['Body text'],
    );
    final cancelInputEdits = _acceptedEdits + 1;
    await _deliverText('After🧭 stays.', caretOffset: 7);
    await _recordEdit(
      '22-cancel-committed-input',
      'Before🧭 stays.\n',
      cancelInputEdits,
      caretText: 'Before🧭 stays.',
      caretOffset: 8,
    );
    await _undoSynthetic('22-cancel-committed-input', surrounded);
    await _drag('Before stays.', 6, 'After stays.', 5, cancel: true);
    final edits = _acceptedEdits + 1;
    if (!await _clipboard.write(const RichClipboardData(text: 'X'))) {
      throw StateError('Linux clipboard write failed');
    }
    await _key(PhysicalKeyboardKey.keyV, LogicalKeyboardKey.keyV, shift: true);
    await _recordEdit(
      '23-partial-table-range-paste',
      'BeforeX stays.\n',
      edits,
      caretText: 'BeforeX stays.',
      caretOffset: 7,
    );
    await _undoSynthetic('23-partial-table-range-paste', surrounded);
    await _runRestoredOrdinaryInput();
  }

  Future<void> _runRestoredOrdinaryInput() async {
    for (final fixture in [
      (
        name: 'paragraphs',
        source: 'Before stays.\n\nMiddle selected.\n\nAfter stays.\n',
        table: false,
      ),
      (
        name: 'mixed',
        source: 'Before stays.\n\n$_syntheticTable\nAfter stays.\n',
        table: false,
      ),
      (
        name: 'table-control',
        source: 'Before stays.\n\n$_syntheticTable',
        table: true,
      ),
    ]) {
      for (final reverse in [false, true]) {
        await _setSynthetic(fixture.source);
        final lastText = fixture.table ? 'End!' : 'After stays.';
        final lastOffset = fixture.table ? 4 : 5;
        await _drag(
          reverse ? lastText : 'Before stays.',
          reverse ? lastOffset : 6,
          reverse ? 'Before stays.' : lastText,
          reverse ? 6 : lastOffset,
        );
        final saved = WysiwygEditorSessionState.fromJson(
          Map<String, Object?>.from(
            jsonDecode(jsonEncode(_session.toJson())) as Map,
          ),
        );
        final edits = _acceptedEdits;
        await _setSynthetic('Other document stays unchanged.\n');
        await _setSynthetic(fixture.source, session: saved);
        // No focus/selection command intervenes between restoration and input.
        final tableInput = fixture.table && !reverse;
        final extentText = reverse ? 'Before stays.' : 'After stays.';
        final extentOffset = reverse ? 6 : 5;
        final focused = _elements(
          (w) => w is TextField && w.focusNode?.hasFocus == true,
        );
        final checks = {
          'source': _liveSource == fixture.source,
          'noRestorationEdits': _acceptedEdits == edits,
          'logicalRange':
              _session.anchorBlockId == saved.anchorBlockId &&
              _session.anchorOffset == saved.anchorOffset &&
              _session.extentBlockId == saved.extentBlockId &&
              _session.extentOffset == saved.extentOffset,
          'inputClient': _ProbeMessenger.clientId != null,
          'extentFocus':
              tableInput ||
              (focused.singleOrNull?.widget as TextField?)?.controller?.text ==
                  extentText,
        };
        final label = '24-restored-${fixture.name}-reverse-$reverse';
        _reports.add({
          'case': '$label-focus',
          'checks': checks,
          'logicalSelection': _session.toJson(),
          'client': _ProbeMessenger.clientId,
        });
        if (checks.values.any((v) => !v)) throw StateError('$label: $checks');
        await _deliverText(
          tableInput
              ? '你🧭'
              : extentText.replaceRange(extentOffset, extentOffset, '你🧭'),
          caretOffset: tableInput ? 3 : extentOffset + 3,
        );
        final suffix = fixture.table ? '' : ' stays.';
        final replaced = 'Before你🧭$suffix';
        final continued = 'Before你🧭 next$suffix';
        await _recordEdit(
          '$label-commit',
          '$replaced\n',
          edits + 1,
          caretText: replaced,
          caretOffset: 9,
        );
        await _deliverText(continued, caretOffset: 14);
        await _recordEdit(
          '$label-continued',
          '$continued\n',
          edits + 2,
          caretText: continued,
          caretOffset: 14,
        );
        await _undoSynthetic('$label-continued', '$replaced\n');
        await _undoSynthetic('$label-commit', fixture.source);
        await _key(
          PhysicalKeyboardKey.keyZ,
          LogicalKeyboardKey.keyZ,
          shift: true,
        );
        await _recordEdit('$label-commit-redo', '$replaced\n', edits + 5);
        await _key(
          PhysicalKeyboardKey.keyZ,
          LogicalKeyboardKey.keyZ,
          shift: true,
        );
        await _recordEdit('$label-continued-redo', '$continued\n', edits + 6);
      }
    }
  }
}

// Runs the actual main entry point and workspace buffer/session/history path.
// Only the documented disposable synthetic table fixture may be edited.
class _ApplicationProbeDriver {
  _ApplicationProbeDriver({
    required this.boundary,
    required this.fixture,
    required this.output,
  });
  final GlobalKey boundary;
  final File fixture;
  final Directory output;
  final clipboard = busyMarkRichClipboardService;
  final reports = <Map<String, Object?>>[];

  List<Element> elements(bool Function(Widget) predicate, [Element? root]) {
    final found = <Element>[];
    void visit(Element element) {
      if (predicate(element.widget)) found.add(element);
      element.visitChildren(visit);
    }

    visit(root ?? boundary.currentContext! as Element);
    return found;
  }

  Element get editorElement =>
      elements((w) => w is BusyMarkWysiwygEditor).single;
  BusyMarkWysiwygEditor get editor =>
      editorElement.widget as BusyMarkWysiwygEditor;
  ProviderContainer get container =>
      ProviderScope.containerOf(editorElement, listen: false);
  WorkspaceController get controller =>
      container.read(workspaceControllerProvider.notifier);
  String get source =>
      container.read(workspaceControllerProvider).activeBuffer!.text;
  WysiwygEditorSessionState get session => container
      .read(workspaceControllerProvider)
      .activeBuffer!
      .editorState
      .wysiwygState;
  List<BusyMarkWysiwygBlockField> get selected => elements(
    (w) => w is BusyMarkWysiwygBlockField && w.selectionRange != null,
  ).map((e) => e.widget as BusyMarkWysiwygBlockField).toList();

  Future<void> settle() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await _ProbeInput.pause();
  }

  Future<void> record(String label, Map<String, bool> checks) async {
    reports.add({
      'case': label,
      'checks': checks,
      'source': source,
      'session': session.toJson(),
      'undoEntries': container
          .read(workspaceControllerProvider)
          .activeBuffer!
          .editorState
          .undoState
          .undo
          .length,
    });
    final image =
        await (boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary)
            .toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    await File(
      '${output.path}/$label.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    stdout.writeln('$label: $checks');
    if (checks.values.any((v) => !v)) {
      throw StateError('$label failed: $checks');
    }
  }

  Future<void> command(
    PhysicalKeyboardKey physical,
    LogicalKeyboardKey logical, {
    bool shift = false,
  }) async {
    await _ProbeInput.command(physical, logical, shift: shift);
    await settle();
  }

  Future<void> selectTable() async {
    final field =
        elements(
              (w) => w is TextField && w.controller?.text == 'Header',
            ).single.widget
            as TextField;
    field.focusNode!.requestFocus();
    field.controller!.selection = const TextSelection.collapsed(offset: 0);
    await settle();
    await command(PhysicalKeyboardKey.keyA, LogicalKeyboardKey.keyA);
    await command(PhysicalKeyboardKey.keyA, LogicalKeyboardKey.keyA);
  }

  bool get tableSelected =>
      selected.length == 1 &&
      selected.single.block.kind == BusyBlockKind.table &&
      selected.single.selectionRange!.start == 0 &&
      selected.single.selectionRange!.end == 0;

  Future<void> checkTableCopy(String label) async {
    await command(PhysicalKeyboardKey.keyC, LogicalKeyboardKey.keyC);
    final data = await clipboard.read();
    await File('${output.path}/$label-clipboard-summary.json').writeAsString(
      jsonEncode({
        'textLength': data.text?.length,
        'sourceTextLength': data.sourceText?.length,
        'htmlLength': data.html?.length,
        'textContainsHeader': data.text?.contains('Header'),
        'textContainsEnd': data.text?.contains('End!'),
        'sourceContainsTable': data.sourceText?.contains(
          '| Short | Body text |',
        ),
      }),
    );
    await record(label, {
      'source': source == _ProbeState._syntheticTable,
      'selection': tableSelected,
      'clipboard':
          data.sourceText?.contains('| Short | Body text |') == true &&
          data.text?.contains('End!') == true,
    });
  }

  Future<void> run() async {
    Object? failure;
    try {
      if (await fixture.readAsString() != _ProbeState._syntheticTable) {
        throw ArgumentError(
          'Application probe requires the disposable synthetic table fixture',
        );
      }
      await settle();
      await selectTable();
      await checkTableCopy('01-normal-select-all');
      await command(PhysicalKeyboardKey.keyA, LogicalKeyboardKey.keyA);
      await checkTableCopy('02-normal-repeat-select-all');
      final revision = controller.editRevision;
      final frameBeforeIdle = WidgetsBinding.instance.hasScheduledFrame;
      await Future<void>.delayed(const Duration(milliseconds: 600));
      await record('03-normal-idle-selection', {
        'sourceUnchanged': source == _ProbeState._syntheticTable,
        'revisionUnchanged': controller.editRevision == revision,
        'noPerpetualFrame':
            !frameBeforeIdle && !WidgetsBinding.instance.hasScheduledFrame,
      });

      final tableBuffer = container
          .read(workspaceControllerProvider)
          .activeBuffer!
          .id;
      final saved = jsonEncode(session.toJson());
      if (!await controller.openActiveFile('${fixture.parent.path}/other.md')) {
        throw StateError('Could not open the other disposable tab');
      }
      await settle();
      await command(PhysicalKeyboardKey.tab, LogicalKeyboardKey.tab);
      await record('04-normal-tab-restoration', {
        'activeTab':
            container.read(workspaceControllerProvider).activeBuffer!.id ==
            tableBuffer,
        'tableSelection': tableSelected,
        'endpoints':
            session.anchorBlockId ==
                (jsonDecode(saved) as Map)['anchorBlockId'] &&
            session.extentBlockId ==
                (jsonDecode(saved) as Map)['extentBlockId'],
      });
      await checkTableCopy('05-normal-restored-copy');

      _ProbeInput.keyData(
        PhysicalKeyboardKey.delete,
        LogicalKeyboardKey.delete,
        ui.KeyEventType.down,
      );
      _ProbeInput.keyData(
        PhysicalKeyboardKey.delete,
        LogicalKeyboardKey.delete,
        ui.KeyEventType.up,
      );
      await settle();
      await record('06-normal-table-delete', {
        // Workspace buffers retain the file's existing final-newline policy.
        'source': source == '\n',
        'structure': editor.document.blocks.every(
          (b) => b.kind == BusyBlockKind.paragraph,
        ),
        'selectionCleared': selected.isEmpty,
        'history':
            container
                .read(workspaceControllerProvider)
                .activeBuffer!
                .editorState
                .undoState
                .undo
                .length ==
            1,
      });
      await command(PhysicalKeyboardKey.keyZ, LogicalKeyboardKey.keyZ);
      await checkTableCopy('07-normal-delete-undo');
      await command(
        PhysicalKeyboardKey.keyZ,
        LogicalKeyboardKey.keyZ,
        shift: true,
      );
      await record('08-normal-delete-redo', {'source': source == '\n'});
      await command(PhysicalKeyboardKey.keyZ, LogicalKeyboardKey.keyZ);
      await checkTableCopy('09-normal-redo-undo');

      await _ProbeInput.deliverText(
        'ni',
        composing: const TextRange(start: 0, end: 2),
      );
      await settle();
      await record('10-normal-preedit', {
        'source': source == _ProbeState._syntheticTable,
        'selection': tableSelected,
      });
      await _ProbeInput.deliverText('');
      await settle();
      await record('11-normal-composition-cancel', {
        'source': source == _ProbeState._syntheticTable,
        'selection': tableSelected,
      });
      await _ProbeInput.deliverText('你🧭');
      await settle();
      await record('12-normal-committed-input', {
        'source': source == '你🧭\n',
        'selectionCleared': selected.isEmpty,
        'history':
            container
                .read(workspaceControllerProvider)
                .activeBuffer!
                .editorState
                .undoState
                .undo
                .length ==
            1,
      });
      await _ProbeInput.deliverText('你🧭 next');
      await settle();
      await record('13-normal-continued-input', {
        'source': source == '你🧭 next\n',
        'caret':
            (elements(
                      (w) => w is TextField && w.focusNode?.hasFocus == true,
                    ).single.widget
                    as TextField)
                .controller!
                .selection
                .extentOffset ==
            8,
      });
      await command(PhysicalKeyboardKey.keyZ, LogicalKeyboardKey.keyZ);
      await record('14-normal-continued-undo', {'source': source == '你🧭\n'});
      await command(PhysicalKeyboardKey.keyZ, LogicalKeyboardKey.keyZ);
      await checkTableCopy('15-normal-input-undo');

      await command(PhysicalKeyboardKey.keyX, LogicalKeyboardKey.keyX);
      final cut = await clipboard.read();
      await record('16-normal-cut', {
        'source': source == '\n',
        'clipboard': cut.sourceText?.contains('| Last | End! |') == true,
      });
      await command(PhysicalKeyboardKey.keyZ, LogicalKeyboardKey.keyZ);
      await checkTableCopy('17-normal-cut-undo');
      await clipboard.write(const RichClipboardData(text: 'Pasted 🧭'));
      await command(
        PhysicalKeyboardKey.keyV,
        LogicalKeyboardKey.keyV,
        shift: true,
      );
      await record('18-normal-paste', {
        'source': source == 'Pasted 🧭\n',
        'selectionCleared': selected.isEmpty,
      });
      await command(PhysicalKeyboardKey.keyZ, LogicalKeyboardKey.keyZ);
      await checkTableCopy('19-normal-paste-undo');
      await record('20-normal-fixture-integrity', {
        'diskUnchanged':
            await fixture.readAsString() == _ProbeState._syntheticTable,
      });
      await runRestoredOrdinaryInput();
    } catch (error, stack) {
      failure = '$error\n$stack';
      stderr.writeln(failure);
    }
    await File('${output.path}/report.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'failure': failure?.toString(),
        'entryPoint': 'lib/main.dart',
        'inputMethod':
            'framework-dispatched keys and engine-channel editing updates; native Linux clipboard; actual workspace buffers, tab recreation, and external history',
        'cases': reports,
      }),
    );
    exit(failure == null ? 0 : 1);
  }

  Future<void> runRestoredOrdinaryInput() async {
    for (final name in ['paragraphs', 'mixed']) {
      final path = '${fixture.parent.path}/$name.md';
      final original = await File(path).readAsString();
      final expected = name == 'paragraphs'
          ? 'Before stays.\n\nMiddle selected.\n\nAfter stays.\n'
          : 'Before stays.\n\n${_ProbeState._syntheticTable}\nAfter stays.\n';
      if (original != expected) {
        throw ArgumentError('Unexpected synthetic fixture: $path');
      }
      if (!await controller.openActiveFile(path)) {
        throw StateError('Could not open $name fixture');
      }
      await settle();
      for (final reverse in [false, true]) {
        final fromText = reverse ? 'After stays.' : 'Before stays.';
        final toText = reverse ? 'Before stays.' : 'After stays.';
        Offset caret(String text, int offset) {
          final field = elements(
            (w) => w is TextField && w.controller?.text == text,
          ).single;
          final editable =
              (elements((w) => w is EditableText, field).single
                          as StatefulElement)
                      .state
                  as EditableTextState;
          return editable.renderEditable.localToGlobal(
            editable.renderEditable
                .getLocalRectForCaret(TextPosition(offset: offset))
                .center,
          );
        }

        final start = caret(fromText, reverse ? 5 : 6);
        final end = caret(toText, reverse ? 6 : 5);
        final viewId = View.of(editorElement).viewId;
        final pointer = 500 + (name == 'mixed' ? 2 : 0) + (reverse ? 1 : 0);
        GestureBinding.instance.handlePointerEvent(
          PointerDownEvent(
            viewId: viewId,
            pointer: pointer,
            position: start,
            buttons: kPrimaryMouseButton,
            kind: PointerDeviceKind.mouse,
          ),
        );
        GestureBinding.instance.handlePointerEvent(
          PointerMoveEvent(
            viewId: viewId,
            pointer: pointer,
            position: end,
            delta: end - start,
            buttons: kPrimaryMouseButton,
            kind: PointerDeviceKind.mouse,
          ),
        );
        GestureBinding.instance.handlePointerEvent(
          PointerUpEvent(
            viewId: viewId,
            pointer: pointer,
            position: end,
            kind: PointerDeviceKind.mouse,
          ),
        );
        await settle();
        final saved = session;
        final bufferId = container
            .read(workspaceControllerProvider)
            .activeBuffer!
            .id;
        final revision = controller.editRevision;
        final undoBefore = container
            .read(workspaceControllerProvider)
            .activeBuffer!
            .editorState
            .undoState
            .undo
            .length;
        if (!await controller.openActiveFile(
          '${fixture.parent.path}/other.md',
        )) {
          throw StateError('Could not open other tab');
        }
        await settle();
        final openCount = container
            .read(workspaceControllerProvider)
            .documentBuffers
            .length;
        for (var attempt = 0; attempt < openCount; attempt++) {
          await command(PhysicalKeyboardKey.tab, LogicalKeyboardKey.tab);
          if (container.read(workspaceControllerProvider).activeBuffer!.id ==
              bufferId) {
            break;
          }
        }
        final label = '21-normal-restored-$name-reverse-$reverse';
        final focused =
            elements(
                  (w) => w is TextField && w.focusNode?.hasFocus == true,
                ).singleOrNull?.widget
                as TextField?;
        await record('$label-focus', {
          'activeBuffer':
              container.read(workspaceControllerProvider).activeBuffer!.id ==
              bufferId,
          'logicalRange':
              session.anchorBlockId == saved.anchorBlockId &&
              session.anchorOffset == saved.anchorOffset &&
              session.extentBlockId == saved.extentBlockId &&
              session.extentOffset == saved.extentOffset,
          'sourceUnchanged': source == original,
          'revisionUnchanged': controller.editRevision == revision,
          'historyUnchanged':
              container
                  .read(workspaceControllerProvider)
                  .activeBuffer!
                  .editorState
                  .undoState
                  .undo
                  .length ==
              undoBefore,
          'extentFocus': focused?.controller?.text == toText,
          'inputClient': _ProbeMessenger.clientId != null,
          'selectedBlocks': selected.length == 3,
        });
        // Deliver immediately to the restored client; no focus command intervenes.
        final offset = reverse ? 6 : 5;
        await _ProbeInput.deliverText(
          toText.replaceRange(offset, offset, '你🧭'),
          caretOffset: offset + 3,
        );
        await settle();
        await record('$label-commit', {
          'source': source == 'Before你🧭 stays.\n',
          'structure':
              editor.document.blocks.length == 1 &&
              editor.document.blocks.single.kind == BusyBlockKind.paragraph,
          'selectionCleared': selected.isEmpty,
          'caret':
              (elements(
                        (w) => w is TextField && w.focusNode?.hasFocus == true,
                      ).single.widget
                      as TextField)
                  .controller!
                  .selection
                  .extentOffset ==
              9,
          'history':
              container
                  .read(workspaceControllerProvider)
                  .activeBuffer!
                  .editorState
                  .undoState
                  .undo
                  .length ==
              undoBefore + 1,
        });
        await _ProbeInput.deliverText('Before你🧭 next stays.', caretOffset: 14);
        await settle();
        await record('$label-continued', {
          'source': source == 'Before你🧭 next stays.\n',
          'caret':
              (elements(
                        (w) => w is TextField && w.focusNode?.hasFocus == true,
                      ).single.widget
                      as TextField)
                  .controller!
                  .selection
                  .extentOffset ==
              14,
        });
        await command(PhysicalKeyboardKey.keyZ, LogicalKeyboardKey.keyZ);
        await record('$label-continued-undo', {
          'source': source == 'Before你🧭 stays.\n',
        });
        await command(PhysicalKeyboardKey.keyZ, LogicalKeyboardKey.keyZ);
        await record('$label-commit-undo', {'source': source == original});
        await command(
          PhysicalKeyboardKey.keyZ,
          LogicalKeyboardKey.keyZ,
          shift: true,
        );
        await record('$label-commit-redo', {
          'source': source == 'Before你🧭 stays.\n',
        });
        await command(
          PhysicalKeyboardKey.keyZ,
          LogicalKeyboardKey.keyZ,
          shift: true,
        );
        await record('$label-continued-redo', {
          'source': source == 'Before你🧭 next stays.\n',
        });
        await command(PhysicalKeyboardKey.keyZ, LogicalKeyboardKey.keyZ);
        await command(PhysicalKeyboardKey.keyZ, LogicalKeyboardKey.keyZ);
        await record('$label-integrity', {
          'source': source == original,
          'diskUnchanged': await File(path).readAsString() == original,
        });
      }
    }
  }
}

class _ProbeInput {
  static Future<void> pause() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    await WidgetsBinding.instance.endOfFrame;
  }

  static void keyData(
    PhysicalKeyboardKey physical,
    LogicalKeyboardKey logical,
    ui.KeyEventType type,
  ) {
    // Synthesized framework messages also update HardwareKeyboard. These are
    // intentionally distinct from physical input or X11-generated events.
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

  static Future<void> command(
    PhysicalKeyboardKey physical,
    LogicalKeyboardKey logical, {
    bool shift = false,
  }) async {
    keyData(
      PhysicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.controlLeft,
      ui.KeyEventType.down,
    );
    if (shift) {
      keyData(
        PhysicalKeyboardKey.shiftLeft,
        LogicalKeyboardKey.shiftLeft,
        ui.KeyEventType.down,
      );
    }
    keyData(physical, logical, ui.KeyEventType.down);
    keyData(physical, logical, ui.KeyEventType.up);
    if (shift) {
      keyData(
        PhysicalKeyboardKey.shiftLeft,
        LogicalKeyboardKey.shiftLeft,
        ui.KeyEventType.up,
      );
    }
    keyData(
      PhysicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.controlLeft,
      ui.KeyEventType.up,
    );
    await pause();
  }

  static Future<void> deliverText(
    String text, {
    TextRange composing = TextRange.empty,
    int? caretOffset,
  }) async {
    final client = _ProbeMessenger.clientId;
    if (client == null) throw StateError('No active Linux text-input client');
    ServicesBinding.instance.channelBuffers.push(
      SystemChannels.textInput.name,
      SystemChannels.textInput.codec.encodeMethodCall(
        MethodCall('TextInputClient.updateEditingState', [
          client,
          TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(
              offset: caretOffset ?? text.length,
            ),
            composing: composing,
          ).toJSON(),
        ]),
      ),
      (_) {},
    );
    await pause();
  }
}

class _RectCanvas implements Canvas {
  final rects = <Rect>[];
  @override
  void drawRect(Rect rect, Paint paint) => rects.add(rect);
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
