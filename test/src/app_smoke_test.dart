import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/l10n/generated/app_localizations_de.dart';
import 'package:busymark/l10n/generated/app_localizations_en.dart';
import 'package:busymark/l10n/generated/app_localizations_fr.dart';
import 'package:busymark/src/app/app_metadata.dart';
import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/app/busymark_app.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/startup_path.dart';
import 'package:busymark/src/app/window_control_service.dart';
import 'package:busymark/src/editor/markdown_image_view.dart';
import 'package:busymark/src/platform/linux_header_bar_service.dart';
import 'package:busymark/src/workspace/workspace_controller.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:busymark/src/workspace/workspace_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

void main() {
  late _FallbackHeaderBarService headerBarService;
  final l10n = AppLocalizationsEn();

  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.defaultRouteNameTestValue = '/';
    headerBarService = _FallbackHeaderBarService();
  });

  testWidgets('app wires generated localization delegates and locales', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        ],
        child: const BusyMarkApp(),
      ),
    );
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.localizationsDelegates, contains(AppLocalizations.delegate));
    expect(app.supportedLocales, AppLocalizations.supportedLocales);
    expect(app.supportedLocales, contains(const Locale('de')));
    expect(app.supportedLocales, contains(const Locale('it')));
    expect(app.supportedLocales, contains(const Locale('no')));
    expect(app.supportedLocales, contains(const Locale('fr')));
    expect(app.supportedLocales, contains(const Locale('ru')));
    expect(app.supportedLocales, contains(const Locale('uk')));
    expect(app.supportedLocales, contains(const Locale('pl')));
    expect(app.supportedLocales, contains(const Locale('es')));
    expect(app.supportedLocales, contains(const Locale('pt')));
    expect(app.supportedLocales, contains(const Locale('ar')));
    expect(app.supportedLocales, contains(const Locale('fa')));
    expect(app.supportedLocales, contains(const Locale('hi')));
    expect(app.onGenerateTitle, isNotNull);
    expect(find.text(l10n.appTitle), findsWidgets);
  });

  testWidgets('app boots to BusyMark welcome screen without login UI', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        ],
        child: const BusyMarkApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.appTitle), findsWidgets);
    expect(find.text(l10n.createMarkdownFile), findsOneWidget);
    expect(find.text(l10n.createWritersideProject), findsOneWidget);
    expect(find.text(l10n.openMarkdownFile), findsOneWidget);
    expect(find.text('File or folder path'), findsNothing);
    expect(find.textContaining('sign in'), findsNothing);
  });

  testWidgets('settings screen opens', (tester) async {
    final l10n = AppLocalizationsEn();
    final settingsStore = _MemorySettingsStore();
    final nativeWindow = _FakeNativeWindowController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
          localSettingsStoreProvider.overrideWithValue(settingsStore),
          nativeWindowControllerProvider.overrideWithValue(nativeWindow),
        ],
        child: const BusyMarkApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(l10n.mainMenu));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.settings));
    await tester.pumpAndSettle();

    expect(find.text(l10n.settingsTitle), findsOneWidget);
    expect(find.text(l10n.appLanguage), findsOneWidget);
    expect(find.text(l10n.systemLanguage), findsWidgets);
    expect(find.text(l10n.autoSave), findsOneWidget);
    expect(find.text(l10n.autoSaveDescription), findsOneWidget);
    expect(find.text(l10n.validateOnEdit), findsOneWidget);
    expect(find.byType(DropdownButton<String>), findsNothing);
    expect(find.text(l10n.settingsWindowSectionTitle), findsOneWidget);
    expect(
      find.text(l10n.settingsConfirmCloseWithUnsavedChangesTitle),
      findsOneWidget,
    );
    expect(
      find.text(l10n.settingsConfirmCloseWithUnsavedChangesDescription),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip(l10n.appLanguage));
    await tester.pumpAndSettle();

    expect(find.text('Deutsch'), findsOneWidget);
    expect(find.text('العربية'), findsOneWidget);
    expect(find.text('हिन्दी'), findsOneWidget);
    await tester.tap(find.text(l10n.systemLanguage).last);
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.autoSave));
    await tester.pumpAndSettle();

    expect(settingsStore.value['autoSave'], isFalse);

    await tester.ensureVisible(
      find.text(l10n.settingsConfirmCloseWithUnsavedChangesTitle),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.text(l10n.settingsConfirmCloseWithUnsavedChangesTitle),
    );
    await tester.pumpAndSettle();

    expect(settingsStore.value['confirmCloseWithUnsavedChanges'], isFalse);
  });

  testWidgets('stored language override localizes app text', (tester) async {
    final de = AppLocalizationsDe();
    final settingsStore = _MemorySettingsStore()
      ..value = AppSettings.defaults().copyWith(localeTag: 'de').toJson();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
          localSettingsStoreProvider.overrideWithValue(settingsStore),
        ],
        child: const BusyMarkApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(de.mainMenu));
    await tester.pumpAndSettle();
    await tester.tap(find.text(de.settings));
    await tester.pumpAndSettle();

    expect(find.text(de.settingsTitle), findsOneWidget);
    expect(find.text(de.appLanguage), findsOneWidget);
    expect(find.text(de.validateOnEdit), findsOneWidget);
  });

  testWidgets('Writerside project dialog syncs generated fields until edited', (
    tester,
  ) async {
    final temp = Directory.systemTemp.createTempSync('busymark-create-dialog-');
    const fileSelectorChannel = MethodChannel(
      'plugins.flutter.io/file_selector',
    );
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      fileSelectorChannel,
      (call) async {
        expect(call.method, 'getDirectoryPath');
        return temp.path;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        fileSelectorChannel,
        null,
      );
      if (temp.existsSync()) {
        temp.deleteSync(recursive: true);
      }
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        ],
        child: const BusyMarkApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.createWritersideProject));
    await tester.pumpAndSettle();

    expect(find.text(l10n.createWritersideProject), findsWidgets);

    final entries = find.byWidgetPredicate(
      (widget) => widget is EditableText && !widget.readOnly,
    );
    expect(entries, findsNWidgets(5));
    final projectNameEntry = entries.at(0);
    final directoryNameEntry = entries.at(1);
    final instanceNameEntry = entries.at(2);
    final instanceIdEntry = entries.at(3);

    await tester.enterText(projectNameEntry, 'API Reference');
    await tester.pump();

    expect(
      tester.widget<EditableText>(directoryNameEntry).controller.text,
      'api-reference',
    );

    await tester.enterText(projectNameEntry, 'Developer Portal');
    await tester.pump();

    expect(
      tester.widget<EditableText>(directoryNameEntry).controller.text,
      'developer-portal',
    );

    await tester.enterText(projectNameEntry, 'Документация API');
    await tester.pump();

    expect(
      tester.widget<EditableText>(directoryNameEntry).controller.text,
      'документация-api',
    );

    await tester.enterText(projectNameEntry, 'دليل المستخدم');
    await tester.pump();

    expect(
      tester.widget<EditableText>(directoryNameEntry).controller.text,
      'دليل-المستخدم',
    );

    await tester.enterText(projectNameEntry, 'Café Études');
    await tester.pump();

    expect(
      tester.widget<EditableText>(directoryNameEntry).controller.text,
      'café-études',
    );

    await tester.enterText(directoryNameEntry, 'custom-directory');
    await tester.pump();
    await tester.enterText(projectNameEntry, 'Operator Portal');
    await tester.pump();

    expect(
      tester.widget<EditableText>(directoryNameEntry).controller.text,
      'custom-directory',
    );

    await tester.enterText(instanceNameEntry, 'Admin Handbook');
    await tester.pump();

    expect(
      tester.widget<EditableText>(instanceIdEntry).controller.text,
      'admin-handbook',
    );

    await tester.enterText(instanceNameEntry, 'Reviewer Handbook');
    await tester.pump();

    expect(
      tester.widget<EditableText>(instanceIdEntry).controller.text,
      'reviewer-handbook',
    );

    await tester.enterText(instanceNameEntry, 'Руководство администратора');
    await tester.pump();

    expect(
      tester.widget<EditableText>(instanceIdEntry).controller.text,
      'руководство-администратора',
    );

    await tester.enterText(instanceNameEntry, 'دليل الإدارة');
    await tester.pump();

    expect(
      tester.widget<EditableText>(instanceIdEntry).controller.text,
      'دليل-الإدارة',
    );

    await tester.enterText(instanceNameEntry, 'Café Études');
    await tester.pump();

    expect(
      tester.widget<EditableText>(instanceIdEntry).controller.text,
      'café-études',
    );

    await tester.enterText(instanceIdEntry, 'custom-instance');
    await tester.pump();
    await tester.enterText(instanceNameEntry, 'Operator Guide');
    await tester.pump();

    expect(
      tester.widget<EditableText>(instanceIdEntry).controller.text,
      'custom-instance',
    );
  });

  testWidgets('keyboard shortcuts dialog opens from the header', (
    tester,
  ) async {
    final l10n = AppLocalizationsEn();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        ],
        child: const BusyMarkApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(l10n.mainMenu));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.keyboardShortcuts));
    await tester.pumpAndSettle();

    expect(find.text(l10n.keyboardShortcuts), findsWidgets);
    expect(find.text(l10n.shortcutNewDocumentDescription), findsOneWidget);
    expect(find.text(l10n.shortcutOpenDescription), findsOneWidget);
    expect(find.text(l10n.shortcutSaveDescription), findsOneWidget);
    expect(find.text(l10n.shortcutFindDescription), findsOneWidget);
    expect(
      find.text(l10n.shortcutKeyboardShortcutsDescription),
      findsOneWidget,
    );
    expect(find.text(l10n.shortcutNextTabDescription), findsOneWidget);
    expect(find.text(l10n.shortcutPreviousTabDescription), findsOneWidget);
    expect(find.text(l10n.shortcutCloseTabDescription), findsOneWidget);
    expect(find.text(l10n.shortcutCloseAllTabsDescription), findsOneWidget);
    expect(find.text('Show shortcuts over toolbar buttons'), findsNothing);
    expect(find.text(l10n.shortcutUndoDescription), findsOneWidget);
    expect(find.text(l10n.shortcutRedoDescription), findsOneWidget);
    expect(find.text(l10n.shortcutBoldDescription), findsOneWidget);
    expect(find.text(l10n.shortcutUnderlineDescription), findsOneWidget);
    expect(find.text(l10n.shortcutStrikethroughDescription), findsOneWidget);
    expect(find.text(l10n.shortcutParagraphDescription), findsOneWidget);
    expect(find.text(l10n.shortcutHeading1Description), findsOneWidget);
    expect(find.text(l10n.shortcutHeading6Description), findsOneWidget);
    expect(find.text(l10n.shortcutNumberedListDescription), findsOneWidget);
    expect(find.text(l10n.shortcutBulletedListDescription), findsOneWidget);
    expect(find.text(l10n.shortcutChecklistDescription), findsOneWidget);
    expect(find.text('Ctrl+N'), findsOneWidget);
    expect(find.text('Ctrl+O'), findsOneWidget);
    expect(find.text('Ctrl+S'), findsOneWidget);
    expect(find.text('Ctrl+F'), findsOneWidget);
    expect(find.text('Ctrl+/'), findsOneWidget);
    expect(find.text('Ctrl+Tab'), findsOneWidget);
    expect(find.text('Ctrl+Shift+Tab'), findsOneWidget);
    expect(find.text('Ctrl+W'), findsOneWidget);
    expect(find.text('Ctrl+Shift+W'), findsOneWidget);
    expect(find.text('Ctrl+A'), findsOneWidget);
    expect(find.text('Ctrl+X'), findsAtLeastNWidgets(1));
    expect(find.text('Ctrl+C'), findsOneWidget);
    expect(find.text('Ctrl+V'), findsOneWidget);
    expect(find.text('Ctrl+Shift+V'), findsOneWidget);
    expect(find.text('Ctrl+Z'), findsOneWidget);
    expect(find.text('Ctrl+Shift+Z'), findsOneWidget);
    expect(find.text('Ctrl+B'), findsOneWidget);
    expect(find.text('Ctrl+I'), findsOneWidget);
    expect(find.text('Ctrl+U'), findsOneWidget);
    expect(find.text('Ctrl+K'), findsOneWidget);
    expect(find.text('Ctrl+E'), findsOneWidget);
    expect(find.text('Alt+Shift+5'), findsOneWidget);
    expect(find.text('Ctrl+Shift+0'), findsOneWidget);
    expect(find.text('Ctrl+Shift+1'), findsOneWidget);
    expect(find.text('Ctrl+Shift+2'), findsOneWidget);
    expect(find.text('Ctrl+Shift+3'), findsOneWidget);
    expect(find.text('Ctrl+Shift+4'), findsOneWidget);
    expect(find.text('Ctrl+Shift+5'), findsOneWidget);
    expect(find.text('Ctrl+Shift+6'), findsOneWidget);
    expect(find.text('Ctrl+Shift+7'), findsOneWidget);
    expect(find.text('Ctrl+Shift+8'), findsOneWidget);
    expect(find.text('Ctrl+Shift+9'), findsOneWidget);
    expect(find.text('Alt'), findsNothing);
    expect(find.text('Esc'), findsOneWidget);
    expect(find.text('Close'), findsNothing);
  });

  testWidgets('keyboard shortcuts tabs section title is localized', (
    tester,
  ) async {
    final fr = AppLocalizationsFr();
    final settingsStore = _MemorySettingsStore()
      ..value = AppSettings.defaults().copyWith(localeTag: 'fr').toJson();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
          localSettingsStoreProvider.overrideWithValue(settingsStore),
        ],
        child: const BusyMarkApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(fr.mainMenu));
    await tester.pumpAndSettle();
    await tester.tap(find.text(fr.keyboardShortcuts));
    await tester.pumpAndSettle();

    expect(find.text(fr.tabs), findsOneWidget);
    expect(find.text('Tabs'), findsNothing);
  });

  testWidgets('about dialog shows the BusyMark logo', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        ],
        child: const BusyMarkApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(l10n.mainMenu));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.aboutBusyMark));
    await tester.pumpAndSettle();

    expect(find.text(l10n.appTitle), findsWidgets);
    expect(find.text(l10n.aboutTagline), findsOneWidget);
    expect(find.text(busyMarkAppVersion), findsOneWidget);
    expect(find.textContaining('Version'), findsNothing);
    expect(
      find.ancestor(
        of: find.text(busyMarkAppVersion),
        matching: find.byType(DecoratedBox),
      ),
      findsWidgets,
    );
    expect(find.text(l10n.aboutLicenseLabel), findsOneWidget);
    expect(find.text(l10n.aboutLicenseName), findsOneWidget);
    expect(find.text(l10n.aboutWebsite), findsOneWidget);
    expect(find.text('https://busystack.org'), findsOneWidget);
    expect(find.text(l10n.aboutReportIssue), findsOneWidget);
    expect(
      find.text('https://github.com/busystack/busymark/issues'),
      findsOneWidget,
    );
    final logo = find.byType(SvgPicture);
    expect(logo, findsOneWidget);
    final logoSize = tester.getSize(logo);
    expect(logoSize.width, lessThanOrEqualTo(BusyMarkSizes.aboutLogoViewport));
    expect(logoSize.height, lessThanOrEqualTo(BusyMarkSizes.aboutLogoViewport));
  });

  testWidgets('Ctrl+N creates a new Markdown document', (tester) async {
    final service = _StartupWorkspaceService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
          workspaceServiceProvider.overrideWithValue(service),
        ],
        child: const BusyMarkApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(service.untitledCount, 1);
    expect(find.text(l10n.createMarkdownFile), findsNothing);
    expect(find.text(l10n.workspaceKindUnsavedMarkdown), findsWidgets);
  });

  testWidgets('Ctrl+N with unsaved changes opens confirmation dialog', (
    tester,
  ) async {
    final service = _StartupWorkspaceService();
    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(_MemorySettingsStore()),
        workspaceServiceProvider.overrideWithValue(service),
        startupPathProvider.overrideWithValue(
          'test/fixtures/markdown/basic.md',
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BusyMarkApp(),
      ),
    );
    await tester.pump();
    for (var i = 0; i < 10; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    container
        .read(workspaceControllerProvider.notifier)
        .updateActiveText('# Dirty\n');
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(find.text(l10n.unsavedChanges), findsOneWidget);

    await tester.tap(find.text(l10n.discard));
    await tester.pumpAndSettle();

    expect(service.untitledCount, 1);
    expect(find.text(l10n.workspaceKindUnsavedMarkdown), findsWidgets);
  });

  testWidgets('tab keyboard shortcuts move and close editor tabs', (
    tester,
  ) async {
    final temp = Directory.systemTemp.createTempSync('busymark_tabs_');
    addTearDown(() {
      temp.deleteSync(recursive: true);
    });
    final first = File('${temp.path}/a.md')..writeAsStringSync('# A\n');
    final second = File('${temp.path}/b.md')..writeAsStringSync('# B\n');
    final third = File('${temp.path}/c.md')..writeAsStringSync('# C\n');
    final service = _TabbedWorkspaceService(
      rootPath: temp.path,
      paths: [first.path, second.path, third.path],
    );
    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(_MemorySettingsStore()),
        workspaceServiceProvider.overrideWithValue(service),
        startupPathProvider.overrideWithValue(temp.path),
      ],
    );
    addTearDown(container.dispose);

    Future<void> pressControlShortcut(
      LogicalKeyboardKey key, {
      bool shift = false,
    }) async {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      if (shift) {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      }
      await tester.sendKeyDownEvent(key);
      await tester.sendKeyUpEvent(key);
      if (shift) {
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      }
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
    }

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BusyMarkApp(),
      ),
    );
    await tester.pump();
    for (var i = 0; i < 30; i += 1) {
      if (container.read(workspaceControllerProvider).workspace != null) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(container.read(workspaceControllerProvider).workspace, isNotNull);

    final controller = container.read(workspaceControllerProvider.notifier);
    await controller.openActiveFile(second.path);
    await controller.openActiveFile(third.path);
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      container.read(workspaceControllerProvider).workspace?.openFilePaths,
      [first.path, second.path, third.path],
    );
    expect(
      container.read(workspaceControllerProvider).workspace?.activeFilePath,
      third.path,
    );

    controller.updateActiveText('# Edited third\n');
    await tester.pump();

    await pressControlShortcut(LogicalKeyboardKey.tab);

    expect(find.text(l10n.unsavedChanges), findsNothing);
    expect(service.saveCount, 1);
    expect(service.savedPath, third.path);
    expect(service.savedText, '# Edited third\n');
    expect(
      container.read(workspaceControllerProvider).workspace?.activeFilePath,
      first.path,
    );

    await pressControlShortcut(LogicalKeyboardKey.tab, shift: true);

    expect(
      container.read(workspaceControllerProvider).workspace?.activeFilePath,
      third.path,
    );

    await pressControlShortcut(LogicalKeyboardKey.keyW);

    expect(
      container.read(workspaceControllerProvider).workspace?.activeFilePath,
      second.path,
    );
    expect(
      container.read(workspaceControllerProvider).workspace?.openFilePaths,
      [first.path, second.path],
    );

    await pressControlShortcut(LogicalKeyboardKey.keyW, shift: true);

    expect(
      container.read(workspaceControllerProvider).workspace?.activeFilePath,
      isNull,
    );
    expect(
      container.read(workspaceControllerProvider).workspace?.openFilePaths,
      isEmpty,
    );
    expect(find.text(l10n.noOpenFile), findsWidgets);
  });

  testWidgets('window close still warns when active changes are unsaved', (
    tester,
  ) async {
    final nativeWindow = _FakeNativeWindowController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
          localSettingsStoreProvider.overrideWithValue(_MemorySettingsStore()),
          nativeWindowControllerProvider.overrideWithValue(nativeWindow),
        ],
        child: const BusyMarkApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(nativeWindow.listeners, hasLength(1));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    nativeWindow.listeners.single.onWindowClose();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(l10n.closeUnsavedChangesTitle), findsOneWidget);
    expect(nativeWindow.closeCount, 0);
  });

  testWidgets('window close flushes autosave for saved files', (tester) async {
    final nativeWindow = _FakeNativeWindowController();
    final service = _StartupWorkspaceService();
    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(_MemorySettingsStore()),
        nativeWindowControllerProvider.overrideWithValue(nativeWindow),
        workspaceServiceProvider.overrideWithValue(service),
        startupPathProvider.overrideWithValue(
          'test/fixtures/markdown/basic.md',
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BusyMarkApp(),
      ),
    );
    for (var i = 0; i < 20; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (container.read(workspaceControllerProvider).workspace != null &&
          nativeWindow.listeners.isNotEmpty) {
        break;
      }
    }

    container
        .read(workspaceControllerProvider.notifier)
        .updateActiveText('# Closing\n');
    await tester.pump();

    nativeWindow.listeners.single.onWindowClose();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(service.saveCount, 1);
    expect(service.savedPath, 'test/fixtures/markdown/basic.md');
    expect(service.savedText, '# Closing\n');
    expect(find.text(l10n.closeUnsavedChangesTitle), findsNothing);
    expect(nativeWindow.closeCount, 1);
  });

  testWidgets('startup path opens a Markdown file workspace', (tester) async {
    final service = _StartupWorkspaceService();
    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(_MemorySettingsStore()),
        workspaceServiceProvider.overrideWithValue(service),
        startupPathProvider.overrideWithValue(
          'test/fixtures/markdown/basic.md',
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BusyMarkApp(),
      ),
    );
    await tester.pump();
    for (var i = 0; i < 10; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(service.openedPath, 'test/fixtures/markdown/basic.md');
    expect(find.text(l10n.openMarkdownFile), findsNothing);
    expect(find.textContaining('Basic Markdown'), findsWidgets);
  });

  testWidgets('shared Markdown image renderer resolves local images', (
    tester,
  ) async {
    final temp = Directory.systemTemp.createTempSync('busymark_preview_image_');
    try {
      File('${temp.path}/logo.png').writeAsBytesSync(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAFgwJ/l8Kz3wAAAABJRU5ErkJggg==',
        ),
      );
      final markdown = File('${temp.path}/image.md')
        ..writeAsStringSync('# Image\n\n![Logo](logo.png)\n');

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MarkdownImageView(
              source: 'logo.png',
              alt: 'Logo',
              activeFilePath: markdown.path,
              workspaceRoot: temp.path,
              writersideRoot: null,
              imagesDir: 'images',
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Image), findsOneWidget);
      expect(find.text('logo.png'), findsNothing);
    } finally {
      temp.deleteSync(recursive: true);
    }
  });

  testWidgets(
    'shared Markdown image renderer resolves absolute paths with spaces',
    (tester) async {
      final temp = Directory.systemTemp.createTempSync(
        'busymark_preview_image_space_',
      );
      try {
        final image = File('${temp.path}/Screenshot From 2026.png')
          ..writeAsBytesSync(
            base64Decode(
              'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAFgwJ/l8Kz3wAAAABJRU5ErkJggg==',
            ),
          );
        final markdown = File('${temp.path}/image.md')
          ..writeAsStringSync('# Image\n\n![Screenshot](${image.path})\n');

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: MarkdownImageView(
                source: image.path,
                alt: 'Screenshot',
                activeFilePath: markdown.path,
                workspaceRoot: temp.path,
                writersideRoot: null,
                imagesDir: 'images',
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(Image), findsOneWidget);
        expect(find.text(image.path), findsNothing);
      } finally {
        temp.deleteSync(recursive: true);
      }
    },
  );

  testWidgets(
    'shared Markdown image renderer rejects absolute paths outside workspace',
    (tester) async {
      final workspace = Directory.systemTemp.createTempSync(
        'busymark_preview_image_workspace_',
      );
      final outside = Directory.systemTemp.createTempSync(
        'busymark_preview_image_outside_',
      );
      try {
        final image = File('${outside.path}/outside.png')
          ..writeAsBytesSync(
            base64Decode(
              'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAFgwJ/l8Kz3wAAAABJRU5ErkJggg==',
            ),
          );
        final markdown = File('${workspace.path}/image.md')
          ..writeAsStringSync('# Image\n\n![Outside](${image.path})\n');

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: MarkdownImageView(
                source: image.path,
                alt: 'Outside',
                activeFilePath: markdown.path,
                workspaceRoot: workspace.path,
                writersideRoot: null,
                imagesDir: 'images',
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(Image), findsNothing);
        expect(find.textContaining(image.path), findsOneWidget);
      } finally {
        workspace.deleteSync(recursive: true);
        outside.deleteSync(recursive: true);
      }
    },
  );

  testWidgets('shared Markdown image renderer resolves local SVG images', (
    tester,
  ) async {
    final temp = Directory.systemTemp.createTempSync('busymark_preview_svg_');
    try {
      File('${temp.path}/logo.svg').writeAsStringSync(
        '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16">'
        '<rect width="16" height="16" fill="#3584e4"/>'
        '</svg>',
      );
      final markdown = File('${temp.path}/image.md')
        ..writeAsStringSync('# Image\n\n![Logo](logo.svg)\n');

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MarkdownImageView(
              source: 'logo.svg',
              alt: 'Logo',
              activeFilePath: markdown.path,
              workspaceRoot: temp.path,
              writersideRoot: null,
              imagesDir: 'images',
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.text('logo.svg'), findsNothing);
    } finally {
      temp.deleteSync(recursive: true);
    }
  });

  testWidgets(
    'shared Markdown image renderer sanitizes embedded SVG image data',
    (tester) async {
      final temp = Directory.systemTemp.createTempSync(
        'busymark_preview_svg_data_',
      );
      try {
        final embeddedSvg = Uri.encodeComponent(
          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 8 8">'
          '<rect width="8" height="8" fill="#ffffff"/>'
          '</svg>',
        );
        File('${temp.path}/badge.svg').writeAsStringSync(
          '<svg xmlns="http://www.w3.org/2000/svg" '
          'xmlns:xlink="http://www.w3.org/1999/xlink" '
          'width="20" height="20">'
          '<rect width="20" height="20" fill="#0e8420"/>'
          '<image x="2" y="2" width="16" height="16" '
          'xlink:href="data:image/svg+xml,$embeddedSvg"/>'
          '</svg>',
        );
        final markdown = File('${temp.path}/image.md')
          ..writeAsStringSync('# Image\n\n![Badge](badge.svg)\n');

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: MarkdownImageView(
                source: 'badge.svg',
                alt: 'Badge',
                activeFilePath: markdown.path,
                workspaceRoot: temp.path,
                writersideRoot: null,
                imagesDir: 'images',
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(tester.takeException(), isNull);
        expect(find.byType(SvgPicture), findsOneWidget);
        expect(find.textContaining('badge.svg'), findsNothing);
      } finally {
        temp.deleteSync(recursive: true);
      }
    },
  );

  testWidgets('shared Markdown image renderer renders generated SVG badges', (
    tester,
  ) async {
    final temp = Directory.systemTemp.createTempSync(
      'busymark_preview_svg_badge_',
    );
    try {
      final embeddedIcon = Uri.encodeComponent(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">'
        '<defs><style>.cls-1{fill:#fff}</style></defs>'
        '<path class="cls-1" d="M18.03 18.03l5.95-5.95-5.95-2.65v8.6z"/>'
        '</svg>',
      );
      File('${temp.path}/badge.svg').writeAsStringSync(
        '<svg xmlns="http://www.w3.org/2000/svg" '
        'xmlns:xlink="http://www.w3.org/1999/xlink" '
        'width="197.9" height="20">'
        '<clipPath id="round">'
        '<rect width="197.9" height="20" rx="3" fill="#fff"/>'
        '</clipPath>'
        '<g clip-path="url(#round)">'
        '<rect width="80.8" height="20" fill="#555"/>'
        '<rect x="80.8" width="117.1" height="20" fill="#0e8420"/>'
        '</g>'
        '<g fill="#fff" text-anchor="middle" font-size="110">'
        '<image x="5" y="3" width="14" height="14" '
        'xlink:href="data:image/svg+xml,$embeddedIcon"/>'
        '<text x="499" y="150" fill="#010101" fill-opacity=".3" '
        'transform="scale(0.1)" textLength="538" lengthAdjust="spacing">'
        'BusyMark'
        '</text>'
        '<text x="499" y="140" transform="scale(0.1)" '
        'textLength="538" lengthAdjust="spacing">'
        'BusyMark'
        '</text>'
        '<text x="1383.5" y="150" fill="#010101" fill-opacity=".3" '
        'transform="scale(0.1)" textLength="1071" lengthAdjust="spacing">'
        'latest/beta 0.1.1+1'
        '</text>'
        '<text x="1383.5" y="140" transform="scale(0.1)" '
        'textLength="1071" lengthAdjust="spacing">'
        'latest/beta 0.1.1+1'
        '</text>'
        '</g>'
        '</svg>',
      );
      final markdown = File('${temp.path}/image.md')
        ..writeAsStringSync('# Image\n\n![Badge](badge.svg)\n');

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: DefaultTextStyle.merge(
              style: const TextStyle(
                decoration: TextDecoration.underline,
                fontStyle: FontStyle.italic,
              ),
              child: MarkdownImageView(
                source: 'badge.svg',
                alt: 'Badge',
                activeFilePath: markdown.path,
                workspaceRoot: temp.path,
                writersideRoot: null,
                imagesDir: 'images',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.text('BusyMark'), findsOneWidget);
      expect(find.text('latest/beta 0.1.1+1'), findsOneWidget);
      expect(find.textContaining('badge.svg'), findsNothing);
      final badgeText = tester.widget<Text>(find.text('BusyMark'));
      expect(badgeText.style?.fontStyle, FontStyle.normal);
      expect(badgeText.style?.decoration, isNot(TextDecoration.underline));
      final iconRight = tester.getTopRight(find.byType(SvgPicture)).dx;
      final textLeft = tester.getTopLeft(find.text('BusyMark')).dx;
      expect(textLeft, greaterThan(iconRight + 2));
    } finally {
      temp.deleteSync(recursive: true);
    }
  });

  testWidgets('Ctrl+F opens search and Escape closes it', (tester) async {
    final service = _StartupWorkspaceService();
    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(_MemorySettingsStore()),
        workspaceServiceProvider.overrideWithValue(service),
        startupPathProvider.overrideWithValue(
          'test/fixtures/markdown/basic.md',
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BusyMarkApp(),
      ),
    );
    await tester.pump();
    for (var i = 0; i < 20; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text(l10n.workspaceKindSingleMarkdown).evaluate().isNotEmpty) {
        break;
      }
    }
    expect(find.text(l10n.workspaceKindSingleMarkdown), findsWidgets);

    final initialTextFields = find.byType(TextField).evaluate().length;

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(TextField).evaluate().length, initialTextFields + 1);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(TextField).evaluate().length, initialTextFields + 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(TextField).evaluate().length, initialTextFields);
  });

  testWidgets('preview search result clicks move preview scroll repeatedly', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final settingsStore = _MemorySettingsStore()
      ..value = AppSettings.defaults()
          .copyWith(documentViewMode: DocumentViewModePreference.preview)
          .toJson();
    final service = _SearchWorkspaceService(
      [
        '# Search Scroll',
        '',
        '- **First [needle target](https://example.com)**',
        '',
        for (var index = 0; index < 60; index += 1) ...[
          'Filler paragraph $index keeps the preview tall enough to scroll.',
          '',
        ],
        '- `Second needle target`',
        '',
        for (var index = 0; index < 20; index += 1) ...[
          'Trailing paragraph $index keeps the second target away from the end.',
          '',
        ],
      ].join('\n'),
    );
    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(settingsStore),
        workspaceServiceProvider.overrideWithValue(service),
        startupPathProvider.overrideWithValue('/tmp/search-scroll.md'),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BusyMarkApp(),
      ),
    );
    for (var i = 0; i < 20; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text(l10n.workspaceKindSingleMarkdown).evaluate().isNotEmpty) {
        break;
      }
    }

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'needle');
    await tester.pump();

    expect(
      find.text('- **First [needle target](https://example.com)**'),
      findsNothing,
    );
    expect(find.text('- `Second needle target`'), findsNothing);
    expect(find.text('First needle target'), findsWidgets);
    expect(find.text('Second needle target'), findsWidgets);

    await _tapLeftmostText(tester, 'Second needle target');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final secondOffset = _largestScrollableOffset(tester);
    expect(secondOffset, greaterThan(100));

    await _tapLeftmostText(tester, 'First needle target');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final firstOffset = _largestScrollableOffset(tester);
    expect(firstOffset, lessThan(secondOffset));

    await _tapLeftmostText(tester, 'Second needle target');
    await _tapLeftmostText(tester, 'First needle target');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(_largestScrollableOffset(tester), lessThan(secondOffset));
  });

  testWidgets('preview search result clicks scroll to code block matches', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final settingsStore = _MemorySettingsStore()
      ..value = AppSettings.defaults()
          .copyWith(documentViewMode: DocumentViewModePreference.preview)
          .toJson();
    final service = _SearchWorkspaceService(
      [
        '# Code Search',
        '',
        '```dart',
        "print('first code needle target');",
        '```',
        '',
        for (var index = 0; index < 60; index += 1) ...[
          'Filler paragraph $index keeps the preview tall enough to scroll.',
          '',
        ],
        '```dart',
        "print('second code needle target');",
        '```',
        '',
        for (var index = 0; index < 20; index += 1) ...[
          'Trailing paragraph $index keeps the second target away from the end.',
          '',
        ],
      ].join('\n'),
    );
    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(settingsStore),
        workspaceServiceProvider.overrideWithValue(service),
        startupPathProvider.overrideWithValue('/tmp/search-code-scroll.md'),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BusyMarkApp(),
      ),
    );
    for (var i = 0; i < 20; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text(l10n.workspaceKindSingleMarkdown).evaluate().isNotEmpty) {
        break;
      }
    }

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'code needle');
    await tester.pump();

    await _tapLeftmostText(tester, 'second code needle target');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final secondOffset = _largestScrollableOffset(tester);
    expect(secondOffset, greaterThan(100));

    await _tapLeftmostText(tester, 'first code needle target');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(_largestScrollableOffset(tester), lessThan(secondOffset));
  });

  testWidgets('preview search result click lands on paragraph after lists', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const target = 'An application factory is also available:';
    final settingsStore = _MemorySettingsStore()
      ..value = AppSettings.defaults()
          .copyWith(documentViewMode: DocumentViewModePreference.preview)
          .toJson();
    final service = _SearchWorkspaceService(_fsrsReadmeSearchSource());
    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(settingsStore),
        workspaceServiceProvider.overrideWithValue(service),
        startupPathProvider.overrideWithValue('/tmp/search-readme-scroll.md'),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BusyMarkApp(),
      ),
    );
    for (var i = 0; i < 20; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text(l10n.workspaceKindSingleMarkdown).evaluate().isNotEmpty) {
        break;
      }
    }

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'ac');
    await tester.pump();

    await _tapLeftmostText(tester, target);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    final rect = _rightmostTextRect(tester, target);
    final offset = _largestScrollableOffset(tester);
    expect(rect.top, greaterThan(40));
    expect(rect.bottom, lessThan(800), reason: 'rect=$rect offset=$offset');
  });

  testWidgets('preview search result click lands on code block line', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const target = 'conda activate fsrs-service';
    final settingsStore = _MemorySettingsStore()
      ..value = AppSettings.defaults()
          .copyWith(documentViewMode: DocumentViewModePreference.preview)
          .toJson();
    final service = _SearchWorkspaceService(_fsrsReadmeSearchSource());
    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(settingsStore),
        workspaceServiceProvider.overrideWithValue(service),
        startupPathProvider.overrideWithValue('/tmp/search-readme-scroll.md'),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BusyMarkApp(),
      ),
    );
    for (var i = 0; i < 20; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text(l10n.workspaceKindSingleMarkdown).evaluate().isNotEmpty) {
        break;
      }
    }

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'ac');
    await tester.pump();

    await _tapLeftmostText(tester, target);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    final rect = _rightmostTextRect(tester, target);
    final offset = _largestScrollableOffset(tester);
    expect(rect.top, greaterThan(0));
    expect(rect.bottom, lessThan(800), reason: 'rect=$rect offset=$offset');
  });

  testWidgets('Ctrl+S runs Save for the active workspace', (tester) async {
    final service = _StartupWorkspaceService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
          localSettingsStoreProvider.overrideWithValue(_MemorySettingsStore()),
          workspaceServiceProvider.overrideWithValue(service),
          startupPathProvider.overrideWithValue(
            'test/fixtures/markdown/basic.md',
          ),
        ],
        child: const BusyMarkApp(),
      ),
    );
    await tester.pump();
    for (var i = 0; i < 10; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyS);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyS);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(service.saveCount, 1);
    expect(service.savedPath, 'test/fixtures/markdown/basic.md');
    expect(service.savedText, '# Basic Markdown\n');
  });
}

double _largestScrollableOffset(WidgetTester tester) {
  var maxExtent = double.negativeInfinity;
  var pixels = 0.0;
  for (final state in tester.stateList<ScrollableState>(
    find.byType(Scrollable),
  )) {
    final position = state.position;
    if (position.maxScrollExtent > maxExtent) {
      maxExtent = position.maxScrollExtent;
      pixels = position.pixels;
    }
  }
  return pixels;
}

Future<void> _tapLeftmostText(WidgetTester tester, String text) async {
  final finder = find.textContaining(text).hitTestable();
  expect(finder, findsAtLeastNWidgets(1));
  Finder? leftmostFinder;
  var leftmostX = double.infinity;
  for (final element in finder.evaluate()) {
    final elementFinder = find.byElementPredicate(
      (candidate) => identical(candidate, element),
    );
    final center = tester.getCenter(elementFinder);
    if (center.dx < leftmostX) {
      leftmostX = center.dx;
      leftmostFinder = elementFinder;
    }
  }
  await tester.tap(leftmostFinder!);
}

Rect _rightmostTextRect(WidgetTester tester, String text) {
  final finder = find.textContaining(text);
  expect(finder, findsAtLeastNWidgets(1));
  Finder? rightmostFinder;
  var rightmostX = double.negativeInfinity;
  for (final element in finder.evaluate()) {
    final elementFinder = find.byElementPredicate(
      (candidate) => identical(candidate, element),
    );
    final center = tester.getCenter(elementFinder);
    if (center.dx > rightmostX) {
      rightmostX = center.dx;
      rightmostFinder = elementFinder;
    }
  }
  return tester.getRect(rightmostFinder!);
}

String _fsrsReadmeSearchSource() {
  return [
    '# FSRS Service',
    '',
    'Stateless FastAPI microservice exposing the **py-fsrs (FSRS 6.x)** scheduling algorithm via a strict OpenAPI contract.',
    '',
    'This service performs **pure computation only**.',
    'Persistence, authentication, authorization, and rate-limiting are expected to be handled by an upstream service (e.g.',
    'Spring Boot).',
    '',
    'This service is designed to be deployed:',
    '',
    '* Behind an API gateway or Spring Boot service',
    '* Without direct public exposure',
    '* Without authentication logic',
    '',
    '---',
    '',
    '## Conda Environment Setup',
    '',
    '```bash',
    'conda create -n fsrs-service python=3.11',
    'conda activate fsrs-service',
    'python -m pip install -e .',
    '```',
    '',
    'Install test dependencies:',
    '',
    '```bash',
    'conda install -n fsrs-service pytest',
    '```',
    '',
    '---',
    '',
    '## Run the Service',
    '',
    '```bash',
    'uvicorn fsrs_service.main:app --host 127.0.0.1 --port 8000',
    '```',
    '',
    'An application factory is also available:',
    '',
    '```python',
    'from fsrs_service.main import create_app',
    '',
    'app = create_app()',
    '```',
    '',
    '---',
    '',
    '### Scheduler Operations',
    '',
    '* `POST /v1/schedulers/retrievability`',
    '  Compute recall probability at a given time.',
    '',
    '* `POST /v1/schedulers/review`',
    '  Apply a review rating and return:',
    '',
    '  ```json',
    '  { "card": {}, "review_log": {} }',
    '  ```',
    '',
    '* `POST /v1/schedulers/reschedule`',
    '  Recompute card state **from review history**.',
    '',
    '  This endpoint **does not accept a target datetime**.',
    '  It replays `review_logs` to derive the card state.',
    '',
    for (var index = 0; index < 50; index += 1) ...[
      'Trailing content $index keeps the preview scrollable.',
      '',
    ],
  ].join('\n');
}

class _FallbackHeaderBarService extends LinuxHeaderBarService {
  _FallbackHeaderBarService()
    : super(channel: const MethodChannel('test.busymark/headerbar'));

  @override
  bool get isAvailable => false;

  @override
  bool get usesNativeHeaderBar => false;

  @override
  Stream<HeaderBarAction> get actions => const Stream.empty();
}

class _StartupWorkspaceService extends WorkspaceService {
  String? openedPath;
  String? savedPath;
  String? savedText;
  var untitledCount = 0;
  var saveCount = 0;

  @override
  Workspace createUntitledMarkdown({String source = ''}) {
    untitledCount++;
    return super.createUntitledMarkdown(source: source);
  }

  @override
  Future<Workspace> openPath(String path) async {
    openedPath = path;
    return Workspace(
      id: path,
      rootPath: path,
      kind: WorkspaceKind.singleMarkdown,
      openedAt: DateTime(2026),
      activeFilePath: path,
      activeFileModifiedAt: DateTime(2026),
      files: [
        DocumentFile(
          absolutePath: path,
          relativePath: 'basic.md',
          kind: DocumentKind.markdown,
          size: 16,
          lastModified: DateTime(2026),
        ),
      ],
      diagnostics: const [],
    );
  }

  @override
  Future<String> loadText(String path) async {
    return '# Basic Markdown\n';
  }

  @override
  Future<WorkspaceFileLoad> loadTextWithSnapshot(String path) async {
    return WorkspaceFileLoad(
      text: '# Basic Markdown\n',
      snapshot: WorkspaceFileSnapshot(
        modifiedAt: DateTime(2026),
        size: '# Basic Markdown\n'.length,
        contentHash: 'startup',
      ),
    );
  }

  @override
  Future<bool> fileChangedSince(
    String path,
    WorkspaceFileSnapshot? knownSnapshot,
  ) async {
    return false;
  }

  @override
  Future<WorkspaceFileSnapshot> saveText(String path, String text) async {
    saveCount++;
    savedPath = path;
    savedText = text;
    return WorkspaceFileSnapshot(
      modifiedAt: DateTime(2026, 1, 2),
      size: 0,
      contentHash: '',
    );
  }
}

class _TabbedWorkspaceService extends WorkspaceService {
  _TabbedWorkspaceService({required this.rootPath, required this.paths});

  final String rootPath;
  final List<String> paths;
  String? savedPath;
  String? savedText;
  var saveCount = 0;

  @override
  Future<Workspace> openPath(String path) async {
    final files = [
      for (final filePath in paths)
        DocumentFile(
          absolutePath: filePath,
          relativePath: filePath.split('/').last,
          kind: DocumentKind.markdown,
          size: _sourceFor(filePath).length,
          lastModified: DateTime(2026),
        ),
    ];
    return Workspace(
      id: rootPath,
      rootPath: rootPath,
      kind: WorkspaceKind.markdownFolder,
      openedAt: DateTime(2026),
      activeFilePath: paths.first,
      activeFileModifiedAt: DateTime(2026),
      openFilePaths: [paths.first],
      files: files,
      diagnostics: const [],
    );
  }

  @override
  Future<WorkspaceFileLoad> loadTextWithSnapshot(String path) async {
    final text = _sourceFor(path);
    return WorkspaceFileLoad(
      text: text,
      snapshot: WorkspaceFileSnapshot(
        modifiedAt: DateTime(2026),
        size: text.length,
        contentHash: path,
      ),
    );
  }

  @override
  Future<Workspace> reparseActive(Workspace workspace, String source) async {
    return workspace.copyWith(diagnostics: const []);
  }

  @override
  Future<bool> fileChangedSince(
    String path,
    WorkspaceFileSnapshot? knownSnapshot,
  ) async {
    return false;
  }

  @override
  Future<WorkspaceFileSnapshot> saveText(String path, String text) async {
    saveCount++;
    savedPath = path;
    savedText = text;
    return WorkspaceFileSnapshot(
      modifiedAt: DateTime(2026, 1, 2),
      size: text.length,
      contentHash: text,
    );
  }

  String _sourceFor(String path) => '# ${path.split('/').last}\n';
}

class _SearchWorkspaceService extends WorkspaceService {
  const _SearchWorkspaceService(this.source);

  final String source;

  @override
  Future<Workspace> openPath(String path) async {
    return Workspace(
      id: path,
      rootPath: path,
      kind: WorkspaceKind.singleMarkdown,
      openedAt: DateTime(2026),
      activeFilePath: path,
      activeFileModifiedAt: DateTime(2026),
      files: [
        DocumentFile(
          absolutePath: path,
          relativePath: 'search-scroll.md',
          kind: DocumentKind.markdown,
          size: source.length,
          lastModified: DateTime(2026),
        ),
      ],
      diagnostics: const [],
    );
  }

  @override
  Future<String> loadText(String path) async => source;

  @override
  Future<WorkspaceFileLoad> loadTextWithSnapshot(String path) async {
    return WorkspaceFileLoad(
      text: source,
      snapshot: WorkspaceFileSnapshot(
        modifiedAt: DateTime(2026),
        size: source.length,
        contentHash: 'search',
      ),
    );
  }
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

class _FakeNativeWindowController implements NativeWindowController {
  final preventCloseValues = <bool>[];
  final listeners = <WindowListener>[];
  var closeCount = 0;

  @override
  Future<void> setPreventClose(bool value) async {
    preventCloseValues.add(value);
  }

  @override
  Future<void> close() async {
    closeCount++;
  }

  @override
  void addListener(WindowListener listener) {
    listeners.add(listener);
  }

  @override
  void removeListener(WindowListener listener) {
    listeners.remove(listener);
  }
}
