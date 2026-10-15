import 'dart:isolate';

import '../nextcloud_notes/domain/notes_search.dart';

class QuickOpenDocument {
  const QuickOpenDocument({
    required this.title,
    required this.path,
    this.localId,
    this.filePath,
  });
  final String title, path;
  final String? localId, filePath;
  String get identity => localId ?? filePath!;
}

List<QuickOpenDocument> rankQuickOpen(
  List<QuickOpenDocument> documents,
  String query, {
  int limit = 100,
}) {
  final normalized = normalizeNotesSearch(query.trim());
  final ranked = <({QuickOpenDocument document, String title, int rank})>[];
  for (final document in documents) {
    final title = normalizeNotesSearch(document.title);
    final rank = normalized.isEmpty || title == normalized
        ? 0
        : title.startsWith(normalized)
        ? 1
        : title.contains(normalized)
        ? 2
        : normalizeNotesSearch(document.path).contains(normalized)
        ? 3
        : 4;
    if (rank < 4) ranked.add((document: document, title: title, rank: rank));
  }
  ranked.sort((a, b) {
    final rank = a.rank.compareTo(b.rank);
    if (rank != 0) return rank;
    final title = a.title.compareTo(b.title);
    if (title != 0) return title;
    final path = a.document.path.compareTo(b.document.path);
    return path != 0
        ? path
        : a.document.identity.compareTo(b.document.identity);
  });
  return ranked.take(limit).map((r) => r.document).toList();
}

/// A top-level isolate boundary prevents a search controller's subscriptions
/// and futures from being captured by a ranking closure.
Future<List<QuickOpenDocument>> rankQuickOpenAsync(
  List<QuickOpenDocument> documents,
  String query, {
  int limit = 100,
}) => Isolate.run(() => rankQuickOpen(documents, query, limit: limit));
