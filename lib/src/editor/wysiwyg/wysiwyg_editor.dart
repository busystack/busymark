import 'dart:async';
import 'dart:math' as math;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_settings.dart';
import '../../app/busymark_dialogs.dart';
import '../../app/busymark_design.dart';
import '../../app/busymark_glyphs.dart';
import '../../app/busymark_shortcuts.dart';
import '../../app/localization.dart';
import '../../markdown/busymark_document.dart';
import '../../markdown/document_outline.dart';
import '../../platform/linux_header_bar_service.dart';
import '../document_callout.dart';
import '../document_code_block.dart';
import '../document_layout.dart';
import '../document_surface.dart';
import 'wysiwyg_block_widgets.dart';
import 'wysiwyg_commands.dart';
import 'wysiwyg_document_controller.dart';
import 'wysiwyg_inline_controller.dart';
import 'wysiwyg_toolbar.dart';

typedef BusyMarkWysiwygSourceChanged =
    void Function(String filePath, String source);

class BusyMarkWysiwygEditor extends StatefulWidget {
  const BusyMarkWysiwygEditor({
    super.key,
    required this.document,
    required this.onSourceChanged,
    this.onDocumentChanged,
    this.workspaceRoot,
    this.writersideRoot,
    this.imagesDir = 'images',
    this.allowRemoteImages = false,
    this.onRemoteImageBlocked,
    this.toolbarPlacement = EditorToolbarPlacement.topLeft,
    this.toolbarDirection = EditorToolbarDirection.horizontal,
    this.onToolbarPlacementChanged,
    this.onToolbarDirectionChanged,
    this.scrollToHeadingId,
    this.scrollToBlockId,
    this.scrollToSearchQuery,
    this.scrollRequest = 0,
    this.onOpenSearch,
    this.onCloseSearch,
    this.headerBarService,
    this.documentLayout,
  });

  final BusyDocument document;
  final BusyMarkWysiwygSourceChanged onSourceChanged;
  final ValueChanged<BusyDocument>? onDocumentChanged;
  final String? workspaceRoot;
  final String? writersideRoot;
  final String imagesDir;
  final bool allowRemoteImages;
  final VoidCallback? onRemoteImageBlocked;
  final EditorToolbarPlacement toolbarPlacement;
  final EditorToolbarDirection toolbarDirection;
  final ValueChanged<EditorToolbarPlacement>? onToolbarPlacementChanged;
  final ValueChanged<EditorToolbarDirection>? onToolbarDirectionChanged;
  final String? scrollToHeadingId;
  final String? scrollToBlockId;
  final String? scrollToSearchQuery;
  final int scrollRequest;
  final VoidCallback? onOpenSearch;
  final VoidCallback? onCloseSearch;
  final LinuxHeaderBarService? headerBarService;
  final BusyMarkDocumentLayoutSpec? documentLayout;

  @override
  State<BusyMarkWysiwygEditor> createState() => _BusyMarkWysiwygEditorState();
}

class _BusyMarkWysiwygEditorState extends State<BusyMarkWysiwygEditor> {
  static const _historyLimit = 100;

  late final BusyMarkWysiwygDocumentController _documentController;
  final _textControllers = <String, BusyMarkWysiwygTextController>{};
  final _textUndoControllers = <String, UndoHistoryController>{};
  final _focusNodes = <String, FocusNode>{};
  final _blockKeys = <String, GlobalKey>{};
  final _undoStack = <BusyDocument>[];
  final _redoStack = <BusyDocument>[];
  final _scrollController = ScrollController();
  final _selectionFocusNode = FocusNode(
    debugLabel: 'BusyMark WYSIWYG block selection',
  );
  String? _activeBlockId;
  String? _selectionStartBlockId;
  String? _selectionEndBlockId;
  int? _selectionStartOffset;
  int? _selectionEndOffset;
  String? _pointerDownBlockId;
  _WysiwygInternalClipboard? _internalClipboard;
  final _pendingInlineKindsByBlockId = <String, Set<BusyInlineKind>>{};
  int _preserveSelectionFocusCallbacks = 0;
  bool _internalChange = false;
  bool _initialFocusScheduled = false;
  var _toolbarVisible = true;
  var _documentGeneration = 0;

  @override
  void initState() {
    super.initState();
    _documentController = BusyMarkWysiwygDocumentController(
      document: widget.document,
    )..addListener(_handleDocumentControllerChanged);
    _syncBlockControllers();
    _scheduleInitialFocus();
    _scheduleHeadingScroll();
    _scheduleSearchScroll();
  }

  @override
  void didUpdateWidget(covariant BusyMarkWysiwygEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final fileChanged = oldWidget.document.filePath != widget.document.filePath;
    final sourceChanged = oldWidget.document.source != widget.document.source;
    if (fileChanged || (sourceChanged && !_internalChange)) {
      _undoStack.clear();
      _redoStack.clear();
      if (fileChanged) {
        _internalChange = false;
        _resetPerDocumentState();
      }
      _documentController.replaceDocument(widget.document);
      _initialFocusScheduled = false;
      _scheduleInitialFocus();
    }
    if (oldWidget.scrollRequest != widget.scrollRequest) {
      _scheduleHeadingScroll();
      _scheduleSearchScroll();
    }
  }

  @override
  void dispose() {
    _documentController.removeListener(_handleDocumentControllerChanged);
    _documentController.dispose();
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    for (final controller in _textUndoControllers.values) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    _scrollController.dispose();
    _selectionFocusNode.dispose();
    super.dispose();
  }

  void _resetPerDocumentState() {
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    for (final controller in _textUndoControllers.values) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    _textControllers.clear();
    _textUndoControllers.clear();
    _focusNodes.clear();
    _blockKeys.clear();
    _pendingInlineKindsByBlockId.clear();
    _activeBlockId = null;
    _selectionStartBlockId = null;
    _selectionEndBlockId = null;
    _selectionStartOffset = null;
    _selectionEndOffset = null;
    _pointerDownBlockId = null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final entries = _editableBlockEntries(_documentController.document.blocks);
    final renderEntries = _editorRenderEntries(
      _documentController.document.blocks,
    );
    final blocks = entries.map((entry) => entry.block).toList();
    final blockSelectionActive = _hasBlockSelection;
    final selectionRangesByBlockId = {
      for (final range in _selectedTextRanges(blocks))
        range.block.id: BusyMarkWysiwygSelectionRange(
          start: range.start,
          end: range.end,
        ),
    };
    if (blockSelectionActive) {
      for (final blockId in _selectedBlockIds(blocks)) {
        selectionRangesByBlockId.putIfAbsent(
          blockId,
          () => const BusyMarkWysiwygSelectionRange(start: 0, end: 0),
        );
      }
    }
    final selectedBlockIds = _fullySelectedBlockIds(blocks);
    return Shortcuts(
      shortcuts: {
        ...BusyMarkEditorShortcutActivators.intentMap(
          _EditorShortcutIntent.new,
        ),
        BusyMarkTextEditingShortcutActivators.paste: const _PasteTextIntent(),
        BusyMarkTextEditingShortcutActivators.selectAll:
            const _SelectAllTextIntent(),
        BusyMarkTextEditingShortcutActivators.undo: const _UndoEditorIntent(),
        BusyMarkTextEditingShortcutActivators.redo: const _RedoEditorIntent(),
        if (blockSelectionActive)
          BusyMarkTextEditingShortcutActivators.copy:
              const _CopyBlockSelectionIntent(),
        if (blockSelectionActive)
          BusyMarkTextEditingShortcutActivators.cut:
              const _CutBlockSelectionIntent(),
        if (blockSelectionActive)
          const SingleActivator(LogicalKeyboardKey.backspace):
              const _DeleteBlockSelectionIntent(),
        if (blockSelectionActive)
          const SingleActivator(LogicalKeyboardKey.delete):
              const _DeleteBlockSelectionIntent(),
        if (blockSelectionActive)
          BusyMarkTextEditingShortcutActivators.escape:
              const _ClearBlockSelectionIntent(),
      },
      child: Actions(
        actions: {
          _EditorShortcutIntent: CallbackAction<_EditorShortcutIntent>(
            onInvoke: (intent) {
              _applyEditorShortcutAction(intent.action);
              return null;
            },
          ),
          _PasteTextIntent: CallbackAction<_PasteTextIntent>(
            onInvoke: (intent) {
              unawaited(_pasteIntoActiveBlock());
              return null;
            },
          ),
          _SelectAllTextIntent: CallbackAction<_SelectAllTextIntent>(
            onInvoke: (intent) {
              _selectAllForActiveBlock();
              return null;
            },
          ),
          _DeleteBlockSelectionIntent:
              CallbackAction<_DeleteBlockSelectionIntent>(
                onInvoke: (intent) {
                  _deleteBlockSelection();
                  return null;
                },
              ),
          _CopyBlockSelectionIntent: CallbackAction<_CopyBlockSelectionIntent>(
            onInvoke: (intent) {
              _copyBlockSelection();
              return null;
            },
          ),
          _CutBlockSelectionIntent: CallbackAction<_CutBlockSelectionIntent>(
            onInvoke: (intent) {
              _cutBlockSelection();
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
          _UndoEditorIntent: CallbackAction<_UndoEditorIntent>(
            onInvoke: (intent) {
              _undoEditorChange();
              return null;
            },
          ),
          _RedoEditorIntent: CallbackAction<_RedoEditorIntent>(
            onInvoke: (intent) {
              _redoEditorChange();
              return null;
            },
          ),
        },
        child: DecoratedBox(
          decoration: BoxDecoration(color: colors.view),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final documentLayout = _documentLayout;
              return Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        _clearBlockSelection();
                        _focusActiveOrFirstBlock();
                      },
                      child: Focus(
                        focusNode: _selectionFocusNode,
                        child: ListView.builder(
                          key: const ValueKey('wysiwyg-document-scroll'),
                          controller: _scrollController,
                          padding: documentLayout.scrollPadding,
                          itemCount: renderEntries.length,
                          itemBuilder: (context, index) => _buildRenderEntry(
                            context,
                            renderEntries[index],
                            documentLayout: documentLayout,
                            first: index == 0,
                            selectedBlockIds: selectedBlockIds,
                            selectionRangesByBlockId: selectionRangesByBlockId,
                          ),
                        ),
                      ),
                    ),
                  ),
                  _FloatingWysiwygToolbar(
                    placement: widget.toolbarPlacement,
                    direction: widget.toolbarDirection,
                    visible: _toolbarVisible,
                    maxWidth: math.max(
                      0,
                      constraints.maxWidth - BusyMarkSpacing.lg,
                    ),
                    maxHeight: math.max(
                      0,
                      constraints.maxHeight - BusyMarkSpacing.lg,
                    ),
                    onToggle: () =>
                        setState(() => _toolbarVisible = !_toolbarVisible),
                    onPlacementChanged: widget.onToolbarPlacementChanged,
                    onDirectionChanged: widget.onToolbarDirectionChanged,
                    child: BusyMarkWysiwygToolbar(
                      axis: widget.toolbarDirection._axis,
                      alignEnd: _toolbarAlignedEnd(
                        widget.toolbarPlacement,
                        widget.toolbarDirection,
                      ),
                      onBlockCommand: _applyBlockCommand,
                      onInlineCommand: _applyInlineCommand,
                      onLinkCommand: () => unawaited(_applyLinkCommand()),
                      onImageCommand: () => unawaited(_applyImageCommand()),
                      onInlineImageCommand: () =>
                          unawaited(_applyInlineImageCommand()),
                      onTableCommand: () => unawaited(_applyTableCommand()),
                      onHtmlCommand: () => unawaited(_applyHtmlCommand()),
                      onIndentCommand: _applyIndentCommand,
                      onOutdentCommand: _applyOutdentCommand,
                      onToggleTaskCommand: _applyToggleTaskCommand,
                      onHardBreakCommand: _applyHardBreakCommand,
                      onCodeLanguageCommand: () =>
                          unawaited(_applyCodeLanguageCommand()),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  BusyMarkDocumentLayoutSpec get _documentLayout =>
      widget.documentLayout ??
      BusyMarkDocumentLayoutSpec.standalone.withEditingToolbar(
        placement: widget.toolbarPlacement,
        direction: widget.toolbarDirection,
      );

  Widget _buildRenderEntry(
    BuildContext context,
    _EditorRenderEntry entry, {
    required BusyMarkDocumentLayoutSpec documentLayout,
    bool applyDocumentFrame = true,
    bool first = false,
    required Set<String> selectedBlockIds,
    required Map<String, BusyMarkWysiwygSelectionRange>
    selectionRangesByBlockId,
  }) {
    final block = entry.block;
    final blockTextDirection = busyMarkWysiwygBlockTextDirection(
      block,
      fallback: Directionality.of(context),
    );
    final content = entry.children == null
        ? _buildEditableBlockField(
            block,
            first: first,
            selectedBlockIds: selectedBlockIds,
            selectionRangesByBlockId: selectionRangesByBlockId,
          )
        : _buildBlockquoteEntry(
            context,
            entry,
            documentLayout: documentLayout,
            blockTextDirection: blockTextDirection,
            selectedBlockIds: selectedBlockIds,
            selectionRangesByBlockId: selectionRangesByBlockId,
          );
    final indentedContent = Padding(
      padding: EdgeInsetsDirectional.only(
        start: entry.depth * BusyMarkSizes.wysiwygBlockIndent,
      ).resolve(blockTextDirection),
      child: content,
    );
    if (!applyDocumentFrame) {
      return indentedContent;
    }
    return BusyMarkDocumentContentFrame(
      layout: documentLayout,
      contentKey: first ? const ValueKey('wysiwyg-document-content') : null,
      child: indentedContent,
    );
  }

  Widget _buildBlockquoteEntry(
    BuildContext context,
    _EditorRenderEntry entry, {
    required BusyMarkDocumentLayoutSpec documentLayout,
    required TextDirection blockTextDirection,
    required Set<String> selectedBlockIds,
    required Map<String, BusyMarkWysiwygSelectionRange>
    selectionRangesByBlockId,
  }) {
    final children = entry.children!;
    final firstEditableBlock = _firstEditableBlockIn(children);
    return Directionality(
      textDirection: blockTextDirection,
      child: BusyMarkDocumentCallout(
        key: ValueKey('wysiwyg-blockquote-${entry.block.id}'),
        icon: BusyMarkGlyphs.blockquote,
        onTap: firstEditableBlock == null
            ? null
            : () {
                _handleBlockFocused(firstEditableBlock.id);
                _focusNodeFor(firstEditableBlock).requestFocus();
              },
        child: Builder(
          builder: (quoteContext) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (index, child) in children.indexed)
                _buildRenderEntry(
                  quoteContext,
                  child,
                  documentLayout: documentLayout,
                  applyDocumentFrame: false,
                  first: index == 0,
                  selectedBlockIds: selectedBlockIds,
                  selectionRangesByBlockId: selectionRangesByBlockId,
                ),
            ],
          ),
        ),
      ),
    );
  }

  BusyBlock? _firstEditableBlockIn(List<_EditorRenderEntry> entries) {
    for (final entry in entries) {
      final children = entry.children;
      if (children == null) {
        return entry.block;
      }
      final descendant = _firstEditableBlockIn(children);
      if (descendant != null) {
        return descendant;
      }
    }
    return null;
  }

  Widget _buildEditableBlockField(
    BusyBlock block, {
    required bool first,
    required Set<String> selectedBlockIds,
    required Map<String, BusyMarkWysiwygSelectionRange>
    selectionRangesByBlockId,
  }) {
    final documentFilePath = _documentController.document.filePath;
    return BusyMarkWysiwygBlockField(
      key: _blockKeyFor(block.id),
      block: block,
      first: first,
      documentFilePath: documentFilePath,
      workspaceRoot: widget.workspaceRoot,
      writersideRoot: widget.writersideRoot,
      imagesDir: widget.imagesDir,
      allowRemoteImages: widget.allowRemoteImages,
      onRemoteImageBlocked: widget.onRemoteImageBlocked,
      controller: _textControllerFor(block),
      undoController: _textUndoControllerFor(block),
      focusNode: _focusNodeFor(block),
      selected: selectedBlockIds.contains(block.id),
      selectionRange: selectionRangesByBlockId[block.id],
      onPointerDown: (event) => _handleBlockPointerDown(block.id, event),
      onPointerMove: _handleBlockPointerMove,
      onPointerUp: _handleBlockPointerUp,
      onFocused: () => _handleBlockFocused(block.id),
      onChanged: (value) =>
          _handleBlockTextChanged(documentFilePath, block.id, value),
      onTableCellChanged: (cellId, value) => _handleTableCellTextChanged(
        documentFilePath,
        block.id,
        cellId,
        value,
      ),
      onTableRowInserted: (rowIndex, {required after}) =>
          _handleTableRowInserted(block.id, rowIndex, after: after),
      onTableRowDeleted: (rowIndex) =>
          _handleTableRowDeleted(block.id, rowIndex),
      onTableColumnInserted: (columnIndex, {required after}) =>
          _handleTableColumnInserted(block.id, columnIndex, after: after),
      onTableColumnDeleted: (columnIndex) =>
          _handleTableColumnDeleted(block.id, columnIndex),
      onTableDeleted: () => _handleTableDeleted(block.id),
      onImageEditRequested: () =>
          unawaited(_handleImageBlockEditRequested(block.id)),
      onHtmlEditRequested: () =>
          unawaited(_handleHtmlBlockEditRequested(block.id)),
    );
  }

  bool _toolbarAlignedEnd(
    EditorToolbarPlacement placement,
    EditorToolbarDirection direction,
  ) {
    return direction == EditorToolbarDirection.horizontal
        ? placement._isRight
        : !placement._isTop;
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
    for (final id in _pendingInlineKindsByBlockId.keys.toList()) {
      if (!ids.contains(id)) {
        _pendingInlineKindsByBlockId.remove(id);
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

  void _handleDocumentControllerChanged() {
    _documentGeneration++;
    _syncBlockControllers();
  }

  _WysiwygDialogTarget _captureDialogTarget() {
    return _WysiwygDialogTarget(
      filePath: _documentController.document.filePath,
      generation: _documentGeneration,
    );
  }

  bool _isDialogTargetCurrent(_WysiwygDialogTarget target) {
    return mounted &&
        target.filePath == _documentController.document.filePath &&
        target.generation == _documentGeneration;
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

  UndoHistoryController _textUndoControllerFor(BusyBlock block) {
    return _textUndoControllers.putIfAbsent(
      block.id,
      UndoHistoryController.new,
    );
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
    return [for (final entry in _editableBlockEntries(blocks)) entry.block];
  }

  List<_EditableBlockEntry> _editableBlockEntries(
    List<BusyBlock> blocks, [
    int depth = 0,
  ]) {
    final entries = <_EditableBlockEntry>[];
    for (final block in blocks) {
      if (block.kind == BusyBlockKind.frontMatter || block.isSourceOnly) {
        continue;
      }
      if (_isStructuralBlockquote(block)) {
        entries.addAll(_editableBlockEntries(block.children, depth));
        continue;
      }
      entries.add(_EditableBlockEntry(block: block, depth: depth));
      if (_showsNestedEditorBlocks(block)) {
        entries.addAll(_editableBlockEntries(block.children, depth + 1));
      }
    }
    return entries;
  }

  List<_EditorRenderEntry> _editorRenderEntries(
    List<BusyBlock> blocks, [
    int depth = 0,
  ]) {
    final entries = <_EditorRenderEntry>[];
    for (final block in blocks) {
      if (block.kind == BusyBlockKind.frontMatter || block.isSourceOnly) {
        continue;
      }
      if (_isStructuralBlockquote(block)) {
        entries.add(
          _EditorRenderEntry.blockquote(
            block: block,
            depth: depth,
            children: _editorRenderEntries(block.children),
          ),
        );
        continue;
      }
      entries.add(_EditorRenderEntry.block(block: block, depth: depth));
      if (_showsNestedEditorBlocks(block)) {
        entries.addAll(_editorRenderEntries(block.children, depth + 1));
      }
    }
    return entries;
  }

  bool _isStructuralBlockquote(BusyBlock block) =>
      block.kind == BusyBlockKind.blockquote &&
      block.children.isNotEmpty &&
      !block.isSourceProtected;

  bool _showsNestedEditorBlocks(BusyBlock block) {
    if (block.isSourceProtected) {
      return false;
    }
    return switch (block.kind) {
      BusyBlockKind.unorderedListItem ||
      BusyBlockKind.orderedListItem ||
      BusyBlockKind.taskListItem ||
      BusyBlockKind.blockquote => true,
      _ => false,
    };
  }

  void _setActiveBlock(String blockId) {
    _activeBlockId = blockId;
  }

  BusyDocument _historySnapshot() {
    final markdown = _documentController.markdown;
    return _documentController.document.copyWith(
      blocks: [
        for (final block in _documentController.document.blocks)
          _historyBlockSnapshot(block),
      ],
      source: markdown,
    );
  }

  BusyBlock _historyBlockSnapshot(BusyBlock block) {
    return BusyBlock(
      id: block.id,
      kind: block.kind,
      inlines: block.inlines,
      children: [
        for (final child in block.children) _historyBlockSnapshot(child),
      ],
      attributes: block.attributes,
      rawSource: block.rawSource,
      preserveRaw: block.preserveRaw,
      isSourceOnly: block.isSourceOnly,
      isGenerated: block.isGenerated,
      isSourceProtected: block.isSourceProtected,
      dirty: block.dirty,
    );
  }

  void _recordUndoSnapshot() {
    final snapshot = _historySnapshot();
    if (_undoStack.isNotEmpty && _undoStack.last.source == snapshot.source) {
      return;
    }
    _undoStack.add(snapshot);
    if (_undoStack.length > _historyLimit) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  bool _undoEditorChange() {
    final filePath = _documentController.document.filePath;
    final current = _historySnapshot();
    while (_undoStack.isNotEmpty) {
      final previous = _undoStack.removeLast();
      if (previous.filePath != filePath) {
        continue;
      }
      if (current.source != previous.source) {
        _redoStack.add(current);
      }
      _restoreEditorSnapshot(previous);
      return true;
    }
    return false;
  }

  bool _redoEditorChange() {
    final filePath = _documentController.document.filePath;
    final current = _historySnapshot();
    while (_redoStack.isNotEmpty) {
      final next = _redoStack.removeLast();
      if (next.filePath != filePath) {
        continue;
      }
      if (current.source != next.source) {
        _undoStack.add(current);
      }
      _restoreEditorSnapshot(next);
      return true;
    }
    return false;
  }

  void _restoreEditorSnapshot(BusyDocument snapshot) {
    _clearBlockSelection();
    _documentController.replaceDocument(snapshot);
    _emitMarkdown();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusActiveOrFirstBlock();
      }
    });
  }

  void _handleBlockFocused(String blockId) {
    if (_preserveSelectionFocusCallbacks > 0 && _hasBlockSelection) {
      _preserveSelectionFocusCallbacks--;
      _setActiveBlock(blockId);
      return;
    }
    _clearBlockSelection();
    _collapseInactiveFieldSelections(blockId);
    _setActiveBlock(blockId);
  }

  void _handleBlockTextChanged(
    String documentFilePath,
    String blockId,
    String value,
  ) {
    if (documentFilePath != _documentController.document.filePath) {
      return;
    }
    _clearBlockSelection();
    _setActiveBlock(blockId);
    if (_documentController.blockText(blockId) == value) {
      return;
    }
    _recordUndoSnapshot();
    final controller = _textControllers[blockId];
    final offset =
        controller?.selection.extentOffset.clamp(0, value.length).toInt() ??
        value.length;
    final pendingInlineKinds =
        _pendingInlineKindsByBlockId[blockId]?.toList(growable: false) ??
        const <BusyInlineKind>[];
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
    _documentController.updateBlockText(
      blockId,
      value,
      activeInlineKinds: pendingInlineKinds,
    );
    if (value.isNotEmpty) {
      _pendingInlineKindsByBlockId.remove(blockId);
    }
    _emitMarkdown();
  }

  void _handleTableCellTextChanged(
    String documentFilePath,
    String tableBlockId,
    String cellId,
    String value,
  ) {
    if (documentFilePath != _documentController.document.filePath) {
      return;
    }
    _clearBlockSelection();
    _setActiveBlock(tableBlockId);
    _recordUndoSnapshot();
    _documentController.updateTableCellText(tableBlockId, cellId, value);
    _emitMarkdown();
  }

  void _handleTableRowInserted(
    String tableBlockId,
    int rowIndex, {
    required bool after,
  }) {
    _clearBlockSelection();
    _setActiveBlock(tableBlockId);
    _recordUndoSnapshot();
    _documentController.insertTableRow(tableBlockId, rowIndex, after: after);
    _emitMarkdown();
  }

  void _handleTableRowDeleted(String tableBlockId, int rowIndex) {
    _clearBlockSelection();
    _setActiveBlock(tableBlockId);
    _recordUndoSnapshot();
    _documentController.deleteTableRow(tableBlockId, rowIndex);
    _emitMarkdown();
  }

  void _handleTableColumnInserted(
    String tableBlockId,
    int columnIndex, {
    required bool after,
  }) {
    _clearBlockSelection();
    _setActiveBlock(tableBlockId);
    _recordUndoSnapshot();
    _documentController.insertTableColumn(
      tableBlockId,
      columnIndex,
      after: after,
    );
    _emitMarkdown();
  }

  void _handleTableColumnDeleted(String tableBlockId, int columnIndex) {
    _clearBlockSelection();
    _setActiveBlock(tableBlockId);
    _recordUndoSnapshot();
    _documentController.deleteTableColumn(tableBlockId, columnIndex);
    _emitMarkdown();
  }

  void _handleTableDeleted(String tableBlockId) {
    _clearBlockSelection();
    _recordUndoSnapshot();
    _documentController.deleteTable(tableBlockId);
    _emitMarkdown();
  }

  Future<void> _handleImageBlockEditRequested(String blockId) async {
    _clearBlockSelection();
    _setActiveBlock(blockId);
    final block = _documentController.blockById(blockId);
    if (block == null || block.kind != BusyBlockKind.image) {
      return;
    }
    final target = _captureDialogTarget();
    final result = await _showImageDialog(
      context,
      title: context.l10n.image,
      initialSource: _imageSourceForBlock(block),
      initialAlt: block.plainText,
      submitLabel: context.l10n.apply,
    );
    if (!_isDialogTargetCurrent(target) ||
        result == null ||
        result.source.trim().isEmpty) {
      return;
    }
    _recordUndoSnapshot();
    _documentController.applyImageBlock(
      blockId,
      source: result.source,
      alt: result.alt,
    );
    _emitMarkdown();
  }

  Future<void> _handleHtmlBlockEditRequested(String blockId) async {
    _clearBlockSelection();
    _setActiveBlock(blockId);
    final block = _documentController.blockById(blockId);
    if (block == null || block.kind != BusyBlockKind.htmlBlock) {
      return;
    }
    final target = _captureDialogTarget();
    final source = await _showHtmlDialog(
      context,
      initialSource: block.rawSource ?? '',
      submitLabel: context.l10n.apply,
    );
    if (!_isDialogTargetCurrent(target) || source == null) {
      return;
    }
    _recordUndoSnapshot();
    _documentController.updateRawHtmlBlock(blockId, source);
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

  void _scheduleHeadingScroll() {
    final headingId = widget.scrollToHeadingId;
    final editorBlockId = widget.scrollToBlockId;
    if (widget.scrollRequest == 0 ||
        ((headingId == null || headingId.isEmpty) &&
            (editorBlockId == null || editorBlockId.isEmpty))) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      var heading = editorBlockId == null
          ? null
          : _documentController.blockById(editorBlockId);
      if (heading?.kind != BusyBlockKind.heading) {
        heading = headingId == null ? null : _headingBlockForId(headingId);
      }
      if (heading == null) {
        return;
      }
      final headingBlockId = heading.id;
      if (_ensureBlockVisible(headingBlockId)) {
        return;
      }
      _jumpNearBlock(headingBlockId);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _ensureBlockVisible(headingBlockId);
        }
      });
    });
  }

  void _scheduleSearchScroll() {
    final query = widget.scrollToSearchQuery?.trim();
    if (query == null || query.isEmpty || widget.scrollRequest == 0) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final target = _blockForSearchQuery(query);
      if (target == null) {
        return;
      }
      final controller = _textControllerFor(target);
      final matchStart = controller.text.toLowerCase().indexOf(
        query.toLowerCase(),
      );
      if (matchStart >= 0) {
        _activeBlockId = target.id;
        _focusNodeFor(target).requestFocus();
        controller.selection = TextSelection(
          baseOffset: matchStart,
          extentOffset: matchStart + query.length,
        );
      }
      if (_ensureBlockVisible(target.id)) {
        return;
      }
      _jumpNearBlock(target.id);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _ensureBlockVisible(target.id);
        }
      });
    });
  }

  BusyBlock? _blockForSearchQuery(String query) {
    final normalizedQuery = query.toLowerCase();
    for (final entry in _editableBlockEntries(
      _documentController.document.blocks,
    )) {
      if (entry.block.plainText.toLowerCase().contains(normalizedQuery)) {
        return entry.block;
      }
    }
    return null;
  }

  bool _ensureBlockVisible(String blockId) {
    final targetContext = _blockKeys[blockId]?.currentContext;
    if (targetContext == null) {
      return false;
    }
    Scrollable.ensureVisible(
      targetContext,
      duration: BusyMarkMotion.scroll,
      curve: Curves.easeOutCubic,
      alignment: 0.04,
    );
    return true;
  }

  void _jumpNearBlock(String blockId) {
    if (!_scrollController.hasClients) {
      return;
    }
    final entries = _editableBlockEntries(_documentController.document.blocks);
    final index = entries.indexWhere((entry) => entry.block.id == blockId);
    if (index < 0) {
      return;
    }
    final targetOffset = (index * 72.0)
        .clamp(0.0, _scrollController.position.maxScrollExtent)
        .toDouble();
    _scrollController.jumpTo(targetOffset);
  }

  BusyBlock? _headingBlockForId(String headingId) {
    for (final heading in _documentController.document.outline) {
      if (heading.id != headingId) {
        continue;
      }
      final blockId = heading.editorBlockId;
      if (blockId != null) {
        return _documentController.blockById(blockId);
      }
    }
    return null;
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
    final keyboard = HardwareKeyboard.instance;
    final key = event.logicalKey;
    if ((event is KeyDownEvent || event is KeyRepeatEvent) &&
        BusyMarkTextEditingShortcutActivators.insertIndentation.accepts(
          event,
          keyboard,
        )) {
      _activeBlockId = blockId;
      return _insertTabIntoBlock(blockId)
          ? KeyEventResult.handled
          : KeyEventResult.ignored;
    }
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    _activeBlockId = blockId;
    if (keyboard.isControlPressed && key == LogicalKeyboardKey.keyA) {
      _selectAllForBlock(blockId);
      return KeyEventResult.handled;
    }
    if (keyboard.isControlPressed &&
        key == LogicalKeyboardKey.keyC &&
        _copyCurrentSelection()) {
      return KeyEventResult.handled;
    }
    if (keyboard.isControlPressed &&
        key == LogicalKeyboardKey.keyX &&
        _cutCurrentSelection()) {
      return KeyEventResult.handled;
    }
    if (keyboard.isControlPressed &&
        !keyboard.isShiftPressed &&
        key == LogicalKeyboardKey.keyV) {
      unawaited(_pasteIntoActiveBlock());
      return KeyEventResult.handled;
    }
    if (keyboard.isControlPressed &&
        keyboard.isShiftPressed &&
        key == LogicalKeyboardKey.keyZ) {
      _redoEditorChange();
      return KeyEventResult.handled;
    }
    if (keyboard.isControlPressed && key == LogicalKeyboardKey.keyZ) {
      _undoEditorChange();
      return KeyEventResult.handled;
    }
    if (BusyMarkAppShortcutActivators.search.accepts(event, keyboard)) {
      widget.onOpenSearch?.call();
      return KeyEventResult.handled;
    }
    if (BusyMarkTextEditingShortcutActivators.escape.accepts(event, keyboard)) {
      widget.onCloseSearch?.call();
      return KeyEventResult.handled;
    }
    final shortcutAction = BusyMarkEditorShortcutActivators.actionForKeyEvent(
      event,
      keyboard,
    );
    if (shortcutAction != null) {
      _applyEditorShortcutAction(shortcutAction);
      return KeyEventResult.handled;
    }
    if (_hasCommandModifierPressed()) {
      return KeyEventResult.ignored;
    }
    if ((key == LogicalKeyboardKey.backspace ||
            key == LogicalKeyboardKey.delete) &&
        _deleteBlockSelection()) {
      return KeyEventResult.handled;
    }
    final controller = _textControllers[blockId];
    if (controller == null || !controller.selection.isValid) {
      return KeyEventResult.ignored;
    }
    final selection = controller.selection;
    final shiftPressed = HardwareKeyboard.instance.isShiftPressed;
    if (!selection.isCollapsed) {
      if (key == LogicalKeyboardKey.enter && !shiftPressed) {
        final start = math
            .min(selection.start, selection.end)
            .clamp(0, controller.text.length)
            .toInt();
        final end = math
            .max(selection.start, selection.end)
            .clamp(start, controller.text.length)
            .toInt();
        final activeInlineKinds = _activeInlineKindsAt(blockId, start);
        _recordUndoSnapshot();
        _documentController.updateBlockText(
          blockId,
          controller.text.replaceRange(start, end, ''),
          activeInlineKinds: activeInlineKinds,
        );
        final result = _documentController.applyEnterAt(blockId, start);
        if (result == null) {
          return KeyEventResult.ignored;
        }
        if (_documentController.blockText(result.blockId).isEmpty) {
          _setPendingInlineKinds(result.blockId, activeInlineKinds);
        }
        _emitMarkdown();
        _focusBlockAfterFrame(result.blockId, offset: result.offset);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    final offset = controller.selection.extentOffset
        .clamp(0, controller.text.length)
        .toInt();
    final block = _documentController.blockById(blockId);
    if (block == null) {
      return KeyEventResult.ignored;
    }
    final textDirection = busyMarkWysiwygBlockTextDirection(
      block,
      fallback: Directionality.of(context),
    );
    final previousBlockKey = textDirection == TextDirection.rtl
        ? LogicalKeyboardKey.arrowRight
        : LogicalKeyboardKey.arrowLeft;
    final nextBlockKey = textDirection == TextDirection.rtl
        ? LogicalKeyboardKey.arrowLeft
        : LogicalKeyboardKey.arrowRight;
    if (shiftPressed) {
      if (key == LogicalKeyboardKey.arrowUp &&
          _isOffsetOnFirstTextLine(controller.text, offset)) {
        return _extendSelectionToRelativeBlock(
          blockId,
          -1,
          desiredOffset: _MoveToBlockEnd(),
        );
      }
      if (key == LogicalKeyboardKey.arrowDown &&
          _isOffsetOnLastTextLine(controller.text, offset)) {
        return _extendSelectionToRelativeBlock(
          blockId,
          1,
          desiredOffset: offset,
        );
      }
      if (key == previousBlockKey && offset == 0) {
        return _extendSelectionToRelativeBlock(
          blockId,
          -1,
          desiredOffset: _MoveToBlockEnd(),
        );
      }
      if (key == nextBlockKey && offset == controller.text.length) {
        return _extendSelectionToRelativeBlock(blockId, 1, desiredOffset: 0);
      }
      return KeyEventResult.ignored;
    }
    if (key == LogicalKeyboardKey.enter) {
      final activeInlineKinds = _activeInlineKindsAt(blockId, offset);
      _recordUndoSnapshot();
      final result = _documentController.applyEnterAt(blockId, offset);
      if (result == null) {
        return KeyEventResult.ignored;
      }
      if (_documentController.blockText(result.blockId).isEmpty) {
        _setPendingInlineKinds(result.blockId, activeInlineKinds);
      }
      _emitMarkdown();
      _focusBlockAfterFrame(result.blockId, offset: result.offset);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.backspace && offset == 0) {
      _recordUndoSnapshot();
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
    if (key == previousBlockKey && offset == 0) {
      return _focusRelativeBlock(blockId, -1, desiredOffset: _MoveToBlockEnd());
    }
    if (key == nextBlockKey && offset == controller.text.length) {
      return _focusRelativeBlock(blockId, 1, desiredOffset: 0);
    }
    return KeyEventResult.ignored;
  }

  bool _hasCommandModifierPressed() {
    final keyboard = HardwareKeyboard.instance;
    return keyboard.isControlPressed ||
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

  KeyEventResult _extendSelectionToRelativeBlock(
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
    final anchor = _selectionAnchorForBlock(blockId);
    if (anchor == null) {
      return KeyEventResult.ignored;
    }
    final nextBlock = blocks[nextIndex];
    final controller = _textControllerFor(nextBlock);
    final focusNode = _focusNodeFor(nextBlock);
    final offset = desiredOffset is _MoveToBlockEnd
        ? controller.text.length
        : (desiredOffset as int).clamp(0, controller.text.length).toInt();
    _activeBlockId = nextBlock.id;
    focusNode.requestFocus();
    controller.selection = TextSelection.collapsed(offset: offset);
    setState(() {
      _selectionStartBlockId = anchor.blockId;
      _selectionStartOffset = anchor.offset;
      _selectionEndBlockId = nextBlock.id;
      _selectionEndOffset = offset;
    });
    _collapseFieldSelections(exceptBlockId: nextBlock.id);
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
      _recordUndoSnapshot();
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
      _recordUndoSnapshot();
      final nextBlockId = _documentController.insertThematicBreakAfter(blockId);
      _emitMarkdown();
      if (nextBlockId != null) {
        _focusBlockAfterFrame(nextBlockId, offset: 0);
      }
      return;
    }
    _recordUndoSnapshot();
    _documentController.applyBlockCommand(blockId, command);
    _emitMarkdown();
  }

  void _applyInlineCommand(BusyWysiwygInlineCommand command) {
    final selectedRanges = _selectedTextRanges();
    if (selectedRanges.isNotEmpty) {
      _recordUndoSnapshot();
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
    if (controller == null || selection == null) {
      return;
    }
    if (selection.isCollapsed) {
      _togglePendingInlineKind(blockId, inlineKindForCommand(command));
      return;
    }
    _recordUndoSnapshot();
    _documentController.applyInlineCommand(
      blockId,
      command,
      selection.start,
      selection.end,
    );
    _emitMarkdown();
  }

  void _applyEditorShortcutAction(BusyMarkEditorShortcutAction action) {
    switch (action) {
      case BusyMarkEditorShortcutAction.bold:
        _applyInlineCommand(BusyWysiwygInlineCommand.bold);
        break;
      case BusyMarkEditorShortcutAction.italic:
        _applyInlineCommand(BusyWysiwygInlineCommand.italic);
        break;
      case BusyMarkEditorShortcutAction.underline:
        _applyInlineCommand(BusyWysiwygInlineCommand.underline);
        break;
      case BusyMarkEditorShortcutAction.strikethrough:
        _applyInlineCommand(BusyWysiwygInlineCommand.strikethrough);
        break;
      case BusyMarkEditorShortcutAction.inlineCode:
        _applyInlineCommand(BusyWysiwygInlineCommand.code);
        break;
      case BusyMarkEditorShortcutAction.link:
        unawaited(_applyLinkCommand());
        break;
      case BusyMarkEditorShortcutAction.paragraph:
        _applyBlockCommand(BusyWysiwygBlockCommand.paragraph);
        break;
      case BusyMarkEditorShortcutAction.heading1:
        _applyBlockCommand(BusyWysiwygBlockCommand.heading1);
        break;
      case BusyMarkEditorShortcutAction.heading2:
        _applyBlockCommand(BusyWysiwygBlockCommand.heading2);
        break;
      case BusyMarkEditorShortcutAction.heading3:
        _applyBlockCommand(BusyWysiwygBlockCommand.heading3);
        break;
      case BusyMarkEditorShortcutAction.heading4:
        _applyBlockCommand(BusyWysiwygBlockCommand.heading4);
        break;
      case BusyMarkEditorShortcutAction.heading5:
        _applyBlockCommand(BusyWysiwygBlockCommand.heading5);
        break;
      case BusyMarkEditorShortcutAction.heading6:
        _applyBlockCommand(BusyWysiwygBlockCommand.heading6);
        break;
      case BusyMarkEditorShortcutAction.orderedList:
        _applyBlockCommand(BusyWysiwygBlockCommand.orderedList);
        break;
      case BusyMarkEditorShortcutAction.unorderedList:
        _applyBlockCommand(BusyWysiwygBlockCommand.unorderedList);
        break;
      case BusyMarkEditorShortcutAction.taskList:
        _applyBlockCommand(BusyWysiwygBlockCommand.taskList);
        break;
      case BusyMarkEditorShortcutAction.toggleTask:
        _applyToggleTaskCommand();
        break;
      case BusyMarkEditorShortcutAction.indent:
        _applyIndentCommand();
        break;
      case BusyMarkEditorShortcutAction.outdent:
        _applyOutdentCommand();
        break;
      case BusyMarkEditorShortcutAction.blockquote:
        _applyBlockCommand(BusyWysiwygBlockCommand.blockquote);
        break;
      case BusyMarkEditorShortcutAction.codeBlock:
        _applyBlockCommand(BusyWysiwygBlockCommand.codeBlock);
        break;
      case BusyMarkEditorShortcutAction.codeBlockLanguage:
        unawaited(_applyCodeLanguageCommand());
        break;
      case BusyMarkEditorShortcutAction.image:
        unawaited(_applyImageCommand());
        break;
      case BusyMarkEditorShortcutAction.inlineImage:
        unawaited(_applyInlineImageCommand());
        break;
      case BusyMarkEditorShortcutAction.table:
        unawaited(_applyTableCommand());
        break;
      case BusyMarkEditorShortcutAction.htmlBlock:
        unawaited(_applyHtmlCommand());
        break;
      case BusyMarkEditorShortcutAction.thematicBreak:
        _applyBlockCommand(BusyWysiwygBlockCommand.thematicBreak);
        break;
      case BusyMarkEditorShortcutAction.hardLineBreak:
        _applyHardBreakCommand();
        break;
      case BusyMarkEditorShortcutAction.pastePlainText:
        unawaited(_pastePlainTextIntoActiveBlock());
        break;
    }
  }

  Set<BusyInlineKind> _activeInlineKindsAt(String blockId, int offset) {
    final block = _documentController.blockById(blockId);
    final active = <BusyInlineKind>{...?_pendingInlineKindsByBlockId[blockId]};
    if (block == null) {
      return active;
    }
    final safeOffset = offset.clamp(0, block.plainText.length).toInt();
    for (final range in busyInlineStyleRanges(block.inlines)) {
      if (_isTypingInlineKind(range.kind) &&
          range.start <= safeOffset &&
          range.end >= safeOffset) {
        active.add(range.kind);
      }
    }
    return active;
  }

  void _setPendingInlineKinds(
    String blockId,
    Iterable<BusyInlineKind> inlineKinds,
  ) {
    final next = {
      for (final kind in inlineKinds)
        if (_isTypingInlineKind(kind)) kind,
    };
    if (next.isEmpty) {
      _pendingInlineKindsByBlockId.remove(blockId);
    } else {
      _pendingInlineKindsByBlockId[blockId] = next;
    }
  }

  void _togglePendingInlineKind(String blockId, BusyInlineKind inlineKind) {
    if (!_isTypingInlineKind(inlineKind)) {
      return;
    }
    final active = _activeInlineKindsAt(
      blockId,
      _textControllers[blockId]?.selection.extentOffset ?? 0,
    );
    if (active.contains(inlineKind)) {
      active.remove(inlineKind);
    } else {
      active.add(inlineKind);
    }
    _setPendingInlineKinds(blockId, active);
  }

  bool _isTypingInlineKind(BusyInlineKind kind) {
    return switch (kind) {
      BusyInlineKind.strong ||
      BusyInlineKind.emphasis ||
      BusyInlineKind.underline ||
      BusyInlineKind.strikethrough ||
      BusyInlineKind.code => true,
      _ => false,
    };
  }

  Future<void> _applyLinkCommand() async {
    final selectedRanges = _selectedTextRanges();
    if (selectedRanges.isNotEmpty) {
      final target = _captureDialogTarget();
      final destination = await _showLinkDialog(context);
      if (!_isDialogTargetCurrent(target) ||
          destination == null ||
          destination.trim().isEmpty) {
        return;
      }
      _recordUndoSnapshot();
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
    final target = _captureDialogTarget();
    final destination = await _showLinkDialog(context);
    if (!_isDialogTargetCurrent(target) ||
        destination == null ||
        destination.trim().isEmpty) {
      return;
    }
    _recordUndoSnapshot();
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
    final target = _captureDialogTarget();
    final result = await _showImageDialog(
      context,
      title: context.l10n.image,
      submitLabel: context.l10n.insert,
    );
    if (!_isDialogTargetCurrent(target) ||
        result == null ||
        result.source.trim().isEmpty) {
      return;
    }
    _recordUndoSnapshot();
    _documentController.applyImageBlock(
      blockId,
      source: result.source,
      alt: result.alt,
    );
    _emitMarkdown();
  }

  Future<void> _pasteIntoActiveBlock() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) {
      return;
    }
    final internalClipboard = _internalClipboard;
    if (internalClipboard != null &&
        internalClipboard.text == text &&
        _pasteInternalClipboardIntoActiveBlock(internalClipboard)) {
      return;
    }
    await _pastePlainTextIntoActiveBlock(textOverride: text);
  }

  bool _pasteInternalClipboardIntoActiveBlock(
    _WysiwygInternalClipboard clipboard,
  ) {
    final blockId = _activeBlockId;
    if (blockId == null) {
      return false;
    }
    final controller = _textControllers[blockId];
    if (controller == null) {
      return false;
    }
    final currentText = controller.text;
    final selection = controller.selection.isValid
        ? controller.selection
        : TextSelection.collapsed(offset: currentText.length);
    final start = math
        .min(selection.start, selection.end)
        .clamp(0, currentText.length)
        .toInt();
    final end = math
        .max(selection.start, selection.end)
        .clamp(start, currentText.length)
        .toInt();
    _recordUndoSnapshot();
    final result = _documentController.insertStyledBlocksAtSelection(
      blockId: blockId,
      selectionStart: start,
      selectionEnd: end,
      blocks: clipboard.blocks,
    );
    if (result == null) {
      return false;
    }
    _clearBlockSelection(collapseFields: false);
    _emitMarkdown();
    _focusBlockAfterFrame(result.blockId, offset: result.offset);
    return true;
  }

  Future<void> _pastePlainTextIntoActiveBlock({String? textOverride}) async {
    final blockId = _activeBlockId;
    if (blockId == null) {
      return;
    }
    final controller = _textControllers[blockId];
    if (controller == null) {
      return;
    }
    final text =
        textOverride ?? (await Clipboard.getData(Clipboard.kTextPlain))?.text;
    if (text == null || text.isEmpty) {
      return;
    }
    final currentText = controller.text;
    final selection = controller.selection.isValid
        ? controller.selection
        : TextSelection.collapsed(offset: currentText.length);
    final start = math
        .min(selection.start, selection.end)
        .clamp(0, currentText.length)
        .toInt();
    final end = math
        .max(selection.start, selection.end)
        .clamp(0, currentText.length)
        .toInt();
    final nextText = currentText.replaceRange(start, end, text);
    controller.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: start + text.length),
    );
    _handleBlockTextChanged(
      _documentController.document.filePath,
      blockId,
      nextText,
    );
  }

  bool _insertTabIntoBlock(String blockId) {
    final controller = _textControllers[blockId];
    if (controller == null) {
      return false;
    }
    final currentText = controller.text;
    final selection = controller.selection.isValid
        ? controller.selection
        : TextSelection.collapsed(offset: currentText.length);
    final start = math
        .min(selection.start, selection.end)
        .clamp(0, currentText.length)
        .toInt();
    final end = math
        .max(selection.start, selection.end)
        .clamp(start, currentText.length)
        .toInt();
    final nextText = currentText.replaceRange(start, end, '\t');
    controller.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: start + 1),
    );
    _handleBlockTextChanged(
      _documentController.document.filePath,
      blockId,
      nextText,
    );
    return true;
  }

  Future<void> _applyInlineImageCommand() async {
    final selectedRanges = _selectedTextRanges();
    final activeBlockId = _activeBlockId;
    final activeController = activeBlockId == null
        ? null
        : _textControllers[activeBlockId];
    final activeSelection = activeController?.selection;
    if (selectedRanges.isEmpty &&
        (activeBlockId == null ||
            activeController == null ||
            activeSelection == null ||
            !activeSelection.isValid)) {
      return;
    }
    final initialAlt = selectedRanges.isNotEmpty
        ? selectedRanges.first.block.plainText
              .substring(selectedRanges.first.start, selectedRanges.first.end)
              .trim()
        : activeSelection == null || activeSelection.isCollapsed
        ? ''
        : activeController!.text
              .substring(activeSelection.start, activeSelection.end)
              .trim();
    final dialogTitle = context.l10n.inlineImage;
    final insertLabel = context.l10n.insert;
    final fallbackAltText = context.l10n.image;
    final target = _captureDialogTarget();
    final result = await _showImageDialog(
      context,
      title: dialogTitle,
      initialAlt: initialAlt,
      submitLabel: insertLabel,
    );
    if (!_isDialogTargetCurrent(target) ||
        result == null ||
        result.source.trim().isEmpty) {
      return;
    }
    if (selectedRanges.isNotEmpty) {
      _recordUndoSnapshot();
      for (final range in selectedRanges) {
        _documentController.insertInlineImage(
          range.block.id,
          selectionStart: range.start,
          selectionEnd: range.end,
          source: result.source,
          alt: result.alt,
          fallbackAltText: fallbackAltText,
        );
      }
      _clearBlockSelection();
      _emitMarkdown();
      return;
    }
    final selection = activeSelection!;
    _recordUndoSnapshot();
    _documentController.insertInlineImage(
      activeBlockId!,
      selectionStart: selection.start,
      selectionEnd: selection.end,
      source: result.source,
      alt: result.alt,
      fallbackAltText: fallbackAltText,
    );
    _emitMarkdown();
  }

  Future<void> _applyTableCommand() async {
    final blockId = _activeBlockId;
    if (blockId == null) {
      return;
    }
    final block = _documentController.blockById(blockId);
    final l10n = context.l10n;
    String headerTextForColumn(int columnNumber) {
      return l10n.tableHeaderNumber(columnNumber);
    }

    final cellText = l10n.tableCellDefault;
    final target = _captureDialogTarget();
    final result = await _showTableDialog(
      context,
      initialColumns: block == null ? 2 : _tableColumnCount(block),
      initialRows: block == null ? 2 : _tableBodyRowCount(block),
    );
    if (!_isDialogTargetCurrent(target) || result == null) {
      return;
    }
    if (block?.kind == BusyBlockKind.table) {
      _recordUndoSnapshot();
      _documentController.replaceTable(
        blockId,
        columns: result.columns,
        rows: result.rows,
        headerTextForColumn: headerTextForColumn,
        cellText: cellText,
      );
      _emitMarkdown();
      return;
    }
    _recordUndoSnapshot();
    final paragraphId = _documentController.insertTableAfter(
      blockId,
      columns: result.columns,
      rows: result.rows,
      headerTextForColumn: headerTextForColumn,
      cellText: cellText,
    );
    _emitMarkdown();
    if (paragraphId != null) {
      _focusBlockAfterFrame(paragraphId, offset: 0);
    }
  }

  Future<void> _applyHtmlCommand() async {
    final blockId = _activeBlockId;
    if (blockId == null) {
      return;
    }
    final block = _documentController.blockById(blockId);
    if (block?.kind == BusyBlockKind.htmlBlock) {
      await _handleHtmlBlockEditRequested(blockId);
      return;
    }
    final target = _captureDialogTarget();
    final source = await _showHtmlDialog(
      context,
      initialSource:
          '<div>\n  <p>${context.l10n.htmlContentDefault}</p>\n</div>',
      submitLabel: context.l10n.insert,
    );
    if (!_isDialogTargetCurrent(target) ||
        source == null ||
        source.trim().isEmpty) {
      return;
    }
    _recordUndoSnapshot();
    final paragraphId = _documentController.insertRawHtmlBlockAfter(
      blockId,
      source,
    );
    _emitMarkdown();
    if (paragraphId != null) {
      _focusBlockAfterFrame(paragraphId, offset: 0);
    }
  }

  int _tableColumnCount(BusyBlock block) {
    if (block.kind != BusyBlockKind.table || block.children.isEmpty) {
      return 2;
    }
    return block.children.first.children.length
        .clamp(BusyMarkSizes.tableMinColumns, BusyMarkSizes.tableMaxColumns)
        .toInt();
  }

  int _tableBodyRowCount(BusyBlock block) {
    if (block.kind != BusyBlockKind.table) {
      return 2;
    }
    return (block.children.length - 1)
        .clamp(BusyMarkSizes.tableMinRows, BusyMarkSizes.tableMaxRows)
        .toInt();
  }

  void _applyIndentCommand() {
    final blockIds = _commandTargetBlockIds();
    if (blockIds.isEmpty) {
      return;
    }
    _recordUndoSnapshot();
    _documentController.indentListItems(blockIds);
    _clearBlockSelection();
    _emitMarkdown();
  }

  void _applyOutdentCommand() {
    final blockIds = _commandTargetBlockIds();
    if (blockIds.isEmpty) {
      return;
    }
    _recordUndoSnapshot();
    _documentController.outdentListItems(blockIds);
    _clearBlockSelection();
    _emitMarkdown();
  }

  void _applyToggleTaskCommand() {
    final blockIds = _commandTargetBlockIds();
    if (blockIds.isEmpty) {
      return;
    }
    _recordUndoSnapshot();
    _documentController.toggleTaskChecked(blockIds);
    _clearBlockSelection();
    _emitMarkdown();
  }

  void _applyHardBreakCommand() {
    final blockId = _activeBlockId;
    if (blockId == null) {
      return;
    }
    final controller = _textControllers[blockId];
    final block = _documentController.blockById(blockId);
    if (controller == null || block == null) {
      return;
    }
    final selection = controller.selection;
    final offset = selection.isValid
        ? selection.extentOffset.clamp(0, controller.text.length).toInt()
        : block.plainText.length;
    _recordUndoSnapshot();
    _documentController.insertHardBreak(blockId, offset);
    _emitMarkdown();
  }

  Future<void> _applyCodeLanguageCommand() async {
    final blockIds = _commandTargetBlockIds();
    if (blockIds.isEmpty) {
      return;
    }
    final firstBlock = _documentController.blockById(blockIds.first);
    final target = _captureDialogTarget();
    final language = await _showCodeLanguageDialog(
      context,
      initialLanguage: firstBlock?.attributes['language'] ?? '',
    );
    if (!_isDialogTargetCurrent(target) || language == null) {
      return;
    }
    _recordUndoSnapshot();
    for (final blockId in blockIds) {
      _documentController.applyCodeBlockLanguage(blockId, language);
    }
    _clearBlockSelection();
    _emitMarkdown();
  }

  List<String> _commandTargetBlockIds() {
    final selectedBlocks = _selectedBlocks();
    if (selectedBlocks.isNotEmpty) {
      return selectedBlocks.map((block) => block.id).toSet().toList();
    }
    final selectedRanges = _selectedTextRanges();
    if (selectedRanges.isNotEmpty) {
      return selectedRanges.map((range) => range.block.id).toSet().toList();
    }
    final blockId = _activeBlockId;
    return blockId == null ? const [] : [blockId];
  }

  Future<T?> _showEditorDialog<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    double maxWidth = BusyMarkSizes.dialogCompact,
  }) {
    final headerBar = widget.headerBarService;
    return showBusyMarkModalEditorDialog<T>(
      context,
      headerBarService: headerBar != null && headerBar.isAvailable
          ? headerBar
          : null,
      maxWidth: maxWidth,
      builder: builder,
    );
  }

  Future<String?> _showLinkDialog(BuildContext context) {
    var destination = '';
    return _showEditorDialog<String>(
      context,
      builder: (context) => BusyMarkModalEditorScaffold(
        title: context.l10n.link,
        cancelLabel: context.l10n.cancel,
        saveLabel: context.l10n.apply,
        onCancel: () => Navigator.pop(context),
        onSave: () => Navigator.pop(context, destination),
        children: [
          BusyMarkGroupedList(
            filled: true,
            children: [
              BusyMarkGroupedTextEntry(
                key: const ValueKey('wysiwyg-link-destination-field'),
                label: context.l10n.source,
                autofocus: true,
                textDirection: TextDirection.ltr,
                onChanged: (value) => destination = value,
                textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: BusyMarkTypography.monoFontFamily,
                  fontFamilyFallback: BusyMarkTypography.monoFontFamilyFallback,
                ),
                hintText: 'https://example.com',
                onSubmitted: (value) => Navigator.pop(context, value),
              ),
            ],
          ),
          const SizedBox(height: BusyMarkSpacing.lg),
        ],
      ),
    );
  }

  Future<_ImageDialogResult?> _showImageDialog(
    BuildContext context, {
    required String title,
    String initialSource = '',
    String initialAlt = '',
    required String submitLabel,
  }) {
    return _showEditorDialog<_ImageDialogResult>(
      context,
      builder: (context) => _ImageDialog(
        title: title,
        initialSource: initialSource,
        initialAlt: initialAlt,
        submitLabel: submitLabel,
      ),
    );
  }

  Future<_TableDialogResult?> _showTableDialog(
    BuildContext context, {
    required int initialColumns,
    required int initialRows,
  }) {
    return _showEditorDialog<_TableDialogResult>(
      context,
      builder: (context) => _TableDialog(
        initialColumns: initialColumns,
        initialRows: initialRows,
      ),
    );
  }

  Future<String?> _showHtmlDialog(
    BuildContext context, {
    required String initialSource,
    required String submitLabel,
  }) {
    var source = initialSource;
    return _showEditorDialog<String>(
      context,
      maxWidth: BusyMarkSizes.dialogNarrow,
      builder: (context) => BusyMarkModalEditorScaffold(
        title: context.l10n.editHtml,
        cancelLabel: context.l10n.cancel,
        saveLabel: submitLabel,
        onCancel: () => Navigator.pop(context),
        onSave: () => Navigator.pop(context, source),
        children: [
          BusyMarkGroupedList(
            filled: true,
            children: [
              BusyMarkGroupedTextEntry(
                key: const ValueKey('wysiwyg-html-source-field'),
                label: context.l10n.htmlSource,
                initialValue: initialSource,
                onChanged: (value) => source = value,
                autofocus: true,
                minLines: 8,
                maxLines: 16,
                textInputAction: TextInputAction.newline,
                textDirection: TextDirection.ltr,
                textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: BusyMarkTypography.monoFontFamily,
                  fontFamilyFallback: BusyMarkTypography.monoFontFamilyFallback,
                ),
                alignLabelWithHint: true,
              ),
            ],
          ),
          const SizedBox(height: BusyMarkSpacing.lg),
        ],
      ),
    );
  }

  Future<String?> _showCodeLanguageDialog(
    BuildContext context, {
    required String initialLanguage,
  }) {
    var language = initialLanguage;
    return _showEditorDialog<String>(
      context,
      builder: (context) => BusyMarkModalEditorScaffold(
        title: context.l10n.codeBlockLanguage,
        cancelLabel: context.l10n.cancel,
        saveLabel: context.l10n.apply,
        onCancel: () => Navigator.pop(context),
        onSave: () => Navigator.pop(context, language),
        children: [
          BusyMarkGroupedList(
            filled: true,
            children: [
              BusyMarkGroupedTextEntry(
                key: const ValueKey('wysiwyg-code-language-field'),
                label: context.l10n.language,
                initialValue: initialLanguage,
                onChanged: (value) => language = value,
                autofocus: true,
                textDirection: TextDirection.ltr,
                textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: BusyMarkTypography.monoFontFamily,
                  fontFamilyFallback: BusyMarkTypography.monoFontFamilyFallback,
                ),
                onSubmitted: (value) => Navigator.pop(context, value),
              ),
            ],
          ),
          const SizedBox(height: BusyMarkSpacing.lg),
        ],
      ),
    );
  }

  void _emitMarkdown() {
    _internalChange = true;
    final markdown = _documentController.markdown;
    widget.onDocumentChanged?.call(
      _documentController.document.copyWith(source: markdown),
    );
    widget.onSourceChanged(_documentController.document.filePath, markdown);
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

  _SelectionAnchor? _selectionAnchorForBlock(String fallbackBlockId) {
    final startBlockId = _selectionStartBlockId;
    final startOffset = _selectionStartOffset;
    if (startBlockId != null && startOffset != null) {
      return _SelectionAnchor(blockId: startBlockId, offset: startOffset);
    }
    final controller = _textControllers[fallbackBlockId];
    final selection = controller?.selection;
    if (controller == null || selection == null || !selection.isValid) {
      return null;
    }
    return _SelectionAnchor(
      blockId: fallbackBlockId,
      offset: selection.baseOffset.clamp(0, controller.text.length).toInt(),
    );
  }

  void _handleBlockPointerDown(String blockId, PointerDownEvent event) {
    if (event.buttons != kPrimaryMouseButton) {
      return;
    }
    final offset = _textOffsetAtGlobalPosition(blockId, event.position);
    if (HardwareKeyboard.instance.isShiftPressed) {
      final anchor = _selectionAnchorForBlock(_activeBlockId ?? blockId);
      if (anchor != null) {
        _pointerDownBlockId = anchor.blockId;
        _activeBlockId = blockId;
        setState(() {
          _selectionStartBlockId = anchor.blockId;
          _selectionStartOffset = anchor.offset;
          _selectionEndBlockId = blockId;
          _selectionEndOffset = offset;
        });
        _preserveSelectionFocusCallbacks = 2;
        _collapseFieldSelections();
        _selectionFocusNode.requestFocus();
        return;
      }
    }
    _clearBlockSelection();
    _collapseInactiveFieldSelections(blockId);
    _pointerDownBlockId = blockId;
    _selectionStartOffset = offset;
    _selectionEndOffset = null;
  }

  void _handleBlockPointerMove(PointerMoveEvent event) {
    if (_pointerDownBlockId == null || event.buttons != kPrimaryMouseButton) {
      return;
    }
    _updateBlockSelectionDrag(event.position);
  }

  bool _updateBlockSelectionDrag(Offset position) {
    final startBlockId = _pointerDownBlockId;
    if (startBlockId == null) {
      return false;
    }
    final targetBlockId = _blockIdAtGlobalPosition(position);
    if (targetBlockId == null || targetBlockId == startBlockId) {
      return false;
    }
    final endOffset = _textOffsetAtGlobalPosition(targetBlockId, position);
    if (_selectionStartBlockId == startBlockId &&
        _selectionEndBlockId == targetBlockId &&
        _selectionEndOffset == endOffset) {
      return false;
    }
    setState(() {
      _selectionStartBlockId = startBlockId;
      _selectionEndBlockId = targetBlockId;
      _selectionEndOffset = endOffset;
    });
    _collapseFieldSelections();
    _selectionFocusNode.requestFocus();
    return true;
  }

  void _handleBlockPointerUp(PointerUpEvent event) {
    _updateBlockSelectionDrag(event.position);
    _pointerDownBlockId = null;
    if (_preserveSelectionFocusCallbacks > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _preserveSelectionFocusCallbacks = 0;
      });
    }
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

  void _collapseInactiveFieldSelections(String activeBlockId) {
    _collapseFieldSelections(exceptBlockId: activeBlockId);
  }

  void _collapseFieldSelections({String? exceptBlockId}) {
    for (final entry in _textControllers.entries) {
      if (entry.key == exceptBlockId) {
        continue;
      }
      final controller = entry.value;
      if (!controller.selection.isValid) {
        continue;
      }
      final offset = controller.selection.extentOffset
          .clamp(0, controller.text.length)
          .toInt();
      controller.selection = TextSelection.collapsed(offset: offset);
    }
  }

  void _clearBlockSelection({bool collapseFields = true}) {
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
    if (collapseFields) {
      _collapseFieldSelections();
    }
  }

  void _selectAllForActiveBlock() {
    final blockId = _activeBlockId;
    if (blockId == null) {
      final blocks = _focusableBlocks();
      if (blocks.isNotEmpty) {
        _selectAllForBlock(blocks.first.id);
      }
      return;
    }
    _selectAllForBlock(blockId);
  }

  void _selectAllForBlock(String blockId) {
    final controller = _textControllers[blockId];
    final focusNode = _focusNodes[blockId];
    if (controller == null || focusNode == null) {
      return;
    }
    _activeBlockId = blockId;
    if (_isWholeBlockSelected(blockId)) {
      _selectWholeDocumentText();
      return;
    }
    _clearBlockSelection();
    focusNode.requestFocus();
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
  }

  bool _isWholeBlockSelected(String blockId) {
    if (_hasBlockSelection) {
      final ranges = _selectedTextRanges();
      return ranges.length == 1 &&
          ranges.single.block.id == blockId &&
          ranges.single.coversWholeBlock;
    }
    final controller = _textControllers[blockId];
    final selection = controller?.selection;
    if (controller == null || selection == null || !selection.isValid) {
      return false;
    }
    return math.min(selection.start, selection.end) == 0 &&
        math.max(selection.start, selection.end) == controller.text.length;
  }

  void _selectWholeDocumentText() {
    final blocks = _focusableBlocks();
    if (blocks.isEmpty) {
      return;
    }
    final first = blocks.first;
    final last = blocks.last;
    setState(() {
      _selectionStartBlockId = first.id;
      _selectionStartOffset = 0;
      _selectionEndBlockId = last.id;
      _selectionEndOffset = last.plainText.length;
    });
    _collapseFieldSelections();
    _selectionFocusNode.requestFocus();
  }

  bool _deleteBlockSelection() {
    final ranges = _selectedTextRanges();
    if (ranges.isEmpty) {
      return false;
    }
    final first = ranges.first;
    final last = ranges.last;
    _recordUndoSnapshot();
    final result = _documentController.deleteTextSelection(
      firstBlockId: first.block.id,
      firstStartOffset: first.start,
      lastBlockId: last.block.id,
      lastEndOffset: last.end,
      removedBlockIds: ranges.map((range) => range.block.id),
    );
    if (result == null) {
      return false;
    }
    _clearBlockSelection(collapseFields: false);
    _emitMarkdown();
    _focusBlockAfterFrame(result.blockId, offset: result.offset);
    return true;
  }

  void _copyBlockSelection() {
    _copyCurrentSelection();
  }

  bool _cutBlockSelection() {
    return _cutCurrentSelection();
  }

  bool _copyCurrentSelection() {
    final ranges = _currentSelectionRanges();
    if (ranges.isEmpty) {
      return false;
    }
    return _copyRangesToClipboard(ranges);
  }

  bool _cutCurrentSelection() {
    final ranges = _currentSelectionRanges();
    if (ranges.isEmpty || !_copyRangesToClipboard(ranges)) {
      return false;
    }
    if (_hasBlockSelection) {
      return _deleteBlockSelection();
    }
    return _deleteActiveTextSelection(ranges.single);
  }

  bool _copyRangesToClipboard(List<_SelectedTextRange> ranges) {
    final clipboardBlocks = <BusyWysiwygStyledBlock>[];
    final clipboardTexts = <String>[];
    for (final range in ranges) {
      final clipboardText = _copyTextForRange(range);
      if (clipboardText.trim().isEmpty) {
        continue;
      }
      clipboardTexts.add(clipboardText);
      clipboardBlocks.add(_styledBlockForRange(range));
    }
    if (clipboardTexts.isEmpty || clipboardBlocks.isEmpty) {
      return false;
    }
    final clipboardText = clipboardTexts.join('\n\n');
    _internalClipboard = _WysiwygInternalClipboard(
      text: clipboardText,
      blocks: clipboardBlocks,
    );
    unawaited(Clipboard.setData(ClipboardData(text: clipboardText)));
    return true;
  }

  List<_SelectedTextRange> _currentSelectionRanges() {
    final selectedRanges = _selectedTextRanges();
    if (selectedRanges.isNotEmpty) {
      return selectedRanges;
    }
    final activeRange = _activeTextSelectionRange();
    return activeRange == null ? const [] : [activeRange];
  }

  _SelectedTextRange? _activeTextSelectionRange() {
    final blockId = _activeBlockId;
    if (blockId == null) {
      return null;
    }
    final block = _documentController.blockById(blockId);
    final controller = _textControllers[blockId];
    final selection = controller?.selection;
    if (block == null ||
        controller == null ||
        selection == null ||
        !selection.isValid ||
        selection.isCollapsed) {
      return null;
    }
    final start = math
        .min(selection.start, selection.end)
        .clamp(0, controller.text.length)
        .toInt();
    final end = math
        .max(selection.start, selection.end)
        .clamp(start, controller.text.length)
        .toInt();
    if (end <= start) {
      return null;
    }
    return _SelectedTextRange(block: block, start: start, end: end);
  }

  BusyWysiwygStyledBlock _styledBlockForRange(_SelectedTextRange range) {
    final text = range.block.plainText;
    final start = range.start.clamp(0, text.length).toInt();
    final end = range.end.clamp(start, text.length).toInt();
    return BusyWysiwygStyledBlock(
      kind: range.coversWholeBlock ? range.block.kind : BusyBlockKind.paragraph,
      text: text.substring(start, end),
      ranges: _inlineRangesForSlice(
        busyInlineStyleRanges(range.block.inlines),
        start,
        end,
      ),
      attributes: range.coversWholeBlock ? range.block.attributes : const {},
    );
  }

  bool _deleteActiveTextSelection(_SelectedTextRange range) {
    final blockId = range.block.id;
    final controller = _textControllers[blockId];
    if (controller == null) {
      return false;
    }
    final text = controller.text;
    final start = range.start.clamp(0, text.length).toInt();
    final end = range.end.clamp(start, text.length).toInt();
    if (end <= start) {
      return false;
    }
    _recordUndoSnapshot();
    _documentController.updateBlockText(
      blockId,
      text.replaceRange(start, end, ''),
    );
    _emitMarkdown();
    _focusBlockAfterFrame(blockId, offset: start);
    return true;
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

  List<BusyInlineStyleRange> _inlineRangesForSlice(
    List<BusyInlineStyleRange> ranges,
    int start,
    int end,
  ) {
    if (end <= start) {
      return const [];
    }
    return [
      for (final range in ranges)
        if (range.end > start && range.start < end)
          BusyInlineStyleRange(
            start: (range.start < start ? start : range.start) - start,
            end: (range.end > end ? end : range.end) - start,
            kind: range.kind,
            destination: range.destination,
          ),
    ];
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
    final outerPadding = busyMarkWysiwygOuterPadding(
      block,
      first: _isFirstRootBlock(block.id),
    );
    final contentPadding = busyMarkWysiwygTextLayoutInsets(block);
    final prefixWidth = busyMarkWysiwygHasPrefix(block)
        ? BusyMarkSizes.wysiwygPrefixWidth + BusyMarkSpacing.sm
        : 0.0;
    final textDirection = busyMarkWysiwygBlockTextDirection(
      block,
      fallback: Directionality.of(context),
    );
    final maxWidth =
        (renderObject.size.width -
                prefixWidth -
                contentPadding.horizontal -
                outerPadding.horizontal)
            .clamp(1.0, double.infinity)
            .toDouble();
    final textLayoutWidth = (maxWidth - busyMarkWysiwygTextFieldLayoutInset)
        .clamp(1.0, double.infinity)
        .toDouble();
    final physicalLeftInset =
        outerPadding.left +
        contentPadding.left +
        (textDirection == TextDirection.ltr ? prefixWidth : 0.0);
    final textX = (local.dx - physicalLeftInset)
        .clamp(0.0, textLayoutWidth)
        .toDouble();
    final textY = (local.dy - outerPadding.top - contentPadding.top)
        .clamp(0.0, renderObject.size.height)
        .toDouble();
    final textPainter = TextPainter(
      text: TextSpan(text: controller.text, style: _textStyleForBlock(block)),
      textDirection: textDirection,
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.maybeLocaleOf(context),
    )..layout(maxWidth: textLayoutWidth);
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
      BusyBlockKind.heading when level == 3 => theme.titleMedium!.copyWith(
        fontWeight: FontWeight.w700,
      ),
      BusyBlockKind.heading when level == 4 => theme.titleSmall!.copyWith(
        fontWeight: FontWeight.w700,
      ),
      BusyBlockKind.heading when level == 5 => theme.bodyLarge!.copyWith(
        fontWeight: FontWeight.w700,
      ),
      BusyBlockKind.heading => theme.bodyMedium!.copyWith(
        fontWeight: FontWeight.w700,
      ),
      BusyBlockKind.codeBlock => busyMarkDocumentCodeTextStyle(context),
      _ => busyMarkDocumentBodyTextStyle(context),
    };
  }

  bool _isFirstRootBlock(String blockId) {
    final entries = _editorRenderEntries(_documentController.document.blocks);
    return entries.isNotEmpty &&
        entries.first.children == null &&
        entries.first.block.id == blockId;
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

class _WysiwygDialogTarget {
  const _WysiwygDialogTarget({
    required this.filePath,
    required this.generation,
  });

  final String filePath;
  final int generation;
}

class _SelectionAnchor {
  const _SelectionAnchor({required this.blockId, required this.offset});

  final String blockId;
  final int offset;
}

class _WysiwygInternalClipboard {
  const _WysiwygInternalClipboard({required this.text, required this.blocks});

  final String text;
  final List<BusyWysiwygStyledBlock> blocks;
}

class _EditableBlockEntry {
  const _EditableBlockEntry({required this.block, required this.depth});

  final BusyBlock block;
  final int depth;
}

class _EditorRenderEntry {
  const _EditorRenderEntry.block({required this.block, required this.depth})
    : children = null;

  const _EditorRenderEntry.blockquote({
    required this.block,
    required this.depth,
    required this.children,
  });

  final BusyBlock block;
  final int depth;
  final List<_EditorRenderEntry>? children;
}

class _FloatingWysiwygToolbar extends StatelessWidget {
  const _FloatingWysiwygToolbar({
    required this.placement,
    required this.direction,
    required this.visible,
    required this.maxWidth,
    required this.maxHeight,
    required this.onToggle,
    this.onPlacementChanged,
    this.onDirectionChanged,
    required this.child,
  });

  final EditorToolbarPlacement placement;
  final EditorToolbarDirection direction;
  final bool visible;
  final double maxWidth;
  final double maxHeight;
  final VoidCallback onToggle;
  final ValueChanged<EditorToolbarPlacement>? onPlacementChanged;
  final ValueChanged<EditorToolbarDirection>? onDirectionChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final axis = direction._axis;
    final alignedEnd = axis == Axis.horizontal
        ? placement._isRight
        : !placement._isTop;
    final toolbar = visible
        ? Flexible(fit: FlexFit.loose, child: child)
        : const SizedBox.shrink();
    final configurable =
        onPlacementChanged != null || onDirectionChanged != null;
    final toggle = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapUp: configurable
          ? (details) =>
                unawaited(_showSettingsMenu(context, details.globalPosition))
          : null,
      child: BusyMarkHeaderIconButton(
        tooltip: visible
            ? context.l10n.hideEditingButtons
            : context.l10n.showEditingButtons,
        icon: visible ? BusyMarkGlyphs.hide : BusyMarkGlyphs.edit,
        onPressed: onToggle,
        accented: true,
        elevated: true,
        foregroundColor: BusyMarkLinuxPalette.white,
      ),
    );
    final gap = visible
        ? SizedBox(
            width: axis == Axis.horizontal ? BusyMarkSpacing.xs : null,
            height: axis == Axis.vertical ? BusyMarkSpacing.xs : null,
          )
        : const SizedBox.shrink();
    final toolbarChildren = alignedEnd
        ? [toolbar, gap, toggle]
        : [toggle, gap, toolbar];
    return Positioned(
      top: placement._isTop ? BusyMarkSpacing.sm : null,
      bottom: placement._isTop ? null : BusyMarkSpacing.sm,
      left: placement._isRight ? null : BusyMarkSpacing.sm,
      right: placement._isRight ? BusyMarkSpacing.sm : null,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: SizedBox(
          width: axis == Axis.vertical ? _floatingWysiwygToolbarExtent : null,
          height: axis == Axis.horizontal
              ? _floatingWysiwygToolbarExtent
              : null,
          child: Flex(
            direction: axis,
            textDirection: TextDirection.ltr,
            mainAxisSize: MainAxisSize.min,
            children: toolbarChildren,
          ),
        ),
      ),
    );
  }

  Future<void> _showSettingsMenu(BuildContext context, Offset position) async {
    final placementCallback = onPlacementChanged;
    final directionCallback = onDirectionChanged;
    final action = await showBusyMarkContextMenu<_EditorToolbarMenuAction>(
      context,
      position,
      items: [
        if (placementCallback != null)
          for (final value in EditorToolbarPlacement.values)
            BusyMarkPopupMenuItem(
              value: _EditorToolbarMenuAction.forPlacement(value),
              label: _editorToolbarPlacementLabel(context, value),
              checked: placement == value,
              trailingCheck: true,
            ),
        if (placementCallback != null && directionCallback != null)
          const PopupMenuDivider(height: BusyMarkSpacing.sm),
        if (directionCallback != null)
          for (final value in EditorToolbarDirection.values)
            BusyMarkPopupMenuItem(
              value: _EditorToolbarMenuAction.forDirection(value),
              label: _editorToolbarDirectionLabel(context, value),
              checked: direction == value,
              trailingCheck: true,
            ),
      ],
    );
    if (action == null) {
      return;
    }
    final selectedPlacement = action.placement;
    if (selectedPlacement != null) {
      placementCallback?.call(selectedPlacement);
      return;
    }
    final selectedDirection = action.direction;
    if (selectedDirection != null) {
      directionCallback?.call(selectedDirection);
    }
  }
}

const double _floatingWysiwygToolbarExtent =
    BusyMarkSizes.wysiwygToolbarReserve;

class _EditorToolbarMenuAction {
  const _EditorToolbarMenuAction.forPlacement(this.placement)
    : direction = null;

  const _EditorToolbarMenuAction.forDirection(this.direction)
    : placement = null;

  final EditorToolbarPlacement? placement;
  final EditorToolbarDirection? direction;
}

String _editorToolbarPlacementLabel(
  BuildContext context,
  EditorToolbarPlacement placement,
) {
  return switch (placement) {
    EditorToolbarPlacement.topLeft => context.l10n.topLeft,
    EditorToolbarPlacement.topRight => context.l10n.topRight,
    EditorToolbarPlacement.bottomLeft => context.l10n.bottomLeft,
    EditorToolbarPlacement.bottomRight => context.l10n.bottomRight,
  };
}

String _editorToolbarDirectionLabel(
  BuildContext context,
  EditorToolbarDirection direction,
) {
  return switch (direction) {
    EditorToolbarDirection.horizontal => context.l10n.horizontal,
    EditorToolbarDirection.vertical => context.l10n.vertical,
  };
}

extension _EditorToolbarPlacementX on EditorToolbarPlacement {
  bool get _isTop {
    return this == EditorToolbarPlacement.topLeft ||
        this == EditorToolbarPlacement.topRight;
  }

  bool get _isRight {
    return this == EditorToolbarPlacement.topRight ||
        this == EditorToolbarPlacement.bottomRight;
  }
}

extension _EditorToolbarDirectionX on EditorToolbarDirection {
  Axis get _axis {
    return switch (this) {
      EditorToolbarDirection.horizontal => Axis.horizontal,
      EditorToolbarDirection.vertical => Axis.vertical,
    };
  }
}

class _EditorShortcutIntent extends Intent {
  const _EditorShortcutIntent(this.action);

  final BusyMarkEditorShortcutAction action;
}

class _PasteTextIntent extends Intent {
  const _PasteTextIntent();
}

class _SelectAllTextIntent extends Intent {
  const _SelectAllTextIntent();
}

class _DeleteBlockSelectionIntent extends Intent {
  const _DeleteBlockSelectionIntent();
}

class _CopyBlockSelectionIntent extends Intent {
  const _CopyBlockSelectionIntent();
}

class _CutBlockSelectionIntent extends Intent {
  const _CutBlockSelectionIntent();
}

class _ClearBlockSelectionIntent extends Intent {
  const _ClearBlockSelectionIntent();
}

class _UndoEditorIntent extends Intent {
  const _UndoEditorIntent();
}

class _RedoEditorIntent extends Intent {
  const _RedoEditorIntent();
}

class _MoveToBlockEnd {
  const _MoveToBlockEnd();
}

String _imageSourceForBlock(BusyBlock block) {
  final attributeSource = block.attributes['src'];
  if (attributeSource != null && attributeSource.trim().isNotEmpty) {
    return attributeSource.trim();
  }
  for (final inline in block.inlines) {
    final source = _imageSourceFromInline(inline);
    if (source != null) {
      return source;
    }
  }
  return '';
}

String? _imageSourceFromInline(BusyInline inline) {
  if (inline.kind == BusyInlineKind.image &&
      inline.destination != null &&
      inline.destination!.trim().isNotEmpty) {
    return inline.destination!.trim();
  }
  for (final child in inline.children) {
    final source = _imageSourceFromInline(child);
    if (source != null) {
      return source;
    }
  }
  return null;
}

class _ImageDialogResult {
  const _ImageDialogResult({required this.source, required this.alt});

  final String source;
  final String alt;
}

abstract final class BusyMarkImageDialogKeys {
  static const source = ValueKey<String>('wysiwyg-image-source-field');
  static const alt = ValueKey<String>('wysiwyg-image-alt-field');
  static const choose = ValueKey<String>('wysiwyg-image-choose');
  static const cancel = ValueKey<String>('wysiwyg-image-cancel');
  static const submit = ValueKey<String>('wysiwyg-image-submit');
}

class _ImageDialog extends StatefulWidget {
  const _ImageDialog({
    required this.title,
    this.initialSource = '',
    this.initialAlt = '',
    required this.submitLabel,
  });

  final String title;
  final String initialSource;
  final String initialAlt;
  final String submitLabel;

  @override
  State<_ImageDialog> createState() => _ImageDialogState();
}

class _ImageDialogState extends State<_ImageDialog> {
  final _sourceController = TextEditingController();
  final _altController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _sourceController.text = widget.initialSource;
    _altController.text = widget.initialAlt;
    _sourceController.addListener(_handleSourceChanged);
  }

  @override
  void dispose() {
    _sourceController.removeListener(_handleSourceChanged);
    _sourceController.dispose();
    _altController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BusyMarkModalEditorScaffold(
      title: widget.title,
      cancelLabel: context.l10n.cancel,
      saveLabel: widget.submitLabel,
      cancelKey: BusyMarkImageDialogKeys.cancel,
      saveKey: BusyMarkImageDialogKeys.submit,
      onCancel: () => Navigator.pop(context),
      onSave: _canSubmit ? _submit : null,
      children: [
        BusyMarkGroupedList(
          filled: true,
          children: [
            BusyMarkGroupedTextEntry(
              key: BusyMarkImageDialogKeys.source,
              label: context.l10n.source,
              controller: _sourceController,
              hintText: 'images/example.png',
              autofocus: true,
              textDirection: TextDirection.ltr,
              textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: BusyMarkTypography.monoFontFamily,
                fontFamilyFallback: BusyMarkTypography.monoFontFamilyFallback,
              ),
              textInputAction: TextInputAction.next,
              trailing: BusyMarkPushButton.standardIcon(
                key: BusyMarkImageDialogKeys.choose,
                icon: const Icon(BusyMarkGlyphs.folderOpen),
                label: Text(context.l10n.choose),
                onPressed: _chooseImage,
              ),
            ),
            BusyMarkGroupedTextEntry(
              key: BusyMarkImageDialogKeys.alt,
              label: context.l10n.altText,
              controller: _altController,
              hintText: context.l10n.describeTheImage,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
        const SizedBox(height: BusyMarkSpacing.lg),
      ],
    );
  }

  bool get _canSubmit => _sourceController.text.trim().isNotEmpty;

  void _handleSourceChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _chooseImage() async {
    final file = await openFile(
      acceptedTypeGroups: [
        XTypeGroup(
          label: context.l10n.fileTypeImages,
          extensions: const ['png', 'jpg', 'jpeg', 'gif', 'svg', 'webp'],
        ),
      ],
    );
    if (file == null || !mounted) {
      return;
    }
    _sourceController.text = file.path;
    if (_altController.text.trim().isEmpty) {
      _altController.text = file.name;
    }
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

class _TableDialogResult {
  const _TableDialogResult({required this.columns, required this.rows});

  final int columns;
  final int rows;
}

class _TableDialog extends StatefulWidget {
  const _TableDialog({required this.initialColumns, required this.initialRows});

  final int initialColumns;
  final int initialRows;

  @override
  State<_TableDialog> createState() => _TableDialogState();
}

class _TableDialogState extends State<_TableDialog> {
  late final TextEditingController _columnsController;
  late final TextEditingController _rowsController;

  @override
  void initState() {
    super.initState();
    _columnsController = TextEditingController(
      text:
          '${widget.initialColumns.clamp(BusyMarkSizes.tableMinColumns, BusyMarkSizes.tableMaxColumns)}',
    );
    _rowsController = TextEditingController(
      text:
          '${widget.initialRows.clamp(BusyMarkSizes.tableMinRows, BusyMarkSizes.tableMaxRows)}',
    );
  }

  @override
  void dispose() {
    _columnsController.dispose();
    _rowsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BusyMarkModalEditorScaffold(
      title: context.l10n.table,
      cancelLabel: context.l10n.cancel,
      saveLabel: context.l10n.insert,
      onCancel: () => Navigator.pop(context),
      onSave: _submit,
      children: [
        BusyMarkGroupedList(
          filled: true,
          children: [
            BusyMarkGroupedTextEntry(
              label: context.l10n.columns,
              controller: _columnsController,
              autofocus: true,
              keyboardType: TextInputType.number,
              hintText: '2',
              onSubmitted: (_) => _submit(),
            ),
            BusyMarkGroupedTextEntry(
              label: context.l10n.rows,
              controller: _rowsController,
              keyboardType: TextInputType.number,
              hintText: '2',
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
        const SizedBox(height: BusyMarkSpacing.lg),
      ],
    );
  }

  void _submit() {
    final columns = int.tryParse(_columnsController.text.trim()) ?? 2;
    final rows = int.tryParse(_rowsController.text.trim()) ?? 2;
    Navigator.pop(
      context,
      _TableDialogResult(
        columns: columns
            .clamp(BusyMarkSizes.tableMinColumns, BusyMarkSizes.tableMaxColumns)
            .toInt(),
        rows: rows
            .clamp(BusyMarkSizes.tableMinRows, BusyMarkSizes.tableMaxRows)
            .toInt(),
      ),
    );
  }
}
