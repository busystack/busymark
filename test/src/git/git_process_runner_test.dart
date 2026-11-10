import 'dart:io';
import 'package:busystack_git/busystack_git.dart' as shared;

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
    final directory = await Directory.systemTemp.createTemp(
      'busymark-shared-timeouts-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final runner = _RecordingCoreRunner(directory.path);
    await runner.run(
      ['init', '-b', 'main'],
      cwd: directory.path,
      deadline: const Duration(seconds: 10),
    );
    final gateway = GitCliGateway(
      engine: shared.GitEngine(runner: runner, authorize: (_) => true),
    );
    final repository = (await gateway.detectRepository(directory.path))!;
    await gateway.status(repository);
    expect(runner.timeouts, isNotEmpty);
    expect(runner.timeouts, everyElement(greaterThan(Duration.zero)));
  });

  test('gateway classifies a missing commit author identity', () async {
    final directory = await Directory.systemTemp.createTemp(
      'busymark-shared-identity-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final runner = _RecordingCoreRunner(directory.path);
    await runner.run(
      ['init', '-b', 'main'],
      cwd: directory.path,
      deadline: const Duration(seconds: 10),
    );
    // Git can infer a usable identity from the OS account on some machines.
    // This fixture specifically exercises missing configured author identity.
    await runner.run(
      ['config', '--local', 'user.useConfigOnly', 'true'],
      cwd: directory.path,
      deadline: const Duration(seconds: 10),
    );
    await File(
      '${directory.path}/draft.md',
    ).writeAsString('Preserve this staged draft.');
    await runner.run(
      ['add', '.'],
      cwd: directory.path,
      deadline: const Duration(seconds: 10),
    );
    final gateway = GitCliGateway(
      engine: shared.GitEngine(runner: runner, authorize: (_) => true),
    );
    final repository = (await gateway.detectRepository(directory.path))!;
    await expectLater(
      gateway.commit(repository, 'Document the release'),
      throwsA(
        isA<GitFailure>()
            .having(
              (failure) => failure.code,
              'code',
              GitFailureCode.authorIdentity,
            )
            .having(
              (failure) => failure.userMessageKey,
              'userMessageKey',
              'gitErrorAuthorIdentity',
            ),
      ),
    );
    final index = await runner.run(
      ['show', ':draft.md'],
      cwd: directory.path,
      deadline: const Duration(seconds: 10),
    );
    expect(index.text, 'Preserve this staged draft.');
  });

  test('snap packages the Linux process-group launcher', () {
    final snapcraft = File('snap/snapcraft.yaml').readAsStringSync();

    expect(snapcraft, contains(RegExp(r'^\s*- util-linux$', multiLine: true)));
  });

  test('snap Git uses bundled helpers, templates, and SSH', () {
    expect(gitEnvironmentForSnap('/snap/busymark/x1'), {
      'GIT_EXEC_PATH': '/snap/busymark/x1/usr/lib/git-core',
      'GIT_TEMPLATE_DIR': '/snap/busymark/x1/usr/share/git-core/templates',
      'GIT_SSH': '/snap/busymark/x1/usr/bin/ssh',
    });
    expect(gitEnvironmentForSnap(''), isEmpty);
  });

  test('snap launcher never falls back to the confined host setsid', () async {
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
  }, skip: !Platform.isLinux);

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

class _RecordingCoreRunner implements shared.GitRunner {
  _RecordingCoreRunner(this.home);
  final String home;
  final timeouts = <Duration>[];
  final process = shared.ProcessGitRunner();
  @override
  Future<shared.GitRunResult> run(
    List<String> arguments, {
    required String cwd,
    List<int>? input,
    shared.GitCancellation? cancellation,
    Duration? deadline,
    void Function(List<int>)? onStdout,
    void Function(String)? onProgress,
    String Function(String)? redactDiagnostic,
    Map<String, String> environment = const {},
    Map<int, List<int>> byteArguments = const {},
    int? maximumBytes,
  }) {
    if (deadline != null) timeouts.add(deadline);
    return process.run(
      arguments,
      cwd: cwd,
      input: input,
      cancellation: cancellation,
      deadline: deadline,
      onStdout: onStdout,
      onProgress: onProgress,
      redactDiagnostic: redactDiagnostic,
      byteArguments: byteArguments,
      maximumBytes: maximumBytes,
      environment: {
        'HOME': home,
        'GIT_CONFIG_GLOBAL': '/dev/null',
        'GIT_CONFIG_NOSYSTEM': '1',
        ...environment,
      },
    );
  }
}
