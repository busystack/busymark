import 'package:busystack_git/busystack_git.dart' as shared;
import 'dart:convert';
import 'dart:io';

import '../domain/git_models.dart';

const gitCommandTimeout = Duration(minutes: 2);
const gitExecutableProbeTimeout = Duration(seconds: 5);
const gitCommandOutputLimitBytes = 32 * 1024 * 1024;

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

/// Compatibility boundary for application probes and existing runner regressions.
/// Process creation, binary capture and process-group cleanup are shared.
class DartGitCommandRunner implements GitCommandRunner {
  const DartGitCommandRunner({
    this.processGroupLauncher = const GitProcessGroupLauncher(),
    this.maxOutputBytes = gitCommandOutputLimitBytes,
  });
  final GitProcessGroupLauncher processGroupLauncher;
  final int maxOutputBytes;
  @override
  Future<GitProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    required Duration timeout,
    required String commandName,
    Map<String, String> environment = const {},
  }) async {
    if (timeout <= Duration.zero) throw ArgumentError.value(timeout, 'timeout');
    try {
      final result =
          await shared.ProcessGitRunner(
            executable: executable,
            maximumOutputBytes: maxOutputBytes,
          ).run(
            arguments,
            cwd: workingDirectory ?? Directory.current.path,
            deadline: timeout,
            environment: {
              ...gitEnvironmentForSnap(processGroupLauncher.snapRootOverride),
              ...environment,
            },
          );
      return GitProcessResult(
        executable: executable,
        arguments: List.unmodifiable(arguments),
        exitCode: result.exitCode,
        stdoutBytes: result.stdout,
        stderrBytes: result.stderr,
      );
    } on shared.GitException catch (error) {
      throw GitFailure(
        code: GitFailureCode.commandFailed,
        userMessageKey: 'gitErrorCommandFailed',
        commandName: commandName,
        rawMessage: error.code == shared.GitErrorCode.outputLimit
            ? 'Git command output exceeded the $maxOutputBytes-byte capture limit.'
            : error.code == shared.GitErrorCode.deadline
            ? 'Git command timed out.'
            : error.diagnostic,
      );
    }
  }
}

Map<String, String> gitEnvironmentForSnap([String? snapRootOverride]) {
  final snapRoot = snapRootOverride ?? Platform.environment['SNAP'];
  if (snapRoot == null || snapRoot.isEmpty) {
    return const {};
  }
  return {
    'GIT_EXEC_PATH': '$snapRoot/usr/lib/git-core',
    'GIT_TEMPLATE_DIR': '$snapRoot/usr/share/git-core/templates',
    'GIT_SSH': '$snapRoot/usr/bin/ssh',
  };
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
      // Prefer the packaged launcher whenever this binary runs from a Snap. A
      // malformed package should retain Git support while sacrificing
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
