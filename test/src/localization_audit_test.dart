import 'dart:convert';
import 'dart:io';

import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/l10n/generated/app_localizations_ar.dart';
import 'package:busymark/l10n/generated/app_localizations_en.dart';
import 'package:busymark/l10n/generated/app_localizations_fa.dart';
import 'package:busymark/src/core/diagnostic.dart';
import 'package:busymark/src/core/diagnostic_localizations.dart';
import 'package:busymark/src/app/app_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production Dart does not hardcode obvious user-facing strings', () {
    const patterns = <_LiteralPattern>[
      _LiteralPattern('Text literal', r"\bText\(\s*'([^']*[A-Z][^']*)'"),
      _LiteralPattern(
        'SelectableText literal',
        r"\bSelectableText\(\s*'([^']*[A-Z][^']*)'",
      ),
      _LiteralPattern('tooltip literal', r"\btooltip:\s*'([^']+)'"),
      _LiteralPattern('title literal', r"\btitle:\s*'([^']+)'"),
      _LiteralPattern('subtitle literal', r"\bsubtitle:\s*'([^']+)'"),
      _LiteralPattern('label literal', r"\blabel:\s*'([^']+)'"),
      _LiteralPattern('message literal', r"\bmessage:\s*'([^']+)'"),
      _LiteralPattern(
        'confirmButtonText literal',
        r"\bconfirmButtonText:\s*'([^']+)'",
      ),
      _LiteralPattern('hintText literal', r"\bhintText:\s*'([^']+)'"),
      _LiteralPattern('helperText literal', r"\bhelperText:\s*'([^']+)'"),
      _LiteralPattern('labelText literal', r"\blabelText:\s*'([^']+)'"),
      _LiteralPattern('semanticLabel literal', r"\bsemanticLabel:\s*'([^']+)'"),
      _LiteralPattern(
        'SnackBar Text literal',
        r"\bSnackBar\([^)]*content:\s*Text\(\s*'([^']*[A-Z][^']*)'",
        dotAll: true,
      ),
      _LiteralPattern(
        'Semantics label literal',
        r"\bSemantics\([^)]*label:\s*'([^']+)'",
        dotAll: true,
      ),
    ];

    final failures = <String>[];
    for (final file in _productionDartFiles()) {
      final source = file.readAsStringSync();
      for (final pattern in patterns) {
        for (final match in pattern.regExp.allMatches(source)) {
          final literal = match.group(1)!;
          if (_allowedLiteral(literal)) {
            continue;
          }
          failures.add(
            '${file.path}:${_lineForOffset(source, match.start)} '
            '${pattern.name}: $literal',
          );
        }
      }
    }

    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('native Linux GTK user-facing strings are not hardcoded', () {
    final failures = <String>[];
    for (final file in _nativeLinuxSourceFiles()) {
      final source = file.readAsStringSync();
      for (final pattern in _nativeGtkUserFacingPatterns) {
        for (final match in pattern.regExp.allMatches(source)) {
          final literal = match.group(1)!;
          if (_allowedNativeLiteral(literal)) {
            continue;
          }
          failures.add(
            '${file.path}:${_lineForOffset(source, match.start)} '
            '${pattern.name}: $literal',
          );
        }
      }
    }

    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('Linux package metadata matches supplied target locales', () {
    final failures = _metadataTranslationFailures().toList();

    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('package metadata uses reviewed product wording in every locale', () {
    final desktop = File(
      'linux/io.busystack.busymark.desktop',
    ).readAsStringSync();
    final metainfo = File(
      'linux/io.busystack.busymark.metainfo.xml',
    ).readAsStringSync();
    const summaries = <String, String>{
      'ar': 'محرر لملفات Markdown ومشاريع التوثيق المتوافقة مع Writerside',
      'de':
          'Editor für Markdown-Dateien und Writerside-kompatible '
          'Dokumentationsprojekte',
      'es':
          'Editor de archivos Markdown y proyectos de documentación '
          'compatibles con Writerside',
      'et':
          'Markdowni failide ja Writerside’iga ühilduvate '
          'dokumentatsiooniprojektide redaktor',
      'fa':
          'ویرایشگر فایل‌های Markdown و پروژه‌های مستندسازی سازگار با '
          'Writerside',
      'fr':
          'Éditeur de fichiers Markdown et de projets de documentation '
          'compatibles avec Writerside',
      'hi':
          'Markdown फ़ाइलों और Writerside-संगत दस्तावेज़ीकरण परियोजनाओं का '
          'संपादक',
      'it':
          'Editor per file Markdown e progetti di documentazione compatibili '
          'con Writerside',
      'nb':
          'Redigerer for Markdown-filer og Writerside-kompatible '
          'dokumentasjonsprosjekter',
      'pl':
          'Edytor plików Markdown i projektów dokumentacji zgodnych z '
          'Writerside',
      'pt':
          'Editor de arquivos Markdown e projetos de documentação compatíveis '
          'com o Writerside',
      'ru':
          'Редактор файлов Markdown и проектов документации, совместимых с '
          'Writerside',
      'uk':
          'Редактор файлів Markdown і проєктів документації, сумісних із '
          'Writerside',
    };

    for (final entry in summaries.entries) {
      expect(
        desktop,
        contains('Comment[${entry.key}]=${entry.value}'),
        reason: 'desktop ${entry.key}',
      );
      expect(
        metainfo,
        contains('<summary xml:lang="${entry.key}">${entry.value}</summary>'),
        reason: 'AppStream ${entry.key}',
      );
    }
  });

  test('target ARBs match the English messages and placeholders', () {
    final templateFile = File('lib/l10n/app_en.arb');
    final templateArb = _arbMessages(templateFile);
    final template = _arbMessageStrings(templateFile);
    final failures = <String>[];
    for (final file in _arbFiles()) {
      if (file.path.endsWith('app_en.arb')) {
        continue;
      }
      final messages = _arbMessageStrings(file);
      final missing = template.keys.toSet().difference(messages.keys.toSet());
      final extra = messages.keys.toSet().difference(template.keys.toSet());
      for (final key in missing.toList()..sort()) {
        failures.add('${file.path}: missing message $key');
      }
      for (final key in extra.toList()..sort()) {
        failures.add('${file.path}: unexpected message $key');
      }
      for (final key in template.keys.toSet().intersection(
        messages.keys.toSet(),
      )) {
        for (final placeholder in _declaredPlaceholders(templateArb, key)) {
          if (_usesPlaceholder(messages[key]!, placeholder)) {
            continue;
          }
          failures.add(
            '${file.path}: $key is missing placeholder {$placeholder}',
          );
        }
      }
    }

    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('unsaved-changes discard actions are distinct from cancel', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final localizations = lookupAppLocalizations(locale);
      expect(
        localizations.discard,
        isNot(localizations.cancel),
        reason:
            '${locale.toLanguageTag()} must not translate Discard as Cancel',
      );
      expect(
        localizations.closeUnsavedChangesDiscard,
        isNot(localizations.closeUnsavedChangesCancel),
        reason:
            '${locale.toLanguageTag()} must not translate window-close '
            'Discard as Cancel',
      );
    }

    final russian = lookupAppLocalizations(const Locale('ru'));
    expect(russian.discard, 'Не сохранять');
    expect(russian.closeUnsavedChangesDiscard, 'Не сохранять');
    expect(russian.unsavedChanges, 'Несохранённые изменения');
    expect(russian.closeUnsavedChangesTitle, 'Несохранённые изменения');
  });

  test('English-identical target messages are explicitly reviewed', () {
    final english = _arbMessageStrings(File('lib/l10n/app_en.arb'));
    final failures = <String>[];
    for (final file in _arbFiles()) {
      if (file.path.endsWith('app_en.arb')) {
        continue;
      }
      final arb = _arbMessages(file);
      final locale = arb['@@locale'] as String;
      final allowed = {
        ..._sharedEnglishMatches,
        ...?_localeSpecificEnglishMatches[locale],
      };
      for (final entry in _arbMessageStrings(file).entries) {
        if (entry.value == english[entry.key] && !allowed.contains(entry.key)) {
          failures.add(
            '${file.path}: ${entry.key} unexpectedly still matches English',
          );
        }
      }
    }

    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('RTL translations isolate technical interpolations', () {
    const fsi = '\u2068';
    const pdi = '\u2069';
    final localizations = <AppLocalizations>[
      AppLocalizationsAr(),
      AppLocalizationsFa(),
    ];

    for (final l10n in localizations) {
      expect(
        l10n.errorPathDoesNotExist('docs/intro-v2.md'),
        contains('${fsi}docs/intro-v2.md$pdi'),
      );
      expect(
        l10n.confirmDeleteFileMessage('topic-v2.md'),
        contains('${fsi}topic-v2.md$pdi'),
      );
      expect(l10n.feedbackSuccess('BM-12345'), contains('${fsi}BM-12345$pdi'));
      expect(
        l10n.workspaceErrorOpenFailed('ENOENT: docs/topic.md'),
        contains('${fsi}ENOENT: docs/topic.md$pdi'),
      );
      final branchTitle = l10n.gitConfirmSwitchBranchTitle('feature/rtl-v2');
      expect(branchTitle, contains('${fsi}feature/rtl-v2$pdi'));
      expect(branchTitle.split(fsi).length - 1, 1);
      expect(branchTitle.split(pdi).length - 1, 1);
      expect(l10n.gitDetachedHeadAt('a1b2c3d'), contains('${fsi}a1b2c3d$pdi'));
      expect(
        l10n.gitDiffHunkRange('-12,4', '+12,6'),
        allOf(contains('$fsi-12,4$pdi'), contains('$fsi+12,6$pdi')),
      );
      expect(
        l10n.diagnosticWritersideVariableUnresolved('api-version'),
        contains('$fsi%api-version%$pdi'),
      );
    }
  });

  test('Persian dynamic numbers use Persian digits', () {
    const fsi = '\u2068';
    const pdi = '\u2069';
    final fa = AppLocalizationsFa();

    expect(fa.diagnosticCount(12), contains('۱۲'));
    expect(fa.headingLevelAbbreviation(6), '${fsi}H۶$pdi');
    expect(fa.searchResultLine('docs/topic.md', 42), contains('$fsi۴۲$pdi'));
    expect(fa.gitAdditionsDeletions(12, 3), '$fsi+۱۲ -۳$pdi');

    // The generic `ar` locale in package:intl intentionally uses Latin digits.
    // Regional Arabic locales can choose different numbering systems.
    expect(AppLocalizationsAr().diagnosticCount(12), contains('12'));
  });

  test(
    'locale resolution considers all preferences and falls back to English',
    () {
      expect(
        resolveBusyMarkLocales(const [
          Locale('eo'),
          Locale('de', 'DE'),
        ], AppLocalizations.supportedLocales),
        const Locale('de'),
      );
      expect(
        resolveBusyMarkLocales(const [
          Locale('eo'),
          Locale('kl'),
        ], AppLocalizations.supportedLocales),
        const Locale('en'),
      );
    },
  );

  test('every selectable locale has a generated catalog', () {
    expect(
      busyMarkLocaleOptions.map((option) => option.locale).toSet(),
      AppLocalizations.supportedLocales.toSet(),
    );
  });

  testWidgets('diagnostics localize at render time from codes and args', (
    tester,
  ) async {
    final l10n = AppLocalizationsEn();
    const diagnostic = Diagnostic(
      code: 'markdown.heading.duplicate-id',
      severity: DiagnosticSeverity.warning,
      filePath: 'topic.md',
      args: {'id': 'intro'},
    );

    expect(diagnostic.toJson().containsKey('message'), isFalse);

    late String localized;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            localized = localizeDiagnostic(context, diagnostic);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(localized, l10n.diagnosticMarkdownHeadingDuplicateId('intro'));
  });
}

class _LiteralPattern {
  const _LiteralPattern(this.name, this.source, {this.dotAll = false});

  final String name;
  final String source;
  final bool dotAll;

  RegExp get regExp => RegExp(source, dotAll: dotAll);
}

Iterable<File> _productionDartFiles() sync* {
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    if (entity.path.contains('/l10n/generated/')) {
      continue;
    }
    yield entity;
  }
}

Iterable<File> _arbFiles() sync* {
  for (final entity in Directory('lib/l10n').listSync()) {
    if (entity is File && entity.path.endsWith('.arb')) {
      yield entity;
    }
  }
}

Map<String, Object?> _arbMessages(File file) {
  return jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
}

Map<String, String> _arbMessageStrings(File file) {
  final arb = _arbMessages(file);
  return {
    for (final entry in arb.entries)
      if (!entry.key.startsWith('@') && entry.value is String)
        entry.key: entry.value! as String,
  };
}

Set<String> _declaredPlaceholders(Map<String, Object?> arb, String key) {
  final metadata = arb['@$key'];
  if (metadata is! Map<String, Object?>) {
    return const {};
  }
  final placeholders = metadata['placeholders'];
  if (placeholders is! Map<String, Object?>) {
    return const {};
  }
  return placeholders.keys.toSet();
}

bool _usesPlaceholder(String message, String placeholder) =>
    RegExp('\\{${RegExp.escape(placeholder)}(?:\\}|\\s*,)').hasMatch(message);

Iterable<File> _nativeLinuxSourceFiles() sync* {
  for (final entity in Directory('linux/runner').listSync(recursive: true)) {
    if (entity is! File) {
      continue;
    }
    if (!entity.path.endsWith('.cc') && !entity.path.endsWith('.h')) {
      continue;
    }
    yield entity;
  }
}

bool _allowedLiteral(String literal) {
  final interpolationStripped = literal.replaceAll(
    RegExp(r'\$\{[^}]*\}|\$[A-Za-z_][A-Za-z0-9_]*'),
    '',
  );
  final hasReadableWord = RegExp(
    r'[A-Za-z]{3,}',
  ).hasMatch(interpolationStripped);
  return _fileExtension.hasMatch(literal) ||
      _mimeType.hasMatch(literal) ||
      _routePath.hasMatch(literal) ||
      _technicalToken.hasMatch(literal) ||
      literal.startsWith(r'$') ||
      !hasReadableWord ||
      // Code fence language identifier example; not translatable prose.
      literal == 'dart' ||
      literal == 'Ubuntu Mono' ||
      literal == 'Ubuntu' ||
      literal.startsWith('Ctrl+') ||
      literal.startsWith('Alt+') ||
      literal == 'Esc';
}

bool _allowedNativeLiteral(String literal) {
  return literal.isEmpty ||
      _fileExtension.hasMatch(literal) ||
      _mimeType.hasMatch(literal) ||
      _routePath.hasMatch(literal) ||
      _technicalToken.hasMatch(literal);
}

Iterable<String> _metadataTranslationFailures() sync* {
  final targetLocales = _targetArbLocales();
  final desktop = File(
    'linux/io.busystack.busymark.desktop',
  ).readAsStringSync();
  final metainfo = File(
    'linux/io.busystack.busymark.metainfo.xml',
  ).readAsStringSync();
  final snap = File('snap/snapcraft.yaml').readAsStringSync();

  if (!snap.contains('Snap Store listing translations are managed outside')) {
    yield 'snap/snapcraft.yaml: missing note that Snap Store translations are '
        'managed outside Flutter metadata';
  }

  if (targetLocales.isEmpty) {
    if (RegExp(
      r'^(Name|Comment)\[[A-Za-z_@.-]+\]=',
      multiLine: true,
    ).hasMatch(desktop)) {
      yield 'linux/io.busystack.busymark.desktop: localized entries exist but '
          'no matching target ARB locale files are present';
    }
    if (metainfo.contains('xml:lang=')) {
      yield 'linux/io.busystack.busymark.metainfo.xml: localized entries exist '
          'but no matching target ARB locale files are present';
    }
    return;
  }

  for (final locale in targetLocales) {
    final xmlLocale = locale.replaceAll('_', '-');
    if (!desktop.contains('Name[$locale]=')) {
      yield 'linux/io.busystack.busymark.desktop: missing Name[$locale]';
    }
    if (!desktop.contains('Comment[$locale]=')) {
      yield 'linux/io.busystack.busymark.desktop: missing Comment[$locale]';
    }
    if (!RegExp('<name\\s+xml:lang="$xmlLocale">').hasMatch(metainfo)) {
      yield 'linux/io.busystack.busymark.metainfo.xml: missing localized '
          '<name> for $xmlLocale';
    }
    if (!RegExp('<summary\\s+xml:lang="$xmlLocale">').hasMatch(metainfo)) {
      yield 'linux/io.busystack.busymark.metainfo.xml: missing localized '
          '<summary> for $xmlLocale';
    }
    if (!RegExp('<p\\s+xml:lang="$xmlLocale">').hasMatch(metainfo)) {
      yield 'linux/io.busystack.busymark.metainfo.xml: missing localized '
          'description paragraph for $xmlLocale';
    }
  }
}

List<String> _targetArbLocales() {
  final locales = <String>[];
  for (final entity in Directory('lib/l10n').listSync()) {
    if (entity is! File) {
      continue;
    }
    final name = entity.uri.pathSegments.last;
    final match = RegExp(r'^app_([A-Za-z_]+)\.arb$').firstMatch(name);
    if (match == null) {
      continue;
    }
    final locale = match.group(1)!;
    if (locale != 'en') {
      locales.add(locale);
    }
  }
  locales.sort();
  return locales;
}

int _lineForOffset(String source, int offset) {
  return '\n'.allMatches(source.substring(0, offset)).length + 1;
}

final _fileExtension = RegExp(r'^\.[A-Za-z0-9]+(?: or \.[A-Za-z0-9]+)?$');
final _mimeType = RegExp(r'^[a-z]+/[A-Za-z0-9.+-]+$');
final _routePath = RegExp(r'^/[A-Za-z0-9_./:-]+$');
final _technicalToken = RegExp(
  r'^(?=.*[_.:+#%/@<>{}\[\]()-])[A-Za-z0-9_.:+#%/@<>{}\[\]()-]+$',
);

const _nativeGtkUserFacingPatterns = <_LiteralPattern>[
  _LiteralPattern(
    'GTK placeholder literal',
    r'\bgtk_entry_set_placeholder_text\s*\([^;]*,\s*"([^"]*)"\s*\)',
    dotAll: true,
  ),
  _LiteralPattern(
    'GTK tooltip literal',
    r'\bgtk_widget_set_tooltip_text\s*\([^;]*,\s*"([^"]*)"\s*\)',
    dotAll: true,
  ),
  _LiteralPattern(
    'GTK label literal',
    r'\bgtk_label_set_text\s*\([^;]*,\s*"([^"]*)"\s*\)',
    dotAll: true,
  ),
  _LiteralPattern(
    'GTK button label literal',
    r'\bgtk_button_set_label\s*\([^;]*,\s*"([^"]*)"\s*\)',
    dotAll: true,
  ),
  _LiteralPattern(
    'GTK menu item label literal',
    r'\bgtk_menu_item_new_with_label\s*\(\s*"([^"]*)"\s*\)',
    dotAll: true,
  ),
  _LiteralPattern(
    'GTK header title literal',
    r'\bgtk_header_bar_set_title\s*\([^;]*,\s*"([^"]*)"\s*\)',
    dotAll: true,
  ),
];

const _sharedEnglishMatches = <String>{
  'appTitle',
  'aboutLicenseName',
  'markdown',
  'languageEnglish',
  'languageGerman',
  'languageItalian',
  'languageNorwegian',
  'languageFrench',
  'languageRussian',
  'languageUkrainian',
  'languagePolish',
  'languageSpanish',
  'languagePortuguese',
  'languageArabic',
  'languagePersian',
  'languageHindi',
  'languageEstonian',
  'writerside',
  'xml',
  'fileTypeMarkdown',
  'headingLevelAbbreviation',
  'git',
  'gitPull',
  'gitPush',
  'gitAdditionsDeletions',
};

const _localeSpecificEnglishMatches = <String, Set<String>>{
  'de': {
    'aboutWebsite',
    'editor',
    'horizontal',
    'link',
    'tabs',
    'tab',
    'gitDetachedHead',
    'gitBranches',
    'gitCommit',
  },
  'et': {'link', 'gitCommit'},
  'es': {
    'editor',
    'gitCommit',
    'horizontal',
    'vertical',
    'shortcutGroupGeneral',
  },
  'fr': {
    'source',
    'validation',
    'fileTypeImages',
    'defaultProjectName',
    'image',
    'foldKindSection',
    'note',
    'gitBranches',
    'gitCommit',
    'editorPlaceholderCode',
  },
  'it': {
    'editor',
    'file',
    'checklist',
    'privacy',
    'toc',
    'foldKindTag',
    'gitCommit',
  },
  'nb': {'systemTheme', 'systemLanguage', 'gitCommit'},
  'pl': {'folder', 'foldKindTag'},
  'pt': {
    'editor',
    'link',
    'toc',
    'foldKindTag',
    'gitBranches',
    'gitCommit',
    'horizontal',
    'vertical',
  },
  'hi': {'toc'},
};
