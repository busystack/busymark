import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import 'spelling_catalog.dart';
import 'spelling_dictionary_installer.dart';
import 'spelling_language.dart';

final class SpellingDictionaryImporter {
  const SpellingDictionaryImporter({
    this.installer = const SpellingDictionaryPairInstaller(),
  });

  final SpellingDictionaryPairInstaller installer;

  Future<SpellingDictionaryInstallation> import({
    required String affPath,
    required String dicPath,
    required String languageId,
    required String displayLabel,
    required String importedRoot,
    required Future<String> Function(String affPath, String dicPath)
    validateNativePair,
  }) async {
    final language = normalizeSpellingLanguageId(languageId);
    if (language == null || !_languageTag.hasMatch(language)) {
      throw const FormatException('Choose an explicit valid language tag.');
    }
    final aff = File(p.normalize(p.absolute(affPath)));
    final dic = File(p.normalize(p.absolute(dicPath)));
    if (p.basenameWithoutExtension(aff.path) !=
        p.basenameWithoutExtension(dic.path)) {
      throw const FormatException(
        'The .aff and .dic files must have the same base name.',
      );
    }
    final affStat = await aff.stat();
    final dicStat = await dic.stat();
    final affChecksum = await sha256.bind(aff.openRead()).first;
    final dicChecksum = await sha256.bind(dic.openRead()).first;
    final spec = SpellingDictionaryInstallSpec(
      resourceId: language,
      id: language,
      locales: [language],
      label: displayLabel.trim().isEmpty ? language : displayLabel.trim(),
      sourceRevision: 'local-import',
      affSha256: affChecksum.toString(),
      dicSha256: dicChecksum.toString(),
      affSize: affStat.size,
      dicSize: dicStat.size,
      kind: SpellingDictionaryInstallationKind.imported,
    );
    return installer.install(
      affSource: aff,
      dicSource: dic,
      spec: spec,
      destinationRoot: importedRoot,
      validateNativePair: validateNativePair,
    );
  }
}

final RegExp _languageTag = RegExp(r'^[A-Za-z]{2,8}(?:-[A-Za-z0-9]{1,8})*$');
