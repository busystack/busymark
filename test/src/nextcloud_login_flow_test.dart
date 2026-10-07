import 'dart:async';
import 'dart:convert';

import 'package:busymark/src/nextcloud_notes/data/login_flow.dart';
import 'package:busymark/src/nextcloud_notes/data/server_uri.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('Nextcloud installation URLs', () {
    test('normalizes the root URL and preserves installation prefixes', () {
      for (final input in [
        'https://cloud.example',
        ' https://CLOUD.example/ ',
        'https://cloud.example///',
      ]) {
        expect(
          normalizeNextcloudServer(input).toString(),
          'https://cloud.example',
        );
      }
      final server = normalizeNextcloudServer(
        'https://cloud.example/nextcloud/',
      );
      expect(
        nextcloudEndpoint(server, 'index.php/login/v2').toString(),
        'https://cloud.example/nextcloud/index.php/login/v2',
      );
      expect(
        nextcloudEndpoint(
          normalizeNextcloudServer('https://localhost:8080/cloud/'),
          'ocs/v2.php/cloud/capabilities',
          queryParameters: {'format': 'json'},
        ).toString(),
        'https://localhost:8080/cloud/ocs/v2.php/cloud/capabilities?format=json',
      );
    });

    test('rejects malformed and unsafe installation URLs', () {
      for (final value in [
        '',
        'cloud.example',
        '/nextcloud',
        'ftp://cloud.example',
        'http://cloud.example',
        'http://192.168.1.2/nextcloud',
        'http://127.0.0.1:8080',
        'http://localhost:8080',
        'http://[::1]:8080',
        'https://name:secret@cloud.example',
        'https://cloud.example?q=1',
        'https://cloud.example?',
        'https://cloud.example#fragment',
        'https://cloud.example#',
        'https://cloud.example/a/../cloud',
        'https://cloud.example/%2e%2e/cloud',
        'https://cloud.example/a%2fb',
        'https://cloud.example/a\\b',
        'https://cloud.example/with space',
        'https://cloud.example/%00',
        'https://cloud.example:99999',
        'https://cloud.example:0',
      ]) {
        expect(
          () => normalizeNextcloudServer(value),
          throwsFormatException,
          reason: value,
        );
      }
    });

    test('routes cannot reset a prefix or change origin', () {
      final server = Uri.parse('https://cloud.example/nextcloud');
      for (final route in [
        '/index.php/login/v2',
        '../index.php/login/v2',
        'a/../../index.php/login/v2',
        'index.php?x=1',
        'index.php#x',
        'a\\b',
      ]) {
        expect(() => nextcloudEndpoint(server, route), throwsFormatException);
      }
    });
  });

  group('Login Flow v2', () {
    final server = Uri.parse('https://cloud.example/nextcloud');
    final started = DateTime.utc(2026, 10, 4);

    Map<String, Object?> flowJson() => {
      'poll': {'token': 'flow token+', 'endpoint': '$server/login/v2/poll'},
      'login': '$server/login/v2/flow/browser-token',
      'futureField': true,
    };

    http.Response credentials() => http.Response(
      jsonEncode({
        'server': 'https://cloud.example/nextcloud/',
        'loginName': ' exact.Login@EXAMPLE ',
        'appPassword': ' exact password ',
        'futureField': 'ignored',
      }),
      200,
    );

    test(
      'anonymous start, browser, pending poll and canonical exact success',
      () async {
        final calls = <http.Request>[];
        final opened = <Uri>[];
        var polls = 0;
        final client = MockClient((request) async {
          calls.add(request);
          expect(request.followRedirects, isFalse);
          expect(request.headers['Authorization'], isNull);
          if (request.url.path.endsWith('/login/v2')) {
            return http.Response(jsonEncode(flowJson()), 200);
          }
          expect(request.url.path, '/nextcloud/login/v2/poll');
          expect(request.bodyFields, {'token': 'flow token+'});
          return polls++ == 0 ? http.Response('', 404) : credentials();
        });
        var now = started;
        final flow = NextcloudLoginFlow(
          client: client,
          openBrowser: (uri) async {
            opened.add(uri);
            return true;
          },
          clock: () => now,
          delay: (duration) async => now = now.add(duration),
        );
        final result = await flow.authenticate(server);
        expect(calls.first.method, 'POST');
        expect(calls.first.url.path, '/nextcloud/index.php/login/v2');
        expect(calls.first.body, isEmpty);
        expect(opened.single.toString(), flowJson()['login']);
        expect(polls, 2);
        expect(result.server, server);
        expect(result.loginName, ' exact.Login@EXAMPLE ');
        expect(result.appPassword, ' exact password ');
        expect(result.toString(), isNot(contains('exact password')));
      },
    );

    test('production login rejects HTTP before network or browser', () async {
      var calls = 0;
      final flow = NextcloudLoginFlow(
        client: MockClient((_) async {
          calls++;
          return http.Response('', 200);
        }),
        openBrowser: (_) async {
          calls++;
          return true;
        },
      );
      await expectLater(
        flow.authenticate(Uri.parse('http://localhost:8080')),
        throwsFormatException,
      );
      expect(calls, 0);
    });

    test('token expires at twenty minutes without extra poll', () async {
      var now = started;
      var polls = 0;
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/login/v2')) {
          return http.Response(jsonEncode(flowJson()), 200);
        }
        polls++;
        return http.Response('', 404);
      });
      final flow = NextcloudLoginFlow(
        client: client,
        openBrowser: (_) async => true,
        clock: () => now,
        delay: (_) async => now = now.add(const Duration(minutes: 20)),
      );
      await expectLater(
        flow.authenticate(server),
        throwsA(
          isA<NextcloudLoginException>().having(
            (error) => error.code,
            'code',
            NextcloudLoginFailure.timedOut,
          ),
        ),
      );
      expect(polls, 1);
    });

    test('user can cancel while waiting without another poll', () async {
      final cancellation = NextcloudLoginCancellation();
      final delay = Completer<void>();
      var polls = 0;
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/login/v2')) {
          return http.Response(jsonEncode(flowJson()), 200);
        }
        polls++;
        cancellation.cancel();
        return http.Response('', 404);
      });
      final flow = NextcloudLoginFlow(
        client: client,
        openBrowser: (_) async => true,
        delay: (_) => delay.future,
      );
      await expectLater(
        flow.authenticate(server, cancellation: cancellation),
        throwsA(
          isA<NextcloudLoginException>().having(
            (error) => error.code,
            'code',
            NextcloudLoginFailure.cancelled,
          ),
        ),
      );
      expect(polls, 1);
    });

    test('cancel racing a success revokes the returned app password', () async {
      final cancellation = NextcloudLoginCancellation();
      var revoked = false;
      final client = MockClient((request) async {
        if (request.method == 'DELETE') {
          expect(request.url.path, '/nextcloud/ocs/v2.php/core/apppassword');
          revoked = true;
          return http.Response('', 200);
        }
        if (request.url.path.endsWith('/login/v2')) {
          return http.Response(jsonEncode(flowJson()), 200);
        }
        cancellation.cancel();
        return credentials();
      });
      final flow = NextcloudLoginFlow(
        client: client,
        openBrowser: (_) async => true,
      );
      await expectLater(
        flow.authenticate(server, cancellation: cancellation),
        throwsA(isA<NextcloudLoginException>()),
      );
      expect(revoked, isTrue);
    });

    test('failed external browser launch does not begin polling', () async {
      var requests = 0;
      final client = MockClient((request) async {
        requests++;
        return http.Response(jsonEncode(flowJson()), 200);
      });
      final flow = NextcloudLoginFlow(
        client: client,
        openBrowser: (_) async => false,
      );
      await expectLater(
        flow.authenticate(server),
        throwsA(
          isA<NextcloudLoginException>().having(
            (error) => error.code,
            'code',
            NextcloudLoginFailure.browserUnavailable,
          ),
        ),
      );
      expect(requests, 1);
    });

    test(
      'rejects malformed responses and unsafe returned flow endpoints',
      () async {
        for (final body in [
          '{}',
          'not json',
          '[]',
          jsonEncode({
            'poll': {'token': 'x'},
            'login': 'x',
          }),
          jsonEncode({
            'poll': {'token': 'x', 'endpoint': 'https://evil.example/poll'},
            'login': '$server/login',
          }),
          jsonEncode({
            'poll': {'token': 'x', 'endpoint': '$server/poll'},
            'login': 'https://name:secret@cloud.example/nextcloud/login',
          }),
        ]) {
          final flow = NextcloudLoginFlow(
            client: MockClient((_) async => http.Response(body, 200)),
            openBrowser: (_) async => true,
          );
          await expectLater(
            flow.start(server),
            throwsA(isA<NextcloudLoginException>()),
          );
        }
      },
    );

    test(
      'pending status is only 404; other status and redirects are errors',
      () async {
        for (final status in [401, 403, 423, 500, 302]) {
          final flow = NextcloudLoginFlow(
            client: MockClient(
              (request) async => request.url.path.endsWith('/login/v2')
                  ? http.Response(jsonEncode(flowJson()), 200)
                  : http.Response('secret response', status),
            ),
            openBrowser: (_) async => true,
          );
          await expectLater(
            flow.authenticate(server),
            throwsA(
              isA<NextcloudLoginException>().having(
                (error) => error.message,
                'safe diagnostic',
                isNot(contains('secret response')),
              ),
            ),
          );
        }
      },
    );

    test('malformed credentials never become an account', () async {
      for (final result in [
        <String, Object?>{},
        {
          'server': 'https://cloud.example',
          'loginName': '',
          'appPassword': 'p',
        },
        {
          'server': 'https://cloud.example',
          'loginName': 'a:b',
          'appPassword': 'p',
        },
        {
          'server': 'https://cloud.example?unsafe',
          'loginName': 'a',
          'appPassword': 'p',
        },
        {
          'server': 'https://cloud.example',
          'loginName': 'a',
          'appPassword': '',
        },
        {
          'server': 'https://cloud.example',
          'loginName': 'a',
          'appPassword': 'secret\u0000suffix',
        },
      ]) {
        final flow = NextcloudLoginFlow(
          client: MockClient(
            (request) async => request.url.path.endsWith('/login/v2')
                ? http.Response(jsonEncode(flowJson()), 200)
                : http.Response(jsonEncode(result), 200),
          ),
          openBrowser: (_) async => true,
        );
        await expectLater(
          flow.authenticate(server),
          throwsA(isA<NextcloudLoginException>()),
        );
      }
    });

    test('network failures have sanitized diagnostics', () async {
      final flow = NextcloudLoginFlow(
        client: MockClient(
          (_) async => throw http.ClientException('sensitive proxy secret'),
        ),
        openBrowser: (_) async => true,
      );
      await expectLater(
        flow.start(server),
        throwsA(
          isA<NextcloudLoginException>()
              .having(
                (error) => error.code,
                'code',
                NextcloudLoginFailure.network,
              )
              .having(
                (error) => error.toString(),
                'message',
                isNot(contains('secret')),
              ),
        ),
      );
    });
  });
}
