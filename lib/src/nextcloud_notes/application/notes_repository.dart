import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../data/notes_api_client.dart';
import '../data/notes_attachment_references.dart';
import '../data/notes_store.dart';
import '../domain/notes_models.dart';
import '../domain/notes_conflict.dart';

/// Owns local durability and ordinary optimistic synchronization separately.
class NotesRepository {
  NotesRepository({
    required this.store,
    required Future<NotesApiClient> Function(NextcloudAccount) clientForAccount,
  }) : _clientForAccount = clientForAccount;

  final NotesStore store;
  final Future<NotesApiClient> Function(NextcloudAccount) _clientForAccount;
  final _changes = StreamController<void>.broadcast();
  final _accounts = <String, NextcloudAccount>{};
  final _notes = <String, NextcloudNote>{};
  final _listedIds = <String, Set<int>>{};
  final _baseGenerations = <String, int>{};
  final _mediaResolutions = <String, Future<String?>>{};
  final _mediaVersions = <String, int>{};
  int mediaVersion(String localId) => _mediaVersions[localId] ?? 0;

  final _publishedReferences = <String, Map<String, String>>{};
  final _accountErrors = <String, NotesException>{};
  final _syncs = <String, Future<void>>{};
  final _removing = <String>{};
  final _creationResolutions = <String>{};
  final _bindingCandidates = <String>{};
  final _creationBindingGuards = <bool Function(String, Set<String>)>{};

  /// Every controller registers its open tabs, including unsaved candidate tabs.
  void addCreationBindingGuard(bool Function(String, Set<String>) guard) =>
      _creationBindingGuards.add(guard);
  void removeCreationBindingGuard(bool Function(String, Set<String>) guard) =>
      _creationBindingGuards.remove(guard);
  bool isCreationCandidateBinding(String localId) =>
      _bindingCandidates.contains(localId);

  NotesCreationReview creationReview(String localId, NoteState candidate) {
    final note = _require(localId);
    final attempt = note.creationAttempt;
    if (note.serverId != null ||
        note.syncState != NoteSyncState.creationUncertain ||
        attempt == null ||
        !attempt.candidateServerIds.contains(candidate.id)) {
      throw const NotesException(
        NotesFailureCode.conflict,
        'Refresh and review the uncertain creation again.',
      );
    }
    return NotesCreationReview(
      localId: localId,
      accountId: note.accountId,
      attemptId: attempt.id,
      revision: note.revision,
      candidate: candidate,
    );
  }

  final _uuid = const Uuid();
  Future<void> _mutations = Future.value();
  Future<void>? _initialization;
  bool _disposed = false;
  Future<void>? _disposing;

  List<NextcloudAccount> get accounts => List.unmodifiable(_accounts.values);
  List<NextcloudNote> get notes => List.unmodifiable(_notes.values);
  Stream<void> get changes => _changes.stream;
  NextcloudAccount? accountById(String id) => _accounts[id];
  NextcloudNote? noteById(String id) => _notes[id];
  NotesEditorBase editorBase(String id) =>
      NotesEditorBase(_require(id).base, _baseGenerations[id] ?? 0);
  NotesException? accountError(String accountId) => _accountErrors[accountId];
  Future<List<NotesAttachment>> attachments(String localId) =>
      store.attachments(localId);

  List<NextcloudNote> uncertainCreationCandidates(String localId) {
    final note = _require(localId);
    final ids = note.creationAttempt?.candidateServerIds ?? const <int>{};
    return List.unmodifiable(
      _notes.values.where(
        (candidate) =>
            candidate.accountId == note.accountId &&
            candidate.serverId != null &&
            ids.contains(candidate.serverId),
      ),
    );
  }

  Future<void> initialize() => _initialization ??= _initialize();
  Future<void> _initialize() async {
    for (final account in await store.accounts()) {
      _accounts[account.id] = account;
    }
    for (final note in await store.notes()) {
      _notes[note.localId] = note;
    }
    for (final attachment in await store.attachments()) {
      if (attachment.remotePath != null &&
          attachment.reference.startsWith('busymark-attachment:')) {
        (_publishedReferences[attachment.noteId] ??= {})[attachment.reference] =
            attachmentMarkdownReference(attachment.remotePath!);
      }
    }
  }

  /// Rebase only BusyMark staging references; ordinary editor text is untouched.
  String resolvePublishedReferences(String localId, String content) {
    final mappings = _publishedReferences[localId] ?? const <String, String>{};
    // Namespace strings can be ordinary prose or code. Rebase destinations
    // only, including a restored-reference → staging → publication chain.
    if (!mappings.keys.any(content.contains)) return content;
    final resolved = <String, String>{};
    for (final entry in mappings.entries) {
      var destination = entry.value;
      final visited = {entry.key};
      while (destination.startsWith('busymark-attachment:') &&
          mappings.containsKey(destination) &&
          visited.add(destination)) {
        destination = mappings[destination]!;
      }
      resolved[entry.key] = destination;
    }
    return replaceNotesAttachmentReferences(
      content,
      notesAttachmentReferences(content),
      resolved,
    );
  }

  Future<T> _mutate<T>(Future<T> Function() action) {
    final result = _mutations.then((_) => action());
    _mutations = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  void _notify() {
    if (!_disposed) _changes.add(null);
  }

  NextcloudNote _require(String localId) =>
      _notes[localId] ??
      (throw const NotesException(
        NotesFailureCode.missing,
        'This note is no longer available.',
      ));

  Future<void> upsertAccount(NextcloudAccount account) async {
    await initialize();
    _validateId(account.id);
    await _mutate(() async {
      await store.saveAccount(account);
      _accounts[account.id] = account;
      _notify();
    });
  }

  Future<NextcloudNote> create(
    String accountId, {
    String title = 'New note',
    String category = '',
    String content = '',
  }) async {
    await initialize();
    if (!_accounts.containsKey(accountId) || _removing.contains(accountId)) {
      throw const NotesException(
        NotesFailureCode.authentication,
        'Connect a Nextcloud account first.',
      );
    }
    return _mutate(() async {
      final note = NextcloudNote(
        localId: _uuid.v4(),
        accountId: accountId,
        title: title,
        category: category,
        content: content,
      );
      await store.saveNote(note);
      _notes[note.localId] = note;
      _notify();
      return note;
    });
  }

  /// Resolves only after the exact editor revision and its outbox are committed.
  Future<NextcloudNote> save(
    String localId, {
    required String content,
    int? editorRevision,
    NotesEditorBase? editBase,
    String? title,
    String? category,
    bool? favorite,
  }) => _mutate(() async {
    var current = _require(localId);
    final digest = sha256.convert(utf8.encode(content)).toString();
    if (editorRevision != null &&
        (editorRevision < current.editorRevision ||
            (editorRevision == current.editorRevision &&
                digest == current.editorContentDigest))) {
      return current;
    }
    content = resolvePublishedReferences(localId, content);
    final restoration = await _prepareDeletedReferences(current, content);
    content = restoration.content;
    final contentChanged = current.content != content;
    final metadataChanged =
        (title != null && title != current.title) ||
        (category != null && category != current.category);
    final newlyForbidden =
        (current.readonly || current.error) &&
        (contentChanged || metadataChanged);
    if (newlyForbidden &&
        editorRevision == null &&
        (contentChanged || metadataChanged)) {
      throw const NotesException(
        NotesFailureCode.forbidden,
        'This Nextcloud note is read-only.',
      );
    }
    if (!contentChanged &&
        !metadataChanged &&
        (favorite == null || favorite == current.favorite)) {
      return current;
    }
    if (editBase != null &&
        editBase.generation != (_baseGenerations[localId] ?? 0) &&
        editBase.state?.etag != current.etag &&
        current.syncState != NoteSyncState.deletedRemotely) {
      // A download may have committed before the editor's debounce. Preserve
      // all three states instead of uploading that edit against the new ETag.
      current = current.copyWith(
        base: editBase.state,
        etag: editBase.state?.etag,
        remote: current.remote ?? current.base,
        syncState: NoteSyncState.conflict,
        errorMessage:
            'The note changed on Nextcloud while editor changes were unsaved.',
      );
    }
    final blocked = {
      NoteSyncState.conflict,
      NoteSyncState.creationUncertain,
      NoteSyncState.deletedRemotely,
    }.contains(current.syncState);
    final revision = editorRevision != null && editorRevision > current.revision
        ? editorRevision
        : current.revision + 1;
    final saved = current.copyWith(
      content: content,
      title: title,
      category: category,
      favorite: favorite,
      revision: revision,
      editorRevision: editorRevision ?? current.editorRevision,
      editorContentDigest: editorRevision == null
          ? current.editorContentDigest
          : digest,
      syncState: blocked
          ? current.syncState
          : newlyForbidden
          ? NoteSyncState.forbidden
          : NoteSyncState.pending,
      errorMessage: blocked
          ? current.errorMessage
          : newlyForbidden
          ? 'Nextcloud became read-only after editing. Your local revision is preserved; recover it as a new note.'
          : null,
    );
    if (restoration.attachments.isEmpty) {
      await store.saveNote(saved);
    } else {
      // The rewritten edit, attachment bytes and its outbox are one durability
      // boundary for undo, source, AI and history restoration alike.
      await store.createWithAttachments(saved, restoration.attachments);
    }
    (_publishedReferences[localId] ??= {}).addAll(restoration.references);
    _notes[localId] = saved;
    _notify();
    return saved;
  });

  Future<void> synchronize(String accountId) {
    if (_disposed || _removing.contains(accountId)) return Future.value();
    final existing = _syncs[accountId];
    if (existing != null) return existing;
    final future = _synchronize(accountId);
    _syncs[accountId] = future;
    future.then<void>(
      (_) {
        _syncs.remove(accountId);
      },
      onError: (Object _, StackTrace _) {
        _syncs.remove(accountId);
      },
    );
    return future;
  }

  Future<void> _synchronize(String accountId) async {
    await initialize();
    final account = _accounts[accountId];
    if (account == null) return;
    late NotesApiClient client;
    try {
      client = await _clientForAccount(account);
      final list = await client.list(
        forceFull: _notes.values.any(
          (n) =>
              n.accountId == accountId &&
              n.syncState == NoteSyncState.creationUncertain,
        ),
      );
      if (!list.notModified) {
        await _applyList(account, list);
        _listedIds[accountId] = list.ids;
      }
      if (_accountErrors.remove(accountId) != null) _notify();
    } on NotesException catch (error) {
      await _markAccountError(accountId, error);
      return;
    } catch (_) {
      await _markAccountError(
        accountId,
        const NotesException(
          NotesFailureCode.authentication,
          'Unlock your keyring or reconnect to Nextcloud.',
        ),
      );
      return;
    }
    // One pass, bounded retries through deliberate refresh, never a lock spin loop.
    final pendingIds = _notes.values
        .where(
          (n) =>
              n.accountId == accountId && n.hasPendingChanges && !_isBlocked(n),
        )
        .map((n) => n.localId)
        .toList();
    for (final id in pendingIds) {
      if (_removing.contains(accountId)) return;
      var note = _notes[id];
      if (note == null || _isBlocked(note)) continue;
      try {
        if (note.serverId == null) {
          final sent = await _markCreationSending(id);
          try {
            final remote = await client.create(sent);
            await _acknowledge(sent, remote);
          } on NotesException catch (error) {
            // 5xx/malformed/transport failure can happen after a successful POST.
            if (error.code == NotesFailureCode.network ||
                error.code == NotesFailureCode.server ||
                error.code == NotesFailureCode.invalidResponse ||
                error.code == NotesFailureCode.locked) {
              await _setState(
                id,
                NoteSyncState.creationUncertain,
                'Nextcloud may have created this note. Refresh and resolve the uncertain result before creating another.',
              );
            } else {
              // A definitive rejection establishes that this request created no note.
              await _mutate(() async {
                final current = _require(id);
                if (current.creationAttempt?.id != sent.creationAttempt?.id) {
                  return;
                }
                final rejected = current.copyWith(creationAttempt: null);
                await store.saveNote(rejected);
                _notes[id] = rejected;
              });
              await _recordError(id, error);
            }
            continue;
          }
        }
        if (_isBlocked(_require(id))) continue;
        await _publishAttachments(id, client);
        note = _require(id);
        if (note.hasPendingChanges && !_isBlocked(note)) {
          final sent = await _markSending(id);
          final remote = await client.update(sent);
          await _acknowledge(sent, remote);
        }
      } on NotesException catch (error) {
        await _recordError(id, error, client: client);
        if (error.code == NotesFailureCode.authentication) {
          await _markAccountError(accountId, error);
          return;
        }
      }
    }
  }

  bool _isBlocked(NextcloudNote note) =>
      (note.serverId == null && note.creationAttempt != null) ||
      note.error ||
      (note.readonly &&
          (note.base == null ||
              note.content != note.base!.content ||
              note.title != note.base!.title ||
              note.category != note.base!.category)) ||
      {
        NoteSyncState.conflict,
        NoteSyncState.creationUncertain,
        NoteSyncState.deletedRemotely,
        NoteSyncState.unavailable,
      }.contains(note.syncState);

  bool _readonlyBlocks(NextcloudNote note, NoteState remote) =>
      remote.readonly &&
      (note.content != remote.content ||
          note.title != remote.title ||
          note.category != remote.category);

  Future<void> _applyList(
    NextcloudAccount account,
    NotesListResult list,
  ) => _mutate(() async {
    if (_removing.contains(account.id) || !_accounts.containsKey(account.id)) {
      return;
    }
    final updated = <NextcloudNote>[];
    final existing = <int, NextcloudNote>{
      for (final n in _notes.values.where(
        (n) => n.accountId == account.id && n.serverId != null,
      ))
        n.serverId!: n,
    };
    final uncertain = _notes.values
        .where(
          (n) =>
              n.accountId == account.id &&
              n.syncState == NoteSyncState.creationUncertain,
        )
        .toList();
    for (final note in uncertain) {
      final attempt = note.creationAttempt;
      if (attempt == null) continue;
      // Payload equality is correlation evidence, never proof of identity.
      final plausible = list.notes.where(attempt.plausiblyMatches).toList()
        ..sort(
          (a, b) => (attempt.matches(b) ? 1 : 0).compareTo(
            attempt.matches(a) ? 1 : 0,
          ),
        );
      updated.add(
        note.copyWith(
          remote: plausible.length == 1 ? plausible.single : null,
          creationAttempt: attempt.withCandidateServerIds(
            plausible.map((n) => n.id),
          ),
          errorMessage: plausible.isEmpty
              ? 'The creation outcome remains unknown. No matching note was found; this does not prove the request failed.'
              : 'Possible server notes were found. Review and deliberately use one or create a separate note.',
        ),
      );
    }
    for (final remote in list.notes) {
      final current = existing[remote.id];
      if (current == null) {
        updated.add(_fromRemote(_uuid.v4(), account.id, remote));
      } else if (remote.error) {
        updated.add(
          current.copyWith(
            readonly: true,
            error: true,
            remote: remote,
            syncState: NoteSyncState.unavailable,
            errorMessage:
                'Nextcloud could not read this note. Cached content has been preserved.',
          ),
        );
      } else if (current.hasPendingChanges) {
        if (remote.etag != current.etag) {
          updated.add(
            current.copyWith(
              remote: remote,
              readonly: remote.readonly,
              syncState: NoteSyncState.conflict,
              errorMessage:
                  'The note changed on Nextcloud while local changes were pending.',
            ),
          );
        } else if (current.readonly != remote.readonly || current.error) {
          final forbidden =
              _readonlyBlocks(current, remote) &&
              current.syncState != NoteSyncState.conflict;
          updated.add(
            current.copyWith(
              readonly: remote.readonly,
              error: false,
              syncState: forbidden
                  ? NoteSyncState.forbidden
                  : current.syncState == NoteSyncState.unavailable
                  ? NoteSyncState.pending
                  : current.syncState,
              errorMessage: forbidden
                  ? 'Nextcloud became read-only. Local changes are preserved; recover them as a new note.'
                  : current.syncState == NoteSyncState.unavailable
                  ? null
                  : current.errorMessage,
            ),
          );
        }
      } else {
        updated.add(
          _fromRemote(
            current.localId,
            account.id,
            remote,
            revision: current.revision,
            previous: current,
          ),
        );
      }
    }
    // Only list()'s fully received final chunk may supply the complete ID set.
    for (final note in existing.values) {
      if (!list.ids.contains(note.serverId)) {
        updated.add(
          note.copyWith(
            syncState: NoteSyncState.deletedRemotely,
            errorMessage: note.hasPendingChanges
                ? 'This note was deleted on Nextcloud. Recover as a new note or discard local changes.'
                : null,
          ),
        );
      }
    }
    // Reconnection may refresh app/capability metadata while this request is
    // in flight. Commit the checkpoint onto the current non-secret account.
    final checkpoint = (_accounts[account.id] ?? account).withCheckpoint(
      list.etag,
      list.lastModified,
    );
    await store.commit(accounts: [checkpoint], notes: updated);
    _accounts[account.id] = checkpoint;
    for (final note in updated) {
      if (note.etag != _notes[note.localId]?.etag) {
        _baseGenerations[note.localId] =
            (_baseGenerations[note.localId] ?? 0) + 1;
      }
      _notes[note.localId] = note;
    }
    _notify();
  });

  NextcloudNote _fromRemote(
    String localId,
    String accountId,
    NoteState remote, {
    int revision = 1,
    NextcloudNote? previous,
  }) => NextcloudNote(
    localId: localId,
    accountId: accountId,
    serverId: remote.id,
    content: remote.content,
    title: remote.title,
    category: remote.category,
    favorite: remote.favorite,
    readonly: remote.readonly,
    error: remote.error,
    modified: remote.modified,
    etag: remote.etag,
    base: remote,
    revision: revision,
    ackRevision: revision,
    editorRevision: previous?.editorRevision ?? 0,
    editorContentDigest: previous?.editorContentDigest,
    syncState: remote.error ? NoteSyncState.unavailable : NoteSyncState.synced,
  );

  Future<NextcloudNote> _markCreationSending(String id) => _mutate(() async {
    final current = _require(id);
    if (current.serverId != null ||
        current.creationAttempt != null ||
        _isBlocked(current)) {
      throw const NotesException(
        NotesFailureCode.conflict,
        'Resolve the previous creation attempt before creating another.',
      );
    }
    final attributes = await NotesApiClient.creationAttributes(current);
    final attempt = NotesCreationAttempt(
      id: _uuid.v4(),
      revision: current.revision,
      localContent: current.content,
      wireBody: jsonEncode(attributes),
      knownServerIds: {
        ...?_listedIds[current.accountId],
        for (final note in _notes.values)
          if (note.accountId == current.accountId && note.serverId != null)
            note.serverId!,
      },
    );
    final sent = current.copyWith(
      creationAttempt: attempt,
      syncState: NoteSyncState.syncing,
      errorMessage: null,
    );
    // The exact request and outbox become durable before the first network byte.
    await store.saveNote(sent);
    _notes[id] = sent;
    _notify();
    return sent;
  });

  NextcloudNote _adoptCreation(NextcloudNote current, NoteState remote) {
    final attempt = current.creationAttempt!;
    final wire = attempt.attributes;
    final latest = current.revision == attempt.revision;
    final staged = current.content != remote.content;
    final adopted = current.copyWith(
      serverId: remote.id,
      etag: remote.etag,
      base: remote,
      remote: null,
      content: current.content,
      title: current.title == wire['title'] ? remote.title : current.title,
      category: current.category == wire['category']
          ? remote.category
          : current.category,
      favorite: current.favorite == wire['favorite']
          ? remote.favorite
          : current.favorite,
      readonly: remote.readonly,
      modified: remote.modified,
      error: false,
      ackRevision: attempt.revision,
      revision: latest && staged ? current.revision + 1 : current.revision,
      syncState: latest && !staged
          ? NoteSyncState.synced
          : NoteSyncState.pending,
      creationAttempt: null,
      errorMessage: null,
    );
    return _readonlyBlocks(adopted, remote)
        ? adopted.copyWith(
            syncState: NoteSyncState.forbidden,
            errorMessage:
                'Nextcloud became read-only. Local changes and staged attachments are preserved for recovery.',
          )
        : adopted;
  }

  Future<NextcloudNote> _markSending(String id) => _mutate(() async {
    final sent = _require(
      id,
    ).copyWith(syncState: NoteSyncState.syncing, errorMessage: null);
    await store.saveNote(sent);
    _notes[id] = sent;
    _notify();
    return sent;
  });

  Future<void> _acknowledge(
    NextcloudNote sent,
    NoteState remote,
  ) => _mutate(() async {
    final current = _require(sent.localId);
    if (_removing.contains(current.accountId) ||
        !_accounts.containsKey(current.accountId) ||
        (sent.serverId == null &&
            (current.serverId != null ||
                current.creationAttempt?.id != sent.creationAttempt?.id)) ||
        (sent.serverId != null && current.serverId != sent.serverId)) {
      throw const NotesException(
        NotesFailureCode.conflict,
        'This response no longer belongs to the active request.',
      );
    }
    if (remote.error) {
      final unavailable = current.copyWith(
        serverId: remote.id,
        remote: remote,
        readonly: true,
        error: true,
        syncState: NoteSyncState.unavailable,
        errorMessage:
            'Nextcloud could not read the saved note. Local content has been preserved.',
      );
      await store.saveNote(unavailable);
      _notes[sent.localId] = unavailable;
    } else {
      final latest = current.revision == sent.revision;
      final staged =
          sent.serverId == null &&
          current.content.contains('busymark-attachment:') &&
          (await scanNotesAttachmentReferences(
            current.content,
          )).any((r) => r.reference.startsWith('busymark-attachment:'));
      // Apply acknowledgments only to the captured revision, retain newer edits.
      var acknowledged = current.copyWith(
        serverId: remote.id,
        creationAttempt: null,
        etag: remote.etag,
        base: remote,
        remote: null,
        ackRevision: sent.revision,
        content: latest && !staged ? remote.content : current.content,
        title: latest || current.title == sent.title
            ? remote.title
            : current.title,
        category: latest || current.category == sent.category
            ? remote.category
            : current.category,
        favorite: latest ? remote.favorite : current.favorite,
        readonly: remote.readonly,
        error: false,
        modified: remote.modified,
        revision: latest && staged ? current.revision + 1 : current.revision,
        syncState: latest && !staged
            ? NoteSyncState.synced
            : NoteSyncState.pending,
        errorMessage: null,
      );
      if (acknowledged.hasPendingChanges &&
          _readonlyBlocks(acknowledged, remote)) {
        acknowledged = acknowledged.copyWith(
          syncState: NoteSyncState.forbidden,
          errorMessage:
              'Nextcloud became read-only during synchronization. Newer local changes are preserved; recover them as a new note.',
        );
      }
      await store.saveNote(acknowledged);
      _notes[sent.localId] = acknowledged;
    }
    _notify();
  });

  Future<void> _setState(
    String id,
    NoteSyncState state,
    String? message, {
    NoteState? remote,
  }) => _mutate(() async {
    final current = _require(id);
    final updated = current.copyWith(
      syncState: state,
      errorMessage: message,
      remote: remote ?? current.remote,
      readonly: remote?.readonly ?? current.readonly,
    );
    await store.saveNote(updated);
    _notes[id] = updated;
    _notify();
  });

  Future<void> _recordError(
    String id,
    NotesException error, {
    NotesApiClient? client,
  }) async {
    var remote = error.remote;
    if ((error.code == NotesFailureCode.conflict ||
            error.code == NotesFailureCode.forbidden) &&
        remote == null &&
        client != null) {
      try {
        remote = await client.get(_require(id).serverId!);
      } on NotesException {
        /* Preserve base/local. */
      }
    }
    final state = switch (error.code) {
      NotesFailureCode.authentication => NoteSyncState.reconnectRequired,
      NotesFailureCode.forbidden => NoteSyncState.forbidden,
      NotesFailureCode.missing => NoteSyncState.deletedRemotely,
      NotesFailureCode.conflict => NoteSyncState.conflict,
      NotesFailureCode.locked => NoteSyncState.locked,
      NotesFailureCode.storageFull => NoteSyncState.storageFull,
      NotesFailureCode.network => NoteSyncState.offline,
      _ => NoteSyncState.pending,
    };
    await _setState(id, state, error.message, remote: remote);
  }

  Future<void> _markAccountError(String accountId, NotesException error) async {
    _accountErrors[accountId] = error;
    _notify();
    for (final note in notes.where(
      (n) => n.accountId == accountId && n.hasPendingChanges && !_isBlocked(n),
    )) {
      await _recordError(note.localId, error);
    }
  }

  /// Recreates a remote recovery/history snapshot with its own durable staged
  /// attachments. Nothing is published until the complete local transaction.
  Future<NextcloudNote> recoverAsNew(
    String originalLocalId, {
    String? content,
    String? title,
    bool creationDecision = false,
  }) async {
    final original = _require(originalLocalId);
    final separateId = original.creationAttempt?.separateNoteLocalId;
    if (creationDecision && separateId != null) return _require(separateId);
    if (creationDecision &&
        (original.serverId != null ||
            original.syncState != NoteSyncState.creationUncertain)) {
      throw const NotesException(
        NotesFailureCode.conflict,
        'Review the creation outcome again.',
      );
    }
    final source = content ?? original.content;
    final references = await scanNotesAttachmentReferences(source);
    final originals = await store.attachments(originalLocalId);
    final localId = _uuid.v4();
    final copied = <String, ({NotesAttachment attachment, Uint8List bytes})>{};
    final replacements = <String, String>{};
    NotesApiClient? client;
    for (final occurrence in references) {
      final reference = occurrence.reference;
      final canonical = canonicalAttachmentReference(reference);
      final known = originals
          .where(
            (a) =>
                a.reference == reference ||
                (canonical != null && a.remotePath == canonical),
          )
          .firstOrNull;
      final pending = reference.startsWith('busymark-attachment:');
      final managed = canonical?.startsWith('.attachments.') == true;
      final ownManaged =
          original.serverId != null &&
          canonical?.startsWith('.attachments.${original.serverId}/') == true;
      if (pending && known == null || managed && !ownManaged && known == null) {
        throw const NotesException(
          NotesFailureCode.unsafeReference,
          'This recovery snapshot contains an attachment owned by another note.',
        );
      }
      if (known == null &&
          !ownManaged &&
          !(occurrence.image && canonical != null)) {
        continue;
      }
      final key = known?.id ?? canonical!;
      var publication = copied[key];
      if (publication == null) {
        Uint8List? bytes;
        if (known != null) bytes = await store.attachmentBytes(known.id);
        if (bytes == null) {
          final remotePath = known?.remotePath ?? canonical;
          if (original.serverId == null ||
              remotePath == null ||
              !isSafeAttachmentPath(remotePath)) {
            throw const NotesException(
              NotesFailureCode.missing,
              'The original attachment bytes are unavailable. Restore them before recovering this note.',
            );
          }
          client ??= await _clientForAccount(_accounts[original.accountId]!);
          bytes = await _fetchAttachmentBytes(
            client,
            original.serverId!,
            remotePath,
          );
        }
        final id = _uuid.v4();
        publication = (
          attachment: NotesAttachment(
            id: id,
            noteId: localId,
            filename: known?.filename ?? p.basename(canonical!),
            reference: 'busymark-attachment:${original.accountId}:$localId:$id',
          ),
          bytes: bytes,
        );
        copied[key] = publication;
      }
      replacements[reference] = publication.attachment.reference;
    }
    var rewritten = source;
    var previousStart = source.length;
    for (final occurrence in references.reversed) {
      final replacement = replacements[occurrence.reference];
      if (replacement == null || occurrence.end > previousStart) continue;
      rewritten = rewritten.replaceRange(
        occurrence.start,
        occurrence.end,
        replacement,
      );
      previousStart = occurrence.start;
    }
    final recovered = NextcloudNote(
      localId: localId,
      accountId: original.accountId,
      title: title ?? original.title,
      category: original.category,
      favorite: original.favorite,
      content: rewritten,
    );
    return _mutate(() async {
      final current = _require(originalLocalId);
      if (_removing.contains(original.accountId) ||
          !_accounts.containsKey(original.accountId) ||
          current.revision != original.revision ||
          current.creationAttempt?.id != original.creationAttempt?.id ||
          (creationDecision && current.serverId != null)) {
        throw const NotesException(
          NotesFailureCode.conflict,
          'Local work or the account changed during recovery. Review again.',
        );
      }
      final existingId = current.creationAttempt?.separateNoteLocalId;
      if (creationDecision && existingId != null) return _require(existingId);
      final decided = creationDecision && current.creationAttempt != null
          ? current.copyWith(
              creationAttempt: current.creationAttempt!.withSeparateNote(
                localId,
              ),
            )
          : null;
      await store.createWithAttachments(
        recovered,
        copied.values.toList(),
        additionalNotes: [if (decided != null) decided],
      );
      if (decided != null) _notes[originalLocalId] = decided;
      _notes[localId] = recovered;
      _notify();
      return recovered;
    });
  }

  /// History may refer to an attachment deliberately deleted after the
  /// snapshot. Re-stage its retained bytes before the normal editor/save path.
  /// The current note remains untouched until that path commits the new edit.
  Future<String> prepareRestoredContent(String localId, String source) async {
    final note = _require(localId);
    if (note.readonly || note.error) {
      throw const NotesException(
        NotesFailureCode.forbidden,
        'This Nextcloud note is read-only.',
      );
    }
    final restoration = await _prepareDeletedReferences(
      note,
      source,
      introducedOnly: false,
    );
    if (restoration.attachments.isEmpty) return source;
    await _mutate(() async {
      final current = _require(localId);
      if (current.readonly || current.error) {
        throw const NotesException(
          NotesFailureCode.forbidden,
          'This Nextcloud note became read-only.',
        );
      }
      await store.stageAttachments(restoration.attachments);
      (_publishedReferences[localId] ??= {}).addAll(restoration.references);
      _notify();
    });
    return restoration.content;
  }

  Future<
    ({
      String content,
      List<({NotesAttachment attachment, Uint8List bytes})> attachments,
      Map<String, String> references,
    })
  >
  _prepareDeletedReferences(
    NextcloudNote note,
    String source, {
    bool introducedOnly = true,
  }) async {
    final localId = note.localId;
    final originals = await store.attachments(localId);
    if (!originals.any(
      (a) => a.state == 'deleted' || a.state == 'deletePending',
    )) {
      return (
        content: source,
        attachments: <({NotesAttachment attachment, Uint8List bytes})>[],
        references: <String, String>{},
      );
    }
    final occurrences = await scanNotesAttachmentReferences(source);
    final previousCounts = <String, int>{};
    final desiredCounts = <String, int>{};
    if (introducedOnly) {
      for (final occurrence in await scanNotesAttachmentReferences(
        note.content,
      )) {
        previousCounts.update(
          occurrence.reference,
          (v) => v + 1,
          ifAbsent: () => 1,
        );
      }
      for (final occurrence in occurrences) {
        desiredCounts.update(
          occurrence.reference,
          (v) => v + 1,
          ifAbsent: () => 1,
        );
      }
    }
    final staged = <String, ({NotesAttachment attachment, Uint8List bytes})>{};
    final replacements = <String, String>{};
    for (final occurrence in occurrences) {
      if (introducedOnly &&
          (desiredCounts[occurrence.reference] ?? 0) <=
              (previousCounts[occurrence.reference] ?? 0)) {
        // An explicitly deleted file can deliberately leave a missing link.
        // Unrelated edits must not reverse that deletion behind the user.
        continue;
      }
      final canonical = canonicalAttachmentReference(occurrence.reference);
      final candidates = originals
          .where(
            (a) =>
                a.reference == occurrence.reference ||
                (canonical != null && a.remotePath == canonical),
          )
          .toList();
      // A re-upload may reuse the same filename after deletion. Its healthy
      // metadata supersedes the retained historical deletion tombstone.
      final original =
          candidates
              .where((a) => a.state != 'deleted' && a.state != 'deletePending')
              .firstOrNull ??
          candidates.firstOrNull;
      if (original == null ||
          (original.state != 'deleted' && original.state != 'deletePending')) {
        continue;
      }
      var replacement = staged[original.id];
      if (replacement == null) {
        final bytes = await store.attachmentBytes(original.id);
        if (bytes == null) {
          throw const NotesException(
            NotesFailureCode.missing,
            'The deleted attachment bytes are unavailable. Restore them before restoring this history snapshot.',
          );
        }
        final id = _uuid.v4();
        replacement = (
          attachment: NotesAttachment(
            id: id,
            noteId: localId,
            filename: original.filename,
            reference: 'busymark-attachment:${note.accountId}:$localId:$id',
          ),
          bytes: bytes,
        );
        staged[original.id] = replacement;
      }
      replacements[occurrence.reference] = replacement.attachment.reference;
    }
    if (staged.isEmpty) {
      return (
        content: source,
        attachments: <({NotesAttachment attachment, Uint8List bytes})>[],
        references: <String, String>{},
      );
    }
    var restored = source;
    var previousStart = source.length;
    for (final occurrence in occurrences.reversed) {
      final replacement = replacements[occurrence.reference];
      if (replacement == null || occurrence.end > previousStart) continue;
      restored = restored.replaceRange(
        occurrence.start,
        occurrence.end,
        replacement,
      );
      previousStart = occurrence.start;
    }
    return (
      content: restored,
      attachments: staged.values.toList(),
      references: replacements,
    );
  }

  Future<void> resolveConflict(
    String localId,
    NoteConflictResolution resolution, {
    String? mergedContent,
    Map<NotesMergeAttribute, NotesMergeChoice> metadataChoices = const {},
    int? expectedRevision,
    int? creationCandidateServerId,
    NotesCreationReview? creationReview,
  }) async {
    final original = _require(localId);
    if (expectedRevision != null && original.revision != expectedRevision) {
      throw const NotesException(
        NotesFailureCode.conflict,
        'New local edits appeared. Review the conflict again.',
      );
    }
    if (resolution == NoteConflictResolution.saveAsNew) {
      if (!_creationResolutions.add(localId)) {
        throw const NotesException(
          NotesFailureCode.conflict,
          'A creation decision is already in progress.',
        );
      }
      try {
        await recoverAsNew(
          localId,
          creationDecision: original.serverId == null,
        );
      } finally {
        _creationResolutions.remove(localId);
      }
      return;
    }
    if (resolution == NoteConflictResolution.useServerNote) {
      if (creationReview == null ||
          creationCandidateServerId != creationReview.candidate.id) {
        throw const NotesException(
          NotesFailureCode.conflict,
          'Select and review a server note before confirming adoption.',
        );
      }
      await _resolveCreation(original, creationReview);
      return;
    }
    if (original.serverId == null) {
      throw const NotesException(
        NotesFailureCode.conflict,
        'An uncertain creation needs explicit server-note confirmation or a separate note.',
      );
    }
    final client = await _clientForAccount(_accounts[original.accountId]!);
    late NoteState fresh;
    try {
      fresh = await client.get(original.serverId!);
    } on NotesException catch (error) {
      if (error.code == NotesFailureCode.missing &&
          original.syncState == NoteSyncState.deletedRemotely &&
          resolution == NoteConflictResolution.takeRemote) {
        await _setDeleted(localId, expectedRevision: original.revision);
        return;
      }
      rethrow;
    }
    if (fresh.error) {
      throw const NotesException(
        NotesFailureCode.forbidden,
        'The server note is unavailable.',
      );
    }
    await _mutate(() async {
      final current = _require(localId);
      if (current.revision != original.revision) {
        throw const NotesException(
          NotesFailureCode.conflict,
          'New local edits appeared while resolving this note. Review them before applying the resolution.',
        );
      }
      if (resolution != NoteConflictResolution.takeRemote &&
          original.remote != null &&
          fresh.etag != original.remote!.etag) {
        final changedAgain = current.copyWith(
          remote: fresh,
          readonly: fresh.readonly,
          syncState: NoteSyncState.conflict,
          errorMessage:
              'The server note changed again. Review its current state before resolving the conflict.',
        );
        await store.saveNote(changedAgain);
        _notes[localId] = changedAgain;
        _notify();
        throw NotesException(
          NotesFailureCode.conflict,
          changedAgain.errorMessage!,
          remote: fresh,
        );
      }
      final merge = NotesConflictMerge(current, fresh);
      final merging = resolution == NoteConflictResolution.merge;
      final resolved = resolution == NoteConflictResolution.takeRemote
          ? _fromRemote(
              localId,
              current.accountId,
              fresh,
              revision: current.revision + 1,
              previous: current,
            ).copyWith(
              editorRevision: current.revision + 1,
              editorContentDigest: sha256
                  .convert(utf8.encode(fresh.content))
                  .toString(),
            )
          : current.copyWith(
              content: merging
                  ? mergedContent ?? merge.content.resolve()
                  : current.content,
              title: merging
                  ? merge.title.resolve(
                      metadataChoices[NotesMergeAttribute.title],
                    )
                  : current.title,
              category: merging
                  ? merge.category.resolve(
                      metadataChoices[NotesMergeAttribute.category],
                    )
                  : current.category,
              favorite: merging
                  ? merge.favorite.resolve(
                      metadataChoices[NotesMergeAttribute.favorite],
                    )
                  : current.favorite,
              etag: fresh.etag,
              base: fresh,
              remote: null,
              readonly: fresh.readonly,
              error: false,
              revision: current.revision + 1,
              syncState: NoteSyncState.pending,
              errorMessage: null,
            );
      if (fresh.readonly &&
          resolution != NoteConflictResolution.takeRemote &&
          _readonlyBlocks(resolved, fresh)) {
        throw const NotesException(
          NotesFailureCode.forbidden,
          'The server note is read-only. Only its favorite can be changed; recover protected local changes as a new note.',
        );
      }
      await store.saveNote(resolved);
      _notes[localId] = resolved;
      _notify();
    });
  }

  Future<void> _resolveCreation(
    NextcloudNote original,
    NotesCreationReview review,
  ) async {
    if (!_creationResolutions.add(original.localId)) {
      throw const NotesException(
        NotesFailureCode.conflict,
        'A creation decision is already in progress.',
      );
    }
    final candidateIds = _notes.values
        .where(
          (n) =>
              n.accountId == original.accountId &&
              n.serverId == review.candidate.id,
        )
        .map((n) => n.localId)
        .toSet();
    _bindingCandidates.addAll(candidateIds);
    try {
      final account = _accounts[original.accountId];
      void validate() {
        final current = _require(original.localId);
        if (account == null ||
            _removing.contains(original.accountId) ||
            _accounts[original.accountId]?.server != account.server ||
            _accounts[original.accountId]?.loginName != account.loginName ||
            current.serverId != null ||
            current.syncState != NoteSyncState.creationUncertain ||
            review.localId != current.localId ||
            review.accountId != current.accountId ||
            current.creationAttempt?.id != review.attemptId ||
            current.creationAttempt?.separateNoteLocalId != null ||
            current.revision != review.revision ||
            !(current.creationAttempt?.candidateServerIds.contains(
                  review.candidate.id,
                ) ??
                false)) {
          throw const NotesException(
            NotesFailureCode.conflict,
            'The account, local edits or creation decision changed. Review again.',
          );
        }
      }

      validate();
      final running = _syncs[original.accountId];
      if (running != null) await running;
      validate();
      final client = await _clientForAccount(account!);
      late NoteState fresh;
      try {
        fresh = await client.get(review.candidate.id);
      } on NotesException catch (error) {
        await _mutate(() async {
          validate();
          final current = _require(original.localId);
          final ids = {...current.creationAttempt!.candidateServerIds};
          if (error.code == NotesFailureCode.missing) {
            ids.remove(review.candidate.id);
          }
          final unresolved = current.copyWith(
            remote: null,
            creationAttempt: current.creationAttempt!.withCandidateServerIds(
              ids,
            ),
            errorMessage:
                'The selected server note is unavailable. Refresh and review again.',
          );
          await store.saveNote(unresolved);
          _notes[current.localId] = unresolved;
          _notify();
        });
        rethrow;
      }
      await _mutate(() async {
        validate();
        final current = _require(original.localId);
        if (jsonEncode(fresh.toJson()) !=
                jsonEncode(review.candidate.toJson()) ||
            fresh.error ||
            fresh.readonly) {
          final unresolved = current.copyWith(
            remote: fresh,
            errorMessage:
                'The selected server note changed or is read-only. Review its current state before deciding.',
          );
          await store.saveNote(unresolved);
          _notes[current.localId] = unresolved;
          _notify();
          throw NotesException(
            NotesFailureCode.conflict,
            unresolved.errorMessage!,
            remote: fresh,
          );
        }
        final duplicates = _notes.values
            .where(
              (n) =>
                  n.accountId == current.accountId &&
                  n.serverId == fresh.id &&
                  n.localId != current.localId,
            )
            .toList();
        candidateIds.addAll(duplicates.map((n) => n.localId));
        _bindingCandidates.addAll(candidateIds);
        for (final twin in duplicates) {
          final attachments = await store.attachments(twin.localId);
          if (twin.hasPendingChanges ||
              attachments.any(
                (a) => {
                  'pending',
                  'uploading',
                  'uncertain',
                  'uploaded',
                  'deletePending',
                }.contains(a.state),
              )) {
            throw const NotesException(
              NotesFailureCode.conflict,
              'The downloaded candidate has local changes or pending attachments. Preserve or resolve them first.',
            );
          }
        }
        validate();
        final ids = duplicates.map((n) => n.localId).toSet();
        if (_creationBindingGuards.any(
          (guard) => !guard(current.localId, ids),
        )) {
          throw const NotesException(
            NotesFailureCode.conflict,
            'New editor changes appeared or a downloaded candidate is still open. Preserve those edits, close candidate tabs, and review again.',
          );
        }
        final adopted = _adoptCreation(current, fresh);
        // Binding/outbox and clean-twin removal are a single SQLite transaction.
        await store.commit(notes: [adopted], removeNotes: ids.toList());
        for (final id in ids) {
          _notes.remove(id);
        }
        _notes[current.localId] = adopted;
        _baseGenerations[current.localId] =
            (_baseGenerations[current.localId] ?? 0) + 1;
        _notify();
      });
    } finally {
      _bindingCandidates.removeAll(candidateIds);
      _creationResolutions.remove(original.localId);
    }
  }

  /// Online refresh plus explicit action only. The API has no atomic conditional DELETE.
  Future<void> delete(String localId) async {
    final original = _require(localId);
    if (original.serverId == null) {
      if (original.syncState == NoteSyncState.creationUncertain ||
          original.syncState == NoteSyncState.syncing) {
        throw const NotesException(
          NotesFailureCode.conflict,
          'Resolve the uncertain creation before deleting this note.',
        );
      }
      await _setDeleted(localId, expectedRevision: original.revision);
      return;
    }
    final running = _syncs[original.accountId];
    if (running != null) await running;
    final client = await _clientForAccount(_accounts[original.accountId]!);
    final current = _require(localId);
    final fresh = await client.get(current.serverId!);
    if (fresh.etag != current.etag) {
      await _setState(
        localId,
        NoteSyncState.conflict,
        'The note changed on Nextcloud. Review the fresh version before deleting.',
        remote: fresh,
      );
      throw NotesException(
        NotesFailureCode.conflict,
        'The note changed on Nextcloud; deletion was cancelled.',
        remote: fresh,
      );
    }
    await client.delete(current.serverId!);
    await _setDeleted(localId, expectedRevision: current.revision);
  }

  Future<void> _setDeleted(
    String localId, {
    required int expectedRevision,
  }) => _mutate(() async {
    final note = _require(localId);
    final deleted = note.copyWith(
      syncState: NoteSyncState.deletedRemotely,
      ackRevision: expectedRevision,
      errorMessage: note.revision > expectedRevision
          ? 'The remote note was deleted, but newer local edits are preserved for recovery.'
          : null,
    );
    await store.saveNote(deleted);
    _notes[localId] = deleted;
    _notify();
  });

  Future<NotesAttachment> addAttachment(
    String localId, {
    required String filename,
    required Uint8List bytes,
  }) async {
    final note = _require(localId);
    if (note.readonly || note.error) {
      throw const NotesException(
        NotesFailureCode.forbidden,
        'This note is read-only.',
      );
    }
    if (filename.isEmpty ||
        p.basename(filename) != filename ||
        filename.contains('\\') ||
        RegExp(r'[\x00-\x1f\x7f]').hasMatch(filename)) {
      throw const NotesException(
        NotesFailureCode.unsafeReference,
        'The attachment filename is unsafe.',
      );
    }
    final id = _uuid.v4();
    final attachment = NotesAttachment(
      id: id,
      noteId: localId,
      filename: filename,
      reference: 'busymark-attachment:${note.accountId}:$localId:$id',
    );
    await store.saveAttachment(attachment, bytes);
    _notify();
    return attachment;
  }

  Future<void> _publishAttachments(
    String localId,
    NotesApiClient client,
  ) async {
    for (final queued in await store.attachments(localId)) {
      final storedAttachment = (await store.attachments(
        localId,
      )).where((a) => a.id == queued.id).firstOrNull;
      if (storedAttachment == null) continue;
      var attachment = storedAttachment;
      final note = _require(localId);
      if (attachment.state == 'deleted') continue;
      if (attachment.state == 'deletePending') {
        try {
          await client.deleteAttachment(note.serverId!, attachment.remotePath!);
        } on NotesException catch (error) {
          if (error.code != NotesFailureCode.missing) rethrow;
        }
        final deleted = attachment;
        await _mutate(() async {
          // Repair duplicate cache owners written by older application builds.
          for (final item in await store.attachments(localId)) {
            if (item.id == deleted.id ||
                item.remotePath == deleted.remotePath) {
              await _retainDeletedAttachment(item);
            }
          }
          _notify();
        });
        continue;
      }
      if (!note.content.contains(attachment.reference) ||
          !(await scanNotesAttachmentReferences(
            note.content,
          )).any((r) => r.reference == attachment.reference)) {
        continue;
      }
      if (attachment.state == 'uploading' || attachment.state == 'uncertain') {
        throw const NotesException(
          NotesFailureCode.conflict,
          'An attachment upload has an uncertain outcome. Keep its durable bytes and resolve before uploading again.',
        );
      }
      if (attachment.remotePath == null) {
        final bytes = await store.attachmentBytes(attachment.id);
        if (bytes == null) {
          throw const NotesException(
            NotesFailureCode.invalidResponse,
            'The durable attachment is unavailable.',
          );
        }
        final sending = NotesAttachment(
          id: attachment.id,
          noteId: localId,
          filename: attachment.filename,
          reference: attachment.reference,
          state: 'uploading',
        );
        await store.updateAttachment(sending);
        try {
          final path = await client.uploadAttachment(
            note.serverId!,
            attachment.filename,
            bytes,
          );
          attachment = NotesAttachment(
            id: attachment.id,
            noteId: localId,
            filename: attachment.filename,
            reference: attachment.reference,
            remotePath: path,
            state: 'uploaded',
          );
        } on NotesException catch (error) {
          final uncertain =
              error.code == NotesFailureCode.network ||
              error.code == NotesFailureCode.server ||
              error.code == NotesFailureCode.invalidResponse ||
              error.code == NotesFailureCode.locked;
          await store.updateAttachment(
            NotesAttachment(
              id: attachment.id,
              noteId: localId,
              filename: attachment.filename,
              reference: attachment.reference,
              state: uncertain ? 'uncertain' : 'pending',
            ),
          );
          rethrow;
        }
      }
      await _mutate(() async {
        final current = _require(localId);
        final content = replaceNotesAttachmentReferences(
          current.content,
          await scanNotesAttachmentReferences(current.content),
          {
            attachment.reference: attachmentMarkdownReference(
              attachment.remotePath!,
            ),
          },
        );
        final updated = current.copyWith(
          content: content,
          revision: current.revision + 1,
          syncState: NoteSyncState.pending,
        );
        await store.updateAttachment(attachment, note: updated);
        (_publishedReferences[localId] ??= {})[attachment.reference] =
            attachmentMarkdownReference(attachment.remotePath!);
        _notes[localId] = updated;
        _notify();
      });
    }
  }

  Future<String?> resolveMedia(
    String accountId,
    String localId,
    String reference,
  ) {
    final canonical = canonicalAttachmentReference(reference);
    final key = '$accountId:$localId:${canonical ?? reference}';
    final existing = _mediaResolutions[key];
    if (existing != null) return existing;
    final future = _resolveMedia(accountId, localId, reference, canonical);
    _mediaResolutions[key] = future;
    return future.whenComplete(() {
      if (identical(_mediaResolutions[key], future)) {
        _mediaResolutions.remove(key);
      }
    });
  }

  Future<String?> _resolveMedia(
    String accountId,
    String localId,
    String reference,
    String? canonicalReference,
  ) async {
    _validateId(accountId);
    _validateId(localId);
    final note = _notes[localId];
    if (note == null || note.accountId != accountId) return null;
    bool matches(NotesAttachment candidate) =>
        candidate.reference == reference ||
        (canonicalReference != null &&
            candidate.remotePath == canonicalReference);
    final initial = (await store.attachments(localId)).where(matches).toList();
    final initialAttachment = _liveMediaAttachment(initial);
    if (initial.isNotEmpty && initialAttachment == null) return null;
    File? fetched;
    if (initialAttachment == null) {
      if (canonicalReference == null || note.serverId == null) return null;
      final client = await _clientForAccount(_accounts[accountId]!);
      fetched = await _downloadAttachment(
        client,
        note.serverId!,
        canonicalReference,
      );
    }
    try {
      return await _mutate(() async {
        // Another context, publication or deletion may have committed during HTTP.
        // Never insert another owner for the same canonical destination or revive
        // a deletion tombstone. Network waits stay outside the durability queue.
        if (_notes[localId]?.accountId != accountId) return null;
        final current = (await store.attachments(
          localId,
        )).where(matches).toList();
        final liveAttachment = _liveMediaAttachment(current);
        if (current.isNotEmpty && liveAttachment == null) return null;
        final attachment =
            liveAttachment ??
            NotesAttachment(
              id: _uuid.v4(),
              noteId: localId,
              filename: p.basename(canonicalReference!),
              reference: reference,
              remotePath: canonicalReference,
              state: 'cached',
            );
        if (liveAttachment == null) {
          if (fetched == null) return null;
          await store.saveAttachmentFile(attachment, fetched);
        }
        _validateId(attachment.id);
        final extension = p.extension(attachment.filename);
        final safeExtension =
            RegExp(r'^\.[a-zA-Z0-9]{1,12}$').hasMatch(extension)
            ? extension
            : '';
        final mediaRoot = Directory(p.join(p.dirname(store.path), 'media'));
        final accountDirectory = Directory(p.join(mediaRoot.path, accountId));
        final directory = Directory(p.join(accountDirectory.path, localId));
        for (final component in [mediaRoot, accountDirectory, directory]) {
          if (await FileSystemEntity.isLink(component.path)) return null;
        }
        for (final component in [mediaRoot, accountDirectory, directory]) {
          await component.create();
          if (Platform.isLinux) {
            final permissions = await Process.run('chmod', [
              '700',
              component.path,
            ]);
            if (permissions.exitCode != 0) return null;
          }
        }
        final staging = await directory.createTemp('.materialize-');
        try {
          if (Platform.isLinux) {
            final permissions = await Process.run('chmod', [
              '700',
              staging.path,
            ]);
            if (permissions.exitCode != 0) return null;
          }
          final partial = File(p.join(staging.path, 'attachment'));
          await store.writeAttachmentFile(attachment.id, partial);
          final digest = await sha256.bind(partial.openRead()).first;
          final file = File(
            p.join(
              directory.path,
              '${attachment.id}-${digest.toString().substring(0, 16)}$safeExtension',
            ),
          );
          if (await FileSystemEntity.isLink(file.path)) return null;
          if (!await file.exists()) {
            if (Platform.isLinux) {
              final permissions = await Process.run('chmod', [
                '600',
                partial.path,
              ]);
              if (permissions.exitCode != 0) return null;
            }
            await partial.rename(file.path);
          }
          return file.path;
        } finally {
          await staging.delete(recursive: true);
        }
      });
    } finally {
      if (fetched != null) await fetched.parent.delete(recursive: true);
    }
  }

  Future<File> _downloadAttachment(
    NotesApiClient client,
    int id,
    String path,
  ) async {
    final root = Directory(p.join(p.dirname(store.path), 'downloads'));
    if (await FileSystemEntity.isLink(root.path)) {
      throw const NotesException(
        NotesFailureCode.unsafeReference,
        'Unsafe attachment cache directory.',
      );
    }
    await root.create();
    final directory = await root.createTemp('attachment-');
    try {
      if (Platform.isLinux) {
        final permissions = await Process.run('chmod', ['700', directory.path]);
        if (permissions.exitCode != 0) {
          throw const FileSystemException('Cannot protect cache.');
        }
      }
      return await client.fetchAttachment(
        id,
        path,
        destination: File(p.join(directory.path, 'complete')),
      );
    } catch (_) {
      await directory.delete(recursive: true);
      rethrow;
    }
  }

  /// Recovery/upload still uses the store's bounded blob representation. The
  /// network download itself always streams to disk before reading any bytes.
  Future<Uint8List> _fetchAttachmentBytes(
    NotesApiClient client,
    int id,
    String path,
  ) async {
    final file = await _downloadAttachment(client, id, path);
    try {
      return await file.readAsBytes();
    } finally {
      await file.parent.delete(recursive: true);
    }
  }

  NotesAttachment? _liveMediaAttachment(List<NotesAttachment> items) {
    // A deliberate history restore can upload new bytes under the same server
    // filename. Its acknowledged upload supersedes old recovery tombstones;
    // an old duplicate cache row does not.
    final uploaded = items.where((a) => a.state == 'uploaded').firstOrNull;
    if (uploaded != null) return uploaded;
    if (items.any((a) => a.state == 'deleted')) return null;
    return items.firstOrNull;
  }

  Future<void> deleteAttachment(
    String localId,
    String reference, {
    bool retainForHistory = false,
  }) async {
    final note = _require(localId);
    if (note.readonly || note.error) {
      throw const NotesException(
        NotesFailureCode.forbidden,
        'This Nextcloud note is read-only.',
      );
    }
    final items = await store.attachments(localId);
    final matching = items
        .where(
          (a) =>
              a.reference == reference ||
              (canonicalAttachmentReference(reference) != null &&
                  a.remotePath == canonicalAttachmentReference(reference)),
        )
        .toList();
    if (matching.isEmpty) return;
    final attachment = matching.first;
    if (attachment.state == 'uploading' || attachment.state == 'uncertain') {
      throw const NotesException(
        NotesFailureCode.conflict,
        'Resolve the uncertain attachment upload before deleting.',
      );
    }
    if (attachment.remotePath != null) {
      if (!(_accounts[note.accountId]?.supportsAttachmentDeletion ?? false)) {
        throw const NotesException(
          NotesFailureCode.unsupported,
          'Remote attachment cleanup is unavailable: it requires a verified Notes version of 6.1.0 or newer. Notes and attachment upload/download remain available.',
        );
      }
      if (note.serverId == null) return;
      await _mutate(() async {
        final current = _require(localId);
        final pending = current.copyWith(
          revision: current.revision + 1,
          syncState: NoteSyncState.pending,
        );
        await store.updateAttachment(
          NotesAttachment(
            id: attachment.id,
            noteId: localId,
            filename: attachment.filename,
            reference: attachment.reference,
            remotePath: attachment.remotePath,
            state: 'deletePending',
          ),
          note: pending,
        );
        _notes[localId] = pending;
        _notify();
      });
      await synchronize(note.accountId);
      return;
    }
    await _mutate(() async {
      if (retainForHistory) {
        await _retainDeletedAttachment(attachment);
      } else {
        await store.removeAttachment(attachment.id);
        await _invalidateAttachmentMedia(attachment);
      }
      _notify();
    });
  }

  Future<void> _retainDeletedAttachment(NotesAttachment attachment) async {
    await store.updateAttachment(
      NotesAttachment(
        id: attachment.id,
        noteId: attachment.noteId,
        filename: attachment.filename,
        reference: attachment.reference,
        remotePath: attachment.remotePath,
        state: 'deleted',
      ),
    );
    await _invalidateAttachmentMedia(attachment);
  }

  Future<void> _invalidateAttachmentMedia(NotesAttachment attachment) async {
    _mediaVersions[attachment.noteId] = mediaVersion(attachment.noteId) + 1;
    final note = _notes[attachment.noteId];
    if (note == null) return;
    final directory = Directory(
      p.join(p.dirname(store.path), 'media', note.accountId, attachment.noteId),
    );
    for (final component in [
      directory.parent.parent,
      directory.parent,
      directory,
    ]) {
      if (await FileSystemEntity.isLink(component.path)) return;
    }
    if (!await directory.exists()) return;
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is File &&
          p.basename(entity.path).startsWith('${attachment.id}-')) {
        await entity.delete();
      }
    }
  }

  /// A deliberate resolution for an upload whose response was lost. Retrying
  /// can leave an orphaned server file; automatic synchronization never retries.
  Future<void> retryUncertainAttachments(String localId) async {
    final note = _require(localId);
    if (note.serverId == null ||
        note.syncState == NoteSyncState.creationUncertain) {
      throw const NotesException(
        NotesFailureCode.conflict,
        'Resolve the uncertain note creation before retrying attachments.',
      );
    }
    for (final attachment in await store.attachments(localId)) {
      if (attachment.state != 'uncertain' && attachment.state != 'uploading') {
        continue;
      }
      await store.updateAttachment(
        NotesAttachment(
          id: attachment.id,
          noteId: localId,
          filename: attachment.filename,
          reference: attachment.reference,
          state: 'pending',
        ),
      );
    }
    await _setState(localId, NoteSyncState.pending, null);
  }

  /// Adopts a user-selected server filename only after its bytes are verified.
  Future<void> adoptUncertainAttachment(
    String localId,
    String reference,
    String remotePath,
  ) async {
    final note = _require(localId);
    if (note.serverId == null ||
        !isSafeAttachmentPath(remotePath) ||
        !isNoteAttachmentPath(note.serverId!, remotePath)) {
      throw const NotesException(
        NotesFailureCode.unsafeReference,
        'Choose an attachment in this note’s managed attachment folder.',
      );
    }
    final matching = (await store.attachments(
      localId,
    )).where((a) => a.reference == reference).toList();
    if (matching.length != 1) {
      throw const NotesException(
        NotesFailureCode.missing,
        'The staged attachment is unavailable.',
      );
    }
    final attachment = matching.first;
    final expected = await store.attachmentBytes(attachment.id);
    final client = await _clientForAccount(_accounts[note.accountId]!);
    final actual = await _fetchAttachmentBytes(
      client,
      note.serverId!,
      remotePath,
    );
    if (expected == null ||
        sha256.convert(expected) != sha256.convert(actual)) {
      throw const NotesException(
        NotesFailureCode.conflict,
        'The server attachment does not match the durable local bytes.',
      );
    }
    await store.updateAttachment(
      NotesAttachment(
        id: attachment.id,
        noteId: localId,
        filename: attachment.filename,
        reference: reference,
        remotePath: remotePath,
        state: 'uploaded',
      ),
    );
    await _setState(localId, NoteSyncState.pending, null);
  }

  static void _validateId(String id) {
    if (!RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(id)) {
      throw const NotesException(
        NotesFailureCode.unsafeReference,
        'The Nextcloud account or note identifier is invalid.',
      );
    }
  }

  Future<void> removeAccount(
    String accountId, {
    Future<void> Function()? beforeRemove,
  }) async {
    _validateId(accountId);
    _removing.add(accountId);
    try {
      await _syncs[accountId];
      await _mutate(() async {
        await beforeRemove?.call();
        await store.removeAccount(accountId);
        _accounts.remove(accountId);
        _accountErrors.remove(accountId);
        _notes.removeWhere((_, n) => n.accountId == accountId);
        _publishedReferences.removeWhere((id, _) => !_notes.containsKey(id));
        final directory = Directory(
          p.join(p.dirname(store.path), 'media', accountId),
        );
        if (await directory.exists() &&
            !await FileSystemEntity.isLink(directory.path)) {
          await directory.delete(recursive: true);
        }
        _notify();
      });
    } finally {
      _removing.remove(accountId);
    }
  }

  Future<void> dispose() => _disposing ??= _dispose();

  Future<void> _dispose() async {
    _disposed = true;
    await Future.wait(_syncs.values);
    await _mutations;
    await _changes.close();
    await store.close();
  }
}
