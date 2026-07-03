import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/l10n/generated/app_localizations_en.dart';
import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/busymark_glyphs.dart';
import 'package:busymark/src/workspace/workspace_controller.dart';
import 'package:busymark/src/workspace/workspace_safety.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsEn();

  testWidgets(
    'unsaved changes dialog aborts destructive navigation on cancel',
    (tester) async {
      bool? safeToContinue;
      late WidgetRef widgetRef;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localSettingsStoreProvider.overrideWithValue(
              _MemorySettingsStore(),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: buildBusyMarkTheme(
              brightness: Brightness.light,
              accentColor: Colors.green,
            ),
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  widgetRef = ref;
                  return Column(
                    children: [
                      TextButton(
                        onPressed: () async {
                          safeToContinue = await confirmSafeToContinue(
                            context,
                            ref,
                          );
                        },
                        child: const Text('Navigate'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      final controller = widgetRef.read(workspaceControllerProvider.notifier);
      await tester.runAsync(() async {
        await controller.openPath('test/fixtures/markdown/other.md');
        controller.updateActiveText('# Dirty\n');
      });
      expect(
        widgetRef.read(workspaceControllerProvider).hasUnsavedChanges,
        isTrue,
      );

      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      expect(find.text(l10n.unsavedChanges), findsOneWidget);
      expect(find.byType(BusyMarkDialogButton), findsNWidgets(3));
      expect(find.byIcon(BusyMarkGlyphs.clear), findsOneWidget);
      expect(find.byIcon(BusyMarkGlyphs.delete), findsOneWidget);
      expect(find.byIcon(BusyMarkGlyphs.save), findsOneWidget);
      await tester.tap(find.text(l10n.cancel));
      await tester.pumpAndSettle();

      expect(safeToContinue, isFalse);
    },
  );

  testWidgets('discarding unsaved changes prevents repeated prompts', (
    tester,
  ) async {
    var safeToContinueCount = 0;
    late WidgetRef widgetRef;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localSettingsStoreProvider.overrideWithValue(_MemorySettingsStore()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildBusyMarkTheme(
            brightness: Brightness.light,
            accentColor: Colors.green,
          ),
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, child) {
                widgetRef = ref;
                return TextButton(
                  onPressed: () async {
                    if (await confirmSafeToContinue(context, ref)) {
                      safeToContinueCount++;
                    }
                  },
                  child: const Text('Navigate'),
                );
              },
            ),
          ),
        ),
      ),
    );

    final controller = widgetRef.read(workspaceControllerProvider.notifier);
    await tester.runAsync(() async {
      await controller.openPath('test/fixtures/markdown/other.md');
      controller.updateActiveText('# Dirty\n');
    });

    await tester.tap(find.text('Navigate'));
    await tester.pumpAndSettle();
    expect(find.text(l10n.unsavedChanges), findsOneWidget);

    await tester.tap(find.text(l10n.discard));
    await tester.pumpAndSettle();
    expect(
      widgetRef.read(workspaceControllerProvider).hasUnsavedChanges,
      isFalse,
    );
    expect(safeToContinueCount, 1);

    await tester.tap(find.text('Navigate'));
    await tester.pumpAndSettle();

    expect(find.text(l10n.unsavedChanges), findsNothing);
    expect(safeToContinueCount, 2);
  });

  testWidgets('destructive dialog buttons stay readable on dark controls', (
    tester,
  ) async {
    late Color activeControl;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildBusyMarkTheme(
          brightness: Brightness.dark,
          accentColor: Colors.green,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              activeControl = BusyMarkSurfaceColors.of(context).controlActive;
              return BusyMarkDialogButton(
                label: l10n.discard,
                icon: BusyMarkGlyphs.delete,
                destructive: true,
                onPressed: () {},
              );
            },
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text(l10n.discard));
    final foreground = text.style?.color;

    expect(foreground, isNotNull);
    expect(
      _contrastRatio(foreground!, activeControl),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      tester.widget<Icon>(find.byIcon(BusyMarkGlyphs.delete)).color,
      foreground,
    );
  });
}

double _contrastRatio(Color foreground, Color background) {
  final luminance = [
    foreground.computeLuminance(),
    background.computeLuminance(),
  ]..sort();
  return (luminance.last + 0.05) / (luminance.first + 0.05);
}

class _MemorySettingsStore implements LocalSettingsStore {
  Map<String, Object?> value = <String, Object?>{};

  @override
  Future<Map<String, Object?>> load() async => value;

  @override
  Future<void> save(Map<String, Object?> json) async {
    value = json;
  }
}
