import 'dart:async';

import 'ai_models.dart';

abstract interface class AiProvider {
  String get id;

  Stream<AiStreamEvent> stream(
    AiRequest request, {
    required AiCancellationToken cancellationToken,
  });

  Future<List<AiModelInfo>> listModels();
}
