import 'dart:convert';

import 'package:busymark/src/nextcloud_notes/data/notes_capabilities.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  Map<String, dynamic> response({Object? notes}) => {
    'ocs': {
      'meta': {'statuscode': 200, 'status': 'ok'},
      'data': {
        'capabilities': {
          if (notes != null) 'notes': notes,
          'future': {'newProperty': true},
        },
      },
    },
  };

  test('accepts stable baseline and ignores future capability fields', () {
    final capabilities = NotesCapabilities.fromOcsJson(
      response(
        notes: {
          'version': '6.1.0',
          'api_version': ['0.2', '1.3', '1.4', '1.8', '2.0', 10, 'future'],
          'future': true,
        },
      ),
    );
    expect(capabilities.appVersion, '6.1.0');
    expect(capabilities.apiVersion, '1.8');
  });

  for (final version in [
    '6.0.0',
    '6.0.1',
    '6.1.0',
    '6.1.2',
    null,
    '',
    'malformed',
    42,
  ]) {
    test('API 1.4 accepted independently of app version $version', () {
      final capabilities = NotesCapabilities.fromOcsJson(
        response(
          notes: {
            'version': version,
            'api_version': ['0.2', '1.3', '1.4'],
          },
        ),
      );
      expect(capabilities.apiVersion, '1.4');
    });
  }
  test('rejects missing Notes and unavailable/old API accurately', () {
    for (final notes in [
      null,
      {'version': '6.1.0'},
      {
        'api_version': ['0.2', '1.3'],
      },
      {
        'api_version': ['2.0'],
      },
      {'api_version': '1.4'},
      {
        'api_version': ['1.bad'],
      },
    ]) {
      expect(
        () => NotesCapabilities.fromOcsJson(response(notes: notes)),
        throwsA(
          isA<NextcloudCapabilityException>()
              .having(
                (e) => e.code,
                'code',
                NextcloudCapabilityFailure.unsupported,
              )
              .having(
                (e) => e.message,
                'message',
                allOf(contains('Notes API'), isNot(contains('6.1.0'))),
              ),
        ),
      );
    }
  });

  test(
    'requests OCS capabilities under prefix with proper Basic and headers',
    () async {
      final client = MockClient((request) async {
        expect(
          request.url.toString(),
          'https://cloud.example/nextcloud/ocs/v2.php/cloud/capabilities?format=json',
        );
        expect(request.followRedirects, isFalse);
        expect(request.headers['OCS-APIRequest'], 'true');
        expect(request.headers['Accept'], 'application/json');
        expect(
          request.headers['Authorization'],
          nextcloudAuthorization('Exact.Login', ' password '),
        );
        return http.Response(
          jsonEncode(
            response(
              notes: {
                'version': '6.1.0',
                'api_version': ['1.4'],
              },
            ),
          ),
          200,
        );
      });
      final result = await fetchNotesCapabilities(
        client: client,
        server: Uri.parse('https://cloud.example/nextcloud'),
        loginName: 'Exact.Login',
        appPassword: ' password ',
      );
      expect(result.apiVersion, '1.4');
    },
  );

  test(
    'authenticated redirects are rejected without following another origin',
    () async {
      var calls = 0;
      final client = MockClient((request) async {
        calls++;
        expect(request.followRedirects, isFalse);
        expect(request.url.host, 'cloud.example');
        return http.Response(
          '',
          302,
          headers: {'Location': 'https://evil.example/capabilities'},
        );
      });
      await expectLater(
        fetchNotesCapabilities(
          client: client,
          server: Uri.parse('https://cloud.example'),
          loginName: 'login',
          appPassword: 'secret',
        ),
        throwsA(isA<NextcloudCapabilityException>()),
      );
      expect(calls, 1);
    },
  );

  test(
    'revocation uses documented DELETE and is best effort on non-200',
    () async {
      for (final code in [200, 401, 403, 500, 302]) {
        final client = MockClient((request) async {
          expect(request.method, 'DELETE');
          expect(request.url.path, '/nextcloud/ocs/v2.php/core/apppassword');
          expect(request.followRedirects, isFalse);
          expect(request.headers['OCS-APIRequest'], 'true');
          return http.Response('', code);
        });
        expect(
          await revokeNextcloudAppPassword(
            client: client,
            server: Uri.parse('https://cloud.example/nextcloud'),
            loginName: 'login',
            appPassword: 'secret',
          ),
          code == 200,
        );
      }
    },
  );
}
