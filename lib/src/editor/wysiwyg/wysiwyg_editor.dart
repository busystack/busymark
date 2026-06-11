import 'dart:async';

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

  @override
  void initState() {
    super.initState();
    _documentController = BusyMarkWysiwygDocumentController(
      document: widget.document,
    )..addListener(_syncBlockControllers);
    _syncBlockControllers();
  }

  @override
  void didUpdateWidget(covariant BusyMarkWysiwygEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.document.source != widget.document.source &&
        !_internalChange) {
      _documentController.replaceDocument(widget.document);
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
              ),
              Expanded(
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
                                onFocused: () => _activeBlockId = block.id,
                                onChanged: (value) {
                                  _activeBlockId = block.id;
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
      _focusNodes.putIfAbsent(block.id, FocusNode.new);
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
