import 'dart:io';

import 'package:busymark/src/git/data/git_cli_gateway.dart';
import 'package:busymark/src/git/domain/git_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
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
    final modified = await gateway.status(info);
    expect(modified.unstagedFiles.single.repoRelativePath, 'README.md');
    expect(
      (await gateway.diffFile(info, 'README.md', staged: false)).rawPatch,
      contains('Changed.'),
    );

    await gateway.stage(info, ['README.md']);
    expect(
      (await gateway.status(info)).stagedFiles.single.repoRelativePath,
      'README.md',
    );
    await gateway.commit(info, 'Update docs\n\nMultiline body.');
    expect((await gateway.history(info)).first.subject, 'Update docs');

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
