import 'dart:async';

import 'package:busymark/l10n/generated/app_localizations_en.dart';
import 'package:busymark/src/app/app_router.dart';
import 'package:busymark/src/app/busymark_app.dart';
import 'package:busymark/src/app/busymark_shortcuts.dart';
import 'package:busymark/src/platform/linux_header_bar_service.dart';
import 'package:busymark/src/workspace/presentation/settings_screen.dart';
import 'package:busymark/src/workspace/workspace_controller.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsEn();

  test('settings return targets are explicit and validated', () {
    expect(
      SettingsReturnTarget.fromSettingsUri(
        Uri.parse('/settings?returnTo=workspace'),
      ),
      SettingsReturnTarget.workspace,
    );
    expect(
      SettingsReturnTarget.fromSettingsUri(
        Uri.parse('/settings?returnTo=welcome'),
      ),
      SettingsReturnTarget.welcome,
    );
    expect(
      SettingsReturnTarget.fromSettingsUri(Uri.parse('/settings')),
      SettingsReturnTarget.welcome,
    );
    expect(
      SettingsReturnTarget.fromSettingsUri(
        Uri.parse('/settings?returnTo=/workspace'),
      ),
      SettingsReturnTarget.welcome,
    );
    expect(
      SettingsReturnTarget.fromSettingsUri(
        Uri.parse('/settings?returnTo=unexpected'),
      ),
      SettingsReturnTarget.welcome,
    );
  });

  test('opening Settings preserves a validated Settings origin', () {
    expect(
      settingsLocationForUri(Uri.parse('/')),
      '/settings?returnTo=welcome',
    );
    expect(
      settingsLocationForUri(Uri.parse('/workspace')),
      '/settings?returnTo=workspace',
    );
    expect(
      settingsLocationForUri(Uri.parse('/settings?returnTo=workspace')),
      '/settings?returnTo=workspace',
    );
    expect(
      settingsLocationForUri(Uri.parse('/settings?returnTo=untrusted')),
      '/settings?returnTo=welcome',
    );
  });

  test('settings page routes are explicit and validated', () {
    expect(settingsPageFromRouteValue(null), SettingsPage.appearance);
    expect(settingsPageFromRouteValue('editor'), SettingsPage.editor);
    expect(settingsPageFromRouteValue('validation'), SettingsPage.validation);
    expect(settingsPageFromRouteValue('ai'), SettingsPage.ai);
    expect(settingsPageFromRouteValue('window'), SettingsPage.window);
    expect(settingsPageFromRouteValue('privacy'), SettingsPage.privacy);
    expect(settingsPageFromRouteValue('advanced'), SettingsPage.advanced);
    expect(settingsPageFromRouteValue('unexpected'), SettingsPage.appearance);
    expect(
      SettingsPage.values.map(settingsPageRouteValue),
      SettingsPage.values.map((page) => page.name),
    );
  });

  testWidgets(
    'Settings opened from Welcome returns to Welcome with a stale workspace',
    (tester) async {
      final headerBar = _FallbackHeaderBarService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            linuxHeaderBarServiceProvider.overrideWithValue(headerBar),
            workspaceControllerProvider.overrideWith(
              () => _StaleWorkspaceController(),
            ),
          ],
          child: const BusyMarkApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n.createMarkdownFile), findsOneWidget);

      await tester.tap(find.byTooltip(l10n.mainMenu));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.settings));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('settings-page-selector')),
        findsOneWidget,
      );

      await tester.tap(
        find.byTooltip('${l10n.back} (${BusyMarkAppShortcutLabels.back})'),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('settings-page-selector')),
        findsNothing,
      );
      expect(find.text(l10n.createMarkdownFile), findsOneWidget);
    },
  );

  testWidgets('returning to Welcome does not restore the session again', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          linuxHeaderBarServiceProvider.overrideWithValue(
            _FallbackHeaderBarService(),
          ),
          workspaceControllerProvider.overrideWith(
            _RestoringWorkspaceController.new,
          ),
        ],
        child: const BusyMarkApp(),
      ),
    );
    for (var index = 0; index < 30; index += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find
          .byTooltip('${l10n.welcome} (${BusyMarkAppShortcutLabels.back})')
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }

    expect(
      find.byTooltip('${l10n.welcome} (${BusyMarkAppShortcutLabels.back})'),
      findsOneWidget,
    );
    await tester.tap(
      find.byTooltip('${l10n.welcome} (${BusyMarkAppShortcutLabels.back})'),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text(l10n.createMarkdownFile), findsOneWidget);
    expect(
      find.byTooltip('${l10n.welcome} (${BusyMarkAppShortcutLabels.back})'),
      findsNothing,
    );
  });
}

class _FallbackHeaderBarService extends LinuxHeaderBarService {
  _FallbackHeaderBarService()
    : super(channel: const MethodChannel('test.busymark/headerbar.router'));

  @override
  bool get isAvailable => false;

  @override
  bool get usesNativeHeaderBar => false;

  @override
  Stream<HeaderBarAction> get actions => const Stream.empty();
}

class _StaleWorkspaceController extends WorkspaceController {
  @override
  WorkspaceState build() {
    return WorkspaceState(
      workspace: Workspace(
        id: 'stale-workspace',
        rootPath: '/tmp/stale-workspace.md',
        kind: WorkspaceKind.singleMarkdown,
        openedAt: DateTime(2026),
        files: const [],
        diagnostics: const [],
      ),
    );
  }
}

class _RestoringWorkspaceController extends WorkspaceController {
  @override
  WorkspaceState build() => const WorkspaceState();

  @override
  Future<bool> restorePreviousSession() async {
    state = WorkspaceState(
      workspace: Workspace(
        id: 'restored-workspace',
        rootPath: '/tmp/restored.md',
        kind: WorkspaceKind.singleMarkdown,
        openedAt: DateTime(2026),
        activeFilePath: '/tmp/restored.md',
        files: [
          DocumentFile(
            absolutePath: '/tmp/restored.md',
            relativePath: 'restored.md',
            kind: DocumentKind.markdown,
            size: 20,
            lastModified: DateTime(2026),
          ),
        ],
        diagnostics: const [],
      ),
    );
    return true;
  }
}
