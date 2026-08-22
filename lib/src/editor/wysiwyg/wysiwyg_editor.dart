import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:path/path.dart' as p;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../ai/ai_models.dart';
import '../../assets/asset_ingestion_service.dart';
import '../../assets/asset_input_service.dart';
import '../../app/app_settings.dart';
import '../../app/busymark_dialogs.dart';
import '../../app/busymark_design.dart';
import '../../app/busymark_glyphs.dart';
import '../../app/busymark_shortcuts.dart';
import '../../app/command_registry.dart';
import '../../app/localization.dart';
import '../../core/source_span.dart';
import '../../markdown/busymark_document.dart';
import '../../markdown/document_outline.dart';
import '../../markdown/markdown_parser.dart';
import '../../platform/linux_header_bar_service.dart';
import '../document_callout.dart';
import '../document_code_block.dart';
import '../document_layout.dart';
import '../document_surface.dart';
import '../document_text_geometry.dart';
import 'wysiwyg_block_widgets.dart';
import 'wysiwyg_commands.dart';
import 'wysiwyg_document_controller.dart';
import 'wysiwyg_inline_controller.dart';
import 'wysiwyg_session_state.dart';
import 'wysiwyg_toolbar.dart';

typedef BusyMarkWysiwygSourceChanged =
    void Function(String filePath, String source);
typedef BusyMarkWysiwygSessionChanged =
    void Function(String documentId, WysiwygEditorSessionState state);

class BusyMarkWysiwygEditor extends StatefulWidget {
  const BusyMarkWysiwygEditor({
    super.key,
    required this.document,
    required this.onSourceChanged,
    this.documentId,
    this.initialSessionState = const WysiwygEditorSessionState(),
    this.onSessionChanged,
    this.useExternalUndoHistory = false,
    this.onDocumentChanged,
    this.workspaceRoot,
    this.writersideRoot,
    this.imagesDir = 'images',
    this.assetWorkspaceKind,
    this.assetIngestionService = const AssetIngestionService(),
    this.assetInputService,
    this.onAssetSaveRequired,
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
    this.onVisibleHeadingChanged,
    this.onOpenSearch,
    this.onCloseSearch,
    this.onUndo,
    this.onRedo,
    this.headerBarService,
    this.documentLayout,
    this.visualizationRevision = 0,
    this.onAiEdit,
    this.onMathDiagnostic,
  });

  final BusyDocument document;
  final BusyMarkWysiwygSourceChanged onSourceChanged;
  final String? documentId;
  final WysiwygEditorSessionState initialSessionState;
  final BusyMarkWysiwygSessionChanged? onSessionChanged;
  final bool useExternalUndoHistory;
  final ValueChanged<BusyDocument>? onDocumentChanged;
  final String? workspaceRoot;
  final String? writersideRoot;
  final String imagesDir;
  final AssetWorkspaceKind? assetWorkspaceKind;
  final AssetIngestionService assetIngestionService;
  final AssetInputService? assetInputService;
  final VoidCallback? onAssetSaveRequired;
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
  final ValueChanged<DocumentOutlineHeading?>? onVisibleHeadingChanged;
  final VoidCallback? onOpenSearch;
  final VoidCallback? onCloseSearch;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final LinuxHeaderBarService? headerBarService;
  final BusyMarkDocumentLayoutSpec? documentLayout;
  final int visualizationRevision;
  final BusyMarkAiEditCallback? onAiEdit;
  final BusyMarkWysiwygMathDiagnosticCallback? onMathDiagnostic;

  @override
  State<BusyMarkWysiwygEditor> createState() => _BusyMarkWysiwygEditorState();
}

class _BusyMarkWysiwygEditorState extends State<BusyMarkWysiwygEditor> {
  static const _historyLimit = 100;

  late final BusyMarkWysiwygDocumentController _documentController;
  final _textControllers = <String, BusyMarkWysiwygTextController>{};
  final _textUndoControllers = <String, UndoHistoryController>{};
  final _focusNodes = <String, FocusNode>{};
  StreamSubscription<List<String>>? _assetDropSubscription;
  final _blockKeys = <String, GlobalKey>{};
  final _undoStack = <BusyDocument>[];
  final _redoStack = <BusyDocument>[];
  final _itemScrollController = ItemScrollController();
  final _itemPositionsListener = ItemPositionsListener.create();
  List<({int itemIndex, DocumentOutlineHeading heading})>
  _viewportOutlineStops = const [];
  List<String> _viewportBlockIds = const [];
  String? _reportedVisibleHeadingKey;
  bool _hasReportedVisibleHeading = false;
  late final FocusNode _selectionFocusNode;
  String? _activeBlockId;
  _DocumentTextSelection? _documentSelection;
  _DocumentTextPosition? _pointerSelectionAnchor;
  VerticalCaretMovementRun? _verticalCaretMovement;
  String? _verticalCaretMovementBlockId;
  TextPosition? _verticalCaretMovementPosition;
  double? _preferredVerticalCaretX;
  _WysiwygInternalClipboard? _internalClipboard;
  final _pendingInlineKindsByBlockId = <String, Set<BusyInlineKind>>{};
  int _preserveSelectionFocusCallbacks = 0;
  bool _internalChange = false;
  bool _initialFocusScheduled = false;
  var _toolbarVisible = true;
  var _documentGeneration = 0;
  bool _sessionReportScheduled = false;

  String get _documentId => widget.documentId ?? widget.document.filePath;

  @override
  void initState() {
    super.initState();
    _selectionFocusNode = FocusNode(
      debugLabel: 'BusyMark WYSIWYG document selection',
      onKeyEvent: _handleDocumentSelectionKeyEvent,
    );
    _documentController = BusyMarkWysiwygDocumentController(
      document: widget.document,
    )..addListener(_handleDocumentControllerChanged);
    _listenForDroppedAssets();
    _itemPositionsListener.itemPositions.addListener(
      _handleVisibleItemsChanged,
    );
    _syncBlockControllers();
    _scheduleSessionRestore(widget.initialSessionState);
    _scheduleHeadingScroll();
    _scheduleSearchScroll();
    _scheduleVisibleHeadingReport();
  }

  @override
  void didUpdateWidget(covariant BusyMarkWysiwygEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetInputService != widget.assetInputService) {
      unawaited(_assetDropSubscription?.cancel());
      _listenForDroppedAssets();
    }
    final oldDocumentId = oldWidget.documentId ?? oldWidget.document.filePath;
    final fileChanged = oldDocumentId != _documentId;
    final sourceChanged = oldWidget.document.source != widget.document.source;
    if (fileChanged || (sourceChanged && !_internalChange)) {
      _hasReportedVisibleHeading = false;
      if (fileChanged) {
        _reportSessionNow(
          callback: oldWidget.onSessionChanged,
          documentId: oldDocumentId,
        );
        _undoStack.clear();
        _redoStack.clear();
        _internalChange = false;
        _resetPerDocumentState();
      }
      _documentController.replaceDocument(widget.document);
      _initialFocusScheduled = false;
      _scheduleSessionRestore(widget.initialSessionState);
      _scheduleVisibleHeadingReport();
    } else if (oldWidget.onVisibleHeadingChanged !=
        widget.onVisibleHeadingChanged) {
      _hasReportedVisibleHeading = false;
      _scheduleVisibleHeadingReport();
    }
    if (oldWidget.scrollRequest != widget.scrollRequest) {
      _scheduleHeadingScroll();
      _scheduleSearchScroll();
    }
  }

  @override
  void dispose() {
    unawaited(_assetDropSubscription?.cancel());
    _itemPositionsListener.itemPositions.removeListener(
      _handleVisibleItemsChanged,
    );
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
    _documentSelection = null;
    _pointerSelectionAnchor = null;
    _resetVerticalCaretMovement();
  }

  void _scheduleVisibleHeadingReport() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _handleVisibleItemsChanged();
      }
    });
  }

  void _handleVisibleItemsChanged() {
    if (!mounted) {
      return;
    }
    int? firstVisible;
    for (final position in _itemPositionsListener.itemPositions.value) {
      if (position.itemTrailingEdge <= 0 || position.itemLeadingEdge >= 1) {
        continue;
      }
      if (firstVisible == null || position.index < firstVisible) {
        firstVisible = position.index;
      }
    }
    if (firstVisible == null) {
      return;
    }
    _scheduleSessionReport();
    if (_viewportOutlineStops.isEmpty) {
      return;
    }
    var low = 0;
    var high = _viewportOutlineStops.length - 1;
    DocumentOutlineHeading? heading;
    while (low <= high) {
      final middle = (low + high) >> 1;
      final candidate = _viewportOutlineStops[middle];
      if (candidate.itemIndex <= firstVisible) {
        heading = candidate.heading;
        low = middle + 1;
      } else {
        high = middle - 1;
      }
    }
    final key = heading == null
        ? null
        : '${heading.id}\u0000${heading.editorBlockId ?? ''}'
              '\u0000${heading.sourceStartOffset ?? ''}';
    if (_hasReportedVisibleHeading && _reportedVisibleHeadingKey == key) {
      return;
    }
    _hasReportedVisibleHeading = true;
    _reportedVisibleHeadingKey = key;
    widget.onVisibleHeadingChanged?.call(heading);
  }

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final commandRegistry =
        BusyMarkCommandRegistryScope.maybeOf(context) ??
        BusyMarkCommandCatalog.metadata;
    final entries = _editableBlockEntries(_documentController.document.blocks);
    final renderEntries = _editorRenderEntries(
      _documentController.document.blocks,
    );
    final outline = _documentController.document.outline;
    final outlineByBlockId = {
      for (final heading in outline)
        if (heading.editorBlockId case final blockId?) blockId: heading,
    };
    final outlineByHeadingId = {
      for (final heading in outline) heading.id: heading,
    };
    _viewportOutlineStops = [
      for (final (index, entry) in renderEntries.indexed)
        if (outlineByBlockId[entry.block.id] ??
                outlineByHeadingId[entry.block.attributes['id']]
            case final heading?)
          (itemIndex: index, heading: heading),
    ];
    _viewportBlockIds = [for (final entry in renderEntries) entry.block.id];
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
        ...commandRegistry.shortcutIntents(
          scopes: const {BusyMarkCommandScope.editor},
          intentFor: BusyMarkContextCommandIntent.new,
        ),
        commandRegistry[BusyMarkCommandIds.textPaste]!.shortcut!.activator:
            const _PasteTextIntent(),
        commandRegistry[BusyMarkCommandIds.textSelectAll]!.shortcut!.activator:
            const _SelectAllTextIntent(),
        commandRegistry['text.undo']!.shortcut!.activator:
            const _UndoEditorIntent(),
        commandRegistry['text.redo']!.shortcut!.activator:
            const _RedoEditorIntent(),
        if (blockSelectionActive)
          commandRegistry[BusyMarkCommandIds.textCopy]!.shortcut!.activator:
              const _CopyBlockSelectionIntent(),
        if (blockSelectionActive)
          commandRegistry[BusyMarkCommandIds.textCut]!.shortcut!.activator:
              const _CutBlockSelectionIntent(),
        if (blockSelectionActive)
          const SingleActivator(LogicalKeyboardKey.backspace):
              const _DeleteBlockSelectionIntent(),
        if (blockSelectionActive)
          const SingleActivator(LogicalKeyboardKey.delete):
              const _DeleteBlockSelectionIntent(),
        if (blockSelectionActive)
          commandRegistry['text.escape']!.shortcut!.activator:
              const _ClearBlockSelectionIntent(),
      },
      child: Actions(
        actions: {
          BusyMarkContextCommandIntent: BusyMarkContextCommandAction(
            isCommandEnabled: _canApplyContextCommand,
            onCommand: _applyContextCommand,
          ),
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
              if (widget.useExternalUndoHistory || !_undoEditorChange()) {
                widget.onUndo?.call();
              }
              return null;
            },
          ),
          _RedoEditorIntent: CallbackAction<_RedoEditorIntent>(
            onInvoke: (intent) {
              if (widget.useExternalUndoHistory || !_redoEditorChange()) {
                widget.onRedo?.call();
              }
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
                        child: ScrollablePositionedList.builder(
                          key: const ValueKey('wysiwyg-document-scroll'),
                          itemScrollController: _itemScrollController,
                          itemPositionsListener: _itemPositionsListener,
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
                      onInlineMathCommand: _applyInlineMathCommand,
                      onDisplayMathCommand: _applyDisplayMathCommand,
                      onImageCommand: () => unawaited(_applyImageCommand()),
                      onInlineImageCommand: () =>
                          unawaited(_applyInlineImageCommand()),
                      onTableCommand: () => unawaited(_applyTableCommand()),
                      onHtmlCommand: () => unawaited(_applyHtmlCommand()),
                      onIndentCommand: _applyIndentCommand,
                      onOutdentCommand: _applyOutdentCommand,
                      onToggleTaskCommand: _applyToggleTaskCommand,
                      onHardBreakCommand: _applyHardBreakCommand,
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
            listRunEnd: entry.listRunEnd,
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
        start: entry.depth * BusyMarkSizes.documentListIndent,
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
    required bool listRunEnd,
    required Set<String> selectedBlockIds,
    required Map<String, BusyMarkWysiwygSelectionRange>
    selectionRangesByBlockId,
  }) {
    final documentFilePath = _documentController.document.filePath;
    return BusyMarkWysiwygBlockField(
      key: _blockKeyFor(block.id),
      block: block,
      first: first,
      listRunEnd: listRunEnd,
      documentFilePath: documentFilePath,
      workspaceRoot: widget.workspaceRoot,
      writersideRoot: widget.writersideRoot,
      imagesDir: widget.imagesDir,
      allowRemoteImages: widget.allowRemoteImages,
      onRemoteImageBlocked: widget.onRemoteImageBlocked,
      onMathDiagnostic: widget.onMathDiagnostic,
      controller: _textControllerFor(block),
      undoController: _textUndoControllerFor(block),
      focusNode: _focusNodeFor(block),
      selected: selectedBlockIds.contains(block.id),
      selectionRange: selectionRangesByBlockId[block.id],
      onPointerDown: (event) => _handleBlockPointerDown(block.id, event),
      onPointerMove: _handleBlockPointerMove,
      onPointerUp: _handleBlockPointerUp,
      onFocused: () => _handleBlockFocused(block.id),
      onRefineWithAi: widget.onAiEdit == null
          ? null
          : () => unawaited(_runAiEdit(blockId: block.id)),
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
      onTableColumnAlignmentChanged: (columnIndex, alignment) =>
          _handleTableColumnAlignmentChanged(block.id, columnIndex, alignment),
      onTableDeleted: () => _handleTableDeleted(block.id),
      onImageEditRequested: () =>
          unawaited(_handleImageBlockEditRequested(block.id)),
      onHtmlEditRequested: () =>
          unawaited(_handleHtmlBlockEditRequested(block.id)),
      onTaskChanged: (checked) => _handleTaskCheckedChanged(block.id, checked),
      editRevision: widget.visualizationRevision + _documentGeneration,
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
    final documentSelection = _documentSelection;
    if (documentSelection != null &&
        (!ids.contains(documentSelection.anchor.blockId) ||
            !ids.contains(documentSelection.extent.blockId))) {
      _documentSelection = null;
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
    final controller = _textControllers.putIfAbsent(block.id, () {
      final created = BusyMarkWysiwygTextController(
        text: busyMarkWysiwygEditableText(block),
        ranges: busyMarkWysiwygBlockContainsMath(block)
            ? const []
            : busyInlineStyleRanges(block.inlines),
      );
      created.addListener(_scheduleSessionReport);
      return created;
    });
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
    final visibleBlocks = blocks
        .where(
          (block) =>
              block.kind != BusyBlockKind.frontMatter && !block.isSourceOnly,
        )
        .toList();
    for (final (index, block) in visibleBlocks.indexed) {
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
      final nextBlock = index + 1 < visibleBlocks.length
          ? visibleBlocks[index + 1]
          : null;
      entries.add(
        _EditorRenderEntry.block(
          block: block,
          depth: depth,
          listRunEnd:
              _isListItemBlock(block) &&
              (nextBlock == null || !_isListItemBlock(nextBlock)),
        ),
      );
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
    return _isListItemBlock(block) || block.kind == BusyBlockKind.blockquote;
  }

  bool _isListItemBlock(BusyBlock block) => switch (block.kind) {
    BusyBlockKind.unorderedListItem ||
    BusyBlockKind.orderedListItem ||
    BusyBlockKind.taskListItem => true,
    _ => false,
  };

  void _setActiveBlock(String blockId) {
    _activeBlockId = blockId;
    _scheduleSessionReport();
  }

  KeyEventResult _handleDocumentSelectionKeyEvent(
    FocusNode node,
    KeyEvent event,
  ) {
    final blockId = _documentSelection?.extent.blockId ?? _activeBlockId;
    return blockId == null
        ? KeyEventResult.ignored
        : _handleBlockKeyEvent(blockId, event);
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

  void _recordUndoSnapshot([BusyDocument? previousDocument]) {
    final snapshot = previousDocument ?? _historySnapshot();
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
    final selectedDocumentText = _documentSelection;
    if (selectedDocumentText != null &&
        selectedDocumentText.extent.blockId == blockId) {
      final oldText = _documentController.blockText(blockId);
      final replacement = _replacementTextForFieldEdit(oldText, value);
      if (_replaceDocumentSelectionWithText(replacement)) {
        return;
      }
    }
    _clearBlockSelection();
    _setActiveBlock(blockId);
    if (_documentController.blockText(blockId) == value) {
      return;
    }
    _recordUndoSnapshot();
    final currentBlock = _documentController.blockById(blockId);
    if (currentBlock != null &&
        busyMarkWysiwygBlockContainsMath(currentBlock)) {
      _documentController.updateMathSource(blockId, value);
      _emitMarkdown();
      return;
    }
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

  String _replacementTextForFieldEdit(String oldText, String newText) {
    var prefixLength = 0;
    final shortestLength = math.min(oldText.length, newText.length);
    while (prefixLength < shortestLength &&
        oldText.codeUnitAt(prefixLength) == newText.codeUnitAt(prefixLength)) {
      prefixLength++;
    }
    var oldSuffixStart = oldText.length;
    var newSuffixStart = newText.length;
    while (oldSuffixStart > prefixLength &&
        newSuffixStart > prefixLength &&
        oldText.codeUnitAt(oldSuffixStart - 1) ==
            newText.codeUnitAt(newSuffixStart - 1)) {
      oldSuffixStart--;
      newSuffixStart--;
    }
    return newText.substring(prefixLength, newSuffixStart);
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

  void _handleTableColumnAlignmentChanged(
    String tableBlockId,
    int columnIndex,
    BusyTableAlignment alignment,
  ) {
    _clearBlockSelection();
    _setActiveBlock(tableBlockId);
    _recordUndoSnapshot();
    _documentController.setTableColumnAlignment(
      tableBlockId,
      columnIndex,
      alignment,
    );
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
      if (!mounted) {
        return;
      }
      final firstPlainBlock = _focusableBlocks()
          .where((block) => !busyMarkWysiwygBlockContainsMath(block))
          .firstOrNull;
      if (firstPlainBlock == null) {
        return;
      }
      _activeBlockId = firstPlainBlock.id;
      _focusActiveOrFirstBlock(initialSelectionOffset: 0);
    });
  }

  void _scheduleSessionRestore(WysiwygEditorSessionState session) {
    if (session.activeBlockId == null &&
        session.anchorBlockId == null &&
        session.viewportBlockId == null) {
      _scheduleInitialFocus();
      return;
    }
    _initialFocusScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final activeBlock = session.activeBlockId == null
          ? null
          : _documentController.blockById(session.activeBlockId!);
      _activeBlockId = activeBlock?.id ?? _focusableBlocks().firstOrNull?.id;
      final anchorBlockId = session.anchorBlockId;
      final extentBlockId = session.extentBlockId;
      if (anchorBlockId != null && extentBlockId != null) {
        final anchor = _documentController.blockById(anchorBlockId);
        final extent = _documentController.blockById(extentBlockId);
        if (anchor != null && extent != null) {
          if (anchorBlockId == extentBlockId) {
            final controller = _textControllers[anchorBlockId];
            if (controller != null) {
              controller.selection = TextSelection(
                baseOffset: session.anchorOffset
                    .clamp(0, controller.text.length)
                    .toInt(),
                extentOffset: session.extentOffset
                    .clamp(0, controller.text.length)
                    .toInt(),
              );
            }
          } else {
            _documentSelection = _DocumentTextSelection(
              anchor: _DocumentTextPosition(
                blockId: anchorBlockId,
                offset: session.anchorOffset
                    .clamp(0, anchor.plainText.length)
                    .toInt(),
              ),
              extent: _DocumentTextPosition(
                blockId: extentBlockId,
                offset: session.extentOffset
                    .clamp(0, extent.plainText.length)
                    .toInt(),
              ),
            );
          }
        }
      }
      final viewportBlockId = session.viewportBlockId;
      if (viewportBlockId != null) {
        _jumpToBlock(
          viewportBlockId,
          alignment: session.viewportAlignment.clamp(0.0, 1.0),
        );
      }
      _focusActiveOrFirstBlock();
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _scheduleSessionReport() {
    if (_sessionReportScheduled || widget.onSessionChanged == null) {
      return;
    }
    _sessionReportScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sessionReportScheduled = false;
      if (mounted) {
        _reportSessionNow();
      }
    });
  }

  void _reportSessionNow({
    BusyMarkWysiwygSessionChanged? callback,
    String? documentId,
  }) {
    final report = callback ?? widget.onSessionChanged;
    if (report == null) {
      return;
    }
    String? anchorBlockId;
    String? extentBlockId;
    var anchorOffset = 0;
    var extentOffset = 0;
    final documentSelection = _documentSelection;
    if (documentSelection != null) {
      anchorBlockId = documentSelection.anchor.blockId;
      anchorOffset = documentSelection.anchor.offset;
      extentBlockId = documentSelection.extent.blockId;
      extentOffset = documentSelection.extent.offset;
    } else if (_activeBlockId case final blockId?) {
      final selection = _textControllers[blockId]?.selection;
      if (selection != null && selection.isValid) {
        anchorBlockId = blockId;
        anchorOffset = selection.baseOffset;
        extentBlockId = blockId;
        extentOffset = selection.extentOffset;
      }
    }
    String? viewportBlockId;
    var viewportAlignment = 0.0;
    final positions =
        _itemPositionsListener.itemPositions.value
            .where(
              (position) =>
                  position.itemTrailingEdge > 0 && position.itemLeadingEdge < 1,
            )
            .toList()
          ..sort((left, right) => left.index.compareTo(right.index));
    if (positions.isNotEmpty &&
        positions.first.index < _viewportBlockIds.length) {
      viewportBlockId = _viewportBlockIds[positions.first.index];
      viewportAlignment = positions.first.itemLeadingEdge.clamp(0.0, 1.0);
    }
    report(
      documentId ?? _documentId,
      WysiwygEditorSessionState(
        activeBlockId: _activeBlockId,
        anchorBlockId: anchorBlockId,
        anchorOffset: anchorOffset,
        extentBlockId: extentBlockId,
        extentOffset: extentOffset,
        viewportBlockId: viewportBlockId,
        viewportAlignment: viewportAlignment,
      ),
    );
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
      _jumpToBlockAndAlign(heading.id, alignment: 0);
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
      _jumpToBlockAndAlign(target.id, alignment: 0.04);
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

  bool _ensureBlockVisible(String blockId, {required double alignment}) {
    final targetContext = _blockKeys[blockId]?.currentContext;
    if (targetContext == null) {
      return false;
    }
    Scrollable.ensureVisible(
      targetContext,
      duration: BusyMarkMotion.scroll,
      curve: Curves.easeOutCubic,
      alignment: alignment,
    );
    return true;
  }

  void _jumpToBlockAndAlign(String blockId, {required double alignment}) {
    final request = widget.scrollRequest;
    if (!_jumpToBlock(blockId, alignment: alignment)) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.scrollRequest == request) {
        _ensureBlockVisible(blockId, alignment: alignment);
      }
    });
  }

  bool _jumpToBlock(String blockId, {required double alignment}) {
    if (!_itemScrollController.isAttached) {
      return false;
    }
    final entries = _editorRenderEntries(_documentController.document.blocks);
    final index = entries.indexWhere(
      (entry) => _renderEntryContainsBlock(entry, blockId),
    );
    if (index < 0) {
      return false;
    }
    _itemScrollController.jumpTo(index: index, alignment: alignment);
    return true;
  }

  bool _renderEntryContainsBlock(_EditorRenderEntry entry, String blockId) {
    if (entry.block.id == blockId) {
      return true;
    }
    return entry.children?.any(
          (child) => _renderEntryContainsBlock(child, blockId),
        ) ??
        false;
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
    final commands =
        BusyMarkCommandRegistryScope.read(context) ??
        BusyMarkCommandCatalog.metadata;
    if ((event is KeyDownEvent || event is KeyRepeatEvent) &&
        key == LogicalKeyboardKey.tab &&
        !_hasCommandModifierPressed()) {
      _activeBlockId = blockId;
      final block = _documentController.blockById(blockId);
      if (block != null && _isListItemBlock(block)) {
        if (keyboard.isShiftPressed) {
          _applyOutdentCommand();
        } else {
          _applyIndentCommand();
        }
        return KeyEventResult.handled;
      }
    }
    if ((event is KeyDownEvent || event is KeyRepeatEvent) &&
        commands.shortcutAccepts(
          BusyMarkCommandIds.textInsertIndentation,
          event,
          keyboard,
        )) {
      _activeBlockId = blockId;
      return _insertTabIntoBlock(blockId)
          ? KeyEventResult.handled
          : KeyEventResult.ignored;
    }
    final isRepeatedArrowKey =
        event is KeyRepeatEvent &&
        (key == LogicalKeyboardKey.arrowUp ||
            key == LogicalKeyboardKey.arrowDown ||
            key == LogicalKeyboardKey.arrowLeft ||
            key == LogicalKeyboardKey.arrowRight);
    if (event is! KeyDownEvent && !isRepeatedArrowKey) {
      return KeyEventResult.ignored;
    }
    _activeBlockId = blockId;
    if (commands.shortcutAccepts(
      BusyMarkCommandIds.textSelectAll,
      event,
      keyboard,
    )) {
      _selectAllForBlock(blockId);
      return KeyEventResult.handled;
    }
    if (commands.shortcutAccepts(
          BusyMarkCommandIds.textCopy,
          event,
          keyboard,
        ) &&
        _copyCurrentSelection()) {
      return KeyEventResult.handled;
    }
    if (commands.shortcutAccepts(BusyMarkCommandIds.textCut, event, keyboard) &&
        _cutCurrentSelection()) {
      return KeyEventResult.handled;
    }
    if (commands.shortcutAccepts(
      BusyMarkCommandIds.textPaste,
      event,
      keyboard,
    )) {
      unawaited(_pasteIntoActiveBlock());
      return KeyEventResult.handled;
    }
    if (commands.shortcutAccepts(
      BusyMarkCommandIds.textRedo,
      event,
      keyboard,
    )) {
      if (widget.useExternalUndoHistory || !_redoEditorChange()) {
        widget.onRedo?.call();
      }
      return KeyEventResult.handled;
    }
    if (commands.shortcutAccepts(
      BusyMarkCommandIds.textUndo,
      event,
      keyboard,
    )) {
      if (widget.useExternalUndoHistory || !_undoEditorChange()) {
        widget.onUndo?.call();
      }
      return KeyEventResult.handled;
    }
    if (commands.shortcutAccepts(BusyMarkCommandIds.search, event, keyboard)) {
      widget.onOpenSearch?.call();
      return KeyEventResult.handled;
    }
    if (commands.shortcutAccepts(
      BusyMarkCommandIds.textEscape,
      event,
      keyboard,
    )) {
      widget.onCloseSearch?.call();
      return KeyEventResult.handled;
    }
    final commandId = commands.matchingCommandId(
      event,
      keyboard,
      scope: BusyMarkCommandScope.editor,
    );
    final shortcutAction = commandId == null
        ? null
        : BusyMarkEditorShortcutAction.values
              .where((action) => commandId == 'editor.${action.name}')
              .firstOrNull;
    if (shortcutAction != null) {
      if (shortcutAction == BusyMarkEditorShortcutAction.refineWithAi &&
          (widget.onAiEdit == null || _currentSelectionRanges().isEmpty)) {
        return KeyEventResult.ignored;
      }
      _applyEditorShortcutAction(shortcutAction);
      return KeyEventResult.handled;
    }
    if (keyboard.isControlPressed &&
        !keyboard.isAltPressed &&
        !keyboard.isMetaPressed &&
        (key == LogicalKeyboardKey.arrowLeft ||
            key == LogicalKeyboardKey.arrowRight)) {
      final boundaryResult = keyboard.isShiftPressed
          ? _extendKeyboardSelectionByWord(blockId, key)
          : _moveWordCaretAcrossBlockBoundary(blockId, key);
      if (boundaryResult == KeyEventResult.handled) {
        return boundaryResult;
      }
    }
    if (_hasCommandModifierPressed()) {
      return KeyEventResult.ignored;
    }
    if ((key == LogicalKeyboardKey.backspace ||
            key == LogicalKeyboardKey.delete) &&
        _deleteBlockSelection()) {
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter &&
        _hasBlockSelection &&
        _replaceDocumentSelectionWithText('\n')) {
      return KeyEventResult.handled;
    }
    final controller = _textControllers[blockId];
    if (controller == null || !controller.selection.isValid) {
      return KeyEventResult.ignored;
    }
    final selection = controller.selection;
    final shiftPressed = HardwareKeyboard.instance.isShiftPressed;
    final isArrowKey =
        key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight;
    final isVerticalArrow =
        key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown;
    if (!isVerticalArrow) {
      _resetVerticalCaretMovement();
    }
    if (shiftPressed && isArrowKey) {
      return _extendKeyboardSelection(blockId, key);
    }
    if (!shiftPressed && isArrowKey && _hasBlockSelection) {
      return _collapseDocumentSelectionForArrow(key);
    }
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
    if (key == LogicalKeyboardKey.arrowUp) {
      return _moveCaretVertically(blockId, -1);
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      return _moveCaretVertically(blockId, 1);
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

  KeyEventResult _moveWordCaretAcrossBlockBoundary(
    String blockId,
    LogicalKeyboardKey key,
  ) {
    if (_hasBlockSelection) {
      return KeyEventResult.ignored;
    }
    final controller = _textControllers[blockId];
    final selection = controller?.selection;
    if (controller == null ||
        selection == null ||
        !selection.isValid ||
        !selection.isCollapsed) {
      return KeyEventResult.ignored;
    }
    final position = _DocumentTextPosition(
      blockId: blockId,
      offset: selection.extentOffset.clamp(0, controller.text.length).toInt(),
      affinity: selection.affinity,
    );
    final target = _horizontalCaretTarget(position, key);
    if (target == null || target.blockId == blockId) {
      return KeyEventResult.ignored;
    }
    _resetVerticalCaretMovement();
    _applyKeyboardSelection(
      _DocumentTextSelection(anchor: target, extent: target),
    );
    return KeyEventResult.handled;
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

  KeyEventResult _extendKeyboardSelection(
    String blockId,
    LogicalKeyboardKey key,
  ) {
    final selection = _keyboardSelectionFor(blockId);
    if (selection == null) {
      return KeyEventResult.ignored;
    }
    final extent = selection.extent;
    final _DocumentTextPosition? target;
    if (key == LogicalKeyboardKey.arrowUp) {
      target = _verticalCaretTarget(extent, -1);
    } else if (key == LogicalKeyboardKey.arrowDown) {
      target = _verticalCaretTarget(extent, 1);
    } else if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight) {
      target = _horizontalCaretTarget(extent, key);
    } else {
      target = null;
    }
    if (target == null) {
      return KeyEventResult.handled;
    }
    _applyKeyboardSelection(
      _DocumentTextSelection(anchor: selection.anchor, extent: target),
    );
    return KeyEventResult.handled;
  }

  KeyEventResult _extendKeyboardSelectionByWord(
    String blockId,
    LogicalKeyboardKey key,
  ) {
    final selection = _keyboardSelectionFor(blockId);
    if (selection == null) {
      return KeyEventResult.ignored;
    }
    final target = _wordCaretTarget(selection.extent, key);
    if (target == null) {
      return KeyEventResult.ignored;
    }
    _resetVerticalCaretMovement();
    _applyKeyboardSelection(
      _DocumentTextSelection(anchor: selection.anchor, extent: target),
    );
    return KeyEventResult.handled;
  }

  _DocumentTextSelection? _keyboardSelectionFor(String fallbackBlockId) {
    final documentSelection = _documentSelection;
    if (documentSelection != null) {
      return documentSelection;
    }
    final controller = _textControllers[fallbackBlockId];
    final selection = controller?.selection;
    if (controller == null || selection == null || !selection.isValid) {
      return null;
    }
    return _DocumentTextSelection(
      anchor: _DocumentTextPosition(
        blockId: fallbackBlockId,
        offset: selection.baseOffset.clamp(0, controller.text.length).toInt(),
      ),
      extent: _DocumentTextPosition(
        blockId: fallbackBlockId,
        offset: selection.extentOffset.clamp(0, controller.text.length).toInt(),
        affinity: selection.affinity,
      ),
    );
  }

  _DocumentTextPosition? _horizontalCaretTarget(
    _DocumentTextPosition position,
    LogicalKeyboardKey key,
  ) {
    final block = _documentController.blockById(position.blockId);
    final controller = _textControllers[position.blockId];
    if (block == null || controller == null) {
      return null;
    }
    final textDirection = busyMarkWysiwygBlockTextDirection(
      block,
      fallback: Directionality.of(context),
    );
    final forwardKey = textDirection == TextDirection.rtl
        ? LogicalKeyboardKey.arrowLeft
        : LogicalKeyboardKey.arrowRight;
    final forward = key == forwardKey;
    final offset = position.offset.clamp(0, controller.text.length).toInt();
    final boundary = CharacterBoundary(controller.text);
    if (forward && offset < controller.text.length) {
      return _DocumentTextPosition(
        blockId: position.blockId,
        offset:
            boundary.getTrailingTextBoundaryAt(offset) ??
            controller.text.length,
      );
    }
    if (!forward && offset > 0) {
      return _DocumentTextPosition(
        blockId: position.blockId,
        offset: boundary.getLeadingTextBoundaryAt(offset - 1) ?? 0,
      );
    }
    final nextBlock = _relativeFocusableBlock(
      position.blockId,
      forward ? 1 : -1,
    );
    if (nextBlock == null) {
      return position;
    }
    final nextController = _textControllerFor(nextBlock);
    return _DocumentTextPosition(
      blockId: nextBlock.id,
      offset: forward ? 0 : nextController.text.length,
    );
  }

  _DocumentTextPosition? _wordCaretTarget(
    _DocumentTextPosition position,
    LogicalKeyboardKey key,
  ) {
    final block = _documentController.blockById(position.blockId);
    final controller = _textControllers[position.blockId];
    if (block == null || controller == null) {
      return null;
    }
    final textDirection = busyMarkWysiwygBlockTextDirection(
      block,
      fallback: Directionality.of(context),
    );
    final forwardKey = textDirection == TextDirection.rtl
        ? LogicalKeyboardKey.arrowLeft
        : LogicalKeyboardKey.arrowRight;
    final forward = key == forwardKey;
    final offset = position.offset.clamp(0, controller.text.length).toInt();
    if ((forward && offset < controller.text.length) ||
        (!forward && offset > 0)) {
      final wordBoundary = _renderEditableForBlock(
        position.blockId,
      )?.wordBoundaries.moveByWordBoundary;
      if (wordBoundary == null) {
        return null;
      }
      return _DocumentTextPosition(
        blockId: position.blockId,
        offset: forward
            ? wordBoundary.getTrailingTextBoundaryAt(offset) ??
                  controller.text.length
            : wordBoundary.getLeadingTextBoundaryAt(offset - 1) ?? 0,
      );
    }
    final nextBlock = _relativeFocusableBlock(
      position.blockId,
      forward ? 1 : -1,
    );
    if (nextBlock == null) {
      return position;
    }
    final nextController = _textControllerFor(nextBlock);
    return _DocumentTextPosition(
      blockId: nextBlock.id,
      offset: forward ? 0 : nextController.text.length,
    );
  }

  KeyEventResult _moveCaretVertically(String blockId, int direction) {
    final controller = _textControllers[blockId];
    final selection = controller?.selection;
    if (controller == null || selection == null || !selection.isValid) {
      return KeyEventResult.ignored;
    }
    final target = _verticalCaretTarget(
      _DocumentTextPosition(
        blockId: blockId,
        offset: selection.extentOffset.clamp(0, controller.text.length).toInt(),
        affinity: selection.affinity,
      ),
      direction,
    );
    if (target == null) {
      return KeyEventResult.ignored;
    }
    _applyKeyboardSelection(
      _DocumentTextSelection(anchor: target, extent: target),
    );
    return KeyEventResult.handled;
  }

  _DocumentTextPosition? _verticalCaretTarget(
    _DocumentTextPosition position,
    int direction,
  ) {
    final controller = _textControllers[position.blockId];
    if (controller == null) {
      return null;
    }
    final currentPosition = TextPosition(
      offset: position.offset.clamp(0, controller.text.length).toInt(),
      affinity: position.affinity,
    );
    final renderEditable = _renderEditableForBlock(position.blockId);
    if (renderEditable != null && renderEditable.hasSize) {
      final runMatches =
          _verticalCaretMovementBlockId == position.blockId &&
          _verticalCaretMovementPosition == currentPosition &&
          (_verticalCaretMovement?.isValid ?? false);
      if (!runMatches) {
        _verticalCaretMovement = renderEditable.startVerticalCaretMovement(
          currentPosition,
        );
        _verticalCaretMovementBlockId = position.blockId;
        _verticalCaretMovementPosition = currentPosition;
        final caret = renderEditable.getLocalRectForCaret(currentPosition);
        _preferredVerticalCaretX = renderEditable
            .localToGlobal(caret.topLeft)
            .dx;
      }
      final run = _verticalCaretMovement!;
      final moved = direction < 0 ? run.movePrevious() : run.moveNext();
      if (moved) {
        final target = run.current;
        _verticalCaretMovementPosition = target;
        return _DocumentTextPosition(
          blockId: position.blockId,
          offset: target.offset,
          affinity: target.affinity,
        );
      }
    }

    final nextBlock = _relativeFocusableBlock(position.blockId, direction);
    if (nextBlock == null) {
      final boundaryOffset = direction < 0 ? 0 : controller.text.length;
      final target = _DocumentTextPosition(
        blockId: position.blockId,
        offset: boundaryOffset,
      );
      _verticalCaretMovementPosition = TextPosition(offset: boundaryOffset);
      return target;
    }
    final nextController = _textControllerFor(nextBlock);
    final nextRenderEditable = _renderEditableForBlock(nextBlock.id);
    var targetPosition = TextPosition(
      offset: position.offset.clamp(0, nextController.text.length).toInt(),
    );
    if (nextRenderEditable != null && nextRenderEditable.hasSize) {
      final edgePosition = TextPosition(
        offset: direction < 0 ? nextController.text.length : 0,
        affinity: direction < 0
            ? TextAffinity.upstream
            : TextAffinity.downstream,
      );
      final edgeCaret = nextRenderEditable.getLocalRectForCaret(edgePosition);
      final edgeGlobal = nextRenderEditable.localToGlobal(edgeCaret.center);
      targetPosition = nextRenderEditable.getPositionForPoint(
        Offset(_preferredVerticalCaretX ?? edgeGlobal.dx, edgeGlobal.dy),
      );
      _verticalCaretMovement = nextRenderEditable.startVerticalCaretMovement(
        targetPosition,
      );
    } else {
      _verticalCaretMovement = null;
    }
    _verticalCaretMovementBlockId = nextBlock.id;
    _verticalCaretMovementPosition = targetPosition;
    return _DocumentTextPosition(
      blockId: nextBlock.id,
      offset: targetPosition.offset
          .clamp(0, nextController.text.length)
          .toInt(),
      affinity: targetPosition.affinity,
    );
  }

  BusyBlock? _relativeFocusableBlock(String blockId, int direction) {
    final blocks = _focusableBlocks();
    final index = blocks.indexWhere((block) => block.id == blockId);
    if (index == -1) {
      return null;
    }
    final targetIndex = index + direction;
    return targetIndex < 0 || targetIndex >= blocks.length
        ? null
        : blocks[targetIndex];
  }

  RenderEditable? _renderEditableForBlock(String blockId) {
    final renderObject = _blockKeys[blockId]?.currentContext
        ?.findRenderObject();
    return renderObject == null ? null : _findRenderEditable(renderObject);
  }

  RenderEditable? _findRenderEditable(RenderObject renderObject) {
    if (renderObject is RenderEditable) {
      return renderObject;
    }
    RenderEditable? result;
    renderObject.visitChildren((child) {
      result ??= _findRenderEditable(child);
    });
    return result;
  }

  void _applyKeyboardSelection(_DocumentTextSelection selection) {
    final anchor = _clampDocumentPosition(selection.anchor);
    final extent = _clampDocumentPosition(selection.extent);
    if (anchor == null || extent == null) {
      return;
    }
    final nextSelection = _DocumentTextSelection(
      anchor: anchor,
      extent: extent,
    );
    final extentBlock = _documentController.blockById(extent.blockId);
    if (extentBlock == null) {
      return;
    }
    final controller = _textControllerFor(extentBlock);
    final focusNode = _focusNodeFor(extentBlock);
    _activeBlockId = extent.blockId;
    if (anchor.blockId == extent.blockId) {
      if (_documentSelection != null) {
        setState(() => _documentSelection = null);
      }
      focusNode.requestFocus();
      controller.selection = TextSelection(
        baseOffset: anchor.offset,
        extentOffset: extent.offset,
        affinity: extent.affinity,
      );
      _collapseInactiveFieldSelections(extent.blockId);
      return;
    }
    setState(() => _documentSelection = nextSelection);
    if (!_selectionFocusNode.hasPrimaryFocus) {
      focusNode.requestFocus();
    }
    controller.selection = TextSelection.collapsed(
      offset: extent.offset,
      affinity: extent.affinity,
    );
    _collapseInactiveFieldSelections(extent.blockId);
  }

  _DocumentTextPosition? _clampDocumentPosition(
    _DocumentTextPosition position,
  ) {
    final controller = _textControllers[position.blockId];
    if (controller == null) {
      return null;
    }
    return _DocumentTextPosition(
      blockId: position.blockId,
      offset: position.offset.clamp(0, controller.text.length).toInt(),
      affinity: position.affinity,
    );
  }

  KeyEventResult _collapseDocumentSelectionForArrow(LogicalKeyboardKey key) {
    final selection = _documentSelection;
    if (selection == null) {
      return KeyEventResult.ignored;
    }
    final ordered = _orderedDocumentSelection(selection);
    if (ordered == null) {
      return KeyEventResult.ignored;
    }
    final extentBlock = _documentController.blockById(selection.extent.blockId);
    if (extentBlock == null) {
      return KeyEventResult.ignored;
    }
    final textDirection = busyMarkWysiwygBlockTextDirection(
      extentBlock,
      fallback: Directionality.of(context),
    );
    final towardStartKey = textDirection == TextDirection.rtl
        ? LogicalKeyboardKey.arrowRight
        : LogicalKeyboardKey.arrowLeft;
    final towardStart =
        key == LogicalKeyboardKey.arrowUp || key == towardStartKey;
    final target = towardStart ? ordered.start : ordered.end;
    _resetVerticalCaretMovement();
    _applyKeyboardSelection(
      _DocumentTextSelection(anchor: target, extent: target),
    );
    return KeyEventResult.handled;
  }

  _OrderedDocumentSelection? _orderedDocumentSelection(
    _DocumentTextSelection selection,
  ) {
    final blocks = _focusableBlocks();
    final anchorIndex = blocks.indexWhere(
      (block) => block.id == selection.anchor.blockId,
    );
    final extentIndex = blocks.indexWhere(
      (block) => block.id == selection.extent.blockId,
    );
    if (anchorIndex == -1 || extentIndex == -1) {
      return null;
    }
    final anchorFirst =
        anchorIndex < extentIndex ||
        (anchorIndex == extentIndex &&
            selection.anchor.offset <= selection.extent.offset);
    return _OrderedDocumentSelection(
      start: anchorFirst ? selection.anchor : selection.extent,
      end: anchorFirst ? selection.extent : selection.anchor,
    );
  }

  void _resetVerticalCaretMovement() {
    _verticalCaretMovement = null;
    _verticalCaretMovementBlockId = null;
    _verticalCaretMovementPosition = null;
    _preferredVerticalCaretX = null;
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
    final activeBlock = _activeBlockId == null
        ? null
        : _documentController.blockById(_activeBlockId!);
    final commandTargets = selectedBlocks.isNotEmpty
        ? selectedBlocks
        : [if (activeBlock != null) activeBlock];
    if (command == BusyWysiwygBlockCommand.codeBlock &&
        commandTargets.isNotEmpty &&
        commandTargets.every(
          (block) => block.kind == BusyBlockKind.codeBlock,
        )) {
      unawaited(_applyCodeLanguageCommand());
      return;
    }
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
      case BusyMarkEditorShortcutAction.refineWithAi:
        unawaited(_runAiEdit());
        break;
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

  bool _canApplyContextCommand(String commandId) {
    if (commandId.startsWith('editor.')) {
      final name = commandId.substring('editor.'.length);
      return BusyMarkEditorShortcutAction.values.any(
        (action) => action.name == name,
      );
    }
    return switch (commandId) {
      BusyMarkCommandIds.textSelectAll ||
      BusyMarkCommandIds.textCut ||
      BusyMarkCommandIds.textCopy ||
      BusyMarkCommandIds.textPaste ||
      'text.pastePlainText' ||
      'text.undo' ||
      'text.redo' => true,
      _ => false,
    };
  }

  void _applyContextCommand(String commandId) {
    if (commandId.startsWith('editor.')) {
      final name = commandId.substring('editor.'.length);
      final action = BusyMarkEditorShortcutAction.values
          .where((candidate) => candidate.name == name)
          .firstOrNull;
      if (action != null) {
        _applyEditorShortcutAction(action);
      }
      return;
    }
    switch (commandId) {
      case BusyMarkCommandIds.textSelectAll:
        _selectAllForActiveBlock();
      case BusyMarkCommandIds.textCut:
        _cutCurrentSelection();
      case BusyMarkCommandIds.textCopy:
        _copyCurrentSelection();
      case BusyMarkCommandIds.textPaste:
        unawaited(_pasteIntoActiveBlock());
      case 'text.pastePlainText':
        unawaited(_pastePlainTextIntoActiveBlock());
      case 'text.undo':
        if (widget.useExternalUndoHistory || !_undoEditorChange()) {
          widget.onUndo?.call();
        }
      case 'text.redo':
        if (widget.useExternalUndoHistory || !_redoEditorChange()) {
          widget.onRedo?.call();
        }
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

  void _applyInlineMathCommand() {
    final blockId = _activeBlockId;
    final controller = blockId == null ? null : _textControllers[blockId];
    if (blockId == null || controller == null) {
      return;
    }
    final selection = controller.selection.isValid
        ? controller.selection
        : TextSelection.collapsed(offset: controller.text.length);
    final start = math.min(selection.start, selection.end);
    final end = math.max(selection.start, selection.end);
    final selected = controller.text.substring(start, end);
    final expression = selected.isEmpty ? 'x' : selected;
    final currentBlock = _documentController.blockById(blockId);
    if (currentBlock != null &&
        !busyMarkWysiwygBlockContainsMath(currentBlock)) {
      _recordUndoSnapshot();
      final insertion = _documentController.insertInlineMath(
        blockId,
        start,
        end,
        fallbackExpression: expression,
      );
      if (insertion == null) {
        return;
      }
      _emitMarkdown();
      _focusBlockAfterFrame(blockId, offset: insertion.selectionEnd);
      return;
    }
    final insertion = '\$$expression\$';
    final nextText = controller.text.replaceRange(start, end, insertion);
    _recordUndoSnapshot();
    controller.value = TextEditingValue(
      text: nextText,
      selection: TextSelection(
        baseOffset: start + 1,
        extentOffset: start + 1 + expression.length,
      ),
    );
    _documentController.updateMathSource(blockId, nextText);
    _emitMarkdown();
    _focusBlockAfterFrame(blockId, offset: start + 1 + expression.length);
  }

  void _applyDisplayMathCommand() {
    final blockId = _activeBlockId;
    if (blockId == null) {
      return;
    }
    _recordUndoSnapshot();
    final mathId = _documentController.insertDisplayMathAfter(blockId);
    if (mathId == null) {
      return;
    }
    _emitMarkdown();
    _focusBlockAfterFrame(mathId, offset: 4);
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
    if (text != null && text.isNotEmpty) {
      final internalClipboard = _internalClipboard;
      if (internalClipboard != null &&
          internalClipboard.text == text &&
          _pasteInternalClipboardIntoActiveBlock(internalClipboard)) {
        return;
      }
      final filePath = _localFilePathFromClipboardText(text);
      if (filePath != null &&
          await _ingestExternalImageFile(
            filePath,
            AssetIngestionOrigin.clipboardImageFile,
            reportInvalidImage: false,
          )) {
        return;
      }
      await _pastePlainTextIntoActiveBlock(textOverride: text);
      return;
    }
    final assetInput = widget.assetInputService ?? busyMarkAssetInputService;
    final clipboardFiles = await assetInput.readClipboardImageFiles();
    if (clipboardFiles.isNotEmpty &&
        await _ingestExternalImageFile(
          clipboardFiles.first,
          AssetIngestionOrigin.clipboardImageFile,
        )) {
      return;
    }
    final png = await assetInput.readClipboardImagePng();
    if (png != null && png.isNotEmpty) {
      await _ingestExternalImageBytes(
        png,
        suggestedFileName:
            'screenshot-${DateTime.now().millisecondsSinceEpoch}.png',
        origin: AssetIngestionOrigin.screenshotPaste,
      );
    }
  }

  bool _pasteInternalClipboardIntoActiveBlock(
    _WysiwygInternalClipboard clipboard,
  ) {
    if (_hasBlockSelection) {
      return _replaceDocumentSelectionWithStyledBlocks(clipboard.blocks);
    }
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
    if (_hasBlockSelection && _replaceDocumentSelectionWithText(text)) {
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
    if (_hasBlockSelection) {
      return _replaceDocumentSelectionWithText('\t');
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

  bool _applyIndentCommand() {
    final blockIds = _commandTargetBlockIds();
    if (blockIds.isEmpty) {
      return false;
    }
    final undoSnapshot = _historySnapshot();
    if (!_documentController.indentListItems(blockIds)) {
      return false;
    }
    _recordUndoSnapshot(undoSnapshot);
    _clearBlockSelection();
    _emitMarkdown();
    return true;
  }

  bool _applyOutdentCommand() {
    final blockIds = _commandTargetBlockIds();
    if (blockIds.isEmpty) {
      return false;
    }
    final undoSnapshot = _historySnapshot();
    if (!_documentController.outdentListItems(blockIds)) {
      return false;
    }
    _recordUndoSnapshot(undoSnapshot);
    _clearBlockSelection();
    _emitMarkdown();
    return true;
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

  void _handleTaskCheckedChanged(String blockId, bool checked) {
    final block = _documentController.blockById(blockId);
    if (block == null ||
        block.kind != BusyBlockKind.taskListItem ||
        (block.attributes['task'] == 'true') == checked) {
      return;
    }
    _handleBlockFocused(blockId);
    _recordUndoSnapshot();
    _documentController.toggleTaskChecked([blockId]);
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
        ingestSelectedImage: _ingestSelectedImage,
        onSaveRequired: widget.onAssetSaveRequired,
      ),
    );
  }

  Future<String> _ingestSelectedImage(String sourcePath) async {
    final asset = await widget.assetIngestionService.ingestFile(
      sourcePath: sourcePath,
      request: _assetIngestionRequest,
      origin: AssetIngestionOrigin.imagePicker,
    );
    return asset.markdownPath;
  }

  AssetIngestionRequest get _assetIngestionRequest => AssetIngestionRequest(
    documentFilePath: _documentController.document.filePath,
    workspaceKind:
        widget.assetWorkspaceKind ??
        (widget.writersideRoot != null
            ? AssetWorkspaceKind.writerside
            : widget.workspaceRoot != null
            ? AssetWorkspaceKind.markdownWorkspace
            : AssetWorkspaceKind.standalone),
    workspaceRoot: widget.workspaceRoot,
    writersideRoot: widget.writersideRoot,
    imagesDir: widget.imagesDir,
  );

  void _listenForDroppedAssets() {
    final input = widget.assetInputService ?? busyMarkAssetInputService;
    _assetDropSubscription = input.droppedFiles.listen((paths) {
      unawaited(_ingestDroppedAssetFiles(paths));
    });
  }

  Future<void> _ingestDroppedAssetFiles(List<String> paths) async {
    for (final path in paths) {
      if (!mounted) {
        return;
      }
      await _ingestExternalImageFile(path, AssetIngestionOrigin.dragAndDrop);
    }
  }

  String? _localFilePathFromClipboardText(String value) {
    final trimmed = value.trim();
    if (trimmed.contains('\n') || trimmed.contains('\r')) {
      return null;
    }
    final uri = Uri.tryParse(trimmed);
    final candidate = uri?.scheme == 'file' ? File.fromUri(uri!).path : trimmed;
    return File(candidate).existsSync() ? candidate : null;
  }

  Future<bool> _ingestExternalImageFile(
    String sourcePath,
    AssetIngestionOrigin origin, {
    bool reportInvalidImage = true,
  }) async {
    try {
      final asset = await widget.assetIngestionService.ingestFile(
        sourcePath: sourcePath,
        request: _assetIngestionRequest,
        origin: origin,
      );
      await _requestAltAndInsertAsset(
        asset,
        suggestedAlt: p.basenameWithoutExtension(sourcePath),
      );
      return true;
    } on AssetSaveRequiredException {
      widget.onAssetSaveRequired?.call();
      return true;
    } on AssetIngestionException catch (error) {
      if (reportInvalidImage && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
      return false;
    } on FileSystemException {
      return false;
    }
  }

  Future<bool> _ingestExternalImageBytes(
    Uint8List bytes, {
    required String suggestedFileName,
    required AssetIngestionOrigin origin,
  }) async {
    try {
      final asset = await widget.assetIngestionService.ingestBytes(
        bytes: bytes,
        suggestedFileName: suggestedFileName,
        request: _assetIngestionRequest,
        origin: origin,
      );
      await _requestAltAndInsertAsset(asset, suggestedAlt: 'Screenshot');
      return true;
    } on AssetSaveRequiredException {
      widget.onAssetSaveRequired?.call();
      return true;
    } on AssetIngestionException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
      return false;
    }
  }

  Future<void> _requestAltAndInsertAsset(
    IngestedAsset asset, {
    required String suggestedAlt,
  }) async {
    if (!mounted) {
      return;
    }
    final fallbackAltText = context.l10n.image;
    final target = _captureDialogTarget();
    final result = await _showImageDialog(
      context,
      title: context.l10n.image,
      initialSource: asset.markdownPath,
      initialAlt: suggestedAlt,
      submitLabel: context.l10n.insert,
    );
    if (!_isDialogTargetCurrent(target) || result == null) {
      if (!asset.reusedExisting) {
        try {
          await File(asset.absolutePath).delete();
        } on FileSystemException {
          // A cancelled dialog should not make the editor unusable.
        }
      }
      return;
    }
    final blockId = _activeBlockId;
    final controller = blockId == null ? null : _textControllers[blockId];
    if (blockId == null || controller == null) {
      return;
    }
    final selection = controller.selection.isValid
        ? controller.selection
        : TextSelection.collapsed(offset: controller.text.length);
    _recordUndoSnapshot();
    _documentController.insertInlineImage(
      blockId,
      selectionStart: selection.start,
      selectionEnd: selection.end,
      source: result.source,
      alt: result.alt,
      fallbackAltText: fallbackAltText,
    );
    _emitMarkdown();
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

  Future<void> _runAiEdit({String? blockId}) async {
    final callback = widget.onAiEdit;
    if (callback == null) {
      return;
    }
    if (blockId != null) {
      _setActiveBlock(blockId);
    }
    final originalSource = _documentController.markdown;
    if (_currentSelectionRanges().isEmpty) {
      return;
    }
    final snapshot = _aiEditorSnapshot(originalSource);
    if (snapshot == null) {
      return;
    }
    final result = await callback(snapshot);
    if (!mounted || result == null) {
      return;
    }
    if (_documentController.markdown != originalSource) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.aiStaleProposal)));
      return;
    }
    final invocation = result.invocation;
    final start = invocation.replacementStart;
    final end = invocation.replacementEnd;
    if (invocation.documentSource != originalSource ||
        start == null ||
        end == null ||
        start < 0 ||
        end < start ||
        end > originalSource.length) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.aiStaleProposal)));
      return;
    }
    final candidate = originalSource.replaceRange(
      start,
      end,
      result.replacement,
    );
    final parsed = const MarkdownParser().parse(
      filePath: _documentController.document.filePath,
      source: candidate,
      mode: _documentController.document.mode,
      validateLocalReferences: false,
    );
    _recordUndoSnapshot();
    _clearBlockSelection();
    _documentController.replaceDocument(parsed.busyDocument);
    _emitMarkdown();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusActiveOrFirstBlock();
      }
    });
  }

  AiEditorSnapshot? _aiEditorSnapshot(String source) {
    final activeBlockId = _activeBlockId;
    if (activeBlockId == null) {
      return null;
    }
    final liveBlocks = _editableBlocks(_documentController.document.blocks);
    final parsedDocument = const MarkdownParser()
        .parse(
          filePath: _documentController.document.filePath,
          source: source,
          mode: _documentController.document.mode,
          validateLocalReferences: false,
        )
        .busyDocument;
    final parsedBlocks = _editableBlocks(parsedDocument.blocks);
    final ranges = _currentSelectionRanges();
    if (ranges.isEmpty) {
      return null;
    }
    final parsedMatches = _matchAiSourceBlocks(
      liveBlocks: liveBlocks,
      parsedBlocks: parsedBlocks,
      parsedRoots: parsedDocument.blocks,
    );
    final firstMatch = parsedMatches[ranges.first.block.id];
    final lastMatch = parsedMatches[ranges.last.block.id];
    if (firstMatch == null || lastMatch == null) {
      return null;
    }
    for (final range in ranges) {
      if (parsedMatches[range.block.id] == null) {
        return null;
      }
    }

    late final int selectionStart;
    late final int selectionEnd;
    if (ranges.every((range) => range.coversWholeBlock)) {
      selectionStart = firstMatch.span.startOffset;
      selectionEnd = lastMatch.span.endOffset;
    } else {
      final mappedStart = _visibleOffsetToSource(
        source,
        firstMatch.block,
        ranges.first.start,
        sourceSpan: firstMatch.span,
        endBoundary: false,
        visibleText: ranges.first.block.plainText,
      );
      final mappedEnd = _visibleOffsetToSource(
        source,
        lastMatch.block,
        ranges.last.end,
        sourceSpan: lastMatch.span,
        endBoundary: true,
        visibleText: ranges.last.block.plainText,
      );
      if (mappedStart == null || mappedEnd == null || mappedEnd < mappedStart) {
        return null;
      }
      selectionStart = mappedStart;
      selectionEnd = mappedEnd;
    }

    final activeLiveBlock = liveBlocks
        .where((block) => block.id == activeBlockId)
        .firstOrNull;
    final activeMatch = parsedMatches[activeBlockId];
    final activeSelection = _textControllers[activeBlockId]?.selection;
    final mappedAnchor = activeLiveBlock == null || activeMatch == null
        ? null
        : _visibleOffsetToSource(
            source,
            activeMatch.block,
            activeSelection?.isValid == true
                ? activeSelection!.extentOffset
                      .clamp(0, activeLiveBlock.plainText.length)
                      .toInt()
                : ranges.last.end,
            sourceSpan: activeMatch.span,
            endBoundary: false,
            visibleText: activeLiveBlock.plainText,
          );
    return AiEditorSnapshot(
      documentSource: source,
      selectionStart: selectionStart,
      selectionEnd: selectionEnd,
      anchorOffset: mappedAnchor ?? selectionStart,
      sourceRevision: widget.visualizationRevision,
      targetId: _documentController.document.filePath,
      documentPath: _documentController.document.filePath,
    );
  }

  Map<String, ({BusyBlock block, SourceSpan span})> _matchAiSourceBlocks({
    required List<BusyBlock> liveBlocks,
    required List<BusyBlock> parsedBlocks,
    required List<BusyBlock> parsedRoots,
  }) {
    final matches = <String, ({BusyBlock block, SourceSpan span})>{};
    var parsedIndex = 0;
    for (final liveBlock in liveBlocks) {
      if (liveBlock.plainText.isEmpty) {
        continue;
      }
      var candidateIndex = parsedIndex;
      while (candidateIndex < parsedBlocks.length) {
        final parsedBlock = parsedBlocks[candidateIndex];
        if (parsedBlock.kind != liveBlock.kind ||
            parsedBlock.plainText != liveBlock.plainText) {
          candidateIndex += 1;
          continue;
        }
        final span =
            parsedBlock.sourceSpan ??
            _aiSourceSpanForBlock(parsedRoots, parsedBlock);
        if (span != null) {
          matches[liveBlock.id] = (block: parsedBlock, span: span);
        }
        parsedIndex = candidateIndex + 1;
        break;
      }
    }
    return matches;
  }

  SourceSpan? _aiSourceSpanForBlock(
    List<BusyBlock> blocks,
    BusyBlock target, [
    SourceSpan? inheritedSpan,
  ]) {
    for (final block in blocks) {
      final sourceSpan = block.sourceSpan ?? inheritedSpan;
      if (identical(block, target)) {
        return sourceSpan;
      }
      final childSpan = _aiSourceSpanForBlock(
        block.children,
        target,
        sourceSpan,
      );
      if (childSpan != null) {
        return childSpan;
      }
    }
    return null;
  }

  int? _visibleOffsetToSource(
    String source,
    BusyBlock block,
    int visibleOffset, {
    SourceSpan? sourceSpan,
    required bool endBoundary,
    String? visibleText,
  }) {
    final span = sourceSpan ?? block.sourceSpan;
    if (span == null ||
        span.startOffset < 0 ||
        span.endOffset > source.length) {
      return null;
    }
    final plainText = visibleText ?? block.plainText;
    final safeOffset = visibleOffset.clamp(0, plainText.length).toInt();
    if (plainText.isEmpty) {
      return span.startOffset;
    }
    final requiredCharacters = endBoundary
        ? safeOffset
        : math.min(plainText.length, safeOffset + 1);
    final raw = source.substring(span.startOffset, span.endOffset);
    final sourceStarts = <int>[];
    final sourceEnds = <int>[];
    var rawOffset = _aiBlockContentStart(raw);
    var textOffset = 0;
    while (textOffset < requiredCharacters) {
      final codeUnit = plainText.codeUnitAt(textOffset);
      if (_aiMappingWhitespace(codeUnit)) {
        final visibleRunStart = textOffset;
        while (textOffset < plainText.length &&
            _aiMappingWhitespace(plainText.codeUnitAt(textOffset))) {
          textOffset += 1;
        }
        final visibleRunLength = textOffset - visibleRunStart;
        int? rawRunStart;
        int? rawRunEnd;
        while (rawOffset < raw.length) {
          final breakEnd = _aiBreakTagEnd(raw, rawOffset);
          if (breakEnd != null) {
            rawRunStart = rawOffset;
            rawRunEnd = breakEnd;
            break;
          }
          if (_aiMappingWhitespace(raw.codeUnitAt(rawOffset))) {
            rawRunStart = rawOffset;
            while (rawOffset < raw.length &&
                _aiMappingWhitespace(raw.codeUnitAt(rawOffset))) {
              rawOffset += 1;
            }
            rawRunEnd = rawOffset;
            break;
          }
          final tagEnd = _aiMarkupTagEnd(raw, rawOffset);
          rawOffset = tagEnd ?? rawOffset + 1;
        }
        if (rawRunStart == null || rawRunEnd == null) {
          return null;
        }
        final rawRunLength = rawRunEnd - rawRunStart;
        for (var index = 0; index < visibleRunLength; index += 1) {
          if (rawRunLength == visibleRunLength) {
            sourceStarts.add(span.startOffset + rawRunStart + index);
            sourceEnds.add(span.startOffset + rawRunStart + index + 1);
          } else {
            sourceStarts.add(span.startOffset + rawRunStart);
            sourceEnds.add(span.startOffset + rawRunEnd);
          }
        }
        rawOffset = rawRunEnd;
        continue;
      }

      var matched = false;
      while (rawOffset < raw.length) {
        final tagEnd = _aiMarkupTagEnd(raw, rawOffset);
        if (tagEnd != null) {
          rawOffset = tagEnd;
          continue;
        }
        final entity = _aiEntityAt(raw, rawOffset);
        if (entity != null &&
            !plainText.startsWith(entity.raw, textOffset) &&
            plainText.startsWith(entity.decoded, textOffset)) {
          for (var index = 0; index < entity.decoded.length; index += 1) {
            sourceStarts.add(span.startOffset + rawOffset);
            sourceEnds.add(span.startOffset + entity.end);
          }
          textOffset += entity.decoded.length;
          rawOffset = entity.end;
          matched = true;
          break;
        }
        if (raw.codeUnitAt(rawOffset) == codeUnit) {
          sourceStarts.add(span.startOffset + rawOffset);
          rawOffset += 1;
          sourceEnds.add(span.startOffset + rawOffset);
          textOffset += 1;
          matched = true;
          break;
        }
        rawOffset += 1;
      }
      if (!matched) {
        return null;
      }
    }
    if (sourceStarts.isEmpty) {
      return span.startOffset;
    }
    if (safeOffset == 0) {
      return sourceStarts.first;
    }
    if (safeOffset >= sourceStarts.length) {
      return sourceEnds.last;
    }
    return endBoundary ? sourceEnds[safeOffset - 1] : sourceStarts[safeOffset];
  }

  int _aiBlockContentStart(String raw) {
    var offset = 0;
    final quotePrefix = RegExp(r'^(?:[ \t]{0,3}>[ \t]?)+').firstMatch(raw);
    if (quotePrefix != null) {
      offset = quotePrefix.end;
    }
    final remainder = raw.substring(offset);
    final structuralPrefix = RegExp(
      r'^(?:[ \t]{0,3}#{1,6}[ \t]+|[ \t]{0,3}[-+*][ \t]+(?:\[[ xX]\][ \t]+)?|[ \t]{0,3}\d{1,9}[.)][ \t]+)',
    ).firstMatch(remainder);
    return offset + (structuralPrefix?.end ?? 0);
  }

  bool _aiMappingWhitespace(int codeUnit) =>
      codeUnit == 0x09 ||
      codeUnit == 0x0a ||
      codeUnit == 0x0d ||
      codeUnit == 0x20;

  int? _aiBreakTagEnd(String raw, int offset) {
    if (raw.codeUnitAt(offset) != 0x3c) {
      return null;
    }
    final match = RegExp(
      r'^<br\s*/?>',
      caseSensitive: false,
    ).firstMatch(raw.substring(offset));
    return match == null ? null : offset + match.end;
  }

  int? _aiMarkupTagEnd(String raw, int offset) {
    if (raw.codeUnitAt(offset) != 0x3c) {
      return null;
    }
    final match = RegExp(
      r'^</?[A-Za-z][A-Za-z0-9-]*(?:\s[^<>]*?)?/?>',
    ).firstMatch(raw.substring(offset));
    return match == null ? null : offset + match.end;
  }

  ({String raw, String decoded, int end})? _aiEntityAt(String raw, int offset) {
    if (raw.codeUnitAt(offset) != 0x26) {
      return null;
    }
    final semicolon = raw.indexOf(';', offset + 1);
    if (semicolon < 0 || semicolon - offset > 32) {
      return null;
    }
    final encoded = raw.substring(offset, semicolon + 1);
    final decoded = html_parser.parseFragment(encoded).text;
    if (decoded == null || decoded.isEmpty || decoded == encoded) {
      return null;
    }
    return (raw: encoded, decoded: decoded, end: semicolon + 1);
  }

  bool get _hasBlockSelection => _documentSelection != null;

  GlobalKey _blockKeyFor(String blockId) {
    return _blockKeys.putIfAbsent(blockId, GlobalKey.new);
  }

  Set<String> _selectedBlockIds(List<BusyBlock> blocks) {
    final selection = _documentSelection;
    if (selection == null) {
      return const {};
    }
    final startIndex = blocks.indexWhere(
      (block) => block.id == selection.anchor.blockId,
    );
    final endIndex = blocks.indexWhere(
      (block) => block.id == selection.extent.blockId,
    );
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

  List<_SelectedTextRange> _selectedTextRanges([
    List<BusyBlock>? inputBlocks,
    bool includeEmptyRanges = false,
  ]) {
    final selection = _documentSelection;
    if (selection == null) {
      return const [];
    }
    final blocks =
        inputBlocks ?? _editableBlocks(_documentController.document.blocks);
    final startIndex = blocks.indexWhere(
      (block) => block.id == selection.anchor.blockId,
    );
    final endIndex = blocks.indexWhere(
      (block) => block.id == selection.extent.blockId,
    );
    if (startIndex == -1 || endIndex == -1) {
      return const [];
    }
    final forward =
        startIndex < endIndex ||
        (startIndex == endIndex &&
            selection.anchor.offset <= selection.extent.offset);
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
        startOffset: selection.anchor.offset.clamp(0, textLength).toInt(),
        endOffset: selection.extent.offset.clamp(0, textLength).toInt(),
        forward: forward,
      );
      if (range != null && (includeEmptyRanges || range.end > range.start)) {
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

  _DocumentTextPosition? _selectionAnchorForBlock(String fallbackBlockId) {
    final documentSelection = _documentSelection;
    if (documentSelection != null) {
      return documentSelection.anchor;
    }
    final controller = _textControllers[fallbackBlockId];
    final selection = controller?.selection;
    if (controller == null || selection == null || !selection.isValid) {
      return null;
    }
    return _DocumentTextPosition(
      blockId: fallbackBlockId,
      offset: selection.baseOffset.clamp(0, controller.text.length).toInt(),
    );
  }

  void _handleBlockPointerDown(String blockId, PointerDownEvent event) {
    if (event.buttons != kPrimaryMouseButton) {
      return;
    }
    _resetVerticalCaretMovement();
    final offset = _textOffsetAtGlobalPosition(blockId, event.position);
    if (HardwareKeyboard.instance.isShiftPressed) {
      final anchor = _selectionAnchorForBlock(_activeBlockId ?? blockId);
      if (anchor != null) {
        _pointerSelectionAnchor = anchor;
        _activeBlockId = blockId;
        setState(() {
          _documentSelection = _DocumentTextSelection(
            anchor: anchor,
            extent: _DocumentTextPosition(blockId: blockId, offset: offset),
          );
        });
        _preserveSelectionFocusCallbacks = 2;
        _collapseFieldSelections();
        _selectionFocusNode.requestFocus();
        return;
      }
    }
    _clearBlockSelection();
    _collapseInactiveFieldSelections(blockId);
    _pointerSelectionAnchor = _DocumentTextPosition(
      blockId: blockId,
      offset: offset,
    );
  }

  void _handleBlockPointerMove(PointerMoveEvent event) {
    if (_pointerSelectionAnchor == null ||
        event.buttons != kPrimaryMouseButton) {
      return;
    }
    _updateBlockSelectionDrag(event.position);
  }

  bool _updateBlockSelectionDrag(Offset position) {
    final anchor = _pointerSelectionAnchor;
    if (anchor == null) {
      return false;
    }
    final targetBlockId = _blockIdAtGlobalPosition(position);
    if (targetBlockId == null) {
      return false;
    }
    if (targetBlockId == anchor.blockId && _documentSelection == null) {
      return false;
    }
    final endOffset = _textOffsetAtGlobalPosition(targetBlockId, position);
    final nextSelection = _DocumentTextSelection(
      anchor: anchor,
      extent: _DocumentTextPosition(blockId: targetBlockId, offset: endOffset),
    );
    if (_documentSelection == nextSelection) {
      return false;
    }
    setState(() {
      _documentSelection = nextSelection;
    });
    _collapseFieldSelections();
    _selectionFocusNode.requestFocus();
    return true;
  }

  void _handleBlockPointerUp(PointerUpEvent event) {
    _updateBlockSelectionDrag(event.position);
    _pointerSelectionAnchor = null;
    if (_hasBlockSelection) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusDocumentSelectionExtent();
        }
      });
    }
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
      _documentSelection = null;
      return;
    }
    setState(() {
      _documentSelection = null;
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
      _documentSelection = _DocumentTextSelection(
        anchor: _DocumentTextPosition(blockId: first.id, offset: 0),
        extent: _DocumentTextPosition(
          blockId: last.id,
          offset: last.plainText.length,
        ),
      );
    });
    _collapseFieldSelections();
    _focusDocumentSelectionExtent();
  }

  void _focusDocumentSelectionExtent() {
    final extent = _documentSelection?.extent;
    if (extent == null) {
      return;
    }
    final block = _documentController.blockById(extent.blockId);
    if (block == null) {
      return;
    }
    final controller = _textControllerFor(block);
    _activeBlockId = extent.blockId;
    _focusNodeFor(block).requestFocus();
    controller.selection = TextSelection.collapsed(
      offset: extent.offset.clamp(0, controller.text.length).toInt(),
      affinity: extent.affinity,
    );
    _collapseInactiveFieldSelections(extent.blockId);
  }

  bool _deleteBlockSelection() {
    final ranges = _selectedTextRanges(null, true);
    if (ranges.isEmpty) {
      return false;
    }
    final first = ranges.first;
    final last = ranges.last;
    if (first.block.id == last.block.id && first.start == last.end) {
      return false;
    }
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

  bool _replaceDocumentSelectionWithText(String replacementText) {
    final ranges = _selectedTextRanges(null, true);
    if (ranges.isEmpty) {
      return false;
    }
    final first = ranges.first;
    final last = ranges.last;
    if (first.block.id == last.block.id && first.start == last.end) {
      return false;
    }
    final normalizedReplacement = replacementText
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');
    final activeInlineKinds = _activeInlineKindsAt(first.block.id, first.start);
    _recordUndoSnapshot();
    final deletion = _documentController.deleteTextSelection(
      firstBlockId: first.block.id,
      firstStartOffset: first.start,
      lastBlockId: last.block.id,
      lastEndOffset: last.end,
      removedBlockIds: ranges.map((range) => range.block.id),
    );
    if (deletion == null) {
      return false;
    }
    final mergedText = _documentController.blockText(deletion.blockId);
    final insertionOffset = deletion.offset.clamp(0, mergedText.length).toInt();
    final nextText = mergedText.replaceRange(
      insertionOffset,
      insertionOffset,
      normalizedReplacement,
    );
    final splitResult = _documentController.replaceBlockTextWithParagraphs(
      deletion.blockId,
      nextText,
      insertionOffset + normalizedReplacement.length,
    );
    final focusResult =
        splitResult ??
        BusyWysiwygTextSplitResult(
          blockId: deletion.blockId,
          offset: insertionOffset + normalizedReplacement.length,
        );
    if (splitResult == null) {
      _documentController.updateBlockText(
        deletion.blockId,
        nextText,
        activeInlineKinds: activeInlineKinds,
      );
    }
    if (nextText.isEmpty) {
      _setPendingInlineKinds(deletion.blockId, activeInlineKinds);
    }
    _clearBlockSelection(collapseFields: false);
    _emitMarkdown();
    _focusBlockAfterFrame(focusResult.blockId, offset: focusResult.offset);
    return true;
  }

  bool _replaceDocumentSelectionWithStyledBlocks(
    List<BusyWysiwygStyledBlock> blocks,
  ) {
    if (blocks.isEmpty) {
      return false;
    }
    final ranges = _selectedTextRanges(null, true);
    if (ranges.isEmpty) {
      return false;
    }
    final first = ranges.first;
    final last = ranges.last;
    if (first.block.id == last.block.id && first.start == last.end) {
      return false;
    }
    _recordUndoSnapshot();
    final deletion = _documentController.deleteTextSelection(
      firstBlockId: first.block.id,
      firstStartOffset: first.start,
      lastBlockId: last.block.id,
      lastEndOffset: last.end,
      removedBlockIds: ranges.map((range) => range.block.id),
    );
    if (deletion == null) {
      return false;
    }
    final result = _documentController.insertStyledBlocksAtSelection(
      blockId: deletion.blockId,
      selectionStart: deletion.offset,
      selectionEnd: deletion.offset,
      blocks: blocks,
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
    if (_hasBlockSelection) {
      return _copyDocumentSelectionToClipboard();
    }
    final ranges = _currentSelectionRanges();
    if (ranges.isEmpty) {
      return false;
    }
    return _copyRangesToClipboard(ranges);
  }

  bool _cutCurrentSelection() {
    if (_hasBlockSelection) {
      if (!_copyDocumentSelectionToClipboard()) {
        return false;
      }
      return _deleteBlockSelection();
    }
    final ranges = _currentSelectionRanges();
    if (ranges.isEmpty || !_copyRangesToClipboard(ranges)) {
      return false;
    }
    return _deleteActiveTextSelection(ranges.single);
  }

  bool _copyDocumentSelectionToClipboard() {
    final allRanges = _selectedTextRanges(null, true);
    if (allRanges.isEmpty) {
      return false;
    }
    final ranges = allRanges.any((range) => range.end > range.start)
        ? _withoutEmptySelectionEndpoints(allRanges)
        : allRanges;
    final clipboardText = ranges.map(_copyTextForRange).join('\n\n');
    final clipboardBlocks = [
      for (final range in ranges) _styledBlockForRange(range),
    ];
    _internalClipboard = _WysiwygInternalClipboard(
      text: clipboardText,
      blocks: clipboardBlocks,
    );
    unawaited(Clipboard.setData(ClipboardData(text: clipboardText)));
    return true;
  }

  List<_SelectedTextRange> _withoutEmptySelectionEndpoints(
    List<_SelectedTextRange> ranges,
  ) {
    var start = 0;
    var end = ranges.length;
    while (start < end && ranges[start].start == ranges[start].end) {
      start++;
    }
    while (end > start && ranges[end - 1].start == ranges[end - 1].end) {
      end--;
    }
    return ranges.sublist(start, end);
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
      BusyBlockKind.video => block.attributes['src'] ?? block.rawSource ?? '',
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
    final prefixWidth = busyMarkWysiwygPrefixExtent(block);
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
    final textLayoutWidth =
        (maxWidth - BusyMarkDocumentTextGeometry.editableLayoutInset)
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
    final level = int.tryParse(block.attributes['level'] ?? '') ?? 0;
    return switch (block.kind) {
      BusyBlockKind.heading => busyMarkDocumentHeadingTextStyle(context, level),
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

class _DocumentTextPosition {
  const _DocumentTextPosition({
    required this.blockId,
    required this.offset,
    this.affinity = TextAffinity.downstream,
  });

  final String blockId;
  final int offset;
  final TextAffinity affinity;

  @override
  bool operator ==(Object other) {
    return other is _DocumentTextPosition &&
        other.blockId == blockId &&
        other.offset == offset &&
        other.affinity == affinity;
  }

  @override
  int get hashCode => Object.hash(blockId, offset, affinity);
}

class _DocumentTextSelection {
  const _DocumentTextSelection({required this.anchor, required this.extent});

  final _DocumentTextPosition anchor;
  final _DocumentTextPosition extent;

  @override
  bool operator ==(Object other) {
    return other is _DocumentTextSelection &&
        other.anchor == anchor &&
        other.extent == extent;
  }

  @override
  int get hashCode => Object.hash(anchor, extent);
}

class _OrderedDocumentSelection {
  const _OrderedDocumentSelection({required this.start, required this.end});

  final _DocumentTextPosition start;
  final _DocumentTextPosition end;
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
  const _EditorRenderEntry.block({
    required this.block,
    required this.depth,
    required this.listRunEnd,
  }) : children = null;

  const _EditorRenderEntry.blockquote({
    required this.block,
    required this.depth,
    required this.children,
  }) : listRunEnd = false;

  final BusyBlock block;
  final int depth;
  final bool listRunEnd;
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
    required this.ingestSelectedImage,
    this.onSaveRequired,
  });

  final String title;
  final String initialSource;
  final String initialAlt;
  final String submitLabel;
  final Future<String> Function(String sourcePath) ingestSelectedImage;
  final VoidCallback? onSaveRequired;

  @override
  State<_ImageDialog> createState() => _ImageDialogState();
}

class _ImageDialogState extends State<_ImageDialog> {
  final _sourceController = TextEditingController();
  final _altController = TextEditingController();
  String? _errorMessage;

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
            if (_errorMessage case final message?)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  BusyMarkSpacing.md,
                  BusyMarkSpacing.xs,
                  BusyMarkSpacing.md,
                  BusyMarkSpacing.sm,
                ),
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
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
    try {
      final markdownPath = await widget.ingestSelectedImage(file.path);
      if (!mounted) {
        return;
      }
      _sourceController.text = markdownPath;
      if (_altController.text.trim().isEmpty) {
        _altController.text = p.basenameWithoutExtension(file.name);
      }
      setState(() => _errorMessage = null);
    } on AssetSaveRequiredException {
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
      widget.onSaveRequired?.call();
    } on AssetIngestionException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
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
