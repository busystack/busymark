import 'dart:async';
import 'dart:io';

import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/nextcloud_notes/application/nextcloud_connection.dart';
import 'package:busymark/src/nextcloud_notes/application/notes_repository.dart';
import 'package:busymark/src/nextcloud_notes/application/notes_sync_coordinator.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_secret_store.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_store.dart';
import 'package:busymark/src/nextcloud_notes/domain/notes_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqlite3/sqlite3.dart';

import 'notes_api_test.dart' show testAccount;

void main() {
  final account = testAccount();
  late Directory root;
  late String path;
  late NotesStore owner;
  late _Secrets secrets;
  late int revocations;
  late int revokeStatus;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('notes-disconnect-');
    path = '${root.path}/notes.sqlite';
    owner = await NotesStore.open(path: path);
    await owner.saveAccount(account);
    secrets = _Secrets();
    revocations = 0;
    revokeStatus = 200;
  });

  tearDown(() async {
    await owner.close();
    await root.delete(recursive: true);
  });

  Future<NextcloudConnectionController> connection() async {
    final container = ProviderContainer(
      overrides: [
        nextcloudNotesDatabasePathProvider.overrideWith((_) async => path),
        nextcloudSecretStoreProvider.overrideWithValue(secrets),
        nextcloudHttpClientProvider.overrideWithValue(
          MockClient((request) async {
            expect(request.method, 'DELETE');
            expect(request.url.path, endsWith('/core/apppassword'));
            revocations++;
            return http.Response('', revokeStatus);
          }),
        ),
        localSettingsStoreProvider.overrideWithValue(_Settings()),
      ],
    );
    final repository = await container.read(
      nextcloudNotesRepositoryProvider.future,
    );
    final controller = container.read(nextcloudConnectionProvider.notifier);
    await controller.reload();
    addTearDown(() async {
      container.dispose();
      await repository.dispose();
    });
    return controller;
  }

  test('stale disconnect leaves both credentials untouched', () async {
    final controller = await connection();
    await owner.saveAccount(account.copyWith(appVersion: '6.2.0'));
    expect(await controller.disconnect(), isFalse);
    expect(revocations, 0);
    expect(secrets.deletions, 0);
    expect(secrets.password, 'fixture');
    expect((await owner.accounts()).single.disconnectPending, isFalse);
    expect(controller.state.failure, isA<NotesException>());
  });

  test(
    'foreign ownership excludes disconnect and a later retry succeeds',
    () async {
      final controller = await connection();
      final acquired = Completer<void>(), release = Completer<void>();
      final held = owner.withRequestOwnership(account.id, () async {
        acquired.complete();
        await release.future;
      });
      await acquired.future;
      try {
        expect(await controller.disconnect(), isFalse);
        expect(revocations, 0);
        expect(secrets.deletions, 0);
      } finally {
        release.complete();
        await held;
      }
      expect(await controller.disconnect(), isTrue);
      expect(revocations, 1);
      expect(secrets.password, isNull);
      expect(await owner.accounts(), isEmpty);
      expect(controller.state.account, isNull);
    },
  );

  test(
    'failed credential deletion leaves durable disconnect state and retry',
    () async {
      final controller = await connection();
      secrets.failDeletion = true;
      expect(await controller.disconnect(), isFalse);
      expect(revocations, 1);
      expect(secrets.password, 'fixture');
      expect((await owner.accounts()).single.disconnectPending, isTrue);
      expect(
        controller.state.phase,
        NextcloudConnectionPhase.disconnectPending,
      );
      final reopened = await connection();
      expect(reopened.state.phase, NextcloudConnectionPhase.disconnectPending);
      expect(await reopened.reconnect(), isFalse);
      secrets.failDeletion = false;
      expect(await reopened.disconnect(), isTrue);
      expect(secrets.password, isNull);
      expect(await owner.accounts(), isEmpty);
    },
  );

  test(
    'database removal failure after revocation stays disconnected on retry',
    () async {
      final controller = await connection();
      final db = sqlite3.open(path);
      addTearDown(db.close);
      db.execute('''
      CREATE TRIGGER block_disconnect BEFORE DELETE ON accounts
      BEGIN SELECT RAISE(ABORT, 'test failure'); END
    ''');
      expect(await controller.disconnect(), isFalse);
      expect(revocations, 1);
      expect(secrets.password, isNull);
      expect(
        controller.state.phase,
        NextcloudConnectionPhase.disconnectPending,
      );
      final reopened = await connection();
      expect(reopened.state.phase, NextcloudConnectionPhase.disconnectPending);
      db.execute('DROP TRIGGER block_disconnect');
      expect(await reopened.disconnect(), isTrue);
      expect(revocations, 1);
      expect(await owner.accounts(), isEmpty);
    },
  );

  test(
    'failed remote revocation removes local state with the existing warning',
    () async {
      final controller = await connection();
      revokeStatus = 503;
      expect(await controller.disconnect(), isTrue);
      expect(controller.state.removedWithWarning, isTrue);
      expect(controller.state.account, isNull);
      expect(secrets.password, isNull);
      expect(await owner.accounts(), isEmpty);
    },
  );

  test(
    'manual Sync reports a foreign owner and a stale cache as account errors',
    () async {
      var requests = 0;
      final repository = NotesRepository(
        store: await NotesStore.open(path: path),
        clientForAccount: (_) async {
          requests++;
          throw StateError('Unexpected network access');
        },
      );
      await repository.initialize();
      addTearDown(repository.dispose);
      final coordinator = NotesSyncCoordinator(repository)
        ..setActiveAccount(account.id);
      addTearDown(coordinator.dispose);
      await owner.withRequestOwnership(account.id, () async {
        await coordinator.request(NotesSyncTrigger.manual);
        expect(
          repository.accountError(account.id)?.code,
          NotesFailureCode.conflict,
        );
      });
      await owner.saveAccount(account.copyWith(appVersion: '6.2.0'));
      await coordinator.request(NotesSyncTrigger.manual);
      expect(
        repository.accountError(account.id)?.code,
        NotesFailureCode.conflict,
      );
      expect(requests, 0);
    },
  );

  test(
    'unexpected acquisition failure propagates and disposal still closes',
    () async {
      final store = await NotesStore.open(path: path);
      final repository = NotesRepository(
        store: store,
        clientForAccount: (_) async =>
            throw StateError('Unexpected network access'),
      );
      await repository.initialize();
      await store.close();
      await expectLater(repository.synchronize(account.id), throwsStateError);
      final disposal = repository.dispose();
      await disposal;
      expect(repository.dispose(), same(disposal));
      await expectLater(repository.changes, emitsDone);
    },
  );

  test(
    'failed pending synchronization releases ownership and disposal closes resources',
    () async {
      final entered = Completer<void>(), fail = Completer<void>();
      final store = await NotesStore.open(path: path);
      final repository = NotesRepository(
        store: store,
        clientForAccount: (_) async {
          entered.complete();
          await fail.future;
          throw StateError('injected synchronization failure');
        },
      );
      await repository.initialize();
      final ended = expectLater(
        repository.changes,
        emitsInOrder([mayEmit(null), emitsDone]),
      );
      final sync = repository.synchronize(account.id);
      final rejected = expectLater(sync, throwsStateError);
      await entered.future;
      final disposal = repository.dispose();
      final disposedWithError = expectLater(disposal, throwsStateError);
      expect(repository.dispose(), same(disposal));
      fail.complete();
      await rejected;
      await disposedWithError;
      await ended;
      await expectLater(store.accounts(), throwsStateError);
      await owner.withRequestOwnership(account.id, () async {});
    },
  );
}

class _Secrets implements NextcloudSecretStore {
  String? password = 'fixture';
  int deletions = 0;
  bool failDeletion = false;

  @override
  Future<String?> read(String accountId) async => password;

  @override
  Future<void> write(String accountId, String secret) async {
    password = secret;
  }

  @override
  Future<void> delete(String accountId) async {
    deletions++;
    if (failDeletion) {
      throw const NextcloudCredentialException('injected failure');
    }
    password = null;
  }
}

class _Settings implements LocalSettingsStore {
  @override
  Future<Map<String, Object?>> load() async => {};
  @override
  Future<void> save(Map<String, Object?> json) async {}
}
