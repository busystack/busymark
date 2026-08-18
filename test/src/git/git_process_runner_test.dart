import 'dart:io';

import 'package:busymark/src/git/data/git_cli_gateway.dart';
import 'package:busymark/src/git/data/git_executable_locator.dart';
import 'package:busymark/src/git/data/git_process_runner.dart';
import 'package:busymark/src/git/domain/git_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'runner closes child stdin so commands waiting for EOF can finish',
    () async {
      final result = await const DartGitCommandRunner().run(
        '/bin/sh',
        const ['-c', 'IFS= read -r ignored; printf stdin-closed'],
        timeout: const Duration(seconds: 1),
        commandName: 'sh',
      );

      expect(result.exitCode, 0);
      expect(result.stdoutText, 'stdin-closed');
    },
    skip: Platform.isWindows,
  );

  test(
    'runner terminates commands that exceed the combined output limit',
    () async {
      const runner = DartGitCommandRunner(maxOutputBytes: 128);

      await expectLater(
        runner.run(
          '/bin/sh',
          const ['-c', 'printf %080d 0; printf %080d 0 >&2; sleep 10'],
          timeout: const Duration(seconds: 5),
          commandName: 'noisy-command',
        ),
        throwsA(
          isA<GitFailure>()
              .having(
                (failure) => failure.commandName,
                'commandName',
                'noisy-command',
              )
              .having(
                (failure) => failure.rawMessage,
                'rawMessage',
                contains('128-byte'),
              ),
        ),
      );
    },
    skip: Platform.isWindows,
  );

  test('normal gateway commands always receive a finite timeout', () async {
    final runner = _RecordingGitRunner();
    final gateway = GitCliGateway(
      runner: runner,
      locator: const _AvailableGitLocator(),
    );

    await gateway.status(
      const GitRepositoryInfo(
        rootPath: '/repo',
        gitDirPath: '/repo/.git',
        currentBranch: 'main',
      ),
    );

    expect(runner.timeouts, isNotEmpty);
    expect(runner.timeouts, everyElement(greaterThan(Duration.zero)));
  });

  test('snap packages the Linux process-group launcher', () {
    final snapcraft = File('snap/snapcraft.yaml').readAsStringSync();

    expect(snapcraft, contains(RegExp(r'^\s*- util-linux$', multiLine: true)));
  });

  test(
    'snap launcher never falls back to the confined host setsid',
    () async {
      final snapRoot = await Directory.systemTemp.createTemp(
        'busymark-snap-launcher-',
      );
      addTearDown(() => snapRoot.delete(recursive: true));
      final launcher = GitProcessGroupLauncher(snapRootOverride: snapRoot.path);

      final direct = launcher.resolve('/snap/busymark/usr/bin/git', const [
        '--version',
      ]);
      expect(direct.executable, '/snap/busymark/usr/bin/git');
      expect(direct.arguments, const ['--version']);
      expect(direct.processGroup, isFalse);

      final bundledSetsid = File('${snapRoot.path}/usr/bin/setsid');
      await bundledSetsid.create(recursive: true);
      final wrapped = launcher.resolve('/snap/busymark/usr/bin/git', const [
        '--version',
      ]);
      expect(wrapped.executable, bundledSetsid.path);
      expect(wrapped.arguments, const [
        '--wait',
        '--',
        '/snap/busymark/usr/bin/git',
        '--version',
      ]);
      expect(wrapped.processGroup, isTrue);
    },
    skip: !Platform.isLinux,
  );

  test('Git locator preserves process launcher failures', () async {
    final availability = await const GitExecutableLocator(
      runner: _PermissionDeniedGitRunner(),
      candidatePaths: ['/snap/busymark/current/usr/bin/git'],
    ).locate();

    expect(availability.available, isFalse);
    expect(
      availability.unavailableReason,
      allOf(
        contains('/snap/busymark/current/usr/bin/git'),
        contains('setsid'),
        contains('Permission denied'),
      ),
    );
  });

  test('Git locator preserves a failed version probe result', () async {
    final availability = await const GitExecutableLocator(
      runner: _FailedVersionGitRunner(),
      candidatePaths: ['/snap/busymark/current/usr/bin/git'],
    ).locate();

    expect(availability.available, isFalse);
    expect(availability.unavailableReason, contains('exited with code 126'));
    expect(availability.unavailableReason, contains('loader failure'));
  });

  test(
    'Git locator reports not found for a genuinely missing command',
    () async {
      final availability = await const GitExecutableLocator(
        runner: _MissingGitRunner(),
        candidatePaths: ['git'],
      ).locate();

      expect(availability.available, isFalse);
      expect(availability.unavailableReason, 'Git executable was not found.');
    },
  );

  test(
    'runner terminates descendant processes when a command times out',
    () async {
      final temp = await Directory.systemTemp.createTemp(
        'busymark-git-runner-timeout-',
      );
      addTearDown(() async {
        if (await temp.exists()) {
          await temp.delete(recursive: true);
        }
      });
      final sentinel = File('${temp.path}/descendant-survived');
      final started = File('${temp.path}/descendant-started');

      await expectLater(
        const DartGitCommandRunner().run(
          '/bin/sh',
          [
            '-c',
            '(trap "" TERM; sleep 1; printf survived > "\$1") & '
                'printf started > "\$2"; wait',
            'sh',
            sentinel.path,
            started.path,
          ],
          timeout: const Duration(milliseconds: 200),
          commandName: 'sh',
        ),
        throwsA(
          isA<GitFailure>().having(
            (failure) => failure.userMessageKey,
            'userMessageKey',
            'gitErrorCommandFailed',
          ),
        ),
      );
      expect(await started.exists(), isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 1100));
      expect(
        await sentinel.exists(),
        isFalse,
        reason: 'A timed-out Git command must not leave descendants running.',
      );
    },
    skip: !Platform.isLinux,
  );

  test(
    'timeout covers descendants that outlive the direct child and hold stdio',
    () async {
      final temp = await Directory.systemTemp.createTemp(
        'busymark-git-runner-stdio-timeout-',
      );
      addTearDown(() async {
        if (await temp.exists()) {
          await temp.delete(recursive: true);
        }
      });
      final sentinel = File('${temp.path}/descendant-survived');

      await expectLater(
        const DartGitCommandRunner().run(
          '/bin/sh',
          [
            '-c',
            '(trap "" TERM; sleep 1; printf survived > "\$1") &',
            'sh',
            sentinel.path,
          ],
          timeout: const Duration(milliseconds: 200),
          commandName: 'sh',
        ),
        throwsA(
          isA<GitFailure>()
              .having(
                (failure) => failure.userMessageKey,
                'userMessageKey',
                'gitErrorCommandFailed',
              )
              .having((failure) => failure.commandName, 'commandName', 'sh'),
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 1100));
      expect(await sentinel.exists(), isFalse);
    },
    skip: !Platform.isLinux,
  );
}

class _AvailableGitLocator extends GitExecutableLocator {
  const _AvailableGitLocator();

  @override
  Future<GitAvailability> locate() async => const GitAvailability(
    available: true,
    executablePath: 'git',
    version: '2.43.0',
  );
}

class _RecordingGitRunner implements GitCommandRunner {
  final timeouts = <Duration>[];

  @override
  Future<GitProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    required Duration timeout,
    required String commandName,
    Map<String, String> environment = const {},
  }) async {
    timeouts.add(timeout);
    final stdout = arguments.contains('status')
        ? '## main\n'.codeUnits
        : <int>[];
    return GitProcessResult(
      executable: executable,
      arguments: arguments,
      exitCode: 0,
      stdoutBytes: stdout,
      stderrBytes: const [],
    );
  }
}

class _PermissionDeniedGitRunner implements GitCommandRunner {
  const _PermissionDeniedGitRunner();

  @override
  Future<GitProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    required Duration timeout,
    required String commandName,
    Map<String, String> environment = const {},
  }) async {
    throw ProcessException('setsid', const [], 'Permission denied', 13);
  }
}

class _FailedVersionGitRunner implements GitCommandRunner {
  const _FailedVersionGitRunner();

  @override
  Future<GitProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    required Duration timeout,
    required String commandName,
    Map<String, String> environment = const {},
  }) async {
    return GitProcessResult(
      executable: executable,
      arguments: arguments,
      exitCode: 126,
      stdoutBytes: const [],
      stderrBytes: 'loader failure'.codeUnits,
    );
  }
}

class _MissingGitRunner implements GitCommandRunner {
  const _MissingGitRunner();

  @override
  Future<GitProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    required Duration timeout,
    required String commandName,
    Map<String, String> environment = const {},
  }) async {
    throw ProcessException('git', const [], 'No such file or directory', 2);
  }
}
