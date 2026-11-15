import 'dart:async';
import 'dart:io';

import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/git/application/git_controller.dart';
import 'package:busymark/src/git/application/git_gateway.dart';
import 'package:busymark/src/git/application/git_workspace_eligibility.dart';
import 'package:busymark/src/git/domain/git_models.dart';
import 'package:busymark/src/local_history/local_history_controller.dart';
import 'package:busymark/src/local_history/local_history_store.dart';
import 'package:busymark/src/workspace/workspace_controller.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:busymark/src/workspace/workspace_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:busystack_git/busystack_git.dart' as shared;

void main() {
  test(
    'attachment ignores editor publications; Files-only disk changes refresh status',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'busymark-git-files-watch-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final root = await directory.resolveSymbolicLinks();
      await Directory('$root/.git').create();
      final index = await File('$root/.git/index').writeAsString('initial');
      final repository = shared.RepositoryId(
        root: root,
        gitDir: '$root/.git',
        commonDir: '$root/.git',
        objectFormat: 'sha1',
        filesystemToken: 'fixture',
      );
      final gateway = _AssociatedGitGateway(repository);
      final container = _container(gateway);
      await container
          .read(appSettingsControllerProvider.notifier)
          .waitUntilLoaded();
      await container
          .read(appSettingsControllerProvider.notifier)
          .trustGitWorkspace(root);
      final controller = container.read(gitControllerProvider.notifier);
      final workspace = _workspace(id: root, rootPath: root);
      controller.attachWorkspace(workspace);
      await controller.refresh();
      final scans = gateway.statusCalls;
      for (var i = 0; i < 10; i++) {
        controller.attachWorkspace(
          workspace.copyWith(activeFilePath: '$root/doc$i.md'),
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(gateway.statusCalls, scans);
      final monitor = container.read(workspaceFileMonitorProvider);
      await monitor.start(rootPath: root, openFilePaths: const []);
      await index.writeAsString('external index change');
      final timeout = DateTime.now().add(const Duration(seconds: 5));
      while (gateway.statusCalls == scans && DateTime.now().isBefore(timeout)) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      expect(gateway.statusCalls, greaterThan(scans));
      expect(
        container.read(gitControllerProvider).repositoryInfo!.rootPath,
        root,
      );
      await monitor.stop();
    },
  );

  test(
    'shared status serves authoring refresh without another repository scan',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'busymark-shared-status-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final root = await directory.resolveSymbolicLinks();
      final repository = shared.RepositoryId(
        root: root,
        gitDir: '$root/.git',
        commonDir: '$root/.git',
        objectFormat: 'sha1',
        filesystemToken: 'shared',
      );
      final gateway = _AssociatedGitGateway(repository);
      final container = _container(gateway);
      final controller = container.read(gitControllerProvider.notifier);
      final workspace = _workspace(id: root, rootPath: root);
      controller.attachWorkspace(workspace);
      await controller.associateSharedRepository(workspace, repository);
      GitStatusSnapshot snapshot() => GitStatusSnapshot(
        repositoryInfo: GitRepositoryInfo(
          rootPath: root,
          gitDirPath: '$root/.git',
          identityKey: repository.key,
        ),
        files: const [],
      );
      var latest = snapshot(), refreshes = 0, projections = 0;
      expect(
        controller.bindSharedStatusSource(
          workspace,
          repository,
          stage: (_, _) async => throw StateError('Unexpected staging'),
          refresh: () async {
            refreshes++;
            return latest;
          },
          current: () async {
            projections++;
            return latest;
          },
        ),
        isTrue,
      );
      await controller.refresh();
      expect(refreshes, 1);
      expect(gateway.detectCalls, 0);
      expect(gateway.statusCalls, 0);
      expect(
        container.read(gitControllerProvider).requiresWorkspaceTrust,
        isTrue,
        reason:
            'Sharing passive data does not grant executable repository trust.',
      );
      latest = snapshot();
      await controller.refreshFromSharedSnapshot();
      expect(projections, 1);
      expect(
        refreshes,
        1,
        reason: 'A reconciled operation already has its snapshot.',
      );
      expect(
        container.read(gitControllerProvider).statusSnapshot,
        same(latest),
      );
      expect(gateway.detectCalls, 0);
      expect(gateway.statusCalls, 0);
      final beforeTrustRefreshes = refreshes;
      await container
          .read(appSettingsControllerProvider.notifier)
          .trustGitWorkspace(root);
      await Future<void>.delayed(Duration.zero);
      expect(
        refreshes,
        beforeTrustRefreshes,
        reason: 'Granting trust must not queue another working-tree scan.',
      );
      await controller.refresh();
      expect(
        container.read(gitControllerProvider).requiresWorkspaceTrust,
        isFalse,
      );
      await container
          .read(appSettingsControllerProvider.notifier)
          .revokeGitWorkspaceTrust(root);
      await controller.refreshFromSharedSnapshot();
      expect(
        container.read(gitControllerProvider).requiresWorkspaceTrust,
        isTrue,
      );
      await controller.stageFiles(['README.md']);
      expect(gateway.stageCalls, 0);
    },
  );

  test(
    'late shared status cannot target a different authoring workspace',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'busymark-late-shared-status-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final root = await directory.resolveSymbolicLinks();
      final repository = shared.RepositoryId(
        root: root,
        gitDir: '$root/.git',
        commonDir: '$root/.git',
        objectFormat: 'sha1',
        filesystemToken: 'shared',
      );
      final gateway = _AssociatedGitGateway(repository);
      final container = _container(gateway);
      final controller = container.read(gitControllerProvider.notifier);
      final workspace = _workspace(id: root, rootPath: root);
      controller.attachWorkspace(workspace);
      await controller.associateSharedRepository(workspace, repository);
      final waiting = Completer<GitStatusSnapshot>();
      final status = GitStatusSnapshot(
        repositoryInfo: GitRepositoryInfo(
          rootPath: root,
          gitDirPath: '$root/.git',
          identityKey: repository.key,
        ),
        files: const [],
      );
      expect(
        controller.bindSharedStatusSource(
          workspace,
          repository,
          stage: (_, _) async => throw StateError('Unexpected staging'),
          refresh: () => waiting.future,
          current: () => waiting.future,
        ),
        isTrue,
      );
      final pending = controller.refresh();
      controller.attachWorkspace(
        _workspace(id: 'another-workspace', rootPath: root),
      );
      waiting.complete(status);
      await pending;
      expect(
        container.read(gitControllerProvider).attachedWorkspace!.id,
        'another-workspace',
      );
      expect(container.read(gitControllerProvider).statusSnapshot, isNull);
      expect(gateway.statusCalls, 0);
    },
  );

  test('shared status rejects a substituted repository identity', () async {
    final directory = await Directory.systemTemp.createTemp(
      'busymark-shared-substitution-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final root = await directory.resolveSymbolicLinks();
    final repository = shared.RepositoryId(
      root: root,
      gitDir: '$root/.git',
      commonDir: '$root/.git',
      objectFormat: 'sha1',
      filesystemToken: 'shared',
    );
    final gateway = _AssociatedGitGateway(repository);
    final container = _container(gateway);
    final controller = container.read(gitControllerProvider.notifier);
    final workspace = _workspace(id: root, rootPath: root);
    controller.attachWorkspace(workspace);
    await controller.associateSharedRepository(workspace, repository);
    final status = GitStatusSnapshot(
      repositoryInfo: GitRepositoryInfo(
        rootPath: '$root/other',
        gitDirPath: '$root/other/.git',
        identityKey: 'other',
      ),
      files: const [],
    );
    expect(
      controller.bindSharedStatusSource(
        workspace,
        repository,
        stage: (_, _) async => throw StateError('Unexpected staging'),
        refresh: () async => status,
        current: () async => status,
      ),
      isTrue,
    );
    await controller.refresh();
    expect(container.read(gitControllerProvider).repositoryInfo, isNull);
    expect(container.read(gitControllerProvider).lastError, isNotNull);
    expect(gateway.detectCalls, 0);
    expect(gateway.statusCalls, 0);
  });

  test(
    'an ancestor grant cannot attach or authorize descendant workspace commands',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'busymark-git-scope-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final docs = await Directory('${directory.path}/docs').create();
      final root = await directory.resolveSymbolicLinks();
      final repository = shared.RepositoryId(
        root: root,
        gitDir: '$root/.git',
        commonDir: '$root/.git',
        objectFormat: 'sha1',
        filesystemToken: 'parent',
      );
      final gateway = _AssociatedGitGateway(repository);
      final container = _container(gateway);
      final controller = container.read(gitControllerProvider.notifier);
      final workspace = _workspace(id: docs.path, rootPath: docs.path);
      controller.attachWorkspace(workspace);
      await expectLater(
        controller.associateSharedRepository(workspace, repository),
        throwsA(isA<GitWorkspaceRootRequired>()),
      );
      await container
          .read(appSettingsControllerProvider.notifier)
          .trustGitWorkspace(root);
      await controller.refresh();
      await controller.stageFiles(['README.md']);
      expect(gateway.stageCalls, 0);
      expect(gateway.statusCalls, 0);
      expect(container.read(gitControllerProvider).repositoryInfo, isNull);
      expect(
        container
            .read(appSettingsControllerProvider)
            .trustsGitWorkspace(docs.path),
        isFalse,
      );
    },
  );

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

  test('does not expose repository Git for a single Markdown file', () async {
    final gateway = _FakeGitGateway();
    final container = _container(gateway);
    final controller = container.read(gitControllerProvider.notifier);

    controller.attachWorkspace(
      _workspace(
        kind: WorkspaceKind.singleMarkdown,
        activeFilePath: '/repo/README.md',
      ),
    );
    await Future<void>.delayed(Duration.zero);
    await controller.refresh();

    expect(gateway.detectCalls, 0);
    expect(gateway.statusCalls, 0);
    expect(container.read(gitControllerProvider).repositoryInfo, isNull);
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

  test('Git executes with the canonical path that was trusted', () async {
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
    final trustedDetectCalls = gateway.detectCalls;
    await workspaceLink.delete();
    await workspaceLink.create(replacement.path);

    await controller.refresh();

    expect(gateway.detectCalls, trustedDetectCalls);
    expect(
      container.read(gitControllerProvider).requiresWorkspaceTrust,
      isTrue,
    );
  }, skip: Platform.isWindows);

  test(
    'Files Stage cannot fall back to a gateway without a canonical session',
    () async {
      final gateway = _FakeGitGateway();
      final container = _container(gateway);
      final controller = container.read(gitControllerProvider.notifier);
      controller.attachWorkspace(_workspace());
      await controller.refresh();
      await controller.stageFiles(['README.md']);
      await controller.unstageFiles(['README.md']);
      expect(gateway.staged, isFalse);
      expect(container.read(gitControllerProvider).lastError, isNotNull);
    },
  );

  test(
    'Files Stage and Unstage project the captured session result and reconcile comparison selection',
    () async {
      final folder = await Directory.systemTemp.createTemp(
        'files-session-adapter-',
      );
      addTearDown(() => folder.delete(recursive: true));
      final root = await folder.resolveSymbolicLinks();
      final repository = shared.RepositoryId(
        root: root,
        gitDir: '$root/.git',
        commonDir: '$root/.git',
        objectFormat: 'sha1',
      );
      final gateway = _AssociatedGitGateway(repository);
      final container = _container(gateway);
      await container
          .read(appSettingsControllerProvider.notifier)
          .trustGitWorkspace(root);
      final controller = container.read(gitControllerProvider.notifier);
      final workspace = _workspace(id: root, rootPath: root);
      controller.attachWorkspace(workspace);
      await controller.associateSharedRepository(workspace, repository);
      var staged = false;
      final requests = <(List<String>, bool)>[];
      Future<GitStatusSnapshot> current() async => GitStatusSnapshot(
        repositoryInfo: GitRepositoryInfo(
          rootPath: root,
          gitDirPath: repository.gitDir,
          identityKey: repository.key,
        ),
        files: [gateway._file(staged: staged, unstaged: !staged)],
      );
      controller.bindSharedStatusSource(
        workspace,
        repository,
        current: current,
        refresh: current,
        stage: (paths, unstage) async {
          requests.add((paths, unstage));
          staged = !unstage;
          await controller.refreshFromSharedSnapshot();
        },
      );
      await controller.refreshFromSharedSnapshot();
      final scansBeforeStaging = gateway.statusCalls;
      await controller.stageFiles(['README.md']);
      expect(
        container
            .read(gitControllerProvider)
            .statusSnapshot!
            .stagedFiles
            .single
            .repoRelativePath,
        'README.md',
      );
      await controller.unstageFiles(['README.md']);
      expect(
        container
            .read(gitControllerProvider)
            .statusSnapshot!
            .unstagedFiles
            .single
            .repoRelativePath,
        'README.md',
      );
      expect(requests.map((r) => r.$2), [false, true]);
      expect(gateway.stageCalls, 0);
      expect(gateway.statusCalls, scansBeforeStaging);
    },
  );

  test('AI staged-diff fingerprint rejects obsolete commit context', () async {
    final gateway = _FakeGitGateway(staged: true)
      ..stagedRawPatch = 'diff --git a/a.md b/a.md\n+first\n';
    final container = _container(gateway);
    final controller = container.read(gitControllerProvider.notifier);
    controller.attachWorkspace(_workspace());
    await controller.refresh();

    final snapshot = await controller.stagedDiffForAi();

    expect(snapshot, isNotNull);
    expect(snapshot!.patch, gateway.stagedRawPatch);
    expect(await controller.stagedDiffMatches(snapshot.fingerprint), isTrue);

    gateway.stagedRawPatch = 'diff --git a/a.md b/a.md\n+second\n';

    expect(await controller.stagedDiffMatches(snapshot.fingerprint), isFalse);
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

  test('reports disconnected Files staging', () async {
    final gateway = _FakeGitGateway();
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
  });

  test('clears previous workspace Git state immediately on attach', () async {
    final gateway = _FakeGitGateway();
    final container = _container(gateway);
    final controller = container.read(gitControllerProvider.notifier);
    controller.attachWorkspace(_workspace(activeFilePath: '/repo/README.md'));
    await controller.refresh();
    await controller.stageFiles(['../outside.md']);

    controller.attachWorkspace(_workspace(id: '/other', rootPath: '/other'));

    final state = container.read(gitControllerProvider);
    expect(state.attachedWorkspace?.id, '/other');
    expect(state.repositoryInfo, isNull);
    expect(state.statusSnapshot, isNull);
    expect(state.lastError, isNull);
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
}

ProviderContainer _container(
  GitRepositoryGateway gateway, {
  LocalHistoryStore? historyStore,
}) {
  final container = ProviderContainer(
    overrides: [
      gitRepositoryGatewayProvider.overrideWithValue(gateway),
      localSettingsStoreProvider.overrideWithValue(_MemorySettingsStore()),
      if (historyStore != null)
        localHistoryStoreProvider.overrideWithValue(historyStore),
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
  WorkspaceKind kind = WorkspaceKind.markdownFolder,
}) {
  return Workspace(
    id: id,
    rootPath: rootPath,
    kind: kind,
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
    this.failStatus = false,
  }) : _staged = staged;

  final bool conflicted;
  final bool failStatus;
  final bool _staged;
  var detectCalls = 0;
  var statusCalls = 0;
  var stagedRawPatch = 'diff --git a/README.md b/README.md\n+staged\n';
  String? lastDetectedWorkspacePath;

  bool get staged => _staged;
  @override
  Future<String> stagedPatch(GitRepositoryInfo repository) async =>
      stagedRawPatch;

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
    return GitStatusSnapshot(repositoryInfo: repo, files: files);
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

class _AssociatedGitGateway extends _TrustRequiredFakeGitGateway {
  _AssociatedGitGateway(this.repository);
  shared.RepositoryId repository;
  var stageCalls = 0;
  @override
  Future<GitRepositoryInfo?> detectRepository(String workspacePath) async {
    detectCalls++;
    return GitRepositoryInfo(
      rootPath: repository.root,
      gitDirPath: repository.gitDir,
      identityKey: repository.key,
    );
  }

  @override
  Future<GitStatusSnapshot> status(GitRepositoryInfo repository) async {
    final value = await super.status(repository);
    return GitStatusSnapshot(repositoryInfo: repository, files: value.files);
  }
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

class _MemorySettingsStore implements LocalSettingsStore {
  @override
  Future<Map<String, Object?>> load() async => <String, Object?>{};

  @override
  Future<void> save(Map<String, Object?> json) async {}
}
