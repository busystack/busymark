import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:busystack_git/busystack_git.dart' as shared;

import '../../core/anchored_path_guard.dart';
import '../domain/git_models.dart';

/// BusyMark attaches Git to the opened working-tree root, never an ancestor.
/// Discovery still belongs to the controlled shared engine (including gitfiles,
/// worktrees and submodules). Use the same canonical directory identity as the
/// workspace service; neither file navigation nor the active document is input.
Future<String> requireGitWorkspaceRoot(
  String workspacePath,
  String root,
) async {
  late CanonicalPathAnchor anchor;
  try {
    anchor = await captureCanonicalDirectoryAnchor(workspacePath);
  } on AnchoredPathViolation {
    throw const shared.GitException(shared.GitErrorCode.unsafePath);
  } on FileSystemException {
    throw const shared.GitException(shared.GitErrorCode.unsafePath);
  }
  if (!p.equals(anchor.rootPath, p.normalize(root))) {
    throw GitWorkspaceRootRequired(root);
  }
  return anchor.rootPath;
}

final class GitWorkspaceRootRequired extends GitFailure {
  const GitWorkspaceRootRequired(this.repositoryRoot)
    : super(
        code: GitFailureCode.invalidPath,
        userMessageKey: 'gitWorkspaceRootRequired',
        rawMessage: repositoryRoot,
        commandName: 'discover',
      );

  final String repositoryRoot;
}
