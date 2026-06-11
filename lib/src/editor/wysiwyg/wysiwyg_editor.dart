import 'dart:async';
import 'dart:math' as math;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/busymark_design.dart';
import '../../markdown/busymark_document.dart';
import 'wysiwyg_block_widgets.dart';
import 'wysiwyg_commands.dart';
import 'wysiwyg_document_controller.dart';
import 'wysiwyg_inline_controller.dart';
import 'wysiwyg_toolbar.dart';

class BusyMarkWysiwygEditor extends StatefulWidget {
  const BusyMarkWysiwygEditor({
    super.key,
    required this.document,
    required this.onSourceChanged,
    this.onDocumentChanged,
    this.workspaceRoot,
    this.writersideRoot,
    this.imagesDir = 'images',
  });

  final BusyDocument document;
  final ValueChanged<String> onSourceChanged;
  final ValueChanged<BusyDocument>? onDocumentChanged;
  final String? workspaceRoot;
  final String? writersideRoot;
  final String imagesDir;

  @override
  State<BusyMarkWysiwygEditor> createState() => _BusyMarkWysiwygEditorState();
}

class _BusyMarkWysiwygEditorState extends State<BusyMarkWysiwygEditor> {
  late final BusyMarkWysiwygDocumentController _documentController;
  final _textControllers = <String, BusyMarkWysiwygTextController>{};
  final _focusNodes = <String, FocusNode>{};
  final _blockKeys = <String, GlobalKey>{};
  final _selectionFocusNode = FocusNode(
    debugLabel: 'BusyMark WYSIWYG block selection',
  );
  String? _activeBlockId;
  String? _selectionStartBlockId;
  String? _selectionEndBlockId;
  int? _selectionStartOffset;
  int? _selectionEndOffset;
  String? _pointerDownBlockId;
  bool _internalChange = false;
  bool _initialFocusScheduled = false;

  @override
  void initState() {
    super.initState();
    _documentController = BusyMarkWysiwygDocumentController(
      document: widget.document,
    )..addListener(_syncBlockControllers);
    _syncBlockControllers();
    _scheduleInitialFocus();
  }

  @override
  void didUpdateWidget(covariant BusyMarkWysiwygEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.document.source != widget.document.source &&
        !_internalChange) {
      _documentController.replaceDocument(widget.document);
      _initialFocusScheduled = false;
      _scheduleInitialFocus();
    }
  }

  @override
  void dispose() {
    _documentController.removeListener(_syncBlockControllers);
    _documentController.dispose();
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    _selectionFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final blocks = _editableBlocks(_documentController.document.blocks);
    final selectionRangesByBlockId = {
      for (final range in _selectedTextRanges(blocks))
        range.block.id: BusyMarkWysiwygSelectionRange(
          start: range.start,
          end: range.end,
        ),
    };
    final selectedBlockIds = _fullySelectedBlockIds(blocks);
    final blockSelectionActive = _hasBlockSelection;
    return Shortcuts(
      shortcuts: {
        const SingleActivator(LogicalKeyboardKey.keyB, control: true):
            _InlineCommandIntent(BusyWysiwygInlineCommand.bold),
        const SingleActivator(LogicalKeyboardKey.keyI, control: true):
            _InlineCommandIntent(BusyWysiwygInlineCommand.italic),
        const SingleActivator(LogicalKeyboardKey.keyK, control: true):
            const _LinkCommandIntent(),
        if (blockSelectionActive)
          const SingleActivator(LogicalKeyboardKey.keyC, control: true):
              const _CopyBlockSelectionIntent(),
        if (blockSelectionActive)
          const SingleActivator(LogicalKeyboardKey.escape):
              const _ClearBlockSelectionIntent(),
      },
      child: Actions(
        actions: {
          _InlineCommandIntent: CallbackAction<_InlineCommandIntent>(
            onInvoke: (intent) {
              _applyInlineCommand(intent.command);
              return null;
            },
          ),
          _LinkCommandIntent: CallbackAction<_LinkCommandIntent>(
            onInvoke: (intent) {
              unawaited(_applyLinkCommand());
              return null;
            },
          ),
          _CopyBlockSelectionIntent: CallbackAction<_CopyBlockSelectionIntent>(
            onInvoke: (intent) {
              _copyBlockSelection();
              return null;
            },
          ),
          _ClearBlockSelectionIntent:
              CallbackAction<_ClearBlockSelectionIntent>(
                onInvoke: (intent) {
                  _clearBlockSelection();
                  return null;
                },
              ),
        },
        child: DecoratedBox(
          decoration: BoxDecoration(color: colors.view),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BusyMarkWysiwygToolbar(
                onBlockCommand: _applyBlockCommand,
                onInlineCommand: _applyInlineCommand,
                onLinkCommand: () => unawaited(_applyLinkCommand()),
                onImageCommand: () => unawaited(_applyImageCommand()),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    _clearBlockSelection();
                    _focusActiveOrFirstBlock();
                  },
                  child: Focus(
                    focusNode: _selectionFocusNode,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(28, 20, 28, 38),
                      itemCount: blocks.length,
                      itemBuilder: (context, index) {
                        final block = blocks[index];
                        return Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 820),
                            child: BusyMarkWysiwygBlockField(
                              key: _blockKeyFor(block.id),
                              block: block,
                              documentFilePath:
                                  _documentController.document.filePath,
                              workspaceRoot: widget.workspaceRoot,
                              writersideRoot: widget.writersideRoot,
                              imagesDir: widget.imagesDir,
                              controller: _textControllerFor(block),
                              focusNode: _focusNodeFor(block),
                              selected: selectedBlockIds.contains(block.id),
                              selectionRange:
                                  selectionRangesByBlockId[block.id],
                              onPointerDown: (event) =>
                                  _handleBlockPointerDown(block.id, event),
                              onPointerMove: _handleBlockPointerMove,
                              onPointerUp: _handleBlockPointerUp,
                              onFocused: () => _handleBlockFocused(block.id),
                              onChanged: (value) =>
                                  _handleBlockTextChanged(block.id, value),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _syncBlockControllers() {
    final blocks = _editableBlocks(_documentController.document.blocks);
    final ids = {for (final block in blocks) block.id};
    final blockById = {for (final block in blocks) block.id: block};
    for (final entry in _textControllers.entries) {
      final block = blockById[entry.key];
      if (block != null) {
        entry.value.updateFromBlock(block);
      }
    }
    for (final id in _textControllers.keys.toList()) {
      if (!ids.contains(id)) {
        _textControllers.remove(id)?.dispose();
      }
    }
    for (final id in _focusNodes.keys.toList()) {
      if (!ids.contains(id)) {
        _focusNodes.remove(id)?.dispose();
      }
    }
    for (final id in _blockKeys.keys.toList()) {
      if (!ids.contains(id)) {
        _blockKeys.remove(id);
      }
    }
    if ((_selectionStartBlockId != null &&
            !ids.contains(_selectionStartBlockId)) ||
        (_selectionEndBlockId != null && !ids.contains(_selectionEndBlockId))) {
      _selectionStartBlockId = null;
      _selectionEndBlockId = null;
      _selectionStartOffset = null;
      _selectionEndOffset = null;
    }
    if (_activeBlockId == null || !ids.contains(_activeBlockId)) {
      _activeBlockId = blocks.isEmpty ? null : blocks.first.id;
    }
    if (mounted) {
      setState(() {});
    }
  }

  BusyMarkWysiwygTextController _textControllerFor(BusyBlock block) {
    final controller = _textControllers.putIfAbsent(
      block.id,
      () => BusyMarkWysiwygTextController(
        text: block.plainText,
        ranges: busyInlineStyleRanges(block.inlines),
      ),
    );
    controller.updateFromBlock(block);
    return controller;
  }

  FocusNode _focusNodeFor(BusyBlock block) {
    final focusNode = _focusNodes.putIfAbsent(
      block.id,
      () => FocusNode(
        debugLabel: 'BusyMark WYSIWYG ${block.id}',
        onKeyEvent: (node, event) => _handleBlockKeyEvent(block.id, event),
      ),
    );
    focusNode.onKeyEvent = (node, event) =>
        _handleBlockKeyEvent(block.id, event);
    return focusNode;
  }

  List<BusyBlock> _editableBlocks(List<BusyBlock> blocks) {
    return [
      for (final block in blocks)
        if (block.kind != BusyBlockKind.frontMatter) block,
    ];
  }

  void _setActiveBlock(String blockId) {
    _activeBlockId = blockId;
  }

  void _handleBlockFocused(String blockId) {
    _clearBlockSelection();
    _setActiveBlock(blockId);
  }

  void _handleBlockTextChanged(String blockId, String value) {
    _clearBlockSelection();
    _setActiveBlock(blockId);
    final controller = _textControllers[blockId];
    final offset =
        controller?.selection.extentOffset.clamp(0, value.length).toInt() ??
        value.length;
    final splitResult = _documentController.replaceBlockTextWithParagraphs(
      blockId,
      value,
      offset,
    );
    if (splitResult != null) {
      _emitMarkdown();
      _focusBlockAfterFrame(splitResult.blockId, offset: splitResult.offset);
      return;
    }
    _documentController.updateBlockText(blockId, value);
    _emitMarkdown();
  }

  void _scheduleInitialFocus() {
    if (_initialFocusScheduled) {
      return;
    }
    _initialFocusScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusActiveOrFirstBlock(initialSelectionOffset: 0);
      }
    });
  }

  void _focusActiveOrFirstBlock({int? initialSelectionOffset}) {
    final blocks = _focusableBlocks();
    if (blocks.isEmpty) {
      return;
    }
    final blockId =
        _activeBlockId != null && _focusNodes[_activeBlockId] != null
        ? _activeBlockId!
        : blocks.first.id;
    final focusNode = _focusNodes[blockId];
    final controller = _textControllers[blockId];
    if (focusNode == null || controller == null) {
      return;
    }
    _activeBlockId = blockId;
    if (!focusNode.hasFocus) {
      focusNode.requestFocus();
    }
    final selection = controller.selection;
    if (!selection.isValid || selection.baseOffset < 0) {
      controller.selection = TextSelection.collapsed(
        offset:
            initialSelectionOffset?.clamp(0, controller.text.length).toInt() ??
            controller.text.length,
      );
    }
  }

  KeyEventResult _handleBlockKeyEvent(String blockId, KeyEvent event) {
    if (event is! KeyDownEvent || _hasNavigationModifierPressed()) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final controller = _textControllers[blockId];
    if (controller == null ||
        !controller.selection.isValid ||
        !controller.selection.isCollapsed) {
      return KeyEventResult.ignored;
    }
    final offset = controller.selection.extentOffset
        .clamp(0, controller.text.length)
        .toInt();
    if (key == LogicalKeyboardKey.enter) {
      final result = _documentController.applyEnterAt(blockId, offset);
      if (result == null) {
        return KeyEventResult.ignored;
      }
      _emitMarkdown();
      _focusBlockAfterFrame(result.blockId, offset: result.offset);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.backspace && offset == 0) {
      final result = _documentController.applyBackspaceAtStart(blockId);
      if (result == null) {
        return KeyEventResult.ignored;
      }
      _emitMarkdown();
      _focusBlockAfterFrame(result.blockId, offset: result.offset);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp &&
        _isOffsetOnFirstTextLine(controller.text, offset)) {
      return _focusRelativeBlock(blockId, -1, desiredOffset: offset);
    }
    if (key == LogicalKeyboardKey.arrowDown &&
        _isOffsetOnLastTextLine(controller.text, offset)) {
      return _focusRelativeBlock(blockId, 1, desiredOffset: offset);
    }
    if (key == LogicalKeyboardKey.arrowLeft && offset == 0) {
      return _focusRelativeBlock(blockId, -1, desiredOffset: _MoveToBlockEnd());
    }
    if (key == LogicalKeyboardKey.arrowRight &&
        offset == controller.text.length) {
      return _focusRelativeBlock(blockId, 1, desiredOffset: 0);
    }
    return KeyEventResult.ignored;
  }

  bool _hasNavigationModifierPressed() {
    final keyboard = HardwareKeyboard.instance;
    return keyboard.isShiftPressed ||
        keyboard.isControlPressed ||
        keyboard.isAltPressed ||
        keyboard.isMetaPressed;
  }

  bool _isOffsetOnFirstTextLine(String text, int offset) {
    return !text.substring(0, offset.clamp(0, text.length)).contains('\n');
  }

  bool _isOffsetOnLastTextLine(String text, int offset) {
    return !text.substring(offset.clamp(0, text.length)).contains('\n');
  }

  KeyEventResult _focusRelativeBlock(
    String blockId,
    int direction, {
    required Object desiredOffset,
  }) {
    final blocks = _focusableBlocks();
    final index = blocks.indexWhere((block) => block.id == blockId);
    if (index == -1) {
      return KeyEventResult.ignored;
    }
    final nextIndex = index + direction;
    if (nextIndex < 0 || nextIndex >= blocks.length) {
      return KeyEventResult.ignored;
    }
    final nextBlock = blocks[nextIndex];
    final controller = _textControllerFor(nextBlock);
    final focusNode = _focusNodeFor(nextBlock);
    _activeBlockId = nextBlock.id;
    focusNode.requestFocus();
    final offset = desiredOffset is _MoveToBlockEnd
        ? controller.text.length
        : (desiredOffset as int).clamp(0, controller.text.length).toInt();
    controller.selection = TextSelection.collapsed(offset: offset);
    return KeyEventResult.handled;
  }

  void _focusBlockAfterFrame(String blockId, {required int offset}) {
    _activeBlockId = blockId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final block = _documentController.blockById(blockId);
      if (block == null) {
        return;
      }
      final focusNode = _focusNodeFor(block);
      final controller = _textControllerFor(block);
      focusNode.requestFocus();
      controller.selection = TextSelection.collapsed(
        offset: offset.clamp(0, controller.text.length).toInt(),
      );
    });
  }

  List<BusyBlock> _focusableBlocks() {
    return [
      for (final block in _editableBlocks(_documentController.document.blocks))
        if (_isFocusableTextBlock(block)) block,
    ];
  }

  bool _isFocusableTextBlock(BusyBlock block) {
    return !block.preserveRaw &&
        block.kind != BusyBlockKind.thematicBreak &&
        block.kind != BusyBlockKind.table;
  }

  void _applyBlockCommand(BusyWysiwygBlockCommand command) {
    final selectedBlocks = _selectedBlocks();
    if (selectedBlocks.isNotEmpty) {
      _documentController.applyBlockCommandToBlocks(
        selectedBlocks.map((block) => block.id),
        command,
      );
      _clearBlockSelection();
      _emitMarkdown();
      return;
    }
    final blockId = _activeBlockId;
    if (blockId == null) {
      return;
    }
    if (command == BusyWysiwygBlockCommand.thematicBreak) {
      final nextBlockId = _documentController.insertThematicBreakAfter(blockId);
      _emitMarkdown();
      if (nextBlockId != null) {
        _focusBlockAfterFrame(nextBlockId, offset: 0);
      }
      return;
    }
    _documentController.applyBlockCommand(blockId, command);
    _emitMarkdown();
  }

  void _applyInlineCommand(BusyWysiwygInlineCommand command) {
    final selectedRanges = _selectedTextRanges();
    if (selectedRanges.isNotEmpty) {
      for (final range in selectedRanges) {
        _documentController.applyInlineCommand(
          range.block.id,
          command,
          range.start,
          range.end,
        );
      }
      _clearBlockSelection();
      _emitMarkdown();
      return;
    }
    final blockId = _activeBlockId;
    if (blockId == null) {
      return;
    }
    final controller = _textControllers[blockId];
    final selection = controller?.selection;
    if (controller == null || selection == null || selection.isCollapsed) {
      return;
    }
    _documentController.applyInlineCommand(
      blockId,
      command,
      selection.start,
      selection.end,
    );
    _emitMarkdown();
  }

  Future<void> _applyLinkCommand() async {
    final selectedRanges = _selectedTextRanges();
    if (selectedRanges.isNotEmpty) {
      final destination = await _showLinkDialog(context);
      if (destination == null || destination.trim().isEmpty) {
        return;
      }
      for (final range in selectedRanges) {
        _documentController.applyInlineCommand(
          range.block.id,
          BusyWysiwygInlineCommand.link,
          range.start,
          range.end,
          destination: destination.trim(),
        );
      }
      _clearBlockSelection();
      _emitMarkdown();
      return;
    }
    final blockId = _activeBlockId;
    if (blockId == null) {
      return;
    }
    final controller = _textControllers[blockId];
    final selection = controller?.selection;
    if (controller == null || selection == null || selection.isCollapsed) {
      return;
    }
    final destination = await _showLinkDialog(context);
    if (destination == null || destination.trim().isEmpty) {
      return;
    }
    _documentController.applyInlineCommand(
      blockId,
      BusyWysiwygInlineCommand.link,
      selection.start,
      selection.end,
      destination: destination.trim(),
    );
    _emitMarkdown();
  }

  Future<void> _applyImageCommand() async {
    final blockId = _activeBlockId;
    if (blockId == null) {
      return;
    }
    final result = await _showImageDialog(context);
    if (result == null || result.source.trim().isEmpty) {
      return;
    }
    _documentController.applyImageBlock(
      blockId,
      source: result.source,
      alt: result.alt,
    );
    _emitMarkdown();
  }

  Future<String?> _showLinkDialog(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Link'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'https://example.com'),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Apply'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  Future<_ImageDialogResult?> _showImageDialog(BuildContext context) {
    return showDialog<_ImageDialogResult>(
      context: context,
      builder: (context) => const _ImageDialog(),
    );
  }

  void _emitMarkdown() {
    _internalChange = true;
    final markdown = _documentController.markdown;
    widget.onDocumentChanged?.call(
      _documentController.document.copyWith(source: markdown),
    );
    widget.onSourceChanged(markdown);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _internalChange = false;
    });
  }

  bool get _hasBlockSelection {
    return _selectionStartBlockId != null &&
        _selectionEndBlockId != null &&
        _selectionStartOffset != null &&
        _selectionEndOffset != null;
  }

  GlobalKey _blockKeyFor(String blockId) {
    return _blockKeys.putIfAbsent(blockId, GlobalKey.new);
  }

  Set<String> _selectedBlockIds(List<BusyBlock> blocks) {
    final startId = _selectionStartBlockId;
    final endId = _selectionEndBlockId;
    if (startId == null || endId == null) {
      return const {};
    }
    final startIndex = blocks.indexWhere((block) => block.id == startId);
    final endIndex = blocks.indexWhere((block) => block.id == endId);
    if (startIndex == -1 || endIndex == -1) {
      return const {};
    }
    final lower = math.min(startIndex, endIndex);
    final upper = math.max(startIndex, endIndex);
    return {for (var index = lower; index <= upper; index++) blocks[index].id};
  }

  Set<String> _fullySelectedBlockIds(List<BusyBlock> blocks) {
    return {
      for (final range in _selectedTextRanges(blocks))
        if (range.coversWholeBlock) range.block.id,
    };
  }

  List<_SelectedTextRange> _selectedTextRanges([List<BusyBlock>? inputBlocks]) {
    final startId = _selectionStartBlockId;
    final endId = _selectionEndBlockId;
    final rawStartOffset = _selectionStartOffset;
    final rawEndOffset = _selectionEndOffset;
    if (startId == null ||
        endId == null ||
        rawStartOffset == null ||
        rawEndOffset == null) {
      return const [];
    }
    final blocks =
        inputBlocks ?? _editableBlocks(_documentController.document.blocks);
    final startIndex = blocks.indexWhere((block) => block.id == startId);
    final endIndex = blocks.indexWhere((block) => block.id == endId);
    if (startIndex == -1 || endIndex == -1) {
      return const [];
    }
    final forward =
        startIndex < endIndex ||
        (startIndex == endIndex && rawStartOffset <= rawEndOffset);
    final lower = math.min(startIndex, endIndex);
    final upper = math.max(startIndex, endIndex);
    final ranges = <_SelectedTextRange>[];
    for (var index = lower; index <= upper; index++) {
      final block = blocks[index];
      final textLength = block.plainText.length;
      final range = _rangeForSelectedBlock(
        block: block,
        index: index,
        startIndex: startIndex,
        endIndex: endIndex,
        startOffset: rawStartOffset.clamp(0, textLength).toInt(),
        endOffset: rawEndOffset.clamp(0, textLength).toInt(),
        forward: forward,
      );
      if (range != null && range.end > range.start) {
        ranges.add(range);
      }
    }
    return ranges;
  }

  _SelectedTextRange? _rangeForSelectedBlock({
    required BusyBlock block,
    required int index,
    required int startIndex,
    required int endIndex,
    required int startOffset,
    required int endOffset,
    required bool forward,
  }) {
    final textLength = block.plainText.length;
    if (startIndex == endIndex) {
      return _SelectedTextRange(
        block: block,
        start: math.min(startOffset, endOffset),
        end: math.max(startOffset, endOffset),
      );
    }
    if (forward) {
      if (index == startIndex) {
        return _SelectedTextRange(
          block: block,
          start: startOffset.clamp(0, textLength).toInt(),
          end: textLength,
        );
      }
      if (index == endIndex) {
        return _SelectedTextRange(
          block: block,
          start: 0,
          end: endOffset.clamp(0, textLength).toInt(),
        );
      }
    } else {
      if (index == endIndex) {
        return _SelectedTextRange(
          block: block,
          start: endOffset.clamp(0, textLength).toInt(),
          end: textLength,
        );
      }
      if (index == startIndex) {
        return _SelectedTextRange(
          block: block,
          start: 0,
          end: startOffset.clamp(0, textLength).toInt(),
        );
      }
    }
    return _SelectedTextRange(block: block, start: 0, end: textLength);
  }

  List<BusyBlock> _selectedBlocks() {
    final blocks = _editableBlocks(_documentController.document.blocks);
    final selectedIds = _selectedBlockIds(blocks);
    if (selectedIds.isEmpty) {
      return const [];
    }
    return [
      for (final block in blocks)
        if (selectedIds.contains(block.id)) block,
    ];
  }

  void _handleBlockPointerDown(String blockId, PointerDownEvent event) {
    if (event.buttons != kPrimaryMouseButton) {
      return;
    }
    _pointerDownBlockId = blockId;
    _selectionStartOffset = _textOffsetAtGlobalPosition(
      blockId,
      event.position,
    );
    _selectionEndOffset = null;
  }

  void _handleBlockPointerMove(PointerMoveEvent event) {
    final startBlockId = _pointerDownBlockId;
    if (startBlockId == null || event.buttons != kPrimaryMouseButton) {
      return;
    }
    final targetBlockId = _blockIdAtGlobalPosition(event.position);
    if (targetBlockId == null || targetBlockId == startBlockId) {
      return;
    }
    final endOffset = _textOffsetAtGlobalPosition(
      targetBlockId,
      event.position,
    );
    if (_selectionStartBlockId == startBlockId &&
        _selectionEndBlockId == targetBlockId &&
        _selectionEndOffset == endOffset) {
      return;
    }
    setState(() {
      _selectionStartBlockId = startBlockId;
      _selectionEndBlockId = targetBlockId;
      _selectionEndOffset = endOffset;
    });
    _collapseFieldSelections();
    _selectionFocusNode.requestFocus();
  }

  void _handleBlockPointerUp(PointerUpEvent event) {
    _pointerDownBlockId = null;
  }

  String? _blockIdAtGlobalPosition(Offset position) {
    String? nearestBlockId;
    var nearestDistance = double.infinity;
    for (final entry in _blockKeys.entries) {
      final context = entry.value.currentContext;
      final renderObject = context?.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) {
        continue;
      }
      final topLeft = renderObject.localToGlobal(Offset.zero);
      final rect = topLeft & renderObject.size;
      if (position.dy >= rect.top && position.dy <= rect.bottom) {
        return entry.key;
      }
      final distance = position.dy < rect.top
          ? rect.top - position.dy
          : position.dy - rect.bottom;
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestBlockId = entry.key;
      }
    }
    return nearestDistance <= 80 ? nearestBlockId : null;
  }

  void _collapseFieldSelections() {
    for (final controller in _textControllers.values) {
      if (!controller.selection.isValid) {
        continue;
      }
      final offset = controller.selection.extentOffset
          .clamp(0, controller.text.length)
          .toInt();
      controller.selection = TextSelection.collapsed(offset: offset);
    }
  }

  void _clearBlockSelection() {
    if (!_hasBlockSelection) {
      _selectionStartBlockId = null;
      _selectionEndBlockId = null;
      _selectionStartOffset = null;
      _selectionEndOffset = null;
      return;
    }
    setState(() {
      _selectionStartBlockId = null;
      _selectionEndBlockId = null;
      _selectionStartOffset = null;
      _selectionEndOffset = null;
    });
    _collapseFieldSelections();
  }

  void _copyBlockSelection() {
    final selectedText = _selectedTextRanges()
        .map(_copyTextForRange)
        .where((text) => text.trim().isNotEmpty)
        .join('\n\n');
    if (selectedText.isEmpty) {
      return;
    }
    unawaited(Clipboard.setData(ClipboardData(text: selectedText)));
  }

  String _copyTextForBlock(BusyBlock block) {
    final text = block.plainText.trimRight();
    return switch (block.kind) {
      BusyBlockKind.unorderedListItem => '• $text',
      BusyBlockKind.orderedListItem =>
        '${block.attributes['marker'] ?? '1.'} $text',
      BusyBlockKind.taskListItem =>
        '${block.attributes['task'] == 'true' ? '[x]' : '[ ]'} $text',
      BusyBlockKind.thematicBreak => '---',
      BusyBlockKind.image =>
        text.isNotEmpty
            ? text
            : (block.attributes['src'] ?? block.rawSource ?? ''),
      _ => text.isNotEmpty ? text : (block.rawSource ?? ''),
    };
  }

  String _copyTextForRange(_SelectedTextRange range) {
    if (range.coversWholeBlock) {
      return _copyTextForBlock(range.block);
    }
    final text = range.block.plainText;
    if (text.isEmpty) {
      return '';
    }
    return text.substring(
      range.start.clamp(0, text.length).toInt(),
      range.end.clamp(0, text.length).toInt(),
    );
  }

  int _textOffsetAtGlobalPosition(String blockId, Offset globalPosition) {
    final block = _documentController.blockById(blockId);
    final controller = _textControllers[blockId];
    if (block == null || controller == null || controller.text.isEmpty) {
      return 0;
    }
    final keyContext = _blockKeys[blockId]?.currentContext;
    final renderObject = keyContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      final selection = controller.selection;
      if (selection.isValid) {
        return selection.extentOffset.clamp(0, controller.text.length).toInt();
      }
      return 0;
    }
    final local = renderObject.globalToLocal(globalPosition);
    final outerPadding = _outerPaddingForBlock(block);
    final contentPadding = _contentPaddingForBlock(block);
    final prefixWidth = _hasPrefix(block) ? 30.0 + BusyMarkSpacing.sm : 0.0;
    final textX = (local.dx - prefixWidth - contentPadding.left)
        .clamp(0.0, renderObject.size.width)
        .toDouble();
    final textY = (local.dy - outerPadding.top - contentPadding.top)
        .clamp(0.0, renderObject.size.height)
        .toDouble();
    final maxWidth =
        (renderObject.size.width -
                prefixWidth -
                contentPadding.horizontal -
                outerPadding.horizontal)
            .clamp(1.0, double.infinity)
            .toDouble();
    final textPainter = TextPainter(
      text: TextSpan(text: controller.text, style: _textStyleForBlock(block)),
      textDirection: Directionality.of(context),
    )..layout(maxWidth: maxWidth);
    return textPainter
        .getPositionForOffset(Offset(textX, textY))
        .offset
        .clamp(0, controller.text.length)
        .toInt();
  }

  TextStyle _textStyleForBlock(BusyBlock block) {
    final theme = Theme.of(context).textTheme;
    final level = int.tryParse(block.attributes['level'] ?? '') ?? 0;
    return switch (block.kind) {
      BusyBlockKind.heading when level == 1 => theme.headlineSmall!.copyWith(
        fontWeight: FontWeight.w700,
      ),
      BusyBlockKind.heading when level == 2 => theme.titleLarge!.copyWith(
        fontWeight: FontWeight.w700,
      ),
      BusyBlockKind.heading => theme.titleMedium!.copyWith(
        fontWeight: FontWeight.w700,
      ),
      BusyBlockKind.codeBlock => theme.bodyMedium!.copyWith(
        fontFamily: 'Ubuntu Mono',
        height: 1.45,
      ),
      _ => theme.bodyMedium!.copyWith(height: 1.5),
    };
  }

  EdgeInsets _outerPaddingForBlock(BusyBlock block) {
    return switch (block.kind) {
      BusyBlockKind.heading => const EdgeInsets.only(top: 16, bottom: 6),
      BusyBlockKind.codeBlock ||
      BusyBlockKind.blockquote ||
      BusyBlockKind.writersideAdmonition ||
      BusyBlockKind.writersideTabs ||
      BusyBlockKind.writersideProcedure ||
      BusyBlockKind.writersideRawXml ||
      BusyBlockKind.table ||
      BusyBlockKind.htmlBlock ||
      BusyBlockKind.unknown => const EdgeInsets.symmetric(vertical: 8),
      _ => const EdgeInsets.symmetric(vertical: 4),
    };
  }

  EdgeInsets _contentPaddingForBlock(BusyBlock block) {
    return switch (block.kind) {
      BusyBlockKind.codeBlock ||
      BusyBlockKind.blockquote ||
      BusyBlockKind.writersideAdmonition ||
      BusyBlockKind.writersideTabs ||
      BusyBlockKind.writersideProcedure ||
      BusyBlockKind.writersideRawXml ||
      BusyBlockKind.table ||
      BusyBlockKind.htmlBlock ||
      BusyBlockKind.unknown => const EdgeInsets.all(12),
      _ => EdgeInsets.zero,
    };
  }

  bool _hasPrefix(BusyBlock block) {
    return switch (block.kind) {
      BusyBlockKind.unorderedListItem ||
      BusyBlockKind.orderedListItem ||
      BusyBlockKind.taskListItem ||
      BusyBlockKind.image ||
      BusyBlockKind.blockquote ||
      BusyBlockKind.codeBlock ||
      BusyBlockKind.writersideAdmonition ||
      BusyBlockKind.writersideTabs ||
      BusyBlockKind.writersideProcedure ||
      BusyBlockKind.writersideRawXml ||
      BusyBlockKind.htmlBlock ||
      BusyBlockKind.unknown => true,
      _ => false,
    };
  }
}

class _SelectedTextRange {
  const _SelectedTextRange({
    required this.block,
    required this.start,
    required this.end,
  });

  final BusyBlock block;
  final int start;
  final int end;

  bool get coversWholeBlock => start <= 0 && end >= block.plainText.length;
}

class _InlineCommandIntent extends Intent {
  const _InlineCommandIntent(this.command);

  final BusyWysiwygInlineCommand command;
}

class _LinkCommandIntent extends Intent {
  const _LinkCommandIntent();
}

class _CopyBlockSelectionIntent extends Intent {
  const _CopyBlockSelectionIntent();
}

class _ClearBlockSelectionIntent extends Intent {
  const _ClearBlockSelectionIntent();
}

class _MoveToBlockEnd {
  const _MoveToBlockEnd();
}

class _ImageDialogResult {
  const _ImageDialogResult({required this.source, required this.alt});

  final String source;
  final String alt;
}

class _ImageDialog extends StatefulWidget {
  const _ImageDialog();

  @override
  State<_ImageDialog> createState() => _ImageDialogState();
}

class _ImageDialogState extends State<_ImageDialog> {
  final _sourceController = TextEditingController();
  final _altController = TextEditingController();

  @override
  void dispose() {
    _sourceController.dispose();
    _altController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Image'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _sourceController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Source',
                      hintText: 'images/example.png',
                    ),
                  ),
                ),
                const SizedBox(width: BusyMarkSpacing.sm),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: OutlinedButton(
                    onPressed: _chooseImage,
                    child: const Text('Choose'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: BusyMarkSpacing.md),
            TextField(
              controller: _altController,
              decoration: const InputDecoration(
                labelText: 'Alt text',
                hintText: 'Describe the image',
              ),
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Insert')),
      ],
    );
  }

  Future<void> _chooseImage() async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'Images',
          extensions: ['png', 'jpg', 'jpeg', 'gif', 'svg', 'webp'],
        ),
      ],
    );
    if (file == null) {
      return;
    }
    setState(() {
      _sourceController.text = file.path;
      if (_altController.text.trim().isEmpty) {
        _altController.text = file.name;
      }
    });
  }

  void _submit() {
    final source = _sourceController.text.trim();
    if (source.isEmpty) {
      return;
    }
    Navigator.pop(
      context,
      _ImageDialogResult(source: source, alt: _altController.text.trim()),
    );
  }
}
