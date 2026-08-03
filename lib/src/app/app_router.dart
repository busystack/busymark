import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../workspace/presentation/settings_screen.dart';
import '../workspace/presentation/welcome_screen.dart';
import '../workspace/presentation/workspace_screen.dart';

const settingsRoutePath = '/settings';
const _settingsReturnTargetParameter = 'returnTo';

enum SettingsReturnTarget {
  welcome('/'),
  workspace('/workspace');

  const SettingsReturnTarget(this.location);

  final String location;

  static SettingsReturnTarget fromSettingsUri(Uri uri) {
    final encodedTarget = uri.queryParameters[_settingsReturnTargetParameter];
    return SettingsReturnTarget.values.firstWhere(
      (target) => target.name == encodedTarget,
      orElse: () => SettingsReturnTarget.welcome,
    );
  }
}

String settingsLocation(SettingsReturnTarget returnTarget) {
  return Uri(
    path: settingsRoutePath,
    queryParameters: {_settingsReturnTargetParameter: returnTarget.name},
  ).toString();
}

SettingsReturnTarget settingsReturnTargetForUri(Uri currentUri) {
  return switch (currentUri.path) {
    settingsRoutePath => SettingsReturnTarget.fromSettingsUri(currentUri),
    '/workspace' => SettingsReturnTarget.workspace,
    _ => SettingsReturnTarget.welcome,
  };
}

String settingsLocationForUri(Uri currentUri) {
  return settingsLocation(settingsReturnTargetForUri(currentUri));
}

final rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'BusyMark root navigator',
);

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) =>
            const NoTransitionPage<void>(child: WelcomeScreen()),
      ),
      GoRoute(
        path: '/workspace',
        pageBuilder: (context, state) =>
            const NoTransitionPage<void>(child: WorkspaceScreen()),
      ),
      GoRoute(
        path: settingsRoutePath,
        pageBuilder: (context, state) => NoTransitionPage<void>(
          child: SettingsScreen(
            returnTarget: SettingsReturnTarget.fromSettingsUri(state.uri),
            initialPage: settingsPageFromRouteValue(
              state.uri.queryParameters['page'],
            ),
          ),
        ),
      ),
    ],
  );
});
