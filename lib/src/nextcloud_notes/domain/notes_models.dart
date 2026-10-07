import 'dart:convert';

enum NoteSyncState {
  synced,
  pending,
  syncing,
  offline,
  conflict,
  locked,
  reconnectRequired,
  forbidden,
  storageFull,
  unavailable,
  creationUncertain,
  deletedRemotely,
}

enum NoteConflictResolution { keepLocal, takeRemote, saveAsNew, merge }

enum NotesFailureCode {
  authentication,
  forbidden,
  missing,
  conflict,
  locked,
  storageFull,
  network,
  server,
  invalidResponse,
  unsupported,
  unsafeReference,
}

class NotesException implements Exception {
  const NotesException(this.code, this.message, {this.statusCode, this.remote});

  final NotesFailureCode code;
  final String message;
  final int? statusCode;
  final NoteState? remote;

  @override
  String toString() => message;
}

class NextcloudAccount {
  const NextcloudAccount({
    required this.id,
    required this.server,
    required this.loginName,
    required this.appVersion,
    this.apiVersion = '1.4',
    this.listEtag,
    this.lastModified,
  });

  final String id;
  final Uri server;
  final String loginName;
  final String appVersion;
  final String apiVersion;
  final String? listEtag;
  final String? lastModified;

  /// DELETE was added without an API capability bump (upstream #2037).
  /// Unknown/malformed/prerelease versions cannot establish support.
  bool get supportsAttachmentDeletion {
    final match = RegExp(
      r'^(\d+)\.(\d+)\.(\d+)(?:\+[0-9A-Za-z.-]+)?$',
    ).firstMatch(appVersion);
    if (match == null) return false;
    final parts = [for (var i = 1; i <= 3; i++) int.tryParse(match.group(i)!)];
    if (parts.any((part) => part == null)) return false;
    return parts[0]! > 6 || (parts[0] == 6 && parts[1]! >= 1);
  }

  NextcloudAccount withCheckpoint(String? etag, String? modified) =>
      NextcloudAccount(
        id: id,
        server: server,
        loginName: loginName,
        appVersion: appVersion,
        apiVersion: apiVersion,
        listEtag: etag,
        lastModified: modified,
      );

  Map<String, Object?> toJson() => {
    'id': id,
    'server': server.toString(),
    'loginName': loginName,
    'appVersion': appVersion,
    'apiVersion': apiVersion,
    'listEtag': listEtag,
    'lastModified': lastModified,
  };

  factory NextcloudAccount.fromJson(Map<String, dynamic> json) =>
      NextcloudAccount(
        id: json['id'] as String,
        server: Uri.parse(json['server'] as String),
        loginName: json['loginName'] as String,
        appVersion: json['appVersion'] as String,
        apiVersion: json['apiVersion'] as String? ?? '1.4',
        listEtag: json['listEtag'] as String?,
        lastModified: json['lastModified'] as String?,
      );
}

/// A complete acknowledged or conflicting server state, never editor state.
class NoteState {
  const NoteState({
    required this.id,
    required this.etag,
    required this.content,
    required this.title,
    required this.category,
    required this.favorite,
    required this.readonly,
    required this.modified,
    this.error = false,
  });

  final int id;
  final String etag;
  final String content;
  final String title;
  final String category;
  final bool favorite;
  final bool readonly;
  final int modified;
  final bool error;

  factory NoteState.fromJson(Map<String, dynamic> json) {
    if (json['id'] is! int ||
        (json['id'] as int) <= 0 ||
        json['etag'] is! String ||
        json['content'] is! String ||
        json['title'] is! String ||
        json['category'] is! String ||
        json['favorite'] is! bool ||
        json['readonly'] is! bool ||
        json['modified'] is! int) {
      throw const NotesException(
        NotesFailureCode.invalidResponse,
        'The server returned an incomplete or invalid note.',
      );
    }
    final etag = json['etag'] as String;
    if (etag.isEmpty || RegExp(r'["\x00-\x20\x7f]').hasMatch(etag)) {
      throw const NotesException(
        NotesFailureCode.invalidResponse,
        'The server returned an invalid note ETag.',
      );
    }
    final error = json['error'] == true;
    return NoteState(
      id: json['id'] as int,
      etag: etag,
      // Note.php substitutes an exception message into error-state content.
      content: error ? '' : json['content'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      favorite: json['favorite'] as bool,
      readonly: error || json['readonly'] as bool,
      modified: json['modified'] as int,
      error: error,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'etag': etag,
    'content': content,
    'title': title,
    'category': category,
    'favorite': favorite,
    'readonly': readonly,
    'modified': modified,
    'error': error,
  };
}

/// Durable evidence of one POST. Never reconstruct its payload from later edits.
class NotesCreationAttempt {
  NotesCreationAttempt({
    required this.id,
    required this.revision,
    required this.localContent,
    required this.wireBody,
    required Set<int> knownServerIds,
    Set<int> candidateServerIds = const {},
  }) : knownServerIds = Set.unmodifiable(knownServerIds),
       candidateServerIds = Set.unmodifiable(candidateServerIds);

  final String id;
  final int revision;
  final String localContent;
  final String wireBody;
  final Set<int> knownServerIds;
  final Set<int> candidateServerIds;
  Map<String, dynamic> get attributes =>
      jsonDecode(wireBody) as Map<String, dynamic>;

  bool plausiblyMatches(NoteState remote) {
    final wire = attributes;
    return !remote.error &&
        !knownServerIds.contains(remote.id) &&
        remote.content == wire['content'] &&
        remote.favorite == wire['favorite'] &&
        remote.modified == wire['modified'];
  }

  bool matches(NoteState remote) {
    final wire = attributes;
    return plausiblyMatches(remote) &&
        remote.title == wire['title'] &&
        remote.category == wire['category'];
  }

  NotesCreationAttempt withCandidateServerIds(Iterable<int> ids) =>
      NotesCreationAttempt(
        id: id,
        revision: revision,
        localContent: localContent,
        wireBody: wireBody,
        knownServerIds: knownServerIds,
        candidateServerIds: ids.toSet(),
      );

  Map<String, Object?> toJson() => {
    'id': id,
    'revision': revision,
    'localContent': localContent,
    'wireBody': wireBody,
    'knownServerIds': knownServerIds.toList(),
    'candidateServerIds': candidateServerIds.toList(),
  };
  factory NotesCreationAttempt.fromJson(Map<String, dynamic> json) =>
      NotesCreationAttempt(
        id: json['id'] as String,
        revision: json['revision'] as int,
        localContent: json['localContent'] as String,
        wireBody: json['wireBody'] as String,
        knownServerIds: (json['knownServerIds'] as List).cast<int>().toSet(),
        candidateServerIds:
            (json['candidateServerIds'] as List?)?.cast<int>().toSet() ??
            const {},
      );
}

const _unchanged = Object();

/// In-memory provenance of an editor buffer. A server observation advances the
/// generation; acknowledgments of our own writes do not. The captured server
/// state is retained until the editor revision has been stored durably.
class NotesEditorBase {
  const NotesEditorBase(this.state, this.generation);
  final NoteState? state;
  final int generation;
}

class NextcloudNote {
  const NextcloudNote({
    required this.localId,
    required this.accountId,
    this.serverId,
    required this.content,
    required this.title,
    this.category = '',
    this.favorite = false,
    this.readonly = false,
    this.error = false,
    this.modified = 0,
    this.etag,
    this.base,
    this.remote,
    this.creationAttempt,
    this.revision = 1,
    this.ackRevision = 0,
    this.editorRevision = 0,
    this.editorContentDigest,
    this.syncState = NoteSyncState.pending,
    this.errorMessage,
  });

  final String localId;
  final String accountId;
  final int? serverId;
  final String content;
  final String title;
  final String category;
  final bool favorite;
  final bool readonly;
  final bool error;
  final int modified;
  final String? etag;
  final NoteState? base;
  final NoteState? remote;
  final NotesCreationAttempt? creationAttempt;
  final int revision;
  final int ackRevision;

  /// Last accepted editor capture, independent of metadata/publication revisions.
  final int editorRevision;
  final String? editorContentDigest;
  final NoteSyncState syncState;
  final String? errorMessage;

  bool get hasPendingChanges =>
      revision > ackRevision ||
      (serverId == null && syncState != NoteSyncState.deletedRemotely);
  String get identity => 'nextcloud-note:$accountId:$localId';

  NextcloudNote copyWith({
    Object? serverId = _unchanged,
    String? content,
    String? title,
    String? category,
    bool? favorite,
    bool? readonly,
    bool? error,
    int? modified,
    Object? etag = _unchanged,
    Object? base = _unchanged,
    Object? remote = _unchanged,
    Object? creationAttempt = _unchanged,
    int? revision,
    int? ackRevision,
    int? editorRevision,
    Object? editorContentDigest = _unchanged,
    NoteSyncState? syncState,
    Object? errorMessage = _unchanged,
  }) => NextcloudNote(
    localId: localId,
    accountId: accountId,
    serverId: identical(serverId, _unchanged)
        ? this.serverId
        : serverId as int?,
    content: content ?? this.content,
    title: title ?? this.title,
    category: category ?? this.category,
    favorite: favorite ?? this.favorite,
    readonly: readonly ?? this.readonly,
    error: error ?? this.error,
    modified: modified ?? this.modified,
    etag: identical(etag, _unchanged) ? this.etag : etag as String?,
    base: identical(base, _unchanged) ? this.base : base as NoteState?,
    remote: identical(remote, _unchanged) ? this.remote : remote as NoteState?,
    creationAttempt: identical(creationAttempt, _unchanged)
        ? this.creationAttempt
        : creationAttempt as NotesCreationAttempt?,
    revision: revision ?? this.revision,
    ackRevision: ackRevision ?? this.ackRevision,
    editorRevision: editorRevision ?? this.editorRevision,
    editorContentDigest: identical(editorContentDigest, _unchanged)
        ? this.editorContentDigest
        : editorContentDigest as String?,
    syncState: syncState ?? this.syncState,
    errorMessage: identical(errorMessage, _unchanged)
        ? this.errorMessage
        : errorMessage as String?,
  );

  Map<String, Object?> toJson() => {
    'localId': localId,
    'accountId': accountId,
    'serverId': serverId,
    'content': content,
    'title': title,
    'category': category,
    'favorite': favorite,
    'readonly': readonly,
    'error': error,
    'modified': modified,
    'etag': etag,
    'base': base?.toJson(),
    'remote': remote?.toJson(),
    'creationAttempt': creationAttempt?.toJson(),
    'revision': revision,
    'ackRevision': ackRevision,
    'editorRevision': editorRevision,
    'editorContentDigest': editorContentDigest,
    'syncState': syncState.name,
    'errorMessage': errorMessage,
  };

  factory NextcloudNote.fromJson(Map<String, dynamic> json) => NextcloudNote(
    localId: json['localId'] as String,
    accountId: json['accountId'] as String,
    serverId: json['serverId'] as int?,
    content: json['content'] as String,
    title: json['title'] as String,
    category: json['category'] as String,
    favorite: json['favorite'] as bool,
    readonly: json['readonly'] as bool,
    error: json['error'] as bool? ?? false,
    modified: json['modified'] as int? ?? 0,
    etag: json['etag'] as String?,
    base: json['base'] == null
        ? null
        : NoteState.fromJson(Map<String, dynamic>.from(json['base'] as Map)),
    remote: json['remote'] == null
        ? null
        : NoteState.fromJson(Map<String, dynamic>.from(json['remote'] as Map)),
    creationAttempt: json['creationAttempt'] == null
        ? null
        : NotesCreationAttempt.fromJson(
            Map<String, dynamic>.from(json['creationAttempt'] as Map),
          ),
    revision: json['revision'] as int,
    ackRevision: json['ackRevision'] as int,
    editorRevision: json['editorRevision'] as int? ?? 0,
    editorContentDigest: json['editorContentDigest'] as String?,
    syncState: NoteSyncState.values.byName(json['syncState'] as String),
    errorMessage: json['errorMessage'] as String?,
  );

  String encode() => jsonEncode(toJson());
}

class NotesAttachment {
  const NotesAttachment({
    required this.id,
    required this.noteId,
    required this.filename,
    required this.reference,
    this.remotePath,
    this.state = 'pending',
  });

  final String id;
  final String noteId;
  final String filename;
  final String reference;
  final String? remotePath;
  final String state;

  Map<String, Object?> toJson() => {
    'id': id,
    'noteId': noteId,
    'filename': filename,
    'reference': reference,
    'remotePath': remotePath,
    'state': state,
  };

  factory NotesAttachment.fromJson(Map<String, dynamic> json) =>
      NotesAttachment(
        id: json['id'] as String,
        noteId: json['noteId'] as String,
        filename: json['filename'] as String,
        reference: json['reference'] as String,
        remotePath: json['remotePath'] as String?,
        state: json['state'] as String,
      );
}
