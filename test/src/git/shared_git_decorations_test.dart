import 'package:busymark/src/git/application/shared_git_decorations.dart';
import 'package:busymark/src/git/data/git_shared_gateway.dart';
import 'package:busystack_git_flutter/busystack_git_flutter.dart' as shared;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'authoring projection retains shared byte paths, deletions and clean refresh',
    () {
      const repo = shared.RepositoryId(
        root: '/repo',
        gitDir: '/repo/.git',
        commonDir: '/repo/.git',
        objectFormat: 'sha1',
      );
      shared.GitSnapshot status(List<shared.GitChange> changes) =>
          shared.GitSnapshot(
            repository: repo,
            token: 'same-token',
            indexToken: 'index',
            changes: changes,
            operation: const shared.RepositoryOperation(
              shared.GitOperationKind.none,
            ),
            observedAt: DateTime.utc(2026),
          );
      final source = status([
        shared.GitChange(
          path: shared.RepoPath.text('topics/named-export-presets.md'),
          index: '.',
          worktree: 'M',
        ),
        shared.GitChange(
          path: shared.RepoPath.text('topics/releasev051.md'),
          index: '.',
          worktree: 'D',
        ),
        shared.GitChange(
          path: shared.RepoPath([116, 111, 112, 105, 99, 115, 47, 255]),
          index: '.',
          worktree: 'M',
        ),
      ]);
      final projected = GitCliGateway.projectSharedStatus(source);
      final tree = busyMarkFileTreeDecorations(projected)!;
      expect(
        identical(tree, shared.GitFileTreeDecorations.fromSnapshot(source)),
        isTrue,
      );
      final topics = tree.forUri('file:///repo/topics', directory: true)!;
      expect(topics.directoryState, shared.GitDirectoryChangeState.immediate);
      expect(topics.status, isNull);
      expect(topics.immediateCount, 3);
      expect(topics.deletedCount, 1);
      expect(
        tree.forUri('file:///repo/topics/named-export-presets.md')!.status,
        shared.GitFileStatus.modified,
      );
      expect(
        projected.files.singleWhere((f) => f.deleted).repoRelativePath,
        'topics/releasev051.md',
      );
      expect(projected.source!.changes, hasLength(3));
      expect(tree.forUri('file:///other/topics'), isNull);
      expect(
        busyMarkFileTreeDecorations(
          GitCliGateway.projectSharedStatus(status([])),
        )!.forUri('file:///repo/topics'),
        isNull,
      );
      expect(busyMarkFileTreeDecorations(null), isNull);
    },
  );
}
