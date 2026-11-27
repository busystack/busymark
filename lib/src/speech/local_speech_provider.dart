import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../ai/ai_http_transport.dart';
import '../ai/ai_models.dart';
import 'piper_voice_store.dart';
import 'speech_http.dart';
import 'speech_pcm.dart';
import 'speech_provider.dart';

class EspeakSpeechProvider implements SpeechProvider, SpeechSession {
  EspeakSpeechProvider(this.options, {String? executable})
    : executable =
          executable ??
          (Platform.environment['SNAP'] == null
              ? 'espeak-ng'
              : p.join(
                  Platform.environment['SNAP']!,
                  'usr',
                  'bin',
                  'espeak-ng',
                ));

  final SpeechOptions options;
  final String executable;

  @override
  int get maximumInputBytes => 5000;

  @override
  Future<SpeechCatalog> discover(AiCancellationToken cancellationToken) async {
    try {
      final result = await _runSpeechProcess(
        executable,
        ['--voices'],
        '',
        cancellationToken,
        limit: 512 * 1024,
      );
      final voices = <String, SpeechChoice>{};
      for (final line
          in const LineSplitter().convert(utf8.decode(result)).skip(1)) {
        final fields = line.trim().split(RegExp(r'\s+'));
        if (fields.length < 5 || int.tryParse(fields.first) == null) continue;
        final id = fields[1];
        voices.putIfAbsent(
          id,
          () => SpeechChoice(
            id,
            fields[3].replaceAll('_', ' '),
            language: id,
            locality: SpeechLocality.offline,
          ),
        );
      }
      return SpeechCatalog(voices: List.unmodifiable(voices.values));
    } on AiException catch (error) {
      if (error.code == AiFailureCode.cancelled) rethrow;
      return SpeechCatalog(unavailableReason: error.message);
    }
  }

  @override
  Future<SpeechSession> open(AiCancellationToken cancellationToken) async {
    cancellationToken.throwIfCancelled();
    return this;
  }

  @override
  Future<SpeechChunk> synthesize(
    String text, {
    String? language,
    required AiCancellationToken cancellationToken,
    SpeechRequestUsage? requestUsage,
  }) async {
    final voice =
        nonBlankSpeechSetting(options.voice) ??
        nonBlankSpeechSetting(language) ??
        'en';
    if (!RegExp(r'^[a-zA-Z0-9_-]{1,64}$').hasMatch(voice)) {
      throw const AiException(
        AiFailureCode.invalidConfiguration,
        'Choose a valid eSpeak NG voice.',
      );
    }
    final bytes = await _runSpeechProcess(
      executable,
      [
        '-b',
        '1',
        '-v',
        voice,
        '-s',
        (175 * options.speed).round().toString(),
        '-p',
        options.pitch.toString(),
        '--stdin',
        '--stdout',
      ],
      text,
      cancellationToken,
    );
    return SpeechChunk(decodeSpeechWave(bytes, allowPipeHeader: true));
  }

  @override
  Future<void> close() async {}
}

class PiperSpeechProvider implements SpeechProvider {
  PiperSpeechProvider(this.options, this.voices, {String? python})
    : python = python ?? _piperPython();

  final SpeechOptions options;
  final PiperVoiceStore voices;
  final String python;

  static String _piperPython() {
    final snap = Platform.environment['SNAP'];
    if (snap != null) return p.join(snap, 'bin', 'busymark-piper-python');
    final bundled = p.join(
      p.dirname(Platform.resolvedExecutable),
      'bin',
      'busymark-piper-python',
    );
    return File(bundled).existsSync() ? bundled : 'python3';
  }

  @override
  int get maximumInputBytes => 5000;

  @override
  Future<SpeechCatalog> discover(AiCancellationToken cancellationToken) async {
    try {
      await _runSpeechProcess(
        python,
        ['-c', 'import piper'],
        '',
        cancellationToken,
        limit: 16 * 1024,
      );
      return SpeechCatalog(voices: await voices.list());
    } on AiException catch (error) {
      if (error.code == AiFailureCode.cancelled) rethrow;
      return SpeechCatalog(unavailableReason: error.message);
    }
  }

  @override
  Future<SpeechSession> open(AiCancellationToken cancellationToken) async {
    final model = await voices.resolve(options.voice);
    final worker = _PiperSession(
      await _startSpeechProcess(
        python,
        ['-u', '-c', _piperWorker, model.path],
        cancellationToken,
        engine: 'Piper',
      ),
      options.speed,
    );
    try {
      await worker.ready(cancellationToken);
      return worker;
    } on Object {
      await worker.close();
      rethrow;
    }
  }

  static const _piperWorker = r'''
import base64, io, json, sys, wave
from piper import PiperVoice, SynthesisConfig

voice = PiperVoice.load(sys.argv[1], use_cuda=False)
print('ready', flush=True)
for line in sys.stdin:
    payload = json.loads(line)
    out = io.BytesIO()
    with wave.open(out, 'wb') as wav:
        voice.synthesize_wav(
            payload['text'],
            wav,
            syn_config=SynthesisConfig(length_scale=1.0 / payload['speed']),
        )
    print(base64.b64encode(out.getbuffer()).decode('ascii'), flush=True)
''';
}

class _PiperSession implements SpeechSession {
  _PiperSession(this.process, this.speed)
    : _reader = StreamIterator(
        process.stdout
            .transform(utf8.decoder)
            .transform(const _BoundedSpeechLines(24 * 1024 * 1024)),
      ) {
    unawaited(process.stderr.drain<void>());
  }

  final Process process;
  final double speed;
  final StreamIterator<String> _reader;
  bool _closed = false;

  Future<String> _read(AiCancellationToken token, AiDeadline deadline) async {
    if (!await moveNextWithDeadline(
      _reader,
      token,
      deadline,
      timeoutMessage: 'Piper did not respond in time.',
    )) {
      throw const AiException(
        AiFailureCode.rejected,
        'Piper could not load the voice or synthesize the supplied text.',
      );
    }
    return _reader.current;
  }

  Future<void> ready(AiCancellationToken token) async {
    if (await _read(token, AiDeadline(const Duration(seconds: 40))) !=
        'ready') {
      invalidSpeechResponse();
    }
  }

  @override
  Future<SpeechChunk> synthesize(
    String text, {
    String? language,
    required AiCancellationToken cancellationToken,
    SpeechRequestUsage? requestUsage,
  }) async {
    cancellationToken.throwIfCancelled();
    final deadline = AiDeadline(const Duration(seconds: 95));
    process.stdin.writeln(jsonEncode({'text': text, 'speed': speed}));
    await deadline.wait(
      process.stdin.flush(),
      cancellationToken,
      timeoutMessage: 'Piper did not accept the speech request in time.',
    );
    final data = await _read(cancellationToken, deadline);
    return SpeechChunk(decodeSpeechWave(decodeSpeechBase64(data)));
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    process.kill();
    await _reader.cancel();
    await _waitForSpeechProcess(process);
    try {
      await process.stdin.close();
    } on IOException {
      // Cancellation can close the pipe before the owner does.
    }
  }
}

class _BoundedSpeechLines extends StreamTransformerBase<String, String> {
  const _BoundedSpeechLines(this.maximum);
  final int maximum;

  @override
  Stream<String> bind(Stream<String> stream) async* {
    final line = StringBuffer();
    await for (final chunk in stream) {
      var start = 0;
      while (start < chunk.length) {
        final separator = chunk.indexOf('\n', start);
        final end = separator < 0 ? chunk.length : separator;
        if (line.length + end - start > maximum) invalidSpeechResponse();
        line.write(chunk.substring(start, end));
        if (separator < 0) break;
        yield line.toString();
        line.clear();
        start = separator + 1;
      }
    }
    if (line.isNotEmpty) invalidSpeechResponse();
  }
}

Future<Process> _startSpeechProcess(
  String executable,
  List<String> arguments,
  AiCancellationToken token, {
  required String engine,
}) async {
  token.throwIfCancelled();
  try {
    final process = await Process.start(executable, arguments);
    if (token.isCancelled) {
      await _waitForSpeechProcess(process..kill());
      token.throwIfCancelled();
    }
    return process;
  } on ProcessException {
    throw AiException(
      AiFailureCode.invalidConfiguration,
      '$engine is unavailable. Install the official engine to use it.',
    );
  }
}

Future<int> _waitForSpeechProcess(Process process) async {
  try {
    return await process.exitCode.timeout(const Duration(seconds: 2));
  } on TimeoutException {
    process.kill(ProcessSignal.sigkill);
    return process.exitCode.timeout(const Duration(seconds: 2));
  }
}

Future<Uint8List> _runSpeechProcess(
  String executable,
  List<String> args,
  String text,
  AiCancellationToken token, {
  int limit = speechChunkMaxBytes,
}) async {
  final process = await _startSpeechProcess(
    executable,
    args,
    token,
    engine: args.contains('import piper') ? 'Piper' : 'eSpeak NG',
  );
  final deadline = AiDeadline(const Duration(seconds: 75));
  final read = SpeechHttp.transport.readBounded(
    stream: process.stdout,
    maximumBytes: limit,
    cancellationToken: token,
    deadline: deadline,
    timeoutMessage: 'The speech engine did not finish in time.',
    tooLargeMessage: 'The speech engine exceeded the output limit.',
  );
  unawaited(process.stderr.drain<void>());
  Future<void> send() async {
    process.stdin.add(utf8.encode(text));
    await process.stdin.close();
  }

  try {
    final (bytes, status, _) = await (
      read,
      deadline.wait(
        process.exitCode,
        token,
        timeoutMessage: 'The speech engine did not exit in time.',
      ),
      deadline.wait(
        send(),
        token,
        timeoutMessage: 'The speech engine did not accept the text in time.',
      ),
    ).wait;
    if (status != 0) {
      throw const AiException(
        AiFailureCode.rejected,
        'The local speech engine could not complete the request.',
      );
    }
    return bytes;
  } on ParallelWaitError catch (error) {
    token.throwIfCancelled();
    final Object? cause = switch (error.errors) {
      (
        final AsyncError? output,
        final AsyncError? status,
        final AsyncError? input,
      ) =>
        output?.error ?? status?.error ?? input?.error,
      _ => null,
    };
    if (cause is AiException) throw cause;
    throw const AiException(
      AiFailureCode.rejected,
      'The local speech engine failed.',
    );
  } finally {
    process.kill();
    await _waitForSpeechProcess(process);
  }
}
