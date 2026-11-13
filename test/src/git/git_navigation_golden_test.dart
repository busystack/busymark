import 'package:busystack_git_flutter/busystack_git_flutter.dart' as git;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'git_navigation_visual_contract_test.dart'
    show mountGitVisualContract, loadGitVisualFonts;

// These exercise production host rendering with official packaged fonts.
// Native GTK framebuffer captures remain a separate acceptance requirement.
void main() {
  setUpAll(loadGitVisualFonts);
  for (final brightness in Brightness.values) {
    for (final view in ['branches', 'inspector', 'history']) {
      testWidgets('native Git $view painted surface ${brightness.name}', (
        tester,
      ) async {
        await mountGitVisualContract(
          tester,
          (session) => RepaintBoundary(
            key: const ValueKey('golden'),
            child: Builder(
              builder: (context) => ColoredBox(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: switch (view) {
                  'branches' => git.GitBranchesView(session: session),
                  'inspector' => git.GitLogView(
                    session: session,
                    inspector: true,
                  ),
                  _ => git.GitLogView(
                    session: session,
                    onChooseCommit: (_) {},
                    preserveActionsWhenChoosing: true,
                  ),
                },
              ),
            ),
          ),
          size: Size(
            view == 'history'
                ? 1100
                : view == 'branches'
                ? 660
                : 320,
            600,
          ),
          brightness: brightness,
        );
        await expectLater(
          find.byKey(const ValueKey('golden')),
          matchesGoldenFile('goldens/git-$view-${brightness.name}.png'),
        );
      });
    }
  }
}
