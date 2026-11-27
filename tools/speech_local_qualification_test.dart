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

  test(
    'local speech qualification',
    timeout: const Timeout(Duration(minutes: 10)),
    () async {
      if (directory.isEmpty || !Directory(directory).existsSync()) {
        fail('Supply an isolated speech evidence directory.');
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
      final voice = PiperVoiceStore.downloads.first;
      if (backend == SpeechBackend.piper && download) {
        await store.install(voice, cancellationToken: token);
      }
      final options = SpeechOptions(
        backend: backend,
        voice: engine == 'piper' ? voice.id : '',
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
        [
          const SpeechSegment(
            'At noon, Maya Chen counted forty-two pages.',
            pauseAfter: Duration(milliseconds: 350),
            language: 'en',
          ),
          const SpeechSegment('She returned the notebook.', language: 'en'),
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
        p.join(directory, '$engine.wav'),
      ).writeAsBytes(result.wavBytes, flush: true);
    },
  );
}
