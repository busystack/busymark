import 'dart:io';

import '../domain/git_models.dart';
import 'git_process_runner.dart';

class GitExecutableLocator {
  const GitExecutableLocator({this.runner = const DartGitCommandRunner()});

  final GitCommandRunner runner;

  Future<GitAvailability> locate() async {
    for (final candidate in _candidates()) {
      try {
        final result = await runner.run(candidate, const ['--version']);
        if (!result.success) {
          continue;
        }
        final version = _parseVersion(result.stdoutText);
        if (version == null) {
          return GitAvailability(
            available: false,
            executablePath: candidate,
            unsupportedReason: result.stdoutText.trim(),
          );
        }
        if (!_supportsSwitchAndRestore(version)) {
          return GitAvailability(
            available: false,
            executablePath: candidate,
            version: version.raw,
            unsupportedReason: 'Git 2.23 or newer is required.',
          );
        }
        return GitAvailability(
          available: true,
          executablePath: candidate,
          version: version.raw,
        );
      } on Object {
        continue;
      }
    }
    return const GitAvailability.unavailable('Git executable was not found.');
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
