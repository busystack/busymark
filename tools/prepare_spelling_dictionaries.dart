import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

const sourceRevision = '32b006a2c22a4ac7e8ed3f03346f7b3d85a970a4';
const selectedPackages = <String>{
  'ar',
  'de',
  'en',
  'es',
  'et_EE',
  'fa_IR',
  'fr_FR',
  'hi_IN',
  'id',
  'it_IT',
  'ko_KR',
  'no',
  'nl_NL',
  'pl_PL',
  'pt_BR',
  'ru_RU',
  'tr_TR',
  'uk_UA',
  'vi',
};

const languageNames = <String, String>{
  'ar': 'Arabic',
  'de': 'German',
  'en': 'English',
  'es': 'Spanish',
  'et': 'Estonian',
  'fa': 'Persian',
  'fr': 'French',
  'hi': 'Hindi',
  'id': 'Indonesian',
  'it': 'Italian',
  'ko': 'Korean',
  'nb': 'Norwegian Bokmål',
  'nn': 'Norwegian Nynorsk',
  'nl': 'Dutch',
  'pl': 'Polish',
  'pt': 'Portuguese',
  'ru': 'Russian',
  'tr': 'Turkish',
  'uk': 'Ukrainian',
  'vi': 'Vietnamese',
};

Future<void> main(List<String> arguments) async {
  if (arguments.length < 2 ||
      arguments.length > 3 ||
      (arguments.length == 3 && arguments[2] != '--include-pairs')) {
    stderr.writeln(
      'Usage: dart run tools/prepare_spelling_dictionaries.dart '
      'SOURCE OUTPUT [--include-pairs]',
    );
    exitCode = 64;
    return;
  }
  final source = Directory(p.normalize(p.absolute(arguments[0])));
  final output = Directory(p.normalize(p.absolute(arguments[1])));
  final includePairs = arguments.length == 3;
  if (!source.existsSync()) {
    throw FileSystemException(
      'Dictionary source directory is missing',
      source.path,
    );
  }
  if (output.existsSync()) output.deleteSync(recursive: true);
  output.createSync(recursive: true);

  final entries = <_Entry>[];
  final pairByFingerprint = <String, _Entry>{};
  final attributionPaths = <String>{};
  for (final packageName in selectedPackages.toList()..sort()) {
    final packageDirectory = Directory(p.join(source.path, packageName));
    final configuration = File(
      p.join(packageDirectory.path, 'dictionaries.xcu'),
    );
    if (!configuration.existsSync()) {
      throw StateError('$packageName has no dictionaries.xcu');
    }
    final document = XmlDocument.parse(configuration.readAsStringSync());
    var foundSpellingResource = false;
    for (final node in document.descendants.whereType<XmlElement>().where(
      (element) => element.name.local == 'node',
    )) {
      final properties = <String, XmlElement>{};
      for (final property in node.childElements.where(
        (element) => element.name.local == 'prop',
      )) {
        final name = _attribute(property, 'name');
        if (name != null) properties[name] = property;
      }
      if (_value(properties['Format']) != 'DICT_SPELL') continue;
      foundSpellingResource = true;
      final locations = _value(properties['Locations'])
          .split(RegExp(r'\s+'))
          .where((value) => value.isNotEmpty)
          .map((value) => value.replaceFirst('%origin%/', ''))
          .toList();
      if (locations.length != 2 ||
          !locations.any((value) => value.endsWith('.aff')) ||
          !locations.any((value) => value.endsWith('.dic'))) {
        throw StateError('Invalid DICT_SPELL pair in $packageName: $locations');
      }
      final affSource = _locate(
        packageDirectory,
        locations.singleWhere((e) => e.endsWith('.aff')),
      );
      final dicSource = _locate(
        packageDirectory,
        locations.singleWhere((e) => e.endsWith('.dic')),
      );
      final locales = _value(
        properties['Locales'],
      ).split(RegExp(r'\s+')).where((value) => value.isNotEmpty).toList();
      if (locales.isEmpty) {
        throw StateError('DICT_SPELL entry in $packageName has no locale');
      }
      final affChecksum = _checksum(affSource);
      final dicChecksum = _checksum(dicSource);
      final fingerprint = '$affChecksum:$dicChecksum';
      final duplicate = pairByFingerprint[fingerprint];
      if (duplicate != null) {
        duplicate.locales.addAll(locales);
        continue;
      }
      final id = locales.first;
      final affSourcePath = p.posix.joinAll(
        p.split(p.relative(affSource.path, from: source.path)),
      );
      final dicSourcePath = p.posix.joinAll(
        p.split(p.relative(dicSource.path, from: source.path)),
      );
      final entry = _Entry(
        resourceId: id,
        id: id,
        locales: locales.toSet(),
        label: _label(id),
        affSourcePath: affSourcePath,
        dicSourcePath: dicSourcePath,
        affSize: affSource.lengthSync(),
        dicSize: dicSource.lengthSync(),
        affChecksum: affChecksum,
        dicChecksum: dicChecksum,
        sourcePackage: packageName,
        affSource: affSource,
        dicSource: dicSource,
      );
      entries.add(entry);
      pairByFingerprint[fingerprint] = entry;
    }
    if (!foundSpellingResource) {
      throw StateError('$packageName declares no DICT_SPELL resource');
    }
    for (final entity
        in packageDirectory.listSync(recursive: true).whereType<File>()) {
      final basename = p.basename(entity.path).toLowerCase();
      if (!RegExp(r'(license|licence|copying|readme)').hasMatch(basename)) {
        continue;
      }
      final relativeInsidePackage = p.relative(
        entity.path,
        from: packageDirectory.path,
      );
      final destination = p.join(
        'licenses',
        packageName,
        relativeInsidePackage,
      );
      File(p.join(output.path, destination)).parent.createSync(recursive: true);
      entity.copySync(p.join(output.path, destination));
      attributionPaths.add(p.posix.joinAll(p.split(destination)));
    }
  }
  entries.sort((left, right) => left.label.compareTo(right.label));
  if (includePairs) {
    for (final entry in entries) {
      _publishTestInstallation(
        output: output,
        entry: entry,
        affSource: entry.affSource,
        dicSource: entry.dicSource,
      );
    }
  }
  final manifest = <String, Object?>{
    'schemaVersion': 2,
    'source': <String, Object?>{
      'name': 'LibreOffice dictionaries',
      'url': 'https://github.com/LibreOffice/dictionaries',
      'revision': sourceRevision,
      'archiveSha256':
          'cbd790eca560de5e8ec8bd64117a00dfd0bc06b091c8f52d23e44ea00d3e8461',
    },
    'dictionaries': entries.map((entry) => entry.toJson()).toList(),
    'attributions': attributionPaths.toList()..sort(),
  };
  File(p.join(output.path, 'dictionaries.json')).writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
    flush: true,
  );
  File(p.join(output.path, 'NOTICE')).writeAsStringSync(
    'LibreOffice dictionary data\nRevision: $sourceRevision\n'
    'Each dictionary remains under the terms recorded in licenses/.\n',
    flush: true,
  );
  File(
    p.join(output.path, 'VERSION'),
  ).writeAsStringSync('$sourceRevision\n', flush: true);
  final checksummedFiles =
      output
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => p.basename(file.path) != 'CHECKSUMS.sha256')
          .toList()
        ..sort((left, right) => left.path.compareTo(right.path));
  File(p.join(output.path, 'CHECKSUMS.sha256')).writeAsStringSync(
    [
      for (final file in checksummedFiles)
        '${_checksum(file)}  ${p.posix.joinAll(p.split(p.relative(file.path, from: output.path)))}',
      '',
    ].join('\n'),
    flush: true,
  );
}

String? _attribute(XmlElement element, String localName) {
  for (final attribute in element.attributes) {
    if (attribute.name.local == localName) return attribute.value;
  }
  return null;
}

String _value(XmlElement? property) {
  if (property == null) return '';
  final values = <String>[];
  for (final value in property.childElements.where(
    (element) => element.name.local == 'value',
  )) {
    final items = value.descendants
        .whereType<XmlElement>()
        .where((element) => element.name.local == 'it')
        .map((element) => element.innerText.trim())
        .where((text) => text.isNotEmpty)
        .toList();
    if (items.isNotEmpty) {
      values.addAll(items);
    } else if (value.innerText.trim() case final text when text.isNotEmpty) {
      values.add(text);
    }
  }
  return values.join(' ').trim();
}

File _locate(Directory packageDirectory, String configuredPath) {
  final direct = File(p.join(packageDirectory.path, configuredPath));
  if (direct.existsSync()) return direct;
  final basename = p.basename(configuredPath);
  final candidates = packageDirectory
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => p.basename(file.path) == basename)
      .toList();
  if (candidates.length != 1) {
    throw StateError(
      'Could not resolve $configuredPath in ${packageDirectory.path}',
    );
  }
  return candidates.single;
}

String _checksum(File file) =>
    sha256.convert(file.readAsBytesSync()).toString();

String _safeName(String value) =>
    value.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');

String _label(String locale) {
  final language = locale.split('-').first.toLowerCase();
  final name = languageNames[language] ?? language;
  return locale.contains('-') ? '$name ($locale)' : name;
}

final class _Entry {
  _Entry({
    required this.resourceId,
    required this.id,
    required this.locales,
    required this.label,
    required this.affSourcePath,
    required this.dicSourcePath,
    required this.affSize,
    required this.dicSize,
    required this.affChecksum,
    required this.dicChecksum,
    required this.sourcePackage,
    required this.affSource,
    required this.dicSource,
  });

  final String resourceId;
  final String id;
  final Set<String> locales;
  final String label;
  final String affSourcePath;
  final String dicSourcePath;
  final int affSize;
  final int dicSize;
  final String affChecksum;
  final String dicChecksum;
  final String sourcePackage;
  final File affSource;
  final File dicSource;

  Map<String, Object?> toJson() => <String, Object?>{
    'resourceId': resourceId,
    'id': id,
    'locales': locales.toList()..sort(),
    'label': label,
    'affSourcePath': affSourcePath,
    'dicSourcePath': dicSourcePath,
    'affDownloadUrl':
        'https://raw.githubusercontent.com/LibreOffice/dictionaries/'
        '$sourceRevision/$affSourcePath',
    'dicDownloadUrl':
        'https://raw.githubusercontent.com/LibreOffice/dictionaries/'
        '$sourceRevision/$dicSourcePath',
    'affSize': affSize,
    'dicSize': dicSize,
    'sourceRevision': sourceRevision,
    'affSha256': affChecksum,
    'dicSha256': dicChecksum,
    'licenseDirectory': 'licenses/$sourcePackage',
  };
}

void _publishTestInstallation({
  required Directory output,
  required _Entry entry,
  required File affSource,
  required File dicSource,
}) {
  final relativeDirectory = p.join('installed', _safeName(entry.resourceId));
  final directory = Directory(p.join(output.path, relativeDirectory))
    ..createSync(recursive: true);
  affSource.copySync(p.join(directory.path, 'dictionary.aff'));
  dicSource.copySync(p.join(directory.path, 'dictionary.dic'));
  final manifest = <String, Object?>{
    'schemaVersion': 1,
    'kind': 'downloaded',
    'resourceId': entry.resourceId,
    'id': entry.id,
    'locales': entry.locales.toList()..sort(),
    'label': entry.label,
    'sourceRevision': sourceRevision,
    'affPath': 'dictionary.aff',
    'dicPath': 'dictionary.dic',
    'affSha256': entry.affChecksum,
    'dicSha256': entry.dicChecksum,
  };
  File(p.join(directory.path, 'manifest.json')).writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
    flush: true,
  );
}
