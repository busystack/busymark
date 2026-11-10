import 'package:busystack_git_flutter/busystack_git_flutter.dart' as shared;

import '../domain/git_models.dart';

final _decorations = Expando<shared.GitFileTreeDecorations>();

/// Adapt authoring status data only. Classification, path aggregation and
/// presentation belong to the shared Git UI, including non-UTF-8 byte paths.
shared.GitFileTreeDecorations? busyMarkFileTreeDecorations(
  GitStatusSnapshot? snapshot,
) {
  if (snapshot == null) return null;
  final source = snapshot.source;
  if (source != null) return shared.GitFileTreeDecorations.fromSnapshot(source);
  return _decorations[snapshot] ??= shared.GitFileTreeDecorations(
    repository: shared.RepositoryId(
      root: snapshot.repositoryInfo.rootPath,
      gitDir: snapshot.repositoryInfo.gitDirPath,
      commonDir: snapshot.repositoryInfo.gitDirPath,
      objectFormat: 'sha1',
    ),
    changes: snapshot.files.map(
      (file) => shared.GitChange(
        path: shared.RepoPath.text(file.repoRelativePath),
        originalPath: file.originalRepoRelativePath == null
            ? null
            : shared.RepoPath.text(file.originalRepoRelativePath!),
        index: file.conflicted ? 'U' : _code(file.indexStatus),
        worktree: file.conflicted ? 'U' : _code(file.workTreeStatus),
      ),
    ),
  );
}

String _code(GitFileChangeStatus status) => switch (status) {
  GitFileChangeStatus.unmodified => '.',
  GitFileChangeStatus.modified => 'M',
  GitFileChangeStatus.added => 'A',
  GitFileChangeStatus.deleted => 'D',
  GitFileChangeStatus.renamed => 'R',
  GitFileChangeStatus.copied => 'C',
  GitFileChangeStatus.typeChanged => 'T',
  GitFileChangeStatus.unmerged => 'U',
  GitFileChangeStatus.untracked => '?',
  GitFileChangeStatus.ignored => '!',
  GitFileChangeStatus.unknown => 'X',
};
