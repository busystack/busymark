import 'dart:io';

import 'package:busymark/src/spellcheck/spelling_catalog.dart';
import 'package:busymark_spellcheck_native/busymark_spellcheck_native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final root = Platform.environment['BUSYMARK_TEST_SPELLING_ROOT'];
  final unavailable =
      root == null || !File('$root/dictionaries.json').existsSync();

  test(
    'packaged catalog opens real regional and non-Latin dictionaries',
    () async {
      final catalog = await SpellingDictionaryCatalog.load(
        bundledRoot: root!,
        downloadedRoot: '$root/installed',
      );
      expect(catalog.unavailableEntries, isEmpty);
      expect(catalog.availableEntries, hasLength(48));
      expect(catalog.installations, hasLength(48));

      for (final resource in catalog.availableEntries) {
        final installation = catalog.installationForResource(
          resource.resourceId,
        );
        expect(installation, isNotNull, reason: resource.resourceId);
        late final NativeSpellDictionary dictionary;
        try {
          dictionary = NativeSpellDictionary.open(
            affPath: installation!.affPath,
            dicPath: installation.dicPath,
          );
        } on Object catch (error) {
          fail('${resource.resourceId} failed native validation: $error');
        }
        try {
          expect(dictionary.encoding, isNotEmpty, reason: resource.resourceId);
          expect(
            dictionary.check(resource.knownValidProbe),
            NativeSpellResult.accepted,
            reason: '${resource.resourceId}: ${resource.knownValidProbe}',
          );
        } finally {
          dictionary.close();
        }
      }

      final us = _open(catalog, 'en-US');
      try {
        expect(us.check('color'), NativeSpellResult.accepted);
        expect(us.check('helo'), NativeSpellResult.rejected);
        expect(us.suggest('helo'), contains('hello'));
      } finally {
        us.close();
      }
    },
    skip: unavailable ? 'Prepared spelling bundle is not available.' : false,
  );
}

NativeSpellDictionary _open(SpellingDictionaryCatalog catalog, String id) {
  final entry = catalog.installedById(id)!;
  return NativeSpellDictionary.open(
    affPath: entry.affPath,
    dicPath: entry.dicPath,
  );
}
