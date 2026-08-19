import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'ai_http_transport.dart';
import 'ai_models.dart';
import 'ai_policy.dart';
import 'ai_provider.dart';
import 'ai_secret_store.dart';
import 'sse_decoder.dart';

class GeminiAiProvider implements AiProvider {
  GeminiAiProvider({
    required http.Client client,
    required AiSecretStore secretStore,
    this.transport = const AiHttpTransport(),
    this.sseDecoder = const SseDecoder(),
    Uri? endpoint,
  }) : _client = client,
       _secretStore = secretStore,
       endpoint =
           endpoint ??
           Uri.https('generativelanguage.googleapis.com', '/v1/interactions', {
             'alt': 'sse',
           });

  final http.Client _client;
  final AiSecretStore _secretStore;
  final AiHttpTransport transport;
  final SseDecoder sseDecoder;
  final Uri endpoint;

  static const supportedModels = <AiModelInfo>[
    AiModelInfo(
      name: 'gemini-3.5-flash-lite',
      displayName: 'Gemini 3.5 Flash-Lite',
      inputTokenLimit: 1048576,
      outputTokenLimit: 65536,
    ),
    AiModelInfo(
      name: 'gemini-3.6-flash',
      displayName: 'Gemini 3.6 Flash',
      inputTokenLimit: 1048576,
      outputTokenLimit: 65536,
    ),
    AiModelInfo(
      name: 'gemini-3.5-flash',
      displayName: 'Gemini 3.5 Flash',
      inputTokenLimit: 1048576,
      outputTokenLimit: 65536,
    ),
  ];

  @override
  String get id => AiProviderKind.gemini.id;

  @override
  AiProviderCapabilities get capabilities => const AiProviderCapabilities(
    kind: AiProviderKind.gemini,
    streaming: true,
    modelDiscovery: false,
    maximumConcurrentRequests: 2,
    recommendedModels: {
      AiModelClass.fast: [
        'gemini-3.5-flash-lite',
        'gemini-3.6-flash',
        'gemini-3.5-flash',
      ],
      AiModelClass.balanced: [
        'gemini-3.6-flash',
        'gemini-3.5-flash',
        'gemini-3.5-flash-lite',
      ],
      AiModelClass.strong: [
        'gemini-3.5-flash',
        'gemini-3.6-flash',
        'gemini-3.5-flash-lite',
      ],
      AiModelClass.code: [
        'gemini-3.5-flash',
        'gemini-3.6-flash',
        'gemini-3.5-flash-lite',
      ],
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
      id: 'gemini-health',
      targetId: 'settings:gemini-health',
      provider: AiProviderKind.gemini,
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
        'The selected Gemini model did not pass the editing-generation test.',
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
      _secretStore.read(AiProviderKind.gemini),
      cancellationToken,
      timeoutMessage: 'The system credential store did not respond.',
    );
    if (key == null) {
      throw const AiException(
        AiFailureCode.invalidConfiguration,
        'Save a Gemini API key in Settings first.',
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
            'x-goog-api-key': key,
            'content-type': 'application/json',
            'accept': 'text/event-stream',
          })
          ..body = jsonEncode({
            'model': request.model,
            'system_instruction': systemPrompt ?? request.systemPrompt,
            'input': userPrompt ?? request.userPrompt,
            'stream': true,
            'store': false,
            'generation_config': {
              'max_output_tokens':
                  maximumOutputTokens ?? request.maxOutputTokens,
              'thinking_level': 'minimal',
            },
          });
    final response = await transport.send(
      client: _client,
      request: httpRequest,
      cancellationToken: cancellationToken,
      deadline: deadline,
      providerName: 'Gemini',
    );
    yield AiStarted(providerId: id, model: request.model);
    final events = StreamIterator(sseDecoder.decode(response.stream));
    var completed = false;
    try {
      while (await moveNextWithDeadline(
        events,
        cancellationToken,
        deadline,
        timeoutMessage: 'Gemini did not finish before the request deadline.',
      )) {
        final event = events.current;
        if (event.data == '[DONE]') {
          break;
        }
        final data = _decodeObject(event.data);
        final type =
            data['event_type']?.toString() ??
            data['type']?.toString() ??
            event.event ??
            '';
        switch (type) {
          case 'step.delta':
            final delta = _object(data['delta']);
            if (delta?['type'] == 'text') {
              final text = delta?['text']?.toString() ?? '';
              if (text.isNotEmpty) {
                yield AiTextDelta(text);
              }
            }
          case 'interaction.completed':
            final interaction = _object(data['interaction']);
            if (interaction?['status']?.toString() != 'completed') {
              throw const AiException(
                AiFailureCode.rejected,
                'Gemini did not complete the generation request.',
              );
            }
            final usage = _object(interaction?['usage']);
            yield AiUsageEvent(
              AiUsage(
                inputTokens: _usageInt(
                  usage?['total_input_tokens'] ?? usage?['prompt_tokens'],
                ),
                outputTokens: _usageInt(
                  usage?['total_output_tokens'] ?? usage?['completion_tokens'],
                ),
                providerId: id,
                model: request.model,
              ),
            );
            completed = true;
            yield const AiCompleted();
            return;
          case 'interaction.status_update':
            final status = data['status']?.toString();
            if (status == 'incomplete' || status == 'budget_exceeded') {
              throw const AiException(
                AiFailureCode.validation,
                'Gemini reached a generation limit before completing the proposal.',
              );
            }
            if (status == 'failed' ||
                status == 'cancelled' ||
                status == 'requires_action') {
              throw const AiException(
                AiFailureCode.rejected,
                'Gemini could not complete the generation request.',
              );
            }
          case 'error':
            throw const AiException(
              AiFailureCode.rejected,
              'Gemini could not complete the generation request.',
            );
        }
      }
    } finally {
      unawaited(events.cancel());
    }
    if (!completed) {
      throw const AiException(
        AiFailureCode.malformedResponse,
        'Gemini ended the response before completion.',
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
      'Choose a supported Gemini text model in Settings.',
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
        'The AI request exceeds the selected Gemini model context limit.',
      );
    }
    if (outputLimit != null && request.maxOutputTokens > outputLimit) {
      throw const AiException(
        AiFailureCode.validation,
        'The AI request exceeds the selected Gemini model output limit.',
      );
    }
  }
}

Map<String, Object?> _decodeObject(String value) {
  final Object? decoded;
  try {
    decoded = jsonDecode(value);
  } on FormatException {
    throw const AiException(
      AiFailureCode.malformedResponse,
      'Gemini returned a malformed stream event.',
    );
  }
  if (decoded is! Map) {
    throw const AiException(
      AiFailureCode.malformedResponse,
      'Gemini returned an unexpected stream event.',
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
    'Gemini returned malformed usage data.',
  );
}
