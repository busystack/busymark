import 'dart:async';
import 'dart:io';
import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/app/busymark_main_menu.dart';
import 'package:busymark/src/app/command_registry.dart';
import 'package:busymark/src/export/html_export_models.dart';
import 'package:busymark/src/export/html_export_service.dart';
import 'package:busymark/src/export/html_export_ui.dart';
import 'package:busymark/src/platform/linux_header_bar_service.dart';
import 'package:busymark/src/workspace/workspace_controller.dart';
import 'package:busymark/src/writerside/writerside_project.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test(
    'HTML command has no default shortcut and PDF retains Ctrl+Shift+E',
    () async {
      var calls = 0;
      var enabled = false;
      final registry = BusyMarkCommandCatalog.create(
        executions: {BusyMarkCommandIds.exportHtml: () => calls++},
        enabled: {BusyMarkCommandIds.exportHtml: () => enabled},
      );
      expect(registry[BusyMarkCommandIds.exportHtml]!.shortcut, isNull);
      expect(
        registry[BusyMarkCommandIds.exportPdf]!.shortcut!.label,
        'Ctrl+Shift+E',
      );
      expect(await registry.execute(BusyMarkCommandIds.exportHtml), isFalse);
      enabled = true;
      expect(await registry.execute(BusyMarkCommandIds.exportHtml), isTrue);
      expect(calls, 1);
      final native = File('linux/runner/my_application.cc').readAsStringSync();
      expect(native, contains('"header.export-html"'));
      expect(native, contains('configuration.can_export_html'));
      expect(native, contains('"setCanExportHtml"'));
    },
  );

  testWidgets('Flutter HTML menu preserves enablement and dispatch', (
    tester,
  ) async {
    var selected = false;
    Future<void> menu(bool enabled) => tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: BusyMarkMainMenuButton(
              canExportHtml: enabled,
              onSelected: (action) =>
                  selected = action == BusyMarkMainMenuAction.exportHtml,
            ),
          ),
        ),
      ),
    );
    await menu(false);
    await tester.tap(find.byType(BusyMarkMainMenuButton));
    await tester.pumpAndSettle();
    final item = find.byWidgetPredicate(
      (widget) =>
          widget is PopupMenuItem<BusyMarkMainMenuAction> &&
          widget.value == BusyMarkMainMenuAction.exportHtml,
    );
    expect(
      tester.widget<PopupMenuItem<BusyMarkMainMenuAction>>(item).enabled,
      isFalse,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await menu(true);
    await tester.tap(find.byType(BusyMarkMainMenuButton));
    await tester.pumpAndSettle();
    expect(
      tester.widget<PopupMenuItem<BusyMarkMainMenuAction>>(item).enabled,
      isTrue,
    );
    await tester.tap(find.text('Export as HTML…'));
    await tester.pumpAndSettle();
    expect(selected, isTrue);
  });

  testWidgets(
    'untitled active text stays captured while destination picker is open',
    (tester) async {
      final root = Directory.systemTemp.createTempSync('html-ui-');
      addTearDown(() => root.deleteSync(recursive: true));
      final service = _RecordingExporter();
      final picker = Completer<String?>();
      const channel = MethodChannel('plugins.flutter.io/file_selector');
      String? suggestion;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        suggestion = (call.arguments as Map)['suggestedName'] as String?;
        return picker.future;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      late WidgetRef ref;
      await tester.pumpWidget(_harness(service, (value) => ref = value));
      await tester.runAsync(
        () =>
            ref.read(workspaceControllerProvider.notifier).createMarkdownFile(),
      );
      ref
          .read(workspaceControllerProvider.notifier)
          .updateActiveText('# Captured unsaved');
      await tester.tap(find.text('Run HTML'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 80)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Export'));
      await tester.pumpAndSettle();
      expect(suggestion, endsWith('.html'));
      ref
          .read(workspaceControllerProvider.notifier)
          .updateActiveText('# Later edit');
      picker.complete(p.join(root.path, 'untitled.html'));
      for (var i = 0; i < 15; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(service.markdown?.source, '# Captured unsaved');
      expect(ref.read(workspaceControllerProvider).activeText, '# Later edit');
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Show in Folder'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final action in ['Cancel', 'Discard', 'Save']) {
    testWidgets(
      'Writerside HTML follows $action handling before instance selection',
      (tester) async {
        final root = Directory.systemTemp.createTempSync('html-ws-ui-');
        addTearDown(() => root.deleteSync(recursive: true));
        void put(String name, String source) {
          final file = File(p.join(root.path, name));
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(source);
        }

        put(
          'writerside.cfg',
          '<ihp version="2.0"><topics dir="topics"/><instance src="guide.tree"/></ihp>',
        );
        put(
          'guide.tree',
          '<instance-profile id="guide" name="Guide" start-page="a.topic"><toc-element topic="a.topic"/></instance-profile>',
        );
        put('topics/a.topic', '<topic id="a" title="Old"><p>Disk</p></topic>');
        final service = _RecordingExporter();
        late WidgetRef ref;
        await tester.pumpWidget(_harness(service, (value) => ref = value));
        await tester.runAsync(
          () => ref
              .read(workspaceControllerProvider.notifier)
              .openPath(root.path),
        );
        await tester.runAsync(
          () => ref
              .read(workspaceControllerProvider.notifier)
              .openActiveFile(p.join(root.path, 'topics/a.topic')),
        );
        ref
            .read(workspaceControllerProvider.notifier)
            .updateActiveText(
              '<topic id="a" title="Edited"><p>New</p></topic>',
            );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Run HTML'));
        await tester.pumpAndSettle();
        expect(find.text('Unsaved changes'), findsOneWidget);
        await tester.tap(find.text(action));
        for (
          var i = 0;
          i < 60 && find.text('Instance').evaluate().isEmpty;
          i++
        ) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          );
          await tester.pump(const Duration(milliseconds: 100));
        }
        if (action == 'Cancel') {
          expect(find.text('Instance'), findsNothing);
          expect(
            ref.read(workspaceControllerProvider).hasUnsavedChanges,
            isTrue,
          );
        } else {
          expect(find.text('Instance'), findsOneWidget);
          expect(
            File(p.join(root.path, 'topics/a.topic')).readAsStringSync(),
            contains(action == 'Save' ? 'Edited' : 'Old'),
          );
          await tester.tap(find.text('Cancel'));
          await tester.pumpAndSettle();
        }
        expect(service.markdown, isNull);
        expect(service.siteCalls, 0);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}

Widget _harness(
  HtmlExportService service,
  void Function(WidgetRef) ready,
) => ProviderScope(
  overrides: [
    htmlExportServiceProvider.overrideWithValue(service),
    localSettingsStoreProvider.overrideWithValue(_Settings()),
    linuxHeaderBarServiceProvider.overrideWithValue(
      LinuxHeaderBarService(channel: const MethodChannel('html-test-header')),
    ),
  ],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: buildBusyMarkTheme(
      brightness: Brightness.light,
      accentColor: Colors.blue,
    ),
    home: Scaffold(
      body: Consumer(
        builder: (context, ref, child) {
          ready(ref);
          return Column(
            children: [
              TextButton(
                onPressed: () => exportWorkspaceToHtml(context, ref),
                child: const Text('Run HTML'),
              ),
              BusyMarkMainMenuButton(canExportHtml: true, onSelected: (_) {}),
            ],
          );
        },
      ),
    ),
  ),
);

class _Settings implements LocalSettingsStore {
  Map<String, Object?> data = AppSettings.defaults()
      .copyWith(autoSave: false)
      .toJson();
  @override
  Future<Map<String, Object?>> load() async => data;
  @override
  Future<void> save(Map<String, Object?> json) async {
    data = json;
  }
}

class _RecordingExporter extends HtmlExportService {
  MarkdownHtmlExportRequest? markdown;
  int siteCalls = 0;
  @override
  Future<HtmlExportResult> exportMarkdown(
    MarkdownHtmlExportRequest request, {
    HtmlExportCancellationToken? cancellationToken,
    HtmlExportProgress? onProgress,
  }) async {
    markdown = request;
    return HtmlExportResult(
      entryPointPath: request.destinationPath,
      warnings: const [],
    );
  }

  @override
  Future<HtmlExportResult> exportWriterside({
    required String projectRoot,
    required String moduleRoot,
    required String instanceId,
    required String destinationPath,
    bool overwrite = false,
    HtmlExportOptions options = const HtmlExportOptions(),
    WritersideProject? capturedProject,
    HtmlExportCancellationToken? cancellationToken,
    HtmlExportProgress? onProgress,
  }) async {
    siteCalls++;
    return HtmlExportResult(
      entryPointPath: p.join(destinationPath, 'index.html'),
      warnings: const [],
    );
  }
}
