import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:busymark/src/git/data/git_shared_gateway.dart';
import 'package:busymark/src/git/domain/git_models.dart';
import 'package:busystack_git/busystack_git.dart' as shared;
import 'package:flutter_test/flutter_test.dart';
// The source-complete sibling layout supplies the same isolated Git fixture
// used by the engine; application tests never inherit the user's Git config.
import '../../../../busystack_git/test/support/repository_fixture.dart';

void main() {
  late RepositoryFixture f;
  setUp(() async => f = await RepositoryFixture.create());
  tearDown(() async => f.close());
  test(
    'authoring status never turns an escaped byte filename into a mutation path',
    () async {
      final path = shared.RepoPath([255]);
      final raw = File.fromRawPath(
        Uint8List.fromList([...utf8.encode('${f.root.path}/'), ...path.bytes]),
      );
      await raw.writeAsBytes([1, 2, 3]);
      final literal = File('${f.root.path}/${path.display}');
      await literal.writeAsString('literal filename');
      final gateway = GitCliGateway(engine: f.engine);
      final repository = (await gateway.detectRepository(f.root.path))!;
      final status = await gateway.status(repository);
      expect((await f.engine.status(f.repository)).changes, hasLength(2));
      expect(status.files.single.repoRelativePath, path.display);
      expect(status.unrepresentedPathCount, 1);
      await gateway.stage(repository, [status.files.single.repoRelativePath]);
      expect(await f.git(['ls-files', '-z']), '${path.display}\u0000');
      expect(await raw.readAsBytes(), [1, 2, 3]);
      await literal.delete();
      await f.git(['rm', '--cached', '--', path.display]);
      final onlyRaw = await gateway.status(repository);
      expect(onlyRaw.files, isEmpty);
      expect(onlyRaw.unrepresentedPathCount, 1);
      expect(onlyRaw.clean, isFalse);
    },
  );
  test(
    'a replacement Git directory cannot reuse an authoring repository handle',
    () async {
      await f.commit('a.md', utf8.encode('retained bytes'), 'original');
      final gateway = GitCliGateway(engine: f.engine);
      final reviewed = (await gateway.detectRepository(f.root.path))!;
      expect(reviewed.identityKey, f.repository.key);
      final saved = await Directory(
        f.repository.gitDir,
      ).rename('${f.directory.path}/saved-git');
      await f.git(['init', '-b', 'replacement']);
      await expectLater(
        gateway.stage(reviewed, ['a.md']),
        throwsA(isA<GitFailure>()),
      );
      expect(await f.git(['ls-files']), isEmpty);
      expect(
        await File('${f.root.path}/a.md').readAsString(),
        'retained bytes',
      );
      expect(await saved.exists(), isTrue);
    },
  );
}
