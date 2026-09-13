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
      Uri.file(htmlPath).toString(),
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
    final request = await client.getUrl(
      Uri.http('${uri.host}:${uri.port}', '/json/list'),
    );
    final response = await request.close();
    final targets =
        jsonDecode(await response.transform(utf8.decoder).join()) as List;
    final page = targets.cast<Map<String, dynamic>>().firstWhere(
      (t) => t['type'] == 'page',
    );
    socket = await WebSocket.connect(page['webSocketDebuggerUrl'] as String);
    final messages = StreamIterator<dynamic>(socket);
    socket.add(
      jsonEncode({
        'id': 1,
        'method': 'Runtime.evaluate',
        'params': {
          'expression':
              '''(async () => {
          if (document.readyState !== 'complete') {
            await new Promise(resolve => addEventListener('load', resolve, {once:true}));
          }
          return $expression;
        })()''',
          'awaitPromise': true,
          'returnByValue': true,
        },
      }),
    );
    Future<Object?> readResult() async {
      while (await messages.moveNext()) {
        final message = jsonDecode(messages.current as String) as Map;
        if (message['id'] != 1) continue;
        if (message['error'] != null ||
            message['result']['exceptionDetails'] != null) {
          throw StateError('Browser evaluation failed: $message');
        }
        return message['result']['result']['value'];
      }
      throw StateError('Browser closed before evaluating styles.');
    }

    return await readResult().timeout(const Duration(seconds: 15));
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
