import 'dart:async';

import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/l10n/generated/app_localizations_en.dart';
import 'package:busymark/src/app/app_theme.dart';
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

  testWidgets('uses the native grouped modal-editor structure', (tester) async {
    final service = _FakeFeedbackService(
      handler: (_) async =>
          throw const FeedbackSubmissionException(FeedbackFailureKind.rejected),
    );
    await _pumpDialog(tester, service);

    final dialog = find.byType(BusyMarkFeedbackDialog);
    Finder dialogDescendant(Finder matching) =>
        find.descendant(of: dialog, matching: matching, matchRoot: true);

    expect(
      dialogDescendant(find.byType(BusyMarkModalEditorScaffold)),
      findsOneWidget,
    );
    expect(dialogDescendant(find.byType(BusyMarkEditorHeader)), findsOneWidget);
    expect(
      dialogDescendant(find.byType(BusyMarkComboRow<FeedbackCategory?>)),
      findsOneWidget,
    );
    expect(
      dialogDescendant(find.byType(BusyMarkGroupedList)),
      findsNWidgets(2),
    );
    expect(dialogDescendant(find.byType(YaruCheckboxListTile)), findsOneWidget);
    expect(dialogDescendant(find.byType(TextField)), findsNWidgets(3));
    expect(dialogDescendant(find.byType(YaruListTile)), findsNWidgets(5));

    for (final key in const [
      BusyMarkFeedbackKeys.subject,
      BusyMarkFeedbackKeys.message,
      BusyMarkFeedbackKeys.replyEmail,
    ]) {
      final field = tester.widget<TextField>(find.byKey(key));
      final decoration = field.decoration!;

      expect(decoration.filled, isFalse);
      expect(decoration.fillColor, Colors.transparent);
      expect(decoration.hoverColor, Colors.transparent);
      expect(decoration.border, InputBorder.none);
      expect(decoration.enabledBorder, InputBorder.none);
      expect(decoration.focusedBorder, InputBorder.none);
      expect(decoration.disabledBorder, InputBorder.none);
      expect(decoration.errorBorder, InputBorder.none);
      expect(decoration.focusedErrorBorder, InputBorder.none);
      expect(decoration.contentPadding, EdgeInsets.zero);
      expect(
        find.ancestor(of: find.byKey(key), matching: find.byType(YaruListTile)),
        findsOneWidget,
      );
    }

    expect(dialogDescendant(find.byType(BusyMarkDialogShell)), findsNothing);
    expect(dialogDescendant(find.byType(YaruDialogTitleBar)), findsNothing);
    expect(dialogDescendant(find.byType(BusyMarkDialogButton)), findsNothing);
    expect(
      dialogDescendant(find.byType(BusyMarkFloatingTextEntry)),
      findsNothing,
    );
    expect(dialogDescendant(find.byType(BusyMarkSwitchRow)), findsNothing);
    expect(dialogDescendant(find.byType(BusyMarkStatusBox)), findsNothing);
    expect(dialogDescendant(find.byType(AlertDialog)), findsNothing);
    expect(
      dialogDescendant(
        find.byWidgetPredicate(
          (widget) => widget is DropdownButtonFormField<FeedbackCategory>,
        ),
      ),
      findsNothing,
    );
    expect(dialogDescendant(find.byType(TextFormField)), findsNothing);

    await _enterValidRequiredFields(tester, l10n);
    await tester.tap(find.byKey(BusyMarkFeedbackKeys.submit));
    await tester.pumpAndSettle();

    expect(find.byKey(BusyMarkFeedbackKeys.status), findsOneWidget);
    expect(dialogDescendant(find.byType(BusyMarkStatusBox)), findsNothing);
  });

  testWidgets('shared report form remains directional in an Arabic UI', (
    tester,
  ) async {
    final service = _FakeFeedbackService();
    await _pumpDialog(
      tester,
      service,
      locale: const Locale('ar'),
      surfaceSize: const Size(760, 760),
    );

    final dialog = find.byType(BusyMarkFeedbackDialog);
    final dialogContext = tester.element(dialog);
    final localized = AppLocalizations.of(dialogContext);
    expect(Directionality.of(dialogContext), TextDirection.rtl);
    final email = find.descendant(
      of: find.byKey(BusyMarkFeedbackKeys.replyEmail),
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(email).textDirection, TextDirection.ltr);

    await tester.tap(find.byKey(BusyMarkFeedbackKeys.category));
    await tester.pumpAndSettle();

    expect(find.text(localized.feedbackCategoryProblem), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dark route keeps the modal and fields theme-owned', (
    tester,
  ) async {
    final service = _FakeFeedbackService();
    await _pumpDialogRoute(tester, service, brightness: Brightness.dark);

    final feedback = find.byType(BusyMarkFeedbackDialog);
    final feedbackContext = tester.element(feedback);
    final dialog = tester.widget<Dialog>(
      find.descendant(
        of: find.byType(BusyMarkModalEditorSurface),
        matching: find.byType(Dialog),
      ),
    );
    expect(
      dialog.backgroundColor,
      Theme.of(feedbackContext).scaffoldBackgroundColor,
    );
    expect(dialog.surfaceTintColor, dialog.backgroundColor);

    for (final key in const [
      BusyMarkFeedbackKeys.subject,
      BusyMarkFeedbackKeys.message,
      BusyMarkFeedbackKeys.replyEmail,
    ]) {
      final decoration = tester.widget<TextField>(find.byKey(key)).decoration!;
      expect(decoration.filled, isFalse);
      expect(decoration.fillColor, Colors.transparent);
      expect(decoration.border, InputBorder.none);
    }

    expect(find.byType(BusyMarkDialogShell), findsNothing);
    expect(find.byType(YaruDialogTitleBar), findsNothing);
  });

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

  testWidgets('category can return to the unselected placeholder', (
    tester,
  ) async {
    final service = _FakeFeedbackService();
    await _pumpDialog(tester, service);

    await tester.tap(find.byKey(BusyMarkFeedbackKeys.category));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.feedbackCategoryProblem).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(BusyMarkFeedbackKeys.category));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.feedbackChooseCategory).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(BusyMarkFeedbackKeys.submit));
    await tester.pump();

    expect(find.text(l10n.feedbackCategoryRequired), findsOneWidget);
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
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text(l10n.feedbackSubmit), findsNothing);
    final button = tester.widget<ElevatedButton>(
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
    expect(_fieldText(tester, BusyMarkFeedbackKeys.subject), isEmpty);
    expect(_fieldText(tester, BusyMarkFeedbackKeys.message), isEmpty);
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
    expect(_fieldText(tester, BusyMarkFeedbackKeys.subject), 'Example subject');
    expect(
      _fieldText(tester, BusyMarkFeedbackKeys.message),
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
    expect(_fieldText(tester, BusyMarkFeedbackKeys.subject), 'Example subject');
    expect(
      _fieldText(tester, BusyMarkFeedbackKeys.message),
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
          .widget<FilledButton>(find.byKey(BusyMarkFeedbackKeys.cancel))
          .onPressed,
      isNull,
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
          .widget<FilledButton>(find.byKey(BusyMarkFeedbackKeys.cancel))
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(BusyMarkFeedbackKeys.cancel));
    await tester.pumpAndSettle();
    expect(find.byType(BusyMarkFeedbackDialog), findsNothing);
  });
}

Future<void> _pumpDialog(
  WidgetTester tester,
  _FakeFeedbackService service, {
  Locale locale = const Locale('en'),
  Size surfaceSize = const Size(1000, 900),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = surfaceSize;
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
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildBusyMarkTheme(
          brightness: Brightness.light,
          accentColor: BusyMarkLinuxPalette.blueAccent,
        ),
        home: Scaffold(body: Center(child: const BusyMarkFeedbackDialog())),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpDialogRoute(
  WidgetTester tester,
  _FakeFeedbackService service, {
  Brightness brightness = Brightness.light,
}) async {
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
        theme: buildBusyMarkTheme(
          brightness: brightness,
          accentColor: BusyMarkLinuxPalette.blueAccent,
        ),
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

String _fieldText(WidgetTester tester, Key key) {
  final editableText = find.descendant(
    of: find.byKey(key),
    matching: find.byType(EditableText),
    matchRoot: true,
  );
  expect(editableText, findsOneWidget);
  return tester.widget<EditableText>(editableText).controller.text;
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
