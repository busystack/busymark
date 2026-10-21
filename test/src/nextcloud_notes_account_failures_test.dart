import 'dart:io';
import 'dart:async';

import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/nextcloud_notes/application/nextcloud_connection.dart';
import 'package:busymark/src/nextcloud_notes/application/notes_repository.dart';
import 'package:busymark/src/nextcloud_notes/data/login_flow.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_capabilities.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_store.dart';
import 'package:busymark/src/nextcloud_notes/presentation/nextcloud_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
