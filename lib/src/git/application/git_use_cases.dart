import 'package:path/path.dart' as p;

import '../domain/git_models.dart';

class GitValidation {
  const GitValidation();

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
