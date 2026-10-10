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
import '../data/notes_capabilities.dart';
import '../domain/notes_models.dart';
import '../domain/notes_conflict.dart';

/// Owns local durability and ordinary optimistic synchronization separately.
class NotesRepository {
  NotesRepository({
    required this.store,
    required Future<NotesApiClient> Function(NextcloudAccount) clientForAccount,
    DateTime Function()? clock,
    this.fetchCapabilities,
  }) : clock = clock ?? DateTime.now,
       _clientForAccount = clientForAccount;

  final NotesStore store;
  final DateTime Function() clock;
  final Future<NotesCapabilities> Function(NextcloudAccount)? fetchCapabilities;
  final _capabilityRequests = <String, Future<void>>{};
  final _accountGenerations = <String, int>{};
  final _verifiedInProcess = <String>{};
  final _settingsTransitions = <String>{};
  final _activeMediaNotes = <String>{};
  final _mediaFreshnessEpochs = <String, int>{};
  final _validatedMediaEpochs = <String, int>{};
  final _downloads = <String, NotesDownloadCancellation>{};
  static const mediaFreshness = Duration(minutes: 5);
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
  bool isSynchronizing(String accountId) => _syncs.containsKey(accountId);
  bool _currentAccount(String id, int generation) =>
      !_disposed &&
      !_removing.contains(id) &&
      _accounts.containsKey(id) &&
      (_accountGenerations[id] ?? 0) == generation;
  void _assertMutableAccount(String id) {
    if (_disposed || _removing.contains(id) || !_accounts.containsKey(id)) {
      throw const NotesException(
        NotesFailureCode.missing,
        'The Nextcloud account is no longer available.',
        scope: NotesRequestScope.account,
      );
    }
    if (_settingsTransitions.contains(id) ||
        _accounts[id]!.settingsAttempt != null) {
      throw const NotesException(
        NotesFailureCode.conflict,
        'Resolve the Notes settings transition before editing this collection.',
        scope: NotesRequestScope.settings,
      );
    }
  }

  bool _writeEligible(NextcloudNote note) =>
      note.retryCount <= 6 &&
      (note.retryNotBefore == null || !clock().isBefore(note.retryNotBefore!));
  bool hasRetryableWork(String id) => notes.any(
    (n) =>
        n.accountId == id &&
        n.hasPendingChanges &&
        !_isBlocked(n) &&
        n.retryCount > 0 &&
        n.retryCount <= 6,
  );
  DateTime? writeDeadline(String id) {
    final deadlines = notes
        .where(
          (n) =>
              n.accountId == id &&
              n.hasPendingChanges &&
              !_isBlocked(n) &&
              n.retryCount <= 6,
        )
        .map((n) => n.retryNotBefore)
        .whereType<DateTime>()
        .toList();
    final accountDeadline =
        _accounts[id]?.throttleNotBefore ?? accountError(id)?.retryNotBefore;
    if (accountDeadline != null) deadlines.add(accountDeadline);
    deadlines.sort();
    return deadlines.lastOrNull;
  }

  Future<void> retryWrites(String id) => _mutate(() async {
    final reset = notes
        .where(
          (n) =>
              n.accountId == id &&
              n.failureCode != null &&
              {
                NotesFailureCode.network,
                NotesFailureCode.server,
                NotesFailureCode.locked,
                NotesFailureCode.throttled,
              }.contains(n.failureCode) &&
              !_isBlocked(n),
        )
        .map((n) => n.copyWith(retryCount: 0))
        .toList();
    await store.commit(notes: reset);
    for (final n in reset) {
      _notes[n.localId] = n;
    }
  });

  Future<void> recoverNetworkWrites(String id) => _mutate(() async {
    final recovered = notes
        .where(
          (n) =>
              n.accountId == id &&
              n.failureCode == NotesFailureCode.network &&
              !_isBlocked(n),
        )
        .map(
          (n) => n.copyWith(
            retryCount: 0,
            syncState: NoteSyncState.pending,
            failureCode: null,
            failureScope: null,
          ),
        )
        .toList();
    await store.commit(notes: recovered);
    for (final n in recovered) {
      _notes[n.localId] = n;
    }
  });

  /// A deliberate corrective action; timers and ordinary Refresh cannot do this.
  Future<void> retryRejectedNote(String id) => _mutate(() async {
    final current = _require(id);
    _assertMutableAccount(current.accountId);
    if (!{
          NoteSyncState.rejected,
          NoteSyncState.storageFull,
        }.contains(current.syncState) ||
        current.creationAttempt != null ||
        (current.readonly &&
            (current.base == null ||
                _readonlyBlocks(current, current.base!)))) {
      throw const NotesException(
        NotesFailureCode.conflict,
        'Resolve this operation before retrying it.',
      );
    }
    for (final attachment in await store.attachments(id)) {
      if (attachment.state == 'rejected') {
        await store.updateAttachment(
          NotesAttachment(
            id: attachment.id,
            noteId: id,
            filename: attachment.filename,
            reference: attachment.reference,
            remotePath: attachment.remotePath,
            state: 'pending',
          ),
        );
      }
    }
    final retry = current.copyWith(
      syncState: NoteSyncState.pending,
      failureCode: null,
      failureScope: null,
      retryCount: 0,
      errorMessage: null,
    );
    await store.saveNote(retry);
    _notes[id] = retry;
    _notify();
  });

  NotesMetadataSnapshot metadataSnapshot(String id) =>
      NotesMetadataSnapshot(_require(id), editorBase(id));

  /// Three-way field merge under the same boundary that owns editor content.
  Future<NextcloudNote> patchMetadata(
    NotesMetadataSnapshot snapshot, {
    String? title,
    String? category,
    bool? favorite,
  }) => _mutate(() async {
    final original = snapshot.note;
    final current = _require(original.localId);
    _assertMutableAccount(original.accountId);
    if (current.accountId != original.accountId ||
        current.serverId != original.serverId) {
      throw const NotesException(
        NotesFailureCode.conflict,
        'The note identity changed; reopen its properties.',
      );
    }
    title = title == original.title ? null : title;
    category = category == original.category ? null : category;
    favorite = favorite == original.favorite ? null : favorite;
    if (title == null && category == null && favorite == null) return current;
    if ((current.readonly || current.error) &&
        (title != null || category != null)) {
      throw const NotesException(
        NotesFailureCode.forbidden,
        'This Nextcloud note became read-only.',
      );
    }
    final divergent =
        (title != null &&
            current.title != original.title &&
            current.title != title) ||
        (category != null &&
            current.category != original.category &&
            current.category != category) ||
        (favorite != null &&
            current.favorite != original.favorite &&
            current.favorite != favorite);
    final changed =
        (title != null && title != current.title) ||
        (category != null && category != current.category) ||
        (favorite != null && favorite != current.favorite);
    if (!changed) return current;
    final patched = current.copyWith(
      title: title,
      category: category,
      favorite: favorite,
      revision: current.revision + 1,
      localActivityMicros: clock().microsecondsSinceEpoch,
      base: divergent ? snapshot.base.state : current.base,
      remote: divergent
          ? (current.remote ??
                NoteState(
                  id: current.serverId ?? 1,
                  etag: current.etag ?? 'local',
                  content: current.content,
                  title: current.title,
                  category: current.category,
                  favorite: current.favorite,
                  readonly: current.readonly,
                  modified: current.modified,
                ))
          : current.remote,
      syncState: divergent || current.syncState == NoteSyncState.conflict
          ? NoteSyncState.conflict
          : _isBlocked(current) && current.syncState != NoteSyncState.rejected
          ? current.syncState
          : NoteSyncState.pending,
      failureCode: null,
      failureScope: null,
      retryCount: 0,
      retryNotBefore: null,
      errorMessage: divergent
          ? 'A property changed while the dialog was open. Review both values before synchronizing.'
          : current.syncState == NoteSyncState.conflict
          ? current.errorMessage
          : null,
    );
    await store.saveNote(patched);
    _notes[current.localId] = patched;
    _notify();
    return patched;
  });

  final _capabilityEpochs = <String, int>{};
  int capabilityEpoch(String id) => _capabilityEpochs[id] ?? 0;
  int accountGeneration(String id) => _accountGenerations[id] ?? 0;
  Future<void> recordApiVersions(
    String id,
    int generation,
    int epoch,
    String raw,
  ) => _mutate(() async {
    if (!_currentAccount(id, generation) || capabilityEpoch(id) != epoch) {
      return;
    }
    final values = raw.split(',').map((v) => v.trim()).toList();
    if (values.isEmpty ||
        values.any((v) => !RegExp(r'^\d+\.\d+$').hasMatch(v))) {
      return;
    }
    final version = parseNotesApiVersions(values);
    final current = _accounts[id]!;
    final updated = current.copyWith(
      apiVersion: version ?? current.apiVersion,
      apiSupported: version != null,
    );
    await store.saveAccount(updated);
    _accounts[id] = updated;
    _capabilityEpochs[id] = epoch + 1;
    if (version == null) {
      _accountErrors[id] = const NotesException(
        NotesFailureCode.unsupported,
        'This server no longer advertises Notes API major 1, minor 4 or later. Local work is preserved.',
        scope: NotesRequestScope.capability,
      );
    }
    _notify();
  });

  Future<void> maintainCapabilities(String id, {bool force = false}) {
    if (_capabilityRequests[id] case final pending?) return pending;
    final account = _accounts[id];
    if (fetchCapabilities == null ||
        account == null ||
        _disposed ||
        _removing.contains(id)) {
      return Future.value();
    }
    if (!force &&
        _verifiedInProcess.contains(id) &&
        account.capabilitiesCheckedAt != null &&
        clock().difference(account.capabilitiesCheckedAt!) <
            const Duration(hours: 1)) {
      return Future.value();
    }
    final generation = accountGeneration(id);
    final epoch = capabilityEpoch(id) + 1;
    _capabilityEpochs[id] = epoch;
    final future = () async {
      try {
        final capabilities = await fetchCapabilities!(account);
        await _mutate(() async {
          if (!_currentAccount(id, generation)) return;
          final current = _accounts[id]!;
          final updated = current.copyWith(
            appVersion: capabilities.appVersion,
            apiVersion: capabilityEpoch(id) == epoch
                ? capabilities.apiVersion
                : current.apiVersion,
            apiSupported: capabilityEpoch(id) == epoch
                ? true
                : current.apiSupported,
            capabilitiesCheckedAt: clock(),
          );
          await store.saveAccount(updated);
          _accounts[id] = updated;
          _verifiedInProcess.add(id);
          _notify();
        });
      } on NextcloudCapabilityException catch (error) {
        if (!_currentAccount(id, generation)) return;
        if (error.code == NextcloudCapabilityFailure.unsupported) {
          await _mutate(() async {
            if (!_currentAccount(id, generation) ||
                capabilityEpoch(id) != epoch) {
              return;
            }
            final current = _accounts[id]!.copyWith(
              apiSupported: false,
              capabilitiesCheckedAt: clock(),
            );
            await store.saveAccount(current);
            _accounts[id] = current;
          });
        }
        throw NotesException(
          switch (error.code) {
            NextcloudCapabilityFailure.unsupported =>
              NotesFailureCode.unsupported,
            NextcloudCapabilityFailure.unauthorized =>
              NotesFailureCode.authentication,
            NextcloudCapabilityFailure.malformed =>
              NotesFailureCode.invalidResponse,
            NextcloudCapabilityFailure.network => NotesFailureCode.network,
            NextcloudCapabilityFailure.rejected => NotesFailureCode.rejected,
            NextcloudCapabilityFailure.forbidden => NotesFailureCode.forbidden,
            NextcloudCapabilityFailure.throttled => NotesFailureCode.throttled,
          },
          error.message,
          scope: NotesRequestScope.capability,
          statusCode: error.statusCode,
          retryNotBefore: error.retryNotBefore,
        );
      }
    }();
    _capabilityRequests[id] = future;
    return future.whenComplete(() {
      if (identical(_capabilityRequests[id], future)) {
        _capabilityRequests.remove(id);
      }
    });
  }

  Future<NotesSettings> getSettings(String id) async {
    final generation = accountGeneration(id);
    final account = _accounts[id];
    if (account == null) {
      throw const NotesException(
        NotesFailureCode.missing,
        'The account was removed.',
        scope: NotesRequestScope.account,
      );
    }
    _checkThrottle(account);
    late NotesSettings settings;
    try {
      settings = await (await _clientForAccount(account)).getSettings();
    } on NotesException catch (error) {
      await _rememberThrottle(id, error);
      rethrow;
    }
    if (!_currentAccount(id, generation)) {
      throw const NotesException(
        NotesFailureCode.missing,
        'The account was removed or reconnected.',
        scope: NotesRequestScope.account,
      );
    }
    return settings;
  }

  bool hasSettingsBlockers(String id) => notes.any(
    (n) =>
        n.accountId == id &&
        (n.hasPendingChanges ||
            n.syncState == NoteSyncState.conflict ||
            n.syncState == NoteSyncState.creationUncertain),
  );

  Future<NotesSettings> changeSettings(
    String id,
    NotesSettings original,
    Map<String, String> patch,
  ) async {
    if (patch.isEmpty) return original;
    _assertMutableAccount(id);
    _settingsTransitions.add(id);
    final generation = accountGeneration(id);
    try {
      await _syncs[id];
      final fresh = await getSettings(id);
      for (final field in patch.keys) {
        if (fresh.toJson()[field] != original.toJson()[field] &&
            fresh.toJson()[field] != patch[field]) {
          throw const NotesException(
            NotesFailureCode.conflict,
            'Server settings changed while this form was open. Reload and review them.',
            scope: NotesRequestScope.settings,
          );
        }
      }
      final pathChange =
          patch.containsKey('notesPath') &&
          patch['notesPath'] != fresh.notesPath;
      final suffixChange =
          patch.containsKey('fileSuffix') &&
          patch['fileSuffix'] != fresh.fileSuffix;
      final attempt = NotesSettingsAttempt(
        id: _uuid.v4(),
        original: fresh,
        patch: patch,
      );
      await _mutate(() async {
        if (!_currentAccount(id, generation)) {
          throw const NotesException(
            NotesFailureCode.missing,
            'The account was removed.',
            scope: NotesRequestScope.account,
          );
        }
        final attachments = await store.attachments();
        if ((pathChange || suffixChange) &&
            (hasSettingsBlockers(id) ||
                attachments.any(
                  (a) =>
                      _notes[a.noteId]?.accountId == id &&
                      !{'cached', 'uploaded', 'deleted'}.contains(a.state),
                ))) {
          throw const NotesException(
            NotesFailureCode.conflict,
            'Synchronize or resolve pending notes, conflicts and attachment operations before changing the server collection.',
            scope: NotesRequestScope.settings,
          );
        }
        final current = _accounts[id]!.copyWith(settingsAttempt: attempt);
        await store.saveAccount(current);
        _accounts[id] = current;
      });
      NotesSettings result;
      try {
        result = await (await _clientForAccount(
          _accounts[id]!,
        )).updateSettings(patch);
      } on NotesException catch (error) {
        await _rememberThrottle(id, error);
        if (!error.possiblyExecuted) {
          await _finishSettings(
            id,
            generation,
            attempt,
            fresh,
            resetCheckpoint: false,
          );
          rethrow;
        }
        // A lost response may follow normalization/partial execution. Read first;
        // if that read fails, the durable attempt fences writes across restart.
        result = await getSettings(id);
        if (patch.keys.every(
          (key) => result.toJson()[key] == fresh.toJson()[key],
        )) {
          await _finishSettings(
            id,
            generation,
            attempt,
            result,
            resetCheckpoint:
                result.notesPath != fresh.notesPath ||
                result.fileSuffix != fresh.fileSuffix,
          );
          throw const NotesException(
            NotesFailureCode.rejected,
            'The settings response was lost and the server still reports the previous values. Review them before saving again.',
            scope: NotesRequestScope.settings,
          );
        }
      }
      await _finishSettings(
        id,
        generation,
        attempt,
        result,
        resetCheckpoint:
            pathChange ||
            suffixChange ||
            result.notesPath != fresh.notesPath ||
            result.fileSuffix != fresh.fileSuffix,
      );
      return result;
    } finally {
      _settingsTransitions.remove(id);
    }
  }

  Future<void> _finishSettings(
    String id,
    int generation,
    NotesSettingsAttempt attempt,
    NotesSettings result, {
    required bool resetCheckpoint,
  }) => _mutate(() async {
    if (!_currentAccount(id, generation) ||
        _accounts[id]!.settingsAttempt?.id != attempt.id) {
      throw const NotesException(
        NotesFailureCode.missing,
        'The account changed during the settings request.',
        scope: NotesRequestScope.account,
      );
    }
    final current = _accounts[id]!.copyWith(
      settingsAttempt: null,
      listEtag: resetCheckpoint ? null : _accounts[id]!.listEtag,
      lastModified: resetCheckpoint ? null : _accounts[id]!.lastModified,
    );
    await store.saveAccount(current);
    _accounts[id] = current;
    _notify();
  });

  void _checkThrottle(NextcloudAccount account) {
    final deadline = account.throttleNotBefore;
    if (deadline != null && clock().isBefore(deadline)) {
      throw NotesException(
        NotesFailureCode.throttled,
        'Nextcloud requested a pause before the next request.',
        scope: NotesRequestScope.account,
        retryNotBefore: deadline,
      );
    }
  }

  Future<void> _rememberThrottle(String id, NotesException error) =>
      _mutate(() async {
        final account = _accounts[id];
        if (account == null ||
            _disposed ||
            _removing.contains(id) ||
            error.retryNotBefore == null) {
          return;
        }
        final previous = account.throttleNotBefore;
        final deadline =
            previous != null && previous.isAfter(error.retryNotBefore!)
            ? previous
            : error.retryNotBefore;
        final updated = account.copyWith(throttleNotBefore: deadline);
        await store.saveAccount(updated);
        _accounts[id] = updated;
      });
  Future<NotesSettings> reconcileSettings(String id) async {
    final attempt = _accounts[id]?.settingsAttempt;
    final generation = accountGeneration(id);
    final result = await getSettings(id);
    if (attempt != null) {
      await _finishSettings(
        id,
        generation,
        attempt,
        result,
        resetCheckpoint: true,
      );
    }
    return result;
  }

  void setDisplayedMediaNotes(Iterable<String> ids) {
    _activeMediaNotes
      ..clear()
      ..addAll(ids);
  }

  void _invalidateMediaFreshness(String id) {
    _mediaFreshnessEpochs[id] = (_mediaFreshnessEpochs[id] ?? 0) + 1;
    for (final entry in _downloads.entries.where(
      (e) => e.key.contains(':$id:'),
    )) {
      entry.value.cancel();
    }
    _mediaVersions[id] = mediaVersion(id) + 1;
  }

  Future<void> refreshDisplayedMedia({bool force = false}) async {
    for (final id in _activeMediaNotes.toList()) {
      final note = _notes[id];
      if (note == null || _disposed || _removing.contains(note.accountId)) {
        continue;
      }
      final used = (await scanNotesAttachmentReferences(note.content))
          .map((r) => canonicalAttachmentReference(r.reference))
          .whereType<String>()
          .toSet();
      final cached = (await store.attachments(id))
          .where(
            (a) =>
                a.remotePath != null &&
                used.contains(a.remotePath) &&
                {'cached', 'uploaded'}.contains(a.state),
          )
          .toList();
      if (force) {
        _invalidateMediaFreshness(id);
        await Future.wait(
          _mediaResolutions.entries
              .where((e) => e.key.startsWith('${note.accountId}:$id:'))
              .map(
                (e) => e.value.then<void>(
                  (_) {},
                  onError: (Object _, StackTrace _) {},
                ),
              )
              .toList(),
        );
      }
      for (final attachment in cached) {
        await resolveMedia(
          note.accountId,
          id,
          attachmentMarkdownReference(attachment.remotePath!),
        );
      }
    }
  }

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

  Future<void> upsertAccount(
    NextcloudAccount account, {
    bool reconnect = false,
  }) async {
    await initialize();
    _validateId(account.id);
    await _mutate(() async {
      final existing = _accounts[account.id];
      final merged = existing == null
          ? account
          : existing.copyWith(
              appVersion: account.appVersion,
              apiVersion: account.apiVersion,
              apiSupported: account.apiSupported,
              capabilitiesCheckedAt: account.capabilitiesCheckedAt,
            );
      await store.saveAccount(merged);
      _accounts[account.id] = merged;
      if (reconnect || existing == null) {
        _accountGenerations[account.id] =
            (_accountGenerations[account.id] ?? 0) + 1;
      }
      _verifiedInProcess.remove(account.id);
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
      _assertMutableAccount(accountId);
      final note = NextcloudNote(
        creationNeverSent: true,
        localId: _uuid.v4(),
        accountId: accountId,
        title: title,
        category: category,
        content: content,
        localActivityMicros: clock().microsecondsSinceEpoch,
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
    _assertMutableAccount(current.accountId);
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
      NoteSyncState.recoveryRequired,
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
      localActivityMicros: clock().microsecondsSinceEpoch,
      failureCode: null,
      failureScope: null,
      retryCount: 0,
      retryNotBefore: null,
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

  Future<void> synchronize(
    String accountId, {
    bool allowWrites = true,
    bool refreshCapabilities = false,
    bool onlyFreshWrites = false,
  }) {
    if (_disposed || _removing.contains(accountId)) return Future.value();
    final existing = _syncs[accountId];
    if (existing != null) return existing;
    final future = _synchronize(
      accountId,
      allowWrites: allowWrites,
      refreshCapabilities: refreshCapabilities,
      onlyFreshWrites: onlyFreshWrites,
    );
    _syncs[accountId] = future;
    _notify();
    future.then<void>(
      (_) {
        _syncs.remove(accountId);
        _notify();
      },
      onError: (Object _, StackTrace _) {
        _syncs.remove(accountId);
        _notify();
      },
    );
    return future;
  }

  Future<void> _synchronize(
    String accountId, {
    required bool allowWrites,
    required bool refreshCapabilities,
    required bool onlyFreshWrites,
  }) async {
    await initialize();
    var account = _accounts[accountId];
    if (account == null || _settingsTransitions.contains(accountId)) return;
    final generation = _accountGenerations[accountId] ?? 0;
    final deadline =
        _accounts[accountId]?.throttleNotBefore ??
        _accountErrors[accountId]?.retryNotBefore;
    if (deadline != null && clock().isBefore(deadline)) {
      _accountErrors[accountId] = NotesException(
        NotesFailureCode.throttled,
        'Nextcloud requested a pause before the next server check.',
        scope: NotesRequestScope.account,
        retryNotBefore: deadline,
      );
      _notify();
      return;
    }
    late NotesApiClient client;
    try {
      await maintainCapabilities(accountId, force: refreshCapabilities);
      account = _accounts[accountId];
      if (account == null ||
          !_currentAccount(accountId, generation) ||
          !account.apiSupported) {
        return;
      }
      if (account.settingsAttempt != null) {
        await reconcileSettings(accountId);
        account = _accounts[accountId];
        if (account == null || account.settingsAttempt != null) return;
      }
      client = await _clientForAccount(account);
      final list = await client.list(
        forceFull: _notes.values.any(
          (n) =>
              n.accountId == accountId &&
              (n.syncState == NoteSyncState.creationUncertain ||
                  (n.syncState == NoteSyncState.deletedRemotely &&
                      n.deletionEvidence == null)),
        ),
      );
      if (!_currentAccount(accountId, generation)) return;
      if (!list.notModified) {
        await _applyList(account, list);
        _listedIds[accountId] = list.ids;
      }
      await _mutate(() async {
        if (!_currentAccount(accountId, generation)) return;
        final checked = _accounts[accountId]!.copyWith(
          lastServerCheck: clock(),
        );
        await store.saveAccount(checked);
        _accounts[accountId] = checked;
        if (checked.apiSupported) _accountErrors.remove(accountId);
        _notify();
      });
    } on NotesException catch (error) {
      await _markAccountError(accountId, error);
      return;
    }
    if (!allowWrites ||
        !_currentAccount(accountId, generation) ||
        _accounts[accountId]?.apiSupported != true) {
      return;
    }
    // One pass, bounded retries through deliberate refresh, never a lock spin loop.
    final pendingIds = _notes.values
        .where(
          (n) =>
              n.accountId == accountId &&
              n.hasPendingChanges &&
              (!onlyFreshWrites ||
                  (n.retryCount == 0 && n.failureCode == null)) &&
              !_isBlocked(n) &&
              _writeEligible(n),
        )
        .map((n) => n.localId)
        .toList();
    for (final id in pendingIds) {
      if (!_currentAccount(accountId, generation)) return;
      var note = _notes[id];
      if (note == null ||
          _isBlocked(note) ||
          !_writeEligible(note) ||
          (onlyFreshWrites &&
              (note.retryCount != 0 || note.failureCode != null))) {
        continue;
      }
      try {
        if (note.serverId == null) {
          final sent = await _markCreationSending(id);
          try {
            final remote = await client.create(sent);
            await _acknowledge(sent, remote);
          } on NotesException catch (error) {
            // 5xx/malformed/transport failure can happen after a successful POST.
            if (error.possiblyExecuted) {
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
                final rejected = current.copyWith(
                  creationAttempt: null,
                  creationNeverSent: true,
                );
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
        NoteSyncState.rejected,
        NoteSyncState.forbidden,
        NoteSyncState.reconnectRequired,
        NoteSyncState.storageFull,
        NoteSyncState.recoveryRequired,
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
        if (current.syncState == NoteSyncState.deletedRemotely &&
            current.deletionEvidence == null &&
            remote.etag == current.etag) {
          updated.add(
            current.copyWith(
              syncState: NoteSyncState.pending,
              errorMessage: null,
              failureCode: null,
              failureScope: null,
            ),
          );
        } else if (remote.etag != current.etag) {
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
            deletionEvidence: 'completeList',
            errorMessage: note.hasPendingChanges
                ? 'This note was deleted on Nextcloud. Recover as a new note or discard local changes.'
                : null,
          ),
        );
      }
    }
    for (final draft in _notes.values.where(
      (n) =>
          n.accountId == account.id &&
          n.serverId == null &&
          n.syncState == NoteSyncState.deletedRemotely &&
          n.deletionEvidence == null &&
          n.ackRevision == 0 &&
          n.creationAttempt == null,
    )) {
      updated.add(
        draft.copyWith(
          syncState: draft.creationNeverSent
              ? NoteSyncState.pending
              : NoteSyncState.recoveryRequired,
          errorMessage: draft.creationNeverSent
              ? null
              : 'This older record has no reliable creation history. Review the server notes before deliberately creating a separate note; its content and attachment bytes are retained.',
        ),
      );
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
        _invalidateMediaFreshness(note.localId);
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
    localActivityMicros: previous?.localActivityMicros,
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
      creationNeverSent: false,
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
        failureCode: null,
        failureScope: null,
        retryCount: 0,
        retryNotBefore: null,
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
      NotesFailureCode.missing =>
        error.scope == NotesRequestScope.note
            ? NoteSyncState.deletedRemotely
            : NoteSyncState.rejected,
      NotesFailureCode.rejected ||
      NotesFailureCode.invalidResponse ||
      NotesFailureCode.unsafeReference ||
      NotesFailureCode.unsupported => NoteSyncState.rejected,
      NotesFailureCode.throttled => NoteSyncState.throttled,
      NotesFailureCode.conflict => NoteSyncState.conflict,
      NotesFailureCode.locked => NoteSyncState.locked,
      NotesFailureCode.storageFull => NoteSyncState.storageFull,
      NotesFailureCode.network => NoteSyncState.offline,
      _ => NoteSyncState.pending,
    };
    await _mutate(() async {
      final current = _notes[id];
      if (current == null ||
          _disposed ||
          _removing.contains(current.accountId)) {
        return;
      }
      final updated = current.copyWith(
        syncState: state,
        errorMessage: error.message,
        remote: remote ?? current.remote,
        readonly: remote?.readonly ?? current.readonly,
        failureCode: error.code,
        failureScope: error.scope,
        retryNotBefore: error.retryNotBefore,
        retryCount: error.retryable
            ? current.retryCount + 1
            : current.retryCount,
        deletionEvidence: state == NoteSyncState.deletedRemotely
            ? 'individualNote'
            : current.deletionEvidence,
      );
      await store.saveNote(updated);
      _notes[id] = updated;
      _notify();
    });
  }

  Future<void> _markAccountError(String accountId, NotesException error) async {
    if (_disposed ||
        _removing.contains(accountId) ||
        !_accounts.containsKey(accountId)) {
      return;
    }
    _accountErrors[accountId] = _accounts[accountId]!.apiSupported
        ? error
        : const NotesException(
            NotesFailureCode.unsupported,
            'This server no longer advertises Notes API major 1, minor 4 or later. Local work is preserved.',
            scope: NotesRequestScope.capability,
          );
    await _rememberThrottle(accountId, error);
    _notify();
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
      creationNeverSent: true,
      localActivityMicros: clock().microsecondsSinceEpoch,
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
          creationDecision:
              original.serverId == null &&
              original.syncState == NoteSyncState.creationUncertain,
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
              localActivityMicros: clock().microsecondsSinceEpoch,
              failureCode: null,
              failureScope: null,
              retryCount: 0,
              retryNotBefore: null,
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
      deletionEvidence: 'deliberate',
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
  }) => _mutate(() async {
    final note = _require(localId);
    _assertMutableAccount(note.accountId);
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
  });

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
            validatedAt: clock(),
          );
          await store.updateAttachment(attachment);
        } on NotesException catch (error) {
          final uncertain = error.possiblyExecuted;
          await store.updateAttachment(
            NotesAttachment(
              id: attachment.id,
              noteId: localId,
              filename: attachment.filename,
              reference: attachment.reference,
              state: uncertain
                  ? 'uncertain'
                  : error.retryable
                  ? 'pending'
                  : 'rejected',
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
    if (note == null ||
        note.accountId != accountId ||
        _disposed ||
        _removing.contains(accountId)) {
      return null;
    }
    final accountGeneration = this.accountGeneration(accountId);
    final freshnessEpoch = _mediaFreshnessEpochs[localId] ?? 0;
    bool matches(NotesAttachment candidate) =>
        candidate.reference == reference ||
        (canonicalReference != null &&
            candidate.remotePath == canonicalReference);
    final initial = (await store.attachments(localId)).where(matches).toList();
    final initialAttachment = _liveMediaAttachment(initial);
    if (initial.isNotEmpty && initialAttachment == null) return null;
    File? fetched;
    final downloadable =
        canonicalReference != null &&
        note.serverId != null &&
        (initialAttachment == null ||
            ({'cached', 'uploaded'}.contains(initialAttachment.state) &&
                !(initialAttachment.state == 'uploaded' &&
                    (note.hasPendingChanges ||
                        !notesAttachmentReferences(note.content).any(
                          (r) =>
                              canonicalAttachmentReference(r.reference) ==
                              canonicalReference,
                        ))) &&
                !reference.startsWith('busymark-attachment:') &&
                !note.content.contains(
                  initialAttachment.reference.startsWith('busymark-attachment:')
                      ? initialAttachment.reference
                      : '\u0000',
                )));
    final stale =
        initialAttachment == null ||
        initialAttachment.validatedAt == null ||
        clock().difference(initialAttachment.validatedAt!) >= mediaFreshness ||
        (_validatedMediaEpochs[initialAttachment.id] ?? 0) < freshnessEpoch;
    if (downloadable && stale) {
      final cancellation = NotesDownloadCancellation();
      final key = '$accountId:$localId:$canonicalReference';
      _downloads[key] = cancellation;
      try {
        if (!_currentAccount(accountId, accountGeneration)) return null;
        _checkThrottle(_accounts[accountId]!);
        final client = await _clientForAccount(_accounts[accountId]!);
        cancellation.check();
        if (!_currentAccount(accountId, accountGeneration)) return null;
        fetched = await _downloadAttachment(
          client,
          note.serverId!,
          canonicalReference,
          cancellation: cancellation,
        );
      } on NotesException catch (error) {
        if (!_currentAccount(accountId, accountGeneration)) return null;
        await _rememberThrottle(accountId, error);
        if (initialAttachment == null) rethrow;
        // Retain last usable bytes, without advancing their validation time.
      } finally {
        if (identical(_downloads[key], cancellation)) _downloads.remove(key);
      }
    } else if (initialAttachment == null) {
      return null;
    }
    try {
      return await _mutate(() async {
        // Another context, publication or deletion may have committed during HTTP.
        // Never insert another owner for the same canonical destination or revive
        // a deletion tombstone. Network waits stay outside the durability queue.
        if (!_currentAccount(accountId, accountGeneration) ||
            _notes[localId]?.accountId != accountId ||
            _notes[localId]?.serverId != note.serverId ||
            _notes[localId]?.category != note.category ||
            (_mediaFreshnessEpochs[localId] ?? 0) != freshnessEpoch) {
          return null;
        }
        final current = (await store.attachments(
          localId,
        )).where(matches).toList();
        final liveAttachment = _liveMediaAttachment(current);
        if (current.isNotEmpty && liveAttachment == null) return null;
        var attachment =
            liveAttachment ??
            NotesAttachment(
              id: _uuid.v4(),
              noteId: localId,
              filename: p.basename(canonicalReference!),
              reference: reference,
              remotePath: canonicalReference,
              state: 'cached',
            );
        if (fetched != null &&
            (liveAttachment == null ||
                {'cached', 'uploaded'}.contains(liveAttachment.state))) {
          attachment = NotesAttachment(
            id: attachment.id,
            noteId: localId,
            filename: attachment.filename,
            reference: attachment.reference,
            remotePath: attachment.remotePath,
            state: attachment.state,
            validatedAt: clock(),
          );
          await store.saveAttachmentFile(attachment, fetched);
          _validatedMediaEpochs[attachment.id] = freshnessEpoch;
          _mediaVersions[localId] = mediaVersion(localId) + 1;
          _notify();
        } else if (liveAttachment == null) {
          return null;
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
          // One complete materialization per attachment; content-addressed paths
          // change renderer identity without accumulating superseded files.
          await for (final entity in directory.list(followLinks: false)) {
            if (entity is File &&
                entity.path != file.path &&
                p.basename(entity.path).startsWith('${attachment.id}-')) {
              await entity.delete();
            }
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
    String path, {
    NotesDownloadCancellation? cancellation,
  }) async {
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
        cancellation: cancellation,
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
    _downloads.entries
        .where((e) => e.key.contains(':${attachment.noteId}:'))
        .forEach((e) => e.value.cancel());
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
    _accountGenerations[accountId] = (_accountGenerations[accountId] ?? 0) + 1;
    for (final entry in _downloads.entries.where(
      (e) => e.key.startsWith('$accountId:'),
    )) {
      entry.value.cancel();
    }
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
    for (final cancellation in _downloads.values) {
      cancellation.cancel();
    }
    await Future.wait([
      ..._syncs.values,
      ..._capabilityRequests.values,
      ..._mediaResolutions.values.map(
        (f) => f.then<void>((_) {}, onError: (Object _, StackTrace _) {}),
      ),
    ]);
    await _mutations;
    await _changes.close();
    await store.close();
  }
}
