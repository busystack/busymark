import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import '../domain/git_models.dart';

const gitCommandTimeout = Duration(minutes: 2);
const gitExecutableProbeTimeout = Duration(seconds: 5);
const _terminationGracePeriod = Duration(milliseconds: 250);
const _terminationCleanupTimeout = Duration(seconds: 1);

abstract class GitCommandRunner {
  Future<GitProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    required Duration timeout,
    required String commandName,
    Map<String, String> environment = const {},
  });
}

class GitProcessResult {
  const GitProcessResult({
    required this.executable,
    required this.arguments,
    required this.exitCode,
    required this.stdoutBytes,
    required this.stderrBytes,
  });

  final String executable;
  final List<String> arguments;
  final int exitCode;
  final List<int> stdoutBytes;
  final List<int> stderrBytes;

  String get stdoutText => utf8.decode(stdoutBytes, allowMalformed: true);
  String get stderrText => utf8.decode(stderrBytes, allowMalformed: true);

  bool get success => exitCode == 0;
}

class DartGitCommandRunner implements GitCommandRunner {
  const DartGitCommandRunner({
    this.processGroupLauncher = const GitProcessGroupLauncher(),
  });

  final GitProcessGroupLauncher processGroupLauncher;

  @override
  Future<GitProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    required Duration timeout,
    required String commandName,
    Map<String, String> environment = const {},
  }) async {
    if (timeout <= Duration.zero) {
      throw ArgumentError.value(timeout, 'timeout', 'must be positive');
    }
    final stopwatch = Stopwatch()..start();
    final launch = processGroupLauncher.resolve(executable, arguments);
    final process = await Process.start(
      launch.executable,
      launch.arguments,
      workingDirectory: workingDirectory,
      environment: {
        ...environment,
        'GIT_TERMINAL_PROMPT': '0',
        'GIT_PAGER': 'cat',
        'LC_ALL': 'C',
      },
      includeParentEnvironment: true,
      runInShell: false,
    );
    final stdoutFuture = process.stdout.expand((bytes) => bytes).toList();
    final stderrFuture = process.stderr.expand((bytes) => bytes).toList();
    final completion = _collectResult(
      process,
      executable,
      arguments,
      stdoutFuture,
      stderrFuture,
    );
    final remainingMicros =
        timeout.inMicroseconds - stopwatch.elapsedMicroseconds;
    if (remainingMicros <= 0) {
      await _terminate(process, processGroup: launch.processGroup);
      await _awaitCleanup(completion);
      throw _timeoutFailure(commandName);
    }
    try {
      return await completion.timeout(Duration(microseconds: remainingMicros));
    } on TimeoutException {
      await _terminate(process, processGroup: launch.processGroup);
      await _awaitCleanup(completion);
      throw _timeoutFailure(commandName);
    }
  }

  Future<void> _awaitCleanup(Future<GitProcessResult> completion) async {
    try {
      await completion.timeout(_terminationCleanupTimeout);
    } on Object {
      // Cleanup is bounded. The process group has already received SIGKILL.
    }
  }

  Future<GitProcessResult> _collectResult(
    Process process,
    String executable,
    List<String> arguments,
    Future<List<int>> stdoutFuture,
    Future<List<int>> stderrFuture,
  ) async {
    try {
      await process.stdin.close();
    } on Object {
      // The child may exit before its stdin pipe is closed.
    }
    final exitCode = await process.exitCode;
    return GitProcessResult(
      executable: executable,
      arguments: List.unmodifiable(arguments),
      exitCode: exitCode,
      stdoutBytes: await stdoutFuture,
      stderrBytes: await stderrFuture,
    );
  }

  Future<void> _terminate(Process process, {required bool processGroup}) async {
    _signal(process, ProcessSignal.sigterm, processGroup: processGroup);
    await Future<void>.delayed(_terminationGracePeriod);
    _signal(process, ProcessSignal.sigkill, processGroup: processGroup);
    try {
      await process.exitCode.timeout(_terminationCleanupTimeout);
    } on Object {
      // Do not let a failed reap make timeout handling unbounded.
    }
  }

  void _signal(
    Process process,
    ProcessSignal signal, {
    required bool processGroup,
  }) {
    if (processGroup) {
      try {
        if (_LinuxProcessSignals.instance.sendToGroup(process.pid, signal)) {
          return;
        }
      } on Object {
        // Fall through to terminating at least the direct child.
      }
    }
    process.kill(signal);
  }

  GitFailure _timeoutFailure(String commandName) {
    return GitFailure(
      code: GitFailureCode.commandFailed,
      userMessageKey: 'gitErrorCommandFailed',
      rawMessage: 'Git command timed out.',
      commandName: commandName,
    );
  }
}

class GitProcessGroupLauncher {
  const GitProcessGroupLauncher({this.snapRootOverride});

  final String? snapRootOverride;

  GitProcessLaunch resolve(String executable, List<String> arguments) {
    if (!Platform.isLinux) {
      return GitProcessLaunch(
        executable: executable,
        arguments: arguments,
        processGroup: false,
      );
    }

    final snapRoot = snapRootOverride ?? Platform.environment['SNAP'];
    if (snapRoot != null && snapRoot.isNotEmpty) {
      final bundledSetsid = '$snapRoot/usr/bin/setsid';
      if (File(bundledSetsid).existsSync()) {
        return GitProcessLaunch(
          executable: bundledSetsid,
          arguments: ['--wait', '--', executable, ...arguments],
          processGroup: true,
        );
      }
      // Strict snap confinement cannot execute the host's /usr/bin/setsid.
      // A malformed or older snap should retain Git support while sacrificing
      // process-group cleanup until its packaging is corrected.
      return GitProcessLaunch(
        executable: executable,
        arguments: arguments,
        processGroup: false,
      );
    }

    return GitProcessLaunch(
      executable: 'setsid',
      arguments: ['--wait', '--', executable, ...arguments],
      processGroup: true,
    );
  }
}

class GitProcessLaunch {
  const GitProcessLaunch({
    required this.executable,
    required this.arguments,
    required this.processGroup,
  });

  final String executable;
  final List<String> arguments;
  final bool processGroup;
}

typedef _KillNative = Int32 Function(Int32 pid, Int32 signal);
typedef _KillDart = int Function(int pid, int signal);

final class _LinuxProcessSignals {
  _LinuxProcessSignals()
    : _kill = DynamicLibrary.process().lookupFunction<_KillNative, _KillDart>(
        'kill',
      );

  static final instance = _LinuxProcessSignals();

  final _KillDart _kill;

  bool sendToGroup(int processGroupId, ProcessSignal signal) {
    return _kill(-processGroupId, signal.signalNumber) == 0;
  }
}
