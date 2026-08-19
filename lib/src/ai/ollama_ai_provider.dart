import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'ai_models.dart';
import 'ai_policy.dart';
import 'ai_provider.dart';
import 'ndjson_decoder.dart';

class OllamaAiProvider implements AiProvider {
  OllamaAiProvider({
    required http.Client client,
    required String endpoint,
    this.requestTimeout = const Duration(seconds: 20),
    this.streamTimeout = const Duration(minutes: 2),
    this.ndjsonDecoder = const NdjsonDecoder(),
  }) : _client = client,
       endpoint = AiPolicy.validateLocalOllamaEndpoint(endpoint);

  final http.Client _client;
  final Uri endpoint;
  final Duration requestTimeout;
  final Duration streamTimeout;
  final NdjsonDecoder ndjsonDecoder;

  @override
  String get id => 'ollama-local';

  @override
  Future<List<AiModelInfo>> listModels() async {
    final models = await _listAllModels();
    return models.where((model) => !model.isRemote).toList(growable: false);
  }

  Future<List<AiModelInfo>> _listAllModels() async {
    final request = http.Request('GET', endpoint.resolve('/api/tags'))
      ..followRedirects = false
      ..maxRedirects = 0;
    final response = await _send(request);
    final bytes = await _readBoundedModelList(response.stream);
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } on FormatException {
      throw const AiException(
        AiFailureCode.malformedResponse,
        'Ollama returned a malformed model list.',
      );
    }
    if (decoded is! Map || decoded['models'] is! List) {
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
          sizeBytes: switch (json['size']) {
            final int value => value,
            final num value => value.toInt(),
            _ => null,
          },
          modifiedAt: DateTime.tryParse(json['modified_at']?.toString() ?? ''),
          remoteModel: _nonEmptyString(json['remote_model']),
          remoteHost: _nonEmptyString(json['remote_host']),
        ),
      );
    }
    models.sort((a, b) => a.name.compareTo(b.name));
    return models;
  }

  @override
  Stream<AiStreamEvent> stream(
    AiRequest request, {
    required AiCancellationToken cancellationToken,
  }) async* {
    AiPolicy.validateRequest(request);
    cancellationToken.throwIfCancelled();
    final models = await _listAllModels();
    cancellationToken.throwIfCancelled();
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
    final httpRequest = http.Request('POST', endpoint.resolve('/api/chat'))
      ..followRedirects = false
      ..maxRedirects = 0
      ..headers['content-type'] = 'application/json'
      ..body = jsonEncode({
        'model': request.model,
        'stream': true,
        'messages': [
          {'role': 'system', 'content': request.systemPrompt},
          {'role': 'user', 'content': request.userPrompt},
        ],
        'options': {'temperature': 0.2},
      });
    final response = await _send(httpRequest);
    cancellationToken.throwIfCancelled();
    yield const AiStarted();
    var completed = false;
    final records = StreamIterator(
      ndjsonDecoder.decode(response.stream.timeout(streamTimeout)),
    );
    try {
      while (await _moveNext(records, cancellationToken)) {
        final record = records.current;
        final error = record['error']?.toString().trim();
        if (error != null && error.isNotEmpty) {
          throw AiException(
            AiFailureCode.rejected,
            'Ollama rejected the request: $error',
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
          completed = true;
          yield AiUsageEvent(
            AiUsage(
              inputTokens: _intValue(record['prompt_eval_count']),
              outputTokens: _intValue(record['eval_count']),
              totalDurationMicroseconds: _nanosecondsToMicroseconds(
                record['total_duration'],
              ),
            ),
          );
          yield const AiCompleted();
          break;
        }
      }
    } on TimeoutException {
      throw const AiException(
        AiFailureCode.timeout,
        'Ollama stopped responding before the proposal completed.',
        retryable: true,
      );
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

  Future<http.StreamedResponse> _send(http.BaseRequest request) async {
    final http.StreamedResponse response;
    try {
      response = await _client.send(request).timeout(requestTimeout);
    } on TimeoutException {
      throw const AiException(
        AiFailureCode.timeout,
        'Ollama did not respond in time.',
        retryable: true,
      );
    } on http.ClientException {
      throw const AiException(
        AiFailureCode.connection,
        'BusyMark could not connect to local Ollama.',
        retryable: true,
      );
    } on SocketException {
      throw const AiException(
        AiFailureCode.connection,
        'BusyMark could not connect to local Ollama.',
        retryable: true,
      );
    }
    if (response.isRedirect ||
        (response.statusCode >= 300 && response.statusCode < 400)) {
      throw const AiException(
        AiFailureCode.rejected,
        'Ollama redirects are not allowed.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AiException(
        AiFailureCode.rejected,
        'Ollama returned HTTP ${response.statusCode}.',
        retryable: response.statusCode == 429 || response.statusCode >= 500,
      );
    }
    return response;
  }

  Future<Uint8List> _readBoundedModelList(Stream<List<int>> stream) async {
    final bytes = BytesBuilder(copy: false);
    var length = 0;
    try {
      await for (final chunk in stream.timeout(requestTimeout)) {
        length += chunk.length;
        if (length > ndjsonDecoder.maxBytes) {
          throw const AiException(
            AiFailureCode.responseTooLarge,
            'The Ollama model list exceeded the size limit.',
          );
        }
        bytes.add(chunk);
      }
    } on TimeoutException {
      throw const AiException(
        AiFailureCode.timeout,
        'Ollama stopped responding while listing models.',
        retryable: true,
      );
    }
    return bytes.takeBytes();
  }
}

const _cancelledMarker = Object();

Future<bool> _moveNext(
  StreamIterator<Map<String, Object?>> records,
  AiCancellationToken token,
) async {
  final result = await Future.any<Object>([
    records.moveNext(),
    token.whenCancelled.then<Object>((_) => _cancelledMarker),
  ]);
  if (identical(result, _cancelledMarker)) {
    unawaited(records.cancel());
    token.throwIfCancelled();
  }
  return result as bool;
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
  final nanoseconds = _intValue(value);
  return nanoseconds == null ? null : nanoseconds ~/ 1000;
}
