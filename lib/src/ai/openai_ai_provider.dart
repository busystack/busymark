import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'ai_http_transport.dart';
import 'ai_models.dart';
import 'ai_policy.dart';
import 'ai_provider.dart';
import 'ai_secret_store.dart';
import 'sse_decoder.dart';

class OpenAiProvider implements AiProvider {
  OpenAiProvider({
    required http.Client client,
    required AiSecretStore secretStore,
    this.transport = const AiHttpTransport(),
    this.sseDecoder = const SseDecoder(),
    Uri? endpoint,
  }) : _client = client,
       _secretStore = secretStore,
       endpoint = endpoint ?? Uri.https('api.openai.com', '/v1/responses');

  final http.Client _client;
  final AiSecretStore _secretStore;
  final AiHttpTransport transport;
  final SseDecoder sseDecoder;
  final Uri endpoint;

  static const supportedModels = <AiModelInfo>[
    AiModelInfo(
      name: 'gpt-5.6-luna',
      displayName: 'GPT-5.6 Luna',
      inputTokenLimit: 1050000,
      outputTokenLimit: 128000,
    ),
    AiModelInfo(
      name: 'gpt-5.6-terra',
      displayName: 'GPT-5.6 Terra',
      inputTokenLimit: 1050000,
      outputTokenLimit: 128000,
    ),
    AiModelInfo(
      name: 'gpt-5.6-sol',
      displayName: 'GPT-5.6 Sol',
      inputTokenLimit: 1050000,
      outputTokenLimit: 128000,
    ),
  ];

  @override
  String get id => AiProviderKind.openAi.id;

  @override
  AiProviderCapabilities get capabilities => const AiProviderCapabilities(
    kind: AiProviderKind.openAi,
    streaming: true,
    modelDiscovery: false,
    maximumConcurrentRequests: 2,
    recommendedModels: {
      AiModelClass.fast: ['gpt-5.6-luna', 'gpt-5.6-terra', 'gpt-5.6-sol'],
      AiModelClass.balanced: ['gpt-5.6-terra', 'gpt-5.6-luna', 'gpt-5.6-sol'],
      AiModelClass.strong: ['gpt-5.6-sol', 'gpt-5.6-terra', 'gpt-5.6-luna'],
      AiModelClass.code: ['gpt-5.6-sol', 'gpt-5.6-terra', 'gpt-5.6-luna'],
    },
  );

  @override
  Future<List<AiModelInfo>> listModels({
    AiCancellationToken? cancellationToken,
  }) async {
    cancellationToken?.throwIfCancelled();
    return supportedModels;
  }

  @override
  Future<AiHealthResult> checkHealth({
    required String model,
    required AiCancellationToken cancellationToken,
  }) async {
    final modelInfo = _requireSupportedModel(model);
    final request = AiPromptBuilder.build(
      id: 'openai-health',
      targetId: 'settings:openai-health',
      provider: AiProviderKind.openAi,
      feature: AiFeature.rewrite,
      scope: AiScope.selection,
      input: 'Connection test.',
      modelCandidates: [model],
      sourceRevision: 0,
      contentFormat: AiContentFormat.plainText,
      deadline: const Duration(seconds: 45),
      maxRetries: 0,
    );
    final output = StringBuffer();
    await for (final event in _streamRequest(
      request,
      cancellationToken,
      systemPrompt: 'Return exactly BUSYMARK_OK and nothing else.',
      userPrompt: 'Connection test.',
      maximumOutputTokens: 16,
    )) {
      if (event is AiTextDelta) {
        output.write(event.text);
      }
    }
    if (output.toString().trim() != 'BUSYMARK_OK') {
      throw const AiException(
        AiFailureCode.validation,
        'The selected OpenAI model did not pass the editing-generation test.',
      );
    }
    return AiHealthResult(
      model: modelInfo,
      models: supportedModels,
      generationVerified: true,
    );
  }

  @override
  Stream<AiStreamEvent> stream(
    AiRequest request, {
    required AiCancellationToken cancellationToken,
  }) {
    AiPolicy.validateRequest(request);
    _validateModelCapacity(request, _requireSupportedModel(request.model));
    return _streamRequest(request, cancellationToken);
  }

  Stream<AiStreamEvent> _streamRequest(
    AiRequest request,
    AiCancellationToken cancellationToken, {
    String? systemPrompt,
    String? userPrompt,
    int? maximumOutputTokens,
  }) async* {
    final deadline = AiDeadline(request.deadline);
    final key = await deadline.wait(
      _secretStore.read(AiProviderKind.openAi),
      cancellationToken,
      timeoutMessage: 'The system credential store did not respond.',
    );
    if (key == null) {
      throw const AiException(
        AiFailureCode.invalidConfiguration,
        'Save an OpenAI API key in Settings first.',
      );
    }
    final httpRequest =
        http.AbortableRequest(
            'POST',
            endpoint,
            abortTrigger: deadline.abortTrigger(cancellationToken),
          )
          ..followRedirects = false
          ..maxRedirects = 0
          ..headers.addAll({
            'authorization': 'Bearer $key',
            'content-type': 'application/json',
            'accept': 'text/event-stream',
          })
          ..body = jsonEncode({
            'model': request.model,
            'instructions': systemPrompt ?? request.systemPrompt,
            'input': userPrompt ?? request.userPrompt,
            'max_output_tokens': maximumOutputTokens ?? request.maxOutputTokens,
            'reasoning': {'effort': 'none'},
            'stream': true,
            'store': false,
          });
    final response = await transport.send(
      client: _client,
      request: httpRequest,
      cancellationToken: cancellationToken,
      deadline: deadline,
      providerName: 'OpenAI',
    );
    yield AiStarted(providerId: id, model: request.model);
    final events = StreamIterator(sseDecoder.decode(response.stream));
    var completed = false;
    try {
      while (await moveNextWithDeadline(
        events,
        cancellationToken,
        deadline,
        timeoutMessage: 'OpenAI did not finish before the request deadline.',
      )) {
        final event = events.current;
        if (event.data == '[DONE]') {
          break;
        }
        final data = _decodeObject(event.data, 'OpenAI stream event');
        final type = data['type']?.toString() ?? event.event ?? '';
        switch (type) {
          case 'response.output_text.delta':
            final delta = data['delta']?.toString() ?? '';
            if (delta.isNotEmpty) {
              yield AiTextDelta(delta);
            }
          case 'response.completed':
            final responseData = _object(data['response']);
            final usage = _object(responseData?['usage']);
            yield AiUsageEvent(
              AiUsage(
                inputTokens: _usageInt(usage?['input_tokens']),
                outputTokens: _usageInt(usage?['output_tokens']),
                providerId: id,
                model: request.model,
              ),
            );
            completed = true;
            yield const AiCompleted();
            return;
          case 'response.incomplete':
            throw const AiException(
              AiFailureCode.validation,
              'OpenAI reached a generation limit before completing the proposal.',
            );
          case 'response.failed' || 'error':
            throw const AiException(
              AiFailureCode.rejected,
              'OpenAI could not complete the generation request.',
            );
        }
      }
    } finally {
      unawaited(events.cancel());
    }
    if (!completed) {
      throw const AiException(
        AiFailureCode.malformedResponse,
        'OpenAI ended the response before completion.',
        retryable: true,
      );
    }
  }

  AiModelInfo _requireSupportedModel(String model) {
    for (final candidate in supportedModels) {
      if (candidate.name == model) {
        return candidate;
      }
    }
    throw const AiException(
      AiFailureCode.invalidConfiguration,
      'Choose a supported OpenAI text model in Settings.',
    );
  }

  void _validateModelCapacity(AiRequest request, AiModelInfo model) {
    final contextLimit = model.inputTokenLimit;
    final outputLimit = model.outputTokenLimit;
    if (contextLimit != null &&
        request.estimatedPromptTokens + request.maxOutputTokens >
            contextLimit) {
      throw const AiException(
        AiFailureCode.validation,
        'The AI request exceeds the selected OpenAI model context limit.',
      );
    }
    if (outputLimit != null && request.maxOutputTokens > outputLimit) {
      throw const AiException(
        AiFailureCode.validation,
        'The AI request exceeds the selected OpenAI model output limit.',
      );
    }
  }
}

Map<String, Object?> _decodeObject(String value, String source) {
  final Object? decoded;
  try {
    decoded = jsonDecode(value);
  } on FormatException {
    throw AiException(
      AiFailureCode.malformedResponse,
      '$source contained malformed JSON.',
    );
  }
  if (decoded is! Map) {
    throw AiException(
      AiFailureCode.malformedResponse,
      '$source had an unexpected shape.',
    );
  }
  return decoded.cast<String, Object?>();
}

Map<String, Object?>? _object(Object? value) =>
    value is Map ? value.cast<String, Object?>() : null;

int? _usageInt(Object? value) {
  if (value == null) {
    return null;
  }
  if (value case final int number when number >= 0) {
    return number;
  }
  throw const AiException(
    AiFailureCode.malformedResponse,
    'OpenAI returned malformed usage data.',
  );
}
