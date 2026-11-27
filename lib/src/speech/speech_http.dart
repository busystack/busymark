import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../ai/ai_http_transport.dart';
import '../ai/ai_models.dart';
import 'speech_pcm.dart';
import 'speech_provider.dart';

class SpeechHttp {
  const SpeechHttp(this.client, this.provider);

  final http.Client client;
  final String provider;
  static const transport = AiHttpTransport();

  Future<http.StreamedResponse> request(
    Uri uri,
    Map<String, String> headers,
    AiCancellationToken token,
    AiDeadline deadline, {
    Map<String, Object?>? body,
    SpeechRequestUsage? requestUsage,
    void Function(http.StreamedResponse response)? onResponse,
  }) {
    token.throwIfCancelled();
    final request = http.AbortableRequest(
      body == null ? 'GET' : 'POST',
      uri,
      abortTrigger: deadline.abortTrigger(token),
    )..followRedirects = false;
    request.headers.addAll(headers);
    if (body != null) {
      request.headers['content-type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    requestUsage?.markSent();
    return transport.send(
      client: onResponse == null
          ? client
          : _ObservingClient(client, onResponse),
      request: request,
      cancellationToken: token,
      deadline: deadline,
      providerName: provider,
    );
  }

  Future<Uint8List> bytes(
    http.StreamedResponse response,
    AiCancellationToken token,
    AiDeadline deadline, {
    int limit = speechChunkMaxBytes,
  }) async {
    if ((response.contentLength ?? 0) > limit) {
      await response.stream.listen(null).cancel();
      throw const AiException(
        AiFailureCode.responseTooLarge,
        'The speech response exceeds the size limit.',
      );
    }
    final bytes = await transport.readBounded(
      stream: response.stream,
      maximumBytes: limit,
      cancellationToken: token,
      deadline: deadline,
      timeoutMessage: '$provider did not finish in time.',
      tooLargeMessage: 'The speech response exceeds the size limit.',
    );
    if (response.contentLength case final int size) {
      if (response.headers['content-encoding'] == null &&
          bytes.length != size) {
        throw const AiException(
          AiFailureCode.malformedResponse,
          'The speech response was incomplete.',
        );
      }
    }
    return bytes;
  }

  Future<Object?> json(
    http.StreamedResponse response,
    AiCancellationToken token,
    AiDeadline deadline, {
    int limit = 2 * 1024 * 1024,
  }) async {
    final content = await bytes(response, token, deadline, limit: limit);
    try {
      return jsonDecode(utf8.decode(content));
    } on FormatException {
      return invalidSpeechResponse();
    }
  }
}

class _ObservingClient extends http.BaseClient {
  _ObservingClient(this.client, this.onResponse);

  final http.Client client;
  final void Function(http.StreamedResponse response) onResponse;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await client.send(request);
    onResponse(response);
    return response;
  }
}

Map<String, Object?> objectMap(Object? value) =>
    value is Map<String, Object?> ? value : const {};

List<Object?> objectList(Object? value) =>
    value is List<Object?> ? value : const [];

String? textValue(Object? value) =>
    value is String && value.isNotEmpty ? value : null;

int? countValue(Object? value) => value is int && value >= 0 ? value : null;

Never invalidSpeechResponse() => throw const AiException(
  AiFailureCode.malformedResponse,
  'The provider returned an incomplete or invalid speech response.',
);

Uint8List decodeSpeechBase64(Object? value) {
  if (value is! String || value.length > speechChunkMaxBytes * 2) {
    invalidSpeechResponse();
  }
  try {
    return base64Decode(value);
  } on FormatException {
    return invalidSpeechResponse();
  }
}
