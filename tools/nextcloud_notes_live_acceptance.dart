import 'package:busymark/src/nextcloud_notes/application/notes_offline_controller.dart';
import 'package:busymark/src/nextcloud_notes/application/notes_search_controller.dart';
import 'package:busymark/src/nextcloud_notes/application/notes_transfer_service.dart';
import 'package:busymark/src/nextcloud_notes/application/notes_navigation.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:uuid/uuid.dart';

import 'package:busymark/src/nextcloud_notes/application/notes_repository.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_api_client.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_capabilities.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_store.dart';
import 'package:busymark/src/nextcloud_notes/domain/notes_models.dart';
import 'package:busymark/src/nextcloud_notes/domain/notes_conflict.dart';

class _HeldWrite {
  _HeldWrite(this.status);
  final int status;
  final started = Completer<void>();
  final release = Completer<void>();
  int? executedId;
}

class _Connection extends http.BaseClient {
  _Connection(this._client);
  final http.Client _client;
  bool offline = false;
  bool loseNextCreateResponse = false;
  bool discardNextCreate = false;
  bool loseNextSettingsResponse = false;
  bool loseNextUploadResponse = false;
  int? nextCollectionFailure;
  bool rejectNextPutCredentials = false;
  String? nextPutRetryAfter;
  Map<String, dynamic>? discardedCreation;
  int attachmentUploads = 0;
  int noteUpdates = 0;
  final noteUpdatesById = <int, int>{};
  final attachmentUploadsById = <int, int>{};
  int noteCreates = 0;
  int chunkRequests = 0;
  _HeldWrite? holdNextWrite;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (offline) throw http.ClientException('Intentional offline acceptance.');
    if (rejectNextPutCredentials &&
        request.method == 'PUT' &&
        request.url.path.contains('/v1/notes/')) {
      rejectNextPutCredentials = false;
      // Real server authentication rejection with intentionally invalid fixture
      // credentials, confined to this one write. Never logged or persisted.
      request.headers['Authorization'] = nextcloudAuthorization(
        'invalid-review-fixture',
        'invalid-review-password',
      );
    }
    if (request.method == 'GET' &&
        request.url.path.endsWith('/v1/notes') &&
        nextCollectionFailure != null) {
      final status = nextCollectionFailure!;
      nextCollectionFailure = null;
      return http.StreamedResponse(
        Stream.value(utf8.encode('{}')),
        status,
        request: request,
      );
    }
    if (request.method == 'PUT' &&
        request.url.path.contains('/v1/notes/') &&
        nextPutRetryAfter != null) {
      final deadline = nextPutRetryAfter!;
      nextPutRetryAfter = null;
      return http.StreamedResponse(
        Stream.value(utf8.encode('{}')),
        429,
        headers: {'Retry-After': deadline},
        request: request,
      );
    }
    if (request.url.queryParameters.containsKey('chunkCursor')) chunkRequests++;
    final creation =
        request.method == 'POST' && request.url.path.endsWith('/v1/notes');
    if (creation) noteCreates++;
    if (request.method == 'POST' && request.url.path.contains('/attachment/')) {
      attachmentUploads++;
      final id = int.parse(request.url.pathSegments.last);
      attachmentUploadsById.update(id, (v) => v + 1, ifAbsent: () => 1);
    }
    if (request.method == 'PUT' && request.url.path.contains('/v1/notes/')) {
      noteUpdates++;
      final id = int.parse(request.url.pathSegments.last);
      noteUpdatesById.update(id, (v) => v + 1, ifAbsent: () => 1);
    }
    if (creation && discardNextCreate) {
      discardNextCreate = false;
      discardedCreation =
          jsonDecode((request as http.Request).body) as Map<String, dynamic>;
      throw http.ClientException(
        'Intentional nondelivery of creation request.',
      );
    }
    final held =
        creation ||
            (request.method == 'PUT' && request.url.path.contains('/v1/notes/'))
        ? holdNextWrite
        : null;
    if (held != null) {
      holdNextWrite = null;
      held.started.complete();
      await held.release.future;
      if (held.status == 429) {
        // Definitive rejection: deliberately do not execute this fixture write.
        return http.StreamedResponse(
          Stream.value(utf8.encode('{}')),
          429,
          headers: {'Retry-After': '10'},
          request: request,
        );
      }
    }
    final response = await _client.send(request);
    if (held?.status == 503) {
      // Simulate a server failure after a real successful write. A POST outcome
      // remains uncertain; its known test-owned ID is retained only for cleanup.
      final bytes = await response.stream.toBytes();
      _require(
        response.statusCode == 200,
        'Held fixture write was not successful.',
      );
      held!.executedId = (jsonDecode(utf8.decode(bytes)) as Map)['id'] as int;
      return http.StreamedResponse(
        Stream.value(utf8.encode('{}')),
        503,
        request: request,
      );
    }
    if ((loseNextSettingsResponse &&
            request.method == 'PUT' &&
            request.url.path.endsWith('/v1/settings')) ||
        (loseNextUploadResponse &&
            request.method == 'POST' &&
            request.url.path.contains('/attachment/'))) {
      loseNextSettingsResponse = false;
      loseNextUploadResponse = false;
      await response.stream.drain<void>();
      throw http.ClientException(
        'Intentional lost response after a real server write.',
      );
    }
    if (creation && loseNextCreateResponse) {
      loseNextCreateResponse = false;
      await response.stream.drain<void>();
      throw http.ClientException(
        'Intentional loss of successful creation response.',
      );
    }
    return response;
  }

  @override
  void close() => _client.close();
}

void _require(bool condition, String message) {
  if (!condition) throw StateError(message);
}

Future<void> main(List<String> arguments) async {
  if (arguments.length < 2 || arguments.length > 3) {
    stderr.writeln(
      'Usage: dart run tools/nextcloud_notes_live_acceptance.dart <private-credentials.json> <report.json> [test-ca.pem]',
    );
    exitCode = 64;
    return;
  }
  final credentials =
      jsonDecode(await File(arguments[0]).readAsString())
          as Map<String, dynamic>;
  final server = Uri.parse(credentials['server'] as String);
  final login = (credentials['loginName'] ?? credentials['user']) as String;
  final password =
      (credentials['appPassword'] ?? credentials['password']) as String;
  // Live harness only: trust this specific test CA; hostname and certificate
  // validation remain enabled. Production uses the OS trust store unchanged.
  final context = SecurityContext(withTrustedRoots: true);
  if (arguments.length == 3) context.setTrustedCertificates(arguments[2]);
  final connection = _Connection(IOClient(HttpClient(context: context)));
  final directory = await Directory.systemTemp.createTemp(
    'busymark-notes-live-db-',
  );
  final checks = <String, Object?>{};
  NotesRepository? repository;
  final createdIds = <int>{};
  NotesSettings? originalSettings;
  DateTime? editClock;
  try {
    final capabilities = await fetchNotesCapabilities(
      client: connection,
      server: server,
      loginName: login,
      appPassword: password,
    );
    checks['notesVersion'] = capabilities.appVersion;
    checks['apiVersion'] = capabilities.apiVersion;
    final account = NextcloudAccount(
      id: const Uuid().v4(),
      server: server,
      loginName: login,
      appVersion: capabilities.appVersion,
      apiVersion: capabilities.apiVersion,
    );
    NotesApiClient api(NextcloudAccount value) => NotesApiClient(
      client: connection,
      account: value,
      appPassword: password,
    );
    Future<NotesRepository> reopen() async {
      final store = await NotesStore.open(
        path: '${directory.path}/notes.sqlite3',
      );
      final result = NotesRepository(
        store: store,
        clientForAccount: (value) async => api(value),
        clock: () => editClock ?? DateTime.now(),
        fetchCapabilities: (value) => fetchNotesCapabilities(
          client: connection,
          server: value.server,
          loginName: value.loginName,
          appPassword: password,
        ),
      );
      await result.initialize();
      return result;
    }

    repository = await reopen();
    await repository.upsertAccount(account);
    originalSettings = await api(account).getSettings();
    await _milestoneChecks(
      repository,
      connection,
      account,
      api,
      createdIds,
      checks,
      directory,
      (value) => editClock = value,
    );
    await _reviewCorrections(
      connection,
      account,
      api,
      createdIds,
      checks,
      directory,
    );
    await _metadataRaceChecks(
      connection,
      account,
      api,
      createdIds,
      checks,
      directory,
    );
    if (credentials['lockedNoteId'] case final int lockedId) {
      await repository.synchronize(account.id);
      final locked = repository.notes.firstWhere((n) => n.serverId == lockedId);
      await repository.save(
        locked.localId,
        content: '# Locked durable local edit',
      );
      final unrelated = await repository.create(
        account.id,
        title: 'Unrelated lock acceptance',
        content: '# Unrelated note',
      );
      await repository.synchronize(account.id);
      final blocked = repository.noteById(locked.localId)!;
      final independent = repository.noteById(unrelated.localId)!;
      checks['lockFixtureState'] = blocked.syncState.name;
      checks['lockFixturePending'] = blocked.hasPendingChanges;
      checks['unrelatedDuringLockState'] = independent.syncState.name;
      if (independent.serverId != null) createdIds.add(independent.serverId!);
      _require(
        blocked.syncState == NoteSyncState.locked &&
            blocked.hasPendingChanges &&
            blocked.content == '# Locked durable local edit' &&
            independent.syncState == NoteSyncState.synced,
        'Real 423 did not preserve the local outbox and isolate unrelated notes.',
      );
      checks['real423PreservesLocalOutboxAndOtherNotesSync'] = true;
    }
    final local = await repository.create(
      account.id,
      title: 'BusyMark live acceptance',
      category: 'Acceptance/Nested',
      content: '# Durable note\n\nInitial content',
    );
    _require(
      local.serverId == null && local.hasPendingChanges,
      'Creation was not locally durable before network.',
    );
    await repository.synchronize(account.id);
    var note = repository.noteById(local.localId)!;
    _require(
      note.serverId != null && note.syncState == NoteSyncState.synced,
      'Creation did not synchronize.',
    );
    createdIds.add(note.serverId!);
    checks['locallyDurableCreation'] = true;
    await repository.save(
      note.localId,
      content: '# Durable note\n\nEdited content',
      title: 'Sanitized / title : ?',
      category: 'Acceptance/Nested/Deeper',
      favorite: true,
    );
    await repository.synchronize(account.id);
    note = repository.noteById(local.localId)!;
    final remote = await api(account).get(note.serverId!);
    _require(
      remote.content == note.content &&
          remote.favorite &&
          remote.category == 'Acceptance/Nested/Deeper',
      'Content/category/favorite adoption failed.',
    );
    _require(
      remote.title == note.title,
      'Canonical server title was not adopted.',
    );
    checks['contentCategoryFavoriteCanonicalTitle'] = true;
    checks['titleSanitized'] = remote.title != 'Sanitized / title : ?';

    final bytes = Uint8List.fromList(
      utf8.encode('BusyMark attachment acceptance fixture'),
    );
    final attachmentPath = await api(
      account,
    ).uploadAttachment(note.serverId!, 'fixture.txt', bytes);
    final duplicatePath = await api(
      account,
    ).uploadAttachment(note.serverId!, 'fixture.txt', bytes);
    _require(
      attachmentPath != duplicatePath,
      'Attachment duplicate filename was not canonicalized.',
    );
    _require(
      base64Encode(
            await (await api(account).fetchAttachment(
              note.serverId!,
              attachmentPath,
              destination: File('${directory.path}/attachment'),
            )).readAsBytes(),
          ) ==
          base64Encode(bytes),
      'Attachment download bytes differ.',
    );
    if (account.supportsAttachmentDeletion) {
      await api(account).deleteAttachment(note.serverId!, duplicatePath);
      checks['attachmentDelete'] = true;
    } else {
      try {
        await api(account).deleteAttachment(note.serverId!, duplicatePath);
        throw StateError('Unsupported attachment deletion was allowed.');
      } on NotesException catch (error) {
        _require(
          error.code == NotesFailureCode.unsupported,
          'Wrong deletion gate.',
        );
      }
      checks['attachmentDeleteUnavailable'] = true;
    }
    checks['attachmentUploadFetchRename'] = true;

    // A second API actor updates the acknowledged server state before BusyMark.
    final fresh = await api(account).get(note.serverId!);
    await api(account).update(
      note.copyWith(
        etag: fresh.etag,
        content: '# Second actor\nRemote content',
      ),
    );
    await repository.save(
      note.localId,
      content: '# Local actor\nDurable conflict content',
    );
    await repository.synchronize(account.id);
    note = repository.noteById(note.localId)!;
    _require(
      note.syncState == NoteSyncState.conflict &&
          note.base != null &&
          note.remote != null &&
          note.content.contains('Durable conflict'),
      'Conflict did not preserve base/local/remote.',
    );
    await repository.resolveConflict(
      note.localId,
      NoteConflictResolution.merge,
      mergedContent: '# Merged\nRemote and local',
    );
    await repository.synchronize(account.id);
    _require(
      repository.noteById(note.localId)!.syncState == NoteSyncState.synced,
      'Merged conflict did not synchronize.',
    );
    checks['secondActorEtagConflictAndMerge'] = true;

    connection.offline = true;
    final offline = await repository.create(
      account.id,
      title: 'Offline attachment note',
      content: '# Offline',
    );
    final pendingAttachment = await repository.addAttachment(
      offline.localId,
      filename: 'offline.txt',
      bytes: bytes,
    );
    await repository.save(
      offline.localId,
      content: '# Offline\n\n[Attachment](${pendingAttachment.reference})',
    );
    await repository.synchronize(account.id);
    await repository.dispose();
    repository = await reopen();
    _require(
      repository
          .noteById(offline.localId)!
          .content
          .contains(pendingAttachment.reference),
      'Offline note attachment reference was lost after restart.',
    );
    _require(
      await repository.store.attachmentBytes(pendingAttachment.id) != null,
      'Offline attachment bytes were lost after restart.',
    );
    connection.offline = false;
    await repository.synchronize(account.id);
    final published = repository.noteById(offline.localId)!;
    _require(
      published.serverId != null &&
          published.syncState == NoteSyncState.synced &&
          !published.content.contains('busymark-attachment:'),
      'Offline new-note attachment sequence did not finish.',
    );
    createdIds.add(published.serverId!);
    final cachedMedia = await repository.resolveMedia(
      account.id,
      offline.localId,
      (await repository.store.attachments(offline.localId)).single.remotePath!,
    );
    _require(
      cachedMedia != null && await File(cachedMedia).exists(),
      'Managed attachment media cache is unavailable.',
    );
    checks['offlineNewNoteAttachmentRestartReconnect'] = true;

    final uncertain = await repository.create(
      account.id,
      title: 'Uncertain / title : ?',
      category: 'Acceptance/Unsafe : category',
      content: 'Uncertain creation acceptance ${const Uuid().v4()}',
    );
    final staged = await repository.addAttachment(
      uncertain.localId,
      filename: 'uncertain.txt',
      bytes: bytes,
    );
    await repository.save(
      uncertain.localId,
      content: '${uncertain.content}\n[file](${staged.reference})',
    );
    final beforeCreates = connection.noteCreates;
    connection.loseNextCreateResponse = true;
    await repository.synchronize(account.id);
    _require(
      repository.noteById(uncertain.localId)!.syncState ==
          NoteSyncState.creationUncertain,
      'Dropped creation response was not retained as uncertain.',
    );
    await repository.dispose();
    repository = await reopen();
    final pending = repository.noteById(uncertain.localId)!;
    _require(
      pending.creationAttempt != null &&
          pending.content.contains('busymark-attachment:'),
      'Creation wire journal or staged reference did not survive restart.',
    );
    await repository.save(
      uncertain.localId,
      content: '${pending.content}\nNewer local edit',
    );
    for (var i = 0; i < 3; i++) {
      await repository.synchronize(account.id);
    }
    final unresolved = repository.noteById(uncertain.localId)!;
    _require(
      unresolved.serverId == null &&
          unresolved.syncState == NoteSyncState.creationUncertain,
      'Discovery adopted the uncertain draft without confirmation.',
    );
    final candidate = repository
        .uncertainCreationCandidates(uncertain.localId)
        .single
        .base!;
    createdIds.add(candidate.id);
    final unchangedCandidate = await api(account).get(candidate.id);
    _require(
      jsonEncode(unchangedCandidate.toJson()) ==
              jsonEncode(candidate.toJson()) &&
          (connection.attachmentUploadsById[candidate.id] ?? 0) == 0 &&
          (connection.noteUpdatesById[candidate.id] ?? 0) == 0 &&
          connection.noteCreates == beforeCreates + 1,
      'Discovery mutated the candidate or published an attachment.',
    );
    await repository.resolveConflict(
      uncertain.localId,
      NoteConflictResolution.useServerNote,
      creationCandidateServerId: candidate.id,
      creationReview: repository.creationReview(uncertain.localId, candidate),
    );
    await repository.synchronize(account.id);
    final adopted = repository.noteById(uncertain.localId)!;
    _require(
      adopted.serverId != null && adopted.syncState == NoteSyncState.synced,
      'Uncertain creation was not safely adopted after restart.',
    );
    createdIds.add(adopted.serverId!);
    _require(
      connection.noteCreates == beforeCreates + 1 &&
          !adopted.content.contains('busymark-attachment:') &&
          adopted.content.contains('Newer local edit'),
      'Reconciliation repeated POST or lost the staged attachment/newer edit.',
    );
    final actual = await api(account).get(adopted.serverId!);
    _require(
      actual.content == adopted.content &&
          actual.title == adopted.title &&
          actual.category == adopted.category &&
          adopted.title != pending.title &&
          adopted.category != pending.category,
      'Reconciliation failed to adopt sanitized title/category and published content.',
    );
    final adoptedAttachment = (await repository.attachments(
      uncertain.localId,
    )).single;
    final received = await (await api(account).fetchAttachment(
      adopted.serverId!,
      adoptedAttachment.remotePath!,
      destination: File('${directory.path}/adopted-attachment'),
    )).readAsBytes();
    final stagedBytes = await repository.store.attachmentBytes(
      adoptedAttachment.id,
    );
    _require(
      base64Encode(received) == base64Encode(stagedBytes!),
      'Adopted attachment bytes differ.',
    );
    await repository.dispose();
    repository = await reopen();
    final durableBinding = repository.noteById(uncertain.localId)!;
    _require(
      durableBinding.serverId == adopted.serverId &&
          !durableBinding.hasPendingChanges &&
          durableBinding.creationAttempt == null,
      'Adopted binding did not survive restart.',
    );
    checks['uncertainCreateExplicitAdoptionAttachmentRestart'] = true;

    connection.discardNextCreate = true;
    final counterexample = await repository.create(
      account.id,
      title: 'Independent identical candidate',
      content: '# Independent identical content',
    );
    await repository.synchronize(account.id);
    final wire = connection.discardedCreation!;
    final actor = api(account);
    final independent = await actor.create(
      NextcloudNote(
        localId: 'independent',
        accountId: account.id,
        title: wire['title'] as String,
        content: wire['content'] as String,
        category: wire['category'] as String,
        favorite: wire['favorite'] as bool,
        creationAttempt: NotesCreationAttempt(
          id: 'actor',
          revision: 1,
          localContent: wire['content'] as String,
          wireBody: jsonEncode(wire),
          knownServerIds: {},
        ),
      ),
    );
    createdIds.add(independent.id);
    final beforeIndependentUpdates =
        connection.noteUpdatesById[independent.id] ?? 0;
    for (var i = 0; i < 3; i++) {
      await repository.synchronize(account.id);
    }
    _require(
      repository.noteById(counterexample.localId)!.serverId == null &&
          repository
              .uncertainCreationCandidates(counterexample.localId)
              .any((n) => n.serverId == independent.id) &&
          (connection.noteUpdatesById[independent.id] ?? 0) ==
              beforeIndependentUpdates &&
          jsonEncode((await actor.get(independent.id)).toJson()) ==
              jsonEncode(independent.toJson()),
      'An independently created identical note was adopted or mutated.',
    );
    checks['independentIdenticalCandidateRequiresConfirmation'] = true;

    final chunked = await api(account).list(chunkSize: 1);
    _require(
      chunked.ids.containsAll(createdIds) &&
          connection.chunkRequests > 0 &&
          chunked.lastModified != null &&
          chunked.etag != null,
      'Real list chunking/checkpoints failed.',
    );
    // ETags describe a response page, not the union of all pages. Verify 304
    // with a consistent unchunked representation after testing chunk cursors.
    final complete = await api(account).list();
    final cachedAccount = account.withCheckpoint(
      complete.etag,
      complete.lastModified,
    );
    final pruned = await api(cachedAccount).list();
    final unchanged = pruned.notModified
        ? pruned
        : await api(
            account.withCheckpoint(pruned.etag, cachedAccount.lastModified),
          ).list();
    _require(unchanged.notModified, 'Real If-None-Match did not return 304.');
    checks['listChunksLastModifiedEtag304'] = true;

    await repository.save(
      published.localId,
      content: '# Offline deletion recovery',
    );
    await api(account).delete(published.serverId!);
    createdIds.remove(published.serverId!);
    await repository.synchronize(account.id);
    _require(
      repository.noteById(published.localId)!.syncState ==
              NoteSyncState.deletedRemotely &&
          repository
              .noteById(published.localId)!
              .content
              .contains('deletion recovery'),
      'Remote deletion discarded pending local work.',
    );
    checks['remoteDeletionPreservesLocalWork'] = true;
    await repository.delete(local.localId);
    createdIds.remove(note.serverId!);
    _require(
      repository.noteById(local.localId)!.syncState ==
          NoteSyncState.deletedRemotely,
      'Explicit online deletion failed.',
    );
    checks['explicitFreshCheckedDeletion'] = true;
    await _everydayWorkspaceChecks(
      repository,
      connection,
      account,
      api,
      createdIds,
      checks,
      directory.path,
    );
    await File(arguments[1]).writeAsString(
      const JsonEncoder.withIndent(
        '  ',
      ).convert({'ok': true, 'checks': checks}),
      flush: true,
    );
    stdout.writeln(
      'Live Nextcloud Notes acceptance passed (${checks.length} checks).',
    );
  } on Object catch (error, stack) {
    await File(arguments[1]).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'ok': false,
        'checks': checks,
        'failureType': error.runtimeType.toString(),
        'failureStack': stack.toString(),
        'failure': error is NotesException
            ? error.message
            : error is StateError
            ? error.message
            : 'Live acceptance failed.',
      }),
      flush: true,
    );
    stderr.writeln('Live Nextcloud Notes acceptance failed. See the report.');
    exitCode = 1;
  } finally {
    connection.offline = false;
    if (originalSettings != null &&
        repository != null &&
        repository.accounts.isNotEmpty) {
      try {
        await NotesApiClient(
          client: connection,
          account: repository.accounts.first,
          appPassword: password,
        ).updateSettings(originalSettings.toJson());
      } on Object {
        /* Fixture teardown still bounds cleanup. */
      }
    }
    // Every destructive cleanup target was created by this isolated test run.
    for (final id in createdIds) {
      try {
        final request =
            http.Request(
                'DELETE',
                Uri.parse('$server/index.php/apps/notes/api/v1/notes/$id'),
              )
              ..followRedirects = false
              ..headers['Authorization'] = nextcloudAuthorization(
                login,
                password,
              );
        final response = await connection.send(request);
        await response.stream.drain<void>();
      } on Object {
        // The isolated server/container is separately removed by its owner.
      }
    }
    await repository?.dispose();
    connection.close();
    await directory.delete(recursive: true);
  }
}

Future<void> _milestoneChecks(
  NotesRepository repository,
  _Connection connection,
  NextcloudAccount account,
  NotesApiClient Function(NextcloudAccount) api,
  Set<int> createdIds,
  Map<String, Object?> checks,
  Directory directory,
  void Function(DateTime?) setClock,
) async {
  final settings = await repository.getSettings(account.id);
  final changed = await repository.changeSettings(account.id, settings, {
    'fileSuffix': '.busyacceptance',
  });
  _require(
    changed.fileSuffix == '.busyacceptance' &&
        changed.notesPath == settings.notesPath,
    'Custom suffix/partial settings update failed.',
  );
  final normalized = await repository.changeSettings(account.id, changed, {
    'fileSuffix': 'md',
  });
  _require(
    normalized.fileSuffix.startsWith('.'),
    'Server suffix normalization was not adopted.',
  );
  await repository.changeSettings(account.id, normalized, {
    'fileSuffix': settings.fileSuffix,
  });
  checks['settingsPartialCustomSuffixNormalization'] = true;
  connection.loseNextSettingsResponse = true;
  final lost = await repository.changeSettings(account.id, settings, {
    'notesPath': 'BusyMark M1 isolated collection',
  });
  _require(
    lost.notesPath == 'BusyMark M1 isolated collection' &&
        repository.accounts.single.settingsAttempt == null &&
        repository.accounts.single.listEtag == null,
    'Lost settings response did not reconcile by read/reset checkpoint.',
  );
  await repository.changeSettings(account.id, lost, {
    'notesPath': settings.notesPath,
  });
  checks['lostSettingsResponseReconciledRealWrite'] = true;
  await repository.synchronize(account.id, allowWrites: false);
  _require(
    repository.accounts.single.lastServerCheck != null,
    'Complete server check timestamp missing.',
  );
  await repository.maintainCapabilities(account.id, force: true);
  _require(
    repository.accounts.single.appVersion == account.appVersion,
    'Capabilities were not maintained without reconnect.',
  );
  checks['maintainedCapabilitiesAndServerCheck'] = true;

  final editTime = DateTime.now().toUtc().subtract(const Duration(days: 3));
  setClock(editTime);
  final draft = await repository.create(
    account.id,
    title: 'M1 timestamp and filenames',
    category: 'BusyMarkAcceptance',
    content: '# Edit time',
  );
  final captured = draft.localActivityMicros;
  setClock(editTime.add(const Duration(days: 2)));
  await repository.synchronize(account.id);
  var note = repository.noteById(draft.localId)!;
  createdIds.add(note.serverId!);
  _require(
    (await api(account).get(note.serverId!)).modified ==
            editTime.millisecondsSinceEpoch ~/ 1000 &&
        note.localActivityMicros == captured,
    'Delayed creation changed the local edit time.',
  );
  checks['delayedPublicationTimestampFidelity'] = true;
  setClock(null);
  final names = [
    'é 日本.txt',
    'literal%.txt',
    'space # (1).txt',
    '%2F.txt',
    '%2e%2e.txt',
  ];
  for (final filename in names) {
    final bytes = Uint8List.fromList(utf8.encode('fixture:$filename'));
    final attachment = await repository.addAttachment(
      note.localId,
      filename: filename,
      bytes: bytes,
    );
    await repository.save(
      note.localId,
      content:
          '${repository.noteById(note.localId)!.content}\n[file](${attachment.reference})',
    );
    await repository.synchronize(account.id);
    final stored = (await repository.attachments(
      note.localId,
    )).singleWhere((a) => a.id == attachment.id);
    _require(
      stored.remotePath != null &&
          repository
              .noteById(note.localId)!
              .content
              .contains(attachmentMarkdownReference(stored.remotePath!)),
      'Raw filename was not durably published into Markdown.',
    );
    final file = await api(account).fetchAttachment(
      note.serverId!,
      stored.remotePath!,
      destination: File('${directory.path}/filename-${attachment.id}'),
    );
    _require(
      base64Encode(await file.readAsBytes()) == base64Encode(bytes),
      'Filename upload/Markdown/download round trip failed.',
    );
  }
  checks['unicodePercentSpaceHashParenthesesAttachmentRoundTrips'] = true;
  await repository.save(
    note.localId,
    content: '${repository.noteById(note.localId)!.content}\nPending edit',
  );
  connection.nextCollectionFailure = 404;
  await repository.synchronize(account.id);
  _require(
    repository.noteById(note.localId)!.syncState !=
            NoteSyncState.deletedRemotely &&
        repository.noteById(note.localId)!.hasPendingChanges,
    'Injected collection 404 poisoned pending work.',
  );
  connection.nextPutRetryAfter = '3600';
  await repository.synchronize(account.id);
  note = repository.noteById(note.localId)!;
  _require(
    note.syncState == NoteSyncState.throttled && note.retryNotBefore != null,
    'Injected throttle did not preserve a deadline.',
  );
  final updates = connection.noteUpdates;
  await repository.synchronize(account.id);
  _require(
    connection.noteUpdates == updates &&
        repository.noteById(note.localId)!.hasPendingChanges,
    'Write retried before the throttle deadline.',
  );
  setClock(note.retryNotBefore!.add(const Duration(seconds: 1)));
  await repository.synchronize(account.id);
  setClock(null);
  checks['simulatedCollection404AndThrottlingAroundRealRequests'] = true;
  final staged = await repository.addAttachment(
    note.localId,
    filename: 'lost-upload.txt',
    bytes: Uint8List.fromList([1, 2, 3]),
  );
  await repository.save(
    note.localId,
    content:
        '${repository.noteById(note.localId)!.content}\n[lost](${staged.reference})',
  );
  connection.loseNextUploadResponse = true;
  await repository.synchronize(account.id);
  final uploads = connection.attachmentUploads;
  await repository.synchronize(account.id);
  _require(
    connection.attachmentUploads == uploads &&
        (await repository.attachments(
              note.localId,
            )).singleWhere((a) => a.id == staged.id).state ==
            'uncertain',
    'Lost upload was repeated automatically.',
  );
  checks['lostRealUploadResponsePreservesUncertainty'] = true;
  // Explicitly remove the note; uncertain attachment bytes remain in local recovery.
  await repository.delete(note.localId);
  createdIds.remove(note.serverId!);
}

Future<void> _reviewCorrections(
  _Connection connection,
  NextcloudAccount account,
  NotesApiClient Function(NextcloudAccount) api,
  Set<int> createdIds,
  Map<String, Object?> checks,
  Directory directory,
) async {
  var now = DateTime.now();
  Future<NotesRepository> open() async {
    final r = NotesRepository(
      store: await NotesStore.open(path: '${directory.path}/review.sqlite3'),
      clientForAccount: (a) async => api(a),
      clock: () => now,
    );
    await r.initialize();
    if (r.accounts.isEmpty) await r.upsertAccount(account);
    return r;
  }

  var r = await open();
  Future<void> restart() async {
    await r.dispose();
    r = await open();
  }

  try {
    final owned = await r.create(
      account.id,
      title: 'Review auth and Unicode',
      category: 'BusyMarkReview',
      content: 'body',
    );
    await r.synchronize(account.id);
    final id = owned.localId;
    createdIds.add(r.noteById(id)!.serverId!);
    await r.save(id, content: 'durable authenticated edit');
    connection.rejectNextPutCredentials = true;
    await r.synchronize(account.id);
    _require(
      r.noteById(id)!.syncState == NoteSyncState.reconnectRequired,
      'Real invalid-credential PUT did not produce an authentication block.',
    );
    await restart();
    // The account identity and valid app password came from the verified Login
    // Flow; this authenticated read verifies the restored credential boundary.
    await api(account).list();
    await r.upsertAccount(account, reconnect: true);
    await r.synchronize(account.id);
    _require(
      r.noteById(id)!.syncState == NoteSyncState.synced &&
          (await api(account).get(r.noteById(id)!.serverId!)).content ==
              'durable authenticated edit',
      'Restart/reconnect did not resume the real authenticated write.',
    );
    checks['real401RestartVerifiedReconnectResumesWrite'] = true;

    await r.save(id, content: 'first throttled edit');
    connection.nextPutRetryAfter = '600';
    await r.synchronize(account.id);
    final deadline = r.noteById(id)!.retryNotBefore!;
    final updates = connection.noteUpdates;
    await r.save(id, content: 'content edited while throttled');
    await r.patchMetadata(
      r.metadataSnapshot(id),
      category: 'BusyMarkReview/Edited',
    );
    await restart();
    await r.synchronize(account.id);
    _require(
      r.noteById(id)!.retryNotBefore == deadline &&
          connection.noteUpdates == updates,
      'Content/metadata editing or restart bypassed injected Retry-After.',
    );
    now = deadline;
    await r.synchronize(account.id);
    _require(
      r.noteById(id)!.syncState == NoteSyncState.synced &&
          connection.noteUpdates == updates + 1,
      'Expired throttle did not publish the edited revision.',
    );
    checks['simulated429ContentMetadataRestartDeadlineExpiryRealPublication'] =
        true;
    now = DateTime.now();

    final bytes = Uint8List.fromList([1, 2, 3, 4]);
    final attachment = await r.addAttachment(
      id,
      filename: 'café.png',
      bytes: bytes,
    );
    await r.save(id, content: '![unicode](${attachment.reference})');
    await r.synchronize(account.id);
    final path = (await r.attachments(
      id,
    )).singleWhere((a) => a.id == attachment.id).remotePath!;
    await r.save(id, content: '<img src="$path">');
    await r.synchronize(account.id);
    for (final destination in [path, attachmentMarkdownReference(path)]) {
      final file = await r.resolveMedia(account.id, id, destination);
      _require(
        file != null &&
            base64Encode(await File(file).readAsBytes()) == base64Encode(bytes),
        'Literal/encoded Unicode HTML media failed.',
      );
    }
    final downloaded = await api(account).fetchAttachment(
      r.noteById(id)!.serverId!,
      path,
      destination: File('${directory.path}/unicode-review.png'),
    );
    _require(
      base64Encode(await downloaded.readAsBytes()) == base64Encode(bytes),
      'Real Unicode download did not round trip.',
    );
    checks['literalAndEncodedUnicodeHtmlUploadPublicationDownload'] = true;

    var sequence = 0;
    final prefix = DateTime.now().microsecondsSinceEpoch;
    for (final draft in [false, true]) {
      for (final resolution in [
        NoteConflictResolution.takeRemote,
        NoteConflictResolution.keepLocal,
        NoteConflictResolution.merge,
        NoteConflictResolution.saveAsNew,
      ]) {
        final suffix = '$prefix-${sequence++}';
        final a = 'A-$suffix', b = 'B-$suffix', c = 'C-$suffix';
        final note = await r.create(
          account.id,
          title: a,
          category: 'BusyMarkReview/Choices',
          content: 'choice body',
        );
        if (!draft) {
          await r.synchronize(account.id);
          createdIds.add(r.noteById(note.localId)!.serverId!);
        }
        final snapshot = r.metadataSnapshot(note.localId);
        await r.patchMetadata(snapshot, title: b);
        await r.patchMetadata(snapshot, title: c);
        await restart();
        await r.resolveConflict(
          note.localId,
          resolution,
          metadataChoices: {NotesMergeAttribute.title: NotesMergeChoice.remote},
        );
        final chosen = resolution == NoteConflictResolution.saveAsNew
            ? r.notes.singleWhere(
                (n) =>
                    n.localId != note.localId &&
                    n.title == c &&
                    n.serverId == null,
              )
            : r.noteById(note.localId)!;
        await r.synchronize(account.id);
        final published = r.noteById(chosen.localId)!;
        createdIds.add(published.serverId!);
        final expected =
            resolution == NoteConflictResolution.takeRemote ||
                resolution == NoteConflictResolution.merge
            ? b
            : c;
        _require(
          published.title == expected &&
              (await api(account).get(published.serverId!)).title == expected,
          'Reviewed local choice was substituted during real server synchronization.',
        );
      }
    }
    checks['serverAndDraftEveryReviewedMetadataChoiceRestartRealSync'] = true;
  } finally {
    await r.dispose();
  }
}

Future<void> _metadataRaceChecks(
  _Connection connection,
  NextcloudAccount account,
  NotesApiClient Function(NextcloudAccount) api,
  Set<int> createdIds,
  Map<String, Object?> checks,
  Directory directory,
) async {
  var now = DateTime.now();
  Future<NotesRepository> open() async {
    final r = NotesRepository(
      store: await NotesStore.open(
        path: '${directory.path}/metadata-race.sqlite3',
      ),
      clientForAccount: (a) async => api(a),
      clock: () => now,
    );
    await r.initialize();
    if (r.accounts.isEmpty) await r.upsertAccount(account);
    return r;
  }

  var r = await open();
  Future<void> restart() async {
    await r.dispose();
    r = await open();
  }

  var sequence = 0;
  final prefix = DateTime.now().microsecondsSinceEpoch;
  try {
    for (final draft in [false, true]) {
      for (final status in [200, 429, 503]) {
        for (final choice in [
          NoteConflictResolution.takeRemote,
          NoteConflictResolution.keepLocal,
        ]) {
          now = DateTime.now();
          final suffix = '$prefix-${sequence++}';
          final a = 'Race A-$suffix',
              b = 'Race B-$suffix',
              c = 'Race C-$suffix';
          final note = await r.create(
            account.id,
            title: a,
            category: 'BusyMarkRace',
            content: 'race body',
          );
          if (!draft) {
            await r.synchronize(account.id);
            createdIds.add(r.noteById(note.localId)!.serverId!);
          }
          final snapshot = r.metadataSnapshot(note.localId);
          await r.patchMetadata(snapshot, title: b);
          final sent = r.noteById(note.localId)!;
          final held = _HeldWrite(status);
          connection.holdNextWrite = held;
          final sending = r.synchronize(account.id);
          late int revision, requests;
          try {
            await Future.any([
              held.started.future,
              sending.then<void>((_) => throw StateError('No held write.')),
            ]);
            await r.patchMetadata(snapshot, title: c);
            revision = r.noteById(note.localId)!.revision;
            requests = connection.noteUpdates + connection.noteCreates;
          } finally {
            held.release.complete();
          }
          await sending;
          if (held.executedId != null) createdIds.add(held.executedId!);
          var current = r.noteById(note.localId)!;
          if (current.serverId != null) createdIds.add(current.serverId!);
          _require(
            current.revision == revision &&
                current.ackRevision ==
                    (status == 200 ? sent.revision : sent.ackRevision) &&
                current.title == c &&
                current.metadataConflict?.alternative.title == b,
            'Older held response lost the reviewed revision or alternatives.',
          );
          now = now.add(const Duration(minutes: 1));
          await r.synchronize(account.id);
          await restart();
          await r.synchronize(account.id);
          _require(
            connection.noteUpdates + connection.noteCreates == requests,
            'Unresolved metadata published after response/retry/restart.',
          );
          await r.resolveConflict(note.localId, choice);
          final expected = choice == NoteConflictResolution.takeRemote ? b : c;
          current = r.noteById(note.localId)!;
          _require(
            current.title == expected,
            'Explicit metadata choice was substituted.',
          );
          if (draft && status == 503) {
            await r.synchronize(account.id);
            _require(
              connection.noteUpdates + connection.noteCreates == requests &&
                  r.noteById(note.localId)!.syncState ==
                      NoteSyncState.creationUncertain,
              'Metadata resolution released an uncertain real creation.',
            );
            final candidate = r
                .uncertainCreationCandidates(note.localId)
                .singleWhere((n) => n.serverId == held.executedId);
            await r.resolveConflict(
              note.localId,
              NoteConflictResolution.useServerNote,
              creationCandidateServerId: candidate.serverId,
              creationReview: r.creationReview(note.localId, candidate.base!),
            );
          } else if (current.syncState == NoteSyncState.conflict) {
            // A simulated failed response may follow a real accepted PUT. Review
            // that actual server observation separately from the B/C decision.
            await r.resolveConflict(
              note.localId,
              NoteConflictResolution.keepLocal,
            );
          }
          await r.synchronize(account.id);
          current = r.noteById(note.localId)!;
          createdIds.add(current.serverId!);
          _require(
            current.syncState == NoteSyncState.synced &&
                current.title == expected &&
                (await api(account).get(current.serverId!)).title == expected,
            'Selected race alternative did not synchronize to the real server.',
          );
        }
      }
    }
    checks['heldPutPostResponsesMetadataAlternativesRetryRestartRealSync'] =
        true;
    checks['heldPossiblyExecutedPostRequiresSeparateCreationDecision'] = true;
  } finally {
    await r.dispose();
  }
}

Future<void> _everydayWorkspaceChecks(
  NotesRepository r,
  _Connection connection,
  NextcloudAccount account,
  NotesApiClient Function(NextcloudAccount) api,
  Set<int> owned,
  Map<String, Object?> checks,
  String root,
) async {
  connection.offline = true;
  final draft = await r.create(
    account.id,
    title: 'M2 portable 同じ',
    category: 'M2/子/Sub',
    content: 'pending alpha beta café 中文 foo_bar',
  );
  final attachment = await r.addAttachment(
    draft.localId,
    filename: 'café%20.png',
    bytes: Uint8List.fromList([1, 2, 3]),
  );
  await r.save(
    draft.localId,
    content:
        'pending alpha beta café 中文 foo_bar\n![image](${attachment.reference})\n<img src="${attachment.reference}">',
  );
  final second = await r.create(
    account.id,
    title: draft.title,
    category: draft.category,
    content: 'duplicate alpha beta',
  );
  final outcomes = await r.patchMetadataBatch([
    r.metadataSnapshot(draft.localId),
    r.metadataSnapshot(second.localId),
  ], favorite: true);
  _require(
    outcomes.every((o) => o.status == NotesBatchStatus.changed),
    'Offline batch did not persist every reviewed note.',
  );
  final search = NotesSearchController(r.store, account.id);
  await search.search('"alpha beta" category:"M2/子"');
  _require(
    search.state.error == null &&
        search.state.hits.any((h) => h.localId == draft.localId),
    'Indexed pending note search failed.',
  );
  await search.dispose();
  connection.offline = false;
  await r.synchronize(account.id);
  for (final note in [draft, second]) {
    final published = r.noteById(note.localId)!;
    if (published.serverId != null) owned.add(published.serverId!);
    _require(
      published.syncState == NoteSyncState.synced,
      'Offline organization did not synchronize: ${published.syncState.name}; ${published.errorMessage}; deadline=${published.retryNotBefore}; scope=${published.failureScope}',
    );
    final actual = await api(account).get(published.serverId!);
    _require(
      actual.favorite && actual.category == 'M2/子/Sub',
      'Server metadata did not match the batch.',
    );
  }
  checks['m2OfflineBatchIndexedPendingTextRealSync'] = true;
  var offline = NotesOfflineController(r, account.id);
  await offline.initialize();
  await offline.setRequirement('category', 'M2');
  await offline.reconcile();
  final published = r.noteById(draft.localId)!;
  _require(
    (await offline.inspect(published)).available,
    'Category retention is incomplete.',
  );
  connection.offline = true;
  final media = await r.attachmentAvailability(draft.localId);
  _require(
    media.required.isNotEmpty &&
        media.available.length == media.required.length,
    'Retained bytes unavailable offline.',
  );
  final export = await NotesTransferService(r).exportSnapshot(
    notes: [published, r.noteById(second.localId)!],
    destination: root,
    cancellation: NotesTransferCancellation(),
  );
  _require(export.complete, 'Portable snapshot silently omitted media.');
  final review = await NotesTransferService(r).review(export.path, account.id);
  _require(
    review.items.length == 2 && review.items.every((i) => i.collision),
    'Import review lost duplicate title collisions.',
  );
  final imported = await NotesTransferService(r).importReviewed(
    review,
    account.id,
    cancellation: NotesTransferCancellation(),
  );
  _require(imported.every((i) => i.noteId != null), 'Portable import failed.');
  final repeated = await NotesTransferService(r).importReviewed(
    review,
    account.id,
    cancellation: NotesTransferCancellation(),
  );
  _require(
    repeated.every((i) => i.alreadyImported),
    'Resume duplicated a completed import.',
  );
  checks['m2RetainedCategoryPortableMarkdownHtmlMediaDuplicateRoundTrip'] =
      true;
  await offline.dispose();
  connection.offline = false;
  await r.delete(draft.localId);
  owned.remove(published.serverId);
  final recovered = await r.recoverAsNew(draft.localId);
  _require(
    recovered.localId != draft.localId && recovered.serverId == null,
    'Recovery overwrote an existing identity.',
  );
  await r.synchronize(account.id);
  for (final id in [recovered.localId, ...imported.map((i) => i.noteId!)]) {
    final note = r.noteById(id)!;
    if (note.serverId != null) owned.add(note.serverId!);
    _require(
      note.syncState == NoteSyncState.synced,
      'Recovered/imported media did not synchronize.',
    );
    final actual = await api(account).get(note.serverId!);
    _require(
      actual.favorite && actual.category == 'M2/子/Sub',
      'Round trip lost exact organization metadata.',
    );
  }
  checks['m2DeletedNoteRetainedMediaRecoveryAndImportedRealPublication'] = true;
}
