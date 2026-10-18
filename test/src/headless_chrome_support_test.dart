import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../support/headless_chrome.dart';

void main() {
  test(
    'browser does not inherit Flutter synthetic fonts or read-only cache',
    () {
      final parent = {
        'FONTCONFIG_FILE': '/tmp/flutter_test_fonts.owned/fonts.conf',
        'XDG_CACHE_HOME': '/owned/browser-cache',
        'DISPLAY': ':97',
      };
      expect(chromeProcessEnvironment(parent), {
        'XDG_CACHE_HOME': '/owned/browser-cache',
        'DISPLAY': ':97',
      });
      expect(parent['FONTCONFIG_FILE'], isNotNull);
    },
  );

  test('browser preserves ordinary explicit font configuration', () {
    final parent = {
      'FONTCONFIG_FILE': '/owned/custom-fonts/fonts.conf',
      'FONTCONFIG_PATH': '/owned/font-config',
    };
    expect(chromeProcessEnvironment(parent), parent);
    expect(chromeProcessEnvironment({'DISPLAY': ':97'}), {'DISPLAY': ':97'});
  });

  test('browser endpoint survives normal later process exit', () async {
    final exit = Completer<int>();
    final uri = await browserDevToolsEndpoint(
      Stream.value(
        utf8.encode(
          'DevTools listening on ws://127.0.0.1:9222/devtools/browser/test\n',
        ),
      ),
      exit.future,
    );
    expect(uri.toString(), 'ws://127.0.0.1:9222/devtools/browser/test');
    exit.complete(0);
  });

  test('early exit includes the first available browser error', () async {
    final stderr = StreamController<List<int>>();
    final exit = Completer<int>();
    final endpoint = browserDevToolsEndpoint(stderr.stream, exit.future);
    final assertion = expectLater(
      endpoint,
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'diagnostics',
          allOf(
            contains('exited 23'),
            contains('Sandbox initialization failed'),
          ),
        ),
      ),
    );
    stderr.add(utf8.encode('Sandbox initialization failed\n'));
    await Future<void>.delayed(Duration.zero);
    exit.complete(23);
    await assertion;
    await stderr.close();
  });

  test(
    'startup timeout retains bounded diagnostics and the same deadline',
    () async {
      final endpoint = browserDevToolsEndpoint(
        Stream.value(
          utf8.encode('${List.generate(25, (i) => 'line-$i').join('\n')}\n'),
        ),
        Completer<int>().future,
        timeout: const Duration(milliseconds: 10),
      );
      await expectLater(
        endpoint,
        throwsA(
          isA<TimeoutException>()
              .having(
                (error) => error.duration,
                'deadline',
                const Duration(milliseconds: 10),
              )
              .having(
                (error) => error.message,
                'bounded tail',
                allOf(isNot(contains('line-0\n')), contains('line-24')),
              ),
        ),
      );
    },
  );

  test(
    'stderr failure is reported instead of awaiting a missing endpoint',
    () async {
      await expectLater(
        browserDevToolsEndpoint(
          Stream.error(StateError('pipe unavailable')),
          Completer<int>().future,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'stderr failure',
            contains('pipe unavailable'),
          ),
        ),
      );
    },
  );
}
