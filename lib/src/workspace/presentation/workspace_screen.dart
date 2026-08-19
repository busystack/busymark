import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:file_selector/file_selector.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yaru/yaru.dart';

import '../../ai/ai_edit_ui.dart';
import '../../app/app_settings.dart';
import '../../app/app_router.dart';
import '../../app/busymark_dialogs.dart';
import '../../app/busymark_design.dart';
import '../../app/busymark_glyphs.dart';
import '../../app/busymark_main_menu.dart';
import '../../app/busymark_search_field.dart';
import '../../app/busymark_shortcuts.dart';
import '../../app/localization.dart';
import '../../app/window_control_service.dart';
import '../../core/diagnostic.dart';
import '../../core/diagnostic_localizations.dart';
import '../../core/path_utils.dart' show slugForHeading;
import '../../core/uri_utils.dart';
import '../../editor/document_callout.dart';
import '../../editor/document_code_block.dart';
import '../../editor/document_layout.dart';
import '../../editor/document_list_marker.dart';
import '../../editor/document_surface.dart';
import '../../editor/document_text_geometry.dart';
import '../../editor/document_text_direction.dart';
import '../../editor/document_thematic_break.dart';
import '../../editor/markdown_image_view.dart';
import '../../editor/source/source_controller.dart';
import '../../editor/source/source_document.dart';
import '../../editor/source/source_editor.dart';
import '../../editor/source/source_search.dart';
import '../../editor/wysiwyg/wysiwyg_editor.dart';
import '../../feedback/presentation/feedback_dialog.dart';
import '../../export/markdown_pdf_export_ui.dart';
import '../../git/application/git_controller.dart';
import '../../git/domain/git_models.dart';
import '../../git/presentation/git_diff_viewer.dart';
import '../../git/presentation/git_file_status_colors.dart';
import '../../git/presentation/git_sidebar_tab.dart';
import '../../markdown/busymark_document.dart';
import '../../markdown/document_outline.dart';
import '../../markdown/markdown_model.dart';
import '../../markdown/markdown_parser.dart';
import '../../markdown/markdown_section_editor.dart';
import '../../markdown/markdown_toc_generator.dart';
import '../../markdown/preview_model.dart';
import '../../platform/linux_header_bar_service.dart';
import '../../visualization/visualization_card.dart';
import '../../visualization/visualization_models.dart';
import '../../writerside/writerside_model.dart';
import '../../writerside/writerside_instance_service.dart';
import '../../writerside/writerside_topic_creator.dart';
import '../../writerside/writerside_topic_removal_service.dart';
import '../workspace_controller.dart';
import '../workspace_glyphs.dart';
import '../workspace_model.dart';
import '../workspace_message.dart';
import '../workspace_safety.dart';
import '../workspace_tabs.dart';
import 'welcome_screen.dart';
import 'writerside_instance_dialog.dart';

final _outlineNavigationTargetProvider =
    NotifierProvider<
      _OutlineNavigationTargetController,
      _OutlineNavigationTarget?
    >(_OutlineNavigationTargetController.new);
final _outlineViewportTargetProvider =
    NotifierProvider<_OutlineViewportTargetController, _OutlineViewportTarget?>(
      _OutlineViewportTargetController.new,
    );
final _sourceNavigationTargetProvider =
    NotifierProvider<
      _SourceNavigationTargetController,
      _SourceNavigationTarget?
    >(_SourceNavigationTargetController.new);
final _workspaceSearchProvider =
    NotifierProvider<_WorkspaceSearchController, _WorkspaceSearchState>(
      _WorkspaceSearchController.new,
    );
final _searchNavigationTargetProvider =
    NotifierProvider<
      _SearchNavigationTargetController,
      _SearchNavigationTarget?
    >(_SearchNavigationTargetController.new);
final _sidebarShortcutRequestProvider =
    NotifierProvider<_SidebarShortcutRequestController, _SidebarTab?>(
      _SidebarShortcutRequestController.new,
    );

class _OutlineNavigationTargetController
    extends Notifier<_OutlineNavigationTarget?> {
  @override
  _OutlineNavigationTarget? build() => null;

  void set(_OutlineNavigationTarget? target) {
    state = target;
  }
}

class _OutlineViewportTargetController
    extends Notifier<_OutlineViewportTarget?> {
  @override
  _OutlineViewportTarget? build() => null;

  void set(_OutlineViewportTarget target) {
    if (state?.sameLocationAs(target) ?? false) {
      return;
    }
    state = target;
  }
}

class _SourceNavigationTargetController
    extends Notifier<_SourceNavigationTarget?> {
  @override
  _SourceNavigationTarget? build() => null;

  void set(_SourceNavigationTarget? target) {
    state = target;
  }
}

class _WorkspaceSearchController extends Notifier<_WorkspaceSearchState> {
  static const _debounceDelay = Duration(milliseconds: 120);

  Timer? _debounce;
  late Future<String> Function(String path) _loadText;
  var _request = 0;
  var _disposed = false;

  @override
  _WorkspaceSearchState build() {
    _loadText = ref.read(workspaceServiceProvider).loadText;
    ref.listen<WorkspaceState>(workspaceControllerProvider, (previous, next) {
      refresh(next);
    });
    ref.onDispose(() {
      _disposed = true;
      _request += 1;
      _debounce?.cancel();
    });
    return const _WorkspaceSearchState();
  }

  void set(_WorkspaceSearchState searchState) {
    final inputChanged =
        state.query != searchState.query ||
        state.caseSensitive != searchState.caseSensitive ||
        state.wholeWord != searchState.wholeWord ||
        state.regex != searchState.regex ||
        state.active != searchState.active;
    state = searchState.copyWith(
      matches: inputChanged ? const [] : state.matches,
      searching: false,
    );
    _schedule(ref.read(workspaceControllerProvider));
  }

  void refresh(WorkspaceState workspaceState) {
    if (!state.active || state.options.query.isEmpty) {
      return;
    }
    _schedule(workspaceState);
  }

  Future<bool> submit() async {
    _debounce?.cancel();
    final request = ++_request;
    final workspaceState = ref.read(workspaceControllerProvider);
    final options = state.options;
    if (!state.active ||
        options.query.isEmpty ||
        workspaceState.workspace == null) {
      return false;
    }
    state = state.copyWith(matches: const [], searching: true);
    await _runSearch(
      request: request,
      workspaceState: workspaceState,
      options: options,
    );
    return !_disposed && request == _request;
  }

  void _schedule(WorkspaceState workspaceState) {
    _debounce?.cancel();
    final request = ++_request;
    final workspace = workspaceState.workspace;
    final options = state.options;
    if (!state.active || options.query.isEmpty || workspace == null) {
      final clearMatches = options.query.isEmpty || workspace == null;
      if (state.searching || (clearMatches && state.matches.isNotEmpty)) {
        state = state.copyWith(
          matches: clearMatches ? const [] : state.matches,
          searching: false,
        );
      }
      return;
    }
    state = state.copyWith(matches: const [], searching: true);
    _debounce = Timer(_debounceDelay, () {
      _debounce = null;
      unawaited(
        _runSearch(
          request: request,
          workspaceState: workspaceState,
          options: options,
        ),
      );
    });
  }

  Future<void> _runSearch({
    required int request,
    required WorkspaceState workspaceState,
    required SourceSearchOptions options,
  }) async {
    try {
      final matches = await _loadWorkspaceSearchMatches(
        workspaceState,
        options,
        loadText: _loadText,
        isCancelled: () => _disposed || request != _request,
      );
      if (_disposed || request != _request) {
        return;
      }
      state = state.copyWith(matches: matches, searching: false);
    } on Object {
      if (_disposed || request != _request) {
        return;
      }
      state = state.copyWith(matches: const [], searching: false);
    }
  }
}

class _SearchNavigationTargetController
    extends Notifier<_SearchNavigationTarget?> {
  @override
  _SearchNavigationTarget? build() => null;

  void set(_SearchNavigationTarget? target) {
    state = target;
  }
}

class _SidebarShortcutRequestController extends Notifier<_SidebarTab?> {
  @override
  _SidebarTab? build() => null;

  void select(_SidebarTab tab) {
    state = tab;
  }

  void clear() {
    state = null;
  }
}

class _OutlineNavigationTarget {
  const _OutlineNavigationTarget({
    required this.workspaceId,
    required this.filePath,
    required this.headingId,
    required this.line,
    this.editorBlockId,
  });

  final String workspaceId;
  final String? filePath;
  final String headingId;
  final int? line;
  final String? editorBlockId;
}

class _OutlineViewportTarget {
  const _OutlineViewportTarget({
    required this.workspaceId,
    required this.filePath,
    required this.headingId,
    required this.sourceStartOffset,
    required this.editorBlockId,
  });

  final String workspaceId;
  final String? filePath;
  final String? headingId;
  final int? sourceStartOffset;
  final String? editorBlockId;

  bool sameLocationAs(_OutlineViewportTarget other) {
    return workspaceId == other.workspaceId &&
        filePath == other.filePath &&
        headingId == other.headingId &&
        sourceStartOffset == other.sourceStartOffset &&
        editorBlockId == other.editorBlockId;
  }
}

class _SourceNavigationTarget {
  const _SourceNavigationTarget({required this.filePath, required this.line});

  final String filePath;
  final int line;
}

class _WorkspaceSearchState {
  const _WorkspaceSearchState({
    this.active = false,
    this.query = '',
    this.caseSensitive = false,
    this.wholeWord = false,
    this.regex = false,
    this.matches = const [],
    this.searching = false,
  });

  final bool active;
  final String query;
  final bool caseSensitive;
  final bool wholeWord;
  final bool regex;
  final List<_WorkspaceSearchMatch> matches;
  final bool searching;

  SourceSearchOptions get options => SourceSearchOptions(
    query: query.trim(),
    caseSensitive: caseSensitive,
    wholeWord: wholeWord,
    regex: regex,
  );

  _WorkspaceSearchState copyWith({
    bool? active,
    String? query,
    bool? caseSensitive,
    bool? wholeWord,
    bool? regex,
    List<_WorkspaceSearchMatch>? matches,
    bool? searching,
  }) {
    return _WorkspaceSearchState(
      active: active ?? this.active,
      query: query ?? this.query,
      caseSensitive: caseSensitive ?? this.caseSensitive,
      wholeWord: wholeWord ?? this.wholeWord,
      regex: regex ?? this.regex,
      matches: matches ?? this.matches,
      searching: searching ?? this.searching,
    );
  }

  _WorkspaceSearchState withOptions(SourceSearchOptions options) {
    return copyWith(
      query: options.query,
      caseSensitive: options.caseSensitive,
      wholeWord: options.wholeWord,
      regex: options.regex,
    );
  }
}

class _SearchNavigationTarget {
  const _SearchNavigationTarget({
    required this.filePath,
    required this.line,
    required this.startOffset,
    required this.endOffset,
    required this.query,
    required this.request,
  });

  final String filePath;
  final int line;
  final int startOffset;
  final int endOffset;
  final String query;
  final int request;
}

class _ToggleSearchIntent extends Intent {
  const _ToggleSearchIntent();
}

class _OpenSearchIntent extends Intent {
  const _OpenSearchIntent();
}

class _SelectSidebarTabIntent extends Intent {
  const _SelectSidebarTabIntent(this.tab);

  final _SidebarTab tab;
}

class WorkspaceScreen extends ConsumerWidget {
  const WorkspaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workspaceControllerProvider);
    final settings = ref.watch(appSettingsControllerProvider);
    final workspace = state.workspace;
    if (workspace == null) {
      return const WelcomeScreen();
    }
    final searchState = ref.watch(_workspaceSearchProvider);
    final gitState = ref.watch(gitControllerProvider);
    final searchResults = _workspaceSearchResults(context, searchState.matches);

    final colors = BusyMarkSurfaceColors.of(context);
    final headerBar = ref.watch(linuxHeaderBarServiceProvider);
    final useNativeHeaderBar = headerBar.usesNativeHeaderBar;
    final settingsController = ref.read(appSettingsControllerProvider.notifier);
    final sidebarVisible =
        settings.sidebarVisible && _hasWorkspaceSidebar(workspace);
    final documentOutline = _activeDocumentOutline(state);
    final sidebar = SizedBox(
      width: BusyMarkSizes.sidebarWidth,
      child: _Sidebar(
        workspace: workspace,
        outline: documentOutline,
        searchState: searchState,
        searchResults: searchResults,
        onOpenSearchResult: (result) => _openSearchResult(context, ref, result),
      ),
    );
    final workspaceContent = Expanded(
      child: Column(
        children: [
          if (_shouldShowEditorTabs(workspace, gitState))
            _EditorTabStrip(state: state, gitState: gitState),
          Expanded(
            child: gitState.selectedDiffForDisplay == null
                ? _EditorPreviewSplit(
                    state: state,
                    outline: documentOutline,
                    viewMode: settings.documentViewMode,
                    editorFontSize: settings.editorFontSize,
                    editorToolbarPlacement: settings.editorToolbarPlacement,
                    editorToolbarDirection: settings.editorToolbarDirection,
                    wordWrap: settings.wordWrap,
                  )
                : _GitDiffDocumentView(
                    diff: gitState.selectedDiffForDisplay,
                    comparisonLabel: _gitDiffComparisonLabel(context, gitState),
                    comparisonType: gitState.selectedView == GitView.fileHistory
                        ? gitState.fileHistory.comparisonType
                        : null,
                    comparisonEnabled: !gitState.isRunningOperation,
                    onComparisonTypeChanged:
                        gitState.selectedView == GitView.fileHistory
                        ? (comparison) => unawaited(
                            _selectFileHistoryComparison(ref, comparison),
                          )
                        : null,
                    openFilePath: gitState.selectedDiffOpenFilePath,
                    workspace: workspace,
                    viewMode: settings.documentViewMode,
                    hasUnsavedEditorChanges: state.isDirty,
                    editorFontSize: settings.editorFontSize,
                    onOpenFile: (relativePath) =>
                        _openGitDiffFile(context, ref, relativePath),
                  ),
          ),
        ],
      ),
    );
    final sidebarOnRight = Directionality.of(context) == TextDirection.rtl;
    final workspaceChildren = [
      if (!sidebarOnRight && sidebarVisible) sidebar,
      workspaceContent,
      if (sidebarOnRight && sidebarVisible) sidebar,
    ];
    ref.listen(headerBarActionsProvider, (previous, next) {
      next.whenData((event) {
        _handleHeaderBarAction(context, ref, event.action);
      });
    });
    ref.listen(headerBarSearchEventsProvider, (previous, next) {
      next.whenData((event) {
        switch (event) {
          case HeaderBarSearchQueryChanged(:final query):
            final current = ref.read(_workspaceSearchProvider);
            if (current.query == query && current.active) {
              return;
            }
            _clearGitDetailSelection(ref);
            ref
                .read(_workspaceSearchProvider.notifier)
                .set(current.copyWith(active: true, query: query));
            unawaited(settingsController.setSidebarVisible(true));
          case HeaderBarSearchSubmitted():
            unawaited(_submitSearch(context, ref));
          case HeaderBarSearchCleared():
            _clearSearchQuery(ref);
          case HeaderBarSearchEscapePressed():
            _closeSearch(ref);
          case HeaderBarSearchFocusChanged():
            break;
        }
      });
    });
    ref.listen<int>(workspaceSearchOpenRequestProvider, (previous, next) {
      if (next != previous) {
        _openSearch(ref);
      }
    });
    ref.listen<int>(workspaceSearchCloseRequestProvider, (previous, next) {
      if (next != previous) {
        _closeSearch(ref);
      }
    });
    ref.listen<WorkspaceState>(workspaceControllerProvider, (previous, next) {
      final nextWorkspace = next.workspace;
      if (nextWorkspace == null) {
        return;
      }
      ref.read(gitControllerProvider.notifier).attachWorkspace(nextWorkspace);
    });
    if (gitState.attachedWorkspace?.id != workspace.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(gitControllerProvider.notifier).attachWorkspace(workspace);
      });
    }
    final title = state.isDirty
        ? '*${_activeFileName(context, workspace)}'
        : _activeFileName(context, workspace);
    final hasSidebar = _hasWorkspaceSidebar(workspace);
    final canExportPdf = canExportWorkspacePdf(state);
    final canGenerateMarkdownToc =
        _activeWorkspaceDocumentKind(workspace)?.supportsAiMarkdownEditing ??
        false;
    final headerConfiguration = HeaderBarConfigurationDefaults.of(context)
        .copyWith(
          title: busyMarkBidiIsolateFor(context, title),
          viewMode: _headerBarViewMode(settings.documentViewMode),
          searchQuery: searchState.query,
          canRefresh: true,
          canExportPdf: canExportPdf,
          documentControlsVisible: true,
          searchActive: searchState.active,
          searchVisible: true,
          sidebarVisible: sidebarVisible,
          sidebarToggleVisible: hasSidebar,
          backVisible: true,
        );

    return HeaderBarConfigurationPublisher(
      synchronizer: headerBar.configurationSynchronizer,
      configuration: headerConfiguration,
      enabled: headerBar.isAvailable,
      child: Shortcuts(
        shortcuts: {
          BusyMarkAppShortcutActivators.search: const _OpenSearchIntent(),
          BusyMarkSidebarShortcutActivators.files:
              const _SelectSidebarTabIntent(_SidebarTab.files),
          const SingleActivator(LogicalKeyboardKey.numpad1, control: true):
              const _SelectSidebarTabIntent(_SidebarTab.files),
          BusyMarkSidebarShortcutActivators.toc: const _SelectSidebarTabIntent(
            _SidebarTab.toc,
          ),
          const SingleActivator(LogicalKeyboardKey.numpad2, control: true):
              const _SelectSidebarTabIntent(_SidebarTab.toc),
          BusyMarkSidebarShortcutActivators.outline:
              const _SelectSidebarTabIntent(_SidebarTab.outline),
          const SingleActivator(LogicalKeyboardKey.numpad3, control: true):
              const _SelectSidebarTabIntent(_SidebarTab.outline),
          BusyMarkSidebarShortcutActivators.git: const _SelectSidebarTabIntent(
            _SidebarTab.git,
          ),
          const SingleActivator(LogicalKeyboardKey.numpad4, control: true):
              const _SelectSidebarTabIntent(_SidebarTab.git),
        },
        child: Actions(
          actions: {
            _OpenSearchIntent: CallbackAction<_OpenSearchIntent>(
              onInvoke: (intent) {
                _openSearch(ref);
                return null;
              },
            ),
            _ToggleSearchIntent: CallbackAction<_ToggleSearchIntent>(
              onInvoke: (intent) {
                _toggleSearch(ref);
                return null;
              },
            ),
            _SelectSidebarTabIntent: CallbackAction<_SelectSidebarTabIntent>(
              onInvoke: (intent) {
                _selectSidebarShortcut(ref, intent.tab);
                return null;
              },
            ),
          },
          child: FocusScope(
            autofocus: true,
            child: Scaffold(
              backgroundColor: colors.window,
              appBar: useNativeHeaderBar
                  ? null
                  : AppBar(
                      leading: Center(
                        child: BusyMarkHeaderIconButton(
                          tooltip: context.l10n.welcome,
                          icon: BusyMarkGlyphs.home,
                          shortcut: BusyMarkAppShortcutLabels.back,
                          onPressed: () async {
                            final router = GoRouter.of(context);
                            if (await confirmSafeToContinue(context, ref)) {
                              router.go('/');
                            }
                          },
                        ),
                      ),
                      title: searchState.active
                          ? _HeaderSearchField(
                              query: searchState.query,
                              onChanged: (query) => _setSearchQuery(ref, query),
                              onClear: () => _clearSearchQuery(ref),
                              onSubmitted: () =>
                                  unawaited(_submitSearch(context, ref)),
                              onEscape: () => _closeSearch(ref),
                            )
                          : _HeaderTitle(
                              title: _activeFileName(context, workspace),
                              subtitle: _workspaceKindLabel(
                                context,
                                workspace.kind,
                              ),
                              dirty: state.isDirty,
                            ),
                      actions: [
                        const SizedBox(width: BusyMarkSpacing.sm),
                        BusyMarkHeaderIconButton(
                          tooltip: context.l10n.validate,
                          icon: BusyMarkGlyphs.diagnostics,
                          onPressed: () => unawaited(
                            _validateActiveAndShowProblems(context, ref),
                          ),
                        ),
                        const _HeaderSeparator(),
                        BusyMarkHeaderIconButton(
                          tooltip: settings.sidebarVisible
                              ? context.l10n.hideSidebar
                              : context.l10n.showSidebar,
                          icon: BusyMarkGlyphs.sidebar,
                          selected: settings.sidebarVisible,
                          shortcut: BusyMarkSidebarShortcutLabels.toggleSidebar,
                          onPressed: () {
                            final visible = !settings.sidebarVisible;
                            if (!visible) {
                              _clearGitDetailSelection(ref);
                            }
                            unawaited(
                              settingsController.setSidebarVisible(visible),
                            );
                          },
                        ),
                        BusyMarkHeaderIconButton(
                          tooltip: context.l10n.search,
                          icon: BusyMarkGlyphs.search,
                          selected: searchState.active,
                          shortcut: BusyMarkAppShortcutLabels.search,
                          onPressed: () => _toggleSearch(ref),
                        ),
                        BusyMarkHeaderPopupMenuButton<
                          DocumentViewModePreference
                        >(
                          tooltip: context.l10n.viewMode,
                          icon: _documentViewModeIcon(
                            settings.documentViewMode,
                          ),
                          itemBuilder: (context) => [
                            for (final mode
                                in DocumentViewModePreference.values)
                              BusyMarkPopupMenuItem(
                                value: mode,
                                label: _documentViewModeLabel(context, mode),
                                icon: _documentViewModeIcon(mode),
                                checked: mode == settings.documentViewMode,
                                trailingCheck: true,
                              ),
                          ],
                          onSelected: (mode) =>
                              settingsController.setDocumentViewMode(mode),
                        ),
                        BusyMarkMainMenuButton(
                          canExportPdf: canExportPdf,
                          canGenerateMarkdownToc: canGenerateMarkdownToc,
                          onSelected: (action) =>
                              _handleMainMenuAction(context, ref, action),
                        ),
                        const SizedBox(width: BusyMarkSpacing.sm),
                      ],
                    ),
              body: Column(
                children: [
                  if (state.message != null)
                    BusyMarkStatusBox(
                      message: localizeWorkspaceMessage(
                        context,
                        state.message!,
                      ),
                      kind: busyMarkWorkspaceMessageStatusKind(
                        state.message!.code,
                      ),
                    ),
                  Expanded(
                    child: Row(
                      textDirection: TextDirection.ltr,
                      children: workspaceChildren,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _toggleSearch(WidgetRef ref) {
    final search = ref.read(_workspaceSearchProvider);
    if (search.active) {
      _closeSearch(ref);
    } else {
      _openSearch(ref);
    }
  }

  void _openSearch(WidgetRef ref) {
    final search = ref.read(_workspaceSearchProvider);
    if (search.active) {
      unawaited(
        ref
            .read(appSettingsControllerProvider.notifier)
            .setSidebarVisible(true),
      );
      unawaited(ref.read(linuxHeaderBarServiceProvider).focusSearch());
      return;
    }
    _clearGitDetailSelection(ref);
    ref
        .read(_workspaceSearchProvider.notifier)
        .set(search.copyWith(active: true));
    unawaited(
      ref.read(appSettingsControllerProvider.notifier).setSidebarVisible(true),
    );
  }

  void _closeSearch(WidgetRef ref) {
    final search = ref.read(_workspaceSearchProvider);
    if (!search.active) {
      return;
    }
    ref
        .read(_workspaceSearchProvider.notifier)
        .set(search.copyWith(active: false));
  }

  void _selectSidebarShortcut(WidgetRef ref, _SidebarTab tab) {
    _closeSearch(ref);
    unawaited(
      ref.read(appSettingsControllerProvider.notifier).setSidebarVisible(true),
    );
    ref.read(_sidebarShortcutRequestProvider.notifier).select(tab);
  }

  void _setSearchQuery(WidgetRef ref, String query) {
    final current = ref.read(_workspaceSearchProvider);
    ref
        .read(_workspaceSearchProvider.notifier)
        .set(current.copyWith(active: true, query: query));
  }

  void _clearSearchQuery(WidgetRef ref) {
    final current = ref.read(_workspaceSearchProvider);
    ref
        .read(_workspaceSearchProvider.notifier)
        .set(current.copyWith(query: ''));
  }

  Future<void> _submitSearch(BuildContext context, WidgetRef ref) async {
    final current = await ref.read(_workspaceSearchProvider.notifier).submit();
    if (!current || !context.mounted) {
      return;
    }
    final matches = ref.read(_workspaceSearchProvider).matches;
    if (matches.isEmpty) {
      return;
    }
    final result = _workspaceSearchResults(context, matches).first;
    await _openSearchResult(context, ref, result);
  }

  void _handleHeaderBarAction(
    BuildContext context,
    WidgetRef ref,
    HeaderBarAction action,
  ) {
    final settings = ref.read(appSettingsControllerProvider);
    final settingsController = ref.read(appSettingsControllerProvider.notifier);
    switch (action) {
      case HeaderBarAction.back:
        unawaited(() async {
          if (await confirmSafeToContinue(context, ref) && context.mounted) {
            context.go('/');
          }
        }());
      case HeaderBarAction.sidebarToggle:
        final visible = !settings.sidebarVisible;
        if (!visible) {
          _clearGitDetailSelection(ref);
        }
        unawaited(settingsController.setSidebarVisible(visible));
      case HeaderBarAction.refresh:
        unawaited(_validateActiveAndShowProblems(context, ref));
      case HeaderBarAction.save:
        break;
      case HeaderBarAction.exportPdf:
        unawaited(exportWorkspaceToPdf(context, ref));
      case HeaderBarAction.fullScreen:
        break;
      case HeaderBarAction.settings:
        context.go(settingsLocation(SettingsReturnTarget.workspace));
      case HeaderBarAction.keyboardShortcuts:
        showBusyMarkKeyboardShortcutsDialog(context);
      case HeaderBarAction.markdownAndHtml:
        showBusyMarkMarkdownHtmlDialog(context);
      case HeaderBarAction.reportIssue:
        final headerBar = ref.read(linuxHeaderBarServiceProvider);
        showBusyMarkFeedbackDialog(
          context,
          headerBarService: headerBar.isAvailable ? headerBar : null,
        );
      case HeaderBarAction.aboutBusyMark:
        showBusyMarkAboutDialog(context);
      case HeaderBarAction.viewModeEditor:
        unawaited(
          settingsController.setDocumentViewMode(
            DocumentViewModePreference.editor,
          ),
        );
      case HeaderBarAction.viewModeSource:
        unawaited(
          settingsController.setDocumentViewMode(
            DocumentViewModePreference.source,
          ),
        );
      case HeaderBarAction.viewModePreview:
        unawaited(
          settingsController.setDocumentViewMode(
            DocumentViewModePreference.preview,
          ),
        );
      case HeaderBarAction.viewModeSplit:
        unawaited(
          settingsController.setDocumentViewMode(
            DocumentViewModePreference.split,
          ),
        );
      case HeaderBarAction.sidebarFiles:
        _selectSidebarShortcut(ref, _SidebarTab.files);
      case HeaderBarAction.sidebarToc:
        _selectSidebarShortcut(ref, _SidebarTab.toc);
      case HeaderBarAction.sidebarOutline:
        _selectSidebarShortcut(ref, _SidebarTab.outline);
      case HeaderBarAction.sidebarGit:
        _selectSidebarShortcut(ref, _SidebarTab.git);
      case HeaderBarAction.search:
        _toggleSearch(ref);
      case HeaderBarAction.menu:
        break;
    }
  }

  void _handleMainMenuAction(
    BuildContext context,
    WidgetRef ref,
    BusyMarkMainMenuAction action,
  ) {
    switch (action) {
      case BusyMarkMainMenuAction.exportPdf:
        unawaited(exportWorkspaceToPdf(context, ref));
      case BusyMarkMainMenuAction.generateMarkdownToc:
        _generateOrUpdateMarkdownToc(context, ref);
      case BusyMarkMainMenuAction.fullScreen:
        unawaited(ref.read(windowControlServiceProvider).toggleFullScreen());
      case BusyMarkMainMenuAction.settings:
        context.go(settingsLocation(SettingsReturnTarget.workspace));
      case BusyMarkMainMenuAction.keyboardShortcuts:
        showBusyMarkKeyboardShortcutsDialog(context);
      case BusyMarkMainMenuAction.markdownAndHtml:
        showBusyMarkMarkdownHtmlDialog(context);
      case BusyMarkMainMenuAction.reportIssue:
        final headerBar = ref.read(linuxHeaderBarServiceProvider);
        showBusyMarkFeedbackDialog(
          context,
          headerBarService: headerBar.isAvailable ? headerBar : null,
        );
      case BusyMarkMainMenuAction.aboutBusyMark:
        showBusyMarkAboutDialog(context);
    }
  }

  void _generateOrUpdateMarkdownToc(BuildContext context, WidgetRef ref) {
    final state = ref.read(workspaceControllerProvider);
    final workspace = state.workspace;
    if (workspace == null) {
      return;
    }
    final kind = _activeWorkspaceDocumentKind(workspace);
    if (!(kind?.supportsAiMarkdownEditing ?? false)) {
      return;
    }
    final filePath = workspace.activeFilePath ?? workspace.markdown?.filePath;
    if (filePath == null) {
      return;
    }
    try {
      final result = const MarkdownTocGenerator().generate(
        source: state.activeText,
        filePath: filePath,
        mode: kind == DocumentKind.writersideMarkdownTopic
            ? MarkdownMode.writersideMarkdown
            : MarkdownMode.gfm,
        title: context.l10n.markdownTocTitle,
      );
      ref
          .read(workspaceControllerProvider.notifier)
          .updateActiveText(result.source, sourceFilePath: filePath);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.markdownTocUpdated(result.entryCount)),
        ),
      );
    } on MarkdownTocException catch (error) {
      final message = switch (error.failure) {
        MarkdownTocFailure.malformedMarkers =>
          context.l10n.markdownTocMalformedMarkers,
        MarkdownTocFailure.noHeadings => context.l10n.markdownTocNoHeadings,
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  String _activeFileName(BuildContext context, Workspace workspace) {
    final path = workspace.activeFilePath ?? workspace.markdown?.filePath;
    if (path == null || path.isEmpty) {
      return switch (workspace.kind) {
        WorkspaceKind.markdownFolder ||
        WorkspaceKind.writersideModule => context.l10n.noOpenFile,
        WorkspaceKind.untitledMarkdown ||
        WorkspaceKind.singleMarkdown => context.l10n.untitledMarkdownFileName,
      };
    }
    return p.basename(path);
  }

  String _workspaceKindLabel(BuildContext context, WorkspaceKind kind) {
    return switch (kind) {
      WorkspaceKind.untitledMarkdown =>
        context.l10n.workspaceKindUnsavedMarkdown,
      WorkspaceKind.singleMarkdown => context.l10n.workspaceKindSingleMarkdown,
      WorkspaceKind.markdownFolder => context.l10n.workspaceKindMarkdownFolder,
      WorkspaceKind.writersideModule =>
        context.l10n.workspaceKindWritersideModule,
    };
  }

  AppViewMode _headerBarViewMode(DocumentViewModePreference mode) {
    return switch (mode) {
      DocumentViewModePreference.editor => AppViewMode.editor,
      DocumentViewModePreference.source => AppViewMode.source,
      DocumentViewModePreference.preview => AppViewMode.preview,
      DocumentViewModePreference.split => AppViewMode.split,
    };
  }

  IconData _documentViewModeIcon(DocumentViewModePreference mode) {
    return switch (mode) {
      DocumentViewModePreference.editor => BusyMarkGlyphs.editorView,
      DocumentViewModePreference.source => BusyMarkGlyphs.sourceView,
      DocumentViewModePreference.preview => BusyMarkGlyphs.previewView,
      DocumentViewModePreference.split => BusyMarkGlyphs.splitView,
    };
  }

  String _documentViewModeLabel(
    BuildContext context,
    DocumentViewModePreference mode,
  ) {
    return switch (mode) {
      DocumentViewModePreference.editor => context.l10n.editor,
      DocumentViewModePreference.source => context.l10n.source,
      DocumentViewModePreference.preview => context.l10n.preview,
      DocumentViewModePreference.split => context.l10n.split,
    };
  }

  Future<void> _openSearchResult(
    BuildContext context,
    WidgetRef ref,
    _WorkspaceSearchResult result,
  ) async {
    final workspace = ref.read(workspaceControllerProvider).workspace;
    if (workspace == null) {
      return;
    }
    final activePath = workspace.activeFilePath ?? workspace.markdown?.filePath;
    if (activePath != result.filePath) {
      if (!await saveOrConfirmSafeToChangeActiveFile(context, ref) ||
          !context.mounted) {
        return;
      }
      await ref
          .read(workspaceControllerProvider.notifier)
          .openActiveFile(result.filePath);
    }
    _clearGitDetailSelection(ref);
    if (!context.mounted) {
      return;
    }
    final previous = ref.read(_searchNavigationTargetProvider);
    ref
        .read(_searchNavigationTargetProvider.notifier)
        .set(
          _SearchNavigationTarget(
            filePath: result.filePath,
            line: result.line,
            startOffset: result.startOffset,
            endOffset: result.endOffset,
            query: result.query,
            request: (previous?.request ?? 0) + 1,
          ),
        );
  }

  void _showProblemsDialog(BuildContext context, WidgetRef ref) {
    final workspace = ref.read(workspaceControllerProvider).workspace;
    if (workspace == null) {
      return;
    }
    final headerBar = ref.read(linuxHeaderBarServiceProvider);
    final count = workspace.diagnostics.length;
    unawaited(
      showBusyMarkModalDialog<void>(
        context,
        headerBarService: headerBar.isAvailable ? headerBar : null,
        builder: (context) => BusyMarkDialogShell(
          title: context.l10n.problems,
          maxWidth: BusyMarkSizes.contentWidth,
          children: [
            Text(
              context.l10n.diagnosticCount(count),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: BusyMarkSurfaceColors.of(context).mutedForeground,
              ),
            ),
            const SizedBox(height: BusyMarkSpacing.md),
            SizedBox(
              width: BusyMarkSizes.problemsListWidth,
              height: BusyMarkSizes.problemsListHeight,
              child: _ProblemsList(workspace: workspace),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _validateActiveAndShowProblems(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await ref.read(workspaceControllerProvider.notifier).validateActive();
    if (!context.mounted) {
      return;
    }
    _showProblemsDialog(context, ref);
  }
}

Future<void> _openGitDiffFile(
  BuildContext context,
  WidgetRef ref,
  String repoRelativePath,
) async {
  final repo = ref.read(gitControllerProvider).repositoryInfo;
  if (repo == null) {
    return;
  }
  final absolutePath = p.normalize(p.join(repo.rootPath, repoRelativePath));
  if (!File(absolutePath).existsSync()) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.errorPathDoesNotExist(absolutePath))),
    );
    await ref.read(gitControllerProvider.notifier).refresh();
    return;
  }
  if (!await saveOrConfirmSafeToChangeActiveFile(context, ref) ||
      !context.mounted) {
    return;
  }
  final workspace = ref.read(workspaceControllerProvider).workspace;
  final fileInWorkspace =
      workspace?.files.any((file) => file.absolutePath == absolutePath) ??
      false;
  final controller = ref.read(workspaceControllerProvider.notifier);
  if (fileInWorkspace) {
    await controller.openActiveFile(absolutePath);
  } else {
    await controller.openPath(absolutePath);
  }
  ref.read(gitControllerProvider.notifier).deactivateDiffFile();
}

void _clearGitDetailSelection(WidgetRef ref) {
  final gitState = ref.read(gitControllerProvider);
  if (gitState.selectedDiff != null ||
      gitState.selectedFilePath != null ||
      gitState.selectedCommitHash != null ||
      gitState.selectedCommitFilePath != null ||
      gitState.openDiffFilePaths.isNotEmpty) {
    ref.read(gitControllerProvider.notifier).clearSelection();
  }
}

Future<bool> _confirmDiscardGitFiles(
  BuildContext context,
  WidgetRef ref,
  List<GitFileStatus> files,
) async {
  if (files.isEmpty ||
      !await confirmSafeToContinue(context, ref) ||
      !context.mounted) {
    return false;
  }
  final untracked = files.where((file) => file.untracked).toList();
  final tracked = files.where((file) => !file.untracked).toList();
  final title = context.l10n.gitConfirmDiscardTitle;
  final message = tracked.isNotEmpty && untracked.isNotEmpty
      ? context.l10n.gitConfirmDiscardMixed(files.length)
      : untracked.isNotEmpty
      ? context.l10n.gitConfirmDiscardUntracked(untracked.length)
      : context.l10n.gitConfirmDiscardTracked(tracked.length);
  final headerBar = ref.read(linuxHeaderBarServiceProvider);
  final confirmed = await showBusyMarkModalDialog<bool>(
    context,
    headerBarService: headerBar.isAvailable ? headerBar : null,
    builder: (context) => BusyMarkDialogShell(
      title: title,
      maxWidth: BusyMarkSizes.dialogWide,
      actions: [
        BusyMarkDialogButton(
          label: context.l10n.cancel,
          onPressed: () => Navigator.pop(context, false),
        ),
        BusyMarkDialogButton(
          label: tracked.isEmpty
              ? context.l10n.delete
              : context.l10n.gitDiscard,
          destructive: true,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
      children: [
        Text(message),
        const SizedBox(height: BusyMarkSpacing.md),
        _GitFileList(files: files),
      ],
    ),
  );
  return confirmed ?? false;
}

Future<bool> _confirmSwitchGitBranch(
  BuildContext context,
  WidgetRef ref,
  String branchName,
) async {
  if (!await confirmSafeToContinue(context, ref) || !context.mounted) {
    return false;
  }
  final headerBar = ref.read(linuxHeaderBarServiceProvider);
  final confirmed = await showBusyMarkModalDialog<bool>(
    context,
    headerBarService: headerBar.isAvailable ? headerBar : null,
    builder: (context) => BusyMarkDialogShell(
      title: context.l10n.gitConfirmSwitchBranchTitle(branchName),
      maxWidth: BusyMarkSizes.dialog,
      actions: [
        BusyMarkDialogButton(
          label: context.l10n.cancel,
          onPressed: () => Navigator.pop(context, false),
        ),
        BusyMarkDialogButton(
          label: context.l10n.gitSwitchBranch,
          suggested: true,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
      children: [Text(context.l10n.gitConfirmSwitchBranchMessage)],
    ),
  );
  return confirmed ?? false;
}

Future<bool> _confirmGitPushSetUpstream(
  BuildContext context,
  WidgetRef ref,
) async {
  final repo = ref.read(gitControllerProvider).repositoryInfo;
  if (repo?.upstreamBranch != null) {
    return false;
  }
  final headerBar = ref.read(linuxHeaderBarServiceProvider);
  final confirmed = await showBusyMarkModalDialog<bool>(
    context,
    headerBarService: headerBar.isAvailable ? headerBar : null,
    builder: (context) => BusyMarkDialogShell(
      title: context.l10n.gitConfirmPushSetUpstreamTitle,
      maxWidth: BusyMarkSizes.dialog,
      actions: [
        BusyMarkDialogButton(
          label: context.l10n.cancel,
          onPressed: () => Navigator.pop(context, false),
        ),
        BusyMarkDialogButton(
          label: context.l10n.gitPush,
          suggested: true,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
      children: [
        Text(
          context.l10n.gitConfirmPushSetUpstreamMessage(
            repo?.currentBranch ?? '',
          ),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

Future<List<PopupMenuEntry<_GitMenuAction>>> _loadWorkspaceGitMenuItems(
  BuildContext context,
  WidgetRef ref,
  GitRepositoryInfo repository,
) async {
  final controller = ref.read(gitControllerProvider.notifier);
  final branches = await controller.loadBranches();
  if (!context.mounted) {
    return const [];
  }
  final latestState = ref.read(gitControllerProvider);
  final latestRepository = latestState.repositoryInfo ?? repository;
  return _sidebarGitMenuItems(
    context,
    latestRepository,
    branches,
    selectedView: latestState.selectedView,
  );
}

Future<void> _performWorkspaceGitAction(
  BuildContext context,
  WidgetRef ref,
  _GitMenuAction action,
) async {
  if (!context.mounted) {
    return;
  }
  final controller = ref.read(gitControllerProvider.notifier);
  switch (action) {
    case _SelectGitViewMenuAction(:final view):
      await controller.selectView(view);
    case _SwitchBranchMenuAction(:final branchName):
      if (branchName ==
          ref.read(gitControllerProvider).repositoryInfo?.currentBranch) {
        return;
      }
      if (!await _confirmSwitchGitBranch(context, ref, branchName) ||
          !context.mounted) {
        return;
      }
      await controller.switchBranch(branchName);
      if (ref.read(gitControllerProvider).lastError == null) {
        await _refreshWorkspaceAfterGitFileChanges(ref);
      }
    case _CreateBranchMenuAction():
      final branchName = await _showCreateBranchDialog(context);
      if (branchName == null) {
        return;
      }
      await controller.createBranch(branchName);
    case _FetchBranchMenuAction():
      await controller.fetch();
    case _PullBranchMenuAction():
      await controller.pullFastForwardOnly();
      await _refreshWorkspaceAfterGitFileChanges(ref);
    case _PushBranchMenuAction():
      final repo = ref.read(gitControllerProvider).repositoryInfo;
      final allowSetUpstream =
          repo?.upstreamBranch == null &&
          await _confirmGitPushSetUpstream(context, ref);
      await controller.push(allowSetUpstream: allowSetUpstream);
  }
}

List<PopupMenuEntry<_GitMenuAction>> _sidebarGitMenuItems(
  BuildContext context,
  GitRepositoryInfo repository,
  List<GitBranch> branches, {
  required GitView selectedView,
}) {
  return [
    BusyMarkPopupMenuItem(
      value: const _SelectGitViewMenuAction(GitView.changes),
      label: context.l10n.gitChanges,
      icon: BusyMarkGlyphs.checklist,
      checked: selectedView == GitView.changes,
      trailingCheck: true,
    ),
    BusyMarkPopupMenuItem(
      value: const _SelectGitViewMenuAction(GitView.projectHistory),
      label: context.l10n.gitProjectHistory,
      icon: BusyMarkGlyphs.history,
      checked: selectedView == GitView.projectHistory,
      trailingCheck: true,
    ),
    BusyMarkPopupMenuItem(
      value: const _SelectGitViewMenuAction(GitView.fileHistory),
      label: context.l10n.gitFileHistory,
      icon: BusyMarkGlyphs.documentHistory,
      checked: selectedView == GitView.fileHistory,
      trailingCheck: true,
    ),
    const PopupMenuDivider(height: BusyMarkSpacing.sm),
    BusyMarkPopupMenuItem(
      value: const _FetchBranchMenuAction(),
      label: context.l10n.gitFetch,
      icon: BusyMarkGlyphs.refresh,
      enabled: repository.hasRemote,
    ),
    BusyMarkPopupMenuItem(
      value: const _PullBranchMenuAction(),
      label: context.l10n.gitPull,
      icon: BusyMarkGlyphs.pull,
      enabled: repository.upstreamBranch != null,
    ),
    BusyMarkPopupMenuItem(
      value: const _PushBranchMenuAction(),
      label: context.l10n.gitPush,
      icon: BusyMarkGlyphs.push,
      enabled: repository.hasRemote,
    ),
    const PopupMenuDivider(height: BusyMarkSpacing.sm),
    BusyMarkPopupMenuItem(
      value: const _CreateBranchMenuAction(),
      label: context.l10n.gitNewBranch,
      icon: BusyMarkGlyphs.add,
    ),
    const PopupMenuDivider(height: BusyMarkSpacing.sm),
    for (final branch in branches)
      BusyMarkPopupMenuItem(
        value: _SwitchBranchMenuAction(branch.name),
        label: busyMarkLtrIsolateFor(context, branch.name),
        icon: BusyMarkGlyphs.branch,
        checked: branch.current,
        trailingCheck: true,
      ),
  ];
}

Future<void> _showWorkspacePathMenu(
  BuildContext context, {
  required String name,
  required String path,
  required Offset position,
  String? copyNameLabel,
  bool pathActionsEnabled = true,
}) async {
  final action = await _showSidebarPathMenu(
    context,
    position,
    copyNameLabel: copyNameLabel,
    pathActionsEnabled: pathActionsEnabled,
  );
  if (action == null || !context.mounted) {
    return;
  }
  await _performWorkspacePathAction(
    context,
    name: name,
    path: path,
    action: action,
  );
}

Future<void> _performWorkspacePathAction(
  BuildContext context, {
  required String name,
  required String path,
  required _PathMenuAction action,
}) async {
  if (path.isEmpty && action != _PathMenuAction.copyName) {
    return;
  }
  switch (action) {
    case _PathMenuAction.copyName:
      await _copyToClipboard(name);
    case _PathMenuAction.copyPath:
      await _copyToClipboard(path);
    case _PathMenuAction.openInFiles:
      await _openInFiles(context, path);
  }
}

enum _PathMenuAction { copyName, copyPath, openInFiles }

List<PopupMenuEntry<_PathMenuAction>> _sidebarPathMenuItems(
  BuildContext context, {
  String? copyNameLabel,
  bool pathActionsEnabled = true,
}) {
  return [
    BusyMarkPopupMenuItem(
      value: _PathMenuAction.copyName,
      label: copyNameLabel ?? context.l10n.copyName,
      icon: BusyMarkGlyphs.copy,
    ),
    BusyMarkPopupMenuItem(
      value: _PathMenuAction.copyPath,
      label: context.l10n.copyPath,
      icon: BusyMarkGlyphs.copy,
      enabled: pathActionsEnabled,
    ),
    const PopupMenuDivider(height: BusyMarkSpacing.sm),
    BusyMarkPopupMenuItem(
      value: _PathMenuAction.openInFiles,
      label: context.l10n.openInFiles,
      icon: BusyMarkGlyphs.folderOpen,
      enabled: pathActionsEnabled,
    ),
  ];
}

Future<_PathMenuAction?> _showSidebarPathMenu(
  BuildContext context,
  Offset position, {
  String? copyNameLabel,
  bool pathActionsEnabled = true,
}) {
  return showBusyMarkContextMenu<_PathMenuAction>(
    context,
    position,
    items: _sidebarPathMenuItems(
      context,
      copyNameLabel: copyNameLabel,
      pathActionsEnabled: pathActionsEnabled,
    ),
  );
}

Future<String?> _showCreateBranchDialog(BuildContext context) {
  return showBusyMarkModalEditorDialog<String>(
    context,
    maxWidth: BusyMarkSizes.dialogCompact,
    builder: (context) => const _CreateBranchDialog(),
  );
}

sealed class _GitMenuAction {
  const _GitMenuAction();
}

final class _SelectGitViewMenuAction extends _GitMenuAction {
  const _SelectGitViewMenuAction(this.view);

  final GitView view;
}

final class _SwitchBranchMenuAction extends _GitMenuAction {
  const _SwitchBranchMenuAction(this.branchName);

  final String branchName;
}

final class _CreateBranchMenuAction extends _GitMenuAction {
  const _CreateBranchMenuAction();
}

final class _FetchBranchMenuAction extends _GitMenuAction {
  const _FetchBranchMenuAction();
}

final class _PullBranchMenuAction extends _GitMenuAction {
  const _PullBranchMenuAction();
}

final class _PushBranchMenuAction extends _GitMenuAction {
  const _PushBranchMenuAction();
}

class _CreateBranchDialog extends StatefulWidget {
  const _CreateBranchDialog();

  @override
  State<_CreateBranchDialog> createState() => _CreateBranchDialogState();
}

class _CreateBranchDialogState extends State<_CreateBranchDialog> {
  late final TextEditingController _controller;

  bool get _canCreate => _controller.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController()..addListener(_handleChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BusyMarkModalEditorScaffold(
      title: context.l10n.gitCreateBranch,
      cancelLabel: context.l10n.cancel,
      saveLabel: context.l10n.gitCreateBranch,
      onCancel: () => Navigator.pop(context),
      onSave: _canCreate ? _submit : null,
      children: [
        BusyMarkGroupedList(
          filled: true,
          children: [
            BusyMarkGroupedTextEntry(
              label: context.l10n.gitBranchName,
              controller: _controller,
              textDirection: TextDirection.ltr,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
        const SizedBox(height: BusyMarkSpacing.lg),
      ],
    );
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      return;
    }
    Navigator.pop(context, value);
  }

  void _handleChanged() {
    setState(() {});
  }
}

Future<void> _refreshWorkspaceAfterGitFileChanges(WidgetRef ref) async {
  await ref
      .read(workspaceControllerProvider.notifier)
      .refreshWorkspaceFromDiskPreservingOpenTabs();
  final workspace = ref.read(workspaceControllerProvider).workspace;
  if (workspace != null) {
    ref.read(gitControllerProvider.notifier).attachWorkspace(workspace);
  }
}

class _GitFileList extends StatelessWidget {
  const _GitFileList({required this.files});

  final List<GitFileStatus> files;

  @override
  Widget build(BuildContext context) {
    return BusyMarkGroupedSurface(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 180),
        child: ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.all(BusyMarkSpacing.sm),
          itemCount: files.length,
          itemBuilder: (context, index) => Text(
            files[index].repoRelativePath,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: BusyMarkTypography.monoFontFamily,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderTitle extends StatelessWidget {
  const _HeaderTitle({
    required this.title,
    required this.subtitle,
    required this.dirty,
  });

  final String title;
  final String subtitle;
  final bool dirty;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return Row(
      children: [
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dirty ? '*$title' : title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colors.foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderSearchField extends StatefulWidget {
  const _HeaderSearchField({
    required this.query,
    required this.onChanged,
    required this.onClear,
    required this.onSubmitted,
    required this.onEscape,
  });

  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onSubmitted;
  final VoidCallback onEscape;

  @override
  State<_HeaderSearchField> createState() => _HeaderSearchFieldState();
}

class _HeaderSearchFieldState extends State<_HeaderSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant _HeaderSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.query,
        selection: TextSelection.collapsed(offset: widget.query.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BusyMarkSearchField(
      controller: _controller,
      hintText: context.l10n.search,
      autofocus: true,
      onChanged: widget.onChanged,
      onSubmitted: (_) => widget.onSubmitted(),
      onClear: widget.onClear,
      onEscape: widget.onEscape,
    );
  }
}

class _HeaderSeparator extends StatelessWidget {
  const _HeaderSeparator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: BusyMarkStroke.hairline,
      height: BusyMarkSizes.sidebarSeparatorHeight,
      margin: const EdgeInsets.symmetric(horizontal: BusyMarkSpacing.xs),
      color: BusyMarkSurfaceColors.of(context).subtleBorder,
    );
  }
}

class _Sidebar extends ConsumerStatefulWidget {
  const _Sidebar({
    required this.workspace,
    required this.outline,
    required this.searchState,
    required this.searchResults,
    required this.onOpenSearchResult,
  });

  final Workspace workspace;
  final List<DocumentOutlineHeading> outline;
  final _WorkspaceSearchState searchState;
  final List<_WorkspaceSearchResult> searchResults;
  final Future<void> Function(_WorkspaceSearchResult result) onOpenSearchResult;

  @override
  ConsumerState<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends ConsumerState<_Sidebar> {
  late int _tab;
  late String _workspaceId;
  String? _activeFilePath;
  _WritersideTopicUsageReview? _topicUsageReview;

  @override
  void initState() {
    super.initState();
    _workspaceId = widget.workspace.id;
    _activeFilePath = widget.workspace.activeFilePath;
    _tab = _initialSidebarTabIndex(widget.workspace);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(_sidebarShortcutRequestProvider.notifier).clear();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _Sidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchState.active && !oldWidget.searchState.active) {
      _clearGitDetailSelection(ref);
    }
    if (widget.workspace.id != _workspaceId) {
      _workspaceId = widget.workspace.id;
      _activeFilePath = widget.workspace.activeFilePath;
      _topicUsageReview = null;
      _tab = _initialSidebarTabIndex(widget.workspace);
      return;
    }
    if (widget.workspace.activeFilePath != _activeFilePath) {
      _activeFilePath = widget.workspace.activeFilePath;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _sidebarTabsFor(widget.workspace.kind);
    final gitState = ref.watch(gitControllerProvider);
    final repositoryInfo = gitState.attachedWorkspace?.id == widget.workspace.id
        ? gitState.repositoryInfo
        : null;
    ref.listen<_SidebarTab?>(_sidebarShortcutRequestProvider, (_, next) {
      if (next == null) {
        return;
      }
      _selectTab(next, tabs);
      ref.read(_sidebarShortcutRequestProvider.notifier).clear();
    });
    final selectedIndex = tabs.isEmpty
        ? 0
        : _tab.clamp(0, tabs.length - 1).toInt();
    final selectedTab = tabs.isEmpty ? null : tabs[selectedIndex];
    return BusyMarkSidebarSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SidebarHeader(
            workspace: widget.workspace,
            tabs: tabs,
            selectedTab: widget.searchState.active ? null : selectedTab,
            repositoryInfo: repositoryInfo,
            showTabMenu: !widget.searchState.active && tabs.length > 1,
            onSelectTab: (tab) => _selectTab(tab, tabs),
            loadGitMenuItems: (menuContext, repository) =>
                _loadWorkspaceGitMenuItems(menuContext, ref, repository),
            onGitAction: (menuContext, action) =>
                _performWorkspaceGitAction(menuContext, ref, action),
          ),
          Expanded(
            child: widget.searchState.active
                ? _SearchSidebar(
                    query: widget.searchState.query,
                    results: widget.searchResults,
                    searching: widget.searchState.searching,
                    onOpenResult: widget.onOpenSearchResult,
                  )
                : _topicUsageReview != null
                ? _WritersideTopicUsagesSidebar(
                    review: _topicUsageReview!,
                    onBack: _closeTopicUsageReview,
                    onOpenUsage: (usage) =>
                        _openWritersideTopicUsage(context, usage),
                    onDoRefactor: () => _resumeWritersideTopicRemoval(context),
                  )
                : switch (selectedTab) {
                    _SidebarTab.files => _FilesTab(
                      workspace: widget.workspace,
                      onShowFileHistory: _showFileHistory,
                      onRequestTopicRemoval: (target) =>
                          _runWritersideTopicRemoval(context, target),
                    ),
                    _SidebarTab.toc => _TocTab(
                      workspace: widget.workspace,
                      onShowFileHistory: _showFileHistory,
                      onRequestTopicRemoval: (target) =>
                          _runWritersideTopicRemoval(context, target),
                    ),
                    _SidebarTab.outline => _OutlineTab(
                      workspace: widget.workspace,
                      headings: widget.outline,
                    ),
                    _SidebarTab.git => GitSidebarTab(
                      workspace: widget.workspace,
                      onOpenFile: (relativePath) =>
                          _openGitDiffFile(context, ref, relativePath),
                      onConfirmDiscard: (files) =>
                          _confirmDiscardGitFiles(context, ref, files),
                      onAfterWorkspaceFilesChanged: () =>
                          _refreshWorkspaceAfterGitFileChanges(ref),
                      onConfirmSwitchBranch: (branchName) =>
                          _confirmSwitchGitBranch(context, ref, branchName),
                      onConfirmPushSetUpstream: () =>
                          _confirmGitPushSetUpstream(context, ref),
                    ),
                    null => const SizedBox.shrink(),
                  },
          ),
        ],
      ),
    );
  }

  void _selectTab(
    _SidebarTab tab,
    List<_SidebarTab> tabs, {
    bool showGitChanges = true,
  }) {
    final index = tabs.indexOf(tab);
    if (index < 0) {
      return;
    }
    setState(() {
      _tab = index;
    });
    if (tab == _SidebarTab.git &&
        showGitChanges &&
        ref.read(gitControllerProvider).selectedView != GitView.changes) {
      unawaited(
        ref.read(gitControllerProvider.notifier).selectView(GitView.changes),
      );
    } else if (tab != _SidebarTab.git) {
      _clearGitDetailSelection(ref);
    }
  }

  Future<void> _showFileHistory(DocumentFile file) async {
    if (widget.workspace.activeFilePath != file.absolutePath) {
      if (!await saveOrConfirmSafeToChangeActiveFile(context, ref) ||
          !mounted) {
        return;
      }
      final opened = await ref
          .read(workspaceControllerProvider.notifier)
          .openActiveFile(file.absolutePath);
      if (!opened || !mounted) {
        return;
      }
    }
    await ref
        .read(gitControllerProvider.notifier)
        .loadFileHistory(file.absolutePath);
    if (!mounted) {
      return;
    }
    _selectTab(
      _SidebarTab.git,
      _sidebarTabsFor(widget.workspace.kind),
      showGitChanges: false,
    );
  }

  Future<WritersideTopicRemovalResult?> _runWritersideTopicRemoval(
    BuildContext context,
    _WritersideTopicRemovalTarget target, {
    bool updateUsagesAutomatically = false,
    String? redirectTopicPath,
    bool applyIfUnused = false,
  }) async {
    if (!await saveOrConfirmSafeToChangeActiveFile(context, ref) ||
        !mounted ||
        !context.mounted) {
      return null;
    }
    final controller = ref.read(workspaceControllerProvider.notifier);
    final analysis = await controller.analyzeWritersideTopicRemoval(
      topicPath: target.topicPath,
      mode: target.mode,
      treePath: target.treePath,
      nodePath: target.nodePath,
    );
    if (!mounted || !context.mounted) {
      return null;
    }
    if (analysis == null) {
      _showLatestWorkspaceMessage(context);
      return null;
    }
    final initialRedirect = analysis.redirectTargets
        .where((candidate) => candidate.topicPath == redirectTopicPath)
        .firstOrNull;
    _WritersideTopicRemovalDialogResult decision;
    if (applyIfUnused && analysis.relevantUsages.isEmpty) {
      decision = _WritersideTopicRemovalDialogResult.apply(
        updateUsagesAutomatically: false,
        redirectTarget: initialRedirect,
      );
    } else {
      final headerBar = ref.read(linuxHeaderBarServiceProvider);
      final selected =
          await showBusyMarkModalDialog<_WritersideTopicRemovalDialogResult>(
            context,
            headerBarService: headerBar.isAvailable ? headerBar : null,
            barrierDismissible: false,
            builder: (dialogContext) => _WritersideTopicRemovalDialog(
              analysis: analysis,
              initialUpdateUsagesAutomatically: updateUsagesAutomatically,
              initialRedirectTarget: initialRedirect,
            ),
          );
      if (!mounted || !context.mounted || selected == null) {
        return null;
      }
      decision = selected;
    }
    if (decision.reviewUsages) {
      setState(() {
        _topicUsageReview = _WritersideTopicUsageReview(
          target: target,
          analysis: analysis,
          updateUsagesAutomatically: decision.updateUsagesAutomatically,
          redirectTopicPath: decision.redirectTarget?.topicPath,
        );
      });
      return null;
    }
    if (!await saveOrConfirmSafeToChangeActiveFile(context, ref) ||
        !mounted ||
        !context.mounted) {
      return null;
    }
    final result = await controller.applyWritersideTopicRemoval(
      WritersideTopicRemovalRequest(
        analysis: analysis,
        updateUsagesAutomatically: decision.updateUsagesAutomatically,
        redirectTarget: decision.redirectTarget,
      ),
    );
    if (!mounted || !context.mounted) {
      return null;
    }
    if (result == null) {
      _showLatestWorkspaceMessage(context);
      return null;
    }
    setState(() => _topicUsageReview = null);
    _clearGitDetailSelection(ref);
    if (target.mode == WritersideTopicRemovalMode.removeFromInstance &&
        result.orphaned &&
        !result.deletedFile) {
      final deleteOrphan = await _confirmDeleteOrphanTopicFile(
        context,
        analysis.topicFileName,
      );
      if (deleteOrphan && mounted && context.mounted) {
        return _runWritersideTopicRemoval(
          context,
          _WritersideTopicRemovalTarget(
            mode: WritersideTopicRemovalMode.safeDeleteFile,
            topicPath: target.topicPath,
          ),
          applyIfUnused: true,
        );
      }
    }
    return result;
  }

  void _closeTopicUsageReview() {
    setState(() => _topicUsageReview = null);
    _clearGitDetailSelection(ref);
  }

  Future<void> _resumeWritersideTopicRemoval(BuildContext context) async {
    final review = _topicUsageReview;
    if (review == null) {
      return;
    }
    setState(() => _topicUsageReview = null);
    await _runWritersideTopicRemoval(
      context,
      review.target,
      updateUsagesAutomatically: review.updateUsagesAutomatically,
      redirectTopicPath: review.redirectTopicPath,
    );
  }

  Future<void> _openWritersideTopicUsage(
    BuildContext context,
    WritersideTopicUsage usage,
  ) async {
    if (!await saveOrConfirmSafeToChangeActiveFile(context, ref) ||
        !mounted ||
        !context.mounted) {
      return;
    }
    final opened = await ref
        .read(workspaceControllerProvider.notifier)
        .openActiveFile(usage.filePath);
    if (!opened || !mounted) {
      return;
    }
    ref
        .read(_sourceNavigationTargetProvider.notifier)
        .set(
          _SourceNavigationTarget(filePath: usage.filePath, line: usage.line),
        );
    _clearGitDetailSelection(ref);
  }

  void _showLatestWorkspaceMessage(BuildContext context) {
    if (!context.mounted) {
      return;
    }
    final message = ref.read(workspaceControllerProvider).message;
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizeWorkspaceMessage(context, message))),
      );
    }
  }

  int _initialSidebarTabIndex(Workspace workspace) {
    final tabs = _sidebarTabsFor(workspace.kind);
    final request = ref.read(_sidebarShortcutRequestProvider);
    final requestedIndex = request == null ? -1 : tabs.indexOf(request);
    return requestedIndex >= 0
        ? requestedIndex
        : _preferredSidebarTabIndex(workspace);
  }
}

enum _SidebarTab { files, toc, outline, git }

int _preferredSidebarTabIndex(Workspace workspace) {
  final tabs = _sidebarTabsFor(workspace.kind);
  if (_shouldShowOutlineForOpenFile(workspace)) {
    final outlineIndex = tabs.indexOf(_SidebarTab.outline);
    if (outlineIndex >= 0) {
      return outlineIndex;
    }
  }
  return 0;
}

bool _shouldShowOutlineForOpenFile(Workspace workspace) {
  return workspace.activeFilePath != null && workspace.markdown != null;
}

bool _hasWorkspaceSidebar(Workspace workspace) {
  return _sidebarTabsFor(workspace.kind).isNotEmpty;
}

List<_SidebarTab> _sidebarTabsFor(WorkspaceKind kind) {
  return switch (kind) {
    WorkspaceKind.untitledMarkdown => const [_SidebarTab.outline],
    WorkspaceKind.singleMarkdown => const [
      _SidebarTab.outline,
      _SidebarTab.git,
    ],
    WorkspaceKind.markdownFolder => const [
      _SidebarTab.files,
      _SidebarTab.outline,
      _SidebarTab.git,
    ],
    WorkspaceKind.writersideModule => const [
      _SidebarTab.files,
      _SidebarTab.toc,
      _SidebarTab.outline,
      _SidebarTab.git,
    ],
  };
}

String _sidebarTabLabel(BuildContext context, _SidebarTab tab) {
  return switch (tab) {
    _SidebarTab.files => context.l10n.files,
    _SidebarTab.toc => context.l10n.toc,
    _SidebarTab.outline => context.l10n.outline,
    _SidebarTab.git => context.l10n.git,
  };
}

IconData _sidebarTabIcon(_SidebarTab tab, TextDirection direction) {
  return switch (tab) {
    _SidebarTab.files => BusyMarkGlyphs.documentOpen,
    _SidebarTab.toc => BusyMarkGlyphs.orderedList,
    _SidebarTab.outline => BusyMarkGlyphs.indentFor(direction),
    _SidebarTab.git => BusyMarkGlyphs.branch,
  };
}

String? _sidebarTabShortcut(_SidebarTab tab) {
  return switch (tab) {
    _SidebarTab.files => BusyMarkSidebarShortcutLabels.files,
    _SidebarTab.toc => BusyMarkSidebarShortcutLabels.toc,
    _SidebarTab.outline => BusyMarkSidebarShortcutLabels.outline,
    _SidebarTab.git => BusyMarkSidebarShortcutLabels.git,
  };
}

String? _gitBranchLabel(BuildContext context, GitRepositoryInfo? repository) {
  if (repository == null) {
    return null;
  }
  final branch = repository.currentBranch;
  if (branch != null) {
    return busyMarkLtrIsolateFor(context, branch);
  }
  final commit = repository.detachedHeadCommit;
  return commit == null
      ? context.l10n.gitDetachedHead
      : context.l10n.gitDetachedHeadAt(commit);
}

String? _gitDiffComparisonLabel(BuildContext context, GitState state) {
  final comparison = switch (state.selectedView) {
    GitView.changes => null,
    GitView.fileHistory => state.fileHistory.comparison,
    GitView.projectHistory => state.projectHistory.comparison,
  };
  if (comparison == null) {
    return null;
  }
  return state.selectedView == GitView.fileHistory &&
          state.fileHistory.comparisonType ==
              GitComparisonType.commitVersusCurrent
      ? context.l10n.gitCompareWithCurrent
      : context.l10n.gitChangesInCommit;
}

Future<void> _selectFileHistoryComparison(
  WidgetRef ref,
  GitComparisonType comparison,
) async {
  final controller = ref.read(gitControllerProvider.notifier);
  switch (comparison) {
    case GitComparisonType.commitChange:
      final hash = ref
          .read(gitControllerProvider)
          .fileHistory
          .selectedCommitHash;
      if (hash != null) {
        await controller.selectFileHistoryCommit(hash);
      }
    case GitComparisonType.commitVersusCurrent:
      await controller.compareFileHistoryWithCurrent();
    case GitComparisonType.staged:
    case GitComparisonType.unstaged:
    case GitComparisonType.untracked:
      return;
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({
    required this.workspace,
    required this.tabs,
    required this.selectedTab,
    required this.repositoryInfo,
    required this.showTabMenu,
    required this.onSelectTab,
    required this.loadGitMenuItems,
    required this.onGitAction,
  });

  final Workspace workspace;
  final List<_SidebarTab> tabs;
  final _SidebarTab? selectedTab;
  final GitRepositoryInfo? repositoryInfo;
  final bool showTabMenu;
  final ValueChanged<_SidebarTab> onSelectTab;
  final Future<List<PopupMenuEntry<_GitMenuAction>>> Function(
    BuildContext context,
    GitRepositoryInfo repository,
  )
  loadGitMenuItems;
  final Future<void> Function(BuildContext context, _GitMenuAction action)
  onGitAction;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final path = _workspacePath(workspace);
    final activeDocumentPath =
        workspace.activeFilePath ?? workspace.markdown?.filePath ?? '';
    final hasActiveDocumentPath = activeDocumentPath.isNotEmpty;
    final activeDocumentName = hasActiveDocumentPath
        ? _fileNameFromPath(activeDocumentPath)
        : context.l10n.untitledMarkdownFileName;
    final activeDocumentFile = hasActiveDocumentPath
        ? _documentFileForPath(workspace, activeDocumentPath)
        : null;
    final repository = repositoryInfo;
    final branchLabel = _gitBranchLabel(context, repositoryInfo);
    final detailsStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: colors.mutedForeground);
    final accentColor = Theme.of(context).colorScheme.primary;
    final branchStyle = detailsStyle?.copyWith(
      color: accentColor,
      fontWeight: FontWeight.w700,
    );
    return Padding(
      padding: BusyMarkInsets.sidebarHeader,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SidebarHeaderRow(
            key: const ValueKey('workspace-sidebar-primary-row'),
            child: Row(
              children: [
                Expanded(
                  child: _SidebarHeaderLine(
                    key: const ValueKey('workspace-sidebar-primary-label'),
                    icon: WorkspaceGlyphs.forKind(workspace.kind),
                    text: _workspaceDisplayName(context, workspace),
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: colors.foreground),
                  ),
                ),
                if (showTabMenu && selectedTab != null) ...[
                  const SizedBox(width: BusyMarkSpacing.sm),
                  BusyMarkHeaderPopupMenuButton<_SidebarTab>(
                    tooltip: context.l10n.sidebarViewMenu,
                    icon: _sidebarTabIcon(
                      selectedTab!,
                      Directionality.of(context),
                    ),
                    transparent: true,
                    borderRadius: BusyMarkRadius.nativeHeaderButton,
                    highlightWhenOpen: false,
                    itemBuilder: (context) => [
                      for (final tab in tabs)
                        BusyMarkPopupMenuItem(
                          value: tab,
                          label: _sidebarTabLabel(context, tab),
                          icon: _sidebarTabIcon(
                            tab,
                            Directionality.of(context),
                          ),
                          shortcut: _sidebarTabShortcut(tab),
                          checked: tab == selectedTab,
                          trailingCheck: true,
                        ),
                    ],
                    onSelected: onSelectTab,
                  ),
                ],
              ],
            ),
          ),
          if (selectedTab == _SidebarTab.files && path.isNotEmpty) ...[
            const SizedBox(height: BusyMarkSpacing.sm),
            _SidebarHeaderRow(
              key: const ValueKey('workspace-sidebar-first-content'),
              child: Row(
                children: [
                  Expanded(
                    child: _SidebarHeaderLine(
                      icon: WorkspaceGlyphs.pathForKind(workspace.kind),
                      text: path,
                      style: detailsStyle,
                      leadingEllipsis: true,
                      tooltip: busyMarkLtrIsolateFor(context, path),
                      onSecondaryTapUp: (lineContext, details) =>
                          _showWorkspacePathMenu(
                            lineContext,
                            name: _workspaceName(context, workspace),
                            path: path,
                            position: details.globalPosition,
                          ),
                    ),
                  ),
                  const SizedBox(width: BusyMarkSpacing.sm),
                  BusyMarkHeaderPopupMenuButton<_PathMenuAction>(
                    key: const ValueKey('workspace-sidebar-path-menu'),
                    tooltip: context.l10n.pathActions,
                    icon: BusyMarkGlyphs.menuVertical,
                    transparent: true,
                    borderRadius: BusyMarkRadius.nativeHeaderButton,
                    highlightWhenOpen: false,
                    itemBuilder: _sidebarPathMenuItems,
                    onSelected: (action) => unawaited(
                      _performWorkspacePathAction(
                        context,
                        name: _workspaceName(context, workspace),
                        path: path,
                        action: action,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (selectedTab == _SidebarTab.outline) ...[
            const SizedBox(height: BusyMarkSpacing.sm),
            _SidebarHeaderRow(
              key: const ValueKey('workspace-sidebar-first-content'),
              child: Row(
                children: [
                  Expanded(
                    child: _SidebarHeaderLine(
                      key: const ValueKey(
                        'workspace-sidebar-outline-file-label',
                      ),
                      icon: _documentKindIcon(
                        activeDocumentFile?.kind ?? DocumentKind.markdown,
                      ),
                      text: busyMarkLtrIsolateFor(context, activeDocumentName),
                      style: detailsStyle,
                      tooltip: hasActiveDocumentPath
                          ? busyMarkLtrIsolateFor(context, activeDocumentPath)
                          : null,
                      onSecondaryTapUp: (lineContext, details) =>
                          _showWorkspacePathMenu(
                            lineContext,
                            name: activeDocumentName,
                            path: activeDocumentPath,
                            position: details.globalPosition,
                            copyNameLabel: lineContext.l10n.copyFileName,
                            pathActionsEnabled: hasActiveDocumentPath,
                          ),
                    ),
                  ),
                  const SizedBox(width: BusyMarkSpacing.sm),
                  BusyMarkHeaderPopupMenuButton<_PathMenuAction>(
                    key: const ValueKey('workspace-sidebar-outline-file-menu'),
                    tooltip: context.l10n.fileActions,
                    icon: BusyMarkGlyphs.menuVertical,
                    transparent: true,
                    borderRadius: BusyMarkRadius.nativeHeaderButton,
                    highlightWhenOpen: false,
                    itemBuilder: (menuContext) => _sidebarPathMenuItems(
                      menuContext,
                      copyNameLabel: menuContext.l10n.copyFileName,
                      pathActionsEnabled: hasActiveDocumentPath,
                    ),
                    onSelected: (action) => unawaited(
                      _performWorkspacePathAction(
                        context,
                        name: activeDocumentName,
                        path: activeDocumentPath,
                        action: action,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (selectedTab == _SidebarTab.git &&
              repository != null &&
              branchLabel != null &&
              branchLabel.trim().isNotEmpty) ...[
            const SizedBox(height: BusyMarkSpacing.sm),
            _SidebarHeaderRow(
              key: const ValueKey('workspace-sidebar-first-content'),
              child: Row(
                children: [
                  Expanded(
                    child: _SidebarHeaderLine(
                      icon: WorkspaceGlyphs.branch,
                      text: branchLabel,
                      style: branchStyle,
                      inlineTrailing: _branchSyncIndicators(
                        context,
                        repository,
                        branchStyle,
                      ),
                    ),
                  ),
                  const SizedBox(width: BusyMarkSpacing.sm),
                  BusyMarkHeaderPopupMenuButton<_GitMenuAction>(
                    key: const ValueKey('workspace-sidebar-branch-menu'),
                    tooltip: context.l10n.gitActions,
                    icon: BusyMarkGlyphs.menuVertical,
                    transparent: true,
                    borderRadius: BusyMarkRadius.nativeHeaderButton,
                    highlightWhenOpen: false,
                    itemBuilder: (menuContext) =>
                        loadGitMenuItems(menuContext, repository),
                    onSelected: (action) =>
                        unawaited(onGitAction(context, action)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _workspaceName(BuildContext context, Workspace workspace) {
    if (workspace.kind == WorkspaceKind.untitledMarkdown) {
      final filePath = workspace.markdown?.filePath;
      return filePath == null || filePath.isEmpty
          ? context.l10n.untitledMarkdownFileName
          : filePath;
    }
    if (workspace.kind == WorkspaceKind.writersideModule) {
      final moduleName = workspace.writersideModule?.config.moduleName?.trim();
      if (moduleName != null && moduleName.isNotEmpty) {
        return moduleName;
      }
    }
    final path = _workspacePath(workspace);
    final segments = path.split('/').where((segment) => segment.isNotEmpty);
    return segments.isEmpty ? path : segments.last;
  }

  String _workspaceDisplayName(BuildContext context, Workspace workspace) {
    final name = _workspaceName(context, workspace);
    final filePath = workspace.markdown?.filePath;
    final localizedUntitled =
        workspace.kind == WorkspaceKind.untitledMarkdown &&
        (filePath == null || filePath.isEmpty);
    return localizedUntitled ? name : busyMarkLtrIsolateFor(context, name);
  }

  String _workspacePath(Workspace workspace) {
    if (workspace.kind == WorkspaceKind.singleMarkdown) {
      return workspace.activeFilePath ??
          workspace.markdown?.filePath ??
          workspace.rootPath;
    }
    return workspace.rootPath;
  }
}

List<Widget> _branchSyncIndicators(
  BuildContext context,
  GitRepositoryInfo repository,
  TextStyle? style,
) {
  return [
    if (repository.behindCount > 0)
      _BranchSyncIndicator(
        direction: _BranchSyncDirection.incoming,
        count: repository.behindCount,
        tooltip: context.l10n.gitBehindCount(repository.behindCount),
        style: style,
      ),
    if (repository.aheadCount > 0)
      _BranchSyncIndicator(
        direction: _BranchSyncDirection.outgoing,
        count: repository.aheadCount,
        tooltip: context.l10n.gitAheadCount(repository.aheadCount),
        style: style,
      ),
  ];
}

typedef _SidebarHeaderSecondaryTapHandler =
    Future<void> Function(BuildContext context, TapUpDetails details);

class _SidebarHeaderRow extends StatelessWidget {
  const _SidebarHeaderRow({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: BusyMarkSizes.iconButton),
      child: child,
    );
  }
}

class _SidebarHeaderLine extends StatelessWidget {
  const _SidebarHeaderLine({
    super.key,
    required this.icon,
    required this.text,
    required this.style,
    this.leadingEllipsis = false,
    this.inlineTrailing = const [],
    this.tooltip,
    this.onSecondaryTapUp,
  });

  final IconData icon;
  final String text;
  final TextStyle? style;
  final bool leadingEllipsis;
  final List<Widget> inlineTrailing;
  final String? tooltip;
  final _SidebarHeaderSecondaryTapHandler? onSecondaryTapUp;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final iconColor = style?.color ?? colors.mutedForeground;
    final iconFontWeight = style?.fontWeight;
    final iconWeight = iconFontWeight?.value.toDouble();
    final textScale = MediaQuery.textScalerOf(context);
    final iconSize = textScale.scale(style?.fontSize ?? BusyMarkSizes.iconSm);
    final text = leadingEllipsis
        ? _LeadingEllipsisText(text: this.text, style: style)
        : Text(
            this.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          );
    final line = Row(
      children: [
        Icon(
          icon,
          size: iconSize,
          color: iconColor,
          weight: iconWeight,
          fontWeight: iconFontWeight,
        ),
        const SizedBox(width: BusyMarkSpacing.sm),
        Expanded(
          child: Row(
            children: [
              Flexible(child: text),
              for (final trailing in inlineTrailing) ...[
                const SizedBox(width: BusyMarkSpacing.sm),
                trailing,
              ],
            ],
          ),
        ),
      ],
    );
    final secondaryTapHandler = onSecondaryTapUp;
    if (secondaryTapHandler == null) {
      return line;
    }
    final clickable = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapUp: (details) =>
          unawaited(secondaryTapHandler(context, details)),
      child: line,
    );
    final tooltip = this.tooltip;
    return tooltip == null
        ? clickable
        : Tooltip(message: tooltip, child: clickable);
  }
}

enum _BranchSyncDirection { incoming, outgoing }

class _BranchSyncIndicator extends StatelessWidget {
  const _BranchSyncIndicator({
    required this.direction,
    required this.count,
    required this.tooltip,
    required this.style,
  });

  final _BranchSyncDirection direction;
  final int count;
  final String tooltip;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final effectiveStyle =
        style ??
        Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colors.mutedForeground,
          fontWeight: FontWeight.w700,
        );
    final color = effectiveStyle?.color ?? colors.mutedForeground;
    final textScale = MediaQuery.textScalerOf(context);
    final iconSize = textScale.scale(
      effectiveStyle?.fontSize ?? BusyMarkSizes.iconSm,
    );
    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BoldVerticalArrowIcon(
            direction: direction,
            size: iconSize,
            color: color,
          ),
          const SizedBox(width: BusyMarkSpacing.xxs),
          Text('$count', style: effectiveStyle),
        ],
      ),
    );
  }
}

class _BoldVerticalArrowIcon extends StatelessWidget {
  const _BoldVerticalArrowIcon({
    required this.direction,
    required this.size,
    required this.color,
  });

  final _BranchSyncDirection direction;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _BoldVerticalArrowIconPainter(direction, color),
      ),
    );
  }
}

class _BoldVerticalArrowIconPainter extends CustomPainter {
  const _BoldVerticalArrowIconPainter(this.direction, this.color);

  final _BranchSyncDirection direction;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / BusyMarkSizes.iconSm;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.15 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final centerX = size.width * 0.5;
    final topY = size.height * 0.25;
    final bottomY = size.height * 0.75;
    final head = size.width * 0.18;
    switch (direction) {
      case _BranchSyncDirection.incoming:
        canvas.drawLine(Offset(centerX, topY), Offset(centerX, bottomY), paint);
        canvas.drawLine(
          Offset(centerX, bottomY),
          Offset(centerX - head, bottomY - head),
          paint,
        );
        canvas.drawLine(
          Offset(centerX, bottomY),
          Offset(centerX + head, bottomY - head),
          paint,
        );
      case _BranchSyncDirection.outgoing:
        canvas.drawLine(Offset(centerX, bottomY), Offset(centerX, topY), paint);
        canvas.drawLine(
          Offset(centerX, topY),
          Offset(centerX - head, topY + head),
          paint,
        );
        canvas.drawLine(
          Offset(centerX, topY),
          Offset(centerX + head, topY + head),
          paint,
        );
    }
  }

  @override
  bool shouldRepaint(_BoldVerticalArrowIconPainter oldDelegate) {
    return direction != oldDelegate.direction || color != oldDelegate.color;
  }
}

class _LeadingEllipsisText extends StatelessWidget {
  const _LeadingEllipsisText({required this.text, required this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final value = constraints.hasBoundedWidth
            ? _truncateStart(context, text, style, constraints.maxWidth)
            : text;
        return Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.clip,
          softWrap: false,
          style: style,
          textAlign: Directionality.of(context) == TextDirection.rtl
              ? TextAlign.right
              : TextAlign.left,
          textDirection: TextDirection.ltr,
        );
      },
    );
  }

  String _truncateStart(
    BuildContext context,
    String value,
    TextStyle? style,
    double maxWidth,
  ) {
    if (maxWidth <= 0 || value.isEmpty) {
      return '';
    }
    final painter = TextPainter(
      maxLines: 1,
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    );

    bool fits(String candidate) {
      painter.text = TextSpan(text: candidate, style: style);
      painter.layout(maxWidth: double.infinity);
      return painter.width <= maxWidth;
    }

    if (fits(value)) {
      return value;
    }

    const prefix = '...';
    var low = 0;
    var high = value.length;
    while (low < high) {
      final mid = (low + high) >> 1;
      if (fits(prefix + value.substring(mid))) {
        high = mid;
      } else {
        low = mid + 1;
      }
    }
    return prefix + value.substring(low);
  }
}

class _WritersideTopicRemovalTarget {
  _WritersideTopicRemovalTarget({
    required this.mode,
    required this.topicPath,
    this.treePath,
    List<int>? nodePath,
  }) : nodePath = nodePath == null ? null : List.unmodifiable(nodePath);

  final WritersideTopicRemovalMode mode;
  final String topicPath;
  final String? treePath;
  final List<int>? nodePath;
}

class _WritersideTopicRemovalDialogResult {
  const _WritersideTopicRemovalDialogResult._({
    required this.reviewUsages,
    required this.updateUsagesAutomatically,
    required this.redirectTarget,
  });

  const _WritersideTopicRemovalDialogResult.review({
    required bool updateUsagesAutomatically,
    required WritersideTopicRedirectTarget? redirectTarget,
  }) : this._(
         reviewUsages: true,
         updateUsagesAutomatically: updateUsagesAutomatically,
         redirectTarget: redirectTarget,
       );

  const _WritersideTopicRemovalDialogResult.apply({
    required bool updateUsagesAutomatically,
    required WritersideTopicRedirectTarget? redirectTarget,
  }) : this._(
         reviewUsages: false,
         updateUsagesAutomatically: updateUsagesAutomatically,
         redirectTarget: redirectTarget,
       );

  final bool reviewUsages;
  final bool updateUsagesAutomatically;
  final WritersideTopicRedirectTarget? redirectTarget;
}

class _WritersideTopicUsageReview {
  const _WritersideTopicUsageReview({
    required this.target,
    required this.analysis,
    required this.updateUsagesAutomatically,
    required this.redirectTopicPath,
  });

  final _WritersideTopicRemovalTarget target;
  final WritersideTopicRemovalAnalysis analysis;
  final bool updateUsagesAutomatically;
  final String? redirectTopicPath;
}

class _WritersideTopicRemovalDialog extends StatefulWidget {
  const _WritersideTopicRemovalDialog({
    required this.analysis,
    required this.initialUpdateUsagesAutomatically,
    required this.initialRedirectTarget,
  });

  final WritersideTopicRemovalAnalysis analysis;
  final bool initialUpdateUsagesAutomatically;
  final WritersideTopicRedirectTarget? initialRedirectTarget;

  @override
  State<_WritersideTopicRemovalDialog> createState() =>
      _WritersideTopicRemovalDialogState();
}

class _WritersideTopicRemovalDialogState
    extends State<_WritersideTopicRemovalDialog> {
  late bool _updateUsagesAutomatically;
  WritersideTopicRedirectTarget? _redirectTarget;

  WritersideTopicRemovalAnalysis get _analysis => widget.analysis;

  bool get _canApply {
    if (_analysis.blockingUsages.isEmpty) {
      return true;
    }
    return _updateUsagesAutomatically && _analysis.canUpdateUsagesAutomatically;
  }

  @override
  void initState() {
    super.initState();
    _updateUsagesAutomatically =
        widget.initialUpdateUsagesAutomatically &&
        _analysis.canUpdateUsagesAutomatically;
    _redirectTarget = widget.initialRedirectTarget;
  }

  @override
  Widget build(BuildContext context) {
    final removeFromInstance =
        _analysis.mode == WritersideTopicRemovalMode.removeFromInstance;
    final relevantUsages = _analysis.relevantUsages;
    final title = removeFromInstance
        ? context.l10n.removeTocElement
        : context.l10n.safeDeleteTopicFile;
    final topicLabel = _analysis.topicTitle?.trim().isNotEmpty == true
        ? _analysis.topicTitle!.trim()
        : _analysis.topicFileName;
    return BusyMarkDialogShell(
      title: title,
      maxWidth: BusyMarkSizes.dialogWide,
      actions: [
        BusyMarkDialogButton(
          label: context.l10n.cancel,
          onPressed: () => Navigator.pop(context),
        ),
        if (relevantUsages.isNotEmpty)
          BusyMarkDialogButton(
            label: context.l10n.reviewUsages,
            icon: BusyMarkGlyphs.search,
            onPressed: () => Navigator.pop(
              context,
              _WritersideTopicRemovalDialogResult.review(
                updateUsagesAutomatically: _updateUsagesAutomatically,
                redirectTarget: _redirectTarget,
              ),
            ),
          ),
        BusyMarkDialogButton(
          label: removeFromInstance
              ? context.l10n.removeAction
              : context.l10n.deleteTopicFile,
          icon: removeFromInstance
              ? BusyMarkGlyphs.outdentFor(Directionality.of(context))
              : BusyMarkGlyphs.delete,
          destructive: true,
          onPressed: _canApply
              ? () => Navigator.pop(
                  context,
                  _WritersideTopicRemovalDialogResult.apply(
                    updateUsagesAutomatically: _updateUsagesAutomatically,
                    redirectTarget: _redirectTarget,
                  ),
                )
              : null,
        ),
      ],
      children: [
        Text(
          removeFromInstance
              ? context.l10n.topicRemovalSummary(topicLabel)
              : context.l10n.safeDeleteTopicSummary(topicLabel),
        ),
        if (_analysis.childCount > 0) ...[
          const SizedBox(height: BusyMarkSpacing.md),
          BusyMarkStatusBox(
            message: context.l10n.childTopicsPromoted(_analysis.childCount),
            kind: BusyMarkStatusKind.warning,
          ),
        ],
        if (_analysis.isStartPage) ...[
          const SizedBox(height: BusyMarkSpacing.md),
          BusyMarkStatusBox(
            message: context.l10n.topicIsStartPageRemovalWarning,
            kind: BusyMarkStatusKind.warning,
          ),
        ],
        BusyMarkGroupedList(
          title: context.l10n.topicUsagesCount(relevantUsages.length),
          description: relevantUsages.isEmpty
              ? context.l10n.noBreakingTopicUsages
              : context.l10n.topicUsagesFound,
          filled: true,
          children: [
            for (final kind in WritersideTopicUsageKind.values)
              if (_usageCount(relevantUsages, kind) > 0)
                BusyMarkActionRow(
                  title: _writersideTopicUsageKindLabel(context, kind),
                  subtitle: context.l10n.usageCount(
                    _usageCount(relevantUsages, kind),
                  ),
                  leading: Icon(_writersideTopicUsageKindIcon(kind)),
                ),
          ],
        ),
        BusyMarkGroupedList(
          title: context.l10n.refactoringOptions,
          filled: true,
          children: [
            BusyMarkSwitchRow(
              title: context.l10n.updateUsagesAutomatically,
              subtitle: _analysis.canUpdateUsagesAutomatically
                  ? context.l10n.updateUsagesAutomaticallyDescription
                  : context.l10n.manualUsageUpdatesRequired,
              leading: const Icon(BusyMarkGlyphs.edit),
              value: _updateUsagesAutomatically,
              enabled: _analysis.canUpdateUsagesAutomatically,
              onChanged: (value) {
                setState(() => _updateUsagesAutomatically = value);
              },
            ),
            if (_analysis.redirectTargets.isNotEmpty)
              BusyMarkSwitchRow(
                title: context.l10n.setRedirectTo,
                subtitle: _redirectTarget == null
                    ? context.l10n.noRedirectDescription
                    : _redirectTarget!.label,
                leading: const Icon(BusyMarkGlyphs.link),
                value: _redirectTarget != null,
                onChanged: (value) {
                  setState(() {
                    _redirectTarget = value
                        ? _analysis.redirectTargets.first
                        : null;
                  });
                },
              ),
          ],
        ),
        if (_redirectTarget != null) ...[
          const SizedBox(height: BusyMarkSpacing.md),
          BusyMarkGroupedList(
            filled: true,
            children: [
              BusyMarkActionRow(
                title: context.l10n.redirectTarget,
                leading: const Icon(BusyMarkGlyphs.link),
                trailing: BusyMarkPopupSelector<WritersideTopicRedirectTarget>(
                  value: _redirectTarget,
                  label: _redirectTarget!.label,
                  tooltip: context.l10n.redirectTarget,
                  options: [
                    for (final target in _analysis.redirectTargets)
                      BusyMarkPopupSelectorOption(
                        value: target,
                        label: target.label,
                      ),
                  ],
                  onSelected: (value) {
                    setState(() => _redirectTarget = value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: BusyMarkSpacing.xs),
          Text(
            '${_analysis.oldWebFileName} → ${_redirectTarget!.topicFileName}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: BusyMarkSurfaceColors.of(context).mutedForeground,
            ),
          ),
        ],
        if (!_canApply) ...[
          const SizedBox(height: BusyMarkSpacing.md),
          BusyMarkStatusBox(
            message: context.l10n.remainingUsagesBlockRemoval,
            kind: BusyMarkStatusKind.warning,
          ),
        ],
      ],
    );
  }
}

class _WritersideTopicUsagesSidebar extends StatelessWidget {
  const _WritersideTopicUsagesSidebar({
    required this.review,
    required this.onBack,
    required this.onOpenUsage,
    required this.onDoRefactor,
  });

  final _WritersideTopicUsageReview review;
  final VoidCallback onBack;
  final Future<void> Function(WritersideTopicUsage usage) onOpenUsage;
  final VoidCallback onDoRefactor;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final analysis = review.analysis;
    final groups = <WritersideTopicUsageKind, List<WritersideTopicUsage>>{
      for (final kind in WritersideTopicUsageKind.values)
        kind: [
          for (final usage in analysis.usages)
            if (usage.kind == kind) usage,
        ],
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.sidebar,
            border: Border(bottom: BorderSide(color: colors.subtleBorder)),
          ),
          child: SizedBox(
            height: BusyMarkSizes.paneHeaderHeight,
            child: Row(
              children: [
                const SizedBox(width: BusyMarkSpacing.xs),
                BusyMarkHeaderIconButton(
                  tooltip: context.l10n.back,
                  icon: BusyMarkGlyphs.backFor(Directionality.of(context)),
                  transparent: true,
                  onPressed: onBack,
                ),
                const SizedBox(width: BusyMarkSpacing.xs),
                Icon(
                  BusyMarkGlyphs.search,
                  size: BusyMarkSizes.iconSm,
                  color: colors.mutedForeground,
                ),
                const SizedBox(width: BusyMarkSpacing.sm),
                Expanded(
                  child: Text(
                    context.l10n.usagesOfTopic(analysis.topicFileName),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: BusyMarkSpacing.sm),
              ],
            ),
          ),
        ),
        Expanded(
          child: analysis.usages.isEmpty
              ? _SidebarEmptyState(
                  icon: BusyMarkGlyphs.check,
                  title: context.l10n.noUsagesFound,
                )
              : ListView(
                  padding: BusyMarkInsets.sidebarList,
                  children: [
                    for (final kind in WritersideTopicUsageKind.values)
                      if (groups[kind]!.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            BusyMarkSpacing.sm,
                            BusyMarkSpacing.sm,
                            BusyMarkSpacing.sm,
                            BusyMarkSpacing.xxs,
                          ),
                          child: Text(
                            '${_writersideTopicUsageKindLabel(context, kind)} '
                            '(${groups[kind]!.length})',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: colors.mutedForeground,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0,
                                ),
                          ),
                        ),
                        for (final usage in groups[kind]!) ...[
                          _SidebarNavigationResultRow(
                            title: usage.reference,
                            subtitle:
                                '${busyMarkLtrIsolateFor(context, '${p.basename(usage.filePath)}:${usage.line}:${usage.column}')}'
                                '${usage.relevant ? '' : ' · ${context.l10n.outsideSelectedInstance}'}',
                            icon: _writersideTopicUsageKindIcon(kind),
                            onOpen: () => onOpenUsage(usage),
                          ),
                          Divider(
                            height: BusyMarkStroke.hairline,
                            color: colors.subtleBorder,
                          ),
                        ],
                      ],
                  ],
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(BusyMarkSpacing.sm),
          child: BusyMarkPushButton.standardIcon(
            onPressed: onDoRefactor,
            icon: const Icon(BusyMarkGlyphs.edit),
            label: Text(context.l10n.doRefactor),
          ),
        ),
      ],
    );
  }
}

int _usageCount(
  Iterable<WritersideTopicUsage> usages,
  WritersideTopicUsageKind kind,
) {
  return usages.where((usage) => usage.kind == kind).length;
}

String _writersideTopicUsageKindLabel(
  BuildContext context,
  WritersideTopicUsageKind kind,
) {
  return switch (kind) {
    WritersideTopicUsageKind.tocElement => context.l10n.topicUsageTocElements,
    WritersideTopicUsageKind.startPage => context.l10n.topicUsageStartPages,
    WritersideTopicUsageKind.topicLink => context.l10n.topicUsageTopicLinks,
    WritersideTopicUsageKind.include => context.l10n.topicUsageIncludes,
  };
}

IconData _writersideTopicUsageKindIcon(WritersideTopicUsageKind kind) {
  return switch (kind) {
    WritersideTopicUsageKind.tocElement => BusyMarkGlyphs.tree,
    WritersideTopicUsageKind.startPage => BusyMarkGlyphs.startTopic,
    WritersideTopicUsageKind.topicLink => BusyMarkGlyphs.link,
    WritersideTopicUsageKind.include => BusyMarkGlyphs.insertObject,
  };
}

Future<bool> _confirmDeleteOrphanTopicFile(
  BuildContext context,
  String topicFileName,
) async {
  final confirmed = await showBusyMarkModalDialog<bool>(
    context,
    barrierDismissible: false,
    builder: (dialogContext) => BusyMarkDialogShell(
      title: context.l10n.orphanTopicTitle,
      maxWidth: BusyMarkSizes.dialog,
      actions: [
        BusyMarkDialogButton(
          label: context.l10n.keepTopicFile,
          onPressed: () => Navigator.pop(dialogContext, false),
        ),
        BusyMarkDialogButton(
          label: context.l10n.deleteTopicFile,
          icon: BusyMarkGlyphs.delete,
          destructive: true,
          onPressed: () => Navigator.pop(dialogContext, true),
        ),
      ],
      children: [Text(context.l10n.orphanTopicMessage(topicFileName))],
    ),
  );
  return confirmed ?? false;
}

class _FilesTab extends ConsumerStatefulWidget {
  const _FilesTab({
    required this.workspace,
    required this.onShowFileHistory,
    required this.onRequestTopicRemoval,
  });

  final Workspace workspace;
  final Future<void> Function(DocumentFile file) onShowFileHistory;
  final Future<WritersideTopicRemovalResult?> Function(
    _WritersideTopicRemovalTarget target,
  )
  onRequestTopicRemoval;

  @override
  ConsumerState<_FilesTab> createState() => _FilesTabState();
}

class _FilesTabState extends ConsumerState<_FilesTab> {
  late String _workspaceId;
  late Set<String> _expandedPaths;
  late final FocusNode _treeFocusNode;
  String? _selectedPath;
  _FileTreeClipboardEntry? _cutEntry;

  @override
  void initState() {
    super.initState();
    _workspaceId = widget.workspace.id;
    _expandedPaths = _initialExpandedFileTreePaths(widget.workspace);
    _treeFocusNode = FocusNode(debugLabel: 'BusyMark files tree');
    _selectedPath = widget.workspace.activeFilePath;
  }

  @override
  void didUpdateWidget(covariant _FilesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.workspace.id != _workspaceId) {
      _workspaceId = widget.workspace.id;
      _expandedPaths = _initialExpandedFileTreePaths(widget.workspace);
      _selectedPath = widget.workspace.activeFilePath;
      _cutEntry = null;
      return;
    }
    if (widget.workspace.activeFilePath != oldWidget.workspace.activeFilePath) {
      _expandedPaths.addAll(_activeFileAncestorPaths(widget.workspace));
      _selectedPath = widget.workspace.activeFilePath;
    }
  }

  @override
  void dispose() {
    _treeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tree = _buildFileTree(widget.workspace.files);
    final entries = _visibleFileTreeEntries(tree, _expandedPaths);
    final vcsStatusColors = _FileTreeVcsStatusColors.fromSnapshot(
      widget.workspace,
      ref.watch(gitControllerProvider.select((state) => state.statusSnapshot)),
    );
    if (widget.workspace.files.isEmpty) {
      return _SidebarEmptyState(
        icon: BusyMarkGlyphs.folder,
        title: context.l10n.noFiles,
      );
    }
    return Shortcuts(
      shortcuts: {
        BusyMarkTreeShortcutActivators.deleteSelection:
            const _DeleteSelectedFileTreeEntryIntent(),
      },
      child: Actions(
        actions: {
          _DeleteSelectedFileTreeEntryIntent:
              CallbackAction<_DeleteSelectedFileTreeEntryIntent>(
                onInvoke: (_) {
                  unawaited(_deleteSelectedFileTreeEntry(context));
                  return null;
                },
              ),
        },
        child: Focus(
          focusNode: _treeFocusNode,
          child: ListView.builder(
            padding: BusyMarkInsets.sidebarList,
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final node = entry.node;
              final file = node.file;
              final expanded = _expandedPaths.contains(node.relativePath);
              final openable = file != null && _isOpenableTextDocument(file);
              final historyFile = openable ? file : null;
              final menuPath = _fileTreeEntryPath(entry, widget.workspace);
              final menuName = node.name;
              final menuIsFolder = node.isFolder;
              final selectedHistoryFile = historyFile;
              void selectEntry() {
                _treeFocusNode.requestFocus();
                if (!_sameOptionalPath(_selectedPath, menuPath)) {
                  setState(() => _selectedPath = menuPath);
                }
              }

              void onSecondaryTapUp(TapUpDetails details) {
                selectEntry();
                unawaited(
                  _showFileContextMenu(
                    context,
                    menuName,
                    menuPath,
                    menuIsFolder,
                    selectedHistoryFile,
                    details.globalPosition,
                  ),
                );
              }

              return _SidebarTreeRow(
                title: busyMarkLtrIsolateFor(context, node.name),
                depth: entry.depth,
                icon: _fileTreeIcon(node, expanded: expanded),
                vcsColor: vcsStatusColors.colorForNode(node),
                hasChildren: node.isFolder && node.children.isNotEmpty,
                expanded: expanded,
                selected: _sameOptionalPath(_selectedPath, menuPath),
                enabled: node.isFolder || openable,
                onTap: node.isFolder
                    ? () {
                        selectEntry();
                        setState(() {
                          if (expanded) {
                            _expandedPaths.remove(node.relativePath);
                          } else {
                            _expandedPaths.add(node.relativePath);
                          }
                        });
                      }
                    : openable
                    ? () async {
                        selectEntry();
                        if (await saveOrConfirmSafeToChangeActiveFile(
                          context,
                          ref,
                        )) {
                          await ref
                              .read(workspaceControllerProvider.notifier)
                              .openActiveFile(file.absolutePath);
                          _clearGitDetailSelection(ref);
                        }
                      }
                    : null,
                onSecondaryTapUp: onSecondaryTapUp,
              );
            },
          ),
        ),
      ),
    );
  }

  String _fileTreeEntryPath(_FileTreeEntry entry, Workspace workspace) {
    return entry.node.file?.absolutePath ??
        p.join(workspace.rootPath, entry.node.relativePath);
  }

  Future<void> _showFileContextMenu(
    BuildContext context,
    String name,
    String path,
    bool isFolder,
    DocumentFile? historyFile,
    Offset position,
  ) async {
    final isTopic = _isWritersideTopicFile(widget.workspace, historyFile);
    final cutEntry = _cutEntry;
    final canPaste =
        cutEntry != null &&
        _canPasteFileTreeEntry(cutEntry.path, path, isFolder);
    final gitRelativePath = _gitRelativePathForFileTreeEntry(ref, path);
    final canUseGitFileActions = gitRelativePath != null;
    final action = await _showFileTreeMenu(
      context,
      position,
      safeDeleteTopic: isTopic,
      showHistory: historyFile != null,
      showPaste: canPaste,
      enableGitActions: canUseGitFileActions,
    );
    if (!context.mounted || action == null) {
      return;
    }
    switch (action) {
      case _FileTreeAction.newFile:
        final directory = isFolder ? path : p.dirname(path);
        final fileName = await _showFileNameDialog(
          context,
          title: context.l10n.newFile,
          actionLabel: context.l10n.create,
          initialValue: 'untitled.md',
        );
        if (fileName == null ||
            !context.mounted ||
            !await saveOrConfirmSafeToChangeActiveFile(context, ref)) {
          return;
        }
        final created = await ref
            .read(workspaceControllerProvider.notifier)
            .createWorkspaceFile(directory, fileName);
        if (created) {
          _expandedPaths.addAll(_directoryAncestorPaths(directory));
          _clearGitDetailSelection(ref);
        }
      case _FileTreeAction.rename:
        final newName = await _showFileNameDialog(
          context,
          title: context.l10n.rename,
          actionLabel: context.l10n.rename,
          initialValue: name,
        );
        if (newName == null ||
            !context.mounted ||
            !await saveOrConfirmSafeToChangeActiveFile(context, ref)) {
          return;
        }
        final renamed = isTopic
            ? await ref
                  .read(workspaceControllerProvider.notifier)
                  .renameWritersideTopicFile(path, newName)
            : await ref
                  .read(workspaceControllerProvider.notifier)
                  .renameWorkspaceEntity(path, newName);
        if (renamed) {
          setState(() => _cutEntry = null);
          _clearGitDetailSelection(ref);
        }
      case _FileTreeAction.cut:
        setState(() {
          _cutEntry = _FileTreeClipboardEntry(path: path);
        });
      case _FileTreeAction.paste:
        final entry = _cutEntry;
        if (entry == null ||
            !await saveOrConfirmSafeToChangeActiveFile(context, ref)) {
          return;
        }
        final directory = isFolder ? path : p.dirname(path);
        final moved = await ref
            .read(workspaceControllerProvider.notifier)
            .moveWorkspaceEntity(entry.path, directory);
        if (moved) {
          setState(() => _cutEntry = null);
          _expandedPaths.addAll(_directoryAncestorPaths(directory));
          _clearGitDetailSelection(ref);
        }
      case _FileTreeAction.delete:
        final matchingEntry = _fileTreeEntryForPath(path);
        if (matchingEntry != null) {
          await _deleteFileTreeEntry(context, matchingEntry);
        }
      case _FileTreeAction.addToGit:
        final relativePath = gitRelativePath;
        if (relativePath == null) {
          return;
        }
        await ref.read(gitControllerProvider.notifier).stageFiles([
          relativePath,
        ]);
      case _FileTreeAction.copyName:
        await _copyToClipboard(name);
      case _FileTreeAction.copyPath:
        await _copyToClipboard(path);
      case _FileTreeAction.openInFiles:
        await _openInFiles(context, path);
      case _FileTreeAction.fileHistory:
        final file = historyFile;
        if (file != null && canUseGitFileActions) {
          await widget.onShowFileHistory(file);
        }
    }
  }

  _FileTreeEntry? _fileTreeEntryForPath(String path) {
    final entries = _visibleFileTreeEntries(
      _buildFileTree(widget.workspace.files),
      _expandedPaths,
    );
    for (final entry in entries) {
      if (p.equals(_fileTreeEntryPath(entry, widget.workspace), path)) {
        return entry;
      }
    }
    return null;
  }

  Future<void> _deleteSelectedFileTreeEntry(BuildContext context) async {
    final path = _selectedPath;
    if (path == null) {
      return;
    }
    final file = _documentFileForPath(widget.workspace, path);
    if (_isWritersideTopicFile(widget.workspace, file)) {
      final result = await widget.onRequestTopicRemoval(
        _WritersideTopicRemovalTarget(
          mode: WritersideTopicRemovalMode.safeDeleteFile,
          topicPath: path,
        ),
      );
      if (mounted && result != null) {
        _clearDeletedFileTreeState(path);
      }
      return;
    }
    final entry = _fileTreeEntryForPath(path);
    if (entry != null) {
      await _deleteFileTreeEntry(context, entry);
    }
  }

  Future<void> _deleteFileTreeEntry(
    BuildContext context,
    _FileTreeEntry entry,
  ) async {
    final node = entry.node;
    final file = node.file;
    final path = _fileTreeEntryPath(entry, widget.workspace);
    final isTopic = _isWritersideTopicFile(widget.workspace, file);
    if (isTopic) {
      final result = await widget.onRequestTopicRemoval(
        _WritersideTopicRemovalTarget(
          mode: WritersideTopicRemovalMode.safeDeleteFile,
          topicPath: path,
        ),
      );
      if (!mounted || result == null) {
        return;
      }
      _clearDeletedFileTreeState(path);
      return;
    }
    final confirmed = await _confirmDeleteFileTreeEntry(
      context,
      ref,
      name: node.name,
      isFolder: node.isFolder,
    );
    if (!confirmed ||
        !context.mounted ||
        !await saveOrConfirmSafeToChangeActiveFile(context, ref)) {
      return;
    }
    final deleted = await ref
        .read(workspaceControllerProvider.notifier)
        .deleteWorkspaceEntity(path);
    if (!mounted || !deleted) {
      return;
    }
    _clearDeletedFileTreeState(path);
  }

  void _clearDeletedFileTreeState(String path) {
    final cutEntry = _cutEntry;
    if (cutEntry != null &&
        (p.equals(cutEntry.path, path) || p.isWithin(path, cutEntry.path))) {
      setState(() {
        _cutEntry = null;
        _selectedPath = null;
      });
    } else if (_sameOptionalPath(_selectedPath, path)) {
      setState(() => _selectedPath = null);
    }
    _clearGitDetailSelection(ref);
  }

  Iterable<String> _directoryAncestorPaths(String absoluteDirectory) {
    final relative = p
        .normalize(
          p.relative(absoluteDirectory, from: widget.workspace.rootPath),
        )
        .replaceAll(r'\', '/');
    if (relative == '.' || relative.isEmpty || relative.startsWith('../')) {
      return const [];
    }
    final parts = p.posix.split(relative);
    final paths = <String>[];
    for (var index = 1; index <= parts.length; index += 1) {
      paths.add(p.posix.joinAll(parts.take(index)));
    }
    return paths;
  }
}

class _FileTreeClipboardEntry {
  const _FileTreeClipboardEntry({required this.path});

  final String path;
}

class _DeleteSelectedFileTreeEntryIntent extends Intent {
  const _DeleteSelectedFileTreeEntryIntent();
}

bool _isWritersideTopicFile(Workspace workspace, DocumentFile? file) {
  if (file == null) {
    return false;
  }
  if (file.kind == DocumentKind.writersideMarkdownTopic ||
      file.kind == DocumentKind.writersideXmlTopic) {
    return true;
  }
  return workspace.writersideModule?.topics.any(
        (topic) => p.equals(topic.filePath, file.absolutePath),
      ) ??
      false;
}

enum _FileTreeAction {
  newFile,
  rename,
  cut,
  paste,
  delete,
  addToGit,
  copyName,
  copyPath,
  openInFiles,
  fileHistory,
}

Future<_FileTreeAction?> _showFileTreeMenu(
  BuildContext context,
  Offset position, {
  required bool safeDeleteTopic,
  required bool showHistory,
  required bool showPaste,
  required bool enableGitActions,
}) {
  return _showSidebarTreeMenu<_FileTreeAction>(
    context,
    position,
    items: [
      BusyMarkPopupMenuItem(
        value: _FileTreeAction.newFile,
        label: context.l10n.newFile,
        icon: BusyMarkGlyphs.newDocument,
      ),
      BusyMarkPopupMenuItem(
        value: _FileTreeAction.rename,
        label: safeDeleteTopic
            ? context.l10n.renameTopicFile
            : context.l10n.rename,
        icon: BusyMarkGlyphs.edit,
      ),
      BusyMarkPopupMenuItem(
        value: _FileTreeAction.cut,
        label: context.l10n.cut,
        icon: BusyMarkGlyphs.cut,
        enabled: !safeDeleteTopic,
      ),
      BusyMarkPopupMenuItem(
        value: _FileTreeAction.paste,
        label: context.l10n.paste,
        icon: BusyMarkGlyphs.paste,
        enabled: showPaste,
      ),
      BusyMarkPopupMenuItem(
        value: _FileTreeAction.delete,
        label: safeDeleteTopic
            ? context.l10n.safeDeleteTopicFile
            : context.l10n.delete,
        icon: BusyMarkGlyphs.delete,
        shortcut: BusyMarkTreeShortcutLabels.deleteSelection,
      ),
      const PopupMenuDivider(height: BusyMarkSpacing.sm),
      BusyMarkPopupMenuItem(
        value: _FileTreeAction.copyName,
        label: context.l10n.copyName,
        icon: BusyMarkGlyphs.copy,
      ),
      BusyMarkPopupMenuItem(
        value: _FileTreeAction.copyPath,
        label: context.l10n.copyPath,
        icon: BusyMarkGlyphs.copy,
      ),
      const PopupMenuDivider(height: BusyMarkSpacing.sm),
      BusyMarkPopupMenuItem(
        value: _FileTreeAction.openInFiles,
        label: context.l10n.openInFiles,
        icon: BusyMarkGlyphs.folderOpen,
      ),
      BusyMarkPopupMenuItem(
        value: _FileTreeAction.addToGit,
        label: context.l10n.addToGit,
        icon: BusyMarkGlyphs.branch,
        enabled: enableGitActions,
      ),
      if (showHistory) const PopupMenuDivider(height: BusyMarkSpacing.sm),
      if (showHistory)
        BusyMarkPopupMenuItem(
          value: _FileTreeAction.fileHistory,
          label: context.l10n.fileHistory,
          icon: BusyMarkGlyphs.documentHistory,
          enabled: enableGitActions,
        ),
    ],
  );
}

Future<T?> _showSidebarTreeMenu<T>(
  BuildContext context,
  Offset position, {
  required List<PopupMenuEntry<T>> items,
}) {
  return showBusyMarkContextMenu<T>(context, position, items: items);
}

bool _canPasteFileTreeEntry(
  String sourcePath,
  String targetPath,
  bool targetIsFolder,
) {
  final source = p.normalize(sourcePath);
  final targetDirectory = p.normalize(
    targetIsFolder ? targetPath : p.dirname(targetPath),
  );
  if (p.equals(p.dirname(source), targetDirectory)) {
    return false;
  }
  if (p.equals(source, targetDirectory) ||
      p.isWithin(source, targetDirectory)) {
    return false;
  }
  return true;
}

String? _gitRelativePathForFileTreeEntry(WidgetRef ref, String absolutePath) {
  final repository = ref.read(gitControllerProvider).repositoryInfo;
  if (repository == null) {
    return null;
  }
  final root = p.normalize(repository.rootPath);
  final path = p.normalize(absolutePath);
  if (!p.equals(root, path) && !p.isWithin(root, path)) {
    return null;
  }
  final relative = p.relative(path, from: root).replaceAll(r'\', '/');
  if (relative.isEmpty || relative == '.') {
    return null;
  }
  return relative;
}

Future<String?> _showFileNameDialog(
  BuildContext context, {
  required String title,
  required String actionLabel,
  required String initialValue,
}) {
  return showBusyMarkModalEditorDialog<String>(
    context,
    maxWidth: BusyMarkSizes.dialogCompact,
    builder: (context) => _FileNameDialog(
      title: title,
      actionLabel: actionLabel,
      initialValue: initialValue,
    ),
  );
}

class _FileNameDialog extends StatefulWidget {
  const _FileNameDialog({
    required this.title,
    required this.actionLabel,
    required this.initialValue,
  });

  final String title;
  final String actionLabel;
  final String initialValue;

  @override
  State<_FileNameDialog> createState() => _FileNameDialogState();
}

class _FileNameDialogState extends State<_FileNameDialog> {
  late final TextEditingController _controller;

  bool get _canSubmit => _controller.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue)
      ..addListener(_handleChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BusyMarkModalEditorScaffold(
      title: widget.title,
      cancelLabel: context.l10n.cancel,
      saveLabel: widget.actionLabel,
      onCancel: () => Navigator.pop(context),
      onSave: _canSubmit ? _submit : null,
      children: [
        BusyMarkGroupedList(
          filled: true,
          children: [
            BusyMarkGroupedTextEntry(
              label: context.l10n.fileName,
              controller: _controller,
              textDirection: TextDirection.ltr,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
        const SizedBox(height: BusyMarkSpacing.lg),
      ],
    );
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      return;
    }
    Navigator.pop(context, value);
  }

  void _handleChanged() {
    setState(() {});
  }
}

Future<bool> _confirmDeleteFileTreeEntry(
  BuildContext context,
  WidgetRef ref, {
  required String name,
  required bool isFolder,
}) async {
  final headerBar = ref.read(linuxHeaderBarServiceProvider);
  final confirmed = await showBusyMarkModalDialog<bool>(
    context,
    headerBarService: headerBar.isAvailable ? headerBar : null,
    builder: (context) => BusyMarkDialogShell(
      title: isFolder
          ? context.l10n.confirmDeleteFolderTitle
          : context.l10n.confirmDeleteFileTitle,
      maxWidth: BusyMarkSizes.dialog,
      actions: [
        BusyMarkDialogButton(
          label: context.l10n.cancel,
          onPressed: () => Navigator.pop(context, false),
        ),
        BusyMarkDialogButton(
          label: context.l10n.delete,
          icon: BusyMarkGlyphs.delete,
          destructive: true,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
      children: [
        Text(
          isFolder
              ? context.l10n.confirmDeleteFolderMessage(name)
              : context.l10n.confirmDeleteFileMessage(name),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

class _SidebarTreeRow extends StatelessWidget {
  const _SidebarTreeRow({
    required this.title,
    required this.depth,
    required this.icon,
    this.leading,
    this.hasChildren = false,
    this.expanded = false,
    this.selected = false,
    this.enabled = true,
    this.muted = false,
    this.vcsColor,
    this.onToggle,
    this.onTap,
    this.onSecondaryTapUp,
  });

  final String title;
  final int depth;
  final IconData icon;
  final Widget? leading;
  final bool hasChildren;
  final bool expanded;
  final bool selected;
  final bool enabled;
  final bool muted;
  final BusyMarkVcsFileColor? vcsColor;
  final VoidCallback? onToggle;
  final VoidCallback? onTap;
  final GestureTapUpCallback? onSecondaryTapUp;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final direction = Directionality.of(context);
    final clickable = enabled && (onTap != null || onSecondaryTapUp != null);
    final vcsForeground = vcsColor == null
        ? null
        : busyMarkVcsFileStatusColor(context, vcsColor!);
    final foreground = !enabled || muted
        ? colors.disabledForeground
        : vcsForeground ??
              (selected ? colors.foreground : colors.mutedForeground);
    final titleColor = !enabled || muted
        ? colors.disabledForeground
        : vcsForeground ?? colors.foreground;
    final titleStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: titleColor);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BusyMarkStroke.hairline),
      child: Material(
        color: selected
            ? busyMarkSelectedBackground(context)
            : BusyMarkLinuxPalette.transparent,
        borderRadius: BorderRadius.circular(BusyMarkRadius.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          hoverColor: clickable
              ? busyMarkRowHoverColor(context)
              : BusyMarkLinuxPalette.transparent,
          onTap: enabled ? onTap : null,
          onSecondaryTapUp: enabled ? onSecondaryTapUp : null,
          child: SizedBox(
            height: BusyMarkSizes.sidebarTreeRowHeight,
            child: Row(
              children: [
                SizedBox(
                  width:
                      BusyMarkSizes.sidebarTreeDepthBase +
                      depth * BusyMarkSizes.sidebarTreeDepthIndent,
                ),
                SizedBox.square(
                  dimension: BusyMarkSizes.sidebarTreeControl,
                  child: hasChildren
                      ? GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: enabled ? onToggle ?? onTap : null,
                          child: AnimatedRotation(
                            turns: expanded
                                ? direction == TextDirection.rtl
                                      ? -0.25
                                      : 0.25
                                : 0,
                            duration: BusyMarkMotion.sidebarExpand,
                            child: Icon(
                              BusyMarkGlyphs.collapsedTreeArrowFor(direction),
                              size: BusyMarkSizes.sidebarTreeArrow,
                              color: foreground,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(width: BusyMarkSpacing.xs),
                SizedBox.square(
                  dimension: BusyMarkSizes.sidebarTreeControl,
                  child: Center(
                    child:
                        leading ??
                        Icon(
                          icon,
                          size: BusyMarkSizes.iconSm,
                          color: foreground,
                        ),
                  ),
                ),
                const SizedBox(width: BusyMarkSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                  ),
                ),
                const SizedBox(width: BusyMarkSpacing.xs),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

IconData _fileTreeIcon(_FileTreeNode node, {required bool expanded}) {
  if (node.isFolder) {
    return expanded ? YaruIcons.folder_open : YaruIcons.folder;
  }
  return switch (node.file!.kind) {
    DocumentKind.markdown ||
    DocumentKind.writersideMarkdownTopic => YaruIcons.text_editor,
    DocumentKind.writersideXmlTopic => YaruIcons.document,
    DocumentKind.tree => BusyMarkGlyphs.tree,
    DocumentKind.config => YaruIcons.gear,
    DocumentKind.variables => BusyMarkGlyphs.symbols,
    DocumentKind.categories => BusyMarkGlyphs.category,
    DocumentKind.image => BusyMarkGlyphs.image,
    _ => YaruIcons.document,
  };
}

bool _isOpenableTextDocument(DocumentFile file) {
  return switch (file.kind) {
    DocumentKind.markdown ||
    DocumentKind.writersideMarkdownTopic ||
    DocumentKind.writersideXmlTopic ||
    DocumentKind.tree ||
    DocumentKind.config ||
    DocumentKind.variables ||
    DocumentKind.categories ||
    DocumentKind.resource => true,
    DocumentKind.image || DocumentKind.unknown => false,
  };
}

class _FileTreeNode {
  const _FileTreeNode({
    required this.name,
    required this.relativePath,
    required this.children,
    this.file,
  });

  final String name;
  final String relativePath;
  final List<_FileTreeNode> children;
  final DocumentFile? file;

  bool get isFolder => file == null;
}

class _MutableFileTreeNode {
  _MutableFileTreeNode({required this.name, required this.relativePath});

  final String name;
  final String relativePath;
  DocumentFile? file;
  final children = <String, _MutableFileTreeNode>{};
}

class _FileTreeEntry {
  const _FileTreeEntry({required this.node, required this.depth});

  final _FileTreeNode node;
  final int depth;
}

class _FileTreeVcsStatusColors {
  const _FileTreeVcsStatusColors({
    required Map<String, BusyMarkVcsFileColor> files,
    required Map<String, BusyMarkVcsFileColor> folders,
  }) : _files = files,
       _folders = folders;

  const _FileTreeVcsStatusColors.empty()
    : _files = const {},
      _folders = const {};

  final Map<String, BusyMarkVcsFileColor> _files;
  final Map<String, BusyMarkVcsFileColor> _folders;

  factory _FileTreeVcsStatusColors.fromSnapshot(
    Workspace workspace,
    GitStatusSnapshot? snapshot,
  ) {
    if (snapshot == null || snapshot.files.isEmpty) {
      return const _FileTreeVcsStatusColors.empty();
    }
    final workspaceRoot = p.normalize(workspace.rootPath);
    final files = <String, BusyMarkVcsFileColor>{};
    final folders = <String, BusyMarkVcsFileColor>{};

    for (final status in snapshot.files) {
      final color = busyMarkVcsFileColorForGitStatus(status);
      final absolutePath = p.normalize(status.absolutePath);
      final relativePath = _workspaceRelativePath(
        workspaceRoot: workspaceRoot,
        absolutePath: absolutePath,
      );
      if (relativePath == null) {
        continue;
      }
      files[absolutePath] = _dominantVcsFileColor(files[absolutePath], color);
      final parts = p.posix
          .split(relativePath)
          .where((part) => part.isNotEmpty)
          .toList();
      for (var index = 1; index < parts.length; index += 1) {
        final folderPath = p.posix.joinAll(parts.take(index));
        folders[folderPath] = _dominantVcsFileColor(folders[folderPath], color);
      }
    }

    return _FileTreeVcsStatusColors(files: files, folders: folders);
  }

  BusyMarkVcsFileColor? colorForNode(_FileTreeNode node) {
    if (node.isFolder) {
      return _folders[node.relativePath];
    }
    final file = node.file;
    if (file == null) {
      return null;
    }
    return _files[p.normalize(file.absolutePath)];
  }
}

String? _workspaceRelativePath({
  required String workspaceRoot,
  required String absolutePath,
}) {
  if (!p.equals(workspaceRoot, absolutePath) &&
      !p.isWithin(workspaceRoot, absolutePath)) {
    return null;
  }
  final relativePath = p
      .relative(absolutePath, from: workspaceRoot)
      .replaceAll(r'\', '/');
  if (relativePath.isEmpty || relativePath == '.') {
    return null;
  }
  return relativePath;
}

BusyMarkVcsFileColor _dominantVcsFileColor(
  BusyMarkVcsFileColor? current,
  BusyMarkVcsFileColor candidate,
) {
  if (current == null) {
    return candidate;
  }
  return _vcsFileColorPriority(candidate) > _vcsFileColorPriority(current)
      ? candidate
      : current;
}

int _vcsFileColorPriority(BusyMarkVcsFileColor color) {
  return switch (color) {
    BusyMarkVcsFileColor.modified => 10,
    BusyMarkVcsFileColor.untracked => 20,
    BusyMarkVcsFileColor.copied => 30,
    BusyMarkVcsFileColor.renamed => 40,
    BusyMarkVcsFileColor.added => 50,
    BusyMarkVcsFileColor.deleted => 60,
    BusyMarkVcsFileColor.conflicted => 70,
  };
}

List<_FileTreeNode> _buildFileTree(List<DocumentFile> files) {
  final root = _MutableFileTreeNode(name: '', relativePath: '');
  final sortedFiles = [...files]
    ..sort((a, b) => a.relativePath.compareTo(b.relativePath));

  for (final file in sortedFiles) {
    final parts = file.relativePath
        .split('/')
        .where((part) => part.isNotEmpty)
        .toList();
    var parent = root;
    for (var index = 0; index < parts.length; index++) {
      final name = parts[index];
      final relativePath = parts.take(index + 1).join('/');
      final node = parent.children.putIfAbsent(
        name,
        () => _MutableFileTreeNode(name: name, relativePath: relativePath),
      );
      if (index == parts.length - 1) {
        node.file = file;
      }
      parent = node;
    }
  }

  return root.children.values.map(_immutableFileTreeNode).toList()
    ..sort(_compareFileTreeNodes);
}

_FileTreeNode _immutableFileTreeNode(_MutableFileTreeNode node) {
  final children = node.children.values.map(_immutableFileTreeNode).toList()
    ..sort(_compareFileTreeNodes);
  return _FileTreeNode(
    name: node.name,
    relativePath: node.relativePath,
    file: node.file,
    children: children,
  );
}

int _compareFileTreeNodes(_FileTreeNode a, _FileTreeNode b) {
  if (a.isFolder != b.isFolder) {
    return a.isFolder ? -1 : 1;
  }
  return a.name.toLowerCase().compareTo(b.name.toLowerCase());
}

List<_FileTreeEntry> _visibleFileTreeEntries(
  List<_FileTreeNode> nodes,
  Set<String> expandedPaths,
) {
  final entries = <_FileTreeEntry>[];
  void visit(_FileTreeNode node, int depth) {
    entries.add(_FileTreeEntry(node: node, depth: depth));
    if (!node.isFolder || !expandedPaths.contains(node.relativePath)) {
      return;
    }
    for (final child in node.children) {
      visit(child, depth + 1);
    }
  }

  for (final node in nodes) {
    visit(node, 0);
  }
  return entries;
}

Set<String> _initialExpandedFileTreePaths(Workspace workspace) {
  final expanded = <String>{};
  for (final file in workspace.files) {
    final parts = file.relativePath.split('/').where((part) => part.isNotEmpty);
    if (parts.length > 1) {
      expanded.add(parts.first);
    }
  }
  expanded.addAll(_activeFileAncestorPaths(workspace));
  return expanded;
}

Set<String> _activeFileAncestorPaths(Workspace workspace) {
  final activeFilePath = workspace.activeFilePath;
  if (activeFilePath == null) {
    return const {};
  }

  String? relativePath;
  for (final file in workspace.files) {
    if (file.absolutePath == activeFilePath) {
      relativePath = file.relativePath;
      break;
    }
  }
  if (relativePath == null) {
    return const {};
  }

  final parts = relativePath
      .split('/')
      .where((part) => part.isNotEmpty)
      .toList();
  final ancestors = <String>{};
  for (var index = 0; index < parts.length - 1; index++) {
    ancestors.add(parts.take(index + 1).join('/'));
  }
  return ancestors;
}

class _TocTab extends ConsumerStatefulWidget {
  const _TocTab({
    required this.workspace,
    required this.onShowFileHistory,
    required this.onRequestTopicRemoval,
  });

  final Workspace workspace;
  final Future<void> Function(DocumentFile file) onShowFileHistory;
  final Future<WritersideTopicRemovalResult?> Function(
    _WritersideTopicRemovalTarget target,
  )
  onRequestTopicRemoval;

  @override
  ConsumerState<_TocTab> createState() => _TocTabState();
}

class _TocTabState extends ConsumerState<_TocTab> {
  late String _workspaceId;
  late String _tocStructureKey;
  String? _selectedInstanceTreePath;
  late Set<String> _expandedNodeKeys;
  late final FocusNode _treeFocusNode;
  String? _selectedNodePathKey;
  _TocTreeClipboardEntry? _cutEntry;

  @override
  void initState() {
    super.initState();
    _workspaceId = widget.workspace.id;
    _tocStructureKey = _tocStructureSignature(widget.workspace);
    _selectedInstanceTreePath = _preferredInstanceTreePath(widget.workspace);
    _expandedNodeKeys = _initialExpandedTocNodeKeys(
      widget.workspace,
      treePath: _selectedInstanceTreePath,
    );
    _selectedNodePathKey = _activeTocNodePathKey(
      widget.workspace,
      treePath: _selectedInstanceTreePath,
    );
    _treeFocusNode = FocusNode(debugLabel: 'BusyMark topics tree');
  }

  @override
  void dispose() {
    _treeFocusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _TocTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextStructureKey = _tocStructureSignature(widget.workspace);
    if (widget.workspace.id != _workspaceId) {
      _workspaceId = widget.workspace.id;
      _tocStructureKey = nextStructureKey;
      _selectedInstanceTreePath = _preferredInstanceTreePath(widget.workspace);
      _expandedNodeKeys = _initialExpandedTocNodeKeys(
        widget.workspace,
        treePath: _selectedInstanceTreePath,
      );
      _selectedNodePathKey = _activeTocNodePathKey(
        widget.workspace,
        treePath: _selectedInstanceTreePath,
      );
      _cutEntry = null;
      return;
    }
    if (nextStructureKey != _tocStructureKey) {
      _tocStructureKey = nextStructureKey;
      _selectedInstanceTreePath = _preferredInstanceTreePath(
        widget.workspace,
        currentTreePath: _selectedInstanceTreePath,
      );
      // Structural keys are positional, so every insertion, removal, or move
      // can invalidate otherwise unrelated expansion paths.
      _expandedNodeKeys = _initialExpandedTocNodeKeys(
        widget.workspace,
        treePath: _selectedInstanceTreePath,
      );
      _cutEntry = null;
      _selectedNodePathKey = _activeTocNodePathKey(
        widget.workspace,
        treePath: _selectedInstanceTreePath,
      );
    }
    if (widget.workspace.activeFilePath != oldWidget.workspace.activeFilePath) {
      final previousInstanceTreePath = _selectedInstanceTreePath;
      _selectedInstanceTreePath =
          _tocInstanceTreePathForActiveFile(
            widget.workspace,
            preferredTreePath: _selectedInstanceTreePath,
          ) ??
          _selectedInstanceTreePath;
      if (!_sameOptionalPath(
        previousInstanceTreePath,
        _selectedInstanceTreePath,
      )) {
        _expandedNodeKeys = _initialExpandedTocNodeKeys(
          widget.workspace,
          treePath: _selectedInstanceTreePath,
        );
      }
      _expandedNodeKeys.addAll(
        _activeTocAncestorKeys(
          widget.workspace,
          treePath: _selectedInstanceTreePath,
        ),
      );
      _selectedNodePathKey = _activeTocNodePathKey(
        widget.workspace,
        treePath: _selectedInstanceTreePath,
      );
    }
  }

  String? _preferredInstanceTreePath(
    Workspace workspace, {
    String? currentTreePath,
  }) {
    final storedId = ref
        .read(appSettingsControllerProvider)
        .selectedWritersideInstanceId(workspace.rootPath);
    if (currentTreePath == null && storedId != null) {
      final stored = workspace.writersideModule?.instances
          .where((instance) => instance.id == storedId)
          .firstOrNull;
      if (stored != null) {
        return stored.sourceTreePath;
      }
    }
    return _preferredTocInstanceTreePath(
      workspace,
      currentTreePath: currentTreePath,
    );
  }

  @override
  Widget build(BuildContext context) {
    final module = widget.workspace.writersideModule;
    if (module == null || module.instances.isEmpty) {
      return _SidebarEmptyState(
        icon: BusyMarkGlyphs.tree,
        title: context.l10n.noWritersideToc,
      );
    }
    final instance =
        _tocInstanceForTreePath(module, _selectedInstanceTreePath) ??
        _defaultWritersideInstance(module);
    final instanceColor = ref
        .watch(appSettingsControllerProvider)
        .writersideInstanceIconColor(widget.workspace.rootPath, instance.id);
    final entries = _visibleTocTreeEntries(
      instance.navigationTocRoots,
      _expandedNodeKeys,
    );
    _TocTreeEntry? selectedEntry;
    for (final entry in entries) {
      if (entry.pathKey == _selectedNodePathKey) {
        selectedEntry = entry;
        break;
      }
    }
    return Shortcuts(
      shortcuts: {
        BusyMarkTreeShortcutActivators.deleteSelection:
            const _RemoveSelectedTocEntryIntent(),
      },
      child: Actions(
        actions: {
          _RemoveSelectedTocEntryIntent:
              CallbackAction<_RemoveSelectedTocEntryIntent>(
                onInvoke: (_) {
                  final entry = selectedEntry;
                  if (entry != null) {
                    unawaited(
                      _removeTocEntry(
                        context,
                        instanceTreePath: instance.sourceTreePath,
                        entry: entry,
                      ),
                    );
                  }
                  return null;
                },
              ),
        },
        child: Focus(
          focusNode: _treeFocusNode,
          child: ListView.builder(
            padding: BusyMarkInsets.sidebarList,
            itemCount: entries.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _TocHeader(
                  instances: module.instances,
                  selectedInstance: instance,
                  selectedColor: instanceColor,
                  onSelectInstance: (treePath) {
                    if (p.equals(treePath, instance.sourceTreePath)) {
                      return;
                    }
                    setState(() {
                      _selectedInstanceTreePath = treePath;
                      _expandedNodeKeys = _initialExpandedTocNodeKeys(
                        widget.workspace,
                        treePath: treePath,
                      );
                      _selectedNodePathKey = _activeTocNodePathKey(
                        widget.workspace,
                        treePath: treePath,
                      );
                      _cutEntry = null;
                    });
                    final selected = _tocInstanceForTreePath(module, treePath);
                    if (selected != null) {
                      unawaited(
                        ref
                            .read(appSettingsControllerProvider.notifier)
                            .selectWritersideInstance(
                              widget.workspace.rootPath,
                              selected.id,
                            ),
                      );
                    }
                  },
                  onCreateTopic: () => _showCreateTopicDialog(
                    context,
                    instanceTreePath: instance.sourceTreePath,
                    placement: WritersideTopicCreatePlacement.root,
                    referenceEntry: null,
                  ),
                  onCreateHelpInstance: () => _showInstanceEditor(
                    context,
                    BusyMarkWritersideInstanceDialogMode.createHelp,
                  ),
                  onImportMarkdownInstance: () =>
                      _showMarkdownInstanceImport(context),
                  onCreateLibrary: () => _showInstanceEditor(
                    context,
                    BusyMarkWritersideInstanceDialogMode.createLibrary,
                  ),
                  onEditInstance: () => _showInstanceEditor(
                    context,
                    BusyMarkWritersideInstanceDialogMode.edit,
                    instance: instance,
                  ),
                  onChangeColor: () =>
                      _showInstanceColorDialog(context, instance),
                  onOpenTocFile: () =>
                      _openInstanceTree(context, instance.sourceTreePath),
                );
              }
              final entry = entries[index - 1];
              final node = entry.node;
              final key = entry.pathKey;
              final expanded = _expandedNodeKeys.contains(key);
              final hasChildren = node.children.isNotEmpty;
              final topicReference = node.topicReference;
              final writersideTopic =
                  topicReference == null || node.origin != null
                  ? null
                  : module.topicByReference(topicReference);
              final topicPath = writersideTopic?.filePath;
              final rawLabel = _tocNodeLabel(context, node);
              final label = _tocNodeDisplayLabel(context, node);
              void selectEntry() {
                _treeFocusNode.requestFocus();
                if (_selectedNodePathKey != entry.pathKey) {
                  setState(() => _selectedNodePathKey = entry.pathKey);
                }
              }

              void toggle() {
                setState(() {
                  if (expanded) {
                    _expandedNodeKeys.remove(key);
                  } else {
                    _expandedNodeKeys.add(key);
                  }
                });
              }

              return _SidebarTreeRow(
                title: label,
                enabled: true,
                selected: _selectedNodePathKey == null
                    ? topicPath == widget.workspace.activeFilePath
                    : entry.pathKey == _selectedNodePathKey,
                depth: entry.depth,
                icon: node.includeResolutionError != null
                    ? BusyMarkGlyphs.error
                    : node.workInProgress
                    ? BusyMarkGlyphs.warning
                    : node.href != null
                    ? BusyMarkGlyphs.externalLink
                    : BusyMarkGlyphs.document,
                hasChildren: hasChildren,
                expanded: expanded,
                muted: node.hidden,
                onToggle: hasChildren ? toggle : null,
                onTap: topicPath != null
                    ? () async {
                        selectEntry();
                        final canOpen =
                            await saveOrConfirmSafeToChangeActiveFile(
                              context,
                              ref,
                            );
                        if (!canOpen || !mounted || !context.mounted) {
                          return;
                        }
                        await ref
                            .read(workspaceControllerProvider.notifier)
                            .openActiveFile(topicPath);
                        if (mounted) {
                          _clearGitDetailSelection(ref);
                        }
                      }
                    : hasChildren
                    ? () {
                        selectEntry();
                        toggle();
                      }
                    : () {
                        selectEntry();
                      },
                onSecondaryTapUp: (details) {
                  selectEntry();
                  unawaited(
                    _showTopicContextMenu(
                      context,
                      instanceTreePath: instance.sourceTreePath,
                      entry: entry,
                      topic: writersideTopic,
                      rawLabel: rawLabel,
                      canEditStructure:
                          node.canEditStructure &&
                          p.equals(
                            node.sourceTreePath!,
                            instance.sourceTreePath,
                          ),
                      position: details.globalPosition,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _removeTocEntry(
    BuildContext context, {
    required String instanceTreePath,
    required _TocTreeEntry entry,
  }) async {
    if (!entry.canEditStructureIn(instanceTreePath)) {
      return;
    }
    if (!_tocTreeEntryStillMatches(widget.workspace, instanceTreePath, entry)) {
      return;
    }
    final reference = entry.node.topicReference;
    final rawNode = _rawTocNodeForEntry(
      widget.workspace,
      instanceTreePath,
      entry,
    );
    if (rawNode == null) {
      return;
    }
    final topic = reference == null
        ? null
        : widget.workspace.writersideModule?.topicByReference(reference);
    if (topic != null) {
      final result = await widget.onRequestTopicRemoval(
        _WritersideTopicRemovalTarget(
          mode: WritersideTopicRemovalMode.removeFromInstance,
          topicPath: topic.filePath,
          treePath: instanceTreePath,
          nodePath: entry.editPath!,
        ),
      );
      if (!mounted || result == null) {
        return;
      }
      setState(() {
        _cutEntry = null;
        _selectedNodePathKey = null;
      });
      _clearGitDetailSelection(ref);
      return;
    }

    final label = _tocNodeLabel(context, entry.node);
    final confirmed = await _confirmRemoveTocEntry(context, ref, name: label);
    if (!confirmed || !context.mounted || !mounted) {
      return;
    }
    final canRemove = await saveOrConfirmSafeToChangeActiveFile(context, ref);
    if (!canRemove ||
        !mounted ||
        !context.mounted ||
        !_tocTreeEntryStillMatches(widget.workspace, instanceTreePath, entry)) {
      return;
    }
    final removed = await ref
        .read(workspaceControllerProvider.notifier)
        .removeWritersideTocEntry(
          treePath: instanceTreePath,
          nodePath: entry.editPath!,
          expectedIdentity: WritersideTocNodeIdentity.fromNode(rawNode),
        );
    if (!mounted || !removed) {
      return;
    }
    setState(() {
      _cutEntry = null;
      _selectedNodePathKey = null;
    });
    _clearGitDetailSelection(ref);
  }

  Future<void> _showTopicContextMenu(
    BuildContext context, {
    required String instanceTreePath,
    required _TocTreeEntry entry,
    required WritersideTopic? topic,
    required String rawLabel,
    required bool canEditStructure,
    required Offset position,
  }) async {
    final topicPath = topic?.filePath;
    final historyFile = topicPath == null
        ? null
        : _documentFileForPath(widget.workspace, topicPath);
    final gitRelativePath = topicPath == null
        ? null
        : _gitRelativePathForFileTreeEntry(ref, topicPath);
    final cutEntry = _cutEntry;
    final rawNode = canEditStructure
        ? _rawTocNodeForEntry(widget.workspace, instanceTreePath, entry)
        : null;
    final canPaste =
        cutEntry != null &&
        _tocClipboardEntryStillMatches(widget.workspace, cutEntry) &&
        canEditStructure &&
        rawNode != null &&
        _canPasteTocTreeEntry(cutEntry, instanceTreePath, entry.editPath!);
    final action = await _showTocTreeMenu(
      context,
      position,
      hasTopicFile: topicPath != null,
      showHistory: historyFile != null,
      showPaste: canPaste,
      enableGitActions: gitRelativePath != null,
      canEditStructure: canEditStructure,
    );
    if (!mounted || !context.mounted || action == null) {
      return;
    }
    bool entryIsCurrent() =>
        _tocTreeEntryStillMatches(widget.workspace, instanceTreePath, entry);
    if (!entryIsCurrent()) {
      return;
    }
    switch (action) {
      case _TocTreeAction.newSiblingTopic:
        if (!canEditStructure) {
          return;
        }
        await _showCreateTopicDialog(
          context,
          instanceTreePath: instanceTreePath,
          placement: WritersideTopicCreatePlacement.sibling,
          referenceEntry: entry,
        );
      case _TocTreeAction.newChildTopic:
        if (!canEditStructure) {
          return;
        }
        await _showCreateTopicDialog(
          context,
          instanceTreePath: instanceTreePath,
          placement: WritersideTopicCreatePlacement.child,
          referenceEntry: entry,
        );
      case _TocTreeAction.rename:
        final path = topicPath;
        if (path == null) {
          return;
        }
        final newName = await _showFileNameDialog(
          context,
          title: context.l10n.rename,
          actionLabel: context.l10n.rename,
          initialValue: p.basename(path),
        );
        if (newName == null || !context.mounted || !mounted) {
          return;
        }
        final canRename = await saveOrConfirmSafeToChangeActiveFile(
          context,
          ref,
        );
        if (!canRename || !mounted || !context.mounted || !entryIsCurrent()) {
          return;
        }
        final renamed = await ref
            .read(workspaceControllerProvider.notifier)
            .renameWritersideTopicFile(path, newName);
        if (!mounted) {
          return;
        }
        if (renamed) {
          setState(() => _cutEntry = null);
          _clearGitDetailSelection(ref);
        }
      case _TocTreeAction.cut:
        if (!canEditStructure || rawNode == null) {
          return;
        }
        setState(() {
          _cutEntry = _TocTreeClipboardEntry(
            treePath: instanceTreePath,
            nodePath: entry.editPath!,
            nodeFingerprint: _tocNodeFingerprint(rawNode),
            nodeIdentity: WritersideTocNodeIdentity.fromNode(rawNode),
          );
        });
      case _TocTreeAction.pasteAfter:
      case _TocTreeAction.pasteAsChild:
        if (!canEditStructure || rawNode == null) {
          return;
        }
        final source = _cutEntry;
        if (source == null ||
            !_tocClipboardEntryStillMatches(widget.workspace, source)) {
          if (source != null && mounted) {
            setState(() => _cutEntry = null);
          }
          return;
        }
        final canMove = await saveOrConfirmSafeToChangeActiveFile(context, ref);
        if (!canMove ||
            !mounted ||
            !context.mounted ||
            !entryIsCurrent() ||
            !_tocClipboardEntryStillMatches(widget.workspace, source)) {
          return;
        }
        final moved = await ref
            .read(workspaceControllerProvider.notifier)
            .moveWritersideTocEntry(
              treePath: instanceTreePath,
              sourcePath: source.nodePath,
              placement: action == _TocTreeAction.pasteAsChild
                  ? WritersideTopicCreatePlacement.child
                  : WritersideTopicCreatePlacement.sibling,
              referencePath: entry.editPath!,
              sourceIdentity: source.nodeIdentity,
              referenceIdentity: WritersideTocNodeIdentity.fromNode(rawNode),
            );
        if (!mounted) {
          return;
        }
        if (moved) {
          setState(() {
            _cutEntry = null;
            _selectedNodePathKey = null;
          });
          _clearGitDetailSelection(ref);
        }
      case _TocTreeAction.removeFromToc:
        if (!canEditStructure) {
          return;
        }
        await _removeTocEntry(
          context,
          instanceTreePath: instanceTreePath,
          entry: entry,
        );
      case _TocTreeAction.delete:
        final path = topicPath;
        if (path == null) {
          return;
        }
        final result = await widget.onRequestTopicRemoval(
          _WritersideTopicRemovalTarget(
            mode: WritersideTopicRemovalMode.safeDeleteFile,
            topicPath: path,
          ),
        );
        if (mounted && result != null) {
          setState(() {
            _cutEntry = null;
            _selectedNodePathKey = null;
          });
          _clearGitDetailSelection(ref);
        }
      case _TocTreeAction.addToGit:
        final relativePath = gitRelativePath;
        if (relativePath != null) {
          await ref.read(gitControllerProvider.notifier).stageFiles([
            relativePath,
          ]);
        }
      case _TocTreeAction.copyName:
        await _copyToClipboard(topic == null ? rawLabel : topic.baseName);
      case _TocTreeAction.copyPath:
        final path = topicPath;
        if (path != null) {
          await _copyToClipboard(path);
        }
      case _TocTreeAction.openInFiles:
        final path = topicPath;
        if (path != null) {
          await _openInFiles(context, path);
        }
      case _TocTreeAction.fileHistory:
        final file = historyFile;
        if (file != null && gitRelativePath != null) {
          await widget.onShowFileHistory(file);
        }
    }
  }

  Future<void> _showInstanceEditor(
    BuildContext context,
    BusyMarkWritersideInstanceDialogMode mode, {
    WritersideInstance? instance,
    String? importRootPath,
    List<WritersideMarkdownImportCandidate> importCandidates = const [],
  }) async {
    final canContinue = await saveOrConfirmSafeToChangeActiveFile(context, ref);
    if (!canContinue || !mounted || !context.mounted) {
      return;
    }
    final headerBar = ref.read(linuxHeaderBarServiceProvider);
    final result =
        await showBusyMarkModalEditorDialog<WritersideInstanceMutationResult>(
          context,
          headerBarService: headerBar.isAvailable ? headerBar : null,
          maxWidth: BusyMarkSizes.dialogWide,
          builder: (dialogContext) => BusyMarkWritersideInstanceDialog(
            workspace: widget.workspace,
            mode: mode,
            instance: instance,
            importRootPath: importRootPath,
            importCandidates: importCandidates,
          ),
        );
    if (result == null || !mounted) {
      return;
    }
    final id = p.basenameWithoutExtension(result.treePath);
    final settings = ref.read(appSettingsControllerProvider.notifier);
    final previousId = result.previousId;
    if (previousId != null && previousId != id) {
      await settings.renameWritersideInstancePreferences(
        widget.workspace.rootPath,
        previousId,
        id,
      );
    }
    await settings.selectWritersideInstance(widget.workspace.rootPath, id);
    if (mounted) {
      setState(() {
        _selectedInstanceTreePath = result.treePath;
        _selectedNodePathKey = null;
        _cutEntry = null;
      });
    }
  }

  Future<void> _showMarkdownInstanceImport(BuildContext context) async {
    final sourcePath = await getDirectoryPath(
      initialDirectory: widget.workspace.rootPath,
      confirmButtonText: context.l10n.open,
      canCreateDirectories: false,
    );
    if (sourcePath == null || !mounted || !context.mounted) {
      return;
    }
    final candidates = await ref
        .read(workspaceControllerProvider.notifier)
        .discoverWritersideMarkdownImport(sourcePath);
    if (candidates == null || !mounted || !context.mounted) {
      return;
    }
    await _showInstanceEditor(
      context,
      BusyMarkWritersideInstanceDialogMode.importMarkdown,
      importRootPath: sourcePath,
      importCandidates: candidates,
    );
  }

  Future<void> _showInstanceColorDialog(
    BuildContext context,
    WritersideInstance instance,
  ) async {
    final settings = ref.read(appSettingsControllerProvider);
    final headerBar = ref.read(linuxHeaderBarServiceProvider);
    final color = await showBusyMarkModalDialog<WritersideInstanceIconColor>(
      context,
      headerBarService: headerBar.isAvailable ? headerBar : null,
      builder: (context) => BusyMarkWritersideInstanceColorDialog(
        selected: settings.writersideInstanceIconColor(
          widget.workspace.rootPath,
          instance.id,
        ),
      ),
    );
    if (color == null || !mounted) {
      return;
    }
    await ref
        .read(appSettingsControllerProvider.notifier)
        .setWritersideInstanceIconColor(
          widget.workspace.rootPath,
          instance.id,
          color,
        );
  }

  Future<void> _openInstanceTree(BuildContext context, String treePath) async {
    final canContinue = await saveOrConfirmSafeToChangeActiveFile(context, ref);
    if (!canContinue || !mounted || !context.mounted) {
      return;
    }
    await ref
        .read(workspaceControllerProvider.notifier)
        .openActiveFile(treePath);
  }

  Future<void> _showCreateTopicDialog(
    BuildContext context, {
    required String instanceTreePath,
    required WritersideTopicCreatePlacement placement,
    required _TocTreeEntry? referenceEntry,
  }) async {
    final canContinue = await saveOrConfirmSafeToChangeActiveFile(context, ref);
    if (!canContinue || !mounted || !context.mounted) {
      return;
    }
    final rawReference = referenceEntry == null
        ? null
        : _rawTocNodeForEntry(
            widget.workspace,
            instanceTreePath,
            referenceEntry,
          );
    if (referenceEntry != null && rawReference == null) {
      return;
    }
    final headerBar = ref.read(linuxHeaderBarServiceProvider);
    await showBusyMarkModalEditorDialog<void>(
      context,
      headerBarService: headerBar.isAvailable ? headerBar : null,
      maxWidth: BusyMarkSizes.dialogWide,
      builder: (dialogContext) => _CreateWritersideTopicDialog(
        workspace: widget.workspace,
        instanceTreePath: instanceTreePath,
        placement: placement,
        referencePath: referenceEntry?.editPath,
        referenceTopic: referenceEntry?.node.topicFileName,
        referenceIdentity: rawReference == null
            ? null
            : WritersideTocNodeIdentity.fromNode(rawReference),
        referenceLabel: referenceEntry == null
            ? null
            : _tocNodeDisplayLabel(dialogContext, referenceEntry.node),
      ),
    );
  }
}

class _TocTreeClipboardEntry {
  _TocTreeClipboardEntry({
    required this.treePath,
    required List<int> nodePath,
    required this.nodeFingerprint,
    required this.nodeIdentity,
  }) : nodePath = List.unmodifiable(nodePath);

  final String treePath;
  final List<int> nodePath;
  final String nodeFingerprint;
  final WritersideTocNodeIdentity nodeIdentity;
}

class _RemoveSelectedTocEntryIntent extends Intent {
  const _RemoveSelectedTocEntryIntent();
}

enum _TocTreeAction {
  newSiblingTopic,
  newChildTopic,
  rename,
  cut,
  pasteAfter,
  pasteAsChild,
  removeFromToc,
  delete,
  addToGit,
  copyName,
  copyPath,
  openInFiles,
  fileHistory,
}

Future<_TocTreeAction?> _showTocTreeMenu(
  BuildContext context,
  Offset position, {
  required bool hasTopicFile,
  required bool showHistory,
  required bool showPaste,
  required bool enableGitActions,
  required bool canEditStructure,
}) {
  return _showSidebarTreeMenu<_TocTreeAction>(
    context,
    position,
    items: [
      BusyMarkPopupMenuItem(
        value: _TocTreeAction.newSiblingTopic,
        label: context.l10n.newSiblingTopic,
        icon: BusyMarkGlyphs.newDocument,
        enabled: canEditStructure,
      ),
      BusyMarkPopupMenuItem(
        value: _TocTreeAction.newChildTopic,
        label: context.l10n.newChildTopic,
        icon: BusyMarkGlyphs.tree,
        enabled: canEditStructure,
      ),
      const PopupMenuDivider(height: BusyMarkSpacing.sm),
      BusyMarkPopupMenuItem(
        value: _TocTreeAction.rename,
        label: context.l10n.renameTopicFile,
        icon: BusyMarkGlyphs.edit,
        enabled: hasTopicFile,
      ),
      BusyMarkPopupMenuItem(
        value: _TocTreeAction.cut,
        label: context.l10n.cut,
        icon: BusyMarkGlyphs.cut,
        enabled: canEditStructure,
      ),
      BusyMarkPopupMenuItem(
        value: _TocTreeAction.pasteAfter,
        label: context.l10n.pasteAfterTopic,
        icon: BusyMarkGlyphs.paste,
        enabled: showPaste,
      ),
      BusyMarkPopupMenuItem(
        value: _TocTreeAction.pasteAsChild,
        label: context.l10n.pasteAsChildTopic,
        icon: BusyMarkGlyphs.tree,
        enabled: showPaste,
      ),
      BusyMarkPopupMenuItem(
        value: _TocTreeAction.removeFromToc,
        label: context.l10n.removeTocElement,
        icon: BusyMarkGlyphs.outdentFor(Directionality.of(context)),
        shortcut: BusyMarkTreeShortcutLabels.deleteSelection,
        enabled: canEditStructure,
      ),
      BusyMarkPopupMenuItem(
        value: _TocTreeAction.delete,
        label: context.l10n.safeDeleteTopicFile,
        icon: BusyMarkGlyphs.delete,
        enabled: hasTopicFile,
      ),
      const PopupMenuDivider(height: BusyMarkSpacing.sm),
      BusyMarkPopupMenuItem(
        value: _TocTreeAction.copyName,
        label: context.l10n.copyName,
        icon: BusyMarkGlyphs.copy,
      ),
      BusyMarkPopupMenuItem(
        value: _TocTreeAction.copyPath,
        label: context.l10n.copyPath,
        icon: BusyMarkGlyphs.copy,
        enabled: hasTopicFile,
      ),
      const PopupMenuDivider(height: BusyMarkSpacing.sm),
      BusyMarkPopupMenuItem(
        value: _TocTreeAction.openInFiles,
        label: context.l10n.openInFiles,
        icon: BusyMarkGlyphs.folderOpen,
        enabled: hasTopicFile,
      ),
      BusyMarkPopupMenuItem(
        value: _TocTreeAction.addToGit,
        label: context.l10n.addToGit,
        icon: BusyMarkGlyphs.branch,
        enabled: enableGitActions,
      ),
      if (showHistory) const PopupMenuDivider(height: BusyMarkSpacing.sm),
      if (showHistory)
        BusyMarkPopupMenuItem(
          value: _TocTreeAction.fileHistory,
          label: context.l10n.fileHistory,
          icon: BusyMarkGlyphs.documentHistory,
          enabled: enableGitActions,
        ),
    ],
  );
}

bool _canPasteTocTreeEntry(
  _TocTreeClipboardEntry source,
  String targetTreePath,
  List<int> targetPath,
) {
  if (!p.equals(source.treePath, targetTreePath) ||
      _sameTocPath(source.nodePath, targetPath)) {
    return false;
  }
  return !_tocPathContains(source.nodePath, targetPath);
}

bool _tocClipboardEntryStillMatches(
  Workspace workspace,
  _TocTreeClipboardEntry source,
) {
  return _tocPathStillMatches(
    workspace,
    source.treePath,
    source.nodePath,
    source.nodeFingerprint,
  );
}

bool _tocTreeEntryStillMatches(
  Workspace workspace,
  String treePath,
  _TocTreeEntry entry,
) {
  if (!entry.canEditStructureIn(treePath)) {
    final module = workspace.writersideModule;
    final instance = module == null
        ? null
        : _tocInstanceForTreePath(module, treePath);
    final current = instance == null
        ? null
        : _tocNodeAtPath(instance.navigationTocRoots, entry.path);
    return current != null &&
        _tocNodeFingerprint(current) == _tocNodeFingerprint(entry.node);
  }
  final rawNode = _rawTocNodeForEntry(workspace, treePath, entry);
  return rawNode != null && _sameTocNodeAttributes(rawNode, entry.node);
}

TocNode? _rawTocNodeForEntry(
  Workspace workspace,
  String treePath,
  _TocTreeEntry entry,
) {
  final editPath = entry.editPath;
  if (editPath == null) {
    return null;
  }
  final module = workspace.writersideModule;
  final instance = module == null
      ? null
      : _tocInstanceForTreePath(module, treePath);
  return instance == null ? null : _tocNodeAtPath(instance.tocRoots, editPath);
}

bool _sameTocNodeAttributes(TocNode first, TocNode second) {
  return first.topicFileName == second.topicFileName &&
      first.referenceTopicFileName == second.referenceTopicFileName &&
      first.referenceInstanceId == second.referenceInstanceId &&
      first.href == second.href &&
      first.tocTitle == second.tocTitle &&
      first.id == second.id &&
      first.acceptsWebFileNames == second.acceptsWebFileNames &&
      first.acceptsWebFileNamesRef == second.acceptsWebFileNamesRef &&
      first.targetForAcceptWebFileNames == second.targetForAcceptWebFileNames &&
      first.instanceCondition == second.instanceCondition &&
      first.customFilter == second.customFilter &&
      first.origin == second.origin &&
      first.hidden == second.hidden &&
      first.workInProgress == second.workInProgress;
}

bool _tocPathStillMatches(
  Workspace workspace,
  String treePath,
  List<int> nodePath,
  String nodeFingerprint,
) {
  final module = workspace.writersideModule;
  if (module == null) {
    return false;
  }
  for (final instance in module.instances) {
    if (!p.equals(instance.sourceTreePath, treePath)) {
      continue;
    }
    final node = _tocNodeAtPath(instance.tocRoots, nodePath);
    return node != null && _tocNodeFingerprint(node) == nodeFingerprint;
  }
  return false;
}

TocNode? _tocNodeAtPath(List<TocNode> roots, List<int> path) {
  if (path.isEmpty) {
    return null;
  }
  var siblings = roots;
  TocNode? node;
  for (final index in path) {
    if (index < 0 || index >= siblings.length) {
      return null;
    }
    node = siblings[index];
    siblings = node.children;
  }
  return node;
}

bool _sameTocPath(List<int> first, List<int> second) {
  if (first.length != second.length) {
    return false;
  }
  for (var index = 0; index < first.length; index += 1) {
    if (first[index] != second[index]) {
      return false;
    }
  }
  return true;
}

bool _sameOptionalPath(String? first, String? second) {
  if (first == null || second == null) {
    return first == second;
  }
  return p.equals(first, second);
}

bool _tocPathContains(List<int> parent, List<int> candidate) {
  if (candidate.length <= parent.length) {
    return false;
  }
  for (var index = 0; index < parent.length; index += 1) {
    if (parent[index] != candidate[index]) {
      return false;
    }
  }
  return true;
}

String _tocNodeLabel(BuildContext context, TocNode node) {
  if (node.includeFrom != null || node.includeElementId != null) {
    final source = node.includeFrom ?? '?';
    final element = node.includeElementId ?? '?';
    return '$source#$element';
  }
  return node.tocTitle ??
      node.topicFileName ??
      node.referenceTopicFileName ??
      node.href ??
      context.l10n.tocSection;
}

String _tocNodeDisplayLabel(BuildContext context, TocNode node) {
  final label = _tocNodeLabel(context, node);
  return node.tocTitle == null &&
          (node.topicFileName != null ||
              node.referenceTopicFileName != null ||
              node.href != null ||
              node.includeFrom != null)
      ? busyMarkLtrIsolateFor(context, label)
      : label;
}

String _tocStructureSignature(Workspace workspace) {
  final buffer = StringBuffer();
  void addField(String? value) {
    if (value == null) {
      buffer.write('-1:');
      return;
    }
    buffer
      ..write(value.length)
      ..write(':')
      ..write(value);
  }

  final module = workspace.writersideModule;
  if (module == null) {
    return '';
  }
  for (final instance in module.instances) {
    addField(instance.sourceTreePath);
    buffer
      ..write(instance.navigationTocRoots.length)
      ..write(':');
    for (final node in instance.navigationTocRoots) {
      addField(_tocNodeFingerprint(node));
    }
  }
  return buffer.toString();
}

String _tocNodeFingerprint(TocNode node) {
  final buffer = StringBuffer();
  void addField(String? value) {
    if (value == null) {
      buffer.write('-1:');
      return;
    }
    buffer
      ..write(value.length)
      ..write(':')
      ..write(value);
  }

  addField(node.id);
  addField(node.topicFileName);
  addField(node.referenceTopicFileName);
  addField(node.referenceInstanceId);
  addField(node.href);
  addField(node.tocTitle);
  addField(node.acceptsWebFileNames);
  addField(node.acceptsWebFileNamesRef);
  addField(node.targetForAcceptWebFileNames);
  addField(node.instanceCondition);
  addField(node.customFilter);
  addField(node.origin);
  addField(node.includeFrom);
  addField(node.includeElementId);
  addField(node.includeResolutionError);
  addField(node.span.filePath);
  buffer
    ..write(node.hidden ? '1:' : '0:')
    ..write(node.workInProgress ? '1:' : '0:')
    ..write(node.included ? '1:' : '0:')
    ..write(node.span.startOffset)
    ..write(':')
    ..write(node.span.endOffset)
    ..write(':')
    ..write(node.children.length)
    ..write(':');
  for (final child in node.children) {
    addField(_tocNodeFingerprint(child));
  }
  return buffer.toString();
}

Future<bool> _confirmRemoveTocEntry(
  BuildContext context,
  WidgetRef ref, {
  required String name,
}) async {
  final headerBar = ref.read(linuxHeaderBarServiceProvider);
  final confirmed = await showBusyMarkModalDialog<bool>(
    context,
    headerBarService: headerBar.isAvailable ? headerBar : null,
    builder: (context) => BusyMarkDialogShell(
      title: context.l10n.confirmRemoveFromTocTitle,
      maxWidth: BusyMarkSizes.dialog,
      actions: [
        BusyMarkDialogButton(
          label: context.l10n.cancel,
          onPressed: () => Navigator.pop(context, false),
        ),
        BusyMarkDialogButton(
          label: context.l10n.removeFromToc,
          icon: BusyMarkGlyphs.outdentFor(Directionality.of(context)),
          destructive: true,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
      children: [Text(context.l10n.confirmRemoveFromTocMessage(name))],
    ),
  );
  return confirmed ?? false;
}

enum _TocHeaderAction {
  newTopic,
  newHelpInstance,
  importMarkdownInstance,
  newLibrary,
  editInstance,
  changeColor,
  openTocFile,
}

class _TocHeader extends StatelessWidget {
  const _TocHeader({
    required this.instances,
    required this.selectedInstance,
    required this.selectedColor,
    required this.onSelectInstance,
    required this.onCreateTopic,
    required this.onCreateHelpInstance,
    required this.onImportMarkdownInstance,
    required this.onCreateLibrary,
    required this.onEditInstance,
    required this.onChangeColor,
    required this.onOpenTocFile,
  });

  final List<WritersideInstance> instances;
  final WritersideInstance selectedInstance;
  final WritersideInstanceIconColor selectedColor;
  final ValueChanged<String> onSelectInstance;
  final VoidCallback onCreateTopic;
  final VoidCallback onCreateHelpInstance;
  final VoidCallback onImportMarkdownInstance;
  final VoidCallback onCreateLibrary;
  final VoidCallback onEditInstance;
  final VoidCallback onChangeColor;
  final VoidCallback onOpenTocFile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: BusyMarkInsets.tocHeader,
      child: _SidebarHeaderRow(
        key: const ValueKey('workspace-sidebar-first-content'),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selectedInstance.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: busyMarkSectionHeaderStyle(context),
              ),
            ),
            const SizedBox(width: BusyMarkSpacing.xs),
            BusyMarkHeaderPopupMenuButton<String>(
              tooltip: context.l10n.instanceName,
              icon: BusyMarkGlyphs.tree,
              foregroundColor: writersideInstanceIconColorValue(
                context,
                selectedColor,
              ),
              transparent: true,
              itemBuilder: (context) => [
                for (final instance in instances)
                  BusyMarkPopupMenuItem(
                    value: instance.sourceTreePath,
                    label: instance.name,
                    icon: BusyMarkGlyphs.tree,
                    checked: p.equals(
                      instance.sourceTreePath,
                      selectedInstance.sourceTreePath,
                    ),
                    trailingCheck: true,
                  ),
              ],
              onSelected: onSelectInstance,
            ),
            BusyMarkHeaderPopupMenuButton<_TocHeaderAction>(
              key: const ValueKey('workspace-sidebar-toc-menu'),
              tooltip: context.l10n.tocActions,
              icon: BusyMarkGlyphs.menuVertical,
              transparent: true,
              borderRadius: BusyMarkRadius.nativeHeaderButton,
              highlightWhenOpen: false,
              itemBuilder: (context) => [
                BusyMarkPopupMenuItem(
                  value: _TocHeaderAction.newTopic,
                  label: context.l10n.newTopic,
                  icon: BusyMarkGlyphs.newDocument,
                ),
                const PopupMenuDivider(),
                BusyMarkPopupMenuItem(
                  value: _TocHeaderAction.newHelpInstance,
                  label: context.l10n.newHelpInstance,
                  icon: BusyMarkGlyphs.add,
                ),
                BusyMarkPopupMenuItem(
                  value: _TocHeaderAction.importMarkdownInstance,
                  label: context.l10n.importMarkdownInstance,
                  icon: BusyMarkGlyphs.folderOpen,
                ),
                BusyMarkPopupMenuItem(
                  value: _TocHeaderAction.newLibrary,
                  label: context.l10n.newTocLibrary,
                  icon: BusyMarkGlyphs.code,
                ),
                const PopupMenuDivider(),
                BusyMarkPopupMenuItem(
                  value: _TocHeaderAction.editInstance,
                  label: context.l10n.editInstance,
                  icon: BusyMarkGlyphs.edit,
                ),
                BusyMarkPopupMenuItem(
                  value: _TocHeaderAction.changeColor,
                  label: context.l10n.changeInstanceColor,
                  icon: BusyMarkGlyphs.appearance,
                ),
                BusyMarkPopupMenuItem(
                  value: _TocHeaderAction.openTocFile,
                  label: context.l10n.openTocFile,
                  icon: BusyMarkGlyphs.documentOpen,
                ),
              ],
              onSelected: (action) {
                switch (action) {
                  case _TocHeaderAction.newTopic:
                    onCreateTopic();
                  case _TocHeaderAction.newHelpInstance:
                    onCreateHelpInstance();
                  case _TocHeaderAction.importMarkdownInstance:
                    onImportMarkdownInstance();
                  case _TocHeaderAction.newLibrary:
                    onCreateLibrary();
                  case _TocHeaderAction.editInstance:
                    onEditInstance();
                  case _TocHeaderAction.changeColor:
                    onChangeColor();
                  case _TocHeaderAction.openTocFile:
                    onOpenTocFile();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateWritersideTopicDialog extends ConsumerStatefulWidget {
  const _CreateWritersideTopicDialog({
    required this.workspace,
    required this.instanceTreePath,
    required this.placement,
    required this.referencePath,
    required this.referenceTopic,
    required this.referenceIdentity,
    required this.referenceLabel,
  });

  final Workspace workspace;
  final String instanceTreePath;
  final WritersideTopicCreatePlacement placement;
  final List<int>? referencePath;
  final String? referenceTopic;
  final WritersideTocNodeIdentity? referenceIdentity;
  final String? referenceLabel;

  @override
  ConsumerState<_CreateWritersideTopicDialog> createState() =>
      _CreateWritersideTopicDialogState();
}

class _CreateWritersideTopicDialogState
    extends ConsumerState<_CreateWritersideTopicDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _fileNameController;
  late WritersideTopicCreatePlacement _placement;
  var _format = WritersideTopicFormat.markdown;
  var _fileNameEdited = false;
  var _syncingFileName = false;
  var _creating = false;
  String? _creationError;
  var _localizedDefaultsApplied = false;

  @override
  void initState() {
    super.initState();
    _placement = widget.placement;
    _titleController = TextEditingController()
      ..addListener(_handleTitleChanged);
    _fileNameController = TextEditingController(text: 'new-topic.md')
      ..addListener(_handleFileNameChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _fileNameController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_localizedDefaultsApplied) {
      return;
    }
    _localizedDefaultsApplied = true;
    _titleController.text = context.l10n.defaultNewTopicTitle;
  }

  @override
  Widget build(BuildContext context) {
    final titleError = _titleError(context);
    final fileNameError = _fileNameError(context);
    final canCreate = !_creating && titleError == null && fileNameError == null;
    return PopScope(
      canPop: !_creating,
      child: BusyMarkModalEditorScaffold(
        title: _dialogTitle(context),
        cancelLabel: context.l10n.cancel,
        saveLabel: context.l10n.create,
        onCancel: () => Navigator.pop(context),
        cancelEnabled: !_creating,
        onSave: canCreate ? _submit : null,
        saving: _creating,
        children: [
          BusyMarkGroupedList(
            filled: true,
            children: [
              BusyMarkGroupedTextEntry(
                label: context.l10n.topicTitle,
                controller: _titleController,
                autofocus: true,
                textInputAction: TextInputAction.next,
                errorText: titleError,
              ),
              BusyMarkGroupedTextEntry(
                label: context.l10n.fileName,
                controller: _fileNameController,
                textDirection: TextDirection.ltr,
                textInputAction: TextInputAction.done,
                errorText: fileNameError,
                onSubmitted: (_) {
                  if (canCreate) {
                    _submit();
                  }
                },
              ),
            ],
          ),
          BusyMarkGroupedList(
            filled: true,
            children: [
              BusyMarkComboRow<WritersideTopicCreatePlacement>(
                title: context.l10n.topicPlacement,
                subtitle:
                    _placement != WritersideTopicCreatePlacement.root &&
                        widget.referenceLabel != null
                    ? widget.referenceLabel
                    : null,
                leading: const Icon(BusyMarkGlyphs.tree),
                values: [
                  WritersideTopicCreatePlacement.root,
                  if (widget.referencePath != null)
                    WritersideTopicCreatePlacement.sibling,
                  if (widget.referencePath != null)
                    WritersideTopicCreatePlacement.child,
                ],
                selected: _placement,
                labelFor: (value) => _placementLabel(context, value),
                enabled: !_creating,
                onSelected: (value) {
                  setState(() => _placement = value);
                },
              ),
              BusyMarkComboRow<WritersideTopicFormat>(
                title: context.l10n.file,
                leading: const Icon(BusyMarkGlyphs.document),
                values: WritersideTopicFormat.values,
                selected: _format,
                labelFor: (value) => switch (value) {
                  WritersideTopicFormat.markdown => context.l10n.markdown,
                  WritersideTopicFormat.xml => context.l10n.xml,
                },
                enabled: !_creating,
                onSelected: _setFormat,
              ),
            ],
          ),
          if (_creationError != null) ...[
            const SizedBox(height: BusyMarkSpacing.md),
            BusyMarkStatusBox(
              message: _creationError!,
              kind: BusyMarkStatusKind.error,
            ),
          ],
          BusyMarkGroupedList(
            title: context.l10n.location,
            filled: true,
            children: [
              YaruListTile.square(
                title: Directionality(
                  textDirection: TextDirection.ltr,
                  child: SelectableText(
                    _targetPath,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: BusyMarkSurfaceColors.of(context).foreground,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: BusyMarkSpacing.lg),
        ],
      ),
    );
  }

  String _dialogTitle(BuildContext context) {
    return _placement == WritersideTopicCreatePlacement.child
        ? context.l10n.newChildTopic
        : _placement == WritersideTopicCreatePlacement.sibling
        ? context.l10n.newSiblingTopic
        : context.l10n.newTopic;
  }

  String _placementLabel(
    BuildContext context,
    WritersideTopicCreatePlacement placement,
  ) {
    return switch (placement) {
      WritersideTopicCreatePlacement.root => context.l10n.tocRoot,
      WritersideTopicCreatePlacement.sibling => context.l10n.afterSelectedTopic,
      WritersideTopicCreatePlacement.child => context.l10n.insideSelectedTopic,
    };
  }

  String? _titleError(BuildContext context) {
    if (_titleController.text.trim().isEmpty) {
      return context.l10n.topicTitleRequired;
    }
    return null;
  }

  String? _fileNameError(BuildContext context) {
    final value = _fileNameController.text.trim();
    if (value.isEmpty) {
      return context.l10n.fileNameRequired;
    }
    if (value == '.' ||
        value == '..' ||
        p.isAbsolute(value) ||
        value.contains('/') ||
        value.contains(r'\') ||
        value.contains('..')) {
      return context.l10n.useSingleSafeFileName;
    }
    final expectedExtension = _extensionFor(_format);
    final extension = p.extension(value).toLowerCase();
    if (extension.isNotEmpty && extension != expectedExtension) {
      return context.l10n.useExpectedExtension(expectedExtension);
    }
    final id = p.basenameWithoutExtension(value);
    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(id)) {
      return context.l10n.useIdentifierCharacters;
    }
    final existingIds = widget.workspace.writersideModule?.topics
        .map((topic) => topic.id)
        .toSet();
    if (existingIds?.contains(id) ?? false) {
      return context.l10n.topicIdAlreadyExists;
    }
    return null;
  }

  String get _targetPath {
    final module = widget.workspace.writersideModule;
    var topicsDir = module?.config.topicsDir ?? 'topics';
    if (_placement != WritersideTopicCreatePlacement.root &&
        widget.referenceTopic != null &&
        module != null) {
      final topicRoot = module
          .topicByReference(widget.referenceTopic!)
          ?.topicRoot;
      if (topicRoot != null) {
        topicsDir = p.relative(topicRoot, from: module.rootPath);
      }
    }
    return p.join(topicsDir, _effectiveFileName);
  }

  String get _effectiveFileName {
    final value = _fileNameController.text.trim();
    if (p.extension(value).isEmpty) {
      return '$value${_extensionFor(_format)}';
    }
    return value;
  }

  void _handleTitleChanged() {
    _creationError = null;
    if (!_fileNameEdited) {
      _syncingFileName = true;
      _fileNameController.text =
          '${_slugTopicName(_titleController.text)}${_extensionFor(_format)}';
      _syncingFileName = false;
    }
    setState(() {});
  }

  void _handleFileNameChanged() {
    _creationError = null;
    if (!_syncingFileName) {
      _fileNameEdited = true;
    }
    setState(() {});
  }

  void _setFormat(WritersideTopicFormat value) {
    final previousExtension = _extensionFor(_format);
    _format = value;
    final nextExtension = _extensionFor(value);
    if (!_fileNameEdited) {
      _syncingFileName = true;
      _fileNameController.text =
          '${_slugTopicName(_titleController.text)}$nextExtension';
      _syncingFileName = false;
    } else {
      final text = _fileNameController.text.trim();
      if (p.extension(text).toLowerCase() == previousExtension) {
        _syncingFileName = true;
        _fileNameController.text =
            '${p.basenameWithoutExtension(text)}'
            '$nextExtension';
        _syncingFileName = false;
      }
    }
    _creationError = null;
    setState(() {});
  }

  Future<void> _submit() async {
    if (_creating ||
        _titleError(context) != null ||
        _fileNameError(context) != null) {
      return;
    }
    setState(() {
      _creating = true;
      _creationError = null;
    });
    final created = await ref
        .read(workspaceControllerProvider.notifier)
        .createWritersideTopic(
          WritersideTopicCreateRequest(
            title: _titleController.text.trim(),
            fileName: _effectiveFileName,
            format: _format,
            placement: _placement,
            referenceTocPath: _placement == WritersideTopicCreatePlacement.root
                ? null
                : widget.referencePath,
            referenceTopic: _placement == WritersideTopicCreatePlacement.root
                ? null
                : widget.referenceTopic,
            referenceTocIdentity:
                _placement == WritersideTopicCreatePlacement.root
                ? null
                : widget.referenceIdentity,
          ),
          instanceTreePath: widget.instanceTreePath,
        );
    if (!mounted) {
      return;
    }
    if (created) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _creating = false;
      final message = ref.read(workspaceControllerProvider).message;
      _creationError = message == null
          ? context.l10n.createWritersideTopicFailed
          : localizeWorkspaceMessage(context, message);
    });
  }

  String _slugTopicName(String value) {
    final slug = slugForHeading(value);
    return slug.isEmpty ? 'new-topic' : slug;
  }

  String _extensionFor(WritersideTopicFormat format) {
    return switch (format) {
      WritersideTopicFormat.markdown => '.md',
      WritersideTopicFormat.xml => '.topic',
    };
  }
}

class _TocTreeEntry {
  const _TocTreeEntry({
    required this.node,
    required this.depth,
    required this.path,
  });

  final TocNode node;
  final int depth;
  final List<int> path;

  String get pathKey => path.join('/');

  List<int>? get editPath => node.sourceTocPath;

  bool canEditStructureIn(String treePath) {
    return node.canEditStructure &&
        node.sourceTreePath != null &&
        p.equals(node.sourceTreePath!, treePath);
  }
}

List<_TocTreeEntry> _visibleTocTreeEntries(
  List<TocNode> nodes,
  Set<String> expandedNodeKeys,
) {
  final entries = <_TocTreeEntry>[];
  void visit(TocNode node, int depth, List<int> path) {
    entries.add(_TocTreeEntry(node: node, depth: depth, path: path));
    if (!expandedNodeKeys.contains(path.join('/'))) {
      return;
    }
    for (var index = 0; index < node.children.length; index += 1) {
      visit(node.children[index], depth + 1, [...path, index]);
    }
  }

  for (var index = 0; index < nodes.length; index += 1) {
    visit(nodes[index], 0, [index]);
  }
  return entries;
}

WritersideInstance? _tocInstanceForTreePath(
  WritersideModule module,
  String? treePath,
) {
  if (treePath == null) {
    return null;
  }
  for (final instance in module.instances) {
    if (p.equals(instance.sourceTreePath, treePath)) {
      return instance;
    }
  }
  return null;
}

String? _preferredTocInstanceTreePath(
  Workspace workspace, {
  String? currentTreePath,
}) {
  final module = workspace.writersideModule;
  if (module == null || module.instances.isEmpty) {
    return null;
  }
  final current = _tocInstanceForTreePath(module, currentTreePath);
  if (current != null) {
    return current.sourceTreePath;
  }
  return _tocInstanceTreePathForActiveFile(workspace) ??
      _defaultWritersideInstance(module).sourceTreePath;
}

String? _tocInstanceTreePathForActiveFile(
  Workspace workspace, {
  String? preferredTreePath,
}) {
  final module = workspace.writersideModule;
  final activeFilePath = workspace.activeFilePath;
  if (module == null || activeFilePath == null) {
    return null;
  }
  String? firstMatch;
  for (final instance in module.instances) {
    final matches = instance.navigationTocRoots
        .expand((node) => node.flatten())
        .any((node) {
          final reference = node.topicReference;
          return reference != null &&
              module.topicByReference(reference)?.filePath == activeFilePath;
        });
    if (!matches) {
      continue;
    }
    if (preferredTreePath != null &&
        p.equals(instance.sourceTreePath, preferredTreePath)) {
      return instance.sourceTreePath;
    }
    firstMatch ??= instance.sourceTreePath;
  }
  return firstMatch;
}

String? _activeTocNodePathKey(Workspace workspace, {String? treePath}) {
  final module = workspace.writersideModule;
  final activeFilePath = workspace.activeFilePath;
  if (module == null || module.instances.isEmpty || activeFilePath == null) {
    return null;
  }
  final instance =
      _tocInstanceForTreePath(module, treePath) ??
      _defaultWritersideInstance(module);
  String? result;
  void visit(TocNode node, List<int> path) {
    if (result != null) {
      return;
    }
    final reference = node.topicReference;
    if (reference != null &&
        module.topicByReference(reference)?.filePath == activeFilePath) {
      result = path.join('/');
      return;
    }
    for (var index = 0; index < node.children.length; index += 1) {
      visit(node.children[index], [...path, index]);
    }
  }

  final roots = instance.navigationTocRoots;
  for (var index = 0; index < roots.length; index += 1) {
    visit(roots[index], [index]);
  }
  return result;
}

Set<String> _initialExpandedTocNodeKeys(
  Workspace workspace, {
  String? treePath,
}) {
  final module = workspace.writersideModule;
  if (module == null || module.instances.isEmpty) {
    return const {};
  }
  final instance =
      _tocInstanceForTreePath(module, treePath) ??
      _defaultWritersideInstance(module);
  final expanded = <String>{};
  void visit(TocNode node, List<int> path) {
    if (node.children.isNotEmpty) {
      expanded.add(path.join('/'));
    }
    for (var index = 0; index < node.children.length; index += 1) {
      visit(node.children[index], [...path, index]);
    }
  }

  for (var index = 0; index < instance.navigationTocRoots.length; index += 1) {
    visit(instance.navigationTocRoots[index], [index]);
  }
  return expanded
    ..addAll(_activeTocAncestorKeys(workspace, treePath: treePath));
}

Set<String> _activeTocAncestorKeys(Workspace workspace, {String? treePath}) {
  final module = workspace.writersideModule;
  final activeFilePath = workspace.activeFilePath;
  if (module == null || module.instances.isEmpty || activeFilePath == null) {
    return const {};
  }
  final instance =
      _tocInstanceForTreePath(module, treePath) ??
      _defaultWritersideInstance(module);
  final ancestors = <String>{};
  bool visit(TocNode node, List<int> path) {
    final topic = node.topicReference == null || node.origin != null
        ? null
        : module.topicByReference(node.topicReference!)?.filePath;
    if (topic == activeFilePath) {
      return true;
    }
    for (var index = 0; index < node.children.length; index += 1) {
      if (visit(node.children[index], [...path, index])) {
        ancestors.add(path.join('/'));
        return true;
      }
    }
    return false;
  }

  for (var index = 0; index < instance.navigationTocRoots.length; index += 1) {
    visit(instance.navigationTocRoots[index], [index]);
  }
  return ancestors;
}

WritersideInstance _defaultWritersideInstance(WritersideModule module) {
  return module.instances
          .where((instance) => !instance.isLibrary)
          .firstOrNull ??
      module.instances.first;
}

class _OutlineTab extends ConsumerStatefulWidget {
  const _OutlineTab({required this.workspace, required this.headings});

  final Workspace workspace;
  final List<DocumentOutlineHeading> headings;

  @override
  ConsumerState<_OutlineTab> createState() => _OutlineTabState();
}

class _OutlineTabState extends ConsumerState<_OutlineTab> {
  static const _treeRowExtent =
      BusyMarkSizes.sidebarTreeRowHeight + BusyMarkStroke.hairline * 2;

  late String _outlineStateKey;
  late Set<String> _expandedNodeKeys;
  final _treeScrollController = ScrollController();
  String? _revealedActiveNodeKey;

  @override
  void initState() {
    super.initState();
    _outlineStateKey = _outlineStateSignature(
      widget.workspace,
      widget.headings,
    );
    _expandedNodeKeys = _initialExpandedOutlineNodeKeys(widget.headings);
  }

  @override
  void didUpdateWidget(covariant _OutlineTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextKey = _outlineStateSignature(widget.workspace, widget.headings);
    if (nextKey != _outlineStateKey) {
      _outlineStateKey = nextKey;
      _expandedNodeKeys = _initialExpandedOutlineNodeKeys(widget.headings);
      _revealedActiveNodeKey = null;
    }
  }

  @override
  void dispose() {
    _treeScrollController.dispose();
    super.dispose();
  }

  void _scheduleActiveNodeReveal(
    List<_OutlineTreeEntry> entries,
    String? activeNodeKey,
  ) {
    if (activeNodeKey == null) {
      _revealedActiveNodeKey = null;
      return;
    }
    if (activeNodeKey == _revealedActiveNodeKey) {
      return;
    }
    final index = entries.indexWhere(
      (entry) => _outlineNodeKey(entry.node.heading) == activeNodeKey,
    );
    if (index < 0) {
      return;
    }
    _revealedActiveNodeKey = activeNodeKey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_treeScrollController.hasClients) {
        _revealedActiveNodeKey = null;
        return;
      }
      final position = _treeScrollController.position;
      final itemTop = BusyMarkInsets.sidebarList.top + index * _treeRowExtent;
      final itemBottom = itemTop + _treeRowExtent;
      final viewportTop = position.pixels;
      final viewportBottom = viewportTop + position.viewportDimension;
      final alreadyVisible =
          itemBottom > viewportTop && itemTop < viewportBottom;
      if (!alreadyVisible) {
        final target = (itemTop - position.viewportDimension * 0.35)
            .clamp(position.minScrollExtent, position.maxScrollExtent)
            .toDouble();
        _treeScrollController.jumpTo(target);
      }
    });
  }

  Future<void> _showSectionMenu(
    DocumentOutlineHeading heading,
    int headingIndex,
    Offset position,
  ) async {
    final capabilities = _outlineSectionCapabilities(
      widget.headings,
      headingIndex,
    );
    final action = await showBusyMarkContextMenu<_OutlineSectionAction>(
      context,
      position,
      items: _outlineSectionMenuItems(context, capabilities),
    );
    if (action == null || !mounted) {
      return;
    }
    await _runSectionAction(heading, headingIndex, action);
  }

  Future<void> _runSectionAction(
    DocumentOutlineHeading heading,
    int preferredIndex,
    _OutlineSectionAction action,
  ) async {
    final initialState = ref.read(workspaceControllerProvider);
    final workspace = initialState.workspace;
    if (workspace == null) {
      return;
    }
    final workspaceId = workspace.id;
    final activePath = workspace.activeFilePath ?? workspace.markdown?.filePath;
    final source = initialState.activeText;
    final mode =
        workspace.markdown?.mode ??
        (workspace.kind == WorkspaceKind.writersideModule
            ? MarkdownMode.writersideMarkdown
            : MarkdownMode.commonMark);
    final parsed = await const MarkdownParser().parseAsync(
      filePath: activePath ?? 'untitled.md',
      source: source,
      mode: mode,
      workspaceRoot: workspace.rootPath,
      validateLocalReferences: false,
    );
    if (!mounted ||
        !_isSameActiveDocument(
          ref.read(workspaceControllerProvider),
          workspaceId: workspaceId,
          activePath: activePath,
          source: source,
        )) {
      return;
    }
    final headingIndex = _resolveParsedOutlineHeadingIndex(
      parsed.headings,
      heading,
      preferredIndex,
    );
    if (headingIndex < 0) {
      return;
    }
    final section = MarkdownSectionEditor.fromHeadings(
      source: source,
      headings: parsed.headings,
      headingIndex: headingIndex,
    );
    String? updatedSource;
    switch (action) {
      case _OutlineSectionAction.copy:
        await _copyToClipboard(section.sectionText);
        return;
      case _OutlineSectionAction.cut:
        await _copyToClipboard(section.sectionText);
        updatedSource = section.withoutSection();
      case _OutlineSectionAction.delete:
        final confirmed = await _confirmDeleteOutlineSection(
          context,
          ref,
          heading.text,
        );
        if (!confirmed || !mounted) {
          return;
        }
        updatedSource = section.withoutSection();
      case _OutlineSectionAction.promote:
        updatedSource = section.promote();
      case _OutlineSectionAction.demote:
        updatedSource = section.demote();
      case _OutlineSectionAction.moveUp:
        updatedSource = section.moveUp();
      case _OutlineSectionAction.moveDown:
        updatedSource = section.moveDown();
    }
    if (!mounted ||
        updatedSource == null ||
        updatedSource == source ||
        !_isSameActiveDocument(
          ref.read(workspaceControllerProvider),
          workspaceId: workspaceId,
          activePath: activePath,
          source: source,
        )) {
      return;
    }
    ref
        .read(workspaceControllerProvider.notifier)
        .updateActiveText(updatedSource, sourceFilePath: activePath);
  }

  @override
  Widget build(BuildContext context) {
    final headings = widget.headings;
    if (headings.isEmpty) {
      return _SidebarEmptyState(
        icon: BusyMarkGlyphs.font,
        title: context.l10n.noOutline,
      );
    }
    final tree = _buildOutlineTree(headings);
    final entries = _visibleOutlineTreeEntries(tree, _expandedNodeKeys);
    final viewportTarget = ref.watch(_outlineViewportTargetProvider);
    final activeNodeKey = _activeVisibleOutlineNodeKey(
      workspace: widget.workspace,
      headings: headings,
      entries: entries,
      target: viewportTarget,
    );
    _scheduleActiveNodeReveal(entries, activeNodeKey);
    final headingIndexes = {
      for (var index = 0; index < headings.length; index += 1)
        _outlineNodeKey(headings[index]): index,
    };
    return ListView.builder(
      key: const ValueKey('workspace-sidebar-outline-tree'),
      controller: _treeScrollController,
      padding: BusyMarkInsets.sidebarList,
      itemExtent: _treeRowExtent,
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final node = entry.node;
        final heading = node.heading;
        final key = _outlineNodeKey(heading);
        final headingIndex = headingIndexes[key]!;
        final expanded = _expandedNodeKeys.contains(key);
        final hasChildren = node.children.isNotEmpty;
        void toggle() {
          setState(() {
            _revealedActiveNodeKey = null;
            if (expanded) {
              _expandedNodeKeys.remove(key);
            } else {
              _expandedNodeKeys.add(key);
            }
          });
        }

        return KeyedSubtree(
          key: ValueKey('workspace-sidebar-outline-row-$headingIndex'),
          child: _SidebarTreeRow(
            title: heading.text,
            depth: entry.depth,
            icon: BusyMarkGlyphs.tag,
            leading: _HeadingBadge(level: heading.level),
            hasChildren: hasChildren,
            expanded: expanded,
            selected: key == activeNodeKey,
            onToggle: hasChildren ? toggle : null,
            onTap: () {
              _setOutlineViewportTarget(
                ref,
                workspace: widget.workspace,
                heading: heading,
              );
              ref
                  .read(_outlineNavigationTargetProvider.notifier)
                  .set(
                    _OutlineNavigationTarget(
                      workspaceId: widget.workspace.id,
                      filePath: widget.workspace.activeFilePath,
                      headingId: heading.id,
                      line: heading.sourceStartLine,
                      editorBlockId: heading.editorBlockId,
                    ),
                  );
            },
            onSecondaryTapUp: (details) => unawaited(
              _showSectionMenu(heading, headingIndex, details.globalPosition),
            ),
          ),
        );
      },
    );
  }
}

enum _OutlineSectionAction {
  copy,
  cut,
  delete,
  promote,
  demote,
  moveUp,
  moveDown,
}

typedef _OutlineSectionCapabilities = ({
  bool canPromote,
  bool canDemote,
  bool canMoveUp,
  bool canMoveDown,
});

_OutlineSectionCapabilities _outlineSectionCapabilities(
  List<DocumentOutlineHeading> headings,
  int headingIndex,
) {
  final level = headings[headingIndex].level;
  var sectionEndIndex = headingIndex + 1;
  while (sectionEndIndex < headings.length &&
      headings[sectionEndIndex].level > level) {
    sectionEndIndex += 1;
  }
  var canMoveUp = false;
  for (var index = headingIndex - 1; index >= 0; index -= 1) {
    if (headings[index].level < level) {
      break;
    }
    if (headings[index].level == level) {
      canMoveUp = true;
      break;
    }
  }
  return (
    canPromote: level > 1,
    canDemote: headings
        .getRange(headingIndex, sectionEndIndex)
        .every((candidate) => candidate.level < 6),
    canMoveUp: canMoveUp,
    canMoveDown:
        sectionEndIndex < headings.length &&
        headings[sectionEndIndex].level == level,
  );
}

List<PopupMenuEntry<_OutlineSectionAction>> _outlineSectionMenuItems(
  BuildContext context,
  _OutlineSectionCapabilities capabilities,
) {
  final direction = Directionality.of(context);
  return [
    BusyMarkPopupMenuItem(
      value: _OutlineSectionAction.copy,
      label: context.l10n.copy,
      icon: BusyMarkGlyphs.copy,
    ),
    BusyMarkPopupMenuItem(
      value: _OutlineSectionAction.cut,
      label: context.l10n.cut,
      icon: BusyMarkGlyphs.cut,
    ),
    const PopupMenuDivider(height: BusyMarkSpacing.sm),
    BusyMarkPopupMenuItem(
      value: _OutlineSectionAction.promote,
      label: context.l10n.promoteSection,
      icon: BusyMarkGlyphs.outdentFor(direction),
      enabled: capabilities.canPromote,
    ),
    BusyMarkPopupMenuItem(
      value: _OutlineSectionAction.demote,
      label: context.l10n.demoteSection,
      icon: BusyMarkGlyphs.indentFor(direction),
      enabled: capabilities.canDemote,
    ),
    const PopupMenuDivider(height: BusyMarkSpacing.sm),
    BusyMarkPopupMenuItem(
      value: _OutlineSectionAction.moveUp,
      label: context.l10n.moveSectionUp,
      icon: BusyMarkGlyphs.upArrow,
      enabled: capabilities.canMoveUp,
    ),
    BusyMarkPopupMenuItem(
      value: _OutlineSectionAction.moveDown,
      label: context.l10n.moveSectionDown,
      icon: BusyMarkGlyphs.downArrow,
      enabled: capabilities.canMoveDown,
    ),
    const PopupMenuDivider(height: BusyMarkSpacing.sm),
    BusyMarkPopupMenuItem(
      value: _OutlineSectionAction.delete,
      label: context.l10n.delete,
      icon: BusyMarkGlyphs.delete,
    ),
  ];
}

int _resolveParsedOutlineHeadingIndex(
  List<MarkdownHeading> headings,
  DocumentOutlineHeading target,
  int preferredIndex,
) {
  bool matches(MarkdownHeading candidate) =>
      candidate.level == target.level &&
      candidate.text == target.text &&
      candidate.id == target.id;
  if (preferredIndex >= 0 &&
      preferredIndex < headings.length &&
      matches(headings[preferredIndex])) {
    return preferredIndex;
  }
  final sourceOffset = target.sourceStartOffset;
  if (sourceOffset != null) {
    final index = headings.indexWhere(
      (candidate) =>
          candidate.span.startOffset == sourceOffset &&
          candidate.level == target.level &&
          candidate.text == target.text,
    );
    if (index >= 0) {
      return index;
    }
  }
  return headings.indexWhere(matches);
}

bool _isSameActiveDocument(
  WorkspaceState state, {
  required String workspaceId,
  required String? activePath,
  required String source,
}) {
  final workspace = state.workspace;
  return workspace?.id == workspaceId &&
      (workspace?.activeFilePath ?? workspace?.markdown?.filePath) ==
          activePath &&
      state.activeText == source;
}

Future<bool> _confirmDeleteOutlineSection(
  BuildContext context,
  WidgetRef ref,
  String heading,
) async {
  final headerBar = ref.read(linuxHeaderBarServiceProvider);
  final confirmed = await showBusyMarkModalDialog<bool>(
    context,
    headerBarService: headerBar.isAvailable ? headerBar : null,
    builder: (context) => BusyMarkDialogShell(
      title: context.l10n.confirmDeleteSectionTitle,
      maxWidth: BusyMarkSizes.dialog,
      actions: [
        BusyMarkDialogButton(
          label: context.l10n.cancel,
          onPressed: () => Navigator.pop(context, false),
        ),
        BusyMarkDialogButton(
          label: context.l10n.delete,
          icon: BusyMarkGlyphs.delete,
          destructive: true,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
      children: [Text(context.l10n.confirmDeleteSectionMessage(heading))],
    ),
  );
  return confirmed ?? false;
}

void _setOutlineViewportTarget(
  WidgetRef ref, {
  required Workspace workspace,
  required DocumentOutlineHeading? heading,
}) {
  ref
      .read(_outlineViewportTargetProvider.notifier)
      .set(
        _OutlineViewportTarget(
          workspaceId: workspace.id,
          filePath: workspace.activeFilePath ?? workspace.markdown?.filePath,
          headingId: heading?.id,
          sourceStartOffset: heading?.sourceStartOffset,
          editorBlockId: heading?.editorBlockId,
        ),
      );
}

String? _activeVisibleOutlineNodeKey({
  required Workspace workspace,
  required List<DocumentOutlineHeading> headings,
  required List<_OutlineTreeEntry> entries,
  required _OutlineViewportTarget? target,
}) {
  if (target == null ||
      target.workspaceId != workspace.id ||
      target.filePath !=
          (workspace.activeFilePath ?? workspace.markdown?.filePath)) {
    return headings.isEmpty ? null : _outlineNodeKey(headings.first);
  }
  final targetIndex = _outlineViewportHeadingIndex(headings, target);
  if (targetIndex < 0) {
    return null;
  }
  final visibleKeys = {
    for (final entry in entries) _outlineNodeKey(entry.node.heading),
  };
  for (var index = targetIndex; index >= 0; index -= 1) {
    final key = _outlineNodeKey(headings[index]);
    if (visibleKeys.contains(key)) {
      return key;
    }
  }
  return null;
}

int _outlineViewportHeadingIndex(
  List<DocumentOutlineHeading> headings,
  _OutlineViewportTarget target,
) {
  final editorBlockId = target.editorBlockId;
  if (editorBlockId != null) {
    final index = headings.indexWhere(
      (heading) => heading.editorBlockId == editorBlockId,
    );
    if (index >= 0) {
      return index;
    }
  }
  final sourceStartOffset = target.sourceStartOffset;
  if (sourceStartOffset != null) {
    final index = headings.indexWhere(
      (heading) => heading.sourceStartOffset == sourceStartOffset,
    );
    if (index >= 0) {
      return index;
    }
  }
  final headingId = target.headingId;
  return headingId == null
      ? -1
      : headings.indexWhere((heading) => heading.id == headingId);
}

List<DocumentOutlineHeading> _activeDocumentOutline(WorkspaceState state) {
  final liveOutline = state.liveOutline;
  final workspace = state.workspace;
  if (liveOutline != null &&
      workspace != null &&
      liveOutline.matches(workspace, state.activeText)) {
    return liveOutline.headings;
  }
  final preview = state.preview;
  if (preview != null) {
    return preview.outline;
  }
  return [
    for (final heading
        in state.workspace?.markdown?.headings ?? const <MarkdownHeading>[])
      DocumentOutlineHeading.fromMarkdown(heading),
  ];
}

class _OutlineTreeNode {
  const _OutlineTreeNode({required this.heading, required this.children});

  final DocumentOutlineHeading heading;
  final List<_OutlineTreeNode> children;
}

class _MutableOutlineTreeNode {
  _MutableOutlineTreeNode(this.heading);

  final DocumentOutlineHeading heading;
  final children = <_MutableOutlineTreeNode>[];
}

class _OutlineTreeEntry {
  const _OutlineTreeEntry({required this.node, required this.depth});

  final _OutlineTreeNode node;
  final int depth;
}

List<_OutlineTreeNode> _buildOutlineTree(
  List<DocumentOutlineHeading> headings,
) {
  final roots = <_MutableOutlineTreeNode>[];
  final stack = <_MutableOutlineTreeNode>[];

  for (final heading in headings) {
    final node = _MutableOutlineTreeNode(heading);
    while (stack.isNotEmpty && stack.last.heading.level >= heading.level) {
      stack.removeLast();
    }
    if (stack.isEmpty) {
      roots.add(node);
    } else {
      stack.last.children.add(node);
    }
    stack.add(node);
  }

  return roots.map(_immutableOutlineTreeNode).toList();
}

_OutlineTreeNode _immutableOutlineTreeNode(_MutableOutlineTreeNode node) {
  return _OutlineTreeNode(
    heading: node.heading,
    children: node.children.map(_immutableOutlineTreeNode).toList(),
  );
}

List<_OutlineTreeEntry> _visibleOutlineTreeEntries(
  List<_OutlineTreeNode> nodes,
  Set<String> expandedNodeKeys,
) {
  final entries = <_OutlineTreeEntry>[];
  void visit(_OutlineTreeNode node) {
    entries.add(
      _OutlineTreeEntry(
        node: node,
        depth: (node.heading.level - 1).clamp(0, 5).toInt(),
      ),
    );
    if (!expandedNodeKeys.contains(_outlineNodeKey(node.heading))) {
      return;
    }
    for (final child in node.children) {
      visit(child);
    }
  }

  for (final node in nodes) {
    visit(node);
  }
  return entries;
}

Set<String> _initialExpandedOutlineNodeKeys(
  List<DocumentOutlineHeading> headings,
) {
  return {
    for (final node in _flattenOutlineTree(_buildOutlineTree(headings)))
      if (node.children.isNotEmpty) _outlineNodeKey(node.heading),
  };
}

Iterable<_OutlineTreeNode> _flattenOutlineTree(
  List<_OutlineTreeNode> nodes,
) sync* {
  for (final node in nodes) {
    yield node;
    yield* _flattenOutlineTree(node.children);
  }
}

String _outlineNodeKey(DocumentOutlineHeading heading) {
  return [
    heading.id,
    heading.editorBlockId ?? heading.sourceStartOffset ?? 'live',
  ].join(':');
}

String _outlineStateSignature(
  Workspace workspace,
  List<DocumentOutlineHeading> headings,
) {
  return [
    workspace.id,
    workspace.activeFilePath ?? workspace.markdown?.filePath ?? '',
    for (final heading in headings)
      [
        heading.id,
        heading.level,
        heading.editorBlockId ?? heading.sourceStartOffset ?? 'live',
      ].join(':'),
  ].join('|');
}

class _HeadingBadge extends StatelessWidget {
  const _HeadingBadge({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.control,
        borderRadius: BorderRadius.circular(BusyMarkRadius.sm),
      ),
      child: Center(
        child: Text(
          context.l10n.headingLevelAbbreviation(level),
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _SidebarEmptyState extends StatelessWidget {
  const _SidebarEmptyState({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BusyMarkSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: colors.mutedForeground),
            const SizedBox(height: BusyMarkSpacing.sm),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

bool _shouldShowEditorTabs(Workspace workspace, GitState gitState) {
  return switch (workspace.kind) {
        WorkspaceKind.markdownFolder || WorkspaceKind.writersideModule => true,
        WorkspaceKind.untitledMarkdown || WorkspaceKind.singleMarkdown => false,
      } &&
      (workspace.openFilePaths.isNotEmpty ||
          gitState.openDiffFilePaths.isNotEmpty ||
          gitState.selectedDiffForDisplay != null);
}

class _EditorTabStrip extends ConsumerWidget {
  const _EditorTabStrip({required this.state, required this.gitState});

  final WorkspaceState state;
  final GitState gitState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = state.workspace;
    if (workspace == null) {
      return const SizedBox.shrink();
    }
    final entries = workspaceTabEntries(
      workspace: workspace,
      gitState: gitState,
    );
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }
    final colors = BusyMarkSurfaceColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.headerbarFlat,
        border: Border(bottom: BorderSide(color: colors.subtleBorder)),
      ),
      child: SizedBox(
        height: BusyMarkSizes.paneHeaderHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(
            BusyMarkSpacing.sm,
            BusyMarkSpacing.xs,
            BusyMarkSpacing.sm,
            0,
          ),
          itemBuilder: (context, index) {
            final entry = entries[index];
            return _WorkspaceTabButton(
              title: _tabTitle(context, workspace, entry),
              icon: _tabIcon(workspace, entry),
              diff: entry.kind == WorkspaceTabKind.gitDiff,
              active: entry.active,
              dirty: _tabDirty(workspace, entry),
              onSelected: () => _selectTab(context, ref, workspace, entry),
              onClose: () => _closeTab(context, ref, workspace, entry),
            );
          },
          separatorBuilder: (context, index) =>
              const SizedBox(width: BusyMarkSpacing.xs),
          itemCount: entries.length,
        ),
      ),
    );
  }

  String _tabTitle(
    BuildContext context,
    Workspace workspace,
    WorkspaceTabEntry entry,
  ) {
    return switch (entry.kind) {
      WorkspaceTabKind.file => _relativeDocumentPath(workspace, entry.path),
      WorkspaceTabKind.gitDiff =>
        entry.path.isEmpty ? context.l10n.gitDiff : _diffTabTitle(entry.path),
    };
  }

  IconData? _tabIcon(Workspace workspace, WorkspaceTabEntry entry) {
    if (entry.kind == WorkspaceTabKind.gitDiff) {
      return null;
    }
    final file = _documentFileForPath(workspace, entry.path);
    return _documentKindIcon(file?.kind ?? DocumentKind.markdown);
  }

  bool _tabDirty(Workspace workspace, WorkspaceTabEntry entry) {
    return entry.kind == WorkspaceTabKind.file &&
        entry.path == workspace.activeFilePath &&
        state.isDirty;
  }

  Future<void> _selectTab(
    BuildContext context,
    WidgetRef ref,
    Workspace workspace,
    WorkspaceTabEntry entry,
  ) async {
    final gitController = ref.read(gitControllerProvider.notifier);
    switch (entry.kind) {
      case WorkspaceTabKind.file:
        if (entry.path == workspace.activeFilePath) {
          gitController.deactivateDiffFile();
          return;
        }
        if (!await saveOrConfirmSafeToChangeActiveFile(context, ref) ||
            !context.mounted) {
          return;
        }
        await ref
            .read(workspaceControllerProvider.notifier)
            .openActiveFile(entry.path);
        gitController.deactivateDiffFile();
      case WorkspaceTabKind.gitDiff:
        if (entry.path.isEmpty) {
          return;
        }
        await gitController.activateDiffFile(entry.path);
    }
  }

  Future<void> _closeTab(
    BuildContext context,
    WidgetRef ref,
    Workspace workspace,
    WorkspaceTabEntry entry,
  ) async {
    final gitController = ref.read(gitControllerProvider.notifier);
    switch (entry.kind) {
      case WorkspaceTabKind.file:
        final currentWorkspaceFile = entry.path == workspace.activeFilePath;
        if (currentWorkspaceFile &&
            (!await saveOrConfirmSafeToChangeActiveFile(context, ref) ||
                !context.mounted)) {
          return;
        }
        await ref
            .read(workspaceControllerProvider.notifier)
            .closeOpenFileTab(entry.path);
        gitController.deactivateDiffFile();
      case WorkspaceTabKind.gitDiff:
        if (entry.path.isEmpty) {
          gitController.clearSelection();
        } else {
          gitController.closeDiffFile(entry.path);
        }
    }
  }
}

class _WorkspaceTabButton extends StatelessWidget {
  const _WorkspaceTabButton({
    required this.title,
    required this.icon,
    required this.diff,
    required this.active,
    required this.dirty,
    required this.onSelected,
    required this.onClose,
  });

  final String title;
  final IconData? icon;
  final bool diff;
  final bool active;
  final bool dirty;
  final VoidCallback onSelected;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final foreground = active ? colors.foreground : colors.mutedForeground;
    final background = active ? colors.view : BusyMarkLinuxPalette.transparent;
    final borderColor = active
        ? colors.subtleBorder
        : BusyMarkLinuxPalette.transparent;
    return Material(
      color: background,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(BusyMarkRadius.sm),
      ),
      child: InkWell(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(BusyMarkRadius.sm),
        ),
        hoverColor: colors.controlHover,
        onTap: onSelected,
        child: Container(
          height: BusyMarkSizes.paneHeaderHeight - BusyMarkSpacing.xs,
          constraints: const BoxConstraints(minWidth: 112, maxWidth: 240),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(BusyMarkRadius.sm),
            ),
            border: Border.all(color: borderColor),
          ),
          padding: const EdgeInsetsDirectional.only(
            start: BusyMarkSpacing.sm,
            end: BusyMarkSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dirty) ...[
                Container(
                  width: BusyMarkSizes.markerDot,
                  height: BusyMarkSizes.markerDot,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: BusyMarkSpacing.sm),
              ] else ...[
                if (diff)
                  _DiffCompareIcon(color: foreground)
                else
                  Icon(icon, size: BusyMarkSizes.iconSm, color: foreground),
                const SizedBox(width: BusyMarkSpacing.sm),
              ],
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: foreground,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: BusyMarkSpacing.xs),
              BusyMarkCompactIconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                icon: BusyMarkGlyphs.clear,
                foregroundColor: foreground,
                onPressed: onClose,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiffCompareIcon extends StatelessWidget {
  const _DiffCompareIcon({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: BusyMarkSizes.iconSm,
      child: CustomPaint(
        painter: _DiffCompareIconPainter(color),
        size: const Size.square(BusyMarkSizes.iconSm),
      ),
    );
  }
}

class _DiffCompareIconPainter extends CustomPainter {
  const _DiffCompareIconPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / BusyMarkSizes.iconSm;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final topY = 5 * scale;
    final bottomY = 11 * scale;
    final left = 3 * scale;
    final right = 13 * scale;
    final arrow = 3 * scale;

    final top = Path()
      ..moveTo(right, topY)
      ..lineTo(left, topY)
      ..lineTo(left + arrow, topY - arrow)
      ..moveTo(left, topY)
      ..lineTo(left + arrow, topY + arrow);
    final bottom = Path()
      ..moveTo(left, bottomY)
      ..lineTo(right, bottomY)
      ..lineTo(right - arrow, bottomY - arrow)
      ..moveTo(right, bottomY)
      ..lineTo(right - arrow, bottomY + arrow);

    canvas.drawPath(top, paint);
    canvas.drawPath(bottom, paint);
  }

  @override
  bool shouldRepaint(_DiffCompareIconPainter oldDelegate) {
    return color != oldDelegate.color;
  }
}

String _diffTabTitle(String path) {
  final name = p.basename(path);
  return name.isEmpty ? path : name;
}

class _GitDiffDocumentView extends StatefulWidget {
  const _GitDiffDocumentView({
    required this.diff,
    required this.comparisonLabel,
    required this.comparisonType,
    required this.comparisonEnabled,
    required this.onComparisonTypeChanged,
    required this.openFilePath,
    required this.workspace,
    required this.viewMode,
    required this.hasUnsavedEditorChanges,
    required this.editorFontSize,
    required this.onOpenFile,
  });

  final GitDiff? diff;
  final String? comparisonLabel;
  final GitComparisonType? comparisonType;
  final bool comparisonEnabled;
  final ValueChanged<GitComparisonType>? onComparisonTypeChanged;
  final String? openFilePath;
  final Workspace workspace;
  final DocumentViewModePreference viewMode;
  final bool hasUnsavedEditorChanges;
  final double editorFontSize;
  final ValueChanged<String> onOpenFile;

  @override
  State<_GitDiffDocumentView> createState() => _GitDiffDocumentViewState();
}

class _GitDiffDocumentViewState extends State<_GitDiffDocumentView> {
  final _previewScrollController = ItemScrollController();
  late final GitDiffChangeNavigatorController _sourceChangeNavigatorController;
  final _previewBlockContexts = <int, BuildContext>{};
  int _currentChangeIndex = 0;
  String? _initialScrollToken;

  @override
  void initState() {
    super.initState();
    _sourceChangeNavigatorController = GitDiffChangeNavigatorController();
  }

  @override
  Widget build(BuildContext context) {
    final diff = widget.diff;
    if (diff == null) {
      return _EmptyPane(
        icon: BusyMarkGlyphs.history,
        title: context.l10n.gitDiff,
      );
    }
    final colors = BusyMarkSurfaceColors.of(context);
    final sourceVisible =
        widget.viewMode == DocumentViewModePreference.source ||
        widget.viewMode == DocumentViewModePreference.split;
    final previewVisible =
        widget.viewMode == DocumentViewModePreference.preview ||
        widget.viewMode == DocumentViewModePreference.split ||
        widget.viewMode == DocumentViewModePreference.editor;
    final previewData = previewVisible
        ? _diffPreviewData(diff, widget.workspace)
        : null;
    final changeTargets =
        previewData?.changeTargets ?? const <_DiffPreviewChangeTarget>[];
    final splitVisible = sourceVisible && previewVisible;
    final sourceChangeCount = sourceVisible
        ? gitDiffSourceChangeCount(diff)
        : 0;
    final comparisonUsesSourceNavigator =
        widget.comparisonLabel != null &&
        sourceVisible &&
        sourceChangeCount > 0;
    final comparisonUsesPreviewNavigator =
        widget.comparisonLabel != null &&
        !sourceVisible &&
        previewVisible &&
        changeTargets.isNotEmpty;
    final navigatorChangeCount = splitVisible
        ? sourceChangeCount
        : changeTargets.length;
    if (_currentChangeIndex >= navigatorChangeCount) {
      _currentChangeIndex = 0;
    }
    if (navigatorChangeCount > 0) {
      _scheduleInitialScroll(
        diff: diff,
        splitVisible: splitVisible,
        sourceChangeCount: sourceChangeCount,
        previewTargets: changeTargets,
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.view),
      child: Column(
        children: [
          if (widget.comparisonLabel != null)
            _DiffToolbar(
              label: widget.comparisonLabel!,
              comparisonType: widget.comparisonType,
              comparisonEnabled: widget.comparisonEnabled,
              onComparisonTypeChanged: widget.onComparisonTypeChanged,
              currentIndex:
                  comparisonUsesSourceNavigator ||
                      comparisonUsesPreviewNavigator
                  ? _currentChangeIndex
                  : null,
              total: comparisonUsesSourceNavigator
                  ? sourceChangeCount
                  : comparisonUsesPreviewNavigator
                  ? changeTargets.length
                  : null,
              onPrevious: comparisonUsesSourceNavigator
                  ? () => _jumpToSplitChange(
                      sourceChangeCount: sourceChangeCount,
                      previewTargets: changeTargets,
                      direction: -1,
                    )
                  : comparisonUsesPreviewNavigator
                  ? () => _jumpToPreviewChange(changeTargets, -1)
                  : null,
              onNext: comparisonUsesSourceNavigator
                  ? () => _jumpToSplitChange(
                      sourceChangeCount: sourceChangeCount,
                      previewTargets: changeTargets,
                      direction: 1,
                    )
                  : comparisonUsesPreviewNavigator
                  ? () => _jumpToPreviewChange(changeTargets, 1)
                  : null,
              target: comparisonUsesSourceNavigator
                  ? _diffChangeTarget(diff, _currentChangeIndex)
                  : null,
              openFilePath: comparisonUsesSourceNavigator
                  ? widget.openFilePath
                  : null,
              onOpenFile: comparisonUsesSourceNavigator
                  ? widget.onOpenFile
                  : null,
            ),
          if (widget.comparisonLabel == null &&
              splitVisible &&
              sourceChangeCount > 0)
            _DiffToolbar(
              currentIndex: _currentChangeIndex,
              total: sourceChangeCount,
              onPrevious: () => _jumpToSplitChange(
                sourceChangeCount: sourceChangeCount,
                previewTargets: changeTargets,
                direction: -1,
              ),
              onNext: () => _jumpToSplitChange(
                sourceChangeCount: sourceChangeCount,
                previewTargets: changeTargets,
                direction: 1,
              ),
              target: _diffChangeTarget(diff, _currentChangeIndex),
              openFilePath: widget.openFilePath,
              onOpenFile: widget.onOpenFile,
            ),
          Expanded(
            child: Row(
              children: [
                if (sourceVisible)
                  Expanded(
                    child: GitDiffViewer(
                      diff: diff,
                      hasUnsavedEditorChanges: widget.hasUnsavedEditorChanges,
                      showHeader: false,
                      showFileHeaders: false,
                      showCloseButton: false,
                      showFileActions: !splitVisible,
                      showHunkHeaders: !splitVisible,
                      editorFontSize: widget.editorFontSize,
                      showChangeNavigator:
                          !previewVisible && widget.comparisonLabel == null,
                      changeNavigatorController:
                          splitVisible ||
                              (widget.comparisonLabel != null && sourceVisible)
                          ? _sourceChangeNavigatorController
                          : null,
                      openFilePath: widget.openFilePath,
                      onOpenFile: widget.onOpenFile,
                      onClose: () {},
                    ),
                  ),
                if (sourceVisible && previewVisible)
                  VerticalDivider(
                    width: BusyMarkStroke.hairline,
                    color: colors.subtleBorder,
                  ),
                if (previewVisible)
                  Expanded(
                    child: Column(
                      children: [
                        if (widget.comparisonLabel == null &&
                            !splitVisible &&
                            changeTargets.isNotEmpty)
                          _DiffToolbar(
                            currentIndex: _currentChangeIndex,
                            total: changeTargets.length,
                            onPrevious: () =>
                                _jumpToPreviewChange(changeTargets, -1),
                            onNext: () =>
                                _jumpToPreviewChange(changeTargets, 1),
                            target: null,
                            openFilePath: null,
                            onOpenFile: null,
                          ),
                        Expanded(
                          child: _PreviewPane(
                            preview: previewData?.document,
                            workspace: widget.workspace,
                            controller: _previewScrollController,
                            onBlockContextAvailable:
                                _rememberPreviewBlockContext,
                            onBlockContextUnavailable:
                                _forgetPreviewBlockContext,
                            documentLayout:
                                BusyMarkDocumentLayoutSpec.standalone,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _jumpToPreviewChange(
    List<_DiffPreviewChangeTarget> targets,
    int direction,
  ) {
    if (targets.isEmpty) {
      return;
    }
    final nextIndex =
        (_currentChangeIndex + direction + targets.length) % targets.length;
    setState(() {
      _currentChangeIndex = nextIndex;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollPreviewToChange(targets, nextIndex);
    });
  }

  void _jumpToSplitChange({
    required int sourceChangeCount,
    required List<_DiffPreviewChangeTarget> previewTargets,
    required int direction,
  }) {
    if (sourceChangeCount == 0) {
      return;
    }
    final nextIndex =
        (_currentChangeIndex + direction + sourceChangeCount) %
        sourceChangeCount;
    setState(() {
      _currentChangeIndex = nextIndex;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sourceChangeNavigatorController.jumpToChange(nextIndex);
      if (previewTargets.isNotEmpty) {
        _scrollPreviewToChange(
          previewTargets,
          math.min(nextIndex, previewTargets.length - 1),
        );
      }
    });
  }

  void _scrollPreviewToChange(
    List<_DiffPreviewChangeTarget> targets,
    int index,
  ) {
    final blockIndex = targets[index].blockIndex;
    final blockContext = _previewBlockContexts[blockIndex];
    if (blockContext != null && blockContext.mounted) {
      unawaited(
        Scrollable.ensureVisible(
          blockContext,
          duration: BusyMarkMotion.scroll,
          curve: Curves.easeOutCubic,
          alignment: 0.1,
        ),
      );
      return;
    }
    if (!_previewScrollController.isAttached) {
      return;
    }
    _previewScrollController.jumpTo(index: blockIndex, alignment: 0.1);
  }

  void _rememberPreviewBlockContext(int index, BuildContext context) {
    _previewBlockContexts[index] = context;
  }

  void _forgetPreviewBlockContext(int index, BuildContext context) {
    if (identical(_previewBlockContexts[index], context)) {
      _previewBlockContexts.remove(index);
    }
  }

  void _scheduleInitialScroll({
    required GitDiff diff,
    required bool splitVisible,
    required int sourceChangeCount,
    required List<_DiffPreviewChangeTarget> previewTargets,
  }) {
    final token = gitDiffChangeNavigationToken(diff, widget.viewMode);
    if (_initialScrollToken == token) {
      return;
    }
    _initialScrollToken = token;
    _currentChangeIndex = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _initialScrollToken != token) {
        return;
      }
      if (splitVisible && sourceChangeCount > 0) {
        _sourceChangeNavigatorController.jumpToChange(0);
      }
      if (previewTargets.isNotEmpty) {
        _scrollPreviewToChange(previewTargets, 0);
      }
    });
  }
}

class _DiffToolbar extends StatelessWidget {
  const _DiffToolbar({
    this.label,
    this.comparisonType,
    this.comparisonEnabled = true,
    this.onComparisonTypeChanged,
    this.currentIndex,
    this.total,
    this.onPrevious,
    this.onNext,
    this.target,
    this.openFilePath,
    this.onOpenFile,
  });

  final String? label;
  final GitComparisonType? comparisonType;
  final bool comparisonEnabled;
  final ValueChanged<GitComparisonType>? onComparisonTypeChanged;
  final int? currentIndex;
  final int? total;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final _DiffChangeTarget? target;
  final String? openFilePath;
  final ValueChanged<String>? onOpenFile;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final hasNavigator =
        currentIndex != null &&
        total != null &&
        total! > 0 &&
        onPrevious != null &&
        onNext != null;
    final selectable =
        comparisonType != null && onComparisonTypeChanged != null;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.headerbarFlat,
        border: Border(bottom: BorderSide(color: colors.subtleBorder)),
      ),
      child: SizedBox(
        height: BusyMarkSizes.paneHeaderHeight,
        child: Row(
          children: [
            const SizedBox(width: BusyMarkSpacing.md),
            if (label != null) ...[
              Icon(
                BusyMarkGlyphs.documentHistory,
                size: BusyMarkSizes.iconSm,
                color: colors.mutedForeground,
              ),
              const SizedBox(width: BusyMarkSpacing.sm),
              Flexible(
                flex: 2,
                child: selectable
                    ? _GitHistoryComparisonSelector(
                        value: comparisonType!,
                        label: label!,
                        enabled: comparisonEnabled,
                        onSelected: onComparisonTypeChanged!,
                      )
                    : Text(
                        label!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
              ),
            ],
            if (hasNavigator) ...[
              if (label != null) const SizedBox(width: BusyMarkSpacing.md),
              Text(
                '${currentIndex! + 1} / $total',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.mutedForeground,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (target != null) ...[
                const SizedBox(width: BusyMarkSpacing.md),
                Flexible(
                  child: Text(
                    gitDiffHunkRangeText(
                      target!.hunk,
                      format: context.l10n.gitDiffHunkRange,
                      noLinesText: context.l10n.gitDiffNoLines,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.mutedForeground,
                      fontFamily: BusyMarkTypography.monoFontFamily,
                    ),
                  ),
                ),
                const SizedBox(width: BusyMarkSpacing.sm),
                if (openFilePath != null && onOpenFile != null)
                  BusyMarkHeaderIconButton(
                    tooltip: context.l10n.gitOpenFile,
                    icon: BusyMarkGlyphs.externalLink,
                    transparent: true,
                    onPressed: () => onOpenFile!(openFilePath!),
                  ),
              ] else
                const Spacer(),
              BusyMarkHeaderIconButton(
                tooltip: context.l10n.sourceSearchPreviousMatch,
                icon: YaruIcons.pan_up,
                transparent: true,
                onPressed: onPrevious!,
              ),
              BusyMarkHeaderIconButton(
                tooltip: context.l10n.sourceSearchNextMatch,
                icon: BusyMarkGlyphs.downArrow,
                transparent: true,
                onPressed: onNext!,
              ),
            ] else
              const Spacer(),
            const SizedBox(width: BusyMarkSpacing.xs),
          ],
        ),
      ),
    );
  }
}

class _GitHistoryComparisonSelector extends StatelessWidget {
  const _GitHistoryComparisonSelector({
    required this.value,
    required this.label,
    required this.enabled,
    required this.onSelected,
  });

  final GitComparisonType value;
  final String label;
  final bool enabled;
  final ValueChanged<GitComparisonType> onSelected;

  @override
  Widget build(BuildContext context) {
    return BusyMarkMenuButton<GitComparisonType>(
      key: const ValueKey('git-history-comparison-selector'),
      tooltip: context.l10n.gitDiff,
      enabled: enabled,
      fallbackMenuWidth: 224,
      items: [
        BusyMarkPopupMenuItem(
          value: GitComparisonType.commitChange,
          label: context.l10n.gitChangesInCommit,
          icon: BusyMarkGlyphs.documentHistory,
          checked: value == GitComparisonType.commitChange,
          trailingCheck: true,
        ),
        BusyMarkPopupMenuItem(
          value: GitComparisonType.commitVersusCurrent,
          label: context.l10n.gitCompareWithCurrent,
          icon: BusyMarkGlyphs.preview,
          checked: value == GitComparisonType.commitVersusCurrent,
          trailingCheck: true,
        ),
      ],
      onSelected: (selection) {
        if (selection != value) {
          onSelected(selection);
        }
      },
      triggerBuilder: (context, trigger) {
        return trigger.anchor(
          child: Tooltip(
            message: context.l10n.gitDiff,
            child: Semantics(
              expanded: trigger.isOpen,
              child: BusyMarkPushButton.standard(
                onPressed: trigger.onPressed,
                focusNode: trigger.focusNode,
                style: Theme.of(context).outlinedButtonTheme.style?.copyWith(
                  side: const WidgetStatePropertyAll(BorderSide.none),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    ),
                    const SizedBox(width: BusyMarkSpacing.sm),
                    const Icon(
                      BusyMarkGlyphs.downArrow,
                      size: BusyMarkSizes.iconSm,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DiffChangeTarget {
  const _DiffChangeTarget({required this.file, required this.hunk});

  final GitDiffFile file;
  final GitDiffHunk hunk;
}

_DiffChangeTarget? _diffChangeTarget(GitDiff diff, int changeIndex) {
  var remaining = changeIndex;
  for (final file in diff.files) {
    if (remaining < file.hunks.length) {
      return _DiffChangeTarget(file: file, hunk: file.hunks[remaining]);
    }
    remaining -= file.hunks.length;
  }
  return null;
}

_DiffPreviewData _diffPreviewData(GitDiff diff, Workspace workspace) {
  final snapshot = _diffPreviewSnapshot(diff);
  final document = snapshot == null
      ? _diffPreviewDocumentFromPatch(diff, workspace)
      : _diffPreviewDocumentFromSnapshot(
          diff: diff,
          filePath: snapshot.path,
          source: snapshot.source,
          workspace: workspace,
        );
  return _DiffPreviewData(
    document,
    _diffPreviewChangeTargets(diff, document, filePath: snapshot?.path),
  );
}

_DiffPreviewSnapshot? _diffPreviewSnapshot(GitDiff diff) {
  for (final file in diff.files) {
    if (file.status == GitDiffFileStatus.deleted) {
      continue;
    }
    final path = file.displayPath;
    if (path.isEmpty) {
      continue;
    }
    final source = diff.fileSnapshots[path];
    if (source != null) {
      return _DiffPreviewSnapshot(path: path, source: source);
    }
  }
  return null;
}

PreviewDocument _diffPreviewDocumentFromSnapshot({
  required GitDiff diff,
  required String filePath,
  required String source,
  required Workspace workspace,
}) {
  final document = _safePreviewDocument(
    source: source,
    filePath: filePath,
    workspace: workspace,
  );
  final changedRanges = _diffChangedLineRanges(diff, filePath: filePath);
  final changedLineTones = _diffChangedLineTones(diff, filePath: filePath);
  final removedBlocksByIndex = _diffRemovedBlocksByPreviewBlock(
    diff: diff,
    document: document,
    filePath: filePath,
    workspace: workspace,
  );
  return PreviewDocument(
    title: document.title,
    modeLabel: document.modeLabel,
    compatibility: document.compatibility,
    blocks: [
      for (final (index, block) in document.blocks.indexed) ...[
        ...?removedBlocksByIndex[index],
        _diffPreviewBlockFromSnapshot(
          block: block,
          changedRanges: changedRanges,
          changedLineTones: changedLineTones,
        ),
      ],
    ],
  );
}

PreviewDocument _safePreviewDocument({
  required String source,
  required String filePath,
  required Workspace workspace,
}) {
  try {
    return _parsePreviewDocument(
      source: source,
      filePath: filePath,
      workspace: workspace,
    );
  } on Object {
    return PreviewDocument(
      title: '',
      modeLabel: '',
      compatibility: '',
      blocks: _plainPreviewBlocks(source),
    );
  }
}

PreviewDocument _diffPreviewDocumentFromPatch(
  GitDiff diff,
  Workspace workspace,
) {
  final blocks = <PreviewBlock>[];
  for (final file in diff.files) {
    if (file.binary) {
      continue;
    }
    final filePath = file.displayPath.isEmpty ? diff.title : file.displayPath;
    for (final hunk in file.hunks) {
      for (final run in _diffPreviewRuns(hunk.lines)) {
        final runBlocks = _previewBlocksForDiffRun(
          source: run.source,
          filePath: filePath,
          workspace: workspace,
        );
        blocks.addAll([
          for (final block in runBlocks) _withDiffPreviewTone(block, run.tone),
        ]);
      }
    }
  }
  if (blocks.isEmpty) {
    return const PreviewDocument(
      title: '',
      modeLabel: '',
      compatibility: '',
      blocks: [],
    );
  }
  return PreviewDocument(
    title: diff.title,
    modeLabel: '',
    compatibility: '',
    blocks: blocks,
  );
}

PreviewDocument _parsePreviewDocument({
  required String source,
  required String filePath,
  required Workspace workspace,
}) {
  final mode = workspace.kind == WorkspaceKind.writersideModule
      ? MarkdownMode.writersideMarkdown
      : MarkdownMode.commonMark;
  final parsed = const MarkdownParser().parse(
    filePath: filePath,
    source: source,
    mode: mode,
    workspaceRoot: workspace.rootPath,
    validateLocalReferences: false,
  );
  return const MarkdownPreviewBuilder().build(parsed);
}

List<PreviewBlock> _previewBlocksForDiffRun({
  required String source,
  required String filePath,
  required Workspace workspace,
}) {
  if (source.trim().isEmpty) {
    return const [];
  }
  try {
    return _parsePreviewDocument(
      source: source,
      filePath: filePath,
      workspace: workspace,
    ).blocks;
  } on Object {
    return _plainPreviewBlocks(source);
  }
}

PreviewBlock _diffPreviewBlockFromSnapshot({
  required PreviewBlock block,
  required List<_DiffChangedLineRange> changedRanges,
  required Map<int, _DiffPreviewTone> changedLineTones,
}) {
  final blockWithCodeLineTones = _withDiffPreviewCodeLineTones(
    block,
    changedLineTones,
  );
  final changed = _blockOverlapsAnyChangedLine(block, changedRanges);
  if (!changed) {
    return blockWithCodeLineTones;
  }
  if (block.kind == PreviewBlockKind.code &&
      _diffPreviewCodeLineTones(blockWithCodeLineTones).isNotEmpty) {
    return blockWithCodeLineTones;
  }
  return _withDiffPreviewTone(blockWithCodeLineTones, _DiffPreviewTone.changed);
}

List<_DiffChangedLineRange> _diffChangedLineRanges(
  GitDiff diff, {
  String? filePath,
}) {
  final ranges = <_DiffChangedLineRange>[];
  for (final file in diff.files) {
    if (filePath != null && !file.matchesPath(filePath)) {
      continue;
    }
    for (final hunk in file.hunks) {
      final changedNewLines = [
        for (final line in hunk.lines)
          if (line.kind == GitDiffLineKind.added && line.newLineNumber != null)
            line.newLineNumber!,
      ];
      if (changedNewLines.isEmpty) {
        ranges.add(
          _DiffChangedLineRange(
            startLine: hunk.newStart,
            endLine: hunk.newStart,
          ),
        );
      } else {
        ranges.add(
          _DiffChangedLineRange(
            startLine: changedNewLines.reduce(math.min),
            endLine: changedNewLines.reduce(math.max),
          ),
        );
      }
    }
  }
  return ranges;
}

Map<int, _DiffPreviewTone> _diffChangedLineTones(
  GitDiff diff, {
  required String filePath,
}) {
  final tones = <int, _DiffPreviewTone>{};
  for (final file in diff.files) {
    if (!file.matchesPath(filePath)) {
      continue;
    }
    for (final hunk in file.hunks) {
      for (final line in hunk.lines) {
        if (line.kind != GitDiffLineKind.added) {
          continue;
        }
        final lineNumber = line.newLineNumber;
        if (lineNumber != null) {
          tones[lineNumber] = _DiffPreviewTone.changed;
        }
      }
    }
  }
  return tones;
}

Map<int, List<PreviewBlock>> _diffRemovedBlocksByPreviewBlock({
  required GitDiff diff,
  required PreviewDocument document,
  required String filePath,
  required Workspace workspace,
}) {
  final blocksByIndex = <int, List<PreviewBlock>>{};
  for (final file in diff.files) {
    if (!file.matchesPath(filePath)) {
      continue;
    }
    for (final hunk in file.hunks) {
      final removedLines = [
        for (final line in hunk.lines)
          if (line.kind == GitDiffLineKind.removed) line.content,
      ];
      if (removedLines.isEmpty) {
        continue;
      }
      final targetRange = _DiffChangedLineRange(
        startLine: hunk.newStart,
        endLine: hunk.newStart,
      );
      final blockIndex =
          _blockIndexForChangedLineRange(document.blocks, targetRange) ?? 0;
      final removedBlocks = [
        for (final block in _previewBlocksForDiffRun(
          source: removedLines.join('\n'),
          filePath: filePath,
          workspace: workspace,
        ))
          _withDiffPreviewTone(block, _DiffPreviewTone.removed),
      ];
      if (removedBlocks.isEmpty) {
        continue;
      }
      blocksByIndex
          .putIfAbsent(blockIndex, () => <PreviewBlock>[])
          .addAll(removedBlocks);
    }
  }
  return blocksByIndex;
}

List<_DiffPreviewChangeTarget> _diffPreviewChangeTargets(
  GitDiff diff,
  PreviewDocument document, {
  String? filePath,
}) {
  final targets = <_DiffPreviewChangeTarget>[];
  for (final range in _diffChangedLineRanges(diff, filePath: filePath)) {
    final blockIndex = _blockIndexForChangedLineRange(document.blocks, range);
    if (blockIndex == null) {
      continue;
    }
    if (targets.any((target) => target.blockIndex == blockIndex)) {
      continue;
    }
    targets.add(
      _DiffPreviewChangeTarget(blockIndex: blockIndex, line: range.startLine),
    );
  }
  return targets;
}

int? _blockIndexForChangedLineRange(
  List<PreviewBlock> blocks,
  _DiffChangedLineRange range,
) {
  for (final (index, block) in blocks.indexed) {
    if (_blockOverlapsChangedLine(block, range)) {
      return index;
    }
  }
  for (final (index, block) in blocks.indexed) {
    final startLine = block.sourceStartLine;
    if (startLine != null && startLine >= range.startLine) {
      return index;
    }
  }
  return blocks.isEmpty ? null : blocks.length - 1;
}

bool _blockOverlapsAnyChangedLine(
  PreviewBlock block,
  List<_DiffChangedLineRange> ranges,
) {
  return ranges.any((range) => _blockOverlapsChangedLine(block, range));
}

bool _blockOverlapsChangedLine(
  PreviewBlock block,
  _DiffChangedLineRange range,
) {
  final startLine = block.sourceStartLine;
  final endLine = block.sourceEndLine ?? startLine;
  if (startLine == null || endLine == null) {
    return false;
  }
  return startLine <= range.endLine && endLine >= range.startLine;
}

List<_DiffPreviewRun> _diffPreviewRuns(List<GitDiffLine> lines) {
  final runs = <_DiffPreviewRun>[];
  var currentLines = <String>[];
  _DiffPreviewTone? currentTone;

  void flush() {
    if (currentLines.isEmpty) {
      return;
    }
    runs.add(_DiffPreviewRun(currentLines.join('\n'), currentTone));
    currentLines = <String>[];
  }

  for (final line in lines) {
    final tone = switch (line.kind) {
      GitDiffLineKind.added => _DiffPreviewTone.added,
      GitDiffLineKind.removed => _DiffPreviewTone.removed,
      GitDiffLineKind.context => null,
      GitDiffLineKind.header => null,
    };
    if (line.kind == GitDiffLineKind.header) {
      continue;
    }
    if (currentTone != tone) {
      flush();
      currentTone = tone;
    }
    currentLines.add(line.content);
  }
  flush();
  return runs;
}

List<PreviewBlock> _plainPreviewBlocks(String source) {
  return [
    for (final line in source.split('\n'))
      if (line.trim().isNotEmpty)
        PreviewBlock(
          kind: PreviewBlockKind.paragraph,
          text: line.trim(),
          inlines: [
            PreviewInline(kind: PreviewInlineKind.text, text: line.trim()),
          ],
        ),
  ];
}

PreviewBlock _withDiffPreviewTone(PreviewBlock block, _DiffPreviewTone? tone) {
  if (tone == null) {
    return block;
  }
  return PreviewBlock(
    kind: block.kind,
    text: block.text,
    level: block.level,
    language: block.language,
    visualization: block.visualization,
    inlines: block.inlines,
    children: [
      for (final child in block.children) _withDiffPreviewTone(child, tone),
    ],
    attributes: {...block.attributes, 'diffTone': tone.name},
    sourceStartLine: block.sourceStartLine,
    sourceEndLine: block.sourceEndLine,
    sourceStartOffset: block.sourceStartOffset,
    sourceEndOffset: block.sourceEndOffset,
  );
}

PreviewBlock _withDiffPreviewCodeLineTones(
  PreviewBlock block,
  Map<int, _DiffPreviewTone> sourceLineTones,
) {
  if (block.kind != PreviewBlockKind.code || sourceLineTones.isEmpty) {
    return block;
  }
  final startLine = block.sourceStartLine;
  final endLine = block.sourceEndLine;
  if (startLine == null || endLine == null) {
    return block;
  }
  final lines = block.text.split('\n');
  final contentLineCount = lines.isNotEmpty && lines.last.isEmpty
      ? lines.length - 1
      : lines.length;
  final firstContentSourceLine =
      startLine + ((endLine - startLine + 1) >= contentLineCount + 2 ? 1 : 0);
  final lineTones = <int, _DiffPreviewTone>{};
  for (var index = 0; index < contentLineCount; index += 1) {
    final tone = sourceLineTones[firstContentSourceLine + index];
    if (tone != null) {
      lineTones[index] = tone;
    }
  }
  if (lineTones.isEmpty) {
    return block;
  }
  return PreviewBlock(
    kind: block.kind,
    text: block.text,
    level: block.level,
    language: block.language,
    visualization: block.visualization,
    inlines: block.inlines,
    children: block.children,
    attributes: {
      ...block.attributes,
      'diffCodeLineTones': _encodeDiffPreviewCodeLineTones(lineTones),
    },
    sourceStartLine: block.sourceStartLine,
    sourceEndLine: block.sourceEndLine,
    sourceStartOffset: block.sourceStartOffset,
    sourceEndOffset: block.sourceEndOffset,
  );
}

String _encodeDiffPreviewCodeLineTones(Map<int, _DiffPreviewTone> lineTones) {
  final entries = lineTones.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  return entries.map((entry) => '${entry.key}:${entry.value.name}').join(',');
}

Map<int, _DiffPreviewTone> _diffPreviewCodeLineTones(PreviewBlock block) {
  final encoded = block.attributes['diffCodeLineTones'];
  if (encoded == null || encoded.isEmpty) {
    return const {};
  }
  final tones = <int, _DiffPreviewTone>{};
  for (final part in encoded.split(',')) {
    final separator = part.indexOf(':');
    if (separator <= 0 || separator == part.length - 1) {
      continue;
    }
    final lineIndex = int.tryParse(part.substring(0, separator));
    final tone = _diffPreviewToneFromName(part.substring(separator + 1));
    if (lineIndex != null && tone != null) {
      tones[lineIndex] = tone;
    }
  }
  return tones;
}

class _DiffPreviewData {
  const _DiffPreviewData(this.document, this.changeTargets);

  final PreviewDocument document;
  final List<_DiffPreviewChangeTarget> changeTargets;
}

class _DiffPreviewSnapshot {
  const _DiffPreviewSnapshot({required this.path, required this.source});

  final String path;
  final String source;
}

class _DiffPreviewChangeTarget {
  const _DiffPreviewChangeTarget({
    required this.blockIndex,
    required this.line,
  });

  final int blockIndex;
  final int line;
}

class _DiffChangedLineRange {
  const _DiffChangedLineRange({required this.startLine, required this.endLine});

  final int startLine;
  final int endLine;
}

class _DiffPreviewRun {
  const _DiffPreviewRun(this.source, this.tone);

  final String source;
  final _DiffPreviewTone? tone;
}

enum _DiffPreviewTone { added, removed, changed }

_DiffPreviewTone? _diffPreviewToneFromName(String? name) {
  if (name == null) {
    return null;
  }
  return _DiffPreviewTone.values
      .where((value) => value.name == name)
      .firstOrNull;
}

DocumentFile? _documentFileForPath(Workspace workspace, String path) {
  for (final file in workspace.files) {
    if (file.absolutePath == path) {
      return file;
    }
  }
  return null;
}

class _EditorPreviewSplit extends ConsumerStatefulWidget {
  const _EditorPreviewSplit({
    required this.state,
    required this.outline,
    required this.viewMode,
    required this.editorFontSize,
    required this.editorToolbarPlacement,
    required this.editorToolbarDirection,
    required this.wordWrap,
  });

  final WorkspaceState state;
  final List<DocumentOutlineHeading> outline;
  final DocumentViewModePreference viewMode;
  final double editorFontSize;
  final EditorToolbarPlacement editorToolbarPlacement;
  final EditorToolbarDirection editorToolbarDirection;
  final bool wordWrap;

  @override
  ConsumerState<_EditorPreviewSplit> createState() =>
      _EditorPreviewSplitState();
}

class _EditorPreviewSplitState extends ConsumerState<_EditorPreviewSplit> {
  final _previewScrollController = ItemScrollController();
  final _previewItemPositionsListener = ItemPositionsListener.create();
  PreviewDocument? _outlineStopsPreview;
  List<_PositionedOutlineHeading> _previewOutlineStops = const [];
  final _sourceEditorKey = GlobalKey<BusyMarkSourceEditorState>();
  final _previewBlockContexts = <int, BuildContext>{};
  String _lastPath = '';
  var _previewSearchScrollRequest = 0;
  BusyDocument? _cachedWysiwygDocument;
  String? _cachedWysiwygPath;
  String? _cachedWysiwygSource;
  String? _wysiwygScrollHeadingId;
  String? _wysiwygScrollBlockId;
  String? _wysiwygSearchQuery;
  var _wysiwygScrollRequest = 0;

  @override
  void initState() {
    super.initState();
    _lastPath = widget.state.workspace?.activeFilePath ?? '';
    _previewItemPositionsListener.itemPositions.addListener(
      _handlePreviewVisibleItemsChanged,
    );
  }

  @override
  void dispose() {
    _previewItemPositionsListener.itemPositions.removeListener(
      _handlePreviewVisibleItemsChanged,
    );
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _EditorPreviewSplit oldWidget) {
    super.didUpdateWidget(oldWidget);
    final path = widget.state.workspace?.activeFilePath ?? '';
    if (path != _lastPath) {
      _lastPath = path;
      _clearWysiwygCache();
      _previewBlockContexts.clear();
      _wysiwygScrollHeadingId = null;
      _wysiwygScrollBlockId = null;
      _wysiwygSearchQuery = null;
      _wysiwygScrollRequest = 0;
    }
    if (oldWidget.viewMode == DocumentViewModePreference.editor &&
        widget.viewMode != DocumentViewModePreference.editor &&
        widget.state.workspace != null &&
        widget.state.isDirty) {
      final workspaceId = widget.state.workspace!.id;
      final sourceFilePath = _activeEditorPath();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            widget.viewMode == DocumentViewModePreference.editor ||
            widget.state.workspace?.id != workspaceId ||
            _activeEditorPath() != sourceFilePath) {
          return;
        }
        ref
            .read(workspaceControllerProvider.notifier)
            .refreshActivePreview(sourceFilePath: sourceFilePath);
      });
    }
  }

  void _handlePreviewVisibleItemsChanged() {
    if (!mounted ||
        (widget.viewMode != DocumentViewModePreference.preview &&
            widget.viewMode != DocumentViewModePreference.split)) {
      return;
    }
    final preview = widget.state.preview;
    if (preview == null || preview.blocks.isEmpty) {
      _publishVisibleOutlineHeading(null);
      return;
    }
    final firstVisible = _firstVisiblePositionedItemIndex(
      _previewItemPositionsListener.itemPositions.value,
    );
    if (firstVisible == null) {
      return;
    }
    if (!identical(_outlineStopsPreview, preview)) {
      _outlineStopsPreview = preview;
      _previewOutlineStops = [
        for (final (index, block) in preview.blocks.indexed)
          if (_outlineHeadingForPreviewBlock(block) case final heading?)
            (itemIndex: index, heading: heading),
      ];
    }
    _publishVisibleOutlineHeading(
      _outlineHeadingAtItemIndex(_previewOutlineStops, firstVisible),
    );
  }

  void _handleWysiwygVisibleHeadingChanged(DocumentOutlineHeading? heading) {
    if (widget.viewMode == DocumentViewModePreference.editor) {
      _publishVisibleOutlineHeading(heading);
    }
  }

  void _handleSourceVisibleLineChanged(int? line) {
    final heading = line == null
        ? null
        : _outlineHeadingAtOrBeforeLine(widget.outline, line);
    _publishVisibleOutlineHeading(heading);
  }

  void _publishVisibleOutlineHeading(DocumentOutlineHeading? heading) {
    final workspace = widget.state.workspace;
    if (!mounted || workspace == null) {
      return;
    }
    _setOutlineViewportTarget(ref, workspace: workspace, heading: heading);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(_outlineNavigationTargetProvider, (previous, next) {
      if (next == null) {
        return;
      }
      final workspace = widget.state.workspace;
      if (workspace == null ||
          next.workspaceId != workspace.id ||
          next.filePath != workspace.activeFilePath) {
        return;
      }
      _scrollToOutlineTarget(next);
    });
    ref.listen(_sourceNavigationTargetProvider, (previous, next) {
      if (next == null) {
        return;
      }
      if (next.filePath != widget.state.workspace?.activeFilePath) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _sourceEditorKey.currentState?.scrollToLine(next.line);
        }
      });
    });
    ref.listen(_searchNavigationTargetProvider, (previous, next) {
      if (next == null) {
        return;
      }
      if (next.filePath != widget.state.workspace?.activeFilePath &&
          next.filePath != widget.state.workspace?.markdown?.filePath) {
        return;
      }
      _scrollToSearchTarget(next);
    });
    final colors = BusyMarkSurfaceColors.of(context);
    final settings = ref.watch(appSettingsControllerProvider);
    final headerBar = ref.watch(linuxHeaderBarServiceProvider);
    final allowRemoteImages = settings.allowsRemoteImagesForWorkspace(
      _remoteImageWorkspacePath(widget.state.workspace),
    );
    final editorVisible = widget.viewMode == DocumentViewModePreference.editor;
    final wysiwygDocument =
        editorVisible && _canUseWysiwyg(widget.state.workspace)
        ? _wysiwygDocument()
        : null;
    final wysiwygVisible =
        editorVisible &&
        _canUseWysiwyg(widget.state.workspace) &&
        wysiwygDocument != null;
    final sourceVisible =
        widget.viewMode != DocumentViewModePreference.preview &&
        !wysiwygVisible;
    final previewVisible =
        widget.viewMode != DocumentViewModePreference.source && !editorVisible;
    final standaloneDocumentLayout = BusyMarkDocumentLayoutSpec.standalone
        .withEditingToolbar(
          placement: widget.editorToolbarPlacement,
          direction: widget.editorToolbarDirection,
        );
    final activeEditorPath = _activeEditorPath();
    final searchState = ref.watch(_workspaceSearchProvider);
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.view),
      child: Row(
        children: [
          if (wysiwygVisible)
            Expanded(
              child: BusyMarkWysiwygEditor(
                document: wysiwygDocument,
                headerBarService: headerBar,
                workspaceRoot: _imageWorkspaceRoot(widget.state.workspace),
                writersideRoot:
                    widget.state.workspace?.writersideModule?.rootPath,
                imagesDir:
                    widget
                        .state
                        .workspace
                        ?.writersideModule
                        ?.effectiveImagesDir ??
                    'images',
                allowRemoteImages: allowRemoteImages,
                onRemoteImageBlocked: () =>
                    unawaited(_showRemoteImagesPrompt(context, ref)),
                onDocumentChanged: _cacheWysiwygDocument,
                onSourceChanged: _handleWysiwygSourceChanged,
                toolbarPlacement: widget.editorToolbarPlacement,
                toolbarDirection: widget.editorToolbarDirection,
                onToolbarPlacementChanged: ref
                    .read(appSettingsControllerProvider.notifier)
                    .setEditorToolbarPlacement,
                onToolbarDirectionChanged: ref
                    .read(appSettingsControllerProvider.notifier)
                    .setEditorToolbarDirection,
                scrollToHeadingId: _wysiwygScrollHeadingId,
                scrollToBlockId: _wysiwygScrollBlockId,
                scrollToSearchQuery: _wysiwygSearchQuery,
                scrollRequest: _wysiwygScrollRequest,
                onVisibleHeadingChanged: _handleWysiwygVisibleHeadingChanged,
                documentLayout: standaloneDocumentLayout,
                visualizationRevision: ref
                    .read(workspaceControllerProvider.notifier)
                    .editRevision,
                onOpenSearch: () => ref
                    .read(workspaceSearchOpenRequestProvider.notifier)
                    .request(),
                onCloseSearch: () => ref
                    .read(workspaceSearchCloseRequestProvider.notifier)
                    .request(),
              ),
            ),
          if (sourceVisible)
            Expanded(
              child: BusyMarkSourceEditor(
                key: _sourceEditorKey,
                text: widget.state.activeText,
                language: _sourceSyntaxLanguage(widget.state.workspace),
                filePath: activeEditorPath,
                diagnostics:
                    widget.state.workspace?.diagnostics ?? const <Diagnostic>[],
                editorFontSize: widget.editorFontSize,
                wordWrap: widget.wordWrap,
                searchActive: searchState.active,
                searchOptions: searchState.options,
                onSearchOptionsChanged: (options) {
                  final current = ref.read(_workspaceSearchProvider);
                  ref
                      .read(_workspaceSearchProvider.notifier)
                      .set(current.withOptions(options));
                },
                onOpenSearch: () => ref
                    .read(workspaceSearchOpenRequestProvider.notifier)
                    .request(),
                onCloseSearch: () => ref
                    .read(workspaceSearchCloseRequestProvider.notifier)
                    .request(),
                onVisibleLineChanged: _handleSourceVisibleLineChanged,
                onChanged: _handleSourceChanged,
                editRevision: ref
                    .read(workspaceControllerProvider.notifier)
                    .editRevision,
                onAiEdit:
                    (_activeDocumentKind(
                          widget.state.workspace,
                        )?.supportsAiMarkdownEditing ??
                        false)
                    ? (invocation) =>
                          showBusyMarkAiProposal(context, ref, invocation)
                    : null,
              ),
            ),
          if (sourceVisible && previewVisible)
            VerticalDivider(
              width: BusyMarkStroke.hairline,
              color: colors.subtleBorder,
            ),
          if (previewVisible)
            Expanded(
              child: _PreviewPane(
                preview: widget.state.preview,
                workspace: widget.state.workspace,
                activeSource: widget.state.activeText,
                editRevision: ref
                    .read(workspaceControllerProvider.notifier)
                    .editRevision,
                visualizationsEnabled: true,
                onVisualizationDiagnostic: _openVisualizationSourceLine,
                onEditVisualizationSource: _openVisualizationSourceLine,
                controller: _previewScrollController,
                itemPositionsListener: _previewItemPositionsListener,
                onBlockContextAvailable: _rememberPreviewBlockContext,
                onBlockContextUnavailable: _forgetPreviewBlockContext,
                documentLayout: sourceVisible
                    ? BusyMarkDocumentLayoutSpec.splitPreview
                    : standaloneDocumentLayout,
              ),
            ),
        ],
      ),
    );
  }

  void _rememberPreviewBlockContext(int index, BuildContext context) {
    _previewBlockContexts[index] = context;
  }

  Future<void> _openVisualizationSourceLine(int line) async {
    final workspace = widget.state.workspace;
    final filePath = _activeEditorPath();
    if (workspace == null || filePath == null) {
      return;
    }
    final settings = ref.read(appSettingsControllerProvider);
    if (settings.documentViewMode == DocumentViewModePreference.preview ||
        settings.documentViewMode == DocumentViewModePreference.editor) {
      await ref
          .read(appSettingsControllerProvider.notifier)
          .setDocumentViewMode(DocumentViewModePreference.split);
    }
    if (!mounted || widget.state.workspace?.id != workspace.id) {
      return;
    }
    ref
        .read(_sourceNavigationTargetProvider.notifier)
        .set(_SourceNavigationTarget(filePath: filePath, line: line));
  }

  void _forgetPreviewBlockContext(int index, BuildContext context) {
    if (identical(_previewBlockContexts[index], context)) {
      _previewBlockContexts.remove(index);
    }
  }

  void _handleSourceChanged(String value, String? sourceFilePath) {
    final activePath = _activeEditorPath();
    if (sourceFilePath != null && sourceFilePath != activePath) {
      return;
    }
    _clearWysiwygCache();
    ref
        .read(workspaceControllerProvider.notifier)
        .updateActiveText(value, sourceFilePath: sourceFilePath ?? activePath);
  }

  void _handleWysiwygSourceChanged(String filePath, String value) {
    if (filePath != _activeEditorPath()) {
      return;
    }
    final document = _cachedWysiwygDocument;
    final controller = ref.read(workspaceControllerProvider.notifier);
    if (document == null ||
        document.filePath != filePath ||
        document.source != value) {
      controller.updateActiveText(value, sourceFilePath: filePath);
      return;
    }
    controller.updateActiveWysiwygText(
      value,
      document: document,
      sourceFilePath: filePath,
    );
  }

  void _cacheWysiwygDocument(BusyDocument document) {
    _cachedWysiwygDocument = document;
    _cachedWysiwygPath = document.filePath;
    _cachedWysiwygSource = document.source;
  }

  void _clearWysiwygCache() {
    _cachedWysiwygDocument = null;
    _cachedWysiwygPath = null;
    _cachedWysiwygSource = null;
  }

  String? _activeEditorPath() {
    final workspace = widget.state.workspace;
    return workspace?.activeFilePath ?? workspace?.markdown?.filePath;
  }

  SourceSyntaxLanguage _sourceSyntaxLanguage(Workspace? workspace) {
    final kind = _activeDocumentKind(workspace);
    return switch (kind) {
      DocumentKind.markdown ||
      DocumentKind.writersideMarkdownTopic => SourceSyntaxLanguage.markdown,
      DocumentKind.writersideXmlTopic ||
      DocumentKind.tree ||
      DocumentKind.config ||
      DocumentKind.variables ||
      DocumentKind.categories => SourceSyntaxLanguage.xml,
      DocumentKind.image ||
      DocumentKind.resource ||
      DocumentKind.unknown ||
      null => SourceSyntaxLanguage.plain,
    };
  }

  DocumentKind? _activeDocumentKind(Workspace? workspace) {
    if (workspace == null) {
      return null;
    }
    return _activeWorkspaceDocumentKind(workspace);
  }

  void _scrollToOutlineTarget(_OutlineNavigationTarget target) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _wysiwygScrollHeadingId = target.headingId;
        _wysiwygScrollBlockId = target.editorBlockId;
        _wysiwygSearchQuery = null;
        _wysiwygScrollRequest += 1;
      });
      if (target.line case final line?) {
        _sourceEditorKey.currentState?.scrollToLine(line);
      }
      _scrollPreviewToHeading(target.headingId);
    });
  }

  void _scrollToSearchTarget(_SearchNavigationTarget target) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final editorVisible =
          widget.viewMode == DocumentViewModePreference.editor;
      final wysiwygVisible =
          editorVisible &&
          _canUseWysiwyg(widget.state.workspace) &&
          _wysiwygDocument() != null;
      final sourceVisible =
          widget.viewMode != DocumentViewModePreference.preview &&
          !wysiwygVisible;
      final previewVisible =
          widget.viewMode != DocumentViewModePreference.source &&
          !editorVisible;

      if (wysiwygVisible) {
        setState(() {
          _wysiwygScrollHeadingId = null;
          _wysiwygScrollBlockId = null;
          _wysiwygSearchQuery = target.query;
          _wysiwygScrollRequest += 1;
        });
      }
      if (sourceVisible) {
        _sourceEditorKey.currentState?.scrollToSearchRange(
          line: target.line,
          startOffset: target.startOffset,
          endOffset: target.endOffset,
        );
      }
      if (previewVisible) {
        _schedulePreviewSearchScroll(target);
      }
    });
  }

  void _scrollPreviewToHeading(String headingId) {
    final blocks = widget.state.preview?.blocks ?? const <PreviewBlock>[];
    final index = blocks.indexWhere(
      (block) =>
          block.kind == PreviewBlockKind.heading &&
          block.attributes['id'] == headingId,
    );
    if (index < 0 || !_previewScrollController.isAttached) {
      return;
    }
    unawaited(_scrollPreviewToIndex(index, alignment: 0.0));
  }

  Future<void> _scrollPreviewToIndex(
    int index, {
    double alignment = 0.04,
  }) async {
    final blockContext = _previewBlockContexts[index];
    if (blockContext != null && blockContext.mounted) {
      await Scrollable.ensureVisible(
        blockContext,
        alignment: alignment,
        duration: BusyMarkMotion.scroll,
        curve: Curves.easeOutCubic,
      );
      return;
    }
    if (!_previewScrollController.isAttached) {
      return;
    }
    _previewScrollController.jumpTo(index: index, alignment: alignment);
    await WidgetsBinding.instance.endOfFrame;
  }

  bool _scrollPreviewToSearchTarget(_SearchNavigationTarget target) {
    final query = target.query.trim();
    if (query.isEmpty || !_previewScrollController.isAttached) {
      return false;
    }
    final blocks = widget.state.preview?.blocks ?? const <PreviewBlock>[];
    final index = _previewSearchBlockIndex(
      blocks,
      target,
      widget.state.activeText,
    );
    if (index == null) {
      return _scrollPreviewToApproximateLine(target, blocks.length);
    }
    unawaited(_scrollPreviewToSearchBlock(target, index, blocks[index]));
    return true;
  }

  Future<void> _scrollPreviewToSearchBlock(
    _SearchNavigationTarget target,
    int index,
    PreviewBlock block,
  ) async {
    await _scrollPreviewToIndex(index, alignment: 0.0);
    if (!mounted || !_isCurrentPreviewSearchScroll(target)) {
      return;
    }
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || !_isCurrentPreviewSearchScroll(target)) {
      return;
    }
    var blockContext = _previewBlockContexts[index];
    if (blockContext == null) {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || !_isCurrentPreviewSearchScroll(target)) {
        return;
      }
      blockContext = _previewBlockContexts[index];
    }
    if (blockContext != null && blockContext.mounted) {
      _scrollPreviewToBlockOffset(blockContext, block, target);
    }
  }

  void _scrollPreviewToBlockOffset(
    BuildContext blockContext,
    PreviewBlock block,
    _SearchNavigationTarget target,
  ) {
    final renderObject = blockContext.findRenderObject();
    final position = Scrollable.maybeOf(blockContext)?.position;
    if (renderObject is! RenderBox || position == null) {
      return;
    }
    final viewportBox =
        position.context.notificationContext?.findRenderObject() as RenderBox?;
    if (viewportBox == null) {
      return;
    }
    final targetY = renderObject
        .localToGlobal(
          Offset(
            0,
            renderObject.size.height *
                _previewBlockTargetFraction(
                  block,
                  target,
                  widget.state.activeText,
                ),
          ),
        )
        .dy;
    final viewportTop = viewportBox.localToGlobal(Offset.zero).dy;
    final targetOffset =
        position.pixels + targetY - viewportTop - BusyMarkSpacing.lg;
    position.jumpTo(
      targetOffset.clamp(0.0, position.maxScrollExtent).toDouble(),
    );
  }

  bool _scrollPreviewToApproximateLine(
    _SearchNavigationTarget target,
    int blockCount,
  ) {
    if (!_previewScrollController.isAttached || blockCount == 0) {
      return false;
    }
    final sourceLineCount = widget.state.activeText.split('\n').length;
    final denominator = math.max(1, sourceLineCount - 1);
    final fraction = ((target.line - 1) / denominator).clamp(0.0, 1.0);
    final index = (fraction * (blockCount - 1)).round();
    unawaited(_scrollPreviewToIndex(index));
    return true;
  }

  void _schedulePreviewSearchScroll(_SearchNavigationTarget target) {
    _previewSearchScrollRequest = target.request;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isCurrentPreviewSearchScroll(target) ||
          _scrollPreviewToSearchTarget(target)) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isCurrentPreviewSearchScroll(target)) {
          _scrollPreviewToSearchTarget(target);
        }
      });
      unawaited(
        Future<void>.delayed(BusyMarkMotion.previewSearchDelay, () {
          if (_isCurrentPreviewSearchScroll(target)) {
            _scrollPreviewToSearchTarget(target);
          }
        }),
      );
      unawaited(
        Future<void>.delayed(BusyMarkMotion.scroll, () {
          if (_isCurrentPreviewSearchScroll(target)) {
            _scrollPreviewToSearchTarget(target);
          }
        }),
      );
    });
  }

  bool _isCurrentPreviewSearchScroll(_SearchNavigationTarget target) {
    return mounted && target.request == _previewSearchScrollRequest;
  }

  bool _canUseWysiwyg(Workspace? workspace) {
    final kind = _activeDocumentKind(workspace);
    return kind?.supportsAiMarkdownEditing ?? false;
  }

  BusyDocument? _wysiwygDocument() {
    final workspace = widget.state.workspace;
    final activePath =
        workspace?.activeFilePath ?? workspace?.markdown?.filePath;
    if (workspace == null || activePath == null) {
      return null;
    }
    if (_cachedWysiwygPath == activePath &&
        _cachedWysiwygSource == widget.state.activeText) {
      return _cachedWysiwygDocument;
    }
    final currentMarkdown = workspace.markdown;
    if (currentMarkdown != null &&
        p.equals(currentMarkdown.filePath, activePath) &&
        currentMarkdown.source == widget.state.activeText) {
      final document = currentMarkdown.busyDocument;
      _cachedWysiwygDocument = document;
      _cachedWysiwygPath = activePath;
      _cachedWysiwygSource = widget.state.activeText;
      return document;
    }
    final mode = workspace.kind == WorkspaceKind.writersideModule
        ? MarkdownMode.writersideMarkdown
        : MarkdownMode.commonMark;
    try {
      final document = const MarkdownParser()
          .parse(
            filePath: activePath,
            source: widget.state.activeText,
            mode: mode,
            workspaceRoot: workspace.rootPath,
            validateLocalReferences: false,
          )
          .busyDocument;
      _cachedWysiwygDocument = document;
      _cachedWysiwygPath = activePath;
      _cachedWysiwygSource = widget.state.activeText;
      return document;
    } on Object {
      return workspace.markdown?.busyDocument;
    }
  }
}

int? _firstVisiblePositionedItemIndex(Iterable<ItemPosition> positions) {
  int? first;
  for (final position in positions) {
    if (position.itemTrailingEdge <= 0 || position.itemLeadingEdge >= 1) {
      continue;
    }
    if (first == null || position.index < first) {
      first = position.index;
    }
  }
  return first;
}

typedef _PositionedOutlineHeading = ({
  int itemIndex,
  DocumentOutlineHeading heading,
});

DocumentOutlineHeading? _outlineHeadingForPreviewBlock(PreviewBlock block) {
  if (block.kind != PreviewBlockKind.heading) {
    return null;
  }
  final headingId = block.attributes['id'];
  final level = block.level;
  final sourceStartLine = block.sourceStartLine;
  final sourceStartOffset = block.sourceStartOffset;
  if (headingId == null ||
      headingId.isEmpty ||
      level == null ||
      sourceStartLine == null ||
      sourceStartOffset == null) {
    return null;
  }
  return DocumentOutlineHeading(
    level: level,
    text: block.text,
    id: headingId,
    sourceStartLine: sourceStartLine,
    sourceStartOffset: sourceStartOffset,
    editorBlockId: block.attributes['editorBlockId'],
  );
}

DocumentOutlineHeading? _outlineHeadingAtItemIndex(
  List<_PositionedOutlineHeading> headings,
  int itemIndex,
) {
  var low = 0;
  var high = headings.length - 1;
  DocumentOutlineHeading? result;
  while (low <= high) {
    final middle = (low + high) >> 1;
    final candidate = headings[middle];
    if (candidate.itemIndex <= itemIndex) {
      result = candidate.heading;
      low = middle + 1;
    } else {
      high = middle - 1;
    }
  }
  return result;
}

DocumentOutlineHeading? _outlineHeadingAtOrBeforeLine(
  List<DocumentOutlineHeading> headings,
  int line,
) {
  var low = 0;
  var high = headings.length - 1;
  DocumentOutlineHeading? result;
  var encounteredMissingLine = false;
  while (low <= high) {
    final middle = (low + high) >> 1;
    final heading = headings[middle];
    final headingLine = heading.sourceStartLine;
    if (headingLine == null) {
      encounteredMissingLine = true;
      break;
    }
    if (headingLine <= line) {
      result = heading;
      low = middle + 1;
    } else {
      high = middle - 1;
    }
  }
  if (!encounteredMissingLine) {
    return result;
  }
  result = null;
  for (final heading in headings) {
    final headingLine = heading.sourceStartLine;
    if (headingLine == null) {
      continue;
    }
    if (headingLine > line) {
      break;
    }
    result = heading;
  }
  return result;
}

class _PreviewPane extends StatelessWidget {
  const _PreviewPane({
    required this.preview,
    required this.workspace,
    required this.controller,
    required this.documentLayout,
    this.activeSource = '',
    this.editRevision = 0,
    this.visualizationsEnabled = false,
    this.onVisualizationDiagnostic,
    this.onEditVisualizationSource,
    this.itemPositionsListener,
    this.onBlockContextAvailable,
    this.onBlockContextUnavailable,
  });

  final PreviewDocument? preview;
  final Workspace? workspace;
  final String activeSource;
  final int editRevision;
  final bool visualizationsEnabled;
  final ValueChanged<int>? onVisualizationDiagnostic;
  final ValueChanged<int>? onEditVisualizationSource;
  final ItemScrollController controller;
  final ItemPositionsListener? itemPositionsListener;
  final BusyMarkDocumentLayoutSpec documentLayout;
  final void Function(int index, BuildContext context)? onBlockContextAvailable;
  final void Function(int index, BuildContext context)?
  onBlockContextUnavailable;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final document = preview;
    if (document == null) {
      return _EmptyPane(
        icon: BusyMarkGlyphs.preview,
        title: context.l10n.noPreview,
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.view),
      child: SelectionArea(
        child: BusyMarkDocumentContentFrame(
          layout: documentLayout,
          contentKey: const ValueKey('preview-document-content'),
          child: ScrollablePositionedList.builder(
            key: const ValueKey('preview-document-scroll'),
            itemScrollController: controller,
            itemPositionsListener: itemPositionsListener,
            padding: documentLayout.scrollPadding,
            itemCount: document.blocks.length,
            itemBuilder: (context, index) =>
                _keyedPreviewBlock(context, index, document.blocks[index]),
          ),
        ),
      ),
    );
  }

  Widget _keyedPreviewBlock(
    BuildContext context,
    int index,
    PreviewBlock block,
  ) {
    final child = _PreviewBlockView(
      block,
      first: index == 0,
      listRunEnd: _isLastListBlock(index),
      workspace: workspace,
      activeSource: activeSource,
      editRevision: editRevision,
      visualizationsEnabled: visualizationsEnabled,
      onVisualizationDiagnostic: onVisualizationDiagnostic,
      onEditVisualizationSource: onEditVisualizationSource,
      headingKey: block.kind == PreviewBlockKind.heading
          ? ValueKey('preview-heading-$index')
          : null,
    );
    return _PreviewBlockContextAnchor(
      key: ValueKey('preview-block-$index'),
      index: index,
      onAvailable: onBlockContextAvailable,
      onUnavailable: onBlockContextUnavailable,
      child: child,
    );
  }

  bool _isLastListBlock(int index) {
    final blocks = preview?.blocks;
    if (blocks == null || blocks[index].kind != PreviewBlockKind.list) {
      return false;
    }
    return index == blocks.length - 1 ||
        blocks[index + 1].kind != PreviewBlockKind.list;
  }
}

class _PreviewBlockContextAnchor extends StatefulWidget {
  const _PreviewBlockContextAnchor({
    super.key,
    required this.index,
    required this.child,
    this.onAvailable,
    this.onUnavailable,
  });

  final int index;
  final Widget child;
  final void Function(int index, BuildContext context)? onAvailable;
  final void Function(int index, BuildContext context)? onUnavailable;

  @override
  State<_PreviewBlockContextAnchor> createState() =>
      _PreviewBlockContextAnchorState();
}

class _PreviewBlockContextAnchorState
    extends State<_PreviewBlockContextAnchor> {
  @override
  void didUpdateWidget(covariant _PreviewBlockContextAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index ||
        oldWidget.onUnavailable != widget.onUnavailable) {
      oldWidget.onUnavailable?.call(oldWidget.index, context);
    }
  }

  @override
  void dispose() {
    widget.onUnavailable?.call(widget.index, context);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onAvailable?.call(widget.index, this.context);
      }
    });
    return widget.child;
  }
}

class _PreviewBlockView extends StatelessWidget {
  const _PreviewBlockView(
    this.block, {
    required this.workspace,
    required this.first,
    required this.listRunEnd,
    required this.headingKey,
    this.activeSource = '',
    this.editRevision = 0,
    this.visualizationsEnabled = false,
    this.onVisualizationDiagnostic,
    this.onEditVisualizationSource,
  });

  final PreviewBlock block;
  final Workspace? workspace;
  final bool first;
  final bool listRunEnd;
  final Key? headingKey;
  final String activeSource;
  final int editRevision;
  final bool visualizationsEnabled;
  final ValueChanged<int>? onVisualizationDiagnostic;
  final ValueChanged<int>? onEditVisualizationSource;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final displayBlock = _localizedPreviewBlock(context, block);
    final inheritedDirection = Directionality.of(context);
    final blockDirection = _previewBlockTextDirection(
      displayBlock,
      inheritedDirection,
    );
    final child = switch (displayBlock.kind) {
      PreviewBlockKind.heading => Padding(
        padding: first
            ? BusyMarkInsets.documentHeadingBlock.copyWith(top: 0)
            : BusyMarkInsets.documentHeadingBlock,
        child: _PreviewInlineText(
          key: headingKey,
          block: displayBlock,
          style: _diffPreviewTextStyle(
            context,
            displayBlock,
            busyMarkDocumentHeadingTextStyle(context, displayBlock.level),
          ),
        ),
      ),
      PreviewBlockKind.code
          when visualizationsEnabled && displayBlock.visualization != null =>
        _visualizationCard(displayBlock),
      PreviewBlockKind.code => BusyMarkDocumentCodeBlock(
        backgroundColor: _diffPreviewCodeBackground(context, displayBlock),
        child: Text.rich(
          _diffPreviewCodeTextSpan(
            context,
            displayBlock,
            busyMarkDocumentCodeTextStyle(context),
          ),
          textDirection: blockDirection,
        ),
      ),
      PreviewBlockKind.image => _PreviewImageBlock(
        block: displayBlock,
        workspace: workspace,
      ),
      PreviewBlockKind.admonition => BusyMarkDocumentAdmonition(
        style: displayBlock.attributes['style'],
        child: _PreviewInlineText(
          block: displayBlock,
          style: _diffPreviewTextStyle(context, displayBlock, null),
        ),
      ),
      PreviewBlockKind.tabs => BusyMarkDocumentCallout(
        icon: BusyMarkGlyphs.tab,
        child: Text(displayBlock.text),
      ),
      PreviewBlockKind.procedure => BusyMarkDocumentCallout(
        icon: BusyMarkGlyphs.orderedList,
        child: Text(displayBlock.text),
      ),
      PreviewBlockKind.list => Padding(
        padding: busyMarkDocumentListItemPadding(
          listRunEnd: listRunEnd,
          endsWithNestedList:
              displayBlock.children.isNotEmpty &&
              displayBlock.children.last.kind == PreviewBlockKind.list,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BusyMarkDocumentListMarker(
                  ordered: displayBlock.attributes['ordered'] == 'true',
                  marker: displayBlock.attributes['marker'],
                  task: switch (displayBlock.attributes['task']) {
                    'true' => true,
                    'false' => false,
                    _ => null,
                  },
                ),
                const SizedBox(width: BusyMarkSpacing.sm),
                Expanded(
                  child: _PreviewInlineText(
                    block: displayBlock,
                    style: _diffPreviewTextStyle(context, displayBlock, null),
                  ),
                ),
              ],
            ),
            if (displayBlock.children.isNotEmpty)
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: BusyMarkSizes.documentListIndent,
                ),
                child: _previewChildBlocks(displayBlock.children, first: false),
              ),
          ],
        ),
      ),
      PreviewBlockKind.quote => BusyMarkDocumentCallout(
        icon: BusyMarkGlyphs.blockquote,
        child: displayBlock.children.isEmpty
            ? _PreviewInlineText(
                block: displayBlock,
                style: _diffPreviewTextStyle(context, displayBlock, null),
              )
            : _previewChildBlocks(displayBlock.children, first: true),
      ),
      PreviewBlockKind.thematicBreak => const BusyMarkDocumentThematicBreak(),
      PreviewBlockKind.table => _PreviewTable(block: displayBlock),
      PreviewBlockKind.container
          when displayBlock.attributes['htmlTag'] == 'figure' =>
        _PreviewFigure(block: displayBlock, workspace: workspace, first: first),
      PreviewBlockKind.container => _previewChildBlocks(
        displayBlock.children,
        first: first,
      ),
      PreviewBlockKind.raw => BusyMarkDocumentCodeBlock(
        child: Text(
          displayBlock.text,
          textDirection: blockDirection,
          style: busyMarkDocumentCodeTextStyle(
            context,
            color: colors.mutedForeground,
          ),
        ),
      ),
      _ => Padding(
        padding: first
            ? BusyMarkInsets.documentParagraphBlock.copyWith(top: 0)
            : BusyMarkInsets.documentParagraphBlock,
        child: _PreviewInlineText(
          block: displayBlock,
          style: _diffPreviewTextStyle(context, displayBlock, null),
        ),
      ),
    };
    return blockDirection == inheritedDirection
        ? child
        : Directionality(textDirection: blockDirection, child: child);
  }

  Color _diffPreviewCodeBackground(BuildContext context, PreviewBlock block) {
    final colors = BusyMarkSurfaceColors.of(context);
    if (_diffPreviewCodeLineTones(block).isNotEmpty) {
      return colors.panel;
    }
    return switch (block.attributes['diffTone']) {
      'added' => colors.admonitionTip,
      'changed' => colors.admonitionTip,
      'removed' => colors.admonitionWarning,
      _ => colors.panel,
    };
  }

  Widget _visualizationCard(PreviewBlock block) {
    final descriptor = block.visualization!;
    final documentPath =
        workspace?.activeFilePath ?? workspace?.markdown?.filePath ?? '';
    final blockIdentity =
        block.attributes['editorBlockId'] ??
        block.sourceStartOffset?.toString() ??
        '${block.sourceStartLine ?? 1}';
    return BusyMarkVisualizationCard(
      key: ValueKey('visualization-$documentPath-$blockIdentity'),
      descriptor: descriptor,
      source: block.text,
      sourceFence: _visualizationSourceFence(block, descriptor),
      documentPath: documentPath,
      workspaceRoot: workspace?.rootPath ?? '',
      sourceStartLine: block.sourceStartLine ?? 1,
      editRevision: editRevision,
      blockKey: 'preview:${workspace?.id ?? ''}:$documentPath:$blockIdentity',
      onDiagnosticSelected: onVisualizationDiagnostic,
      onEditSource: onEditVisualizationSource == null
          ? null
          : () => onEditVisualizationSource!(block.sourceStartLine ?? 1),
    );
  }

  String _visualizationSourceFence(
    PreviewBlock block,
    VisualizationDescriptor descriptor,
  ) {
    final start = block.sourceStartOffset;
    final end = block.sourceEndOffset;
    if (start != null &&
        end != null &&
        start >= 0 &&
        end >= start &&
        end <= activeSource.length) {
      return activeSource.substring(start, end);
    }
    final source = block.text.endsWith('\n') ? block.text : '${block.text}\n';
    return '```${descriptor.originalLanguage}\n$source```';
  }

  TextSpan _diffPreviewCodeTextSpan(
    BuildContext context,
    PreviewBlock block,
    TextStyle? base,
  ) {
    final lineTones = _diffPreviewCodeLineTones(block);
    final blockStyle = _diffPreviewTextStyle(context, block, base);
    if (lineTones.isEmpty) {
      return TextSpan(text: block.text, style: blockStyle);
    }
    final spans = <InlineSpan>[];
    final lines = block.text.split('\n');
    for (final (index, line) in lines.indexed) {
      final tone = lineTones[index];
      spans.add(
        TextSpan(
          text: line,
          style: tone == null
              ? blockStyle
              : _diffPreviewTextStyleForTone(context, tone, base),
        ),
      );
      if (index < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }
    return TextSpan(style: blockStyle, children: spans);
  }

  TextStyle _diffPreviewTextStyle(
    BuildContext context,
    PreviewBlock block,
    TextStyle? base,
  ) {
    return _diffPreviewTextStyleForTone(
      context,
      _diffPreviewToneFromName(block.attributes['diffTone']),
      base,
    );
  }

  TextStyle _diffPreviewTextStyleForTone(
    BuildContext context,
    _DiffPreviewTone? tone,
    TextStyle? base,
  ) {
    final colors = BusyMarkSurfaceColors.of(context);
    final effectiveBase = base ?? busyMarkDocumentBodyTextStyle(context);
    return switch (tone) {
      _DiffPreviewTone.added || _DiffPreviewTone.changed =>
        effectiveBase.copyWith(backgroundColor: colors.admonitionTip),
      _DiffPreviewTone.removed => effectiveBase.copyWith(
        color: colors.mutedForeground,
        backgroundColor: colors.admonitionWarning,
        decoration: TextDecoration.lineThrough,
      ),
      null => effectiveBase,
    };
  }

  bool _isLastListBlock(List<PreviewBlock> blocks, int index) {
    return blocks[index].kind == PreviewBlockKind.list &&
        (index == blocks.length - 1 ||
            blocks[index + 1].kind != PreviewBlockKind.list);
  }

  Widget _previewChildBlocks(List<PreviewBlock> blocks, {required bool first}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, child) in blocks.indexed)
          _PreviewBlockView(
            child,
            workspace: workspace,
            first: first && index == 0,
            listRunEnd: _isLastListBlock(blocks, index),
            headingKey: null,
            activeSource: activeSource,
            editRevision: editRevision,
            visualizationsEnabled: visualizationsEnabled,
            onVisualizationDiagnostic: onVisualizationDiagnostic,
            onEditVisualizationSource: onEditVisualizationSource,
          ),
      ],
    );
  }

  PreviewBlock _localizedPreviewBlock(
    BuildContext context,
    PreviewBlock block,
  ) {
    if (block.text.trim().isNotEmpty) {
      return block;
    }
    final element = block.attributes['element'];
    final text = switch (block.kind) {
      PreviewBlockKind.heading =>
        element == 'chapter' ? context.l10n.chapter : context.l10n.topic,
      PreviewBlockKind.code => context.l10n.codeBlock,
      PreviewBlockKind.image => context.l10n.image,
      PreviewBlockKind.admonition => switch (block.attributes['style']) {
        'warning' => context.l10n.warning,
        'tip' => context.l10n.tip,
        _ => context.l10n.note,
      },
      PreviewBlockKind.tabs =>
        element == 'tab' ? context.l10n.tab : context.l10n.tabs,
      PreviewBlockKind.procedure =>
        element == 'step' ? context.l10n.step : context.l10n.procedure,
      PreviewBlockKind.paragraph =>
        element == 'a'
            ? context.l10n.link
            : element ?? context.l10n.untitledResult,
      _ => block.text,
    };
    if (text == block.text) {
      return block;
    }
    return PreviewBlock(
      kind: block.kind,
      text: text,
      level: block.level,
      language: block.language,
      visualization: block.visualization,
      attributes: block.attributes,
      inlines: block.inlines,
      children: block.children,
      sourceStartLine: block.sourceStartLine,
      sourceEndLine: block.sourceEndLine,
      sourceStartOffset: block.sourceStartOffset,
      sourceEndOffset: block.sourceEndOffset,
    );
  }
}

TextDirection _previewBlockTextDirection(
  PreviewBlock block,
  TextDirection inheritedDirection,
) {
  return busyMarkDocumentTextDirection(
    text: _previewDirectionalText(block),
    fallback: inheritedDirection,
    explicitDirection: block.attributes['dir'],
    technical:
        block.kind == PreviewBlockKind.code ||
        block.kind == PreviewBlockKind.raw,
  );
}

String _previewDirectionalText(PreviewBlock block) {
  return [
    block.text,
    for (final child in block.children) _previewDirectionalText(child),
  ].join(' ');
}

class _PreviewTable extends StatelessWidget {
  const _PreviewTable({required this.block});

  final PreviewBlock block;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final columnCount = block.children.fold<int>(
      0,
      (max, row) => math.max(max, row.children.length),
    );
    return Container(
      margin: const EdgeInsets.symmetric(vertical: BusyMarkSpacing.smPlus),
      decoration: BoxDecoration(
        color: colors.panel,
        borderRadius: BorderRadius.circular(BusyMarkRadius.md),
        border: Border.all(color: colors.subtleBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(BusyMarkRadius.md),
        child: Table(
          border: TableBorder.symmetric(
            inside: BorderSide(color: colors.subtleBorder),
          ),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            for (final row in block.children)
              TableRow(
                decoration: BoxDecoration(
                  color: row.attributes['header'] == 'true'
                      ? colors.control
                      : BusyMarkLinuxPalette.transparent,
                ),
                children: [
                  for (var index = 0; index < columnCount; index += 1)
                    Padding(
                      padding: BusyMarkInsets.documentTableCell,
                      child: index < row.children.length
                          ? _PreviewInlineText(
                              block: row.children[index],
                              style: row.attributes['header'] == 'true'
                                  ? busyMarkDocumentBodyTextStyle(
                                      context,
                                    ).copyWith(fontWeight: FontWeight.w700)
                                  : null,
                            )
                          : const SizedBox.shrink(),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _PreviewInlineText extends ConsumerWidget {
  const _PreviewInlineText({super.key, required this.block, this.style});

  final PreviewBlock block;
  final TextStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baseStyle = style ?? busyMarkDocumentBodyTextStyle(context);
    final searchState = ref.watch(_workspaceSearchProvider);
    final workspace = ref.watch(workspaceControllerProvider).workspace;
    final settings = ref.watch(appSettingsControllerProvider);
    final allowRemoteImages = settings.allowsRemoteImagesForWorkspace(
      _remoteImageWorkspacePath(workspace),
    );
    final highlightQuery = searchState.active ? searchState.query.trim() : '';
    final inlines = block.inlines.isEmpty
        ? [PreviewInline(kind: PreviewInlineKind.text, text: block.text)]
        : block.inlines;
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        end: BusyMarkDocumentTextGeometry.editableLayoutInset,
      ),
      child: Text.rich(
        TextSpan(
          style: baseStyle,
          children: [
            for (final inline in inlines)
              _previewInlineSpan(
                context,
                inline,
                workspace: workspace,
                highlightQuery: highlightQuery,
                allowRemoteImages: allowRemoteImages,
                onRemoteImageBlocked: () =>
                    unawaited(_showRemoteImagesPrompt(context, ref)),
                onLinkTap: (destination) =>
                    _openPreviewLink(context, ref, destination),
              ),
          ],
        ),
      ),
    );
  }
}

String _previewBlockSearchText(PreviewBlock block) {
  return [
    block.text,
    for (final inline in block.inlines) _previewInlineSearchText(inline),
    for (final child in block.children) _previewBlockSearchText(child),
  ].where((value) => value.isNotEmpty).join(' ');
}

int? _previewSearchBlockIndex(
  List<PreviewBlock> blocks,
  _SearchNavigationTarget target,
  String source,
) {
  int? nearestBeforeIndex;
  int? nearestAfterIndex;
  for (final (index, block) in blocks.indexed) {
    if (_previewBlockContainsSearchTarget(block, target)) {
      return index;
    }
    final startLine = block.sourceStartLine;
    if (startLine == null) {
      continue;
    }
    if (startLine <= target.line) {
      nearestBeforeIndex = index;
    } else {
      nearestAfterIndex ??= index;
    }
  }
  return _previewSearchBlockIndexForSourceLine(blocks, source, target) ??
      _previewSearchBlockIndexForOrdinal(
        blocks,
        target.query,
        _searchResultOrdinalInSource(source, target),
      ) ??
      nearestBeforeIndex ??
      nearestAfterIndex;
}

int? _previewSearchBlockIndexForSourceLine(
  List<PreviewBlock> blocks,
  String source,
  _SearchNavigationTarget target,
) {
  final rawLine = _sourceLineText(source, target.line).trim();
  if (rawLine.isEmpty) {
    return null;
  }
  final strippedLine = _stripMarkdownForSearchResult(rawLine).toLowerCase();
  final rawNeedle = rawLine.toLowerCase();
  if (strippedLine.isEmpty && rawNeedle.isEmpty) {
    return null;
  }
  for (final (index, block) in blocks.indexed) {
    final searchText = _previewBlockSearchText(block).toLowerCase();
    if ((strippedLine.isNotEmpty && searchText.contains(strippedLine)) ||
        (rawNeedle.isNotEmpty && searchText.contains(rawNeedle))) {
      return index;
    }
  }
  return null;
}

String _sourceLineText(String source, int lineNumber) {
  if (lineNumber <= 0) {
    return '';
  }
  final lines = source.split('\n');
  if (lineNumber > lines.length) {
    return '';
  }
  return lines[lineNumber - 1];
}

int _searchResultOrdinalInSource(
  String source,
  _SearchNavigationTarget target,
) {
  final normalizedQuery = target.query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) {
    return 0;
  }
  final lines = source.split('\n');
  var ordinal = 0;
  var lineStartOffset = 0;
  for (final line in lines) {
    final matchColumn = line.toLowerCase().indexOf(normalizedQuery);
    if (matchColumn >= 0) {
      final startOffset = lineStartOffset + matchColumn;
      if (startOffset == target.startOffset) {
        return ordinal;
      }
      if (startOffset > target.startOffset) {
        return ordinal;
      }
      ordinal += 1;
    }
    lineStartOffset += line.length + 1;
  }
  return ordinal;
}

int? _previewSearchBlockIndexForOrdinal(
  List<PreviewBlock> blocks,
  String query,
  int ordinal,
) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) {
    return null;
  }
  var matchIndex = 0;
  for (final (index, block) in blocks.indexed) {
    if (!_previewBlockSearchText(
      block,
    ).toLowerCase().contains(normalizedQuery)) {
      continue;
    }
    if (matchIndex == ordinal) {
      return index;
    }
    matchIndex += 1;
  }
  return null;
}

String _previewInlineSearchText(PreviewInline inline) {
  return [
    inline.text,
    for (final child in inline.children) _previewInlineSearchText(child),
  ].where((value) => value.isNotEmpty).join(' ');
}

bool _previewBlockContainsSearchTarget(
  PreviewBlock block,
  _SearchNavigationTarget target,
) {
  final startOffset = block.sourceStartOffset;
  final endOffset = block.sourceEndOffset;
  if (startOffset != null &&
      endOffset != null &&
      target.startOffset >= startOffset &&
      target.startOffset < endOffset) {
    return true;
  }

  final startLine = block.sourceStartLine;
  final endLine = block.sourceEndLine;
  if (startLine != null &&
      endLine != null &&
      target.line >= startLine &&
      target.line <= endLine) {
    return true;
  }

  return block.children.any(
    (child) => _previewBlockContainsSearchTarget(child, target),
  );
}

double _previewBlockTargetFraction(
  PreviewBlock block,
  _SearchNavigationTarget target,
  String source,
) {
  final startOffset = block.sourceStartOffset;
  final endOffset = block.sourceEndOffset;
  if (startOffset != null && endOffset != null && endOffset > startOffset) {
    return ((target.startOffset - startOffset) / (endOffset - startOffset))
        .clamp(0.0, 1.0)
        .toDouble();
  }

  final startLine = block.sourceStartLine;
  final endLine = block.sourceEndLine;
  if (startLine != null && endLine != null && endLine > startLine) {
    return ((target.line - startLine) / (endLine - startLine))
        .clamp(0.0, 1.0)
        .toDouble();
  }

  final sourceLine = _sourceLineText(source, target.line).trim();
  if (sourceLine.isNotEmpty && block.text.contains('\n')) {
    final sourceNeedles = {
      sourceLine,
      _stripMarkdownForSearchResult(sourceLine),
    }.where((value) => value.isNotEmpty).map((value) => value.toLowerCase());
    final blockLines = block.text.split('\n');
    for (final (index, blockLine) in blockLines.indexed) {
      final normalizedBlockLine = blockLine.trim().toLowerCase();
      if (sourceNeedles.any(normalizedBlockLine.contains)) {
        final denominator = math.max(1, blockLines.length - 1);
        return (index / denominator).clamp(0.0, 1.0).toDouble();
      }
    }
  }

  return 0.0;
}

class _PreviewFigure extends StatelessWidget {
  const _PreviewFigure({
    required this.block,
    required this.workspace,
    required this.first,
  });

  static const double _captionMinWidth = 240;

  final PreviewBlock block;
  final Workspace? workspace;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final contentBlocks = block.children.where(_isNotCaption).toList();
    final captionBlocks = block.children.where(_isCaption).toList();
    final captionStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: colors.mutedForeground,
      height: BusyMarkTypography.bodyLineHeight,
    );
    final captionWidth = _captionWidth(contentBlocks);

    return Padding(
      padding: EdgeInsets.only(
        top: first ? 0 : BusyMarkSpacing.smPlus,
        bottom: BusyMarkSpacing.smPlus,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (index, child) in contentBlocks.indexed)
            _figureContentBlock(child, index, contentBlocks),
          if (captionBlocks.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                top: contentBlocks.isEmpty ? 0 : BusyMarkSpacing.xs,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: captionWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (index, caption) in captionBlocks.indexed)
                      Padding(
                        padding: EdgeInsets.only(
                          top: index == 0 ? 0 : BusyMarkSpacing.xs,
                        ),
                        child: _PreviewInlineText(
                          block: caption,
                          style: captionStyle,
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _figureContentBlock(
    PreviewBlock child,
    int index,
    List<PreviewBlock> contentBlocks,
  ) {
    if (child.kind == PreviewBlockKind.image) {
      return _PreviewImageBlock(
        block: child,
        workspace: workspace,
        padding: EdgeInsets.zero,
      );
    }
    return _PreviewBlockView(
      child,
      workspace: workspace,
      first: index == 0,
      listRunEnd: _isLastListBlock(contentBlocks, index),
      headingKey: null,
    );
  }

  double _captionWidth(List<PreviewBlock> contentBlocks) {
    for (final child in contentBlocks) {
      if (child.kind != PreviewBlockKind.image) {
        continue;
      }
      final width = busyMarkDocumentImageWidth(child.attributes);
      if (width != null) {
        return math.max(width, _captionMinWidth);
      }
    }
    return BusyMarkSizes.documentImageMaxWidth;
  }

  bool _isLastListBlock(List<PreviewBlock> blocks, int index) {
    return blocks[index].kind == PreviewBlockKind.list &&
        (index == blocks.length - 1 ||
            blocks[index + 1].kind != PreviewBlockKind.list);
  }

  bool _isCaption(PreviewBlock block) {
    return block.attributes['htmlTag'] == 'figcaption';
  }

  bool _isNotCaption(PreviewBlock block) {
    return !_isCaption(block);
  }
}

class _PreviewImageBlock extends ConsumerWidget {
  const _PreviewImageBlock({
    required this.block,
    required this.workspace,
    this.padding = BusyMarkInsets.documentImageBlock,
  });

  final PreviewBlock block;
  final Workspace? workspace;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = busyMarkDocumentImageWidth(block.attributes);
    final source = _previewImageSource(block);
    final activeFilePath =
        workspace?.activeFilePath ?? workspace?.markdown?.filePath;
    final settings = ref.watch(appSettingsControllerProvider);
    final allowRemoteImages = settings.allowsRemoteImagesForWorkspace(
      _remoteImageWorkspacePath(workspace),
    );
    return Padding(
      padding: padding,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: BusyMarkSizes.documentImageMinHeight,
        ),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: MarkdownImageView(
            source: source,
            alt: block.text,
            activeFilePath: activeFilePath ?? '',
            workspaceRoot: _imageWorkspaceRoot(workspace),
            writersideRoot: workspace?.writersideModule?.rootPath,
            imagesDir:
                workspace?.writersideModule?.effectiveImagesDir ?? 'images',
            allowRemoteImages: allowRemoteImages,
            onRemoteImageBlocked: () =>
                unawaited(_showRemoteImagesPrompt(context, ref)),
            width: width,
            maxWidth: width ?? BusyMarkSizes.documentImageMaxWidth,
          ),
        ),
      ),
    );
  }
}

String? _imageWorkspaceRoot(Workspace? workspace) {
  if (workspace == null) {
    return null;
  }
  final module = workspace.writersideModule;
  if (module == null) {
    return workspace.rootPath;
  }
  final activeFilePath =
      workspace.activeFilePath ?? workspace.markdown?.filePath;
  if (activeFilePath == null) {
    return null;
  }
  return module.topics
      .where((topic) => topic.filePath == activeFilePath)
      .map((topic) => topic.topicRoot)
      .firstOrNull;
}

String _previewImageSource(PreviewBlock block) {
  final attributeSource = block.attributes['src'];
  if (attributeSource != null && attributeSource.trim().isNotEmpty) {
    return attributeSource.trim();
  }
  for (final inline in block.inlines) {
    final source = _previewImageSourceFromInline(inline);
    if (source != null) {
      return source;
    }
  }
  return '';
}

String? _previewImageSourceFromInline(PreviewInline inline) {
  if (inline.kind == PreviewInlineKind.image &&
      inline.destination != null &&
      inline.destination!.trim().isNotEmpty) {
    return inline.destination!.trim();
  }
  for (final child in inline.children) {
    final source = _previewImageSourceFromInline(child);
    if (source != null) {
      return source;
    }
  }
  return null;
}

InlineSpan _previewInlineSpan(
  BuildContext context,
  PreviewInline inline, {
  required Workspace? workspace,
  required String highlightQuery,
  required bool allowRemoteImages,
  required VoidCallback? onRemoteImageBlocked,
  required Future<void> Function(String destination) onLinkTap,
  String? inheritedLinkDestination,
  TextStyle? inheritedStyle,
}) {
  final colors = BusyMarkSurfaceColors.of(context);
  final theme = Theme.of(context);
  final linkDestination = inline.kind == PreviewInlineKind.link
      ? inline.destination ?? inline.text
      : inheritedLinkDestination;
  final linkStyle = linkDestination == null
      ? null
      : TextStyle(
          color: theme.colorScheme.primary,
          decoration: TextDecoration.underline,
        );
  TextStyle? mergeStyle(TextStyle? style) {
    final merged = inheritedStyle?.merge(style) ?? style ?? inheritedStyle;
    return merged?.merge(linkStyle) ?? linkStyle;
  }

  TapGestureRecognizer? linkRecognizer() {
    final destination = linkDestination;
    if (destination == null || destination.trim().isEmpty) {
      return null;
    }
    return TapGestureRecognizer()
      ..onTap = () {
        unawaited(onLinkTap(destination));
      };
  }

  InlineSpan childSpan(PreviewInline child, TextStyle? style) {
    return _previewInlineSpan(
      context,
      child,
      workspace: workspace,
      highlightQuery: highlightQuery,
      allowRemoteImages: allowRemoteImages,
      onRemoteImageBlocked: onRemoteImageBlocked,
      onLinkTap: onLinkTap,
      inheritedLinkDestination: linkDestination,
      inheritedStyle: style,
    );
  }

  TextSpan span({
    required String? text,
    required List<InlineSpan>? children,
    TextStyle? style,
  }) {
    final clickable = linkDestination != null && text != null;
    if (text != null && highlightQuery.trim().isNotEmpty) {
      final highlighted = _highlightedPreviewTextSpans(
        context,
        text,
        highlightQuery,
        style: style,
        mouseCursor: clickable ? SystemMouseCursors.click : null,
        recognizerBuilder: clickable ? linkRecognizer : null,
      );
      if (highlighted != null) {
        return TextSpan(children: highlighted);
      }
    }
    return TextSpan(
      text: text,
      children: children,
      style: style,
      mouseCursor: clickable ? SystemMouseCursors.click : null,
      recognizer: clickable ? linkRecognizer() : null,
    );
  }

  return switch (inline.kind) {
    PreviewInlineKind.text => span(
      text: inline.text,
      children: null,
      style: mergeStyle(null),
    ),
    PreviewInlineKind.strong => span(
      text: inline.children.isEmpty ? inline.text : null,
      children: inline.children.isEmpty
          ? null
          : [
              for (final child in inline.children)
                childSpan(
                  child,
                  mergeStyle(const TextStyle(fontWeight: FontWeight.w700)),
                ),
            ],
      style: mergeStyle(const TextStyle(fontWeight: FontWeight.w700)),
    ),
    PreviewInlineKind.emphasis => span(
      text: inline.children.isEmpty ? inline.text : null,
      children: inline.children.isEmpty
          ? null
          : [
              for (final child in inline.children)
                childSpan(
                  child,
                  mergeStyle(const TextStyle(fontStyle: FontStyle.italic)),
                ),
            ],
      style: mergeStyle(const TextStyle(fontStyle: FontStyle.italic)),
    ),
    PreviewInlineKind.underline => span(
      text: inline.children.isEmpty ? inline.text : null,
      children: inline.children.isEmpty
          ? null
          : [
              for (final child in inline.children)
                childSpan(
                  child,
                  mergeStyle(
                    const TextStyle(decoration: TextDecoration.underline),
                  ),
                ),
            ],
      style: mergeStyle(const TextStyle(decoration: TextDecoration.underline)),
    ),
    PreviewInlineKind.strikethrough => span(
      text: inline.children.isEmpty ? inline.text : null,
      children: inline.children.isEmpty
          ? null
          : [
              for (final child in inline.children)
                childSpan(
                  child,
                  mergeStyle(
                    const TextStyle(decoration: TextDecoration.lineThrough),
                  ),
                ),
            ],
      style: mergeStyle(
        const TextStyle(decoration: TextDecoration.lineThrough),
      ),
    ),
    PreviewInlineKind.code => span(
      text: inline.text,
      children: null,
      style: mergeStyle(
        TextStyle(
          fontFamily: BusyMarkTypography.monoFontFamily,
          backgroundColor: colors.control,
          color: colors.foreground,
        ),
      ),
    ),
    PreviewInlineKind.link => span(
      text: inline.children.isEmpty ? inline.text : null,
      children: inline.children.isEmpty
          ? null
          : [
              for (final child in inline.children)
                childSpan(child, mergeStyle(null)),
            ],
      style: mergeStyle(null),
    ),
    PreviewInlineKind.image => _previewInlineImageSpan(
      context,
      inline,
      workspace,
      allowRemoteImages: allowRemoteImages,
      onRemoteImageBlocked: onRemoteImageBlocked,
      style: mergeStyle(
        TextStyle(color: colors.mutedForeground, fontStyle: FontStyle.italic),
      ),
    ),
  };
}

InlineSpan _previewInlineImageSpan(
  BuildContext context,
  PreviewInline inline,
  Workspace? workspace, {
  required bool allowRemoteImages,
  required VoidCallback? onRemoteImageBlocked,
  required TextStyle? style,
}) {
  final activeFilePath =
      workspace?.activeFilePath ?? workspace?.markdown?.filePath;
  return WidgetSpan(
    alignment: PlaceholderAlignment.middle,
    style: const TextStyle(
      decoration: TextDecoration.none,
      fontStyle: FontStyle.normal,
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: BusyMarkSpacing.xs),
      child: DefaultTextStyle.merge(
        style: style,
        child: MarkdownImageView(
          source: inline.destination ?? '',
          alt: inline.text,
          activeFilePath: activeFilePath ?? '',
          workspaceRoot: _imageWorkspaceRoot(workspace),
          writersideRoot: workspace?.writersideModule?.rootPath,
          imagesDir:
              workspace?.writersideModule?.effectiveImagesDir ?? 'images',
          allowRemoteImages: allowRemoteImages,
          onRemoteImageBlocked: onRemoteImageBlocked,
          maxWidth: BusyMarkSizes.previewMinWidth,
          maxHeight: BusyMarkSizes.previewInlineImageMaxHeight,
          height: BusyMarkSizes.previewInlineImageHeight,
        ),
      ),
    ),
  );
}

List<InlineSpan>? _highlightedPreviewTextSpans(
  BuildContext context,
  String text,
  String query, {
  required TextStyle? style,
  MouseCursor? mouseCursor,
  GestureRecognizer? Function()? recognizerBuilder,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) {
    return null;
  }
  final normalizedText = text.toLowerCase();
  final firstMatch = normalizedText.indexOf(normalizedQuery);
  if (firstMatch < 0) {
    return null;
  }
  final highlightStyle =
      style?.merge(
        TextStyle(
          backgroundColor: Theme.of(context).colorScheme.primary.withValues(
            alpha: BusyMarkAlpha.previewHighlight,
          ),
        ),
      ) ??
      TextStyle(
        backgroundColor: Theme.of(
          context,
        ).colorScheme.primary.withValues(alpha: BusyMarkAlpha.previewHighlight),
      );
  final spans = <InlineSpan>[];
  var cursor = 0;
  var match = firstMatch;
  while (match >= 0) {
    if (match > cursor) {
      spans.add(
        TextSpan(
          text: text.substring(cursor, match),
          style: style,
          mouseCursor: mouseCursor,
          recognizer: recognizerBuilder?.call(),
        ),
      );
    }
    final end = match + normalizedQuery.length;
    spans.add(
      TextSpan(
        text: text.substring(match, end),
        style: highlightStyle,
        mouseCursor: mouseCursor,
        recognizer: recognizerBuilder?.call(),
      ),
    );
    cursor = end;
    match = normalizedText.indexOf(normalizedQuery, cursor);
  }
  if (cursor < text.length) {
    spans.add(
      TextSpan(
        text: text.substring(cursor),
        style: style,
        mouseCursor: mouseCursor,
        recognizer: recognizerBuilder?.call(),
      ),
    );
  }
  return spans;
}

Future<void> _openPreviewLink(
  BuildContext context,
  WidgetRef ref,
  String destination,
) async {
  final target = destination.trim();
  if (target.isEmpty) {
    return;
  }
  final uri = parseSchemedUri(target);
  if (uri != null) {
    if (!isLaunchableExternalUri(uri)) {
      if (context.mounted) {
        _showPreviewLinkMessage(
          context,
          context.l10n.couldNotOpenTarget(target),
        );
      }
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      _showPreviewLinkMessage(context, context.l10n.couldNotOpenTarget(target));
    }
    return;
  }

  final state = ref.read(workspaceControllerProvider);
  final workspace = state.workspace;
  final activeFilePath = workspace?.activeFilePath;
  if (workspace == null || activeFilePath == null) {
    return;
  }

  final parts = target.split('#');
  final targetPath = _decodePreviewLinkPart(parts.first);
  final anchor = parts.length > 1
      ? _decodePreviewLinkPart(parts.sublist(1).join('#'))
      : null;
  if (targetPath.isEmpty) {
    _navigatePreviewAnchor(context, ref, activeFilePath, anchor);
    return;
  }

  final resolvedPath = p.normalize(
    p.join(p.dirname(activeFilePath), targetPath),
  );
  final file = workspace.files
      .where((file) => p.normalize(file.absolutePath) == resolvedPath)
      .firstOrNull;
  if (file == null) {
    if (context.mounted) {
      _showPreviewLinkMessage(
        context,
        context.l10n.linkTargetNotFound(targetPath),
      );
    }
    return;
  }
  if (!_isOpenableTextDocument(file)) {
    if (context.mounted) {
      _showPreviewLinkMessage(context, context.l10n.cannotOpenFileTypeInEditor);
    }
    return;
  }
  if (workspace.activeFilePath != file.absolutePath) {
    if (!await saveOrConfirmSafeToChangeActiveFile(context, ref) ||
        !context.mounted) {
      return;
    }
    await ref
        .read(workspaceControllerProvider.notifier)
        .openActiveFile(file.absolutePath);
    _clearGitDetailSelection(ref);
  }
  if (!context.mounted) {
    return;
  }
  _navigatePreviewAnchor(context, ref, file.absolutePath, anchor);
}

Future<void> _openInFiles(BuildContext context, String path) async {
  final target = _openInFilesTargetPath(path);
  if (target.isEmpty) {
    return;
  }
  final launched = await launchUrl(
    Uri.file(target),
    mode: LaunchMode.externalApplication,
  );
  if (!launched && context.mounted) {
    _showPreviewLinkMessage(context, context.l10n.couldNotOpenTarget(target));
  }
}

String _openInFilesTargetPath(String path) {
  final trimmed = path.trim();
  if (trimmed.isEmpty) {
    return '';
  }
  final normalized = p.normalize(trimmed);
  final type = FileSystemEntity.typeSync(normalized);
  if (type == FileSystemEntityType.directory) {
    return normalized;
  }
  return p.dirname(normalized);
}

Future<void> _copyToClipboard(String value) {
  return Clipboard.setData(ClipboardData(text: value));
}

String _decodePreviewLinkPart(String value) {
  try {
    return Uri.decodeComponent(value);
  } on FormatException {
    return value;
  }
}

void _navigatePreviewAnchor(
  BuildContext context,
  WidgetRef ref,
  String filePath,
  String? anchor,
) {
  if (anchor == null || anchor.isEmpty) {
    return;
  }
  final state = ref.read(workspaceControllerProvider);
  final workspace = state.workspace;
  final activePath = workspace?.activeFilePath ?? workspace?.markdown?.filePath;
  if (workspace == null || activePath != filePath) {
    return;
  }
  final normalizedAnchor = anchor.startsWith('#')
      ? anchor.substring(1)
      : anchor;
  final decodedAnchor = _decodePreviewAnchor(normalizedAnchor);
  final slug = slugForHeading(decodedAnchor);
  final heading = state.preview?.outline
      .where(
        (heading) =>
            heading.id == normalizedAnchor ||
            heading.id == decodedAnchor ||
            heading.id == slug ||
            slugForHeading(heading.text) == slug,
      )
      .firstOrNull;
  if (heading == null) {
    _showPreviewLinkMessage(context, context.l10n.anchorNotFound(anchor));
    return;
  }
  ref
      .read(_outlineNavigationTargetProvider.notifier)
      .set(
        _OutlineNavigationTarget(
          workspaceId: workspace.id,
          filePath: workspace.activeFilePath,
          headingId: heading.id,
          line: heading.sourceStartLine,
          editorBlockId: heading.editorBlockId,
        ),
      );
}

void _showPreviewLinkMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

enum _RemoteImagesPromptAction { cancel, allowWorkspace, allowAlways }

Future<void> _showRemoteImagesPrompt(
  BuildContext context,
  WidgetRef ref,
) async {
  final workspacePath = _remoteImageWorkspacePath(
    ref.read(workspaceControllerProvider).workspace,
  );
  final headerBar = ref.read(linuxHeaderBarServiceProvider);
  final action = await showBusyMarkModalDialog<_RemoteImagesPromptAction>(
    context,
    headerBarService: headerBar.isAvailable ? headerBar : null,
    builder: (context) => BusyMarkDialogShell(
      title: context.l10n.remoteImagesBlockedTitle,
      maxWidth: BusyMarkSizes.dialog,
      actions: [
        BusyMarkDialogButton(
          label: context.l10n.cancel,
          icon: BusyMarkGlyphs.clear,
          onPressed: () =>
              Navigator.pop(context, _RemoteImagesPromptAction.cancel),
        ),
        if (workspacePath != null)
          BusyMarkDialogButton(
            label: context.l10n.loadRemoteImagesForWorkspace,
            icon: BusyMarkGlyphs.folder,
            onPressed: () => Navigator.pop(
              context,
              _RemoteImagesPromptAction.allowWorkspace,
            ),
          ),
        BusyMarkDialogButton(
          label: context.l10n.alwaysLoadRemoteImages,
          icon: BusyMarkGlyphs.image,
          suggested: true,
          onPressed: () =>
              Navigator.pop(context, _RemoteImagesPromptAction.allowAlways),
        ),
      ],
      children: [Text(context.l10n.remoteImagesBlockedMessage)],
    ),
  );
  if (action == _RemoteImagesPromptAction.allowWorkspace &&
      workspacePath != null) {
    await ref
        .read(appSettingsControllerProvider.notifier)
        .allowRemoteImagesForWorkspace(workspacePath);
    return;
  }
  if (action == _RemoteImagesPromptAction.allowAlways) {
    await ref
        .read(appSettingsControllerProvider.notifier)
        .setAllowRemoteImages(true);
  }
}

String? _remoteImageWorkspacePath(Workspace? workspace) {
  if (workspace == null) {
    return null;
  }
  final root = workspace.rootPath.trim();
  if (root.isNotEmpty) {
    return root;
  }
  final fallback = workspace.activeFilePath ?? workspace.markdown?.filePath;
  final trimmed = fallback?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

String _decodePreviewAnchor(String value) {
  try {
    return Uri.decodeComponent(value);
  } on FormatException {
    return value;
  }
}

class _ProblemsList extends StatelessWidget {
  const _ProblemsList({required this.workspace});

  final Workspace workspace;

  @override
  Widget build(BuildContext context) {
    final diagnostics = workspace.diagnostics;
    return BusyMarkGroupedSurface(
      child: diagnostics.isEmpty
          ? _EmptyPane(
              icon: BusyMarkGlyphs.check,
              title: context.l10n.noProblemsFound,
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: BusyMarkSpacing.xs),
              itemCount: diagnostics.length,
              itemBuilder: (context, index) {
                return _DiagnosticRow(diagnostic: diagnostics[index]);
              },
            ),
    );
  }
}

class _SearchSidebar extends StatelessWidget {
  const _SearchSidebar({
    required this.query,
    required this.results,
    required this.searching,
    required this.onOpenResult,
  });

  final String query;
  final List<_WorkspaceSearchResult> results;
  final bool searching;
  final Future<void> Function(_WorkspaceSearchResult result) onOpenResult;

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      return _SidebarEmptyState(
        icon: BusyMarkGlyphs.search,
        title: context.l10n.search,
      );
    }
    if (searching && results.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          key: ValueKey('workspace-search-progress'),
        ),
      );
    }
    final colors = BusyMarkSurfaceColors.of(context);
    if (results.isEmpty) {
      return _SidebarEmptyState(
        icon: BusyMarkGlyphs.searchUnavailable,
        title: context.l10n.noResults,
      );
    }
    final groups = _workspaceSearchFileGroups(results);
    return ListView(
      padding: BusyMarkInsets.sidebarList,
      children: [
        for (final group in groups) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              BusyMarkSpacing.sm,
              BusyMarkSpacing.sm,
              BusyMarkSpacing.sm,
              BusyMarkSpacing.xxs,
            ),
            child: Text(
              busyMarkLtrIsolateFor(context, group.relativePath),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.mutedForeground,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
          for (final result in group.results) ...[
            _SearchResultRow(
              result: result,
              onOpen: () => onOpenResult(result),
            ),
            Divider(
              height: BusyMarkStroke.hairline,
              color: colors.subtleBorder,
            ),
          ],
        ],
      ],
    );
  }
}

class _SearchResultRow extends StatelessWidget {
  const _SearchResultRow({required this.result, required this.onOpen});

  final _WorkspaceSearchResult result;
  final Future<void> Function() onOpen;

  @override
  Widget build(BuildContext context) {
    return _SidebarNavigationResultRow(
      title: result.title,
      subtitle: result.subtitle,
      icon: result.icon,
      onOpen: onOpen,
    );
  }
}

class _SidebarNavigationResultRow extends StatelessWidget {
  const _SidebarNavigationResultRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onOpen,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Future<void> Function() onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return Material(
      color: BusyMarkLinuxPalette.transparent,
      child: InkWell(
        hoverColor: busyMarkRowHoverColor(context),
        onTap: () => unawaited(onOpen()),
        child: Padding(
          padding: BusyMarkInsets.searchResultRow,
          child: Row(
            children: [
              Icon(
                icon,
                size: BusyMarkSizes.iconMd,
                color: colors.mutedForeground,
              ),
              const SizedBox(width: BusyMarkSpacing.md),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: BusyMarkSpacing.xxs),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: BusyMarkSpacing.md),
              Icon(
                BusyMarkGlyphs.forwardFor(Directionality.of(context)),
                size: BusyMarkSizes.iconSm,
                color: colors.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkspaceSearchResult {
  const _WorkspaceSearchResult({
    required this.filePath,
    required this.relativePath,
    required this.line,
    required this.startOffset,
    required this.endOffset,
    required this.query,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String filePath;
  final String relativePath;
  final int line;
  final int startOffset;
  final int endOffset;
  final String query;
  final String title;
  final String subtitle;
  final IconData icon;
}

enum _WorkspaceSearchMatchKind { text, fileName }

class _WorkspaceSearchMatch {
  const _WorkspaceSearchMatch({
    required this.kind,
    required this.filePath,
    required this.relativePath,
    required this.fileKind,
    required this.line,
    required this.startOffset,
    required this.endOffset,
    required this.query,
    this.lineText,
  });

  final _WorkspaceSearchMatchKind kind;
  final String filePath;
  final String relativePath;
  final DocumentKind fileKind;
  final int line;
  final int startOffset;
  final int endOffset;
  final String query;
  final String? lineText;
}

class _WorkspaceSearchFileGroup {
  const _WorkspaceSearchFileGroup({
    required this.relativePath,
    required this.results,
  });

  final String relativePath;
  final List<_WorkspaceSearchResult> results;
}

List<_WorkspaceSearchFileGroup> _workspaceSearchFileGroups(
  List<_WorkspaceSearchResult> results,
) {
  final groups = <String, List<_WorkspaceSearchResult>>{};
  for (final result in results) {
    groups.putIfAbsent(result.relativePath, () => []).add(result);
  }
  return [
    for (final entry in groups.entries)
      _WorkspaceSearchFileGroup(
        relativePath: entry.key,
        results: List.unmodifiable(entry.value),
      ),
  ];
}

List<_WorkspaceSearchResult> _workspaceSearchResults(
  BuildContext context,
  List<_WorkspaceSearchMatch> matches,
) {
  return [
    for (final match in matches)
      _WorkspaceSearchResult(
        filePath: match.filePath,
        relativePath: match.relativePath,
        line: match.line,
        startOffset: match.startOffset,
        endOffset: match.endOffset,
        query: match.query,
        title: switch (match.kind) {
          _WorkspaceSearchMatchKind.text => _searchResultTitle(
            context,
            match.lineText ?? '',
          ),
          _WorkspaceSearchMatchKind.fileName => busyMarkLtrIsolateFor(
            context,
            match.relativePath,
          ),
        },
        subtitle: switch (match.kind) {
          _WorkspaceSearchMatchKind.text => context.l10n.searchResultLine(
            match.relativePath,
            match.line,
          ),
          _WorkspaceSearchMatchKind.fileName => _documentKindLabel(
            context,
            match.fileKind,
          ),
        },
        icon: switch (match.kind) {
          _WorkspaceSearchMatchKind.text => BusyMarkGlyphs.paragraph,
          _WorkspaceSearchMatchKind.fileName => _documentKindIcon(
            match.fileKind,
          ),
        },
      ),
  ];
}

const int _maxWorkspaceSearchResults = 80;
const int _maxWorkspaceSearchFileBytes = 1024 * 1024;

Future<List<_WorkspaceSearchMatch>> _loadWorkspaceSearchMatches(
  WorkspaceState state,
  SourceSearchOptions options, {
  required Future<String> Function(String path) loadText,
  required bool Function() isCancelled,
}) async {
  final workspace = state.workspace;
  final trimmedQuery = options.query.trim();
  if (workspace == null || trimmedQuery.isEmpty || isCancelled()) {
    return const [];
  }
  final normalizedOptions = options.copyWith(query: trimmedQuery);
  final results = <_WorkspaceSearchMatch>[];
  final activePath = workspace.activeFilePath ?? workspace.markdown?.filePath;
  final sortedFiles = [...workspace.files]
    ..sort((a, b) => a.relativePath.compareTo(b.relativePath));
  if (activePath != null &&
      sortedFiles.every((file) => file.absolutePath != activePath)) {
    _addWorkspaceSearchTextMatches(
      file: DocumentFile(
        absolutePath: activePath,
        relativePath: p.basename(activePath),
        kind: DocumentKind.markdown,
        size: state.activeText.length,
        lastModified: DateTime.fromMillisecondsSinceEpoch(0),
      ),
      text: state.activeText,
      options: normalizedOptions,
      results: results,
    );
    if (results.length >= _maxWorkspaceSearchResults) {
      return List.unmodifiable(results);
    }
  }
  for (final file in sortedFiles) {
    if (isCancelled()) {
      return const [];
    }
    if (!_isOpenableTextDocument(file)) {
      continue;
    }
    final String? text;
    if (file.absolutePath == activePath) {
      text = state.activeText;
    } else if (file.size > _maxWorkspaceSearchFileBytes) {
      text = null;
    } else {
      String? loadedText;
      try {
        loadedText = await loadText(file.absolutePath);
      } on Object {
        // Keep filename matching available when a document cannot be read.
      }
      if (isCancelled()) {
        return const [];
      }
      text = loadedText;
    }
    if (text != null) {
      _addWorkspaceSearchTextMatches(
        file: file,
        text: text,
        options: normalizedOptions,
        results: results,
      );
      if (results.length >= _maxWorkspaceSearchResults) {
        return List.unmodifiable(results);
      }
    }
    if (!_fileNameMatchesSearch(file.relativePath, normalizedOptions)) {
      continue;
    }
    results.add(
      _WorkspaceSearchMatch(
        kind: _WorkspaceSearchMatchKind.fileName,
        filePath: file.absolutePath,
        relativePath: file.relativePath,
        fileKind: file.kind,
        line: 1,
        startOffset: 0,
        endOffset: 0,
        query: trimmedQuery,
      ),
    );
    if (results.length >= _maxWorkspaceSearchResults) {
      return List.unmodifiable(results);
    }
  }
  return List.unmodifiable(results);
}

void _addWorkspaceSearchTextMatches({
  required DocumentFile file,
  required String text,
  required SourceSearchOptions options,
  required List<_WorkspaceSearchMatch> results,
}) {
  final document = SourceDocument(fullText: text);
  final searchResult = searchSourceDocument(document, options);
  for (final match in searchResult.matches) {
    final lineNumber = document.lineIndex.lineNumberAtOffset(match.fullStart);
    final line = document.lineIndex.lineAt(lineNumber).text;
    results.add(
      _WorkspaceSearchMatch(
        kind: _WorkspaceSearchMatchKind.text,
        filePath: file.absolutePath,
        relativePath: file.relativePath,
        fileKind: file.kind,
        line: lineNumber,
        startOffset: match.fullStart,
        endOffset: match.fullEnd,
        query: options.query,
        lineText: line,
      ),
    );
    if (results.length >= _maxWorkspaceSearchResults) {
      return;
    }
  }
}

bool _fileNameMatchesSearch(String relativePath, SourceSearchOptions options) {
  if (options.regex || options.wholeWord) {
    return false;
  }
  final haystack = options.caseSensitive
      ? relativePath
      : relativePath.toLowerCase();
  final needle = options.caseSensitive
      ? options.query
      : options.query.toLowerCase();
  return haystack.contains(needle);
}

String _searchResultTitle(BuildContext context, String line) {
  final trimmed = _stripMarkdownForSearchResult(line, context: context);
  if (trimmed.length <= 120) {
    return trimmed;
  }
  return '${trimmed.substring(0, 117)}...';
}

String _stripMarkdownForSearchResult(String line, {BuildContext? context}) {
  var value = line.trim();
  final fence = RegExp(
    r'^(```+|~~~+)\s*([A-Za-z0-9_+\-#.]*)',
  ).firstMatch(value);
  if (fence != null) {
    final language = fence.group(2)?.trim() ?? '';
    return language.isEmpty
        ? context?.l10n.codeBlock ?? 'code block'
        : language;
  }

  value = value
      .replaceFirst(RegExp(r'^\s{0,3}#{1,6}\s+'), '')
      .replaceFirst(RegExp(r'^\s{0,3}>\s?'), '')
      .replaceFirst(RegExp(r'^\s{0,3}[-+*]\s+\[[ xX]\]\s+'), '')
      .replaceFirst(RegExp(r'^\s{0,3}[-+*]\s+'), '')
      .replaceFirst(RegExp(r'^\s{0,3}\d+[.)]\s+'), '')
      .trim();
  final replacements = <RegExp, String Function(Match)>{
    RegExp(r'!\[([^\]]*)\]\([^)]+\)'): (match) => match.group(1) ?? '',
    RegExp(r'\[([^\]]+)\]\([^)]+\)'): (match) => match.group(1) ?? '',
    RegExp(r'\[([^\]]+)\]\[[^\]]*\]'): (match) => match.group(1) ?? '',
    RegExp(r'`([^`]*)`'): (match) => match.group(1) ?? '',
    RegExp(r'\*\*([^*]+)\*\*'): (match) => match.group(1) ?? '',
    RegExp(r'__([^_]+)__'): (match) => match.group(1) ?? '',
    RegExp(r'\*([^*]+)\*'): (match) => match.group(1) ?? '',
    RegExp(r'_([^_]+)_'): (match) => match.group(1) ?? '',
    RegExp(r'~~([^~]+)~~'): (match) => match.group(1) ?? '',
    RegExp(r'<[^>]+>'): (_) => '',
  };
  for (final entry in replacements.entries) {
    value = value.replaceAllMapped(entry.key, entry.value);
  }
  value = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  return value.isEmpty
      ? context?.l10n.untitledResult ?? 'untitled result'
      : value;
}

String _relativeDocumentPath(Workspace workspace, String path) {
  for (final file in workspace.files) {
    if (file.absolutePath == path) {
      return file.relativePath;
    }
  }
  return _fileNameFromPath(path);
}

String _fileNameFromPath(String path) {
  final normalized = path.replaceAll('\\', '/');
  final separator = normalized.lastIndexOf('/');
  if (separator == -1) {
    return normalized;
  }
  return normalized.substring(separator + 1);
}

IconData _documentKindIcon(DocumentKind kind) {
  return switch (kind) {
    DocumentKind.markdown ||
    DocumentKind.writersideMarkdownTopic => YaruIcons.text_editor,
    DocumentKind.writersideXmlTopic => YaruIcons.document,
    DocumentKind.tree => BusyMarkGlyphs.tree,
    DocumentKind.config => YaruIcons.gear,
    DocumentKind.variables => BusyMarkGlyphs.symbols,
    DocumentKind.categories => BusyMarkGlyphs.category,
    DocumentKind.image => BusyMarkGlyphs.image,
    DocumentKind.resource || DocumentKind.unknown => YaruIcons.document,
  };
}

String _documentKindLabel(BuildContext context, DocumentKind kind) {
  return switch (kind) {
    DocumentKind.markdown => context.l10n.documentKindMarkdownFile,
    DocumentKind.writersideMarkdownTopic =>
      context.l10n.documentKindWritersideMarkdownTopic,
    DocumentKind.writersideXmlTopic =>
      context.l10n.documentKindWritersideXmlTopic,
    DocumentKind.tree => context.l10n.documentKindWritersideTree,
    DocumentKind.config => context.l10n.documentKindConfigurationFile,
    DocumentKind.variables => context.l10n.documentKindVariablesFile,
    DocumentKind.categories => context.l10n.documentKindCategoriesFile,
    DocumentKind.image => context.l10n.image,
    DocumentKind.resource => context.l10n.documentKindResourceFile,
    DocumentKind.unknown => context.l10n.file,
  };
}

class _DiagnosticRow extends ConsumerWidget {
  const _DiagnosticRow({required this.diagnostic});

  final Diagnostic diagnostic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = BusyMarkSurfaceColors.of(context);
    return Material(
      color: BusyMarkLinuxPalette.transparent,
      child: InkWell(
        hoverColor: busyMarkRowHoverColor(context),
        onTap: () async {
          if (await saveOrConfirmSafeToChangeActiveFile(context, ref)) {
            await ref
                .read(workspaceControllerProvider.notifier)
                .openActiveFile(diagnostic.filePath);
            final line = diagnostic.line;
            if (line != null) {
              ref
                  .read(_sourceNavigationTargetProvider.notifier)
                  .set(
                    _SourceNavigationTarget(
                      filePath: diagnostic.filePath,
                      line: line,
                    ),
                  );
            }
            _clearGitDetailSelection(ref);
          }
        },
        child: Padding(
          padding: BusyMarkInsets.searchResultRow,
          child: Row(
            children: [
              Icon(
                _diagnosticIconForSeverity(diagnostic.severity),
                size: BusyMarkSizes.iconMd,
                color: _diagnosticColorForSeverity(
                  context,
                  diagnostic.severity,
                ),
              ),
              const SizedBox(width: BusyMarkSpacing.md),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizeDiagnostic(context, diagnostic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: BusyMarkSpacing.xxs),
                    Text(
                      '${diagnostic.code} - ${diagnostic.filePath.split('/').last}'
                      '${diagnostic.line == null ? '' : ' ${diagnostic.line}:${diagnostic.column}'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.ltr,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.mutedForeground,
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
}

DocumentKind? _activeWorkspaceDocumentKind(Workspace workspace) {
  final activePath = workspace.activeFilePath ?? workspace.markdown?.filePath;
  if (activePath == null) {
    return null;
  }
  for (final file in workspace.files) {
    if (file.absolutePath == activePath) {
      return file.kind;
    }
  }
  return workspace.kind == WorkspaceKind.untitledMarkdown ||
          workspace.kind == WorkspaceKind.singleMarkdown
      ? DocumentKind.markdown
      : null;
}

IconData _diagnosticIconForSeverity(DiagnosticSeverity severity) {
  return switch (severity) {
    DiagnosticSeverity.error => BusyMarkGlyphs.error,
    DiagnosticSeverity.warning => BusyMarkGlyphs.warning,
    DiagnosticSeverity.info => BusyMarkGlyphs.info,
    DiagnosticSeverity.hint => BusyMarkGlyphs.tip,
  };
}

Color _diagnosticColorForSeverity(
  BuildContext context,
  DiagnosticSeverity severity,
) {
  return switch (severity) {
    DiagnosticSeverity.error => busyMarkStatusColor(
      context,
      BusyMarkStatusKind.error,
    ),
    DiagnosticSeverity.warning => busyMarkStatusColor(
      context,
      BusyMarkStatusKind.warning,
    ),
    DiagnosticSeverity.info => busyMarkStatusColor(
      context,
      BusyMarkStatusKind.information,
    ),
    DiagnosticSeverity.hint => BusyMarkSurfaceColors.of(context).muted,
  };
}

class _EmptyPane extends StatelessWidget {
  const _EmptyPane({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colors.mutedForeground),
          const SizedBox(height: BusyMarkSpacing.sm),
          Text(title, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
