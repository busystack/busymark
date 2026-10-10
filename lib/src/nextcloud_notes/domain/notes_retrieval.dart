import 'notes_models.dart';

/// A validator always belongs to a complete, cached server representation.
sealed class NotesGetResult {
  const NotesGetResult();
}

final class NotesReturned extends NotesGetResult {
  const NotesReturned(this.note);
  final NoteState note;
}

final class NotesNotModified extends NotesGetResult {
  const NotesNotModified(this.cached);
  final NoteState cached;
}

/// Optional reads are deliberately separate from complete-account checkpoints.
class NotesRetrievalScope {
  NotesRetrievalScope({this.category, Set<String> exclude = const {}})
    : exclude = Set.unmodifiable(exclude) {
    if (exclude.any((field) => !fields.contains(field))) {
      throw ArgumentError('Invalid excluded Notes field.');
    }
  }

  static const fields = {
    'id',
    'etag',
    'content',
    'title',
    'category',
    'favorite',
    'readonly',
    'modified',
    'error',
  };
  final String? category;
  final Set<String> exclude;
  Map<String, String> get query => {
    if (category != null) 'category': category!,
    if (exclude.isNotEmpty) 'exclude': (exclude.toList()..sort()).join(','),
  };
}

/// Presence is retained; an omitted field has no value or fabricated default.
class NotesProjection {
  NotesProjection.fromJson(Map<String, dynamic> json)
    : values = Map.unmodifiable(json) {
    if (json.containsKey('id') &&
        (json['id'] is! int || (json['id'] as int) <= 0)) {
      throw const NotesException(
        NotesFailureCode.invalidResponse,
        'Nextcloud returned an invalid note identifier.',
      );
    }
    for (final entry in json.entries) {
      final valid = switch (entry.key) {
        'id' || 'modified' => entry.value is int,
        'etag' || 'content' || 'title' || 'category' => entry.value is String,
        'favorite' || 'readonly' || 'error' => entry.value is bool,
        _ => true,
      };
      if (!valid) {
        throw const NotesException(
          NotesFailureCode.invalidResponse,
          'Nextcloud returned an invalid projected note field.',
        );
      }
    }
  }
  final Map<String, dynamic> values;
  int? get id => values['id'] as int?;
  bool has(String field) => values.containsKey(field);
}

class NotesQueryResult {
  NotesQueryResult({required this.scope, required List<NotesProjection> notes})
    : notes = List.unmodifiable(notes);
  final NotesRetrievalScope scope;
  final List<NotesProjection> notes;
}
