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
        'toast message literal',
        r'\bBusyMarkToastOverlay\.(?:show|maybeShow)\([^)]*'
            r"message:\s*'([^']*[A-Z][^']*)'",
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
      'nl':
          'Editor voor Markdown-bestanden en Writerside-compatibele '
          'documentatieprojecten',
      'tr':
          'Markdown dosyaları ve Writerside uyumlu dokümantasyon '
          'projeleri için düzenleyici',
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
      'id':
          'Editor untuk file Markdown dan proyek dokumentasi yang kompatibel '
          'dengan Writerside',
      'ja': 'Markdown ファイルおよび Writerside 互換のドキュメントプロジェクト用エディター',
      'ko': 'Markdown 파일 및 Writerside 호환 문서 프로젝트용 편집기',
      'it':
          'Editor per file Markdown e progetti di documentazione compatibili '
          'con Writerside',
      'nb':
          'Redigerer for Markdown-filer og Writerside-kompatible '
          'dokumentasjonsprosjekter',
      'pl':
          'Edytor plików Markdown i projektów dokumentacji zgodnych z '
          'Writerside',
      'pt_BR':
          'Editor de arquivos Markdown e projetos de documentação compatíveis '
          'com o Writerside',
      'ru':
          'Редактор файлов Markdown и проектов документации, совместимых с '
          'Writerside',
      'uk':
          'Редактор файлів Markdown і проєктів документації, сумісних із '
          'Writerside',
      'vi':
          'Trình biên tập tệp Markdown và các dự án tài liệu tương thích với '
          'Writerside',
      'zh-CN': 'Markdown 文件和兼容 Writerside 的文档项目编辑器',
    };

    for (final entry in summaries.entries) {
      final desktopLocale = entry.key.replaceAll('-', '_');
      final xmlLocale = entry.key.replaceAll('_', '-');
      expect(
        desktop,
        contains('Comment[$desktopLocale]=${entry.value}'),
        reason: 'desktop ${entry.key}',
      );
      expect(
        metainfo,
        contains('<summary xml:lang="$xmlLocale">${entry.value}</summary>'),
        reason: 'AppStream ${entry.key}',
      );
    }
  });

  test('duplicate JSON key scanning respects nested object scopes', () {
    expect(
      _duplicateJsonKeys(
        '{"message":"one","message":"two",'
        '"metadata":{"description":"one","description":"two"},'
        '"separate":{"description":"allowed"}}',
      ),
      <String>[r'$.message', r'$.metadata.description'],
    );
  });

  test('ARB catalogs have valid, unique message structure and locale IDs', () {
    final failures = <String>[];

    for (final file in _arbFiles()) {
      final source = file.readAsStringSync();
      Map<String, Object?> arb;
      try {
        arb = _arbMessages(file);
      } on FormatException catch (error) {
        failures.add('${file.path}: invalid JSON: ${error.message}');
        continue;
      }
      for (final duplicate in _duplicateJsonKeys(source)) {
        failures.add('${file.path}: duplicate JSON key $duplicate');
      }

      final name = file.uri.pathSegments.last;
      final match = RegExp(r'^app_([A-Za-z_]+)\.arb$').firstMatch(name);
      final fileLocale = match?.group(1);
      final declaredLocale = arb['@@locale'];
      if (fileLocale == null) {
        failures.add('${file.path}: filename does not identify an ARB locale');
      } else if (declaredLocale is! String || declaredLocale != fileLocale) {
        failures.add(
          '${file.path}: filename locale $fileLocale conflicts with '
          '@@locale ${declaredLocale ?? '<missing>'}',
        );
      }

      for (final entry in arb.entries) {
        if (entry.key.startsWith('@')) {
          continue;
        }
        if (entry.value is! String) {
          failures.add(
            '${file.path}: ${entry.key} has non-string message value '
            '${entry.value.runtimeType}',
          );
          continue;
        }
        if ((entry.value! as String).trim().isEmpty) {
          failures.add('${file.path}: ${entry.key} has a blank translation');
        }
      }
    }

    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('all ARBs match the English messages and placeholders', () {
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
        final declared = _declaredPlaceholders(templateArb, key);
        final used = _messageArguments(messages[key]!);
        for (final placeholder in declared.difference(used).toList()..sort()) {
          failures.add(
            '${file.path}: $key is missing placeholder {$placeholder}',
          );
        }
        for (final placeholder in used.difference(declared).toList()..sort()) {
          failures.add(
            '${file.path}: $key has unexpected placeholder {$placeholder}',
          );
        }
        for (final placeholder in declared) {
          if (!_usesPlaceholder(messages[key]!, placeholder)) {
            failures.add(
              '${file.path}: $key does not use declared placeholder '
              '{$placeholder}',
            );
          }
        }
      }
    }

    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('destructive, save, and Git history actions remain distinct', () {
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
      expect(
        localizations.save,
        isNot(localizations.gitCommit),
        reason: '${locale.toLanguageTag()} must distinguish Save from Commit',
      );
      expect(
        localizations.gitFileHistory,
        isNot(localizations.gitProjectHistory),
        reason:
            '${locale.toLanguageTag()} must distinguish File History from '
            'Project History',
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

  test('Syntax Reference is localized without legacy message keys', () {
    final english = AppLocalizationsEn();
    for (final locale in AppLocalizations.supportedLocales) {
      if (locale.languageCode == 'en') {
        continue;
      }
      final localizations = lookupAppLocalizations(locale);
      expect(
        localizations.syntaxReference,
        isNot(english.syntaxReference),
        reason: locale.toLanguageTag(),
      );
      expect(
        localizations.syntaxReferenceDiagramsDescription,
        isNot(english.syntaxReferenceDiagramsDescription),
        reason: locale.toLanguageTag(),
      );
    }

    for (final file in _arbFiles()) {
      final messages = _arbMessageStrings(file);
      expect(messages, contains('syntaxReference'), reason: file.path);
      expect(messages, isNot(contains('markdownAndHtml')), reason: file.path);
      expect(
        messages,
        isNot(contains('shortcutMarkdownAndHtmlDescription')),
        reason: file.path,
      );
    }
  });

  test('clipboard write failures are localized in every target locale', () {
    const expected = <String, String>{
      'ar': 'تعذّر نسخ المحتوى المحدد إلى الحافظة.',
      'de': 'Die Auswahl konnte nicht in die Zwischenablage kopiert werden.',
      'es': 'No se pudo copiar la selección al portapapeles.',
      'et': 'Valikut ei saanud lõikelauale kopeerida.',
      'fa': 'امکان کپی کردن محتوای انتخاب‌شده در کلیپ‌بورد وجود نداشت.',
      'fr': 'Impossible de copier la sélection dans le presse-papiers.',
      'hi': 'चयनित सामग्री को क्लिपबोर्ड पर कॉपी नहीं किया जा सका।',
      'id': 'Konten yang dipilih tidak dapat disalin ke papan klip.',
      'it': 'Impossibile copiare la selezione negli appunti.',
      'ja': '選択内容をクリップボードにコピーできませんでした。',
      'ko': '선택한 내용을 클립보드에 복사할 수 없습니다.',
      'nb': 'Utvalget kunne ikke kopieres til utklippstavlen.',
      'nl': 'De selectie kon niet naar het klembord worden gekopieerd.',
      'pl': 'Nie udało się skopiować zaznaczenia do schowka.',
      'pt': 'Não foi possível copiar a seleção para a área de transferência.',
      'pt-BR':
          'Não foi possível copiar a seleção para a área de transferência.',
      'ru': 'Не удалось скопировать выделенный фрагмент в буфер обмена.',
      'tr': 'Seçili içerik panoya kopyalanamadı.',
      'uk': 'Не вдалося скопіювати виділений фрагмент до буфера обміну.',
      'vi': 'Không thể sao chép nội dung đã chọn vào bảng nhớ tạm.',
      'zh': '无法将所选内容复制到剪贴板。',
      'zh-CN': '无法将所选内容复制到剪贴板。',
    };

    final locales = AppLocalizations.supportedLocales.where(
      (locale) => locale.languageCode != 'en',
    );
    expect(
      locales.map((locale) => locale.toLanguageTag()).toSet(),
      expected.keys,
    );
    for (final locale in locales) {
      expect(
        lookupAppLocalizations(locale).clipboardCopyFailed,
        expected[locale.toLanguageTag()],
        reason: locale.toLanguageTag(),
      );
    }
  });

  test('Portuguese and Chinese base catalogs contain reviewed UI prose', () {
    final english = lookupAppLocalizations(const Locale('en'));
    final portuguese = lookupAppLocalizations(const Locale('pt'));
    final chinese = lookupAppLocalizations(const Locale('zh'));

    for (final translated in <String>[
      portuguese.appSubtitle,
      portuguese.settings,
      portuguese.gitProjectHistory,
      portuguese.gitFileHistory,
      portuguese.exportAsPdf,
      chinese.appSubtitle,
      chinese.settings,
      chinese.gitProjectHistory,
      chinese.gitFileHistory,
      chinese.exportAsPdf,
    ]) {
      expect(
        translated,
        isNot(
          anyOf(<String>[
            english.appSubtitle,
            english.settings,
            english.gitProjectHistory,
            english.gitFileHistory,
            english.exportAsPdf,
          ]),
        ),
      );
    }

    expect(portuguese.file, 'Ficheiro');
    expect(portuguese.link, 'Ligação');
    expect(portuguese.exportReset, 'Restaurar predefinições');
    final brazilian = lookupAppLocalizations(const Locale('pt', 'BR'));
    expect(brazilian.file, 'Arquivo');
    expect(brazilian.link, 'Link');
    expect(brazilian.exportReset, 'Restaurar padrões');

    final zh = _arbMessageStrings(File('lib/l10n/app_zh.arb'));
    final zhCn = _arbMessageStrings(File('lib/l10n/app_zh_CN.arb'));
    expect(zh, zhCn);
  });

  test('completed base-catalog plurals reach their supported branches', () {
    final portuguese = lookupAppLocalizations(const Locale('pt'));
    expect(portuguese.diagnosticCount(0), 'Nenhum diagnóstico');
    expect(portuguese.diagnosticCount(1), '1 diagnóstico');
    expect(portuguese.diagnosticCount(2), '2 diagnósticos');
    expect(
      portuguese.workspaceRecoveryRestored(1),
      'Foi recuperado 1 documento não guardado. Reveja-o antes de o guardar '
      'ou descartar.',
    );
    expect(
      portuguese.workspaceRecoveryRestored(3),
      'Foram recuperados 3 documentos não guardados. Reveja cada um antes '
      'de o guardar ou descartar.',
    );

    final chinese = lookupAppLocalizations(const Locale('zh'));
    expect(chinese.diagnosticCount(0), '没有诊断信息');
    expect(chinese.diagnosticCount(1), '1 条诊断信息');
    expect(chinese.diagnosticCount(2), '2 条诊断信息');
    expect(chinese.workspaceRecoveryRestored(1), '已恢复 1 个未保存的文档。请在保存或放弃前进行检查。');
    expect(chinese.workspaceRecoveryRestored(3), '已恢复 3 个未保存的文档。请在保存或放弃前逐一检查。');
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
      final resetTitle = l10n.gitResetCurrentBranchTitle(
        'feature/rtl-v2',
        'a1b2c3d',
      );
      expect(
        resetTitle,
        allOf(
          contains('${fsi}feature/rtl-v2$pdi'),
          contains('${fsi}a1b2c3d$pdi'),
        ),
      );
      final resetMessage = l10n.gitResetCurrentBranchMessage(
        'feature/rtl-v2',
        'a1b2c3d',
      );
      expect(
        resetMessage,
        allOf(
          contains('${fsi}feature/rtl-v2$pdi'),
          contains('${fsi}a1b2c3d$pdi'),
        ),
      );
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
      expect(
        resolveBusyMarkLocales(const [
          Locale('pt'),
        ], AppLocalizations.supportedLocales),
        const Locale('pt'),
      );
      expect(
        resolveBusyMarkLocales(const [
          Locale('pt', 'PT'),
        ], AppLocalizations.supportedLocales),
        const Locale('pt'),
      );
      expect(
        resolveBusyMarkLocales(const [
          Locale('pt', 'BR'),
        ], AppLocalizations.supportedLocales),
        const Locale('pt', 'BR'),
      );
      expect(
        resolveBusyMarkLocales(const [
          Locale('zh'),
        ], AppLocalizations.supportedLocales),
        const Locale('zh'),
      );
      expect(
        resolveBusyMarkLocales(const [
          Locale('zh', 'CN'),
        ], AppLocalizations.supportedLocales),
        const Locale('zh', 'CN'),
      );
    },
  );

  test('every selectable locale has a generated catalog', () {
    expect(
      AppLocalizations.supportedLocales,
      containsAll(busyMarkLocaleOptions.map((option) => option.locale)),
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

Set<String> _messageArguments(String message) => {
  for (final match in RegExp(
    r'\{([A-Za-z][A-Za-z0-9_]*)\s*(?:\}|,\s*(?:plural|select|selectordinal)\s*,)',
  ).allMatches(message))
    match.group(1)!,
};

List<String> _duplicateJsonKeys(String source) =>
    _JsonKeyScanner(source).scan();

class _JsonKeyScanner {
  _JsonKeyScanner(this.source);

  final String source;
  final duplicates = <String>[];
  var _offset = 0;

  List<String> scan() {
    _skipWhitespace();
    _scanValue(r'$');
    return duplicates;
  }

  void _scanValue(String path) {
    _skipWhitespace();
    switch (source[_offset]) {
      case '{':
        _scanObject(path);
        return;
      case '[':
        _scanArray(path);
        return;
      case '"':
        _scanString();
        return;
      default:
        _scanScalar();
        return;
    }
  }

  void _scanObject(String path) {
    _offset++;
    _skipWhitespace();
    if (source[_offset] == '}') {
      _offset++;
      return;
    }

    final keys = <String>{};
    while (true) {
      _skipWhitespace();
      final key = _scanString();
      final keyPath = '$path.$key';
      if (!keys.add(key)) {
        duplicates.add(keyPath);
      }
      _skipWhitespace();
      _offset++; // Colon; jsonDecode performs the syntax validation.
      _scanValue(keyPath);
      _skipWhitespace();
      if (source[_offset] == '}') {
        _offset++;
        return;
      }
      _offset++; // Comma.
    }
  }

  void _scanArray(String path) {
    _offset++;
    _skipWhitespace();
    if (source[_offset] == ']') {
      _offset++;
      return;
    }

    var index = 0;
    while (true) {
      _scanValue('$path[$index]');
      index++;
      _skipWhitespace();
      if (source[_offset] == ']') {
        _offset++;
        return;
      }
      _offset++; // Comma.
    }
  }

  String _scanString() {
    final start = _offset;
    _offset++;
    while (true) {
      final codeUnit = source.codeUnitAt(_offset++);
      if (codeUnit == 0x5c) {
        _offset++;
      } else if (codeUnit == 0x22) {
        return jsonDecode(source.substring(start, _offset)) as String;
      }
    }
  }

  void _scanScalar() {
    while (_offset < source.length &&
        !const {
          ' ',
          '\t',
          '\r',
          '\n',
          ',',
          ']',
          '}',
        }.contains(source[_offset])) {
      _offset++;
    }
  }

  void _skipWhitespace() {
    while (_offset < source.length &&
        const {' ', '\t', '\r', '\n'}.contains(source[_offset])) {
      _offset++;
    }
  }
}

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
    if (locale != 'en' && locale != 'pt' && locale != 'zh') {
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
  'languageDutch',
  'languageTurkish',
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
  'languageIndonesian',
  'languageEstonian',
  'languageJapanese',
  'languageKorean',
  'languageVietnamese',
  'languageSimplifiedChinese',
  'writerside',
  'syntaxReferenceCategoryHtml',
  'syntaxReferenceMermaid',
  'syntaxReferencePlantUml',
  'syntaxReferenceD2',
  'syntaxReferenceOpenApi',
  'video',
  'xml',
  'fileTypeMarkdown',
  'pdfPageSizeA4',
  'exportLegal', // International paper format name.
  'headingLevelAbbreviation',
  'git',
  'gitPull',
  'gitPush',
  'gitAdditionsDeletions',
  'gitResetModeSoft',
  'gitResetModeMixed',
  'gitResetModeHard',
  'gitResetModeKeep',
  'ai',
};

const _localeSpecificEnglishMatches = <String, Set<String>>{
  'de': {
    'exportLayout',
    'aboutWebsite',
    'editor',
    'horizontal',
    'link',
    'tabs',
    'tab',
    'gitDetachedHead',
    'gitBranches',
    'gitCommit',
    'instanceColorOrange',
    'instanceVersion',
    'instanceStatus',
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
    'htmlInstance', // Instance is also the French technical term.
    'actions',
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
    'pdfOrientation',
    'pdfPortrait',
    'instanceColorOrange',
    'instances',
    'instanceVersion',
    'writersidePdfPage',
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
  'nb': {'systemTheme', 'systemLanguage', 'gitCommit', 'instanceStatus'},
  'pl': {'folder', 'foldKindTag', 'aiModel'},
  'pt_BR': {
    'exportLayout',
    'editor',
    'link',
    'toc',
    'foldKindTag',
    'gitBranches',
    'gitCommit',
    'horizontal',
    'vertical',
  },
  'pt': {'editor', 'horizontal', 'vertical', 'toc', 'foldKindTag', 'gitCommit'},
  'hi': {'toc'},
  'ja': {'gitFetch', 'gitCommit', 'pdfPageSizeLetter'},
  'ko': {'gitDiff', 'gitFetch', 'gitCommit', 'pdfPageSizeLetter'},
  'id': {
    'editor',
    'file',
    'folder',
    'link',
    'sourceSearchRegex',
    'tip',
    'pdfMarginNormal',
    'instanceStatus',
    'aiModel',
    'horizontal',
    'editHtml',
    'tableHeaderHint',
    'tableHeaderNumber',
    'foldKindTag',
    'gitSelectForCommit',
    'gitReset',
    'visualizationValid',
    'editInstance',
    'instanceColorTeal',
    'gitDiff',
    'gitFetch',
    'gitCommit',
    'pdfPageSizeLetter',
  },
  'nl': {
    'aboutWebsite',
    'editor',
    'recent',
    'privacy',
    'untitledMarkdownFileName',
    'link',
    'editorPlaceholderCode',
    'toc',
    'sourceSearchRegex',
    'tip',
    'tab',
    'procedure',
    'gitDiff',
    'gitFetch',
    'gitCommit',
    'syntaxReferenceHtmlContainers',
    'pdfPageSizeLetter',
    'visualizationServers',
    'instanceStatus',
    'instanceStatusRelease',
    'aiModel',
  },
  'vi': {'tab', 'gitFetch', 'gitCommit', 'gitAuthorEmail', 'pdfPageSizeLetter'},
  'zh_CN': {'gitFetch', 'gitCommit', 'gitAuthorEmail', 'pdfPageSizeLetter'},
  'zh': {'gitFetch', 'gitCommit', 'gitAuthorEmail', 'pdfPageSizeLetter'},
};
