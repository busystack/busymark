import 'dart:convert';
import 'package:busystack_git_flutter/busystack_git_flutter.dart' as shared;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A captured review context. Endpoints and file navigation never follow the
/// sidebar's later selection. Mutable content retains the reviewed snapshot ID.
final class SharedGitReview {
  const SharedGitReview(
    this.repository, {
    required this.comparison,
    this.reviewToken,
    this.reviewedFiles = const [],
  });
  final shared.RepositoryId repository;
  final shared.GitComparison comparison;
  final String? reviewToken;
  final List<shared.GitComparison> reviewedFiles;

  bool get historical => comparison.right.kind == shared.ContentKind.commit;
  String get id => jsonEncode([
    repository.key,
    (comparison.leftPath ?? comparison.path).toJson(),
    comparison.path.toJson(),
    comparison.left.toJson(),
    comparison.right.toJson(),
    if (!historical) reviewToken,
  ]);
}

final class SharedGitTabs {
  const SharedGitTabs({this.entries = const [], this.activeId});
  final List<SharedGitReview> entries;
  final String? activeId;
  SharedGitReview? get active =>
      entries.where((entry) => entry.id == activeId).firstOrNull;
}

final sharedGitReviewProvider =
    NotifierProvider<SharedGitReviews, Map<String, SharedGitTabs>>(
      SharedGitReviews.new,
    );

class SharedGitReviews extends Notifier<Map<String, SharedGitTabs>> {
  @override
  Map<String, SharedGitTabs> build() => {};

  void open(String workspace, SharedGitReview review) {
    final tabs = state[workspace] ?? const SharedGitTabs();
    state = {
      ...state,
      workspace: SharedGitTabs(
        entries: List.unmodifiable([
          ...tabs.entries,
          if (!tabs.entries.any((entry) => entry.id == review.id)) review,
        ]),
        activeId: review.id,
      ),
    };
  }

  void activate(String workspace, String id) {
    final tabs = state[workspace];
    if (tabs == null || !tabs.entries.any((entry) => entry.id == id)) return;
    state = {
      ...state,
      workspace: SharedGitTabs(entries: tabs.entries, activeId: id),
    };
  }

  void deactivate(String workspace) {
    final tabs = state[workspace];
    if (tabs == null || tabs.activeId == null) return;
    state = {...state, workspace: SharedGitTabs(entries: tabs.entries)};
  }

  void close(String workspace, String id) {
    final tabs = state[workspace];
    if (tabs == null) return;
    final index = tabs.entries.indexWhere((entry) => entry.id == id);
    if (index < 0) return;
    final remaining = List<SharedGitReview>.of(tabs.entries)..removeAt(index);
    state = {
      ...state,
      workspace: SharedGitTabs(
        entries: List.unmodifiable(remaining),
        activeId: tabs.activeId != id
            ? tabs.activeId
            : remaining.isEmpty
            ? null
            : remaining[(index - 1).clamp(0, remaining.length - 1)].id,
      ),
    };
  }
}
