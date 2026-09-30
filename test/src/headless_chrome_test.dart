import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/headless_chrome.dart';

void main() {
  final documentUri = Uri.file('/tmp/busymark-devtools-fixture.html');

  test('evaluates the requested document after it becomes ready', () async {
    final devTools = await _FakeDevTools.start(
      documentUri,
      onEvaluate: (socket, request) =>
          socket.add(_response(request, {'ready': true, 'value': 'ready'})),
    );
    addTearDown(devTools.close);

    expect(
      await _evaluate(
        browserEndpoint: devTools.browserEndpoint,
        documentUri: documentUri,
        expression: 'document.title',
        readinessTimeout: const Duration(seconds: 1),
      ),
      'ready',
    );
    expect(devTools.evaluatedPaths, ['/devtools/page/requested']);
  });

  test('does not evaluate the initial about:blank target', () async {
    final devTools = await _FakeDevTools.start(
      documentUri,
      initialListOnly: true,
      onEvaluate: (socket, request) =>
          socket.add(_response(request, {'ready': true, 'value': 'target'})),
    );
    addTearDown(devTools.close);

    expect(
      await _evaluate(
        browserEndpoint: devTools.browserEndpoint,
        documentUri: documentUri,
        expression: 'document.title',
        readinessTimeout: const Duration(seconds: 1),
      ),
      'target',
    );
    expect(devTools.listRequests, greaterThanOrEqualTo(2));
    expect(devTools.evaluatedPaths, ['/devtools/page/requested']);
  });

  test('retries when navigation destroys the execution context', () async {
    var attempts = 0;
    final devTools = await _FakeDevTools.start(
      documentUri,
      onEvaluate: (socket, request) {
        attempts++;
        socket.add(
          attempts == 1
              ? jsonEncode({
                  'id': request['id'],
                  'error': {
                    'code': -32000,
                    'message': 'Execution context was destroyed.',
                  },
                })
              : _response(request, {
                  'ready': true,
                  'value': 'after navigation',
                }),
        );
      },
    );
    addTearDown(devTools.close);

    expect(
      await _evaluate(
        browserEndpoint: devTools.browserEndpoint,
        documentUri: documentUri,
        expression: 'document.title',
        readinessTimeout: const Duration(seconds: 1),
      ),
      'after navigation',
    );
    expect(attempts, 2);
  });

  test('a silent open DevTools socket respects the readiness bound', () async {
    final responseWait = Stopwatch();
    final devTools = await _FakeDevTools.start(
      documentUri,
      onEvaluate: (_, _) => responseWait.start(),
    );
    addTearDown(devTools.close);

    await expectLater(
      _evaluate(
        browserEndpoint: devTools.browserEndpoint,
        documentUri: documentUri,
        expression: 'document.title',
        readinessTimeout: const Duration(milliseconds: 150),
      ).timeout(const Duration(seconds: 5)),
      throwsA(
        isA<StateError>().having(
          (error) => error.toString(),
          'diagnostic',
          allOf(
            contains('DevTools response timed out'),
            contains('$documentUri'),
          ),
        ),
      ),
    );
    expect(responseWait.elapsed, lessThan(const Duration(seconds: 2)));
    expect(devTools.evaluatedPaths, ['/devtools/page/requested']);
  });

  test('socket closure before a response fails deterministically', () async {
    final devTools = await _FakeDevTools.start(
      documentUri,
      onEvaluate: (socket, _) => socket.close(),
    );
    addTearDown(devTools.close);

    await expectLater(
      _evaluate(
        browserEndpoint: devTools.browserEndpoint,
        documentUri: documentUri,
        expression: 'document.title',
        readinessTimeout: const Duration(milliseconds: 300),
      ).timeout(const Duration(seconds: 2)),
      throwsA(
        isA<StateError>().having(
          (error) => error.toString(),
          'diagnostic',
          allOf(
            contains('socket closed before response'),
            contains('$documentUri'),
          ),
        ),
      ),
    );
  });

  test('a DevTools error is not mistaken for navigation', () async {
    final devTools = await _FakeDevTools.start(
      documentUri,
      onEvaluate: (socket, request) => socket.add(
        jsonEncode({
          'id': request['id'],
          'error': {'code': -32601, 'message': 'Method not found'},
        }),
      ),
    );
    addTearDown(devTools.close);

    await expectLater(
      _evaluate(
        browserEndpoint: devTools.browserEndpoint,
        documentUri: documentUri,
        expression: 'document.title',
        readinessTimeout: const Duration(seconds: 1),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.toString(),
          'diagnostic',
          allOf(contains('evaluation failed'), contains('Method not found')),
        ),
      ),
    );
  });

  test('a page that never becomes ready reports its last state', () async {
    final devTools = await _FakeDevTools.start(
      documentUri,
      onEvaluate: (socket, request) => socket.add(
        _response(request, {
          'ready': false,
          'url': '$documentUri',
          'state': 'loading',
          'styles': 0,
        }),
      ),
    );
    addTearDown(devTools.close);

    await expectLater(
      _evaluate(
        browserEndpoint: devTools.browserEndpoint,
        documentUri: documentUri,
        expression: 'document.title',
        readinessTimeout: const Duration(milliseconds: 150),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.toString(),
          'diagnostic',
          allOf(contains('did not finish loading'), contains('loading')),
        ),
      ),
    );
  });
}

Future<Object?> _evaluate({
  required Uri browserEndpoint,
  required Uri documentUri,
  required String expression,
  required Duration readinessTimeout,
}) => HttpOverrides.runWithHttpOverrides(
  () => evaluateDevToolsDocument(
    browserEndpoint: browserEndpoint,
    documentUri: documentUri,
    expression: expression,
    readinessTimeout: readinessTimeout,
  ),
  _TestHttpOverrides(),
);

class _TestHttpOverrides extends HttpOverrides {}

String _response(Map<String, dynamic> request, Map<String, dynamic> state) =>
    jsonEncode({
      'id': request['id'],
      'result': {
        'result': {'type': 'object', 'value': state},
      },
    });

class _FakeDevTools {
  _FakeDevTools(
    this.server,
    this.documentUri,
    this.onEvaluate,
    this.initialListOnly,
  );

  final HttpServer server;
  final Uri documentUri;
  final FutureOr<void> Function(WebSocket, Map<String, dynamic>) onEvaluate;
  final bool initialListOnly;
  final sockets = <WebSocket>[];
  final evaluatedPaths = <String>[];
  late final StreamSubscription<HttpRequest> subscription;
  var listRequests = 0;

  Uri get browserEndpoint => Uri.parse(
    'ws://${server.address.address}:${server.port}/devtools/browser',
  );

  static Future<_FakeDevTools> start(
    Uri documentUri, {
    required FutureOr<void> Function(WebSocket, Map<String, dynamic>)
    onEvaluate,
    bool initialListOnly = false,
  }) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final fixture = _FakeDevTools(
      server,
      documentUri,
      onEvaluate,
      initialListOnly,
    );
    fixture.subscription = server.listen(fixture._handleRequest);
    return fixture;
  }

  Future<void> _handleRequest(HttpRequest request) async {
    if (request.uri.path == '/json/list') {
      listRequests++;
      final targets = <Map<String, String>>[
        {
          'type': 'page',
          'url': 'about:blank',
          'webSocketDebuggerUrl':
              'ws://${server.address.address}:${server.port}/devtools/page/initial',
        },
        if (!initialListOnly || listRequests > 1)
          {
            'type': 'page',
            'url': '$documentUri',
            'webSocketDebuggerUrl':
                'ws://${server.address.address}:${server.port}/devtools/page/requested',
          },
      ];
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(targets));
      await request.response.close();
      return;
    }
    if (request.uri.path.startsWith('/devtools/page/')) {
      evaluatedPaths.add(request.uri.path);
      final socket = await WebSocketTransformer.upgrade(request);
      sockets.add(socket);
      socket.listen((data) {
        final message = jsonDecode(data as String) as Map<String, dynamic>;
        onEvaluate(socket, message);
      });
      return;
    }
    request.response.statusCode = HttpStatus.notFound;
    await request.response.close();
  }

  Future<void> close() async {
    for (final socket in sockets) {
      await socket.close();
    }
    await subscription.cancel();
    await server.close(force: true);
  }
}
