import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../ai/ai_http_transport.dart';
import '../ai/ai_models.dart';
import '../ai/sse_decoder.dart';
import 'speech_http.dart';
import 'speech_pcm.dart';
import 'speech_provider.dart';

class GeminiSpeechProvider implements SpeechProvider, SpeechSession {
  GeminiSpeechProvider({
    required http.Client client,
    required this.key,
    required this.options,
    this.streaming = false,
  }) : _http = SpeechHttp(client, 'Gemini');

  static const origin = 'generativelanguage.googleapis.com';
  static const models = [
    SpeechChoice('gemini-3.8-flash-lite-tts', 'Gemini 3.8 Flash-Lite TTS'),
    SpeechChoice('gemini-3.8-flash-tts', 'Gemini 3.8 Flash TTS'),
  ];
  static const defaultVoice = 'Kore';
  // Application bound for one request, independently of the model context.
  @override
  int get maximumInputBytes => 2048;

  final SpeechHttp _http;
  final SpeechOptions options;
  final String key;
  final bool streaming;

  Map<String, String> get _headers => {'x-goog-api-key': key};
  String get _model => options.model.isEmpty ? models.first.id : options.model;

  @override
  Future<SpeechCatalog> discover(AiCancellationToken cancellationToken) async {
    final deadline = AiDeadline(const Duration(seconds: 25));
    final available = <String, SpeechChoice>{};
    final seenModelPages = <String>{};
    String? modelPage;
    do {
      final response = await _http.request(
        Uri.https(origin, '/v1beta/models', {
          'pageSize': '100',
          if (modelPage != null) 'pageToken': modelPage,
        }),
        _headers,
        cancellationToken,
        deadline,
      );
      final data = objectMap(
        await _http.json(response, cancellationToken, deadline),
      );
      for (final entry in objectList(data['models']).map(objectMap)) {
        final name = textValue(entry['name']);
        if (name == null) continue;
        final id = name.split('/').last;
        final known = models.where((model) => model.id == id).firstOrNull;
        if (known != null) available[id] = known;
      }
      modelPage = textValue(data['nextPageToken']);
      if (modelPage != null &&
          (!seenModelPages.add(modelPage) || seenModelPages.length > 20)) {
        invalidSpeechResponse();
      }
    } while (modelPage != null);
    if (available.isEmpty) {
      return const SpeechCatalog(
        unavailableReason:
            'This Gemini credential has no supported speech models.',
      );
    }
    final voices = <String, SpeechChoice>{};
    final visited = <String>{};
    String? page;
    do {
      final response = await _http.request(
        Uri.https(origin, '/v1beta/voices', {
          'type': 'prebuilt',
          'page_size': '50',
          if (page != null) 'page_token': page,
        }),
        _headers,
        cancellationToken,
        deadline,
      );
      final data = objectMap(
        await _http.json(response, cancellationToken, deadline),
      );
      for (final entry in objectList(data['voices'])) {
        final voice = objectMap(entry);
        final resource = textValue(voice['id'] ?? voice['name']);
        if (resource == null) continue;
        final id = resource.split('/').last;
        if (id.isEmpty) continue;
        voices[id] = SpeechChoice(
          id,
          textValue(voice['display_name'] ?? voice['displayName']) ?? id,
          language: textValue(voice['language_code']),
        );
      }
      page = textValue(data['next_page_token'] ?? data['nextPageToken']);
      if (page != null && (!visited.add(page) || visited.length > 20)) {
        invalidSpeechResponse();
      }
    } while (page != null);
    if (voices.isEmpty) invalidSpeechResponse();
    return SpeechCatalog(
      models: List.unmodifiable(
        models.where((model) => available.containsKey(model.id)),
      ),
      voices: List.unmodifiable(voices.values),
    );
  }

  @override
  Future<SpeechSession> open(AiCancellationToken cancellationToken) async {
    cancellationToken.throwIfCancelled();
    if (!models.any((model) => model.id == _model)) {
      throw const AiException(
        AiFailureCode.invalidConfiguration,
        'Choose a currently supported Gemini speech model.',
      );
    }
    return this;
  }

  @override
  Future<SpeechChunk> synthesize(
    String text, {
    String? language,
    required AiCancellationToken cancellationToken,
  }) async {
    final deadline = AiDeadline(const Duration(seconds: 95));
    final expectedMime = streaming ? 'audio/l16' : 'audio/wav';
    final response = await _http.request(
      Uri.https(
        origin,
        '/v1beta/interactions',
        streaming ? {'alt': 'sse'} : null,
      ),
      {
        ..._headers,
        'accept': streaming ? 'text/event-stream' : 'application/json',
      },
      cancellationToken,
      deadline,
      body: {
        'model': _model,
        'input': [
          {
            'type': 'user_input',
            'content': [
              {
                'type': 'text',
                'text': text,
                if (options.style.isNotEmpty)
                  'annotations': [
                    {'type': 'speech_metadata', 'style': options.style},
                  ],
              },
            ],
          },
        ],
        'response_format': {
          'type': 'audio',
          'mime_type': expectedMime,
          'sample_rate': 24000,
        },
        'generation_config': {
          'speech_config': [
            {'voice': options.voice.isEmpty ? defaultVoice : options.voice},
          ],
        },
        'store': false,
        'stream': streaming,
      },
    );
    if (streaming) {
      return _readEvents(
        response.stream,
        expectedMime,
        cancellationToken,
        deadline,
      );
    }
    final output = objectMap(
      await _http.json(
        response,
        cancellationToken,
        deadline,
        limit: speechChunkMaxBytes * 2,
      ),
    );
    if (output['status'] != 'completed') {
      throw const AiException(
        AiFailureCode.rejected,
        'Gemini did not complete speech generation.',
      );
    }
    Map<String, Object?>? audio;
    for (final step in objectList(output['steps']).map(objectMap)) {
      if (step['type'] != 'model_output') continue;
      for (final part in objectList(step['content']).map(objectMap)) {
        if (part['type'] != 'audio') continue;
        if (audio != null) invalidSpeechResponse();
        audio = part;
      }
    }
    if (audio == null) invalidSpeechResponse();
    final bytes = decodeSpeechBase64(audio['data']);
    return SpeechChunk(
      _decodeAudio(bytes, audio, expectedMime),
      usage: _usage(output),
    );
  }

  Future<SpeechChunk> _readEvents(
    Stream<List<int>> source,
    String expectedMime,
    AiCancellationToken token,
    AiDeadline deadline,
  ) async {
    final events = StreamIterator(
      const SseDecoder(maxBytes: speechChunkMaxBytes * 2).decode(source),
    );
    final bytes = BytesBuilder(copy: false);
    String? mime;
    int? sampleRate;
    Object? stepIndex;
    Object? contentIndex;
    try {
      while (await moveNextWithDeadline(
        events,
        token,
        deadline,
        timeoutMessage: 'Gemini did not finish speech generation in time.',
      )) {
        final event = events.current;
        final data = objectMap(jsonDecode(event.data));
        final type = data['event_type'] ?? data['type'] ?? event.event;
        if (type == 'error' || type == 'interaction.failed') {
          throw const AiException(
            AiFailureCode.rejected,
            'Gemini rejected the speech request.',
          );
        }
        if (type == 'interaction.completed') {
          final interaction = objectMap(data['interaction']);
          if (interaction['status'] != 'completed' || bytes.isEmpty) {
            invalidSpeechResponse();
          }
          return SpeechChunk(
            _decodeAudio(bytes.takeBytes(), {
              'mime_type': mime,
              'sample_rate': sampleRate,
            }, expectedMime),
            usage: _usage(interaction),
          );
        }
        if (type != 'step.delta') continue;
        final delta = objectMap(data['delta']);
        if (delta['type'] != 'audio') continue;
        if (bytes.isNotEmpty &&
            (data['index'] != stepIndex ||
                data['content_index'] != contentIndex)) {
          invalidSpeechResponse();
        }
        stepIndex = data['index'];
        contentIndex = data['content_index'];
        final nextMime = textValue(delta['mime_type']);
        final nextRate = countValue(delta['sample_rate']);
        if ((mime != null && nextMime != null && mime != nextMime) ||
            (sampleRate != null &&
                nextRate != null &&
                sampleRate != nextRate)) {
          invalidSpeechAudio();
        }
        mime ??= nextMime;
        sampleRate ??= nextRate;
        final decoded = decodeSpeechBase64(delta['data']);
        if (bytes.length + decoded.length > speechChunkMaxBytes) {
          invalidSpeechAudio();
        }
        bytes.add(decoded);
      }
    } on FormatException {
      invalidSpeechResponse();
    } finally {
      unawaited(events.cancel());
    }
    return invalidSpeechResponse();
  }

  SpeechPcm _decodeAudio(
    Uint8List bytes,
    Map<String, Object?> metadata,
    String requestedMime,
  ) {
    final mime =
        (textValue(metadata['mime_type'] ?? metadata['mimeType']) ??
                requestedMime)
            .split(';')
            .first
            .trim()
            .toLowerCase();
    final explicitRate = countValue(
      metadata['sample_rate'] ?? metadata['sampleRate'],
    );
    if (mime == 'audio/wav' || mime == 'audio/x-wav') {
      final pcm = decodeSpeechWave(bytes);
      if (explicitRate != null && pcm.sampleRate != explicitRate) {
        invalidSpeechAudio();
      }
      return pcm;
    }
    if (mime != 'audio/l16' || isWave(bytes)) invalidSpeechAudio();
    return SpeechPcm(bytes, sampleRate: explicitRate ?? 24000);
  }

  SpeechUsage _usage(Map<String, Object?> interaction) {
    final usage = objectMap(interaction['usage']);
    return SpeechUsage(
      requestId: textValue(interaction['id']),
      inputTokens: countValue(usage['total_input_tokens']),
      outputTokens: countValue(usage['total_output_tokens']),
      outputAudioTokens: countValue(usage['total_output_audio_tokens']),
    );
  }

  @override
  Future<void> close() async {}
}
