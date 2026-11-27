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
  Map<String, int?> _limits = const {};

  Map<String, int?>? _forCredential(String credential) =>
      _credentialFingerprint == _fingerprint(credential) ? _limits : null;

  Map<String, int?> _publish(String credential, List<SpeechChoice> models) {
    _credentialFingerprint = _fingerprint(credential);
    return _limits = {
      for (final model in models) model.id: model.maximumInputBytes,
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
       _modelLimits = modelLimits ?? ElevenLabsModelLimits();

  static const _host = 'api.elevenlabs.io';
  static const defaultModel = 'eleven_multilingual_v2';
  static const _format = 'pcm_24000';

  final SpeechHttp _http;
  final String key;
  final SpeechOptions options;
  final bool streaming;
  final int? _accountLimit;
  final ElevenLabsModelLimits _modelLimits;
  int? _plannedLimit;

  String get _model => options.model.isEmpty ? defaultModel : options.model;

  @override
  int get maximumInputBytes =>
      _plannedLimit ??
      _bound(_accountLimit ?? _modelLimits._forCredential(key)?[_model]);

  static int _bound(int? maximum) => (maximum ?? 1800).clamp(1, 1800);

  Map<String, String> get _headers => {'xi-api-key': key};

  Future<Object?> _metadata(
    String path,
    AiCancellationToken token,
    AiDeadline deadline, {
    Map<String, String>? query,
  }) async {
    final response = await _http.request(
      Uri.https(_host, path, query),
      _headers,
      token,
      deadline,
    );
    return _http.json(response, token, deadline);
  }

  Future<List<SpeechChoice>> _loadModels(
    AiCancellationToken token,
    AiDeadline deadline,
  ) async {
    final rawModels = await _metadata('/v1/models', token, deadline);
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
          maximumInputBytes: maximum == 0 ? null : maximum,
          languages: List.unmodifiable(
            objectList(model['languages'])
                .map(objectMap)
                .map((value) => textValue(value['language_id']))
                .whereType<String>(),
          ),
        ),
      );
    }
    return List.unmodifiable(models);
  }

  /// A fresh process has no account catalog. Resolve its model cap before the
  /// caller plans any synthesis, without fetching voices or sending text.
  Future<void> prepareGeneration(AiCancellationToken token) async {
    token.throwIfCancelled();
    _validateVoice();
    if (_accountLimit != null || _plannedLimit != null) return;
    var catalog = _modelLimits._forCredential(key);
    if (catalog == null) {
      try {
        final models = await _loadModels(
          token,
          AiDeadline(const Duration(seconds: 30)),
        );
        token.throwIfCancelled();
        catalog = _modelLimits._publish(key, models);
      } on AiException catch (error) {
        if (error.code == AiFailureCode.cancelled) rethrow;
        throw AiException(
          error.code,
          'Could not load ElevenLabs model limits. ${error.message}',
          retryable: error.retryable,
          retryAfter: error.retryAfter,
          statusCode: error.statusCode,
        );
      }
    }
    if (!catalog.containsKey(_model)) {
      throw const AiException(
        AiFailureCode.invalidConfiguration,
        'The selected ElevenLabs model is unavailable. Refresh the catalog in Settings and choose an available model.',
      );
    }
    _plannedLimit = _bound(catalog[_model]);
  }

  @override
  Future<SpeechCatalog> discover(AiCancellationToken cancellationToken) async {
    final deadline = AiDeadline(const Duration(seconds: 30));
    final models = await _loadModels(cancellationToken, deadline);
    final voices = <String, SpeechChoice>{};
    final visited = <String>{};
    String? page;
    do {
      final data = objectMap(
        await _metadata(
          '/v2/voices',
          cancellationToken,
          deadline,
          query: {
            'page_size': '100',
            'include_total_count': 'false',
            if (page != null) 'next_page_token': page,
          },
        ),
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
    _modelLimits._publish(key, models);
    return SpeechCatalog(
      models: models,
      voices: List.unmodifiable(voices.values),
    );
  }

  @override
  Future<SpeechSession> open(AiCancellationToken cancellationToken) async {
    cancellationToken.throwIfCancelled();
    _validateVoice();
    return this;
  }

  void _validateVoice() {
    if (!RegExp(r'^[A-Za-z0-9_-]{1,100}$').hasMatch(options.voice)) {
      throw const AiException(
        AiFailureCode.invalidConfiguration,
        'Select an ElevenLabs voice before generating speech.',
      );
    }
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
