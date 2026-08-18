import 'dart:io';

import 'package:busymark/src/git/data/git_cli_gateway.dart';
import 'package:busymark/src/git/domain/git_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('process-backed Git gateway requires workspace trust', () {
    expect(const GitCliGateway().requiresWorkspaceTrust, isTrue);
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
    await gateway.discardTracked(info, ['README.md']);
    expect(await readme.readAsString(), contains('Changed.'));

    final draft = File(p.join(root.path, 'draft.md'));
    await draft.writeAsString('# Draft\n');
    final withUntracked = await gateway.status(info);
    expect(withUntracked.untrackedFiles.single.repoRelativePath, 'draft.md');
    await gateway.discardUntracked(info, ['draft.md'], withUntracked);
    expect(await draft.exists(), isFalse);
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

  test(
    'diff APIs do not run a repository-configured textconv',
    () async {
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

      final allDiff = await fixture.gateway.diffAll(
        fixture.info,
        staged: false,
      );
      expect(allDiff.rawPatch, contains('Working tree change.'));
      expect(
        await sentinel.exists(),
        isFalse,
        reason: 'Git diffAll must disable repository textconv commands.',
      );
    },
    skip: Platform.isWindows,
  );

  test(
    'commit details do not run a repository-configured textconv',
    () async {
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
    },
    skip: Platform.isWindows,
  );
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
