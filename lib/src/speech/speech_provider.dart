import 'dart:typed_data';

import '../ai/ai_models.dart';

enum SpeechBackend {
  system,
  espeak,
  piper,
  gemini,
  openai,
  elevenLabs,
  ollama;

  bool get isCloud => switch (this) {
    gemini || openai || elevenLabs => true,
    _ => false,
  };

  bool get supportsFiles => this != system;
  bool get supportsSpeed =>
      this == espeak || this == piper || this == openai || this == elevenLabs;
  bool get supportsPitch => this == espeak;
}

enum SpeechLocality { offline, remote, unknown }

class SpeechOptions {
  const SpeechOptions({
    this.backend = SpeechBackend.espeak,
    this.model = '',
    this.voice = '',
    this.language = '',
    this.speed = 1,
    this.pitch = 50,
    this.style = '',
  });

  final SpeechBackend backend;
  final String model;
  final String voice;
  final String language;
  final double speed;
  final int pitch;
  final String style;
}

class SpeechChoice {
  const SpeechChoice(
    this.id,
    this.label, {
    this.language,
    this.locality,
    this.model,
    this.maximumInputBytes,
    this.languages = const [],
  });

  final String id;
  final String label;
  final String? language;
  final SpeechLocality? locality;
  final String? model;
  final int? maximumInputBytes;
  final List<String> languages;
}

class SpeechCatalog {
  const SpeechCatalog({
    this.models = const [],
    this.voices = const [],
    this.unavailableReason,
  });

  final List<SpeechChoice> models;
  final List<SpeechChoice> voices;
  final String? unavailableReason;
}

class SpeechSegment {
  const SpeechSegment(
    this.text, {
    this.pauseAfter = Duration.zero,
    this.language,
  });

  final String text;
  final Duration pauseAfter;
  final String? language;
}

class SpeechUsage {
  const SpeechUsage({
    this.inputTokens,
    this.outputTokens,
    this.inputAudioTokens,
    this.outputAudioTokens,
    this.characters,
    this.requestId,
  });

  final int? inputTokens;
  final int? outputTokens;
  final int? inputAudioTokens;
  final int? outputAudioTokens;
  final int? characters;
  final String? requestId;
}

/// Decoded signed 16-bit little-endian PCM with interleaved frames.
class SpeechPcm {
  SpeechPcm(this.bytes, {required this.sampleRate, this.channels = 1}) {
    if (sampleRate < 8000 ||
        sampleRate > 96000 ||
        channels < 1 ||
        channels > 2 ||
        bytes.isEmpty ||
        bytes.lengthInBytes % (channels * 2) != 0) {
      throw const AiException(
        AiFailureCode.malformedResponse,
        'The speech response has invalid PCM audio.',
      );
    }
  }

  final Uint8List bytes;
  final int sampleRate;
  final int channels;
  int get frames => bytes.lengthInBytes ~/ (channels * 2);
}

class SpeechChunk {
  const SpeechChunk(this.pcm, {this.usage, this.transcript});

  final SpeechPcm pcm;
  final SpeechUsage? usage;
  final String? transcript;
}

class SpeechResult {
  const SpeechResult({
    required this.wavBytes,
    required this.duration,
    required this.usage,
    required this.segmentOffsets,
  });

  final Uint8List wavBytes;
  final Duration duration;
  final List<SpeechUsage> usage;
  final List<Duration> segmentOffsets;
}

abstract interface class SpeechProvider {
  int get maximumInputBytes;
  Future<SpeechCatalog> discover(AiCancellationToken cancellationToken);

  /// The returned session owns all engine resources for this synthesis job.
  Future<SpeechSession> open(AiCancellationToken cancellationToken);
}

abstract interface class SpeechSession {
  Future<SpeechChunk> synthesize(
    String text, {
    String? language,
    required AiCancellationToken cancellationToken,
  });

  Future<void> close();
}
