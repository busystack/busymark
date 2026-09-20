import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

final class SpellingDictionaryEntry {
  const SpellingDictionaryEntry({
    required this.id,
    required this.locales,
    required this.label,
    required this.affPath,
    required this.dicPath,
    required this.affSha256,
    required this.dicSha256,
    required this.imported,
    this.sourceRevision,
    this.licenseDirectory,
  });

  factory SpellingDictionaryEntry.fromJson(
    Map<String, Object?> json, {
    required String rootPath,
    required bool imported,
  }) {
    String requiredString(String key) {
      final value = json[key]?.toString().trim();
      if (value == null || value.isEmpty) {
        throw FormatException('Dictionary entry is missing $key.');
      }
      return value;
    }

    final locales =
        (json['locales'] as List?)
            ?.map((value) => value.toString().trim())
            .where((value) => value.isNotEmpty)
            .toList(growable: false) ??
        const <String>[];
    if (locales.isEmpty) {
      throw const FormatException('Dictionary entry has no locale tags.');
    }
    String resolvedPath(String key) {
      final relative = requiredString(key);
      if (p.isAbsolute(relative) || p.split(relative).contains('..')) {
        throw FormatException('Dictionary $key must stay inside its catalog.');
      }
      return p.normalize(p.join(rootPath, relative));
    }

    return SpellingDictionaryEntry(
      id: requiredString('id'),
      locales: List.unmodifiable(locales),
      label: requiredString('label'),
      affPath: resolvedPath('affPath'),
      dicPath: resolvedPath('dicPath'),
      affSha256: requiredString('affSha256'),
      dicSha256: requiredString('dicSha256'),
      imported: imported,
      sourceRevision: json['sourceRevision']?.toString(),
      licenseDirectory: json['licenseDirectory']?.toString(),
    );
  }

  final String id;
  final List<String> locales;
  final String label;
  final String affPath;
  final String dicPath;
  final String affSha256;
  final String dicSha256;
  final bool imported;
  final String? sourceRevision;
  final String? licenseDirectory;

  String get fingerprint => '$affSha256:$dicSha256';
}

final class SpellingDictionaryCatalog {
  const SpellingDictionaryCatalog({
    required this.entries,
    required this.unavailableEntries,
  });

  final List<SpellingDictionaryEntry> entries;
  final Map<String, String> unavailableEntries;

  SpellingDictionaryEntry? byId(String id) {
    for (final entry in entries) {
      if (entry.id == id || entry.locales.contains(id)) return entry;
    }
    return null;
  }

  static Future<SpellingDictionaryCatalog> load({
    required String bundledRoot,
    String? importedRoot,
    bool verifyChecksums = true,
  }) async {
    final entries = <SpellingDictionaryEntry>[];
    final unavailable = <String, String>{};
    await _loadManifest(
      File(p.join(bundledRoot, 'dictionaries.json')),
      rootPath: bundledRoot,
      imported: false,
      verifyChecksums: verifyChecksums,
      entries: entries,
      unavailable: unavailable,
    );
    final importedDirectory = importedRoot == null
        ? null
        : Directory(importedRoot);
    if (importedDirectory != null && await importedDirectory.exists()) {
      await for (final entity in importedDirectory.list()) {
        if (entity is! Directory) continue;
        final manifest = File(p.join(entity.path, 'manifest.json'));
        if (!await manifest.exists()) continue;
        await _loadManifest(
          manifest,
          rootPath: entity.path,
          imported: true,
          verifyChecksums: verifyChecksums,
          entries: entries,
          unavailable: unavailable,
        );
      }
    }
    entries.sort((left, right) => left.label.compareTo(right.label));
    return SpellingDictionaryCatalog(
      entries: List.unmodifiable(entries),
      unavailableEntries: Map.unmodifiable(unavailable),
    );
  }

  static Future<void> _loadManifest(
    File manifest, {
    required String rootPath,
    required bool imported,
    required bool verifyChecksums,
    required List<SpellingDictionaryEntry> entries,
    required Map<String, String> unavailable,
  }) async {
    if (!await manifest.exists()) {
      unavailable[manifest.path] = 'Dictionary manifest is unavailable.';
      return;
    }
    try {
      final decoded = jsonDecode(await manifest.readAsString());
      if (decoded is! Map || decoded['schemaVersion'] != 1) {
        throw const FormatException('Unsupported dictionary manifest.');
      }
      final dictionaries = decoded['dictionaries'];
      if (dictionaries is! List) {
        throw const FormatException('Dictionary manifest has no entries.');
      }
      for (final value in dictionaries.whereType<Map>()) {
        final json = value.cast<String, Object?>();
        final id = json['id']?.toString() ?? manifest.path;
        try {
          final entry = SpellingDictionaryEntry.fromJson(
            json,
            rootPath: rootPath,
            imported: imported,
          );
          await _validateEntryFiles(entry, verifyChecksums: verifyChecksums);
          if (entries.any((candidate) => candidate.id == entry.id)) {
            throw FormatException('Duplicate dictionary ID ${entry.id}.');
          }
          entries.add(entry);
        } on Object catch (error) {
          unavailable[id] = error.toString();
        }
      }
    } on Object catch (error) {
      unavailable[manifest.path] = error.toString();
    }
  }
}

final class SpellingResourceLocator {
  const SpellingResourceLocator({this.environment, this.resolvedExecutable});

  final Map<String, String>? environment;
  final String? resolvedExecutable;

  String? locate() {
    final processEnvironment = environment ?? Platform.environment;
    final executableDirectory = p.dirname(
      resolvedExecutable ?? Platform.resolvedExecutable,
    );
    final candidates = <String>[
      if (processEnvironment['BUSYMARK_SPELLING_PATH'] case final override?)
        override,
      if (processEnvironment['SNAP'] case final snapRoot?)
        p.join(snapRoot, 'share', 'busymark', 'spelling'),
      p.join(executableDirectory, 'share', 'busymark', 'spelling'),
      p.normalize(
        p.join(executableDirectory, '..', 'share', 'busymark', 'spelling'),
      ),
      p.join(executableDirectory, 'data', 'flutter_assets', 'spelling'),
    ];
    for (final candidate in candidates) {
      try {
        final manifest = File(p.join(candidate, 'dictionaries.json'));
        if (manifest.statSync().type == FileSystemEntityType.file) {
          return p.normalize(p.absolute(candidate));
        }
      } on FileSystemException {
        // Continue through deterministic application-bundle locations.
      }
    }
    return null;
  }
}

Future<void> _validateEntryFiles(
  SpellingDictionaryEntry entry, {
  required bool verifyChecksums,
}) async {
  for (final path in [entry.affPath, entry.dicPath]) {
    final stat = await File(path).stat();
    if (stat.type != FileSystemEntityType.file) {
      throw FileSystemException('Dictionary resource is missing', path);
    }
  }
  if (!verifyChecksums) return;
  final aff = await sha256.bind(File(entry.affPath).openRead()).first;
  final dic = await sha256.bind(File(entry.dicPath).openRead()).first;
  if (aff.toString() != entry.affSha256 || dic.toString() != entry.dicSha256) {
    throw const FormatException('Dictionary resource checksum mismatch.');
  }
}
