import 'dart:async';

import 'ai_models.dart';

abstract interface class AiProvider {
  String get id;
  AiProviderCapabilities get capabilities;

  Stream<AiStreamEvent> stream(
    AiRequest request, {
    required AiCancellationToken cancellationToken,
  });

  Future<List<AiModelInfo>> listModels({
    AiCancellationToken? cancellationToken,
  });

  Future<AiHealthResult> checkHealth({
    required String model,
    required AiCancellationToken cancellationToken,
  });
}
