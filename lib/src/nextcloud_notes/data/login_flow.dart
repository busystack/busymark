import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'notes_capabilities.dart';
import 'server_uri.dart';

enum NextcloudLoginFailure {
  network,
  server,
  malformedResponse,
  unsafeRedirect,
  browserUnavailable,
  timedOut,
  cancelled,
}

class NextcloudLoginException implements Exception {
  const NextcloudLoginException(this.code, this.message);

  final NextcloudLoginFailure code;
  final String message;

  @override
  String toString() => message;
}

class NextcloudLoginCancellation {
  final _cancelled = Completer<void>();
  bool get isCancelled => _cancelled.isCompleted;
  Future<void> get whenCancelled => _cancelled.future;

  void cancel() {
    if (!_cancelled.isCompleted) {
      _cancelled.complete();
    }
  }

  void throwIfCancelled() {
    if (isCancelled) {
      throw const NextcloudLoginException(
        NextcloudLoginFailure.cancelled,
        'Nextcloud sign-in was cancelled.',
      );
    }
  }
}

class NextcloudLoginCredentials {
  const NextcloudLoginCredentials({
    required this.server,
    required this.loginName,
    required this.appPassword,
  });

  final Uri server;
  final String loginName;
  final String appPassword;

  // Deliberately no JSON serialization or credential-bearing toString.
}

class NextcloudLoginRequest {
  const NextcloudLoginRequest({
    required this.login,
    required this.poll,
    required this.token,
    required this.expiresAt,
  });

  final Uri login;
  final Uri poll;
  final String token;
  final DateTime expiresAt;
}

typedef NextcloudExternalBrowser = Future<bool> Function(Uri uri);

/// Nextcloud Login Flow v2. Authentication belongs to the system browser.
class NextcloudLoginFlow {
  NextcloudLoginFlow({
    required http.Client client,
    required NextcloudExternalBrowser openBrowser,
    DateTime Function()? clock,
    Future<void> Function(Duration)? delay,
    this.timeout = const Duration(minutes: 20),
    this.pollInterval = const Duration(seconds: 1),
    this.requestTimeout = const Duration(seconds: 30),
  }) : _client = client,
       _openBrowser = openBrowser,
       _clock = clock ?? DateTime.now,
       _delay = delay ?? Future<void>.delayed;

  final http.Client _client;
  final NextcloudExternalBrowser _openBrowser;
  final DateTime Function() _clock;
  final Future<void> Function(Duration) _delay;
  final Duration timeout;
  final Duration pollInterval;
  final Duration requestTimeout;

  Future<NextcloudLoginRequest> start(Uri server) async {
    final base = normalizeNextcloudServer(server.toString());
    final response = await _post(nextcloudEndpoint(base, 'index.php/login/v2'));
    if (response.statusCode != 200) {
      throw const NextcloudLoginException(
        NextcloudLoginFailure.server,
        'The Nextcloud server could not start browser sign-in.',
      );
    }
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final poll = json['poll'] as Map<String, dynamic>;
      final token = poll['token'];
      if (token is! String || token.isEmpty || token.length > 16384) {
        throw const FormatException();
      }
      return NextcloudLoginRequest(
        login: nextcloudFlowEndpoint(base, json['login']),
        poll: nextcloudFlowEndpoint(base, poll['endpoint']),
        token: token,
        expiresAt: _clock().add(timeout),
      );
    } on Object {
      throw const NextcloudLoginException(
        NextcloudLoginFailure.malformedResponse,
        'The Nextcloud server returned an invalid browser sign-in response.',
      );
    }
  }

  Future<NextcloudLoginCredentials> authenticate(
    Uri server, {
    NextcloudLoginCancellation? cancellation,
    void Function()? onAwaitingBrowser,
  }) async {
    final cancel = cancellation ?? NextcloudLoginCancellation();
    cancel.throwIfCancelled();
    final request = await start(server);
    cancel.throwIfCancelled();
    bool opened;
    try {
      opened = await _openBrowser(request.login);
    } on Object {
      opened = false;
    }
    if (!opened) {
      throw const NextcloudLoginException(
        NextcloudLoginFailure.browserUnavailable,
        'BusyMark could not open the default browser for Nextcloud sign-in.',
      );
    }
    onAwaitingBrowser?.call();
    return poll(request, cancellation: cancel);
  }

  Future<NextcloudLoginCredentials> poll(
    NextcloudLoginRequest request, {
    NextcloudLoginCancellation? cancellation,
  }) async {
    final cancel = cancellation ?? NextcloudLoginCancellation();
    while (true) {
      cancel.throwIfCancelled();
      if (!_clock().isBefore(request.expiresAt)) {
        throw const NextcloudLoginException(
          NextcloudLoginFailure.timedOut,
          'Nextcloud sign-in expired. Start sign-in again.',
        );
      }
      final response = await _post(request.poll, token: request.token);
      if (response.statusCode == 200) {
        try {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          final loginName = json['loginName'];
          final password = json['appPassword'];
          final server = json['server'];
          if (server is! String ||
              loginName is! String ||
              loginName.isEmpty ||
              loginName.contains(':') ||
              loginName.contains(RegExp(r'[\x00-\x1f\x7f]')) ||
              password is! String ||
              password.isEmpty ||
              password.contains('\u0000') ||
              utf8.encode(password).length > 16384) {
            throw const FormatException();
          }
          final credentials = NextcloudLoginCredentials(
            server: normalizeNextcloudServer(server),
            loginName: loginName,
            appPassword: password,
          );
          if (cancel.isCancelled) {
            await revokeNextcloudAppPassword(
              client: _client,
              server: credentials.server,
              loginName: credentials.loginName,
              appPassword: credentials.appPassword,
            );
            cancel.throwIfCancelled();
          }
          return credentials;
        } on NextcloudLoginException {
          rethrow;
        } on Object {
          throw const NextcloudLoginException(
            NextcloudLoginFailure.malformedResponse,
            'The Nextcloud server returned invalid sign-in credentials.',
          );
        }
      }
      cancel.throwIfCancelled();
      if (response.statusCode != 404) {
        throw const NextcloudLoginException(
          NextcloudLoginFailure.server,
          'The Nextcloud server could not complete browser sign-in.',
        );
      }
      await Future.any([_delay(pollInterval), cancel.whenCancelled]);
    }
  }

  Future<http.Response> _post(Uri uri, {String? token}) async {
    final request = http.Request('POST', uri)
      ..followRedirects = false
      ..headers['Accept'] = 'application/json'
      ..headers['User-Agent'] = 'BusyMark Nextcloud Notes';
    if (token != null) {
      request.bodyFields = {'token': token};
    }
    try {
      final response = await _client.send(request).timeout(requestTimeout);
      if (response.statusCode >= 300 && response.statusCode < 400) {
        await response.stream.drain<void>();
        throw const NextcloudLoginException(
          NextcloudLoginFailure.unsafeRedirect,
          'The Nextcloud sign-in endpoint redirected. Use its canonical server URL.',
        );
      }
      return await http.Response.fromStream(response).timeout(requestTimeout);
    } on NextcloudLoginException {
      rethrow;
    } on Object {
      // Client exceptions may contain URLs or proxy details. Never include
      // token-bearing responses or arbitrary transport text in diagnostics.
      throw const NextcloudLoginException(
        NextcloudLoginFailure.network,
        'BusyMark could not reach the Nextcloud server.',
      );
    }
  }
}
