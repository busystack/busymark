import 'narration.dart';
import 'speech_provider.dart';

class SpeechPreferences {
  const SpeechPreferences({
    this.backend = SpeechBackend.espeak,
    this.providers = const {},
    this.narration = const NarrationRules(),
    this.audioDirectory = '',
    this.outputName = '',
  });

  factory SpeechPreferences.fromJson(Object? stored) {
    if (stored is! Map) return const SpeechPreferences();
    String string(String key) =>
        stored[key] is String ? stored[key] as String : '';
    final backend =
        SpeechBackend.values
            .where((value) => value.name == stored['backend'])
            .firstOrNull ??
        SpeechBackend.espeak;
    final saved = stored['providers'];
    return SpeechPreferences(
      backend: backend,
      providers: Map.unmodifiable({
        if (saved is Map)
          for (final kind in SpeechBackend.values)
            if (saved[kind.name] case final Map config)
              kind: _optionsFromJson(kind, config),
      }),
      narration: stored['narration'] is Map
          ? NarrationRules.fromJson(stored['narration'] as Map)
          : const NarrationRules(),
      audioDirectory: string('audioDirectory'),
      outputName: string('outputName'),
    );
  }

  final SpeechBackend backend;
  final Map<SpeechBackend, SpeechOptions> providers;
  final NarrationRules narration;
  final String audioDirectory;
  final String outputName;

  SpeechOptions get options =>
      providers[backend] ?? SpeechOptions(backend: backend);

  SpeechPreferences copyWith({
    SpeechBackend? backend,
    SpeechOptions? options,
    NarrationRules? narration,
    String? audioDirectory,
    String? outputName,
  }) => SpeechPreferences(
    backend: backend ?? this.backend,
    providers: options == null
        ? providers
        : Map.unmodifiable({...providers, options.backend: options}),
    narration: narration ?? this.narration,
    audioDirectory: audioDirectory ?? this.audioDirectory,
    outputName: outputName ?? this.outputName,
  );

  Map<String, Object> toJson() => {
    'backend': backend.name,
    'providers': {
      for (final (kind, settings) in providers.entries.map(
        (e) => (e.key, e.value),
      ))
        kind.name: {
          'model': settings.model,
          'voice': settings.voice,
          'language': settings.language,
          'speed': settings.speed,
          'pitch': settings.pitch,
          'style': settings.style,
        },
    },
    'narration': narration.toJson(),
    'audioDirectory': audioDirectory,
    'outputName': outputName,
  };

  static SpeechOptions _optionsFromJson(SpeechBackend kind, Map saved) {
    String string(String key) =>
        saved[key] is String ? saved[key] as String : '';
    final speed = saved['speed'];
    final pitch = saved['pitch'];
    return SpeechOptions(
      backend: kind,
      model: string('model'),
      voice: string('voice'),
      language: string('language'),
      speed: speed is num && speed.isFinite ? speed.toDouble() : 1,
      pitch: pitch is int ? pitch.clamp(0, 99) : 50,
      style: string('style'),
    );
  }
}
