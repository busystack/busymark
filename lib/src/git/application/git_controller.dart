import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:busystack_git/busystack_git.dart' as shared;

import '../../app/app_settings.dart';
import '../../workspace/workspace_controller.dart';
import '../../workspace/workspace_model.dart';
import '../domain/git_models.dart';
import 'git_gateway.dart';
import 'git_workspace_eligibility.dart';
import 'git_use_cases.dart';

final gitRepositoryGatewayProvider = Provider<GitRepositoryGateway>(
  (ref) => const UnavailableGitRepositoryGateway(),
);

final gitControllerProvider = NotifierProvider<GitController, GitState>(
  GitController.new,
);

class GitStagedDiffSnapshot {
  const GitStagedDiffSnapshot({required this.patch, required this.fingerprint});

  final String patch;
  final String fingerprint;
}

class GitState {
  const GitState({
    this.availability = const GitAvailability.unavailable(),
    this.repositoryInfo,
    this.statusSnapshot,
    this.requiresWorkspaceTrust = false,
    this.isRefreshing = false,
    this.lastError,
    this.attachedWorkspace,
  });

  final GitAvailability availability;
  final GitRepositoryInfo? repositoryInfo;
  final GitStatusSnapshot? statusSnapshot;
  final bool requiresWorkspaceTrust;
  final bool isRefreshing;
  final GitFailure? lastError;
  final Workspace? attachedWorkspace;

  bool get isRepository => repositoryInfo != null;

  GitState copyWith({
    GitAvailability? availability,
    Object? repositoryInfo = _unset,
    Object? statusSnapshot = _unset,
    bool? requiresWorkspaceTrust,
    bool? isRefreshing,
    Object? lastError = _unset,
    Object? attachedWorkspace = _unset,
  }) => GitState(
    availability: availability ?? this.availability,
    repositoryInfo: identical(repositoryInfo, _unset)
        ? this.repositoryInfo
        : repositoryInfo as GitRepositoryInfo?,
    statusSnapshot: identical(statusSnapshot, _unset)
        ? this.statusSnapshot
        : statusSnapshot as GitStatusSnapshot?,
    requiresWorkspaceTrust:
        requiresWorkspaceTrust ?? this.requiresWorkspaceTrust,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    lastError: identical(lastError, _unset)
        ? this.lastError
        : lastError as GitFailure?,
    attachedWorkspace: identical(attachedWorkspace, _unset)
        ? this.attachedWorkspace
        : attachedWorkspace as Workspace?,
  );
}

class GitController extends Notifier<GitState> {
  static const _refreshDebounce = Duration(milliseconds: 350);

  late GitRepositoryGateway _gateway;
  final _validation = const GitValidation();
  Timer? _debounce;
  StreamSubscription<void>? _repositoryWatch;
  var _refreshEpoch = 0;
  var _workspaceEpoch = 0;
  var _attachmentEpoch = 0;
  var _isUpdatingWorkspaceTrust = false;
  ({
    String workspaceId,
    String workspacePath,
    String canonicalPath,
    shared.RepositoryId repository,
  })?
  _sharedAssociation;

  ({
    Object owner,
    String workspaceId,
    shared.RepositoryId repository,
    String workspacePath,
    Future<GitStatusSnapshot> Function() refresh,
    Future<GitStatusSnapshot?> Function() current,
    Future<void> Function(List<String>, bool) stage,
  })?
  _sharedStatusSource;

  /// Bind the existing authoring commands to this worktree's shared session.
  /// Callbacks retain their repository identity through asynchronous refreshes.
  bool bindSharedStatusSource(
    Workspace workspace,
    shared.RepositoryId repository, {
    Object? owner,
    required Future<GitStatusSnapshot> Function() refresh,
    required Future<GitStatusSnapshot?> Function() current,
    required Future<void> Function(List<String>, bool) stage,
  }) {
    if (workspace.isRemote ||
        state.attachedWorkspace?.id != workspace.id ||
        _sharedAssociation?.repository.key != repository.key) {
      return false;
    }
    _refreshEpoch++;
    _debounce?.cancel();
    _stopRepositoryWatch();
    _sharedStatusSource = (
      owner: owner ?? refresh,
      workspaceId: workspace.id,
      repository: repository,
      workspacePath: workspace.rootPath,
      refresh: refresh,
      current: current,
      stage: stage,
    );
    return true;
  }

  void releaseSharedStatusSource(Object owner) {
    if (!ref.mounted || !identical(_sharedStatusSource?.owner, owner)) return;
    _sharedStatusSource = null;
    _refreshEpoch++;
    _scheduleRefresh(immediate: true);
  }

  Future<void> refreshFromSharedSnapshot({bool refresh = false}) async {
    final source = _sharedStatusSource, workspace = state.attachedWorkspace;
    if (source == null ||
        workspace == null ||
        source.workspaceId != workspace.id ||
        workspace.isRemote ||
        source.workspacePath != workspace.rootPath ||
        _sharedAssociation?.repository.key != source.repository.key) {
      return;
    }
    final epoch = ++_refreshEpoch;
    _debounce?.cancel();
    try {
      final status = await (refresh ? source.refresh() : source.current());
      if (status == null ||
          !_isCurrentRefresh(workspace.id, epoch) ||
          source != _sharedStatusSource) {
        return;
      }
      final info = status.repositoryInfo;
      if (info.rootPath != source.repository.root ||
          info.gitDirPath != source.repository.gitDir ||
          info.identityKey != source.repository.key) {
        throw const shared.GitException(shared.GitErrorCode.staleReview);
      }
      final settings = ref.read(appSettingsControllerProvider);
      final trusted =
          settings.trustsGitWorkspace(workspace.rootPath) ||
          _hasRepositoryGrant(workspace, settings);
      if (identical(state.statusSnapshot, status) &&
          state.requiresWorkspaceTrust == !trusted &&
          !state.isRefreshing) {
        return;
      }
      state = state.copyWith(
        availability: const GitAvailability(available: true),
      );
      _applyStatus(status, workspace, requiresTrust: !trusted);
    } on Object catch (error) {
      if (_isCurrentRefresh(workspace.id, epoch) &&
          source == _sharedStatusSource) {
        _setFailure(error, commandName: 'status');
        state = state.copyWith(isRefreshing: false);
      }
    }
  }

  /// Bind authoring commands only to the opened working-tree root. Shared
  /// discovery may find an ancestor, which is ineligible in BusyMark.
  Future<void> associateSharedRepository(
    Workspace workspace,
    shared.RepositoryId repository,
  ) async {
    if (!ref.mounted || workspace.isRemote) return;
    final ownerEpoch = _attachmentEpoch;
    String canonical;
    try {
      canonical = await requireGitWorkspaceRoot(
        workspace.rootPath,
        repository.root,
        bare: repository.bare,
      );
    } on FileSystemException {
      if (!ref.mounted) return;
      throw const shared.GitException(shared.GitErrorCode.unsafePath);
    }
    if (!ref.mounted ||
        ownerEpoch != _attachmentEpoch ||
        state.attachedWorkspace?.id != workspace.id ||
        workspace.isRemote ||
        !p.equals(canonical, repository.root)) {
      return;
    }
    final previousKey =
        _sharedAssociation?.repository.key ?? state.repositoryInfo?.identityKey;
    if (previousKey != null && previousKey != repository.key) {
      _workspaceEpoch++;
      _refreshEpoch++;
    }
    _sharedAssociation = (
      workspaceId: workspace.id,
      workspacePath: workspace.rootPath,
      canonicalPath: canonical,
      repository: repository,
    );
    // The shared session supplies the first status. A second legacy scan here
    // would compete with opening Commit and continue after its operation ends.
    _refreshEpoch++;
    _debounce?.cancel();
  }

  bool _hasRepositoryGrant(Workspace workspace, AppSettings settings) {
    final association = _sharedAssociation;
    return association != null &&
        association.workspaceId == workspace.id &&
        association.workspacePath == workspace.rootPath &&
        settings.trustsGitWorkspace(association.repository.root);
  }

  @override
  GitState build() {
    _gateway = ref.read(gitRepositoryGatewayProvider);
    ref.listen(appSettingsControllerProvider, (previous, next) {
      if (!_gateway.requiresWorkspaceTrust || _isUpdatingWorkspaceTrust) {
        return;
      }
      final workspace = state.attachedWorkspace;
      if (workspace == null) {
        return;
      }
      final wasTrusted =
          previous != null &&
          (previous.trustsGitWorkspace(workspace.rootPath) ||
              _hasRepositoryGrant(workspace, previous));
      final isTrusted =
          next.trustsGitWorkspace(workspace.rootPath) ||
          _hasRepositoryGrant(workspace, next);
      if (wasTrusted != isTrusted) {
        if (!isTrusted) {
          _setWorkspaceTrustRequiredState();
        }
        final source = _sharedStatusSource;
        if (source != null &&
            source.workspaceId == workspace.id &&
            !workspace.isRemote &&
            source.workspacePath == workspace.rootPath &&
            _sharedAssociation?.repository.key == source.repository.key) {
          // Trust changes authorization, not Git contents. Reuse the passive
          // snapshot without queuing a second scan over the active operation.
          unawaited(refreshFromSharedSnapshot());
        } else {
          _scheduleRefresh(immediate: true);
        }
      }
    });
    final files = ref.read(workspaceFileMonitorProvider).events.listen((event) {
      final root = state.attachedWorkspace?.filesystemRootPath;
      if (_sharedStatusSource == null &&
          _repositoryWatch == null &&
          root != null &&
          (p.equals(root, event.path) || p.isWithin(root, event.path))) {
        _scheduleRefresh();
      }
    });
    ref.onDispose(() {
      _debounce?.cancel();
      _stopRepositoryWatch();
      unawaited(files.cancel());
    });
    return const GitState();
  }

  void attachWorkspace(Workspace workspace) {
    final changedOwner =
        state.attachedWorkspace?.id != workspace.id ||
        state.attachedWorkspace?.rootPath != workspace.rootPath ||
        state.attachedWorkspace?.kind != workspace.kind;
    if (!changedOwner) return;
    _stopRepositoryWatch();
    _attachmentEpoch++;
    _workspaceEpoch++;
    _sharedAssociation = null;
    _sharedStatusSource = null;
    if (workspace.isRemote) {
      _debounce?.cancel();
      state = const GitState();
      return;
    }
    if (_gateway is UnavailableGitRepositoryGateway) {
      _debounce?.cancel();
      state = _workspaceResetState(
        workspace,
        availability: const GitAvailability.unavailable(
          'Git gateway is not configured.',
        ),
      );
      return;
    }
    if (workspace.kind == WorkspaceKind.nextcloudNotes ||
        workspace.kind == WorkspaceKind.untitledMarkdown ||
        workspace.kind == WorkspaceKind.singleMarkdown) {
      _debounce?.cancel();
      state = const GitState();
      return;
    }
    _debounce?.cancel();
    state = _workspaceResetState(workspace);
    _scheduleRefresh(immediate: true);
  }

  Future<void> refresh() async {
    final source = _sharedStatusSource;
    if (source != null &&
        source.workspaceId == state.attachedWorkspace?.id &&
        state.attachedWorkspace?.isRemote == false &&
        source.workspacePath == state.attachedWorkspace!.rootPath &&
        _sharedAssociation?.repository.key == source.repository.key) {
      await refreshFromSharedSnapshot(refresh: true);
      return;
    }
    final workspace = state.attachedWorkspace;
    if (workspace == null ||
        workspace.kind == WorkspaceKind.nextcloudNotes ||
        workspace.kind == WorkspaceKind.untitledMarkdown ||
        workspace.kind == WorkspaceKind.singleMarkdown) {
      return;
    }
    final workspaceId = workspace.id;
    final refreshEpoch = ++_refreshEpoch;
    _debounce?.cancel();
    state = state.copyWith(isRefreshing: true, lastError: null);
    final availability = await _gateway.availability();
    if (!_isCurrentRefresh(workspaceId, refreshEpoch)) {
      return;
    }
    state = state.copyWith(availability: availability);
    if (!availability.available) {
      _stopRepositoryWatch();
      state = state.copyWith(
        isRefreshing: false,
        requiresWorkspaceTrust: false,
        repositoryInfo: null,
        statusSnapshot: null,
      );
      return;
    }
    if (_gateway case final GitWorkspaceRootInspector inspector) {
      try {
        await inspector.requireWorkspaceRoot(workspace.rootPath);
      } on Object catch (error) {
        if (!_isCurrentRefresh(workspaceId, refreshEpoch)) return;
        state = _workspaceResetState(workspace);
        _setFailure(error, commandName: 'discover');
        return;
      }
      if (!_isCurrentRefresh(workspaceId, refreshEpoch)) return;
    }
    final trustedWorkspacePath = _trustedWorkspaceGitPath(workspace);
    if (trustedWorkspacePath == null) {
      _setWorkspaceTrustRequiredState();
      return;
    }
    state = state.copyWith(requiresWorkspaceTrust: false);
    try {
      final repository = await _gateway.detectRepository(trustedWorkspacePath);
      if (!_isCurrentRefresh(workspaceId, refreshEpoch)) {
        return;
      }
      if (_trustedWorkspaceGitPath(workspace) != trustedWorkspacePath) {
        _setWorkspaceTrustRequiredState();
        return;
      }
      if (repository == null) {
        _stopRepositoryWatch();
        state = state.copyWith(
          isRefreshing: false,
          requiresWorkspaceTrust: false,
          repositoryInfo: null,
          statusSnapshot: null,
        );
        return;
      }
      final association = _sharedAssociation;
      if (!ref
              .read(appSettingsControllerProvider)
              .trustsGitWorkspace(workspace.rootPath) &&
          association != null &&
          _hasRepositoryGrant(
            workspace,
            ref.read(appSettingsControllerProvider),
          ) &&
          (repository.rootPath != association.repository.root ||
              repository.gitDirPath != association.repository.gitDir ||
              repository.identityKey != null &&
                  repository.identityKey != association.repository.key)) {
        _setWorkspaceTrustRequiredState();
        return;
      }
      final previous = state.repositoryInfo;
      if (previous?.identityKey != repository.identityKey ||
          previous?.rootPath != repository.rootPath ||
          previous?.gitDirPath != repository.gitDirPath) {
        _stopRepositoryWatch();
      }
      state = state.copyWith(repositoryInfo: repository);
      final status = await _gateway.status(repository);
      if (!_isCurrentRefresh(workspaceId, refreshEpoch)) {
        return;
      }
      _applyStatus(status, workspace);
      // The shared watcher covers linked-worktree metadata outside the opened
      // directory too. The session takes ownership when a Git view opens.
      _repositoryWatch ??= _gateway
          .watch(repository)
          .listen(
            (_) {
              if (_isCurrentWorkspace(workspaceId) &&
                  _sharedStatusSource == null) {
                _scheduleRefresh();
              }
            },
            onError: (Object error) {
              if (_isCurrentWorkspace(workspaceId) &&
                  _sharedStatusSource == null) {
                _setFailure(error, commandName: 'watch');
              }
            },
          );
    } on Object catch (error) {
      if (!_isCurrentRefresh(workspaceId, refreshEpoch)) {
        return;
      }
      if (error is GitWorkspaceRootRequired) {
        _stopRepositoryWatch();
        _sharedAssociation = null;
        _sharedStatusSource = null;
        state = _workspaceResetState(workspace);
      }
      _setFailure(error, commandName: 'status');
      state = state.copyWith(isRefreshing: false);
    }
  }

  void _applyStatus(
    GitStatusSnapshot status,
    Workspace workspace, {
    bool requiresTrust = false,
  }) {
    state = state.copyWith(
      isRefreshing: false,
      requiresWorkspaceTrust: requiresTrust,
      repositoryInfo: status.repositoryInfo,
      statusSnapshot: status,
      lastError: null,
    );
  }

  Future<void> trustWorkspace() async {
    final workspace = state.attachedWorkspace;
    if (workspace == null ||
        !state.requiresWorkspaceTrust ||
        !_gateway.requiresWorkspaceTrust) {
      return;
    }
    final workspaceId = workspace.id;
    if (_gateway case final GitWorkspaceRootInspector inspector) {
      await inspector.requireWorkspaceRoot(workspace.rootPath);
      if (!_isCurrentWorkspace(workspaceId)) return;
    }
    _isUpdatingWorkspaceTrust = true;
    try {
      await ref
          .read(appSettingsControllerProvider.notifier)
          .trustGitWorkspace(workspace.rootPath);
    } finally {
      _isUpdatingWorkspaceTrust = false;
    }
    if (_isCurrentWorkspace(workspaceId)) {
      await refresh();
    }
  }

  Future<void> stageFiles(List<String> paths) =>
      _stageThroughSession(paths, false);
  Future<void> unstageFiles(List<String> paths) =>
      _stageThroughSession(paths, true);

  Future<void> _stageThroughSession(List<String> paths, bool unstage) async {
    final operation = _captureRepositoryOperation(),
        source = _sharedStatusSource;
    if (operation == null) return;
    final failure = _validation.validateRepoRelativePaths(paths);
    if (failure != null) {
      state = state.copyWith(lastError: failure);
      return;
    }
    if (source == null ||
        source.repository.key != _sharedAssociation?.repository.key) {
      _setFailure(
        const shared.GitException(shared.GitErrorCode.disconnected),
        commandName: 'git',
      );
      return;
    }
    try {
      await source.stage(List.unmodifiable(paths), unstage);
    } on Object catch (error) {
      if (_isCurrentRepositoryOperation(operation)) {
        _setFailure(error, commandName: 'git');
      }
    }
  }

  Future<GitStagedDiffSnapshot?> stagedDiffForAi() async {
    final operation = _captureRepositoryOperation();
    if (operation == null ||
        (state.statusSnapshot?.stagedFiles.isEmpty ?? true)) {
      return null;
    }
    try {
      final patch = await _gateway.stagedPatch(operation.repository);
      if (!_isCurrentRepositoryOperation(operation)) {
        return null;
      }
      if (patch.trim().isEmpty) {
        return null;
      }
      return GitStagedDiffSnapshot(
        patch: patch,
        fingerprint: _stagedDiffFingerprint(patch),
      );
    } on Object catch (error) {
      if (_isCurrentRepositoryOperation(operation)) {
        _setFailure(error, commandName: 'diff');
      }
      return null;
    }
  }

  Future<bool> stagedDiffMatches(String fingerprint) async {
    final operation = _captureRepositoryOperation();
    if (operation == null) {
      return false;
    }
    try {
      final patch = await _gateway.stagedPatch(operation.repository);
      return _isCurrentRepositoryOperation(operation) &&
          patch.trim().isNotEmpty &&
          _stagedDiffFingerprint(patch) == fingerprint;
    } on Object catch (error) {
      if (_isCurrentRepositoryOperation(operation)) {
        _setFailure(error, commandName: 'diff');
      }
      return false;
    }
  }

  String _stagedDiffFingerprint(String patch) =>
      sha256.convert(utf8.encode(patch)).toString();

  void _scheduleRefresh({bool immediate = false}) {
    _debounce?.cancel();
    if (immediate) {
      unawaited(refresh());
      return;
    }
    _debounce = Timer(_refreshDebounce, () => unawaited(refresh()));
  }

  void _setWorkspaceTrustRequiredState() {
    _debounce?.cancel();
    _stopRepositoryWatch();
    _workspaceEpoch++;
    state = state.copyWith(
      isRefreshing: false,
      requiresWorkspaceTrust: true,
      repositoryInfo: null,
      statusSnapshot: null,
      lastError: null,
    );
  }

  void _stopRepositoryWatch() {
    final watch = _repositoryWatch;
    _repositoryWatch = null;
    if (watch != null) unawaited(watch.cancel());
  }

  void _setFailure(Object error, {required String commandName}) {
    final failure = error is GitFailure
        ? error
        : GitFailure(
            code: GitFailureCode.commandFailed,
            userMessageKey: 'gitErrorCommandFailed',
            rawMessage: '$error',
            commandName: commandName,
          );
    state = state.copyWith(lastError: failure);
  }

  GitState _workspaceResetState(
    Workspace workspace, {
    GitAvailability? availability,
  }) {
    return GitState(
      availability: availability ?? state.availability,
      attachedWorkspace: workspace,
      requiresWorkspaceTrust: !_workspaceHasGitTrust(workspace),
    );
  }

  bool _isCurrentWorkspace(String workspaceId) {
    return ref.mounted && state.attachedWorkspace?.id == workspaceId;
  }

  bool _isCurrentRefresh(String workspaceId, int refreshEpoch) {
    return _refreshEpoch == refreshEpoch && _isCurrentWorkspace(workspaceId);
  }

  _GitWorkspaceOperation? _captureWorkspaceOperation() {
    final workspace = state.attachedWorkspace;
    if (workspace == null) {
      return null;
    }
    return _GitWorkspaceOperation(
      workspaceId: workspace.id,
      workspaceEpoch: _workspaceEpoch,
    );
  }

  _GitRepositoryOperation? _captureRepositoryOperation() {
    final workspace = _captureWorkspaceOperation();
    final repository = _trustedRepositoryInfo;
    if (workspace == null || repository == null) {
      return null;
    }
    return _GitRepositoryOperation(
      workspace: workspace,
      repository: repository,
    );
  }

  bool _isCurrentWorkspaceOperation(_GitWorkspaceOperation operation) {
    return _workspaceEpoch == operation.workspaceEpoch &&
        _isCurrentWorkspace(operation.workspaceId);
  }

  bool _isCurrentRepositoryOperation(_GitRepositoryOperation operation) {
    if (!_isCurrentWorkspaceOperation(operation.workspace)) {
      return false;
    }
    final repository = _trustedRepositoryInfo;
    return repository != null &&
        repository.rootPath == operation.repository.rootPath &&
        repository.gitDirPath == operation.repository.gitDirPath &&
        repository.identityKey == operation.repository.identityKey;
  }

  bool _workspaceHasGitTrust(Workspace workspace) {
    return _trustedWorkspaceGitPath(workspace) != null;
  }

  String? _trustedWorkspaceGitPath(Workspace workspace) {
    if (workspace.isRemote) return null;
    if (!_gateway.requiresWorkspaceTrust) {
      return workspace.rootPath;
    }
    final settings = ref.read(appSettingsControllerProvider);
    return settings.trustedGitWorkspacePath(workspace.rootPath) ??
        (_hasRepositoryGrant(workspace, settings)
            ? _sharedAssociation!.canonicalPath
            : null);
  }

  GitRepositoryInfo? get _trustedRepositoryInfo {
    final workspace = state.attachedWorkspace;
    if (workspace == null || !_workspaceHasGitTrust(workspace)) {
      return null;
    }
    final repository = state.repositoryInfo, association = _sharedAssociation;
    if (!ref
            .read(appSettingsControllerProvider)
            .trustsGitWorkspace(workspace.rootPath) &&
        association != null &&
        repository != null &&
        (repository.rootPath != association.repository.root ||
            repository.gitDirPath != association.repository.gitDir ||
            repository.identityKey != null &&
                repository.identityKey != association.repository.key)) {
      return null;
    }
    return state.repositoryInfo;
  }
}

class _GitWorkspaceOperation {
  const _GitWorkspaceOperation({
    required this.workspaceId,
    required this.workspaceEpoch,
  });

  final String workspaceId;
  final int workspaceEpoch;
}

class _GitRepositoryOperation {
  const _GitRepositoryOperation({
    required this.workspace,
    required this.repository,
  });

  final _GitWorkspaceOperation workspace;
  final GitRepositoryInfo repository;
}

class UnavailableGitRepositoryGateway implements GitRepositoryGateway {
  const UnavailableGitRepositoryGateway();

  @override
  bool get requiresWorkspaceTrust => false;

  @override
  Future<GitAvailability> availability() async {
    return const GitAvailability.unavailable('Git gateway is not configured.');
  }

  @override
  Future<GitRepositoryInfo?> detectRepository(String workspacePath) async =>
      null;

  @override
  Future<GitStatusSnapshot> status(GitRepositoryInfo repository) =>
      _unavailable();

  @override
  Stream<void> watch(GitRepositoryInfo repository) => _unavailable();

  @override
  Future<String> stagedPatch(GitRepositoryInfo repository) => _unavailable();

  Never _unavailable() {
    throw const GitFailure(
      code: GitFailureCode.unavailable,
      userMessageKey: 'gitErrorUnavailable',
      rawMessage: 'Git is unavailable.',
      commandName: 'git',
    );
  }
}

const Object _unset = Object();
