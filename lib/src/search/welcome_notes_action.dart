import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_router.dart';
import '../app/command_registry.dart';
import '../local_history/local_history_controller.dart';
import '../nextcloud_notes/application/nextcloud_connection.dart';
import '../workspace/workspace_navigation.dart';
import '../workspace/workspace_controller.dart';
import 'search_session.dart';

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
  WorkspaceNavigation navigation,
  Uri origin,
  bool Function() currentNavigation,
  WelcomeNotesAction action,
) async {
  final container = navigation.container;
  final pending = container.read(welcomeNotesActionProvider.notifier);
  if (pending.busy) return;
  pending.busy = true;
  try {
    final fromWorkspace =
        settingsReturnTargetForUri(origin) == SettingsReturnTarget.workspace;
    if (origin.path != '/' &&
        origin.path != '/workspace' &&
        origin.path != settingsRoutePath) {
      return;
    }
    await container.read(nextcloudConnectionProvider.notifier).reload();
    if (!currentNavigation()) {
      pending.clear();
      return;
    }
    final activeAccount = fromWorkspace
        ? container
              .read(workspaceControllerProvider)
              .workspace
              ?.nextcloudAccountId
        : null;
    final repository = container.read(nextcloudNotesRepositoryProvider).value;
    final account = activeAccount == null
        ? container.read(nextcloudConnectionProvider).account
        : repository?.accountById(activeAccount);
    if (activeAccount != null && account == null) {
      pending.clear();
      navigation.showUnavailable();
      return;
    }
    if (account == null) {
      // Returning without a successful connection cancels the pending operation.
      if (container.read(welcomeNotesActionProvider) != null) {
        pending.clear();
        return;
      }
      pending.request(action);
      navigation.router.go(
        '${settingsLocation(SettingsReturnTarget.welcome)}&page=nextcloudNotes',
      );
      return;
    }
    pending
        .clear(); // Claim once before any asynchronous work or pointer reactivation.
    bool currentRequest() =>
        currentNavigation() &&
        (activeAccount == null
            ? container.read(nextcloudConnectionProvider).account?.id ==
                  account.id
            : container
                          .read(workspaceControllerProvider)
                          .workspace
                          ?.nextcloudAccountId ==
                      account.id &&
                  repository?.accountById(account.id) != null);
    final controller = container.read(workspaceControllerProvider.notifier);
    if (container
            .read(workspaceControllerProvider)
            .workspace
            ?.nextcloudAccountId !=
        account.id) {
      if (!await navigation.confirmDeparture(canContinue: currentRequest) ||
          !currentRequest() ||
          !await controller.openNextcloudWorkspace(
            account.id,
            acceptNavigation: currentRequest,
          )) {
        return;
      }
    }
    if (!currentRequest() ||
        container
                .read(workspaceControllerProvider)
                .workspace
                ?.nextcloudAccountId !=
            account.id) {
      return;
    }
    container.read(searchSessionProvider.notifier).close(restoreFocus: false);
    if (action == WelcomeNotesAction.create) {
      container.read(localHistoryControllerProvider.notifier).clearComparison();
      if (!await controller.createNextcloudNote(
        acceptNavigation: currentRequest,
        focusEditor: true,
      )) {
        return;
      }
      if (!currentRequest()) return;
    }
    if (currentRequest()) {
      final router = navigation.router;
      final commands = container.read(
        workspaceNavigationCommandProvider.notifier,
      );
      if (action == WelcomeNotesAction.create) {
        navigation.reveal();
      } else {
        router.go('/workspace');
      }
      if (action == WelcomeNotesAction.browse && fromWorkspace) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (router.routeInformationProvider.value.uri.path == '/workspace') {
            commands.request(BusyMarkCommandIds.sidebarFiles);
          }
        });
      }
    }
  } finally {
    pending.busy = false;
  }
}
