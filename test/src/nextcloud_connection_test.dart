import 'dart:convert';
import 'dart:io';

import 'package:busymark/src/nextcloud_notes/application/nextcloud_connection.dart';
import 'package:busymark/src/nextcloud_notes/application/notes_repository.dart';
import 'package:busymark/src/nextcloud_notes/data/login_flow.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_secret_store.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _Secrets implements NextcloudSecretStore {
  final values = <String, String>{};
  bool failWrite = false;
  bool failDelete = false;
  @override
  Future<String?> read(String accountId) async => values[accountId];
  @override
  Future<void> write(String accountId, String appPassword) async {
    if (failWrite) throw const NextcloudCredentialException('Keyring locked.');
    values[accountId] = appPassword;
  }

  @override
  Future<void> delete(String accountId) async {
    if (failDelete) throw const NextcloudCredentialException('Keyring locked.');
    values.remove(accountId);
  }
}

void main() {
  late Directory directory;
  late NotesRepository repository;
  late ProviderContainer container;
  late _Secrets secrets;
  late http.Client client;
  var version = '6.1.0';
  var apiVersion = '1.4';
  var login = 'Exact.Login';
  var revokeStatus = 200;
  var revocations = 0;

  setUp(() async {
    version = '6.1.0';
    apiVersion = '1.4';
    login = 'Exact.Login';
    revokeStatus = 200;
    revocations = 0;
    directory = await Directory.systemTemp.createTemp('busymark-connection-');
    final store = await NotesStore.open(
      path: '${directory.path}/notes.sqlite3',
    );
    repository = NotesRepository(
      store: store,
      clientForAccount: (_) async => throw StateError('No sync requested.'),
    );
    await repository.initialize();
    secrets = _Secrets();
    client = MockClient((request) async {
      if (request.method == 'DELETE') {
        revocations++;
        return http.Response('', revokeStatus);
      }
      if (request.url.path.endsWith('/index.php/login/v2')) {
        return http.Response(
          jsonEncode({
            'poll': {
              'token': 'token',
              'endpoint': 'https://cloud.example/nextcloud/login/v2/poll',
            },
            'login': 'https://cloud.example/nextcloud/login/v2/flow/test',
          }),
          200,
        );
      }
      if (request.url.path.endsWith('/login/v2/poll')) {
        return http.Response(
          jsonEncode({
            'server': 'https://cloud.example/nextcloud/',
            'loginName': login,
            'appPassword': 'secret-app-password',
          }),
          200,
        );
      }
      return http.Response(
        jsonEncode({
          'ocs': {
            'meta': {'statuscode': 200},
            'data': {
              'capabilities': {
                'notes': {
                  'version': version,
                  'api_version': [apiVersion],
                },
              },
            },
          },
        }),
        200,
      );
    });
    container = ProviderContainer(
      overrides: [
        nextcloudNotesRepositoryProvider.overrideWith((_) async => repository),
        nextcloudSecretStoreProvider.overrideWithValue(secrets),
        nextcloudHttpClientProvider.overrideWithValue(client),
        nextcloudLoginFlowProvider.overrideWithValue(
          NextcloudLoginFlow(client: client, openBrowser: (_) async => true),
        ),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    client.close();
    await repository.dispose();
    await directory.delete(recursive: true);
  });

  test(
    'setup stores password only in secret service and metadata in SQLite',
    () async {
      final controller = container.read(nextcloudConnectionProvider.notifier);
      expect(
        await controller.connect('https://cloud.example/nextcloud/'),
        isTrue,
      );
      final account = repository.accounts.single;
      expect(account.loginName, 'Exact.Login');
      expect(secrets.values[account.id], 'secret-app-password');
      expect(account.toJson().toString(), isNot(contains('password')));
      final bytes = await File(repository.store.path).readAsBytes();
      expect(latin1.decode(bytes), isNot(contains('secret-app-password')));
      expect(
        container.read(nextcloudConnectionProvider).phase,
        NextcloudConnectionPhase.connected,
      );
    },
  );

  test(
    'locked keyring fails setup without a plaintext account fallback',
    () async {
      secrets.failWrite = true;
      final controller = container.read(nextcloudConnectionProvider.notifier);
      expect(
        await controller.connect('https://cloud.example/nextcloud'),
        isFalse,
      );
      expect(repository.accounts, isEmpty);
      expect(secrets.values, isEmpty);
      expect(revocations, 1);
      expect(
        container.read(nextcloudConnectionProvider).error,
        'Keyring locked.',
      );
    },
  );

  test('Notes 6.0.1 connects with API 1.4', () async {
    version = '6.0.1';
    expect(
      await container
          .read(nextcloudConnectionProvider.notifier)
          .connect('https://cloud.example/nextcloud'),
      isTrue,
    );
    expect(repository.accounts.single.supportsAttachmentDeletion, isFalse);
    expect(secrets.values, hasLength(1));
    expect(revocations, 0);
  });

  test(
    'production setup preserves the HTTPS-specific validation error',
    () async {
      final controller = container.read(nextcloudConnectionProvider.notifier);
      expect(await controller.connect('http://192.168.1.2/nextcloud'), isFalse);
      expect(repository.accounts, isEmpty);
      expect(secrets.values, isEmpty);
      expect(
        container.read(nextcloudConnectionProvider).error,
        'Enter a valid HTTPS Nextcloud server URL.',
      );
    },
  );

  test('unsupported API rolls back secret and revokes new token', () async {
    apiVersion = '1.3';
    final controller = container.read(nextcloudConnectionProvider.notifier);
    expect(
      await controller.connect('https://cloud.example/nextcloud'),
      isFalse,
    );
    expect(repository.accounts, isEmpty);
    expect(secrets.values, isEmpty);
    expect(revocations, 1);
    expect(
      container.read(nextcloudConnectionProvider).error,
      contains('Notes API'),
    );
  });

  test('setup revokes the grant even if keyring cleanup fails', () async {
    apiVersion = '1.3';
    secrets.failDelete = true;
    final controller = container.read(nextcloudConnectionProvider.notifier);
    expect(
      await controller.connect('https://cloud.example/nextcloud'),
      isFalse,
    );
    expect(repository.accounts, isEmpty);
    expect(revocations, 1);
    expect(
      container.read(nextcloudConnectionProvider).error,
      contains('could not clean up the desktop keyring'),
    );
  });

  test(
    'reconnect preserves stable account identity and pending note cache',
    () async {
      final controller = container.read(nextcloudConnectionProvider.notifier);
      await controller.connect('https://cloud.example/nextcloud');
      final before = repository.accounts.single;
      final note = await repository.create(
        before.id,
        content: 'Durable pending edit',
      );
      expect(await controller.reconnect(), isTrue);
      expect(repository.accounts.single.id, before.id);
      expect(
        repository.noteById(note.localId)?.content,
        'Durable pending edit',
      );
    },
  );

  test(
    'different returned login cannot inherit the existing account outbox',
    () async {
      final controller = container.read(nextcloudConnectionProvider.notifier);
      await controller.connect('https://cloud.example/nextcloud');
      final before = repository.accounts.single;
      login = 'Other.Login';
      expect(await controller.reconnect(), isFalse);
      expect(repository.accounts.single.loginName, before.loginName);
      expect(secrets.values[before.id], 'secret-app-password');
      expect(
        container.read(nextcloudConnectionProvider).error,
        contains('same Nextcloud account'),
      );
    },
  );

  test(
    'failed remote revocation still removes local account and secret',
    () async {
      final controller = container.read(nextcloudConnectionProvider.notifier);
      await controller.connect('https://cloud.example/nextcloud');
      revokeStatus = 500;
      expect(await controller.disconnect(), isTrue);
      expect(repository.accounts, isEmpty);
      expect(secrets.values, isEmpty);
      expect(container.read(nextcloudConnectionProvider).account, isNull);
      expect(
        container.read(nextcloudConnectionProvider).error,
        contains('could not confirm app-password revocation'),
      );
    },
  );

  test(
    'locked keyring during removal retains account for explicit retry',
    () async {
      final controller = container.read(nextcloudConnectionProvider.notifier);
      await controller.connect('https://cloud.example/nextcloud');
      secrets.failDelete = true;
      expect(await controller.disconnect(), isFalse);
      expect(repository.accounts, hasLength(1));
      expect(secrets.values, hasLength(1));
      secrets.failDelete = false;
      expect(await controller.disconnect(), isTrue);
      expect(repository.accounts, isEmpty);
    },
  );
}
