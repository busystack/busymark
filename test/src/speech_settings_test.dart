import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/localization.dart';
import 'package:busymark/src/speech/local_speech_provider.dart';
import 'package:busymark/src/speech/narration.dart';
import 'package:busymark/src/speech/speech.dart';
import 'package:busymark/src/speech/speech_dialog.dart';
import 'package:busymark/src/speech/speech_pcm.dart';
import 'package:busymark/src/speech/speech_settings.dart';
import 'package:busymark/src/speech/speech_usage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const window = MethodChannel('yaru_window');
  const windowEvents = EventChannel('yaru_window/events');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  setUp(() {
    messenger.setMockMethodCallHandler(
      window,
      (call) async =>
          call.method == 'state' ? <String, Object?>{'active': true} : null,
    );
    messenger.setMockStreamHandler(
      windowEvents,
      MockStreamHandler.inline(onListen: (_, _) {}, onCancel: (_) {}),
    );
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(window, null);
    messenger.setMockStreamHandler(windowEvents, null);
  });

  testWidgets('untouched Speech Settings generate the default eSpeak sample', (
    tester,
  ) async {
    final directory = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('default-espeak-sample-test-'),
    ))!;
    addTearDown(() => directory.delete(recursive: true));
    final capture = File('${directory.path}/input');
    final program = File('${directory.path}/espeak-ng');
    await tester.runAsync(() async {
      await File('${directory.path}/sample.wav').writeAsBytes(
        encodeSpeechWave(
          SpeechPcm(Uint8List.fromList([1, 0, 2, 0]), sampleRate: 24000),
        ),
      );
      await program.writeAsString(r'''#!/bin/sh
set -eu
cd -- "$(dirname -- "$0")"
[ "$3" = -v ] && [ "$4" = en ]
cat > input
cat sample.wav
''');
      final chmod = await Process.run('chmod', ['700', program.path]);
      expect(chmod.exitCode, 0);
    });
    final store = _MemoryStore();
    final providerCalls = <SpeechOptions>[];
    await _mount(
      tester,
      store,
      SpeechSettings(
        createService: () => SpeechService(
          client: () => MockClient(
            (_) async => fail('Local speech made an HTTP request.'),
          ),
          providerFactory: (options) {
            providerCalls.add(options);
            return EspeakSpeechProvider(options, executable: program.path);
          },
        ),
      ),
    );
    final l10n = _localizations(tester);

    final sample = _action(l10n.speechSample);
    for (var i = 0; i < 12 && !_actionHasFocus(l10n.speechSample); i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }
    expect(_actionHasFocus(l10n.speechSample), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(BusyMarkDialogShell), findsOneWidget);
    expect(providerCalls, isEmpty);
    expect(capture.existsSync(), isFalse);

    await tester.runAsync(() => tester.tap(_dialogAction(l10n.speechSample)));
    await _waitFor(
      tester,
      () => find.text(l10n.speechGenerated).evaluate().isNotEmpty,
    );
    expect(providerCalls.single.backend, SpeechBackend.espeak);
    expect(providerCalls.single.voice, isEmpty);
    expect(providerCalls.single.language, isEmpty);
    expect(capture.readAsStringSync().trim(), l10n.speechSampleText);
    expect(store.settings, isEmpty);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await _waitFor(
      tester,
      () => find.byType(BusyMarkDialogShell).evaluate().isEmpty,
    );
    await tester.pumpAndSettle();
    expect(find.byType(BusyMarkDialogShell), findsNothing);
    expect(sample, findsOneWidget);
    expect(_actionHasFocus(l10n.speechSample), isTrue);
  });

  testWidgets(
    'Settings keeps the original valid speed and shows invalid input',
    (tester) async {
      final store = _MemoryStore({
        'speech': {
          'backend': 'espeak',
          'providers': {
            'espeak': {'speed': 1.75},
          },
        },
      });
      await _mount(tester, store, const SpeechSettings());
      final l10n = _localizations(tester);
      final field = _entry(l10n.speechSpeed);
      final sample = _action(l10n.speechSample);
      await tester.ensureVisible(field);
      expect(
        tester.widget<BusyMarkGroupedTextEntry>(field).initialValue,
        '1.75',
      );
      expect(
        find.descendant(of: field, matching: find.text('0.5–2.0')),
        findsOneWidget,
      );

      await tester.enterText(field, '2.5');
      await tester.pump();
      expect(
        tester.widget<BusyMarkGroupedTextEntry>(field).errorText,
        '0.5–2.0',
      );
      expect(tester.widget<BusyMarkActionRow>(sample).enabled, isFalse);
      expect(AppSettings.fromJson(store.settings).speech.options.speed, 1.75);

      await tester.enterText(field, '1.9');
      await tester.pumpAndSettle();
      expect(AppSettings.fromJson(store.settings).speech.options.speed, 1.9);
      expect(tester.widget<BusyMarkActionRow>(sample).enabled, isTrue);
      expect(
        find.descendant(of: field, matching: find.text('0.5–2.0')),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox());
      await _mount(tester, store, const SpeechSettings());
      expect(
        tester.widget<BusyMarkGroupedTextEntry>(field).initialValue,
        '1.9',
      );
    },
  );

  testWidgets(
    'narrow localized Speech Settings keep native groups and Piper actions',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 680);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final store = _MemoryStore({
        'speech': {'backend': 'piper'},
      });
      for (final (brightness, locale, direction) in [
        (Brightness.light, const Locale('fr'), TextDirection.ltr),
        (Brightness.dark, const Locale('ar'), TextDirection.rtl),
      ]) {
        await tester.pumpWidget(const SizedBox());
        await _mount(
          tester,
          store,
          const SpeechSettings(),
          brightness: brightness,
          locale: locale,
          textScale: 1.5,
        );
        final context = tester.element(find.byType(SpeechSettings));
        final l10n = context.l10n;
        expect(Theme.of(context).brightness, brightness);
        expect(Directionality.of(context), direction);
        expect(find.byType(BusyMarkGroupedList), findsNWidgets(5));
        expect(
          tester
              .widgetList<BusyMarkGroupedList>(find.byType(BusyMarkGroupedList))
              .every((group) => group.filled),
          isTrue,
        );
        final provider = _combo<SpeechBackend>(l10n.speechProvider);
        expect(provider, findsOneWidget);
        final semantics = tester.ensureSemantics();
        try {
          await tester.pump();
          final providerSemantics = find.bySemanticsLabel(l10n.speechProvider);
          expect(providerSemantics, findsOneWidget);
          expect(tester.getSemantics(providerSemantics).value, 'Piper');
        } finally {
          semantics.dispose();
        }
        expect(_combo<NarrationLinks>(l10n.speechLinks), findsOneWidget);
        expect(_entry(l10n.speechLanguage), findsOneWidget);
        expect(_entry(l10n.audioDestination), findsOneWidget);
        expect(find.byType(BusyMarkSwitchRow), findsNWidgets(7));
        expect(_action(l10n.speechPiperImport), findsOneWidget);
        for (final voice in PiperVoiceStore.downloads) {
          final action = _action('${l10n.speechPiperInstall} · ${voice.label}');
          await tester.ensureVisible(action);
          final row = tester.widget<BusyMarkActionRow>(action);
          expect(row.onTap, isNotNull);
          expect((row.subtitleWidget as Text).data, contains(voice.license));
        }
        final headings = find.byWidgetPredicate(
          (widget) =>
              widget is BusyMarkSwitchRow &&
              widget.title == l10n.speechHeadings,
        );
        final previous = tester.widget<BusyMarkSwitchRow>(headings).value;
        await tester.ensureVisible(headings);
        await tester.tap(headings);
        await tester.pumpAndSettle();
        expect(
          AppSettings.fromJson(store.settings).speech.narration.headings,
          !previous,
        );
        expect(tester.takeException(), isNull);
      }
      expect(
        AppSettings.fromJson(store.settings).speech.backend,
        SpeechBackend.piper,
      );
    },
  );

  testWidgets(
    'cloud credentials retain secure storage and native status surfaces',
    (tester) async {
      const channel = MethodChannel('com.busymark.app/secure_credentials');
      final messenger = tester.binding.defaultBinaryMessenger;
      final methods = <String>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        methods.add(call.method);
        expect(
          call.arguments['key'],
          'busymark.speech.provider-key.elevenlabs',
        );
        if (call.method == 'write') {
          expect(call.arguments['value'], 'speech-test-placeholder');
        }
        return null;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      final store = _MemoryStore({
        'speech': {'backend': 'elevenLabs'},
      });
      await _mount(
        tester,
        store,
        SpeechSettings(
          createService: () => throw StateError(
            'Credential settings must not create a synthesis job.',
          ),
        ),
      );
      final l10n = _localizations(tester);
      final key = _entry(l10n.speechKey);
      final entry = tester.widget<BusyMarkGroupedTextEntry>(key);
      expect(entry.obscureText, isTrue);
      expect(entry.autocorrect, isFalse);
      expect(entry.enableSuggestions, isFalse);
      expect(find.text(l10n.speechCloudConsent), findsOneWidget);
      expect(methods, isEmpty);

      await tester.ensureVisible(key);
      await tester.enterText(key, 'speech-test-placeholder');
      final storeKey = _action(l10n.speechStoreKey);
      await tester.ensureVisible(storeKey);
      final semantics = tester.ensureSemantics();
      try {
        await tester.pump();
        final storeButton = find.bySemanticsLabel(l10n.speechStoreKey);
        expect(storeButton, findsOneWidget);
        final data = tester.getSemantics(storeButton).getSemanticsData();
        expect(data.flagsCollection.isButton, isTrue);
        expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
        tester.semantics.tap(find.semantics.byLabel(l10n.speechStoreKey));
      } finally {
        semantics.dispose();
      }
      await tester.pumpAndSettle();
      final status = find.byType(BusyMarkStatusBox);
      expect(
        tester.widget<BusyMarkStatusBox>(status).message,
        l10n.speechKeyStored,
      );
      expect(
        tester.widget<BusyMarkStatusBox>(status).kind,
        BusyMarkStatusKind.success,
      );
      expect(entry.controller!.text, isEmpty);

      final deleteKey = _action(l10n.speechDeleteKey);
      expect(tester.widget<BusyMarkActionRow>(deleteKey).destructive, isTrue);
      await tester.ensureVisible(deleteKey);
      await tester.tap(deleteKey);
      await tester.pumpAndSettle();
      expect(methods, ['write', 'delete']);
      expect(
        tester.widget<BusyMarkStatusBox>(status).message,
        l10n.speechKeyDeleted,
      );
      expect(
        jsonEncode(store.settings),
        isNot(contains('speech-test-placeholder')),
      );
    },
  );

  testWidgets(
    'Russian credential settings localize invalid input and vault errors',
    (tester) async {
      const channel = MethodChannel('com.busymark.app/secure_credentials');
      final messenger = tester.binding.defaultBinaryMessenger;
      var writes = 0;
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'write');
        writes++;
        throw PlatformException(code: 'unavailable');
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      await _mount(
        tester,
        _MemoryStore({
          'speech': {'backend': 'elevenLabs'},
        }),
        const SpeechSettings(),
        locale: const Locale('ru'),
      );
      final l10n = _localizations(tester);
      final storeKey = _action(l10n.speechStoreKey);
      await tester.ensureVisible(storeKey);
      await tester.tap(storeKey);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<BusyMarkStatusBox>(find.byType(BusyMarkStatusBox))
            .message,
        l10n.speechCredentialKeyInvalid,
      );
      expect(writes, 0);

      final key = _entry(l10n.speechKey);
      await tester.ensureVisible(key);
      await tester.enterText(key, 'synthetic-speech-key');
      await tester.ensureVisible(storeKey);
      await tester.tap(storeKey);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<BusyMarkStatusBox>(find.byType(BusyMarkStatusBox))
            .message,
        l10n.speechCredentialStoreUnavailable,
      );
      expect(writes, 1);
    },
  );

  testWidgets(
    'discovery progress, cancellation and failures use native controls',
    (tester) async {
      final discovery = _SettingsDiscoveryService();
      await _mount(
        tester,
        _MemoryStore(),
        SpeechSettings(createService: () => discovery),
      );
      final l10n = _localizations(tester);
      final discover = _action(l10n.speechRefresh);
      final provider = _combo<SpeechBackend>(l10n.speechProvider);
      final cancel = _action(l10n.cancel);
      final progress = find.byType(BusyMarkProgressIndicator);
      expect(discovery.calls, 0);
      await tester.ensureVisible(discover);
      await tester.tap(discover);
      await tester.pump();
      expect(progress, findsOneWidget);
      expect(
        tester.widget<BusyMarkProgressIndicator>(progress).semanticsLabel,
        l10n.speechRefresh,
      );
      expect(
        tester.widget<BusyMarkComboRow<SpeechBackend>>(provider).enabled,
        isFalse,
      );
      expect(
        tester.widget<BusyMarkActionRow>(_action(l10n.speechSample)).enabled,
        isFalse,
      );

      await tester.ensureVisible(cancel);
      await tester.tap(cancel);
      await tester.pumpAndSettle();
      expect(discovery.calls, 1);
      expect(discovery.cancellations, 1);
      expect(progress, findsNothing);
      expect(find.byType(BusyMarkStatusBox), findsNothing);
      expect(
        tester.widget<BusyMarkComboRow<SpeechBackend>>(provider).enabled,
        isTrue,
      );

      discovery.fails = true;
      await tester.ensureVisible(discover);
      await tester.tap(discover);
      await tester.pumpAndSettle();
      final status = tester.widget<BusyMarkStatusBox>(
        find.byType(BusyMarkStatusBox),
      );
      expect(status.kind, BusyMarkStatusKind.error);
      expect(status.message, 'Fixture catalog failed.');
      expect(progress, findsNothing);
    },
  );

  testWidgets(
    'discovered ElevenLabs model limits reach fresh document synthesis',
    (tester) async {
      final directory = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('speech-catalog-test-'),
      ))!;
      addTearDown(() => directory.delete(recursive: true));
      final ledger = SpeechUsageLedger(supportDirectory: () async => directory);
      final requests = <String>[];
      final synthesis = <String>[];
      final services = <SpeechService>[];
      final text = List.filled(1500, 'a').join();
      final store = _MemoryStore({
        'speech': {
          'backend': 'elevenLabs',
          'providers': {
            'elevenLabs': {'voice': 'fixture-voice'},
          },
        },
      });
      SpeechService createService() {
        final service = SpeechService(
          usageLedger: ledger,
          credentials: const _FixtureCredentials(),
          client: () => MockClient((request) async {
            expect(request.headers['xi-api-key'], 'catalog-fixture-account');
            requests.add(request.url.path);
            switch (request.url.path) {
              case '/v1/models':
                return http.Response(
                  jsonEncode([
                    {
                      'model_id': 'discovered-model',
                      'name': 'Discovered fixture model',
                      'can_do_text_to_speech': true,
                      'maximum_text_length_per_request': 1250,
                    },
                  ]),
                  200,
                );
              case '/v2/voices':
                return http.Response(
                  jsonEncode({
                    'voices': [
                      {'voice_id': 'fixture-voice', 'name': 'Fixture voice'},
                    ],
                    'has_more': false,
                  }),
                  200,
                );
              case '/v1/text-to-speech/fixture-voice/stream':
                final body = jsonDecode(request.body) as Map;
                expect(body['model_id'], 'discovered-model');
                final part = body['text'] as String;
                synthesis.add(part);
                expect(utf8.encode(part).length, lessThanOrEqualTo(1250));
                return http.Response.bytes(
                  [1, 0, 2, 0],
                  200,
                  headers: {
                    'content-type': 'audio/pcm',
                    'character-cost': part.length.toString(),
                  },
                );
              default:
                fail('Unexpected speech request ${request.url.path}');
            }
          }),
        );
        services.add(service);
        return service;
      }

      await _mount(
        tester,
        store,
        Column(
          children: [
            Consumer(
              builder: (context, ref, _) => BusyMarkPushButton.standard(
                onPressed: () {
                  final options = ref
                      .read(appSettingsControllerProvider)
                      .speech
                      .options;
                  final service = createService();
                  unawaited(
                    showSpeechNarrationDialog(
                      context,
                      options: options,
                      service: service,
                      planForScope: (_) => NarrationPlan(
                        documentId: 'fixture',
                        providerId: 'filesystem',
                        revision: 1,
                        scope: NarrationScope.document,
                        insertionOffset: 0,
                        passages: [(speech: SpeechSegment(text), source: null)],
                        omissions: const [],
                      ),
                      initialScope: NarrationScope.document,
                      scopes: const [NarrationScope.document],
                      suggestedFilename: 'fixture.wav',
                    ),
                  );
                },
                child: const Text('Begin document narration'),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: SpeechSettings(createService: createService),
              ),
            ),
          ],
        ),
        scroll: false,
      );
      final l10n = _localizations(tester);
      final model = _combo<String>(l10n.speechModel);
      expect(requests, isEmpty);
      final refresh = _action(l10n.speechRefresh);
      await tester.ensureVisible(refresh);
      await tester.runAsync(() => tester.tap(refresh));
      await _waitFor(
        tester,
        () =>
            model.evaluate().isNotEmpty &&
            tester.widget<BusyMarkComboRow<String>>(model).enabled,
      );
      expect(requests, ['/v1/models', '/v2/voices']);
      await tester.ensureVisible(model);
      await tester.tap(model);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discovered fixture model').last);
      await tester.pumpAndSettle();
      expect(
        AppSettings.fromJson(store.settings).speech.options.model,
        'discovered-model',
      );
      expect(synthesis, isEmpty);

      await tester.tap(find.text('Begin document narration'));
      await tester.pumpAndSettle();
      expect(synthesis, isEmpty);
      await tester.runAsync(
        () => tester.tap(_dialogAction(l10n.generateAudio)),
      );
      await _waitFor(
        tester,
        () => find.text(l10n.speechSaveAudio).evaluate().isNotEmpty,
      );
      expect(services, hasLength(2));
      expect(identical(services.first, services.last), isFalse);
      expect(synthesis.map((part) => utf8.encode(part).length), [1250, 250]);
      expect(synthesis.join(), text);
      expect(requests, [
        '/v1/models',
        '/v2/voices',
        '/v1/text-to-speech/fixture-voice/stream',
        '/v1/text-to-speech/fixture-voice/stream',
      ]);
      final usage = jsonDecode(
        File('${directory.path}/speech-usage.json').readAsStringSync(),
      );
      expect(usage['elevenLabs'], {'requests': 2, 'characters': 1500});
    },
  );
}

Finder _action(String title) => find.byWidgetPredicate(
  (widget) => widget is BusyMarkActionRow && widget.title == title,
);

Finder _dialogAction(String title) => find.byWidgetPredicate(
  (widget) => widget is BusyMarkDialogButton && widget.label == title,
);

Finder _entry(String label) => find.byWidgetPredicate(
  (widget) => widget is BusyMarkGroupedTextEntry && widget.label == label,
);

Finder _combo<T>(String title) => find.byWidgetPredicate(
  (widget) => widget is BusyMarkComboRow<T> && widget.title == title,
);

bool _actionHasFocus(String title) =>
    FocusManager.instance.primaryFocus?.context
        ?.findAncestorWidgetOfExactType<BusyMarkActionRow>()
        ?.title ==
    title;

AppLocalizations _localizations(WidgetTester tester) =>
    tester.element(find.byType(SpeechSettings)).l10n;

Future<void> _mount(
  WidgetTester tester,
  _MemoryStore store,
  Widget child, {
  bool scroll = true,
  Brightness brightness = Brightness.light,
  Locale locale = const Locale('en'),
  double textScale = 1,
}) async {
  final startup = await tester.runAsync(() => StartupAppSettings.load(store));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localSettingsStoreProvider.overrideWithValue(store),
        appSettingsControllerProvider.overrideWith(
          () => AppSettingsController(startupSettings: startup),
        ),
      ],
      child: MaterialApp(
        theme: buildBusyMarkTheme(
          brightness: brightness,
          accentColor: const Color(0xFF3584E4),
        ),
        locale: locale,
        localizationsDelegates: busyMarkLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: scroll ? SingleChildScrollView(child: child) : child,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _waitFor(WidgetTester tester, bool Function() condition) async {
  await tester.pump();
  for (var attempt = 0; attempt < 400 && !condition(); attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 20));
  }
  expect(
    condition(),
    isTrue,
    reason: tester
        .widgetList<Text>(find.byType(Text))
        .map((widget) => widget.data)
        .whereType<String>()
        .map(
          (label) => label.length > 160 ? '${label.substring(0, 160)}…' : label,
        )
        .join('\n'),
  );
}

class _MemoryStore implements LocalSettingsStore {
  _MemoryStore([this.settings = const {}]);
  Map<String, Object?> settings;

  @override
  Future<Map<String, Object?>> load() async => settings;

  @override
  Future<void> save(Map<String, Object?> json) async => settings = json;
}

class _FixtureCredentials extends SpeechCredentials {
  const _FixtureCredentials();

  @override
  Future<String?> read(SpeechBackend backend) async =>
      'catalog-fixture-account';
}

class _SettingsDiscoveryService extends SpeechService {
  int calls = 0;
  int cancellations = 0;
  bool fails = false;

  @override
  Future<SpeechCatalog> discover(
    SpeechOptions options, {
    required AiCancellationToken cancellationToken,
  }) async {
    calls++;
    if (fails) {
      throw const AiException(
        AiFailureCode.rejected,
        'Fixture catalog failed.',
      );
    }
    await cancellationToken.whenCancelled;
    cancellations++;
    cancellationToken.throwIfCancelled();
    return const SpeechCatalog();
  }
}
