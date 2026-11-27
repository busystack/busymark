import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/app/localization.dart';
import 'package:busymark/src/speech/local_speech_provider.dart';
import 'package:busymark/src/speech/narration.dart';
import 'package:busymark/src/speech/speech.dart';
import 'package:busymark/src/speech/speech_dialog.dart';
import 'package:busymark/src/speech/speech_pcm.dart';
import 'package:busymark/src/speech/speech_settings.dart';
import 'package:busymark/src/speech/speech_usage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';

void main() {
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

    await tester.tap(find.text(l10n.speechSample));
    await tester.pumpAndSettle();
    expect(providerCalls, isEmpty);
    expect(capture.existsSync(), isFalse);

    await tester.runAsync(
      () => tester.tap(find.widgetWithText(FilledButton, l10n.speechSample)),
    );
    await _waitFor(
      tester,
      () => find.text(l10n.speechGenerated).evaluate().isNotEmpty,
    );
    expect(providerCalls.single.backend, SpeechBackend.espeak);
    expect(providerCalls.single.voice, isEmpty);
    expect(providerCalls.single.language, isEmpty);
    expect(capture.readAsStringSync().trim(), l10n.speechSampleText);
    expect(store.settings, isEmpty);
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
      final field = find.widgetWithText(TextFormField, l10n.speechSpeed);
      final sample = find.widgetWithText(TextButton, l10n.speechSample);
      await tester.ensureVisible(field);
      expect(tester.widget<TextFormField>(field).initialValue, '1.75');

      await tester.enterText(field, '2.5');
      await tester.pump();
      expect(
        tester
            .widget<TextField>(
              find.descendant(of: field, matching: find.byType(TextField)),
            )
            .decoration
            ?.errorText,
        '0.5–2.0',
      );
      expect(tester.widget<TextButton>(sample).onPressed, isNull);
      expect(AppSettings.fromJson(store.settings).speech.options.speed, 1.75);

      await tester.enterText(field, '1.9');
      await tester.pumpAndSettle();
      expect(AppSettings.fromJson(store.settings).speech.options.speed, 1.9);
      expect(tester.widget<TextButton>(sample).onPressed, isNotNull);

      await tester.pumpWidget(const SizedBox());
      await _mount(tester, store, const SpeechSettings());
      expect(tester.widget<TextFormField>(field).initialValue, '1.9');
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
              builder: (context, ref, _) => TextButton(
                onPressed: () {
                  final options = ref
                      .read(appSettingsControllerProvider)
                      .speech
                      .options;
                  final service = createService();
                  showDialog<void>(
                    context: context,
                    builder: (_) => SpeechDialog(
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
      final model = find.widgetWithText(
        DropdownButtonFormField<String>,
        l10n.speechModel,
      );
      expect(requests, isEmpty);
      await tester.runAsync(() => tester.tap(find.text(l10n.speechRefresh)));
      await _waitFor(tester, () => model.evaluate().isNotEmpty);
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
        () => tester.tap(find.widgetWithText(FilledButton, l10n.generateAudio)),
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

AppLocalizations _localizations(WidgetTester tester) =>
    tester.element(find.byType(SpeechSettings)).l10n;

Future<void> _mount(
  WidgetTester tester,
  _MemoryStore store,
  Widget child, {
  bool scroll = true,
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
        locale: const Locale('en'),
        localizationsDelegates: busyMarkLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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
