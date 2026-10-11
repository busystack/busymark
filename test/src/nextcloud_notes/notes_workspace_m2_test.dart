import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:busymark/src/nextcloud_notes/application/notes_navigation.dart';
import 'package:busymark/src/nextcloud_notes/application/notes_offline_controller.dart';
import 'package:busymark/src/nextcloud_notes/application/notes_repository.dart';
import 'package:busymark/src/nextcloud_notes/application/notes_search_controller.dart';
import 'package:busymark/src/nextcloud_notes/application/notes_transfer_service.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_api_client.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_store.dart';
import 'package:busymark/src/nextcloud_notes/domain/notes_models.dart';
import 'package:busymark/src/nextcloud_notes/domain/notes_search.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import 'notes_api_test.dart' show testAccount, serverNote;

class _Fixture {
  late Directory root;
  late NotesRepository repository;
  bool offline = false, failMedia = false;
  bool loseNextCreate = false, loseNextUpload = false;
  Completer<void>? mediaGate, writeGate;
  final writeStarted = Completer<void>();
  final mediaStarted = Completer<void>();
  int downloads = 0, writes = 0, uploads = 0;
  final remote = <int, Map<String, dynamic>>{};
  late final transport = MockClient((request) async {
    if (offline) throw http.ClientException('offline fixture');
    if (request.url.path.contains('/attachment/')) {
      final id = int.parse(request.url.path.split('/').last);
      if (request.method == 'GET') {
        downloads++;
        if (!mediaStarted.isCompleted) mediaStarted.complete();
        await mediaGate?.future;
        if (failMedia) return http.Response('missing', 404);
        return http.Response.bytes([1, 2, 3], 200);
      }
      if (request.method == 'POST') {
        uploads++;
        if (loseNextUpload) {
          loseNextUpload = false;
          throw http.ClientException('lost upload response');
        }
      }
      return http.Response(
        jsonEncode({'filename': '.attachments.$id/café%20.png'}),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }
    final id = int.tryParse(request.url.path.split('/').last);
    if (request.method == 'GET') {
      return http.Response(
        jsonEncode(id == null ? remote.values.toList() : remote[id]),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }
    if (request.method == 'DELETE') {
      remote.remove(id);
      return http.Response('', 200);
    }
    writes++;
    if (!writeStarted.isCompleted) writeStarted.complete();
    await writeGate?.future;
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    final assigned = id ?? remote.length + 1;
    if (id != null && remote[id]?['readonly'] == true) {
      expect(body.keys, ['favorite']);
    }
    remote[assigned] = {
      ...serverNote(assigned),
      ...remote[assigned] ?? {},
      ...body,
      'etag': 'write-$writes',
    };
    if (id == null && loseNextCreate) {
      loseNextCreate = false;
      throw http.ClientException('lost creation response');
    }
    return http.Response(
      jsonEncode(remote[assigned]),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });
  Future<void> open() async {
    repository = NotesRepository(
      store: await NotesStore.open(path: p.join(root.path, 'notes.db')),
      clientForAccount: (account) async => NotesApiClient(
        client: transport,
        account: account,
        appPassword: 'fixture',
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

  Future<void> seed() async {
    remote[1] = {
      ...serverNote(1),
      'title': 'A',
      'category': 'Work/Sub',
      'content': 'café 中文 Привет foo_bar C++ alpha beta',
    };
    remote[2] = {
      ...serverNote(2),
      'title': 'A',
      'category': 'Work/Other',
      'readonly': true,
      'content': 'readonly',
    };
    await repository.synchronize(testAccount().id, allowWrites: false);
  }
}

void main() {
  late _Fixture f;
  setUp(() async {
    f = _Fixture();
    f.root = await Directory.systemTemp.createTemp('notes-m2-');
    await f.open();
  });
  tearDown(() async {
    f.mediaGate?.complete();
    await f.repository.dispose();
    await f.root.delete(recursive: true);
  });

  test('correction: every occurrence beyond 32 is reachable', () async {
    final content = List.filled(40, 'needle').join(' ');
    final note = await f.repository.create(testAccount().id, content: content);
    final search = NotesSearchController(f.repository.store, testAccount().id);
    addTearDown(search.dispose);
    await search.search('needle');
    expect(search.state.error, isNull);
    expect(search.state.hits.map((h) => (h.localId, h.start, h.end)), [
      for (var i = 0; i < 40; i++) (note.localId, i * 7, i * 7 + 6),
    ]);
    expect(search.state.truncated, false);
  });

  test(
    'correction: database pages preserve all document identities and offsets',
    () async {
      final expected = <(String, int?, int?)>{};
      for (var n = 0; n < 10; n++) {
        final note = await f.repository.create(
          testAccount().id,
          title: 'Note $n',
          content: List.filled(32, 'needle').join(' '),
        );
        expected.addAll([
          for (var i = 0; i < 32; i++) (note.localId, i * 7, i * 7 + 6),
        ]);
      }
      final search = NotesSearchController(
        f.repository.store,
        testAccount().id,
      );
      addTearDown(search.dispose);
      var previous = <(String, int?, int?)>{};
      for (final limit in [80, 160, 240, 320, 400]) {
        await search.search('needle', limit: limit);
        final actual = search.state.hits
            .map((h) => (h.localId, h.start, h.end))
            .toSet();
        expect(search.state.error, isNull);
        expect(actual.length, limit.clamp(0, 320));
        expect(search.state.hits.length, actual.length);
        expect(actual.containsAll(previous), true);
        expect(expected.containsAll(actual), true);
        expect(search.state.truncated, limit < 320);
        previous = actual;
      }
      expect(previous, expected);
      await f.restart();
      final reopened = NotesSearchController(
        f.repository.store,
        testAccount().id,
      );
      addTearDown(reopened.dispose);
      await reopened.search('needle', limit: 400);
      expect(
        reopened.state.hits.map((h) => (h.localId, h.start, h.end)).toSet(),
        expected,
      );
    },
  );

  test(
    'correction: a new reviewed import creates a distinct note in its reviewed category',
    () async {
      final source = await Directory(p.join(f.root.path, 'source')).create();
      await File(
        p.join(source.path, 'note.md'),
      ).writeAsString('unchanged body');
      var service = NotesTransferService(f.repository);
      final first = await service.importReviewed(
        await service.review(source.path, testAccount().id),
        testAccount().id,
        cancellation: NotesTransferCancellation(),
      );
      await f.repository.synchronize(testAccount().id);
      await f.restart();
      service = NotesTransferService(f.repository);
      final review = await service.review(source.path, testAccount().id);
      expect(review.items.single.collision, true);
      review.items.single.category = 'Reviewed/子';
      final second = await service.importReviewed(
        review,
        testAccount().id,
        cancellation: NotesTransferCancellation(),
      );
      expect(second.single.alreadyImported, false);
      expect(second.single.noteId, isNot(first.single.noteId));
      expect(
        f.repository.noteById(second.single.noteId!)!.category,
        'Reviewed/子',
      );
      await f.repository.synchronize(testAccount().id);
      expect(f.repository.notes.length, 2);
      expect(
        f.repository.notes.every((n) => n.syncState == NoteSyncState.synced),
        true,
      );
      expect(f.remote.values.map((n) => n['category']).toSet(), {
        '',
        'Reviewed/子',
      });
    },
  );

  test(
    'correction: a fresh import honors repaired and changed media with unchanged Markdown',
    () async {
      final source = await Directory(p.join(f.root.path, 'source')).create();
      await File(
        p.join(source.path, 'note.md'),
      ).writeAsString('![image](photo.png)');
      final service = NotesTransferService(f.repository);
      final missing = await service.review(source.path, testAccount().id);
      expect(missing.items.single.issues, isNotEmpty);
      final first = await service.importReviewed(
        missing,
        testAccount().id,
        cancellation: NotesTransferCancellation(),
      );
      await File(p.join(source.path, 'photo.png')).writeAsBytes([4, 5, 6]);
      for (final bytes in [
        [4, 5, 6],
        [7, 8, 9],
      ]) {
        await File(p.join(source.path, 'photo.png')).writeAsBytes(bytes);
        final review = await service.review(source.path, testAccount().id);
        expect(review.items.single.issues, isEmpty);
        final imported = await service.importReviewed(
          review,
          testAccount().id,
          cancellation: NotesTransferCancellation(),
        );
        expect(imported.single.noteId, isNot(first.single.noteId));
        final attachments = await f.repository.store.attachments(
          imported.single.noteId,
        );
        expect(attachments, hasLength(1));
        expect(
          await f.repository.store.attachmentBytes(attachments.single.id),
          bytes,
        );
      }
      await f.restart();
      expect(f.repository.notes, hasLength(3));
    },
  );

  for (final prefix in ['./', '../']) {
    test(
      'correction: Markdown and HTML local media resolve safely with $prefix',
      () async {
        final source = await Directory(p.join(f.root.path, 'source')).create();
        await Directory(p.join(source.path, 'images')).create();
        await Directory(p.join(source.path, 'chapters')).create();
        final document = prefix == './' ? 'note.md' : 'chapters/note.md';
        final reference = '${prefix}images/caf%C3%A9%2520.png';
        await File(
          p.join(source.path, 'images/café%20.png'),
        ).writeAsBytes([4, 3, 2]);
        await File(
          p.join(source.path, document),
        ).writeAsString('![image]($reference)\n\n<img src="$reference" />\n');
        final service = NotesTransferService(f.repository);
        final review = await service.review(source.path, testAccount().id);
        expect(review.items.single.issues, isEmpty);
        expect(review.items.single.media.keys, [reference]);
        final result = await service.importReviewed(
          review,
          testAccount().id,
          cancellation: NotesTransferCancellation(),
        );
        final note = f.repository.noteById(result.single.noteId!)!;
        final attachment = (await f.repository.store.attachments(
          note.localId,
        )).single;
        expect(
          note.content,
          '![image](${attachment.reference})\n\n<img src="${attachment.reference}" />\n',
        );
        expect(await f.repository.store.attachmentBytes(attachment.id), [
          4,
          3,
          2,
        ]);
        await f.restart();
        expect(
          await f.repository.resolveCachedMedia(
            testAccount().id,
            note.localId,
            attachment.reference,
          ),
          isNotNull,
        );
        expect(canonicalAttachmentReference(reference), isNull);
        await f.repository.synchronize(testAccount().id);
        expect(
          f.repository.noteById(note.localId)!.syncState,
          NoteSyncState.synced,
        );
      },
    );
  }

  test(
    'correction: outside-root local media is rejected without reading its bytes',
    () async {
      final source = await Directory(p.join(f.root.path, 'source')).create();
      await File(p.join(f.root.path, 'outside.png')).writeAsBytes([9, 9, 9]);
      await File(p.join(source.path, 'note.md')).writeAsString(
        '![image](../outside.png)\n\n<img src="../outside.png" />\n',
      );
      final review = await NotesTransferService(
        f.repository,
      ).review(source.path, testAccount().id);
      expect(review.items.single.media, isEmpty);
      expect(review.items.single.issues, isNotEmpty);
    },
  );

  test(
    'correction: deleted recovery bytes are unavailable to live offline media',
    () async {
      f.remote[1] = {
        ...serverNote(1),
        'content': '![image](.attachments.1/café%2520.png)',
      };
      await f.repository.synchronize(testAccount().id, allowWrites: false);
      final note = f.repository.notes.single;
      const reference = '.attachments.1/café%2520.png';
      await f.repository.resolveMedia(
        testAccount().id,
        note.localId,
        reference,
      );
      final original = (await f.repository.store.attachments(
        note.localId,
      )).single;
      await f.repository.deleteAttachment(
        note.localId,
        reference,
        retainForHistory: true,
      );
      expect(await f.repository.store.attachmentBytes(original.id), [1, 2, 3]);
      expect(
        await f.repository.resolveCachedMedia(
          testAccount().id,
          note.localId,
          reference,
        ),
        isNull,
      );
      final availability = await f.repository.attachmentAvailability(
        note.localId,
      );
      expect(availability.required.map(canonicalAttachmentReference), [
        canonicalAttachmentReference(reference),
      ]);
      expect(availability.available, isEmpty);
      await f.restart();
      final offline = NotesOfflineController(f.repository, testAccount().id);
      addTearDown(offline.dispose);
      await offline.initialize();
      await offline.setRequirement('note', note.localId);
      expect(
        (await offline.inspect(f.repository.noteById(note.localId)!)).available,
        false,
      );
      expect(
        (await f.repository.store.attachments(note.localId)).single.state,
        'deleted',
      );
      expect(await f.repository.store.attachmentBytes(original.id), [1, 2, 3]);
      final replacement = await f.repository.addAttachment(
        note.localId,
        filename: 'café%20.png',
        bytes: Uint8List.fromList([7, 8, 9]),
      );
      await f.repository.save(
        note.localId,
        content: '![image](${replacement.reference})',
      );
      await f.repository.synchronize(testAccount().id);
      expect(
        (await f.repository.store.attachments(
          note.localId,
        )).where((a) => a.id == replacement.id).single.state,
        'uploaded',
      );
      expect(
        (await offline.inspect(f.repository.noteById(note.localId)!)).available,
        true,
      );
      expect(
        await f.repository.resolveCachedMedia(
          testAccount().id,
          note.localId,
          reference,
        ),
        isNotNull,
      );
      expect(await f.repository.store.attachmentBytes(original.id), [1, 2, 3]);
    },
  );

  test(
    'correction: worker continuation spans occurrences, candidates and Unicode ranges',
    () async {
      final expected = <(String, int?, int?)>{};
      for (var n = 0; n < 40; n++) {
        final source = List.filled(
          n == 0 ? 403 : 2,
          'cafe\u0301 café',
        ).join(' ');
        final note = await f.repository.create(
          testAccount().id,
          content: source,
        );
        expected.addAll(
          RegExp(
            'cafe\u0301|café',
          ).allMatches(source).map((m) => (note.localId, m.start, m.end)),
        );
      }
      final actual = <(String, int?, int?)>[];
      var after = 0;
      Map<String, dynamic>? continuation;
      var more = true, calls = 0;
      while (more) {
        expect(++calls, lessThan(100));
        final page = await f.repository.store.searchChunk(
          testAccount().id,
          NotesSearchQuery('café'),
          after: after,
          continuation: continuation,
          limit: 200,
        );
        final hits = (page['hits'] as List)
            .map(
              (h) =>
                  NotesSearchHit.fromJson(Map<String, dynamic>.from(h as Map)),
            )
            .toList();
        expect(hits.length, lessThanOrEqualTo(200));
        actual.addAll(hits.map((h) => (h.localId, h.start, h.end)));
        after = page['after'] as int;
        continuation = page['continuation'] == null
            ? null
            : Map<String, dynamic>.from(page['continuation'] as Map);
        more = page['more'] as bool;
      }
      expect(actual.length, expected.length);
      expect(actual.toSet(), expected);
      final search = NotesSearchController(
        f.repository.store,
        testAccount().id,
      );
      addTearDown(search.dispose);
      await search.search('café', limit: 1000);
      expect(
        search.state.hits.map((h) => (h.localId, h.start, h.end)).toSet(),
        expected,
      );
      expect(search.state.truncated, false);
    },
  );

  test(
    'correction: partial-document continuation rejects changed revisions',
    () async {
      final note = await f.repository.create(
        testAccount().id,
        content: List.filled(40, 'needle').join(' '),
      );
      final first = await f.repository.store.searchChunk(
        testAccount().id,
        NotesSearchQuery('needle'),
        limit: 10,
      );
      expect(first['more'], true);
      expect(first['continuation'], isNotNull);
      await f.repository.save(note.localId, content: 'changed needle');
      await expectLater(
        f.repository.store.searchChunk(
          testAccount().id,
          NotesSearchQuery('needle'),
          after: first['after'] as int,
          continuation: Map<String, dynamic>.from(first['continuation'] as Map),
        ),
        throwsStateError,
      );
      final search = NotesSearchController(
        f.repository.store,
        testAccount().id,
      );
      addTearDown(search.dispose);
      await search.search('needle');
      expect(search.state.hits.map((h) => (h.start, h.end)), [(8, 14)]);
    },
  );

  test(
    'correction: interrupted import is reconstructed from its durable operation after restart',
    () async {
      final source = await Directory(p.join(f.root.path, 'resume')).create();
      for (var n = 0; n < 3; n++) {
        await File(
          p.join(source.path, '$n.md'),
        ).writeAsString('resume body $n');
      }
      var service = NotesTransferService(f.repository);
      final original = await service.review(source.path, testAccount().id);
      for (final item in original.items) {
        item.category = 'Reviewed/Resume';
      }
      final cancel = NotesTransferCancellation();
      final first = await service.importReviewed(
        original,
        testAccount().id,
        cancellation: cancel,
        onProgress: (_, _) => cancel.cancel(),
      );
      expect(first, hasLength(1));
      final pending = await f.repository.store.importOperations(
        testAccount().id,
      );
      expect(pending.single['id'], original.operationId);
      await f.restart();
      service = NotesTransferService(f.repository);
      final resumed = await service.resumeImport(
        original.operationId,
        testAccount().id,
      );
      expect(resumed.items.first.importedNoteId, first.single.noteId);
      expect(resumed.items.every((i) => i.category == 'Reviewed/Resume'), true);
      final second = await service.importReviewed(
        resumed,
        testAccount().id,
        cancellation: NotesTransferCancellation(),
      );
      expect(second.map((o) => o.alreadyImported), [true, false, false]);
      expect(second.first.noteId, first.single.noteId);
      expect(f.repository.notes, hasLength(3));
      expect(
        await f.repository.store.importOperations(testAccount().id),
        isEmpty,
      );
      await f.repository.synchronize(testAccount().id);
      final writes = f.writes;
      await f.restart();
      final completed = await NotesTransferService(
        f.repository,
      ).resumeImport(original.operationId, testAccount().id);
      final replayed = await NotesTransferService(f.repository).importReviewed(
        completed,
        testAccount().id,
        cancellation: NotesTransferCancellation(),
      );
      expect(replayed.every((o) => o.alreadyImported), true);
      await f.repository.synchronize(testAccount().id);
      expect(f.writes, writes);
      final fresh = await NotesTransferService(
        f.repository,
      ).review(source.path, testAccount().id);
      expect(fresh.operationId, isNot(original.operationId));
      expect(fresh.items.every((i) => !i.alreadyImported), true);
      await f.repository.removeAccount(testAccount().id);
      expect(
        await f.repository.store.importOperation(
          testAccount().id,
          original.operationId,
        ),
        isNull,
      );
      await expectLater(
        NotesTransferService(
          f.repository,
        ).resumeImport(original.operationId, testAccount().id),
        throwsStateError,
      );
    },
  );

  test(
    'correction: Recovery search is account-scoped and excluded from live indexing',
    () async {
      final deleted = await f.repository.create(
        testAccount().id,
        title: 'Retained 子',
        category: 'Gone/Sub',
        content: 'forty retained needles',
      );
      await f.repository.delete(deleted.localId);
      final pending = await f.repository.create(
        testAccount().id,
        title: 'Deletion conflict',
        content: 'retained needles',
      );
      await f.repository.store.saveNote(
        pending.copyWith(syncState: NoteSyncState.deletedRemotely),
      );
      final other = NextcloudAccount(
        id: 'aaf20ae4-efbb-43a5-8f57-88bb0a6b9132',
        server: testAccount().server,
        loginName: 'Other',
        appVersion: '6.1.0',
      );
      await f.repository.upsertAccount(other);
      final foreign = await f.repository.create(
        other.id,
        content: 'retained needles',
      );
      await f.repository.delete(foreign.localId);
      await f.restart();
      final recovery = NotesSearchController(
        f.repository.store,
        testAccount().id,
        recovery: true,
      );
      final live = NotesSearchController(f.repository.store, testAccount().id);
      addTearDown(recovery.dispose);
      addTearDown(live.dispose);
      await recovery.search('"retained needles" category:Gone');
      expect(recovery.state.hits.single.localId, deleted.localId);
      expect(recovery.state.hits.single.start, 6);
      await live.search('retained');
      expect(live.state.hits.map((h) => h.localId), [pending.localId]);
      final restored = await f.repository.recoverAsNew(deleted.localId);
      expect(restored.localId, isNot(deleted.localId));
      await f.repository.synchronize(testAccount().id);
      expect(
        f.repository.noteById(restored.localId)!.syncState,
        NoteSyncState.synced,
      );
      await recovery.search('title:"Retained 子"');
      expect(recovery.state.hits.single.localId, deleted.localId);
      await f.repository.removeAccount(testAccount().id);
      await recovery.search('retained');
      expect(recovery.state.hits, isEmpty);
    },
  );

  test(
    'correction: resumed operation preserves uncertain creation and upload evidence',
    () async {
      final source = await Directory(p.join(f.root.path, 'uncertain')).create();
      await File(
        p.join(source.path, '0.md'),
      ).writeAsString('![image](photo.png)');
      await File(p.join(source.path, '1.md')).writeAsString('other');
      await File(p.join(source.path, 'photo.png')).writeAsBytes([1, 2, 3]);
      var service = NotesTransferService(f.repository);
      final review = await service.review(source.path, testAccount().id);
      final cancel = NotesTransferCancellation();
      final first = await service.importReviewed(
        review,
        testAccount().id,
        cancellation: cancel,
        onProgress: (_, _) => cancel.cancel(),
      );
      final id = first.single.noteId!;
      f.loseNextCreate = true;
      await f.repository.synchronize(testAccount().id);
      expect(
        f.repository.noteById(id)!.syncState,
        NoteSyncState.creationUncertain,
      );
      final evidence = f.repository.noteById(id)!.creationAttempt!;
      await f.restart();
      service = NotesTransferService(f.repository);
      final resumed = await service.resumeImport(
        review.operationId,
        testAccount().id,
      );
      final second = await service.importReviewed(
        resumed,
        testAccount().id,
        cancellation: NotesTransferCancellation(),
      );
      expect(second.first.noteId, id);
      expect(second.first.alreadyImported, true);
      expect(
        f.repository.noteById(id)!.creationAttempt!.toJson(),
        evidence.toJson(),
      );
      await f.repository.synchronize(testAccount().id);
      expect(f.remote.length, 2);
      expect(
        f.repository.noteById(id)!.syncState,
        NoteSyncState.creationUncertain,
      );
      final candidate = NoteState.fromJson(f.remote.values.first);
      await f.repository.resolveConflict(
        id,
        NoteConflictResolution.useServerNote,
        creationCandidateServerId: candidate.id,
        creationReview: f.repository.creationReview(id, candidate),
      );
      f.loseNextUpload = true;
      await f.repository.synchronize(testAccount().id);
      final staged = (await f.repository.store.attachments(id)).single;
      expect(staged.state, 'uncertain');
      expect(await f.repository.store.attachmentBytes(staged.id), [1, 2, 3]);
      final uploads = f.uploads;
      await f.restart();
      final complete = await NotesTransferService(
        f.repository,
      ).resumeImport(review.operationId, testAccount().id);
      final replay = await NotesTransferService(f.repository).importReviewed(
        complete,
        testAccount().id,
        cancellation: NotesTransferCancellation(),
      );
      expect(replay.every((o) => o.alreadyImported), true);
      await f.repository.synchronize(testAccount().id);
      expect(f.uploads, uploads);
      expect(
        (await f.repository.store.attachments(id)).single.state,
        'uncertain',
      );
      expect(f.repository.notes, hasLength(2));
    },
  );

  test(
    'correction: schema 5 migration preserves existing item ledger and all durable data',
    () async {
      final note = await f.repository.importLocal(
        accountId: testAccount().id,
        sourceKey: 'legacy-import-key',
        title: 'legacy',
        category: 'Legacy/Sub',
        content: 'body',
        media: {
          'photo.png': (
            filename: 'photo.png',
            bytes: Uint8List.fromList([8, 7, 6]),
          ),
        },
      );
      await f.repository.setOfflineRequirement(
        testAccount().id,
        'category',
        'Legacy',
      );
      final attachment = (await f.repository.store.attachments(
        note.localId,
      )).single;
      await f.repository.dispose();
      var db = sqlite3.open(p.join(f.root.path, 'notes.db'));
      db.execute('DROP TABLE import_operations');
      db.execute('PRAGMA user_version=5');
      final before = {
        for (final table in [
          'accounts',
          'notes',
          'outbox',
          'attachments',
          'import_items',
          'offline_requirements',
        ])
          table: db
              .select('SELECT * FROM $table')
              .map((r) => Map<String, Object?>.from(r))
              .toList(),
      };
      db.close();
      await f.open();
      expect(
        await f.repository.store.importedNote(
          testAccount().id,
          'legacy-import-key',
        ),
        note.localId,
      );
      expect(await f.repository.store.attachmentBytes(attachment.id), [
        8,
        7,
        6,
      ]);
      db = sqlite3.open(f.repository.store.path);
      expect(db.select('PRAGMA user_version').single.values.single, 6);
      for (final entry in before.entries) {
        expect(
          db
              .select('SELECT * FROM ${entry.key}')
              .map((r) => Map<String, Object?>.from(r))
              .toList(),
          entry.value,
        );
      }
      db.close();
    },
  );

  test(
    'correction: dirty overlays expose every occurrence without saving',
    () async {
      final note = await f.repository.create(
        testAccount().id,
        content: 'saved body',
      );
      final search = NotesSearchController(
        f.repository.store,
        testAccount().id,
      );
      addTearDown(search.dispose);
      final source = List.filled(103, 'needle').join(' ');
      for (final limit in [80, 160]) {
        await search.search(
          'needle',
          limit: limit,
          overlays: [
            NotesSearchOverlay(note.localId, 9, note.title, '', source),
          ],
        );
        expect(search.state.hits.map((h) => (h.localId, h.start, h.end)), [
          for (var i = 0; i < limit.clamp(0, 103); i++)
            (note.localId, i * 7, i * 7 + 6),
        ]);
        expect(search.state.truncated, limit < 103);
      }
      expect((await f.repository.store.notes()).single.content, 'saved body');
    },
  );

  test(
    'correction: overlapping terms continue at the same start without duplication',
    () async {
      final note = await f.repository.create(
        testAccount().id,
        content: List.filled(40, 'foobar').join(' '),
      );
      final query = NotesSearchQuery('foo foobar');
      final actual = <(int?, int?)>[];
      var after = 0;
      Map<String, dynamic>? continuation;
      for (var i = 0; i < 80; i++) {
        final page = await f.repository.store.searchChunk(
          testAccount().id,
          query,
          after: after,
          continuation: continuation,
          limit: 1,
        );
        final hit = NotesSearchHit.fromJson(
          Map<String, dynamic>.from((page['hits'] as List).single as Map),
        );
        expect(hit.localId, note.localId);
        actual.add((hit.start, hit.end));
        expect(page['more'], i < 79);
        after = page['after'] as int;
        continuation = page['continuation'] == null
            ? null
            : Map<String, dynamic>.from(page['continuation'] as Map);
      }
      expect(actual, [
        for (var i = 0; i < 40; i++) ...[
          (i * 7, i * 7 + 3),
          (i * 7, i * 7 + 6),
        ],
      ]);
    },
  );

  test(
    'correction: navigation relocates late occurrences after a dirty edit',
    () async {
      final source = 'x ${List.filled(400, 'needle').join(' ')}';
      final hit = await relocateNotesSearchHit(
        NotesSearchQuery('needle'),
        NotesSearchOverlay('identity', 11, 'Title', '', source),
        350 * 7,
      );
      expect(hit!.start, 350 * 7 + 2);
      expect(hit.end, 350 * 7 + 8);
      expect(hit.revision, 11);
      expect(hit.digest, notesSearchDigest(source));
    },
  );

  test(
    'navigation counts share inclusion, descendants, recovery and stable selection',
    () async {
      await f.seed();
      final draft = await f.repository.create(
        testAccount().id,
        title: 'Uncategorized',
      );
      final deleted = await f.repository.create(
        testAccount().id,
        title: 'deleted',
      );
      await f.repository.delete(deleted.localId);
      final pendingDeleted = await f.repository.create(
        testAccount().id,
        title: 'deletion conflict',
      );
      await f.repository.store.saveNote(
        pendingDeleted.copyWith(syncState: NoteSyncState.deletedRemotely),
      );
      await f.restart();
      final nav = NotesNavigationController()
        ..update(f.repository.notes, testAccount().id);
      expect(nav.counts[NotesDestination.all], 4);
      expect(nav.counts[NotesDestination.recovery], 1);
      expect(nav.categoryCounts, {'Work': 2, 'Work/Sub': 1, 'Work/Other': 1});
      nav.destination = NotesDestination.category;
      nav.category = 'Work';
      nav.update(f.repository.notes, testAccount().id);
      final ids = nav.visible.map((n) => n.localId).toList();
      nav.select(ids.first);
      nav.select(ids.last, range: true);
      expect(nav.selected, ids.toSet());
      nav.sort = NotesSort.titleDescending;
      nav.update(f.repository.notes, testAccount().id);
      expect(nav.selected, ids.toSet());
      expect(nav.contextTargets(draft.localId), [draft.localId]);
      nav.destination = NotesDestination.uncategorized;
      nav.update(f.repository.notes, testAccount().id);
      expect(nav.selected, isEmpty);
      nav.selectAll();
      expect(nav.selected.length, 2);
    },
  );

  test(
    'mixed batch permissions, unrelated edits and same-field conflict survive restart',
    () async {
      await f.seed();
      final a = f.repository.notes.firstWhere((n) => n.serverId == 1);
      final b = f.repository.notes.firstWhere((n) => n.serverId == 2);
      final reviewed = [
        f.repository.metadataSnapshot(a.localId),
        f.repository.metadataSnapshot(b.localId),
      ];
      await f.repository.save(a.localId, content: 'pending body');
      await f.repository.patchMetadata(
        f.repository.metadataSnapshot(a.localId),
        title: 'concurrent title',
      );
      final results = await f.repository.patchMetadataBatch(
        reviewed,
        category: 'Moved/Sub',
      );
      expect(results.map((r) => r.status), [
        NotesBatchStatus.changed,
        NotesBatchStatus.skipped,
      ]);
      expect(f.repository.noteById(a.localId)!.title, 'concurrent title');
      expect(f.repository.noteById(a.localId)!.content, 'pending body');
      await f.repository.patchMetadata(
        f.repository.metadataSnapshot(a.localId),
        category: 'Other',
      );
      final conflicts = await f.repository.patchMetadataBatch(
        reviewed,
        category: 'Reviewed',
      );
      expect(conflicts.first.status, NotesBatchStatus.conflicted);
      await f.restart();
      expect(f.repository.noteById(a.localId)!.metadataConflict, isNotNull);
      final favorites = await f.repository.patchMetadataBatch([
        f.repository.metadataSnapshot(b.localId),
      ], favorite: true);
      expect(favorites.single.status, NotesBatchStatus.changed);
      await f.repository.synchronize(testAccount().id);
      expect(f.remote[2]!['favorite'], true);
      expect(f.remote[2]!['content'], 'readonly');
      expect(f.repository.noteById(a.localId)!.metadataConflict, isNotNull);
    },
  );

  for (final query in [
    '"alpha beta"',
    'alpha beta',
    'title:A category:Work',
    '中文',
    'é',
    'Привет',
    'C++',
    'foo_bar',
    'cafe\u0301',
  ]) {
    test(
      'indexed literal and multilingual query $query matches unopened durable notes',
      () async {
        await f.seed();
        final search = NotesSearchController(
          f.repository.store,
          testAccount().id,
        );
        addTearDown(search.dispose);
        await search.search(query);
        expect(search.state.error, isNull);
        expect(search.state.hits, isNotEmpty);
        for (final hit in search.state.hits.where((h) => h.start != null)) {
          final source = f.repository.noteById(hit.localId)!.content;
          expect(hit.start, greaterThanOrEqualTo(0));
          expect(hit.end, lessThanOrEqualTo(source.length));
          expect(source.substring(hit.start!, hit.end!), isNotEmpty);
        }
      },
    );
  }
  test(
    'FTS operators and punctuation stay literal; Unicode whole words and short terms',
    () async {
      final note = await f.repository.create(
        testAccount().id,
        content:
            'AND OR foo_bar foobar foo βήτα βήταx cafe\u0301 café 100% C++',
      );
      final search = NotesSearchController(
        f.repository.store,
        testAccount().id,
      );
      addTearDown(search.dispose);
      await search.search('AND');
      expect(search.state.hits.length, 1);
      await search.search('foo', wholeWord: true);
      expect(search.state.hits.length, 1);
      expect(
        note.content.substring(
          search.state.hits.single.start!,
          search.state.hits.single.end!,
        ),
        'foo',
      );
      await search.search('βήτα', wholeWord: true);
      expect(search.state.hits.length, 1);
      await search.search('100%');
      expect(search.state.hits.length, 1);
      await search.search('"OR foo_bar"');
      expect(search.state.hits.length, 1);
      await search.search('café');
      expect(search.state.hits.length, 2);
      expect(
        search.state.hits.map((h) => note.content.substring(h.start!, h.end!)),
        ['cafe\u0301', 'café'],
      );
      await search.search('foo*');
      expect(search.state.hits, isEmpty);
    },
  );
  test(
    'pending and dirty overlay, cancellation, pagination and changed-result relocation',
    () async {
      final note = await f.repository.create(
        testAccount().id,
        content: 'saved needle',
      );
      final search = NotesSearchController(
        f.repository.store,
        testAccount().id,
      );
      addTearDown(search.dispose);
      await search.search(
        'needle',
        overlays: [
          NotesSearchOverlay(
            note.localId,
            10,
            note.title,
            note.category,
            'dirty needle needle',
          ),
        ],
        limit: 1,
      );
      expect(search.state.truncated, true);
      expect(search.state.hits.single.revision, 10);
      expect(f.repository.noteById(note.localId)!.content, 'saved needle');
      final stale = search.state.hits.single;
      final running = search.search('saved');
      await search.search('missing');
      await running;
      expect(search.state.hits, isEmpty);
      final changed = matchNotesDocument(
        query: NotesSearchQuery('needle'),
        localId: note.localId,
        revision: 11,
        title: note.title,
        category: '',
        source: 'prefix dirty needle',
      );
      expect(changed.single.start, isNot(stale.start));
      expect(notesSearchDigest('prefix dirty needle'), isNot(stale.digest));
    },
  );
  test(
    'restart, derived index loss/rebuild, deletion and account removal erase search content',
    () async {
      final note = await f.repository.create(
        testAccount().id,
        content: 'findme',
      );
      await f.restart();
      await f.repository.store.rebuildIndex();
      final search = NotesSearchController(
        f.repository.store,
        testAccount().id,
      );
      await search.search('findme');
      expect(search.state.hits.single.localId, note.localId);
      await f.repository.delete(note.localId);
      await search.search('findme');
      expect(search.state.hits, isEmpty);
      await f.repository.removeAccount(testAccount().id);
      final db = sqlite3.open(f.repository.store.path);
      expect(db.select('SELECT count(*) AS n FROM note_search').single['n'], 0);
      expect(
        db.select('SELECT count(*) AS n FROM note_search_map').single['n'],
        0,
      );
      db.close();
      await search.dispose();
    },
  );

  test(
    'offline category descendants, independent retention, new refs and restart',
    () async {
      f.remote[1] = {
        ...serverNote(1),
        'category': 'Work/Sub',
        'content': '![image](.attachments.1/a.png)',
      };
      await f.repository.synchronize(testAccount().id, allowWrites: false);
      final note = f.repository.notes.single;
      var offline = NotesOfflineController(f.repository, testAccount().id);
      await offline.initialize();
      await offline.setRequirement('category', 'Work');
      await offline.reconcile();
      expect((await offline.inspect(note)).available, true);
      expect(f.downloads, 1);
      await offline.setRequirement('note', note.localId);
      await offline.setRequirement('category', 'Work', required: false);
      expect(offline.retained(note), true);
      await f.repository.save(
        note.localId,
        content: '![image](.attachments.1/a.png) ![new](.attachments.1/b.png)',
      );
      expect(
        (await offline.inspect(f.repository.noteById(note.localId)!)).available,
        false,
      );
      await offline.reconcile();
      expect(
        (await offline.inspect(f.repository.noteById(note.localId)!)).available,
        true,
      );
      await offline.dispose();
      await f.restart();
      f.offline = true;
      offline = NotesOfflineController(f.repository, testAccount().id);
      await offline.initialize();
      expect(offline.individuallyRetained(note.localId), true);
      expect(
        (await offline.inspect(f.repository.noteById(note.localId)!)).available,
        true,
      );
      expect(
        await f.repository.resolveCachedMedia(
          testAccount().id,
          note.localId,
          '.attachments.1/b.png',
        ),
        isNotNull,
      );
      await offline.dispose();
    },
  );
  test(
    'offline failure needs retry; paused category does not cancel independent requirement',
    () async {
      f.remote[1] = {
        ...serverNote(1),
        'category': 'Work/Sub',
        'content': '![image](.attachments.1/a.png)',
      };
      await f.repository.synchronize(testAccount().id, allowWrites: false);
      final note = f.repository.notes.single;
      final offline = NotesOfflineController(f.repository, testAccount().id);
      await offline.initialize();
      f.failMedia = true;
      await offline.setRequirement('category', 'Work');
      await offline.reconcile();
      expect((await offline.inspect(note)).available, false);
      final downloads = f.downloads;
      await offline.reconcile();
      expect(f.downloads, downloads);
      f.failMedia = false;
      await offline.retry();
      expect((await offline.inspect(note)).available, true);
      await offline.setRequirement('note', note.localId);
      await offline.setRequirement('category', 'Work', paused: true);
      expect((await offline.inspect(note)).paused, false);
      await offline.dispose();
    },
  );
  test(
    'account removal fences a late offline download and requirements',
    () async {
      f.remote[1] = {
        ...serverNote(1),
        'category': 'Work/Sub',
        'content': '![image](.attachments.1/a.png)',
      };
      await f.repository.synchronize(testAccount().id, allowWrites: false);
      final offline = NotesOfflineController(f.repository, testAccount().id);
      await offline.initialize();
      f.mediaGate = Completer<void>();
      final download = offline.setRequirement('category', 'Work');
      await f.mediaStarted.future;
      await f.repository.removeAccount(testAccount().id);
      f.mediaGate!.complete();
      f.mediaGate = null;
      await download;
      expect(await f.repository.store.attachments(), isEmpty);
      expect(
        await f.repository.store.offlineRequirements(testAccount().id),
        isEmpty,
      );
      await offline.dispose();
    },
  );
  test(
    'pending upload bytes are available offline before acknowledgement',
    () async {
      final note = await f.repository.create(testAccount().id);
      final attachment = await f.repository.addAttachment(
        note.localId,
        filename: 'é%.png',
        bytes: Uint8List.fromList([1, 2]),
      );
      final saved = await f.repository.save(
        note.localId,
        content: '![local](${attachment.reference})',
      );
      final offline = NotesOfflineController(f.repository, testAccount().id);
      expect((await offline.inspect(saved)).available, true);
      expect(saved.hasPendingChanges, true);
      await offline.setRequirement('note', note.localId, required: false);
      expect(await f.repository.store.attachmentBytes(attachment.id), [1, 2]);
      await offline.dispose();
    },
  );
  test(
    'deleted draft and retained media recover as new and synchronize',
    () async {
      final note = await f.repository.create(
        testAccount().id,
        title: 'retained',
      );
      final a = await f.repository.addAttachment(
        note.localId,
        filename: 'café%.png',
        bytes: Uint8List.fromList([1, 2, 3]),
      );
      await f.repository.save(
        note.localId,
        content: '![image](${a.reference})',
      );
      await f.repository.delete(note.localId);
      await f.restart();
      final recovered = await f.repository.recoverAsNew(note.localId);
      expect(recovered.localId, isNot(note.localId));
      expect(recovered.serverId, isNull);
      expect(
        (await f.repository.store.attachments(recovered.localId)).length,
        1,
      );
      await f.repository.synchronize(testAccount().id);
      expect(
        f.repository.noteById(recovered.localId)!.syncState,
        NoteSyncState.synced,
      );
      expect(
        f.repository.noteById(note.localId)!.syncState,
        NoteSyncState.deletedRemotely,
      );
    },
  );

  test(
    'portable nested round trip duplicates favorites Unicode and Markdown/HTML media',
    () async {
      final note = await f.repository.create(
        testAccount().id,
        title: '同じ:/CON?',
        category: 'Work/子',
        content: 'body',
      );
      final a = await f.repository.addAttachment(
        note.localId,
        filename: 'café%20.png',
        bytes: Uint8List.fromList([1, 2, 3]),
      );
      await f.repository.save(
        note.localId,
        content:
            '![one](${a.reference})\n<img src="${a.reference}">\n`![literal](${a.reference})`\n[doc](other.md)',
      );
      await f.repository.patchMetadata(
        f.repository.metadataSnapshot(note.localId),
        favorite: true,
      );
      await f.repository.create(
        testAccount().id,
        title: note.title,
        category: note.category,
        content: 'duplicate',
      );
      final service = NotesTransferService(f.repository);
      final exported = await service.exportSnapshot(
        notes: f.repository.notes,
        destination: f.root.path,
        cancellation: NotesTransferCancellation(),
      );
      expect(exported.complete, true);
      final review = await service.review(exported.path, testAccount().id);
      expect(review.items.length, 2);
      expect(review.items.every((i) => i.collision), true);
      expect(
        review.items.where((i) => i.media.isNotEmpty).single.media.length,
        1,
      );
      final imported = await service.importReviewed(
        review,
        testAccount().id,
        cancellation: NotesTransferCancellation(),
      );
      expect(imported.every((i) => i.noteId != null), true);
      final copies = imported
          .map((i) => f.repository.noteById(i.noteId!)!)
          .toList();
      expect(
        copies.every((n) => n.category == 'Work/子' && n.title == note.title),
        true,
      );
      expect(copies.where((n) => n.favorite).length, 1);
      expect(
        copies.where((n) => n.favorite).single.content,
        contains('[doc](other.md)'),
      );
      expect(
        copies.where((n) => n.favorite).single.content,
        contains('`![literal](${a.reference})`'),
      );
      await f.restart();
      final repeated = await NotesTransferService(f.repository).importReviewed(
        review,
        testAccount().id,
        cancellation: NotesTransferCancellation(),
      );
      expect(repeated.every((o) => o.alreadyImported), true);
      expect(f.repository.notes.length, 4);
    },
  );
  test(
    'missing media explicit, no external fetching; cancellation leaves no published folder',
    () async {
      await f.seed();
      final note = await f.repository.create(
        testAccount().id,
        content:
            '![missing](missing.png) ![external](https://example.org/a.png)',
      );
      final service = NotesTransferService(f.repository);
      final result = await service.exportSnapshot(
        notes: [note],
        destination: f.root.path,
        cancellation: NotesTransferCancellation(),
      );
      expect(result.complete, false);
      expect(result.omissions.length, 2);
      expect(f.downloads, 0);
      final cancel = NotesTransferCancellation()..cancel();
      await expectLater(
        service.exportSnapshot(
          notes: [note],
          destination: f.root.path,
          cancellation: cancel,
        ),
        throwsA(isA<FileSystemException>()),
      );
      expect(
        await f.root
            .list()
            .where((e) => p.basename(e.path).startsWith('.busymark-export-'))
            .length,
        0,
      );
    },
  );
  test(
    'manifest versions, traversal, symlinks and changed files are rejected',
    () async {
      final folder = await Directory(p.join(f.root.path, 'source')).create();
      final outside = File(p.join(f.root.path, 'outside.png'));
      await outside.writeAsBytes([1]);
      final file = File(p.join(folder.path, 'a.md'));
      await file.writeAsString('![image](../outside.png)');
      final service = NotesTransferService(f.repository);
      var review = await service.review(folder.path, testAccount().id);
      expect(review.items.single.issues, isNotEmpty);
      expect(review.items.single.media, isEmpty);
      await file.writeAsString('changed');
      final changed = await service.importReviewed(
        review,
        testAccount().id,
        cancellation: NotesTransferCancellation(),
      );
      expect(changed.single.error, isNotNull);
      expect(f.repository.notes, isEmpty);
      await Link(p.join(folder.path, 'link.md')).create(file.path);
      review = await service.review(folder.path, testAccount().id);
      expect(review.issues, isNotEmpty);
      await File(
        p.join(folder.path, NotesTransferService.manifestName),
      ).writeAsString(
        jsonEncode({
          'format': 'busymark-notes',
          'version': 99,
          'documents': [],
        }),
      );
      await expectLater(
        service.review(folder.path, testAccount().id),
        throwsFormatException,
      );
      await File(
        p.join(folder.path, NotesTransferService.manifestName),
      ).writeAsString(
        jsonEncode({
          'format': 'busymark-notes',
          'version': 1,
          'documents': [
            {
              'file': '../outside.png',
              'title': 'bad',
              'category': '',
              'favorite': false,
            },
          ],
        }),
      );
      await expectLater(
        service.review(folder.path, testAccount().id),
        throwsFormatException,
      );
    },
  );
  test(
    'partial cancelled import resumes associations without duplicate local notes',
    () async {
      final folder = await Directory(p.join(f.root.path, 'source')).create();
      for (var i = 0; i < 3; i++) {
        await File(p.join(folder.path, '$i.md')).writeAsString('body $i');
      }
      final service = NotesTransferService(f.repository);
      final review = await service.review(folder.path, testAccount().id);
      final cancel = NotesTransferCancellation();
      final first = await service.importReviewed(
        review,
        testAccount().id,
        cancellation: cancel,
        onProgress: (a, b) => cancel.cancel(),
      );
      expect(first.length, 1);
      expect(f.repository.notes.length, 1);
      await f.restart();
      final second = await NotesTransferService(f.repository).importReviewed(
        review,
        testAccount().id,
        cancellation: NotesTransferCancellation(),
      );
      expect(second.first.alreadyImported, true);
      expect(f.repository.notes.length, 3);
      await f.repository.synchronize(testAccount().id);
      expect(
        f.repository.notes.every((n) => n.syncState == NoteSyncState.synced),
        true,
      );
    },
  );
  test(
    'note cancellation overrides category work durably and retry resumes',
    () async {
      f.remote[1] = {
        ...serverNote(1),
        'category': 'Work/Sub',
        'content': '![image](.attachments.1/a.png)',
      };
      await f.repository.synchronize(testAccount().id, allowWrites: false);
      final note = f.repository.notes.single;
      var offline = NotesOfflineController(f.repository, testAccount().id);
      await offline.initialize();
      await offline.cancelNote(note.localId);
      await offline.setRequirement('category', 'Work');
      await offline.reconcile();
      expect(f.downloads, 0);
      expect((await offline.inspect(note)).paused, true);
      await offline.dispose();
      await f.restart();
      offline = NotesOfflineController(f.repository, testAccount().id);
      await offline.initialize();
      await offline.reconcile();
      expect(f.downloads, 0);
      await offline.retry(note.localId);
      expect((await offline.inspect(note)).available, true);
      expect(f.downloads, 1);
      await offline.dispose();
    },
  );
  test(
    'captured export rejects refreshed media but preserves captured text during later edits',
    () async {
      f.remote[1] = serverNote(1);
      await f.repository.synchronize(testAccount().id, allowWrites: false);
      final note = f.repository.notes.single;
      final snapshot = await f.repository.captureLocalSnapshot(
        testAccount().id,
        {note.localId},
      );
      f.remote[1] = {...f.remote[1]!, 'etag': 'media-refreshed'};
      await f.repository.synchronize(testAccount().id, allowWrites: false);
      final service = NotesTransferService(f.repository);
      await expectLater(
        service.exportSnapshot(
          notes: snapshot,
          destination: f.root.path,
          cancellation: NotesTransferCancellation(),
        ),
        throwsA(isA<FileSystemException>()),
      );
      expect(f.root.listSync().whereType<Directory>(), isEmpty);
      final fresh = await f.repository.captureLocalSnapshot(testAccount().id, {
        note.localId,
      });
      await f.repository.save(note.localId, content: 'later local edit');
      final exported = await service.exportSnapshot(
        notes: fresh,
        destination: f.root.path,
        cancellation: NotesTransferCancellation(),
      );
      final review = await service.review(exported.path, testAccount().id);
      expect(review.items.single.content, fresh.single.content);
      expect(f.repository.noteById(note.localId)!.content, 'later local edit');
    },
  );
  test(
    'account removal during export prevents publication and cleans staging',
    () async {
      final note = await f.repository.create(testAccount().id, content: 'body');
      final snapshot = await f.repository.captureLocalSnapshot(
        testAccount().id,
        {note.localId},
      );
      Future<void>? removal;
      await expectLater(
        NotesTransferService(f.repository).exportSnapshot(
          notes: snapshot,
          destination: f.root.path,
          cancellation: NotesTransferCancellation(),
          onProgress: (_, _) =>
              removal = f.repository.removeAccount(testAccount().id),
        ),
        throwsA(isA<FileSystemException>()),
      );
      await removal;
      expect(f.root.listSync().whereType<Directory>(), isEmpty);
      expect(f.repository.accounts, isEmpty);
    },
  );
  test(
    'export filesystem failure publishes no partial snapshot and keeps unrelated files',
    () async {
      final note = await f.repository.create(
        testAccount().id,
        title: 'Disk failure',
        content: 'retained',
      );
      final destination = File('${f.root.path}/not-a-directory');
      await destination.writeAsString('unrelated');
      await expectLater(
        NotesTransferService(f.repository).exportSnapshot(
          notes: [note],
          destination: destination.path,
          cancellation: NotesTransferCancellation(),
        ),
        throwsA(isA<FileSystemException>()),
      );
      expect(await destination.readAsString(), 'unrelated');
      expect(f.repository.noteById(note.localId)!.content, 'retained');
    },
  );
  test(
    'metadata-only matches highlight original combining characters without a content offset',
    () {
      final hits = matchNotesDocument(
        query: NotesSearchQuery('title:"café"'),
        localId: 'id',
        revision: 1,
        title: 'A cafe\u0301 title',
        category: 'Work',
        source: 'unrelated',
      );
      expect(hits.single.start, isNull);
      expect(
        hits.single.snippet.substring(
          hits.single.snippetMatchStart!,
          hits.single.snippetMatchEnd!,
        ),
        'cafe\u0301',
      );
      expect(
        NotesSearchHit.fromJson(hits.single.toJson()).snippetMatchStart,
        hits.single.snippetMatchStart,
      );
    },
  );
  test(
    'batch same-field conflict blocks publication after an older in-flight PUT response',
    () async {
      f.remote[1] = serverNote(1);
      await f.repository.synchronize(testAccount().id, allowWrites: false);
      final id = f.repository.notes.single.localId;
      final reviewed = f.repository.metadataSnapshot(id);
      await f.repository.save(id, content: 'local content during held PUT');
      f.writeGate = Completer<void>();
      final sending = f.repository.synchronize(testAccount().id);
      await f.writeStarted.future;
      await f.repository.patchMetadata(
        f.repository.metadataSnapshot(id),
        category: 'Concurrent',
      );
      final result = await f.repository.patchMetadataBatch([
        reviewed,
      ], category: 'Reviewed');
      expect(result.single.status, NotesBatchStatus.conflicted);
      f.writeGate!.complete();
      await sending;
      expect(f.repository.noteById(id)!.metadataConflict, isNotNull);
      expect(
        f.repository.noteById(id)!.content,
        'local content during held PUT',
      );
      expect(f.repository.noteById(id)!.category, 'Reviewed');
      expect(f.remote[1]!['category'], reviewed.note.category);
      expect(f.writes, 1);
      await f.restart();
      await f.repository.synchronize(testAccount().id);
      expect(f.writes, 1);
      expect(f.repository.noteById(id)!.metadataConflict, isNotNull);
    },
  );
  test(
    'import association, note, index and bytes roll back as one transaction',
    () async {
      final store = f.repository.store;
      final invalid = NextcloudNote(
        localId: 'new',
        accountId: 'missing',
        title: 'bad',
        content: 'bad',
      );
      await expectLater(
        store.createWithAttachments(invalid, [], importKey: 'key'),
        throwsStateError,
      );
      expect(await store.importedNote(testAccount().id, 'key'), isNull);
      expect(await store.notes(), isEmpty);
      final db = sqlite3.open(store.path);
      expect(db.select('SELECT count(*) AS n FROM note_search').single['n'], 0);
      db.close();
    },
  );
}
