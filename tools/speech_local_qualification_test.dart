import 'dart:async';
import 'dart:io';

import 'package:busymark/src/speech/local_speech_provider.dart';
import 'package:busymark/src/speech/ollama_speech_provider.dart';
import 'package:busymark/src/speech/speech.dart';
import 'package:busymark/src/speech/speech_pcm.dart';
import 'package:busymark/src/speech/system_speech.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

void main() {
  const engine = String.fromEnvironment('SPEECH_LOCAL_ENGINE');
  const directory = String.fromEnvironment('SPEECH_LOCAL_EVIDENCE_DIR');
  const executable = String.fromEnvironment('SPEECH_LOCAL_EXECUTABLE');
  const ollama = String.fromEnvironment('SPEECH_OLLAMA_ORIGIN');
  const download = bool.fromEnvironment('SPEECH_INSTALL_VOICE');
  const playSystem = bool.fromEnvironment('SPEECH_SYSTEM_PLAY');
  const verifyPiperFailures = bool.fromEnvironment(
    'SPEECH_TEST_PIPER_FAILURES',
  );
  const language = String.fromEnvironment(
    'SPEECH_LOCAL_LANGUAGE',
    defaultValue: 'en',
  );

  test(
    'local speech qualification',
    timeout: const Timeout(Duration(minutes: 10)),
    () async {
      if (directory.isEmpty || !Directory(directory).existsSync()) {
        fail('Supply an isolated speech evidence directory.');
      }
      if (language != 'en' && language != 'fr') {
        fail('Choose en or fr for the synthetic qualification sample.');
      }
      final token = AiCancellationToken();
      final client = http.Client();
      addTearDown(token.dispose);
      addTearDown(client.close);
      if (engine == 'system') {
        final catalog = await SystemSpeech.discover(token);
        expect(catalog.unavailableReason, isNull);
        expect(catalog.models.map((value) => value.id), contains('espeak-ng'));
        expect(catalog.voices.any((voice) => voice.model == 'espeak-ng'), true);
        if (playSystem) {
          final expectedSocket =
              'unix_socket:${p.join(directory, 'system.sock')}';
          expect(
            Platform.environment['SPEECHD_ADDRESS'],
            expectedSocket,
            reason: 'Playback qualification requires the owned fixture socket.',
          );
          final first = await SystemSpeech.connect();
          final second = await SystemSpeech.connect();
          addTearDown(first.close);
          addTearDown(second.close);
          const options = SpeechOptions(backend: SpeechBackend.system);
          await first.configure(options, allowUnverifiedModule: false);
          await second.configure(options, allowUnverifiedModule: false);
          final long = first.speak(
            List.filled(25, 'One member of the choir will stop.').join(' '),
            language: 'en',
            cancellationToken: token,
          );
          final stopped = expectLater(
            long,
            throwsA(
              isA<AiException>().having(
                (error) => error.code,
                'code',
                AiFailureCode.cancelled,
              ),
            ),
          );
          final other = second.speak(
            'The other member of the choir continues speaking.',
            language: 'en',
            cancellationToken: token,
          );
          await first.pause();
          await first.resume();
          await first.stop();
          await stopped;
          await other;
        }
        return;
      }
      final store = PiperVoiceStore(
        directory: () async => Directory(p.join(directory, 'models')),
      );
      final backend = switch (engine) {
        'espeak' => SpeechBackend.espeak,
        'piper' => SpeechBackend.piper,
        'ollama' => SpeechBackend.ollama,
        _ => throw ArgumentError('Select espeak, piper, system, or ollama.'),
      };
      final voice = backend == SpeechBackend.piper
          ? PiperVoiceStore.downloads.firstWhere(
              (voice) => voice.language.startsWith(language),
            )
          : null;
      if (voice != null && download) {
        await store.install(voice, cancellationToken: token);
      }
      final options = SpeechOptions(
        backend: backend,
        voice: switch (engine) {
          'piper' => voice!.id,
          'ollama' when language == 'fr' => 'female-french',
          _ => '',
        },
        language: language,
      );
      final service = SpeechService(
        piperVoices: store,
        providerFactory: (_) => switch (backend) {
          SpeechBackend.espeak => EspeakSpeechProvider(
            options,
            executable: executable.isEmpty ? null : executable,
          ),
          SpeechBackend.piper => PiperSpeechProvider(
            options,
            store,
            python: executable.isEmpty ? null : executable,
          ),
          SpeechBackend.ollama => OllamaSpeechProvider(
            client: client,
            options: options,
            endpoint: ollama,
          ),
          _ => throw StateError('Unsupported file-generating engine.'),
        },
      );
      final metadata = await service.discover(
        options,
        cancellationToken: token,
      );
      expect(metadata.unavailableReason, isNull);
      expect(metadata.models.isNotEmpty || metadata.voices.isNotEmpty, true);
      final result = await service.generate(
        language == 'fr'
            ? [
                const SpeechSegment(
                  'À midi, Lucie Bernard a compté quarante-deux pages.',
                  pauseAfter: Duration(milliseconds: 350),
                ),
                const SpeechSegment('Elle a rendu le cahier.'),
              ]
            : [
                const SpeechSegment(
                  'At noon, Maya Chen counted forty-two pages.',
                  pauseAfter: Duration(milliseconds: 350),
                ),
                const SpeechSegment('She returned the notebook.'),
              ],
        options,
        cancellationToken: token,
      );
      final pcm = decodeSpeechWave(result.wavBytes);
      expect(result.segmentOffsets, hasLength(2));
      expect(pcm.sampleRate, 24000);
      expect(result.duration.inSeconds, greaterThan(1));
      expect(pcm.bytes.any((sample) => sample != 0), true);
      await File(
        p.join(
          directory,
          language == 'en' ? '$engine.wav' : '$engine-$language.wav',
        ),
      ).writeAsBytes(result.wavBytes, flush: true);
      if (backend == SpeechBackend.piper && verifyPiperFailures) {
        await _checkPiperFailures(
          provider: PiperSpeechProvider(
            options,
            store,
            python: executable.isEmpty ? null : executable,
          ),
          model: await store.resolve(voice!.id),
          python: executable.isEmpty ? null : executable,
        );
      }
    },
  );
}

Future<void> _checkPiperFailures({
  required PiperSpeechProvider provider,
  required File model,
  required String? python,
}) async {
  final scratch = await Directory.systemTemp.createTemp(
    'busymark-piper-probe-',
  );
  addTearDown(() => scratch.delete(recursive: true));
  final token = AiCancellationToken();
  addTearDown(token.dispose);
  final invalidStore = PiperVoiceStore(directory: () async => scratch);

  Matcher failure(AiFailureCode code) =>
      throwsA(isA<AiException>().having((error) => error.code, 'code', code));

  Future<SpeechSession> openInvalid(String voice) => PiperSpeechProvider(
    SpeechOptions(backend: SpeechBackend.piper, voice: voice),
    invalidStore,
    python: python,
  ).open(token);

  await expectLater(
    openInvalid('missing'),
    failure(AiFailureCode.invalidConfiguration),
  );
  final corrupt = await Directory(p.join(scratch.path, 'corrupt')).create();
  final corruptModel = File(p.join(corrupt.path, 'corrupt.onnx'));
  await corruptModel.writeAsString('Invalid ONNX fixture.');
  await File('${model.path}.json').copy('${corruptModel.path}.json');
  await expectLater(openInvalid('corrupt'), failure(AiFailureCode.rejected));

  final prior = await _childPids();
  final session = await provider.open(token);
  try {
    final owned = (await _childPids()).difference(prior);
    expect(owned, isNotEmpty, reason: 'The real Piper worker must be running.');
    final synthesis = session.synthesize(
      List.filled(100, 'Maya counted pages in the blue notebook.').join(' '),
      cancellationToken: token,
    );
    final cancelled = expectLater(synthesis, failure(AiFailureCode.cancelled));
    final timer = Timer(const Duration(milliseconds: 25), token.cancel);
    try {
      await cancelled;
    } finally {
      timer.cancel();
      await session.close();
    }
    expect((await _childPids()).intersection(owned), isEmpty);
  } finally {
    await session.close();
  }
}

Future<Set<int>> _childPids() async {
  final pids = <int>{};
  await for (final task in Directory('/proc/self/task').list()) {
    try {
      final children = await File(p.join(task.path, 'children')).readAsString();
      pids.addAll(
        children.split(RegExp(r'\s+')).map(int.tryParse).whereType<int>(),
      );
    } on FileSystemException {
      // A test runner thread can exit during enumeration.
    }
  }
  return pids;
}
