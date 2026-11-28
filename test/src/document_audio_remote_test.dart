import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:busymark/src/app/localization.dart';
import 'package:busymark/src/editor/audio_authoring.dart';
import 'package:busymark/src/editor/document_audio_view.dart';
import 'package:busymark/src/speech/speech_pcm.dart';
import 'package:busymark/src/speech/speech_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;

import '../support/widget_async.dart';

const _channel = MethodChannel('com.busymark.app/audio_player');
final _wave = encodeSpeechWave(SpeechPcm(Uint8List(4800), sampleRate: 24000));

Set<String> _downloadDirectories() => {
  for (final entry in Directory.systemTemp.listSync())
    if (entry is Directory &&
        p.basename(entry.path).startsWith('busymark-media-'))
      entry.path,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> selectAudio(WidgetTester tester, String markup) async {
    final audio = parseAuthoredAudio(markup)!;
    final document = (
      opening: 'test',
      identity: 'test',
      path: null,
      revision: 1,
      mediaIdentity: null,
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: busyMarkLocalizationsDelegates,
        home: DocumentAudioScope(
          document: document,
          openDocuments: {'test': document},
          rootPath: null,
          child: Material(child: BusyMarkDocumentAudioView(audio: audio)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> state(int id, String name) => TestDefaultBinaryMessengerBinding
      .instance
      .defaultBinaryMessenger
      .handlePlatformMessage(
        _channel.name,
        const StandardMethodCodec().encodeMethodCall(
          MethodCall('state', {'id': id, 'state': name}),
        ),
        (_) {},
      );

  testWidgets(
    'invalid remote file retires its directory before the next source opens',
    (tester) async {
      final baseline = _downloadDirectories();
      final requests = <Uri>[];
      final retired = <_Client>[];
      String? lastPath;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(_channel, (call) async {
        final arguments = call.arguments as Map;
        if (call.method == 'open') {
          lastPath = arguments['path'] as String;
          expect(File(lastPath!).readAsBytesSync(), _wave);
          expect(_downloadDirectories().difference(baseline), {
            p.dirname(lastPath!),
          });
          await state(arguments['id'] as int, 'playing');
        }
        if (call.method == 'position') {
          return {'position': 0.0, 'duration': 0.1, 'seekable': true};
        }
        return true;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(_channel, null));
      _Client createClient() {
        final client = _Client((uri) {
          requests.add(uri);
          if (uri.path == '/invalid') {
            return _Response(Stream.value([0, 0, 0, 0, 0, 0]), 6);
          }
          expect(uri.path, '/recording');
          expect(_downloadDirectories().difference(baseline), isEmpty);
          return _Response(Stream.value(_wave), _wave.length);
        });
        retired.add(client);
        return client;
      }

      await selectAudio(
        tester,
        '<audio controls>'
        '<source src="https://example.invalid/invalid">'
        '<source src="https://example.invalid/recording">'
        '</audio>',
      );
      await HttpOverrides.runZoned(() async {
        await tester.tap(find.bySemanticsLabel('Play'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(requests, isEmpty);
        await tester.runAsync(
          () => tester.tap(find.text('Allow in this document')),
        );
        await pumpUntil(
          tester,
          () => find.bySemanticsLabel('Pause').evaluate().isNotEmpty,
          operation: 'fall back to the second audio source',
        );
        expect(requests.map((uri) => uri.path), ['/invalid', '/recording']);
        expect(retired.every((client) => client.closed), isTrue);
        await tester.runAsync(settleDocumentAudioForWindowClose);
        expect(_downloadDirectories().difference(baseline), isEmpty);
      }, createHttpClient: (_) => createClient());
    },
  );

  testWidgets(
    'an open-ended HTTPS response reaches the decoder before EOF and cancels cleanly',
    (tester) async {
      final baseline = _downloadDirectories();
      final network = StreamController<List<int>>();
      final operations = <String>[];
      final accepted = BytesBuilder();
      final client = _Client(
        (uri) => _Response(network.stream, -1),
        onClose: () {
          if (!network.isClosed) unawaited(network.close());
        },
      );
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      var waitOnce = true;
      messenger.setMockMethodCallHandler(_channel, (call) async {
        operations.add(call.method);
        final arguments = call.arguments as Map;
        switch (call.method) {
          case 'openStream':
            expect(arguments.containsKey('path'), isFalse);
            expect(arguments.containsKey('uri'), isFalse);
            return true;
          case 'streamBytes':
            if (waitOnce) {
              waitOnce = false;
              return 0;
            }
            accepted.add(arguments['bytes'] as Uint8List);
            if (accepted.length >= _wave.length) {
              await state(arguments['id'] as int, 'playing');
            }
            return 1;
          case 'position':
            return {'position': 0.1, 'duration': -1.0, 'seekable': false};
          default:
            return true;
        }
      });
      addTearDown(() => messenger.setMockMethodCallHandler(_channel, null));
      await selectAudio(
        tester,
        '<audio controls src="https://example.invalid/live"></audio>',
      );
      await HttpOverrides.runZoned(() async {
        await tester.tap(find.bySemanticsLabel('Play'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(client.requestCount, 0);
        await tester.tap(find.text('Allow in this document'));
        network.add(_wave.sublist(0, 12));
        network.add(_wave.sublist(12));
        await pumpUntil(
          tester,
          () => find.bySemanticsLabel('Pause').evaluate().isNotEmpty,
          operation: 'decode the first bytes before the server sends EOF',
        );
        expect(accepted.takeBytes(), _wave);
        expect(network.isClosed, isFalse);
        expect(operations, isNot(contains('finishStream')));
        expect(find.text('0:00 / —'), findsOneWidget);
        expect(_downloadDirectories().difference(baseline), isEmpty);
        var settled = false;
        final closing = settleDocumentAudioForWindowClose().whenComplete(() {
          settled = true;
        });
        await pumpUntil(
          tester,
          () => settled,
          operation: 'close the decoder and abandon the network stream',
          diagnostics: () => 'client=${client.closed}, operations=$operations',
        );
        await closing;
        expect(client.closed, isTrue);
        expect(operations.last, 'close');
      }, createHttpClient: (_) => client);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets('Play reopens a completed non-seekable HTTPS response', (
    tester,
  ) async {
    final requests = <Uri>[];
    final clients = <_Client>[];
    final opened = <int>[];
    final finished = <int>[];
    final closed = <int>[];
    final received = <int, BytesBuilder>{};
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_channel, (call) async {
      final arguments = call.arguments as Map;
      final id = arguments['id'] as int;
      switch (call.method) {
        case 'openStream':
          opened.add(id);
          received[id] = BytesBuilder();
          return true;
        case 'streamBytes':
          final audio = received[id]!;
          audio.add(arguments['bytes'] as Uint8List);
          if (audio.length == _wave.length) await state(id, 'playing');
          return 1;
        case 'finishStream':
          finished.add(id);
          return 1;
        case 'close':
          closed.add(id);
          return true;
        case 'position':
          return {'position': 0.1, 'duration': -1.0, 'seekable': false};
        default:
          fail('Unexpected native command: ${call.method}');
      }
    });
    addTearDown(() => messenger.setMockMethodCallHandler(_channel, null));

    const url = 'https://example.invalid/live?recording=1';
    await selectAudio(tester, '<audio controls src="$url"></audio>');
    await HttpOverrides.runZoned(
      () async {
        await tester.tap(find.bySemanticsLabel('Play'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(requests, isEmpty);
        await tester.tap(find.text('Allow in this document'));
        await pumpUntil(
          tester,
          () => finished.length == 1,
          operation: 'finish the first response',
        );
        expect(opened, [finished.single]);
        expect(find.bySemanticsLabel('Pause'), findsOneWidget);
        await state(finished.single, 'ended');
        await tester.pump();

        await tester.tap(find.bySemanticsLabel('Play'));
        await pumpUntil(
          tester,
          () => finished.length == 2,
          operation: 'finish the fresh response after one Play',
        );
        expect(opened, finished);
        expect(opened.toSet(), hasLength(2));
        expect(closed, [opened.first]);
        expect(requests, [Uri.parse(url), Uri.parse(url)]);
        expect(find.bySemanticsLabel('Pause'), findsOneWidget);
        expect(find.bySemanticsLabel('Retry'), findsNothing);
        for (final payload in received.values) {
          expect(payload.takeBytes(), _wave);
        }

        await state(finished.last, 'ended');
        await settleDocumentAudioForWindowClose();
        expect(closed, opened);
        expect(clients.every((client) => client.closed), isTrue);
      },
      createHttpClient: (_) {
        final client = _Client((uri) {
          requests.add(uri.removeFragment());
          return _Response(Stream.value(_wave), -1);
        });
        clients.add(client);
        return client;
      },
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

class _Client implements HttpClient {
  _Client(this.response, {this.onClose});
  final _Response Function(Uri) response;
  final void Function()? onClose;
  bool closed = false;
  int requestCount = 0;
  @override
  Duration? connectionTimeout;
  @override
  bool autoUncompress = true;
  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    requestCount++;
    return _Request(response(url));
  }

  @override
  void close({bool force = false}) {
    if (closed) return;
    closed = true;
    onClose?.call();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Request implements HttpClientRequest {
  _Request(this.response);
  final _Response response;
  @override
  bool followRedirects = true;
  @override
  final _Headers headers = _Headers();
  @override
  Future<HttpClientResponse> close() async {
    expect(followRedirects, isFalse);
    expect(headers.recorded, {HttpHeaders.acceptEncodingHeader: 'identity'});
    return response;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Headers implements HttpHeaders {
  final recorded = <String, Object>{};
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) =>
      recorded[name] = value;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Response extends Stream<List<int>> implements HttpClientResponse {
  _Response(this.stream, this.contentLength);
  final Stream<List<int>> stream;
  @override
  final int contentLength;
  @override
  bool get isRedirect => false;
  @override
  int get statusCode => HttpStatus.ok;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => stream.listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
