import 'package:busymark/src/git/domain/git_models.dart';
import 'package:busymark/src/git/domain/git_status_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = GitStatusParser();

  test('parses clean repository status', () {
    final snapshot = parser.parsePorcelainV1Z(
      output: '## main\x00',
      repositoryInfo: _repo(),
    );

    expect(snapshot.clean, isTrue);
    expect(snapshot.repositoryInfo.currentBranch, 'main');
  });

  test('parses modified tracked file', () {
    final file = _parse(' M README.md\x00').files.single;

    expect(file.repoRelativePath, 'README.md');
    expect(file.category, GitFileStatusCategory.modified);
    expect(file.unstaged, isTrue);
    expect(file.staged, isFalse);
  });

  test('parses staged modification', () {
    final file = _parse('M  README.md\x00').files.single;

    expect(file.indexStatus, GitFileChangeStatus.modified);
    expect(file.staged, isTrue);
    expect(file.unstaged, isFalse);
  });

  test('parses unstaged modification', () {
    final file = _parse(' M README.md\x00').files.single;

    expect(file.workTreeStatus, GitFileChangeStatus.modified);
    expect(file.unstaged, isTrue);
  });

  test('parses staged and unstaged same file', () {
    final file = _parse('MM README.md\x00').files.single;

    expect(file.staged, isTrue);
    expect(file.unstaged, isTrue);
  });

  test('keeps staged addition and working-tree deletion separate', () {
    final file = _parse('AD draft.md\x00').files.single;

    expect(file.indexStatus, GitFileChangeStatus.added);
    expect(file.workTreeStatus, GitFileChangeStatus.deleted);
    expect(file.staged, isTrue);
    expect(file.unstaged, isTrue);
    expect(file.hasWorkingTreeFile, isFalse);
  });

  test('tracks rename state independently in each status column', () {
    final staged = _parse('R  new.md\x00old.md\x00').files.single;
    final unstaged = _parse(' R new.md\x00old.md\x00').files.single;

    expect(staged.hasStagedRename, isTrue);
    expect(staged.hasUnstagedRename, isFalse);
    expect(unstaged.hasStagedRename, isFalse);
    expect(unstaged.hasUnstagedRename, isTrue);
  });

  test('parses untracked file', () {
    final file = _parse('?? draft.md\x00').files.single;

    expect(file.category, GitFileStatusCategory.untracked);
    expect(file.untracked, isTrue);
  });

  test('parses deleted file', () {
    final file = _parse(' D old.md\x00').files.single;

    expect(file.category, GitFileStatusCategory.deleted);
    expect(file.deleted, isTrue);
  });

  test('parses renamed file', () {
    final file = _parse('R  new name.md\x00old name.md\x00').files.single;

    expect(file.category, GitFileStatusCategory.renamed);
    expect(file.repoRelativePath, 'new name.md');
    expect(file.originalRepoRelativePath, 'old name.md');
  });

  test('parses copied file', () {
    final file = _parse('C  copy.md\x00source.md\x00').files.single;

    expect(file.category, GitFileStatusCategory.copied);
    expect(file.copied, isTrue);
    expect(file.originalRepoRelativePath, 'source.md');
  });

  test('parses conflicted files', () {
    final snapshot = _parse('UU conflict.md\x00');
    final file = snapshot.files.single;

    expect(file.category, GitFileStatusCategory.conflicted);
    expect(file.conflicted, isTrue);
    expect(snapshot.conflictedFiles, [file]);
    expect(snapshot.repositoryInfo.hasConflicts, isTrue);
  });

  test('parses branch header and ahead behind counts', () {
    final snapshot = _parse('## main...origin/main [ahead 2, behind 3]\x00');

    expect(snapshot.repositoryInfo.currentBranch, 'main');
    expect(snapshot.repositoryInfo.upstreamBranch, 'origin/main');
    expect(snapshot.repositoryInfo.aheadCount, 2);
    expect(snapshot.repositoryInfo.behindCount, 3);
  });

  test('parses detached head header', () {
    final snapshot = _parse('## HEAD (no branch)\x00');

    expect(snapshot.repositoryInfo.currentBranch, isNull);
  });

  test('preserves spaces, unicode, quotes, and newlines in filenames', () {
    final snapshot = _parse(
      ' M dir/file with spaces.md\x00'
      ' M unicode/привет.md\x00'
      ' M quotes/"quoted".md\x00'
      ' M lines/a\nb.md\x00',
    );

    expect(
      snapshot.files.map((file) => file.repoRelativePath),
      containsAll([
        'dir/file with spaces.md',
        'unicode/привет.md',
        'quotes/"quoted".md',
        'lines/a\nb.md',
      ]),
    );
  });
}

GitStatusSnapshot _parse(String output) {
  return const GitStatusParser().parsePorcelainV1Z(
    output: output,
    repositoryInfo: _repo(),
  );
}

GitRepositoryInfo _repo() {
  return const GitRepositoryInfo(rootPath: '/repo', gitDirPath: '/repo/.git');
}
