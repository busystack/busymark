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

typedef BusyMarkGitClientFactory =
    shared.GitClient Function({
      required bool Function(shared.RepositoryId) authorize,
      shared.GitPromptHandler? prompts,
    });
final sharedGitClientFactoryProvider = Provider<BusyMarkGitClientFactory>(
  (_) =>
      ({required authorize, prompts}) =>
          shared.GitEngine(authorize: authorize, prompts: prompts),
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
  var _discoveryCancellation = shared.GitCancellation();
  var _generation = 0;
  Future<shared.RepositoryId?>? _discovery;
  shared.GitClient? _client;

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
    if (!mounted) return null;
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
        oldWidget.workspace.rootPath != widget.workspace.rootPath) {
      _releaseAttachments();
      _discoveryCancellation = shared.GitCancellation();
    }
  }

  void _releaseAttachments() {
    _generation++;
    _discoveryCancellation.cancel();
    for (final session in _owned) {
      session.dispose();
    }
    _owned.clear();
    _sessions.clear();
    _discovery = null;
    _client = null;
  }

  @override
  void dispose() {
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
  });
  final shared.RepositoryId repository;
  final shared.GitComparison? comparison;
  final bool log;
  final shared.RepoPath? historyPath;
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
      await ui.present('Fetch', shared.GitFetchView(session: session));
    case 'pull':
      await ui.pull();
    case 'push':
      await ui.push();
    case 'more':
      await ui.more();
  }
}

final class BusyMarkGitDraftStore implements shared.GitDraftStore {
  Future<Map<String, Object>?> readViewState(String key) async {
    final value = await read('$key-view');
    return value == null
        ? null
        : Map<String, Object>.from(jsonDecode(value) as Map);
  }

  Future<void> writeViewState(String key, Map<String, Object> value) =>
      write('$key-view', jsonEncode(value));
  Future<File> _file(String key) async {
    final directory = Directory(
      p.join((await getApplicationSupportDirectory()).path, 'git-drafts'),
    );
    await directory.create(recursive: true);
    return File(p.join(directory.path, '$key.txt'));
  }

  final _tails = <String, Future<void>>{};
  final _memory = <String, String>{};
  @override
  Future<String?> read(String worktreeKey) async {
    if (_memory.containsKey(worktreeKey)) return _memory[worktreeKey];
    await _tails[worktreeKey];
    final file = await _file(worktreeKey);
    return await file.exists() ? file.readAsString() : null;
  }

  @override
  Future<void> write(String worktreeKey, String message) {
    _memory[worktreeKey] = message;
    Future<void> save() async {
      final file = await _file(worktreeKey),
          temporary = File('${(await _file(worktreeKey)).path}.pending');
      await temporary.writeAsString(message, flush: true);
      await temporary.rename(file.path);
    }

    final next = (_tails[worktreeKey] ?? Future<void>.value()).then(
      (_) => save(),
      onError: (Object error, StackTrace stack) => save(),
    );
    return _tails[worktreeKey] = next;
  }
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
            'Refresh Git status',
            const SingleActivator(LogicalKeyboardKey.f5),
            session.refresh,
          ),
          (
            'commit',
            'Commit staged',
            const SingleActivator(LogicalKeyboardKey.enter, control: true),
            () async {
              if (session.canCommit?.call() == true) {
                await session.commitAction?.call(false);
              }
            },
          ),
          (
            'branches',
            'Git branches',
            const SingleActivator(
              LogicalKeyboardKey.keyB,
              control: true,
              shift: true,
            ),
            () => shared.GitWorkflowUi(context, session).branches(),
          ),
          (
            'push',
            'Review push',
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
        category: (_) => 'Git',
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
  final approved = await showBusyMarkModalDialog<bool>(
    context,
    builder: (dialogContext) => AlertDialog(
      title: Text(context.l10n.gitTrustRequiredTitle),
      content: Text(
        '${repository.root}\n\n${context.l10n.gitTrustRequiredMessage}\n'
        'Git operations apply to this entire repository and may execute its configured hooks, filters, credential and signing tools.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(context.l10n.gitTrustWorkspace),
        ),
      ],
    ),
  );
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
  final strings = context.l10n;
  var reconcileWorkingFiles = true;
  return shared.GitHost(
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
    translate: (key, fallback) => switch (fallback) {
      'Cancel' => strings.cancel,
      'Close' => strings.close,
      'Apply' => strings.apply,
      'Open' => strings.open,
      'Commit' => strings.gitCommit,
      'Commit message' => strings.gitCommitMessage,
      'Staged' => strings.gitStaged,
      'Unstaged' => strings.gitUnstaged,
      'Untracked' => strings.gitUntracked,
      'No changes' => strings.gitNoChanges,
      'Branches…' => '${strings.gitBranches}…',
      'Fetch…' => '${strings.gitFetch}…',
      'Pull…' => '${strings.gitPull}…',
      'Push…' => '${strings.gitPush}…',
      _ => fallback,
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
                          onPressed: () => Navigator.of(context).pop(),
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
                  snapshot.version.label,
                  path.display,
                ),
                text: snapshot.text ?? 'Content unavailable',
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
        // The shared session already has the engine's reconciled outcome.
        // Keep the compatibility status used by authoring commands current in
        // the background, without extending the completed operation's lifetime.
        unawaited(ref.read(gitControllerProvider.notifier).refresh());
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
                    initialize ? 'Initialize repository' : 'Clone repository',
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
                  initialize ? 'Initialize here…' : 'Clone repository…',
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
    final comparisons = shared.gitStatusComparisons(_session?.snapshot);
    final index = shared.gitComparisonIndex(
          comparisons,
          widget.review.comparison,
        ),
        next =
            shared.gitComparisonIndex(comparisons, widget.review.comparison) +
            direction;
    if (index < 0 || next < 0 || next >= comparisons.length) return null;
    return () => ref
        .read(sharedGitReviewProvider.notifier)
        .open(
          widget.workspace.id,
          SharedGitReview(
            widget.review.repository,
            comparison: comparisons[next],
          ),
        );
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
                  ? 'Git Log'
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
