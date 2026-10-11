import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:busymark/src/nextcloud_notes/application/notes_repository.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_api_client.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_store.dart';
import 'package:busymark/src/nextcloud_notes/data/server_uri.dart';
import 'package:busymark/src/nextcloud_notes/domain/notes_models.dart';
import 'package:busymark/src/nextcloud_notes/domain/notes_retrieval.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'notes_api_test.dart' show serverNote, testAccount;

void main() {
  NotesApiClient api(Future<http.Response> Function(http.Request) handler) =>
      NotesApiClient(
        client: MockClient(handler),
        account: testAccount(
          listEtag: '"collection"',
          lastModified: 'Wed, 01 Jul 2026 00:00:00 GMT',
        ),
        appPassword: 'fixture',
      );

  test(
    'excluded identifier remains omitted across filtered pagination',
    () async {
      var requests = 0;
      final scope = NotesRetrievalScope(
        category: 'Scope',
        exclude: {'id', 'content'},
      );
      final result = await api((request) async {
        expect(request.url.queryParameters['category'], 'Scope');
        expect(request.url.queryParameters['exclude'], 'content,id');
        expect(request.headers.containsKey('If-None-Match'), isFalse);
        return requests++ == 0
            ? http.Response(
                jsonEncode([
                  {'title': 'A', 'etag': 'a'},
                ]),
                200,
                headers: {'X-Notes-Chunk-Cursor': 'next'},
              )
            : http.Response(
                jsonEncode([
                  {'title': 'B', 'etag': 'b'},
                  {'id': 1},
                ]),
                200,
              );
      }).query(scope, chunkSize: 1);
      expect(result.notes, hasLength(2));
      expect(result.notes.map((n) => n.id), everyElement(isNull));
      expect(result.notes.map((n) => n.has('content')), everyElement(isFalse));
    },
  );

  test(
    'web route observes explicit configuration without credentials or redirects',
    () async {
      for (final pretty in [true, false]) {
        final result = await api((request) async {
          expect(
            request.url.path,
            '${testAccount().server.path}/index.php/login',
          );
          expect(request.followRedirects, isFalse);
          expect(request.headers.containsKey('Authorization'), isFalse);
          return http.Response(
            '<script>var _oc_config={"modRewriteWorking":$pretty};</script>',
            200,
          );
        }).noteWebPrettyUrls();
        expect(result, pretty);
        expect(
          nextcloudNoteUrl(testAccount().server, 42, pretty: result).path,
          '${testAccount().server.path}${pretty ? '' : '/index.php'}/apps/notes/note/42',
        );
      }
      await expectLater(
        api(
          (_) async => http.Response(
            '',
            302,
            headers: {'location': 'https://evil.example'},
          ),
        ).noteWebPrettyUrls(),
        throwsA(isA<NotesException>()),
      );
    },
  );
  test(
    'optional web observation round trips without changing schema or checkpoint',
    () {
      final original = testAccount(listEtag: '"checkpoint"');
      final restored = NextcloudAccount.fromJson(
        original.copyWith(notesWebPrettyUrls: true).toJson(),
      );
      expect(restored.notesWebPrettyUrls, isTrue);
      expect(restored.listEtag, original.listEtag);
      expect(
        NextcloudAccount.fromJson(original.toJson()).notesWebPrettyUrls,
        isNull,
      );
    },
  );
  test(
    'conditional 200/304 retains complete representation and quoted validator',
    () async {
      final cached = NoteState.fromJson(serverNote(1));
      final client = api((request) async {
        expect(request.headers['If-None-Match'], '"abc"');
        return http.Response('', 304);
      });
      final result = await client.retrieve(1, cached: cached);
      expect(result, isA<NotesNotModified>());
      expect(identical((result as NotesNotModified).cached, cached), isTrue);
      final returned = await api((request) async {
        expect(request.headers.containsKey('If-None-Match'), isFalse);
        return http.Response(jsonEncode(serverNote(1)), 200);
      }).retrieve(1);
      expect(returned, isA<NotesReturned>());
    },
  );

  test(
    '304 without cache, wrong identity and malformed full response fail',
    () async {
      for (final response in [
        http.Response('', 304),
        http.Response(jsonEncode(serverNote(2)), 200),
        http.Response('{"id":1}', 200),
      ]) {
        await expectLater(
          api((_) async => response).retrieve(1),
          throwsA(isA<NotesException>()),
        );
      }
    },
  );

  test(
    'filtered projected pagination preserves parameters and omissions',
    () async {
      var calls = 0;
      final scope = NotesRetrievalScope(
        category: 'café/中文',
        exclude: {'content', 'title'},
      );
      final result = await api((request) async {
        expect(request.url.queryParameters['category'], 'café/中文');
        expect(request.url.queryParameters['exclude'], 'content,title');
        expect(request.url.queryParameters.containsKey('pruneBefore'), isFalse);
        expect(request.headers.containsKey('If-None-Match'), isFalse);
        if (calls++ == 0) {
          return http.Response(
            '[{"id":1,"category":"café/中文"}]',
            200,
            headers: {
              'X-Notes-Chunk-Cursor': 'next',
              'content-type': 'application/json; charset=utf-8',
            },
          );
        }
        expect(request.url.queryParameters['chunkCursor'], 'next');
        return http.Response('[{"id":2,"favorite":true},{"id":1}]', 200);
      }).query(scope, chunkSize: 1);
      expect(identical(result.scope, scope), isTrue);
      expect(result.notes.map((n) => n.id), [1, 2]);
      expect(result.notes.first.has('content'), isFalse);
      expect(result.notes.first.values['category'], 'café/中文');
      expect(result.notes.last.has('readonly'), isFalse);
    },
  );

  test('projected individual response retains omitted fields', () async {
    final result = await api((request) async {
      expect(request.url.queryParameters['exclude'], 'content');
      return http.Response('{"id":1,"title":"Title"}', 200);
    }).getProjection(1, NotesRetrievalScope(exclude: {'content'}));
    expect(result.has('content'), isFalse);
  });

  test(
    'query malformed fields, repeated cursor and authentication are scoped',
    () async {
      for (final response in [
        http.Response('[{"id":1,"title":null}]', 200),
        http.Response('bad', 200),
        http.Response('[]', 401),
        http.Response('[]', 200, headers: {'X-Notes-Chunk-Cursor': 'repeat'}),
      ]) {
        await expectLater(
          api((_) async => response).query(NotesRetrievalScope()),
          throwsA(
            isA<NotesException>().having(
              (e) => e.scope,
              'scope',
              NotesRequestScope.collection,
            ),
          ),
        );
      }
    },
  );

  test('portable URLs retain installation boundaries and real IDs', () {
    for (final prefix in ['', '/nextcloud', '/cloud%20space/中文']) {
      final server = normalizeNextcloudServer('https://cloud.example$prefix');
      final url = nextcloudNoteUrl(server, 42);
      expect(nextcloudNoteId(server, url.toString()), 42);
      expect(
        nextcloudNoteId(server, url.toString().replaceFirst('index.php/', '')),
        42,
      );
      expect(nextcloudNoteId(server, '$url#actual-id'), 42);
      for (final bad in [
        url.toString().replaceFirst('cloud.example', 'cloud.example.evil'),
        url.toString().replaceFirst('/apps/', '/apps-extra/'),
        '$url/more',
        url.toString().replaceFirst('/note/42', '/note/%34%32'),
        url.toString().replaceFirst('https:', 'http:'),
      ]) {
        expect(nextcloudNoteId(server, bad), isNull, reason: bad);
      }
    }
  });

  late Directory root;
  late NotesRepository repository;
  late Completer<http.Response> pending;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('notes-retrieval-');
    final store = await NotesStore.open(path: '${root.path}/notes.sqlite3');
    pending = Completer<http.Response>();
    repository = NotesRepository(
      store: store,
      clientForAccount: (account) async => NotesApiClient(
        client: MockClient((_) => pending.future),
        account: account,
        appPassword: 'fixture',
      ),
    );
    await repository.initialize();
    await repository.upsertAccount(testAccount(listEtag: '"checkpoint"'));
    final state = NoteState.fromJson(serverNote(1));
    await store.saveNote(
      NextcloudNote(
        localId: 'cached',
        accountId: testAccount().id,
        serverId: 1,
        content: state.content,
        title: state.title,
        category: state.category,
        etag: state.etag,
        base: state,
        revision: 1,
        ackRevision: 1,
      ),
    );
    // Load the durable representation through the ordinary repository path.
    await repository.dispose();
    final reopened = await NotesStore.open(path: '${root.path}/notes.sqlite3');
    repository = NotesRepository(
      store: reopened,
      clientForAccount: (account) async => NotesApiClient(
        client: MockClient((_) => pending.future),
        account: account,
        appPassword: 'fixture',
      ),
    );
    await repository.initialize();
  });
  tearDown(() async {
    await repository.dispose();
    await root.delete(recursive: true);
  });

  test(
    '304 after local edit leaves content, pending revision and checkpoint intact',
    () async {
      final request = repository.refreshLinkedNote(testAccount().id, 1);
      final saved = await repository.save('cached', content: 'new local');
      pending.complete(http.Response('', 304));
      final result = await request;
      expect(result.content, 'new local');
      expect(result.revision, saved.revision);
      expect(result.ackRevision, 1);
      expect(result.hasPendingChanges, isTrue);
      expect(
        repository.accountById(testAccount().id)!.listEtag,
        '"checkpoint"',
      );
    },
  );

  test(
    '200 during edit records conflict without replacing newer local text',
    () async {
      final request = repository.refreshLinkedNote(testAccount().id, 1);
      await repository.save('cached', content: 'new local');
      pending.complete(
        http.Response(
          jsonEncode(serverNote(1, content: 'remote', etag: 'changed')),
          200,
        ),
      );
      final result = await request;
      expect(result.content, 'new local');
      expect(result.remote!.content, 'remote');
      expect(result.syncState, NoteSyncState.conflict);
      expect(
        repository.accountById(testAccount().id)!.listEtag,
        '"checkpoint"',
      );
    },
  );

  test('cached offline navigation starts no request', () async {
    final result = await repository.linkedNote(testAccount().id, 1);
    expect(result.localId, 'cached');
    expect(pending.isCompleted, isFalse);
  });

  test('account removal rejects in-flight retrieval', () async {
    final request = repository.refreshLinkedNote(testAccount().id, 1);
    final assertion = expectLater(request, throwsA(isA<NotesException>()));
    await repository.removeAccount(testAccount().id);
    pending.complete(http.Response(jsonEncode(serverNote(1)), 200));
    await assertion;
    expect(repository.notes, isEmpty);
  });
  test(
    'scoped projection never replaces records or full-account checkpoint',
    () async {
      final request = repository.queryNotes(
        testAccount().id,
        NotesRetrievalScope(category: 'elsewhere', exclude: {'content'}),
      );
      pending.complete(http.Response('[{"id":2,"title":"Other"}]', 200));
      final result = await request;
      expect(result.notes.single.id, 2);
      expect(repository.notes.map((n) => n.localId), ['cached']);
      expect(
        repository.accountById(testAccount().id)!.listEtag,
        '"checkpoint"',
      );
    },
  );
  test('account removal rejects an in-flight scoped projection', () async {
    final request = repository.queryNotes(
      testAccount().id,
      NotesRetrievalScope(),
    );
    final assertion = expectLater(request, throwsA(isA<NotesException>()));
    await repository.removeAccount(testAccount().id);
    pending.complete(http.Response('[{"id":2}]', 200));
    await assertion;
    expect(repository.notes, isEmpty);
  });
}
