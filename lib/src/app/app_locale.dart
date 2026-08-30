import 'package:flutter/widgets.dart';

/// A locale that can be selected explicitly in BusyMark.
///
/// Labels are endonyms so the language selector remains usable even when the
/// current application language is unfamiliar to the user.
class BusyMarkLocaleOption {
  const BusyMarkLocaleOption({required this.locale, required this.endonym});

  final Locale locale;
  final String endonym;

  String get tag => locale.toLanguageTag();
}

const busyMarkLocaleOptions = <BusyMarkLocaleOption>[
  BusyMarkLocaleOption(locale: Locale('ar'), endonym: 'العربية'),
  BusyMarkLocaleOption(locale: Locale('de'), endonym: 'Deutsch'),
  BusyMarkLocaleOption(locale: Locale('en'), endonym: 'English'),
  BusyMarkLocaleOption(locale: Locale('es'), endonym: 'Español'),
  BusyMarkLocaleOption(locale: Locale('et'), endonym: 'Eesti'),
  BusyMarkLocaleOption(locale: Locale('fa'), endonym: 'فارسی'),
  BusyMarkLocaleOption(locale: Locale('fr'), endonym: 'Français'),
  BusyMarkLocaleOption(locale: Locale('hi'), endonym: 'हिन्दी'),
  BusyMarkLocaleOption(locale: Locale('id'), endonym: 'Bahasa Indonesia'),
  BusyMarkLocaleOption(locale: Locale('it'), endonym: 'Italiano'),
  BusyMarkLocaleOption(locale: Locale('ja'), endonym: '日本語'),
  BusyMarkLocaleOption(locale: Locale('ko'), endonym: '한국어'),
  BusyMarkLocaleOption(locale: Locale('nb'), endonym: 'Norsk bokmål'),
  BusyMarkLocaleOption(locale: Locale('nl'), endonym: 'Nederlands'),
  BusyMarkLocaleOption(locale: Locale('pl'), endonym: 'Polski'),
  BusyMarkLocaleOption(
    locale: Locale.fromSubtags(languageCode: 'pt', countryCode: 'BR'),
    endonym: 'Português',
  ),
  BusyMarkLocaleOption(locale: Locale('ru'), endonym: 'Русский'),
  BusyMarkLocaleOption(locale: Locale('tr'), endonym: 'Türkçe'),
  BusyMarkLocaleOption(locale: Locale('uk'), endonym: 'Українська'),
  BusyMarkLocaleOption(locale: Locale('vi'), endonym: 'Tiếng Việt'),
  BusyMarkLocaleOption(
    locale: Locale.fromSubtags(languageCode: 'zh', countryCode: 'CN'),
    endonym: '简体中文',
  ),
];

Locale? busyMarkLocaleFromTag(String? tag) {
  final normalized = normalizeBusyMarkLocaleTag(tag);
  if (normalized == null) {
    return null;
  }
  return busyMarkLocaleOptions
      .firstWhere((option) => option.tag == normalized)
      .locale;
}

String? normalizeBusyMarkLocaleTag(String? tag) {
  final trimmed = tag?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  final migrated = trimmed.toLowerCase() == 'no'
      ? 'nb'
      : trimmed.toLowerCase().startsWith('no-') ||
            trimmed.toLowerCase().startsWith('no_')
      ? 'nb${trimmed.substring(2)}'
      : trimmed;
  final parsed = _parseLocaleTag(migrated);
  if (parsed == null) {
    return null;
  }

  if (parsed.languageCode == 'zh') {
    final isTraditional = parsed.scriptCode == 'Hant' ||
        parsed.countryCode == 'TW' ||
        parsed.countryCode == 'HK' ||
        parsed.countryCode == 'MO';
    if (isTraditional ||
        (parsed.countryCode != null && parsed.countryCode != 'CN')) {
      return null;
    }
    return const Locale.fromSubtags(languageCode: 'zh', countryCode: 'CN')
        .toLanguageTag();
  }

  for (final option in busyMarkLocaleOptions) {
    if (option.locale == parsed || option.locale.languageCode == parsed.languageCode) {
      return option.tag;
    }
  }
  return null;
}

/// Resolves all platform language preferences with English as the deliberate
/// fallback. Generated locale lists are alphabetical, so relying on their
/// first item would otherwise make Arabic the fallback for an unknown locale.
Locale resolveBusyMarkLocales(
  List<Locale>? requestedLocales,
  Iterable<Locale> supportedLocales,
) {
  final supported = supportedLocales.toList(growable: false);
  if (supported.isEmpty) {
    return const Locale('en');
  }
  final english = supported.cast<Locale?>().firstWhere(
    (locale) => locale?.languageCode == 'en',
    orElse: () => null,
  );
  final orderedSupported = <Locale>[
    if (english != null) english,
    for (final locale in supported)
      if (locale != english) locale,
  ];
  return basicLocaleListResolution(requestedLocales, orderedSupported);
}

Locale? _parseLocaleTag(String tag) {
  final parts = tag.replaceAll('_', '-').split('-');
  if (parts.isEmpty || !RegExp(r'^[A-Za-z]{2,3}$').hasMatch(parts.first)) {
    return null;
  }
  final languageCode = parts.first.toLowerCase();
  String? scriptCode;
  String? countryCode;
  for (final part in parts.skip(1)) {
    if (scriptCode == null && RegExp(r'^[A-Za-z]{4}$').hasMatch(part)) {
      scriptCode =
          '${part.substring(0, 1).toUpperCase()}'
          '${part.substring(1).toLowerCase()}';
      continue;
    }
    if (countryCode == null &&
        RegExp(r'^(?:[A-Za-z]{2}|[0-9]{3})$').hasMatch(part)) {
      countryCode = part.toUpperCase();
      continue;
    }
    return null;
  }
  return Locale.fromSubtags(
    languageCode: languageCode,
    scriptCode: scriptCode,
    countryCode: countryCode,
  );
}
