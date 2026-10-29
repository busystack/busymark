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
    final target = repository;
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
  Widget build(BuildContext context) =>
      _BusyMarkGitAttachmentScope(owner: this, child: widget.child);
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

final sharedGitReviewProvider =
    NotifierProvider<SharedGitReviews, Map<String, SharedGitReview>>(
      SharedGitReviews.new,
    );

class SharedGitReviews extends Notifier<Map<String, SharedGitReview>> {
  @override
  Map<String, SharedGitReview> build() => {};
  void open(String workspace, SharedGitReview review) =>
      state = {...state, workspace: review};
  void close(String workspace) => state = {...state}..remove(workspace);
}

class SharedGitReview {
  const SharedGitReview(
    this.repository, {
    this.comparison,
    this.log = false,
    this.historyPath,
    this.reviewedFiles = const [],
  });
  final shared.RepositoryId repository;
  final shared.GitComparison? comparison;
  final bool log;
  final shared.RepoPath? historyPath;
  final List<shared.GitComparison> reviewedFiles;
}

Future<void> showBusyMarkSharedGitAction(
  BuildContext context,
  WidgetRef ref,
  String action, {
  String? absolutePath,
}) async {
  final workspace = ref.read(workspaceControllerProvider).workspace;
  if (workspace == null || !context.mounted) return;
  final session = await BusyMarkGitWorkspaceScope._of(context).open();
  if (!context.mounted || session == null) return;
  final repository = session.repository;
  if (!context.mounted || session.snapshot == null) return;
  final ui = shared.GitWorkflowUi(context, session);
  switch (action) {
    case 'log':
      ref
          .read(sharedGitReviewProvider.notifier)
          .open(workspace.id, SharedGitReview(repository, log: true));
    case 'fileHistory':
      if (absolutePath == null || !p.isWithin(repository.root, absolutePath)) {
        return;
      }
      ref
          .read(sharedGitReviewProvider.notifier)
          .open(
            workspace.id,
            SharedGitReview(
              repository,
              historyPath: shared.RepoPath.text(
                p.relative(absolutePath, from: repository.root),
              ),
            ),
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
      await ui.more();
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

Widget _gitCommands(
  BuildContext context,
  shared.GitSession session,
  Widget child,
) {
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
        execute: action.$4,
      ),
  ]);
  return BusyMarkCommandRegistryScope(
    registry: commands,
    child: Shortcuts(
      shortcuts: commands.shortcutIntents(
        scopes: {BusyMarkCommandScope.git},
        intentFor: BusyMarkCommandIntent.new,
      ),
      child: Actions(
        actions: {
          BusyMarkCommandIntent: CallbackAction<BusyMarkCommandIntent>(
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
  if (ref
      .read(appSettingsControllerProvider)
      .trustsGitWorkspace(repository.root)) {
    return true;
  }
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

      return AlertDialog(
        title: Text(context.l10n.gitTrustRequiredTitle),
        content: Text(
          '${repository.root}\n\n${context.l10n.gitTrustRequiredMessage}\n${context.l10n.gitHostGitOperationsApplyToThisEntireRepositoryAndMay}',
        ),
        actions: [
          TextButton(
            onPressed: () => decide(false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => decide(true),
            child: Text(context.l10n.gitTrustWorkspace),
          ),
        ],
      );
    },
  );
  decisionSubmitted = true;
  if (approved != true ||
      !context.mounted ||
      ref.read(workspaceControllerProvider).workspace?.id != workspace.id) {
    return false;
  }
  await ref
      .read(appSettingsControllerProvider.notifier)
      .trustGitWorkspace(repository.root);
  return true;
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
    registerDismissalGuard: ref.read(busyMarkGitDismissalProvider).register,
    spacing: BusyMarkSpacing.sm,
    minimumRowHeight: 30,
    icons: const {
      shared.GitGlyph.back: BusyMarkGlyphs.gitPrevious,
      shared.GitGlyph.branch: BusyMarkGlyphs.branch,
      shared.GitGlyph.history: BusyMarkGlyphs.history,
      shared.GitGlyph.refresh: BusyMarkGlyphs.refresh,
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
    presentMenu: (menuContext, entries, {position}) => showBusyMarkMenu<String>(
      context: menuContext,
      anchorPoint: position,
      focusFirst: true,
      items: [
        for (final entry in entries) ...[
          if (entry.sectionStart) const PopupMenuDivider(),
          BusyMarkPopupMenuItem(
            value: entry.id,
            label: entry.label,
            enabled: entry.enabled,
            checked: entry.checked ?? false,
            trailingCheck: entry.checked != null,
            mutuallyExclusive: entry.radio,
          ),
        ],
      ],
    ),
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
          builder: (context) => Dialog(
            insetPadding: const EdgeInsets.all(BusyMarkSpacing.lg),
            child: SizedBox(
              width: expanded ? MediaQuery.sizeOf(context).width * .94 : 560,
              height: expanded ? MediaQuery.sizeOf(context).height * .86 : null,
              child: Column(
                mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(BusyMarkSpacing.sm),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          tooltip: context.l10n.close,
                          onPressed: () {
                            final route = ModalRoute.of(context);
                            if (route?.isCurrent == true) {
                              unawaited(Navigator.of(context).maybePop());
                            }
                          },
                          icon: const Icon(BusyMarkGlyphs.windowClose),
                        ),
                      ],
                    ),
                  ),
                  if (expanded)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(BusyMarkSpacing.sm),
                        child: child,
                      ),
                    )
                  else
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(BusyMarkSpacing.md),
                        child: child,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
    openDocument: (repository, path, {snapshot}) async {
      if (!isMounted()) return;
      if (snapshot != null) {
        await showBusyMarkModalDialog<void>(
          context,
          builder: (context) => Dialog(
            child: SizedBox(
              width: MediaQuery.sizeOf(context).width * .85,
              height: MediaQuery.sizeOf(context).height * .8,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.gitNonUtf8FilenameMessage)),
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
      if (!await _ensureGitTrust(context, ref, workspace, repository) ||
          !isMounted() ||
          !context.mounted) {
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
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
  const BusyMarkSharedGitSidebar({super.key, required this.workspace});
  final Workspace workspace;
  @override
  ConsumerState<BusyMarkSharedGitSidebar> createState() =>
      _BusyMarkSharedGitSidebarState();
}

class _BusyMarkSharedGitSidebarState
    extends ConsumerState<BusyMarkSharedGitSidebar> {
  shared.GitSession? _session;
  shared.GitException? _failure;
  bool _loading = false, _noRepository = false;
  int _generation = 0;
  @override
  void didUpdateWidget(covariant BusyMarkSharedGitSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workspace.id != widget.workspace.id ||
        oldWidget.workspace.rootPath != widget.workspace.rootPath) {
      _generation++;
      _session = null;
      _loading = false;
      _noRepository = false;
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
    setState(() => _loading = true);
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
    } on shared.GitException catch (error) {
      if (mounted && generation == _generation) {
        setState(() {
          _failure = error;
          _loading = false;
        });
      }
    }
  }

  void _review({shared.GitComparison? comparison, bool log = false}) {
    ref
        .read(sharedGitReviewProvider.notifier)
        .open(
          widget.workspace.id,
          SharedGitReview(
            _session!.repository,
            comparison: comparison,
            reviewedFiles: List.unmodifiable(
              shared.gitStatusComparisons(_session!.snapshot),
            ),
            log: log,
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
        ?.comparison;
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
              TextButton(
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
      if (!_loading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_attach());
        });
      }
      return const Center(child: CircularProgressIndicator());
    }
    return _gitCommands(
      context,
      _session!,
      shared.GitCommitView(
        session: _session!,
        protectMessageDrafts: false,
        reviewContext: () => (
          ref.read(sharedGitReviewProvider)[widget.workspace.id],
          ref.read(workspaceControllerProvider).activeBufferId,
        ),
        selectedComparison: selection,
        notice: trusted
            ? null
            : Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(context.l10n.gitTrustRequiredTitle),
                  TextButton(
                    onPressed: () async {
                      if (await _ensureGitTrust(
                            context,
                            ref,
                            widget.workspace,
                            _session!.repository,
                          ) &&
                          mounted) {
                        await _session!.refresh();
                      }
                    },
                    child: Text(context.l10n.gitTrustWorkspace),
                  ),
                ],
              ),
        onReview: (comparison) => _review(comparison: comparison),
        onLog: () => _review(log: true),
        onBranches: () => shared.GitWorkflowUi(context, _session!).branches(),
        onPush: () => shared.GitWorkflowUi(context, _session!).push(),
        onMore: (anchor) => shared.GitWorkflowUi(anchor, _session!).more(),
      ),
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
  bool _attaching = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_session != null || _attaching) return;
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
          !identical(
            ref.read(sharedGitReviewProvider)[widget.workspace.id],
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
              reviewedFiles: comparisons,
            ),
          );
    };
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          TextButton.icon(
            onPressed: () => ref
                .read(sharedGitReviewProvider.notifier)
                .close(widget.workspace.id),
            icon: const Icon(BusyMarkGlyphs.undo),
            label: Text(context.l10n.gitReturnToDocument),
          ),
          Expanded(
            child: Text(
              widget.review.log
                  ? context.l10n.gitHostGitLog
                  : (widget.review.historyPath ??
                            widget.review.comparison!.path)
                        .display,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      Expanded(
        child: _failure != null
            ? shared.GitFailurePanel(
                error: _failure!,
                onRefresh: () => unawaited(_attach()),
              )
            : _session == null
            ? const Center(child: CircularProgressIndicator())
            : _gitCommands(
                context,
                _session!,
                widget.review.log
                    ? shared.GitLogView(session: _session!)
                    : widget.review.historyPath != null
                    ? shared.GitFileHistoryView(
                        session: _session!,
                        path: widget.review.historyPath!,
                      )
                    : shared.GitDiffView(
                        session: _session!,
                        comparison: widget.review.comparison!,
                        onPreviousFile: _navigate(-1),
                        onNextFile: _navigate(1),
                      ),
              ),
      ),
    ],
  );
}
