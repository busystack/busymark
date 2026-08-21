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
    String? originalRepoRelativePath,
  });
  Future<GitDiff> diffUntrackedFile(
    GitRepositoryInfo repository,
    String repoRelativePath,
  );
  Future<GitDiff> diffAll(GitRepositoryInfo repository, {required bool staged});
  Future<List<GitCommitSummary>> history(
    GitRepositoryInfo repository, {
    String? repoRelativePath,
    int limit = 200,
    int skip = 0,
  });
  Future<List<GitFileHistoryEntry>> fileHistory(
    GitRepositoryInfo repository,
    String repoRelativePath, {
    int limit = 200,
    int skip = 0,
  });
  Future<GitCommitDetails> commitDetails(
    GitRepositoryInfo repository,
    String hash, {
    String? repoRelativePath,
  });
  Future<String?> readFileAtCommit(
    GitRepositoryInfo repository,
    String hash,
    String repoRelativePath,
  );
  Future<GitHistoricalFileComparison> compareFileWithParent(
    GitRepositoryInfo repository,
    String hash, {
    String? oldPath,
    String? newPath,
  });
  Future<GitHistoricalFileComparison> compareFileWithWorkingTree(
    GitRepositoryInfo repository,
    String hash, {
    required String historicalPath,
    required String currentPath,
  });
  Future<GitOperationResult> restoreFileFromCommit(
    GitRepositoryInfo repository,
    String hash, {
    required String historicalPath,
    required String currentPath,
  });
  Future<GitOperationResult> resetCurrentBranch(
    GitRepositoryInfo repository,
    String hash,
    GitResetMode mode,
  );
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
  Future<GitOperationResult> rollbackTracked(
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
  Future<GitOperationResult> fetch(GitRepositoryInfo repository);
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
