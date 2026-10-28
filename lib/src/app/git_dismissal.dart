import 'package:busystack_git_flutter/busystack_git_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Draft guards are scoped to this application's window/provider container.
final busyMarkGitDismissalProvider = Provider<GitDismissalRegistry>(
  (_) => GitDismissalRegistry(),
);
