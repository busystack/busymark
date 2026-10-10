import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yaru/yaru.dart';

import '../../app/busymark_design.dart';
import '../../app/busymark_dialogs.dart';
import '../../app/busymark_glyphs.dart';
import '../../app/localization.dart';
import '../../assets/asset_ingestion_service.dart';
import '../../comparison/source_comparison.dart';
import '../../local_history/local_history_comparison_view.dart';
import '../../workspace/workspace_controller.dart';
import '../../workspace/workspace_message.dart';
import '../../workspace/workspace_safety.dart';
import '../application/nextcloud_connection.dart';
import '../application/notes_navigation.dart';
import 'notes_workspace_ui.dart';
import '../application/attachment_markdown.dart';
import '../domain/notes_models.dart';
import '../domain/notes_conflict.dart';
import '../data/notes_attachment_references.dart';

final nextcloudNotesChangesProvider = StreamProvider<int>((ref) async* {
  final repository = await ref.watch(nextcloudNotesRepositoryProvider.future);
  var generation = 0;
  await for (final _ in repository.changes) {
    yield ++generation;
  }
});

String nextcloudSyncLabel(
  BuildContext context,
  NoteSyncState state,
) => switch (state) {
  NoteSyncState.synced => context.l10n.nextcloudSynced,
  NoteSyncState.pending => context.l10n.nextcloudSavedLocally,
  NoteSyncState.syncing => context.l10n.nextcloudSyncing,
  NoteSyncState.offline => context.l10n.nextcloudOffline,
  NoteSyncState.conflict => context.l10n.gitConflicts,
  NoteSyncState.locked => context.l10n.nextcloudLocked,
  NoteSyncState.reconnectRequired => context.l10n.nextcloudReconnectRequired,
  NoteSyncState.creationUncertain => context.l10n.nextcloudCreationUncertain,
  NoteSyncState.deletedRemotely => context.l10n.localHistoryDeleted,
  NoteSyncState.forbidden => context.l10n.nextcloudReadOnly,
  NoteSyncState.storageFull ||
  NoteSyncState.unavailable ||
  NoteSyncState.rejected ||
  NoteSyncState.throttled ||
  NoteSyncState.recoveryRequired => context.l10n.warning,
};

// Legacy response transitions may have left a transient/synchronized state
// alongside durable review evidence. That evidence still takes precedence.
bool _metadataNeedsReview(NextcloudNote note) =>
    note.metadataConflict != null &&
    {
      NoteSyncState.synced,
      NoteSyncState.pending,
      NoteSyncState.syncing,
      NoteSyncState.offline,
      NoteSyncState.locked,
      NoteSyncState.throttled,
      NoteSyncState.conflict,
    }.contains(note.syncState);

class NextcloudNotesSidebar extends ConsumerStatefulWidget {
  const NextcloudNotesSidebar({super.key, required this.accountId});
  final String accountId;
  @override
  ConsumerState<NextcloudNotesSidebar> createState() =>
      _NextcloudNotesSidebarState();
}

class _NextcloudNotesSidebarState extends ConsumerState<NextcloudNotesSidebar> {
  final _navigation = NotesNavigationController();
  final _listFocus = FocusNode();
  final _listScroll = ScrollController();
  StreamSubscription<void>? _notesSubscription;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initializeNavigation());
  }

  @override
  void didUpdateWidget(covariant NextcloudNotesSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accountId != widget.accountId) {
      unawaited(_notesSubscription?.cancel());
      _ready = false;
      unawaited(_initializeNavigation());
    }
  }

  Future<void> _initializeNavigation() async {
    final accountId = widget.accountId;
    final repository = await ref.read(nextcloudNotesRepositoryProvider.future);
    if (!mounted || accountId != widget.accountId) return;
    _navigation.update(repository.notes, widget.accountId);
    _notesSubscription = repository.changes.listen((_) {
      if (mounted) {
        setState(() => _navigation.update(repository.notes, widget.accountId));
      }
    });
    setState(() => _ready = true);
  }

  void _refreshNavigation() {
    final repository = ref.read(nextcloudNotesRepositoryProvider).value;
    if (repository != null) {
      _navigation.update(repository.notes, widget.accountId);
    }
  }

  @override
  void dispose() {
    unawaited(_notesSubscription?.cancel());
    _listFocus.dispose();
    _listScroll.dispose();
    super.dispose();
  }

  KeyEventResult _listKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isControlPressed &&
        event.logicalKey == LogicalKeyboardKey.keyA) {
      setState(_navigation.selectAll);
      return KeyEventResult.handled;
    }
    final visible = _navigation.visible;
    if (visible.isEmpty) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
        event.logicalKey == LogicalKeyboardKey.arrowUp) {
      final index = visible.indexWhere((n) => n.localId == _navigation.focused);
      final next =
          (index + (event.logicalKey == LogicalKeyboardKey.arrowDown ? 1 : -1))
              .clamp(0, visible.length - 1);
      setState(
        () => _navigation.select(
          visible[next].localId,
          range: keyboard.isShiftPressed,
          toggle: keyboard.isControlPressed,
        ),
      );
      if (_listScroll.hasClients) {
        unawaited(
          _listScroll.animateTo(
            (next * 100.0).clamp(0, _listScroll.position.maxScrollExtent),
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
          ),
        );
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.space &&
        _navigation.focused != null) {
      setState(() => _navigation.select(_navigation.focused!, toggle: true));
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter &&
        _navigation.focused != null) {
      final note = visible.firstWhere((n) => n.localId == _navigation.focused);
      unawaited(
        isNotesRecovery(note)
            ? showNotesRecovery(context, ref, note)
            : ref
                  .read(workspaceControllerProvider.notifier)
                  .openNextcloudNote(note.localId),
      );
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(nextcloudNotesRepositoryProvider).value;
    final active = ref.watch(
      workspaceControllerProvider.select(
        (s) => s.activeBuffer?.remoteNote?.localId,
      ),
    );
    final offline = ref.watch(notesOfflineProvider(widget.accountId)).value;
    ref.watch(notesOfflineChangesProvider(widget.accountId));
    if (repository == null || !_ready) {
      return const Center(child: CircularProgressIndicator());
    }
    final categories = _navigation.categoryPaths;
    final categoryRows = categories
        .where(
          (category) => !_navigation.collapsed.any(
            (parent) => category.startsWith('$parent/'),
          ),
        )
        .toList();
    final visible = _navigation.visible;
    final accountError = repository.accountError(widget.accountId);
    String destinationLabel(NotesDestination destination) =>
        switch (destination) {
          NotesDestination.all => context.l10n.notesAll,
          NotesDestination.favorites => context.l10n.nextcloudFavorites,
          NotesDestination.uncategorized => context.l10n.notesUncategorized,
          NotesDestination.recovery => context.l10n.notesRecovery,
          NotesDestination.category => _navigation.category,
        };
    return Column(
      children: [
        if (accountError != null)
          Padding(
            padding: const EdgeInsets.all(BusyMarkSpacing.sm),
            child: BusyMarkStatusBox(
              message: accountError.message,
              kind: BusyMarkStatusKind.warning,
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(BusyMarkSpacing.sm),
          child: Row(
            children: [
              Expanded(
                child: BusyMarkPushButton.standard(
                  onPressed: () => unawaited(
                    ref
                        .read(workspaceControllerProvider.notifier)
                        .createNextcloudNote(
                          title: context.l10n.nextcloudNewNote,
                          category:
                              _navigation.destination ==
                                  NotesDestination.category
                              ? _navigation.category
                              : '',
                        ),
                  ),
                  child: Text(context.l10n.nextcloudNewNote),
                ),
              ),
              IconButton(
                tooltip: context.l10n.tocSynchronize,
                icon: const Icon(BusyMarkGlyphs.refresh),
                onPressed: () => unawaited(
                  ref
                      .read(workspaceControllerProvider.notifier)
                      .refreshNextcloudNotes(),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: context.l10n.mainMenu,
                onSelected: (action) {
                  if (action == 'export') {
                    unawaited(
                      showNotesExport(
                        context,
                        ref,
                        repository.notes
                            .where(
                              (n) =>
                                  n.accountId == widget.accountId &&
                                  !isNotesRecovery(n) &&
                                  (_navigation.destination !=
                                          NotesDestination.category ||
                                      categoryIncludes(
                                        _navigation.category,
                                        n.category,
                                      )),
                            )
                            .map((n) => n.localId)
                            .toList(),
                      ),
                    );
                  }
                  if (action == 'import') {
                    unawaited(showNotesImport(context, ref));
                  }
                  if (action == 'file') {
                    unawaited(showNotesImport(context, ref, folder: false));
                  }
                  if (action == 'offline' && offline != null) {
                    unawaited(
                      offline.setRequirement(
                        'category',
                        _navigation.destination == NotesDestination.category
                            ? _navigation.category
                            : '',
                      ),
                    );
                  }
                  if (action == 'remove' && offline != null) {
                    unawaited(
                      offline.setRequirement(
                        'category',
                        _navigation.destination == NotesDestination.category
                            ? _navigation.category
                            : '',
                        required: false,
                      ),
                    );
                  }
                  if (action == 'cancel' && offline != null) {
                    unawaited(
                      offline.setRequirement(
                        'category',
                        _navigation.destination == NotesDestination.category
                            ? _navigation.category
                            : '',
                        paused: true,
                      ),
                    );
                  }
                  if (action == 'retry' && offline != null) {
                    unawaited(
                      offline.setRequirement(
                        'category',
                        _navigation.destination == NotesDestination.category
                            ? _navigation.category
                            : '',
                      ),
                    );
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'export',
                    child: Text(context.l10n.notesExport),
                  ),
                  PopupMenuItem(
                    value: 'import',
                    child: Text(
                      '${context.l10n.notesImport} · ${context.l10n.folder}',
                    ),
                  ),
                  PopupMenuItem(
                    value: 'file',
                    child: Text(
                      '${context.l10n.notesImport} · ${context.l10n.fileTypeMarkdown}',
                    ),
                  ),
                  PopupMenuItem(
                    value: 'offline',
                    child: Text(context.l10n.notesOffline),
                  ),
                  PopupMenuItem(
                    value: 'remove',
                    child: Text(context.l10n.notesOfflineRemove),
                  ),
                  PopupMenuItem(
                    value: 'cancel',
                    child: Text(context.l10n.cancel),
                  ),
                  PopupMenuItem(
                    value: 'retry',
                    child: Text(context.l10n.visualizationRetry),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: BusyMarkSpacing.sm),
          child: TextField(
            readOnly: true,
            decoration: InputDecoration(
              hintText: context.l10n.search,
              prefixIcon: const Icon(BusyMarkGlyphs.search),
            ),
            onTap: () => unawaited(
              showNotesSearch(
                context,
                ref,
                account: widget.accountId,
                recovery: _navigation.destination == NotesDestination.recovery,
              ),
            ),
          ),
        ),
        SizedBox(
          height: ((categoryRows.length + 4) * 36.0).clamp(0, 240),
          child: ListView.builder(
            itemExtent: 36,
            itemCount: categoryRows.length + 4,
            itemBuilder: (context, index) {
              if (index < 4) {
                final destination = [
                  NotesDestination.all,
                  NotesDestination.favorites,
                  NotesDestination.uncategorized,
                  NotesDestination.recovery,
                ][index];
                return ListTile(
                  dense: true,
                  minTileHeight: 36,
                  minVerticalPadding: 0,
                  selected: _navigation.destination == destination,
                  title: Text(destinationLabel(destination)),
                  trailing: Text('${_navigation.counts[destination] ?? 0}'),
                  onTap: () => setState(() {
                    _navigation.destination = destination;
                    _refreshNavigation();
                  }),
                );
              }
              final category = categoryRows[index - 4];
              return ListTile(
                dense: true,
                minTileHeight: 36,
                minVerticalPadding: 0,
                contentPadding: EdgeInsets.only(
                  left: 8 + 12.0 * (category.split('/').length - 1),
                  right: 12,
                ),
                selected:
                    _navigation.destination == NotesDestination.category &&
                    _navigation.category == category,
                leading: IconButton(
                  constraints: const BoxConstraints.tightFor(
                    width: 24,
                    height: 24,
                  ),
                  padding: EdgeInsets.zero,
                  tooltip: category,
                  icon: Icon(
                    _navigation.collapsed.contains(category)
                        ? BusyMarkGlyphs.collapsedTreeArrowFor(
                            Directionality.of(context),
                          )
                        : BusyMarkGlyphs.downArrow,
                  ),
                  onPressed: () => setState(() {
                    if (!_navigation.collapsed.remove(category)) {
                      _navigation.collapsed.add(category);
                    }
                  }),
                ),
                title: Text(
                  category.split('/').last,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text('${_navigation.categoryCounts[category]}'),
                onTap: () => setState(() {
                  _navigation.destination = NotesDestination.category;
                  _navigation.category = category;
                  _refreshNavigation();
                }),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: DropdownButton<NotesSort>(
            isExpanded: true,
            value: _navigation.sort,
            items: [
              DropdownMenuItem(
                value: NotesSort.recent,
                child: Text(context.l10n.notesRecentlyEdited),
              ),
              DropdownMenuItem(
                value: NotesSort.oldest,
                child: Text(context.l10n.notesOldestEdited),
              ),
              DropdownMenuItem(
                value: NotesSort.titleAscending,
                child: Text(context.l10n.notesTitleAscending),
              ),
              DropdownMenuItem(
                value: NotesSort.titleDescending,
                child: Text(context.l10n.notesTitleDescending),
              ),
            ],
            onChanged: (v) => setState(() {
              _navigation.sort = v!;
              _refreshNavigation();
            }),
          ),
        ),
        if (_navigation.selected.isNotEmpty &&
            _navigation.destination != NotesDestination.recovery)
          TextButton(
            onPressed: () => unawaited(
              showNotesBatch(
                context,
                ref,
                _navigation.visible
                    .where((n) => _navigation.selected.contains(n.localId))
                    .map((n) => n.localId)
                    .toList(),
              ),
            ),
            child: Text(
              '${context.l10n.notesSelected} (${_navigation.selected.length})',
            ),
          ),
        if (_navigation.destination == NotesDestination.recovery)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              context.l10n.notesRecoveryHelp,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        Expanded(
          child: Focus(
            focusNode: _listFocus,
            onKeyEvent: _listKey,
            child: visible.isEmpty
                ? Center(child: Text(context.l10n.noResults))
                : ListView.builder(
                    controller: _listScroll,
                    itemExtent: 100,
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final note = visible[index];
                      final retained = offline?.statuses[note.localId];
                      return GestureDetector(
                        onSecondaryTapDown: (details) => unawaited(
                          _contextMenu(note, details.globalPosition),
                        ),
                        child: ListTile(
                          key: ValueKey('nextcloud-note-${note.localId}'),
                          dense: true,
                          selected: _navigation.selected.contains(note.localId),
                          shape: _navigation.focused == note.localId
                              ? Border(
                                  left: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    width: 2,
                                  ),
                                )
                              : null,
                          leading: Checkbox(
                            value: _navigation.selected.contains(note.localId),
                            semanticLabel: note.title,
                            onChanged: (_) => setState(
                              () => _navigation.select(
                                note.localId,
                                toggle: true,
                              ),
                            ),
                          ),
                          title: Text(
                            note.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            [
                              note.category,
                              MaterialLocalizations.of(context).formatShortDate(
                                DateTime.fromMicrosecondsSinceEpoch(
                                  note.activityMicros,
                                ),
                              ),
                              if (_metadataNeedsReview(note))
                                context.l10n.gitConflicts
                              else if (note.syncState != NoteSyncState.synced)
                                nextcloudSyncLabel(context, note.syncState),
                              if (note.content.contains('busymark-attachment:'))
                                context.l10n.nextcloudPendingUpload,
                              if (retained != null)
                                '${retained.available ? context.l10n.notesAvailableOffline : context.l10n.notesIncomplete} ${retained.availableCount}/${retained.requiredCount}',
                            ].where((s) => s.isNotEmpty).join(' · '),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (active == note.localId)
                                Icon(
                                  BusyMarkGlyphs.markdownFile,
                                  size: 14,
                                  semanticLabel: context.l10n.open,
                                ),
                              IconButton(
                                tooltip: note.favorite
                                    ? context.l10n.notesRemoveFavorite
                                    : context.l10n.nextcloudFavorites,
                                icon: Icon(
                                  note.favorite
                                      ? YaruIcons.star_filled
                                      : YaruIcons.star,
                                  size: 16,
                                ),
                                onPressed: () => unawaited(
                                  ref
                                      .read(
                                        workspaceControllerProvider.notifier,
                                      )
                                      .updateNextcloudNoteMetadata(
                                        note.localId,
                                        snapshot: repository.metadataSnapshot(
                                          note.localId,
                                        ),
                                        favorite: !note.favorite,
                                      ),
                                ),
                              ),
                              IconButton(
                                tooltip: context.l10n.mainMenu,
                                icon: const Icon(
                                  BusyMarkGlyphs.menuVertical,
                                  size: 16,
                                ),
                                onPressed: () =>
                                    unawaited(_contextMenu(note, null)),
                              ),
                            ],
                          ),
                          onTap: () {
                            _listFocus.requestFocus();
                            final keyboard = HardwareKeyboard.instance;
                            setState(
                              () => _navigation.select(
                                note.localId,
                                toggle: keyboard.isControlPressed,
                                range: keyboard.isShiftPressed,
                              ),
                            );
                            if (!keyboard.isControlPressed &&
                                !keyboard.isShiftPressed) {
                              unawaited(
                                isNotesRecovery(note)
                                    ? showNotesRecovery(context, ref, note)
                                    : ref
                                          .read(
                                            workspaceControllerProvider
                                                .notifier,
                                          )
                                          .openNextcloudNote(note.localId),
                              );
                            }
                          },
                          onLongPress: () => unawaited(_editNote(note)),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _contextMenu(NextcloudNote note, Offset? position) async {
    final targets = _navigation.contextTargets(note.localId);
    final repository = await ref.read(nextcloudNotesRepositoryProvider.future);
    final reviewed = [
      for (final id in targets)
        if (repository.noteById(id) != null) repository.metadataSnapshot(id),
    ];
    if (!mounted) return;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final point =
        position ??
        overlay.localToGlobal(
          Offset(overlay.size.width / 2, overlay.size.height / 2),
        );
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(point.dx, point.dy, 1, 1),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          enabled: false,
          child: Text(
            targets.length > 1
                ? '${context.l10n.notesSelected} (${targets.length})'
                : note.title,
          ),
        ),
        if (!isNotesRecovery(note)) ...[
          PopupMenuItem(
            value: 'favorite',
            child: Text(context.l10n.nextcloudFavorites),
          ),
          PopupMenuItem(
            value: 'unfavorite',
            child: Text(context.l10n.notesRemoveFavorite),
          ),
          PopupMenuItem(value: 'move', child: Text(context.l10n.notesMove)),
        ],
        if (targets.length == 1) ...[
          PopupMenuItem(value: 'properties', child: Text(context.l10n.rename)),
          PopupMenuItem(
            value: 'offline',
            child: Text(context.l10n.notesOffline),
          ),
          if (isNotesRecovery(note))
            PopupMenuItem(
              value: 'recovery',
              child: Text(context.l10n.notesRecovery),
            ),
        ],
      ],
    );
    if (!mounted || action == null) return;
    if ({'favorite', 'unfavorite', 'move'}.contains(action)) {
      await showNotesBatch(
        context,
        ref,
        targets,
        initialAction: action,
        reviewedTargets: reviewed,
      );
    }
    if (action == 'properties') await _editNote(note);
    if (!mounted) return;
    if (action == 'offline') await showNotesOffline(context, ref, note);
    if (!mounted) return;
    if (action == 'recovery') await showNotesRecovery(context, ref, note);
  }

  Future<void> _editNote(NextcloudNote note) async {
    final repository = await ref.read(nextcloudNotesRepositoryProvider.future);
    if (!mounted || repository.noteById(note.localId) == null) return;
    final snapshot = repository.metadataSnapshot(note.localId);
    note = snapshot.note;
    var title = note.title;
    var category = note.category;
    var favorite = note.favorite;
    final action = await showBusyMarkModalDialog<String>(
      context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => BusyMarkDialogShell(
          title: note.title,
          actions: [
            BusyMarkDialogButton(
              label: context.l10n.cancel,
              onPressed: () => Navigator.pop(context),
            ),
            BusyMarkDialogButton(
              label: context.l10n.delete,
              destructive: true,
              onPressed: () => Navigator.pop(context, 'delete'),
            ),
            BusyMarkDialogButton(
              label: context.l10n.nextcloudSaveLocalCopy,
              onPressed: () => Navigator.pop(context, 'copy'),
            ),
            BusyMarkDialogButton(
              label: context.l10n.save,
              onPressed: () => Navigator.pop(context, 'save'),
            ),
          ],
          children: [
            BusyMarkGroupedList(
              filled: true,
              children: [
                BusyMarkGroupedTextEntry(
                  label: context.l10n.pdfTitlePageTitle,
                  initialValue: title,
                  readOnly: note.readonly,
                  onChanged: (v) => title = v,
                ),
                BusyMarkGroupedTextEntry(
                  label: context.l10n.syntaxReferenceCategory,
                  initialValue: category,
                  readOnly: note.readonly,
                  onChanged: (v) => category = v,
                ),
                CheckboxListTile(
                  title: Text(context.l10n.nextcloudFavorites),
                  value: favorite,
                  onChanged: (v) => setDialogState(() => favorite = v ?? false),
                ),
                if (!note.readonly && !note.error)
                  BusyMarkActionRow(
                    title: context.l10n.nextcloudAddAttachment,
                    onTap: () => Navigator.pop(context, 'attach'),
                  ),
              ],
            ),
            _ManagedAttachments(note: note),
            if (note.errorMessage != null) Text(note.errorMessage!),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    final controller = ref.read(workspaceControllerProvider.notifier);
    if (action == 'copy') {
      if (await controller.openNextcloudNote(note.localId) && mounted) {
        await saveActiveToNewLocation(context, ref);
      }
    } else if (action == 'attach') {
      await addNextcloudFileAttachment(context, ref, note.localId);
    } else if (action == 'save') {
      await controller.updateNextcloudNoteMetadata(
        note.localId,
        snapshot: snapshot,
        title: note.readonly || title == snapshot.note.title ? null : title,
        category: note.readonly || category == snapshot.note.category
            ? null
            : category,
        favorite: favorite == snapshot.note.favorite ? null : favorite,
      );
    } else if (action == 'delete') {
      final confirmed = await showBusyMarkModalDialog<bool>(
        context,
        builder: (context) => BusyMarkDialogShell(
          title: context.l10n.nextcloudDeleteNote,
          actions: [
            BusyMarkDialogButton(
              label: context.l10n.cancel,
              onPressed: () => Navigator.pop(context, false),
            ),
            BusyMarkDialogButton(
              label: context.l10n.delete,
              destructive: true,
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
          children: [Text(note.title)],
        ),
      );
      if (confirmed == true) await controller.deleteNextcloudNote(note.localId);
    }
  }
}

class NextcloudNoteStatus extends ConsumerWidget {
  const NextcloudNoteStatus({
    super.key,
    required this.localId,
    required this.unsaved,
  });
  final String localId;
  final bool unsaved;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(nextcloudNotesChangesProvider);
    final repository = ref.watch(nextcloudNotesRepositoryProvider).value;
    final note = repository?.noteById(localId);
    if (note == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BusyMarkSpacing.md,
        vertical: BusyMarkSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  unsaved
                      ? context.l10n.closeUnsavedChangesTitle
                      : _metadataNeedsReview(note)
                      ? context.l10n.gitConflicts
                      : repository!.isSynchronizing(note.accountId)
                      ? context.l10n.nextcloudSyncing
                      : notesAttachmentReferences(note.content).any(
                          (r) => r.reference.startsWith('busymark-attachment:'),
                        )
                      ? context.l10n.nextcloudPendingUpload
                      : nextcloudSyncLabel(context, note.syncState),
                ),
              ),
              if (note.readonly) Text(context.l10n.nextcloudReadOnly),
              if (!note.readonly && !note.error)
                IconButton(
                  tooltip: context.l10n.nextcloudAddAttachment,
                  icon: const Icon(BusyMarkGlyphs.add),
                  onPressed: () => unawaited(
                    addNextcloudFileAttachment(context, ref, note.localId),
                  ),
                ),
              if (note.metadataConflict != null ||
                  note.syncState == NoteSyncState.conflict ||
                  note.syncState == NoteSyncState.deletedRemotely ||
                  note.syncState == NoteSyncState.creationUncertain ||
                  note.syncState == NoteSyncState.recoveryRequired ||
                  ((note.syncState == NoteSyncState.forbidden ||
                          note.syncState == NoteSyncState.unavailable) &&
                      note.hasPendingChanges))
                BusyMarkPushButton.standard(
                  onPressed: () =>
                      unawaited(showNextcloudConflict(context, ref, note)),
                  child: Text(context.l10n.compare),
                ),
              if (note.syncState == NoteSyncState.locked ||
                  note.syncState == NoteSyncState.offline)
                BusyMarkPushButton.standard(
                  onPressed: () => unawaited(
                    ref
                        .read(workspaceControllerProvider.notifier)
                        .refreshNextcloudNotes(),
                  ),
                  child: Text(context.l10n.visualizationRetry),
                ),
              if (note.syncState == NoteSyncState.rejected ||
                  note.syncState == NoteSyncState.storageFull)
                BusyMarkPushButton.standard(
                  onPressed: () => unawaited(
                    ref
                        .read(workspaceControllerProvider.notifier)
                        .retryRejectedNextcloudNote(localId),
                  ),
                  child: Text(context.l10n.visualizationRetry),
                ),
            ],
          ),
          if (repository?.accountById(note.accountId)?.lastServerCheck
              case final checked?)
            Text(
              context.l10n.nextcloudServerCheck(
                '${MaterialLocalizations.of(context).formatShortDate(checked.toLocal())} ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(checked.toLocal()))}',
              ),
            ),
          if (note.errorMessage != null)
            Text(
              note.errorMessage!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}

/// The selected file is durable before its link enters the editor. Save then
/// commits the exact editor revision; HTTP upload is handled by the outbox.
Future<void> addNextcloudFileAttachment(
  BuildContext context,
  WidgetRef ref,
  String localId,
) async {
  try {
    final selected = await openFile();
    if (selected == null || !context.mounted) return;
    final length = await selected.length();
    final maximumBytes = const AssetIngestionService().maximumAssetBytes;
    if (length <= 0 || length > maximumBytes) {
      throw const AssetIngestionException(
        'asset.invalid-size',
        'The attachment is empty or exceeds the supported 100 MiB limit.',
      );
    }
    final bytes = await selected.readAsBytes();
    if (bytes.isEmpty || bytes.length > maximumBytes) {
      throw const AssetIngestionException(
        'asset.invalid-size',
        'The attachment is empty or exceeds the supported 100 MiB limit.',
      );
    }
    final controller = ref.read(workspaceControllerProvider.notifier);
    if (!await controller.openNextcloudNote(localId)) return;
    final repository = await ref.read(nextcloudNotesRepositoryProvider.future);
    final attachment = await repository.addAttachment(
      localId,
      filename: selected.name,
      bytes: bytes,
    );
    final buffer = ref.read(workspaceControllerProvider).activeBuffer;
    if (buffer?.remoteNote?.localId != localId || buffer!.readonly) {
      await repository.deleteAttachment(localId, attachment.reference);
      return;
    }
    controller.updateActiveText(
      appendNextcloudAttachmentLink(
        content: buffer.text,
        filename: selected.name,
        reference: attachment.reference,
      ),
      sourceBufferId: buffer.id,
    );
    if (!await controller.saveActive()) {
      throw const AssetIngestionException(
        'asset.note-save-failed',
        'The attachment is retained, but the note could not be saved. Keep the editor open and retry Save.',
      );
    }
  } on Object catch (error) {
    if (!context.mounted) return;
    await showBusyMarkModalDialog<void>(
      context,
      builder: (context) => BusyMarkDialogShell(
        title: context.l10n.warning,
        actions: [
          BusyMarkDialogButton(
            label: context.l10n.close,
            onPressed: () => Navigator.pop(context),
          ),
        ],
        children: [Text(error.toString())],
      ),
    );
  }
}

Future<void> showNextcloudConflict(
  BuildContext context,
  WidgetRef ref,
  NextcloudNote note,
) async {
  final workspaceState = ref.read(workspaceControllerProvider);
  if (workspaceState.documentBuffers.any(
    (buffer) => buffer.remoteNote?.localId == note.localId && buffer.isDirty,
  )) {
    final saved = await ref
        .read(workspaceControllerProvider.notifier)
        .saveAll();
    if (!saved.succeeded) return;
  }
  final repository = await ref.read(nextcloudNotesRepositoryProvider.future);
  final current = repository.noteById(note.localId);
  if (current == null || !context.mounted) return;
  note = current;
  final localMetadata = note.metadataConflict != null;
  final remote = note.remote;
  final creationCandidates = note.serverId == null && !localMetadata
      ? repository.uncertainCreationCandidates(note.localId)
      : const <NextcloudNote>[];
  var creationCandidateServerId = remote?.id;
  NoteState? selectedCreationRemote() {
    if (remote != null && remote.id == creationCandidateServerId) return remote;
    return creationCandidates
        .where((candidate) => candidate.serverId == creationCandidateServerId)
        .map((candidate) => candidate.base)
        .whereType<NoteState>()
        .firstOrNull;
  }

  final canOverwriteRemote = localMetadata
      ? !note.readonly && !note.error
      : note.serverId != null &&
            remote != null &&
            !remote.readonly &&
            !remote.error;
  final deletedRemotely =
      note.syncState == NoteSyncState.deletedRemotely && remote == null;
  final merge = localMetadata
      ? NotesConflictMerge.metadata(note)
      : remote == null
      ? null
      : NotesConflictMerge(note, remote);
  final canMergeRemote =
      canOverwriteRemote ||
      (!localMetadata &&
          note.serverId != null &&
          remote != null &&
          remote.readonly &&
          !remote.error &&
          merge!.content.value == remote.content &&
          merge.title.value == remote.title &&
          merge.category.value == remote.category);
  var merged = merge?.content.value ?? note.content;
  final choices = <NotesMergeAttribute, NotesMergeChoice>{};
  final conflicts = <NotesMergeAttribute, NotesAttributeMerge<Object>>{
    if (merge?.title.conflicted == true)
      NotesMergeAttribute.title: merge!.title,
    if (merge?.category.conflicted == true)
      NotesMergeAttribute.category: merge!.category,
    if (merge?.favorite.conflicted == true)
      NotesMergeAttribute.favorite: merge!.favorite,
  };
  final resolution = await showBusyMarkModalDialog<NoteConflictResolution>(
    context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        final displayedRemote = localMetadata
            ? null
            : note.serverId == null
            ? selectedCreationRemote()
            : remote;
        final comparison = compareSource(
          SourceComparisonInput(
            id: 'remote:${note.localId}',
            version: displayedRemote?.modified ?? 0,
            label: localMetadata
                ? context.l10n.nextcloudPreviousLocalEdit
                : context.l10n.nextcloudTakeRemote,
            source: localMetadata
                ? note.content
                : displayedRemote?.content ?? '',
          ),
          SourceComparisonInput(
            id: note.localId,
            version: note.revision,
            label: context.l10n.keepMine,
            source: note.content,
          ),
        );
        return BusyMarkDialogShell(
          title: context.l10n.gitConflicts,
          maxWidth: 960,
          actions: [
            BusyMarkDialogButton(
              label: context.l10n.cancel,
              onPressed: () => Navigator.pop(context),
            ),
            BusyMarkDialogButton(
              label: note.serverId == null && !localMetadata
                  ? context.l10n.nextcloudCreateSeparate
                  : context.l10n.nextcloudNewNote,
              onPressed: () =>
                  Navigator.pop(context, NoteConflictResolution.saveAsNew),
            ),
            if (localMetadata)
              BusyMarkDialogButton(
                label: context.l10n.nextcloudUsePreviousEdit,
                onPressed: canOverwriteRemote
                    ? () => Navigator.pop(
                        context,
                        NoteConflictResolution.takeRemote,
                      )
                    : null,
              ),
            if (displayedRemote != null &&
                !displayedRemote.error &&
                (note.serverId != null || note.creationAttempt != null))
              BusyMarkDialogButton(
                label: note.serverId == null
                    ? context.l10n.nextcloudUseServerNote
                    : context.l10n.nextcloudTakeRemote,
                onPressed: displayedRemote.readonly && note.serverId == null
                    ? null
                    : () => Navigator.pop(
                        context,
                        note.serverId == null
                            ? NoteConflictResolution.useServerNote
                            : NoteConflictResolution.takeRemote,
                      ),
              ),
            if (deletedRemotely)
              BusyMarkDialogButton(
                label: context.l10n.discard,
                destructive: true,
                onPressed: () =>
                    Navigator.pop(context, NoteConflictResolution.takeRemote),
              ),

            if (canOverwriteRemote)
              BusyMarkDialogButton(
                label: context.l10n.keepMine,
                onPressed: () =>
                    Navigator.pop(context, NoteConflictResolution.keepLocal),
              ),
            if (canMergeRemote)
              BusyMarkDialogButton(
                label: context.l10n.nextcloudMerge,
                onPressed: choices.length != conflicts.length
                    ? null
                    : () =>
                          Navigator.pop(context, NoteConflictResolution.merge),
              ),
          ],
          children: [
            if (note.errorMessage != null) Text(note.errorMessage!),
            if (creationCandidates.length > 1)
              DropdownButton<int>(
                isExpanded: true,
                value: creationCandidateServerId,
                hint: Text(context.l10n.nextcloudSelectCandidate),
                items: [
                  for (final candidate in creationCandidates)
                    DropdownMenuItem(
                      value: candidate.serverId,
                      child: Text(
                        '${candidate.title}${candidate.category.isEmpty ? '' : ' — ${candidate.category}'} (#${candidate.serverId})',
                      ),
                    ),
                ],
                onChanged: (value) => setDialogState(() {
                  creationCandidateServerId = value;
                }),
              ),
            if (note.serverId == null && displayedRemote != null) ...[
              Text(
                '#${displayedRemote.id} · ${displayedRemote.title} · ${displayedRemote.category}',
              ),
              Text(
                DateTime.fromMillisecondsSinceEpoch(
                  displayedRemote.modified * 1000,
                ).toLocal().toString(),
              ),
              Text(
                note.creationAttempt?.matches(displayedRemote) == true
                    ? context.l10n.nextcloudExactCandidate
                    : context.l10n.nextcloudPossibleCandidate,
              ),
              Text(context.l10n.nextcloudUseServerNoteExplanation),
            ],
            if (note.serverId != null && !deletedRemotely)
              _UncertainAttachments(note: note),
            SizedBox(
              height: 300,
              child: SourceComparisonView(comparison: comparison),
            ),
            if (canMergeRemote && conflicts.isNotEmpty)
              Text(context.l10n.nextcloudChooseConflictingAttributes),
            if (canMergeRemote)
              for (final entry in conflicts.entries)
                ListTile(
                  title: Text(switch (entry.key) {
                    NotesMergeAttribute.title => context.l10n.pdfTitlePageTitle,
                    NotesMergeAttribute.category =>
                      context.l10n.syntaxReferenceCategory,
                    NotesMergeAttribute.favorite =>
                      context.l10n.nextcloudFavorites,
                  }),
                  subtitle: DropdownButton<NotesMergeChoice>(
                    isExpanded: true,
                    value: choices[entry.key],
                    hint: Text(
                      context.l10n.nextcloudChooseConflictingAttributes,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: NotesMergeChoice.local,
                        child: Text(
                          '${context.l10n.keepMine}: ${entry.value.local}',
                        ),
                      ),
                      DropdownMenuItem(
                        value: NotesMergeChoice.remote,
                        child: Text(
                          '${localMetadata ? context.l10n.nextcloudPreviousLocalEdit : context.l10n.nextcloudTakeRemote}: ${entry.value.remote}',
                        ),
                      ),
                    ],
                    onChanged: (value) => setDialogState(() {
                      if (value != null) choices[entry.key] = value;
                    }),
                  ),
                ),
            if (canOverwriteRemote)
              BusyMarkGroupedTextEntry(
                label: context.l10n.nextcloudMerge,
                initialValue: merged,
                minLines: 5,
                maxLines: 12,
                onChanged: (value) => merged = value,
              ),
          ],
        );
      },
    ),
  );
  if (deletedRemotely && resolution == NoteConflictResolution.takeRemote) {
    if (!context.mounted) return;
    final confirmed = await showBusyMarkModalDialog<bool>(
      context,
      builder: (context) => BusyMarkDialogShell(
        title: context.l10n.discard,
        actions: [
          BusyMarkDialogButton(
            label: context.l10n.cancel,
            onPressed: () => Navigator.pop(context, false),
          ),
          BusyMarkDialogButton(
            label: context.l10n.discard,
            destructive: true,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
        children: [Text(note.title)],
      ),
    );
    if (confirmed != true) return;
  }
  if (note.serverId == null &&
      !localMetadata &&
      resolution == NoteConflictResolution.saveAsNew) {
    if (!context.mounted) return;
    final confirmed = await showBusyMarkModalDialog<bool>(
      context,
      builder: (context) => BusyMarkDialogShell(
        title: context.l10n.nextcloudCreateSeparate,
        actions: [
          BusyMarkDialogButton(
            label: context.l10n.cancel,
            onPressed: () => Navigator.pop(context, false),
          ),
          BusyMarkDialogButton(
            label: context.l10n.nextcloudCreateSeparate,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
        children: [Text(context.l10n.nextcloudCreateSeparateWarning)],
      ),
    );
    if (confirmed != true) return;
  }
  final selected = selectedCreationRemote();
  final review =
      resolution == NoteConflictResolution.useServerNote && selected != null
      ? NotesCreationReview(
          localId: note.localId,
          accountId: note.accountId,
          attemptId: note.creationAttempt!.id,
          revision: note.revision,
          candidate: selected,
        )
      : null;
  if (resolution != null) {
    await ref
        .read(workspaceControllerProvider.notifier)
        .resolveNextcloudConflict(
          note.localId,
          resolution,
          expectedRevision: note.revision,
          metadataChoices: choices,
          mergedContent: resolution == NoteConflictResolution.merge
              ? merged
              : null,
          creationCandidateServerId: creationCandidateServerId,
          creationReview: review,
        );
  }
}

Future<void> _retryAttachments(
  BuildContext context,
  WidgetRef ref,
  NextcloudNote note,
) async {
  final confirmed = await showBusyMarkModalDialog<bool>(
    context,
    builder: (context) => BusyMarkDialogShell(
      title: context.l10n.visualizationRetry,
      actions: [
        BusyMarkDialogButton(
          label: context.l10n.cancel,
          onPressed: () => Navigator.pop(context, false),
        ),
        BusyMarkDialogButton(
          label: context.l10n.visualizationRetry,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
      children: [Text(context.l10n.nextcloudAttachmentRetryWarning)],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  try {
    final repository = await ref.read(nextcloudNotesRepositoryProvider.future);
    await repository.retryUncertainAttachments(note.localId);
    await ref
        .read(workspaceControllerProvider.notifier)
        .refreshNextcloudNotes();
    if (context.mounted) Navigator.pop(context);
  } on Object catch (error) {
    if (!context.mounted) return;
    await showBusyMarkModalDialog<void>(
      context,
      builder: (context) => BusyMarkDialogShell(
        title: context.l10n.warning,
        actions: [
          BusyMarkDialogButton(
            label: context.l10n.close,
            onPressed: () => Navigator.pop(context),
          ),
        ],
        children: [Text(error.toString())],
      ),
    );
  }
}

class _UncertainAttachments extends ConsumerStatefulWidget {
  const _UncertainAttachments({required this.note});
  final NextcloudNote note;
  @override
  ConsumerState<_UncertainAttachments> createState() =>
      _UncertainAttachmentsState();
}

class _ManagedAttachments extends ConsumerStatefulWidget {
  const _ManagedAttachments({required this.note});
  final NextcloudNote note;
  @override
  ConsumerState<_ManagedAttachments> createState() =>
      _ManagedAttachmentsState();
}

class _ManagedAttachmentsState extends ConsumerState<_ManagedAttachments> {
  late Future<List<NotesAttachment>> _attachments = _load();
  String? _error;
  bool _busy = false;
  Future<List<NotesAttachment>> _load() => ref
      .read(nextcloudNotesRepositoryProvider.future)
      .then((repository) => repository.attachments(widget.note.localId));

  @override
  Widget build(BuildContext context) => FutureBuilder<List<NotesAttachment>>(
    future: _attachments,
    builder: (context, snapshot) {
      final attachments = snapshot.data
          ?.where((a) => a.state != 'deleted')
          .toList();
      if (attachments == null || attachments.isEmpty) {
        return const SizedBox.shrink();
      }
      return Column(
        children: [
          BusyMarkGroupedList(
            filled: true,
            children: [
              for (final attachment in attachments)
                BusyMarkActionRow(
                  title: attachment.filename,
                  trailing: IconButton(
                    tooltip: context.l10n.delete,
                    icon: const Icon(BusyMarkGlyphs.delete),
                    onPressed:
                        _busy ||
                            widget.note.readonly ||
                            widget.note.error ||
                            attachment.state == 'uploading' ||
                            attachment.state == 'uncertain' ||
                            attachment.state == 'deletePending' ||
                            (attachment.remotePath == null &&
                                widget.note.content.contains(
                                  attachment.reference,
                                ))
                        ? null
                        : () => unawaited(_delete(attachment)),
                  ),
                ),
            ],
          ),
          if (_error != null)
            BusyMarkStatusBox(message: _error!, kind: BusyMarkStatusKind.error),
        ],
      );
    },
  );

  Future<void> _delete(NotesAttachment attachment) async {
    final confirmed = await showBusyMarkModalDialog<bool>(
      context,
      builder: (context) => BusyMarkDialogShell(
        title: attachment.filename,
        actions: [
          BusyMarkDialogButton(
            label: context.l10n.cancel,
            onPressed: () => Navigator.pop(context, false),
          ),
          BusyMarkDialogButton(
            label: context.l10n.delete,
            destructive: true,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
        children: [Text(context.l10n.nextcloudDeleteAttachmentWarning)],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final controller = ref.read(workspaceControllerProvider.notifier);
      final deleted = await controller.deleteNextcloudAttachment(
        widget.note.localId,
        attachment.reference,
      );
      if (!deleted && mounted) {
        final message = ref.read(workspaceControllerProvider).message;
        setState(
          () => _error = message == null
              ? context.l10n.warning
              : localizeWorkspaceMessage(context, message),
        );
      }
      if (mounted) setState(() => _attachments = _load());
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _UncertainAttachmentsState extends ConsumerState<_UncertainAttachments> {
  late final _attachments = ref
      .read(nextcloudNotesRepositoryProvider.future)
      .then((repository) => repository.attachments(widget.note.localId));
  String _serverReference = '';
  String? _error;
  @override
  Widget build(BuildContext context) => FutureBuilder<List<NotesAttachment>>(
    future: _attachments,
    builder: (context, snapshot) {
      final pending =
          snapshot.data
              ?.where((a) => a.state == 'uncertain' || a.state == 'uploading')
              .toList() ??
          [];
      if (pending.isEmpty) return const SizedBox.shrink();
      return BusyMarkGroupedList(
        filled: true,
        children: [
          BusyMarkGroupedTextEntry(
            label: context.l10n.nextcloudAttachmentReference,
            onChanged: (value) => _serverReference = value,
            errorText: _error,
          ),
          for (final attachment in pending)
            BusyMarkActionRow(
              title: attachment.filename,
              trailing: BusyMarkPushButton.standard(
                child: Text(context.l10n.nextcloudTakeRemote),
                onPressed: () => unawaited(_adopt(attachment)),
              ),
            ),
          BusyMarkActionRow(
            title: context.l10n.visualizationRetry,
            subtitle: context.l10n.nextcloudAttachmentRetryWarning,
            onTap: () =>
                unawaited(_retryAttachments(context, ref, widget.note)),
          ),
        ],
      );
    },
  );
  Future<void> _adopt(NotesAttachment attachment) async {
    try {
      final repository = await ref.read(
        nextcloudNotesRepositoryProvider.future,
      );
      await repository.adoptUncertainAttachment(
        widget.note.localId,
        attachment.reference,
        _serverReference,
      );
      await ref
          .read(workspaceControllerProvider.notifier)
          .refreshNextcloudNotes();
      if (mounted) Navigator.pop(context);
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }
}
