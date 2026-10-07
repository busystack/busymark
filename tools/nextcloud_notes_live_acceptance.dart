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

class _Connection extends http.BaseClient {
  _Connection(this._client);
  final http.Client _client;
  bool offline = false;
  bool loseNextCreateResponse = false;
  int noteCreates = 0;
  int chunkRequests = 0;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (offline) throw http.ClientException('Intentional offline acceptance.');
    if (request.url.queryParameters.containsKey('chunkCursor')) chunkRequests++;
    final creation =
        request.method == 'POST' && request.url.path.endsWith('/v1/notes');
    if (creation) noteCreates++;
    final response = await _client.send(request);
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
      );
      await result.initialize();
      return result;
    }

    repository = await reopen();
    await repository.upsertAccount(account);
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
    checks['uncertainCreateStagedAttachmentSanitizationRestartNoDuplicate'] =
        true;

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
    await File(arguments[1]).writeAsString(
      const JsonEncoder.withIndent(
        '  ',
      ).convert({'ok': true, 'checks': checks}),
      flush: true,
    );
    stdout.writeln(
      'Live Nextcloud Notes acceptance passed (${checks.length} checks).',
    );
  } on Object catch (error) {
    await File(arguments[1]).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'ok': false,
        'checks': checks,
        'failureType': error.runtimeType.toString(),
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
