import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../ai/ai_http_transport.dart';
import '../ai/ai_models.dart';
import 'speech_http.dart';
import 'speech_provider.dart';

typedef _VoiceFile = ({String name, int bytes, String digest});

class PiperDownload {
  const PiperDownload(
    this.id,
    this.label,
    this.language,
    this.license,
    this.path,
    this._files,
  );

  final String id;
  final String label;
  final String language;
  final String license;
  final String path;
  final List<_VoiceFile> _files;
  int get size => _files.fold(0, (sum, file) => sum + file.bytes);
}

class PiperVoiceStore {
  PiperVoiceStore({
    Future<Directory> Function()? directory,
    http.Client Function()? client,
  }) : _directory = directory ?? _defaultDirectory,
       _client = client ?? http.Client.new;

  static const revision = 'cf910fb59f1d79ab3b625a63993a108751c6c25d';
  static const downloads = [
    PiperDownload(
      'en_US-joe-medium',
      'Joe',
      'en-US',
      'CC0 (Joe and rdh datasets)',
      'en/en_US/joe/medium',
      [
        (
          name: 'en_US-joe-medium.onnx',
          bytes: 63221984,
          digest:
              'abf4b998e34045cbd00eaf050de2de620f81ded6eb8b85a24b022a1c2b3f08d2',
        ),
        (
          name: 'en_US-joe-medium.onnx.json',
          bytes: 5465,
          digest:
              '7b5f0293c0bf5bda8e377be1696da84af798befeef31038e43beefc01fe858da',
        ),
        (
          name: 'MODEL_CARD',
          bytes: 423,
          digest:
              '4b319248135916e8f5433ce7a9fe5271026b05cb598bab05807b22cb17fd129b',
        ),
      ],
    ),
    PiperDownload(
      'fr_FR-siwis-medium',
      'Siwis',
      'fr-FR',
      'CC BY 4.0 (SIWIS and Hi-Fi TTS datasets)',
      'fr/fr_FR/siwis/medium',
      [
        (
          name: 'fr_FR-siwis-medium.onnx',
          bytes: 63221984,
          digest:
              'b1d946fd68d0347155fa59bce0a018924abbef3c1561181db45ca463d83963ef',
        ),
        (
          name: 'fr_FR-siwis-medium.onnx.json',
          bytes: 5458,
          digest:
              'df814aa3dfedd00510a07144442cc0a220ff21e43d03c3b078444fc0be68fc37',
        ),
        (
          name: 'MODEL_CARD',
          bytes: 502,
          digest:
              'f75d76ec577b5e7a49a7462883d31ef65383022387818a9a0b75bdaf90b9010c',
        ),
      ],
    ),
  ];

  final Future<Directory> Function() _directory;
  final http.Client Function() _client;
  static final _idPattern = RegExp(r'^[A-Za-z0-9_-]{1,100}$');

  static Future<Directory> _defaultDirectory() async => Directory(
    p.join(
      (await getApplicationSupportDirectory()).path,
      'speech',
      'piper-voices',
    ),
  );

  Future<List<SpeechChoice>> list() async {
    final root = await _directory();
    if (!await root.exists()) return const [];
    final voices = <SpeechChoice>[];
    await for (final entry in root.list(followLinks: false)) {
      if (entry is! Directory) continue;
      final id = p.basename(entry.path);
      if (!_idPattern.hasMatch(id)) continue;
      final config = File(p.join(entry.path, '$id.onnx.json'));
      if (!await File(p.join(entry.path, '$id.onnx')).exists() ||
          !await _safeConfig(config)) {
        continue;
      }
      final descriptor = downloads.where((voice) => voice.id == id).firstOrNull;
      voices.add(
        SpeechChoice(
          id,
          descriptor?.label ?? id,
          language: descriptor?.language,
          locality: SpeechLocality.offline,
        ),
      );
    }
    return voices..sort((a, b) => a.label.compareTo(b.label));
  }

  Future<File> resolve(String id) async {
    if (_idPattern.hasMatch(id)) {
      final root = await _directory();
      final location = p.join(root.path, id);
      final file = File(p.join(location, '$id.onnx'));
      if (await FileSystemEntity.type(location, followLinks: false) ==
              FileSystemEntityType.directory &&
          await FileSystemEntity.type(file.path, followLinks: false) ==
              FileSystemEntityType.file &&
          await file.length() > 0 &&
          await _safeConfig(File('${file.path}.json'))) {
        return file;
      }
    }
    throw const AiException(
      AiFailureCode.invalidConfiguration,
      'Select an installed Piper voice with its matching configuration.',
    );
  }

  static Future<bool> _safeConfig(File file) async {
    if (await FileSystemEntity.type(file.path, followLinks: false) !=
            FileSystemEntityType.file ||
        await file.length() > 1024 * 1024) {
      return false;
    }
    try {
      final data = objectMap(jsonDecode(await file.readAsString()));
      final sampleRate = objectMap(data['audio'])['sample_rate'];
      return sampleRate is int && sampleRate >= 8000 && sampleRate <= 96000;
    } on FormatException {
      return false;
    }
  }

  Future<void> install(
    PiperDownload voice, {
    required AiCancellationToken cancellationToken,
    void Function(int received, int total)? onProgress,
  }) async {
    if (!downloads.contains(voice)) {
      throw ArgumentError('Unrecognized Piper voice.');
    }
    final client = _client();
    try {
      await _publish(voice.id, cancellationToken, (stage) async {
        var received = 0;
        for (final file in voice._files) {
          final uri = Uri.https(
            'huggingface.co',
            '/rhasspy/piper-voices/resolve/$revision/${voice.path}/${file.name}',
          );
          final bytes = await _download(client, uri, cancellationToken);
          final target = File(p.join(stage.path, file.name));
          await _capture(
            bytes,
            target,
            cancellationToken,
            file.bytes,
            onBytes: (size) => onProgress?.call(received + size, voice.size),
          );
          if (await target.length() != file.bytes ||
              (await sha256.bind(target.openRead()).first).toString() !=
                  file.digest) {
            throw const AiException(
              AiFailureCode.validation,
              'The Piper voice failed its integrity check.',
            );
          }
          received += file.bytes;
        }
        await File(p.join(stage.path, 'PROVENANCE.json')).writeAsString(
          jsonEncode({
            'source':
                'https://huggingface.co/rhasspy/piper-voices/tree/$revision/${voice.path}',
            'license': voice.license,
            'sha256': {for (final file in voice._files) file.name: file.digest},
          }),
          flush: true,
        );
      });
    } finally {
      client.close();
    }
  }

  Future<void> importVoice(
    File model,
    File config,
    File modelCard, {
    required AiCancellationToken cancellationToken,
  }) async {
    final id = p.basenameWithoutExtension(model.path);
    if (p.extension(model.path) != '.onnx' ||
        !_idPattern.hasMatch(id) ||
        p.basename(config.path) != '$id.onnx.json') {
      throw const AiException(
        AiFailureCode.invalidConfiguration,
        'Choose an ONNX voice and its matching .onnx.json configuration.',
      );
    }
    await _publish(id, cancellationToken, (stage) async {
      for (final (source, name, maximum) in [
        (model, '$id.onnx', 250 * 1024 * 1024),
        (config, '$id.onnx.json', 1024 * 1024),
        (modelCard, 'MODEL_CARD', 1024 * 1024),
      ]) {
        if (await source.length() > maximum) {
          throw const AiException(
            AiFailureCode.responseTooLarge,
            'A Piper voice file exceeds its size limit.',
          );
        }
        await _capture(
          source.openRead(),
          File(p.join(stage.path, name)),
          cancellationToken,
          maximum,
        );
      }
      if (!await _safeConfig(File(p.join(stage.path, '$id.onnx.json')))) {
        throw const AiException(
          AiFailureCode.validation,
          'The Piper voice configuration is invalid.',
        );
      }
    });
  }

  Future<void> _publish(
    String id,
    AiCancellationToken token,
    Future<void> Function(Directory stage) populate,
  ) async {
    token.throwIfCancelled();
    final root = await _directory();
    await root.create(recursive: true);
    final target = p.join(root.path, id);
    final stage = await root.createTemp('.voice-');
    try {
      await populate(stage);
      token.throwIfCancelled();
      if (await FileSystemEntity.type(target, followLinks: false) !=
          FileSystemEntityType.notFound) {
        throw const AiException(
          AiFailureCode.invalidConfiguration,
          'This Piper voice is already installed.',
        );
      }
      await stage.rename(target);
    } finally {
      if (await stage.exists()) await stage.delete(recursive: true);
    }
  }

  Future<Stream<List<int>>> _download(
    http.Client client,
    Uri uri,
    AiCancellationToken token,
  ) async {
    final deadline = AiDeadline(const Duration(minutes: 4));
    for (var redirects = 0; redirects < 5; redirects++) {
      if (uri.scheme != 'https' ||
          uri.userInfo.isNotEmpty ||
          uri.port != 443 ||
          !(uri.host == 'huggingface.co' ||
              uri.host.endsWith('.huggingface.co') ||
              uri.host.endsWith('.hf.co'))) {
        break;
      }
      final request = http.AbortableRequest(
        'GET',
        uri,
        abortTrigger: deadline.abortTrigger(token),
      )..followRedirects = false;
      final response = await deadline.wait(
        client.send(request),
        token,
        timeoutMessage: 'The Piper voice download timed out.',
      );
      if (response.statusCode == 200) return response.stream;
      await response.stream.listen(null).cancel();
      final location = response.headers['location'];
      if (response.statusCode < 300 ||
          response.statusCode >= 400 ||
          location == null) {
        break;
      }
      uri = uri.resolve(location);
    }
    throw const AiException(
      AiFailureCode.rejected,
      'The official Piper voice download could not be completed.',
    );
  }

  Future<void> _capture(
    Stream<List<int>> input,
    File target,
    AiCancellationToken token,
    int limit, {
    void Function(int size)? onBytes,
  }) async {
    final iterator = StreamIterator(input);
    final out = await target.open(mode: FileMode.write);
    final deadline = AiDeadline(const Duration(minutes: 4));
    var received = 0;
    try {
      while (await moveNextWithDeadline(
        iterator,
        token,
        deadline,
        timeoutMessage: 'The Piper voice file could not be read in time.',
      )) {
        final bytes = iterator.current;
        received += bytes.length;
        if (received > limit) {
          throw const AiException(
            AiFailureCode.responseTooLarge,
            'The Piper voice file exceeds its size limit.',
          );
        }
        await out.writeFrom(bytes);
        onBytes?.call(received);
      }
      if (received == 0) invalidSpeechResponse();
      await out.flush();
    } finally {
      await out.close();
      await iterator.cancel();
    }
  }
}
