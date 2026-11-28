import 'dart:async';
import 'dart:typed_data';

import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/busymark_dialogs.dart';
import 'package:busymark/src/app/localization.dart';
import 'package:busymark/src/editor/document_audio_view.dart';
import 'package:busymark/src/speech/narration.dart';
import 'package:busymark/src/speech/speech.dart';
import 'package:busymark/src/speech/speech_dialog.dart';
import 'package:busymark/src/speech/speech_pcm.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('document scope, consent and result use the shared modal', (
    tester,
  ) async {
    final service = _ControlledSpeechService();
    final result = _result();
    final publication = Completer<bool>();
    final plans = <NarrationScope>[];
    final inserted = <({NarrationPlan plan, Uint8List bytes})>[];
    await _mount(
      tester,
      service: service,
      options: const SpeechOptions(backend: SpeechBackend.openai),
      planForScope: (scope) {
        plans.add(scope);
        return _plan(scope);
      },
      insert: (plan, bytes) {
        inserted.add((plan: plan, bytes: bytes));
        return publication.future;
      },
    );
    final l10n = _l10n(tester);
    final scope = find.byType(BusyMarkComboRow<NarrationScope>);
    expect(find.byType(BusyMarkDialogShell), findsOneWidget);
    expect(find.byType(BusyMarkDialogTitleBar), findsOneWidget);
    expect(find.byType(BusyMarkModalShortcutBoundary), findsOneWidget);
    expect(
      find.widgetWithText(BusyMarkStatusBox, l10n.speechCloudConsent),
      findsOneWidget,
    );
    expect(find.text('OpenAI'), findsOneWidget);
    expect(find.text(l10n.speechProviderPricing), findsOneWidget);
    expect(
      find.text(l10n.speechInputCharacters('Whole draft.'.runes.length)),
      findsOneWidget,
    );
    expect(find.widgetWithText(SelectableText, 'Whole draft.'), findsOneWidget);
    expect(service.requests, 0);

    await tester.tap(scope);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.speechSection).last);
    await tester.pumpAndSettle();
    expect(plans, [NarrationScope.document, NarrationScope.section]);
    expect(
      find.widgetWithText(SelectableText, 'Section only.'),
      findsOneWidget,
    );
    expect(service.requests, 0);

    final delayedSelection = tester
        .widget<BusyMarkComboRow<NarrationScope>>(scope)
        .onSelected;
    await tester.tap(_action(l10n.generateAudio));
    await tester.pump();
    expect(service.segments.single.text, 'Section only.');
    expect(
      tester.widget<BusyMarkComboRow<NarrationScope>>(scope).enabled,
      isFalse,
    );
    delayedSelection(NarrationScope.document);
    expect(plans, [NarrationScope.document, NarrationScope.section]);
    service.onProgress?.call(1, 2);
    await tester.pump();
    final progress = tester.widget<BusyMarkProgressIndicator>(
      find.byType(BusyMarkProgressIndicator),
    );
    expect(progress.value, 0.5);
    expect(progress.semanticsLabel, l10n.speechProgress);

    service.completion.complete(result);
    await tester.pumpAndSettle();
    expect(find.byType(BusyMarkAudioTransport), findsOneWidget);
    expect(find.textContaining(l10n.speechInputTokens(4)), findsOneWidget);
    expect(find.textContaining(l10n.speechOutputTokens(8)), findsOneWidget);
    expect(_action(l10n.speechSaveAudio), findsOneWidget);
    await tester.tap(_action(l10n.insertAudio));
    await tester.pump();
    expect(
      tester.widget<BusyMarkDialogButton>(_action(l10n.close)).onPressed,
      isNull,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.byType(SpeechNarrationDialog), findsOneWidget);
    expect(inserted.single.plan.scope, NarrationScope.section);
    expect(inserted.single.bytes, result.wavBytes);
    publication.complete(false);
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(BusyMarkStatusBox, l10n.audioStaleTarget),
      findsOneWidget,
    );
    expect(service.requests, 1);
    await tester.tap(_action(l10n.close));
    await tester.pumpAndSettle();
  });

  testWidgets('Escape waits for cancellation and restores the opening focus', (
    tester,
  ) async {
    final service = _ControlledSpeechService();
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await _mount(tester, service: service, focus: focus);
    final l10n = _l10n(tester);
    final generate = tester.widget<BusyMarkDialogButton>(
      _action(l10n.generateAudio),
    );
    generate.onPressed!();
    generate.onPressed!();
    await tester.pump();
    expect(service.requests, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(service.cancellation?.isCancelled, isTrue);
    expect(find.byType(SpeechNarrationDialog), findsOneWidget);

    service.completion.complete(_result());
    await tester.pumpAndSettle();
    expect(find.byType(SpeechNarrationDialog), findsNothing);
    expect(find.byType(BusyMarkAudioTransport), findsNothing);
    expect(FocusManager.instance.primaryFocus, same(focus));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the sample stays usable in a narrow scaled RTL modal', (
    tester,
  ) async {
    final service = _ControlledSpeechService();
    await tester.binding.setSurfaceSize(const Size(360, 540));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _mount(
      tester,
      service: service,
      sample: true,
      locale: const Locale('ar'),
      textScaler: TextScaler.linear(1.6),
    );
    final l10n = _l10n(tester);
    expect(
      Directionality.of(tester.element(find.byType(BusyMarkDialogShell))),
      TextDirection.rtl,
    );
    expect(find.byType(BusyMarkComboRow<NarrationScope>), findsNothing);
    expect(service.requests, 0);
    await tester.tap(_action(l10n.speechSample));
    await tester.pump();
    expect(service.requests, 1);
    service.completion.complete(_result());
    await tester.pumpAndSettle();
    expect(find.byType(BusyMarkAudioTransport), findsOneWidget);
    expect(_action(l10n.speechSaveAudio), findsNothing);
    expect(_action(l10n.insertAudio), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(SpeechNarrationDialog), findsNothing);
  });

  testWidgets('system Read Aloud keeps its own pause, resume and stop', (
    tester,
  ) async {
    final service = _ControlledSystemSpeechService();
    await _mount(
      tester,
      service: service,
      readAloud: true,
      options: const SpeechOptions(backend: SpeechBackend.system),
    );
    final l10n = _l10n(tester);
    expect(
      find.widgetWithText(BusyMarkStatusBox, l10n.speechUnknownLocality),
      findsOneWidget,
    );
    expect(service.cancellation, isNull);
    await tester.tap(_action(l10n.readAloud));
    await tester.pump();
    expect(service.allowedUnverifiedModule, isTrue);
    await tester.tap(_action(l10n.audioPause));
    await tester.pump();
    await tester.tap(_action(l10n.audioPlay));
    await tester.pump();
    expect(service.controls, ['pause', 'resume']);
    await tester.tap(_action(l10n.speechStop));
    await tester.pump();
    expect(service.cancellation?.isCancelled, isTrue);
    service.completion.complete();
    await tester.pumpAndSettle();
    expect(_action(l10n.readAloud), findsOneWidget);
    expect(_action(l10n.speechSaveAudio), findsNothing);
    expect(find.byType(BusyMarkAudioTransport), findsNothing);
    await tester.tap(_action(l10n.close));
    await tester.pumpAndSettle();
  });
}

Finder _action(String label) => find.byWidgetPredicate(
  (widget) => widget is BusyMarkDialogButton && widget.label == label,
);

AppLocalizations _l10n(WidgetTester tester) =>
    tester.element(find.byType(SpeechNarrationDialog)).l10n;

Future<void> _mount(
  WidgetTester tester, {
  required SpeechService service,
  SpeechOptions options = const SpeechOptions(backend: SpeechBackend.espeak),
  NarrationPlan Function(NarrationScope) planForScope = _plan,
  Future<bool> Function(NarrationPlan, Uint8List)? insert,
  FocusNode? focus,
  bool sample = false,
  bool readAloud = false,
  Locale locale = const Locale('en'),
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: busyMarkLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => BusyMarkPushButton.standard(
            focusNode: focus,
            onPressed: () => unawaited(
              showSpeechNarrationDialog(
                context,
                options: options,
                planForScope: planForScope,
                initialScope: NarrationScope.document,
                scopes: const [NarrationScope.document, NarrationScope.section],
                suggestedFilename: 'fixture.wav',
                sample: sample,
                readAloud: readAloud,
                insert: insert,
                service: service,
              ),
            ),
            child: const Text('Open fixture'),
          ),
        ),
      ),
    ),
  );
  focus?.requestFocus();
  await tester.pump();
  await tester.tap(find.text('Open fixture'));
  await tester.pumpAndSettle();
}

NarrationPlan _plan(NarrationScope scope) => NarrationPlan(
  documentId: 'fixture-document',
  providerId: 'fixture-provider',
  revision: 1,
  scope: scope,
  insertionOffset: 0,
  passages: [
    (
      speech: SpeechSegment(
        scope == NarrationScope.section ? 'Section only.' : 'Whole draft.',
      ),
      source: null,
    ),
  ],
  omissions: const [NarrationOmission.media],
);

SpeechResult _result() => SpeechResult(
  wavBytes: encodeSpeechWave(SpeechPcm(Uint8List(1600), sampleRate: 8000)),
  duration: const Duration(milliseconds: 100),
  usage: const [SpeechUsage(inputTokens: 4, outputTokens: 8)],
  segmentOffsets: const [Duration.zero],
);

class _ControlledSpeechService extends SpeechService {
  final completion = Completer<SpeechResult>();
  List<SpeechSegment> segments = const [];
  AiCancellationToken? cancellation;
  void Function(int, int)? onProgress;
  int requests = 0;

  @override
  Future<SpeechResult> generate(
    List<SpeechSegment> segments,
    SpeechOptions options, {
    required AiCancellationToken cancellationToken,
    void Function(int completed, int total)? onProgress,
    bool resumeCompletedChunks = false,
  }) {
    requests++;
    this.segments = segments;
    cancellation = cancellationToken;
    this.onProgress = onProgress;
    return completion.future;
  }
}

class _ControlledSystemSpeechService extends SpeechService {
  final completion = Completer<void>();
  final controls = <String>[];
  AiCancellationToken? cancellation;
  bool? allowedUnverifiedModule;

  @override
  Future<void> readSystem(
    List<SpeechSegment> segments,
    SpeechOptions options, {
    required AiCancellationToken cancellationToken,
    bool allowUnverifiedModule = false,
    void Function(int completed, int total)? onProgress,
  }) {
    cancellation = cancellationToken;
    allowedUnverifiedModule = allowUnverifiedModule;
    onProgress?.call(0, segments.length);
    return completion.future;
  }

  @override
  Future<void> pauseSystem() async => controls.add('pause');

  @override
  Future<void> resumeSystem() async => controls.add('resume');
}
