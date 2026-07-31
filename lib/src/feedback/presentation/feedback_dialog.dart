import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:yaru/yaru.dart';

import '../../app/busymark_design.dart';
import '../../app/busymark_dialogs.dart';
import '../../app/localization.dart';
import '../../platform/linux_header_bar_service.dart';
import '../feedback_metadata.dart';
import '../feedback_service.dart';
import '../feedback_submission.dart';

typedef FeedbackSubmissionIdGenerator = String Function();

final feedbackSubmissionIdGeneratorProvider =
    Provider<FeedbackSubmissionIdGenerator>((ref) {
      final uuid = Uuid();
      return uuid.v4;
    });

abstract final class BusyMarkFeedbackKeys {
  static const category = ValueKey<String>('feedback.category');
  static const subject = ValueKey<String>('feedback.subject');
  static const message = ValueKey<String>('feedback.message');
  static const replyEmail = ValueKey<String>('feedback.replyEmail');
  static const technicalDetails = ValueKey<String>('feedback.technicalDetails');
  static const submit = ValueKey<String>('feedback.submit');
  static const cancel = ValueKey<String>('feedback.cancel');
  static const status = ValueKey<String>('feedback.status');
}

void showBusyMarkFeedbackDialog(
  BuildContext context, {
  LinuxHeaderBarService? headerBarService,
}) {
  unawaited(
    showBusyMarkModalEditorDialog<void>(
      context,
      headerBarService: headerBarService,
      maxWidth: 680,
      maxHeight: 760,
      builder: (dialogContext) => BusyMarkFeedbackDialog(
        onCancel: () => Navigator.of(dialogContext).pop(),
      ),
    ),
  );
}

class BusyMarkFeedbackDialog extends ConsumerStatefulWidget {
  const BusyMarkFeedbackDialog({super.key, this.onCancel});

  final VoidCallback? onCancel;

  @override
  ConsumerState<BusyMarkFeedbackDialog> createState() =>
      _BusyMarkFeedbackDialogState();
}

class _BusyMarkFeedbackDialogState
    extends ConsumerState<BusyMarkFeedbackDialog> {
  late final TextEditingController _subjectController;
  late final TextEditingController _messageController;
  late final TextEditingController _replyEmailController;
  late String _submissionId;
  FeedbackCategory? _category;
  FeedbackFailureKind? _failure;
  String? _receiptId;
  var _includeTechnicalDetails = false;
  var _showValidationErrors = false;
  var _submissionAttempted = false;
  var _submitting = false;
  var _suppressFieldChanges = false;

  @override
  void initState() {
    super.initState();
    _submissionId = ref.read(feedbackSubmissionIdGeneratorProvider)();
    _subjectController = TextEditingController()
      ..addListener(_handleFieldChanged);
    _messageController = TextEditingController()
      ..addListener(_handleFieldChanged);
    _replyEmailController = TextEditingController()
      ..addListener(_handleFieldChanged);
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    _replyEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final validation = FeedbackValidator.validate(
      category: _category,
      subject: _subjectController.text,
      message: _messageController.text,
      replyEmail: _replyEmailController.text,
    );
    final categoryError = _showValidationErrors
        ? _validationMessage(context, validation[FeedbackField.category])
        : null;
    final subjectError = _showValidationErrors
        ? _validationMessage(context, validation[FeedbackField.subject])
        : null;
    final messageError = _showValidationErrors
        ? _validationMessage(context, validation[FeedbackField.message])
        : null;
    final replyEmailError = _showValidationErrors
        ? _validationMessage(context, validation[FeedbackField.replyEmail])
        : null;
    return PopScope(
      canPop: !_submitting,
      child: CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.escape): _cancel},
        child: Focus(
          autofocus: true,
          child: BusyMarkModalEditorScaffold(
            title: context.l10n.reportIssue,
            cancelLabel: context.l10n.cancel,
            saveLabel: context.l10n.feedbackSubmit,
            cancelKey: BusyMarkFeedbackKeys.cancel,
            saveKey: BusyMarkFeedbackKeys.submit,
            onCancel: _cancel,
            cancelEnabled: !_submitting,
            onSave: _submitting ? null : _submit,
            saving: _submitting,
            children: [
              BusyMarkGroupedList(
                filled: true,
                children: [
                  BusyMarkComboRow<FeedbackCategory?>(
                    key: BusyMarkFeedbackKeys.category,
                    title: context.l10n.feedbackCategory,
                    errorText: categoryError,
                    values: const [null, ...FeedbackCategory.values],
                    selected: _category,
                    labelFor: (category) => category == null
                        ? context.l10n.feedbackChooseCategory
                        : _categoryLabel(context, category),
                    enabled: !_submitting,
                    onSelected: _setCategory,
                  ),
                  YaruListTile.square(
                    title: TextField(
                      key: BusyMarkFeedbackKeys.subject,
                      controller: _subjectController,
                      enabled: !_submitting,
                      textInputAction: TextInputAction.next,
                      decoration: busyMarkGroupedTextFieldDecoration(
                        context,
                        labelText: context.l10n.feedbackSubject,
                        errorText: subjectError,
                      ),
                    ),
                  ),
                  YaruListTile.square(
                    title: TextField(
                      key: BusyMarkFeedbackKeys.message,
                      controller: _messageController,
                      enabled: !_submitting,
                      minLines: 4,
                      maxLines: 8,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      decoration: busyMarkGroupedTextFieldDecoration(
                        context,
                        labelText: context.l10n.feedbackMessage,
                        alignLabelWithHint: true,
                        errorText: messageError,
                      ),
                    ),
                  ),
                  YaruListTile.square(
                    title: TextField(
                      key: BusyMarkFeedbackKeys.replyEmail,
                      controller: _replyEmailController,
                      enabled: !_submitting,
                      textDirection: TextDirection.ltr,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      decoration: busyMarkGroupedTextFieldDecoration(
                        context,
                        labelText: context.l10n.feedbackReplyEmail,
                        errorText: replyEmailError,
                      ),
                      onSubmitted: (_) {
                        if (!_submitting) {
                          _submit();
                        }
                      },
                    ),
                  ),
                ],
              ),
              BusyMarkGroupedList(
                filled: true,
                children: [
                  YaruCheckboxListTile(
                    key: BusyMarkFeedbackKeys.technicalDetails,
                    value: _includeTechnicalDetails,
                    onChanged: _submitting
                        ? null
                        : (value) =>
                              _setIncludeTechnicalDetails(value ?? false),
                    title: Text(context.l10n.feedbackIncludeTechnicalDetails),
                    subtitle: Text(
                      context.l10n.feedbackTechnicalDetailsDisclosure,
                    ),
                    shape: const RoundedRectangleBorder(),
                  ),
                ],
              ),
              if (_receiptId != null || _failure != null) ...[
                const SizedBox(height: BusyMarkSpacing.md),
                Semantics(
                  key: BusyMarkFeedbackKeys.status,
                  liveRegion: true,
                  child: Text(
                    _receiptId != null
                        ? context.l10n.feedbackSuccess(_receiptId!)
                        : _failureMessage(context, _failure!),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _failure != null
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: BusyMarkSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  void _cancel() {
    if (_submitting) {
      return;
    }
    final onCancel = widget.onCancel;
    if (onCancel != null) {
      onCancel();
      return;
    }
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  void _handleFieldChanged() {
    if (_suppressFieldChanges || !mounted) {
      return;
    }
    setState(() {
      _rotateSubmissionIdAfterAttempt();
      _failure = null;
      _receiptId = null;
    });
  }

  void _setIncludeTechnicalDetails(bool value) {
    if (value == _includeTechnicalDetails) {
      return;
    }
    setState(() {
      _rotateSubmissionIdAfterAttempt();
      _includeTechnicalDetails = value;
      _failure = null;
      _receiptId = null;
    });
  }

  void _setCategory(FeedbackCategory? category) {
    setState(() {
      if (category != _category) {
        _rotateSubmissionIdAfterAttempt();
      }
      _category = category;
      _failure = null;
      _receiptId = null;
    });
  }

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }
    final validation = FeedbackValidator.validate(
      category: _category,
      subject: _subjectController.text,
      message: _messageController.text,
      replyEmail: _replyEmailController.text,
    );
    if (!validation.isValid) {
      setState(() {
        _showValidationErrors = true;
        _failure = null;
        _receiptId = null;
      });
      return;
    }

    final locale = Localizations.localeOf(context).toLanguageTag();
    setState(() {
      _submissionAttempted = true;
      _submitting = true;
      _failure = null;
      _receiptId = null;
    });

    try {
      final metadata = await ref.read(feedbackAppMetadataLoaderProvider).load();
      final replyEmail = _replyEmailController.text.trim();
      final submission = FeedbackSubmission(
        submissionId: _submissionId,
        appVersion: metadata.version,
        buildNumber: metadata.buildNumber,
        category: _category!,
        subject: _subjectController.text.trim(),
        message: _messageController.text.trim(),
        replyEmail: replyEmail.isEmpty ? null : replyEmail,
        technicalDetails: _includeTechnicalDetails
            ? FeedbackTechnicalDetails(
                osVersion: Platform.operatingSystemVersion,
                locale: locale,
              )
            : null,
      );
      final receipt = await ref
          .read(feedbackSubmissionServiceProvider)
          .submit(submission);
      if (!mounted) {
        return;
      }
      _suppressFieldChanges = true;
      _subjectController.clear();
      _messageController.clear();
      _replyEmailController.clear();
      _suppressFieldChanges = false;
      setState(() {
        _submitting = false;
        _category = null;
        _includeTechnicalDetails = false;
        _showValidationErrors = false;
        _submissionAttempted = false;
        _receiptId = receipt.id;
        _submissionId = ref.read(feedbackSubmissionIdGeneratorProvider)();
      });
    } on FeedbackSubmissionException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _failure = error.kind;
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _failure = FeedbackFailureKind.server;
      });
    }
  }

  void _rotateSubmissionIdAfterAttempt() {
    if (!_submissionAttempted) {
      return;
    }
    _submissionId = ref.read(feedbackSubmissionIdGeneratorProvider)();
    _submissionAttempted = false;
  }

  String _categoryLabel(BuildContext context, FeedbackCategory category) {
    return switch (category) {
      FeedbackCategory.problem => context.l10n.feedbackCategoryProblem,
      FeedbackCategory.feature => context.l10n.feedbackCategoryFeature,
      FeedbackCategory.privacySecurity =>
        context.l10n.feedbackCategoryPrivacySecurity,
      FeedbackCategory.usability => context.l10n.feedbackCategoryUsability,
      FeedbackCategory.other => context.l10n.feedbackCategoryOther,
    };
  }

  String? _validationMessage(
    BuildContext context,
    FeedbackValidationError? error,
  ) {
    return switch (error) {
      FeedbackValidationError.categoryRequired =>
        context.l10n.feedbackCategoryRequired,
      FeedbackValidationError.subjectLength =>
        context.l10n.feedbackSubjectLength,
      FeedbackValidationError.messageLength =>
        context.l10n.feedbackMessageLength,
      FeedbackValidationError.replyEmailInvalid =>
        context.l10n.feedbackReplyEmailInvalid,
      null => null,
    };
  }

  String _failureMessage(BuildContext context, FeedbackFailureKind failure) {
    return switch (failure) {
      FeedbackFailureKind.connection => context.l10n.feedbackConnectionFailure,
      FeedbackFailureKind.timeout => context.l10n.feedbackTimeoutFailure,
      FeedbackFailureKind.rateLimited =>
        context.l10n.feedbackRateLimitedFailure,
      FeedbackFailureKind.rejected => context.l10n.feedbackRejectedFailure,
      FeedbackFailureKind.server => context.l10n.feedbackServerFailure,
    };
  }
}
