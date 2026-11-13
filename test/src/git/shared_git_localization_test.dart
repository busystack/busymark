import 'dart:convert';
import 'dart:io';
import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/git/application/shared_git_localizations.dart';
import 'package:busystack_git_flutter/busystack_git_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Set<String> parameters(String message) => RegExp(
  r'\{([A-Za-z][A-Za-z0-9_]*)\}',
).allMatches(message).map((match) => match[1]!).toSet();
void main() {
  test(
    'English host methods preserve every named value and its position',
    () async {
      final strings = await AppLocalizations.delegate.load(const Locale('en'));
      for (final template in GitMessages.all.toSet()) {
        final values = {
          for (final name in parameters(template)) name: '⟦$name/東京\n{other}⟧',
        };
        final expected = template.replaceAllMapped(
          RegExp(r'\{([A-Za-z][A-Za-z0-9_]*)\}'),
          (match) => values[match[1]]!,
        );
        expect(
          strings.translateSharedGitMessage(template, values),
          expected,
          reason: template,
        );
      }
    },
  );
  test(
    'every supported catalog explicitly translates all Git messages with the same parameters',
    () async {
      final english =
          (jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map)
              .cast<String, Object?>();
      final entries = {
        for (final entry in english.entries)
          if (entry.key.startsWith('gitUi') || entry.key.startsWith('gitHost'))
            entry.key: entry.value as String,
      };
      final failures = <String>[];
      for (final locale in AppLocalizations.supportedLocales) {
        final suffix = [
          locale.languageCode,
          if (locale.countryCode != null) locale.countryCode!,
        ].join('_');
        final data =
            jsonDecode(File('lib/l10n/app_$suffix.arb').readAsStringSync())
                as Map;
        for (final entry in entries.entries) {
          final value = data[entry.key];
          if (value is! String ||
              value.trim().isEmpty ||
              !setEquals(parameters(value), parameters(entry.value))) {
            failures.add('$suffix:${entry.key}');
          }
          if (value is String) {
            final identifiers = RegExp(
              r'\bHEAD\b|--[a-z]+(?:-[a-z]+)*',
            ).allMatches(entry.value).map((m) => m[0]!);
            for (final identifier in identifiers) {
              if (!value.contains(identifier)) {
                failures.add('$suffix:${entry.key}: missing $identifier');
              }
            }
            if (RegExp(r'ZQX|X\d{3}X|38641952\d\d').hasMatch(value)) {
              failures.add('$suffix:${entry.key}: invalid authoring marker');
            }
          }
        }
        final strings = await AppLocalizations.delegate.load(locale);
        for (final template in GitMessages.all.toSet()) {
          final values = {
            for (final name in parameters(template))
              name: '⟦$name/東京/{literal}⟧',
          };
          final result = strings.translateSharedGitMessage(template, values);
          for (final value in values.values) {
            expect(result, contains(value), reason: '$suffix: $template');
          }
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    },
  );
}
