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
