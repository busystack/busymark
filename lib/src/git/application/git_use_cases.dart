import 'package:path/path.dart' as p;

import '../domain/git_models.dart';

class GitValidation {
  const GitValidation();

  GitFailure? validateCommitMessage(String message) {
    if (message.trim().isEmpty) {
      return const GitFailure(
        code: GitFailureCode.invalidCommitMessage,
        userMessageKey: 'gitErrorEmptyCommitMessage',
        rawMessage: '',
        commandName: 'commit',
      );
    }
    return null;
  }

  GitFailure? validateHasStagedFiles(GitStatusSnapshot? snapshot) {
    if (snapshot == null || snapshot.stagedFiles.isEmpty) {
      return const GitFailure(
        code: GitFailureCode.noStagedFiles,
        userMessageKey: 'gitErrorNoStagedFiles',
        rawMessage: '',
        commandName: 'commit',
      );
    }
    return null;
  }

  GitFailure? validateBranchNameShape(String branchName) {
    final value = branchName.trim();
    if (value.isEmpty ||
        value.startsWith('-') ||
        value.contains('..') ||
        value.contains(' ') ||
        value.endsWith('.') ||
        value.endsWith('/') ||
        value.contains(RegExp(r'[\x00-\x20~^:?*\\[]'))) {
      return GitFailure(
        code: GitFailureCode.invalidBranchName,
        userMessageKey: 'gitErrorInvalidBranchName',
        rawMessage: branchName,
        commandName: 'check-ref-format',
      );
    }
    return null;
  }

  GitFailure? validateRepoRelativePaths(List<String> paths) {
    for (final path in paths) {
      if (!_safeRepoRelativePath(path)) {
        return GitFailure(
          code: GitFailureCode.invalidPath,
          userMessageKey: 'gitErrorUnsafePath',
          rawMessage: path,
          commandName: 'path-validation',
        );
      }
    }
    return null;
  }

  bool isHashAllowed(String hash, Iterable<GitCommitSummary> knownCommits) {
    return knownCommits.any((commit) => commit.fullHash == hash);
  }

  bool _safeRepoRelativePath(String path) {
    if (path.isEmpty || p.isAbsolute(path) || path.contains('\x00')) {
      return false;
    }
    final normalized = p.posix.normalize(path.replaceAll(r'\', '/'));
    return normalized != '.' &&
        !normalized.startsWith('../') &&
        normalized != '..' &&
        !normalized.startsWith('.git/') &&
        normalized != '.git';
  }
}
