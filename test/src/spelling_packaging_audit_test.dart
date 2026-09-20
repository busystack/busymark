import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shipped spelling catalog is metadata-only and revision pinned', () {
    final root = Directory('assets/spelling');
    final dictionaryFiles = root
        .listSync(recursive: true)
        .whereType<File>()
        .where(
          (file) => file.path.endsWith('.aff') || file.path.endsWith('.dic'),
        );
    expect(dictionaryFiles, isEmpty);
    expect(File('${root.path}/NOTICE').existsSync(), isTrue);
    expect(Directory('${root.path}/licenses').existsSync(), isTrue);

    final manifest =
        jsonDecode(File('${root.path}/dictionaries.json').readAsStringSync())
            as Map<String, Object?>;
    expect(manifest['schemaVersion'], 2);
    final source = (manifest['source'] as Map).cast<String, Object?>();
    const revision = '32b006a2c22a4ac7e8ed3f03346f7b3d85a970a4';
    expect(source['revision'], revision);
    final dictionaries = (manifest['dictionaries'] as List).cast<Map>();
    expect(dictionaries, hasLength(48));
    final resourceIds = <String>{};
    for (final raw in dictionaries) {
      final entry = raw.cast<String, Object?>();
      expect(resourceIds.add(entry['resourceId']! as String), isTrue);
      expect(entry.containsKey('affPath'), isFalse);
      expect(entry.containsKey('dicPath'), isFalse);
      expect(entry['affSourcePath'], isNotEmpty);
      expect(entry['dicSourcePath'], isNotEmpty);
      expect(
        entry['affSize'],
        isA<int>().having((value) => value, 'size', isPositive),
      );
      expect(
        entry['dicSize'],
        isA<int>().having((value) => value, 'size', isPositive),
      );
      expect(entry['affSha256'].toString(), hasLength(64));
      expect(entry['dicSha256'].toString(), hasLength(64));
      expect(
        entry['affDownloadUrl'].toString(),
        startsWith(
          'https://raw.githubusercontent.com/LibreOffice/dictionaries/'
          '$revision/',
        ),
      );
      expect(
        entry['dicDownloadUrl'].toString(),
        startsWith(
          'https://raw.githubusercontent.com/LibreOffice/dictionaries/'
          '$revision/',
        ),
      );
    }
  });

  test('ordinary Linux release does not prepare all-language pairs', () {
    final cmake = File('linux/CMakeLists.txt').readAsStringSync();
    expect(cmake, isNot(contains('add_custom_target(busymark_spelling ALL')));
    expect(cmake, isNot(contains('fetch_spelling_dictionaries.sh')));
    expect(cmake, contains('../assets/spelling/'));
    expect(cmake, contains('PATTERN "*.aff" EXCLUDE'));
    expect(cmake, contains('PATTERN "*.dic" EXCLUDE'));

    final snapcraft = File('snap/snapcraft.yaml').readAsStringSync();
    expect(
      snapcraft,
      contains(
        r'BUSYMARK_SPELLING_INSTALL_ROOT: $SNAP_USER_COMMON/spelling/dictionaries',
      ),
    );
  });
}
