import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import 'spelling_language.dart';

const int _maximumAffixBytes = 16 * 1024 * 1024;
const int _maximumDictionaryBytes = 256 * 1024 * 1024;

final class SpellingDictionaryImporter {
  const SpellingDictionaryImporter();

  Future<void> import({
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
    await _validateFile(aff, _maximumAffixBytes, '.aff');
    await _validateFile(dic, _maximumDictionaryBytes, '.dic');
    final affBytes = await aff.readAsBytes();
    final dicBytes = await dic.readAsBytes();
    _validateAffixMetadata(affBytes);
    _validateDictionaryHeader(dicBytes);

    final root = Directory(p.normalize(p.absolute(importedRoot)));
    await root.create(recursive: true);
    final destination = Directory(p.join(root.path, _safeName(language)));
    if (await destination.exists()) {
      throw FileSystemException(
        'An imported dictionary already uses this language identity',
        destination.path,
      );
    }
    final staging = await root.createTemp('.busymark-dictionary-');
    final stagedAff = File(p.join(staging.path, 'dictionary.aff'));
    final stagedDic = File(p.join(staging.path, 'dictionary.dic'));
    try {
      await stagedAff.writeAsBytes(affBytes, flush: true);
      await stagedDic.writeAsBytes(dicBytes, flush: true);
      // Native handles stay in the application's long-lived spelling worker.
      // Publication cannot happen until that worker has opened and exercised
      // the staged pair successfully.
      final encoding = (await validateNativePair(
        stagedAff.path,
        stagedDic.path,
      )).trim();
      if (encoding.isEmpty) {
        throw const FormatException('Dictionary declares no usable encoding.');
      }
      final manifest = {
        'schemaVersion': 1,
        'dictionaries': [
          {
            'id': language,
            'locales': [language],
            'label': displayLabel.trim().isEmpty
                ? language
                : displayLabel.trim(),
            'affPath': 'dictionary.aff',
            'dicPath': 'dictionary.dic',
            'sourceRevision': 'local-import',
            'affSha256': sha256.convert(affBytes).toString(),
            'dicSha256': sha256.convert(dicBytes).toString(),
          },
        ],
      };
      await File(p.join(staging.path, 'manifest.json')).writeAsString(
        '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
        flush: true,
      );
      await staging.rename(destination.path);
    } finally {
      if (await staging.exists()) {
        await staging.delete(recursive: true);
      }
    }
  }

  Future<void> remove({
    required String languageId,
    required String importedRoot,
  }) async {
    final language = normalizeSpellingLanguageId(languageId);
    if (language == null) return;
    final root = p.normalize(p.absolute(importedRoot));
    final destination = p.normalize(p.join(root, _safeName(language)));
    if (!p.isWithin(root, destination)) {
      throw StateError('Imported dictionary path escaped its storage root.');
    }
    final directory = Directory(destination);
    if (await directory.exists()) await directory.delete(recursive: true);
  }
}

Future<void> _validateFile(
  File file,
  int maximumBytes,
  String extension,
) async {
  final stat = await file.stat();
  if (stat.type != FileSystemEntityType.file ||
      !file.path.toLowerCase().endsWith(extension)) {
    throw FileSystemException('Expected a readable $extension file', file.path);
  }
  if (stat.size <= 0 || stat.size > maximumBytes) {
    throw FileSystemException(
      'Dictionary resource has an invalid size',
      file.path,
    );
  }
  await file.openRead(0, 1).drain<void>();
}

void _validateAffixMetadata(List<int> bytes) {
  final prefix = latin1.decode(
    bytes.take(64 * 1024).toList(growable: false),
    allowInvalid: true,
  );
  final set = RegExp(
    r'^\s*SET\s+([^\s#]+)',
    multiLine: true,
    caseSensitive: false,
  ).firstMatch(prefix);
  if (set == null || set.group(1)!.trim().isEmpty) {
    throw const FormatException('The .aff file has no SET encoding directive.');
  }
}

void _validateDictionaryHeader(List<int> bytes) {
  final newline = bytes.indexOf(0x0a);
  final headerBytes = bytes.take(newline < 0 ? bytes.length : newline).toList();
  final header = ascii.decode(headerBytes, allowInvalid: false).trim();
  final count = int.tryParse(header);
  if (count == null || count < 0) {
    throw const FormatException('The .dic header is not a word count.');
  }
}

String _safeName(String value) =>
    value.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');

final RegExp _languageTag = RegExp(r'^[A-Za-z]{2,8}(?:-[A-Za-z0-9]{1,8})*$');
