import 'dart:io';

import 'package:busymark_spellcheck_native/busymark_spellcheck_native.dart';
import 'package:test/test.dart';

void main() {
  late NativeSpellDictionary dictionary;

  String fixturePath(String name) {
    final local = File('test/fixtures/$name');
    if (local.existsSync()) return local.absolute.path;
    return File(
      'packages/busymark_spellcheck_native/test/fixtures/$name',
    ).absolute.path;
  }

  setUp(() {
    dictionary = NativeSpellDictionary.open(
      affPath: fixturePath('test.aff'),
      dicPath: fixturePath('test.dic'),
    );
  });

  tearDown(() => dictionary.close());

  test('checks roots, affixes, compounds, and casing', () {
    expect(dictionary.encoding, 'UTF-8');
    expect(dictionary.check('hello'), NativeSpellResult.accepted);
    expect(dictionary.check('hellos'), NativeSpellResult.accepted);
    expect(dictionary.check('sunflower'), NativeSpellResult.accepted);
    expect(dictionary.check('BusyMark'), NativeSpellResult.accepted);
    expect(dictionary.check('busymark'), NativeSpellResult.rejected);
    expect(dictionary.check('helo'), NativeSpellResult.rejected);
  });

  test('copies suggestions before releasing the Hunspell list', () {
    expect(dictionary.suggest('helo'), contains('hello'));
  });

  test('custom words participate in checking and suggestions', () {
    expect(dictionary.check('busystack'), NativeSpellResult.rejected);
    dictionary.add('busystack');
    expect(dictionary.check('busystack'), NativeSpellResult.accepted);
    expect(dictionary.suggest('busystak'), contains('busystack'));
  });

  test('tokenization reports UTF-8 and character boundaries separately', () {
    const prose = '😀 helo café don’t state-of-the-art';
    final ranges = dictionary.tokenize(prose, language: 'en-US');
    final utf16 = nativeUtf8BoundaryToUtf16(prose);
    final words = [
      for (final range in ranges)
        prose.substring(utf16[range.utf8Start], utf16[range.utf8End]),
    ];
    expect(words, ['helo', 'café', 'don’t', 'state-of-the-art']);
  });

  test('dictionary word characters do not absorb quotation punctuation', () {
    const prose =
        "C++ C# +lead trail# -dash dash- 'quoted' ‘curly’ -hyphen- "
        "don't ’tis dogs’ café";
    final ranges = dictionary.tokenize(prose, language: 'en-US');
    final utf16 = nativeUtf8BoundaryToUtf16(prose);
    final words = [
      for (final range in ranges)
        prose.substring(utf16[range.utf8Start], utf16[range.utf8End]),
    ];

    expect(words, [
      'C++',
      'C#',
      '+lead',
      'trail#',
      '-dash',
      'dash-',
      'quoted',
      'curly',
      '-hyphen-',
      "don't",
      '’tis',
      'dogs’',
      'café',
    ]);
    expect(dictionary.check('C++'), NativeSpellResult.accepted);
    expect(dictionary.check('C#'), NativeSpellResult.accepted);
    expect(dictionary.check('-dash'), NativeSpellResult.accepted);
    expect(dictionary.check('dash-'), NativeSpellResult.accepted);
  });

  test('closed handles report an unchecked failure', () {
    dictionary.close();
    expect(
      () => dictionary.check('word'),
      throwsA(isA<NativeSpellException>()),
    );
  });

  test('missing dictionary is reported without leaking a handle', () {
    expect(
      () => NativeSpellDictionary.open(
        affPath: '/missing/test.aff',
        dicPath: '/missing/test.dic',
      ),
      throwsA(isA<NativeSpellException>()),
    );
  });

  test('rejects a dictionary that claims records but loads none', () async {
    final temporary = await Directory.systemTemp.createTemp(
      'busymark-empty-dictionary-',
    );
    addTearDown(() => temporary.delete(recursive: true));
    final aff = File('${temporary.path}/empty.aff');
    final dic = File('${temporary.path}/empty.dic');
    await aff.writeAsString('SET UTF-8\n');
    await dic.writeAsString('1\n');

    expect(
      () => NativeSpellDictionary.open(affPath: aff.path, dicPath: dic.path),
      throwsA(
        isA<NativeSpellException>().having(
          (error) => error.message,
          'message',
          contains('no records'),
        ),
      ),
    );
  });

  test('accepts a valid dictionary whose stems require affixes', () async {
    final temporary = await Directory.systemTemp.createTemp(
      'busymark-need-affix-dictionary-',
    );
    addTearDown(() => temporary.delete(recursive: true));
    final aff = File('${temporary.path}/need-affix.aff');
    final dic = File('${temporary.path}/need-affix.dic');
    await aff.writeAsString('''SET UTF-8
NEEDAFFIX X
SFX S Y 1
SFX S 0 s .
''');
    await dic.writeAsString('1\ncat/XS\n');

    final affixOnly = NativeSpellDictionary.open(
      affPath: aff.path,
      dicPath: dic.path,
    );
    addTearDown(affixOnly.close);
    expect(affixOnly.check('cat'), NativeSpellResult.rejected);
    expect(affixOnly.check('cats'), NativeSpellResult.accepted);
  });
}
