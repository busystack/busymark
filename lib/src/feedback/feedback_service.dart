import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'feedback_submission.dart';

const feedbackEndpointUrl = String.fromEnvironment(
  'BUSYSTACK_FEEDBACK_ENDPOINT',
  defaultValue: 'https://busystack.org/api/feedback',
);

const feedbackRequestTimeout = Duration(seconds: 15);

class FeedbackReceipt {
  const FeedbackReceipt(this.id);

  final String id;
}

enum FeedbackFailureKind { connection, timeout, rateLimited, rejected, server }

class FeedbackSubmissionException implements Exception {
  const FeedbackSubmissionException(this.kind, {this.retryAfter});

  final FeedbackFailureKind kind;
  final Duration? retryAfter;
}

abstract interface class FeedbackSubmissionService {
  Future<FeedbackReceipt> submit(FeedbackSubmission submission);
}

class HttpFeedbackSubmissionService implements FeedbackSubmissionService {
  const HttpFeedbackSubmissionService({
    required http.Client client,
    required Uri endpoint,
    this.timeout = feedbackRequestTimeout,
  }) : _client = client,
       _endpoint = endpoint;

  final http.Client _client;
  final Uri _endpoint;
  final Duration timeout;

  @override
  Future<FeedbackReceipt> submit(FeedbackSubmission submission) async {
    try {
      final response = await _client
          .post(
            _endpoint,
            headers: const {
              HttpHeaders.acceptHeader: 'application/json',
              HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
            },
            body: jsonEncode(submission.toJson()),
          )
          .timeout(timeout);
      if (response.statusCode == HttpStatus.tooManyRequests) {
        throw FeedbackSubmissionException(
          FeedbackFailureKind.rateLimited,
          retryAfter: _parseRetryAfter(response.headers['retry-after']),
        );
      }
      if (response.statusCode == HttpStatus.badRequest ||
          response.statusCode == HttpStatus.unprocessableEntity) {
        throw const FeedbackSubmissionException(FeedbackFailureKind.rejected);
      }
      if (response.statusCode != HttpStatus.created) {
        throw const FeedbackSubmissionException(FeedbackFailureKind.server);
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FeedbackSubmissionException(FeedbackFailureKind.server);
      }
      final id = decoded['id'];
      if (id is! String || id.trim().isEmpty) {
        throw const FeedbackSubmissionException(FeedbackFailureKind.server);
      }
      return FeedbackReceipt(id.trim());
    } on FeedbackSubmissionException {
      rethrow;
    } on TimeoutException {
      throw const FeedbackSubmissionException(FeedbackFailureKind.timeout);
    } on SocketException {
      throw const FeedbackSubmissionException(FeedbackFailureKind.connection);
    } on http.ClientException {
      throw const FeedbackSubmissionException(FeedbackFailureKind.connection);
    } on Object {
      throw const FeedbackSubmissionException(FeedbackFailureKind.server);
    }
  }

  Duration? _parseRetryAfter(String? value) {
    final seconds = int.tryParse(value?.trim() ?? '');
    return seconds == null || seconds < 0 ? null : Duration(seconds: seconds);
  }
}

final feedbackHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final feedbackSubmissionServiceProvider = Provider<FeedbackSubmissionService>(
  (ref) => HttpFeedbackSubmissionService(
    client: ref.watch(feedbackHttpClientProvider),
    endpoint: Uri.parse(feedbackEndpointUrl),
  ),
);
