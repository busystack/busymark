import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:busymark/src/speech/elevenlabs_speech_provider.dart';
import 'package:busymark/src/speech/gemini_speech_provider.dart';
import 'package:busymark/src/speech/openai_speech_provider.dart';
import 'package:busymark/src/speech/speech.dart';
import 'package:busymark/src/speech/speech_pcm.dart';
import 'package:busymark/src/speech/speech_preferences.dart';
import 'package:busymark/src/speech/speech_usage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late AiCancellationToken token;
  setUp(() => token = AiCancellationToken());
  tearDown(() => token.dispose());

  test('WAV writer and PCM normalizer preserve frame boundaries', () {
    final pcm = SpeechPcm(
      Uint8List.fromList([0, 0, 1, 0, 2, 0, 3, 0]),
      sampleRate: 12000,
      channels: 2,
    );
    final resampled = normalizeSpeechPcm(pcm);
    expect(resampled, hasLength(8));
    final compact = SpeechPcm(resampled, sampleRate: 24000);
    final wave = encodeSpeechWave(compact);
    final read = decodeSpeechWave(wave);
    expect(read.bytes, resampled);
    expect(read.frames, 4);
    expect(
      () => decodeSpeechWave(Uint8List.sublistView(wave, 0, wave.length - 1)),
      throwsA(isA<AiException>()),
    );
  });

  test('planner preserves joined graphemes and the final structural pause', () {
    const combined = '👩🏽‍💻';
    const pause = Duration(milliseconds: 350);
    final plan = planSpeechChunks([
      const SpeechSegment(
        'Prix. Au revoir $combined',
        pauseAfter: pause,
        language: 'fr',
      ),
    ], 17);
    expect(plan.map((chunk) => chunk.text), ['Prix.', 'Au revoir', combined]);
    expect(plan.map((chunk) => chunk.pauseAfter), [
      Duration.zero,
      Duration.zero,
      pause,
    ]);
    expect(plan.every((chunk) => chunk.language == 'fr'), true);
    expect(
      () => planSpeechChunks([const SpeechSegment(combined)], 2),
      throwsA(isA<AiException>()),
    );
  });

  test(
    'Gemini requests annotated content and reads actual WAV metadata',
    () async {
      final expected = SpeechPcm(
        Uint8List.fromList([0, 0, 1, 0]),
        sampleRate: 16000,
      );
      final httpClient = MockClient((request) async {
        expect(request.url.path, '/v1beta/interactions');
        expect(request.followRedirects, false);
        expect(request.headers['x-goog-api-key'], 'fixture');
        final body = jsonDecode(request.body) as Map;
        expect(body['store'], false);
        expect(body['response_format']['mime_type'], 'audio/wav');
        expect(body['input'][0]['content'][0], {
          'type': 'text',
          'text': 'Bonjour !',
          'annotations': [
            {'type': 'speech_metadata', 'style': 'calm'},
          ],
        });
        return http.Response(
          jsonEncode({
            'status': 'completed',
            'steps': [
              {
                'type': 'model_output',
                'content': [
                  {
                    'type': 'audio',
                    'mime_type': 'audio/wav',
                    'sample_rate': 16000,
                    'data': base64Encode(encodeSpeechWave(expected)),
                  },
                ],
              },
            ],
          }),
          200,
        );
      });
      addTearDown(httpClient.close);
      final provider = GeminiSpeechProvider(
        client: httpClient,
        key: 'fixture',
        options: const SpeechOptions(
          backend: SpeechBackend.gemini,
          style: 'calm',
        ),
      );
      final session = await provider.open(token);
      final result = await session.synthesize(
        'Bonjour !',
        cancellationToken: token,
      );
      expect(result.pcm.sampleRate, 16000);
      expect(result.pcm.bytes, expected.bytes);
    },
  );

  test(
    'Gemini streaming assembles odd PCM fragments and requires completion',
    () async {
      for (final completed in [true, false]) {
        final client = MockClient.streaming((request, bodyStream) async {
          expect(request.url.queryParameters['alt'], 'sse');
          final body = jsonDecode(await bodyStream.bytesToString()) as Map;
          expect(body['response_format']['mime_type'], 'audio/l16');
          final events = <Map<String, Object?>>[
            {
              'event_type': 'step.delta',
              'index': 1,
              'delta': {
                'type': 'audio',
                'mime_type': 'audio/l16',
                'sample_rate': 16000,
                'data': 'AQ==',
              },
            },
            {
              'event_type': 'step.delta',
              'index': 1,
              'delta': {'type': 'audio', 'data': 'AAIA'},
            },
            if (completed)
              {
                'event_type': 'interaction.completed',
                'interaction': {'status': 'completed'},
              },
          ];
          final bytes = utf8.encode(
            events.map((event) => 'data: ${jsonEncode(event)}\r\n\r\n').join(),
          );
          return http.StreamedResponse(
            Stream.fromIterable(bytes.map((byte) => [byte])),
            200,
            headers: {'content-type': 'text/event-stream'},
          );
        });
        addTearDown(client.close);
        final session = await GeminiSpeechProvider(
          client: client,
          key: 'fixture',
          streaming: true,
          options: const SpeechOptions(backend: SpeechBackend.gemini),
        ).open(token);
        final result = session.synthesize(
          'Bonjour !',
          cancellationToken: token,
        );
        if (completed) {
          final chunk = await result;
          expect(chunk.pcm.sampleRate, 16000);
          expect(chunk.pcm.bytes, [1, 0, 2, 0]);
        } else {
          await expectLater(
            result,
            throwsA(_speechError(AiFailureCode.malformedResponse)),
          );
        }
      }
    },
  );

  test(
    'ElevenLabs discovers paginated voices separately from speech',
    () async {
      final requests = <String>[];
      final client = MockClient((request) async {
        expect(request.headers['xi-api-key'], 'fixture');
        requests.add(request.url.path);
        switch (request.url.path) {
          case '/v1/models':
            return http.Response(
              jsonEncode([
                {'model_id': 'invalid', 'can_do_text_to_speech': false},
                {
                  'model_id': 'voice-model',
                  'can_do_text_to_speech': true,
                  'maximum_text_length_per_request': 1250,
                },
              ]),
              200,
            );
          case '/v2/voices':
            final next = request.url.queryParameters['next_page_token'];
            return http.Response(
              jsonEncode({
                'voices': [
                  {'voice_id': next == null ? 'abc' : 'def', 'name': 'Voice'},
                ],
                'has_more': next == null,
                'next_page_token': next == null ? 'next' : null,
              }),
              200,
            );
          default:
            fail('Metadata discovery must send no synthesis request.');
        }
      });
      addTearDown(client.close);
      final limits = ElevenLabsModelLimits();
      final provider = ElevenLabsSpeechProvider(
        client: client,
        key: 'fixture',
        options: const SpeechOptions(backend: SpeechBackend.elevenLabs),
        modelLimits: limits,
      );
      final catalog = await provider.discover(token);
      expect(catalog.models.single.maximumInputBytes, 1250);
      expect(catalog.voices.map((entry) => entry.id), ['abc', 'def']);
      expect(requests, ['/v1/models', '/v2/voices', '/v2/voices']);
      ElevenLabsSpeechProvider generationAccount(String key) =>
          ElevenLabsSpeechProvider(
            client: client,
            key: key,
            options: const SpeechOptions(
              backend: SpeechBackend.elevenLabs,
              model: 'voice-model',
            ),
            modelLimits: limits,
          );
      expect(generationAccount('fixture').maximumInputBytes, 1250);
      expect(generationAccount('different-fixture').maximumInputBytes, 1800);
    },
  );

  test(
    'ElevenLabs complete and streaming paths validate MIME, lengths and quota',
    () async {
      for (final stream in [true, false]) {
        final client = MockClient.streaming((request, bodyStream) async {
          expect(
            request.url.path,
            '/v1/text-to-speech/abc${stream ? '/stream' : ''}',
          );
          expect(request.url.queryParameters['output_format'], 'pcm_24000');
          final payload = jsonDecode(await bodyStream.bytesToString()) as Map;
          expect(payload['language_code'], 'fr');
          if (payload['text'] == 'quota') {
            return http.StreamedResponse(
              const Stream.empty(),
              429,
              headers: {'retry-after': '3'},
            );
          }
          return http.StreamedResponse(
            Stream.fromIterable([
              [1],
              [0, 2],
              [0],
            ]),
            200,
            headers: {
              'content-type': payload['text'] == 'bad'
                  ? 'audio/mpeg'
                  : 'audio/pcm',
              'character-cost': '9',
            },
            contentLength: 4,
          );
        });
        addTearDown(client.close);
        final session = await ElevenLabsSpeechProvider(
          client: client,
          key: 'fixture',
          streaming: stream,
          options: const SpeechOptions(
            backend: SpeechBackend.elevenLabs,
            model: 'flash-v2.5',
            voice: 'abc',
          ),
        ).open(token);
        final result = await session.synthesize(
          'Bonjour !',
          language: 'fr-CA',
          cancellationToken: token,
        );
        expect(result.pcm.bytes, [1, 0, 2, 0]);
        expect(result.usage?.characters, 9);
        final malformed = SpeechRequestUsage();
        await expectLater(
          session.synthesize(
            'bad',
            language: 'fr',
            cancellationToken: token,
            requestUsage: malformed,
          ),
          throwsA(_speechError(AiFailureCode.malformedResponse)),
        );
        expect(malformed.sent, isTrue);
        expect(malformed.reported?.characters, 9);
        final quota = SpeechRequestUsage();
        await expectLater(
          session.synthesize(
            'quota',
            language: 'fr',
            cancellationToken: token,
            requestUsage: quota,
          ),
          throwsA(_speechError(AiFailureCode.rateLimited)),
        );
        expect(quota.sent, isTrue);
        expect(quota.reported?.characters, isNull);
      }
    },
  );

  test(
    'ElevenLabs resolves persisted model limits before sending text',
    () async {
      final support = await Directory.systemTemp.createTemp(
        'elevenlabs-cold-start-',
      );
      addTearDown(() => support.delete(recursive: true));
      final calls = <(String, String)>[];
      final input = List.filled(1500, 'a').join();
      final sent = <String>[];
      var metadataAccess = false;
      final service = SpeechService(
        credentials: const _ColdStartSpeechCredentials(),
        usageLedger: SpeechUsageLedger(supportDirectory: () async => support),
        client: () => MockClient((request) async {
          expect(
            request.headers['xi-api-key'],
            'cold-start-fixture-credential',
          );
          calls.add((request.method, request.url.path));
          if (request.url.path == '/v1/models') {
            expect(request.body, isEmpty);
            if (!metadataAccess) return http.Response('', 403);
            return http.Response(
              jsonEncode([
                {
                  'model_id': 'persisted-model',
                  'can_do_text_to_speech': true,
                  'maximum_text_length_per_request': 1250,
                },
              ]),
              200,
            );
          }
          expect(request.url.path, '/v1/text-to-speech/kept-voice/stream');
          final body = jsonDecode(request.body) as Map;
          expect(body['model_id'], 'persisted-model');
          final text = body['text'] as String;
          expect(utf8.encode(text).length, lessThanOrEqualTo(1250));
          sent.add(text);
          return http.Response.bytes(
            [1, 0],
            200,
            headers: {
              'content-type': 'audio/pcm',
              'character-cost': text.length.toString(),
            },
          );
        }),
      );
      final options = SpeechPreferences.fromJson({
        'backend': 'elevenLabs',
        'providers': {
          'elevenLabs': {'model': 'persisted-model', 'voice': 'kept-voice'},
        },
      }).options;

      final usage = File('${support.path}/speech-usage.json');
      await expectLater(
        service.generate(
          [SpeechSegment(input)],
          options,
          cancellationToken: token,
        ),
        throwsA(
          isA<AiException>()
              .having((error) => error.statusCode, 'statusCode', 403)
              .having(
                (error) => error.message,
                'message',
                contains('ElevenLabs model limits'),
              ),
        ),
      );
      expect(calls, [('GET', '/v1/models')]);
      expect(service.latestSynthesisWasSent, isFalse);
      expect(await usage.exists(), isFalse);

      metadataAccess = true;
      final result = await service.generate(
        [SpeechSegment(input)],
        options,
        cancellationToken: token,
      );
      expect(calls, [
        ('GET', '/v1/models'),
        ('GET', '/v1/models'),
        ('POST', '/v1/text-to-speech/kept-voice/stream'),
        ('POST', '/v1/text-to-speech/kept-voice/stream'),
      ]);
      expect(sent.map((part) => utf8.encode(part).length), [1250, 250]);
      expect(sent.join(), input);
      expect(decodeSpeechWave(result.wavBytes).bytes, [1, 0, 1, 0]);
      expect(jsonDecode(await usage.readAsString())['elevenLabs'], {
        'requests': 2,
        'characters': 1500,
      });
    },
  );

  test(
    'Realtime requires correlated final status and faithful transcript',
    () async {
      for (final (status, transcript, failure) in [
        ('completed', 'Maya found forty-two pages.', null),
        ('incomplete', 'Maya found forty-two pages.', AiFailureCode.rejected),
        ('completed', 'Maya found forty pages.', AiFailureCode.validation),
      ]) {
        final fixture = await _RealtimeFixture.start(status, transcript);
        addTearDown(fixture.close);
        final observations = <SpeechUsage>[];
        final session = await OpenAiSpeechProvider(
          key: 'fixture',
          options: const SpeechOptions(backend: SpeechBackend.openai),
          connect: (model, key, token) => WebSocket.connect(fixture.url),
          onUsage: observations.add,
        ).open(token);
        addTearDown(session.close);
        final result = session.synthesize(
          'Maya found 42 pages.',
          language: 'en',
          cancellationToken: token,
        );
        if (failure != null) {
          await expectLater(result, throwsA(_speechError(failure)));
        } else {
          expect((await result).pcm.bytes, [1, 0, 2, 0]);
        }
        expect(observations.single.outputAudioTokens, 21);
        await session.close();
      }
    },
  );

  test(
    'Realtime cancellation targets exactly the created out-of-band response',
    () async {
      final fixture = await _RealtimeFixture.start(
        'cancelled',
        '',
        awaitCancel: true,
      );
      addTearDown(fixture.close);
      final session = await OpenAiSpeechProvider(
        key: 'fixture',
        options: const SpeechOptions(backend: SpeechBackend.openai),
        connect: (model, key, token) => WebSocket.connect(fixture.url),
      ).open(token);
      final synthesis = session.synthesize(
        'Bonjour.',
        cancellationToken: token,
      );
      final cancelled = expectLater(
        synthesis,
        throwsA(_speechError(AiFailureCode.cancelled)),
      );
      await fixture.created.future;
      token.cancel();
      await cancelled;
      expect(await fixture.cancelled.future, 'response-fixture');
    },
  );

  test(
    'Realtime ledger counts each terminal attempt independently of audio',
    () async {
      final support = await Directory.systemTemp.createTemp(
        'speech-usage-test-',
      );
      addTearDown(() => support.delete(recursive: true));
      final ledger = SpeechUsageLedger(supportDirectory: () async => support);
      const options = SpeechOptions(backend: SpeechBackend.openai);
      for (final (status, transcript, usage, failure) in [
        ('incomplete', 'Maya found 42 pages.', true, AiFailureCode.rejected),
        ('failed', 'Maya found 42 pages.', true, AiFailureCode.rejected),
        ('completed', 'Maya found 40 pages.', true, AiFailureCode.validation),
        ('incomplete', 'Maya found 42 pages.', false, AiFailureCode.rejected),
      ]) {
        final fixture = await _RealtimeFixture.start(
          status,
          transcript,
          includeUsage: usage,
        );
        addTearDown(fixture.close);
        final service = _realtimeService(fixture, ledger);
        await expectLater(
          service.generate(
            [const SpeechSegment('Maya found 42 pages.')],
            options,
            cancellationToken: token,
          ),
          throwsA(_speechError(failure)),
        );
      }

      final fixture = await _RealtimeFixture.start(
        'cancelled',
        '',
        awaitCancel: true,
      );
      addTearDown(fixture.close);
      final service = _realtimeService(fixture, ledger);
      final generating = service.generate(
        [const SpeechSegment('Cancel this narration sample.')],
        options,
        cancellationToken: token,
      );
      final cancelled = expectLater(
        generating,
        throwsA(_speechError(AiFailureCode.cancelled)),
      );
      await fixture.created.future;
      token.cancel();
      await cancelled;
      expect(await fixture.cancelled.future, 'response-fixture');

      final content = await File(
        '${support.path}/speech-usage.json',
      ).readAsString();
      expect(jsonDecode(content)['openai'], {
        'requests': 5,
        'unreportedRequests': 1,
        'inputTokens': 160,
        'outputTokens': 100,
        'outputAudioTokens': 84,
      });
      expect(content, isNot(contains('response-fixture')));
      expect(content, isNot(contains('Maya')));
    },
  );

  test(
    'ledger retains completed paid chunks once across failure and resume',
    () async {
      final support = await Directory.systemTemp.createTemp(
        'speech-resume-test-',
      );
      addTearDown(() => support.delete(recursive: true));
      final provider = _ResumableSpeech();
      final service = SpeechService(
        providerFactory: (_) => provider,
        usageLedger: SpeechUsageLedger(supportDirectory: () async => support),
      );
      const segments = [
        SpeechSegment('First chunk'),
        SpeechSegment('Second chunk'),
      ];
      const options = SpeechOptions(backend: SpeechBackend.openai);

      await expectLater(
        service.generate(segments, options, cancellationToken: token),
        throwsA(_speechError(AiFailureCode.rejected)),
      );
      final ledger = File('${support.path}/speech-usage.json');
      expect(jsonDecode(await ledger.readAsString())['openai'], {
        'requests': 2,
        'inputTokens': 12,
        'outputTokens': 0,
      });

      final resumed = await service.generate(
        segments,
        options,
        cancellationToken: token,
        resumeCompletedChunks: true,
      );
      expect(decodeSpeechWave(resumed.wavBytes).bytes, [1, 0, 2, 0]);
      expect(provider.calls, ['First chunk', 'Second chunk', 'Second chunk']);
      expect(jsonDecode(await ledger.readAsString())['openai'], {
        'requests': 3,
        'inputTokens': 17,
        'outputTokens': 0,
      });
    },
  );

  test(
    'persisted speeds retain their numbers and validate by provider',
    () async {
      final support = await Directory.systemTemp.createTemp(
        'speech-speed-test-',
      );
      addTearDown(() => support.delete(recursive: true));
      final ledger = SpeechUsageLedger(supportDirectory: () async => support);
      for (final (backend, accepted, rejected) in [
        (SpeechBackend.espeak, 2.0, 2.1),
        (SpeechBackend.piper, 0.5, 0.49),
        (SpeechBackend.openai, 1.5, 1.51),
        (SpeechBackend.elevenLabs, 0.7, 0.69),
      ]) {
        SpeechOptions stored(double speed) => SpeechPreferences.fromJson({
          'backend': backend.name,
          'providers': {
            backend.name: {'speed': speed},
          },
        }).options;
        expect(stored(accepted).speed, accepted);
        expect(stored(rejected).speed, rejected);

        final provider = _ResumableSpeech();
        final observed = <double>[];
        final service = SpeechService(
          usageLedger: ledger,
          providerFactory: (options) {
            observed.add(options.speed);
            return provider;
          },
        );
        await service.generate(
          [const SpeechSegment('First chunk')],
          stored(accepted),
          cancellationToken: token,
        );
        await expectLater(
          service.generate(
            [const SpeechSegment('First chunk')],
            stored(rejected),
            cancellationToken: token,
          ),
          throwsA(_speechError(AiFailureCode.invalidConfiguration)),
        );
        expect(observed, [accepted]);
      }
    },
  );

  test(
    'completed audio and its usage survive a stop before the next chunk',
    () async {
      final support = await Directory.systemTemp.createTemp(
        'speech-stop-test-',
      );
      addTearDown(() => support.delete(recursive: true));
      final provider = _ResumableSpeech(failSecondOnce: false);
      final service = SpeechService(
        providerFactory: (_) => provider,
        usageLedger: SpeechUsageLedger(supportDirectory: () async => support),
      );
      const options = SpeechOptions(backend: SpeechBackend.openai);
      const segments = [
        SpeechSegment('First chunk'),
        SpeechSegment('Second chunk'),
      ];
      final stopped = service.generate(
        segments,
        options,
        cancellationToken: token,
        onProgress: (completed, _) {
          if (completed == 1) token.cancel();
        },
      );
      await expectLater(
        stopped,
        throwsA(_speechError(AiFailureCode.cancelled)),
      );
      final ledger = File('${support.path}/speech-usage.json');
      expect(jsonDecode(await ledger.readAsString())['openai']['requests'], 1);

      final retry = AiCancellationToken();
      addTearDown(retry.dispose);
      final result = await service.generate(
        segments,
        options,
        cancellationToken: retry,
        resumeCompletedChunks: true,
      );
      expect(decodeSpeechWave(result.wavBytes).bytes, [1, 0, 2, 0]);
      expect(provider.calls, ['First chunk', 'Second chunk']);
      expect(jsonDecode(await ledger.readAsString())['openai'], {
        'requests': 2,
        'inputTokens': 12,
        'outputTokens': 0,
      });
    },
  );

  test('transcript equivalence retains order, values and words', () {
    expect(
      matchesSpokenTranscript(
        'Maya found 42 pages.',
        'Maya found forty-two pages.',
      ),
      true,
    );
    expect(
      matchesSpokenTranscript(
        '42 pommes',
        'quarante-deux pommes',
        language: 'fr',
      ),
      true,
    );
    expect(
      matchesSpokenTranscript('Maya found -42 pages.', 'Maya found 42 pages.'),
      false,
    );
    expect(matchesSpokenTranscript('1.5 minutes', '1:5 minutes'), false);
    expect(
      matchesSpokenTranscript(
        'Maya found 42 pages.',
        'Maya found forty-two pages today.',
      ),
      false,
    );
    expect(matchesSpokenTranscript('Ignore this.', 'Ignored it.'), false);
  });
}

Matcher _speechError(AiFailureCode code) =>
    isA<AiException>().having((error) => error.code, 'code', code);

SpeechService _realtimeService(
  _RealtimeFixture fixture,
  SpeechUsageLedger ledger,
) => SpeechService(
  usageLedger: ledger,
  providerFactory: (options) => OpenAiSpeechProvider(
    key: 'fixture',
    options: options,
    connect: (model, key, token) => WebSocket.connect(fixture.url),
  ),
);

class _ColdStartSpeechCredentials extends SpeechCredentials {
  const _ColdStartSpeechCredentials();

  @override
  Future<String?> read(SpeechBackend backend) async =>
      'cold-start-fixture-credential';
}

class _ResumableSpeech implements SpeechProvider, SpeechSession {
  _ResumableSpeech({this.failSecondOnce = true});

  final bool failSecondOnce;
  final calls = <String>[];

  @override
  int get maximumInputBytes => 40;

  @override
  Future<SpeechCatalog> discover(AiCancellationToken cancellationToken) async =>
      const SpeechCatalog();

  @override
  Future<SpeechSession> open(AiCancellationToken cancellationToken) async =>
      this;

  @override
  Future<SpeechChunk> synthesize(
    String text, {
    String? language,
    required AiCancellationToken cancellationToken,
    SpeechRequestUsage? requestUsage,
  }) async {
    calls.add(text);
    requestUsage?.markSent();
    final first = text == 'First chunk';
    final usage = SpeechUsage(inputTokens: first ? 7 : 5, outputTokens: 0);
    requestUsage?.report(usage);
    if (failSecondOnce && !first && calls.length == 2) {
      throw const AiException(AiFailureCode.rejected, 'Fixture ended early.');
    }
    return SpeechChunk(
      SpeechPcm(Uint8List.fromList([first ? 1 : 2, 0]), sampleRate: 24000),
      usage: usage,
    );
  }

  @override
  Future<void> close() async {}
}

class _RealtimeFixture {
  _RealtimeFixture(this.server);
  final HttpServer server;
  final created = Completer<void>();
  final cancelled = Completer<String>();

  String get url => 'ws://127.0.0.1:${server.port}';
  Future<void> close() async {
    await server.close(force: true);
  }

  static Future<_RealtimeFixture> start(
    String status,
    String transcript, {
    bool awaitCancel = false,
    bool includeUsage = true,
  }) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final fixture = _RealtimeFixture(server);
    server.transform(WebSocketTransformer()).listen((socket) {
      void send(Map<String, Object?> event) => socket.add(jsonEncode(event));
      const responseId = 'response-fixture';
      const part = {
        'response_id': responseId,
        'item_id': 'item',
        'output_index': 0,
        'content_index': 0,
      };
      void done(String terminalStatus) => send({
        'type': 'response.done',
        'response': {
          'id': responseId,
          'status': terminalStatus,
          if (includeUsage)
            'usage': {
              'input_tokens': 40,
              'output_tokens': 25,
              'output_token_details': {'audio_tokens': 21},
            },
        },
      });
      socket.listen((data) {
        final event = jsonDecode(data as String) as Map;
        switch (event['type']) {
          case 'session.update':
            final settings = Map<String, Object?>.from(event['session'] as Map);
            send({
              'type': 'session.updated',
              'session': {...settings, 'model': OpenAiSpeechProvider.model},
            });
          case 'response.create':
            final response = event['response'] as Map;
            expect(response['conversation'], 'none');
            expect(response['tool_choice'], 'none');
            send({
              'type': 'response.created',
              'response': {'id': responseId, 'metadata': response['metadata']},
            });
            fixture.created.complete();
            if (awaitCancel) return;
            send({
              ...part,
              'response_id': 'unrelated',
              'type': 'response.output_audio.delta',
              'delta': 'junk',
            });
            send({
              ...part,
              'type': 'response.output_audio.delta',
              'delta': 'AQ==',
            });
            send({
              ...part,
              'type': 'response.output_audio.delta',
              'delta': 'AAIA',
            });
            send({...part, 'type': 'response.output_audio.done'});
            send({
              ...part,
              'type': 'response.output_audio_transcript.done',
              'transcript': transcript,
            });
            done(status);
          case 'response.cancel':
            fixture.cancelled.complete(event['response_id'] as String);
            done('cancelled');
        }
      });
    });
    return fixture;
  }
}
