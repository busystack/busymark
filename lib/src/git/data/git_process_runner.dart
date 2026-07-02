import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../domain/git_models.dart';

abstract class GitCommandRunner {
  Future<GitProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Duration? timeout,
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
  const DartGitCommandRunner();

  @override
  Future<GitProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Duration? timeout,
  }) async {
    final process = await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: const {
        'GIT_TERMINAL_PROMPT': '0',
        'GIT_PAGER': 'cat',
        'LC_ALL': 'C',
      },
      includeParentEnvironment: true,
      runInShell: false,
    );
    final stdoutFuture = process.stdout.expand((bytes) => bytes).toList();
    final stderrFuture = process.stderr.expand((bytes) => bytes).toList();
    final exitFuture = process.exitCode;
    final exitCode = timeout == null
        ? await exitFuture
        : await exitFuture.timeout(
            timeout,
            onTimeout: () {
              process.kill();
              throw GitFailure(
                code: GitFailureCode.commandFailed,
                userMessageKey: 'gitErrorCommandTimedOut',
                rawMessage: 'Git command timed out.',
                commandName: _commandName(arguments),
              );
            },
          );
    return GitProcessResult(
      executable: executable,
      arguments: List.unmodifiable(arguments),
      exitCode: exitCode,
      stdoutBytes: await stdoutFuture,
      stderrBytes: await stderrFuture,
    );
  }

  String _commandName(List<String> arguments) {
    final index = arguments.indexWhere((argument) => !argument.startsWith('-'));
    return index < 0 ? 'git' : arguments[index];
  }
}
