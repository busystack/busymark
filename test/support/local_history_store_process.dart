// Runs under Flutter's test runtime because the production store's dependency
// graph includes dart:ui. Each invocation is an independent OS process.
import 'dart:async';
import 'dart:io';

import 'package:busymark/src/local_history/local_history_models.dart';
import 'package:busymark/src/local_history/local_history_store.dart';
import 'package:busymark/src/workspace/text_format_metadata.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  final rootPath = Platform.environment['BUSYMARK_HISTORY_PROCESS_ROOT'];
  if (rootPath == null) return;
  test('independent history process', () async {
    final root = Directory(rootPath);
    final signal = Platform.environment['BUSYMARK_HISTORY_PROCESS_SIGNAL']!;
    final mode = Platform.environment['BUSYMARK_HISTORY_PROCESS_MODE']!;
    await File('$signal.pid').writeAsString('$pid');
    Future<void> waitForRelease() async {
      final deadline = Stopwatch()..start();
      while (!await File('$signal.release').exists()) {
        if (deadline.elapsed > const Duration(seconds: 45)) {
          throw TimeoutException('Parent did not release $mode');
        }
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    }

    if (mode == 'hold') {
      final handle = await File(
        p.join(root.path, '.store.lock'),
      ).open(mode: FileMode.append);
      try {
        await handle.lock(FileLock.exclusive);
        await File('$signal.ready').writeAsString('locked');
        await waitForRelease();
        await handle.unlock();
      } finally {
        await handle.close();
      }
      return;
    }
    if (mode == 'replace-paths') {
      final store = FileLocalHistoryStore(rootDirectory: () async => root);
      final snapshot = await store.load();
      final oldDelete = snapshot.documents.singleWhere(
        (document) =>
            document.currentPath == '/workspace/reconcile-d.md' &&
            !document.deleted,
      );
      await store.clearDocument(oldDelete.id);
      for (final path in [
        '/workspace/reconcile-b.md',
        '/workspace/reconcile-d.md',
      ]) {
        await store.capture(
          LocalHistoryCaptureRequest(
            path: path,
            displayName: p.basename(path),
            source: 'replacement $path',
            format: TextFormatMetadata.utf8Lf,
            capturedAt: DateTime.utc(2026, 1, 2),
            reason: LocalHistoryCaptureReason.saved,
          ),
          const LocalHistoryPolicy(),
        );
      }
      final replaced = await store.load();
      await File('$signal.result').writeAsString(
        replaced.documents
            .where(
              (document) =>
                  document.currentPath == '/workspace/reconcile-b.md' ||
                  document.currentPath == '/workspace/reconcile-d.md',
            )
            .map((document) => document.id)
            .join('\n'),
      );
      await File('$signal.ready').writeAsString('replaced');
      await waitForRelease();
      return;
    }
    final owner = Platform.environment['BUSYMARK_HISTORY_PROCESS_OWNER']!;
    final store = FileLocalHistoryStore(rootDirectory: () async => root);
    if (mode == 'recapture-id') {
      await store.capture(
        LocalHistoryCaptureRequest(
          documentId: owner,
          path: '/workspace/reconcile-same-id.md',
          displayName: 'reconcile-same-id.md',
          source: 'replacement under reused identity',
          format: TextFormatMetadata.utf8Lf,
          capturedAt: DateTime.utc(2026, 1, 3),
          reason: LocalHistoryCaptureReason.saved,
        ),
        const LocalHistoryPolicy(),
      );
      await File('$signal.ready').writeAsString('recaptured');
      await waitForRelease();
      return;
    }
    await File('$signal.ready').writeAsString('ready');
    await waitForRelease();
    String? documentId;
    for (var index = 0; index < 8; index++) {
      final result = await store.capture(
        LocalHistoryCaptureRequest(
          documentId: documentId,
          path: '/workspace/$owner.md',
          displayName: '$owner.md',
          source: '$owner revision $index',
          format: TextFormatMetadata.utf8Lf,
          capturedAt: DateTime.utc(2026, 1, 1, 0, index),
          reason: LocalHistoryCaptureReason.saved,
        ),
        const LocalHistoryPolicy(),
      );
      documentId = result.document.id;
      await File('$signal.progress').writeAsString('${index + 1}');
    }
    expect((await store.load()).revisionsFor(documentId!), hasLength(8));
  }, timeout: const Timeout(Duration(seconds: 60)));
}
