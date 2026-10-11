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

class NextcloudNotesSettings extends ConsumerStatefulWidget {
  const NextcloudNotesSettings({super.key});
  @override
  ConsumerState<NextcloudNotesSettings> createState() =>
      _NextcloudNotesSettingsState();
}

class _NextcloudNotesSettingsState
    extends ConsumerState<NextcloudNotesSettings> {
  final _server = TextEditingController();
  @override
  void dispose() {
    _server.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    await ref.read(nextcloudConnectionProvider.notifier).connect(_server.text);
    if (!mounted) return;
    final account = ref.read(nextcloudConnectionProvider).account;
    if (account != null) {
      await _openAccount(account.id);
    }
  }

  Future<void> _openAccount(String accountId) async {
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
    final repository = ref.watch(nextcloudNotesRepositoryProvider).value;
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
                enabled: !connection.busy,
                keyboardType: TextInputType.url,
                autocorrect: false,
                enableSuggestions: false,
                onSubmitted: (_) =>
                    connection.busy ? null : unawaited(_connect()),
              ),
              BusyMarkActionRow(
                key: const ValueKey('nextcloud-connect'),
                title: context.l10n.nextcloudConnect,
                subtitle: context.l10n.nextcloudSignInBrowser,
                onTap: connection.busy ? null : () => unawaited(_connect()),
              ),
            ] else ...[
              BusyMarkActionRow(
                title: account.loginName,
                subtitle: account.server.toString(),
                trailing: Text(
                  '${context.l10n.nextcloudNotes} ${account.appVersion} · ${account.apiVersion}',
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.open,
                onTap: connection.busy
                    ? null
                    : () => unawaited(_openAccount(account.id)),
              ),
              BusyMarkActionRow(
                title: context.l10n.nextcloudReconnect,
                onTap: connection.busy
                    ? null
                    : () => unawaited(controller.reconnect()),
              ),
              BusyMarkActionRow(
                title: context.l10n.nextcloudDisconnect,
                onTap: connection.busy ? null : () => unawaited(_disconnect()),
              ),
            ],
            if (connection.busy)
              BusyMarkActionRow(
                title: context.l10n.nextcloudSignInBrowser,
                trailing: const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            if (connection.phase == NextcloudConnectionPhase.awaitingBrowser)
              BusyMarkActionRow(
                title: context.l10n.cancel,
                onTap: controller.cancel,
              ),
          ],
        ),
        if (account != null) ...[
          _ServerNotesSettings(accountId: account.id),
          if (repository?.accountError(account.id) case final error?)
            BusyMarkStatusBox(
              message: error.message,
              kind: BusyMarkStatusKind.error,
            ),
        ],
        if (connection.error != null)
          BusyMarkStatusBox(
            message: connection.error!,
            kind: BusyMarkStatusKind.error,
          ),
      ],
    );
  }

  Future<void> _disconnect() async {
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
      if (!saved.succeeded) return;
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
              controller: _suffix,
              enabled: draft != null && !settings.busy,
              onChanged: (value) => controller.edit(fileSuffix: value),
            ),
          ],
        ),
        Text(context.l10n.nextcloudServerSettingsExplanation),
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
        if (settings.error != null)
          BusyMarkStatusBox(
            message: settings.error!,
            kind: BusyMarkStatusKind.error,
          ),
        if (settings.phase == NotesSettingsPhase.saved)
          Text(
            settings.normalized
                ? context.l10n.nextcloudSettingsNormalized
                : context.l10n.nextcloudSettingsSaved,
          ),
        if (settings.dirty) Text(context.l10n.closeUnsavedChangesTitle),
        Row(
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
              onPressed: !settings.busy && !settings.dirty
                  ? () => unawaited(controller.load(widget.accountId))
                  : null,
              child: Text(context.l10n.visualizationRetry),
            ),
          ],
        ),
      ],
    );
  }
}
