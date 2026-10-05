import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Optional browser integration, using the installed browser's DevTools API.
final String? headlessChromePath = [
  Platform.environment['BUSYMARK_CHROME_PATH'],
  '/usr/bin/google-chrome',
  '/usr/bin/chromium',
  '/usr/bin/chromium-browser',
].whereType<String>().where((path) => File(path).existsSync()).firstOrNull;

Future<Object?> evaluateInChrome(String htmlPath, String expression) =>
    HttpOverrides.runWithHttpOverrides(
      () => _evaluateInChrome(htmlPath, expression),
      _BrowserHttpOverrides(),
    );

class _BrowserHttpOverrides extends HttpOverrides {}

Future<Object?> _evaluateInChrome(String htmlPath, String expression) async {
  final profile = await Directory.systemTemp.createTemp('html-csp-browser-');
  Process? browser;
  Uri? browserEndpoint;
  final documentUri = Uri.file(htmlPath);
  try {
    final endpoint = Completer<Uri>();
    browser = await Process.start(headlessChromePath!, [
      '--headless=new',
      '--no-first-run',
      '--disable-background-networking',
      '--disable-component-update',
      '--remote-debugging-port=0',
      '--user-data-dir=${profile.path}',
      '--proxy-server=http://127.0.0.1:9',
      '--proxy-bypass-list=127.0.0.1;localhost',
      documentUri.toString(),
    ]);
    unawaited(browser.stdout.drain<void>());
    browser.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          const prefix = 'DevTools listening on ';
          if (line.startsWith(prefix) && !endpoint.isCompleted) {
            endpoint.complete(Uri.parse(line.substring(prefix.length)));
          }
        });
    final uri = await endpoint.future.timeout(const Duration(seconds: 15));
    browserEndpoint = uri;
    return await evaluateDevToolsDocument(
      browserEndpoint: uri,
      documentUri: documentUri,
      expression: expression,
    );
  } finally {
    if (browser != null) {
      if (browserEndpoint != null) {
        final control = await WebSocket.connect(browserEndpoint.toString());
        control.add(jsonEncode({'id': 2, 'method': 'Browser.close'}));
        await control.drain<void>().timeout(const Duration(seconds: 5));
      } else {
        browser.kill();
      }
      await browser.exitCode.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          browser!.kill(ProcessSignal.sigkill);
          return browser.exitCode;
        },
      );
    }
    await profile.delete(recursive: true);
  }
}

/// The narrow DevTools protocol seam used by the fake-server regression tests.
Future<Object?> evaluateDevToolsDocument({
  required Uri browserEndpoint,
  required Uri documentUri,
  required String expression,
  Duration targetTimeout = const Duration(seconds: 15),
  Duration readinessTimeout = const Duration(seconds: 15),
}) async {
  final client = HttpClient();
  WebSocket? socket;
  StreamIterator<dynamic>? messages;
  try {
    // DevTools may appear while Chromium is still displaying its initial
    // about:blank page. Evaluating there silently returns default CSS values.
    final targetClock = Stopwatch()..start();
    Map<String, dynamic>? page;
    Object? lastTargetState;
    Future<T> waitForTarget<T>(Future<T> pending) {
      final remaining = targetTimeout - targetClock.elapsed;
      StateError timedOut() => StateError(
        'Chromium did not load $documentUri before the DevTools target '
        'deadline; last targets: $lastTargetState',
      );
      if (remaining <= Duration.zero) throw timedOut();
      return pending.timeout(remaining, onTimeout: () => throw timedOut());
    }

    while (page == null && targetClock.elapsed < targetTimeout) {
      final request = await waitForTarget(
        client.getUrl(
          Uri.http(
            '${browserEndpoint.host}:${browserEndpoint.port}',
            '/json/list',
          ),
        ),
      );
      final response = await waitForTarget(request.close());
      final targets =
          jsonDecode(
                await waitForTarget(response.transform(utf8.decoder).join()),
              )
              as List;
      lastTargetState = targets;
      for (final target in targets.cast<Map<String, dynamic>>()) {
        if (target['type'] == 'page' &&
            target['url'] == documentUri.toString()) {
          page = target;
          break;
        }
      }
      if (page != null) break;
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
    if (page == null) {
      throw StateError(
        'Chromium did not load $documentUri; last targets: $lastTargetState',
      );
    }
    final evaluationSocket = await waitForTarget(
      WebSocket.connect(page['webSocketDebuggerUrl'] as String),
    );
    socket = evaluationSocket;
    messages = StreamIterator<dynamic>(evaluationSocket);
    final readyClock = Stopwatch()..start();
    var nextId = 0;
    Object? lastPageState;
    while (readyClock.elapsed < readinessTimeout) {
      final id = ++nextId;
      try {
        evaluationSocket.add(
          jsonEncode({
            'id': id,
            'method': 'Runtime.evaluate',
            'params': {
              'expression':
                  '''(() => {
              const ready = location.href === ${jsonEncode(documentUri.toString())} &&
                document.readyState === 'complete' &&
                document.querySelector('style') !== null;
              return ready
                ? {ready: true, value: ($expression)}
                : {ready: false, url: location.href,
                   state: document.readyState,
                   styles: document.querySelectorAll('style').length};
            })()''',
              'returnByValue': true,
            },
          }),
        );
      } on StateError catch (error) {
        throw StateError(
          'Chromium DevTools socket closed before response for '
          '$documentUri (request $id): $error; '
          'last page state: $lastPageState',
        );
      }
      while (true) {
        final remaining = readinessTimeout - readyClock.elapsed;
        if (remaining <= Duration.zero) {
          throw StateError(
            'Chromium DevTools response timed out for $documentUri '
            '(request $id); last page state: $lastPageState',
          );
        }
        bool hasMessage;
        try {
          hasMessage = await messages.moveNext().timeout(remaining);
        } on TimeoutException {
          throw StateError(
            'Chromium DevTools response timed out for $documentUri '
            '(request $id); last page state: $lastPageState',
          );
        }
        if (!hasMessage) {
          throw StateError(
            'Chromium DevTools socket closed before response for '
            '$documentUri (request $id); last page state: $lastPageState',
          );
        }
        final message = jsonDecode(messages.current as String) as Map;
        if (message['id'] != id) continue;
        if (message['error'] != null ||
            message['result']['exceptionDetails'] != null) {
          // Navigation can destroy the initial execution context. The next
          // evaluation runs in the document's new context.
          if (_isNavigationContextError(message)) {
            lastPageState = message;
          } else {
            throw StateError(
              'Chromium DevTools evaluation failed for $documentUri: '
              '$message; last page state: $lastPageState',
            );
          }
        } else {
          final state = message['result']['result']['value'] as Map;
          if (state['ready'] == true) return state['value'];
          lastPageState = state;
        }
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
    throw StateError(
      'Chromium did not finish loading $documentUri: $lastPageState',
    );
  } finally {
    await messages?.cancel();
    await socket?.close();
    client.close(force: true);
  }
}

bool _isNavigationContextError(Map message) {
  final details = jsonEncode(message).toLowerCase();
  return details.contains('execution context was destroyed') ||
      details.contains('cannot find context with specified id');
}
