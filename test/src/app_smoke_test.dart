import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:busymark/l10n/generated/app_localizations_en.dart';
import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/app/busymark_app.dart';
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

  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.defaultRouteNameTestValue = '/';
    headerBarService = _FallbackHeaderBarService();
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

    expect(find.text('BusyMark'), findsWidgets);
    expect(find.text('Create Markdown File'), findsOneWidget);
    expect(find.text('Create Writerside Project'), findsOneWidget);
    expect(find.text('Open Markdown File'), findsOneWidget);
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

    await tester.tap(find.byTooltip(l10n.mainMenuTooltip));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.settingsMenuItem));
    await tester.pumpAndSettle();

    expect(find.text('BusyMark Settings'), findsOneWidget);
    expect(find.text('Validate on edit'), findsOneWidget);
    expect(find.text(l10n.settingsWindowSectionTitle), findsOneWidget);
    expect(
      find.text(l10n.settingsConfirmCloseWithUnsavedChangesTitle),
      findsOneWidget,
    );
    expect(
      find.text(l10n.settingsConfirmCloseWithUnsavedChangesDescription),
      findsOneWidget,
    );
    expect(find.text(l10n.settingsAlwaysOnTopTitle), findsOneWidget);
    expect(find.text(l10n.settingsAlwaysOnTopDescription), findsOneWidget);

    await tester.ensureVisible(find.text(l10n.settingsAlwaysOnTopTitle));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.settingsAlwaysOnTopTitle));
    await tester.pumpAndSettle();

    expect(nativeWindow.alwaysOnTopValues, contains(true));
    expect(settingsStore.value['alwaysOnTop'], isTrue);

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

  testWidgets(
    'settings disables always-on-top when the desktop cannot support it',
    (tester) async {
      final l10n = AppLocalizationsEn();
      final settingsStore = _MemorySettingsStore();
      final nativeWindow = _FakeNativeWindowController(
        alwaysOnTopSupported: false,
      );
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

      await tester.tap(find.byTooltip(l10n.mainMenuTooltip));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.settingsMenuItem));
      await tester.pumpAndSettle();

      expect(find.text(l10n.settingsAlwaysOnTopTitle), findsOneWidget);
      expect(
        find.text(l10n.settingsAlwaysOnTopUnsupportedDescription),
        findsOneWidget,
      );

      await tester.ensureVisible(find.text(l10n.settingsAlwaysOnTopTitle));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.settingsAlwaysOnTopTitle));
      await tester.pumpAndSettle();

      expect(nativeWindow.alwaysOnTopValues, isNot(contains(true)));
      expect(settingsStore.value['alwaysOnTop'], isNot(true));
    },
  );

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

    await tester.tap(find.byTooltip(l10n.mainMenuTooltip));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.keyboardShortcutsMenuItem));
    await tester.pumpAndSettle();

    expect(find.text(l10n.keyboardShortcutsMenuItem), findsOneWidget);
    expect(find.text('Create a new unsaved Markdown document'), findsOneWidget);
    expect(
      find.text('Choose a Markdown file, folder, or Writerside project'),
      findsOneWidget,
    );
    expect(find.text('Save the current Markdown file'), findsOneWidget);
    expect(find.text('Open workspace search'), findsOneWidget);
    expect(find.text('Show this popup'), findsOneWidget);
    expect(find.text('Show shortcuts over toolbar buttons'), findsNothing);
    expect(find.text('Undo the last edit'), findsOneWidget);
    expect(find.text('Redo the last undone edit'), findsOneWidget);
    expect(find.text('Apply bold formatting'), findsOneWidget);
    expect(find.text('Apply underline formatting'), findsOneWidget);
    expect(find.text('Apply strikethrough formatting'), findsOneWidget);
    expect(find.text('Apply paragraph style'), findsOneWidget);
    expect(find.text('Apply level 1 heading style'), findsOneWidget);
    expect(find.text('Apply level 6 heading style'), findsOneWidget);
    expect(find.text('Apply ordered list formatting'), findsOneWidget);
    expect(find.text('Apply bulleted list formatting'), findsOneWidget);
    expect(find.text('Apply task list formatting'), findsOneWidget);
    expect(find.text('Ctrl+N'), findsOneWidget);
    expect(find.text('Ctrl+O'), findsOneWidget);
    expect(find.text('Ctrl+S'), findsOneWidget);
    expect(find.text('Ctrl+F'), findsOneWidget);
    expect(find.text('Ctrl+/'), findsOneWidget);
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

  testWidgets('about dialog opens from the header', (tester) async {
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

    await tester.tap(find.byTooltip(l10n.mainMenuTooltip));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.aboutBusyMarkMenuItem));
    await tester.pumpAndSettle();

    expect(find.text('Version 0.1.1'), findsOneWidget);
    expect(
      find.text(
        'BusyMark is an open-source application for reading and editing Markdown files and Writerside-compatible projects.',
      ),
      findsOneWidget,
    );
    expect(find.text('https://github.com/busystack/busymark'), findsOneWidget);
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
    expect(find.text('Create Markdown File'), findsNothing);
    expect(find.text('Unsaved Markdown file'), findsWidgets);
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

    expect(find.text('Unsaved changes'), findsOneWidget);

    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(service.untitledCount, 1);
    expect(find.text('Unsaved Markdown file'), findsWidgets);
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
    expect(find.text('Open Markdown File'), findsNothing);
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
      if (find.text('Single Markdown file').evaluate().isNotEmpty) {
        break;
      }
    }
    expect(find.text('Single Markdown file'), findsWidgets);

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
      if (find.text('Single Markdown file').evaluate().isNotEmpty) {
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
      if (find.text('Single Markdown file').evaluate().isNotEmpty) {
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
      if (find.text('Single Markdown file').evaluate().isNotEmpty) {
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
      if (find.text('Single Markdown file').evaluate().isNotEmpty) {
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
  Future<bool> fileChangedSince(String path, DateTime? knownModifiedAt) async {
    return false;
  }

  @override
  Future<DateTime> saveText(String path, String text) async {
    saveCount++;
    savedPath = path;
    savedText = text;
    return DateTime(2026, 1, 2);
  }
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
  _FakeNativeWindowController({this.alwaysOnTopSupported = true});

  final bool alwaysOnTopSupported;
  final alwaysOnTopValues = <bool>[];
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
  Future<bool> isAlwaysOnTopSupported() async {
    return alwaysOnTopSupported;
  }

  @override
  Future<bool> setAlwaysOnTop(bool value) async {
    alwaysOnTopValues.add(value);
    return !value || alwaysOnTopSupported;
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
