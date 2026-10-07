import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:busymark/src/nextcloud_notes/application/notes_repository.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_api_client.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_store.dart';
import 'package:busymark/src/nextcloud_notes/domain/notes_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqlite3/sqlite3.dart';

import 'notes_api_test.dart' show serverNote, testAccount;

void main() {
  late Directory root;
  late NotesRepository repository;
  late MockClient transport;
  final remotes = <int, Map<String, dynamic>>{};
  var creates = 0;
  var puts = 0;
  var uploads = 0;
  var deliverCreate = true;
  Future<http.Response> Function(http.Request)? getCandidate;
  Future<void> reopen() async {
    repository = NotesRepository(
      store: await NotesStore.open(path: '${root.path}/notes.sqlite3'),
      clientForAccount: (account) async => NotesApiClient(
        client: transport,
        account: account,
        appPassword: 'test',
      ),
    );
    await repository.initialize();
    if (repository.accounts.isEmpty) {
      await repository.upsertAccount(testAccount());
    }
  }

  Future<NextcloudNote> uncertain({String content = 'submitted'}) async {
    final note = await repository.create(testAccount().id, content: content);
    await repository.synchronize(note.accountId);
    expect(
      repository.noteById(note.localId)!.syncState,
      NoteSyncState.creationUncertain,
    );
    return repository.noteById(note.localId)!;
  }

  NotesCreationReview review(String id) =>
      repository.creationReview(id, repository.noteById(id)!.remote!);
  Future<void> adopt(NotesCreationReview reviewed) =>
      repository.resolveConflict(
        reviewed.localId,
        NoteConflictResolution.useServerNote,
        expectedRevision: reviewed.revision,
        creationCandidateServerId: reviewed.candidate.id,
        creationReview: reviewed,
      );
  setUp(() async {
    root = await Directory.systemTemp.createTemp('creation-policy-');
    remotes.clear();
    creates = puts = uploads = 0;
    deliverCreate = true;
    getCandidate = null;
    transport = MockClient((request) async {
      if (request.method == 'POST' && request.url.path.endsWith('/notes')) {
        creates++;
        if (deliverCreate) {
          remotes[1] = {...serverNote(1), ...jsonDecode(request.body) as Map};
        }
        throw http.ClientException('lost response');
      }
      if (request.method == 'GET' && request.url.path.endsWith('/notes')) {
        return http.Response(jsonEncode(remotes.values.toList()), 200);
      }
      if (request.method == 'GET') {
        if (getCandidate != null) return getCandidate!(request);
        final remote = remotes[int.parse(request.url.pathSegments.last)];
        return http.Response(
          remote == null ? '{}' : jsonEncode(remote),
          remote == null ? 404 : 200,
        );
      }
      if (request.method == 'PUT') {
        puts++;
        final id = int.parse(request.url.pathSegments.last);
        expect(request.headers['If-Match'], '"${remotes[id]!['etag']}"');
        remotes[id] = {
          ...remotes[id]!,
          ...jsonDecode(request.body) as Map,
          'etag': 'updated-$puts',
        };
        return http.Response(jsonEncode(remotes[id]), 200);
      }
      if (request.method == 'POST') {
        uploads++;
        return http.Response('{"filename":".attachments.1/photo.png"}', 200);
      }
      fail('Unexpected mutation: ${request.method}');
    });
    await reopen();
  });
  tearDown(() async {
    await repository.dispose();
    await root.delete(recursive: true);
  });

  for (final scenario in [
    'exact',
    'sanitized',
    'multiple',
    'none',
    'empty',
    'other actor',
  ]) {
    test(
      '$scenario discovery across refresh reconnect and restart cannot bind or mutate draft',
      () async {
        deliverCreate = scenario != 'other actor';
        final note = await uncertain(
          content: scenario == 'empty' ? '' : 'submitted',
        );
        final attachment = await repository.addAttachment(
          note.localId,
          filename: 'photo.png',
          bytes: Uint8List.fromList([1, 2, 3]),
        );
        await repository.save(
          note.localId,
          content: '${note.content}\n![photo](${attachment.reference})',
        );
        final immutable = note.creationAttempt!.wireBody;
        if (scenario == 'other actor') {
          remotes[1] = {...serverNote(1), ...note.creationAttempt!.attributes};
        }
        if (scenario == 'none') remotes.clear();
        if (scenario == 'sanitized') remotes[1]!['title'] = 'Sanitized';
        if (scenario == 'multiple') remotes[2] = {...remotes[1]!, 'id': 2};
        final before = jsonEncode(remotes.values.toList());
        for (var i = 0; i < 3; i++) {
          await repository.synchronize(note.accountId);
          await repository.dispose();
          await reopen();
          await repository.upsertAccount(testAccount());
          final pending = repository.noteById(note.localId)!;
          expect(pending.serverId, isNull);
          expect(pending.ackRevision, 0);
          expect(pending.creationAttempt!.id, note.creationAttempt!.id);
          expect(pending.creationAttempt!.wireBody, immutable);
          expect(
            pending.creationAttempt!.candidateServerIds,
            scenario == 'none'
                ? <int>{}
                : scenario == 'multiple'
                ? {1, 2}
                : {1},
          );
          expect(pending.content, contains('busymark-attachment:'));
          expect(await repository.store.attachmentBytes(attachment.id), [
            1,
            2,
            3,
          ]);
          await expectLater(
            repository.delete(note.localId),
            throwsA(isA<NotesException>()),
          );
          await expectLater(
            repository.retryUncertainAttachments(note.localId),
            throwsA(isA<NotesException>()),
          );
        }
        expect(creates, 1);
        expect(puts, 0);
        expect(uploads, 0);
        expect(jsonEncode(remotes.values.toList()), before);
        // The unresolved draft cannot stop an independently pending update.
        remotes[9] = serverNote(9);
        await repository.synchronize(note.accountId);
        final other = repository.notes.firstWhere((n) => n.serverId == 9);
        await repository.save(other.localId, content: 'unrelated edit');
        await repository.synchronize(note.accountId);
        expect(remotes[9]!['content'], 'unrelated edit');
        expect(repository.noteById(note.localId)!.serverId, isNull);
        expect(puts, 1);
      },
    );
  }

  for (final change in [
    'content',
    'readonly',
    'error',
    'deleted',
    'unavailable',
  ]) {
    test(
      'confirmation rejects $change candidate and retains unresolved work',
      () async {
        final note = await uncertain();
        await repository.synchronize(note.accountId);
        final reviewed = review(note.localId);
        switch (change) {
          case 'content':
            remotes[1]!['content'] = 'external edit';
          case 'readonly':
            remotes[1]!['readonly'] = true;
          case 'error':
            remotes[1]!['error'] = true;
          case 'deleted':
            remotes.remove(1);
          case 'unavailable':
            getCandidate = (_) async => http.Response('{}', 503);
        }
        await expectLater(adopt(reviewed), throwsA(isA<NotesException>()));
        final pending = repository.noteById(note.localId)!;
        expect(pending.serverId, isNull);
        expect(pending.content, 'submitted');
        expect(pending.creationAttempt!.id, reviewed.attemptId);
        expect(puts, 0);
        expect(creates, 1);
        if (change == 'content') {
          expect(pending.remote!.content, 'external edit');
        }
      },
    );
  }

  for (final race in ['local edit', 'account removal', 'repeat confirmation']) {
    test('confirmation revalidates $race during authenticated GET', () async {
      final note = await uncertain();
      await repository.synchronize(note.accountId);
      final reviewed = review(note.localId);
      final entered = Completer<void>();
      final response = Completer<http.Response>();
      getCandidate = (_) {
        entered.complete();
        return response.future;
      };
      final confirmation = adopt(reviewed);
      final check = race == 'repeat confirmation'
          ? expectLater(confirmation, completes)
          : expectLater(confirmation, throwsA(isA<NotesException>()));
      await entered.future;
      switch (race) {
        case 'local edit':
          await repository.save(note.localId, content: 'new local revision');
        case 'account removal':
          await repository.removeAccount(note.accountId);
        case 'repeat confirmation':
          await expectLater(adopt(reviewed), throwsA(isA<NotesException>()));
      }
      response.complete(http.Response(jsonEncode(remotes[1]), 200));
      await check;
      if (race == 'local edit') {
        expect(
          repository.noteById(note.localId)!.content,
          'new local revision',
        );
        expect(repository.noteById(note.localId)!.serverId, isNull);
      }
      if (race == 'account removal') expect(repository.notes, isEmpty);
      if (race == 'repeat confirmation') {
        await expectLater(adopt(reviewed), throwsA(isA<NotesException>()));
        expect(repository.noteById(note.localId)!.serverId, 1);
      }
      expect(puts, 0);
    });
  }

  for (final competing in [
    'durable edit',
    'pending attachment',
    'open editor',
  ]) {
    test('binding protects downloaded candidate with $competing', () async {
      final note = await uncertain();
      await repository.synchronize(note.accountId);
      final reviewed = review(note.localId);
      final twin = repository.notes.firstWhere((n) => n.serverId == 1);
      if (competing == 'durable edit') {
        await repository.save(twin.localId, content: 'twin edit');
      }
      if (competing == 'pending attachment') {
        await repository.addAttachment(
          twin.localId,
          filename: 'photo.png',
          bytes: Uint8List.fromList([4, 5]),
        );
      }
      if (competing == 'open editor') {
        repository.addCreationBindingGuard(
          (localId, ids) => !ids.contains(twin.localId),
        );
      }
      await expectLater(adopt(reviewed), throwsA(isA<NotesException>()));
      expect(repository.noteById(note.localId)!.serverId, isNull);
      expect(repository.noteById(twin.localId), isNotNull);
      await repository.dispose();
      await reopen();
      expect(repository.noteById(twin.localId), isNotNull);
    });
  }

  test(
    'failed adoption transaction rolls back binding and downloaded identity',
    () async {
      final note = await uncertain();
      await repository.synchronize(note.accountId);
      final reviewed = review(note.localId);
      final twin = repository.notes.firstWhere((n) => n.serverId == 1);
      final db = sqlite3.open(repository.store.path);
      db.execute(
        "CREATE TRIGGER fail_binding BEFORE UPDATE ON notes WHEN NEW.server_id=1 AND NEW.id='${note.localId}' BEGIN SELECT RAISE(ABORT,'fixture'); END",
      );
      await expectLater(adopt(reviewed), throwsA(isA<StateError>()));
      expect(repository.noteById(note.localId)!.serverId, isNull);
      expect(repository.noteById(twin.localId), isNotNull);
      db.execute('DROP TRIGGER fail_binding');
      db.close();
      await repository.dispose();
      await reopen();
      expect(repository.noteById(note.localId)!.serverId, isNull);
      expect(repository.noteById(twin.localId), isNotNull);
      await adopt(review(note.localId));
      await repository.dispose();
      await reopen();
      expect(repository.noteById(note.localId)!.serverId, 1);
      expect(repository.noteById(twin.localId), isNull);
      expect(repository.noteById(note.localId)!.creationAttempt, isNull);
    },
  );

  test(
    'separate-note decision is durable and repeated confirmation makes one replacement',
    () async {
      final note = await uncertain();
      await repository.synchronize(note.accountId);
      await repository.resolveConflict(
        note.localId,
        NoteConflictResolution.saveAsNew,
      );
      await repository.resolveConflict(
        note.localId,
        NoteConflictResolution.saveAsNew,
      );
      final separateId = repository
          .noteById(note.localId)!
          .creationAttempt!
          .separateNoteLocalId;
      expect(separateId, isNotNull);
      expect(repository.notes, hasLength(3));
      await repository.dispose();
      await reopen();
      await repository.resolveConflict(
        note.localId,
        NoteConflictResolution.saveAsNew,
      );
      expect(repository.notes, hasLength(3));
      expect(repository.noteById(separateId!)!.content, 'submitted');
      await expectLater(
        adopt(review(note.localId)),
        throwsA(isA<NotesException>()),
      );
    },
  );
}
