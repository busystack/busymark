import 'dart:convert';

enum DocumentLineEnding { none, lf, crlf, mixed }

enum LineEndingNormalization { lf, crlf }

class MixedLineEndingNormalizationRequired implements Exception {
  const MixedLineEndingNormalizationRequired();

  @override
  String toString() =>
      'A document with mixed line endings must be normalized before saving.';
}

class TextFormatMetadata {
  const TextFormatMetadata({
    required this.hasUtf8Bom,
    required this.lineEnding,
    required this.hasFinalNewline,
    this.lfCount = 0,
    this.crlfCount = 0,
    this.crCount = 0,
  });

  static const utf8Lf = TextFormatMetadata(
    hasUtf8Bom: false,
    lineEnding: DocumentLineEnding.lf,
    hasFinalNewline: false,
  );

  final bool hasUtf8Bom;
  final DocumentLineEnding lineEnding;
  final bool hasFinalNewline;
  final int lfCount;
  final int crlfCount;
  final int crCount;

  bool get hasMixedLineEndings => lineEnding == DocumentLineEnding.mixed;

  TextFormatMetadata copyWith({
    bool? hasUtf8Bom,
    DocumentLineEnding? lineEnding,
    bool? hasFinalNewline,
    int? lfCount,
    int? crlfCount,
    int? crCount,
  }) {
    return TextFormatMetadata(
      hasUtf8Bom: hasUtf8Bom ?? this.hasUtf8Bom,
      lineEnding: lineEnding ?? this.lineEnding,
      hasFinalNewline: hasFinalNewline ?? this.hasFinalNewline,
      lfCount: lfCount ?? this.lfCount,
      crlfCount: crlfCount ?? this.crlfCount,
      crCount: crCount ?? this.crCount,
    );
  }

  String get statusLabel => switch (lineEnding) {
    DocumentLineEnding.none || DocumentLineEnding.lf => 'LF',
    DocumentLineEnding.crlf => 'CRLF',
    DocumentLineEnding.mixed => 'Mixed',
  };

  TextFormatMetadata normalized(LineEndingNormalization normalization) {
    return TextFormatMetadata(
      hasUtf8Bom: hasUtf8Bom,
      lineEnding: switch (normalization) {
        LineEndingNormalization.lf => DocumentLineEnding.lf,
        LineEndingNormalization.crlf => DocumentLineEnding.crlf,
      },
      hasFinalNewline: hasFinalNewline,
      lfCount: normalization == LineEndingNormalization.lf
          ? lfCount + crlfCount + crCount
          : 0,
      crlfCount: normalization == LineEndingNormalization.crlf
          ? lfCount + crlfCount + crCount
          : 0,
    );
  }

  List<int> encode(
    String canonicalText, {
    LineEndingNormalization? mixedNormalization,
  }) {
    return utf8.encode(
      formattedText(canonicalText, mixedNormalization: mixedNormalization),
    );
  }

  String formattedText(
    String canonicalText, {
    LineEndingNormalization? mixedNormalization,
  }) {
    var effective = this;
    if (hasMixedLineEndings) {
      if (mixedNormalization == null) {
        throw const MixedLineEndingNormalizationRequired();
      }
      effective = normalized(mixedNormalization);
    }
    var text = canonicalText.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    if (effective.hasFinalNewline) {
      if (!text.endsWith('\n')) {
        text = '$text\n';
      }
    } else {
      text = text.replaceFirst(RegExp(r'\n+$'), '');
    }
    if (effective.lineEnding == DocumentLineEnding.crlf) {
      text = text.replaceAll('\n', '\r\n');
    }
    return effective.hasUtf8Bom ? '\uFEFF$text' : text;
  }

  Map<String, Object?> toJson() => {
    'hasUtf8Bom': hasUtf8Bom,
    'lineEnding': lineEnding.name,
    'hasFinalNewline': hasFinalNewline,
    'lfCount': lfCount,
    'crlfCount': crlfCount,
    'crCount': crCount,
  };

  factory TextFormatMetadata.fromJson(Map<String, Object?> json) {
    return TextFormatMetadata(
      hasUtf8Bom: json['hasUtf8Bom'] as bool? ?? false,
      lineEnding: DocumentLineEnding.values.firstWhere(
        (value) => value.name == json['lineEnding'],
        orElse: () => DocumentLineEnding.lf,
      ),
      hasFinalNewline: json['hasFinalNewline'] as bool? ?? false,
      lfCount: (json['lfCount'] as num?)?.toInt() ?? 0,
      crlfCount: (json['crlfCount'] as num?)?.toInt() ?? 0,
      crCount: (json['crCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class DecodedUtf8Document {
  const DecodedUtf8Document({required this.text, required this.format});

  final String text;
  final TextFormatMetadata format;
}

DecodedUtf8Document decodeUtf8Document(List<int> bytes) {
  final hasBom =
      bytes.length >= 3 &&
      bytes[0] == 0xef &&
      bytes[1] == 0xbb &&
      bytes[2] == 0xbf;
  final decoded = utf8.decode(hasBom ? bytes.sublist(3) : bytes);
  var lf = 0;
  var crlf = 0;
  var cr = 0;
  for (var index = 0; index < decoded.length; index++) {
    final unit = decoded.codeUnitAt(index);
    if (unit == 13) {
      if (index + 1 < decoded.length && decoded.codeUnitAt(index + 1) == 10) {
        crlf++;
        index++;
      } else {
        cr++;
      }
    } else if (unit == 10) {
      lf++;
    }
  }
  final styles = [if (lf > 0) 'lf', if (crlf > 0) 'crlf', if (cr > 0) 'cr'];
  final lineEnding = styles.isEmpty
      ? DocumentLineEnding.none
      : styles.length > 1 || cr > 0
      ? DocumentLineEnding.mixed
      : crlf > 0
      ? DocumentLineEnding.crlf
      : DocumentLineEnding.lf;
  return DecodedUtf8Document(
    text: decoded.replaceAll('\r\n', '\n').replaceAll('\r', '\n'),
    format: TextFormatMetadata(
      hasUtf8Bom: hasBom,
      lineEnding: lineEnding,
      hasFinalNewline: decoded.endsWith('\n') || decoded.endsWith('\r'),
      lfCount: lf,
      crlfCount: crlf,
      crCount: cr,
    ),
  );
}
