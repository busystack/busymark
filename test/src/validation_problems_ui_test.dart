import 'dart:async';
import 'dart:io';

import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/app/busymark_app.dart';
import 'package:busymark/src/app/app_router.dart';
import 'package:busymark/src/app/system_accent.dart';
import 'package:busymark/src/core/source_span.dart';
import 'package:busymark/src/editor/source/source_editor.dart';
import 'package:busymark/src/platform/linux_header_bar_service.dart';
import 'package:busymark/src/workspace/workspace_controller.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:busymark/src/workspace/workspace_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  setUp(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('yaru_window'),
      (call) async => call.method == 'state' ? <String, Object?>{} : null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('yaru_window/events'),
      (_) async => null,
    );
  });
  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('yaru_window'),
      null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('yaru_window/events'),
      null,
    );
  });
  for (final mode in [
    DocumentViewModePreference.preview,
    DocumentViewModePreference.editor,
  ]) {
    testWidgets('Problems reveals the source and dismisses from ${mode.name}', (
      tester,
    ) async {
      final harness = await _open(tester, mode);
      expect(find.byType(BusyMarkSourceEditor), findsNothing);
      await _validate(tester);
      expect(find.text('Problems'), findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(
          find.textContaining('markdown.link.unresolved-target - b.md'),
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await _settle(tester);
      expect(
        harness.state.workspace!.activeFilePath,
        harness.bPath,
        reason: '${harness.state.message}',
      );
      expect(find.text('Problems'), findsNothing);
      expect(
        harness.state.activeBuffer!.editorState.mode,
        DocumentViewModePreference.source,
      );
      expect(find.byType(BusyMarkSourceEditor), findsOneWidget);
      final editable = tester.widget<EditableText>(
        find
            .descendant(
              of: find.byType(BusyMarkSourceEditor),
              matching: find.byType(EditableText),
            )
            .first,
      );
      expect(editable.controller.selection.baseOffset, '# B\n\n'.length);
      expect(editable.focusNode.hasFocus, isTrue);
      await harness.dispose(tester);
    });
  }

  testWidgets('an open Problems dialog updates its count and math rows', (
    tester,
  ) async {
    final harness = await _open(tester, DocumentViewModePreference.preview);
    await _validate(tester);
    expect(find.text('Problems'), findsOneWidget);
    final before = harness.state.workspace!.allDiagnostics.length;
    final context = tester.element(find.text('Problems'));
    final l10n = AppLocalizations.of(context);
    expect(find.text(l10n.diagnosticCount(before)), findsOneWidget);
    harness.controller.updateMathRenderDiagnostic(
      expressionId: 'runtime',
      code: 'math.invalidTex',
      sourceSpan: SourceSpan.fromOffsets(
        filePath: harness.aPath,
        source: '# A\n',
        startOffset: 0,
        endOffset: 3,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('math.invalidTex - a.md'), findsOneWidget);
    expect(find.text(l10n.diagnosticCount(before + 1)), findsOneWidget);
    harness.controller.updateMathRenderDiagnostic(
      expressionId: 'runtime',
      code: null,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('math.invalidTex - a.md'), findsNothing);
    expect(find.text(l10n.diagnosticCount(before)), findsOneWidget);
    await harness.dispose(tester);
  });

  testWidgets(
    'manual Validate supersedes queued automatic validation and presents once',
    (tester) async {
      final service = _QueuedValidationService();
      final harness = await _open(
        tester,
        DocumentViewModePreference.source,
        service: service,
        validateOnEdit: true,
      );
      await tester.runAsync(() async {
        harness.controller.updateActiveText('# Automatic first\n');
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await _settle(tester);
      expect(
        service.automaticStarted.isCompleted,
        isTrue,
        reason: service.sources.toString(),
      );
      await tester.runAsync(() async {
        // Queue an automatic follow-up behind the blocked first pass.
        harness.controller.updateActiveText('# Latest\n');
        await tester.tap(find.byTooltip('Validate'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await _settle(tester);
      expect(
        service.manualStarted.isCompleted,
        isTrue,
        reason: service.sources.toString(),
      );
      // Finish the first pass while the manual pass is still blocked.
      service.releaseAutomatic.complete();
      await _settle(tester);
      expect(service.latestCalls, 1);
      expect(find.text('Problems'), findsNothing);
      service.releaseManual.complete();
      await _settle(tester);
      expect(find.text('Problems'), findsOneWidget);
      expect(service.latestCalls, 1);
      expect(harness.state.workspace!.markdown!.source, '# Latest\n');
      await harness.dispose(tester);
    },
  );

  testWidgets(
    'failed and stale validation do not show Problems; concurrent clicks publish once',
    (tester) async {
      final service = _ControlledValidationService();
      final harness = await _open(
        tester,
        DocumentViewModePreference.preview,
        service: service,
      );
      service.fail = true;
      await _validate(tester);
      expect(find.text('Problems'), findsNothing);
      service.fail = false;
      service.gate = Completer<void>();
      service.blockedPath = harness.aPath;
      service.calls = 0;
      await tester.tap(find.byTooltip('Validate'));
      await tester.tap(find.byTooltip('Validate'));
      await _settle(tester);
      expect(service.calls, 1);
      await tester.runAsync(
        () => harness.controller.openActiveFile(harness.bPath),
      );
      service.gate!.complete();
      await _settle(tester);
      expect(find.text('Problems'), findsNothing);
      service.gate = null;
      await _validate(tester);
      expect(find.text('Problems'), findsOneWidget);
      await harness.dispose(tester);
    },
  );
}

Future<_Harness> _open(
  WidgetTester tester,
  DocumentViewModePreference mode, {
  WorkspaceService service = const WorkspaceService(),
  bool validateOnEdit = false,
}) async {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  late _Harness harness;
  await tester.runAsync(() async {
    final root = await Directory.systemTemp.createTemp('busymark-problems-ui-');
    await File(p.join(root.path, 'a.md')).writeAsString('# A\n');
    await File(
      p.join(root.path, 'b.md'),
    ).writeAsString('# B\n\n[Broken](missing.md)\n');
    final container = ProviderContainer(
      overrides: [
        systemAccentColorProvider.overrideWith((ref) => const Stream.empty()),
        localSettingsStoreProvider.overrideWithValue(
          _Settings(mode, validateOnEdit: validateOnEdit),
        ),
        workspaceServiceProvider.overrideWithValue(service),
        linuxHeaderBarServiceProvider.overrideWithValue(_HeaderBar()),
      ],
    );
    harness = _Harness(root, container);
    container.read(appSettingsControllerProvider);
    await Future<void>.delayed(Duration.zero);
    await harness.controller.openPath(root.path);
    container.read(appRouterProvider).go('/workspace');
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: harness.container,
      child: const BusyMarkApp(),
    ),
  );
  await _settle(tester);
  return harness;
}

Future<void> _validate(WidgetTester tester) async {
  await tester.runAsync(() async {
    await tester.tap(find.byTooltip('Validate'));
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
}

class _Harness {
  _Harness(this.root, this.container);
  final Directory root;
  final ProviderContainer container;
  String get aPath => p.join(root.path, 'a.md');
  String get bPath => p.join(root.path, 'b.md');
  WorkspaceController get controller =>
      container.read(workspaceControllerProvider.notifier);
  WorkspaceState get state => container.read(workspaceControllerProvider);
  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await tester.pump(const Duration(seconds: 2));
    await tester.runAsync(() => root.delete(recursive: true));
  }
}

class _Settings implements LocalSettingsStore {
  _Settings(this.mode, {this.validateOnEdit = false});
  final DocumentViewModePreference mode;
  final bool validateOnEdit;
  @override
  Future<Map<String, Object?>> load() async => AppSettings.defaults()
      .copyWith(
        documentViewMode: mode,
        validateOnEdit: validateOnEdit,
        autoSave: false,
        sidebarVisible: false,
      )
      .toJson();
  @override
  Future<void> save(Map<String, Object?> json) async {}
}

class _HeaderBar extends LinuxHeaderBarService {
  _HeaderBar() : super(channel: const MethodChannel('test.busymark/problems'));
  @override
  bool get isAvailable => false;
  @override
  bool get usesNativeHeaderBar => false;
}

class _ControlledValidationService extends WorkspaceService {
  bool fail = false;
  Completer<void>? gate;
  String? blockedPath;
  int calls = 0;
  @override
  Future<Workspace> reparseActive(Workspace workspace, String source) async {
    calls++;
    if (fail) throw StateError('Validation failed');
    if (workspace.activeFilePath == blockedPath) await gate?.future;
    return super.reparseActive(workspace, source);
  }
}

class _QueuedValidationService extends WorkspaceService {
  final automaticStarted = Completer<void>();
  final manualStarted = Completer<void>();
  final releaseAutomatic = Completer<void>();
  final releaseManual = Completer<void>();
  int latestCalls = 0;
  final sources = <String>[];

  @override
  Future<Workspace> reparseActive(Workspace workspace, String source) async {
    sources.add(source);
    if (source == '# Automatic first\n') {
      automaticStarted.complete();
      await releaseAutomatic.future;
    } else if (source == '# Latest\n') {
      latestCalls++;
      if (!manualStarted.isCompleted) manualStarted.complete();
      await releaseManual.future;
    }
    return super.reparseActive(workspace, source);
  }
}
