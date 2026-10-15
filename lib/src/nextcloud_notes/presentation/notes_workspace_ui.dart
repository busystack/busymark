import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_settings.dart';
import '../../app/busymark_design.dart';
import '../../app/busymark_dialogs.dart';
import '../../app/busymark_glyphs.dart';
import '../../app/localization.dart';
import '../../local_history/local_history_controller.dart';
import '../../local_history/local_history_models.dart';
import '../../workspace/workspace_controller.dart';
import '../application/nextcloud_connection.dart';
import '../application/notes_navigation.dart';
import '../application/notes_repository.dart';
import '../application/notes_offline_controller.dart';
import '../application/notes_search_controller.dart';
import '../application/notes_transfer_service.dart';
import '../domain/notes_models.dart';
import '../domain/notes_search.dart';

final notesOfflineProvider = FutureProvider.autoDispose
    .family<NotesOfflineController, String>((ref, accountId) async {
      final repository = await ref.watch(
        nextcloudNotesRepositoryProvider.future,
      );
      final controller = NotesOfflineController(repository, accountId);
      ref.onDispose(() => unawaited(controller.dispose()));
      await controller.initialize();
      return controller;
    });
final notesOfflineChangesProvider = StreamProvider.autoDispose
    .family<int, String>((ref, accountId) async* {
      final controller = await ref.watch(
        notesOfflineProvider(accountId).future,
      );
      var generation = 0;
      await for (final _ in controller.changes) {
        yield ++generation;
      }
    });

class NotesMatchNavigation {
  const NotesMatchNavigation(
    this.localId,
    this.start,
    this.end,
    this.digest,
    this.request,
  );
  final String localId, digest;
  final int start, end, request;
}

final notesMatchNavigationProvider =
    NotifierProvider<NotesMatchNavigationController, NotesMatchNavigation?>(
      NotesMatchNavigationController.new,
    );

class NotesMatchNavigationController extends Notifier<NotesMatchNavigation?> {
  @override
  NotesMatchNavigation? build() => null;
  void navigate(String id, int start, int end, String digest) {
    state = NotesMatchNavigation(
      id,
      start,
      end,
      digest,
      (state?.request ?? 0) + 1,
    );
  }
}

Future<void> showNotesSearch(
  BuildContext context,
  WidgetRef ref, {
  String query = '',
  String? account,
  bool recovery = false,
}) async {
  final accountId =
      account ??
      ref.read(workspaceControllerProvider).workspace?.nextcloudAccountId;
  if (accountId == null) return;
  final focus = FocusManager.instance.primaryFocus;
  final choice =
      await showBusyMarkModalDialog<
        ({NotesSearchHit hit, String query, bool wholeWord, bool source})
      >(
        context,
        builder: (_) => NotesSearchDialog(
          accountId: accountId,
          initialQuery: query,
          recovery: recovery,
        ),
      );
  if (!context.mounted) return;
  if (choice == null) {
    if (focus?.context?.mounted == true) focus!.requestFocus();
    return;
  }
  if (ref.read(workspaceControllerProvider).workspace?.nextcloudAccountId !=
      accountId) {
    return;
  }
  if (recovery) {
    final repository = await ref.read(nextcloudNotesRepositoryProvider.future);
    final note = repository.noteById(choice.hit.localId);
    if (context.mounted &&
        note != null &&
        note.accountId == accountId &&
        isNotesRecovery(note)) {
      await showNotesRecovery(context, ref, note);
    }
    return;
  }
  final controller = ref.read(workspaceControllerProvider.notifier);
  if (!await controller.openNextcloudNote(choice.hit.localId) ||
      !context.mounted) {
    return;
  }
  final buffer = ref.read(workspaceControllerProvider).activeBuffer;
  if (buffer?.remoteNote?.localId != choice.hit.localId) return;
  final repository = await ref.read(nextcloudNotesRepositoryProvider.future);
  final note = repository.noteById(choice.hit.localId);
  if (note == null) return;
  var hit = choice.hit;
  // Even a revision collision cannot apply offsets to a different document.
  if (buffer!.revision != hit.revision ||
      notesSearchDigest(buffer.text) != hit.digest) {
    final refreshed = await relocateNotesSearchHit(
      NotesSearchQuery(choice.query, wholeWord: choice.wholeWord),
      NotesSearchOverlay(
        note.localId,
        buffer.revision,
        note.title,
        note.category,
        buffer.text,
      ),
      hit.start ?? 0,
    );
    if (refreshed == null || !context.mounted) return;
    final current = ref.read(workspaceControllerProvider).activeBuffer;
    if (current?.remoteNote?.localId != note.localId ||
        current!.revision != refreshed.revision ||
        notesSearchDigest(current.text) != refreshed.digest) {
      return;
    }
    hit = refreshed;
  }
  if (hit.start == null || hit.end == null) return;
  if (choice.source) {
    await ref
        .read(appSettingsControllerProvider.notifier)
        .setDocumentViewMode(DocumentViewModePreference.source);
  }
  ref
      .read(notesMatchNavigationProvider.notifier)
      .navigate(hit.localId, hit.start!, hit.end!, hit.digest);
}

class NotesSearchDialog extends ConsumerStatefulWidget {
  const NotesSearchDialog({
    super.key,
    required this.accountId,
    this.initialQuery = '',
    this.recovery = false,
  });
  final String accountId, initialQuery;
  final bool recovery;
  @override
  ConsumerState<NotesSearchDialog> createState() => _NotesSearchDialogState();
}

class _NotesSearchDialogState extends ConsumerState<NotesSearchDialog> {
  NotesSearchController? _controller;
  StreamSubscription<NotesSearchState>? _results;
  StreamSubscription<void>? _repositoryChanges;
  Timer? _debounce;
  late final _text = TextEditingController(text: widget.initialQuery);
  late final _focus = FocusNode(onKeyEvent: _key);
  final _scroll = ScrollController();
  NotesSearchState _state = const NotesSearchState(loading: true);
  bool _wholeWord = false;
  int _selected = 0, _limit = 80;
  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    final repository = await ref.read(nextcloudNotesRepositoryProvider.future);
    if (!mounted) return;
    _controller = NotesSearchController(
      repository.store,
      widget.accountId,
      recovery: widget.recovery,
    );
    _results = _controller!.changes.listen((state) {
      if (mounted) {
        setState(() {
          _state = state;
          _selected = 0;
        });
      }
    });
    _repositoryChanges = repository.changes.listen((_) => _schedule());
    _search();
  }

  void _schedule() {
    _controller?.cancel();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), _search);
  }

  void _search() {
    final repository = ref.read(nextcloudNotesRepositoryProvider).value;
    if (repository == null || _controller == null) return;
    final overlays = [
      for (final buffer
          in ref.read(workspaceControllerProvider).documentBuffers)
        if (!widget.recovery &&
            buffer.isDirty &&
            buffer.remoteNote?.accountId == widget.accountId &&
            repository.noteById(buffer.remoteNote!.localId) != null)
          NotesSearchOverlay(
            buffer.remoteNote!.localId,
            buffer.revision,
            repository.noteById(buffer.remoteNote!.localId)!.title,
            repository.noteById(buffer.remoteNote!.localId)!.category,
            buffer.text,
          ),
    ];
    unawaited(
      _controller!.search(
        _text.text,
        wholeWord: _wholeWord,
        limit: _limit,
        overlays: overlays,
      ),
    );
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.pop(context);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _open();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
        event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (_state.hits.isNotEmpty) {
        setState(
          () => _selected =
              (_selected +
                      (event.logicalKey == LogicalKeyboardKey.arrowDown
                          ? 1
                          : -1))
                  .clamp(0, _state.hits.length - 1),
        );
        if (_scroll.hasClients) {
          _scroll.animateTo(
            (_selected * 90.0).clamp(0, _scroll.position.maxScrollExtent),
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _open({bool source = false, int? index}) {
    if (_state.loading || _state.hits.isEmpty) return;
    Navigator.pop(context, (
      hit: _state.hits[index ?? _selected],
      query: _text.text,
      wholeWord: _wholeWord,
      source: source,
    ));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    unawaited(_results?.cancel());
    unawaited(_repositoryChanges?.cancel());
    unawaited(_controller?.dispose());
    _text.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      workspaceControllerProvider.select((s) => s.documentBuffers),
      (a, b) => _schedule(),
    );
    return BusyMarkDialogShell(
      title: widget.recovery
          ? '${context.l10n.notesRecovery} · ${context.l10n.search}'
          : context.l10n.search,
      maxWidth: 760,
      children: [
        TextField(
          autofocus: true,
          focusNode: _focus,
          controller: _text,
          decoration: InputDecoration(labelText: context.l10n.search),
          onChanged: (_) {
            _limit = 80;
            _schedule();
          },
        ),
        if (widget.recovery) Text(context.l10n.notesRecoveryHelp),
        Text(
          context.l10n.notesSearchHelp,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        CheckboxListTile(
          dense: true,
          title: Text(context.l10n.sourceSearchWholeWord),
          value: _wholeWord,
          onChanged: (v) => setState(() {
            _wholeWord = v ?? false;
            _schedule();
          }),
        ),
        if (_state.loading) const LinearProgressIndicator(),
        if (_state.indexing) Text(context.l10n.notesIndexing),
        if (_state.error != null)
          Text('${context.l10n.warning}: ${_state.error}'),
        SizedBox(
          height: 360,
          child: _state.hits.isEmpty
              ? Center(
                  child: Text(
                    _state.loading
                        ? context.l10n.notesIndexing
                        : context.l10n.noResults,
                  ),
                )
              : ListView.builder(
                  key: const ValueKey('notes-search-results'),
                  controller: _scroll,
                  itemCount: _state.hits.length,
                  itemBuilder: (context, index) {
                    final hit = _state.hits[index];
                    final from =
                        hit.snippetMatchStart ??
                        (hit.start == null
                            ? 0
                            : (hit.start! - hit.snippetStart).clamp(
                                0,
                                hit.snippet.length,
                              ));
                    final to =
                        hit.snippetMatchEnd ??
                        (hit.end == null
                            ? 0
                            : (hit.end! - hit.snippetStart).clamp(
                                from,
                                hit.snippet.length,
                              ));
                    return ListTile(
                      key: ValueKey((
                        'notes-search-hit',
                        hit.localId,
                        hit.start,
                        hit.end,
                      )),
                      selected: index == _selected,
                      title: Text(
                        hit.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hit.category.isNotEmpty)
                            Text(
                              hit.category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: hit.snippet
                                      .substring(0, from)
                                      .replaceAll(RegExp(r'[\r\n\t]'), ' '),
                                ),
                                TextSpan(
                                  text: hit.snippet
                                      .substring(from, to)
                                      .replaceAll(RegExp(r'[\r\n\t]'), ' '),
                                  style: TextStyle(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: hit.snippet
                                      .substring(to)
                                      .replaceAll(RegExp(r'[\r\n\t]'), ' '),
                                ),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      trailing: widget.recovery || hit.start == null
                          ? null
                          : IconButton(
                              tooltip: context.l10n.notesSourceLocation,
                              icon: const Icon(BusyMarkGlyphs.code),
                              onPressed: () =>
                                  _open(source: true, index: index),
                            ),
                      onTap: () => _open(index: index),
                    );
                  },
                ),
        ),
        if (_state.truncated)
          TextButton(
            onPressed: () {
              _limit += 80;
              _search();
            },
            child: Text(context.l10n.workspaceSearchShowMore),
          ),
      ],
    );
  }
}

Future<void> showNotesBatch(
  BuildContext context,
  WidgetRef ref,
  List<String> ids, {
  String? initialAction,
  List<NotesMetadataSnapshot>? reviewedTargets,
}) async {
  final repository = await ref.read(nextcloudNotesRepositoryProvider.future);
  final reviewed =
      reviewedTargets ??
      [
        for (final id in ids)
          if (repository.noteById(id) != null) repository.metadataSnapshot(id),
      ];
  if (!context.mounted || reviewed.isEmpty) return;
  var action = initialAction ?? 'favorite';
  var category = '';
  final confirmed = await showBusyMarkModalDialog<bool>(
    context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => BusyMarkDialogShell(
        title: '${context.l10n.notesSelected} (${reviewed.length})',
        actions: [
          BusyMarkDialogButton(
            label: context.l10n.cancel,
            onPressed: () => Navigator.pop(context, false),
          ),
          BusyMarkDialogButton(
            label: context.l10n.save,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
        children: [
          SizedBox(
            height: 140,
            child: ListView(
              children: [
                for (final snapshot in reviewed)
                  ListTile(
                    dense: true,
                    title: Text(snapshot.note.title),
                    subtitle: Text(snapshot.note.category),
                  ),
              ],
            ),
          ),
          DropdownButton<String>(
            isExpanded: true,
            value: action,
            items: [
              DropdownMenuItem(
                value: 'favorite',
                child: Text(context.l10n.nextcloudFavorites),
              ),
              DropdownMenuItem(
                value: 'unfavorite',
                child: Text(context.l10n.notesRemoveFavorite),
              ),
              DropdownMenuItem(
                value: 'move',
                child: Text(context.l10n.notesMove),
              ),
            ],
            onChanged: (v) => setDialogState(() => action = v!),
          ),
          if (action == 'move')
            TextField(
              decoration: InputDecoration(
                labelText: context.l10n.syntaxReferenceCategory,
              ),
              onChanged: (v) => category = v,
            ),
        ],
      ),
    ),
  );
  if (confirmed != true || !context.mounted) return;
  final outcomes = await ref
      .read(workspaceControllerProvider.notifier)
      .batchNextcloudMetadata(
        reviewed,
        category: action == 'move' ? category : null,
        favorite: action == 'move' ? null : action == 'favorite',
      );
  if (!context.mounted) return;
  await showBusyMarkModalDialog<void>(
    context,
    builder: (context) => BusyMarkDialogShell(
      title: context.l10n.notesSelected,
      children: [
        for (final outcome in outcomes)
          ListTile(
            title: Text(outcome.title),
            subtitle: Text(
              [
                switch (outcome.status) {
                  NotesBatchStatus.changed =>
                    context.l10n.nextcloudSavedLocally,
                  NotesBatchStatus.skipped => context.l10n.notesSkipped,
                  NotesBatchStatus.conflicted => context.l10n.gitConflicts,
                  NotesBatchStatus.failed => context.l10n.notesFailed,
                },
                if (outcome.detail != null) outcome.detail!,
              ].join(' · '),
            ),
          ),
      ],
    ),
  );
}

Future<void> showNotesOffline(
  BuildContext context,
  WidgetRef ref,
  NextcloudNote note,
) async {
  final controller = await ref.read(
    notesOfflineProvider(note.accountId).future,
  );
  if (!context.mounted) return;
  await showBusyMarkModalDialog<void>(
    context,
    builder: (context) => StreamBuilder<void>(
      stream: controller.changes,
      builder: (context, _) => FutureBuilder<NotesOfflineStatus>(
        future: controller.inspect(note),
        builder: (context, snapshot) {
          final status = snapshot.data;
          return BusyMarkDialogShell(
            title: context.l10n.notesOffline,
            actions: [
              BusyMarkDialogButton(
                label: context.l10n.visualizationRetry,
                onPressed: () => unawaited(controller.retry(note.localId)),
              ),
              BusyMarkDialogButton(
                label: context.l10n.cancel,
                onPressed: () => unawaited(controller.cancelNote(note.localId)),
              ),
              BusyMarkDialogButton(
                label: controller.individuallyRetained(note.localId)
                    ? context.l10n.notesOfflineRemove
                    : context.l10n.notesOffline,
                onPressed: () => unawaited(
                  controller.setRequirement(
                    'note',
                    note.localId,
                    required: !controller.individuallyRetained(note.localId),
                  ),
                ),
              ),
            ],
            children: [
              Text(note.title),
              if (status == null)
                const LinearProgressIndicator()
              else ...[
                Text(context.l10n.notesTextAvailable),
                Text(
                  '${status.available ? context.l10n.notesAvailableOffline : context.l10n.notesIncomplete} · ${status.availableCount}/${status.requiredCount}',
                ),
                if (status.running) const LinearProgressIndicator(),
                for (final reference in status.missing) Text(reference),
                for (final reference in status.external)
                  Text('${context.l10n.notesIncomplete}: $reference'),
                for (final failure in controller.failures.entries.where(
                  (e) => e.key.startsWith('${note.localId}:'),
                ))
                  Text(failure.value),
              ],
            ],
          );
        },
      ),
    ),
  );
}

Future<void> showNotesRecovery(
  BuildContext context,
  WidgetRef ref,
  NextcloudNote note,
) async {
  await ref.read(localHistoryControllerProvider.notifier).refresh();
  if (!context.mounted) return;
  await showBusyMarkModalDialog<void>(
    context,
    builder: (_) => NotesRecoveryDialog(note: note),
  );
}

class NotesRecoveryDialog extends ConsumerStatefulWidget {
  const NotesRecoveryDialog({super.key, required this.note});
  final NextcloudNote note;
  @override
  ConsumerState<NotesRecoveryDialog> createState() =>
      _NotesRecoveryDialogState();
}

class _NotesRecoveryDialogState extends ConsumerState<NotesRecoveryDialog> {
  LocalHistoryDocument? _document;
  LocalHistoryRevision? _revision;
  late String _source = widget.note.content;
  NotesOfflineStatus? _availability;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    unawaited(_inspect());
  }

  Future<void> _inspect() async {
    final generation = ++_generation;
    final repository = await ref.read(nextcloudNotesRepositoryProvider.future);
    final availability = await _inspectRecoveryAvailability(
      repository,
      widget.note,
      source: _source,
    );
    if (mounted && generation == _generation) {
      setState(() => _availability = availability);
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(localHistoryControllerProvider);
    _document ??= history.snapshot.documents
        .where(
          (d) =>
              d.remoteNote?.accountId == widget.note.accountId &&
              d.remoteNote?.localId == widget.note.localId,
        )
        .firstOrNull;
    final summaries = _document == null
        ? <LocalHistoryRevisionSummary>[]
        : history.snapshot.revisionsFor(_document!.id);
    return BusyMarkDialogShell(
      title: context.l10n.notesRecovery,
      maxWidth: 760,
      actions: [
        BusyMarkDialogButton(
          label:
              '${context.l10n.notesRecovery}: ${context.l10n.nextcloudNewNote}',
          onPressed: _availability == null || _availability!.missing.isNotEmpty
              ? null
              : () async {
                  final controller = ref.read(
                    workspaceControllerProvider.notifier,
                  );
                  final success = _revision == null || _document == null
                      ? await controller.recoverDeletedNextcloudNote(
                          widget.note.localId,
                          content: _source,
                        )
                      : await controller.recoverNextcloudHistoryRevision(
                          document: _document!,
                          revision: _revision!,
                        );
                  if (context.mounted && success) Navigator.pop(context);
                },
        ),
      ],
      children: [
        Text(widget.note.title),
        Text(context.l10n.notesRecoveryHelp),
        if (summaries.isEmpty) Text(context.l10n.notesNoHistory),
        if (!ref
            .read(localHistoryControllerProvider.notifier)
            .policy
            .recordingEnabled)
          Text(context.l10n.localHistoryWarningRecordingDisabled),
        DropdownButton<String>(
          isExpanded: true,
          value: _revision?.summary.id ?? '',
          items: [
            DropdownMenuItem(
              value: '',
              child: Text(context.l10n.notesTextAvailable),
            ),
            for (final summary in summaries)
              DropdownMenuItem(
                value: summary.id,
                child: Text(summary.capturedAt.toLocal().toString()),
              ),
          ],
          onChanged: (id) async {
            if (id == '') {
              setState(() {
                _revision = null;
                _source = widget.note.content;
                _availability = null;
              });
              await _inspect();
              return;
            }
            if (_document == null) return;
            final controller = ref.read(
              localHistoryControllerProvider.notifier,
            );
            controller.selectDocument(_document!.id);
            await controller.selectRevision(id!);
            final revision = ref
                .read(localHistoryControllerProvider)
                .selectedRevision;
            if (mounted && revision != null) {
              setState(() {
                _revision = revision;
                _source = revision.source;
                _availability = null;
              });
              await _inspect();
            }
          },
        ),
        if (_availability == null)
          const LinearProgressIndicator()
        else ...[
          Text(
            '${context.l10n.notesAvailableOffline}: ${_availability!.availableCount}/${_availability!.requiredCount}',
          ),
          for (final item in _availability!.missing)
            Text('${context.l10n.notesIncomplete}: $item'),
          for (final item in _availability!.external)
            Text('${context.l10n.notesIncomplete}: $item'),
        ],
        SizedBox(
          height: 260,
          child: SingleChildScrollView(child: SelectableText(_source)),
        ),
      ],
    );
  }
}

Future<void> showNotesExport(
  BuildContext context,
  WidgetRef ref,
  List<String> ids,
) async {
  final completedLabel = context.l10n.notesCompleted;
  final incompleteLabel = context.l10n.notesIncomplete;
  final parent = await getDirectoryPath(
    confirmButtonText: context.l10n.notesExport,
  );
  if (parent == null || !context.mounted) return;
  List<NextcloudNote>? snapshot;
  Object? failure;
  try {
    snapshot = await ref
        .read(workspaceControllerProvider.notifier)
        .captureNextcloudExport(ids.toSet());
    if (snapshot == null) failure = incompleteLabel;
  } on Object catch (error) {
    failure = error;
  }
  if (!context.mounted) return;
  if (failure != null || snapshot == null) {
    await showBusyMarkModalDialog<void>(
      context,
      builder: (context) => BusyMarkDialogShell(
        title: context.l10n.warning,
        children: [Text(context.l10n.workspaceErrorSaveFailed('$failure'))],
      ),
    );
    return;
  }
  final captured = snapshot;
  final repository = await ref.read(nextcloudNotesRepositoryProvider.future);
  if (!context.mounted) return;
  await showBusyMarkModalDialog<void>(
    context,
    barrierDismissible: false,
    builder: (_) => NotesTransferProgressDialog(
      title: context.l10n.notesExport,
      operation: (cancel, progress) async {
        final result = await NotesTransferService(repository).exportSnapshot(
          notes: captured,
          destination: parent,
          cancellation: cancel,
          onProgress: progress,
        );
        return [
          result.complete ? completedLabel : incompleteLabel,
          '${result.count}',
          result.path,
          ...result.omissions,
        ];
      },
    ),
  );
}

Future<void> showNotesImport(
  BuildContext context,
  WidgetRef ref, {
  bool folder = true,
}) async {
  final accountId = ref
      .read(workspaceControllerProvider)
      .workspace
      ?.nextcloudAccountId;
  if (accountId == null) return;
  final savedLocally = context.l10n.nextcloudSavedLocally;
  final alreadyImported = context.l10n.notesImportAlreadyImported;
  final synced = context.l10n.nextcloudSynced;
  final source = folder
      ? await getDirectoryPath(confirmButtonText: context.l10n.notesImport)
      : (await openFile(
          acceptedTypeGroups: [
            XTypeGroup(
              label: context.l10n.fileTypeMarkdown,
              extensions: ['md', 'markdown'],
            ),
          ],
        ))?.path;
  if (source == null || !context.mounted) return;
  final repository = await ref.read(nextcloudNotesRepositoryProvider.future);
  final service = NotesTransferService(repository);
  try {
    var review = await service.review(source, accountId);
    final pending = (await repository.store.importOperations(
      accountId,
    )).where((o) => o['root'] == review.root).toList();
    if (!context.mounted) return;
    if (pending.isNotEmpty) {
      final choice = await showBusyMarkModalDialog<String>(
        context,
        builder: (_) => NotesImportOperationDialog(operations: pending),
      );
      if (choice == null || !context.mounted) return;
      if (choice.isNotEmpty) {
        review = await service.resumeImport(choice, accountId);
      }
      if (!context.mounted) return;
    }
    final confirmed = await showBusyMarkModalDialog<bool>(
      context,
      builder: (_) => NotesImportReviewDialog(review: review),
    );
    if (confirmed != true || !context.mounted) return;
    await showBusyMarkModalDialog<void>(
      context,
      barrierDismissible: false,
      builder: (_) => NotesTransferProgressDialog(
        title: context.l10n.notesImport,
        operation: (cancel, progress) async {
          final results = await service.importReviewed(
            review,
            accountId,
            cancellation: cancel,
            onProgress: progress,
          );
          ref
              .read(workspaceControllerProvider.notifier)
              .synchronizeImportedNotes(accountId);
          return [
            for (final result in results)
              '${result.item}: ${result.error ?? [if (result.alreadyImported) alreadyImported, repository.noteById(result.noteId ?? '')?.hasPendingChanges == false ? synced : savedLocally].join(' · ')}',
          ];
        },
      ),
    );
  } on Object catch (error) {
    if (context.mounted) {
      await showBusyMarkModalDialog<void>(
        context,
        builder: (context) => BusyMarkDialogShell(
          title: context.l10n.warning,
          children: [Text(error.toString())],
        ),
      );
    }
  }
}

/// Choosing a new import never reuses a prior source-item association. Resume
/// is explicit and selects a persisted reviewed operation within this account.
class NotesImportOperationDialog extends StatelessWidget {
  const NotesImportOperationDialog({super.key, required this.operations});
  final List<Map<String, dynamic>> operations;
  @override
  Widget build(BuildContext context) => BusyMarkDialogShell(
    title: context.l10n.notesImport,
    actions: [
      BusyMarkDialogButton(
        label: context.l10n.cancel,
        onPressed: () => Navigator.pop(context),
      ),
    ],
    children: [
      ListTile(
        title: Text(context.l10n.notesImportNew),
        onTap: () => Navigator.pop(context, ''),
      ),
      for (final operation in operations)
        ListTile(
          title: Text(context.l10n.notesImportResume),
          subtitle: Text(
            '${operation['root']}\n${DateTime.fromMillisecondsSinceEpoch((operation['created_at'] as int) * 1000).toLocal()}',
          ),
          onTap: () => Navigator.pop(context, operation['id'] as String),
        ),
    ],
  );
}

class NotesImportReviewDialog extends StatefulWidget {
  const NotesImportReviewDialog({super.key, required this.review});
  final NotesImportReview review;
  @override
  State<NotesImportReviewDialog> createState() =>
      _NotesImportReviewDialogState();
}

class _NotesImportReviewDialogState extends State<NotesImportReviewDialog> {
  @override
  Widget build(BuildContext context) => BusyMarkDialogShell(
    title: context.l10n.notesImport,
    maxWidth: 780,
    actions: [
      BusyMarkDialogButton(
        label: context.l10n.cancel,
        onPressed: () => Navigator.pop(context, false),
      ),
      BusyMarkDialogButton(
        label: context.l10n.notesImport,
        onPressed: widget.review.items.any((i) => i.selected)
            ? () => Navigator.pop(context, true)
            : null,
      ),
    ],
    children: [
      for (final issue in widget.review.issues) Text(issue),
      SizedBox(
        height: 400,
        child: ListView.builder(
          itemCount: widget.review.items.length,
          itemBuilder: (context, index) {
            final item = widget.review.items[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CheckboxListTile(
                  value: item.selected,
                  onChanged: item.alreadyImported
                      ? null
                      : (v) => setState(() => item.selected = v ?? false),
                  title: Text(item.title),
                  subtitle: Text(
                    item.alreadyImported
                        ? context.l10n.notesImportAlreadyImported
                        : item.collision
                        ? context.l10n.notesImportDistinct
                        : item.path,
                  ),
                ),
                TextFormField(
                  initialValue: item.category,
                  readOnly: item.alreadyImported,
                  decoration: InputDecoration(
                    labelText: context.l10n.syntaxReferenceCategory,
                  ),
                  onChanged: (v) => item.category = v,
                ),
                Text('${context.l10n.notesAttachments}: ${item.media.length}'),
                for (final reference in item.media.keys)
                  Text(reference, style: Theme.of(context).textTheme.bodySmall),
                for (final issue in item.issues)
                  Text('${context.l10n.notesIncomplete}: $issue'),
                const Divider(),
              ],
            );
          },
        ),
      ),
    ],
  );
}

class NotesTransferProgressDialog extends StatefulWidget {
  const NotesTransferProgressDialog({
    super.key,
    required this.title,
    required this.operation,
  });
  final String title;
  final Future<List<String>> Function(
    NotesTransferCancellation,
    void Function(int, int),
  )
  operation;
  @override
  State<NotesTransferProgressDialog> createState() =>
      _NotesTransferProgressDialogState();
}

class _NotesTransferProgressDialogState
    extends State<NotesTransferProgressDialog> {
  final _cancel = NotesTransferCancellation();
  int _completed = 0, _total = 0;
  List<String>? _result;
  @override
  void initState() {
    super.initState();
    unawaited(_run());
  }

  Future<void> _run() async {
    List<String> result;
    try {
      result = await widget.operation(_cancel, (a, b) {
        if (mounted) {
          setState(() {
            _completed = a;
            _total = b;
          });
        }
      });
    } on Object catch (error) {
      result = [error.toString()];
    }
    if (mounted) setState(() => _result = result);
  }

  @override
  void dispose() {
    _cancel.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _result != null,
    child: BusyMarkDialogShell(
      title: widget.title,
      closable: _result != null,
      actions: [
        BusyMarkDialogButton(
          label: _result == null ? context.l10n.cancel : context.l10n.close,
          onPressed: () {
            if (_result == null) {
              setState(_cancel.cancel);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ],
      children: [
        Text('$_completed/$_total'),
        if (_result == null)
          const LinearProgressIndicator()
        else
          SizedBox(
            height: 300,
            child: ListView(
              children: [for (final line in _result!) Text(line)],
            ),
          ),
        if (_cancel.cancelled) Text(context.l10n.notesIncomplete),
      ],
    ),
  );
}

Future<NotesOfflineStatus> _inspectRecoveryAvailability(
  NotesRepository repository,
  NextcloudNote note, {
  required String source,
}) async {
  final dependencies = await repository.attachmentAvailability(
    note.localId,
    source: source,
  );
  return NotesOfflineStatus(
    revision: note.revision,
    textAvailable: true,
    requiredCount: dependencies.required.length,
    availableCount: dependencies.available.length,
    missing: List<String>.from(
      dependencies.required.where(
        (String r) => !dependencies.available.contains(r),
      ),
    ),
    external: List<String>.from(dependencies.external),
  );
}
