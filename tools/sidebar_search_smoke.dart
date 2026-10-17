import 'package:busymark/src/platform/header_bar_configuration.dart';
import 'package:busymark/src/workspace/presentation/keyboard_shortcuts_settings.dart';
import 'package:busymark/src/workspace/presentation/settings_screen.dart';
// Native Linux search workflows with disposable files and a cached offline
// Notes account. All artifacts and navigation history stay in PRIVATE_OUTPUT.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:busymark/src/app/app_router.dart';
import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/app/busymark_app.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/busymark_glyphs.dart';
import 'package:busymark/src/app/busymark_search_field.dart';
import 'package:busymark/src/app/startup_path.dart';
import 'package:busymark/src/editor/source/source_editor.dart';
import 'package:busymark/src/editor/source_highlighter.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_inline_controller.dart';
import 'package:busymark/src/local_history/local_history_controller.dart';
import 'package:busymark/src/local_history/local_history_store.dart';
import 'package:busymark/src/local_history/local_history_models.dart';
import 'package:busymark/src/local_history/local_history_panel.dart';
import 'package:busymark/src/clipboard/clipboard_history_panel.dart';
import 'package:busymark/src/clipboard/clipboard_history_controller.dart';
import 'package:busymark/src/clipboard/clipboard_models.dart';
import 'package:busymark/src/workspace/text_format_metadata.dart';
import 'package:busymark/src/workspace/workspace_service.dart';
import 'package:busymark/src/search/search_sidebar.dart';
import 'package:busymark/src/app/command_registry.dart';
import 'package:busymark/src/app/keymap_controller.dart';
import 'package:busymark/src/app/shortcut_binding.dart';
import 'package:busymark/src/app/shortcut_capture.dart';
import 'package:busymark/src/nextcloud_notes/application/nextcloud_connection.dart';
import 'package:busymark/src/nextcloud_notes/application/notes_repository.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_store.dart';
import 'package:busymark/src/nextcloud_notes/domain/notes_models.dart';
import 'package:busymark/src/search/search_session.dart';
import 'package:busymark/src/search/welcome_notes_action.dart';
import 'package:busymark/src/workspace/recovery_persistence.dart';
import 'package:busymark/src/workspace/session_persistence.dart';
import 'package:busymark/src/workspace/workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:yaru/yaru.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty ||
      args.length > 2 ||
      args.length == 2 && args.last != '--large') {
    throw ArgumentError('PRIVATE_OUTPUT [--large]');
  }
  final large = args.length == 2;
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    exitCode = 1;
  };
  ui.PlatformDispatcher.instance.onError = (error, stack) {
    stderr.writeln('$error\n$stack');
    exitCode = 1;
    return true;
  };
  await windowManager.ensureInitialized();
  await YaruWindow.ensureInitialized();
  await windowManager.setSize(const Size(1100, 850));
  final output = await Directory(args.first).create(recursive: true);
  final store = await NotesStore.open(path: '${output.path}/notes.sqlite3');
  const account = '123e4567-e89b-42d3-a456-426614174000';
  await store.saveAccount(
    NextcloudAccount(
      id: account,
      server: Uri.parse('https://offline.example.invalid'),
      loginName: 'cached-fixture',
      appVersion: '6.1.0',
    ),
  );
  await store.saveNote(
    const NextcloudNote(
      localId: '223e4567-e89b-42d3-a456-426614174000',
      accountId: account,
      title: 'Cached individual note',
      category: 'Work/Offline',
      content: 'cached needle in an unopened note',
      revision: 1,
      ackRevision: 1,
    ),
  );
  await store.saveAccount(
    NextcloudAccount(
      id: '423e4567-e89b-42d3-a456-426614174001',
      server: Uri.parse('https://other-offline.example.invalid'),
      loginName: 'other-cached-fixture',
      appVersion: '6.1.0',
    ),
  );
  await store.saveNote(
    const NextcloudNote(
      localId: '523e4567-e89b-42d3-a456-426614174001',
      accountId: '423e4567-e89b-42d3-a456-426614174001',
      title: 'Cached individual note',
      category: 'Work/Offline',
      content: 'other account confidential needle',
      revision: 1,
      ackRevision: 1,
    ),
  );
  if (large) {
    for (var batch = 0; batch < 10000; batch += 100) {
      await store.commit(
        notes: [
          for (var i = batch; i < batch + 100; i++)
            NextcloudNote(
              localId:
                  '323e4567-e89b-42d3-a456-${i.toString().padLeft(12, '0')}',
              accountId: account,
              serverId: i + 1,
              title: 'Duplicate ${i % 250}',
              category: 'Area ${i % 20}/Group ${i % 71}',
              content: List.generate(
                14,
                (line) =>
                    'Row $line: café 中文 日本語 Привет مرحبا Ελληνικά. '
                    'Independent alpha beta record-$i corpus-token${i % 97}.',
              ).join('\n'),
              revision: 1,
              ackRevision: 1,
            ),
        ],
      );
    }
  }
  final repository = NotesRepository(
    store: store,
    clientForAccount: (_) async => throw const NotesException(
      NotesFailureCode.network,
      'Offline fixture',
      scope: NotesRequestScope.account,
    ),
  );
  await repository.initialize();
  runApp(
    ProviderScope(
      overrides: [
        startupPathProvider.overrideWithValue(null),
        localSettingsStoreProvider.overrideWithValue(_Settings()),
        documentSessionStoreProvider.overrideWithValue(
          MemoryDocumentSessionStore(),
        ),
        documentRecoveryStoreProvider.overrideWithValue(
          MemoryDocumentRecoveryStore(),
        ),
        workspaceServiceProvider.overrideWithValue(_TraceWorkspaceService()),
        localHistoryStoreProvider.overrideWithValue(
          _TraceHistoryStore(
            rootDirectory: () async => Directory('${output.path}/history'),
          ),
        ),
        nextcloudNotesRepositoryProvider.overrideWith(
          (ref) async => repository,
        ),
      ],
      child: _Driver(output, repository, large),
    ),
  );
}

class _Settings implements LocalSettingsStore {
  bool failSaves = false;
  Map<String, Object?> value = AppSettings.defaults()
      .copyWith(
        localeTag: 'en',
        themeModePreference: BusyMarkThemeModePreference.light,
        autoSave: false,
        automaticSpelling: false,
        reopenPreviousWorkspaceOnStartup: false,
        confirmCloseWithUnsavedChanges: false,
      )
      .toJson();
  @override
  Future<Map<String, Object?>> load() async => value;
  @override
  Future<void> save(Map<String, Object?> json) async {
    if (failSaves) {
      throw const FileSystemException('Disposable settings fixture');
    }
    value = json;
  }
}

class _TraceWorkspaceService extends WorkspaceService {
  int reads = 0;
  int readMicroseconds = 0;
  @override
  Future<String> loadText(String path) async {
    reads++;
    final watch = Stopwatch()..start();
    try {
      return await super.loadText(path);
    } finally {
      readMicroseconds += watch.elapsedMicroseconds;
    }
  }
}

class _TraceHistoryStore extends FileLocalHistoryStore {
  _TraceHistoryStore({required super.rootDirectory});
  int reads = 0;
  @override
  Future<LocalHistoryRevision?> readRevision(String revisionId) {
    reads++;
    return super.readRevision(revisionId);
  }
}

class _Driver extends ConsumerStatefulWidget {
  const _Driver(this.output, this.repository, this.large);
  final Directory output;
  final NotesRepository repository;
  final bool large;
  @override
  ConsumerState<_Driver> createState() => _DriverState();
}

class _DriverState extends ConsumerState<_Driver> {
  final boundary = GlobalKey();
  final measurements = <String, Object?>{};
  double _textScale = 1;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(run()));
  }

  @override
  Widget build(BuildContext context) => MediaQuery(
    data: MediaQueryData.fromView(
      View.of(context),
    ).copyWith(textScaler: TextScaler.linear(_textScale)),
    child: RepaintBoundary(key: boundary, child: const BusyMarkApp()),
  );
  SearchSessionState get search => ref.read(searchSessionProvider);
  WorkspaceController get workspace =>
      ref.read(workspaceControllerProvider.notifier);
  List<T> widgets<T extends Widget>() {
    final result = <T>[];
    void visit(Element e) {
      if (e.widget is Offstage && (e.widget as Offstage).offstage) return;
      if (e.widget is T) result.add(e.widget as T);
      e.visitChildren(visit);
    }

    WidgetsBinding.instance.rootElement!.visitChildren(visit);
    return result;
  }

  void check(bool value, String message) {
    if (!value) throw StateError(message);
    stdout.writeln('PASS $message');
  }

  Rect boundsForKey(Key key) {
    Rect? bounds;
    void visit(Element element) {
      if (element.widget.key == key) {
        final box = element.findRenderObject()! as RenderBox;
        bounds = box.localToGlobal(Offset.zero) & box.size;
      } else {
        element.visitChildren(visit);
      }
    }

    WidgetsBinding.instance.rootElement!.visitChildren(visit);
    return bounds ?? (throw StateError('Missing mounted bounds for $key'));
  }

  Future<void> wait(bool Function() test, String description) async {
    final end = DateTime.now().add(const Duration(seconds: 30));
    while (!test()) {
      if (DateTime.now().isAfter(end)) {
        throw StateError(
          'Timed out: $description; ${search.error}; '
          'route=${ref.read(appRouterProvider).routeInformationProvider.value.uri}; '
          'focus=${FocusManager.instance.primaryFocus}; '
          'pressed=${HardwareKeyboard.instance.logicalKeysPressed}',
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 30));
    }
  }

  Future<void> key(String key, {bool verifySearch = true}) async {
    final focusRequest = search.focusRequest;
    await windowManager.focus();
    final result = await Process.run(
      'python3',
      ['tools/nextcloud_notes_native_key.py', key],
      environment: {'BUSYMARK_NATIVE_ACCEPTANCE': '1'},
    );
    check(result.exitCode == 0, 'native $key delivery');
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (verifySearch &&
        const {
          'ctrl+f',
          'ctrl+shift+f',
          'ctrl+shift+d',
          'ctrl+shift+t',
          'ctrl+shift+r',
          'ctrl+shift+h',
          'ctrl+shift+l',
          'ctrl+shift+p',
        }.contains(key)) {
      check(
        search.focusRequest == focusRequest + 1,
        'native $key opens search exactly once '
        '($focusRequest → ${search.focusRequest})',
      );
    }
  }

  Future<void> query(String text) async {
    await wait(
      () => widgets<BusyMarkSearchField>().any(
        (f) => f.key == const ValueKey('shared-search-query'),
      ),
      'shared header query mounted',
    );
    changeQuery(text);
    await wait(() => !search.searching, 'query $text');
    check(search.error == null, 'query $text completed without error');
    await WidgetsBinding.instance.endOfFrame;
  }

  void changeQuery(String text) {
    final field = widgets<BusyMarkSearchField>().singleWhere(
      (f) => f.key == const ValueKey('shared-search-query'),
    );
    field.controller!.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    field.onChanged!(text);
  }

  // Provider events measure application work, excluding native injection and
  // the harness's polling intervals. Debounce remains part of user latency.
  Future<Map<String, Object?>> measuredQuery(String text) async {
    final files = ref.read(workspaceServiceProvider) as _TraceWorkspaceService;
    final history = ref.read(localHistoryStoreProvider) as _TraceHistoryStore;
    final reads = files.reads, historyReads = history.reads;
    final io = files.readMicroseconds;
    int? first, completed;
    var started = false;
    final watch = Stopwatch();
    final listener = ref.listenManual(searchSessionProvider, (_, state) {
      if (state.query != text) return;
      if (state.searching) started = true;
      if (started && state.results.isNotEmpty) {
        first ??= watch.elapsedMicroseconds;
      }
      if (started && !state.searching) completed ??= watch.elapsedMicroseconds;
    });
    try {
      watch.start();
      changeQuery(text);
      await wait(() => completed != null, 'measured query $text');
      check(search.error == null, 'measured query succeeds');
      return {
        'firstUsefulUs': first,
        'completedUs': completed,
        'fileReads': files.reads - reads,
        'summedFileReadUs': files.readMicroseconds - io,
        'revisionReads': history.reads - historyReads,
      };
    } finally {
      listener.close();
    }
  }

  Future<void> measuredCancellation(
    String label, {
    bool history = false,
  }) async {
    final files = ref.read(workspaceServiceProvider) as _TraceWorkspaceService;
    final revisions = ref.read(localHistoryStoreProvider) as _TraceHistoryStore;
    int reads() => history ? revisions.reads : files.reads;
    final before = reads();
    changeQuery('cancel-no-match-$label');
    await wait(() => reads() > before, 'active $label scan');
    final atSwitch = reads();
    final watch = Stopwatch()..start();
    int? first, complete;
    final subscription = ref.listenManual(searchSessionProvider, (_, value) {
      if (value.category != SearchCategory.actions) return;
      first ??= watch.elapsedMicroseconds;
      if (!value.searching && value.results.isNotEmpty) {
        complete ??= watch.elapsedMicroseconds;
      }
    });
    widgets<BusyMarkPopupSelector<SearchCategory>>().single.onSelected(
      SearchCategory.actions,
    );
    try {
      await wait(() => complete != null, 'Actions after $label cancellation');
      await Future<void>.delayed(const Duration(milliseconds: 180));
      check(
        search.results.every((r) => r is ActionSearchResult),
        '$label cancellation rejects stale progress and completion',
      );
      check(reads() == atSwitch, '$label cancellation starts no further reads');
      measurements['${label}Cancellation'] = {
        'categoryChangedUs': first,
        'actionsCompleteUs': complete,
        'readsBeforeSwitch': atSwitch - before,
        'readsAfterSwitch': reads() - atSwitch,
      };
    } finally {
      subscription.close();
    }
  }

  Future<void> historyJourney() async {
    final store = ref.read(localHistoryStoreProvider);
    final path = '${widget.output.path}/retired.md';
    final now = DateTime.now().toUtc();
    for (var i = 0; i < 20; i++) {
      await store.capture(
        LocalHistoryCaptureRequest(
          path: path,
          displayName: 'Retired document',
          source: i.isEven
              ? 'historical unique-needle $i'
              : 'another revision $i',
          format: TextFormatMetadata.utf8Lf,
          capturedAt: now.add(Duration(seconds: i)),
          reason: LocalHistoryCaptureReason.saved,
        ),
        const LocalHistoryPolicy(),
      );
    }
    await store.remapPath(path, '${widget.output.path}/renamed.md');
    await store.markDeleted(
      '${widget.output.path}/renamed.md',
      recursive: false,
    );
    final history = ref.read(localHistoryControllerProvider.notifier);
    await history.refresh();
    final before = ref.read(workspaceControllerProvider).activeBuffer!;
    await key('ctrl+shift+p');
    await query('Bold');
    await key('ctrl+f');
    await query('target');
    check(
      search.fileActive,
      'Actions to Ctrl+F selects only Search in Document',
    );
    await key('ctrl+shift+f');
    await query('scope needle');
    await key('ctrl+3');
    check(!search.active, 'ordinary Outline closes workspace search');
    await ref
        .read(busyMarkCommandRegistryProvider)
        .execute(BusyMarkCommandIds.findLocalHistory);
    await wait(
      () => search.active && search.category == SearchCategory.localHistory,
      'Find in Local History opens shared search',
    );
    await WidgetsBinding.instance.endOfFrame;
    measurements['historySearchApplicationTiming'] = [
      await measuredQuery('unique-needle'),
      await measuredQuery('another revision'),
      await measuredQuery('unique-needle'),
    ];
    check(
      search.results.length == 10,
      'all retained matching revisions discovered',
    );
    await measuredCancellation('history', history: true);
    ref.read(searchSessionProvider.notifier).openHistory();
    await query('unique-needle');
    final result = search.results.first as HistorySearchResult;
    final revision = (result.match as LocalHistoryRevisionMatch).revision;
    await key('enter');
    await wait(
      () =>
          ref
              .read(localHistoryControllerProvider)
              .selectedRevision
              ?.summary
              .id ==
          revision.id,
      'exact retained revision comparison',
    );
    check(search.active, 'revision comparison keeps sidebar search');
    check(
      ref.read(workspaceControllerProvider).activeText == before.text &&
          ref.read(workspaceControllerProvider).activeBufferId == before.id,
      'history inspection never opens or restores a live document',
    );
    await key('ctrl+5');
    await wait(
      () =>
          !search.active &&
          widgets<TextField>().every(
            (f) => f.key != const ValueKey('local-history-search'),
          ),
      'ordinary History timeline',
    );
    check(
      ref.read(localHistoryControllerProvider).selectedRevisions.length == 20,
      'ordinary History retains every revision without a hidden filter',
    );
    ref.read(searchSessionProvider.notifier).toggle();
    await wait(() => !search.searching, 'return to remembered History query');
    check(
      search.query == 'unique-needle' && search.results.length == 10,
      'History query remains in shared session',
    );
    await key('ctrl+shift+r');
    await query('a.md');
    await key('enter');
    await wait(
      () => !search.active,
      'Recent document activation after history',
    );
    check(
      ref.read(localHistoryControllerProvider).selectedRevision == null,
      'Recent opening reveals editor instead of stale history comparison',
    );
    await writeMeasurements();
  }

  Future<void> rapidChanges(String label, String finalQuery) async {
    for (var i = 0; i < 20; i++) {
      changeQuery('rapid-$i');
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    measurements['${label}AfterRapidChangesApplicationTiming'] =
        await measuredQuery(finalQuery);
    changeQuery('$finalQuery stale');
    await Future<void>.delayed(const Duration(milliseconds: 140));
    final cancelled = Stopwatch()..start();
    await key('ctrl+shift+p');
    await query('Bold');
    measurements['${label}SwitchToActionsWithNativeInjectionUs'] =
        cancelled.elapsedMicroseconds;
    check(
      search.category == SearchCategory.actions &&
          search.results.every((r) => r is ActionSearchResult),
      'no stale $label results after category switch',
    );
    await key('ctrl+shift+f');
    await query(finalQuery);
    await writeMeasurements();
  }

  Future<void> screenshot(String name) async {
    await WidgetsBinding.instance.endOfFrame;
    final render =
        boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await render.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File(
      '${widget.output.path}/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  }

  Future<void> captureNativeDisplay(String name, {Offset? hover}) async {
    final capture = await Process.run('/usr/bin/python3', [
      '-c',
      r"""
import gi, sys
gi.require_version('Gdk', '3.0')
from gi.repository import Gdk
root = Gdk.get_default_root_window()
if len(sys.argv) == 4:
    display = Gdk.Display.get_default()
    display.get_default_seat().get_pointer().warp(display.get_default_screen(), int(sys.argv[2]), int(sys.argv[3]))
    display.sync()
    import time
    time.sleep(.15)
pix = Gdk.pixbuf_get_from_window(root, 0, 0, root.get_width(), root.get_height())
pix.savev(sys.argv[1], 'png', [], [])
""",
      '${widget.output.path}/$name-native.png',
      if (hover != null) ...['${hover.dx.round()}', '${hover.dy.round()}'],
    ]);
    check(capture.exitCode == 0, '$name isolated native capture');
  }

  Future<void> selectorPresentation(String appearance) async {
    await key('ctrl+f');
    await query('');
    final rect = boundsForKey(const ValueKey('search-category'));
    final origin = await windowManager.getPosition();
    await captureNativeDisplay(
      '$appearance-selector-rest',
      hover: const Offset(1500, 1000),
    );
    await captureNativeDisplay(
      '$appearance-selector-hover',
      hover: origin + rect.center,
    );
    // Traverse into the same selector with actual keys, then open its GTK menu.
    bool categoryFocused() {
      var found = false;
      FocusManager.instance.primaryFocus?.context?.visitAncestorElements((e) {
        if (e.widget.key == const ValueKey('search-category')) {
          found = true;
          return false;
        }
        return true;
      });
      return found;
    }

    for (var i = 0; i < 30 && !categoryFocused(); i++) {
      await key('tab');
    }
    check(categoryFocused(), '$appearance selector keyboard focus');
    await captureNativeDisplay(
      '$appearance-selector-focus',
      hover: const Offset(1500, 1000),
    );
    await key('enter');
    await wait(
      () => widgets<Semantics>().any((s) => s.properties.expanded == true),
      '$appearance selector open',
    );
    await captureNativeDisplay('$appearance-selector-open');
    await key('escape');
    check(search.active, '$appearance popup Escape preserves search');
    await key('escape');
  }

  Future<void> action(String name) async {
    await key('ctrl+shift+p');
    await query(name);
    check(search.results.isNotEmpty, 'Action $name found');
    await key('enter');
  }

  Future<void> findReplaceNavigation() async {
    final original = ref.read(workspaceControllerProvider).activeText;
    for (final mode in ['source', 'split']) {
      await ref.read(busyMarkCommandRegistryProvider).execute('view.$mode');
      await wait(
        () =>
            ref
                .read(workspaceControllerProvider)
                .activeBuffer
                ?.editorState
                .mode
                .name ==
            mode,
        '$mode view is active',
      );
      for (final count in [81, 3000]) {
        final text =
            '# Find navigation\n${List.generate(count, (i) => 'needle $i\n').join()}';
        workspace.updateActiveText(text);
        await key('ctrl+f');
        await query('needle');
        await wait(
          () => widgets<TextField>().any(
            (field) =>
                field.controller is BusyMarkSourceEditingController &&
                (field.controller! as BusyMarkSourceEditingController)
                        .searchResult
                        .totalMatchCount ==
                    count,
          ),
          '$mode $count full match count',
        );
        final field = widgets<TextField>().singleWhere(
          (f) => f.controller is BusyMarkSourceEditingController,
        );
        final source = field.controller! as BusyMarkSourceEditingController;
        final editor =
            (widgets<BusyMarkSourceEditor>().single.key! as GlobalKey)
                    .currentState!
                as BusyMarkSourceEditorState;
        void press(String tooltip) => widgets<YaruIconButton>()
            .singleWhere((b) => b.tooltip == tooltip)
            .onPressed!();
        Future<void> selected(int index, String expectedText) async {
          final occurrence = RegExp(
            'needle',
          ).allMatches(expectedText).elementAt(index);
          await wait(
            () =>
                source.searchResult.currentMatchIndex == index &&
                source.fullSelection ==
                    TextSelection(
                      baseOffset: occurrence.start,
                      extentOffset: occurrence.end,
                    ),
            '$mode selected occurrence $index',
          );
          check(
            search.results.length <= 80 &&
                (search.results[search.selected] as TextSearchResult)
                        .match
                        .startOffset ==
                    occurrence.start,
            '$mode sidebar identifies occurrence $index in a bounded page',
          );
          await wait(
            () => widgets<BusyMarkSidebarRecordRow>().any(
              (row) =>
                  row.key ==
                      ValueKey(search.results[search.selected].identity) &&
                  row.selected,
            ),
            '$mode selected sidebar row revealed',
          );
        }

        Future<void> choose(int index) async {
          final occurrence = RegExp('needle').allMatches(text).elementAt(index);
          editor.scrollToSearchRange(
            line: index + 2,
            startOffset: occurrence.start,
            endOffset: occurrence.end,
          );
          await selected(index, text);
        }

        editor.scrollToOffset(0);
        await wait(
          () => widgets<BusyMarkCompactIconButton>().any(
            (button) => button.tooltip == 'Collapse section',
          ),
          '$mode first section is visible for folding',
        );
        widgets<BusyMarkCompactIconButton>()
            .firstWhere((button) => button.tooltip == 'Collapse section')
            .onPressed!();
        await WidgetsBinding.instance.endOfFrame;
        check(
          source.document.hiddenRanges.ranges.isNotEmpty,
          '$mode search starts with folded content',
        );
        press('Previous match');
        await selected(count - 1, text);
        check(
          !source.searchResult.currentMatch!.hidden,
          '$mode navigation unfolds the actual final occurrence',
        );
        press('Next match');
        await selected(0, text);
        await choose(79);
        press('Next match');
        await selected(80, text);
        press('Previous match');
        await selected(79, text);
        final index = count == 81 ? 80 : 2500;
        await choose(index);
        final replacement = widgets<TextField>().singleWhere(
          (f) => f.key == const ValueKey('source-search-replacement'),
        );
        replacement.controller!.text = 'changed';
        replacement.onChanged!('changed');
        await WidgetsBinding.instance.endOfFrame;
        final occurrence = RegExp('needle').allMatches(text).elementAt(index);
        final modified = text.replaceRange(
          occurrence.start,
          occurrence.end,
          'changed',
        );
        press('Replace and find next');
        await wait(
          () => source.fullText == modified,
          '$mode replacement beyond first page',
        );
        await selected(count == 81 ? 0 : index, modified);
        check(
          RegExp('changed').allMatches(source.fullText).length == 1,
          '$mode replaces exactly once',
        );
        final editable = field.focusNode!.context!
            .findAncestorStateOfType<EditableTextState>()!
            .renderEditable;
        await wait(() {
          final caret = editable.getLocalRectForCaret(
            TextPosition(offset: source.selection.extentOffset),
          );
          return caret.top >= 0 &&
              caret.bottom <= editable.size.height &&
              (mode != 'split' ||
                  count != 3000 ||
                  editable.localToGlobal(caret.topLeft).dy >
                      boundsForKey(
                        const ValueKey('source-search-replacement'),
                      ).bottom);
        }, '$mode replacement caret becomes visible');
        check(
          source.fullSelection.extentOffset ==
              RegExp(
                'needle',
              ).allMatches(modified).elementAt(count == 81 ? 0 : index).end,
          '$mode replacement caret remains visible',
        );
        await screenshot('find-replace-$mode-$count');
        await key('ctrl+z');
        await wait(() => source.fullText == text, '$mode replacement Undo');
        await key('ctrl+shift+z');
        await wait(() => source.fullText == modified, '$mode replacement Redo');
        await key('escape');
      }
    }
    workspace.updateActiveText(original);
    await ref.read(busyMarkCommandRegistryProvider).execute('view.source');
    await wait(
      () => widgets<TextField>().any(
        (f) =>
            f.controller is BusyMarkSourceEditingController &&
            (f.controller! as BusyMarkSourceEditingController).fullText ==
                original,
      ),
      'restore native workflow document',
    );
  }

  Future<void> presentationJourney(String appearance) async {
    final controller = ref.read(searchSessionProvider.notifier);
    final before = ref.read(workspaceControllerProvider).activeText;
    final files = ref.read(workspaceServiceProvider) as _TraceWorkspaceService;
    final history = ref.read(localHistoryStoreProvider) as _TraceHistoryStore;
    // These expected initial behaviors are independent of coordinator helpers.
    final samples = <SearchCategory, String>{
      SearchCategory.file: 'semantic',
      SearchCategory.workspace: 'semantic',
      SearchCategory.outline: 'Outline presentation',
      SearchCategory.documents: 'outside-search',
      SearchCategory.topics: 'outside-search',
      SearchCategory.recent: 'a.md',
      SearchCategory.localHistory: 'unique-needle',
      SearchCategory.actions: '',
    };
    for (final entry in samples.entries) {
      controller.open(category: entry.key);
      await query('');
      final fileReads = files.reads, revisionReads = history.reads;
      final listsInitially = entry.key == SearchCategory.actions;
      controller.showMore();
      await controller.submit();
      await Future<void>.delayed(const Duration(milliseconds: 150));
      check(
        search.waitingForInput != listsInitially &&
            (listsInitially
                ? search.results.isNotEmpty
                : search.results.isEmpty),
        '$appearance ${entry.key.name} correct initial list',
      );
      check(
        files.reads == fileReads && history.reads == revisionReads,
        '$appearance ${entry.key.name} empty query does not read providers',
      );
      check(
        widgets<BusyMarkSearchField>()
                .where((f) => f.key == const ValueKey('shared-search-query'))
                .length ==
            1,
        '$appearance one shared query',
      );
      if (!listsInitially) {
        await screenshot('$appearance-${entry.key.name}-empty');
        await query('zz-no-search-match-984134');
        check(
          search.results.isEmpty && !search.waitingForInput,
          '$appearance ${entry.key.name} completed no-results',
        );
      }
      await query(entry.value);
      check(
        search.results.isNotEmpty,
        '$appearance ${entry.key.name} representative results',
      );
      check(
        widgets<ListTile>().isEmpty,
        '$appearance uses native sidebar record rows',
      );
      check(
        !widgets<Text>().any((t) => ['Aa', 'W', '.*'].contains(t.data)),
        '$appearance no matching-mode controls',
      );
      await screenshot('$appearance-${entry.key.name}-results');
      if (entry.key == SearchCategory.actions) {
        await query(BusyMarkCommandIds.syncNotes);
        check(
          search.results.single is ActionSearchResult &&
              !(search.results.single as ActionSearchResult).enabled,
          '$appearance Notes action has truthful unavailable context',
        );
        await WidgetsBinding.instance.endOfFrame;
        final row = widgets<BusyMarkSidebarRecordRow>().singleWhere(
          (r) => r.key == ValueKey(BusyMarkCommandIds.syncNotes),
        );
        check(
          row.onTap == null,
          '$appearance disabled action has no active callback',
        );
        await screenshot('$appearance-actions-disabled');
        await key('enter');
        check(
          search.active && search.query == BusyMarkCommandIds.syncNotes,
          '$appearance disabled Enter keeps the same result and search',
        );
      }

      check(
        ref.read(workspaceControllerProvider).activeText == before,
        '$appearance ${entry.key.name} query is source-neutral',
      );
    }
    if (appearance == 'light') {
      final missing = File('${widget.output.path}/documents/a.md');
      await missing.delete();
      final owner = ref.read(workspaceControllerProvider).workspace!.id;
      controller.open(category: SearchCategory.recent);
      await query('a.md');
      check(
        search.results.single is RecentSearchResult &&
            (search.results.single as RecentSearchResult).resource.path ==
                missing.path,
        'missing Recent retains the exact resource identity',
      );
      await key('enter');
      await wait(
        () => widgets<Text>().any(
          (t) => t.data == 'This resource is unavailable.',
        ),
        'missing Recent resource feedback',
      );
      check(
        ref.read(workspaceControllerProvider).workspace!.id == owner &&
            ref.read(workspaceControllerProvider).activeText == before,
        'missing Recent cannot substitute another resource or change the editor',
      );
      await screenshot('missing-recent-resource');
    }
    controller.close();
    await selectorPresentation(appearance);
    await shortcutSettingsPresentation(appearance);
    await historyPanelsPresentation(appearance);
  }

  Future<void> literalMatcherJourney() async {
    final original = ref.read(workspaceControllerProvider).activeText;
    for (final mode in ['source', 'split']) {
      await ref.read(busyMarkCommandRegistryProvider).execute('view.$mode');
      const text = r'Cat catalog .* $1 😀';
      workspace.updateActiveText(text);
      await key('ctrl+f');
      await query('cat');
      check(
        search.documentMatchCount == 2,
        '$mode case-insensitive partial words',
      );
      await query('.*');
      check(search.documentMatchCount == 1, '$mode punctuation is literal');
      final source =
          widgets<TextField>()
                  .singleWhere(
                    (f) => f.controller is BusyMarkSourceEditingController,
                  )
                  .controller!
              as BusyMarkSourceEditingController;
      void press(String tooltip) => widgets<YaruIconButton>()
          .singleWhere((b) => b.tooltip == tooltip)
          .onPressed!();
      await wait(
        () =>
            source.searchResult.totalMatchCount == 1 &&
            widgets<YaruIconButton>().any(
              (b) => b.tooltip == 'Next match' && b.onPressed != null,
            ),
        '$mode Source receives literal query snapshot',
      );
      press('Next match');
      await wait(
        () =>
            source.fullSelection ==
            const TextSelection(baseOffset: 12, extentOffset: 14),
        '$mode literal occurrence selection',
      );
      final replacement = widgets<TextField>().singleWhere(
        (f) => f.key == const ValueKey('source-search-replacement'),
      );
      replacement.controller!.text = r'$1';
      replacement.onChanged!(r'$1');
      await WidgetsBinding.instance.endOfFrame;
      press('Replace and find next');
      await wait(
        () => source.fullText == r'Cat catalog $1 $1 😀' && !search.searching,
        '$mode literal replacement',
      );
      await key('ctrl+z');
      await wait(
        () => source.fullText == text,
        '$mode literal replacement Undo',
      );
      await key('ctrl+shift+z');
      await wait(
        () => source.fullText == r'Cat catalog $1 $1 😀',
        '$mode literal replacement Redo',
      );
      await query('😀');
      check(search.documentMatchCount == 1, '$mode Unicode literal occurrence');
      final match = (search.results.single as TextSearchResult).match;
      check(
        source.fullText.substring(match.startOffset, match.endOffset) == '😀',
        '$mode complete Unicode source boundaries',
      );
      await key('escape');
    }
    workspace.updateActiveText(original);
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<void> openShortcutSettings() async {
    await key('ctrl+alt+s', verifySearch: false);
    await wait(() => widgets<SettingsScreen>().isNotEmpty, 'Settings route');
    final nav = widgets<BusyMarkSidebarNavigationTile>().where(
      (r) => r.key == const ValueKey('settings-navigation-keyboardShortcuts'),
    );
    if (nav.isNotEmpty) {
      nav.single.onTap();
    } else {
      widgets<BusyMarkMenuButton<SettingsPage>>().single.onSelected(
        SettingsPage.keyboardShortcuts,
      );
    }
    await wait(
      () => widgets<KeyboardShortcutsSettings>().isNotEmpty,
      'Keyboard Shortcuts through Settings',
    );
  }

  Future<void> categoryShortcutsJourney() async {
    const bindings = {
      SearchCategory.file: 'ctrl+f',
      SearchCategory.workspace: 'ctrl+shift+f',
      SearchCategory.outline: 'ctrl+shift+h',
      SearchCategory.documents: 'ctrl+shift+d',
      SearchCategory.topics: 'ctrl+shift+t',
      SearchCategory.recent: 'ctrl+shift+r',
      SearchCategory.localHistory: 'ctrl+shift+l',
      SearchCategory.actions: 'ctrl+shift+p',
    };
    final before = ref.read(workspaceControllerProvider).activeText;
    for (final entry in bindings.entries) {
      await key(entry.value);
      check(
        search.category == entry.key,
        '${entry.key.name} direct command destination',
      );
      final selector = widgets<BusyMarkPopupSelector<SearchCategory>>().single;
      final option = selector.options.singleWhere((o) => o.value == entry.key);
      final command = ref.read(
        busyMarkCommandRegistryProvider,
      )[searchCommandForCategory(entry.key)]!;
      check(
        option.shortcut == command.shortcut!.label &&
            option.gtkAccelerator == command.shortcut!.gtkAccelerator,
        '${entry.key.name} effective selector metadata',
      );
      check(
        widgets<TextField>()
            .singleWhere(
              (f) => identical(
                f.controller,
                widgets<BusyMarkSearchField>()
                    .singleWhere(
                      (f) => f.key == const ValueKey('shared-search-query'),
                    )
                    .controller,
              ),
            )
            .focusNode!
            .hasFocus,
        '${entry.key.name} focuses shared query',
      );
      final keymap = ref.read(keymapControllerProvider.notifier);
      final id = searchCommandForCategory(entry.key);
      Map<String, BusyMarkKeyBinding?> overrides() =>
          ref.read(appSettingsControllerProvider).shortcutOverrides;
      check(
        (await keymap.update(
              id,
              const BusyMarkKeyBinding(LogicalKeyboardKey.f8),
              expected: overrides(),
            )).status ==
            KeymapUpdateStatus.saved,
        '${entry.key.name} custom assignment',
      );
      await WidgetsBinding.instance.endOfFrame;
      var request = search.focusRequest;
      await key(entry.value, verifySearch: false);
      check(
        search.focusRequest == request,
        '${entry.key.name} former default removed',
      );
      await key('F8', verifySearch: false);
      check(
        search.focusRequest == request + 1 && search.category == entry.key,
        '${entry.key.name} custom binding executes once',
      );
      check(
        widgets<BusyMarkPopupSelector<SearchCategory>>().single.options
                .singleWhere((o) => o.value == entry.key)
                .shortcut ==
            'F8',
        '${entry.key.name} custom option label',
      );
      await keymap.update(id, null, expected: overrides());
      await WidgetsBinding.instance.endOfFrame;
      request = search.focusRequest;
      await key('F8', verifySearch: false);
      await key(entry.value, verifySearch: false);
      check(
        search.focusRequest == request,
        '${entry.key.name} unassigned binding and default inactive',
      );
      final unassigned = widgets<BusyMarkPopupSelector<SearchCategory>>()
          .single
          .options
          .singleWhere((o) => o.value == entry.key);
      check(
        unassigned.shortcut == null && unassigned.gtkAccelerator == null,
        '${entry.key.name} unassigned metadata removed',
      );
      await keymap.update(id, null, reset: true, expected: overrides());
      await key(entry.value);
      check(
        search.category == entry.key,
        '${entry.key.name} reset default destination',
      );
    }
    await key('escape');
    for (final old in ['ctrl+p', 'ctrl+alt+h', 'ctrl+alt+o', 'ctrl+alt+y']) {
      final request = search.focusRequest;
      await key(old, verifySearch: false);
      check(
        !search.active && search.focusRequest == request,
        'old default $old has no implicit alias',
      );
    }
    await key('ctrl+alt+k', verifySearch: false);
    check(
      widgets<KeyboardShortcutsSettings>().isEmpty,
      'retired Ctrl+Alt+K does not open Settings',
    );
    check(
      ref.read(workspaceControllerProvider).activeText == before,
      'category shortcuts preserve source',
    );
  }

  Future<void> historyPanelsPresentation(String stage) async {
    final originalSize = await windowManager.getSize();
    // Ordinary browsing has a workspace breakpoint; its sidebar itself stays
    // 300 px wide. Search and Settings are separately exercised at 600 px.
    final expand =
        originalSize.width < BusyMarkSizes.workspaceSidebarBreakpoint;
    if (expand) {
      await windowManager.setSize(
        Size(BusyMarkSizes.workspaceSidebarBreakpoint, originalSize.height),
      );
      await wait(
        () =>
            (boundary.currentContext?.size?.width ?? 0) >=
            BusyMarkSizes.workspaceSidebarBreakpoint,
        'ordinary sidebar width threshold',
      );
    }
    try {
      final before = ref.read(workspaceControllerProvider).activeText;
      bool hasInput(Type panel) {
        var input = false;
        void descendants(Element e) {
          if (e.widget is EditableText) input = true;
          e.visitChildren(descendants);
        }

        void visit(Element e) {
          if (e.widget.runtimeType == panel) {
            descendants(e);
          } else {
            e.visitChildren(visit);
          }
        }

        WidgetsBinding.instance.rootElement!.visitChildren(visit);
        return input;
      }

      await key('ctrl+5', verifySearch: false);
      await wait(
        () => widgets<LocalHistoryPanel>().isNotEmpty,
        'ordinary History panel',
      );
      check(
        !search.active && !hasInput(LocalHistoryPanel),
        '$stage ordinary History has no search',
      );
      final historyMenu = widgets<BusyMarkHeaderPopupMenuButton>().singleWhere(
        (m) => m.key == const ValueKey('local-history-actions-menu'),
      );
      final historyItems = (await historyMenu.itemBuilder(
        rootNavigatorKey.currentContext!,
      )).whereType<BusyMarkPopupMenuItem>().toList();
      check(
        historyItems.length == 3 &&
            historyItems.every((m) => m.icon != BusyMarkGlyphs.search),
        '$stage History only has Refresh and confirmed clear operations',
      );
      (historyMenu as dynamic).onSelected(historyItems.first.menuValue);
      await wait(
        () => !ref.read(localHistoryControllerProvider).loading,
        'History refresh',
      );
      await screenshot('ordinary-history-$stage');
      await ref
          .read(busyMarkCommandRegistryProvider)
          .execute(BusyMarkCommandIds.clipboardHistory);
      await wait(
        () => widgets<ClipboardHistoryPanel>().isNotEmpty,
        'Clipboard panel',
      );
      check(
        !hasInput(ClipboardHistoryPanel),
        '$stage Clipboard History has no search',
      );
      await screenshot('clipboard-history-initial-$stage');
      final clipboard = ref.read(clipboardHistoryControllerProvider.notifier);
      clipboard.retain(
        const BusyMarkClipboardCapture(
          kind: BusyMarkClipboardContentKind.text,
          text: 'Retained panel entry',
          sourceText: 'Retained panel entry',
        ),
      );
      await WidgetsBinding.instance.endOfFrame;
      await screenshot('clipboard-history-populated-$stage');
      final menu = widgets<BusyMarkHeaderPopupMenuButton>().singleWhere(
        (m) => m.key == const ValueKey('clipboard-history-actions-menu'),
      );
      final items = (await menu.itemBuilder(
        rootNavigatorKey.currentContext!,
      )).whereType<BusyMarkPopupMenuItem>().toList();
      check(items.length == 2, '$stage Clipboard management menu');
      (menu as dynamic).onSelected(items.first.menuValue);
      await wait(
        () => !ref.read(clipboardHistoryControllerProvider).refreshing,
        'Clipboard refresh',
      );
      (menu as dynamic).onSelected(items.last.menuValue);
      check(
        ref.read(clipboardHistoryControllerProvider).entries.isEmpty,
        '$stage Clipboard clear',
      );
      check(
        ref.read(workspaceControllerProvider).activeText == before,
        '$stage History browsing preserves source',
      );
    } finally {
      if (expand) {
        await windowManager.setSize(originalSize);
        await wait(
          () =>
              (boundary.currentContext?.size?.width ?? 0) <= originalSize.width,
          'restore narrow search viewport',
        );
      }
    }
  }

  Future<void> browseShortcut(String id) async {
    Element? locate(Key key) {
      Element? found;
      void visit(Element e) {
        if (e.widget.key == key) {
          found = e;
        } else {
          e.visitChildren(visit);
        }
      }

      WidgetsBinding.instance.rootElement!.visitChildren(visit);
      return found;
    }

    final list = locate(const ValueKey('settings-shortcut-list'))!;
    ScrollableState? scrolling;
    void findScroll(Element e) {
      if (e is StatefulElement && e.state is ScrollableState) {
        scrolling ??= e.state as ScrollableState;
      }
      e.visitChildren(findScroll);
    }

    findScroll(list);
    final position = scrolling!.position;
    position.jumpTo(0);
    await WidgetsBinding.instance.endOfFrame;
    for (var step = 0; step < 100; step++) {
      final row = locate(ValueKey('shortcut-edit-$id'));
      if (row != null) {
        await Scrollable.ensureVisible(
          row,
          alignment: .5,
          duration: const Duration(milliseconds: 80),
        );
        await WidgetsBinding.instance.endOfFrame;
        check(
          (row.widget as BusyMarkActionRow).enabled,
          'browse configurable $id',
        );
        (row.widget as BusyMarkActionRow).onTap!();
        return;
      }
      final next = (position.pixels + position.viewportDimension * .8).clamp(
        0.0,
        position.maxScrollExtent,
      );
      if (next == position.pixels) break;
      position.jumpTo(next);
      await WidgetsBinding.instance.endOfFrame;
    }
    throw StateError('Command row not found by browsing: $id');
  }

  Future<void> shortcutSettingsPresentation(String stage) async {
    final before = ref.read(workspaceControllerProvider).activeText;
    await openShortcutSettings();
    await wait(
      () => widgets<KeyboardShortcutsSettings>().isNotEmpty,
      'shortcut Settings $stage',
    );
    check(
      !BusyMarkShortcutCapture.suppressing,
      'ordinary Settings browsing owns no capture session',
    );
    check(
      widgets<BusyMarkSearchField>().every(
        (f) => f.key != const ValueKey('settings-shortcut-search'),
      ),
      'shortcut Settings has no query control',
    );
    await screenshot('shortcuts-settings-$stage');
    await browseShortcut('file.save');
    await wait(
      () => widgets<Dialog>().isNotEmpty,
      'Settings assignment dialog',
    );
    await Future<void>.delayed(const Duration(milliseconds: 220));
    await screenshot('shortcut-assignment-$stage');
    widgets<BusyMarkActionRow>()
        .singleWhere((r) => r.key == const ValueKey('record-shortcut'))
        .onTap!();
    await key('ctrl+o', verifySearch: false);
    check(
      !BusyMarkShortcutCapture.suppressing,
      '$stage capture releases native dispatch',
    );
    await Future<void>.delayed(const Duration(milliseconds: 220));
    await screenshot('shortcut-conflict-$stage');
    await key('escape');
    await wait(
      () => widgets<Dialog>().isEmpty,
      'assignment cancellation $stage',
    );

    if (stage == 'light' || stage == 'dark') {
      widgets<BusyMarkSidebarNavigationTile>()
          .singleWhere(
            (r) => r.key == const ValueKey('settings-navigation-appearance'),
          )
          .onTap();
      await wait(
        () => widgets<BusyMarkPopupSelector<String>>().isNotEmpty,
        'Settings language selector',
      );
      await captureNativeDisplay('settings-selectors-$stage');
    }
    check(
      ref.read(workspaceControllerProvider).activeText == before,
      'Settings $stage leaves source unchanged',
    );
    await key('alt+Left');
    await wait(
      () =>
          ref.read(appRouterProvider).routeInformationProvider.value.uri.path ==
          '/workspace',
      'Settings return $stage',
    );
  }

  Future<void> keymapJourney() async {
    final router = ref.read(appRouterProvider);
    await workspace.saveActive();
    router.go('/');
    await wait(
      () => router.routeInformationProvider.value.uri.path == '/',
      'Welcome before keymap',
    );
    await openShortcutSettings();
    await wait(
      () => widgets<KeyboardShortcutsSettings>().isNotEmpty,
      'shortcut Settings from Welcome',
    );
    check(
      router.routeInformationProvider.value.uri.queryParameters['returnTo'] ==
          'welcome',
      'Welcome Settings return target',
    );
    await openShortcutSettings();
    check(
      router.routeInformationProvider.value.uri.queryParameters['returnTo'] ==
          'welcome',
      'Settings shortcut keeps original return target',
    );
    await key('alt+Left');
    await wait(
      () => router.routeInformationProvider.value.uri.path == '/',
      'return to Welcome from shortcut Settings',
    );

    Future<void> edit(String id) async {
      await openShortcutSettings();
      await wait(
        () => widgets<KeyboardShortcutsSettings>().isNotEmpty,
        'shortcut editor',
      );
      await browseShortcut(id);
      await wait(
        () => widgets<BusyMarkActionRow>().any(
          (b) => b.key == const ValueKey('record-shortcut'),
        ),
        'record button',
      );
    }

    Future<void> assign(String id, String combination) async {
      await edit(id);
      widgets<BusyMarkActionRow>()
          .singleWhere((b) => b.key == const ValueKey('record-shortcut'))
          .onTap!();
      final before = ref.read(workspaceControllerProvider).activeText;
      await key(combination, verifySearch: false);
      check(
        !BusyMarkShortcutCapture.suppressing,
        'capture $combination releases native dispatch after key up',
      );
      check(
        ref.read(workspaceControllerProvider).activeText == before,
        'capture $combination does not execute',
      );
      await wait(
        () => widgets<ElevatedButton>().any(
          (b) =>
              b.key == const ValueKey('assign-shortcut') && b.onPressed != null,
        ),
        'candidate captured',
      );
      widgets<ElevatedButton>()
          .singleWhere((b) => b.key == const ValueKey('assign-shortcut'))
          .onPressed!();
      await wait(() => widgets<Dialog>().isEmpty, 'assignment saved');
      await key('alt+Left');
      await wait(
        () => router.routeInformationProvider.value.uri.path == '/workspace',
        'return to keymap document',
      );
    }

    // Qualify a previously unbound typed Writerside operation through real keys.
    await workspace.openPath('${widget.output.path}/writerside');
    await workspace.openActiveFile(
      '${widget.output.path}/writerside/topics/outside-search.topic',
    );
    router.go('/workspace');
    await key('ctrl+shift+1', verifySearch: false);
    await assign('source.declaration', 'ctrl+alt+y');
    await assign('writerside.uiControl', 'ctrl+alt+y');
    check(
      ref
                  .read(busyMarkCommandRegistryProvider)['source.declaration']!
                  .shortcut
                  ?.label ==
              'Ctrl+Alt+Y' &&
          ref
                  .read(
                    busyMarkCommandRegistryProvider,
                  )['writerside.uiControl']!
                  .shortcut
                  ?.label ==
              'Ctrl+Alt+Y',
      'separate Source and Editor receivers keep both assignments',
    );
    await wait(
      () => widgets<TextField>().any(
        (f) =>
            f.controller is BusyMarkWysiwygTextController &&
            f.controller!.text.contains('semantic selection'),
      ),
      'Writerside shortcut target',
    );
    final semantic = widgets<TextField>().firstWhere(
      (f) =>
          f.controller is BusyMarkWysiwygTextController &&
          f.controller!.text.contains('semantic selection'),
    );
    semantic.focusNode!.requestFocus();
    final offset = semantic.controller!.text.indexOf('selection');
    semantic.controller!.selection = TextSelection(
      baseOffset: offset,
      extentOffset: offset + 'selection'.length,
    );
    await WidgetsBinding.instance.endOfFrame;
    final beforeSemantic = ref.read(workspaceControllerProvider).activeText;
    await key('ctrl+alt+y', verifySearch: false);
    await wait(
      () => ref
          .read(workspaceControllerProvider)
          .activeText
          .contains('<control>selection</control>'),
      'assigned Writerside Control',
    );
    await key('ctrl+z');
    await wait(
      () => ref.read(workspaceControllerProvider).activeText == beforeSemantic,
      'assigned Writerside Undo',
    );
    await key('ctrl+shift+z');
    await wait(
      () => ref
          .read(workspaceControllerProvider)
          .activeText
          .contains('<control>selection</control>'),
      'assigned Writerside Redo',
    );
    await workspace.saveActive();
    await screenshot('keymap-writerside-command');

    final file = File('${widget.output.path}/keymap-document.md');
    await file.writeAsString('Binding target\n');
    await workspace.openPath(file.path);
    router.go('/workspace');
    await wait(
      () =>
          ref.read(workspaceControllerProvider).activeBuffer?.filePath ==
          file.path,
      'keymap document',
    );

    for (final mode in [
      DocumentViewModePreference.source,
      DocumentViewModePreference.split,
    ]) {
      await ref
          .read(busyMarkCommandRegistryProvider)
          .execute(
            mode == DocumentViewModePreference.source
                ? BusyMarkCommandIds.viewSource
                : BusyMarkCommandIds.viewSplit,
          );
      const original =
          '## Fold\nfirst hidden\nsecond hidden\n\n## Next\nbefore target after\n';
      workspace.updateActiveText(original);
      await workspace.saveActive();
      await assign('text.selectAll', 'F8');
      await wait(
        () => widgets<BusyMarkSourceEditor>().isNotEmpty,
        '$mode Source field',
      );
      BusyMarkSourceEditingController source() => widgets<TextField>()
          .map((f) => f.controller)
          .whereType<BusyMarkSourceEditingController>()
          .single;
      void focusSource() => widgets<TextField>()
          .singleWhere((f) => f.controller is BusyMarkSourceEditingController)
          .focusNode!
          .requestFocus();
      widgets<IconButton>()
          .firstWhere((b) => b.tooltip == 'Collapse section')
          .onPressed!();
      await wait(
        () => source().document.hiddenRanges.ranges.isNotEmpty,
        '$mode folded content',
      );
      focusSource();
      await key('F8', verifySearch: false);
      check(
        source().fullSelection ==
            const TextSelection(baseOffset: 0, extentOffset: original.length),
        '$mode F8 selects entire folded document',
      );
      await edit('text.selectAll');
      widgets<BusyMarkActionRow>()
          .singleWhere((b) => b.key == const ValueKey('remove-shortcut'))
          .onTap!();
      await wait(() => widgets<Dialog>().isEmpty, '$mode unassignment saved');
      await key('alt+Left');
      focusSource();
      source().fullSelection = const TextSelection.collapsed(offset: 0);
      await key('F8', verifySearch: false);
      await key('ctrl+a', verifySearch: false);
      check(
        source().fullSelection == const TextSelection.collapsed(offset: 0),
        '$mode unassigned Select All has no hidden default',
      );
      await edit('text.selectAll');
      widgets<BusyMarkActionRow>()
          .singleWhere(
            (b) => b.key == const ValueKey('restore-shortcut-default'),
          )
          .onTap!();
      await wait(() => widgets<Dialog>().isEmpty, '$mode reset saved');
      await key('alt+Left');
      focusSource();
      await key('ctrl+a', verifySearch: false);
      check(
        source().fullSelection ==
            const TextSelection(baseOffset: 0, extentOffset: original.length),
        '$mode reset Ctrl+A selects complete document',
      );
      widgets<IconButton>()
          .firstWhere((b) => b.tooltip == 'Expand section')
          .onPressed!();
      await assign('editor.bold', 'alt+enter');
      focusSource();
      source().fullSelection = TextSelection(
        baseOffset: original.indexOf('target'),
        extentOffset: original.indexOf('target') + 6,
      );
      await key('alt+enter', verifySearch: false);
      final modified = original.replaceFirst('target', '**target**');
      await wait(
        () => source().fullText == modified,
        '$mode Alt+Enter exact Bold markup',
      );
      await key('ctrl+z');
      check(source().fullText == original, '$mode Alt+Enter one Undo');
      await key('ctrl+shift+z');
      check(source().fullText == modified, '$mode Alt+Enter Redo');
      source().fullSelection = TextSelection.collapsed(offset: modified.length);
      await key('enter');
      check(source().fullText == '$modified\n', '$mode plain Enter');
      await key('ctrl+z');
      check(source().fullText == modified, '$mode Enter separate Undo');
      check(
        await workspace.saveActive() && await file.readAsString() == modified,
        '$mode Alt+Enter saved source',
      );
      check(
        await workspace.closeDocumentBuffer(
          ref.read(workspaceControllerProvider).activeBufferId!,
        ),
        '$mode close modified document',
      );
      await workspace.openPath(file.path);
      await wait(
        () => ref.read(workspaceControllerProvider).activeText == modified,
        '$mode Alt+Enter save/reopen',
      );
    }
    workspace.updateActiveText('Binding target\n');
    await workspace.saveActive();

    await assign('editor.bold', 'ctrl+alt+b');
    for (final mode in [
      DocumentViewModePreference.editor,
      DocumentViewModePreference.source,
    ]) {
      await key(
        mode == DocumentViewModePreference.source
            ? 'ctrl+shift+2'
            : 'ctrl+shift+1',
        verifySearch: false,
      );
      await wait(
        () => widgets<TextField>().any(
          (f) => mode == DocumentViewModePreference.source
              ? f.controller is BusyMarkSourceEditingController
              : f.controller is BusyMarkWysiwygTextController,
        ),
        '$mode keymap field',
      );
      final field = widgets<TextField>().firstWhere(
        (f) => mode == DocumentViewModePreference.source
            ? f.controller is BusyMarkSourceEditingController
            : f.controller is BusyMarkWysiwygTextController,
      );
      field.focusNode!.requestFocus();
      field.controller!.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 7,
      );
      await WidgetsBinding.instance.endOfFrame;
      if (mode == DocumentViewModePreference.editor) {
        check(
          widgets<Tooltip>().any((t) => t.message == 'Bold (Ctrl+Alt+B)'),
          'toolbar displays the reassigned formatting shortcut',
        );
      }
      await key('ctrl+b', verifySearch: false);
      check(
        !ref.read(workspaceControllerProvider).activeText.contains('**'),
        '$mode old formatting binding removed',
      );
      await key('ctrl+alt+b', verifySearch: false);
      await wait(
        () => ref
            .read(workspaceControllerProvider)
            .activeText
            .contains('**Binding**'),
        '$mode reassigned formatting',
      );
      await key('ctrl+z');
      await wait(
        () => !ref.read(workspaceControllerProvider).activeText.contains('**'),
        '$mode reassigned formatting Undo',
      );
      await key('ctrl+shift+z');
      await wait(
        () => ref
            .read(workspaceControllerProvider)
            .activeText
            .contains('**Binding**'),
        '$mode reassigned formatting Redo',
      );
      await workspace.saveActive();
      check(
        (await file.readAsString()).contains('**Binding**'),
        '$mode saved formatting',
      );
      await key('ctrl+z');
      await wait(
        () => !ref.read(workspaceControllerProvider).activeText.contains('**'),
        '$mode reset text',
      );
      await workspace.saveActive();
    }
    final savedField = widgets<TextField>().singleWhere(
      (f) => f.controller is BusyMarkSourceEditingController,
    );
    savedField.focusNode!.requestFocus();
    savedField.controller!.selection = const TextSelection(
      baseOffset: 0,
      extentOffset: 7,
    );
    await WidgetsBinding.instance.endOfFrame;
    await key('ctrl+alt+b', verifySearch: false);
    await wait(
      () =>
          ref.read(workspaceControllerProvider).activeText ==
          '**Binding** target\n',
      'formatted source before reopening',
    );
    check(
      await workspace.saveActive(),
      'save reassigned formatting for reopening',
    );
    check(
      await workspace.closeDocumentBuffer(
        ref.read(workspaceControllerProvider).activeBufferId!,
      ),
      'close saved formatting document',
    );
    await workspace.openPath(file.path);
    check(
      ref.read(workspaceControllerProvider).activeText ==
          '**Binding** target\n',
      'reopen retains the reassigned formatting source',
    );
    workspace.updateActiveText('Binding target\n');
    await workspace.saveActive();
    await key('ctrl+shift+2', verifySearch: false);
    final layout = await Process.run('setxkbmap', [
      '-display',
      Platform.environment['DISPLAY']!,
      '-layout',
      'fr',
    ]);
    check(layout.exitCode == 0, 'isolated French keyboard layout');
    try {
      PhysicalKeyboardKey? capturedPhysical;
      bool observeFrenchKey(KeyEvent event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.keyA) {
          capturedPhysical = event.physicalKey;
        }
        return false;
      }

      HardwareKeyboard.instance.addHandler(observeFrenchKey);
      try {
        await assign('editor.bold', 'ctrl+shift+a');
      } finally {
        HardwareKeyboard.instance.removeHandler(observeFrenchKey);
      }
      final binding = ref
          .read(appSettingsControllerProvider)
          .shortcutOverrides['editor.bold']!;
      check(
        binding.key == LogicalKeyboardKey.keyA &&
            binding.control &&
            binding.shift &&
            capturedPhysical == PhysicalKeyboardKey.keyQ,
        'capture follows French logical A on physical Q '
        '(${binding.label}, physical ${capturedPhysical?.usbHidUsage})',
      );
      final source = widgets<TextField>().singleWhere(
        (f) => f.controller is BusyMarkSourceEditingController,
      );
      source.focusNode!.requestFocus();
      source.controller!.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 7,
      );
      await WidgetsBinding.instance.endOfFrame;
      await key('ctrl+shift+a', verifySearch: false);
      await wait(
        () => ref
            .read(workspaceControllerProvider)
            .activeText
            .contains('**Binding**'),
        'French logical-key formatting',
      );
      await key('ctrl+z');
      await wait(
        () => !ref.read(workspaceControllerProvider).activeText.contains('**'),
        'French logical-key Undo',
      );
      await workspace.saveActive();
      final input = source.controller! as BusyMarkSourceEditingController;
      source.focusNode!.requestFocus();
      final sourceBeforeAltGr = input.fullText;
      await key('altgr+e', verifySearch: false);
      await wait(
        () => input.fullText.contains('€'),
        'AltGr stays in the editor',
      );
      await key('ctrl+z');
      check(
        input.fullText == sourceBeforeAltGr,
        'AltGr has ordinary source Undo',
      );
      await screenshot('keymap-french-input');
      measurements['nonUsKeymap'] =
          'French layout: logical Ctrl+Shift+A captured and executed on physical Q';
    } finally {
      final restored = await Process.run('setxkbmap', [
        '-display',
        Platform.environment['DISPLAY']!,
        '-layout',
        'us',
      ]);
      check(restored.exitCode == 0, 'restore isolated keyboard layout');
    }
    await edit('file.save');
    widgets<BusyMarkActionRow>()
        .singleWhere((r) => r.key == const ValueKey('record-shortcut'))
        .onTap!();
    await key('F8', verifySearch: false);
    final settingsStore = ref.read(localSettingsStoreProvider) as _Settings;
    final persistedBeforeFailure = jsonEncode(settingsStore.value);
    settingsStore.failSaves = true;
    widgets<ElevatedButton>()
        .singleWhere((b) => b.key == const ValueKey('assign-shortcut'))
        .onPressed!();
    await wait(
      () => widgets<Text>().any(
        (t) => t.key == const ValueKey('shortcut-feedback'),
      ),
      'visible settings persistence failure',
    );
    check(
      jsonEncode(settingsStore.value) == persistedBeforeFailure &&
          widgets<Dialog>().isNotEmpty,
      'failed save preserves persisted settings and dialog',
    );
    await screenshot('shortcut-persistence-failure');
    settingsStore.failSaves = false;
    widgets<ElevatedButton>()
        .singleWhere((b) => b.key == const ValueKey('assign-shortcut'))
        .onPressed!();
    await wait(() => widgets<Dialog>().isEmpty, 'settings persistence retry');
    check(
      ref.read(busyMarkCommandRegistryProvider)['file.save']!.shortcut!.label ==
          'F8',
      'retry keeps current assignment',
    );
    await key('alt+Left');

    await edit('view.source');
    widgets<BusyMarkActionRow>()
        .singleWhere((b) => b.key == const ValueKey('remove-shortcut'))
        .onTap!();
    await wait(() => widgets<Dialog>().isEmpty, 'view unassignment saved');
    await key('alt+Left');
    await wait(
      () => router.routeInformationProvider.value.uri.path == '/workspace',
      'return after view unassignment',
    );
    await key('ctrl+shift+1', verifySearch: false);
    await wait(
      () =>
          widgets<TextField>().any(
            (f) => f.controller is BusyMarkWysiwygTextController,
          ) &&
          widgets<BusyMarkSourceEditor>().isEmpty,
      'Editor after view unassignment',
    );
    final beforeUnassignedView = ref
        .read(workspaceControllerProvider)
        .activeText;
    await key('ctrl+shift+2', verifySearch: false);
    check(
      widgets<BusyMarkSourceEditor>().isEmpty &&
          ref.read(workspaceControllerProvider).activeText ==
              beforeUnassignedView,
      'old unassigned view key cannot switch modes',
    );
    // The shared Flutter page frame publishes this configuration even when
    // the legacy native header service is unavailable on the current runner.
    final labels =
        widgets<HeaderBarConfigurationPublisher>().single.configuration.labels;
    check(
      labels.sourceShortcut.isEmpty && labels.sourceGtkAccelerator.isEmpty,
      'mounted header removes unassigned view metadata',
    );
    await assign('search.find', 'F12');
    await key('ctrl+f', verifySearch: false);
    check(!search.active, 'old search shortcut removed');
    final request = search.focusRequest;
    await key('F12', verifySearch: false);
    final documentOption = widgets<BusyMarkPopupSelector<SearchCategory>>()
        .single
        .options
        .singleWhere((o) => o.value == SearchCategory.file);
    check(
      documentOption.shortcut == 'F12' &&
          documentOption.gtkAccelerator == 'F12',
      'custom search selector metadata',
    );
    check(
      search.active &&
          search.category == SearchCategory.file &&
          search.focusRequest == request + 1,
      'custom document search executes once',
    );
    await query('Binding');
    check(
      search.documentMatchCount == 1,
      'custom search retains document scope',
    );
    await key('ctrl+shift+f');
    check(
      search.category == SearchCategory.workspace,
      'workspace search remains separate',
    );
    await key('ctrl+shift+p');
    await query('Keyboard Shortcuts');
    await key('enter');
    await wait(
      () => widgets<KeyboardShortcutsSettings>().isNotEmpty,
      'shortcut Settings from Actions',
    );
    await screenshot('keymap-custom-settings');
    await key('alt+Left');
    await openShortcutSettings();
    await wait(
      () => widgets<FilledButton>().any(
        (b) => b.key == const ValueKey('reset-all-shortcuts'),
      ),
      'Reset All button',
    );
    widgets<FilledButton>()
        .singleWhere((b) => b.key == const ValueKey('reset-all-shortcuts'))
        .onPressed!();
    await wait(() => widgets<Dialog>().isNotEmpty, 'Reset All confirmation');
    widgets<ElevatedButton>()
        .singleWhere((b) => b.onPressed != null)
        .onPressed!();
    await wait(
      () => ref.read(appSettingsControllerProvider).shortcutOverrides.isEmpty,
      'Reset All saved',
    );
    await key('alt+Left');
    await key('ctrl+f');
    check(
      search.category == SearchCategory.file,
      'Reset All restores default document binding',
    );
    await key('escape');
    measurements['configurableKeymapNativeWorkflows'] =
        'Welcome, Settings, Actions, Editor, Source, Undo/Redo, save, custom search, reset defaults';
  }

  Future<void> recentPresentationJourney() async {
    await windowManager.setSize(const Size(1100, 850));
    await wait(
      () =>
          View.of(context).physicalSize.width /
              View.of(context).devicePixelRatio >=
          1000,
      'wide Welcome Recent presentation',
    );
    final router = ref.read(appRouterProvider);
    final files = <File>[];
    for (final parent in [
      'short',
      'a-long-owner-name/nested/another-long-folder/final-parent',
    ]) {
      final file = File('${widget.output.path}/recent/$parent/Same.md');
      await file.parent.create(recursive: true);
      await file.writeAsString('Recent exact resource: $parent\n');
      await workspace.openPath(file.path);
      files.add(file);
    }
    // Keep a genuine project-qualified topic in the mixed chronological list.
    await workspace.openPath('${widget.output.path}/writerside');
    await workspace.openActiveFile(
      '${widget.output.path}/writerside/topics/outside-search.topic',
    );
    check(
      await workspace.openNextcloudWorkspace(
        '123e4567-e89b-42d3-a456-426614174000',
      ),
      'mixed Recent Notes owner',
    );
    check(
      await workspace.openNextcloudNote('223e4567-e89b-42d3-a456-426614174000'),
      'mixed Recent explicit note opening',
    );
    router.go('/');
    await wait(
      () => router.routeInformationProvider.value.uri.path == '/',
      'Welcome mixed Recent',
    );
    await wait(
      () => widgets<BusyMarkSidebarRecordRow>().isNotEmpty,
      'Welcome Recent rows mounted',
    );
    final before = ref.read(appSettingsControllerProvider).recentWorkspaces;
    check(
      before.any((r) => r.isDocument && r.accountId != null),
      'mixed Recent retains account-qualified note',
    );
    check(
      before.any(
        (r) => r.isDocument && r.ownerRoot != null && r.path.endsWith('.topic'),
      ),
      'mixed Recent retains project-qualified topic',
    );
    for (final scale in [1.0, 1.6]) {
      setState(() => _textScale = scale);
      await WidgetsBinding.instance.endOfFrame;
      final rows = widgets<BusyMarkSidebarRecordRow>();
      check(
        rows.isNotEmpty &&
            rows.every(
              (r) => r.content == null && r.title != null && r.subtitle != null,
            ),
        'Welcome standard Recent identity rows $scale',
      );
      final heights = rows.map((r) => boundsForKey(r.key!).height).toList();
      check(
        heights.every((h) => (h - heights.first).abs() < .1),
        'Welcome uniform mixed Recent heights $scale',
      );
      check(
        rows.every(
          (r) => r.tooltip != null && r.semanticsLabel!.contains(r.tooltip!),
        ),
        'Welcome complete accessible locations $scale',
      );
      await screenshot('welcome-mixed-recent-$scale');
    }
    setState(() => _textScale = 1);
    await key('ctrl+shift+r');
    await query('');
    check(
      search.waitingForInput && search.results.isEmpty,
      'Recent search waits independently of Welcome browsing',
    );
    await query('Same.md');
    check(
      search.results.whereType<RecentSearchResult>().length == 2,
      'Recent duplicate filenames retain separate identities',
    );
    // Welcome retains its ordinary list behind the search presentation.
    // Inspect just these two resource identities, rather than counting hidden
    // browsing rows in the framework's retained IndexedStack children.
    final expectedKeys = {for (final r in search.results) ValueKey(r.identity)};
    final records = widgets<BusyMarkSidebarRecordRow>().where(
      (r) => expectedKeys.contains(r.key),
    );
    check(
      records.map((r) => r.subtitle).toSet().length == 2,
      'Recent duplicate filename locations distinguish owners',
    );
    await query('');
    await key('ctrl+shift+p');
    await key('ctrl+shift+r');
    check(
      search.waitingForInput && search.results.isEmpty,
      'Recent stays empty after clear and category change',
    );
    await key('escape');
    check(
      jsonEncode(
            ref
                .read(appSettingsControllerProvider)
                .recentWorkspaces
                .map((r) => r.toJson())
                .toList(),
          ) ==
          jsonEncode(before.map((r) => r.toJson()).toList()),
      'search leaves Welcome Recent collection unchanged',
    );
    for (final file in files) {
      await key('ctrl+shift+r');
      await query(file.path);
      check(
        search.results.single is RecentSearchResult,
        'exact long-path Recent resource',
      );
      await key('enter');
      await wait(
        () =>
            ref.read(workspaceControllerProvider).activeBuffer?.filePath ==
            file.path,
        'Recent exact resource activation',
      );
      check(
        ref.read(workspaceControllerProvider).activeText ==
            await file.readAsString(),
        'Recent exact resource contents',
      );
      router.go('/');
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  Future<void> run() async {
    try {
      await Future<void>.delayed(const Duration(seconds: 2));
      check(
        ref.read(appRouterProvider).routeInformationProvider.value.uri.path ==
            '/',
        'Welcome visible',
      );
      await key('ctrl+shift+r');
      await query('');
      check(search.category == SearchCategory.recent, 'Welcome Recent sidebar');
      bool categoryHasFocus() {
        var found = false;
        FocusManager.instance.primaryFocus?.context?.visitAncestorElements((
          element,
        ) {
          if (element.widget.key == const ValueKey('search-category')) {
            found = true;
            return false;
          }
          return true;
        });
        return found;
      }

      for (var i = 0; i < 30 && !categoryHasFocus(); i++) {
        await key('tab');
      }
      check(categoryHasFocus(), 'keyboard traversal reaches category selector');
      await key('enter');
      await wait(
        () =>
            widgets<Semantics>().any(
              (s) => s.properties.label == 'Search category',
            ) &&
            widgets<Semantics>().any((s) => s.properties.expanded == true),
        'native category popup opened by keyboard',
      );
      await key('escape');
      check(
        search.active,
        'category popup consumes Escape before closing search',
      );
      await screenshot('welcome-recent');
      await key('escape');
      final folder = await Directory(
        '${widget.output.path}/documents',
      ).create();
      final file = File('${folder.path}/a.md');
      await file.writeAsString(
        '# Title\n\nFormatting target\n\nscope needle alpha\n',
      );
      await File(
        '${folder.path}/b.md',
      ).writeAsString('# Other\n\nscope needle beta\n');
      if (widget.large) {
        for (var i = 0; i < 200; i++) {
          await File('${folder.path}/corpus-$i.md').writeAsString(
            '# Corpus $i\n\n${List.generate(40, (line) => 'Paragraph $line: representative local content café 中文 '
                'corpus-token${i % 97} alpha beta gamma delta.').join('\n\n')}',
          );
        }
      }
      await workspace.openFolder(folder.path);
      await workspace.openActiveFile(file.path);
      ref.read(appRouterProvider).go('/workspace');
      await wait(
        () => widgets<TextField>().any(
          (f) =>
              f.controller is BusyMarkWysiwygTextController &&
              f.controller!.text == 'Formatting target',
        ),
        'Editor ready',
      );
      final field = widgets<TextField>().singleWhere(
        (f) =>
            f.controller is BusyMarkWysiwygTextController &&
            f.controller!.text == 'Formatting target',
      );
      field.focusNode!.requestFocus();
      field.controller!.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 10,
      );
      await WidgetsBinding.instance.endOfFrame;
      await action('Bold');
      await wait(
        () => ref
            .read(workspaceControllerProvider)
            .activeText
            .contains('**Formatting**'),
        'Editor Bold uses captured text',
      );
      await key('ctrl+z');
      await wait(
        () => !ref
            .read(workspaceControllerProvider)
            .activeText
            .contains('**Formatting**'),
        'Editor Undo',
      );
      await key('ctrl+shift+z');
      await wait(
        () => ref
            .read(workspaceControllerProvider)
            .activeText
            .contains('**Formatting**'),
        'Editor Redo',
      );
      check(await workspace.saveActive(), 'save formatting');
      check(
        (await file.readAsString()).contains('**Formatting**'),
        'formatting persisted',
      );
      // Settle the preceding save's inventory metadata before measuring clean
      // tab navigation. A later genuine metadata refresh is a valid reason to
      // invalidate workspace results, independently of a tab being closed.
      check(
        await workspace.refreshWorkspaceFromDiskPreservingOpenTabs(),
        'refresh saved file metadata before workspace navigation',
      );
      await key('ctrl+f');
      await query('scope needle');
      check(
        search.category == SearchCategory.file && search.results.length == 1,
        'Ctrl+F document-only',
      );
      await key('ctrl+shift+f');
      await query('scope needle');
      check(search.results.length == 2, 'Ctrl+Shift+F workspace');
      final beforeArrowing = ref.read(workspaceControllerProvider);
      await key('down');
      check(
        search.selected == 1 &&
            ref.read(workspaceControllerProvider).activeBufferId ==
                beforeArrowing.activeBufferId &&
            ref.read(workspaceControllerProvider).activeText ==
                beforeArrowing.activeText,
        'arrow selection does not open or edit a document',
      );
      final queryFocus = FocusManager.instance.primaryFocus;
      await key('tab');
      check(
        FocusManager.instance.primaryFocus != queryFocus,
        'Tab leaves the query',
      );
      await key('shift+tab');
      check(
        FocusManager.instance.primaryFocus == queryFocus,
        'Shift+Tab returns to the query',
      );
      await key('enter');
      await wait(
        () =>
            ref.read(workspaceControllerProvider).activeBuffer?.filePath ==
            '${folder.path}/b.md',
        'Enter activates the selected text occurrence',
      );
      final tracedFiles =
          ref.read(workspaceServiceProvider) as _TraceWorkspaceService;
      final readsAfterActivation = tracedFiles.reads;
      final searchGeneration = search.generation;
      await Future<void>.delayed(const Duration(milliseconds: 180));
      check(
        tracedFiles.reads == readsAfterActivation &&
            search.generation == searchGeneration,
        'clean document activation and outline refresh do not rescan workspace',
      );
      final retainedResult =
          search.results[search.selected] as TextSearchResult;
      final closedBuffer = ref.read(workspaceControllerProvider).activeBuffer!;
      check(
        await workspace.closeDocumentBuffer(closedBuffer.id),
        'close clean search destination tab',
      );
      await Future<void>.delayed(const Duration(milliseconds: 180));
      check(
        search.generation == searchGeneration &&
            identical(search.results[search.selected], retainedResult),
        'closing clean tab retains workspace result without rescanning '
        '(generation $searchGeneration → ${search.generation}, '
        'selected ${search.selected}, retained '
        '${identical(search.results.elementAtOrNull(search.selected), retainedResult)})',
      );
      widgets<TextField>()
          .singleWhere(
            (f) => f.decoration?.hintText?.startsWith('Search ') == true,
          )
          .focusNode!
          .requestFocus();
      await key('enter');
      await wait(
        () =>
            ref.read(workspaceControllerProvider).activeBuffer?.filePath ==
            closedBuffer.filePath,
        'retained workspace result reopens closed clean file',
      );
      await wait(
        () => widgets<TextField>()
            .map((f) => f.controller)
            .whereType<BusyMarkWysiwygTextController>()
            .any(
              (c) =>
                  c.text.contains('scope needle beta') &&
                  c.selection.isValid &&
                  c.selection.textInside(c.text) == 'scope needle',
            ),
        'reopened workspace result reveals exact occurrence',
      );
      check(
        search.generation == searchGeneration,
        'reopening does not rescan workspace',
      );
      final samples = <Map<String, Object?>>[];
      for (var i = 0; i < 10; i++) {
        samples.add(
          await measuredQuery(
            widget.large
                ? (i.isEven ? 'corpus-token42' : 'corpus-token17')
                : (i.isEven ? 'needle' : 'scope'),
          ),
        );
      }
      measurements['localSearchApplicationTiming'] = samples;
      measurements['localDocumentCount'] = widget.large ? 202 : 2;
      if (widget.large) await measuredCancellation('local');
      await key('ctrl+shift+f');
      await query('scope needle');
      await writeMeasurements();
      await screenshot('local-search-light');
      await rapidChanges('local', 'scope needle');
      await key('ctrl+shift+d');
      await query('beta');
      check(
        search.results.isEmpty,
        'Documents excludes body-only local matches',
      );
      await query('b.md');
      check(
        search.results.single is DocumentSearchResult,
        'Documents path ranking',
      );
      await key('enter');
      await wait(
        () =>
            ref
                .read(workspaceControllerProvider)
                .activeBuffer
                ?.filePath
                ?.endsWith('b.md') ==
            true,
        'Documents Enter opens file',
      );
      await workspace.openActiveFile(file.path);
      await key('ctrl+shift+2');
      await wait(
        () => widgets<BusyMarkSourceEditor>().isNotEmpty,
        'Source mode',
      );
      final sourceField = widgets<TextField>().singleWhere(
        (f) => f.controller is BusyMarkSourceEditingController,
      );
      sourceField.focusNode!.requestFocus();
      final source = ref.read(workspaceControllerProvider).activeText;
      final offset = source.indexOf('target');
      sourceField.controller!.selection = TextSelection(
        baseOffset: offset,
        extentOffset: offset + 6,
      );
      await action('Italic');
      await wait(
        () => ref
            .read(workspaceControllerProvider)
            .activeText
            .contains('*target*'),
        'Source action uses captured selection',
      );
      check(await workspace.saveActive(), 'Source formatting saved');
      await key('ctrl+f');
      await query('target');
      check(
        search.category == SearchCategory.file &&
            search.results.every((r) => r is TextSearchResult),
        'Source Ctrl+F uses current-buffer occurrences',
      );
      await key('escape');
      await findReplaceNavigation();
      await literalMatcherJourney();
      workspace.updateActiveText(
        '${ref.read(workspaceControllerProvider).activeText}\n## Unsaved target heading\n',
      );
      await key('ctrl+3');
      check(
        !search.active && widgets<SearchHeaderField>().isEmpty,
        'Ctrl+3 opens ordinary Outline without a query',
      );
      await key('ctrl+f');
      widgets<BusyMarkPopupSelector<SearchCategory>>().single.onSelected(
        SearchCategory.outline,
      );
      await query('Unsaved target');
      await wait(
        () => widgets<Text>().any((t) => t.data == 'Unsaved target heading'),
        'unsaved Outline heading',
      );
      await key('enter');
      await key('escape');
      check(await workspace.saveActive(), 'save outline edit');
      await historyJourney();
      ref.read(appRouterProvider).go('/');
      await WidgetsBinding.instance.endOfFrame;
      await key('ctrl+shift+r');
      await query('a.md');
      await key('enter');
      await wait(
        () =>
            ref
                .read(appRouterProvider)
                .routeInformationProvider
                .value
                .uri
                .path ==
            '/workspace',
        'Recent local reopen',
      );
      check(
        ref.read(workspaceControllerProvider).activeBuffer?.filePath ==
            file.path,
        'Recent document identity',
      );
      ref.read(appRouterProvider).go('/');
      await WidgetsBinding.instance.endOfFrame;
      final browse = widgets<ListTile>()
          .where(
            (t) => t.title is Text && (t.title as Text).data == 'Browse Notes',
          )
          .firstOrNull;
      // Welcome uses BusyMark action rows, so invoke the registered command.
      await ref.read(busyMarkCommandRegistryProvider).execute('notes.browse');
      await wait(
        () => ref.read(workspaceControllerProvider).workspace?.isRemote == true,
        'Browse Notes',
      );
      check(
        browse == null || browse.onTap != null,
        'Notes navigation available',
      );
      await workspace.openNextcloudNote('223e4567-e89b-42d3-a456-426614174000');
      await key('ctrl+f');
      await query('cached needle');
      check(
        search.category == SearchCategory.file &&
            search.results.single is TextSearchResult &&
            (search.results.single as TextSearchResult).match.bufferId ==
                ref.read(workspaceControllerProvider).activeBufferId,
        'Notes Ctrl+F searches only the active in-memory note',
      );
      await key('ctrl+shift+f');
      final noteSamples = <Map<String, Object?>>[];
      for (var i = 0; i < 10; i++) {
        noteSamples.add(
          await measuredQuery(
            widget.large
                ? (i.isEven ? 'corpus-token42' : 'category:"Area 7"')
                : (i.isEven ? 'cached needle' : 'category:Offline'),
          ),
        );
      }
      measurements['cachedNotesApplicationTiming'] = noteSamples;
      measurements['cachedNoteCount'] = widget.repository.notes
          .where((n) => n.accountId == '123e4567-e89b-42d3-a456-426614174000')
          .length;
      await writeMeasurements();
      await query('cached needle');
      check(
        search.results.whereType<NoteSearchResult>().isNotEmpty,
        'cached Notes occurrences',
      );
      await rapidChanges('notes', 'cached needle');
      changeQuery(widget.large ? 'corpus-token42' : 'cached needle');
      await Future<void>.delayed(const Duration(milliseconds: 140));
      check(
        await workspace.openNextcloudWorkspace(
          '423e4567-e89b-42d3-a456-426614174001',
        ),
        'switch account during Notes search',
      );
      await query('confidential');
      check(
        search.results.whereType<NoteSearchResult>().every(
          (r) => r.accountId == '423e4567-e89b-42d3-a456-426614174001',
        ),
        'Notes results remain in the new account',
      );
      await key('escape');
      final otherIds = widget.repository.notes
          .where((n) => n.accountId == '423e4567-e89b-42d3-a456-426614174001')
          .map((n) => n.localId)
          .toSet();
      final otherNotes = widget.repository.notes
          .where((n) => n.accountId == '423e4567-e89b-42d3-a456-426614174001')
          .length;
      await action('New note');
      await wait(
        () =>
            widget.repository.notes
                .where(
                  (n) => n.accountId == '423e4567-e89b-42d3-a456-426614174001',
                )
                .length ==
            otherNotes + 1,
        'Actions New Note retains the active account',
      );
      final createdOther = widget.repository.notes.singleWhere(
        (n) =>
            n.accountId == '423e4567-e89b-42d3-a456-426614174001' &&
            !otherIds.contains(n.localId),
      );
      await wait(
        () =>
            ref
                    .read(workspaceControllerProvider)
                    .activeBuffer
                    ?.remoteNote
                    ?.localId ==
                createdOther.localId &&
            !ref.read(welcomeNotesActionProvider.notifier).busy,
        'new note is open in its originating account',
      );
      check(
        ref
                .read(workspaceControllerProvider)
                .activeBuffer
                ?.remoteNote
                ?.accountId ==
            '423e4567-e89b-42d3-a456-426614174001',
        'created note belongs to the explicit active account',
      );
      check(
        await workspace.openNextcloudWorkspace(
          '123e4567-e89b-42d3-a456-426614174000',
        ),
        'return to original Notes account',
      );
      await key('ctrl+shift+f');
      await query('confidential');
      check(
        search.results.isEmpty,
        'previous account results cannot cross accounts',
      );
      await query('cached needle');
      await key('ctrl+shift+d');
      await query('needle');
      check(search.results.isEmpty, 'Documents excludes note-body matches');
      await key('escape');
      ref.read(appRouterProvider).go('/');
      await WidgetsBinding.instance.endOfFrame;
      final before = widget.repository.notes.length;
      await ref.read(busyMarkCommandRegistryProvider).execute('notes.create');
      await wait(
        () => widget.repository.notes.length == before + 1,
        'New Note exactly once',
      );
      check(
        ref
                .read(appSettingsControllerProvider)
                .recentWorkspaces
                .where(
                  (r) =>
                      r.localId ==
                      ref
                          .read(workspaceControllerProvider)
                          .activeBuffer
                          ?.remoteNote
                          ?.localId,
                )
                .length ==
            1,
        'offline note Recent identity',
      );
      check(await workspace.saveActive(), 'offline note durable');
      ref.read(appRouterProvider).go('/');
      await WidgetsBinding.instance.endOfFrame;
      await key('ctrl+shift+r');
      await query('Cached individual');
      await key('enter');
      await wait(
        () =>
            ref
                .read(appRouterProvider)
                .routeInformationProvider
                .value
                .uri
                .path ==
            '/workspace',
        'Recent individual note reopen',
      );
      check(
        ref
                .read(workspaceControllerProvider)
                .activeBuffer
                ?.remoteNote
                ?.localId ==
            '223e4567-e89b-42d3-a456-426614174000',
        'Recent exact account-qualified note',
      );
      final project = Directory('${widget.output.path}/writerside');
      await project.create();
      final copied = await Process.run('cp', [
        '-a',
        'test/fixtures/writerside/basic_project/.',
        project.path,
      ]);
      check(copied.exitCode == 0, 'disposable Writerside project');
      final hidden = File('${project.path}/topics/outside-search.topic');
      await hidden.writeAsString(
        '<topic id="outside-search" title="Outside Search Topic"><p>semantic selection</p><chapter id="outline-presentation" title="Outline presentation target"><p>Section text.</p></chapter></topic>',
      );
      await workspace.openFolder(project.path);
      await key('ctrl+shift+t');
      await query('Outside Search Topic');
      check(
        search.category == SearchCategory.topics &&
            search.results.single is TopicSearchResult,
        'topic outside selected TOC',
      );
      check(
        (search.results.single as TopicSearchResult).path == hidden.path,
        'actual topic identity',
      );
      await key('enter');
      await wait(
        () =>
            ref.read(workspaceControllerProvider).activeBuffer?.filePath ==
            hidden.path,
        'topic activation',
      );
      await key('ctrl+shift+1');
      await wait(
        () => widgets<TextField>().any(
          (f) =>
              f.controller is BusyMarkWysiwygTextController &&
              f.controller!.text == 'semantic selection',
        ),
        'XML Editor ready',
      );
      final semantic = widgets<TextField>().singleWhere(
        (f) =>
            f.controller is BusyMarkWysiwygTextController &&
            f.controller!.text == 'semantic selection',
      );
      semantic.focusNode!.requestFocus();
      semantic.controller!.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 8,
      );
      await WidgetsBinding.instance.endOfFrame;
      await action('UI Control');
      await wait(
        () => ref
            .read(workspaceControllerProvider)
            .activeText
            .contains('<control>semantic</control>'),
        'typed Writerside semantic action',
      );
      await key('ctrl+z');
      await wait(
        () => !ref
            .read(workspaceControllerProvider)
            .activeText
            .contains('<control>semantic</control>'),
        'semantic Undo',
      );
      await key('ctrl+shift+z');
      await wait(
        () => ref
            .read(workspaceControllerProvider)
            .activeText
            .contains('<control>semantic</control>'),
        'semantic Redo',
      );
      check(await workspace.saveActive(), 'semantic save');
      check(
        (await hidden.readAsString()).contains('<control>semantic</control>'),
        'semantic serialization persisted',
      );
      final savedId = ref.read(workspaceControllerProvider).activeBufferId!;
      check(await workspace.closeDocumentBuffer(savedId), 'close saved topic');
      check(
        await workspace.openActiveFile(hidden.path),
        'reopen saved topic with project context',
      );
      check(
        ref.read(workspaceControllerProvider).workspace?.writersideProject !=
            null,
        'project owner preserved',
      );
      // Add this previously orphaned source to the disposable publication only
      // after proving Topics can find it outside the TOC.
      final tree = File('${project.path}/user-guide.tree');
      await tree.writeAsString(
        (await tree.readAsString()).replaceFirst(
          '</instance-profile>',
          '<toc-element topic="outside-search.topic"/></instance-profile>',
        ),
      );
      await screenshot('writerside-semantic-action');
      await categoryShortcutsJourney();
      await presentationJourney('light');
      await openShortcutSettings();
      await wait(
        () => widgets<Text>().any((t) => t.data == 'Keyboard Shortcuts'),
        'Keyboard Shortcuts Settings page',
      );
      await screenshot('keyboard-shortcuts');
      ref.read(appRouterProvider).go('/workspace');
      await wait(
        () =>
            ref
                .read(appRouterProvider)
                .routeInformationProvider
                .value
                .uri
                .path ==
            '/workspace',
        'return from Keyboard Shortcuts Settings',
      );
      await ref
          .read(appSettingsControllerProvider.notifier)
          .setThemeModePreference(BusyMarkThemeModePreference.dark);
      await key('ctrl+shift+p');
      await query('Bold');
      await screenshot('search-dark');
      await presentationJourney('dark');
      await key('ctrl+shift+p');
      await query('Bold');
      await windowManager.setSize(const Size(600, 800));
      await wait(
        () =>
            View.of(context).physicalSize.width /
                View.of(context).devicePixelRatio <
            700,
        'narrow window size',
      );
      await screenshot('search-narrow');
      await presentationJourney('narrow');
      await key('ctrl+shift+p');
      await query('Bold');
      setState(() => _textScale = 1.6);
      await screenshot('search-scaled');
      await presentationJourney('scaled');
      await key('ctrl+shift+p');
      await query('Bold');
      await ref.read(appSettingsControllerProvider.notifier).setLocaleTag('ar');
      ref.read(searchSessionProvider.notifier).query('');
      await wait(() => !search.searching, 'RTL action results');
      await screenshot('search-rtl');
      await presentationJourney('rtl');
      await key('ctrl+shift+p');
      await query('');
      await ref.read(appSettingsControllerProvider.notifier).setLocaleTag('en');
      setState(() => _textScale = 1);
      await WidgetsBinding.instance.endOfFrame;
      await key('escape');
      await keymapJourney();
      await recentPresentationJourney();
      measurements['rssBeforeThirtyOpenCloseCycles'] = ProcessInfo.currentRss;
      measurements['fileDescriptorsBeforeCycles'] = await Directory(
        '/proc/self/fd',
      ).list().length;
      final cycles = Stopwatch()..start();
      for (var cycle = 0; cycle < 30; cycle++) {
        await key('ctrl+shift+p');
        await query(cycle.isEven ? 'Bold' : 'Italic');
        await key('escape');
      }
      measurements['thirtyOpenCloseCyclesMicroseconds'] =
          cycles.elapsedMicroseconds;
      await Future<void>.delayed(const Duration(seconds: 2));
      check(
        !search.active &&
            search.results.isEmpty &&
            ref.read(searchSessionProvider.notifier).commandTarget == null,
        'closed search releases results and command targets',
      );
      measurements['rssAfterThirtyOpenCloseCycles'] = ProcessInfo.currentRss;
      measurements['fileDescriptorsAfterCycles'] = await Directory(
        '/proc/self/fd',
      ).list().length;
      measurements['rssBytes'] = ProcessInfo.currentRss;
      measurements['maximumRssBytes'] = ProcessInfo.maxRss;
      stdout.writeln(jsonEncode(measurements));
      await File(
        '${widget.output.path}/measurements.json',
      ).writeAsString(jsonEncode(measurements));
      // The native runner can return success after SystemNavigator.pop even
      // when Dart's exitCode was set by an unexpected framework error.
      if (exitCode != 0) exit(exitCode);
      await workspace.discardRecoveryForShutdown();
      if (exitCode != 0) exit(exitCode);
      await SystemNavigator.pop();
    } catch (error, stack) {
      stderr.writeln('$error\n$stack');
      await screenshot('failure');
      exit(1);
    }
  }

  Future<void> writeMeasurements() => File(
    '${widget.output.path}/measurements.json',
  ).writeAsString(jsonEncode(measurements));
}
