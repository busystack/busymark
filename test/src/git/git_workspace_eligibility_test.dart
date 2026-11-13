import 'dart:convert';
import 'dart:io';

import 'package:busymark/src/git/application/git_workspace_eligibility.dart';
import 'package:busymark/src/git/data/git_shared_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../busystack_git/test/support/repository_fixture.dart';

void main() {
  late RepositoryFixture fixture;
  setUp(() async => fixture = await RepositoryFixture.create());
  tearDown(() async => fixture.close());

  test(
    'root and equivalent spellings accepted; independently opened descendant rejected',
    () async {
      await fixture.commit('docs/a.md', utf8.encode('one\n'), 'initial');
      final gateway = GitCliGateway(engine: fixture.engine);
      final root = fixture.repository.root;
      expect(
        (await gateway.detectRepository(root))!.identityKey,
        fixture.repository.key,
      );
      expect((await gateway.detectRepository('$root/docs/..'))!.rootPath, root);
      final alias = Link('${fixture.directory.path}/alias');
      await alias.create(root);
      expect((await gateway.detectRepository(alias.path))!.rootPath, root);
      await expectLater(
        gateway.detectRepository('$root/docs'),
        throwsA(
          isA<GitWorkspaceRootRequired>().having(
            (e) => e.repositoryRoot,
            'root',
            root,
          ),
        ),
      );
      // Discovery remains unchanged for other hosts, including BusyFiles.
      expect(
        (await fixture.engine.discover('$root/docs'))!.key,
        fixture.repository.key,
      );
      expect(await File('$root/docs/.git').exists(), isFalse);
      expect(await File('$root/docs/a.md').readAsString(), 'one\n');
    },
  );

  test(
    'gitfile worktree and submodule roots use their own identities',
    () async {
      await fixture.commit('a.md', utf8.encode('one\n'), 'initial');
      final worktree = '${fixture.directory.path}/linked';
      await fixture.git(['worktree', 'add', '-b', 'linked', worktree]);
      final gateway = GitCliGateway(engine: fixture.engine);
      final linked = (await gateway.detectRepository(worktree))!;
      expect(await File('$worktree/.git').exists(), isTrue);
      expect(linked.rootPath, worktree);
      expect(linked.identityKey, isNot(fixture.repository.key));
      await fixture.git([
        '-c',
        'protocol.file.allow=always',
        'submodule',
        'add',
        fixture.root.path,
        'module',
      ]);
      final module = (await gateway.detectRepository(
        '${fixture.root.path}/module',
      ))!;
      expect(await File('${module.rootPath}/.git').exists(), isTrue);
      expect(module.rootPath, '${fixture.root.path}/module');
      expect(module.identityKey, isNot(fixture.repository.key));
      expect(module.identityKey, isNot(linked.identityKey));
    },
  );

  test('bare metadata directory has no eligible working-tree root', () async {
    final path = '${fixture.directory.path}/bare.git';
    await fixture.git(['init', '--bare', path]);
    final discovered = (await fixture.engine.discover(path))!;
    expect(discovered.bare, isTrue);
    await expectLater(
      GitCliGateway(engine: fixture.engine).detectRepository(path),
      throwsA(isA<GitWorkspaceRootRequired>()),
    );
  });
  test('unborn root accepted; ordinary folder remains uninitialized', () async {
    final gateway = GitCliGateway(engine: fixture.engine);
    expect(
      (await gateway.detectRepository(fixture.root.path))!.rootPath,
      fixture.root.path,
    );
    final empty = await Directory(
      '${fixture.directory.path}/ordinary',
    ).create();
    expect(await gateway.detectRepository(empty.path), isNull);
    expect(await Directory('${empty.path}/.git').exists(), isFalse);
  });
}
