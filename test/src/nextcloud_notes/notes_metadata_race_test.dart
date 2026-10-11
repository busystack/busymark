import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:busymark/src/nextcloud_notes/application/notes_repository.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_api_client.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_store.dart';
import 'package:busymark/src/nextcloud_notes/domain/notes_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'notes_api_test.dart' show testAccount, serverNote;

class _RaceFixture {
  _RaceFixture(this.draft);
  final bool draft;
  late Directory directory;
  late NotesRepository repository;
  DateTime now = DateTime.utc(2026, 10, 10);
  final started = Completer<Map<String, dynamic>>();
  final release = Completer<int>();
  final writes = <Map<String, dynamic>>[];
  Map<String, Object?>? remote;
  late final transport = MockClient((request) async {
    const root = '/nextcloud/index.php/apps/notes/api/v1/notes';
    expect(request.headers['authorization'], startsWith('Basic '));
    if (request.method == 'GET') {
      expect(request.url.path, anyOf(root, '$root/1'));
      return http.Response(
        jsonEncode(
          request.url.path == root ? [if (remote != null) remote] : remote,
        ),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }
    final creating = request.method == 'POST';
    expect(request.method, creating ? 'POST' : 'PUT');
    expect(request.url.path, creating ? root : '$root/1');
    expect(
      request.headers['if-match'],
      creating ? isNull : '"${remote!['etag']}"',
    );
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    expect(
      body.keys,
      unorderedEquals(['content', 'title', 'category', 'favorite', 'modified']),
    );
    expect(body['content'], 'body');
    expect(body['category'], '');
    expect(body['favorite'], false);
    expect(body['modified'], now.millisecondsSinceEpoch ~/ 1000);
    writes.add(body);
    if (!started.isCompleted) {
      started.complete(body);
      final status = await release.future;
      if (status != 200) {
        return http.Response(
          '{}',
          status,
          headers: {if (status == 429) 'Retry-After': '10'},
        );
      }
    }
    remote = {
      ...serverNote(1),
      ...body,
      'id': 1,
      'etag': 'written-${writes.length}',
    };
    return http.Response(
      jsonEncode(remote),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });

  Future<void> open() async {
    repository = NotesRepository(
      store: await NotesStore.open(path: '${directory.path}/notes.sqlite3'),
      clock: () => now,
      clientForAccount: (a) async => NotesApiClient(
        client: transport,
        account: a,
        appPassword: 'fixture',
        clock: () => now,
      ),
    );
    await repository.initialize();
    if (repository.accounts.isEmpty) {
      await repository.upsertAccount(testAccount());
    }
  }

  Future<void> restart() async {
    await repository.dispose();
    await open();
  }

  Future<String> seed() async {
    if (draft) {
      return (await repository.create(
        testAccount().id,
        title: 'A',
        content: 'body',
      )).localId;
    }
    remote = {...serverNote(1), 'title': 'A', 'category': ''};
    await repository.synchronize(testAccount().id, allowWrites: false);
    return repository.notes.single.localId;
  }
}

void main() {
  for (final state in [NoteSyncState.pending, NoteSyncState.synced]) {
    test(
      'durable metadata evidence independently blocks $state after restart',
      () async {
        final f = _RaceFixture(false);
        f.directory = await Directory.systemTemp.createTemp(
          'notes-metadata-evidence-',
        );
        await f.open();
        addTearDown(() async {
          await f.repository.dispose();
          f.transport.close();
          await f.directory.delete(recursive: true);
        });
        final id = await f.seed();
        final snapshot = f.repository.metadataSnapshot(id);
        await f.repository.patchMetadata(snapshot, title: 'B');
        await f.repository.patchMetadata(snapshot, title: 'C');
        final conflicted = f.repository.noteById(id)!;
        // Reproduce older transitions without inventing another server observation.
        await f.repository.store.saveNote(
          conflicted.copyWith(
            syncState: state,
            ackRevision: conflicted.revision,
            retryCount: 1,
            failureCode: NotesFailureCode.server,
          ),
        );
        await f.restart();
        expect(f.repository.noteById(id)!.hasPendingChanges, isTrue);
        expect(f.repository.hasRetryableWork(testAccount().id), isFalse);
        await f.repository.retryWrites(testAccount().id);
        await f.repository.synchronize(testAccount().id);
        expect(f.writes, isEmpty);
        expect(f.repository.noteById(id)!.title, 'C');
        expect(
          f.repository.noteById(id)!.metadataConflict!.alternative.title,
          'B',
        );
        expect(
          (await f.repository.store.notes())
              .single
              .metadataConflict!
              .alternative
              .title,
          'B',
        );
      },
    );
  }

  for (final draft in [false, true]) {
    for (final status in [200, 429, 503]) {
      for (final choice in [
        NoteConflictResolution.takeRemote,
        NoteConflictResolution.keepLocal,
      ]) {
        test(
          'held ${draft ? 'POST' : 'PUT'} $status cannot publish B/C before $choice, including restart',
          () async {
            final f = _RaceFixture(draft);
            f.directory = await Directory.systemTemp.createTemp(
              'notes-metadata-race-',
            );
            await f.open();
            Future<void>? sending;
            addTearDown(() async {
              if (!f.release.isCompleted) f.release.complete(status);
              await sending;
              await f.repository.dispose();
              f.transport.close();
              await f.directory.delete(recursive: true);
            });
            final id = await f.seed();
            final snapshot = f.repository.metadataSnapshot(id);
            await f.repository.patchMetadata(snapshot, title: 'B');
            final sentRevision = f.repository.noteById(id)!.revision;
            final previousAck = f.repository.noteById(id)!.ackRevision;
            final previousBase = f.repository.noteById(id)!.base;
            sending = f.repository.synchronize(testAccount().id);
            expect(
              (await Future.any([
                f.started.future,
                sending.then<Map<String, dynamic>>(
                  (_) => throw StateError('No held request'),
                ),
              ]))['title'],
              'B',
            );
            final recordedAttempt = f.repository.noteById(id)!.creationAttempt;
            await f.repository.patchMetadata(snapshot, title: 'C');
            final conflicted = f.repository.noteById(id)!;
            expect(conflicted.metadataConflict!.alternative.title, 'B');
            f.release.complete(status);
            await sending;
            final uncertain = draft && status == 503;
            final settled = f.repository.noteById(id)!;
            expect(settled.revision, conflicted.revision);
            expect(
              settled.ackRevision,
              status == 200 ? sentRevision : previousAck,
            );
            expect(settled.title, 'C');
            expect(settled.metadataConflict!.alternative.title, 'B');
            expect(
              settled.base?.title,
              status == 200 ? 'B' : previousBase?.title,
            );
            expect(
              settled.base?.etag,
              status == 200 ? 'written-1' : previousBase?.etag,
            );
            expect(
              settled.syncState,
              uncertain
                  ? NoteSyncState.creationUncertain
                  : NoteSyncState.conflict,
            );
            expect(f.repository.hasRetryableWork(testAccount().id), isFalse);
            expect(f.writes.map((w) => w['title']), ['B']);
            if (uncertain) {
              expect(
                settled.creationAttempt!.wireBody,
                recordedAttempt!.wireBody,
              );
            }
            // Retry deadlines expire, but unresolved metadata still blocks every pass.
            f.now = f.now.add(const Duration(minutes: 1));
            await f.repository.synchronize(testAccount().id);
            await f.restart();
            await f.repository.synchronize(testAccount().id);
            expect(f.writes.map((w) => w['title']), ['B']);
            expect(
              f.repository.noteById(id)!.ackRevision,
              status == 200 ? sentRevision : previousAck,
            );
            expect(
              f.repository.noteById(id)!.syncState,
              uncertain
                  ? NoteSyncState.creationUncertain
                  : NoteSyncState.conflict,
            );
            expect(f.repository.noteById(id)!.title, 'C');
            expect(
              f.repository.noteById(id)!.metadataConflict!.alternative.title,
              'B',
            );
            await f.repository.resolveConflict(id, choice);
            final chosen = choice == NoteConflictResolution.takeRemote
                ? 'B'
                : 'C';
            expect(f.repository.noteById(id)!.title, chosen);
            await f.repository.synchronize(testAccount().id);
            if (uncertain) {
              // A metadata decision cannot establish the outcome of a possibly
              // executed POST. Explicit creation recovery is a separate decision.
              expect(f.writes.length, 1);
              expect(
                f.repository.noteById(id)!.syncState,
                NoteSyncState.creationUncertain,
              );
              expect(
                f.repository.noteById(id)!.creationAttempt!.wireBody,
                recordedAttempt!.wireBody,
              );
              final recovered = await f.repository.recoverAsNew(
                id,
                creationDecision: true,
              );
              await f.repository.synchronize(testAccount().id);
              expect(f.repository.noteById(recovered.localId)!.title, chosen);
              expect(
                f.repository.noteById(id)!.syncState,
                NoteSyncState.creationUncertain,
              );
            } else {
              expect(
                f.repository.noteById(id)!.syncState,
                NoteSyncState.synced,
              );
              expect(f.repository.noteById(id)!.metadataConflict, isNull);
            }
            expect(f.remote!['title'], chosen);
            expect(f.writes.last['title'], chosen);
          },
        );
      }
    }
  }
}
