import 'dart:async';

import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/app/busymark_app.dart';
import 'package:busymark/src/app/startup_path.dart';
import 'package:busymark/src/platform/linux_header_bar_service.dart';
import 'package:busymark/src/workspace/workspace_controller.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:busymark/src/workspace/workspace_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    expect(find.text('Open Markdown File'), findsOneWidget);
    expect(find.text('File or folder path'), findsNothing);
    expect(find.textContaining('sign in'), findsNothing);
  });

  testWidgets('settings screen opens', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        ],
        child: const BusyMarkApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('BusyMark Settings'), findsOneWidget);
    expect(find.text('Validate on edit'), findsOneWidget);
  });

  testWidgets('keyboard shortcuts dialog opens from the header', (
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

    await tester.tap(find.byTooltip('Keyboard Shortcuts'));
    await tester.pumpAndSettle();

    expect(find.text('Keyboard Shortcuts'), findsOneWidget);
    expect(find.text('Create a new unsaved Markdown document'), findsOneWidget);
    expect(find.text('Save the current Markdown file'), findsOneWidget);
    expect(find.text('Undo the last edit'), findsOneWidget);
    expect(find.text('Redo the last undone edit'), findsOneWidget);
    expect(find.text('Ctrl+N'), findsOneWidget);
    expect(find.text('Ctrl+S'), findsOneWidget);
    expect(find.text('Ctrl+Z'), findsOneWidget);
    expect(find.text('Ctrl+Shift+Z'), findsOneWidget);
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

class _MemorySettingsStore implements LocalSettingsStore {
  Map<String, Object?> value = <String, Object?>{};

  @override
  Future<Map<String, Object?>> load() async => value;

  @override
  Future<void> save(Map<String, Object?> json) async {
    value = json;
  }
}
