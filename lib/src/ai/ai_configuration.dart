import '../app/app_settings.dart';
import 'ai_models.dart';
import 'ai_provider.dart';

extension AiSettingsConfiguration on AppSettings {
  AiProviderKind? get aiProviderKind => switch (aiProviderPreference) {
    AiProviderPreference.disabled => null,
    AiProviderPreference.ollamaLocal => AiProviderKind.ollamaLocal,
    AiProviderPreference.openAi => AiProviderKind.openAi,
    AiProviderPreference.gemini => AiProviderKind.gemini,
  };

  String selectedAiModel(AiProviderKind provider) => switch (provider) {
    AiProviderKind.ollamaLocal => aiOllamaModel,
    AiProviderKind.openAi => aiOpenAiModel,
    AiProviderKind.gemini => aiGeminiModel,
  };

  bool hasCloudConsent(AiProviderKind provider) =>
      !provider.isCloud || aiCloudProviderConsentIds.contains(provider.id);

  List<String> modelCandidatesFor(AiFeature feature, AiProvider provider) {
    final selected = selectedAiModel(provider.capabilities.kind).trim();
    if (aiModelRoutingPreference == AiModelRoutingPreference.fixed ||
        provider.capabilities.recommendedModels.isEmpty) {
      return [if (selected.isNotEmpty) selected];
    }
    final recommended = provider.capabilities.modelsFor(
      feature.spec.modelClass,
    );
    return <String>{
      ...recommended,
      if (selected.isNotEmpty) selected,
    }.toList(growable: false);
  }
}
