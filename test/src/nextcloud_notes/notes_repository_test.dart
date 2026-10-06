import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:busymark/src/nextcloud_notes/application/notes_repository.dart';
import 'package:busymark/src/nextcloud_notes/application/notes_media.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_api_client.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_store.dart';
import 'package:busymark/src/nextcloud_notes/domain/notes_models.dart';
import 'package:busymark/src/nextcloud_notes/domain/notes_conflict.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqlite3/sqlite3.dart';

import 'notes_api_test.dart' show serverNote, testAccount, testNote;

void main() {
  late Directory directory;
  late String path;
  final repositories = <NotesRepository>[];
  final stores = <NotesStore>[];

  Future<NotesRepository> open(
    http.Client client, {
    bool addAccount = true,
  }) async {
    final store = await NotesStore.open(path: path);
    final repository = NotesRepository(
      store: store,
      clientForAccount: (account) async => NotesApiClient(
        client: client,
        account: account,
        appPassword: 'test-secret',
      ),
    );
    await repository.initialize();
    if (addAccount && repository.accounts.isEmpty) {
      await repository.upsertAccount(testAccount());
    }
    repositories.add(repository);
    return repository;
  }

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('busymark-notes-test-');
    path = '${directory.path}/notes.sqlite3';
  });
  tearDown(() async {
    for (final repository in repositories) {
      await repository.dispose();
    }
    repositories.clear();
    for (final store in stores) {
      await store.close();
    }
    stores.clear();
    await directory.delete(recursive: true);
  });

  test(
    'v1 data migrates without losing pending content or inventing an attempt',
    () async {
      final store = await NotesStore.open(path: path);
      await store.saveAccount(testAccount());
      await store.saveNote(
        testNote(
          serverId: null,
        ).copyWith(syncState: NoteSyncState.creationUncertain),
      );
      await store.close();
      final old = sqlite3.open(path);
      old.execute('PRAGMA user_version=1');
      old.close();
      final repository = await open(
        MockClient((_) async => http.Response('[]', 200)),
      );
      expect(repository.notes.single.content, 'body');
      expect(repository.notes.single.creationAttempt, isNull);
      expect(
        repository.notes.single.syncState,
        NoteSyncState.creationUncertain,
      );
    },
  );

  test(
    'uncertain creation adopts wire revision and preserves later edits',
    () async {
      Map<String, dynamic>? remote;
      var posts = 0;
      var puts = 0;
      final repository = await open(
        MockClient((request) async {
          if (request.method == 'POST') {
            posts++;
            remote = {...serverNote(1), ...jsonDecode(request.body) as Map};
            throw http.ClientException('lost response');
          }
          if (request.method == 'PUT') {
            puts++;
            expect(jsonDecode(request.body)['content'], 'newer local content');
            remote = {
              ...remote!,
              ...jsonDecode(request.body) as Map,
              'etag': 'new',
            };
          }
          return http.Response(
            jsonEncode(
              request.method == 'GET' ? [if (remote != null) remote] : remote,
            ),
            200,
          );
        }),
      );
      final local = await repository.create(
        testAccount().id,
        content: 'sent content',
      );
      await repository.synchronize(local.accountId);
      await repository.save(local.localId, content: 'newer local content');
      await repository.synchronize(local.accountId);
      expect(
        repository.noteById(local.localId)!.content,
        'newer local content',
      );
      expect(
        repository.noteById(local.localId)!.syncState,
        NoteSyncState.synced,
      );
      expect(posts, 1);
      expect(puts, 1);
    },
  );

  test(
    'unsupported attachment cleanup queues nothing and core updates still sync',
    () async {
      var remote = serverNote(1);
      var deletes = 0;
      final repository = await open(
        MockClient((request) async {
          if (request.method == 'DELETE') deletes++;
          if (request.method == 'PUT') {
            remote = {...remote, ...jsonDecode(request.body) as Map};
          }
          return http.Response(
            jsonEncode(request.method == 'GET' ? [remote] : remote),
            200,
          );
        }),
      );
      await repository.upsertAccount(testAccount(appVersion: '6.0.1'));
      await repository.synchronize(testAccount().id);
      final note = repository.notes.single;
      final attachment = NotesAttachment(
        id: 'a',
        noteId: note.localId,
        filename: 'flat.png',
        reference: 'flat.png',
        remotePath: 'flat.png',
        state: 'cached',
      );
      await repository.store.saveAttachment(
        attachment,
        Uint8List.fromList([1]),
      );
      await expectLater(
        repository.deleteAttachment(note.localId, 'flat.png'),
        throwsA(
          isA<NotesException>().having(
            (e) => e.code,
            'code',
            NotesFailureCode.unsupported,
          ),
        ),
      );
      expect(
        (await repository.attachments(note.localId)).single.state,
        'cached',
      );
      await repository.save(note.localId, content: 'still editable');
      await repository.synchronize(note.accountId);
      expect(
        repository.noteById(note.localId)!.syncState,
        NoteSyncState.synced,
      );
      expect(deletes, 0);
    },
  );

  for (final scenario in [
    'ordinary',
    'attachment',
    'sanitized title',
    'sanitized category',
    'sanitized attachment',
    'restart',
    'restart attachment',
    'restart sanitized attachment',
    'ambiguous',
  ]) {
    test(
      'lost create response reconciles $scenario without another POST',
      () async {
        late NotesRepository repository;
        Map<String, dynamic>? remote;
        var posts = 0;
        var uploads = 0;
        final client = MockClient((request) async {
          if (request.method == 'GET') {
            return http.Response(
              jsonEncode([
                if (remote != null) remote,
                if (remote != null && scenario == 'ambiguous')
                  {...remote!, 'id': 2},
              ]),
              200,
            );
          }
          if (request.method == 'POST' && request.url.path.endsWith('/notes')) {
            posts++;
            final persisted = (await repository.store.notes()).single;
            expect(persisted.creationAttempt!.wireBody, request.body);
            expect(persisted.creationAttempt!.id, isNotEmpty);
            final wire = jsonDecode(request.body) as Map<String, dynamic>;
            expect(wire['content'], isNot(contains('busymark-attachment:')));
            remote = {...serverNote(1), ...wire};
            if (scenario == 'sanitized title' ||
                scenario.contains('sanitized attachment')) {
              remote!['title'] = 'Sanitized title (2)';
            }
            if (scenario == 'sanitized category') {
              remote!['category'] = 'Safe/Category';
            }
            throw http.ClientException('lost response');
          }
          if (request.method == 'POST') {
            uploads++;
            return http.Response(
              '{"filename":".attachments.1/photo.png"}',
              200,
            );
          }
          expect(request.method, 'PUT');
          expect(request.headers['If-Match'], '"${remote!['etag']}"');
          remote = {
            ...remote!,
            ...jsonDecode(request.body) as Map,
            'etag': 'published',
          };
          return http.Response(jsonEncode(remote), 200);
        });
        repository = await open(client);
        final note = await repository.create(
          testAccount().id,
          content: 'Unique exact wire body',
          title: 'Original / title',
          category: 'Original: / Category',
        );
        final staged = scenario.contains('attachment');
        if (staged) {
          final attachment = await repository.addAttachment(
            note.localId,
            filename: 'photo.png',
            bytes: Uint8List.fromList([1, 2, 3]),
          );
          await repository.save(
            note.localId,
            content: '${note.content}\n![photo](${attachment.reference})',
          );
        }
        await repository.synchronize(note.accountId);
        final uncertain = repository.noteById(note.localId)!;
        expect(uncertain.syncState, NoteSyncState.creationUncertain);
        if (staged) {
          expect(uncertain.content, contains('busymark-attachment:'));
          expect(
            uncertain.creationAttempt!.attributes['content'],
            isNot(contains('busymark-attachment:')),
          );
        }
        if (scenario.startsWith('restart')) {
          await repository.dispose();
          repositories.remove(repository);
          repository = await open(client, addAccount: false);
          expect(
            repository.noteById(note.localId)!.creationAttempt!.wireBody,
            uncertain.creationAttempt!.wireBody,
          );
        }
        await repository.synchronize(note.accountId);
        var reconciled = repository.noteById(note.localId)!;
        if (scenario == 'restart sanitized attachment') {
          await repository.dispose();
          repositories.remove(repository);
          repository = await open(client, addAccount: false);
          reconciled = repository.noteById(note.localId)!;
        }
        final requiresAdoption =
            scenario.contains('sanitized') || scenario == 'ambiguous';
        if (requiresAdoption) {
          expect(reconciled.serverId, isNull);
          expect(reconciled.syncState, NoteSyncState.creationUncertain);
          expect(
            reconciled.creationAttempt!.candidateServerIds,
            scenario == 'ambiguous' ? {1, 2} : {1},
          );
          expect(reconciled.remote?.id, scenario == 'ambiguous' ? isNull : 1);
          await repository.resolveConflict(
            note.localId,
            NoteConflictResolution.takeRemote,
            creationCandidateServerId: scenario == 'ambiguous' ? 1 : null,
          );
          await repository.synchronize(note.accountId);
          reconciled = repository.noteById(note.localId)!;
        }
        expect(reconciled.serverId, 1);
        expect(repository.notes, hasLength(scenario == 'ambiguous' ? 2 : 1));
        expect(reconciled.syncState, NoteSyncState.synced);
        expect(reconciled.title, remote!['title']);
        expect(reconciled.category, remote!['category']);
        if (staged) {
          expect(reconciled.content, contains('.attachments.1/photo.png'));
        }
        await repository.synchronize(note.accountId);
        expect(posts, 1);
        expect(uploads, staged ? 1 : 0);
      },
    );
  }

  test(
    'uncertain creation excludes preexisting IDs and empty weak matches',
    () async {
      var remote = serverNote(1, content: '');
      var posts = 0;
      final repository = await open(
        MockClient((request) async {
          if (request.method == 'POST') {
            posts++;
            remote = {
              ...remote,
              ...jsonDecode(request.body) as Map<String, dynamic>,
            };
            throw http.ClientException('lost response');
          }
          return http.Response(
            jsonEncode([
              remote,
              if (posts > 0) {...remote, 'id': 2},
            ]),
            200,
          );
        }),
      );
      final local = await repository.create(testAccount().id, content: '');
      await repository.synchronize(local.accountId);
      expect(
        repository.noteById(local.localId)!.creationAttempt!.knownServerIds,
        {1},
      );
      await repository.synchronize(local.accountId);
      expect(repository.noteById(local.localId)!.serverId, isNull);
      expect(
        repository.noteById(local.localId)!.syncState,
        NoteSyncState.creationUncertain,
      );
      expect(posts, 1);
    },
  );

  test(
    'an exact candidate is not auto-adopted by one of two plausible attempts',
    () async {
      const content = 'same wire content';
      const modified = 1770000001;
      final seedStore = await NotesStore.open(path: path);
      await seedStore.saveAccount(testAccount());
      for (final entry in [
        ('first', 'Exact title'),
        ('second', 'Other title'),
      ]) {
        final wireBody = jsonEncode({
          'content': content,
          'title': entry.$2,
          'category': '',
          'favorite': false,
          'modified': modified,
        });
        await seedStore.saveNote(
          NextcloudNote(
            localId: entry.$1,
            accountId: testAccount().id,
            title: entry.$2,
            content: content,
            creationAttempt: NotesCreationAttempt(
              id: '${entry.$1}-attempt',
              revision: 1,
              localContent: content,
              wireBody: wireBody,
              knownServerIds: const {},
            ),
            syncState: NoteSyncState.creationUncertain,
          ),
        );
      }
      await seedStore.close();
      var posts = 0;
      final candidate = {
        ...serverNote(1, content: content),
        'title': 'Exact title',
        'category': '',
        'modified': modified,
      };
      final repository = await open(
        MockClient((request) async {
          if (request.method == 'POST') posts++;
          return http.Response(jsonEncode([candidate]), 200);
        }),
        addAccount: false,
      );

      await repository.synchronize(testAccount().id);
      for (final id in ['first', 'second']) {
        final note = repository.noteById(id)!;
        expect(note.serverId, isNull);
        expect(note.syncState, NoteSyncState.creationUncertain);
        expect(note.creationAttempt!.candidateServerIds, {1});
      }
      expect(posts, 0);
    },
  );

  for (final attribute in ['favorite', 'title', 'content']) {
    test(
      'three-way merge preserves remote $attribute and independent local edit',
      () async {
        var remote = serverNote(1);
        var puts = 0;
        final repository = await open(
          MockClient((request) async {
            if (request.method == 'PUT') {
              puts++;
              expect(request.headers['If-Match'], '"fresh"');
              remote = {
                ...remote,
                ...jsonDecode(request.body) as Map,
                'etag': 'resolved',
              };
            }
            return http.Response(
              jsonEncode(
                request.url.path.endsWith('/notes') ? [remote] : remote,
              ),
              200,
            );
          }),
        );
        await repository.synchronize(testAccount().id);
        final note = repository.notes.single;
        await repository.save(
          note.localId,
          content: attribute == 'content' ? note.content : 'local content',
          category: attribute == 'content' ? 'Local category' : null,
        );
        remote = {
          ...remote,
          'etag': 'fresh',
          attribute: attribute == 'favorite' ? true : 'remote $attribute',
        };
        await repository.synchronize(note.accountId);
        expect(
          repository.noteById(note.localId)!.syncState,
          NoteSyncState.conflict,
        );
        await repository.resolveConflict(
          note.localId,
          NoteConflictResolution.merge,
        );
        final merged = repository.noteById(note.localId)!;
        expect(
          merged.content,
          attribute == 'content' ? 'remote content' : 'local content',
        );
        if (attribute == 'favorite') expect(merged.favorite, isTrue);
        if (attribute == 'title') expect(merged.title, 'remote title');
        if (attribute == 'content') expect(merged.category, 'Local category');
        expect(merged.syncState, NoteSyncState.pending);
        expect(merged.etag, 'fresh');
        await repository.synchronize(note.accountId);
        expect(puts, 1);
      },
    );
  }

  for (final attribute in [
    NotesMergeAttribute.title,
    NotesMergeAttribute.category,
  ]) {
    test('divergent $attribute requires explicit choice', () async {
      var remote = serverNote(1);
      final repository = await open(
        MockClient(
          (request) async => http.Response(
            jsonEncode(request.url.path.endsWith('/notes') ? [remote] : remote),
            200,
          ),
        ),
      );
      await repository.synchronize(testAccount().id);
      final note = repository.notes.single;
      await repository.save(
        note.localId,
        content: note.content,
        title: attribute == NotesMergeAttribute.title ? 'local' : null,
        category: attribute == NotesMergeAttribute.category ? 'local' : null,
      );
      remote = {...remote, attribute.name: 'remote', 'etag': 'fresh'};
      await repository.synchronize(note.accountId);
      await expectLater(
        repository.resolveConflict(note.localId, NoteConflictResolution.merge),
        throwsA(
          isA<NotesException>().having(
            (e) => e.code,
            'code',
            NotesFailureCode.conflict,
          ),
        ),
      );
      expect(repository.noteById(note.localId)!.base!.etag, 'abc');
      await repository.resolveConflict(
        note.localId,
        NoteConflictResolution.merge,
        metadataChoices: {attribute: NotesMergeChoice.remote},
      );
      final merged = repository.noteById(note.localId)!;
      expect(
        attribute == NotesMergeAttribute.title ? merged.title : merged.category,
        'remote',
      );
      expect(merged.hasPendingChanges, isTrue);
    });
  }

  test(
    '412 merge keeps remote protected fields and local favorite on readonly note',
    () async {
      var remote = serverNote(1);
      var updateAttempts = 0;
      final repository = await open(
        MockClient((request) async {
          if (request.method == 'PUT') {
            updateAttempts++;
            if (updateAttempts == 1) {
              remote = serverNote(
                1,
                content: 'remote content',
                etag: 'fresh',
                readonly: true,
              );
              return http.Response(jsonEncode(remote), 412);
            }
            expect(jsonDecode(request.body), {'favorite': true});
            remote = {...remote, 'favorite': true, 'etag': 'resolved'};
            return http.Response(jsonEncode(remote), 200);
          }
          return http.Response(
            jsonEncode(request.url.path.endsWith('/notes') ? [remote] : remote),
            200,
          );
        }),
      );
      await repository.synchronize(testAccount().id);
      final id = repository.notes.single.localId;
      await repository.save(id, content: 'body', favorite: true);

      await repository.synchronize(testAccount().id);
      expect(repository.noteById(id)!.syncState, NoteSyncState.conflict);
      expect(repository.noteById(id)!.readonly, isTrue);

      await repository.resolveConflict(id, NoteConflictResolution.merge);
      final merged = repository.noteById(id)!;
      expect(merged.content, 'remote content');
      expect(merged.title, 'Title');
      expect(merged.category, 'Parent/Child');
      expect(merged.favorite, isTrue);
      expect(merged.syncState, NoteSyncState.pending);

      await repository.synchronize(testAccount().id);
      expect(repository.noteById(id)!.syncState, NoteSyncState.synced);
      expect(updateAttempts, 2);
    },
  );

  test(
    'readonly conflict accepts an explicit favorite choice when base is absent',
    () async {
      final remote = NoteState.fromJson({
        ...serverNote(1, etag: 'fresh', readonly: true),
        'favorite': true,
      });
      final seedStore = await NotesStore.open(path: path);
      await seedStore.saveAccount(testAccount());
      await seedStore.saveNote(
        testNote().copyWith(
          base: null,
          remote: remote,
          readonly: true,
          favorite: false,
          revision: 2,
          ackRevision: 1,
          syncState: NoteSyncState.conflict,
        ),
      );
      await seedStore.close();
      final repository = await open(
        MockClient((request) async => http.Response(jsonEncode(remote), 200)),
        addAccount: false,
      );

      await expectLater(
        repository.resolveConflict(
          testNote().localId,
          NoteConflictResolution.merge,
        ),
        throwsA(
          isA<NotesException>().having(
            (error) => error.code,
            'code',
            NotesFailureCode.conflict,
          ),
        ),
      );
      await repository.resolveConflict(
        testNote().localId,
        NoteConflictResolution.merge,
        metadataChoices: const {
          NotesMergeAttribute.favorite: NotesMergeChoice.local,
        },
      );
      final resolved = repository.noteById(testNote().localId)!;
      expect(resolved.favorite, isFalse);
      expect(resolved.content, remote.content);
      expect(resolved.title, remote.title);
      expect(resolved.category, remote.category);
      expect(resolved.readonly, isTrue);
      expect(resolved.syncState, NoteSyncState.pending);
    },
  );

  test(
    'schema migration, foreign-key transaction rollback and Linux permissions',
    () async {
      final store = await NotesStore.open(path: path);
      stores.add(store);
      await store.saveAccount(testAccount());
      final note = testNote();
      await expectLater(
        store.commit(
          notes: [note, note.copyWith(serverId: 2).copyWith()],
          accounts: [],
        ),
        completes,
      ); // Coalesced same logical identity remains valid.
      final invalid = NextcloudNote(
        localId: 'invalid-note',
        accountId: 'missing-account',
        content: 'bad',
        title: 'bad',
      );
      await expectLater(
        store.commit(
          notes: [
            note.copyWith(content: 'should rollback'),
            invalid,
          ],
        ),
        throwsStateError,
      );
      expect((await store.notes()).single.content, 'body');
      final db = sqlite3.open(path);
      expect(db.select('PRAGMA user_version').single.values.single, 2);
      expect(db.select('SELECT COUNT(*) AS n FROM outbox').single['n'], 1);
      db.close();
      if (Platform.isLinux) {
        expect((await File(path).stat()).mode & 0x1ff, 0x180);
        expect((await directory.stat()).mode & 0x1ff, 0x1c0);
      }
    },
  );

  test('durable new note survives restart before any HTTP request', () async {
    var calls = 0;
    final client = MockClient((_) async {
      calls++;
      throw http.ClientException('offline');
    });
    var repository = await open(client);
    final note = await repository.create(
      testAccount().id,
      title: 'Offline',
      content: 'exact offline content',
    );
    expect(calls, 0);
    await repository.save(
      note.localId,
      content: 'revision 10',
      editorRevision: 10,
    );
    await repository.dispose();
    repositories.remove(repository);
    repository = await open(client, addAccount: false);
    expect(repository.noteById(note.localId)!.content, 'revision 10');
    expect(repository.noteById(note.localId)!.revision, 10);
    expect(repository.noteById(note.localId)!.hasPendingChanges, isTrue);
    await repository.synchronize(testAccount().id);
    expect(repository.noteById(note.localId)!.syncState, NoteSyncState.offline);
    expect(repository.noteById(note.localId)!.content, 'revision 10');
  });

  test(
    'older capture cannot overwrite a newer durable editor revision',
    () async {
      final repository = await open(
        MockClient((_) async => http.Response('[]', 200)),
      );
      final note = await repository.create(testAccount().id);
      await repository.save(note.localId, content: 'newer', editorRevision: 11);
      await repository.save(note.localId, content: 'older', editorRevision: 10);
      expect(repository.noteById(note.localId)!.content, 'newer');
      expect((await repository.store.notes()).single.revision, 11);
    },
  );

  test('metadata revision does not invalidate a new editor capture', () async {
    final repository = await open(
      MockClient((_) async => http.Response('[]', 200)),
    );
    final note = await repository.create(testAccount().id);
    await repository.save(
      note.localId,
      content: 'capture 9',
      editorRevision: 9,
    );
    await repository.save(
      note.localId,
      content: 'capture 9',
      title: 'Metadata 10',
    );
    await repository.save(note.localId, content: 'capture 9', favorite: true);
    expect(repository.noteById(note.localId)!.revision, 11);
    final saved = await repository.save(
      note.localId,
      content: 'capture 10',
      editorRevision: 10,
    );
    expect(saved.content, 'capture 10');
    expect(saved.revision, 12);
    expect(saved.editorRevision, 10);
    await repository.save(note.localId, content: 'obsolete', editorRevision: 9);
    expect(repository.noteById(note.localId)!.content, 'capture 10');
  });

  test(
    'account failure is visible even with only synchronized cached notes',
    () async {
      var offline = false;
      final repository = await open(
        MockClient((_) async {
          if (offline) throw http.ClientException('offline');
          return http.Response(jsonEncode([serverNote(1)]), 200);
        }),
      );
      await repository.synchronize(testAccount().id);
      offline = true;
      await repository.synchronize(testAccount().id);
      expect(
        repository.accountError(testAccount().id)!.code,
        NotesFailureCode.network,
      );
      expect(repository.notes.single.hasPendingChanges, isFalse);
      offline = false;
      await repository.synchronize(testAccount().id);
      expect(repository.accountError(testAccount().id), isNull);
    },
  );

  test(
    'attachment delete operation survives offline restart and retains history bytes',
    () async {
      var offline = false;
      var deletes = 0;
      final client = MockClient((request) async {
        if (offline) throw http.ClientException('offline');
        if (request.method == 'DELETE') {
          deletes++;
          return http.Response('[]', 200);
        }
        if (request.method == 'GET') {
          return http.Response(jsonEncode([serverNote(1)]), 200);
        }
        return http.Response(jsonEncode(serverNote(1)), 200);
      });
      var repository = await open(client);
      await repository.synchronize(testAccount().id);
      final note = repository.notes.single;
      const attachmentId = '9cb3c381-ee60-4ed3-a71d-263d28b97012';
      await repository.store.saveAttachment(
        NotesAttachment(
          id: attachmentId,
          noteId: note.localId,
          filename: 'old.png',
          reference: '.attachments.1/old.png',
          remotePath: '.attachments.1/old.png',
          state: 'cached',
        ),
        Uint8List.fromList([4, 5]),
      );
      offline = true;
      await repository.deleteAttachment(note.localId, '.attachments.1/old.png');
      expect(
        (await repository.attachments(note.localId)).single.state,
        'deletePending',
      );
      await repository.dispose();
      repositories.remove(repository);
      repository = await open(client, addAccount: false);
      offline = false;
      await repository.synchronize(testAccount().id);
      expect(deletes, 1);
      expect(
        (await repository.attachments(note.localId)).single.state,
        'deleted',
      );
      expect(await repository.store.attachmentBytes(attachmentId), [4, 5]);
    },
  );

  test(
    'taking remote cannot discard a local edit made while fresh GET is pending',
    () async {
      var resolving = false;
      final started = Completer<void>();
      final reply = Completer<http.Response>();
      final repository = await open(
        MockClient((request) async {
          if (resolving) {
            started.complete();
            return reply.future;
          }
          return http.Response(jsonEncode([serverNote(1)]), 200);
        }),
      );
      await repository.synchronize(testAccount().id);
      final id = repository.notes.single.localId;
      await repository.save(id, content: 'local before', editorRevision: 2);
      resolving = true;
      final resolvingFuture = repository.resolveConflict(
        id,
        NoteConflictResolution.takeRemote,
      );
      await started.future;
      await repository.save(id, content: 'local during', editorRevision: 3);
      reply.complete(
        http.Response(
          jsonEncode(serverNote(1, content: 'fresh remote', etag: 'fresh')),
          200,
        ),
      );
      await expectLater(resolvingFuture, throwsA(isA<NotesException>()));
      expect(repository.noteById(id)!.content, 'local during');
    },
  );

  test(
    'revision 10 acknowledgment leaves edit 11 pending during flight',
    () async {
      final sending = Completer<void>();
      final response = Completer<http.Response>();
      var block = false;
      final repository = await open(
        MockClient((request) async {
          if (request.method == 'GET') {
            return http.Response(jsonEncode([serverNote(1)]), 200);
          }
          expect(request.headers['If-Match'], '"abc"');
          expect(jsonDecode(request.body)['content'], 'revision 10');
          if (block) {
            sending.complete();
            return response.future;
          }
          return http.Response(jsonEncode(serverNote(1)), 200);
        }),
      );
      await repository.synchronize(testAccount().id);
      final id = repository.notes.single.localId;
      await repository.save(id, content: 'revision 10', editorRevision: 10);
      block = true;
      final sync = repository.synchronize(testAccount().id);
      await sending.future;
      await repository.save(id, content: 'revision 11', editorRevision: 11);
      response.complete(
        http.Response(
          jsonEncode(serverNote(1, etag: 'ack10', content: 'revision 10')),
          200,
        ),
      );
      await sync;
      final note = repository.noteById(id)!;
      expect(note.content, 'revision 11');
      expect(note.ackRevision, 10);
      expect(note.revision, 11);
      expect(note.syncState, NoteSyncState.pending);
      expect(note.base!.content, 'revision 10');
      expect(note.etag, 'ack10');
    },
  );

  test('412 preserves base/local/current remote without overwrite', () async {
    final repository = await open(
      MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(jsonEncode([serverNote(1)]), 200);
        }
        return http.Response(
          jsonEncode(serverNote(1, etag: 'other', content: 'remote edit')),
          412,
        );
      }),
    );
    await repository.synchronize(testAccount().id);
    final id = repository.notes.single.localId;
    await repository.save(id, content: 'local edit');
    await repository.synchronize(testAccount().id);
    final note = repository.noteById(id)!;
    expect(note.base!.content, 'body');
    expect(note.content, 'local edit');
    expect(note.remote!.content, 'remote edit');
    expect(note.syncState, NoteSyncState.conflict);
  });

  test('locked note does not block unrelated synchronization', () async {
    final putIds = <int>[];
    final repository = await open(
      MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(jsonEncode([serverNote(1), serverNote(2)]), 200);
        }
        final id = int.parse(request.url.pathSegments.last);
        putIds.add(id);
        if (id == 1) return http.Response('{}', 423);
        return http.Response(
          jsonEncode(serverNote(id, etag: 'saved', content: 'edited')),
          200,
        );
      }),
    );
    await repository.synchronize(testAccount().id);
    for (final note in repository.notes) {
      await repository.save(note.localId, content: 'edited');
    }
    await repository.synchronize(testAccount().id);
    expect(putIds.toSet(), {1, 2});
    expect(
      repository.notes.singleWhere((n) => n.serverId == 1).syncState,
      NoteSyncState.locked,
    );
    expect(
      repository.notes.singleWhere((n) => n.serverId == 1).content,
      'edited',
    );
    expect(
      repository.notes.singleWhere((n) => n.serverId == 2).syncState,
      NoteSyncState.synced,
    );
  });

  test(
    'interrupted chunks preserve notes and previous checkpoint atomically',
    () async {
      var phase = 0;
      var chunks = 0;
      final repository = await open(
        MockClient((_) async {
          if (phase == 0) {
            return http.Response(
              jsonEncode([serverNote(1), serverNote(2)]),
              200,
              headers: {
                'ETag': '"good"',
                'Last-Modified': 'Mon, 02 Feb 2026 02:40:00 GMT',
              },
            );
          }
          if (++chunks == 1) {
            return http.Response(
              jsonEncode([serverNote(1, content: 'partial')]),
              200,
              headers: {
                'X-Notes-Chunk-Cursor': 'next',
                'ETag': '"partial"',
                'Last-Modified': 'Tue, 03 Feb 2026 02:40:00 GMT',
              },
            );
          }
          throw http.ClientException('interrupted');
        }),
      );
      await repository.synchronize(testAccount().id);
      phase = 1;
      await repository.synchronize(testAccount().id);
      expect(repository.notes.length, 2);
      expect(repository.notes.every((n) => n.content == 'body'), isTrue);
      expect(repository.accountById(testAccount().id)!.listEtag, '"good"');
      expect(
        (await repository.store.accounts()).single.lastModified,
        'Mon, 02 Feb 2026 02:40:00 GMT',
      );
    },
  );

  test(
    'complete remote disappearance retains dirty content for recovery',
    () async {
      var missing = false;
      final repository = await open(
        MockClient(
          (_) async =>
              http.Response(missing ? '[]' : jsonEncode([serverNote(1)]), 200),
        ),
      );
      await repository.synchronize(testAccount().id);
      final id = repository.notes.single.localId;
      await repository.save(id, content: 'recovery');
      missing = true;
      await repository.synchronize(testAccount().id);
      final note = repository.noteById(id)!;
      expect(note.syncState, NoteSyncState.deletedRemotely);
      expect(note.content, 'recovery');
      expect(note.hasPendingChanges, isTrue);
    },
  );

  test(
    'server error-state content never replaces known good cached content',
    () async {
      var error = false;
      final repository = await open(
        MockClient(
          (_) async => http.Response(
            jsonEncode([
              serverNote(
                1,
                error: error,
                content: error ? 'Error: FileException' : 'known good',
              ),
            ]),
            200,
          ),
        ),
      );
      await repository.synchronize(testAccount().id);
      error = true;
      await repository.synchronize(testAccount().id);
      expect(repository.notes.single.content, 'known good');
      expect(repository.notes.single.error, isTrue);
      expect(repository.notes.single.syncState, NoteSyncState.unavailable);
      error = false;
      await repository.synchronize(testAccount().id);
      expect(repository.notes.single.error, isFalse);
      expect(repository.notes.single.syncState, NoteSyncState.synced);
    },
  );

  test(
    'pretransition editor capture remains durable when server becomes readonly',
    () async {
      var readonly = false;
      var puts = 0;
      final repository = await open(
        MockClient((request) async {
          if (request.method == 'PUT') {
            puts++;
            return http.Response('{}', 403);
          }
          return http.Response(
            jsonEncode([serverNote(1, readonly: readonly)]),
            200,
          );
        }),
      );
      await repository.synchronize(testAccount().id);
      final id = repository.notes.single.localId;
      readonly = true;
      await repository.synchronize(testAccount().id);
      await repository.save(
        id,
        content: 'typed before transition',
        editorRevision: 2,
      );
      await repository.synchronize(testAccount().id);
      expect(repository.noteById(id)!.content, 'typed before transition');
      expect(repository.noteById(id)!.hasPendingChanges, isTrue);
      expect(puts, 0);
    },
  );

  test('uncertain creation never blindly repeats POST after restart', () async {
    var posts = 0;
    final client = MockClient((request) async {
      if (request.method == 'GET') return http.Response('[]', 200);
      posts++;
      throw http.ClientException('lost response');
    });
    var repository = await open(client);
    final note = await repository.create(
      testAccount().id,
      content: 'uncertain',
    );
    await repository.synchronize(testAccount().id);
    expect(
      repository.noteById(note.localId)!.syncState,
      NoteSyncState.creationUncertain,
    );
    await repository.dispose();
    repositories.remove(repository);
    repository = await open(client, addAccount: false);
    await repository.synchronize(testAccount().id);
    expect(posts, 1);
    expect(repository.noteById(note.localId)!.content, 'uncertain');
  });

  test('crash-marked create is recovered as uncertain without POST', () async {
    final store = await NotesStore.open(path: path);
    await store.saveAccount(testAccount());
    await store.saveNote(
      testNote(serverId: null).copyWith(syncState: NoteSyncState.syncing),
    );
    await store.close();
    var posts = 0;
    final repository = await open(
      MockClient((request) async {
        if (request.method == 'POST') posts++;
        return http.Response('[]', 200);
      }),
      addAccount: false,
    );
    expect(repository.notes.single.syncState, NoteSyncState.creationUncertain);
    await repository.synchronize(testAccount().id);
    expect(posts, 0);
  });

  test(
    'delete checks fresh state; failed DELETE retains durable content',
    () async {
      var deleting = false;
      var freshEtag = 'abc';
      var deletes = 0;
      final repository = await open(
        MockClient((request) async {
          if (request.method == 'DELETE') {
            deletes++;
            return http.Response('{}', 500);
          }
          return http.Response(
            jsonEncode(
              deleting ? serverNote(1, etag: freshEtag) : [serverNote(1)],
            ),
            200,
          );
        }),
      );
      await repository.synchronize(testAccount().id);
      final id = repository.notes.single.localId;
      deleting = true;
      freshEtag = 'changed';
      await expectLater(repository.delete(id), throwsA(isA<NotesException>()));
      expect(deletes, 0);
      freshEtag = 'abc';
      await expectLater(repository.delete(id), throwsA(isA<NotesException>()));
      expect(deletes, 1);
      expect(repository.noteById(id)!.content, 'body');
      expect((await repository.store.notes()).single.content, 'body');
    },
  );

  test(
    'new offline attachment restart creates/uploads/publishes authoritative path',
    () async {
      final calls = <String>[];
      var serverContent = '';
      final client = MockClient((request) async {
        calls.add('${request.method} ${request.url.path}');
        if (request.method == 'GET') return http.Response('[]', 200);
        if (request.url.path.contains('/attachment/')) {
          return http.Response(
            '{"filename":".attachments.1/photo (1).png"}',
            200,
          );
        }
        serverContent = jsonDecode(request.body)['content'] as String;
        expect(serverContent, isNot(contains('busymark-attachment:')));
        return http.Response(
          jsonEncode(serverNote(1, content: serverContent, etag: 'new')),
          200,
        );
      });
      var repository = await open(client);
      final note = await repository.create(
        testAccount().id,
        title: 'Title',
        category: 'Parent/Child',
      );
      final attachment = await repository.addAttachment(
        note.localId,
        filename: 'photo.png',
        bytes: Uint8List.fromList([1, 2, 3]),
      );
      await repository.save(
        note.localId,
        content: '![image](${attachment.reference})',
      );
      final localPath = await repository.resolveMedia(
        note.accountId,
        note.localId,
        attachment.reference,
      );
      expect(localPath, endsWith('.png'));
      expect(await File(localPath!).readAsBytes(), [1, 2, 3]);
      await repository.dispose();
      repositories.remove(repository);
      repository = await open(client, addAccount: false);
      await repository.synchronize(testAccount().id);
      expect(calls.map((c) => c.split(' ').first), [
        'GET',
        'POST',
        'POST',
        'PUT',
      ]);
      expect(
        repository.noteById(note.localId)!.content,
        '![image](.attachments.1/photo%20%281%29.png)',
      );
      expect(
        repository.noteById(note.localId)!.syncState,
        NoteSyncState.synced,
      );
    },
  );

  test(
    'uploaded attachment stage survives restart and is not uploaded twice',
    () async {
      final store = await NotesStore.open(path: path);
      await store.saveAccount(testAccount());
      final note = testNote(content: '![x](busymark-attachment:staged)');
      await store.saveNote(note);
      await store.saveAttachment(
        NotesAttachment(
          id: 'a',
          noteId: note.localId,
          filename: 'x.png',
          reference: 'busymark-attachment:staged',
          remotePath: '.attachments.1/x.png',
          state: 'uploaded',
        ),
        Uint8List.fromList([1]),
      );
      await store.close();
      var uploads = 0;
      final repository = await open(
        MockClient((request) async {
          if (request.method == 'GET') {
            return http.Response(jsonEncode([serverNote(1)]), 200);
          }
          if (request.method == 'POST') uploads++;
          return http.Response(
            jsonEncode(
              serverNote(
                1,
                etag: 'updated',
                content: jsonDecode(request.body)['content'] as String,
              ),
            ),
            200,
          );
        }),
        addAccount: false,
      );
      await repository.synchronize(testAccount().id);
      expect(uploads, 0);
      expect(repository.notes.single.content, '![x](.attachments.1/x.png)');
    },
  );

  test(
    'concurrent contexts share one cache owner and deletion invalidates all media',
    () async {
      const reference = '.attachments.1/photo.png';
      var fetches = 0;
      var deletes = 0;
      final started = Completer<void>();
      final release = Completer<void>();
      final repository = await open(
        MockClient((request) async {
          if (request.url.path.contains('/attachment/')) {
            if (request.method == 'DELETE') {
              deletes++;
              return http.Response('', 200);
            }
            fetches++;
            if (!started.isCompleted) started.complete();
            await release.future;
            return http.Response.bytes([1, 2, 3], 200);
          }
          return http.Response(
            jsonEncode(
              request.method == 'PUT' ? serverNote(1) : [serverNote(1)],
            ),
            200,
          );
        }),
      );
      await repository.synchronize(testAccount().id);
      final note = repository.notes.single;
      final first = NextcloudDocumentMedia(
        repository,
        note.accountId,
        note.localId,
      );
      final second = NextcloudDocumentMedia(
        repository,
        note.accountId,
        note.localId,
      );
      final oldContext = first.context;
      final a = first.resolve(reference);
      await started.future;
      final b = second.resolve(reference);
      release.complete();
      final paths = await Future.wait([a, b]);
      expect(paths[0], isNotNull);
      expect(paths[0], paths[1]);
      expect(fetches, 1);
      final attachment = (await repository.attachments(note.localId)).single;
      expect(oldContext.resolveCached(reference), paths[0]);
      // Simulate duplicate rows already persisted by the previous implementation.
      await repository.store.saveAttachment(
        NotesAttachment(
          id: '9cb3c381-ee60-4ed3-a71d-263d28b97012',
          noteId: note.localId,
          filename: 'photo.png',
          reference: reference,
          remotePath: reference,
          state: 'cached',
        ),
        Uint8List.fromList([1, 2, 3]),
      );
      await repository.deleteAttachment(note.localId, reference);
      expect(deletes, 1);
      expect(
        (await repository.attachments(
          note.localId,
        )).every((a) => a.state == 'deleted'),
        isTrue,
      );
      expect(await repository.store.attachmentBytes(attachment.id), [1, 2, 3]);
      expect(await File(paths[0]!).exists(), isFalse);
      expect(oldContext.resolveCached(reference), isNull);
      expect(first.context.identity, isNot(oldContext.identity));
      expect(await first.resolve(reference), isNull);
      expect(await second.resolve(reference), isNull);
      expect(
        await NextcloudDocumentMedia(
          repository,
          note.accountId,
          note.localId,
        ).resolve(reference),
        isNull,
      );
      expect(fetches, 1);
      await repository.dispose();
      repositories.remove(repository);
      final restarted = await open(
        MockClient(
          (_) async => throw StateError('Deleted media must not be fetched'),
        ),
      );
      expect(
        await restarted.resolveMedia(note.accountId, note.localId, reference),
        isNull,
      );
      expect(await restarted.store.attachmentBytes(attachment.id), [1, 2, 3]);
    },
  );

  test(
    'a deliberate re-upload can reuse a deleted attachment filename',
    () async {
      final repository = await open(
        MockClient(
          (_) async => http.Response(jsonEncode([serverNote(1)]), 200),
        ),
      );
      await repository.synchronize(testAccount().id);
      final note = repository.notes.single;
      const reference = '.attachments.1/photo.png';
      for (final deleted in [true, false]) {
        await repository.store.saveAttachment(
          NotesAttachment(
            id: deleted
                ? '123e4567-e89b-42d3-a456-426614174000'
                : '223e4567-e89b-42d3-a456-426614174000',
            noteId: note.localId,
            filename: 'photo.png',
            reference: deleted ? reference : 'busymark-attachment:new-upload',
            remotePath: reference,
            state: deleted ? 'deleted' : 'uploaded',
          ),
          Uint8List.fromList(deleted ? [1] : [2]),
        );
      }
      final path = await repository.resolveMedia(
        note.accountId,
        note.localId,
        reference,
      );
      expect(path, isNotNull);
      expect(await File(path!).readAsBytes(), [2]);
    },
  );

  test(
    'own upload acknowledgment does not stale a newer editor capture',
    () async {
      var remote = serverNote(1, content: 'initial', etag: 'initial');
      var puts = 0;
      final repository = await open(
        MockClient((request) async {
          if (request.method == 'PUT') {
            expect(request.headers['if-match'], '"${remote['etag']}"');
            puts++;
            remote = serverNote(
              1,
              content: (jsonDecode(request.body) as Map)['content'] as String,
              etag: 'own-$puts',
            );
            return http.Response(jsonEncode(remote), 200);
          }
          return http.Response(jsonEncode([remote]), 200);
        }),
      );
      await repository.synchronize(testAccount().id);
      final id = repository.notes.single.localId;
      final editBase = repository.editorBase(id);
      await repository.save(
        id,
        content: 'first edit',
        editorRevision: 2,
        editBase: editBase,
      );
      await repository.synchronize(testAccount().id);
      await repository.save(
        id,
        content: 'newer edit',
        editorRevision: 3,
        editBase: editBase,
      );
      expect(repository.noteById(id)!.syncState, NoteSyncState.pending);
      await repository.synchronize(testAccount().id);
      expect(puts, 2);
      expect(repository.noteById(id)!.content, 'newer edit');
      expect(repository.noteById(id)!.syncState, NoteSyncState.synced);
    },
  );

  test('media rejects invalid logical IDs and symbolic-link parent', () async {
    final repository = await open(
      MockClient((_) async => http.Response('[]', 200)),
    );
    await expectLater(
      repository.resolveMedia('../escape', 'invalid', 'a.png'),
      throwsA(isA<NotesException>()),
    );
    final note = await repository.create(testAccount().id);
    final attachment = await repository.addAttachment(
      note.localId,
      filename: 'a.png',
      bytes: Uint8List.fromList([1]),
    );
    await Link('${directory.path}/media').create('/tmp');
    expect(
      await repository.resolveMedia(
        note.accountId,
        note.localId,
        attachment.reference,
      ),
      isNull,
    );
  });

  test(
    'recovery clones durable pending attachments without rewriting prose or code',
    () async {
      final repository = await open(
        MockClient((_) async => throw http.ClientException('offline')),
      );
      final original = await repository.create(testAccount().id);
      final asset = await repository.addAttachment(
        original.localId,
        filename: 'photo.png',
        bytes: Uint8List.fromList([8, 9]),
      );
      final content =
          '![actual](${asset.reference})\n\nLiteral ${asset.reference}\n\n'
          '`![inline](${asset.reference})`\n\n```\n![fenced](${asset.reference})\n```\n';
      await repository.save(original.localId, content: content);
      final recovered = await repository.recoverAsNew(original.localId);
      final copies = await repository.attachments(recovered.localId);
      expect(copies.length, 1);
      expect(copies.single.reference, isNot(asset.reference));
      expect(
        recovered.content,
        startsWith('![actual](${copies.single.reference})'),
      );
      expect(recovered.content, contains('Literal ${asset.reference}'));
      expect(recovered.content, contains('`![inline](${asset.reference})`'));
      expect(recovered.content, contains('![fenced](${asset.reference})'));
      expect(await repository.store.attachmentBytes(copies.single.id), [8, 9]);
      expect(repository.noteById(original.localId)!.content, content);
    },
  );

  test(
    'recovery rewrites shared attachment definitions and refuses unavailable bytes atomically',
    () async {
      final repository = await open(
        MockClient((_) async => http.Response('{}', 404)),
      );
      final original = await repository.create(testAccount().id);
      final asset = await repository.addAttachment(
        original.localId,
        filename: 'photo.png',
        bytes: Uint8List.fromList([8]),
      );
      final source = '![actual][asset]\n\n[asset]: ${asset.reference}\n';
      final recovered = await repository.recoverAsNew(
        original.localId,
        content: source,
      );
      final copied = (await repository.attachments(recovered.localId)).single;
      expect(
        recovered.content,
        '![actual][asset]\n\n[asset]: ${copied.reference}\n',
      );
      final serverBacked = testNote(
        content: '![missing](.attachments.1/missing.png)',
      );
      await repository.store.saveNote(serverBacked);
      await repository.dispose();
      repositories.remove(repository);
      final reopened = await open(
        MockClient((_) async => http.Response('{}', 404)),
        addAccount: false,
      );
      final count = reopened.notes.length;
      await expectLater(
        reopened.recoverAsNew(serverBacked.localId),
        throwsA(isA<NotesException>()),
      );
      expect(reopened.notes.length, count);
    },
  );

  test(
    'discard after confirmed remote deletion retains tombstone content and cached bytes',
    () async {
      var phase = 0;
      final repository = await open(
        MockClient((request) async {
          if (phase == 0) {
            return http.Response(jsonEncode([serverNote(1)]), 200);
          }
          if (request.url.path.endsWith('/notes')) {
            return http.Response('[]', 200);
          }
          return http.Response('{}', 404);
        }),
      );
      await repository.synchronize(testAccount().id);
      final original = repository.notes.single;
      await repository.save(
        original.localId,
        content: 'retain discarded history',
      );
      phase = 1;
      await repository.synchronize(testAccount().id);
      expect(repository.noteById(original.localId)!.hasPendingChanges, isTrue);
      await repository.resolveConflict(
        original.localId,
        NoteConflictResolution.takeRemote,
      );
      final discarded = repository.noteById(original.localId)!;
      expect(discarded.syncState, NoteSyncState.deletedRemotely);
      expect(discarded.hasPendingChanges, isFalse);
      expect(discarded.content, 'retain discarded history');
    },
  );

  test(
    'history restoration restages deleted bytes before editing and survives restart',
    () async {
      var repository = await open(
        MockClient((_) async => throw http.ClientException('offline')),
      );
      final note = await repository.create(
        testAccount().id,
        content: 'current content',
      );
      final original = await repository.addAttachment(
        note.localId,
        filename: 'photo.png',
        bytes: Uint8List.fromList([3, 4]),
      );
      await repository.store.updateAttachment(
        NotesAttachment(
          id: original.id,
          noteId: note.localId,
          filename: original.filename,
          reference: original.reference,
          remotePath: '.attachments.1/photo.png',
          state: 'deleted',
        ),
      );
      final source =
          '![photo](.attachments.1/photo.png)\n\nLiteral .attachments.1/photo.png';
      final restored = await repository.prepareRestoredContent(
        note.localId,
        source,
      );
      final attachments = await repository.attachments(note.localId);
      final staged = attachments.singleWhere((a) => a.state == 'pending');
      expect(
        restored,
        '![photo](${staged.reference})\n\nLiteral .attachments.1/photo.png',
      );
      expect(repository.noteById(note.localId)!.content, 'current content');
      expect(await repository.store.attachmentBytes(staged.id), [3, 4]);
      await repository.save(note.localId, content: restored, editorRevision: 2);
      await repository.dispose();
      repositories.remove(repository);
      repository = await open(
        MockClient((_) async => throw http.ClientException('offline')),
        addAccount: false,
      );
      expect(repository.noteById(note.localId)!.content, restored);
      expect(await repository.store.attachmentBytes(staged.id), [3, 4]);
    },
  );

  test(
    'readonly attachment deletion preserves content and attachment bytes',
    () async {
      final store = await NotesStore.open(path: path);
      await store.saveAccount(testAccount());
      final note = testNote().copyWith(readonly: true);
      await store.saveNote(note);
      await store.saveAttachment(
        NotesAttachment(
          id: 'readonly-attachment',
          noteId: note.localId,
          filename: 'a.png',
          reference: '.attachments.1/a.png',
          remotePath: '.attachments.1/a.png',
          state: 'uploaded',
        ),
        Uint8List.fromList([1]),
      );
      await store.close();
      var calls = 0;
      final repository = await open(
        MockClient((_) async {
          calls++;
          return http.Response('{}', 200);
        }),
        addAccount: false,
      );
      await expectLater(
        repository.deleteAttachment(note.localId, '.attachments.1/a.png'),
        throwsA(
          isA<NotesException>().having(
            (e) => e.code,
            'code',
            NotesFailureCode.forbidden,
          ),
        ),
      );
      expect(calls, 0);
      expect(await repository.store.attachmentBytes('readonly-attachment'), [
        1,
      ]);
      expect(repository.noteById(note.localId)!.content, note.content);
    },
  );

  test(
    'ordinary Save atomically restages a deleted attachment restored by undo',
    () async {
      final store = await NotesStore.open(path: path);
      await store.saveAccount(testAccount());
      final note = testNote(content: 'after deletion');
      await store.saveNote(note);
      await store.saveAttachment(
        NotesAttachment(
          id: 'deleted-attachment',
          noteId: note.localId,
          filename: 'picture.png',
          reference: 'busymark-attachment:previous-staging',
          remotePath: '.attachments.1/picture.png',
          state: 'deleted',
        ),
        Uint8List.fromList([9, 8]),
      );
      await store.close();
      var repository = await open(
        MockClient((_) async => throw http.ClientException('offline')),
        addAccount: false,
      );
      final saved = await repository.save(
        note.localId,
        content: '![undo](.attachments.1/picture.png)',
        editorRevision: 10,
      );
      final attachments = await repository.attachments(note.localId);
      final staged = attachments.singleWhere((a) => a.state == 'pending');
      expect(saved.content, '![undo](${staged.reference})');
      expect(
        repository.resolvePublishedReferences(
          note.localId,
          '![undo](.attachments.1/picture.png)\n\nLiteral .attachments.1/picture.png\n`![code](.attachments.1/picture.png)`',
        ),
        '![undo](${staged.reference})\n\nLiteral .attachments.1/picture.png\n`![code](.attachments.1/picture.png)`',
      );
      expect(saved.revision, 10);
      expect(saved.hasPendingChanges, isTrue);
      expect(await repository.store.attachmentBytes(staged.id), [9, 8]);
      await repository.dispose();
      repositories.remove(repository);
      repository = await open(
        MockClient((_) async => throw http.ClientException('offline')),
        addAccount: false,
      );
      expect(repository.noteById(note.localId)!.content, saved.content);
      expect(await repository.store.attachmentBytes(staged.id), [9, 8]);
    },
  );

  test(
    'unrelated edits preserve explicit attachment deletion; newly restored links restage',
    () async {
      final store = await NotesStore.open(path: path);
      await store.saveAccount(testAccount());
      const reference = '.attachments.1/deleted.png';
      final note = testNote(content: '![missing]($reference)');
      await store.saveNote(note);
      await store.saveAttachment(
        NotesAttachment(
          id: 'deleted',
          noteId: note.localId,
          filename: 'deleted.png',
          reference: reference,
          remotePath: reference,
          state: 'deleted',
        ),
        Uint8List.fromList([5]),
      );
      await store.close();
      final repository = await open(
        MockClient((_) async => throw http.ClientException('offline')),
        addAccount: false,
      );
      final unrelated = await repository.save(
        note.localId,
        content: '${note.content}\n\nUnrelated edit',
        editorRevision: 10,
      );
      expect(unrelated.content, '${note.content}\n\nUnrelated edit');
      expect((await repository.attachments(note.localId)).length, 1);
      await repository.save(
        note.localId,
        content: 'link removed',
        editorRevision: 11,
      );
      final restored = await repository.save(
        note.localId,
        content: note.content,
        editorRevision: 12,
      );
      expect(restored.content, isNot(note.content));
      expect(
        (await repository.attachments(
          note.localId,
        )).where((a) => a.state == 'pending').length,
        1,
      );
    },
  );

  test(
    'explicit unpublished deletion can retain recovery bytes without uploading',
    () async {
      final repository = await open(
        MockClient((_) async => throw http.ClientException('offline')),
      );
      final note = await repository.create(testAccount().id);
      final attachment = await repository.addAttachment(
        note.localId,
        filename: 'draft.png',
        bytes: Uint8List.fromList([7]),
      );
      await repository.deleteAttachment(
        note.localId,
        attachment.reference,
        retainForHistory: true,
      );
      expect(
        (await repository.attachments(note.localId)).single.state,
        'deleted',
      );
      expect(await repository.store.attachmentBytes(attachment.id), [7]);
      final restored = await repository.prepareRestoredContent(
        note.localId,
        '![history](${attachment.reference})',
      );
      expect(restored, isNot(contains(attachment.reference)));
    },
  );

  test(
    'literal private namespace in a new note does not create pending publication',
    () async {
      const content =
          'Literal busymark-attachment:example\n\n`![code](busymark-attachment:example)`';
      var posts = 0;
      var puts = 0;
      final repository = await open(
        MockClient((request) async {
          if (request.method == 'GET') return http.Response('[]', 200);
          if (request.method == 'POST') posts++;
          if (request.method == 'PUT') puts++;
          expect(jsonDecode(request.body)['content'], content);
          return http.Response(
            jsonEncode(serverNote(1, content: content)),
            200,
          );
        }),
      );
      final note = await repository.create(testAccount().id, content: content);
      await repository.synchronize(note.accountId);
      expect(repository.noteById(note.localId)!.content, content);
      expect(
        repository.noteById(note.localId)!.syncState,
        NoteSyncState.synced,
      );
      expect(posts, 1);
      expect(puts, 0);
    },
  );

  test(
    'merge and keep-local reject a local edit made during fresh GET',
    () async {
      for (final resolution in [
        NoteConflictResolution.merge,
        NoteConflictResolution.keepLocal,
      ]) {
        final started = Completer<void>();
        final reply = Completer<http.Response>();
        var resolving = false;
        final repository = await open(
          MockClient((request) async {
            if (resolving) {
              started.complete();
              return reply.future;
            }
            return http.Response(jsonEncode([serverNote(1)]), 200);
          }),
        );
        await repository.synchronize(testAccount().id);
        final note = repository.notes.single;
        await repository.save(
          note.localId,
          content: 'local before',
          editorRevision: 2,
        );
        resolving = true;
        final resolvingFuture = repository.resolveConflict(
          note.localId,
          resolution,
          mergedContent: 'stale merge',
        );
        await started.future;
        await repository.save(
          note.localId,
          content: 'local during',
          editorRevision: 3,
        );
        reply.complete(
          http.Response(jsonEncode(serverNote(1, etag: 'fresh')), 200),
        );
        await expectLater(resolvingFuture, throwsA(isA<NotesException>()));
        expect(repository.noteById(note.localId)!.content, 'local during');
        await repository.dispose();
        repositories.remove(repository);
        await File(path).delete();
      }
    },
  );

  test(
    'conflict overwrite requires review again when remote changes after comparison',
    () async {
      var remoteEtag = 'base';
      var remoteContent = 'body';
      final repository = await open(
        MockClient(
          (request) async => http.Response(
            jsonEncode(
              request.url.path.endsWith('/notes')
                  ? [serverNote(1, etag: remoteEtag, content: remoteContent)]
                  : serverNote(1, etag: remoteEtag, content: remoteContent),
            ),
            200,
          ),
        ),
      );
      await repository.synchronize(testAccount().id);
      final note = repository.notes.single;
      await repository.save(note.localId, content: 'local edit');
      remoteEtag = 'reviewed';
      remoteContent = 'remote reviewed';
      await repository.synchronize(note.accountId);
      expect(repository.noteById(note.localId)!.remote!.etag, 'reviewed');
      remoteEtag = 'newer';
      remoteContent = 'remote unseen';
      await expectLater(
        repository.resolveConflict(
          note.localId,
          NoteConflictResolution.keepLocal,
        ),
        throwsA(isA<NotesException>()),
      );
      final unresolved = repository.noteById(note.localId)!;
      expect(unresolved.content, 'local edit');
      expect(unresolved.base!.etag, 'base');
      expect(unresolved.remote!.content, 'remote unseen');
      expect(unresolved.syncState, NoteSyncState.conflict);
    },
  );

  test(
    'uncertain creation adoption preserves a durably edited downloaded twin',
    () async {
      final store = await NotesStore.open(path: path);
      await store.saveAccount(testAccount());
      final remote = NoteState.fromJson(
        serverNote(1, content: 'uncertain source'),
      );
      final original = testNote(
        serverId: null,
        content: remote.content,
      ).copyWith(remote: remote, syncState: NoteSyncState.creationUncertain);
      final twin = NextcloudNote(
        localId: 'c6b38b40-858c-42de-80a4-1315bfb3c578',
        accountId: original.accountId,
        serverId: 1,
        content: remote.content,
        title: remote.title,
        category: remote.category,
        etag: remote.etag,
        base: remote,
        revision: 1,
        ackRevision: 1,
        syncState: NoteSyncState.synced,
      );
      await store.commit(notes: [original, twin]);
      await store.close();
      final repository = await open(
        MockClient((_) async => throw StateError('Adoption needs no HTTP')),
        addAccount: false,
      );
      await repository.save(
        twin.localId,
        content: 'durable twin edit',
        editorRevision: 2,
      );
      await expectLater(
        repository.resolveConflict(
          original.localId,
          NoteConflictResolution.takeRemote,
        ),
        throwsA(
          isA<NotesException>().having(
            (error) => error.code,
            'code',
            NotesFailureCode.conflict,
          ),
        ),
      );
      expect(repository.notes.length, 2);
      expect(repository.noteById(original.localId)!.serverId, isNull);
      expect(repository.noteById(original.localId)!.content, remote.content);
      expect(
        repository.noteById(original.localId)!.syncState,
        NoteSyncState.creationUncertain,
      );
      expect(repository.noteById(twin.localId)!.content, 'durable twin edit');
      expect(repository.noteById(twin.localId)!.hasPendingChanges, isTrue);
      final durable = await repository.store.notes();
      expect(durable.length, 2);
      expect(
        durable.singleWhere((n) => n.localId == twin.localId).content,
        'durable twin edit',
      );
    },
  );

  test(
    'list checkpoint preserves account capabilities refreshed during HTTP',
    () async {
      final started = Completer<void>();
      final reply = Completer<http.Response>();
      final repository = await open(
        MockClient((_) async {
          started.complete();
          return reply.future;
        }),
      );
      final synchronization = repository.synchronize(testAccount().id);
      await started.future;
      final previous = repository.accounts.single;
      await repository.upsertAccount(
        NextcloudAccount(
          id: previous.id,
          server: previous.server,
          loginName: previous.loginName,
          appVersion: '6.2.0',
          apiVersion: '1.5',
        ),
      );
      reply.complete(
        http.Response(
          '[]',
          200,
          headers: {
            'ETag': '"checkpoint"',
            'Last-Modified': 'Mon, 02 Feb 2026 02:40:00 GMT',
          },
        ),
      );
      await synchronization;
      expect(repository.accounts.single.appVersion, '6.2.0');
      expect(repository.accounts.single.apiVersion, '1.5');
      expect(repository.accounts.single.listEtag, '"checkpoint"');
      expect((await repository.store.accounts()).single.appVersion, '6.2.0');
    },
  );

  test(
    'readonly acknowledgment exposes recovery for a newer in-flight local edit',
    () async {
      final sending = Completer<void>();
      final reply = Completer<http.Response>();
      var puts = 0;
      final repository = await open(
        MockClient((request) async {
          if (request.method == 'PUT') {
            puts++;
            sending.complete();
            return reply.future;
          }
          return http.Response(jsonEncode([serverNote(1)]), 200);
        }),
      );
      await repository.synchronize(testAccount().id);
      final id = repository.notes.single.localId;
      await repository.save(id, content: 'revision ten', editorRevision: 10);
      final synchronization = repository.synchronize(testAccount().id);
      await sending.future;
      await repository.save(
        id,
        content: 'newer revision eleven',
        editorRevision: 11,
      );
      reply.complete(
        http.Response(
          jsonEncode(
            serverNote(
              1,
              etag: 'ack10',
              content: 'revision ten',
              readonly: true,
            ),
          ),
          200,
        ),
      );
      await synchronization;
      final note = repository.noteById(id)!;
      expect(note.content, 'newer revision eleven');
      expect(note.revision, 11);
      expect(note.ackRevision, 10);
      expect(note.base!.content, 'revision ten');
      expect(note.syncState, NoteSyncState.forbidden);
      expect(note.hasPendingChanges, isTrue);
      expect(puts, 1);
    },
  );

  test(
    'same-ETag readonly transition preserves base/local and exposes recovery',
    () async {
      var readonly = false;
      var puts = 0;
      final repository = await open(
        MockClient((request) async {
          if (request.method == 'PUT') {
            puts++;
            return http.Response('{}', 403);
          }
          return http.Response(
            jsonEncode([serverNote(1, readonly: readonly)]),
            200,
          );
        }),
      );
      await repository.synchronize(testAccount().id);
      final id = repository.notes.single.localId;
      await repository.save(id, content: 'durable edit', editorRevision: 2);
      readonly = true;
      await repository.synchronize(testAccount().id);
      final note = repository.noteById(id)!;
      expect(note.content, 'durable edit');
      expect(note.base!.content, 'body');
      expect(note.etag, 'abc');
      expect(note.revision, 2);
      expect(note.ackRevision, 1);
      expect(note.syncState, NoteSyncState.forbidden);
      expect(puts, 0);
    },
  );

  test(
    'readonly transition still synchronizes a favorite-only pending change',
    () async {
      var readonly = false;
      var puts = 0;
      final repository = await open(
        MockClient((request) async {
          if (request.method == 'PUT') {
            puts++;
            expect(jsonDecode(request.body), {'favorite': true});
            final returned = serverNote(1, etag: 'favorite-ack', readonly: true)
              ..['favorite'] = true;
            return http.Response(jsonEncode(returned), 200);
          }
          return http.Response(
            jsonEncode([serverNote(1, readonly: readonly)]),
            200,
          );
        }),
      );
      await repository.synchronize(testAccount().id);
      final id = repository.notes.single.localId;
      await repository.save(id, content: 'body', favorite: true);
      readonly = true;
      await repository.synchronize(testAccount().id);
      final note = repository.noteById(id)!;
      expect(note.favorite, isTrue);
      expect(note.readonly, isTrue);
      expect(note.content, 'body');
      expect(note.syncState, NoteSyncState.synced);
      expect(puts, 1);
    },
  );
}
