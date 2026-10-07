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
    final account = connection.account;
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
