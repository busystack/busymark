import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:yaru/yaru.dart';

import '../../ai/ai_models.dart';
import '../../app/busymark_design.dart';
import '../../app/busymark_glyphs.dart';
import '../../app/busymark_shortcuts.dart';
import '../../app/busymark_toast.dart';
import '../../app/command_registry.dart';
import '../../app/localization.dart';
import '../../core/diagnostic.dart';
import '../../search/search_replace_service.dart';
import '../document_text_geometry.dart';
import '../editor_text_context_menu.dart';
import '../source_folding.dart';
import 'source_commands.dart';
import 'source_controller.dart';
import 'source_autocomplete.dart';
import 'source_diagnostics.dart';
import 'source_gutter.dart';
import 'source_search.dart';

typedef BusyMarkSourceChanged =
    void Function(String fullText, String? sourceFilePath);

typedef BusyMarkSourceSessionChanged =
    void Function(
      TextSelection selection,
      double scrollOffset,
      Set<String> foldedRegionKeys,
    );

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
  final String? Function()? onUndo;
  final String? Function()? onRedo;
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
  final _intrinsicWidthCache = _SourceIntrinsicWidthCache();
  final _lineLayoutCache = SourceLineLayoutCache();
  final _autocompleteProvider = const SourceAutocompleteProvider();
  List<SourceFoldRegion> _foldRegions = const [];
  List<SourceAutocompleteSuggestion> _autocompleteSuggestions = const [];
  var _autocompleteSelection = 0;
  String _lastPath = '';
  bool _horizontalCaretScheduled = false;
  bool _contentShrinkCorrectionScheduled = false;
  Timer? _searchDebounce;
  Timer? _foldRefreshDebounce;

  @override
  void initState() {
    super.initState();
    _controller = BusyMarkSourceController(
      text: widget.text,
      language: widget.language,
    );
    _focusNode = FocusNode(onKeyEvent: _handleKeyEvent);
    _scrollController = ScrollController();
    _horizontalScrollController = ScrollController();
    _undoController = UndoHistoryController();
    _lastPath = widget.documentId ?? widget.filePath ?? '';
    _recomputeFoldRegions(resetCollapsed: true);
    _restoreSessionState();
    _syncSearchOptions();
    _controller.addListener(_handleControllerActivity);
    _scrollController.addListener(_publishSessionState);
  }

  @override
  void didUpdateWidget(covariant BusyMarkSourceEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
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
    } else if (widget.text != _controller.fullText || languageChanged) {
      authoritativeDocumentChanged = true;
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
    _publishSessionState();
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
    _unfoldSourceLine(line);
    final textOffset = _textOffsetForLine(_controller.fullText, line);
    _focusNode.requestFocus();
    _controller.fullSelection = TextSelection.collapsed(offset: textOffset);
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
    _focusNode.requestFocus();
    _controller.fullSelection = TextSelection(
      baseOffset: start,
      extentOffset: end,
    );
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
    final commands =
        BusyMarkCommandRegistryScope.read(context) ??
        BusyMarkCommandCatalog.metadata;
    if (commands.shortcutAccepts(BusyMarkCommandIds.search, event, keyboard)) {
      widget.onOpenSearch();
      return KeyEventResult.handled;
    }
    if (commands.shortcutAccepts(
      BusyMarkCommandIds.textUndo,
      event,
      keyboard,
    )) {
      final text = widget.onUndo?.call();
      if (text != null) {
        _applyOwnedUndoText(text);
        return KeyEventResult.handled;
      }
    }
    if (commands.shortcutAccepts(
      BusyMarkCommandIds.textRedo,
      event,
      keyboard,
    )) {
      final text = widget.onRedo?.call();
      if (text != null) {
        _applyOwnedUndoText(text);
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
                                  commandId.startsWith('editor.'),
                              onCommand: (commandId) {
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
                                onRefineWithAi: widget.onAiEdit == null
                                    ? null
                                    : () => unawaited(_runAiEdit()),
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
              if (minimumFullOffset != null && result.matches.isNotEmpty) {
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
    if (_searchController.result.invalidRegex) {
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
    _applyFullEditingValue(
      TextEditingValue(
        text: nextText,
        selection: TextSelection(
          baseOffset: match.start,
          extentOffset: match.start + match.replacement.length,
        ),
      ),
    );
    final replacementEnd = match.start + match.replacement.length;
    if (findNext) {
      _refreshSearch(
        minimumFullOffset: replacementEnd,
        revealCurrentAfterRefresh: true,
      );
    } else {
      _refreshSearch(
        currentIndex: currentIndex,
        firstMatchIndex: _searchController.result.firstMatchIndex,
      );
    }
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
    final currentIndex = _searchController.result.currentMatchIndex;
    if (match.hidden) {
      _unfoldSourceRange(match.fullStart, match.fullEnd);
      _refreshSearch(currentIndex: currentIndex);
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

  void _handleSourceChanged() {
    _replacementWorker.cancel();
    final visibleEdit = _controller.lastVisibleEdit;
    final currentSearchIndex = _searchController.result.currentMatchIndex;
    final firstMatchIndex = _searchController.result.firstMatchIndex;
    _scheduleFoldRefresh();
    _refreshSearch(
      currentIndex: currentSearchIndex,
      firstMatchIndex: firstMatchIndex,
    );
    widget.onChanged(_controller.fullText, widget.filePath);
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
    widget.onSessionChanged?.call(
      _controller.fullSelection,
      _scrollController.hasClients ? _scrollController.offset : 0,
      Set.unmodifiable(_foldedRegionKeys),
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

  void _applyFullEditingValue(TextEditingValue value) {
    _controller.setFullEditingValue(value);
    _focusNode.requestFocus();
    _handleSourceChanged();
  }

  void _applyOwnedUndoText(String text) {
    _controller.replaceFullTextAndLanguage(
      text: text,
      language: widget.language,
    );
    _recomputeFoldRegions();
    _refreshSearch();
    setState(() {});
  }

  void _applyShortcutAction(BusyMarkEditorShortcutAction action) {
    switch (action) {
      case BusyMarkEditorShortcutAction.refineWithAi:
        unawaited(_runAiEdit());
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
      case BusyMarkEditorShortcutAction.pastePlainText:
        unawaited(_pastePlainText());
        break;
    }
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

  Future<void> _pastePlainText() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) {
      return;
    }
    final value = _fullEditingValue();
    final selection = value.selection;
    final nextText =
        selection.textBefore(value.text) +
        text +
        selection.textAfter(value.text);
    _applyFullEditingValue(
      TextEditingValue(
        text: nextText,
        selection: TextSelection.collapsed(
          offset: selection.start + text.length,
        ),
      ),
    );
  }

  void _replaceController({
    required String text,
    required SourceSyntaxLanguage language,
  }) {
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
  final SourceLineLayoutCache layoutCache;
  final _SourceIntrinsicWidthCache intrinsicWidthCache;
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

class _SourceIntrinsicWidthCache {
  Object? _document;
  SourceSyntaxLanguage? _language;
  TextStyle? _textStyle;
  StrutStyle? _strutStyle;
  TextScaler? _textScaler;
  double? _width;

  double resolve(
    BuildContext context, {
    required BusyMarkSourceEditingController controller,
    required TextStyle textStyle,
    required StrutStyle? strutStyle,
  }) {
    final document = controller.document;
    final textScaler = MediaQuery.textScalerOf(context);
    final cached = _width;
    if (cached != null &&
        identical(_document, document) &&
        _language == controller.language &&
        _textStyle == textStyle &&
        _strutStyle == strutStyle &&
        _textScaler == textScaler) {
      return cached;
    }
    final painter = TextPainter(
      text: controller.buildSourceTextSpan(
        context: context,
        style: textStyle,
        hideCollapsedStartLines: true,
      ),
      strutStyle: strutStyle,
      textDirection: TextDirection.ltr,
      textHeightBehavior: sourceTextHeightBehavior,
      textScaler: textScaler,
    )..layout();
    final width = math
        .max(1, painter.width + BusyMarkStroke.sourceCursor)
        .toDouble();
    painter.dispose();
    _document = document;
    _language = controller.language;
    _textStyle = textStyle;
    _strutStyle = strutStyle;
    _textScaler = textScaler;
    _width = width;
    return width;
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

class _SourceRenderedTextLayer extends StatelessWidget {
  const _SourceRenderedTextLayer({
    required this.controller,
    required this.scrollController,
    required this.textStyle,
    required this.strutStyle,
    required this.textWidth,
  });

  final BusyMarkSourceEditingController controller;
  final ScrollController scrollController;
  final TextStyle textStyle;
  final StrutStyle? strutStyle;
  final double textWidth;

  @override
  Widget build(BuildContext context) {
    final renderedText = RichText(
      textDirection: TextDirection.ltr,
      text: controller.buildSourceTextSpan(
        context: context,
        style: textStyle,
        hideCollapsedStartLines: true,
      ),
      strutStyle: strutStyle,
      textHeightBehavior: sourceTextHeightBehavior,
      textScaler: MediaQuery.textScalerOf(context),
      textWidthBasis: TextWidthBasis.parent,
    );
    return IgnorePointer(
      child: ClipRect(
        child: AnimatedBuilder(
          animation: scrollController,
          child: renderedText,
          builder: (context, child) {
            final scrollOffset = safeScrollOffset(scrollController);
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: _SourceEditorFrame.editorPaddingTop - scrollOffset,
                  left: _SourceEditorFrame.editorPaddingLeft,
                  width: textWidth,
                  child: child!,
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

class _CollapsedSourceLine extends StatelessWidget {
  const _CollapsedSourceLine({
    required this.text,
    required this.height,
    required this.textStyle,
  });

  final String text;
  final double height;
  final TextStyle textStyle;

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
    );
  }
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
        : '${(result.currentMatchIndex ?? 0) + 1} / ${result.totalMatchCount}';
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
                    onPressed: result.totalMatchCount == 0
                        ? null
                        : widget.onReplaceCurrent,
                  ),
                  _SearchPanelIconButton(
                    tooltip: context.l10n.sourceSearchReplaceAndFindNext,
                    icon: BusyMarkGlyphs.forwardFor(Directionality.of(context)),
                    onPressed: result.totalMatchCount == 0
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
