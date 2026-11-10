import 'package:busymark/src/git/application/shared_git_tabs.dart';
import 'package:busystack_git_flutter/busystack_git_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _repo = RepositoryId(
  root: '/one',
  gitDir: '/one/.git',
  commonDir: '/one/.git',
  objectFormat: 'sha1',
);
SharedGitReview _review(
  ContentVersion left,
  ContentVersion right, {
  RepositoryId repo = _repo,
  String path = 'file.md',
  String? old,
  String token = 'review',
}) => SharedGitReview(
  repo,
  comparison: GitComparison(
    RepoPath.text(path),
    left,
    right,
    leftPath: old == null ? null : RepoPath.text(old),
  ),
  reviewToken: token,
);
void main() {
  test(
    'normal tabs distinguish repository, side, paths, revision, parent and review context',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final tabs = container.read(sharedGitReviewProvider.notifier);
      final a = ContentVersion(ContentKind.commit, revision: GitOid('a' * 40)),
          b = ContentVersion(ContentKind.commit, revision: GitOid('b' * 40)),
          c = ContentVersion(ContentKind.commit, revision: GitOid('c' * 40));
      final entries = [
        _review(a, const ContentVersion.index()),
        _review(const ContentVersion.index(), const ContentVersion.working()),
        _review(a, b),
        _review(a, c),
        _review(b, c),
        _review(a, c, old: 'old.md'),
        _review(a, const ContentVersion.index(), token: 'new review'),
        _review(
          a,
          c,
          repo: const RepositoryId(
            root: '/two',
            gitDir: '/two/.git',
            commonDir: '/two/.git',
            objectFormat: 'sha1',
          ),
        ),
      ];
      for (final entry in entries) {
        tabs.open('workspace', entry);
      }
      expect(
        container.read(sharedGitReviewProvider)['workspace']!.entries.length,
        entries.length,
      );
      tabs.open('workspace', entries.first);
      final live = container.read(sharedGitReviewProvider)['workspace']!;
      expect(live.active, same(entries.first));
      expect(live.entries.length, entries.length);
      tabs.deactivate('workspace');
      expect(
        container.read(sharedGitReviewProvider)['workspace']!.active,
        isNull,
      );
      tabs.activate('workspace', entries[3].id);
      expect(
        container.read(sharedGitReviewProvider)['workspace']!.active,
        same(entries[3]),
      );
      tabs.close('workspace', entries[3].id);
      expect(
        container.read(sharedGitReviewProvider)['workspace']!.entries.length,
        entries.length - 1,
      );
      expect(entries[4].comparison.left.revision, b.revision);
    },
  );
  test(
    'another workspace and a later sidebar context cannot replace an existing tab',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final tabs = container.read(sharedGitReviewProvider.notifier);
      final first = _review(
        const ContentVersion.index(),
        const ContentVersion.working(),
      );
      tabs.open('one', first);
      tabs.open(
        'two',
        _review(const ContentVersion.absent(), const ContentVersion.working()),
      );
      expect(
        container.read(sharedGitReviewProvider)['one']!.active,
        same(first),
      );
      tabs.open(
        'one',
        _review(const ContentVersion.index(), const ContentVersion.working()),
      );
      expect(
        container.read(sharedGitReviewProvider)['one']!.active,
        same(first),
      );
    },
  );
}
