import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:busymark/src/nextcloud_notes/application/notes_repository.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_api_client.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_attachment_references.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_store.dart';
import 'package:busymark/src/nextcloud_notes/domain/notes_conflict.dart';
import 'package:busymark/src/nextcloud_notes/domain/notes_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'notes_api_test.dart' show testAccount, serverNote;

class _Fixture {
  late Directory directory;
  late NotesRepository repository;
  DateTime now = DateTime.utc(2026, 10, 9, 12);
  final remotes = <int, Map<String, Object?>>{
    1: {...serverNote(1), 'title': 'A'},
  };
  int writes = 0;
  int reads = 0;
  int uploads = 0;
  int rejection = 0;
  String? retryAfter;
  final downloaded = <String>[];
  Future<void>? writeGate;
  late final transport = MockClient((request) async {
    expect(request.headers['authorization'], startsWith('Basic '));
    final path = request.url.path;
    const root = '/nextcloud/index.php/apps/notes/api/';
    if (path == '${root}v1/notes' && request.method == 'GET') {
      reads++;
      return http.Response(
        jsonEncode(remotes.values.toList()),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }
    if (path == '${root}v1.4/attachment/1') {
      if (request.method == 'GET') {
        downloaded.add(request.url.queryParameters['path']!);
        return http.Response.bytes([1, 2, 3], 200);
      }
      expect(request.method, 'POST');
      uploads++;
      return http.Response(
        jsonEncode('.attachments.1/caf\u00e9.png'),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }
    if (path == '${root}v1/notes' && request.method == 'POST') {
      writes++;
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final id = remotes.keys.fold(1, (int a, b) => a > b ? a : b) + 1;
      final remote = {
        ...serverNote(id),
        ...body,
        'id': id,
        'etag': 'created-$id',
      };
      remotes[id] = remote;
      return http.Response(
        jsonEncode(remote),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }
    expect(path, '${root}v1/notes/1');
    if (request.method == 'GET') {
      return http.Response(
        jsonEncode(remotes[1]),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }
    expect(request.method, 'PUT');
    expect(request.headers['if-match'], '"${remotes[1]!['etag']}"');
    writes++;
    await writeGate;
    if (rejection != 0) {
      return http.Response(
        '{}',
        rejection,
        headers: {if (retryAfter != null) 'Retry-After': retryAfter!},
      );
    }
    remotes[1] = {
      ...remotes[1]!,
      ...jsonDecode(request.body) as Map<String, dynamic>,
      'etag': 'write-$writes',
    };
    return http.Response(
      jsonEncode(remotes[1]),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });

  Future<void> open() async {
    repository = NotesRepository(
      store: await NotesStore.open(path: '${directory.path}/notes.sqlite3'),
      clock: () => now,
      clientForAccount: (account) async => NotesApiClient(
        client: transport,
        account: account,
        appPassword: 'fixture',
        clock: () => now,
      ),
    );
    await repository.initialize();
    if (repository.accounts.isEmpty) {
      await repository.upsertAccount(testAccount());
    }
  }

  Future<void> restart() async {
    await repository.dispose();
    await open();
  }

  Future<String> seed() async {
    await repository.synchronize(testAccount().id, allowWrites: false);
    return repository.notes.single.localId;
  }
}

void main() {
  late _Fixture f;
  setUp(() async {
    f = _Fixture();
    f.directory = await Directory.systemTemp.createTemp('notes-review-');
    await f.open();
  });
  tearDown(() async {
    await f.repository.dispose();
    f.transport.close();
    await f.directory.delete(recursive: true);
  });

  for (final restart in [false, true]) {
    test(
      'verified reconnect resumes a 401-blocked write, restart=$restart',
      () async {
        final id = await f.seed();
        await f.repository.save(id, content: 'durable authenticated edit');
        f.rejection = 401;
        await f.repository.synchronize(testAccount().id);
        expect(
          f.repository.noteById(id)!.syncState,
          NoteSyncState.reconnectRequired,
        );
        if (restart) await f.restart();
        f.rejection = 0;
        await f.repository.upsertAccount(testAccount(), reconnect: true);
        await f.repository.synchronize(testAccount().id);
        expect(f.writes, 2);
        expect(f.repository.noteById(id)!.syncState, NoteSyncState.synced);
        expect(f.remotes[1]!['content'], 'durable authenticated edit');
      },
    );
  }

  test(
    'reconnect recovers legacy persisted authentication blocks without changing acknowledgments',
    () async {
      final id = await f.seed();
      await f.repository.save(id, content: 'persisted edit');
      f.rejection = 401;
      await f.repository.synchronize(testAccount().id);
      final blocked = f.repository.noteById(id)!;
      await f.repository.store.saveNote(
        blocked.copyWith(failureCode: null, failureScope: null),
      );
      await f.restart();
      await f.repository.upsertAccount(testAccount(), reconnect: true);
      expect(f.repository.noteById(id)!.ackRevision, blocked.ackRevision);
      expect(f.repository.noteById(id)!.revision, blocked.revision);
      f.rejection = 0;
      await f.repository.synchronize(testAccount().id);
      expect(f.repository.noteById(id)!.syncState, NoteSyncState.synced);
    },
  );

  test(
    'reconnection finishes an older credential request before releasing its block',
    () async {
      final id = await f.seed();
      await f.repository.save(id, content: 'pending across reconnect');
      f.rejection = 401;
      final gate = Completer<void>();
      f.writeGate = gate.future;
      final sending = f.repository.synchronize(testAccount().id);
      while (f.writes == 0) {
        await Future<void>.delayed(Duration.zero);
      }
      var reconnected = false;
      final reconnect = f.repository
          .upsertAccount(testAccount(), reconnect: true)
          .then((_) => reconnected = true);
      await f.repository.save(
        id,
        content: 'newer durable edit during reconnect',
      );
      expect(reconnected, isFalse);
      gate.complete();
      await sending;
      await reconnect;
      f.rejection = 0;
      await f.repository.synchronize(testAccount().id);
      expect(f.repository.noteById(id)!.syncState, NoteSyncState.synced);
      expect(f.remotes[1]!['content'], 'newer durable edit during reconnect');
    },
  );

  test(
    'reconnect preserves changed-server conflicts and uncertain creation/upload evidence',
    () async {
      final id = await f.seed();
      await f.repository.save(id, content: 'pending conflict');
      f.rejection = 401;
      await f.repository.synchronize(testAccount().id);
      final draft = await f.repository.create(
        testAccount().id,
        content: 'uncertain draft',
      );
      final attempt = NotesCreationAttempt(
        id: 'attempt',
        revision: draft.revision,
        localContent: draft.content,
        wireBody: '{"content":"uncertain draft"}',
        knownServerIds: {1},
      );
      await f.repository.store.saveNote(
        draft.copyWith(
          syncState: NoteSyncState.creationUncertain,
          creationNeverSent: false,
          creationAttempt: attempt,
        ),
      );
      final attachment = await f.repository.addAttachment(
        id,
        filename: 'a.png',
        bytes: Uint8List.fromList([4, 5]),
      );
      await f.repository.store.updateAttachment(
        NotesAttachment(
          id: attachment.id,
          noteId: id,
          filename: attachment.filename,
          reference: attachment.reference,
          state: 'uncertain',
        ),
      );
      await f.restart();
      f.remotes[1] = {
        ...f.remotes[1]!,
        'title': 'real remote change',
        'etag': 'remote-change',
      };
      f.rejection = 0;
      await f.repository.upsertAccount(testAccount(), reconnect: true);
      await f.repository.synchronize(testAccount().id);
      expect(f.repository.noteById(id)!.syncState, NoteSyncState.conflict);
      expect(
        f.repository.noteById(draft.localId)!.syncState,
        NoteSyncState.creationUncertain,
      );
      expect(
        f.repository.noteById(draft.localId)!.creationAttempt!.wireBody,
        attempt.wireBody,
      );
      expect(
        (await f.repository.store.attachments(id)).single.state,
        'uncertain',
      );
      expect(await f.repository.store.attachmentBytes(attachment.id), [4, 5]);
      expect(f.writes, 1);
      expect(f.uploads, 0);
    },
  );

  for (final draft in [false, true]) {
    for (final resolution in [
      NoteConflictResolution.keepLocal,
      NoteConflictResolution.takeRemote,
      NoteConflictResolution.merge,
      NoteConflictResolution.saveAsNew,
    ]) {
      test(
        'reviewed B/C metadata choice survives resolution and sync: draft=$draft $resolution',
        () async {
          final id = draft
              ? (await f.repository.create(
                  testAccount().id,
                  title: 'A',
                  content: 'body',
                )).localId
              : await f.seed();
          final snapshot = f.repository.metadataSnapshot(id);
          await f.repository.patchMetadata(snapshot, title: 'B');
          await f.repository.patchMetadata(snapshot, title: 'C');
          final conflict = f.repository.noteById(id)!;
          expect(conflict.syncState, NoteSyncState.conflict);
          expect(conflict.title, 'C');
          await f.restart();
          await f.repository.resolveConflict(
            id,
            resolution,
            expectedRevision: conflict.revision,
            metadataChoices: {
              NotesMergeAttribute.title: NotesMergeChoice.remote,
            },
          );
          final expected =
              resolution == NoteConflictResolution.keepLocal ||
                  resolution == NoteConflictResolution.saveAsNew
              ? 'C'
              : 'B';
          final selected = resolution == NoteConflictResolution.saveAsNew
              ? f.repository.notes.singleWhere(
                  (n) => n.localId != id && n.serverId == null,
                )
              : f.repository.noteById(id)!;
          expect(selected.title, expected);
          expect(selected.content, 'body');
          await f.repository.synchronize(testAccount().id);
          expect(f.repository.noteById(selected.localId)!.title, expected);
          expect(
            f.repository.noteById(selected.localId)!.syncState,
            NoteSyncState.synced,
          );
          if (resolution == NoteConflictResolution.saveAsNew) {
            expect(
              f.repository.noteById(id)!.syncState,
              NoteSyncState.conflict,
            );
          }
        },
      );
    }
  }

  for (final draft in [false, true]) {
    test('metadata merge explicitly selects C, draft=$draft', () async {
      final id = draft
          ? (await f.repository.create(
              testAccount().id,
              title: 'A',
              content: 'body',
            )).localId
          : await f.seed();
      final snapshot = f.repository.metadataSnapshot(id);
      await f.repository.patchMetadata(snapshot, title: 'B');
      await f.repository.patchMetadata(snapshot, title: 'C');
      await f.repository.resolveConflict(
        id,
        NoteConflictResolution.merge,
        metadataChoices: {NotesMergeAttribute.title: NotesMergeChoice.local},
      );
      await f.repository.synchronize(testAccount().id);
      expect(f.repository.noteById(id)!.title, 'C');
      expect(f.repository.noteById(id)!.syncState, NoteSyncState.synced);
    });
  }

  test(
    'actual server changes retain the selected local alternative for another review',
    () async {
      final id = await f.seed();
      final snapshot = f.repository.metadataSnapshot(id);
      await f.repository.patchMetadata(snapshot, title: 'B');
      await f.repository.patchMetadata(snapshot, title: 'C');
      f.remotes[1] = {...f.remotes[1]!, 'title': 'D', 'etag': 'changed-again'};
      await f.repository.resolveConflict(id, NoteConflictResolution.takeRemote);
      final chosen = f.repository.noteById(id)!;
      expect(chosen.title, 'B');
      expect(chosen.remote!.title, 'D');
      expect(chosen.syncState, NoteSyncState.conflict);
      await f.repository.synchronize(testAccount().id);
      expect(f.writes, 0);
      await f.repository.resolveConflict(id, NoteConflictResolution.keepLocal);
      await f.repository.synchronize(testAccount().id);
      expect(f.remotes[1]!['title'], 'B');
    },
  );

  test(
    'take-server cannot silently substitute a value changed after review',
    () async {
      final id = await f.seed();
      await f.repository.save(id, content: 'local work');
      f.remotes[1] = {
        ...f.remotes[1]!,
        'title': 'reviewed server',
        'etag': 'second',
      };
      await f.repository.synchronize(testAccount().id, allowWrites: false);
      f.remotes[1] = {
        ...f.remotes[1]!,
        'title': 'unreviewed server',
        'etag': 'third',
      };
      await expectLater(
        f.repository.resolveConflict(id, NoteConflictResolution.takeRemote),
        throwsA(
          isA<NotesException>().having(
            (e) => e.code,
            'code',
            NotesFailureCode.conflict,
          ),
        ),
      );
      expect(f.repository.noteById(id)!.content, 'local work');
      expect(f.repository.noteById(id)!.remote!.title, 'unreviewed server');
    },
  );

  test('local metadata review revalidates read-only permission', () async {
    final id = await f.seed();
    final snapshot = f.repository.metadataSnapshot(id);
    await f.repository.patchMetadata(snapshot, title: 'B');
    await f.repository.patchMetadata(snapshot, title: 'C');
    f.remotes[1] = {...f.remotes[1]!, 'readonly': true};
    await expectLater(
      f.repository.resolveConflict(id, NoteConflictResolution.takeRemote),
      throwsA(
        isA<NotesException>().having(
          (e) => e.code,
          'code',
          NotesFailureCode.forbidden,
        ),
      ),
    );
    expect(f.repository.noteById(id)!.metadataConflict!.alternative.title, 'B');
  });

  for (final metadata in [false, true]) {
    test(
      'accepted edit retains 429 deadline through restart: metadata=$metadata',
      () async {
        final id = await f.seed();
        await f.repository.save(id, content: 'first edit');
        f.rejection = 429;
        f.retryAfter = '600';
        await f.repository.synchronize(testAccount().id);
        final deadline = f.now.add(const Duration(minutes: 10));
        f.rejection = 0;
        f.now = f.now.add(const Duration(minutes: 1));
        if (metadata) {
          await f.repository.patchMetadata(
            f.repository.metadataSnapshot(id),
            title: 'new metadata',
          );
        } else {
          await f.repository.save(id, content: 'new content');
        }
        expect(f.repository.noteById(id)!.retryNotBefore, deadline);
        await f.repository.synchronize(testAccount().id);
        expect(f.writes, 1);
        await f.restart();
        await f.repository.synchronize(testAccount().id);
        expect(f.writes, 1);
        f.now = deadline.subtract(const Duration(microseconds: 1));
        await f.repository.synchronize(testAccount().id);
        expect(f.writes, 1);
        f.now = deadline;
        await f.repository.synchronize(testAccount().id);
        expect(f.writes, 2);
        expect(f.repository.noteById(id)!.syncState, NoteSyncState.synced);
      },
    );
  }

  test(
    'literal Unicode HTML attachment resolves at the URI boundary',
    () async {
      f.remotes[1] = {
        ...f.remotes[1]!,
        'content': '<img src=".attachments.1/caf\u00e9.png">',
      };
      final id = await f.seed();
      final refs = notesAttachmentReferences(
        f.repository.noteById(id)!.content,
      );
      expect(refs.single.reference, '.attachments.1/caf\u00e9.png');
      for (final ref in [
        '.attachments.1/caf\u00e9.png',
        '.attachments.1/caf%C3%A9.png',
      ]) {
        expect(
          canonicalAttachmentReference(ref),
          '.attachments.1/caf\u00e9.png',
        );
        final file = await f.repository.resolveMedia(testAccount().id, id, ref);
        expect(await File(file!).readAsBytes(), Uint8List.fromList([1, 2, 3]));
      }
      expect(f.downloaded, ['.attachments.1/caf\u00e9.png']);
      expect(
        canonicalAttachmentReference('.attachments.1/100%25.png'),
        '.attachments.1/100%.png',
      );
      expect(
        canonicalAttachmentReference('.attachments.1/%252F.png'),
        '.attachments.1/%2F.png',
      );
      for (final unsafe in [
        '../caf\u00e9.png',
        '.attachments.1/%2e%2e/caf%C3%A9.png',
        '.attachments.1/bad%GG.png',
        '.attachments.1/bad%',
        '//foreign/image',
        '.attachments.1/a%5Cb.png',
      ]) {
        expect(canonicalAttachmentReference(unsafe), isNull);
      }
    },
  );
}
