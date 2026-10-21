import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/busymark_design.dart';
import '../../app/busymark_dialogs.dart';
import '../../app/localization.dart';
import '../../app/path_label.dart';
import 'notes_messages.dart';
import '../../local_history/local_history_controller.dart';
import '../../local_history/local_history_models.dart';
import '../../workspace/workspace_controller.dart';
import '../application/nextcloud_connection.dart';
import '../application/notes_navigation.dart';
import '../application/notes_repository.dart';
import '../application/notes_offline_controller.dart';
import '../application/notes_transfer_service.dart';
import '../domain/notes_models.dart';

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
    this.request, {
    this.accountId,
  });
  final String localId, digest;
  final String? accountId;
  final int start, end, request;
}

final notesMatchNavigationProvider =
    NotifierProvider<NotesMatchNavigationController, NotesMatchNavigation?>(
      NotesMatchNavigationController.new,
    );

class NotesMatchNavigationController extends Notifier<NotesMatchNavigation?> {
  @override
  NotesMatchNavigation? build() => null;
  void navigate(
    String id,
    int start,
    int end,
    String digest, {
    String? accountId,
  }) {
    state = NotesMatchNavigation(
      id,
      start,
      end,
      digest,
      (state?.request ?? 0) + 1,
      accountId: accountId,
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
  var category = reviewed.length == 1 ? reviewed.single.note.category : '';
  var busy = false;
  List<NotesBatchOutcome>? outcomes;
  String? error;
  await showBusyMarkModalDialog<void>(
    context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, update) {
        String actionLabel(String value) => switch (value) {
          'move' => context.l10n.notesMove,
          'unfavorite' => context.l10n.notesRemoveFavorite,
          _ => context.l10n.nextcloudFavorites,
        };
        String statusLabel(NotesBatchStatus value) => switch (value) {
          NotesBatchStatus.changed => context.l10n.nextcloudSavedLocally,
          NotesBatchStatus.skipped => context.l10n.notesSkipped,
          NotesBatchStatus.conflicted => context.l10n.gitConflicts,
          NotesBatchStatus.failed => context.l10n.notesFailed,
        };
        return PopScope(
          canPop: !busy,
          child: BusyMarkDialogShell(
            title: '${actionLabel(action)} (${reviewed.length})',
            closable: !busy,
            actions: [
              BusyMarkDialogButton(
                label: outcomes == null
                    ? context.l10n.cancel
                    : context.l10n.close,
                onPressed: busy ? null : () => Navigator.pop(context),
              ),
              if (outcomes == null)
                BusyMarkDialogButton(
                  label: context.l10n.save,
                  onPressed: busy
                      ? null
                      : () async {
                          update(() {
                            busy = true;
                            error = null;
                          });
                          try {
                            final result = await ref
                                .read(workspaceControllerProvider.notifier)
                                .batchNextcloudMetadata(
                                  reviewed,
                                  category: action == 'move' ? category : null,
                                  favorite: action == 'move'
                                      ? null
                                      : action == 'favorite',
                                );
                            if (context.mounted) {
                              update(() => outcomes = result);
                            }
                          } on Object catch (failure) {
                            if (context.mounted) {
                              update(
                                () => error = localizeNotesFailure(
                                  context,
                                  failure,
                                ),
                              );
                            }
                          } finally {
                            if (context.mounted) update(() => busy = false);
                          }
                        },
                ),
            ],
            children: [
              if (initialAction == null && outcomes == null)
                BusyMarkComboRow<String>(
                  title: context.l10n.notesActions,
                  values: const ['favorite', 'unfavorite', 'move'],
                  selected: action,
                  labelFor: actionLabel,
                  enabled: !busy,
                  onSelected: (value) => update(() => action = value),
                ),
              if (action == 'move' && outcomes == null)
                BusyMarkGroupedTextEntry(
                  label: context.l10n.syntaxReferenceCategory,
                  initialValue: category,
                  enabled: !busy,
                  onChanged: (value) => category = value,
                ),
              if (busy) const LinearProgressIndicator(),
              if (error != null)
                BusyMarkStatusBox(
                  message: error!,
                  kind: BusyMarkStatusKind.error,
                ),
              if (outcomes != null)
                Semantics(
                  liveRegion: true,
                  child: Text(
                    [
                      for (final status in NotesBatchStatus.values)
                        '${statusLabel(status)}: ${outcomes!.where((o) => o.status == status).length}',
                    ].join(' · '),
                  ),
                ),
              SizedBox(
                height: MediaQuery.sizeOf(context).height * .3,
                child: ListView(
                  children: [
                    for (final snapshot in reviewed)
                      BusyMarkActionRow(
                        title: snapshot.note.title,
                        subtitle: outcomes == null
                            ? snapshot.note.category
                            : statusLabel(
                                outcomes!
                                    .firstWhere(
                                      (o) => o.localId == snapshot.note.localId,
                                    )
                                    .status,
                              ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

Future<void> showNotesOffline(
  BuildContext context,
  WidgetRef ref,
  NextcloudNote note,
) async {
  await showBusyMarkModalDialog<void>(
    context,
    builder: (_) => NotesOfflineDialog(note: note),
  );
}

class NotesOfflineDialog extends ConsumerStatefulWidget {
  const NotesOfflineDialog({super.key, required this.note});
  final NextcloudNote note;
  @override
  ConsumerState<NotesOfflineDialog> createState() => _NotesOfflineDialogState();
}

class _NotesOfflineDialogState extends ConsumerState<NotesOfflineDialog> {
  NotesOfflineController? _controller;
  NotesOfflineStatus? _status;
  StreamSubscription<void>? _subscription;
  int _generation = 0;
  bool _loading = true, _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      final controller = await ref.read(
        notesOfflineProvider(widget.note.accountId).future,
      );
      if (!mounted) return;
      _controller = controller;
      _subscription = controller.changes.listen((_) => unawaited(_inspect()));
      await _inspect();
    } on Object {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = context.l10n.notesInspectionFailed;
        });
      }
    }
  }

  Future<void> _reload() async {
    ref.invalidate(notesOfflineProvider(widget.note.accountId));
    await _initialize();
  }

  Future<void> _inspect() async {
    final request = ++_generation;
    try {
      final status = await _controller!.inspect(widget.note);
      if (mounted && request == _generation) {
        setState(() {
          _status = status;
          _loading = false;
          _error = null;
        });
      }
    } on Object {
      if (mounted && request == _generation) {
        setState(() {
          _loading = false;
          _error = context.l10n.notesInspectionFailed;
        });
      }
    }
  }

  Future<void> _run(
    Future<void> Function(NotesOfflineController) action,
  ) async {
    if (_busy || _controller == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action(_controller!);
      await _inspect();
    } on Object {
      if (mounted) setState(() => _error = context.l10n.notesOperationFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _generation++;
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keep the controller's auto-dispose owner alive for the whole dialog.
    ref.watch(notesOfflineProvider(widget.note.accountId));
    final controller = _controller;
    final status = _status;
    final failed =
        controller?.failures.keys.any(
          (key) => key.startsWith('${widget.note.localId}:'),
        ) ??
        false;
    final retained =
        controller?.individuallyRetained(widget.note.localId) ?? false;
    final broader =
        controller?.requirements.any(
          (r) =>
              r['kind'] == 'category' &&
              categoryIncludes(r['target'] as String, widget.note.category),
        ) ??
        false;
    return BusyMarkDialogShell(
      title: context.l10n.notesOffline,
      actions: [
        if (status?.paused == true)
          BusyMarkDialogButton(
            label: context.l10n.notesOfflineResume,
            onPressed: _busy
                ? null
                : () => unawaited(_run((c) => c.retry(widget.note.localId))),
          )
        else if (status?.running == true)
          BusyMarkDialogButton(
            label: context.l10n.notesOfflinePause,
            onPressed: _busy
                ? null
                : () =>
                      unawaited(_run((c) => c.cancelNote(widget.note.localId))),
          ),
        if (failed ||
            _error != null ||
            (status != null &&
                status.missing.isNotEmpty &&
                !status.running &&
                !status.paused))
          BusyMarkDialogButton(
            label: context.l10n.visualizationRetry,
            onPressed: _busy
                ? null
                : () => unawaited(
                    controller == null
                        ? _reload()
                        : _run((c) => c.retry(widget.note.localId)),
                  ),
          ),
        BusyMarkDialogButton(
          label: context.l10n.close,
          onPressed: () => Navigator.pop(context),
        ),
      ],
      children: [
        Text(widget.note.title),
        BusyMarkSwitchRow(
          title: context.l10n.notesOfflineKeep,
          subtitle: context.l10n.notesOfflineRetentionHelp,
          value: retained,
          enabled: !_busy && controller != null,
          onChanged: (value) => unawaited(
            _run(
              (c) => c.setRequirement(
                'note',
                widget.note.localId,
                required: value,
              ),
            ),
          ),
        ),
        if (broader) Text(context.l10n.notesOfflineBroader),
        if (_loading || _busy) const LinearProgressIndicator(),
        if (_error != null)
          BusyMarkStatusBox(message: _error!, kind: BusyMarkStatusKind.error),
        if (status != null) ...[
          Text(context.l10n.notesTextAvailable),
          Text(
            '${status.available && status.external.isEmpty
                ? context.l10n.notesAvailableOffline
                : status.available
                ? context.l10n.notesTextAvailable
                : context.l10n.notesIncomplete} · ${context.l10n.notesAttachments}: ${status.availableCount}/${status.requiredCount}',
          ),
          if (status.paused) Text(context.l10n.notesDownloadsPaused),
          if (status.running) const LinearProgressIndicator(),
          if (failed)
            BusyMarkStatusBox(
              message: context.l10n.notesInspectionFailed,
              kind: BusyMarkStatusKind.warning,
            ),
          for (final reference in status.missing)
            Text('${context.l10n.notesIncomplete}: $reference'),
          if (status.external.isNotEmpty)
            Text(context.l10n.notesOfflineExternal),
        ],
      ],
    );
  }
}

Future<void> showNotesRecovery(
  BuildContext context,
  WidgetRef ref,
  NextcloudNote note,
) async {
  await showBusyMarkModalDialog<void>(
    context,
    barrierDismissible: false,
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
  List<LocalHistoryRevisionSummary> _summaries = const [];
  LocalHistoryRevision? _revision;
  late String _source = widget.note.content;
  String _selected = '';
  NotesOfflineStatus? _availability;
  int _generation = 0;
  bool _loading = true, _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final generation = ++_generation;
    try {
      final history = await ref
          .read(localHistoryControllerProvider.notifier)
          .readRecoveryHistory();
      if (!mounted || generation != _generation) return;
      _document = history.documents
          .where(
            (d) =>
                d.remoteNote?.accountId == widget.note.accountId &&
                d.remoteNote?.localId == widget.note.localId,
          )
          .firstOrNull;
      _summaries = _document == null ? [] : history.revisionsFor(_document!.id);
      await _select('', generation: generation);
    } on Object {
      if (mounted && generation == _generation) {
        setState(() {
          _loading = false;
          _error = context.l10n.notesOperationFailed;
        });
      }
    }
  }

  Future<void> _select(String id, {int? generation}) async {
    if (_busy) return;
    final request = generation ?? ++_generation;
    setState(() {
      _selected = id;
      _loading = true;
      _error = null;
      _availability = null;
    });
    try {
      final revision = id.isEmpty
          ? null
          : await ref
                .read(localHistoryControllerProvider.notifier)
                .readRecoveryRevision(_document!.id, id);
      if (!mounted || request != _generation) return;
      if (id.isNotEmpty && revision == null) {
        throw StateError('Missing revision');
      }
      final source = revision?.source ?? widget.note.content;
      final repository = await ref.read(
        nextcloudNotesRepositoryProvider.future,
      );
      if (!mounted || request != _generation) return;
      final availability = await _inspectRecoveryAvailability(
        repository,
        widget.note,
        source: source,
      );
      if (!mounted || request != _generation) return;
      setState(() {
        _revision = revision;
        _source = source;
        _availability = availability;
        _loading = false;
      });
    } on Object {
      if (mounted && request == _generation) {
        setState(() {
          _loading = false;
          _error = context.l10n.notesInspectionFailed;
        });
      }
    }
  }

  Future<void> _recover() async {
    if (_busy ||
        _loading ||
        _availability == null ||
        _availability!.missing.isNotEmpty) {
      return;
    }
    // Freeze the reviewed source before any await and reject repeated activation.
    final revision = _revision;
    final document = _document;
    final source = _source;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final controller = ref.read(workspaceControllerProvider.notifier);
      final success = revision == null || document == null
          ? await controller.recoverDeletedNextcloudNote(
              widget.note.localId,
              content: source,
            )
          : await controller.recoverNextcloudHistoryRevision(
              document: document,
              revision: revision,
            );
      if (!mounted) return;
      if (success) {
        Navigator.pop(context);
      } else {
        setState(() => _error = context.l10n.notesOperationFailed);
      }
    } on Object catch (failure) {
      if (mounted) {
        setState(() => _error = localizeNotesFailure(context, failure));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: BusyMarkDialogShell(
      title: context.l10n.notesRecovery,
      maxWidth: 760,
      closable: !_busy,
      actions: [
        BusyMarkDialogButton(
          label: context.l10n.close,
          onPressed: _busy ? null : () => Navigator.pop(context),
        ),
        if (_error != null)
          BusyMarkDialogButton(
            label: context.l10n.visualizationRetry,
            onPressed: _busy
                ? null
                : () => unawaited(
                    _document == null ? _load() : _select(_selected),
                  ),
          ),
        BusyMarkDialogButton(
          label:
              '${context.l10n.notesRecovery}: ${context.l10n.nextcloudNewNote}',
          onPressed:
              _busy ||
                  _loading ||
                  _availability == null ||
                  _availability!.missing.isNotEmpty
              ? null
              : () => unawaited(_recover()),
        ),
      ],
      children: [
        Text(widget.note.title),
        Text(context.l10n.notesRecoveryHelp),
        if (!_loading && _summaries.isEmpty) Text(context.l10n.notesNoHistory),
        BusyMarkComboRow<String>(
          title: context.l10n.localHistory,
          selected: _selected,
          enabled: !_busy,
          values: ['', for (final summary in _summaries) summary.id],
          labelFor: (id) => id.isEmpty
              ? context.l10n.notesCurrentText
              : notesLocalDate(
                  context,
                  _summaries.firstWhere((s) => s.id == id).capturedAt,
                ),
          onSelected: (id) => unawaited(_select(id)),
        ),
        if (_loading || _busy) const LinearProgressIndicator(),
        if (_busy)
          Semantics(
            liveRegion: true,
            child: Text(context.l10n.notesRecovering),
          ),
        if (_error != null)
          Semantics(
            liveRegion: true,
            child: BusyMarkStatusBox(
              message: _error!,
              kind: BusyMarkStatusKind.error,
            ),
          ),
        if (_availability case final status?) ...[
          Text(
            '${context.l10n.notesTextAvailable} · ${context.l10n.notesAttachments}: ${status.availableCount}/${status.requiredCount}',
          ),
          for (final item in status.missing)
            Text('${context.l10n.notesIncomplete}: $item'),
          if (status.external.isNotEmpty)
            Text(context.l10n.notesOfflineExternal),
        ],
        SizedBox(
          height: MediaQuery.sizeOf(context).height * .3,
          child: SingleChildScrollView(child: SelectableText(_source)),
        ),
      ],
    ),
  );
}

Future<void> showNotesExport(
  BuildContext context,
  WidgetRef ref,
  List<String> ids,
) async {
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
      exporting: true,
      operation: (cancel, progress) async {
        final result = await NotesTransferService(repository).exportSnapshot(
          notes: captured,
          destination: parent,
          cancellation: cancel,
          onProgress: progress,
        );
        return NotesTransferResult(
          phase: result.complete
              ? NotesTransferPhase.completed
              : NotesTransferPhase.partial,
          created: result.count,
          destination: result.path,
          omissions: result.omissions,
        );
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
  if (!context.mounted) return;
  try {
    var review = await showBusyMarkModalDialog<NotesImportReview>(
      context,
      barrierDismissible: false,
      builder: (_) => NotesImportScanDialog(
        scan: (cancel) =>
            service.review(source, accountId, cancellation: cancel),
      ),
    );
    if (review == null || !context.mounted) return;
    final pending = (await repository.store.importOperations(
      accountId,
    )).where((o) => o['root'] == review!.root).toList();
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
      builder: (_) => NotesImportReviewDialog(review: review!),
    );
    if (confirmed != true || !context.mounted) return;
    await showBusyMarkModalDialog<void>(
      context,
      barrierDismissible: false,
      builder: (_) => NotesTransferProgressDialog(
        title: context.l10n.notesImport,
        operation: (cancel, progress) async {
          final results = await service.importReviewed(
            review!,
            accountId,
            cancellation: cancel,
            onProgress: progress,
          );
          ref
              .read(workspaceControllerProvider.notifier)
              .synchronizeImportedNotes(accountId);
          final total = review!.items.where((item) => item.selected).length;
          final failures = results.where((item) => item.error != null).length;
          final skipped = results.where((item) => item.alreadyImported).length;
          final created = results
              .where((item) => item.noteId != null && !item.alreadyImported)
              .length;
          final notStarted = total - results.length;
          return NotesTransferResult(
            phase: notStarted == 0 && failures == 0
                ? NotesTransferPhase.completed
                : created > 0 || skipped > 0
                ? NotesTransferPhase.partial
                : cancel.cancelled
                ? NotesTransferPhase.cancelled
                : NotesTransferPhase.failed,
            created: created,
            skipped: skipped,
            failed: failures,
            notStarted: notStarted,
            items: results,
          );
        },
      ),
    );
  } on Object catch (error) {
    if (context.mounted) {
      await showBusyMarkModalDialog<void>(
        context,
        builder: (context) => BusyMarkDialogShell(
          title: context.l10n.warning,
          children: [Text(localizeNotesFailure(context, error))],
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
      BusyMarkGroupedList(
        filled: true,
        children: [
          BusyMarkActionRow(
            title: context.l10n.notesImportNew,
            onTap: () => Navigator.pop(context, ''),
          ),
          for (final operation in operations)
            BusyMarkActionRow(
              title: context.l10n.notesImportResume,
              subtitleWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BusyMarkPathLabel(path: operation['root'] as String),
                  Text(
                    notesLocalDate(
                      context,
                      DateTime.fromMillisecondsSinceEpoch(
                        (operation['created_at'] as int) * 1000,
                      ),
                    ),
                  ),
                ],
              ),
              onTap: () => Navigator.pop(context, operation['id'] as String),
            ),
        ],
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
      if (widget.review.issues.isNotEmpty) ...[
        BusyMarkStatusBox(
          message: context.l10n.notesIncomplete,
          kind: BusyMarkStatusKind.warning,
        ),
        ExpansionTile(
          title: Text(context.l10n.notesTechnicalDetails),
          children: [
            for (final issue in widget.review.issues) SelectableText(issue),
          ],
        ),
      ],
      SizedBox(
        height: (MediaQuery.sizeOf(context).height * .5).clamp(0.0, 400.0),
        child: ListView.builder(
          itemCount: widget.review.items.length,
          itemBuilder: (context, index) {
            final item = widget.review.items[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BusyMarkGroupedList(
                  filled: true,
                  children: [
                    MergeSemantics(
                      child: BusyMarkActionRow(
                        title: item.title,
                        subtitle: item.alreadyImported
                            ? context.l10n.notesImportAlreadyImported
                            : item.collision
                            ? context.l10n.notesImportDistinct
                            : item.path,
                        enabled: !item.alreadyImported,
                        leading: ExcludeFocus(
                          child: BusyMarkCheckbox(
                            value: item.selected,
                            onChanged: item.alreadyImported
                                ? null
                                : (value) => setState(
                                    () => item.selected = value ?? false,
                                  ),
                          ),
                        ),
                        onTap: item.alreadyImported
                            ? null
                            : () => setState(
                                () => item.selected = !item.selected,
                              ),
                      ),
                    ),
                    BusyMarkGroupedTextEntry(
                      label: context.l10n.syntaxReferenceCategory,
                      initialValue: item.category,
                      readOnly: item.alreadyImported,
                      onChanged: (value) => item.category = value,
                    ),
                  ],
                ),
                Text('${context.l10n.notesAttachments}: ${item.media.length}'),
                for (final reference in item.media.keys)
                  Text(reference, style: Theme.of(context).textTheme.bodySmall),
                if (item.issues.isNotEmpty) ...[
                  Text(context.l10n.notesIncomplete),
                  ExpansionTile(
                    title: Text(context.l10n.notesTechnicalDetails),
                    children: [
                      for (final issue in item.issues) SelectableText(issue),
                    ],
                  ),
                ],
                const Divider(),
              ],
            );
          },
        ),
      ),
    ],
  );
}

enum NotesTransferPhase {
  scanning,
  running,
  cancelling,
  cancelled,
  completed,
  partial,
  failed,
}

class NotesTransferResult {
  const NotesTransferResult({
    required this.phase,
    this.created = 0,
    this.skipped = 0,
    this.failed = 0,
    this.notStarted = 0,
    this.destination,
    this.omissions = const [],
    this.items = const [],
  });
  final NotesTransferPhase phase;
  final int created, skipped, failed, notStarted;
  final String? destination;
  final List<String> omissions;
  final List<NotesImportOutcome> items;
}

String _transferLabel(BuildContext context, NotesTransferPhase phase) =>
    switch (phase) {
      NotesTransferPhase.scanning => context.l10n.notesScanning,
      NotesTransferPhase.running => context.l10n.notesTransferring,
      NotesTransferPhase.cancelling => context.l10n.notesCancelling,
      NotesTransferPhase.cancelled => context.l10n.notesCancelled,
      NotesTransferPhase.completed => context.l10n.notesCompleted,
      NotesTransferPhase.partial => context.l10n.notesPartial,
      NotesTransferPhase.failed => context.l10n.notesTransferFailed,
    };

class NotesTransferProgressDialog extends StatefulWidget {
  const NotesTransferProgressDialog({
    super.key,
    required this.title,
    required this.operation,
    this.exporting = false,
  });
  final bool exporting;
  final String title;
  final Future<NotesTransferResult> Function(
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
  NotesTransferPhase _phase = NotesTransferPhase.running;
  NotesTransferResult? _result;
  @override
  void initState() {
    super.initState();
    unawaited(_run());
  }

  Future<void> _run() async {
    NotesTransferResult result;
    try {
      result = await widget.operation(_cancel, (a, b) {
        if (mounted) {
          setState(() {
            _completed = a;
            _total = b;
          });
        }
      });
    } on NotesTransferCancelled {
      result = NotesTransferResult(
        phase: NotesTransferPhase.cancelled,
        notStarted: _total - _completed,
      );
    } on Object {
      result = NotesTransferResult(
        phase: _completed > 0
            ? NotesTransferPhase.partial
            : NotesTransferPhase.failed,
        failed: 1,
        notStarted: (_total - _completed).clamp(0, _total),
      );
    }
    if (mounted) {
      setState(() {
        _result = result;
        _phase = result.phase;
      });
    }
  }

  @override
  void dispose() {
    _cancel.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return PopScope(
      canPop: result != null,
      child: BusyMarkDialogShell(
        title: widget.title,
        closable: result != null,
        actions: [
          BusyMarkDialogButton(
            label: result == null ? context.l10n.cancel : context.l10n.close,
            onPressed: _phase == NotesTransferPhase.cancelling
                ? null
                : () {
                    if (result == null) {
                      setState(() {
                        _cancel.cancel();
                        _phase = NotesTransferPhase.cancelling;
                      });
                    } else {
                      Navigator.pop(context);
                    }
                  },
          ),
        ],
        children: [
          Semantics(
            liveRegion: true,
            child: Text(_transferLabel(context, _phase)),
          ),
          if (result == null) ...[
            if (_total > 0) Text('$_completed/$_total'),
            LinearProgressIndicator(
              value: _total > 0 ? _completed / _total : null,
            ),
          ] else ...[
            if (result.destination != null) SelectableText(result.destination!),
            if (widget.exporting && result.destination == null)
              Text(context.l10n.notesExportNotPublished),
            Text(
              '${context.l10n.notesCreated}: ${result.created} · ${context.l10n.notesSkipped}: ${result.skipped} · ${context.l10n.notesFailed}: ${result.failed} · ${context.l10n.notesNotStarted}: ${result.notStarted}',
            ),
            if (result.phase == NotesTransferPhase.partial ||
                result.phase == NotesTransferPhase.cancelled)
              Text(context.l10n.notesImportPartialHelp),
            SizedBox(
              height: MediaQuery.sizeOf(context).height * .3,
              child: ListView(
                children: [
                  for (final item in result.items)
                    BusyMarkActionRow(
                      title: item.item,
                      subtitle: item.error != null
                          ? context.l10n.notesFailed
                          : item.alreadyImported
                          ? context.l10n.notesImportAlreadyImported
                          : context.l10n.nextcloudSavedLocally,
                    ),
                  for (final omission in result.omissions)
                    Text('${context.l10n.notesIncomplete}: $omission'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The review scan shares the service cancellation boundary. A cancelled scan
/// can never return a review for a later route or selection.
class NotesImportScanDialog extends StatefulWidget {
  const NotesImportScanDialog({super.key, required this.scan});
  final Future<NotesImportReview> Function(NotesTransferCancellation) scan;
  @override
  State<NotesImportScanDialog> createState() => _NotesImportScanDialogState();
}

class _NotesImportScanDialogState extends State<NotesImportScanDialog> {
  final _cancel = NotesTransferCancellation();
  NotesTransferPhase _phase = NotesTransferPhase.scanning;
  bool _settled = false;
  @override
  void initState() {
    super.initState();
    unawaited(_run());
  }

  Future<void> _run() async {
    try {
      final review = await widget.scan(_cancel);
      if (!mounted) return;
      setState(() {
        _settled = true;
        _phase = _cancel.cancelled
            ? NotesTransferPhase.cancelled
            : NotesTransferPhase.completed;
      });
      if (!_cancel.cancelled) Navigator.pop(context, review);
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _settled = true;
          _phase = error is NotesTransferCancelled
              ? NotesTransferPhase.cancelled
              : NotesTransferPhase.failed;
        });
      }
    }
  }

  @override
  void dispose() {
    _cancel.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _settled,
    child: BusyMarkDialogShell(
      title: context.l10n.notesImport,
      closable: _settled,
      actions: [
        BusyMarkDialogButton(
          label: _settled ? context.l10n.close : context.l10n.cancel,
          onPressed: _phase == NotesTransferPhase.cancelling
              ? null
              : () {
                  if (_settled) {
                    Navigator.pop(context);
                  } else {
                    setState(() {
                      _cancel.cancel();
                      _phase = NotesTransferPhase.cancelling;
                    });
                  }
                },
        ),
      ],
      children: [
        Semantics(
          liveRegion: true,
          child: Text(_transferLabel(context, _phase)),
        ),
        if (!_settled) const LinearProgressIndicator(),
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
