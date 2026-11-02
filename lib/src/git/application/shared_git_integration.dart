import '../../app/busymark_toast.dart';
import '../../platform/native_menu_service.dart';
export 'shared_git_tabs.dart';
import 'shared_git_tabs.dart';
import 'shared_git_localizations.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:busystack_git_flutter/busystack_git_flutter.dart' as shared;
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../ai/ai_edit_ui.dart';
import '../../ai/ai_models.dart';
import '../../app/app_settings.dart';
import '../../app/app_router.dart';
import '../../app/git_dismissal.dart';
import '../../app/busymark_design.dart';
import '../../app/busymark_dialogs.dart';
import '../../app/busymark_glyphs.dart';
import '../../app/command_registry.dart';
import '../../app/busymark_shortcuts.dart';
import '../../app/localization.dart';
import '../../workspace/workspace_controller.dart';
import '../../workspace/workspace_model.dart';
import '../../workspace/workspace_safety.dart';
import 'git_controller.dart';
import 'git_workspace_eligibility.dart';
import '../data/git_shared_gateway.dart';
import '../domain/git_models.dart' show GitStatusSnapshot;

typedef BusyMarkGitClientFactory =
    shared.GitClient Function({
      required bool Function(shared.RepositoryId) authorize,
      shared.GitPromptHandler? prompts,
    });
final sharedGitClientFactoryProvider = Provider<BusyMarkGitClientFactory>(
  (_) =>
      ({required authorize, prompts}) =>
          shared.BackgroundGitClient(authorize: authorize, prompts: prompts),
);
final sharedGitDraftStoreProvider = Provider<shared.GitDraftStore>(
  (_) => _drafts,
);

/// Owns repository attachments for one authoring workspace. Commit, review,
/// and commands share their status, drafts and operation lifecycle. The host
/// callbacks belong to this scope, so closing a sidebar cannot invalidate a
/// review or retarget an outstanding operation.
class BusyMarkGitWorkspaceScope extends ConsumerStatefulWidget {
  const BusyMarkGitWorkspaceScope({
    super.key,
    required this.workspace,
    required this.child,
  });
  final Workspace workspace;
  final Widget child;

  static _BusyMarkGitWorkspaceScopeState _of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_BusyMarkGitAttachmentScope>()!
      .owner;

  @override
  ConsumerState<BusyMarkGitWorkspaceScope> createState() =>
      _BusyMarkGitWorkspaceScopeState();
}

class _BusyMarkGitWorkspaceScopeState
    extends ConsumerState<BusyMarkGitWorkspaceScope> {
  final _sessions = <String, Future<shared.GitSession>>{};
  final _owned = <shared.GitSession>[];
  final _eligibleRepositories = <String>{};
  final _legacyListeners = <shared.GitSession, VoidCallback>{};
  var _discoveryCancellation = shared.GitCancellation();
  var _generation = 0;
  Future<shared.RepositoryId?>? _discovery;
  shared.GitClient? _client;
  late VoidCallback _unregisterDraftFlush;

  @override
  void initState() {
    super.initState();
    _registerDraftFlush();
  }

  void _registerDraftFlush() {
    _unregisterDraftFlush = ref
        .read(busyMarkGitDraftFlushProvider)
        .register(_flushDrafts, sessions: () => List.of(_owned));
  }

  Future<void> _flushDrafts() async {
    final store = ref.read(sharedGitDraftStoreProvider);
    for (final session in List.of(_owned)) {
      await session.flushMessageDrafts();
    }
    if (store is shared.GitFlushableDraftStore) {
      await (store as shared.GitFlushableDraftStore).flush();
    }
  }

  shared.GitHost get _host {
    final generation = _generation;
    return busyMarkGitHost(
      context,
      ref,
      widget.workspace,
      isMounted: () => mounted && generation == _generation,
    );
  }

  shared.GitClient get client => _client ??= _createClient();

  shared.GitClient _createClient() {
    final generation = _generation;
    final host = _host;
    return ref.read(sharedGitClientFactoryProvider)(
      authorize: (repository) =>
          mounted &&
          generation == _generation &&
          _eligibleRepositories.contains(repository.key) &&
          ref
              .read(appSettingsControllerProvider)
              .trustsGitWorkspace(repository.root),
      prompts: (prompt, cancellation) => !mounted || generation != _generation
          ? Future.value(null)
          : shared.presentGitPrompt(
              context,
              host.present,
              prompt,
              cancellation,
            ),
    );
  }

  Future<shared.GitSession?> open({shared.RepositoryId? repository}) async {
    if (!mounted || widget.workspace.isRemote) return null;
    final generation = _generation, workspace = widget.workspace;
    if (repository == null) {
      final discovery = _discovery ??= client.discover(
        workspace.rootPath,
        cancellation: _discoveryCancellation,
      );
      try {
        repository = await discovery;
      } finally {
        if (identical(_discovery, discovery)) _discovery = null;
      }
    }
    if (!mounted || generation != _generation || repository == null) {
      return null;
    }
    await requireGitWorkspaceRoot(
      workspace.rootPath,
      repository.root,
      bare: repository.bare,
    );
    if (!mounted || generation != _generation) return null;
    final target = repository;
    _eligibleRepositories.add(target.key);
    final attachment = _sessions.putIfAbsent(target.key, () async {
      await ref
          .read(gitControllerProvider.notifier)
          .associateSharedRepository(workspace, target);
      if (!mounted || generation != _generation) {
        throw const shared.GitException(shared.GitErrorCode.cancelled);
      }
      final session = shared.GitSession(
        client: client,
        repository: target,
        host: _host,
      );
      _owned.add(session);
      _bindLegacyStatus(workspace, target, session);
      await session.start();
      if (!mounted || generation != _generation) {
        throw const shared.GitException(shared.GitErrorCode.cancelled);
      }
      return session;
    });
    try {
      return await attachment;
    } on Object {
      if (identical(_sessions[target.key], attachment)) {
        _sessions.remove(target.key);
      }
      rethrow;
    }
  }

  @override
  void didUpdateWidget(covariant BusyMarkGitWorkspaceScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workspace.id != widget.workspace.id ||
        oldWidget.workspace.isRemote != widget.workspace.isRemote ||
        !widget.workspace.isRemote &&
            oldWidget.workspace.rootPath != widget.workspace.rootPath) {
      // Navigation can complete before the next frame and reuse this State.
      // Retire old message owners before clearing them, as disposal does.
      _unregisterDraftFlush();
      _releaseAttachments();
      _registerDraftFlush();
      _discoveryCancellation = shared.GitCancellation();
    }
  }

  void _bindLegacyStatus(
    Workspace workspace,
    shared.RepositoryId repository,
    shared.GitSession session,
  ) {
    final engine = client;
    if (engine is! shared.GitWorkflowClient) return;
    final generation = _generation;
    shared.GitSnapshot? projected;
    Future<GitStatusSnapshot?>? projection;
    Future<GitStatusSnapshot?> current() {
      final snapshot = session.snapshot;
      if (snapshot == null) return Future.value(null);
      if (identical(projected, snapshot) && projection != null) {
        return projection!;
      }
      projected = snapshot;
      return projection = () async {
        final metadata = await (engine as shared.GitWorkflowClient).inspect(
          repository,
          const shared.GitInspection(shared.GitInspectionKind.remotes),
        );
        if (!mounted || generation != _generation) {
          throw const shared.GitException(shared.GitErrorCode.cancelled);
        }
        final remotes = metadata['remotes'] as List;
        return GitCliGateway.projectSharedStatus(
          snapshot,
          hasRemote: remotes.isNotEmpty,
        );
      }();
    }

    final controller = ref.read(gitControllerProvider.notifier);
    if (!controller.bindSharedStatusSource(
      workspace,
      repository,
      current: current,
      refresh: () async {
        await session.refresh();
        if (session.failure case final failure?) throw failure;
        final status = await current();
        if (status == null) {
          throw const shared.GitException(shared.GitErrorCode.disconnected);
        }
        return status;
      },
    )) {
      return;
    }
    shared.GitSnapshot? observed;
    void changed() {
      if (!mounted ||
          generation != _generation ||
          session.snapshot == null ||
          identical(observed, session.snapshot)) {
        return;
      }
      observed = session.snapshot;
      unawaited(controller.refreshFromSharedSnapshot());
    }

    _legacyListeners[session] = changed;
    session.addListener(changed);
  }

  void _releaseAttachments() {
    _generation++;
    _discoveryCancellation.cancel();
    for (final entry in _legacyListeners.entries) {
      entry.key.removeListener(entry.value);
    }
    _legacyListeners.clear();
    for (final session in _owned) {
      session.dispose();
    }
    _owned.clear();
    _sessions.clear();
    _eligibleRepositories.clear();
    _discovery = null;
    final retired = _client;
    _client = null;
    if (retired is shared.BackgroundGitClient) unawaited(retired.close());
  }

  @override
  void dispose() {
    _unregisterDraftFlush();
    _releaseAttachments();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => shared.GitHostScope(
    host: _host,
    child: _BusyMarkGitAttachmentScope(owner: this, child: widget.child),
  );
}

class _BusyMarkGitAttachmentScope extends InheritedWidget {
  const _BusyMarkGitAttachmentScope({
    required this.owner,
    required super.child,
  });
  final _BusyMarkGitWorkspaceScopeState owner;
  @override
  bool updateShouldNotify(_BusyMarkGitAttachmentScope oldWidget) =>
      owner != oldWidget.owner;
}

Future<void> showBusyMarkSharedGitAction(
  BuildContext context,
  WidgetRef ref,
  String action, {
  String? absolutePath,
}) async {
  final workspace = ref.read(workspaceControllerProvider).workspace;
  if (workspace == null || !context.mounted) return;
  shared.GitSession? session;
  try {
    session = await BusyMarkGitWorkspaceScope._of(context).open();
  } on GitWorkspaceRootRequired {
    if (context.mounted) {
      BusyMarkToastOverlay.show(
        context,
        message: context.l10n.gitWorkspaceRootRequired,
      );
    }
    return;
  }
  if (!context.mounted || session == null) return;
  final repository = session.repository;
  if (!context.mounted || session.snapshot == null) return;
  final ui = shared.GitWorkflowUi(context, session);
  switch (action) {
    case 'fileHistory':
      if (absolutePath == null || !p.isWithin(repository.root, absolutePath)) {
        return;
      }
      await session.host.present<void>(
        context,
        context.l10n.gitHostGitLog,
        shared.GitFileHistoryView(
          session: session,
          path: shared.RepoPath.text(
            p.relative(absolutePath, from: repository.root),
          ),
        ),
        expanded: true,
      );
    case 'diff':
      if (absolutePath == null || !p.isWithin(repository.root, absolutePath)) {
        return;
      }
      ref
          .read(sharedGitReviewProvider.notifier)
          .open(
            workspace.id,
            SharedGitReview(
              repository,
              reviewToken: session.snapshot!.token,
              comparison: shared.GitComparison(
                shared.RepoPath.text(
                  p.relative(absolutePath, from: repository.root),
                ),
                const shared.ContentVersion.index(),
                const shared.ContentVersion.working(),
              ),
            ),
          );
    case 'branches':
      await ui.branches();
    case 'fetch':
      await ui.present(
        context.l10n.gitHostFetch,
        shared.GitFetchView(session: session),
      );
    case 'pull':
      await ui.pull();
    case 'push':
      await ui.push();
    case 'more':
      await ui.more(
        showBranches: false,
        includeRefresh: true,
        showBranchOperations: false,
      );
  }
}

final class BusyMarkGitDraftStore
    implements shared.GitVersionedDraftStore, shared.GitFlushableDraftStore {
  BusyMarkGitDraftStore({Future<Directory> Function()? directory})
    : _directory = directory;
  final Future<Directory> Function()? _directory;
  late final _store = shared.FileGitDraftStore(file: _file);

  Future<Map<String, Object>?> readViewState(String key) async {
    final value = await _store.read('$key-view');
    final targets = await _store.recoverAmendTargets(key);
    if (value == null && targets.isEmpty) return null;
    return {
      if (value != null) ...Map<String, Object>.from(jsonDecode(value) as Map),
      // Preferences may be overwritten by another window. A retained amend
      // belongs to its actual nonempty message slot and original reviewed HEAD.
      'commitAmendDraftTargets': targets,
    };
  }

  Future<void> writeViewState(String key, Map<String, Object> value) =>
      _store.writeUnconditionally('$key-view', jsonEncode(value));

  Future<File> _file(String key) async {
    final directory = _directory == null
        ? Directory(
            p.join((await getApplicationSupportDirectory()).path, 'git-drafts'),
          )
        : await _directory();
    await directory.create(recursive: true);
    // Logical amend slots include ':'; keep existing Linux filenames while
    // encoding characters forbidden in Windows filenames with a reversible codec.
    final name = Platform.isWindows
        ? Uri.encodeComponent(key).replaceAll('*', '%2A')
        : key;
    return File(p.join(directory.path, '$name.txt'));
  }

  @override
  Future<String?> read(String key) => _store.read(key);

  @override
  Future<void> write(String key, String message) => _store.write(key, message);

  @override
  Future<shared.GitStoredDraft> readVersioned(String key) =>
      _store.readVersioned(key);

  @override
  Future<shared.GitDraftWriteResult> compareAndWrite(
    String key, {
    required String expectedVersion,
    required String? text,
  }) =>
      _store.compareAndWrite(key, expectedVersion: expectedVersion, text: text);

  @override
  Future<void> flush() => _store.flush();
}

final _drafts = BusyMarkGitDraftStore();

// Git's local dispatcher must not intercept application commands such as
// tab activation when their shortcuts bubble out of a focused Git control.
class _GitCommandIntent extends Intent {
  const _GitCommandIntent(this.commandId);
  final String commandId;
}

Widget _gitCommands(
  BuildContext context,
  shared.GitSession session,
  Widget child, {
  bool enabled = true,
}) {
  final commands = BusyMarkCommandRegistry([
    for (final action
        in <(String, String, ShortcutActivator, Future<void> Function())>[
          (
            'refresh',
            context.l10n.gitHostRefreshGitStatus,
            const SingleActivator(LogicalKeyboardKey.f5),
            session.refresh,
          ),
          (
            'commit',
            context.l10n.gitHostCommitStaged,
            const SingleActivator(LogicalKeyboardKey.enter, control: true),
            () async {
              if (session.canCommit?.call() == true) {
                await session.commitAction?.call(false);
              }
            },
          ),
          (
            'branches',
            context.l10n.gitHostGitBranches,
            const SingleActivator(
              LogicalKeyboardKey.keyB,
              control: true,
              shift: true,
            ),
            () => shared.GitWorkflowUi(context, session).branches(),
          ),
          (
            'push',
            context.l10n.gitHostReviewPush,
            const SingleActivator(
              LogicalKeyboardKey.keyP,
              control: true,
              shift: true,
            ),
            () => shared.GitWorkflowUi(context, session).push(),
          ),
        ])
      BusyMarkCommand(
        id: 'git.${action.$1}',
        label: (_) => action.$2,
        category: (_) => context.l10n.gitHostGit,
        scope: BusyMarkCommandScope.git,
        shortcut: BusyMarkShortcutDefinition(
          label: action.$2,
          activator: action.$3,
        ),
        execute: () async {
          if (enabled) await action.$4();
        },
      ),
  ]);
  return BusyMarkCommandRegistryScope(
    registry: commands,
    child: Shortcuts(
      shortcuts: commands.shortcutIntents(
        scopes: {BusyMarkCommandScope.git},
        intentFor: _GitCommandIntent.new,
      ),
      child: Actions(
        actions: {
          _GitCommandIntent: CallbackAction<_GitCommandIntent>(
            onInvoke: (intent) {
              unawaited(commands.execute(intent.commandId));
              return null;
            },
          ),
        },
        child: child,
      ),
    ),
  );
}

Future<bool> _ensureGitTrust(
  BuildContext context,
  WidgetRef ref,
  Workspace workspace,
  shared.RepositoryId repository,
) async {
  bool current() {
    final active = ref.read(workspaceControllerProvider).workspace;
    return context.mounted &&
        active?.id == workspace.id &&
        active?.rootPath == workspace.rootPath &&
        active?.openedAt == workspace.openedAt &&
        active?.isRemote == false;
  }

  if (!current()) return false;
  await requireGitWorkspaceRoot(
    workspace.rootPath,
    repository.root,
    bare: repository.bare,
  );
  if (!current()) return false;
  if (ref
      .read(appSettingsControllerProvider)
      .trustsGitWorkspace(repository.root)) {
    return true;
  }
  if (!context.mounted) return false;
  final labels = context.l10n;
  var decisionSubmitted = false;
  final approved = await showBusyMarkModalDialog<bool>(
    context,
    builder: (dialogContext) {
      final route = ModalRoute.of(dialogContext);
      void decide(bool value) {
        // A native activation can still be queued while this route exits.
        // It must never dismiss the review underneath the trust dialog.
        if (decisionSubmitted ||
            !dialogContext.mounted ||
            route?.isCurrent != true) {
          return;
        }
        decisionSubmitted = true;
        Navigator.of(dialogContext).pop(value);
      }

      return BusyMarkDialogShell(
        title: labels.gitTrustRequiredTitle,
        actions: [
          BusyMarkPushButton.standard(
            onPressed: () => decide(false),
            child: Text(labels.cancel),
          ),
          BusyMarkPushButton.suggested(
            onPressed: () => decide(true),
            child: Text(labels.gitTrustWorkspace),
          ),
        ],
        children: [
          Text('${repository.root}\n\n${labels.gitTrustRequiredMessage}'),
        ],
      );
    },
  );
  decisionSubmitted = true;
  if (approved != true || !context.mounted || !current()) {
    return false;
  }
  await requireGitWorkspaceRoot(
    workspace.rootPath,
    repository.root,
    bare: repository.bare,
  );
  if (!current()) return false;
  await ref
      .read(appSettingsControllerProvider.notifier)
      .trustGitWorkspace(repository.root);
  return current();
}

shared.GitHost busyMarkGitHost(
  BuildContext context,
  WidgetRef ref,
  Workspace workspace, {
  required bool Function() isMounted,
}) {
  final drafts = ref.read(sharedGitDraftStoreProvider);
  var reconcileWorkingFiles = true;
  final fallbackLocalizations = context.l10n;
  return shared.GitHost(
    presentation: const BusyMarkGitPresentation(),
    registerDismissalGuard: ref.read(busyMarkGitDismissalProvider).register,
    spacing: BusyMarkSpacing.sm,
    minimumRowHeight:
        BusyMarkSizes.sidebarTreeRowHeight + BusyMarkStroke.hairline * 2,
    icons: const {
      shared.GitGlyph.back: BusyMarkGlyphs.gitPrevious,
      shared.GitGlyph.branch: BusyMarkGlyphs.branch,
      shared.GitGlyph.history: BusyMarkGlyphs.history,
      shared.GitGlyph.refresh: BusyMarkGlyphs.refresh,
      shared.GitGlyph.copy: BusyMarkGlyphs.copy,
      shared.GitGlyph.options: BusyMarkGlyphs.settings,
      shared.GitGlyph.moreHorizontal: BusyMarkGlyphs.menuHorizontal,
      shared.GitGlyph.more: BusyMarkGlyphs.menuVertical,
      shared.GitGlyph.expand: BusyMarkGlyphs.downArrow,
      shared.GitGlyph.previous: BusyMarkGlyphs.gitPrevious,
      shared.GitGlyph.next: BusyMarkGlyphs.gitNext,
      shared.GitGlyph.up: BusyMarkGlyphs.upArrow,
      shared.GitGlyph.down: BusyMarkGlyphs.downArrow,
      shared.GitGlyph.search: BusyMarkGlyphs.search,
      shared.GitGlyph.add: BusyMarkGlyphs.add,
      shared.GitGlyph.remove: BusyMarkGlyphs.thematicBreak,
      shared.GitGlyph.check: BusyMarkGlyphs.check,
      shared.GitGlyph.tag: BusyMarkGlyphs.tag,
      shared.GitGlyph.error: BusyMarkGlyphs.error,
      shared.GitGlyph.warning: BusyMarkGlyphs.warning,
      shared.GitGlyph.close: BusyMarkGlyphs.windowClose,
    },
    presentMenu: busyMarkPresentGitMenu,
    localize: (message, values) {
      final current = rootNavigatorKey.currentContext;
      final localizations = current != null && current.mounted
          ? current.l10n
          : fallbackLocalizations;
      return localizations.translateSharedGitMessage(message, values);
    },
    present: <T>(dialogContext, title, child, {bool expanded = false}) =>
        showBusyMarkModalDialog<T>(
          dialogContext,
          builder: (context) => BusyMarkDialogShell(
            title: title,
            maxWidth: expanded
                ? MediaQuery.sizeOf(context).width * .94
                : BusyMarkSizes.dialogWide,
            expanded: expanded,
            body: child,
          ),
        ),
    openDocument: (repository, path, {snapshot}) async {
      if (!isMounted()) return;
      if (snapshot != null) {
        await showBusyMarkModalDialog<void>(
          context,
          builder: (context) => BusyMarkDialogShell(
            title: context.l10n.gitHostGit,
            maxWidth: MediaQuery.sizeOf(context).width * .85,
            expanded: true,
            body: shared.GitHostScope(
              host: busyMarkGitHost(
                context,
                ref,
                workspace,
                isMounted: isMounted,
              ),
              child: shared.GitTextPane(
                label: context.l10n.gitSnapshotLabel(
                  shared.gitVersionLabel(context, snapshot.version),
                  path.display,
                ),
                text: snapshot.text ?? context.l10n.gitHostContentUnavailable,
              ),
            ),
          ),
        );
        return;
      }
      final relative = path.utf8Path;
      if (relative == null) {
        BusyMarkToastOverlay.show(
          context,
          message: context.l10n.gitNonUtf8FilenameMessage,
        );
        return;
      }
      final filePath = p.join(repository.root, relative);
      if (await saveOrConfirmSafeToChangeActiveFile(context, ref) &&
          isMounted()) {
        final current = ref.read(workspaceControllerProvider).workspace;
        final file = current?.files
            .where((file) => p.equals(file.absolutePath, filePath))
            .firstOrNull;
        if (file != null) {
          await ref
              .read(workspaceControllerProvider.notifier)
              .openActiveFile(file.absolutePath);
        }
      }
    },
    prepareMutation: (repository, request) async {
      if (!isMounted() ||
          ref.read(workspaceControllerProvider).workspace?.id != workspace.id) {
        return false;
      }
      // Authorization is explicit in the trust screen. A queued mutation may
      // never resume merely because another action grants trust.
      await requireGitWorkspaceRoot(
        workspace.rootPath,
        repository.root,
        bare: repository.bare,
      );
      if (!isMounted() ||
          !context.mounted ||
          !ref
              .read(appSettingsControllerProvider)
              .trustsGitWorkspace(repository.root)) {
        return false;
      }
      var mayReplaceFiles = request.replacesWorkingFiles;
      if (request is shared.CommitIndex) {
        final client = ref.read(sharedGitClientFactoryProvider)(
          authorize: (_) => true,
        );
        final options = await (client as shared.GitWorkflowClient).inspect(
          repository,
          const shared.GitInspection(shared.GitInspectionKind.commitOptions),
        );
        mayReplaceFiles = options['hasConfiguredHooks'] == true;
      }
      reconcileWorkingFiles = mayReplaceFiles;
      if (!context.mounted || !isMounted()) return false;
      if (mayReplaceFiles) {
        final paths = ref
            .read(workspaceControllerProvider)
            .documentBuffers
            .where(
              (buffer) =>
                  buffer.filePath != null &&
                  (p.equals(repository.root, buffer.filePath!) ||
                      p.isWithin(repository.root, buffer.filePath!)),
            )
            .map((buffer) => buffer.filePath!)
            .toList();
        if (!await confirmSafeToChangeWorkspaceFiles(context, ref, paths)) {
          return false;
        }
      }
      return isMounted() &&
          ref.read(workspaceControllerProvider).workspace?.id == workspace.id;
    },
    afterMutation: (repository, result) async {
      if (isMounted() &&
          ref.read(workspaceControllerProvider).workspace?.id == workspace.id) {
        // Fetch, staging and other metadata-only operations do not change
        // authoring buffers. A full folder rescan here keeps cancellation
        // pending and needlessly cancels the editor's derived work/autosaves.
        // Reconcile file-changing operations even after a nonzero Git result.
        if (reconcileWorkingFiles) {
          await ref
              .read(workspaceControllerProvider.notifier)
              .refreshWorkspaceFromDiskPreservingOpenTabs();
        }
        // Project the reconciled result for authoring commands. A second full
        // query would keep competing with typing and opening the next diff.
        unawaited(
          ref.read(gitControllerProvider.notifier).refreshFromSharedSnapshot(),
        );
      }
    },
    chooseDirectory: (_) => getDirectoryPath(),
    revokeRepositoryTrust: (repository) async {
      await ref
          .read(appSettingsControllerProvider.notifier)
          .revokeGitWorkspaceTrust(repository.root);
    },
    openFolder: (path) async {
      if (isMounted() && await confirmSafeToContinue(context, ref)) {
        await ref.read(workspaceControllerProvider.notifier).openFolder(path);
      }
    },
    prepareInspection: (repository, request) async {
      if (!isMounted()) return false;
      if ({
            shared.GitInspectionKind.pushReview,
            shared.GitInspectionKind.rebasePlan,
            shared.GitInspectionKind.workingStatus,
          }.contains(request.kind) &&
          !await _ensureGitTrust(context, ref, workspace, repository)) {
        return false;
      }
      if (!context.mounted || !isMounted()) return false;
      if ({
        shared.GitInspectionKind.rebasePlan,
        shared.GitInspectionKind.workingStatus,
      }.contains(request.kind)) {
        final paths = ref
            .read(workspaceControllerProvider)
            .documentBuffers
            .where(
              (buffer) =>
                  buffer.filePath != null &&
                  p.isWithin(repository.root, buffer.filePath!),
            )
            .map((buffer) => buffer.filePath!)
            .toList();
        return confirmSafeToChangeWorkspaceFiles(context, ref, paths);
      }
      return true;
    },
    notify: (message) {
      if (isMounted()) {
        BusyMarkToastOverlay.show(context, message: message);
      }
    },
    drafts: drafts,
    readViewState: drafts is BusyMarkGitDraftStore
        ? drafts.readViewState
        : null,
    writeViewState: drafts is BusyMarkGitDraftStore
        ? drafts.writeViewState
        : null,
    draftMessage: (repository) async {
      if (!isMounted()) return null;
      final controller = ref.read(gitControllerProvider.notifier);
      final diff = await controller.stagedDiffForAi();
      if (diff == null || !isMounted() || !context.mounted) return null;
      final provider = await chooseBusyMarkAiProvider(context, ref);
      if (provider == null || !isMounted() || !context.mounted) return null;
      return showBusyMarkAiProposal(
        context,
        ref,
        AiEditInvocation(
          feature: AiFeature.draftCommitMessage,
          scope: AiScope.gitDiff,
          input: diff.patch,
          replacementOriginal: '',
          sourceRevision: 0,
          targetId: 'git-commit:${repository.key}',
          documentPath: null,
          contentFormat: AiContentFormat.plainText,
          enforceDocumentRevision: false,
        ),
        providerKind: provider,
        validateBeforeApply: () =>
            controller.stagedDiffMatches(diff.fingerprint),
        staleMessage: context.l10n.gitAiStagedChangesChanged,
      );
    },
  );
}

class BusyMarkSharedGitSidebar extends ConsumerStatefulWidget {
  const BusyMarkSharedGitSidebar({
    super.key,
    required this.workspace,
    required this.onShowLog,
    this.log = false,
    this.active = true,
  });
  final bool log, active;
  final VoidCallback onShowLog;
  final Workspace workspace;
  @override
  ConsumerState<BusyMarkSharedGitSidebar> createState() =>
      _BusyMarkSharedGitSidebarState();
}

class _BusyMarkSharedGitSidebarState
    extends ConsumerState<BusyMarkSharedGitSidebar> {
  shared.GitSession? _session;
  shared.GitException? _failure;
  bool _loading = false, _noRepository = false, _rootRequired = false;
  int _generation = 0;
  bool _logVisited = false;
  @override
  void didUpdateWidget(covariant BusyMarkSharedGitSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workspace.id != widget.workspace.id ||
        oldWidget.workspace.rootPath != widget.workspace.rootPath) {
      _generation++;
      _session = null;
      _loading = false;
      _noRepository = false;
      _rootRequired = false;
      _failure = null;
    }
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }

  Future<void> _attach() async {
    if (_loading || _session != null) return;
    setState(() {
      _loading = true;
      _failure = null;
    });
    final generation = ++_generation;
    try {
      final session = await BusyMarkGitWorkspaceScope._of(context).open();
      if (!mounted || generation != _generation) return;
      if (session == null) {
        setState(() {
          _loading = false;
          _noRepository = true;
        });
        return;
      }
      setState(() {
        _session = session;
        _loading = false;
      });
    } on GitWorkspaceRootRequired {
      if (mounted && generation == _generation) {
        setState(() {
          _rootRequired = true;
          _loading = false;
        });
      }
    } on shared.GitException catch (error) {
      if (mounted && generation == _generation) {
        setState(() {
          _failure = error;
          _loading = false;
        });
      }
    }
  }

  void _review(shared.GitComparison comparison) {
    final session = _session!;
    ref
        .read(sharedGitReviewProvider.notifier)
        .open(
          widget.workspace.id,
          SharedGitReview(
            session.repository,
            comparison: comparison,
            reviewToken: session.snapshot!.token,
            reviewedFiles: List.unmodifiable(
              shared.gitStatusComparisons(session.snapshot),
            ),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final trusted =
        _session != null &&
        ref
            .watch(appSettingsControllerProvider)
            .trustsGitWorkspace(_session!.repository.root);
    final selection = ref
        .watch(sharedGitReviewProvider)[widget.workspace.id]
        ?.active
        ?.comparison;
    if (_rootRequired) {
      return Padding(
        padding: const EdgeInsets.all(BusyMarkSpacing.lg),
        child: Text(context.l10n.gitWorkspaceRootRequired),
      );
    }
    if (_failure != null) {
      return shared.GitFailurePanel(
        error: _failure!,
        onRefresh: () => unawaited(_attach()),
      );
    }
    if (_noRepository) {
      return SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.gitNotRepositoryMessage),
            for (final initialize in [false, true])
              BusyMarkPushButton.standard(
                onPressed: () async {
                  final host = busyMarkGitHost(
                    context,
                    ref,
                    widget.workspace,
                    isMounted: () => mounted,
                  );
                  final engine = ref.read(sharedGitClientFactoryProvider)(
                    authorize: (_) => false,
                    prompts: (prompt, cancellation) => shared.presentGitPrompt(
                      context,
                      host.present,
                      prompt,
                      cancellation,
                    ),
                  );
                  final created = await host.present<shared.RepositoryId>(
                    context,
                    initialize
                        ? context.l10n.gitHostInitializeRepository
                        : context.l10n.gitHostCloneRepository,
                    shared.GitCreationView(
                      client: engine as shared.GitWorkflowClient,
                      chooseDirectory: host.chooseDirectory,
                      initialize: initialize,
                      initialDestination: initialize
                          ? widget.workspace.rootPath
                          : '',
                    ),
                    expanded: false,
                  );
                  if (created != null) {
                    await host.openFolder?.call(created.root);
                    if (mounted) setState(() => _noRepository = false);
                  }
                },
                child: Text(
                  initialize
                      ? context.l10n.gitHostInitializeHere
                      : context.l10n.gitHostCloneRepository2,
                ),
              ),
          ],
        ),
      );
    }
    if (_session == null) {
      if (!widget.active) return const SizedBox.shrink();
      if (!_loading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_attach());
        });
      }
      return const Center(child: shared.GitLoading.spinner());
    }
    _logVisited = _logVisited || widget.log;
    return _gitCommands(
      context,
      _session!,
      IndexedStack(
        index: widget.log ? 1 : 0,
        children: [
          ExcludeFocus(
            excluding: !widget.active || widget.log,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Visibility(
                  visible: trusted,
                  maintainState: true,
                  child: shared.GitCommitView(
                    layout: shared.GitCommitLayout.sidebar,
                    branchActionLabel: context.l10n.gitManageBranches,
                    minimumWidth: busyMarkGitSidebarMinimumWidth(context),
                    trackingDescription: (snapshot) => snapshot.upstream == null
                        ? context.l10n.gitUiNoUpstream
                        : context.l10n.gitLocalTrackingDescription(
                            snapshot.upstream!,
                            snapshot.trackingCountsKnown
                                ? snapshot.ahead.toString()
                                : context.l10n.gitStatusUnknown,
                            snapshot.trackingCountsKnown
                                ? snapshot.behind.toString()
                                : context.l10n.gitStatusUnknown,
                          ),
                    session: _session!,
                    active: trusted && widget.active && !widget.log,
                    protectMessageDrafts: false,
                    reviewContext: () => (
                      ref
                          .read(sharedGitReviewProvider)[widget.workspace.id]
                          ?.activeId,
                      ref.read(workspaceControllerProvider).activeBufferId,
                    ),
                    selectedComparison: selection,
                    onReview: _review,
                    onLog: widget.onShowLog,
                    onBranches: () =>
                        shared.GitWorkflowUi(context, _session!).branches(),
                    onPush: () =>
                        shared.GitWorkflowUi(context, _session!).push(),
                    onMore: (anchor) =>
                        shared.GitWorkflowUi(anchor, _session!).more(
                          showBranches: false,
                          includeRefresh: true,
                          showBranchOperations: false,
                        ),
                  ),
                ),
                if (!trusted)
                  Positioned.fill(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(BusyMarkSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.gitOperationsRequireTrust,
                            style: busyMarkSectionHeaderStyle(context),
                          ),
                          const SizedBox(height: BusyMarkSpacing.lg),
                          BusyMarkPushButton.suggested(
                            onPressed: () async {
                              final session = _session!;
                              if (await _ensureGitTrust(
                                    context,
                                    ref,
                                    widget.workspace,
                                    session.repository,
                                  ) &&
                                  mounted &&
                                  identical(session, _session)) {
                                await session.refresh();
                              }
                            },
                            child: Text(context.l10n.gitTrustWorkspace),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_logVisited)
            ExcludeFocus(
              excluding: !widget.active || !widget.log,
              child: FocusTraversalGroup(
                key: const ValueKey('busymark-git-log-traversal'),
                policy: WidgetOrderTraversalPolicy(),
                child: shared.GitLogView(
                  session: _session!,
                  inspector: true,
                  active: widget.active && widget.log,
                  onReview: (comparison, files) => ref
                      .read(sharedGitReviewProvider.notifier)
                      .open(
                        widget.workspace.id,
                        SharedGitReview(
                          _session!.repository,
                          comparison: comparison,
                          reviewedFiles: List.unmodifiable(files),
                        ),
                      ),
                ),
              ),
            ),
        ],
      ),
      enabled: trusted,
    );
  }
}

class BusyMarkSharedGitReview extends ConsumerStatefulWidget {
  const BusyMarkSharedGitReview({
    super.key,
    required this.workspace,
    required this.review,
  });
  final Workspace workspace;
  final SharedGitReview review;
  @override
  ConsumerState<BusyMarkSharedGitReview> createState() =>
      _BusyMarkSharedGitReviewState();
}

class _BusyMarkSharedGitReviewState
    extends ConsumerState<BusyMarkSharedGitReview> {
  shared.GitSession? _session;
  shared.GitException? _failure;
  bool _attaching = false, _rootRequired = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_session != null || _attaching || _rootRequired) return;
    unawaited(_attach());
  }

  Future<void> _attach() async {
    _attaching = true;
    try {
      final session = await BusyMarkGitWorkspaceScope._of(
        context,
      ).open(repository: widget.review.repository);
      if (!mounted) return;
      setState(() {
        _session = session;
        _failure = null;
      });
      session?.addListener(_changed);
    } on GitWorkspaceRootRequired {
      if (mounted) setState(() => _rootRequired = true);
    } on shared.GitException catch (error) {
      if (mounted) setState(() => _failure = error);
    } finally {
      _attaching = false;
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _session?.removeListener(_changed);
    super.dispose();
  }

  VoidCallback? _navigate(int direction) {
    final comparisons = widget.review.reviewedFiles;
    final index = shared.gitComparisonIndex(
          comparisons,
          widget.review.comparison,
        ),
        next =
            shared.gitComparisonIndex(comparisons, widget.review.comparison) +
            direction;
    if (index < 0 || next < 0 || next >= comparisons.length) return null;
    final reviewed = widget.review;
    return () {
      if (!mounted ||
          ref.read(sharedGitReviewProvider)[widget.workspace.id]?.activeId !=
              reviewed.id ||
          !identical(
            ref
                .read(sharedGitReviewProvider)[widget.workspace.id]
                ?.entries
                .where((entry) => entry.id == reviewed.id)
                .firstOrNull,
            reviewed,
          )) {
        return;
      }
      ref
          .read(sharedGitReviewProvider.notifier)
          .open(
            widget.workspace.id,
            SharedGitReview(
              reviewed.repository,
              comparison: comparisons[next],
              reviewToken: reviewed.reviewToken,
              reviewedFiles: comparisons,
            ),
          );
    };
  }

  @override
  Widget build(BuildContext context) => _rootRequired
      ? Padding(
          padding: const EdgeInsets.all(BusyMarkSpacing.lg),
          child: Text(context.l10n.gitWorkspaceRootRequired),
        )
      : _failure != null
      ? shared.GitFailurePanel(
          error: _failure!,
          onRefresh: () => unawaited(_attach()),
        )
      : _session == null
      ? const Center(child: shared.GitLoading.spinner())
      : _gitCommands(
          context,
          _session!,
          shared.GitDiffView(
            session: _session!,
            comparison: widget.review.comparison,
            initialSideBySide: true,
            showFileHeader: false,
            onPreviousFile: _navigate(-1),
            onNextFile: _navigate(1),
          ),
        );
}

/// Native service failure is an operational error; Git never invokes the
/// generic application's fallback menu path.
Future<String?> busyMarkPresentGitTabMenu(
  BuildContext context, {
  required Offset position,
  required bool hasOtherTabs,
}) async {
  try {
    return await busyMarkPresentGitMenu(context, [
      shared.GitMenuEntry('close', context.l10n.close),
      shared.GitMenuEntry(
        'closeOthers',
        context.l10n.closeOtherTabs,
        enabled: hasOtherTabs,
      ),
      shared.GitMenuEntry('closeAll', context.l10n.shortcutCloseAllTabs),
    ], position: position);
  } on shared.GitException {
    if (context.mounted) {
      BusyMarkToastOverlay.show(
        context,
        message: context.l10n.gitUiNativeMenuUnavailable,
      );
    }
    return null;
  }
}

Future<String?> busyMarkPresentGitMenu(
  BuildContext context,
  List<shared.GitMenuEntry> entries, {
  Offset? position,
}) async {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return null;
  final result = await const NativeMenuService().show(
    session: NativeMenuSession(),
    anchor: position == null
        ? box.localToGlobal(Offset.zero) & box.size
        : position & const Size(1, 1),
    textDirection: Directionality.of(context),
    focusFirst: true,
    entries: [
      for (final entry in entries) ...[
        if (entry.sectionStart) const NativeMenuEntry.separator(),
        NativeMenuEntry.command(
          label: entry.label,
          enabled: entry.enabled,
          checkable: entry.checked != null,
          selected: entry.checked ?? false,
          mutuallyExclusive: entry.radio,
        ),
      ],
    ],
  );
  if (!result.available) {
    throw const shared.GitException(shared.GitErrorCode.unavailable);
  }
  final index = result.selectedIndex;
  // Native separators occupy entries too.
  final indexed = <shared.GitMenuEntry?>[
    for (final entry in entries) ...[if (entry.sectionStart) null, entry],
  ];
  return context.mounted &&
          index != null &&
          index >= 0 &&
          index < indexed.length &&
          indexed[index]?.enabled == true
      ? indexed[index]!.id
      : null;
}
