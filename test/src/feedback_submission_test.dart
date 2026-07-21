import 'package:busymark/src/feedback/feedback_submission.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FeedbackValidator', () {
    test('requires category and enforces subject and message bounds', () {
      final result = FeedbackValidator.validate(
        category: null,
        subject: 'ab',
        message: 'too short',
        replyEmail: '',
      );

      expect(result.isValid, isFalse);
      expect(
        result[FeedbackField.category],
        FeedbackValidationError.categoryRequired,
      );
      expect(
        result[FeedbackField.subject],
        FeedbackValidationError.subjectLength,
      );
      expect(
        result[FeedbackField.message],
        FeedbackValidationError.messageLength,
      );
    });

    test('accepts inclusive subject and message boundaries', () {
      final minimum = FeedbackValidator.validate(
        category: FeedbackCategory.problem,
        subject: 'abc',
        message: '0123456789',
        replyEmail: '',
      );
      final maximum = FeedbackValidator.validate(
        category: FeedbackCategory.other,
        subject: List.filled(120, 's').join(),
        message: List.filled(5000, 'm').join(),
        replyEmail: 'person@example.com',
      );

      expect(minimum.isValid, isTrue);
      expect(maximum.isValid, isTrue);
    });

    test('rejects oversized fields and invalid optional email', () {
      final result = FeedbackValidator.validate(
        category: FeedbackCategory.feature,
        subject: List.filled(121, 's').join(),
        message: List.filled(5001, 'm').join(),
        replyEmail: 'not-an-email',
      );

      expect(
        result[FeedbackField.subject],
        FeedbackValidationError.subjectLength,
      );
      expect(
        result[FeedbackField.message],
        FeedbackValidationError.messageLength,
      );
      expect(
        result[FeedbackField.replyEmail],
        FeedbackValidationError.replyEmailInvalid,
      );
    });

    test('counts Unicode code points at subject and message boundaries', () {
      final belowMinimum = FeedbackValidator.validate(
        category: FeedbackCategory.problem,
        subject: '😀😀',
        message: List.filled(9, '😀').join(),
        replyEmail: '',
      );
      final minimum = FeedbackValidator.validate(
        category: FeedbackCategory.problem,
        subject: '😀😀😀',
        message: List.filled(10, '😀').join(),
        replyEmail: '',
      );
      final maximum = FeedbackValidator.validate(
        category: FeedbackCategory.problem,
        subject: List.filled(120, '😀').join(),
        message: List.filled(5000, '😀').join(),
        replyEmail: '',
      );

      expect(
        belowMinimum[FeedbackField.subject],
        FeedbackValidationError.subjectLength,
      );
      expect(
        belowMinimum[FeedbackField.message],
        FeedbackValidationError.messageLength,
      );
      expect(minimum.isValid, isTrue);
      expect(maximum.isValid, isTrue);
    });

    test('accepts practical valid email syntax', () {
      final maximumLengthEmail =
          '${List.filled(64, 'a').join()}@'
          '${List.filled(63, 'b').join()}.'
          '${List.filled(63, 'c').join()}.'
          '${List.filled(61, 'd').join()}';
      for (final email in [
        'person@example.com',
        'person+tag@example.co.uk',
        'a@localhost',
        '${List.filled(64, 'a').join()}@example.com',
        maximumLengthEmail,
      ]) {
        final result = FeedbackValidator.validate(
          category: FeedbackCategory.other,
          subject: 'Valid subject',
          message: 'A sufficiently detailed message.',
          replyEmail: email,
        );
        expect(result.isValid, isTrue, reason: email);
      }
    });

    test('rejects malformed email syntax and length boundaries', () {
      final oversizedEmail =
          '${List.filled(64, 'a').join()}@'
          '${List.filled(63, 'b').join()}.'
          '${List.filled(63, 'c').join()}.'
          '${List.filled(62, 'd').join()}';
      for (final email in [
        '.a@example.com',
        'a.@example.com',
        'a..b@example.com',
        'a@example..com',
        'a@-example.com',
        'a@example-.com',
        'a@exam_ple.com',
        'a@@example.com',
        'a b@example.com',
        '${List.filled(65, 'a').join()}@example.com',
        oversizedEmail,
      ]) {
        final result = FeedbackValidator.validate(
          category: FeedbackCategory.other,
          subject: 'Valid subject',
          message: 'A sufficiently detailed message.',
          replyEmail: email,
        );
        expect(
          result[FeedbackField.replyEmail],
          FeedbackValidationError.replyEmailInvalid,
          reason: email,
        );
      }
    });
  });

  group('FeedbackSubmission', () {
    test('serializes required metadata and omits unapproved details', () {
      const submission = FeedbackSubmission(
        submissionId: '3b45c9a8-f0dc-4f36-a26e-3bc653251ed4',
        appVersion: '0.2.1',
        buildNumber: '0',
        category: FeedbackCategory.privacySecurity,
        subject: 'Privacy question',
        message: 'Please explain this privacy behavior.',
        replyEmail: null,
      );

      expect(submission.toJson(), {
        'submissionId': '3b45c9a8-f0dc-4f36-a26e-3bc653251ed4',
        'app': 'busymark',
        'appVersion': '0.2.1',
        'buildNumber': '0',
        'platform': 'linux',
        'category': 'privacy_security',
        'subject': 'Privacy question',
        'message': 'Please explain this privacy behavior.',
        'replyEmail': null,
      });
      expect(submission.toJson(), isNot(contains('technicalDetails')));
    });

    test('serializes only explicitly approved technical details', () {
      const submission = FeedbackSubmission(
        submissionId: '1d26caac-e399-4aca-856a-2e94c8ffda1e',
        appVersion: '0.2.1',
        buildNumber: '0',
        category: FeedbackCategory.usability,
        subject: 'Keyboard navigation',
        message: 'Please improve keyboard navigation here.',
        replyEmail: 'person@example.com',
        technicalDetails: FeedbackTechnicalDetails(
          osVersion: 'Linux 6.x',
          locale: 'en-CA',
        ),
      );

      expect(submission.toJson()['technicalDetails'], {
        'osVersion': 'Linux 6.x',
        'locale': 'en-CA',
      });
    });

    test('uses every declared category wire value', () {
      expect(FeedbackCategory.values.map((category) => category.wireName), [
        'problem',
        'feature',
        'privacy_security',
        'usability',
        'other',
      ]);
    });
  });
}
