import 'dart:async';

import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/ai/ai_edit_ui.dart';
import 'package:busymark/src/ai/ai_models.dart';
import 'package:busymark/src/ai/ai_provider.dart';
import 'package:busymark/src/ai/ai_provider_registry.dart';
import 'package:busymark/src/ai/ai_providers.dart';
import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('document-only AI snapshot opens a usable configuration', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildBusyMarkTheme(
            brightness: Brightness.dark,
            accentColor: BusyMarkLinuxPalette.blueAccent,
          ),
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, child) => ElevatedButton(
                onPressed: () => unawaited(
                  showBusyMarkAiEdit(
                    context,
                    ref,
                    const AiEditorSnapshot(
                      documentSource: '',
                      selectionStart: 0,
                      selectionEnd: 0,
                      anchorOffset: 0,
                      sourceRevision: 0,
                      targetId: 'empty.md',
                      documentPath: 'empty.md',
                      blockTargetAvailable: false,
                    ),
                  ),
                ),
                child: const Text('Open AI'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open AI'));
    await tester.pumpAndSettle();

    expect(find.text('Refine with AI'), findsOneWidget);
    expect(find.text('Complete document'), findsOneWidget);
    expect(find.text('No document context'), findsOneWidget);
    expect(find.text('Generate proposal'), findsOneWidget);
    expect(find.textContaining('cannot map'), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.text('Refine with AI'), findsNothing);
  });

  testWidgets('AI configuration uses native rows without duplicate choices', (
    tester,
  ) async {
    const source = '# Guide\n\nText to refine.\n';
    final selectionStart = source.indexOf('Text');
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildBusyMarkTheme(
            brightness: Brightness.dark,
            accentColor: BusyMarkLinuxPalette.blueAccent,
          ),
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, child) => ElevatedButton(
                onPressed: () => unawaited(
                  showBusyMarkAiEdit(
                    context,
                    ref,
                    AiEditorSnapshot(
                      documentSource: source,
                      selectionStart: selectionStart,
                      selectionEnd: selectionStart + 'Text to refine.'.length,
                      anchorOffset: selectionStart,
                      sourceRevision: 1,
                      targetId: 'guide.md',
                      documentPath: 'guide.md',
                    ),
                  ),
                ),
                child: const Text('Open AI'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open AI'));
    await tester.pumpAndSettle();

    expect(find.byType(BusyMarkModalEditorScaffold), findsOneWidget);
    final providerSelector = tester.widget<BusyMarkComboRow<AiProviderKind>>(
      find.byKey(const ValueKey('ai-edit-provider')),
    );
    expect(providerSelector.values, AiProviderKind.values);
    expect(providerSelector.selected, AiProviderKind.ollamaLocal);
    providerSelector.onSelected(AiProviderKind.gemini);
    await tester.pump();
    expect(
      tester
          .widget<BusyMarkComboRow<AiProviderKind>>(
            find.byKey(const ValueKey('ai-edit-provider')),
          )
          .selected,
      AiProviderKind.gemini,
    );
    expect(find.byType(BusyMarkComboRow<AiEditTargetKind>), findsOneWidget);
    expect(find.byType(BusyMarkComboRow<AiEditContextKind>), findsOneWidget);
    expect(find.byType(DropdownButtonFormField), findsNothing);
    expect(find.byType(ExpansionTile), findsNothing);
    expect(find.text('What may change'), findsOneWidget);
    expect(find.text('Context shared with AI'), findsOneWidget);
    expect(find.text('Review exact content'), findsNothing);
    expect(find.text('Content to change'), findsNothing);
    expect(find.text('Content sent to AI'), findsNothing);
    expect(find.text('Text to refine.'), findsNWidgets(2));
    final changeSelector = tester.getTopLeft(
      find.byKey(const ValueKey('ai-edit-target')),
    );
    final changeContent = tester.getTopLeft(
      find.byKey(const ValueKey('ai-content-to-change')),
    );
    final contextSelector = tester.getTopLeft(
      find.byKey(const ValueKey('ai-edit-context')),
    );
    final sharedContent = tester.getTopLeft(
      find.byKey(const ValueKey('ai-content-sent-to-ai')),
    );
    expect(changeSelector.dy, lessThan(changeContent.dy));
    expect(changeContent.dy, lessThan(contextSelector.dy));
    expect(contextSelector.dy, lessThan(sharedContent.dy));
  });

  testWidgets('AI proposal uses an explicitly selected provider', (
    tester,
  ) async {
    final settings = AppSettings.defaults().copyWith(
      aiProviderPreference: AiProviderPreference.ollamaLocal,
      aiOllamaModel: 'local-model',
      aiGeminiModel: 'gemini-model',
      aiModelRoutingPreference: AiModelRoutingPreference.fixed,
      aiCloudProviderConsentIds: [AiProviderKind.gemini.id],
    );
    final local = _ImmediateAiProvider(
      kind: AiProviderKind.ollamaLocal,
      model: 'local-model',
    );
    final gemini = _ImmediateAiProvider(
      kind: AiProviderKind.gemini,
      model: 'gemini-model',
    );
    final container = ProviderContainer(
      overrides: [
        localSettingsStoreProvider.overrideWithValue(
          _MemorySettingsStore(settings.toJson()),
        ),
        aiProviderRegistryProvider.overrideWithValue(
          AiProviderRegistry([local, gemini]),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(appSettingsControllerProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, child) => ElevatedButton(
                onPressed: () => unawaited(
                  showBusyMarkAiProposal(
                    context,
                    ref,
                    const AiEditInvocation(
                      feature: AiFeature.draftCommitMessage,
                      scope: AiScope.gitDiff,
                      input: 'diff --git a/guide.md b/guide.md',
                      replacementOriginal: '',
                      sourceRevision: 0,
                      targetId: 'git-commit:/repo',
                      documentPath: null,
                      contentFormat: AiContentFormat.plainText,
                      enforceDocumentRevision: false,
                    ),
                    providerKind: AiProviderKind.gemini,
                  ),
                ),
                child: const Text('Generate'),
              ),
            ),
          ),
        ),
      ),
    );
    await _pumpSettings(tester, container);

    await tester.tap(find.text('Generate'));
    await tester.pumpAndSettle();

    expect(local.requests, isEmpty);
    expect(gemini.requests, hasLength(1));
    expect(gemini.requests.single.provider, AiProviderKind.gemini);
    expect(find.textContaining('Google Gemini'), findsWidgets);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });

  testWidgets('provider chooser exposes every supported provider kind', (
    tester,
  ) async {
    final settings = AppSettings.defaults().copyWith(
      aiProviderPreference: AiProviderPreference.ollamaLocal,
    );
    final container = ProviderContainer(
      overrides: [
        localSettingsStoreProvider.overrideWithValue(
          _MemorySettingsStore(settings.toJson()),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(appSettingsControllerProvider);
    AiProviderKind? selected;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, child) => ElevatedButton(
                onPressed: () async {
                  selected = await chooseBusyMarkAiProvider(context, ref);
                },
                child: const Text('Choose provider'),
              ),
            ),
          ),
        ),
      ),
    );
    await _pumpSettings(tester, container);

    await tester.tap(find.text('Choose provider'));
    await tester.pumpAndSettle();
    final selector = tester.widget<BusyMarkComboRow<AiProviderKind>>(
      find.byKey(const ValueKey('ai-provider-choice')),
    );
    expect(selector.values, AiProviderKind.values);
    expect(selector.selected, AiProviderKind.ollamaLocal);
    selector.onSelected(AiProviderKind.openAi);
    await tester.pump();
    await tester.tap(find.text('Generate proposal'));
    await tester.pumpAndSettle();

    expect(selected, AiProviderKind.openAi);
  });

  testWidgets('fixed AI target cannot widen a sidebar selection', (
    tester,
  ) async {
    const source = '# First\n\nSelected section.\n\n# Last\n';
    final start = source.indexOf('# First');
    final end = source.indexOf('# Last');
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, child) => ElevatedButton(
                onPressed: () => unawaited(
                  showBusyMarkAiEdit(
                    context,
                    ref,
                    AiEditorSnapshot(
                      documentSource: source,
                      selectionStart: start,
                      selectionEnd: end,
                      anchorOffset: start,
                      sourceRevision: 1,
                      targetId: 'outline.md',
                      documentPath: 'outline.md',
                      blockTargetAvailable: false,
                    ),
                    fixedTarget: AiEditTargetKind.selection,
                  ),
                ),
                child: const Text('Open fixed AI'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open fixed AI'));
    await tester.pumpAndSettle();

    final selector = tester.widget<BusyMarkComboRow<AiEditTargetKind>>(
      find.byType(BusyMarkComboRow<AiEditTargetKind>),
    );
    expect(selector.values, [AiEditTargetKind.selection]);
    expect(selector.selected, AiEditTargetKind.selection);
    expect(find.textContaining('Selected section.'), findsNWidgets(2));
  });

  testWidgets('proposal Apply refuses stale external source content', (
    tester,
  ) async {
    final settings = AppSettings.defaults().copyWith(
      aiProviderPreference: AiProviderPreference.ollamaLocal,
      aiOllamaModel: 'test-model',
      aiModelRoutingPreference: AiModelRoutingPreference.fixed,
    );
    final store = _MemorySettingsStore(settings.toJson());
    final provider = _ImmediateAiProvider();
    final container = ProviderContainer(
      overrides: [
        localSettingsStoreProvider.overrideWithValue(store),
        aiProviderRegistryProvider.overrideWithValue(
          AiProviderRegistry([provider]),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(appSettingsControllerProvider);

    var freshnessChecks = 0;
    String? accepted;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildBusyMarkTheme(
            brightness: Brightness.dark,
            accentColor: BusyMarkLinuxPalette.blueAccent,
          ),
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, child) => ElevatedButton(
                onPressed: () async {
                  accepted = await showBusyMarkAiProposal(
                    context,
                    ref,
                    const AiEditInvocation(
                      feature: AiFeature.draftCommitMessage,
                      scope: AiScope.gitDiff,
                      input: 'diff --git a/guide.md b/guide.md',
                      replacementOriginal: '',
                      sourceRevision: 0,
                      targetId: 'git-commit:/repo',
                      documentPath: null,
                      contentFormat: AiContentFormat.plainText,
                      enforceDocumentRevision: false,
                    ),
                    validateBeforeApply: () async {
                      freshnessChecks += 1;
                      return false;
                    },
                    staleMessage:
                        'The staged changes changed while this commit message was generated. Run the action again.',
                  );
                },
                child: const Text('Generate'),
              ),
            ),
          ),
        ),
      ),
    );
    for (var index = 0; index < 20; index += 1) {
      await tester.pump();
      if (container.read(appSettingsControllerProvider).aiOllamaModel ==
          'test-model') {
        break;
      }
    }

    await tester.tap(find.text('Generate'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Improve documentation'), findsWidgets);

    await tester.tap(find.text('Apply proposal'));
    await tester.pumpAndSettle();

    expect(freshnessChecks, 1);
    expect(accepted, isNull);
    expect(
      find.text(
        'The staged changes changed while this commit message was generated. Run the action again.',
      ),
      findsOneWidget,
    );
    expect(find.text('Apply proposal'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(accepted, isNull);
  });
}

Future<void> _pumpSettings(
  WidgetTester tester,
  ProviderContainer container,
) async {
  for (var index = 0; index < 20; index += 1) {
    await tester.pump();
    if (container.read(appSettingsControllerProvider).aiProviderPreference !=
        AiProviderPreference.disabled) {
      return;
    }
  }
  fail('App settings did not finish loading.');
}

class _ImmediateAiProvider implements AiProvider {
  _ImmediateAiProvider({
    this.kind = AiProviderKind.ollamaLocal,
    this.model = 'test-model',
  });

  final AiProviderKind kind;
  final String model;
  final List<AiRequest> requests = [];

  @override
  String get id => kind.id;

  @override
  AiProviderCapabilities get capabilities => AiProviderCapabilities(
    kind: kind,
    streaming: true,
    modelDiscovery: false,
    maximumConcurrentRequests: 1,
    recommendedModels: {},
  );

  @override
  Stream<AiStreamEvent> stream(
    AiRequest request, {
    required AiCancellationToken cancellationToken,
  }) async* {
    requests.add(request);
    yield AiStarted(providerId: kind.id, model: model);
    yield const AiTextDelta('Improve documentation');
    yield const AiCompleted();
  }

  @override
  Future<List<AiModelInfo>> listModels({
    AiCancellationToken? cancellationToken,
  }) async => const [AiModelInfo(name: 'test-model')];

  @override
  Future<AiHealthResult> checkHealth({
    required String model,
    required AiCancellationToken cancellationToken,
  }) => throw UnimplementedError();
}

class _MemorySettingsStore implements LocalSettingsStore {
  _MemorySettingsStore(this.value);

  Map<String, Object?> value;

  @override
  Future<Map<String, Object?>> load() async => value;

  @override
  Future<void> save(Map<String, Object?> json) async {
    value = json;
  }
}
