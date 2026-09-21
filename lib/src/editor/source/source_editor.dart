import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show setEquals, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:yaru/yaru.dart';

import '../../ai/ai_models.dart';
import '../../app/busymark_design.dart';
import '../../app/busymark_glyphs.dart';
import '../../app/busymark_shortcuts.dart';
import '../../app/busymark_toast.dart';
import '../../app/command_registry.dart';
import '../../app/localization.dart';
import '../../assets/asset_ingestion_service.dart';
import '../../assets/asset_input_service.dart';
import '../../clipboard/clipboard_insertion.dart';
import '../../clipboard/clipboard_models.dart';
import '../../core/diagnostic.dart';
import '../../markdown/markdown_model.dart';
import '../../platform/rich_clipboard_service.dart';
import '../../search/search_replace_service.dart';
import '../../spellcheck/spelling_coordinator.dart';
import '../../spellcheck/spelling_projection.dart';
import '../../spellcheck/spelling_replacement.dart';
import '../document_text_geometry.dart';
import '../clipboard_paste_resolver.dart';
import '../clipboard_local_image_path.dart';
import '../editor_text_context_menu.dart';
import '../wysiwyg/wysiwyg_clipboard_fragment.dart';
import '../source_folding.dart';
import 'source_commands.dart';
import 'source_controller.dart';
import 'source_autocomplete.dart';
import 'source_diagnostics.dart';
import 'source_document.dart';
import 'source_gutter.dart';
import 'source_intrinsic_width.dart';
import 'source_paste_engine.dart';
import 'source_search.dart';

export 'source_paste_engine.dart'
    show SourceDocumentFormat, debugBusyMarkSourceInlineMappingParseCount;

typedef BusyMarkSourceChanged =
    void Function(String fullText, String? sourceFilePath);

typedef BusyMarkSourceTransactionalChanged =
    void Function(
      String fullText,
      String? sourceFilePath,
      TextSelection previousSelection,
      TextSelection selection,
      String? undoGroup,
    );

typedef BusyMarkSourceSessionChanged =
    void Function(
      TextSelection selection,
      double scrollOffset,
      Set<String> foldedRegionKeys,
    );

enum SourceSymbolAction { declaration, usages, rename }

var _sourceEditorUndoSessionSequence = 0;

class BusyMarkSourceEditor extends StatefulWidget {
  const BusyMarkSourceEditor({
    super.key,
    required this.text,
    required this.language,
    required this.filePath,
    this.documentId,
    required this.diagnostics,
    required this.editorFontSize,
    required this.wordWrap,
    required this.searchActive,
    required this.searchOptions,
    required this.onSearchOptionsChanged,
    this.searchReplacement = '',
    this.onSearchReplacementChanged,
    required this.onChanged,
    this.onTransactionalChanged,
    this.onUndo,
    this.onRedo,
    required this.onOpenSearch,
    required this.onCloseSearch,
    this.onVisibleLineChanged,
    this.onAiEdit,
    this.editRevision = 0,
    this.initialSelection,
    this.initialScrollOffset = 0,
    this.initialFoldedRegionKeys = const {},
    this.onSessionChanged,
    this.autocompleteContext = const SourceAutocompleteContext(),
    this.onSymbolAction,
    this.clipboardService,
    this.clipboardInsertionRegistry,
    this.onClipboardCaptured,
    this.workspaceRoot,
    this.writersideRoot,
    this.imagesDir = 'images',
    this.assetWorkspaceKind,
    this.assetIngestionService = const AssetIngestionService(),
    this.assetInputService,
    this.documentFormat,
    this.markdownMode,
    this.onAssetSaveRequired,
    this.spellingAnnotations = const [],
    this.onCheckSpelling,
    this.readSpellingMenuItems,
  });

  final String text;
  final SourceSyntaxLanguage language;
  final String? filePath;
  final String? documentId;
  final Iterable<Diagnostic> diagnostics;
  final double editorFontSize;
  final bool wordWrap;
  final bool searchActive;
  final SourceSearchOptions searchOptions;
  final ValueChanged<SourceSearchOptions> onSearchOptionsChanged;
  final String searchReplacement;
  final ValueChanged<String>? onSearchReplacementChanged;
  final BusyMarkSourceChanged onChanged;
  final BusyMarkSourceTransactionalChanged? onTransactionalChanged;
  final TextEditingValue? Function()? onUndo;
  final TextEditingValue? Function()? onRedo;
  final VoidCallback onOpenSearch;
  final VoidCallback onCloseSearch;
  final ValueChanged<int?>? onVisibleLineChanged;
  final BusyMarkAiEditCallback? onAiEdit;
  final int editRevision;
  final TextSelection? initialSelection;
  final double initialScrollOffset;
  final Set<String> initialFoldedRegionKeys;
  final BusyMarkSourceSessionChanged? onSessionChanged;
  final SourceAutocompleteContext autocompleteContext;
  final void Function(SourceSymbolAction action, int offset)? onSymbolAction;
  final RichClipboardService? clipboardService;
  final BusyMarkClipboardInsertionRegistry? clipboardInsertionRegistry;
  final ValueChanged<BusyMarkClipboardCapture>? onClipboardCaptured;
  final String? workspaceRoot;
  final String? writersideRoot;
  final String imagesDir;
  final AssetWorkspaceKind? assetWorkspaceKind;
  final AssetIngestionService assetIngestionService;
  final AssetInputService? assetInputService;
  final SourceDocumentFormat? documentFormat;
  final MarkdownMode? markdownMode;
  final VoidCallback? onAssetSaveRequired;
  final List<SpellingAnnotation> spellingAnnotations;
  final VoidCallback? onCheckSpelling;
  final BusyMarkEditorSpellingMenuReader? readSpellingMenuItems;

  @override
  State<BusyMarkSourceEditor> createState() => BusyMarkSourceEditorState();
}

class BusyMarkSourceEditorState extends State<BusyMarkSourceEditor> {
  late BusyMarkSourceController _controller;
  late final FocusNode _focusNode;
  late final ScrollController _scrollController;
  late final ScrollController _horizontalScrollController;
  late UndoHistoryController _undoController;
  final _sourceEditorKey = GlobalKey();
  final _foldedRegionKeys = <String>{};
  final _searchController = SourceSearchController();
  final _searchWorker = SourceSearchWorker();
  final _replacementWorker = SearchReplacementWorker();
  bool _applyingSearchReplacement = false;
  ({int start, int end})? _requestedSearchRange;
  bool _searchNavigationFailed = false;
  final _intrinsicWidthCache = SourceIntrinsicWidthCache();
  final _lineLayoutCache = SourceLineLayoutCache();
  final _autocompleteProvider = const SourceAutocompleteProvider();
  final _pasteEngine = const SourcePasteEngine();
  List<SourceFoldRegion> _foldRegions = const [];
  List<SourceAutocompleteSuggestion> _autocompleteSuggestions = const [];
  var _autocompleteSelection = 0;
  String _lastPath = '';
  bool _horizontalCaretScheduled = false;
  bool _contentShrinkCorrectionScheduled = false;
  Timer? _searchDebounce;
  Timer? _foldRefreshDebounce;
  _ContinuousSourceEdit? _continuousSourceEdit;
  _SourceSessionSnapshot? _lastPublishedSession;
  bool _sessionPublicationScheduled = false;
  final _undoSessionId = ++_sourceEditorUndoSessionSequence;
  var _undoGroupSequence = 0;
  late final _SourceClipboardInsertionTarget _historyInsertionTarget;

  RichClipboardService get _clipboard =>
      widget.clipboardService ?? busyMarkRichClipboardService;

  int get spellingCaretOffset => _controller.fullSelection.extentOffset
      .clamp(0, _controller.fullText.length)
      .toInt();

  void restoreSpellingFocus() => _focusNode.requestFocus();

  void revealSpellingOccurrence(SpellingOccurrence occurrence) {
    if (occurrence.run.snapshot.bufferId !=
            (widget.documentId ?? widget.filePath) ||
        occurrence.run.snapshot.contentRevision != widget.editRevision ||
        occurrence.run.target is! SpellingSourceTarget) {
      return;
    }
    final start = occurrence.sourceStart;
    final end = occurrence.sourceEnd;
    if (start == null || end == null || end > _controller.fullText.length) {
      return;
    }
    _unfoldSourceRange(start, end);
    _focusNode.requestFocus();
    scrollToOffset(start, updateSelection: false);
    _controller.fullSelection = TextSelection(
      baseOffset: start,
      extentOffset: end,
    );
  }

  bool applySpellingCorrection({
    required SpellingOccurrence occurrence,
    required String suggestion,
  }) {
    final before = spellingSourceSnapshot(occurrence);
    if (before == null) return false;
    late final SpellingReplacementPlan plan;
    late final String after;
    try {
      plan = const SpellingReplacementPlanner().build(
        occurrence: occurrence,
        suggestion: suggestion,
      );
      after = plan.applyToSource(before);
    } on Object {
      return false;
    }
    return applyPreparedSpellingCorrection(
      occurrence: occurrence,
      plan: plan,
      expectedSource: before,
      replacementSource: after,
    );
  }

  String? spellingSourceSnapshot(SpellingOccurrence occurrence) {
    final snapshot = occurrence.run.snapshot;
    final target = occurrence.run.target;
    if (snapshot.bufferId != (widget.documentId ?? widget.filePath) ||
        snapshot.contentRevision != widget.editRevision ||
        target is! SpellingSourceTarget ||
        target.filePath != (widget.filePath ?? widget.documentId) ||
        occurrence.word !=
            occurrence.run.text.substring(
              occurrence.logicalStart,
              occurrence.logicalEnd,
            )) {
      return null;
    }
    final before = _controller.fullText;
    for (final atom in occurrence.atoms) {
      if (atom.sourceStart < 0 ||
          atom.sourceEnd > before.length ||
          atom.sourceEnd < atom.sourceStart) {
        return null;
      }
    }
    return before;
  }

  bool applyPreparedSpellingCorrection({
    required SpellingOccurrence occurrence,
    required SpellingReplacementPlan plan,
    required String expectedSource,
    required String replacementSource,
  }) {
    final snapshot = occurrence.run.snapshot;
    // Final guard and mutation are synchronous; no operation is awaited here.
    if (snapshot.bufferId != (widget.documentId ?? widget.filePath) ||
        snapshot.contentRevision != widget.editRevision ||
        expectedSource != _controller.fullText) {
      return false;
    }
    if (replacementSource == expectedSource || plan.sourceEdits.isEmpty) {
      return false;
    }
    final start = plan.sourceEdits.map((edit) => edit.start).reduce(math.min);
    final selectionOffset = plan.resultingSourceCaret ?? start;
    _unfoldSourceRange(
      start,
      plan.sourceEdits.map((edit) => edit.end).reduce(math.max),
    );
    _applyFullEditingValue(
      TextEditingValue(
        text: replacementSource,
        selection: TextSelection.collapsed(
          offset: selectionOffset.clamp(0, replacementSource.length),
        ),
      ),
      origin: _SourceEditOrigin.spellingCorrection,
    );
    return true;
  }

  SourceDocumentFormat get _documentFormat =>
      widget.documentFormat ??
      switch (widget.language) {
        SourceSyntaxLanguage.markdown => SourceDocumentFormat.markdown,
        SourceSyntaxLanguage.xml => SourceDocumentFormat.genericXml,
        SourceSyntaxLanguage.plain => SourceDocumentFormat.plainText,
      };

  MarkdownMode get _destinationMarkdownMode =>
      widget.markdownMode ?? MarkdownMode.commonMark;

  @override
  void initState() {
    super.initState();
    _controller = BusyMarkSourceController(
      text: widget.text,
      language: widget.language,
    );
    _historyInsertionTarget = _SourceClipboardInsertionTarget(this);
    widget.clipboardInsertionRegistry?.register(_historyInsertionTarget);
    _focusNode = FocusNode(onKeyEvent: _handleKeyEvent);
    _scrollController = ScrollController();
    _horizontalScrollController = ScrollController();
    _undoController = UndoHistoryController();
    _lastPath = widget.documentId ?? widget.filePath ?? '';
    _recomputeFoldRegions(resetCollapsed: true);
    _restoreSessionState();
    _lastPublishedSession = _sourceSessionSnapshot();
    _syncSearchOptions();
    _controller.addListener(_handleControllerActivity);
    _scrollController.addListener(_scheduleSessionPublication);
  }

  @override
  void didUpdateWidget(covariant BusyMarkSourceEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clipboardInsertionRegistry !=
        widget.clipboardInsertionRegistry) {
      oldWidget.clipboardInsertionRegistry?.unregister(_historyInsertionTarget);
      widget.clipboardInsertionRegistry?.register(_historyInsertionTarget);
    }
    if (widget.text != oldWidget.text ||
        widget.searchOptions != oldWidget.searchOptions ||
        widget.searchReplacement != oldWidget.searchReplacement) {
      _replacementWorker.cancel();
    }
    final path = widget.documentId ?? widget.filePath ?? '';
    final pathChanged = path != _lastPath;
    final languageChanged = widget.language != oldWidget.language;
    var authoritativeDocumentChanged = false;
    if (pathChanged) {
      authoritativeDocumentChanged = true;
      _lastPath = path;
      _foldedRegionKeys.clear();
      _withoutSessionPublication(() {
        _replaceController(text: widget.text, language: widget.language);
        _recomputeFoldRegions(resetCollapsed: true);
        _restoreSessionState();
      });
      _lastPublishedSession = _sourceSessionSnapshot();
    } else if (widget.text != _controller.fullText || languageChanged) {
      authoritativeDocumentChanged = true;
      _continuousSourceEdit = null;
      _withoutSessionPublication(() {
        _controller.replaceFullTextAndLanguage(
          text: widget.text,
          language: widget.language,
        );
        _recomputeFoldRegions(resetCollapsed: languageChanged);
      });
    }
    if (widget.searchActive != oldWidget.searchActive ||
        widget.searchOptions != oldWidget.searchOptions ||
        authoritativeDocumentChanged) {
      _requestedSearchRange = null;
      _searchNavigationFailed = false;
      _syncSearchOptions();
    }
    if (widget.wordWrap && !oldWidget.wordWrap) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_horizontalScrollController.hasClients) {
          _horizontalScrollController.jumpTo(0);
        }
      });
    }
  }

  @override
  void dispose() {
    widget.clipboardInsertionRegistry?.unregister(_historyInsertionTarget);
    _searchDebounce?.cancel();
    _foldRefreshDebounce?.cancel();
    _searchWorker.dispose();
    _replacementWorker.dispose();
    _controller.removeListener(_handleControllerActivity);
    _scrollController.dispose();
    _horizontalScrollController.dispose();
    _focusNode.dispose();
    _undoController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleControllerActivity() {
    _scheduleSessionPublication();
    if (widget.wordWrap || _horizontalCaretScheduled) {
      return;
    }
    _horizontalCaretScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _horizontalCaretScheduled = false;
      _ensureCaretHorizontallyVisible();
    });
  }

  void _ensureCaretHorizontallyVisible() {
    if (!mounted ||
        widget.wordWrap ||
        !_horizontalScrollController.hasClients ||
        !_controller.selection.isValid) {
      return;
    }
    final editorRenderObject = _sourceEditorKey.currentContext
        ?.findRenderObject();
    if (editorRenderObject is! RenderBox) {
      return;
    }
    final editable = _findSourceRenderEditable(editorRenderObject);
    if (editable == null) {
      return;
    }
    final caret = editable.getLocalRectForCaret(
      TextPosition(offset: _controller.selection.extentOffset),
    );
    final caretX = editable
        .localToGlobal(caret.topLeft, ancestor: editorRenderObject)
        .dx;
    final position = _horizontalScrollController.position;
    const margin = BusyMarkSpacing.lg;
    var target = position.pixels;
    if (caretX < position.pixels + margin) {
      target = caretX - margin;
    } else if (caretX > position.pixels + position.viewportDimension - margin) {
      target = caretX - position.viewportDimension + margin;
    }
    target = target.clamp(0.0, position.maxScrollExtent).toDouble();
    if ((target - position.pixels).abs() > 0.5) {
      position.jumpTo(target);
    }
  }

  void scrollToLine(int line) {
    scrollToOffset(_textOffsetForLine(_controller.fullText, line));
  }

  /// Reveals a full-document offset, including a destination inside a fold.
  void scrollToOffset(int offset, {bool updateSelection = true}) {
    final textOffset = offset.clamp(0, _controller.fullText.length);
    final line =
        '\n'.allMatches(_controller.fullText.substring(0, textOffset)).length +
        1;
    _unfoldSourceLine(line);
    _focusNode.requestFocus();
    if (updateSelection) {
      _controller.fullSelection = TextSelection.collapsed(offset: textOffset);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animateScrollToLine(line);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _jumpScrollToLine(line);
      });
      unawaited(
        Future<void>.delayed(BusyMarkMotion.previewSearchDelay, () {
          _jumpScrollToLine(line);
        }),
      );
    });
  }

  void scrollToSearchRange({
    required int line,
    required int startOffset,
    required int endOffset,
  }) {
    _unfoldSourceRange(startOffset, endOffset);
    final start = startOffset.clamp(0, _controller.fullText.length).toInt();
    final end = endOffset.clamp(start, _controller.fullText.length).toInt();
    _replacementWorker.cancel();
    _requestedSearchRange = start < end ? (start: start, end: end) : null;
    _searchNavigationFailed = false;
    _focusNode.requestFocus();
    _controller.fullSelection = TextSelection(
      baseOffset: start,
      extentOffset: end,
    );
    final result = _searchController.result;
    final localIndex = result.matches.indexWhere(
      (match) => match.fullStart == start && match.fullEnd == end,
    );
    if (localIndex >= 0) {
      _requestedSearchRange = null;
      _searchController.setCurrentMatchIndex(
        result.firstMatchIndex + localIndex,
      );
      _controller.setSearchResult(_searchController.result);
      setState(() {});
    } else if (start < end) {
      _scheduleSearch(
        minimumFullOffset: start,
        revealCurrentAfterRefresh: true,
        wrapIfOffsetMissing: false,
      );
    } else {
      _searchController.setCurrentMatchIndex(null);
      _controller.setSearchResult(_searchController.result);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animateScrollToLine(line);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _jumpScrollToLine(line);
      });
      unawaited(
        Future<void>.delayed(BusyMarkMotion.previewSearchDelay, () {
          _jumpScrollToLine(line);
        }),
      );
    });
  }

  void _moveSourceLines({required bool down}) {
    final before = _fullEditingValue();
    final after = SourceCommands.moveLines(before, down: down);
    if (after == before) return;
    var start = 0;
    while (start < before.text.length &&
        start < after.text.length &&
        before.text.codeUnitAt(start) == after.text.codeUnitAt(start)) {
      start++;
    }
    var end = before.text.length;
    var nextEnd = after.text.length;
    while (end > start &&
        nextEnd > start &&
        before.text.codeUnitAt(end - 1) == after.text.codeUnitAt(nextEnd - 1)) {
      end--;
      nextEnd--;
    }
    _unfoldSourceRange(start, end);
    _applyFullEditingValue(after);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (_hasActiveComposition) {
      // Keep Source shortcuts and focus traversal out of an active platform
      // composition while leaving the key unhandled for the input method.
      return KeyEventResult.skipRemainingHandlers;
    }
    final keyboard = HardwareKeyboard.instance;
    final key = event.logicalKey;
    if (_autocompleteSuggestions.isNotEmpty) {
      if (key == LogicalKeyboardKey.arrowDown) {
        _moveAutocompleteSelection(1);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowUp) {
        _moveAutocompleteSelection(-1);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.tab) {
        _applyAutocomplete(_autocompleteSuggestions[_autocompleteSelection]);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.escape) {
        _closeAutocomplete();
        return KeyEventResult.handled;
      }
    }
    if (key == LogicalKeyboardKey.space &&
        keyboard.isControlPressed &&
        !keyboard.isAltPressed) {
      _showAutocomplete();
      return KeyEventResult.handled;
    }
    if (widget.onSymbolAction != null) {
      final action = key == LogicalKeyboardKey.keyB && keyboard.isControlPressed
          ? SourceSymbolAction.declaration
          : key == LogicalKeyboardKey.f7 && keyboard.isAltPressed
          ? SourceSymbolAction.usages
          : key == LogicalKeyboardKey.f6 && keyboard.isShiftPressed
          ? SourceSymbolAction.rename
          : null;
      if (action != null) {
        widget.onSymbolAction!(action, _controller.fullSelection.extentOffset);
        return KeyEventResult.handled;
      }
    }
    final commands =
        BusyMarkCommandRegistryScope.read(context) ??
        BusyMarkCommandCatalog.metadata;
    if (widget.filePath?.toLowerCase().endsWith('.tree') == true) {
      final up = commands.shortcutAccepts(
        BusyMarkCommandIds.treeMoveLineUp,
        event,
        keyboard,
      );
      final down = commands.shortcutAccepts(
        BusyMarkCommandIds.treeMoveLineDown,
        event,
        keyboard,
      );
      if (up || down) {
        _moveSourceLines(down: down);
        return KeyEventResult.handled;
      }
    }
    if (commands.shortcutAccepts(BusyMarkCommandIds.search, event, keyboard)) {
      widget.onOpenSearch();
      return KeyEventResult.handled;
    }
    if (commands.shortcutAccepts(
      BusyMarkCommandIds.textCopy,
      event,
      keyboard,
    )) {
      unawaited(_copyOrCutSource(cut: false));
      return KeyEventResult.handled;
    }
    if (commands.shortcutAccepts(BusyMarkCommandIds.textCut, event, keyboard)) {
      unawaited(_copyOrCutSource(cut: true));
      return KeyEventResult.handled;
    }
    if (commands.shortcutAccepts(
      BusyMarkCommandIds.textPastePlainText,
      event,
      keyboard,
    )) {
      unawaited(_pasteFromSystemClipboard(BusyMarkPasteMode.plainText));
      return KeyEventResult.handled;
    }
    if (commands.shortcutAccepts(
      BusyMarkCommandIds.textPaste,
      event,
      keyboard,
    )) {
      unawaited(_pasteFromSystemClipboard(BusyMarkPasteMode.normal));
      return KeyEventResult.handled;
    }
    if (commands.shortcutAccepts(
      BusyMarkCommandIds.textUndo,
      event,
      keyboard,
    )) {
      final value = widget.onUndo?.call();
      if (value != null) {
        _applyOwnedUndoValue(value);
        return KeyEventResult.handled;
      }
    }
    if (commands.shortcutAccepts(
      BusyMarkCommandIds.textRedo,
      event,
      keyboard,
    )) {
      final value = widget.onRedo?.call();
      if (value != null) {
        _applyOwnedUndoValue(value);
        return KeyEventResult.handled;
      }
    }
    if (commands.shortcutAccepts(
      BusyMarkCommandIds.textInsertIndentation,
      event,
      keyboard,
    )) {
      _insertTab();
      return KeyEventResult.handled;
    }
    if (commands.shortcutAccepts(
      BusyMarkCommandIds.textOutdentSource,
      event,
      keyboard,
    )) {
      _outdentSelection();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter && !keyboard.isShiftPressed) {
      _applyFullEditingValue(SourceCommands.smartEnter(_fullEditingValue()));
      return KeyEventResult.handled;
    }
    if (commands.shortcutAccepts(
      BusyMarkCommandIds.textEscape,
      event,
      keyboard,
    )) {
      widget.onCloseSearch();
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
          !_canRefineWithAi) {
        return KeyEventResult.ignored;
      }
      _applyShortcutAction(shortcutAction);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final sourceStrutStyle = _sourceStrutStyle(
      folded: _foldedRegionKeys.isNotEmpty,
    );
    final sourceLineHeight = _sourceLineHeight(context, sourceStrutStyle);
    final markers = widget.filePath == null
        ? const <SourceDiagnosticMarker>[]
        : sourceDiagnosticMarkers(
            document: _controller.document,
            diagnostics: widget.diagnostics,
            filePath: widget.filePath!,
          );
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.view),
      child: Stack(
        children: [
          Positioned.fill(
            child: _SourceEditorFrame(
              controller: _controller,
              scrollController: _scrollController,
              horizontalScrollController: _horizontalScrollController,
              wordWrap: widget.wordWrap,
              lineHeight: sourceLineHeight,
              textStyle: _sourceTextStyle,
              strutStyle: sourceStrutStyle,
              collapsedRegionKeys: _foldedRegionKeys,
              foldRegions: _foldRegions,
              diagnosticMarkers: markers,
              spellingAnnotations: widget.spellingAnnotations,
              layoutCache: _lineLayoutCache,
              intrinsicWidthCache: _intrinsicWidthCache,
              onToggleFold: _toggleFold,
              onVisibleLineChanged: widget.onVisibleLineChanged,
              child: SizedBox(
                key: _sourceEditorKey,
                child: KeyedSubtree(
                  key: ValueKey(widget.documentId ?? widget.filePath),
                  child: Shortcuts(
                    shortcuts:
                        (BusyMarkCommandRegistryScope.maybeOf(context) ??
                                BusyMarkCommandCatalog.metadata)
                            .shortcutIntents(
                              scopes: const {BusyMarkCommandScope.editor},
                              intentFor: BusyMarkContextCommandIntent.new,
                            ),
                    child: Actions(
                      actions: {
                        BusyMarkContextCommandIntent:
                            BusyMarkContextCommandAction(
                              isCommandEnabled: (commandId) =>
                                  !_hasActiveComposition &&
                                  (commandId ==
                                          BusyMarkCommandIds.checkSpelling ||
                                      commandId.startsWith('editor.') ||
                                      (widget.filePath?.toLowerCase().endsWith(
                                                '.tree',
                                              ) ==
                                              true &&
                                          {
                                            BusyMarkCommandIds.treeMoveLineUp,
                                            BusyMarkCommandIds.treeMoveLineDown,
                                          }.contains(commandId)) ||
                                      {
                                        BusyMarkCommandIds.textCopy,
                                        BusyMarkCommandIds.textCut,
                                        BusyMarkCommandIds.textPaste,
                                        BusyMarkCommandIds.textPastePlainText,
                                      }.contains(commandId)),
                              onCommand: (commandId) {
                                if (commandId ==
                                    BusyMarkCommandIds.checkSpelling) {
                                  widget.onCheckSpelling?.call();
                                  return;
                                }
                                if (commandId ==
                                        BusyMarkCommandIds.treeMoveLineUp ||
                                    commandId ==
                                        BusyMarkCommandIds.treeMoveLineDown) {
                                  _moveSourceLines(
                                    down:
                                        commandId ==
                                        BusyMarkCommandIds.treeMoveLineDown,
                                  );
                                  return;
                                }
                                if (commandId == BusyMarkCommandIds.textCopy) {
                                  unawaited(_copyOrCutSource(cut: false));
                                  return;
                                }
                                if (commandId == BusyMarkCommandIds.textCut) {
                                  unawaited(_copyOrCutSource(cut: true));
                                  return;
                                }
                                if (commandId == BusyMarkCommandIds.textPaste) {
                                  unawaited(
                                    _pasteFromSystemClipboard(
                                      BusyMarkPasteMode.normal,
                                    ),
                                  );
                                  return;
                                }
                                if (commandId ==
                                    BusyMarkCommandIds.textPastePlainText) {
                                  unawaited(
                                    _pasteFromSystemClipboard(
                                      BusyMarkPasteMode.plainText,
                                    ),
                                  );
                                  return;
                                }
                                final name = commandId.substring(
                                  'editor.'.length,
                                );
                                final action = BusyMarkEditorShortcutAction
                                    .values
                                    .where(
                                      (candidate) => candidate.name == name,
                                    )
                                    .firstOrNull;
                                if (action != null) {
                                  _applyShortcutAction(action);
                                }
                              },
                            ),
                        _SourceEditorShortcutIntent:
                            CallbackAction<_SourceEditorShortcutIntent>(
                              onInvoke: (intent) {
                                _applyShortcutAction(intent.action);
                                return null;
                              },
                            ),
                      },
                      child: DefaultTextHeightBehavior(
                        textHeightBehavior: sourceTextHeightBehavior,
                        child: TextField(
                          controller: _controller,
                          undoController: _undoController,
                          focusNode: _focusNode,
                          scrollController: _scrollController,
                          textDirection: TextDirection.ltr,
                          keyboardType: TextInputType.multiline,
                          autocorrect: false,
                          enableSuggestions: false,
                          smartDashesType: SmartDashesType.disabled,
                          smartQuotesType: SmartQuotesType.disabled,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          style: _sourceTextStyle,
                          strutStyle: sourceStrutStyle,
                          selectionHeightStyle: BusyMarkDocumentTextGeometry
                              .sourceSelectionHeightStyle,
                          selectionWidthStyle:
                              BusyMarkDocumentTextGeometry.selectionWidthStyle,
                          cursorColor: colors.foreground.withValues(
                            alpha: BusyMarkAlpha.sourceCursor,
                          ),
                          cursorHeight:
                              widget.editorFontSize *
                              BusyMarkTypography.sourceCursorHeightScale,
                          cursorWidth: BusyMarkStroke.sourceCursor,
                          decoration: const InputDecoration(
                            isCollapsed: true,
                            filled: false,
                            fillColor: BusyMarkLinuxPalette.transparent,
                            hoverColor: BusyMarkLinuxPalette.transparent,
                            focusColor: BusyMarkLinuxPalette.transparent,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: BusyMarkInsets.sourceEditor,
                          ),
                          contextMenuBuilder: (context, editableTextState) =>
                              buildBusyMarkEditorTextContextMenu(
                                context,
                                editableTextState,
                                refineWithAiLabel: context.l10n.aiRefineWithAi,
                                readSpellingItems:
                                    widget.readSpellingMenuItems == null
                                    ? null
                                    : (visibleOffset) =>
                                          widget.readSpellingMenuItems!(
                                            _controller
                                                .visibleOffsetToFullOffset(
                                                  visibleOffset,
                                                ),
                                          ),
                                onCheckSpelling: widget.onCheckSpelling,
                                additionalItems: [
                                  if (widget.onSymbolAction != null)
                                    for (final action
                                        in SourceSymbolAction.values)
                                      BusyMarkPopupMenuItem<VoidCallback>(
                                        value: () => widget.onSymbolAction!(
                                          action,
                                          _controller
                                              .fullSelection
                                              .extentOffset,
                                        ),
                                        label: switch (action) {
                                          SourceSymbolAction.declaration =>
                                            'Go to Declaration',
                                          SourceSymbolAction.usages =>
                                            'Find Usages',
                                          SourceSymbolAction.rename =>
                                            context.l10n.rename,
                                        },
                                        shortcut: switch (action) {
                                          SourceSymbolAction.declaration =>
                                            'Ctrl+B',
                                          SourceSymbolAction.usages => 'Alt+F7',
                                          SourceSymbolAction.rename =>
                                            'Shift+F6',
                                        },
                                      ),
                                ],
                                onRefineWithAi: widget.onAiEdit == null
                                    ? null
                                    : () => unawaited(_runAiEdit()),
                                onCopy: () =>
                                    unawaited(_copyOrCutSource(cut: false)),
                                onCut: () =>
                                    unawaited(_copyOrCutSource(cut: true)),
                                onPaste: () => unawaited(
                                  _pasteFromSystemClipboard(
                                    BusyMarkPasteMode.normal,
                                  ),
                                ),
                                onPastePlainText: () => unawaited(
                                  _pasteFromSystemClipboard(
                                    BusyMarkPasteMode.plainText,
                                  ),
                                ),
                                readPasteAvailability:
                                    _readContextMenuPasteAvailability,
                              ),
                          onChanged: (_) => _handleSourceChanged(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_controller.sourceFeaturesDegraded)
            const Positioned(
              top: BusyMarkSpacing.sm,
              left: BusyMarkSpacing.sm,
              child: _SourceLargeFileBanner(),
            ),
          if (widget.searchActive)
            Positioned(
              top: BusyMarkSpacing.sm,
              right: BusyMarkSpacing.sm,
              child: _SourceSearchPanel(
                result: _searchController.result,
                onPrevious: _previousSearchMatch,
                onNext: _nextSearchMatch,
                onToggleCaseSensitive: () => _updateSearchOptions(
                  widget.searchOptions.copyWith(
                    caseSensitive: !widget.searchOptions.caseSensitive,
                  ),
                ),
                onToggleWholeWord: () => _updateSearchOptions(
                  widget.searchOptions.copyWith(
                    wholeWord: !widget.searchOptions.wholeWord,
                  ),
                ),
                onToggleRegex: () => _updateSearchOptions(
                  widget.searchOptions.copyWith(
                    regex: !widget.searchOptions.regex,
                  ),
                ),
                replacement: widget.searchReplacement,
                canReplaceCurrent:
                    _requestedSearchRange == null && !_searchNavigationFailed,
                onReplacementChanged:
                    widget.onSearchReplacementChanged ?? (_) {},
                onReplaceCurrent: () => unawaited(_replaceCurrentSearchMatch()),
                onReplaceAndFindNext: () =>
                    unawaited(_replaceCurrentSearchMatch(findNext: true)),
                onReplaceAll: () => unawaited(_replaceAllSearchMatches()),
                onClose: widget.onCloseSearch,
              ),
            ),
          if (_autocompleteSuggestions.isNotEmpty)
            Positioned(
              right: BusyMarkSpacing.sm,
              bottom: BusyMarkSpacing.sm,
              child: _SourceAutocompletePopup(
                suggestions: _autocompleteSuggestions,
                selectedIndex: _autocompleteSelection,
                onSelected: _applyAutocomplete,
              ),
            ),
        ],
      ),
    );
  }

  bool get _canRefineWithAi {
    final selection = _controller.fullSelection;
    return widget.onAiEdit != null &&
        selection.isValid &&
        !selection.isCollapsed;
  }

  Future<void> _runAiEdit() async {
    final callback = widget.onAiEdit;
    if (callback == null) {
      return;
    }
    final value = _fullEditingValue();
    final rawSelection = value.selection;
    final anchorOffset = rawSelection.isValid
        ? rawSelection.extentOffset.clamp(0, value.text.length).toInt()
        : value.text.length;
    final selection = rawSelection.isValid
        ? TextSelection(
            baseOffset: rawSelection.start.clamp(0, value.text.length).toInt(),
            extentOffset: rawSelection.end.clamp(0, value.text.length).toInt(),
          )
        : TextSelection.collapsed(offset: value.text.length);
    if (selection.isCollapsed) {
      return;
    }
    final originalText = value.text;
    final result = await callback(
      AiEditorSnapshot(
        documentSource: originalText,
        selectionStart: selection.start,
        selectionEnd: selection.end,
        anchorOffset: anchorOffset,
        sourceRevision: widget.editRevision,
        targetId: widget.filePath ?? 'untitled',
        documentPath: widget.filePath,
      ),
    );
    if (!mounted || result == null) {
      return;
    }
    final invocation = result.invocation;
    final replacementStart = invocation.replacementStart;
    final replacementEnd = invocation.replacementEnd;
    if (replacementStart == null || replacementEnd == null) {
      return;
    }
    if (_controller.fullText != originalText) {
      BusyMarkToastOverlay.show(
        context,
        message: context.l10n.aiStaleProposal,
        priority: BusyMarkToastPriority.high,
      );
      return;
    }
    final replacement = result.replacement;
    _applyFullEditingValue(
      TextEditingValue(
        text: originalText.replaceRange(
          replacementStart,
          replacementEnd,
          replacement,
        ),
        selection: replacementStart == replacementEnd
            ? TextSelection.collapsed(
                offset: replacementStart + replacement.length,
              )
            : TextSelection(
                baseOffset: replacementStart,
                extentOffset: replacementStart + replacement.length,
              ),
      ),
    );
  }

  void _syncSearchOptions() {
    _scheduleSearch();
  }

  void _scheduleSearch({
    int? currentIndex,
    int? firstMatchIndex,
    int? minimumFullOffset,
    bool revealCurrentAfterRefresh = false,
    bool wrapIfOffsetMissing = true,
  }) {
    _searchDebounce?.cancel();
    _searchWorker.cancel();
    if (!widget.searchActive) {
      _searchController.stageOptions(const SourceSearchOptions());
      _controller.setSearchResult(SourceSearchResult.empty);
      return;
    }
    final options = widget.searchOptions;
    final previousResult = _searchController.result;
    final requestedFirstMatchIndex =
        firstMatchIndex ??
        (previousResult.options == options
            ? previousResult.firstMatchIndex
            : 0);
    final invalidRegex = sourceSearchOptionsHaveInvalidRegex(options);
    _searchController.stageOptions(options, invalidRegex: invalidRegex);
    _controller.setSearchResult(_searchController.result);
    if (options.query.isEmpty || invalidRegex) {
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 120), () {
      final document = _controller.document;
      unawaited(
        _searchWorker
            .search(
              document,
              options,
              currentMatchIndex: currentIndex,
              firstMatchIndex: requestedFirstMatchIndex,
              minimumFullOffset: minimumFullOffset,
            )
            .then((result) {
              if (!mounted ||
                  result == null ||
                  !identical(document, _controller.document) ||
                  options != widget.searchOptions ||
                  !widget.searchActive) {
                return;
              }
              if (minimumFullOffset != null &&
                  result.matches.isEmpty &&
                  result.totalMatchCount > 0 &&
                  wrapIfOffsetMissing) {
                _scheduleSearch(
                  currentIndex: 0,
                  firstMatchIndex: 0,
                  revealCurrentAfterRefresh: revealCurrentAfterRefresh,
                  wrapIfOffsetMissing: false,
                );
                return;
              }
              _searchController.acceptResult(result);
              final requestedRange = _requestedSearchRange;
              if (requestedRange != null) {
                _requestedSearchRange = null;
                final localIndex = result.matches.indexWhere(
                  (match) =>
                      match.fullStart == requestedRange.start &&
                      match.fullEnd == requestedRange.end,
                );
                _searchNavigationFailed = localIndex < 0;
                if (localIndex >= 0) {
                  _searchController.setCurrentMatchIndex(
                    result.firstMatchIndex + localIndex,
                  );
                } else {
                  // A completed lookup with no exact match must not silently
                  // turn Replace Current into replacement of the first result.
                  _searchController.setCurrentMatchIndex(null);
                }
              } else if (minimumFullOffset != null &&
                  result.matches.isNotEmpty) {
                _searchController.setCurrentMatchIndex(result.firstMatchIndex);
              } else if (revealCurrentAfterRefresh &&
                  _searchController.result.currentMatch == null &&
                  result.matches.isNotEmpty) {
                _searchController.setCurrentMatchIndex(result.firstMatchIndex);
              }
              _controller.setSearchResult(_searchController.result);
              setState(() {});
              if (revealCurrentAfterRefresh) {
                _revealSearchMatch(_searchController.result.currentMatch);
              }
            }),
      );
    });
  }

  void _refreshSearch({
    int? currentIndex,
    int? firstMatchIndex,
    int? minimumFullOffset,
    bool revealCurrentAfterRefresh = false,
  }) {
    if (!widget.searchActive) {
      _controller.setSearchResult(SourceSearchResult.empty);
      return;
    }
    _scheduleSearch(
      currentIndex: currentIndex,
      firstMatchIndex: firstMatchIndex,
      minimumFullOffset: minimumFullOffset,
      revealCurrentAfterRefresh: revealCurrentAfterRefresh,
    );
  }

  void _updateSearchOptions(SourceSearchOptions options) {
    widget.onSearchOptionsChanged(options);
  }

  void _nextSearchMatch() {
    _requestedSearchRange = null;
    _searchNavigationFailed = false;
    final result = _searchController.result;
    if (result.totalMatchCount == 0) {
      _revealSearchMatch(null);
      return;
    }
    final index = result.currentMatchIndex == null
        ? 0
        : (result.currentMatchIndex! + 1) % result.totalMatchCount;
    _selectSearchMatchIndex(index, loadPreviousWindow: false);
  }

  void _previousSearchMatch() {
    _requestedSearchRange = null;
    _searchNavigationFailed = false;
    final result = _searchController.result;
    if (result.totalMatchCount == 0) {
      _revealSearchMatch(null);
      return;
    }
    final index = result.currentMatchIndex == null
        ? result.totalMatchCount - 1
        : (result.currentMatchIndex! - 1 + result.totalMatchCount) %
              result.totalMatchCount;
    _selectSearchMatchIndex(index, loadPreviousWindow: true);
  }

  void _selectSearchMatchIndex(int index, {required bool loadPreviousWindow}) {
    final result = _searchController.result;
    final storedEnd = result.firstMatchIndex + result.matches.length;
    if (index >= result.firstMatchIndex && index < storedEnd) {
      _searchController.setCurrentMatchIndex(index);
      _revealSearchMatch(_searchController.result.currentMatch);
      return;
    }
    final firstMatchIndex = loadPreviousWindow
        ? math.max(0, index - sourceInteractiveSearchMatchLimit + 1)
        : index;
    _scheduleSearch(
      currentIndex: index,
      firstMatchIndex: firstMatchIndex,
      revealCurrentAfterRefresh: true,
    );
  }

  Future<void> _replaceCurrentSearchMatch({bool findNext = false}) async {
    if (_searchController.result.invalidRegex ||
        _requestedSearchRange != null ||
        _searchNavigationFailed) {
      return;
    }
    if (_searchController.result.currentMatchIndex == null) {
      _searchController.next(_controller.document);
    }
    final currentIndex = _searchController.result.currentMatchIndex;
    final currentMatch = _searchController.result.currentMatch;
    if (currentIndex == null || currentMatch == null) {
      return;
    }
    final document = _controller.document;
    final options = widget.searchOptions;
    final replacement = widget.searchReplacement;
    final preview = await _replacementWorker.previewText(
      source: document.fullText,
      options: options,
      replacement: replacement,
      targetStart: currentMatch.fullStart,
      targetEnd: currentMatch.fullEnd,
    );
    if (!mounted ||
        preview == null ||
        !identical(document, _controller.document) ||
        options != widget.searchOptions ||
        replacement != widget.searchReplacement ||
        _searchController.result.currentMatchIndex != currentIndex ||
        preview.invalidRegex ||
        preview.matches.isEmpty) {
      return;
    }
    final match = preview.matches.single;
    final nextText = preview.source.replaceRange(
      match.start,
      match.end,
      match.replacement,
    );
    _applyingSearchReplacement = true;
    try {
      _applyFullEditingValue(
        TextEditingValue(
          text: nextText,
          selection: TextSelection(
            baseOffset: match.start,
            extentOffset: match.start + match.replacement.length,
          ),
        ),
      );
    } finally {
      _applyingSearchReplacement = false;
    }
    final replacementEnd = match.start + match.replacement.length;
    _refreshSearch(
      minimumFullOffset: findNext ? replacementEnd : match.start,
      revealCurrentAfterRefresh: true,
    );
  }

  Future<void> _replaceAllSearchMatches() async {
    final document = _controller.document;
    final options = widget.searchOptions;
    final replacement = widget.searchReplacement;
    final preview = await _replacementWorker.previewText(
      source: document.fullText,
      options: options,
      replacement: replacement,
    );
    if (!mounted ||
        preview == null ||
        !identical(document, _controller.document) ||
        options != widget.searchOptions ||
        replacement != widget.searchReplacement ||
        preview.invalidRegex ||
        preview.matches.isEmpty) {
      return;
    }
    if (preview.truncated) {
      BusyMarkToastOverlay.show(
        context,
        message: context.l10n.workspaceReplaceIssueTruncated,
        priority: BusyMarkToastPriority.high,
      );
      return;
    }
    final nextText = preview.apply();
    final selectionOffset = _controller.fullSelection.extentOffset
        .clamp(0, nextText.length)
        .toInt();
    _applyFullEditingValue(
      TextEditingValue(
        text: nextText,
        selection: TextSelection.collapsed(offset: selectionOffset),
      ),
    );
    _refreshSearch();
  }

  void _revealSearchMatch(SourceSearchMatch? initialMatch) {
    var match = initialMatch;
    if (match == null) {
      setState(() {
        _controller.setSearchResult(_searchController.result);
      });
      return;
    }
    if (match.hidden) {
      _unfoldSourceRange(match.fullStart, match.fullEnd);
    }
    final line = _controller.document.lineIndex.lineNumberAtOffset(
      match.fullStart,
    );
    _controller.fullSelection = TextSelection(
      baseOffset: match.fullStart,
      extentOffset: match.fullEnd,
    );
    _focusNode.requestFocus();
    _controller.setSearchResult(_searchController.result);
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animateScrollToLine(line);
    });
  }

  void _recomputeFoldRegions({bool resetCollapsed = false}) {
    final next = _controller.sourceFeaturesDegraded
        ? const <SourceFoldRegion>[]
        : sourceFoldRegions(_controller.fullText, _controller.language);
    final validKeys = {for (final region in next) region.key};
    if (resetCollapsed) {
      _foldedRegionKeys.clear();
    } else {
      final preservedKeys = {
        for (final region in _controller.foldedRegions)
          if (validKeys.contains(region.key)) region.key,
      };
      if (preservedKeys.isNotEmpty) {
        _foldedRegionKeys
          ..clear()
          ..addAll(preservedKeys);
      } else {
        _foldedRegionKeys.removeWhere((key) => !validKeys.contains(key));
      }
    }
    _foldRegions = next;
    _applyFoldedRegions();
  }

  void _applyFoldedRegions() {
    _controller.setFoldedRegions([
      for (final region in _foldRegions)
        if (_foldedRegionKeys.contains(region.key)) region,
    ]);
  }

  void _toggleFold(SourceFoldRegion region) {
    setState(() {
      if (_foldedRegionKeys.contains(region.key)) {
        _foldedRegionKeys.remove(region.key);
      } else {
        _foldedRegionKeys.add(region.key);
      }
      _applyFoldedRegions();
      _refreshSearch(currentIndex: _searchController.result.currentMatchIndex);
    });
    _publishSessionState();
  }

  void _unfoldSourceLine(int line) {
    final region = collapsedRegionContainingLine(
      _controller.fullText,
      _controller.language,
      _foldedRegionKeys,
      line,
    );
    if (region == null) {
      return;
    }
    setState(() {
      _foldedRegionKeys.remove(region.key);
      _applyFoldedRegions();
      _refreshSearch(currentIndex: _searchController.result.currentMatchIndex);
    });
  }

  void _unfoldSourceRange(int start, int end) {
    final before = _foldedRegionKeys.length;
    _foldedRegionKeys.removeWhere((key) {
      return _controller.foldedRegions.any((region) {
        if (region.key != key) {
          return false;
        }
        return region.hiddenStartOffset <= end &&
            start <= region.hiddenEndOffset;
      });
    });
    if (_foldedRegionKeys.length == before) {
      return;
    }
    setState(() {
      _applyFoldedRegions();
      _refreshSearch(currentIndex: _searchController.result.currentMatchIndex);
    });
  }

  void _handleSourceChanged({
    _SourceEditOrigin origin = _SourceEditOrigin.userTyping,
  }) {
    _replacementWorker.cancel();
    // Sidebar offsets belong to the pre-edit document. Once the user edits,
    // resume normal search on the new text instead of awaiting the old range.
    _requestedSearchRange = null;
    _searchNavigationFailed = false;
    final visibleEdit = _controller.lastVisibleEdit;
    final selection = _controller.fullSelection;
    final previousSelection =
        _controller.lastFullSelectionBeforeEdit ?? selection;
    final undoGroup =
        origin == _SourceEditOrigin.paste ||
            origin == _SourceEditOrigin.spellingCorrection
        ? null
        : _undoGroupForSourceEdit(
            visibleEdit,
            previousSelection: previousSelection,
            selection: selection,
          );
    if (origin == _SourceEditOrigin.paste ||
        origin == _SourceEditOrigin.spellingCorrection) {
      _continuousSourceEdit = null;
    }
    final currentSearchIndex = _searchController.result.currentMatchIndex;
    final firstMatchIndex = _searchController.result.firstMatchIndex;
    _scheduleFoldRefresh();
    if (!_applyingSearchReplacement) {
      _refreshSearch(
        currentIndex: currentSearchIndex,
        firstMatchIndex: firstMatchIndex,
      );
    }
    final transactionalCallback = widget.onTransactionalChanged;
    if (transactionalCallback == null) {
      widget.onChanged(_controller.fullText, widget.filePath);
    } else {
      transactionalCallback(
        _controller.fullText,
        widget.filePath,
        previousSelection,
        selection,
        undoGroup,
      );
    }
    if (_autocompleteSuggestions.isNotEmpty) {
      _refreshAutocomplete();
    }
    if (mounted) {
      setState(() {});
    }
    if (visibleEdit != null && visibleEdit.fullDelta < 0) {
      _scheduleContentShrinkCorrection();
    }
    _publishSessionState();
  }

  void _scheduleContentShrinkCorrection() {
    if (_contentShrinkCorrectionScheduled) {
      return;
    }
    _contentShrinkCorrectionScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _contentShrinkCorrectionScheduled = false;
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      final position = _scrollController.position;
      final target = position.pixels
          .clamp(position.minScrollExtent, position.maxScrollExtent)
          .toDouble();
      if ((target - position.pixels).abs() > 0.5) {
        position.jumpTo(target);
      }
    });
  }

  void _scheduleFoldRefresh() {
    _foldRefreshDebounce?.cancel();
    _foldRefreshDebounce = Timer(const Duration(milliseconds: 100), () {
      if (!mounted) {
        return;
      }
      setState(_recomputeFoldRegions);
      _publishSessionState();
    });
  }

  void _showAutocomplete() {
    final suggestions = _autocompleteProvider.suggestions(
      document: _controller.document,
      fullOffset: _controller.fullSelection.extentOffset,
      context: widget.autocompleteContext,
      limit: 12,
    );
    setState(() {
      _autocompleteSuggestions = suggestions;
      _autocompleteSelection = 0;
    });
  }

  void _refreshAutocomplete() {
    final suggestions = _autocompleteProvider.suggestions(
      document: _controller.document,
      fullOffset: _controller.fullSelection.extentOffset,
      context: widget.autocompleteContext,
      limit: 12,
    );
    setState(() {
      _autocompleteSuggestions = suggestions;
      _autocompleteSelection = suggestions.isEmpty
          ? 0
          : _autocompleteSelection.clamp(0, suggestions.length - 1);
    });
  }

  void _moveAutocompleteSelection(int delta) {
    setState(() {
      _autocompleteSelection =
          (_autocompleteSelection + delta) % _autocompleteSuggestions.length;
    });
  }

  void _closeAutocomplete() {
    if (_autocompleteSuggestions.isEmpty) {
      return;
    }
    setState(() {
      _autocompleteSuggestions = const [];
      _autocompleteSelection = 0;
    });
  }

  void _applyAutocomplete(SourceAutocompleteSuggestion suggestion) {
    final value = _fullEditingValue();
    final offset = value.selection.extentOffset.clamp(0, value.text.length);
    final range = sourceAutocompleteReplacementRange(value.text, offset);
    final nextText = value.text.replaceRange(
      range.start,
      range.end,
      suggestion.insertText,
    );
    final nextOffset = range.start + suggestion.insertText.length;
    _autocompleteSuggestions = const [];
    _autocompleteSelection = 0;
    _applyFullEditingValue(
      TextEditingValue(
        text: nextText,
        selection: TextSelection.collapsed(offset: nextOffset),
      ),
    );
  }

  void _restoreSessionState() {
    final validKeys = {for (final region in _foldRegions) region.key};
    _foldedRegionKeys
      ..clear()
      ..addAll(widget.initialFoldedRegionKeys.where(validKeys.contains));
    _applyFoldedRegions();
    final selection = widget.initialSelection;
    if (selection != null) {
      _controller.fullSelection = TextSelection(
        baseOffset: selection.baseOffset
            .clamp(0, _controller.fullText.length)
            .toInt(),
        extentOffset: selection.extentOffset
            .clamp(0, _controller.fullText.length)
            .toInt(),
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      _scrollController.jumpTo(
        widget.initialScrollOffset
            .clamp(0, _scrollController.position.maxScrollExtent)
            .toDouble(),
      );
    });
  }

  void _publishSessionState() {
    if (_suppressSessionPublication) {
      return;
    }
    final snapshot = _sourceSessionSnapshot();
    if (snapshot.sameAs(_lastPublishedSession)) {
      return;
    }
    _lastPublishedSession = snapshot;
    widget.onSessionChanged?.call(
      snapshot.selection,
      snapshot.scrollOffset,
      snapshot.foldedRegionKeys,
    );
  }

  void _scheduleSessionPublication() {
    if (_suppressSessionPublication || _sessionPublicationScheduled) {
      return;
    }
    _sessionPublicationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sessionPublicationScheduled = false;
      if (mounted) {
        _publishSessionState();
      }
    });
  }

  _SourceSessionSnapshot _sourceSessionSnapshot() {
    return _SourceSessionSnapshot(
      selection: _controller.fullSelection,
      scrollOffset: _scrollController.hasClients ? _scrollController.offset : 0,
      foldedRegionKeys: Set.unmodifiable(_foldedRegionKeys),
    );
  }

  bool _suppressSessionPublication = false;

  void _withoutSessionPublication(VoidCallback callback) {
    final wasSuppressed = _suppressSessionPublication;
    _suppressSessionPublication = true;
    try {
      callback();
    } finally {
      _suppressSessionPublication = wasSuppressed;
    }
  }

  TextEditingValue _fullEditingValue() {
    return TextEditingValue(
      text: _controller.fullText,
      selection: _controller.fullSelection,
      composing: _controller.fullComposing,
    );
  }

  bool get _hasActiveComposition {
    final value = _controller.value;
    final composing = value.composing;
    return composing.isValid &&
        composing.isNormalized &&
        !composing.isCollapsed &&
        composing.end <= value.text.length;
  }

  void _applyFullEditingValue(
    TextEditingValue value, {
    _SourceEditOrigin origin = _SourceEditOrigin.userTyping,
  }) {
    _controller.setFullEditingValue(value);
    _focusNode.requestFocus();
    _handleSourceChanged(origin: origin);
  }

  void _applyOwnedUndoValue(TextEditingValue value) {
    _continuousSourceEdit = null;
    _controller.setFullEditingValue(value);
    _recomputeFoldRegions();
    _refreshSearch();
    setState(() {});
  }

  String? _undoGroupForSourceEdit(
    SourceVisibleEdit? edit, {
    required TextSelection previousSelection,
    required TextSelection selection,
  }) {
    if (edit == null ||
        !previousSelection.isValid ||
        !previousSelection.isCollapsed ||
        !selection.isValid ||
        !selection.isCollapsed) {
      _continuousSourceEdit = null;
      return null;
    }
    final insertedLength = edit.replacement.length;
    final removedLength = edit.replacedFullText.length;
    final kind = switch ((insertedLength, removedLength)) {
      (1, 0) => _SourceSimpleEditKind.typing,
      (0, 1) => _SourceSimpleEditKind.deletion,
      _ => null,
    };
    if (kind == null ||
        !_sourceEditSelectionIsContinuous(
          kind,
          edit,
          previousSelection,
          selection,
        )) {
      _continuousSourceEdit = null;
      return null;
    }
    final currentText = _controller.fullText;
    final oldText = currentText.replaceRange(
      edit.fullStart,
      edit.fullStart + insertedLength,
      edit.replacedFullText,
    );
    final now = DateTime.now();
    final previous = _continuousSourceEdit;
    final continuous =
        previous != null &&
        previous.kind == kind &&
        previous.newText == oldText &&
        previous.selection == previousSelection &&
        now.difference(previous.timestamp) < const Duration(seconds: 2);
    final group = continuous
        ? previous.group
        : 'source-${widget.documentId ?? widget.filePath ?? 'document'}-'
              '$_undoSessionId-${++_undoGroupSequence}';
    _continuousSourceEdit = _ContinuousSourceEdit(
      kind: kind,
      newText: currentText,
      selection: selection,
      timestamp: now,
      group: group,
    );
    return group;
  }

  bool _sourceEditSelectionIsContinuous(
    _SourceSimpleEditKind kind,
    SourceVisibleEdit edit,
    TextSelection previousSelection,
    TextSelection selection,
  ) {
    final previousCaret = previousSelection.extentOffset;
    final caret = selection.extentOffset;
    return switch (kind) {
      _SourceSimpleEditKind.typing =>
        previousCaret == edit.fullStart && caret == edit.fullStart + 1,
      _SourceSimpleEditKind.deletion =>
        (previousCaret == edit.fullStart || previousCaret == edit.fullEnd) &&
            caret == edit.fullStart,
    };
  }

  void _applyShortcutAction(BusyMarkEditorShortcutAction action) {
    switch (action) {
      case BusyMarkEditorShortcutAction.refineWithAi:
        unawaited(_runAiEdit());
        break;
      case BusyMarkEditorShortcutAction.copyPlainText:
        unawaited(_copyOrCutSource(cut: false));
        break;
      case BusyMarkEditorShortcutAction.bold:
        _applyInlineCommand(SourceInlineCommand.bold);
        break;
      case BusyMarkEditorShortcutAction.italic:
        _applyInlineCommand(SourceInlineCommand.italic);
        break;
      case BusyMarkEditorShortcutAction.underline:
        _applyInlineCommand(SourceInlineCommand.underline);
        break;
      case BusyMarkEditorShortcutAction.strikethrough:
        _applyInlineCommand(SourceInlineCommand.strikethrough);
        break;
      case BusyMarkEditorShortcutAction.inlineCode:
        _applyInlineCommand(SourceInlineCommand.code);
        break;
      case BusyMarkEditorShortcutAction.link:
        _applyInlineCommand(SourceInlineCommand.link);
        break;
      case BusyMarkEditorShortcutAction.paragraph:
        _applyBlockCommand(SourceBlockCommand.paragraph);
        break;
      case BusyMarkEditorShortcutAction.heading1:
        _applyBlockCommand(SourceBlockCommand.heading1);
        break;
      case BusyMarkEditorShortcutAction.heading2:
        _applyBlockCommand(SourceBlockCommand.heading2);
        break;
      case BusyMarkEditorShortcutAction.heading3:
        _applyBlockCommand(SourceBlockCommand.heading3);
        break;
      case BusyMarkEditorShortcutAction.heading4:
        _applyBlockCommand(SourceBlockCommand.heading4);
        break;
      case BusyMarkEditorShortcutAction.heading5:
        _applyBlockCommand(SourceBlockCommand.heading5);
        break;
      case BusyMarkEditorShortcutAction.heading6:
        _applyBlockCommand(SourceBlockCommand.heading6);
        break;
      case BusyMarkEditorShortcutAction.orderedList:
        _applyBlockCommand(SourceBlockCommand.orderedList);
        break;
      case BusyMarkEditorShortcutAction.unorderedList:
        _applyBlockCommand(SourceBlockCommand.unorderedList);
        break;
      case BusyMarkEditorShortcutAction.taskList:
        _applyBlockCommand(SourceBlockCommand.taskList);
        break;
      case BusyMarkEditorShortcutAction.toggleTask:
        _applyFullEditingValue(
          SourceCommands.toggleTaskChecked(_fullEditingValue()),
        );
        break;
      case BusyMarkEditorShortcutAction.indent:
        _indentSelection();
        break;
      case BusyMarkEditorShortcutAction.outdent:
        _outdentSelection();
        break;
      case BusyMarkEditorShortcutAction.blockquote:
        _applyFullEditingValue(
          SourceCommands.applyLinePrefix(_fullEditingValue(), '> '),
        );
        break;
      case BusyMarkEditorShortcutAction.codeBlock:
        _insertCodeBlock();
        break;
      case BusyMarkEditorShortcutAction.codeBlockLanguage:
        _insertCodeBlock(language: 'language');
        break;
      case BusyMarkEditorShortcutAction.image:
        _applyFullEditingValue(
          SourceCommands.insertImage(
            _fullEditingValue(),
            block: true,
            altPlaceholder: context.l10n.editorPlaceholderAltText,
          ),
        );
        break;
      case BusyMarkEditorShortcutAction.inlineImage:
        _applyFullEditingValue(
          SourceCommands.insertImage(
            _fullEditingValue(),
            block: false,
            altPlaceholder: context.l10n.editorPlaceholderAltText,
          ),
        );
        break;
      case BusyMarkEditorShortcutAction.table:
        _applyFullEditingValue(
          SourceCommands.insertTable(
            _fullEditingValue(),
            headerTextForColumn: context.l10n.tableHeaderNumber,
            cellText: context.l10n.tableCellDefault,
          ),
        );
        break;
      case BusyMarkEditorShortcutAction.htmlBlock:
        _applyFullEditingValue(
          SourceCommands.insertHtmlBlock(
            _fullEditingValue(),
            defaultContent: context.l10n.htmlContentDefault,
          ),
        );
        break;
      case BusyMarkEditorShortcutAction.thematicBreak:
        _applyFullEditingValue(
          SourceCommands.insertBlock(_fullEditingValue(), '\n---\n'),
        );
        break;
      case BusyMarkEditorShortcutAction.hardLineBreak:
        _applyFullEditingValue(
          SourceCommands.insertBlock(_fullEditingValue(), '  \n'),
        );
        break;
    }
  }

  _SourceClipboardOperationTarget _captureClipboardTarget() =>
      _SourceClipboardOperationTarget(
        documentId: widget.documentId ?? widget.filePath ?? '',
        filePath: widget.filePath,
        language: widget.language,
        format: _documentFormat,
        markdownMode: _destinationMarkdownMode,
        text: _controller.fullText,
        selection: _controller.fullSelection,
        composing: _controller.fullComposing,
      );

  bool _isClipboardTargetCurrent(_SourceClipboardOperationTarget target) =>
      mounted &&
      target.documentId == (widget.documentId ?? widget.filePath ?? '') &&
      target.filePath == widget.filePath &&
      target.language == widget.language &&
      target.format == _documentFormat &&
      target.markdownMode == _destinationMarkdownMode &&
      target.text == _controller.fullText &&
      target.selection == _controller.fullSelection &&
      target.composing == _controller.fullComposing &&
      !_hasActiveComposition;

  SourcePasteDocumentSnapshot _sourcePasteSnapshot(
    _SourceClipboardOperationTarget target,
  ) => SourcePasteDocumentSnapshot(
    expectedSource: target.text,
    selection: target.selection,
    format: target.format,
    markdownMode: target.markdownMode,
    filePath: target.filePath,
  );

  Future<bool> _copyOrCutSource({required bool cut}) async {
    if (_hasActiveComposition) return false;
    final target = _captureClipboardTarget();
    final selection = target.selection;
    if (!selection.isValid || selection.isCollapsed) return false;
    final start = selection.start.clamp(0, target.text.length).toInt();
    final end = selection.end.clamp(start, target.text.length).toInt();
    final selected = target.text.substring(start, end);
    final success = await _clipboard.write(
      RichClipboardData(
        text: selected,
        sourceText: selected,
        origin: _clipboardOrigin,
      ),
    );
    if (!success) {
      if (mounted) {
        BusyMarkToastOverlay.show(
          context,
          message: context.l10n.clipboardCopyFailed,
        );
      }
      return false;
    }
    widget.onClipboardCaptured?.call(
      BusyMarkClipboardCapture(
        kind: BusyMarkClipboardContentKind.text,
        text: selected,
        sourceText: selected,
        origin: _clipboardOrigin,
      ),
    );
    if (cut && _isClipboardTargetCurrent(target)) {
      _applyFullEditingValue(
        TextEditingValue(
          text: target.text.replaceRange(start, end, ''),
          selection: TextSelection.collapsed(offset: start),
        ),
      );
    }
    return true;
  }

  Future<ClipboardPasteResult> _pasteFromSystemClipboard(
    BusyMarkPasteMode mode,
  ) async {
    if (_hasActiveComposition) return ClipboardPasteResult.staleTarget;
    final onCaptured = widget.onClipboardCaptured;
    final target = _captureClipboardTarget();
    final data = await _clipboard.read();
    if (!_isClipboardTargetCurrent(target)) {
      return ClipboardPasteResult.staleTarget;
    }
    final snapshot = BusyMarkClipboardSnapshot.fromSystem(data);
    final outcome = await _pasteClipboardSnapshot(
      snapshot,
      mode: mode,
      target: target,
      systemIdentity: data,
    );
    if (outcome.result == ClipboardPasteResult.inserted && snapshot.external) {
      onCaptured?.call(
        outcome.capture ?? busyMarkClipboardCaptureFromSnapshot(snapshot),
      );
    }
    return outcome.result;
  }

  Future<BusyMarkEditorTextPasteAvailability>
  _readContextMenuPasteAvailability() async {
    if (_hasActiveComposition) {
      return BusyMarkEditorTextPasteAvailability.unavailable;
    }
    final target = _captureClipboardTarget();
    final first = await _clipboard.read();
    if (!_isClipboardTargetCurrent(target)) {
      return BusyMarkEditorTextPasteAvailability.unavailable;
    }
    final snapshot = BusyMarkClipboardSnapshot.fromSystem(first);
    final destination = switch (target.format) {
      SourceDocumentFormat.markdown => BusyMarkPasteDestination.markdownSource,
      SourceDocumentFormat.writersideXmlTopic =>
        BusyMarkPasteDestination.writersideXmlSource,
      SourceDocumentFormat.genericXml =>
        BusyMarkPasteDestination.genericXmlSource,
      SourceDocumentFormat.plainText => BusyMarkPasteDestination.plainSource,
    };
    const resolver = BusyMarkClipboardPasteResolver();
    final plainText = resolver
        .resolve(
          snapshot: snapshot,
          mode: BusyMarkPasteMode.plainText,
          destination: destination,
          markdownMode: target.markdownMode,
        )
        .candidates
        .isNotEmpty;
    final normalPlan = resolver.resolve(
      snapshot: snapshot,
      mode: BusyMarkPasteMode.normal,
      destination: destination,
      markdownMode: target.markdownMode,
    );
    var normal = false;
    var inspectNativeImage = false;
    candidates:
    for (final candidate in normalPlan.candidates) {
      if (candidate is BusyMarkStructuredPasteCandidate) {
        final preparation = _pasteEngine.prepareStructured(
          target: _sourcePasteSnapshot(target),
          fragment: candidate.fragment,
        );
        if (preparation is SourcePasteStop) break candidates;
        if (preparation is SourcePasteTryNext) continue;
        if (!_structuredMediaCanBePrepared(snapshot, candidate.fragment)) {
          continue;
        }
        normal = true;
        break candidates;
      }
      if (candidate is BusyMarkImagePasteCandidate) {
        normal = widget.assetIngestionService.canIngestMediaBytes(
          bytes: candidate.bytes,
          suggestedFileName: candidate.displayName ?? 'clipboard-image.png',
        );
        if (normal) break candidates;
        continue;
      }
      if (candidate is BusyMarkNativeImagePasteCandidate) {
        inspectNativeImage = true;
        break candidates;
      }
      normal = true;
      break candidates;
    }
    if (!normal && inspectNativeImage) {
      final input = widget.assetInputService ?? busyMarkAssetInputService;
      final files = await input.readClipboardImageFiles();
      Uint8List? png;
      if (files.isEmpty) png = await input.readClipboardImagePng();
      final second = await _clipboard.read();
      if (!_isClipboardTargetCurrent(target)) {
        return BusyMarkEditorTextPasteAvailability.unavailable;
      }
      normal =
          first.sameExternalIdentity(second) &&
          (files.isNotEmpty || (png != null && png.isNotEmpty));
    }
    return BusyMarkEditorTextPasteAvailability(
      normal: normal,
      plainText: plainText,
    );
  }

  bool _structuredMediaCanBePrepared(
    BusyMarkClipboardSnapshot snapshot,
    WysiwygClipboardFragment fragment,
  ) {
    if (fragment.mediaPaths.isEmpty) return true;
    return snapshot.mediaComplete &&
        fragment.mediaPaths.entries.every((entry) {
          final bytes = snapshot.mediaBytes[entry.key];
          return bytes != null &&
              widget.assetIngestionService.canIngestMediaBytes(
                bytes: bytes,
                suggestedFileName: p.basename(entry.value),
              );
        });
  }

  Future<ClipboardPasteResult> _pasteHistoryPayload(
    BusyMarkClipboardPayload payload, {
    required BusyMarkPasteMode mode,
  }) async {
    if (_hasActiveComposition) {
      return ClipboardPasteResult.staleTarget;
    }
    final onCaptured = widget.onClipboardCaptured;
    final target = _captureClipboardTarget();
    final outcome = await _pasteClipboardSnapshot(
      BusyMarkClipboardSnapshot.fromPayload(payload),
      mode: mode,
      target: target,
    );
    if (outcome.result == ClipboardPasteResult.inserted && payload.external) {
      onCaptured?.call(
        outcome.capture ??
            busyMarkClipboardCaptureFromSnapshot(
              BusyMarkClipboardSnapshot.fromPayload(payload),
            ),
      );
    }
    return outcome.result;
  }

  Future<({ClipboardPasteResult result, BusyMarkClipboardCapture? capture})>
  _pasteClipboardSnapshot(
    BusyMarkClipboardSnapshot snapshot, {
    required BusyMarkPasteMode mode,
    required _SourceClipboardOperationTarget target,
    RichClipboardData? systemIdentity,
  }) async {
    final destination = switch (target.format) {
      SourceDocumentFormat.markdown => BusyMarkPasteDestination.markdownSource,
      SourceDocumentFormat.writersideXmlTopic =>
        BusyMarkPasteDestination.writersideXmlSource,
      SourceDocumentFormat.genericXml =>
        BusyMarkPasteDestination.genericXmlSource,
      SourceDocumentFormat.plainText => BusyMarkPasteDestination.plainSource,
    };
    final plan = const BusyMarkClipboardPasteResolver().resolve(
      snapshot: snapshot,
      mode: mode,
      destination: destination,
      markdownMode: target.markdownMode,
    );
    if (plan.isEmpty) {
      return (result: ClipboardPasteResult.unsupported, capture: null);
    }
    for (final candidate in plan.candidates) {
      if (!_isClipboardTargetCurrent(target)) {
        return (result: ClipboardPasteResult.staleTarget, capture: null);
      }
      if (candidate is BusyMarkStructuredPasteCandidate) {
        final decoded = candidate.fragment;
        var fragment = decoded.rebase(target.filePath ?? '');
        var assets = const <IngestedAsset>[];
        if (decoded.mediaPaths.isNotEmpty) {
          if (!snapshot.mediaComplete) continue;
          final prepared = await _prepareRetainedClipboardMedia(
            decoded,
            snapshot,
            target,
          );
          if (prepared == null) {
            if (!_isClipboardTargetCurrent(target)) {
              return (result: ClipboardPasteResult.staleTarget, capture: null);
            }
            continue;
          }
          fragment = prepared.fragment;
          assets = prepared.assets;
        }
        final preparation = _pasteEngine.prepareStructured(
          target: _sourcePasteSnapshot(target),
          fragment: fragment,
        );
        if (preparation is SourcePasteTryNext) {
          await _deleteUncommittedClipboardAssets(assets);
          continue;
        }
        if (preparation is SourcePasteStop) {
          await _deleteUncommittedClipboardAssets(assets);
          return (result: ClipboardPasteResult.unsupported, capture: null);
        }
        final edit = (preparation as SourcePasteReady).edit;
        final result = _insertClipboardText(
          target,
          edit.replacement,
          replacementStart: edit.start,
          replacementEnd: edit.end,
          resultingSelectionOffset: edit.caretOffset,
        );
        if (result != ClipboardPasteResult.inserted) {
          await _deleteUncommittedClipboardAssets(assets);
        }
        if (result == ClipboardPasteResult.inserted) {
          await _finalizeInsertedAssets(assets);
          return (result: result, capture: null);
        }
        return (result: result, capture: null);
      }
      if (candidate is BusyMarkImagePasteCandidate) {
        final result = await _pasteImageBytes(
          candidate.bytes,
          suggestedFileName: candidate.displayName ?? 'clipboard-image.png',
          target: target,
        );
        if (result == ClipboardPasteResult.inserted) {
          return (result: result, capture: null);
        }
        if (result == ClipboardPasteResult.staleTarget) {
          return (result: result, capture: null);
        }
        continue;
      }
      if (candidate is BusyMarkNativeImagePasteCandidate) {
        final native = await _pasteNativeClipboardImage(
          target,
          systemIdentity!,
        );
        return (result: native.result, capture: native.capture);
      }
      final text = switch (candidate) {
        BusyMarkPlainTextPasteCandidate(:final text) => text,
        BusyMarkSourceTextPasteCandidate(:final text) => text,
        _ => null,
      };
      if (text == null) continue;
      if (mode == BusyMarkPasteMode.normal &&
          candidate is BusyMarkPlainTextPasteCandidate &&
          _formatSupportsImages(target.format)) {
        final path = busyMarkLocalImagePathFromClipboardText(text);
        if (path != null) {
          Uint8List? retainedBytes;
          final result = await _pasteImageFile(
            path,
            target: target,
            onInserted: (value) => retainedBytes = value,
          );
          if (result == ClipboardPasteResult.inserted) {
            return (
              result: result,
              capture: retainedBytes == null
                  ? null
                  : busyMarkClipboardCaptureFromSnapshot(
                      snapshot,
                      imageBytes: retainedBytes,
                      imageMimeType: _sourceClipboardImageMimeType(path),
                      imageDisplayName: p.basename(path),
                    ),
            );
          }
          if (result == ClipboardPasteResult.staleTarget) {
            return (result: result, capture: null);
          }
        }
      }
      final result = _insertClipboardText(target, text);
      return (result: result, capture: null);
    }
    return (
      result: _isClipboardTargetCurrent(target)
          ? ClipboardPasteResult.unsupported
          : ClipboardPasteResult.staleTarget,
      capture: null,
    );
  }

  bool _formatSupportsImages(SourceDocumentFormat format) =>
      format == SourceDocumentFormat.markdown ||
      format == SourceDocumentFormat.writersideXmlTopic;

  Future<ClipboardPasteResult> _pasteImageFile(
    String sourcePath, {
    required _SourceClipboardOperationTarget target,
    ValueChanged<Uint8List>? onInserted,
  }) async {
    try {
      final snapshot = await widget.assetIngestionService.ingestFileSnapshot(
        sourcePath: sourcePath,
        request: _assetIngestionRequest,
        origin: AssetIngestionOrigin.clipboardImageFile,
      );
      final result = await _insertIngestedImage(snapshot.asset, target);
      if (result == ClipboardPasteResult.inserted) {
        onInserted?.call(snapshot.bytes);
      }
      return result;
    } on AssetSaveRequiredException {
      widget.onAssetSaveRequired?.call();
      return _isClipboardTargetCurrent(target)
          ? ClipboardPasteResult.unsupported
          : ClipboardPasteResult.staleTarget;
    } on AssetIngestionException {
      return _isClipboardTargetCurrent(target)
          ? ClipboardPasteResult.unsupported
          : ClipboardPasteResult.staleTarget;
    } on FileSystemException {
      return _isClipboardTargetCurrent(target)
          ? ClipboardPasteResult.unsupported
          : ClipboardPasteResult.staleTarget;
    }
  }

  Future<ClipboardPasteResult> _pasteImageBytes(
    Uint8List bytes, {
    required String suggestedFileName,
    required _SourceClipboardOperationTarget target,
  }) async {
    try {
      final asset = await widget.assetIngestionService.ingestBytes(
        bytes: bytes,
        suggestedFileName: suggestedFileName,
        request: _assetIngestionRequest,
        origin: AssetIngestionOrigin.screenshotPaste,
      );
      return await _insertIngestedImage(asset, target);
    } on AssetSaveRequiredException {
      widget.onAssetSaveRequired?.call();
      return _isClipboardTargetCurrent(target)
          ? ClipboardPasteResult.unsupported
          : ClipboardPasteResult.staleTarget;
    } on AssetIngestionException {
      return _isClipboardTargetCurrent(target)
          ? ClipboardPasteResult.unsupported
          : ClipboardPasteResult.staleTarget;
    } on FileSystemException {
      return _isClipboardTargetCurrent(target)
          ? ClipboardPasteResult.unsupported
          : ClipboardPasteResult.staleTarget;
    }
  }

  Future<ClipboardPasteResult> _insertIngestedImage(
    IngestedAsset asset,
    _SourceClipboardOperationTarget target,
  ) async {
    if (!_isClipboardTargetCurrent(target)) {
      await _deleteUncommittedClipboardAssets([asset]);
      return ClipboardPasteResult.staleTarget;
    }
    final reference = switch (target.format) {
      SourceDocumentFormat.markdown => SourceCommands.imageReference(
        alt: context.l10n.image,
        sourceReference: asset.markdownPath,
      ),
      SourceDocumentFormat.writersideXmlTopic =>
        SourceCommands.writersideImageReference(
          alt: context.l10n.image,
          sourceReference: asset.markdownPath,
        ),
      SourceDocumentFormat.genericXml || SourceDocumentFormat.plainText => null,
    };
    if (reference == null) {
      await _deleteUncommittedClipboardAssets([asset]);
      return ClipboardPasteResult.unsupported;
    }
    final result = _insertClipboardText(target, reference);
    if (result != ClipboardPasteResult.inserted) {
      await _deleteUncommittedClipboardAssets([asset]);
    } else {
      await _finalizeInsertedAssets([asset]);
    }
    return result;
  }

  Future<({ClipboardPasteResult result, BusyMarkClipboardCapture? capture})>
  _pasteNativeClipboardImage(
    _SourceClipboardOperationTarget target,
    RichClipboardData first,
  ) async {
    final input = widget.assetInputService ?? busyMarkAssetInputService;
    final files = await input.readClipboardImageFiles();
    Uint8List? png;
    if (files.isEmpty) png = await input.readClipboardImagePng();
    final second = await _clipboard.read();
    if (!_isClipboardTargetCurrent(target) ||
        !first.sameExternalIdentity(second)) {
      return (result: ClipboardPasteResult.staleTarget, capture: null);
    }
    if (files.isNotEmpty) {
      Uint8List? bytes;
      final result = await _pasteImageFile(
        files.first,
        target: target,
        onInserted: (value) => bytes = value,
      );
      return (
        result: result,
        capture: result == ClipboardPasteResult.inserted && bytes != null
            ? busyMarkClipboardCaptureFromSnapshot(
                BusyMarkClipboardSnapshot.fromSystem(first),
                imageBytes: bytes,
                imageMimeType: _sourceClipboardImageMimeType(files.first),
                imageDisplayName: p.basename(files.first),
              )
            : null,
      );
    }
    if (png == null || png.isEmpty) {
      return (result: ClipboardPasteResult.unsupported, capture: null);
    }
    final name = 'screenshot-${DateTime.now().millisecondsSinceEpoch}.png';
    final result = await _pasteImageBytes(
      png,
      suggestedFileName: name,
      target: target,
    );
    return (
      result: result,
      capture: result == ClipboardPasteResult.inserted
          ? busyMarkClipboardCaptureFromSnapshot(
              BusyMarkClipboardSnapshot.fromSystem(first),
              imageBytes: png,
              imageMimeType: 'image/png',
              imageDisplayName: name,
            )
          : null,
    );
  }

  Future<({WysiwygClipboardFragment fragment, List<IngestedAsset> assets})?>
  _prepareRetainedClipboardMedia(
    WysiwygClipboardFragment fragment,
    BusyMarkClipboardSnapshot snapshot,
    _SourceClipboardOperationTarget target,
  ) async {
    final destinations = <String, String>{};
    final assets = <IngestedAsset>[];
    try {
      for (final entry in fragment.mediaPaths.entries) {
        final bytes = snapshot.mediaBytes[entry.key];
        if (bytes == null || bytes.isEmpty) {
          await _deleteUncommittedClipboardAssets(assets);
          return null;
        }
        final asset = await widget.assetIngestionService.ingestMediaBytes(
          bytes: bytes,
          suggestedFileName: p.basename(entry.value),
          request: _assetIngestionRequest,
          origin: AssetIngestionOrigin.clipboardImageFile,
        );
        assets.add(asset);
        if (!_isClipboardTargetCurrent(target)) {
          await _deleteUncommittedClipboardAssets(assets);
          return null;
        }
        destinations[entry.key] = asset.markdownPath;
      }
      return (
        fragment: fragment.rebase(
          widget.filePath ?? '',
          mediaDestinations: destinations,
        ),
        assets: List<IngestedAsset>.unmodifiable(assets),
      );
    } on AssetSaveRequiredException {
      await _deleteUncommittedClipboardAssets(assets);
      widget.onAssetSaveRequired?.call();
      return null;
    } on AssetIngestionException {
      await _deleteUncommittedClipboardAssets(assets);
      return null;
    } on FileSystemException {
      await _deleteUncommittedClipboardAssets(assets);
      return null;
    }
  }

  AssetIngestionRequest get _assetIngestionRequest => AssetIngestionRequest(
    documentFilePath: widget.filePath ?? '',
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

  Future<void> _deleteUncommittedClipboardAssets(
    Iterable<IngestedAsset> assets,
  ) async {
    await widget.assetIngestionService.rollbackAll(assets);
  }

  Future<void> _finalizeInsertedAssets(Iterable<IngestedAsset> assets) async {
    try {
      await widget.assetIngestionService.commitAll(assets);
    } on Object catch (error) {
      // Insertion already succeeded. A stale pending record safely protects
      // the referenced file; rolling it back would corrupt document content.
      if (!mounted) return;
      BusyMarkToastOverlay.show(
        context,
        message: error is AssetIngestionException
            ? error.message
            : context.l10n.clipboardUnavailable,
        priority: BusyMarkToastPriority.high,
      );
    }
  }

  ClipboardPasteResult _insertClipboardText(
    _SourceClipboardOperationTarget target,
    String text, {
    int? replacementStart,
    int? replacementEnd,
    int? resultingSelectionOffset,
  }) {
    if (!_isClipboardTargetCurrent(target)) {
      return ClipboardPasteResult.staleTarget;
    }
    final selection = target.selection.isValid
        ? target.selection
        : TextSelection.collapsed(offset: target.text.length);
    final start = (replacementStart ?? selection.start)
        .clamp(0, target.text.length)
        .toInt();
    final end = (replacementEnd ?? selection.end)
        .clamp(start, target.text.length)
        .toInt();
    _applyFullEditingValue(
      TextEditingValue(
        text: target.text.replaceRange(start, end, text),
        selection: TextSelection.collapsed(
          offset: resultingSelectionOffset ?? start + text.length,
        ),
      ),
      origin: _SourceEditOrigin.paste,
    );
    return ClipboardPasteResult.inserted;
  }

  BusyMarkClipboardOrigin get _clipboardOrigin {
    final path = widget.filePath;
    final documentId = widget.documentId ?? path ?? 'untitled';
    return BusyMarkClipboardOrigin(
      documentId: documentId,
      documentName: path == null || p.basename(path).isEmpty
          ? documentId
          : p.basename(path),
      documentPath: path,
    );
  }

  void _applyInlineCommand(SourceInlineCommand command) {
    _applyFullEditingValue(
      SourceCommands.applyInlineCommand(
        _fullEditingValue(),
        command,
        placeholder: command == SourceInlineCommand.code
            ? context.l10n.editorPlaceholderCode
            : context.l10n.editorPlaceholderText,
      ),
    );
  }

  void _applyBlockCommand(SourceBlockCommand command) {
    _applyFullEditingValue(
      SourceCommands.applyBlockCommand(_fullEditingValue(), command),
    );
  }

  void _indentSelection() {
    _applyFullEditingValue(SourceCommands.indentSelection(_fullEditingValue()));
  }

  void _outdentSelection() {
    _applyFullEditingValue(
      SourceCommands.outdentSelection(_fullEditingValue()),
    );
  }

  void _insertCodeBlock({String language = ''}) {
    _applyFullEditingValue(
      SourceCommands.insertCodeFence(
        _fullEditingValue(),
        language: language,
        contentPlaceholder: context.l10n.editorPlaceholderCode,
      ),
    );
  }

  void _insertTab() {
    _applyFullEditingValue(SourceCommands.insertTab(_fullEditingValue()));
  }

  void _replaceController({
    required String text,
    required SourceSyntaxLanguage language,
  }) {
    _continuousSourceEdit = null;
    final previous = _controller;
    _controller = BusyMarkSourceController(text: text, language: language);
    _controller.addListener(_handleControllerActivity);
    _resetUndoHistory();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      previous.dispose();
    });
  }

  void _resetUndoHistory() {
    final previous = _undoController;
    _undoController = UndoHistoryController();
    previous.dispose();
  }

  TextStyle get _sourceTextStyle => TextStyle(
    fontFamily: BusyMarkTypography.monoFontFamily,
    fontFamilyFallback: BusyMarkTypography.monoFontFamilyFallback,
    fontSize: widget.editorFontSize,
    height: BusyMarkTypography.sourceEditorLineHeight,
    leadingDistribution: TextLeadingDistribution.even,
  );

  StrutStyle? _sourceStrutStyle({required bool folded}) {
    if (folded) {
      return null;
    }
    return StrutStyle.fromTextStyle(_sourceTextStyle);
  }

  double _sourceLineHeight(BuildContext context, StrutStyle? strutStyle) {
    final painter = TextPainter(
      text: TextSpan(text: ' ', style: _sourceTextStyle),
      strutStyle: strutStyle,
      textDirection: Directionality.of(context),
      textHeightBehavior: sourceTextHeightBehavior,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final metrics = painter.computeLineMetrics();
    painter.dispose();
    return metrics.isEmpty
        ? widget.editorFontSize * 1.45
        : metrics.first.height;
  }

  void _animateScrollToLine(int line) {
    if (!mounted || !_scrollController.hasClients) {
      return;
    }
    _scrollController.animateTo(
      _scrollOffsetForLine(line),
      duration: BusyMarkMotion.scroll,
      curve: Curves.easeOutCubic,
    );
  }

  void _jumpScrollToLine(int line) {
    if (!mounted || !_scrollController.hasClients) {
      return;
    }
    _scrollController.jumpTo(_scrollOffsetForLine(line));
  }

  double _scrollOffsetForLine(int line) {
    final textWidth = _textLayoutWidth();
    final strutStyle = _sourceStrutStyle(folded: _foldedRegionKeys.isNotEmpty);
    final lineHeight = _sourceLineHeight(context, strutStyle);
    final layouts = sourceLineLayoutEntries(
      context,
      controller: _controller,
      foldRegions: _foldRegions,
      collapsedRegionKeys: _foldedRegionKeys,
      textStyle: _sourceTextStyle,
      strutStyle: strutStyle,
      lineHeight: lineHeight,
      textWidth: textWidth,
    );
    final targetOffset = layouts
        .firstWhere(
          (entry) => entry.gutterLine.fullLine >= line,
          orElse: () => layouts.isEmpty
              ? const SourceLineLayoutEntry.empty()
              : layouts.last,
        )
        .top;
    return targetOffset
        .clamp(0.0, safeMaxScrollExtent(_scrollController))
        .toDouble();
  }

  double _textLayoutWidth() {
    final renderBox =
        _sourceEditorKey.currentContext?.findRenderObject() as RenderBox?;
    final editorWidth = renderBox?.size.width ?? 800;
    return math.max(
      1,
      editorWidth -
          _SourceEditorFrame.editorPaddingLeft -
          _SourceEditorFrame.editorPaddingRight,
    );
  }
}

class _SourceEditorFrame extends StatelessWidget {
  const _SourceEditorFrame({
    required this.controller,
    required this.scrollController,
    required this.horizontalScrollController,
    required this.wordWrap,
    required this.lineHeight,
    required this.textStyle,
    required this.strutStyle,
    required this.foldRegions,
    required this.collapsedRegionKeys,
    required this.diagnosticMarkers,
    required this.spellingAnnotations,
    required this.layoutCache,
    required this.intrinsicWidthCache,
    required this.onToggleFold,
    this.onVisibleLineChanged,
    required this.child,
  });

  static const double editorPaddingTop = BusyMarkSourceEditorMetrics.paddingTop;
  static const double editorPaddingLeft =
      BusyMarkSourceEditorMetrics.paddingLeft;
  static const double editorPaddingRight =
      BusyMarkSourceEditorMetrics.paddingRight;
  static const double _gutterWidth = BusyMarkSizes.sourceGutterWidth;

  final BusyMarkSourceEditingController controller;
  final ScrollController scrollController;
  final ScrollController horizontalScrollController;
  final bool wordWrap;
  final double lineHeight;
  final TextStyle textStyle;
  final StrutStyle? strutStyle;
  final List<SourceFoldRegion> foldRegions;
  final Set<String> collapsedRegionKeys;
  final List<SourceDiagnosticMarker> diagnosticMarkers;
  final List<SpellingAnnotation> spellingAnnotations;
  final SourceLineLayoutCache layoutCache;
  final SourceIntrinsicWidthCache intrinsicWidthCache;
  final ValueChanged<SourceFoldRegion> onToggleFold;
  final ValueChanged<int?>? onVisibleLineChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final editorWidth = math
            .max(
              BusyMarkStroke.hairline,
              constraints.maxWidth - _gutterWidth - BusyMarkStroke.hairline,
            )
            .toDouble();
        final viewportTextWidth = math
            .max(1, editorWidth - editorPaddingLeft - editorPaddingRight)
            .toDouble();
        final textWidth = wordWrap
            ? viewportTextWidth
            : math.max(
                viewportTextWidth,
                intrinsicWidthCache.resolve(
                  context,
                  controller: controller,
                  textStyle: textStyle,
                  strutStyle: strutStyle,
                ),
              );
        final editorContentWidth =
            textWidth + editorPaddingLeft + editorPaddingRight;
        int? visibleLineAt(double scrollOffset) {
          final layouts = layoutCache.resolve(
            context,
            controller: controller,
            foldRegions: foldRegions,
            collapsedRegionKeys: collapsedRegionKeys,
            textStyle: textStyle,
            strutStyle: strutStyle,
            lineHeight: lineHeight,
            textWidth: textWidth,
            diagnostics: diagnosticMarkers,
          );
          if (layouts.isEmpty) {
            return null;
          }
          final anchor = scrollOffset + lineHeight * 0.25;
          var low = 0;
          var high = layouts.length - 1;
          var result = 0;
          while (low <= high) {
            final middle = (low + high) >> 1;
            if (layouts[middle].top <= anchor) {
              result = middle;
              low = middle + 1;
            } else {
              high = middle - 1;
            }
          }
          return layouts[result].gutterLine.fullLine;
        }

        void reportVisibleLine(double scrollOffset) {
          onVisibleLineChanged?.call(visibleLineAt(scrollOffset));
        }

        if (onVisibleLineChanged != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              reportVisibleLine(safeScrollOffset(scrollController));
            }
          });
        }
        return DecoratedBox(
          decoration: BoxDecoration(color: colors.view),
          child: Row(
            textDirection: TextDirection.ltr,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: _gutterWidth,
                child: BusyMarkSourceGutter(
                  controller: controller,
                  scrollController: scrollController,
                  lineHeight: lineHeight,
                  textStyle: textStyle,
                  strutStyle: strutStyle,
                  textWidth: textWidth,
                  foldRegions: foldRegions,
                  collapsedRegionKeys: collapsedRegionKeys,
                  diagnosticMarkers: diagnosticMarkers,
                  onToggleFold: onToggleFold,
                  layoutCache: layoutCache,
                ),
              ),
              VerticalDivider(
                width: BusyMarkStroke.hairline,
                color: colors.subtleBorder,
              ),
              Expanded(
                child: ClipRect(
                  child: Scrollbar(
                    controller: horizontalScrollController,
                    thumbVisibility: !wordWrap,
                    notificationPredicate: (notification) =>
                        notification.metrics.axis == Axis.horizontal,
                    child: SingleChildScrollView(
                      key: const ValueKey('source-horizontal-scroll-view'),
                      controller: horizontalScrollController,
                      scrollDirection: Axis.horizontal,
                      physics: wordWrap
                          ? const NeverScrollableScrollPhysics()
                          : null,
                      child: SizedBox(
                        width: editorContentWidth,
                        height: constraints.maxHeight,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: _SourceRenderedTextLayer(
                                controller: controller,
                                scrollController: scrollController,
                                textStyle: textStyle,
                                strutStyle: strutStyle,
                                textWidth: textWidth,
                                spellingAnnotations: spellingAnnotations,
                              ),
                            ),
                            if (collapsedRegionKeys.isNotEmpty)
                              Positioned.fill(
                                child: _CollapsedSourceLineOverlay(
                                  controller: controller,
                                  scrollController: scrollController,
                                  lineHeight: lineHeight,
                                  textWidth: textWidth,
                                  textStyle: textStyle,
                                  strutStyle: strutStyle,
                                  foldRegions: foldRegions,
                                  collapsedRegionKeys: collapsedRegionKeys,
                                  diagnosticMarkers: diagnosticMarkers,
                                  spellingAnnotations: spellingAnnotations,
                                  layoutCache: layoutCache,
                                ),
                              ),
                            Positioned.fill(
                              child: NotificationListener<ScrollNotification>(
                                onNotification: (notification) {
                                  if (notification.metrics.axis ==
                                      Axis.vertical) {
                                    reportVisibleLine(
                                      notification.metrics.pixels,
                                    );
                                  }
                                  return false;
                                },
                                child: child,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

RenderEditable? _findSourceRenderEditable(RenderObject root) {
  if (root is RenderEditable) {
    return root;
  }
  RenderEditable? result;
  root.visitChildren((child) {
    result ??= _findSourceRenderEditable(child);
  });
  return result;
}

class _SourceRenderedTextLayer extends StatefulWidget {
  const _SourceRenderedTextLayer({
    required this.controller,
    required this.scrollController,
    required this.textStyle,
    required this.strutStyle,
    required this.textWidth,
    required this.spellingAnnotations,
  });

  final BusyMarkSourceEditingController controller;
  final ScrollController scrollController;
  final TextStyle textStyle;
  final StrutStyle? strutStyle;
  final double textWidth;
  final List<SpellingAnnotation> spellingAnnotations;

  @override
  State<_SourceRenderedTextLayer> createState() =>
      _SourceRenderedTextLayerState();
}

class _SourceRenderedTextLayerState extends State<_SourceRenderedTextLayer> {
  final _paragraphKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final renderedText = RichText(
      key: _paragraphKey,
      textDirection: TextDirection.ltr,
      text: widget.controller.buildSourceTextSpan(
        context: context,
        style: widget.textStyle,
        hideCollapsedStartLines: true,
      ),
      strutStyle: widget.strutStyle,
      textHeightBehavior: sourceTextHeightBehavior,
      textScaler: MediaQuery.textScalerOf(context),
      textWidthBasis: TextWidthBasis.parent,
    );
    return IgnorePointer(
      child: ClipRect(
        child: AnimatedBuilder(
          animation: Listenable.merge([
            widget.controller,
            widget.scrollController,
          ]),
          child: renderedText,
          builder: (context, child) {
            final scrollOffset = safeScrollOffset(widget.scrollController);
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: _SourceEditorFrame.editorPaddingTop - scrollOffset,
                  left: _SourceEditorFrame.editorPaddingLeft,
                  width: widget.textWidth,
                  child: CustomPaint(
                    foregroundPainter: _SourceSpellingPainter(
                      paragraphKey: _paragraphKey,
                      controller: widget.controller,
                      document: widget.controller.document,
                      annotations: widget.spellingAnnotations,
                      color: busyMarkStatusColor(
                        context,
                        BusyMarkStatusKind.error,
                      ),
                    ),
                    child: child!,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CollapsedSourceLineOverlay extends StatelessWidget {
  const _CollapsedSourceLineOverlay({
    required this.controller,
    required this.scrollController,
    required this.lineHeight,
    required this.textWidth,
    required this.textStyle,
    required this.strutStyle,
    required this.foldRegions,
    required this.collapsedRegionKeys,
    required this.diagnosticMarkers,
    required this.layoutCache,
    required this.spellingAnnotations,
  });

  final BusyMarkSourceEditingController controller;
  final ScrollController scrollController;
  final double lineHeight;
  final double textWidth;
  final TextStyle textStyle;
  final StrutStyle? strutStyle;
  final List<SourceFoldRegion> foldRegions;
  final Set<String> collapsedRegionKeys;
  final List<SourceDiagnosticMarker> diagnosticMarkers;
  final SourceLineLayoutCache layoutCache;
  final List<SpellingAnnotation> spellingAnnotations;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return AnimatedBuilder(
              animation: Listenable.merge([controller, scrollController]),
              builder: (context, _) {
                final layouts = layoutCache.resolve(
                  context,
                  controller: controller,
                  foldRegions: foldRegions,
                  collapsedRegionKeys: collapsedRegionKeys,
                  textStyle: textStyle,
                  strutStyle: strutStyle,
                  lineHeight: lineHeight,
                  textWidth: textWidth,
                  diagnostics: diagnosticMarkers,
                );
                final scrollOffset = safeScrollOffset(scrollController);
                final children = <Widget>[];
                final visibleRange = sourceVisibleLayoutRange(
                  layouts,
                  scrollOffset: scrollOffset,
                  viewportHeight: constraints.maxHeight,
                  overscan: lineHeight,
                );
                for (final layout in layouts.sublist(
                  visibleRange.start,
                  visibleRange.end,
                )) {
                  final line = layout.gutterLine;
                  if (!line.collapsed) {
                    continue;
                  }
                  final top = layout.top - scrollOffset;
                  if (line.fullLine < 1 ||
                      line.fullLine > controller.document.lineIndex.lineCount) {
                    continue;
                  }
                  final fullLine = controller.document.lineIndex.lineAt(
                    line.fullLine,
                  );
                  children.add(
                    Positioned(
                      top: top,
                      left: 0,
                      right: 0,
                      height: layout.height,
                      child: _CollapsedSourceLine(
                        text: _collapsedLineText(fullLine.text),
                        authoredLength: fullLine.text.trimRight().length,
                        sourceStart: fullLine.startOffset,
                        spellingAnnotations: spellingAnnotations,
                        height: lineHeight,
                        textStyle: textStyle,
                      ),
                    ),
                  );
                }
                return Stack(children: children);
              },
            );
          },
        ),
      ),
    );
  }
}

class _SourceSpellingPainter extends CustomPainter {
  const _SourceSpellingPainter({
    required this.paragraphKey,
    required this.controller,
    required this.document,
    required this.annotations,
    required this.color,
  });

  final GlobalKey paragraphKey;
  final BusyMarkSourceEditingController controller;
  final SourceDocument document;
  final List<SpellingAnnotation> annotations;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paragraph = paragraphKey.currentContext?.findRenderObject();
    if (paragraph is! RenderParagraph) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = BusyMarkStroke.hairline
      ..style = PaintingStyle.stroke;
    for (final annotation in annotations) {
      if (annotation.target is! SpellingSourceTarget ||
          annotation.end <= annotation.start ||
          busyMarkSourceSpellingUnderlineSuppressed(
            controller,
            TextRange(start: annotation.start, end: annotation.end),
          )) {
        continue;
      }
      final mapped = document.fullRangeToVisibleRange(
        annotation.start,
        annotation.end,
      );
      if (mapped.clippedByHiddenRange || mapped.range.isCollapsed) continue;
      final boxes = paragraph.getBoxesForSelection(
        TextSelection(
          baseOffset: mapped.range.start,
          extentOffset: mapped.range.end,
        ),
        boxHeightStyle: BusyMarkDocumentTextGeometry.selectionHeightStyle,
        boxWidthStyle: BusyMarkDocumentTextGeometry.selectionWidthStyle,
      );
      for (final box in boxes) {
        _paintSpellingWave(canvas, box.toRect(), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SourceSpellingPainter oldDelegate) =>
      oldDelegate.document != document ||
      oldDelegate.annotations != annotations ||
      oldDelegate.controller != controller ||
      oldDelegate.color != color;
}

@visibleForTesting
bool busyMarkSourceSpellingUnderlineSuppressed(
  BusyMarkSourceEditingController controller,
  TextRange range,
) {
  final composing = controller.fullComposing;
  return composing.isValid &&
      !composing.isCollapsed &&
      range.start < composing.end &&
      range.end > composing.start;
}

void _paintSpellingWave(Canvas canvas, Rect rect, Paint paint) {
  if (rect.width <= 0) return;
  final y = rect.bottom - 1;
  const halfWave = 2.0;
  final path = Path()..moveTo(rect.left, y);
  var x = rect.left;
  var up = true;
  while (x < rect.right) {
    x = math.min(rect.right, x + halfWave);
    path.lineTo(x, y + (up ? -1.25 : 1.25));
    up = !up;
  }
  canvas.drawPath(path, paint);
}

class _CollapsedSourceLine extends StatelessWidget {
  const _CollapsedSourceLine({
    required this.text,
    required this.height,
    required this.textStyle,
    required this.authoredLength,
    required this.sourceStart,
    required this.spellingAnnotations,
  });

  final String text;
  final double height;
  final TextStyle textStyle;
  final int authoredLength;
  final int sourceStart;
  final List<SpellingAnnotation> spellingAnnotations;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final background = Color.alphaBlend(
      colors.foreground.withValues(alpha: BusyMarkAlpha.sourceCollapsedLine),
      colors.view,
    );
    return DecoratedBox(
      decoration: BoxDecoration(color: background),
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.only(
              left: _SourceEditorFrame.editorPaddingLeft,
              right: _SourceEditorFrame.editorPaddingRight,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: CustomPaint(
                foregroundPainter: _CollapsedSpellingPainter(
                  text: text,
                  authoredLength: authoredLength,
                  sourceStart: sourceStart,
                  annotations: spellingAnnotations,
                  style: textStyle,
                  color: busyMarkStatusColor(context, BusyMarkStatusKind.error),
                  textScaler: MediaQuery.textScalerOf(context),
                ),
                child: Text(
                  text,
                  textDirection: TextDirection.ltr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle.copyWith(color: colors.mutedForeground),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CollapsedSpellingPainter extends CustomPainter {
  const _CollapsedSpellingPainter({
    required this.text,
    required this.authoredLength,
    required this.sourceStart,
    required this.annotations,
    required this.style,
    required this.color,
    required this.textScaler,
  });

  final String text;
  final int authoredLength;
  final int sourceStart;
  final List<SpellingAnnotation> annotations;
  final TextStyle style;
  final Color color;
  final TextScaler textScaler;

  @override
  void paint(Canvas canvas, Size size) {
    if (authoredLength <= 0 || size.width <= 0) return;
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: size.width);
    final wave = Paint()
      ..color = color
      ..strokeWidth = BusyMarkStroke.hairline
      ..style = PaintingStyle.stroke;
    for (final annotation in annotations) {
      if (annotation.target is! SpellingSourceTarget ||
          annotation.start < sourceStart ||
          annotation.end > sourceStart + authoredLength) {
        continue;
      }
      final boxes = painter.getBoxesForSelection(
        TextSelection(
          baseOffset: annotation.start - sourceStart,
          extentOffset: annotation.end - sourceStart,
        ),
      );
      for (final box in boxes) {
        _paintSpellingWave(canvas, box.toRect(), wave);
      }
    }
    painter.dispose();
  }

  @override
  bool shouldRepaint(covariant _CollapsedSpellingPainter oldDelegate) =>
      oldDelegate.text != text ||
      oldDelegate.authoredLength != authoredLength ||
      oldDelegate.sourceStart != sourceStart ||
      oldDelegate.annotations != annotations ||
      oldDelegate.style != style ||
      oldDelegate.color != color ||
      oldDelegate.textScaler != textScaler;
}

class _SourceSearchPanel extends StatefulWidget {
  const _SourceSearchPanel({
    required this.result,
    required this.onPrevious,
    required this.onNext,
    required this.onToggleCaseSensitive,
    required this.onToggleWholeWord,
    required this.onToggleRegex,
    required this.replacement,
    required this.canReplaceCurrent,
    required this.onReplacementChanged,
    required this.onReplaceCurrent,
    required this.onReplaceAndFindNext,
    required this.onReplaceAll,
    required this.onClose,
  });

  final SourceSearchResult result;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToggleCaseSensitive;
  final VoidCallback onToggleWholeWord;
  final VoidCallback onToggleRegex;
  final String replacement;
  final bool canReplaceCurrent;
  final ValueChanged<String> onReplacementChanged;
  final VoidCallback onReplaceCurrent;
  final VoidCallback onReplaceAndFindNext;
  final VoidCallback onReplaceAll;
  final VoidCallback onClose;

  @override
  State<_SourceSearchPanel> createState() => _SourceSearchPanelState();
}

class _SourceSearchPanelState extends State<_SourceSearchPanel> {
  late final TextEditingController _replacementController;

  @override
  void initState() {
    super.initState();
    _replacementController = TextEditingController(text: widget.replacement);
  }

  @override
  void didUpdateWidget(covariant _SourceSearchPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.replacement != oldWidget.replacement &&
        widget.replacement != _replacementController.text) {
      _replacementController.text = widget.replacement;
    }
  }

  @override
  void dispose() {
    _replacementController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final result = widget.result;
    final status = result.invalidRegex
        ? context.l10n.sourceSearchInvalidRegex
        : result.totalMatchCount == 0
        ? '0 / 0'
        : result.currentMatchIndex == null
        ? '– / ${result.totalMatchCount}'
        : '${result.currentMatchIndex! + 1} / ${result.totalMatchCount}';
    return BusyMarkSurface(
      color: colors.panel,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BusyMarkSpacing.xs,
          vertical: BusyMarkSpacing.xxs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (result.hasZeroLengthMatches)
              Text(
                context.l10n.sourceSearchZeroLengthUnsupported,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  status,
                  textDirection: result.invalidRegex
                      ? Directionality.of(context)
                      : TextDirection.ltr,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: result.invalidRegex
                        ? Theme.of(context).colorScheme.error
                        : colors.mutedForeground,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: BusyMarkSpacing.xs),
                _SearchPanelIconButton(
                  tooltip: context.l10n.sourceSearchPreviousMatch,
                  icon: YaruIcons.pan_up,
                  onPressed: result.totalMatchCount == 0
                      ? null
                      : widget.onPrevious,
                ),
                _SearchPanelIconButton(
                  tooltip: context.l10n.sourceSearchNextMatch,
                  icon: YaruIcons.pan_down,
                  onPressed: result.totalMatchCount == 0 ? null : widget.onNext,
                ),
                _SearchOptionButton(
                  label: 'Aa',
                  tooltip: context.l10n.sourceSearchCaseSensitive,
                  selected: result.options.caseSensitive,
                  onPressed: widget.onToggleCaseSensitive,
                ),
                _SearchOptionButton(
                  label: 'W',
                  tooltip: context.l10n.sourceSearchWholeWord,
                  selected: result.options.wholeWord,
                  onPressed: widget.onToggleWholeWord,
                ),
                _SearchOptionButton(
                  label: '.*',
                  tooltip: context.l10n.sourceSearchRegex,
                  selected: result.options.regex,
                  onPressed: widget.onToggleRegex,
                ),
                _SearchPanelIconButton(
                  tooltip: context.l10n.close,
                  icon: YaruIcons.window_close,
                  onPressed: widget.onClose,
                ),
              ],
            ),
            const SizedBox(height: BusyMarkSpacing.xxs),
            SizedBox(
              width: 410,
              height: 30,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('source-search-replacement'),
                      controller: _replacementController,
                      onChanged: widget.onReplacementChanged,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: context.l10n.sourceSearchReplacement,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: BusyMarkSpacing.sm,
                          vertical: BusyMarkSpacing.xs,
                        ),
                      ),
                    ),
                  ),
                  _SearchPanelIconButton(
                    tooltip: context.l10n.sourceSearchReplaceCurrent,
                    icon: BusyMarkGlyphs.edit,
                    onPressed:
                        result.totalMatchCount == 0 || !widget.canReplaceCurrent
                        ? null
                        : widget.onReplaceCurrent,
                  ),
                  _SearchPanelIconButton(
                    tooltip: context.l10n.sourceSearchReplaceAndFindNext,
                    icon: BusyMarkGlyphs.forwardFor(Directionality.of(context)),
                    onPressed:
                        result.totalMatchCount == 0 || !widget.canReplaceCurrent
                        ? null
                        : widget.onReplaceAndFindNext,
                  ),
                  _SearchPanelIconButton(
                    tooltip: context.l10n.sourceSearchReplaceAll,
                    icon: BusyMarkGlyphs.searchUnavailable,
                    onPressed:
                        result.options.query.isEmpty || result.invalidRegex
                        ? null
                        : widget.onReplaceAll,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchPanelIconButton extends StatelessWidget {
  const _SearchPanelIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return YaruIconButton(
      tooltip: tooltip,
      iconSize: 28,
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
    );
  }
}

class _SearchOptionButton extends StatelessWidget {
  const _SearchOptionButton({
    required this.label,
    required this.tooltip,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final String tooltip;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    Widget optionLabel() => Builder(
      builder: (context) => Text(
        label,
        textDirection: TextDirection.ltr,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: IconTheme.of(context).color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: YaruIconButton(
        tooltip: tooltip,
        iconSize: 28,
        isSelected: selected,
        onPressed: onPressed,
        icon: optionLabel(),
        selectedIcon: optionLabel(),
      ),
    );
  }
}

class _SourceAutocompletePopup extends StatelessWidget {
  const _SourceAutocompletePopup({
    required this.suggestions,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<SourceAutocompleteSuggestion> suggestions;
  final int selectedIndex;
  final ValueChanged<SourceAutocompleteSuggestion> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return Material(
      key: const ValueKey('source-autocomplete-popup'),
      color: colors.popover,
      elevation: BusyMarkElevation.surface,
      borderRadius: BorderRadius.circular(BusyMarkRadius.nativeHeaderButton),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: BusyMarkSizes.popupMenuMinWidth,
          maxWidth: BusyMarkSizes.languagePopupMaxWidth,
          maxHeight: 280,
        ),
        child: ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: BusyMarkSpacing.xs),
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            final selected = index == selectedIndex;
            return InkWell(
              key: ValueKey(
                'source-autocomplete-${suggestion.kind.name}-${suggestion.label}',
              ),
              onTap: () => onSelected(suggestion),
              child: ColoredBox(
                color: selected
                    ? colors.controlActive
                    : BusyMarkLinuxPalette.transparent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BusyMarkSpacing.md,
                    vertical: BusyMarkSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          suggestion.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textDirection: TextDirection.ltr,
                        ),
                      ),
                      const SizedBox(width: BusyMarkSpacing.sm),
                      Text(
                        suggestion.kind.name,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SourceLargeFileBanner extends StatelessWidget {
  const _SourceLargeFileBanner();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: BusyMarkSizes.dialogCompact),
      child: BusyMarkStatusBox(
        message: context.l10n.sourceLargeFileFeaturesPaused,
      ),
    );
  }
}

enum _SourceSimpleEditKind { typing, deletion }

class _ContinuousSourceEdit {
  const _ContinuousSourceEdit({
    required this.kind,
    required this.newText,
    required this.selection,
    required this.timestamp,
    required this.group,
  });

  final _SourceSimpleEditKind kind;
  final String newText;
  final TextSelection selection;
  final DateTime timestamp;
  final String group;
}

class _SourceSessionSnapshot {
  const _SourceSessionSnapshot({
    required this.selection,
    required this.scrollOffset,
    required this.foldedRegionKeys,
  });

  final TextSelection selection;
  final double scrollOffset;
  final Set<String> foldedRegionKeys;

  bool sameAs(_SourceSessionSnapshot? other) {
    return other != null &&
        selection == other.selection &&
        scrollOffset == other.scrollOffset &&
        setEquals(foldedRegionKeys, other.foldedRegionKeys);
  }
}

class _SourceClipboardOperationTarget {
  const _SourceClipboardOperationTarget({
    required this.documentId,
    required this.filePath,
    required this.language,
    required this.format,
    required this.markdownMode,
    required this.text,
    required this.selection,
    required this.composing,
  });

  final String documentId;
  final String? filePath;
  final SourceSyntaxLanguage language;
  final SourceDocumentFormat format;
  final MarkdownMode markdownMode;
  final String text;
  final TextSelection selection;
  final TextRange composing;
}

enum _SourceEditOrigin { userTyping, paste, spellingCorrection }

class _SourceClipboardInsertionTarget
    implements
        BusyMarkClipboardInsertionTarget,
        BusyMarkClipboardInsertionCapabilities {
  const _SourceClipboardInsertionTarget(this.state);

  final BusyMarkSourceEditorState state;

  @override
  String get documentId =>
      state.widget.documentId ?? state.widget.filePath ?? 'untitled';

  @override
  String get documentName {
    final path = state.widget.filePath;
    return path == null || p.basename(path).isEmpty
        ? documentId
        : p.basename(path);
  }

  @override
  String? get documentPath => state.widget.filePath;

  @override
  bool get editable => state.mounted && !state._hasActiveComposition;

  @override
  bool canPaste(
    BusyMarkClipboardPayload payload, {
    required BusyMarkPasteMode mode,
  }) {
    if (!editable) return false;
    final snapshot = BusyMarkClipboardSnapshot.fromPayload(payload);
    final destination = switch (state._documentFormat) {
      SourceDocumentFormat.markdown => BusyMarkPasteDestination.markdownSource,
      SourceDocumentFormat.writersideXmlTopic =>
        BusyMarkPasteDestination.writersideXmlSource,
      SourceDocumentFormat.genericXml =>
        BusyMarkPasteDestination.genericXmlSource,
      SourceDocumentFormat.plainText => BusyMarkPasteDestination.plainSource,
    };
    final plan = const BusyMarkClipboardPasteResolver().resolve(
      snapshot: snapshot,
      mode: mode,
      destination: destination,
      markdownMode: state._destinationMarkdownMode,
    );
    final target = state._captureClipboardTarget();
    for (final candidate in plan.candidates) {
      if (candidate is BusyMarkStructuredPasteCandidate) {
        final preparation = state._pasteEngine.prepareStructured(
          target: state._sourcePasteSnapshot(target),
          fragment: candidate.fragment,
        );
        if (preparation is SourcePasteStop) return false;
        if (preparation is SourcePasteTryNext) continue;
        if (!state._structuredMediaCanBePrepared(
          snapshot,
          candidate.fragment,
        )) {
          continue;
        }
        return true;
      }
      if (candidate is BusyMarkImagePasteCandidate) {
        if (state.widget.assetIngestionService.canIngestMediaBytes(
          bytes: candidate.bytes,
          suggestedFileName: candidate.displayName ?? 'clipboard-image.png',
        )) {
          return true;
        }
        continue;
      }
      if (candidate is BusyMarkNativeImagePasteCandidate) return false;
      return true;
    }
    return false;
  }

  @override
  Future<ClipboardPasteResult> paste(
    BusyMarkClipboardPayload payload, {
    required BusyMarkPasteMode mode,
  }) => state._pasteHistoryPayload(payload, mode: mode);

  @override
  void requestEditorFocus() => state._focusNode.requestFocus();
}

String _sourceClipboardImageMimeType(String path) =>
    switch (p.extension(path).toLowerCase()) {
      '.jpg' || '.jpeg' => 'image/jpeg',
      '.gif' => 'image/gif',
      '.webp' => 'image/webp',
      '.bmp' => 'image/bmp',
      '.svg' => 'image/svg+xml',
      _ => 'image/png',
    };

class _SourceEditorShortcutIntent extends Intent {
  const _SourceEditorShortcutIntent(this.action);

  final BusyMarkEditorShortcutAction action;
}

int _textOffsetForLine(String source, int lineNumber) {
  if (lineNumber <= 1) {
    return 0;
  }
  var currentLine = 1;
  for (var index = 0; index < source.length; index++) {
    if (source.codeUnitAt(index) == 10) {
      currentLine += 1;
      if (currentLine == lineNumber) {
        return index + 1;
      }
    }
  }
  return source.length;
}

String _collapsedLineText(String text) {
  final trimmed = text.trimRight();
  if (trimmed.isEmpty) {
    return '...';
  }
  return '$trimmed ...';
}
