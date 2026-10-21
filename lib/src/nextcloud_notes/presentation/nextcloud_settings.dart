import '../../search/welcome_notes_action.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/busymark_design.dart';
import '../../app/busymark_dialogs.dart';
import '../../app/localization.dart';
import '../../workspace/workspace_controller.dart';
import '../../workspace/workspace_safety.dart';
import '../application/nextcloud_connection.dart';
import '../application/notes_settings_controller.dart';
import 'notes_sidebar.dart' show nextcloudNotesChangesProvider;
import 'notes_messages.dart';

class NextcloudNotesSettings extends ConsumerStatefulWidget {
  const NextcloudNotesSettings({super.key});
  @override
  ConsumerState<NextcloudNotesSettings> createState() =>
      _NextcloudNotesSettingsState();
}

class _NextcloudNotesSettingsState
    extends ConsumerState<NextcloudNotesSettings> {
  final _server = TextEditingController();
  late final WelcomeNotesActionController _pendingWelcome;
  bool _returningToWelcome = false;
  bool _localSaveFailed = false;
  @override
  void initState() {
    super.initState();
    _pendingWelcome = ref.read(welcomeNotesActionProvider.notifier);
  }

  @override
  void dispose() {
    if (!_returningToWelcome) Future<void>.microtask(_pendingWelcome.clear);
    _server.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final connected = await ref
        .read(nextcloudConnectionProvider.notifier)
        .connect(_server.text);
    if (mounted && connected && ref.read(welcomeNotesActionProvider) != null) {
      _returningToWelcome = true;
      context.go('/');
      return;
    }
    if (!mounted) return;
    final account = ref.read(nextcloudConnectionProvider).account;
    if (account != null) {
      await _openAccount(account.id);
    }
  }

  Future<void> _openAccount(String accountId) async {
    if (!await confirmNotesSettingsDeparture(context) || !mounted) return;
    if (!await confirmSafeToContinue(context, ref) || !mounted) return;
    final opened = await ref
        .read(workspaceControllerProvider.notifier)
        .openNextcloudWorkspace(accountId);
    if (opened && mounted) context.go('/workspace');
  }

  @override
  Widget build(BuildContext context) {
    final connection = ref.watch(nextcloudConnectionProvider);
    final controller = ref.read(nextcloudConnectionProvider.notifier);
    ref.watch(nextcloudNotesChangesProvider);
    final repositoryState = ref.watch(nextcloudNotesRepositoryProvider);
    final repository = repositoryState.value;
    final actionsEnabled =
        !connection.busy &&
        !repositoryState.isLoading &&
        !repositoryState.hasError;
    final account = connection.account == null
        ? null
        : repository == null
        ? connection.account
        : repository.accountById(connection.account!.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BusyMarkGroupedList(
          title: context.l10n.nextcloudNotes,
          filled: true,
          children: [
            if (account == null) ...[
              BusyMarkGroupedTextEntry(
                key: const ValueKey('nextcloud-server'),
                label: context.l10n.nextcloudServer,
                controller: _server,
                enabled: actionsEnabled,
                keyboardType: TextInputType.url,
                textDirection: TextDirection.ltr,
                autocorrect: false,
                enableSuggestions: false,
                onSubmitted: (_) =>
                    actionsEnabled ? unawaited(_connect()) : null,
              ),
              BusyMarkActionRow(
                key: const ValueKey('nextcloud-connect'),
                title: context.l10n.nextcloudConnect,
                subtitle: context.l10n.nextcloudSignInBrowser,
                enabled: actionsEnabled,
                onTap: actionsEnabled ? () => unawaited(_connect()) : null,
              ),
            ] else ...[
              BusyMarkActionRow(
                title: account.loginName,
                subtitleWidget: Directionality(
                  textDirection: TextDirection.ltr,
                  child: SelectableText(account.server.toString()),
                ),
                tooltip:
                    '${context.l10n.nextcloudNotes} ${account.appVersion} · ${account.apiVersion}',
              ),
              BusyMarkActionRow(
                title: context.l10n.open,
                enabled: actionsEnabled,
                onTap: !actionsEnabled
                    ? null
                    : () => unawaited(_openAccount(account.id)),
              ),
              BusyMarkActionRow(
                title: context.l10n.nextcloudReconnect,
                enabled: actionsEnabled,
                onTap: !actionsEnabled
                    ? null
                    : () async {
                        if (await confirmNotesSettingsDeparture(context)) {
                          await controller.reconnect();
                        }
                      },
              ),
              BusyMarkActionRow(
                title: context.l10n.nextcloudDisconnect,
                destructive: true,
                enabled: actionsEnabled,
                onTap: actionsEnabled ? () => unawaited(_disconnect()) : null,
              ),
            ],
            if (connection.busy)
              Semantics(
                liveRegion: true,
                child: BusyMarkActionRow(
                  title: switch (connection.phase) {
                    NextcloudConnectionPhase.starting =>
                      context.l10n.notesStartingConnection,
                    NextcloudConnectionPhase.awaitingBrowser =>
                      context.l10n.nextcloudSignInBrowser,
                    NextcloudConnectionPhase.verifying =>
                      context.l10n.notesVerifyingConnection,
                    NextcloudConnectionPhase.cancelling =>
                      context.l10n.notesCancellingConnection,
                    NextcloudConnectionPhase.removing =>
                      context.l10n.notesRemovingConnection,
                    _ => context.l10n.nextcloudNotes,
                  },
                  trailing: const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            if ({
              NextcloudConnectionPhase.starting,
              NextcloudConnectionPhase.awaitingBrowser,
            }.contains(connection.phase))
              BusyMarkActionRow(
                title: context.l10n.cancel,
                onTap: () {
                  ref.read(welcomeNotesActionProvider.notifier).clear();
                  controller.cancel();
                },
              ),
          ],
        ),
        if (repositoryState.isLoading && !connection.busy)
          LinearProgressIndicator(semanticsLabel: context.l10n.nextcloudNotes),
        if (repositoryState.hasError) ...[
          BusyMarkStatusBox(
            message: context.l10n.notesLoadFailed,
            kind: BusyMarkStatusKind.error,
          ),
          BusyMarkActionRow(
            title: context.l10n.visualizationRetry,
            enabled: !connection.busy && !repositoryState.isLoading,
            onTap: connection.busy || repositoryState.isLoading
                ? null
                : () {
                    ref.invalidate(nextcloudNotesRepositoryProvider);
                    unawaited(controller.reload());
                  },
          ),
        ],
        if (account != null) ...[
          _ServerNotesSettings(accountId: account.id),
          if (repository?.accountError(account.id) case final error?)
            BusyMarkStatusBox(
              message: localizeNotesFailure(context, error),
              kind: BusyMarkStatusKind.error,
            ),
        ],
        if (_localSaveFailed)
          BusyMarkStatusBox(
            message: context.l10n.notesBuffersNotSaved,
            kind: BusyMarkStatusKind.error,
          ),
        if (connection.error != null &&
            !repositoryState.hasError &&
            !repositoryState.isLoading)
          BusyMarkStatusBox(
            message: connection.removedWithWarning
                ? context.l10n.notesRemovedWarning
                : connection.removalFailed
                ? context.l10n.notesLocalRemovalFailed
                : localizeNotesConnectionFailure(context, connection.failure),
            kind: connection.removedWithWarning
                ? BusyMarkStatusKind.warning
                : BusyMarkStatusKind.error,
          ),
      ],
    );
  }

  Future<void> _disconnect() async {
    if (!await confirmNotesSettingsDeparture(context) || !mounted) return;
    final confirmed = await showBusyMarkModalDialog<bool>(
      context,
      builder: (context) => BusyMarkDialogShell(
        title: context.l10n.nextcloudDisconnect,
        actions: [
          BusyMarkDialogButton(
            label: context.l10n.cancel,
            onPressed: () => Navigator.pop(context, false),
          ),
          BusyMarkDialogButton(
            label: context.l10n.nextcloudDisconnect,
            destructive: true,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
        children: [Text(context.l10n.nextcloudDisconnectWarning)],
      ),
    );
    if (confirmed == true && mounted) {
      final saved = await ref
          .read(workspaceControllerProvider.notifier)
          .saveAll();
      if (!saved.succeeded) {
        if (mounted) setState(() => _localSaveFailed = true);
        return;
      }
      if (!mounted) return;
      final accountId = ref.read(nextcloudConnectionProvider).account?.id;
      final removed = await ref
          .read(nextcloudConnectionProvider.notifier)
          .disconnect();
      if (removed && accountId != null) {
        await ref
            .read(workspaceControllerProvider.notifier)
            .closeRemovedNextcloudWorkspace(accountId);
        if (mounted) context.go('/');
      }
    }
  }
}

class _ServerNotesSettings extends ConsumerStatefulWidget {
  const _ServerNotesSettings({required this.accountId});
  final String accountId;
  @override
  ConsumerState<_ServerNotesSettings> createState() =>
      _ServerNotesSettingsState();
}

class _ServerNotesSettingsState extends ConsumerState<_ServerNotesSettings> {
  final _path = TextEditingController();
  final _suffix = TextEditingController();
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        unawaited(
          ref.read(notesSettingsProvider.notifier).load(widget.accountId),
        );
      }
    });
  }

  @override
  void didUpdateWidget(_ServerNotesSettings oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.accountId != oldWidget.accountId) {
      unawaited(
        ref
            .read(notesSettingsProvider.notifier)
            .load(widget.accountId, discard: true),
      );
    }
  }

  @override
  void dispose() {
    _path.dispose();
    _suffix.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(notesSettingsProvider);
    final controller = ref.read(notesSettingsProvider.notifier);
    final draft = settings.draft;
    if (draft != null) {
      if (_path.text != draft.notesPath) _path.text = draft.notesPath;
      if (_suffix.text != draft.fileSuffix) _suffix.text = draft.fileSuffix;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BusyMarkGroupedList(
          title: context.l10n.nextcloudServerSettings,
          filled: true,
          children: [
            BusyMarkGroupedTextEntry(
              key: const ValueKey('notes-settings-path'),
              label: context.l10n.nextcloudNotesPath,
              controller: _path,
              enabled: draft != null && !settings.busy,
              onChanged: (value) => controller.edit(notesPath: value),
            ),
            BusyMarkGroupedTextEntry(
              key: const ValueKey('notes-settings-suffix'),
              label: context.l10n.nextcloudFileSuffix,
              textDirection: TextDirection.ltr,
              controller: _suffix,
              enabled: draft != null && !settings.busy,
              onChanged: (value) => controller.edit(fileSuffix: value),
            ),
          ],
        ),
        Text(context.l10n.nextcloudServerSettingsExplanation),
        Text(context.l10n.notesPathRelative),
        if (settings.busy) ...[
          Semantics(
            liveRegion: true,
            child: Text(
              settings.phase == NotesSettingsPhase.loading
                  ? context.l10n.nextcloudSettingsLoading
                  : context.l10n.nextcloudSettingsSaving,
            ),
          ),
          LinearProgressIndicator(
            semanticsLabel: settings.phase == NotesSettingsPhase.loading
                ? context.l10n.nextcloudSettingsLoading
                : context.l10n.nextcloudSettingsSaving,
          ),
        ],
        if (settings.failure != null || settings.error != null)
          BusyMarkStatusBox(
            message: settings.failure == NotesSettingsFailure.buffersNotSaved
                ? context.l10n.notesBuffersNotSaved
                : settings.failure == NotesSettingsFailure.stale
                ? context.l10n.notesSettingsStale
                : localizeNotesFailure(context, settings.cause),
            kind: BusyMarkStatusKind.error,
          ),
        if (settings.refreshFailed)
          BusyMarkStatusBox(
            message: context.l10n.notesSettingsRefreshFailed,
            kind: BusyMarkStatusKind.warning,
          ),
        if (settings.phase == NotesSettingsPhase.saved)
          Text(
            settings.normalized
                ? context.l10n.nextcloudSettingsNormalized
                : context.l10n.nextcloudSettingsSaved,
          ),
        if (settings.dirty) Text(context.l10n.closeUnsavedChangesTitle),
        Wrap(
          spacing: BusyMarkSpacing.sm,
          runSpacing: BusyMarkSpacing.sm,
          children: [
            BusyMarkPushButton.standard(
              key: const ValueKey('notes-settings-save'),
              onPressed: settings.dirty && !settings.busy
                  ? () => unawaited(
                      controller.save(
                        preserveBuffers: () async =>
                            (await ref
                                    .read(workspaceControllerProvider.notifier)
                                    .saveAll())
                                .succeeded,
                      ),
                    )
                  : null,
              child: Text(context.l10n.save),
            ),
            BusyMarkPushButton.standard(
              onPressed: settings.dirty && !settings.busy
                  ? controller.cancel
                  : null,
              child: Text(context.l10n.cancel),
            ),
            BusyMarkPushButton.standard(
              onPressed: !settings.busy
                  ? () => unawaited(
                      reloadNotesSettings(context, widget.accountId),
                    )
                  : null,
              child: Text(context.l10n.notesSettingsReload),
            ),
          ],
        ),
      ],
    );
  }
}

/// Every settings departure uses the same decision, including native Back and
/// programmatic route exits. Keep the provider alive until the decision settles.
Future<bool> confirmNotesSettingsDeparture(BuildContext context) async {
  final container = ProviderScope.containerOf(context, listen: false);
  if (!container.exists(notesSettingsProvider)) return true;
  final settings = container.read(notesSettingsProvider);
  if (settings.phase == NotesSettingsPhase.saving) return false;
  if (!settings.dirty) return true;
  final decision = await showBusyMarkModalDialog<String>(
    context,
    builder: (context) => BusyMarkDialogShell(
      title: context.l10n.notesSettingsLeave,
      actions: [
        BusyMarkDialogButton(
          label: context.l10n.cancel,
          onPressed: () => Navigator.pop(context),
        ),
        BusyMarkDialogButton(
          label: context.l10n.discard,
          destructive: true,
          onPressed: () => Navigator.pop(context, 'discard'),
        ),
        BusyMarkDialogButton(
          label: context.l10n.save,
          onPressed: () => Navigator.pop(context, 'save'),
        ),
      ],
      children: [Text(context.l10n.notesSettingsLeaveHelp)],
    ),
  );
  if (!context.mounted) return false;
  final controller = container.read(notesSettingsProvider.notifier);
  if (decision == 'discard') {
    controller.cancel();
    return true;
  }
  if (decision != 'save') return false;
  return controller.save(
    preserveBuffers: () async =>
        (await container.read(workspaceControllerProvider.notifier).saveAll())
            .succeeded,
  );
}

Future<void> reloadNotesSettings(BuildContext context, String accountId) async {
  final container = ProviderScope.containerOf(context, listen: false);
  if (container.read(notesSettingsProvider).dirty) {
    final discard = await showBusyMarkModalDialog<bool>(
      context,
      builder: (context) => BusyMarkDialogShell(
        title: context.l10n.notesSettingsReload,
        actions: [
          BusyMarkDialogButton(
            label: context.l10n.cancel,
            onPressed: () => Navigator.pop(context, false),
          ),
          BusyMarkDialogButton(
            label: context.l10n.discard,
            destructive: true,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
        children: [Text(context.l10n.notesSettingsReloadHelp)],
      ),
    );
    if (discard != true || !context.mounted) return;
  }
  await container
      .read(notesSettingsProvider.notifier)
      .load(accountId, discard: true);
}
