import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/git/application/git_controller.dart';
import 'package:busymark/src/git/application/git_gateway.dart';
import 'package:busymark/src/git/domain/git_models.dart';
import 'package:busymark/src/workspace/workspace_controller.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:busymark/src/workspace/workspace_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('refreshes after workspace attach', () async {
    final gateway = _FakeGitGateway();
    final container = _container(gateway);

    container
        .read(gitControllerProvider.notifier)
        .attachWorkspace(_workspace());
    await Future<void>.delayed(Duration.zero);
    await container.read(gitControllerProvider.notifier).refresh();

    expect(
      container.read(gitControllerProvider).repositoryInfo?.rootPath,
      '/repo',
    );
    expect(gateway.detectCalls, 2);
  });

  test('stage and unstage update state', () async {
    final gateway = _FakeGitGateway();
    final container = _container(gateway);
    final controller = container.read(gitControllerProvider.notifier);
    controller.attachWorkspace(_workspace());
    await controller.refresh();

    await controller.stageFiles(['README.md']);
    expect(
      container
          .read(gitControllerProvider)
          .statusSnapshot
          ?.stagedFiles
          .single
          .repoRelativePath,
      'README.md',
    );

    await controller.unstageFiles(['README.md']);
    expect(
      container
          .read(gitControllerProvider)
          .statusSnapshot
          ?.unstagedFiles
          .single
          .repoRelativePath,
      'README.md',
    );
  });

  test('commit blocks empty message', () async {
    final gateway = _FakeGitGateway(staged: true);
    final container = _container(gateway);
    final controller = container.read(gitControllerProvider.notifier);
    controller.attachWorkspace(_workspace());
    await controller.refresh();

    await controller.commit('   ');

    expect(
      container.read(gitControllerProvider).lastError?.code,
      GitFailureCode.invalidCommitMessage,
    );
    expect(gateway.commitCalls, 0);
  });

  test('commit blocks when no files are staged', () async {
    final gateway = _FakeGitGateway();
    final container = _container(gateway);
    final controller = container.read(gitControllerProvider.notifier);
    controller.attachWorkspace(_workspace());
    await controller.refresh();

    await controller.commit('Docs');

    expect(
      container.read(gitControllerProvider).lastError?.code,
      GitFailureCode.noStagedFiles,
    );
    expect(gateway.commitCalls, 0);
  });

  test('branch switch requires clean BusyMark editor state', () async {
    final gateway = _FakeGitGateway();
    final container = _container(gateway);
    await container
        .read(workspaceControllerProvider.notifier)
        .createMarkdownFile();
    container
        .read(workspaceControllerProvider.notifier)
        .updateActiveText('# Dirty\n');
    final controller = container.read(gitControllerProvider.notifier);
    controller.attachWorkspace(_workspace());
    await controller.refresh();

    await controller.switchBranch('feature');

    expect(
      container.read(gitControllerProvider).lastError?.code,
      GitFailureCode.dirtyWorkspace,
    );
    expect(gateway.switchCalls, 0);
  });

  test('reports Git unavailable state', () async {
    final container = _container(const UnavailableGitRepositoryGateway());
    final controller = container.read(gitControllerProvider.notifier);

    controller.attachWorkspace(_workspace());
    await controller.refresh();

    expect(
      container.read(gitControllerProvider).availability.available,
      isFalse,
    );
    expect(container.read(gitControllerProvider).repositoryInfo, isNull);
  });

  test('stores operation failure state', () async {
    final gateway = _FakeGitGateway(failStage: true);
    final container = _container(gateway);
    final controller = container.read(gitControllerProvider.notifier);
    controller.attachWorkspace(_workspace());
    await controller.refresh();

    await controller.stageFiles(['README.md']);

    expect(
      container.read(gitControllerProvider).lastError?.code,
      GitFailureCode.commandFailed,
    );
  });

  test('exposes conflict state', () async {
    final gateway = _FakeGitGateway(conflicted: true);
    final container = _container(gateway);
    final controller = container.read(gitControllerProvider.notifier);

    controller.attachWorkspace(_workspace());
    await controller.refresh();

    expect(
      container.read(gitControllerProvider).statusSnapshot?.conflictedFiles,
      isNotEmpty,
    );
    expect(
      container.read(gitControllerProvider).repositoryInfo?.hasConflicts,
      isTrue,
    );
  });

  test(
    'current file history scopes selected commit details to the file',
    () async {
      final gateway = _FakeGitGateway();
      final container = _container(gateway);
      final controller = container.read(gitControllerProvider.notifier);
      controller.attachWorkspace(_workspace(activeFilePath: '/repo/README.md'));
      await controller.refresh();

      await controller.loadFileHistory('/repo/README.md');
      await controller.loadCommitDetails('1234567890abcdef');

      expect(gateway.lastHistoryPath, 'README.md');
      expect(gateway.lastCommitDetailsPath, 'README.md');
      expect(
        container.read(gitControllerProvider).selectedView,
        GitView.changes,
      );
      expect(
        container.read(gitControllerProvider).selectedCommitHash,
        isNotNull,
      );
    },
  );

  test(
    'project history loads selected commit details without a file scope',
    () async {
      final gateway = _FakeGitGateway();
      final container = _container(gateway);
      final controller = container.read(gitControllerProvider.notifier);
      controller.attachWorkspace(_workspace(activeFilePath: '/repo/README.md'));
      await controller.refresh();

      await controller.loadFileHistory('/repo/README.md');
      await controller.loadProjectHistory();
      await controller.loadCommitDetails('1234567890abcdef');

      expect(gateway.lastHistoryPath, isNull);
      expect(gateway.lastCommitDetailsPath, isNull);
    },
  );

  test(
    'project commit details display the first changed file by default',
    () async {
      final gateway = _FakeGitGateway();
      final container = _container(gateway);
      final controller = container.read(gitControllerProvider.notifier);
      controller.attachWorkspace(_workspace(activeFilePath: '/repo/README.md'));
      await controller.refresh();

      await controller.loadProjectHistory();
      await controller.loadCommitDetails('1234567890abcdef');

      final state = container.read(gitControllerProvider);
      expect(state.selectedDiff?.files.map((file) => file.displayPath), [
        'README.md',
        'guide.md',
      ]);
      expect(state.selectedCommitFilePath, 'README.md');
      expect(state.openDiffFilePaths, ['README.md']);
      expect(
        state.selectedDiffForDisplay?.files.single.displayPath,
        'README.md',
      );
    },
  );

  test('selected commit file opens a project commit diff tab', () async {
    final gateway = _FakeGitGateway();
    final container = _container(gateway);
    final controller = container.read(gitControllerProvider.notifier);
    controller.attachWorkspace(_workspace());
    await controller.refresh();

    await controller.loadProjectHistory();
    await controller.loadCommitDetails('1234567890abcdef');
    controller.selectCommitFile('guide.md');

    final state = container.read(gitControllerProvider);
    expect(state.selectedCommitFilePath, 'guide.md');
    expect(state.openDiffFilePaths, ['README.md', 'guide.md']);
    expect(state.selectedDiff?.files, hasLength(2));
    expect(state.selectedDiffForDisplay?.files.single.displayPath, 'guide.md');
    expect(
      state.selectedDiffForDisplay?.fileSnapshots['guide.md'],
      contains('Full revision text'),
    );
  });

  test(
    'closing a commit diff file tab activates the neighboring tab',
    () async {
      final gateway = _FakeGitGateway();
      final container = _container(gateway);
      final controller = container.read(gitControllerProvider.notifier);
      controller.attachWorkspace(_workspace());
      await controller.refresh();

      await controller.loadProjectHistory();
      await controller.loadCommitDetails('1234567890abcdef');
      controller.selectCommitFile('guide.md');
      controller.closeDiffFile('guide.md');

      final state = container.read(gitControllerProvider);
      expect(state.selectedCommitFilePath, 'README.md');
      expect(state.openDiffFilePaths, ['README.md']);
      expect(
        state.selectedDiffForDisplay?.files.single.displayPath,
        'README.md',
      );
    },
  );

  test('deactivating a diff file keeps open diff tabs', () async {
    final gateway = _FakeGitGateway();
    final container = _container(gateway);
    final controller = container.read(gitControllerProvider.notifier);
    controller.attachWorkspace(_workspace());
    await controller.refresh();

    await controller.loadProjectHistory();
    await controller.loadCommitDetails('1234567890abcdef');
    controller.selectCommitFile('guide.md');
    controller.deactivateDiffFile();

    final state = container.read(gitControllerProvider);
    expect(state.selectedCommitFilePath, isNull);
    expect(state.openDiffFilePaths, ['README.md', 'guide.md']);
    expect(state.selectedDiffForDisplay, isNull);
  });
}

ProviderContainer _container(GitRepositoryGateway gateway) {
  final container = ProviderContainer(
    overrides: [
      gitRepositoryGatewayProvider.overrideWithValue(gateway),
      localSettingsStoreProvider.overrideWithValue(_MemorySettingsStore()),
      workspaceServiceProvider.overrideWithValue(const WorkspaceService()),
    ],
  );
  addTearDown(container.dispose);
  container.read(workspaceControllerProvider.notifier);
  return container;
}

Workspace _workspace({String? activeFilePath}) {
  return Workspace(
    id: '/repo',
    rootPath: '/repo',
    kind: WorkspaceKind.markdownFolder,
    openedAt: DateTime(2026),
    activeFilePath: activeFilePath,
    files: const [],
    diagnostics: const [],
  );
}

class _FakeGitGateway implements GitRepositoryGateway {
  _FakeGitGateway({
    bool staged = false,
    this.conflicted = false,
    this.failStage = false,
  }) : _staged = staged;

  final bool conflicted;
  final bool failStage;
  var _staged = false;
  var detectCalls = 0;
  var commitCalls = 0;
  var switchCalls = 0;
  String? lastHistoryPath;
  String? lastCommitDetailsPath;

  static const repo = GitRepositoryInfo(
    rootPath: '/repo',
    gitDirPath: '/repo/.git',
  );

  @override
  Future<GitAvailability> availability() async {
    return const GitAvailability(
      available: true,
      executablePath: '/usr/bin/git',
      version: '2.50.0',
    );
  }

  @override
  Future<GitRepositoryInfo?> detectRepository(String workspacePath) async {
    detectCalls++;
    return repo;
  }

  @override
  Future<GitStatusSnapshot> status(GitRepositoryInfo repository) async {
    final files = conflicted
        ? [
            _file(
              category: GitFileStatusCategory.conflicted,
              conflicted: true,
              staged: false,
              unstaged: false,
            ),
          ]
        : [_file(staged: _staged, unstaged: !_staged)];
    return GitStatusSnapshot(
      repositoryInfo: repo.copyWith(hasConflicts: conflicted),
      files: files,
    );
  }

  @override
  Future<GitOperationResult> stage(
    GitRepositoryInfo repository,
    List<String> repoRelativePaths,
  ) async {
    if (failStage) {
      throw const GitFailure(
        code: GitFailureCode.commandFailed,
        userMessageKey: 'gitErrorCommandFailed',
        rawMessage: 'failed',
        commandName: 'add',
      );
    }
    _staged = true;
    return _result();
  }

  @override
  Future<GitOperationResult> unstage(
    GitRepositoryInfo repository,
    List<String> repoRelativePaths,
  ) async {
    _staged = false;
    return _result();
  }

  @override
  Future<GitOperationResult> commit(
    GitRepositoryInfo repository,
    String message,
  ) async {
    commitCalls++;
    _staged = false;
    return _result();
  }

  @override
  Future<GitOperationResult> switchBranch(
    GitRepositoryInfo repository,
    String branchName,
  ) async {
    switchCalls++;
    return _result();
  }

  @override
  Future<List<GitCommitSummary>> history(
    GitRepositoryInfo repository, {
    String? repoRelativePath,
    int limit = 200,
    int skip = 0,
  }) async {
    lastHistoryPath = repoRelativePath;
    return [
      GitCommitSummary(
        fullHash: '1234567890abcdef',
        shortHash: '1234567',
        authorName: 'BusyMark Test',
        authorEmail: 'busymark@example.com',
        authorDate: DateTime(2026),
        subject: 'Update docs',
        parentHashes: [],
      ),
    ];
  }

  @override
  Future<GitDiff> diffFile(
    GitRepositoryInfo repository,
    String repoRelativePath, {
    required bool staged,
  }) async {
    return const GitDiff(
      title: 'README.md',
      files: [],
      rawPatch: '',
      hasBinaryFiles: false,
    );
  }

  @override
  Future<GitDiff> diffAll(
    GitRepositoryInfo repository, {
    required bool staged,
  }) async {
    return const GitDiff(
      title: 'All',
      files: [],
      rawPatch: '',
      hasBinaryFiles: false,
    );
  }

  @override
  Future<GitCommitDetails> commitDetails(
    GitRepositoryInfo repository,
    String hash, {
    String? repoRelativePath,
  }) async {
    lastCommitDetailsPath = repoRelativePath;
    final changedFiles = repoRelativePath == null
        ? [_diffFile('README.md'), _diffFile('guide.md')]
        : [_diffFile(repoRelativePath)];
    return GitCommitDetails(
      summary: GitCommitSummary(
        fullHash: hash,
        shortHash: hash.substring(0, 7),
        authorName: 'BusyMark Test',
        authorEmail: 'busymark@example.com',
        authorDate: DateTime(2026),
        subject: 'Update docs',
        parentHashes: const [],
      ),
      changedFiles: changedFiles,
      patch: '',
      fileSnapshots: {
        for (final file in changedFiles)
          file.displayPath: '# ${file.displayPath}\n\nFull revision text.\n',
      },
    );
  }

  @override
  Future<List<GitBranch>> branches(GitRepositoryInfo repository) async {
    return const [GitBranch(name: 'main', current: true)];
  }

  @override
  Future<List<String>> remotes(GitRepositoryInfo repository) async => const [];

  @override
  Future<GitOperationResult> discardTracked(
    GitRepositoryInfo repository,
    List<String> repoRelativePaths,
  ) async => _result();

  @override
  Future<GitOperationResult> discardUntracked(
    GitRepositoryInfo repository,
    List<String> repoRelativePaths,
    GitStatusSnapshot snapshot,
  ) async => _result();

  @override
  Future<GitOperationResult> pullFastForwardOnly(
    GitRepositoryInfo repository,
  ) async => _result();

  @override
  Future<GitOperationResult> push(GitRepositoryInfo repository) async =>
      _result();

  @override
  Future<GitOperationResult> pushSetUpstream(
    GitRepositoryInfo repository,
    String remote,
    String branch,
  ) async => _result();

  @override
  Future<GitOperationResult> createBranch(
    GitRepositoryInfo repository,
    String branchName,
  ) async => _result();

  @override
  Future<GitOperationResult> initializeRepository(String rootPath) async =>
      _result();

  GitOperationResult _result() {
    return const GitOperationResult(
      success: true,
      message: 'ok',
      stdout: '',
      stderr: '',
    );
  }

  GitFileStatus _file({
    GitFileStatusCategory category = GitFileStatusCategory.modified,
    bool staged = false,
    bool unstaged = true,
    bool conflicted = false,
  }) {
    return GitFileStatus(
      repoRelativePath: 'README.md',
      absolutePath: '/repo/README.md',
      indexStatus: staged
          ? GitFileChangeStatus.modified
          : GitFileChangeStatus.unmodified,
      workTreeStatus: unstaged
          ? GitFileChangeStatus.modified
          : GitFileChangeStatus.unmodified,
      category: category,
      staged: staged,
      unstaged: unstaged,
      untracked: false,
      deleted: false,
      renamed: false,
      copied: false,
      conflicted: conflicted,
      ignored: false,
    );
  }
}

GitDiffFile _diffFile(String path) {
  return GitDiffFile(
    oldPath: path,
    newPath: path,
    status: GitDiffFileStatus.modified,
    hunks: const [],
    binary: false,
    additions: 1,
    deletions: 0,
  );
}

class _MemorySettingsStore implements LocalSettingsStore {
  @override
  Future<Map<String, Object?>> load() async => <String, Object?>{};

  @override
  Future<void> save(Map<String, Object?> json) async {}
}
