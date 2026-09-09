import 'dart:async';

import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/local_history/local_history_controller.dart';
import 'package:busymark/src/local_history/local_history_models.dart';
import 'package:busymark/src/local_history/local_history_store.dart';
import 'package:busymark/src/workspace/document_buffer.dart';
import 'package:busymark/src/workspace/text_format_metadata.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'continuous typing captures latest text at fixed checkpoint interval',
    () async {
      var now = DateTime.utc(2026, 1, 1);
      final timers = <_FakeTimer>[];
      final store = MemoryLocalHistoryStore();
      final container = ProviderContainer(
        overrides: [
          localSettingsStoreProvider.overrideWithValue(_MemorySettingsStore()),
          localHistoryStoreProvider.overrideWithValue(store),
          localHistoryClockProvider.overrideWithValue(() => now),
          localHistoryTimerFactoryProvider.overrideWithValue((delay, callback) {
            final timer = _FakeTimer(delay, callback);
            timers.add(timer);
            return timer;
          }),
        ],
      );
      addTearDown(container.dispose);
      await Future<void>.delayed(Duration.zero);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      final opened = DocumentBuffer.untitled(
        id: 'buffer-one',
        name: 'Draft.md',
        text: 'A',
      );
      await controller.observeOpened(opened);
      final firstEdit = opened.edited('B');
      controller.observeEdit(opened, firstEdit);
      await Future<void>.delayed(Duration.zero);
      final secondEdit = firstEdit.edited('C');
      controller.observeEdit(firstEdit, secondEdit);
      await Future<void>.delayed(Duration.zero);

      expect(timers, hasLength(1));
      expect(timers.single.duration, const Duration(seconds: 60));
      now = now.add(const Duration(seconds: 60));
      timers.single.fire();
      await controller.flushAll([secondEdit]);
      final snapshot = await store.load();
      final revisions = snapshot.revisionsFor(snapshot.documents.single.id);

      expect(revisions, hasLength(2));
      expect(revisions.map((entry) => entry.reason), [
        LocalHistoryCaptureReason.automaticCheckpoint,
        LocalHistoryCaptureReason.baseline,
      ]);
      expect((await store.readRevision(revisions.first.id))!.source, 'C');
    },
  );

  test('inactive buffers receive independent checkpoint timers', () async {
    final timers = <_FakeTimer>[];
    final store = MemoryLocalHistoryStore();
    final container = ProviderContainer(
      overrides: [
        localSettingsStoreProvider.overrideWithValue(_MemorySettingsStore()),
        localHistoryStoreProvider.overrideWithValue(store),
        localHistoryTimerFactoryProvider.overrideWithValue((delay, callback) {
          final timer = _FakeTimer(delay, callback);
          timers.add(timer);
          return timer;
        }),
      ],
    );
    addTearDown(container.dispose);
    await Future<void>.delayed(Duration.zero);
    final controller = container.read(localHistoryControllerProvider.notifier);
    final first = DocumentBuffer.untitled(
      id: 'buffer-first',
      name: 'First.md',
      text: 'one',
    );
    final second = DocumentBuffer.untitled(
      id: 'buffer-second',
      name: 'Second.md',
      text: 'two',
    );
    await controller.observeOpened(first);
    await controller.observeOpened(second);
    final firstEdit = first.edited('one changed');
    final secondEdit = second.edited('two changed');
    controller.observeEdit(first, firstEdit);
    controller.observeEdit(second, secondEdit);
    await Future<void>.delayed(Duration.zero);

    expect(timers, hasLength(2));
    for (final timer in timers) {
      timer.fire();
    }
    await controller.flushAll([firstEdit, secondEdit]);
    final snapshot = await store.load();
    expect(snapshot.documents, hasLength(2));
    expect(snapshot.revisions, hasLength(4));
  });

  test(
    'recording off prevents baseline and checkpoints without deleting history',
    () async {
      final settingsStore = _MemorySettingsStore();
      final store = MemoryLocalHistoryStore();
      final container = ProviderContainer(
        overrides: [
          localSettingsStoreProvider.overrideWithValue(settingsStore),
          localHistoryStoreProvider.overrideWithValue(store),
        ],
      );
      addTearDown(container.dispose);
      await Future<void>.delayed(Duration.zero);
      final settings = container.read(appSettingsControllerProvider.notifier);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      final buffer = DocumentBuffer.untitled(
        id: 'buffer-one',
        name: 'Draft.md',
        text: 'text',
      );
      await controller.observeOpened(buffer);
      expect((await store.load()).revisions, hasLength(1));
      await settings.setLocalHistoryRecordingEnabled(false);
      final edited = buffer.edited('changed');
      controller.observeEdit(buffer, edited);
      await controller.flushAll([edited]);
      expect((await store.load()).revisions, hasLength(1));
    },
  );

  test(
    'store-wide find locates closed and deleted documents by path or content',
    () async {
      final store = MemoryLocalHistoryStore();
      await store.capture(
        LocalHistoryCaptureRequest(
          path: '/retired/guides/removed.md',
          displayName: 'removed.md',
          source: 'A vanished authentication phrase',
          format: TextFormatMetadata.utf8Lf,
          capturedAt: DateTime.utc(2026, 1, 1),
          reason: LocalHistoryCaptureReason.beforeDelete,
        ),
        const LocalHistoryPolicy(),
      );
      await store.markDeleted('/retired/guides/removed.md', recursive: false);
      final container = ProviderContainer(
        overrides: [
          localSettingsStoreProvider.overrideWithValue(_MemorySettingsStore()),
          localHistoryStoreProvider.overrideWithValue(store),
          localHistoryClockProvider.overrideWithValue(
            () => DateTime.utc(2026, 1, 2),
          ),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      await controller.refresh();
      expect(
        container.read(localHistoryControllerProvider).snapshot.revisions,
        hasLength(1),
      );
      expect(
        (await store.readRevision(
          container
              .read(localHistoryControllerProvider)
              .snapshot
              .revisions
              .single
              .id,
        ))!.source,
        contains('authentication'),
      );

      controller.beginDocumentSearch();
      await controller.search('authentication');
      var state = container.read(localHistoryControllerProvider);
      expect(state.findingDocuments, isTrue);
      expect(state.documentSearchMatches, {state.snapshot.documents.single.id});

      await controller.search('/retired/guides');
      state = container.read(localHistoryControllerProvider);
      expect(state.documentSearchMatches, {state.snapshot.documents.single.id});
      expect(state.snapshot.documents.single.deleted, isTrue);
    },
  );
}

class _MemorySettingsStore implements LocalSettingsStore {
  Map<String, Object?> value = {};

  @override
  Future<Map<String, Object?>> load() async => value;

  @override
  Future<void> save(Map<String, Object?> json) async => value = json;
}

class _FakeTimer implements Timer {
  _FakeTimer(this.duration, this.callback);

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
