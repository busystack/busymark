import 'notes_models.dart';

enum NotesMergeAttribute { title, category, favorite }

enum NotesMergeChoice { local, remote }

/// Independent three-way comparison. A missing base requires a choice whenever
/// local and remote differ; it is never interpreted as unchanged local metadata.
class NotesAttributeMerge<T> {
  const NotesAttributeMerge(this.base, this.local, this.remote);
  final T? base;
  final T local;
  final T remote;
  bool get conflicted => local != remote && local != base && remote != base;
  T? get value => conflicted
      ? null
      : local == base
      ? remote
      : local;
  T resolve([NotesMergeChoice? choice]) {
    if (!conflicted) return value as T;
    if (choice == null) {
      throw const NotesException(
        NotesFailureCode.conflict,
        'Choose a local or remote value for every conflicting note attribute.',
      );
    }
    return choice == NotesMergeChoice.local ? local : remote;
  }
}

class NotesConflictMerge {
  NotesConflictMerge.metadata(NextcloudNote local)
    : content = NotesAttributeMerge(
        local.content,
        local.content,
        local.content,
      ),
      title = NotesAttributeMerge(
        local.metadataConflict!.original.title,
        local.title,
        local.metadataConflict!.alternative.title,
      ),
      category = NotesAttributeMerge(
        local.metadataConflict!.original.category,
        local.category,
        local.metadataConflict!.alternative.category,
      ),
      favorite = NotesAttributeMerge(
        local.metadataConflict!.original.favorite,
        local.favorite,
        local.metadataConflict!.alternative.favorite,
      );

  NotesConflictMerge(NextcloudNote local, NoteState remote)
    : content = NotesAttributeMerge(
        local.base?.content,
        local.content,
        remote.content,
      ),
      title = NotesAttributeMerge(local.base?.title, local.title, remote.title),
      category = NotesAttributeMerge(
        local.base?.category,
        local.category,
        remote.category,
      ),
      favorite = NotesAttributeMerge(
        local.base?.favorite,
        local.favorite,
        remote.favorite,
      );
  final NotesAttributeMerge<String> content;
  final NotesAttributeMerge<String> title;
  final NotesAttributeMerge<String> category;
  final NotesAttributeMerge<bool> favorite;
}
