enum FeedbackCategory { problem, feature, privacySecurity, usability, other }

extension FeedbackCategoryWireName on FeedbackCategory {
  String get wireName => switch (this) {
    FeedbackCategory.problem => 'problem',
    FeedbackCategory.feature => 'feature',
    FeedbackCategory.privacySecurity => 'privacy_security',
    FeedbackCategory.usability => 'usability',
    FeedbackCategory.other => 'other',
  };
}

enum FeedbackField { category, subject, message, replyEmail }

enum FeedbackValidationError {
  categoryRequired,
  subjectLength,
  messageLength,
  replyEmailInvalid,
}

class FeedbackValidationResult {
  const FeedbackValidationResult(this.errors);

  final Map<FeedbackField, FeedbackValidationError> errors;

  bool get isValid => errors.isEmpty;

  FeedbackValidationError? operator [](FeedbackField field) => errors[field];
}

abstract final class FeedbackValidator {
  static const subjectMinLength = 3;
  static const subjectMaxLength = 120;
  static const messageMinLength = 10;
  static const messageMaxLength = 5000;

  static FeedbackValidationResult validate({
    required FeedbackCategory? category,
    required String subject,
    required String message,
    required String replyEmail,
  }) {
    final errors = <FeedbackField, FeedbackValidationError>{};
    if (category == null) {
      errors[FeedbackField.category] = FeedbackValidationError.categoryRequired;
    }

    final subjectLength = _codePointLength(subject.trim());
    if (subjectLength < subjectMinLength || subjectLength > subjectMaxLength) {
      errors[FeedbackField.subject] = FeedbackValidationError.subjectLength;
    }

    final messageLength = _codePointLength(_normalizeMessage(message));
    if (messageLength < messageMinLength || messageLength > messageMaxLength) {
      errors[FeedbackField.message] = FeedbackValidationError.messageLength;
    }

    final email = replyEmail.trim();
    if (email.isNotEmpty && !_isValidEmail(email)) {
      errors[FeedbackField.replyEmail] =
          FeedbackValidationError.replyEmailInvalid;
    }

    return FeedbackValidationResult(Map.unmodifiable(errors));
  }

  static String _normalizeMessage(String value) {
    return value.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
  }

  static int _codePointLength(String value) => value.runes.length;

  static bool _isValidEmail(String value) {
    if (_codePointLength(value) > 254 || _controlPattern.hasMatch(value)) {
      return false;
    }

    final separator = value.indexOf('@');
    if (separator <= 0 ||
        separator != value.lastIndexOf('@') ||
        separator == value.length - 1) {
      return false;
    }

    final localPart = value.substring(0, separator);
    final domain = value.substring(separator + 1);
    if (_codePointLength(localPart) > 64 ||
        localPart.startsWith('.') ||
        localPart.endsWith('.') ||
        localPart.contains('..') ||
        !_localPartPattern.hasMatch(localPart) ||
        _codePointLength(domain) > 253 ||
        domain.startsWith('.') ||
        domain.endsWith('.') ||
        domain.contains('..')) {
      return false;
    }

    for (final label in domain.split('.')) {
      if (label.isEmpty ||
          label.length > 63 ||
          label.startsWith('-') ||
          label.endsWith('-') ||
          !_domainLabelPattern.hasMatch(label)) {
        return false;
      }
    }
    return true;
  }

  static final _controlPattern = RegExp(r'[\x00-\x20\x7f]');
  static final _localPartPattern = RegExp(
    r"^[A-Za-z0-9!#$%&'*+/=?^_`{|}~.-]+$",
  );
  static final _domainLabelPattern = RegExp(r'^[A-Za-z0-9-]+$');
}

class FeedbackTechnicalDetails {
  const FeedbackTechnicalDetails({
    required this.osVersion,
    required this.locale,
  });

  final String osVersion;
  final String locale;

  Map<String, Object?> toJson() => {'osVersion': osVersion, 'locale': locale};
}

class FeedbackSubmission {
  const FeedbackSubmission({
    required this.submissionId,
    required this.appVersion,
    required this.buildNumber,
    required this.category,
    required this.subject,
    required this.message,
    required this.replyEmail,
    this.technicalDetails,
  });

  static const applicationId = 'busymark';
  static const platform = 'linux';

  final String submissionId;
  final String appVersion;
  final String buildNumber;
  final FeedbackCategory category;
  final String subject;
  final String message;
  final String? replyEmail;
  final FeedbackTechnicalDetails? technicalDetails;

  Map<String, Object?> toJson() => {
    'submissionId': submissionId,
    'app': applicationId,
    'appVersion': appVersion,
    'buildNumber': buildNumber,
    'platform': platform,
    'category': category.wireName,
    'subject': subject,
    'message': message,
    'replyEmail': replyEmail,
    if (technicalDetails != null)
      'technicalDetails': technicalDetails!.toJson(),
  };
}
