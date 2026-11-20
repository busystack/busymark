import '../domain/git_models.dart';

/// Optional controlled, non-executing discovery for the application policy.
abstract interface class GitWorkspaceRootInspector {
  Future<void> requireWorkspaceRoot(String workspacePath);
}

abstract class GitRepositoryGateway {
  Future<GitAvailability> availability();
  Future<GitRepositoryInfo?> detectRepository(String workspacePath);

  /// Whether this gateway can execute repository-controlled configuration.
  ///
  /// The controller will not call [detectRepository] or any repository method
  /// until the user explicitly trusts the attached workspace.
  bool get requiresWorkspaceTrust;

  Future<GitStatusSnapshot> status(GitRepositoryInfo repository);
  Stream<void> watch(GitRepositoryInfo repository);
  Future<String> stagedPatch(GitRepositoryInfo repository);
}
