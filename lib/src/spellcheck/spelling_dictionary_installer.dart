import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import 'spelling_catalog.dart';

const int maximumSpellingAffixBytes = 16 * 1024 * 1024;
const int maximumSpellingDictionaryBytes = 256 * 1024 * 1024;

final class SpellingDictionaryInstallSpec {
  const SpellingDictionaryInstallSpec({
    required this.resourceId,
    required this.id,
    required this.locales,
    required this.label,
    required this.sourceRevision,
    required this.affSha256,
    required this.dicSha256,
    required this.affSize,
    required this.dicSize,
    required this.kind,
  });

  factory SpellingDictionaryInstallSpec.downloaded(
    SpellingDictionaryResource resource,
  ) => SpellingDictionaryInstallSpec(
    resourceId: resource.resourceId,
    id: resource.id,
    locales: resource.locales,
    label: resource.label,
    sourceRevision: resource.sourceRevision,
    affSha256: resource.affSha256,
    dicSha256: resource.dicSha256,
    affSize: resource.affSize,
    dicSize: resource.dicSize,
    kind: SpellingDictionaryInstallationKind.downloaded,
  );

  final String resourceId;
  final String id;
  final List<String> locales;
  final String label;
  final String sourceRevision;
  final String affSha256;
  final String dicSha256;
  final int affSize;
  final int dicSize;
  final SpellingDictionaryInstallationKind kind;
}

/// Validates and atomically publishes a complete affix/dictionary pair.
///
/// Downloads and local imports intentionally share this path. A published
/// directory is always complete and native-loadable; staging directories are
/// ignored by catalog discovery and removed after failure or cancellation.
final class SpellingDictionaryPairInstaller {
  const SpellingDictionaryPairInstaller();

  Future<SpellingDictionaryInstallation> install({
    required File affSource,
    required File dicSource,
    required SpellingDictionaryInstallSpec spec,
    required String destinationRoot,
    required Future<String> Function(String affPath, String dicPath)
    validateNativePair,
    void Function()? cancellationGuard,
  }) async {
    cancellationGuard?.call();
    await validateSpellingDictionaryPair(
      affSource: affSource,
      dicSource: dicSource,
      expectedAffSize: spec.affSize,
      expectedDicSize: spec.dicSize,
      expectedAffSha256: spec.affSha256,
      expectedDicSha256: spec.dicSha256,
    );
    final root = Directory(p.normalize(p.absolute(destinationRoot)));
    await root.create(recursive: true);
    final destination = Directory(
      p.join(root.path, safeSpellingResourceName(spec.resourceId)),
    );
    if (!p.isWithin(root.path, destination.path)) {
      throw StateError('Dictionary installation escaped its storage root.');
    }
    if (await destination.exists()) {
      throw FileSystemException(
        'This dictionary resource is already installed',
        destination.path,
      );
    }
    final staging = await root.createTemp('.busymark-dictionary-');
    final stagedAff = File(p.join(staging.path, 'dictionary.aff'));
    final stagedDic = File(p.join(staging.path, 'dictionary.dic'));
    try {
      await affSource.copy(stagedAff.path);
      await dicSource.copy(stagedDic.path);
      await validateSpellingDictionaryPair(
        affSource: stagedAff,
        dicSource: stagedDic,
        expectedAffSize: spec.affSize,
        expectedDicSize: spec.dicSize,
        expectedAffSha256: spec.affSha256,
        expectedDicSha256: spec.dicSha256,
      );
      cancellationGuard?.call();
      final encoding = (await validateNativePair(
        stagedAff.path,
        stagedDic.path,
      )).trim();
      if (encoding.isEmpty) {
        throw const FormatException('Dictionary declares no usable encoding.');
      }
      cancellationGuard?.call();
      final manifest = <String, Object?>{
        'schemaVersion': 1,
        'kind': spec.kind.name,
        'resourceId': spec.resourceId,
        'id': spec.id,
        'locales': spec.locales,
        'label': spec.label,
        'sourceRevision': spec.sourceRevision,
        'affPath': 'dictionary.aff',
        'dicPath': 'dictionary.dic',
        'affSha256': spec.affSha256,
        'dicSha256': spec.dicSha256,
      };
      await File(p.join(staging.path, 'manifest.json')).writeAsString(
        '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
        flush: true,
      );
      cancellationGuard?.call();
      await staging.rename(destination.path);
      return SpellingDictionaryInstallation(
        resourceId: spec.resourceId,
        id: spec.id,
        locales: List.unmodifiable(spec.locales),
        label: spec.label,
        affPath: p.join(destination.path, 'dictionary.aff'),
        dicPath: p.join(destination.path, 'dictionary.dic'),
        affSha256: spec.affSha256,
        dicSha256: spec.dicSha256,
        kind: spec.kind,
        directoryPath: destination.path,
        sourceRevision: spec.sourceRevision,
      );
    } finally {
      if (await staging.exists()) {
        await staging.delete(recursive: true);
      }
    }
  }

  Future<void> remove({
    required SpellingDictionaryInstallation installation,
    required String installationRoot,
  }) async {
    final root = p.normalize(p.absolute(installationRoot));
    final target = p.normalize(p.absolute(installation.directoryPath));
    if (!p.isWithin(root, target) || p.equals(root, target)) {
      throw StateError('Dictionary removal escaped its storage root.');
    }
    final directory = Directory(target);
    if (await directory.exists()) await directory.delete(recursive: true);
  }
}

Future<void> validateSpellingDictionaryPair({
  required File affSource,
  required File dicSource,
  required int expectedAffSize,
  required int expectedDicSize,
  required String expectedAffSha256,
  required String expectedDicSha256,
}) async {
  await _validateFile(
    affSource,
    maximumSpellingAffixBytes,
    expectedAffSize,
    '.aff',
  );
  await _validateFile(
    dicSource,
    maximumSpellingDictionaryBytes,
    expectedDicSize,
    '.dic',
  );
  final affChecksum = await sha256.bind(affSource.openRead()).first;
  final dicChecksum = await sha256.bind(dicSource.openRead()).first;
  if (affChecksum.toString() != expectedAffSha256 ||
      dicChecksum.toString() != expectedDicSha256) {
    throw const FormatException('Dictionary resource checksum mismatch.');
  }
  _validateAffixMetadata(
    await affSource
        .openRead(0, 64 * 1024)
        .fold<List<int>>(<int>[], (bytes, part) => bytes..addAll(part)),
  );
  final firstLine = await dicSource
      .openRead(0, 4096)
      .fold<List<int>>(<int>[], (bytes, part) => bytes..addAll(part));
  _validateDictionaryHeader(firstLine);
}

Future<void> _validateFile(
  File file,
  int maximumBytes,
  int expectedBytes,
  String extension,
) async {
  final stat = await file.stat();
  if (stat.type != FileSystemEntityType.file ||
      !file.path.toLowerCase().endsWith(extension)) {
    throw FileSystemException('Expected a readable $extension file', file.path);
  }
  if (stat.size <= 0 ||
      stat.size > maximumBytes ||
      stat.size != expectedBytes) {
    throw FileSystemException(
      'Dictionary resource has an invalid size',
      file.path,
    );
  }
  await file.openRead(0, 1).drain<void>();
}

void _validateAffixMetadata(List<int> bytes) {
  final prefix = latin1.decode(bytes, allowInvalid: true);
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

String safeSpellingResourceName(String value) =>
    value.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
