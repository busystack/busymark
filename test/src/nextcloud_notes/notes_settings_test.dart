import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/local_history/local_history_controller.dart';
import 'package:busymark/src/local_history/local_history_store.dart';
import 'package:busymark/src/nextcloud_notes/application/nextcloud_connection.dart';
import 'package:busymark/src/nextcloud_notes/application/notes_repository.dart';
import 'package:busymark/src/nextcloud_notes/application/notes_settings_controller.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_api_client.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_capabilities.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_store.dart';
import 'package:busymark/src/nextcloud_notes/presentation/nextcloud_settings.dart';
import 'package:busymark/src/workspace/recovery_persistence.dart';
import 'package:busymark/src/workspace/session_persistence.dart';
import 'package:busymark/src/workspace/workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'notes_api_test.dart' show testAccount;

void main() {
  late Directory directory;
  late NotesRepository repository;
  late http.Client transport;
  var widgetDisposed = false;
  var gets = 0;
  var failRefresh = false;
  var capabilityChecks = 0;
  final bodies = <Map>[];
  var settings = {'notesPath': 'Notes', 'fileSuffix': '.txt'};
  setUp(() async {
    widgetDisposed = false;
    gets = 0;
    failRefresh = false;
    capabilityChecks = 0;
    bodies.clear();
    settings = {'notesPath': 'Notes', 'fileSuffix': '.txt'};
    directory = await Directory.systemTemp.createTemp('notes-settings-');
    transport = MockClient((request) async {
      if (request.url.path.endsWith('/v1/notes')) {
        expect(request.method, 'GET');
        return http.Response(
          failRefresh ? '{}' : '[]',
          failRefresh ? 503 : 200,
        );
      }
      expect(
        request.url.path,
        '/nextcloud/index.php/apps/notes/api/v1/settings',
      );
      expect(request.headers['authorization'], startsWith('Basic '));
      if (request.method == 'GET') {
        gets++;
      } else {
        expect(request.method, 'PUT');
        final body = jsonDecode(request.body) as Map;
        bodies.add(body);
        settings = {
          ...settings,
          for (final entry in body.entries)
            entry.key as String: (entry.value as String).trim(),
        };
      }
      return http.Response(
        jsonEncode({...settings, 'editorMode': 'ignored'}),
        200,
      );
    });
    repository = _SettingsRepository(
      store: await NotesStore.open(path: '${directory.path}/notes.sqlite3'),
      clientForAccount: (a) async =>
          NotesApiClient(client: transport, account: a, appPassword: 'fixture'),
    );
    await repository.initialize();
    await repository.upsertAccount(testAccount());
  });
  tearDown(() async {
    if (!widgetDisposed) await repository.dispose();
    directory.deleteSync(recursive: true);
  });

  test(
    'settings-only first connected use verifies maintained capabilities',
    () async {
      await repository.dispose();
      repository = NotesRepository(
        store: await NotesStore.open(path: '${directory.path}/notes.sqlite3'),
        clientForAccount: (a) async => NotesApiClient(
          client: transport,
          account: a,
          appPassword: 'fixture',
        ),
        fetchCapabilities: (_) async {
          capabilityChecks++;
          return const NotesCapabilities(
            appVersion: '6.1.0',
            apiVersion: '1.4',
          );
        },
      );
      await repository.initialize();
      await repository.upsertAccount(testAccount(appVersion: '6.0.2'));
      final container = ProviderContainer(
        overrides: [
          nextcloudNotesRepositoryProvider.overrideWith(
            (_) async => repository,
          ),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(notesSettingsProvider, (_, _) {});
      addTearDown(subscription.close);
      final controller = container.read(notesSettingsProvider.notifier);
      await controller.load(testAccount().id);
      expect(capabilityChecks, 1);
      expect(repository.accountById(testAccount().id)!.appVersion, '6.1.0');
      expect(
        repository.accountById(testAccount().id)!.capabilitiesCheckedAt,
        isNotNull,
      );
      await controller.load(testAccount().id);
      expect(capabilityChecks, 1);
      expect(gets, 2);
    },
  );

  test(
    'dirty settings form ignores background reload and Cancel restores server snapshot',
    () async {
      final container = ProviderContainer(
        overrides: [
          nextcloudNotesRepositoryProvider.overrideWith(
            (_) async => repository,
          ),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(notesSettingsProvider, (_, _) {});
      addTearDown(subscription.close);
      final controller = container.read(notesSettingsProvider.notifier);
      await controller.load(testAccount().id);
      controller.edit(fileSuffix: '.custom');
      await controller.load(testAccount().id);
      expect(gets, 1);
      expect(
        container.read(notesSettingsProvider).draft!.fileSuffix,
        '.custom',
      );
      controller.cancel();
      expect(container.read(notesSettingsProvider).draft!.fileSuffix, '.txt');
      expect(container.read(notesSettingsProvider).dirty, isFalse);
      controller.edit(fileSuffix: ' .custom ');
      expect(await controller.save(preserveBuffers: () async => true), isTrue);
      expect(bodies.single, {'fileSuffix': ' .custom '});
      expect(container.read(notesSettingsProvider).normalized, isTrue);
      expect(
        container.read(notesSettingsProvider).draft!.fileSuffix,
        '.custom',
      );
    },
  );

  for (final throwsLocally in [false, true]) {
    test(
      'settings preserve failure reaches terminal state with draft, throws=$throwsLocally',
      () async {
        final container = ProviderContainer(
          overrides: [
            nextcloudNotesRepositoryProvider.overrideWith(
              (_) async => repository,
            ),
          ],
        );
        addTearDown(container.dispose);
        final subscription = container.listen(notesSettingsProvider, (_, _) {});
        addTearDown(subscription.close);
        final controller = container.read(notesSettingsProvider.notifier);
        await controller.load(testAccount().id);
        final original = container.read(notesSettingsProvider).original;
        controller.edit(notesPath: 'Draft/Nested');
        final saved = await controller.save(
          preserveBuffers: () async {
            if (throwsLocally) {
              throw FileSystemException('fixture local failure');
            }
            return false;
          },
        );
        expect(saved, isFalse);
        final state = container.read(notesSettingsProvider);
        expect(state.busy, isFalse);
        expect(state.failure, isNotNull);
        expect(state.original, same(original));
        expect(state.draft!.notesPath, 'Draft/Nested');
        expect(bodies, isEmpty);
      },
    );
  }

  for (final localThrow in [false, true]) {
    test(
      'acknowledged settings remain authoritative after refresh failure, local=$localThrow',
      () async {
        final container = ProviderContainer(
          overrides: [
            nextcloudNotesRepositoryProvider.overrideWith(
              (_) async => repository,
            ),
          ],
        );
        addTearDown(container.dispose);
        final subscription = container.listen(notesSettingsProvider, (_, _) {});
        addTearDown(subscription.close);
        final controller = container.read(notesSettingsProvider.notifier);
        await controller.load(testAccount().id);
        controller.edit(notesPath: ' Server/Normalized ');
        failRefresh = true;
        (repository as _SettingsRepository).throwRefresh = localThrow;
        expect(
          await controller.save(preserveBuffers: () async => true),
          isTrue,
        );
        final state = container.read(notesSettingsProvider);
        expect(state.phase, NotesSettingsPhase.saved);
        expect(state.dirty, isFalse);
        expect(state.draft!.notesPath, 'Server/Normalized');
        expect(state.original!.notesPath, 'Server/Normalized');
        expect(state.normalized, isTrue);
        expect(state.refreshFailed, localThrow);
        if (!localThrow) {
          expect(repository.accountError(testAccount().id), isNotNull);
        }
      },
    );
  }

  testWidgets(
    'settings departure Cancel preserves draft and comparison; Discard restores original',
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
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(notesSettingsProvider, (_, _) {});
      addTearDown(subscription.close);
      final controller = container.read(notesSettingsProvider.notifier);
      await tester.runAsync(() => controller.load(testAccount().id));
      controller.edit(notesPath: 'Draft/Nested');
      final original = container.read(notesSettingsProvider).original;
      bool? approved;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () async {
                    approved = await confirmNotesSettingsDeparture(context);
                  },
                  child: const Text('leave'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('leave'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(approved, isFalse);
      expect(container.read(notesSettingsProvider).original, same(original));
      expect(
        container.read(notesSettingsProvider).draft!.notesPath,
        'Draft/Nested',
      );
      expect(bodies, isEmpty);
      await tester.tap(find.text('leave'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(approved, isTrue);
      expect(container.read(notesSettingsProvider).dirty, isFalse);
      expect(bodies, isEmpty);
    },
  );

  testWidgets(
    'server settings controls load, save partial custom suffix and show normalization',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            nextcloudNotesRepositoryProvider.overrideWith(
              (_) async => repository,
            ),
            documentSessionStoreProvider.overrideWithValue(
              MemoryDocumentSessionStore(),
            ),
            documentRecoveryStoreProvider.overrideWithValue(
              MemoryDocumentRecoveryStore(),
            ),
            localHistoryStoreProvider.overrideWithValue(
              MemoryLocalHistoryStore(),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: SingleChildScrollView(child: NextcloudNotesSettings()),
            ),
          ),
        ),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(NextcloudNotesSettings)),
      );
      await tester.runAsync(() async {
        await container.read(nextcloudConnectionProvider.notifier).reload();
      });
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await container
            .read(notesSettingsProvider.notifier)
            .load(testAccount().id);
      });
      await tester.pumpAndSettle();
      expect(find.text('Server Notes settings'), findsOneWidget);
      final suffix = find.descendant(
        of: find.byKey(const ValueKey('notes-settings-suffix')),
        matching: find.byType(TextField),
      );
      expect(tester.widget<TextField>(suffix).controller!.text, '.txt');
      await tester.enterText(suffix, ' .custom ');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('notes-settings-save')),
      );
      await tester.tap(find.byKey(const ValueKey('notes-settings-save')));
      for (
        var i = 0;
        i < 1000 &&
            container.read(notesSettingsProvider).phase !=
                NotesSettingsPhase.saved;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 20));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
      }
      expect(
        container.read(notesSettingsProvider).phase,
        NotesSettingsPhase.saved,
      );
      await tester.pumpAndSettle();
      expect(bodies.single, {'fileSuffix': ' .custom '});
      expect(find.text('Saved with server-normalized values'), findsOneWidget);
      expect(tester.widget<TextField>(suffix).controller!.text, '.custom');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      var disposed = false;
      unawaited(repository.dispose().then((_) => disposed = true));
      for (var i = 0; i < 1000 && !disposed; i++) {
        await tester.pump(const Duration(milliseconds: 20));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
      }
      widgetDisposed =
          true; // Disposal is verified here in the widget test zone.
      expect(disposed, isTrue);
    },
  );
}

class _SettingsRepository extends NotesRepository {
  _SettingsRepository({required super.store, required super.clientForAccount});
  bool throwRefresh = false;
  @override
  Future<void> synchronize(
    String id, {
    bool allowWrites = true,
    bool refreshCapabilities = false,
    bool onlyFreshWrites = false,
  }) {
    if (throwRefresh) {
      throw const FileSystemException('fixture refresh storage failure');
    }
    return super.synchronize(
      id,
      allowWrites: allowWrites,
      refreshCapabilities: refreshCapabilities,
      onlyFreshWrites: onlyFreshWrites,
    );
  }
}
