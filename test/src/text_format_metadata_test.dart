import 'dart:convert';

import 'package:busymark/src/workspace/text_format_metadata.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('detects and preserves UTF-8 BOM, CRLF, and final newline', () {
    final bytes = <int>[0xef, 0xbb, 0xbf, ...utf8.encode('one\r\ntwo\r\n')];

    final decoded = decodeUtf8Document(bytes);

    expect(decoded.text, 'one\ntwo\n');
    expect(decoded.format.hasUtf8Bom, isTrue);
    expect(decoded.format.lineEnding, DocumentLineEnding.crlf);
    expect(decoded.format.hasFinalNewline, isTrue);
    expect(decoded.format.encode(decoded.text), bytes);
  });

  test('preserves a missing final newline when saving edited text', () {
    final decoded = decodeUtf8Document(utf8.encode('one\ntwo'));

    expect(decoded.format.hasFinalNewline, isFalse);
    expect(
      utf8.decode(decoded.format.encode('changed\ntext\n')),
      'changed\ntext',
    );
  });

  test('requires an explicit normalization for mixed line endings', () {
    final decoded = decodeUtf8Document(utf8.encode('one\r\ntwo\nthree'));

    expect(decoded.format.lineEnding, DocumentLineEnding.mixed);
    expect(
      () => decoded.format.encode(decoded.text),
      throwsA(isA<MixedLineEndingNormalizationRequired>()),
    );
    expect(
      utf8.decode(
        decoded.format.encode(
          decoded.text,
          mixedNormalization: LineEndingNormalization.crlf,
        ),
      ),
      'one\r\ntwo\r\nthree',
    );
  });

  test('rejects invalid UTF-8 instead of replacing bytes', () {
    expect(
      () => decodeUtf8Document(const [0xc3, 0x28]),
      throwsA(isA<FormatException>()),
    );
  });
}
