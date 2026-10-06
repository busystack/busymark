import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:busymark/src/nextcloud_notes/data/notes_api_client.dart';
import 'package:busymark/src/nextcloud_notes/domain/notes_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, Object?> serverNote(
  int id, {
  String content = 'body',
  String etag = 'abc',
  bool readonly = false,
  bool error = false,
}) => {
  'id': id,
  'content': content,
  'title': 'Title',
  'category': 'Parent/Child',
  'favorite': false,
  'readonly': readonly,
  'modified': 1770000000,
  'etag': etag,
  'error': error,
  'futureField': {'ignored': true},
};

NextcloudAccount testAccount({
  String? listEtag,
  String? lastModified,
  String appVersion = '6.1.0',
}) => NextcloudAccount(
  id: 'b8ff08d8-083d-49ee-8990-e1a78774ba53',
  server: Uri.parse('https://cloud.example/nextcloud'),
  loginName: 'Exact.Login',
  appVersion: appVersion,
  listEtag: listEtag,
  lastModified: lastModified,
);

NextcloudNote testNote({
  int? serverId = 1,
  String content = 'body',
  String etag = 'abc',
}) => NextcloudNote(
  localId: 'b6b38b40-858c-42de-80a4-1315bfb3c578',
  accountId: testAccount().id,
  serverId: serverId,
  content: content,
  title: 'Title',
  category: 'Parent/Child',
  etag: etag,
);

void main() {
  for (final version in [
    '6.0.0',
    '6.0.1',
    '6.1.0',
    '6.1.4',
    '',
    'unknown',
    '6.1.0-rc1',
    '999999999999999999999.0.0',
  ]) {
    test(
      'API 1.4 uploads/downloads on $version; DELETE independently gated',
      () async {
        final deletion = ['6.1.0', '6.1.4'].contains(version);
        final account = testAccount(appVersion: version);
        expect(account.supportsAttachmentDeletion, deletion);
        final fileName = version.startsWith('6.0')
            ? 'server-random.png'
            : '.attachments.1/server.png';
        final methods = <String>[];
        final client = NotesApiClient(
          client: MockClient((request) async {
            methods.add(request.method);
            if (request.method == 'POST') {
              return http.Response(jsonEncode({'filename': fileName}), 200);
            }
            return http.Response(request.method == 'GET' ? 'bytes' : '', 200);
          }),
          account: account,
          appPassword: 'test',
        );
        final root = await Directory.systemTemp.createTemp('notes-cap-');
        try {
          expect(
            await client.uploadAttachment(1, 'x.png', Uint8List.fromList([1])),
            fileName,
          );
          final fetched = await client.fetchAttachment(
            1,
            fileName,
            destination: File('${root.path}/complete'),
          );
          expect(await fetched.readAsString(), 'bytes');
          if (deletion) {
            await client.deleteAttachment(1, fileName);
            expect(methods, ['POST', 'GET', 'DELETE']);
          } else {
            await expectLater(
              client.deleteAttachment(1, fileName),
              throwsA(
                isA<NotesException>().having(
                  (e) => e.code,
                  'code',
                  NotesFailureCode.unsupported,
                ),
              ),
            );
            expect(methods, ['POST', 'GET']);
          }
        } finally {
          await root.delete(recursive: true);
        }
      },
    );
  }

  test(
    'persisted HTTP account cannot issue an authenticated request',
    () async {
      var calls = 0;
      final account = NextcloudAccount.fromJson({
        ...testAccount().toJson(),
        'server': 'http://192.168.1.1',
      });
      final client = NotesApiClient(
        client: MockClient((request) async {
          calls++;
          return http.Response('', 200);
        }),
        account: account,
        appPassword: 'test',
      );
      await expectLater(client.get(1), throwsFormatException);
      expect(calls, 0);
    },
  );

  test(
    'pruned IDs tolerate future fields and filename URI escaping is reversible',
    () async {
      final client = NotesApiClient(
        client: MockClient(
          (_) async =>
              http.Response('[{"id":1,"futurePrunedMetadata":true}]', 200),
        ),
        account: testAccount(),
        appPassword: 'secret',
      );
      final result = await client.list();
      expect(result.ids, {1});
      expect(result.notes, isEmpty);
      expect(
        attachmentMarkdownReference('.attachments.1/photo (1)#.png'),
        '.attachments.1/photo%20%281%29%23.png',
      );
      expect(
        canonicalAttachmentReference('.attachments.1/photo%20%281%29%23.png'),
        '.attachments.1/photo (1)#.png',
      );
    },
  );
  test(
    'decodes future fields/read-only/error without exception text as content',
    () {
      expect(NoteState.fromJson(serverNote(1)).category, 'Parent/Child');
      expect(
        NoteState.fromJson(serverNote(1, readonly: true)).readonly,
        isTrue,
      );
      final unavailable = NoteState.fromJson(
        serverNote(1, error: true, content: 'Error: Exception'),
      );
      expect(unavailable.content, isEmpty);
      expect(unavailable.readonly, isTrue);
      expect(unavailable.error, isTrue);
    },
  );

  test(
    'CRUD preserves installation prefix and sends exactly quoted If-Match',
    () async {
      final requests = <http.Request>[];
      final client = NotesApiClient(
        client: MockClient((request) async {
          requests.add(request);
          return http.Response(jsonEncode(serverNote(1)), 200);
        }),
        account: testAccount(),
        appPassword: 'secret',
      );
      await client.update(testNote());
      expect(
        requests.single.url.path,
        '/nextcloud/index.php/apps/notes/api/v1/notes/1',
      );
      expect(requests.single.headers['If-Match'], '"abc"');
      expect(requests.single.followRedirects, isFalse);
      expect(requests.single.url.userInfo, isEmpty);
      expect(
        utf8.decode(
          base64Decode(requests.single.headers['Authorization']!.substring(6)),
        ),
        'Exact.Login:secret',
      );
    },
  );

  test('canonical title/category write response is adopted', () async {
    final response = serverNote(1)
      ..['title'] = 'Sanitized'
      ..['category'] = 'Safe';
    final client = NotesApiClient(
      client: MockClient((_) async => http.Response(jsonEncode(response), 200)),
      account: testAccount(),
      appPassword: 'secret',
    );
    final note = await client.update(testNote());
    expect(note.title, 'Sanitized');
    expect(note.category, 'Safe');
  });

  test('412 carries complete fresh remote conflict state', () async {
    final client = NotesApiClient(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode(serverNote(1, etag: 'new', content: 'other')),
          412,
        ),
      ),
      account: testAccount(),
      appPassword: 'secret',
    );
    await expectLater(
      client.update(testNote()),
      throwsA(
        isA<NotesException>()
            .having((e) => e.code, 'code', NotesFailureCode.conflict)
            .having((e) => e.remote?.content, 'remote', 'other'),
      ),
    );
  });

  for (final entry in {
    401: NotesFailureCode.authentication,
    403: NotesFailureCode.forbidden,
    404: NotesFailureCode.missing,
    423: NotesFailureCode.locked,
    507: NotesFailureCode.storageFull,
    500: NotesFailureCode.server,
    429: NotesFailureCode.server,
    599: NotesFailureCode.server,
  }.entries) {
    test(
      'classifies HTTP ${entry.key} preserving future-code compatibility',
      () async {
        final client = NotesApiClient(
          client: MockClient((_) async => http.Response('{}', entry.key)),
          account: testAccount(),
          appPassword: 'secret',
        );
        await expectLater(
          client.update(testNote()),
          throwsA(
            isA<NotesException>().having((e) => e.code, 'code', entry.value),
          ),
        );
      },
    );
  }

  test('never follows cross-origin authenticated redirects', () async {
    var calls = 0;
    final client = NotesApiClient(
      client: MockClient((request) async {
        calls++;
        expect(request.followRedirects, isFalse);
        return http.Response(
          '',
          302,
          headers: {'location': 'https://attacker.example/capture'},
        );
      }),
      account: testAccount(),
      appPassword: 'secret',
    );
    await expectLater(client.get(1), throwsA(isA<NotesException>()));
    expect(calls, 1);
  });

  test(
    'incremental chunk list uses server Last-Modified and final complete ids',
    () async {
      var calls = 0;
      final client = NotesApiClient(
        client: MockClient((request) async {
          calls++;
          expect(request.url.queryParameters['pruneBefore'], '1770000000');
          if (calls == 1) {
            expect(
              request.url.queryParameters.containsKey('chunkCursor'),
              isFalse,
            );
            expect(request.headers['If-None-Match'], '"previous"');
            return http.Response(
              jsonEncode([serverNote(1)]),
              200,
              headers: {
                'X-NOTES-CHUNK-CURSOR': 'opaque',
                'LAST-MODIFIED': 'Mon, 02 Feb 2026 02:40:00 GMT',
                'ETAG': '"first"',
              },
            );
          }
          expect(request.url.queryParameters['chunkCursor'], 'opaque');
          expect(request.headers.containsKey('If-None-Match'), isFalse);
          return http.Response(
            jsonEncode([
              serverNote(2),
              {'id': 1},
              {'id': 3},
            ]),
            200,
            headers: {
              'ETAG': '"final"',
              'LAST-MODIFIED': 'Mon, 02 Feb 2026 02:40:00 GMT',
            },
          );
        }),
        account: testAccount(
          listEtag: '"previous"',
          lastModified: 'Mon, 02 Feb 2026 02:40:00 GMT',
        ),
        appPassword: 'secret',
      );
      final list = await client.list(chunkSize: 1);
      expect(list.ids, {1, 2, 3});
      expect(list.notes.map((n) => n.id), [1, 2]);
      expect(list.etag, '"final"');
      expect(calls, 2);
    },
  );

  test(
    '304 returns unchanged checkpoint outcome without parsing a body',
    () async {
      final client = NotesApiClient(
        client: MockClient((_) async => http.Response('', 304)),
        account: testAccount(listEtag: '"old"'),
        appPassword: 'secret',
      );
      expect((await client.list()).notModified, isTrue);
    },
  );

  test('interrupted chunks do not return partial deletion evidence', () async {
    var calls = 0;
    final client = NotesApiClient(
      client: MockClient((_) async {
        if (++calls == 1) {
          return http.Response(
            jsonEncode([serverNote(1)]),
            200,
            headers: {'X-Notes-Chunk-Cursor': 'next'},
          );
        }
        throw http.ClientException('offline');
      }),
      account: testAccount(),
      appPassword: 'secret',
    );
    await expectLater(
      client.list(),
      throwsA(
        isA<NotesException>().having(
          (e) => e.code,
          'code',
          NotesFailureCode.network,
        ),
      ),
    );
  });

  test('attachment upload uses authoritative renamed relative path', () async {
    final client = NotesApiClient(
      client: MockClient((request) async {
        expect(
          request.url.path,
          '/nextcloud/index.php/apps/notes/api/v1.4/attachment/1',
        );
        expect(
          request.headers['content-type'],
          startsWith('multipart/form-data'),
        );
        return http.Response(
          '{"filename":".attachments.1/photo (1).png"}',
          200,
        );
      }),
      account: testAccount(),
      appPassword: 'secret',
    );
    expect(
      await client.uploadAttachment(1, 'photo.png', Uint8List.fromList([1, 2])),
      '.attachments.1/photo (1).png',
    );
  });

  test(
    'attachment upload rejects a filename outside the current note',
    () async {
      for (final filename in [
        '.attachments.2/foreign.png',
        '.attachments.1/../foreign.png',
        'https://evil.example/foreign.png',
      ]) {
        final client = NotesApiClient(
          client: MockClient(
            (_) async => http.Response(jsonEncode({'filename': filename}), 200),
          ),
          account: testAccount(),
          appPassword: 'secret',
        );
        await expectLater(
          client.uploadAttachment(1, 'photo.png', Uint8List.fromList([1])),
          throwsA(isA<NotesException>()),
        );
      }
    },
  );

  test(
    'attachment fetch rejects URLs and traversal without sending credentials',
    () async {
      var calls = 0;
      final client = NotesApiClient(
        client: MockClient((_) async {
          calls++;
          return http.Response('', 200);
        }),
        account: testAccount(),
        appPassword: 'secret',
      );
      for (final path in [
        'file:///etc/passwd',
        '/etc/passwd',
        'https://evil.example/i.png',
        '../escape',
        '%2e%2e/escape',
        'a\\b',
        'a/%2e%2e/b',
        '.attachments.2/foreign.png',
        '.attachments%2e2/foreign.png',
      ]) {
        await expectLater(
          client.fetchAttachment(
            1,
            path,
            destination: File('/unused/attachment'),
          ),
          throwsA(isA<NotesException>()),
        );
      }
      expect(calls, 0);
    },
  );

  test(
    'attachment delete gates app version independently of API 1.4',
    () async {
      var calls = 0;
      final client = NotesApiClient(
        client: MockClient((_) async {
          calls++;
          return http.Response('[]', 200);
        }),
        account: testAccount(appVersion: '6.0.2'),
        appPassword: 'secret',
      );
      await expectLater(
        client.deleteAttachment(1, '.attachments.1/a.png'),
        throwsA(
          isA<NotesException>().having(
            (e) => e.code,
            'code',
            NotesFailureCode.unsupported,
          ),
        ),
      );
      expect(calls, 0);
    },
  );

  test('create does not publish private staging references', () async {
    final client = NotesApiClient(
      client: MockClient((request) async {
        expect(request.body, isNot(contains('busymark-attachment:')));
        return http.Response(jsonEncode(serverNote(1)), 200);
      }),
      account: testAccount(),
      appPassword: 'secret',
    );
    await client.create(
      testNote(
        serverId: null,
        content: '![image](busymark-attachment:account:note:asset)',
      ),
    );
  });

  test(
    'update never publishes an unresolved private attachment reference',
    () async {
      var calls = 0;
      final client = NotesApiClient(
        client: MockClient((_) async {
          calls++;
          return http.Response('{}', 200);
        }),
        account: testAccount(),
        appPassword: 'secret',
      );
      await expectLater(
        client.update(
          testNote(content: '![orphan](busymark-attachment:missing)'),
        ),
        throwsA(isA<NotesException>()),
      );
      expect(calls, 0);
    },
  );

  test(
    'private namespace text in prose and code is preserved by create and update',
    () async {
      const content =
          'Literal busymark-attachment:example:note:asset\n\n'
          '`![example](busymark-attachment:example:note:asset)`\n\n'
          '```markdown\n![example](busymark-attachment:example:note:asset)\n```';
      final methods = <String>[];
      final client = NotesApiClient(
        client: MockClient((request) async {
          methods.add(request.method);
          expect(jsonDecode(request.body)['content'], content);
          return http.Response(
            jsonEncode(serverNote(1, content: content)),
            200,
          );
        }),
        account: testAccount(),
        appPassword: 'secret',
      );
      expect(
        (await client.create(
          testNote(serverId: null, content: content),
        )).content,
        content,
      );
      expect(
        (await client.update(testNote(content: content))).content,
        content,
      );
      expect(methods, ['POST', 'PUT']);
    },
  );
}
