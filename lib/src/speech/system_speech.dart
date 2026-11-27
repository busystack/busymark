import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../ai/ai_http_transport.dart';
import '../ai/ai_models.dart';
import 'speech_provider.dart';

typedef _Reply = ({int code, List<String> values});

/// A single Speech Dispatcher client on the desktop's local Unix socket.
class SystemSpeech {
  SystemSpeech._(this._socket) {
    _subscription = _socket
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          _receive,
          onError: (Object _) => _disconnected(),
          onDone: _disconnected,
        );
  }

  final Socket _socket;
  late final StreamSubscription<String> _subscription;
  Completer<_Reply>? _pending;
  Future<void> _commands = Future.value();
  final _lines = <String>[];
  final _terminal = <int, int>{};
  final _finished = StreamController<int>.broadcast();
  bool _closed = false;
  int? _code;
  int _responseLength = 0;

  static const defaultModule = 'espeak-ng';

  static SpeechLocality locality(String module) => switch (module) {
    'espeak-ng' || 'espeak' || 'openjtalk' => SpeechLocality.offline,
    'ibmtts-cloud' => SpeechLocality.remote,
    _ => SpeechLocality.unknown,
  };

  static Future<SystemSpeech> connect() async {
    if (!Platform.isLinux) throw _unavailable;
    final configured = Platform.environment['SPEECHD_ADDRESS'];
    final runtime = Platform.environment['XDG_RUNTIME_DIR'];
    final path = switch (configured) {
      final String value when value.startsWith('unix_socket:') =>
        value.substring('unix_socket:'.length),
      null when runtime != null => p.join(
        runtime,
        'speech-dispatcher',
        'speechd.sock',
      ),
      _ => null,
    };
    if (path == null || !p.isAbsolute(path)) throw _unavailable;
    try {
      return SystemSpeech._(
        await Socket.connect(
          InternetAddress(path, type: InternetAddressType.unix),
          0,
          timeout: const Duration(seconds: 2),
        ),
      );
    } on SocketException {
      throw _unavailable;
    }
  }

  static const _unavailable = AiException(
    AiFailureCode.connection,
    'The desktop Speech Dispatcher service is unavailable to BusyMark.',
  );

  static Future<SpeechCatalog> discover(
    AiCancellationToken cancellationToken,
  ) async {
    cancellationToken.throwIfCancelled();
    SystemSpeech? client;
    try {
      client = await connect();
      final modules = await client.modules();
      final voices = <SpeechChoice>[];
      for (final model in modules) {
        cancellationToken.throwIfCancelled();
        await client._command('SET SELF OUTPUT_MODULE ${model.id}');
        final reply = await client._command(
          'LIST SYNTHESIS_VOICES',
          allowFailure: true,
        );
        for (final line in reply.values) {
          final values = line.split('\t');
          if (values.length < 2 || !_valueSafe(values[0])) continue;
          voices.add(
            SpeechChoice(
              values[0],
              values[0],
              language: values[1],
              model: model.id,
              locality: model.locality,
            ),
          );
        }
      }
      return SpeechCatalog(
        models: List.unmodifiable(modules),
        voices: List.unmodifiable(voices),
        unavailableReason: modules.isEmpty
            ? 'No system speech engines are available.'
            : null,
      );
    } on AiException catch (error) {
      if (error.code == AiFailureCode.cancelled) rethrow;
      return SpeechCatalog(unavailableReason: error.message);
    } finally {
      await client?.close();
    }
  }

  Future<List<SpeechChoice>> modules() async {
    final reply = await _command('LIST OUTPUT_MODULES');
    final modules = <SpeechChoice>[];
    for (final name in reply.values) {
      if (!RegExp(r'^[a-zA-Z0-9_-]{1,64}$').hasMatch(name)) continue;
      modules.add(SpeechChoice(name, name, locality: locality(name)));
    }
    return modules;
  }

  Future<void> configure(
    SpeechOptions options, {
    required bool allowUnverifiedModule,
  }) async {
    final module = options.model.isEmpty ? defaultModule : options.model;
    final available = (await modules()).any((choice) => choice.id == module);
    if (!available) {
      throw const AiException(
        AiFailureCode.invalidConfiguration,
        'Select an available Speech Dispatcher output module.',
      );
    }
    if (locality(module) != SpeechLocality.offline && !allowUnverifiedModule) {
      throw const AiException(
        AiFailureCode.invalidConfiguration,
        'Allow this system speech module to receive the narration first. '
        'The module may send text over the network.',
      );
    }
    await _command('SET SELF CLIENT_NAME "busymark:busymark:narration"');
    await _command('SET SELF OUTPUT_MODULE $module');
    await _command('SET SELF SSML_MODE OFF');
    await _command('SET SELF PRIORITY TEXT');
    await _command('SET SELF NOTIFICATION END ON');
    await _command('SET SELF NOTIFICATION CANCEL ON');
  }

  Future<void> speak(
    String text, {
    required AiCancellationToken cancellationToken,
    String? voice,
    String? language,
  }) async {
    final queued = await _serialize(() async {
      cancellationToken.throwIfCancelled();
      if (language != null && language.isNotEmpty) {
        if (!RegExp(r'^[a-zA-Z0-9-]{1,64}$').hasMatch(language)) {
          throw _badSelection;
        }
        await _send('SET SELF LANGUAGE $language');
      }
      if (voice != null && voice.isNotEmpty) {
        if (!_valueSafe(voice)) throw _badSelection;
        await _send('SET SELF SYNTHESIS_VOICE $voice');
      }
      final receiving = await _send('SPEAK');
      if (receiving.code != 230) throw _unavailable;
      final body = const LineSplitter()
          .convert(text.replaceAll('\u0000', ''))
          .map((line) => line.startsWith('.') ? '.$line' : line)
          .join('\r\n');
      return _send('$body\r\n.');
    });
    final id = int.tryParse(queued.values.firstOrNull ?? '');
    if (queued.code != 225 || id == null) throw _unavailable;
    try {
      if (!_terminal.containsKey(id)) {
        final wait = _finished.stream.firstWhere(
          (value) => value == id || value == -1,
        );
        final received = await AiDeadline(const Duration(minutes: 5)).wait(
          wait,
          cancellationToken,
          timeoutMessage: 'System narration did not finish in time.',
        );
        if (received == -1) throw _unavailable;
      }
      if (_terminal.remove(id) != 702) {
        throw const AiException(
          AiFailureCode.cancelled,
          'System narration was cancelled.',
        );
      }
    } finally {
      if (cancellationToken.isCancelled) await stop();
    }
  }

  Future<void> pause() async {
    await _command('PAUSE SELF');
  }

  Future<void> resume() async {
    await _command('RESUME SELF');
  }

  Future<void> stop() async {
    if (_closed) return;
    try {
      await _command('CANCEL SELF', allowFailure: true);
    } on AiException {
      // The connection might have closed before cancellation was acknowledged.
    }
  }

  static bool _valueSafe(String value) =>
      value.isNotEmpty &&
      value.length <= 200 &&
      !RegExp(r'[\x00-\x1f\x7f"]').hasMatch(value);

  static const _badSelection = AiException(
    AiFailureCode.invalidConfiguration,
    'The selected system speech language or voice is invalid.',
  );

  Future<T> _serialize<T>(Future<T> Function() work) {
    final result = _commands.then((_) => work());
    _commands = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  Future<_Reply> _command(String command, {bool allowFailure = false}) =>
      _serialize(() => _send(command, allowFailure: allowFailure));

  Future<_Reply> _send(String command, {bool allowFailure = false}) async {
    if (_closed || _pending != null) throw _unavailable;
    final pending = Completer<_Reply>();
    _pending = pending;
    try {
      _socket.write('$command\r\n');
      final reply = await pending.future.timeout(const Duration(seconds: 3));
      if (reply.code ~/ 100 != 2 && !allowFailure) throw _badSelection;
      return reply;
    } on TimeoutException {
      await close();
      throw _unavailable;
    } on SocketException {
      throw _unavailable;
    } finally {
      if (identical(_pending, pending)) _pending = null;
    }
  }

  void _receive(String line) {
    if (_closed) return;
    final code = line.length >= 4 ? int.tryParse(line.substring(0, 3)) : null;
    _responseLength += line.length;
    if (code == null ||
        line.length > 2048 ||
        _responseLength > 2 * 1024 * 1024 ||
        (_code != null && _code != code) ||
        _lines.length >= 20000) {
      _disconnected();
      return;
    }
    _code = code;
    if (line[3] == '-') {
      _lines.add(line.substring(4));
      return;
    }
    final values = _lines.toList(growable: false);
    _lines.clear();
    _code = null;
    _responseLength = 0;
    if (code == 702 || code == 703) {
      final id = int.tryParse(values.firstOrNull ?? '');
      if (id != null && _terminal.length < 16) {
        _terminal[id] = code;
        _finished.add(id);
      }
    } else if (code < 700) {
      final pending = _pending;
      _pending = null;
      pending?.complete((code: code, values: values));
    }
  }

  void _disconnected() {
    if (_closed) return;
    _closed = true;
    final pending = _pending;
    _pending = null;
    pending?.completeError(_unavailable);
    _finished.add(-1);
    _socket.destroy();
    unawaited(_finished.close());
  }

  Future<void> close() async {
    _disconnected();
    await _subscription.cancel();
  }
}
