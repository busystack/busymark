import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/workspace/workspace_controller.dart';
import 'package:busymark/src/workspace/workspace_safety.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

      expect(find.text('Unsaved changes'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(safeToContinue, isFalse);
    },
  );
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
