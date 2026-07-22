import 'dart:async';
import 'dart:convert';

import 'package:busymark/src/feedback/feedback_service.dart';
import 'package:busymark/src/feedback/feedback_submission.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'posts the serialized request and returns the server reference',
    () async {
      late http.Request captured;
      final service = HttpFeedbackSubmissionService(
        client: MockClient((request) async {
          captured = request;
          return http.Response('{"id":"BM-123"}', 201);
        }),
        endpoint: Uri.parse('https://example.test/api/feedback'),
      );

      final receipt = await service.submit(_submission);

      expect(receipt.id, 'BM-123');
      expect(captured.method, 'POST');
      expect(captured.url, Uri.parse('https://example.test/api/feedback'));
      expect(
        captured.headers['content-type'],
        'application/json; charset=utf-8',
      );
      expect(jsonDecode(captured.body), _submission.toJson());
    },
  );

  test('maps connection failures', () async {
    final service = HttpFeedbackSubmissionService(
      client: MockClient((request) async {
        throw http.ClientException('offline', request.url);
      }),
      endpoint: Uri.parse('https://example.test/api/feedback'),
    );

    await expectLater(
      service.submit(_submission),
      throwsA(_failure(FeedbackFailureKind.connection)),
    );
  });

  test('maps response timeouts', () async {
    final pending = Completer<http.Response>();
    final service = HttpFeedbackSubmissionService(
      client: MockClient((request) => pending.future),
      endpoint: Uri.parse('https://example.test/api/feedback'),
      timeout: const Duration(milliseconds: 1),
    );

    await expectLater(
      service.submit(_submission),
      throwsA(_failure(FeedbackFailureKind.timeout)),
    );
  });

  test('maps HTTP 429 and preserves Retry-After', () async {
    final service = HttpFeedbackSubmissionService(
      client: MockClient(
        (request) async => http.Response(
          '{"error":"rate_limited"}',
          429,
          headers: {'retry-after': '90'},
        ),
      ),
      endpoint: Uri.parse('https://example.test/api/feedback'),
    );

    await expectLater(
      service.submit(_submission),
      throwsA(
        _failure(FeedbackFailureKind.rateLimited).having(
          (error) => error.retryAfter,
          'retryAfter',
          const Duration(seconds: 90),
        ),
      ),
    );
  });

  test('maps HTTP 400 and 422 to rejected request failures', () async {
    for (final statusCode in [400, 422]) {
      final service = HttpFeedbackSubmissionService(
        client: MockClient(
          (request) async =>
              http.Response('{"error":"invalid_request"}', statusCode),
        ),
        endpoint: Uri.parse('https://example.test/api/feedback'),
      );

      await expectLater(
        service.submit(_submission),
        throwsA(_failure(FeedbackFailureKind.rejected)),
        reason: 'HTTP $statusCode',
      );
    }
  });

  test(
    'maps server and malformed-response failures to server errors',
    () async {
      final unavailable = HttpFeedbackSubmissionService(
        client: MockClient(
          (request) async => http.Response('{"error":"unavailable"}', 503),
        ),
        endpoint: Uri.parse('https://example.test/api/feedback'),
      );
      final malformed = HttpFeedbackSubmissionService(
        client: MockClient((request) async => http.Response('{}', 201)),
        endpoint: Uri.parse('https://example.test/api/feedback'),
      );

      await expectLater(
        unavailable.submit(_submission),
        throwsA(_failure(FeedbackFailureKind.server)),
      );
      await expectLater(
        malformed.submit(_submission),
        throwsA(_failure(FeedbackFailureKind.server)),
      );
    },
  );
}

TypeMatcher<FeedbackSubmissionException> _failure(FeedbackFailureKind kind) =>
    isA<FeedbackSubmissionException>().having(
      (error) => error.kind,
      'kind',
      kind,
    );

const _submission = FeedbackSubmission(
  submissionId: '3b45c9a8-f0dc-4f36-a26e-3bc653251ed4',
  appVersion: '0.2.1',
  buildNumber: '0',
  category: FeedbackCategory.problem,
  subject: 'Example subject',
  message: 'Detailed example message',
  replyEmail: null,
);
