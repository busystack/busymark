import 'package:busymark/src/spellcheck/spelling_catalog.dart';
import 'package:busymark/src/workspace/presentation/welcome_screen.dart';
import 'package:busymark/src/workspace/presentation/settings_screen.dart';
import 'package:busymark/src/app/keymap_controller.dart';
import 'package:busymark/src/app/keyboard_shortcut_badge.dart';
import 'package:busymark/src/app/shortcut_binding.dart';
import 'package:busymark/src/app/shortcut_capture.dart';
import 'package:busymark/src/workspace/presentation/keyboard_shortcuts_settings.dart';
import 'package:busymark/src/search/search_session.dart';
import 'package:busymark/src/core/path_utils.dart';
import 'package:busymark/src/platform/native_writerside_dialog_service.dart';
import 'dart:async';
import 'package:busymark/src/editor/wysiwyg/writerside_properties.dart';
import 'dart:convert';
import 'dart:io';

import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/l10n/generated/app_localizations_ar.dart';
import 'package:busymark/l10n/generated/app_localizations_de.dart';
import 'package:busymark/l10n/generated/app_localizations_en.dart';
import 'package:busymark/l10n/generated/app_localizations_fa.dart';
import 'package:busymark/l10n/generated/app_localizations_fr.dart';
import 'package:busymark/src/app/app_metadata.dart';
import 'package:busymark/src/app/app_router.dart';
import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/app/busymark_app.dart';
import 'package:busymark/src/app/command_registry.dart';
import 'package:busymark/src/app/busymark_dialogs.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/busymark_glyphs.dart';
import 'package:busymark/src/app/busymark_shortcuts.dart';
import 'package:busymark/src/app/linux/linux_header_style.dart';
import 'package:busymark/src/app/startup_path.dart';
import 'package:busymark/src/app/system_accent.dart';
import 'package:busymark/src/app/window_control_service.dart';
import 'package:busymark/src/app/git_dismissal.dart';
import 'package:busymark/src/core/busymark_exception.dart';
import 'package:busymark/src/core/diagnostic.dart';
import 'package:busymark/src/core/local_image_resolver.dart';
import 'package:busymark/src/core/source_span.dart';
import 'package:busymark/src/clipboard/clipboard_history_controller.dart';
import 'package:busymark/src/clipboard/clipboard_history_panel.dart';
import 'package:busymark/src/clipboard/clipboard_insertion.dart';
import 'package:busymark/src/clipboard/clipboard_models.dart';
import 'package:busymark/src/editor/document_callout.dart';
import 'package:busymark/src/editor/document_code_block.dart';
import 'package:busymark/src/editor/document_layout.dart';
import 'package:busymark/src/editor/document_list_marker.dart';
import 'package:busymark/src/editor/document_text_geometry.dart';
import 'package:busymark/src/editor/document_thematic_break.dart';
import 'package:busymark/src/editor/markdown_image_view.dart';
import 'package:busymark/src/editor/source/source_editor.dart';
import 'package:busymark/src/editor/source_highlighter.dart'
    show BusyMarkSourceEditingController;
import 'package:busymark/src/editor/source/source_read_only_view.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_session_state.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_inline_controller.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/feedback/presentation/feedback_dialog.dart';
import 'package:busymark/src/export/export_options_editor.dart';
import 'package:busymark/src/git/application/git_controller.dart';
import 'package:busymark/src/git/application/shared_git_integration.dart';
import 'package:busystack_git_flutter/busystack_git_flutter.dart' as shared;
import 'package:busymark/src/git/domain/git_models.dart';
import 'package:busymark/src/git/presentation/git_diff_viewer.dart';
import 'package:busymark/src/local_history/local_history_controller.dart';
import 'package:busymark/src/local_history/local_history_panel.dart';
import 'package:busymark/src/local_history/local_history_store.dart';
import 'package:busymark/src/local_history/local_history_models.dart';
import 'package:busymark/src/local_history/local_history_comparison_view.dart';
import 'package:busymark/src/markdown/preview_model.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/platform/linux_gtk_accent_service.dart';
import 'package:busymark/src/platform/gtk_header_icon_service.dart';
import 'package:busymark/src/platform/linux_header_bar_service.dart';
import 'package:busymark/src/platform/rich_clipboard_service.dart';
import 'package:busymark/src/spellcheck/spelling_dictionary_downloader.dart';
import 'package:busymark/src/spellcheck/spelling_session_controller.dart';
import 'package:busymark/src/writerside/writerside_model.dart';
import 'package:busymark/src/writerside/writerside_project.dart';
import 'package:busymark/src/writerside/writerside_toc_editor.dart';
import 'package:busymark/src/writerside/writerside_topic_creator.dart';
import 'package:busymark/src/writerside/writerside_topic_file_editor.dart';
import 'package:busymark/src/writerside/writerside_topic_removal_service.dart';
import 'package:busymark/src/workspace/document_buffer.dart';
import 'package:busymark/src/workspace/recovery_persistence.dart';
import 'package:busymark/src/workspace/session_persistence.dart';
import 'package:busymark/src/workspace/workspace_controller.dart';
import 'package:busymark/src/workspace/workspace_file_monitor.dart';
import 'package:busymark/src/workspace/workspace_message.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:busymark/src/workspace/workspace_service.dart';
import 'package:busymark/src/workspace/text_format_metadata.dart';
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

import '../support/spelling_test_bundle.dart';
import '../support/widget_async.dart';
import '../support/shared_git_read_fixture.dart';

void main() {
  late _FallbackHeaderBarService headerBarService;
  final l10n = AppLocalizationsEn();

  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.defaultRouteNameTestValue = '/';
    for (final channelName in ['yaru_window', 'yaru_window/events']) {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        MethodChannel(channelName),
        (call) async => call.method == 'state' ? <String, Object?>{} : null,
      );
    }
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel(nativeWritersideDialogChannelName),
      (_) async => throw MissingPluginException(),
    );
    headerBarService = _FallbackHeaderBarService();
  });

  for (final fail in [false, true]) {
    testWidgets(
      'prepared editor is visible during recent persistence failure=$fail',
      (tester) async {
        final settings = _GatedRecentSettingsStore(fail: fail);
        addTearDown(() {
          if (!settings.release.isCompleted) settings.release.complete();
        });
        final container = ProviderContainer(
          overrides: [
            ..._smokeAccentOverrides,
            linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
            localSettingsStoreProvider.overrideWithValue(settings),
            workspaceServiceProvider.overrideWithValue(
              _StartupWorkspaceService(),
            ),
            localHistoryStoreProvider.overrideWithValue(
              MemoryLocalHistoryStore(),
            ),
            documentSessionStoreProvider.overrideWithValue(
              MemoryDocumentSessionStore(),
            ),
            documentRecoveryStoreProvider.overrideWithValue(
              MemoryDocumentRecoveryStore(),
            ),
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
        await _pumpUntilFound(
          tester,
          find.byKey(const ValueKey('workspace-page-frame')),
        );
        expect(settings.entered.isCompleted, isTrue);
        expect(settings.release.isCompleted, isFalse);
        expect(container.read(workspaceControllerProvider).isLoading, isFalse);
        expect(
          container.read(workspaceControllerProvider).activeText,
          '# Basic Markdown\n',
        );
        final search = container.read(searchSessionProvider.notifier);
        search.open(category: SearchCategory.file);
        search.query('Basic');
        await tester.runAsync(search.submit);
        await tester.pumpAndSettle();
        expect(
          container
              .read(searchSessionProvider)
              .results
              .whereType<TextSearchResult>(),
          isNotEmpty,
        );
        expect(
          find.byKey(const ValueKey('shared-search-query')),
          findsOneWidget,
        );
        search.close(restoreFocus: false);
        await tester.pumpAndSettle();
        var shutdownComplete = false;
        final shutdown = container
            .read(workspaceControllerProvider.notifier)
            .markCleanShutdown()
            .then((_) => shutdownComplete = true);
        await tester.pump();
        expect(shutdownComplete, isFalse);
        settings.release.complete();
        await tester.pump();
        if (fail) {
          expect(
            container.read(workspaceControllerProvider).message?.code,
            WorkspaceMessageCode.recentWorkspaceUpdateFailed,
          );
        } else {
          expect(settings.value['recentWorkspaces'], isNotEmpty);
        }
        await pumpUntil(
          tester,
          () => shutdownComplete,
          operation: 'settings shutdown barrier',
        );
        expect(shutdownComplete, isTrue);
        await shutdown;
        expect(
          container.read(workspaceControllerProvider).activeText,
          '# Basic Markdown\n',
        );
        expect(
          container.read(workspaceControllerProvider).message?.code,
          isNot(WorkspaceMessageCode.openFailed),
        );
        if (fail) {
          final message = container.read(workspaceControllerProvider).message!;
          final warning = 'Could not update Recent items: ${message.error}.';
          expect(find.text(warning), findsOneWidget);
          expect(
            busyMarkWorkspaceMessageStatusKind(message.code),
            BusyMarkStatusKind.warning,
          );
        }
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  for (final mode in [
    DocumentViewModePreference.source,
    DocumentViewModePreference.split,
  ]) {
    testWidgets(
      'effective Select All and Alt+Enter edit the full document in ${mode.name}',
      (tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final root = Directory.systemTemp.createTempSync(
          'busymark-effective-source-',
        );
        addTearDown(() => root.deleteSync(recursive: true));
        const original =
            '## Fold\nfirst hidden\nsecond hidden\n\n## Next\nbefore target after\n';
        final file = File('${root.path}/document.md')
          ..writeAsStringSync(original);
        final store = _MemorySettingsStore()
          ..value = AppSettings.defaults()
              .copyWith(autoSave: false, documentViewMode: mode)
              .toJson();
        final container = ProviderContainer(
          overrides: [
            ..._smokeAccentOverrides,
            linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
            localSettingsStoreProvider.overrideWithValue(store),
            localHistoryStoreProvider.overrideWithValue(
              MemoryLocalHistoryStore(),
            ),
            documentSessionStoreProvider.overrideWithValue(
              MemoryDocumentSessionStore(),
            ),
            documentRecoveryStoreProvider.overrideWithValue(
              MemoryDocumentRecoveryStore(),
            ),
            startupPathProvider.overrideWithValue(file.path),
          ],
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const BusyMarkApp(),
          ),
        );
        await _waitForSearchCondition(
          tester,
          () => find.byType(BusyMarkSourceEditor).evaluate().isNotEmpty,
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<BusyMarkSourceEditor>(find.byType(BusyMarkSourceEditor))
              .searchSnapshot,
          isNotNull,
        );
        final source = _searchSourceController(tester);
        final field = tester.widget<TextField>(
          find.byWidgetPredicate(
            (w) => w is TextField && identical(w.controller, source),
          ),
        );
        final keymap = container.read(keymapControllerProvider.notifier);
        Map<String, BusyMarkKeyBinding?> current() =>
            container.read(appSettingsControllerProvider).shortcutOverrides;
        Future<void> press(
          LogicalKeyboardKey key, {
          bool control = false,
          bool alt = false,
          bool shift = false,
        }) async {
          field.focusNode!.requestFocus();
          await tester.pump();
          if (control) {
            await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
          }
          if (alt) await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
          if (shift) {
            await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
          }
          await tester.sendKeyEvent(key);
          if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
          if (alt) await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
          if (control) {
            await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
          }
          await tester.pumpAndSettle();
        }

        expect(
          (await keymap.update(
            'text.selectAll',
            const BusyMarkKeyBinding(LogicalKeyboardKey.f8),
            expected: current(),
          )).status,
          KeymapUpdateStatus.saved,
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find
              .descendant(
                of: find.byType(BusyMarkSourceEditor),
                matching: find.byTooltip(
                  l10n.collapseKind(l10n.foldKindSection),
                ),
              )
              .first,
        );
        await tester.pumpAndSettle();
        expect(source.document.hiddenRanges.ranges, isNotEmpty);
        await press(LogicalKeyboardKey.f8);
        expect(
          source.fullSelection,
          const TextSelection(baseOffset: 0, extentOffset: original.length),
        );
        expect(source.fullText, original);
        await keymap.update('text.selectAll', null, expected: current());
        await tester.pumpAndSettle();
        source.fullSelection = const TextSelection.collapsed(offset: 0);
        await press(LogicalKeyboardKey.f8);
        expect(source.fullSelection, const TextSelection.collapsed(offset: 0));
        await press(LogicalKeyboardKey.keyA, control: true);
        expect(
          source.fullSelection,
          const TextSelection.collapsed(offset: 0),
          reason: 'No hidden platform default after unassignment',
        );
        await keymap.update(
          'text.selectAll',
          null,
          reset: true,
          expected: current(),
        );
        await tester.pumpAndSettle();
        await press(LogicalKeyboardKey.keyA, control: true);
        expect(
          source.fullSelection,
          const TextSelection(baseOffset: 0, extentOffset: original.length),
        );
        await tester.tap(
          find
              .descendant(
                of: find.byType(BusyMarkSourceEditor),
                matching: find.byTooltip(l10n.expandKind(l10n.foldKindSection)),
              )
              .first,
        );
        await tester.pumpAndSettle();
        expect(
          (await keymap.update(
            'editor.bold',
            const BusyMarkKeyBinding(LogicalKeyboardKey.enter, alt: true),
            expected: current(),
          )).status,
          KeymapUpdateStatus.saved,
        );
        await tester.pumpAndSettle();
        final start = original.indexOf('target');
        source.fullSelection = TextSelection(
          baseOffset: start,
          extentOffset: start + 6,
        );
        await press(LogicalKeyboardKey.enter, alt: true);
        final modified = original.replaceFirst('target', '**target**');
        expect(source.fullText, modified);
        expect(
          container.read(workspaceControllerProvider).activeText,
          modified,
        );
        await press(LogicalKeyboardKey.keyZ, control: true);
        expect(
          source.fullText,
          original,
          reason: 'Exactly one undo restores the complete document',
        );
        await press(LogicalKeyboardKey.keyZ, control: true, shift: true);
        expect(source.fullText, modified);
        // Plain Enter retains its existing input behavior and its own undo unit.
        source.fullSelection = TextSelection.collapsed(offset: modified.length);
        await press(LogicalKeyboardKey.enter);
        expect(source.fullText, '$modified\n');
        await press(LogicalKeyboardKey.keyZ, control: true);
        expect(source.fullText, modified);
        final workspace = container.read(workspaceControllerProvider.notifier);
        bool? saved;
        unawaited(workspace.saveActive().then((value) => saved = value));
        await _waitForSearchCondition(tester, () => saved != null);
        expect(saved, isTrue);
        await tester.pumpAndSettle();
        expect(file.readAsStringSync(), modified);
        final id = container.read(workspaceControllerProvider).activeBufferId!;
        bool? closed;
        unawaited(
          workspace.closeDocumentBuffer(id).then((value) => closed = value),
        );
        await _waitForSearchCondition(tester, () => closed != null);
        expect(closed, isTrue);
        unawaited(workspace.openPath(file.path));
        await _waitForSearchCondition(
          tester,
          () =>
              container.read(workspaceControllerProvider).activeText ==
              modified,
        );
        expect(file.readAsStringSync(), modified);
        expect(
          container.read(workspaceControllerProvider).activeText,
          modified,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
      },
    );
  }

  testWidgets(
    'effective keymap changes Source execution, disables defaults and updates native metadata',
    (tester) async {
      final (:container, :events) = await _pumpSearchRegression(
        tester,
        headerBarService,
        {'a.md': 'needle other'},
      );
      final saveHandler = container
          .read(busyMarkCommandRegistryProvider)['file.save']!
          .execute;
      final keymap = container.read(keymapControllerProvider.notifier);
      Map<String, BusyMarkKeyBinding?> overrides() =>
          container.read(appSettingsControllerProvider).shortcutOverrides;
      expect(
        (await keymap.update(
          'editor.bold',
          const BusyMarkKeyBinding(
            LogicalKeyboardKey.keyB,
            control: true,
            alt: true,
          ),
          expected: overrides(),
        )).status,
        KeymapUpdateStatus.saved,
      );
      expect(
        container.read(busyMarkCommandRegistryProvider)['file.save']!.execute,
        same(saveHandler),
      );
      container.read(searchSessionProvider.notifier).close(restoreFocus: false);
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(
        find
            .descendant(
              of: find.byType(BusyMarkSourceEditor),
              matching: find.byType(TextField),
            )
            .first,
      );
      final source = _searchSourceController(tester);
      field.focusNode!.requestFocus();
      source.selection = const TextSelection(baseOffset: 0, extentOffset: 6);
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(
        container.read(workspaceControllerProvider).activeText,
        'needle other',
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(
        container.read(workspaceControllerProvider).activeText,
        '**needle** other',
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(
        container.read(workspaceControllerProvider).activeText,
        'needle other',
      );
      expect(
        (await keymap.update(
          'text.selectAll',
          null,
          expected: overrides(),
        )).status,
        KeymapUpdateStatus.saved,
      );
      await tester.pumpAndSettle();
      source.selection = const TextSelection.collapsed(offset: 2);
      field.focusNode!.requestFocus();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      expect(
        source.fullSelection,
        const TextSelection.collapsed(offset: 2),
        reason: 'No fallthrough to DefaultTextEditingShortcuts',
      );
      await keymap.update('text.paste', null, expected: overrides());
      await tester.pumpAndSettle();
      var clipboardReads = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.getData') {
            clipboardReads++;
          }
          if (call.method == 'Clipboard.getData') {
            return {'text': 'unexpected paste'};
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      field.focusNode!.requestFocus();
      final beforePaste = source.fullText;
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.insert);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(
        source.fullText,
        beforePaste,
        reason: 'Removing Paste also removes the platform Shift+Insert alias',
      );
      expect(clipboardReads, 0);
      expect(
        (await keymap.update(
          'view.source',
          null,
          expected: overrides(),
        )).status,
        KeymapUpdateStatus.saved,
      );
      expect(
        (await keymap.update(
          'search.find',
          const BusyMarkKeyBinding(LogicalKeyboardKey.f12),
          expected: overrides(),
        )).status,
        KeymapUpdateStatus.saved,
      );
      await tester.pumpAndSettle();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      expect(container.read(searchSessionProvider).active, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.f12);
      await tester.pumpAndSettle();
      expect(
        container.read(searchSessionProvider).category,
        SearchCategory.file,
      );
      expect(container.read(searchSessionProvider).active, isTrue);
      BusyMarkPopupSelectorOption<SearchCategory> documentOption() => tester
          .widget<BusyMarkPopupSelector<SearchCategory>>(
            find.byKey(const ValueKey('search-category')),
          )
          .options
          .singleWhere((o) => o.value == SearchCategory.file);
      expect(documentOption().shortcut, 'F12');
      expect(documentOption().gtkAccelerator, 'F12');
      await tester.tap(find.byKey(const ValueKey('search-category')));
      await tester.pumpAndSettle();
      expect(find.text('F12'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(container.read(searchSessionProvider).active, isTrue);
      await keymap.update('search.find', null, expected: overrides());
      await tester.pumpAndSettle();
      expect(documentOption().shortcut, isNull);
      expect(documentOption().gtkAccelerator, isNull);
      final unchangedRequest = container
          .read(searchSessionProvider)
          .focusRequest;
      await tester.sendKeyEvent(LogicalKeyboardKey.f12);
      await tester.pump();
      expect(
        container.read(searchSessionProvider).focusRequest,
        unchangedRequest,
      );
      await keymap.update(
        'search.find',
        null,
        reset: true,
        expected: overrides(),
      );
      await tester.pumpAndSettle();
      expect(documentOption().shortcut, 'Ctrl+F');
      expect(documentOption().gtkAccelerator, '<Primary>f');
      expect(
        container
            .read(busyMarkCommandRegistryProvider)['view.source']!
            .shortcut,
        isNull,
      );
      await keymap.update(
        'file.newDocument',
        const BusyMarkKeyBinding(LogicalKeyboardKey.keyA, control: true),
        expected: overrides(),
      );
      await tester.pumpAndSettle();
      final queryField = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const ValueKey('shared-search-query')),
          matching: find.byType(TextField),
        ),
      );
      queryField.controller!.text = 'local query';
      queryField.focusNode!.requestFocus();
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      expect(
        queryField.controller!.selection,
        const TextSelection(baseOffset: 0, extentOffset: 11),
      );
      expect(find.byType(Dialog), findsNothing);
      await keymap.update('file.newDocument', null, expected: overrides());
      expect(
        (await keymap.update(
          BusyMarkCommandIds.quickOpen,
          const BusyMarkKeyBinding(LogicalKeyboardKey.keyA, control: true),
          expected: overrides(),
        )).status,
        KeymapUpdateStatus.saved,
      );
      await tester.pumpAndSettle();
      queryField.controller!.selection = const TextSelection.collapsed(
        offset: 3,
      );
      final request = container.read(searchSessionProvider).focusRequest;
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      expect(
        queryField.controller!.selection,
        const TextSelection(baseOffset: 0, extentOffset: 11),
      );
      expect(container.read(searchSessionProvider).focusRequest, request);
      expect(
        container.read(searchSessionProvider).category,
        SearchCategory.file,
      );
      final replacement = tester.widget<TextField>(
        find.byKey(const ValueKey('source-search-replacement')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('source-search-replacement')),
        'replacement',
      );
      replacement.controller!.selection = const TextSelection.collapsed(
        offset: 3,
      );
      final beforeReplacementInput = container
          .read(workspaceControllerProvider)
          .activeText;
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      expect(
        replacement.controller!.selection,
        const TextSelection(baseOffset: 0, extentOffset: 11),
      );
      expect(container.read(searchSessionProvider).focusRequest, request);
      expect(
        container.read(workspaceControllerProvider).activeText,
        beforeReplacementInput,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'capture releases dispatch even when native key-up skips focus delivery',
    (tester) async {
      final harness = await _pumpSearchRegression(tester, headerBarService, {
        'a.md': 'unchanged',
      });
      final owner = Object();
      var candidates = 0;
      BusyMarkShortcutCapture.begin(
        owner,
        onCandidate: (_) {
          candidates++;
          BusyMarkShortcutCapture.end(owner);
        },
        onCancel: () {},
      );
      addTearDown(() => BusyMarkShortcutCapture.end(owner));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.f8);
      expect(candidates, 1);
      expect(BusyMarkShortcutCapture.suppressing, isTrue);
      // Reproduce the native hardware-only release, without a subsequent
      // FocusManager key message. The candidate must remain consumed while the
      // key is held, then dispatch must become available after release.
      HardwareKeyboard.instance.handleKeyEvent(
        const KeyUpEvent(
          physicalKey: PhysicalKeyboardKey.f8,
          logicalKey: LogicalKeyboardKey.f8,
          timeStamp: Duration.zero,
        ),
      );
      await tester.pump();
      expect(BusyMarkShortcutCapture.suppressing, isFalse);
      expect(
        harness.container.read(workspaceControllerProvider).activeText,
        'unchanged',
      );
    },
  );

  testWidgets(
    'capture suppresses the real workspace search route until key release',
    (tester) async {
      final harness = await _pumpSearchRegression(tester, headerBarService, {
        'a.md': 'selected text',
      });
      final container = harness.container;
      final session = container.read(searchSessionProvider.notifier);
      session.close(restoreFocus: false);
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(
        find
            .descendant(
              of: find.byType(BusyMarkSourceEditor),
              matching: find.byType(TextField),
            )
            .first,
      );
      field.focusNode!.requestFocus();
      field.controller!.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 8,
      );
      await tester.pump();
      final request = container.read(searchSessionProvider).focusRequest;
      final owner = Object();
      final candidates = <BusyMarkKeyBinding>[];
      addTearDown(() async {
        for (final key
            in HardwareKeyboard.instance.logicalKeysPressed.toList()) {
          await tester.sendKeyUpEvent(key);
        }
        BusyMarkShortcutCapture.end(owner);
      });
      BusyMarkShortcutCapture.begin(
        owner,
        onCandidate: candidates.add,
        onCancel: () => BusyMarkShortcutCapture.end(owner),
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyF);
      await tester.pump();
      expect(container.read(searchSessionProvider).active, isFalse);
      expect(candidates, [
        const BusyMarkKeyBinding(LogicalKeyboardKey.keyF, control: true),
      ]);
      BusyMarkShortcutCapture.end(owner);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      expect(container.read(searchSessionProvider).focusRequest, request);
      expect(
        container.read(workspaceControllerProvider).activeText,
        'selected text',
      );
      expect(
        field.controller!.selection,
        const TextSelection(baseOffset: 0, extentOffset: 8),
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(container.read(searchSessionProvider).active, isTrue);
      expect(
        container.read(searchSessionProvider).category,
        SearchCategory.file,
      );
      expect(container.read(searchSessionProvider).focusRequest, request + 1);
    },
  );

  testWidgets(
    'shortcut Settings respects pending property edits before leaving the workspace',
    (tester) async {
      final harness = await _pumpSearchRegression(tester, headerBarService, {
        'a.md': 'Original text',
      });
      final container = harness.container;
      container.read(searchSessionProvider.notifier).close(restoreFocus: false);
      await tester.pumpAndSettle();
      final workspace = container.read(workspaceControllerProvider.notifier);
      var attempted = 0;
      final draft = workspace.propertyEdits.bind(
        'shortcut-settings-guard',
        '',
        (_) {
          attempted++;
          return false;
        },
      );
      workspace.propertyEdits.edit(draft, 'pending');
      await container
          .read(keymapControllerProvider.notifier)
          .update(
            BusyMarkCommandIds.keyboardShortcuts,
            const BusyMarkKeyBinding(
              LogicalKeyboardKey.keyK,
              control: true,
              alt: true,
            ),
            expected: container
                .read(appSettingsControllerProvider)
                .shortcutOverrides,
          );

      await tester.pumpAndSettle();
      expect(
        container
            .read(
              busyMarkCommandRegistryProvider,
            )[BusyMarkCommandIds.keyboardShortcuts]!
            .shortcut!
            .label,
        'Ctrl+Alt+K',
      );
      Future<void> openSettings() async {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pumpAndSettle();
      }

      await openSettings();
      expect(attempted, 1);
      expect(find.byType(KeyboardShortcutsSettings), findsNothing);
      expect(workspace.propertyEdits.hasPending, isTrue);
      expect(
        container.read(workspaceControllerProvider).activeText,
        'Original text',
      );
      workspace.propertyEdits.revert(draft);
      await openSettings();
      expect(find.byType(KeyboardShortcutsSettings), findsOneWidget);
      expect(
        container
            .read(appRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .queryParameters['returnTo'],
        'workspace',
      );
    },
  );

  testWidgets(
    'Actions keeps its captured target and selected command when a binding changes',
    (tester) async {
      final harness = await _pumpSearchRegression(tester, headerBarService, {
        'a.md': 'selected text',
      });
      final container = harness.container;
      final session = container.read(searchSessionProvider.notifier);
      session.close(restoreFocus: false);
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(
        find
            .descendant(
              of: find.byType(BusyMarkSourceEditor),
              matching: find.byType(TextField),
            )
            .first,
      );
      field.focusNode!.requestFocus();
      field.controller!.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 8,
      );
      await tester.pump();
      session.open(category: SearchCategory.actions);
      session.query('Bold');
      await tester.runAsync(session.submit);
      await tester.pumpAndSettle();
      final query = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const ValueKey('shared-search-query')),
          matching: find.byType(TextField),
        ),
      );
      query.focusNode!.requestFocus();
      await tester.pump();
      final focus = FocusManager.instance.primaryFocus;
      expect(focus, same(query.focusNode));
      final target = session.commandTarget;
      await container
          .read(keymapControllerProvider.notifier)
          .update(
            'editor.bold',
            const BusyMarkKeyBinding(
              LogicalKeyboardKey.keyB,
              control: true,
              alt: true,
            ),
            expected: {},
          );
      await tester.pumpAndSettle();
      expect(session.commandTarget, same(target));
      expect(
        target!.isCurrent(container.read(workspaceControllerProvider)),
        isTrue,
      );
      expect(FocusManager.instance.primaryFocus, same(focus));
      final state = container.read(searchSessionProvider);
      expect(state.results[state.selected].identity, 'editor.bold');
      expect(
        (state.results[state.selected] as ActionSearchResult).enabled,
        isTrue,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is BusyMarkKeyboardShortcutBadge && w.label == 'Ctrl+Alt+B',
        ),
        findsOneWidget,
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await _waitForSearchCondition(
        tester,
        () =>
            container.read(workspaceControllerProvider).activeText ==
            '**selected** text',
      );
      expect(
        container.read(workspaceControllerProvider).activeText,
        '**selected** text',
      );
    },
  );

  testWidgets('application reassignment receives a retired editor combination', (
    tester,
  ) async {
    final harness = await _pumpSearchRegression(tester, headerBarService, {
      'a.md': 'Text',
    });
    final container = harness.container;
    final keymap = container.read(keymapControllerProvider.notifier);
    container.read(searchSessionProvider.notifier).close(restoreFocus: false);
    Map<String, BusyMarkKeyBinding?> current() =>
        container.read(appSettingsControllerProvider).shortcutOverrides;
    await keymap.update('text.paste', null, expected: current());
    expect(
      (await keymap.update(
        'help.keyboardShortcuts',
        const BusyMarkKeyBinding(LogicalKeyboardKey.keyV, control: true),
        expected: current(),
      )).status,
      KeymapUpdateStatus.saved,
    );
    await tester.pumpAndSettle();
    tester
        .widget<TextField>(
          find
              .descendant(
                of: find.byType(BusyMarkSourceEditor),
                matching: find.byType(TextField),
              )
              .first,
        )
        .focusNode!
        .requestFocus();
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(find.byType(KeyboardShortcutsSettings), findsOneWidget);
    expect(
      container
          .read(appRouterProvider)
          .routeInformationProvider
          .value
          .uri
          .queryParameters['returnTo'],
      'workspace',
    );
    expect(container.read(workspaceControllerProvider).activeText, 'Text');
    await keymap.update('help.keyboardShortcuts', null, expected: current());
    expect(
      (await keymap.update(
        'notes.sync',
        const BusyMarkKeyBinding(LogicalKeyboardKey.keyV, control: true),
        expected: current(),
      )).status,
      KeymapUpdateStatus.saved,
    );
    container.read(appRouterProvider).go('/workspace');
    await tester.pumpAndSettle();
    expect(
      container.read(busyMarkCommandRegistryProvider)['notes.sync']!.canExecute,
      isFalse,
    );
    var clipboardReads = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.getData') {
          clipboardReads++;
          return {'text': 'unexpected fallback'};
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final source = tester.widget<TextField>(
      find
          .descendant(
            of: find.byType(BusyMarkSourceEditor),
            matching: find.byType(TextField),
          )
          .first,
    );
    source.focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(
      clipboardReads,
      0,
      reason:
          'A disabled replacement command must not fall through to unassigned Paste.',
    );
    expect(container.read(workspaceControllerProvider).activeText, 'Text');
  });

  testWidgets(
    'effective keymap replaces sidebar keypad aliases and tree deletion keys',
    (tester) async {
      final harness = await _pumpSearchRegression(tester, headerBarService, {
        'a.md': '# Heading\nText',
        'b.md': 'Other',
      });
      final container = harness.container;
      final keymap = container.read(keymapControllerProvider.notifier);
      Map<String, BusyMarkKeyBinding?> current() =>
          container.read(appSettingsControllerProvider).shortcutOverrides;
      await keymap.update(
        'sidebar.files',
        const BusyMarkKeyBinding(LogicalKeyboardKey.f8),
        expected: current(),
      );
      await keymap.update(
        'tree.deleteSelection',
        const BusyMarkKeyBinding(
          LogicalKeyboardKey.keyD,
          control: true,
          alt: true,
        ),
        expected: current(),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(container.read(searchSessionProvider).active, isFalse);
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'Outline navigation',
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.numpad1);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'Outline navigation',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.f8);
      await tester.pumpAndSettle();
      final tree = find.byWidgetPredicate(
        (w) => w is Focus && w.focusNode?.debugLabel == 'BusyMark files tree',
      );
      expect(
        tree,
        findsOneWidget,
        reason: 'The reassigned navigation key reveals Files',
      );
      tester.widget<Focus>(tree).focusNode!.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text(l10n.confirmDeleteFileTitle), findsOneWidget);
      await tester.tap(find.text(l10n.cancel));
      await tester.pumpAndSettle();
      expect(
        container.read(workspaceControllerProvider).workspace!.files,
        hasLength(2),
      );
      expect(
        container.read(workspaceControllerProvider).activeText,
        '# Heading\nText',
      );
      expect(tester.takeException(), isNull);
    },
  );
  test('editor shortcuts use documented cross-editor defaults', () {
    expect(
      {
        for (final entry in BusyMarkEditorShortcuts.definitions.entries)
          entry.key: entry.value.label,
      },
      {
        BusyMarkEditorShortcutAction.refineWithAi: 'Ctrl+G',
        BusyMarkEditorShortcutAction.copyPlainText: 'Ctrl+Shift+C',
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
        BusyMarkEditorShortcutAction.thematicBreak: 'Ctrl+Shift+-',
        BusyMarkEditorShortcutAction.hardLineBreak: 'Shift+Enter',
      },
    );
    final pastePlainText = BusyMarkTextEditingShortcuts
        .definitions[BusyMarkTextEditingShortcutAction.pastePlainText]!;
    expect(pastePlainText.label, 'Ctrl+Shift+V');
    final activator = pastePlainText.activator as SingleActivator;
    expect(activator.trigger, LogicalKeyboardKey.keyV);
    expect(activator.control, isTrue);
    expect(activator.shift, isTrue);
    expect(
      BusyMarkTextEditingShortcuts.definitions.values.where(
        (definition) => definition.activator == activator,
      ),
      hasLength(1),
    );
  });

  testWidgets(
    'workspace resize retains the sidebar and leaves room for header controls',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 720);
      addTearDown(tester.view.reset);
      final container = ProviderContainer(
        overrides: [
          ..._smokeAccentOverrides,
          linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
          localSettingsStoreProvider.overrideWithValue(_MemorySettingsStore()),
          workspaceServiceProvider.overrideWithValue(
            _StartupWorkspaceService(),
          ),
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
      await _pumpUntilFound(
        tester,
        find.byKey(const ValueKey('workspace-page-frame')),
      );
      await tester.pumpAndSettle();
      final sidebarKey = ValueKey(
        container.read(workspaceControllerProvider).workspace!.id,
      );
      final sidebarState = tester.state(find.byKey(sidebarKey));
      final generation = container.read(sidebarTransitionGenerationProvider);
      final viewport = find.byKey(const ValueKey('linux-sidebar-viewport'));
      expect(tester.getSize(viewport).width, BusyMarkSizes.sidebarWidth);

      tester.view.physicalSize = const Size(700, 720);
      await tester.pump();
      expect(tester.getSize(viewport).width, 0);
      expect(
        tester.state(find.byKey(sidebarKey, skipOffstage: false)),
        same(sidebarState),
      );
      expect(
        container.read(appSettingsControllerProvider).sidebarVisible,
        isTrue,
      );
      expect(container.read(sidebarTransitionGenerationProvider), generation);

      tester.view.physicalSize = const Size(1280, 720);
      await tester.pump();
      expect(tester.getSize(viewport).width, BusyMarkSizes.sidebarWidth);
      expect(tester.state(find.byKey(sidebarKey)), same(sidebarState));
      expect(container.read(sidebarTransitionGenerationProvider), generation);
    },
  );

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

  testWidgets(
    'heading boundary survives workspace undo, view switching, save and reopen',
    (tester) async {
      final root = Directory.systemTemp.createTempSync(
        'busymark-heading-boundary-',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      const original = '## About the job\n';
      final file = File('${root.path}/header_test_text.md')
        ..writeAsStringSync(original);
      final container = ProviderContainer(
        overrides: [
          ..._smokeAccentOverrides,
          linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
          localSettingsStoreProvider.overrideWithValue(
            _MemorySettingsStore()
              ..value = AppSettings.defaults()
                  .copyWith(
                    autoSave: false,
                    documentViewMode: DocumentViewModePreference.editor,
                  )
                  .toJson(),
          ),
          localHistoryStoreProvider.overrideWithValue(
            MemoryLocalHistoryStore(),
          ),
          documentSessionStoreProvider.overrideWithValue(
            MemoryDocumentSessionStore(),
          ),
          documentRecoveryStoreProvider.overrideWithValue(
            MemoryDocumentRecoveryStore(),
          ),
          startupPathProvider.overrideWithValue(file.path),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BusyMarkApp(),
        ),
      );
      await _waitForSearchCondition(
        tester,
        () => find.byType(BusyMarkWysiwygEditor).evaluate().isNotEmpty,
      );
      await tester.pumpAndSettle();
      final workspace = container.read(workspaceControllerProvider.notifier);
      final field = tester.widget<TextField>(
        find.widgetWithText(TextField, 'About the job'),
      );
      field.focusNode!.requestFocus();
      field.controller!.selection = const TextSelection.collapsed(offset: 0);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      final edited = container.read(workspaceControllerProvider).activeBuffer!;
      final savedSource = edited.text;
      expect(edited.editorState.undoState.undo, hasLength(1));
      expect(edited.isDirty, isTrue);
      expect(savedSource, contains('## About the job'));
      expect(savedSource, isNot(contains('## \n')));
      final kept = tester.widget<TextField>(
        find.widgetWithText(TextField, 'About the job'),
      );
      expect(kept.focusNode!.hasFocus, isTrue);
      expect(
        kept.controller!.selection,
        const TextSelection.collapsed(offset: 0),
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(container.read(workspaceControllerProvider).activeText, original);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(
        container.read(workspaceControllerProvider).activeText,
        savedSource,
      );
      // External history restores source through the production parser. Blank
      // paragraphs remain transient; redo must preserve the heading, not invent
      // a semantic paragraph that save/reopen intentionally does not retain.
      expect(
        find.descendant(
          of: find.byType(BusyMarkWysiwygEditor),
          matching: find.byWidgetPredicate(
            (w) => w is TextField && w.controller?.text.isEmpty == true,
          ),
        ),
        findsNothing,
      );
      for (final mode in [
        DocumentViewModePreference.source,
        DocumentViewModePreference.preview,
        DocumentViewModePreference.split,
        DocumentViewModePreference.editor,
      ]) {
        workspace.updateActiveEditorMode(mode);
        await container
            .read(appSettingsControllerProvider.notifier)
            .setDocumentViewMode(mode);
        await tester.pumpAndSettle();
        expect(
          container.read(workspaceControllerProvider).activeText,
          savedSource,
        );
        final parsed = const MarkdownParser()
            .parse(filePath: file.path, source: savedSource)
            .busyDocument;
        expect(parsed.blocks.single.kind, BusyBlockKind.heading);
        expect(parsed.blocks.single.attributes['level'], '2');
        expect(parsed.blocks.single.plainText, 'About the job');
      }
      bool? saved;
      unawaited(workspace.saveActive().then((value) => saved = value));
      await _waitForSearchCondition(tester, () => saved != null);
      expect(saved, isTrue);
      await tester.pumpAndSettle();
      expect(file.readAsStringSync(), savedSource);
      bool? closed;
      unawaited(
        workspace.closeActiveOpenFileTab().then((value) => closed = value),
      );
      await _waitForSearchCondition(tester, () => closed != null);
      expect(closed, isTrue);
      unawaited(workspace.openPath(file.path));
      await _waitForSearchCondition(
        tester,
        () => find
            .widgetWithText(TextField, 'About the job')
            .evaluate()
            .isNotEmpty,
      );
      await tester.pumpAndSettle();
      final reopened = container
          .read(workspaceControllerProvider)
          .activeBuffer!;
      expect(reopened.text, savedSource);
      expect(reopened.isDirty, isFalse);
      expect(
        tester
            .widget<BusyMarkWysiwygEditor>(find.byType(BusyMarkWysiwygEditor))
            .document
            .blocks
            .single
            .kind,
        BusyBlockKind.heading,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final count in [1, 2]) {
    testWidgets(
      'inline break anchors survive workspace history, save and reopen count=$count',
      (tester) async {
        final root = Directory.systemTemp.createTempSync(
          'busymark-inline-break-anchors-',
        );
        addTearDown(() => root.deleteSync(recursive: true));
        const original =
            '**a![](first.png)![](second.png)  \n![](third.png)![](fourth.png)b**\n';
        final file = File('${root.path}/breaks.md')
          ..writeAsStringSync(original);
        const parser = MarkdownParser();
        BusyBlock parsed(String source) => parser
            .parse(filePath: file.path, source: source)
            .busyDocument
            .blocks
            .single;
        final before = parsed(original);
        expect(before.plainText, 'a\nb');
        final expected = [
          for (final anchor in busyInlineSemanticAnchors(before.inlines))
            [
              anchor.offset <= 1 ? anchor.offset : anchor.offset + count,
              _inlineAnchorTree(anchor.inline),
            ],
        ];
        final container = ProviderContainer(
          overrides: [
            ..._smokeAccentOverrides,
            linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
            localSettingsStoreProvider.overrideWithValue(
              _MemorySettingsStore()
                ..value = AppSettings.defaults()
                    .copyWith(
                      autoSave: false,
                      automaticSpelling: false,
                      documentViewMode: DocumentViewModePreference.editor,
                    )
                    .toJson(),
            ),
            localHistoryStoreProvider.overrideWithValue(
              MemoryLocalHistoryStore(),
            ),
            documentSessionStoreProvider.overrideWithValue(
              MemoryDocumentSessionStore(),
            ),
            documentRecoveryStoreProvider.overrideWithValue(
              MemoryDocumentRecoveryStore(),
            ),
            startupPathProvider.overrideWithValue(file.path),
          ],
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const BusyMarkApp(),
          ),
        );
        await _waitForSearchCondition(
          tester,
          () => find.byType(BusyMarkWysiwygEditor).evaluate().isNotEmpty,
        );
        await tester.pumpAndSettle();
        final workspace = container.read(workspaceControllerProvider.notifier);
        final field = tester.widget<TextField>(
          find.widgetWithText(TextField, 'a\nb'),
        );
        field.focusNode!.requestFocus();
        field.controller!.selection = const TextSelection.collapsed(offset: 1);
        await tester.pump();
        if (count == 1) {
          await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        } else {
          final button = find.byWidgetPredicate(
            (w) =>
                w is BusyMarkHeaderIconButton &&
                w.icon == BusyMarkGlyphs.blankLine,
          );
          await tester.ensureVisible(button);
          await tester.tap(button);
        }
        await tester.pumpAndSettle();
        final edited = container
            .read(workspaceControllerProvider)
            .activeBuffer!;
        final savedSource = edited.text;
        expect(edited.editorState.undoState.undo, hasLength(1));
        expect(_inlineAnchorPositions(parsed(savedSource)), expected);
        expect(field.controller!.text, 'a${'\n' * (count + 1)}b');
        expect(field.focusNode!.hasFocus, isTrue);
        expect(
          field.controller!.selection,
          TextSelection.collapsed(offset: 1 + count),
        );
        final dynamic editorState = tester.state(
          find.byType(BusyMarkWysiwygEditor),
        );
        expect(editorState.debugUndoSnapshotCount, 0);
        expect(workspace.undoActiveBuffer(), isTrue);
        await tester.pumpAndSettle();
        expect(
          container.read(workspaceControllerProvider).activeText,
          original,
        );
        expect(
          _inlineAnchorPositions(
            tester
                .widget<BusyMarkWysiwygEditor>(
                  find.byType(BusyMarkWysiwygEditor),
                )
                .document
                .blocks
                .single,
          ),
          _inlineAnchorPositions(before),
        );
        expect(workspace.redoActiveBuffer(), isTrue);
        await tester.pumpAndSettle();
        expect(
          container.read(workspaceControllerProvider).activeText,
          savedSource,
        );
        expect(
          _inlineAnchorPositions(
            tester
                .widget<BusyMarkWysiwygEditor>(
                  find.byType(BusyMarkWysiwygEditor),
                )
                .document
                .blocks
                .single,
          ),
          expected,
        );
        for (final mode in [
          DocumentViewModePreference.source,
          DocumentViewModePreference.preview,
          DocumentViewModePreference.split,
          DocumentViewModePreference.editor,
        ]) {
          workspace.updateActiveEditorMode(mode);
          await container
              .read(appSettingsControllerProvider.notifier)
              .setDocumentViewMode(mode);
          await tester.pumpAndSettle();
          expect(
            container.read(workspaceControllerProvider).activeText,
            savedSource,
          );
          expect(_inlineAnchorPositions(parsed(savedSource)), expected);
        }
        bool? saved;
        unawaited(workspace.saveActive().then((value) => saved = value));
        await _waitForSearchCondition(tester, () => saved != null);
        expect(saved, isTrue);
        expect(file.readAsStringSync(), savedSource);
        bool? closed;
        unawaited(
          workspace.closeActiveOpenFileTab().then((value) => closed = value),
        );
        await _waitForSearchCondition(tester, () => closed != null);
        expect(closed, isTrue);
        unawaited(workspace.openPath(file.path));
        await _waitForSearchCondition(
          tester,
          () => find
              .widgetWithText(TextField, 'a${'\n' * (count + 1)}b')
              .evaluate()
              .isNotEmpty,
        );
        await tester.pumpAndSettle();
        final reopened = container
            .read(workspaceControllerProvider)
            .activeBuffer!;
        expect(reopened.text, savedSource);
        expect(reopened.isDirty, isFalse);
        expect(_inlineAnchorPositions(parsed(reopened.text)), expected);
        expect(
          _inlineAnchorPositions(
            tester
                .widget<BusyMarkWysiwygEditor>(
                  find.byType(BusyMarkWysiwygEditor),
                )
                .document
                .blocks
                .single,
          ),
          expected,
        );
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets('workspace coalesces pixel viewport sessions without edits', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        ..._smokeAccentOverrides,
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(
          _MemorySettingsStore()
            ..value = AppSettings.defaults()
                .copyWith(
                  autoSave: false,
                  documentViewMode: DocumentViewModePreference.editor,
                )
                .toJson(),
        ),
        workspaceServiceProvider.overrideWithValue(
          const _SearchWorkspaceService('Reading target.'),
        ),
        startupPathProvider.overrideWithValue('/tmp/viewport-session.md'),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BusyMarkApp(),
      ),
    );
    await _pumpUntilFound(tester, find.byType(BusyMarkWysiwygEditor));
    await tester.pumpAndSettle();
    final editor = tester.widget<BusyMarkWysiwygEditor>(
      find.byType(BusyMarkWysiwygEditor),
    );
    final before = container.read(workspaceControllerProvider).activeBuffer!;
    final saved = before.editorState.wysiwygState;
    WysiwygEditorSessionState pixels(double offset) =>
        WysiwygEditorSessionState(
          activeBlockId: saved.activeBlockId,
          activeCellId: saved.activeCellId,
          anchorBlockId: saved.anchorBlockId,
          anchorOffset: saved.anchorOffset,
          extentBlockId: saved.extentBlockId,
          extentOffset: saved.extentOffset,
          viewportBlockId: saved.viewportBlockId,
          viewportAlignment: saved.viewportAlignment,
          viewportOffset: offset,
          viewportEditingOffset: -offset,
          viewportLayoutSignature: saved.viewportLayoutSignature,
          sourceSignature: saved.sourceSignature,
          sourceBindings: saved.sourceBindings,
        );
    final first = pixels(2300.25);
    editor.onSessionChanged!(editor.documentId!, first);
    expect(
      container
          .read(workspaceControllerProvider)
          .activeBuffer!
          .editorState
          .wysiwygState,
      same(first),
    );
    editor.onSessionChanged!(editor.documentId!, pixels(2300.26));
    expect(
      container
          .read(workspaceControllerProvider)
          .activeBuffer!
          .editorState
          .wysiwygState,
      same(first),
    );
    final second = pixels(2300.5);
    editor.onSessionChanged!(editor.documentId!, second);
    final after = container.read(workspaceControllerProvider).activeBuffer!;
    expect(after.editorState.wysiwygState, same(second));
    expect(after.text, before.text);
    expect(after.dirty, before.dirty);
    expect(after.editorState.undoState, same(before.editorState.undoState));
  });

  testWidgets(
    'workspace routes paste shortcuts only to editable document views',
    (tester) async {
      var generation = 0;
      var clipboardText = '';
      var readCount = 0;
      const clipboardChannel = MethodChannel(richClipboardChannelName);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        clipboardChannel,
        (call) async {
          if (call.method != 'read') return null;
          readCount += 1;
          return <String, Object?>{
            'text': clipboardText,
            'generation': generation,
          };
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          clipboardChannel,
          null,
        ),
      );

      final settingsStore = _MemorySettingsStore()
        ..value = AppSettings.defaults()
            .copyWith(
              autoSave: false,
              documentViewMode: DocumentViewModePreference.editor,
            )
            .toJson();
      const service = _SearchWorkspaceService('start');
      final container = ProviderContainer(
        overrides: [
          ..._smokeAccentOverrides,
          linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
          localSettingsStoreProvider.overrideWithValue(settingsStore),
          workspaceServiceProvider.overrideWithValue(service),
          startupPathProvider.overrideWithValue('/tmp/workspace-paste.md'),
        ],
      );
      addTearDown(container.dispose);

      Future<void> pressPaste(BusyMarkPasteMode mode) async {
        final useShift = mode == BusyMarkPasteMode.plainText;
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        if (useShift) {
          await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        }
        await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
        if (useShift) {
          await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        }
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pump(const Duration(milliseconds: 100));
      }

      Future<void> selectView(DocumentViewModePreference mode) async {
        container
            .read(workspaceControllerProvider.notifier)
            .updateActiveEditorMode(mode);
        await container
            .read(appSettingsControllerProvider.notifier)
            .setDocumentViewMode(mode);
        for (var index = 0; index < 10; index += 1) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      Future<void> focusLastEditableTextField() async {
        final field = find.byType(TextField).last;
        await tester.tap(field);
        await tester.showKeyboard(field);
        final controller = tester.widget<TextField>(field).controller!;
        controller.selection = TextSelection.collapsed(
          offset: controller.text.length,
        );
        await tester.pump();
      }

      Future<void> typeSuffix(String suffix) async {
        final field = find.byType(TextField).last;
        final controller = tester.widget<TextField>(field).controller!;
        await tester.enterText(field, '${controller.text}$suffix');
        await tester.pump(const Duration(milliseconds: 100));
      }

      Future<void> expectUndoRedoSequence({
        required BusyMarkPasteMode mode,
        BusyMarkClipboardPayload? historyPayload,
        String pasteText = 'b',
        bool replaceTypedCharacter = false,
      }) async {
        final workspace = container.read(workspaceControllerProvider.notifier);
        final original = container.read(workspaceControllerProvider).activeText;
        await typeSuffix('a');
        final afterTyping = container
            .read(workspaceControllerProvider)
            .activeText;
        if (replaceTypedCharacter) {
          final field = find.byType(TextField).last;
          final controller = tester.widget<TextField>(field).controller!;
          controller.selection = TextSelection(
            baseOffset: controller.text.length - 1,
            extentOffset: controller.text.length,
          );
          await tester.pump();
        }
        if (historyPayload == null) {
          clipboardText = pasteText;
          generation += 1;
          await pressPaste(mode);
        } else {
          expect(
            await container
                .read(clipboardInsertionRegistryProvider)
                .paste(historyPayload, mode: mode),
            ClipboardPasteResult.inserted,
          );
          await tester.pump(const Duration(milliseconds: 100));
        }
        final afterPaste = container
            .read(workspaceControllerProvider)
            .activeText;
        await typeSuffix('c');
        final afterFollowingTyping = container
            .read(workspaceControllerProvider)
            .activeText;

        workspace.undoActiveBuffer();
        await tester.pump(const Duration(milliseconds: 100));
        expect(
          container.read(workspaceControllerProvider).activeText,
          afterPaste,
        );
        workspace.undoActiveBuffer();
        await tester.pump(const Duration(milliseconds: 100));
        expect(
          container.read(workspaceControllerProvider).activeText,
          afterTyping,
        );
        workspace.undoActiveBuffer();
        await tester.pump(const Duration(milliseconds: 100));
        expect(
          container.read(workspaceControllerProvider).activeText,
          original,
        );

        workspace.redoActiveBuffer();
        await tester.pump(const Duration(milliseconds: 100));
        expect(
          container.read(workspaceControllerProvider).activeText,
          afterTyping,
        );
        workspace.redoActiveBuffer();
        await tester.pump(const Duration(milliseconds: 100));
        expect(
          container.read(workspaceControllerProvider).activeText,
          afterPaste,
        );
        workspace.redoActiveBuffer();
        await tester.pump(const Duration(milliseconds: 100));
        expect(
          container.read(workspaceControllerProvider).activeText,
          afterFollowingTyping,
        );
      }

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BusyMarkApp(),
        ),
      );
      for (var index = 0; index < 30; index += 1) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find
            .byKey(const ValueKey('document-wysiwyg-pane'))
            .evaluate()
            .isNotEmpty) {
          break;
        }
      }

      await focusLastEditableTextField();
      await expectUndoRedoSequence(mode: BusyMarkPasteMode.normal);
      await focusLastEditableTextField();
      await expectUndoRedoSequence(mode: BusyMarkPasteMode.plainText);
      await focusLastEditableTextField();
      await expectUndoRedoSequence(
        mode: BusyMarkPasteMode.normal,
        historyPayload: BusyMarkClipboardPayload(
          id: 'workspace-history-paste',
          acquiredAt: DateTime.utc(2026),
          kind: BusyMarkClipboardContentKind.text,
          text: 'b',
          external: true,
        ),
      );
      await focusLastEditableTextField();
      await expectUndoRedoSequence(
        mode: BusyMarkPasteMode.normal,
        replaceTypedCharacter: true,
      );
      await focusLastEditableTextField();
      await expectUndoRedoSequence(
        mode: BusyMarkPasteMode.normal,
        pasteText: 'b\nline',
      );
      await focusLastEditableTextField();
      clipboardText = ' editor-normal';
      generation += 1;
      await pressPaste(BusyMarkPasteMode.normal);
      clipboardText = ' editor-plain';
      generation += 1;
      await pressPaste(BusyMarkPasteMode.plainText);
      expect(
        container.read(workspaceControllerProvider).activeText,
        contains('editor-normal editor-plain'),
      );

      await selectView(DocumentViewModePreference.source);
      expect(find.byType(BusyMarkSourceEditor), findsOneWidget);
      await focusLastEditableTextField();
      await expectUndoRedoSequence(mode: BusyMarkPasteMode.normal);
      await focusLastEditableTextField();
      await expectUndoRedoSequence(mode: BusyMarkPasteMode.plainText);
      await focusLastEditableTextField();
      clipboardText = ' source-normal';
      generation += 1;
      await pressPaste(BusyMarkPasteMode.normal);
      clipboardText = ' source-plain';
      generation += 1;
      await pressPaste(BusyMarkPasteMode.plainText);
      expect(
        container.read(workspaceControllerProvider).activeText,
        contains('source-normal source-plain'),
      );

      await selectView(DocumentViewModePreference.split);
      expect(find.byType(BusyMarkSourceEditor), findsOneWidget);
      await focusLastEditableTextField();
      clipboardText = ' split-source';
      generation += 1;
      await pressPaste(BusyMarkPasteMode.plainText);
      expect(
        container.read(workspaceControllerProvider).activeText,
        endsWith(' split-source'),
      );

      await selectView(DocumentViewModePreference.preview);
      expect(find.byType(BusyMarkSourceEditor), findsNothing);
      expect(container.read(clipboardInsertionRegistryProvider).target, isNull);
      final readingText = container
          .read(workspaceControllerProvider)
          .activeText;
      final readingReadCount = readCount;
      clipboardText = ' must-not-insert';
      generation += 1;
      await pressPaste(BusyMarkPasteMode.normal);
      await pressPaste(BusyMarkPasteMode.plainText);
      expect(
        container.read(workspaceControllerProvider).activeText,
        readingText,
      );
      expect(readCount, readingReadCount);
    },
  );

  testWidgets(
    'workspace source history restores a pasted URL suffix through undo and redo',
    (tester) async {
      const url = 'https://example.com';
      const text = '$url*';
      const clipboardChannel = MethodChannel(richClipboardChannelName);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        clipboardChannel,
        (call) async => call.method == 'read'
            ? <String, Object?>{'text': text, 'generation': 1}
            : null,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          clipboardChannel,
          null,
        ),
      );
      final settings = _MemorySettingsStore()
        ..value = AppSettings.defaults()
            .copyWith(
              autoSave: false,
              documentViewMode: DocumentViewModePreference.editor,
            )
            .toJson();
      final container = ProviderContainer(
        overrides: [
          ..._smokeAccentOverrides,
          linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
          localSettingsStoreProvider.overrideWithValue(settings),
          workspaceServiceProvider.overrideWithValue(
            const _SearchWorkspaceService(''),
          ),
          startupPathProvider.overrideWithValue('/tmp/workspace-url-undo.md'),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BusyMarkApp(),
        ),
      );
      for (var index = 0; index < 30; index++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.byType(BusyMarkWysiwygEditor).evaluate().isNotEmpty) break;
      }
      Future<void> shortcut(
        LogicalKeyboardKey key, {
        bool shift = false,
      }) async {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(key);
        if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pump(const Duration(milliseconds: 100));
      }

      BusyDocument live() => tester
          .widget<BusyMarkWysiwygEditor>(find.byType(BusyMarkWysiwygEditor))
          .document;
      TextField first() => tester.widget<TextField>(
        find
            .descendant(
              of: find.byType(BusyMarkWysiwygEditor),
              matching: find.byType(TextField),
            )
            .first,
      );
      String source() => container.read(workspaceControllerProvider).activeText;
      void check({required bool recognized}) {
        expect(first().controller!.text, text);
        expect(first().controller!.text, isNot(contains(r'\')));
        expect(live().blocks.first.plainText, text);
        final ranges = busyInlineStyleRanges(live().blocks.first.inlines);
        if (recognized) {
          final link = ranges.single;
          expect(
            (link.kind, link.start, link.end, link.destination),
            (BusyInlineKind.link, 0, url.length, url),
          );
          expect(link.attributes[busyMarkBareUrlAttribute], 'true');
        } else {
          expect(ranges, isEmpty);
        }
      }

      first().focusNode!.requestFocus();
      first().controller!.selection = const TextSelection.collapsed(offset: 0);
      await tester.pump();
      await shortcut(LogicalKeyboardKey.keyV);
      check(recognized: false);
      final beforeEnter = source();
      expect(beforeEnter, r'&#104;ttps://example.com\*');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump(const Duration(milliseconds: 100));
      check(recognized: true);
      final afterEnter = source();
      // This workspace fixture has no final newline, so the buffer strips
      // trailing document separators while retaining the live new paragraph.
      expect(afterEnter, text);
      final fields = tester
          .widgetList<TextField>(
            find.descendant(
              of: find.byType(BusyMarkWysiwygEditor),
              matching: find.byType(TextField),
            ),
          )
          .toList();
      expect(fields.last.focusNode!.hasFocus, isTrue);
      expect(
        fields.last.controller!.selection,
        const TextSelection.collapsed(offset: 0),
      );
      expect(
        tester
            .state<BusyMarkWysiwygEditorState>(
              find.byType(BusyMarkWysiwygEditor),
            )
            .debugUndoSnapshotCount,
        0,
      );
      await shortcut(LogicalKeyboardKey.keyZ);
      expect(source(), beforeEnter);
      check(recognized: false);
      await shortcut(LogicalKeyboardKey.keyZ, shift: true);
      expect(source(), afterEnter);
      check(recognized: true);
      await shortcut(LogicalKeyboardKey.keyZ);
      check(recognized: false);
      await shortcut(LogicalKeyboardKey.keyZ);
      expect(first().controller!.text, '');
      await shortcut(LogicalKeyboardKey.keyZ, shift: true);
      expect(source(), beforeEnter);
      check(recognized: false);
      await shortcut(LogicalKeyboardKey.keyZ, shift: true);
      expect(source(), afterEnter);
      check(recognized: true);
    },
  );

  testWidgets('app wires generated localization delegates and locales', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._smokeAccentOverrides,
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
          ..._smokeAccentOverrides,
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
    expect(find.text(l10n.browseNotes), findsOneWidget);
    expect(find.text(l10n.nextcloudNewNote), findsOneWidget);
    expect(
      tester.getTopLeft(find.text(l10n.markdownFolderOrWritersideProject)).dy,
      lessThan(tester.getTopLeft(find.text(l10n.browseNotes)).dy),
    );
    expect(find.text('File or folder path'), findsNothing);
    expect(find.textContaining('sign in'), findsNothing);
    expect(
      find.byTooltip(
        '${l10n.hideSidebar} (${BusyMarkSidebarShortcuts.toggleSidebar.label})',
      ),
      findsOneWidget,
    );
    _expectNeutralSidebarToggle(
      tester,
      '${l10n.hideSidebar} (${BusyMarkSidebarShortcuts.toggleSidebar.label})',
      selected: true,
    );
    _expectHeaderGeometry(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.f9);
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.byTooltip(
        '${l10n.showSidebar} (${BusyMarkSidebarShortcuts.toggleSidebar.label})',
      ),
      findsOneWidget,
    );
    _expectNeutralSidebarToggle(
      tester,
      '${l10n.showSidebar} (${BusyMarkSidebarShortcuts.toggleSidebar.label})',
      selected: false,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.f9);
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.byTooltip(
        '${l10n.hideSidebar} (${BusyMarkSidebarShortcuts.toggleSidebar.label})',
      ),
      findsOneWidget,
    );
    _expectNeutralSidebarToggle(
      tester,
      '${l10n.hideSidebar} (${BusyMarkSidebarShortcuts.toggleSidebar.label})',
      selected: true,
    );
  });

  for (final readErrors in [0, 1]) {
    testWidgets(
      'recovery shows one actionable notice and preserves damage warnings ($readErrors)',
      (tester) async {
        final recoveryStore = MemoryDocumentRecoveryStore()
          ..value = RecoverySnapshot(
            cleanShutdown: false,
            readErrors: readErrors,
            entries: [
              DocumentRecoveryEntry.fromBuffer(
                DocumentBuffer.untitled(
                  id: 'recovered-draft',
                  name: 'Recovered draft',
                  text: '# Recovered draft\n',
                ),
                workspacePath: null,
              ),
            ],
          );
        final container = ProviderContainer(
          overrides: [
            ..._smokeAccentOverrides,
            linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
            localSettingsStoreProvider.overrideWithValue(
              _MemorySettingsStore(),
            ),
            localHistoryStoreProvider.overrideWithValue(
              MemoryLocalHistoryStore(),
            ),
            documentSessionStoreProvider.overrideWithValue(
              MemoryDocumentSessionStore(),
            ),
            documentRecoveryStoreProvider.overrideWithValue(recoveryStore),
            startupPathProvider.overrideWithValue(null),
          ],
        );
        addTearDown(container.dispose);
        await tester.runAsync(() async {
          await container
              .read(appSettingsControllerProvider.notifier)
              .waitUntilLoaded();
          expect(
            await container
                .read(workspaceControllerProvider.notifier)
                .restorePreviousSession(),
            isTrue,
          );
        });
        container.read(appRouterProvider).go('/workspace');
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const BusyMarkApp(),
          ),
        );
        await tester.pumpAndSettle();

        final buffer = container
            .read(workspaceControllerProvider)
            .activeBuffer!;
        expect(buffer.recovered, isTrue);
        expect(buffer.text, '# Recovered draft\n');
        expect(find.text(l10n.workspaceRecoveryRestored(1)), findsNothing);
        final review = find.text(
          l10n.recoveredDocumentReview(buffer.displayName),
        );
        expect(review, findsOneWidget);
        final actions = find
            .ancestor(of: review, matching: find.byType(Row))
            .first;
        for (final label in [l10n.save, l10n.saveAs, l10n.discard]) {
          final button = find.ancestor(
            of: find.descendant(of: actions, matching: find.text(label)),
            matching: find.byWidgetPredicate(
              (widget) => widget is ButtonStyleButton,
            ),
          );
          expect(button, findsOneWidget);
          expect(tester.widget<ButtonStyleButton>(button).onPressed, isNotNull);
        }
        expect(
          find.text(l10n.workspaceRecoveryDamaged(1)),
          readErrors > 0 ? findsOneWidget : findsNothing,
        );
      },
    );
  }

  for (final closeTabFirst in [false, true]) {
    testWidgets(
      'Welcome creates a fresh Markdown workspace after leaving basic.md (close tab: $closeTabFirst)',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            ..._smokeAccentOverrides,
            linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
            localSettingsStoreProvider.overrideWithValue(
              _MemorySettingsStore(),
            ),
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
        await tester.pumpAndSettle();
        final controller = container.read(workspaceControllerProvider.notifier);
        await tester.pump();
        await tester.runAsync(
          () => controller.openPath('test/fixtures/markdown/basic.md'),
        );
        container.read(appRouterProvider).go('/workspace');
        await tester.pumpAndSettle();
        final oldId = container
            .read(workspaceControllerProvider)
            .activeBufferId!;
        if (closeTabFirst) {
          await tester.runAsync(() => controller.closeDocumentBuffer(oldId));
          await tester.pumpAndSettle();
        }
        await tester.tap(
          find.byTooltip('${l10n.back} (${BusyMarkAppShortcuts.back.label})'),
        );
        await tester.pumpAndSettle();
        expect(find.text(l10n.createMarkdownFile), findsOneWidget);
        await tester.tap(find.text(l10n.createMarkdownFile));
        await pumpUntil(tester, () {
          final state = container.read(workspaceControllerProvider);
          return state.documentBuffers.length == 1 &&
              state.activeBuffer?.filePath == null &&
              state.activeBufferId != oldId &&
              !state.isLoading;
        }, operation: 'Fresh Markdown workspace from Welcome');
        await tester.pumpAndSettle();
        final state = container.read(workspaceControllerProvider);
        expect(state.documentBuffers, hasLength(1));
        expect(state.activeBuffer!.filePath, isNull);
        expect(state.activeBufferId, isNot(oldId));
        expect(state.workspace!.kind, WorkspaceKind.untitledMarkdown);
        expect(state.workspace!.openFilePaths, isEmpty);
      },
    );
  }

  testWidgets('main menu and F11 toggle full-screen mode', (tester) async {
    final nativeWindow = _FakeNativeWindowController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._smokeAccentOverrides,
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
    expect(find.text(BusyMarkAppShortcuts.fullScreen.label), findsOneWidget);
    final exportMenuItem = find.byWidgetPredicate(
      (widget) =>
          widget is BusyMarkPopupMenuItem<Object?> &&
          widget.label == l10n.export,
    );
    expect(exportMenuItem, findsOneWidget);
    expect(
      tester.widget<BusyMarkPopupMenuItem<Object?>>(exportMenuItem).enabled,
      isFalse,
    );
    expect(find.text(BusyMarkAppShortcuts.export.label), findsOneWidget);
    for (final documentCommand in <String>{
      l10n.clipboardHistory,
      l10n.localHistory,
      l10n.findLocalHistoryEllipsis,
    }) {
      expect(find.text(documentCommand), findsNothing);
    }
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
          ..._smokeAccentOverrides,
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
      find.byTooltip('${l10n.back} (${BusyMarkAppShortcuts.back.label})'),
      findsOneWidget,
    );
    final backButton = tester.widget<BusyMarkLinuxHeaderIconButton>(
      find.byWidgetPredicate(
        (widget) =>
            widget is BusyMarkLinuxHeaderIconButton &&
            widget.tooltip == l10n.back,
      ),
    );
    expect(backButton.nativeIcon, BusyMarkLinuxHeaderIcon.back);
    expect(backButton.icon, BusyMarkGlyphs.headerBackFor(TextDirection.ltr));
    _expectHeaderGeometry(tester);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pumpAndSettle();

    expect(find.text(l10n.createMarkdownFile), findsOneWidget);
    expect(find.byKey(const ValueKey('settings-page-selector')), findsNothing);
  });

  testWidgets(
    'restored capture failure stays owned across Back create discard create',
    (tester) async {
      final root = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('busymark-history-navigation-'),
      ))!;
      addTearDown(() => root.delete(recursive: true));
      final path = p.join(root.path, 'Restored.md');
      await tester.runAsync(
        () => File(path).writeAsString('original restored source'),
      );
      final store = _NavigationHistoryStore();
      final sessions = MemoryDocumentSessionStore()
        ..value = WorkspaceSessionSnapshot(
          workspacePath: root.path,
          tabs: [
            DocumentSessionEntry(
              id: 'restored',
              filePath: path,
              untitledName: null,
              editorState: const DocumentEditorState(),
            ),
          ],
          activeBufferId: 'restored',
        );
      final settings = _MemorySettingsStore()
        ..value = AppSettings.defaults().copyWith(autoSave: false).toJson();
      final container = ProviderContainer(
        overrides: [
          ..._smokeAccentOverrides,
          linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
          localSettingsStoreProvider.overrideWithValue(settings),
          localHistoryStoreProvider.overrideWithValue(store),
          localHistoryTimerFactoryProvider.overrideWithValue(
            (delay, callback) => _HistoryTestTimer(delay, callback),
          ),
          documentSessionStoreProvider.overrideWithValue(sessions),
          documentRecoveryStoreProvider.overrideWithValue(
            MemoryDocumentRecoveryStore(),
          ),
          startupPathProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);
      await tester.runAsync(() async {
        await container
            .read(appSettingsControllerProvider.notifier)
            .waitUntilLoaded();
        expect(
          await container
              .read(workspaceControllerProvider.notifier)
              .restorePreviousSession(),
          isTrue,
        );
        await container
            .read(localHistoryControllerProvider.notifier)
            .flushAll(
              container.read(workspaceControllerProvider).documentBuffers,
            );
      });
      final history = container.read(localHistoryControllerProvider.notifier);
      final originalId = container
          .read(workspaceControllerProvider)
          .activeBuffer!
          .id;
      expect(
        history.warningForBuffer(originalId)?.kind,
        LocalHistoryWarningKind.capture,
      );
      container.read(appRouterProvider).go('/workspace');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BusyMarkApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('could not capture'), findsOneWidget);
      Future<void> back() async {
        await container
            .read(busyMarkCommandRegistryProvider)
            .execute(BusyMarkCommandIds.back);
        await tester.pumpAndSettle();
      }

      await back();
      expect(find.text(l10n.createMarkdownFile), findsOneWidget);
      await tester.tap(find.text(l10n.createMarkdownFile));
      await _pumpUntilCondition(
        tester,
        () =>
            container
                .read(appRouterProvider)
                .routeInformationProvider
                .value
                .uri
                .path ==
            '/workspace',
      );
      await tester.pumpAndSettle();
      final firstDraft = container
          .read(workspaceControllerProvider)
          .activeBuffer!;
      expect(firstDraft.id, isNot(originalId));
      expect(history.warningForBuffer(firstDraft.id), isNull);
      expect(find.textContaining('could not capture'), findsNothing);
      await back();
      expect(find.text(l10n.discard), findsOneWidget);
      await tester.tap(find.text(l10n.discard));
      await tester.pumpAndSettle();
      expect(find.text(l10n.createMarkdownFile), findsOneWidget);
      await tester.tap(find.text(l10n.createMarkdownFile));
      await tester.pumpAndSettle();
      await _pumpUntilCondition(
        tester,
        () =>
            container
                .read(appRouterProvider)
                .routeInformationProvider
                .value
                .uri
                .path ==
            '/workspace',
      );
      expect(
        history.warningForBuffer(
          container.read(workspaceControllerProvider).activeBuffer!.id,
        ),
        isNull,
      );
      expect(find.textContaining('could not capture'), findsNothing);
      expect(store.protectiveAttempts, 0);
      expect(
        container.read(localHistoryControllerProvider).warning?.ownerBufferId,
        originalId,
      );
      store.available = true;
      // Drain UI-zone persistence before runAsync waits on a Local History
      // retry that durably chains another session write behind it.
      var persistenceDrained = false;
      final persistence = container
          .read(workspaceControllerProvider.notifier)
          .flushPersistence()
          .whenComplete(() => persistenceDrained = true);
      await _pumpUntilCondition(tester, () => persistenceDrained);
      await persistence;
      var historyFlushed = false;
      var historySettled = false;
      final flush = history
          .flushAll(container.read(workspaceControllerProvider).documentBuffers)
          .then((settled) {
            historySettled = settled;
            historyFlushed = true;
          });
      await _pumpUntilCondition(tester, () => historyFlushed);
      await flush;
      expect(historySettled, isTrue);
      final snapshot = await store.load();
      expect(snapshot.revisions, hasLength(1));
      expect(
        (await store.readRevision(snapshot.revisions.single.id))!.source,
        'original restored source',
      );
      expect(container.read(localHistoryControllerProvider).warning, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Escape closes header popup menus', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._smokeAccentOverrides,
          linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        ],
        child: const BusyMarkApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(l10n.mainMenu));
    await tester.pumpAndSettle();

    expect(find.text(l10n.settings), findsOneWidget);
    expect(find.text(BusyMarkAppShortcuts.settings.label), findsOneWidget);
    expect(
      find.byTooltip(
        '${l10n.settings} (${BusyMarkAppShortcuts.settings.label})',
      ),
      findsNothing,
    );
    expect(find.text(l10n.keyboardShortcuts), findsNothing);
    expect(find.text('Ctrl+Alt+K'), findsNothing);
    expect(find.text(l10n.syntaxReference), findsOneWidget);
    expect(
      find.text(BusyMarkAppShortcuts.syntaxReference.label),
      findsOneWidget,
    );
    expect(
      find.byTooltip(
        '${l10n.syntaxReference} '
        '(${BusyMarkAppShortcuts.syntaxReference.label})',
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
          ..._smokeAccentOverrides,
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
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._smokeAccentOverrides,
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
    expect(find.byType(KeyboardShortcutsSettings), findsNothing);
    await pressShortcut(LogicalKeyboardKey.keyS, control: true, alt: true);
    await _selectShortcutSettingsPage(tester);
    expect(find.byType(KeyboardShortcutsSettings), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(KeyboardShortcutsSettings), findsOneWidget);
    await pressShortcut(LogicalKeyboardKey.arrowLeft, alt: true);
    expect(find.byType(KeyboardShortcutsSettings), findsNothing);

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
          ..._smokeAccentOverrides,
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

    Finder groupedSection(String title) => find.byWidgetPredicate(
      (widget) => widget is BusyMarkGroupedList && widget.title == title,
    );
    void expectControlInSection(String sectionTitle, String controlTitle) {
      expect(
        find.descendant(
          of: groupedSection(sectionTitle),
          matching: find.text(controlTitle),
        ),
        findsOneWidget,
      );
    }

    expect(
      tester
          .widgetList<BusyMarkGroupedList>(find.byType(BusyMarkGroupedList))
          .map((section) => section.title),
      [
        l10n.editor,
        l10n.settingsEditingButtonsSectionTitle,
        l10n.spelling,
        l10n.settingsDictionariesSectionTitle,
      ],
    );
    expectControlInSection(l10n.editor, l10n.autoSave);
    expectControlInSection(l10n.editor, l10n.editorFontSize);
    expectControlInSection(
      l10n.settingsEditingButtonsSectionTitle,
      l10n.editingButtonsPosition,
    );
    expectControlInSection(
      l10n.settingsEditingButtonsSectionTitle,
      l10n.editingButtonsDirection,
    );
    expectControlInSection(l10n.spelling, l10n.automaticSpelling);
    expectControlInSection(l10n.spelling, l10n.defaultSpellingLanguage);
    expectControlInSection(l10n.spelling, l10n.projectSpellingLanguage);
    expectControlInSection(
      l10n.settingsDictionariesSectionTitle,
      l10n.spellingDictionaries,
    );
    expectControlInSection(
      l10n.settingsDictionariesSectionTitle,
      l10n.personalSpellingDictionary,
    );
    expectControlInSection(
      l10n.settingsDictionariesSectionTitle,
      l10n.projectSpellingDictionary,
    );
    final dictionariesSection = tester.widget<BusyMarkGroupedList>(
      groupedSection(l10n.settingsDictionariesSectionTitle),
    );
    expect(dictionariesSection.children, hasLength(3));
    expect(find.text(l10n.importSpellingDictionary), findsNothing);
    expect(
      tester.widget<BusyMarkClamp>(find.byType(BusyMarkClamp)).scrollable,
      isTrue,
    );

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
    expect(find.text(l10n.wordWrapDescription), findsOneWidget);
    final autoSaveRow = find.byWidgetPredicate(
      (widget) => widget is BusyMarkSwitchRow && widget.title == l10n.autoSave,
    );
    expect(autoSaveRow, findsOneWidget);
    expect(
      tester.widget<BusyMarkSwitchRow>(autoSaveRow).value,
      AppSettings.defaults().autoSave,
    );

    await tester.tap(
      find.descendant(of: autoSaveRow, matching: find.byType(BusyMarkSwitch)),
    );
    await tester.pumpAndSettle();
    expect(settingsStore.value['autoSave'], isFalse);
    expect(tester.widget<BusyMarkSwitchRow>(autoSaveRow).value, isFalse);

    await tester.tap(find.text(l10n.autoSave));
    await tester.pumpAndSettle();
    expect(settingsStore.value['autoSave'], isTrue);
    expect(tester.widget<BusyMarkSwitchRow>(autoSaveRow).value, isTrue);

    final header = tester.widget<HeaderBarConfigurationPublisher>(
      find.byType(HeaderBarConfigurationPublisher),
    );
    expect(header.configuration.title, l10n.editor);
    expect(header.configuration.sidebarVisible, isFalse);
    expect(
      find.byKey(const ValueKey('settings-page-selector')),
      findsOneWidget,
    );
    expect(find.byType(BusyMarkGroupedList), findsNWidgets(4));
    expect(find.text(l10n.autoSave), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('settings-page-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.validation));
    await tester.pumpAndSettle();

    expect(find.text(l10n.validateOnEdit), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('settings-page-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.settingsHistory));
    await tester.pumpAndSettle();

    final historySection = find.byWidgetPredicate(
      (widget) =>
          widget is BusyMarkGroupedList && widget.title == l10n.settingsHistory,
    );
    expect(historySection, findsOneWidget);
    expect(
      find.descendant(
        of: historySection,
        matching: find.byType(BusyMarkComboRow<int>),
      ),
      findsNWidgets(3),
    );
    expect(
      find.descendant(
        of: historySection,
        matching: find.byType(DropdownButton<int>),
      ),
      findsNothing,
    );

    BusyMarkComboRow<int> historyRow(String title) =>
        tester.widget<BusyMarkComboRow<int>>(
          find.byWidgetPredicate(
            (widget) =>
                widget is BusyMarkComboRow<int> && widget.title == title,
          ),
        );
    expect(historyRow(l10n.settingsHistoryCheckpoint).values, [
      30,
      60,
      120,
      300,
      600,
    ]);
    expect(historyRow(l10n.settingsHistoryCheckpoint).selected, 60);
    expect(
      historyRow(l10n.settingsHistoryCheckpoint).labelFor(60),
      l10n.settingsSecondsValue(60),
    );
    expect(historyRow(l10n.settingsHistoryRetention).values, [7, 30, 90, 365]);
    expect(historyRow(l10n.settingsHistoryRetention).selected, 30);
    expect(
      historyRow(l10n.settingsHistoryRetention).labelFor(30),
      l10n.settingsDaysValue(30),
    );
    expect(historyRow(l10n.settingsHistoryStorage).values, [
      128,
      256,
      512,
      1024,
      2048,
      4096,
    ]);
    expect(historyRow(l10n.settingsHistoryStorage).selected, 512);
    expect(
      historyRow(l10n.settingsHistoryStorage).labelFor(512),
      l10n.settingsMebibytesValue(512),
    );

    await tester.tap(find.byTooltip(l10n.settingsHistoryCheckpoint));
    await tester.pumpAndSettle();
    for (final choice in [30, 60, 120, 300, 600]) {
      expect(find.text(l10n.settingsSecondsValue(choice)), findsWidgets);
    }
    expect(find.byType(Radio<int>), findsNothing);
    expect(find.byType(RadioListTile<int>), findsNothing);
    await tester.tap(find.text(l10n.settingsSecondsValue(120)).last);
    await tester.pumpAndSettle();
    expect(settingsStore.value['localHistoryCheckpointSeconds'], 120);
    expect(historyRow(l10n.settingsHistoryCheckpoint).selected, 120);

    historyRow(l10n.settingsHistoryRetention).onSelected(90);
    await tester.pumpAndSettle();
    expect(settingsStore.value['localHistoryRetentionDays'], 90);
    expect(historyRow(l10n.settingsHistoryRetention).selected, 90);

    historyRow(l10n.settingsHistoryStorage).onSelected(1024);
    await tester.pumpAndSettle();
    expect(settingsStore.value['localHistoryMaximumStorageMiB'], 1024);
    expect(historyRow(l10n.settingsHistoryStorage).selected, 1024);

    Future<void> openExcludedPaths() async {
      final row = find.byWidgetPredicate(
        (widget) =>
            widget is BusyMarkActionRow &&
            widget.title == l10n.settingsHistoryExcludedPaths,
      );
      await tester.ensureVisible(row);
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(find.byType(BusyMarkDialogShell), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    }

    await openExcludedPaths();
    final excludedEntry = find.byType(BusyMarkGroupedTextEntry);
    final excluded = tester.widget<BusyMarkGroupedTextEntry>(excludedEntry);
    expect(excluded.controller!.text, '');
    expect(excluded.maxLines, 12);
    expect(excluded.onSubmitted, isNull);
    await tester.enterText(excludedEntry, '/tmp/build');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.testTextInput.receiveAction(TextInputAction.newline);
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(text: '/tmp/build\n'),
    );
    await tester.pump();
    expect(find.byType(BusyMarkDialogShell), findsOneWidget);
    expect(excluded.controller!.text, contains('\n'));
    await tester.enterText(excludedEntry, '/tmp/build\r\n/tmp/cache');
    await tester.tap(find.text(l10n.save));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(settingsStore.value['localHistoryExcludedPaths'], [
      '/tmp/build',
      '/tmp/cache',
    ]);
    await openExcludedPaths();
    expect(
      tester.widget<BusyMarkGroupedTextEntry>(excludedEntry).controller!.text,
      '/tmp/build\n/tmp/cache',
    );
    await tester.enterText(excludedEntry, 'discard');
    await tester.tap(find.text(l10n.cancel));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(settingsStore.value['localHistoryExcludedPaths'], [
      '/tmp/build',
      '/tmp/cache',
    ]);

    await tester.ensureVisible(find.text(l10n.settingsLocalHistoryTitle));
    await tester.tap(find.text(l10n.settingsLocalHistoryTitle));
    await tester.pumpAndSettle();
    expect(settingsStore.value['localHistoryRecordingEnabled'], isFalse);
    expect(
      tester
          .widgetList<BusyMarkComboRow<int>>(
            find.descendant(
              of: historySection,
              matching: find.byType(BusyMarkComboRow<int>),
            ),
          )
          .every((row) => !row.enabled),
      isTrue,
    );

    final clearRecentRow = tester.widget<BusyMarkActionRow>(
      find.byWidgetPredicate(
        (widget) =>
            widget is BusyMarkActionRow &&
            widget.title == l10n.clearRecentWorkspaces,
      ),
    );
    expect(clearRecentRow.destructive, isTrue);
    expect(clearRecentRow.onTap, isNotNull);
    final clearRecentTitle = find.text(l10n.clearRecentWorkspaces);
    final clearRecentContext = tester.element(clearRecentTitle);
    expect(
      tester.widget<Text>(clearRecentTitle).style?.color,
      busyMarkDestructiveForeground(clearRecentContext),
    );
    expect(Theme.of(clearRecentContext).brightness, Brightness.dark);
    expect(
      busyMarkDestructiveForeground(clearRecentContext),
      isNot(Theme.of(clearRecentContext).colorScheme.error),
    );

    expect(
      find.text(l10n.settingsReopenWorkspaceOnStartupTitle),
      findsOneWidget,
    );
    expect(
      find.text(l10n.settingsReopenWorkspaceOnStartupDescription),
      findsOneWidget,
    );
    await tester.ensureVisible(
      find.text(l10n.settingsReopenWorkspaceOnStartupTitle),
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
    await tester.ensureVisible(
      find.text(l10n.settingsConfirmCloseWithUnsavedChangesTitle),
    );
    await tester.tap(
      find.text(l10n.settingsConfirmCloseWithUnsavedChangesTitle),
    );
    await tester.pumpAndSettle();

    expect(settingsStore.value['confirmCloseWithUnsavedChanges'], isFalse);

    await tester.tap(
      find.byTooltip('${l10n.back} (${BusyMarkAppShortcuts.back.label})'),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.createMarkdownFile), findsOneWidget);
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
          ..._smokeAccentOverrides,
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
      findsNWidgets(SettingsPage.values.length - 1),
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
    expect(
      tester
          .widgetList<BusyMarkGroupedList>(find.byType(BusyMarkGroupedList))
          .map((section) => section.title),
      [
        l10n.editor,
        l10n.settingsEditingButtonsSectionTitle,
        l10n.spelling,
        l10n.settingsDictionariesSectionTitle,
      ],
    );
    expect(find.text(l10n.autoSave), findsOneWidget);
    header = tester.widget<HeaderBarConfigurationPublisher>(
      find.byType(HeaderBarConfigurationPublisher),
    );
    expect(header.configuration.sidebarVisible, isTrue);
    expect(header.configuration.title, l10n.editor);

    expect(find.text(l10n.spellingDictionaries), findsOneWidget);
    expect(find.byType(BusyMarkSidebarSurface), findsOneWidget);
    expect(find.byKey(const ValueKey('settings-page-selector')), findsNothing);
    expect(find.byType(Scrollable), findsWidgets);
    expect(
      tester.widget<BusyMarkClamp>(find.byType(BusyMarkClamp)).scrollable,
      isTrue,
    );
    header = tester.widget<HeaderBarConfigurationPublisher>(
      find.byType(HeaderBarConfigurationPublisher),
    );
    expect(header.configuration.sidebarVisible, isTrue);
    expect(header.configuration.title, l10n.editor);
    expect(
      tester
          .widget<BusyMarkSidebarNavigationTile>(
            find.byKey(const ValueKey('settings-navigation-editor')),
          )
          .selected,
      isTrue,
    );
    header = tester.widget<HeaderBarConfigurationPublisher>(
      find.byType(HeaderBarConfigurationPublisher),
    );
    expect(header.configuration.sidebarVisible, isTrue);
    expect(header.configuration.title, l10n.editor);

    final dictionariesNavigation = find.byKey(
      const ValueKey('settings-spelling-dictionaries'),
    );
    await tester.ensureVisible(dictionariesNavigation);
    await tester.tap(dictionariesNavigation);
    await tester.pumpAndSettle();

    expect(find.byType(BusyMarkSidebarSurface), findsOneWidget);
    expect(find.byKey(const ValueKey('settings-page-selector')), findsNothing);
    expect(
      tester
          .widget<BusyMarkSidebarNavigationTile>(
            find.byKey(const ValueKey('settings-navigation-editor')),
          )
          .selected,
      isTrue,
    );
    header = tester.widget<HeaderBarConfigurationPublisher>(
      find.byType(HeaderBarConfigurationPublisher),
    );
    expect(header.configuration.title, l10n.spellingDictionaries);
    expect(find.text(l10n.importSpellingDictionary), findsOneWidget);
    expect(find.text(l10n.spellingDictionaryProblems), findsNothing);

    await tester.tap(
      find.byTooltip('${l10n.back} (${BusyMarkAppShortcuts.back.label})'),
    );
    await tester.pumpAndSettle();
    header = tester.widget<HeaderBarConfigurationPublisher>(
      find.byType(HeaderBarConfigurationPublisher),
    );
    expect(header.configuration.title, l10n.editor);
    expect(find.text(l10n.autoSave), findsOneWidget);
  });

  testWidgets(
    'Spelling Dictionaries page groups downloadable and custom data',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 900);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      late Directory temporary;
      late ({String bundle, String storage}) fixture;
      late SpellingSessionController spelling;
      await tester.runAsync(() async {
        temporary = await Directory.systemTemp.createTemp(
          'busymark-settings-dictionaries-',
        );
        fixture = await _createSettingsSpellingFixture(temporary);
        spelling = SpellingSessionController(
          bundledRoot: fixture.bundle,
          applicationSupportRoot: p.join(temporary.path, 'support'),
          dictionaryStorageRoot: fixture.storage,
          verifyDictionaryChecksums: false,
        );
        await spelling.prepareSettings(null);
      });
      final container = ProviderContainer(
        overrides: [
          ..._smokeAccentOverrides,
          linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
          localSettingsStoreProvider.overrideWithValue(_MemorySettingsStore()),
          spellingSessionControllerProvider.overrideWith((ref) => spelling),
        ],
      );
      addTearDown(() async {
        container.dispose();
        if (await temporary.exists()) {
          await temporary.delete(recursive: true);
        }
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BusyMarkApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip(l10n.mainMenu));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.settings));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('settings-page-selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.editor));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('settings-spelling-dictionaries')),
      );
      await tester.pumpAndSettle();

      final availableGroup = find.byWidgetPredicate(
        (widget) =>
            widget is BusyMarkGroupedList &&
            widget.title == l10n.availableSpellingDictionaries,
      );
      final customGroup = find.byWidgetPredicate(
        (widget) =>
            widget is BusyMarkGroupedList &&
            widget.title == l10n.customSpellingDictionaries,
      );
      final problemsGroup = find.byWidgetPredicate(
        (widget) =>
            widget is BusyMarkGroupedList &&
            widget.title == l10n.spellingDictionaryProblems,
      );
      expect(availableGroup, findsOneWidget);
      expect(customGroup, findsOneWidget);
      expect(problemsGroup, findsOneWidget);
      expect(
        find.byKey(const ValueKey('settings-page-selector')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('settings-page-selector')),
          matching: find.text(l10n.editor),
        ),
        findsOneWidget,
      );
      expect(
        container
            .read(appRouterProvider)
            .routerDelegate
            .currentConfiguration
            .uri
            .queryParameters['page'],
        'spellingDictionaries',
      );
      expect(find.byType(Scrollable), findsOneWidget);
      expect(
        tester.widget<BusyMarkClamp>(find.byType(BusyMarkClamp)).scrollable,
        isTrue,
      );
      expect(find.text(l10n.importSpellingDictionary), findsOneWidget);
      expect(find.text('Test English'), findsOneWidget);
      expect(find.text('Test French'), findsOneWidget);
      expect(find.text(l10n.spellingDictionaryInstalled), findsOneWidget);
      expect(find.textContaining('Not installed ·'), findsAtLeastNWidgets(1));
      expect(find.text('Local Test English'), findsOneWidget);
      expect(find.text('xx-Test'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Test English')).dy,
        lessThan(tester.getTopLeft(find.text('Test French')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Test French')).dy,
        lessThan(
          tester.getTopLeft(find.text(l10n.importSpellingDictionary)).dy,
        ),
      );
      expect(
        tester.getTopLeft(find.text(l10n.importSpellingDictionary)).dy,
        lessThan(tester.getTopLeft(find.text('Local Test English')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Local Test English')).dy,
        lessThan(tester.getTopLeft(find.text('xx-Test')).dy),
      );
      for (final resourceTitle in ['Test English', 'Test French']) {
        final row = find.byWidgetPredicate(
          (widget) =>
              widget is BusyMarkActionRow && widget.title == resourceTitle,
        );
        expect(
          find.descendant(
            of: row,
            matching: find.byType(BusyMarkCompactIconButton),
          ),
          findsOneWidget,
        );
        final actionRow = tester.widget<BusyMarkActionRow>(row);
        expect(actionRow.onTap, isNull);
        expect(actionRow.destructive, isFalse);
      }

      final importRow = tester.widget<BusyMarkActionRow>(
        find.byKey(const ValueKey('import-spelling-dictionary')),
      );
      expect(importRow.onTap, isNotNull);
      final importedRow = tester.widget<BusyMarkActionRow>(
        find.byWidgetPredicate(
          (widget) =>
              widget is BusyMarkActionRow &&
              widget.title == 'Local Test English',
        ),
      );
      expect(importedRow.destructive, isFalse);
      expect(importedRow.onTap, isNull);
      final importedRemove = importedRow.trailing! as BusyMarkCompactIconButton;
      expect(importedRemove.onPressed, isNotNull);
      expect(
        importedRemove.foregroundColor,
        Theme.of(tester.element(customGroup)).colorScheme.error,
      );
      final invalidRow = tester.widget<BusyMarkActionRow>(
        find.byWidgetPredicate(
          (widget) => widget is BusyMarkActionRow && widget.title == 'xx-Test',
        ),
      );
      expect(invalidRow.destructive, isFalse);
      expect(invalidRow.onTap, isNull);
      final invalidRemove = invalidRow.trailing! as BusyMarkCompactIconButton;
      expect(invalidRemove.onPressed, isNotNull);
      expect(
        invalidRemove.foregroundColor,
        Theme.of(tester.element(problemsGroup)).colorScheme.error,
      );

      await tester.ensureVisible(find.text('Local Test English'));
      await tester.tap(find.text('Local Test English'));
      await tester.pumpAndSettle();
      expect(
        spelling.catalog?.installations.any(
          (entry) => entry.id == 'local-Test' && entry.imported,
        ),
        isTrue,
      );
    },
  );

  testWidgets('dictionary import continues real I/O without another frame', (
    tester,
  ) async {
    var gateNextCatalog = false;
    final catalogEntered = Completer<void>();
    final releaseCatalog = Completer<void>();
    var catalogResumed = false;
    final harness = await _pumpSettingsSpellingHarness(
      tester,
      headerBarService: headerBarService,
      settingsStore: _MemorySettingsStore(),
      downloadFile: _copySettingsDictionaryDownload,
      catalogLoader:
          ({
            required bundledRoot,
            required downloadedRoot,
            required importedRoot,
            required verifyChecksums,
          }) async {
            if (gateNextCatalog && !catalogEntered.isCompleted) {
              catalogEntered.complete();
              await releaseCatalog.future;
              // Model a cooperative retry/yield in a real-I/O provider.
              await Future<void>.delayed(Duration.zero);
              catalogResumed = true;
            }
            return SpellingDictionaryCatalog.load(
              bundledRoot: bundledRoot,
              downloadedRoot: downloadedRoot,
              importedRoot: importedRoot,
              verifyChecksums: verifyChecksums,
            );
          },
    );
    addTearDown(harness.dispose);
    const channel = MethodChannel('plugins.flutter.io/file_selector');
    final fixtures = p.join(
      Directory.current.path,
      'packages',
      'busymark_spellcheck_native',
      'test',
      'fixtures',
    );
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (_) async => [p.join(fixtures, 'test.aff'), p.join(fixtures, 'test.dic')],
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    await _openImportDictionaryPrompt(tester);
    gateNextCatalog = true;
    await tester.enterText(find.byType(TextFormField), ' en-GB ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    // Keep the original import assertion's fifteen-second wall budget, including
    // the controlled scheduling check. There is no additional allowance.
    final deadline = DateTime.now().add(const Duration(seconds: 15));
    await _pumpUntilCondition(
      tester,
      () => catalogEntered.isCompleted,
      timeout: deadline.difference(DateTime.now()),
    );
    var resumedWithoutFrame = false;
    await tester.runAsync(() async {
      releaseCatalog.complete();
      // Drain real microtask and zero-timer turns without a fake frame.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      resumedWithoutFrame = catalogResumed;
    });
    await _pumpUntilCondition(
      tester,
      () => harness.spelling.catalog?.installedById('en-GB') != null,
      timeout: deadline.difference(DateTime.now()),
    );
    expect(find.byType(BusyMarkDialogShell), findsNothing);
    expect(harness.spelling.catalog?.installedById('en-GB'), isNotNull);
    expect(
      resumedWithoutFrame,
      isTrue,
      reason: 'The real-I/O continuation must not require a fake widget frame.',
    );
  });

  testWidgets(
    'import dictionary prompt uses native controls and submits a trimmed ID',
    (tester) async {
      final harness = await _pumpSettingsSpellingHarness(
        tester,
        headerBarService: headerBarService,
        settingsStore: _MemorySettingsStore(),
        downloadFile: _copySettingsDictionaryDownload,
      );
      addTearDown(harness.dispose);
      const fileSelectorChannel = MethodChannel(
        'plugins.flutter.io/file_selector',
      );
      final dictionaryFixture = p.join(
        Directory.current.path,
        'packages',
        'busymark_spellcheck_native',
        'test',
        'fixtures',
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        fileSelectorChannel,
        (call) async {
          expect(call.method, 'openFile');
          expect((call.arguments as Map<Object?, Object?>)['multiple'], isTrue);
          return <String>[
            p.join(dictionaryFixture, 'test.aff'),
            p.join(dictionaryFixture, 'test.dic'),
          ];
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          fileSelectorChannel,
          null,
        ),
      );

      await _openImportDictionaryPrompt(tester);

      final dialog = find.byType(BusyMarkDialogShell);
      expect(dialog, findsOneWidget);
      final shell = tester.widget<BusyMarkDialogShell>(dialog);
      expect(shell.title, l10n.importSpellingDictionary);
      expect(shell.closable, isFalse);
      final entryFinder = find.descendant(
        of: dialog,
        matching: find.byType(BusyMarkFloatingTextEntry),
      );
      expect(entryFinder, findsOneWidget);
      final entry = tester.widget<BusyMarkFloatingTextEntry>(entryFinder);
      expect(entry.label, l10n.language);
      expect(entry.hintText, 'en-US');
      expect(entry.autofocus, isTrue);
      expect(entry.textInputAction, TextInputAction.done);
      expect(entry.minLines, 1);
      expect(entry.maxLines, 1);
      final actions = tester
          .widgetList<BusyMarkDialogButton>(
            find.descendant(
              of: dialog,
              matching: find.byType(BusyMarkDialogButton),
            ),
          )
          .toList(growable: false);
      expect(actions, hasLength(2));
      expect(actions.map((action) => action.label), [l10n.cancel, l10n.save]);
      expect(actions.first.suggested, isFalse);
      expect(actions.last.suggested, isTrue);
      expect(find.byType(AlertDialog), findsNothing);

      await tester.enterText(find.byType(TextFormField), '   ');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await _pumpSettingsUi(tester);
      expect(dialog, findsOneWidget);

      await tester.enterText(find.byType(TextFormField), ' en-GB ');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump(kThemeAnimationDuration);
      await _pumpUntilCondition(
        tester,
        () => harness.spelling.catalog?.installedById('en-GB') != null,
        timeout: const Duration(seconds: 15),
        diagnostics: () {
          final imported = Directory(
            p.join(
              harness.temporary.path,
              'dictionary-storage',
              'imported',
              'en-GB',
            ),
          );
          return 'imported directory=${imported.existsSync()}, '
              'installed=${harness.spelling.catalog?.installedById('en-GB')}, '
              'invalid=${harness.spelling.catalog?.invalidInstallations}, '
              'dialog visible=${dialog.evaluate().isNotEmpty}';
        },
      );

      expect(dialog, findsNothing);
      expect(harness.spelling.catalog?.installedById('en-GB'), isNotNull);
    },
  );

  testWidgets('import dictionary prompt cancels and saves without redesign', (
    tester,
  ) async {
    final harness = await _pumpSettingsSpellingHarness(
      tester,
      headerBarService: headerBarService,
      settingsStore: _MemorySettingsStore(),
      downloadFile: _copySettingsDictionaryDownload,
    );
    addTearDown(harness.dispose);
    const fileSelectorChannel = MethodChannel(
      'plugins.flutter.io/file_selector',
    );
    final dictionaryFixture = p.join(
      Directory.current.path,
      'packages',
      'busymark_spellcheck_native',
      'test',
      'fixtures',
    );
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      fileSelectorChannel,
      (call) async => <String>[
        p.join(dictionaryFixture, 'test.aff'),
        p.join(dictionaryFixture, 'test.dic'),
      ],
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        fileSelectorChannel,
        null,
      ),
    );

    await _openImportDictionaryPrompt(tester);
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is BusyMarkDialogButton && widget.label == l10n.cancel,
      ),
    );
    await _pumpSettingsUi(tester);

    expect(find.byType(BusyMarkDialogShell), findsNothing);
    expect(harness.spelling.catalog?.installedById('en-GB'), isNull);

    await tester.tap(find.byKey(const ValueKey('import-spelling-dictionary')));
    await _pumpUntilFound(tester, find.byType(BusyMarkDialogShell));
    await tester.enterText(find.byType(TextFormField), ' en-GB ');
    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is BusyMarkDialogButton && widget.label == l10n.save,
      ),
    );
    await tester.pump(kThemeAnimationDuration);
    await _pumpUntilCondition(
      tester,
      () => harness.spelling.catalog?.installedById('en-GB') != null,
      timeout: const Duration(seconds: 15),
      diagnostics: () {
        final imported = Directory(
          p.join(
            harness.temporary.path,
            'dictionary-storage',
            'imported',
            'en-GB',
          ),
        );
        return 'imported directory=${imported.existsSync()}, '
            'catalog unavailable=${harness.spelling.catalog == null}, '
            'installed=${harness.spelling.catalog?.installedById('en-GB')}';
      },
    );

    expect(find.byType(BusyMarkDialogShell), findsNothing);
    expect(harness.spelling.catalog?.installedById('en-GB'), isNotNull);
  });

  testWidgets(
    'cancelling a default-language install keeps the previous selection',
    (tester) async {
      var downloadCount = 0;
      final settingsStore = _MemorySettingsStore()
        ..value = AppSettings.defaults()
            .copyWith(defaultSpellingLanguage: 'en-Test')
            .toJson();
      final harness = await _pumpSettingsSpellingHarness(
        tester,
        headerBarService: headerBarService,
        settingsStore: settingsStore,
        downloadFile:
            ({
              required source,
              required destination,
              required expectedBytes,
              required cancellation,
              required onProgress,
            }) async {
              downloadCount += 1;
              await _copySettingsDictionaryDownload(
                source: source,
                destination: destination,
                expectedBytes: expectedBytes,
                cancellation: cancellation,
                onProgress: onProgress,
              );
            },
      );
      addTearDown(harness.dispose);

      await _selectSpellingLanguage(
        tester,
        selectorTooltip: l10n.defaultSpellingLanguage,
        languageLabel: 'Test French',
      );

      expect(find.text(l10n.spellingDictionaryNotInstalled), findsOneWidget);
      expect(find.byType(BusyMarkDialogShell), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(settingsStore.value['defaultSpellingLanguage'], 'en-Test');
      await tester.tap(find.text(l10n.cancel));
      await _pumpSettingsUi(tester);

      expect(settingsStore.value['defaultSpellingLanguage'], 'en-Test');
      expect(
        _spellingLanguageSelector(tester, l10n.defaultSpellingLanguage).label,
        'Test English',
      );
      expect(downloadCount, 0);
    },
  );

  testWidgets('settings readiness advances UI timers after real I/O', (
    tester,
  ) async {
    var ioReady = false;
    var uiReady = false;
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 1));
      ioReady = true;
    });
    Timer(const Duration(milliseconds: 75), () => uiReady = true);
    await _pumpUntilCondition(
      tester,
      () => ioReady && uiReady,
      timeout: const Duration(seconds: 1),
    );
  });

  testWidgets(
    'default language persists only after dictionary installation succeeds',
    (tester) async {
      var downloadCount = 0;
      final allowDownload = Completer<void>();
      final settingsStore = _MemorySettingsStore()
        ..value = AppSettings.defaults()
            .copyWith(defaultSpellingLanguage: 'en-Test')
            .toJson();
      final harness = await _pumpSettingsSpellingHarness(
        tester,
        headerBarService: headerBarService,
        settingsStore: settingsStore,
        downloadFile:
            ({
              required source,
              required destination,
              required expectedBytes,
              required cancellation,
              required onProgress,
            }) async {
              downloadCount += 1;
              await allowDownload.future;
              await _copySettingsDictionaryDownload(
                source: source,
                destination: destination,
                expectedBytes: expectedBytes,
                cancellation: cancellation,
                onProgress: onProgress,
              );
            },
      );
      addTearDown(harness.dispose);

      await _selectSpellingLanguage(
        tester,
        selectorTooltip: l10n.defaultSpellingLanguage,
        languageLabel: 'Test French',
      );
      await tester.tap(find.text(l10n.installSpellingDictionary));
      await _pumpUntilCondition(tester, () => downloadCount > 0);

      expect(settingsStore.value['defaultSpellingLanguage'], 'en-Test');
      expect(
        _spellingLanguageSelector(tester, l10n.defaultSpellingLanguage).label,
        'Test English',
      );

      allowDownload.complete();
      await _pumpUntilCondition(
        tester,
        () => settingsStore.value['defaultSpellingLanguage'] == 'fr-Test',
        timeout: const Duration(seconds: 15),
        diagnostics: () =>
            'downloads=$downloadCount, '
            'installed=${harness.spelling.catalog?.installedById('fr-Test')}, '
            'catalog unavailable=${harness.spelling.catalog == null}, '
            'phase=${harness.spelling.dictionaryInstallStatus?.phase}, '
            'install error=${harness.spelling.dictionaryInstallStatus?.error}, '
            'invalid=${harness.spelling.catalog?.invalidInstallations}, '
            'persisted=${settingsStore.value['defaultSpellingLanguage']}',
      );

      expect(harness.spelling.catalog?.installedById('fr-Test'), isNotNull);
      expect(settingsStore.value['defaultSpellingLanguage'], 'fr-Test');
      expect(
        _spellingLanguageSelector(tester, l10n.defaultSpellingLanguage).label,
        'Test French',
      );
      expect(downloadCount, 2);
    },
  );

  testWidgets('failed dictionary install keeps the default language', (
    tester,
  ) async {
    var downloadCount = 0;
    final settingsStore = _MemorySettingsStore()
      ..value = AppSettings.defaults()
          .copyWith(defaultSpellingLanguage: 'en-Test')
          .toJson();
    final harness = await _pumpSettingsSpellingHarness(
      tester,
      headerBarService: headerBarService,
      settingsStore: settingsStore,
      downloadFile:
          ({
            required source,
            required destination,
            required expectedBytes,
            required cancellation,
            required onProgress,
          }) async {
            downloadCount += 1;
            throw const SocketException('test dictionary download failure');
          },
    );
    addTearDown(harness.dispose);

    await _selectSpellingLanguage(
      tester,
      selectorTooltip: l10n.defaultSpellingLanguage,
      languageLabel: 'Test French',
    );
    await tester.tap(find.text(l10n.installSpellingDictionary));
    await _pumpUntilCondition(
      tester,
      () =>
          harness.spelling.dictionaryInstallStatus?.phase ==
          SpellingDictionaryInstallPhase.failed,
    );

    expect(downloadCount, 1);
    expect(settingsStore.value['defaultSpellingLanguage'], 'en-Test');
    expect(
      _spellingLanguageSelector(tester, l10n.defaultSpellingLanguage).label,
      'Test English',
    );
    expect(find.text(l10n.commandUnavailableInContext), findsOneWidget);
  });

  testWidgets(
    'cancelling a project-language install keeps the previous selection',
    (tester) async {
      var downloadCount = 0;
      final harness = await _pumpSettingsSpellingHarness(
        tester,
        headerBarService: headerBarService,
        settingsStore: _MemorySettingsStore(),
        projectLanguage: 'en-Test',
        downloadFile:
            ({
              required source,
              required destination,
              required expectedBytes,
              required cancellation,
              required onProgress,
            }) async {
              downloadCount += 1;
              await _copySettingsDictionaryDownload(
                source: source,
                destination: destination,
                expectedBytes: expectedBytes,
                cancellation: cancellation,
                onProgress: onProgress,
              );
            },
      );
      addTearDown(harness.dispose);

      await _selectSpellingLanguage(
        tester,
        selectorTooltip: l10n.projectSpellingLanguage,
        languageLabel: 'Test French',
      );

      expect(find.text(l10n.spellingDictionaryNotInstalled), findsOneWidget);
      expect(harness.spelling.projectWords.projectLanguage, 'en-Test');
      await tester.tap(find.text(l10n.cancel));
      await _pumpSettingsUi(tester);

      expect(harness.spelling.projectWords.projectLanguage, 'en-Test');
      expect(
        _spellingLanguageSelector(tester, l10n.projectSpellingLanguage).label,
        'Test English',
      );
      expect(downloadCount, 0);
      final persistedSource = await tester.runAsync(
        () => File(harness.projectSpellingPath!).readAsString(),
      );
      final persisted = jsonDecode(persistedSource!);
      expect((persisted as Map<String, Object?>)['projectLanguage'], 'en-Test');
    },
  );

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
            ..._smokeAccentOverrides,
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
          ..._smokeAccentOverrides,
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

  for (final localeCase in <({String name, Locale requested, Locale expected})>[
    (
      name: 'European Portuguese',
      requested: const Locale('pt', 'PT'),
      expected: const Locale('pt'),
    ),
    (
      name: 'language-only Chinese',
      requested: const Locale('zh'),
      expected: const Locale('zh'),
    ),
  ]) {
    testWidgets(
      '${localeCase.name} system locale renders the completed base catalog',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1;
        tester.binding.platformDispatcher.localesTestValue = <Locale>[
          localeCase.requested,
        ];
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          tester.binding.platformDispatcher.clearLocalesTestValue();
        });
        final translated = lookupAppLocalizations(localeCase.expected);
        final settingsStore = _MemorySettingsStore();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ..._smokeAccentOverrides,
              linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
              localSettingsStoreProvider.overrideWithValue(settingsStore),
            ],
            child: const BusyMarkApp(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(translated.createMarkdownFile), findsOneWidget);
        expect(find.text(l10n.createMarkdownFile), findsNothing);
        await tester.tap(find.byTooltip(translated.mainMenu));
        await tester.pumpAndSettle();
        await tester.tap(find.text(translated.settings));
        await tester.pumpAndSettle();

        expect(find.text(translated.appLanguage), findsOneWidget);
        expect(find.text(l10n.appLanguage), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

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
          ..._smokeAccentOverrides,
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

  testWidgets(
    'Keyboard Shortcuts opens its categorized Settings page and safely records assignments',
    (tester) async {
      final store = _MemorySettingsStore();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._smokeAccentOverrides,
            linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
            localSettingsStoreProvider.overrideWithValue(store),
          ],
          child: const BusyMarkApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(l10n.mainMenu));
      await tester.pumpAndSettle();
      expect(find.text(l10n.searchDocumentsCommand), findsNothing);
      expect(find.text(l10n.searchActionsCommand), findsNothing);
      expect(find.text(l10n.keyboardShortcuts), findsNothing);
      await tester.tap(find.text(l10n.settings));
      await tester.pumpAndSettle();
      await _selectShortcutSettingsPage(tester);
      expect(find.byType(KeyboardShortcutsSettings), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(KeyboardShortcutsSettings)),
      );
      final router = container.read(appRouterProvider);
      expect(
        router.routeInformationProvider.value.uri.queryParameters,
        containsPair('returnTo', 'welcome'),
      );
      await _browseShortcutRow(tester, 'file.save');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('record-shortcut')));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyO);
      await tester.pump();
      expect(
        find.descendant(
          of: find.byWidgetPredicate(
            (w) =>
                w is BusyMarkActionRow &&
                w.title == l10n.shortcutProposedBinding,
          ),
          matching: find.byWidgetPredicate(
            (w) => w is BusyMarkKeyboardShortcutBadge && w.label == 'Ctrl+O',
          ),
        ),
        findsOneWidget,
      );
      expect(find.text(l10n.shortcutConflicts), findsOneWidget);
      expect(
        find.byType(Dialog),
        findsOneWidget,
        reason: 'Capturing Ctrl+O must not open the application chooser',
      );
      expect(
        container.read(appSettingsControllerProvider).shortcutOverrides,
        isEmpty,
      );
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyO);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.tap(find.text(l10n.cancel).last);
      await tester.pumpAndSettle();
      expect(
        container.read(appSettingsControllerProvider).shortcutOverrides,
        isEmpty,
      );
      await tester.tap(find.byKey(const ValueKey('shortcut-edit-file.save')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('record-shortcut')));
      await tester.sendKeyEvent(LogicalKeyboardKey.f12);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('assign-shortcut')));
      await tester.pumpAndSettle();
      expect(
        container
            .read(busyMarkCommandRegistryProvider)['file.save']!
            .shortcut!
            .label,
        'F12',
      );
      expect(find.text('F12'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('settings-shortcut-search')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('find-by-shortcut')), findsNothing);
      await _browseShortcutRow(tester, 'view.source');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('remove-shortcut')));
      await tester.pumpAndSettle();
      expect(
        container
            .read(busyMarkCommandRegistryProvider)['view.source']!
            .shortcut,
        isNull,
      );
      expect(find.byType(Dialog), findsNothing);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pumpAndSettle();
      expect(find.byType(WelcomeScreen), findsOneWidget);
    },
  );

  testWidgets('syntax reference categories expose supported authoring forms', (
    tester,
  ) async {
    final l10n = AppLocalizationsEn();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._smokeAccentOverrides,
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
    expect(categoryText('html', l10n.insertBlankLine), findsOneWidget);
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
          ..._smokeAccentOverrides,
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

    expect(BusyMarkAppShortcuts.syntaxReference.label, 'Ctrl+Alt+M');
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
          ..._smokeAccentOverrides,
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

  testWidgets(
    'shortcut Settings keeps persistence failure visible and retries the current assignment',
    (tester) async {
      final store = _MemorySettingsStore();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._smokeAccentOverrides,
            linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
            localSettingsStoreProvider.overrideWithValue(store),
          ],
          child: const BusyMarkApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      await _selectShortcutSettingsPage(tester);
      await _browseShortcutRow(tester, 'file.save');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('record-shortcut')));
      await tester.sendKeyEvent(LogicalKeyboardKey.f8);
      await tester.pump();
      final previous = Map<String, Object?>.of(store.value);
      store.failSaves = true;
      await tester.tap(find.byKey(const ValueKey('assign-shortcut')));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byKey(const ValueKey('shortcut-feedback')), findsOneWidget);
      expect(find.text(l10n.shortcutSaveFailed), findsWidgets);
      expect(
        store.value,
        previous,
        reason: 'Failed publication leaves persisted preferences intact',
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(KeyboardShortcutsSettings)),
      );
      expect(
        container
            .read(busyMarkCommandRegistryProvider)['file.save']!
            .shortcut!
            .label,
        'F8',
      );
      expect(
        container.read(keymapControllerProvider),
        KeymapUpdateStatus.failed,
      );
      store.failSaves = false;
      await tester.tap(find.byKey(const ValueKey('assign-shortcut')));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(find.text(l10n.shortcutSaveFailed), findsNothing);
      expect(
        container.read(keymapControllerProvider),
        KeymapUpdateStatus.saved,
      );
      expect(
        AppSettings.fromJson(store.value).shortcutOverrides['file.save']!.key,
        LogicalKeyboardKey.f8,
      );
      expect(
        AppSettings.fromJson(store.value).autoSave,
        AppSettings.fromJson(previous).autoSave,
      );
    },
  );

  testWidgets('keyboard shortcuts tabs section title is localized', (
    tester,
  ) async {
    final fr = AppLocalizationsFr();
    final settingsStore = _MemorySettingsStore()
      ..value = AppSettings.defaults().copyWith(localeTag: 'fr').toJson();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._smokeAccentOverrides,
          linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
          localSettingsStoreProvider.overrideWithValue(settingsStore),
        ],
        child: const BusyMarkApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(fr.mainMenu));
    await tester.pumpAndSettle();
    expect(find.text(fr.keyboardShortcuts), findsNothing);
    await tester.tap(find.text(fr.settings));
    await tester.pumpAndSettle();
    await _selectShortcutSettingsPage(tester);

    await _revealShortcutRow(tester, 'tabs.next');
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.header == true &&
            w.child is Text &&
            (w.child as Text).data == fr.tabs,
      ),
      findsOneWidget,
    );
    expect(find.text('Tabs'), findsNothing);
    await _revealShortcutRow(tester, 'view.toggleSidebar');
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.header == true &&
            w.child is Text &&
            (w.child as Text).data == fr.shortcutGroupSidebar,
      ),
      findsOneWidget,
    );
    expect(find.text('Sidebar'), findsNothing);
  });

  testWidgets('about dialog shows the BusyMark logo', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._smokeAccentOverrides,
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
    final settingsStore = _MemorySettingsStore()
      ..value = AppSettings.defaults()
          .copyWith(defaultSpellingLanguage: null)
          .toJson();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._smokeAccentOverrides,
          linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
          localSettingsStoreProvider.overrideWithValue(settingsStore),
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
    expect(find.text(l10n.untitledMarkdownFileName), findsWidgets);
    expect(find.byKey(const ValueKey('editor-tab-strip')), findsNothing);
    expect(find.byKey(const ValueKey('document-status-bar')), findsOneWidget);
    expect(find.text('LF'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('document-spelling-language-status')),
      findsOneWidget,
    );
    expect(find.text(l10n.spellingLanguageUnsetStatus), findsOneWidget);
    final spellingBanner = find.byKey(const ValueKey('spelling-banner'));
    expect(spellingBanner, findsOneWidget);
    expect(tester.widget<BusyMarkBanner>(spellingBanner).revealed, isFalse);
  });

  testWidgets('Ctrl+N keeps unsaved documents in independent tabs', (
    tester,
  ) async {
    final service = _StartupWorkspaceService();
    final container = ProviderContainer(
      overrides: [
        ..._smokeAccentOverrides,
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

  testWidgets('Ctrl+N creates real CommonMark inside a Writerside workspace', (
    tester,
  ) async {
    const yaruWindowChannel = MethodChannel('yaru_window');
    const yaruWindowEventsChannel = MethodChannel('yaru_window/events');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(yaruWindowChannel, (call) async {
          if (call.method == 'state') return <String, Object?>{};
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
    final root = Directory('test/fixtures/writerside/basic_project').absolute;
    final container = ProviderContainer(
      overrides: [
        ..._smokeAccentOverrides,
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(
          _MemorySettingsStore()
            ..value = AppSettings.defaults().copyWith(autoSave: false).toJson(),
        ),
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
    await tester.runAsync(
      () => container
          .read(workspaceControllerProvider.notifier)
          .openPath(root.path),
    );
    for (var index = 0; index < 30; index += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (container.read(workspaceControllerProvider).workspace?.kind ==
          WorkspaceKind.writersideModule) {
        break;
      }
    }
    final before = container.read(workspaceControllerProvider);
    expect(before.workspace?.kind, WorkspaceKind.writersideModule);
    final topicId = before.activeBuffer!.id;

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(
      () => tester.tap(
        find.descendant(
          of: find.byType(BusyMarkDialogShell),
          matching: find.text(l10n.createMarkdownFile),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final controller = container.read(workspaceControllerProvider.notifier);
    const source = '''# Widget draft

Paragraph with *emphasis*.

- item

```text
code
    ```
''';
    await tester.runAsync(() async {
      controller.updateActiveText(source);
    });
    await tester.runAsync(() => controller.validateActive());
    for (var index = 0; index < 30; index += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (container
              .read(workspaceControllerProvider)
              .preview
              ?.blocks
              .any((block) => block.text == 'Widget draft') ??
          false) {
        break;
      }
    }

    var state = container.read(workspaceControllerProvider);
    final untitledId = state.activeBuffer!.id;
    final resolved = resolveWorkspaceDocumentContext(
      state.workspace!,
      state.activeBuffer!,
    );
    expect(state.workspace?.kind, WorkspaceKind.writersideModule);
    expect(state.workspace?.activeFilePath, isNull);
    expect(resolved.kind, DocumentKind.markdown);
    expect(resolved.markdownMode, MarkdownMode.commonMark);
    expect(
      state.preview?.blocks.map((block) => block.kind),
      containsAll(<PreviewBlockKind>[
        PreviewBlockKind.heading,
        PreviewBlockKind.paragraph,
        PreviewBlockKind.list,
        PreviewBlockKind.code,
      ]),
    );

    controller.updateActiveEditorMode(DocumentViewModePreference.source);
    await tester.pump(const Duration(milliseconds: 500));
    final sourceEditor = tester.widget<BusyMarkSourceEditor>(
      find.byType(BusyMarkSourceEditor),
    );
    expect(sourceEditor.documentId, untitledId);
    expect(sourceEditor.language.name, 'markdown');
    expect(sourceEditor.documentFormat?.name, 'markdown');
    expect(sourceEditor.markdownMode, MarkdownMode.commonMark);

    controller.updateActiveEditorMode(DocumentViewModePreference.editor);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('document-wysiwyg-pane')), findsOneWidget);
    expect(find.byKey(const ValueKey('document-source-pane')), findsNothing);

    expect(
      await tester.runAsync(() => controller.activateDocumentBuffer(topicId)),
      isTrue,
    );
    expect(
      await tester.runAsync(
        () => controller.activateDocumentBuffer(untitledId),
      ),
      isTrue,
    );
    await tester.pump(const Duration(milliseconds: 500));
    state = container.read(workspaceControllerProvider);
    expect(state.activeBuffer?.id, untitledId);
    expect(
      resolveWorkspaceDocumentContext(
        state.workspace!,
        state.activeBuffer!,
      ).markdownMode,
      MarkdownMode.commonMark,
    );
    expect(find.byKey(const ValueKey('document-wysiwyg-pane')), findsOneWidget);
    expect(
      state.preview?.blocks.any((block) => block.text == 'Widget draft'),
      isTrue,
    );

    controller.updateActiveEditorMode(DocumentViewModePreference.source);
    await tester.pump(const Duration(milliseconds: 300));
    final staleSourceCallback = tester
        .widget<BusyMarkSourceEditor>(find.byType(BusyMarkSourceEditor))
        .onChanged;
    controller.updateActiveEditorMode(DocumentViewModePreference.editor);
    await tester.pump(const Duration(milliseconds: 300));
    final firstWysiwyg = tester.widget<BusyMarkWysiwygEditor>(
      find.byType(BusyMarkWysiwygEditor),
    );

    await tester.runAsync(controller.createMarkdownFile);
    await tester.runAsync(() async {
      controller.updateActiveText(source);
    });
    await tester.runAsync(() => controller.validateActive());
    await tester.pump(const Duration(milliseconds: 500));
    final secondState = container.read(workspaceControllerProvider);
    final secondWysiwyg = tester.widget<BusyMarkWysiwygEditor>(
      find.byType(BusyMarkWysiwygEditor),
    );
    expect(secondState.activeBuffer?.id, isNot(untitledId));
    expect(secondWysiwyg.documentId, secondState.activeBuffer?.id);
    expect(firstWysiwyg.documentId, untitledId);
    expect(identical(firstWysiwyg.document, secondWysiwyg.document), isFalse);

    staleSourceCallback('# stale callback\n', '');
    expect(container.read(workspaceControllerProvider).activeText, source);
  });

  for (final nativeHostAvailable in [false, true]) {
    testWidgets(
      'Table of Contents creates from selection and exposes nested Writerside actions${nativeHostAvailable ? ' with an available native host' : ''}',
      (tester) async {
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
            .setMockMethodCallHandler(
              yaruWindowEventsChannel,
              (_) async => null,
            );
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
  <toc-element ref="loose.md" in="guide" toc-title="Ref entry"/>
  <toc-element topic="shared.md" origin="shared-docs" toc-title="Origin entry"/>
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
        File(
          p.join(root.path, 'topics', 'api.md'),
        ).writeAsStringSync('# API\n');
        final sharedModule = Directory(p.join(root.path, 'shared'))
          ..createSync();
        File(p.join(sharedModule.path, 'writerside.cfg')).writeAsStringSync('''
<ihp version="2.0">
  <module name="shared-docs"/>
  <topics dir="."/>
  <instance src="shared.tree"/>
</ihp>
''');
        File(p.join(sharedModule.path, 'shared.tree')).writeAsStringSync('''
<instance-profile id="shared" name="Shared" start-page="shared.md">
  <toc-element topic="shared.md"/>
</instance-profile>
''');
        File(
          p.join(sharedModule.path, 'shared.md'),
        ).writeAsStringSync('# Shared\n');
        final workspace = (await tester.runAsync(
          () => const WorkspaceService().openPath(root.path),
        ))!;
        final workspaceState = WorkspaceState(
          workspace: workspace,
          activeText: '# Nested\n',
        );
        final controller = _MutableWorkspaceController(workspaceState);
        final nativeCalls = <MethodCall>[];
        if (nativeHostAvailable) {
          const channel = MethodChannel(nativeWritersideDialogChannelName);
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            channel,
            (call) async {
              if (call.method != 'showCreateTopic') {
                throw MissingPluginException();
              }
              nativeCalls.add(call);
              return null;
            },
          );
          addTearDown(
            () => tester.binding.defaultBinaryMessenger
                .setMockMethodCallHandler(channel, null),
          );
        }
        Future<void> acceptCreation() async {
          expect(find.byType(BusyMarkModalEditorScaffold), findsOneWidget);
          expect(find.byType(Dialog), findsOneWidget);
          expect(nativeCalls, isEmpty);
          await tester.tap(find.text(l10n.tocOk));
          await tester.pumpAndSettle();
        }

        final container = ProviderContainer(
          overrides: [
            ..._smokeAccentOverrides,
            linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
            localSettingsStoreProvider.overrideWithValue(
              _MemorySettingsStore(),
            ),
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
              (widget is BusyMarkPopupMenuItem<Object?> &&
                  widget.label == label) ||
              (widget is MenuItemButton &&
                  widget.child is Text &&
                  (widget.child! as Text).data == label) ||
              (widget is SubmenuButton &&
                  widget.child is Text &&
                  (widget.child! as Text).data == label),
        );

        await openPopup(find.byTooltip(l10n.sidebarViewMenu));
        await tester.tap(find.text(l10n.files));
        await tester.pumpAndSettle();
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
        expect(find.text(l10n.delete), findsOneWidget);
        expect(find.text(l10n.tocSafeDelete), findsOneWidget);
        final mandatorySafeDelete = tester.widget<BusyMarkCheckbox>(
          find.descendant(
            of: find.widgetWithText(BusyMarkActionRow, l10n.tocSafeDelete),
            matching: find.byType(BusyMarkCheckbox),
          ),
        );
        expect(mandatorySafeDelete.value, isTrue);
        expect(mandatorySafeDelete.onChanged, isNull);
        expect(find.text(l10n.updateUsagesAutomatically), findsOneWidget);
        expect(find.text(l10n.reviewUsages), findsOneWidget);
        await tester.tap(find.text(l10n.cancel));
        await tester.pump(const Duration(milliseconds: 200));

        await openPopup(find.text('target.md'), buttons: kSecondaryButton);
        expect(popupMenuItem(l10n.tocRefactorMenu), findsOneWidget);
        await tester.tap(popupMenuItem(l10n.tocRefactorMenu));
        await tester.pumpAndSettle();
        expect(popupMenuItem(l10n.tocSafeDelete), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        await openPopup(find.byTooltip(l10n.sidebarViewMenu));
        await tester.tap(find.text(l10n.toc));
        await tester.pumpAndSettle();

        final instanceSelector = find.byKey(
          const ValueKey('writerside-instance-selector'),
        );
        expect(instanceSelector, findsOneWidget);
        final instanceSelectorTrigger = find.byKey(
          const ValueKey('writerside-instance-selector-trigger'),
        );
        expect(instanceSelectorTrigger, findsOneWidget);
        expect(
          find.descendant(
            of: instanceSelector,
            matching: find.byType(FilledButton),
          ),
          findsNothing,
        );
        final instanceSelectorSurface = find.descendant(
          of: instanceSelectorTrigger,
          matching: find.byType(Material),
        );
        final instanceSelectorInkWell = find.descendant(
          of: instanceSelectorTrigger,
          matching: find.byType(InkWell),
        );
        expect(instanceSelectorSurface, findsOneWidget);
        expect(instanceSelectorInkWell, findsOneWidget);
        expect(
          tester.widget<Material>(instanceSelectorSurface).color,
          BusyMarkLinuxPalette.transparent,
        );
        final instanceSelectorRect = tester.getRect(instanceSelectorTrigger);
        final tocHeaderRowRect = tester.getRect(
          find.byKey(const ValueKey('workspace-sidebar-first-content')),
        );
        final firstTocRow = find.byKey(
          const ValueKey('workspace-sidebar-toc-row-0'),
        );
        final firstTocRowRect = tester.getRect(firstTocRow);
        final firstTocRowSurface = find.descendant(
          of: firstTocRow,
          matching: find.byType(Material),
        );
        final firstTocRowInkWell = find.descendant(
          of: firstTocRow,
          matching: find.byType(InkWell),
        );
        expect(firstTocRowSurface, findsOneWidget);
        expect(firstTocRowInkWell, findsOneWidget);
        expect(
          tester.widget<Material>(instanceSelectorSurface).borderRadius,
          tester.widget<Material>(firstTocRowSurface).borderRadius,
        );
        expect(
          tester.widget<InkWell>(instanceSelectorInkWell).hoverColor,
          tester.widget<InkWell>(firstTocRowInkWell).hoverColor,
        );
        final primaryIconRect = tester.getRect(
          find.descendant(
            of: find.byKey(const ValueKey('workspace-sidebar-primary-label')),
            matching: find.byType(Icon),
          ),
        );
        final instanceIconRect = tester.getRect(
          find.descendant(
            of: instanceSelector,
            matching: find.byIcon(BusyMarkGlyphs.tree),
          ),
        );
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('workspace-sidebar-toc-row-0')),
            matching: find.byIcon(BusyMarkGlyphs.document),
          ),
          findsNothing,
        );
        expect(instanceIconRect.left, primaryIconRect.left);
        expect(tocHeaderRowRect.left, firstTocRowRect.left);
        expect(tocHeaderRowRect.right, firstTocRowRect.right);
        expect(instanceSelectorRect.left, tocHeaderRowRect.left);
        expect(instanceSelectorRect.right, lessThan(tocHeaderRowRect.right));
        final primaryMenuRect = tester.getRect(
          find.byTooltip(l10n.sidebarViewMenu),
        );
        final tocMenuRect = tester.getRect(
          find.descendant(
            of: find.byKey(const ValueKey('workspace-sidebar-toc-menu')),
            matching: find.byType(IconButton),
          ),
        );
        expect(instanceSelectorRect.height, tocMenuRect.height);
        expect(instanceSelectorRect.center.dy, tocMenuRect.center.dy);
        expect(instanceSelectorRect.height, firstTocRowRect.height);
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        addTearDown(mouse.removePointer);
        await mouse.addPointer(location: Offset.zero);
        await mouse.moveTo(
          tester.getCenter(
            find.byKey(const ValueKey('workspace-sidebar-toc-row-0')),
          ),
        );
        await tester.pump();
        final tocRowMenuRect = tester.getRect(
          find.descendant(
            of: find.byKey(const ValueKey('workspace-sidebar-toc-row-0')),
            matching: find.byType(IconButton),
          ),
        );
        expect(tocMenuRect.center.dx, primaryMenuRect.center.dx);
        expect(tocRowMenuRect.center.dx, primaryMenuRect.center.dx);
        await mouse.moveTo(Offset.zero);
        await tester.pump();
        expect(find.text(l10n.instances), findsNothing);
        expect(
          find.byKey(const ValueKey('writerside-instance-guide')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('writerside-instance-api')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('writerside-module-selector')),
          findsOneWidget,
        );
        await openPopup(
          find.byKey(const ValueKey('writerside-module-selector')),
        );
        await tester.tap(find.text('shared-docs'));
        await tester.pump(const Duration(milliseconds: 200));
        expect(controller.selectedWritersideModuleId, 'shared-docs');
        final guideIcon = tester.widget<Icon>(
          find.descendant(
            of: instanceSelector,
            matching: find.byIcon(BusyMarkGlyphs.tree),
          ),
        );
        await openPopup(instanceSelector);
        final apiInstance = find.byWidgetPredicate(
          (widget) =>
              widget is BusyMarkPopupMenuItem<String> &&
              widget.label.contains('API Reference'),
        );
        final guideInstance = find.byWidgetPredicate(
          (widget) =>
              widget is BusyMarkPopupMenuItem<String> &&
              widget.label.contains('Guide'),
        );
        expect(apiInstance, findsOneWidget);
        expect(guideInstance, findsOneWidget);
        final guideOptionIcon = tester.widget<Icon>(
          find.descendant(
            of: guideInstance,
            matching: find.byIcon(BusyMarkGlyphs.tree),
          ),
        );
        final apiOptionIcon = tester.widget<Icon>(
          find.descendant(
            of: apiInstance,
            matching: find.byIcon(BusyMarkGlyphs.tree),
          ),
        );
        expect(guideOptionIcon.color, guideIcon.color);
        expect(apiOptionIcon.color, isNotNull);
        expect(apiOptionIcon.color, isNot(guideOptionIcon.color));
        await tester.tap(apiInstance);
        await tester.pump(const Duration(milliseconds: 200));
        expect(controller.selectedWritersideInstanceId, 'api');
        final apiIcon = tester.widget<Icon>(
          find.descendant(
            of: instanceSelector,
            matching: find.byIcon(BusyMarkGlyphs.tree),
          ),
        );
        expect(guideIcon.color, isNotNull);
        expect(apiIcon.color, isNotNull);
        expect(guideIcon.color, isNot(apiIcon.color));
        await openPopup(instanceSelector);
        expect(guideInstance, findsOneWidget);
        await tester.tap(guideInstance);
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('Nested entry'), findsOneWidget);
        expect(find.byTooltip(l10n.newTopic), findsOneWidget);
        expect(find.byTooltip(l10n.tocActions), findsOneWidget);
        expect(find.byTooltip(l10n.tocSynchronize), findsNothing);
        expect(find.byTooltip(l10n.newChildTopic), findsNothing);
        final tocMenuButton = find.descendant(
          of: find.byKey(const ValueKey('workspace-sidebar-toc-menu')),
          matching: find.byType(IconButton),
        );
        expect(tester.widget<IconButton>(tocMenuButton).isSelected, isFalse);
        await openPopup(find.byTooltip(l10n.tocActions));
        expect(tester.widget<IconButton>(tocMenuButton).isSelected, isFalse);
        expect(find.text(l10n.newTopic), findsNothing);
        final synchronizeItem = find.byWidgetPredicate(
          (widget) =>
              widget is BusyMarkPopupMenuItem<Object?> &&
              widget.label == l10n.tocSynchronize,
        );
        expect(synchronizeItem, findsOneWidget);
        expect(
          tester
              .widget<BusyMarkPopupMenuItem<Object?>>(synchronizeItem)
              .enabled,
          isTrue,
        );
        expect(find.text(l10n.newInstance), findsOneWidget);
        expect(find.text(l10n.newTocLibrary), findsOneWidget);
        expect(find.text(l10n.editInstance), findsOneWidget);
        expect(find.text(l10n.openTocFile), findsOneWidget);
        expect(find.text(l10n.export), findsNothing);
        final tocActionSequence = find
            .byWidgetPredicate(
              (widget) =>
                  widget is BusyMarkPopupMenuItem<Object?> ||
                  widget is PopupMenuDivider,
            )
            .evaluate()
            .map((element) {
              final widget = element.widget;
              return widget is BusyMarkPopupMenuItem<Object?>
                  ? widget.label
                  : '<divider>';
            })
            .toList();
        expect(tocActionSequence, [
          l10n.tocSynchronize,
          '<divider>',
          l10n.newInstance,
          l10n.newTocLibrary,
          '<divider>',
          l10n.editInstance,
          l10n.openTocFile,
        ]);
        await tester.tap(find.text(l10n.editInstance));
        await tester.pumpAndSettle();
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
        await tester.pumpAndSettle();

        await openPopup(find.byTooltip(l10n.tocActions));
        await tester.tap(find.text(l10n.newInstance));
        await tester.pumpAndSettle();
        expect(find.text(l10n.createInstance), findsOneWidget);
        expect(find.text(l10n.emptyInstance), findsOneWidget);
        await tester.tap(find.text(l10n.emptyInstance));
        await tester.pumpAndSettle();
        expect(find.text(l10n.markdownFiles), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.text(l10n.instanceAppearance), findsOneWidget);
        await tester.tap(find.text(l10n.cancel));
        await tester.pumpAndSettle();

        await openPopup(find.byTooltip(l10n.newTopic));
        await tester.tap(find.text(l10n.tocEmptyMdTopic));
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        expect(find.byType(BusyMarkModalEditorScaffold), findsNothing);
        expect(controller.createdTopicRequest, isNull);

        await openPopup(find.byTooltip(l10n.newTopic));
        expect(find.text(l10n.addLocalMarkdownFiles), findsOneWidget);
        expect(find.text(l10n.tocLinkTopicFiles), findsOneWidget);
        await tester.tap(find.text(l10n.tocEmptyMdTopic));
        await tester.pumpAndSettle();

        expect(find.text(l10n.newTopic), findsOneWidget);
        expect(find.byType(BusyMarkModalEditorScaffold), findsOneWidget);
        expect(find.byType(BusyMarkModalEditorSurface), findsOneWidget);
        expect(
          tester.getRect(find.byType(Dialog)).bottom -
              tester.getRect(find.byType(BusyMarkGroupedList)).bottom,
          greaterThanOrEqualTo(BusyMarkSpacing.lg),
        );
        expect(find.byType(BusyMarkEditorHeader), findsOneWidget);
        expect(find.byType(Dialog), findsOneWidget);
        expect(find.byType(BusyMarkDialogShell), findsNothing);
        expect(
          tester
              .widget<BusyMarkGroupedList>(find.byType(BusyMarkGroupedList))
              .filled,
          isTrue,
        );
        expect(nativeCalls, isEmpty);
        expect(
          find.descendant(
            of: find.byType(BusyMarkModalEditorScaffold),
            matching: find.byType(BusyMarkGroupedTextEntry),
          ),
          findsNWidgets(2),
        );
        expect(find.text(l10n.topicPlacement), findsNothing);

        final entries = find.byType(BusyMarkGroupedTextEntry);
        final title = entries.at(0);
        final name = entries.at(1);
        expect(
          tester.widget<BusyMarkGroupedTextEntry>(title).controller!.text,
          l10n.defaultNewTopicTitle,
        );
        await tester.enterText(title, 'Résumé 世界');
        await tester.pump();
        expect(
          tester.widget<BusyMarkGroupedTextEntry>(name).controller!.text,
          '${slugForHeading('Résumé 世界')}.md',
        );
        await tester.enterText(title, 'Hello World');
        await tester.pump();
        expect(
          tester.widget<BusyMarkGroupedTextEntry>(name).controller!.text,
          'hello-world.md',
        );
        await tester.enterText(name, 'manual');
        await tester.enterText(title, 'Changed title');
        await tester.pump();
        expect(
          tester.widget<BusyMarkGroupedTextEntry>(name).controller!.text,
          'manual',
        );
        for (final invalid in [
          '',
          '../unsafe.md',
          'CON.md',
          'parent.md',
          'wrong.topic',
        ]) {
          await tester.enterText(name, invalid);
          await tester.pump();
          expect(
            tester
                .widget<ElevatedButton>(
                  find.byWidgetPredicate(
                    (widget) =>
                        widget is ElevatedButton &&
                        widget.child is Text &&
                        (widget.child! as Text).data == l10n.tocOk,
                  ),
                )
                .onPressed,
            isNull,
          );
        }
        await tester.enterText(name, 'root-topic');
        await tester.enterText(title, ' ');
        await tester.pump();
        expect(find.text(l10n.topicTitleRequired), findsOneWidget);
        await tester.enterText(title, 'Created Root');
        await tester.pump();
        final pendingCreation = Completer<bool>();
        controller.createTopic = (_) => pendingCreation.future;
        final submissionsBeforeEnter = controller.createTopicCount;
        await tester.tap(title);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(controller.createTopicCount, submissionsBeforeEnter);
        final filenameEditor = tester.widget<EditableText>(
          find.descendant(of: name, matching: find.byType(EditableText)),
        );
        expect(filenameEditor.focusNode.hasFocus, isTrue);
        await tester.tap(title);
        await tester.pump();
        await tester.testTextInput.receiveAction(TextInputAction.next);
        await tester.pump();
        expect(controller.createTopicCount, submissionsBeforeEnter);
        expect(filenameEditor.focusNode.hasFocus, isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(controller.createTopicCount, submissionsBeforeEnter + 1);
        expect(
          tester
              .widget<BusyMarkModalEditorScaffold>(
                find.byType(BusyMarkModalEditorScaffold),
              )
              .cancelEnabled,
          isFalse,
        );
        expect(tester.widget<BusyMarkGroupedTextEntry>(title).enabled, isFalse);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pump();
        expect(find.byType(BusyMarkModalEditorScaffold), findsOneWidget);
        final count = controller.createTopicCount;
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();
        expect(controller.createTopicCount, count);
        pendingCreation.complete(false);
        await tester.pumpAndSettle();
        expect(find.text(l10n.createWritersideTopicFailed), findsOneWidget);
        expect(
          tester.widget<BusyMarkGroupedTextEntry>(title).controller!.text,
          'Created Root',
        );
        expect(
          tester.widget<BusyMarkGroupedTextEntry>(name).controller!.text,
          'root-topic',
        );
        controller.createTopic = null;

        await acceptCreation();

        expect(controller.createdTopicRequest, isNotNull);
        expect(
          controller.createdTopicRequest!.placement,
          WritersideTopicCreatePlacement.root,
        );
        expect(controller.createdTopicRequest!.referenceTocPath, isNull);
        expect(controller.createdTopicRequest!.referenceTopic, isNull);
        expect(
          controller.createdTopicTreePath,
          p.join(root.path, 'guide.tree'),
        );

        await openPopup(instanceSelector);
        await tester.tap(apiInstance);
        await tester.pumpAndSettle();
        expect(find.text('API'), findsOneWidget);

        await openPopup(find.byTooltip(l10n.newTopic));
        await tester.tap(find.text(l10n.tocEmptyMdTopic));
        await tester.pumpAndSettle();
        await acceptCreation();
        expect(controller.createdTopicTreePath, p.join(root.path, 'api.tree'));

        await openPopup(instanceSelector);
        await tester.tap(guideInstance);
        await tester.pumpAndSettle();

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
        expect(find.text(l10n.setRedirectTo), findsOneWidget);
        expect(find.text(l10n.updateUsagesAutomatically), findsOneWidget);
        expect(find.text(l10n.topicUsagesCount(1)), findsOneWidget);
        expect(find.byType(Checkbox), findsNothing);
        expect(find.byType(CheckboxListTile), findsNothing);
        final removalControls = tester
            .widgetList<BusyMarkCheckbox>(find.byType(BusyMarkCheckbox))
            .toList();
        expect(removalControls, hasLength(2));
        removalControls.last.onChanged!(false);
        await tester.pump();
        expect(
          tester
              .widgetList<BusyMarkCheckbox>(find.byType(BusyMarkCheckbox))
              .last
              .value,
          isFalse,
        );
        tester
            .widgetList<BusyMarkCheckbox>(find.byType(BusyMarkCheckbox))
            .last
            .onChanged!(true);
        await tester.pump();
        expect(find.text(l10n.reviewUsages), findsOneWidget);
        expect(find.text(l10n.removeAction), findsOneWidget);
        await tester.tap(find.text(l10n.reviewUsages));
        await tester.pumpAndSettle();
        expect(find.text(l10n.doRefactor), findsOneWidget);
        await tester.tap(find.text(l10n.doRefactor));
        await tester.pumpAndSettle();
        expect(controller.appliedTopicRemovalCount, 1);
        expect(find.text(l10n.removeTocElement), findsNothing);

        for (final label in ['Ref entry', 'Origin entry']) {
          await tester.tap(find.text(label));
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
          await tester.pumpAndSettle();
        }

        await tester.pumpAndSettle();
        await openPopup(find.text('Nested entry'), buttons: kSecondaryButton);

        for (final label in [
          l10n.copy,
          l10n.aiRefineWithAi,
          l10n.newSiblingTopic,
          l10n.newChildTopic,
          l10n.tocDuplicate,
          l10n.tocCopySpecial,
          l10n.tocEditTitleAction,
          l10n.renameTopicFile,
          l10n.cut,
          l10n.pasteAfterTopic,
          l10n.pasteAsChildTopic,
          l10n.tocRemoveElementAction,
          l10n.tocSetHomePage,
          l10n.tocGoToElement('guide.tree'),
          l10n.copyName,
          l10n.copyPath,
          l10n.openInFiles,
          l10n.fileHistory,
        ]) {
          expect(popupMenuItem(label), findsOneWidget);
        }
        expect(popupMenuItem(l10n.addToGit), findsNothing);
        expect(popupMenuItem(l10n.safeDeleteTopicFile), findsNothing);
        expect(popupMenuItem(l10n.delete), findsNothing);
        expect(popupMenuItem('Preview Topic'), findsNothing);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
        await tester.pumpAndSettle();
        expect(popupMenuItem(l10n.openInFiles), findsOneWidget);
        expect(popupMenuItem(l10n.addToGit), findsNothing);
        expect(popupMenuItem(l10n.fileHistory), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        await openPopup(find.text('Nested entry'), buttons: kSecondaryButton);
        await tester.tap(find.text(l10n.newChildTopic));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.tocEmptyXmlTopic));
        await tester.pumpAndSettle();
        expect(find.text(l10n.newTopic), findsOneWidget);
        await acceptCreation();
        expect(
          controller.createdTopicRequest!.placement,
          WritersideTopicCreatePlacement.child,
        );
        expect(controller.createdTopicRequest!.referenceTocPath, [0, 0]);
        expect(controller.createdTopicRequest!.referenceTopic, 'nested.md');
        expect(controller.createdTopicRequest!.referenceTocIdentity, isNotNull);

        await openPopup(find.text('Nested entry'), buttons: kSecondaryButton);
        await tester.tap(find.text(l10n.newSiblingTopic));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.tocEmptyMdTopic));
        await tester.pumpAndSettle();
        expect(find.text(l10n.newTopic), findsOneWidget);
        await acceptCreation();
        expect(
          controller.createdTopicRequest!.placement,
          WritersideTopicCreatePlacement.sibling,
        );
        expect(controller.createdTopicRequest!.referenceTocPath, [0, 0]);

        // Exercise actual row drag recognizers, including the pointer-relative
        // child/before zones and the selection captured for a multi-item drag.
        Future<void> dragBetween(Finder source, Offset destination) async {
          final gesture = await tester.startGesture(
            tester.getCenter(source),
            kind: PointerDeviceKind.mouse,
          );
          await gesture.moveBy(const Offset(22, 0));
          await tester.pump();
          await gesture.moveTo(destination);
          await tester.pump(const Duration(milliseconds: 700));
          await gesture.up();
          await tester.pumpAndSettle();
        }

        await dragBetween(
          find.text('Loose'),
          tester.getCenter(find.text('Target')),
        );
        expect(controller.dragRequest!.sources.single.sourcePath, [1]);
        expect(controller.dragRequest!.referencePath, [2]);
        expect(
          controller.dragRequest!.placement,
          WritersideTopicCreatePlacement.child,
        );
        controller.dragRequest = null;
        await dragBetween(
          find.text('Parent'),
          tester.getCenter(find.text('Nested entry')),
        );
        expect(
          controller.dragRequest,
          isNull,
          reason: 'Ancestor cannot enter its descendant',
        );
        await openPopup(find.text('Target'), buttons: kSecondaryButton);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.tap(find.text('Loose'));
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pump(kDoubleTapTimeout);
        await tester.pumpAndSettle();
        final parentRow = find.byKey(
          const ValueKey('workspace-sidebar-toc-row-0'),
        );
        await tester.tap(
          find.descendant(
            of: parentRow,
            matching: find.byType(AnimatedRotation),
          ),
        );
        await tester.pump(kDoubleTapTimeout);
        await tester.pumpAndSettle();
        expect(find.text('Nested entry'), findsNothing);
        await dragBetween(find.text('Loose'), tester.getCenter(parentRow));
        expect(
          find.text('Nested entry'),
          findsOneWidget,
          reason: 'Hover expands a collapsed destination during the drag',
        );
        expect(
          controller.dragRequest!.placement,
          WritersideTopicCreatePlacement.child,
        );
        await openPopup(find.text('Target'), buttons: kSecondaryButton);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.tap(find.text('Loose'));
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pump(kDoubleTapTimeout);
        await tester.pumpAndSettle();
        await dragBetween(
          find.text('Loose'),
          tester.getTopLeft(parentRow) + const Offset(80, 3),
        );
        expect(
          controller.dragRequest!.sources.map((entry) => entry.sourcePath),
          [
            [1],
            [2],
          ],
        );
        expect(controller.dragRequest!.referencePath, [0]);
        expect(controller.dragRequest!.beforeReference, isTrue);
        await openPopup(find.text('Nested entry'), buttons: kSecondaryButton);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.tap(
          find.byKey(const ValueKey('workspace-sidebar-toc-row-1')),
        );
        await tester.tap(
          find.byKey(const ValueKey('workspace-sidebar-toc-row-2')),
        );
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pump();
        await openPopup(find.text('Target'), buttons: kSecondaryButton);
        for (final label in [
          l10n.copy,
          l10n.cut,
          l10n.aiRefineWithAi,
          l10n.removeTocElements,
        ]) {
          expect(popupMenuItem(label), findsOneWidget);
        }
        expect(popupMenuItem(l10n.delete), findsNothing);
        expect(popupMenuItem(l10n.safeDeleteTopicFile), findsNothing);
        expect(find.text(l10n.newSiblingTopic), findsNothing);
        expect(find.text(l10n.copyName), findsNothing);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.tap(
          find.byKey(const ValueKey('workspace-sidebar-toc-row-1')),
        );
        await tester.tap(
          find.byKey(const ValueKey('workspace-sidebar-toc-row-1')),
        );
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.tap(
          find.byKey(const ValueKey('workspace-sidebar-toc-row-2')),
        );
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.pump();
        await openPopup(find.text('Target'), buttons: kSecondaryButton);
        expect(find.text(l10n.aiRefineWithAi), findsOneWidget);
        expect(find.text(l10n.newSiblingTopic), findsNothing);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        await openPopup(find.text('Nested entry'), buttons: kSecondaryButton);

        await tester.ensureVisible(find.text(l10n.cut));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text(l10n.cut));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.cut));
        await tester.pumpAndSettle();
        await openPopup(find.text('Parent'), buttons: kSecondaryButton);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is MenuItemButton &&
                widget.child is Text &&
                (widget.child! as Text).data == l10n.pasteAfterTopic &&
                widget.onPressed != null,
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
        await tester.pumpAndSettle();

        await openPopup(find.text('Parent'), buttons: kSecondaryButton);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is MenuItemButton &&
                widget.child is Text &&
                (widget.child! as Text).data == l10n.pasteAfterTopic &&
                widget.onPressed == null,
          ),
          findsOneWidget,
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        await openPopup(find.text('Loose'), buttons: kSecondaryButton);
        await tester.ensureVisible(find.text(l10n.cut));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.cut));
        await tester.pumpAndSettle();
        await openPopup(find.text('Target'), buttons: kSecondaryButton);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is MenuItemButton &&
                widget.child is Text &&
                (widget.child! as Text).data == l10n.pasteAsChildTopic &&
                widget.onPressed != null,
          ),
          findsOneWidget,
        );
        await tester.ensureVisible(find.text(l10n.pasteAsChildTopic));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.pasteAsChildTopic));
        await tester.pumpAndSettle();

        expect(
          controller.movedTopicPlacement,
          WritersideTopicCreatePlacement.child,
        );
        expect(controller.movedTopicSourcePath, [1]);
        expect(controller.movedTopicReferencePath, [2]);
        expect(find.text('Loose'), findsOneWidget);
        final movedRoots = controller
            .state
            .workspace!
            .writersideModule!
            .instances
            .first
            .tocRoots;
        final targetNode = movedRoots.singleWhere(
          (node) => node.topicFileName == 'target.md',
        );
        expect(targetNode.children.single.topicFileName, 'loose.md');

        await openPopup(find.byTooltip(l10n.mainMenu));
        final mainMenuExportItem = find.byWidgetPredicate(
          (widget) =>
              widget is BusyMarkPopupMenuItem<Object?> &&
              widget.label == l10n.export,
        );
        expect(mainMenuExportItem, findsOneWidget);
        expect(
          tester
              .widget<BusyMarkPopupMenuItem<Object?>>(mainMenuExportItem)
              .enabled,
          isTrue,
        );
        await tester.tap(mainMenuExportItem);
        for (var index = 0; index < 20; index++) {
          await tester.pump(const Duration(milliseconds: 100));
          if (find.byType(BusyMarkModalEditorSurface).evaluate().isNotEmpty) {
            break;
          }
        }
        expect(find.byType(BusyMarkModalEditorSurface), findsOneWidget);
        expect(find.byType(BusyMarkModalEditorScaffold), findsOneWidget);
        expect(find.byType(BusyMarkComboRow<ExportFormat>), findsOneWidget);
        expect(find.byType(SegmentedButton<ExportFormat>), findsNothing);
        expect(find.text(l10n.pdfPageSize), findsOneWidget);
        expect(find.text(l10n.pdfIncludePageNumbers), findsOneWidget);
        await tester.tap(find.text(l10n.cancel));
        await tester.pumpAndSettle();

        await openPopup(find.byTooltip(l10n.tocActions));
        final exportItem = find.byWidgetPredicate(
          (widget) =>
              widget is BusyMarkPopupMenuItem<Object?> &&
              widget.label == l10n.export,
        );
        expect(find.text(l10n.tocSynchronize), findsOneWidget);
        expect(find.text(l10n.newInstance), findsOneWidget);
        expect(find.text(l10n.newTocLibrary), findsOneWidget);
        expect(find.text(l10n.editInstance), findsOneWidget);
        expect(find.text(l10n.openTocFile), findsOneWidget);
        expect(exportItem, findsNothing);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyE);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        for (var index = 0; index < 20; index++) {
          await tester.pump(const Duration(milliseconds: 100));
          if (find.byType(BusyMarkModalEditorSurface).evaluate().isNotEmpty) {
            break;
          }
        }
        expect(find.byType(BusyMarkModalEditorSurface), findsOneWidget);
        final formatRow = tester.widget<BusyMarkComboRow<ExportFormat>>(
          find.byType(BusyMarkComboRow<ExportFormat>),
        );
        expect(formatRow.title, l10n.exportFormat);
        expect(formatRow.values, ExportFormat.values);
        expect(formatRow.selected, ExportFormat.pdf);
        await tester.tap(find.text(l10n.cancel));
        await tester.pumpAndSettle();
        await openPopup(instanceSelectorTrigger, buttons: kSecondaryButton);
        await tester.tap(find.text(l10n.openTocFile));
        await tester.pumpAndSettle();
        expect(controller.openedFilePath, p.join(root.path, 'guide.tree'));
        expect(
          controller.requestedEditorMode,
          DocumentViewModePreference.source,
        );

        File(p.join(root.path, 'guide.tree')).writeAsStringSync(
          '<instance-profile id="guide" name="Guide" start-page="nested.md">'
          '<toc-element toc-title="Drag source"/>'
          '${[for (var i = 0; i < 40; i++) '<toc-element toc-title="Long $i"/>'].join()}'
          '<toc-element toc-title="Distant destination"/>'
          '</instance-profile>',
        );
        controller.replaceWorkspace(
          (await tester.runAsync(
            () => const WorkspaceService().openPath(root.path),
          ))!,
        );
        await tester.pumpAndSettle();
        controller.openedFilePath = null;
        await tester.tap(find.text('Drag source'));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.text('Drag source'));
        await tester.pumpAndSettle();
        expect(
          controller.openedFilePath,
          p.join(root.path, 'guide.tree'),
          reason: 'An empty-group double-click opens its source tree',
        );
        final viewport = tester.getRect(
          find.ancestor(
            of: find.text('Drag source'),
            matching: find.byType(ScrollablePositionedList),
          ),
        );
        final edge = Offset(viewport.center.dx, viewport.bottom - 16);
        final distant = find.text('Distant destination').hitTestable();
        expect(distant, findsNothing);
        final scrollDrag = await tester.startGesture(
          tester.getCenter(find.text('Drag source')),
          kind: PointerDeviceKind.mouse,
        );
        await scrollDrag.moveBy(const Offset(22, 0));
        await tester.pump();
        for (var step = 0; step < 60 && distant.evaluate().isEmpty; step++) {
          await scrollDrag.moveTo(edge + Offset(step.isEven ? 0 : 1, 0));
          await tester.pump(const Duration(milliseconds: 140));
        }
        expect(
          distant,
          findsOneWidget,
          reason:
              'Edge autoscroll reaches a destination outside the initial viewport',
        );
        await scrollDrag.moveTo(tester.getCenter(distant));
        await tester.pump(const Duration(milliseconds: 20));
        await scrollDrag.up();
        await tester.pumpAndSettle();
        expect(controller.dragRequest!.sources.single.sourcePath, [0]);
        expect(controller.dragRequest!.referencePath, [41]);
      },
    );
  }

  for (final longPath in [false, true]) {
    testWidgets(
      'Writerside topic rename uses Preview, Do Refactor, and shared entry points'
      '${longPath ? ' with long paths' : ''}',
      (tester) async {
        const yaruWindowChannel = MethodChannel('yaru_window');
        const yaruWindowEventsChannel = MethodChannel('yaru_window/events');
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(yaruWindowChannel, (call) async {
              if (call.method == 'state') return <String, Object?>{};
              return null;
            });
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              yaruWindowEventsChannel,
              (_) async => null,
            );
        addTearDown(() {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            ..setMockMethodCallHandler(yaruWindowChannel, null)
            ..setMockMethodCallHandler(yaruWindowEventsChannel, null);
        });
        final binding = TestWidgetsFlutterBinding.ensureInitialized();
        binding.platformDispatcher.defaultRouteNameTestValue = '/workspace';
        await binding.setSurfaceSize(const Size(1440, 900));
        addTearDown(() async {
          binding.platformDispatcher.defaultRouteNameTestValue = '/';
          await binding.setSurfaceSize(null);
        });
        final temporary = Directory.systemTemp.createTempSync(
          'busymark-topic-rename-ui-',
        );
        final root = longPath
            ? (Directory(
                p.joinAll([
                  temporary.path,
                  for (var index = 0; index < 4; index++)
                    'long-project-segment-$index-with-readable-project-details',
                ]),
              )..createSync(recursive: true))
            : temporary;
        addTearDown(() {
          if (temporary.existsSync()) temporary.deleteSync(recursive: true);
        });
        final topics = Directory(p.join(root.path, 'topics'))..createSync();
        final configPath = p.join(root.path, 'writerside.cfg');
        final treePath = p.join(root.path, 'guide.tree');
        final topicPath = p.join(topics.path, 'guide.topic');
        final linksPath = p.join(topics.path, 'links.md');
        File(configPath).writeAsStringSync('''
<ihp version="2.0"><topics dir="topics"/><instance src="guide.tree"/></ihp>
''');
        File(treePath).writeAsStringSync('''
<instance-profile id="guide" start-page="guide.topic">
  <toc-element topic="guide.topic"/>
  <toc-element topic="links.md"/>
</instance-profile>
''');
        const topicSource =
            '<topic id="guide" title="Guide">'
            '<chapter id="install" title="Install"/>'
            '</topic>\n';
        File(topicPath).writeAsStringSync(topicSource);
        File(linksPath).writeAsStringSync('# Links\n\n[Guide](guide.topic)\n');
        final workspace = (await tester.runAsync(
          () => const WorkspaceService().openPath(root.path),
        ))!;
        final setupPlan = (await tester.runAsync(
          () => const WorkspaceService().prepareWritersideTopicRename(
            workspace,
            topicPath: topicPath,
            newFileName: 'setup.topic',
            topicModuleRoot: root.path,
          ),
        ))!;
        final controller =
            _MutableWorkspaceController(
                WorkspaceState(workspace: workspace, activeText: topicSource),
              )
              ..topicRenamePlans['setup.topic'] = setupPlan
              ..simulateTopicRename = true;
        final container = ProviderContainer(
          overrides: [
            ..._smokeAccentOverrides,
            linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
            localSettingsStoreProvider.overrideWithValue(
              _MemorySettingsStore(),
            ),
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
        for (var index = 0; index < 10; index++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        Future<void> openPopup(Finder anchor) async {
          await tester.tap(anchor, buttons: kSecondaryButton);
          await tester.pumpAndSettle();
        }

        Future<void> pressShiftF6() async {
          await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
          await tester.sendKeyDownEvent(LogicalKeyboardKey.f6);
          await tester.sendKeyUpEvent(LogicalKeyboardKey.f6);
          await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
          await tester.pumpAndSettle();
        }

        Future<void> enterRename(String fileName) async {
          final field = find.descendant(
            of: find.byType(BusyMarkDialogShell),
            matching: find.byType(EditableText),
          );
          expect(field, findsOneWidget);
          await tester.enterText(field, fileName);
          await tester.pump();
        }

        await tester.tap(find.byTooltip(l10n.sidebarViewMenu));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.toc));
        await tester.pumpAndSettle();
        final firstRow = find.byKey(
          const ValueKey('workspace-sidebar-toc-row-0'),
        );
        await tester.tap(firstRow);
        await tester.pump();

        await pressShiftF6();
        expect(find.text(l10n.rename), findsOneWidget);
        expect(find.text(l10n.preview), findsOneWidget);
        expect(find.text(l10n.tocRefactorMenu), findsOneWidget);
        await tester.tap(find.text(l10n.cancel));
        await tester.pumpAndSettle();
        expect(File(topicPath).readAsStringSync(), topicSource);

        await openPopup(firstRow);
        final renameMenuItem = find.text(l10n.renameTopicFile);
        expect(renameMenuItem, findsOneWidget);
        await tester.tap(renameMenuItem);
        await tester.pumpAndSettle();
        await enterRename('setup.topic');
        await tester.tap(find.text(l10n.preview));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(
          find.text(l10n.topicRenamePreviewTitle),
          findsOneWidget,
          reason:
              'prepared=${controller.topicRenamePrepareCount}, '
              'error=${controller.state.message?.error}',
        );
        expect(find.text(l10n.doRefactor), findsOneWidget);
        if (longPath) {
          final scrollable = find
              .descendant(
                of: find.byKey(const ValueKey('topic-rename-preview-scroll')),
                matching: find.byType(Scrollable),
              )
              .first;
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey('topic-rename-affected-files')),
            400,
            scrollable: scrollable,
          );
          await tester.pumpAndSettle();
        }
        expect(find.text('guide.topic → setup.topic'), findsOneWidget);
        expect(find.text('guide.tree'), findsOneWidget);
        expect(find.text('links.md'), findsOneWidget);
        expect(File(topicPath).readAsStringSync(), topicSource);
        expect(File(p.join(topics.path, 'setup.topic')).existsSync(), isFalse);

        if (longPath) {
          expect(tester.takeException(), isNull);
          await tester.ensureVisible(find.text('links.md'));
          await tester.pumpAndSettle();
          expect(find.text('links.md').hitTestable(), findsOneWidget);
          expect(find.text(l10n.doRefactor).hitTestable(), findsOneWidget);
          await tester.tap(find.text('links.md'));
          await tester.pumpAndSettle();
          final scrollable = find
              .descendant(
                of: find.byKey(const ValueKey('topic-rename-preview-scroll')),
                matching: find.byType(Scrollable),
              )
              .first;
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey('topic-rename-path-change')),
            -400,
            scrollable: scrollable,
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }

        controller.rejectTopicRename = true;
        await tester.tap(find.text(l10n.doRefactor));
        await tester.pump();
        expect(find.text(l10n.topicRenamePreviewTitle), findsOneWidget);
        expect(File(topicPath).readAsStringSync(), topicSource);
        expect(File(p.join(topics.path, 'setup.topic')).existsSync(), isFalse);

        controller.rejectTopicRename = false;
        controller.appliedTopicRenamePlan = null;
        controller.markWritersideProjectBufferDirty(
          path: linksPath,
          text: '# Links\n\nUnsaved after preview.\n',
          lastSavedText: File(linksPath).readAsStringSync(),
        );
        await tester.tap(find.text(l10n.doRefactor));
        await tester.pumpAndSettle();
        expect(find.text(l10n.topicRenamePreviewTitle), findsNothing);
        expect(controller.appliedTopicRenamePlan, isNull);
        expect(File(topicPath).readAsStringSync(), topicSource);
        expect(File(p.join(topics.path, 'setup.topic')).existsSync(), isFalse);

        controller.clearDocumentBuffersForTest();
        await openPopup(firstRow);
        await tester.tap(find.text(l10n.renameTopicFile));
        await tester.pumpAndSettle();
        await enterRename('setup.topic');
        await tester.tap(find.text(l10n.preview));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.text(l10n.doRefactor));
        await tester.pumpAndSettle();
        expect(controller.appliedTopicRenamePlan, same(setupPlan));
        expect(File(topicPath).readAsStringSync(), topicSource);
        expect(File(treePath).readAsStringSync(), contains('guide.topic'));
        expect(File(linksPath).readAsStringSync(), contains('(guide.topic)'));

        await tester.tap(find.byTooltip(l10n.sidebarViewMenu));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.files));
        await tester.pumpAndSettle();
        controller.appliedTopicRenamePlan = null;
        await openPopup(find.text('guide.topic').first);
        await tester.tap(find.text(l10n.renameTopicFile));
        await tester.pumpAndSettle();
        await enterRename('setup.topic');
        await tester.tap(find.text(l10n.tocRefactorMenu));
        await tester.pumpAndSettle();
        expect(controller.appliedTopicRenamePlan, same(setupPlan));

        await openPopup(find.text('guide.tree'));
        await tester.tap(find.text(l10n.rename));
        await tester.pumpAndSettle();
        expect(find.text(l10n.preview), findsNothing);
        expect(find.text(l10n.rename), findsWidgets);
        await tester.tap(find.text(l10n.cancel));
        await tester.pumpAndSettle();

        await openPopup(find.text('guide.topic').first);
        await tester.tap(find.text(l10n.renameTopicFile));
        await tester.pumpAndSettle();
        expect(find.text(l10n.preview), findsOneWidget);
        expect(find.text(l10n.tocRefactorMenu), findsOneWidget);
        await tester.tap(find.text(l10n.cancel));
        await tester.pumpAndSettle();

        final sourceField = find.descendant(
          of: find.byType(BusyMarkSourceEditor),
          matching: find.byType(TextField),
        );
        expect(sourceField, findsOneWidget);
        await tester.tap(sourceField);
        final sourceController = tester
            .widget<TextField>(sourceField)
            .controller!;
        final sourceEditor = tester.widget<BusyMarkSourceEditor>(
          find.byType(BusyMarkSourceEditor),
        );
        controller.editorIndexOverride = const WritersideProjectIndex(
          symbols: [],
          references: [],
          diagnostics: [],
        );
        sourceEditor.onSymbolAction!(
          SourceSymbolAction.usages,
          topicSource.length - 1,
        );
        await tester.pumpAndSettle();
        expect(find.byType(BusyMarkDialogShell), findsOneWidget);
        expect(find.text(l10n.noResults), findsOneWidget);
        expect(find.byType(AlertDialog), findsNothing);
        await tester.tap(find.text(l10n.close));
        await tester.pumpAndSettle();
        controller.editorIndexOverride = null;

        sourceEditor.onSymbolAction!(
          SourceSymbolAction.usages,
          topicSource.indexOf('guide') + 1,
        );
        await tester.pumpAndSettle();
        expect(find.text('${l10n.findUsages}: guide'), findsOneWidget);
        expect(find.byType(BusyMarkDialogShell), findsOneWidget);
        expect(find.byType(BusyMarkActionRow), findsWidgets);
        expect(find.text('links.md'), findsWidgets);
        await tester.tap(find.text(l10n.close));
        await tester.pumpAndSettle();

        sourceEditor.onSymbolAction!(
          SourceSymbolAction.rename,
          topicSource.indexOf('install') + 1,
        );
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField), 'invalid!');
        await tester.tap(find.text(l10n.rename));
        await tester.pumpAndSettle();
        expect(find.byType(BusyMarkDialogShell), findsOneWidget);
        expect(find.text(l10n.cannotRenameSymbol), findsOneWidget);
        expect(find.byType(AlertDialog), findsNothing);
        expect(controller.state.activeText, topicSource);
        await tester.tap(find.text(l10n.close));
        await tester.pumpAndSettle();

        sourceController.selection = TextSelection.collapsed(
          offset: topicSource.indexOf('guide') + 1,
        );
        await pressShiftF6();
        expect(find.text(l10n.renameTopicFileInstead), findsOneWidget);
        expect(controller.state.activeText, topicSource);
        expect(File(topicPath).readAsStringSync(), topicSource);
        await tester.tap(find.text(l10n.close));
        await tester.pumpAndSettle();

        await tester.tap(sourceField);
        sourceController.selection = TextSelection.collapsed(
          offset: topicSource.indexOf('install') + 1,
        );
        await pressShiftF6();
        expect(find.text('${l10n.rename}: install'), findsOneWidget);
        expect(find.byType(BusyMarkModalEditorScaffold), findsOneWidget);
        expect(find.byType(Dialog), findsOneWidget);
        expect(find.byType(AlertDialog), findsNothing);
        await tester.tapAt(const Offset(1, 1));
        await tester.pump();
        expect(find.byType(BusyMarkModalEditorScaffold), findsOneWidget);
        await tester.enterText(find.byType(TextFormField), 'renamed-install');
        await tester.tap(find.text(l10n.rename));
        await tester.pumpAndSettle();
        expect(controller.state.activeText, contains('id="renamed-install"'));
        expect(controller.state.activeText, contains('id="guide"'));
      },
    );
  }

  testWidgets(
    'topic rename saves every dirty Writerside project source before planning',
    (tester) async {
      const yaruWindowChannel = MethodChannel('yaru_window');
      const yaruWindowEventsChannel = MethodChannel('yaru_window/events');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(yaruWindowChannel, (call) async {
            if (call.method == 'state') return <String, Object?>{};
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
      await binding.setSurfaceSize(const Size(1440, 900));
      addTearDown(() async {
        binding.platformDispatcher.defaultRouteNameTestValue = '/';
        await binding.setSurfaceSize(null);
      });

      final root = Directory.systemTemp.createTempSync(
        'busymark-topic-rename-dirty-project-',
      );
      addTearDown(() {
        if (root.existsSync()) root.deleteSync(recursive: true);
      });
      final topics = Directory(p.join(root.path, 'topics'))..createSync();
      File(p.join(root.path, 'writerside.cfg')).writeAsStringSync(
        '<ihp><topics dir="topics"/><instance src="guide.tree"/></ihp>\n',
      );
      const savedTree = '''
<instance-profile id="guide" start-page="guide.md">
  <toc-element topic="guide.md"/>
  <toc-element topic="notes.md"/>
  <toc-element topic="notes.topic"/>
</instance-profile>
''';
      const dirtyTree = '''
<instance-profile id="guide" start-page="guide.md">
  <toc-element topic="guide.md"/>
  <toc-element topic="guide.md"/>
  <toc-element topic="notes.md"/>
  <toc-element topic="notes.topic"/>
</instance-profile>
''';
      final tree = File(p.join(root.path, 'guide.tree'))
        ..writeAsStringSync(savedTree);
      final guide = File(p.join(topics.path, 'guide.md'))
        ..writeAsStringSync('# Guide\n');
      final markdown = File(p.join(topics.path, 'notes.md'))
        ..writeAsStringSync('# Notes\n');
      final xml = File(p.join(topics.path, 'notes.topic'))
        ..writeAsStringSync('<topic id="notes" title="Notes"/>\n');
      const workspaceService = WorkspaceService();
      final workspace = (await tester.runAsync(
        () => workspaceService.openPath(root.path),
      ))!;

      Future<DocumentBuffer> buffer(
        String id,
        File file,
        String saved,
        String current,
      ) async {
        final snapshot = (await tester.runAsync(
          () => workspaceService.fileSnapshot(file.path),
        ))!;
        return DocumentBuffer.file(
          id: id,
          filePath: file.path,
          text: saved,
          snapshot: snapshot,
          format: TextFormatMetadata.utf8Lf,
        ).edited(current);
      }

      final cleanGuide = await buffer('guide', guide, '# Guide\n', '# Guide\n');
      final dirtyMarkdown = await buffer(
        'markdown',
        markdown,
        '# Notes\n',
        '# Notes\n\n[Guide](guide.md)\n',
      );
      final dirtyXml = await buffer(
        'xml',
        xml,
        '<topic id="notes" title="Notes"/>\n',
        '<topic id="notes" title="Notes"><a href="guide.md">Guide</a></topic>\n',
      );
      final dirtyTreeBuffer = await buffer('tree', tree, savedTree, dirtyTree);
      tree.writeAsStringSync(dirtyTree);
      markdown.writeAsStringSync('# Notes\n\n[Guide](guide.md)\n');
      xml.writeAsStringSync(
        '<topic id="notes" title="Notes"><a href="guide.md">Guide</a></topic>\n',
      );
      final authoritativePlan = (await tester.runAsync(
        () => workspaceService.prepareWritersideTopicRename(
          workspace,
          topicPath: guide.path,
          newFileName: 'setup.md',
          topicModuleRoot: root.path,
        ),
      ))!;
      tree.writeAsStringSync(savedTree);
      markdown.writeAsStringSync('# Notes\n');
      xml.writeAsStringSync('<topic id="notes" title="Notes"/>\n');
      final controller =
          _MutableWorkspaceController(
              WorkspaceState(
                workspace: workspace.copyWith(
                  activeFilePath: guide.path,
                  openFilePaths: [
                    tree.path,
                    markdown.path,
                    xml.path,
                    guide.path,
                  ],
                ),
                documentBuffers: [
                  dirtyTreeBuffer,
                  dirtyMarkdown,
                  dirtyXml,
                  cleanGuide,
                ],
                activeBufferId: cleanGuide.id,
              ),
            )
            ..topicRenamePlans['setup.md'] = authoritativePlan
            ..simulateTopicRename = true;
      final container = ProviderContainer(
        overrides: [
          ..._smokeAccentOverrides,
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
      for (var index = 0; index < 10; index++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.tap(find.byTooltip(l10n.sidebarViewMenu));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.toc));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('workspace-sidebar-toc-row-0')),
      );
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.f6);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.f6);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      final renameField = find.descendant(
        of: find.byType(BusyMarkDialogShell),
        matching: find.byType(EditableText),
      );
      await tester.enterText(renameField, 'setup.md');
      await tester.tap(find.text(l10n.tocRefactorMenu));
      await tester.pumpAndSettle();

      expect(find.text(l10n.unsavedChanges), findsOneWidget);
      for (final name in ['guide.tree', 'notes.md', 'notes.topic']) {
        expect(find.text(name), findsWidgets);
      }
      expect(controller.topicRenamePrepareCount, 0);
      await tester.tap(find.text(l10n.save));
      await tester.pumpAndSettle();

      expect(controller.topicRenamePrepareCount, 1);
      expect(tree.readAsStringSync(), dirtyTree);
      expect(markdown.readAsStringSync(), contains('(guide.md)'));
      expect(xml.readAsStringSync(), contains('href="guide.md"'));
      final prepared = controller.appliedTopicRenamePlan;
      expect(prepared, isNotNull);
      final plannedByPath = {
        for (final change in prepared!.changedFiles)
          p.basename(change.path): change.resultingSource,
      };
      for (final name in ['guide.tree', 'notes.md', 'notes.topic']) {
        expect(
          plannedByPath[name],
          contains('setup.md'),
          reason: '$name must be part of the clean-disk authoritative plan',
        );
      }
      expect(File(guide.path).existsSync(), isTrue);
      expect(File(p.join(topics.path, 'setup.md')).existsSync(), isFalse);
    },
  );

  Future<void> waitForTabAction(
    WidgetTester tester,
    bool Function() done,
  ) async {
    for (var i = 0; i < 1500 && !done(); i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(done(), isTrue, reason: 'Tab action did not finish');
    await tester.pumpAndSettle();
  }

  Future<T> tabOperation<T>(
    WidgetTester tester,
    Future<T> Function() operation,
  ) async {
    late T result;
    Object? error;
    StackTrace? stack;
    var done = false;
    unawaited(
      operation().then<void>(
        (value) {
          result = value;
          done = true;
        },
        onError: (Object caught, StackTrace trace) {
          error = caught;
          stack = trace;
          done = true;
        },
      ),
    );
    await waitForTabAction(tester, () => done);
    if (error != null) Error.throwWithStackTrace(error!, stack!);
    return result;
  }

  Future<
    ({
      ProviderContainer container,
      WorkspaceController controller,
      _TabbedWorkspaceService service,
      List<String> paths,
    })
  >
  tabWorkspace(
    WidgetTester tester, {
    int count = 3,
    bool git = false,
    WorkspaceKind kind = WorkspaceKind.markdownFolder,
  }) async {
    final temp = Directory.systemTemp.createTempSync('busymark_tab_actions_');
    addTearDown(() => temp.deleteSync(recursive: true));
    final paths = [
      for (var i = 0; i < count; i++)
        '${temp.path}/${['a space 文.md', 'b.md', 'c.md'][i]}',
    ];
    for (final path in paths) {
      File(path).writeAsStringSync('# Original\n');
    }
    final service = _TabbedWorkspaceService(
      rootPath: temp.path,
      paths: paths,
      kind: kind,
    );
    final container = ProviderContainer(
      overrides: [
        ..._smokeAccentOverrides,
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(
          _MemorySettingsStore()
            ..value = AppSettings.defaults()
                .copyWith(
                  autoSave: false,
                  validateOnEdit: false,
                  documentViewMode: DocumentViewModePreference.source,
                )
                .toJson(),
        ),
        workspaceServiceProvider.overrideWithValue(service),
        startupPathProvider.overrideWithValue(temp.path),
        if (git)
          gitControllerProvider.overrideWith(
            () => _PresetGitController(_gitDiffState(temp.path)),
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
    for (
      var i = 0;
      i < 40 && container.read(workspaceControllerProvider).workspace == null;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final controller = container.read(workspaceControllerProvider.notifier);
    await tabOperation(tester, () async {
      for (final path in paths.skip(1)) {
        await controller.openActiveFile(path);
      }
    });
    await tester.pumpAndSettle();
    return (
      container: container,
      controller: controller,
      service: service,
      paths: paths,
    );
  }

  testWidgets(
    'Git comparison search keeps authoring search inactive and returns focus',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final temp = Directory.systemTemp.createTempSync('busymark_git_find_');
      addTearDown(() => temp.deleteSync(recursive: true));
      final file = File('${temp.path}/Intro.md')
        ..writeAsStringSync('# Intro.md\n');
      final gitState = _gitSidebarShortcutState(temp.path);
      final client = _SearchableGitReadFixture(gitState);
      final container = ProviderContainer(
        overrides: [
          sharedGitDraftStoreProvider.overrideWithValue(
            shared.MemoryGitDraftStore(),
          ),
          sharedGitClientFactoryProvider.overrideWithValue(
            ({required authorize, prompts}) => client,
          ),
          ..._smokeAccentOverrides.skip(2),
          linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
          localSettingsStoreProvider.overrideWithValue(
            _MemorySettingsStore()
              ..value = AppSettings.defaults()
                  .copyWith(
                    autoSave: false,
                    validateOnEdit: false,
                    documentViewMode: DocumentViewModePreference.source,
                  )
                  .toJson(),
          ),
          workspaceServiceProvider.overrideWithValue(
            _TabbedWorkspaceService(rootPath: temp.path, paths: [file.path]),
          ),
          startupPathProvider.overrideWithValue(temp.path),
          gitControllerProvider.overrideWith(
            () => _PresetGitController(gitState),
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
      await pumpUntil(
        tester,
        () => container.read(workspaceControllerProvider).workspace != null,
        operation: 'open authoring workspace',
      );
      final workspace = container.read(workspaceControllerProvider).workspace!;
      container
          .read(sharedGitReviewProvider.notifier)
          .open(
            workspace.id,
            SharedGitReview(
              client.repository!,
              comparison: shared.GitComparison(
                shared.RepoPath.text('README.md'),
                const shared.ContentVersion.index(),
                const shared.ContentVersion.working(),
              ),
            ),
          );
      final review = find.byType(shared.GitDiffView);
      final comparisonText = find.descendant(
        of: review,
        matching: find.byType(SelectionArea),
      );
      await pumpUntil(
        tester,
        () => comparisonText.evaluate().isNotEmpty,
        operation: 'load shared comparison',
      );
      await tester.pumpAndSettle();
      await tester.tap(comparisonText.first);
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(container.read(searchSessionProvider).active, isFalse);
      expect(find.byKey(const ValueKey('shared-search-query')), findsNothing);
      final query = find.descendant(
        of: review,
        matching: find.byType(TextField),
      );
      expect(query, findsOneWidget);
      expect(tester.widget<TextField>(query).focusNode!.hasFocus, isTrue);
      await tester.enterText(query, 'needle');
      await pumpUntil(
        tester,
        () => find.text('1 of 1 matches').evaluate().isNotEmpty,
        operation: 'finish background Git comparison search',
      );
      expect(tester.widget<TextField>(query).controller!.text, 'needle');
      expect(container.read(searchSessionProvider).query, isEmpty);
      expect(
        container.read(workspaceControllerProvider).activeBuffer!.text,
        '# Intro.md\n',
      );
      await tester.tap(find.text(l10n.gitReturnToDocument));
      await tester.pumpAndSettle();
      final document = find.byWidgetPredicate(
        (w) => w is TextField && w.controller?.text == '# Intro.md\n',
      );
      await tester.tap(document);
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(container.read(searchSessionProvider).active, isTrue);
      expect(review, findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  Finder documentTab(DocumentBuffer buffer) =>
      find.byKey(ValueKey('file:${buffer.id}'));
  Finder tabLabel(DocumentBuffer buffer) => find
      .descendant(of: documentTab(buffer), matching: find.byType(Text))
      .first;
  Future<void> openTabMenu(WidgetTester tester, DocumentBuffer buffer) async {
    await tester.ensureVisible(documentTab(buffer));
    await tester.pumpAndSettle();
    await tester.tap(tabLabel(buffer), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
  }

  Future<void> openTabComparison(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    final history = container.read(localHistoryControllerProvider.notifier);
    final buffer = container.read(workspaceControllerProvider).activeBuffer!;
    // Keep these memory-store operations in the test's zone so pending history
    // work and its completion callbacks can drain through pump().
    var done = false;
    unawaited(() async {
      await history.flushAll(
        container.read(workspaceControllerProvider).documentBuffers,
      );
      await history.selectDocumentForBuffer(buffer);
      await history.selectRevision(
        container
            .read(localHistoryControllerProvider)
            .selectedRevisions
            .first
            .id,
      );
      done = true;
    }());
    await waitForTabAction(tester, () => done);
    expect(
      container.read(localHistoryControllerProvider).selectedRevision,
      isNotNull,
    );
  }

  for (final count in [1, 3]) {
    testWidgets(
      'document tab menu ordering and dismissal with $count documents',
      (tester) async {
        final h = await tabWorkspace(tester, count: count);
        final before = h.container.read(workspaceControllerProvider);
        await openTabMenu(tester, before.documentBuffers.first);
        final entries = tester
            .widgetList<PopupMenuEntry<dynamic>>(
              find.byWidgetPredicate((w) => w is PopupMenuEntry),
            )
            .toList();
        expect(
          entries.map(
            (e) => e is BusyMarkPopupMenuItem ? e.label : 'separator',
          ),
          [
            l10n.close,
            l10n.closeOtherTabs,
            l10n.shortcutCloseAllTabs,
            'separator',
            l10n.copyPath,
            'separator',
            l10n.localHistoryEllipsis,
          ],
        );
        expect((entries[1] as PopupMenuItem).enabled, count > 1);
        expect((entries[4] as PopupMenuItem).enabled, isTrue);
        expect(
          entries.whereType<PopupMenuDivider>().map((e) => e.height),
          everyElement(BusyMarkSpacing.sm),
        );
        expect(
          h.container.read(workspaceControllerProvider).activeBufferId,
          before.activeBufferId,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        final after = h.container.read(workspaceControllerProvider);
        expect(after.activeBufferId, before.activeBufferId);
        expect(
          after.documentBuffers.map((b) => b.id),
          before.documentBuffers.map((b) => b.id),
        );
        expect(after.activeText, before.activeText);
      },
    );
  }

  for (final trigger in ['menu', 'middle', 'cross']) {
    for (final active in [false, true]) {
      testWidgets(
        '$trigger closes exactly the ${active ? 'active' : 'inactive'} document tab',
        (tester) async {
          final h = await tabWorkspace(tester);
          final before = h.container.read(workspaceControllerProvider);
          final target = active
              ? before.activeBuffer!
              : before.documentBuffers.first;
          if (trigger == 'menu') {
            await openTabMenu(tester, target);
            await tester.tap(find.text(l10n.close));
          } else if (trigger == 'middle') {
            final gesture = await tester.startGesture(
              tester.getCenter(tabLabel(target)),
              kind: PointerDeviceKind.mouse,
              buttons: kTertiaryButton,
            );
            await tester.pump();
            expect(
              h.container.read(workspaceControllerProvider).documentBuffers,
              hasLength(3),
            );
            expect(
              h.container.read(workspaceControllerProvider).activeBufferId,
              before.activeBufferId,
            );
            await gesture.up();
          } else {
            await tester.tap(
              find.descendant(
                of: documentTab(target),
                matching: find.byTooltip('Close'),
              ),
            );
          }
          await waitForTabAction(
            tester,
            () =>
                h.container
                    .read(workspaceControllerProvider)
                    .documentBuffers
                    .length ==
                2,
          );
          final after = h.container.read(workspaceControllerProvider);
          expect(
            after.documentBuffers.map((b) => b.id),
            before.documentBuffers
                .where((b) => b.id != target.id)
                .map((b) => b.id),
          );
          if (!active) expect(after.activeBufferId, before.activeBufferId);
          expect(h.service.saveCount, 0);
        },
      );
    }
  }

  for (final trigger in [
    'middle',
    'menu',
    'cross',
    'keyboard',
    'allKeyboard',
  ]) {
    for (final action in ['Cancel', 'Save', 'Discard']) {
      testWidgets('$trigger closes dirty document with $action once', (
        tester,
      ) async {
        final h = await tabWorkspace(tester);
        await tabOperation(
          tester,
          () => h.controller.activateDocumentBuffer(
            h.container
                .read(workspaceControllerProvider)
                .documentBuffers
                .first
                .id,
          ),
        );
        h.controller.updateActiveText('# Unsaved target\n');
        h.controller.updateActiveEditorState(
          h.container
              .read(workspaceControllerProvider)
              .activeBuffer!
              .editorState
              .copyWith(
                mode: DocumentViewModePreference.source,
                selection: const TextSelection(baseOffset: 2, extentOffset: 9),
              ),
        );
        await tester.pumpAndSettle();
        final target = h.container
            .read(workspaceControllerProvider)
            .activeBuffer!;
        await tabOperation(
          tester,
          () => h.controller.activateDocumentBuffer(
            h.container
                .read(workspaceControllerProvider)
                .documentBuffers
                .last
                .id,
          ),
        );
        await tester.pumpAndSettle();
        if (trigger == 'keyboard') {
          await tabOperation(
            tester,
            () => h.controller.activateDocumentBuffer(target.id),
          );
        }
        final activeId = h.container
            .read(workspaceControllerProvider)
            .activeBufferId;
        if (trigger == 'middle') {
          await tester.tap(tabLabel(target), buttons: kTertiaryButton);
        } else if (trigger == 'menu') {
          await openTabMenu(tester, target);
          await tester.tap(find.text(l10n.close));
        } else if (trigger == 'cross') {
          await tester.tap(
            find.descendant(
              of: documentTab(target),
              matching: find.byTooltip('Close'),
            ),
          );
        } else {
          await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
          if (trigger == 'allKeyboard') {
            await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
          }
          await tester.sendKeyEvent(LogicalKeyboardKey.keyW);
          if (trigger == 'allKeyboard') {
            await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
          }
          await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        }
        await tester.pumpAndSettle();
        expect(find.text(l10n.unsavedChanges), findsOneWidget);
        expect(
          h.container.read(workspaceControllerProvider).activeBufferId,
          activeId,
        );
        await tester.tap(find.text(action));
        await tester.pumpAndSettle();
        if (action != 'Cancel') {
          await waitForTabAction(
            tester,
            () =>
                h.container
                    .read(workspaceControllerProvider)
                    .documentBuffers
                    .length ==
                (trigger == 'allKeyboard' ? 0 : 2),
          );
        }
        final remaining = h.container
            .read(workspaceControllerProvider)
            .documentBuffers;
        if (action == 'Cancel') {
          final kept = remaining.singleWhere((b) => b.id == target.id);
          expect(kept.text, target.text);
          expect(kept.isDirty, isTrue);
          expect(kept.editorState.selection, target.editorState.selection);
          expect(
            kept.editorState.undoState,
            same(target.editorState.undoState),
          );
          expect(
            h.container.read(workspaceControllerProvider).activeBufferId,
            activeId,
          );
        } else {
          expect(remaining.any((b) => b.id == target.id), isFalse);
          expect(remaining, hasLength(trigger == 'allKeyboard' ? 0 : 2));
        }
        expect(h.service.saveCount, action == 'Save' ? 1 : 0);
      });
    }
  }

  testWidgets(
    'wheel rotation and primary and secondary tab interactions remain independent',
    (tester) async {
      final h = await tabWorkspace(tester);
      final target = h.container
          .read(workspaceControllerProvider)
          .documentBuffers
          .first;
      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: tester.getCenter(tabLabel(target)),
          scrollDelta: const Offset(0, 24),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        h.container.read(workspaceControllerProvider).documentBuffers,
        hasLength(3),
      );
      await openTabMenu(tester, target);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(
        h.container.read(workspaceControllerProvider).activeBufferId,
        isNot(target.id),
      );
      await tester.tap(tabLabel(target));
      await tester.pumpAndSettle();
      expect(
        h.container.read(workspaceControllerProvider).activeBufferId,
        target.id,
      );
    },
  );

  for (final bulk in ['other', 'all']) {
    testWidgets(
      'close $bulk document tabs also closes Git and Local History comparisons',
      (tester) async {
        final h = await tabWorkspace(tester, git: true);
        final retainedId = h.container
            .read(workspaceControllerProvider)
            .documentBuffers
            .first
            .id;
        await tabOperation(
          tester,
          () => h.controller.activateDocumentBuffer(retainedId),
        );
        h.controller.updateActiveText('# Retained unsaved draft\n');
        h.controller.updateActiveEditorState(
          h.container
              .read(workspaceControllerProvider)
              .activeBuffer!
              .editorState
              .copyWith(
                mode: DocumentViewModePreference.source,
                selection: const TextSelection(baseOffset: 3, extentOffset: 11),
                scrollOffset: 12,
                foldedRegionKeys: const {'keep-fold'},
              ),
        );
        await tester.pumpAndSettle();
        await tester.pumpAndSettle();
        await tabOperation(
          tester,
          () => h.controller.activateDocumentBuffer(
            h.container
                .read(workspaceControllerProvider)
                .documentBuffers
                .last
                .id,
          ),
        );
        await tester.pumpAndSettle();
        final retained = h.container
            .read(workspaceControllerProvider)
            .documentBuffers
            .first;
        await openTabComparison(tester, h.container);
        final historyBefore = h.container
            .read(localHistoryControllerProvider)
            .snapshot
            .revisions
            .length;
        await openTabMenu(tester, retained);
        await tester.tap(
          find.text(
            bulk == 'other' ? l10n.closeOtherTabs : l10n.shortcutCloseAllTabs,
          ),
        );
        await tester.pumpAndSettle();
        if (bulk == 'all') {
          expect(find.text(l10n.unsavedChanges), findsOneWidget);
          await tester.tap(find.text(l10n.discard));
          await tester.pumpAndSettle();
        } else {
          expect(find.text(l10n.unsavedChanges), findsNothing);
        }
        await waitForTabAction(
          tester,
          () =>
              h.container
                  .read(workspaceControllerProvider)
                  .documentBuffers
                  .length ==
              (bulk == 'other' ? 1 : 0),
        );
        final after = h.container.read(workspaceControllerProvider);
        expect(
          h.container.read(gitControllerProvider).openDiffFilePaths,
          isEmpty,
        );
        expect(
          h.container.read(gitControllerProvider).selectedDiffForDisplay,
          isNull,
        );
        expect(
          h.container.read(localHistoryControllerProvider).selectedRevisionId,
          isNull,
        );
        expect(
          h.container
              .read(localHistoryControllerProvider)
              .snapshot
              .revisions
              .length,
          greaterThanOrEqualTo(historyBefore),
        );
        expect(h.service.saveCount, 0);
        if (bulk == 'other') {
          expect(after.documentBuffers.single.id, retained.id);
          expect(after.activeBufferId, retained.id);
          expect(after.activeBuffer!.text, retained.text);
          expect(after.activeBuffer!.isDirty, isTrue);
          expect(retained.editorState.undoState.undo, isNotEmpty);
          expect(
            after.activeBuffer!.editorState.selection,
            retained.editorState.selection,
          );
          expect(
            after.activeBuffer!.editorState.foldedRegionKeys,
            retained.editorState.foldedRegionKeys,
          );
          expect(
            after.activeBuffer!.editorState.undoState,
            same(retained.editorState.undoState),
          );
        } else {
          expect(after.documentBuffers, isEmpty);
          expect(after.workspace!.kind, WorkspaceKind.markdownFolder);
          expect(after.workspace!.openFilePaths, isEmpty);
        }
      },
    );
  }

  testWidgets(
    'comparison-only neighbors enable Close other tabs and middle click closes comparison views',
    (tester) async {
      final h = await tabWorkspace(tester, count: 1, git: true);
      await openTabComparison(tester, h.container);
      final target = h.container
          .read(workspaceControllerProvider)
          .activeBuffer!;
      await openTabMenu(tester, target);
      final other = tester.widget<PopupMenuItem<dynamic>>(
        find.byWidgetPredicate(
          (w) => w is BusyMarkPopupMenuItem && w.label == l10n.closeOtherTabs,
        ),
      );
      expect(other.enabled, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      final revision = h.container
          .read(localHistoryControllerProvider)
          .selectedRevisionId;
      await tester.scrollUntilVisible(
        find.byKey(ValueKey('localHistory:$revision')),
        180,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('editor-tab-strip')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byKey(ValueKey('localHistory:$revision')),
          matching: find.byType(Text),
        ),
        buttons: kTertiaryButton,
      );
      await tester.pumpAndSettle();
      expect(
        h.container.read(localHistoryControllerProvider).selectedRevisionId,
        isNull,
      );
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('gitDiff:README.md')),
          matching: find.byType(Text),
        ),
        buttons: kTertiaryButton,
      );
      await tester.pumpAndSettle();
      expect(h.container.read(gitControllerProvider).openDiffFilePaths, [
        'guide.md',
      ]);
      await openTabMenu(tester, target);
      await tester.tap(find.text(l10n.closeOtherTabs));
      await tester.pumpAndSettle();
      expect(
        h.container.read(gitControllerProvider).openDiffFilePaths,
        isEmpty,
      );
      expect(
        h.container.read(workspaceControllerProvider).activeBufferId,
        target.id,
      );
    },
  );

  testWidgets('bulk close survives the strip disappearing', (tester) async {
    final h = await tabWorkspace(tester, kind: WorkspaceKind.singleMarkdown);
    final target = h.container
        .read(workspaceControllerProvider)
        .documentBuffers
        .first;
    await openTabMenu(tester, target);
    await tester.tap(find.text(l10n.closeOtherTabs));
    await tester.pumpAndSettle();
    await waitForTabAction(
      tester,
      () =>
          h.container
              .read(workspaceControllerProvider)
              .documentBuffers
              .length ==
          1,
    );
    expect(
      h.container.read(workspaceControllerProvider).documentBuffers.single.id,
      target.id,
    );
    expect(find.byKey(const ValueKey('editor-tab-strip')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Copy path uses exact live inactive path even after Save As or deletion',
    (tester) async {
      String? clipboard;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final h = await tabWorkspace(tester);
      var target = h.container
          .read(workspaceControllerProvider)
          .documentBuffers
          .first;
      final active = h.container
          .read(workspaceControllerProvider)
          .activeBufferId;
      await openTabMenu(tester, target);
      await tester.tap(find.text(l10n.copyPath));
      await tester.pumpAndSettle();
      expect(clipboard, h.paths.first);
      expect(
        h.container.read(workspaceControllerProvider).activeBufferId,
        active,
      );
      File(h.paths.first).deleteSync();
      await openTabMenu(tester, target);
      await tester.tap(find.text(l10n.copyPath));
      await tester.pumpAndSettle();
      expect(clipboard, h.paths.first);
      await tabOperation(tester, () => h.controller.createMarkdownFile());
      target = h.container.read(workspaceControllerProvider).activeBuffer!;
      await tester.pumpAndSettle();
      await openTabMenu(tester, target);
      final copy = tester.widget<PopupMenuItem<dynamic>>(
        find.byWidgetPredicate(
          (w) => w is BusyMarkPopupMenuItem && w.label == l10n.copyPath,
        ),
      );
      expect(copy.enabled, isFalse);
      await tester.tap(find.text(l10n.copyPath));
      await tester.pump();
      expect(clipboard, h.paths.first);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      final newPath = '${h.service.rootPath}/saved 文 space.md';
      await openTabMenu(
        tester,
        h.container.read(workspaceControllerProvider).documentBuffers[1],
      );
      // A live path change while a native menu is pending is covered below.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await tabOperation(tester, () => h.controller.saveActiveAs(newPath));
      await tester.pumpAndSettle();
      target = h.container.read(workspaceControllerProvider).activeBuffer!;
      await tabOperation(
        tester,
        () => h.controller.activateDocumentBuffer(
          h.container.read(workspaceControllerProvider).documentBuffers[1].id,
        ),
      );
      await tester.pumpAndSettle();
      await openTabMenu(tester, target);
      await tester.tap(find.text(l10n.copyPath));
      await tester.pumpAndSettle();
      expect(clipboard, newPath);
    },
  );

  for (final selected in [0, 1, 2, 4, 6]) {
    testWidgets(
      'native document menu serializes entries and dispatches index $selected',
      (tester) async {
        final h = await tabWorkspace(tester);
        final before = h.container.read(workspaceControllerProvider);
        final target = before.documentBuffers.first;
        Map? shown;
        String? clipboard;
        const channel = MethodChannel('busymark/native_menus');
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          (call) async {
            if (call.method == 'show') {
              shown = call.arguments as Map;
              return selected;
            }
            return true;
          },
        );
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              clipboard = (call.arguments as Map)['text'] as String;
            }
            return null;
          },
        );
        addTearDown(() {
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            channel,
            null,
          );
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          );
        });
        await openTabMenu(tester, target);
        expect((shown!['entries'] as List).map((e) => (e as Map)['label']), [
          l10n.close,
          l10n.closeOtherTabs,
          l10n.shortcutCloseAllTabs,
          '',
          l10n.copyPath,
          '',
          l10n.localHistoryEllipsis,
        ]);
        expect(
          (shown!['entries'] as List).map((e) => (e as Map)['separator']),
          [false, false, false, true, false, true, false],
        );
        expect((shown!['entries'] as List).map((e) => (e as Map)['enabled']), [
          true,
          true,
          true,
          false,
          true,
          false,
          true,
        ]);
        if (selected <= 2) {
          await waitForTabAction(
            tester,
            () =>
                h.container
                    .read(workspaceControllerProvider)
                    .documentBuffers
                    .length ==
                [2, 1, 0][selected],
          );
        }
        if (selected == 6) {
          await waitForTabAction(
            tester,
            () =>
                h.container
                    .read(localHistoryControllerProvider)
                    .selectedDocument !=
                null,
          );
        }
        final after = h.container.read(workspaceControllerProvider);
        if (selected == 0) {
          expect(after.documentBuffers.any((b) => b.id == target.id), isFalse);
        }
        if (selected == 1) expect(after.documentBuffers.single.id, target.id);
        if (selected == 2) expect(after.documentBuffers, isEmpty);
        if (selected == 4) {
          expect(clipboard, target.filePath);
          expect(after.activeBufferId, before.activeBufferId);
        }
        if (selected == 6) {
          expect(after.activeBufferId, target.id);
          expect(
            h.container
                .read(localHistoryControllerProvider)
                .selectedDocument
                ?.currentPath,
            target.filePath,
          );
          expect(find.byType(LocalHistoryPanel), findsOneWidget);
        }
      },
    );
  }

  testWidgets(
    'pending native Close follows an untitled buffer through its first save',
    (tester) async {
      final h = await tabWorkspace(
        tester,
        count: 1,
        kind: WorkspaceKind.singleMarkdown,
      );
      await tabOperation(tester, () => h.controller.createMarkdownWorkspace());
      h.controller.updateActiveText('# First-save target\n');
      await tester.pumpAndSettle();
      final target = h.container
          .read(workspaceControllerProvider)
          .activeBuffer!;
      await tabOperation(tester, () => h.controller.createMarkdownFile());
      final retainedId = h.container
          .read(workspaceControllerProvider)
          .activeBufferId;
      final result = Completer<int?>();
      const channel = MethodChannel('busymark/native_menus');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'show') return await result.future;
        return true;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      await tester.tap(tabLabel(target), buttons: kSecondaryButton);
      await tester.pump();
      await tabOperation(tester, () async {
        await h.controller.activateDocumentBuffer(target.id);
        await h.controller.saveActiveAs(
          '${h.service.rootPath}/first saved 文.md',
        );
        await h.controller.activateDocumentBuffer(retainedId!);
      });
      expect(
        h.container.read(workspaceControllerProvider).workspace!.kind,
        WorkspaceKind.singleMarkdown,
      );
      result.complete(0);
      await waitForTabAction(
        tester,
        () =>
            h.container
                .read(workspaceControllerProvider)
                .documentBuffers
                .length ==
            1,
      );
      final after = h.container.read(workspaceControllerProvider);
      expect(after.documentBuffers.single.id, retainedId);
      expect(after.documentBuffers.single.isDirty, isTrue);
      expect(find.text(l10n.unsavedChanges), findsNothing);
    },
  );

  for (final actionIndex in [0, 4]) {
    for (final change in ['remove', 'workspace', 'path']) {
      testWidgets(
        'pending native menu index $actionIndex validates live target after $change',
        (tester) async {
          final h = await tabWorkspace(tester);
          final target = h.container
              .read(workspaceControllerProvider)
              .documentBuffers
              .first;
          final result = Completer<int?>();
          String? clipboard;
          const channel = MethodChannel('busymark/native_menus');
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            channel,
            (call) async {
              if (call.method == 'show') return await result.future;
              return true;
            },
          );
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            (call) async {
              if (call.method == 'Clipboard.setData') {
                clipboard = (call.arguments as Map)['text'] as String;
              }
              return null;
            },
          );
          addTearDown(() {
            tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
              channel,
              null,
            );
            tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
              SystemChannels.platform,
              null,
            );
          });
          await tester.tap(tabLabel(target), buttons: kSecondaryButton);
          await tester.pump();
          String? newPath;
          await tabOperation(tester, () async {
            if (change == 'remove') {
              await h.controller.closeDocumentBuffer(target.id);
            }
            if (change == 'workspace') {
              await h.controller.createMarkdownWorkspace();
            }
            if (change == 'path') {
              await h.controller.activateDocumentBuffer(target.id);
              newPath = '${h.service.rootPath}/renamed 文 space.md';
              await h.controller.saveActiveAs(newPath!);
            }
          });
          final beforeDispatch = h.container.read(workspaceControllerProvider);
          result.complete(actionIndex);
          await tester.pumpAndSettle();
          final after = h.container.read(workspaceControllerProvider);
          if (change == 'path') {
            if (actionIndex == 4) expect(clipboard, newPath);
            if (actionIndex == 0) {
              expect(
                after.documentBuffers.any((b) => b.id == target.id),
                isFalse,
              );
            }
          } else {
            expect(clipboard, isNull);
            expect(
              after.documentBuffers.map((b) => b.id),
              beforeDispatch.documentBuffers.map((b) => b.id),
            );
            expect(after.activeBufferId, beforeDispatch.activeBufferId);
          }
        },
      );
    }
  }

  testWidgets('tab keyboard shortcuts move and close editor tabs', (
    tester,
  ) async {
    final temp = Directory.systemTemp.createTempSync('busymark_tabs_');
    addTearDown(() {
      temp.deleteSync(recursive: true);
    });
    final first = File('${temp.path}/a.md')..writeAsStringSync('# A\n');
    final second = File('${temp.path}/b.md')..writeAsStringSync('# B\r\n');
    final third = File('${temp.path}/c.md')..writeAsStringSync('# C\n');
    final service = _TabbedWorkspaceService(
      rootPath: temp.path,
      paths: [first.path, second.path, third.path],
    ).._sources[second.path] = '# B\r\n';
    final container = ProviderContainer(
      overrides: [
        ..._smokeAccentOverrides,
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
    final tabStrip = find.byKey(const ValueKey('editor-tab-strip'));
    final statusBar = find.byKey(const ValueKey('document-status-bar'));
    expect(tabStrip, findsOneWidget);
    expect(statusBar, findsOneWidget);
    expect(
      find.descendant(of: statusBar, matching: find.text('LF')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: tabStrip, matching: find.text('LF')),
      findsNothing,
    );
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
    expect(find.text('LF'), findsNothing);
    expect(find.text('CRLF'), findsOneWidget);
    expect(
      find.descendant(of: statusBar, matching: find.text('CRLF')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: tabStrip, matching: find.text('CRLF')),
      findsNothing,
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
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
        ..._smokeAccentOverrides,
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

    final selectedDiff = container
        .read(gitControllerProvider)
        .selectedCommitFilePath;
    await tester.sendKeyEvent(LogicalKeyboardKey.f9);
    await tester.pumpAndSettle();
    expect(
      container.read(gitControllerProvider).selectedCommitFilePath,
      selectedDiff,
    );
    expect(
      find.textContaining('Guide change', findRichText: true),
      findsWidgets,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.f9);
    await tester.pumpAndSettle();
    expect(
      container.read(gitControllerProvider).selectedCommitFilePath,
      selectedDiff,
    );

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('editor-tab-strip')),
        matching: find.text('current.md'),
      ),
    );
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
    expect(find.byKey(const ValueKey('document-status-bar')), findsNothing);

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
    expect(find.byKey(const ValueKey('document-status-bar')), findsOneWidget);

    await pressControlShortcut(LogicalKeyboardKey.tab);
    expect(
      container.read(gitControllerProvider).selectedCommitFilePath,
      'README.md',
    );
    expect(
      find.textContaining('Readme change', findRichText: true),
      findsWidgets,
    );
    expect(find.byKey(const ValueKey('document-status-bar')), findsNothing);

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
    expect(find.text('${l10n.gitUnstaged} (1)'), findsOneWidget);
    expect(find.textContaining('3 behind'), findsOneWidget);
    expect(find.textContaining('2 ahead'), findsOneWidget);

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

    expect(find.byTooltip(temp.path), findsOneWidget);
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
    expect(find.text(l10n.export), findsNothing);
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
    final review = container.read(sharedGitReviewProvider)[workspace.id]!;
    expect(review.historyPath?.utf8Path, 'README.md');
    expect(review.repository.root, temp.path);
    expect(gitController.loadedFileHistoryPath, isNull);
    expect(find.byType(shared.GitFileHistoryView), findsOneWidget);
    expect(find.byTooltip(l10n.back), findsNothing);
    expect(find.text('File history test commit'), findsOneWidget);

    await tester.tap(find.byTooltip(l10n.sidebarViewMenu));
    await tester.pumpAndSettle();
    expect(find.text(l10n.files), findsWidgets);
    await tester.tap(find.text(l10n.files).last);
    await tester.pumpAndSettle();

    expect(find.text('File history test commit'), findsOneWidget);
    expect(find.text(l10n.gitReturnToDocument), findsOneWidget);
    await tester.tap(find.text(l10n.gitReturnToDocument));
    await tester.pumpAndSettle();
    expect(find.byType(shared.GitFileHistoryView), findsNothing);
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
          ..._smokeAccentOverrides,
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
        ..._smokeAccentOverrides,
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

  for (final hiddenState in ['Log', 'collapsed']) {
    testWidgets(
      'actual window close protects failed message after $hiddenState',
      (tester) async {
        final temp = Directory.systemTemp.createTempSync(
          'busymark_hidden_draft_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));
        final document = File('${temp.path}/Intro.md')
          ..writeAsStringSync('# Intro\n');
        final service = _TabbedWorkspaceService(
          rootPath: temp.path,
          paths: [document.path],
        );
        final gitController = _PresetGitController(
          _gitSidebarShortcutState(temp.path),
        );
        final directory = Directory('${temp.path}/drafts');
        Completer<Directory>? finalWriteDirectory;
        final store = BusyMarkGitDraftStore(
          directory: () =>
              finalWriteDirectory?.future ?? Future.value(directory),
        );
        final workspaceController = _DraftDuringShutdownController();
        final other = BusyMarkGitDraftStore(directory: () async => directory);
        final native = _FakeNativeWindowController();
        final container = ProviderContainer(
          overrides: [
            ..._smokeAccentOverrides.skip(1),
            sharedGitDraftStoreProvider.overrideWithValue(store),
            linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
            localSettingsStoreProvider.overrideWithValue(
              _MemorySettingsStore(),
            ),
            workspaceServiceProvider.overrideWithValue(service),
            workspaceControllerProvider.overrideWith(() => workspaceController),
            startupPathProvider.overrideWithValue(temp.path),
            gitControllerProvider.overrideWith(() => gitController),
            nativeWindowControllerProvider.overrideWithValue(native),
          ],
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const BusyMarkApp(),
          ),
        );
        await pumpUntil(
          tester,
          () => container.read(workspaceControllerProvider).workspace != null,
          operation: 'open authoring workspace',
        );
        await tester.pumpAndSettle();
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await pumpUntil(
          tester,
          () => find.byType(shared.GitCommitView).evaluate().isNotEmpty,
          operation: 'open actual Commit tool area',
        );
        final commit = tester.widget<shared.GitCommitView>(
          find.byType(shared.GitCommitView),
        );
        expect(commit.protectMessageDrafts, isFalse);
        final session = commit.session;
        var observed = false;
        unawaited(
          session
              .readMessageDraft(session.repository.presentationKey)
              .then((_) => observed = true),
        );
        await pumpUntil(
          tester,
          () => observed,
          operation: 'observe initial durable message',
        );
        await tester.runAsync(
          () => other.write(session.repository.presentationKey, 'saved C'),
        );
        final input = find.descendant(
          of: find.byType(shared.GitCommitView),
          matching: find.byType(TextField),
        );
        await tester.enterText(input, 'local unsaved B');
        var saved = false;
        unawaited(session.flushMessageDrafts().then((_) => saved = true));
        await pumpUntil(
          tester,
          () => saved,
          operation: 'observe explicit message persistence conflict',
        );
        await tester.pump();
        expect(session.hasUnpersistedMessageDrafts, isTrue);
        if (hiddenState == 'Log') {
          final log = find.descendant(
            of: find.byType(shared.GitCommitView),
            matching: find.byTooltip('Log'),
          );
          await tester.ensureVisible(log);
          await tester.tap(log);
          await pumpUntil(
            tester,
            () => find.byType(shared.GitLogView).evaluate().isNotEmpty,
            operation: 'enter Log with failed commit draft',
          );
        } else {
          await tester.sendKeyEvent(LogicalKeyboardKey.f9);
          await tester.pumpAndSettle();
          expect(find.byType(shared.GitCommitView), findsNothing);
        }
        expect(
          container.read(busyMarkGitDraftFlushProvider).liveSessions(),
          contains(session),
        );
        final window = container.read(windowControlServiceProvider);
        final closing = window.requestClose();
        await pumpUntil(
          tester,
          () => find
              .text(l10n.gitUiDiscardUnsavedCommitMessages)
              .evaluate()
              .isNotEmpty,
          operation: 'actual app close message guard',
        );
        native.listeners.single.onWindowClose();
        await tester.pump();
        expect(
          find.text(l10n.gitUiDiscardUnsavedCommitMessages),
          findsOneWidget,
        );
        await tester.tap(find.text(l10n.gitUiCancel).last);
        await tester.pumpAndSettle();
        await closing;
        expect(native.closeCount, 0);
        expect(session.draft, 'local unsaved B');
        await tester.runAsync(() async {
          expect(
            await other.read(session.repository.presentationKey),
            'saved C',
          );
        });
        Future<void>? finalWriting;
        workspaceController.onCleanShutdown = () {
          finalWriteDirectory = Completer<Directory>();
          if (hiddenState == 'collapsed') {
            session.setDraft('late unsaved D during document metadata');
            finalWriting = session.flushMessageDrafts();
          } else {
            finalWriting = store.write(
              'shutdown-checkpoint',
              'draft queued after asynchronous document metadata',
            );
          }
        };
        addTearDown(() {
          if (finalWriteDirectory?.isCompleted == false) {
            finalWriteDirectory!.complete(directory);
          }
        });
        final discard = window.requestClose();
        await pumpUntil(
          tester,
          () => find
              .text(l10n.gitUiDiscardUnsavedCommitMessages)
              .evaluate()
              .isNotEmpty,
          operation: 'repeat actual app close message guard',
        );
        await tester.tap(find.text(l10n.gitUiDiscardCommitMessages));
        await pumpUntil(
          tester,
          () => finalWriteDirectory != null,
          operation: 'queue draft during final document metadata',
        );
        await tester.pump();
        expect(
          native.closeCount,
          0,
          reason: 'Final storage flush follows awaited document metadata.',
        );
        finalWriteDirectory!.complete(directory);
        var completed = false;
        unawaited(discard.then((_) => completed = true));
        await pumpUntil(
          tester,
          () => completed,
          operation: 'finish final persistence and exact-revision close check',
        );
        await discard;
        await finalWriting;
        if (hiddenState == 'collapsed') {
          expect(
            native.closeCount,
            0,
            reason: 'Consent for B cannot discard later failed D.',
          );
          expect(session.draft, 'late unsaved D during document metadata');
          expect(session.hasUnpersistedMessageDrafts, isTrue);
          workspaceController.onCleanShutdown = null;
          final renewed = window.requestClose();
          await pumpUntil(
            tester,
            () => find
                .text(l10n.gitUiDiscardUnsavedCommitMessages)
                .evaluate()
                .isNotEmpty,
            operation: 'review newly unsaved message after veto',
          );
          await tester.tap(find.text(l10n.gitUiDiscardCommitMessages));
          await pumpUntil(
            tester,
            () => native.closeCount == 1,
            operation: 'complete newly reviewed draft discard',
          );
          await renewed;
        }
        expect(native.closeCount, 1);
        await tester.runAsync(() async {
          expect(
            await other.read(session.repository.presentationKey),
            'saved C',
          );
        });
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  for (final fail in [false, true]) {
    testWidgets(
      'actual same-State workspace replacement retains draft failure=$fail',
      (tester) async {
        final temp = Directory.systemTemp.createTempSync(
          'busymark_replaced_draft_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));
        final first = Directory('${temp.path}/first')..createSync();
        final second = Directory('${temp.path}/second')..createSync();
        for (final root in [first, second]) {
          File('${root.path}/Intro.md').writeAsStringSync('# Intro\n');
        }
        final directory = Directory.systemTemp.createTempSync(
          'busymark_replaced_messages_',
        );
        addTearDown(() => directory.deleteSync(recursive: true));
        Completer<Directory>? gate;
        final entered = Completer<void>();
        final store = BusyMarkGitDraftStore(
          directory: () {
            if (gate != null) {
              if (!entered.isCompleted) entered.complete();
              return gate.future;
            }
            return Future.value(directory);
          },
        );
        final other = BusyMarkGitDraftStore(directory: () async => directory);
        final native = _FakeNativeWindowController();
        final container = ProviderContainer(
          overrides: [
            ..._smokeAccentOverrides.skip(2),
            sharedGitClientFactoryProvider.overrideWithValue(
              ({required authorize, prompts}) =>
                  _SwitchingSharedGitReadFixture(first.path),
            ),
            sharedGitDraftStoreProvider.overrideWithValue(store),
            linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
            localSettingsStoreProvider.overrideWithValue(
              _MemorySettingsStore(),
            ),
            workspaceServiceProvider.overrideWithValue(
              _SwitchingTabbedWorkspaceService(first.path),
            ),
            startupPathProvider.overrideWithValue(first.path),
            gitControllerProvider.overrideWith(
              () => _SwitchingGitController(first.path),
            ),
            nativeWindowControllerProvider.overrideWithValue(native),
          ],
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const BusyMarkApp(),
          ),
        );
        await pumpUntil(
          tester,
          () => container.read(workspaceControllerProvider).workspace != null,
          operation:
              'open first actual workspace before same-State replacement',
        );
        await tester.pumpAndSettle();
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await pumpUntil(
          tester,
          () => find.byType(shared.GitCommitView).evaluate().isNotEmpty,
          operation: 'attach first actual scope and host',
        );
        final scope = tester.state(find.byType(BusyMarkGitWorkspaceScope));
        final old = tester
            .widget<shared.GitCommitView>(find.byType(shared.GitCommitView))
            .session;
        expect(old.repository.root, first.path);
        gate = Completer<Directory>();
        addTearDown(() {
          final pending = gate;
          if (pending != null && !pending.isCompleted) {
            pending.complete(directory);
          }
        });
        await tester.enterText(
          find.descendant(
            of: find.byType(shared.GitCommitView),
            matching: find.byType(TextField),
          ),
          'pending local B',
        );
        await pumpUntil(
          tester,
          () => entered.isCompleted,
          operation: 'hold actual old-owner draft write before file resolution',
        );
        if (fail) {
          await tester.runAsync(
            () => other.write(
              old.repository.presentationKey,
              'other window saved C',
            ),
          );
        }
        final registry = container.read(busyMarkGitDraftFlushProvider);
        // Complete normal workspace navigation without rendering its transient
        // null workspace. The unkeyed production scope must receive an update,
        // rather than relying on disposal happening on an intermediate frame.
        await _replaceWorkspaceWithoutFrame(tester, container, second.path);
        expect(
          container.read(workspaceControllerProvider).workspace?.rootPath,
          second.path,
        );
        expect(
          tester
              .widget<BusyMarkGitWorkspaceScope>(
                find.byType(BusyMarkGitWorkspaceScope),
              )
              .workspace
              .rootPath,
          first.path,
        );
        await tester.pump();
        expect(
          tester.state(find.byType(BusyMarkGitWorkspaceScope)),
          same(scope),
        );
        expect(
          tester
              .widget<BusyMarkGitWorkspaceScope>(
                find.byType(BusyMarkGitWorkspaceScope),
              )
              .workspace
              .rootPath,
          second.path,
        );
        if (!fail) {
          expect(
            registry.liveSessions(),
            contains(old),
            reason: 'same-State A to B must retain the pending old owner',
          );
        }
        var flushed = false;
        unawaited(registry.flush().then((_) => flushed = true));
        await tester.pump();
        expect(flushed, isFalse);
        gate.complete(directory);
        await pumpUntil(
          tester,
          () => flushed,
          operation: 'drain writes after same-State workspace replacement',
        );
        expect(old.hasUnpersistedMessageDrafts, fail);
        expect(
          registry.liveSessions().contains(old),
          fail,
          reason: 'same-State replacement must retain a failed old owner',
        );
        await tester.runAsync(() async {
          expect(
            await other.read(old.repository.presentationKey),
            fail ? 'other window saved C' : 'pending local B',
          );
        });
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await pumpUntil(
          tester,
          () => find.byType(shared.GitCommitView).evaluate().isNotEmpty,
          operation:
              'attach replacement repository without retargeting old draft',
        );
        final replacement = tester
            .widget<shared.GitCommitView>(find.byType(shared.GitCommitView))
            .session;
        expect(replacement.repository.root, second.path);
        expect(replacement.draft, isEmpty);
        if (fail) {
          final close = container
              .read(windowControlServiceProvider)
              .requestClose();
          await pumpUntil(
            tester,
            () => find
                .text(l10n.gitUiDiscardUnsavedCommitMessages)
                .evaluate()
                .isNotEmpty,
            operation:
                'actual close protects failed owner from prior workspace',
          );
          await tester.tap(find.text(l10n.gitUiCancel).last);
          await tester.pumpAndSettle();
          await close;
          expect(native.closeCount, 0);
        }
        await _replaceWorkspaceWithoutFrame(tester, container, first.path);
        await tester.pump();
        expect(
          tester.state(find.byType(BusyMarkGitWorkspaceScope)),
          same(scope),
        );
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await pumpUntil(
          tester,
          () => find.byType(shared.GitCommitView).evaluate().isNotEmpty,
          operation:
              'recover old-owner text after actual A to B to A navigation',
        );
        final reopened = tester
            .widget<shared.GitCommitView>(find.byType(shared.GitCommitView))
            .session;
        expect(reopened.repository.root, first.path);
        expect(reopened, isNot(same(old)));
        expect(reopened.draft, 'pending local B');
        expect(reopened.hasUnpersistedMessageDrafts, fail);
        expect(find.text('pending local B'), findsOneWidget);
        await tester.runAsync(() async {
          expect(
            await other.read(old.repository.presentationKey),
            fail ? 'other window saved C' : 'pending local B',
          );
          expect(
            await other.read(replacement.repository.presentationKey),
            isNull,
          );
        });
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  for (final fail in [false, true]) {
    testWidgets(
      'actual workspace retirement preserves pending draft failure=$fail',
      (tester) async {
        final temp = Directory.systemTemp.createTempSync(
          'busymark_retired_draft_',
        );
        addTearDown(() => temp.deleteSync(recursive: true));
        final document = File('${temp.path}/Intro.md')
          ..writeAsStringSync('# Intro\n');
        final directory = Directory.systemTemp.createTempSync(
          'busymark_retired_messages_',
        );
        addTearDown(() => directory.deleteSync(recursive: true));
        Completer<Directory>? gate;
        final entered = Completer<void>();
        final store = BusyMarkGitDraftStore(
          directory: () {
            if (gate != null) {
              if (!entered.isCompleted) entered.complete();
              return gate.future;
            }
            return Future.value(directory);
          },
        );
        final other = BusyMarkGitDraftStore(directory: () async => directory);
        final native = _FakeNativeWindowController();
        final container = ProviderContainer(
          overrides: [
            ..._smokeAccentOverrides.skip(1),
            sharedGitDraftStoreProvider.overrideWithValue(store),
            linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
            localSettingsStoreProvider.overrideWithValue(
              _MemorySettingsStore()
                ..value = AppSettings.defaults()
                    .copyWith(localeTag: fail ? 'de' : 'en')
                    .toJson(),
            ),
            workspaceServiceProvider.overrideWithValue(
              _TabbedWorkspaceService(
                rootPath: temp.path,
                paths: [document.path],
              ),
            ),
            startupPathProvider.overrideWithValue(temp.path),
            gitControllerProvider.overrideWith(
              () => _PresetGitController(_gitSidebarShortcutState(temp.path)),
            ),
            nativeWindowControllerProvider.overrideWithValue(native),
          ],
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const BusyMarkApp(),
          ),
        );
        await pumpUntil(
          tester,
          () => container.read(workspaceControllerProvider).workspace != null,
          operation: 'open workspace for retirement',
        );
        await tester.pumpAndSettle();
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await pumpUntil(
          tester,
          () => find.byType(shared.GitCommitView).evaluate().isNotEmpty,
          operation: 'attach actual workspace Git session',
        );
        final old = tester
            .widget<shared.GitCommitView>(find.byType(shared.GitCommitView))
            .session;
        gate = Completer<Directory>();
        addTearDown(() {
          final pending = gate;
          if (pending != null && !pending.isCompleted) {
            pending.complete(directory);
          }
        });
        await tester.enterText(
          find.descendant(
            of: find.byType(shared.GitCommitView),
            matching: find.byType(TextField),
          ),
          'pending local B',
        );
        await pumpUntil(
          tester,
          () => entered.isCompleted,
          operation: 'hold concrete draft before file resolution',
        );
        if (fail) {
          await tester.runAsync(
            () => other.write(
              old.repository.presentationKey,
              'other window saved C',
            ),
          );
        }
        final registry = container.read(busyMarkGitDraftFlushProvider);
        await tester.pumpWidget(const SizedBox.shrink());
        expect(registry.liveSessions(), contains(old));
        var flushed = false;
        unawaited(registry.flush().then((_) => flushed = true));
        await tester.pump();
        expect(flushed, isFalse);
        gate.complete(directory);
        await pumpUntil(
          tester,
          () => flushed,
          operation: 'drain retired workspace message/store jobs',
        );
        expect(registry.liveSessions().contains(old), fail);
        await tester.runAsync(() async {
          expect(
            await other.read(old.repository.presentationKey),
            fail ? 'other window saved C' : 'pending local B',
          );
        });
        if (fail) {
          // The owner is retired, its original widget/localization context gone.
          // A current application context must still show a localized guard.
          container.read(appRouterProvider).go('/');
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: const BusyMarkApp(),
            ),
          );
          await tester.pumpAndSettle();
          final close = container
              .read(windowControlServiceProvider)
              .requestClose();
          final german = AppLocalizationsDe();
          await pumpUntil(
            tester,
            () => find
                .text(german.gitUiDiscardUnsavedCommitMessages)
                .evaluate()
                .isNotEmpty,
            operation: 'localized retired-owner close confirmation',
          );
          await tester.tap(find.text(german.gitUiCancel).last);
          await tester.pumpAndSettle();
          await close;
          expect(native.closeCount, 0);
          container.read(appRouterProvider).go('/workspace');
          await tester.pumpAndSettle();
          await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
          await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
          await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
          await pumpUntil(
            tester,
            () => find.byType(shared.GitCommitView).evaluate().isNotEmpty,
            operation: 'reopen original worktree with retained local draft',
          );
          final reopened = tester
              .widget<shared.GitCommitView>(find.byType(shared.GitCommitView))
              .session;
          expect(reopened, isNot(same(old)));
          expect(reopened.draft, 'pending local B');
          expect(reopened.hasUnpersistedMessageDrafts, isTrue);
          expect(find.text('pending local B'), findsOneWidget);
          await tester.pumpWidget(const SizedBox.shrink());
        }
      },
    );
  }

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
        ..._smokeAccentOverrides,
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
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
    }

    Future<void> setDocumentViewMode(
      DocumentViewModePreference expectedMode,
    ) async {
      await container
          .read(appSettingsControllerProvider.notifier)
          .setDocumentViewMode(expectedMode);
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
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
      await tester.pumpAndSettle();
    }
    await tester.pumpAndSettle();

    expect(find.text('Api.md'), findsOneWidget);

    final sidebarKey = ValueKey(
      container.read(workspaceControllerProvider).workspace!.id,
    );
    final sidebarState = tester.state(find.byKey(sidebarKey));

    expect(
      find.byTooltip(
        '${l10n.hideSidebar} (${BusyMarkSidebarShortcuts.toggleSidebar.label})',
      ),
      findsOneWidget,
    );
    _expectNeutralSidebarToggle(
      tester,
      '${l10n.hideSidebar} (${BusyMarkSidebarShortcuts.toggleSidebar.label})',
      selected: true,
    );
    _expectHeaderControlGap(
      tester,
      leftTooltip: l10n.hideSidebar,
      rightTooltip: l10n.back,
    );
    _expectHeaderControlGap(
      tester,
      leftTooltip: l10n.viewMode,
      rightTooltip: l10n.validate,
    );
    _expectHeaderControlGap(
      tester,
      leftTooltip: l10n.validate,
      rightTooltip: l10n.search,
    );
    _expectHeaderControlGap(
      tester,
      leftTooltip: l10n.search,
      rightTooltip: l10n.mainMenu,
    );
    _expectHeaderGeometry(tester);
    for (final tooltip in [
      l10n.back,
      l10n.viewMode,
      l10n.validate,
      l10n.search,
      l10n.mainMenu,
    ]) {
      _expectNeutralHeaderControl(tester, tooltip, selected: false);
    }
    expect(
      tester.widget<IconButton>(_headerIconButton(l10n.viewMode)).tooltip,
      l10n.viewMode,
    );
    await tester.tap(_headerIconButton(l10n.viewMode));
    await tester.pumpAndSettle();
    _expectNeutralHeaderControl(tester, l10n.viewMode, selected: true);
    final viewItems = tester
        .widgetList<BusyMarkPopupMenuItem<DocumentViewModePreference>>(
          find.byType(BusyMarkPopupMenuItem<DocumentViewModePreference>),
        )
        .toList();
    expect(viewItems, hasLength(4));
    expect(
      viewItems.every((item) => item.shortcut?.isNotEmpty == true),
      isTrue,
    );
    expect(
      viewItems.singleWhere((item) => item.label == l10n.reading).icon,
      BusyMarkGlyphs.previewView,
    );
    expect(
      viewItems.singleWhere((item) => item.label == l10n.split).icon,
      BusyMarkGlyphs.splitView,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.tap(_headerIconButton(l10n.mainMenu));
    await tester.pumpAndSettle();
    _expectNeutralHeaderControl(tester, l10n.mainMenu, selected: true);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.f9);
    await tester.pumpAndSettle();
    expect(find.byTooltip(l10n.sidebarViewMenu), findsNothing);
    expect(
      tester.state(find.byKey(sidebarKey, skipOffstage: false)),
      same(sidebarState),
    );
    expect(
      find.byTooltip(
        '${l10n.showSidebar} (${BusyMarkSidebarShortcuts.toggleSidebar.label})',
      ),
      findsOneWidget,
    );
    _expectNeutralSidebarToggle(
      tester,
      '${l10n.showSidebar} (${BusyMarkSidebarShortcuts.toggleSidebar.label})',
      selected: false,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.f9);
    await tester.pumpAndSettle();
    expect(find.byTooltip(l10n.sidebarViewMenu), findsOneWidget);
    expect(tester.state(find.byKey(sidebarKey)), same(sidebarState));
    _expectNeutralSidebarToggle(
      tester,
      '${l10n.hideSidebar} (${BusyMarkSidebarShortcuts.toggleSidebar.label})',
      selected: true,
    );
    _expectHeaderGeometry(tester);

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
    expect(
      tester
          .widget<BusyMarkHeaderPopupMenuButton>(
            find.byKey(const ValueKey('workspace-sidebar-view-menu')),
          )
          .icon,
      BusyMarkGlyphs.documentOpen,
    );
    expect(find.byTooltip(temp.path), findsOneWidget);
    expect(find.byTooltip(l10n.gitActions), findsNothing);

    await pressControlShortcut(LogicalKeyboardKey.digit5);
    expect(find.byType(LocalHistoryPanel), findsOneWidget);
    expect(
      tester
          .widget<BusyMarkHeaderPopupMenuButton>(
            find.byKey(const ValueKey('workspace-sidebar-view-menu')),
          )
          .icon,
      BusyMarkGlyphs.sidebarLocalHistory,
    );

    await pressControlShortcut(LogicalKeyboardKey.digit6);
    expect(find.byType(ClipboardHistoryPanel), findsOneWidget);
    expect(
      tester
          .widget<BusyMarkHeaderPopupMenuButton>(
            find.byKey(const ValueKey('workspace-sidebar-view-menu')),
          )
          .icon,
      BusyMarkGlyphs.copy,
    );

    await setDocumentViewMode(DocumentViewModePreference.preview);
    await pressControlShortcut(LogicalKeyboardKey.digit4);
    expect(find.text(l10n.gitNoChanges), findsOneWidget);
    expect(find.byTooltip(temp.path), findsOneWidget);
    expect(find.byType(shared.GitCommitView), findsOneWidget);
    expect(find.text('Commit scope: entire repository'), findsOneWidget);
    expect(find.byTooltip('Repository actions'), findsOneWidget);
    final commitView = find.byType(shared.GitCommitView);
    final commitWidget = tester.widget<shared.GitCommitView>(commitView);
    expect(commitWidget.session.host.spacing, BusyMarkSpacing.sm);
    expect(commitWidget.session.repository.root, temp.path);
    expect(commitWidget.session.snapshot!.changes, isEmpty);
    expect(
      commitWidget.session.host.icons[shared.GitGlyph.branch],
      BusyMarkGlyphs.branch,
    );
    expect(
      commitWidget.session.host.icons[shared.GitGlyph.history],
      BusyMarkGlyphs.history,
    );
    expect(gitController.branchLoadCount, 0);
    final messageField = find.descendant(
      of: commitView,
      matching: find.byType(TextField),
    );
    expect(messageField, findsOneWidget);
    expect(tester.widget<TextField>(messageField).maxLines, isNull);
    expect(tester.widget<TextField>(messageField).expands, isTrue);
    await tester.enterText(messageField, 'Preserved shell draft');
    await tester.pump();
    expect(commitWidget.session.draft, 'Preserved shell draft');
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Commit staged (0)'),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Commit and Push…'),
          )
          .onPressed,
      isNull,
    );
    expect(find.byType(Checkbox), findsOneWidget);
    final logAction = find.descendant(
      of: commitView,
      matching: find.byTooltip('Log'),
    );
    expect(logAction, findsOneWidget);
    final sharedClient = commitWidget.session.client as SharedGitReadFixture;
    final statusReadsBeforeLog = sharedClient.statusReads;
    expect(sharedClient.watchSubscriptions, 1);
    await tester.ensureVisible(logAction);
    await tester.pumpAndSettle();
    await tester.tap(logAction);
    await tester.pumpAndSettle();
    expect(find.byType(shared.GitLogView), findsOneWidget);
    expect(
      tester.widget<shared.GitLogView>(find.byType(shared.GitLogView)).session,
      same(commitWidget.session),
      reason: 'Commit and Log must retain one worktree attachment and draft.',
    );
    expect(sharedClient.statusReads, statusReadsBeforeLog);
    expect(sharedClient.watchSubscriptions, 1);
    expect(
      find.textContaining('Sidebar history shortcut commit'),
      findsOneWidget,
    );
    expect(find.text('Subject / references'), findsOneWidget);
    // A compact Log exposes navigation as a named icon; a wider Log uses its
    // text button. Exercise the command instead of requiring one presentation.
    final navigationLabel = find.text('Go to commit/reference…');
    final navigationAction = navigationLabel.evaluate().isEmpty
        ? find.byTooltip('Go to commit/reference…')
        : navigationLabel;
    expect(navigationAction, findsOneWidget);
    await tester.ensureVisible(navigationAction);
    await tester.tap(navigationAction);
    await tester.pumpAndSettle();
    final navigationField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.labelText == 'Go to commit/reference',
    );
    expect(navigationField, findsOneWidget);
    expect(tester.widget<TextField>(navigationField).readOnly, isFalse);
    await tester.enterText(navigationField, 'HEAD');
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(navigationField, findsNothing);
    expect(find.byType(shared.GitLogView), findsOneWidget);
    expect(commitWidget.session.draft, 'Preserved shell draft');
    expect(find.text('Reset filters'), findsOneWidget);
    expect(
      container
          .read(sharedGitReviewProvider)[container
              .read(workspaceControllerProvider)
              .workspace!
              .id]
          ?.log,
      isTrue,
    );
    await setDocumentViewMode(DocumentViewModePreference.split);
    await pressControlShortcut(LogicalKeyboardKey.digit4);
    expect(find.byType(shared.GitLogView), findsOneWidget);
    expect(find.text('Preserved shell draft'), findsOneWidget);
    expect(find.byTooltip(temp.path), findsOneWidget);
    expect(find.text(l10n.gitReturnToDocument), findsOneWidget);
    await tester.tap(find.text(l10n.gitReturnToDocument));
    await tester.pumpAndSettle();
    expect(find.byType(shared.GitLogView), findsNothing);
    expect(
      find.textContaining('Sidebar history shortcut commit'),
      findsNothing,
    );
    expect(find.text('Preserved shell draft'), findsOneWidget);
    expect(container.read(gitControllerProvider).selectedView, GitView.changes);

    await setDocumentViewMode(DocumentViewModePreference.editor);
    await pressControlShortcut(LogicalKeyboardKey.digit3);
    expect(find.text(l10n.gitNoChanges), findsNothing);
    expect(
      find.textContaining('Sidebar history shortcut commit'),
      findsNothing,
    );
    expect(find.text('Intro.md'), findsWidgets);
    expect(find.byTooltip(temp.path), findsNothing);
    expect(find.byTooltip(l10n.gitActions), findsNothing);
    expect(container.read(searchSessionProvider).active, isFalse);
    expect(find.byKey(const ValueKey('shared-search-query')), findsNothing);
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
    expect(find.text(l10n.export), findsNothing);
    expect(find.byType(PopupMenuDivider), findsNothing);

    await tester.tap(find.text(l10n.copyFileName));
    await tester.pumpAndSettle();
    expect(clipboardText, 'Intro.md');

    await tester.tap(outlineFileActions);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.copyPath));
    await tester.pumpAndSettle();
    expect(clipboardText, first.path);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(l10n.sidebarViewMenu));
    await tester.pumpAndSettle();

    for (final (label, shortcut) in <(String, String)>[
      (l10n.files, BusyMarkSidebarShortcuts.files.label),
      (l10n.outline, BusyMarkSidebarShortcuts.outline.label),
      (l10n.git, BusyMarkSidebarShortcuts.git.label),
      (l10n.localHistory, BusyMarkSidebarShortcuts.localHistory.label),
      (l10n.clipboardHistory, BusyMarkSidebarShortcuts.clipboardHistory.label),
    ]) {
      expect(find.text(label), findsOneWidget);
      expect(find.text(shortcut), findsOneWidget);
      expect(find.byTooltip('$label ($shortcut)'), findsNothing);
    }
    expect(
      tester.getTopLeft(find.text(l10n.localHistory)).dy,
      lessThan(tester.getTopLeft(find.text(l10n.clipboardHistory)).dy),
    );
    expect(find.text(l10n.gitChanges), findsNothing);
    expect(find.text(l10n.gitFileHistory), findsNothing);
    expect(find.text(l10n.gitProjectHistory), findsNothing);
    expect(find.text(l10n.findLocalHistoryEllipsis), findsNothing);
    expect(find.text(l10n.export), findsNothing);
    final gitEntry = find.ancestor(
      of: find.text(l10n.git),
      matching: find.byWidgetPredicate((widget) => widget is PopupMenuItem),
    );
    expect(
      find.descendant(
        of: gitEntry,
        matching: find.byIcon(BusyMarkGlyphs.branch),
      ),
      findsOneWidget,
    );
    expect(find.byIcon(BusyMarkGlyphs.sidebarLocalHistory), findsOneWidget);
  });

  testWidgets(
    'real Source edits reach the visible Local History list on the fixed deadline',
    (tester) async {
      const nativeMenuChannel = MethodChannel('busymark/native_menus');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        nativeMenuChannel,
        (call) async => call.method == 'dismiss' ? true : null,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          nativeMenuChannel,
          null,
        ),
      );
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final temp = Directory.systemTemp.createTempSync(
        'busymark-editor-history-',
      );
      final file = File(p.join(temp.path, 'history.md'))
        ..writeAsStringSync('alpha beta\n');
      addTearDown(() {
        if (temp.existsSync()) temp.deleteSync(recursive: true);
      });
      final settingsStore = _MemorySettingsStore()
        ..value = AppSettings.defaults()
            .copyWith(
              autoSave: false,
              validateOnEdit: false,
              documentViewMode: DocumentViewModePreference.source,
            )
            .toJson();
      var now = DateTime.utc(2026, 3, 4, 10);
      final timers = <_HistoryTestTimer>[];
      final historyStore = MemoryLocalHistoryStore();
      final container = ProviderContainer(
        overrides: [
          ..._smokeAccentOverrides,
          linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
          localSettingsStoreProvider.overrideWithValue(settingsStore),
          workspaceServiceProvider.overrideWithValue(
            const _SearchWorkspaceService('alpha beta\n'),
          ),
          startupPathProvider.overrideWithValue(file.path),
          localHistoryStoreProvider.overrideWithValue(historyStore),
          localHistoryClockProvider.overrideWithValue(() => now),
          localHistoryTimerFactoryProvider.overrideWithValue((delay, callback) {
            final timer = _HistoryTestTimer(delay, callback);
            timers.add(timer);
            return timer;
          }),
        ],
      );
      addTearDown(container.dispose);
      Future<void> waitForHistory(
        bool Function(LocalHistoryState state) condition,
      ) async {
        await tester.runAsync(() async {
          final deadline = DateTime.now().add(const Duration(seconds: 3));
          while (!condition(container.read(localHistoryControllerProvider))) {
            if (DateTime.now().isAfter(deadline)) {
              throw StateError('Timed out waiting for Local History state');
            }
            await Future<void>.delayed(const Duration(milliseconds: 10));
          }
        });
        await tester.pump();
      }

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BusyMarkApp(),
        ),
      );
      for (var index = 0; index < 40; index += 1) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.byType(BusyMarkSourceEditor).evaluate().isNotEmpty) break;
      }
      expect(find.byType(BusyMarkSourceEditor), findsOneWidget);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit5);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump(const Duration(milliseconds: 100));
      await waitForHistory((history) => history.selectedRevisions.length == 1);
      expect(find.byType(LocalHistoryPanel), findsOneWidget);
      expect(
        container.read(localHistoryControllerProvider).selectedRevisions,
        hasLength(1),
      );

      final sourceField = find.descendant(
        of: find.byType(BusyMarkSourceEditor),
        matching: find.byType(TextField),
      );
      await tester.tap(sourceField);
      await tester.enterText(sourceField, 'alpha beta gamma\n');
      await tester.pump();
      await tester.enterText(sourceField, 'alpha gamma\n');
      await tester.pump();
      await tester.enterText(sourceField, '**alpha** gamma\n');
      await tester.pump();

      const formatted = '**alpha** gamma\n';
      expect(container.read(workspaceControllerProvider).activeText, formatted);
      final editedBufferId = container
          .read(workspaceControllerProvider)
          .activeBuffer!
          .id;
      await waitForHistory(
        (_) =>
            container
                .read(localHistoryControllerProvider.notifier)
                .pendingSnapshotForBuffer(editedBufferId)
                ?.text ==
            formatted,
      );
      expect(timers, hasLength(1));
      expect(timers.single.duration, const Duration(seconds: 60));
      expect(
        container.read(localHistoryControllerProvider).selectedRevisions,
        hasLength(1),
        reason: 'Source operations update pending state, not one row per edit.',
      );

      now = now.add(const Duration(seconds: 60));
      timers.single.fire();
      await waitForHistory((history) => history.selectedRevisions.length == 2);
      var history = container.read(localHistoryControllerProvider);
      expect(history.selectedRevisions, hasLength(2));
      expect(
        find.descendant(
          of: find.byType(LocalHistoryPanel),
          matching: find.byWidgetPredicate(
            (widget) => widget is BusyMarkSidebarRecordRow,
          ),
        ),
        findsNWidgets(2),
      );
      final capturedSources = <String>[];
      await tester.runAsync(() async {
        for (final revision in history.selectedRevisions) {
          capturedSources.add(
            (await historyStore.readRevision(revision.id))!.source,
          );
        }
      });
      expect(capturedSources, contains(formatted));

      container
          .read(searchSessionProvider.notifier)
          .openHistory(documentId: history.selectedDocumentId);
      await tester.pump();
      final historySearch = find.descendant(
        of: find.byKey(const ValueKey('shared-search-query')),
        matching: find.byType(TextField),
      );
      await tester.enterText(historySearch, 'needle');
      await tester.pump();
      await tester.tap(sourceField);
      await tester.enterText(sourceField, '**alpha** needle\n');
      await tester.pump();
      now = now.add(const Duration(seconds: 60));
      expect(timers.where((timer) => timer.isActive), hasLength(1));
      timers.lastWhere((timer) => timer.isActive).fire();
      await _waitForSearchCondition(
        tester,
        () =>
            !container.read(searchSessionProvider).searching &&
            container
                    .read(searchSessionProvider)
                    .results
                    .whereType<HistorySearchResult>()
                    .length ==
                1,
      );

      history = container.read(localHistoryControllerProvider);
      expect(container.read(searchSessionProvider).query, 'needle');
      expect(
        container
            .read(searchSessionProvider)
            .results
            .whereType<HistorySearchResult>(),
        hasLength(1),
      );
      expect(
        tester.widget<TextField>(historySearch).controller!.text,
        'needle',
      );
      await tester.pump(BusyMarkMotion.search);
      expect(find.byType(LocalHistoryPanel), findsNothing);
      expect(
        history.selectedRevisions,
        hasLength(3),
        reason: 'Search never filters the ordinary timeline.',
      );

      await tester.tap(sourceField);
      await tester.enterText(sourceField, '**alpha** needle redo-state\n');
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      expect(
        container.read(workspaceControllerProvider).activeText,
        '**alpha** needle\n',
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      const redone = '**alpha** needle redo-state\n';
      expect(container.read(workspaceControllerProvider).activeText, redone);
      final bufferId = container
          .read(workspaceControllerProvider)
          .activeBuffer!
          .id;
      await waitForHistory(
        (_) =>
            container
                .read(localHistoryControllerProvider.notifier)
                .pendingSnapshotForBuffer(bufferId)
                ?.text ==
            redone,
      );
      expect(
        container
            .read(localHistoryControllerProvider.notifier)
            .pendingSnapshotForBuffer(bufferId)
            ?.text,
        redone,
      );
      now = now.add(const Duration(seconds: 60));
      timers.lastWhere((timer) => timer.isActive).fire();
      await waitForHistory((history) => history.selectedRevisions.length == 4);
      history = container.read(localHistoryControllerProvider);
      final finalSources = <String>[];
      await tester.runAsync(() async {
        for (final revision in history.selectedRevisions) {
          finalSources.add(
            (await historyStore.readRevision(revision.id))!.source,
          );
        }
      });
      expect(finalSources, contains(redone));
      await _waitForSearchCondition(
        tester,
        () =>
            !container.read(searchSessionProvider).searching &&
            container.read(searchSessionProvider).results.length == 2,
        debugState: () {
          final search = container.read(searchSessionProvider);
          return 'query=${search.query}, searching=${search.searching}, '
              'results=${search.results.map((r) => r.identity).toList()}, '
              'sources=$finalSources';
        },
      );
      expect(container.read(searchSessionProvider).query, 'needle');
      expect(
        container
            .read(searchSessionProvider)
            .results
            .whereType<HistorySearchResult>(),
        hasLength(2),
      );
    },
  );

  testWidgets(
    'selected WYSIWYG formatting reaches Local History through workspace callbacks',
    (tester) async {
      const nativeMenuChannel = MethodChannel('busymark/native_menus');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        nativeMenuChannel,
        (call) async => call.method == 'dismiss' ? true : null,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          nativeMenuChannel,
          null,
        ),
      );
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final temp = Directory.systemTemp.createTempSync(
        'busymark-wysiwyg-history-',
      );
      final file = File(p.join(temp.path, 'format.md'))
        ..writeAsStringSync('First\n\nSecond\n\nThird\n');
      addTearDown(() {
        if (temp.existsSync()) temp.deleteSync(recursive: true);
      });
      final settingsStore = _MemorySettingsStore()
        ..value = AppSettings.defaults()
            .copyWith(
              autoSave: false,
              validateOnEdit: false,
              documentViewMode: DocumentViewModePreference.editor,
            )
            .toJson();
      var now = DateTime.utc(2026, 3, 4, 11);
      final timers = <_HistoryTestTimer>[];
      final historyStore = MemoryLocalHistoryStore();
      final container = ProviderContainer(
        overrides: [
          ..._smokeAccentOverrides,
          linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
          localSettingsStoreProvider.overrideWithValue(settingsStore),
          workspaceServiceProvider.overrideWithValue(
            const _SearchWorkspaceService('First\n\nSecond\n\nThird\n'),
          ),
          startupPathProvider.overrideWithValue(file.path),
          localHistoryStoreProvider.overrideWithValue(historyStore),
          localHistoryClockProvider.overrideWithValue(() => now),
          localHistoryTimerFactoryProvider.overrideWithValue((delay, callback) {
            final timer = _HistoryTestTimer(delay, callback);
            timers.add(timer);
            return timer;
          }),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BusyMarkApp(),
        ),
      );
      for (var index = 0; index < 40; index += 1) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find
            .byKey(const ValueKey('wysiwyg-document-content'))
            .evaluate()
            .isNotEmpty) {
          break;
        }
      }
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit5);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump(const Duration(milliseconds: 100));
      for (var index = 0; index < 40; index += 1) {
        await tester.pump(const Duration(milliseconds: 25));
        if (container
                .read(localHistoryControllerProvider)
                .selectedRevisions
                .length ==
            1) {
          break;
        }
      }

      final wysiwygFields = find.descendant(
        of: find.byKey(const ValueKey('wysiwyg-document-content')),
        matching: find.byType(TextField),
      );
      expect(wysiwygFields, findsWidgets);
      final firstField = tester.widget<TextField>(wysiwygFields.first);
      firstField.focusNode!.requestFocus();
      firstField.controller!.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 5,
      );
      await tester.tap(find.byIcon(BusyMarkGlyphs.bold));
      await tester.pump();

      const formatted = '**First**\n\nSecond\n\nThird\n';
      expect(container.read(workspaceControllerProvider).activeText, formatted);
      final bufferId = container
          .read(workspaceControllerProvider)
          .activeBuffer!
          .id;
      for (var index = 0; index < 40; index += 1) {
        await tester.pump(const Duration(milliseconds: 10));
        if (container
                .read(localHistoryControllerProvider.notifier)
                .pendingSnapshotForBuffer(bufferId)
                ?.text ==
            formatted) {
          break;
        }
      }
      expect(timers, hasLength(1));
      expect(timers.single.duration, const Duration(seconds: 60));
      expect(
        container.read(localHistoryControllerProvider).selectedRevisions,
        hasLength(1),
      );

      now = now.add(const Duration(seconds: 60));
      timers.single.fire();
      for (var index = 0; index < 80; index += 1) {
        await tester.pump(const Duration(milliseconds: 25));
        if (container
                .read(localHistoryControllerProvider)
                .selectedRevisions
                .length ==
            2) {
          break;
        }
      }
      final history = container.read(localHistoryControllerProvider);
      expect(history.selectedRevisions, hasLength(2));
      final sources = <String>[];
      for (final revision in history.selectedRevisions) {
        sources.add((await historyStore.readRevision(revision.id))!.source);
      }
      expect(sources, contains(formatted));
      expect(
        find.descendant(
          of: find.byType(LocalHistoryPanel),
          matching: find.byWidgetPredicate(
            (widget) => widget is BusyMarkSidebarRecordRow,
          ),
        ),
        findsNWidgets(2),
      );
    },
  );

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
    final source = workspace.markdown?.source ?? '';
    final activePath = workspace.activeFilePath!;
    final activeBuffer = DocumentBuffer(
      id: 'writerside-sidebar-active',
      filePath: activePath,
      text: source,
      lastSavedText: source,
      dirty: false,
    );
    final controller = _MutableWorkspaceController(
      WorkspaceState(
        workspace: workspace,
        documentBuffers: [activeBuffer],
        activeBufferId: activeBuffer.id,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        ..._smokeAccentOverrides,
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
      controller.updateActiveEditorMode(expectedMode);
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
      if (key == LogicalKeyboardKey.digit4) {
        final commit = find.byType(shared.GitCommitView);
        expect(commit, findsOneWidget);
        expect(
          tester.widget<shared.GitCommitView>(commit).session.host.spacing,
          BusyMarkSpacing.sm,
        );
        expect(
          tester.getRect(commit).top,
          greaterThanOrEqualTo(tester.getBottomLeft(primaryRow).dy),
        );
        expect(
          tester.getRect(commit).bottom,
          lessThanOrEqualTo(tester.view.physicalSize.height),
        );
        expect(find.byTooltip('Repository actions'), findsOneWidget);
        expect(find.text('Commit scope: entire repository'), findsOneWidget);
        expect(find.text('Commit staged (0)'), findsOneWidget);
        expect(find.text(l10n.gitCommitMessage), findsOneWidget);
        continue;
      }
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

    await selectView(LogicalKeyboardKey.digit3);
    final outlineFileMenu = find.byKey(
      const ValueKey('workspace-sidebar-outline-file-menu'),
    );
    final outlineFileActions = find.descendant(
      of: outlineFileMenu,
      matching: find.byTooltip(l10n.actions),
    );
    await tester.tap(outlineFileActions);
    await tester.pumpAndSettle();
    expect(find.text(l10n.copyFileName), findsOneWidget);
    expect(find.text(l10n.copyPath), findsOneWidget);
    expect(find.text(l10n.openInFiles), findsOneWidget);
    expect(find.text(l10n.aiRefineWithAi), findsOneWidget);
    expect(find.text(l10n.export), findsNothing);
    expect(find.byType(PopupMenuDivider), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    await selectView(LogicalKeyboardKey.digit2);
    final selectedTopicActions = find.byTooltip(l10n.actions);
    expect(selectedTopicActions, findsOneWidget);
    await tester.tap(selectedTopicActions);
    await tester.pump(kDoubleTapTimeout);
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
        ..._smokeAccentOverrides,
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
        ..._smokeAccentOverrides,
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
        ..._smokeAccentOverrides,
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
        ..._smokeAccentOverrides,
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
      final activeBuffer = DocumentBuffer.untitled(
        id: 'arabic-untitled-active',
        name: ar.untitledMarkdownFileName,
        text: '# عنوان\n',
        mode: DocumentViewModePreference.source,
      );
      final controller = _MutableWorkspaceController(
        WorkspaceState(
          workspace: workspace,
          documentBuffers: [activeBuffer],
          activeBufferId: activeBuffer.id,
        ),
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
          ..._smokeAccentOverrides,
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
  <toc-element topic="start.md" id="nav-start" toc-title="Navigation label"/>
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
        ..._smokeAccentOverrides,
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
    await tester.ensureVisible(find.text(ar.copyName));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ar.copyName));
    await tester.pumpAndSettle();

    expect(clipboardText, href);
    expect(clipboardText, isNot(contains(RegExp('[\u2066-\u2069]'))));

    for (final (label, expected) in [
      (ar.tocCopyFileName('start.md'), 'start.md'),
      (ar.tocCopyFilePath, p.join(root.path, 'topics/start.md')),
      (ar.tocCopyTopicTitle('Start'), 'Start'),
      (ar.tocCopyElementId('nav-start'), 'nav-start'),
    ]) {
      await tester.tap(
        find.text('Navigation label'),
        buttons: kSecondaryButton,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(ar.tocCopySpecial));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(clipboardText, expected);
      expect(clipboardText, isNot(contains(RegExp('[\u2066-\u2069]'))));
    }
  });

  testWidgets('TOC Copy uses an inactive origin topic open buffer', (
    tester,
  ) async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.defaultRouteNameTestValue = '/workspace';
    addTearDown(
      () => binding.platformDispatcher.defaultRouteNameTestValue = '/',
    );
    String? clipboardText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboardText = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final root = Directory.systemTemp.createTempSync(
      'busymark-toc-copy-buffer-',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final mainTopics = Directory(p.join(root.path, 'topics'))..createSync();
    final sharedRoot = Directory(p.join(root.path, 'shared'))..createSync();
    final sharedTopics = Directory(p.join(sharedRoot.path, 'topics'))
      ..createSync();
    File(p.join(root.path, 'writerside.cfg')).writeAsStringSync('''
<ihp><module name="main"/><topics dir="topics"/><instance src="guide.tree"/></ihp>
''');
    File(p.join(root.path, 'guide.tree')).writeAsStringSync('''
<instance-profile id="guide" start-page="active.md">
  <toc-element topic="shared.md" origin="shared"/>
  <toc-element topic="active.md"/>
</instance-profile>
''');
    final active = File(p.join(mainTopics.path, 'active.md'))
      ..writeAsStringSync('# Active\n');
    File(p.join(sharedRoot.path, 'writerside.cfg')).writeAsStringSync('''
<ihp><module name="shared"/><topics dir="topics"/><instance src="library.tree"/></ihp>
''');
    File(p.join(sharedRoot.path, 'library.tree')).writeAsStringSync('''
<instance-profile id="library" is-library="true"><toc-element topic="shared.md"/></instance-profile>
''');
    final shared = File(p.join(sharedTopics.path, 'shared.md'))
      ..writeAsStringSync('# Shared saved\n');
    final workspace = (await tester.runAsync(
      () => const WorkspaceService().openPath(root.path),
    ))!;
    final controller = _MutableWorkspaceController(
      WorkspaceState(
        workspace: workspace.copyWith(
          activeFilePath: active.path,
          openFilePaths: [shared.path, active.path],
        ),
        documentBuffers: [
          DocumentBuffer(
            id: 'shared',
            filePath: shared.path,
            text: '# Shared unsaved\n',
            lastSavedText: '# Shared saved\n',
            dirty: true,
          ),
          DocumentBuffer(
            id: 'active',
            filePath: active.path,
            text: '# Active\n',
            lastSavedText: '# Active\n',
            dirty: false,
          ),
        ],
        activeBufferId: 'active',
      ),
    );
    final container = ProviderContainer(
      overrides: [
        ..._smokeAccentOverrides,
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
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
    final en = AppLocalizationsEn();
    await tester.tap(find.byTooltip(en.sidebarViewMenu));
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.toc));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Shared saved'), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.copy));
    await tester.pumpAndSettle();
    expect(clipboardText, '# Shared unsaved\n');
  });

  testWidgets('TOC Paste reviews an inactive dirty tree before moving', (
    tester,
  ) async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.defaultRouteNameTestValue = '/workspace';
    addTearDown(
      () => binding.platformDispatcher.defaultRouteNameTestValue = '/',
    );
    final root = Directory.systemTemp.createTempSync(
      'busymark-toc-paste-tree-',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final topics = Directory(p.join(root.path, 'topics'))..createSync();
    File(p.join(root.path, 'writerside.cfg')).writeAsStringSync('''
<ihp><topics dir="topics"/><instance src="guide.tree"/></ihp>
''');
    final tree = File(p.join(root.path, 'guide.tree'))
      ..writeAsStringSync('''
<instance-profile id="guide" start-page="a.md">
  <toc-element topic="a.md"/>
  <toc-element topic="b.md"/>
</instance-profile>
''');
    File(p.join(topics.path, 'a.md')).writeAsStringSync('# Topic A\n');
    final active = File(p.join(topics.path, 'b.md'))
      ..writeAsStringSync('# Topic B\n');
    final workspace = (await tester.runAsync(
      () => const WorkspaceService().openPath(root.path),
    ))!;
    final controller = _MutableWorkspaceController(
      WorkspaceState(
        workspace: workspace.copyWith(
          activeFilePath: active.path,
          openFilePaths: [tree.path, active.path],
        ),
        documentBuffers: [
          DocumentBuffer(
            id: 'tree',
            filePath: tree.path,
            text: '${tree.readAsStringSync()}<!-- unsaved -->\n',
            lastSavedText: tree.readAsStringSync(),
            dirty: true,
          ),
          DocumentBuffer(
            id: 'active',
            filePath: active.path,
            text: '# Topic B\n',
            lastSavedText: '# Topic B\n',
            dirty: false,
          ),
        ],
        activeBufferId: 'active',
      ),
    );
    final container = ProviderContainer(
      overrides: [
        ..._smokeAccentOverrides,
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
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
    final en = AppLocalizationsEn();
    await tester.tap(find.byTooltip(en.sidebarViewMenu));
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.toc));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Topic A'), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(en.cut));
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.cut));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Topic B').first, buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(en.pasteAfterTopic));
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.pasteAfterTopic));
    await tester.pumpAndSettle();
    expect(find.text(en.unsavedChanges), findsOneWidget);
    expect(find.textContaining('guide.tree'), findsWidgets);
    expect(controller.movedTopicPlacement, isNull);
    await tester.tap(find.text(en.cancel));
    await tester.pumpAndSettle();
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
        ..._smokeAccentOverrides,
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

  Future<ProviderContainer> historyApp(
    WidgetTester tester,
    DocumentViewModePreference mode, {
    WorkspaceService? service,
    String startupPath = '/tmp/disposable-history.md',
    String initialSource = 'abc',
  }) async {
    final settings = _MemorySettingsStore()
      ..value = AppSettings.defaults()
          .copyWith(
            autoSave: false,
            validateOnEdit: false,
            documentViewMode: mode,
          )
          .toJson();
    final container = ProviderContainer(
      overrides: [
        ..._smokeAccentOverrides,
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(settings),
        workspaceServiceProvider.overrideWithValue(
          service ?? _SearchWorkspaceService(initialSource),
        ),
        localHistoryStoreProvider.overrideWithValue(MemoryLocalHistoryStore()),
        documentSessionStoreProvider.overrideWithValue(
          MemoryDocumentSessionStore(),
        ),
        documentRecoveryStoreProvider.overrideWithValue(
          MemoryDocumentRecoveryStore(),
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
    await _pumpUntilFound(
      tester,
      find.byType(
        mode == DocumentViewModePreference.source
            ? BusyMarkSourceEditor
            : BusyMarkWysiwygEditor,
      ),
    );
    return container;
  }

  Finder historyField(DocumentViewModePreference mode) => find
      .descendant(
        of: find.byType(
          mode == DocumentViewModePreference.source
              ? BusyMarkSourceEditor
              : BusyMarkWysiwygEditor,
        ),
        matching: find.byType(TextField),
      )
      .first;

  Future<void> historyKey(WidgetTester tester, {bool redo = false}) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    if (redo) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    if (redo) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  }

  for (final mode in [
    DocumentViewModePreference.source,
    DocumentViewModePreference.editor,
  ]) {
    testWidgets('${mode.name} exhausted keyboard history is a consumed no-op', (
      tester,
    ) async {
      final container = await historyApp(tester, mode);
      final workspace = container.read(workspaceControllerProvider.notifier);
      final field = historyField(mode);
      await tester.tap(field);
      await tester.showKeyboard(field);
      for (final text in ['abcd', 'abcde', 'abcdef']) {
        tester.testTextInput.updateEditingValue(
          TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          ),
        );
        // Populate Flutter's throttled field history as well as shared history.
        await tester.pump(const Duration(milliseconds: 600));
      }
      while (container
          .read(workspaceControllerProvider)
          .activeBuffer!
          .editorState
          .undoState
          .undo
          .isNotEmpty) {
        await historyKey(tester);
        await tester.pump(const Duration(milliseconds: 600));
      }
      for (final redo in [false, true]) {
        if (redo) {
          while (container
              .read(workspaceControllerProvider)
              .activeBuffer!
              .editorState
              .undoState
              .redo
              .isNotEmpty) {
            await historyKey(tester, redo: true);
            await tester.pump(const Duration(milliseconds: 600));
          }
        }
        final before = container
            .read(workspaceControllerProvider)
            .activeBuffer!;
        final history = container.read(localHistoryControllerProvider.notifier);
        final pending = history.pendingSnapshotForBuffer(before.id);
        for (var i = 0; i < 4; i++) {
          await historyKey(tester, redo: redo);
          await tester.pump(const Duration(milliseconds: 600));
        }
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        if (redo) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.keyZ);
        await tester.sendKeyRepeatEvent(LogicalKeyboardKey.keyZ);
        await tester.sendKeyRepeatEvent(LogicalKeyboardKey.keyZ);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.keyZ);
        if (redo) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pump();
        final after = container.read(workspaceControllerProvider).activeBuffer!;
        expect(after.text, before.text);
        expect(after.revision, before.revision);
        expect(after.dirty, before.dirty);
        expect(after.editorState.undoState, same(before.editorState.undoState));
        expect(history.pendingSnapshotForBuffer(before.id), same(pending));
        expect(
          tester.widget<TextField>(historyField(mode)).controller!.text,
          after.text,
        );
      }
      expect(workspace.undoActiveBuffer(), isTrue);
    });

    testWidgets('${mode.name} remapped history preserves search field undo', (
      tester,
    ) async {
      final container = await historyApp(tester, mode);
      final keymap = container.read(keymapControllerProvider.notifier);
      for (final entry in {
        BusyMarkCommandIds.textUndo: LogicalKeyboardKey.f9,
        BusyMarkCommandIds.textRedo: LogicalKeyboardKey.f10,
      }.entries) {
        expect(
          (await keymap.update(
            entry.key,
            BusyMarkKeyBinding(entry.value, control: true, alt: true),
            expected: container
                .read(appSettingsControllerProvider)
                .shortcutOverrides,
          )).status,
          KeymapUpdateStatus.saved,
        );
      }
      await tester.pump();
      await tester.showKeyboard(historyField(mode));
      tester.widget<TextField>(historyField(mode)).controller!.selection =
          const TextSelection.collapsed(offset: 3);
      await tester.enterText(historyField(mode), 'abcd');
      await tester.pump(const Duration(milliseconds: 600));
      await historyKey(tester);
      await tester.pump();
      expect(
        container.read(workspaceControllerProvider).activeText,
        'abcd',
        reason: 'The remapped default is blocked in document inputs',
      );

      Future<void> remapped(LogicalKeyboardKey key) async {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
        await tester.sendKeyEvent(key);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pump();
      }

      await remapped(LogicalKeyboardKey.f9);
      expect(container.read(workspaceControllerProvider).activeText, 'abc');
      final exhausted = container
          .read(workspaceControllerProvider)
          .activeBuffer!;
      await remapped(LogicalKeyboardKey.f9);
      expect(
        container.read(workspaceControllerProvider).activeBuffer!.revision,
        exhausted.revision,
      );
      await remapped(LogicalKeyboardKey.f10);
      expect(container.read(workspaceControllerProvider).activeText, 'abcd');
      final document = container
          .read(workspaceControllerProvider)
          .activeBuffer!;
      await remapped(LogicalKeyboardKey.f10);
      expect(
        container.read(workspaceControllerProvider).activeBuffer!.revision,
        document.revision,
      );

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      final query = find.descendant(
        of: find.byKey(const ValueKey('shared-search-query')),
        matching: find.byType(TextField),
      );
      await tester.showKeyboard(query);
      await tester.enterText(query, 'first query');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.enterText(query, 'second query');
      await tester.pump(const Duration(milliseconds: 600));
      await historyKey(tester);
      await tester.pump();
      expect(tester.widget<TextField>(query).controller!.text, 'first query');
      final after = container.read(workspaceControllerProvider).activeBuffer!;
      expect(after.text, document.text);
      expect(after.revision, document.revision);
      expect(after.editorState.undoState, same(document.editorState.undoState));
      container.read(searchSessionProvider.notifier).close(restoreFocus: false);
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets(
      '${mode.name} accepts typing after Local History restore traversal',
      (tester) async {
        final container = await historyApp(tester, mode);
        final workspace = container.read(workspaceControllerProvider.notifier);
        final store = container.read(localHistoryStoreProvider);
        final buffer = container
            .read(workspaceControllerProvider)
            .activeBuffer!;
        final capture = await tabOperation(
          tester,
          () => store.capture(
            LocalHistoryCaptureRequest(
              path: buffer.filePath,
              displayName: buffer.displayName,
              source: 'recoverable',
              format: buffer.format,
              capturedAt: DateTime(2026),
              reason: LocalHistoryCaptureReason.saved,
              force: true,
            ),
            container.read(localHistoryControllerProvider.notifier).policy,
          ),
        );
        final revision = await store.readRevision(capture.revision!.id);
        workspace.updateActiveText('latest branch');
        await tester.pump();
        expect(
          await tabOperation(
            tester,
            () => workspace.restoreLocalHistoryRevision(
              document: capture.document,
              revision: revision!,
            ),
          ),
          isTrue,
        );
        await tester.pump();
        await tester.showKeyboard(historyField(mode));
        await historyKey(tester);
        await tester.pump();
        expect(
          container.read(workspaceControllerProvider).activeText,
          'latest branch',
        );
        await historyKey(tester, redo: true);
        await tester.pump();
        expect(
          container.read(workspaceControllerProvider).activeText,
          'recoverable',
        );
        await tester.showKeyboard(historyField(mode));
        tester.widget<TextField>(historyField(mode)).controller!.selection =
            const TextSelection.collapsed(offset: 11);
        tester.testTextInput.updateEditingValue(
          const TextEditingValue(
            text: 'recoverabler',
            selection: TextSelection.collapsed(offset: 12),
          ),
        );
        await tester.pump();
        expect(
          container.read(workspaceControllerProvider).activeText,
          'recoverabler',
        );
        expect(
          tester.widget<TextField>(historyField(mode)).controller!.text,
          'recoverabler',
        );
      },
    );

    testWidgets('${mode.name} caret round trip closes typing transaction', (
      tester,
    ) async {
      final container = await historyApp(tester, mode);
      final field = historyField(mode);
      await tester.showKeyboard(field);
      final text = tester.widget<TextField>(field).controller!;
      text.selection = const TextSelection.collapsed(offset: 3);
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'abcd',
          selection: TextSelection.collapsed(offset: 4),
        ),
      );
      await tester.pump();
      text.selection = const TextSelection.collapsed(offset: 3);
      await tester.pump();
      text.selection = const TextSelection.collapsed(offset: 4);
      await tester.pump();
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'abcde',
          selection: TextSelection.collapsed(offset: 5),
        ),
      );
      await tester.pump();
      expect(
        container
            .read(workspaceControllerProvider)
            .activeBuffer!
            .editorState
            .undoState
            .undo,
        hasLength(2),
      );
      await historyKey(tester);
      await tester.pump();
      expect(container.read(workspaceControllerProvider).activeText, 'abcd');
      expect(text.text, 'abcd');
    });
  }

  for (final mode in [
    DocumentViewModePreference.source,
    DocumentViewModePreference.editor,
  ]) {
    testWidgets('${mode.name} sustained typing has finite undo size', (
      tester,
    ) async {
      final container = await historyApp(tester, mode);
      await tester.tap(historyField(mode));
      await tester.showKeyboard(historyField(mode));
      var text = 'abc';
      for (var i = 0; i < 180; i++) {
        text += mode == DocumentViewModePreference.source && i % 20 == 19
            ? '\n'
            : 'x';
        tester.testTextInput.updateEditingValue(
          TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          ),
        );
      }
      final undo = container
          .read(workspaceControllerProvider)
          .activeBuffer!
          .editorState
          .undoState;
      expect(undo.undo.length, greaterThan(1));
      await historyKey(tester);
      await tester.pump();
      expect(
        container.read(workspaceControllerProvider).activeText,
        isNot('abc'),
      );
    });
  }

  for (final mode in [
    DocumentViewModePreference.source,
    DocumentViewModePreference.editor,
  ]) {
    testWidgets(
      '${mode.name} typing and deletion direction are distinct transactions',
      (tester) async {
        final container = await historyApp(tester, mode);
        final field = historyField(mode);
        await tester.showKeyboard(field);
        tester.widget<TextField>(field).controller!.selection =
            const TextSelection.collapsed(offset: 2);
        final groups = <String?>[];
        for (final (text, caret) in [
          ('abxc', 3),
          ('abc', 2),
          ('ac', 1),
          ('a', 1),
        ]) {
          tester.testTextInput.updateEditingValue(
            TextEditingValue(
              text: text,
              selection: TextSelection.collapsed(offset: caret),
            ),
          );
          groups.add(
            container
                .read(workspaceControllerProvider)
                .activeBuffer!
                .editorState
                .undoState
                .activeGroup,
          );
        }
        expect(groups, everyElement(isNotNull));
        expect(groups[0], isNot(groups[1]));
        expect(groups[1], groups[2]);
        expect(groups[2], isNot(groups[3]));
        final before = container
            .read(workspaceControllerProvider)
            .activeBuffer!;
        await historyKey(tester);
        await tester.pump();
        expect(container.read(workspaceControllerProvider).activeText, 'ac');
        expect(before.editorState.undoState.undo.length, 3);
      },
    );

    testWidgets('${mode.name} platform history actions remain document owned', (
      tester,
    ) async {
      final container = await historyApp(tester, mode);
      final field = historyField(mode);
      await tester.enterText(field, 'abcd');
      await tester.pump(const Duration(milliseconds: 600));
      EditableTextState editable() => tester.state<EditableTextState>(
        find.descendant(of: field, matching: find.byType(EditableText)),
      );
      Actions.invoke(
        editable().context,
        const UndoTextIntent(SelectionChangedCause.keyboard),
      );
      await tester.pump();
      expect(container.read(workspaceControllerProvider).activeText, 'abc');
      final exhausted = container
          .read(workspaceControllerProvider)
          .activeBuffer!;
      for (var i = 0; i < 4; i++) {
        Actions.invoke(
          editable().context,
          const UndoTextIntent(SelectionChangedCause.keyboard),
        );
      }
      expect(
        container.read(workspaceControllerProvider).activeBuffer!.revision,
        exhausted.revision,
      );
      Actions.invoke(
        editable().context,
        const RedoTextIntent(SelectionChangedCause.keyboard),
      );
      await tester.pump();
      expect(container.read(workspaceControllerProvider).activeText, 'abcd');
      final redone = container.read(workspaceControllerProvider).activeBuffer!;
      Actions.invoke(
        editable().context,
        const RedoTextIntent(SelectionChangedCause.keyboard),
      );
      expect(
        container.read(workspaceControllerProvider).activeBuffer!.revision,
        redone.revision,
      );
    });

    testWidgets(
      '${mode.name} rejects a publication invalidated before parent rebuild',
      (tester) async {
        final container = await historyApp(tester, mode);
        final workspace = container.read(workspaceControllerProvider.notifier);
        await tester.enterText(historyField(mode), 'abcd');
        workspace.updateActiveText('authoritative');
        final revision = container
            .read(workspaceControllerProvider)
            .activeBuffer!
            .revision;
        tester.testTextInput.updateEditingValue(
          const TextEditingValue(
            text: 'abcdx',
            selection: TextSelection.collapsed(offset: 5),
          ),
        );
        expect(
          container.read(workspaceControllerProvider).activeText,
          'authoritative',
        );
        expect(
          container.read(workspaceControllerProvider).activeBuffer!.revision,
          revision,
        );
        await tester.pump();
        expect(
          tester.widget<TextField>(historyField(mode)).controller!.text,
          'authoritative',
        );
        await tester.enterText(historyField(mode), 'authoritativex');
        expect(
          container.read(workspaceControllerProvider).activeText,
          'authoritativex',
        );
      },
    );
  }

  for (final mode in [
    DocumentViewModePreference.source,
    DocumentViewModePreference.editor,
  ]) {
    testWidgets(
      '${mode.name} authoritative traversal restores the historical caret',
      (tester) async {
        final container = await historyApp(tester, mode);
        final workspace = container.read(workspaceControllerProvider.notifier);
        await tester.showKeyboard(historyField(mode));
        tester.widget<TextField>(historyField(mode)).controller!.selection =
            const TextSelection.collapsed(offset: 1);
        await tester.pump();
        tester.testTextInput.updateEditingValue(
          const TextEditingValue(
            text: 'aXbc',
            selection: TextSelection.collapsed(offset: 2),
          ),
        );
        await tester.pump();
        expect(workspace.undoActiveBuffer(), isTrue);
        await tester.pump();
        expect(
          tester.widget<TextField>(historyField(mode)).controller!.text,
          'abc',
        );
        expect(
          tester.widget<TextField>(historyField(mode)).controller!.selection,
          const TextSelection.collapsed(offset: 1),
        );
        expect(workspace.redoActiveBuffer(), isTrue);
        await tester.pump();
        expect(
          tester.widget<TextField>(historyField(mode)).controller!.text,
          'aXbc',
        );
        expect(
          tester.widget<TextField>(historyField(mode)).controller!.selection,
          const TextSelection.collapsed(offset: 2),
        );
      },
    );
  }

  testWidgets('WYSIWYG Save As updates the mounted publication path', (
    tester,
  ) async {
    final root = await tester.runAsync(
      () => Directory.systemTemp.createTemp('busymark-history-save-as-'),
    );
    addTearDown(() async {
      if (await root!.exists()) await root.delete(recursive: true);
    });
    final original = File('${root!.path}/original.md');
    final destination = '${root.path}/renamed.md';
    await tester.runAsync(() => original.writeAsString('abc'));
    const mode = DocumentViewModePreference.editor;
    final container = await historyApp(
      tester,
      mode,
      service: const WorkspaceService(),
      startupPath: original.path,
    );
    await tester.enterText(historyField(mode), 'abcd');
    await tester.pump();
    final workspace = container.read(workspaceControllerProvider.notifier);
    expect(
      await tabOperation(tester, () => workspace.saveActiveAs(destination)),
      isTrue,
    );
    await tester.pump();
    await tester.enterText(historyField(mode), 'abcdx');
    await tester.pump();
    expect(container.read(workspaceControllerProvider).activeText, 'abcdx');
    expect(
      tester
          .widget<BusyMarkWysiwygEditor>(find.byType(BusyMarkWysiwygEditor))
          .document
          .filePath,
      destination,
    );
    await historyKey(tester);
    await tester.pump();
    expect(container.read(workspaceControllerProvider).activeText, 'abcd');
  });

  for (final mode in [
    DocumentViewModePreference.source,
    DocumentViewModePreference.editor,
  ]) {
    for (final deletion in [false, true]) {
      testWidgets(
        '${mode.name} repeated-character ${deletion ? "deletion" : "typing"} groups at the actual caret',
        (tester) async {
          final initial = deletion ? 'aaaaaa' : 'aaaa';
          final container = await historyApp(
            tester,
            mode,
            initialSource: initial,
          );
          await tester.showKeyboard(historyField(mode));
          tester.widget<TextField>(historyField(mode)).controller!.selection =
              TextSelection.collapsed(offset: deletion ? 4 : 2);
          for (final (text, caret)
              in deletion
                  ? [('aaaaa', 3), ('aaaa', 2)]
                  : [('aaaaa', 3), ('aaaaaa', 4), ('aaaaaaa', 5)]) {
            tester.testTextInput.updateEditingValue(
              TextEditingValue(
                text: text,
                selection: TextSelection.collapsed(offset: caret),
              ),
            );
          }
          expect(
            container
                .read(workspaceControllerProvider)
                .activeBuffer!
                .editorState
                .undoState
                .undo,
            hasLength(1),
          );
          await historyKey(tester);
          await tester.pump();
          expect(
            container.read(workspaceControllerProvider).activeText,
            initial,
          );
        },
      );
    }
  }

  testWidgets(
    'Source to Split closes the group without dropping a no-frame edit',
    (tester) async {
      const mode = DocumentViewModePreference.source;
      final container = await historyApp(tester, mode);
      await tester.showKeyboard(historyField(mode));
      tester.widget<TextField>(historyField(mode)).controller!.selection =
          const TextSelection.collapsed(offset: 3);
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'abcd',
          selection: TextSelection.collapsed(offset: 4),
        ),
      );
      await tester.pump();
      final workspace = container.read(workspaceControllerProvider.notifier);
      workspace.updateActiveEditorMode(DocumentViewModePreference.split);
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'abcdx',
          selection: TextSelection.collapsed(offset: 5),
        ),
      );
      expect(container.read(workspaceControllerProvider).activeText, 'abcdx');
      expect(
        container
            .read(workspaceControllerProvider)
            .activeBuffer!
            .editorState
            .undoState
            .undo,
        hasLength(2),
      );
      expect(workspace.undoActiveBuffer(), isTrue);
      await tester.pump();
      expect(container.read(workspaceControllerProvider).activeText, 'abcd');
      expect(
        tester.widget<TextField>(historyField(mode)).controller!.text,
        'abcd',
      );
    },
  );

  testWidgets('WYSIWYG remount starts a distinct undo group', (tester) async {
    const mode = DocumentViewModePreference.editor;
    final container = await historyApp(tester, mode);
    final workspace = container.read(workspaceControllerProvider.notifier);
    await tester.showKeyboard(historyField(mode));
    tester.widget<TextField>(historyField(mode)).controller!.selection =
        const TextSelection.collapsed(offset: 3);
    await tester.enterText(historyField(mode), 'abcd');
    await tester.pump();
    final first = container.read(workspaceControllerProvider).activeBuffer!;
    expect(first.editorState.undoState.activeGroup, isNotNull);
    workspace.updateActiveEditorMode(DocumentViewModePreference.preview);
    await container
        .read(appSettingsControllerProvider.notifier)
        .setDocumentViewMode(DocumentViewModePreference.preview);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(BusyMarkWysiwygEditor), findsNothing);
    workspace.updateActiveEditorMode(mode);
    await container
        .read(appSettingsControllerProvider.notifier)
        .setDocumentViewMode(mode);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.showKeyboard(historyField(mode));
    tester.widget<TextField>(historyField(mode)).controller!.selection =
        const TextSelection.collapsed(offset: 4);
    await tester.enterText(historyField(mode), 'abcde');
    await tester.pump();
    final second = container.read(workspaceControllerProvider).activeBuffer!;
    expect(
      second.editorState.undoState.activeGroup,
      isNot(first.editorState.undoState.activeGroup),
    );
    await historyKey(tester);
    await tester.pump();
    expect(container.read(workspaceControllerProvider).activeText, 'abcd');
    expect(
      tester.widget<TextField>(historyField(mode)).controller!.text,
      'abcd',
    );
  });

  for (final beforeFrame in [false, true]) {
    testWidgets(
      'WYSIWYG same-frame traversal and next edit (early=$beforeFrame)',
      (tester) async {
        const mode = DocumentViewModePreference.editor;
        final container = await historyApp(tester, mode);
        final workspace = container.read(workspaceControllerProvider.notifier);
        await tester.enterText(historyField(mode), 'abcd');
        expect(container.read(workspaceControllerProvider).activeText, 'abcd');
        await historyKey(tester);
        expect(container.read(workspaceControllerProvider).activeText, 'abc');
        expect(
          tester
              .state<BusyMarkWysiwygEditorState>(
                find.byType(BusyMarkWysiwygEditor),
              )
              .serializedSource,
          'abc',
        );
        if (!beforeFrame) await tester.pump();
        final controller = tester
            .widget<TextField>(historyField(mode))
            .controller!;
        if (!beforeFrame) expect(controller.text, 'abc');
        // Native input may arrive before the parent has acknowledged Undo.
        tester.testTextInput.updateEditingValue(
          TextEditingValue(
            text: '${controller.text}x',
            selection: TextSelection.collapsed(
              offset: controller.text.length + 1,
            ),
          ),
        );
        await tester.pump();
        final current = container.read(workspaceControllerProvider).activeText;
        expect(current, 'abcx');
        expect(
          tester
              .state<BusyMarkWysiwygEditorState>(
                find.byType(BusyMarkWysiwygEditor),
              )
              .serializedSource,
          current,
        );
        expect(
          tester.widget<TextField>(historyField(mode)).controller!.text,
          current,
        );
        expect(
          tester
              .widget<BusyMarkWysiwygEditor>(find.byType(BusyMarkWysiwygEditor))
              .document
              .source,
          current,
        );
        expect(workspace.redoActiveBuffer(), isFalse);
      },
    );
  }

  testWidgets(
    'rich traversal bursts reconcile live serialization without frames',
    (tester) async {
      const mode = DocumentViewModePreference.editor;
      final container = await historyApp(tester, mode);
      final field = historyField(mode);
      await tester.showKeyboard(field);
      final text = tester.widget<TextField>(field).controller!;
      text.selection = const TextSelection.collapsed(offset: 3);
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'abcd',
          selection: TextSelection.collapsed(offset: 4),
        ),
      );
      text.selection = const TextSelection.collapsed(offset: 0);
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'Xabcd',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      final rich = tester.state<BusyMarkWysiwygEditorState>(
        find.byType(BusyMarkWysiwygEditor),
      );
      void agrees(String expected, int caret) {
        expect(
          container.read(workspaceControllerProvider).activeText,
          expected,
        );
        expect(text.text, expected);
        expect(rich.serializedSource, expected);
        expect(text.selection, TextSelection.collapsed(offset: caret));
      }

      agrees('Xabcd', 1);
      for (var i = 0; i < 5; i++) {
        await historyKey(tester);
        agrees('abcd', 0);
        await historyKey(tester);
        agrees('abc', 3);
        await historyKey(tester, redo: true);
        agrees('abcd', 0);
        await historyKey(tester, redo: true);
        agrees('Xabcd', 1);
      }
      await historyKey(tester);
      agrees('abcd', 0);
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'xabcd',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      agrees('xabcd', 1);
      await tester.pump();
      agrees('xabcd', 1);
      expect(
        tester
            .widget<BusyMarkWysiwygEditor>(find.byType(BusyMarkWysiwygEditor))
            .document
            .source,
        'xabcd',
      );
      expect(
        container.read(workspaceControllerProvider.notifier).redoActiveBuffer(),
        isFalse,
      );
    },
  );

  testWidgets(
    'rich group boundaries capture the live pre-edit caret without frames',
    (tester) async {
      const mode = DocumentViewModePreference.editor;
      final container = await historyApp(tester, mode);
      await tester.showKeyboard(historyField(mode));
      final text = tester.widget<TextField>(historyField(mode)).controller!;
      text.selection = const TextSelection.collapsed(offset: 3);
      await tester.pump();
      await tester.pump();
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'abcd',
          selection: TextSelection.collapsed(offset: 4),
        ),
      );
      text.selection = const TextSelection.collapsed(offset: 0);
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'Xabcd',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      final history = container
          .read(workspaceControllerProvider)
          .activeBuffer!
          .editorState
          .undoState;
      expect(history.undo, hasLength(2));
      expect(history.undo.last.text, 'abcd');
      expect(history.undo.last.wysiwygState.anchorOffset, 0);
      expect(history.undo.first.wysiwygState.anchorOffset, 3);
    },
  );

  testWidgets('rich no-frame Undo restores the caret before the next input', (
    tester,
  ) async {
    const mode = DocumentViewModePreference.editor;
    final container = await historyApp(tester, mode, initialSource: 'abcdef');
    final field = historyField(mode);
    await tester.showKeyboard(field);
    final text = tester.widget<TextField>(field).controller!;
    text.selection = const TextSelection.collapsed(offset: 3);
    await tester.pump();
    await tester.pump();
    expect(
      container
          .read(workspaceControllerProvider)
          .activeBuffer!
          .editorState
          .wysiwygState
          .anchorOffset,
      3,
    );
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'abcXdef',
        selection: TextSelection.collapsed(offset: 4),
      ),
    );
    await tester.pump();
    await tester.pump();
    await historyKey(tester);
    expect(container.read(workspaceControllerProvider).activeText, 'abcdef');
    expect(text.selection, const TextSelection.collapsed(offset: 3));
    final caret = text.selection.extentOffset;
    tester.testTextInput.updateEditingValue(
      TextEditingValue(
        text: text.text.replaceRange(caret, caret, 'Y'),
        selection: TextSelection.collapsed(offset: caret + 1),
      ),
    );
    expect(container.read(workspaceControllerProvider).activeText, 'abcYdef');
    await tester.pump();
    expect(text.selection, const TextSelection.collapsed(offset: 4));
  });

  testWidgets(
    'rich table traversal restores cell focus and caret without a frame',
    (tester) async {
      const mode = DocumentViewModePreference.editor;
      const source = '| One | Two |\n| --- | --- |\n| abcdef | ghijkl |\n';
      final container = await historyApp(tester, mode, initialSource: source);
      Finder cell(String value) => find
          .descendant(
            of: find.byType(BusyMarkWysiwygEditor),
            matching: find.byWidgetPredicate(
              (w) => w is TextField && w.controller?.text == value,
            ),
          )
          .first;
      final first = cell('abcdef');
      await tester.showKeyboard(first);
      final a = tester.widget<TextField>(first);
      a.controller!.selection = const TextSelection.collapsed(offset: 3);
      await tester.pump();
      await tester.pump();
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'abcXdef',
          selection: TextSelection.collapsed(offset: 4),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.showKeyboard(cell('ghijkl'));
      final b = tester.widget<TextField>(cell('ghijkl'));
      b.controller!.selection = const TextSelection.collapsed(offset: 2);
      await tester.pump();
      await tester.pump();
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'ghYijkl',
          selection: TextSelection.collapsed(offset: 3),
        ),
      );
      await tester.pump();
      await tester.pump();
      await historyKey(tester);
      expect(b.controller!.text, 'ghijkl');
      expect(b.controller!.selection, const TextSelection.collapsed(offset: 2));
      await historyKey(tester);
      expect(container.read(workspaceControllerProvider).activeText, source);
      expect(a.controller!.text, 'abcdef');
      expect(a.controller!.selection, const TextSelection.collapsed(offset: 3));
      expect(a.focusNode!.hasPrimaryFocus, isTrue);
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'abcYdef',
          selection: TextSelection.collapsed(offset: 4),
        ),
      );
      expect(
        container.read(workspaceControllerProvider).activeText,
        contains('abcYdef'),
      );
      final rich = tester.state<BusyMarkWysiwygEditorState>(
        find.byType(BusyMarkWysiwygEditor),
      );
      expect(
        rich.serializedSource,
        container.read(workspaceControllerProvider).activeText,
      );
      await tester.pump();
      expect(a.controller!.selection, const TextSelection.collapsed(offset: 4));
    },
  );

  testWidgets(
    'rich no-frame Undo restores document selection command ownership',
    (tester) async {
      const mode = DocumentViewModePreference.editor;
      const source = 'abc\n\ndef';
      final container = await historyApp(tester, mode, initialSource: source);
      await tester.showKeyboard(historyField(mode));
      for (var i = 0; i < 2; i++) {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      }
      await tester.pump();
      await tester.pump();
      final selected = container
          .read(workspaceControllerProvider)
          .activeBuffer!
          .editorState
          .wysiwygState;
      expect(selected.anchorBlockId, isNot(selected.extentBlockId));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      await tester.pump();
      expect(
        container.read(workspaceControllerProvider).activeText,
        contains('**abc**'),
      );
      await historyKey(tester);
      expect(container.read(workspaceControllerProvider).activeText, source);
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      expect(container.read(workspaceControllerProvider).activeText, isEmpty);
      await tester.pump();
    },
  );

  testWidgets('rich caret movement supersedes a pending traversal restore', (
    tester,
  ) async {
    const mode = DocumentViewModePreference.editor;
    final container = await historyApp(tester, mode, initialSource: 'abcdef');
    await tester.showKeyboard(historyField(mode));
    final text = tester.widget<TextField>(historyField(mode)).controller!;
    text.selection = const TextSelection.collapsed(offset: 3);
    await tester.pump();
    await tester.pump();
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'abcXdef',
        selection: TextSelection.collapsed(offset: 4),
      ),
    );
    await tester.pump();
    await tester.pump();
    await historyKey(tester);
    expect(container.read(workspaceControllerProvider).activeText, 'abcdef');
    text.selection = const TextSelection.collapsed(offset: 1);
    await tester.pump();
    expect(text.selection, const TextSelection.collapsed(offset: 1));
  });

  testWidgets(
    'rich formatting captures a new document range before any frame',
    (tester) async {
      const mode = DocumentViewModePreference.editor;
      const source = 'abc\n\ndef';
      final container = await historyApp(tester, mode, initialSource: source);
      await tester.showKeyboard(historyField(mode));
      for (var i = 0; i < 2; i++) {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      }
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      expect(
        container.read(workspaceControllerProvider).activeText,
        contains('**abc**'),
      );
      final before = container
          .read(workspaceControllerProvider)
          .activeBuffer!
          .editorState
          .undoState
          .undo
          .last;
      expect(before.text, source);
      expect(
        before.wysiwygState.anchorBlockId,
        isNot(before.wysiwygState.extentBlockId),
      );
      expect(before.wysiwygState.anchorOffset, 0);
      expect(before.wysiwygState.extentOffset, 3);
    },
  );

  testWidgets('Source groups typing and deletion undo with historical carets', (
    tester,
  ) async {
    const source = 'abc';
    const startupPath = '/tmp/source-grouped-undo.md';
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
        ..._smokeAccentOverrides,
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
    for (var index = 0; index < 30; index += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(BusyMarkSourceEditor).evaluate().isNotEmpty) {
        break;
      }
    }

    final sourceField = find.descendant(
      of: find.byType(BusyMarkSourceEditor),
      matching: find.byType(TextField),
    );
    await tester.tap(sourceField);
    await tester.showKeyboard(sourceField);
    final textController = tester.widget<TextField>(sourceField).controller!;
    textController.selection = const TextSelection.collapsed(offset: 1);
    await tester.pump();

    for (final (text, caret) in const [
      ('awbc', 2),
      ('awobc', 3),
      ('aworbc', 4),
      ('awordbc', 5),
    ]) {
      tester.testTextInput.updateEditingValue(
        TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: caret),
        ),
      );
      await tester.pump();
    }

    final buffer = container.read(workspaceControllerProvider).activeBuffer!;
    expect(buffer.editorState.undoState.undo.map((state) => state.text), [
      source,
    ]);
    expect(buffer.text, 'awordbc');

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(textController.text, source);
    expect(textController.selection, const TextSelection.collapsed(offset: 1));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(textController.text, 'awordbc');
    expect(textController.selection, const TextSelection.collapsed(offset: 5));

    for (final (text, caret) in const [('aworbc', 4), ('awobc', 3)]) {
      tester.testTextInput.updateEditingValue(
        TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: caret),
        ),
      );
      await tester.pump();
    }

    expect(
      container
          .read(workspaceControllerProvider)
          .activeBuffer!
          .editorState
          .undoState
          .undo
          .map((state) => state.text),
      [source, 'awordbc'],
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(textController.text, 'awordbc');
    expect(textController.selection, const TextSelection.collapsed(offset: 5));

    textController.selection = const TextSelection.collapsed(offset: 1);
    await tester.pump();
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'aXwordbc',
        selection: TextSelection.collapsed(offset: 2),
      ),
    );
    await tester.pump();
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'aXYZwordbc',
        selection: TextSelection.collapsed(offset: 4),
      ),
    );
    await tester.pump();

    expect(
      container
          .read(workspaceControllerProvider)
          .activeBuffer!
          .editorState
          .undoState
          .undo
          .map((state) => state.text),
      [source, 'awordbc', 'aXwordbc'],
    );

    for (final (text, caret) in const [('aXwordbc', 2), ('awordbc', 1)]) {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      expect(textController.text, text);
      expect(textController.selection, TextSelection.collapsed(offset: caret));
    }
  });

  testWidgets('Source remount starts a distinct undo group', (tester) async {
    const source = 'abc';
    const startupPath = '/tmp/source-remount-undo.md';
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
        ..._smokeAccentOverrides,
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
    for (var index = 0; index < 30; index += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(BusyMarkSourceEditor).evaluate().isNotEmpty) {
        break;
      }
    }

    Finder sourceField() => find.descendant(
      of: find.byType(BusyMarkSourceEditor),
      matching: find.byType(TextField),
    );

    await tester.tap(sourceField());
    await tester.showKeyboard(sourceField());
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'abcd',
        selection: TextSelection.collapsed(offset: 4),
      ),
    );
    await tester.pump();
    final firstGroup = container
        .read(workspaceControllerProvider)
        .activeBuffer!
        .editorState
        .undoState
        .activeGroup;
    expect(firstGroup, isNotNull);

    container
        .read(workspaceControllerProvider.notifier)
        .updateActiveEditorMode(DocumentViewModePreference.preview);
    await container
        .read(appSettingsControllerProvider.notifier)
        .setDocumentViewMode(DocumentViewModePreference.preview);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(BusyMarkSourceEditor), findsNothing);

    container
        .read(workspaceControllerProvider.notifier)
        .updateActiveEditorMode(DocumentViewModePreference.source);
    await container
        .read(appSettingsControllerProvider.notifier)
        .setDocumentViewMode(DocumentViewModePreference.source);
    for (var index = 0; index < 10; index += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(BusyMarkSourceEditor).evaluate().isNotEmpty) {
        break;
      }
    }

    await tester.tap(sourceField());
    await tester.showKeyboard(sourceField());
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'abcde',
        selection: TextSelection.collapsed(offset: 5),
      ),
    );
    await tester.pump();

    final remountedBuffer = container
        .read(workspaceControllerProvider)
        .activeBuffer!;
    expect(
      remountedBuffer.editorState.undoState.activeGroup,
      isNot(firstGroup),
    );
    expect(
      remountedBuffer.editorState.undoState.undo.map((state) => state.text),
      [source, 'abcd'],
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    final remountedController = tester
        .widget<TextField>(sourceField())
        .controller!;
    expect(remountedController.text, 'abcd');
    expect(remountedController.selection.isCollapsed, isTrue);
    expect(remountedController.selection.extentOffset, 4);
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
            automaticSpelling: false,
          )
          .toJson();
    final container = ProviderContainer(
      overrides: [
        ..._smokeAccentOverrides,
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

    await pressShortcut(LogicalKeyboardKey.minus, control: true, shift: true);
    expect(
      container.read(workspaceControllerProvider).activeText,
      'line\n---\n',
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
        ..._smokeAccentOverrides,
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
          ..._smokeAccentOverrides,
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
          '(${BusyMarkEditorShortcuts.unorderedList.label})';
      final orderedTooltip =
          '${l10n.orderedList} '
          '(${BusyMarkEditorShortcuts.orderedList.label})';
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
          .copyWith(
            documentViewMode: DocumentViewModePreference.editor,
            automaticSpelling: false,
          )
          .toJson();
    const service = _SearchWorkspaceService(
      '# Shared document frame\n\nParagraph line one\nParagraph line two\n',
    );
    final container = ProviderContainer(
      overrides: [
        ..._smokeAccentOverrides,
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

  testWidgets(
    'rendered views ignore redundant blanks while Source preserves them',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const source =
          '# Test Title 1\n'
          '\n'
          'Lorem ipsum dolor\n'
          '\n'
          '\n'
          '\n'
          'Lorem ipsume dolor 2\n'
          '\n'
          '\n'
          'Sincerely,\n'
          '\n'
          'User name\n';
      final settingsStore = _MemorySettingsStore()
        ..value = AppSettings.defaults()
            .copyWith(documentViewMode: DocumentViewModePreference.editor)
            .toJson();
      const service = _SearchWorkspaceService(source);
      final container = ProviderContainer(
        overrides: [
          ..._smokeAccentOverrides,
          linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
          localSettingsStoreProvider.overrideWithValue(settingsStore),
          workspaceServiceProvider.overrideWithValue(service),
          startupPathProvider.overrideWithValue('/tmp/empty-paragraphs.md'),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BusyMarkApp(),
        ),
      );
      final editorContent = find.byKey(
        const ValueKey('wysiwyg-document-content'),
      );
      final editorScroll = find.byKey(
        const ValueKey('wysiwyg-document-scroll'),
      );
      final editorFieldFinder = find.descendant(
        of: editorScroll,
        matching: find.byType(TextField),
      );
      for (
        var i = 0;
        i < 30 && editorFieldFinder.evaluate().length != 5;
        i += 1
      ) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(editorContent, findsOneWidget);
      final editorFields = tester
          .widgetList<TextField>(editorFieldFinder)
          .toList();
      final editorEmptyFields = editorFields
          .where((field) => field.controller?.text.isEmpty ?? false)
          .toList();
      expect(editorFields, hasLength(5));
      expect(editorEmptyFields, isEmpty);
      final editorContentTops = [
        for (var index = 0; index < editorFields.length; index += 1)
          tester.getTopLeft(editorFieldFinder.at(index)).dy,
      ];

      container
          .read(workspaceControllerProvider.notifier)
          .updateActiveEditorMode(DocumentViewModePreference.preview);
      await container
          .read(appSettingsControllerProvider.notifier)
          .setDocumentViewMode(DocumentViewModePreference.preview);
      await tester.pump(const Duration(milliseconds: 100));
      final previewScroll = find.byKey(
        const ValueKey('preview-document-scroll'),
      );
      final previewContentFinders = [
        for (final text in const [
          'Test Title 1',
          'Lorem ipsum dolor',
          'Lorem ipsume dolor 2',
          'Sincerely,',
          'User name',
        ])
          find.descendant(
            of: previewScroll,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Text && widget.textSpan?.toPlainText() == text,
            ),
          ),
      ];
      for (final finder in previewContentFinders) {
        expect(finder, findsOneWidget);
      }
      final previewContentTops = [
        for (final finder in previewContentFinders)
          tester.getTopLeft(finder).dy,
      ];
      for (var index = 1; index < previewContentTops.length; index += 1) {
        expect(
          previewContentTops[index] - previewContentTops.first,
          closeTo(editorContentTops[index] - editorContentTops.first, 0.1),
        );
      }
      expect(find.text(l10n.untitledResult), findsNothing);

      container
          .read(workspaceControllerProvider.notifier)
          .updateActiveEditorMode(DocumentViewModePreference.source);
      await container
          .read(appSettingsControllerProvider.notifier)
          .setDocumentViewMode(DocumentViewModePreference.source);
      final sourceEditor = find.byType(BusyMarkSourceEditor);
      for (var i = 0; i < 30 && sourceEditor.evaluate().isEmpty; i += 1) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final sourceField = find.descendant(
        of: sourceEditor,
        matching: find.byType(TextField),
      );
      expect(sourceField, findsOneWidget);
      expect(tester.widget<TextField>(sourceField).controller?.text, source);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'standalone HTML breaks preserve one blank line in every document view',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const source = 'Before\n<br>\n<br>\nAfter\n';
      const renderedText = 'Before\n\nAfter';
      final settingsStore = _MemorySettingsStore()
        ..value = AppSettings.defaults()
            .copyWith(documentViewMode: DocumentViewModePreference.editor)
            .toJson();
      const service = _SearchWorkspaceService(source);
      final container = ProviderContainer(
        overrides: [
          ..._smokeAccentOverrides,
          linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
          localSettingsStoreProvider.overrideWithValue(settingsStore),
          workspaceServiceProvider.overrideWithValue(service),
          startupPathProvider.overrideWithValue('/tmp/explicit-blank-line.md'),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BusyMarkApp(),
        ),
      );
      final editorScroll = find.byKey(
        const ValueKey('wysiwyg-document-scroll'),
      );
      final editorField = find.descendant(
        of: editorScroll,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is TextField && widget.controller?.text == renderedText,
        ),
      );
      for (var i = 0; i < 30 && editorField.evaluate().isEmpty; i += 1) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(editorField, findsOneWidget);

      container
          .read(workspaceControllerProvider.notifier)
          .updateActiveEditorMode(DocumentViewModePreference.preview);
      await container
          .read(appSettingsControllerProvider.notifier)
          .setDocumentViewMode(DocumentViewModePreference.preview);
      await tester.pump(const Duration(milliseconds: 100));
      final previewScroll = find.byKey(
        const ValueKey('preview-document-scroll'),
      );
      expect(
        find.descendant(
          of: previewScroll,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Text &&
                widget.textSpan?.toPlainText() == renderedText,
          ),
        ),
        findsOneWidget,
      );

      container
          .read(workspaceControllerProvider.notifier)
          .updateActiveEditorMode(DocumentViewModePreference.source);
      await container
          .read(appSettingsControllerProvider.notifier)
          .setDocumentViewMode(DocumentViewModePreference.source);
      final sourceEditor = find.byType(BusyMarkSourceEditor);
      for (var i = 0; i < 30 && sourceEditor.evaluate().isEmpty; i += 1) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final sourceField = find.descendant(
        of: sourceEditor,
        matching: find.byType(TextField),
      );
      expect(sourceField, findsOneWidget);
      expect(tester.widget<TextField>(sourceField).controller?.text, source);
      expect(tester.takeException(), isNull);
    },
  );

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
        ..._smokeAccentOverrides,
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
          .copyWith(
            documentViewMode: DocumentViewModePreference.editor,
            automaticSpelling: false,
          )
          .toJson();
    const service = _SearchWorkspaceService('> Shared quote.\n');
    final container = ProviderContainer(
      overrides: [
        ..._smokeAccentOverrides,
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
            automaticSpelling: false,
          )
          .toJson();
    const service = _SearchWorkspaceService('```dart\n$code\n```\n\nمرحبا\n');
    final container = ProviderContainer(
      overrides: [
        ..._smokeAccentOverrides,
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
          .copyWith(
            documentViewMode: DocumentViewModePreference.editor,
            automaticSpelling: false,
          )
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
        ..._smokeAccentOverrides,
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
          .copyWith(
            documentViewMode: DocumentViewModePreference.editor,
            automaticSpelling: false,
          )
          .toJson();
    const source = '''
<warning>Shared warning.</warning>

![Shared image](missing.png){ width="320" }
''';
    final root = Directory('test/fixtures/writerside/basic_project').absolute;
    const service = WorkspaceService();
    final workspace = (await tester.runAsync(
      () => service.openPath(root.path),
    ))!;
    final activeBuffer = DocumentBuffer(
      id: 'writerside-rich-blocks-active',
      filePath: workspace.activeFilePath,
      text: source,
      lastSavedText: source,
      dirty: false,
      editorState: const DocumentEditorState(
        mode: DocumentViewModePreference.editor,
      ),
    );
    final preview = service.buildDocumentPreview(workspace, activeBuffer);
    final controller = _MutableWorkspaceController(
      WorkspaceState(
        workspace: workspace,
        preview: preview,
        documentBuffers: [activeBuffer],
        activeBufferId: activeBuffer.id,
      ),
    );
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.defaultRouteNameTestValue = '/workspace';
    addTearDown(() {
      binding.platformDispatcher.defaultRouteNameTestValue = '/';
    });
    final container = ProviderContainer(
      overrides: [
        ..._smokeAccentOverrides,
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
    for (var i = 0; i < 30; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(BusyMarkDocumentAdmonition).evaluate().isNotEmpty &&
          find.byType(MarkdownImageView).evaluate().isNotEmpty) {
        break;
      }
    }
    await tester.pump(BusyMarkMotion.bannerReveal);
    final spellingBanner = find.byType(BusyMarkBanner);
    expect(tester.widget<BusyMarkBanner>(spellingBanner).revealed, isFalse);
    expect(tester.getSize(spellingBanner).height, 0);

    final editorAdmonition = find.byType(BusyMarkDocumentAdmonition);
    final editorImage = find.byType(MarkdownImageView);
    expect(editorAdmonition, findsOneWidget);
    expect(editorImage, findsOneWidget);
    // The utility pane starts closed; hover access must not open it.
    expect(find.byType(BusyMarkWritersideProperties), findsNothing);
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
        ..._smokeAccentOverrides,
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
        ..._smokeAccentOverrides,
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
        ..._smokeAccentOverrides,
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

  testWidgets(
    'close waits for adopted recovery and shortcut persistence before Cancel',
    (tester) async {
      final nativeWindow = _FakeNativeWindowController();
      final recovery = _GatedRecoveryAdoptionStore()
        ..value = RecoverySnapshot(
          cleanShutdown: false,
          entries: [
            DocumentRecoveryEntry.fromBuffer(
              DocumentBuffer.untitled(
                id: 'combined-recovery',
                name: 'Recovered draft',
                text: '# Retained edit\n',
              ),
              workspacePath: null,
            ),
          ],
        );
      final recent = RecentResource(
        path: '',
        kind: 'nextcloudNote',
        document: true,
        accountId: 'retained-account',
        localId: 'retained-note',
        title: 'Retained Recent',
        lastOpenedAt: DateTime.utc(2026, 10, 20),
      );
      final settings = _GatedRecentSettingsStore(fail: false)
        ..value = AppSettings.defaults()
            .copyWith(
              autoSave: false,
              reopenPreviousWorkspaceOnStartup: false,
              recentWorkspaces: [recent],
            )
            .toJson();
      addTearDown(() {
        if (!recovery.release.isCompleted) recovery.release.complete();
        if (!settings.release.isCompleted) settings.release.complete();
      });
      final container = ProviderContainer(
        overrides: [
          ..._smokeAccentOverrides,
          linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
          localSettingsStoreProvider.overrideWithValue(settings),
          nativeWindowControllerProvider.overrideWithValue(nativeWindow),
          localHistoryStoreProvider.overrideWithValue(
            MemoryLocalHistoryStore(),
          ),
          documentSessionStoreProvider.overrideWithValue(
            MemoryDocumentSessionStore(),
          ),
          documentRecoveryStoreProvider.overrideWithValue(recovery),
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
      await pumpUntil(
        tester,
        () => recovery.adopted.isCompleted,
        operation: 'recovery ownership adoption',
      );
      expect(container.read(workspaceControllerProvider).workspace, isNull);
      expect(recovery.value.entries.single.ownerId, recovery.ownerId);
      final shortcutSave = container
          .read(appSettingsControllerProvider.notifier)
          .saveShortcutOverrides({
            'file.save': const BusyMarkKeyBinding(LogicalKeyboardKey.f8),
          });
      await tester.pump();
      expect(settings.entered.isCompleted, isTrue);
      nativeWindow.listeners.single.onWindowClose();
      await tester.pump();
      expect(find.text(l10n.closeUnsavedChangesTitle), findsNothing);
      expect(nativeWindow.closeCount, 0);
      recovery.release.complete();
      await pumpUntil(
        tester,
        () => container.read(workspaceControllerProvider).activeBuffer != null,
        operation: 'recovered editor publication',
      );
      expect(
        container.read(workspaceControllerProvider).activeBuffer!.text,
        '# Retained edit\n',
      );
      expect(
        find.text(l10n.closeUnsavedChangesTitle),
        findsNothing,
        reason:
            'A visible editor does not complete restoration while its settings write is pending',
      );
      expect(nativeWindow.closeCount, 0);
      settings.release.complete();
      await pumpUntil(
        tester,
        () => find.text(l10n.closeUnsavedChangesTitle).evaluate().isNotEmpty,
        operation: 'close confirmation after durable restoration',
      );
      expect(await shortcutSave, isTrue);
      await tester.tap(find.text(l10n.cancel));
      await tester.pumpAndSettle();
      expect(nativeWindow.closeCount, 0);
      expect(recovery.value.cleanShutdown, isFalse);
      expect(recovery.value.entries.single.text, '# Retained edit\n');
      final saved = AppSettings.fromJson(settings.value);
      expect(saved.shortcutOverrides.keys, ['file.save']);
      expect(saved.recentWorkspaces.single.toJson(), recent.toJson());
      expect(
        container.read(workspaceControllerProvider).hasUnsavedChanges,
        isTrue,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    },
  );

  testWidgets('window close still warns when active changes are unsaved', (
    tester,
  ) async {
    final nativeWindow = _FakeNativeWindowController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._smokeAccentOverrides,
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
        ..._smokeAccentOverrides,
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
        ..._smokeAccentOverrides,
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

    expect(find.byTooltip(l10n.sidebarViewMenu), findsOneWidget);
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
          ..._smokeAccentOverrides,
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
        ..._smokeAccentOverrides,
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

  testWidgets(
    'tabbed Outline row delegates arrows, reveal and activation to Outline',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final source = [
        for (var i = 0; i < 60; i++)
          '# Heading ${i.toString().padLeft(2, '0')}\n\nParagraph $i.\n',
      ].join('\n');
      final settings = _MemorySettingsStore()
        ..value = AppSettings.defaults()
            .copyWith(
              autoSave: false,
              documentViewMode: DocumentViewModePreference.preview,
            )
            .toJson();
      final container = ProviderContainer(
        overrides: [
          ..._smokeAccentOverrides,
          localSettingsStoreProvider.overrideWithValue(settings),
          workspaceServiceProvider.overrideWithValue(
            _SearchWorkspaceService(source),
          ),
          startupPathProvider.overrideWithValue('/tmp/outline-row-keyboard.md'),
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
      final registry = container.read(busyMarkCommandRegistryProvider);
      await registry.execute(BusyMarkCommandIds.sidebarOutline);
      await tester.pumpAndSettle();
      BusyMarkSidebarTreeRow? focusedRow() => FocusManager
          .instance
          .primaryFocus
          ?.context
          ?.findAncestorWidgetOfExactType<BusyMarkSidebarTreeRow>();
      for (var i = 0; i < 100 && focusedRow()?.title != 'Heading 00'; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      expect(focusedRow()?.title, 'Heading 00');
      BusyMarkSidebarTreeRow row(int index) =>
          tester.widget<BusyMarkSidebarTreeRow>(
            find.descendant(
              of: find.byKey(ValueKey('workspace-sidebar-outline-row-$index')),
              matching: find.byType(BusyMarkSidebarTreeRow),
            ),
          );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(row(1).selected, isTrue);
      expect(row(0).selected, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(row(0).selected, isTrue);
      for (var i = 0; i < 40; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
      }
      expect(row(40).selected, isTrue);
      final outlineScroll = tester
          .widget<ListView>(
            find.byKey(const ValueKey('workspace-sidebar-outline-tree')),
          )
          .controller!;
      expect(outlineScroll.offset, greaterThan(0));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      final state = container.read(workspaceControllerProvider);
      final heading = state.preview!.outline[40];
      final blockIndex = state.preview!.blocks.indexWhere(
        (b) => b.attributes['id'] == heading.id,
      );
      final positions = tester
          .widget<ScrollablePositionedList>(
            find.byKey(const ValueKey('preview-document-scroll')),
          )
          .itemPositionsNotifier!
          .itemPositions
          .value;
      expect(
        positions.any(
          (p) => p.index == blockIndex && p.itemLeadingEdge.abs() < .01,
        ),
        isTrue,
      );
    },
  );

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
        ..._smokeAccentOverrides,
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
        ..._smokeAccentOverrides,
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
    final searchSession = container.read(searchSessionProvider.notifier);
    searchSession.open(category: SearchCategory.outline);
    searchSession.query('Unsaved');
    await _waitForSearchCondition(
      tester,
      () => !container.read(searchSessionProvider).searching,
    );
    final result =
        container.read(searchSessionProvider).results.single
            as OutlineSearchResult;
    expect(
      result.heading.editorBlockId,
      state.liveOutline!.headings.single.editorBlockId,
    );
    editorList().itemScrollController!.jumpTo(
      index: editorList().itemCount - 1,
    );
    await tester.pump();
    expect(editorFieldWithText('Unsaved heading'), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await _waitForSearchCondition(
      tester,
      () => editorFieldWithText('Unsaved heading').evaluate().isNotEmpty,
    );
    expect(
      container.read(workspaceControllerProvider).activeText,
      state.activeText,
    );
    expect(
      container.read(searchSessionProvider).results.single.identity,
      result.identity,
    );
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
        ..._smokeAccentOverrides,
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
        ..._smokeAccentOverrides,
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
        ..._smokeAccentOverrides,
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
        ..._smokeAccentOverrides,
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
        ..._smokeAccentOverrides,
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
        ..._smokeAccentOverrides,
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
    final recentDirectory = Directory.systemTemp.createTempSync(
      'busymark-recent-docs-',
    );
    final recentPath = recentDirectory.path;
    addTearDown(() => recentDirectory.deleteSync(recursive: true));
    final service = _StartupWorkspaceService();
    final settingsStore = _MemorySettingsStore()
      ..value = AppSettings.defaults()
          .copyWith(
            recentWorkspaces: [
              RecentResource(
                path: recentPath,
                kind: 'markdownFolder',
                lastOpenedAt: DateTime(2026, 1, 2),
              ),
            ],
          )
          .toJson();
    final container = ProviderContainer(
      overrides: [
        ..._smokeAccentOverrides,
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
    expect(find.text(p.basename(recentPath)), findsOneWidget);

    await tester.tap(find.text(p.basename(recentPath)));
    await _waitForSearchCondition(
      tester,
      () => service.openedPath == recentPath,
    );
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
              RecentResource(
                path: recentPath,
                kind: 'markdownFolder',
                lastOpenedAt: DateTime(2026, 1, 2),
              ),
            ],
          )
          .toJson();
    final container = ProviderContainer(
      overrides: [
        ..._smokeAccentOverrides,
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

  for (final mode in [
    DocumentViewModePreference.source,
    DocumentViewModePreference.split,
  ]) {
    for (final count in [81, 3000]) {
      testWidgets(
        'shared Find/Replace navigates $count matches in ${mode.name}',
        (tester) async {
          tester.view.physicalSize = const Size(1440, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final original =
              '# Group\n${List.generate(count, (i) => 'cat $i\n').join()}';
          final harness = await _pumpSearchRegression(
            tester,
            headerBarService,
            {'a.md': original},
            mode: mode,
          );
          final container = harness.container;
          final session = container.read(searchSessionProvider.notifier);
          session.open(category: SearchCategory.file);
          session.query('cat');
          await _waitForSearchCondition(
            tester,
            () =>
                _searchSourceController(tester).searchResult.totalMatchCount ==
                count,
          );
          final source = _searchSourceController(tester);
          final editor = tester.widget<BusyMarkSourceEditor>(
            find.byType(BusyMarkSourceEditor),
          );
          expect(editor.searchSnapshot, isNotNull);
          expect(container.read(searchSessionProvider).results, hasLength(80));
          expect(source.searchResult.currentMatchIndex, isNull);

          Future<void> expectIndex(int index, String text) async {
            final expected = RegExp('cat').allMatches(text).elementAt(index);
            await _waitForSearchCondition(
              tester,
              () =>
                  source.searchResult.currentMatchIndex == index &&
                  source.fullSelection ==
                      TextSelection(
                        baseOffset: expected.start,
                        extentOffset: expected.end,
                      ),
            );
            final state = container.read(searchSessionProvider);
            expect(source.fullText, text);
            expect(state.results.length, lessThanOrEqualTo(80));
            expect(state.documentCurrentMatchIndex, index);
            final selected = state.results[state.selected] as TextSearchResult;
            expect(selected.match.startOffset, expected.start);
            expect(selected.match.endOffset, expected.end);
            final row = find.byKey(ValueKey(selected.identity));
            await _waitForSearchCondition(
              tester,
              () =>
                  row.evaluate().isNotEmpty &&
                  tester
                      .getRect(row)
                      .overlaps(
                        tester.getRect(
                          find.byKey(const ValueKey('sidebar-search-results')),
                        ),
                      ),
            );
            expect(
              tester.widget<BusyMarkSidebarRecordRow>(row).selected,
              isTrue,
            );
          }

          Future<void> choose(int index) async {
            final match = RegExp(
              'cat',
            ).allMatches(source.fullText).elementAt(index);
            final editorState = tester.state<BusyMarkSourceEditorState>(
              find.byType(BusyMarkSourceEditor),
            );
            editorState.scrollToSearchRange(
              line:
                  '\n'
                      .allMatches(source.fullText.substring(0, match.start))
                      .length +
                  1,
              startOffset: match.start,
              endOffset: match.end,
            );
            await expectIndex(index, source.fullText);
          }

          // Starting from no selection, Previous must find the actual last match
          // inside folded content, rather than the last loaded sidebar row.
          await tester.tap(
            find.byTooltip(l10n.collapseKind(l10n.foldKindSection)).first,
          );
          await tester.pump();
          expect(source.document.hiddenRanges.ranges, isNotEmpty);
          await tester.tap(find.byTooltip(l10n.sourceSearchPreviousMatch));
          await expectIndex(count - 1, original);
          expect(source.searchResult.currentMatch!.hidden, isFalse);
          await tester.pumpAndSettle();
          final sourceField = tester.widget<TextField>(
            find.byWidgetPredicate(
              (w) => w is TextField && identical(w.controller, source),
            ),
          );
          expect(sourceField.scrollController!.offset, greaterThan(0));
          await tester.tap(find.byTooltip(l10n.sourceSearchNextMatch));
          await expectIndex(0, original);
          await choose(79);
          await tester.tap(find.byTooltip(l10n.sourceSearchNextMatch));
          await expectIndex(80, original);
          await tester.tap(find.byTooltip(l10n.sourceSearchPreviousMatch));
          await expectIndex(79, original);
          await tester.tap(find.byTooltip(l10n.sourceSearchNextMatch));
          await expectIndex(80, original);
          await tester.tap(find.byTooltip(l10n.sourceSearchNextMatch));
          await expectIndex(count == 81 ? 0 : 81, original);

          if (mode == DocumentViewModePreference.split && count == 3000) {
            tester.view.physicalSize = const Size(1100, 900);
            await tester.pumpAndSettle();
          }
          final replaceIndex = count == 81 ? 80 : 2500;
          await choose(replaceIndex);
          final occurrence = RegExp(
            'cat',
          ).allMatches(original).elementAt(replaceIndex);
          final modified = original.replaceRange(
            occurrence.start,
            occurrence.end,
            'wolf',
          );
          await tester.enterText(
            find.byKey(const ValueKey('source-search-replacement')),
            'wolf',
          );
          await tester.pump();
          await tester.tap(find.byTooltip(l10n.sourceSearchReplaceAndFindNext));
          await _waitForSearchCondition(
            tester,
            () =>
                container.read(workspaceControllerProvider).activeText ==
                modified,
          );
          await expectIndex(count == 81 ? 0 : replaceIndex, modified);
          expect(source.searchResult.totalMatchCount, count - 1);
          expect(RegExp('wolf').allMatches(source.fullText), hasLength(1));
          await tester.pumpAndSettle();
          final editable = tester
              .state<EditableTextState>(
                find.descendant(
                  of: find.byWidgetPredicate(
                    (w) => w is TextField && identical(w.controller, source),
                  ),
                  matching: find.byType(EditableText),
                ),
              )
              .renderEditable;
          final caret = editable.getLocalRectForCaret(
            TextPosition(offset: source.selection.extentOffset),
          );
          expect(caret.top, greaterThanOrEqualTo(0));
          expect(caret.bottom, lessThanOrEqualTo(editable.size.height));
          if (mode == DocumentViewModePreference.split && count == 3000) {
            expect(
              editable.localToGlobal(caret.topLeft).dy,
              greaterThan(
                tester
                    .getRect(
                      find.byKey(const ValueKey('source-search-replacement')),
                    )
                    .bottom,
              ),
              reason: 'The selected match must clear the floating controls.',
            );
          }
          await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
          await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
          await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
          await _waitForSearchCondition(
            tester,
            () =>
                source.fullText == original &&
                source.searchResult.totalMatchCount == count,
          );
          await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
          await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
          await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
          await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
          await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
          await _waitForSearchCondition(
            tester,
            () =>
                source.fullText == modified &&
                source.searchResult.totalMatchCount == count - 1,
          );
          expect(RegExp('wolf').allMatches(source.fullText), hasLength(1));
          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(seconds: 1));
        },
      );
    }
  }

  for (final mode in [
    DocumentViewModePreference.source,
    DocumentViewModePreference.split,
  ]) {
    for (final scenario in [
      'separated',
      'double',
      'refresh',
      'query',
      'clear',
      'category',
      'document',
      'undo/redo',
      'caret',
    ]) {
      testWidgets('shared replacement refresh $scenario in ${mode.name}', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final original = 'cat\n${'gap\n' * 200}cat\n${'tail\n' * 200}cat\n';
        final modified = original.replaceRange(0, 3, 'wolf');
        final harness = await _pumpSearchRegression(tester, headerBarService, {
          'a.md': original,
          'b.md': 'other cat buffer\n',
        }, mode: mode);
        final container = harness.container;
        final session = container.read(searchSessionProvider.notifier);
        final workspace = container.read(workspaceControllerProvider.notifier);
        session.open(category: SearchCategory.file);
        session.query('cat');
        await _waitForSearchCondition(
          tester,
          () =>
              _searchSourceController(tester).searchResult.totalMatchCount == 3,
        );
        var source = _searchSourceController(tester);
        expect(
          tester
              .widget<BusyMarkSourceEditor>(find.byType(BusyMarkSourceEditor))
              .searchSnapshot,
          isNotNull,
        );
        await tester.tap(find.byTooltip(l10n.sourceSearchNextMatch));
        await _waitForSearchCondition(
          tester,
          () =>
              source.searchResult.currentMatchIndex == 0 &&
              source.fullSelection.extentOffset == 3,
        );
        await tester.enterText(
          find.byKey(const ValueKey('source-search-replacement')),
          'wolf',
        );
        await tester.pump();
        await tester.tap(find.byTooltip(l10n.sourceSearchReplaceAndFindNext));
        if (scenario == 'double') {
          await tester.tap(find.byTooltip(l10n.sourceSearchReplaceAndFindNext));
        }
        // Stop after mutation, while the replacement's async refresh is pending.
        await _waitForSearchCondition(
          tester,
          () =>
              container.read(workspaceControllerProvider).activeText ==
              modified,
        );
        expect(container.read(searchSessionProvider).searching, isTrue);
        Future<void> undoRedoKey({bool redo = false}) async {
          await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
          if (redo) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
          await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
          if (redo) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
          await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        }

        switch (scenario) {
          case 'query':
            for (var i = 0; i < 12; i++) {
              session.query('missing-$i');
            }
            session.query('cat');
          case 'clear':
            session.query('');
            session.query('cat');
          case 'category':
            session.open(category: SearchCategory.workspace);
            session.query('cat');
            session.open(category: SearchCategory.file);
          case 'document':
            await workspace.openActiveFile(
              '${_SearchRegressionService.root}/b.md',
            );
          case 'undo/redo':
            await undoRedoKey();
            expect(
              container.read(workspaceControllerProvider).activeText,
              original,
            );
            await undoRedoKey(redo: true);
          case 'caret':
            source.fullSelection = const TextSelection.collapsed(offset: 7);
          case 'refresh':
            await tester.runAsync(() => session.submit());
            expect(
              container.read(searchSessionProvider).appliedSourceNavigation,
              isNonZero,
            );
            session.refresh(container.read(workspaceControllerProvider));
        }
        await tester.pump();
        source = _searchSourceController(tester);
        final selectionAfterAction = source.fullSelection;
        await _waitForSearchCondition(
          tester,
          () => !container.read(searchSessionProvider).searching,
        );
        if (scenario == 'separated' ||
            scenario == 'double' ||
            scenario == 'refresh') {
          final next = modified.indexOf('cat');
          await _waitForSearchCondition(
            tester,
            () =>
                source.fullSelection ==
                TextSelection(baseOffset: next, extentOffset: next + 3),
          );
          final state = container.read(searchSessionProvider);
          expect(state.documentMatchCount, 2);
          expect(state.documentCurrentMatchIndex, 0);
          expect(
            (state.results[state.selected] as TextSearchResult)
                .match
                .startOffset,
            next,
          );
          await tester.pumpAndSettle();
          final field = find.byWidgetPredicate(
            (w) => w is TextField && identical(w.controller, source),
          );
          final editable = tester
              .state<EditableTextState>(
                find.descendant(of: field, matching: find.byType(EditableText)),
              )
              .renderEditable;
          final caret = editable.getLocalRectForCaret(
            TextPosition(offset: source.selection.extentOffset),
          );
          expect(
            tester.widget<TextField>(field).scrollController!.offset,
            greaterThan(0),
          );
          expect(caret.top, greaterThanOrEqualTo(0));
          expect(caret.bottom, lessThanOrEqualTo(editable.size.height));
        } else {
          await tester.pump(const Duration(milliseconds: 700));
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)),
          );
          await tester.pumpAndSettle();
          expect(source.fullSelection, selectionAfterAction);
          expect(
            container.read(searchSessionProvider).appliedSourceNavigation,
            0,
          );
        }
        expect(
          source.fullText,
          scenario == 'document' ? 'other cat buffer\n' : modified,
        );
        expect(
          RegExp('wolf').allMatches(source.fullText).length,
          scenario == 'document' ? 0 : 1,
        );
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
      });
    }
  }

  testWidgets('Welcome, Recent search and Open use the same mixed chronology', (
    tester,
  ) async {
    final settings = _MemorySettingsStore()
      ..value = AppSettings.defaults()
          .copyWith(
            reopenPreviousWorkspaceOnStartup: false,
            recentWorkspaces: [
              RecentResource(
                path: '/old.md',
                kind: 'markdown',
                document: true,
                title: 'Oldest entry',
                lastOpenedAt: DateTime.utc(2026, 1, 1),
              ),
              RecentResource(
                path: '/new-folder',
                kind: 'markdownFolder',
                title: 'Newest entry',
                lastOpenedAt: DateTime.utc(2026, 1, 3),
              ),
              RecentResource(
                path: '',
                kind: 'nextcloudNote',
                document: true,
                accountId: 'account-a',
                localId: 'offline-id',
                title: 'Middle entry',
                lastOpenedAt: DateTime.utc(2026, 1, 2),
              ),
            ],
          )
          .toJson();
    final container = ProviderContainer(
      overrides: [
        ..._smokeAccentOverrides,
        startupPathProvider.overrideWithValue(null),
        linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
        localSettingsStoreProvider.overrideWithValue(settings),
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
    void expectChronologicalRows() {
      final newest = tester.getTopLeft(find.text('Newest entry')).dy;
      final middle = tester.getTopLeft(find.text('Middle entry')).dy;
      final oldest = tester.getTopLeft(find.text('Oldest entry')).dy;
      expect(newest, lessThan(middle));
      expect(middle, lessThan(oldest));
    }

    expectChronologicalRows();
    final search = container.read(searchSessionProvider.notifier);
    search.open(category: SearchCategory.recent);
    search.query('entry');
    await _waitForSearchCondition(
      tester,
      () => !container.read(searchSessionProvider).searching,
    );
    await tester.pumpAndSettle();
    expect(
      container
          .read(searchSessionProvider)
          .results
          .whereType<RecentSearchResult>()
          .map((r) => r.resource.title),
      ['Newest entry', 'Middle entry', 'Oldest entry'],
    );
    expectChronologicalRows();
    search.close();
    await tester.pumpAndSettle();
    final opening = container
        .read(busyMarkCommandRegistryProvider)
        .execute(BusyMarkCommandIds.open);
    await tester.pumpAndSettle();
    final recentRows = tester
        .widgetList<BusyMarkActionRow>(
          find.descendant(
            of: find.byType(BusyMarkDialogShell),
            matching: find.byType(BusyMarkActionRow),
          ),
        )
        .where((r) => r.title.contains('entry'))
        .map((r) => r.title.replaceAll('\u2066', '').replaceAll('\u2069', ''))
        .toList();
    expect(recentRows, ['Newest entry', 'Middle entry', 'Oldest entry']);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await opening;
  });

  for (final mode in [
    DocumentViewModePreference.editor,
    DocumentViewModePreference.preview,
  ]) {
    for (final change in ['initialization', 'edit', 'navigation']) {
      testWidgets(
        'deleted History recovery in ${mode.name} tolerates only initialization: $change',
        (tester) async {
          final root = Directory.systemTemp.createTempSync(
            'busymark-history-initialization-',
          );
          addTearDown(() => root.deleteSync(recursive: true));
          final anchor = File(p.join(root.path, 'anchor.md'))
            ..writeAsStringSync('# Anchor\n');
          final missing = File(p.join(root.path, 'deleted.md'));
          final store = _PendingHistoryRestoreStore();
          const recovered = '# Recovered\n\nDeleted source.\n';
          final format = decodeUtf8Document(utf8.encode(recovered)).format;
          final destinationSource = decodeUtf8Document(format.encode('')).text;
          final capture = await store.capture(
            LocalHistoryCaptureRequest(
              path: missing.path,
              displayName: 'deleted.md',
              source: recovered,
              format: format,
              capturedAt: DateTime.now().toUtc(),
              reason: LocalHistoryCaptureReason.beforeDelete,
            ),
            const LocalHistoryPolicy(),
          );
          await store.markDeleted(missing.path, recursive: false);
          final document = (await store.load()).documents.single;
          final revision = (await store.readRevision(capture.revision!.id))!;
          final settings = _MemorySettingsStore()
            ..value = AppSettings.defaults()
                .copyWith(
                  autoSave: false,
                  automaticSpelling: false,
                  documentViewMode: mode,
                )
                .toJson();
          final container = ProviderContainer(
            overrides: [
              ..._smokeAccentOverrides,
              linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
              workspaceFileMonitorProvider.overrideWith(
                (ref) => _SearchTestFileMonitor(),
              ),
              localSettingsStoreProvider.overrideWithValue(settings),
              localHistoryStoreProvider.overrideWithValue(store),
              startupPathProvider.overrideWithValue(root.path),
            ],
          );
          addTearDown(container.dispose);
          addTearDown(() {
            if (!store.release.isCompleted) store.release.complete();
          });
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: const BusyMarkApp(),
            ),
          );
          await _waitForSearchCondition(
            tester,
            () =>
                container
                    .read(workspaceControllerProvider)
                    .activeBuffer
                    ?.filePath ==
                anchor.path,
            attempts: 3000,
          );
          final controller = container.read(
            workspaceControllerProvider.notifier,
          );
          container.read(localHistoryOpenRequestProvider.notifier).request();
          await tester.pumpAndSettle();
          final history = container.read(
            localHistoryControllerProvider.notifier,
          );
          history.inspectRetainedDocument(document.id);
          await tester.runAsync(
            () => history.selectRevision(revision.summary.id),
          );
          await tester.pump();
          final restoring = controller.restoreMissingLocalHistoryRevision(
            document: document,
            revision: revision,
            destinationPath: missing.path,
            overwriteExisting: false,
          );
          bool? restored;
          unawaited(restoring.then((value) => restored = value));
          await _waitForSearchCondition(
            tester,
            () => store.started.isCompleted || restored != null,
            attempts: 3000,
          );
          expect(
            store.started.isCompleted,
            isTrue,
            reason:
                'Recovery must reach protective capture before simulating navigation (returned $restored).',
          );
          final before = container
              .read(workspaceControllerProvider)
              .activeBuffer!;
          expect(before.filePath, missing.path);
          expect(before.text, destinationSource);
          expect(before.editorState.mode, mode);
          // Mount the actual destination editor while the protective capture is
          // suspended. Its session report must not masquerade as a source edit.
          await tester.pumpAndSettle();
          final initialized = container
              .read(workspaceControllerProvider)
              .activeBuffer!;
          expect(initialized.text, before.text);
          expect(initialized.revision, before.revision);
          if (mode == DocumentViewModePreference.editor) {
            expect(find.byType(BusyMarkWysiwygEditor), findsOneWidget);
            expect(
              identical(initialized.editorState, before.editorState),
              isFalse,
            );
          }
          if (change == 'edit') {
            controller.updateActiveText('Concurrent user edit\n');
          }
          if (change == 'navigation') {
            await tester.runAsync(() => controller.openActiveFile(anchor.path));
            // Returning to the same tab must not revive the pending restore.
            await tester.runAsync(
              () => controller.openActiveFile(missing.path),
            );
          }
          store.release.complete();
          await _waitForSearchCondition(
            tester,
            () => restored != null,
            attempts: 3000,
          );
          await tester.pumpAndSettle();
          expect(restored, change == 'initialization');
          expect(
            container.read(workspaceControllerProvider).activeText,
            change == 'initialization'
                ? recovered
                : change == 'edit'
                ? 'Concurrent user edit\n'
                : destinationSource,
          );
          if (change == 'initialization') {
            expect(missing.readAsStringSync(), destinationSource);
            expect(controller.undoActiveBuffer(), isTrue);
            await tester.pumpAndSettle();
            expect(
              container.read(workspaceControllerProvider).activeText,
              destinationSource,
            );
            expect(controller.redoActiveBuffer(), isTrue);
            await tester.pumpAndSettle();
            expect(
              container.read(workspaceControllerProvider).activeText,
              recovered,
            );
            bool? saved;
            unawaited(controller.saveActive().then((value) => saved = value));
            // This includes real filesystem publication and protective History
            // capture, rather than only the query debounce used by this helper.
            await _waitForSearchCondition(
              tester,
              () => saved != null,
              attempts: 3000,
            );
            expect(saved, isTrue);
            expect(missing.readAsStringSync(), recovered);
          }
          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(seconds: 1));
        },
      );
    }
  }

  testWidgets(
    'shared History search double-click inspects exact retained revisions and restores ordinary browsing',
    (tester) async {
      final store = MemoryLocalHistoryStore();
      final now = DateTime.now().toUtc();
      for (var i = 0; i < 2; i++) {
        await store.capture(
          LocalHistoryCaptureRequest(
            path: '/retired/same.md',
            displayName: 'Retired same',
            source: i == 0 ? 'historical needle' : 'later retained revision',
            format: TextFormatMetadata.utf8Lf,
            capturedAt: now.add(Duration(seconds: i)),
            reason: LocalHistoryCaptureReason.saved,
          ),
          const LocalHistoryPolicy(),
        );
      }
      await store.remapPath('/retired/same.md', '/deleted/same.md');
      await store.markDeleted('/deleted/same.md', recursive: false);
      final harness = await _pumpSearchRegression(tester, headerBarService, {
        'a.md': '# Live heading\nlive source\n',
      }, historyStore: store);
      final container = harness.container;
      final history = container.read(localHistoryControllerProvider.notifier);
      await history.refresh();
      final retained = container
          .read(localHistoryControllerProvider)
          .snapshot
          .documents
          .singleWhere((d) => d.deleted);
      final before = container.read(workspaceControllerProvider).activeBuffer!;
      final session = container.read(searchSessionProvider.notifier);
      session.openHistory();
      session.query('historical needle');
      await _waitForSearchCondition(
        tester,
        () => !container.read(searchSessionProvider).searching,
      );
      final result =
          container.read(searchSessionProvider).results.single
              as HistorySearchResult;
      final revisionId =
          (result.match as LocalHistoryRevisionMatch).revision.id;
      final resultRow = find.byKey(ValueKey(result.identity));
      await tester.tap(resultRow);
      await tester.pump(kDoubleTapMinTime + const Duration(milliseconds: 1));
      await tester.tap(resultRow);
      await _waitForSearchCondition(
        tester,
        () =>
            container
                .read(localHistoryControllerProvider)
                .selectedRevision
                ?.summary
                .id ==
            revisionId,
      );
      expect(container.read(searchSessionProvider).active, isTrue);
      expect(
        container.read(localHistoryControllerProvider).selectedDocumentId,
        retained.id,
      );
      expect(
        container.read(localHistoryControllerProvider).selectedRevision!.source,
        'historical needle',
      );
      expect(
        container.read(workspaceControllerProvider).activeBuffer,
        same(before),
      );
      expect(find.byType(LocalHistoryComparisonView), findsOneWidget);
      await container
          .read(busyMarkCommandRegistryProvider)
          .execute(BusyMarkCommandIds.localHistory);
      await tester.pump();
      expect(container.read(searchSessionProvider).active, isFalse);
      expect(find.byType(LocalHistoryPanel), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(LocalHistoryPanel),
          matching: find.byType(TextField),
        ),
        findsNothing,
      );
      expect(
        container.read(localHistoryControllerProvider).selectedRevisions,
        hasLength(2),
      );
      expect(find.byTooltip(l10n.findLocalHistoryEllipsis), findsNothing);
      container
          .read(searchSessionProvider.notifier)
          .openHistory(documentId: retained.id);
      await tester.pump();
      expect(
        container.read(searchSessionProvider).historyDocumentId,
        retained.id,
      );
      await container
          .read(busyMarkCommandRegistryProvider)
          .execute(BusyMarkCommandIds.findLocalHistory);
      expect(container.read(searchSessionProvider).historyDocumentId, isNull);
      await _waitForSearchCondition(
        tester,
        () => !container.read(searchSessionProvider).searching,
      );
      expect(
        container.read(searchSessionProvider).results.single.identity,
        result.identity,
      );
      await history.clearDocument(retained.id);
      await _waitForSearchCondition(
        tester,
        () => !container.read(searchSessionProvider).searching,
      );
      expect(container.read(searchSessionProvider).results, isEmpty);
      expect(
        container.read(localHistoryControllerProvider).selectedRevision,
        isNull,
      );
      expect(
        container.read(workspaceControllerProvider).activeBuffer,
        same(before),
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    },
  );

  testWidgets(
    'ordinary Outline keeps its tree state independently of typed Outline search',
    (tester) async {
      const text =
          '# Alpha\n## Shared\nalpha body\n# Beta\n## Shared\nbeta body\n';
      final harness = await _pumpSearchRegression(tester, headerBarService, {
        'a.md': text,
      });
      final container = harness.container;
      final session = container.read(searchSessionProvider.notifier);
      Future<void> outlineShortcut() async {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pumpAndSettle();
      }

      await outlineShortcut();
      final tree = find.byKey(const ValueKey('workspace-sidebar-outline-tree'));
      expect(tree, findsOneWidget);
      expect(find.byKey(const ValueKey('shared-search-query')), findsNothing);
      expect(find.byKey(const ValueKey('search-category')), findsNothing);
      final ordinary = find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == '_OutlineTab',
      );
      final ordinaryState = tester.state(ordinary);
      final first = find.byKey(
        const ValueKey('workspace-sidebar-outline-row-0'),
      );
      final expander = find.descendant(
        of: first,
        matching: find.byWidgetPredicate(
          (w) => w is GestureDetector && w.child is AnimatedRotation,
        ),
      );
      await tester.tap(expander);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('workspace-sidebar-outline-row-1')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('workspace-sidebar-outline-row-3')),
        findsOneWidget,
      );
      session.open(category: SearchCategory.outline);
      await tester.pumpAndSettle();
      expect(tree, findsNothing);
      expect(find.text(l10n.searchEnterText), findsOneWidget);
      expect(container.read(searchSessionProvider).results, isEmpty);
      await tester.enterText(
        find.byKey(const ValueKey('shared-search-query')),
        'Shared',
      );
      await _waitForSearchCondition(
        tester,
        () => !container.read(searchSessionProvider).searching,
      );
      final results = container
          .read(searchSessionProvider)
          .results
          .cast<OutlineSearchResult>();
      expect(results, hasLength(2));
      expect(results.map((r) => r.ancestors.single), ['Alpha', 'Beta']);
      expect(find.byKey(ValueKey(results.first.identity)), findsOneWidget);
      expect(tree, findsNothing);
      session.moveSelection(1);
      await tester.pump();
      expect(container.read(workspaceControllerProvider).activeText, text);
      await tester.tap(find.byKey(ValueKey(results.last.identity)));
      await _waitForSearchCondition(
        tester,
        () =>
            _searchSourceController(tester).fullSelection.start ==
            text.lastIndexOf('## Shared'),
      );
      expect(container.read(searchSessionProvider).active, isTrue);
      expect(container.read(workspaceControllerProvider).activeText, text);
      await outlineShortcut();
      expect(container.read(searchSessionProvider).active, isFalse);
      expect(tester.state(ordinary), same(ordinaryState));
      expect(
        find.byKey(const ValueKey('workspace-sidebar-outline-row-1')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('workspace-sidebar-outline-row-3')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('search-category')), findsNothing);
      // Section operations remain on the normal complete tree, outside search.
      await tester.tap(
        find.byKey(const ValueKey('workspace-sidebar-outline-row-2')),
        buttons: kSecondaryButton,
      );
      await tester.pumpAndSettle();
      expect(find.text(l10n.moveSectionUp), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(container.read(workspaceControllerProvider).activeText, text);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    },
  );

  testWidgets(
    'unified search scopes, query isolation and explicit shortcut destinations',
    (tester) async {
      final harness = await _pumpSearchRegression(tester, headerBarService, {
        'a.md': '# Alpha\nneedle alpha\n',
        'b.md': '# Beta\nneedle beta\n',
      });
      final container = harness.container;
      final session = container.read(searchSessionProvider.notifier);
      expect(session.categories, [
        SearchCategory.file,
        SearchCategory.workspace,
        SearchCategory.outline,
        SearchCategory.documents,
        SearchCategory.recent,
        SearchCategory.localHistory,
        SearchCategory.actions,
      ]);
      Future<void> shortcut(
        LogicalKeyboardKey key, {
        bool shift = false,
        bool alt = false,
        bool search = true,
      }) async {
        final focusRequest = container.read(searchSessionProvider).focusRequest;
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        if (alt) await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
        await tester.sendKeyEvent(key);
        if (alt) await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
        if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pump();
        expect(
          container.read(searchSessionProvider).focusRequest,
          focusRequest + (search ? 1 : 0),
        );
      }

      final query = find.descendant(
        of: find.byKey(const ValueKey('shared-search-query')),
        matching: find.byType(TextField),
      );
      session.close();
      await tester.pump();
      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.controller is BusyMarkSourceEditingController,
        ),
      );
      await shortcut(LogicalKeyboardKey.keyF);
      expect(
        container.read(searchSessionProvider).category,
        SearchCategory.file,
      );
      await tester.enterText(query, 'needle');
      await _waitForSearchCondition(
        tester,
        () => !container.read(searchSessionProvider).searching,
      );
      expect(container.read(searchSessionProvider).results, hasLength(1));
      // Dropdown Enter and Escape belong to the popup before search dismissal.
      await tester.tap(find.byKey(const ValueKey('search-category')));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(container.read(searchSessionProvider).active, isTrue);
      tester
          .widget<TextButton>(
            find.descendant(
              of: find.byKey(const ValueKey('search-category')),
              matching: find.byType(TextButton),
            ),
          )
          .focusNode!
          .requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text(l10n.searchWorkspaceTextCategory), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text(l10n.searchWorkspaceTextCategory), findsNothing);
      expect(container.read(searchSessionProvider).active, isTrue);
      await shortcut(LogicalKeyboardKey.keyF, shift: true);
      expect(
        container.read(searchSessionProvider).category,
        SearchCategory.workspace,
      );
      expect(container.read(searchSessionProvider).query, '');
      await tester.enterText(query, 'needle');
      await _waitForSearchCondition(
        tester,
        () => !container.read(searchSessionProvider).searching,
      );
      expect(container.read(searchSessionProvider).results, hasLength(2));
      await shortcut(LogicalKeyboardKey.keyP, shift: true);
      expect(
        container.read(searchSessionProvider).category,
        SearchCategory.actions,
      );
      await tester.enterText(query, 'Bold');
      await _waitForSearchCondition(
        tester,
        () => !container.read(searchSessionProvider).searching,
      );
      expect(
        container
            .read(searchSessionProvider)
            .results
            .whereType<ActionSearchResult>()
            .any((r) => r.command.id == 'editor.bold'),
        isTrue,
      );
      expect(
        container
            .read(searchSessionProvider)
            .sourceSnapshot(
              container.read(workspaceControllerProvider).activeBuffer,
            )
            .result
            .options
            .query,
        '',
      );
      expect(
        container.read(workspaceControllerProvider).activeText,
        '# Alpha\nneedle alpha\n',
      );
      await shortcut(LogicalKeyboardKey.keyF);
      expect(
        container.read(searchSessionProvider).category,
        SearchCategory.file,
      );
      expect(
        container.read(searchSessionProvider).category,
        SearchCategory.file,
      );
      expect(container.read(searchSessionProvider).query, 'needle');
      await shortcut(LogicalKeyboardKey.keyD, shift: true);
      expect(
        container.read(searchSessionProvider).category,
        SearchCategory.documents,
      );
      await tester.enterText(query, 'b.md');
      await _waitForSearchCondition(
        tester,
        () => !container.read(searchSessionProvider).searching,
      );
      expect(container.read(searchSessionProvider).error, isNull);
      expect(
        (container.read(searchSessionProvider).results.single
                as DocumentSearchResult)
            .document
            .filePath,
        endsWith('/b.md'),
      );
      await shortcut(LogicalKeyboardKey.digit3, search: false);
      expect(container.read(searchSessionProvider).active, isFalse);
      expect(
        find.byKey(const ValueKey('workspace-sidebar-outline-tree')),
        findsOneWidget,
      );
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'Outline navigation',
      );
      session.open(category: SearchCategory.outline);
      await tester.pump();
      expect(
        container.read(searchSessionProvider).category,
        SearchCategory.outline,
      );
      await shortcut(LogicalKeyboardKey.keyR, shift: true);
      expect(
        container.read(searchSessionProvider).category,
        SearchCategory.recent,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(container.read(searchSessionProvider).active, isFalse);
      await tester.tap(find.byTooltip(l10n.search));
      await tester.pump();
      expect(
        container.read(searchSessionProvider).category,
        SearchCategory.recent,
      );
      session.close();
      container
          .read(workspaceControllerProvider.notifier)
          .updateActiveEditorMode(DocumentViewModePreference.editor);
      await container
          .read(appSettingsControllerProvider.notifier)
          .setDocumentViewMode(DocumentViewModePreference.editor);
      await tester.pumpAndSettle();
      await tester.tap(
        find
            .byWidgetPredicate(
              (widget) =>
                  widget is TextField &&
                  widget.controller is BusyMarkWysiwygTextController,
            )
            .first,
      );
      await shortcut(LogicalKeyboardKey.keyF);
      expect(
        container.read(searchSessionProvider).category,
        SearchCategory.file,
      );
      container.read(appRouterProvider).go('/');
      await tester.pumpAndSettle();
      expect(
        container.read(workspaceControllerProvider).activeBuffer,
        isNotNull,
      );
      expect(session.categories, [
        SearchCategory.recent,
        SearchCategory.actions,
      ]);
      session.open(category: SearchCategory.actions);
      await tester.pump();
      expect(session.commandTarget, isNull);
      container.read(searchSessionProvider.notifier).close();
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    },
  );

  testWidgets(
    'unified Actions formats captured Source selection and rejects a later selection',
    (tester) async {
      final harness = await _pumpSearchRegression(tester, headerBarService, {
        'a.md': 'cat dog\n',
      });
      final container = harness.container;
      container.read(searchSessionProvider.notifier).close();
      await tester.pump();
      final source = _searchSourceController(tester);
      final editor = find.byWidgetPredicate(
        (widget) => widget is TextField && identical(widget.controller, source),
      );
      tester.widget<TextField>(editor).focusNode!.requestFocus();
      await tester.pump();
      source.selection = const TextSelection(baseOffset: 0, extentOffset: 3);
      await tester.pump();
      Future<void> actions() async {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pump();
        await tester.enterText(
          find.descendant(
            of: find.byKey(const ValueKey('shared-search-query')),
            matching: find.byType(TextField),
          ),
          'Bold',
        );
        await _waitForSearchCondition(
          tester,
          () => !container.read(searchSessionProvider).searching,
        );
      }

      await actions();
      final target = container
          .read(searchSessionProvider.notifier)
          .commandTarget;
      expect(target, isNotNull);
      expect(target!.context, isNotNull);
      expect(
        target.isCurrent(container.read(workspaceControllerProvider)),
        isTrue,
        reason: 'Captured Source target must remain valid after query editing',
      );
      expect(
        container.read(searchSessionProvider).results.map((r) => r.identity),
        ['editor.bold'],
      );
      expect(
        container
            .read(busyMarkCommandRegistryProvider)
            .canExecuteInContext('editor.bold', target.context),
        isTrue,
      );
      final original = container.read(workspaceControllerProvider).activeText;
      expect(original, 'cat dog\n');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await _waitForSearchCondition(
        tester,
        () =>
            container.read(workspaceControllerProvider).activeText ==
            '**cat** dog\n',
      );
      expect(container.read(searchSessionProvider).active, isFalse);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await _waitForSearchCondition(
        tester,
        () =>
            container.read(workspaceControllerProvider).activeText == original,
      );
      source.selection = const TextSelection(baseOffset: 0, extentOffset: 3);
      await tester.pump();
      await actions();
      source.selection = const TextSelection(baseOffset: 4, extentOffset: 7);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(container.read(workspaceControllerProvider).activeText, original);
      expect(container.read(searchSessionProvider).active, isTrue);
      container.read(searchSessionProvider.notifier).close();
      await tester.pump();
      tester.widget<TextField>(editor).focusNode!.requestFocus();
      await tester.pump();
      await actions();
      final query = find.descendant(
        of: find.byKey(const ValueKey('shared-search-query')),
        matching: find.byType(TextField),
      );
      await tester.enterText(query, 'Save');
      final controller = container.read(workspaceControllerProvider.notifier);
      controller.updateDocumentText(
        container.read(workspaceControllerProvider).activeBufferId!,
        'later edit\n',
      );
      await _waitForSearchCondition(
        tester,
        () => !container.read(searchSessionProvider).searching,
      );
      final save = container
          .read(searchSessionProvider)
          .results
          .whereType<ActionSearchResult>()
          .singleWhere((r) => r.command.id == BusyMarkCommandIds.save);
      final saveRow = find.byKey(ValueKey(save.identity));
      container
          .read(searchSessionProvider.notifier)
          .select(
            container
                .read(searchSessionProvider)
                .results
                .indexWhere((r) => r.identity == save.identity),
          );
      await _waitForSearchCondition(
        tester,
        () =>
            saveRow.evaluate().isNotEmpty &&
            tester.widget<BusyMarkSidebarRecordRow>(saveRow).onTap == null,
      );
      expect(
        tester
                .widget<BusyMarkSidebarRecordRow>(
                  find.byKey(ValueKey(save.identity)),
                )
                .onTap !=
            null,
        isFalse,
      );
      tester.widget<TextField>(query).focusNode!.requestFocus();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(container.read(searchSessionProvider).active, isTrue);
      expect(
        container.read(workspaceControllerProvider).activeText,
        'later edit\n',
      );
      container.read(searchSessionProvider.notifier).close();
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    },
  );

  testWidgets(
    'unified search overlay retains source controller and initial hidden sidebar',
    (tester) async {
      final harness = await _pumpSearchRegression(tester, headerBarService, {
        'a.md': 'needle\n',
      });
      final container = harness.container;
      container.read(searchSessionProvider.notifier).close();
      await container
          .read(appSettingsControllerProvider.notifier)
          .setSidebarVisible(false);
      await tester.pump();
      final source = _searchSourceController(tester);
      source.selection = const TextSelection(baseOffset: 1, extentOffset: 4);
      tester.view.physicalSize = const Size(600, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      container
          .read(searchSessionProvider.notifier)
          .open(category: SearchCategory.file);
      await tester.pump();
      expect(identical(_searchSourceController(tester), source), isTrue);
      expect(
        source.fullSelection,
        const TextSelection(baseOffset: 1, extentOffset: 4),
      );
      expect(find.byKey(const ValueKey('search-category')), findsOneWidget);
      expect(
        container.read(appSettingsControllerProvider).sidebarVisible,
        isFalse,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(container.read(searchSessionProvider).active, isFalse);
      expect(
        container.read(appSettingsControllerProvider).sidebarVisible,
        isFalse,
      );
      container.read(searchSessionProvider.notifier).close();
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    },
  );

  testWidgets('header Search button toggles the expanded search field', (
    tester,
  ) async {
    final service = _StartupWorkspaceService();
    final container = ProviderContainer(
      overrides: [
        ..._smokeAccentOverrides,
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
      await tester.pumpAndSettle();
      if (find
          .byKey(const ValueKey('workspace-page-frame'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }
    expect(find.byKey(const ValueKey('workspace-page-frame')), findsWidgets);

    final initialTextFields = find.byType(TextField).evaluate().length;
    final editorFocus = tester
        .widget<EditableText>(find.byType(EditableText).first)
        .focusNode;
    editorFocus.requestFocus();
    await tester.pump();
    Finder headerButton(String tooltip) => find.byWidgetPredicate(
      (widget) =>
          widget is IconButton &&
          (widget.tooltip == tooltip ||
              widget.tooltip?.startsWith('$tooltip (') == true),
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(find.byType(TextField).evaluate().length, initialTextFields + 1);
    expect(headerButton(l10n.back), findsNothing);
    expect(headerButton(l10n.validate), findsNothing);
    expect(headerButton(l10n.viewMode), findsNothing);
    _expectNeutralHeaderControl(tester, l10n.search, selected: true);

    await tester.tap(headerButton(l10n.search));
    await tester.pumpAndSettle();
    expect(find.byType(TextField).evaluate().length, initialTextFields);
    expect(headerButton(l10n.back), findsOneWidget);
    expect(editorFocus.hasFocus, isTrue);
    expect(headerButton(l10n.validate), findsOneWidget);
    expect(headerButton(l10n.viewMode), findsOneWidget);

    await tester.tap(headerButton(l10n.search));
    await tester.pumpAndSettle();
    expect(find.byType(TextField).evaluate().length, initialTextFields + 1);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(find.byType(TextField).evaluate().length, initialTextFields + 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(TextField).evaluate().length, initialTextFields);
    expect(editorFocus.hasFocus, isTrue);
  });

  testWidgets(
    'native header Search action toggles search and Back visibility',
    (tester) async {
      if (!Platform.isLinux) {
        return;
      }
      const channelName = 'test.busymark/headerbar-search-toggle';
      const channel = MethodChannel(channelName);
      const codec = StandardMethodCodec();
      final nativeHeaderBarService = LinuxHeaderBarService(
        channel: channel,
        sessionId: 'search-toggle-session',
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'initialize' || call.method == 'focusSearch') {
              return true;
            }
            if (call.method == 'applyConfiguration') {
              final configuration = Map<Object?, Object?>.from(
                call.arguments! as Map<Object?, Object?>,
              );
              return configuration['revision'];
            }
            return null;
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
        channel.setMethodCallHandler(null);
      });
      await nativeHeaderBarService.initialize();

      final container = ProviderContainer(
        overrides: [
          ..._smokeAccentOverrides,
          linuxHeaderBarServiceProvider.overrideWithValue(
            nativeHeaderBarService,
          ),
          localSettingsStoreProvider.overrideWithValue(_MemorySettingsStore()),
          workspaceServiceProvider.overrideWithValue(
            _StartupWorkspaceService(),
          ),
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
        if (find
            .byKey(const ValueKey('workspace-page-frame'))
            .evaluate()
            .isNotEmpty) {
          break;
        }
      }

      HeaderBarConfiguration configuration() => tester
          .widget<HeaderBarConfigurationPublisher>(
            find.byType(HeaderBarConfigurationPublisher),
          )
          .configuration;

      expect(configuration().searchActive, isFalse);
      expect(configuration().backVisible, isTrue);

      Future<void> pressNativeSearch() async {
        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
              channelName,
              codec.encodeMethodCall(const MethodCall('search')),
              (_) {},
            );
        await tester.pump(const Duration(milliseconds: 100));
      }

      await pressNativeSearch();
      expect(configuration().searchActive, isTrue);
      expect(configuration().backVisible, isFalse);

      await pressNativeSearch();
      expect(configuration().searchActive, isFalse);
      expect(configuration().backVisible, isTrue);
    },
  );

  testWidgets(
    'workspace search awaits non-active file reads without blocking builds',
    (tester) async {
      final service = _DeferredWorkspaceSearchService();
      final settingsStore = _MemorySettingsStore()
        ..value = AppSettings.defaults()
            .copyWith(
              autoSave: false,
              documentViewMode: DocumentViewModePreference.preview,
            )
            .toJson();
      final container = ProviderContainer(
        overrides: [
          ..._smokeAccentOverrides,
          systemAccentColorProvider.overrideWith((ref) => const Stream.empty()),
          workspaceFileMonitorProvider.overrideWith(
            (ref) => _SearchTestFileMonitor(),
          ),
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
        if (find
            .byKey(const ValueKey('workspace-page-frame'))
            .evaluate()
            .isNotEmpty) {
          break;
        }
      }

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'needle');
      await tester.pump(const Duration(milliseconds: 150));
      await _waitForSearchCondition(tester, () => service.searchReadCount == 1);
      expect(service.searchReadCount, 1);
      expect(
        find.byKey(const ValueKey('workspace-search-progress')),
        findsOneWidget,
      );

      service.completeSearchRead('Delayed needle result');
      await _waitForSearchCondition(
        tester,
        () => find.text('Delayed needle result').evaluate().isNotEmpty,
      );

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

      final activeBuffer = container
          .read(workspaceControllerProvider)
          .activeBuffer!;
      container
          .read(workspaceControllerProvider.notifier)
          .updateDocumentEditorState(
            activeBuffer.id,
            activeBuffer.editorState.copyWith(
              selection: const TextSelection.collapsed(offset: 3),
              scrollOffset: 24,
            ),
          );
      await tester.pump(const Duration(milliseconds: 150));

      expect(service.searchReadCount, 1);
      expect(find.text('Delayed needle result'), findsOneWidget);

      container
          .read(workspaceControllerProvider.notifier)
          .updateActiveText(
            '# Active needle document\n',
            sourceFilePath: _DeferredWorkspaceSearchService.activePath,
          );
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump();

      await _waitForSearchCondition(tester, () => service.searchReadCount == 2);
      expect(service.searchReadCount, 2);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    },
  );

  testWidgets(
    'document text native submit uses exact payload and selected sidebar occurrence',
    (tester) async {
      final session = await _pumpSearchRegression(tester, headerBarService, {
        'a.md': 'cat\n cat \n cat \n',
      });
      session.container
          .read(searchSessionProvider.notifier)
          .open(category: SearchCategory.file);
      session.events.add(const HeaderBarSearchSubmitted(' cat '));
      await _waitForSearchCondition(
        tester,
        () => _searchSourceController(tester).searchResult.totalMatchCount == 2,
      );
      await _waitForSearchCondition(
        tester,
        () => find.text(l10n.searchResultLine('a.md', 3)).evaluate().isNotEmpty,
      );
      expect(
        tester
            .widget<HeaderBarConfigurationPublisher>(
              find.byType(HeaderBarConfigurationPublisher),
            )
            .configuration
            .searchQuery,
        ' cat ',
      );
      await tester.tap(find.text(l10n.searchResultLine('a.md', 3)));
      await _waitForSearchCondition(
        tester,
        () =>
            _searchSourceController(tester).searchResult.currentMatchIndex == 1,
      );
      expect(
        _searchSourceController(tester).fullSelection,
        const TextSelection(baseOffset: 10, extentOffset: 15),
      );
      await tester.enterText(
        find.byKey(const ValueKey('source-search-replacement')),
        ' dog ',
      );
      await tester.pump();
      await tester.tap(find.byTooltip(l10n.sourceSearchReplaceCurrent));
      await _waitForSearchCondition(
        tester,
        () =>
            session.container.read(workspaceControllerProvider).activeText ==
            'cat\n cat \n dog \n',
      );
      session.events.add(const HeaderBarSearchSubmitted(' '));
      await _waitForSearchCondition(
        tester,
        () =>
            _searchSourceController(tester).searchResult.options.query == ' ' &&
            _searchSourceController(tester).searchResult.totalMatchCount == 4,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    },
  );

  testWidgets(
    'workspace search preserves query and lands on unopened destination',
    (tester) async {
      final session = await _pumpSearchRegression(tester, headerBarService, {
        'a.md': 'First file\n',
        'b.md': 'Before\nsecond needle result\n',
      });
      session.events.add(const HeaderBarSearchQueryChanged('needle'));
      await _waitForSearchCondition(
        tester,
        () => find.text('second needle result').evaluate().isNotEmpty,
      );
      await tester.tap(find.text('second needle result'));
      await _waitForSearchCondition(
        tester,
        () =>
            session.container
                .read(workspaceControllerProvider)
                .activeBuffer
                ?.filePath
                ?.endsWith('/b.md') ==
            true,
      );
      await _waitForSearchCondition(
        tester,
        () =>
            _searchSourceController(tester).fullSelection ==
            const TextSelection(baseOffset: 14, extentOffset: 20),
      );
      final source = _searchSourceController(tester);
      await _waitForSearchCondition(
        tester,
        () => source.searchResult.matches.any(
          (match) => match.fullStart == 14 && match.fullEnd == 20,
        ),
      );
      expect(
        source.fullSelection,
        const TextSelection(baseOffset: 14, extentOffset: 20),
      );
      expect(session.container.read(searchSessionProvider).query, 'needle');
      await _waitForSearchCondition(
        tester,
        () => find.text('second needle result').evaluate().isNotEmpty,
      );
      expect(
        tester
            .widget<HeaderBarConfigurationPublisher>(
              find.byType(HeaderBarConfigurationPublisher),
            )
            .configuration
            .searchQuery,
        'needle',
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    },
  );

  for (final resourceChange in [
    'unchanged',
    'reopened',
    'changed',
    'deleted',
  ]) {
    testWidgets(
      'workspace result resolves a closed clean tab: $resourceChange',
      (tester) async {
        final sources = {
          'a.md': 'Before\noriginal needle result\n',
          'b.md': '# B\n',
        };
        final harness = await _pumpSearchRegression(
          tester,
          headerBarService,
          sources,
        );
        final container = harness.container;
        final controller = container.read(workspaceControllerProvider.notifier);
        final original = container
            .read(workspaceControllerProvider)
            .activeBuffer!;
        await controller.openActiveFile(
          '${_SearchRegressionService.root}/b.md',
        );
        harness.events.add(const HeaderBarSearchQueryChanged('needle'));
        await _waitForSearchCondition(
          tester,
          () =>
              !container.read(searchSessionProvider).searching &&
              container.read(searchSessionProvider).results.isNotEmpty,
        );
        final result =
            container.read(searchSessionProvider).results.single
                as TextSearchResult;
        expect(result.match.bufferId, original.id);
        final generation = container.read(searchSessionProvider).generation;
        expect(await controller.closeDocumentBuffer(original.id), isTrue);
        await tester.pump();
        expect(
          container
              .read(workspaceControllerProvider)
              .bufferForPath(original.filePath!),
          isNull,
        );
        if (resourceChange == 'changed') {
          sources['a.md'] = 'Changed needle content\n';
        }
        if (resourceChange == 'deleted') sources.remove('a.md');
        if (resourceChange == 'reopened') {
          expect(await controller.openActiveFile(original.filePath!), isTrue);
          await controller.openActiveFile(
            '${_SearchRegressionService.root}/b.md',
          );
        }
        await tester.pump(const Duration(milliseconds: 200));
        expect(container.read(searchSessionProvider).generation, generation);
        expect(
          identical(
            container.read(searchSessionProvider).results.single,
            result,
          ),
          isTrue,
        );
        await tester.tap(find.text('original needle result'));
        if (resourceChange == 'unchanged' || resourceChange == 'reopened') {
          await _waitForSearchCondition(
            tester,
            () =>
                container
                        .read(workspaceControllerProvider)
                        .activeBuffer
                        ?.filePath ==
                    original.filePath &&
                _searchSourceController(tester).fullSelection ==
                    const TextSelection(baseOffset: 16, extentOffset: 22),
          );
          expect(
            container.read(workspaceControllerProvider).activeText,
            sources['a.md'],
          );
          expect(
            container
                .read(workspaceControllerProvider)
                .documentBuffers
                .where((b) => b.filePath == original.filePath),
            hasLength(1),
          );
        } else {
          await _waitForSearchCondition(
            tester,
            () => find
                .text(l10n.commandUnavailableInContext)
                .evaluate()
                .isNotEmpty,
          );
          expect(
            _searchSourceController(tester).fullSelection,
            isNot(const TextSelection(baseOffset: 16, extentOffset: 22)),
          );
          expect(
            container.read(workspaceControllerProvider).activeText,
            resourceChange == 'changed' ? sources['a.md'] : sources['b.md'],
          );
        }
        expect(container.read(searchSessionProvider).query, 'needle');
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
      },
    );
  }

  testWidgets(
    'cancelled closed-tab result cannot navigate or publish feedback',
    (tester) async {
      final harness = await _pumpSearchRegression(tester, headerBarService, {
        'a.md': 'original needle result\n',
        'b.md': '# B\n',
      });
      final container = harness.container;
      final controller = container.read(workspaceControllerProvider.notifier);
      final original = container
          .read(workspaceControllerProvider)
          .activeBuffer!;
      await controller.openActiveFile('${_SearchRegressionService.root}/b.md');
      final destination = container
          .read(workspaceControllerProvider)
          .activeBuffer!;
      harness.events.add(const HeaderBarSearchQueryChanged('needle'));
      await _waitForSearchCondition(
        tester,
        () =>
            !container.read(searchSessionProvider).searching &&
            container.read(searchSessionProvider).results.isNotEmpty,
      );
      expect(await controller.closeDocumentBuffer(original.id), isTrue);
      final started = Completer<void>();
      final release = Completer<void>();
      addTearDown(() {
        if (!release.isCompleted) release.complete();
      });
      (container.read(workspaceServiceProvider) as _SearchRegressionService)
          .beforeLoad = (path) async {
        if (path == original.filePath) {
          started.complete();
          await release.future;
        }
      };
      await tester.tap(find.text('original needle result'));
      await _waitForSearchCondition(tester, () => started.isCompleted);
      container
          .read(searchSessionProvider.notifier)
          .open(category: SearchCategory.actions);
      release.complete();
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect(
        container.read(workspaceControllerProvider).activeBufferId,
        destination.id,
      );
      expect(
        container
            .read(workspaceControllerProvider)
            .bufferForPath(original.filePath!),
        isNull,
      );
      expect(
        container.read(searchSessionProvider).category,
        SearchCategory.actions,
      );
      expect(
        find.ancestor(
          of: find.text(l10n.commandUnavailableInContext),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Semantics && widget.properties.liveRegion == true,
          ),
        ),
        findsNothing,
      );
      expect(
        container.read(workspaceControllerProvider).activeText,
        destination.text,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    },
  );

  testWidgets('workspace search observes edits to inactive buffers', (
    tester,
  ) async {
    final session = await _pumpSearchRegression(tester, headerBarService, {
      'a.md': 'First file\n',
      'b.md': 'disk needle\n',
    });
    final controller = session.container.read(
      workspaceControllerProvider.notifier,
    );
    await controller.openActiveFile('${_SearchRegressionService.root}/b.md');
    await tester.pump();
    final buffer = session.container
        .read(workspaceControllerProvider)
        .activeBuffer!;
    controller.updateDocumentText(buffer.id, 'unsaved needle\n');
    await controller.openActiveFile('${_SearchRegressionService.root}/a.md');
    await tester.pump();
    session.events.add(const HeaderBarSearchQueryChanged('needle'));
    await _waitForSearchCondition(
      tester,
      () => find.text('unsaved needle').evaluate().isNotEmpty,
    );
    expect(find.text('disk needle'), findsNothing);
    controller.updateDocumentText(buffer.id, 'removed\n');
    await _waitForSearchCondition(
      tester,
      () => find.text(l10n.noResults).evaluate().isNotEmpty,
    );
    controller.updateDocumentText(buffer.id, 'added needle\n');
    await _waitForSearchCondition(
      tester,
      () => find.text('added needle').evaluate().isNotEmpty,
    );
    await tester.tap(find.text('added needle'));
    await _waitForSearchCondition(
      tester,
      () =>
          _searchSourceController(tester).fullSelection ==
          const TextSelection(baseOffset: 6, extentOffset: 12),
    );
    expect(session.container.read(searchSessionProvider).query, 'needle');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets(
    'workspace search reports limits and continues into later files',
    (tester) async {
      final session = await _pumpSearchRegression(tester, headerBarService, {
        'a.md': List.generate(80, (i) => 'needle $i').join('\n'),
        'b.md': 'later needle\n',
      });
      session.events.add(const HeaderBarSearchQueryChanged('needle'));
      await _waitForSearchCondition(
        tester,
        () => find.text(l10n.workspaceSearchShowMore).evaluate().isNotEmpty,
      );
      expect(find.text(l10n.workspaceSearchIncomplete), findsOneWidget);
      await tester.tap(find.text(l10n.workspaceSearchShowMore));
      await _waitForSearchCondition(
        tester,
        () => find
            .byKey(const ValueKey('workspace-search-progress'))
            .evaluate()
            .isEmpty,
      );
      expect(find.text(l10n.workspaceSearchIncomplete), findsNothing);
      final sidebarList = find.byKey(const ValueKey('sidebar-search-results'));
      final scrollable = find
          .descendant(of: sidebarList, matching: find.byType(Scrollable))
          .first;
      await tester.scrollUntilVisible(
        find.text('later needle'),
        400,
        scrollable: scrollable,
        maxScrolls: 60,
      );
      expect(find.text('later needle'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    },
  );

  testWidgets(
    'workspace search keeps skipped-file feedback for literal punctuation',
    (tester) async {
      final session = await _pumpSearchRegression(
        tester,
        headerBarService,
        {
          'a.md': 'active\n',
          'large.md': 'large needle',
          'unreadable.md': 'needle',
        },
        oversized: {'large.md'},
        unreadable: {'unreadable.md'},
      );
      session.events.add(const HeaderBarSearchQueryChanged('needle'));
      await _waitForSearchCondition(
        tester,
        () => find
            .textContaining(l10n.workspaceSearchSkippedFiles)
            .evaluate()
            .isNotEmpty,
      );
      expect(find.text(l10n.noResults), findsNothing);
      expect(find.textContaining('large.md\nunreadable.md'), findsOneWidget);
      session.events.add(const HeaderBarSearchQueryChanged('['));
      await _waitForSearchCondition(
        tester,
        () => !session.container.read(searchSessionProvider).searching,
      );
      expect(find.textContaining('large.md\nunreadable.md'), findsOneWidget);
      expect(session.container.read(searchSessionProvider).results, isEmpty);
      expect(find.text('Aa'), findsNothing);
      expect(find.text('W'), findsNothing);
      expect(find.text('.*'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    },
  );

  testWidgets(
    'workspace search cancels rapid literal queries while UI keeps building',
    (tester) async {
      final session = await _pumpSearchRegression(tester, headerBarService, {
        'a.md': 'active\n',
        'b.md': '${'a' * 100}b\n',
      });
      session.events.add(const HeaderBarSearchQueryChanged('needle'));
      await tester.pump();
      session.events.add(const HeaderBarSearchQueryChanged(r'^(a+)+$'));
      await tester.pump(const Duration(milliseconds: 1));
      await session.container
          .read(appSettingsControllerProvider.notifier)
          .setWordWrap(false);
      await tester.pump();
      session.events.add(const HeaderBarSearchQueryChanged('active'));
      await _waitForSearchCondition(
        tester,
        () =>
            !session.container.read(searchSessionProvider).searching &&
            find.text(l10n.searchResultLine('a.md', 1)).evaluate().isNotEmpty,
      );
      expect(
        find.byKey(const ValueKey('workspace-search-progress')),
        findsNothing,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    },
  );

  testWidgets(
    'workspace search replacement review loads an asynchronous plan',
    (tester) async {
      final session = await _pumpSearchRegression(tester, headerBarService, {
        'a.md': 'cat cat\n',
        'b.md': 'cat\n',
      });
      session.events.add(const HeaderBarSearchQueryChanged('cat'));
      await _waitForSearchCondition(
        tester,
        () => find.text(l10n.workspaceReplace).evaluate().isNotEmpty,
      );
      await tester.tap(find.text(l10n.workspaceReplace));
      await tester.pumpAndSettle();
      final entry = find.descendant(
        of: find.byType(BusyMarkModalEditorScaffold),
        matching: find.byType(TextField),
      );
      await tester.enterText(entry, 'dog');
      await tester.tap(find.text(l10n.reviewReplacements));
      await _waitForSearchCondition(
        tester,
        () => find.text(l10n.applyReplacements).evaluate().isNotEmpty,
      );
      expect(find.text('cat → dog'), findsNWidgets(3));
      expect(find.byType(CheckboxListTile), findsNothing);
      final controls = find.byType(BusyMarkCheckbox);
      expect(controls, findsNWidgets(5));
      tester.widget<BusyMarkCheckbox>(controls.at(1)).onChanged!(false);
      await tester.pump();
      expect(tester.widget<BusyMarkCheckbox>(controls.first).value, isNull);
      tester.widget<BusyMarkCheckbox>(controls.first).onChanged!(false);
      tester.widget<BusyMarkCheckbox>(controls.at(3)).onChanged!(false);
      await tester.pump();
      final apply = find.byWidgetPredicate(
        (widget) =>
            widget is BusyMarkModalEditorScaffold &&
            widget.saveLabel == l10n.applyReplacements,
      );
      expect(tester.widget<BusyMarkModalEditorScaffold>(apply).onSave, isNull);
      tester.widget<BusyMarkCheckbox>(controls.at(2)).onChanged!(true);
      await tester.pump();
      expect(tester.widget<BusyMarkCheckbox>(controls.first).value, isNull);
      expect(tester.widget<BusyMarkCheckbox>(controls.at(1)).value, isFalse);
      expect(tester.widget<BusyMarkCheckbox>(controls.at(2)).value, isTrue);
      expect(
        tester.widget<BusyMarkModalEditorScaffold>(apply).onSave,
        isNotNull,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.cancel));
      await tester.pumpAndSettle();
      expect(
        session.container.read(workspaceControllerProvider).activeText,
        'cat cat\n',
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    },
  );

  testWidgets(
    'preview search highlights preserve Unicode offsets and literal case-insensitive matching',
    (tester) async {
      final harness = await _pumpSearchRegression(tester, headerBarService, {
        'a.md': 'İ needle Cat catalog .*\n',
      }, mode: DocumentViewModePreference.preview);
      bool hasHighlight(InlineSpan span, String text) =>
          span is TextSpan &&
          (span.text == text && span.style?.backgroundColor != null ||
              (span.children?.any((child) => hasHighlight(child, text)) ??
                  false));
      final session = harness.container.read(searchSessionProvider.notifier);
      for (final (query, highlighted) in [
        ('needle', ['needle']),
        ('cat', ['Cat', 'cat']),
        ('.*', ['.*']),
      ]) {
        session.query(query);
        await _waitForSearchCondition(
          tester,
          () => !harness.container.read(searchSessionProvider).searching,
        );
        await tester.pump();
        expect(
          harness.container.read(searchSessionProvider).results,
          hasLength(highlighted.length),
        );
        for (final text in highlighted) {
          expect(
            tester
                .widgetList<RichText>(find.byType(RichText))
                .any((rich) => hasHighlight(rich.text, text)),
            isTrue,
            reason:
                '$text must use the same literal, case-insensitive matching in Reading',
          );
        }
        expect(tester.takeException(), isNull);
      }
      expect(
        find.text('İ needle Cat catalog .*', findRichText: true),
        findsWidgets,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    },
  );

  testWidgets(
    'literal workspace search bounds malformed Markdown snippets around the match',
    (tester) async {
      final session = await _pumpSearchRegression(tester, headerBarService, {
        'a.md': 'Active document\n',
        'b.md': 'First line\n${'[' * 40000}needle\n',
      });
      session.events.add(const HeaderBarSearchQueryChanged('needle'));
      await _waitForSearchCondition(
        tester,
        () => find.text(l10n.searchResultLine('b.md', 2)).evaluate().isNotEmpty,
      );
      final results = find.byKey(const ValueKey('sidebar-search-results'));
      final title = tester
          .widgetList<Text>(
            find.descendant(of: results, matching: find.byType(Text)),
          )
          .singleWhere((text) => text.data?.contains('needle') == true)
          .data!;
      expect(title.length, lessThanOrEqualTo(120));
      expect(title, startsWith('…'));
      expect(title, endsWith('needle'));
      expect(
        session.container.read(workspaceControllerProvider).documentBuffers,
        hasLength(1),
      );
      // Result titles are also formatted during unrelated workspace rebuilds.
      final rebuild = Stopwatch()..start();
      final settings = session.container.read(appSettingsControllerProvider);
      await session.container
          .read(appSettingsControllerProvider.notifier)
          .setWordWrap(!settings.wordWrap);
      await tester.pump();
      rebuild.stop();
      expect(rebuild.elapsed, lessThan(const Duration(seconds: 1)));
      expect(find.text(title), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
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
        ..._smokeAccentOverrides,
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
      if (find
          .byKey(const ValueKey('workspace-page-frame'))
          .evaluate()
          .isNotEmpty) {
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
    await _waitForSearchCondition(
      tester,
      () => find.text('Second needle target').evaluate().isNotEmpty,
    );

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
        ..._smokeAccentOverrides,
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
        ..._smokeAccentOverrides,
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
      if (find
          .byKey(const ValueKey('workspace-page-frame'))
          .evaluate()
          .isNotEmpty) {
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
    await _waitForSearchCondition(
      tester,
      () => find
          .textContaining('second code needle target')
          .hitTestable()
          .evaluate()
          .isNotEmpty,
    );

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
    final service = _SearchWorkspaceService(_technicalReadmeSearchSource());
    final container = ProviderContainer(
      overrides: [
        ..._smokeAccentOverrides,
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
      if (find
          .byKey(const ValueKey('workspace-page-frame'))
          .evaluate()
          .isNotEmpty) {
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
    await _waitForSearchCondition(
      tester,
      () => find.textContaining(target).hitTestable().evaluate().isNotEmpty,
    );

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
        ..._smokeAccentOverrides,
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
        ..._smokeAccentOverrides,
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
      if (find
          .byKey(const ValueKey('workspace-page-frame'))
          .evaluate()
          .isNotEmpty) {
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
        ..._smokeAccentOverrides,
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
      if (find
          .byKey(const ValueKey('workspace-page-frame'))
          .evaluate()
          .isNotEmpty) {
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
        ..._smokeAccentOverrides,
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

    const target = 'conda activate example-service';
    final settingsStore = _MemorySettingsStore()
      ..value = AppSettings.defaults()
          .copyWith(documentViewMode: DocumentViewModePreference.preview)
          .toJson();
    final service = _SearchWorkspaceService(_technicalReadmeSearchSource());
    final container = ProviderContainer(
      overrides: [
        ..._smokeAccentOverrides,
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
      if (find
          .byKey(const ValueKey('workspace-page-frame'))
          .evaluate()
          .isNotEmpty) {
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
          ..._smokeAccentOverrides,
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
        ..._smokeAccentOverrides,
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

void _expectNeutralSidebarToggle(
  WidgetTester tester,
  String tooltip, {
  required bool selected,
}) {
  _expectNeutralHeaderControl(tester, tooltip, selected: selected);
}

void _expectNeutralHeaderControl(
  WidgetTester tester,
  String tooltip, {
  required bool selected,
}) {
  final finder = _headerIconButton(tooltip);
  expect(finder, findsOneWidget);
  final button = tester.widget<IconButton>(finder);
  final context = tester.element(finder);
  final colors = BusyMarkSurfaceColors.of(context);
  final states = selected
      ? const <WidgetState>{WidgetState.selected}
      : const <WidgetState>{};
  final foreground = button.style?.foregroundColor?.resolve(states);

  expect(button.isSelected, selected);
  expect(foreground, colors.foreground);
  expect(foreground, isNot(Theme.of(context).colorScheme.primary));
  for (final interaction in [WidgetState.hovered, WidgetState.pressed]) {
    expect(
      button.style?.foregroundColor?.resolve({...states, interaction}),
      foreground,
    );
  }
  expect(
    button.style?.backgroundColor?.resolve(states),
    selected
        ? colors.foreground.withValues(alpha: colors.foreground.a * .10)
        : Colors.transparent,
  );
}

Finder _headerIconButton(String tooltip) => find.byWidgetPredicate(
  (widget) =>
      widget is IconButton &&
      (widget.tooltip == tooltip ||
          widget.tooltip?.startsWith('$tooltip (') == true),
);

void _expectHeaderControlGap(
  WidgetTester tester, {
  required String leftTooltip,
  required String rightTooltip,
}) {
  final left = _headerIconButton(leftTooltip);
  final right = _headerIconButton(rightTooltip);
  expect(left, findsOneWidget);
  expect(right, findsOneWidget);
  expect(
    tester.getRect(right).left - tester.getRect(left).right,
    BusyMarkSpacing.headerInset,
  );
}

void _expectHeaderGeometry(WidgetTester tester) {
  final header = find.byType(BusyMarkLinuxHeaderLayout);
  expect(header, findsOneWidget);
  final headerRect = tester.getRect(header);
  final insets = LinuxPageHeaderInsetsScope.of(tester.element(header));
  final groups = find.descendant(
    of: header,
    matching: find.byType(BusyMarkLinuxHeaderControlGroup),
  );
  expect(groups, findsNWidgets(2));
  final groupRects = groups.evaluate().map((element) {
    return tester.getRect(find.byElementPredicate((other) => other == element));
  }).toList()..sort((left, right) => left.left.compareTo(right.left));
  expect(
    groupRects.first.left - headerRect.left - insets.leftObstruction,
    BusyMarkSpacing.headerInset,
  );
  expect(
    headerRect.right - groupRects.last.right - insets.rightObstruction,
    BusyMarkSpacing.headerInset,
  );
  final title = find.descendant(
    of: header,
    matching: find.byType(BusyMarkLinuxHeaderTitle),
  );
  expect(
    tester.getCenter(title).dx,
    closeTo((groupRects.first.right + groupRects.last.left) / 2, .01),
  );
  for (final button
      in find
          .descendant(of: groups, matching: find.byType(IconButton))
          .evaluate()) {
    final finder = find.byElementPredicate((element) => element == button);
    final rect = tester.getRect(finder);
    expect(rect.size, const Size.square(BusyMarkSizes.iconButton));
    expect(rect.top - headerRect.top, BusyMarkSpacing.headerInset);
    expect(headerRect.bottom - rect.bottom, BusyMarkSpacing.headerInset);
    final icon = find.descendant(
      of: finder,
      matching: find.byType(BusyMarkGtkHeaderIcon),
    );
    expect(tester.getSize(icon), const Size.square(BusyMarkSizes.iconSm));
    expect(tester.getCenter(icon), rect.center);
  }
}

List<Object?> _inlineAnchorPositions(BusyBlock block) => [
  for (final anchor in busyInlineSemanticAnchors(block.inlines))
    [anchor.offset, _inlineAnchorTree(anchor.inline)],
];

Object _inlineAnchorTree(BusyInline inline) => [
  inline.kind,
  inline.text,
  inline.destination,
  inline.attributes,
  [for (final child in inline.children) _inlineAnchorTree(child)],
];

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

String _technicalReadmeSearchSource() {
  return [
    '# Rendering Service',
    '',
    'Stateless document-rendering service exposing the **rendering API (version 1.x)** through a strict OpenAPI contract.',
    '',
    'This service performs **pure computation only**.',
    'Persistence, authentication, authorization, and rate-limiting are expected to be handled by an upstream service (e.g.',
    'a separate gateway).',
    '',
    'This service is designed to be deployed:',
    '',
    '* Behind an API gateway or reverse proxy',
    '* Without direct public exposure',
    '* Without authentication logic',
    '',
    '---',
    '',
    '## Conda Environment Setup',
    '',
    '```bash',
    'conda create -n example-service python=3.11',
    'conda activate example-service',
    'python -m pip install -e .',
    '```',
    '',
    'Install test dependencies:',
    '',
    '```bash',
    'conda install -n example-service pytest',
    '```',
    '',
    '---',
    '',
    '## Run the Service',
    '',
    '```bash',
    'uvicorn example_service.main:app --host 127.0.0.1 --port 8000',
    '```',
    '',
    'An application factory is also available:',
    '',
    '```python',
    'from example_service.main import create_app',
    '',
    'app = create_app()',
    '```',
    '',
    '---',
    '',
    '### Rendering Operations',
    '',
    '* `POST /v1/documents/validate`',
    '  Validate document syntax before rendering.',
    '',
    '* `POST /v1/documents/render`',
    '  Render a document and return:',
    '',
    '  ```json',
    '  { "document": {}, "diagnostics": {} }',
    '  ```',
    '',
    '* `POST /v1/documents/rebuild`',
    '  Rebuild document output **from source content**.',
    '',
    '  This endpoint **does not accept remote resources**.',
    '  It reads `source_blocks` to derive the document output.',
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

class _PendingHistoryRestoreStore extends MemoryLocalHistoryStore {
  final started = Completer<void>();
  final release = Completer<void>();

  @override
  Future<LocalHistoryCaptureResult> capture(
    LocalHistoryCaptureRequest request,
    LocalHistoryPolicy policy,
  ) async {
    if (request.reason == LocalHistoryCaptureReason.beforeRestore) {
      if (!started.isCompleted) started.complete();
      await release.future;
    }
    return super.capture(request, policy);
  }
}

class _NavigationHistoryStore extends MemoryLocalHistoryStore {
  var available = false;
  var protectiveAttempts = 0;
  @override
  Future<LocalHistoryCaptureResult> capture(
    LocalHistoryCaptureRequest request,
    LocalHistoryPolicy policy,
  ) async {
    if (request.force) protectiveAttempts++;
    if (!available) {
      throw const FileSystemException(
        'injected capture contention',
        '',
        OSError('', 11),
      );
    }
    return super.capture(request, policy);
  }
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

class _HistoryTestTimer implements Timer {
  _HistoryTestTimer(this.duration, this.callback);

  final Duration duration;
  final void Function() callback;
  var _active = true;

  void fire() {
    if (!_active) return;
    _active = false;
    callback();
  }

  @override
  void cancel() => _active = false;

  @override
  bool get isActive => _active;

  @override
  int get tick => _active ? 0 : 1;
}

class _MutableWorkspaceController extends WorkspaceController {
  _MutableWorkspaceController(this.initialState);

  final WorkspaceState initialState;
  Future<bool> Function(WritersideTopicCreateRequest)? createTopic;
  int createTopicCount = 0;
  WritersideTopicCreateRequest? createdTopicRequest;
  String? createdTopicTreePath;
  WritersideTopicCreatePlacement? movedTopicPlacement;
  List<int>? movedTopicSourcePath;
  List<int>? movedTopicReferencePath;
  WritersideTopicRemovalMode? analyzedRemovalMode;
  var appliedTopicRemovalCount = 0;
  String? selectedWritersideModuleId;
  String? selectedWritersideInstanceId;
  String? openedFilePath;
  DocumentViewModePreference? requestedEditorMode;
  var topicRenamePrepareCount = 0;
  final topicRenamePlans = <String, WritersideTopicRenamePlan>{};
  Future<bool>? topicRenameApplication;
  var simulateTopicRename = false;
  var rejectTopicRename = false;
  WritersideTopicRenamePlan? appliedTopicRenamePlan;

  void markWritersideProjectBufferDirty({
    required String path,
    required String text,
    required String lastSavedText,
  }) {
    state = state.copyWith(
      documentBuffers: [
        DocumentBuffer(
          id: 'topic-rename-dirty',
          filePath: path,
          text: text,
          lastSavedText: lastSavedText,
          dirty: true,
        ),
      ],
      activeBufferId: null,
    );
  }

  void clearDocumentBuffersForTest() {
    state = state.copyWith(documentBuffers: const [], activeBufferId: null);
  }

  @override
  void updateActiveEditorMode(DocumentViewModePreference mode) {
    requestedEditorMode = mode;
    final activeId = state.activeBufferId;
    if (activeId == null) return;
    state = state.copyWith(
      documentBuffers: [
        for (final buffer in state.documentBuffers)
          if (buffer.id == activeId)
            buffer.copyWith(
              editorState: buffer.editorState.copyWith(mode: mode),
            )
          else
            buffer,
      ],
    );
  }

  WritersideTocBatchMoveRequest? dragRequest;

  @override
  Future<WritersideTocMutationResult?> dragWritersideTocEntries({
    required String treePath,
    required WritersideTocBatchMoveRequest request,
  }) async {
    dragRequest = request;
    return null;
  }

  @override
  WorkspaceState build() => initialState;

  @override
  Future<SaveAllResult> saveAll({
    Iterable<String>? bufferIds,
    Map<String, LineEndingNormalization> mixedLineEndingNormalizations =
        const {},
  }) async {
    final included = bufferIds?.toSet();
    final saved = <String>[];
    final failed = <String>[];
    final replacements = <String, DocumentBuffer>{};
    for (final buffer in state.documentBuffers) {
      if (!buffer.isDirty ||
          buffer.filePath == null ||
          (included != null && !included.contains(buffer.id))) {
        continue;
      }
      try {
        File(buffer.filePath!).writeAsStringSync(buffer.text, flush: true);
        saved.add(buffer.id);
        replacements[buffer.id] = buffer.copyWith(
          lastSavedText: buffer.text,
          dirty: false,
          revision: buffer.revision + 1,
        );
      } on Object {
        failed.add(buffer.id);
      }
    }
    state = state.copyWith(
      documentBuffers: [
        for (final buffer in state.documentBuffers)
          replacements[buffer.id] ?? buffer,
      ],
    );
    return SaveAllResult(savedBufferIds: saved, failedBufferIds: failed);
  }

  @override
  Future<void> flushPersistence() async {}

  WritersideProjectIndex? editorIndexOverride;

  @override
  Future<WritersideProjectIndex?> writersideEditorIndex() async =>
      editorIndexOverride ?? state.workspace?.writersideProject?.index;

  @override
  Future<bool> applyWritersideRename(List<WritersideRenameEdit> edits) async {
    if (edits.isEmpty) return false;
    final activePath = state.workspace?.activeFilePath;
    if (activePath == null ||
        edits.any((edit) => edit.filePath != activePath)) {
      return false;
    }
    var source = state.activeText;
    final ordered = edits.toList()
      ..sort(
        (first, second) =>
            second.span.startOffset.compareTo(first.span.startOffset),
      );
    for (final edit in ordered) {
      final expected = edit.expectedText;
      if (expected == null ||
          edit.span.endOffset > source.length ||
          source.substring(edit.span.startOffset, edit.span.endOffset) !=
              expected) {
        return false;
      }
      source = source.replaceRange(
        edit.span.startOffset,
        edit.span.endOffset,
        edit.replacement,
      );
    }
    state = state.copyWith(activeText: source, isDirty: true);
    return true;
  }

  @override
  Future<ValidationOutcome> validateActive() async => ValidationOutcome(
    status: ValidationStatus.published,
    workspaceId: state.workspace?.id,
    filePath: state.workspace?.activeFilePath,
    bufferId: state.activeBuffer?.id,
    revision: editRevision,
    documentRevision: 0,
  );

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
    String? initialSource,
  }) async {
    createTopicCount++;
    createdTopicRequest = request;
    createdTopicTreePath = instanceTreePath;
    return createTopic?.call(request) ?? true;
  }

  @override
  Future<WritersideTopicRenamePlan?> prepareWritersideTopicRename(
    String topicPath,
    String newFileName, {
    required String topicModuleRoot,
  }) async {
    topicRenamePrepareCount++;
    final prepared = topicRenamePlans[newFileName];
    if (prepared != null) return prepared;
    try {
      return await const WorkspaceService().prepareWritersideTopicRename(
        state.workspace!,
        topicPath: topicPath,
        newFileName: newFileName,
        topicModuleRoot: topicModuleRoot,
      );
    } on Object catch (error) {
      state = state.copyWith(
        message: WorkspaceMessage(
          WorkspaceMessageCode.fileOperationFailed,
          error: error,
        ),
      );
      return null;
    }
  }

  @override
  Future<bool> applyWritersideTopicRename(WritersideTopicRenamePlan plan) {
    final workspace = state.workspace;
    if (workspace != null &&
        state.dirtyBuffers.any(
          (buffer) =>
              buffer.filePath != null &&
              isWritersideProjectPath(workspace, buffer.filePath!),
        )) {
      state = state.copyWith(
        message: const WorkspaceMessage(
          WorkspaceMessageCode.fileOperationFailed,
          error: BusyMarkException(
            'writerside.topic-file.project-buffers-dirty',
          ),
        ),
      );
      return Future.value(false);
    }
    appliedTopicRenamePlan = plan;
    if (rejectTopicRename) {
      state = state.copyWith(
        message: WorkspaceMessage(
          WorkspaceMessageCode.fileOperationFailed,
          error: BusyMarkException(
            'writerside.topic-file.topic-inventory-changed',
            args: {'path': plan.oldTopicPath},
          ),
        ),
      );
      return Future.value(false);
    }
    if (simulateTopicRename) return Future.value(true);
    final operation = _applyWritersideTopicRename(plan);
    topicRenameApplication = operation;
    return operation;
  }

  Future<bool> _applyWritersideTopicRename(
    WritersideTopicRenamePlan plan,
  ) async {
    try {
      await const WorkspaceService().applyWritersideTopicRename(plan);
      final refreshed = await const WorkspaceService().openPath(
        state.workspace!.rootPath,
      );
      final activePath = refreshed.activeFilePath;
      state = WorkspaceState(
        workspace: refreshed,
        activeText: activePath == null
            ? ''
            : File(activePath).readAsStringSync(),
      );
      return true;
    } on Object catch (error) {
      state = state.copyWith(
        message: WorkspaceMessage(
          WorkspaceMessageCode.fileOperationFailed,
          error: error,
        ),
      );
      return false;
    }
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
    final workspace = state.workspace!;
    final owner =
        workspace.writersideProject?.topicOwnerForPath(topicPath) ??
        workspace.writersideModule;
    final topic = owner!.topics.singleWhere(
      (candidate) => p.equals(candidate.filePath, topicPath),
    );
    final usagePath =
        workspace.writersideProject?.modules
            .where((module) => !p.equals(module.rootPath, owner.rootPath))
            .expand((module) => module.topics)
            .firstOrNull
            ?.filePath ??
        topicPath;
    return WritersideTopicRemovalAnalysis(
      mode: mode,
      projectRoot: workspace.rootPath,
      targetModuleRoot: owner.rootPath,
      hostModuleRoot: treePath == null
          ? owner.rootPath
          : workspace.writersideProject?.modules
                    .where(
                      (module) => module.instances.any(
                        (instance) =>
                            p.equals(instance.sourceTreePath, treePath),
                      ),
                    )
                    .firstOrNull
                    ?.rootPath ??
                owner.rootPath,
      topicPath: topicPath,
      topicFileName: topic.fileName,
      topicTitle: topic.title,
      oldWebFileName: '${p.basenameWithoutExtension(topic.fileName)}.html',
      selectedTreePath: treePath,
      selectedNodePath: nodePath,
      childCount: 0,
      isStartPage: false,
      usages: [
        WritersideTopicUsage(
          kind: WritersideTopicUsageKind.topicLink,
          filePath: usagePath,
          line: 1,
          column: 1,
          reference: topic.fileName,
          relevant: true,
          canUpdateAutomatically: true,
          moduleRoot: p.dirname(p.dirname(usagePath)),
        ),
      ],
      redirectTargets: const [],
      fingerprint: 'widget-test',
      projectModuleRoots: [
        for (final module in workspace.writersideProject?.modules ?? [owner])
          module.rootPath,
      ],
    );
  }

  @override
  Future<WritersideTopicRemovalResult?> applyWritersideTopicRemoval(
    WritersideTopicRemovalRequest request,
  ) async {
    appliedTopicRemovalCount++;
    return WritersideTopicRemovalResult(
      deletedFile:
          request.analysis.mode == WritersideTopicRemovalMode.safeDeleteFile,
      orphaned: false,
      promotedChildren: 0,
      redirectAdded: false,
      updatedUsageFiles: const [],
    );
  }

  @override
  Future<bool> openActiveFile(
    String path, {
    bool Function()? acceptNavigation,
  }) async {
    if (acceptNavigation?.call() == false) return false;
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
  Future<WorkspaceFileSnapshot> saveTextIfUnchanged(
    String path,
    String text, {
    required WorkspaceFileSnapshot expectedSnapshot,
  }) => saveText(path, text);

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
}

Future<void> _replaceWorkspaceWithoutFrame(
  WidgetTester tester,
  ProviderContainer container,
  String path,
) async {
  var complete = false;
  Object? failure;
  StackTrace? failureStack;
  final pending = container
      .read(workspaceControllerProvider.notifier)
      .openPath(path)
      .then<void>(
        (_) => complete = true,
        onError: (Object error, StackTrace stack) {
          failure = error;
          failureStack = stack;
          complete = true;
        },
      );
  final elapsed = Stopwatch()..start();
  while (!complete) {
    if (elapsed.elapsed >= const Duration(seconds: 10)) {
      throw TimeoutException('Workspace replacement before a frame');
    }
    // Unlike pump, idle drains existing fake-zone microtasks and zero-time
    // timers without rendering the transient null workspace.
    await tester.idle();
    if (!complete) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 1)),
      );
    }
  }
  await pending;
  if (failure != null) Error.throwWithStackTrace(failure!, failureStack!);
}

class _SwitchingGitController extends _PresetGitController {
  _SwitchingGitController(String firstRoot)
    : super(_gitSidebarShortcutState(firstRoot));

  @override
  Future<void> associateSharedRepository(
    Workspace workspace,
    shared.RepositoryId repository,
  ) async {
    expect(repository.root, workspace.rootPath);
    expect(repository.gitDir, '${workspace.rootPath}/.git');
    state = _gitSidebarShortcutState(
      workspace.rootPath,
    ).copyWith(attachedWorkspace: workspace);
  }
}

class _SwitchingSharedGitReadFixture extends SharedGitReadFixture {
  _SwitchingSharedGitReadFixture(String firstRoot)
    : super(_gitSidebarShortcutState(firstRoot));

  @override
  Future<shared.RepositoryId?> discover(
    String localPath, {
    shared.GitCancellation? cancellation,
  }) async =>
      SharedGitReadFixture(_gitSidebarShortcutState(localPath)).repository;
}

class _SwitchingTabbedWorkspaceService extends _TabbedWorkspaceService {
  _SwitchingTabbedWorkspaceService(String firstRoot)
    : super(rootPath: firstRoot, paths: ['$firstRoot/Intro.md']);

  @override
  Future<Workspace> openPath(String path) => _TabbedWorkspaceService(
    rootPath: path,
    paths: ['$path/Intro.md'],
  ).openPath(path);
}

class _TabbedWorkspaceService extends WorkspaceService {
  _TabbedWorkspaceService({
    required this.rootPath,
    required this.paths,
    this.kind = WorkspaceKind.markdownFolder,
  });

  final WorkspaceKind kind;
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
      kind: kind,
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
    final decoded = decodeUtf8Document(utf8.encode(text));
    return WorkspaceFileLoad(
      text: decoded.text,
      format: decoded.format,
      snapshot: WorkspaceFileSnapshot(
        modifiedAt: DateTime(2026),
        size: text.length,
        contentHash: path,
      ),
    );
  }

  @override
  Future<Workspace> reparseDocument(
    Workspace workspace,
    DocumentBuffer buffer,
  ) async {
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

  @override
  Future<WorkspaceFileSnapshot> saveTextIfUnchanged(
    String path,
    String text, {
    required WorkspaceFileSnapshot expectedSnapshot,
  }) => saveText(path, text);

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

Future<void> _waitForSearchCondition(
  WidgetTester tester,
  bool Function() condition, {
  int attempts = 300,
  String Function()? debugState,
}) async {
  for (var attempt = 0; attempt < attempts; attempt++) {
    await tester.pump(const Duration(milliseconds: 20));
    if (condition()) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
  }
  fail('Timed out waiting for workspace search. ${debugState?.call() ?? ''}');
}

BusyMarkSourceEditingController _searchSourceController(WidgetTester tester) =>
    tester
        .widgetList<TextField>(find.byType(TextField))
        .map((field) => field.controller)
        .whereType<BusyMarkSourceEditingController>()
        .single;

Future<
  ({ProviderContainer container, StreamController<HeaderBarSearchEvent> events})
>
_pumpSearchRegression(
  WidgetTester tester,
  LinuxHeaderBarService headerBar,
  Map<String, String> sources, {
  Set<String> oversized = const {},
  Set<String> unreadable = const {},
  DocumentViewModePreference mode = DocumentViewModePreference.source,
  LocalHistoryStore? historyStore,
}) async {
  final events = StreamController<HeaderBarSearchEvent>.broadcast();
  final settings = _MemorySettingsStore()
    ..value = AppSettings.defaults()
        .copyWith(autoSave: false, documentViewMode: mode)
        .toJson();
  final container = ProviderContainer(
    overrides: [
      ..._smokeAccentOverrides,
      systemAccentColorProvider.overrideWith((ref) => const Stream.empty()),
      workspaceFileMonitorProvider.overrideWith(
        (ref) => _SearchTestFileMonitor(),
      ),
      linuxHeaderBarServiceProvider.overrideWithValue(headerBar),
      headerBarSearchEventsProvider.overrideWith((ref) => events.stream),
      localSettingsStoreProvider.overrideWithValue(settings),
      if (historyStore != null)
        localHistoryStoreProvider.overrideWithValue(historyStore),
      workspaceServiceProvider.overrideWithValue(
        _SearchRegressionService(
          sources,
          oversized: oversized,
          unreadable: unreadable,
        ),
      ),
      startupPathProvider.overrideWithValue(
        '${_SearchRegressionService.root}/a.md',
      ),
    ],
  );
  addTearDown(() {
    container.dispose();
    unawaited(events.close());
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const BusyMarkApp()),
  );
  await _waitForSearchCondition(
    tester,
    () =>
        container.read(workspaceControllerProvider).activeBuffer != null &&
        find.byType(HeaderBarConfigurationPublisher).evaluate().isNotEmpty,
  );
  container
      .read(searchSessionProvider.notifier)
      .open(category: SearchCategory.workspace);
  await tester.pump();
  return (container: container, events: events);
}

class _SearchTestFileMonitor extends WorkspaceFileMonitor {
  @override
  Future<void> start({
    required String rootPath,
    required Iterable<String> openFilePaths,
  }) async {}
}

class _SearchRegressionService extends WorkspaceService {
  _SearchRegressionService(
    this.sources, {
    this.oversized = const {},
    this.unreadable = const {},
  });
  static const root = '/tmp/busymark-search-regression';
  final Map<String, String> sources;
  final Set<String> oversized;
  final Set<String> unreadable;
  Future<void> Function(String path)? beforeLoad;

  @override
  Future<Workspace> openPath(String path) async => Workspace(
    id: root,
    rootPath: root,
    kind: WorkspaceKind.markdownFolder,
    openedAt: DateTime(2026),
    activeFilePath: path,
    files: [
      for (final entry in sources.entries)
        DocumentFile(
          absolutePath: '$root/${entry.key}',
          relativePath: entry.key,
          kind: entry.key.endsWith('.cfg')
              ? DocumentKind.config
              : DocumentKind.markdown,
          size: oversized.contains(entry.key)
              ? 1024 * 1024 + 1
              : entry.value.length,
          lastModified: DateTime(2026),
        ),
    ],
    diagnostics: const [],
    markdown: markdownParser.parse(
      filePath: path,
      source: sources[p.basename(path)]!,
    ),
  );

  @override
  Future<String> loadText(String path) async {
    if (unreadable.contains(p.basename(path))) {
      throw FileSystemException('unreadable', path);
    }
    return sources[p.basename(path)]!;
  }

  @override
  Future<WorkspaceFileLoad> loadTextWithSnapshot(String path) async {
    await beforeLoad?.call(path);
    final text = await loadText(path);
    return WorkspaceFileLoad(
      text: text,
      snapshot: WorkspaceFileSnapshot(
        modifiedAt: DateTime(2026),
        size: text.length,
        contentHash: text,
      ),
    );
  }
}

class _SearchWorkspaceService extends WorkspaceService {
  const _SearchWorkspaceService(this.source);

  final String source;

  @override
  Future<Workspace> openPath(String path) async {
    final markdown = markdownParser.parse(
      filePath: path,
      source: source,
      mode: MarkdownMode.commonMark,
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
          kind: DocumentKind.markdown,
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
  Future<void> associateSharedRepository(
    Workspace workspace,
    shared.RepositoryId repository,
  ) async {
    // This controller owns a synthetic repository, alongside its mocked
    // attach/refresh methods. Keep real filesystem discovery out of fake time;
    // real association and metadata replacement have separate Git regressions.
    expect(repository.root, initialState.repositoryInfo!.rootPath);
    expect(repository.gitDir, initialState.repositoryInfo!.gitDirPath);
  }

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

Future<({String bundle, String storage})> _createSettingsSpellingFixture(
  Directory temporary,
) async {
  final bundle = await createSpellingTestBundle(temporary);
  final storage = p.join(temporary.path, 'dictionary-storage');
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

  final downloaded = Directory(p.join(storage, 'downloaded', 'en-Test'));
  final installedManifest =
      jsonDecode(
            await File(p.join(downloaded.path, 'manifest.json')).readAsString(),
          )
          as Map<String, Object?>;
  final imported = Directory(p.join(storage, 'imported', 'local-Test'));
  await imported.create(recursive: true);
  await File(
    p.join(downloaded.path, 'dictionary.aff'),
  ).copy(p.join(imported.path, 'dictionary.aff'));
  await File(
    p.join(downloaded.path, 'dictionary.dic'),
  ).copy(p.join(imported.path, 'dictionary.dic'));
  await File(p.join(imported.path, 'manifest.json')).writeAsString(
    jsonEncode({
      ...installedManifest,
      'kind': 'imported',
      'resourceId': 'local-Test',
      'id': 'local-Test',
      'locales': ['local-Test'],
      'label': 'Local Test English',
      'sourceRevision': 'local-import',
    }),
  );

  final invalid = Directory(p.join(storage, 'imported', 'xx-Test'));
  await invalid.create(recursive: true);
  await File(p.join(invalid.path, 'manifest.json')).writeAsString(
    jsonEncode({
      ...installedManifest,
      'kind': 'imported',
      'resourceId': 'xx-Test',
      'id': 'xx-Test',
      'locales': ['xx-Test'],
      'label': 'Broken import',
      'sourceRevision': 'local-import',
    }),
  );
  return (bundle: bundle, storage: storage);
}

class _SettingsSpellingHarness {
  _SettingsSpellingHarness({
    required this.temporary,
    required this.container,
    required this.spelling,
    this.projectSpellingPath,
  });

  final Directory temporary;
  final ProviderContainer container;
  final SpellingSessionController spelling;
  final String? projectSpellingPath;

  Future<void> dispose() async {
    container.dispose();
    if (await temporary.exists()) {
      await temporary.delete(recursive: true);
    }
  }
}

Future<_SettingsSpellingHarness> _pumpSettingsSpellingHarness(
  WidgetTester tester, {
  required LinuxHeaderBarService headerBarService,
  required _MemorySettingsStore settingsStore,
  required SpellingDictionaryFileDownload downloadFile,
  String? projectLanguage,
  SpellingCatalogLoader? catalogLoader,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(800, 900);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  late Directory temporary;
  late SpellingSessionController spelling;
  Workspace? workspace;
  String? projectSpellingPath;
  await tester.runAsync(() async {
    temporary = await Directory.systemTemp.createTemp(
      'busymark-settings-language-transaction-',
    );
    final fixture = await _createSettingsSpellingFixture(temporary);
    if (projectLanguage != null) {
      final projectRoot = Directory(p.join(temporary.path, 'project'));
      await projectRoot.create(recursive: true);
      await File(
        p.join(projectRoot.path, 'document.md'),
      ).writeAsString('# Project\n');
      projectSpellingPath = p.join(
        projectRoot.path,
        '.busymark',
        'spelling.json',
      );
      final projectFile = File(projectSpellingPath!);
      await projectFile.parent.create(recursive: true);
      await projectFile.writeAsString(
        jsonEncode({
          'schemaVersion': 1,
          'revision': 1,
          'projectLanguage': projectLanguage,
          'words': <String, Object?>{},
        }),
      );
      workspace = await const WorkspaceService().openPath(projectRoot.path);
    }
    spelling = SpellingSessionController(
      catalogLoader: catalogLoader ?? SpellingDictionaryCatalog.load,
      bundledRoot: fixture.bundle,
      applicationSupportRoot: p.join(temporary.path, 'support'),
      dictionaryStorageRoot: fixture.storage,
      verifyDictionaryChecksums: false,
      dictionaryDownloader: SpellingDictionaryDownloader(
        downloadFile: downloadFile,
      ),
    );
    await spelling.prepareSettings(workspace);
  });

  final container = ProviderContainer(
    overrides: [
      ..._smokeAccentOverrides,
      linuxHeaderBarServiceProvider.overrideWithValue(headerBarService),
      localSettingsStoreProvider.overrideWithValue(settingsStore),
      systemAccentColorProvider.overrideWith((ref) => const Stream.empty()),
      spellingSessionControllerProvider.overrideWith((ref) => spelling),
      if (workspace != null)
        startupPathProvider.overrideWithValue(workspace!.rootPath),
    ],
  );
  final preparedWorkspace = workspace;
  if (preparedWorkspace != null) {
    await tester.runAsync(
      () => container
          .read(workspaceControllerProvider.notifier)
          .openPath(preparedWorkspace.rootPath),
    );
    expect(
      container.read(workspaceControllerProvider).workspace?.rootPath,
      preparedWorkspace.rootPath,
    );
  }
  container.read(appRouterProvider).go('/settings?page=editor');
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const BusyMarkApp()),
  );
  await tester.pump();
  for (var attempt = 0; attempt < 20; attempt += 1) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  container.read(appRouterProvider).go('/settings?page=editor');
  await tester.pump();
  for (var attempt = 0; attempt < 10; attempt += 1) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  final l10n = AppLocalizationsEn();
  await _pumpUntilFound(tester, find.byTooltip(l10n.defaultSpellingLanguage));
  if (preparedWorkspace != null) {
    expect(
      container.read(workspaceControllerProvider).workspace?.rootPath,
      preparedWorkspace.rootPath,
    );
  }

  return _SettingsSpellingHarness(
    temporary: temporary,
    container: container,
    spelling: spelling,
    projectSpellingPath: projectSpellingPath,
  );
}

Future<void> _selectSpellingLanguage(
  WidgetTester tester, {
  required String selectorTooltip,
  required String languageLabel,
}) async {
  await tester.ensureVisible(find.byTooltip(selectorTooltip));
  await _pumpSettingsUi(tester);
  final selector = _spellingLanguageSelector(tester, selectorTooltip);
  final languageId = selector.options
      .singleWhere((option) => option.label == languageLabel)
      .value;
  // The selection can start a dictionary transaction after dialog confirmation.
  // Its real filesystem work must not wait for a widget pump after every await.
  await tester.runAsync(() async => selector.onSelected(languageId));
  await _pumpSettingsUi(tester);
}

Future<void> _openImportDictionaryPrompt(WidgetTester tester) async {
  final import = find.byKey(const ValueKey('import-spelling-dictionary'));
  if (import.evaluate().isEmpty) {
    final dictionariesNavigation = find.byKey(
      const ValueKey('settings-spelling-dictionaries'),
    );
    await tester.ensureVisible(dictionariesNavigation);
    await tester.tap(dictionariesNavigation);
    await _pumpUntilFound(tester, import);
  }
  await tester.ensureVisible(import);
  await _pumpSettingsUi(tester);
  // The async import flow resumes after the native picker and modal dialog.
  // Start it in the real zone so I/O continuations do not require fake frames.
  await tester.runAsync(() => tester.tap(import));
  await _pumpUntilFound(tester, find.byType(BusyMarkDialogShell));
}

BusyMarkPopupSelector<String> _spellingLanguageSelector(
  WidgetTester tester,
  String tooltip,
) {
  return tester.widget<BusyMarkPopupSelector<String>>(
    find.byWidgetPredicate(
      (widget) =>
          widget is BusyMarkPopupSelector<String> && widget.tooltip == tooltip,
    ),
  );
}

Future<void> _pumpUntilCondition(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 5),
  String Function()? diagnostics,
}) async {
  final deadline = DateTime.now().add(timeout);

  while (!condition() && DateTime.now().isBefore(deadline)) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
    // I/O progresses in runAsync; UI transitions and retry timers need the
    // test frame clock to advance as well. A zero-duration pump freezes them.
    await tester.pump(const Duration(milliseconds: 25));
  }
  expect(
    condition(),
    isTrue,
    reason: 'deadline exceeded. ${diagnostics?.call() ?? ''}',
  );
  await _pumpSettingsUi(tester);
}

Future<void> _pumpSettingsUi(WidgetTester tester) async {
  await tester.pump();
  for (var attempt = 0; attempt < 6; attempt += 1) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _copySettingsDictionaryDownload({
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

class _MemorySettingsStore implements LocalSettingsStore {
  bool failSaves = false;
  Map<String, Object?> value = <String, Object?>{};

  @override
  Future<Map<String, Object?>> load() async => value;

  @override
  Future<void> save(Map<String, Object?> json) async {
    if (failSaves) throw const FileSystemException('Fixture save failed');
    value = json;
  }
}

class _GatedRecentSettingsStore extends _MemorySettingsStore {
  _GatedRecentSettingsStore({required this.fail});
  final bool fail;
  final entered = Completer<void>();
  final release = Completer<void>();
  @override
  Future<void> save(Map<String, Object?> json) async {
    if ((json['recentWorkspaces'] as List?)?.isNotEmpty == true) {
      if (!entered.isCompleted) entered.complete();
      await release.future;
      if (fail) {
        throw StateError('injected recent-workspace persistence failure');
      }
    }
    await super.save(json);
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

// Smoke tests exercise application behavior with deterministic external accent
// I/O. The production coordinator/provider still run; readiness, deadline and
// GTK/portal event behavior are covered by the focused Linux accent tests.
final _smokeAccentOverrides = [
  sharedGitDraftStoreProvider.overrideWith((_) => shared.MemoryGitDraftStore()),
  sharedGitClientFactoryProvider.overrideWith(
    (ref) => ({required authorize, prompts}) {
      final controller = ref.read(gitControllerProvider.notifier);
      final state = controller is _PresetGitController
          ? controller.initialState
          : ref.read(gitControllerProvider);
      return SharedGitReadFixture(
        state,
        fileHistoryState: state.repositoryInfo == null
            ? null
            : _gitFileHistoryDiffState(state.repositoryInfo!.rootPath),
      );
    },
  ),
  linuxGtkAccentSourceProvider.overrideWithValue(
    const _UnavailableAccentSource(),
  ),
  linuxPortalAccentSourceProvider.overrideWithValue(
    const _UnavailableAccentSource(),
  ),
];

class _SearchableGitReadFixture extends SharedGitReadFixture {
  _SearchableGitReadFixture(super.state);

  @override
  Future<shared.GitContent> content(
    shared.RepositoryId repository,
    shared.RepoPath path,
    shared.ContentVersion version, {
    shared.GitCancellation? cancellation,
  }) async => shared.GitContent(
    path: path,
    version: version,
    availability: shared.ContentAvailability.present,
    token: version.kind.name,
    mode: '100644',
    bytes: utf8.encode(
      version.kind == shared.ContentKind.indexVersion
          ? '# Before\nold text\n'
          : '# After\nneedle comparison\n',
    ),
  );
}

class _UnavailableAccentSource implements LinuxAccentSource {
  const _UnavailableAccentSource();
  @override
  Stream<Color?> watchAccentColor() => Stream.value(null);
}

Future<void> _selectShortcutSettingsPage(WidgetTester tester) async {
  final nav = find.byKey(
    const ValueKey('settings-navigation-keyboardShortcuts'),
  );
  if (nav.evaluate().isNotEmpty) {
    await tester.tap(nav);
  } else {
    final l10n = AppLocalizations.of(
      tester.element(find.byType(SettingsScreen)),
    );
    await tester.tap(find.byKey(const ValueKey('settings-page-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.keyboardShortcuts).last);
  }
  await tester.pumpAndSettle();
}

Future<void> _revealShortcutRow(WidgetTester tester, String id) async {
  final list = find.byKey(const ValueKey('settings-shortcut-list'));
  final scrollable = find
      .descendant(of: list, matching: find.byType(Scrollable))
      .first;
  await tester.drag(scrollable, const Offset(0, 20000));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.byKey(ValueKey('shortcut-edit-$id')),
    300,
    scrollable: scrollable,
    maxScrolls: 100,
  );
  await tester.pumpAndSettle();
}

Future<void> _browseShortcutRow(WidgetTester tester, String id) async {
  await _revealShortcutRow(tester, id);
  await tester.tap(find.byKey(ValueKey('shortcut-edit-$id')));
  await tester.pumpAndSettle();
}

class _GatedRecoveryAdoptionStore extends MemoryDocumentRecoveryStore {
  final adopted = Completer<void>();
  final release = Completer<void>();
  @override
  Future<List<DocumentRecoveryAdoption>> adoptEntries(
    List<DocumentRecoveryEntry> entries,
  ) async {
    final result = await super.adoptEntries(entries);
    adopted.complete();
    await release.future;
    return result;
  }
}

class _DraftDuringShutdownController extends WorkspaceController {
  VoidCallback? onCleanShutdown;
  @override
  Future<void> markCleanShutdown() async {
    await super.markCleanShutdown();
    onCleanShutdown?.call();
  }
}
