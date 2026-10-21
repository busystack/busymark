import 'dart:async';
import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yaru/yaru.dart';
import 'package:go_router/go_router.dart';

import '../../app/busymark_design.dart';
import '../../app/busymark_dialogs.dart';
import '../../app/busymark_glyphs.dart';
import '../../app/localization.dart';
import '../../assets/asset_ingestion_service.dart';
import '../../comparison/source_comparison.dart';
import '../../editor/document_text_direction.dart';
import '../../local_history/local_history_comparison_view.dart';
import '../../workspace/workspace_controller.dart';
import '../../workspace/workspace_message.dart';
import '../../workspace/workspace_safety.dart';
import '../application/nextcloud_connection.dart';
import '../application/notes_navigation.dart';
import 'notes_workspace_ui.dart';
import 'notes_messages.dart';
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
  NoteSyncState.storageFull => context.l10n.notesStorageFull,
  NoteSyncState.unavailable => context.l10n.notesUnavailable,
  NoteSyncState.rejected => context.l10n.notesRejected,
  NoteSyncState.throttled => context.l10n.notesThrottled,
  NoteSyncState.recoveryRequired => context.l10n.notesRecoveryRequired,
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
      NextcloudNotesSidebarState();
}

class NextcloudNotesSidebarState extends ConsumerState<NextcloudNotesSidebar> {
  late NotesNavigationController _navigation;
  late final ScrollController _listScroll;
  final _rowKeys = <String, GlobalKey>{};
  final _noteViewportKey = GlobalKey();
  final _rowFocus = <String, FocusNode>{};
  final _navigationFocus = <Object, FocusNode>{};
  List<String> _exportTargets = const [];
  String _offlineScope = '';
  StreamSubscription<void>? _notesSubscription;
  bool _ready = false;
  bool _creating = false;
  Object? _failure;
  String? _operationError;

  @override
  void initState() {
    super.initState();
    _navigation = ref.read(notesNavigationProvider(widget.accountId));
    _listScroll =
        ScrollController(initialScrollOffset: _navigation.scrollOffset)
          ..addListener(() {
            if (_listScroll.hasClients) {
              _navigation.scrollOffset = _listScroll.offset;
            }
          });
    unawaited(_initializeNavigation());
  }

  @override
  void didUpdateWidget(covariant NextcloudNotesSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accountId != widget.accountId) {
      unawaited(_notesSubscription?.cancel());
      _ready = false;
      _navigation = ref.read(notesNavigationProvider(widget.accountId));
      unawaited(_initializeNavigation());
    }
  }

  Future<void> _initializeNavigation() async {
    final accountId = widget.accountId;
    try {
      final repository = await ref.read(
        nextcloudNotesRepositoryProvider.future,
      );
      if (!mounted || accountId != widget.accountId) return;
      _navigation.update(repository.notes, accountId);
      _notesSubscription = repository.changes.listen((_) {
        if (mounted && accountId == widget.accountId) {
          setState(_refreshNavigation);
        }
      });
      setState(() {
        _ready = true;
        _failure = null;
      });
    } on Object catch (error) {
      if (mounted && accountId == widget.accountId) {
        setState(() {
          _failure = error;
          _ready = false;
        });
      }
    }
  }

  void _refreshNavigation() {
    final repository = ref.read(nextcloudNotesRepositoryProvider).value;
    if (repository != null) {
      _navigation.update(repository.notes, widget.accountId);
    }
  }

  FocusNode _focusForDestination(Object destination) =>
      _navigationFocus.putIfAbsent(destination, () => FocusNode());

  /// Enter Notes through its registered sidebar shortcut without changing the
  /// retained viewport. Prefer the previous row when it is still mounted.
  void requestNavigationFocus() {
    if (_navigation.pendingReveal != null) {
      unawaited(_revealPending(requestFocus: true));
      return;
    }
    final row = _rowFocus[_navigation.focused];
    if (row?.context != null) {
      row!.requestFocus();
    } else {
      _focusForDestination(
        _navigation.destination == NotesDestination.category
            ? _navigation.category
            : _navigation.destination,
      ).requestFocus();
    }
  }

  bool get _presented {
    var shown = true;
    context.visitAncestorElements((element) {
      if (element.widget case Offstage(offstage: true)) {
        shown = false;
        return false;
      }
      return true;
    });
    return shown;
  }

  Future<void> _revealPending({bool requestFocus = false}) async {
    final id = _navigation.pendingReveal;
    if (!mounted ||
        !_ready ||
        !_listScroll.hasClients ||
        id == null ||
        !_presented) {
      return;
    }
    await _reveal(id, requestFocus: requestFocus);
    if (mounted && _presented && _navigation.pendingReveal == id) {
      _navigation.pendingReveal = null;
    }
  }

  @override
  void dispose() {
    unawaited(_notesSubscription?.cancel());
    for (final node in _rowFocus.values) {
      node.dispose();
    }
    for (final node in _navigationFocus.values) {
      node.dispose();
    }
    _listScroll.dispose();
    super.dispose();
  }

  Future<void> _reveal(String id, {bool requestFocus = true}) async {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : BusyMarkMotion.fast;
    // Seek from the current scroll extent for distant lazy rows, then use the
    // mounted row's geometry below. No fixed row height is assumed.
    if (_listScroll.hasClients &&
        _rowKeys[id]?.currentContext == null &&
        _navigation.visible.length > 1) {
      final index = _navigation.visible.indexWhere(
        (note) => note.localId == id,
      );
      if (index < 0) return;
      _listScroll.jumpTo(
        _listScroll.position.maxScrollExtent *
            index /
            (_navigation.visible.length - 1),
      );
      await WidgetsBinding.instance.endOfFrame;
    }
    while (mounted && _listScroll.hasClients && _navigation.focused == id) {
      final target = _rowKeys[id]?.currentContext;
      if (target != null && target.mounted) {
        await Scrollable.ensureVisible(
          target,
          alignment: .5,
          duration: duration,
        );
        if (requestFocus && mounted && _navigation.focused == id) {
          _rowFocus[id]?.requestFocus();
        }
        return;
      }
      final ids = _navigation.visible.map((n) => n.localId).toList();
      final index = ids.indexOf(id);
      if (index < 0) return;
      final mountedIndices = [
        for (final entry in _rowKeys.entries)
          if (entry.value.currentContext != null) ids.indexOf(entry.key),
      ].where((i) => i >= 0).toList()..sort();
      final before = mountedIndices.isNotEmpty && index < mountedIndices.first;
      final p = _listScroll.position;
      final offset = (p.pixels + p.viewportDimension * (before ? -.8 : .8))
          .clamp(0.0, p.maxScrollExtent);
      if (offset == p.pixels) return;
      _listScroll.jumpTo(offset);
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  KeyEventResult _listKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isAltPressed || keyboard.isMetaPressed) {
      return KeyEventResult.ignored;
    }
    if (keyboard.isControlPressed &&
        event.logicalKey == LogicalKeyboardKey.keyA) {
      setState(_navigation.selectAll);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      setState(_navigation.selected.clear);
      return KeyEventResult.handled;
    }
    final visible = _navigation.visible;
    if (visible.isEmpty) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final index = visible.indexWhere((n) => n.localId == _navigation.focused);
    int? next;
    if (key == LogicalKeyboardKey.home) next = 0;
    if (key == LogicalKeyboardKey.end) next = visible.length - 1;
    if (key == LogicalKeyboardKey.arrowDown) next = index + 1;
    if (key == LogicalKeyboardKey.arrowUp) next = index - 1;
    if (key == LogicalKeyboardKey.pageDown ||
        key == LogicalKeyboardKey.pageUp) {
      // Count measured visible rows; text scaling determines the page size.
      final listBox = _noteViewportKey.currentContext?.findRenderObject();
      if (listBox is! RenderBox || !listBox.hasSize) {
        return KeyEventResult.ignored;
      }
      final origin = listBox.localToGlobal(Offset.zero).dy;
      final page = _rowKeys.values
          .where((k) {
            final box = k.currentContext?.findRenderObject();
            if (box is! RenderBox || !box.hasSize) return false;
            final top = box.localToGlobal(Offset.zero).dy;
            return top + box.size.height > origin &&
                top < origin + listBox.size.height;
          })
          .length
          .clamp(1, visible.length);
      next = index + (key == LogicalKeyboardKey.pageDown ? page : -page);
    }
    if (next != null) {
      final id = visible[next.clamp(0, visible.length - 1)].localId;
      setState(() {
        if (keyboard.isControlPressed && !keyboard.isShiftPressed) {
          _navigation.focused = id;
        } else {
          _navigation.select(
            id,
            range: keyboard.isShiftPressed,
            toggle: keyboard.isControlPressed,
          );
        }
      });
      unawaited(_reveal(id));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.space && _navigation.focused != null) {
      setState(() => _navigation.select(_navigation.focused!, toggle: true));
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _create() async {
    if (_creating) return;
    final category = _navigation.destination == NotesDestination.category
        ? _navigation.category
        : '';
    setState(() => _creating = true);
    final created = await ref
        .read(workspaceControllerProvider.notifier)
        .createNextcloudNote(
          title: context.l10n.nextcloudNewNote,
          category: category,
        );
    if (!mounted) return;
    final id = ref
        .read(workspaceControllerProvider)
        .activeBuffer
        ?.remoteNote
        ?.localId;
    setState(() {
      _creating = false;
      if (created && id != null) {
        _navigation.destination = category.isEmpty
            ? NotesDestination.all
            : NotesDestination.category;
        _navigation.category = category;
        _refreshNavigation();
        _navigation.select(id);
      }
    });
    if (created && id != null) unawaited(_reveal(id, requestFocus: false));
  }

  List<PopupMenuEntry<String>> _noteActions(
    BuildContext context,
    NextcloudNote note,
  ) {
    final targets = _navigation.contextTargets(note.localId);
    final recovery = isNotesRecovery(note);
    return [
      if (!recovery) ...[
        BusyMarkPopupMenuItem(
          value: note.favorite ? 'unfavorite' : 'favorite',
          label: note.favorite
              ? context.l10n.notesRemoveFavorite
              : context.l10n.nextcloudFavorites,
        ),
        BusyMarkPopupMenuItem(
          value: 'move',
          enabled: !note.readonly && !note.error,
          label: context.l10n.notesMove,
        ),
      ],
      if (targets.length == 1) ...[
        if (!recovery)
          BusyMarkPopupMenuItem(
            value: 'properties',
            label: context.l10n.noteProperties,
          ),
        BusyMarkPopupMenuItem(
          value: 'offline',
          label: context.l10n.notesOffline,
        ),
        if (recovery)
          BusyMarkPopupMenuItem(
            value: 'recovery',
            label: context.l10n.notesRecovery,
          ),
        if (!recovery) ...[
          BusyMarkPopupMenuItem(
            value: 'attach',
            enabled: !note.readonly && !note.error,
            label: context.l10n.nextcloudAddAttachment,
          ),
          BusyMarkPopupMenuItem(
            value: 'copy',
            label: context.l10n.nextcloudSaveLocalCopy,
          ),
          BusyMarkPopupMenuItem(
            value: 'delete',
            enabled: !note.readonly && !note.error,
            label: context.l10n.nextcloudDeleteNote,
          ),
        ],
      ],
    ];
  }

  List<NotesMetadataSnapshot> _captureTargets(NextcloudNote note) {
    final repository = ref.read(nextcloudNotesRepositoryProvider).value;
    return List.unmodifiable([
      for (final id in _navigation.contextTargets(note.localId))
        if (repository?.noteById(id) != null) repository!.metadataSnapshot(id),
    ]);
  }

  Future<void> _noteAction(
    String action,
    List<NotesMetadataSnapshot> reviewed,
  ) async {
    if (reviewed.isEmpty) return;
    final targets = reviewed.map((s) => s.note.localId).toList();
    final note = reviewed.first.note;
    if ({'favorite', 'unfavorite', 'move'}.contains(action)) {
      if (reviewed.length == 1 && action != 'move') {
        await ref
            .read(workspaceControllerProvider.notifier)
            .updateNextcloudNoteMetadata(
              targets.single,
              snapshot: reviewed.single,
              favorite: action == 'favorite',
            );
      } else {
        await showNotesBatch(
          context,
          ref,
          targets,
          initialAction: action,
          reviewedTargets: reviewed,
        );
      }
      return;
    }
    if (!mounted) return;
    switch (action) {
      case 'properties':
        await _editNote(note, reviewed: reviewed.single);
      case 'offline':
        await showNotesOffline(context, ref, note);
      case 'recovery':
        await showNotesRecovery(context, ref, note);
      case 'attach':
        await addNextcloudFileAttachment(context, ref, note.localId);
      case 'copy':
        await _saveCopy(note);
      case 'delete':
        await _deleteNote(note);
    }
  }

  Future<void> _saveCopy(NextcloudNote note) async {
    if (await ref
            .read(workspaceControllerProvider.notifier)
            .openNextcloudNote(note.localId) &&
        mounted) {
      await saveActiveToNewLocation(context, ref);
    }
  }

  Future<bool> _deleteNote(NextcloudNote note) async {
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
    return confirmed == true &&
        mounted &&
        await ref
            .read(workspaceControllerProvider.notifier)
            .deleteNextcloudNote(note.localId);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(notesNavigationProvider(widget.accountId));
    ref.listen(notesCreatedProvider, (_, created) {
      if (created == null || created.accountId != widget.accountId) return;
      final note = ref
          .read(nextcloudNotesRepositoryProvider)
          .value
          ?.noteById(created.localId);
      if (note == null) return;
      setState(() {
        _refreshNavigation();
      });
    });
    if (_ready && _navigation.pendingReveal != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_revealPending());
      });
    }
    final repositoryState = ref.watch(nextcloudNotesRepositoryProvider);
    final repository = repositoryState.value;
    final active = ref.watch(
      workspaceControllerProvider.select(
        (s) => s.activeBuffer?.remoteNote?.localId,
      ),
    );
    final offlineController = ref
        .watch(notesOfflineProvider(widget.accountId))
        .value;
    ref.watch(notesOfflineChangesProvider(widget.accountId));
    if (_failure != null || repositoryState.hasError) {
      return Column(
        children: [
          BusyMarkStatusBox(
            message: context.l10n.notesLoadFailed,
            kind: BusyMarkStatusKind.error,
          ),
          BusyMarkPushButton.standard(
            onPressed: () {
              ref.invalidate(nextcloudNotesRepositoryProvider);
              setState(() => _failure = null);
              unawaited(_initializeNavigation());
            },
            child: Text(context.l10n.visualizationRetry),
          ),
        ],
      );
    }
    if (repository == null || !_ready) {
      return const Center(child: CircularProgressIndicator());
    }
    final categories = _navigation.categoryPaths;
    final categoryRows = categories
        .where(
          (category) =>
              !_navigation.collapsed.any((p) => category.startsWith('$p/')),
        )
        .toList();
    final visible = _navigation.visible;
    final categoryScope = _navigation.destination == NotesDestination.category;
    final scope = categoryScope ? _navigation.category : '';
    String label(NotesDestination destination) => switch (destination) {
      NotesDestination.all => context.l10n.notesAll,
      NotesDestination.favorites => context.l10n.nextcloudFavorites,
      NotesDestination.uncategorized => context.l10n.notesUncategorized,
      NotesDestination.recovery => context.l10n.notesRecovery,
      NotesDestination.category => _navigation.category,
    };
    String sortLabel(NotesSort sort) => switch (sort) {
      NotesSort.recent => context.l10n.notesRecentlyEdited,
      NotesSort.oldest => context.l10n.notesOldestEdited,
      NotesSort.titleAscending => context.l10n.notesTitleAscending,
      NotesSort.titleDescending => context.l10n.notesTitleDescending,
    };
    return LayoutBuilder(
      builder: (context, constraints) => Column(
        children: [
          if (_operationError != null)
            BusyMarkStatusBox(
              message: _operationError!,
              kind: BusyMarkStatusKind.error,
            ),
          if (repository.accountError(widget.accountId) case final error?)
            BusyMarkBanner(
              title: localizeNotesFailure(context, error),
              actionLabel: error.code == NotesFailureCode.authentication
                  ? context.l10n.nextcloudReconnect
                  : null,
              onAction: error.code == NotesFailureCode.authentication
                  ? () => context.go(
                      '/settings?returnTo=workspace&page=nextcloudNotes',
                    )
                  : null,
            ),
          Padding(
            padding: const EdgeInsets.all(BusyMarkSpacing.sm),
            child: Row(
              children: [
                BusyMarkHeaderIconButton(
                  tooltip: context.l10n.nextcloudNewNote,
                  icon: BusyMarkGlyphs.add,
                  onPressed: _creating ? null : () => unawaited(_create()),
                ),
                const Spacer(),
                BusyMarkHeaderIconButton(
                  tooltip: context.l10n.tocSynchronize,
                  icon: BusyMarkGlyphs.refresh,
                  onPressed: repository.isSynchronizing(widget.accountId)
                      ? null
                      : () => unawaited(
                          ref
                              .read(workspaceControllerProvider.notifier)
                              .refreshNextcloudNotes(),
                        ),
                ),
                BusyMarkHeaderPopupMenuButton<String>(
                  tooltip: context.l10n.notesActions,
                  icon: BusyMarkGlyphs.menuVertical,
                  itemBuilder: (context) {
                    _offlineScope = scope;
                    _exportTargets = List.unmodifiable(
                      repository.notes
                          .where(
                            (n) =>
                                n.accountId == widget.accountId &&
                                !isNotesRecovery(n) &&
                                categoryIncludes(scope, n.category),
                          )
                          .map((n) => n.localId),
                    );
                    final requirement = offlineController?.requirements
                        .where(
                          (r) =>
                              r['kind'] == 'category' && r['target'] == scope,
                        )
                        .firstOrNull;
                    final scopeLabel = scope.isEmpty
                        ? context.l10n.notesAll
                        : scope;
                    final paused = requirement?['paused'] == 1;
                    return [
                      BusyMarkPopupMenuItem(
                        value: 'export',
                        label: categoryScope
                            ? '${context.l10n.notesExportCategory} · $scope'
                            : context.l10n.notesExportAll,
                      ),
                      BusyMarkPopupMenuItem(
                        value: 'import',
                        label:
                            '${context.l10n.notesImport} · ${context.l10n.folder}',
                      ),
                      BusyMarkPopupMenuItem(
                        value: 'file',
                        label:
                            '${context.l10n.notesImport} · ${context.l10n.fileTypeMarkdown}',
                      ),
                      BusyMarkPopupMenuItem(
                        value: 'offline',
                        label: categoryScope
                            ? '${context.l10n.notesOfflineCategory} · $scope'
                            : context.l10n.notesOfflineAll,
                      ),
                      BusyMarkPopupMenuItem(
                        value: 'remove',
                        label: categoryScope
                            ? '${context.l10n.notesOfflineRemoveCategory} · $scope'
                            : context.l10n.notesOfflineRemoveAll,
                      ),
                      if (requirement != null)
                        BusyMarkPopupMenuItem(
                          value: paused ? 'resumeScope' : 'pauseScope',
                          label:
                              '${paused ? context.l10n.notesResumeRequirement : context.l10n.notesPauseRequirement} · $scopeLabel',
                        ),
                      BusyMarkPopupMenuItem(
                        value: 'retryScope',
                        enabled:
                            offlineController != null &&
                            offlineController.failures.keys.any(
                              (key) => _exportTargets.any(
                                (id) => key.startsWith('$id:'),
                              ),
                            ) &&
                            (scope.isEmpty || requirement != null),
                        label:
                            '${context.l10n.visualizationRetry} · ${context.l10n.notesAttachments} · $scopeLabel',
                      ),
                    ];
                  },
                  onSelected: (action) async {
                    if (action == 'export') {
                      await showNotesExport(context, ref, _exportTargets);
                    } else if (action == 'import' || action == 'file') {
                      await showNotesImport(
                        context,
                        ref,
                        folder: action == 'import',
                      );
                    } else {
                      try {
                        final offline = await ref.read(
                          notesOfflineProvider(widget.accountId).future,
                        );
                        if (action == 'retryScope' && _offlineScope.isEmpty) {
                          await offline.retry();
                        } else {
                          await offline.setRequirement(
                            'category',
                            _offlineScope,
                            required: action != 'remove',
                            paused: action == 'pauseScope',
                          );
                        }
                      } on Object catch (error) {
                        if (mounted) {
                          setState(
                            () => _operationError = localizeNotesFailure(
                              context,
                              error,
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          SizedBox(
            height: (constraints.maxHeight * .36).clamp(0.0, 240.0),
            child: ListView.builder(
              padding: BusyMarkInsets.sidebarList,
              itemCount: categoryRows.length + 4,
              itemBuilder: (context, index) {
                if (index < 4) {
                  final destination = [
                    NotesDestination.all,
                    NotesDestination.favorites,
                    NotesDestination.uncategorized,
                    NotesDestination.recovery,
                  ][index];
                  return BusyMarkSidebarTreeRow(
                    traverseWithArrows: true,
                    key: ValueKey(destination),
                    focusNode: _focusForDestination(destination),
                    title: label(destination),
                    depth: 0,
                    selected: _navigation.destination == destination,
                    trailing: Text('${_navigation.counts[destination] ?? 0}'),
                    onTap: () => setState(() {
                      _focusForDestination(destination).requestFocus();
                      _navigation.destination = destination;
                      _refreshNavigation();
                    }),
                  );
                }
                final category = categoryRows[index - 4];
                return BusyMarkSidebarTreeRow(
                  traverseWithArrows: true,
                  key: ValueKey('notes-category-$category'),
                  focusNode: _focusForDestination(category),
                  title: category.split('/').last,
                  tooltip: category,
                  depth: category.split('/').length - 1,
                  hasChildren: categories.any(
                    (c) => c.startsWith('$category/'),
                  ),
                  expanded: !_navigation.collapsed.contains(category),
                  selected: categoryScope && category == _navigation.category,
                  trailing: Text('${_navigation.categoryCounts[category]}'),
                  onToggle: () => setState(() {
                    if (!_navigation.collapsed.remove(category)) {
                      _navigation.collapsed.add(category);
                    }
                  }),
                  onTap: () => setState(() {
                    _focusForDestination(category).requestFocus();
                    _navigation.destination = NotesDestination.category;
                    _navigation.category = category;
                    _refreshNavigation();
                  }),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: BusyMarkSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: BusyMarkPopupSelector<NotesSort>(
                    value: _navigation.sort,
                    label: sortLabel(_navigation.sort),
                    tooltip: context.l10n.notesSort,
                    fullWidth: true,
                    options: [
                      for (final sort in NotesSort.values)
                        BusyMarkPopupSelectorOption(
                          value: sort,
                          label: sortLabel(sort),
                        ),
                    ],
                    onSelected: (v) => setState(() {
                      _navigation.sort = v;
                      _refreshNavigation();
                    }),
                  ),
                ),
                if (_navigation.selected.length > 1 &&
                    _navigation.destination != NotesDestination.recovery)
                  BusyMarkCompactIconButton(
                    tooltip:
                        '${context.l10n.notesSelected} (${_navigation.selected.length})',
                    icon: BusyMarkGlyphs.menuVertical,
                    onPressed: () => unawaited(
                      showNotesBatch(
                        context,
                        ref,
                        _navigation.selected.toList(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Focus(
              key: _noteViewportKey,
              onKeyEvent: _listKey,
              child: visible.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(BusyMarkSpacing.md),
                        child: Text(switch (_navigation.destination) {
                          NotesDestination.all => context.l10n.notesEmptyAll,
                          NotesDestination.favorites =>
                            context.l10n.notesEmptyFavorites,
                          NotesDestination.category =>
                            context.l10n.notesEmptyCategory,
                          NotesDestination.uncategorized =>
                            context.l10n.notesEmptyUncategorized,
                          NotesDestination.recovery =>
                            context.l10n.notesEmptyRecovery,
                        }),
                      ),
                    )
                  : ListView.builder(
                      key: const ValueKey('nextcloud-notes-list'),
                      findChildIndexCallback: (key) {
                        if (key is! ValueKey<String>) return null;
                        final index = visible.indexWhere(
                          (note) =>
                              key.value == 'nextcloud-note-${note.localId}',
                        );
                        return index < 0 ? null : index;
                      },
                      controller: _listScroll,
                      padding: BusyMarkInsets.sidebarList,
                      itemCount: visible.length,
                      itemBuilder: (context, index) {
                        final note = visible[index];
                        return BusyMarkSidebarRecordRow<String>(
                          key: ValueKey('nextcloud-note-${note.localId}'),
                          geometryKey: _rowKeys.putIfAbsent(
                            note.localId,
                            GlobalKey.new,
                          ),
                          focusNode: _rowFocus.putIfAbsent(
                            note.localId,
                            () => FocusNode(debugLabel: 'Note ${note.localId}'),
                          ),
                          onFocusChange: (focused) {
                            if (focused) _navigation.focused = note.localId;
                          },
                          icon: active == note.localId
                              ? BusyMarkGlyphs.markdownFile
                              : note.favorite
                              ? YaruIcons.star_filled
                              : YaruIcons.document,
                          title: note.title,
                          subtitle: _metadataNeedsReview(note)
                              ? context.l10n.gitConflicts
                              : note.syncState != NoteSyncState.synced
                              ? nextcloudSyncLabel(context, note.syncState)
                              : note.category,
                          tooltip: note.title,
                          semanticsLabel:
                              '${note.title}${active == note.localId ? ' · ${context.l10n.open}' : ''}',
                          selected: _navigation.selected.contains(note.localId),
                          menuTooltip: context.l10n.noteActions,
                          menuItemsBuilder: (context) =>
                              _noteActions(context, note),
                          menuSelectionForSession: () {
                            final reviewed = _captureTargets(note);
                            return (action) =>
                                unawaited(_noteAction(action, reviewed));
                          },
                          onTap: () {
                            _rowFocus[note.localId]?.requestFocus();
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
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editNote(
    NextcloudNote note, {
    NotesMetadataSnapshot? reviewed,
  }) async {
    final repository = await ref.read(nextcloudNotesRepositoryProvider.future);
    if (!mounted || repository.noteById(note.localId) == null) return;
    final snapshot = reviewed ?? repository.metadataSnapshot(note.localId);
    note = snapshot.note;
    var title = note.title;
    var category = note.category;
    var favorite = note.favorite;
    var busy = false;
    var attachmentVersion = 0;
    String? error;
    await showBusyMarkModalDialog<void>(
      context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) {
          Future<void> run(Future<void> Function() action) async {
            if (busy) return;
            update(() {
              busy = true;
              error = null;
            });
            try {
              await action();
            } on Object catch (failure) {
              if (context.mounted) {
                update(() => error = localizeNotesFailure(context, failure));
              }
            } finally {
              if (context.mounted) update(() => busy = false);
            }
          }

          return PopScope(
            canPop: !busy,
            child: BusyMarkDialogShell(
              title: context.l10n.noteProperties,
              closable: !busy,
              actions: [
                BusyMarkDialogButton(
                  label: context.l10n.cancel,
                  onPressed: busy ? null : () => Navigator.pop(context),
                ),
                BusyMarkDialogButton(
                  label: context.l10n.save,
                  onPressed: busy
                      ? null
                      : () => unawaited(
                          run(() async {
                            final previousMessage = ref
                                .read(workspaceControllerProvider)
                                .message;
                            final success = await ref
                                .read(workspaceControllerProvider.notifier)
                                .updateNextcloudNoteMetadata(
                                  note.localId,
                                  snapshot: snapshot,
                                  title:
                                      note.readonly ||
                                          title == snapshot.note.title
                                      ? null
                                      : title,
                                  category:
                                      note.readonly ||
                                          category == snapshot.note.category
                                      ? null
                                      : category,
                                  favorite: favorite == snapshot.note.favorite
                                      ? null
                                      : favorite,
                                );
                            if (!context.mounted) return;
                            if (success) {
                              Navigator.pop(context);
                            } else {
                              final current = repository.noteById(note.localId);
                              final message = ref
                                  .read(workspaceControllerProvider)
                                  .message;
                              update(
                                () => error = current?.metadataConflict != null
                                    ? context.l10n.notesRecoveryRequired
                                    : message != null &&
                                          !identical(message, previousMessage)
                                    ? localizeNotesFailure(
                                        context,
                                        message.error,
                                      )
                                    : context.l10n.notesOperationFailed,
                              );
                            }
                          }),
                        ),
                ),
              ],
              children: [
                BusyMarkGroupedList(
                  filled: true,
                  children: [
                    BusyMarkGroupedTextEntry(
                      label: context.l10n.pdfTitlePageTitle,
                      initialValue: title,
                      textDirection: busyMarkDocumentTextDirection(
                        text: title,
                        fallback: Directionality.of(context),
                      ),
                      enabled: !busy,
                      readOnly: note.readonly,
                      onChanged: (v) => update(() => title = v),
                    ),
                    BusyMarkGroupedTextEntry(
                      label: context.l10n.syntaxReferenceCategory,
                      initialValue: category,
                      textDirection: busyMarkDocumentTextDirection(
                        text: category,
                        fallback: Directionality.of(context),
                      ),
                      enabled: !busy,
                      readOnly: note.readonly,
                      onChanged: (v) => update(() => category = v),
                    ),
                    BusyMarkSwitchRow(
                      title: context.l10n.nextcloudFavorites,
                      value: favorite,
                      enabled: !busy,
                      onChanged: (v) => update(() => favorite = v),
                    ),
                    BusyMarkActionRow(
                      title: context.l10n.nextcloudAddAttachment,
                      enabled: !busy && !note.readonly && !note.error,
                      onTap: busy || note.readonly || note.error
                          ? null
                          : () => unawaited(
                              run(() async {
                                await addNextcloudFileAttachment(
                                  context,
                                  ref,
                                  note.localId,
                                );
                                if (context.mounted) {
                                  update(() => attachmentVersion++);
                                }
                              }),
                            ),
                    ),
                    BusyMarkActionRow(
                      title: context.l10n.nextcloudSaveLocalCopy,
                      enabled: !busy,
                      onTap: busy
                          ? null
                          : () => unawaited(run(() => _saveCopy(note))),
                    ),
                    BusyMarkActionRow(
                      title: context.l10n.nextcloudDeleteNote,
                      destructive: true,
                      enabled: !busy && !note.readonly && !note.error,
                      onTap: busy || note.readonly || note.error
                          ? null
                          : () => unawaited(
                              run(() async {
                                if (await _deleteNote(note) &&
                                    context.mounted) {
                                  Navigator.pop(context);
                                }
                              }),
                            ),
                    ),
                  ],
                ),
                if (note.readonly) Text(context.l10n.notesReadOnlyHelp),
                _ManagedAttachments(
                  key: ValueKey(attachmentVersion),
                  note: repository.noteById(note.localId) ?? note,
                ),
                if (busy) const LinearProgressIndicator(),
                if (error != null)
                  Semantics(
                    liveRegion: true,
                    child: BusyMarkStatusBox(
                      message: error!,
                      kind: BusyMarkStatusKind.error,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// A durable note condition always takes precedence over account activity.
String nextcloudNoteStatusLabel(
  BuildContext context,
  NextcloudNote note, {
  bool unsaved = false,
}) {
  if (unsaved) return context.l10n.closeUnsavedChangesTitle;
  if (_metadataNeedsReview(note)) return context.l10n.gitConflicts;
  if (!{
    NoteSyncState.synced,
    NoteSyncState.pending,
    NoteSyncState.syncing,
    NoteSyncState.offline,
  }.contains(note.syncState)) {
    return nextcloudSyncLabel(context, note.syncState);
  }
  if (note.syncState == NoteSyncState.offline) {
    return '${context.l10n.notesTextAvailable}${note.hasPendingChanges ? ' · ${context.l10n.nextcloudSavedLocally}' : ''} · ${context.l10n.nextcloudOffline}';
  }
  if (note.hasPendingChanges ||
      note.syncState == NoteSyncState.pending ||
      note.syncState == NoteSyncState.syncing) {
    return context.l10n.nextcloudSavedLocally;
  }
  if (notesAttachmentReferences(
    note.content,
  ).any((r) => r.reference.startsWith('busymark-attachment:'))) {
    return context.l10n.nextcloudPendingUpload;
  }
  return nextcloudSyncLabel(context, note.syncState);
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
    final deadline = repository!.writeDeadline(note.accountId);
    final canRetry = deadline == null || !DateTime.now().isBefore(deadline);
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
                  nextcloudNoteStatusLabel(context, note, unsaved: unsaved),
                ),
              ),
              if (note.readonly) Text(context.l10n.nextcloudReadOnly),
              if (note.syncState == NoteSyncState.reconnectRequired)
                BusyMarkPushButton.standard(
                  onPressed: () => context.go(
                    '/settings?returnTo=workspace&page=nextcloudNotes',
                  ),
                  child: Text(context.l10n.nextcloudReconnect),
                ),
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
                  onPressed: !canRetry
                      ? null
                      : () => unawaited(
                          ref
                              .read(workspaceControllerProvider.notifier)
                              .refreshNextcloudNotes(),
                        ),
                  child: Text(context.l10n.visualizationRetry),
                ),
              if (note.syncState == NoteSyncState.rejected ||
                  note.syncState == NoteSyncState.storageFull)
                BusyMarkPushButton.standard(
                  onPressed: !canRetry
                      ? null
                      : () => unawaited(
                          ref
                              .read(workspaceControllerProvider.notifier)
                              .retryRejectedNextcloudNote(localId),
                        ),
                  child: Text(context.l10n.visualizationRetry),
                ),
            ],
          ),
          if (repository.isSynchronizing(note.accountId) &&
              {
                NoteSyncState.syncing,
                NoteSyncState.pending,
              }.contains(note.syncState))
            const LinearProgressIndicator(),
          if (repository.accountById(note.accountId)?.lastServerCheck
              case final checked?)
            Text(
              context.l10n.nextcloudServerCheck(
                '${MaterialLocalizations.of(context).formatShortDate(checked.toLocal())} ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(checked.toLocal()))}',
              ),
            ),
          if (note.errorMessage != null &&
              !_metadataNeedsReview(note) &&
              note.syncState != NoteSyncState.synced)
            Text(
              nextcloudSyncLabel(context, note.syncState),
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
        children: [Text(localizeNotesFailure(context, error))],
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
  var localMetadata = note.metadataConflict != null;
  var remote = note.remote;
  final creationCandidates = note.serverId == null && !localMetadata
      ? repository.uncertainCreationCandidates(note.localId)
      : const <NextcloudNote>[];
  var creationCandidateServerId = remote?.id;
  NoteState? selectedCreationRemote() {
    if (remote != null && remote!.id == creationCandidateServerId) {
      return remote;
    }
    return creationCandidates
        .where((candidate) => candidate.serverId == creationCandidateServerId)
        .map((candidate) => candidate.base)
        .whereType<NoteState>()
        .firstOrNull;
  }

  var canOverwriteRemote = localMetadata
      ? !note.readonly && !note.error
      : note.serverId != null &&
            remote != null &&
            !remote.readonly &&
            !remote.error;
  var deletedRemotely =
      note.syncState == NoteSyncState.deletedRemotely && remote == null;
  var merge = localMetadata
      ? NotesConflictMerge.metadata(note)
      : remote == null
      ? null
      : NotesConflictMerge(note, remote);
  var canMergeRemote =
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
  var busy = false;
  var needsReview = false;
  String? failure;
  void refreshReview() {
    note = repository.noteById(note.localId) ?? note;
    localMetadata = note.metadataConflict != null;
    remote = note.remote;
    deletedRemotely =
        note.syncState == NoteSyncState.deletedRemotely && remote == null;
    merge = localMetadata
        ? NotesConflictMerge.metadata(note)
        : remote == null
        ? null
        : NotesConflictMerge(note, remote!);
    canOverwriteRemote = localMetadata
        ? !note.readonly && !note.error
        : note.serverId != null &&
              remote != null &&
              !remote!.readonly &&
              !remote!.error;
    canMergeRemote =
        canOverwriteRemote ||
        (!localMetadata &&
            note.serverId != null &&
            remote != null &&
            remote!.readonly &&
            !remote!.error &&
            merge!.content.value == remote!.content &&
            merge!.title.value == remote!.title &&
            merge!.category.value == remote!.category);
    conflicts.clear();
    if (merge?.title.conflicted == true) {
      conflicts[NotesMergeAttribute.title] = merge!.title;
    }
    if (merge?.category.conflicted == true) {
      conflicts[NotesMergeAttribute.category] = merge!.category;
    }
    if (merge?.favorite.conflicted == true) {
      conflicts[NotesMergeAttribute.favorite] = merge!.favorite;
    }
    choices.clear();
    needsReview = true;
  }

  await showBusyMarkModalDialog<void>(
    context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        Future<void> apply(NoteConflictResolution? resolution) async {
          if (busy || needsReview || resolution == null) return;
          setDialogState(() {
            busy = true;
            failure = null;
          });
          try {
            if (deletedRemotely &&
                resolution == NoteConflictResolution.takeRemote) {
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
            if (!context.mounted) return;
            final selected = selectedCreationRemote();
            final review =
                resolution == NoteConflictResolution.useServerNote &&
                    selected != null
                ? NotesCreationReview(
                    localId: note.localId,
                    accountId: note.accountId,
                    attemptId: note.creationAttempt!.id,
                    revision: note.revision,
                    candidate: selected,
                  )
                : null;
            {
              final success = await ref
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
                    reviewedRemote: remote,
                  );
              if (!context.mounted) return;
              if (success) {
                Navigator.pop(context);
              } else {
                setDialogState(
                  () => failure = context.l10n.notesOperationFailed,
                );
              }
            }
          } on NotesConflictReviewChanged {
            if (context.mounted) {
              setDialogState(() {
                refreshReview();
                failure = context.l10n.notesRemoteReviewChanged;
              });
            }
          } on Object catch (error) {
            if (context.mounted) {
              setDialogState(
                () => failure = localizeNotesFailure(context, error),
              );
            }
          } finally {
            if (context.mounted) {
              setDialogState(() {
                busy = false;
              });
            }
          }
        }

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
        return PopScope(
          canPop: !busy,
          child: BusyMarkDialogShell(
            closable: !busy,
            title: context.l10n.gitConflicts,
            maxWidth: 960,
            actions:
                <BusyMarkDialogButton>[
                      BusyMarkDialogButton(
                        label: context.l10n.cancel,
                        onPressed: () => Navigator.pop(context),
                      ),
                      BusyMarkDialogButton(
                        label: note.serverId == null && !localMetadata
                            ? context.l10n.nextcloudCreateSeparate
                            : context.l10n.nextcloudNewNote,
                        onPressed: () =>
                            unawaited(apply(NoteConflictResolution.saveAsNew)),
                      ),
                      if (localMetadata)
                        BusyMarkDialogButton(
                          label: context.l10n.nextcloudUsePreviousEdit,
                          onPressed: canOverwriteRemote
                              ? () => unawaited(
                                  apply(NoteConflictResolution.takeRemote),
                                )
                              : null,
                        ),
                      if (displayedRemote != null &&
                          !displayedRemote.error &&
                          (note.serverId != null ||
                              note.creationAttempt != null))
                        BusyMarkDialogButton(
                          label: note.serverId == null
                              ? context.l10n.nextcloudUseServerNote
                              : context.l10n.nextcloudTakeRemote,
                          onPressed:
                              displayedRemote.readonly && note.serverId == null
                              ? null
                              : () => unawaited(
                                  apply(
                                    note.serverId == null
                                        ? NoteConflictResolution.useServerNote
                                        : NoteConflictResolution.takeRemote,
                                  ),
                                ),
                        ),
                      if (deletedRemotely)
                        BusyMarkDialogButton(
                          label: context.l10n.discard,
                          destructive: true,
                          onPressed: () => unawaited(
                            apply(NoteConflictResolution.takeRemote),
                          ),
                        ),

                      if (canOverwriteRemote)
                        BusyMarkDialogButton(
                          label: context.l10n.keepMine,
                          onPressed: () => unawaited(
                            apply(NoteConflictResolution.keepLocal),
                          ),
                        ),
                      if (canMergeRemote)
                        BusyMarkDialogButton(
                          label: context.l10n.nextcloudMerge,
                          onPressed: choices.length != conflicts.length
                              ? null
                              : () => unawaited(
                                  apply(NoteConflictResolution.merge),
                                ),
                        ),
                    ]
                    .map(
                      (button) => BusyMarkDialogButton(
                        label: button.label,
                        icon: button.icon,
                        destructive: button.destructive,
                        suggested: button.suggested,
                        onPressed:
                            busy ||
                                (needsReview &&
                                    button.label != context.l10n.cancel)
                            ? null
                            : button.onPressed,
                      ),
                    )
                    .toList(),
            children: [
              if (busy) const LinearProgressIndicator(),
              if (failure != null)
                BusyMarkStatusBox(
                  message: failure!,
                  kind: BusyMarkStatusKind.error,
                ),
              if (needsReview)
                BusyMarkActionRow(
                  title: context.l10n.notesReviewRemote,
                  enabled: !busy,
                  onTap: () => setDialogState(() {
                    needsReview = false;
                    failure = null;
                  }),
                ),
              if (note.errorMessage != null)
                Text(nextcloudSyncLabel(context, note.syncState)),
              if (creationCandidates.length > 1)
                BusyMarkComboRow<int?>(
                  title: context.l10n.nextcloudSelectCandidate,
                  values: [
                    null,
                    for (final candidate in creationCandidates)
                      candidate.serverId,
                  ],
                  selected: creationCandidateServerId,
                  enabled: !busy,
                  labelFor: (id) {
                    if (id == null) {
                      return context.l10n.nextcloudSelectCandidate;
                    }
                    final candidate = creationCandidates.firstWhere(
                      (c) => c.serverId == id,
                    );
                    return '${candidate.title}${candidate.category.isEmpty ? '' : ' · ${candidate.category}'} (#$id)';
                  },
                  onSelected: (value) =>
                      setDialogState(() => creationCandidateServerId = value),
                ),
              if (note.serverId == null && displayedRemote != null) ...[
                Text(
                  '#${displayedRemote.id} · ${displayedRemote.title} · ${displayedRemote.category}',
                ),
                Text(
                  notesLocalDate(
                    context,
                    DateTime.fromMillisecondsSinceEpoch(
                      displayedRemote.modified * 1000,
                    ),
                  ),
                ),
                Text(
                  note.creationAttempt?.matches(displayedRemote) == true
                      ? context.l10n.nextcloudExactCandidate
                      : context.l10n.nextcloudPossibleCandidate,
                ),
                Text(context.l10n.nextcloudUseServerNoteExplanation),
              ],
              if (note.serverId != null && !deletedRemotely)
                _UncertainAttachments(
                  note: note,
                  enabled: !busy,
                  run: (operation) async {
                    if (busy) return;
                    setDialogState(() {
                      busy = true;
                      failure = null;
                    });
                    final before = note;
                    try {
                      await operation();
                      await ref
                          .read(workspaceControllerProvider.notifier)
                          .refreshNextcloudNotes();
                      if (!context.mounted) return;
                      final after = repository.noteById(note.localId);
                      setDialogState(() {
                        if (after != null &&
                            (after.revision != before.revision ||
                                jsonEncode(after.remote?.toJson()) !=
                                    jsonEncode(before.remote?.toJson()))) {
                          refreshReview();
                          failure = context.l10n.notesRemoteReviewChanged;
                        }
                      });
                    } on Object catch (error) {
                      if (context.mounted) {
                        setDialogState(
                          () => failure = localizeNotesFailure(context, error),
                        );
                      }
                    } finally {
                      if (context.mounted) setDialogState(() => busy = false);
                    }
                  },
                ),
              SizedBox(
                height: MediaQuery.sizeOf(context).height * .3,
                child: SourceComparisonView(comparison: comparison),
              ),
              if (canMergeRemote && conflicts.isNotEmpty)
                Text(context.l10n.nextcloudChooseConflictingAttributes),
              if (canMergeRemote)
                for (final entry in conflicts.entries)
                  BusyMarkComboRow<NotesMergeChoice?>(
                    title: switch (entry.key) {
                      NotesMergeAttribute.title =>
                        context.l10n.pdfTitlePageTitle,
                      NotesMergeAttribute.category =>
                        context.l10n.syntaxReferenceCategory,
                      NotesMergeAttribute.favorite =>
                        context.l10n.nextcloudFavorites,
                    },
                    values: const [
                      null,
                      NotesMergeChoice.local,
                      NotesMergeChoice.remote,
                    ],
                    selected: choices[entry.key],
                    enabled: !busy,
                    labelFor: (choice) {
                      if (choice == null) {
                        return context
                            .l10n
                            .nextcloudChooseConflictingAttributes;
                      }
                      final value = choice == NotesMergeChoice.local
                          ? entry.value.local
                          : entry.value.remote;
                      final label = value is bool
                          ? (value
                                ? context.l10n.wsEnabled
                                : context.l10n.wsDisabled)
                          : '$value';
                      return '${choice == NotesMergeChoice.local
                          ? context.l10n.keepMine
                          : localMetadata
                          ? context.l10n.nextcloudPreviousLocalEdit
                          : context.l10n.nextcloudTakeRemote}: $label';
                    },
                    onSelected: (value) => setDialogState(() {
                      if (value == null) {
                        choices.remove(entry.key);
                      } else {
                        choices[entry.key] = value;
                      }
                    }),
                  ),
              if (canOverwriteRemote)
                BusyMarkGroupedTextEntry(
                  label: context.l10n.nextcloudMerge,
                  enabled: !busy,
                  initialValue: merged,
                  minLines: 5,
                  maxLines: 12,
                  onChanged: (value) => merged = value,
                ),
            ],
          ),
        );
      },
    ),
  );
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
  final repository = await ref.read(nextcloudNotesRepositoryProvider.future);
  await repository.retryUncertainAttachments(note.localId);
}

class _UncertainAttachments extends ConsumerStatefulWidget {
  const _UncertainAttachments({
    required this.note,
    required this.enabled,
    required this.run,
  });
  final NextcloudNote note;
  final bool enabled;
  final Future<void> Function(Future<void> Function()) run;
  @override
  ConsumerState<_UncertainAttachments> createState() =>
      _UncertainAttachmentsState();
}

class _ManagedAttachments extends ConsumerStatefulWidget {
  const _ManagedAttachments({super.key, required this.note});
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
      if (snapshot.hasError) {
        return BusyMarkActionRow(
          title: context.l10n.notesInspectionFailed,
          trailing: const Icon(BusyMarkGlyphs.refresh),
          onTap: () => setState(() => _attachments = _load()),
        );
      }
      if (attachments == null) return const LinearProgressIndicator();
      if (attachments.isEmpty) return const SizedBox.shrink();
      final account = ref
          .watch(nextcloudNotesRepositoryProvider)
          .value
          ?.accountById(widget.note.accountId);
      return Column(
        children: [
          BusyMarkGroupedList(
            filled: true,
            children: [
              for (final attachment in attachments)
                BusyMarkActionRow(
                  title: attachment.filename,
                  subtitle:
                      attachment.remotePath != null &&
                          account?.supportsAttachmentDeletion != true
                      ? context.l10n.notesRemoteDeleteUnavailable
                      : null,
                  trailing: BusyMarkCompactIconButton(
                    tooltip: context.l10n.delete,
                    icon: BusyMarkGlyphs.delete,
                    onPressed:
                        (attachment.remotePath != null &&
                                account?.supportsAttachmentDeletion != true) ||
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
      if (mounted) {
        setState(() => _error = localizeNotesFailure(context, error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _UncertainAttachmentsState extends ConsumerState<_UncertainAttachments> {
  late var _attachments = ref
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
      if (snapshot.hasError) {
        return BusyMarkActionRow(
          title: context.l10n.notesInspectionFailed,
          trailing: const Icon(BusyMarkGlyphs.refresh),
          onTap: () => setState(() {
            _attachments = ref
                .read(nextcloudNotesRepositoryProvider.future)
                .then((r) => r.attachments(widget.note.localId));
          }),
        );
      }
      if (snapshot.connectionState != ConnectionState.done) {
        return const LinearProgressIndicator();
      }
      if (pending.isEmpty) return const SizedBox.shrink();
      return BusyMarkGroupedList(
        filled: true,
        children: [
          BusyMarkGroupedTextEntry(
            label: context.l10n.nextcloudAttachmentReference,
            enabled: widget.enabled,
            onChanged: (value) => _serverReference = value,
            errorText: _error,
          ),
          for (final attachment in pending)
            BusyMarkActionRow(
              title: attachment.filename,
              trailing: BusyMarkPushButton.standard(
                child: Text(context.l10n.nextcloudTakeRemote),
                onPressed: widget.enabled
                    ? () => unawaited(_perform(() => _adopt(attachment)))
                    : null,
              ),
            ),
          BusyMarkActionRow(
            title: context.l10n.visualizationRetry,
            subtitle: context.l10n.nextcloudAttachmentRetryWarning,
            enabled: widget.enabled,
            onTap: widget.enabled
                ? () => unawaited(
                    _perform(
                      () => _retryAttachments(context, ref, widget.note),
                    ),
                  )
                : null,
          ),
        ],
      );
    },
  );
  Future<void> _perform(Future<void> Function() operation) async {
    await widget.run(operation);
    if (mounted) {
      setState(() {
        _attachments = ref
            .read(nextcloudNotesRepositoryProvider.future)
            .then((r) => r.attachments(widget.note.localId));
      });
    }
  }

  Future<void> _adopt(NotesAttachment attachment) async {
    final repository = await ref.read(nextcloudNotesRepositoryProvider.future);
    await repository.adoptUncertainAttachment(
      widget.note.localId,
      attachment.reference,
      _serverReference,
    );
  }
}
