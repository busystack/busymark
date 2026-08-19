import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'ai_models.dart';

class AiDeadline {
  AiDeadline(Duration duration)
    : _duration = duration,
      _stopwatch = Stopwatch()..start();

  final Duration _duration;
  final Stopwatch _stopwatch;

  Duration get remaining {
    final value = _duration - _stopwatch.elapsed;
    return value.isNegative ? Duration.zero : value;
  }

  Future<void> abortTrigger(AiCancellationToken cancellationToken) {
    return Future.any<void>([
      cancellationToken.whenCancelled,
      Future<void>.delayed(remaining),
    ]);
  }

  Future<T> wait<T>(
    Future<T> operation,
    AiCancellationToken cancellationToken, {
    required String timeoutMessage,
  }) async {
    cancellationToken.throwIfCancelled();
    final available = remaining;
    if (available == Duration.zero) {
      throw AiException(AiFailureCode.timeout, timeoutMessage, retryable: true);
    }
    final marker = Object();
    try {
      final result = await Future.any<Object?>([
        operation,
        cancellationToken.whenCancelled.then<Object?>((_) => marker),
      ]).timeout(available);
      if (identical(result, marker)) {
        cancellationToken.throwIfCancelled();
      }
      return result as T;
    } on TimeoutException {
      throw AiException(AiFailureCode.timeout, timeoutMessage, retryable: true);
    } on http.RequestAbortedException {
      cancellationToken.throwIfCancelled();
      throw AiException(AiFailureCode.timeout, timeoutMessage, retryable: true);
    }
  }

  AiException timeout(String message) =>
      AiException(AiFailureCode.timeout, message, retryable: true);

  @override
  String toString() => 'AiDeadline(${_duration.inSeconds}s)';
}

class AiHttpTransport {
  const AiHttpTransport();

  Future<http.StreamedResponse> send({
    required http.Client client,
    required http.BaseRequest request,
    required AiCancellationToken cancellationToken,
    required AiDeadline deadline,
    required String providerName,
  }) async {
    final http.StreamedResponse response;
    try {
      response = await deadline.wait(
        client.send(request),
        cancellationToken,
        timeoutMessage: '$providerName did not respond before the deadline.',
      );
    } on AiException {
      rethrow;
    } on http.RequestAbortedException {
      cancellationToken.throwIfCancelled();
      throw deadline.timeout(
        '$providerName did not respond before the deadline.',
      );
    } on http.ClientException {
      throw AiException(
        AiFailureCode.connection,
        'BusyMark could not connect to $providerName.',
        retryable: true,
      );
    } on SocketException {
      throw AiException(
        AiFailureCode.connection,
        'BusyMark could not connect to $providerName.',
        retryable: true,
      );
    }
    cancellationToken.throwIfCancelled();
    if (response.isRedirect ||
        (response.statusCode >= 300 && response.statusCode < 400)) {
      throw AiException(
        AiFailureCode.rejected,
        '$providerName redirects are not allowed.',
        statusCode: response.statusCode,
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final retryAfter = parseRetryAfter(response.headers['retry-after']);
      final status = response.statusCode;
      throw AiException(
        status == 429 ? AiFailureCode.rateLimited : AiFailureCode.rejected,
        '$providerName returned HTTP $status.',
        retryable:
            status == 408 || status == 409 || status == 429 || status >= 500,
        retryAfter: retryAfter,
        statusCode: status,
      );
    }
    return response;
  }

  Future<Uint8List> readBounded({
    required Stream<List<int>> stream,
    required int maximumBytes,
    required AiCancellationToken cancellationToken,
    required AiDeadline deadline,
    required String timeoutMessage,
    required String tooLargeMessage,
  }) async {
    final bytes = BytesBuilder(copy: false);
    var length = 0;
    final iterator = StreamIterator<List<int>>(stream);
    try {
      while (await deadline.wait(
        iterator.moveNext(),
        cancellationToken,
        timeoutMessage: timeoutMessage,
      )) {
        final chunk = iterator.current;
        length += chunk.length;
        if (length > maximumBytes) {
          throw AiException(AiFailureCode.responseTooLarge, tooLargeMessage);
        }
        bytes.add(chunk);
      }
    } finally {
      unawaited(iterator.cancel());
    }
    return bytes.takeBytes();
  }

  static Duration? parseRetryAfter(String? value, {DateTime? now}) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return null;
    }
    final seconds = int.tryParse(normalized);
    if (seconds != null) {
      return seconds < 0 ? Duration.zero : Duration(seconds: seconds);
    }
    try {
      final target = HttpDate.parse(normalized);
      final duration = target.difference(now ?? DateTime.now().toUtc());
      return duration.isNegative ? Duration.zero : duration;
    } on Object {
      return null;
    }
  }
}

const aiCancelledMarker = Object();

Future<bool> moveNextWithDeadline<T>(
  StreamIterator<T> iterator,
  AiCancellationToken cancellationToken,
  AiDeadline deadline, {
  required String timeoutMessage,
}) {
  return deadline.wait(
    iterator.moveNext(),
    cancellationToken,
    timeoutMessage: timeoutMessage,
  );
}
