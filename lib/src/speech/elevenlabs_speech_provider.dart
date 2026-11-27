import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../ai/ai_http_transport.dart';
import '../ai/ai_models.dart';
import 'speech_http.dart';
import 'speech_pcm.dart';
import 'speech_provider.dart';

/// In-memory model bounds for the account that last refreshed its catalog.
class ElevenLabsModelLimits {
  String? _credentialFingerprint;
  Map<String, int> _limits = const {};

  int? lookup(String credential, String model) =>
      _credentialFingerprint == _fingerprint(credential)
      ? _limits[model]
      : null;

  void publish(String credential, List<SpeechChoice> models) {
    _credentialFingerprint = _fingerprint(credential);
    _limits = {
      for (final model in models)
        if (model.maximumInputBytes case final limit? when limit > 0)
          model.id: limit,
    };
  }

  static String _fingerprint(String credential) =>
      sha256.convert(utf8.encode(credential)).toString();
}

class ElevenLabsSpeechProvider implements SpeechProvider, SpeechSession {
  ElevenLabsSpeechProvider({
    required http.Client client,
    required this.key,
    required this.options,
    this.streaming = true,
    int? accountLimit,
    ElevenLabsModelLimits? modelLimits,
  }) : _http = SpeechHttp(client, 'ElevenLabs'),
       _accountLimit = accountLimit,
       _modelLimits = modelLimits;

  static const _host = 'api.elevenlabs.io';
  static const defaultModel = 'eleven_multilingual_v2';
  static const _format = 'pcm_24000';

  final SpeechHttp _http;
  final String key;
  final SpeechOptions options;
  final bool streaming;
  final int? _accountLimit;
  final ElevenLabsModelLimits? _modelLimits;

  String get _model => options.model.isEmpty ? defaultModel : options.model;

  @override
  int get maximumInputBytes =>
      (_accountLimit ?? _modelLimits?.lookup(key, _model) ?? 1800).clamp(
        1,
        1800,
      );

  Map<String, String> get _headers => {'xi-api-key': key};

  @override
  Future<SpeechCatalog> discover(AiCancellationToken cancellationToken) async {
    final deadline = AiDeadline(const Duration(seconds: 30));
    Future<Object?> get(String path, [Map<String, String>? query]) async {
      final response = await _http.request(
        Uri.https(_host, path, query),
        _headers,
        cancellationToken,
        deadline,
      );
      return _http.json(response, cancellationToken, deadline);
    }

    final rawModels = await get('/v1/models');
    if (rawModels is! List<Object?>) invalidSpeechResponse();
    final models = <SpeechChoice>[];
    for (final model in rawModels.map(objectMap)) {
      final id = textValue(model['model_id']);
      if (id == null || model['can_do_text_to_speech'] != true) continue;
      final maximum = countValue(model['maximum_text_length_per_request']);
      models.add(
        SpeechChoice(
          id,
          textValue(model['name']) ?? id,
          maximumInputBytes: maximum,
          languages: List.unmodifiable(
            objectList(model['languages'])
                .map(objectMap)
                .map((value) => textValue(value['language_id']))
                .whereType<String>(),
          ),
        ),
      );
    }
    final voices = <String, SpeechChoice>{};
    final visited = <String>{};
    String? page;
    do {
      final data = objectMap(
        await get('/v2/voices', {
          'page_size': '100',
          'include_total_count': 'false',
          if (page != null) 'next_page_token': page,
        }),
      );
      if (data['voices'] is! List || data['has_more'] is! bool) {
        invalidSpeechResponse();
      }
      for (final voice in objectList(data['voices']).map(objectMap)) {
        final id = textValue(voice['voice_id']);
        if (id == null) continue;
        voices[id] = SpeechChoice(
          id,
          textValue(voice['name']) ?? id,
          language: textValue(objectMap(voice['labels'])['language']),
        );
      }
      if (data['has_more'] != true) break;
      page = textValue(data['next_page_token']);
      if (page == null || !visited.add(page) || visited.length > 20) {
        invalidSpeechResponse();
      }
    } while (true);
    cancellationToken.throwIfCancelled();
    _modelLimits?.publish(key, models);
    return SpeechCatalog(
      models: List.unmodifiable(models),
      voices: List.unmodifiable(voices.values),
    );
  }

  @override
  Future<SpeechSession> open(AiCancellationToken cancellationToken) async {
    cancellationToken.throwIfCancelled();
    if (!RegExp(r'^[A-Za-z0-9_-]{1,100}$').hasMatch(options.voice)) {
      throw const AiException(
        AiFailureCode.invalidConfiguration,
        'Select an ElevenLabs voice before generating speech.',
      );
    }
    return this;
  }

  @override
  Future<SpeechChunk> synthesize(
    String text, {
    String? language,
    required AiCancellationToken cancellationToken,
    SpeechRequestUsage? requestUsage,
  }) async {
    if (utf8.encode(text).length > maximumInputBytes) {
      throw const AiException(
        AiFailureCode.responseTooLarge,
        'The speech text exceeds the ElevenLabs model input limit.',
      );
    }
    final deadline = AiDeadline(const Duration(seconds: 95));
    final model = _model;
    final code = language?.split(RegExp('[-_]')).first.toLowerCase();
    SpeechUsage? usage;
    final response = await _http.request(
      Uri.https(
        _host,
        '/v1/text-to-speech/${options.voice}${streaming ? '/stream' : ''}',
        {'output_format': _format},
      ),
      _headers,
      cancellationToken,
      deadline,
      requestUsage: requestUsage,
      onResponse: (response) {
        final count = int.tryParse(response.headers['character-cost'] ?? '');
        final reported = SpeechUsage(
          characters: count != null && count >= 0 ? count : null,
          requestId: response.headers['request-id'],
        );
        usage = reported;
        requestUsage?.report(reported);
      },
      body: {
        'text': text,
        'model_id': model,
        if (model != defaultModel &&
            code != null &&
            RegExp(r'^[a-z]{2}$').hasMatch(code))
          'language_code': code,
        if (options.speed != 1) 'voice_settings': {'speed': options.speed},
      },
    );
    final mime = response.headers['content-type']
        ?.split(';')
        .first
        .trim()
        .toLowerCase();
    if (mime != 'audio/pcm' &&
        mime != 'audio/l16' &&
        mime != 'application/octet-stream') {
      await response.stream.listen(null).cancel();
      invalidSpeechAudio();
    }
    final body = await _http.bytes(response, cancellationToken, deadline);
    if (isWave(body) ||
        (body.length >= 3 &&
            body[0] == 0x49 &&
            body[1] == 0x44 &&
            body[2] == 0x33)) {
      invalidSpeechAudio();
    }
    return SpeechChunk(SpeechPcm(body, sampleRate: 24000), usage: usage);
  }

  @override
  Future<void> close() async {}
}
