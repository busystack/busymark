// Production-shell Notes acceptance with an isolated offline fixture. No live
// credentials or user profile is opened. Evidence is written to PRIVATE_OUTPUT.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:busymark/src/app/app_router.dart';
import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/app/busymark_app.dart';
import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/app/busymark_dialogs.dart';
import 'package:busymark/src/nextcloud_notes/application/notes_navigation.dart';
import 'package:busymark/src/nextcloud_notes/application/notes_transfer_service.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/startup_path.dart';
import 'package:busymark/src/local_history/local_history_controller.dart';
import 'package:busymark/src/local_history/local_history_store.dart';
import 'package:busymark/src/nextcloud_notes/application/nextcloud_connection.dart';
import 'package:busymark/src/nextcloud_notes/application/notes_repository.dart';
import 'package:busymark/src/nextcloud_notes/domain/notes_models.dart';
import 'package:busymark/src/nextcloud_notes/presentation/notes_sidebar.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_store.dart';
import 'package:busymark/src/nextcloud_notes/presentation/notes_workspace_ui.dart';
import 'package:busymark/src/nextcloud_notes/application/notes_settings_controller.dart';
import 'package:busymark/src/search/search_session.dart';
import 'package:busymark/src/workspace/recovery_persistence.dart';
import 'package:busymark/src/workspace/session_persistence.dart';
import 'package:busymark/src/workspace/workspace_controller.dart';
import 'package:busymark/src/workspace/outline_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:yaru/yaru.dart';

String _noteId(int index) =>
    '223e4567-e89b-42d3-a456-${index.toString().padLeft(12, '0')}';

const _account = '123e4567-e89b-42d3-a456-426614174000';
Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (args.isEmpty) throw ArgumentError('PRIVATE_OUTPUT [--before]');
  final output = await Directory(args.first).create(recursive: true);
  await windowManager.ensureInitialized();
  await YaruWindow.ensureInitialized();
  await windowManager.setSize(const Size(1100, 760));
  final store = await NotesStore.open(path: '${output.path}/notes.sqlite3');
  await store.saveAccount(
    NextcloudAccount(
      id: _account,
      server: Uri.parse(
        'https://offline.example.invalid/long-nextcloud-installation',
      ),
      loginName: 'fixture-user-with-a-long-account-name',
      appVersion: '6.0.1',
    ),
  );
  await store.commit(
    notes: [
      for (
        var i = 0;
        i <
            (args.contains('--empty')
                ? 0
                : args.contains('--large')
                ? 5000
                : 120);
        i++
      )
        NextcloudNote(
          localId: _noteId(i),
          accountId: _account,
          serverId: i + 1,
          title: i == 0
              ? 'A long note title for reviewing the production 300-pixel sidebar'
              : 'Note ${i.toString().padLeft(4, '0')} · نص 中文',
          category: i % 3 == 0
              ? 'Projects/BusyMark/Interface'
              : i % 3 == 1
              ? 'Personal'
              : '',
          content:
              '# Retained fixture note $i\n\nDurable local content.\n${i == 0 ? '[Retained file](.attachments.1/report.pdf)' : ''}',
          readonly: i == 5,
          favorite: i % 4 == 0,
          revision: i >= 6 && i <= 12 ? 2 : 1,
          ackRevision: 1,
          syncState: switch (i) {
            2 => NoteSyncState.conflict,
            3 => NoteSyncState.deletedRemotely,
            6 => NoteSyncState.pending,
            7 => NoteSyncState.offline,
            8 => NoteSyncState.reconnectRequired,
            9 => NoteSyncState.locked,
            10 => NoteSyncState.storageFull,
            11 => NoteSyncState.throttled,
            12 => NoteSyncState.rejected,
            _ => NoteSyncState.synced,
          },
          remote: i == 2
              ? const NoteState(
                  id: 3,
                  etag: 'fixture-remote',
                  title: 'Remote candidate',
                  content: 'Remote text to compare',
                  category: '',
                  favorite: false,
                  modified: 1780000000,
                  readonly: false,
                )
              : null,
        ),
    ],
  );
  if (!args.contains('--empty')) {
    await store.saveAttachment(
      NotesAttachment(
        id: '323e4567-e89b-42d3-a456-426614174000',
        noteId: _noteId(0),
        filename: 'report.pdf',
        reference: '.attachments.1/report.pdf',
        remotePath: '.attachments.1/report.pdf',
        state: 'uploaded',
      ),
      Uint8List.fromList([1, 2, 3]),
    );
  }
  final repository = _FixtureRepository(store);
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
        localHistoryStoreProvider.overrideWithValue(MemoryLocalHistoryStore()),
        nextcloudNotesRepositoryProvider.overrideWith((_) async => repository),
      ],
      child: _Driver(
        output: output,
        before: args.contains('--before'),
        empty: args.contains('--empty'),
        states: args.contains('--states'),
        keyboardOnly: args.contains('--keyboard'),
        importOnly: args.contains('--import'),
      ),
    ),
  );
}

// Server responses are deterministic fixture state. The production repository,
// durability, identity and modal widgets remain in use for note operations.
class _FixtureRepository extends NotesRepository {
  _FixtureRepository(NotesStore store)
    : super(
        store: store,
        clientForAccount: (_) async => throw const NotesException(
          NotesFailureCode.network,
          'Fixture offline',
        ),
      );
  NotesException? fixtureError;
  @override
  NotesException? accountError(String accountId) =>
      fixtureError ?? super.accountError(accountId);
  NotesSettings settings = const NotesSettings(
    notesPath: 'Notes',
    fileSuffix: '.md',
  );
  @override
  Future<void> synchronize(
    String id, {
    bool allowWrites = true,
    bool refreshCapabilities = false,
    bool onlyFreshWrites = false,
  }) async {}
  @override
  Future<void> maintainCapabilities(String id, {bool force = false}) async {}
  @override
  Future<NotesSettings> reconcileSettings(String id) async => settings;
  @override
  Future<NotesSettings> changeSettings(
    String id,
    NotesSettings original,
    Map<String, String> patch,
  ) async => settings = NotesSettings(
    notesPath: (patch['notesPath'] ?? settings.notesPath).trim(),
    fileSuffix: (patch['fileSuffix'] ?? settings.fileSuffix).trim(),
  );
}

class _Settings implements LocalSettingsStore {
  Map<String, Object?> value = AppSettings.defaults()
      .copyWith(
        localeTag: 'en',
        automaticSpelling: false,
        autoSave: false,
        sidebarVisible: true,
        themeModePreference: BusyMarkThemeModePreference.light,
        reopenPreviousWorkspaceOnStartup: false,
        confirmCloseWithUnsavedChanges: false,
      )
      .toJson();
  @override
  Future<Map<String, Object?>> load() async => value;
  @override
  Future<void> save(Map<String, Object?> next) async {
    value = next;
  }
}

class _Driver extends ConsumerStatefulWidget {
  const _Driver({
    required this.output,
    required this.before,
    required this.empty,
    required this.states,
    this.keyboardOnly = false,
    this.importOnly = false,
  });
  final Directory output;
  final bool before;
  final bool empty, states;
  final bool keyboardOnly, importOnly;
  @override
  ConsumerState<_Driver> createState() => _DriverState();
}

class _DriverState extends ConsumerState<_Driver> {
  final boundary = GlobalKey();
  double scale = 1;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(run()));
  }

  @override
  Widget build(BuildContext context) => MediaQuery(
    data: MediaQueryData.fromView(
      View.of(context),
    ).copyWith(textScaler: TextScaler.linear(scale)),
    child: RepaintBoundary(key: boundary, child: const BusyMarkApp()),
  );
  List<T> widgets<T extends Widget>() {
    final result = <T>[];
    void visit(Element element) {
      if (element.widget is Offstage && (element.widget as Offstage).offstage) {
        return;
      }
      if (element.widget is T) result.add(element.widget as T);
      element.visitChildren(visit);
    }

    WidgetsBinding.instance.rootElement!.visitChildren(visit);
    return result;
  }

  Future<void> settle() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<void> capture(String name) async {
    await settle();
    final render =
        boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await render.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await File(
      '${widget.output.path}/$name.png',
    ).writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
    // Boundary readback and the native window present on separate timelines.
    // Present another frame before reading X11 so both images show settled text.
    WidgetsBinding.instance.scheduleFrame();
    await settle();
    stdout.writeln('CAPTURE $name');
    final native = await Process.run('/usr/bin/python3', [
      '-c',
      r'''
import gi,sys
gi.require_version('Gdk','3.0')
from gi.repository import Gdk
root=Gdk.get_default_root_window()
Gdk.pixbuf_get_from_window(root,0,0,root.get_width(),root.get_height()).savev(sys.argv[1],'png',[],[])
''',
      '${widget.output.path}/$name-native.png',
    ]);
    if (native.exitCode != 0) {
      throw StateError('Native capture failed: ${native.stderr}');
    }
  }

  Future<void> reveal(Widget target) async {
    BuildContext? targetContext;
    void visit(Element element) {
      if (identical(element.widget, target)) {
        targetContext = element;
        return;
      }
      element.visitChildren(visit);
    }

    WidgetsBinding.instance.rootElement!.visitChildren(visit);
    if (targetContext == null) throw StateError('Missing reveal target');
    await Scrollable.ensureVisible(targetContext!, alignment: .5);
    await settle();
  }

  Future<void> key(String value) async {
    final result = await Process.run(
      '/usr/bin/python3',
      ['tools/nextcloud_notes_native_key.py', value],
      environment: {'BUSYMARK_NATIVE_ACCEPTANCE': '1'},
    );
    if (result.exitCode != 0) {
      throw StateError('Native key failed: ${result.stderr}');
    }
    await settle();
  }

  Future<void> until(bool Function() condition, String description) async {
    final end = DateTime.now().add(const Duration(seconds: 20));
    while (!condition()) {
      if (DateTime.now().isAfter(end)) throw StateError(description);
      await settle();
    }
  }

  BuildContext get modalContext => rootNavigatorKey.currentContext!;
  Future<void> dismissModal() async {
    final l10n = AppLocalizations.of(modalContext);
    final close = widgets<BusyMarkDialogButton>().lastWhere(
      (b) =>
          b.onPressed != null &&
          (b.label == l10n.cancel || b.label == l10n.close),
    );
    close.onPressed!();
    await settle();
  }

  BusyMarkSidebarRecordRow<String> get firstNote =>
      widgets<BusyMarkSidebarRecordRow<String>>().firstWhere(
        (r) => r.key == ValueKey('nextcloud-note-${_noteId(0)}'),
      );
  Future<void> properties(String name) async {
    await click(firstNote, button: 3);
    await key('home');
    await key('down');
    await key('down');
    await key('enter');
    await until(
      () => widgets<BusyMarkDialogShell>().isNotEmpty,
      'properties opened',
    );
    await capture(name);
    final selected = ref
        .read(notesNavigationProvider(_account))
        .selected
        .length;
    await key('tab');
    await key('ctrl+a');
    if (ref.read(notesNavigationProvider(_account)).selected.length !=
        selected) {
      throw StateError('Modal field shortcut reached the note list');
    }
    await dismissModal();
  }

  Future<void> click(Widget widget, {int button = 1}) async {
    RenderBox? box;
    void visit(Element element) {
      if (identical(element.widget, widget)) {
        box = element.findRenderObject() as RenderBox?;
        return;
      }
      element.visitChildren(visit);
    }

    WidgetsBinding.instance.rootElement!.visitChildren(visit);
    if (box == null) throw StateError('Missing pointer target');
    final origin = await windowManager.getPosition();
    final point = box!.localToGlobal(box!.size.center(Offset.zero)) + origin;
    final result = await Process.run('xdotool', [
      'mousemove',
      '--sync',
      '${point.dx.round()}',
      '${point.dy.round()}',
      'click',
      '$button',
    ]);
    if (result.exitCode != 0) {
      throw StateError('Native pointer delivery failed: ${result.stderr}');
    }
    await settle();
  }

  Future<void> transfers() async {
    final host = modalContext;
    final repository = ref.read(nextcloudNotesRepositoryProvider).value!;
    final snapshot = await ref
        .read(workspaceControllerProvider.notifier)
        .captureNextcloudExport({_noteId(0)});
    if (snapshot == null || !host.mounted) {
      throw StateError('Export snapshot unavailable');
    }
    final service = NotesTransferService(repository);
    final parent = await Directory(
      '${widget.output.path}/portable-export',
    ).create(recursive: true);
    if (!host.mounted) return;
    final gate = Completer<void>();
    final pending = showBusyMarkModalDialog<void>(
      host,
      barrierDismissible: false,
      builder: (_) => NotesTransferProgressDialog(
        title: AppLocalizations.of(host).notesExport,
        exporting: true,
        operation: (cancel, progress) async {
          progress(0, snapshot.length);
          await gate.future;
          final result = await service.exportSnapshot(
            notes: snapshot,
            destination: parent.path,
            cancellation: cancel,
            onProgress: progress,
          );
          return NotesTransferResult(
            phase: result.complete
                ? NotesTransferPhase.completed
                : NotesTransferPhase.partial,
            created: result.count,
            destination: result.path,
            omissions: result.omissions,
          );
        },
      ),
    );
    await until(
      () => widgets<NotesTransferProgressDialog>().isNotEmpty,
      'transfer progress opened',
    );
    await key('escape');
    if (widgets<NotesTransferProgressDialog>().isEmpty) {
      throw StateError('Escape closed an active transfer');
    }
    await capture('notes-export-running');
    widgets<BusyMarkDialogButton>()
        .lastWhere((b) => b.label == AppLocalizations.of(modalContext).cancel)
        .onPressed!();
    await capture('notes-export-cancelling');
    gate.complete();
    await until(
      () => widgets<BusyMarkDialogButton>().any(
        (b) => b.label == AppLocalizations.of(modalContext).close,
      ),
      'export cancelled',
    );
    await capture('notes-export-cancelled');
    await dismissModal();
    await pending;
    if (!host.mounted) return;
    final completed = showBusyMarkModalDialog<void>(
      host,
      barrierDismissible: false,
      builder: (_) => NotesTransferProgressDialog(
        title: AppLocalizations.of(host).notesExport,
        exporting: true,
        operation: (cancel, progress) async {
          final result = await service.exportSnapshot(
            notes: snapshot,
            destination: parent.path,
            cancellation: cancel,
            onProgress: progress,
          );
          if (!await Directory(result.path).exists()) {
            throw StateError('Export publication missing');
          }
          return NotesTransferResult(
            phase: result.complete
                ? NotesTransferPhase.completed
                : NotesTransferPhase.partial,
            created: result.count,
            destination: result.path,
            omissions: result.omissions,
          );
        },
      ),
    );
    await until(
      () => widgets<BusyMarkDialogButton>().any(
        (b) => b.label == AppLocalizations.of(modalContext).close,
      ),
      'export published',
    );
    await capture('notes-export-published');
    await dismissModal();
    await completed;
    final source = await Directory(
      '${widget.output.path}/import-source',
    ).create(recursive: true);
    await File('${source.path}/scan.md').writeAsString('# Scanned fixture');
    if (!host.mounted) return;
    final scanGate = Completer<void>();
    final scan = showBusyMarkModalDialog<NotesImportReview>(
      host,
      barrierDismissible: false,
      builder: (_) => NotesImportScanDialog(
        scan: (cancel) async {
          await scanGate.future;
          return service.review(source.path, _account, cancellation: cancel);
        },
      ),
    );
    await until(
      () => widgets<NotesImportScanDialog>().isNotEmpty,
      'scan opened',
    );
    await capture('notes-import-scanning');
    widgets<BusyMarkDialogButton>()
        .lastWhere((b) => b.label == AppLocalizations.of(modalContext).cancel)
        .onPressed!();
    await capture('notes-import-cancelling');
    scanGate.complete();
    await until(
      () => widgets<BusyMarkDialogButton>().any(
        (b) => b.label == AppLocalizations.of(modalContext).close,
      ),
      'scan cancelled',
    );
    await capture('notes-import-cancelled');
    await dismissModal();
    if (await scan != null) {
      throw StateError('Cancelled scan returned a late review');
    }
  }

  Future<void> importReview(String name) async {
    final dialogHost = modalContext;
    final importReview = showBusyMarkModalDialog<bool>(
      dialogHost,
      builder: (_) => NotesImportReviewDialog(
        review: NotesImportReview('/fixture', [
          NotesImportItem(
            key: 'fixture',
            path: '/fixture/source.md',
            title: 'Reviewed note',
            category: 'Projects/Nested',
            content: 'Text',
            collision: true,
            issues: ['missing-image.png'],
          ),
        ], []),
      ),
    );
    await until(
      () => widgets<NotesImportReviewDialog>().isNotEmpty,
      'import review opened',
    );
    await capture(name);
    await dismissModal();
    await importReview;
  }

  Future<void> importChooser(String name) async {
    final dialogHost = modalContext;
    final chooser = showBusyMarkModalDialog<String>(
      dialogHost,
      builder: (_) => const NotesImportOperationDialog(
        operations: [
          {
            'id': 'fixture-operation',
            'root': '/fixture/مسار طويل/子/Retained import',
            'created_at': 1780000000,
          },
        ],
      ),
    );
    await until(
      () => widgets<NotesImportOperationDialog>().isNotEmpty,
      'import chooser opened',
    );
    await capture(name);
    await dismissModal();
    await chooser;
  }

  Future<void> dialogs() async {
    final dialogHost = modalContext;
    await properties('note-properties-light');
    if (!dialogHost.mounted) return;
    final offline = showNotesOffline(
      dialogHost,
      ref,
      ref.read(nextcloudNotesRepositoryProvider).value!.noteById(_noteId(0))!,
    );
    await until(
      () => widgets<NotesOfflineDialog>().isNotEmpty,
      'offline opened',
    );
    await capture('note-offline-light');
    await dismissModal();
    await offline;
    final repository = ref.read(nextcloudNotesRepositoryProvider).value!;
    if (!dialogHost.mounted) return;
    final recovery = showNotesRecovery(
      dialogHost,
      ref,
      repository.noteById(_noteId(3))!,
    );
    await until(
      () => widgets<NotesRecoveryDialog>().isNotEmpty,
      'recovery opened',
    );
    await capture('note-recovery-light');
    await dismissModal();
    await recovery;
    if (!dialogHost.mounted) return;
    final conflict = showNextcloudConflict(
      dialogHost,
      ref,
      repository.noteById(_noteId(2))!,
    );
    await until(
      () => widgets<BusyMarkDialogShell>().isNotEmpty,
      'comparison opened',
    );
    await capture('note-conflict-light');
    await dismissModal();
    await conflict;
    if (!mounted) return;
    if (!dialogHost.mounted) return;
    final batch = showNotesBatch(dialogHost, ref, [
      _noteId(0),
      _noteId(5),
    ], initialAction: 'move');
    await until(
      () => widgets<BusyMarkDialogShell>().isNotEmpty,
      'batch opened',
    );
    await capture('note-batch-review-light');
    if (!dialogHost.mounted) return;
    widgets<BusyMarkDialogButton>()
        .lastWhere((b) => b.label == AppLocalizations.of(dialogHost).save)
        .onPressed!();
    await until(
      () => widgets<Text>().any(
        (t) => t.data?.contains('Saved locally · sync pending:') == true,
      ),
      'batch outcomes',
    );
    await capture('note-batch-partial-light');
    await dismissModal();
    await batch;
    if (!dialogHost.mounted) return;
    await importReview('note-import-review-light');
    await transfers();
    ref
        .read(appRouterProvider)
        .go('/settings?returnTo=workspace&page=nextcloudNotes');
    await until(
      () => ref.read(notesSettingsProvider).draft != null,
      'server settings loaded',
    );
    await capture('notes-account-settings-light');
    final original = ref.read(notesSettingsProvider).original;
    ref
        .read(notesSettingsProvider.notifier)
        .edit(notesPath: 'Draft/Nested category');
    ref.read(appRouterProvider).go('/workspace');
    await until(
      () => widgets<BusyMarkDialogShell>().isNotEmpty,
      'departure decision',
    );
    await capture('notes-settings-departure');
    await dismissModal();
    if (ref.read(notesSettingsProvider).original != original ||
        ref.read(notesSettingsProvider).draft!.notesPath !=
            'Draft/Nested category') {
      throw StateError('Cancelled departure lost draft');
    }
    ref.read(appRouterProvider).go('/workspace');
    await until(
      () => widgets<BusyMarkDialogShell>().isNotEmpty,
      'discard decision',
    );
    widgets<BusyMarkDialogButton>()
        .lastWhere((b) => b.destructive)
        .onPressed!();
    await settle();
  }

  Future<void> run() async {
    await windowManager.focus();
    try {
      final workspace = ref.read(workspaceControllerProvider.notifier);
      await workspace.openNextcloudWorkspace(_account);
      ref.read(appRouterProvider).go('/workspace');
      await settle();
      await capture('notes-light-300');
      if (widget.importOnly) {
        await importChooser('import-chooser-light');
        await importReview('import-review-light');
        await ref
            .read(appSettingsControllerProvider.notifier)
            .setThemeModePreference(BusyMarkThemeModePreference.dark);
        await ref
            .read(appSettingsControllerProvider.notifier)
            .setLocaleTag('ar');
        setState(() => scale = 1.6);
        await windowManager.setSize(const Size(820, 540));
        await importChooser('import-chooser-rtl-scaled');
        await importReview('import-review-rtl-scaled');
        ref
            .read(appRouterProvider)
            .go('/settings?returnTo=workspace&page=nextcloudNotes');
        await until(
          () => ref.read(notesSettingsProvider).draft != null,
          'scaled account settings loaded',
        );
        await capture('account-settings-rtl-scaled');
        await reveal(
          widgets<BusyMarkGroupedTextEntry>().firstWhere(
            (entry) =>
                entry.label ==
                AppLocalizations.of(modalContext).nextcloudNotesPath,
          ),
        );
        await capture('server-settings-rtl-scaled');
        await File('${widget.output.path}/result.txt').writeAsString(
          'PASS: shared import review and resume chooser; light, dark/RTL, 1.6 text, short window.\n',
        );
        return;
      }
      if (widget.empty) {
        for (final destination in NotesDestination.values.where(
          (d) => d != NotesDestination.category,
        )) {
          final tree = widgets<BusyMarkSidebarTreeRow>().firstWhere(
            (row) => row.key == ValueKey(destination),
          );
          tree.onTap!();
          await capture('notes-empty-${destination.name}');
        }
        await File('${widget.output.path}/result.txt').writeAsString(
          'PASS: empty account, Favorites, Uncategorized and Recovery in production Linux shell.\n',
        );
        return;
      }
      if (widget.states) {
        for (final entry in {
          'read-only': 5,
          'offline': 7,
          'locked': 9,
          'storage-full': 10,
          'throttled': 11,
          'rejected': 12,
          'conflict': 2,
        }.entries) {
          await workspace.openNextcloudNote(_noteId(entry.value));
          await capture('notes-status-${entry.key}');
        }
        final repository =
            ref.read(nextcloudNotesRepositoryProvider).value!
                as _FixtureRepository;
        for (final code in [
          NotesFailureCode.network,
          NotesFailureCode.authentication,
          NotesFailureCode.forbidden,
        ]) {
          repository.fixtureError = NotesException(
            code,
            'Controlled fixture failure',
          );
          await repository.upsertAccount(repository.accounts.single);
          await capture('notes-account-${code.name}');
        }
        repository.fixtureError = null;
        await repository.upsertAccount(repository.accounts.single);
      }
      await workspace.openNextcloudNote(_noteId(0));
      await settle();
      if (!widget.before) {
        if (widget.keyboardOnly) {
          final projects = widgets<BusyMarkSidebarTreeRow>().firstWhere(
            (row) => row.key == const ValueKey('notes-category-Projects'),
          );
          await click(projects);
          await key('left');
          if (!ref
              .read(notesNavigationProvider(_account))
              .collapsed
              .contains('Projects')) {
            throw StateError('Left did not collapse the focused category');
          }
          await key('right');
          if (ref
              .read(notesNavigationProvider(_account))
              .collapsed
              .contains('Projects')) {
            throw StateError('Right did not expand the focused category');
          }
          await key('ctrl+3');
          await key('ctrl+1');
          await until(
            () => widgets<BusyMarkSidebarTreeRow>().any(
              (row) =>
                  row.key == const ValueKey('notes-category-Projects') &&
                  row.focusNode?.hasFocus == true,
            ),
            'Notes shortcut restores category keyboard focus',
          );
          await capture('notes-keyboard-category');
          await click(
            widgets<BusyMarkSidebarTreeRow>().firstWhere(
              (row) => row.key == const ValueKey(NotesDestination.all),
            ),
          );
        }
        final rows = widgets<BusyMarkSidebarRecordRow>();
        final first = rows.firstWhere(
          (r) => r.key == ValueKey('nextcloud-note-${_noteId(0)}'),
        );
        first.focusNode!.requestFocus();
        await key('down');
        await key('page-down');
        await capture('notes-keyboard-page-down');
        await key('page-up');
        await key('end');
        final last = ref
            .read(notesNavigationProvider(_account))
            .visible
            .last
            .localId;
        await until(
          () => widgets<BusyMarkSidebarRecordRow>().any(
            (row) =>
                row.key == ValueKey('nextcloud-note-$last') &&
                row.focusNode?.hasFocus == true,
          ),
          'End reveals and focuses the last note',
        );
        await capture('notes-keyboard-end');
        await key('home');
        await capture('notes-keyboard-home');
        await key('shift+F10');
        await capture('notes-keyboard-menu');
        await key('escape');
        final trigger = widgets<BusyMarkCompactIconButton>().firstWhere(
          (b) => b.tooltip == 'Note actions',
        );
        await click(trigger);
        await capture('notes-overflow-menu');
        await key('escape');
        await click(firstNote, button: 3);
        await capture('notes-pointer-menu');
        await key('escape');
        if (widget.keyboardOnly) {
          final repository = ref.read(nextcloudNotesRepositoryProvider).value!;
          BusyMarkCompactIconButton triggerFor(String id) {
            final rows = widgets<BusyMarkSidebarRecordRow>();
            final index = rows.indexWhere(
              (r) => r.key == ValueKey('nextcloud-note-$id'),
            );
            return widgets<BusyMarkCompactIconButton>()
                .where((b) => b.tooltip == 'Note actions')
                .elementAt(index);
          }

          final a = _noteId(0), b = _noteId(1);
          final favoriteA = repository.noteById(a)!.favorite;
          await click(triggerFor(a));
          await key('escape');
          final rowB = widgets<BusyMarkSidebarRecordRow>().firstWhere(
            (r) => r.key == ValueKey('nextcloud-note-$b'),
          );
          rowB.focusNode!.requestFocus();
          await settle();
          for (
            var i = 0;
            i < 40 && triggerFor(b).focusNode?.hasPrimaryFocus != true;
            i++
          ) {
            await key('tab');
          }
          if (triggerFor(b).focusNode?.hasPrimaryFocus != true) {
            throw StateError('Tab did not focus B overflow');
          }
          await key('enter');
          await capture('note-b-keyboard-overflow');
          await key('home');
          await key('enter');
          await until(
            () => repository.noteById(b)!.favorite,
            'Keyboard Favorite targets B',
          );
          if (repository.noteById(a)!.favorite != favoriteA) {
            throw StateError('B menu changed A');
          }
          await click(triggerFor(a));
          await key('escape');
          widgets<BusyMarkSidebarRecordRow>()
              .firstWhere((r) => r.key == ValueKey('nextcloud-note-$b'))
              .focusNode!
              .requestFocus();
          await settle();
          for (
            var i = 0;
            i < 40 && triggerFor(b).focusNode?.hasPrimaryFocus != true;
            i++
          ) {
            await key('tab');
          }
          if (triggerFor(b).focusNode?.hasPrimaryFocus != true) {
            throw StateError('Tab did not return to B overflow');
          }
          await key('enter');
          await key('home');
          await key('down');
          await key('down');
          await key('enter');
          await until(
            () => widgets<BusyMarkDialogShell>().isNotEmpty,
            'B Properties opened',
          );
          final title = widgets<BusyMarkGroupedTextEntry>().first;
          if (title.controller?.text != repository.noteById(b)!.title &&
              title.initialValue != repository.noteById(b)!.title) {
            throw StateError('B Properties displayed another note');
          }
          await capture('note-b-keyboard-properties');
          await dismissModal();

          await workspace.openNextcloudNote(a);
          workspace.updateActiveText(
            [
              for (var i = 0; i < 60; i++)
                '# Heading ${i.toString().padLeft(2, '0')}\n\nParagraph $i.\n',
            ].join('\n'),
          );
          await key('ctrl+3');
          BusyMarkSidebarTreeRow? focusedHeading() => FocusManager
              .instance
              .primaryFocus
              ?.context
              ?.findAncestorWidgetOfExactType<BusyMarkSidebarTreeRow>();
          for (
            var i = 0;
            i < 15 && focusedHeading()?.title != 'Heading 00';
            i++
          ) {
            await key('tab');
          }
          if (focusedHeading()?.title != 'Heading 00') {
            throw StateError('Tab did not reach Outline heading row');
          }
          await key('down');
          if (!widgets<BusyMarkSidebarTreeRow>().any(
            (r) => r.title == 'Heading 01' && r.selected,
          )) {
            throw StateError('Outline Down did not select heading 01');
          }
          await key('up');
          if (!widgets<BusyMarkSidebarTreeRow>().any(
            (r) => r.title == 'Heading 00' && r.selected,
          )) {
            throw StateError('Outline Up did not select heading 00');
          }
          await capture('outline-tabbed-row-arrows');
          for (var i = 0; i < 35; i++) {
            await key('down');
          }
          if (!widgets<BusyMarkSidebarTreeRow>().any(
            (r) => r.title == 'Heading 35' && r.selected,
          )) {
            throw StateError('Outline did not reveal heading 35');
          }
          await key('enter');
          final headings = activeDocumentOutline(
            ref.read(workspaceControllerProvider),
          );
          if (ref.read(outlineNavigationTargetProvider)?.headingId !=
              headings[35].id) {
            throw StateError('Outline activation used the wrong heading');
          }
          await capture('outline-keyboard-reveal-activation');
          await File('${widget.output.path}/result.txt').writeAsString(
            'PASS: native category Left/Right, note Down/PageDown/PageUp/End/Home, Shift+F10, overflow and pointer menus; pointer A then Tab/Enter on B targets Favorite and Properties only on B; Tab into Outline row, Up/Down selection, scrolling reveal and Enter activation.\n',
          );
          return;
        }
        await dialogs();
      }
      await key('ctrl+3');
      await capture('outline-roundtrip');
      await key('ctrl+1');
      if (widgets<NextcloudNotesSidebar>().isEmpty) {
        throw StateError('Notes did not reopen after Outline');
      }
      await capture('notes-after-outline');
      ref
          .read(searchSessionProvider.notifier)
          .open(category: SearchCategory.workspace);
      await capture('shared-search');
      ref.read(searchSessionProvider.notifier).close();
      await capture('notes-after-search');
      await ref
          .read(appSettingsControllerProvider.notifier)
          .setThemeModePreference(BusyMarkThemeModePreference.dark);
      await capture('notes-dark-300');
      setState(() => scale = 1.6);
      await windowManager.setSize(const Size(820, 540));
      await capture('notes-dark-short-scaled');
      if (!widget.before) await properties('note-properties-dark-short-scaled');
      await ref.read(appSettingsControllerProvider.notifier).setLocaleTag('ar');
      await capture('notes-rtl-short-scaled');
      if (!widget.before) await properties('note-properties-rtl-short-scaled');
      if (!widget.before) {
        await windowManager.setSize(const Size(700, 540));
        await key('F8');
        await key('F8');
        await capture('notes-rtl-narrow-700');
      }
      await File('${widget.output.path}/result.txt').writeAsString(
        'PASS: production shell, controlled fixture account, 300px sidebar; light/dark; 1.6 text; 820x540; RTL; before=${widget.before}.\n',
      );
    } on Object catch (error, stack) {
      await File(
        '${widget.output.path}/failure.txt',
      ).writeAsString('$error\n$stack');
      stderr.writeln('$error\n$stack');
      exitCode = 1;
    } finally {
      exit(exitCode);
    }
  }
}
