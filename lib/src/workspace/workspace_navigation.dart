import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/app_router.dart';
import '../app/busymark_toast.dart';
import '../app/localization.dart';
import '../search/search_session.dart';
import 'workspace_controller.dart';
import 'workspace_safety.dart';
import 'workspace_tab_actions.dart';

final workspaceNavigationProvider = Provider(WorkspaceNavigation.new);

/// Owns resource navigation for the lifetime of the window. Its dialogs use
/// the root navigator even when a header, search row or workspace disappears.
class WorkspaceNavigation {
  WorkspaceNavigation(this._ref) : router = _ref.read(appRouterProvider) {
    var location = router.routeInformationProvider.value.uri;
    void routeChanged() {
      final next = router.routeInformationProvider.value.uri;
      if (next == location) return;
      location = next;
      _intent = null;
      _revision++;
    }

    router.routeInformationProvider.addListener(routeChanged);
    _ref.onDispose(() {
      router.routeInformationProvider.removeListener(routeChanged);
    });
  }

  final Ref _ref;
  ProviderContainer get container => _ref.container;
  final GoRouter router;
  int _revision = 0;
  Object? _intent;
  Future<void>? _finishing;

  BuildContext? get dialogContext =>
      router.routerDelegate.navigatorKey.currentContext;

  Future<void> run(
    Object intent,
    Future<void> Function(Uri origin, bool Function() isCurrent) navigate,
  ) async {
    if (_intent == intent) return;
    _intent = intent;
    final revision = ++_revision;
    final origin = router.routeInformationProvider.value.uri;
    final previous = _finishing;
    final finished = Completer<void>();
    _finishing = finished.future;
    bool current() => _ref.mounted && revision == _revision;
    try {
      // Let a superseded operation release any controller loading state
      // before the next intent starts against that workspace.
      if (previous != null) await previous;
      if (current()) await navigate(origin, current);
    } finally {
      if (identical(_finishing, finished.future)) _finishing = null;
      if (revision == _revision) _intent = null;
      finished.complete();
    }
  }

  Future<bool> confirmDeparture({
    required bool Function() canContinue,
    bool deferDiscard = false,
  }) async {
    final context = dialogContext;
    return context != null &&
        canContinue() &&
        await confirmWorkspaceDeparture(
          context,
          container,
          canContinue: canContinue,
          deferDiscard: deferDiscard,
        );
  }

  void reveal({bool focusNewDocument = false}) {
    _ref.read(revealOpenedDocumentProvider)();
    _ref.read(searchSessionProvider.notifier).close(restoreFocus: false);
    if (focusNewDocument) {
      final id = _ref.read(workspaceControllerProvider).activeBufferId;
      if (id != null) {
        _ref
            .read(workspaceControllerProvider.notifier)
            .focusNewlyCreatedDocument(id);
      }
    }
    router.go('/workspace');
  }

  void showUnavailable() {
    final context = dialogContext;
    if (context == null) return;
    BusyMarkToastOverlay.show(
      context,
      message: context.l10n.searchResourceUnavailable,
    );
  }
}
