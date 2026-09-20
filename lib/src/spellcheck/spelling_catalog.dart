import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

enum SpellingDictionaryInstallationKind { downloaded, imported }

/// Metadata for an immutable dictionary resource BusyMark can acquire.
///
/// Availability never implies that the pair is installed locally.
final class SpellingDictionaryResource {
  const SpellingDictionaryResource({
    required this.resourceId,
    required this.id,
    required this.locales,
    required this.label,
    required this.affSourcePath,
    required this.dicSourcePath,
    required this.affDownloadUrl,
    required this.dicDownloadUrl,
    required this.affSize,
    required this.dicSize,
    required this.affSha256,
    required this.dicSha256,
    required this.sourceRevision,
    this.licenseDirectory,
  });

  factory SpellingDictionaryResource.fromJson(Map<String, Object?> json) {
    String requiredString(String key) {
      final value = json[key]?.toString().trim();
      if (value == null || value.isEmpty) {
        throw FormatException('Dictionary resource is missing $key.');
      }
      return value;
    }

    int requiredSize(String key) {
      final value = json[key];
      final size = value is int ? value : int.tryParse(value?.toString() ?? '');
      if (size == null || size <= 0) {
        throw FormatException('Dictionary resource has an invalid $key.');
      }
      return size;
    }

    final affUrl = Uri.parse(requiredString('affDownloadUrl'));
    final dicUrl = Uri.parse(requiredString('dicDownloadUrl'));
    if (affUrl.scheme != 'https' || dicUrl.scheme != 'https') {
      throw const FormatException('Dictionary downloads must use HTTPS.');
    }
    return SpellingDictionaryResource(
      resourceId: requiredString('resourceId'),
      id: requiredString('id'),
      locales: _requiredLocales(json),
      label: requiredString('label'),
      affSourcePath: _safeRelative(requiredString('affSourcePath')),
      dicSourcePath: _safeRelative(requiredString('dicSourcePath')),
      affDownloadUrl: affUrl,
      dicDownloadUrl: dicUrl,
      affSize: requiredSize('affSize'),
      dicSize: requiredSize('dicSize'),
      affSha256: requiredString('affSha256'),
      dicSha256: requiredString('dicSha256'),
      sourceRevision: requiredString('sourceRevision'),
      licenseDirectory: json['licenseDirectory']?.toString(),
    );
  }

  final String resourceId;
  final String id;
  final List<String> locales;
  final String label;
  final String affSourcePath;
  final String dicSourcePath;
  final Uri affDownloadUrl;
  final Uri dicDownloadUrl;
  final int affSize;
  final int dicSize;
  final String affSha256;
  final String dicSha256;
  final String sourceRevision;
  final String? licenseDirectory;

  int get downloadSize => affSize + dicSize;
  String get fingerprint => '$affSha256:$dicSha256';
  bool supports(String languageId) =>
      id == languageId || locales.contains(languageId);
}

/// A validated pair published in application-managed persistent storage.
final class SpellingDictionaryInstallation {
  const SpellingDictionaryInstallation({
    required this.resourceId,
    required this.id,
    required this.locales,
    required this.label,
    required this.affPath,
    required this.dicPath,
    required this.affSha256,
    required this.dicSha256,
    required this.kind,
    required this.directoryPath,
    required this.sourceRevision,
  });

  factory SpellingDictionaryInstallation.fromJson(
    Map<String, Object?> json, {
    required String rootPath,
  }) {
    String requiredString(String key) {
      final value = json[key]?.toString().trim();
      if (value == null || value.isEmpty) {
        throw FormatException('Dictionary installation is missing $key.');
      }
      return value;
    }

    String installedPath(String key) =>
        p.normalize(p.join(rootPath, _safeRelative(requiredString(key))));
    return SpellingDictionaryInstallation(
      resourceId: requiredString('resourceId'),
      id: requiredString('id'),
      locales: _requiredLocales(json),
      label: requiredString('label'),
      affPath: installedPath('affPath'),
      dicPath: installedPath('dicPath'),
      affSha256: requiredString('affSha256'),
      dicSha256: requiredString('dicSha256'),
      kind: SpellingDictionaryInstallationKind.values.byName(
        requiredString('kind'),
      ),
      directoryPath: p.normalize(p.absolute(rootPath)),
      sourceRevision: requiredString('sourceRevision'),
    );
  }

  final String resourceId;
  final String id;
  final List<String> locales;
  final String label;
  final String affPath;
  final String dicPath;
  final String affSha256;
  final String dicSha256;
  final SpellingDictionaryInstallationKind kind;
  final String directoryPath;
  final String sourceRevision;

  String get fingerprint => '$affSha256:$dicSha256';
  bool get imported => kind == SpellingDictionaryInstallationKind.imported;
  bool supports(String languageId) =>
      id == languageId || locales.contains(languageId);
}

/// One language-selector row combining available metadata with local state.
final class SpellingDictionaryEntry {
  const SpellingDictionaryEntry({
    required this.id,
    required this.locales,
    required this.label,
    required this.resource,
    required this.installation,
  });

  final String id;
  final List<String> locales;
  final String label;
  final SpellingDictionaryResource? resource;
  final SpellingDictionaryInstallation? installation;

  bool get installed => installation != null;
  bool get imported => installation?.imported ?? false;
}

final class SpellingDictionaryCatalog {
  const SpellingDictionaryCatalog({
    required this.availableEntries,
    required this.installations,
    required this.unavailableEntries,
  });

  final List<SpellingDictionaryResource> availableEntries;
  final List<SpellingDictionaryInstallation> installations;
  final Map<String, String> unavailableEntries;

  List<SpellingDictionaryEntry> get entries {
    final result = <SpellingDictionaryEntry>[
      for (final resource in availableEntries)
        SpellingDictionaryEntry(
          id: resource.id,
          locales: resource.locales,
          label: resource.label,
          resource: resource,
          installation: installationForResource(resource.resourceId),
        ),
      for (final installation in installations)
        if (installation.imported &&
            !availableEntries.any(
              (resource) => resource.supports(installation.id),
            ))
          SpellingDictionaryEntry(
            id: installation.id,
            locales: installation.locales,
            label: installation.label,
            resource: null,
            installation: installation,
          ),
    ]..sort((left, right) => left.label.compareTo(right.label));
    return List.unmodifiable(result);
  }

  SpellingDictionaryResource? availableById(String id) {
    for (final entry in availableEntries) {
      if (entry.supports(id)) return entry;
    }
    return null;
  }

  SpellingDictionaryInstallation? installedById(String id) {
    final available = availableById(id);
    if (available != null) {
      return installationForResource(available.resourceId);
    }
    for (final installation in installations) {
      if (installation.supports(id)) return installation;
    }
    return null;
  }

  SpellingDictionaryInstallation? installationForResource(String resourceId) {
    for (final installation in installations) {
      if (installation.resourceId == resourceId) return installation;
    }
    return null;
  }

  SpellingDictionaryEntry? byId(String id) {
    for (final entry in entries) {
      if (entry.id == id || entry.locales.contains(id)) return entry;
    }
    return null;
  }

  static Future<SpellingDictionaryCatalog> load({
    required String bundledRoot,
    String? downloadedRoot,
    String? importedRoot,
    bool verifyChecksums = true,
  }) async {
    final available = <SpellingDictionaryResource>[];
    final installations = <SpellingDictionaryInstallation>[];
    final unavailable = <String, String>{};
    await _loadAvailableManifest(
      File(p.join(bundledRoot, 'dictionaries.json')),
      entries: available,
      unavailable: unavailable,
    );
    await _loadInstallations(
      downloadedRoot,
      expectedKind: SpellingDictionaryInstallationKind.downloaded,
      available: available,
      verifyChecksums: verifyChecksums,
      entries: installations,
      unavailable: unavailable,
    );
    await _loadInstallations(
      importedRoot,
      expectedKind: SpellingDictionaryInstallationKind.imported,
      available: available,
      verifyChecksums: verifyChecksums,
      entries: installations,
      unavailable: unavailable,
    );
    available.sort((left, right) => left.label.compareTo(right.label));
    installations.sort((left, right) => left.label.compareTo(right.label));
    return SpellingDictionaryCatalog(
      availableEntries: List.unmodifiable(available),
      installations: List.unmodifiable(installations),
      unavailableEntries: Map.unmodifiable(unavailable),
    );
  }

  static Future<void> _loadAvailableManifest(
    File manifest, {
    required List<SpellingDictionaryResource> entries,
    required Map<String, String> unavailable,
  }) async {
    if (!await manifest.exists()) {
      unavailable[manifest.path] = 'Dictionary catalog is unavailable.';
      return;
    }
    try {
      final decoded = jsonDecode(await manifest.readAsString());
      if (decoded is! Map || decoded['schemaVersion'] != 2) {
        throw const FormatException('Unsupported dictionary catalog.');
      }
      final dictionaries = decoded['dictionaries'];
      if (dictionaries is! List) {
        throw const FormatException('Dictionary catalog has no entries.');
      }
      final resourceIds = <String>{};
      final dictionaryIds = <String>{};
      for (final value in dictionaries.whereType<Map>()) {
        final json = value.cast<String, Object?>();
        final id = json['id']?.toString() ?? manifest.path;
        try {
          final entry = SpellingDictionaryResource.fromJson(json);
          if (!resourceIds.add(entry.resourceId)) {
            throw FormatException(
              'Duplicate dictionary resource ${entry.resourceId}.',
            );
          }
          if (!dictionaryIds.add(entry.id)) {
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

  static Future<void> _loadInstallations(
    String? rootPath, {
    required SpellingDictionaryInstallationKind expectedKind,
    required List<SpellingDictionaryResource> available,
    required bool verifyChecksums,
    required List<SpellingDictionaryInstallation> entries,
    required Map<String, String> unavailable,
  }) async {
    if (rootPath == null) return;
    final root = Directory(rootPath);
    if (!await root.exists()) return;
    await for (final entity in root.list()) {
      if (entity is! Directory || p.basename(entity.path).startsWith('.')) {
        continue;
      }
      final manifest = File(p.join(entity.path, 'manifest.json'));
      if (!await manifest.exists()) continue;
      try {
        final decoded = jsonDecode(await manifest.readAsString());
        if (decoded is! Map || decoded['schemaVersion'] != 1) {
          throw const FormatException('Unsupported installation manifest.');
        }
        final installation = SpellingDictionaryInstallation.fromJson(
          decoded.cast<String, Object?>(),
          rootPath: entity.path,
        );
        if (installation.kind != expectedKind) {
          throw const FormatException('Dictionary installation kind mismatch.');
        }
        if (expectedKind == SpellingDictionaryInstallationKind.downloaded) {
          final resource = available
              .where(
                (candidate) => candidate.resourceId == installation.resourceId,
              )
              .firstOrNull;
          if (resource == null ||
              resource.affSha256 != installation.affSha256 ||
              resource.dicSha256 != installation.dicSha256 ||
              resource.sourceRevision != installation.sourceRevision) {
            throw const FormatException(
              'Downloaded dictionary does not match the shipped catalog.',
            );
          }
        }
        if (entries.any(
          (candidate) => candidate.resourceId == installation.resourceId,
        )) {
          throw FormatException(
            'Duplicate installed resource ${installation.resourceId}.',
          );
        }
        await _validateInstallationFiles(
          installation,
          verifyChecksums: verifyChecksums,
        );
        entries.add(installation);
      } on Object catch (error) {
        unavailable[entity.path] = error.toString();
      }
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

List<String> _requiredLocales(Map<String, Object?> json) {
  final locales =
      (json['locales'] as List?)
          ?.map((value) => value.toString().trim())
          .where((value) => value.isNotEmpty)
          .toList(growable: false) ??
      const <String>[];
  if (locales.isEmpty) {
    throw const FormatException('Dictionary entry has no locale tags.');
  }
  return List.unmodifiable(locales);
}

String _safeRelative(String value) {
  if (p.isAbsolute(value) || p.split(value).contains('..')) {
    throw const FormatException('Dictionary path must remain relative.');
  }
  return p.posix.joinAll(p.posix.split(value));
}

Future<void> _validateInstallationFiles(
  SpellingDictionaryInstallation installation, {
  required bool verifyChecksums,
}) async {
  for (final path in [installation.affPath, installation.dicPath]) {
    final stat = await File(path).stat();
    if (stat.type != FileSystemEntityType.file) {
      throw FileSystemException('Dictionary resource is missing', path);
    }
  }
  if (!verifyChecksums) return;
  final aff = await sha256.bind(File(installation.affPath).openRead()).first;
  final dic = await sha256.bind(File(installation.dicPath).openRead()).first;
  if (aff.toString() != installation.affSha256 ||
      dic.toString() != installation.dicSha256) {
    throw const FormatException('Dictionary resource checksum mismatch.');
  }
}
