// Compiled once and run by the selected official flutter_tester because the
// production store's dependency graph includes dart:ui. Each invocation is an
// independent OS process; no nested flutter test/tool startup is involved.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:busymark/src/local_history/local_history_models.dart';
import 'package:busymark/src/local_history/local_history_store.dart';
import 'package:busymark/src/workspace/text_format_metadata.dart';
import 'package:path/path.dart' as p;

Future<void> main() async {
  final rootPath = Platform.environment['BUSYMARK_HISTORY_PROCESS_ROOT'];
  if (rootPath == null) return;
  try {
    final root = Directory(rootPath);
    final signal = Platform.environment['BUSYMARK_HISTORY_PROCESS_SIGNAL']!;
    final mode = Platform.environment['BUSYMARK_HISTORY_PROCESS_MODE']!;
    final clock = Stopwatch()..start();
    Future<T> phase<T>(String name, Future<T> Function() operation) async {
      void trace(String status) => stderr.writeln(
        'HISTORY_FIXTURE ${jsonEncode({'pid': pid, 'phase': name, 'status': status, 'elapsedUs': clock.elapsedMicroseconds, 'wallUs': DateTime.now().microsecondsSinceEpoch})}',
      );
      trace('begin');
      try {
        return await operation();
      } finally {
        trace('end');
      }
    }

    stderr.writeln('HISTORY_FIXTURE runtime-entered pid=$pid');
    if (mode == 'fail-before-ready') {
      throw StateError('Controlled history process failure before readiness');
    }
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
        await phase('hold-lock', () => handle.lock(FileLock.exclusive));
        await File('$signal.ready').writeAsString('locked');
        await waitForRelease();
        await handle.unlock();
      } finally {
        await handle.close();
      }
      exit(0);
    }
    if (mode == 'replace-paths') {
      final store = FileLocalHistoryStore(rootDirectory: () async => root);
      final snapshot = await phase('replacement-load', store.load);
      final oldDelete = snapshot.documents.singleWhere(
        (document) =>
            document.currentPath == '/workspace/reconcile-d.md' &&
            !document.deleted,
      );
      await phase('replacement-clear', () => store.clearDocument(oldDelete.id));
      for (final path in [
        '/workspace/reconcile-b.md',
        '/workspace/reconcile-d.md',
      ]) {
        await phase(
          'replacement-capture-$path',
          () => store.capture(
            LocalHistoryCaptureRequest(
              path: path,
              displayName: p.basename(path),
              source: 'replacement $path',
              format: TextFormatMetadata.utf8Lf,
              capturedAt: DateTime.utc(2026, 1, 2),
              reason: LocalHistoryCaptureReason.saved,
            ),
            const LocalHistoryPolicy(),
          ),
        );
      }
      final replaced = await phase('replacement-reload', store.load);
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
      exit(0);
    }
    final owner = Platform.environment['BUSYMARK_HISTORY_PROCESS_OWNER']!;
    final store = FileLocalHistoryStore(rootDirectory: () async => root);
    if (mode == 'recapture-id') {
      await phase(
        'identity-recapture',
        () => store.capture(
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
        ),
      );
      await File('$signal.ready').writeAsString('recaptured');
      await waitForRelease();
      exit(0);
    }
    await File('$signal.ready').writeAsString('ready');
    await waitForRelease();
    String? documentId;
    for (var index = 0; index < 8; index++) {
      final result = await phase(
        'writer-capture-$index',
        () => store.capture(
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
        ),
      );
      documentId = result.document.id;
      await File('$signal.progress').writeAsString('${index + 1}');
    }
    final snapshot = await phase('writer-reload', store.load);
    if (snapshot.revisionsFor(documentId!).length != 8) {
      throw StateError('Expected eight production revisions for $documentId');
    }
    exit(0);
  } on Object catch (error, stack) {
    stderr.writeln('$error\n$stack');
    exit(1);
  }
}
