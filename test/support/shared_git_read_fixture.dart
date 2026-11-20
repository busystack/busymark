import 'package:busymark/src/git/application/git_controller.dart';
import 'package:busymark/src/git/domain/git_models.dart';
import 'package:busystack_git/busystack_git.dart' as shared;

/// Deterministic read transport for application-shell tests. Real command,
/// safety and daemon semantics are verified by the isolated repository suites.
/// Unexpected mutations fail instead of manufacturing a successful outcome.
class SharedGitReadFixture
    implements shared.GitClient, shared.GitWorkflowClient {
  SharedGitReadFixture(
    this.state, {
    this.commits = const [],
    this.fileHistory = const [],
  });
  final GitState state;
  final List<shared.GitCommit> commits;
  final List<shared.Json> fileHistory;
  int statusReads = 0, watchSubscriptions = 0;
  String get snapshotToken => 'shell-fixture';
  shared.RepositoryId? get repository {
    final info = state.repositoryInfo;
    return info == null
        ? null
        : shared.RepositoryId(
            root: info.rootPath,
            gitDir: info.gitDirPath,
            commonDir: info.gitDirPath,
            objectFormat: 'sha1',
          );
  }

  String statusCode(GitFileChangeStatus status) => switch (status) {
    GitFileChangeStatus.unmodified => '.',
    GitFileChangeStatus.modified => 'M',
    GitFileChangeStatus.added => 'A',
    GitFileChangeStatus.deleted => 'D',
    GitFileChangeStatus.renamed => 'R',
    GitFileChangeStatus.copied => 'C',
    GitFileChangeStatus.typeChanged => 'T',
    GitFileChangeStatus.unmerged => 'U',
    GitFileChangeStatus.untracked => '?',
    GitFileChangeStatus.ignored => '!',
    GitFileChangeStatus.unknown => '.',
  };
  @override
  Future<shared.RepositoryId?> discover(
    String localPath, {
    shared.GitCancellation? cancellation,
  }) async => repository;
  @override
  Future<shared.GitSnapshot> status(
    shared.RepositoryId repository, {
    shared.GitCancellation? cancellation,
    shared.GitReadPolicy policy = shared.GitReadPolicy.restricted,
  }) async {
    statusReads++;
    return shared.GitSnapshot(
      repository: repository,
      token: snapshotToken,
      indexToken: 'shell-fixture-index',
      head:
          commits.firstOrNull?.oid ??
          (fileHistory.isEmpty
              ? null
              : shared.GitCommit.fromJson(
                  fileHistory.first['commit'] as shared.Json,
                ).oid),
      branch: 'main',
      upstream: null,
      ahead: 0,
      behind: 0,
      changes: [
        for (final file in state.statusSnapshot?.files ?? <GitFileStatus>[])
          shared.GitChange(
            path: shared.RepoPath.text(file.repoRelativePath),
            originalPath: file.originalRepoRelativePath == null
                ? null
                : shared.RepoPath.text(file.originalRepoRelativePath!),
            index: file.untracked ? '?' : statusCode(file.indexStatus),
            worktree: statusCode(file.workTreeStatus),
          ),
      ],
      operation: const shared.RepositoryOperation(shared.GitOperationKind.none),
      observedAt: DateTime.utc(2026),
    );
  }

  @override
  Future<List<shared.GitReference>> references(
    shared.RepositoryId repository,
  ) async => [
    if (commits.isNotEmpty)
      shared.GitReference(
        name: 'refs/heads/main',
        oid: commits.first.oid,
        current: true,
      ),
  ];
  @override
  Future<shared.HistoryPage> history(
    shared.RepositoryId repository, {
    shared.HistoryFilter filter = const shared.HistoryFilter(),
    int offset = 0,
    int limit = 100,
    String? anchor,
    shared.GitCancellation? cancellation,
  }) async => shared.HistoryPage(
    commits.skip(offset).take(limit).toList(),
    nextOffset: offset + limit,
    hasMore: commits.length > offset + limit,
    anchor: 'shell-fixture-history',
  );
  @override
  Future<List<shared.GitChange>> changedFiles(
    shared.RepositoryId repository,
    shared.GitOid revision, {
    shared.GitOid? parent,
  }) async => [];
  @override
  Future<shared.GitContent> content(
    shared.RepositoryId repository,
    shared.RepoPath path,
    shared.ContentVersion version, {
    shared.GitCancellation? cancellation,
  }) => throw StateError(
    'The shell fixture did not provide content for ${path.display}.',
  );
  @override
  Future<shared.Json> inspect(
    shared.RepositoryId repository,
    shared.GitInspection request, {
    shared.GitCancellation? cancellation,
    void Function(shared.GitProgress)? onProgress,
  }) async => switch (request.kind) {
    shared.GitInspectionKind.commitOptions => {'hasConfiguredHooks': false},
    shared.GitInspectionKind.fileHistory => {
      'revision':
          request.revision?.value ??
          (fileHistory.isEmpty
              ? null
              : shared.GitCommit.fromJson(
                  fileHistory.first['commit'] as shared.Json,
                ).oid.value),
      'entries': fileHistory,
      'hasMore': false,
    },
    _ => throw StateError('Unexpected shell inspection: ${request.kind.name}'),
  };
  @override
  Future<shared.GitOutcome> mutate(
    shared.RepositoryId repository,
    shared.GitMutation request, {
    shared.GitCancellation? cancellation,
    void Function(shared.GitProgress)? onProgress,
  }) => throw StateError('Unexpected shell mutation: ${request.kind}');
  @override
  Future<shared.GitCreationOutcome> create(
    shared.GitCreation request, {
    shared.GitCancellation? cancellation,
    void Function(shared.GitProgress)? onProgress,
  }) => throw StateError('Unexpected shell creation.');
  @override
  Stream<void> watch(shared.RepositoryId repository) => Stream<void>.multi((_) {
    watchSubscriptions++;
  });
}
