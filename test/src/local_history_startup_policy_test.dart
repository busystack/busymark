import 'dart:async';
import 'dart:io';

import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/local_history/local_history_controller.dart';
import 'package:busymark/src/local_history/local_history_models.dart';
import 'package:busymark/src/local_history/local_history_store.dart';
import 'package:busymark/src/workspace/document_buffer.dart';
import 'package:busymark/src/workspace/text_format_metadata.dart';
import 'package:busymark/src/workspace/workspace_file_snapshot.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('startup capture waits for a saved disabled-recording policy', () async {
    final directory = await Directory.systemTemp.createTemp(
      'bm2-history-policy-',
    );
    final store = _ObservedStore(directory);
    final settings = _DelayedSettings();
    final container = ProviderContainer(
      overrides: [
        localSettingsStoreProvider.overrideWithValue(settings),
        localHistoryStoreProvider.overrideWithValue(store),
      ],
    );
    addTearDown(() async {
      if (!settings.ready.isCompleted) {
        settings.ready.complete(
          AppSettings.defaults()
              .copyWith(localHistoryRecordingEnabled: false)
              .toJson(),
        );
      }
      await container
          .read(appSettingsControllerProvider.notifier)
          .waitUntilLoaded();
      container.dispose();
      await store.load();
      await directory.delete(recursive: true);
    });
    final controller = container.read(localHistoryControllerProvider.notifier);
    final opening = controller.observeOpened(
      DocumentBuffer.file(
        id: 'private',
        filePath: '/fixture.md',
        text: 'private draft',
        snapshot: WorkspaceFileSnapshot(
          modifiedAt: DateTime.utc(2026),
          size: 13,
          contentHash: 'fixture',
        ),
        format: TextFormatMetadata.utf8Lf,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(store.capturedSources, isEmpty);
    settings.ready.complete(
      AppSettings.defaults()
          .copyWith(localHistoryRecordingEnabled: false)
          .toJson(),
    );
    await opening;
    expect(store.capturedSources, isEmpty);
    expect((await store.load()).revisions, isEmpty);
  });
  test(
    'startup retention waits for the saved policy before deleting history',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'bm2-history-policy-',
      );
      final store = _ObservedStore(directory);
      const broad = LocalHistoryPolicy(retentionAge: Duration(days: 365));
      for (final entry in [
        (DateTime.utc(2026, 7, 1), 'older'),
        (DateTime.utc(2026, 10, 15), 'current'),
      ]) {
        await store.capture(
          LocalHistoryCaptureRequest(
            path: '/fixture.md',
            displayName: 'fixture.md',
            source: entry.$2,
            format: TextFormatMetadata.utf8Lf,
            capturedAt: entry.$1,
            reason: LocalHistoryCaptureReason.saved,
          ),
          broad,
        );
      }
      final settings = _DelayedSettings();
      final container = ProviderContainer(
        overrides: [
          localSettingsStoreProvider.overrideWithValue(settings),
          localHistoryStoreProvider.overrideWithValue(store),
          localHistoryClockProvider.overrideWithValue(
            () => DateTime.utc(2026, 10, 15),
          ),
        ],
      );
      addTearDown(() async {
        if (!settings.ready.isCompleted) {
          settings.ready.complete(
            AppSettings.defaults()
                .copyWith(localHistoryRetentionDays: 365)
                .toJson(),
          );
        }
        await container
            .read(appSettingsControllerProvider.notifier)
            .waitUntilLoaded();
        container.dispose();
        await store.load();
        await directory.delete(recursive: true);
      });
      final controller = container.read(
        localHistoryControllerProvider.notifier,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(
        store.prunedPolicies,
        isEmpty,
        reason:
            'The default 30-day policy must not delete history while the saved policy is still loading.',
      );
      settings.ready.complete(
        AppSettings.defaults()
            .copyWith(localHistoryRetentionDays: 365)
            .toJson(),
      );
      expect(await controller.refresh(), isTrue);
      expect(store.prunedPolicies, [const Duration(days: 365)]);
      final snapshot = await store.load();
      expect(snapshot.revisions, hasLength(2));
      expect(
        await Future.wait(
          snapshot.revisions.map(
            (revision) async => (await store.readRevision(revision.id))!.source,
          ),
        ),
        unorderedEquals(['older', 'current']),
      );
    },
  );
}

class _ObservedStore extends FileLocalHistoryStore {
  _ObservedStore(Directory root) : super(rootDirectory: () async => root);
  final prunedPolicies = <Duration>[];
  final capturedSources = <String>[];

  @override
  Future<LocalHistoryCaptureResult> capture(
    LocalHistoryCaptureRequest request,
    LocalHistoryPolicy policy,
  ) {
    capturedSources.add(request.source);
    return super.capture(request, policy);
  }

  @override
  Future<void> prune(LocalHistoryPolicy policy, DateTime now) {
    prunedPolicies.add(policy.retentionAge);
    return super.prune(policy, now);
  }
}

class _DelayedSettings implements LocalSettingsStore {
  final ready = Completer<Map<String, Object?>>();
  @override
  Future<Map<String, Object?>> load() => ready.future;
  @override
  Future<void> save(Map<String, Object?> json) async {}
}
