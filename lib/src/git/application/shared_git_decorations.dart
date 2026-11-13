import 'package:busystack_git_flutter/busystack_git_flutter.dart' as shared;
import 'package:path/path.dart' as p;

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
    changes: snapshot.files.map((file) => _change(snapshot, file)).nonNulls,
  );
}

shared.GitChange? _change(GitStatusSnapshot snapshot, GitFileStatus file) {
  // The authoring gateway supplies both forms. Never decorate a local row from
  // a mismatched absolute path; retain the browser's existing scope boundary.
  final root = snapshot.repositoryInfo.rootPath;
  if (!p.equals(file.absolutePath, p.join(root, file.repoRelativePath))) {
    return null;
  }
  try {
    return shared.GitChange(
      path: shared.RepoPath.text(file.repoRelativePath),
      originalPath: file.originalRepoRelativePath == null
          ? null
          : shared.RepoPath.text(file.originalRepoRelativePath!),
      index: file.conflicted ? 'U' : _code(file.indexStatus),
      worktree: file.conflicted ? 'U' : _code(file.workTreeStatus),
    );
  } on ArgumentError {
    return null;
  }
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
