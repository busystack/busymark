import 'package:flutter/foundation.dart';
import '../app/command_presentation.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../app/app_router.dart';
import '../app/app_settings.dart';
import '../app/busymark_design.dart';
import '../app/command_registry.dart';
import '../app/quick_open.dart';
import '../editor/source/source_document.dart';
import '../editor/source/source_search.dart';
import '../local_history/local_history_controller.dart';
import '../local_history/local_history_models.dart';
import '../markdown/document_outline.dart';
import '../workspace/outline_navigation.dart';
import '../nextcloud_notes/application/nextcloud_connection.dart';
import '../nextcloud_notes/application/notes_navigation.dart';
import '../nextcloud_notes/application/notes_search_controller.dart';
import '../nextcloud_notes/domain/notes_search.dart';
import '../workspace/document_buffer.dart';
import '../workspace/workspace_controller.dart';
import '../workspace/workspace_model.dart';
import 'workspace_search_scope.dart';
import 'workspace_text_search.dart';

enum SearchCategory {
  file,
  workspace,
  outline,
  documents,
  topics,
  recent,
  localHistory,
  actions,
}

const searchCommandDestinations = <String, SearchCategory>{
  BusyMarkCommandIds.search: SearchCategory.file,
  BusyMarkCommandIds.searchWorkspace: SearchCategory.workspace,
  BusyMarkCommandIds.searchHeadings: SearchCategory.outline,
  BusyMarkCommandIds.quickOpen: SearchCategory.documents,
  BusyMarkCommandIds.searchTopics: SearchCategory.topics,
  BusyMarkCommandIds.searchRecent: SearchCategory.recent,
  BusyMarkCommandIds.findLocalHistory: SearchCategory.localHistory,
  BusyMarkCommandIds.commandPalette: SearchCategory.actions,
};

String searchCommandForCategory(SearchCategory category) =>
    searchCommandDestinations.entries
        .singleWhere((e) => e.value == category)
        .key;

/// A result is qualified by its owning workspace/account, never a synthetic path.
sealed class SidebarSearchResult {
  const SidebarSearchResult();
  String get identity;
}

final class TextSearchResult extends SidebarSearchResult {
  const TextSearchResult(this.workspaceId, this.match);
  final String workspaceId;
  final WorkspaceTextMatch match;
  @override
  String get identity =>
      '$workspaceId:${match.bufferId ?? match.filePath}:${match.startOffset}:${match.endOffset}';
}

final class NoteSearchResult extends SidebarSearchResult {
  const NoteSearchResult(this.accountId, this.hit, this.recovery);
  final String accountId;
  final NotesSearchHit hit;
  final bool recovery;
  @override
  String get identity => '$accountId:${hit.localId}:${hit.start}:${hit.end}';
}

final class OutlineSearchResult extends SidebarSearchResult {
  const OutlineSearchResult(
    this.workspaceId,
    this.bufferId,
    this.revision,
    this.digest,
    this.heading,
    this.ancestors,
    this.documentName,
  );
  final String workspaceId, bufferId, digest, documentName;
  final int revision;
  final DocumentOutlineHeading heading;
  final List<String> ancestors;
  @override
  String get identity =>
      '$workspaceId:$bufferId:${heading.id}:${heading.editorBlockId}:${heading.sourceStartOffset}:${heading.sourceStartLine}';
}

final class DocumentSearchResult extends SidebarSearchResult {
  const DocumentSearchResult(this.workspaceId, this.document, {this.accountId});
  final String workspaceId;
  final String? accountId;
  final QuickOpenDocument document;
  @override
  String get identity => '$workspaceId:${document.identity}';
}

final class TopicSearchResult extends SidebarSearchResult {
  const TopicSearchResult(
    this.workspaceId,
    this.path,
    this.title,
    this.topicId,
    this.module,
    this.relativePath,
  );
  final String workspaceId, path, title, topicId, module, relativePath;
  @override
  String get identity => '$workspaceId:$path';
}

final class RecentSearchResult extends SidebarSearchResult {
  const RecentSearchResult(this.resource);
  final RecentResource resource;
  @override
  String get identity => resource.identity;
}

final class HistorySearchResult extends SidebarSearchResult {
  const HistorySearchResult(this.match);
  final LocalHistorySearchMatch match;
  @override
  String get identity => match.identity;
}

/// Metadata is localized at the presentation boundary; commands remain in the registry.
final class ActionSearchResult extends SidebarSearchResult {
  const ActionSearchResult(
    this.command,
    this.title,
    this.category,
    this.description, {
    this.enabled = true,
    this.disabledReason,
  });
  final BusyMarkCommand command;
  final String title, category;
  final String? description, disabledReason;
  final bool enabled;
  @override
  String get identity => command.id;
}

/// Identities carried with every generation, independently of retained buffers.
class SearchSessionContext {
  const SearchSessionContext(
    this.route,
    this.workspaceId,
    this.bufferId,
    this.revision,
    this.accountId,
  );
  final String route;
  final String? workspaceId, bufferId, accountId;
  final int? revision;
}

class SearchSessionState {
  const SearchSessionState({
    this.active = false,
    this.context,
    this.category = SearchCategory.file,
    this.recovery = false,
    this.historyDocumentId,
    this.query = '',
    this.results = const [],
    this.selected = 0,
    this.searching = false,
    this.indexing = false,
    this.truncated = false,
    this.skippedFiles = const [],
    this.error,
    this.focusRequest = 0,
    this.generation = 0,
    this.requestRevision = 0,
    this.documentMatchCount = 0,
    this.documentFirstMatchIndex = 0,
    this.documentCurrentMatchIndex,
    this.sourceNavigationRequest = 0,
    this.appliedSourceNavigation = 0,
  });
  final bool active;
  final SearchSessionContext? context;
  final SearchCategory category;
  final bool recovery;
  final String? historyDocumentId;
  final String query;
  final List<SidebarSearchResult> results;
  final int selected, focusRequest, generation;
  final int requestRevision;
  final int documentMatchCount, documentFirstMatchIndex;
  final int? documentCurrentMatchIndex;
  final int sourceNavigationRequest, appliedSourceNavigation;
  final bool searching, indexing, truncated;
  final List<String> skippedFiles;
  final String? error;

  /// Text queries preserve literal whitespace; name queries use their existing
  /// normalization. This is the single gate for every request entry point.
  bool get queryIsEmpty => switch (category) {
    SearchCategory.file => query.isEmpty,
    SearchCategory.workspace =>
      context?.accountId == null ? query.isEmpty : query.trim().isEmpty,
    _ => query.trim().isEmpty,
  };
  bool get showingInitialList =>
      queryIsEmpty && category == SearchCategory.actions;
  bool get waitingForInput => queryIsEmpty && !showingInitialList;
  bool get fileActive => active && category == SearchCategory.file;
  bool get workspaceActive => active && category == SearchCategory.workspace;
  bool get textActive => fileActive || workspaceActive;
  SourceSearchSnapshot sourceSnapshot(DocumentBuffer? buffer) {
    final ranges = <(int, int)>[];
    if (textActive &&
        !waitingForInput &&
        results.isNotEmpty &&
        buffer != null &&
        (workspaceActive ||
            context?.bufferId == buffer.id &&
                context?.revision == buffer.revision)) {
      final remote = buffer.remoteNote;
      final digest = notesSearchDigest(buffer.text);
      for (final result in results) {
        if (result is TextSearchResult &&
            result.match.digest == digest &&
            result.match.startOffset >= 0 &&
            result.match.endOffset <= buffer.text.length &&
            (result.match.bufferId == buffer.id ||
                buffer.filePath != null &&
                    result.match.filePath == buffer.filePath)) {
          ranges.add((result.match.startOffset, result.match.endOffset));
        } else if (result is NoteSearchResult &&
            remote != null &&
            result.accountId == remote.accountId &&
            result.hit.localId == remote.localId &&
            result.hit.digest == digest &&
            result.hit.start != null &&
            result.hit.end != null) {
          ranges.add((result.hit.start!, result.hit.end!));
        }
      }
    }
    return SourceSearchSnapshot(
      source: buffer?.text ?? '',
      truncated: category != SearchCategory.file && truncated,
      searching: searching,
      navigationRequest: sourceNavigationRequest,
      appliedNavigation: appliedSourceNavigation,
      sourceRevision: buffer?.revision,
      sessionRevision: requestRevision,
      result: SourceSearchResult(
        options: options,
        totalMatchCount: category == SearchCategory.file
            ? documentMatchCount
            : null,
        firstMatchIndex: category == SearchCategory.file
            ? documentFirstMatchIndex
            : 0,
        currentMatchIndex: category == SearchCategory.file
            ? documentCurrentMatchIndex
            : null,
        matches: [
          for (final (start, end) in ranges)
            SourceSearchMatch(
              fullStart: start,
              fullEnd: end,
              visibleStart: start,
              visibleEnd: end,
              hidden: false,
            ),
        ],
      ),
    );
  }

  SourceSearchOptions get options =>
      SourceSearchOptions(query: textActive ? query : '');
  SearchSessionState copyWith({
    bool? active,
    SearchSessionContext? context,
    SearchCategory? category,
    bool? recovery,
    String? historyDocumentId,
    bool clearHistoryScope = false,
    String? query,
    List<SidebarSearchResult>? results,
    int? selected,
    bool? searching,
    bool? indexing,
    bool? truncated,
    List<String>? skippedFiles,
    String? error,
    int? focusRequest,
    int? generation,
    int? requestRevision,
    int? documentMatchCount,
    int? documentFirstMatchIndex,
    int? documentCurrentMatchIndex,
    bool clearDocumentSelection = false,
    int? sourceNavigationRequest,
    int? appliedSourceNavigation,
  }) => SearchSessionState(
    active: active ?? this.active,
    context: context ?? this.context,
    category: category ?? this.category,
    recovery: recovery ?? this.recovery,
    historyDocumentId: clearHistoryScope
        ? null
        : historyDocumentId ?? this.historyDocumentId,
    query: query ?? this.query,
    results: results ?? this.results,
    selected: selected ?? this.selected,
    searching: searching ?? this.searching,
    indexing: indexing ?? this.indexing,
    truncated: truncated ?? this.truncated,
    skippedFiles: skippedFiles ?? this.skippedFiles,
    error: error,
    focusRequest: focusRequest ?? this.focusRequest,
    generation: generation ?? this.generation,
    requestRevision: requestRevision ?? this.requestRevision,
    documentMatchCount: documentMatchCount ?? this.documentMatchCount,
    documentFirstMatchIndex:
        documentFirstMatchIndex ?? this.documentFirstMatchIndex,
    documentCurrentMatchIndex: clearDocumentSelection
        ? null
        : documentCurrentMatchIndex ?? this.documentCurrentMatchIndex,
    sourceNavigationRequest:
        sourceNavigationRequest ?? this.sourceNavigationRequest,
    appliedSourceNavigation:
        appliedSourceNavigation ?? this.appliedSourceNavigation,
  );
}

final searchSessionProvider =
    NotifierProvider<SearchSessionController, SearchSessionState>(
      SearchSessionController.new,
    );

/// One window owns one bounded, ephemeral search session. No queries are persisted.
class SearchSessionController extends Notifier<SearchSessionState> {
  SearchSessionController({SourceSearchWorker? worker})
    : _worker = worker ?? SourceSearchWorker();
  int _originContextRevision = 0;
  final SourceSearchWorker _worker;
  Timer? _debounce;
  NotesSearchController? _notes;
  ProviderSubscription<LocalHistoryState>? _historyChanges;
  StreamSubscription<void>? _repositoryChanges;
  StreamSubscription<NotesSearchState>? _noteChanges;
  final _queries = <SearchCategory, SourceSearchOptions>{};
  SourceSearchOptions _recoveryOptions = const SourceSearchOptions();
  final _selectedIdentities = <SearchCategory, String>{};
  final _limits = <SearchCategory, int>{};
  String? _historyScope;
  List<ActionSearchResult> _commands = const [];
  int _request = 0, _limit = maxWorkspaceSearchResults;
  int _sourceWindowStart = 0, _sourceNavigationSerial = 0;
  int? _sourceCurrentIndex;
  _DocumentSearchNavigation? _sourceNavigation;
  bool _disposed = false, _hasOpened = false;
  FocusNode? _returnFocus;
  WeakReference<FocusNode>? _originFocus;
  String? _originWorkspace, _originBuffer;
  Future<void> _running = Future<void>.value();
  SearchCommandTarget? commandTarget;
  String? actionAccountId;

  bool get workspaceVisible =>
      ref.read(appRouterProvider).routeInformationProvider.value.uri.path ==
      '/workspace';
  List<SearchCategory> get categories {
    final route = ref
        .read(appRouterProvider)
        .routeInformationProvider
        .value
        .uri
        .path;
    if (route != '/' && route != '/workspace') return const [];
    final workspace = workspaceVisible
        ? ref.read(workspaceControllerProvider).workspace
        : null;
    final buffer = workspace == null
        ? null
        : ref.read(workspaceControllerProvider).activeBuffer;
    return [
      if (buffer != null) SearchCategory.file,
      if (workspace != null) SearchCategory.workspace,
      if (buffer != null) SearchCategory.outline,
      if (workspace != null) SearchCategory.documents,
      if (workspace?.writersideProject != null ||
          workspace?.writersideModule != null)
        SearchCategory.topics,
      SearchCategory.recent,
      if (workspace != null) SearchCategory.localHistory,
      SearchCategory.actions,
    ];
  }

  @override
  SearchSessionState build() {
    final router = ref.read(appRouterProvider);
    var route = router.routeInformationProvider.value.uri;
    void routeChanged() {
      final next = router.routeInformationProvider.value.uri;
      if (next == route) return;
      route = next;
      _originContextRevision++;
      close(restoreFocus: false);
      commandTarget = null;
      actionAccountId = null;
      _originFocus = null;
      _originWorkspace = null;
      _originBuffer = null;
    }

    router.routeInformationProvider.addListener(routeChanged);
    void focusChanged() {
      if (state.active || !workspaceVisible) return;
      final focus = FocusManager.instance.primaryFocus;
      final contextRevision = _originContextRevision;
      // Focus notifications can refer to an element being deactivated by a
      // rename, tab close or route change. Inspect ancestry after finalization.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!ref.mounted ||
            state.active ||
            !workspaceVisible ||
            contextRevision != _originContextRevision ||
            focus?.context?.mounted != true) {
          return;
        }
        if (_isOrigin(focus)) {
          _originFocus = WeakReference(focus!);
          final workspace = ref.read(workspaceControllerProvider);
          _originWorkspace = workspace.workspace?.id;
          _originBuffer =
              Actions.maybeFind<BusyMarkContextCommandIntent>(focus.context!) !=
                  null
              ? workspace.activeBufferId
              : null;
        }
      });
      WidgetsBinding.instance.scheduleFrame();
    }

    FocusManager.instance.addListener(focusChanged);
    ref.listen<WorkspaceState>(workspaceControllerProvider, (before, after) {
      if (before?.activeBuffer?.editorState.mode !=
          after.activeBuffer?.editorState.mode) {
        cancelSourceNavigation(state.sourceNavigationRequest);
      }
      if (before?.workspace?.id != after.workspace?.id ||
          before?.activeBufferId != after.activeBufferId) {
        _originContextRevision++;
      }
      if (before?.workspace?.id != after.workspace?.id) {
        commandTarget = null;
        _originFocus = null;
        _returnFocus = null;
        if (state.recovery && workspaceVisible && after.workspace != null) {
          open(
            category: after.activeBuffer == null
                ? SearchCategory.workspace
                : SearchCategory.file,
          );
          return;
        }
      }
      if (state.active && _searchInputsChanged(state.category, before, after)) {
        if (categories.isEmpty) {
          close(restoreFocus: false);
          return;
        }
        if (!categories.contains(state.category)) {
          open(category: categories.first);
        } else {
          _schedule();
        }
      }
    });
    ref.listen(appSettingsControllerProvider, (before, after) {
      if (state.active &&
          state.category == SearchCategory.recent &&
          !identical(before?.recentWorkspaces, after.recentWorkspaces)) {
        _schedule();
      }
    });
    ref.onDispose(() {
      _historyChanges?.close();
      _disposed = true;
      _request++;
      _debounce?.cancel();
      _worker.dispose();
      unawaited(_notes?.dispose());
      unawaited(_repositoryChanges?.cancel());
      unawaited(_noteChanges?.cancel());
      router.routeInformationProvider.removeListener(routeChanged);
      FocusManager.instance.removeListener(focusChanged);
      commandTarget = null;
      _returnFocus = null;
      actionAccountId = null;
    });
    return const SearchSessionState();
  }

  List<String> _commandCategories = const [];

  void configureCommands(
    List<ActionSearchResult> commands, {
    List<String> categoryOrder = const [],
  }) {
    final categoriesChanged = !listEquals(_commandCategories, categoryOrder);
    _commandCategories = categoryOrder;
    final changed =
        categoriesChanged ||
        commands.length != _commands.length ||
        commands.indexed.any((entry) {
          final (i, value) = entry;
          final old = _commands[i];
          return value.identity != old.identity ||
              value.enabled != old.enabled ||
              value.title != old.title ||
              value.category != old.category ||
              value.description != old.description ||
              value.disabledReason != old.disabledReason ||
              value.command.shortcut?.label != old.command.shortcut?.label;
        });
    _commands = commands;
    if (changed && state.active && state.category == SearchCategory.actions) {
      // Metadata arrives from the localized registry boundary during rendering.
      // Publish after the frame, without executing a handler or restarting work.
      final request = _request;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_current(request) && state.category == SearchCategory.actions) {
          _publishActions();
        }
      });
      WidgetsBinding.instance.scheduleFrame();
    }
  }

  void _publishActions() {
    if (state.results.isNotEmpty &&
        state.selected >= 0 &&
        state.selected < state.results.length) {
      _selectedIdentities[state.category] =
          state.results[state.selected].identity;
    }
    final query = state.query.trim();
    int? rank(ActionSearchResult c) => commandMatchRank(
      name: c.title,
      category: c.category,
      description: c.description,
      id: c.identity,
      query: query,
    );
    final categories = _commandCategories.isEmpty
        ? _commands.map((c) => c.category).toSet().toList()
        : _commandCategories;
    final results = _commands.where((c) => rank(c) != null).toList()
      ..sort((a, b) {
        if (query.isEmpty) {
          final group = categories
              .indexOf(a.category)
              .compareTo(categories.indexOf(b.category));
          if (group != 0) return group;
        } else {
          final relevance = rank(a)!.compareTo(rank(b)!);
          if (relevance != 0) return relevance;
        }
        if (a.enabled != b.enabled) return a.enabled ? -1 : 1;
        final name = a.title.compareTo(b.title);
        if (name != 0) return name;
        final category = a.category.compareTo(b.category);
        return category != 0 ? category : a.identity.compareTo(b.identity);
      });
    state = state.copyWith(
      results: List.unmodifiable(results),
      selected: _selectionFor(results),
      searching: false,
    );
  }

  bool _isOrigin(FocusNode? focus) {
    final context = focus?.context;
    return context != null &&
        (Actions.maybeFind<BusyMarkContextCommandIntent>(context) != null ||
            context.findAncestorWidgetOfExactType<BusyMarkSidebarSurface>() !=
                null ||
            context.findAncestorStateOfType<EditableTextState>() != null);
  }

  void captureOrigin() {
    if (state.active) return;
    var focus = FocusManager.instance.primaryFocus;
    final workspace = ref.read(workspaceControllerProvider);
    if (workspaceVisible &&
        !_isOrigin(focus) &&
        _originWorkspace == workspace.workspace?.id &&
        (_originBuffer == null || _originBuffer == workspace.activeBufferId) &&
        _originFocus?.target?.context?.mounted == true) {
      focus = _originFocus?.target;
    }
    _returnFocus = focus;
    actionAccountId = workspaceVisible
        ? workspace.workspace?.nextcloudAccountId
        : null;
    commandTarget = workspaceVisible
        ? SearchCommandTarget.capture(workspace, focus)
        : null;
  }

  void open({SearchCategory? category, bool recovery = false}) {
    final available = categories;
    if (available.isEmpty) return;
    final requested =
        category ??
        (_hasOpened && available.contains(state.category)
            ? state.category
            : available.contains(SearchCategory.file)
            ? SearchCategory.file
            : SearchCategory.recent);
    if (!available.contains(requested)) return;

    captureOrigin();
    _resetSourceNavigation();
    _remember();
    final isRecovery = requested == SearchCategory.workspace && recovery;
    final options = isRecovery
        ? _recoveryOptions
        : _queries[requested] ?? const SourceSearchOptions();
    _limit = _limits[requested] ?? maxWorkspaceSearchResults;
    _hasOpened = true;
    state = state.copyWith(
      active: true,
      category: requested,
      recovery: isRecovery,
      historyDocumentId: requested == SearchCategory.localHistory
          ? _historyScope
          : null,
      clearHistoryScope:
          requested != SearchCategory.localHistory || _historyScope == null,
      query: options.query,
      results: const [],
      selected: 0,
      focusRequest: state.focusRequest + 1,
      requestRevision: state.requestRevision + 1,
    );
    _schedule();
  }

  void _observeHistory() {
    _historyChanges ??= ref.listen(localHistoryControllerProvider, (
      before,
      after,
    ) {
      if (state.active &&
          state.category == SearchCategory.localHistory &&
          before?.searchRevision != after.searchRevision) {
        _schedule();
      }
    });
  }

  void openCategory(SearchCategory category) {
    if (category == SearchCategory.localHistory) {
      openHistory();
    } else {
      open(category: category);
    }
  }

  void openHistory({String? documentId}) {
    _historyScope = documentId;
    open(category: SearchCategory.localHistory);
  }

  void clearHistoryScope() {
    _historyScope = null;
    set(state.copyWith(clearHistoryScope: true));
  }

  void toggle() => state.active ? close() : open();
  void close({bool restoreFocus = true}) {
    if (!state.active) return;
    _historyChanges?.close();
    _historyChanges = null;
    _remember();
    _resetSourceNavigation();
    _cancel();
    state = state.copyWith(
      active: false,
      results: const [],
      searching: false,
      indexing: false,
      generation: _request,
      requestRevision: state.requestRevision + 1,
      documentMatchCount: 0,
      documentFirstMatchIndex: 0,
      clearDocumentSelection: true,
      sourceNavigationRequest: 0,
      appliedSourceNavigation: 0,
    );
    final target = _returnFocus;
    _returnFocus = null;
    commandTarget = null;
    actionAccountId = null;
    unawaited(_notes?.dispose());
    _notes = null;
    unawaited(_repositoryChanges?.cancel());
    _repositoryChanges = null;
    if (restoreFocus && !(rootNavigatorKey.currentState?.canPop() ?? false)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (target?.context?.mounted == true && target!.canRequestFocus) {
          target.requestFocus();
        }
      });
    }
  }

  void _remember() {
    final options = SourceSearchOptions(query: state.query);
    if (state.recovery) {
      _recoveryOptions = options;
    } else {
      _queries[state.category] = options;
    }
    _limits[state.category] = _limit;
    if (state.selected >= 0 && state.selected < state.results.length) {
      _selectedIdentities[state.category] =
          state.results[state.selected].identity;
    }
  }

  void set(SearchSessionState next) {
    if (next.query != state.query && next.category != SearchCategory.actions) {
      _selectedIdentities.remove(next.category);
    }
    _resetSourceNavigation();
    state = next.copyWith(
      results: const [],
      selected: 0,
      requestRevision: state.requestRevision + 1,
    );
    _limit = maxWorkspaceSearchResults;
    _remember();
    _schedule();
  }

  void query(String value) => set(state.copyWith(query: value));
  void select(int index) {
    if (state.results.isEmpty) return;
    state = state.copyWith(selected: index.clamp(0, state.results.length - 1));
    _selectedIdentities[state.category] =
        state.results[state.selected].identity;
  }

  void moveSelection(int delta) => select(state.selected + delta);

  void showMore() {
    if (!state.active || state.waitingForInput) return;
    _limit += maxWorkspaceSearchResults;
    if (state.textActive && state.category == SearchCategory.file) {
      _sourceWindowStart =
          ((_sourceCurrentIndex ?? _sourceWindowStart) ~/ _limit) * _limit;
    }
    _schedule();
  }

  void _resetSourceNavigation() {
    _sourceNavigation = null;
    _sourceCurrentIndex = null;
    _sourceWindowStart = 0;
  }

  /// Selects by full-document ordinal or post-edit source offset. Displayed
  /// rows remain a bounded window; scanning/counting stays in the same worker.
  int? navigateSource(SourceSearchNavigationRequest request) {
    final workspace = ref.read(workspaceControllerProvider);
    final buffer = workspace.activeBuffer;
    if (!state.textActive ||
        state.category != SearchCategory.file ||
        !workspaceVisible ||
        buffer == null ||
        (buffer.id != request.documentId &&
            buffer.filePath != request.documentId) ||
        buffer.text != request.source ||
        state.options != request.options ||
        request.matchIndex != null && request.matchIndex! < 0 ||
        request.minimumFullOffset != null &&
            (request.minimumFullOffset! < 0 ||
                request.minimumFullOffset! > buffer.text.length)) {
      return null;
    }
    final id = ++_sourceNavigationSerial;
    final index = request.matchIndex;
    final navigation = _DocumentSearchNavigation(
      id,
      request,
      workspace.workspace!.id,
      buffer.id,
      buffer.revision,
      buffer.editorState.mode,
      state.requestRevision,
    );
    if (!state.searching &&
        index != null &&
        index >= state.documentFirstMatchIndex &&
        index < state.documentFirstMatchIndex + state.results.length) {
      _sourceNavigation = request.reveal ? navigation : null;
      _sourceCurrentIndex = index;
      state = state.copyWith(
        documentCurrentMatchIndex: index,
        selected: index - state.documentFirstMatchIndex,
        sourceNavigationRequest: request.reveal ? id : 0,
        appliedSourceNavigation: request.reveal ? id : 0,
      );
      return id;
    }
    _sourceNavigation = navigation;
    if (index != null) _sourceWindowStart = (index ~/ _limit) * _limit;
    state = state.copyWith(sourceNavigationRequest: id);
    _schedule();
    return id;
  }

  void cancelSourceNavigation(int id) {
    if (id == 0 || state.sourceNavigationRequest != id) return;
    final searchingForTarget = _sourceNavigation != null;
    _sourceNavigation = null;
    _sourceCurrentIndex = null;
    state = state.copyWith(
      sourceNavigationRequest: 0,
      appliedSourceNavigation: 0,
      clearDocumentSelection: true,
    );
    if (searchingForTarget) _schedule();
  }

  bool _sourceNavigationIsCurrent(_DocumentSearchNavigation navigation) {
    final workspace = ref.read(workspaceControllerProvider);
    final buffer = workspace.activeBuffer;
    return state.textActive &&
        state.category == SearchCategory.file &&
        workspaceVisible &&
        workspace.workspace?.id == navigation.workspaceId &&
        buffer?.id == navigation.bufferId &&
        buffer?.revision == navigation.revision &&
        buffer?.editorState.mode == navigation.mode &&
        buffer?.text == navigation.request.source &&
        state.options == navigation.request.options &&
        state.requestRevision == navigation.requestRevision;
  }

  void refresh(WorkspaceState _) => _schedule();
  void _cancel() {
    _request++;
    _debounce?.cancel();
    _worker.cancel();
    _notes?.cancel();
    unawaited(_noteChanges?.cancel());
    _noteChanges = null;
  }

  void _schedule() {
    _cancel();
    final request = _request;
    final visible = workspaceVisible;
    final workspace = ref.read(workspaceControllerProvider);
    final navigation = _sourceNavigation;
    final validNavigation =
        navigation != null && _sourceNavigationIsCurrent(navigation);
    if (!validNavigation &&
        (navigation != null ||
            state.context?.bufferId != workspace.activeBufferId ||
            state.context?.revision != workspace.activeBuffer?.revision ||
            !state.textActive ||
            state.category != SearchCategory.file)) {
      _resetSourceNavigation();
    }
    state = state.copyWith(
      context: SearchSessionContext(
        ref.read(appRouterProvider).routeInformationProvider.value.uri.path,
        visible ? workspace.workspace?.id : null,
        visible ? workspace.activeBufferId : null,
        visible ? workspace.activeBuffer?.revision : null,
        visible ? workspace.workspace?.nextcloudAccountId : null,
      ),
      results: const [],
      selected: 0,
      searching: state.active,
      indexing: false,
      truncated: false,
      skippedFiles: const [],
      generation: request,
      documentMatchCount: 0,
      documentFirstMatchIndex: _sourceWindowStart,
      clearDocumentSelection: true,
      sourceNavigationRequest: validNavigation ? navigation.id : 0,
      appliedSourceNavigation: 0,
    );
    if (state.active &&
        state.category == SearchCategory.localHistory &&
        !state.waitingForInput) {
      _observeHistory();
    } else {
      _historyChanges?.close();
      _historyChanges = null;
    }
    if (!state.active || state.waitingForInput) {
      _selectedIdentities.remove(state.category);
      state = state.copyWith(searching: false);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 120), () {
      _debounce = null;
      _running = _run(request);
      unawaited(_running);
    });
  }

  Future<bool> submit() async {
    if (state.waitingForInput) return state.active && !state.searching;
    final generation = _request;
    if (_debounce?.isActive == true) {
      _debounce!.cancel();
      _debounce = null;
      _running = _run(generation);
    }
    await _running;
    return _current(generation) && !state.searching;
  }

  bool _current(int request) =>
      !_disposed && request == _request && state.active;
  Future<void> _run(int request) async {
    if (!_current(request) || state.waitingForInput) return;
    final snapshot = state;
    final workspaceState = ref.read(workspaceControllerProvider);
    final workspace = workspaceState.workspace;
    void publish(List<SidebarSearchResult> results, {bool truncated = false}) {
      if (_current(request)) {
        state = state.copyWith(
          results: List.unmodifiable(results),
          selected: _selectionFor(results),
          searching: false,
          truncated: truncated,
        );
      }
    }

    try {
      switch (snapshot.category) {
        case SearchCategory.file:
        case SearchCategory.workspace:
          if (workspace == null || !workspaceVisible) return;
          if (snapshot.category != SearchCategory.file && workspace.isRemote) {
            await _searchNotes(request, workspaceState, snapshot);
            return;
          }
          final options = snapshot.options;
          WorkspaceTextOutcome outcome;
          void publishText(
            WorkspaceTextOutcome outcome, {
            required bool searching,
          }) {
            if (!_current(request)) return;
            final results = [
              for (final match in outcome.matches)
                TextSearchResult(workspace.id, match),
            ];
            state = state.copyWith(
              results: List.unmodifiable(results),
              selected: _selectionFor(results),
              searching: searching,
              truncated: outcome.truncated,
              skippedFiles: outcome.skippedFiles,
            );
          }
          if (snapshot.category == SearchCategory.file) {
            await _searchDocument(request, workspaceState, snapshot);
            return;
          } else {
            outcome = await loadWorkspaceTextMatches(
              workspaceState,
              options,
              loadText: ref.read(workspaceServiceProvider).loadText,
              isCancelled: () => !_current(request),
              worker: _worker,
              maximumResults: _limit,
              onProgress: (outcome) => publishText(outcome, searching: true),
            );
          }
          if (!_current(request)) return;
          publishText(outcome, searching: false);
        case SearchCategory.outline:
          final buffer = workspaceState.activeBuffer;
          if (workspace == null || buffer == null || !workspaceVisible) return;
          final digest = notesSearchDigest(buffer.text);
          final matches = [
            for (final match in matchDocumentOutline(
              activeDocumentOutline(workspaceState),
              snapshot.query,
              maximumResults: _limit + 1,
            ))
              OutlineSearchResult(
                workspace.id,
                buffer.id,
                buffer.revision,
                digest,
                match.heading,
                List.unmodifiable(match.ancestors.map((h) => h.text)),
                buffer.displayName,
              ),
          ];
          publish(
            matches.take(_limit).toList(),
            truncated: matches.length > _limit,
          );
        case SearchCategory.documents:
          if (workspace == null || !workspaceVisible) return;
          final documents = <QuickOpenDocument>[];
          if (workspace.isRemote) {
            final repository = await ref.read(
              nextcloudNotesRepositoryProvider.future,
            );
            if (!_current(request)) return;
            documents.addAll(
              repository.notes
                  .where(
                    (n) =>
                        n.accountId == workspace.nextcloudAccountId &&
                        !isNotesRecovery(n) &&
                        !repository.isCreationCandidateBinding(n.localId),
                  )
                  .map(
                    (n) => QuickOpenDocument(
                      title: n.title,
                      path: n.category,
                      localId: n.localId,
                    ),
                  ),
            );
            _observeRepository(repository.changes);
          } else {
            documents.addAll(
              workspace.files
                  .where(isSearchableWorkspaceDocument)
                  .map(
                    (f) => QuickOpenDocument(
                      title: p.basenameWithoutExtension(f.relativePath),
                      path: f.relativePath,
                      filePath: f.absolutePath,
                    ),
                  ),
            );
          }
          final query = snapshot.query;
          final limit = _limit;
          final ranked = await rankQuickOpenAsync(
            documents,
            query,
            limit: limit + 1,
          );
          publish([
            for (final document in ranked.take(limit))
              DocumentSearchResult(
                workspace.id,
                document,
                accountId: workspace.nextcloudAccountId,
              ),
          ], truncated: ranked.length > limit);
        case SearchCategory.topics:
          if (workspace == null || !workspaceVisible) return;
          final query = normalizeNotesSearch(snapshot.query.trim());
          final seen = <String>{};
          final topics = <TopicSearchResult>[];
          final modules =
              workspace.writersideProject?.modules ??
              [
                if (workspace.writersideModule != null)
                  workspace.writersideModule!,
              ];
          for (final module in modules) {
            for (final topic in module.topics) {
              final path = p.normalize(topic.filePath);
              if (!seen.add(path)) continue;
              final title = topic.title ?? topic.id;
              final relative = p.relative(path, from: workspace.rootPath);
              if (!normalizeNotesSearch(
                '$title ${topic.id} ${topic.fileName} $relative',
              ).contains(query)) {
                continue;
              }
              topics.add(
                TopicSearchResult(
                  workspace.id,
                  path,
                  title,
                  topic.id,
                  module.config.moduleName ?? p.basename(module.rootPath),
                  relative,
                ),
              );
            }
          }
          topics.sort((a, b) {
            final title = a.title.compareTo(b.title);
            return title == 0 ? a.path.compareTo(b.path) : title;
          });
          publish(
            topics.take(_limit).toList(),
            truncated: topics.length > _limit,
          );
        case SearchCategory.recent:
          final query = normalizeNotesSearch(snapshot.query.trim());
          final history = ref
              .read(appSettingsControllerProvider)
              .recentWorkspaces;
          publish([
            for (final item in history)
              if (normalizeNotesSearch(
                '${item.title ?? ''} ${item.path} ${item.ownerRoot ?? ''} ${item.accountId ?? ''} ${item.accountLabel ?? ''}',
              ).contains(query))
                RecentSearchResult(item),
          ]);
        case SearchCategory.localHistory:
          final history = ref.read(localHistoryControllerProvider.notifier);
          void publishHistory(
            LocalHistorySearchPage page, {
            bool complete = false,
          }) {
            if (!_current(request)) return;
            final results = [
              for (final match in page.matches) HistorySearchResult(match),
            ];
            state = state.copyWith(
              results: results,
              selected: _selectionFor(results),
              searching: !complete,
              truncated: page.truncated,
            );
          }
          final page = await history.findRetained(
            query: snapshot.query,
            documentId: snapshot.historyDocumentId,
            maximumResults: _limit,
            isCancelled: () => !_current(request),
            onProgress: publishHistory,
          );
          if (page != null) publishHistory(page, complete: true);
        case SearchCategory.actions:
          if (_current(request)) _publishActions();
      }
    } on Object catch (error) {
      if (_current(request)) {
        state = state.copyWith(
          results: const [],
          searching: false,
          error: error.toString(),
        );
      }
    }
  }

  int _selectionFor(List<SidebarSearchResult> results) {
    final id = _selectedIdentities[state.category];
    final found = results.indexWhere((r) => r.identity == id);
    return found < 0 ? 0 : found;
  }

  void _observeRepository(Stream<void> changes) {
    _repositoryChanges ??= changes.listen((_) {
      if (state.active &&
          (state.category == SearchCategory.documents ||
              state.textActive && state.category != SearchCategory.file)) {
        _schedule();
      }
    });
  }

  Future<void> _searchDocument(
    int request,
    WorkspaceState workspace,
    SearchSessionState snapshot,
  ) async {
    final buffer = workspace.activeBuffer;
    if (buffer == null) {
      if (_current(request)) state = state.copyWith(searching: false);
      return;
    }
    final document = SourceDocument(fullText: buffer.text);
    final navigation = _sourceNavigation;
    var matches = await _worker.search(
      document,
      snapshot.options,
      firstMatchIndex: _sourceWindowStart,
      minimumFullOffset: navigation?.request.minimumFullOffset,
      maximumMatches: _limit,
    );
    if (!_current(request)) return;
    if (matches == null) {
      state = state.copyWith(
        searching: false,
        skippedFiles: [buffer.displayName],
      );
      return;
    }
    // An offset past the actual final occurrence wraps to the document's first
    // window, never to the first row in the previously displayed page.
    if (matches.matches.isEmpty && matches.totalMatchCount > 0) {
      matches = await _worker.search(
        document,
        snapshot.options,
        maximumMatches: _limit,
      );
      if (!_current(request) || matches == null) return;
    }
    if (navigation != null && !_sourceNavigationIsCurrent(navigation)) return;
    var selected = navigation?.request.minimumFullOffset != null
        ? matches.matches.isEmpty
              ? null
              : matches.firstMatchIndex
        : navigation?.request.matchIndex ?? _sourceCurrentIndex;
    if (selected != null &&
        (selected < matches.firstMatchIndex ||
            selected >= matches.firstMatchIndex + matches.matches.length)) {
      selected = null;
    }
    _sourceCurrentIndex = selected;
    _sourceWindowStart = matches.firstMatchIndex;
    // Retain the request until the editor acknowledges applying it. A derived
    // workspace refresh may otherwise erase a ready-but-not-yet-revealed match.
    _sourceNavigation = selected != null && navigation?.request.reveal == true
        ? navigation
        : null;
    final digest = notesSearchDigest(buffer.text);
    state = state.copyWith(
      documentMatchCount: matches.totalMatchCount,
      documentFirstMatchIndex: matches.firstMatchIndex,
      documentCurrentMatchIndex: selected,
      clearDocumentSelection: selected == null,
      selected: selected == null ? 0 : selected - matches.firstMatchIndex,
      sourceNavigationRequest: navigation?.id ?? 0,
      appliedSourceNavigation: navigation?.request.reveal == true
          ? navigation!.id
          : 0,
      searching: false,
      truncated: matches.totalMatchCount > matches.matches.length,
      results: [
        for (final match in matches.matches)
          TextSearchResult(
            workspace.workspace!.id,
            WorkspaceTextMatch(
              filePath: buffer.filePath,
              bufferId: buffer.id,
              digest: digest,
              relativePath: buffer.displayName,
              fileKind: resolveWorkspaceDocumentContext(
                workspace.workspace!,
                buffer,
              ).kind,
              line: document.lineIndex.lineNumberAtOffset(match.fullStart),
              startOffset: match.fullStart,
              endOffset: match.fullEnd,
              query: snapshot.query,
              lineText: boundedSearchSnippet(
                document.lineIndex
                    .lineAt(
                      document.lineIndex.lineNumberAtOffset(match.fullStart),
                    )
                    .text,
                matchStart:
                    match.fullStart -
                    document.lineIndex.offsetForLine(
                      document.lineIndex.lineNumberAtOffset(match.fullStart),
                    ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _searchNotes(
    int request,
    WorkspaceState workspace,
    SearchSessionState snapshot,
  ) async {
    final account = workspace.workspace!.nextcloudAccountId!;
    final repository = await ref.read(nextcloudNotesRepositoryProvider.future);
    if (!_current(request)) return;
    _observeRepository(repository.changes);
    await _notes?.dispose();
    if (!_current(request)) return;
    final controller = NotesSearchController(
      repository.store,
      account,
      recovery: snapshot.recovery,
    );
    _notes = controller;
    _noteChanges = controller.changes.listen((value) {
      if (!_current(request)) return;
      state = state.copyWith(
        results: [
          for (final hit in value.hits)
            NoteSearchResult(account, hit, snapshot.recovery),
        ],
        searching: value.loading,
        indexing: value.indexing,
        truncated: value.truncated,
        error: value.error?.toString(),
      );
    });
    await controller.search(
      snapshot.query,
      limit: _limit,
      overlays: [
        for (final buffer in workspace.documentBuffers)
          if (buffer.isDirty &&
              buffer.remoteNote?.accountId == account &&
              repository.noteById(buffer.remoteNote!.localId) != null)
            NotesSearchOverlay(
              buffer.remoteNote!.localId,
              buffer.revision,
              repository.noteById(buffer.remoteNote!.localId)!.title,
              repository.noteById(buffer.remoteNote!.localId)!.category,
              buffer.text,
            ),
      ],
    );
  }
}

class _DocumentSearchNavigation {
  const _DocumentSearchNavigation(
    this.id,
    this.request,
    this.workspaceId,
    this.bufferId,
    this.revision,
    this.mode,
    this.requestRevision,
  );
  final int id, revision, requestRevision;
  final SourceSearchNavigationRequest request;
  final String workspaceId, bufferId;
  final DocumentViewModePreference mode;
}

/// Context plus document identity, revision, view and selection are all required.
/// Losing the target never falls back to the current query field or another editor.
class SearchCommandTarget {
  SearchCommandTarget(
    this.workspaceId,
    this.bufferId,
    this.revision,
    this.editorState,
    this.focus,
    this.selectionSnapshot,
  );
  final String? workspaceId, bufferId;
  final int? revision;
  final DocumentEditorState? editorState;
  final FocusNode? focus;
  final BusyMarkContextCommandSnapshot? selectionSnapshot;
  BuildContext? get context =>
      focus?.context?.mounted == true ? focus!.context : null;
  static SearchCommandTarget capture(WorkspaceState state, FocusNode? focus) =>
      SearchCommandTarget(
        state.workspace?.id,
        state.activeBufferId,
        state.activeBuffer?.revision,
        state.activeBuffer?.editorState,
        focus,
        focus?.context == null
            ? null
            : (Actions.maybeFind<BusyMarkContextCommandIntent>(focus!.context!)
                      as BusyMarkContextCommandAction?)
                  ?.captureTarget
                  ?.call(),
      );
  bool isCurrent(WorkspaceState state) =>
      context != null &&
      workspaceId == state.workspace?.id &&
      bufferId == state.activeBufferId &&
      revision == state.activeBuffer?.revision &&
      editorState?.mode == state.activeBuffer?.editorState.mode &&
      (selectionSnapshot?.isCurrent ??
          (editorState?.selection ==
                  state.activeBuffer?.editorState.selection &&
              editorState?.wysiwygState.anchorBlockId ==
                  state.activeBuffer?.editorState.wysiwygState.anchorBlockId &&
              editorState?.wysiwygState.anchorOffset ==
                  state.activeBuffer?.editorState.wysiwygState.anchorOffset &&
              editorState?.wysiwygState.extentBlockId ==
                  state.activeBuffer?.editorState.wysiwygState.extentBlockId &&
              editorState?.wysiwygState.extentOffset ==
                  state.activeBuffer?.editorState.wysiwygState.extentOffset));
}

// Search dependencies differ from editor/navigation dependencies. In particular,
// a tab selection, inspector update, or derived outline refresh must not rescan
// every workspace file or retained historical revision.
bool _searchInputsChanged(
  SearchCategory category,
  WorkspaceState? before,
  WorkspaceState after,
) {
  if (before == null || before.workspace?.id != after.workspace?.id) {
    return true;
  }
  switch (category) {
    case SearchCategory.outline:
      if (!identical(before.liveOutline, after.liveOutline) ||
          !identical(before.preview, after.preview)) {
        return true;
      }
      continue document;
    document:
    case SearchCategory.file:
      final a = before.activeBuffer, b = after.activeBuffer;
      return a?.id != b?.id ||
          a?.revision != b?.revision ||
          a?.text != b?.text ||
          a?.filePath != b?.filePath ||
          a?.displayName != b?.displayName;
    case SearchCategory.workspace:
      if (after.workspace?.isRemote == true) {
        final account = after.workspace?.nextcloudAccountId;
        Map<String, (int, String)> overlays(WorkspaceState value) => {
          for (final buffer in value.documentBuffers)
            if (buffer.dirty && buffer.remoteNote?.accountId == account)
              buffer.id: (buffer.revision, buffer.text),
        };
        return !mapEquals(overlays(before), overlays(after));
      }
      Map<String, (String, DocumentKind, int, DateTime)> files(
        WorkspaceState value,
      ) => {
        for (final file in value.workspace?.files ?? const <DocumentFile>[])
          if (isSearchableWorkspaceDocument(file))
            file.absolutePath: (
              file.relativePath,
              file.kind,
              file.size,
              file.lastModified,
            ),
      };
      final a = files(before), b = files(after);
      if (!mapEquals(a, b)) return true;
      Map<String, (String, int, String)> overlays(WorkspaceState value) => {
        for (final buffer in value.documentBuffers)
          if (buffer.dirty && b.containsKey(buffer.filePath))
            buffer.filePath!: (buffer.id, buffer.revision, buffer.text),
      };
      return !mapEquals(overlays(before), overlays(after));
    case SearchCategory.documents:
      final a = before.workspace?.files ?? const <DocumentFile>[];
      final b = after.workspace?.files ?? const <DocumentFile>[];
      return !mapEquals(
        {for (final f in a) f.absolutePath: (f.relativePath, f.kind)},
        {for (final f in b) f.absolutePath: (f.relativePath, f.kind)},
      );
    case SearchCategory.topics:
      return !identical(
            before.workspace?.writersideProject,
            after.workspace?.writersideProject,
          ) ||
          !identical(
            before.workspace?.writersideModule,
            after.workspace?.writersideModule,
          );
    case SearchCategory.recent:
    case SearchCategory.localHistory:
    case SearchCategory.actions:
      return false;
  }
}

bool workspaceSearchInputsChanged(
  WorkspaceState? before,
  WorkspaceState after,
) {
  if (before == null ||
      before.workspace?.id != after.workspace?.id ||
      before.activeBufferId != after.activeBufferId ||
      before.activeText != after.activeText ||
      !identical(before.workspace, after.workspace)) {
    return true;
  }
  if (before.documentBuffers.length != after.documentBuffers.length) {
    return true;
  }
  for (var i = 0; i < after.documentBuffers.length; i++) {
    final a = before.documentBuffers[i], b = after.documentBuffers[i];
    if (a.id != b.id ||
        a.filePath != b.filePath ||
        a.revision != b.revision ||
        a.text != b.text) {
      return true;
    }
  }
  return false;
}
