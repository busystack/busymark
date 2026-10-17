import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/app_router.dart';
import '../app/busymark_toast.dart';
import '../app/localization.dart';
import '../nextcloud_notes/application/nextcloud_connection.dart';
import '../workspace/workspace_controller.dart';
import '../workspace/workspace_safety.dart';

enum WelcomeNotesAction { create, browse }

final welcomeNotesActionProvider =
    NotifierProvider<WelcomeNotesActionController, WelcomeNotesAction?>(
      WelcomeNotesActionController.new,
    );

class WelcomeNotesActionController extends Notifier<WelcomeNotesAction?> {
  bool busy = false;
  @override
  WelcomeNotesAction? build() {
    final router = ref.read(appRouterProvider);
    void routeChanged() {
      final uri = router.routeInformationProvider.value.uri;
      if (uri.path != '/' &&
          !(uri.path == settingsRoutePath &&
              uri.queryParameters['page'] == 'nextcloudNotes')) {
        clear();
      }
    }

    router.routeInformationProvider.addListener(routeChanged);
    ref.onDispose(
      () => router.routeInformationProvider.removeListener(routeChanged),
    );
    return null;
  }

  void request(WelcomeNotesAction action) => state = action;
  void clear() {
    if (ref.mounted && state != null) state = null;
  }
}

Future<void> performWelcomeNotesAction(
  BuildContext context,
  WidgetRef ref,
  WelcomeNotesAction action,
) async {
  final pending = ref.read(welcomeNotesActionProvider.notifier);
  if (pending.busy) return;
  pending.busy = true;
  try {
    final origin = ref
        .read(appRouterProvider)
        .routeInformationProvider
        .value
        .uri;
    if (origin.path != '/' && origin.path != '/workspace') return;
    await ref.read(nextcloudConnectionProvider.notifier).reload();
    if (!context.mounted ||
        ref.read(appRouterProvider).routeInformationProvider.value.uri !=
            origin) {
      pending.clear();
      return;
    }
    final activeAccount = origin.path == '/workspace'
        ? ref.read(workspaceControllerProvider).workspace?.nextcloudAccountId
        : null;
    final repository = ref.read(nextcloudNotesRepositoryProvider).value;
    final account = activeAccount == null
        ? ref.read(nextcloudConnectionProvider).account
        : repository?.accountById(activeAccount);
    if (activeAccount != null && account == null) {
      pending.clear();
      BusyMarkToastOverlay.show(
        context,
        message: context.l10n.searchResourceUnavailable,
      );
      return;
    }
    if (account == null) {
      // Returning without a successful connection cancels the pending operation.
      if (ref.read(welcomeNotesActionProvider) != null) {
        pending.clear();
        return;
      }
      pending.request(action);
      context.go(
        '${settingsLocation(SettingsReturnTarget.welcome)}&page=nextcloudNotes',
      );
      return;
    }
    pending
        .clear(); // Claim once before any asynchronous work or pointer reactivation.
    bool currentRequest() =>
        context.mounted &&
        ref.read(appRouterProvider).routeInformationProvider.value.uri ==
            origin &&
        (activeAccount == null
            ? ref.read(nextcloudConnectionProvider).account?.id == account.id
            : ref
                          .read(workspaceControllerProvider)
                          .workspace
                          ?.nextcloudAccountId ==
                      account.id &&
                  repository?.accountById(account.id) != null);
    if (!await confirmSafeToContinue(context, ref) || !context.mounted) return;
    if (ref.read(appRouterProvider).routeInformationProvider.value.uri !=
        origin) {
      return;
    }
    final controller = ref.read(workspaceControllerProvider.notifier);
    if (ref.read(workspaceControllerProvider).workspace?.nextcloudAccountId !=
            account.id &&
        !await controller.openNextcloudWorkspace(
          account.id,
          acceptNavigation: currentRequest,
        )) {
      return;
    }
    if (!context.mounted ||
        ref.read(appRouterProvider).routeInformationProvider.value.uri !=
            origin ||
        !currentRequest() ||
        ref.read(workspaceControllerProvider).workspace?.nextcloudAccountId !=
            account.id) {
      return;
    }
    if (action == WelcomeNotesAction.create &&
        !await controller.createNextcloudNote(
          acceptNavigation: currentRequest,
        )) {
      return;
    }
    if (context.mounted && currentRequest()) context.go('/workspace');
  } finally {
    pending.busy = false;
  }
}
