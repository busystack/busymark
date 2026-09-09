import 'dart:convert';
import 'dart:io';

import 'package:busymark/src/local_history/local_history_models.dart';
import 'package:busymark/src/local_history/local_history_store.dart';
import 'package:busymark/src/workspace/text_format_metadata.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late int ids;
  late FileLocalHistoryStore store;

  setUp(() async {
    root = await Directory.systemTemp.createTemp(
      'busymark-local-history-test-',
    );
    ids = 0;
    store = FileLocalHistoryStore(
      rootDirectory: () async => root,
      createId: () => 'identity_${(++ids).toString().padLeft(12, '0')}',
    );
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  LocalHistoryCaptureRequest request(
    String source,
    DateTime time, {
    String path = '/workspace/guide.md',
    LocalHistoryCaptureReason reason = LocalHistoryCaptureReason.saved,
    bool force = false,
  }) => LocalHistoryCaptureRequest(
    path: path,
    displayName: p.basename(path),
    source: source,
    format: TextFormatMetadata.utf8Lf,
    capturedAt: time,
    reason: reason,
    force: force,
  );

  const policy = LocalHistoryPolicy(
    retentionAge: Duration(days: 30),
    maximumBytes: 16 * 1024 * 1024,
  );

  test(
    'persists full revisions and stable document identity across restart',
    () async {
      final time = DateTime.utc(2026, 1, 1);
      final first = await store.capture(request('A', time), policy);
      final second = await store.capture(
        request('B', time.add(const Duration(minutes: 1))),
        policy,
      );
      final reopened = FileLocalHistoryStore(rootDirectory: () async => root);
      final snapshot = await reopened.load();

      expect(snapshot.documents, hasLength(1));
      expect(snapshot.documents.single.id, first.document.id);
      expect(second.document.id, first.document.id);
      expect(snapshot.revisions, hasLength(2));
      expect((await reopened.readRevision(second.revision!.id))!.source, 'B');
    },
  );

  test(
    'deduplicates only adjacent ordinary captures and preserves A-B-A',
    () async {
      final time = DateTime.utc(2026, 1, 1);
      final a = await store.capture(request('A', time), policy);
      final duplicate = await store.capture(
        request('A', time.add(const Duration(seconds: 1))),
        policy,
      );
      await store.capture(
        request('B', time.add(const Duration(seconds: 2))),
        policy,
      );
      await store.capture(
        request('A', time.add(const Duration(seconds: 3))),
        policy,
      );

      expect(duplicate.deduplicated, isTrue);
      expect(duplicate.revision!.id, a.revision!.id);
      expect((await store.load()).revisions, hasLength(3));
    },
  );

  test('forced protective capture preserves an identical revision', () async {
    final time = DateTime.utc(2026, 1, 1);
    await store.capture(request('same', time), policy);
    await store.capture(
      request(
        'same',
        time.add(const Duration(seconds: 1)),
        reason: LocalHistoryCaptureReason.beforeRestore,
        force: true,
      ),
      policy,
    );
    expect((await store.load()).revisions, hasLength(2));
  });

  test(
    'repairs a damaged index from intact independently checksummed records',
    () async {
      final result = await store.capture(
        request('recover me', DateTime.utc(2026, 1, 1)),
        policy,
      );
      await File(p.join(root.path, 'index.json')).writeAsString('{damaged');

      final snapshot = await store.load();

      expect(snapshot.warning, isNotNull);
      expect(snapshot.revisions.single.id, result.revision!.id);
      expect(
        (await store.readRevision(result.revision!.id))!.source,
        'recover me',
      );
    },
  );

  test(
    'repair rejects a record associated with a different document',
    () async {
      final result = await store.capture(
        request('unaltered source', DateTime.utc(2026, 1, 1)),
        policy,
      );
      final revisionFile = File(
        p.join(
          root.path,
          'revisions',
          result.document.id,
          '${result.revision!.id}.json',
        ),
      );
      final record = (jsonDecode(await revisionFile.readAsString()) as Map)
          .cast<String, Object?>();
      final revision = (record['revision'] as Map).cast<String, Object?>();
      revision['documentId'] = 'identity_999999999999';
      record['revision'] = revision;
      await revisionFile.writeAsString(jsonEncode(record));
      await File(p.join(root.path, 'index.json')).writeAsString('{damaged');

      final snapshot = await store.load();

      expect(snapshot.documents, isEmpty);
      expect(snapshot.revisions, isEmpty);
    },
  );

  test(
    'does not resurrect explicitly cleared revisions during repair',
    () async {
      final result = await store.capture(
        request('remove me', DateTime.utc(2026, 1, 1)),
        policy,
      );
      final revisionFile = File(
        p.join(
          root.path,
          'revisions',
          result.document.id,
          '${result.revision!.id}.json',
        ),
      );
      final retainedBytes = await revisionFile.readAsBytes();
      await store.clearDocument(result.document.id);
      await revisionFile.parent.create(recursive: true);
      await revisionFile.writeAsBytes(retainedBytes);
      await File(p.join(root.path, 'index.json')).writeAsString('{damaged');

      final snapshot = await store.load();
      expect(snapshot.revisions, isEmpty);
      expect(snapshot.documents, isEmpty);
    },
  );

  test('rejects an unknown future index format without rewriting it', () async {
    final file = File(p.join(root.path, 'index.json'));
    await file.writeAsString(jsonEncode({'version': 999}));

    await expectLater(
      store.load(),
      throwsA(isA<UnsupportedLocalHistoryFormat>()),
    );
    expect(jsonDecode(await file.readAsString()), {'version': 999});
  });

  test(
    'age retention uses the injected capture time deterministically',
    () async {
      final old = DateTime.utc(2020, 1, 1);
      await store.capture(request('old', old), policy);
      await store.capture(
        request('new', old.add(const Duration(days: 31))),
        policy,
      );

      final revisions = (await store.load()).revisions;
      expect(revisions, hasLength(1));
      expect((await store.readRevision(revisions.single.id))!.source, 'new');
    },
  );

  test('age retention is enforced when an idle store is reopened', () async {
    await store.capture(request('expired', DateTime.utc(2020, 1, 1)), policy);

    await store.prune(policy, DateTime.utc(2020, 2, 1));

    final snapshot = await store.load();
    expect(snapshot.revisions, isEmpty);
    expect(snapshot.documents, isEmpty);
  });

  test(
    'rename, directory move, delete, and per-document clearing retain lineage',
    () async {
      final result = await store.capture(
        request('text', DateTime.utc(2026, 1, 1), path: '/old/docs/a.md'),
        policy,
      );
      await store.remapPath('/old', '/new');
      var document = (await store.load()).documents.single;
      expect(document.currentPath, '/new/docs/a.md');
      expect(document.historicalPaths, contains('/old/docs/a.md'));
      await store.markDeleted('/new/docs', recursive: true);
      document = (await store.load()).documents.single;
      expect(document.deleted, isTrue);
      await store.clearDocument(result.document.id);
      expect((await store.load()).documents, isEmpty);
    },
  );

  test('ID-bound captures cannot implicitly move document paths', () async {
    final first = await store.capture(
      request('before move', DateTime.utc(2026, 1, 1), path: '/old/A.md'),
      policy,
    );
    await store.remapPath('/old/A.md', '/new/B.md');

    final lateCheckpoint = await store.capture(
      LocalHistoryCaptureRequest(
        documentId: first.document.id,
        path: '/old/A.md',
        displayName: 'A.md',
        source: 'edit queued before remap completed',
        format: TextFormatMetadata.utf8Lf,
        capturedAt: DateTime.utc(2026, 1, 1, 0, 1),
        reason: LocalHistoryCaptureReason.automaticCheckpoint,
      ),
      policy,
    );

    final snapshot = await store.load();
    expect(snapshot.documents, hasLength(1));
    expect(snapshot.documents.single.currentPath, '/new/B.md');
    expect(lateCheckpoint.document.currentPath, '/new/B.md');
    expect(lateCheckpoint.revision!.historicalPath, '/new/B.md');
  });

  test('serializes concurrent captures without losing index entries', () async {
    final time = DateTime.utc(2026, 1, 1);
    await Future.wait([
      for (var index = 0; index < 12; index++)
        store.capture(
          request('version $index', time.add(Duration(seconds: index))),
          policy,
        ),
    ]);
    expect((await store.load()).revisions, hasLength(12));
  });

  test('oversized capture cannot evict the previous revision', () async {
    final smallPolicy = LocalHistoryPolicy(
      maximumBytes: 16 * 1024 * 1024,
      retentionAge: const Duration(days: 30),
    );
    await store.capture(request('safe', DateTime.utc(2026, 1, 1)), smallPolicy);
    final huge = List.filled(17 * 1024 * 1024, 65);

    await expectLater(
      store.capture(
        request(utf8.decode(huge), DateTime.utc(2026, 1, 2)),
        smallPolicy,
      ),
      throwsA(isA<LocalHistoryStorageException>()),
    );
    final revision = (await store.load()).revisions.single;
    expect((await store.readRevision(revision.id))!.source, 'safe');
  });

  test(
    'different paths with the same basename keep separate identities',
    () async {
      final time = DateTime.utc(2026, 1, 1);
      final first = await store.capture(
        request('first', time, path: '/one/readme.md'),
        policy,
      );
      final second = await store.capture(
        request('second', time, path: '/two/readme.md'),
        policy,
      );

      expect(first.document.id, isNot(second.document.id));
      expect((await store.load()).documents, hasLength(2));
    },
  );

  test('an intentional empty revision after content is retained', () async {
    final time = DateTime.utc(2026, 1, 1);
    await store.capture(request('content', time), policy);
    final emptied = await store.capture(
      request('', time.add(const Duration(seconds: 1))),
      policy,
    );

    expect((await store.load()).revisions, hasLength(2));
    expect((await store.readRevision(emptied.revision!.id))!.source, isEmpty);
  });

  test(
    'missing and corrupt revision records do not damage intact entries',
    () async {
      final time = DateTime.utc(2026, 1, 1);
      final first = await store.capture(request('first', time), policy);
      final second = await store.capture(
        request('second', time.add(const Duration(seconds: 1))),
        policy,
      );
      final firstFile = File(
        p.join(
          root.path,
          'revisions',
          first.document.id,
          '${first.revision!.id}.json',
        ),
      );
      await firstFile.delete();
      final secondFile = File(
        p.join(
          root.path,
          'revisions',
          second.document.id,
          '${second.revision!.id}.json',
        ),
      );
      await secondFile.writeAsString('{corrupt');

      expect(await store.readRevision(first.revision!.id), isNull);
      expect(await store.readRevision(second.revision!.id), isNull);
      expect((await store.load()).documents, hasLength(1));
    },
  );

  test(
    'incomplete staging artifacts are never discovered as revisions',
    () async {
      await store.capture(
        request('complete', DateTime.utc(2026, 1, 1)),
        policy,
      );
      final artifact = File(
        p.join(
          root.path,
          'revisions',
          'escaped_identity',
          'partial.json.staging',
        ),
      );
      await artifact.parent.create(recursive: true);
      await artifact.writeAsString('{"source":"partial"}');
      await File(p.join(root.path, 'index.json')).writeAsString('{damaged');

      final repaired = await store.load();
      expect(repaired.revisions, hasLength(1));
      expect(
        (await store.readRevision(repaired.revisions.single.id))!.source,
        'complete',
      );
    },
  );

  test('global clear tombstones prevent repair resurrection', () async {
    final result = await store.capture(
      request('remove globally', DateTime.utc(2026, 1, 1)),
      policy,
    );
    final revisionFile = File(
      p.join(
        root.path,
        'revisions',
        result.document.id,
        '${result.revision!.id}.json',
      ),
    );
    final retainedBytes = await revisionFile.readAsBytes();
    await store.clearAll();
    await revisionFile.parent.create(recursive: true);
    await revisionFile.writeAsBytes(retainedBytes);
    await File(p.join(root.path, 'index.json')).writeAsString('{damaged');

    final repaired = await store.load();
    expect(repaired.documents, isEmpty);
    expect(repaired.revisions, isEmpty);
  });

  test(
    'multiple store instances coordinate concurrent index publication',
    () async {
      var sharedIds = 1000;
      String createSharedId() =>
          'shared_${(++sharedIds).toString().padLeft(12, '0')}';
      final firstStore = FileLocalHistoryStore(
        rootDirectory: () async => root,
        createId: createSharedId,
      );
      final secondStore = FileLocalHistoryStore(
        rootDirectory: () async => root,
        createId: createSharedId,
      );
      final time = DateTime.utc(2026, 1, 1);

      await Future.wait([
        firstStore.capture(request('one', time, path: '/one.md'), policy),
        secondStore.capture(request('two', time, path: '/two.md'), policy),
      ]);

      final snapshot = await firstStore.load();
      expect(snapshot.documents, hasLength(2));
      expect(snapshot.revisions, hasLength(2));
    },
  );

  test(
    'storage permission failures surface without touching document data',
    () async {
      final unavailable = FileLocalHistoryStore(
        rootDirectory: () async =>
            throw const FileSystemException('permission denied'),
      );

      await expectLater(
        unavailable.capture(
          request('never stored', DateTime.utc(2026, 1, 1)),
          policy,
        ),
        throwsA(isA<FileSystemException>()),
      );
      expect((await store.load()).revisions, isEmpty);
    },
  );

  test('path exclusions use injected Windows path semantics', () {
    final windows = p.Context(style: p.Style.windows, current: r'C:\workspace');
    final windowsPolicy = LocalHistoryPolicy(
      excludedPaths: const [r'C:\workspace\private'],
      pathContext: windows,
    );

    expect(windowsPolicy.excludes(r'c:\WORKSPACE\PRIVATE\secret.md'), isTrue);
    expect(windowsPolicy.excludes(r'C:\workspace\public\guide.md'), isFalse);
  });
}
