/// Storage identity is independent of editor mode, title and cache location.
enum DocumentOrigin { untitled, localFile, nextcloudNote }

class NextcloudNoteReference {
  const NextcloudNoteReference({
    required this.accountId,
    required this.localId,
  });

  final String accountId;
  final String localId;

  String get identity => 'nextcloud-note:$accountId:$localId';

  Map<String, Object?> toJson() => {'accountId': accountId, 'localId': localId};

  static NextcloudNoteReference? fromJson(Object? value) {
    if (value is! Map) return null;
    final account = value['accountId'];
    final note = value['localId'];
    if (account is! String ||
        account.isEmpty ||
        note is! String ||
        note.isEmpty) {
      return null;
    }
    return NextcloudNoteReference(accountId: account, localId: note);
  }

  @override
  bool operator ==(Object other) =>
      other is NextcloudNoteReference &&
      accountId == other.accountId &&
      localId == other.localId;

  @override
  int get hashCode => Object.hash(accountId, localId);
}
