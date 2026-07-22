import '../domain/git_models.dart';

abstract class GitRepositoryDetector {
  Future<GitAvailability> availability();
  Future<GitRepositoryInfo?> detectRepository(String workspacePath);
}

abstract class GitRepositoryGateway implements GitRepositoryDetector {
  /// Whether this gateway can execute repository-controlled configuration.
  ///
  /// The controller will not call [detectRepository] or any repository method
  /// until the user explicitly trusts the attached workspace.
  bool get requiresWorkspaceTrust;

  Future<GitStatusSnapshot> status(GitRepositoryInfo repository);
  Future<GitDiff> diffFile(
    GitRepositoryInfo repository,
    String repoRelativePath, {
    required bool staged,
  });
  Future<GitDiff> diffAll(GitRepositoryInfo repository, {required bool staged});
  Future<List<GitCommitSummary>> history(
    GitRepositoryInfo repository, {
    String? repoRelativePath,
    int limit = 200,
    int skip = 0,
  });
  Future<GitCommitDetails> commitDetails(
    GitRepositoryInfo repository,
    String hash, {
    String? repoRelativePath,
  });
  Future<List<GitBranch>> branches(GitRepositoryInfo repository);
  Future<List<String>> remotes(GitRepositoryInfo repository);
  Future<GitOperationResult> stage(
    GitRepositoryInfo repository,
    List<String> repoRelativePaths,
  );
  Future<GitOperationResult> unstage(
    GitRepositoryInfo repository,
    List<String> repoRelativePaths,
  );
  Future<GitOperationResult> discardTracked(
    GitRepositoryInfo repository,
    List<String> repoRelativePaths,
  );
  Future<GitOperationResult> discardUntracked(
    GitRepositoryInfo repository,
    List<String> repoRelativePaths,
    GitStatusSnapshot snapshot,
  );
  Future<GitOperationResult> commit(
    GitRepositoryInfo repository,
    String message,
  );
  Future<GitOperationResult> pullFastForwardOnly(GitRepositoryInfo repository);
  Future<GitOperationResult> push(GitRepositoryInfo repository);
  Future<GitOperationResult> pushSetUpstream(
    GitRepositoryInfo repository,
    String remote,
    String branch,
  );
  Future<GitOperationResult> createBranch(
    GitRepositoryInfo repository,
    String branchName,
  );
  Future<GitOperationResult> switchBranch(
    GitRepositoryInfo repository,
    String branchName,
  );
  Future<GitOperationResult> initializeRepository(String rootPath);
}
