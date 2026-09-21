import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:busymark/l10n/generated/app_localizations_en.dart';
import 'package:busymark/src/app/app_router.dart';
import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/app/busymark_app.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/system_accent.dart';
import 'package:busymark/src/editor/source/source_editor.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_block_widgets.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:busymark/src/local_history/local_history_store.dart';
import 'package:busymark/src/local_history/local_history_controller.dart';
import 'package:busymark/src/platform/linux_header_bar_service.dart';
import 'package:busymark/src/platform/native_menu_service.dart';
import 'package:busymark/src/spellcheck/spelling_dictionary_downloader.dart';
import 'package:busymark/src/spellcheck/spelling_coordinator.dart';
import 'package:busymark/src/spellcheck/spelling_language.dart';
import 'package:busymark/src/spellcheck/spelling_projection.dart';
import 'package:busymark/src/spellcheck/spelling_session_controller.dart';
import 'package:busymark/src/workspace/presentation/workspace_screen.dart';
import 'package:busymark/src/workspace/recovery_persistence.dart';
import 'package:busymark/src/workspace/session_persistence.dart';
import 'package:busymark/src/workspace/workspace_controller.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../support/spelling_test_bundle.dart';

void main() {
  final l10n = AppLocalizationsEn();
  test(
    'workspace spelling UI has no obsolete floating or Material chooser',
    () {
      final source = File(
        'lib/src/workspace/presentation/workspace_screen.dart',
      ).readAsStringSync();
      final chooserStart = source.indexOf(
        'Future<bool> _chooseDocumentSpellingLanguage()',
      );
      final chooserEnd = source.indexOf(
        'void _handleTransactionalSourceChanged',
        chooserStart,
      );
      final chooser = source.substring(chooserStart, chooserEnd);

      expect(source, isNot(contains('_SpellingStatusBanner')));
      expect(chooser, isNot(contains('SimpleDialog')));
      expect(chooser, isNot(contains('SimpleDialogOption')));
      expect(chooser, isNot(contains('AlertDialog')));
    },
  );

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

  for (final viewMode in const [
    DocumentViewModePreference.editor,
    DocumentViewModePreference.split,
  ]) {
    testWidgets(
      'missing dictionary uses one integrated banner in ${viewMode.name}',
      (tester) async {
        final harness = await _pumpWorkspace(
          tester,
          source: 'helo\n',
          dictionaryInstalled: false,
          viewMode: viewMode,
        );
        await _until(
          tester,
          () =>
              harness.spelling.state.status ==
                  SpellingPresentationStatus.dictionaryNotInstalled &&
              find.byType(BusyMarkBanner).evaluate().isNotEmpty,
        );

        final banner = find.byType(BusyMarkBanner);
        final pane = find.byKey(
          ValueKey(
            viewMode == DocumentViewModePreference.editor
                ? 'document-wysiwyg-pane'
                : 'document-source-pane',
          ),
        );
        expect(banner, findsOneWidget);
        expect(
          find.text(
            l10n.spellingDictionaryNotInstalledForLanguage('Test English'),
          ),
          findsOneWidget,
        );
        expect(find.text(l10n.installSpellingDictionary), findsOneWidget);
        expect(
          find.ancestor(
            of: banner,
            matching: find.byType(PositionedDirectional),
          ),
          findsNothing,
        );
        expect(tester.getBottomLeft(banner).dy, tester.getTopLeft(pane).dy);
      },
    );
  }

  testWidgets('language-required state uses one actionable native banner', (
    tester,
  ) async {
    final harness = await _pumpWorkspace(
      tester,
      source: 'helo\n',
      defaultLanguage: null,
    );
    await _until(
      tester,
      () =>
          harness.spelling.state.status ==
              SpellingPresentationStatus.languageRequired &&
          find.byType(BusyMarkBanner).evaluate().isNotEmpty,
    );

    final banner = tester.widget<BusyMarkBanner>(find.byType(BusyMarkBanner));
    expect(banner.title, l10n.chooseSpellingLanguage);
    expect(banner.actionLabel, l10n.chooseSpellingLanguage);
    expect(banner.onAction, isNotNull);
  });

  testWidgets('banner installs the required dictionary and then disappears', (
    tester,
  ) async {
    var downloadCount = 0;
    final harness = await _pumpWorkspace(
      tester,
      source: 'helo\n',
      dictionaryInstalled: false,
      downloadFile:
          ({
            required source,
            required destination,
            required expectedBytes,
            required cancellation,
            required onProgress,
          }) async {
            downloadCount += 1;
            await _copyDictionaryDownload(
              source: source,
              destination: destination,
              expectedBytes: expectedBytes,
              cancellation: cancellation,
              onProgress: onProgress,
            );
          },
    );
    await _until(
      tester,
      () => find.byType(BusyMarkBanner).evaluate().isNotEmpty,
    );

    await tester.tap(find.text(l10n.installSpellingDictionary));
    await _until(
      tester,
      () =>
          downloadCount == 2 &&
          harness.spelling.catalog?.installedById('en-Test') != null &&
          find.byType(BusyMarkBanner).evaluate().isEmpty &&
          harness.spelling.state.complete,
    );

    expect(harness.spelling.state.status, SpellingPresentationStatus.ready);
  });

  testWidgets('failed banner installation keeps the unresolved state', (
    tester,
  ) async {
    final harness = await _pumpWorkspace(
      tester,
      source: 'helo\n',
      dictionaryInstalled: false,
      downloadFile:
          ({
            required source,
            required destination,
            required expectedBytes,
            required cancellation,
            required onProgress,
          }) async {
            throw const SocketException('test dictionary download failure');
          },
    );
    await _until(
      tester,
      () => find.byType(BusyMarkBanner).evaluate().isNotEmpty,
    );

    await tester.tap(find.text(l10n.installSpellingDictionary));
    await _until(
      tester,
      () =>
          harness.spelling.dictionaryInstallStatus?.phase ==
          SpellingDictionaryInstallPhase.failed,
    );

    expect(
      harness.spelling.state.status,
      SpellingPresentationStatus.dictionaryNotInstalled,
    );
    expect(find.byType(BusyMarkBanner), findsOneWidget);
    expect(find.text(l10n.spellingDictionaryInstallFailed), findsOneWidget);
  });

  testWidgets('routine checking does not create persistent editor chrome', (
    tester,
  ) async {
    final coordinator = Completer<SpellingCoordinator>();
    final harness = await _pumpWorkspace(
      tester,
      source: 'helo\n',
      coordinatorStarter: () => coordinator.future,
    );
    await _until(
      tester,
      () =>
          harness.spelling.state.status == SpellingPresentationStatus.checking,
    );

    expect(find.byType(BusyMarkBanner), findsNothing);
  });

  testWidgets('native spelling submenu applies immediate language choices', (
    tester,
  ) async {
    final harness = await _pumpWorkspace(
      tester,
      source: 'helo\n',
      includeSecondLanguage: true,
      viewMode: DocumentViewModePreference.source,
    );
    await _until(tester, () => harness.spelling.state.complete);

    var entries = await _chooseNativeSpellingLanguage(
      tester,
      l10n,
      l10n.disableDocumentSpelling,
    );
    final languageMenu = entries.singleWhere(
      (entry) => entry['label'] == l10n.chooseSpellingLanguage,
    );
    final children = (languageMenu['children'] as List<Object?>)
        .cast<Map<Object?, Object?>>();
    expect(children.map((entry) => entry['label']), [
      l10n.inheritSpellingLanguage,
      l10n.disableDocumentSpelling,
      '',
      'Test English',
      'Test French',
    ]);
    expect(children.where((entry) => entry['selected'] == true), hasLength(1));
    expect(children.first['selected'], isTrue);
    expect(find.byType(SimpleDialog), findsNothing);
    expect(find.byType(SimpleDialogOption), findsNothing);
    await _until(
      tester,
      () =>
          harness.workspace.activeBuffer?.editorState.spellingLanguage ==
          const SpellingLanguageOverride.disabled(),
    );

    harness.controller.updateDocumentEditorState(
      harness.workspace.activeBuffer!.id,
      harness.workspace.activeBuffer!.editorState.copyWith(
        spellingLanguage: const SpellingLanguageOverride.inherit(),
      ),
    );
    await _until(tester, () => harness.spelling.state.complete);
    entries = await _chooseNativeSpellingLanguage(tester, l10n, 'Test English');
    await _until(
      tester,
      () =>
          harness.workspace.activeBuffer?.editorState.spellingLanguage ==
          const SpellingLanguageOverride.selected('en-Test'),
    );
    final updatedMenu = entries.singleWhere(
      (entry) => entry['label'] == l10n.chooseSpellingLanguage,
    );
    expect(updatedMenu['children'], isNotNull);

    await _until(tester, () => harness.spelling.state.complete);
    final selectedEntries = await _chooseNativeSpellingLanguage(
      tester,
      l10n,
      l10n.inheritSpellingLanguage,
    );
    final selectedLanguageMenu = selectedEntries.singleWhere(
      (entry) => entry['label'] == l10n.chooseSpellingLanguage,
    );
    final selectedChildren = (selectedLanguageMenu['children'] as List<Object?>)
        .cast<Map<Object?, Object?>>();
    expect(
      selectedChildren.where((entry) => entry['selected'] == true),
      hasLength(1),
    );
    expect(
      selectedChildren.singleWhere(
        (entry) => entry['label'] == 'Test English',
      )['selected'],
      isTrue,
    );
    await _until(
      tester,
      () =>
          harness.workspace.activeBuffer?.editorState.spellingLanguage ==
          const SpellingLanguageOverride.inherit(),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await _until(tester, () => harness.spelling.state.complete);
  });

  testWidgets('cancelling document dictionary install preserves override', (
    tester,
  ) async {
    final harness = await _pumpWorkspace(
      tester,
      source: 'helo\n',
      includeSecondLanguage: true,
      viewMode: DocumentViewModePreference.source,
    );
    await _until(tester, () => harness.spelling.state.complete);
    const previous = SpellingLanguageOverride.inherit();

    await _chooseNativeSpellingLanguage(tester, l10n, 'Test French');
    expect(find.text(l10n.spellingDictionaryNotInstalled), findsOneWidget);
    expect(find.byType(BusyMarkDialogShell), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(
      harness.workspace.activeBuffer?.editorState.spellingLanguage,
      previous,
    );
    await tester.tap(find.text(l10n.cancel));
    await tester.pumpAndSettle();

    expect(
      harness.workspace.activeBuffer?.editorState.spellingLanguage,
      previous,
    );
    expect(harness.spelling.catalog?.installedById('fr-Test'), isNull);
  });

  testWidgets('document language changes only after dictionary installation', (
    tester,
  ) async {
    final releaseDownload = Completer<void>();
    var downloadCount = 0;
    final harness = await _pumpWorkspace(
      tester,
      source: 'helo\n',
      includeSecondLanguage: true,
      viewMode: DocumentViewModePreference.source,
      downloadFile:
          ({
            required source,
            required destination,
            required expectedBytes,
            required cancellation,
            required onProgress,
          }) async {
            downloadCount += 1;
            await releaseDownload.future;
            await _copyDictionaryDownload(
              source: source,
              destination: destination,
              expectedBytes: expectedBytes,
              cancellation: cancellation,
              onProgress: onProgress,
            );
          },
    );
    await _until(tester, () => harness.spelling.state.complete);

    await _chooseNativeSpellingLanguage(tester, l10n, 'Test French');
    await tester.tap(find.text(l10n.installSpellingDictionary));
    await _until(tester, () => downloadCount > 0);
    expect(
      harness.workspace.activeBuffer?.editorState.spellingLanguage,
      const SpellingLanguageOverride.inherit(),
    );

    releaseDownload.complete();
    await _until(
      tester,
      () =>
          harness.workspace.activeBuffer?.editorState.spellingLanguage ==
          const SpellingLanguageOverride.selected('fr-Test'),
    );
    expect(harness.spelling.catalog?.installedById('fr-Test'), isNotNull);
    await tester.pump(const Duration(milliseconds: 300));
    await _until(tester, () => harness.spelling.state.complete);
  });

  testWidgets('failed document dictionary install preserves override', (
    tester,
  ) async {
    final harness = await _pumpWorkspace(
      tester,
      source: 'helo\n',
      includeSecondLanguage: true,
      viewMode: DocumentViewModePreference.source,
      downloadFile:
          ({
            required source,
            required destination,
            required expectedBytes,
            required cancellation,
            required onProgress,
          }) async {
            throw const SocketException('test dictionary download failure');
          },
    );
    await _until(tester, () => harness.spelling.state.complete);

    await _chooseNativeSpellingLanguage(tester, l10n, 'Test French');
    await tester.tap(find.text(l10n.installSpellingDictionary));
    await _until(
      tester,
      () =>
          harness.spelling.dictionaryInstallStatus?.phase ==
          SpellingDictionaryInstallPhase.failed,
    );

    expect(
      harness.workspace.activeBuffer?.editorState.spellingLanguage,
      const SpellingLanguageOverride.inherit(),
    );
    expect(find.text(l10n.spellingDictionaryInstallFailed), findsOneWidget);
  });
}

Future<_Harness> _pumpWorkspace(
  WidgetTester tester, {
  String? source,
  bool writerside = false,
  bool dictionaryInstalled = true,
  bool includeSecondLanguage = false,
  DocumentViewModePreference viewMode = DocumentViewModePreference.editor,
  String? defaultLanguage = 'en-Test',
  SpellingDictionaryFileDownload? downloadFile,
  SpellingCoordinatorStarter? coordinatorStarter,
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
    if (includeSecondLanguage) {
      final catalogFile = File(p.join(bundle, 'dictionaries.json'));
      final catalog =
          jsonDecode(await catalogFile.readAsString()) as Map<String, Object?>;
      final dictionaries = catalog['dictionaries']! as List<Object?>;
      final english = Map<String, Object?>.from(
        dictionaries.single! as Map<Object?, Object?>,
      );
      dictionaries.add({
        ...english,
        'resourceId': 'fr-Test',
        'id': 'fr-Test',
        'locales': ['fr-Test'],
        'label': 'Test French',
      });
      await catalogFile.writeAsString(jsonEncode(catalog));
    }
    if (!dictionaryInstalled) {
      await Directory(
        p.join(root.path, 'dictionary-storage', 'downloaded', 'en-Test'),
      ).delete(recursive: true);
    }
    spelling = SpellingSessionController(
      bundledRoot: bundle,
      applicationSupportRoot: p.join(root.path, 'support'),
      dictionaryStorageRoot: p.join(root.path, 'dictionary-storage'),
      dictionaryDownloader: downloadFile == null
          ? const SpellingDictionaryDownloader()
          : SpellingDictionaryDownloader(downloadFile: downloadFile),
      coordinatorStarter: coordinatorStarter,
    );
  });
  final container = ProviderContainer(
    overrides: [
      localSettingsStoreProvider.overrideWithValue(
        _Settings(viewMode, defaultLanguage),
      ),
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
  const _Settings(this.viewMode, this.defaultLanguage);

  final DocumentViewModePreference viewMode;
  final String? defaultLanguage;

  @override
  Future<Map<String, Object?>> load() async => AppSettings.defaults()
      .copyWith(
        defaultSpellingLanguage: defaultLanguage,
        automaticSpelling: true,
        autoSave: false,
        reopenPreviousWorkspaceOnStartup: false,
        documentViewMode: viewMode,
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

Future<void> _copyDictionaryDownload({
  required Uri source,
  required File destination,
  required int expectedBytes,
  required SpellingDictionaryDownloadCancellation cancellation,
  required void Function(int receivedBytes) onProgress,
}) async {
  cancellation.throwIfCancelled();
  final fileName = source.path.endsWith('.aff') ? 'test.aff' : 'test.dic';
  final sourceFile = File(
    p.join(
      Directory.current.path,
      'packages',
      'busymark_spellcheck_native',
      'test',
      'fixtures',
      fileName,
    ),
  );
  final bytes = await sourceFile.readAsBytes();
  if (bytes.length != expectedBytes) {
    throw StateError('Test dictionary size does not match its catalog.');
  }
  await destination.writeAsBytes(bytes, flush: true);
  onProgress(bytes.length);
}

Future<List<Map<Object?, Object?>>> _chooseNativeSpellingLanguage(
  WidgetTester tester,
  AppLocalizationsEn l10n,
  String label,
) async {
  List<Map<Object?, Object?>>? entries;
  const channel = MethodChannel(nativeMenuChannelName);
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
    call,
  ) async {
    if (call.method != 'show') return false;
    final arguments = call.arguments as Map<Object?, Object?>;
    entries = (arguments['entries'] as List<Object?>)
        .cast<Map<Object?, Object?>>();
    return _nativeMenuIndexForLabel(entries!, label);
  });
  addTearDown(() {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      null,
    );
  });
  final field = find.descendant(
    of: find.byType(BusyMarkSourceEditor),
    matching: find.byType(TextField),
  );
  final render = _findRenderEditable(tester.renderObject(field))!;
  final caret = render.getLocalRectForCaret(const TextPosition(offset: 1));
  await tester.tapAt(
    render.localToGlobal(caret.center),
    buttons: kSecondaryMouseButton,
  );
  await _until(tester, () => entries != null);
  expect(entries, isNotNull);
  expect(
    entries!.any((entry) => entry['label'] == l10n.chooseSpellingLanguage),
    isTrue,
  );
  return entries!;
}

int _nativeMenuIndexForLabel(
  List<Map<Object?, Object?>> entries,
  String label,
) {
  var index = 0;
  int? visit(List<Map<Object?, Object?>> items) {
    for (final item in items) {
      final current = index++;
      if (item['label'] == label) return current;
      final children = item['children'];
      if (children is List<Object?>) {
        final found = visit(children.cast<Map<Object?, Object?>>());
        if (found != null) return found;
      }
    }
    return null;
  }

  return visit(entries) ?? -1;
}

RenderEditable? _findRenderEditable(RenderObject root) {
  if (root is RenderEditable) return root;
  RenderEditable? result;
  root.visitChildren((child) {
    result ??= _findRenderEditable(child);
  });
  return result;
}
