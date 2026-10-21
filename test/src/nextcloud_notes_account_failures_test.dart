import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/local_history/local_history_controller.dart';
import 'package:busymark/src/local_history/local_history_store.dart';
import 'package:busymark/src/nextcloud_notes/application/nextcloud_connection.dart';
import 'package:busymark/src/nextcloud_notes/application/notes_repository.dart';
import 'package:busymark/src/nextcloud_notes/data/login_flow.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_capabilities.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_store.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_secret_store.dart';
import 'package:busymark/src/nextcloud_notes/domain/notes_models.dart';
import 'package:busymark/src/nextcloud_notes/presentation/nextcloud_settings.dart';
import 'package:busymark/src/workspace/recovery_persistence.dart';
import 'package:busymark/src/workspace/session_persistence.dart';
import 'package:busymark/src/workspace/workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _MemorySecrets implements NextcloudSecretStore {
  final values = <String, String>{};
  @override
  Future<String?> read(String id) async => values[id];
  @override
  Future<void> write(String id, String password) async => values[id] = password;
  @override
  Future<void> delete(String id) async => values.remove(id);
}

class _MemorySettings implements LocalSettingsStore {
  @override
  Future<Map<String, Object?>> load() async => {'automaticSpelling': false};
  @override
  Future<void> save(Map<String, Object?> values) async {}
}

Future<void> _settleAccount(WidgetTester tester) async {
  final elapsed = Stopwatch()..start();
  var rounds = 0;
  bool loading() => find
      .byWidgetPredicate(
        (w) =>
            w is LinearProgressIndicator && w.value == null ||
            w is CircularProgressIndicator && w.value == null,
      )
      .evaluate()
      .isNotEmpty;
  do {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 20));
    rounds++;
  } while ((rounds < 20 || loading()) &&
      elapsed.elapsed < const Duration(seconds: 10));
  expect(loading(), isFalse, reason: 'Account operation did not settle');
  await tester.pumpAndSettle();
}

class _FailedConnection extends NextcloudConnectionController {
  _FailedConnection(this.failure);
  final Object failure;
  @override
  NextcloudConnectionState build() => NextcloudConnectionState(
    error: 'Safe fixture diagnostic',
    failure: failure,
  );
}

Future<void> _closeFixture(
  WidgetTester tester,
  ProviderContainer container,
  NotesRepository repository,
) async {
  await tester.pumpWidget(const SizedBox.shrink());
  container.dispose();
  var closed = false;
  unawaited(repository.dispose().then((_) => closed = true));
  for (var i = 0; i < 1000 && !closed; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 20));
  }
  expect(closed, isTrue);
}

void main() {
  late Directory root;
  late NotesRepository repository;
  var fixtureClosed = false;
  setUp(() async {
    fixtureClosed = false;
    root = await Directory.systemTemp.createTemp('notes-account-presentation-');
    repository = NotesRepository(
      store: await NotesStore.open(path: '${root.path}/notes.db'),
      clientForAccount: (_) async =>
          throw StateError('No network in presentation fixture'),
    );
    await repository.initialize();
  });
  tearDown(() async {
    if (!fixtureClosed) await repository.dispose();
    await root.delete(recursive: true);
  });
  for (final entry in <(Object, String)>[
    for (final code in NextcloudCapabilityFailure.values)
      (
        NextcloudCapabilityException(code, 'Do not expose this diagnostic'),
        switch (code) {
          NextcloudCapabilityFailure.unsupported =>
            'Notes is unavailable or its API is unsupported',
          NextcloudCapabilityFailure.unauthorized =>
            'Nextcloud rejected the credentials',
          NextcloudCapabilityFailure.malformed =>
            'response could not be verified',
          NextcloudCapabilityFailure.network => 'could not reach Nextcloud',
          NextcloudCapabilityFailure.rejected =>
            'rejected the capability request',
          NextcloudCapabilityFailure.forbidden =>
            'denied the Notes capability check',
          NextcloudCapabilityFailure.throttled => 'requested a pause',
        },
      ),
    for (final code in NextcloudLoginFailure.values)
      (
        NextcloudLoginException(code, 'Do not expose this diagnostic'),
        switch (code) {
          NextcloudLoginFailure.network ||
          NextcloudLoginFailure.server => 'could not reach Nextcloud',
          NextcloudLoginFailure.malformedResponse =>
            'response could not be verified',
          NextcloudLoginFailure.unsafeRedirect => 'canonical HTTPS address',
          NextcloudLoginFailure.browserUnavailable =>
            'system browser could not open',
          NextcloudLoginFailure.timedOut => 'Sign-in timed out',
          NextcloudLoginFailure.cancelled => 'Cancelled',
        },
      ),
    (
      StateError('Unmapped initial setup failure'),
      'could not complete account setup',
    ),
  ]) {
    final failureCode = switch (entry.$1) {
      NextcloudCapabilityException(:final code) => code.name,
      NextcloudLoginException(:final code) => code.name,
      _ => 'unknown',
    };
    testWidgets(
      'account failure ${entry.$1.runtimeType}.$failureCode: ${entry.$2}',
      (tester) async {
        for (final name in ['yaru_window', 'yaru_window/events']) {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(
                MethodChannel(name),
                (call) async =>
                    call.method == 'state' ? <String, Object?>{} : null,
              );
        }
        final container = ProviderContainer(
          overrides: [
            nextcloudNotesRepositoryProvider.overrideWith(
              (_) async => repository,
            ),
            nextcloudConnectionProvider.overrideWith(
              () => _FailedConnection(entry.$1),
            ),
          ],
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(
                body: SingleChildScrollView(child: NextcloudNotesSettings()),
              ),
            ),
          ),
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining(entry.$2), findsOneWidget);
        if (entry.$1 case NextcloudCapabilityException(
          code: NextcloudCapabilityFailure.throttled,
        )) {
          expect(find.textContaining('starting sign-in again'), findsOneWidget);
          expect(find.textContaining('Synchronization resumes'), findsNothing);
        }
        expect(find.textContaining('Your draft is retained'), findsNothing);
        expect(find.textContaining('review Save'), findsNothing);
        expect(
          find.textContaining('Do not expose this diagnostic'),
          findsNothing,
        );
        await _closeFixture(tester, container, repository);
        fixtureClosed = true;
      },
    );
  }

  testWidgets(
    'throttled reconnect keeps cached Open and confirmed local removal available',
    (tester) async {
      const id = '123e4567-e89b-42d3-a456-426614174000';
      final account = NextcloudAccount(
        id: id,
        server: Uri.parse('https://cloud.example/nextcloud'),
        loginName: 'retained-user',
        appVersion: '6.1.0',
      );
      late NextcloudNote cached;
      await tester.runAsync(() async {
        await repository.upsertAccount(account);
        cached = await repository.create(
          id,
          content: 'Cached work remains readable',
        );
      });
      final secrets = _MemorySecrets()..values[id] = 'previous-password';
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        if (request.method == 'DELETE') return http.Response('', 204);
        if (request.url.path.endsWith('/index.php/login/v2')) {
          return http.Response(
            jsonEncode({
              'poll': {
                'token': 'fixture-token',
                'endpoint': 'https://cloud.example/nextcloud/login/v2/poll',
              },
              'login': 'https://cloud.example/nextcloud/login/v2/flow/fixture',
            }),
            200,
          );
        }
        if (request.url.path.endsWith('/login/v2/poll')) {
          return http.Response(
            jsonEncode({
              'server': account.server.toString(),
              'loginName': account.loginName,
              'appPassword': 'replacement-password',
            }),
            200,
          );
        }
        return http.Response('', 429, headers: {'retry-after': '3600'});
      });
      final container = ProviderContainer(
        overrides: [
          nextcloudNotesRepositoryProvider.overrideWith(
            (_) async => repository,
          ),
          nextcloudSecretStoreProvider.overrideWithValue(secrets),
          nextcloudHttpClientProvider.overrideWithValue(client),
          nextcloudLoginFlowProvider.overrideWithValue(
            NextcloudLoginFlow(client: client, openBrowser: (_) async => true),
          ),
          localSettingsStoreProvider.overrideWithValue(_MemorySettings()),
          localHistoryStoreProvider.overrideWithValue(
            MemoryLocalHistoryStore(),
          ),
          documentSessionStoreProvider.overrideWithValue(
            MemoryDocumentSessionStore(),
          ),
          documentRecoveryStoreProvider.overrideWithValue(
            MemoryDocumentRecoveryStore(),
          ),
        ],
      );
      final router = GoRouter(
        initialLocation: '/settings',
        routes: [
          GoRoute(
            path: '/settings',
            builder: (_, _) => const Scaffold(
              body: SingleChildScrollView(child: NextcloudNotesSettings()),
            ),
          ),
          GoRoute(
            path: '/workspace',
            builder: (_, _) => Consumer(
              builder: (_, ref, _) => Scaffold(
                body: Text(
                  ref.watch(workspaceControllerProvider).activeBuffer?.text ??
                      'Cached Notes workspace',
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/',
            builder: (_, _) =>
                const Scaffold(body: Text('Local account removed')),
          ),
        ],
      );
      addTearDown(() {
        if (!fixtureClosed) container.dispose();
      });
      addTearDown(router.dispose);
      addTearDown(client.close);
      for (final name in ['yaru_window', 'yaru_window/events']) {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          MethodChannel(name),
          (call) async => call.method == 'state' ? <String, Object?>{} : null,
        );
      }
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await _settleAccount(tester);
      final reconnect = find.widgetWithText(BusyMarkActionRow, 'Reconnect');
      await tester.tap(reconnect);
      await _settleAccount(tester);
      final connection = container.read(nextcloudConnectionProvider);
      expect(connection.account?.id, id);
      expect(
        connection.failure,
        isA<NextcloudCapabilityException>().having(
          (e) => e.code,
          'code',
          NextcloudCapabilityFailure.throttled,
        ),
      );
      expect(connection.retryNotBefore!.isAfter(DateTime.now()), isTrue);
      expect(secrets.values[id], 'previous-password');
      expect(tester.widget<BusyMarkActionRow>(reconnect).enabled, isFalse);
      final requestCount = requests.length;
      expect(
        await container.read(nextcloudConnectionProvider.notifier).reconnect(),
        isFalse,
      );
      expect(requests, hasLength(requestCount));
      final open = find.widgetWithText(BusyMarkActionRow, 'Open');
      final disconnect = find.widgetWithText(BusyMarkActionRow, 'Disconnect');
      expect(tester.widget<BusyMarkActionRow>(open).enabled, isTrue);
      expect(tester.widget<BusyMarkActionRow>(disconnect).enabled, isTrue);
      await tester.tap(open);
      await _settleAccount(tester);
      expect(router.routeInformationProvider.value.uri.path, '/workspace');
      expect(find.text(cached.content), findsOneWidget);
      router.go('/settings');
      await _settleAccount(tester);
      expect(tester.widget<BusyMarkActionRow>(reconnect).enabled, isFalse);
      await tester.tap(disconnect);
      await tester.pumpAndSettle();
      expect(find.byType(BusyMarkDialogShell), findsOneWidget);
      await tester.tap(find.widgetWithText(BusyMarkDialogButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(repository.accountById(id), isNotNull);
      expect(secrets.values[id], 'previous-password');
      await tester.tap(disconnect);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(BusyMarkDialogButton, 'Disconnect'));
      await _settleAccount(tester);
      expect(find.text('Local account removed'), findsOneWidget);
      expect(repository.accountById(id), isNull);
      expect(repository.noteById(cached.localId), isNull);
      expect(secrets.values, isEmpty);
      expect(container.read(workspaceControllerProvider).workspace, isNull);
      expect(requests.where((r) => r.method != 'DELETE'), hasLength(3));
      await _closeFixture(tester, container, repository);
      fixtureClosed = true;
    },
  );

  testWidgets(
    'account throttle disables sign-in until the specified deadline',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          nextcloudNotesRepositoryProvider.overrideWith(
            (_) async => repository,
          ),
          nextcloudConnectionProvider.overrideWith(
            () => _FailedConnection(
              NextcloudCapabilityException(
                NextcloudCapabilityFailure.throttled,
                'pause',
                retryNotBefore: DateTime.now().add(const Duration(hours: 1)),
              ),
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: SingleChildScrollView(child: NextcloudNotesSettings()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<BusyMarkActionRow>(
              find.byKey(const ValueKey('nextcloud-connect')),
            )
            .enabled,
        isFalse,
      );
      expect(
        await container
            .read(nextcloudConnectionProvider.notifier)
            .connect('https://unused.invalid'),
        isFalse,
      );
      await _closeFixture(tester, container, repository);
      fixtureClosed = true;
    },
  );
}
