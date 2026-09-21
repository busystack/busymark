import 'dart:async';
import 'dart:io';

import 'package:busymark/l10n/generated/app_localizations_en.dart';
import 'package:busymark/src/app/app_router.dart';
import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/app/busymark_app.dart';
import 'package:busymark/src/app/system_accent.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_block_widgets.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:busymark/src/local_history/local_history_store.dart';
import 'package:busymark/src/local_history/local_history_controller.dart';
import 'package:busymark/src/platform/linux_header_bar_service.dart';
import 'package:busymark/src/spellcheck/spelling_projection.dart';
import 'package:busymark/src/spellcheck/spelling_session_controller.dart';
import 'package:busymark/src/workspace/presentation/workspace_screen.dart';
import 'package:busymark/src/workspace/recovery_persistence.dart';
import 'package:busymark/src/workspace/session_persistence.dart';
import 'package:busymark/src/workspace/workspace_controller.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../support/spelling_test_bundle.dart';

void main() {
  final l10n = AppLocalizationsEn();
  setUp(() {
    for (final name in ['yaru_window', 'yaru_window/events']) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            MethodChannel(name),
            (call) async => call.method == 'state' ? <String, Object?>{} : null,
          );
    }
  });
  tearDown(() {
    for (final name in ['yaru_window', 'yaru_window/events']) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(name), null);
    }
  });

  testWidgets(
    'Writerside nested TOC and comment retain rich spelling through correction',
    (tester) async {
      const source =
          '# hello\n\n- [hello](#hello)\n  - [world](#world)\n- [hello](#hello)\n<!-- busymark:toc:end -->\n\n## world\n\nhelo **world**\n';
      final harness = await _pumpWorkspace(
        tester,
        source: source,
        writerside: true,
      );
      await _until(tester, () => harness.spelling.state.complete);
      expect(harness.spelling.misspellings.map((o) => o.word), ['helo']);
      final occurrence = harness.spelling.misspellings.single;
      expect(occurrence.run.target, isA<SpellingRichBlockTarget>());
      final target = occurrence.run.target as SpellingRichBlockTarget;
      final view = tester
          .widgetList<BusyMarkWysiwygBlockField>(
            find.byType(BusyMarkWysiwygBlockField),
          )
          .singleWhere((v) => v.block.id == target.blockId);
      expect(view.spellingRanges, isNotEmpty);
      await tester.sendKeyEvent(LogicalKeyboardKey.f7);
      final dialog = find.byType(BusyMarkSpellingReviewDialog);
      await _until(
        tester,
        () => find
            .descendant(of: dialog, matching: find.text('hello'))
            .evaluate()
            .isNotEmpty,
      );
      await tester.tap(
        find.descendant(of: dialog, matching: find.text('hello')),
      );
      await _until(
        tester,
        () => dialog.evaluate().isEmpty && harness.spelling.state.complete,
      );
      expect(harness.workspace.activeText, contains('hello **world**'));
      expect(
        harness.workspace.activeText,
        contains('<!-- busymark:toc:end -->'),
      );
      expect(harness.spelling.misspellings, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Ctrl+N typing paints live spelling targets and corrects with undo',
    (tester) async {
      final harness = await _pumpWorkspace(tester);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.createMarkdownFile).last);
      await _until(
        tester,
        () => find.byType(BusyMarkWysiwygEditor).evaluate().isNotEmpty,
      );
      final editor = find.byType(BusyMarkWysiwygEditor);
      final field = find.descendant(
        of: editor,
        matching: find.byType(EditableText),
      );
      await tester.enterText(field, 'helo');
      await _until(
        tester,
        () =>
            harness.spelling.state.complete &&
            harness.spelling.misspellings.any((o) => o.word == 'helo'),
      );
      final view = tester.widget<BusyMarkWysiwygBlockField>(
        find.byType(BusyMarkWysiwygBlockField),
      );
      final target =
          harness.spelling.misspellings.single.run.target
              as SpellingRichBlockTarget;
      expect(target.blockId, view.block.id);
      expect(harness.spelling.state.complete, isTrue);
      expect(harness.spelling.misspellings.single.word, 'helo');
      expect(view.spellingRanges, [const TextRange(start: 0, end: 4)]);
      expect(harness.workspace.activeText, 'helo');
      final liveController = _controllerForSpellingOverlay(tester, 'helo');
      expect(
        liveController.selection,
        const TextSelection.collapsed(offset: 4),
      );
      expect(
        busyMarkSpellingUnderlineSuppressed(
          liveController,
          const TextRange(start: 0, end: 4),
        ),
        isFalse,
      );
      expect(_spellingUnderlineOverlay(), findsOneWidget);

      // A structural edit can change live IDs/generation without changing the
      // committed source (the new buffer has no final newline). It must still
      // rebind spelling to the mounted tree.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await _until(tester, () {
        final occurrences = harness.spelling.misspellings;
        if (!harness.spelling.state.complete || occurrences.isEmpty) {
          return false;
        }
        final currentTarget =
            occurrences.single.run.target as SpellingRichBlockTarget;
        return currentTarget.documentGeneration ==
            tester
                .state<BusyMarkWysiwygEditorState>(editor)
                .spellingDocumentGeneration;
      });
      expect(harness.workspace.activeText, 'helo');
      expect(
        tester
            .widgetList<BusyMarkWysiwygBlockField>(
              find.byType(BusyMarkWysiwygBlockField),
            )
            .where((v) => v.spellingRanges.isNotEmpty),
        hasLength(1),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.f7);
      await _until(
        tester,
        () => find
            .descendant(
              of: find.byType(BusyMarkSpellingReviewDialog),
              matching: find.text('hello'),
            )
            .evaluate()
            .isNotEmpty,
      );
      await tester.tap(
        find.descendant(
          of: find.byType(BusyMarkSpellingReviewDialog),
          matching: find.text('hello'),
        ),
      );
      await _until(
        tester,
        () =>
            harness.workspace.activeText == 'hello' &&
            find.byType(BusyMarkSpellingReviewDialog).evaluate().isEmpty,
      );
      harness.controller.undoActiveBuffer();
      await _until(
        tester,
        () =>
            harness.spelling.state.complete &&
            harness.spelling.misspellings.any((o) => o.word == 'helo'),
      );
      expect(harness.workspace.activeText, 'helo');
      final undoView = _viewWithSpellingOverlay(tester, 'helo');
      expect(undoView.spellingRanges, [const TextRange(start: 0, end: 4)]);
      final undoController = _controllerForSpellingOverlay(tester, 'helo');
      expect(undoController.selection.isCollapsed, isTrue);
      expect(
        busyMarkSpellingUnderlineSuppressed(
          undoController,
          const TextRange(start: 0, end: 4),
        ),
        isFalse,
      );
      expect(_spellingUnderlineOverlay(), findsOneWidget);
      harness.controller.redoActiveBuffer();
      await _until(
        tester,
        () =>
            harness.spelling.state.complete &&
            harness.spelling.misspellings.isEmpty,
      );
      expect(harness.workspace.activeText, 'hello');
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('confirmed spelling underline survives continued typing', (
    tester,
  ) async {
    final harness = await _pumpWorkspace(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.createMarkdownFile).last);
    await _until(
      tester,
      () => find.byType(BusyMarkWysiwygEditor).evaluate().isNotEmpty,
    );
    final field = find.descendant(
      of: find.byType(BusyMarkWysiwygEditor),
      matching: find.byType(EditableText),
    );

    await tester.enterText(field, 'helo');
    await _until(
      tester,
      () =>
          harness.spelling.state.complete &&
          harness.spelling.misspellings.any((item) => item.word == 'helo'),
    );
    var controller = _controllerForSpellingOverlay(tester, 'helo');
    expect(controller.selection.extentOffset, 4);
    expect(
      busyMarkSpellingUnderlineSuppressed(
        controller,
        const TextRange(start: 0, end: 4),
      ),
      isFalse,
    );

    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'helo ',
        selection: TextSelection.collapsed(offset: 5),
      ),
    );
    controller = _controllerForSpellingOverlay(tester, 'helo ');
    expect(controller.text, 'helo ');
    expect(controller.selection.extentOffset, 5);
    expect(
      busyMarkSpellingUnderlineSuppressed(
        controller,
        const TextRange(start: 0, end: 4),
      ),
      isFalse,
    );
    expect(_spellingUnderlineOverlay(), findsOneWidget);

    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'helo world',
        selection: TextSelection.collapsed(offset: 10),
      ),
    );
    await _until(
      tester,
      () =>
          harness.workspace.activeText == 'helo world' &&
          harness.spelling.state.complete &&
          harness.spelling.misspellings.length == 1 &&
          harness.spelling.misspellings.single.word == 'helo' &&
          _wysiwygViewWithSpellingRanges(
            text: 'helo world',
          ).evaluate().isNotEmpty,
    );
    controller = _controllerForSpellingOverlay(tester, 'helo world');
    expect(controller.selection.extentOffset, 10);
    expect(
      busyMarkSpellingUnderlineSuppressed(
        controller,
        const TextRange(start: 0, end: 4),
      ),
      isFalse,
    );
    expect(_spellingUnderlineOverlay(), findsOneWidget);

    controller.selection = const TextSelection.collapsed(offset: 3);
    await tester.pump();
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'helxo world',
        selection: TextSelection.collapsed(offset: 4),
      ),
    );
    await _until(
      tester,
      () =>
          harness.workspace.activeText == 'helxo world' &&
          harness.spelling.state.complete &&
          harness.spelling.misspellings.length == 1 &&
          harness.spelling.misspellings.single.word == 'helxo' &&
          _wysiwygViewWithSpellingRanges(
            text: 'helxo world',
          ).evaluate().isNotEmpty,
    );
    controller = _controllerForSpellingOverlay(tester, 'helxo world');
    expect(controller.selection.extentOffset, 4);
    expect(_viewWithSpellingOverlay(tester, 'helxo world').spellingRanges, [
      const TextRange(start: 0, end: 5),
    ]);
    expect(
      busyMarkSpellingUnderlineSuppressed(
        controller,
        const TextRange(start: 0, end: 5),
      ),
      isFalse,
    );
    expect(_spellingUnderlineOverlay(), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final source in [
    'helo caf&#233;\n\nwrld\n',
    'helo  \nworld\n\nwrld\n',
    '| helo caf&#233; |\n| --- |\n| hello |\n\nwrld\n',
  ]) {
    testWidgets(
      'real rich review retains later visits after serialization: $source',
      (tester) async {
        final harness = await _pumpWorkspace(tester, source: source);
        await _until(
          tester,
          () =>
              harness.spelling.state.complete &&
              harness.spelling.misspellings.any((o) => o.word == 'wrld'),
        );
        // Start at the later occurrence, then visit earlier words by wrapping.
        final state = tester.state<BusyMarkWysiwygEditorState>(
          find.byType(BusyMarkWysiwygEditor),
        );
        state.revealSpellingOccurrence(
          harness.spelling.misspellings.firstWhere((o) => o.word == 'wrld'),
        );
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.f7);
        final dialog = find.byType(BusyMarkSpellingReviewDialog);
        await _until(
          tester,
          () => find
              .descendant(of: dialog, matching: find.text('wrld'))
              .evaluate()
              .isNotEmpty,
        );
        await tester.tap(
          find.descendant(
            of: dialog,
            matching: find.text(l10n.sourceSearchNextMatch),
          ),
        );
        await _until(
          tester,
          () => find
              .descendant(of: dialog, matching: find.text('hello'))
              .evaluate()
              .isNotEmpty,
        );
        await tester.tap(
          find.descendant(of: dialog, matching: find.text('hello')),
        );
        await _until(
          tester,
          () => !harness.workspace.activeText.contains('helo'),
        );
        if (source.contains('&#233;')) {
          expect(harness.workspace.activeText, contains('café'));
          expect(harness.workspace.activeText, isNot(contains('&#233;')));
        }
        // The fixture deliberately does not contain café. Ignore it if present;
        // the previously visited wrld must not become the next review item.
        await _until(
          tester,
          () =>
              dialog.evaluate().isEmpty ||
              find
                  .descendant(of: dialog, matching: find.text('café'))
                  .evaluate()
                  .isNotEmpty,
        );
        if (dialog.evaluate().isNotEmpty) {
          await tester.tap(
            find.descendant(
              of: dialog,
              matching: find.text(l10n.ignoreSpellingOnce),
            ),
          );
        }
        await _until(tester, () => dialog.evaluate().isEmpty);
        await _until(tester, () => harness.spelling.state.complete);
        expect(
          harness.spelling.misspellings.map((o) => o.word),
          contains('wrld'),
        );
        expect(harness.workspace.activeText, endsWith('wrld\n'));
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}

Future<_Harness> _pumpWorkspace(
  WidgetTester tester, {
  String? source,
  bool writerside = false,
}) async {
  await tester.binding.setSurfaceSize(const Size(1400, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  late Directory root;
  late SpellingSessionController spelling;
  await tester.runAsync(() async {
    root = await Directory.systemTemp.createTemp(
      'busymark-spelling-workspace-',
    );
    final bundle = await createSpellingTestBundle(root);
    spelling = SpellingSessionController(
      bundledRoot: bundle,
      applicationSupportRoot: p.join(root.path, 'support'),
      dictionaryStorageRoot: p.join(root.path, 'dictionary-storage'),
    );
  });
  final container = ProviderContainer(
    overrides: [
      localSettingsStoreProvider.overrideWithValue(_Settings()),
      localHistoryStoreProvider.overrideWithValue(MemoryLocalHistoryStore()),
      documentSessionStoreProvider.overrideWithValue(
        MemoryDocumentSessionStore(),
      ),
      documentRecoveryStoreProvider.overrideWithValue(
        MemoryDocumentRecoveryStore(),
      ),
      linuxHeaderBarServiceProvider.overrideWithValue(_HeaderBar()),
      systemAccentColorProvider.overrideWith((ref) => const Stream.empty()),
      spellingSessionControllerProvider.overrideWith((ref) => spelling),
    ],
  );
  addTearDown(() async {
    container.dispose();
    await root.delete(recursive: true);
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const BusyMarkApp()),
  );
  await tester.pumpAndSettle();
  final controller = container.read(workspaceControllerProvider.notifier);
  if (source != null) {
    await tester.runAsync(() async {
      final file = File(
        p.join(root.path, writerside ? 'topics/document.md' : 'document.md'),
      );
      await file.parent.create(recursive: true);
      await file.writeAsString(source);
      if (writerside) {
        await File(p.join(root.path, 'writerside.cfg')).writeAsString(
          '<ihp version="2.0"><topics dir="topics"/><instance src="guide.tree"/></ihp>',
        );
        await File(p.join(root.path, 'guide.tree')).writeAsString(
          '<instance-profile id="guide" name="Guide" start-page="document.md"><toc-element topic="document.md"/></instance-profile>',
        );
      }
      await controller.openPath(writerside ? root.path : file.path);
    });
    container.read(appRouterProvider).go('/workspace');
    await tester.pumpAndSettle();
  }
  return _Harness(container, spelling);
}

class _Harness {
  _Harness(this.container, this.spelling);
  final ProviderContainer container;
  final SpellingSessionController spelling;
  WorkspaceController get controller =>
      container.read(workspaceControllerProvider.notifier);
  WorkspaceState get workspace => container.read(workspaceControllerProvider);
}

BusyMarkWysiwygBlockField _viewWithSpellingOverlay(
  WidgetTester tester,
  String text,
) => tester.widget<BusyMarkWysiwygBlockField>(
  _wysiwygViewWithSpellingRanges(text: text),
);

TextEditingController _controllerForSpellingOverlay(
  WidgetTester tester,
  String text,
) => tester
    .widgetList<EditableText>(
      find.descendant(
        of: find.byType(BusyMarkWysiwygEditor),
        matching: find.byType(EditableText),
      ),
    )
    .map((editable) => editable.controller)
    .singleWhere((controller) => controller.text == text);

Finder _wysiwygViewWithSpellingRanges({required String text}) =>
    find.byWidgetPredicate(
      (widget) =>
          widget is BusyMarkWysiwygBlockField &&
          widget.block.plainText == text &&
          widget.spellingRanges.isNotEmpty,
    );

Finder _spellingUnderlineOverlay() => find.byWidgetPredicate(
  (widget) =>
      widget is CustomPaint &&
      widget.painter.runtimeType.toString() == '_SpellingUnderlinePainter',
);

Future<void> _until(WidgetTester tester, bool Function() condition) async {
  final elapsed = Stopwatch()..start();
  while (!condition()) {
    if (elapsed.elapsed > const Duration(seconds: 10)) {
      throw TimeoutException('Spelling workspace did not settle');
    }
    await tester.pump(const Duration(milliseconds: 50));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
  }
  await tester.pump();
}

class _Settings implements LocalSettingsStore {
  @override
  Future<Map<String, Object?>> load() async => AppSettings.defaults()
      .copyWith(
        defaultSpellingLanguage: 'en-Test',
        automaticSpelling: true,
        autoSave: false,
        reopenPreviousWorkspaceOnStartup: false,
        documentViewMode: DocumentViewModePreference.editor,
      )
      .toJson();
  @override
  Future<void> save(Map<String, Object?> value) async {}
}

class _HeaderBar extends LinuxHeaderBarService {
  _HeaderBar() : super(channel: const MethodChannel('test.busymark/spelling'));
  @override
  bool get isAvailable => false;
  @override
  bool get usesNativeHeaderBar => false;
  @override
  Stream<HeaderBarAction> get actions => const Stream.empty();
}
