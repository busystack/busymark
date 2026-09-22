enum SpellingLanguageOverrideKind { inherit, disabled, selected }

/// A nullable language cannot distinguish inheritance from an explicit
/// document-level opt-out, so the document state stores both parts.
final class SpellingLanguageOverride {
  const SpellingLanguageOverride.inherit()
    : kind = SpellingLanguageOverrideKind.inherit,
      languageId = null;

  const SpellingLanguageOverride.disabled()
    : kind = SpellingLanguageOverrideKind.disabled,
      languageId = null;

  const SpellingLanguageOverride.selected(String this.languageId)
    : kind = SpellingLanguageOverrideKind.selected;

  final SpellingLanguageOverrideKind kind;
  final String? languageId;

  bool get checksSpelling => kind != SpellingLanguageOverrideKind.disabled;

  Map<String, Object?> toJson() => <String, Object?>{
    'kind': kind.name,
    if (languageId != null) 'languageId': languageId,
  };

  factory SpellingLanguageOverride.fromJson(Object? value) {
    if (value is! Map) return const SpellingLanguageOverride.inherit();
    final json = value.cast<Object?, Object?>();
    final kind = SpellingLanguageOverrideKind.values.firstWhere(
      (candidate) => candidate.name == json['kind'],
      orElse: () => SpellingLanguageOverrideKind.inherit,
    );
    final language = json['languageId']?.toString().trim();
    return switch (kind) {
      SpellingLanguageOverrideKind.disabled =>
        const SpellingLanguageOverride.disabled(),
      SpellingLanguageOverrideKind.selected
          when language != null && language.isNotEmpty =>
        SpellingLanguageOverride.selected(language),
      _ => const SpellingLanguageOverride.inherit(),
    };
  }

  @override
  bool operator ==(Object other) =>
      other is SpellingLanguageOverride &&
      other.kind == kind &&
      other.languageId == languageId;

  @override
  int get hashCode => Object.hash(kind, languageId);
}

String? normalizeSpellingLanguageId(Object? value) {
  final trimmed = value?.toString().trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
