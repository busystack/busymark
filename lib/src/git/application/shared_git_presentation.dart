import 'package:flutter/widgets.dart';
import 'package:busystack_git_flutter/busystack_git_flutter.dart' as git;
import '../../app/localization.dart';

/// Git's first-party native dialog surface.
///
/// The standard BusyMark dialog remains available to unrelated application
/// screens. Git presentation uses this Yaru surface so its rendering chain
/// contains no BusyStack-owned stock Material dialog construction.
class BusyMarkGitDialogShell extends StatelessWidget {
  const BusyMarkGitDialogShell({
    super.key,
    required this.title,
    this.children = const [],
    this.body,
    this.expanded = false,
    this.actions = const [],
  });
  final String title;
  final List<Widget> children, actions;
  final Widget? body;
  final bool expanded;
  @override
  Widget build(BuildContext context) => git.GitNativeDialog(
    title: title,
    expanded: expanded,
    child: actions.isEmpty && children.isEmpty && body != null
        ? body!
        : git.GitDialogForm(
            body: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [if (body != null) body!, ...children],
            ),
            actions: actions,
          ),
  );
}

typedef BusyMarkGitActionRole = git.NativeGitActionRole;
typedef BusyMarkGitActionButton = git.NativeGitActionButton;
typedef BusyMarkGitActionButtonState = git.NativeGitActionButtonState;
typedef BusyMarkGitTextEntry = git.NativeGitTextEntry;

/// The retained Commit sidebar needs two unabridged native actions. Resolve
/// the existing button themes and actual localized text rather than shrinking
/// labels or changing fonts. English at normal scale keeps the usual 300px.
double busyMarkGitSidebarMinimumWidth(BuildContext context) =>
    git.gitSidebarMinimumWidth(
      context,
      presentation: const BusyMarkGitPresentation(),
      commitLabel: context.l10n.gitUiCommit,
      commitAndPushLabel: context.l10n.gitUiCommitAndPush,
    );

/// Provision the canonical shared Linux Git renderer. Host services and app
/// chrome stay outside this const-only presentation adapter.
final class BusyMarkGitPresentation extends git.YaruGitPresentation {
  const BusyMarkGitPresentation();
}
