// Reproducible real SQLite corpus. Run with `dart build cli` for AOT timing.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_store.dart';
import 'package:busymark/src/nextcloud_notes/application/notes_repository.dart';
import 'package:busymark/src/nextcloud_notes/domain/notes_models.dart';
import 'package:busymark/src/nextcloud_notes/application/notes_search_controller.dart';

Future<void> main(List<String> args) async {
  if (args.length != 1) throw ArgumentError('Pass a private output directory.');
  final root = await Directory(args.single).create(recursive: true);
  final path = '${root.path}/performance.sqlite3';
  if (await File(path).exists()) {
    throw StateError('Use an empty output directory.');
  }
  final store = await NotesStore.open(path: path);
  const uuid = Uuid();
  final accountId = uuid.v4();
  await store.saveAccount(
    NextcloudAccount(
      id: accountId,
      server: Uri.parse('https://benchmark.invalid'),
      loginName: 'corpus',
      appVersion: '6.1.0',
    ),
  );
  final beforeRss = ProcessInfo.currentRss;
  var corpusBytes = 0, mediaBytes = 0;
  final notes = <NextcloudNote>[];
  final seed = Stopwatch()..start();
  for (var batch = 0; batch < 10000; batch += 32) {
    final group = <NextcloudNote>[];
    for (var i = batch; i < batch + 32 && i < 10000; i++) {
      final source = List.generate(
        14,
        (line) =>
            'Row $line: café cafe\u0301 中文 日本語 Привет مرحبا 한국어 Ελληνικά. foo_bar C++ x.y 100% independent alpha beta. record-$i token${i % 97}.',
      ).join('\n');
      final note = NextcloudNote(
        localId: uuid.v4(),
        accountId: accountId,
        serverId: i + 1,
        title: 'Duplicate ${i % 250}',
        category: i % 10 == 0 ? '' : 'Area ${i % 20}/Group ${i % 71}/子',
        content: i % 5 == 0
            ? '$source\n![media](.attachments.${i + 1}/café%2520.png)'
            : source,
        revision: 1,
        ackRevision: 1,
        localActivityMicros: 1700000000000000 + i,
        syncState: NoteSyncState.synced,
      );
      corpusBytes += utf8.encode(note.content).length;
      group.add(note);
      notes.add(note);
    }
    await store.commit(notes: group);
  }
  for (final note in notes.where((n) => n.serverId! % 5 == 1)) {
    final bytes = Uint8List(2048);
    await store.saveAttachment(
      NotesAttachment(
        id: uuid.v4(),
        noteId: note.localId,
        filename: 'café%20.png',
        reference: '.attachments.${note.serverId}/café%2520.png',
        remotePath: '.attachments.${note.serverId}/café%20.png',
        state: 'cached',
      ),
      bytes,
    );
    mediaBytes += bytes.length;
  }
  seed.stop();
  await store.rebuildIndex();
  final index = Stopwatch()..start();
  while (await store.indexStep() != 0) {}
  index.stop();
  final search = NotesSearchController(store, accountId);
  final queries = [
    'token42',
    '"alpha beta" category:"Area 7"',
    '中文',
    'C++',
    'é',
  ];
  final latencies = <String, List<double>>{};
  for (final query in queries) {
    await search.search(query);
    if (search.state.error != null || search.state.hits.isEmpty) {
      throw StateError('Corpus query failed.');
    }
    final times = <double>[];
    for (var i = 0; i < 10; i++) {
      final watch = Stopwatch()..start();
      await search.search(query);
      watch.stop();
      times.add(watch.elapsedMicroseconds / 1000);
    }
    times.sort();
    latencies[query] = times;
  }
  await store.rebuildIndex();
  final saves = <double>[];
  final building = () async {
    while (await store.indexStep() != 0) {}
  }();
  for (var i = 0; i < 40; i++) {
    final watch = Stopwatch()..start();
    final note = notes[i].copyWith(
      content: '${notes[i].content}\nedit $i',
      revision: 2,
    );
    await store.saveNote(note);
    watch.stop();
    saves.add(watch.elapsedMicroseconds / 1000);
    await Future<void>.delayed(Duration.zero);
  }
  await building;
  saves.sort();
  final querying = search.search('nothing-matches-this-corpus');
  final duringQuery = Stopwatch()..start();
  await store.saveNote(
    notes[0].copyWith(content: 'edited during a short-query scan', revision: 3),
  );
  duringQuery.stop();
  await querying;
  final repository = NotesRepository(
    store: store,
    clientForAccount: (_) async => throw StateError('Offline benchmark'),
  );
  await repository.initialize();
  final importTimes = <double>[];
  final queryingImports = search.search('é', limit: 2000);
  for (var i = 0; i < 20; i++) {
    final watch = Stopwatch()..start();
    await repository.importLocal(
      accountId: accountId,
      sourceKey: 'benchmark:$i',
      title: 'Imported $i',
      category: 'Import/子',
      content: notes[i].content,
      media: {},
    );
    watch.stop();
    importTimes.add(watch.elapsedMicroseconds / 1000);
  }
  await queryingImports;
  importTimes.sort();
  final report = {
    'count': 10000,
    'categories': notes.map((n) => n.category).toSet().length,
    'duplicateTitleCount': 250,
    'corpusUtf8Bytes': corpusBytes,
    'attachmentCount': 2000,
    'attachmentBytes': mediaBytes,
    'sqlite': sqlite3.version.libVersion,
    'dart': Platform.version,
    'os': Platform.operatingSystemVersion,
    'processors': Platform.numberOfProcessors,
    'aot': const bool.fromEnvironment('dart.vm.product'),
    'seedAndIndexMilliseconds': seed.elapsedMilliseconds,
    'initialRebuildMilliseconds': index.elapsedMilliseconds,
    'warmSearchMilliseconds': {
      for (final entry in latencies.entries)
        entry.key: {'median': entry.value[5], 'p95': entry.value[9]},
    },
    'saveDuringRebuildMilliseconds': {
      'median': saves[20],
      'p95': saves[38],
      'maximum': saves.last,
    },
    'saveDuringQueryMilliseconds': duringQuery.elapsedMicroseconds / 1000,
    'importDuringSearchMilliseconds': {
      'median': importTimes[10],
      'p95': importTimes[19],
    },
    'rssBeforeBytes': beforeRss,
    'rssAfterBytes': ProcessInfo.currentRss,
    'maximumRssBytes': ProcessInfo.maxRss,
    'databaseBytes': await File(path).length(),
  };
  await File(
    '${root.path}/report.json',
  ).writeAsString(const JsonEncoder.withIndent('  ').convert(report));
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(report));
  await search.dispose();
  await repository.dispose();
}
