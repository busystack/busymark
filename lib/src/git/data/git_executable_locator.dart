import 'dart:io';

import '../domain/git_models.dart';
import 'git_process_runner.dart';

class GitExecutableLocator {
  const GitExecutableLocator({
    this.runner = const DartGitCommandRunner(),
    this.candidatePaths,
  });

  final GitCommandRunner runner;
  final List<String>? candidatePaths;

  Future<GitAvailability> locate() async {
    String? probeFailure;
    for (final candidate in candidatePaths ?? _candidates()) {
      try {
        final result = await runner.run(
          candidate,
          const ['--version'],
          timeout: gitExecutableProbeTimeout,
          commandName: 'git',
        );
        if (!result.success) {
          probeFailure ??= _probeResultFailure(candidate, result);
          continue;
        }
        final version = _parseVersion(result.stdoutText);
        if (version == null) {
          final detail = result.stdoutText.trim().isNotEmpty
              ? result.stdoutText.trim()
              : result.stderrText.trim();
          return GitAvailability(
            available: false,
            executablePath: candidate,
            unavailableReason:
                'Git at "$candidate" returned an unrecognized version'
                '${detail.isEmpty ? '.' : ': $detail'}',
          );
        }
        if (!_supportsSwitchAndRestore(version)) {
          return GitAvailability(
            available: false,
            executablePath: candidate,
            version: version.raw,
            unavailableReason: 'Git 2.23 or newer is required.',
          );
        }
        return GitAvailability(
          available: true,
          executablePath: candidate,
          version: version.raw,
        );
      } on Object catch (error) {
        probeFailure ??= _probeExceptionFailure(candidate, error);
        continue;
      }
    }
    return GitAvailability.unavailable(
      probeFailure ?? 'Git executable was not found.',
    );
  }

  String _probeResultFailure(String candidate, GitProcessResult result) {
    final detail = result.stderrText.trim().isNotEmpty
        ? result.stderrText.trim()
        : result.stdoutText.trim();
    return 'Git at "$candidate" exited with code ${result.exitCode} while '
        'checking its version${detail.isEmpty ? '.' : ': $detail'}';
  }

  String? _probeExceptionFailure(String candidate, Object error) {
    if (error is ProcessException) {
      if (error.errorCode == 2 && !File(candidate).existsSync()) {
        return null;
      }
      final launcher = error.executable.isEmpty ? candidate : error.executable;
      final errorCode = error.errorCode == 0 ? '' : ' (${error.errorCode})';
      return 'Git was found at "$candidate", but "$launcher" could not be '
          'started: ${error.message}$errorCode.';
    }
    if (error is GitFailure) {
      return 'Git probe for "$candidate" failed: ${error.rawMessage}';
    }
    return 'Git probe for "$candidate" failed: $error';
  }

  Iterable<String> _candidates() sync* {
    final snap = Platform.environment['SNAP'];
    if (snap != null && snap.isNotEmpty) {
      final bundled = '$snap/usr/bin/git';
      if (File(bundled).existsSync()) {
        yield bundled;
      }
    }
    final seen = <String>{};
    for (final directory in (Platform.environment['PATH'] ?? '').split(':')) {
      if (directory.isEmpty) {
        continue;
      }
      final candidate = '$directory/git';
      if (seen.add(candidate) && File(candidate).existsSync()) {
        yield candidate;
      }
    }
    if (seen.add('git')) {
      yield 'git';
    }
  }

  _GitVersion? _parseVersion(String output) {
    final match = RegExp(r'git version (\d+)\.(\d+)\.(\d+)').firstMatch(output);
    if (match == null) {
      return null;
    }
    return _GitVersion(
      raw: match.group(0)!.replaceFirst('git version ', ''),
      major: int.parse(match.group(1)!),
      minor: int.parse(match.group(2)!),
      patch: int.parse(match.group(3)!),
    );
  }

  bool _supportsSwitchAndRestore(_GitVersion version) {
    if (version.major > 2) {
      return true;
    }
    if (version.major < 2) {
      return false;
    }
    return version.minor >= 23;
  }
}

class _GitVersion {
  const _GitVersion({
    required this.raw,
    required this.major,
    required this.minor,
    required this.patch,
  });

  final String raw;
  final int major;
  final int minor;
  final int patch;
}
