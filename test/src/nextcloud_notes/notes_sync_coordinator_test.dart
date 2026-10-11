import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:busymark/src/nextcloud_notes/application/notes_repository.dart';
import 'package:busymark/src/nextcloud_notes/application/notes_sync_coordinator.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_api_client.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_store.dart';
import 'package:busymark/src/nextcloud_notes/domain/notes_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'notes_api_test.dart' show testAccount, serverNote;

class _Task implements NotesScheduledTask {
  _Task(this.deadline, this.callback);
  final DateTime deadline;
  final void Function() callback;
  bool cancelled = false;
  @override
  void cancel() => cancelled = true;
}

class _Timers {
  DateTime now = DateTime.utc(2026, 9, 1);
  final tasks = <_Task>[];
  NotesScheduledTask schedule(Duration delay, void Function() callback) {
    final task = _Task(now.add(delay), callback);
    tasks.add(task);
    return task;
  }

  void advance(Duration duration) {
    now = now.add(duration);
    final ready = tasks
        .where((t) => !t.cancelled && !t.deadline.isAfter(now))
        .toList();
    for (final task in ready) {
      task.cancelled = true;
      task.callback();
    }
    tasks.removeWhere((t) => t.cancelled);
  }
}

void main() {
  late Directory directory;
  late _Timers timers;
  NotesRepository? repository;
  NotesSyncCoordinator? coordinator;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('notes-scheduler-');
    timers = _Timers();
  });
  tearDown(() async {
    coordinator?.dispose();
    await repository?.dispose();
    repository = null;
    coordinator = null;
    await directory.delete(recursive: true);
  });
  Future<NotesSyncCoordinator> open(http.Client transport) async {
    final r = NotesRepository(
      store: await NotesStore.open(path: '${directory.path}/notes.sqlite3'),
      clock: () => timers.now,
      clientForAccount: (a) async => NotesApiClient(
        client: transport,
        account: a,
        appPassword: 'fixture',
        clock: () => timers.now,
      ),
    );
    await r.initialize();
    await r.upsertAccount(testAccount());
    repository = r;
    final c = NotesSyncCoordinator(
      r,
      clock: () => timers.now,
      schedule: timers.schedule,
    );
    c.setActiveAccount(testAccount().id);
    coordinator = c;
    return c;
  }

  Future<void> advance(NotesSyncCoordinator c, Duration duration) async {
    timers.advance(duration);
    await c.request(NotesSyncTrigger.focus);
  }

  test(
    'healthy read publishes fresh durable work without releasing exhausted writes',
    () async {
      var puts = 0;
      var creates = 0;
      final c = await open(
        MockClient((request) async {
          expect(request.headers['authorization'], startsWith('Basic '));
          if (request.method == 'GET') {
            expect(
              request.url.path,
              '/nextcloud/index.php/apps/notes/api/v1/notes',
            );
            return http.Response(jsonEncode([serverNote(1)]), 200);
          }
          if (request.method == 'PUT') {
            expect(
              request.url.path,
              '/nextcloud/index.php/apps/notes/api/v1/notes/1',
            );
            puts++;
            return http.Response('{}', 423);
          }
          expect(request.method, 'POST');
          expect(
            request.url.path,
            '/nextcloud/index.php/apps/notes/api/v1/notes',
          );
          creates++;
          return http.Response(
            jsonEncode({...serverNote(2), ...jsonDecode(request.body) as Map}),
            200,
          );
        }),
      );
      await c.request(NotesSyncTrigger.opening);
      await repository!.save(
        repository!.notes.single.localId,
        content: 'locked edit',
      );
      for (var i = 0; i < 7; i++) {
        await repository!.synchronize(testAccount().id);
      }
      expect(puts, 7);
      final fresh = await repository!.create(
        testAccount().id,
        content: 'saved while screen inactive',
      );
      await c.request(NotesSyncTrigger.poll);
      expect(puts, 7);
      expect(creates, 1);
      expect(
        repository!.noteById(fresh.localId)!.syncState,
        NoteSyncState.synced,
      );
      expect(
        repository!.notes.firstWhere((n) => n.serverId == 1).retryCount,
        7,
      );
    },
  );

  test(
    'healthy idle discovery, visible focus, hidden suspension and disposal use controlled timers',
    () async {
      var gets = 0;
      var content = 'first';
      final c = await open(
        MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path.endsWith('/v1/notes'), isTrue);
          gets++;
          return http.Response(
            jsonEncode([serverNote(1, content: content, etag: 'etag-$gets')]),
            200,
          );
        }),
      );
      await c.request(NotesSyncTrigger.opening);
      expect(gets, 1);
      content = 'changed remotely';
      await advance(c, const Duration(seconds: 60));
      expect(repository!.notes.single.content, content);
      expect(gets, 2);
      c.focused();
      await c.request(NotesSyncTrigger.focus);
      expect(gets, 2);
      c.setVisible(false);
      await advance(c, const Duration(minutes: 10));
      expect(gets, 2);
      c.setVisible(true);
      await c.request(NotesSyncTrigger.focus);
      expect(gets, 3);
      c.setVisible(true);
      await advance(c, const Duration(seconds: 60));
      expect(gets, 4);
      c.dispose();
      timers.advance(const Duration(hours: 1));
      expect(gets, 4);
      expect(timers.tasks, isEmpty);
    },
  );

  test(
    'manual refresh awaits one coalesced followup when a local save arrives during GET',
    () async {
      final started = Completer<void>();
      final reply = Completer<void>();
      var gets = 0;
      var puts = 0;
      var delay = false;
      var remote = serverNote(1);
      final c = await open(
        MockClient((request) async {
          if (request.method == 'GET') {
            gets++;
            if (delay) {
              delay = false;
              started.complete();
              await reply.future;
            }
            return http.Response(jsonEncode([remote]), 200);
          }
          expect(request.method, 'PUT');
          puts++;
          remote = {
            ...remote,
            ...jsonDecode(request.body) as Map,
            'etag': 'written',
          };
          return http.Response(jsonEncode(remote), 200);
        }),
      );
      await c.request(NotesSyncTrigger.opening);
      delay = true;
      final manual = c.request(NotesSyncTrigger.manual);
      await started.future;
      await repository!.save(
        repository!.notes.single.localId,
        content: 'saved during GET',
      );
      final followup = c.request(NotesSyncTrigger.localChange);
      c.focused();
      var completed = false;
      unawaited(
        manual.then((_) {
          completed = true;
        }),
      );
      expect(completed, isFalse);
      reply.complete();
      await Future.wait([manual, followup]);
      expect(completed, isTrue);
      expect(gets, 3);
      expect(puts, 1);
      expect(repository!.notes.single.syncState, NoteSyncState.synced);
    },
  );

  test(
    'six locked write retries exhaust; healthy reads and focus do not replenish the budget',
    () async {
      var puts = 0;
      final c = await open(
        MockClient((request) async {
          if (request.method == 'GET') {
            return http.Response(jsonEncode([serverNote(1)]), 200);
          }
          expect(request.method, 'PUT');
          puts++;
          return http.Response('{}', 423);
        }),
      );
      await c.request(NotesSyncTrigger.opening);
      await repository!.save(
        repository!.notes.single.localId,
        content: 'locked local edit',
      );
      await c.request(NotesSyncTrigger.localChange);
      for (final seconds in NotesSyncCoordinator.retryIntervals) {
        await advance(c, Duration(seconds: seconds));
      }
      expect(puts, 7);
      expect(repository!.notes.single.retryCount, 7);
      for (var i = 0; i < 4; i++) {
        await advance(c, const Duration(minutes: 1));
      }
      expect(puts, 7);
      await c.request(NotesSyncTrigger.manual);
      expect(puts, 8);
    },
  );

  test(
    'throttling schedules at the server deadline, even beyond normal retry intervals',
    () async {
      var puts = 0;
      final c = await open(
        MockClient((request) async {
          if (request.method == 'GET') {
            return http.Response(jsonEncode([serverNote(1)]), 200);
          }
          puts++;
          return http.Response('{}', 429, headers: {'Retry-After': '3600'});
        }),
      );
      await c.request(NotesSyncTrigger.opening);
      await repository!.save(
        repository!.notes.single.localId,
        content: 'throttled',
      );
      await c.request(NotesSyncTrigger.localChange);
      for (var i = 0; i < 59; i++) {
        await advance(c, const Duration(minutes: 1));
      }
      expect(puts, 1);
      await advance(c, const Duration(minutes: 1));
      expect(puts, 2);
    },
  );

  test(
    'authenticated recovery reads restore network work but never retry uncertain creations',
    () async {
      var offline = false;
      var posts = 0;
      final c = await open(
        MockClient((request) async {
          if (offline) throw http.ClientException('fixture offline');
          if (request.method == 'GET') return http.Response('[]', 200);
          expect(request.method, 'POST');
          posts++;
          throw http.ClientException('fixture lost creation response');
        }),
      );
      await c.request(NotesSyncTrigger.opening);
      final draft = await repository!.create(
        testAccount().id,
        content: 'draft',
      );
      offline = true;
      await c.request(NotesSyncTrigger.localChange);
      expect(posts, 0);
      offline = false;
      await advance(c, const Duration(minutes: 1));
      expect(posts, 1);
      expect(
        repository!.noteById(draft.localId)!.syncState,
        NoteSyncState.creationUncertain,
      );
      await advance(c, const Duration(minutes: 1));
      await c.request(NotesSyncTrigger.manual);
      expect(posts, 1);
      c.removeAccount(testAccount().id);
      timers.advance(const Duration(hours: 1));
      expect(posts, 1);
    },
  );

  test(
    'edited throttled work keeps a deadline timer after restart while hidden',
    () async {
      var puts = 0;
      var remote = serverNote(1);
      final transport = MockClient((request) async {
        if (request.method == 'GET') {
          expect(request.url.path.endsWith('/v1/notes'), isTrue);
          return http.Response(jsonEncode([remote]), 200);
        }
        expect(request.method, 'PUT');
        expect(request.url.path.endsWith('/v1/notes/1'), isTrue);
        puts++;
        if (puts == 1) {
          return http.Response('{}', 429, headers: {'Retry-After': '600'});
        }
        remote = {
          ...remote,
          ...jsonDecode(request.body) as Map,
          'etag': 'written',
        };
        return http.Response(jsonEncode(remote), 200);
      });
      var c = await open(transport);
      await c.request(NotesSyncTrigger.opening);
      final id = repository!.notes.single.localId;
      await repository!.save(id, content: 'first edit');
      await c.request(NotesSyncTrigger.localChange);
      await repository!.patchMetadata(
        repository!.metadataSnapshot(id),
        title: 'edited while throttled',
      );
      expect(repository!.noteById(id)!.retryCount, 0);
      await c.request(NotesSyncTrigger.localChange);
      expect(puts, 1);
      c.dispose();
      await repository!.dispose();
      c = await open(transport);
      c.setVisible(false);
      await c.request(NotesSyncTrigger.opening);
      expect(
        timers.tasks.where((t) => !t.cancelled).single.deadline,
        timers.now.add(const Duration(minutes: 10)),
      );
      timers.advance(const Duration(minutes: 9));
      expect(puts, 1);
      timers.advance(const Duration(minutes: 1));
      // Join the pass started by the deadline timer without making another trigger.
      await repository!.synchronize(testAccount().id);
      expect(puts, 2);
      expect(repository!.noteById(id)!.syncState, NoteSyncState.synced);
      expect(remote['title'], 'edited while throttled');
    },
  );
}
