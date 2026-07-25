import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show BoxHeightStyle, BoxWidthStyle, FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yaru/yaru.dart';

import '../../app/busymark_design.dart';
import '../../app/busymark_shortcuts.dart';
import '../../app/localization.dart';
import '../../core/diagnostic.dart';
import '../source_folding.dart';
import 'source_commands.dart';
import 'source_controller.dart';
import 'source_diagnostics.dart';
import 'source_gutter.dart';
import 'source_search.dart';

typedef BusyMarkSourceChanged =
    void Function(String fullText, String? sourceFilePath);

class BusyMarkSourceEditor extends StatefulWidget {
  const BusyMarkSourceEditor({
    super.key,
    required this.text,
    required this.language,
    required this.filePath,
    required this.diagnostics,
    required this.editorFontSize,
    required this.wordWrap,
    required this.searchActive,
    required this.searchOptions,
    required this.onSearchOptionsChanged,
    required this.onChanged,
    required this.onOpenSearch,
    required this.onCloseSearch,
  });

  final String text;
  final SourceSyntaxLanguage language;
  final String? filePath;
  final Iterable<Diagnostic> diagnostics;
  final double editorFontSize;
  final bool wordWrap;
  final bool searchActive;
  final SourceSearchOptions searchOptions;
  final ValueChanged<SourceSearchOptions> onSearchOptionsChanged;
  final BusyMarkSourceChanged onChanged;
  final VoidCallback onOpenSearch;
  final VoidCallback onCloseSearch;

  @override
  State<BusyMarkSourceEditor> createState() => BusyMarkSourceEditorState();
}

class BusyMarkSourceEditorState extends State<BusyMarkSourceEditor> {
  late BusyMarkSourceController _controller;
  late final FocusNode _focusNode;
  late final ScrollController _scrollController;
  late UndoHistoryController _undoController;
  final _sourceEditorKey = GlobalKey();
  final _foldedRegionKeys = <String>{};
  final _searchController = SourceSearchController();
  List<SourceFoldRegion> _foldRegions = const [];
  String _lastPath = '';

  @override
  void initState() {
    super.initState();
    _controller = BusyMarkSourceController(
      text: widget.text,
      language: widget.language,
    );
    _focusNode = FocusNode(onKeyEvent: _handleKeyEvent);
    _scrollController = ScrollController();
    _undoController = UndoHistoryController();
    _lastPath = widget.filePath ?? '';
    _recomputeFoldRegions(resetCollapsed: true);
    _syncSearchOptions();
  }

  @override
  void didUpdateWidget(covariant BusyMarkSourceEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final path = widget.filePath ?? '';
    final pathChanged = path != _lastPath;
    final languageChanged = widget.language != oldWidget.language;
    if (pathChanged) {
      _lastPath = path;
      _foldedRegionKeys.clear();
      _replaceController(text: widget.text, language: widget.language);
      _recomputeFoldRegions(resetCollapsed: true);
    } else if ((widget.text != oldWidget.text && !_focusNode.hasFocus) ||
        languageChanged) {
      _controller.replaceFullTextAndLanguage(
        text: widget.text,
        language: widget.language,
      );
      _recomputeFoldRegions(resetCollapsed: languageChanged);
    }
    if (widget.searchActive != oldWidget.searchActive ||
        widget.searchOptions != oldWidget.searchOptions ||
        widget.text != oldWidget.text ||
        pathChanged) {
      _syncSearchOptions();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    _undoController.dispose();
    _controller.dispose();
    super.dispose();
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
    final keyboard = HardwareKeyboard.instance;
    final key = event.logicalKey;
    if (BusyMarkAppShortcutActivators.search.accepts(event, keyboard)) {
      widget.onOpenSearch();
      return KeyEventResult.handled;
    }
    if (BusyMarkTextEditingShortcutActivators.insertIndentation.accepts(
      event,
      keyboard,
    )) {
      _insertTab();
      return KeyEventResult.handled;
    }
    if (BusyMarkTextEditingShortcutActivators.outdentSource.accepts(
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
    if (BusyMarkTextEditingShortcutActivators.escape.accepts(event, keyboard)) {
      widget.onCloseSearch();
      return KeyEventResult.handled;
    }
    final shortcutAction = BusyMarkEditorShortcutActivators.actionForKeyEvent(
      event,
      keyboard,
    );
    if (shortcutAction != null) {
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
              lineHeight: sourceLineHeight,
              textStyle: _sourceTextStyle,
              strutStyle: sourceStrutStyle,
              collapsedRegionKeys: _foldedRegionKeys,
              foldRegions: _foldRegions,
              diagnosticMarkers: markers,
              onToggleFold: _toggleFold,
              child: SizedBox(
                key: _sourceEditorKey,
                child: KeyedSubtree(
                  key: ValueKey(widget.filePath),
                  child: Shortcuts(
                    shortcuts: BusyMarkEditorShortcutActivators.intentMap(
                      _SourceEditorShortcutIntent.new,
                    ),
                    child: Actions(
                      actions: {
                        _SourceEditorShortcutIntent:
                            CallbackAction<_SourceEditorShortcutIntent>(
                              onInvoke: (intent) {
                                _applyShortcutAction(intent.action);
                                return null;
                              },
                            ),
                      },
                      child: TextField(
                        controller: _controller,
                        undoController: _undoController,
                        focusNode: _focusNode,
                        scrollController: _scrollController,
                        textDirection: TextDirection.ltr,
                        keyboardType: widget.wordWrap
                            ? TextInputType.multiline
                            : TextInputType.text,
                        autocorrect: false,
                        enableSuggestions: false,
                        smartDashesType: SmartDashesType.disabled,
                        smartQuotesType: SmartQuotesType.disabled,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        style: _sourceTextStyle,
                        strutStyle: sourceStrutStyle,
                        selectionHeightStyle: BoxHeightStyle.max,
                        selectionWidthStyle: BoxWidthStyle.tight,
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
                        onChanged: (_) => _handleSourceChanged(),
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
                onClose: widget.onCloseSearch,
              ),
            ),
        ],
      ),
    );
  }

  void _syncSearchOptions() {
    if (!widget.searchActive) {
      _searchController.setOptions(
        const SourceSearchOptions(),
        _controller.document,
      );
      _controller.setSearchResult(SourceSearchResult.empty);
      return;
    }
    _searchController.setOptions(widget.searchOptions, _controller.document);
    _controller.setSearchResult(_searchController.result);
  }

  void _refreshSearch({int? currentIndex}) {
    if (!widget.searchActive) {
      _controller.setSearchResult(SourceSearchResult.empty);
      return;
    }
    _searchController.refresh(_controller.document);
    _searchController.setCurrentMatchIndex(currentIndex);
    _controller.setSearchResult(_searchController.result);
  }

  void _updateSearchOptions(SourceSearchOptions options) {
    widget.onSearchOptionsChanged(options);
  }

  void _nextSearchMatch() {
    final match = _searchController.next(_controller.document);
    _revealSearchMatch(match);
  }

  void _previousSearchMatch() {
    final match = _searchController.previous(_controller.document);
    _revealSearchMatch(match);
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
      _searchController.refreshCurrent(_controller.document);
      _searchController.setCurrentMatchIndex(currentIndex);
      match = _searchController.result.currentMatch;
      if (match == null) {
        setState(() {
          _controller.setSearchResult(_searchController.result);
        });
        return;
      }
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
    setState(() {
      _recomputeFoldRegions();
      _refreshSearch(currentIndex: _searchController.result.currentMatchIndex);
    });
    widget.onChanged(_controller.fullText, widget.filePath);
  }

  TextEditingValue _fullEditingValue() {
    return TextEditingValue(
      text: _controller.fullText,
      selection: _controller.fullSelection,
    );
  }

  void _applyFullEditingValue(TextEditingValue value) {
    _controller.setFullEditingValue(value);
    _focusNode.requestFocus();
    _handleSourceChanged();
  }

  void _applyShortcutAction(BusyMarkEditorShortcutAction action) {
    switch (action) {
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
    height: BusyMarkTypography.codeLineHeight,
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
    required this.lineHeight,
    required this.textStyle,
    required this.strutStyle,
    required this.foldRegions,
    required this.collapsedRegionKeys,
    required this.diagnosticMarkers,
    required this.onToggleFold,
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
  final double lineHeight;
  final TextStyle textStyle;
  final StrutStyle? strutStyle;
  final List<SourceFoldRegion> foldRegions;
  final Set<String> collapsedRegionKeys;
  final List<SourceDiagnosticMarker> diagnosticMarkers;
  final ValueChanged<SourceFoldRegion> onToggleFold;
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
        final textWidth = math
            .max(1, editorWidth - editorPaddingLeft - editorPaddingRight)
            .toDouble();
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
                ),
              ),
              VerticalDivider(
                width: BusyMarkStroke.hairline,
                color: colors.subtleBorder,
              ),
              Expanded(
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
                      ),
                    ),
                    Positioned.fill(child: child),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
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
    return IgnorePointer(
      child: ClipRect(
        child: AnimatedBuilder(
          animation: Listenable.merge([controller, scrollController]),
          builder: (context, _) {
            final scrollOffset = safeScrollOffset(scrollController);
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: _SourceEditorFrame.editorPaddingTop - scrollOffset,
                  left: _SourceEditorFrame.editorPaddingLeft,
                  width: textWidth,
                  child: RichText(
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
  });

  final BusyMarkSourceEditingController controller;
  final ScrollController scrollController;
  final double lineHeight;
  final double textWidth;
  final TextStyle textStyle;
  final StrutStyle? strutStyle;
  final List<SourceFoldRegion> foldRegions;
  final Set<String> collapsedRegionKeys;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return AnimatedBuilder(
              animation: Listenable.merge([controller, scrollController]),
              builder: (context, _) {
                final layouts = sourceLineLayoutEntries(
                  context,
                  controller: controller,
                  foldRegions: foldRegions,
                  collapsedRegionKeys: collapsedRegionKeys,
                  textStyle: textStyle,
                  strutStyle: strutStyle,
                  lineHeight: lineHeight,
                  textWidth: textWidth,
                );
                final linesByNumber = {
                  for (final line in sourceLineInfos(controller.fullText))
                    line.number: line,
                };
                final scrollOffset = safeScrollOffset(scrollController);
                final children = <Widget>[];
                for (final layout in layouts) {
                  final line = layout.gutterLine;
                  if (!line.collapsed) {
                    continue;
                  }
                  final top = layout.top - scrollOffset;
                  if (top < -layout.height || top > constraints.maxHeight) {
                    continue;
                  }
                  final fullLine = linesByNumber[line.fullLine];
                  if (fullLine == null) {
                    continue;
                  }
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

class _SourceSearchPanel extends StatelessWidget {
  const _SourceSearchPanel({
    required this.result,
    required this.onPrevious,
    required this.onNext,
    required this.onToggleCaseSensitive,
    required this.onToggleWholeWord,
    required this.onToggleRegex,
    required this.onClose,
  });

  final SourceSearchResult result;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToggleCaseSensitive;
  final VoidCallback onToggleWholeWord;
  final VoidCallback onToggleRegex;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
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
        child: Row(
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
              onPressed: result.totalMatchCount == 0 ? null : onPrevious,
            ),
            _SearchPanelIconButton(
              tooltip: context.l10n.sourceSearchNextMatch,
              icon: YaruIcons.pan_down,
              onPressed: result.totalMatchCount == 0 ? null : onNext,
            ),
            _SearchOptionButton(
              label: 'Aa',
              tooltip: context.l10n.sourceSearchCaseSensitive,
              selected: result.options.caseSensitive,
              onPressed: onToggleCaseSensitive,
            ),
            _SearchOptionButton(
              label: 'W',
              tooltip: context.l10n.sourceSearchWholeWord,
              selected: result.options.wholeWord,
              onPressed: onToggleWholeWord,
            ),
            _SearchOptionButton(
              label: '.*',
              tooltip: context.l10n.sourceSearchRegex,
              selected: result.options.regex,
              onPressed: onToggleRegex,
            ),
            _SearchPanelIconButton(
              tooltip: context.l10n.close,
              icon: YaruIcons.window_close,
              onPressed: onClose,
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
