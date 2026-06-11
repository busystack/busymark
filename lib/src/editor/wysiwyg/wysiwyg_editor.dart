import 'dart:async';

import 'package:file_selector/file_selector.dart';
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
  });

  final BusyDocument document;
  final ValueChanged<String> onSourceChanged;

  @override
  State<BusyMarkWysiwygEditor> createState() => _BusyMarkWysiwygEditorState();
}

class _BusyMarkWysiwygEditorState extends State<BusyMarkWysiwygEditor> {
  late final BusyMarkWysiwygDocumentController _documentController;
  final _textControllers = <String, BusyMarkWysiwygTextController>{};
  final _focusNodes = <String, FocusNode>{};
  String? _activeBlockId;
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final blocks = _editableBlocks(_documentController.document.blocks);
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.keyB, control: true):
            _InlineCommandIntent(BusyWysiwygInlineCommand.bold),
        SingleActivator(LogicalKeyboardKey.keyI, control: true):
            _InlineCommandIntent(BusyWysiwygInlineCommand.italic),
        SingleActivator(LogicalKeyboardKey.keyK, control: true):
            _LinkCommandIntent(),
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
                  onTap: _focusActiveOrFirstBlock,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(28, 20, 28, 38),
                    children: [
                      Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 820),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final block in blocks)
                                BusyMarkWysiwygBlockField(
                                  key: ValueKey(block.id),
                                  block: block,
                                  controller: _textControllers[block.id]!,
                                  focusNode: _focusNodes[block.id]!,
                                  onFocused: () => _setActiveBlock(block.id),
                                  onChanged: (value) {
                                    _setActiveBlock(block.id);
                                    _documentController.updateBlockText(
                                      block.id,
                                      value,
                                    );
                                    _emitMarkdown();
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
    for (final block in blocks) {
      final controller = _textControllers.putIfAbsent(
        block.id,
        () => BusyMarkWysiwygTextController(
          text: block.plainText,
          ranges: busyInlineStyleRanges(block.inlines),
        ),
      );
      controller.updateFromBlock(block);
      final focusNode = _focusNodes.putIfAbsent(
        block.id,
        () => FocusNode(
          debugLabel: 'BusyMark WYSIWYG ${block.id}',
          onKeyEvent: (node, event) => _handleBlockKeyEvent(block.id, event),
        ),
      );
      focusNode.onKeyEvent = (node, event) =>
          _handleBlockKeyEvent(block.id, event);
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
    if (_activeBlockId == null || !ids.contains(_activeBlockId)) {
      _activeBlockId = blocks.isEmpty ? null : blocks.first.id;
    }
    if (mounted) {
      setState(() {});
    }
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
    final controller = _textControllers[nextBlock.id];
    final focusNode = _focusNodes[nextBlock.id];
    if (controller == null || focusNode == null) {
      return KeyEventResult.ignored;
    }
    _activeBlockId = nextBlock.id;
    focusNode.requestFocus();
    final offset = desiredOffset is _MoveToBlockEnd
        ? controller.text.length
        : (desiredOffset as int).clamp(0, controller.text.length).toInt();
    controller.selection = TextSelection.collapsed(offset: offset);
    return KeyEventResult.handled;
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
    final blockId = _activeBlockId;
    if (blockId == null) {
      return;
    }
    _documentController.applyBlockCommand(blockId, command);
    _emitMarkdown();
  }

  void _applyInlineCommand(BusyWysiwygInlineCommand command) {
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
    widget.onSourceChanged(_documentController.markdown);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _internalChange = false;
    });
  }
}

class _InlineCommandIntent extends Intent {
  const _InlineCommandIntent(this.command);

  final BusyWysiwygInlineCommand command;
}

class _LinkCommandIntent extends Intent {
  const _LinkCommandIntent();
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
