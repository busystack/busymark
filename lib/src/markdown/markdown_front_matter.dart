import 'dart:convert';
import 'package:xml/xml.dart';

import 'math_syntax.dart';

/// Supported metadata delimiters occupy an entire line. Horizontal whitespace
/// and CRLF are accepted, but prefixes such as `---example` are ordinary text.
final _delimiter = RegExp(r'^---[ \t]*\r?$', multiLine: true);

bool hasFrontMatterOpening(String source) =>
    _delimiter.matchAsPrefix(source) != null;

RegExpMatch? frontMatterClosing(String source) {
  if (!hasFrontMatterOpening(source)) return null;
  return _delimiter.allMatches(source).skip(1).firstOrNull;
}

int frontMatterEndOffset(String source) {
  final closing = frontMatterClosing(source);
  if (closing == null) return 0;
  return closing.end < source.length && source[closing.end] == '\n'
      ? closing.end + 1
      : closing.end;
}

/// The pinned builder inserts this literal into an XML attribute. YAML/JSON
/// quoting does not escape its quotes; XML entities preserve the actual label.
String encodeWritersideSwitcherLabel(String value) {
  return busyMarkEncodeXmlMathText(value)
      .replaceAll('"', '&quot;')
      .replaceAll('\n', '&#10;')
      .replaceAll('\r', '&#13;')
      .replaceAll('\t', '&#9;')
      .replaceAllMapped(RegExp(r'^ +| +$'), (m) => '&#32;' * m[0]!.length);
}

/// Decode only the topic switcher scalar; other metadata and the authored
/// front-matter source retain their existing handling.
String decodeWritersideSwitcherLabel(String scalar) {
  if (scalar.length < 2) return scalar;
  if (scalar.startsWith("'") && scalar.endsWith("'")) {
    return scalar.substring(1, scalar.length - 1).replaceAll("''", "'");
  }
  if (scalar.startsWith('"') && scalar.endsWith('"')) {
    try {
      return jsonDecode(scalar) as String;
    } on FormatException {
      // Keep the existing display behavior for YAML escape forms outside the
      // scalar subset emitted by the authoring control. Source stays intact.
      return scalar.substring(1, scalar.length - 1);
    }
  }
  try {
    return XmlDocumentFragment.parse(scalar).innerText;
  } on XmlParserException {
    return scalar;
  }
}
