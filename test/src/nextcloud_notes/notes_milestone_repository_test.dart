import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:busymark/src/nextcloud_notes/application/notes_media.dart';
import 'package:busymark/src/nextcloud_notes/application/notes_repository.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_api_client.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_capabilities.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_store.dart';
import 'package:busymark/src/nextcloud_notes/domain/notes_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqlite3/sqlite3.dart';

import 'notes_api_test.dart' show testAccount, serverNote;

void main() {
  late Directory directory;
  late DateTime now;
  final repositories = <NotesRepository>[];
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('notes-m1-repository-');
    now = DateTime.utc(2026, 9, 1, 12, 0, 0, 123);
  });
  tearDown(() async {
    for (final r in repositories) {
      await r.dispose();
    }
    repositories.clear();
    await directory.delete(recursive: true);
  });
  Future<NotesRepository> open(
    http.Client client, {
    Future<NotesCapabilities> Function(NextcloudAccount)? capabilities,
  }) async {
    final r = NotesRepository(
      store: await NotesStore.open(path: '${directory.path}/notes.sqlite3'),
      clock: () => now,
      fetchCapabilities: capabilities,
      clientForAccount: (account) async => NotesApiClient(
        client: client,
        account: account,
        appPassword: 'fixture',
        clock: () => now,
      ),
    );
    await r.initialize();
    if (r.accounts.isEmpty) await r.upsertAccount(testAccount());
    repositories.add(r);
    return r;
  }

  Future<void> restart(NotesRepository r) async {
    await r.dispose();
    repositories.remove(r);
  }

  Future<String> seed(NotesRepository r) async {
    await r.synchronize(testAccount().id, allowWrites: false);
    return r.notes.single.localId;
  }

  test(
    'a rejected creation route 404 never establishes draft deletion',
    () async {
      var creates = 0;
      final r = await open(
        MockClient((request) async {
          expect(
            request.url.path,
            '/nextcloud/index.php/apps/notes/api/v1/notes',
          );
          if (request.method == 'GET') return http.Response('[]', 200);
          expect(request.method, 'POST');
          creates++;
          return http.Response('{}', 404);
        }),
      );
      final draft = await r.create(
        testAccount().id,
        content: 'retained local creation',
      );
      await r.synchronize(testAccount().id);
      expect(r.noteById(draft.localId)!.syncState, NoteSyncState.rejected);
      expect(
        r.noteById(draft.localId)!.failureScope,
        NotesRequestScope.collection,
      );
      expect(r.noteById(draft.localId)!.creationAttempt, isNull);
      expect(r.noteById(draft.localId)!.creationNeverSent, isTrue);
      await r.synchronize(testAccount().id);
      expect(creates, 1);
      expect(r.noteById(draft.localId)!.content, 'retained local creation');
    },
  );

  test(
    'attachment-only 404 cannot delete its owner or discard upload bytes',
    () async {
      final transport = MockClient((request) async {
        if (request.url.path.endsWith('/v1/notes')) {
          expect(request.method, 'GET');
          return http.Response(jsonEncode([serverNote(1)]), 200);
        }
        expect(
          request.url.path,
          '/nextcloud/index.php/apps/notes/api/v1.4/attachment/1',
        );
        expect(request.method, anyOf('GET', 'POST'));
        return http.Response('{}', 404);
      });
      final r = await open(transport);
      final id = await seed(r);
      await expectLater(
        r.resolveMedia(testAccount().id, id, '.attachments.1/missing.png'),
        throwsA(
          isA<NotesException>().having(
            (e) => e.scope,
            'scope',
            NotesRequestScope.attachment,
          ),
        ),
      );
      expect(r.noteById(id)!.syncState, NoteSyncState.synced);
      final attachment = await r.addAttachment(
        id,
        filename: 'draft.png',
        bytes: Uint8List.fromList([1, 2, 3]),
      );
      await r.save(id, content: '![image](${attachment.reference})');
      await r.synchronize(testAccount().id);
      expect(r.noteById(id)!.syncState, NoteSyncState.rejected);
      expect(r.noteById(id)!.failureScope, NotesRequestScope.attachment);
      expect(
        await r.store.attachmentBytes(attachment.id),
        Uint8List.fromList([1, 2, 3]),
      );
      expect(r.noteById(id)!.content, contains(attachment.reference));
    },
  );

  test(
    'authoritative upload path survives a later local transaction failure and restart',
    () async {
      var uploads = 0;
      var puts = 0;
      final transport = MockClient((request) async {
        if (request.url.path.endsWith('/v1/notes')) {
          expect(request.method, 'GET');
          return http.Response(jsonEncode([serverNote(1)]), 200);
        }
        if (request.method == 'POST') {
          expect(
            request.url.path,
            '/nextcloud/index.php/apps/notes/api/v1.4/attachment/1',
          );
          expect(
            request.headers['content-type'],
            startsWith('multipart/form-data;'),
          );
          uploads++;
          final db = sqlite3.open('${directory.path}/notes.sqlite3');
          db.execute(
            "CREATE TRIGGER reject_publication BEFORE UPDATE ON notes BEGIN SELECT RAISE(ABORT, 'fixture'); END",
          );
          db.close();
          return http.Response(
            jsonEncode({'filename': '.attachments.1/literal%2F.png'}),
            200,
          );
        }
        expect(request.method, 'PUT');
        expect(
          request.url.path,
          '/nextcloud/index.php/apps/notes/api/v1/notes/1',
        );
        expect(request.headers['if-match'], '"abc"');
        puts++;
        final body = jsonDecode(request.body) as Map;
        expect(body['content'], contains('.attachments.1/literal%252F.png'));
        return http.Response(
          jsonEncode({...serverNote(1), ...body, 'etag': 'published'}),
          200,
        );
      });
      var r = await open(transport);
      final id = await seed(r);
      final attachment = await r.addAttachment(
        id,
        filename: 'literal%2F.png',
        bytes: Uint8List.fromList([7, 8]),
      );
      await r.save(id, content: '![image](${attachment.reference})');
      await expectLater(r.synchronize(testAccount().id), throwsStateError);
      final uploaded = (await r.store.attachments(id)).single;
      expect(uploaded.state, 'uploaded');
      expect(uploaded.remotePath, '.attachments.1/literal%2F.png');
      final db = sqlite3.open('${directory.path}/notes.sqlite3');
      db.execute('DROP TRIGGER reject_publication');
      db.close();
      await restart(r);
      r = await open(transport);
      await r.synchronize(testAccount().id);
      expect(uploads, 1);
      expect(puts, 1);
      expect(r.noteById(id)!.syncState, NoteSyncState.synced);
    },
  );

  test(
    'permanent rejection blocks polling and restart, a new edit permits correction',
    () async {
      var puts = 0;
      var reject = true;
      final transport = MockClient((request) async {
        expect(
          request.url.path,
          startsWith('/nextcloud/index.php/apps/notes/api/v1/notes'),
        );
        if (request.method == 'GET') {
          return http.Response(jsonEncode([serverNote(1)]), 200);
        }
        expect(request.method, 'PUT');
        puts++;
        if (reject) return http.Response('{}', 400);
        return http.Response(
          jsonEncode({...serverNote(1), ...jsonDecode(request.body) as Map}),
          200,
        );
      });
      var r = await open(transport);
      final id = await seed(r);
      await r.save(id, content: 'edited');
      await r.synchronize(testAccount().id);
      expect(r.noteById(id)!.syncState, NoteSyncState.rejected);
      for (var i = 0; i < 3; i++) {
        await r.synchronize(testAccount().id);
      }
      await restart(r);
      r = await open(transport);
      await r.synchronize(testAccount().id);
      expect(puts, 1);
      reject = false;
      await r.save(id, content: 'corrected');
      await r.synchronize(testAccount().id);
      expect(puts, 2);
      expect(r.noteById(id)!.content, 'corrected');
    },
  );

  for (final status in [429, 503]) {
    test(
      'media Retry-After $status retains bytes and not-before across restart',
      () async {
        var downloads = 0;
        final transport = MockClient((request) async {
          expect(request.method, 'GET');
          if (request.url.path.endsWith('/v1/notes')) {
            return http.Response(
              jsonEncode([
                serverNote(1, content: '![image](.attachments.1/a.png)'),
              ]),
              200,
            );
          }
          expect(
            request.url.path,
            '/nextcloud/index.php/apps/notes/api/v1.4/attachment/1',
          );
          expect(request.url.queryParameters['path'], '.attachments.1/a.png');
          downloads++;
          if (downloads == 2) {
            return http.Response(
              '{}',
              status,
              headers: {'Retry-After': '3600'},
            );
          }
          return http.Response.bytes([downloads], 200);
        });
        var r = await open(transport);
        final id = await seed(r);
        final path = await r.resolveMedia(
          testAccount().id,
          id,
          '.attachments.1/a.png',
        );
        final validated = (await r.store.attachments(id)).single.validatedAt;
        now = now.add(const Duration(minutes: 6));
        expect(
          await r.resolveMedia(testAccount().id, id, '.attachments.1/a.png'),
          path,
        );
        expect((await r.store.attachments(id)).single.validatedAt, validated);
        final deadline = now.add(const Duration(hours: 1));
        expect(r.accountById(testAccount().id)!.throttleNotBefore, deadline);
        await restart(r);
        r = await open(transport);
        expect(
          await r.resolveMedia(testAccount().id, id, '.attachments.1/a.png'),
          path,
        );
        expect(downloads, 2);
        now = deadline;
        final fresh = await r.resolveMedia(
          testAccount().id,
          id,
          '.attachments.1/a.png',
        );
        expect(fresh, isNot(path));
        expect(downloads, 3);
        expect(await File(fresh!).readAsBytes(), [3]);
      },
    );
  }
  test(
    '429 not-before survives manual retry and restart; HTTP date and long delay',
    () async {
      var puts = 0;
      final deadline = DateTime.fromMillisecondsSinceEpoch(
        now.add(const Duration(days: 2)).millisecondsSinceEpoch ~/ 1000 * 1000,
        isUtc: true,
      );
      final transport = MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(jsonEncode([serverNote(1)]), 200);
        }
        expect(request.method, 'PUT');
        puts++;
        return http.Response(
          '{}',
          429,
          headers: {'rEtRy-AfTeR': HttpDate.format(deadline)},
        );
      });
      var r = await open(transport);
      final id = await seed(r);
      await r.save(id, content: 'edited');
      await r.synchronize(testAccount().id);
      expect(r.noteById(id)!.retryNotBefore, deadline);
      await r.retryWrites(testAccount().id);
      await r.synchronize(testAccount().id);
      expect(puts, 1);
      await restart(r);
      r = await open(transport);
      now = now.add(const Duration(days: 1));
      await r.synchronize(testAccount().id);
      expect(puts, 1);
      now = deadline;
      await r.synchronize(testAccount().id);
      expect(puts, 2);
      expect(
        retryAfter(
          '999999999999999999999999999',
          now,
        )!.isAfter(now.add(const Duration(days: 365))),
        isTrue,
      );
      expect(retryAfter('nonsense', now), isNull);
      expect(retryAfter('-1', now), isNull);
      expect(
        retryAfter(HttpDate.format(now.subtract(const Duration(days: 1))), now),
        now,
      );
    },
  );

  test(
    'legacy poisoned drafts and server edits recover, true absence remains protected',
    () async {
      final r = await open(
        MockClient((request) async {
          if (request.method == 'GET') {
            expect(
              request.url.queryParameters.containsKey('pruneBefore'),
              isFalse,
            );
            return http.Response(
              jsonEncode([serverNote(1), serverNote(2, etag: 'changed')]),
              200,
            );
          }
          fail('Read-only recovery must not publish');
        }),
      );
      final base = NoteState.fromJson(serverNote(1));
      for (final id in [1, 2, 3]) {
        await r.store.saveNote(
          NextcloudNote(
            localId: '00000000-0000-4000-8000-00000000000$id',
            accountId: testAccount().id,
            serverId: id,
            content: 'retained $id',
            title: 'Title',
            etag: base.etag,
            base: base,
            revision: 4,
            ackRevision: 1,
            syncState: NoteSyncState.deletedRemotely,
          ),
        );
      }
      final draft = await r.create(testAccount().id, content: 'retained draft');
      await r.store.saveNote(
        draft.copyWith(syncState: NoteSyncState.deletedRemotely),
      );
      final ambiguous = NextcloudNote.fromJson({
        ...draft.toJson(),
        'localId': '00000000-0000-4000-8000-000000000009',
        'creationNeverSent': false,
        'localActivityMicros': null,
        'syncState': 'deletedRemotely',
      });
      await r.store.saveNote(ambiguous);
      await restart(r);
      final reopened = await open(
        MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.queryParameters['pruneBefore'], isNull);
          return http.Response(
            jsonEncode([serverNote(1), serverNote(2, etag: 'changed')]),
            200,
          );
        }),
      );
      await reopened.synchronize(testAccount().id, allowWrites: false);
      expect(
        reopened.noteById(ambiguous.localId)!.syncState,
        NoteSyncState.recoveryRequired,
      );
      await reopened.save(ambiguous.localId, content: 'Further retained work');
      await reopened.synchronize(testAccount().id, allowWrites: false);
      expect(
        reopened.noteById(ambiguous.localId)!.syncState,
        NoteSyncState.recoveryRequired,
      );
      await reopened.resolveConflict(
        ambiguous.localId,
        NoteConflictResolution.saveAsNew,
      );
      expect(
        reopened.notes.any(
          (n) =>
              n.localId != ambiguous.localId &&
              n.content == 'Further retained work' &&
              n.creationNeverSent,
        ),
        isTrue,
      );
      expect(
        reopened.noteById(ambiguous.localId)!.ackRevision,
        ambiguous.ackRevision,
      );
      expect(
        reopened.noteById(draft.localId)!.syncState,
        NoteSyncState.pending,
      );
      final notes = {for (final n in reopened.notes) n.serverId: n};
      expect(notes[1]!.syncState, NoteSyncState.pending);
      expect(notes[1]!.ackRevision, 1);
      expect(notes[2]!.syncState, NoteSyncState.conflict);
      expect(notes[2]!.content, 'retained 2');
      expect(notes[3]!.syncState, NoteSyncState.deletedRemotely);
      expect(notes[3]!.deletionEvidence, 'completeList');
    },
  );

  test(
    'edit time survives delay, no-op, restart and a newer edit during acknowledgment',
    () async {
      final started = Completer<void>();
      final reply = Completer<void>();
      var delayPut = false;
      final bodies = <Map>[];
      var remote = serverNote(1);
      final transport = MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(jsonEncode([remote]), 200);
        }
        final body = jsonDecode(request.body) as Map;
        bodies.add(body);
        if (delayPut) {
          started.complete();
          await reply.future;
        }
        remote = {...remote, ...body, 'etag': 'written-${bodies.length}'};
        return http.Response(jsonEncode(remote), 200);
      });
      var r = await open(transport);
      final id = await seed(r);
      final firstTime = now;
      await r.save(id, content: 'first');
      now = now.add(const Duration(days: 1));
      await r.save(id, content: 'first');
      expect(
        r.noteById(id)!.localActivityMicros,
        firstTime.microsecondsSinceEpoch,
      );
      await restart(r);
      r = await open(transport);
      delayPut = true;
      final sync = r.synchronize(testAccount().id);
      await started.future;
      final secondTime = now;
      await r.save(id, content: 'second');
      reply.complete();
      await sync;
      expect(
        bodies.single['modified'],
        firstTime.millisecondsSinceEpoch ~/ 1000,
      );
      expect(
        r.noteById(id)!.localActivityMicros,
        secondTime.microsecondsSinceEpoch,
      );
      expect(r.noteById(id)!.hasPendingChanges, isTrue);
      delayPut = false;
      now = now.add(const Duration(days: 1));
      await r.synchronize(testAccount().id);
      expect(
        bodies.last['modified'],
        secondTime.millisecondsSinceEpoch ~/ 1000,
      );
    },
  );

  test(
    'metadata title patch preserves a concurrent remote category and dirty content',
    () async {
      var remote = serverNote(1);
      final r = await open(
        MockClient((request) async {
          expect(request.method, 'GET');
          return http.Response(jsonEncode([remote]), 200);
        }),
      );
      final id = await seed(r);
      final snapshot = r.metadataSnapshot(id);
      remote = {
        ...remote,
        'category': 'Remote category',
        'etag': 'category-change',
      };
      await r.synchronize(testAccount().id, allowWrites: false);
      await r.save(id, content: 'dirty editor content');
      final patched = await r.patchMetadata(snapshot, title: 'Intended title');
      expect(patched.category, 'Remote category');
      expect(patched.title, 'Intended title');
      expect(patched.content, 'dirty editor content');
      expect(patched.syncState, NoteSyncState.pending);
    },
  );

  test(
    'metadata divergent field retains both values, convergence and no-op make no revision',
    () async {
      final r = await open(
        MockClient(
          (_) async => http.Response(jsonEncode([serverNote(1)]), 200),
        ),
      );
      final id = await seed(r);
      final snapshot = r.metadataSnapshot(id);
      await r.patchMetadata(snapshot, title: 'Other local action');
      final changed = await r.patchMetadata(snapshot, title: 'Dialog intent');
      expect(changed.syncState, NoteSyncState.conflict);
      expect(changed.title, 'Dialog intent');
      expect(changed.remote, isNull);
      expect(changed.metadataConflict!.alternative.title, 'Other local action');
      final convergence = r.metadataSnapshot(id);
      final revision = changed.revision;
      final time = changed.localActivityMicros;
      await r.patchMetadata(convergence, title: 'Dialog intent');
      expect(r.noteById(id)!.revision, revision);
      expect(r.noteById(id)!.localActivityMicros, time);
    },
  );

  test(
    'metadata patch revalidates read-only permission and account removal',
    () async {
      var readonly = false;
      final r = await open(
        MockClient(
          (_) async => http.Response(
            jsonEncode([serverNote(1, readonly: readonly)]),
            200,
          ),
        ),
      );
      final id = await seed(r);
      final snapshot = r.metadataSnapshot(id);
      readonly = true;
      await r.synchronize(testAccount().id, allowWrites: false);
      await expectLater(
        r.patchMetadata(snapshot, title: 'blocked'),
        throwsA(
          isA<NotesException>().having(
            (e) => e.code,
            'permission',
            NotesFailureCode.forbidden,
          ),
        ),
      );
      await r.removeAccount(testAccount().id);
      await expectLater(
        r.patchMetadata(snapshot, favorite: true),
        throwsA(isA<NotesException>()),
      );
    },
  );

  test(
    'same-path refresh changes an open media context even with unchanged note ETag',
    () async {
      var bytes = [1, 2];
      var downloads = 0;
      var failed = false;
      final r = await open(
        MockClient((request) async {
          if (request.url.path.contains('/attachment/')) {
            expect(request.method, 'GET');
            expect(request.url.queryParameters['path'], '.attachments.1/a.png');
            downloads++;
            return failed
                ? http.Response('', 503)
                : http.Response.bytes(bytes, 200);
          }
          expect(request.url.path.endsWith('/v1/notes'), isTrue);
          return http.Response(
            jsonEncode([serverNote(1, content: '![a](.attachments.1/a.png)')]),
            200,
          );
        }),
      );
      final id = await seed(r);
      r.setDisplayedMediaNotes([id]);
      final media = NextcloudDocumentMedia(r, testAccount().id, id);
      final oldContext = media.context;
      final first = await media.resolve('.attachments.1/a.png');
      expect(await File(first!).readAsBytes(), [1, 2]);
      bytes = [3, 4];
      await r.refreshDisplayedMedia(force: true);
      final second = await media.resolve('.attachments.1/a.png');
      expect(await File(second!).readAsBytes(), [3, 4]);
      expect(second, isNot(first));
      expect(media.context.identity, isNot(oldContext.identity));
      final validated = (await r.attachments(id)).single.validatedAt;
      failed = true;
      now = now.add(const Duration(minutes: 6));
      await r.refreshDisplayedMedia();
      expect(
        await File(
          (await media.resolve('.attachments.1/a.png'))!,
        ).readAsBytes(),
        [3, 4],
      );
      expect((await r.attachments(id)).single.validatedAt, validated);
      final files = await Directory(
        '${directory.path}/media/${testAccount().id}/$id',
      ).list().toList();
      expect(files.length, 1);
      expect(downloads, greaterThanOrEqualTo(3));
    },
  );

  for (final action in ['deletion', 'removal', 'disposal']) {
    test(
      'concurrent media coalesces and $action fences a late download',
      () async {
        final started = Completer<void>();
        final reply = Completer<void>();
        var downloads = 0;
        final r = await open(
          MockClient((request) async {
            if (request.url.path.contains('/attachment/')) {
              downloads++;
              started.complete();
              await reply.future;
              return http.Response.bytes([9], 200);
            }
            return http.Response(
              jsonEncode([
                serverNote(1, content: '![a](.attachments.1/a.png)'),
              ]),
              200,
            );
          }),
        );
        final id = await seed(r);
        if (action == 'deletion') {
          await r.store.saveAttachment(
            NotesAttachment(
              id: '22175816-3b00-46a8-8d16-e11e6a583cc4',
              noteId: id,
              filename: 'a.png',
              reference: '.attachments.1/a.png',
              remotePath: '.attachments.1/a.png',
              state: 'cached',
            ),
            Uint8List.fromList([1]),
          );
        }
        final a = r.resolveMedia(testAccount().id, id, '.attachments.1/a.png');
        final b = r.resolveMedia(testAccount().id, id, '.attachments.1/a.png');
        await started.future;
        expect(downloads, 1);
        Future<void>? disposing;
        if (action == 'deletion') {
          final attachment = (await r.attachments(id)).single;
          await r.store.updateAttachment(
            NotesAttachment(
              id: attachment.id,
              noteId: id,
              filename: 'a.png',
              reference: '.attachments.1/a.png',
              remotePath: '.attachments.1/a.png',
              state: 'deleted',
            ),
          );
        }
        if (action == 'removal') await r.removeAccount(testAccount().id);
        if (action == 'disposal') {
          disposing = r.dispose();
          repositories.remove(r);
        }
        reply.complete();
        await Future.wait([
          a.then<void>((p) {
            expect(p, isNull);
          }),
          b.then<void>((p) {
            expect(p, isNull);
          }),
        ]);
        await disposing;
        expect(
          await Directory('${directory.path}/downloads').list().toList(),
          isEmpty,
        );
      },
    );
  }

  test(
    'settings partial update, normalization, pending path blocker and checkpoint reset',
    () async {
      var settings = {'notesPath': 'Notes', 'fileSuffix': '.txt'};
      final puts = <Map>[];
      final r = await open(
        MockClient((request) async {
          if (request.url.path.endsWith('/v1/settings')) {
            if (request.method == 'PUT') {
              final body = jsonDecode(request.body) as Map;
              puts.add(body);
              settings = {
                ...settings,
                for (final e in body.entries)
                  e.key as String: (e.value as String).trim(),
              };
            }
            return http.Response(jsonEncode({...settings, 'unknown': 1}), 200);
          }
          expect(request.method, 'GET');
          return http.Response(
            jsonEncode([serverNote(1)]),
            200,
            headers: {
              'ETag': '"checkpoint"',
              'Last-Modified': 'Tue, 01 Sep 2026 12:00:00 GMT',
            },
          );
        }),
      );
      final id = await seed(r);
      final original = await r.getSettings(testAccount().id);
      final result = await r.changeSettings(testAccount().id, original, {
        'fileSuffix': ' .custom ',
      });
      expect(result.fileSuffix, '.custom');
      expect(puts.single, {'fileSuffix': ' .custom '});
      expect(r.accounts.single.listEtag, isNull);
      await r.save(id, content: 'pending');
      await expectLater(
        r.changeSettings(testAccount().id, result, {'notesPath': 'Different'}),
        throwsA(isA<NotesException>()),
      );
      expect(puts.length, 1);
      expect(r.noteById(id)!.content, 'pending');
    },
  );

  test(
    'lost settings PUT response reconciles by GET, restart retains an unreadable attempt',
    () async {
      var settings = {'notesPath': 'Notes', 'fileSuffix': '.txt'};
      var failedRead = false;
      var puts = 0;
      final transport = MockClient((request) async {
        expect(request.url.path.endsWith('/v1/settings'), isTrue);
        if (request.method == 'PUT') {
          puts++;
          settings = {
            ...settings,
            ...Map<String, String>.from(jsonDecode(request.body) as Map),
          };
          failedRead = true;
          throw http.ClientException('lost');
        }
        if (failedRead) throw http.ClientException('offline');
        return http.Response(jsonEncode(settings), 200);
      });
      var r = await open(transport);
      final original = await r.getSettings(testAccount().id);
      await expectLater(
        r.changeSettings(testAccount().id, original, {'notesPath': 'New'}),
        throwsA(isA<NotesException>()),
      );
      expect(r.accounts.single.settingsAttempt, isNotNull);
      await restart(r);
      r = await open(transport);
      await expectLater(
        r.create(testAccount().id),
        throwsA(isA<NotesException>()),
      );
      failedRead = false;
      final result = await r.reconcileSettings(testAccount().id);
      expect(result.notesPath, 'New');
      expect(r.accounts.single.settingsAttempt, isNull);
      expect(puts, 1);
      expect(r.accounts.single.listEtag, isNull);
    },
  );

  test(
    'capability freshness updates deletion gate and preserves current checkpoint',
    () async {
      var version = '6.0.2';
      var calls = 0;
      final r = await open(
        MockClient((request) async {
          expect(request.method, 'GET');
          return http.Response('[]', 200, headers: {'ETag': '"checkpoint"'});
        }),
        capabilities: (_) async {
          calls++;
          return NotesCapabilities(appVersion: version, apiVersion: '1.4');
        },
      );
      await r.synchronize(testAccount().id);
      expect(r.accounts.single.supportsAttachmentDeletion, isFalse);
      expect(calls, 1);
      version = '6.1.0';
      await r.maintainCapabilities(testAccount().id, force: true);
      expect(r.accounts.single.supportsAttachmentDeletion, isTrue);
      expect(r.accounts.single.listEtag, '"checkpoint"');
      await r.recordApiVersions(
        testAccount().id,
        r.accountGeneration(testAccount().id),
        r.capabilityEpoch(testAccount().id),
        '0.2, 1.3',
      );
      expect(r.accounts.single.apiSupported, isFalse);
      expect(r.accounts.single.supportsAttachmentDeletion, isFalse);
      await r.recordApiVersions(
        testAccount().id,
        r.accountGeneration(testAccount().id),
        r.capabilityEpoch(testAccount().id),
        'garbage',
      );
      expect(r.accounts.single.apiSupported, isFalse);
      expect(
        await r.create(testAccount().id, content: 'local recovery'),
        isNotNull,
      );
    },
  );

  test(
    'capability and settings responses cannot restore removed account state',
    () async {
      final started = Completer<void>();
      final reply = Completer<NotesCapabilities>();
      final r = await open(
        MockClient((_) async => http.Response('{}', 404)),
        capabilities: (_) {
          started.complete();
          return reply.future;
        },
      );
      final pending = r.maintainCapabilities(testAccount().id);
      await started.future;
      await r.removeAccount(testAccount().id);
      reply.complete(
        const NotesCapabilities(appVersion: '6.2.0', apiVersion: '1.5'),
      );
      await pending;
      expect(r.accounts, isEmpty);
      expect(await r.store.accounts(), isEmpty);
    },
  );

  for (final schema in [2, 3, 4]) {
    test(
      'v$schema migration retains exact outbox and bytes; failed recovery rolls back fence; v6 rejected',
      () async {
        final r = await open(MockClient((_) async => http.Response('[]', 200)));
        final draft = await r.create(testAccount().id, content: 'retained');
        final attachment = await r.addAttachment(
          draft.localId,
          filename: 'a.bin',
          bytes: Uint8List.fromList([1, 2]),
        );
        await restart(r);
        var db = sqlite3.open('${directory.path}/notes.sqlite3');
        db.execute('DROP TRIGGER IF EXISTS notes_search_delete');
        for (final table in [
          'note_search',
          'note_search_map',
          'offline_requirements',
          'import_items',
        ]) {
          db.execute('DROP TABLE IF EXISTS $table');
        }
        db.execute('PRAGMA user_version=$schema');
        final outbox = db.select('SELECT data FROM outbox').single['data'];
        db.close();
        final migrated = await open(
          MockClient((_) async => http.Response('[]', 200)),
        );
        expect(
          migrated.notes.single.localActivityMicros,
          draft.localActivityMicros,
        );
        expect(await migrated.store.attachmentBytes(attachment.id), [1, 2]);
        await restart(migrated);
        db = sqlite3.open('${directory.path}/notes.sqlite3');
        expect(db.select('PRAGMA user_version').single.values.single, 5);
        expect(db.select('SELECT data FROM outbox').single['data'], outbox);
        db.execute('DROP TRIGGER IF EXISTS notes_search_delete');
        for (final table in [
          'note_search',
          'note_search_map',
          'offline_requirements',
          'import_items',
        ]) {
          db.execute('DROP TABLE IF EXISTS $table');
        }
        db.execute('PRAGMA user_version=$schema');
        db.execute("UPDATE notes SET data='{}'");
        db.close();
        await expectLater(
          NotesStore.open(path: '${directory.path}/notes.sqlite3'),
          throwsStateError,
        );
        db = sqlite3.open('${directory.path}/notes.sqlite3');
        expect(db.select('PRAGMA user_version').single.values.single, schema);
        expect(
          db.select(
            "SELECT name FROM sqlite_master WHERE name IN ('note_search','offline_requirements','import_items')",
          ),
          isEmpty,
        );
        db.execute('PRAGMA user_version=6');
        db.close();
        await expectLater(
          NotesStore.open(path: '${directory.path}/notes.sqlite3'),
          throwsStateError,
        );
      },
    );
  }
}
