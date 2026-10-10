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
  rejected,
  throttled,
  recoveryRequired,
}

enum NoteConflictResolution {
  keepLocal,
  takeRemote,
  saveAsNew,
  merge,
  useServerNote,
}

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
  rejected,
  throttled,
}

enum NotesRequestScope {
  account,
  capability,
  collection,
  settings,
  note,
  attachment,
}

class NotesException implements Exception {
  const NotesException(
    this.code,
    this.message, {
    this.statusCode,
    this.remote,
    this.scope = NotesRequestScope.note,
    this.retryNotBefore,
  });

  final NotesFailureCode code;
  final String message;
  final int? statusCode;
  final NoteState? remote;
  final NotesRequestScope scope;
  final DateTime? retryNotBefore;
  bool get retryable => {
    NotesFailureCode.network,
    NotesFailureCode.server,
    NotesFailureCode.locked,
    NotesFailureCode.throttled,
  }.contains(code);
  bool get possiblyExecuted => {
    NotesFailureCode.network,
    NotesFailureCode.server,
    NotesFailureCode.invalidResponse,
    NotesFailureCode.locked,
  }.contains(code);
  NotesException inScope(NotesRequestScope value) => NotesException(
    code,
    message,
    statusCode: statusCode,
    remote: remote,
    scope: value,
    retryNotBefore: retryNotBefore,
  );

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
    this.lastServerCheck,
    this.capabilitiesCheckedAt,
    this.apiSupported = true,
    this.settingsAttempt,
    this.throttleNotBefore,
  });

  final String id;
  final Uri server;
  final String loginName;
  final String appVersion;
  final String apiVersion;
  final String? listEtag;
  final String? lastModified;
  final DateTime? lastServerCheck;
  final DateTime? capabilitiesCheckedAt;
  final bool apiSupported;
  final NotesSettingsAttempt? settingsAttempt;
  final DateTime? throttleNotBefore;

  /// DELETE was added without an API capability bump (upstream #2037).
  /// Unknown/malformed/prerelease versions cannot establish support.
  bool get supportsAttachmentDeletion {
    if (!apiSupported) return false;
    final match = RegExp(
      r'^(\d+)\.(\d+)\.(\d+)(?:\+[0-9A-Za-z.-]+)?$',
    ).firstMatch(appVersion);
    if (match == null) return false;
    final parts = [for (var i = 1; i <= 3; i++) int.tryParse(match.group(i)!)];
    if (parts.any((part) => part == null)) return false;
    return parts[0]! > 6 || (parts[0] == 6 && parts[1]! >= 1);
  }

  NextcloudAccount copyWith({
    String? appVersion,
    String? apiVersion,
    bool? apiSupported,
    Object? listEtag = _unchanged,
    Object? lastModified = _unchanged,
    DateTime? lastServerCheck,
    DateTime? capabilitiesCheckedAt,
    Object? settingsAttempt = _unchanged,
    Object? throttleNotBefore = _unchanged,
  }) => NextcloudAccount(
    id: id,
    server: server,
    loginName: loginName,
    appVersion: appVersion ?? this.appVersion,
    apiVersion: apiVersion ?? this.apiVersion,
    apiSupported: apiSupported ?? this.apiSupported,
    listEtag: identical(listEtag, _unchanged)
        ? this.listEtag
        : listEtag as String?,
    lastModified: identical(lastModified, _unchanged)
        ? this.lastModified
        : lastModified as String?,
    lastServerCheck: lastServerCheck ?? this.lastServerCheck,
    capabilitiesCheckedAt: capabilitiesCheckedAt ?? this.capabilitiesCheckedAt,
    settingsAttempt: identical(settingsAttempt, _unchanged)
        ? this.settingsAttempt
        : settingsAttempt as NotesSettingsAttempt?,
    throttleNotBefore: identical(throttleNotBefore, _unchanged)
        ? this.throttleNotBefore
        : throttleNotBefore as DateTime?,
  );
  NextcloudAccount withCheckpoint(String? etag, String? modified) =>
      copyWith(listEtag: etag, lastModified: modified);

  Map<String, Object?> toJson() => {
    'id': id,
    'server': server.toString(),
    'loginName': loginName,
    'appVersion': appVersion,
    'apiVersion': apiVersion,
    'listEtag': listEtag,
    'lastModified': lastModified,
    'lastServerCheck': lastServerCheck?.toIso8601String(),
    'capabilitiesCheckedAt': capabilitiesCheckedAt?.toIso8601String(),
    'apiSupported': apiSupported,
    'settingsAttempt': settingsAttempt?.toJson(),
    'throttleNotBefore': throttleNotBefore?.toIso8601String(),
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
        lastServerCheck: DateTime.tryParse(
          json['lastServerCheck'] as String? ?? '',
        ),
        capabilitiesCheckedAt: DateTime.tryParse(
          json['capabilitiesCheckedAt'] as String? ?? '',
        ),
        apiSupported: json['apiSupported'] as bool? ?? true,
        settingsAttempt: json['settingsAttempt'] == null
            ? null
            : NotesSettingsAttempt.fromJson(
                Map<String, dynamic>.from(json['settingsAttempt'] as Map),
              ),
        throttleNotBefore: DateTime.tryParse(
          json['throttleNotBefore'] as String? ?? '',
        ),
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
    this.separateNoteLocalId,
  }) : knownServerIds = Set.unmodifiable(knownServerIds),
       candidateServerIds = Set.unmodifiable(candidateServerIds);

  final String id;
  final int revision;
  final String localContent;
  final String wireBody;
  final Set<int> knownServerIds;
  final Set<int> candidateServerIds;
  final String? separateNoteLocalId;
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
        separateNoteLocalId: separateNoteLocalId,
      );

  NotesCreationAttempt withSeparateNote(String localId) => NotesCreationAttempt(
    id: id,
    revision: revision,
    localContent: localContent,
    wireBody: wireBody,
    knownServerIds: knownServerIds,
    candidateServerIds: candidateServerIds,
    separateNoteLocalId: localId,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'revision': revision,
    'localContent': localContent,
    'wireBody': wireBody,
    'knownServerIds': knownServerIds.toList(),
    'candidateServerIds': candidateServerIds.toList(),
    'separateNoteLocalId': separateNoteLocalId,
  };
  factory NotesCreationAttempt.fromJson(Map<String, dynamic> json) =>
      NotesCreationAttempt(
        id: json['id'] as String,
        separateNoteLocalId: json['separateNoteLocalId'] as String?,
        revision: json['revision'] as int,
        localContent: json['localContent'] as String,
        wireBody: json['wireBody'] as String,
        knownServerIds: (json['knownServerIds'] as List).cast<int>().toSet(),
        candidateServerIds:
            (json['candidateServerIds'] as List?)?.cast<int>().toSet() ??
            const {},
      );
}

/// The immutable comparison explicitly approved by the user.
class NotesCreationReview {
  const NotesCreationReview({
    required this.localId,
    required this.accountId,
    required this.attemptId,
    required this.revision,
    required this.candidate,
  });
  final String localId;
  final String accountId;
  final String attemptId;
  final int revision;
  final NoteState candidate;
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

/// Metadata values from one accepted local edit, independent of server evidence.
class NotesMetadataValues {
  const NotesMetadataValues({
    required this.title,
    required this.category,
    required this.favorite,
  });
  factory NotesMetadataValues.fromNote(NextcloudNote note) =>
      NotesMetadataValues(
        title: note.title,
        category: note.category,
        favorite: note.favorite,
      );
  final String title;
  final String category;
  final bool favorite;
  NotesMetadataValues copyWith({
    String? title,
    String? category,
    bool? favorite,
  }) => NotesMetadataValues(
    title: title ?? this.title,
    category: category ?? this.category,
    favorite: favorite ?? this.favorite,
  );
  Map<String, Object?> toJson() => {
    'title': title,
    'category': category,
    'favorite': favorite,
  };
  factory NotesMetadataValues.fromJson(Map<String, dynamic> json) =>
      NotesMetadataValues(
        title: json['title'] as String,
        category: json['category'] as String,
        favorite: json['favorite'] as bool,
      );
}

/// Competing local properties edits. Neither side is an observation of Nextcloud.
class NotesMetadataConflict {
  const NotesMetadataConflict({
    required this.original,
    required this.alternative,
  });
  final NotesMetadataValues original;
  final NotesMetadataValues alternative;
  Map<String, Object?> toJson() => {
    'original': original.toJson(),
    'alternative': alternative.toJson(),
  };
  factory NotesMetadataConflict.fromJson(Map<String, dynamic> json) =>
      NotesMetadataConflict(
        original: NotesMetadataValues.fromJson(
          Map<String, dynamic>.from(json['original'] as Map),
        ),
        alternative: NotesMetadataValues.fromJson(
          Map<String, dynamic>.from(json['alternative'] as Map),
        ),
      );
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
    this.metadataConflict,
    this.creationAttempt,
    this.creationNeverSent = false,
    this.revision = 1,
    this.ackRevision = 0,
    this.editorRevision = 0,
    this.editorContentDigest,
    this.syncState = NoteSyncState.pending,
    this.errorMessage,
    this.localActivityMicros,
    this.failureCode,
    this.failureScope,
    this.retryNotBefore,
    this.retryCount = 0,
    this.deletionEvidence,
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
  final NotesMetadataConflict? metadataConflict;
  final NotesCreationAttempt? creationAttempt;

  /// Positive durable evidence; missing legacy metadata is not proof.
  final bool creationNeverSent;
  final int revision;
  final int ackRevision;

  /// Last accepted editor capture, independent of metadata/publication revisions.
  final int editorRevision;
  final String? editorContentDigest;
  final NoteSyncState syncState;
  final String? errorMessage;
  final int? localActivityMicros;
  final NotesFailureCode? failureCode;
  final NotesRequestScope? failureScope;
  final DateTime? retryNotBefore;
  final int retryCount;
  final String? deletionEvidence;
  int get activityMicros => localActivityMicros == null
      ? modified * 1000000
      : (localActivityMicros! > modified * 1000000
            ? localActivityMicros!
            : modified * 1000000);

  bool get hasPendingChanges =>
      metadataConflict != null ||
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
    Object? metadataConflict = _unchanged,
    Object? creationAttempt = _unchanged,
    bool? creationNeverSent,
    int? revision,
    int? ackRevision,
    int? editorRevision,
    Object? editorContentDigest = _unchanged,
    NoteSyncState? syncState,
    Object? errorMessage = _unchanged,
    Object? localActivityMicros = _unchanged,
    Object? failureCode = _unchanged,
    Object? failureScope = _unchanged,
    Object? retryNotBefore = _unchanged,
    int? retryCount,
    Object? deletionEvidence = _unchanged,
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
    metadataConflict: identical(metadataConflict, _unchanged)
        ? this.metadataConflict
        : metadataConflict as NotesMetadataConflict?,
    creationNeverSent: creationNeverSent ?? this.creationNeverSent,
    creationAttempt: identical(creationAttempt, _unchanged)
        ? this.creationAttempt
        : creationAttempt as NotesCreationAttempt?,
    revision: revision ?? this.revision,
    ackRevision: ackRevision ?? this.ackRevision,
    editorRevision: editorRevision ?? this.editorRevision,
    editorContentDigest: identical(editorContentDigest, _unchanged)
        ? this.editorContentDigest
        : editorContentDigest as String?,
    localActivityMicros: identical(localActivityMicros, _unchanged)
        ? this.localActivityMicros
        : localActivityMicros as int?,
    failureCode: identical(failureCode, _unchanged)
        ? this.failureCode
        : failureCode as NotesFailureCode?,
    failureScope: identical(failureScope, _unchanged)
        ? this.failureScope
        : failureScope as NotesRequestScope?,
    retryNotBefore: identical(retryNotBefore, _unchanged)
        ? this.retryNotBefore
        : retryNotBefore as DateTime?,
    retryCount: retryCount ?? this.retryCount,
    deletionEvidence: identical(deletionEvidence, _unchanged)
        ? this.deletionEvidence
        : deletionEvidence as String?,
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
    'metadataConflict': metadataConflict?.toJson(),
    'creationAttempt': creationAttempt?.toJson(),
    'creationNeverSent': creationNeverSent,
    'revision': revision,
    'ackRevision': ackRevision,
    'editorRevision': editorRevision,
    'editorContentDigest': editorContentDigest,
    'syncState': syncState.name,
    'errorMessage': errorMessage,
    'localActivityMicros': localActivityMicros,
    'failureCode': failureCode?.name,
    'failureScope': failureScope?.name,
    'retryNotBefore': retryNotBefore?.toIso8601String(),
    'retryCount': retryCount,
    'deletionEvidence': deletionEvidence,
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
    metadataConflict: json['metadataConflict'] == null
        ? null
        : NotesMetadataConflict.fromJson(
            Map<String, dynamic>.from(json['metadataConflict'] as Map),
          ),
    creationNeverSent: json['creationNeverSent'] == true,
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
    localActivityMicros: json['localActivityMicros'] as int?,
    failureCode: json['failureCode'] == null
        ? null
        : NotesFailureCode.values.byName(json['failureCode'] as String),
    failureScope: json['failureScope'] == null
        ? null
        : NotesRequestScope.values.byName(json['failureScope'] as String),
    retryNotBefore: DateTime.tryParse(json['retryNotBefore'] as String? ?? ''),
    retryCount: json['retryCount'] as int? ?? 0,
    deletionEvidence: json['deletionEvidence'] as String?,
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
    this.validatedAt,
  });

  final String id;
  final String noteId;
  final String filename;
  final String reference;
  final String? remotePath;
  final String state;
  final DateTime? validatedAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'noteId': noteId,
    'filename': filename,
    'reference': reference,
    'remotePath': remotePath,
    'state': state,
    'validatedAt': validatedAt?.toIso8601String(),
  };

  factory NotesAttachment.fromJson(Map<String, dynamic> json) =>
      NotesAttachment(
        id: json['id'] as String,
        noteId: json['noteId'] as String,
        filename: json['filename'] as String,
        reference: json['reference'] as String,
        remotePath: json['remotePath'] as String?,
        state: json['state'] as String,
        validatedAt: DateTime.tryParse(json['validatedAt'] as String? ?? ''),
      );
}

/// Immutable properties-dialog provenance; patches contain only edited fields.
class NotesMetadataSnapshot {
  const NotesMetadataSnapshot(this.note, this.base);
  final NextcloudNote note;
  final NotesEditorBase base;
}

class NotesSettings {
  const NotesSettings({required this.notesPath, required this.fileSuffix});
  final String notesPath;
  final String fileSuffix;
  factory NotesSettings.fromJson(dynamic json) {
    if (json is! Map ||
        json['notesPath'] is! String ||
        json['fileSuffix'] is! String) {
      throw const NotesException(
        NotesFailureCode.invalidResponse,
        'Nextcloud returned invalid Notes settings.',
        scope: NotesRequestScope.settings,
      );
    }
    return NotesSettings(
      notesPath: json['notesPath'] as String,
      fileSuffix: json['fileSuffix'] as String,
    );
  }
  Map<String, String> toJson() => {
    'notesPath': notesPath,
    'fileSuffix': fileSuffix,
  };
}

class NotesSettingsAttempt {
  NotesSettingsAttempt({
    required this.id,
    required this.original,
    required Map<String, String> patch,
  }) : patch = Map.unmodifiable(patch);
  final String id;
  final NotesSettings original;
  final Map<String, String> patch;
  Map<String, Object> toJson() => {
    'id': id,
    'original': original.toJson(),
    'patch': patch,
  };
  factory NotesSettingsAttempt.fromJson(Map<String, dynamic> json) =>
      NotesSettingsAttempt(
        id: json['id'] as String,
        original: NotesSettings.fromJson(json['original']),
        patch: Map<String, String>.from(json['patch'] as Map),
      );
}
