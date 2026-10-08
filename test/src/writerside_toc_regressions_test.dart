import 'package:busymark/src/app/busymark_design.dart';
import 'dart:io';

import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/app/busymark_app.dart';
import 'package:busymark/src/app/system_accent.dart';
import 'package:busymark/src/editor/source/source_editor.dart';
import 'package:busymark/src/local_history/local_history_controller.dart';
import 'package:busymark/src/local_history/local_history_store.dart';
import 'package:busymark/src/platform/linux_header_bar_service.dart';
import 'package:busymark/src/workspace/recovery_persistence.dart';
import 'package:busymark/src/workspace/session_persistence.dart';
import 'package:busymark/src/workspace/workspace_controller.dart';
import 'package:busymark/src/writerside/writerside_template_service.dart';
import 'package:busymark/src/writerside/writerside_topic_removal_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

void main() {
  late Directory root;
  late ProviderContainer container;
  WorkspaceController controller() =>
      container.read(workspaceControllerProvider.notifier);
  String topicPath(String relative) => p.join(root.path, 'topics', relative);

  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    for (final channel in ['yaru_window', 'yaru_window/events']) {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        MethodChannel(channel),
        (call) async => call.method == 'state' ? <String, Object?>{} : null,
      );
    }
    root = Directory.systemTemp.createTempSync('busymark-toc-regression-');
    for (final name in [
      'guides/install.md',
      'elsewhere/install.md',
      'other.md',
    ]) {
      final file = File(topicPath(name));
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(
        '# ${name == 'other.md' ? 'Other topic' : name}\n\nBody\n',
      );
    }
    File(p.join(root.path, 'writerside.cfg')).writeAsStringSync(
      '<ihp><topics dir="topics"/><instance src="guide.tree"/></ihp>',
    );
    File(p.join(root.path, 'guide.tree')).writeAsStringSync('''
<instance-profile id="guide" name="Guide" start-page="other.md">
  <toc-element topic="other.md"/>
  <toc-element toc-title="Group"><toc-element topic="guides/install.md" toc-title="Deep occurrence"/></toc-element>
  <toc-element topic="guides/install.md" toc-title="First occurrence"/>
  <toc-element topic="guides/install.md" toc-title="Second occurrence"/>
  <toc-element topic="elsewhere/install.md" toc-title="Different file"/>
</instance-profile>
''');
    container = ProviderContainer(
      overrides: [
        linuxHeaderBarServiceProvider.overrideWithValue(_FallbackHeader()),
        systemAccentColorProvider.overrideWith(
          (ref) => Stream.value(busyMarkDefaultAccentColor),
        ),
        localSettingsStoreProvider.overrideWithValue(_Settings()),
        documentSessionStoreProvider.overrideWithValue(
          MemoryDocumentSessionStore(),
        ),
        documentRecoveryStoreProvider.overrideWithValue(
          MemoryDocumentRecoveryStore(),
        ),
        localHistoryStoreProvider.overrideWithValue(MemoryLocalHistoryStore()),
        writersideTemplateServiceProvider.overrideWithValue(
          WritersideTemplateService(
            storagePath: p.join(root.path, 'test-support/templates.json'),
            loadBundledSource: () =>
                File('assets/writerside/templates.json').readAsString(),
          ),
        ),
      ],
    );
  });
  tearDown(() async {
    container.dispose();
    for (final channel in ['yaru_window', 'yaru_window/events']) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(channel), null);
    }
    await root.delete(recursive: true);
  });

  Future<void> start(WidgetTester tester) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue = '/workspace';
    addTearDown(() {
      tester.binding.platformDispatcher.defaultRouteNameTestValue = '/';
    });
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      await container
          .read(appSettingsControllerProvider.notifier)
          .waitUntilLoaded();
      await controller().openPath(root.path);
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BusyMarkApp(),
      ),
    );
    await _settle(tester);
    expect(container.read(workspaceControllerProvider).workspace, isNotNull);
    await tester.tap(find.byTooltip('Sidebar view'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Table of Contents'));
    await tester.pumpAndSettle();
  }

  Future<void> selectWithoutOpening(WidgetTester tester, String path) async {
    await tester.tap(
      find.byKey(ValueKey('workspace-sidebar-toc-row-$path')),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
  }

  Future<void> synchronizeTocAndEditor(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('workspace-sidebar-toc-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Synchronize TOC and Editor'));
    await tester.pumpAndSettle();
  }

  Future<void> openRemoval(WidgetTester tester, {String row = '0'}) async {
    await tester.tap(
      find.byKey(ValueKey('workspace-sidebar-toc-row-$row')),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() => tester.tap(find.text('Remove TOC Element')));
    await _settle(
      tester,
      until: () => find.text('Set redirect to:').evaluate().isNotEmpty,
    );
  }

  Finder homeSelector() =>
      find.byType(BusyMarkPopupSelector<WritersideHomePageReplacement>);

  BusyMarkDialogButton removeButton(WidgetTester tester) =>
      tester.widget(find.widgetWithText(BusyMarkDialogButton, 'Remove'));

  Finder automaticCheckbox() => find
      .descendant(
        of: find.byType(BusyMarkDialogShell),
        matching: find.byType(BusyMarkCheckbox),
      )
      .last;

  Future<void> chooseHome(WidgetTester tester) async {
    await tester.tap(find.text('Choose a Home Page'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('guides/install.md'));
    await tester.pumpAndSettle();
  }

  Future<void> keepOrphan(WidgetTester tester) async {
    await _settle(
      tester,
      until: () => find.text('Keep Topic File').evaluate().isNotEmpty,
      timeout: const Duration(seconds: 30),
      diagnostics: () =>
          '${container.read(workspaceControllerProvider).message}',
    );
    await tester.tap(find.text('Keep Topic File'));
    await _settle(tester);
  }

  bool selected(WidgetTester tester, String path) =>
      (tester.widget(
                    find.descendant(
                      of: find.byKey(
                        ValueKey('workspace-sidebar-toc-row-$path'),
                      ),
                      matching: find.byWidgetPredicate(
                        (widget) =>
                            widget.runtimeType.toString() == '_SidebarTreeRow',
                      ),
                    ),
                  )
                  as dynamic)
              .selected
          as bool;

  testWidgets(
    'tree-to-editor sync opens selected topic even with a .tree editor active',
    (tester) async {
      await start(tester);
      final treePath = p.join(root.path, 'guide.tree');
      await tester.runAsync(() => controller().openActiveFile(treePath));
      await _settle(tester);
      await selectWithoutOpening(tester, '2');
      expect(selected(tester, '2'), isTrue);
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'BusyMark topics tree',
      );
      expect(
        container.read(workspaceControllerProvider).activeBuffer!.filePath,
        treePath,
      );
      await synchronizeTocAndEditor(tester);
      await _settle(
        tester,
        until: () =>
            container
                .read(workspaceControllerProvider)
                .activeBuffer
                ?.filePath ==
            topicPath('guides/install.md'),
      );
      expect(
        container.read(workspaceControllerProvider).activeBuffer!.filePath,
        topicPath('guides/install.md'),
      );
      // A topic-less group still uses element source navigation.
      await selectWithoutOpening(tester, '1');
      await synchronizeTocAndEditor(tester);
      await _settle(
        tester,
        until: () =>
            container
                .read(workspaceControllerProvider)
                .activeBuffer
                ?.filePath ==
            treePath,
      );
      expect(
        container.read(workspaceControllerProvider).activeBuffer!.filePath,
        treePath,
      );
    },
  );

  testWidgets(
    'editor-to-TOC sync resolves qualified identities and chooses breadth-first occurrence',
    (tester) async {
      await start(tester);
      final path = topicPath('guides/install.md');
      await tester.runAsync(() => controller().openActiveFile(path));
      await _settle(tester);
      await selectWithoutOpening(tester, '0');
      expect(selected(tester, '0'), isTrue);
      expect(
        container.read(workspaceControllerProvider).activeBuffer!.filePath,
        path,
      );
      await tester.tap(
        find
            .descendant(
              of: find.byType(BusyMarkSourceEditor),
              matching: find.byType(EditableText),
            )
            .first,
      );
      await tester.pump();
      await synchronizeTocAndEditor(tester);
      await _settle(tester);
      expect(selected(tester, '2'), isTrue);
      expect(selected(tester, '0'), isFalse);
      expect(selected(tester, '3'), isFalse);
      expect(selected(tester, '4'), isFalse);
      expect(
        container.read(workspaceControllerProvider).activeBuffer!.filePath,
        path,
      );
    },
  );

  testWidgets(
    'live removal dialog uses documented confirmation, redirect label and usage count',
    (tester) async {
      await start(tester);
      final tree = File(p.join(root.path, 'guide.tree'));
      final original = await tester.runAsync(tree.readAsString);
      await tester.tap(
        find.byKey(const ValueKey('workspace-sidebar-toc-row-0')),
        buttons: kSecondaryMouseButton,
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() => tester.tap(find.text('Remove TOC Element')));
      await _settle(
        tester,
        until: () => find
            .text(
              "Remove TOC element 'Other topic'? The source file associated with the TOC won't be deleted.",
            )
            .evaluate()
            .isNotEmpty,
      );
      expect(
        find.text(
          "Remove TOC element 'Other topic'? The source file associated with the TOC won't be deleted.",
        ),
        findsOneWidget,
      );
      expect(find.text('Set redirect to:'), findsOneWidget);
      expect(
        find.textContaining(RegExp(r'^\d+ usages found\.$')),
        findsOneWidget,
      );
      expect(find.text('Set redirect to'), findsNothing);
      expect(
        find.text(
          'This topic is the Home Page for this instance. Choose another Home Page before removing it from the TOC.',
        ),
        findsOneWidget,
      );
      expect(find.text('New Home Page'), findsOneWidget);
      final picker = tester
          .widget<BusyMarkPopupSelector<WritersideHomePageReplacement>>(
            homeSelector(),
          );
      expect(picker.value, isNull);
      expect(picker.options.map((option) => option.value.topicReference), [
        'guides/install.md',
        'elsewhere/install.md',
      ]);
      expect(removeButton(tester).onPressed, isNull);
      await chooseHome(tester);
      expect(removeButton(tester).onPressed, isNotNull);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await tester.runAsync(tree.readAsString), original);
      expect(File(topicPath('other.md')).existsSync(), isTrue);
    },
  );

  testWidgets(
    'Home Page removal assigns the chosen topic and keeps the orphan source',
    (tester) async {
      await start(tester);
      await openRemoval(tester);
      await tester.tap(automaticCheckbox());
      await tester.pumpAndSettle();
      expect(
        tester.widget<BusyMarkCheckbox>(automaticCheckbox()).value,
        isFalse,
      );
      await chooseHome(tester);
      expect(removeButton(tester).onPressed, isNotNull);
      await tester.runAsync(() => tester.tap(find.text('Remove')));
      await keepOrphan(tester);
      final tree = XmlDocument.parse(
        File(p.join(root.path, 'guide.tree')).readAsStringSync(),
      );
      expect(tree.rootElement.getAttribute('start-page'), 'guides/install.md');
      expect(
        tree
            .findAllElements('toc-element')
            .where((node) => node.getAttribute('topic') == 'other.md'),
        isEmpty,
      );
      expect(
        tree
            .findAllElements('toc-element')
            .any((node) => node.getAttribute('accepts-web-file-names') != null),
        isFalse,
      );
      expect(File(topicPath('other.md')).existsSync(), isTrue);
    },
  );

  testWidgets('Home Page removal with no candidate explains how to unblock it', (
    tester,
  ) async {
    final tree = File(p.join(root.path, 'guide.tree'));
    tree.writeAsStringSync(
      '<instance-profile id="guide" start-page="other.md"><toc-element topic="other.md"/></instance-profile>',
    );
    final original = tree.readAsStringSync();
    await start(tester);
    await openRemoval(tester);
    expect(homeSelector(), findsNothing);
    expect(
      find.text(
        'Add or link another eligible topic to this instance before removing its Home Page.',
      ),
      findsOneWidget,
    );
    expect(removeButton(tester).onPressed, isNull);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tree.readAsStringSync(), original);
  });

  testWidgets(
    'Review Usages without a Home Page choice resumes in the actionable dialog',
    (tester) async {
      await start(tester);
      final tree = File(p.join(root.path, 'guide.tree'));
      final original = tree.readAsStringSync();
      await openRemoval(tester);
      await tester.tap(find.text('Review Usages'));
      await tester.pumpAndSettle();
      expect(tree.readAsStringSync(), original);
      await tester.runAsync(() => tester.tap(find.text('Do Refactor')));
      await _settle(tester, until: () => homeSelector().evaluate().isNotEmpty);
      expect(
        tester
            .widget<BusyMarkPopupSelector<WritersideHomePageReplacement>>(
              homeSelector(),
            )
            .value,
        isNull,
      );
      expect(removeButton(tester).onPressed, isNull);
      await chooseHome(tester);
      await tester.runAsync(() => tester.tap(find.text('Remove')));
      await keepOrphan(tester);
      expect(
        XmlDocument.parse(
          tree.readAsStringSync(),
        ).rootElement.getAttribute('start-page'),
        'guides/install.md',
      );
    },
  );

  testWidgets(
    'Review Usages keeps the explicit Home Page choice across changed TOC positions',
    (tester) async {
      await start(tester);
      final tree = File(p.join(root.path, 'guide.tree'));
      final original = tree.readAsStringSync();
      await openRemoval(tester);
      await chooseHome(tester);
      await tester.tap(find.text('Review Usages'));
      await tester.pumpAndSettle();
      expect(tree.readAsStringSync(), original);
      tree.writeAsStringSync(
        original.replaceFirst(
          '<toc-element toc-title="Group">',
          '<toc-element topic="elsewhere/install.md"/><toc-element toc-title="Group">',
        ),
      );
      await tester.runAsync(() => tester.tap(find.text('Do Refactor')));
      await keepOrphan(tester);
      expect(
        XmlDocument.parse(
          tree.readAsStringSync(),
        ).rootElement.getAttribute('start-page'),
        'guides/install.md',
      );
      expect(File(topicPath('other.md')).existsSync(), isTrue);
    },
  );

  testWidgets(
    'Review Usages reopens the selector when the chosen replacement is no longer eligible',
    (tester) async {
      await start(tester);
      final tree = File(p.join(root.path, 'guide.tree'));
      await openRemoval(tester);
      await chooseHome(tester);
      await tester.tap(find.text('Review Usages'));
      await tester.pumpAndSettle();
      tree.writeAsStringSync(
        tree.readAsStringSync().replaceAll(
          'topic="guides/install.md"',
          'topic="elsewhere/install.md"',
        ),
      );
      final changed = tree.readAsStringSync();
      await tester.runAsync(() => tester.tap(find.text('Do Refactor')));
      await _settle(tester, until: () => homeSelector().evaluate().isNotEmpty);
      final picker = tester
          .widget<BusyMarkPopupSelector<WritersideHomePageReplacement>>(
            homeSelector(),
          );
      expect(picker.value, isNull);
      expect(
        picker.options.single.value.topicReference,
        'elsewhere/install.md',
      );
      expect(removeButton(tester).onPressed, isNull);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(tree.readAsStringSync(), changed);
    },
  );

  testWidgets(
    'Home Page replacement and automatic usage consent remain independent',
    (tester) async {
      File(
        topicPath('guides/install.md'),
      ).writeAsStringSync('# guides/install.md\n\n[Other](../other.md)\n');
      await start(tester);
      await openRemoval(tester);
      expect(
        tester.widget<BusyMarkCheckbox>(automaticCheckbox()).onChanged,
        isNotNull,
      );
      await tester.tap(automaticCheckbox());
      await tester.pumpAndSettle();
      await chooseHome(tester);
      expect(removeButton(tester).onPressed, isNull);
      await tester.tap(automaticCheckbox());
      await tester.pumpAndSettle();
      expect(removeButton(tester).onPressed, isNotNull);
      await tester.runAsync(() => tester.tap(find.text('Remove')));
      await keepOrphan(tester);
      expect(
        File(topicPath('guides/install.md')).readAsStringSync(),
        isNot(contains('../other.md')),
      );
      expect(
        XmlDocument.parse(
          File(p.join(root.path, 'guide.tree')).readAsStringSync(),
        ).rootElement.getAttribute('start-page'),
        'guides/install.md',
      );
    },
  );

  testWidgets(
    'non-Home-Page removal has no Home Page selector and remains enabled',
    (tester) async {
      await start(tester);
      final tree = File(p.join(root.path, 'guide.tree'));
      final original = tree.readAsStringSync();
      await openRemoval(tester, row: '4');
      expect(homeSelector(), findsNothing);
      expect(find.text('New Home Page'), findsNothing);
      expect(removeButton(tester).onPressed, isNotNull);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(tree.readAsStringSync(), original);
    },
  );

  testWidgets('Home Page choice is revalidated after saving a dirty buffer', (
    tester,
  ) async {
    await start(tester);
    await tester.runAsync(
      () => controller().openActiveFile(topicPath('guides/install.md')),
    );
    await _settle(tester);
    await openRemoval(tester);
    await chooseHome(tester);
    controller().updateActiveText(
      '# guides/install.md\n\nSaved during removal.\n',
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() => tester.tap(find.text('Remove')));
    await _settle(
      tester,
      until: () => find.text('Unsaved changes').evaluate().isNotEmpty,
    );
    await tester.runAsync(
      () => tester.tap(find.widgetWithText(BusyMarkDialogButton, 'Save')),
    );
    await _settle(tester, until: () => homeSelector().evaluate().isNotEmpty);
    expect(
      tester
          .widget<BusyMarkPopupSelector<WritersideHomePageReplacement>>(
            homeSelector(),
          )
          .value
          ?.topicReference,
      'guides/install.md',
    );
    expect(removeButton(tester).onPressed, isNotNull);
    expect(
      XmlDocument.parse(
        File(p.join(root.path, 'guide.tree')).readAsStringSync(),
      ).rootElement.getAttribute('start-page'),
      'other.md',
    );
    await tester.runAsync(() => tester.tap(find.text('Remove')));
    await keepOrphan(tester);
    expect(
      XmlDocument.parse(
        File(p.join(root.path, 'guide.tree')).readAsStringSync(),
      ).rootElement.getAttribute('start-page'),
      'guides/install.md',
    );
    expect(
      File(topicPath('guides/install.md')).readAsStringSync(),
      contains('Saved during removal.'),
    );
  });

  testWidgets(
    'New Topic surfaces expose local Markdown import only at root/sibling',
    (tester) async {
      await start(tester);
      await tester.tap(
        find.byKey(const ValueKey('workspace-sidebar-toc-row-0')),
        buttons: kSecondaryMouseButton,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('New Topic'));
      await tester.pumpAndSettle();
      expect(find.text('Empty MD Topic'), findsOneWidget);
      expect(find.text('Empty XML Topic'), findsOneWidget);
      expect(find.text('Empty Group'), findsOneWidget);
      expect(find.text('Topic from Template...'), findsOneWidget);
      expect(find.text('Add Local Markdown Files'), findsOneWidget);
      expect(find.text('Link Topic Files to TOC...'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('workspace-sidebar-toc-row-0')),
        buttons: kSecondaryMouseButton,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('New Child Topic'));
      await tester.pumpAndSettle();
      expect(find.text('Add Local Markdown Files'), findsNothing);
      expect(find.text('Link Topic Files to TOC...'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('workspace-sidebar-new-topic-menu')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Add Local Markdown Files'), findsOneWidget);
      expect(find.text('Link Topic Files to TOC...'), findsOneWidget);
    },
  );

  for (final choice in [
    'Empty MD Topic',
    'Empty XML Topic',
    'Topic from Template...',
  ]) {
    testWidgets(
      '$choice creates an editable document when Reading mode is active, preserving other tabs',
      (tester) async {
        await start(tester);
        final other = topicPath('guides/install.md');
        await tester.runAsync(() => controller().openActiveFile(other));
        controller().updateActiveEditorMode(DocumentViewModePreference.split);
        controller().updateActiveText('# Unrelated unsaved document\n');
        await tester.runAsync(
          () => controller().openActiveFile(topicPath('other.md')),
        );
        await _settle(tester);
        controller().updateActiveEditorMode(DocumentViewModePreference.preview);
        await tester.runAsync(
          () => container
              .read(appSettingsControllerProvider.notifier)
              .setDocumentViewMode(DocumentViewModePreference.preview),
        );
        await _settle(
          tester,
          until: () =>
              container
                  .read(workspaceControllerProvider)
                  .activeBuffer
                  ?.editorState
                  .mode ==
              DocumentViewModePreference.preview,
        );
        final before = container.read(workspaceControllerProvider);
        expect(
          before.activeBuffer!.editorState.mode,
          DocumentViewModePreference.preview,
        );
        expect(
          container.read(appSettingsControllerProvider).documentViewMode,
          DocumentViewModePreference.preview,
        );
        final modes = {
          for (final buffer in before.documentBuffers)
            buffer.id: buffer.editorState.mode,
        };

        await tester.tap(
          find.byKey(const ValueKey('workspace-sidebar-toc-row-0')),
          buttons: kSecondaryMouseButton,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('New Topic'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(choice));
        await _settle(tester);
        final template = choice == 'Topic from Template...';
        if (template) {
          await tester.enterText(
            _editableUnderKey('template-title'),
            'Created topic',
          );
          await tester.enterText(
            _editableUnderKey('template-filename'),
            'created-topic',
          );
        } else {
          await tester.enterText(
            find.widgetWithText(BusyMarkGroupedTextEntry, 'Topic title:'),
            'Created topic',
          );
          await tester.enterText(
            find.widgetWithText(BusyMarkGroupedTextEntry, 'Topic Filename:'),
            'created-topic',
          );
        }
        await tester.pumpAndSettle();
        await tester.runAsync(
          () => tester.tap(find.text(template ? 'Create' : 'OK')),
        );
        final extension = choice == 'Empty XML Topic' ? 'topic' : 'md';
        await _settle(
          tester,
          until: () =>
              container
                      .read(workspaceControllerProvider)
                      .activeBuffer
                      ?.filePath ==
                  topicPath('created-topic.$extension') ||
              container.read(workspaceControllerProvider).message != null,
          diagnostics: () {
            final workspace = container.read(workspaceControllerProvider);
            return 'active=${workspace.activeBuffer?.filePath}, '
                'message=${workspace.message?.code}, '
                'created file=${File(topicPath('created-topic.$extension')).existsSync()}';
          },
        );
        final after = container.read(workspaceControllerProvider);
        expect(
          after.activeBuffer!.filePath,
          topicPath('created-topic.$extension'),
          reason: tester
              .widgetList<Text>(find.byType(Text))
              .map((text) => text.data)
              .whereType<String>()
              .join('\n'),
        );
        expect(
          after.activeBuffer!.editorState.mode,
          DocumentViewModePreference.source,
        );
        expect(find.byType(BusyMarkSourceEditor), findsOneWidget);
        expect(
          after.documentBuffers,
          hasLength(before.documentBuffers.length + 1),
        );
        for (final buffer in after.documentBuffers.where(
          (buffer) => modes.containsKey(buffer.id),
        )) {
          expect(buffer.editorState.mode, modes[buffer.id]);
        }
        expect(
          after.bufferForPath(other)!.text,
          '# Unrelated unsaved document\n',
        );
        expect(after.bufferForPath(other)!.isDirty, isTrue);
        expect(
          container.read(appSettingsControllerProvider).documentViewMode,
          DocumentViewModePreference.preview,
        );
        if (template) {
          expect(
            after.activeText,
            contains(
              'A How-to article is an action-oriented type of document.',
            ),
          );
        }
      },
    );
  }
}

Finder _editableUnderKey(String key) => find.descendant(
  of: find.byKey(ValueKey(key)),
  matching: find.byType(EditableText),
);

Future<void> _settle(
  WidgetTester tester, {
  bool Function()? until,
  String Function()? diagnostics,
  Duration timeout = const Duration(seconds: 10),
}) async {
  final deadline = DateTime.now().add(timeout);
  for (
    var i = 0;
    until == null ? i < 30 : DateTime.now().isBefore(deadline);
    i++
  ) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 15)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    if (until?.call() == true) break;
  }
  if (until != null) {
    expect(
      until(),
      isTrue,
      reason:
          'Workspace operation did not complete. ${diagnostics?.call() ?? ''}',
    );
  }
  await tester.pumpAndSettle();
}

class _Settings implements LocalSettingsStore {
  Map<String, Object?> value = AppSettings.defaults()
      .copyWith(
        localeTag: 'en',
        autoSave: false,
        reopenPreviousWorkspaceOnStartup: false,
        documentViewMode: DocumentViewModePreference.source,
      )
      .toJson();
  @override
  Future<Map<String, Object?>> load() async => value;
  @override
  Future<void> save(Map<String, Object?> json) async {
    value = json;
  }
}

class _FallbackHeader extends LinuxHeaderBarService {
  _FallbackHeader()
    : super(channel: const MethodChannel('test.busymark/toc-header'));
  @override
  bool get isAvailable => false;
  @override
  bool get usesNativeHeaderBar => false;
  @override
  Stream<HeaderBarAction> get actions => const Stream.empty();
}
