import 'dart:convert';

import 'package:busymark/src/ai/ai_models.dart';
import 'package:busymark/src/ai/ai_secret_store.dart';
import 'package:busymark/src/ai/gemini_ai_provider.dart';
import 'package:busymark/src/ai/openai_ai_provider.dart';
import 'package:busymark/src/ai/sse_decoder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('SSE decoder handles split UTF-8 frames and multiline data', () async {
    final encoded = utf8.encode(
      'event: update\n'
      'data: {"text":"Grü\n'
      'data: ße"}\n\n'
      'data: [DONE]\n\n',
    );
    final events = await const SseDecoder()
        .decode(
          Stream.fromIterable([
            encoded.sublist(0, 11),
            encoded.sublist(11, 25),
            encoded.sublist(25, 31),
            encoded.sublist(31),
          ]),
        )
        .toList();

    expect(events, hasLength(2));
    expect(events.first.event, 'update');
    expect(events.first.data, '{"text":"Grü\nße"}');
    expect(events.last.data, '[DONE]');
  });

  test(
    'OpenAI Responses adapter is stateless and maps text and usage',
    () async {
      late http.BaseRequest captured;
      final client = _StreamingClient((request) {
        captured = request;
        return _sseResponse([
          {'type': 'response.output_text.delta', 'delta': 'Clear'},
          {'type': 'response.output_text.delta', 'delta': ' prose.'},
          {
            'type': 'response.completed',
            'response': {
              'usage': {'input_tokens': 19, 'output_tokens': 4},
            },
          },
        ]);
      });
      final secrets = _MemorySecretStore()..openAi = 'openai-secret';
      final provider = OpenAiProvider(client: client, secretStore: secrets);
      final token = AiCancellationToken();

      final events = await provider
          .stream(
            _request(provider: AiProviderKind.openAi, model: 'gpt-5.6-luna'),
            cancellationToken: token,
          )
          .toList();

      expect(captured.url, Uri.https('api.openai.com', '/v1/responses'));
      expect(captured.followRedirects, isFalse);
      expect(captured.headers['authorization'], 'Bearer openai-secret');
      final body = jsonDecode((captured as http.Request).body) as Map;
      expect(body['stream'], isTrue);
      expect(body['store'], isFalse);
      expect(body['model'], 'gpt-5.6-luna');
      expect(body['max_output_tokens'], 4800);
      expect(
        events.whereType<AiTextDelta>().map((event) => event.text).join(),
        'Clear prose.',
      );
      final usage = events.whereType<AiUsageEvent>().single.usage;
      expect(usage.inputTokens, 19);
      expect(usage.outputTokens, 4);
      expect(usage.providerId, AiProviderKind.openAi.id);
      expect(events.whereType<AiCompleted>(), hasLength(1));
      await token.dispose();
    },
  );

  test(
    'Gemini Interactions adapter uses stable v1 and text deltas only',
    () async {
      late http.BaseRequest captured;
      final client = _StreamingClient((request) {
        captured = request;
        return _sseResponse([
          {
            'event_type': 'step.delta',
            'delta': {'type': 'thought_signature', 'signature': 'ignored'},
          },
          {
            'event_type': 'step.delta',
            'delta': {'type': 'text', 'text': 'Revised text.'},
          },
          {
            'event_type': 'interaction.completed',
            'interaction': {
              'status': 'completed',
              'usage': {'total_input_tokens': 23, 'total_output_tokens': 5},
            },
          },
        ]);
      });
      final secrets = _MemorySecretStore()..gemini = 'gemini-secret';
      final provider = GeminiAiProvider(client: client, secretStore: secrets);
      final token = AiCancellationToken();

      final events = await provider
          .stream(
            _request(
              provider: AiProviderKind.gemini,
              model: 'gemini-3.6-flash',
            ),
            cancellationToken: token,
          )
          .toList();

      expect(
        captured.url,
        Uri.https('generativelanguage.googleapis.com', '/v1/interactions', {
          'alt': 'sse',
        }),
      );
      expect(captured.followRedirects, isFalse);
      expect(captured.headers['x-goog-api-key'], 'gemini-secret');
      final body = jsonDecode((captured as http.Request).body) as Map;
      expect(body['stream'], isTrue);
      expect(body['store'], isFalse);
      expect(body['tools'], isNull);
      expect((body['generation_config'] as Map)['thinking_level'], 'minimal');
      expect(
        events.whereType<AiTextDelta>().map((event) => event.text).join(),
        'Revised text.',
      );
      final usage = events.whereType<AiUsageEvent>().single.usage;
      expect(usage.inputTokens, 23);
      expect(usage.outputTokens, 5);
      expect(usage.providerId, AiProviderKind.gemini.id);
      await token.dispose();
    },
  );

  test('cloud provider never includes a secret in surfaced failures', () async {
    const secret = 'never-log-this-key';
    final provider = OpenAiProvider(
      client: _StreamingClient(
        (_) => http.StreamedResponse(Stream.value(const []), 401),
      ),
      secretStore: _MemorySecretStore()..openAi = secret,
    );
    final token = AiCancellationToken();

    Object? failure;
    try {
      await provider
          .stream(
            _request(provider: AiProviderKind.openAi, model: 'gpt-5.6-luna'),
            cancellationToken: token,
          )
          .toList();
    } on Object catch (error) {
      failure = error;
    }

    expect(failure, isA<AiException>());
    expect(failure.toString(), isNot(contains(secret)));
    await token.dispose();
  });

  test('cloud provider rejects malformed usage records', () async {
    final provider = OpenAiProvider(
      client: _StreamingClient(
        (_) => _sseResponse([
          {'type': 'response.output_text.delta', 'delta': 'Proposal'},
          {
            'type': 'response.completed',
            'response': {
              'usage': {'input_tokens': 'invalid', 'output_tokens': 4},
            },
          },
        ]),
      ),
      secretStore: _MemorySecretStore()..openAi = 'key',
    );
    final token = AiCancellationToken();

    await expectLater(
      provider
          .stream(
            _request(provider: AiProviderKind.openAi, model: 'gpt-5.6-luna'),
            cancellationToken: token,
          )
          .toList(),
      throwsA(
        isA<AiException>().having(
          (error) => error.code,
          'code',
          AiFailureCode.malformedResponse,
        ),
      ),
    );
    await token.dispose();
  });

  test('Gemini rejects an incomplete status update', () async {
    final provider = GeminiAiProvider(
      client: _StreamingClient(
        (_) => _sseResponse([
          {
            'event_type': 'interaction.status_update',
            'interaction_id': 'test',
            'status': 'incomplete',
          },
        ]),
      ),
      secretStore: _MemorySecretStore()..gemini = 'key',
    );
    final token = AiCancellationToken();

    await expectLater(
      provider
          .stream(
            _request(
              provider: AiProviderKind.gemini,
              model: 'gemini-3.6-flash',
            ),
            cancellationToken: token,
          )
          .toList(),
      throwsA(
        isA<AiException>().having(
          (error) => error.code,
          'code',
          AiFailureCode.validation,
        ),
      ),
    );
    await token.dispose();
  });

  test('cloud provider rejects EOF without a typed completion event', () async {
    final provider = GeminiAiProvider(
      client: _StreamingClient(
        (_) => _sseResponse([
          {
            'event_type': 'step.delta',
            'delta': {'type': 'text', 'text': 'Partial'},
          },
        ]),
      ),
      secretStore: _MemorySecretStore()..gemini = 'key',
    );
    final token = AiCancellationToken();

    await expectLater(
      provider
          .stream(
            _request(
              provider: AiProviderKind.gemini,
              model: 'gemini-3.6-flash',
            ),
            cancellationToken: token,
          )
          .toList(),
      throwsA(
        isA<AiException>().having(
          (error) => error.code,
          'code',
          AiFailureCode.malformedResponse,
        ),
      ),
    );
    await token.dispose();
  });
}

AiRequest _request({required AiProviderKind provider, required String model}) =>
    AiPromptBuilder.build(
      id: 'cloud-request',
      targetId: 'document:selection',
      provider: provider,
      feature: AiFeature.editDocument,
      scope: AiScope.markdownEdit,
      input: 'Unclear prose.',
      modelCandidates: [model],
      sourceRevision: 1,
      editTarget: AiEditTargetKind.selection,
      editContext: AiEditContextKind.selection,
      instruction: 'Rewrite for clarity.',
    );

http.StreamedResponse _sseResponse(List<Map<String, Object?>> records) {
  final bytes = utf8.encode(
    records.map((record) => 'data: ${jsonEncode(record)}\n\n').join(),
  );
  final first = (bytes.length / 3).floor().clamp(1, bytes.length);
  final second = (bytes.length * 2 / 3).floor().clamp(first, bytes.length);
  return http.StreamedResponse(
    Stream.fromIterable([
      bytes.sublist(0, first),
      bytes.sublist(first, second),
      bytes.sublist(second),
    ]),
    200,
    headers: const {'content-type': 'text/event-stream'},
  );
}

class _StreamingClient extends http.BaseClient {
  _StreamingClient(this.handler);

  final http.StreamedResponse Function(http.BaseRequest request) handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async =>
      handler(request);
}

class _MemorySecretStore implements AiSecretStore {
  String? openAi;
  String? gemini;

  @override
  Future<void> delete(AiProviderKind provider) async {
    if (provider == AiProviderKind.openAi) {
      openAi = null;
    } else if (provider == AiProviderKind.gemini) {
      gemini = null;
    }
  }

  @override
  Future<String?> read(AiProviderKind provider) async => switch (provider) {
    AiProviderKind.openAi => openAi,
    AiProviderKind.gemini => gemini,
    AiProviderKind.ollamaLocal => null,
  };

  @override
  Future<void> write(AiProviderKind provider, String secret) async {
    if (provider == AiProviderKind.openAi) {
      openAi = secret;
    } else if (provider == AiProviderKind.gemini) {
      gemini = secret;
    }
  }
}
