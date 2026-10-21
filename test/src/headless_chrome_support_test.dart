import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/headless_chrome.dart';

void main() {
  test(
    'browser profile survives launcher exit until its writer retires',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'browser-retire-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final gate = File('${directory.path}/release');
      expect((await Process.run('mkfifo', [gate.path])).exitCode, 0);
      final ready = File('${directory.path}/ready');
      final written = File('${directory.path}/written');
      final launcher = File('${directory.path}/browser');
      await launcher.writeAsString('''#!/bin/sh
for arg do
  case "\$arg" in --user-data-dir=*) profile=\${arg#*=};; esac
done
mkdir -p "\$profile"
(
  echo "\$profile" > '${ready.path}'
  read -r release < '${gate.path}'
  echo complete > "\$profile/late-write"
  cp "\$profile/late-write" '${written.path}'
) &
echo 'fixture launcher exited before DevTools' >&2
exit 23
''');
      expect((await Process.run('chmod', ['700', launcher.path])).exitCode, 0);
      var settled = false;
      final evaluation = evaluateInChrome(
        '${directory.path}/document.html',
        'true',
        browserExecutable: launcher.path,
      );
      final assertion = expectLater(
        evaluation.whenComplete(() => settled = true),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'launcher diagnostics',
            contains('fixture launcher exited before DevTools'),
          ),
        ),
      );
      final clock = Stopwatch()..start();
      while (!await ready.exists()) {
        if (clock.elapsed > const Duration(seconds: 5)) {
          fail('Browser writer did not reach its release gate');
        }
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      final profile = Directory((await ready.readAsString()).trim());
      expect(settled, isFalse);
      expect(await profile.exists(), isTrue);
      await gate.writeAsString('release\n');
      await assertion;
      expect(await written.readAsString(), 'complete\n');
      expect(await profile.parent.exists(), isFalse);
    },
    skip: !Platform.isLinux,
  );

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
