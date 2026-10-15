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
import '../nextcloud_notes/application/nextcloud_connection.dart';
import '../nextcloud_notes/application/notes_navigation.dart';
import '../nextcloud_notes/application/notes_search_controller.dart';
import '../nextcloud_notes/domain/notes_search.dart';
import '../workspace/document_buffer.dart';
import '../workspace/workspace_controller.dart';
import '../workspace/workspace_model.dart';
import 'workspace_search_scope.dart';
import 'workspace_text_search.dart';

enum SearchCategory { text, outline, documents, topics, recent, actions }

enum SearchLocation { document, workspace, recovery }

const searchCommandDestinations = <String, (SearchCategory, SearchLocation?)>{
  BusyMarkCommandIds.search: (SearchCategory.text, SearchLocation.document),
  BusyMarkCommandIds.searchWorkspace: (
    SearchCategory.text,
    SearchLocation.workspace,
  ),
  BusyMarkCommandIds.sidebarOutline: (SearchCategory.outline, null),
  BusyMarkCommandIds.quickOpen: (SearchCategory.documents, null),
  BusyMarkCommandIds.searchTopics: (SearchCategory.topics, null),
  BusyMarkCommandIds.searchRecent: (SearchCategory.recent, null),
  BusyMarkCommandIds.commandPalette: (SearchCategory.actions, null),
};

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
  final RecentWorkspace resource;
  @override
  String get identity => resource.identity;
}

/// Metadata is localized at the presentation boundary; commands remain in the registry.
final class ActionSearchResult extends SidebarSearchResult {
  const ActionSearchResult(
    this.command,
    this.title,
    this.category,
    this.description,
  );
  final BusyMarkCommand command;
  final String title, category;
  final String? description;
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
    this.category = SearchCategory.text,
    this.location = SearchLocation.document,
    this.query = '',
    this.caseSensitive = false,
    this.wholeWord = false,
    this.regex = false,
    this.results = const [],
    this.selected = 0,
    this.searching = false,
    this.indexing = false,
    this.truncated = false,
    this.skippedFiles = const [],
    this.invalidRegex = false,
    this.hasZeroLengthMatches = false,
    this.error,
    this.focusRequest = 0,
    this.generation = 0,
    this.requestRevision = 0,
  });
  final bool active;
  final SearchSessionContext? context;
  final SearchCategory category;
  final SearchLocation location;
  final String query;
  final bool caseSensitive, wholeWord, regex;
  final List<SidebarSearchResult> results;
  final int selected, focusRequest, generation;
  final int requestRevision;
  final bool searching, indexing, truncated, invalidRegex, hasZeroLengthMatches;
  final List<String> skippedFiles;
  final String? error;
  bool get textActive => active && category == SearchCategory.text;
  SourceSearchSnapshot sourceSnapshot(DocumentBuffer? buffer) {
    final ranges = <(int, int)>[];
    if (textActive &&
        buffer != null &&
        context?.bufferId == buffer.id &&
        context?.revision == buffer.revision) {
      final remote = buffer.remoteNote;
      final digest = remote == null ? null : notesSearchDigest(buffer.text);
      for (final result in results) {
        if (result is TextSearchResult &&
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
      truncated: truncated,
      result: SourceSearchResult(
        options: options,
        invalidRegex: invalidRegex,
        hasZeroLengthMatches: hasZeroLengthMatches,
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

  SourceSearchOptions get options => SourceSearchOptions(
    query: textActive ? query : '',
    caseSensitive: caseSensitive,
    wholeWord: wholeWord,
    regex: regex,
  );
  SearchSessionState withOptions(SourceSearchOptions options) => copyWith(
    query: options.query,
    caseSensitive: options.caseSensitive,
    wholeWord: options.wholeWord,
    regex: options.regex,
  );
  SearchSessionState copyWith({
    bool? active,
    SearchSessionContext? context,
    SearchCategory? category,
    SearchLocation? location,
    String? query,
    bool? caseSensitive,
    bool? wholeWord,
    bool? regex,
    List<SidebarSearchResult>? results,
    int? selected,
    bool? searching,
    bool? indexing,
    bool? truncated,
    List<String>? skippedFiles,
    bool? invalidRegex,
    bool? hasZeroLengthMatches,
    String? error,
    int? focusRequest,
    int? generation,
    int? requestRevision,
  }) => SearchSessionState(
    active: active ?? this.active,
    context: context ?? this.context,
    category: category ?? this.category,
    location: location ?? this.location,
    query: query ?? this.query,
    caseSensitive: caseSensitive ?? this.caseSensitive,
    wholeWord: wholeWord ?? this.wholeWord,
    regex: regex ?? this.regex,
    results: results ?? this.results,
    selected: selected ?? this.selected,
    searching: searching ?? this.searching,
    indexing: indexing ?? this.indexing,
    truncated: truncated ?? this.truncated,
    skippedFiles: skippedFiles ?? this.skippedFiles,
    invalidRegex: invalidRegex ?? this.invalidRegex,
    hasZeroLengthMatches: hasZeroLengthMatches ?? this.hasZeroLengthMatches,
    error: error,
    focusRequest: focusRequest ?? this.focusRequest,
    generation: generation ?? this.generation,
    requestRevision: requestRevision ?? this.requestRevision,
  );
}

final searchSessionProvider =
    NotifierProvider<SearchSessionController, SearchSessionState>(
      SearchSessionController.new,
    );

/// One window owns one bounded, ephemeral search session. No queries are persisted.
class SearchSessionController extends Notifier<SearchSessionState> {
  int _originContextRevision = 0;
  final _worker = SourceSearchWorker();
  Timer? _debounce;
  NotesSearchController? _notes;
  StreamSubscription<void>? _repositoryChanges;
  StreamSubscription<NotesSearchState>? _noteChanges;
  final _queries = <(SearchCategory, SearchLocation), SourceSearchOptions>{};
  List<ActionSearchResult> _commands = const [];
  int _request = 0, _limit = maxWorkspaceSearchResults;
  bool _disposed = false, _hasOpened = false;
  FocusNode? _returnFocus;
  WeakReference<FocusNode>? _originFocus;
  String? _originWorkspace, _originBuffer;
  Future<void> _running = Future<void>.value();
  SearchCommandTarget? commandTarget;
  String? actionAccountId;

  VoidCallback? activateOutline;
  ValueChanged<int>? moveOutline;

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
      if (workspace != null) SearchCategory.text,
      if (buffer != null) SearchCategory.outline,
      if (workspace != null) SearchCategory.documents,
      if (workspace?.writersideProject != null ||
          workspace?.writersideModule != null)
        SearchCategory.topics,
      SearchCategory.recent,
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
      if (!workspaceSearchInputsChanged(before, after)) return;
      if (before?.workspace?.id != after.workspace?.id ||
          before?.activeBufferId != after.activeBufferId) {
        _originContextRevision++;
      }
      if (before?.workspace?.id != after.workspace?.id) {
        commandTarget = null;
        _originFocus = null;
        _returnFocus = null;
        if (state.textActive &&
            state.location == SearchLocation.recovery &&
            workspaceVisible &&
            after.workspace != null) {
          open(
            category: SearchCategory.text,
            location: after.activeBuffer == null
                ? SearchLocation.workspace
                : SearchLocation.document,
          );
          return;
        }
      }
      if (state.active) {
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

  void configureCommands(List<ActionSearchResult> commands) {
    _commands = commands;
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

  void open({SearchCategory? category, SearchLocation? location}) {
    final available = categories;
    if (available.isEmpty) return;
    final requested =
        category ??
        (_hasOpened && available.contains(state.category)
            ? state.category
            : workspaceVisible &&
                  ref.read(workspaceControllerProvider).activeBuffer != null
            ? SearchCategory.text
            : SearchCategory.recent);
    if (!available.contains(requested)) return;
    final hasDocument =
        workspaceVisible &&
        ref.read(workspaceControllerProvider).activeBuffer != null;
    if (requested == SearchCategory.text &&
        location == SearchLocation.document &&
        !hasDocument) {
      return;
    }
    captureOrigin();
    _remember();
    var nextLocation =
        location ??
        (requested == SearchCategory.text
            ? hasDocument
                  ? state.location
                  : SearchLocation.workspace
            : SearchLocation.document);
    if (requested == SearchCategory.text &&
        location == null &&
        nextLocation == SearchLocation.recovery &&
        state.context?.workspaceId !=
            ref.read(workspaceControllerProvider).workspace?.id) {
      nextLocation = hasDocument
          ? SearchLocation.document
          : SearchLocation.workspace;
    }
    var options =
        _queries[(requested, nextLocation)] ?? const SourceSearchOptions();
    if (requested == SearchCategory.text &&
        nextLocation != SearchLocation.document &&
        ref.read(workspaceControllerProvider).workspace?.isRemote == true) {
      options = options.copyWith(caseSensitive: false, regex: false);
    }
    _limit = maxWorkspaceSearchResults;
    _hasOpened = true;
    state = state.copyWith(
      active: true,
      category: requested,
      location: nextLocation,
      query: options.query,
      results: const [],
      selected: 0,
      caseSensitive: options.caseSensitive,
      wholeWord: options.wholeWord,
      regex: options.regex,
      focusRequest: state.focusRequest + 1,
      requestRevision: state.requestRevision + 1,
    );
    _schedule();
  }

  void toggle() => state.active ? close() : open();
  void close({bool restoreFocus = true}) {
    if (!state.active) return;
    _remember();
    _cancel();
    state = state.copyWith(
      active: false,
      results: const [],
      searching: false,
      indexing: false,
      generation: _request,
      requestRevision: state.requestRevision + 1,
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
    _queries[(state.category, state.location)] = SourceSearchOptions(
      query: state.query,
      caseSensitive: state.caseSensitive,
      wholeWord: state.wholeWord,
      regex: state.regex,
    );
  }

  void set(SearchSessionState next) {
    state = next.copyWith(
      results: const [],
      selected: 0,
      requestRevision: state.requestRevision + 1,
    );
    _remember();
    _limit = maxWorkspaceSearchResults;
    _schedule();
  }

  void query(String value) => set(state.copyWith(query: value));
  void select(int index) {
    if (state.results.isEmpty) return;
    state = state.copyWith(selected: index.clamp(0, state.results.length - 1));
  }

  void moveSelection(int delta) {
    if (state.category == SearchCategory.outline) {
      moveOutline?.call(delta);
    } else {
      select(state.selected + delta);
    }
  }

  void showMore() {
    _limit += maxWorkspaceSearchResults;
    _schedule();
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
    state = state.copyWith(
      context: SearchSessionContext(
        ref.read(appRouterProvider).routeInformationProvider.value.uri.path,
        visible ? workspace.workspace?.id : null,
        visible ? workspace.activeBufferId : null,
        visible ? workspace.activeBuffer?.revision : null,
        visible ? workspace.workspace?.nextcloudAccountId : null,
      ),
      caseSensitive:
          state.textActive &&
              state.location != SearchLocation.document &&
              workspace.workspace?.isRemote == true
          ? false
          : null,
      regex:
          state.textActive &&
              state.location != SearchLocation.document &&
              workspace.workspace?.isRemote == true
          ? false
          : null,
      results: const [],
      selected: 0,
      searching: state.active,
      indexing: false,
      truncated: false,
      skippedFiles: const [],
      invalidRegex: false,
      hasZeroLengthMatches: false,
      generation: request,
    );
    if (!state.active || state.textActive && state.query.isEmpty) {
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
    if (!_current(request)) return;
    final snapshot = state;
    final workspaceState = ref.read(workspaceControllerProvider);
    final workspace = workspaceState.workspace;
    void publish(List<SidebarSearchResult> results, {bool truncated = false}) {
      if (_current(request)) {
        state = state.copyWith(
          results: List.unmodifiable(results),
          searching: false,
          truncated: truncated,
        );
      }
    }

    try {
      switch (snapshot.category) {
        case SearchCategory.text:
          if (workspace == null || !workspaceVisible) return;
          if (snapshot.location != SearchLocation.document &&
              workspace.isRemote) {
            await _searchNotes(request, workspaceState, snapshot);
            return;
          }
          final options = snapshot.options;
          WorkspaceTextOutcome outcome;
          if (snapshot.location == SearchLocation.document) {
            final buffer = workspaceState.activeBuffer;
            if (buffer == null) {
              publish([]);
              return;
            }
            final document = SourceDocument(fullText: buffer.text);
            final matches = await _worker.search(
              document,
              options,
              maximumMatches: _limit + 1,
              stopAfterMaximumMatches: true,
            );
            if (!_current(request)) return;
            if (matches == null) {
              state = state.copyWith(
                searching: false,
                skippedFiles: [buffer.displayName],
              );
              return;
            }
            final digest = notesSearchDigest(buffer.text);
            outcome = WorkspaceTextOutcome(
              invalidRegex: sourceSearchOptionsHaveInvalidRegex(options),
              hasZeroLengthMatches: matches.hasZeroLengthMatches,
              truncated: matches.matches.length > _limit,
              matches: [
                for (final match in matches.matches.take(_limit))
                  WorkspaceTextMatch(
                    filePath: buffer.filePath,
                    bufferId: buffer.id,
                    digest: digest,
                    relativePath:
                        buffer.remoteTitle ??
                        buffer.untitledName ??
                        (buffer.filePath == null
                            ? ''
                            : p.basename(buffer.filePath!)),
                    fileKind: resolveWorkspaceDocumentContext(
                      workspace,
                      buffer,
                    ).kind,
                    line: document.lineIndex.lineNumberAtOffset(
                      match.fullStart,
                    ),
                    startOffset: match.fullStart,
                    endOffset: match.fullEnd,
                    query: options.query,
                    lineText: boundedSearchSnippet(
                      document.lineIndex
                          .lineAt(
                            document.lineIndex.lineNumberAtOffset(
                              match.fullStart,
                            ),
                          )
                          .text,
                      matchStart:
                          match.fullStart -
                          document.lineIndex.offsetForLine(
                            document.lineIndex.lineNumberAtOffset(
                              match.fullStart,
                            ),
                          ),
                    ),
                  ),
              ],
            );
          } else {
            outcome = await loadWorkspaceTextMatches(
              workspaceState,
              options,
              loadText: ref.read(workspaceServiceProvider).loadText,
              isCancelled: () => !_current(request),
              worker: _worker,
              maximumResults: _limit,
            );
          }
          if (!_current(request)) return;
          state = state.copyWith(
            results: [
              for (final match in outcome.matches)
                TextSearchResult(workspace.id, match),
            ],
            searching: false,
            truncated: outcome.truncated,
            skippedFiles: outcome.skippedFiles,
            invalidRegex: outcome.invalidRegex,
            hasZeroLengthMatches: outcome.hasZeroLengthMatches,
          );
        case SearchCategory.outline:
          publish([]); // The existing outline owns its live model and renderer.
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
            for (final item in [
              ...history.where((r) => r.isDocument),
              ...history.where((r) => !r.isDocument),
            ])
              if (normalizeNotesSearch(
                '${item.title ?? ''} ${item.path} ${item.ownerRoot ?? ''} ${item.accountId ?? ''} ${item.accountLabel ?? ''}',
              ).contains(query))
                RecentSearchResult(item),
          ]);
        case SearchCategory.actions:
          final query = snapshot.query.trim().toLowerCase();
          publish(
            _commands
                .where(
                  (c) =>
                      '${c.title} ${c.category} ${c.description ?? ''} ${c.command.id}'
                          .toLowerCase()
                          .contains(query),
                )
                .toList(),
          );
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

  void _observeRepository(Stream<void> changes) {
    _repositoryChanges ??= changes.listen((_) {
      if (state.active &&
          (state.category == SearchCategory.documents ||
              state.textActive && state.location != SearchLocation.document)) {
        _schedule();
      }
    });
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
      recovery: snapshot.location == SearchLocation.recovery,
    );
    _notes = controller;
    _noteChanges = controller.changes.listen((value) {
      if (!_current(request)) return;
      state = state.copyWith(
        results: [
          for (final hit in value.hits)
            NoteSearchResult(
              account,
              hit,
              snapshot.location == SearchLocation.recovery,
            ),
        ],
        searching: value.loading,
        indexing: value.indexing,
        truncated: value.truncated,
        error: value.error?.toString(),
      );
    });
    await controller.search(
      snapshot.query,
      wholeWord: snapshot.wholeWord,
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
