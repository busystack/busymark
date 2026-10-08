import 'dart:async';

import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/l10n/generated/app_localizations_en.dart';
import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/busymark_glyphs.dart';
import 'package:busymark/src/workspace/document_buffer.dart';
import 'package:busymark/src/workspace/workspace_controller.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:busymark/src/workspace/workspace_safety.dart';
import 'package:busymark/src/workspace/workspace_tab_actions.dart';
import 'package:busymark/src/workspace/workspace_tabs.dart';
import 'package:busymark/src/git/application/git_controller.dart';
import 'package:busymark/src/local_history/local_history_controller.dart';
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

  testWidgets(
    'save completes for its buffer when the active document changes',
    (tester) async {
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

      expect(saved, isTrue);
      expect(service.saves, [(path: service.firstPath, text: '# Edited A\n')]);
      expect(service.documents[service.firstPath], '# Edited A\n');
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
      final firstBuffer = widgetRef
          .read(workspaceControllerProvider)
          .documentBuffers
          .singleWhere((buffer) => buffer.filePath == service.firstPath);
      expect(firstBuffer.isDirty, isFalse);
      expect(firstBuffer.lastSavedText, '# Edited A\n');
    },
  );

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
  Future<
    ({WidgetRef ref, WorkspaceController controller, bool? Function() result})
  >
  closeHarness(
    WidgetTester tester,
    _IdentityWorkspaceService service,
    Set<String> targets, {
    String operation = 'confirm',
    WorkspaceController Function()? createController,
  }) async {
    bool? result;
    late WidgetRef ref;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localSettingsStoreProvider.overrideWithValue(
            _MemorySettingsStore()
              ..value = AppSettings.defaults()
                  .copyWith(autoSave: false, validateOnEdit: false)
                  .toJson(),
          ),
          workspaceServiceProvider.overrideWithValue(service),
          if (createController != null)
            workspaceControllerProvider.overrideWith(createController),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Consumer(
              builder: (context, widgetRef, _) {
                ref = widgetRef;
                return TextButton(
                  onPressed: () async {
                    final state = ref.read(workspaceControllerProvider);
                    final workspace = state.workspace!;
                    final tab = WorkspaceTabEntry.file(
                      path: '',
                      active: false,
                      bufferId: targets.firstOrNull ?? state.activeBufferId!,
                    );
                    result = switch (operation) {
                      'one' => await closeWorkspaceTab(
                        context,
                        ref,
                        workspace: workspace,
                        tab: tab,
                      ),
                      'other' => await closeOtherWorkspaceTabs(
                        context,
                        ref,
                        workspace: workspace,
                        retainedTab: tab,
                      ),
                      'all' => await closeAllWorkspaceTabs(
                        context,
                        ref,
                        workspace: workspace,
                      ),
                      _ => await confirmSafeToCloseDocumentBuffers(
                        context,
                        ref,
                        targets,
                      ),
                    };
                  },
                  child: const Text('Close targets'),
                );
              },
            ),
          ),
        ),
      ),
    );
    final controller = ref.read(workspaceControllerProvider.notifier);
    await controller.openPath(service.rootPath);
    final firstId = ref.read(workspaceControllerProvider).activeBufferId!;
    await controller.openActiveFile(service.secondPath);
    await controller.activateDocumentBuffer(firstId);
    return (ref: ref, controller: controller, result: () => result);
  }

  for (final choice in ['Cancel', 'Save', 'Discard']) {
    testWidgets(
      'ID scoped confirmation combines dirty targets and excludes retained draft on $choice',
      (tester) async {
        final service = _IdentityWorkspaceService();
        final targets = <String>{};
        final h = await closeHarness(tester, service, targets);
        h.controller.updateActiveText('# Edited first\n');
        targets.add(h.ref.read(workspaceControllerProvider).activeBufferId!);
        await h.controller.openActiveFile(service.secondPath);
        h.controller.updateActiveText('# Edited second\n');
        targets.add(h.ref.read(workspaceControllerProvider).activeBufferId!);
        await h.controller.createMarkdownFile();
        h.controller.updateActiveText('# Retained dirty\n');
        final retained = h.ref.read(workspaceControllerProvider).activeBuffer!;
        await tester.tap(find.text('Close targets'));
        await tester.pumpAndSettle();
        expect(
          find.text(l10n.unsavedChangesMultipleMessage(2)),
          findsOneWidget,
        );
        expect(find.text(retained.displayName), findsNothing);
        await tester.tap(find.text(choice));
        await tester.pumpAndSettle();
        expect(h.result(), choice != 'Cancel');
        final state = h.ref.read(workspaceControllerProvider);
        expect(state.activeBufferId, retained.id);
        expect(state.activeBuffer!.text, retained.text);
        expect(state.activeBuffer!.isDirty, isTrue);
        expect(state.dirtyBuffers, hasLength(choice == 'Cancel' ? 3 : 1));
        expect(service.saves, hasLength(choice == 'Save' ? 2 : 0));
      },
    );
  }

  for (final change in ['revision', 'active', 'workspace', 'removed']) {
    testWidgets(
      'ID scoped confirmation rejects $change changes while dialog is open',
      (tester) async {
        final service = _IdentityWorkspaceService();
        final targets = <String>{};
        final h = await closeHarness(tester, service, targets);
        h.controller.updateActiveText('# Dirty original\n');
        targets.add(h.ref.read(workspaceControllerProvider).activeBufferId!);
        await tester.tap(find.text('Close targets'));
        await tester.pumpAndSettle();
        if (change == 'revision') {
          h.controller.updateActiveText('# New revision\n');
        }
        if (change == 'active') {
          await h.controller.openActiveFile(service.secondPath);
        }
        if (change == 'workspace') {
          await h.controller.openPath(service.saveAsPath);
        }
        if (change == 'removed') {
          await h.controller.closeDocumentBuffer(targets.first, discard: true);
        }
        final before = h.ref.read(workspaceControllerProvider);
        await tester.tap(find.text(l10n.discard));
        await tester.pumpAndSettle();
        expect(h.result(), isFalse);
        final after = h.ref.read(workspaceControllerProvider);
        expect(
          after.documentBuffers.map((b) => b.id),
          before.documentBuffers.map((b) => b.id),
        );
        expect(after.activeBufferId, before.activeBufferId);
        expect(after.activeText, before.activeText);
        expect(service.saves, isEmpty);
      },
    );
  }

  testWidgets(
    'failed scoped save stops subsequent targets and ordinary closing',
    (tester) async {
      final service = _IdentityWorkspaceService()..failSave = true;
      final targets = <String>{};
      final h = await closeHarness(tester, service, targets, operation: 'all');
      h.controller.updateActiveText('# First edited\n');
      await h.controller.openActiveFile(service.secondPath);
      h.controller.updateActiveText('# Second edited\n');
      final before = h.ref.read(workspaceControllerProvider);
      await tester.tap(find.text('Close targets'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.save));
      await tester.pumpAndSettle();
      expect(h.result(), isFalse);
      expect(service.saves, hasLength(1));
      final after = h.ref.read(workspaceControllerProvider);
      expect(
        after.documentBuffers.map((b) => b.id),
        before.documentBuffers.map((b) => b.id),
      );
      expect(after.dirtyBuffers, hasLength(2));
      expect(after.activeBufferId, before.activeBufferId);
    },
  );

  for (final saveAs in ['cancel', 'save']) {
    testWidgets('scoped tab close supports untitled first Save As $saveAs', (
      tester,
    ) async {
      final service = _IdentityWorkspaceService();
      const channel = MethodChannel('plugins.flutter.io/file_selector');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        expect(call.method, 'getSavePath');
        return saveAs == 'save' ? service.saveAsPath : null;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      final targets = <String>{};
      final h = await closeHarness(tester, service, targets, operation: 'one');
      await h.controller.createMarkdownWorkspace();
      h.controller.updateActiveText('# Untitled close draft\n');
      targets.add(h.ref.read(workspaceControllerProvider).activeBufferId!);
      await tester.tap(find.text('Close targets'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.save));
      await tester.pumpAndSettle();
      expect(h.result(), saveAs == 'save');
      final state = h.ref.read(workspaceControllerProvider);
      if (saveAs == 'save') {
        expect(state.documentBuffers, isEmpty);
        expect(state.workspace!.kind, WorkspaceKind.singleMarkdown);
        expect(
          service.documents[service.saveAsPath],
          '# Untitled close draft\n',
        );
      } else {
        expect(state.activeBufferId, targets.first);
        expect(state.activeText, '# Untitled close draft\n');
        expect(state.isDirty, isTrue);
      }
    });
  }

  testWidgets(
    'close all aborts when another document opens during confirmation',
    (tester) async {
      final service = _IdentityWorkspaceService();
      final h = await closeHarness(
        tester,
        service,
        <String>{},
        operation: 'all',
      );
      h.controller.updateActiveText('# Edited first\n');
      await tester.tap(find.text('Close targets'));
      await tester.pumpAndSettle();
      final activeId = h.ref.read(workspaceControllerProvider).activeBufferId!;
      await h.controller.createMarkdownFile();
      final newId = h.ref.read(workspaceControllerProvider).activeBufferId!;
      await h.controller.activateDocumentBuffer(activeId);
      await tester.tap(find.text(l10n.discard));
      await tester.pumpAndSettle();
      expect(h.result(), isFalse);
      expect(
        h.ref
            .read(workspaceControllerProvider)
            .documentBuffers
            .any((b) => b.id == newId),
        isTrue,
      );
      expect(
        h.ref.read(workspaceControllerProvider).documentBuffers,
        hasLength(3),
      );
    },
  );

  for (final operation in ['one', 'other', 'all']) {
    testWidgets(
      'rejected $operation close stops and preserves comparison state',
      (tester) async {
        final targets = <String>{};
        final controller = _RejectedCloseController();
        final h = await closeHarness(
          tester,
          _IdentityWorkspaceService(),
          targets,
          operation: operation,
          createController: () => controller,
        );
        if (operation == 'other') {
          await h.controller.createMarkdownFile();
        }
        final before = h.ref.read(workspaceControllerProvider);
        targets.add(before.documentBuffers.last.id);
        final git = h.ref.read(gitControllerProvider.notifier);
        git.state = git.state.copyWith(openDiffFilePaths: ['comparison.md']);
        final history = h.ref.read(localHistoryControllerProvider.notifier);
        history.state = history.state.copyWith(
          selectedRevisionId: 'revision-to-keep',
        );
        await tester.tap(find.text('Close targets'));
        await tester.pumpAndSettle();
        expect(h.result(), isFalse);
        expect(controller.closedIds, hasLength(operation == 'all' ? 0 : 1));
        expect(controller.bulkCalls, operation == 'all' ? 1 : 0);
        expect(
          h.ref
              .read(workspaceControllerProvider)
              .documentBuffers
              .map((b) => b.id),
          before.documentBuffers.map((b) => b.id),
        );
        expect(h.ref.read(gitControllerProvider).openDiffFilePaths, [
          'comparison.md',
        ]);
        expect(
          h.ref.read(localHistoryControllerProvider).selectedRevisionId,
          'revision-to-keep',
        );
      },
    );
  }

  testWidgets('canceled Save As after an earlier save stops close other tabs', (
    tester,
  ) async {
    final service = _IdentityWorkspaceService();
    final targets = <String>{};
    final h = await closeHarness(tester, service, targets, operation: 'other');
    h.controller.updateActiveText('# Retained dirty text\n');
    final retained = h.ref.read(workspaceControllerProvider).activeBuffer!;
    targets.add(retained.id);
    await h.controller.openActiveFile(service.secondPath);
    h.controller.updateActiveText('# Target to save\n');
    await h.controller.createMarkdownFile();
    h.controller.updateActiveText('# Untitled target\n');
    const channel = MethodChannel('plugins.flutter.io/file_selector');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (_) async => null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    await tester.tap(find.text('Close targets'));
    await tester.pumpAndSettle();
    expect(find.text(l10n.unsavedChangesMultipleMessage(2)), findsOneWidget);
    await tester.tap(find.text(l10n.save));
    await tester.pumpAndSettle();
    expect(h.result(), isFalse);
    final state = h.ref.read(workspaceControllerProvider);
    expect(state.documentBuffers, hasLength(3));
    expect(
      state.documentBuffers.singleWhere((b) => b.id == retained.id).text,
      retained.text,
    );
    expect(
      state.documentBuffers.singleWhere((b) => b.id == retained.id).isDirty,
      isTrue,
    );
    expect(state.bufferForPath(service.secondPath)!.isDirty, isFalse);
    expect(service.saves.single, (
      path: service.secondPath,
      text: '# Target to save\n',
    ));
  });

  for (final standalone in [false, true]) {
    testWidgets(
      'close all finishes when discard already removes ${standalone ? 'standalone' : 'folder'} untitled targets',
      (tester) async {
        final h = await closeHarness(
          tester,
          _IdentityWorkspaceService(),
          <String>{},
          operation: 'all',
        );
        if (standalone) {
          await h.controller.createMarkdownWorkspace();
        } else {
          final savedIds = h.ref
              .read(workspaceControllerProvider)
              .documentBuffers
              .map((b) => b.id)
              .toList();
          await h.controller.createMarkdownFile();
          for (final id in savedIds) {
            await h.controller.closeDocumentBuffer(id);
          }
        }
        h.controller.updateActiveText('# Draft to discard\n');
        await h.controller.createMarkdownFile();
        await tester.tap(find.text('Close targets'));
        await tester.pumpAndSettle();
        expect(
          find.text(l10n.unsavedChangesMultipleMessage(2)),
          findsOneWidget,
        );
        await tester.tap(find.text(l10n.discard));
        await tester.pumpAndSettle();
        expect(h.result(), isTrue);
        final state = h.ref.read(workspaceControllerProvider);
        expect(state.documentBuffers, isEmpty);
        if (standalone) {
          expect(state.workspace, isNull);
        } else {
          expect(state.workspace!.kind, WorkspaceKind.markdownFolder);
        }
      },
    );
  }

  testWidgets(
    'close other tabs keeps documents opened during confirmation outside the captured set',
    (tester) async {
      final service = _IdentityWorkspaceService();
      final targets = <String>{};
      final h = await closeHarness(
        tester,
        service,
        targets,
        operation: 'other',
      );
      targets.add(h.ref.read(workspaceControllerProvider).activeBufferId!);
      await h.controller.openActiveFile(service.secondPath);
      h.controller.updateActiveText('# Target dirty\n');
      await tester.tap(find.text('Close targets'));
      await tester.pumpAndSettle();
      final originalActiveId = h.ref
          .read(workspaceControllerProvider)
          .activeBufferId!;
      await h.controller.createMarkdownFile();
      final newBuffer = h.ref.read(workspaceControllerProvider).activeBuffer!;
      await h.controller.activateDocumentBuffer(originalActiveId);
      await tester.tap(find.text(l10n.discard));
      await tester.pumpAndSettle();
      expect(h.result(), isTrue);
      final state = h.ref.read(workspaceControllerProvider);
      expect(state.documentBuffers.map((b) => b.id), [
        targets.first,
        newBuffer.id,
      ]);
      expect(state.activeBufferId, targets.first);
      expect(state.documentBuffers.last.isDirty, isTrue);
    },
  );

  testWidgets(
    'close other tabs preserves a comparison opened during confirmation',
    (tester) async {
      final service = _IdentityWorkspaceService();
      final targets = <String>{};
      final h = await closeHarness(
        tester,
        service,
        targets,
        operation: 'other',
      );
      targets.add(h.ref.read(workspaceControllerProvider).activeBufferId!);
      await h.controller.openActiveFile(service.secondPath);
      h.controller.updateActiveText('# Target dirty\n');
      await tester.tap(find.text('Close targets'));
      await tester.pumpAndSettle();
      final history = h.ref.read(localHistoryControllerProvider.notifier);
      await history.flushAll(
        h.ref.read(workspaceControllerProvider).documentBuffers,
      );
      await history.selectDocumentForBuffer(
        h.ref.read(workspaceControllerProvider).activeBuffer!,
      );
      final revision = h.ref
          .read(localHistoryControllerProvider)
          .selectedRevisions
          .first
          .id;
      await history.selectRevision(revision);
      await tester.tap(find.text(l10n.discard));
      await tester.pumpAndSettle();
      expect(h.result(), isFalse);
      expect(
        h.ref.read(workspaceControllerProvider).documentBuffers,
        hasLength(2),
      );
      expect(
        h.ref.read(localHistoryControllerProvider).selectedRevisionId,
        revision,
      );
    },
  );

  testWidgets(
    'shared closing rejects overlapping operations before a second prompt',
    (tester) async {
      final targets = <String>{};
      final h = await closeHarness(
        tester,
        _IdentityWorkspaceService(),
        targets,
        operation: 'all',
      );
      h.controller.updateActiveText('# Dirty\n');
      await tester.tap(find.text('Close targets'));
      await tester.pumpAndSettle();
      final state = h.ref.read(workspaceControllerProvider);
      final second = await closeAllWorkspaceTabs(
        h.ref.context,
        h.ref,
        workspace: state.workspace!,
      );
      expect(second, isFalse);
      expect(find.text(l10n.unsavedChanges), findsOneWidget);
      await tester.tap(find.text(l10n.cancel));
      await tester.pumpAndSettle();
      expect(h.result(), isFalse);
      expect(
        h.ref.read(workspaceControllerProvider).documentBuffers,
        hasLength(2),
      );
    },
  );
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
  var failSave = false;
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
    if (failSave) throw StateError('save rejected');
    if (pauseFirstSave && saves.length == 1) {
      firstSaveStarted.complete();
      await _releaseFirstSave.future;
    }
    documents[path] = text;
    return _snapshot(text);
  }

  @override
  Future<WorkspaceFileSnapshot> saveTextIfUnchanged(
    String path,
    String text, {
    required WorkspaceFileSnapshot expectedSnapshot,
  }) => saveText(path, text);

  void releaseFirstSave() {
    if (!_releaseFirstSave.isCompleted) {
      _releaseFirstSave.complete();
    }
  }

  @override
  Future<WorkspaceFileSnapshot> saveNewText(
    String path,
    String text, {
    Future<void> Function()? onPublished,
  }) async {
    final result = await saveText(path, text);
    await onPublished?.call();
    return result;
  }

  @override
  Future<WorkspaceFileSnapshot> saveTextReplacingPath(
    String path,
    String text, {
    Future<void> Function()? onPublished,
  }) async {
    final result = await saveText(path, text);
    await onPublished?.call();
    return result;
  }

  @override
  Future<WorkspaceFileSnapshot> saveTextReplacingPathIfUnchanged(
    String path,
    String text, {
    required WorkspaceFileSnapshot expectedSnapshot,
    Future<void> Function()? onPublished,
  }) => saveTextReplacingPath(path, text, onPublished: onPublished);

  @override
  Future<Workspace> reparseDocument(
    Workspace workspace,
    DocumentBuffer buffer,
  ) async {
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

class _RejectedCloseController extends WorkspaceController {
  final closedIds = <String>[];
  int bulkCalls = 0;
  @override
  Future<bool> closeDocumentBuffer(
    String bufferId, {
    bool discard = false,
  }) async {
    closedIds.add(bufferId);
    return false;
  }

  @override
  Future<bool> closeAllOpenFileTabs() async {
    bulkCalls++;
    return false;
  }
}
