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

import 'notes_api_test.dart' show testAccount, serverNote;

void main() {
  test(
    'API version headers are observed on scoped errors and attachment streams',
    () async {
      final observed = <String>[];
      final directory = await Directory.systemTemp.createTemp('notes-headers-');
      addTearDown(() => directory.delete(recursive: true));
      final client = NotesApiClient(
        account: testAccount(),
        appPassword: 'fixture',
        onApiVersions: (value) async => observed.add(value),
        client: MockClient((request) async {
          expect(request.headers['authorization'], startsWith('Basic '));
          if (request.url.path.endsWith('/v1/settings')) {
            expect(request.method, 'GET');
            return http.Response(
              '{}',
              404,
              headers: {'X-NoTeS-Api-Versions': '1.4'},
            );
          }
          expect(
            request.url.path,
            '/nextcloud/index.php/apps/notes/api/v1.4/attachment/1',
          );
          expect(request.url.queryParameters['path'], '.attachments.1/a.png');
          return http.Response.bytes(
            [9],
            200,
            headers: {'X-NOTES-API-VERSIONS': '1.5'},
          );
        }),
      );
      await expectLater(
        client.getSettings(),
        throwsA(
          isA<NotesException>().having(
            (e) => e.scope,
            'scope',
            NotesRequestScope.settings,
          ),
        ),
      );
      await client.fetchAttachment(
        1,
        '.attachments.1/a.png',
        destination: File('${directory.path}/cached'),
      );
      expect(observed, ['1.4', '1.5']);
    },
  );
  test(
    'collection 404 preserves clean, edited and local-only work across restart',
    () async {
      final directory = await Directory.systemTemp.createTemp('notes-m1-');
      addTearDown(() => directory.delete(recursive: true));
      var failing = false;
      var writes = 0;
      final transport = MockClient((request) async {
        expect(
          request.url.path,
          startsWith('/nextcloud/index.php/apps/notes/api/v1/notes'),
        );
        if (failing) return http.Response('{}', 404);
        if (request.method == 'GET') {
          return http.Response(jsonEncode([serverNote(1)]), 200);
        }
        writes++;
        final body = jsonDecode(request.body) as Map;
        return http.Response(
          jsonEncode({
            ...serverNote(request.method == 'POST' ? 2 : 1),
            ...body,
            'etag': 'written',
          }),
          200,
        );
      });
      Future<NotesRepository> open() async {
        final repository = NotesRepository(
          store: await NotesStore.open(path: '${directory.path}/notes.sqlite3'),
          clientForAccount: (a) async => NotesApiClient(
            client: transport,
            account: a,
            appPassword: 'test',
          ),
        );
        await repository.initialize();
        return repository;
      }

      var repository = await open();
      await repository.upsertAccount(testAccount());
      await repository.synchronize(testAccount().id);
      final remoteId = repository.notes.single.localId;
      failing = true;
      await repository.synchronize(testAccount().id);
      expect(repository.noteById(remoteId)!.syncState, NoteSyncState.synced);
      await repository.save(remoteId, content: 'offline edit');
      final draft = await repository.create(
        testAccount().id,
        content: 'offline draft',
      );
      await repository.synchronize(testAccount().id);
      expect(
        repository.noteById(remoteId)!.syncState,
        isNot(NoteSyncState.deletedRemotely),
      );
      expect(
        repository.noteById(draft.localId)!.syncState,
        isNot(NoteSyncState.deletedRemotely),
      );
      await repository.dispose();
      repository = await open();
      failing = false;
      await repository.synchronize(testAccount().id);
      expect(writes, 2);
      expect(repository.noteById(remoteId)!.content, 'offline edit');
      expect(repository.noteById(draft.localId)!.serverId, 2);
      await repository.dispose();
    },
  );

  for (final name in [
    'é 日本.png',
    'literal%.png',
    'space # (1).png',
    '%2F.png',
    '%2e%2e.png',
  ]) {
    test('raw attachment round trip: $name', () async {
      final path = '.attachments.1/$name';
      expect(isSafeAttachmentPath(path), isTrue);
      expect(isNoteAttachmentPath(1, path), isTrue);
      expect(
        canonicalAttachmentReference(attachmentMarkdownReference(path)),
        path,
      );
      final directory = await Directory.systemTemp.createTemp('notes-uri-');
      addTearDown(() => directory.delete(recursive: true));
      final client = NotesApiClient(
        client: MockClient((request) async {
          expect(
            request.url.path,
            '/nextcloud/index.php/apps/notes/api/v1.4/attachment/1',
          );
          expect(request.url.queryParameters['path'], path);
          return http.Response.bytes([1, 2, 3], 200);
        }),
        account: testAccount(),
        appPassword: 'test',
      );
      final file = await client.fetchAttachment(
        1,
        path,
        destination: File('${directory.path}/complete'),
      );
      expect(await file.readAsBytes(), Uint8List.fromList([1, 2, 3]));
    });
  }
  test('encoded traversal and malformed destinations remain rejected', () {
    for (final path in [
      '%2e%2e/a.png',
      '%2Fetc/passwd',
      '%00.png',
      'bad%.png',
    ]) {
      expect(canonicalAttachmentReference(path), isNull);
    }
  });
}
