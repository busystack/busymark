import 'package:busystack_git_flutter/busystack_git_flutter.dart' as shared;
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Git identity and tab transitions are shared. Riverpod only bridges the
// existing BusyMark workspace/document tab store.
typedef SharedGitReview = shared.GitReview;
typedef SharedGitTabs = shared.GitReviewTabs;

final sharedGitReviewProvider =
    NotifierProvider<SharedGitReviews, Map<String, SharedGitTabs>>(
      SharedGitReviews.new,
    );

class SharedGitReviews extends Notifier<Map<String, SharedGitTabs>> {
  @override
  Map<String, SharedGitTabs> build() => {};

  void open(String workspace, SharedGitReview review) {
    final tabs = state[workspace] ?? const SharedGitTabs();
    state = {...state, workspace: tabs.open(review)};
  }

  void activate(String workspace, String id) {
    final tabs = state[workspace];
    if (tabs == null || !tabs.entries.any((entry) => entry.id == id)) return;
    state = {...state, workspace: tabs.activate(id)};
  }

  void deactivate(String workspace) {
    final tabs = state[workspace];
    if (tabs == null || tabs.activeId == null) return;
    state = {...state, workspace: tabs.deactivate()};
  }

  void close(String workspace, String id) {
    final tabs = state[workspace];
    if (tabs == null) return;
    state = {...state, workspace: tabs.close(id)};
  }
}
