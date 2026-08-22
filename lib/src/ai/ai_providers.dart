import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../app/app_settings.dart';
import 'ai_configuration.dart';
import 'ai_coordinator.dart';
import 'ai_models.dart';
import 'ai_provider.dart';
import 'ai_provider_registry.dart';
import 'ai_secret_store.dart';
import 'ai_usage_store.dart';
import 'gemini_ai_provider.dart';
import 'ollama_ai_provider.dart';
import 'openai_ai_provider.dart';

final aiHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final aiSecretStoreProvider = Provider<AiSecretStore>(
  (ref) => const FlutterAiSecretStore(),
);

final aiUsageStoreProvider = Provider<AiUsageStore>((ref) => AiUsageStore());

final aiMonthlyUsageProvider = FutureProvider<AiMonthlyUsage>(
  (ref) => ref.watch(aiUsageStoreProvider).read(),
);

final aiProviderRegistryProvider = Provider<AiProviderRegistry>((ref) {
  final client = ref.watch(aiHttpClientProvider);
  final secretStore = ref.watch(aiSecretStoreProvider);
  final endpoint = ref.watch(
    appSettingsControllerProvider.select((value) => value.aiOllamaEndpoint),
  );
  return AiProviderRegistry([
    OllamaAiProvider(client: client, endpoint: endpoint),
    OpenAiProvider(client: client, secretStore: secretStore),
    GeminiAiProvider(client: client, secretStore: secretStore),
  ]);
});

final defaultAiProviderProvider = Provider<AiProvider>((ref) {
  final kind = ref.watch(
    appSettingsControllerProvider.select(
      (value) => value.defaultAiProviderKind,
    ),
  );
  if (kind == null) {
    throw const AiException(
      AiFailureCode.invalidConfiguration,
      'Enable an AI provider in Settings first.',
    );
  }
  return ref.watch(aiProviderRegistryProvider).require(kind);
});

final aiCoordinatorProvider = Provider<AiCoordinator>((ref) {
  final coordinator = AiCoordinator(
    registry: ref.watch(aiProviderRegistryProvider),
    onUsage: (usage) async {
      await ref.read(aiUsageStoreProvider).record(usage);
      ref.invalidate(aiMonthlyUsageProvider);
    },
  );
  ref.onDispose(coordinator.dispose);
  return coordinator;
});
