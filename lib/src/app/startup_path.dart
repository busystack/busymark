import 'package:flutter_riverpod/flutter_riverpod.dart';

final startupPathProvider = Provider<String?>((ref) => null);

/// Claims startup-only navigation work once for the lifetime of the app's
/// provider container.
///
/// [WelcomeScreen] can be mounted again when the user deliberately returns to
/// Welcome. Keeping these flags in widget state would make that navigation
/// look like a new application startup and reopen the command-line path or
/// previous session immediately.
final startupNavigationGuardProvider = Provider<StartupNavigationGuard>(
  (ref) => StartupNavigationGuard(),
);

class StartupNavigationGuard {
  bool _startupPathClaimed = false;
  bool _sessionRestoreClaimed = false;

  bool claimStartupPath(String? path) {
    if (_startupPathClaimed || path == null || path.isEmpty) {
      return false;
    }
    _startupPathClaimed = true;
    return true;
  }

  bool claimSessionRestore(String? startupPath) {
    if (_sessionRestoreClaimed ||
        (startupPath != null && startupPath.isNotEmpty)) {
      return false;
    }
    _sessionRestoreClaimed = true;
    return true;
  }
}
