import 'dart:convert';
import 'package:busystack_git/busystack_git.dart' as shared;
import 'package:path/path.dart' as p;
import '../application/git_gateway.dart';
import '../application/git_workspace_eligibility.dart';
import '../domain/git_models.dart';

/// Host adapter for file status and AI patch access.
/// All Git execution and mutations belong to busystack_git.
/// Workspace trust, dirty buffers, localization and navigation remain here.
class GitCliGateway implements GitRepositoryGateway, GitWorkspaceRootInspector {
  const GitCliGateway({this.engine});
  final shared.GitEngine? engine;
  static final _engines = Expando<shared.GitEngine>();
  shared.GitEngine get core =>
      engine ?? (_engines[this] ??= shared.GitEngine(authorize: (_) => true));
  @override
  bool get requiresWorkspaceTrust => true;
  Future<T> _map<T>(
    Future<T> Function() action, [
    String command = 'git',
  ]) async {
    try {
      return await action();
    } on shared.GitException catch (error) {
      throw _failure(error, command);
    } on FormatException catch (error) {
      throw GitFailure(
        code: GitFailureCode.invalidPath,
        userMessageKey: 'gitErrorUnsafePath',
        rawMessage: '$error',
        commandName: command,
      );
    }
  }

  @override
  Future<GitAvailability> availability() async {
    final runner = shared.ProcessGitRunner();
    try {
      return GitAvailability(
        available: true,
        executablePath: runner.executable,
        version: await runner.verify(),
      );
    } on shared.GitException catch (error) {
      return GitAvailability.unavailable(error.diagnostic);
    }
  }

  Future<shared.RepositoryId> _repo(GitRepositoryInfo repository) async {
    final id = await core.discover(repository.rootPath);
    if (id == null ||
        id.root != repository.rootPath ||
        id.gitDir != repository.gitDirPath ||
        repository.identityKey != null && id.key != repository.identityKey) {
      throw const shared.GitException(shared.GitErrorCode.staleReview);
    }
    return id;
  }

  @override
  Future<void> requireWorkspaceRoot(String workspacePath) async {
    final repository = await core.discover(workspacePath);
    if (repository != null) {
      await requireGitWorkspaceRoot(
        workspacePath,
        repository.root,
        bare: repository.bare,
      );
    }
  }

  @override
  Future<GitRepositoryInfo?> detectRepository(String workspacePath) =>
      _map(() async {
        final id = await core.discover(workspacePath);
        if (id == null) return null;
        await requireGitWorkspaceRoot(workspacePath, id.root, bare: id.bare);
        return _info(id);
      });
  @override
  Future<GitStatusSnapshot> status(GitRepositoryInfo repository) =>
      _map(() async {
        final id = await _repo(repository), state = await core.status(id);
        return projectSharedStatus(state);
      }, 'status');
  @override
  Stream<void> watch(GitRepositoryInfo repository) async* {
    yield* core.watch(await _repo(repository));
  }

  static GitRepositoryInfo _info(shared.RepositoryId id) => GitRepositoryInfo(
    rootPath: id.root,
    gitDirPath: id.gitDir,
    identityKey: id.key,
  );
  static GitStatusSnapshot projectSharedStatus(shared.GitSnapshot state) =>
      GitStatusSnapshot(
        source: state,
        repositoryInfo: _info(state.repository),
        unrepresentedPathCount: state.changes
            .where((change) => change.path.utf8Path == null)
            .length,
        files: [
          for (final change in state.changes)
            if (change.path.utf8Path != null)
              GitFileStatus(
                repoRelativePath: change.path.utf8Path!,
                absolutePath: p.join(
                  state.repository.root,
                  change.path.utf8Path!,
                ),
                originalRepoRelativePath: change.originalPath?.utf8Path,
                indexStatus: _letter(change.index),
                workTreeStatus: _letter(change.worktree),
                category: change.conflicted
                    ? GitFileStatusCategory.conflicted
                    : change.untracked
                    ? GitFileStatusCategory.untracked
                    : GitFileStatusCategory.values.byName(
                        switch (change.index == '.'
                            ? change.worktree
                            : change.index) {
                          'M' => 'modified',
                          'A' => 'added',
                          'D' => 'deleted',
                          'R' => 'renamed',
                          'C' => 'copied',
                          'T' => 'typeChanged',
                          '!' => 'ignored',
                          _ => 'unknown',
                        },
                      ),
                staged: change.staged,
                unstaged: change.unstaged,
                untracked: change.untracked,
                deleted: change.index == 'D' || change.worktree == 'D',
                renamed: change.index == 'R' || change.worktree == 'R',
                copied: change.index == 'C' || change.worktree == 'C',
                conflicted: change.conflicted,
                ignored: change.ignored,
              ),
        ],
      );
  @override
  Future<String> stagedPatch(GitRepositoryInfo repository) => _map(() async {
    final id = await _repo(repository);
    final snapshot = await core.status(id);
    final patch = await core.patch(
      id,
      shared.GitDiffSpec(
        snapshot.head == null
            ? const shared.ContentVersion.absent()
            : shared.ContentVersion(
                shared.ContentKind.commit,
                revision: snapshot.head,
              ),
        const shared.ContentVersion.index(),
      ),
    );
    return utf8.decode(patch.bytes, allowMalformed: true);
  }, 'diff');
  static GitFileChangeStatus _letter(String value) => switch (value) {
    'M' => GitFileChangeStatus.modified,
    'A' => GitFileChangeStatus.added,
    'D' => GitFileChangeStatus.deleted,
    'R' => GitFileChangeStatus.renamed,
    'C' => GitFileChangeStatus.copied,
    'T' => GitFileChangeStatus.typeChanged,
    'U' => GitFileChangeStatus.unmerged,
    '?' => GitFileChangeStatus.untracked,
    '!' => GitFileChangeStatus.ignored,
    '.' => GitFileChangeStatus.unmodified,
    _ => GitFileChangeStatus.unknown,
  };
}

GitFailure _failure(shared.GitException error, String command) {
  final code = switch (error.code) {
    shared.GitErrorCode.unavailable => GitFailureCode.unavailable,
    shared.GitErrorCode.unsupportedVersion => GitFailureCode.unsupportedVersion,
    shared.GitErrorCode.unsafePath ||
    shared.GitErrorCode.staleReview ||
    shared.GitErrorCode.invalidRequest => GitFailureCode.invalidPath,
    shared.GitErrorCode.authorIdentity => GitFailureCode.authorIdentity,
    shared.GitErrorCode.authentication => GitFailureCode.authentication,
    shared.GitErrorCode.transport => GitFailureCode.network,
    shared.GitErrorCode.conflict => GitFailureCode.conflict,
    shared.GitErrorCode.dirty => GitFailureCode.dirtyWorkspace,
    _ => GitFailureCode.commandFailed,
  };
  return GitFailure(
    code: code,
    userMessageKey: switch (code) {
      GitFailureCode.invalidPath => 'gitErrorUnsafePath',
      GitFailureCode.authorIdentity => 'gitErrorAuthorIdentity',
      _ => 'gitErrorCommandFailed',
    },
    rawMessage: error.diagnostic,
    commandName: command,
    exitCode: error.exitCode,
  );
}
