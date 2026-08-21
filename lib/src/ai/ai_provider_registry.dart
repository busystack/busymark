import 'ai_models.dart';
import 'ai_provider.dart';

class AiProviderRegistry {
  AiProviderRegistry(Iterable<AiProvider> providers)
    : _providers = {
        for (final provider in providers) provider.capabilities.kind: provider,
      };

  final Map<AiProviderKind, AiProvider> _providers;

  AiProvider require(AiProviderKind kind) {
    final provider = _providers[kind];
    if (provider == null) {
      throw AiException(
        AiFailureCode.invalidConfiguration,
        '${kind.displayName} is not available in this installation.',
      );
    }
    return provider;
  }

  List<AiProvider> get providers => List.unmodifiable(_providers.values);
}
