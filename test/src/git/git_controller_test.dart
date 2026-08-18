import 'dart:async';
import 'dart:io';

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
  test('diff open target follows the current working-tree context', () {
    const repository = GitRepositoryInfo(
      rootPath: '/repo',
      gitDirPath: '/repo/.git',
    );
    const addedThenDeleted = GitFileStatus(
      repoRelativePath: 'draft.md',
      absolutePath: '/repo/draft.md',
      indexStatus: GitFileChangeStatus.added,
      workTreeStatus: GitFileChangeStatus.deleted,
      category: GitFileStatusCategory.deleted,
      staged: true,
      unstaged: true,
      untracked: false,
      deleted: true,
      renamed: false,
      copied: false,
      conflicted: false,
      ignored: false,
    );
    const changesState = GitState(
      repositoryInfo: repository,
      statusSnapshot: GitStatusSnapshot(
        repositoryInfo: repository,
        files: [addedThenDeleted],
      ),
      selectedChange: GitChangeSelection(
        path: 'draft.md',
        comparison: GitComparisonType.staged,
      ),
    );

    expect(changesState.selectedDiffOpenFilePath, isNull);
    expect(
      const GitState(
        selectedView: GitView.fileHistory,
        fileHistory: GitFileHistoryState(currentPath: 'current.md'),
      ).selectedDiffOpenFilePath,
      'current.md',
    );
    expect(
      const GitState(
        selectedView: GitView.projectHistory,
      ).selectedDiffOpenFilePath,
      isNull,
    );
  });

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

  test(
    'trust-required gateway does not inspect workspace before trust',
    () async {
      final gateway = _TrustRequiredFakeGitGateway();
      final container = _container(gateway);
      final controller = container.read(gitControllerProvider.notifier);

      controller.attachWorkspace(_workspace());
      expect(
        container.read(gitControllerProvider).requiresWorkspaceTrust,
        isTrue,
      );
      expect(gateway.detectCalls, 0);
      expect(gateway.statusCalls, 0);
      await Future<void>.delayed(Duration.zero);
      await controller.refresh();

      var state = container.read(gitControllerProvider);
      expect(state.requiresWorkspaceTrust, isTrue);
      expect(state.repositoryInfo, isNull);
      expect(state.statusSnapshot, isNull);
      expect(gateway.detectCalls, 0);
      expect(gateway.statusCalls, 0);

      await controller.trustWorkspace();

      state = container.read(gitControllerProvider);
      expect(state.requiresWorkspaceTrust, isFalse);
      expect(state.repositoryInfo, isNotNull);
      expect(state.statusSnapshot, isNotNull);
      expect(gateway.detectCalls, greaterThan(0));
      expect(gateway.statusCalls, greaterThan(0));
      expect(
        container
            .read(appSettingsControllerProvider)
            .trustsGitWorkspace('/repo'),
        isTrue,
      );
    },
  );

  test('clearing trust immediately revokes repository access', () async {
    final gateway = _TrustRequiredFakeGitGateway();
    final container = _container(gateway);
    final controller = container.read(gitControllerProvider.notifier);

    controller.attachWorkspace(_workspace());
    await controller.trustWorkspace();
    expect(container.read(gitControllerProvider).repositoryInfo, isNotNull);
    final trustedDetectCalls = gateway.detectCalls;
    final trustedStatusCalls = gateway.statusCalls;

    await container
        .read(appSettingsControllerProvider.notifier)
        .clearTrustedGitWorkspaces();

    final state = container.read(gitControllerProvider);
    expect(state.requiresWorkspaceTrust, isTrue);
    expect(state.repositoryInfo, isNull);
    expect(state.statusSnapshot, isNull);
    await controller.refresh();
    expect(gateway.detectCalls, trustedDetectCalls);
    expect(gateway.statusCalls, trustedStatusCalls);
  });

  test('status failure after trust retains the detected repository', () async {
    final gateway = _TrustRequiredFakeGitGateway(failStatus: true);
    final container = _container(gateway);
    final controller = container.read(gitControllerProvider.notifier);

    controller.attachWorkspace(_workspace());
    await controller.trustWorkspace();

    final state = container.read(gitControllerProvider);
    expect(state.requiresWorkspaceTrust, isFalse);
    expect(state.repositoryInfo, isNotNull);
    expect(state.statusSnapshot, isNull);
    expect(state.lastError?.code, GitFailureCode.commandFailed);
  });

  test('trust is scoped to the attached workspace', () async {
    final gateway = _TrustRequiredFakeGitGateway();
    final container = _container(gateway);
    final controller = container.read(gitControllerProvider.notifier);

    controller.attachWorkspace(_workspace());
    await Future<void>.delayed(Duration.zero);
    await controller.refresh();
    await controller.trustWorkspace();
    final trustedWorkspaceDetectCalls = gateway.detectCalls;
    final trustedWorkspaceStatusCalls = gateway.statusCalls;

    controller.attachWorkspace(_workspace(id: '/other', rootPath: '/other'));
    await Future<void>.delayed(Duration.zero);
    await controller.refresh();

    final state = container.read(gitControllerProvider);
    expect(state.requiresWorkspaceTrust, isTrue);
    expect(state.repositoryInfo, isNull);
    expect(state.statusSnapshot, isNull);
    expect(gateway.detectCalls, trustedWorkspaceDetectCalls);
    expect(gateway.statusCalls, trustedWorkspaceStatusCalls);
    expect(
      container
          .read(appSettingsControllerProvider)
          .trustsGitWorkspace('/other'),
      isFalse,
    );
  });

  test(
    'Git executes with the canonical path that was trusted',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'busymark-controller-git-trust-',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final trusted = await Directory('${root.path}/trusted').create();
      final replacement = await Directory('${root.path}/replacement').create();
      final workspaceLink = Link('${root.path}/workspace');
      await workspaceLink.create(trusted.path);
      final gateway = _TrustRequiredFakeGitGateway();
      final container = _container(gateway);
      await container
          .read(appSettingsControllerProvider.notifier)
          .trustGitWorkspace(workspaceLink.path);
      final controller = container.read(gitControllerProvider.notifier);

      controller.attachWorkspace(
        _workspace(id: workspaceLink.path, rootPath: workspaceLink.path),
      );
      await controller.refresh();

      expect(gateway.lastDetectedWorkspacePath, trusted.path);
      await controller.initializeRepository();
      expect(gateway.lastInitializeRootPath, trusted.path);
      final trustedDetectCalls = gateway.detectCalls;
      await workspaceLink.delete();
      await workspaceLink.create(replacement.path);

      await controller.refresh();

      expect(gateway.detectCalls, trustedDetectCalls);
      expect(
        container.read(gitControllerProvider).requiresWorkspaceTrust,
        isTrue,
      );
    },
    skip: Platform.isWindows,
  );

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

  test(
    'loads only the selected change comparison and reconciles after stage',
    () async {
      final gateway = _FakeGitGateway();
      final container = _container(gateway);
      final controller = container.read(gitControllerProvider.notifier);
      controller.attachWorkspace(_workspace());
      await controller.refresh();

      await controller.selectChange(
        const GitChangeSelection(
          path: 'README.md',
          comparison: GitComparisonType.unstaged,
        ),
      );
      expect(gateway.diffRequests, [('README.md', false)]);

      await controller.stageFiles(['README.md']);

      expect(
        container.read(gitControllerProvider).selectedChange,
        const GitChangeSelection(
          path: 'README.md',
          comparison: GitComparisonType.staged,
        ),
      );
      expect(gateway.diffRequests.last, ('README.md', true));
      expect(gateway.diffRequests.where((request) => request.$2), hasLength(1));
    },
  );

  test('routes untracked selections to the untracked comparison', () async {
    final gateway = _FakeGitGateway();
    final container = _container(gateway);
    final controller = container.read(gitControllerProvider.notifier);
    controller.attachWorkspace(_workspace());
    await controller.refresh();

    await controller.selectChange(
      const GitChangeSelection(
        path: 'draft.md',
        comparison: GitComparisonType.untracked,
      ),
    );

    expect(gateway.untrackedDiffRequests, ['draft.md']);
    expect(gateway.diffRequests, isEmpty);
  });

  test('staged rename comparison preserves the original path', () async {
    final gateway = _FakeGitGateway();
    final container = _container(gateway);
    final controller = container.read(gitControllerProvider.notifier);
    controller.attachWorkspace(_workspace());
    await controller.refresh();

    await controller.selectChange(
      const GitChangeSelection(
        path: 'new.md',
        comparison: GitComparisonType.staged,
        originalRepoRelativePath: 'old.md',
      ),
    );

    expect(gateway.diffRequests, [('new.md', true)]);
    expect(gateway.diffOriginalPaths, ['old.md']);
  });

  test('reactivates an open change comparison tab', () async {
    final gateway = _FakeGitGateway();
    final container = _container(gateway);
    final controller = container.read(gitControllerProvider.notifier);
    controller.attachWorkspace(_workspace());
    await controller.refresh();
    await controller.selectChange(
      const GitChangeSelection(
        path: 'README.md',
        comparison: GitComparisonType.unstaged,
      ),
    );
    controller.deactivateDiffFile();

    expect(
      container.read(gitControllerProvider).selectedDiffForDisplay,
      isNull,
    );
    await controller.activateDiffFile('README.md');

    final state = container.read(gitControllerProvider);
    expect(state.selectedCommitFilePath, 'README.md');
    expect(state.selectedDiffForDisplay, isNotNull);
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

  test(
    'restore is blocked while the active editor has unsaved content',
    () async {
      final gateway = _FakeGitGateway();
      final container = _container(gateway);
      await container
          .read(workspaceControllerProvider.notifier)
          .createMarkdownFile();
      container
          .read(workspaceControllerProvider.notifier)
          .updateActiveText('# Unsaved\n');
      final controller = container.read(gitControllerProvider.notifier);
      controller.attachWorkspace(_workspace(activeFilePath: '/repo/README.md'));
      await controller.refresh();
      await controller.loadFileHistory('/repo/README.md');
      await controller.selectFileHistoryCommit('1234567890abcdef');

      final restored = await controller.restoreSelectedFileVersion();

      expect(restored, isFalse);
      expect(gateway.restoreCalls, 0);
      expect(
        container.read(gitControllerProvider).lastError?.code,
        GitFailureCode.dirtyWorkspace,
      );
    },
  );

  test('restore is blocked while the current file is staged', () async {
    final gateway = _FakeGitGateway(staged: true);
    final originalIndex = gateway.indexContent;
    final originalWorkingTree = gateway.workingTreeContent;
    final container = _container(gateway);
    final controller = container.read(gitControllerProvider.notifier);
    controller.attachWorkspace(_workspace(activeFilePath: '/repo/README.md'));
    await controller.refresh();
    await controller.loadFileHistory('/repo/README.md');
    await controller.selectFileHistoryCommit('1234567890abcdef');

    final restored = await controller.restoreSelectedFileVersion();

    expect(restored, isFalse);
    expect(gateway.restoreCalls, 0);
    expect(gateway.staged, isTrue);
    expect(gateway.indexContent, originalIndex);
    expect(gateway.workingTreeContent, originalWorkingTree);
    expect(
      container.read(gitControllerProvider).lastError?.code,
      GitFailureCode.stagedChanges,
    );
  });

  test('fetch refreshes repository status', () async {
    final gateway = _FakeGitGateway();
    final container = _container(gateway);
    final controller = container.read(gitControllerProvider.notifier);
    controller.attachWorkspace(_workspace());
    await controller.refresh();
    final statusCallsBefore = gateway.statusCalls;

    await controller.fetch();

    expect(gateway.fetchCalls, 1);
    expect(gateway.statusCalls, greaterThan(statusCallsBefore));
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

  test('clears previous workspace Git state immediately on attach', () async {
    final gateway = _FakeGitGateway();
    final container = _container(gateway);
    final controller = container.read(gitControllerProvider.notifier);
    controller.attachWorkspace(_workspace(activeFilePath: '/repo/README.md'));
    await controller.refresh();
    await controller.loadProjectHistory();
    await controller.loadCommitDetails('1234567890abcdef');
    await controller.stageFiles(['../outside.md']);

    controller.attachWorkspace(_workspace(id: '/other', rootPath: '/other'));

    final state = container.read(gitControllerProvider);
    expect(state.attachedWorkspace?.id, '/other');
    expect(state.repositoryInfo, isNull);
    expect(state.statusSnapshot, isNull);
    expect(state.selectedFilePath, isNull);
    expect(state.selectedCommitHash, isNull);
    expect(state.selectedCommitFilePath, isNull);
    expect(state.openDiffFilePaths, isEmpty);
    expect(state.selectedDiff, isNull);
    expect(state.history, isEmpty);
    expect(state.historyFilePath, isNull);
    expect(state.branches, isEmpty);
    expect(state.lastError, isNull);
    expect(state.lastOperationMessage, isNull);
    expect(state.scopedFilePath, isNull);
  });

  test('ignores stale refresh results after workspace switch', () async {
    final gateway = _DeferredDetectGitGateway();
    final container = _container(gateway);
    final controller = container.read(gitControllerProvider.notifier);

    controller.attachWorkspace(_workspace());
    await Future<void>.delayed(Duration.zero);
    controller.attachWorkspace(_workspace(id: '/other', rootPath: '/other'));
    await Future<void>.delayed(Duration.zero);

    gateway.completeDetect('/repo', _DeferredDetectGitGateway.repo('/repo'));
    await Future<void>.delayed(Duration.zero);

    var state = container.read(gitControllerProvider);
    expect(state.attachedWorkspace?.id, '/other');
    expect(state.repositoryInfo, isNull);

    gateway.completeDetect('/other', _DeferredDetectGitGateway.repo('/other'));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    state = container.read(gitControllerProvider);
    expect(state.repositoryInfo?.rootPath, '/other');
    expect(state.statusSnapshot?.repositoryInfo.rootPath, '/other');
  });

  test(
    'cancels set-upstream push when the workspace changes during remote lookup',
    () async {
      final gateway = _DeferredSetUpstreamPushGitGateway();
      final container = _container(gateway);
      final controller = container.read(gitControllerProvider.notifier);

      controller.attachWorkspace(_workspace());
      await controller.refresh();
      expect(
        container.read(gitControllerProvider).repositoryInfo?.rootPath,
        '/repo',
      );

      final push = controller.push(allowSetUpstream: true);
      await gateway.remotesStarted.future;
      expect(gateway.remotesRepository?.rootPath, '/repo');

      controller.attachWorkspace(_workspace(id: '/other', rootPath: '/other'));
      await controller.refresh();
      expect(
        container.read(gitControllerProvider).repositoryInfo?.rootPath,
        '/other',
      );

      gateway.remotesResult.complete(const ['origin']);
      await push;

      expect(gateway.setUpstreamPushes, isEmpty);
      expect(
        container.read(gitControllerProvider).repositoryInfo?.rootPath,
        '/other',
      );
    },
  );

  test('ignores stale history after a workspace switch', () async {
    final gateway = _DeferredHistoryGitGateway();
    final container = _container(gateway);
    final controller = container.read(gitControllerProvider.notifier);

    controller.attachWorkspace(_workspace());
    await controller.refresh();
    final history = controller.loadProjectHistory();
    await gateway.historyStarted.future;

    controller.attachWorkspace(_workspace(id: '/other', rootPath: '/other'));
    await controller.refresh();
    gateway.historyResult.complete([
      _commitSummary('aaaaaaaaaaaaaaaa', 'History from the old repository'),
    ]);
    await history;

    final state = container.read(gitControllerProvider);
    expect(state.repositoryInfo?.rootPath, '/other');
    expect(state.history, isEmpty);
    expect(state.selectedView, GitView.changes);
  });

  test('history tab reloads project history after workspace switch', () async {
    final gateway = _FakeGitGateway();
    final container = _container(gateway);
    final controller = container.read(gitControllerProvider.notifier);
    controller.attachWorkspace(_workspace());
    await controller.refresh();
    await controller.selectView(GitView.projectHistory);
    expect(container.read(gitControllerProvider).history, isNotEmpty);

    controller.attachWorkspace(_workspace(id: '/other', rootPath: '/other'));
    await controller.refresh();
    expect(container.read(gitControllerProvider).selectedView, GitView.changes);
    expect(container.read(gitControllerProvider).history, isEmpty);

    await controller.selectView(GitView.projectHistory);

    final state = container.read(gitControllerProvider);
    expect(state.selectedView, GitView.projectHistory);
    expect(state.history, isNotEmpty);
    expect(gateway.lastHistoryPath, isNull);
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
      expect(gateway.lastCommitDetailsPath, isNull);
      expect(
        container.read(gitControllerProvider).selectedView,
        GitView.fileHistory,
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
      expect(
        state.projectHistory.details?.changedFiles.map(
          (file) => file.displayPath,
        ),
        ['README.md', 'guide.md'],
      );
      expect(state.selectedDiff?.files.single.displayPath, 'README.md');
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
    await controller.selectCommitFile('guide.md');

    final state = container.read(gitControllerProvider);
    expect(state.selectedCommitFilePath, 'guide.md');
    expect(state.openDiffFilePaths, ['README.md', 'guide.md']);
    expect(state.projectHistory.details?.changedFiles, hasLength(2));
    expect(state.selectedDiff?.files, hasLength(1));
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
      await controller.selectCommitFile('guide.md');
      controller.closeDiffFile('guide.md');
      await Future<void>.delayed(Duration.zero);

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
    await controller.selectCommitFile('guide.md');
    controller.deactivateDiffFile();

    final state = container.read(gitControllerProvider);
    expect(state.selectedCommitFilePath, isNull);
    expect(state.openDiffFilePaths, ['README.md', 'guide.md']);
    expect(state.selectedDiffForDisplay, isNull);
  });

  test(
    'file and project history paginate and retain separate selections',
    () async {
      final gateway = _PagedHistoryGitGateway();
      final container = _container(gateway);
      final controller = container.read(gitControllerProvider.notifier);
      controller.attachWorkspace(_workspace(activeFilePath: '/repo/README.md'));
      await controller.refresh();

      await controller.loadFileHistory('/repo/README.md');
      expect(
        container.read(gitControllerProvider).fileHistory.entries,
        hasLength(50),
      );
      expect(container.read(gitControllerProvider).fileHistory.hasMore, isTrue);
      await controller.loadMoreFileHistory();
      expect(
        container.read(gitControllerProvider).fileHistory.entries,
        hasLength(55),
      );
      expect(
        container.read(gitControllerProvider).fileHistory.hasMore,
        isFalse,
      );
      final fileHash = container
          .read(gitControllerProvider)
          .fileHistory
          .entries
          .first
          .commit
          .fullHash;
      await controller.selectFileHistoryCommit(fileHash);

      await controller.loadProjectHistory();
      expect(
        container.read(gitControllerProvider).projectHistory.commits,
        hasLength(50),
      );
      await controller.loadMoreProjectHistory();
      expect(
        container.read(gitControllerProvider).projectHistory.commits,
        hasLength(60),
      );
      final projectHash = container
          .read(gitControllerProvider)
          .projectHistory
          .commits
          .first
          .fullHash;
      await controller.selectProjectCommit(projectHash);
      await controller.selectView(GitView.fileHistory);

      final state = container.read(gitControllerProvider);
      expect(state.fileHistory.selectedCommitHash, fileHash);
      expect(state.projectHistory.selectedCommitHash, projectHash);
      expect(state.selectedCommitHash, fileHash);
    },
  );
}

class _PagedHistoryGitGateway extends _FakeGitGateway {
  final _projectCommits = List.generate(
    60,
    (index) => _commitSummary(
      index.toRadixString(16).padLeft(16, '0'),
      'Project commit $index',
    ),
  );
  late final List<GitFileHistoryEntry> _fileEntries = [
    for (var index = 0; index < 55; index++)
      GitFileHistoryEntry(
        commit: _commitSummary(
          (index + 1000).toRadixString(16).padLeft(16, '0'),
          'File commit $index',
        ),
        pathAtCommit: 'README.md',
        pathInParent: 'README.md',
        status: GitDiffFileStatus.modified,
      ),
  ];

  @override
  Future<List<GitCommitSummary>> history(
    GitRepositoryInfo repository, {
    String? repoRelativePath,
    int limit = 200,
    int skip = 0,
  }) async => _projectCommits.skip(skip).take(limit).toList();

  @override
  Future<List<GitFileHistoryEntry>> fileHistory(
    GitRepositoryInfo repository,
    String repoRelativePath, {
    int limit = 200,
    int skip = 0,
  }) async => _fileEntries.skip(skip).take(limit).toList();
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

Workspace _workspace({
  String id = '/repo',
  String rootPath = '/repo',
  String? activeFilePath,
}) {
  return Workspace(
    id: id,
    rootPath: rootPath,
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
    this.failStatus = false,
  }) : _staged = staged;

  final bool conflicted;
  final bool failStage;
  final bool failStatus;
  var _staged = false;
  var detectCalls = 0;
  var statusCalls = 0;
  var commitCalls = 0;
  var switchCalls = 0;
  var fetchCalls = 0;
  var restoreCalls = 0;
  final diffRequests = <(String, bool)>[];
  final diffOriginalPaths = <String?>[];
  final untrackedDiffRequests = <String>[];
  var indexContent = '# Indexed\n';
  var workingTreeContent = '# Working tree\n';
  String? lastDetectedWorkspacePath;
  String? lastInitializeRootPath;
  String? lastHistoryPath;
  String? lastCommitDetailsPath;

  bool get staged => _staged;

  static const repo = GitRepositoryInfo(
    rootPath: '/repo',
    gitDirPath: '/repo/.git',
  );

  @override
  bool get requiresWorkspaceTrust => false;

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
    lastDetectedWorkspacePath = workspacePath;
    return repo;
  }

  @override
  Future<GitStatusSnapshot> status(GitRepositoryInfo repository) async {
    statusCalls += 1;
    if (failStatus) {
      throw const GitFailure(
        code: GitFailureCode.commandFailed,
        userMessageKey: 'gitErrorCommandFailed',
        rawMessage: 'status failed',
        commandName: 'status',
      );
    }
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
  Future<List<GitFileHistoryEntry>> fileHistory(
    GitRepositoryInfo repository,
    String repoRelativePath, {
    int limit = 200,
    int skip = 0,
  }) async {
    lastHistoryPath = repoRelativePath;
    if (skip > 0) {
      return const [];
    }
    return [
      GitFileHistoryEntry(
        commit: _commitSummary('1234567890abcdef', 'Update docs'),
        pathAtCommit: repoRelativePath,
        pathInParent: repoRelativePath,
        status: GitDiffFileStatus.modified,
      ),
    ];
  }

  @override
  Future<GitDiff> diffFile(
    GitRepositoryInfo repository,
    String repoRelativePath, {
    required bool staged,
    String? originalRepoRelativePath,
  }) async {
    diffRequests.add((repoRelativePath, staged));
    diffOriginalPaths.add(originalRepoRelativePath);
    return const GitDiff(
      title: 'README.md',
      files: [],
      rawPatch: '',
      hasBinaryFiles: false,
    );
  }

  @override
  Future<GitDiff> diffUntrackedFile(
    GitRepositoryInfo repository,
    String repoRelativePath,
  ) async {
    untrackedDiffRequests.add(repoRelativePath);
    return GitDiff(
      title: repoRelativePath,
      files: [_diffFile(repoRelativePath)],
      rawPatch: '',
      hasBinaryFiles: false,
      fileSnapshots: {repoRelativePath: '# Untracked\n'},
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
  Future<String?> readFileAtCommit(
    GitRepositoryInfo repository,
    String hash,
    String repoRelativePath,
  ) async => '# $repoRelativePath\n';

  @override
  Future<GitHistoricalFileComparison> compareFileWithParent(
    GitRepositoryInfo repository,
    String hash, {
    String? oldPath,
    String? newPath,
  }) async {
    final path = newPath ?? oldPath!;
    final file = GitDiffFile(
      oldPath: oldPath,
      newPath: newPath,
      status: newPath == null
          ? GitDiffFileStatus.deleted
          : oldPath == null
          ? GitDiffFileStatus.added
          : oldPath != newPath
          ? GitDiffFileStatus.renamed
          : GitDiffFileStatus.modified,
      hunks: const [],
      binary: false,
      additions: 1,
      deletions: 1,
    );
    final diff = GitDiff(
      title: path,
      files: [file],
      rawPatch: '',
      hasBinaryFiles: false,
      fileSnapshots: {path: '# Full revision text\n'},
    );
    return GitHistoricalFileComparison(
      oldPath: oldPath,
      newPath: newPath,
      oldContent: oldPath == null ? '' : '# Before\n',
      newContent: newPath == null ? '' : '# Full revision text\n',
      diff: diff,
    );
  }

  @override
  Future<GitHistoricalFileComparison> compareFileWithWorkingTree(
    GitRepositoryInfo repository,
    String hash, {
    required String historicalPath,
    required String currentPath,
  }) {
    return compareFileWithParent(
      repository,
      hash,
      oldPath: historicalPath,
      newPath: currentPath,
    );
  }

  @override
  Future<GitOperationResult> restoreFileFromCommit(
    GitRepositoryInfo repository,
    String hash, {
    required String historicalPath,
    required String currentPath,
  }) async {
    restoreCalls += 1;
    workingTreeContent = '# Restored\n';
    return _result();
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
  Future<GitOperationResult> fetch(GitRepositoryInfo repository) async {
    fetchCalls += 1;
    return _result();
  }

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
  Future<GitOperationResult> initializeRepository(String rootPath) async {
    lastInitializeRootPath = rootPath;
    return _result();
  }

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

class _TrustRequiredFakeGitGateway extends _FakeGitGateway {
  _TrustRequiredFakeGitGateway({super.failStatus});

  @override
  bool get requiresWorkspaceTrust => true;
}

class _DeferredDetectGitGateway extends _FakeGitGateway {
  final _detectCompleters = <String, Completer<GitRepositoryInfo?>>{};

  static GitRepositoryInfo repo(String rootPath) {
    return GitRepositoryInfo(rootPath: rootPath, gitDirPath: '$rootPath/.git');
  }

  @override
  Future<GitRepositoryInfo?> detectRepository(String workspacePath) {
    detectCalls++;
    return _detectCompleters
        .putIfAbsent(workspacePath, Completer<GitRepositoryInfo?>.new)
        .future;
  }

  void completeDetect(String workspacePath, GitRepositoryInfo? repository) {
    final completer = _detectCompleters.putIfAbsent(
      workspacePath,
      Completer<GitRepositoryInfo?>.new,
    );
    if (!completer.isCompleted) {
      completer.complete(repository);
    }
  }

  @override
  Future<GitStatusSnapshot> status(GitRepositoryInfo repository) async {
    return GitStatusSnapshot(
      repositoryInfo: repository,
      files: [
        GitFileStatus(
          repoRelativePath: 'README.md',
          absolutePath: '${repository.rootPath}/README.md',
          indexStatus: GitFileChangeStatus.unmodified,
          workTreeStatus: GitFileChangeStatus.modified,
          category: GitFileStatusCategory.modified,
          staged: false,
          unstaged: true,
          untracked: false,
          deleted: false,
          renamed: false,
          copied: false,
          conflicted: false,
          ignored: false,
        ),
      ],
    );
  }
}

class _DeferredHistoryGitGateway extends _FakeGitGateway {
  final historyStarted = Completer<void>();
  final historyResult = Completer<List<GitCommitSummary>>();

  @override
  Future<GitRepositoryInfo?> detectRepository(String workspacePath) async {
    return GitRepositoryInfo(
      rootPath: workspacePath,
      gitDirPath: '$workspacePath/.git',
    );
  }

  @override
  Future<GitStatusSnapshot> status(GitRepositoryInfo repository) async {
    return GitStatusSnapshot(repositoryInfo: repository, files: const []);
  }

  @override
  Future<List<GitCommitSummary>> history(
    GitRepositoryInfo repository, {
    String? repoRelativePath,
    int limit = 200,
    int skip = 0,
  }) {
    if (!historyStarted.isCompleted) {
      historyStarted.complete();
    }
    return historyResult.future;
  }
}

class _DeferredSetUpstreamPushGitGateway extends _FakeGitGateway {
  final remotesStarted = Completer<void>();
  final remotesResult = Completer<List<String>>();
  final setUpstreamPushes =
      <({String rootPath, String remote, String branch})>[];
  GitRepositoryInfo? remotesRepository;

  @override
  Future<GitRepositoryInfo?> detectRepository(String workspacePath) async {
    return GitRepositoryInfo(
      rootPath: workspacePath,
      gitDirPath: '$workspacePath/.git',
      currentBranch: workspacePath == '/repo' ? 'branch-a' : 'branch-b',
      hasRemote: true,
    );
  }

  @override
  Future<GitStatusSnapshot> status(GitRepositoryInfo repository) async {
    return GitStatusSnapshot(repositoryInfo: repository, files: const []);
  }

  @override
  Future<List<String>> remotes(GitRepositoryInfo repository) {
    remotesRepository = repository;
    if (!remotesStarted.isCompleted) {
      remotesStarted.complete();
    }
    return remotesResult.future;
  }

  @override
  Future<GitOperationResult> pushSetUpstream(
    GitRepositoryInfo repository,
    String remote,
    String branch,
  ) async {
    setUpstreamPushes.add((
      rootPath: repository.rootPath,
      remote: remote,
      branch: branch,
    ));
    return _result();
  }
}

GitCommitSummary _commitSummary(String hash, String subject) {
  return GitCommitSummary(
    fullHash: hash,
    shortHash: hash.substring(0, 7),
    authorName: 'BusyMark Test',
    authorEmail: 'busymark@example.com',
    authorDate: DateTime(2026),
    subject: subject,
    parentHashes: const [],
  );
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
