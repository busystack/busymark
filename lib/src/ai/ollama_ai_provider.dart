import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'ai_http_transport.dart';
import 'ai_models.dart';
import 'ai_policy.dart';
import 'ai_provider.dart';
import 'ndjson_decoder.dart';

class OllamaAiProvider implements AiProvider {
  OllamaAiProvider({
    required http.Client client,
    required String endpoint,
    this.ndjsonDecoder = const NdjsonDecoder(),
    this.transport = const AiHttpTransport(),
  }) : _client = client,
       endpoint = AiPolicy.validateLocalOllamaEndpoint(endpoint);

  final http.Client _client;
  final Uri endpoint;
  final NdjsonDecoder ndjsonDecoder;
  final AiHttpTransport transport;

  @override
  String get id => AiProviderKind.ollamaLocal.id;

  @override
  AiProviderCapabilities get capabilities => const AiProviderCapabilities(
    kind: AiProviderKind.ollamaLocal,
    streaming: true,
    modelDiscovery: true,
    maximumConcurrentRequests: 2,
    recommendedModels: {},
  );

  @override
  Future<List<AiModelInfo>> listModels({
    AiCancellationToken? cancellationToken,
  }) async {
    final token = cancellationToken ?? AiCancellationToken();
    try {
      final models = await _listAllModels(
        token,
        AiDeadline(const Duration(seconds: 30)),
      );
      return models.where((model) => !model.isRemote).toList(growable: false);
    } finally {
      if (cancellationToken == null) {
        await token.dispose();
      }
    }
  }

  Future<List<AiModelInfo>> _listAllModels(
    AiCancellationToken cancellationToken,
    AiDeadline deadline,
  ) async {
    final request =
        http.AbortableRequest(
            'GET',
            endpoint.resolve('/api/tags'),
            abortTrigger: deadline.abortTrigger(cancellationToken),
          )
          ..followRedirects = false
          ..maxRedirects = 0;
    final response = await transport.send(
      client: _client,
      request: request,
      cancellationToken: cancellationToken,
      deadline: deadline,
      providerName: 'Ollama',
    );
    final bytes = await transport.readBounded(
      stream: response.stream,
      maximumBytes: ndjsonDecoder.maxBytes,
      cancellationToken: cancellationToken,
      deadline: deadline,
      timeoutMessage: 'Ollama stopped responding while listing models.',
      tooLargeMessage: 'The Ollama model list exceeded the size limit.',
    );
    final decoded = _decodeObject(bytes, 'model list');
    if (decoded['models'] is! List) {
      throw const AiException(
        AiFailureCode.malformedResponse,
        'Ollama returned an unexpected model list.',
      );
    }
    final models = <AiModelInfo>[];
    for (final item in decoded['models'] as List) {
      if (item is! Map) {
        continue;
      }
      final json = item.cast<Object?, Object?>();
      final name = (json['name'] ?? json['model'])?.toString().trim() ?? '';
      if (name.isEmpty) {
        continue;
      }
      models.add(
        AiModelInfo(
          name: name,
          sizeBytes: _intValue(json['size']),
          modifiedAt: DateTime.tryParse(json['modified_at']?.toString() ?? ''),
          remoteModel: _nonEmptyString(json['remote_model']),
          remoteHost: _nonEmptyString(json['remote_host']),
        ),
      );
    }
    return models;
  }

  Future<AiModelInfo> _modelDetails(
    String model,
    AiCancellationToken cancellationToken,
    AiDeadline deadline,
  ) async {
    final request =
        http.AbortableRequest(
            'POST',
            endpoint.resolve('/api/show'),
            abortTrigger: deadline.abortTrigger(cancellationToken),
          )
          ..followRedirects = false
          ..maxRedirects = 0
          ..headers['content-type'] = 'application/json'
          ..body = jsonEncode({'model': model, 'verbose': false});
    final response = await transport.send(
      client: _client,
      request: request,
      cancellationToken: cancellationToken,
      deadline: deadline,
      providerName: 'Ollama',
    );
    final bytes = await transport.readBounded(
      stream: response.stream,
      maximumBytes: ndjsonDecoder.maxBytes,
      cancellationToken: cancellationToken,
      deadline: deadline,
      timeoutMessage: 'Ollama stopped responding while inspecting the model.',
      tooLargeMessage: 'The Ollama model details exceeded the size limit.',
    );
    final decoded = _decodeObject(bytes, 'model details');
    final capabilities = switch (decoded['capabilities']) {
      final List values => values.map((value) => value.toString()).toSet(),
      _ => <String>{},
    };
    final modelInfo = decoded['model_info'];
    int? contextLimit;
    if (modelInfo is Map) {
      for (final entry in modelInfo.entries) {
        if (entry.key.toString().endsWith('.context_length')) {
          final candidate = _intValue(entry.value);
          if (candidate != null &&
              (contextLimit == null || candidate > contextLimit)) {
            contextLimit = candidate;
          }
        }
      }
    }
    return AiModelInfo(
      name: model,
      modifiedAt: DateTime.tryParse(decoded['modified_at']?.toString() ?? ''),
      inputTokenLimit: contextLimit,
      architecture: _nonEmptyString(
        modelInfo is Map ? modelInfo['general.architecture'] : null,
      ),
      supportsTextGeneration:
          capabilities.isEmpty || capabilities.contains('completion'),
      capabilities: capabilities,
    );
  }

  @override
  Future<AiHealthResult> checkHealth({
    required String model,
    required AiCancellationToken cancellationToken,
  }) async {
    final deadline = AiDeadline(const Duration(minutes: 5));
    final models = await _listAllModels(cancellationToken, deadline);
    final selected = models.where((candidate) => candidate.name == model);
    if (selected.isEmpty || selected.first.isRemote) {
      throw const AiException(
        AiFailureCode.invalidConfiguration,
        'The selected local Ollama model is not installed.',
      );
    }
    final details = await _modelDetails(model, cancellationToken, deadline);
    if (!details.supportsTextGeneration) {
      throw const AiException(
        AiFailureCode.invalidConfiguration,
        'The selected Ollama model does not support text generation.',
      );
    }
    final stopwatch = Stopwatch()..start();
    final request = _chatRequest(
      model: model,
      systemPrompt: 'Return exactly BUSYMARK_OK and nothing else.',
      userPrompt: 'Connection test.',
      stream: false,
      maxOutputTokens: 16,
      contextTokens: 256,
      cancellationToken: cancellationToken,
      deadline: deadline,
      modelInfo: details,
    );
    final response = await transport.send(
      client: _client,
      request: request,
      cancellationToken: cancellationToken,
      deadline: deadline,
      providerName: 'Ollama',
    );
    final bytes = await transport.readBounded(
      stream: response.stream,
      maximumBytes: ndjsonDecoder.maxBytes,
      cancellationToken: cancellationToken,
      deadline: deadline,
      timeoutMessage: 'Ollama did not finish the generation test.',
      tooLargeMessage: 'The Ollama generation test exceeded the size limit.',
    );
    stopwatch.stop();
    final decoded = _decodeObject(bytes, 'generation test');
    final message = decoded['message'];
    final content = message is Map
        ? message['content']?.toString().trim() ?? ''
        : '';
    if (decoded['done'] != true || content != 'BUSYMARK_OK') {
      throw const AiException(
        AiFailureCode.validation,
        'The selected Ollama model did not pass the editing-generation test.',
      );
    }
    return AiHealthResult(
      model: details,
      models: [
        for (final candidate in models)
          if (!candidate.isRemote) candidate,
      ],
      generationVerified: true,
      coldStartDuration: stopwatch.elapsed >= const Duration(seconds: 5)
          ? stopwatch.elapsed
          : null,
    );
  }

  @override
  Stream<AiStreamEvent> stream(
    AiRequest request, {
    required AiCancellationToken cancellationToken,
  }) async* {
    AiPolicy.validateRequest(request);
    final deadline = AiDeadline(request.deadline);
    cancellationToken.throwIfCancelled();
    final models = await _listAllModels(cancellationToken, deadline);
    final selected = models.where((model) => model.name == request.model);
    if (selected.isEmpty) {
      throw const AiException(
        AiFailureCode.invalidConfiguration,
        'The selected Ollama model is not installed.',
      );
    }
    if (selected.first.isRemote) {
      throw const AiException(
        AiFailureCode.invalidConfiguration,
        'BusyMark does not send document content to Ollama cloud models.',
      );
    }
    final details = await _modelDetails(
      request.model,
      cancellationToken,
      deadline,
    );
    if (!details.supportsTextGeneration) {
      throw const AiException(
        AiFailureCode.invalidConfiguration,
        'The selected Ollama model does not support text generation.',
      );
    }
    final requiredContext =
        request.estimatedPromptTokens + request.maxOutputTokens;
    final modelLimit = details.inputTokenLimit;
    if (modelLimit != null && requiredContext > modelLimit) {
      throw AiException(
        AiFailureCode.validation,
        'The selected Ollama model supports $modelLimit context tokens, but this request requires up to $requiredContext.',
      );
    }
    final response = await transport.send(
      client: _client,
      request: _chatRequest(
        model: request.model,
        systemPrompt: request.systemPrompt,
        userPrompt: request.userPrompt,
        stream: true,
        maxOutputTokens: request.maxOutputTokens,
        contextTokens: requiredContext,
        cancellationToken: cancellationToken,
        deadline: deadline,
        modelInfo: details,
      ),
      cancellationToken: cancellationToken,
      deadline: deadline,
      providerName: 'Ollama',
    );
    yield AiStarted(providerId: id, model: request.model);
    var completed = false;
    final records = StreamIterator(ndjsonDecoder.decode(response.stream));
    try {
      while (await moveNextWithDeadline(
        records,
        cancellationToken,
        deadline,
        timeoutMessage: 'Ollama did not finish before the request deadline.',
      )) {
        final record = records.current;
        final error = record['error']?.toString().trim();
        if (error != null && error.isNotEmpty) {
          throw AiException(
            AiFailureCode.rejected,
            'Ollama rejected the generation request.',
          );
        }
        final message = record['message'];
        if (message is Map) {
          final content = message['content']?.toString() ?? '';
          if (content.isNotEmpty) {
            yield AiTextDelta(content);
          }
        }
        if (record['done'] == true) {
          if (record['done_reason'] == 'length') {
            throw const AiException(
              AiFailureCode.validation,
              'Ollama reached the output-token limit before completing the proposal.',
            );
          }
          completed = true;
          yield AiUsageEvent(
            AiUsage(
              inputTokens: _usageInt(record['prompt_eval_count']),
              outputTokens: _usageInt(record['eval_count']),
              totalDurationMicroseconds: _nanosecondsToMicroseconds(
                record['total_duration'],
              ),
              providerId: id,
              model: request.model,
            ),
          );
          yield const AiCompleted();
          break;
        }
      }
    } finally {
      unawaited(records.cancel());
    }
    if (!completed) {
      throw const AiException(
        AiFailureCode.malformedResponse,
        'Ollama ended the response before completion.',
        retryable: true,
      );
    }
  }

  http.AbortableRequest _chatRequest({
    required String model,
    required String systemPrompt,
    required String userPrompt,
    required bool stream,
    required int maxOutputTokens,
    required int contextTokens,
    required AiCancellationToken cancellationToken,
    required AiDeadline deadline,
    required AiModelInfo modelInfo,
  }) {
    final architecture = modelInfo.architecture?.toLowerCase();
    final Object? thinking =
        architecture == 'gptoss' || architecture == 'gpt-oss'
        ? 'low'
        : modelInfo.capabilities.contains('thinking')
        ? false
        : null;
    return http.AbortableRequest(
        'POST',
        endpoint.resolve('/api/chat'),
        abortTrigger: deadline.abortTrigger(cancellationToken),
      )
      ..followRedirects = false
      ..maxRedirects = 0
      ..headers['content-type'] = 'application/json'
      ..body = jsonEncode({
        'model': model,
        'stream': stream,
        if (thinking != null) 'think': thinking,
        'keep_alive': '5m',
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'options': {
          'temperature': 0.2,
          'num_predict': maxOutputTokens,
          'num_ctx': contextTokens,
        },
      });
  }
}

Map<String, Object?> _decodeObject(Uint8List bytes, String responseName) {
  final Object? decoded;
  try {
    decoded = jsonDecode(utf8.decode(bytes));
  } on FormatException {
    throw AiException(
      AiFailureCode.malformedResponse,
      'Ollama returned malformed $responseName data.',
    );
  }
  if (decoded is! Map) {
    throw AiException(
      AiFailureCode.malformedResponse,
      'Ollama returned unexpected $responseName data.',
    );
  }
  return decoded.cast<String, Object?>();
}

int? _intValue(Object? value) => switch (value) {
  final int number => number,
  final num number => number.toInt(),
  _ => null,
};

String? _nonEmptyString(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

int? _nanosecondsToMicroseconds(Object? value) {
  final nanoseconds = _usageInt(value);
  return nanoseconds == null ? null : nanoseconds ~/ 1000;
}

int? _usageInt(Object? value) {
  if (value == null) {
    return null;
  }
  if (value case final int number when number >= 0) {
    return number;
  }
  throw const AiException(
    AiFailureCode.malformedResponse,
    'Ollama returned malformed usage data.',
  );
}
