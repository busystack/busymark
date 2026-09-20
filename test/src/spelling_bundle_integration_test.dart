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
      final catalog = await SpellingDictionaryCatalog.load(bundledRoot: root!);
      expect(catalog.unavailableEntries, isEmpty);
      expect(catalog.entries, hasLength(48));

      final us = _open(catalog, 'en-US');
      final gb = _open(catalog, 'en-GB');
      final russian = _open(catalog, 'ru-RU');
      final hindi = _open(catalog, 'hi-IN');
      try {
        expect(us.encoding, isNotEmpty);
        expect(us.check('color'), NativeSpellResult.accepted);
        expect(us.check('helo'), NativeSpellResult.rejected);
        expect(us.suggest('helo'), contains('hello'));
        expect(gb.check('colour'), NativeSpellResult.accepted);
        expect(russian.check('ЧПУ'), NativeSpellResult.accepted);
        expect(hindi.check('ढूंढेगा'), NativeSpellResult.accepted);
      } finally {
        us.close();
        gb.close();
        russian.close();
        hindi.close();
      }
    },
    skip: unavailable ? 'Prepared spelling bundle is not available.' : false,
  );
}

NativeSpellDictionary _open(SpellingDictionaryCatalog catalog, String id) {
  final entry = catalog.byId(id)!;
  return NativeSpellDictionary.open(
    affPath: entry.affPath,
    dicPath: entry.dicPath,
  );
}
