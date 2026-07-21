import 'dart:async';

import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/l10n/generated/app_localizations_en.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/busymark_dialogs.dart';
import 'package:busymark/src/feedback/feedback_metadata.dart';
import 'package:busymark/src/feedback/feedback_service.dart';
import 'package:busymark/src/feedback/feedback_submission.dart';
import 'package:busymark/src/feedback/presentation/feedback_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaru/yaru.dart';

void main() {
  final l10n = AppLocalizationsEn();

  testWidgets('shows required-field validation without sending', (
    tester,
  ) async {
    final service = _FakeFeedbackService();
    await _pumpDialog(tester, service);

    await tester.tap(find.byKey(BusyMarkFeedbackKeys.submit));
    await tester.pump();

    expect(find.text(l10n.feedbackCategoryRequired), findsOneWidget);
    expect(find.text(l10n.feedbackSubjectLength), findsOneWidget);
    expect(find.text(l10n.feedbackMessageLength), findsOneWidget);
    expect(service.submissions, isEmpty);
  });

  testWidgets('rejects an invalid optional reply email', (tester) async {
    final service = _FakeFeedbackService();
    await _pumpDialog(tester, service);
    await _enterValidRequiredFields(tester, l10n);
    await tester.enterText(
      find.byKey(BusyMarkFeedbackKeys.replyEmail),
      'invalid-address',
    );

    await tester.tap(find.byKey(BusyMarkFeedbackKeys.submit));
    await tester.pump();

    expect(find.text(l10n.feedbackReplyEmailInvalid), findsOneWidget);
    expect(service.submissions, isEmpty);
  });

  testWidgets('disables submit while a request is active', (tester) async {
    final completion = Completer<FeedbackReceipt>();
    final service = _FakeFeedbackService(handler: (_) => completion.future);
    await _pumpDialog(tester, service);
    await _enterValidRequiredFields(tester, l10n);

    await tester.tap(find.byKey(BusyMarkFeedbackKeys.submit));
    await tester.pump();

    expect(service.submissions, hasLength(1));
    expect(service.submissions.single.technicalDetails, isNull);
    expect(find.text(l10n.feedbackSubmitting), findsOneWidget);
    final button = tester.widget<BusyMarkDialogButton>(
      find.byKey(BusyMarkFeedbackKeys.submit),
    );
    expect(button.onPressed, isNull);

    completion.complete(const FeedbackReceipt('BM-LOADING'));
    await tester.pumpAndSettle();
  });

  testWidgets('clears the form and shows the server reference on success', (
    tester,
  ) async {
    final service = _FakeFeedbackService(
      handler: (_) async => const FeedbackReceipt('BM-12345'),
    );
    await _pumpDialog(tester, service);
    await _enterValidRequiredFields(tester, l10n);
    await tester.tap(find.byKey(BusyMarkFeedbackKeys.technicalDetails));
    await tester.pump();

    await tester.tap(find.byKey(BusyMarkFeedbackKeys.submit));
    await tester.pumpAndSettle();

    expect(find.text(l10n.feedbackSuccess('BM-12345')), findsOneWidget);
    expect(service.submissions, hasLength(1));
    final submission = service.submissions.single;
    expect(submission.appVersion, '9.8.7');
    expect(submission.buildNumber, '42');
    expect(submission.technicalDetails, isNotNull);
    expect(submission.technicalDetails!.locale, 'en');
    expect(submission.technicalDetails!.osVersion, isNotEmpty);
    expect(
      tester
          .widget<TextField>(find.byKey(BusyMarkFeedbackKeys.subject))
          .controller
          ?.text,
      isEmpty,
    );
    expect(
      tester
          .widget<TextField>(find.byKey(BusyMarkFeedbackKeys.message))
          .controller
          ?.text,
      isEmpty,
    );
    expect(find.text(l10n.feedbackChooseCategory), findsOneWidget);
  });

  testWidgets('shows a distinct message when the server rejects the form', (
    tester,
  ) async {
    final service = _FakeFeedbackService(
      handler: (_) async =>
          throw const FeedbackSubmissionException(FeedbackFailureKind.rejected),
    );
    await _pumpDialog(tester, service);
    await _enterValidRequiredFields(tester, l10n);

    await tester.tap(find.byKey(BusyMarkFeedbackKeys.submit));
    await tester.pumpAndSettle();

    expect(find.text(l10n.feedbackRejectedFailure), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(BusyMarkFeedbackKeys.subject))
          .controller
          ?.text,
      'Example subject',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(BusyMarkFeedbackKeys.message))
          .controller
          ?.text,
      'Detailed example message',
    );
  });

  testWidgets('keeps retry UUID until submitted content changes', (
    tester,
  ) async {
    final service = _FakeFeedbackService(
      handler: (_) async =>
          throw const FeedbackSubmissionException(FeedbackFailureKind.server),
    );
    await _pumpDialog(tester, service);
    await _enterValidRequiredFields(tester, l10n);
    await tester.enterText(
      find.byKey(BusyMarkFeedbackKeys.replyEmail),
      'person@example.com',
    );

    await tester.tap(find.byKey(BusyMarkFeedbackKeys.submit));
    await tester.pumpAndSettle();

    expect(find.text(l10n.feedbackServerFailure), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(BusyMarkFeedbackKeys.subject))
          .controller
          ?.text,
      'Example subject',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(BusyMarkFeedbackKeys.message))
          .controller
          ?.text,
      'Detailed example message',
    );

    await tester.tap(find.byKey(BusyMarkFeedbackKeys.submit));
    await tester.pumpAndSettle();

    expect(service.submissions, hasLength(2));
    expect(
      service.submissions.last.submissionId,
      service.submissions.first.submissionId,
    );

    await tester.enterText(
      find.byKey(BusyMarkFeedbackKeys.subject),
      'Changed example subject',
    );
    await tester.tap(find.byKey(BusyMarkFeedbackKeys.submit));
    await tester.pumpAndSettle();

    expect(service.submissions, hasLength(3));
    expect(
      service.submissions[2].submissionId,
      isNot(service.submissions[1].submissionId),
    );

    await tester.tap(find.byKey(BusyMarkFeedbackKeys.category));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.feedbackCategoryFeature).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(BusyMarkFeedbackKeys.submit));
    await tester.pumpAndSettle();

    expect(service.submissions, hasLength(4));
    expect(
      service.submissions[3].submissionId,
      isNot(service.submissions[2].submissionId),
    );

    await tester.tap(find.byKey(BusyMarkFeedbackKeys.technicalDetails));
    await tester.pump();
    await tester.tap(find.byKey(BusyMarkFeedbackKeys.submit));
    await tester.pumpAndSettle();

    expect(service.submissions, hasLength(5));
    expect(
      service.submissions[4].submissionId,
      isNot(service.submissions[3].submissionId),
    );
  });

  testWidgets('cannot dismiss the dialog while submission is active', (
    tester,
  ) async {
    final completion = Completer<FeedbackReceipt>();
    final service = _FakeFeedbackService(handler: (_) => completion.future);
    await _pumpDialogRoute(tester, service);
    await _enterValidRequiredFields(tester, l10n);

    await tester.tap(find.byKey(BusyMarkFeedbackKeys.submit));
    await tester.pump();

    expect(find.byType(BusyMarkFeedbackDialog), findsOneWidget);
    expect(
      tester
          .widget<YaruDialogTitleBar>(find.byType(YaruDialogTitleBar))
          .isClosable,
      isFalse,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.byType(BusyMarkFeedbackDialog), findsOneWidget);

    await tester.tapAt(const Offset(4, 4));
    await tester.pump();
    expect(find.byType(BusyMarkFeedbackDialog), findsOneWidget);

    completion.complete(const FeedbackReceipt('BM-NON-DISMISSIBLE'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<YaruDialogTitleBar>(find.byType(YaruDialogTitleBar))
          .isClosable,
      isTrue,
    );
    await tester.tap(find.byKey(BusyMarkFeedbackKeys.cancel));
    await tester.pumpAndSettle();
    expect(find.byType(BusyMarkFeedbackDialog), findsNothing);
  });
}

Future<void> _pumpDialog(
  WidgetTester tester,
  _FakeFeedbackService service,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1000, 900);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  var id = 0;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        feedbackSubmissionServiceProvider.overrideWithValue(service),
        feedbackAppMetadataLoaderProvider.overrideWithValue(
          _TestMetadataLoader(),
        ),
        feedbackSubmissionIdGeneratorProvider.overrideWithValue(
          () => '3b45c9a8-f0dc-4f36-a26e-${(++id).toString().padLeft(12, '0')}',
        ),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: BusyMarkModalEditorSurface(
              maxHeight: 840,
              child: const BusyMarkFeedbackDialog(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpDialogRoute(
  WidgetTester tester,
  _FakeFeedbackService service,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1000, 900);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  var id = 0;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        feedbackSubmissionServiceProvider.overrideWithValue(service),
        feedbackAppMetadataLoaderProvider.overrideWithValue(
          _TestMetadataLoader(),
        ),
        feedbackSubmissionIdGeneratorProvider.overrideWithValue(
          () => '3b45c9a8-f0dc-4f36-a26e-${(++id).toString().padLeft(12, '0')}',
        ),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => showBusyMarkFeedbackDialog(context),
                child: const Text('Open feedback'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open feedback'));
  await tester.pumpAndSettle();
}

Future<void> _enterValidRequiredFields(
  WidgetTester tester,
  AppLocalizationsEn l10n,
) async {
  await tester.tap(find.byKey(BusyMarkFeedbackKeys.category));
  await tester.pumpAndSettle();
  await tester.tap(find.text(l10n.feedbackCategoryProblem).last);
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(BusyMarkFeedbackKeys.subject),
    'Example subject',
  );
  await tester.enterText(
    find.byKey(BusyMarkFeedbackKeys.message),
    'Detailed example message',
  );
}

class _FakeFeedbackService implements FeedbackSubmissionService {
  _FakeFeedbackService({this.handler});

  final Future<FeedbackReceipt> Function(FeedbackSubmission submission)?
  handler;
  final submissions = <FeedbackSubmission>[];

  @override
  Future<FeedbackReceipt> submit(FeedbackSubmission submission) {
    submissions.add(submission);
    return handler?.call(submission) ??
        Future.value(const FeedbackReceipt('BM-DEFAULT'));
  }
}

class _TestMetadataLoader implements FeedbackAppMetadataLoader {
  @override
  Future<FeedbackAppMetadata> load() async {
    return const FeedbackAppMetadata(version: '9.8.7', buildNumber: '42');
  }
}
