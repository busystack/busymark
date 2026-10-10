import '../domain/notes_models.dart';

enum NotesDestination { all, favorites, uncategorized, category, recovery }

enum NotesSort { recent, oldest, titleAscending, titleDescending }

bool isNotesRecovery(NextcloudNote note) =>
    note.syncState == NoteSyncState.deletedRemotely && !note.hasPendingChanges;
bool categoryIncludes(String parent, String category) =>
    parent.isEmpty || parent == category || category.startsWith('$parent/');

/// Selection lives in stable local identity space, independently of open tabs.
class NotesNavigationController {
  NotesDestination destination = NotesDestination.all;
  NotesSort sort = NotesSort.recent;
  String category = '';
  final collapsed = <String>{};
  final selected = <String>{};
  String? focused;
  String? anchor;
  List<NextcloudNote> visible = const [];
  Map<String, int> categoryCounts = const {};
  List<String> categoryPaths = const [];
  Map<NotesDestination, int> counts = const {};

  void update(Iterable<NextcloudNote> notes, String accountId) {
    final scoped = notes.where((n) => n.accountId == accountId).toList();
    final live = scoped.where((n) => !isNotesRecovery(n)).toList();
    final categories = <String, int>{};
    for (final note in live) {
      final segments = note.category.split('/');
      for (var i = 1; i <= segments.length; i++) {
        final key = segments.take(i).join('/');
        if (key.isNotEmpty) categories[key] = (categories[key] ?? 0) + 1;
      }
    }
    if (destination == NotesDestination.category &&
        !categories.containsKey(category)) {
      destination = NotesDestination.all;
      category = '';
    }
    categoryCounts = Map.unmodifiable(categories);
    categoryPaths = categories.keys.toList()..sort();
    counts = {
      NotesDestination.all: live.length,
      NotesDestination.favorites: live.where((n) => n.favorite).length,
      NotesDestination.uncategorized: live
          .where((n) => n.category.isEmpty)
          .length,
      NotesDestination.recovery: scoped.where(isNotesRecovery).length,
    };
    visible =
        scoped
            .where(
              (n) => switch (destination) {
                NotesDestination.recovery => isNotesRecovery(n),
                NotesDestination.all => !isNotesRecovery(n),
                NotesDestination.favorites => !isNotesRecovery(n) && n.favorite,
                NotesDestination.uncategorized =>
                  !isNotesRecovery(n) && n.category.isEmpty,
                NotesDestination.category =>
                  !isNotesRecovery(n) && categoryIncludes(category, n.category),
              },
            )
            .toList()
          ..sort((a, b) {
            final order = switch (sort) {
              NotesSort.recent => b.activityMicros.compareTo(a.activityMicros),
              NotesSort.oldest => a.activityMicros.compareTo(b.activityMicros),
              NotesSort.titleAscending => a.title.toLowerCase().compareTo(
                b.title.toLowerCase(),
              ),
              NotesSort.titleDescending => b.title.toLowerCase().compareTo(
                a.title.toLowerCase(),
              ),
            };
            return order == 0 ? a.localId.compareTo(b.localId) : order;
          });
    // Hidden selections cannot accidentally become targets after a filter.
    selected.retainAll(visible.map((n) => n.localId));
    if (!visible.any((n) => n.localId == focused)) focused = null;
    if (!visible.any((n) => n.localId == anchor)) anchor = null;
  }

  void select(String id, {bool toggle = false, bool range = false}) {
    final ids = visible.map((n) => n.localId).toList();
    if (!ids.contains(id)) return;
    focused = id;
    if (range && anchor != null && ids.contains(anchor)) {
      final a = ids.indexOf(anchor!);
      final b = ids.indexOf(id);
      if (!toggle) selected.clear();
      selected.addAll(ids.sublist(a < b ? a : b, (a > b ? a : b) + 1));
    } else if (toggle) {
      if (!selected.remove(id)) selected.add(id);
      anchor = id;
    } else {
      selected
        ..clear()
        ..add(id);
      anchor = id;
    }
  }

  void selectAll() => selected.addAll(visible.map((n) => n.localId));
  List<String> contextTargets(String id) => selected.contains(id)
      ? visible
            .where((n) => selected.contains(n.localId))
            .map((n) => n.localId)
            .toList()
      : [id];
}

enum NotesBatchStatus { changed, skipped, conflicted, failed }

class NotesBatchOutcome {
  const NotesBatchOutcome(this.localId, this.title, this.status, [this.detail]);
  final String localId;
  final String title;
  final NotesBatchStatus status;
  final String? detail;
}
