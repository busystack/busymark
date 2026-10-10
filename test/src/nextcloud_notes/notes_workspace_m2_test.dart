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
  Completer<void>? mediaGate, writeGate;
  final writeStarted = Completer<void>();
  final mediaStarted = Completer<void>();
  int downloads = 0, writes = 0;
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
