import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../data/login_flow.dart';
import '../data/notes_api_client.dart';
import '../data/notes_capabilities.dart';
import '../data/notes_secret_store.dart';
import '../data/notes_store.dart';
import '../data/server_uri.dart';
import '../domain/notes_models.dart';
import 'notes_repository.dart';

final nextcloudHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final nextcloudSecretStoreProvider = Provider<NextcloudSecretStore>(
  (ref) => const FlutterNextcloudSecretStore(),
);

final nextcloudLoginFlowProvider = Provider<NextcloudLoginFlow>(
  (ref) => NextcloudLoginFlow(
    client: ref.watch(nextcloudHttpClientProvider),
    openBrowser: (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
  ),
);

final nextcloudNotesDatabasePathProvider = FutureProvider<String>((ref) async {
  final support = await getApplicationSupportDirectory();
  return p.join(support.path, 'nextcloud-notes', 'notes.sqlite3');
});

/// Initialized only when the Notes workspace or account settings are used.
final nextcloudNotesRepositoryProvider = FutureProvider<NotesRepository>((
  ref,
) async {
  final path = await ref.watch(nextcloudNotesDatabasePathProvider.future);
  final client = ref.watch(nextcloudHttpClientProvider);
  final secrets = ref.watch(nextcloudSecretStoreProvider);
  final store = await NotesStore.open(path: path);
  final repository = NotesRepository(
    store: store,
    clientForAccount: (account) async {
      String? password;
      try {
        password = await secrets.read(account.id);
      } on NextcloudCredentialException {
        throw const NotesException(
          NotesFailureCode.authentication,
          'BusyMark could not access the desktop keyring. Unlock the keyring and reconnect Nextcloud.',
        );
      }
      if (password == null) {
        throw const NotesException(
          NotesFailureCode.authentication,
          'The Nextcloud app password is unavailable. Reconnect this account.',
        );
      }
      return NotesApiClient(
        client: client,
        account: account,
        appPassword: password,
      );
    },
  );
  try {
    await repository.initialize();
  } on Object {
    await store.close();
    rethrow;
  }
  ref.onDispose(() {
    unawaited(repository.dispose());
  });
  return repository;
});

enum NextcloudConnectionPhase {
  idle,
  awaitingBrowser,
  verifying,
  connected,
  removing,
}

class NextcloudConnectionState {
  const NextcloudConnectionState({
    this.account,
    this.phase = NextcloudConnectionPhase.idle,
    this.error,
  });

  final NextcloudAccount? account;
  final NextcloudConnectionPhase phase;
  final String? error;

  bool get busy =>
      phase == NextcloudConnectionPhase.awaitingBrowser ||
      phase == NextcloudConnectionPhase.verifying ||
      phase == NextcloudConnectionPhase.removing;
}

final nextcloudConnectionProvider =
    NotifierProvider<NextcloudConnectionController, NextcloudConnectionState>(
      NextcloudConnectionController.new,
    );

class NextcloudConnectionController extends Notifier<NextcloudConnectionState> {
  NextcloudLoginCancellation? _cancellation;
  int _generation = 0;
  bool _disposed = false;

  @override
  NextcloudConnectionState build() {
    ref.onDispose(() {
      _disposed = true;
      _cancellation?.cancel();
    });
    unawaited(reload());
    return const NextcloudConnectionState();
  }

  Future<void> reload() async {
    final generation = _generation;
    try {
      final repository = await ref.read(
        nextcloudNotesRepositoryProvider.future,
      );
      if (_disposed || generation != _generation || state.busy) return;
      final account = repository.accounts.firstOrNull;
      state = NextcloudConnectionState(
        account: account,
        phase: account == null
            ? NextcloudConnectionPhase.idle
            : NextcloudConnectionPhase.connected,
      );
    } on Object {
      if (_disposed || generation != _generation) return;
      state = const NextcloudConnectionState(
        error: 'BusyMark could not open the durable Nextcloud Notes store.',
      );
    }
  }

  Future<bool> connect(String serverUrl) => _connect(serverUrl);

  Future<bool> reconnect() async {
    final account = state.account;
    if (account == null) return false;
    return _connect(account.server.toString(), previous: account);
  }

  Future<bool> _connect(String serverUrl, {NextcloudAccount? previous}) async {
    if (state.busy) return false;
    final generation = ++_generation;
    final cancellation = NextcloudLoginCancellation();
    _cancellation = cancellation;
    var retainedAccount = previous ?? state.account;
    state = NextcloudConnectionState(
      account: retainedAccount,
      phase: NextcloudConnectionPhase.awaitingBrowser,
    );
    NextcloudLoginCredentials? credentials;
    String? accountId;
    String? previousPassword;
    var secretWritten = false;
    var committed = false;
    final secrets = ref.read(nextcloudSecretStoreProvider);
    final client = ref.read(nextcloudHttpClientProvider);
    final loginFlow = ref.read(nextcloudLoginFlowProvider);
    try {
      final server = normalizeNextcloudServer(serverUrl);
      final repository = await ref.read(
        nextcloudNotesRepositoryProvider.future,
      );
      if (previous == null && repository.accounts.isNotEmpty) {
        retainedAccount = repository.accounts.first;
        throw const NextcloudCredentialException(
          'Remove the connected Nextcloud account before connecting another account.',
        );
      }
      if (previous != null) {
        previousPassword = await secrets.read(previous.id);
      }
      cancellation.throwIfCancelled();
      credentials = await loginFlow.authenticate(
        server,
        cancellation: cancellation,
      );
      cancellation.throwIfCancelled();
      if (previous != null &&
          (previous.server != credentials.server ||
              previous.loginName != credentials.loginName)) {
        throw const NextcloudCredentialException(
          'Sign in to the same Nextcloud account when reconnecting. Remove this account first to connect a different account.',
        );
      }
      state = NextcloudConnectionState(
        account: previous,
        phase: NextcloudConnectionPhase.verifying,
      );
      accountId = previous?.id ?? const Uuid().v4();
      await secrets.write(accountId, credentials.appPassword);
      secretWritten = true;
      final capabilities = await fetchNotesCapabilities(
        client: client,
        server: credentials.server,
        loginName: credentials.loginName,
        appPassword: credentials.appPassword,
      );
      cancellation.throwIfCancelled();
      final account = NextcloudAccount(
        id: accountId,
        server: credentials.server,
        loginName: credentials.loginName,
        appVersion: capabilities.appVersion,
        apiVersion: capabilities.apiVersion,
        listEtag: previous?.listEtag,
        lastModified: previous?.lastModified,
      );
      await repository.upsertAccount(account);
      committed = true;
      if (_disposed) return true;
      state = NextcloudConnectionState(
        account: account,
        phase: NextcloudConnectionPhase.connected,
      );
      if (previousPassword != null &&
          previousPassword != credentials.appPassword) {
        unawaited(
          revokeNextcloudAppPassword(
            client: client,
            server: account.server,
            loginName: account.loginName,
            appPassword: previousPassword,
          ),
        );
      }
      return true;
    } on Object catch (error) {
      if (!committed && secretWritten && accountId != null) {
        try {
          if (previousPassword != null) {
            await secrets.write(accountId, previousPassword);
          } else {
            await secrets.delete(accountId);
          }
        } on Object {
          if (credentials != null) {
            await revokeNextcloudAppPassword(
              client: client,
              server: credentials.server,
              loginName: credentials.loginName,
              appPassword: credentials.appPassword,
            );
          }
          // Report keyring cleanup failure without falling back to plaintext.
          if (!_disposed && generation == _generation) {
            state = NextcloudConnectionState(
              account: retainedAccount,
              phase: retainedAccount == null
                  ? NextcloudConnectionPhase.idle
                  : NextcloudConnectionPhase.connected,
              error:
                  'Nextcloud setup failed and BusyMark could not clean up the desktop keyring. Unlock the keyring and reconnect.',
            );
          }
          return false;
        }
      }
      if (!committed && credentials != null) {
        await revokeNextcloudAppPassword(
          client: client,
          server: credentials.server,
          loginName: credentials.loginName,
          appPassword: credentials.appPassword,
        );
      }
      if (_disposed || generation != _generation) return false;
      state = NextcloudConnectionState(
        account: retainedAccount,
        phase: retainedAccount == null
            ? NextcloudConnectionPhase.idle
            : NextcloudConnectionPhase.connected,
        error: switch (error) {
          NextcloudLoginException(code: NextcloudLoginFailure.cancelled) =>
            null,
          NextcloudLoginException(:final message) => message,
          NextcloudCapabilityException(:final message) => message,
          NextcloudCredentialException(:final message) => message,
          FormatException(:final message) =>
            message == 'Enter a valid HTTPS Nextcloud server URL.'
                ? message
                : 'Enter a valid Nextcloud server URL.',
          _ => 'BusyMark could not finish connecting to Nextcloud Notes.',
        },
      );
      return false;
    } finally {
      if (identical(_cancellation, cancellation)) _cancellation = null;
    }
  }

  void cancel() => _cancellation?.cancel();

  /// Remote revocation is best effort; keyring and cache removal are required.
  Future<bool> disconnect() async {
    if (state.busy) return false;
    final account = state.account;
    if (account == null) return true;
    ++_generation;
    state = NextcloudConnectionState(
      account: account,
      phase: NextcloudConnectionPhase.removing,
    );
    try {
      final repository = await ref.read(
        nextcloudNotesRepositoryProvider.future,
      );
      final secrets = ref.read(nextcloudSecretStoreProvider);
      final password = await secrets.read(account.id);
      var revoked = false;
      if (password != null) {
        revoked = await revokeNextcloudAppPassword(
          client: ref.read(nextcloudHttpClientProvider),
          server: account.server,
          loginName: account.loginName,
          appPassword: password,
        );
      }
      await repository.removeAccount(
        account.id,
        beforeRemove: () => secrets.delete(account.id),
      );
      if (!_disposed) {
        state = NextcloudConnectionState(
          error: revoked
              ? null
              : 'The local Nextcloud account was removed. BusyMark could not confirm app-password revocation; remove its password in Nextcloud Security settings.',
        );
      }
      return true;
    } on Object catch (error) {
      if (!_disposed) {
        state = NextcloudConnectionState(
          account: account,
          phase: NextcloudConnectionPhase.connected,
          error: error is NextcloudCredentialException
              ? error.message
              : 'BusyMark could not remove the local Nextcloud account data. Try again.',
        );
      }
      return false;
    }
  }
}
