import 'dart:io';

import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/l10n/generated/app_localizations_en.dart';
import 'package:busymark/src/core/diagnostic.dart';
import 'package:busymark/src/core/diagnostic_localizations.dart';
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
