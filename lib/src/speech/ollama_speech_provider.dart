import 'dart:io';

import 'package:http/http.dart' as http;

import '../ai/ai_http_transport.dart';
import '../ai/ai_models.dart';
import 'speech_http.dart';
import 'speech_pcm.dart';
import 'speech_provider.dart';

class OllamaSpeechProvider implements SpeechProvider, SpeechSession {
  OllamaSpeechProvider({
    required http.Client client,
    required this.options,
    this.endpoint = 'http://127.0.0.1:11434',
  }) : _http = SpeechHttp(client, 'Local Ollama');

  static const model = 'lfm3-audio';
  static const releasedVersion = '0.40.18';
  static const qualifiedModelDigest =
      '3327c1a067559929d03d9e6e811cc2bc50b292b295e896b10733990dc6187590';
  static const unavailable =
      'Ollama speech requires a qualified Linux runtime and local LFM3 Audio model. '
      'Phonon requires Apple Silicon.';
  final SpeechHttp _http;
  final SpeechOptions options;
  final String endpoint;
  bool _verified = false;

  @override
  int get maximumInputBytes => 1600;

  Uri _route(String path) {
    final uri = Uri.tryParse(endpoint);
    if (uri == null ||
        uri.scheme != 'http' ||
        !const {'127.0.0.1', '::1'}.contains(uri.host) ||
        uri.userInfo.isNotEmpty ||
        (uri.path.isNotEmpty && uri.path != '/') ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const AiException(
        AiFailureCode.invalidConfiguration,
        'Ollama speech requires a loopback address.',
      );
    }
    return uri.replace(path: path);
  }

  @override
  Future<SpeechCatalog> discover(AiCancellationToken cancellationToken) async {
    cancellationToken.throwIfCancelled();
    if (!Platform.isLinux) {
      return const SpeechCatalog(unavailableReason: unavailable);
    }
    try {
      final deadline = AiDeadline(const Duration(seconds: 12));
      final version = await _http.request(
        _route('/api/version'),
        {},
        cancellationToken,
        deadline,
      );
      final data = objectMap(
        await _http.json(version, cancellationToken, deadline),
      );
      if (data['version'] != releasedVersion) {
        return const SpeechCatalog(unavailableReason: unavailable);
      }
      final tags = await _http.request(
        _route('/api/tags'),
        {},
        cancellationToken,
        deadline,
      );
      final installed = objectMap(
        await _http.json(tags, cancellationToken, deadline),
      );
      final stock = objectList(installed['models'])
          .map(objectMap)
          .any(
            (entry) =>
                entry['name'] == '$model:latest' &&
                entry['digest'] == qualifiedModelDigest,
          );
      if (!stock) {
        return const SpeechCatalog(unavailableReason: unavailable);
      }
      final show = await _http.request(
        _route('/api/show'),
        {},
        cancellationToken,
        deadline,
        body: {'model': model},
      );
      final config = objectMap(
        await _http.json(show, cancellationToken, deadline),
      );
      if (!objectList(config['capabilities']).contains('speech') ||
          config['remote_model'] != null ||
          config['remote_host'] != null) {
        return const SpeechCatalog(unavailableReason: unavailable);
      }
      final voices = <SpeechChoice>[];
      for (final item in objectList(config['voices'])) {
        final name = textValue(item) ?? textValue(objectMap(item)['name']);
        if (name != null) {
          voices.add(
            SpeechChoice(name, name, locality: SpeechLocality.offline),
          );
        }
      }
      return SpeechCatalog(
        models: const [
          SpeechChoice(model, 'LFM3 Audio', locality: SpeechLocality.offline),
        ],
        voices: List.unmodifiable(voices),
      );
    } on AiException catch (error) {
      if (error.code == AiFailureCode.cancelled) rethrow;
      return SpeechCatalog(unavailableReason: error.message);
    }
  }

  @override
  Future<SpeechSession> open(AiCancellationToken cancellationToken) async {
    final catalog = await discover(cancellationToken);
    if (catalog.unavailableReason != null ||
        (options.model.isNotEmpty && options.model != model) ||
        (options.voice.isNotEmpty &&
            !catalog.voices.any((voice) => voice.id == options.voice))) {
      throw AiException(
        AiFailureCode.invalidConfiguration,
        catalog.unavailableReason ?? unavailable,
      );
    }
    _verified = true;
    return this;
  }

  @override
  Future<SpeechChunk> synthesize(
    String text, {
    String? language,
    required AiCancellationToken cancellationToken,
    SpeechRequestUsage? requestUsage,
  }) async {
    if (!_verified) {
      throw const AiException(AiFailureCode.invalidConfiguration, unavailable);
    }
    final deadline = AiDeadline(const Duration(seconds: 95));
    final response = await _http.request(
      _route('/v1/audio/speech'),
      {},
      cancellationToken,
      deadline,
      body: {
        'model': model,
        'input': text,
        if (options.voice.isNotEmpty) 'voice': options.voice,
        'response_format': 'wav',
      },
    );
    if (response.headers['content-type']?.split(';').first.trim() !=
        'audio/wav') {
      await response.stream.listen(null).cancel();
      invalidSpeechAudio();
    }
    final bytes = await _http.bytes(response, cancellationToken, deadline);
    return SpeechChunk(decodeSpeechWave(bytes, allowPipeHeader: true));
  }

  @override
  Future<void> close() async {}
}
