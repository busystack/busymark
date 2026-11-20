import 'dart:io';

import 'package:busymark/src/git/data/git_shared_gateway.dart';
import 'package:busymark/src/git/domain/git_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('process-backed Git gateway requires workspace trust', () {
    expect(const GitCliGateway().requiresWorkspaceTrust, isTrue);
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
    final initialBranch = (await _git(root.path, [
      'branch',
      '--show-current',
    ])).trim();

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
    expect(status.source!.operation.unmerged, isTrue);
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

Future<bool> _gitAvailable() async {
  try {
    final result = await Process.run('git', ['--version'], runInShell: false);
    return result.exitCode == 0;
  } on Object {
    return false;
  }
}

Future<String> _git(String root, List<String> args) async {
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
  return result.stdout as String;
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
