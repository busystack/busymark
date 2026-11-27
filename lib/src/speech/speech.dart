import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:characters/characters.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../ai/ai_http_transport.dart';
import '../ai/ai_models.dart';
import 'elevenlabs_speech_provider.dart';
import 'gemini_speech_provider.dart';
import 'local_speech_provider.dart';
import 'ollama_speech_provider.dart';
import 'openai_speech_provider.dart';
import 'piper_voice_store.dart';
import 'speech_credentials.dart';
import 'speech_pcm.dart';
import 'speech_provider.dart';
import 'speech_usage.dart';
import 'system_speech.dart';

export '../ai/ai_models.dart'
    show AiCancellationToken, AiException, AiFailureCode;
export 'piper_voice_store.dart';
export 'speech_credentials.dart';
export 'speech_provider.dart';

typedef SpeechProviderFactory =
    FutureOr<SpeechProvider> Function(SpeechOptions options);

class SpeechService {
  SpeechService({
    this.credentials = const SpeechCredentials(),
    PiperVoiceStore? piperVoices,
    SpeechProviderFactory? providerFactory,
    http.Client Function()? client,
    SpeechUsageLedger? usageLedger,
  }) : piperVoices = piperVoices ?? PiperVoiceStore(),
       _providerFactory = providerFactory,
       _client = client ?? http.Client.new,
       _usageLedger = usageLedger ?? SpeechUsageLedger.shared;

  final SpeechCredentials credentials;
  final PiperVoiceStore piperVoices;
  final SpeechProviderFactory? _providerFactory;
  final http.Client Function() _client;
  final SpeechUsageLedger _usageLedger;
  static final _elevenLabsLimits = ElevenLabsModelLimits();
  _SpeechResume? _resume;
  AiCancellationToken? _active;
  SystemSpeech? _system;
  bool _latestSynthesisWasSent = false;

  bool get latestSynthesisWasSent => _latestSynthesisWasSent;

  static const _maxSegments = 256;
  static const _maxTextBytes = 256 * 1024;

  Future<SpeechCatalog> discover(
    SpeechOptions options, {
    required AiCancellationToken cancellationToken,
  }) async {
    if (options.backend == SpeechBackend.system) {
      return SystemSpeech.discover(cancellationToken);
    }
    final client = _client();
    try {
      final provider = await _provider(options, client, cancellationToken);
      return await provider.discover(cancellationToken);
    } finally {
      client.close();
    }
  }

  Future<SpeechProvider> _provider(
    SpeechOptions options,
    http.Client client,
    AiCancellationToken token,
  ) async {
    if (_providerFactory case final factory?) return factory(options);
    Future<String> key() async {
      final value = await AiDeadline(const Duration(seconds: 10)).wait(
        credentials.read(options.backend),
        token,
        timeoutMessage: 'The secure credential service did not respond.',
      );
      if (value == null || value.contains(RegExp(r'[\x00-\x1f\x7f]'))) {
        throw const AiException(
          AiFailureCode.invalidConfiguration,
          'Save a valid provider key in Settings before requesting speech.',
        );
      }
      return value;
    }

    return switch (options.backend) {
      SpeechBackend.espeak => EspeakSpeechProvider(options),
      SpeechBackend.piper => PiperSpeechProvider(options, piperVoices),
      SpeechBackend.gemini => GeminiSpeechProvider(
        client: client,
        key: await key(),
        options: options,
      ),
      SpeechBackend.openai => OpenAiSpeechProvider(
        key: await key(),
        options: options,
      ),
      SpeechBackend.elevenLabs => ElevenLabsSpeechProvider(
        client: client,
        key: await key(),
        options: options,
        modelLimits: _elevenLabsLimits,
      ),
      SpeechBackend.ollama => OllamaSpeechProvider(
        client: client,
        options: options,
      ),
      SpeechBackend.system => throw const AiException(
        AiFailureCode.invalidConfiguration,
        'Speech Dispatcher can read text aloud through the desktop.',
      ),
    };
  }

  void clearCompletedChunks() => _resume = null;

  void cancelActive() => _active?.cancel();

  Future<SpeechResult> generate(
    List<SpeechSegment> segments,
    SpeechOptions options, {
    required AiCancellationToken cancellationToken,
    void Function(int completed, int total)? onProgress,
    bool resumeCompletedChunks = false,
  }) async {
    _reserve(cancellationToken);
    _latestSynthesisWasSent = false;
    final client = _client();
    SpeechSession? session;
    try {
      _validateOptions(options);
      final provider = await _provider(options, client, cancellationToken);
      if (provider is ElevenLabsSpeechProvider) {
        await provider.prepareGeneration(cancellationToken);
      }
      final planned = planSpeechChunks(segments, provider.maximumInputBytes);
      final identity = _identity(planned, options);
      final resume = resumeCompletedChunks && _resume?.identity == identity
          ? _resume!
          : _SpeechResume(identity);
      _resume = resume;
      final bytes = BytesBuilder(copy: false);
      final usage = <SpeechUsage>[];
      final offsets = <Duration>[];
      onProgress?.call(resume.completed.length, planned.length);
      for (var index = 0; index < planned.length; index++) {
        cancellationToken.throwIfCancelled();
        final segment = planned[index];
        final SpeechChunk chunk;
        if (index < resume.completed.length) {
          chunk = resume.completed[index];
        } else {
          session ??= await provider.open(cancellationToken);
          final raw = await _synthesize(
            session,
            segment,
            options,
            cancellationToken,
          );
          final pcm = raw.pcm;
          final normalized = await Isolate.run(() => normalizeSpeechPcm(pcm));
          chunk = SpeechChunk(
            SpeechPcm(normalized, sampleRate: speechResultSampleRate),
            usage: raw.usage,
          );
        }
        final pause =
            segment.pauseAfter.inMilliseconds.clamp(0, 5000) *
            speechResultSampleRate ~/
            1000 *
            2;
        if (bytes.length + chunk.pcm.bytes.length + pause + 44 >
            speechMaxBytes) {
          throw const AiException(
            AiFailureCode.responseTooLarge,
            'The completed narration exceeds the audio size limit.',
          );
        }
        offsets.add(_duration(bytes.length));
        bytes.add(chunk.pcm.bytes);
        if (pause > 0) bytes.add(Uint8List(pause));
        if (chunk.usage case final value?) usage.add(value);
        // A completed response remains reusable if stop raced its conversion.
        if (index == resume.completed.length) resume.completed.add(chunk);
        cancellationToken.throwIfCancelled();
        onProgress?.call(index + 1, planned.length);
      }
      cancellationToken.throwIfCancelled();
      final duration = _duration(bytes.length);
      final pcm = SpeechPcm(
        bytes.takeBytes(),
        sampleRate: speechResultSampleRate,
      );
      final wav = await Isolate.run(() => encodeSpeechWave(pcm));
      cancellationToken.throwIfCancelled();
      if (identical(_resume, resume)) _resume = null;
      return SpeechResult(
        wavBytes: wav.asUnmodifiableView(),
        duration: duration,
        usage: List.unmodifiable(usage),
        segmentOffsets: List.unmodifiable(offsets),
      );
    } finally {
      try {
        await session?.close();
      } finally {
        client.close();
        _active = null;
      }
    }
  }

  Future<SpeechChunk> _synthesize(
    SpeechSession session,
    SpeechSegment segment,
    SpeechOptions options,
    AiCancellationToken cancellationToken,
  ) async {
    _latestSynthesisWasSent = false;
    final requestUsage = options.backend.isCloud ? SpeechRequestUsage() : null;
    try {
      return await session.synthesize(
        segment.text,
        language:
            nonBlankSpeechSetting(options.language) ??
            nonBlankSpeechSetting(segment.language),
        cancellationToken: cancellationToken,
        requestUsage: requestUsage,
      );
    } finally {
      if (requestUsage != null && requestUsage.sent) {
        _latestSynthesisWasSent = true;
        try {
          await _usageLedger.recordRequest(
            options.backend,
            requestUsage.reported,
          );
        } on Exception {
          // Preserve an audio result or the original provider error if storage fails.
        }
      }
    }
  }

  Future<void> readSystem(
    List<SpeechSegment> segments,
    SpeechOptions options, {
    required AiCancellationToken cancellationToken,
    bool allowUnverifiedModule = false,
    void Function(int completed, int total)? onProgress,
  }) async {
    _reserve(cancellationToken);
    SystemSpeech? system;
    try {
      final planned = planSpeechChunks(segments, 5000);
      system = await SystemSpeech.connect();
      cancellationToken.throwIfCancelled();
      await system.configure(
        options,
        allowUnverifiedModule: allowUnverifiedModule,
      );
      _system = system;
      for (var i = 0; i < planned.length; i++) {
        final segment = planned[i];
        onProgress?.call(i, planned.length);
        await system.speak(
          segment.text,
          voice: options.voice,
          language:
              nonBlankSpeechSetting(options.language) ??
              nonBlankSpeechSetting(segment.language),
          cancellationToken: cancellationToken,
        );
        if (segment.pauseAfter > Duration.zero) {
          await AiDeadline(const Duration(seconds: 6)).wait(
            Future<void>.delayed(
              Duration(
                milliseconds: segment.pauseAfter.inMilliseconds.clamp(0, 5000),
              ),
            ),
            cancellationToken,
            timeoutMessage: 'System narration timed out.',
          );
        }
      }
      onProgress?.call(planned.length, planned.length);
    } finally {
      try {
        await system?.stop();
        await system?.close();
      } finally {
        _system = null;
        _active = null;
      }
    }
  }

  Future<void> pauseSystem() async => _system?.pause();
  Future<void> resumeSystem() async => _system?.resume();

  void _reserve(AiCancellationToken token) {
    token.throwIfCancelled();
    if (_active != null) {
      throw const AiException(
        AiFailureCode.rejected,
        'Wait for the current speech job to finish or cancel it first.',
      );
    }
    _active = token;
  }

  static void _validateOptions(SpeechOptions options) {
    final validSpeed =
        options.speed.isFinite &&
        (options.backend.synthesisSpeed?.allows(options.speed) ?? true);
    if (!validSpeed ||
        options.pitch < 0 ||
        options.pitch > 99 ||
        options.style.length > 300 ||
        options.model.length > 128 ||
        options.voice.length > 200 ||
        options.language.length > 64) {
      throw const AiException(
        AiFailureCode.invalidConfiguration,
        'The selected speech settings exceed the provider limits.',
      );
    }
  }

  static Duration _duration(int bytes) =>
      Duration(microseconds: bytes ~/ 2 * 1000000 ~/ speechResultSampleRate);

  static String _identity(
    List<SpeechSegment> segments,
    SpeechOptions options,
  ) => sha256
      .convert(
        utf8.encode(
          jsonEncode([
            options.backend.name,
            options.model,
            options.voice,
            options.language,
            options.speed,
            options.pitch,
            options.style,
            for (final segment in segments)
              [
                segment.text,
                segment.pauseAfter.inMicroseconds,
                segment.language,
              ],
          ]),
        ),
      )
      .toString();
}

class _SpeechResume {
  _SpeechResume(this.identity);
  final String identity;
  final completed = <SpeechChunk>[];
}

/// Keeps structural pauses and splits only at grapheme boundaries. Prefer
/// whitespace after sentence punctuation, then any whitespace, before a hard split.
List<SpeechSegment> planSpeechChunks(
  List<SpeechSegment> segments,
  int maximumBytes,
) {
  final chunks = <SpeechSegment>[];
  var total = 0;
  for (final segment in segments) {
    final text = segment.text.trim();
    total += utf8.encode(text).length;
    if (total > SpeechService._maxTextBytes) throw _tooMuchText;
    if (text.isEmpty) continue;
    final graphemes = text.characters.toList();
    var start = 0;
    while (start < graphemes.length) {
      var bytes = 0;
      var end = start;
      int? word;
      int? sentence;
      while (end < graphemes.length) {
        final grapheme = graphemes[end];
        bytes += utf8.encode(grapheme).length;
        if (bytes > maximumBytes) break;
        if (end > start && grapheme.trim().isEmpty) {
          word = end;
          if (const [
            '.',
            '!',
            '?',
            '。',
            '！',
            '？',
          ].contains(graphemes[end - 1])) {
            sentence = end;
          }
        }
        end++;
      }
      if (end == start) throw _tooMuchText;
      if (end < graphemes.length) end = sentence ?? word ?? end;
      final part = graphemes.getRange(start, end).join().trim();
      start = end;
      while (start < graphemes.length && graphemes[start].trim().isEmpty) {
        start++;
      }
      if (part.isEmpty) continue;
      chunks.add(
        SpeechSegment(
          part,
          language: segment.language,
          pauseAfter: start == graphemes.length
              ? segment.pauseAfter
              : Duration.zero,
        ),
      );
      if (chunks.length > SpeechService._maxSegments) throw _tooMuchText;
    }
  }
  if (chunks.isEmpty) {
    throw const AiException(
      AiFailureCode.validation,
      'There is no spoken text in this selection.',
    );
  }
  return List.unmodifiable(chunks);
}

const _tooMuchText = AiException(
  AiFailureCode.responseTooLarge,
  'The narration is too long for one job. Select a smaller passage.',
);
