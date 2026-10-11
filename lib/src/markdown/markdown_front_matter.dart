import 'dart:convert';

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

/// Writerside publishes switcher front matter as literal text. Adding YAML
/// single quotes changes the published label, so ordinary labels stay unquoted.
String encodeWritersideSwitcherLabel(String value) {
  if (value.trim() != value ||
      RegExp(r'[\x00-\x1f\x7f]').hasMatch(value) ||
      value.startsWith('"') && value.endsWith('"') ||
      value.startsWith("'") && value.endsWith("'")) {
    return jsonEncode(value);
  }
  return value;
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
  return scalar;
}
