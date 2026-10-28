import 'dart:async';
import 'package:busystack_git_flutter/busystack_git_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Draft guards are scoped to this application's window/provider container.
final busyMarkGitDismissalProvider = Provider<GitDismissalRegistry>(
  (_) => GitDismissalRegistry(),
);

/// Attached workspaces drain their message queues and persistent store before
/// this application's normal window teardown. This is scoped to one window.
final busyMarkGitDraftFlushProvider = Provider<BusyMarkGitDraftFlushRegistry>(
  (_) => BusyMarkGitDraftFlushRegistry(),
);

final class BusyMarkGitDraftFlushRegistry {
  final _flushes = <Future<void> Function(), Iterable<GitSession> Function()>{};
  final _retired = <GitSession>{};

  Future<void> _flushOwner(GitSession session) async {
    await session.flushMessageDrafts();
    final store = session.host.drafts;
    if (store is GitFlushableDraftStore) {
      await (store as GitFlushableDraftStore).flush();
    }
  }

  void _retire(GitSession session) {
    _retired.add(session);
    unawaited(
      _flushOwner(session).then<void>(
        (_) {
          if (!session.hasUnpersistedMessageDrafts) _retired.remove(session);
        },
        onError: (Object _, StackTrace _) {
          // The original message stays with its owner for review/retry. The store
          // releases its lock in finally even when a write fails.
        },
      ),
    );
  }

  void Function() register(
    Future<void> Function() flush, {
    Iterable<GitSession> Function()? sessions,
  }) {
    _flushes[flush] = sessions ?? () => const <GitSession>[];
    return () {
      final retiring =
          _flushes.remove(flush)?.call().toList() ?? <GitSession>[];
      for (final session in retiring) {
        _retire(session);
      }
    };
  }

  Iterable<GitSession> liveSessions() => {
    ..._retired,
    // A reopened worktree owns the same slots and supplies the live host.
    for (final source in List.of(_flushes.values)) ...source(),
  };

  Future<void> flush() async {
    for (final flush in List.of(_flushes.keys)) {
      if (_flushes.containsKey(flush)) await flush();
    }
    for (final session in List.of(_retired)) {
      await _flushOwner(session);
      if (!session.hasUnpersistedMessageDrafts) _retired.remove(session);
    }
  }
}
