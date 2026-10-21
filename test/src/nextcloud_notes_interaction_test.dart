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
  for (final historical in [false, true]) {
    testWidgets(
      'created recovery retries opening without creating again, history=$historical',
      (tester) async {
        await launch(tester);
        if (historical) {
          await tester.tap(find.byType(BusyMarkComboRow<String>));
          await tester.pumpAndSettle();
          await tester.tap(
            find.byWidgetPredicate(
              (w) => w is PopupMenuItem<int> && w.value == 1,
            ),
          );
          await _settle(tester);
        }
        repository.recoverGate = Completer<void>();
        await tester.runAsync(
          () => tester.tap(
            find.byWidgetPredicate(
              (w) => w is BusyMarkDialogButton && w.label.contains('New note'),
            ),
          ),
        );
        await _settle(tester);
        expect(repository.recoveries, 1);
        final workspace = container.read(workspaceControllerProvider.notifier);
        final draft = workspace.propertyEdits.bind(
          'reject-open-after-commit',
          '',
          (_) => false,
        );
        workspace.propertyEdits.edit(draft, 'unflushed property draft');
        repository.recoverGate!.complete();
        await _settle(tester);
        expect(repository.notes, hasLength(3));
        final createdId = repository.notes
            .singleWhere((n) => n.localId != 'retained' && n.localId != 'live')
            .localId;
        expect(
          find.textContaining('The recovered note was saved'),
          findsOneWidget,
        );
        expect(find.byType(NotesRecoveryDialog), findsOneWidget);
        await tester.runAsync(
          () => tester.tap(find.widgetWithText(BusyMarkDialogButton, 'Open')),
        );
        await _settle(tester);
        expect(repository.recoveries, 1);
        expect(repository.notes, hasLength(3));
        workspace.propertyEdits.revert(draft);
        await tester.runAsync(
          () => tester.tap(find.widgetWithText(BusyMarkDialogButton, 'Open')),
        );
        await _settle(tester);
        expect(repository.notes, hasLength(3));
        expect(repository.recoveries, 1);
        expect(
          container
              .read(workspaceControllerProvider)
              .activeBuffer!
              .remoteNote!
              .localId,
          createdId,
        );
        expect(find.byType(NotesRecoveryDialog), findsNothing);
      },
    );
  }

  testWidgets(
    'export staging progress followed by failure reports no publication',
    (tester) async {
      await tester.pumpWidget(
        _app(
          NotesTransferProgressDialog(
            title: 'Export notes',
            exporting: true,
            operation: (cancel, progress) async {
              progress(1, 2);
              throw const FileSystemException('fixture disk full');
            },
          ),
        ),
      );
      await _settle(tester);
      expect(find.textContaining('Transfer failed'), findsOneWidget);
      expect(find.text('No export was published.'), findsOneWidget);
      expect(find.textContaining('Earlier imported'), findsNothing);
      expect(find.textContaining('Resume'), findsNothing);
      expect(
        find.textContaining('Check access and free space'),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'cancelled export creates no snapshot and gives no import advice',
    (tester) async {
      final gate = Completer<NotesTransferResult>();
      await tester.pumpWidget(
        _app(
          NotesTransferProgressDialog(
            title: 'Export notes',
            exporting: true,
            operation: (cancel, progress) async {
              progress(1, 2);
              await gate.future;
              cancel.check();
              throw StateError('unreachable');
            },
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      gate.complete(
        const NotesTransferResult(phase: NotesTransferPhase.cancelled),
      );
      await _settle(tester);
      expect(find.text('Cancelled'), findsOneWidget);
      expect(find.text('No export was published.'), findsOneWidget);
      expect(find.textContaining('Resume'), findsNothing);
    },
  );
  testWidgets(
    'published export with omissions reports destination and no import advice',
    (tester) async {
      await tester.pumpWidget(
        _app(
          NotesTransferProgressDialog(
            title: 'Export notes',
            exporting: true,
            operation: (_, progress) async => const NotesTransferResult(
              phase: NotesTransferPhase.partial,
              created: 2,
              destination: '/published/with-omissions',
              omissions: ['Example: unavailable.png'],
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(find.text('Export available with omissions'), findsOneWidget);
      expect(find.text('/published/with-omissions'), findsOneWidget);
      expect(find.textContaining('Example: unavailable.png'), findsOneWidget);
      expect(find.textContaining('Resume'), findsNothing);
    },
  );

  testWidgets('changed import source retains its reason in results', (
    tester,
  ) async {
    final file = File('${root.path}/reviewed.md');
    await tester.runAsync(() => file.writeAsString('reviewed content'));
    final service = NotesTransferService(repository);
    final review = await tester.runAsync(
      () => service.review(file.path, _account),
    );
    await tester.runAsync(() => file.writeAsString('changed after review'));
    await tester.pumpWidget(
      _app(
        NotesTransferProgressDialog(
          title: 'Import notes',
          operation: (cancel, progress) async {
            final items = await service.importReviewed(
              review!,
              _account,
              cancellation: cancel,
              onProgress: progress,
            );
            return NotesTransferResult(
              phase: NotesTransferPhase.failed,
              failed: 1,
              items: items,
            );
          },
        ),
      ),
    );
    await _settle(tester);
    expect(
      find.textContaining('The source changed after review'),
      findsOneWidget,
    );
    expect(find.textContaining('Review the current file'), findsOneWidget);
    expect(repository.notes, hasLength(2));
  });
  for (final malformed in [true, false]) {
    testWidgets('scan failure keeps actionable reason, malformed=$malformed', (
      tester,
    ) async {
      final source = malformed
          ? Directory('${root.path}/invalid-snapshot')
          : Directory('${root.path}/missing-source');
      if (malformed) {
        await tester.runAsync(() async {
          await source.create();
          await File(
            '${source.path}/${NotesTransferService.manifestName}',
          ).writeAsString('{"format":"unsupported"}');
        });
      }
      await tester.pumpWidget(
        _app(
          NotesImportScanDialog(
            scan: (cancel) => NotesTransferService(
              repository,
            ).review(source.path, _account, cancellation: cancel),
          ),
        ),
      );
      await _settle(tester);
      expect(
        find.textContaining(
          malformed ? 'snapshot is invalid' : 'source could not be read',
        ),
        findsOneWidget,
      );
      expect(find.text('Technical details'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });
  }
  testWidgets(
    'a published export remains completed when cancellation races its result',
    (tester) async {
      final gate = Completer<NotesTransferResult>();
      await tester.pumpWidget(
        _app(
          NotesTransferProgressDialog(
            title: 'Export notes',
            exporting: true,
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
