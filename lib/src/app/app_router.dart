import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../workspace/presentation/settings_screen.dart';
import '../workspace/presentation/welcome_screen.dart';
import '../workspace/presentation/workspace_screen.dart';

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
        path: '/settings',
        pageBuilder: (context, state) =>
            const NoTransitionPage<void>(child: SettingsScreen()),
      ),
    ],
  );
});
