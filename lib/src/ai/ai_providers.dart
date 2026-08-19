import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../app/app_settings.dart';
import 'ai_coordinator.dart';
import 'ai_provider.dart';
import 'ollama_ai_provider.dart';

final aiHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final aiProviderProvider = Provider<AiProvider>((ref) {
  final endpoint = ref.watch(
    appSettingsControllerProvider.select((value) => value.aiOllamaEndpoint),
  );
  return OllamaAiProvider(
    client: ref.watch(aiHttpClientProvider),
    endpoint: endpoint,
  );
});

final aiCoordinatorProvider = Provider<AiCoordinator>((ref) {
  final coordinator = AiCoordinator(provider: ref.watch(aiProviderProvider));
  ref.onDispose(coordinator.dispose);
  return coordinator;
});
