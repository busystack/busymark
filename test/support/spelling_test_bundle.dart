import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

Future<String> createSpellingTestBundle(Directory temporary) async {
  final fixture = p.join(
    Directory.current.path,
    'packages',
    'busymark_spellcheck_native',
    'test',
    'fixtures',
  );
  final bundle = Directory(p.join(temporary.path, 'bundle'));
  await bundle.create(recursive: true);
  final sourceAff = File(p.join(fixture, 'test.aff'));
  final sourceDic = File(p.join(fixture, 'test.dic'));
  final affChecksum = await sha256.bind(sourceAff.openRead()).first;
  final dicChecksum = await sha256.bind(sourceDic.openRead()).first;
  await File(p.join(bundle.path, 'dictionaries.json')).writeAsString(
    jsonEncode({
      'schemaVersion': 2,
      'dictionaries': [
        {
          'resourceId': 'en-Test',
          'id': 'en-Test',
          'knownValidProbe': 'hello',
          'locales': ['en-Test'],
          'label': 'Test English',
          'affSourcePath': 'test/test.aff',
          'dicSourcePath': 'test/test.dic',
          'affDownloadUrl': 'https://example.invalid/test.aff',
          'dicDownloadUrl': 'https://example.invalid/test.dic',
          'affSize': await sourceAff.length(),
          'dicSize': await sourceDic.length(),
          'sourceRevision': 'fixture',
          'affSha256': affChecksum.toString(),
          'dicSha256': dicChecksum.toString(),
        },
      ],
    }),
  );
  final installed = Directory(
    p.join(temporary.path, 'dictionary-storage', 'downloaded', 'en-Test'),
  );
  await installed.create(recursive: true);
  await sourceAff.copy(p.join(installed.path, 'dictionary.aff'));
  await sourceDic.copy(p.join(installed.path, 'dictionary.dic'));
  await File(p.join(installed.path, 'manifest.json')).writeAsString(
    jsonEncode({
      'schemaVersion': 1,
      'kind': 'downloaded',
      'resourceId': 'en-Test',
      'id': 'en-Test',
      'locales': ['en-Test'],
      'label': 'Test English',
      'sourceRevision': 'fixture',
      'affPath': 'dictionary.aff',
      'dicPath': 'dictionary.dic',
      'affSha256': affChecksum.toString(),
      'dicSha256': dicChecksum.toString(),
    }),
  );
  return bundle.path;
}
