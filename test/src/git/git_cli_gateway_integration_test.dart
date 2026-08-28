import 'dart:io';

import 'package:busymark/src/git/data/git_cli_gateway.dart';
import 'package:busymark/src/git/domain/git_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('process-backed Git gateway requires workspace trust', () {
    expect(const GitCliGateway().requiresWorkspaceTrust, isTrue);
  });

  test('configures a repository author identity without terminal setup', () async {
    if (!await _gitAvailable()) {
      markTestSkipped('Git executable is unavailable.');
      return;
    }
    final root = await Directory.systemTemp.createTemp(
      'busymark-git-identity-',
    );
    addTearDown(() async {
      if (await root.exists()) {
        await root.delete(recursive: true);
      }
    });
    await _git(root.path, ['init']);
    const gateway = GitCliGateway();
    final info = await gateway.detectRepository(root.path);

    await gateway.configureAuthorIdentity(
      info!,
      name: 'BusyMark User',
      email: 'busymark@example.com',
      globally: false,
    );

    expect(
      await _gitOutput(root.path, ['config', '--local', 'user.name']),
      'BusyMark User',
    );
    expect(
      await _gitOutput(root.path, ['config', '--local', 'user.email']),
      'busymark@example.com',
    );
  });

  test('runs core workflow in a temporary Git repository', () async {
    if (!await _gitAvailable()) {
      markTestSkipped('Git executable is unavailable.');
      return;
    }
    final root = await Directory.systemTemp.createTemp('busymark-git-real-');
    addTearDown(() async {
      if (await root.exists()) {
        await root.delete(recursive: true);
      }
    });
    await _git(root.path, ['init']);
    await _git(root.path, ['config', 'user.name', 'BusyMark Test']);
    await _git(root.path, ['config', 'user.email', 'busymark@example.com']);
    final readme = File(p.join(root.path, 'README.md'));
    await readme.writeAsString('# Docs\n');
    await _git(root.path, ['add', 'README.md']);
    await _git(root.path, ['commit', '-m', 'Initial docs']);

    const gateway = GitCliGateway();
    final info = await gateway.detectRepository(root.path);
    expect(info, isNotNull);
    final initialBranch = info!.currentBranch!;
    expect((await gateway.status(info)).clean, isTrue);

    await readme.writeAsString('# Docs\n\nChanged.\n');
    final guide = File(p.join(root.path, 'guide.md'));
    await guide.writeAsString('# Guide\n');
    final modified = await gateway.status(info);
    expect(modified.unstagedFiles.single.repoRelativePath, 'README.md');
    expect(
      (await gateway.diffFile(info, 'README.md', staged: false)).rawPatch,
      contains('Changed.'),
    );

    await gateway.stage(info, ['README.md', 'guide.md']);
    expect(
      (await gateway.status(
        info,
      )).stagedFiles.map((file) => file.repoRelativePath),
      containsAll(['README.md', 'guide.md']),
    );
    await gateway.commit(info, 'Update docs\n\nMultiline body.');
    final latestCommit = (await gateway.history(info)).first;
    expect(latestCommit.subject, 'Update docs');
    final fullDetails = await gateway.commitDetails(
      info,
      latestCommit.fullHash,
    );
    expect(
      fullDetails.changedFiles.map((file) => file.newPath ?? file.oldPath),
      containsAll(['README.md', 'guide.md']),
    );
    expect(fullDetails.fileSnapshots['README.md'], contains('Changed.'));
    expect(fullDetails.fileSnapshots['guide.md'], contains('# Guide'));
    final readmeDetails = await gateway.commitDetails(
      info,
      latestCommit.fullHash,
      repoRelativePath: 'README.md',
    );
    expect(
      readmeDetails.changedFiles.map((file) => file.newPath ?? file.oldPath),
      ['README.md'],
    );
    expect(readmeDetails.fileSnapshots['README.md'], contains('Changed.'));

    await gateway.createBranch(info, 'feature/docs');
    expect(
      (await gateway.detectRepository(root.path))?.currentBranch,
      'feature/docs',
    );
    final branchesAfterCreate = await gateway.branches(info);
    expect(
      branchesAfterCreate.map((branch) => branch.name),
      containsAll([initialBranch, 'feature/docs']),
    );
    expect(
      branchesAfterCreate.every((branch) => branch.name.isNotEmpty),
      isTrue,
    );
    await gateway.switchBranch(info, initialBranch);
    expect(
      (await gateway.detectRepository(root.path))?.currentBranch,
      initialBranch,
    );

    await readme.writeAsString('# Docs\n\nDiscard me.\n');
    expect((await gateway.status(info)).unstagedFiles, isNotEmpty);
    await gateway.rollbackTracked(info, ['README.md']);
    expect(await readme.readAsString(), contains('Changed.'));

    final draft = File(p.join(root.path, 'draft.md'));
    await draft.writeAsString('# Draft\n');
    final withUntracked = await gateway.status(info);
    expect(withUntracked.untrackedFiles.single.repoRelativePath, 'draft.md');
    await gateway.discardUntracked(info, ['draft.md'], withUntracked);
    expect(await draft.exists(), isFalse);
  });

  test('status lists every non-ignored hidden untracked file', () async {
    if (!await _gitAvailable()) {
      markTestSkipped('Git executable is unavailable.');
      return;
    }
    final root = await _createRepository('busymark-git-hidden-untracked-');
    final idea = await Directory(p.join(root.path, '.idea')).create();
    await File(
      p.join(idea.path, '.gitignore'),
    ).writeAsString('/workspace.xml\n');
    await File(
      p.join(idea.path, 'workspace.xml'),
    ).writeAsString('<workspace/>\n');
    await File(p.join(idea.path, 'misc.xml')).writeAsString('<project/>\n');
    await File(p.join(root.path, 'writerside.cfg')).writeAsString('<ihp/>\n');
    final gateway = const GitCliGateway();
    final repository = (await gateway.detectRepository(root.path))!;

    final status = await gateway.status(repository);
    final paths = status.untrackedFiles
        .map((file) => file.repoRelativePath)
        .toList();

    expect(
      paths,
      containsAll(['.idea/.gitignore', '.idea/misc.xml', 'writerside.cfg']),
    );
    expect(paths, isNot(contains('.idea/workspace.xml')));
  });

  test('resets the current branch with each explicit Git reset mode', () async {
    if (!await _gitAvailable()) {
      markTestSkipped('Git executable is unavailable.');
      return;
    }
    const gateway = GitCliGateway();
    for (final mode in GitResetMode.values) {
      final root = await _createRepository('busymark-git-reset-${mode.name}-');
      final initialHash = await _gitOutput(root.path, ['rev-parse', 'HEAD']);
      final readme = File(p.join(root.path, 'README.md'));
      await readme.writeAsString('# Later\n');
      await _git(root.path, ['add', 'README.md']);
      await _git(root.path, ['commit', '-m', 'Later docs']);
      final info = (await gateway.detectRepository(root.path))!;

      await gateway.resetCurrentBranch(info, initialHash, mode);

      expect(
        await _gitOutput(root.path, ['rev-parse', 'HEAD']),
        initialHash,
        reason: '$mode must move the current branch',
      );
      final status = await gateway.status(info);
      switch (mode) {
        case GitResetMode.soft:
          expect(status.stagedFiles, hasLength(1));
          expect(status.unstagedFiles, isEmpty);
          expect(await readme.readAsString(), '# Later\n');
        case GitResetMode.mixed:
          expect(status.stagedFiles, isEmpty);
          expect(status.unstagedFiles, hasLength(1));
          expect(await readme.readAsString(), '# Later\n');
        case GitResetMode.hard || GitResetMode.keep:
          expect(status.clean, isTrue);
          expect(await readme.readAsString(), '# Docs\n');
      }
    }
  });

  test('refuses to reset while HEAD is detached', () async {
    if (!await _gitAvailable()) {
      markTestSkipped('Git executable is unavailable.');
      return;
    }
    final root = await _createRepository('busymark-git-reset-detached-');
    final initialHash = await _gitOutput(root.path, ['rev-parse', 'HEAD']);
    await _git(root.path, ['checkout', '--detach', initialHash]);
    const gateway = GitCliGateway();
    final info = (await gateway.detectRepository(root.path))!;

    await expectLater(
      gateway.resetCurrentBranch(info, initialHash, GitResetMode.hard),
      throwsA(
        isA<GitFailure>().having(
          (failure) => failure.code,
          'code',
          GitFailureCode.detachedHead,
        ),
      ),
    );

    expect(await _gitOutput(root.path, ['rev-parse', 'HEAD']), initialHash);
  });

  test('keeps staged and unstaged comparisons separate', () async {
    if (!await _gitAvailable()) {
      markTestSkipped('Git executable is unavailable.');
      return;
    }
    final root = await _createRepository('busymark-git-split-diff-');
    final readme = File(p.join(root.path, 'README.md'));
    await readme.writeAsString('# Docs\n\nStaged version.\n');
    await _git(root.path, ['add', 'README.md']);
    await readme.writeAsString('# Docs\n\nWorking-tree version.\n');

    const gateway = GitCliGateway();
    final info = (await gateway.detectRepository(root.path))!;
    final status = await gateway.status(info);
    expect(status.stagedFiles.single.repoRelativePath, 'README.md');
    expect(status.unstagedFiles.single.repoRelativePath, 'README.md');

    final staged = await gateway.diffFile(info, 'README.md', staged: true);
    final unstaged = await gateway.diffFile(info, 'README.md', staged: false);

    expect(staged.rawPatch, contains('Staged version.'));
    expect(staged.rawPatch, isNot(contains('Working-tree version.')));
    expect(staged.fileSnapshots['README.md'], contains('Staged version.'));
    expect(unstaged.rawPatch, contains('-Staged version.'));
    expect(unstaged.rawPatch, contains('+Working-tree version.'));
    expect(unstaged.rawPatch, isNot(contains('+Staged version.')));
    expect(
      unstaged.fileSnapshots['README.md'],
      contains('Working-tree version.'),
    );
  });

  test('staged rename diff and unstage preserve both paths', () async {
    if (!await _gitAvailable()) {
      markTestSkipped('Git executable is unavailable.');
      return;
    }
    final root = await _createRepository('busymark-git-staged-rename-');
    await _git(root.path, ['mv', 'README.md', 'renamed.md']);

    const gateway = GitCliGateway();
    final info = (await gateway.detectRepository(root.path))!;
    final before = await gateway.status(info);
    final rename = before.stagedFiles.single;
    expect(rename.originalRepoRelativePath, 'README.md');
    expect(rename.repoRelativePath, 'renamed.md');

    final diff = await gateway.diffFile(
      info,
      rename.repoRelativePath,
      staged: true,
      originalRepoRelativePath: rename.originalRepoRelativePath,
    );
    expect(diff.files.single.status, GitDiffFileStatus.renamed);
    expect(diff.files.single.oldPath, 'README.md');
    expect(diff.files.single.newPath, 'renamed.md');

    await gateway.unstage(info, [
      rename.originalRepoRelativePath!,
      rename.repoRelativePath,
    ]);

    expect((await gateway.status(info)).stagedFiles, isEmpty);
    final cachedDiff = await Process.run('git', [
      '-C',
      root.path,
      'diff',
      '--cached',
      '--quiet',
      '--exit-code',
    ], runInShell: false);
    expect(cachedDiff.exitCode, 0, reason: '${cachedDiff.stderr}');
  });

  test('rollback restores both sides of a staged rename to HEAD', () async {
    if (!await _gitAvailable()) {
      markTestSkipped('Git executable is unavailable.');
      return;
    }
    final root = await _createRepository('busymark-git-rollback-rename-');
    final original = File(p.join(root.path, 'README.md'));
    final renamed = File(p.join(root.path, 'renamed.md'));
    await _git(root.path, ['mv', 'README.md', 'renamed.md']);
    await renamed.writeAsString('# Changed after rename\n');

    const gateway = GitCliGateway();
    final info = (await gateway.detectRepository(root.path))!;
    final before = await gateway.status(info);
    final rename = before.stagedFiles.single;
    expect(rename.originalRepoRelativePath, 'README.md');
    expect(rename.repoRelativePath, 'renamed.md');
    expect(before.unstagedFiles.single.repoRelativePath, 'renamed.md');

    await gateway.rollbackTracked(info, [
      rename.originalRepoRelativePath!,
      rename.repoRelativePath,
    ]);

    expect((await gateway.status(info)).clean, isTrue);
    expect(await original.readAsString(), '# Docs\n');
    expect(await renamed.exists(), isFalse);
    final cachedDiff = await Process.run('git', [
      '-C',
      root.path,
      'diff',
      '--cached',
      '--quiet',
      '--exit-code',
    ], runInShell: false);
    expect(cachedDiff.exitCode, 0, reason: '${cachedDiff.stderr}');
  });

  test(
    'staged addition deleted from the working tree keeps separate diffs',
    () async {
      if (!await _gitAvailable()) {
        markTestSkipped('Git executable is unavailable.');
        return;
      }
      final root = await _createRepository('busymark-git-added-deleted-');
      final draft = File(p.join(root.path, 'draft.md'));
      await draft.writeAsString('# Draft\n\nStaged content.\n');
      await _git(root.path, ['add', 'draft.md']);
      await draft.delete();

      const gateway = GitCliGateway();
      final info = (await gateway.detectRepository(root.path))!;
      final status = await gateway.status(info);
      final file = status.files.singleWhere(
        (candidate) => candidate.repoRelativePath == 'draft.md',
      );

      expect(file.indexStatus, GitFileChangeStatus.added);
      expect(file.workTreeStatus, GitFileChangeStatus.deleted);
      expect(status.stagedFiles, contains(file));
      expect(status.unstagedFiles, contains(file));
      expect(file.hasWorkingTreeFile, isFalse);

      final staged = await gateway.diffFile(info, 'draft.md', staged: true);
      final unstaged = await gateway.diffFile(info, 'draft.md', staged: false);

      expect(staged.files.single.status, GitDiffFileStatus.added);
      expect(staged.fileSnapshots['draft.md'], contains('Staged content.'));
      expect(unstaged.files.single.status, GitDiffFileStatus.deleted);
      expect(unstaged.fileSnapshots['draft.md'], contains('Staged content.'));

      await gateway.rollbackTracked(info, ['draft.md']);

      expect((await gateway.status(info)).clean, isTrue);
      expect(await draft.exists(), isFalse);
    },
  );

  test(
    'preserves complete deleted content and restores a deleted version',
    () async {
      if (!await _gitAvailable()) {
        markTestSkipped('Git executable is unavailable.');
        return;
      }
      final root = await _createRepository('busymark-git-deleted-file-');
      final readme = File(p.join(root.path, 'README.md'));
      const gateway = GitCliGateway();
      final info = (await gateway.detectRepository(root.path))!;

      await readme.delete();
      final unstaged = await gateway.diffFile(info, 'README.md', staged: false);
      expect(unstaged.files.single.status, GitDiffFileStatus.deleted);
      expect(unstaged.fileSnapshots['README.md'], '# Docs\n');

      await _git(root.path, ['restore', 'README.md']);
      await _git(root.path, ['rm', 'README.md']);
      final staged = await gateway.diffFile(info, 'README.md', staged: true);
      expect(staged.files.single.status, GitDiffFileStatus.deleted);
      expect(staged.fileSnapshots['README.md'], '# Docs\n');
      await _git(root.path, ['commit', '-m', 'Delete docs']);
      final deletionHash = await _gitOutput(root.path, ['rev-parse', 'HEAD']);

      final commitChange = await gateway.compareFileWithParent(
        info,
        deletionHash,
        oldPath: 'README.md',
        newPath: null,
      );
      expect(commitChange.oldContent, '# Docs\n');
      expect(commitChange.newContent, '');
      expect(commitChange.diff.files.single.status, GitDiffFileStatus.deleted);
      expect(commitChange.diff.fileSnapshots['README.md'], '# Docs\n');

      await readme.writeAsString('# Recreated\n');
      await _git(root.path, ['add', 'README.md']);
      await _git(root.path, ['commit', '-m', 'Recreate docs']);
      await gateway.restoreFileFromCommit(
        info,
        deletionHash,
        historicalPath: 'README.md',
        currentPath: 'README.md',
      );

      expect(await readme.exists(), isFalse);
      final restoredStatus = await gateway.status(info);
      expect(restoredStatus.unstagedFiles.single.repoRelativePath, 'README.md');
      expect(restoredStatus.unstagedFiles.single.deleted, isTrue);
      expect(restoredStatus.stagedFiles, isEmpty);
    },
  );

  test('failed historical blob read cannot delete the working file', () async {
    if (!await _gitAvailable()) {
      markTestSkipped('Git executable is unavailable.');
      return;
    }
    final root = await _createRepository('busymark-git-missing-blob-');
    final readme = File(p.join(root.path, 'README.md'));
    const workingContent = '# Keep this working file\n';
    await readme.writeAsString(workingContent);
    final commitHash = await _gitOutput(root.path, ['rev-parse', 'HEAD']);
    final blobId = await _gitOutput(root.path, ['rev-parse', 'HEAD:README.md']);
    final objectFile = File(
      p.join(
        root.path,
        '.git',
        'objects',
        blobId.substring(0, 2),
        blobId.substring(2),
      ),
    );
    final backup = File('${objectFile.path}.busymark-test-backup');
    expect(await objectFile.exists(), isTrue);
    await objectFile.rename(backup.path);

    const gateway = GitCliGateway();
    final info = (await gateway.detectRepository(root.path))!;
    try {
      await expectLater(
        gateway.restoreFileFromCommit(
          info,
          commitHash,
          historicalPath: 'README.md',
          currentPath: 'README.md',
        ),
        throwsA(
          isA<GitFailure>().having(
            (failure) => failure.code,
            'code',
            GitFailureCode.commandFailed,
          ),
        ),
      );
      expect(await readme.exists(), isTrue);
      expect(await readme.readAsString(), workingContent);
    } finally {
      if (await backup.exists()) {
        await backup.rename(objectFile.path);
      }
    }
  });

  test(
    'constructs complete text and binary comparisons for untracked files',
    () async {
      if (!await _gitAvailable()) {
        markTestSkipped('Git executable is unavailable.');
        return;
      }
      final root = await _createRepository('busymark-git-untracked-diff-');
      final text = File(p.join(root.path, 'draft.md'));
      await text.writeAsString('# Draft\n\nComplete document.\n');
      final binary = File(p.join(root.path, 'image.bin'));
      await binary.writeAsBytes([0, 1, 2, 3, 255]);

      const gateway = GitCliGateway();
      final info = (await gateway.detectRepository(root.path))!;
      final textDiff = await gateway.diffUntrackedFile(info, 'draft.md');
      final binaryDiff = await gateway.diffUntrackedFile(info, 'image.bin');

      expect(textDiff.files.single.status, GitDiffFileStatus.added);
      expect(textDiff.files.single.deletions, 0);
      expect(textDiff.files.single.additions, 3);
      expect(textDiff.fileSnapshots['draft.md'], await text.readAsString());
      expect(
        textDiff.files.single.hunks.single.lines.every(
          (line) => line.kind == GitDiffLineKind.added,
        ),
        isTrue,
      );
      expect(binaryDiff.hasBinaryFiles, isTrue);
      expect(binaryDiff.files.single.binarySize, 5);
      expect(binaryDiff.fileSnapshots, isEmpty);
    },
  );

  test(
    'direct working-tree operations reject intermediate symlink escapes',
    () async {
      if (!await _gitAvailable()) {
        markTestSkipped('Git executable is unavailable.');
        return;
      }
      final root = await _createRepository('busymark-git-symlink-escape-');
      final outside = await Directory.systemTemp.createTemp(
        'busymark-git-symlink-outside-',
      );
      addTearDown(() async {
        if (await outside.exists()) {
          await outside.delete(recursive: true);
        }
      });
      final outsideFile = File(p.join(outside.path, 'outside.md'));
      await outsideFile.writeAsString('# Outside\n');
      await Link(p.join(root.path, 'linked')).create(outside.path);

      const gateway = GitCliGateway();
      final info = (await gateway.detectRepository(root.path))!;
      final commitHash = await _gitOutput(root.path, ['rev-parse', 'HEAD']);
      final unsafePathFailure = isA<GitFailure>().having(
        (failure) => failure.code,
        'code',
        GitFailureCode.invalidPath,
      );

      await expectLater(
        gateway.diffUntrackedFile(info, 'linked/outside.md'),
        throwsA(unsafePathFailure),
      );
      await expectLater(
        gateway.compareFileWithWorkingTree(
          info,
          commitHash,
          historicalPath: 'README.md',
          currentPath: 'linked/outside.md',
        ),
        throwsA(unsafePathFailure),
      );
      await expectLater(
        gateway.restoreFileFromCommit(
          info,
          commitHash,
          historicalPath: 'README.md',
          currentPath: 'linked/outside.md',
        ),
        throwsA(unsafePathFailure),
      );
      expect(await outsideFile.readAsString(), '# Outside\n');
    },
    skip: Platform.isWindows ? 'POSIX symlink behavior only.' : false,
  );

  test('fetch updates remote-tracking status without changing files', () async {
    if (!await _gitAvailable()) {
      markTestSkipped('Git executable is unavailable.');
      return;
    }
    final root = await _createRepository('busymark-git-fetch-');
    final remote = await Directory.systemTemp.createTemp(
      'busymark-git-fetch-remote-',
    );
    final contributor = await Directory.systemTemp.createTemp(
      'busymark-git-fetch-contributor-',
    );
    await contributor.delete();
    addTearDown(() async {
      if (await remote.exists()) {
        await remote.delete(recursive: true);
      }
      if (await contributor.exists()) {
        await contributor.delete(recursive: true);
      }
    });
    await _git(remote.path, ['init', '--bare']);
    await _git(root.path, ['remote', 'add', 'origin', remote.path]);
    final branch = (await const GitCliGateway().detectRepository(
      root.path,
    ))!.currentBranch!;
    await _git(root.path, ['push', '--set-upstream', 'origin', branch]);
    final clone = await Process.run('git', [
      'clone',
      remote.path,
      contributor.path,
    ], runInShell: false);
    expect(clone.exitCode, 0, reason: '${clone.stderr}');
    await _git(contributor.path, ['config', 'user.name', 'Contributor']);
    await _git(contributor.path, [
      'config',
      'user.email',
      'contributor@example.com',
    ]);
    await File(
      p.join(contributor.path, 'README.md'),
    ).writeAsString('# Remote update\n');
    await _git(contributor.path, ['commit', '-am', 'Remote update']);
    await _git(contributor.path, ['push']);

    const gateway = GitCliGateway();
    final info = (await gateway.detectRepository(root.path))!;
    expect((await gateway.status(info)).repositoryInfo.behindCount, 0);
    await gateway.fetch(info);
    final fetched = await gateway.status(info);

    expect(fetched.repositoryInfo.behindCount, 1);
    expect(
      await File(p.join(root.path, 'README.md')).readAsString(),
      '# Docs\n',
    );
  });

  test(
    'follows renames, compares complete versions, and restores one file',
    () async {
      if (!await _gitAvailable()) {
        markTestSkipped('Git executable is unavailable.');
        return;
      }
      final root = await _createRepository('busymark-git-file-history-');
      final oldFile = File(p.join(root.path, 'old.md'));
      await oldFile.writeAsString('# Version one\n');
      await _git(root.path, ['add', 'old.md']);
      await _git(root.path, ['commit', '-m', 'Add old document']);
      await oldFile.writeAsString('# Version two\n');
      await _git(root.path, ['commit', '-am', 'Update old document']);
      final versionTwoHash = await _gitOutput(root.path, ['rev-parse', 'HEAD']);
      await _git(root.path, ['mv', 'old.md', 'new.md']);
      await _git(root.path, ['commit', '-m', 'Rename document']);
      final renameHash = await _gitOutput(root.path, ['rev-parse', 'HEAD']);
      final newFile = File(p.join(root.path, 'new.md'));
      await newFile.writeAsString('# Version three\n');
      await _git(root.path, ['commit', '-am', 'Update renamed document']);
      await newFile.writeAsString('# Working version\n');

      const gateway = GitCliGateway();
      final info = (await gateway.detectRepository(root.path))!;
      final firstPage = await gateway.fileHistory(info, 'new.md', limit: 2);
      final secondPage = await gateway.fileHistory(
        info,
        'new.md',
        limit: 2,
        skip: 2,
      );
      final history = [...firstPage, ...secondPage];

      expect(firstPage, hasLength(2));
      expect(secondPage, isNotEmpty);
      expect(history.map((entry) => entry.pathAtCommit), contains('old.md'));
      final rename = history.singleWhere(
        (entry) => entry.commit.fullHash == renameHash,
      );
      expect(rename.oldPath, 'old.md');
      expect(rename.newPath, 'new.md');
      expect(rename.status, GitDiffFileStatus.renamed);

      final commitChange = await gateway.compareFileWithParent(
        info,
        renameHash,
        oldPath: rename.oldPath,
        newPath: rename.newPath,
      );
      expect(commitChange.oldPath, 'old.md');
      expect(commitChange.newPath, 'new.md');
      expect(commitChange.oldContent, '# Version two\n');
      expect(commitChange.newContent, '# Version two\n');
      expect(commitChange.diff.files.single.status, GitDiffFileStatus.renamed);

      final versusCurrent = await gateway.compareFileWithWorkingTree(
        info,
        versionTwoHash,
        historicalPath: 'old.md',
        currentPath: 'new.md',
      );
      expect(versusCurrent.oldContent, '# Version two\n');
      expect(versusCurrent.newContent, '# Working version\n');
      expect(versusCurrent.diff.rawPatch, contains('Working version'));

      await gateway.restoreFileFromCommit(
        info,
        versionTwoHash,
        historicalPath: 'old.md',
        currentPath: 'new.md',
      );
      expect(await newFile.readAsString(), '# Version two\n');
      final restoredStatus = await gateway.status(info);
      expect(restoredStatus.unstagedFiles.single.repoRelativePath, 'new.md');
      expect(restoredStatus.stagedFiles, isEmpty);
      expect(await oldFile.exists(), isFalse);
    },
  );

  test('compares a merge commit with its first parent', () async {
    if (!await _gitAvailable()) {
      markTestSkipped('Git executable is unavailable.');
      return;
    }
    final root = await _createRepository('busymark-git-merge-parent-');
    final readme = File(p.join(root.path, 'README.md'));
    const gateway = GitCliGateway();
    final info = (await gateway.detectRepository(root.path))!;
    final mainBranch = info.currentBranch!;

    await _git(root.path, ['switch', '-c', 'side']);
    await readme.writeAsString('# Side version\n');
    await _git(root.path, ['commit', '-am', 'Side docs']);
    await _git(root.path, ['switch', mainBranch]);
    await File(p.join(root.path, 'main.txt')).writeAsString('main\n');
    await _git(root.path, ['add', 'main.txt']);
    await _git(root.path, ['commit', '-m', 'Main work']);
    await _git(root.path, ['merge', '--no-ff', 'side', '-m', 'Merge side']);
    final mergeHash = await _gitOutput(root.path, ['rev-parse', 'HEAD']);

    final comparison = await gateway.compareFileWithParent(
      info,
      mergeHash,
      oldPath: 'README.md',
      newPath: 'README.md',
    );

    expect(comparison.oldContent, '# Docs\n');
    expect(comparison.newContent, '# Side version\n');
    expect(comparison.diff.rawPatch, contains('-# Docs'));
    expect(comparison.diff.rawPatch, contains('+# Side version'));
    final details = await gateway.commitDetails(info, mergeHash);
    expect(details.changedFiles.single.displayPath, 'README.md');
  });

  test('switch treats an option-like branch name as an operand', () async {
    if (!await _gitAvailable()) {
      markTestSkipped('Git executable is unavailable.');
      return;
    }
    final root = await _createRepository('busymark-git-switch-option-');
    await _git(root.path, ['update-ref', 'refs/heads/--detach', 'HEAD']);
    const gateway = GitCliGateway();
    final info = await gateway.detectRepository(root.path);
    expect(info, isNotNull);

    await gateway.switchBranch(info!, '--detach');

    final switched = await gateway.detectRepository(root.path);
    expect(switched?.currentBranch, '--detach');
    expect(switched?.detachedHeadCommit, isNull);
  });

  test('diff and commit details preserve C-quoted UTF-8 paths', () async {
    if (!await _gitAvailable()) {
      markTestSkipped('Git executable is unavailable.');
      return;
    }
    final root = await _createRepository('busymark-git-quoted-path-');
    await _git(root.path, ['config', 'core.quotePath', 'true']);
    const repoRelativePath = 'docs/Über "guide".md';
    final document = File(p.join(root.path, repoRelativePath));
    await document.create(recursive: true);
    await document.writeAsString('Initial.\n');
    await _git(root.path, ['add', '--', repoRelativePath]);
    await _git(root.path, ['commit', '-m', 'Add quoted path']);
    await document.writeAsString('Changed.\n');

    const gateway = GitCliGateway();
    final info = await gateway.detectRepository(root.path);
    expect(info, isNotNull);

    final workingTreeDiff = await gateway.diffAll(info!, staged: false);
    expect(workingTreeDiff.files.single.oldPath, repoRelativePath);
    expect(workingTreeDiff.files.single.newPath, repoRelativePath);

    await _git(root.path, ['add', '--', repoRelativePath]);
    await _git(root.path, ['commit', '-m', 'Update quoted path']);
    final commit = (await gateway.history(info, limit: 1)).single;
    final details = await gateway.commitDetails(info, commit.fullHash);

    expect(details.changedFiles.single.oldPath, repoRelativePath);
    expect(details.changedFiles.single.newPath, repoRelativePath);
    expect(details.fileSnapshots[repoRelativePath], 'Changed.\n');
  });

  test(
    'pushSetUpstream does not broaden an option-like branch to --all',
    () async {
      if (!await _gitAvailable()) {
        markTestSkipped('Git executable is unavailable.');
        return;
      }
      final root = await _createRepository('busymark-git-push-option-');
      final remote = await Directory.systemTemp.createTemp(
        'busymark-git-push-option-remote-',
      );
      addTearDown(() async {
        if (await remote.exists()) {
          await remote.delete(recursive: true);
        }
      });
      await _git(remote.path, ['init', '--bare']);
      await _git(root.path, ['remote', 'add', 'origin', remote.path]);
      await _git(root.path, ['update-ref', 'refs/heads/--all', 'HEAD']);
      await _git(root.path, ['update-ref', 'refs/heads/unrelated', 'HEAD']);
      const gateway = GitCliGateway();
      final info = await gateway.detectRepository(root.path);
      expect(info, isNotNull);

      await gateway.pushSetUpstream(info!, 'origin', '--all');

      expect(await _gitRefExists(remote.path, 'refs/heads/--all'), isTrue);
      expect(
        await _gitRefExists(remote.path, 'refs/heads/unrelated'),
        isFalse,
        reason: 'The branch operand must not be interpreted as git push --all.',
      );
    },
  );

  test('detects conflicted files in a temporary Git repository', () async {
    if (!await _gitAvailable()) {
      markTestSkipped('Git executable is unavailable.');
      return;
    }
    final root = await Directory.systemTemp.createTemp(
      'busymark-git-conflict-',
    );
    addTearDown(() async {
      if (await root.exists()) {
        await root.delete(recursive: true);
      }
    });
    await _git(root.path, ['init']);
    await _git(root.path, ['config', 'user.name', 'BusyMark Test']);
    await _git(root.path, ['config', 'user.email', 'busymark@example.com']);
    final readme = File(p.join(root.path, 'README.md'));
    await readme.writeAsString('base\n');
    await _git(root.path, ['add', 'README.md']);
    await _git(root.path, ['commit', '-m', 'Initial']);
    final initialBranch = (await const GitCliGateway().detectRepository(
      root.path,
    ))!.currentBranch!;

    await _git(root.path, ['switch', '-c', 'side']);
    await readme.writeAsString('side\n');
    await _git(root.path, ['commit', '-am', 'Side']);
    await _git(root.path, ['switch', initialBranch]);
    await readme.writeAsString('main\n');
    await _git(root.path, ['commit', '-am', 'Main']);
    final merge = await Process.run('git', [
      '-C',
      root.path,
      'merge',
      'side',
    ], runInShell: false);
    expect(merge.exitCode, isNot(0));

    final gateway = const GitCliGateway();
    final info = await gateway.detectRepository(root.path);
    final status = await gateway.status(info!);

    expect(status.conflictedFiles, isNotEmpty);
    expect(status.repositoryInfo.hasConflicts, isTrue);
    expect(
      status.conflictedFiles.single.category,
      GitFileStatusCategory.conflicted,
    );
  });

  test(
    'status does not run a repository-configured filesystem monitor',
    () async {
      if (!await _gitAvailable()) {
        markTestSkipped('Git executable is unavailable.');
        return;
      }
      final root = await _createRepository('busymark-git-fsmonitor-');
      final gateway = const GitCliGateway();
      final info = await gateway.detectRepository(root.path);
      expect(info, isNotNull);

      final probe = await _writeExecutableProbe(
        root,
        'fsmonitor-probe.sh',
        output: "printf 'busymark-test-token\\n'",
      );
      final sentinel = File('${probe.path}.ran');
      await _git(root.path, ['config', 'core.fsmonitor', probe.path]);

      await _git(root.path, ['status', '--porcelain']);
      expect(
        await sentinel.exists(),
        isTrue,
        reason: 'The fsmonitor probe must execute without the mitigation.',
      );
      await sentinel.delete();

      await gateway.status(info!);

      expect(
        await sentinel.exists(),
        isFalse,
        reason: 'Git status must override repository core.fsmonitor config.',
      );
    },
    skip: Platform.isWindows,
  );

  test('diff APIs do not run a repository-configured textconv', () async {
    if (!await _gitAvailable()) {
      markTestSkipped('Git executable is unavailable.');
      return;
    }
    final fixture = await _createTextconvFixture();
    final sentinel = File('${fixture.probe.path}.ran');

    await _git(fixture.root.path, ['diff', '--textconv', '--', 'README.md']);
    expect(
      await sentinel.exists(),
      isTrue,
      reason: 'The textconv probe must execute without the mitigation.',
    );
    await sentinel.delete();

    final fileDiff = await fixture.gateway.diffFile(
      fixture.info,
      'README.md',
      staged: false,
    );
    expect(fileDiff.rawPatch, contains('Working tree change.'));
    expect(
      await sentinel.exists(),
      isFalse,
      reason: 'Git diffFile must disable repository textconv commands.',
    );

    final allDiff = await fixture.gateway.diffAll(fixture.info, staged: false);
    expect(allDiff.rawPatch, contains('Working tree change.'));
    expect(
      await sentinel.exists(),
      isFalse,
      reason: 'Git diffAll must disable repository textconv commands.',
    );
  }, skip: Platform.isWindows);

  test('commit details do not run a repository-configured textconv', () async {
    if (!await _gitAvailable()) {
      markTestSkipped('Git executable is unavailable.');
      return;
    }
    final fixture = await _createTextconvFixture();
    final sentinel = File('${fixture.probe.path}.ran');

    await _git(fixture.root.path, [
      'show',
      '--textconv',
      '--format=',
      '--patch',
      fixture.commitHash,
    ]);
    expect(
      await sentinel.exists(),
      isTrue,
      reason: 'The textconv probe must execute for raw Git show.',
    );
    await sentinel.delete();

    final details = await fixture.gateway.commitDetails(
      fixture.info,
      fixture.commitHash,
    );

    expect(details.patch, contains('Committed change.'));
    expect(
      await sentinel.exists(),
      isFalse,
      reason: 'Git show must disable repository textconv commands.',
    );
  }, skip: Platform.isWindows);
}

Future<Directory> _createRepository(String prefix) async {
  final root = await Directory.systemTemp.createTemp(prefix);
  addTearDown(() async {
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  });
  await _git(root.path, ['init']);
  await _git(root.path, ['config', 'user.name', 'BusyMark Test']);
  await _git(root.path, ['config', 'user.email', 'busymark@example.com']);
  final readme = File(p.join(root.path, 'README.md'));
  await readme.writeAsString('# Docs\n');
  await _git(root.path, ['add', 'README.md']);
  await _git(root.path, ['commit', '-m', 'Initial docs']);
  return root;
}

Future<_TextconvFixture> _createTextconvFixture() async {
  final root = await Directory.systemTemp.createTemp('busymark-git-textconv-');
  addTearDown(() async {
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  });
  await _git(root.path, ['init']);
  await _git(root.path, ['config', 'user.name', 'BusyMark Test']);
  await _git(root.path, ['config', 'user.email', 'busymark@example.com']);
  await File(
    p.join(root.path, '.gitattributes'),
  ).writeAsString('*.md diff=busymarktest\n');
  final readme = File(p.join(root.path, 'README.md'));
  await readme.writeAsString('# Original\n');
  await _git(root.path, ['add', '.gitattributes', 'README.md']);
  await _git(root.path, ['commit', '-m', 'Initial docs']);
  await readme.writeAsString('# Committed change.\n');
  await _git(root.path, ['add', 'README.md']);
  await _git(root.path, ['commit', '-m', 'Update docs']);

  const gateway = GitCliGateway();
  final info = await gateway.detectRepository(root.path);
  expect(info, isNotNull);
  final commitHash = (await gateway.history(info!, limit: 1)).single.fullHash;
  final probe = await _writeExecutableProbe(
    root,
    'textconv-probe.sh',
    output: 'exec cat "\$1"',
  );
  await _git(root.path, ['config', 'diff.busymarktest.textconv', probe.path]);
  await readme.writeAsString('# Working tree change.\n');
  return _TextconvFixture(
    root: root,
    gateway: gateway,
    info: info,
    commitHash: commitHash,
    probe: probe,
  );
}

Future<File> _writeExecutableProbe(
  Directory root,
  String name, {
  required String output,
}) async {
  final probe = File(p.join(root.path, name));
  await probe.writeAsString('#!/bin/sh\n: > "\$0.ran"\n$output\n');
  final chmod = await Process.run('chmod', ['700', probe.path]);
  expect(chmod.exitCode, 0, reason: '${chmod.stderr}');
  return probe;
}

class _TextconvFixture {
  const _TextconvFixture({
    required this.root,
    required this.gateway,
    required this.info,
    required this.commitHash,
    required this.probe,
  });

  final Directory root;
  final GitCliGateway gateway;
  final GitRepositoryInfo info;
  final String commitHash;
  final File probe;
}

Future<bool> _gitAvailable() async {
  try {
    final result = await Process.run('git', ['--version'], runInShell: false);
    return result.exitCode == 0;
  } on Object {
    return false;
  }
}

Future<void> _git(String root, List<String> args) async {
  final result = await Process.run('git', [
    '-C',
    root,
    ...args,
  ], runInShell: false);
  if (result.exitCode != 0) {
    throw ProcessException(
      'git',
      ['-C', root, ...args],
      '${result.stdout}\n${result.stderr}',
      result.exitCode,
    );
  }
}

Future<String> _gitOutput(String root, List<String> args) async {
  final result = await Process.run('git', [
    '-C',
    root,
    ...args,
  ], runInShell: false);
  if (result.exitCode != 0) {
    throw ProcessException(
      'git',
      ['-C', root, ...args],
      '${result.stdout}\n${result.stderr}',
      result.exitCode,
    );
  }
  return '${result.stdout}'.trim();
}

Future<bool> _gitRefExists(String root, String refName) async {
  final result = await Process.run('git', [
    '-C',
    root,
    'show-ref',
    '--verify',
    '--quiet',
    refName,
  ], runInShell: false);
  return result.exitCode == 0;
}
