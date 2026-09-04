import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/l10n/generated/app_localizations_ar.dart';
import 'package:busymark/l10n/generated/app_localizations_de.dart';
import 'package:busymark/l10n/generated/app_localizations_en.dart';
import 'package:busymark/l10n/generated/app_localizations_fa.dart';
import 'package:busymark/l10n/generated/app_localizations_fr.dart';
import 'package:busymark/src/app/app_metadata.dart';
import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/app/busymark_app.dart';
import 'package:busymark/src/app/busymark_dialogs.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/busymark_dialog_identity.dart';
import 'package:busymark/src/app/busymark_glyphs.dart';
import 'package:busymark/src/app/busymark_shortcuts.dart';
import 'package:busymark/src/app/startup_path.dart';
import 'package:busymark/src/app/window_control_service.dart';
import 'package:busymark/src/core/diagnostic.dart';
import 'package:busymark/src/core/local_image_resolver.dart';
import 'package:busymark/src/core/source_span.dart';
import 'package:busymark/src/editor/document_callout.dart';
import 'package:busymark/src/editor/document_code_block.dart';
import 'package:busymark/src/editor/document_layout.dart';
import 'package:busymark/src/editor/document_list_marker.dart';
import 'package:busymark/src/editor/document_text_geometry.dart';
import 'package:busymark/src/editor/document_thematic_break.dart';
import 'package:busymark/src/editor/markdown_image_view.dart';
import 'package:busymark/src/editor/source/source_editor.dart';
import 'package:busymark/src/editor/source/source_read_only_view.dart';
import 'package:busymark/src/feedback/presentation/feedback_dialog.dart';
import 'package:busymark/src/git/application/git_controller.dart';
import 'package:busymark/src/git/domain/git_models.dart';
import 'package:busymark/src/git/presentation/git_diff_viewer.dart';
import 'package:busymark/src/markdown/preview_model.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/platform/linux_header_bar_service.dart';
import 'package:busymark/src/writerside/writerside_model.dart';
import 'package:busymark/src/writerside/writerside_topic_creator.dart';
import 'package:busymark/src/writerside/writerside_topic_removal_service.dart';
import 'package:busymark/src/workspace/presentation/settings_screen.dart';
import 'package:busymark/src/workspace/workspace_controller.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:busymark/src/workspace/workspace_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:window_manager/window_manager.dart';

void main() {
  late _FallbackHeaderBarService headerBarService;
  final l10n = AppLocalizationsEn();

  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.defaultRouteNameTestValue = '/';
    headerBarService = _FallbackHeaderBarService();
  });

  test('editor shortcuts use documented cross-editor defaults', () {
    expect(
      {
        for (final entry in BusyMarkEditorShortcuts.definitions.entries)
          entry.key: entry.value.label,
      },
      {
        BusyMarkEditorShortcutAction.refineWithAi: 'Ctrl+G',
        BusyMarkEditorShortcutAction.bold: 'Ctrl+B',
        BusyMarkEditorShortcutAction.italic: 'Ctrl+I',
        BusyMarkEditorShortcutAction.underline: 'Ctrl+U',
        BusyMarkEditorShortcutAction.strikethrough: 'Alt+Shift+5',
        BusyMarkEditorShortcutAction.inlineCode: 'Ctrl+Shift+`',
        BusyMarkEditorShortcutAction.link: 'Ctrl+K',
        BusyMarkEditorShortcutAction.paragraph: 'Ctrl+Alt+0',
        BusyMarkEditorShortcutAction.heading1: 'Ctrl+Alt+1',
        BusyMarkEditorShortcutAction.heading2: 'Ctrl+Alt+2',
        BusyMarkEditorShortcutAction.heading3: 'Ctrl+Alt+3',
        BusyMarkEditorShortcutAction.heading4: 'Ctrl+Alt+4',
        BusyMarkEditorShortcutAction.heading5: 'Ctrl+Alt+5',
        BusyMarkEditorShortcutAction.heading6: 'Ctrl+Alt+6',
        BusyMarkEditorShortcutAction.orderedList: 'Ctrl+Shift+7',
        BusyMarkEditorShortcutAction.unorderedList: 'Ctrl+Shift+8',
        BusyMarkEditorShortcutAction.taskList: 'Ctrl+Shift+9',
        BusyMarkEditorShortcutAction.indent: 'Ctrl+]',
        BusyMarkEditorShortcutAction.outdent: 'Ctrl+[',
        BusyMarkEditorShortcutAction.blockquote: 'Ctrl+Shift+Q',
        BusyMarkEditorShortcutAction.codeBlock: 'Ctrl+Shift+K',
        BusyMarkEditorShortcutAction.image: 'Ctrl+Shift+I',
        BusyMarkEditorShortcutAction.hardLineBreak: 'Shift+Enter',
        BusyMarkEditorShortcutAction.pastePlainText: 'Ctrl+Shift+V',
      },
    );
  });

  test('document view shortcuts are distinct from existing commands', () {
    expect(
      {
        for (final entry in BusyMarkDocumentViewShortcuts.definitions.entries)
          entry.key: entry.value.label,
      },
      {
        BusyMarkDocumentViewShortcutAction.editor: 'Ctrl+Shift+1',
        BusyMarkDocumentViewShortcutAction.source: 'Ctrl+Shift+2',
        BusyMarkDocumentViewShortcutAction.reading: 'Ctrl+Shift+3',
        BusyMarkDocumentViewShortcutAction.split: 'Ctrl+Shift+4',
      },
    );

    final existingActivators = <ShortcutActivator>{
      ...BusyMarkAppShortcuts.definitions.values.map(
        (definition) => definition.activator,
      ),
      ...BusyMarkTextEditingShortcuts.definitions.values.map(
        (definition) => definition.activator,
      ),
      ...BusyMarkEditorShortcuts.definitions.values.map(
        (definition) => definition.activator,
      ),
      ...BusyMarkSidebarShortcuts.definitions.values.map(
        (definition) => definition.activator,
      ),
      ...BusyMarkTreeShortcuts.definitions.values.map(
        (definition) => definition.activator,
      ),
    };
    for (final definition in BusyMarkDocumentViewShortcuts.definitions.values) {
      expect(existingActivators, isNot(contains(definition.activator)));
    }
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
    expect(app.supportedLocales, contains(const Locale('et')));
    expect(app.supportedLocales, contains(const Locale('it')));
    expect(app.supportedLocales, contains(const Locale('nb')));
    expect(app.supportedLocales, isNot(contains(const Locale('no'))));
    expect(app.supportedLocales, contains(const Locale('fr')));
    expect(app.supportedLocales, contains(const Locale('ru')));
    expect(app.supportedLocales, contains(const Locale('uk')));
    expect(app.supportedLocales, contains(const Locale('pl')));
    expect(app.supportedLocales, contains(const Locale('es')));
    expect(
      app.supportedLocales,
      contains(Locale.fromSubtags(languageCode: 'pt', countryCode: 'BR')),
    );
    expect(app.supportedLocales, contains(const Locale('ar')));
    expect(app.supportedLocales, contains(const Locale('fa')));
    expect(app.supportedLocales, contains(const Locale('hi')));
    expect(app.supportedLocales, contains(const Locale('id')));
    expect(app.supportedLocales, contains(const Locale('ja')));
    expect(app.supportedLocales, contains(const Locale('ko')));
    expect(app.supportedLocales, contains(const Locale('nl')));
    expect(app.supportedLocales, contains(const Locale('tr')));
    expect(app.supportedLocales, contains(const Locale('vi')));
    expect(
      app.supportedLocales,
      contains(const Locale.fromSubtags(languageCode: 'zh', countryCode: 'CN')),
    );
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
    expect(find.text(l10n.markdownFolderOrWritersideProject), findsOneWidget);
    expect(find.text('File or folder path'), findsNothing);
    expect(find.textContaining('sign in'), findsNothing);
    expect(
      find.byTooltip(
        '${l10n.hideSidebar} (${BusyMarkSidebarShortcutLabels.toggleSidebar})',
      ),
      findsOneWidget,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.f9);
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.byTooltip(
        '${l10n.showSidebar} (${BusyMarkSidebarShortcutLabels.toggleSidebar})',
      ),
      findsOneWidget,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.f9);
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.byTooltip(
        '${l10n.hideSidebar} (${BusyMarkSidebarShortcutLabels.toggleSidebar})',
      ),
      findsOneWidget,
    );
  });

  testWidgets('main menu and F11 toggle full-screen mode', (tester) async {
    final nativeWindow = _FakeNativeWindowController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
          nativeWindowControllerProvider.overrideWithValue(nativeWindow),
        ],
        child: const BusyMarkApp(),
      ),
    );
    await tester.pumpAndSettle();

    Finder fullScreenMenuItem() => find.byWidgetPredicate(
      (widget) =>
          widget is BusyMarkPopupMenuItem<Object?> &&
          widget.label == l10n.fullScreen,
    );

    await tester.tap(find.byTooltip(l10n.mainMenu));
    await tester.pumpAndSettle();
    expect(find.text(l10n.fullScreen), findsOneWidget);
    expect(find.text(BusyMarkAppShortcutLabels.fullScreen), findsOneWidget);
    expect(
      tester
          .widget<BusyMarkPopupMenuItem<Object?>>(fullScreenMenuItem())
          .checked,
      isFalse,
    );

    await tester.tap(find.text(l10n.fullScreen));
    await tester.pumpAndSettle();
    expect(nativeWindow.fullScreenValues, [true]);

    await tester.tap(find.byTooltip(l10n.mainMenu));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<BusyMarkPopupMenuItem<Object?>>(fullScreenMenuItem())
          .checked,
      isTrue,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.f11);
    await tester.pumpAndSettle();
    expect(nativeWindow.fullScreenValues, [true, false]);
  });

  testWidgets('Alt+Left activates the header Back command', (tester) async {
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
    await tester.tap(find.text(l10n.settings));
    await tester.pumpAndSettle();
    expect(
      find.byTooltip('${l10n.back} (${BusyMarkAppShortcutLabels.back})'),
      findsOneWidget,
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pumpAndSettle();

    expect(find.text(l10n.createMarkdownFile), findsOneWidget);
    expect(find.byKey(const ValueKey('settings-page-selector')), findsNothing);
  });

  testWidgets('Escape closes header popup menus', (tester) async {
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

    expect(find.text(l10n.settings), findsOneWidget);
    expect(find.text(BusyMarkAppShortcutLabels.settings), findsOneWidget);
    expect(
      find.byTooltip(
        '${l10n.settings} (${BusyMarkAppShortcutLabels.settings})',
      ),
      findsNothing,
    );
    expect(find.text(l10n.keyboardShortcuts), findsOneWidget);
    expect(
      find.text(BusyMarkAppShortcutLabels.keyboardShortcuts),
      findsOneWidget,
    );
    expect(
      find.byTooltip(
        '${l10n.keyboardShortcuts} '
        '(${BusyMarkAppShortcutLabels.keyboardShortcuts})',
      ),
      findsNothing,
    );
    expect(find.text(l10n.syntaxReference), findsOneWidget);
    expect(
      find.text(BusyMarkAppShortcutLabels.syntaxReference),
      findsOneWidget,
    );
    expect(
      find.byTooltip(
        '${l10n.syntaxReference} '
        '(${BusyMarkAppShortcutLabels.syntaxReference})',
      ),
      findsNothing,
    );
    expect(find.text(l10n.reportIssue), findsOneWidget);
    expect(find.text(l10n.aboutBusyMark), findsOneWidget);
    expect(
      tester.getTopLeft(find.text(l10n.reportIssue)).dy,
      lessThan(tester.getTopLeft(find.text(l10n.aboutBusyMark)).dy),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.text(l10n.settings), findsNothing);
  });

  testWidgets('report issue is in the shared main menu, not Settings content', (
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

    await tester.tap(find.byTooltip(l10n.mainMenu));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.settings));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('settings-page-selector')),
      findsOneWidget,
    );
    expect(find.text(l10n.reportIssue), findsNothing);

    await tester.tap(find.byTooltip(l10n.mainMenu));
    await tester.pumpAndSettle();
    expect(find.text(l10n.reportIssue), findsOneWidget);
    expect(
      tester.getTopLeft(find.text(l10n.reportIssue)).dy,
      lessThan(tester.getTopLeft(find.text(l10n.aboutBusyMark)).dy),
    );
    await tester.tap(find.text(l10n.reportIssue));
    await tester.pumpAndSettle();

    expect(find.text(l10n.reportIssue), findsOneWidget);
    expect(find.text(l10n.feedbackCategory), findsOneWidget);
    expect(find.byKey(BusyMarkFeedbackKeys.cancel), findsOneWidget);
  });

  testWidgets('global reference and settings shortcuts open targets', (
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

    Future<void> pressShortcut(
      LogicalKeyboardKey key, {
      bool control = false,
      bool shift = false,
      bool alt = false,
    }) async {
      if (control) {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      }
      if (shift) {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      }
      if (alt) {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      }
      await tester.sendKeyDownEvent(key);
      await tester.sendKeyUpEvent(key);
      if (alt) {
        await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      }
      if (shift) {
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      }
      if (control) {
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      }
      await tester.pumpAndSettle();
    }

    await pressShortcut(LogicalKeyboardKey.keyK, control: true, alt: true);
    expect(
      find.text(l10n.shortcutKeyboardShortcutsDescription),
      findsOneWidget,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    await pressShortcut(LogicalKeyboardKey.keyM, control: true, alt: true);
    expect(
      find.byKey(const ValueKey('syntax-reference-dialog')),
      findsOneWidget,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    await pressShortcut(LogicalKeyboardKey.keyS, control: true, alt: true);
    expect(
      find.byKey(const ValueKey('settings-page-selector')),
      findsOneWidget,
    );
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

    expect(
      find.byKey(const ValueKey('settings-page-selector')),
      findsOneWidget,
    );
    expect(find.text(l10n.appLanguage), findsOneWidget);
    expect(find.text(l10n.systemLanguage), findsWidgets);
    expect(find.byType(DropdownButton<String>), findsNothing);

    await tester.tap(find.byTooltip(l10n.appLanguage));
    await tester.pumpAndSettle();

    expect(find.text('Deutsch'), findsOneWidget);
    expect(find.text('Eesti'), findsOneWidget);
    expect(find.text('العربية'), findsOneWidget);
    expect(find.text('हिन्दी'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.text('Deutsch'), findsNothing);
    expect(find.text('Eesti'), findsNothing);
    expect(find.text('العربية'), findsNothing);
    expect(find.text('हिन्दी'), findsNothing);

    await tester.tap(find.byTooltip(l10n.appLanguage));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.systemLanguage).last);
    await tester.pumpAndSettle();

    expect(
      find.byType(BusyMarkPopupSelector<BusyMarkThemeModePreference>),
      findsOneWidget,
    );
    expect(
      find.byType(SegmentedButton<BusyMarkThemeModePreference>),
      findsNothing,
    );
    await tester.tap(find.byTooltip(l10n.theme));
    await tester.pumpAndSettle();

    expect(find.text(l10n.systemTheme), findsWidgets);
    expect(find.text(l10n.lightTheme), findsOneWidget);
    expect(find.text(l10n.darkTheme), findsOneWidget);
    await tester.tap(find.text(l10n.darkTheme));
    await tester.pumpAndSettle();

    expect(settingsStore.value['themeModePreference'], 'dark');

    await tester.tap(find.byKey(const ValueKey('settings-page-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.editor));
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate((widget) => widget is SegmentedButton),
      findsNothing,
    );
    expect(
      find.byType(BusyMarkPopupSelector<EditorToolbarPlacement>),
      findsOneWidget,
    );
    expect(
      find.byType(BusyMarkPopupSelector<EditorToolbarDirection>),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip(l10n.editingButtonsPosition));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.bottomRight));
    await tester.pumpAndSettle();

    expect(settingsStore.value['editorToolbarPlacement'], 'bottomRight');

    await tester.tap(find.byTooltip(l10n.editingButtonsDirection));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.vertical));
    await tester.pumpAndSettle();

    expect(settingsStore.value['editorToolbarDirection'], 'vertical');

    expect(find.text(l10n.autoSave), findsOneWidget);
    expect(find.text(l10n.autoSaveDescription), findsOneWidget);
    await tester.tap(find.text(l10n.autoSave));
    await tester.pumpAndSettle();

    expect(settingsStore.value['autoSave'], isFalse);

    await tester.tap(find.byKey(const ValueKey('settings-page-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.validation));
    await tester.pumpAndSettle();

    expect(find.text(l10n.validateOnEdit), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('settings-page-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.settingsWindowSectionTitle));
    await tester.pumpAndSettle();

    expect(
      find.text(l10n.settingsReopenWorkspaceOnStartupTitle),
      findsOneWidget,
    );
    expect(
      find.text(l10n.settingsReopenWorkspaceOnStartupDescription),
      findsOneWidget,
    );
    await tester.tap(find.text(l10n.settingsReopenWorkspaceOnStartupTitle));
    await tester.pumpAndSettle();

    expect(settingsStore.value['reopenPreviousWorkspaceOnStartup'], isTrue);

    expect(
      find.text(l10n.settingsConfirmCloseWithUnsavedChangesTitle),
      findsOneWidget,
    );
    expect(
      find.text(l10n.settingsConfirmCloseWithUnsavedChangesDescription),
      findsOneWidget,
    );
    await tester.tap(
      find.text(l10n.settingsConfirmCloseWithUnsavedChangesTitle),
    );
    await tester.pumpAndSettle();

    expect(settingsStore.value['confirmCloseWithUnsavedChanges'], isFalse);
  });

  testWidgets('settings uses the regular split sidebar at desktop width', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 760);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

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
    await tester.tap(find.text(l10n.settings));
    await tester.pumpAndSettle();

    expect(find.byType(BusyMarkSidebarSurface), findsOneWidget);
    expect(find.byType(BusyMarkSidebarNavigation), findsOneWidget);
    expect(
      find.byType(BusyMarkSidebarNavigationTile),
      findsNWidgets(SettingsPage.values.length),
    );
    expect(
      tester.getSize(find.byType(BusyMarkSidebarSurface)).width,
      BusyMarkSizes.sidebarWidth,
    );
    expect(find.byKey(const ValueKey('settings-page-selector')), findsNothing);

    final appearanceTile = tester.widget<BusyMarkSidebarNavigationTile>(
      find.byKey(const ValueKey('settings-navigation-appearance')),
    );
    final editorTile = tester.widget<BusyMarkSidebarNavigationTile>(
      find.byKey(const ValueKey('settings-navigation-editor')),
    );
    expect(appearanceTile.selected, isTrue);
    expect(editorTile.selected, isFalse);

    var header = tester.widget<HeaderBarConfigurationPublisher>(
      find.byType(HeaderBarConfigurationPublisher),
    );
    expect(header.configuration.sidebarVisible, isTrue);
    expect(header.configuration.sidebarToggleVisible, isFalse);
    expect(header.configuration.title, l10n.appearance);

    await tester.tap(find.byKey(const ValueKey('settings-navigation-editor')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<BusyMarkSidebarNavigationTile>(
            find.byKey(const ValueKey('settings-navigation-editor')),
          )
          .selected,
      isTrue,
    );
    expect(find.text(l10n.autoSave), findsOneWidget);
    header = tester.widget<HeaderBarConfigurationPublisher>(
      find.byType(HeaderBarConfigurationPublisher),
    );
    expect(header.configuration.sidebarVisible, isTrue);
    expect(header.configuration.title, l10n.editor);
  });

  testWidgets('settings main surface matches the headerbar in light and dark', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 760);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    for (final preference in [
      BusyMarkThemeModePreference.light,
      BusyMarkThemeModePreference.dark,
    ]) {
      final settingsStore = _MemorySettingsStore()
        ..value = AppSettings.defaults()
            .copyWith(themeModePreference: preference)
            .toJson();
      headerBarService = _FallbackHeaderBarService();

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

      await tester.tap(find.byTooltip(l10n.mainMenu));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.settings));
      await tester.pumpAndSettle();

      final surfaceFinder = find.byKey(
        const ValueKey('settings-content-surface'),
      );
      expect(surfaceFinder, findsOneWidget);
      final surface = tester.widget<ColoredBox>(surfaceFinder);
      final surfaceContext = tester.element(surfaceFinder);
      final colors = BusyMarkSurfaceColors.of(surfaceContext);
      final header = tester.widget<HeaderBarConfigurationPublisher>(
        find.byType(HeaderBarConfigurationPublisher),
      );

      expect(
        Theme.of(surfaceContext).brightness,
        preference == BusyMarkThemeModePreference.dark
            ? Brightness.dark
            : Brightness.light,
      );
      expect(surface.color, colors.view);
      expect(surface.color, header.configuration.theme.backgroundColor);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
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

    expect(
      find.byKey(const ValueKey('settings-page-selector')),
      findsOneWidget,
    );
    expect(find.text(de.appLanguage), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('settings-page-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(de.validation));
    await tester.pumpAndSettle();

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

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    final newDialog = find.byType(BusyMarkDialogShell);
    expect(newDialog, findsOneWidget);
    await tester.tap(
      find.descendant(
        of: newDialog,
        matching: find.text(l10n.createWritersideProject),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.createWritersideProject), findsWidgets);
    expect(find.byType(BusyMarkModalEditorScaffold), findsOneWidget);
    expect(find.byType(BusyMarkEditorHeader), findsOneWidget);
    expect(find.byType(BusyMarkGroupedTextEntry), findsNWidgets(5));
    expect(find.byType(BusyMarkDialogShell), findsNothing);
    expect(find.byType(BusyMarkDialogButton), findsNothing);

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
    expect(find.text(l10n.shortcutGroupGeneral), findsOneWidget);
    expect(find.text(l10n.shortcutSearchDescription), findsOneWidget);
    expect(
      find.text(l10n.shortcutKeyboardShortcutsDescription),
      findsOneWidget,
    );
    expect(find.text(l10n.shortcutSyntaxReferenceDescription), findsOneWidget);
    expect(find.text(l10n.shortcutSettingsDescription), findsOneWidget);
    expect(find.text(l10n.shortcutNextTabDescription), findsOneWidget);
    expect(find.text(l10n.shortcutPreviousTabDescription), findsOneWidget);
    expect(find.text(l10n.shortcutCloseTabDescription), findsOneWidget);
    expect(find.text(l10n.shortcutCloseAllTabsDescription), findsOneWidget);
    expect(find.text('Show shortcuts over toolbar buttons'), findsNothing);
    expect(find.text(l10n.shortcutUndoDescription), findsOneWidget);
    expect(find.text(l10n.shortcutRedoDescription), findsOneWidget);
    expect(
      find.text(l10n.shortcutInsertIndentationDescription),
      findsOneWidget,
    );
    expect(find.text(l10n.shortcutOutdentSourceDescription), findsOneWidget);
    expect(find.text(l10n.shortcutEscapeDescription), findsOneWidget);
    expect(find.text(l10n.shortcutBoldDescription), findsOneWidget);
    expect(find.text(l10n.shortcutUnderlineDescription), findsOneWidget);
    expect(find.text(l10n.shortcutStrikethroughDescription), findsOneWidget);
    expect(find.text(l10n.shortcutParagraphDescription), findsOneWidget);
    expect(find.text(l10n.shortcutHeading1Description), findsOneWidget);
    expect(find.text(l10n.shortcutHeading6Description), findsOneWidget);
    expect(find.text(l10n.shortcutNumberedListDescription), findsOneWidget);
    expect(find.text(l10n.shortcutBulletedListDescription), findsOneWidget);
    expect(find.text(l10n.shortcutChecklistDescription), findsOneWidget);
    expect(find.text(l10n.shortcutGroupSidebar), findsOneWidget);
    expect(find.text(l10n.git), findsOneWidget);
    expect(find.text(l10n.gitChanges), findsNothing);
    expect(find.text(l10n.gitProjectHistory), findsNothing);
    expect(find.text(l10n.gitHistory), findsNothing);
    expect(find.text(l10n.shortcutDeleteTreeItemDescription), findsOneWidget);
    expect(find.text(l10n.viewMode), findsOneWidget);
    expect(find.text(l10n.editor), findsOneWidget);
    expect(find.text(l10n.source), findsOneWidget);
    expect(find.text(l10n.reading), findsOneWidget);
    expect(find.text(l10n.split), findsOneWidget);

    final expectedShortcutLabels = <String>{
      ...BusyMarkAppShortcuts.definitions.values.map(
        (definition) => definition.label,
      ),
      ...BusyMarkDocumentViewShortcuts.definitions.values.map(
        (definition) => definition.label,
      ),
      ...BusyMarkTextEditingShortcuts.definitions.values.map(
        (definition) => definition.label,
      ),
      ...BusyMarkEditorShortcuts.definitions.values.map(
        (definition) => definition.label,
      ),
      ...BusyMarkSidebarShortcuts.definitions.values.map(
        (definition) => definition.label,
      ),
      ...BusyMarkTreeShortcuts.definitions.values.map(
        (definition) => definition.label,
      ),
    };
    final shortcutRowFinder = find.descendant(
      of: find.byType(BusyMarkInformationalDialog),
      matching: find.byType(BusyMarkActionRow),
    );
    final shortcutRows = tester
        .widgetList<BusyMarkActionRow>(shortcutRowFinder)
        .toList();
    final displayedShortcutLabels = <String>[];
    for (final row in shortcutRows) {
      final trailing = row.trailing;
      expect(trailing, isNotNull, reason: 'Shortcut rows need a badge.');
      final badgeLabels = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byWidget(trailing!),
              matching: find.byType(Text),
            ),
          )
          .map((text) => text.data)
          .whereType<String>()
          .toList();
      expect(badgeLabels, hasLength(1));
      displayedShortcutLabels.add(badgeLabels.single);
    }
    expect(shortcutRows, hasLength(expectedShortcutLabels.length));
    expect(
      displayedShortcutLabels.toSet(),
      expectedShortcutLabels,
      reason: 'The popup must stay synchronized with every shortcut registry.',
    );
    expect(find.text('Alt'), findsNothing);
    expect(find.text('Esc'), findsOneWidget);
    expect(find.text('Close'), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.text(l10n.shortcutNewDocumentDescription), findsNothing);
  });

  testWidgets('syntax reference categories expose supported authoring forms', (
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
    await tester.tap(find.text(l10n.syntaxReference));
    await tester.pumpAndSettle();

    expect(find.text(l10n.syntaxReference), findsWidgets);
    expect(find.text('Markdown and HTML'), findsNothing);
    expect(
      find.byKey(const ValueKey('syntax-reference-category-selector')),
      findsOneWidget,
    );
    final sidebarSurface = tester.widget<Material>(
      find.byKey(const ValueKey('syntax-reference-sidebar-surface')),
    );
    final referenceDialog = tester.widget<Dialog>(
      find.descendant(
        of: find.byKey(const ValueKey('syntax-reference-dialog')),
        matching: find.byType(Dialog),
      ),
    );
    expect(sidebarSurface.color, referenceDialog.backgroundColor);
    Finder scopeHeading(String scope) =>
        find.byKey(ValueKey('syntax-reference-scope-heading-$scope'));
    Finder topicNavigation(String category, int index) => find.byKey(
      ValueKey('syntax-reference-topic-navigation-$category-$index'),
    );
    Finder categoryText(String categoryName, String text) => find.descendant(
      of: find.byKey(ValueKey('syntax-reference-category-$categoryName')),
      matching: find.text(text),
    );
    expect(find.text(l10n.markdown), findsWidgets);
    expect(
      categoryText('markdown', l10n.syntaxReferenceInlineFormatting),
      findsOneWidget,
    );
    expect(
      categoryText('markdown', l10n.syntaxReferenceMarkdownBlocks),
      findsOneWidget,
    );
    expect(categoryText('markdown', l10n.bold), findsOneWidget);
    expect(categoryText('markdown', l10n.italic), findsOneWidget);
    expect(categoryText('markdown', l10n.underline), findsOneWidget);
    expect(find.text('<u>underlined</u>'), findsOneWidget);
    expect(categoryText('markdown', l10n.strikethrough), findsOneWidget);
    expect(categoryText('markdown', l10n.inlineCode), findsOneWidget);
    expect(topicNavigation('markdown', 0), findsOneWidget);
    expect(topicNavigation('markdown', 1), findsOneWidget);
    expect(topicNavigation('markdown', 2), findsNothing);
    expect(find.text(l10n.syntaxReferenceScope), findsNothing);
    expect(scopeHeading(l10n.markdown), findsNothing);

    Future<void> selectCategory(
      String categoryName,
      String fallbackLabel,
    ) async {
      final navigationTile = find.byKey(
        ValueKey('syntax-reference-category-navigation-$categoryName'),
      );
      if (navigationTile.evaluate().isNotEmpty) {
        await tester.tap(navigationTile);
      } else {
        await tester.tap(
          find.byKey(const ValueKey('syntax-reference-category-selector')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(fallbackLabel).last);
      }
      await tester.pumpAndSettle();
    }

    Future<List<BusyMarkPopupMenuItem<Uri>>> openDocumentationMenu(
      String featureTitle,
    ) async {
      final documentationAction = find.byKey(
        ValueKey('syntax-reference-documentation-$featureTitle'),
      );
      await tester.ensureVisible(documentationAction);
      await tester.pumpAndSettle();
      await tester.tap(documentationAction);
      await tester.pumpAndSettle();
      return tester
          .widgetList<BusyMarkPopupMenuItem<Uri>>(
            find.byType(BusyMarkPopupMenuItem<Uri>),
          )
          .toList();
    }

    expect(find.text(l10n.markdown), findsWidgets);
    expect(find.text(l10n.syntaxReferenceCategoryHtml), findsOneWidget);
    expect(
      find.text(l10n.syntaxReferenceCategoryDiagramsAndApi),
      findsOneWidget,
    );
    expect(find.text(l10n.syntaxReferenceCategoryMathematics), findsOneWidget);
    expect(find.text(l10n.writerside), findsOneWidget);
    await selectCategory(
      'diagramsAndApi',
      l10n.syntaxReferenceCategoryDiagramsAndApi,
    );
    expect(find.text('mermaid'), findsOneWidget);
    expect(find.text('plantuml, puml'), findsOneWidget);
    expect(find.text('d2'), findsOneWidget);
    expect(find.text('openapi, oas, swagger'), findsOneWidget);
    expect(find.textContaining('@startuml'), findsOneWidget);
    expect(find.textContaining('openapi: 3.0.3'), findsOneWidget);
    expect(
      find.text(l10n.syntaxReferenceSemanticDiagramLimitation),
      findsOneWidget,
    );
    expect(
      find.text(l10n.syntaxReferenceReferencedDiagramLimitation),
      findsOneWidget,
    );
    final diagramDocumentation = await openDocumentationMenu(
      l10n.syntaxReferenceSemanticDiagramBlocks,
    );
    expect(diagramDocumentation.map((item) => item.label), [
      l10n.syntaxReferenceMermaid,
      l10n.syntaxReferencePlantUml,
      l10n.syntaxReferenceD2,
    ]);
    expect(diagramDocumentation.map((item) => item.menuValue.toString()), [
      'https://www.jetbrains.com/help/writerside/mermaid-diagrams.html',
      'https://www.jetbrains.com/help/writerside/plantuml-diagrams.html',
      'https://www.jetbrains.com/help/writerside/d2-diagrams.html',
    ]);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    final writersideDiagramsTopic = find.byKey(
      const ValueKey('syntax-reference-topic-navigation-diagramsAndApi-1'),
    );
    expect(writersideDiagramsTopic, findsOneWidget);
    await tester.tap(writersideDiagramsTopic);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<BusyMarkSidebarNavigationTile>(writersideDiagramsTopic)
          .selected,
      isTrue,
    );
    expect(tester.takeException(), isNull);
    expect(topicNavigation('diagramsAndApi', 2), findsNothing);

    await selectCategory(
      'mathematics',
      l10n.syntaxReferenceCategoryMathematics,
    );
    expect(scopeHeading(l10n.markdown), findsNothing);
    expect(
      scopeHeading(l10n.syntaxReferenceScopeWritersideMarkdown),
      findsOneWidget,
    );
    expect(
      scopeHeading(l10n.syntaxReferenceScopeWritersideMarkdownAndXml),
      findsOneWidget,
    );
    expect(find.text(l10n.syntaxReferenceTexFenceLimitation), findsOneWidget);
    expect(
      find.text(l10n.syntaxReferenceMathDelimitersLimitation),
      findsOneWidget,
    );
    expect(
      find.text(l10n.syntaxReferenceWritersideMathElementLimitation),
      findsOneWidget,
    );
    expect(topicNavigation('mathematics', 2), findsOneWidget);
    expect(topicNavigation('mathematics', 3), findsNothing);

    await selectCategory('writerside', l10n.writerside);
    expect(
      find.text(l10n.syntaxReferenceSemanticMarkupLimitation),
      findsOneWidget,
    );
    expect(
      categoryText('writerside', l10n.syntaxReferenceSemanticCodeBlocks),
      findsOneWidget,
    );
    expect(
      categoryText('writerside', l10n.syntaxReferenceVideo),
      findsOneWidget,
    );
    final semanticCodeDocumentation = await openDocumentationMenu(
      l10n.syntaxReferenceSemanticCodeBlocks,
    );
    expect(semanticCodeDocumentation.map((item) => item.label), [
      l10n.syntaxReferenceCategoryMathematics,
      l10n.syntaxReferenceMermaid,
      l10n.syntaxReferencePlantUml,
      l10n.syntaxReferenceD2,
    ]);
    expect(semanticCodeDocumentation.map((item) => item.menuValue.toString()), [
      'https://www.jetbrains.com/help/writerside/math-support.html',
      'https://www.jetbrains.com/help/writerside/mermaid-diagrams.html',
      'https://www.jetbrains.com/help/writerside/plantuml-diagrams.html',
      'https://www.jetbrains.com/help/writerside/d2-diagrams.html',
    ]);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    final referencedDiagramDocumentation = await openDocumentationMenu(
      l10n.syntaxReferenceReferencedDiagramSource,
    );
    expect(
      referencedDiagramDocumentation.map((item) => item.menuValue.toString()),
      [
        'https://www.jetbrains.com/help/writerside/mermaid-diagrams.html',
        'https://www.jetbrains.com/help/writerside/plantuml-diagrams.html',
        'https://www.jetbrains.com/help/writerside/d2-diagrams.html',
      ],
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(topicNavigation('writerside', 3), findsOneWidget);
    expect(topicNavigation('writerside', 4), findsNothing);

    await selectCategory('html', l10n.syntaxReferenceCategoryHtml);
    expect(
      categoryText('html', l10n.syntaxReferenceRawHtmlBlocks),
      findsOneWidget,
    );
    expect(
      categoryText('html', l10n.syntaxReferenceRawHtmlInline),
      findsOneWidget,
    );
    expect(find.text('Safety Rules'), findsNothing);
    expect(
      categoryText('html', l10n.syntaxReferenceHtmlContainers),
      findsOneWidget,
    );
    expect(
      categoryText('html', l10n.syntaxReferenceHtmlTextBlocks),
      findsOneWidget,
    );
    expect(categoryText('html', l10n.syntaxReferenceLists), findsOneWidget);
    expect(categoryText('html', l10n.table), findsOneWidget);
    expect(
      categoryText('html', l10n.syntaxReferenceHtmlFigures),
      findsOneWidget,
    );
    expect(
      categoryText('html', l10n.syntaxReferenceHtmlPreformatted),
      findsOneWidget,
    );
    expect(
      categoryText('html', l10n.syntaxReferenceHtmlDisclosure),
      findsOneWidget,
    );
    expect(
      categoryText('html', l10n.syntaxReferenceHtmlDescriptionLists),
      findsOneWidget,
    );
    expect(
      categoryText('html', l10n.syntaxReferenceHtmlFormattingTags),
      findsOneWidget,
    );
    expect(
      categoryText('html', l10n.syntaxReferenceHtmlInlineCodeTags),
      findsOneWidget,
    );
    expect(categoryText('html', l10n.link), findsOneWidget);
    expect(categoryText('html', l10n.inlineImage), findsOneWidget);
    expect(
      categoryText('html', l10n.syntaxReferenceHtmlNeutralInlineTags),
      findsOneWidget,
    );
    expect(categoryText('html', l10n.hardLineBreak), findsOneWidget);
    expect(topicNavigation('html', 1), findsOneWidget);
    expect(topicNavigation('html', 2), findsNothing);
    expect(find.textContaining('article, aside, div, section'), findsOneWidget);
    expect(find.textContaining('strong, em, b, i, u'), findsOneWidget);
    expect(find.textContaining('span, abbr, cite, q'), findsOneWidget);
    expect(
      find.text(l10n.syntaxReferenceMarkdownInsideHtmlDescription),
      findsWidgets,
    );
    expect(
      find.textContaining(l10n.syntaxReferenceBlockedContentDescription),
      findsOneWidget,
    );
    expect(
      find.textContaining(l10n.syntaxReferenceSourcePreservedDescription),
      findsOneWidget,
    );
    expect(find.text(l10n.syntaxReferenceSafeUrlsDescription), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('syntax-reference-dialog')), findsNothing);
  });

  testWidgets('Ctrl+Alt+M opens and Escape closes the syntax reference', (
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

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(BusyMarkAppShortcutLabels.syntaxReference, 'Ctrl+Alt+M');
    expect(
      find.byKey(const ValueKey('syntax-reference-dialog')),
      findsOneWidget,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('syntax-reference-dialog')), findsNothing);
  });

  testWidgets('syntax reference remains usable in constrained RTL layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(560, 420);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final ar = AppLocalizationsAr();
    final settingsStore = _MemorySettingsStore()
      ..value = AppSettings.defaults().copyWith(localeTag: 'ar').toJson();

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

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    final dialog = find.byKey(const ValueKey('syntax-reference-dialog'));
    expect(dialog, findsOneWidget);
    expect(Directionality.of(tester.element(dialog)), TextDirection.rtl);
    expect(find.text(ar.syntaxReference), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(
      find.byKey(const ValueKey('syntax-reference-category-selector')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(ar.syntaxReferenceCategoryMathematics).last);
    await tester.pumpAndSettle();
    expect(find.text(ar.syntaxReferenceMathematicsDescription), findsOneWidget);
    expect(
      find.byKey(const ValueKey('syntax-reference-topic-selector')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('syntax-reference-topic-selector')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(ar.syntaxReferenceTexFence).last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.drag(
      find.byKey(const ValueKey('syntax-reference-category-mathematics')),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('syntax-reference-category-selector')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(dialog, findsNothing);
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
    expect(fr.shortcutGroupSidebar, isNot('Sidebar'));
    expect(find.text(fr.shortcutGroupSidebar), findsOneWidget);
    expect(find.text('Tabs'), findsNothing);
    expect(find.text('Sidebar'), findsNothing);
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
    final versionTag = find.byKey(const ValueKey('about-version-tag'));
    expect(versionTag, findsOneWidget);
    final versionTagTheme = Theme.of(tester.element(versionTag));
    final versionTagDecoration =
        tester.widget<DecoratedBox>(versionTag).decoration as BoxDecoration;
    expect(versionTagDecoration.color, versionTagTheme.colorScheme.primary);
    expect(
      tester.widget<Text>(find.text(busyMarkAppVersion)).style?.color,
      versionTagTheme.colorScheme.onPrimary,
    );
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
    expect(find.text(l10n.aboutSourceCode), findsOneWidget);
    expect(find.text('https://github.com/busystack/busymark/'), findsOneWidget);
    final sourceCodeRow = find.ancestor(
      of: find.text(l10n.aboutSourceCode),
      matching: find.byType(BusyMarkActionRow),
    );
    expect(sourceCodeRow, findsOneWidget);
    expect(
      find.descendant(
        of: sourceCodeRow,
        matching: find.byIcon(BusyMarkGlyphs.code),
      ),
      findsOneWidget,
    );
    final logo = find.byType(SvgPicture);
    expect(logo, findsOneWidget);
    final logoSize = tester.getSize(logo);
    expect(logoSize.width, lessThanOrEqualTo(BusyMarkSizes.aboutLogoViewport));
    expect(logoSize.height, lessThanOrEqualTo(BusyMarkSizes.aboutLogoViewport));
  });

  testWidgets('Ctrl+N chooses between Markdown and Writerside creation', (
    tester,
  ) async {
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

    final newDialog = find.byType(BusyMarkDialogShell);
    final createMarkdown = find.descendant(
      of: newDialog,
      matching: find.text(l10n.createMarkdownFile),
    );
    final createWriterside = find.descendant(
      of: newDialog,
      matching: find.text(l10n.createWritersideProject),
    );
    expect(service.untitledCount, 0);
    expect(newDialog, findsOneWidget);
    expect(createMarkdown, findsOneWidget);
    expect(createWriterside, findsOneWidget);
    expect(
      find.descendant(
        of: newDialog,
        matching: find.byIcon(BusyMarkGlyphs.newDocument),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: newDialog,
        matching: find.byIcon(BusyMarkGlyphs.writersideProject),
      ),
      findsOneWidget,
    );

    await tester.tap(createMarkdown);
    await tester.pumpAndSettle();

    expect(service.untitledCount, 1);
    expect(find.text(l10n.createMarkdownFile), findsNothing);
    expect(find.text(l10n.workspaceKindUnsavedMarkdown), findsWidgets);
  });

  testWidgets('Ctrl+N keeps unsaved documents in independent tabs', (
    tester,
  ) async {
    final service = _StartupWorkspaceService();
    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(
          _MemorySettingsStore()
            ..value = AppSettings.defaults().copyWith(autoSave: false).toJson(),
        ),
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

    final firstNewDialog = find.byType(BusyMarkDialogShell);
    expect(
      find.descendant(
        of: firstNewDialog,
        matching: find.text(l10n.createMarkdownFile),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: firstNewDialog,
        matching: find.text(l10n.createWritersideProject),
      ),
      findsOneWidget,
    );
    expect(find.text(l10n.unsavedChanges), findsNothing);

    await tester.tap(
      find.descendant(
        of: firstNewDialog,
        matching: find.text(l10n.createMarkdownFile),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.unsavedChanges), findsNothing);
    expect(service.untitledCount, 1);
    expect(
      container.read(workspaceControllerProvider).documentBuffers,
      hasLength(2),
    );
    expect(
      container
          .read(workspaceControllerProvider)
          .documentBuffers
          .where((buffer) => buffer.isDirty),
      hasLength(2),
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(BusyMarkDialogShell),
        matching: find.text(l10n.createMarkdownFile),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.unsavedChanges), findsNothing);
    expect(service.untitledCount, 2);
    expect(
      container.read(workspaceControllerProvider).documentBuffers,
      hasLength(3),
    );
    await tester.pump(const Duration(milliseconds: 800));
  });

  testWidgets('Topics defaults creation to root and exposes file-style menu', (
    tester,
  ) async {
    const yaruWindowChannel = MethodChannel('yaru_window');
    const yaruWindowEventsChannel = MethodChannel('yaru_window/events');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(yaruWindowChannel, (call) async {
          if (call.method == 'state') {
            return <String, Object?>{};
          }
          return null;
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(yaruWindowEventsChannel, (_) async => null);
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        ..setMockMethodCallHandler(yaruWindowChannel, null)
        ..setMockMethodCallHandler(yaruWindowEventsChannel, null);
    });
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.defaultRouteNameTestValue = '/workspace';
    addTearDown(() {
      binding.platformDispatcher.defaultRouteNameTestValue = '/';
    });
    final root = Directory.systemTemp.createTempSync(
      'busymark-topics-sidebar-',
    );
    addTearDown(() {
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
    });
    Directory(p.join(root.path, 'topics')).createSync();
    File(p.join(root.path, 'writerside.cfg')).writeAsStringSync('''
<ihp version="2.0">
  <topics dir="topics"/>
  <instance src="guide.tree"/>
  <instance src="api.tree"/>
</ihp>
''');
    File(p.join(root.path, 'guide.tree')).writeAsStringSync('''
<instance-profile id="guide" name="Guide" start-page="nested.md">
  <toc-element topic="parent.md">
    <toc-element topic="nested.md" toc-title="Nested entry"/>
  </toc-element>
  <toc-element topic="loose.md"/>
  <toc-element topic="target.md"/>
</instance-profile>
''');
    File(p.join(root.path, 'api.tree')).writeAsStringSync('''
<instance-profile id="api" name="API Reference" start-page="api.md">
  <toc-element topic="api.md"/>
</instance-profile>
''');
    File(
      p.join(root.path, 'topics', 'parent.md'),
    ).writeAsStringSync('# Parent\n');
    File(
      p.join(root.path, 'topics', 'nested.md'),
    ).writeAsStringSync('# Nested\n');
    File(
      p.join(root.path, 'topics', 'loose.md'),
    ).writeAsStringSync('# Loose\n');
    File(
      p.join(root.path, 'topics', 'target.md'),
    ).writeAsStringSync('# Target\n');
    File(p.join(root.path, 'topics', 'api.md')).writeAsStringSync('# API\n');
    final sharedModule = Directory(p.join(root.path, 'shared'))..createSync();
    Directory(p.join(sharedModule.path, 'topics')).createSync();
    File(p.join(sharedModule.path, 'writerside.cfg')).writeAsStringSync('''
<ihp version="2.0">
  <module name="shared-docs"/>
  <topics dir="topics"/>
  <instance src="shared.tree"/>
</ihp>
''');
    File(p.join(sharedModule.path, 'shared.tree')).writeAsStringSync('''
<instance-profile id="shared" name="Shared" start-page="shared.md">
  <toc-element topic="shared.md"/>
</instance-profile>
''');
    File(
      p.join(sharedModule.path, 'topics', 'shared.md'),
    ).writeAsStringSync('# Shared\n');
    final workspace = (await tester.runAsync(
      () => const WorkspaceService().openPath(root.path),
    ))!;
    final workspaceState = WorkspaceState(
      workspace: workspace,
      activeText: '# Nested\n',
    );
    final controller = _MutableWorkspaceController(workspaceState);
    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(_MemorySettingsStore()),
        workspaceControllerProvider.overrideWith(() => controller),
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
    for (var index = 0; index < 10; index += 1) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    Future<void> openPopup(
      Finder anchor, {
      int buttons = kPrimaryButton,
    }) async {
      await tester.tap(anchor, buttons: buttons);
      await tester.pumpAndSettle();
    }

    Finder popupMenuItem(String label) => find.byWidgetPredicate(
      (widget) =>
          widget is BusyMarkPopupMenuItem<Object?> && widget.label == label,
    );

    await openPopup(find.byTooltip(l10n.sidebarViewMenu));
    await tester.tap(find.text(l10n.files));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('target.md'));
    await tester.pump(const Duration(milliseconds: 200));
    final filesDeleteHandled = await tester.sendKeyDownEvent(
      LogicalKeyboardKey.delete,
    );
    expect(filesDeleteHandled, isTrue);
    await tester.pumpAndSettle();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.delete);
    expect(
      controller.analyzedRemovalMode,
      WritersideTopicRemovalMode.safeDeleteFile,
    );
    expect(find.text(l10n.safeDeleteTopicFile), findsOneWidget);
    await tester.tap(find.text(l10n.cancel));
    await tester.pump(const Duration(milliseconds: 200));

    await openPopup(find.byTooltip(l10n.sidebarViewMenu));
    await tester.tap(find.text(l10n.toc));
    await tester.pump(const Duration(milliseconds: 300));

    final guideInstance = find.byKey(
      const ValueKey('writerside-instance-guide'),
    );
    final apiInstance = find.byKey(const ValueKey('writerside-instance-api'));
    expect(guideInstance, findsOneWidget);
    expect(apiInstance, findsOneWidget);
    expect(
      find.byKey(const ValueKey('writerside-module-selector')),
      findsOneWidget,
    );
    await openPopup(find.byKey(const ValueKey('writerside-module-selector')));
    await tester.tap(find.text('shared-docs'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(controller.selectedWritersideModuleId, 'shared-docs');
    await tester.tap(apiInstance);
    await tester.pump(const Duration(milliseconds: 200));
    expect(controller.selectedWritersideInstanceId, 'api');
    await tester.tap(guideInstance);
    await tester.pump(const Duration(milliseconds: 200));
    final guideIcon = tester.widget<Icon>(
      find.descendant(
        of: guideInstance,
        matching: find.byIcon(BusyMarkGlyphs.tree),
      ),
    );
    final apiIcon = tester.widget<Icon>(
      find.descendant(
        of: apiInstance,
        matching: find.byIcon(BusyMarkGlyphs.tree),
      ),
    );
    expect(guideIcon.color, isNotNull);
    expect(apiIcon.color, isNotNull);
    expect(guideIcon.color, isNot(apiIcon.color));

    expect(find.text('Nested entry'), findsOneWidget);
    expect(find.byTooltip(l10n.tocActions), findsOneWidget);
    expect(find.byTooltip(l10n.newTopic), findsNothing);
    expect(find.byTooltip(l10n.newChildTopic), findsNothing);
    final tocMenuButton = find.descendant(
      of: find.byKey(const ValueKey('workspace-sidebar-toc-menu')),
      matching: find.byType(IconButton),
    );
    expect(tester.widget<IconButton>(tocMenuButton).isSelected, isFalse);
    await openPopup(find.byTooltip(l10n.tocActions));
    expect(tester.widget<IconButton>(tocMenuButton).isSelected, isFalse);
    expect(find.text(l10n.newTopic), findsOneWidget);
    expect(find.text(l10n.newInstance), findsOneWidget);
    expect(find.text(l10n.newTocLibrary), findsOneWidget);
    expect(find.text(l10n.editInstance), findsOneWidget);
    expect(find.text(l10n.openTocFile), findsOneWidget);
    await tester.tap(find.text(l10n.editInstance));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(l10n.instanceOutputSettings), findsOneWidget);
    expect(
      find.byKey(const ValueKey('writerside-instance-name')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('writerside-instance-id')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('writerside-instance-version')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('writerside-instance-web-path')),
      findsOneWidget,
    );
    expect(find.text(l10n.allowSearchEngineIndexing), findsOneWidget);
    expect(find.text(l10n.offlineArtifact), findsOneWidget);
    expect(find.text(l10n.instanceAppearance), findsOneWidget);
    await tester.tap(find.text(l10n.cancel));
    await tester.pump(const Duration(milliseconds: 300));

    await openPopup(find.byTooltip(l10n.tocActions));
    await tester.tap(find.text(l10n.newInstance));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(l10n.createInstance), findsOneWidget);
    expect(find.text(l10n.emptyInstance), findsOneWidget);
    await tester.tap(find.text(l10n.emptyInstance));
    await tester.pumpAndSettle();
    expect(find.text(l10n.markdownFiles), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text(l10n.instanceAppearance), findsOneWidget);
    await tester.tap(find.text(l10n.cancel));
    await tester.pump(const Duration(milliseconds: 300));

    await openPopup(find.byTooltip(l10n.tocActions));
    await tester.tap(find.text(l10n.newTopic));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(l10n.topicPlacement), findsOneWidget);
    expect(find.text(l10n.tocRoot), findsOneWidget);
    expect(find.byType(BusyMarkModalEditorScaffold), findsOneWidget);
    expect(find.byType(BusyMarkGroupedTextEntry), findsNWidgets(2));
    expect(
      find.byWidgetPredicate(
        (widget) => widget is BusyMarkComboRow<WritersideTopicCreatePlacement>,
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) => widget is BusyMarkComboRow<WritersideTopicFormat>,
      ),
      findsOneWidget,
    );
    expect(find.byType(BusyMarkDialogShell), findsNothing);
    expect(find.byType(SegmentedButton<WritersideTopicFormat>), findsNothing);

    await tester.tap(
      find.descendant(
        of: find.byType(BusyMarkEditorHeader),
        matching: find.widgetWithText(ElevatedButton, l10n.create),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(controller.createdTopicRequest, isNotNull);
    expect(
      controller.createdTopicRequest!.placement,
      WritersideTopicCreatePlacement.root,
    );
    expect(controller.createdTopicRequest!.referenceTocPath, isNull);
    expect(controller.createdTopicRequest!.referenceTopic, isNull);
    expect(controller.createdTopicTreePath, p.join(root.path, 'guide.tree'));

    await tester.tap(apiInstance);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('api.md'), findsOneWidget);

    await openPopup(find.byTooltip(l10n.tocActions));
    expect(find.text(l10n.newTopic), findsOneWidget);
    await tester.tap(find.text(l10n.newTopic));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(
      find.descendant(
        of: find.byType(BusyMarkEditorHeader),
        matching: find.widgetWithText(ElevatedButton, l10n.create),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(controller.createdTopicTreePath, p.join(root.path, 'api.tree'));

    await tester.tap(guideInstance);
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Nested entry'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.delete);
    await tester.pumpAndSettle();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.delete);
    expect(
      controller.analyzedRemovalMode,
      WritersideTopicRemovalMode.removeFromInstance,
    );
    expect(find.text(l10n.removeTocElement), findsOneWidget);
    await tester.tap(find.text(l10n.cancel));
    await tester.pump(const Duration(milliseconds: 200));

    await tester.pump(const Duration(milliseconds: 300));
    await openPopup(find.text('Nested entry'), buttons: kSecondaryButton);

    for (final label in [
      l10n.copy,
      l10n.aiRefineWithAi,
      l10n.newSiblingTopic,
      l10n.newChildTopic,
      l10n.renameTopicFile,
      l10n.cut,
      l10n.pasteAfterTopic,
      l10n.pasteAsChildTopic,
      l10n.removeTocElement,
      l10n.safeDeleteTopicFile,
      l10n.delete,
      l10n.copyName,
      l10n.copyPath,
      l10n.openInFiles,
      l10n.addToGit,
      l10n.fileHistory,
    ]) {
      expect(popupMenuItem(label), findsOneWidget);
    }

    await tester.tap(find.text(l10n.newChildTopic));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(l10n.insideSelectedTopic), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(BusyMarkEditorHeader),
        matching: find.widgetWithText(ElevatedButton, l10n.create),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      controller.createdTopicRequest!.placement,
      WritersideTopicCreatePlacement.child,
    );
    expect(controller.createdTopicRequest!.referenceTocPath, [0, 0]);
    expect(controller.createdTopicRequest!.referenceTopic, 'nested.md');
    expect(controller.createdTopicRequest!.referenceTocIdentity, isNotNull);

    await openPopup(find.text('Nested entry'), buttons: kSecondaryButton);
    await tester.tap(find.text(l10n.newSiblingTopic));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(l10n.afterSelectedTopic), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(BusyMarkEditorHeader),
        matching: find.widgetWithText(ElevatedButton, l10n.create),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      controller.createdTopicRequest!.placement,
      WritersideTopicCreatePlacement.sibling,
    );
    expect(controller.createdTopicRequest!.referenceTocPath, [0, 0]);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(find.byKey(const ValueKey('workspace-sidebar-toc-row-1')));
    await tester.tap(find.byKey(const ValueKey('workspace-sidebar-toc-row-2')));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    await openPopup(find.text('target.md'), buttons: kSecondaryButton);
    for (final label in [
      l10n.copy,
      l10n.cut,
      l10n.aiRefineWithAi,
      l10n.delete,
    ]) {
      expect(popupMenuItem(label), findsOneWidget);
    }
    expect(find.text(l10n.newSiblingTopic), findsNothing);
    expect(find.text(l10n.copyName), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(find.byKey(const ValueKey('workspace-sidebar-toc-row-1')));
    await tester.tap(find.byKey(const ValueKey('workspace-sidebar-toc-row-1')));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.tap(find.byKey(const ValueKey('workspace-sidebar-toc-row-2')));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    await openPopup(find.text('target.md'), buttons: kSecondaryButton);
    expect(find.text(l10n.aiRefineWithAi), findsOneWidget);
    expect(find.text(l10n.newSiblingTopic), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    await openPopup(find.text('Nested entry'), buttons: kSecondaryButton);

    await tester.tap(find.text(l10n.cut));
    await tester.pump(const Duration(milliseconds: 300));
    await openPopup(find.text('parent.md'), buttons: kSecondaryButton);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is BusyMarkPopupMenuItem<Object?> &&
            widget.label == l10n.pasteAfterTopic &&
            widget.enabled,
      ),
      findsOneWidget,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    File(
      p.join(root.path, 'topics', 'inserted.md'),
    ).writeAsStringSync('# Inserted\n');
    File(p.join(root.path, 'guide.tree')).writeAsStringSync('''
<instance-profile id="guide" name="Guide" start-page="nested.md">
  <toc-element topic="parent.md">
    <toc-element topic="inserted.md"/>
    <toc-element topic="nested.md" toc-title="Nested entry"/>
  </toc-element>
  <toc-element topic="loose.md"/>
  <toc-element topic="target.md"/>
</instance-profile>
''');
    final refreshedWorkspace = (await tester.runAsync(
      () => const WorkspaceService().openPath(root.path),
    ))!;
    controller.replaceWorkspace(refreshedWorkspace);
    await tester.pump(const Duration(milliseconds: 300));

    await openPopup(find.text('parent.md'), buttons: kSecondaryButton);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is BusyMarkPopupMenuItem<Object?> &&
            widget.label == l10n.pasteAfterTopic &&
            !widget.enabled,
      ),
      findsOneWidget,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await openPopup(find.text('loose.md'), buttons: kSecondaryButton);
    await tester.tap(find.text(l10n.cut));
    await tester.pump(const Duration(milliseconds: 300));
    await openPopup(find.text('target.md'), buttons: kSecondaryButton);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is BusyMarkPopupMenuItem<Object?> &&
            widget.label == l10n.pasteAsChildTopic &&
            widget.enabled,
      ),
      findsOneWidget,
    );
    await tester.tap(find.text(l10n.pasteAsChildTopic));
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      controller.movedTopicPlacement,
      WritersideTopicCreatePlacement.child,
    );
    expect(controller.movedTopicSourcePath, [1]);
    expect(controller.movedTopicReferencePath, [2]);
    expect(find.text('loose.md'), findsOneWidget);
    final movedRoots =
        controller.state.workspace!.writersideModule!.instances.first.tocRoots;
    final targetNode = movedRoots.singleWhere(
      (node) => node.topicFileName == 'target.md',
    );
    expect(targetNode.children.single.topicFileName, 'loose.md');

    await tester.tap(find.byTooltip(l10n.mainMenu));
    await tester.pumpAndSettle();
    final exportItem = find.byWidgetPredicate(
      (widget) =>
          widget is BusyMarkPopupMenuItem<Object?> &&
          widget.label == l10n.exportAsPdf,
    );
    expect(exportItem, findsOneWidget);
    expect(
      tester.widget<BusyMarkPopupMenuItem<Object?>>(exportItem).enabled,
      isTrue,
    );
    await tester.tap(exportItem);
    for (var index = 0; index < 20; index++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(BusyMarkModalEditorSurface).evaluate().isNotEmpty) {
        break;
      }
    }
    expect(find.byType(BusyMarkModalEditorSurface), findsOneWidget);
    expect(find.byType(BusyMarkModalEditorScaffold), findsOneWidget);
    expect(find.text(l10n.pdfPageSize), findsOneWidget);
    expect(find.text(l10n.pdfIncludePageNumbers), findsOneWidget);
    await tester.tap(find.text(l10n.cancel));
    await tester.pumpAndSettle();
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

    for (final (key, expectedMode)
        in <(LogicalKeyboardKey, DocumentViewModePreference)>[
          (LogicalKeyboardKey.digit3, DocumentViewModePreference.preview),
          (LogicalKeyboardKey.digit2, DocumentViewModePreference.source),
          (LogicalKeyboardKey.digit1, DocumentViewModePreference.editor),
          (LogicalKeyboardKey.digit4, DocumentViewModePreference.split),
        ]) {
      await pressControlShortcut(key, shift: true);
      expect(
        container.read(appSettingsControllerProvider).documentViewMode,
        expectedMode,
      );
    }

    final controller = container.read(workspaceControllerProvider.notifier);
    await controller.openActiveFile(second.path);
    await controller.openActiveFile(third.path);
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('LF'), findsOneWidget);
    expect(find.text('CRLF'), findsNothing);
    expect(
      find.ancestor(of: find.text('LF'), matching: find.byType(InkWell)),
      findsNothing,
    );
    expect(find.textContaining('UTF-8'), findsNothing);
    expect(find.textContaining('Final newline'), findsNothing);
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
    expect(service.saveCount, 0);
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

    expect(find.text(l10n.unsavedChanges), findsOneWidget);
    await tester.tap(find.text(l10n.discard));
    await tester.pumpAndSettle();

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
    await tester.pump(const Duration(milliseconds: 800));
  });

  testWidgets('Git diff files are shown as separate editor tabs', (
    tester,
  ) async {
    final temp = Directory.systemTemp.createTempSync('busymark_git_diff_tab_');
    addTearDown(() {
      temp.deleteSync(recursive: true);
    });
    final first = File('${temp.path}/current.md')..writeAsStringSync('# A\n');
    final readme = File('${temp.path}/README.md')
      ..writeAsStringSync('# Readme current\n');
    final service = _TabbedWorkspaceService(
      rootPath: temp.path,
      paths: [first.path, readme.path],
    );
    final gitController = _PresetGitController(_gitDiffState(temp.path));
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

    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(_MemorySettingsStore()),
        workspaceServiceProvider.overrideWithValue(service),
        startupPathProvider.overrideWithValue(temp.path),
        gitControllerProvider.overrideWith(() => gitController),
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
    for (var i = 0; i < 30; i += 1) {
      if (container.read(workspaceControllerProvider).workspace != null) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(container.read(workspaceControllerProvider).workspace, isNotNull);
    expect(find.text('current.md'), findsWidgets);
    expect(find.byTooltip(l10n.gitBehindCount(3)), findsNothing);
    expect(find.byTooltip(l10n.gitAheadCount(2)), findsNothing);
    expect(find.text('README.md'), findsWidgets);
    expect(find.text('guide.md'), findsOneWidget);
    expect(find.text(l10n.gitDiff), findsNothing);
    expect(
      find.textContaining('Readme change', findRichText: true),
      findsNothing,
    );
    expect(
      find.textContaining('Guide change', findRichText: true),
      findsWidgets,
    );

    await tester.tap(find.text('current.md').at(1));
    await tester.pump();

    expect(find.text('README.md'), findsWidgets);
    expect(find.text('guide.md'), findsOneWidget);
    expect(
      find.textContaining('Guide change', findRichText: true),
      findsNothing,
    );

    await tester.tap(find.text('guide.md'));
    await tester.pump();

    expect(
      find.textContaining('Guide change', findRichText: true),
      findsWidgets,
    );

    await pressControlShortcut(LogicalKeyboardKey.tab);
    expect(
      container.read(workspaceControllerProvider).workspace?.activeFilePath,
      first.path,
    );
    expect(
      container.read(gitControllerProvider).selectedCommitFilePath,
      isNull,
    );
    expect(
      find.textContaining('Guide change', findRichText: true),
      findsNothing,
    );

    await pressControlShortcut(LogicalKeyboardKey.tab);
    expect(
      container.read(gitControllerProvider).selectedCommitFilePath,
      'README.md',
    );
    expect(
      find.textContaining('Readme change', findRichText: true),
      findsWidgets,
    );

    await pressControlShortcut(LogicalKeyboardKey.tab, shift: true);
    expect(
      container.read(workspaceControllerProvider).workspace?.activeFilePath,
      first.path,
    );

    await pressControlShortcut(LogicalKeyboardKey.tab, shift: true);
    expect(
      container.read(gitControllerProvider).selectedCommitFilePath,
      'guide.md',
    );

    await pressControlShortcut(LogicalKeyboardKey.keyW);
    expect(container.read(gitControllerProvider).openDiffFilePaths, [
      'README.md',
    ]);
    expect(
      container.read(gitControllerProvider).selectedCommitFilePath,
      'README.md',
    );

    await pressControlShortcut(LogicalKeyboardKey.digit4);
    expect(find.text(l10n.gitUnstaged), findsOneWidget);
    expect(find.byTooltip(l10n.gitBehindCount(3)), findsOneWidget);
    expect(find.byTooltip(l10n.gitAheadCount(2)), findsOneWidget);

    container
        .read(workspaceControllerProvider.notifier)
        .updateActiveEditorMode(DocumentViewModePreference.preview);
    await container
        .read(appSettingsControllerProvider.notifier)
        .setDocumentViewMode(DocumentViewModePreference.preview);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(GitDiffViewer), findsNothing);
    expect(find.byType(BusyMarkReadOnlySourceLines), findsNothing);
    expect(find.byTooltip(l10n.gitOpenFile), findsNothing);
    expect(
      find.textContaining('# Readme change', findRichText: true),
      findsNothing,
    );
    expect(
      find.textContaining('# Readme old', findRichText: true),
      findsNothing,
    );
    expect(
      find.textContaining('@@ -1,1 +1,3 @@', findRichText: true),
      findsNothing,
    );
    expect(
      find.textContaining(
        'git checkout 30af618a6e962623a0098ad6a33b468f33dc49c7',
        findRichText: true,
      ),
      findsNothing,
    );
    expect(find.textContaining('Readme old', findRichText: true), findsWidgets);
    expect(
      find.textContaining('Readme change', findRichText: true),
      findsWidgets,
    );
    expect(
      find.textContaining('Unchanged context after change', findRichText: true),
      findsWidgets,
    );
    final codeSpan = _richTextSpanContaining(tester, 'echo added');
    expect(
      _textSpanStyleForText(codeSpan, 'echo before')?.backgroundColor,
      null,
    );
    expect(
      _textSpanStyleForText(codeSpan, 'echo added')?.backgroundColor,
      isNotNull,
    );
    expect(find.byTooltip(l10n.sourceSearchPreviousMatch), findsOneWidget);
    expect(find.byTooltip(l10n.sourceSearchNextMatch), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    container
        .read(workspaceControllerProvider.notifier)
        .updateActiveEditorMode(DocumentViewModePreference.editor);
    await container
        .read(appSettingsControllerProvider.notifier)
        .setDocumentViewMode(DocumentViewModePreference.editor);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(GitDiffViewer), findsNothing);
    expect(find.byType(BusyMarkReadOnlySourceLines), findsNothing);
    expect(find.byTooltip(l10n.gitOpenFile), findsNothing);
    expect(
      find.textContaining('# Readme change', findRichText: true),
      findsNothing,
    );
    expect(
      find.textContaining('# Readme old', findRichText: true),
      findsNothing,
    );
    expect(
      find.textContaining('@@ -1,1 +1,3 @@', findRichText: true),
      findsNothing,
    );
    expect(
      find.textContaining(
        'git checkout 30af618a6e962623a0098ad6a33b468f33dc49c7',
        findRichText: true,
      ),
      findsNothing,
    );
    expect(find.textContaining('Readme old', findRichText: true), findsWidgets);
    expect(
      find.textContaining('Readme change', findRichText: true),
      findsWidgets,
    );
    expect(
      find.textContaining('Unchanged context after change', findRichText: true),
      findsWidgets,
    );
    expect(find.byType(TextField), findsOneWidget);

    container
        .read(workspaceControllerProvider.notifier)
        .updateActiveEditorMode(DocumentViewModePreference.split);
    await container
        .read(appSettingsControllerProvider.notifier)
        .setDocumentViewMode(DocumentViewModePreference.split);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(GitDiffViewer), findsOneWidget);
    expect(find.byType(BusyMarkReadOnlySourceLines), findsOneWidget);
    expect(find.byTooltip(l10n.gitOpenFile), findsOneWidget);
    expect(
      find.textContaining('# Readme old', findRichText: true),
      findsWidgets,
    );
    expect(
      find.textContaining('# Readme change', findRichText: true),
      findsWidgets,
    );
    expect(
      find.textContaining('Readme old', findRichText: true),
      findsAtLeastNWidgets(2),
    );
    expect(
      find.textContaining('Readme change', findRichText: true),
      findsAtLeastNWidgets(2),
    );
    expect(
      find.textContaining('@@ -1,1 +1,3 @@', findRichText: true),
      findsNothing,
    );
    expect(
      find.textContaining(l10n.gitDiffHunkRange('1', '1'), findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'git checkout 30af618a6e962623a0098ad6a33b468f33dc49c7',
        findRichText: true,
      ),
      findsNothing,
    );
    expect(
      find.textContaining('Unchanged context after change', findRichText: true),
      findsWidgets,
    );
    expect(find.byTooltip(l10n.sourceSearchPreviousMatch), findsOneWidget);
    expect(find.byTooltip(l10n.sourceSearchNextMatch), findsOneWidget);

    container
        .read(workspaceControllerProvider.notifier)
        .updateActiveEditorMode(DocumentViewModePreference.source);
    await container
        .read(appSettingsControllerProvider.notifier)
        .setDocumentViewMode(DocumentViewModePreference.source);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(GitDiffViewer), findsOneWidget);
    expect(find.byType(BusyMarkReadOnlySourceLines), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byTooltip(l10n.gitOpenFile), findsOneWidget);
    expect(find.byTooltip(l10n.sourceSearchPreviousMatch), findsOneWidget);
    expect(find.byTooltip(l10n.sourceSearchNextMatch), findsOneWidget);
    expect(
      find.textContaining('# Readme change', findRichText: true),
      findsWidgets,
    );
    expect(
      find.textContaining('# Readme old', findRichText: true),
      findsWidgets,
    );
    expect(
      find.textContaining('@@ -1,1 +1,3 @@', findRichText: true),
      findsNothing,
    );
    expect(
      find.textContaining(
        'git checkout 30af618a6e962623a0098ad6a33b468f33dc49c7',
        findRichText: true,
      ),
      findsNothing,
    );
    expect(
      find.textContaining('Readme change', findRichText: true),
      findsWidgets,
    );
    expect(
      find.textContaining('Unchanged context after change', findRichText: true),
      findsWidgets,
    );

    final sourceDiffViewer = tester.widget<GitDiffViewer>(
      find.byType(GitDiffViewer),
    );
    expect(sourceDiffViewer.openFilePath, 'README.md');

    await tester.tap(find.byTooltip(l10n.gitOpenFile));
    await tester.pumpAndSettle();

    var workspace = container.read(workspaceControllerProvider).workspace!;
    var gitState = container.read(gitControllerProvider);
    expect(workspace.activeFilePath, readme.path);
    expect(workspace.openFilePaths.where((path) => path == readme.path), [
      readme.path,
    ]);
    expect(workspace.openFilePaths, containsAll([first.path, readme.path]));
    expect(gitState.openDiffFilePaths, ['README.md']);
    expect(gitState.selectedCommitFilePath, isNull);
    expect(find.byType(GitDiffViewer), findsNothing);
    expect(find.byTooltip(l10n.gitOpenFile), findsNothing);

    await container
        .read(gitControllerProvider.notifier)
        .activateDiffFile('README.md');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(GitDiffViewer), findsOneWidget);
    expect(find.byTooltip(l10n.gitOpenFile), findsOneWidget);

    await tester.tap(find.byTooltip(l10n.gitOpenFile));
    await tester.pumpAndSettle();

    workspace = container.read(workspaceControllerProvider).workspace!;
    gitState = container.read(gitControllerProvider);
    expect(workspace.activeFilePath, readme.path);
    expect(workspace.openFilePaths.where((path) => path == readme.path), [
      readme.path,
    ]);
    expect(gitState.openDiffFilePaths, ['README.md']);
    expect(gitState.selectedCommitFilePath, isNull);

    expect(find.byTooltip(temp.path), findsNothing);
    await pressControlShortcut(LogicalKeyboardKey.digit1);
    await tester.pumpAndSettle();

    expect(find.byTooltip(l10n.openInFiles), findsNothing);
    expect(find.byTooltip(temp.path), findsOneWidget);
    expect(find.byTooltip(l10n.pathActions), findsOneWidget);
    await tester.tap(find.byTooltip(temp.path));
    await tester.pumpAndSettle();
    expect(find.text(l10n.openInFiles), findsNothing);

    final pathMenuButton = find.descendant(
      of: find.byKey(const ValueKey('workspace-sidebar-path-menu')),
      matching: find.byType(IconButton),
    );
    expect(tester.widget<IconButton>(pathMenuButton).isSelected, isFalse);
    await tester.tap(find.byTooltip(l10n.pathActions));
    await tester.pumpAndSettle();
    expect(tester.widget<IconButton>(pathMenuButton).isSelected, isFalse);
    expect(find.text(l10n.copyName), findsOneWidget);
    expect(find.text(l10n.copyPath), findsOneWidget);
    expect(find.text(l10n.openInFiles), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(temp.path), buttons: kSecondaryMouseButton);
    await tester.pumpAndSettle();
    expect(find.text(l10n.copyName), findsOneWidget);
    expect(find.text(l10n.copyPath), findsOneWidget);
    expect(find.text(l10n.openInFiles), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    await tester.tap(
      find.text('README.md').first,
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.newFile), findsOneWidget);
    expect(find.text(l10n.rename), findsOneWidget);
    expect(find.text(l10n.cut), findsOneWidget);
    expect(find.text(l10n.paste), findsOneWidget);
    expect(find.text(l10n.delete), findsWidgets);
    expect(find.text(l10n.addToGit), findsOneWidget);
    expect(find.text(l10n.copyName), findsOneWidget);
    expect(find.text(l10n.copyPath), findsOneWidget);
    expect(find.text(l10n.openInFiles), findsOneWidget);
    expect(find.text(l10n.fileHistory), findsOneWidget);

    await tester.tap(find.text(l10n.addToGit));
    await tester.pumpAndSettle();

    expect(gitController.stagedPaths, ['README.md']);

    final readmeRow = find
        .ancestor(
          of: find.text('README.md').first,
          matching: find.byType(InkWell),
        )
        .first;
    final readmeActions = find.descendant(
      of: readmeRow,
      matching: find.byTooltip(l10n.actions),
    );
    expect(readmeActions, findsOneWidget);
    await tester.tap(readmeActions);
    await tester.pumpAndSettle();
    expect(find.text(l10n.fileHistory), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
    await tester.pumpAndSettle();
    expect(find.text(l10n.fileHistory), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    await tester.tap(
      find.text('README.md').first,
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.fileHistory));
    await tester.pumpAndSettle();

    gitState = container.read(gitControllerProvider);
    expect(gitController.loadedFileHistoryPath, readme.path);
    expect(gitState.selectedView, GitView.fileHistory);
    expect(gitState.historyFilePath, 'README.md');
    expect(find.byTooltip(l10n.back), findsNothing);
    expect(find.text('File history test commit'), findsOneWidget);

    await tester.tap(find.byTooltip(l10n.sidebarViewMenu));
    await tester.pumpAndSettle();
    expect(find.text(l10n.files), findsWidgets);
    await tester.tap(find.text(l10n.files).last);
    await tester.pumpAndSettle();

    expect(find.text('File history test commit'), findsNothing);
    expect(find.text('README.md'), findsWidgets);
  });

  testWidgets(
    'File History comparison selector shares its row with match navigation',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final temp = Directory.systemTemp.createTempSync(
        'busymark_git_history_selector_',
      );
      addTearDown(() {
        temp.deleteSync(recursive: true);
      });
      final readme = File('${temp.path}/README.md')
        ..writeAsStringSync('# Current\n');
      final service = _TabbedWorkspaceService(
        rootPath: temp.path,
        paths: [readme.path],
      );
      final gitController = _PresetGitController(
        _gitFileHistoryDiffState(temp.path),
      );
      final settingsStore = _MemorySettingsStore()
        ..value = AppSettings.defaults()
            .copyWith(documentViewMode: DocumentViewModePreference.split)
            .toJson();
      final container = ProviderContainer(
        overrides: [
          linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
          localSettingsStoreProvider.overrideWithValue(settingsStore),
          workspaceServiceProvider.overrideWithValue(service),
          startupPathProvider.overrideWithValue(temp.path),
          gitControllerProvider.overrideWith(() => gitController),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BusyMarkApp(),
        ),
      );
      for (var i = 0; i < 30; i += 1) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find
            .byKey(const ValueKey('git-history-comparison-selector'))
            .evaluate()
            .isNotEmpty) {
          break;
        }
      }

      final selector = find.byKey(
        const ValueKey('git-history-comparison-selector'),
      );
      final previous = find.byTooltip(l10n.sourceSearchPreviousMatch);
      final next = find.byTooltip(l10n.sourceSearchNextMatch);
      expect(selector, findsOneWidget);
      expect(previous, findsOneWidget);
      expect(next, findsOneWidget);
      expect(
        (tester.getCenter(selector).dy - tester.getCenter(previous).dy).abs(),
        lessThan(1),
      );
      expect(find.text(l10n.gitChangesInCommit), findsOneWidget);

      await tester.tap(selector);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.gitCompareWithCurrent));
      await tester.pumpAndSettle();

      expect(gitController.compareWithCurrentCount, 1);
      expect(find.text(l10n.gitCompareWithCurrent), findsOneWidget);

      await tester.tap(selector);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.gitChangesInCommit));
      await tester.pumpAndSettle();

      expect(gitController.commitComparisonCount, 1);
      expect(find.text(l10n.gitChangesInCommit), findsOneWidget);
    },
  );

  testWidgets('file tree disables Git file actions without a repository', (
    tester,
  ) async {
    final temp = Directory.systemTemp.createTempSync(
      'busymark_no_git_file_menu_',
    );
    addTearDown(() {
      temp.deleteSync(recursive: true);
    });
    final readme = File('${temp.path}/README.md')..writeAsStringSync('# A\n');
    final service = _TabbedWorkspaceService(
      rootPath: temp.path,
      paths: [readme.path],
    );
    final gitController = _PresetGitController(
      const GitState(
        availability: GitAvailability(
          available: true,
          executablePath: '/usr/bin/git',
          version: '2.50.0',
        ),
      ),
    );
    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(_MemorySettingsStore()),
        workspaceServiceProvider.overrideWithValue(service),
        startupPathProvider.overrideWithValue(temp.path),
        gitControllerProvider.overrideWith(() => gitController),
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
    for (var i = 0; i < 30; i += 1) {
      if (container.read(workspaceControllerProvider).workspace != null) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();

    await tester.tap(
      find.text('README.md').first,
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.addToGit), findsOneWidget);
    expect(find.text(l10n.fileHistory), findsOneWidget);

    await tester.tap(find.text(l10n.fileHistory));
    await tester.pumpAndSettle();

    expect(gitController.loadedFileHistoryPath, isNull);
    expect(gitController.stagedPaths, isEmpty);
    expect(find.text(l10n.fileHistory), findsOneWidget);
  });

  testWidgets('sidebar view shortcuts select workspace sidebar tabs', (
    tester,
  ) async {
    String? clipboardText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          final arguments = call.arguments as Map<Object?, Object?>;
          clipboardText = arguments['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });
    final temp = Directory.systemTemp.createTempSync('busymark_sidebar_keys_');
    addTearDown(() {
      temp.deleteSync(recursive: true);
    });
    final first = File('${temp.path}/Intro.md')..writeAsStringSync('# Intro\n');
    final second = File('${temp.path}/Api.md')..writeAsStringSync('# API\n');
    final service = _TabbedWorkspaceService(
      rootPath: temp.path,
      paths: [first.path, second.path],
    );
    final gitController = _PresetGitController(
      _gitSidebarShortcutState(temp.path),
    );
    final settingsStore = _MemorySettingsStore()
      ..value = AppSettings.defaults()
          .copyWith(documentViewMode: DocumentViewModePreference.editor)
          .toJson();
    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(settingsStore),
        workspaceServiceProvider.overrideWithValue(service),
        startupPathProvider.overrideWithValue(temp.path),
        gitControllerProvider.overrideWith(() => gitController),
      ],
    );
    addTearDown(container.dispose);

    Future<void> pressControlShortcut(LogicalKeyboardKey key) async {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(key);
      await tester.sendKeyUpEvent(key);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
    }

    Future<void> setDocumentViewMode(
      DocumentViewModePreference expectedMode,
    ) async {
      await container
          .read(appSettingsControllerProvider.notifier)
          .setDocumentViewMode(expectedMode);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        container.read(appSettingsControllerProvider).documentViewMode,
        expectedMode,
      );
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
    await tester.pumpAndSettle();

    expect(find.text('Api.md'), findsOneWidget);

    expect(
      find.byTooltip(
        '${l10n.hideSidebar} (${BusyMarkSidebarShortcutLabels.toggleSidebar})',
      ),
      findsOneWidget,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.f9);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byTooltip(l10n.sidebarViewMenu), findsNothing);
    expect(
      find.byTooltip(
        '${l10n.showSidebar} (${BusyMarkSidebarShortcutLabels.toggleSidebar})',
      ),
      findsOneWidget,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.f9);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byTooltip(l10n.sidebarViewMenu), findsOneWidget);

    final activeEditorField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.controller?.text.contains('Intro.md') == true,
    );
    expect(activeEditorField, findsOneWidget);
    await tester.tap(activeEditorField);
    await tester.pump();
    expect(
      tester.widget<TextField>(activeEditorField).focusNode?.hasFocus,
      isTrue,
      reason: 'The shortcut must work while the document field owns focus.',
    );

    await setDocumentViewMode(DocumentViewModePreference.source);
    await pressControlShortcut(LogicalKeyboardKey.digit1);
    expect(find.text('Api.md'), findsOneWidget);
    expect(find.byTooltip(l10n.sidebarViewMenu), findsOneWidget);
    expect(find.byTooltip(temp.path), findsOneWidget);
    expect(find.byTooltip(l10n.gitActions), findsNothing);

    await setDocumentViewMode(DocumentViewModePreference.preview);
    await pressControlShortcut(LogicalKeyboardKey.digit4);
    expect(find.text(l10n.gitNoChanges), findsOneWidget);
    expect(find.byTooltip(temp.path), findsNothing);
    expect(find.byTooltip(l10n.gitActions), findsOneWidget);
    final branchRow = find.byKey(
      const ValueKey('workspace-sidebar-first-content'),
    );
    final branchGlyph = find.descendant(
      of: branchRow,
      matching: find.byIcon(BusyMarkGlyphs.branch),
    );
    expect(branchGlyph, findsOneWidget);
    final branchGlyphContext = tester.element(branchGlyph);
    final branchIcon = tester.widget<Icon>(branchGlyph);
    expect(branchIcon.color, Theme.of(branchGlyphContext).colorScheme.primary);
    expect(
      branchIcon.size,
      MediaQuery.textScalerOf(branchGlyphContext).scale(
        Theme.of(branchGlyphContext).textTheme.bodySmall?.fontSize ??
            BusyMarkSizes.iconSm,
      ),
    );
    final branchMenu = find.byKey(
      const ValueKey('workspace-sidebar-branch-menu'),
    );
    expect(branchMenu, findsOneWidget);
    expect(
      find.descendant(
        of: branchMenu,
        matching: find.byIcon(BusyMarkGlyphs.menuVertical),
      ),
      findsOneWidget,
    );
    final branchMenuButton = find.descendant(
      of: branchMenu,
      matching: find.byType(IconButton),
    );
    expect(tester.widget<IconButton>(branchMenuButton).isSelected, isFalse);
    expect(gitController.branchLoadCount, 0);
    await tester.tap(branchMenu);
    await tester.pumpAndSettle();
    expect(tester.widget<IconButton>(branchMenuButton).isSelected, isFalse);
    expect(gitController.branchLoadCount, 1);
    expect(find.text(l10n.gitPull), findsOneWidget);
    expect(find.text(l10n.gitPush), findsOneWidget);
    expect(find.text(l10n.gitFetch), findsOneWidget);
    expect(find.text(l10n.gitNewBranch), findsOneWidget);
    expect(l10n.gitNewBranch, isNot(startsWith('+')));
    expect(find.text(l10n.gitChanges), findsOneWidget);
    expect(find.text(l10n.gitProjectHistory), findsOneWidget);
    expect(find.text(l10n.gitFileHistory), findsOneWidget);
    expect(find.byIcon(BusyMarkGlyphs.refresh), findsOneWidget);
    expect(find.byIcon(BusyMarkGlyphs.add), findsOneWidget);
    expect(find.byType(PopupMenuDivider), findsNWidgets(3));

    await tester.tap(find.text(l10n.gitProjectHistory));
    await tester.pumpAndSettle();
    expect(
      container.read(gitControllerProvider).selectedView,
      GitView.projectHistory,
    );
    expect(find.text('Sidebar history shortcut commit'), findsOneWidget);

    await setDocumentViewMode(DocumentViewModePreference.split);
    await pressControlShortcut(LogicalKeyboardKey.digit4);
    expect(find.text(l10n.gitNoChanges), findsOneWidget);
    expect(find.text('Sidebar history shortcut commit'), findsNothing);
    expect(container.read(gitControllerProvider).selectedView, GitView.changes);
    expect(find.byTooltip(temp.path), findsNothing);
    expect(find.byTooltip(l10n.gitActions), findsOneWidget);
    expect(branchMenu, findsOneWidget);

    await setDocumentViewMode(DocumentViewModePreference.editor);
    await pressControlShortcut(LogicalKeyboardKey.digit3);
    expect(find.text(l10n.gitNoChanges), findsNothing);
    expect(find.text('Sidebar history shortcut commit'), findsNothing);
    expect(find.text('Intro.md'), findsWidgets);
    expect(find.byTooltip(temp.path), findsNothing);
    expect(find.byTooltip(l10n.gitActions), findsNothing);
    final outlineFileMenu = find.byKey(
      const ValueKey('workspace-sidebar-outline-file-menu'),
    );
    expect(outlineFileMenu, findsOneWidget);
    expect(find.byTooltip(first.path), findsOneWidget);
    final outlineFileActions = find.descendant(
      of: outlineFileMenu,
      matching: find.byTooltip(l10n.actions),
    );
    expect(outlineFileActions, findsOneWidget);

    await tester.tap(outlineFileActions);
    await tester.pumpAndSettle();
    expect(find.text(l10n.copyFileName), findsOneWidget);
    expect(find.text(l10n.copyPath), findsOneWidget);
    expect(find.text(l10n.openInFiles), findsOneWidget);
    expect(find.text(l10n.aiRefineWithAi), findsOneWidget);

    await tester.tap(find.text(l10n.copyFileName));
    await tester.pumpAndSettle();
    expect(clipboardText, 'Intro.md');

    await tester.tap(outlineFileActions);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.copyPath));
    await tester.pumpAndSettle();
    expect(clipboardText, first.path);

    await tester.tap(find.byTooltip(l10n.sidebarViewMenu));
    await tester.pumpAndSettle();

    for (final (label, shortcut) in <(String, String)>[
      (l10n.files, BusyMarkSidebarShortcutLabels.files),
      (l10n.outline, BusyMarkSidebarShortcutLabels.outline),
      (l10n.git, BusyMarkSidebarShortcutLabels.git),
    ]) {
      expect(find.text(label), findsOneWidget);
      expect(find.text(shortcut), findsOneWidget);
      expect(find.byTooltip('$label ($shortcut)'), findsNothing);
    }
    expect(find.text(l10n.gitChanges), findsNothing);
    expect(find.text(l10n.gitFileHistory), findsNothing);
    expect(find.text(l10n.gitProjectHistory), findsNothing);
  });

  testWidgets('Writerside sidebar shortcuts survive document view changes', (
    tester,
  ) async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.defaultRouteNameTestValue = '/workspace';
    addTearDown(() {
      binding.platformDispatcher.defaultRouteNameTestValue = '/';
    });
    final root = Directory('test/fixtures/writerside/basic_project').absolute;
    final workspace = (await tester.runAsync(
      () => const WorkspaceService().openPath(root.path),
    ))!;
    final controller = _MutableWorkspaceController(
      WorkspaceState(
        workspace: workspace,
        activeText: workspace.markdown?.source ?? '',
      ),
    );
    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(_MemorySettingsStore()),
        workspaceControllerProvider.overrideWith(() => controller),
        gitControllerProvider.overrideWith(
          () => _PresetGitController(
            _gitSidebarShortcutState(workspace.rootPath),
          ),
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
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('workspace-sidebar-primary-label')),
        matching: find.text('BusyMark Test'),
      ),
      findsOneWidget,
    );

    Future<void> selectView(LogicalKeyboardKey key) async {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(key);
      await tester.sendKeyUpEvent(key);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
    }

    Future<void> setDocumentViewMode(
      DocumentViewModePreference expectedMode,
    ) async {
      await container
          .read(appSettingsControllerProvider.notifier)
          .setDocumentViewMode(expectedMode);
      await tester.pumpAndSettle();
      expect(
        container.read(appSettingsControllerProvider).documentViewMode,
        expectedMode,
      );
    }

    await setDocumentViewMode(DocumentViewModePreference.source);
    final activeDocumentField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.controller?.text.contains('# Introduction') == true,
    );
    expect(activeDocumentField, findsOneWidget);
    await tester.tap(activeDocumentField);
    await tester.pump();

    final primaryRow = find.byKey(
      const ValueKey('workspace-sidebar-primary-row'),
    );
    const firstContentKey = ValueKey('workspace-sidebar-first-content');
    Finder viewMarker(LogicalKeyboardKey key) {
      return switch (key) {
        LogicalKeyboardKey.digit1 => find.byKey(
          const ValueKey('workspace-sidebar-path-menu'),
        ),
        LogicalKeyboardKey.digit2 => find.byTooltip(l10n.tocActions),
        LogicalKeyboardKey.digit3 => find.byKey(
          const ValueKey('workspace-sidebar-outline-tree'),
        ),
        LogicalKeyboardKey.digit4 => find.text(l10n.gitNoChanges),
        _ => throw ArgumentError.value(key, 'key'),
      };
    }

    Finder? actionMenuMarker(LogicalKeyboardKey key) {
      if (key == LogicalKeyboardKey.digit1) {
        return find.byKey(const ValueKey('workspace-sidebar-path-menu'));
      }
      if (key == LogicalKeyboardKey.digit2) {
        return find.byKey(const ValueKey('workspace-sidebar-toc-menu'));
      }
      if (key == LogicalKeyboardKey.digit3) {
        return find.byKey(
          const ValueKey('workspace-sidebar-outline-file-menu'),
        );
      }
      if (key == LogicalKeyboardKey.digit4) {
        return find.byKey(const ValueKey('workspace-sidebar-branch-menu'));
      }
      return null;
    }

    final actionMenuGuideRight = tester.getRect(primaryRow).right;
    double? actionMenuRight;
    for (final (key, label, contextRow, expectedDocumentView)
        in <(LogicalKeyboardKey, String, bool, DocumentViewModePreference)>[
          (
            LogicalKeyboardKey.digit1,
            'Files',
            true,
            DocumentViewModePreference.source,
          ),
          (
            LogicalKeyboardKey.digit2,
            'Topics',
            true,
            DocumentViewModePreference.preview,
          ),
          (
            LogicalKeyboardKey.digit3,
            'Outline',
            true,
            DocumentViewModePreference.split,
          ),
          (
            LogicalKeyboardKey.digit4,
            'Git',
            true,
            DocumentViewModePreference.editor,
          ),
        ]) {
      await setDocumentViewMode(expectedDocumentView);
      await selectView(key);
      expect(viewMarker(key), findsOneWidget, reason: '$label selected view');
      final firstContent = find.byKey(firstContentKey);
      expect(firstContent, findsOneWidget, reason: label);
      final gap =
          tester.getTopLeft(firstContent).dy -
          tester.getBottomLeft(primaryRow).dy;
      expect(
        gap,
        closeTo(BusyMarkSpacing.sm, 0.01),
        reason: '$label sidebar gap',
      );
      final actionMenu = actionMenuMarker(key);
      if (actionMenu != null) {
        final right = tester.getRect(actionMenu).right;
        actionMenuRight ??= right;
        expect(
          right,
          closeTo(actionMenuRight, 0.01),
          reason: '$label action menu trailing edge',
        );
        expect(
          right,
          closeTo(actionMenuGuideRight, 0.01),
          reason: '$label action menu header alignment',
        );
      }
      if (contextRow) {
        expect(
          tester.getSize(firstContent).height,
          greaterThanOrEqualTo(BusyMarkSizes.iconButton),
          reason: '$label sidebar context row height',
        );
      }
    }

    await selectView(LogicalKeyboardKey.digit2);
    final selectedTopicActions = find.byTooltip(l10n.actions);
    expect(selectedTopicActions, findsOneWidget);
    await tester.tap(selectedTopicActions);
    await tester.pumpAndSettle();
    expect(find.text(l10n.newSiblingTopic), findsOneWidget);
    expect(find.text(l10n.copyPath), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
    await tester.pumpAndSettle();
    expect(find.text(l10n.newSiblingTopic), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
  });

  testWidgets('Files view colors entries by Git status', (tester) async {
    final temp = Directory.systemTemp.createTempSync('busymark_file_vcs_');
    addTearDown(() {
      temp.deleteSync(recursive: true);
    });
    final docs = Directory('${temp.path}/docs')..createSync();
    final readme = File('${temp.path}/README.md')..writeAsStringSync('# R\n');
    final api = File('${docs.path}/api.md')..writeAsStringSync('# API\n');
    final draft = File('${temp.path}/draft.md')..writeAsStringSync('# D\n');
    final repository = GitRepositoryInfo(
      rootPath: temp.path,
      gitDirPath: '${temp.path}/.git',
      currentBranch: 'main',
    );
    final service = _TabbedWorkspaceService(
      rootPath: temp.path,
      paths: [readme.path, api.path, draft.path],
    );
    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(_MemorySettingsStore()),
        workspaceServiceProvider.overrideWithValue(service),
        startupPathProvider.overrideWithValue(temp.path),
        gitControllerProvider.overrideWith(
          () => _PresetGitController(
            GitState(
              availability: const GitAvailability(
                available: true,
                executablePath: '/usr/bin/git',
                version: '2.50.0',
              ),
              repositoryInfo: repository,
              statusSnapshot: GitStatusSnapshot(
                repositoryInfo: repository,
                files: [
                  _gitStatusFile(
                    repository,
                    'README.md',
                    category: GitFileStatusCategory.modified,
                  ),
                  _gitStatusFile(
                    repository,
                    'docs/api.md',
                    category: GitFileStatusCategory.added,
                    indexStatus: GitFileChangeStatus.added,
                    staged: true,
                    unstaged: false,
                  ),
                  _gitStatusFile(
                    repository,
                    'draft.md',
                    category: GitFileStatusCategory.untracked,
                    indexStatus: GitFileChangeStatus.untracked,
                    workTreeStatus: GitFileChangeStatus.untracked,
                    untracked: true,
                  ),
                ],
              ),
            ),
          ),
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
    for (var i = 0; i < 30; i += 1) {
      if (container.read(workspaceControllerProvider).workspace != null) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();

    _expectTextWithVcsColor(tester, 'README.md', BusyMarkVcsFileColor.modified);
    _expectTextWithVcsColor(tester, 'docs', BusyMarkVcsFileColor.added);
    _expectTextWithVcsColor(tester, 'api.md', BusyMarkVcsFileColor.added);
    _expectTextWithVcsColor(tester, 'draft.md', BusyMarkVcsFileColor.untracked);
  });

  testWidgets('Files view shows hidden, empty, and unsupported entries', (
    tester,
  ) async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.defaultRouteNameTestValue = '/workspace';
    addTearDown(() {
      binding.platformDispatcher.defaultRouteNameTestValue = '/';
    });
    final temp = Directory.systemTemp.createTempSync('busymark_files_all_');
    addTearDown(() {
      temp.deleteSync(recursive: true);
    });
    File('${temp.path}/README.md').writeAsStringSync('# Readme\n');
    File('${temp.path}/binary.bin').writeAsBytesSync([0, 1, 2]);
    Directory('${temp.path}/empty').createSync();
    final idea = Directory('${temp.path}/.idea')..createSync();
    File('${idea.path}/.gitignore').writeAsStringSync('/workspace.xml\n');
    final openedWorkspace = (await tester.runAsync(
      () => const WorkspaceService().openPath(temp.path),
    ))!;
    final controller = _MutableWorkspaceController(
      WorkspaceState(workspace: openedWorkspace, activeText: '# Readme\n'),
    );
    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(_MemorySettingsStore()),
        workspaceControllerProvider.overrideWith(() => controller),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BusyMarkApp(),
      ),
    );
    for (var i = 0; i < 10; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(find.byTooltip(l10n.sidebarViewMenu));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.files));
    await tester.pump(const Duration(milliseconds: 300));

    final workspace = container.read(workspaceControllerProvider).workspace!;
    expect(
      workspace.directories.map((directory) => directory.relativePath),
      containsAll(['.idea', 'empty']),
    );
    expect(
      workspace.files.map((file) => file.relativePath),
      containsAll(['README.md', 'binary.bin', '.idea/.gitignore']),
    );
    expect(find.text('.idea'), findsOneWidget);
    expect(find.text('empty'), findsOneWidget);
    expect(find.text('binary.bin'), findsOneWidget);
    final binaryRow = tester.widget<InkWell>(
      find
          .ancestor(of: find.text('binary.bin'), matching: find.byType(InkWell))
          .first,
    );
    expect(binaryRow.onTap, isNull);

    expect(find.text('.gitignore'), findsOneWidget);
    final gitIgnoreRow = tester.widget<InkWell>(
      find
          .ancestor(of: find.text('.gitignore'), matching: find.byType(InkWell))
          .first,
    );
    expect(gitIgnoreRow.onTap, isNotNull);
  });

  testWidgets('workspace sidebar is on the right in Arabic', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final temp = Directory.systemTemp.createTempSync('busymark_sidebar_rtl_');
    addTearDown(() {
      temp.deleteSync(recursive: true);
    });
    final ar = AppLocalizationsAr();
    final file = File('${temp.path}/Intro.md')..writeAsStringSync('# Intro\n');
    final service = _TabbedWorkspaceService(
      rootPath: temp.path,
      paths: [file.path],
    );
    final settingsStore = _MemorySettingsStore()
      ..value = AppSettings.defaults()
          .copyWith(
            localeTag: 'ar',
            documentViewMode: DocumentViewModePreference.source,
          )
          .toJson();
    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(settingsStore),
        workspaceServiceProvider.overrideWithValue(service),
        startupPathProvider.overrideWithValue(temp.path),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BusyMarkApp(),
      ),
    );
    for (var i = 0; i < 30; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (container.read(workspaceControllerProvider).workspace != null &&
          find.byType(TextField).evaluate().isNotEmpty) {
        break;
      }
    }
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    final sidebarRect = tester.getRect(find.byTooltip(ar.sidebarViewMenu));
    final sourceRect = tester.getRect(find.byType(TextField).last);
    final scaffold = find.byType(Scaffold).last;
    final resolvedHeaderPadding = BusyMarkInsets.sidebarHeader.resolve(
      TextDirection.rtl,
    );

    expect(Directionality.of(tester.element(scaffold)), TextDirection.rtl);
    expect(sidebarRect.left, greaterThan(sourceRect.right));
    expect(resolvedHeaderPadding.right, BusyMarkSpacing.mdPlus);
    expect(resolvedHeaderPadding.left, BusyMarkSpacing.sm);
  });

  testWidgets('workspace sidebar is on the right in Persian', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final temp = Directory.systemTemp.createTempSync('busymark_sidebar_fa_');
    addTearDown(() {
      temp.deleteSync(recursive: true);
    });
    final fa = AppLocalizationsFa();
    final file = File('${temp.path}/Intro.md')..writeAsStringSync('# Intro\n');
    final service = _TabbedWorkspaceService(
      rootPath: temp.path,
      paths: [file.path],
    );
    final settingsStore = _MemorySettingsStore()
      ..value = AppSettings.defaults()
          .copyWith(
            localeTag: 'fa',
            documentViewMode: DocumentViewModePreference.source,
          )
          .toJson();
    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(settingsStore),
        workspaceServiceProvider.overrideWithValue(service),
        startupPathProvider.overrideWithValue(temp.path),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BusyMarkApp(),
      ),
    );
    for (var i = 0; i < 30; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (container.read(workspaceControllerProvider).workspace != null &&
          find.byType(TextField).evaluate().isNotEmpty) {
        break;
      }
    }
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    final sidebarRect = tester.getRect(find.byTooltip(fa.sidebarViewMenu));
    final sourceField = tester.widget<TextField>(find.byType(TextField).last);
    final sourceRect = tester.getRect(find.byType(TextField).last);
    final scaffold = find.byType(Scaffold).last;

    expect(Directionality.of(tester.element(scaffold)), TextDirection.rtl);
    expect(sidebarRect.left, greaterThan(sourceRect.right));
    expect(sourceField.textDirection, TextDirection.ltr);
  });

  testWidgets(
    'Arabic untitled workspace stays RTL and diagnostic metadata stays LTR',
    (tester) async {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.defaultRouteNameTestValue = '/workspace';
      addTearDown(() {
        binding.platformDispatcher.defaultRouteNameTestValue = '/';
      });
      final ar = AppLocalizationsAr();
      const diagnosticPath = '/tmp/topic-مقدمة.md';
      const diagnostic = Diagnostic(
        code: 'markdown.front-matter.malformed',
        severity: DiagnosticSeverity.warning,
        filePath: diagnosticPath,
        sourceSpan: SourceSpan(
          filePath: diagnosticPath,
          startOffset: 0,
          endOffset: 1,
          startLine: 12,
          startColumn: 4,
          endLine: 12,
          endColumn: 5,
        ),
      );
      final workspace = const WorkspaceService()
          .createUntitledMarkdown(source: '# عنوان\n')
          .copyWith(diagnostics: const [diagnostic]);
      final controller = _MutableWorkspaceController(
        WorkspaceState(workspace: workspace, activeText: '# عنوان\n'),
      );
      final settingsStore = _MemorySettingsStore()
        ..value = AppSettings.defaults()
            .copyWith(
              localeTag: 'ar',
              documentViewMode: DocumentViewModePreference.source,
            )
            .toJson();
      final container = ProviderContainer(
        overrides: [
          linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
          localSettingsStoreProvider.overrideWithValue(settingsStore),
          workspaceControllerProvider.overrideWith(() => controller),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BusyMarkApp(),
        ),
      );
      await tester.pumpAndSettle();

      final projectName = find.descendant(
        of: find.byKey(const ValueKey('workspace-sidebar-primary-label')),
        matching: find.text(ar.untitledMarkdownFileName),
      );
      final outlineTitle = find.descendant(
        of: find.byKey(const ValueKey('workspace-sidebar-outline-tree')),
        matching: find.text('عنوان'),
      );
      expect(projectName, findsOneWidget);
      expect(outlineTitle, findsOneWidget);
      expect(Directionality.of(tester.element(projectName)), TextDirection.rtl);
      expect(
        Directionality.of(tester.element(outlineTitle)),
        TextDirection.rtl,
      );

      await tester.tap(find.byTooltip(ar.validate));
      await tester.pumpAndSettle();

      const metadata = 'markdown.front-matter.malformed - topic-مقدمة.md 12:4';
      final metadataFinder = find.text(metadata);
      expect(metadataFinder, findsOneWidget);
      expect(
        tester.widget<Text>(metadataFinder).textDirection,
        TextDirection.ltr,
      );
    },
  );

  testWidgets('RTL topic copy keeps bidi controls out of clipboard data', (
    tester,
  ) async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.defaultRouteNameTestValue = '/workspace';
    addTearDown(() {
      binding.platformDispatcher.defaultRouteNameTestValue = '/';
    });
    String? clipboardText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          final arguments = call.arguments as Map<Object?, Object?>;
          clipboardText = arguments['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });
    final root = Directory.systemTemp.createTempSync(
      'busymark-rtl-topic-copy-',
    );
    addTearDown(() {
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
    });
    Directory(p.join(root.path, 'topics')).createSync();
    File(p.join(root.path, 'writerside.cfg')).writeAsStringSync('''
<ihp version="2.0">
  <topics dir="topics"/>
  <instance src="guide.tree"/>
</ihp>
''');
    File(p.join(root.path, 'guide.tree')).writeAsStringSync('''
<instance-profile id="guide" name="Guide" start-page="start.md">
  <toc-element topic="start.md"/>
  <toc-element href="https://example.com/docs"/>
</instance-profile>
''');
    File(
      p.join(root.path, 'topics', 'start.md'),
    ).writeAsStringSync('# Start\n');
    final workspace = (await tester.runAsync(
      () => const WorkspaceService().openPath(root.path),
    ))!;
    final controller = _MutableWorkspaceController(
      WorkspaceState(workspace: workspace, activeText: '# Start\n'),
    );
    final settingsStore = _MemorySettingsStore()
      ..value = AppSettings.defaults().copyWith(localeTag: 'ar').toJson();
    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(settingsStore),
        workspaceControllerProvider.overrideWith(() => controller),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BusyMarkApp(),
      ),
    );
    await tester.pumpAndSettle();
    final ar = AppLocalizationsAr();
    await tester.tap(find.byTooltip(ar.sidebarViewMenu));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ar.toc));
    await tester.pumpAndSettle();

    const href = 'https://example.com/docs';
    final hrefRow = find.textContaining(href);
    expect(hrefRow, findsOneWidget);
    final rendered = tester.widget<Text>(hrefRow).data!;
    expect('\u2066'.allMatches(rendered), hasLength(1));
    expect('\u2069'.allMatches(rendered), hasLength(1));

    await tester.tap(hrefRow, buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text(ar.copyName));
    await tester.pumpAndSettle();

    expect(clipboardText, href);
    expect(clipboardText, isNot(contains(RegExp('[\u2066-\u2069]'))));
  });

  testWidgets('source undo cannot restore saved text from previous tab', (
    tester,
  ) async {
    final temp = Directory.systemTemp.createTempSync('busymark_source_undo_');
    addTearDown(() {
      temp.deleteSync(recursive: true);
    });
    final first = File('${temp.path}/Introduction.md')
      ..writeAsStringSync('# Introduction\n');
    final second = File('${temp.path}/System-Design.md')
      ..writeAsStringSync('# System Design\n');
    final service = _TabbedWorkspaceService(
      rootPath: temp.path,
      paths: [first.path, second.path],
    );
    final settingsStore = _MemorySettingsStore()
      ..value = AppSettings.defaults()
          .copyWith(documentViewMode: DocumentViewModePreference.source)
          .toJson();
    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(settingsStore),
        workspaceServiceProvider.overrideWithValue(service),
        startupPathProvider.overrideWithValue(temp.path),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BusyMarkApp(),
      ),
    );
    for (var i = 0; i < 30; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (container.read(workspaceControllerProvider).workspace != null) {
        break;
      }
    }
    expect(container.read(workspaceControllerProvider).workspace, isNotNull);
    await container
        .read(appSettingsControllerProvider.notifier)
        .setDocumentViewMode(DocumentViewModePreference.source);
    for (var i = 0; i < 10; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(TextField).evaluate().isNotEmpty) {
        break;
      }
    }

    final sourceField = find.descendant(
      of: find.byType(BusyMarkSourceEditor),
      matching: find.byType(TextField),
    );
    expect(
      tester.widget<TextField>(sourceField).controller?.text,
      '# Introduction.md\n',
    );
    await tester.tap(sourceField);
    await tester.enterText(sourceField, '# Edited Introduction\n');
    await tester.pump();

    expect(
      container.read(workspaceControllerProvider).activeText,
      '# Edited Introduction\n',
    );

    final controller = container.read(workspaceControllerProvider.notifier);
    expect(await controller.saveActive(), isTrue);
    await tester.pump();

    expect(service.saveCount, 1);
    expect(service.savedPath, first.path);
    expect(service.savedText, '# Edited Introduction\n');

    await controller.openActiveFile(second.path);
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      container.read(workspaceControllerProvider).activeText,
      '# System-Design.md\n',
    );
    expect(
      tester.widget<TextField>(sourceField).controller?.text,
      '# System-Design.md\n',
    );

    await tester.tap(sourceField);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      container.read(workspaceControllerProvider).activeText,
      '# System-Design.md\n',
    );
    expect(
      tester.widget<TextField>(sourceField).controller?.text,
      '# System-Design.md\n',
    );
    expect(service.savedPath, first.path);
    expect(service.savedText, '# Edited Introduction\n');
  });

  testWidgets('source view supports editor formatting shortcuts', (
    tester,
  ) async {
    final temp = Directory.systemTemp.createTempSync('busymark_source_keys_');
    addTearDown(() {
      temp.deleteSync(recursive: true);
    });
    final file = File('${temp.path}/Intro.md')..writeAsStringSync('alpha');
    final service = _TabbedWorkspaceService(
      rootPath: temp.path,
      paths: [file.path],
    );
    final settingsStore = _MemorySettingsStore()
      ..value = AppSettings.defaults()
          .copyWith(
            documentViewMode: DocumentViewModePreference.source,
            localeTag: 'de',
          )
          .toJson();
    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(settingsStore),
        workspaceServiceProvider.overrideWithValue(service),
        startupPathProvider.overrideWithValue(temp.path),
      ],
    );
    addTearDown(container.dispose);

    Future<void> pressShortcut(
      LogicalKeyboardKey key, {
      bool control = false,
      bool alt = false,
      bool shift = false,
    }) async {
      if (control) {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      }
      if (alt) {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      }
      if (shift) {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      }
      await tester.sendKeyDownEvent(key);
      await tester.sendKeyUpEvent(key);
      if (shift) {
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      }
      if (alt) {
        await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      }
      if (control) {
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      }
      await tester.pump(const Duration(milliseconds: 100));
    }

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BusyMarkApp(),
      ),
    );
    for (var i = 0; i < 30; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (container.read(workspaceControllerProvider).workspace != null) {
        break;
      }
    }
    await container
        .read(appSettingsControllerProvider.notifier)
        .setDocumentViewMode(DocumentViewModePreference.source);
    for (var i = 0; i < 10; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(TextField).evaluate().isNotEmpty) {
        break;
      }
    }

    final sourceField = find.byType(TextField).last;
    await tester.tap(sourceField);
    await tester.enterText(sourceField, 'alpha');
    await tester.pump();

    await pressShortcut(LogicalKeyboardKey.keyQ, control: true, shift: true);
    expect(container.read(workspaceControllerProvider).activeText, '> alpha');

    await tester.enterText(sourceField, 'snippet');
    final controller = tester.widget<TextField>(sourceField).controller!;
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
    await tester.pump();

    await pressShortcut(LogicalKeyboardKey.keyK, control: true, shift: true);
    expect(
      container.read(workspaceControllerProvider).activeText,
      '```\nsnippet\n```',
    );

    await tester.enterText(sourceField, 'line');
    await tester.pump();

    await pressShortcut(LogicalKeyboardKey.enter, shift: true);
    expect(container.read(workspaceControllerProvider).activeText, 'line  \n');
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
  });

  testWidgets('Tab and Shift+Tab update indentation in source view', (
    tester,
  ) async {
    final temp = Directory.systemTemp.createTempSync('busymark_source_tab_');
    addTearDown(() {
      temp.deleteSync(recursive: true);
    });
    final file = File('${temp.path}/Intro.md')..writeAsStringSync('- Parent\n');
    final service = _TabbedWorkspaceService(
      rootPath: temp.path,
      paths: [file.path],
    );
    final settingsStore = _MemorySettingsStore()
      ..value = AppSettings.defaults()
          .copyWith(documentViewMode: DocumentViewModePreference.source)
          .toJson();
    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(settingsStore),
        workspaceServiceProvider.overrideWithValue(service),
        startupPathProvider.overrideWithValue(temp.path),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BusyMarkApp(),
      ),
    );
    for (var i = 0; i < 30; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (container.read(workspaceControllerProvider).workspace != null) {
        break;
      }
    }
    await container
        .read(appSettingsControllerProvider.notifier)
        .setDocumentViewMode(DocumentViewModePreference.source);
    for (var i = 0; i < 10; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(TextField).evaluate().isNotEmpty) {
        break;
      }
    }

    final sourceField = find.byType(TextField).last;
    await tester.tap(sourceField);
    await tester.enterText(sourceField, '- Parent\n- Child\n');
    final controller = tester.widget<TextField>(sourceField).controller!;
    controller.selection = const TextSelection.collapsed(offset: 9);
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(
      container.read(workspaceControllerProvider).activeText,
      '- Parent\n  - Child\n',
    );
    expect(controller.text, '- Parent\n  - Child\n');

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();

    expect(
      container.read(workspaceControllerProvider).activeText,
      '- Parent\n- Child\n',
    );
    expect(controller.text, '- Parent\n- Child\n');
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
  });

  testWidgets(
    'editing toolbar context menu changes persisted layout without toggling',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final settingsStore = _MemorySettingsStore()
        ..value = AppSettings.defaults()
            .copyWith(documentViewMode: DocumentViewModePreference.editor)
            .toJson();
      const service = _SearchWorkspaceService('# Editing toolbar\n');
      final container = ProviderContainer(
        overrides: [
          linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
          localSettingsStoreProvider.overrideWithValue(settingsStore),
          workspaceServiceProvider.overrideWithValue(service),
          startupPathProvider.overrideWithValue('/tmp/editing-toolbar-menu.md'),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BusyMarkApp(),
        ),
      );
      for (var i = 0; i < 30; i += 1) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.byTooltip(l10n.hideEditingButtons).evaluate().isNotEmpty) {
          break;
        }
      }
      await tester.pump();

      Finder menuItem(String label) => find.byWidgetPredicate(
        (widget) =>
            widget is BusyMarkPopupMenuItem<Object?> && widget.label == label,
      );

      BusyMarkPopupMenuItem<Object?> popupItem(String label) {
        return tester.widget<BusyMarkPopupMenuItem<Object?>>(menuItem(label));
      }

      void expectChecked(String label, {required bool checked}) {
        final item = popupItem(label);
        expect(item.trailingCheck, isTrue);
        expect(item.checked, checked);
      }

      final hideButton = find.byTooltip(l10n.hideEditingButtons);
      final showButton = find.byTooltip(l10n.showEditingButtons);
      expect(hideButton, findsOneWidget);
      expect(showButton, findsNothing);
      expect(
        container.read(appSettingsControllerProvider).editorToolbarPlacement,
        EditorToolbarPlacement.topLeft,
      );
      expect(
        container.read(appSettingsControllerProvider).editorToolbarDirection,
        EditorToolbarDirection.horizontal,
      );

      final initialToggleRect = tester.getRect(hideButton);
      final unorderedTooltip =
          '${l10n.unorderedList} '
          '(${BusyMarkEditorShortcutLabels.unorderedList})';
      final orderedTooltip =
          '${l10n.orderedList} '
          '(${BusyMarkEditorShortcutLabels.orderedList})';
      final horizontalUnorderedRect = tester.getRect(
        find.byTooltip(unorderedTooltip),
      );
      final horizontalOrderedRect = tester.getRect(
        find.byTooltip(orderedTooltip),
      );
      expect(
        horizontalUnorderedRect.center.dy,
        closeTo(horizontalOrderedRect.center.dy, 0.1),
      );
      expect(
        (horizontalUnorderedRect.center.dx - horizontalOrderedRect.center.dx)
            .abs(),
        greaterThan(1),
      );

      await tester.tap(hideButton, buttons: kSecondaryMouseButton);
      await tester.pumpAndSettle();

      expect(hideButton, findsOneWidget);
      expect(showButton, findsNothing);
      for (final label in [
        l10n.topLeft,
        l10n.topRight,
        l10n.bottomLeft,
        l10n.bottomRight,
        l10n.horizontal,
        l10n.vertical,
      ]) {
        expect(menuItem(label), findsOneWidget);
      }
      expectChecked(l10n.topLeft, checked: true);
      expectChecked(l10n.bottomRight, checked: false);
      expectChecked(l10n.horizontal, checked: true);
      expectChecked(l10n.vertical, checked: false);

      await tester.tap(find.text(l10n.bottomRight));
      await tester.pumpAndSettle();

      expect(hideButton, findsOneWidget);
      expect(showButton, findsNothing);
      expect(
        container.read(appSettingsControllerProvider).editorToolbarPlacement,
        EditorToolbarPlacement.bottomRight,
      );
      expect(settingsStore.value['editorToolbarPlacement'], 'bottomRight');
      final bottomRightToggleRect = tester.getRect(hideButton);
      expect(
        bottomRightToggleRect.center.dx,
        greaterThan(initialToggleRect.center.dx),
      );
      expect(
        bottomRightToggleRect.center.dy,
        greaterThan(initialToggleRect.center.dy),
      );

      await tester.tap(hideButton);
      await tester.pump();

      expect(hideButton, findsNothing);
      expect(showButton, findsOneWidget);
      await tester.tap(showButton, buttons: kSecondaryMouseButton);
      await tester.pumpAndSettle();

      expect(hideButton, findsNothing);
      expect(showButton, findsOneWidget);
      expectChecked(l10n.topLeft, checked: false);
      expectChecked(l10n.bottomRight, checked: true);
      expectChecked(l10n.horizontal, checked: true);
      expectChecked(l10n.vertical, checked: false);

      await tester.tap(find.text(l10n.vertical));
      await tester.pumpAndSettle();

      expect(hideButton, findsNothing);
      expect(showButton, findsOneWidget);
      expect(
        container.read(appSettingsControllerProvider).editorToolbarDirection,
        EditorToolbarDirection.vertical,
      );
      expect(settingsStore.value['editorToolbarDirection'], 'vertical');

      await tester.tap(showButton);
      await tester.pump();

      expect(hideButton, findsOneWidget);
      expect(showButton, findsNothing);
      final verticalToggleRect = tester.getRect(hideButton);
      final verticalUnorderedRect = tester.getRect(
        find.byTooltip(unorderedTooltip),
      );
      final verticalOrderedRect = tester.getRect(
        find.byTooltip(orderedTooltip),
      );
      expect(
        verticalUnorderedRect.center.dx,
        closeTo(verticalOrderedRect.center.dx, 0.1),
      );
      expect(
        (verticalUnorderedRect.center.dy - verticalOrderedRect.center.dy).abs(),
        greaterThan(1),
      );
      expect(
        verticalToggleRect.center.dx,
        closeTo(verticalUnorderedRect.center.dx, BusyMarkSpacing.sm),
      );
      expect(
        verticalToggleRect.center.dy,
        greaterThan(verticalUnorderedRect.center.dy),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Editor and Preview share a frame while Split stays fluid', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final settingsStore = _MemorySettingsStore()
      ..value = AppSettings.defaults()
          .copyWith(documentViewMode: DocumentViewModePreference.editor)
          .toJson();
    const service = _SearchWorkspaceService(
      '# Shared document frame\n\nParagraph line one\nParagraph line two\n',
    );
    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(settingsStore),
        workspaceServiceProvider.overrideWithValue(service),
        startupPathProvider.overrideWithValue('/tmp/shared-frame.md'),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BusyMarkApp(),
      ),
    );
    for (var i = 0; i < 30; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find
          .byKey(const ValueKey('wysiwyg-document-content'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }

    final editorContent = find.byKey(
      const ValueKey('wysiwyg-document-content'),
    );
    final editorScroll = find.byKey(const ValueKey('wysiwyg-document-scroll'));
    expect(editorContent, findsOneWidget);
    expect(editorScroll, findsOneWidget);
    final editorRect = tester.getRect(editorContent);
    final editorScrollRect = tester.getRect(editorScroll);
    expect(editorScrollRect.width, greaterThan(editorRect.width));
    expect(editorScrollRect.right, greaterThan(editorRect.right));
    final editorHeadingRect = tester.getRect(
      find.descendant(of: editorContent, matching: find.byType(TextField)),
    );
    final editorParagraphRect = tester.getRect(
      find.descendant(of: editorScroll, matching: find.byType(TextField)).at(1),
    );
    final editorParagraphStyle = tester
        .widget<TextField>(
          find
              .descendant(of: editorScroll, matching: find.byType(TextField))
              .at(1),
        )
        .style;
    final editorPadding = tester
        .widget<ScrollablePositionedList>(editorScroll)
        .padding;
    final expectedStandalone = BusyMarkDocumentLayoutSpec.standalone
        .withEditingToolbar(
          placement: EditorToolbarPlacement.topLeft,
          direction: EditorToolbarDirection.horizontal,
        );
    expect(editorPadding, expectedStandalone.scrollPadding);

    container
        .read(workspaceControllerProvider.notifier)
        .updateActiveEditorMode(DocumentViewModePreference.preview);
    await container
        .read(appSettingsControllerProvider.notifier)
        .setDocumentViewMode(DocumentViewModePreference.preview);
    await tester.pump(const Duration(milliseconds: 100));

    final previewContent = find.byKey(
      const ValueKey('preview-document-content'),
    );
    final previewScroll = find.byKey(const ValueKey('preview-document-scroll'));
    expect(previewContent, findsOneWidget);
    expect(previewScroll, findsOneWidget);
    final previewRect = tester.getRect(previewContent);
    final previewScrollRect = tester.getRect(previewScroll);
    expect(previewScrollRect.width, closeTo(editorScrollRect.width, 0.1));
    expect(previewScrollRect.right, closeTo(editorScrollRect.right, 0.1));
    expect(previewScrollRect.width, greaterThan(previewRect.width));
    expect(previewScrollRect.right, greaterThan(previewRect.right));
    final previewHeading = find.descendant(
      of: previewContent,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('Shared document frame'),
      ),
    );
    expect(previewHeading, findsOneWidget);
    final previewHeadingRect = tester.getRect(previewHeading);
    final previewParagraph = find.descendant(
      of: previewScroll,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.textSpan?.toPlainText().contains('Paragraph line one') ==
                true,
      ),
    );
    expect(previewParagraph, findsOneWidget);
    final previewParagraphRect = tester.getRect(previewParagraph);
    final previewParagraphStyle = tester
        .widget<Text>(previewParagraph)
        .textSpan
        ?.style;
    expect(previewRect.left, closeTo(editorRect.left, 0.1));
    expect(previewRect.right, closeTo(editorRect.right, 0.1));
    expect(previewHeadingRect.left, closeTo(editorHeadingRect.left, 0.1));
    expect(previewHeadingRect.top, closeTo(editorHeadingRect.top, 0.1));
    expect(previewParagraphRect.left, closeTo(editorParagraphRect.left, 0.1));
    expect(previewParagraphRect.top, closeTo(editorParagraphRect.top, 0.1));
    expect(editorParagraphStyle?.height, BusyMarkTypography.bodyLineHeight);
    expect(previewParagraphStyle?.height, editorParagraphStyle?.height);
    expect(
      previewParagraphRect.height,
      closeTo(editorParagraphRect.height, 0.1),
    );
    expect(
      tester.widget<ScrollablePositionedList>(previewScroll).padding,
      editorPadding,
    );
    final previewControllerBeforeSplit = tester
        .widget<ScrollablePositionedList>(previewScroll)
        .itemScrollController;

    container
        .read(workspaceControllerProvider.notifier)
        .updateActiveEditorMode(DocumentViewModePreference.split);
    await container
        .read(appSettingsControllerProvider.notifier)
        .setDocumentViewMode(DocumentViewModePreference.split);
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(
      tester
          .widget<ScrollablePositionedList>(previewScroll)
          .itemScrollController,
      same(previewControllerBeforeSplit),
    );

    final splitPaneRect = tester.getRect(previewScroll);
    final splitContentRect = tester.getRect(previewContent);
    expect(
      splitContentRect.left,
      closeTo(
        splitPaneRect.left +
            BusyMarkDocumentLayoutSpec.splitPreview.minimumInsets.left,
        0.1,
      ),
    );
    expect(
      splitContentRect.right,
      closeTo(
        splitPaneRect.right -
            BusyMarkDocumentLayoutSpec.splitPreview.minimumInsets.right,
        0.1,
      ),
    );
    expect(
      splitContentRect.top,
      closeTo(
        splitPaneRect.top +
            BusyMarkDocumentLayoutSpec.splitPreview.scrollPadding.top,
        0.1,
      ),
    );
    expect(
      tester.widget<ScrollablePositionedList>(previewScroll).padding,
      BusyMarkDocumentLayoutSpec.splitPreview.scrollPadding,
    );
  });

  testWidgets('Editor and Preview share task-list presentation and wrapping', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const paragraph =
        'P1 — Git push can target the wrong workspace. '
        'lib/src/git/application/git_controller.dart captures repository A, '
        'awaits its remotes, then reads the current repository again. '
        'Switching repositories during that await can target the wrong remote.';
    final settingsStore = _MemorySettingsStore()
      ..value = AppSettings.defaults()
          .copyWith(documentViewMode: DocumentViewModePreference.editor)
          .toJson();
    const service = _SearchWorkspaceService(
      '- [x] $paragraph\n'
      '- [ ] Pending task\n',
    );
    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(settingsStore),
        workspaceServiceProvider.overrideWithValue(service),
        startupPathProvider.overrideWithValue('/tmp/wrap-parity.md'),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BusyMarkApp(),
      ),
    );
    for (var i = 0; i < 30; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find
          .byWidgetPredicate(
            (widget) =>
                widget is TextField && widget.controller?.text == paragraph,
          )
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }

    final editorField = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.controller?.text == paragraph,
    );
    final editorRender = _findRenderEditable(
      tester.renderObject<RenderObject>(editorField),
    );
    expect(editorRender, isNotNull);
    final editorLineEnds = _visualLineEndOffsets(
      paragraph,
      (selection) => editorRender!.getBoxesForSelection(selection),
    );
    final editorFieldWidth = tester.getSize(editorField).width;
    expect(editorLineEnds.length, greaterThan(1));
    final editorCheckedMarker = _taskMarkerVisual(tester, checked: true);
    final editorUncheckedMarker = _taskMarkerVisual(tester, checked: false);
    final editorMarkerColors = BusyMarkSurfaceColors.of(
      tester.element(editorCheckedMarker.finder),
    );
    final editorPrimary = Theme.of(
      tester.element(editorCheckedMarker.finder),
    ).colorScheme.primary;
    expect(editorCheckedMarker.onTaskChanged, isNotNull);
    expect(editorUncheckedMarker.onTaskChanged, isNotNull);
    expect(editorCheckedMarker.color, editorPrimary);
    expect(editorUncheckedMarker.color, editorMarkerColors.foreground);

    container
        .read(workspaceControllerProvider.notifier)
        .updateActiveEditorMode(DocumentViewModePreference.preview);
    await container
        .read(appSettingsControllerProvider.notifier)
        .setDocumentViewMode(DocumentViewModePreference.preview);
    await tester.pump(const Duration(milliseconds: 100));

    final previewText = find.byWidgetPredicate(
      (widget) => widget is Text && widget.textSpan?.toPlainText() == paragraph,
    );
    final previewRichText = find.descendant(
      of: previewText,
      matching: find.byType(RichText),
    );
    final previewRender = tester.renderObject<RenderParagraph>(previewRichText);
    final previewLineEnds = _visualLineEndOffsets(
      paragraph,
      (selection) => previewRender.getBoxesForSelection(selection),
    );
    final previewCheckedMarker = _taskMarkerVisual(tester, checked: true);
    final previewUncheckedMarker = _taskMarkerVisual(tester, checked: false);

    expect(previewLineEnds, editorLineEnds);
    expect(
      tester.getSize(previewRichText).width,
      closeTo(
        editorFieldWidth - BusyMarkDocumentTextGeometry.editableLayoutInset,
        0.01,
      ),
    );
    expect(previewCheckedMarker.onTaskChanged, isNull);
    expect(previewUncheckedMarker.onTaskChanged, isNull);
    expect(previewCheckedMarker.size, editorCheckedMarker.size);
    expect(previewUncheckedMarker.size, editorUncheckedMarker.size);
    expect(previewCheckedMarker.glyphSize, editorCheckedMarker.glyphSize);
    expect(previewUncheckedMarker.glyphSize, editorUncheckedMarker.glyphSize);
    expect(previewCheckedMarker.color, editorCheckedMarker.color);
    expect(previewUncheckedMarker.color, editorUncheckedMarker.color);
  });

  testWidgets('Editor and Preview reuse the same quote shell geometry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final settingsStore = _MemorySettingsStore()
      ..value = AppSettings.defaults()
          .copyWith(documentViewMode: DocumentViewModePreference.editor)
          .toJson();
    const service = _SearchWorkspaceService('> Shared quote.\n');
    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(settingsStore),
        workspaceServiceProvider.overrideWithValue(service),
        startupPathProvider.overrideWithValue('/tmp/shared-quote.md'),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BusyMarkApp(),
      ),
    );
    for (var i = 0; i < 30; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(BusyMarkDocumentCallout).evaluate().isNotEmpty) {
        break;
      }
    }

    final editorShell = find.byType(BusyMarkDocumentCallout);
    final editorText = find.descendant(
      of: editorShell,
      matching: find.byType(TextField),
    );
    final editorIcon = find.descendant(
      of: editorShell,
      matching: find.byIcon(BusyMarkGlyphs.blockquote),
    );
    expect(editorShell, findsOneWidget);
    expect(editorText, findsOneWidget);
    expect(editorIcon, findsOneWidget);
    final editorShellRect = tester.getRect(editorShell);
    final editorTextRect = tester.getRect(editorText);
    final editorIconRect = tester.getRect(editorIcon);

    container
        .read(workspaceControllerProvider.notifier)
        .updateActiveEditorMode(DocumentViewModePreference.preview);
    await container
        .read(appSettingsControllerProvider.notifier)
        .setDocumentViewMode(DocumentViewModePreference.preview);
    await tester.pump(const Duration(milliseconds: 100));

    final previewShell = find.byType(BusyMarkDocumentCallout);
    final previewText = find.descendant(
      of: previewShell,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is RichText && widget.text.toPlainText() == 'Shared quote.',
      ),
    );
    final previewIcon = find.descendant(
      of: previewShell,
      matching: find.byIcon(BusyMarkGlyphs.blockquote),
    );
    expect(previewShell, findsOneWidget);
    expect(previewText, findsOneWidget);
    expect(previewIcon, findsOneWidget);
    final previewShellRect = tester.getRect(previewShell);
    final previewTextRect = tester.getRect(previewText);
    final previewIconRect = tester.getRect(previewIcon);

    expect(previewShellRect.left, closeTo(editorShellRect.left, 0.1));
    expect(previewShellRect.right, closeTo(editorShellRect.right, 0.1));
    expect(previewShellRect.top, closeTo(editorShellRect.top, 0.1));
    expect(
      previewTextRect.left - previewShellRect.left,
      closeTo(editorTextRect.left - editorShellRect.left, 0.1),
    );
    expect(
      previewTextRect.top - previewShellRect.top,
      closeTo(editorTextRect.top - editorShellRect.top, 0.1),
    );
    final editorIconOffset = editorIconRect.topLeft - editorShellRect.topLeft;
    final previewIconOffset =
        previewIconRect.topLeft - previewShellRect.topLeft;
    expect(previewIconOffset.dx, closeTo(editorIconOffset.dx, 0.1));
    expect(previewIconOffset.dy, closeTo(editorIconOffset.dy, 0.1));
  });

  testWidgets('Editor and Preview reuse the same code block presentation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const code =
        'final values = <int>[40, 2];\nprint(values.first + values.last);';
    final settingsStore = _MemorySettingsStore()
      ..value = AppSettings.defaults()
          .copyWith(
            localeTag: 'ar',
            documentViewMode: DocumentViewModePreference.editor,
          )
          .toJson();
    const service = _SearchWorkspaceService('```dart\n$code\n```\n\nمرحبا\n');
    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(settingsStore),
        workspaceServiceProvider.overrideWithValue(service),
        startupPathProvider.overrideWithValue('/tmp/shared-code-block.md'),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BusyMarkApp(),
      ),
    );
    for (var i = 0; i < 30; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(BusyMarkDocumentCodeBlock).evaluate().isNotEmpty) {
        break;
      }
    }

    final editorShell = find.byType(BusyMarkDocumentCodeBlock);
    final editorField = find.descendant(
      of: editorShell,
      matching: find.byType(TextField),
    );
    expect(editorShell, findsOneWidget);
    expect(editorField, findsOneWidget);
    expect(
      find.descendant(
        of: editorShell,
        matching: find.byIcon(BusyMarkGlyphs.code),
      ),
      findsNothing,
    );
    final editorTextField = tester.widget<TextField>(editorField);
    expect(editorTextField.controller?.text, code);
    expect(editorTextField.textDirection, TextDirection.ltr);
    final editorShellRect = tester.getRect(editorShell);
    final editorTextRect = tester.getRect(editorField);
    final editorStyle = editorTextField.style;

    container
        .read(workspaceControllerProvider.notifier)
        .updateActiveEditorMode(DocumentViewModePreference.preview);
    await container
        .read(appSettingsControllerProvider.notifier)
        .setDocumentViewMode(DocumentViewModePreference.preview);
    await tester.pump(const Duration(milliseconds: 100));

    final previewShell = find.byType(BusyMarkDocumentCodeBlock);
    final previewText = find.descendant(
      of: previewShell,
      matching: find.byWidgetPredicate(
        (widget) => widget is Text && widget.textSpan?.toPlainText() == code,
      ),
    );
    expect(previewShell, findsOneWidget);
    expect(previewText, findsOneWidget);
    expect(
      find.descendant(
        of: previewShell,
        matching: find.byIcon(BusyMarkGlyphs.code),
      ),
      findsNothing,
    );
    final previewTextWidget = tester.widget<Text>(previewText);
    expect(previewTextWidget.textSpan?.toPlainText(), code);
    expect(Directionality.of(tester.element(previewText)), TextDirection.ltr);
    final previewArabic = find.descendant(
      of: find.byKey(const ValueKey('preview-document-scroll')),
      matching: find.byWidgetPredicate(
        (widget) => widget is RichText && widget.text.toPlainText() == 'مرحبا',
      ),
    );
    expect(previewArabic, findsOneWidget);
    expect(Directionality.of(tester.element(previewArabic)), TextDirection.rtl);
    final previewStyle = previewTextWidget.textSpan?.style;
    final previewShellRect = tester.getRect(previewShell);
    final previewTextRect = tester.getRect(previewText);

    expect(previewShellRect.left, closeTo(editorShellRect.left, 0.1));
    expect(previewShellRect.right, closeTo(editorShellRect.right, 0.1));
    expect(previewShellRect.top, closeTo(editorShellRect.top, 0.1));
    expect(previewShellRect.height, closeTo(editorShellRect.height, 0.1));
    expect(
      previewTextRect.left - previewShellRect.left,
      closeTo(editorTextRect.left - editorShellRect.left, 0.1),
    );
    expect(
      previewTextRect.top - previewShellRect.top,
      closeTo(editorTextRect.top - editorShellRect.top, 0.1),
    );
    expect(editorStyle?.fontFamily, BusyMarkTypography.monoFontFamily);
    expect(previewStyle?.fontFamily, editorStyle?.fontFamily);
    expect(previewStyle?.fontFamilyFallback, editorStyle?.fontFamilyFallback);
    expect(previewStyle?.fontSize, editorStyle?.fontSize);
    expect(previewStyle?.height, editorStyle?.height);
  });

  testWidgets('Editor and Preview share professional heading hierarchy', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final settingsStore = _MemorySettingsStore()
      ..value = AppSettings.defaults()
          .copyWith(documentViewMode: DocumentViewModePreference.editor)
          .toJson();
    const headings = ['First', 'Second', 'Third', 'Fourth', 'Fifth', 'Sixth'];
    const service = _SearchWorkspaceService('''
# First

## Second

### Third

#### Fourth

##### Fifth

###### Sixth

Body paragraph.

Before break.

---

After break.
''');
    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(settingsStore),
        workspaceServiceProvider.overrideWithValue(service),
        startupPathProvider.overrideWithValue('/tmp/shared-block-geometry.md'),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BusyMarkApp(),
      ),
    );
    for (var i = 0; i < 30; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(BusyMarkDocumentThematicBreak).evaluate().isNotEmpty) {
        break;
      }
    }

    Finder editorHeading(String text) => find.byWidgetPredicate(
      (widget) => widget is TextField && widget.controller?.text == text,
    );
    final editorHeadingRects = <String, Rect>{};
    final editorHeadingStyles = <String, TextStyle?>{};
    for (final heading in headings) {
      final finder = editorHeading(heading);
      expect(finder, findsOneWidget);
      editorHeadingRects[heading] = tester.getRect(finder);
      editorHeadingStyles[heading] = tester.widget<TextField>(finder).style;
    }
    final editorBody = find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.controller?.text == 'Body paragraph.',
    );
    expect(editorBody, findsOneWidget);
    final editorBodyStyle = tester.widget<TextField>(editorBody).style;
    final editorBodyRect = tester.getRect(editorBody);
    final editorColors = BusyMarkSurfaceColors.of(
      tester.element(editorHeading(headings.first)),
    );
    final editorHeadingSizes = [
      for (final heading in headings) editorHeadingStyles[heading]!.fontSize!,
    ];
    for (var index = 0; index < editorHeadingSizes.length - 1; index += 1) {
      expect(
        editorHeadingSizes[index],
        greaterThan(editorHeadingSizes[index + 1]),
        reason:
            '${headings[index]} should be larger than '
            '${headings[index + 1]}',
      );
    }
    final editorBodySize = editorBodyStyle!.fontSize!;
    for (var index = 0; index < editorHeadingSizes.length; index += 1) {
      expect(
        editorHeadingSizes[index],
        greaterThan(editorBodySize),
        reason: '${headings[index]} should be visibly larger than body text',
      );
    }
    expect(
      editorHeadingSizes[3],
      lessThanOrEqualTo(editorBodySize * 1.11),
      reason: 'H4 should not jump disproportionately above body text',
    );
    for (var index = 3; index < editorHeadingSizes.length - 1; index += 1) {
      expect(
        editorHeadingSizes[index] - editorHeadingSizes[index + 1],
        lessThanOrEqualTo(editorBodySize * 0.03),
        reason: 'H4-H6 should form a smooth visual progression',
      );
    }
    for (final heading in headings.skip(3)) {
      expect(
        editorHeadingRects[heading]!.height,
        greaterThanOrEqualTo(editorBodyRect.height - 0.1),
        reason: '$heading should not render shorter than body text',
      );
    }
    for (final style in editorHeadingStyles.values) {
      expect(style?.color, editorColors.foreground);
      expect(style?.fontWeight, FontWeight.w700);
      expect(style?.height, isNotNull);
      expect(style?.height, lessThan(BusyMarkTypography.bodyLineHeight));
    }
    final editorBreak = find.byType(BusyMarkDocumentThematicBreak);
    expect(editorBreak, findsOneWidget);
    expect(
      tester.widget<BusyMarkDocumentThematicBreak>(editorBreak).editable,
      isTrue,
    );
    final editorBreakRect = tester.getRect(editorBreak);
    final editorAfterRect = _rightmostTextRect(tester, 'After break.');
    expect(
      editorBreakRect.height,
      closeTo(
        BusyMarkInsets.documentThematicBreakBlock.vertical +
            BusyMarkStroke.thematicBreak,
        0.01,
      ),
    );

    container
        .read(workspaceControllerProvider.notifier)
        .updateActiveEditorMode(DocumentViewModePreference.preview);
    await container
        .read(appSettingsControllerProvider.notifier)
        .setDocumentViewMode(DocumentViewModePreference.preview);
    await tester.pump(const Duration(milliseconds: 100));

    final previewScroll = find.byKey(const ValueKey('preview-document-scroll'));
    Finder previewHeading(String text) => find.descendant(
      of: previewScroll,
      matching: find.byWidgetPredicate(
        (widget) => widget is Text && widget.textSpan?.toPlainText() == text,
      ),
    );
    final previewHeadingStyles = <String, TextStyle?>{};
    for (final heading in headings) {
      final finder = previewHeading(heading);
      expect(finder, findsOneWidget);
      final previewRect = tester.getRect(finder);
      final previewStyle = tester.widget<Text>(finder).textSpan?.style;
      previewHeadingStyles[heading] = previewStyle;
      final editorRect = editorHeadingRects[heading]!;
      final editorStyle = editorHeadingStyles[heading];
      expect(previewRect.left, closeTo(editorRect.left, 0.1));
      expect(previewRect.top, closeTo(editorRect.top, 0.1));
      expect(previewRect.height, closeTo(editorRect.height, 0.1));
      expect(previewStyle?.fontSize, editorStyle?.fontSize);
      expect(previewStyle?.fontWeight, editorStyle?.fontWeight);
      expect(previewStyle?.height, editorStyle?.height);
    }
    final previewBody = find.descendant(
      of: previewScroll,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.textSpan?.toPlainText() == 'Body paragraph.',
      ),
    );
    expect(previewBody, findsOneWidget);
    final previewBodyStyle = tester.widget<Text>(previewBody).textSpan?.style;
    expect(previewBodyStyle?.fontSize, editorBodyStyle.fontSize);
    for (final heading in headings) {
      expect(
        previewHeadingStyles[heading]?.color,
        editorHeadingStyles[heading]?.color,
      );
    }

    final previewBreak = find.byType(BusyMarkDocumentThematicBreak);
    expect(previewBreak, findsOneWidget);
    expect(
      tester.widget<BusyMarkDocumentThematicBreak>(previewBreak).editable,
      isFalse,
    );
    final previewBreakRect = tester.getRect(previewBreak);
    final previewAfterRect = _rightmostTextRect(tester, 'After break.');
    expect(previewBreakRect, editorBreakRect);
    expect(previewAfterRect.left, closeTo(editorAfterRect.left, 0.1));
    expect(previewAfterRect.top, closeTo(editorAfterRect.top, 0.1));
  });

  testWidgets('Editor and Preview share admonition and image presentation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final settingsStore = _MemorySettingsStore()
      ..value = AppSettings.defaults()
          .copyWith(documentViewMode: DocumentViewModePreference.editor)
          .toJson();
    const service = _SearchWorkspaceService('''
<warning>Shared warning.</warning>

![Shared image](missing.png){ width="320" }
''', writerside: true);
    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(settingsStore),
        workspaceServiceProvider.overrideWithValue(service),
        startupPathProvider.overrideWithValue('/tmp/shared-rich-blocks.md'),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BusyMarkApp(),
      ),
    );
    for (var i = 0; i < 30; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(BusyMarkDocumentAdmonition).evaluate().isNotEmpty &&
          find.byType(MarkdownImageView).evaluate().isNotEmpty) {
        break;
      }
    }

    final editorAdmonition = find.byType(BusyMarkDocumentAdmonition);
    final editorImage = find.byType(MarkdownImageView);
    expect(editorAdmonition, findsOneWidget);
    expect(editorImage, findsOneWidget);
    expect(
      find.descendant(
        of: editorAdmonition,
        matching: find.byIcon(BusyMarkGlyphs.warning),
      ),
      findsOneWidget,
    );
    final editorAdmonitionRect = tester.getRect(editorAdmonition);
    final editorImageRect = tester.getRect(editorImage);
    final editorImageWidget = tester.widget<MarkdownImageView>(editorImage);
    expect(editorImageWidget.width, 320);
    expect(editorImageWidget.maxWidth, 320);

    container
        .read(workspaceControllerProvider.notifier)
        .updateActiveEditorMode(DocumentViewModePreference.preview);
    await container
        .read(appSettingsControllerProvider.notifier)
        .setDocumentViewMode(DocumentViewModePreference.preview);
    await tester.pump(const Duration(milliseconds: 100));

    final previewAdmonition = find.byType(BusyMarkDocumentAdmonition);
    final previewImage = find.byType(MarkdownImageView);
    expect(previewAdmonition, findsOneWidget);
    expect(previewImage, findsOneWidget);
    expect(
      find.descendant(
        of: previewAdmonition,
        matching: find.byIcon(BusyMarkGlyphs.warning),
      ),
      findsOneWidget,
    );
    final previewImageWidget = tester.widget<MarkdownImageView>(previewImage);
    expect(previewImageWidget.width, editorImageWidget.width);
    expect(previewImageWidget.maxWidth, editorImageWidget.maxWidth);
    expect(tester.getRect(previewAdmonition), editorAdmonitionRect);
    expect(tester.getRect(previewImage), editorImageRect);
  });

  testWidgets('Preview renders structured formatted and nested quotes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final settingsStore = _MemorySettingsStore()
      ..value = AppSettings.defaults()
          .copyWith(documentViewMode: DocumentViewModePreference.preview)
          .toJson();
    const service = _SearchWorkspaceService('''
> First **bold**.
>
> Second *italic*.
>
> > اقتباس متداخل
''');
    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(settingsStore),
        workspaceServiceProvider.overrideWithValue(service),
        startupPathProvider.overrideWithValue('/tmp/structured-quote.md'),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BusyMarkApp(),
      ),
    );
    for (var i = 0; i < 30; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(BusyMarkDocumentCallout).evaluate().length == 2) {
        break;
      }
    }

    Finder richText(String text) => find.byWidgetPredicate(
      (widget) => widget is RichText && widget.text.toPlainText() == text,
    );

    final shells = find.byType(BusyMarkDocumentCallout);
    final first = richText('First bold.');
    final second = richText('Second italic.');
    final nested = richText('اقتباس متداخل');
    expect(shells, findsNWidgets(2));
    expect(first, findsOneWidget);
    expect(second, findsOneWidget);
    expect(nested, findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('First bold.') &&
            widget.text.toPlainText().contains('Second italic.'),
      ),
      findsNothing,
    );
    expect(tester.getRect(second).top, greaterThan(tester.getRect(first).top));
    expect(
      _textSpanStyleForText(
        tester.widget<RichText>(first).text as TextSpan,
        'bold',
      )?.fontWeight,
      FontWeight.w700,
    );
    expect(
      _textSpanStyleForText(
        tester.widget<RichText>(second).text as TextSpan,
        'italic',
      )?.fontStyle,
      FontStyle.italic,
    );

    final outerShell = find.ancestor(of: first, matching: shells);
    expect(outerShell, findsOneWidget);
    final nestedShells = find.ancestor(of: nested, matching: shells);
    expect(nestedShells, findsNWidgets(2));
    final outerRect = tester.getRect(outerShell);
    final nestedTextRect = tester.getRect(nested);
    expect(outerRect.contains(nestedTextRect.topLeft), isTrue);
    expect(outerRect.contains(nestedTextRect.bottomRight), isTrue);
    expect(Directionality.of(tester.element(nested)), TextDirection.rtl);
    final quoteIconRects = find
        .byIcon(BusyMarkGlyphs.blockquote)
        .evaluate()
        .map(
          (element) => tester.getRect(
            find.byElementPredicate((candidate) => candidate == element),
          ),
        );
    expect(
      quoteIconRects.any((rect) => rect.left > nestedTextRect.right),
      isTrue,
    );
  });

  testWidgets('editor undo cannot restore saved text from previous tab', (
    tester,
  ) async {
    final temp = Directory.systemTemp.createTempSync('busymark_editor_undo_');
    addTearDown(() {
      temp.deleteSync(recursive: true);
    });
    final first = File('${temp.path}/Introduction.md')
      ..writeAsStringSync('# Introduction\n');
    final second = File('${temp.path}/System-Design.md')
      ..writeAsStringSync('# System Design\n');
    final service = _TabbedWorkspaceService(
      rootPath: temp.path,
      paths: [first.path, second.path],
    );
    final settingsStore = _MemorySettingsStore()
      ..value = AppSettings.defaults()
          .copyWith(
            documentViewMode: DocumentViewModePreference.editor,
            editorToolbarPlacement: EditorToolbarPlacement.bottomLeft,
          )
          .toJson();
    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(settingsStore),
        workspaceServiceProvider.overrideWithValue(service),
        startupPathProvider.overrideWithValue(temp.path),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BusyMarkApp(),
      ),
    );
    for (var i = 0; i < 30; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (container.read(workspaceControllerProvider).workspace != null) {
        break;
      }
    }
    expect(container.read(workspaceControllerProvider).workspace, isNotNull);
    container
        .read(workspaceControllerProvider.notifier)
        .updateActiveEditorMode(DocumentViewModePreference.editor);
    await container
        .read(appSettingsControllerProvider.notifier)
        .setDocumentViewMode(DocumentViewModePreference.editor);
    for (var i = 0; i < 10; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(TextField).evaluate().isNotEmpty) {
        break;
      }
    }

    final editorField = find.byType(TextField).first;
    await tester.tap(editorField);
    await tester.enterText(editorField, 'Edited Introduction');
    await tester.pump();

    expect(
      container.read(workspaceControllerProvider).activeText,
      '# Edited Introduction\n',
    );

    final controller = container.read(workspaceControllerProvider.notifier);
    expect(await controller.saveActive(), isTrue);
    await tester.pump();

    expect(service.saveCount, 1);
    expect(service.savedPath, first.path);
    expect(service.savedText, '# Edited Introduction\n');

    await controller.openActiveFile(second.path);
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      container.read(workspaceControllerProvider).activeText,
      '# System-Design.md\n',
    );
    expect(
      tester.widget<TextField>(editorField).controller?.text,
      'System-Design.md',
    );

    await tester.tap(editorField);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      container.read(workspaceControllerProvider).activeText,
      '# System-Design.md\n',
    );
    expect(
      tester.widget<TextField>(editorField).controller?.text,
      'System-Design.md',
    );
    expect(service.savedPath, first.path);
    expect(service.savedText, '# Edited Introduction\n');
  });

  testWidgets('Tab inserts a tab character in editor view paragraphs', (
    tester,
  ) async {
    final settingsStore = _MemorySettingsStore()
      ..value = AppSettings.defaults()
          .copyWith(
            documentViewMode: DocumentViewModePreference.editor,
            editorToolbarPlacement: EditorToolbarPlacement.bottomLeft,
          )
          .toJson();
    final service = _SearchWorkspaceService('Paragraph\n');
    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(settingsStore),
        workspaceServiceProvider.overrideWithValue(service),
        startupPathProvider.overrideWithValue('/tmp/editor-tab.md'),
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
      if (find.byType(TextField).evaluate().isNotEmpty) {
        break;
      }
    }

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('workspace-sidebar-primary-label')),
        matching: find.text('editor-tab.md'),
      ),
      findsOneWidget,
    );
    final editorField = find.byType(TextField).first;
    await tester.tap(editorField);
    final controller = tester.widget<TextField>(editorField).controller!;
    controller.selection = const TextSelection.collapsed(offset: 0);
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(controller.text, '\tParagraph');
    expect(
      container.read(workspaceControllerProvider).activeText,
      '\tParagraph\n',
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
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

    await tester.tap(
      find.descendant(
        of: find.byType(BusyMarkDialogShell),
        matching: find.text(l10n.createMarkdownFile),
      ),
    );
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
    const startupPath = 'test/fixtures/markdown/basic.md';
    final service = _StartupWorkspaceService();
    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(_MemorySettingsStore()),
        workspaceServiceProvider.overrideWithValue(service),
        startupPathProvider.overrideWithValue(startupPath),
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

    expect(service.openedPath, startupPath);
    expect(find.text(l10n.openMarkdownFile), findsNothing);
    expect(find.textContaining('Basic Markdown'), findsWidgets);
    expect(find.byTooltip(startupPath), findsOneWidget);
    final outlineFileMenu = find.byKey(
      const ValueKey('workspace-sidebar-outline-file-menu'),
    );
    expect(outlineFileMenu, findsOneWidget);
    expect(
      find.descendant(
        of: outlineFileMenu,
        matching: find.byTooltip(l10n.actions),
      ),
      findsOneWidget,
    );
    final primarySidebarLabel = find.descendant(
      of: find.byKey(const ValueKey('workspace-sidebar-primary-label')),
      matching: find.byType(Text),
    );
    expect(primarySidebarLabel, findsOneWidget);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('workspace-sidebar-primary-row')))
          .height,
      greaterThanOrEqualTo(BusyMarkSizes.iconButton),
    );
    expect(tester.widget<Text>(primarySidebarLabel).data, 'basic.md');
    final outlineTree = find.byKey(
      const ValueKey('workspace-sidebar-outline-tree'),
    );
    expect(outlineTree, findsOneWidget);
    expect(
      find.descendant(of: outlineTree, matching: find.text('Basic Markdown')),
      findsOneWidget,
    );
    expect(find.text(l10n.noOutline), findsNothing);

    expect(find.byTooltip(l10n.sidebarViewMenu), findsNothing);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.digit4);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.digit4);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(outlineTree, findsOneWidget);
    expect(find.text(l10n.git), findsNothing);
    expect(find.text(l10n.gitChanges), findsNothing);
    expect(find.text(l10n.gitFileHistory), findsNothing);
    expect(find.text(l10n.gitProjectHistory), findsNothing);
  });

  testWidgets(
    'outline follows unsaved source headings without live validation',
    (tester) async {
      const startupPath = 'test/fixtures/markdown/basic.md';
      const unsaved = '''
# Unsaved title

Draft paragraph.

Another draft paragraph.

## Unsaved target

Body.
''';
      final service = _StartupWorkspaceService();
      final settingsStore = _MemorySettingsStore()
        ..value = AppSettings.defaults()
            .copyWith(
              autoSave: false,
              validateOnEdit: false,
              documentViewMode: DocumentViewModePreference.source,
            )
            .toJson();
      final container = ProviderContainer(
        overrides: [
          linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
          localSettingsStoreProvider.overrideWithValue(settingsStore),
          workspaceServiceProvider.overrideWithValue(service),
          startupPathProvider.overrideWithValue(startupPath),
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
        if (find.byType(TextField).evaluate().isNotEmpty) {
          break;
        }
      }

      final sourceField = find.descendant(
        of: find.byType(BusyMarkSourceEditor),
        matching: find.byType(TextField),
      );
      expect(sourceField, findsOneWidget);
      await tester.enterText(sourceField, unsaved);
      await tester.pump();

      final state = container.read(workspaceControllerProvider);
      expect(state.isDirty, isTrue);
      expect(state.workspace?.markdown?.title, 'Basic Markdown');
      final outlineTree = find.byKey(
        const ValueKey('workspace-sidebar-outline-tree'),
      );
      expect(
        find.descendant(of: outlineTree, matching: find.text('Unsaved target')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: outlineTree, matching: find.text('Basic Markdown')),
        findsNothing,
      );

      await tester.tap(
        find.descendant(of: outlineTree, matching: find.text('Unsaved target')),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final controller = tester.widget<TextField>(sourceField).controller!;
      expect(
        controller.selection,
        TextSelection.collapsed(offset: unsaved.indexOf('## Unsaved target')),
      );
      expect(service.saveCount, 0);
    },
  );

  testWidgets('outline context menu edits complete heading sections', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const startupPath = '/tmp/outline-section-actions.md';
    const source = '''
# Root

## Parent

Parent intro.

### Alpha

Alpha body.

#### Alpha child

Child body.

### Beta

Beta body.

### Gamma

Gamma body.
''';
    const alphaSection = '''### Alpha

Alpha body.

#### Alpha child

Child body.

''';
    const betaSection = '''### Beta

Beta body.

''';
    const gammaSection = '''### Gamma

Gamma body.
''';
    String? clipboardText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          final arguments = call.arguments as Map<Object?, Object?>;
          clipboardText = arguments['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    final settingsStore = _MemorySettingsStore()
      ..value = AppSettings.defaults()
          .copyWith(
            autoSave: false,
            validateOnEdit: false,
            documentViewMode: DocumentViewModePreference.source,
          )
          .toJson();
    const service = _SearchWorkspaceService(source);
    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(settingsStore),
        workspaceServiceProvider.overrideWithValue(service),
        startupPathProvider.overrideWithValue(startupPath),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BusyMarkApp(),
      ),
    );
    final outlineTree = find.byKey(
      const ValueKey('workspace-sidebar-outline-tree'),
    );
    for (var index = 0; index < 30; index += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find
          .descendant(of: outlineTree, matching: find.text('Alpha'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }
    expect(outlineTree, findsOneWidget);

    Finder headingRow(String heading) =>
        find.descendant(of: outlineTree, matching: find.text(heading));
    Finder menuItem(String label) => find.byWidgetPredicate(
      (widget) =>
          widget is BusyMarkPopupMenuItem<Object?> && widget.label == label,
    );
    BusyMarkPopupMenuItem<Object?> popupItem(String label) =>
        tester.widget<BusyMarkPopupMenuItem<Object?>>(menuItem(label));

    Future<void> openMenu(String heading) async {
      await tester.tap(headingRow(heading), buttons: kSecondaryButton);
      await tester.pumpAndSettle();
    }

    Future<void> expectSource(String expected) async {
      for (var index = 0; index < 30; index += 1) {
        await tester.pump(const Duration(milliseconds: 100));
        if (container.read(workspaceControllerProvider).activeText ==
            expected) {
          break;
        }
      }
      expect(container.read(workspaceControllerProvider).activeText, expected);
    }

    Future<void> resetSource() async {
      container
          .read(workspaceControllerProvider.notifier)
          .updateActiveText(source, sourceFilePath: startupPath);
      await expectSource(source);
      for (var index = 0; index < 30; index += 1) {
        await tester.pump(const Duration(milliseconds: 100));
        if (headingRow('Beta').evaluate().isNotEmpty) {
          break;
        }
      }
    }

    await openMenu('Alpha');
    for (final label in [
      l10n.copy,
      l10n.cut,
      l10n.aiRefineWithAi,
      l10n.promoteSection,
      l10n.demoteSection,
      l10n.moveSectionUp,
      l10n.moveSectionDown,
      l10n.delete,
    ]) {
      expect(menuItem(label), findsOneWidget);
    }
    expect(popupItem(l10n.promoteSection).enabled, isTrue);
    expect(popupItem(l10n.demoteSection).enabled, isTrue);
    expect(popupItem(l10n.moveSectionUp).enabled, isFalse);
    expect(popupItem(l10n.moveSectionDown).enabled, isTrue);

    await tester.tap(find.text(l10n.copy));
    await tester.pumpAndSettle();
    expect(clipboardText, alphaSection);
    expect(container.read(workspaceControllerProvider).activeText, source);

    await openMenu('Alpha');
    await tester.tap(find.text(l10n.promoteSection));
    final promoted = source
        .replaceFirst('### Alpha', '## Alpha')
        .replaceFirst('#### Alpha child', '### Alpha child');
    await expectSource(promoted);

    await resetSource();
    await openMenu('Alpha');
    await tester.tap(find.text(l10n.demoteSection));
    final demoted = source
        .replaceFirst('### Alpha', '#### Alpha')
        .replaceFirst('#### Alpha child', '##### Alpha child');
    await expectSource(demoted);

    await resetSource();
    await openMenu('Alpha');
    await tester.tap(find.text(l10n.moveSectionDown));
    final movedDown = source.replaceFirst(
      '$alphaSection$betaSection',
      '$betaSection$alphaSection',
    );
    await expectSource(movedDown);

    await resetSource();
    await openMenu('Beta');
    expect(popupItem(l10n.moveSectionUp).enabled, isTrue);
    expect(popupItem(l10n.moveSectionDown).enabled, isTrue);
    await tester.tap(find.text(l10n.cut));
    await expectSource(source.replaceFirst(betaSection, ''));
    expect(clipboardText, betaSection);

    await resetSource();
    await openMenu('Beta');
    await tester.tap(find.text(l10n.delete));
    await tester.pumpAndSettle();
    expect(find.text(l10n.confirmDeleteSectionTitle), findsOneWidget);
    expect(find.text(l10n.confirmDeleteSectionMessage('Beta')), findsOneWidget);
    await tester.tap(find.widgetWithText(BusyMarkDialogButton, l10n.delete));
    await expectSource(source.replaceFirst(betaSection, ''));

    await resetSource();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(headingRow('Alpha'));
    await tester.tap(headingRow('Gamma'));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    await openMenu('Gamma');
    expect(menuItem(l10n.copy), findsOneWidget);
    expect(menuItem(l10n.cut), findsOneWidget);
    expect(menuItem(l10n.aiRefineWithAi), findsOneWidget);
    expect(menuItem(l10n.delete), findsOneWidget);
    expect(menuItem(l10n.promoteSection), findsNothing);
    await tester.tap(find.text(l10n.copy));
    await tester.pumpAndSettle();
    expect(clipboardText, '$alphaSection$gammaSection');

    await openMenu('Gamma');
    await tester.tap(find.text(l10n.cut));
    await expectSource(
      source.replaceFirst(alphaSection, '').replaceFirst(gammaSection, ''),
    );
    expect(clipboardText, '$alphaSection$gammaSection');

    await resetSource();
    await tester.tap(headingRow('Beta'));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.tap(headingRow('Gamma'));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    await openMenu('Gamma');
    await tester.tap(find.text(l10n.delete));
    await tester.pumpAndSettle();
    expect(find.text(l10n.confirmDeleteSectionTitle), findsOneWidget);
    await tester.tap(find.widgetWithText(BusyMarkDialogButton, l10n.delete));
    await expectSource(
      source.replaceFirst(betaSection, '').replaceFirst(gammaSection, ''),
    );
  });

  testWidgets('outline highlights the heading at the document viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final source = [
      '# First section',
      '',
      for (var index = 0; index < 40; index += 1) ...[
        'First section paragraph $index.',
        '',
      ],
      '## Second section',
      '',
      for (var index = 0; index < 40; index += 1) ...[
        'Second section paragraph $index.',
        '',
      ],
      '## Third section',
      '',
      for (var index = 0; index < 40; index += 1) ...[
        'Third section paragraph $index.',
        '',
      ],
    ].join('\n');
    const startupPath = '/tmp/outline-scroll-position.md';
    final settingsStore = _MemorySettingsStore()
      ..value = AppSettings.defaults()
          .copyWith(
            autoSave: false,
            documentViewMode: DocumentViewModePreference.preview,
          )
          .toJson();
    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(settingsStore),
        workspaceServiceProvider.overrideWithValue(
          _SearchWorkspaceService(source),
        ),
        startupPathProvider.overrideWithValue(startupPath),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BusyMarkApp(),
      ),
    );
    final previewScroll = find.byKey(const ValueKey('preview-document-scroll'));
    for (var index = 0; index < 30; index += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (previewScroll.evaluate().isNotEmpty &&
          find
              .byKey(const ValueKey('workspace-sidebar-outline-row-2'))
              .evaluate()
              .isNotEmpty) {
        break;
      }
    }

    Finder outlineRow(int index) =>
        find.byKey(ValueKey('workspace-sidebar-outline-row-$index'));
    Color outlineRowColor(int index) {
      final material = find.descendant(
        of: outlineRow(index),
        matching: find.byWidgetPredicate(
          (widget) => widget is Material && widget.type == MaterialType.canvas,
        ),
      );
      expect(material, findsOneWidget);
      return tester.widget<Material>(material).color ?? Colors.transparent;
    }

    void expectSelectedOutlineRow(int selectedIndex) {
      final selectedColor = busyMarkSelectedBackground(
        tester.element(outlineRow(selectedIndex)),
      );
      for (var index = 0; index < 3; index += 1) {
        expect(
          outlineRowColor(index),
          index == selectedIndex
              ? selectedColor
              : BusyMarkLinuxPalette.transparent,
          reason: 'Outline row $index',
        );
      }
    }

    final firstOutlineRowTop = tester.getTopLeft(outlineRow(0)).dy;
    Finder firstOutlineToggle() => find.descendant(
      of: outlineRow(0),
      matching: find.byIcon(
        BusyMarkGlyphs.collapsedTreeArrowFor(TextDirection.ltr),
      ),
    );
    expect(firstOutlineToggle(), findsOneWidget);
    await tester.tap(firstOutlineToggle());
    await tester.pump();
    await tester.pump(BusyMarkMotion.sidebarExpand);
    await tester.pump();
    expect(
      tester.getTopLeft(outlineRow(0)).dy,
      closeTo(firstOutlineRowTop, 1),
      reason: 'Collapsing the Outline must preserve its top anchor.',
    );
    await tester.tap(firstOutlineToggle());
    await tester.pump();
    await tester.pump(BusyMarkMotion.sidebarExpand);
    await tester.pump();

    final state = container.read(workspaceControllerProvider);
    final outline = state.preview!.outline;
    expect(outline.map((heading) => heading.text), [
      'First section',
      'Second section',
      'Third section',
    ]);
    final secondPreviewIndex = state.preview!.blocks.indexWhere(
      (block) => block.attributes['id'] == outline[1].id,
    );
    expect(secondPreviewIndex, isNonNegative);

    expectSelectedOutlineRow(0);
    tester
        .widget<ScrollablePositionedList>(previewScroll)
        .itemScrollController!
        .jumpTo(index: secondPreviewIndex);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expectSelectedOutlineRow(1);

    final thirdPreviewIndex = state.preview!.blocks.indexWhere(
      (block) => block.attributes['id'] == outline[2].id,
    );
    expect(thirdPreviewIndex, isNonNegative);
    await tester.tap(outlineRow(2));
    await tester.pump();
    await tester.pump(BusyMarkMotion.scroll);
    await tester.pump();
    await tester.pump(BusyMarkMotion.scroll);
    await tester.pump();
    final previewPositions = tester
        .widget<ScrollablePositionedList>(previewScroll)
        .itemPositionsNotifier!
        .itemPositions
        .value;
    final thirdPreviewPosition = previewPositions.singleWhere(
      (position) => position.index == thirdPreviewIndex,
    );
    expect(
      thirdPreviewPosition.itemLeadingEdge,
      closeTo(0, 0.005),
      reason: 'Preview Outline navigation must use the tracking anchor.',
    );
    expectSelectedOutlineRow(2);

    container
        .read(workspaceControllerProvider.notifier)
        .updateActiveEditorMode(DocumentViewModePreference.editor);
    await container
        .read(appSettingsControllerProvider.notifier)
        .setDocumentViewMode(DocumentViewModePreference.editor);
    await tester.pump(const Duration(milliseconds: 100));
    final editorScroll = find.byKey(const ValueKey('wysiwyg-document-scroll'));
    expect(editorScroll, findsOneWidget);
    final editorDocument = container
        .read(workspaceControllerProvider)
        .workspace!
        .markdown!
        .busyDocument;
    final thirdEditorIndex = editorDocument.blocks.indexWhere(
      (block) => block.attributes['id'] == outline[2].id,
    );
    expect(thirdEditorIndex, isNonNegative);
    tester
        .widget<ScrollablePositionedList>(editorScroll)
        .itemScrollController!
        .jumpTo(index: thirdEditorIndex);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expectSelectedOutlineRow(2);

    final secondEditorIndex = editorDocument.blocks.indexWhere(
      (block) => block.attributes['id'] == outline[1].id,
    );
    expect(secondEditorIndex, isNonNegative);
    await tester.tap(outlineRow(1));
    await tester.pump();
    await tester.pump(BusyMarkMotion.scroll);
    await tester.pump();
    final editorPositions = tester
        .widget<ScrollablePositionedList>(editorScroll)
        .itemPositionsNotifier!
        .itemPositions
        .value;
    final secondEditorPosition = editorPositions.singleWhere(
      (position) => position.index == secondEditorIndex,
    );
    expect(
      secondEditorPosition.itemLeadingEdge,
      closeTo(0, 0.005),
      reason: 'Outline navigation must use the viewport tracking anchor.',
    );
    expectSelectedOutlineRow(1);

    container
        .read(workspaceControllerProvider.notifier)
        .updateActiveEditorMode(DocumentViewModePreference.source);
    await container
        .read(appSettingsControllerProvider.notifier)
        .setDocumentViewMode(DocumentViewModePreference.source);
    await tester.pump(const Duration(milliseconds: 100));
    final sourceEditor = find.byType(BusyMarkSourceEditor);
    expect(sourceEditor, findsOneWidget);
    tester
        .state<BusyMarkSourceEditorState>(sourceEditor)
        .scrollToLine(outline[1].sourceStartLine!);
    await tester.pump();
    await tester.pump(BusyMarkMotion.scroll);
    await tester.pump(const Duration(milliseconds: 100));
    expectSelectedOutlineRow(1);
  });

  testWidgets('outline navigates to a renamed unsaved editor heading', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const startupPath = '/tmp/unsaved-editor-outline.md';
    final source = [
      '# [Saved heading](https://example.com)',
      '',
      for (var index = 0; index < 60; index += 1) ...[
        'Paragraph $index keeps the editor scrollable.',
        '',
      ],
    ].join('\n');
    final service = _SearchWorkspaceService(source);
    final settingsStore = _MemorySettingsStore()
      ..value = AppSettings.defaults()
          .copyWith(
            autoSave: false,
            validateOnEdit: false,
            documentViewMode: DocumentViewModePreference.editor,
          )
          .toJson();
    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(settingsStore),
        workspaceServiceProvider.overrideWithValue(service),
        startupPathProvider.overrideWithValue(startupPath),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BusyMarkApp(),
      ),
    );
    final editorScroll = find.byKey(const ValueKey('wysiwyg-document-scroll'));
    for (var i = 0; i < 30; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (editorScroll.evaluate().isNotEmpty) {
        break;
      }
    }

    final editorFields = find.descendant(
      of: editorScroll,
      matching: find.byType(TextField),
    );
    expect(editorFields, findsWidgets);
    ScrollablePositionedList editorList() =>
        tester.widget<ScrollablePositionedList>(editorScroll);
    Finder editorFieldWithText(String text) => find.descendant(
      of: editorScroll,
      matching: find.byWidgetPredicate(
        (widget) => widget is TextField && widget.controller?.text == text,
      ),
    );
    final outlineTree = find.byKey(
      const ValueKey('workspace-sidebar-outline-tree'),
    );
    final formattedTarget = find.descendant(
      of: outlineTree,
      matching: find.text('Saved heading'),
    );
    expect(formattedTarget, findsOneWidget);

    editorList().itemScrollController!.jumpTo(
      index: editorList().itemCount - 1,
    );
    await tester.pump();
    expect(editorFieldWithText('Saved heading'), findsNothing);
    await tester.tap(formattedTarget);
    await tester.pumpAndSettle();
    expect(editorFieldWithText('Saved heading'), findsOneWidget);

    final previewBeforeEdit = container
        .read(workspaceControllerProvider)
        .preview;
    await tester.enterText(editorFields.first, 'Unsaved heading');
    await tester.pump();

    final state = container.read(workspaceControllerProvider);
    expect(
      state.activeText,
      startsWith('# [Unsaved heading](https://example.com)\n'),
    );
    expect(state.isDirty, isTrue);
    expect(identical(state.preview, previewBeforeEdit), isTrue);
    expect(state.liveOutline?.headings.map((heading) => heading.text), [
      'Unsaved heading',
    ]);
    final target = find.descendant(
      of: outlineTree,
      matching: find.text('Unsaved heading'),
    );
    expect(target, findsOneWidget);
    expect(
      find.descendant(of: outlineTree, matching: find.text('Saved heading')),
      findsNothing,
    );

    editorList().itemScrollController!.jumpTo(
      index: editorList().itemCount - 1,
    );
    await tester.pump();
    expect(editorFieldWithText('Unsaved heading'), findsNothing);

    await tester.tap(target);
    await tester.pumpAndSettle();

    expect(editorFieldWithText('Unsaved heading'), findsOneWidget);
    final viewportBounds = tester.getRect(editorScroll);
    final headingBounds = tester.getRect(editorFields.first);
    expect(headingBounds.bottom, greaterThan(viewportBounds.top));
    expect(headingBounds.top, lessThan(viewportBounds.bottom));
  });

  testWidgets('untitled outline navigates before the first save', (
    tester,
  ) async {
    const unsaved = '''
# New document

Draft paragraph.

## Unsaved target
''';
    final service = _StartupWorkspaceService();
    final settingsStore = _MemorySettingsStore()
      ..value = AppSettings.defaults()
          .copyWith(
            autoSave: false,
            validateOnEdit: false,
            documentViewMode: DocumentViewModePreference.source,
          )
          .toJson();
    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(settingsStore),
        workspaceServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BusyMarkApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.createMarkdownFile));
    await tester.pumpAndSettle();
    final sourceField = find.descendant(
      of: find.byType(BusyMarkSourceEditor),
      matching: find.byType(TextField),
    );
    expect(sourceField, findsOneWidget);
    await tester.enterText(sourceField, unsaved);
    await tester.pump();

    expect(
      container.read(workspaceControllerProvider).workspace?.activeFilePath,
      isNull,
    );
    final outlineTree = find.byKey(
      const ValueKey('workspace-sidebar-outline-tree'),
    );
    final target = find.descendant(
      of: outlineTree,
      matching: find.text('Unsaved target'),
    );
    expect(target, findsOneWidget);

    await tester.tap(target);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final controller = tester.widget<TextField>(sourceField).controller!;
    expect(
      controller.selection,
      TextSelection.collapsed(offset: unsaved.indexOf('## Unsaved target')),
    );
    expect(service.saveCount, 0);
  });

  testWidgets('preview tolerates duplicate heading anchors', (tester) async {
    const startupPath = '/tmp/duplicate-headings.md';
    const source = '''
# Title

## First {id="same"}

## Second {id="same"}
''';
    final service = _SearchWorkspaceService(source);
    final settingsStore = _MemorySettingsStore()
      ..value = AppSettings.defaults()
          .copyWith(documentViewMode: DocumentViewModePreference.preview)
          .toJson();
    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(settingsStore),
        workspaceServiceProvider.overrideWithValue(service),
        startupPathProvider.overrideWithValue(startupPath),
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
      if (find
          .textContaining('Second', findRichText: true)
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }

    expect(tester.takeException(), isNull);
    expect(find.textContaining('First', findRichText: true), findsWidgets);
    expect(find.textContaining('Second', findRichText: true), findsWidgets);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('workspace-sidebar-primary-label')),
        matching: find.text('duplicate-headings.md'),
      ),
      findsOneWidget,
    );
    final outlineTree = find.byKey(
      const ValueKey('workspace-sidebar-outline-tree'),
    );
    expect(
      find.descendant(of: outlineTree, matching: find.text('Title')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: outlineTree, matching: find.text('First')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: outlineTree, matching: find.text('Second')),
      findsOneWidget,
    );
  });

  testWidgets('Reading opens an unindexed sibling document link', (
    tester,
  ) async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.defaultRouteNameTestValue = '/workspace';
    addTearDown(() {
      binding.platformDispatcher.defaultRouteNameTestValue = '/';
    });
    final directory = Directory.systemTemp.createTempSync(
      'busymark_reading_sibling_link_',
    );
    addTearDown(() {
      directory.deleteSync(recursive: true);
    });
    final readme = File(p.join(directory.path, 'README.md'))
      ..writeAsStringSync('[Open guide](guide.md)\n');
    final guide = File(p.join(directory.path, 'guide.md'))
      ..writeAsStringSync('# Sibling guide\n');
    final settingsStore = _MemorySettingsStore()
      ..value = AppSettings.defaults()
          .copyWith(documentViewMode: DocumentViewModePreference.preview)
          .toJson();
    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(settingsStore),
      ],
    );
    addTearDown(container.dispose);
    await tester.runAsync(() async {
      await container
          .read(appSettingsControllerProvider.notifier)
          .waitUntilLoaded();
      await container
          .read(workspaceControllerProvider.notifier)
          .openPath(readme.path);
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BusyMarkApp(),
      ),
    );
    for (var index = 0; index < 30; index += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text('Open guide').evaluate().isNotEmpty) {
        break;
      }
    }

    final initialWorkspace = container
        .read(workspaceControllerProvider)
        .workspace!;
    expect(initialWorkspace.kind, WorkspaceKind.singleMarkdown);
    expect(initialWorkspace.files.map((file) => file.absolutePath), [
      readme.path,
    ]);
    expect(
      find.byKey(const ValueKey('preview-document-scroll')),
      findsOneWidget,
    );

    final linkText = tester.widget<Text>(find.text('Open guide'));
    final linkRecognizer = _firstTapRecognizer(linkText.textSpan!);
    expect(linkRecognizer?.onTap, isNotNull);
    await tester.runAsync(() async {
      linkRecognizer!.onTap!();
      for (var index = 0; index < 100; index += 1) {
        if (container
                .read(workspaceControllerProvider)
                .workspace
                ?.activeFilePath ==
            guide.path) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    await tester.pump();

    expect(find.text(l10n.linkTargetNotFound('guide.md')), findsNothing);
    expect(find.text(l10n.cannotOpenFileTypeInEditor), findsNothing);
    expect(container.read(workspaceControllerProvider).message, isNull);
    expect(
      container.read(workspaceControllerProvider).workspace?.activeFilePath,
      guide.path,
    );
    expect(
      container.read(workspaceControllerProvider).activeText,
      '# Sibling guide\n',
    );
  });

  testWidgets('Reading linked block and inline images open their targets', (
    tester,
  ) async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.defaultRouteNameTestValue = '/workspace';
    addTearDown(() {
      binding.platformDispatcher.defaultRouteNameTestValue = '/';
    });
    const rootPath = '/tmp/busymark-linked-images';
    const readmePath = '$rootPath/README.md';
    const blockTargetPath = '$rootPath/block-guide.md';
    const inlineTargetPath = '$rootPath/inline-guide.md';
    const source = '''
[![Block logo](block-logo.png)](block-guide.md)

Before [![Inline logo](inline-logo.png)](inline-guide.md) after.
''';
    final parsed = const MarkdownParser().parse(
      filePath: readmePath,
      source: source,
    );
    final workspace = Workspace(
      id: readmePath,
      rootPath: rootPath,
      kind: WorkspaceKind.singleMarkdown,
      openedAt: DateTime(2026),
      activeFilePath: readmePath,
      openFilePaths: const [readmePath],
      files: [
        for (final path in const [
          readmePath,
          blockTargetPath,
          inlineTargetPath,
        ])
          DocumentFile(
            absolutePath: path,
            relativePath: p.basename(path),
            kind: DocumentKind.markdown,
            size: 1,
            lastModified: DateTime(2026),
          ),
      ],
      diagnostics: parsed.diagnostics,
      markdown: parsed,
    );
    final controller = _MutableWorkspaceController(
      WorkspaceState(
        workspace: workspace,
        activeText: source,
        preview: const MarkdownPreviewBuilder().build(parsed),
      ),
    );
    final settingsStore = _MemorySettingsStore()
      ..value = AppSettings.defaults()
          .copyWith(documentViewMode: DocumentViewModePreference.preview)
          .toJson();
    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(settingsStore),
        workspaceControllerProvider.overrideWith(() => controller),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BusyMarkApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MarkdownImageView), findsNWidgets(2));
    for (final (destination, expectedPath) in const [
      ('block-guide.md', blockTargetPath),
      ('inline-guide.md', inlineTargetPath),
    ]) {
      await tester.tap(
        find.byKey(ValueKey('preview-linked-image-$destination')),
      );
      await tester.pump();
      expect(controller.openedFilePath, expectedPath);
    }
  });

  testWidgets('new empty document leaves remembered preview mode for editor', (
    tester,
  ) async {
    final settingsStore = _MemorySettingsStore()
      ..value = AppSettings.defaults()
          .copyWith(documentViewMode: DocumentViewModePreference.preview)
          .toJson();
    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(settingsStore),
        workspaceServiceProvider.overrideWithValue(_StartupWorkspaceService()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BusyMarkApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.createMarkdownFile));
    await tester.pumpAndSettle();

    expect(
      container.read(appSettingsControllerProvider).documentViewMode,
      DocumentViewModePreference.editor,
    );
    expect(
      find.byKey(const ValueKey('wysiwyg-document-scroll')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('preview-document-scroll')), findsNothing);
  });

  testWidgets('blocked remote image prompt allows the current workspace', (
    tester,
  ) async {
    const startupPath = '/tmp/remote-image.md';
    final service = _SearchWorkspaceService(
      '![Remote](https://example.com/logo.png)\n',
    );
    final settingsStore = _MemorySettingsStore()
      ..value = AppSettings.defaults()
          .copyWith(documentViewMode: DocumentViewModePreference.preview)
          .toJson();
    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(settingsStore),
        workspaceServiceProvider.overrideWithValue(service),
        startupPathProvider.overrideWithValue(startupPath),
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
      if (find.text(l10n.remoteImageBlocked).evaluate().isNotEmpty) {
        break;
      }
    }

    expect(find.text(l10n.remoteImageBlocked), findsOneWidget);

    await tester.tap(find.text(l10n.remoteImageBlocked));
    await tester.pumpAndSettle();

    expect(find.text(l10n.remoteImagesBlockedTitle), findsOneWidget);

    await tester.tap(find.text(l10n.loadRemoteImagesForWorkspace));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      settingsStore.value['remoteImageAllowedWorkspacePaths'],
      contains(startupPath),
    );
  });

  testWidgets('Ctrl+O open chooser lists recent workspaces', (tester) async {
    const startupPath = 'test/fixtures/markdown/basic.md';
    const recentPath = '/tmp/busymark-recent-docs';
    final service = _StartupWorkspaceService();
    final settingsStore = _MemorySettingsStore()
      ..value = AppSettings.defaults()
          .copyWith(
            recentWorkspaces: [
              RecentWorkspace(
                path: recentPath,
                kind: 'markdownFolder',
                lastOpenedAt: DateTime(2026, 1, 2),
              ),
            ],
          )
          .toJson();
    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(settingsStore),
        workspaceServiceProvider.overrideWithValue(service),
        startupPathProvider.overrideWithValue(startupPath),
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

    expect(service.openedPath, startupPath);
    expect(find.text(l10n.openMarkdownFile), findsNothing);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyO);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyO);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(find.text(l10n.openMarkdownFile), findsOneWidget);
    expect(find.text(l10n.recent), findsOneWidget);
    expect(find.text('busymark-recent-docs'), findsOneWidget);

    await tester.tap(find.text('busymark-recent-docs'));
    await tester.pumpAndSettle();

    expect(service.openedPath, recentPath);
    expect(find.text(l10n.openMarkdownFile), findsNothing);
  });

  testWidgets('recent workspace menus support pointer and keyboard actions', (
    tester,
  ) async {
    const recentPath = '/tmp/busymark-recent-actions';
    String? clipboardText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          final arguments = call.arguments as Map<Object?, Object?>;
          clipboardText = arguments['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });
    final settingsStore = _MemorySettingsStore()
      ..value = AppSettings.defaults()
          .copyWith(
            recentWorkspaces: [
              RecentWorkspace(
                path: recentPath,
                kind: 'markdownFolder',
                lastOpenedAt: DateTime(2026, 1, 2),
              ),
            ],
          )
          .toJson();
    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(settingsStore),
        startupPathProvider.overrideWithValue(null),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BusyMarkApp(),
      ),
    );
    await container
        .read(appSettingsControllerProvider.notifier)
        .waitUntilLoaded();
    await tester.pumpAndSettle();

    final recentLabel = find.text('busymark-recent-actions');
    expect(recentLabel, findsOneWidget);
    final recentRow = find
        .ancestor(of: recentLabel, matching: find.byType(InkWell))
        .first;
    final menuButton = find.descendant(
      of: recentRow,
      matching: find.byTooltip(l10n.actions),
    );
    expect(menuButton, findsOneWidget);

    await tester.tap(menuButton);
    await tester.pumpAndSettle();
    expect(find.text(l10n.openInFiles), findsOneWidget);
    expect(find.text(l10n.copyPath), findsOneWidget);
    expect(find.text(l10n.removeFromRecent), findsOneWidget);

    await tester.tap(find.text(l10n.copyPath));
    await tester.pumpAndSettle();
    expect(clipboardText, recentPath);

    await tester.tap(recentRow, buttons: kSecondaryMouseButton);
    await tester.pumpAndSettle();
    expect(find.text(l10n.removeFromRecent), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.f10);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.f10);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();
    expect(find.text(l10n.removeFromRecent), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    await tester.tap(recentRow, buttons: kSecondaryMouseButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.removeFromRecent));
    await tester.pumpAndSettle();

    expect(recentLabel, findsNothing);
    expect(
      container.read(appSettingsControllerProvider).recentWorkspaces,
      isEmpty,
    );
    expect(AppSettings.fromJson(settingsStore.value).recentWorkspaces, isEmpty);
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
              allowRemoteImages: true,
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
    'shared Markdown image renderer blocks remote images by default',
    (tester) async {
      var promptCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MarkdownImageView(
              source: 'https://example.com/logo.png',
              alt: 'Logo',
              activeFilePath: 'doc.md',
              workspaceRoot: null,
              writersideRoot: null,
              imagesDir: 'images',
              allowRemoteImages: false,
              onRemoteImageBlocked: () {
                promptCount += 1;
              },
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text(l10n.remoteImageBlocked), findsOneWidget);
      expect(find.byType(Image), findsNothing);

      await tester.tap(find.text(l10n.remoteImageBlocked));
      await tester.pump();

      expect(promptCount, 1);
    },
  );

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
                allowRemoteImages: true,
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
    'shared Markdown image renderer resolves absolute paths outside workspace',
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
                allowRemoteImages: true,
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(Image), findsOneWidget);
        expect(find.textContaining(image.path), findsNothing);
      } finally {
        workspace.deleteSync(recursive: true);
        outside.deleteSync(recursive: true);
      }
    },
  );

  testWidgets('shared Markdown image renderer resolves Snap real-home paths', (
    tester,
  ) async {
    final root = Directory.systemTemp.createTempSync(
      'busymark_preview_image_snap_home_',
    );
    try {
      final realHome = Directory(p.join(root.path, 'real-home'))..createSync();
      final snapHome = Directory(p.join(root.path, 'snap-home'))..createSync();
      final downloads = Directory(p.join(realHome.path, 'Downloads'))
        ..createSync();
      File(p.join(downloads.path, 'example.jpg')).writeAsBytesSync(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAFgwJ/l8Kz3wAAAABJRU5ErkJggg==',
        ),
      );
      debugLocalImageEnvironmentOverride = {
        'SNAP_REAL_HOME': realHome.path,
        'HOME': snapHome.path,
      };
      addTearDown(() {
        debugLocalImageEnvironmentOverride = null;
      });

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: MarkdownImageView(
              source: '~/Downloads/example.jpg',
              alt: 'Example',
              activeFilePath: 'Untitled.md',
              workspaceRoot: null,
              writersideRoot: null,
              imagesDir: 'images',
              allowRemoteImages: true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Image), findsOneWidget);
      expect(find.textContaining('~/Downloads/example.jpg'), findsNothing);
    } finally {
      debugLocalImageEnvironmentOverride = null;
      root.deleteSync(recursive: true);
    }
  });

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
              allowRemoteImages: true,
            ),
          ),
        ),
      );

      expect(find.byType(SvgPicture), findsNothing);
      await _pumpUntilFound(tester, find.byType(SvgPicture));

      expect(find.textContaining('logo.svg'), findsNothing);
      expect(find.byType(SvgPicture), findsOneWidget);
    } finally {
      temp.deleteSync(recursive: true);
    }
  });

  testWidgets('shared Markdown image renderer rejects oversized local SVGs', (
    tester,
  ) async {
    final temp = Directory.systemTemp.createTempSync(
      'busymark_preview_svg_oversized_',
    );
    try {
      final padding = ''.padRight(1024 * 1024, 'x');
      File('${temp.path}/oversized.svg').writeAsStringSync(
        '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16">'
        '<!--$padding--><rect width="16" height="16" fill="#3584e4"/>'
        '</svg>',
      );
      final markdown = File('${temp.path}/image.md')
        ..writeAsStringSync('# Image\n\n![Large](oversized.svg)\n');

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MarkdownImageView(
              source: 'oversized.svg',
              alt: 'Large',
              activeFilePath: markdown.path,
              workspaceRoot: temp.path,
              writersideRoot: null,
              imagesDir: 'images',
              allowRemoteImages: true,
            ),
          ),
        ),
      );
      await _pumpUntilFound(tester, find.textContaining('oversized.svg'));

      expect(find.byType(SvgPicture), findsNothing);
      expect(find.textContaining('oversized.svg'), findsOneWidget);
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
                allowRemoteImages: true,
              ),
            ),
          ),
        );
        await _pumpUntilFound(tester, find.byType(SvgPicture));

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
                allowRemoteImages: true,
              ),
            ),
          ),
        ),
      );
      await _pumpUntilFound(tester, find.byType(SvgPicture));

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

  testWidgets(
    'workspace search awaits non-active file reads without blocking builds',
    (tester) async {
      final service = _DeferredWorkspaceSearchService();
      final settingsStore = _MemorySettingsStore()
        ..value = AppSettings.defaults()
            .copyWith(documentViewMode: DocumentViewModePreference.preview)
            .toJson();
      final container = ProviderContainer(
        overrides: [
          linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
          localSettingsStoreProvider.overrideWithValue(settingsStore),
          workspaceServiceProvider.overrideWithValue(service),
          startupPathProvider.overrideWithValue(
            _DeferredWorkspaceSearchService.activePath,
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
      await tester.pump(const Duration(milliseconds: 150));

      expect(service.searchReadCount, 1);
      expect(
        find.byKey(const ValueKey('workspace-search-progress')),
        findsOneWidget,
      );

      service.completeSearchRead('Delayed needle result');
      await tester.pump();
      await tester.pump();

      expect(
        find.byKey(const ValueKey('workspace-search-progress')),
        findsNothing,
      );
      expect(find.text('Delayed needle result'), findsOneWidget);

      final settings = container.read(appSettingsControllerProvider);
      await container
          .read(appSettingsControllerProvider.notifier)
          .setWordWrap(!settings.wordWrap);
      await tester.pump();

      expect(service.searchReadCount, 1);
      expect(find.text('Delayed needle result'), findsOneWidget);
    },
  );

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
    await tester.pump(const Duration(milliseconds: 150));
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
    await tester.pumpAndSettle();
    final secondRect = _rightmostTextRect(tester, 'Second needle target');
    expect(secondRect.top, greaterThan(40));
    expect(secondRect.bottom, lessThan(800));

    await _tapLeftmostText(tester, 'First needle target');
    await tester.pump();
    await tester.pumpAndSettle();
    final firstRect = _rightmostTextRect(tester, 'First needle target');
    expect(firstRect.top, greaterThan(40));
    expect(firstRect.bottom, lessThan(800));

    await _tapLeftmostText(tester, 'Second needle target');
    await _tapLeftmostText(tester, 'First needle target');
    await tester.pump();
    await tester.pumpAndSettle();
    final repeatedFirstRect = _rightmostTextRect(tester, 'First needle target');
    expect(repeatedFirstRect.top, greaterThan(40));
    expect(repeatedFirstRect.bottom, lessThan(800));
  });

  testWidgets('preview lazily builds large documents', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final source = List.generate(
      1200,
      (index) => 'Preview paragraph ${index + 1}',
    ).join('\n\n');
    final settingsStore = _MemorySettingsStore()
      ..value = AppSettings.defaults()
          .copyWith(documentViewMode: DocumentViewModePreference.preview)
          .toJson();
    final service = _SearchWorkspaceService(source);
    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(settingsStore),
        workspaceServiceProvider.overrideWithValue(service),
        startupPathProvider.overrideWithValue('/tmp/large-preview.md'),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BusyMarkApp(),
      ),
    );
    for (var i = 0; i < 30; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find
          .byKey(const ValueKey('preview-document-scroll'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }

    final previewList = tester.widget<ScrollablePositionedList>(
      find.byKey(const ValueKey('preview-document-scroll')),
    );
    expect(previewList.itemCount, 1200);
    expect(find.text('Preview paragraph 1200'), findsNothing);
    expect(
      find.textContaining('Preview paragraph').evaluate().length,
      lessThan(80),
    );

    previewList.itemScrollController!.jumpTo(index: 1199);
    await tester.pump();
    expect(find.text('Preview paragraph 1200'), findsOneWidget);
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
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump();

    await _tapLeftmostText(tester, 'second code needle target');
    await tester.pump();
    await tester.pumpAndSettle();
    final secondRect = _rightmostTextRect(tester, 'second code needle target');
    expect(secondRect.top, greaterThan(40));
    expect(secondRect.bottom, lessThan(800));

    await _tapLeftmostText(tester, 'first code needle target');
    await tester.pump();
    await tester.pumpAndSettle();
    final firstRect = _rightmostTextRect(tester, 'first code needle target');
    expect(firstRect.top, greaterThan(40));
    expect(firstRect.bottom, lessThan(800));
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
    await tester.pump(const Duration(milliseconds: 150));
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

  testWidgets('Editor and Preview share ordered list styling and geometry', (
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
          .copyWith(documentViewMode: DocumentViewModePreference.editor)
          .toJson();
    final service = _SearchWorkspaceService(
      '# Title\n\n'
      '1. First item\n'
      '2. Second item\n'
      '\n'
      'After list paragraph.\n',
    );
    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(settingsStore),
        workspaceServiceProvider.overrideWithValue(service),
        startupPathProvider.overrideWithValue('/tmp/list-spacing.md'),
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
      if (find.byType(BusyMarkDocumentListMarker).evaluate().length == 2) {
        break;
      }
    }

    final editorFirst = _rightmostTextRect(tester, 'First item');
    final editorSecond = _rightmostTextRect(tester, 'Second item');
    final editorAfter = _rightmostTextRect(tester, 'After list paragraph.');
    final editorMarkers = find.byType(BusyMarkDocumentListMarker);
    expect(editorMarkers, findsNWidgets(2));
    final editorMarkerRect = tester.getRect(editorMarkers.first);
    final editorMarkerText = tester.widget<Text>(
      find.descendant(of: editorMarkers.first, matching: find.text('1.')),
    );
    final editorMarkerColors = BusyMarkSurfaceColors.of(
      tester.element(editorMarkers.first),
    );
    final editorItemGap = editorSecond.top - editorFirst.bottom;
    final editorAfterListGap = editorAfter.top - editorSecond.bottom;

    expect(editorMarkerRect.width, greaterThanOrEqualTo(24));
    expect(editorMarkerText.style?.color, editorMarkerColors.foreground);
    expect(editorMarkerText.style?.fontWeight, FontWeight.w600);
    expect(editorAfterListGap, greaterThan(editorItemGap + BusyMarkSpacing.xs));

    container
        .read(workspaceControllerProvider.notifier)
        .updateActiveEditorMode(DocumentViewModePreference.preview);
    await container
        .read(appSettingsControllerProvider.notifier)
        .setDocumentViewMode(DocumentViewModePreference.preview);
    await tester.pump(const Duration(milliseconds: 100));

    final previewFirst = _rightmostTextRect(tester, 'First item');
    final previewSecond = _rightmostTextRect(tester, 'Second item');
    final previewAfter = _rightmostTextRect(tester, 'After list paragraph.');
    final previewMarkers = find.byType(BusyMarkDocumentListMarker);
    expect(previewMarkers, findsNWidgets(2));
    final previewMarkerRect = tester.getRect(previewMarkers.first);
    final previewMarkerText = tester.widget<Text>(
      find.descendant(of: previewMarkers.first, matching: find.text('1.')),
    );
    final previewItemGap = previewSecond.top - previewFirst.bottom;
    final previewAfterListGap = previewAfter.top - previewSecond.bottom;

    expect(previewFirst.left, closeTo(editorFirst.left, 0.1));
    expect(previewSecond.left, closeTo(editorSecond.left, 0.1));
    expect(previewAfter.left, closeTo(editorAfter.left, 0.1));
    expect(previewMarkerRect.left, closeTo(editorMarkerRect.left, 0.1));
    expect(previewMarkerRect.width, editorMarkerRect.width);
    expect(previewMarkerText.style, editorMarkerText.style);
    expect(previewItemGap, closeTo(editorItemGap, 0.1));
    expect(previewAfterListGap, closeTo(editorAfterListGap, 0.1));
  });

  testWidgets('preview renders nested list children', (tester) async {
    final settingsStore = _MemorySettingsStore()
      ..value = AppSettings.defaults()
          .copyWith(documentViewMode: DocumentViewModePreference.preview)
          .toJson();
    final service = _SearchWorkspaceService(
      '* Элемент списка А\n'
      '  * Вложенный элемент (нужно сделать 2 или 4 пробела)\n'
      '  * Еще один вложенный элемент\n'
      '  * **Ссылка:** [Яндекс](https://yandex.ru)\n',
    );
    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(settingsStore),
        workspaceServiceProvider.overrideWithValue(service),
        startupPathProvider.overrideWithValue('/tmp/nested-list.md'),
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

    expect(find.textContaining('Элемент списка А'), findsOneWidget);
    expect(
      find.textContaining('Вложенный элемент (нужно сделать 2 или 4 пробела)'),
      findsOneWidget,
    );
    expect(find.textContaining('Еще один вложенный элемент'), findsOneWidget);
    expect(find.textContaining('Ссылка:'), findsOneWidget);
    expect(find.textContaining('Яндекс'), findsOneWidget);
  });

  testWidgets('preview renders raw HTML table as table cells', (tester) async {
    final settingsStore = _MemorySettingsStore()
      ..value = AppSettings.defaults()
          .copyWith(documentViewMode: DocumentViewModePreference.preview)
          .toJson();
    final service = _SearchWorkspaceService(
      '<table>\n'
      '  <tr><th>Name</th><th>Value</th></tr>\n'
      '  <tr><td>A</td></tr>\n'
      '</table>\n',
    );
    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(settingsStore),
        workspaceServiceProvider.overrideWithValue(service),
        startupPathProvider.overrideWithValue('/tmp/raw-html-table.md'),
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

    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Value'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.textContaining('<table>'), findsNothing);
  });

  testWidgets('Reading applies Markdown table column alignment', (
    tester,
  ) async {
    final settingsStore = _MemorySettingsStore()
      ..value = AppSettings.defaults()
          .copyWith(documentViewMode: DocumentViewModePreference.preview)
          .toJson();
    final service = _SearchWorkspaceService(
      '| Center heading | Right heading |\n'
      '| :---: | ---: |\n'
      '| Center value | Right value |\n',
    );
    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(settingsStore),
        workspaceServiceProvider.overrideWithValue(service),
        startupPathProvider.overrideWithValue('/tmp/aligned-table.md'),
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
      if (find.text('Center heading').evaluate().isNotEmpty) {
        break;
      }
    }

    for (final text in const ['Center heading', 'Center value']) {
      expect(tester.widget<Text>(find.text(text)).textAlign, TextAlign.center);
    }
    for (final text in const ['Right heading', 'Right value']) {
      expect(tester.widget<Text>(find.text(text)).textAlign, TextAlign.right);
    }
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
    await tester.pump(const Duration(milliseconds: 150));
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

  testWidgets('Ctrl+S saves source edits from an untitled Markdown document', (
    tester,
  ) async {
    final temp = Directory.systemTemp.createTempSync('busymark_untitled_save_');
    final saveFile = File('${temp.path}/created.md');
    const editedText = '# Created\n\nDraft text.';
    const fileSelectorChannel = MethodChannel(
      'plugins.flutter.io/file_selector',
    );
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      fileSelectorChannel,
      (call) async {
        expect(call.method, 'getSavePath');
        final args = call.arguments as Map<Object?, Object?>;
        expect(args['suggestedName'], l10n.untitledMarkdownFileName);
        return saveFile.path;
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

    final service = _StartupWorkspaceService();
    final settingsStore = _MemorySettingsStore()
      ..value = AppSettings.defaults()
          .copyWith(documentViewMode: DocumentViewModePreference.source)
          .toJson();
    final container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(settingsStore),
        workspaceServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BusyMarkApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.createMarkdownFile));
    await tester.pumpAndSettle();
    for (var i = 0; i < 10; i += 1) {
      if (find.byType(TextField).evaluate().isNotEmpty) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 100));
    }

    final sourceField = find.byType(TextField).last;
    await tester.tap(sourceField);
    await tester.enterText(sourceField, editedText);
    await tester.pump();

    expect(container.read(workspaceControllerProvider).activeText, editedText);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyS);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyS);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(service.saveCount, 1);
    expect(service.savedPath, saveFile.path);
    expect(service.savedText, editedText);
    expect(container.read(workspaceControllerProvider).activeText, editedText);
    expect(
      tester.widget<TextField>(find.byType(TextField).last).controller?.text,
      editedText,
    );
  });
}

RenderEditable? _findRenderEditable(RenderObject root) {
  if (root is RenderEditable) {
    return root;
  }
  RenderEditable? result;
  root.visitChildren((child) {
    result ??= _findRenderEditable(child);
  });
  return result;
}

List<int> _visualLineEndOffsets(
  String text,
  List<TextBox> Function(TextSelection selection) boxesForSelection,
) {
  final ends = <int>[];
  double? previousTop;
  for (var offset = 0; offset < text.length; offset += 1) {
    final boxes = boxesForSelection(
      TextSelection(baseOffset: offset, extentOffset: offset + 1),
    );
    if (boxes.isEmpty) {
      continue;
    }
    final top = boxes.first.top;
    final priorTop = previousTop;
    if (priorTop != null && (top - priorTop).abs() > 0.01) {
      ends.add(offset);
    }
    previousTop = top;
  }
  ends.add(text.length);
  return ends;
}

({
  Finder finder,
  Size size,
  Color? color,
  double? glyphSize,
  ValueChanged<bool>? onTaskChanged,
})
_taskMarkerVisual(WidgetTester tester, {required bool checked}) {
  final markerFinder = find.byWidgetPredicate(
    (widget) => widget is BusyMarkDocumentListMarker && widget.task == checked,
  );
  expect(markerFinder, findsOneWidget);
  final marker = tester.widget<BusyMarkDocumentListMarker>(markerFinder);
  final iconFinder = find.descendant(
    of: markerFinder,
    matching: find.byIcon(
      checked ? BusyMarkGlyphs.checkedBox : BusyMarkGlyphs.task,
    ),
  );
  expect(iconFinder, findsOneWidget);
  final icon = tester.widget<Icon>(iconFinder);
  final iconTheme = IconTheme.of(tester.element(iconFinder));
  return (
    finder: markerFinder,
    size: tester.getSize(markerFinder),
    color: icon.color ?? iconTheme.color,
    glyphSize: icon.size ?? iconTheme.size,
    onTaskChanged: marker.onTaskChanged,
  );
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 20 && finder.evaluate().isEmpty; i += 1) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
    await tester.pump();
  }
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

TextSpan _richTextSpanContaining(WidgetTester tester, String text) {
  for (final richText in tester.widgetList<RichText>(find.byType(RichText))) {
    final span = richText.text;
    if (span is TextSpan && span.toPlainText().contains(text)) {
      return span;
    }
  }
  throw StateError('No rich text contains "$text".');
}

TextStyle? _textSpanStyleForText(TextSpan span, String text) {
  for (final child in _flattenTextSpans(span)) {
    if (child.text == text) {
      return child.style;
    }
  }
  throw StateError('No text span equals "$text".');
}

Iterable<TextSpan> _flattenTextSpans(InlineSpan span) sync* {
  if (span is TextSpan) {
    yield span;
    for (final child in span.children ?? const <InlineSpan>[]) {
      yield* _flattenTextSpans(child);
    }
  }
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

TapGestureRecognizer? _firstTapRecognizer(InlineSpan span) {
  if (span is! TextSpan) {
    return null;
  }
  final recognizer = span.recognizer;
  if (recognizer is TapGestureRecognizer) {
    return recognizer;
  }
  for (final child in span.children ?? const <InlineSpan>[]) {
    final nested = _firstTapRecognizer(child);
    if (nested != null) {
      return nested;
    }
  }
  return null;
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

class _MutableWorkspaceController extends WorkspaceController {
  _MutableWorkspaceController(this.initialState);

  final WorkspaceState initialState;
  WritersideTopicCreateRequest? createdTopicRequest;
  String? createdTopicTreePath;
  WritersideTopicCreatePlacement? movedTopicPlacement;
  List<int>? movedTopicSourcePath;
  List<int>? movedTopicReferencePath;
  WritersideTopicRemovalMode? analyzedRemovalMode;
  String? selectedWritersideModuleId;
  String? selectedWritersideInstanceId;
  String? openedFilePath;

  @override
  WorkspaceState build() => initialState;

  @override
  Future<void> validateActive() async {}

  @override
  Future<bool> selectWritersideContext({
    required String moduleId,
    String? instanceId,
  }) async {
    selectedWritersideModuleId = moduleId;
    selectedWritersideInstanceId = instanceId;
    return true;
  }

  @override
  Future<bool> createWritersideTopic(
    WritersideTopicCreateRequest request, {
    String? instanceTreePath,
  }) async {
    createdTopicRequest = request;
    createdTopicTreePath = instanceTreePath;
    return true;
  }

  @override
  Future<bool> moveWritersideTocEntry({
    required String treePath,
    required List<int> sourcePath,
    required WritersideTopicCreatePlacement placement,
    required List<int>? referencePath,
    WritersideTocNodeIdentity? sourceIdentity,
    WritersideTocNodeIdentity? referenceIdentity,
  }) async {
    movedTopicPlacement = placement;
    movedTopicSourcePath = sourcePath;
    movedTopicReferencePath = referencePath;
    final workspace = state.workspace!;
    final module = workspace.writersideModule!;
    final instances = <WritersideInstance>[];
    for (final instance in module.instances) {
      if (!p.equals(instance.sourceTreePath, treePath)) {
        instances.add(instance);
        continue;
      }
      final roots = [...instance.tocRoots];
      final sourceIndex = sourcePath.single;
      final source = roots.removeAt(sourceIndex);
      var referenceIndex = referencePath!.single;
      if (sourceIndex < referenceIndex) {
        referenceIndex -= 1;
      }
      final reference = roots[referenceIndex];
      roots[referenceIndex] = TocNode(
        topicFileName: reference.topicFileName,
        href: reference.href,
        tocTitle: reference.tocTitle,
        id: reference.id,
        hidden: reference.hidden,
        children: [...reference.children, source],
        span: reference.span,
      );
      instances.add(
        WritersideInstance(
          id: instance.id,
          name: instance.name,
          sourceTreePath: instance.sourceTreePath,
          startPage: instance.startPage,
          status: instance.status,
          isLibrary: instance.isLibrary,
          tocRoots: roots,
          diagnostics: instance.diagnostics,
        ),
      );
    }
    final updatedModule = WritersideModule(
      rootPath: module.rootPath,
      config: module.config,
      instances: instances,
      topics: module.topics,
      variables: module.variables,
      categories: module.categories,
      diagnostics: module.diagnostics,
      validatedImageDirs: module.validatedImageDirs,
    );
    state = state.copyWith(
      workspace: workspace.copyWith(writersideModule: updatedModule),
    );
    return true;
  }

  @override
  Future<WritersideTopicRemovalAnalysis?> analyzeWritersideTopicRemoval({
    required String topicPath,
    required WritersideTopicRemovalMode mode,
    String? treePath,
    List<int>? nodePath,
  }) async {
    analyzedRemovalMode = mode;
    final topic = state.workspace!.writersideModule!.topics.singleWhere(
      (candidate) => p.equals(candidate.filePath, topicPath),
    );
    return WritersideTopicRemovalAnalysis(
      mode: mode,
      moduleRoot: state.workspace!.rootPath,
      topicPath: topicPath,
      topicFileName: topic.fileName,
      topicTitle: topic.title,
      oldWebFileName: '${p.basenameWithoutExtension(topic.fileName)}.html',
      selectedTreePath: treePath,
      selectedNodePath: nodePath,
      childCount: 0,
      isStartPage: false,
      usages: const [],
      redirectTargets: const [],
      fingerprint: 'widget-test',
    );
  }

  @override
  Future<bool> openActiveFile(String path) async {
    openedFilePath = path;
    return true;
  }

  void replaceWorkspace(Workspace workspace) {
    state = state.copyWith(workspace: workspace);
  }
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
    const source = '# Basic Markdown\n';
    openedPath = path;
    final markdown = markdownParser.parse(filePath: path, source: source);
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
      diagnostics: markdown.diagnostics,
      markdown: markdown,
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
  Future<bool> pathExists(String path) async => false;

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

  @override
  Future<WorkspaceFileSnapshot> saveNewText(String path, String text) {
    return saveText(path, text);
  }

  @override
  Future<WorkspaceFileSnapshot> saveTextReplacingPath(
    String path,
    String text,
  ) {
    return saveText(path, text);
  }
}

class _TabbedWorkspaceService extends WorkspaceService {
  _TabbedWorkspaceService({required this.rootPath, required this.paths});

  final String rootPath;
  final List<String> paths;
  final _sources = <String, String>{};
  String? savedPath;
  String? savedText;
  var saveCount = 0;

  @override
  Future<Workspace> openPath(String path) async {
    final files = [
      for (final filePath in paths)
        DocumentFile(
          absolutePath: filePath,
          relativePath: _workspaceRelativePath(rootPath, filePath),
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
    final text = _sources[path] ?? _sourceFor(path);
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
    _sources[path] = text;
    return WorkspaceFileSnapshot(
      modifiedAt: DateTime(2026, 1, 2),
      size: text.length,
      contentHash: text,
    );
  }

  String _sourceFor(String path) => '# ${path.split('/').last}\n';
}

String _workspaceRelativePath(String rootPath, String filePath) {
  final prefix = '$rootPath/';
  return filePath.startsWith(prefix)
      ? filePath.substring(prefix.length)
      : filePath.split('/').last;
}

void _expectTextWithVcsColor(
  WidgetTester tester,
  String text,
  BusyMarkVcsFileColor color,
) {
  final elements = find.text(text).evaluate().toList();
  expect(elements, isNotEmpty);
  final expected = busyMarkVcsFileStatusColor(elements.first, color);
  expect(
    elements.where((element) {
      final widget = element.widget;
      return widget is Text && widget.style?.color == expected;
    }),
    isNotEmpty,
  );
}

GitFileStatus _gitStatusFile(
  GitRepositoryInfo repository,
  String repoRelativePath, {
  required GitFileStatusCategory category,
  GitFileChangeStatus indexStatus = GitFileChangeStatus.unmodified,
  GitFileChangeStatus workTreeStatus = GitFileChangeStatus.modified,
  bool staged = false,
  bool unstaged = true,
  bool untracked = false,
  bool conflicted = false,
}) {
  return GitFileStatus(
    repoRelativePath: repoRelativePath,
    absolutePath: '${repository.rootPath}/$repoRelativePath',
    indexStatus: indexStatus,
    workTreeStatus: workTreeStatus,
    category: category,
    staged: staged,
    unstaged: unstaged,
    untracked: untracked,
    deleted: category == GitFileStatusCategory.deleted,
    renamed: category == GitFileStatusCategory.renamed,
    copied: category == GitFileStatusCategory.copied,
    conflicted: conflicted,
    ignored: category == GitFileStatusCategory.ignored,
  );
}

class _SearchWorkspaceService extends WorkspaceService {
  const _SearchWorkspaceService(this.source, {this.writerside = false});

  final String source;
  final bool writerside;

  @override
  Future<Workspace> openPath(String path) async {
    final markdown = markdownParser.parse(
      filePath: path,
      source: source,
      mode: writerside
          ? MarkdownMode.writersideMarkdown
          : MarkdownMode.commonMark,
    );
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
          kind: writerside
              ? DocumentKind.writersideMarkdownTopic
              : DocumentKind.markdown,
          size: source.length,
          lastModified: DateTime(2026),
        ),
      ],
      diagnostics: markdown.diagnostics,
      markdown: markdown,
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

class _DeferredWorkspaceSearchService extends WorkspaceService {
  _DeferredWorkspaceSearchService();

  static const activePath = '/tmp/busymark-search-active.md';
  static const secondaryPath = '/tmp/busymark-search-secondary.md';
  static const _activeSource = '# Active document\n';

  final Completer<String> _searchRead = Completer<String>();
  int searchReadCount = 0;

  @override
  Future<Workspace> openPath(String path) async {
    final markdown = markdownParser.parse(
      filePath: activePath,
      source: _activeSource,
    );
    return Workspace(
      id: '/tmp/busymark-search-workspace',
      rootPath: '/tmp',
      kind: WorkspaceKind.singleMarkdown,
      openedAt: DateTime(2026),
      activeFilePath: activePath,
      activeFileModifiedAt: DateTime(2026),
      files: [
        DocumentFile(
          absolutePath: activePath,
          relativePath: 'active.md',
          kind: DocumentKind.markdown,
          size: _activeSource.length,
          lastModified: DateTime(2026),
        ),
        DocumentFile(
          absolutePath: secondaryPath,
          relativePath: 'secondary.md',
          kind: DocumentKind.markdown,
          size: 64,
          lastModified: DateTime(2026),
        ),
      ],
      diagnostics: markdown.diagnostics,
      markdown: markdown,
    );
  }

  @override
  Future<String> loadText(String path) {
    if (path == secondaryPath) {
      searchReadCount += 1;
      return _searchRead.future;
    }
    return Future.value(_activeSource);
  }

  @override
  Future<WorkspaceFileLoad> loadTextWithSnapshot(String path) async {
    return WorkspaceFileLoad(
      text: _activeSource,
      snapshot: WorkspaceFileSnapshot(
        modifiedAt: DateTime(2026),
        size: _activeSource.length,
        contentHash: 'deferred-search-active',
      ),
    );
  }

  void completeSearchRead(String source) {
    _searchRead.complete(source);
  }
}

class _PresetGitController extends GitController {
  _PresetGitController(this.initialState);

  final GitState initialState;
  String? loadedFileHistoryPath;
  List<String> stagedPaths = const [];
  int branchLoadCount = 0;
  int compareWithCurrentCount = 0;
  int commitComparisonCount = 0;

  @override
  GitState build() => initialState;

  @override
  void attachWorkspace(Workspace workspace) {
    state = state.copyWith(attachedWorkspace: workspace);
  }

  @override
  Future<void> refresh() async {}

  @override
  Future<List<GitBranch>> loadBranches() async {
    branchLoadCount += 1;
    return state.branches.isEmpty
        ? const [
            GitBranch(name: 'main', current: true),
            GitBranch(name: 'docs', current: false),
          ]
        : state.branches;
  }

  @override
  Future<void> loadFileHistory(String absolutePath) async {
    loadedFileHistoryPath = absolutePath;
    final repositoryRoot = state.repositoryInfo?.rootPath;
    final repoRelativePath =
        repositoryRoot != null && absolutePath.startsWith('$repositoryRoot/')
        ? absolutePath.substring(repositoryRoot.length + 1)
        : absolutePath;
    state = state.copyWith(
      scopedFilePath: repoRelativePath,
      selectedCommitFilePath: null,
      openDiffFilePaths: const [],
      selectedView: GitView.fileHistory,
      fileHistory: GitFileHistoryState(
        currentPath: repoRelativePath,
        entries: [
          GitFileHistoryEntry(
            commit: GitCommitSummary(
              fullHash: '45a2b81a41822ad4171f62205ef996f5752a3bbd',
              shortHash: '45a2b81',
              authorName: 'BusyMark Test',
              authorEmail: 'test@example.invalid',
              authorDate: DateTime(2026),
              subject: 'File history test commit',
              parentHashes: const [],
            ),
            pathAtCommit: repoRelativePath,
            pathInParent: repoRelativePath,
            status: GitDiffFileStatus.modified,
          ),
        ],
      ),
    );
  }

  @override
  Future<void> stageFiles(List<String> repoRelativePaths) async {
    stagedPaths = repoRelativePaths;
  }

  @override
  Future<void> compareFileHistoryWithCurrent() async {
    compareWithCurrentCount += 1;
    state = state.copyWith(
      fileHistory: state.fileHistory.copyWith(
        comparisonType: GitComparisonType.commitVersusCurrent,
      ),
    );
  }

  @override
  Future<void> selectFileHistoryCommit(String hash) async {
    commitComparisonCount += 1;
    state = state.copyWith(
      fileHistory: state.fileHistory.copyWith(
        selectedCommitHash: hash,
        comparisonType: GitComparisonType.commitChange,
      ),
    );
  }
}

GitState _gitFileHistoryDiffState(String rootPath) {
  final repository = GitRepositoryInfo(
    rootPath: rootPath,
    gitDirPath: '$rootPath/.git',
    currentBranch: 'main',
  );
  const hash = '45a2b81a41822ad4171f62205ef996f5752a3bbd';
  final commit = GitCommitSummary(
    fullHash: hash,
    shortHash: '45a2b81',
    authorName: 'BusyMark Test',
    authorEmail: 'test@example.invalid',
    authorDate: DateTime(2026),
    subject: 'File history test commit',
    parentHashes: const ['30af618a6e962623a0098ad6a33b468f33dc49c7'],
  );
  final file = _readmeCodeBlockDiffFile();
  final diff = GitDiff(
    title: 'README.md',
    files: [file],
    rawPatch: '',
    hasBinaryFiles: false,
    fileSnapshots: const {'README.md': '# Readme change\n'},
  );
  return GitState(
    availability: const GitAvailability(
      available: true,
      executablePath: '/usr/bin/git',
      version: '2.50.0',
    ),
    repositoryInfo: repository,
    statusSnapshot: GitStatusSnapshot(
      repositoryInfo: repository,
      files: const [],
    ),
    selectedView: GitView.fileHistory,
    scopedFilePath: 'README.md',
    fileHistory: GitFileHistoryState(
      currentPath: 'README.md',
      entries: [
        GitFileHistoryEntry(
          commit: commit,
          pathAtCommit: 'README.md',
          pathInParent: 'README.md',
          status: GitDiffFileStatus.modified,
        ),
      ],
      selectedCommitHash: hash,
      comparison: GitHistoricalFileComparison(
        oldPath: 'README.md',
        newPath: 'README.md',
        oldContent: '# Readme old\n',
        newContent: '# Readme change\n',
        diff: diff,
      ),
    ),
    selectedCommitFilePath: 'README.md',
    openDiffFilePaths: const ['README.md'],
  );
}

GitState _gitDiffState(String rootPath) {
  final repository = GitRepositoryInfo(
    rootPath: rootPath,
    gitDirPath: '$rootPath/.git',
    currentBranch: 'main',
    upstreamBranch: 'origin/main',
    aheadCount: 2,
    behindCount: 3,
  );
  return GitState(
    availability: const GitAvailability(
      available: true,
      executablePath: '/usr/bin/git',
      version: '2.50.0',
    ),
    repositoryInfo: repository,
    statusSnapshot: GitStatusSnapshot(
      repositoryInfo: repository,
      files: [
        GitFileStatus(
          repoRelativePath: 'README.md',
          absolutePath: '$rootPath/README.md',
          indexStatus: GitFileChangeStatus.unmodified,
          workTreeStatus: GitFileChangeStatus.modified,
          category: GitFileStatusCategory.modified,
          staged: false,
          unstaged: true,
          untracked: false,
          deleted: false,
          renamed: false,
          copied: false,
          conflicted: false,
          ignored: false,
        ),
      ],
    ),
    selectedChange: const GitChangeSelection(
      path: 'guide.md',
      comparison: GitComparisonType.unstaged,
    ),
    changeDiff: GitDiff(
      title: 'Update docs',
      files: [
        _readmeCodeBlockDiffFile(),
        _gitDiffFile('guide.md', '# Guide old', '# Guide change'),
      ],
      rawPatch: '',
      hasBinaryFiles: false,
      fileSnapshots: const {
        'README.md':
            '# Readme change\n\n'
            '```bash\n'
            'echo before\n'
            'echo added\n'
            'echo after\n'
            '```\n\n'
            'Unchanged context after change.\n',
        'guide.md': '# Guide change\n\nGuide context.\n',
      },
    ),
    selectedCommitFilePath: 'guide.md',
    openDiffFilePaths: const ['README.md', 'guide.md'],
  );
}

GitDiffFile _readmeCodeBlockDiffFile() {
  return const GitDiffFile(
    oldPath: 'README.md',
    newPath: 'README.md',
    status: GitDiffFileStatus.modified,
    hunks: [
      GitDiffHunk(
        oldStart: 1,
        oldCount: 1,
        newStart: 1,
        newCount: 1,
        heading: 'git checkout 30af618a6e962623a0098ad6a33b468f33dc49c7',
        lines: [
          GitDiffLine(
            kind: GitDiffLineKind.removed,
            content: '# Readme old',
            oldLineNumber: 1,
          ),
          GitDiffLine(
            kind: GitDiffLineKind.added,
            content: '# Readme change',
            newLineNumber: 1,
          ),
        ],
      ),
      GitDiffHunk(
        oldStart: 3,
        oldCount: 4,
        newStart: 3,
        newCount: 5,
        heading: '',
        lines: [
          GitDiffLine(
            kind: GitDiffLineKind.context,
            content: '```bash',
            oldLineNumber: 3,
            newLineNumber: 3,
          ),
          GitDiffLine(
            kind: GitDiffLineKind.context,
            content: 'echo before',
            oldLineNumber: 4,
            newLineNumber: 4,
          ),
          GitDiffLine(
            kind: GitDiffLineKind.added,
            content: 'echo added',
            newLineNumber: 5,
          ),
          GitDiffLine(
            kind: GitDiffLineKind.context,
            content: 'echo after',
            oldLineNumber: 5,
            newLineNumber: 6,
          ),
          GitDiffLine(
            kind: GitDiffLineKind.context,
            content: '```',
            oldLineNumber: 6,
            newLineNumber: 7,
          ),
        ],
      ),
    ],
    binary: false,
    additions: 2,
    deletions: 1,
  );
}

GitState _gitSidebarShortcutState(String rootPath) {
  final repository = GitRepositoryInfo(
    rootPath: rootPath,
    gitDirPath: '$rootPath/.git',
    currentBranch: 'main',
  );
  return GitState(
    availability: const GitAvailability(
      available: true,
      executablePath: '/usr/bin/git',
      version: '2.50.0',
    ),
    repositoryInfo: repository,
    statusSnapshot: GitStatusSnapshot(
      repositoryInfo: repository,
      files: const [],
    ),
    projectHistory: GitProjectHistoryState(
      commits: [
        GitCommitSummary(
          fullHash: '21e982c772a5cf43f4a99de6d7db9fb1283f50d1',
          shortHash: '21e982c',
          authorName: 'BusyMark Test',
          authorEmail: 'test@example.invalid',
          authorDate: DateTime(2026),
          subject: 'Sidebar history shortcut commit',
          parentHashes: const [],
        ),
      ],
    ),
  );
}

GitDiffFile _gitDiffFile(
  String path,
  String oldContent,
  String newContent, {
  String hunkHeading = '',
}) {
  return GitDiffFile(
    oldPath: path,
    newPath: path,
    status: GitDiffFileStatus.modified,
    hunks: [
      GitDiffHunk(
        oldStart: 1,
        oldCount: 1,
        newStart: 1,
        newCount: 3,
        heading: hunkHeading,
        lines: [
          GitDiffLine(
            kind: GitDiffLineKind.removed,
            content: oldContent,
            oldLineNumber: 1,
          ),
          GitDiffLine(
            kind: GitDiffLineKind.added,
            content: newContent,
            newLineNumber: 1,
          ),
        ],
      ),
    ],
    binary: false,
    additions: 1,
    deletions: 1,
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

class _FakeNativeWindowController implements NativeWindowController {
  final preventCloseValues = <bool>[];
  final fullScreenValues = <bool>[];
  final listeners = <WindowListener>[];
  var closeCount = 0;
  var fullScreen = false;

  @override
  Future<void> setPreventClose(bool value) async {
    preventCloseValues.add(value);
  }

  @override
  Future<void> close() async {
    closeCount++;
  }

  @override
  Future<bool> isFullScreen() async => fullScreen;

  @override
  Future<void> setFullScreen(bool value) async {
    fullScreen = value;
    fullScreenValues.add(value);
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
