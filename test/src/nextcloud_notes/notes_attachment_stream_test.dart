import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:busymark/src/assets/asset_limits.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_api_client.dart';
import 'package:busymark/src/nextcloud_notes/domain/notes_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'notes_api_test.dart' show testAccount;

class _StreamingClient extends http.BaseClient {
  _StreamingClient(this.respond);
  final http.StreamedResponse Function(http.BaseRequest) respond;
  int calls = 0;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    calls++;
    expect(request.followRedirects, isFalse);
    expect(request.url.host, 'cloud.example');
    expect(request.headers['Authorization'], startsWith('Basic '));
    return respond(request);
  }
}

void main() {
  late Directory root;
  late File destination;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('notes-download-test-');
    destination = File('${root.path}/complete');
  });
  tearDown(() async => root.delete(recursive: true));
  NotesApiClient api(_StreamingClient client) => NotesApiClient(
    client: client,
    account: testAccount(),
    appPassword: 'test-only',
  );

  for (final length in [null, 3, 0]) {
    test(
      'streams attachment with content length $length including empty',
      () async {
        final chunks = length == 0
            ? <List<int>>[]
            : [
                [1],
                [2, 3],
              ];
        final client = _StreamingClient(
          (_) => http.StreamedResponse(
            Stream.fromIterable(chunks),
            200,
            headers: {if (length != null) 'Content-Length': '$length'},
          ),
        );
        final file = await api(
          client,
        ).fetchAttachment(1, 'flat.png', destination: destination);
        expect(await file.readAsBytes(), length == 0 ? isEmpty : [1, 2, 3]);
        expect(await root.list().length, 1);
        expect((await file.stat()).mode & 0x1ff, 0x180);
      },
    );
  }

  test('rejects oversized advertised length before consuming body', () async {
    var emitted = 0;
    Stream<List<int>> body() async* {
      for (var i = 0; i < 200; i++) {
        emitted++;
        yield [1];
      }
    }

    final client = _StreamingClient(
      (_) => http.StreamedResponse(
        body(),
        200,
        headers: {'Content-Length': '${maximumManagedAssetBytes + 1}'},
      ),
    );
    await expectLater(
      api(client).fetchAttachment(1, 'x', destination: destination),
      throwsA(
        isA<NotesException>().having(
          (e) => e.code,
          'code',
          NotesFailureCode.unsupported,
        ),
      ),
    );
    expect(emitted, lessThan(2));
    expect(await root.list().length, 0);
  });

  for (final advertised in [null, '1']) {
    test(
      'counts bytes beyond limit with absent/dishonest length $advertised',
      () async {
        final chunk = Uint8List(1024 * 1024);
        var emitted = 0;
        Stream<List<int>> body() async* {
          for (var i = 0; i < 120; i++) {
            emitted++;
            yield chunk;
          }
        }

        final client = _StreamingClient(
          (_) => http.StreamedResponse(
            body(),
            200,
            headers: {if (advertised != null) 'Content-Length': advertised},
          ),
        );
        await expectLater(
          api(client).fetchAttachment(1, 'x', destination: destination),
          throwsA(
            isA<NotesException>().having(
              (e) => e.code,
              'code',
              NotesFailureCode.unsupported,
            ),
          ),
        );
        expect(emitted, lessThan(120));
        expect(await root.list().length, 0);
      },
    );
  }

  for (final failure in ['network', 'truncated', 'dishonest', 'cancel']) {
    test('$failure leaves neither valid attachment nor partial file', () async {
      final cancel = NotesDownloadCancellation();
      Stream<List<int>> body() async* {
        yield [1, 2];
        if (failure == 'network') throw const SocketException('interrupted');
        if (failure == 'cancel') {
          cancel.cancel();
          // The cancellation must interrupt a stalled stream as well.
          await cancel.whenCancelled;
          yield [3];
        }
      }

      final client = _StreamingClient(
        (_) => http.StreamedResponse(
          body(),
          200,
          headers: {
            if (failure == 'truncated') 'Content-Length': '10',
            if (failure == 'dishonest') 'Content-Length': '1',
          },
        ),
      );
      await expectLater(
        api(client).fetchAttachment(
          1,
          'x',
          destination: destination,
          cancellation: cancel,
        ),
        throwsA(isA<NotesException>()),
      );
      expect(await root.list().length, 0);
    });
  }

  test('cancellation before request makes no HTTP call', () async {
    final cancel = NotesDownloadCancellation()..cancel();
    final client = _StreamingClient(
      (_) => http.StreamedResponse(const Stream.empty(), 200),
    );
    await expectLater(
      api(
        client,
      ).fetchAttachment(1, 'x', destination: destination, cancellation: cancel),
      throwsA(isA<NotesException>()),
    );
    expect(client.calls, 0);
  });

  test(
    'authenticated attachment redirect never follows another origin',
    () async {
      final client = _StreamingClient(
        (_) => http.StreamedResponse(
          const Stream.empty(),
          302,
          headers: {'Location': 'https://evil.example/x'},
        ),
      );
      await expectLater(
        api(client).fetchAttachment(1, 'x', destination: destination),
        throwsA(
          isA<NotesException>().having(
            (e) => e.code,
            'code',
            NotesFailureCode.authentication,
          ),
        ),
      );
      expect(client.calls, 1);
      expect(await root.list().length, 0);
    },
  );

  test('symlink destination remains untouched', () async {
    final target = File('${root.path}/existing')..writeAsStringSync('original');
    await Link(destination.path).create(target.path);
    final client = _StreamingClient(
      (_) => http.StreamedResponse(Stream.value([1]), 200),
    );
    await expectLater(
      api(client).fetchAttachment(1, 'x', destination: destination),
      throwsA(isA<NotesException>()),
    );
    expect(await target.readAsString(), 'original');
  });
}
