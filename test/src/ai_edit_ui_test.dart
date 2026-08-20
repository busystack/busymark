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
import 'package:flutter_test/flutter_test.dart';

void main() {
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

class _ImmediateAiProvider implements AiProvider {
  @override
  String get id => AiProviderKind.ollamaLocal.id;

  @override
  AiProviderCapabilities get capabilities => const AiProviderCapabilities(
    kind: AiProviderKind.ollamaLocal,
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
    yield const AiStarted(providerId: 'ollama-local', model: 'test-model');
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
