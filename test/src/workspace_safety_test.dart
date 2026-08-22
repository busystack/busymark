import 'dart:async';

import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/l10n/generated/app_localizations_en.dart';
import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/busymark_glyphs.dart';
import 'package:busymark/src/workspace/workspace_controller.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:busymark/src/workspace/workspace_safety.dart';
import 'package:busymark/src/workspace/workspace_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
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
    final service = _IdentityWorkspaceService();
    var safeToContinueCount = 0;
    late WidgetRef widgetRef;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localSettingsStoreProvider.overrideWithValue(_MemorySettingsStore()),
          workspaceServiceProvider.overrideWithValue(service),
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
    await controller.openPath(service.rootPath);
    controller.updateActiveText('# Dirty\n');

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
    final theme = buildBusyMarkTheme(
      brightness: Brightness.dark,
      accentColor: Colors.green,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: BusyMarkDialogButton(
            label: l10n.discard,
            icon: BusyMarkGlyphs.delete,
            destructive: true,
            onPressed: () {},
          ),
        ),
      ),
    );

    final button = tester.widget<ElevatedButton>(
      find.descendant(
        of: find.byType(BusyMarkDialogButton),
        matching: find.byType(ElevatedButton),
      ),
    );
    final foreground = button.style?.foregroundColor?.resolve({});
    final background = button.style?.backgroundColor?.resolve({});

    expect(foreground, BusyMarkDestructiveButtonStyle.foreground(theme));
    expect(background, BusyMarkDestructiveButtonStyle.background(theme));
    expect(_contrastRatio(foreground!, background!), greaterThanOrEqualTo(4.5));
    expect(button.style?.iconColor?.resolve({}), foreground);
  });

  testWidgets(
    'unsaved changes Discard action renders white in the dark dialog',
    (tester) async {
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
              brightness: Brightness.dark,
              accentColor: Colors.green,
            ),
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  widgetRef = ref;
                  return TextButton(
                    onPressed: () => confirmSafeToContinue(context, ref),
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

      final discardButton = find.widgetWithText(
        BusyMarkDialogButton,
        l10n.discard,
      );
      final elevated = tester.widget<ElevatedButton>(
        find.descendant(
          of: discardButton,
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(
        elevated.style?.foregroundColor?.resolve({}),
        BusyMarkLinuxPalette.white,
      );
      expect(
        elevated.style?.backgroundColor?.resolve({}),
        BusyMarkLinuxPalette.red,
      );
      expect(
        DefaultTextStyle.of(
          tester.element(find.text(l10n.discard)),
        ).style.color,
        BusyMarkLinuxPalette.white,
      );
    },
  );

  testWidgets(
    'overwrite confirmation stays pinned to the document being saved',
    (tester) async {
      final service = _IdentityWorkspaceService()..firstChangedOnDisk = true;

      bool? saved;
      late WidgetRef widgetRef;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localSettingsStoreProvider.overrideWithValue(
              _MemorySettingsStore()
                ..value = AppSettings.defaults()
                    .copyWith(autoSave: false)
                    .toJson(),
            ),
            workspaceServiceProvider.overrideWithValue(service),
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
                      saved = await saveActiveWithOverwriteConfirmation(
                        context,
                        ref,
                      );
                    },
                    child: const Text('Save document'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      final controller = widgetRef.read(workspaceControllerProvider.notifier);
      await controller.openPath(service.rootPath);
      await controller.openActiveFile(service.firstPath);
      controller.updateActiveText('# Edited A\n');

      await tester.tap(find.text('Save document'));
      await tester.pumpAndSettle();
      expect(find.text(l10n.fileChangedOnDisk), findsOneWidget);

      expect(await controller.openActiveFile(service.secondPath), isTrue);
      controller.updateActiveText('# Edited B\n');
      await tester.pump();
      await tester.tap(find.text(l10n.overwrite));
      await tester.pumpAndSettle();

      expect(saved, isFalse);
      expect(service.documents[service.firstPath], '# External A\n');
      expect(service.documents[service.secondPath], '# Original B\n');
      expect(service.saves, isEmpty);
      expect(
        widgetRef.read(workspaceControllerProvider).workspace?.activeFilePath,
        service.secondPath,
      );
      expect(
        widgetRef.read(workspaceControllerProvider).activeText,
        '# Edited B\n',
      );
      expect(widgetRef.read(workspaceControllerProvider).isDirty, isTrue);
    },
  );

  testWidgets('overlapping manual saves write the newer requested revision', (
    tester,
  ) async {
    final service = _IdentityWorkspaceService()..pauseFirstSave = true;
    final saveRequests = <Future<bool>>[];
    late WidgetRef widgetRef;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localSettingsStoreProvider.overrideWithValue(
            _MemorySettingsStore()
              ..value = AppSettings.defaults()
                  .copyWith(autoSave: false)
                  .toJson(),
          ),
          workspaceServiceProvider.overrideWithValue(service),
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
                  onPressed: () {
                    saveRequests.add(
                      saveActiveWithOverwriteConfirmation(context, ref),
                    );
                  },
                  child: const Text('Save document'),
                );
              },
            ),
          ),
        ),
      ),
    );

    final controller = widgetRef.read(workspaceControllerProvider.notifier);
    await controller.openPath(service.rootPath);
    controller.updateActiveText('# First revision\n');
    await tester.tap(find.text('Save document'));
    await service.firstSaveStarted.future;

    controller.updateActiveText('# Second revision\n');
    await tester.tap(find.text('Save document'));
    await tester.pump();
    service.releaseFirstSave();

    expect(await Future.wait(saveRequests), [isTrue, isTrue]);
    await tester.pumpAndSettle();
    expect(service.saves, [
      (path: service.firstPath, text: '# First revision\n'),
      (path: service.firstPath, text: '# Second revision\n'),
    ]);
    expect(service.documents[service.firstPath], '# Second revision\n');
    expect(widgetRef.read(workspaceControllerProvider).isDirty, isFalse);
  });

  testWidgets('save cancels when the active document changes during disk I/O', (
    tester,
  ) async {
    final service = _IdentityWorkspaceService()
      ..pendingFileChangedResult = Completer<bool>();
    bool? saved;
    late WidgetRef widgetRef;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localSettingsStoreProvider.overrideWithValue(
            _MemorySettingsStore()
              ..value = AppSettings.defaults()
                  .copyWith(autoSave: false)
                  .toJson(),
          ),
          workspaceServiceProvider.overrideWithValue(service),
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
                    saved = await saveActiveWithOverwriteConfirmation(
                      context,
                      ref,
                    );
                  },
                  child: const Text('Save document'),
                );
              },
            ),
          ),
        ),
      ),
    );

    final controller = widgetRef.read(workspaceControllerProvider.notifier);
    await controller.openPath(service.rootPath);
    controller.updateActiveText('# Edited A\n');

    await tester.tap(find.text('Save document'));
    await service.fileChangeCheckStarted.future;

    expect(await controller.openActiveFile(service.secondPath), isTrue);
    controller.updateActiveText('# Edited B\n');
    service.pendingFileChangedResult!.complete(false);
    await tester.pumpAndSettle();

    expect(saved, isFalse);
    expect(service.saves, isEmpty);
    expect(service.documents[service.firstPath], '# External A\n');
    expect(service.documents[service.secondPath], '# Original B\n');
    expect(
      widgetRef.read(workspaceControllerProvider).workspace?.activeFilePath,
      service.secondPath,
    );
    expect(
      widgetRef.read(workspaceControllerProvider).activeText,
      '# Edited B\n',
    );
    expect(widgetRef.read(workspaceControllerProvider).isDirty, isTrue);
  });

  testWidgets('Save As stays pinned while the file picker is open', (
    tester,
  ) async {
    final service = _IdentityWorkspaceService();

    const fileSelectorChannel = MethodChannel(
      'plugins.flutter.io/file_selector',
    );
    final pickerResult = Completer<String?>();
    final pickerStarted = Completer<void>();
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      fileSelectorChannel,
      (call) async {
        expect(call.method, 'getSavePath');
        pickerStarted.complete();
        return pickerResult.future;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        fileSelectorChannel,
        null,
      );
    });

    bool? saved;
    late WidgetRef widgetRef;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localSettingsStoreProvider.overrideWithValue(_MemorySettingsStore()),
          workspaceServiceProvider.overrideWithValue(service),
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
                    saved = await saveActiveWithOverwriteConfirmation(
                      context,
                      ref,
                    );
                  },
                  child: const Text('Save document'),
                );
              },
            ),
          ),
        ),
      ),
    );

    final controller = widgetRef.read(workspaceControllerProvider.notifier);
    await controller.createMarkdownFile();
    controller.updateActiveText('# Untitled draft\n');

    await tester.tap(find.text('Save document'));
    await tester.runAsync(() => pickerStarted.future);

    await controller.openPath(service.secondPath);
    controller.updateActiveText('# Edited active document\n');
    pickerResult.complete(service.saveAsPath);
    await tester.pumpAndSettle();

    expect(saved, isFalse);
    expect(service.documents, isNot(contains(service.saveAsPath)));
    expect(service.documents[service.secondPath], '# Original B\n');
    expect(service.saves, isEmpty);
    expect(
      widgetRef.read(workspaceControllerProvider).workspace?.activeFilePath,
      service.secondPath,
    );
    expect(
      widgetRef.read(workspaceControllerProvider).activeText,
      '# Edited active document\n',
    );
    expect(widgetRef.read(workspaceControllerProvider).isDirty, isTrue);
  });

  testWidgets(
    'Save As cancel does not overwrite an existing normalized markdown path',
    (tester) async {
      final service = _IdentityWorkspaceService();

      const fileSelectorChannel = MethodChannel(
        'plugins.flutter.io/file_selector',
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        fileSelectorChannel,
        (call) async {
          expect(call.method, 'getSavePath');
          return service.saveAsExtensionlessPath;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          fileSelectorChannel,
          null,
        );
      });

      bool? saved;
      late WidgetRef widgetRef;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localSettingsStoreProvider.overrideWithValue(
              _MemorySettingsStore(),
            ),
            workspaceServiceProvider.overrideWithValue(service),
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
                      saved = await saveActiveWithOverwriteConfirmation(
                        context,
                        ref,
                      );
                    },
                    child: const Text('Save document'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      final controller = widgetRef.read(workspaceControllerProvider.notifier);
      await controller.createMarkdownFile();
      controller.updateActiveText('# Untitled draft\n');

      await tester.tap(find.text('Save document'));
      await tester.pumpAndSettle();

      expect(find.text(l10n.overwrite), findsOneWidget);
      expect(
        find.text(l10n.errorPathAlreadyExists(service.saveAsNormalizedPath)),
        findsOneWidget,
      );
      await tester.tap(find.text(l10n.cancel));
      await tester.pumpAndSettle();

      expect(saved, isFalse);
      expect(
        service.documents[service.saveAsNormalizedPath],
        '# Existing notes\n',
      );
      expect(service.saves, isEmpty);
      final state = widgetRef.read(workspaceControllerProvider);
      expect(state.workspace?.kind, WorkspaceKind.untitledMarkdown);
      expect(state.activeText, '# Untitled draft\n');
      expect(state.isDirty, isTrue);
    },
  );

  testWidgets(
    'Save As overwrites an existing normalized markdown path only after confirmation',
    (tester) async {
      final service = _IdentityWorkspaceService();

      const fileSelectorChannel = MethodChannel(
        'plugins.flutter.io/file_selector',
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        fileSelectorChannel,
        (call) async {
          expect(call.method, 'getSavePath');
          return service.saveAsExtensionlessPath;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          fileSelectorChannel,
          null,
        );
      });

      bool? saved;
      late WidgetRef widgetRef;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localSettingsStoreProvider.overrideWithValue(
              _MemorySettingsStore(),
            ),
            workspaceServiceProvider.overrideWithValue(service),
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
                      saved = await saveActiveWithOverwriteConfirmation(
                        context,
                        ref,
                      );
                    },
                    child: const Text('Save document'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      final controller = widgetRef.read(workspaceControllerProvider.notifier);
      await controller.createMarkdownFile();
      controller.updateActiveText('# Untitled draft\n');

      await tester.tap(find.text('Save document'));
      await tester.pumpAndSettle();

      expect(find.text(l10n.overwrite), findsOneWidget);
      expect(
        service.documents[service.saveAsNormalizedPath],
        '# Existing notes\n',
      );
      await tester.tap(find.text(l10n.overwrite));
      await tester.pumpAndSettle();

      expect(saved, isTrue);
      expect(
        service.documents[service.saveAsNormalizedPath],
        '# Untitled draft\n',
      );
      expect(service.saves, [
        (path: service.saveAsNormalizedPath, text: '# Untitled draft\n'),
      ]);
      final state = widgetRef.read(workspaceControllerProvider);
      expect(state.workspace?.activeFilePath, service.saveAsNormalizedPath);
      expect(state.activeText, '# Untitled draft\n');
      expect(state.isDirty, isFalse);
    },
  );

  testWidgets('Save As cancels when the document changes during path lookup', (
    tester,
  ) async {
    final service = _IdentityWorkspaceService()
      ..pendingPathExistsResult = Completer<bool>();
    const fileSelectorChannel = MethodChannel(
      'plugins.flutter.io/file_selector',
    );
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      fileSelectorChannel,
      (call) async => service.saveAsExtensionlessPath,
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        fileSelectorChannel,
        null,
      );
    });

    bool? saved;
    late WidgetRef widgetRef;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localSettingsStoreProvider.overrideWithValue(_MemorySettingsStore()),
          workspaceServiceProvider.overrideWithValue(service),
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
                    saved = await saveActiveWithOverwriteConfirmation(
                      context,
                      ref,
                    );
                  },
                  child: const Text('Save document'),
                );
              },
            ),
          ),
        ),
      ),
    );

    final controller = widgetRef.read(workspaceControllerProvider.notifier);
    await controller.createMarkdownFile();
    controller.updateActiveText('# Untitled draft\n');

    await tester.tap(find.text('Save document'));
    await tester.runAsync(() => service.pathExistsCheckStarted.future);

    await controller.openPath(service.secondPath);
    controller.updateActiveText('# Edited active document\n');
    service.pendingPathExistsResult!.complete(true);
    await tester.pumpAndSettle();

    expect(saved, isFalse);
    expect(find.text(l10n.overwrite), findsNothing);
    expect(service.pathExistsChecks, [service.saveAsNormalizedPath]);
    expect(service.saves, isEmpty);
    expect(
      service.documents[service.saveAsNormalizedPath],
      '# Existing notes\n',
    );
    final state = widgetRef.read(workspaceControllerProvider);
    expect(state.workspace?.activeFilePath, service.secondPath);
    expect(state.activeText, '# Edited active document\n');
    expect(state.isDirty, isTrue);
  });

  testWidgets('discard confirmation cannot discard a newly active document', (
    tester,
  ) async {
    final service = _IdentityWorkspaceService();
    bool? safeToContinue;
    late WidgetRef widgetRef;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localSettingsStoreProvider.overrideWithValue(
            _MemorySettingsStore()
              ..value = AppSettings.defaults()
                  .copyWith(autoSave: false)
                  .toJson(),
          ),
          workspaceServiceProvider.overrideWithValue(service),
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
                    safeToContinue = await confirmSafeToContinue(context, ref);
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
    await controller.openPath(service.rootPath);
    controller.updateActiveText('# Edited A\n');

    await tester.tap(find.text('Navigate'));
    await tester.pumpAndSettle();
    expect(find.text(l10n.unsavedChanges), findsOneWidget);

    expect(await controller.openActiveFile(service.secondPath), isTrue);
    controller.updateActiveText('# Edited B\n');
    await tester.pump();
    await tester.tap(find.text(l10n.discard));
    await tester.pumpAndSettle();

    expect(safeToContinue, isFalse);
    expect(
      widgetRef.read(workspaceControllerProvider).workspace?.activeFilePath,
      service.secondPath,
    );
    expect(
      widgetRef.read(workspaceControllerProvider).activeText,
      '# Edited B\n',
    );
    expect(widgetRef.read(workspaceControllerProvider).isDirty, isTrue);
  });

  testWidgets('workspace continuation resolves inactive dirty documents too', (
    tester,
  ) async {
    final service = _IdentityWorkspaceService();
    bool? safeToContinue;
    late WidgetRef widgetRef;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localSettingsStoreProvider.overrideWithValue(
            _MemorySettingsStore()
              ..value = AppSettings.defaults()
                  .copyWith(autoSave: false)
                  .toJson(),
          ),
          workspaceServiceProvider.overrideWithValue(service),
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
                    safeToContinue = await confirmSafeToContinue(context, ref);
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
    await controller.openPath(service.rootPath);
    controller.updateActiveText('# Edited A\n');
    await controller.openActiveFile(service.secondPath);
    controller.updateActiveText('# Edited B\n');
    expect(
      widgetRef.read(workspaceControllerProvider).dirtyBuffers,
      hasLength(2),
    );

    await tester.tap(find.text('Navigate'));
    await tester.pumpAndSettle();
    expect(find.text('a.md'), findsOneWidget);
    expect(find.text('b.md'), findsOneWidget);
    await tester.tap(find.text(l10n.discard));
    await tester.pumpAndSettle();

    expect(safeToContinue, isTrue);
    expect(widgetRef.read(workspaceControllerProvider).dirtyBuffers, isEmpty);
    expect(service.documents[service.firstPath], '# External A\n');
    expect(service.documents[service.secondPath], '# Original B\n');
  });

  for (final action in [
    (label: 'save', discard: false),
    (label: 'discard', discard: true),
  ]) {
    testWidgets(
      'closing one dirty tab can ${action.label} it while another stays dirty',
      (tester) async {
        final service = _IdentityWorkspaceService();
        bool? safeToClose;
        late WidgetRef widgetRef;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              localSettingsStoreProvider.overrideWithValue(
                _MemorySettingsStore()
                  ..value = AppSettings.defaults()
                      .copyWith(autoSave: false)
                      .toJson(),
              ),
              workspaceServiceProvider.overrideWithValue(service),
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
                        safeToClose = await confirmSafeToCloseActiveDocument(
                          context,
                          ref,
                        );
                      },
                      child: const Text('Close active'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        final controller = widgetRef.read(workspaceControllerProvider.notifier);
        await controller.openPath(service.rootPath);
        controller.updateActiveText('# Edited A\n');
        await controller.openActiveFile(service.secondPath);
        controller.updateActiveText('# Edited B\n');
        expect(
          widgetRef.read(workspaceControllerProvider).dirtyBuffers,
          hasLength(2),
        );

        await tester.tap(find.text('Close active'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(action.discard ? l10n.discard : l10n.save));
        await tester.pumpAndSettle();

        expect(safeToClose, isTrue);
        final state = widgetRef.read(workspaceControllerProvider);
        expect(state.dirtyBuffers, hasLength(1));
        expect(state.dirtyBuffers.single.filePath, service.firstPath);
        expect(state.activeBuffer?.filePath, service.secondPath);
        expect(state.activeBuffer?.isDirty, isFalse);
      },
    );
  }
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

class _IdentityWorkspaceService extends WorkspaceService {
  final rootPath = '/virtual/workspace';
  final firstPath = '/virtual/workspace/a.md';
  final secondPath = '/virtual/workspace/b.md';
  final saveAsPath = '/virtual/workspace/saved.md';
  final saveAsExtensionlessPath = '/virtual/workspace/notes';
  final saveAsNormalizedPath = '/virtual/workspace/notes.md';
  final documents = <String, String>{
    '/virtual/workspace/a.md': '# External A\n',
    '/virtual/workspace/b.md': '# Original B\n',
    '/virtual/workspace/notes.md': '# Existing notes\n',
  };
  final saves = <({String path, String text})>[];
  final fileChangeCheckStarted = Completer<void>();
  final firstSaveStarted = Completer<void>();
  final pathExistsCheckStarted = Completer<void>();
  final pathExistsChecks = <String>[];
  var firstChangedOnDisk = false;
  var pauseFirstSave = false;
  Completer<bool>? pendingFileChangedResult;
  Completer<bool>? pendingPathExistsResult;
  final _releaseFirstSave = Completer<void>();

  @override
  Future<Workspace> openPath(String path) async {
    if (path == rootPath) {
      return Workspace(
        id: rootPath,
        rootPath: rootPath,
        kind: WorkspaceKind.markdownFolder,
        openedAt: DateTime(2026),
        activeFilePath: firstPath,
        activeFileSnapshot: _snapshot('# Original A\n'),
        openFilePaths: [firstPath, secondPath],
        files: [_file(firstPath), _file(secondPath)],
        diagnostics: const [],
      );
    }
    return Workspace(
      id: path,
      rootPath: path,
      kind: WorkspaceKind.singleMarkdown,
      openedAt: DateTime(2026),
      activeFilePath: path,
      activeFileSnapshot: _snapshot(documents[path] ?? ''),
      files: [_file(path)],
      diagnostics: const [],
    );
  }

  @override
  Future<WorkspaceFileLoad> loadTextWithSnapshot(String path) async {
    final text = documents[path] ?? '';
    return WorkspaceFileLoad(text: text, snapshot: _snapshot(text));
  }

  @override
  Future<bool> fileChangedSince(
    String path,
    WorkspaceFileSnapshot? knownSnapshot,
  ) async {
    if (path != firstPath) {
      return false;
    }
    if (!fileChangeCheckStarted.isCompleted) {
      fileChangeCheckStarted.complete();
    }
    final pendingResult = pendingFileChangedResult;
    if (pendingResult != null) {
      return pendingResult.future;
    }
    return firstChangedOnDisk;
  }

  @override
  Future<bool> pathExists(String path) async {
    pathExistsChecks.add(path);
    if (!pathExistsCheckStarted.isCompleted) {
      pathExistsCheckStarted.complete();
    }
    final pendingResult = pendingPathExistsResult;
    if (pendingResult != null) {
      return pendingResult.future;
    }
    return documents.containsKey(path);
  }

  @override
  Future<WorkspaceFileSnapshot> saveText(String path, String text) async {
    saves.add((path: path, text: text));
    if (pauseFirstSave && saves.length == 1) {
      firstSaveStarted.complete();
      await _releaseFirstSave.future;
    }
    documents[path] = text;
    return _snapshot(text);
  }

  void releaseFirstSave() {
    if (!_releaseFirstSave.isCompleted) {
      _releaseFirstSave.complete();
    }
  }

  @override
  Future<WorkspaceFileSnapshot> saveTextReplacingPath(
    String path,
    String text,
  ) {
    return saveText(path, text);
  }

  @override
  Future<Workspace> reparseActive(Workspace workspace, String source) async {
    return workspace;
  }

  DocumentFile _file(String path) {
    final text = documents[path] ?? '';
    return DocumentFile(
      absolutePath: path,
      relativePath: path.split('/').last,
      kind: DocumentKind.markdown,
      size: text.length,
      lastModified: DateTime(2026),
    );
  }

  WorkspaceFileSnapshot _snapshot(String text) {
    return WorkspaceFileSnapshot(
      modifiedAt: DateTime(2026),
      size: text.length,
      contentHash: text,
    );
  }
}
