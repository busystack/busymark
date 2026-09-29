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
  WebSocket? socket;
  Uri? browserEndpoint;
  final client = HttpClient();
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
    // DevTools may appear while Chromium is still displaying its initial
    // about:blank page. Evaluating there silently returns default CSS values.
    final deadline = DateTime.now().add(const Duration(seconds: 15));
    Map<String, dynamic>? page;
    do {
      final request = await client.getUrl(
        Uri.http('${uri.host}:${uri.port}', '/json/list'),
      );
      final response = await request.close();
      final targets =
          jsonDecode(await response.transform(utf8.decoder).join()) as List;
      for (final target in targets.cast<Map<String, dynamic>>()) {
        if (target['type'] == 'page' &&
            target['url'] == documentUri.toString()) {
          page = target;
          break;
        }
      }
      if (page != null) break;
      await Future<void>.delayed(const Duration(milliseconds: 25));
    } while (DateTime.now().isBefore(deadline));
    if (page == null) {
      throw StateError('Chromium did not load $documentUri');
    }
    socket = await WebSocket.connect(page['webSocketDebuggerUrl'] as String);
    final messages = StreamIterator<dynamic>(socket);
    final readyDeadline = DateTime.now().add(const Duration(seconds: 15));
    var nextId = 0;
    Object? lastPageState;
    while (DateTime.now().isBefore(readyDeadline)) {
      final id = ++nextId;
      socket.add(
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
      while (await messages.moveNext()) {
        final message = jsonDecode(messages.current as String) as Map;
        if (message['id'] != id) continue;
        if (message['error'] == null &&
            message['result']['exceptionDetails'] == null) {
          final state = message['result']['result']['value'] as Map;
          if (state['ready'] == true) return state['value'];
          lastPageState = state;
        } else {
          // Navigation can destroy the initial execution context. The next
          // evaluation runs in the document's new context.
          lastPageState = message;
        }
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
    throw StateError(
      'Chromium did not finish loading $documentUri: $lastPageState',
    );
  } finally {
    await socket?.close();
    client.close(force: true);
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
