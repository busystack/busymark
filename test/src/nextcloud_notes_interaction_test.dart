import 'dart:async';
import 'dart:io';

import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/busymark_dialogs.dart';
import 'package:busymark/src/local_history/local_history_controller.dart';
import 'package:busymark/src/local_history/local_history_models.dart';
import 'package:busymark/src/local_history/local_history_store.dart';
import 'package:busymark/src/nextcloud_notes/application/nextcloud_connection.dart';
import 'package:busymark/src/nextcloud_notes/application/notes_repository.dart';
import 'package:busymark/src/nextcloud_notes/application/notes_transfer_service.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_store.dart';
import 'package:busymark/src/nextcloud_notes/domain/notes_models.dart';
import 'package:busymark/src/nextcloud_notes/presentation/notes_workspace_ui.dart';
import 'package:busymark/src/workspace/document_origin.dart';
import 'package:busymark/src/workspace/recovery_persistence.dart';
import 'package:busymark/src/workspace/session_persistence.dart';
import 'package:busymark/src/workspace/text_format_metadata.dart';
import 'package:busymark/src/workspace/workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _account = '123e4567-e89b-42d3-a456-426614174000';
const _retained = NextcloudNote(
  localId: 'retained',
  accountId: _account,
  serverId: 3,
  title: 'Retained note',
  content: 'current retained source',
  revision: 1,
  ackRevision: 1,
  syncState: NoteSyncState.deletedRemotely,
);

class _History extends MemoryLocalHistoryStore {
  Completer<LocalHistoryRevision?>? held;
  final readStarted = Completer<void>();
  final revisions = <String, LocalHistoryRevision>{};
  _History() {
    for (final id in ['retained', 'existing']) {
      final source = '$id historical source';
      revisions[id] = LocalHistoryRevision(
        summary: LocalHistoryRevisionSummary(
          id: '$id-rev',
          documentId: id,
          capturedAt: DateTime.utc(2026, 10, 1),
          reason: LocalHistoryCaptureReason.saved,
          checksum: sourceChecksum(source),
          storageBytes: source.length,
          sourceLength: source.length,
        ),
        source: source,
        format: TextFormatMetadata.utf8Lf,
      );
    }
  }
  @override
  Future<LocalHistorySnapshot> load() async => LocalHistorySnapshot(
    documents: [
      for (final id in revisions.keys)
        LocalHistoryDocument(
          id: id,
          displayName: id,
          updatedAt: DateTime.utc(2026),
          remoteNote: id == 'retained'
              ? const NextcloudNoteReference(
                  accountId: _account,
                  localId: 'retained',
                )
              : null,
        ),
    ],
    revisions: revisions.values.map((r) => r.summary).toList(),
  );
  @override
  Future<LocalHistoryRevision?> readRevision(String id) async {
    if (id == 'retained-rev' && held != null) {
      if (!readStarted.isCompleted) readStarted.complete();
      return held!.future;
    }
    return revisions[id.replaceFirst('-rev', '')] ??
        await super.readRevision(id);
  }
}

class _Repository extends NotesRepository {
  _Repository(NotesStore store)
    : super(
        store: store,
        clientForAccount: (_) async => throw StateError('fixture is offline'),
      );
  int recoveries = 0;
  Completer<void>? recoverGate;
  @override
  Future<void> synchronize(
    String id, {
    bool allowWrites = true,
    bool refreshCapabilities = false,
    bool onlyFreshWrites = false,
  }) async {}
  @override
  Future<NextcloudNote> recoverAsNew(
    String id, {
    String? content,
    String? title,
    bool creationDecision = false,
  }) async {
    recoveries++;
    await recoverGate?.future;
    return super.recoverAsNew(
      id,
      content: content,
      title: title,
      creationDecision: creationDecision,
    );
  }
}

class _Settings implements LocalSettingsStore {
  @override
  Future<Map<String, Object?>> load() async => AppSettings.defaults()
      .copyWith(autoSave: false, automaticSpelling: false)
      .toJson();
  @override
  Future<void> save(Map<String, Object?> value) async {}
}

Widget _app(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 20));
  }
}

void main() {
  late Directory root;
  late _Repository repository;
  late _History history;
  late ProviderContainer container;
  setUp(() async {
    for (final name in ['yaru_window', 'yaru_window/events']) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            MethodChannel(name),
            (call) async => call.method == 'state' ? <String, Object?>{} : null,
          );
    }
    root = await Directory.systemTemp.createTemp('notes-interaction-');
    final store = await NotesStore.open(path: '${root.path}/notes.sqlite3');
    await store.saveAccount(
      NextcloudAccount(
        id: _account,
        server: Uri.parse('https://fixture.invalid'),
        loginName: 'fixture',
        appVersion: '6.1.0',
      ),
    );
    await store.saveNote(_retained);
    await store.saveNote(
      const NextcloudNote(
        localId: 'live',
        accountId: _account,
        title: 'Open document',
        content: 'editor source',
      ),
    );
    repository = _Repository(store);
    await repository.initialize();
    history = _History();
    container = ProviderContainer(
      overrides: [
        nextcloudNotesRepositoryProvider.overrideWith((_) async => repository),
        localHistoryStoreProvider.overrideWithValue(history),
        localSettingsStoreProvider.overrideWithValue(_Settings()),
        documentSessionStoreProvider.overrideWithValue(
          MemoryDocumentSessionStore(),
        ),
        documentRecoveryStoreProvider.overrideWithValue(
          MemoryDocumentRecoveryStore(),
        ),
      ],
    );
  });
  tearDown(() async {
    container.dispose();
    await repository.dispose();
    await root.delete(recursive: true);
  });
  Future<void> launch(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _app(
          Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () => showNotesRecovery(context, ref, _retained),
              child: const Text('recover'),
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      final workspace = container.read(workspaceControllerProvider.notifier);
      await workspace.openNextcloudWorkspace(_account);
      await workspace.openNextcloudNote('live');
      final global = container.read(localHistoryControllerProvider.notifier);
      await global.refresh();
      global.selectDocument('existing');
      await global.selectRevision('existing-rev');
    });
    await _settle(tester);
    await tester.tap(find.text('recover'));
    await _settle(tester);
  }

  testWidgets(
    'recovery preview is local, latest selection wins, and closed reads cannot navigate',
    (tester) async {
      await launch(tester);
      final before = container.read(localHistoryControllerProvider);
      final active = container.read(workspaceControllerProvider).activeBufferId;
      history.held = Completer<LocalHistoryRevision?>();
      tester
          .widget<BusyMarkComboRow<String>>(
            find.byType(BusyMarkComboRow<String>),
          )
          .onSelected('retained-rev');
      await _settle(tester);
      expect(history.readStarted.isCompleted, isTrue);
      tester
          .widget<BusyMarkComboRow<String>>(
            find.byType(BusyMarkComboRow<String>),
          )
          .onSelected('');
      await _settle(tester);
      expect(find.text('current retained source'), findsOneWidget);
      history.held!.complete(history.revisions['retained']);
      await _settle(tester);
      expect(find.text('retained historical source'), findsNothing);
      expect(
        container.read(localHistoryControllerProvider).selectedRevision,
        same(before.selectedRevision),
      );
      expect(
        container.read(localHistoryControllerProvider).selectedDocumentId,
        before.selectedDocumentId,
      );
      expect(
        container.read(workspaceControllerProvider).activeBufferId,
        active,
      );
      history.held = Completer<LocalHistoryRevision?>();
      tester
          .widget<BusyMarkComboRow<String>>(
            find.byType(BusyMarkComboRow<String>),
          )
          .onSelected('retained-rev');
      await _settle(tester);
      await tester.tap(find.text('Close'));
      await _settle(tester);
      history.held!.complete(history.revisions['retained']);
      await _settle(tester);
      expect(
        container.read(localHistoryControllerProvider).selectedRevision,
        same(before.selectedRevision),
      );
      expect(
        container.read(workspaceControllerProvider).activeBufferId,
        active,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'recovery accepts one activation and creates exactly one fresh note',
    (tester) async {
      await launch(tester);
      repository.recoverGate = Completer<void>();
      final button = tester.widget<BusyMarkDialogButton>(
        find.byWidgetPredicate(
          (w) => w is BusyMarkDialogButton && w.label.contains('New note'),
        ),
      );
      await tester.runAsync(() async {
        button.onPressed!();
        button.onPressed!();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(repository.recoveries, 1);
        repository.recoverGate!.complete();
        final end = DateTime.now().add(const Duration(seconds: 10));
        while (repository.notes.length < 3 && DateTime.now().isBefore(end)) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      });
      // The local transaction precedes editor activation and dialog dismissal.
      // Await the observable workflow result, allowing real storage/parse work
      // to finish under the full suite rather than relying on a short pump.
      final settled = DateTime.now().add(const Duration(seconds: 10));
      while (find.byType(NotesRecoveryDialog).evaluate().isNotEmpty &&
          DateTime.now().isBefore(settled)) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
      await _settle(tester);
      expect(
        repository.notes.where(
          (n) => n.localId != 'retained' && n.localId != 'live',
        ),
        hasLength(1),
      );
      expect(find.byType(NotesRecoveryDialog), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('cancelled scanning never publishes a late review', (
    tester,
  ) async {
    final gate = Completer<NotesImportReview>();
    NotesImportReview? result;
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showBusyMarkModalDialog<NotesImportReview>(
                context,
                barrierDismissible: false,
                builder: (_) => NotesImportScanDialog(scan: (_) => gate.future),
              );
            },
            child: const Text('scan'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('scan'));
    await tester.pump();
    expect(find.text('Scanning files…'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    expect(
      find.textContaining('Waiting for the current operation'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<BusyMarkDialogButton>(find.byType(BusyMarkDialogButton))
          .onPressed,
      isNull,
    );
    gate.complete(NotesImportReview('/fixture', [], []));
    await _settle(tester);
    expect(find.text('Cancelled'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await _settle(tester);
    expect(result, isNull);
    expect(find.byType(NotesImportReviewDialog), findsNothing);
  });
  testWidgets(
    'a published export remains completed when cancellation races its result',
    (tester) async {
      final gate = Completer<NotesTransferResult>();
      await tester.pumpWidget(
        _app(
          NotesTransferProgressDialog(
            title: 'Export notes',
            operation: (cancel, progress) async {
              progress(0, 2);
              return gate.future;
            },
          ),
        ),
      );
      await tester.pump();
      expect(find.text('0/2'), findsOneWidget);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        0,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      gate.complete(
        const NotesTransferResult(
          phase: NotesTransferPhase.completed,
          created: 2,
          destination: '/published/notes',
        ),
      );
      await _settle(tester);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Cancelled'), findsNothing);
      expect(find.text('/published/notes'), findsOneWidget);
    },
  );
}
