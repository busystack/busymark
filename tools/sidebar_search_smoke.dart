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
import 'package:busymark/src/app/busymark_search_field.dart';
import 'package:busymark/src/app/startup_path.dart';
import 'package:busymark/src/editor/source/source_editor.dart';
import 'package:busymark/src/editor/source_highlighter.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_inline_controller.dart';
import 'package:busymark/src/local_history/local_history_controller.dart';
import 'package:busymark/src/local_history/local_history_store.dart';
import 'package:busymark/src/local_history/local_history_models.dart';
import 'package:busymark/src/workspace/text_format_metadata.dart';
import 'package:busymark/src/workspace/workspace_service.dart';
import 'package:busymark/src/search/search_sidebar.dart';
import 'package:busymark/src/app/command_registry.dart';
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
  Future<void> save(Map<String, Object?> json) async => value = json;
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
        throw StateError('Timed out: $description; ${search.error}');
      }
      await Future<void>.delayed(const Duration(milliseconds: 30));
    }
  }

  Future<void> key(String key) async {
    final focusRequest = search.focusRequest;
    await windowManager.focus();
    final result = await Process.run(
      'python3',
      ['tools/nextcloud_notes_native_key.py', key],
      environment: {'BUSYMARK_NATIVE_ACCEPTANCE': '1'},
    );
    check(result.exitCode == 0, 'native $key delivery');
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (const {
      'ctrl+f',
      'ctrl+shift+f',
      'ctrl+p',
      'ctrl+shift+t',
      'ctrl+alt+o',
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
    widgets<BusyMarkMenuButton<SearchCategory>>().single.onSelected(
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
    await key('ctrl+alt+o');
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
      SearchCategory.recent: '',
      SearchCategory.localHistory: 'unique-needle',
      SearchCategory.actions: '',
    };
    for (final entry in samples.entries) {
      controller.open(category: entry.key);
      await query('');
      final fileReads = files.reads, revisionReads = history.reads;
      final listsInitially =
          entry.key == SearchCategory.recent ||
          entry.key == SearchCategory.actions;
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

  Future<void> run() async {
    try {
      await Future<void>.delayed(const Duration(seconds: 2));
      check(
        ref.read(appRouterProvider).routeInformationProvider.value.uri.path ==
            '/',
        'Welcome visible',
      );
      await key('ctrl+alt+o');
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
        () => widgets<Semantics>().any(
          (s) =>
              s.properties.label == 'Search category' &&
              s.properties.expanded == true,
        ),
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
        'closing clean tab retains workspace result without rescanning',
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
      await key('ctrl+p');
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
      widgets<BusyMarkMenuButton<SearchCategory>>().single.onSelected(
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
      await key('ctrl+alt+o');
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
      await key('ctrl+p');
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
      await key('ctrl+alt+o');
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
      await presentationJourney('light');
      await key('ctrl+alt+k');
      await wait(
        () => widgets<Text>().any((t) => t.data == 'Keyboard Shortcuts'),
        'unchanged Keyboard Shortcuts modal',
      );
      await screenshot('keyboard-shortcuts');
      await key('escape');
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
