import 'dart:async';
import 'dart:isolate';

import '../data/notes_store.dart';
import '../domain/notes_search.dart';

class NotesSearchOverlay {
  const NotesSearchOverlay(
    this.localId,
    this.revision,
    this.title,
    this.category,
    this.source,
  );
  final String localId, title, category, source;
  final int revision;
}

class NotesSearchState {
  const NotesSearchState({
    this.hits = const [],
    this.loading = false,
    this.indexing = false,
    this.truncated = false,
    this.error,
  });
  final List<NotesSearchHit> hits;
  final bool loading, indexing, truncated;
  final Object? error;
}

/// One bounded query workflow for the Notes sidebar and workspace command.
class NotesSearchController {
  NotesSearchController(this.store, this.accountId, {this.recovery = false});
  final NotesStore store;
  final String accountId;
  final bool recovery;
  final _changes = StreamController<NotesSearchState>.broadcast();
  Stream<NotesSearchState> get changes => _changes.stream;
  NotesSearchState state = const NotesSearchState();
  int _generation = 0;
  bool _disposed = false;
  void _publish(NotesSearchState value) {
    if (!_disposed) {
      state = value;
      _changes.add(value);
    }
  }

  void cancel() {
    _generation++;
  }

  Future<void> search(
    String text, {
    bool wholeWord = false,
    int limit = 80,
    List<NotesSearchOverlay> overlays = const [],
  }) async {
    final generation = ++_generation;
    bool current() => !_disposed && generation == _generation;
    _publish(const NotesSearchState(loading: true, indexing: true));
    try {
      final query = NotesSearchQuery(text, wholeWord: wholeWord);
      while (await store.indexStep() != 0) {
        if (!current()) return;
      }
      if (!current()) return;
      _publish(const NotesSearchState(loading: true));
      final hits = await _searchOverlays(
        query,
        recovery ? const [] : overlays,
        limit + 1,
      );
      var after = 0;
      Map<String, dynamic>? continuation;
      var more = true;
      while (more && hits.length <= limit) {
        if (!current()) return;
        final chunk = await store.searchChunk(
          accountId,
          query,
          after: after,
          continuation: continuation,
          recovery: recovery,
          limit: limit + 1 - hits.length,
          exclude: recovery ? const {} : overlays.map((o) => o.localId).toSet(),
        );
        hits.addAll(
          (chunk['hits'] as List).map(
            (h) => NotesSearchHit.fromJson(Map<String, dynamic>.from(h as Map)),
          ),
        );
        after = chunk['after'] as int;
        more = chunk['more'] as bool;
        continuation = chunk['continuation'] == null
            ? null
            : Map<String, dynamic>.from(chunk['continuation'] as Map);
      }
      if (!current()) return;
      hits.sort((a, b) {
        final title = a.title.toLowerCase().compareTo(b.title.toLowerCase());
        if (title != 0) return title;
        final id = a.localId.compareTo(b.localId);
        if (id != 0) return id;
        final start = (a.start ?? -1).compareTo(b.start ?? -1);
        return start != 0 ? start : (a.end ?? -1).compareTo(b.end ?? -1);
      });
      _publish(
        NotesSearchState(
          hits: List.unmodifiable(hits.take(limit)),
          truncated: hits.length > limit || more,
        ),
      );
    } on Object catch (error) {
      if (current()) _publish(NotesSearchState(error: error));
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    _generation++;
    await _changes.close();
  }
}

Future<List<NotesSearchHit>> _searchOverlays(
  NotesSearchQuery query,
  List<NotesSearchOverlay> overlays,
  int limit,
) => Isolate.run(() {
  final hits = <NotesSearchHit>[];
  for (final overlay in overlays) {
    hits.addAll(
      matchNotesDocument(
        query: query,
        localId: overlay.localId,
        revision: overlay.revision,
        title: overlay.title,
        category: overlay.category,
        source: overlay.source,
        limit: limit - hits.length,
      ),
    );
    if (hits.length == limit) break;
  }
  return hits;
});

/// Navigation after an edit searches through bounded occurrence pages instead
/// of relocating a late result to one of the first page's unrelated ranges.
Future<NotesSearchHit?> relocateNotesSearchHit(
  NotesSearchQuery query,
  NotesSearchOverlay document,
  int nearOffset,
) => Isolate.run(() {
  NotesSearchHit? nearest;
  var start = -1, end = -1;
  while (true) {
    final page = matchNotesDocument(
      query: query,
      localId: document.localId,
      revision: document.revision,
      title: document.title,
      category: document.category,
      source: document.source,
      limit: 200,
      afterStart: start,
      afterEnd: end,
    );
    for (final hit in page) {
      if (nearest == null ||
          ((hit.start ?? 0) - nearOffset).abs() <
              ((nearest.start ?? 0) - nearOffset).abs()) {
        nearest = hit;
      }
    }
    if (page.isEmpty ||
        page.length < 200 ||
        (page.last.start ?? 0) >= nearOffset) {
      return nearest;
    }
    start = page.last.start!;
    end = page.last.end!;
  }
});
