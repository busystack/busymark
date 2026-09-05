/// Source selection operates on original text, with comments and strings masked
/// only while locating declarations and balancing their delimiters.
class WritersideCodeSelection {
  const WritersideCodeSelection();

  String select(String source, Map<String, String> attributes) {
    final lines = attributes['include-lines'];
    final symbol = attributes['include-symbol'];
    if (lines != null && symbol != null) {
      throw const FormatException('conflicting-selection');
    }
    if (lines != null) {
      final input = source.replaceAll('\r\n', '\n').split('\n');
      if (input.last.isEmpty) input.removeLast();
      final selected = <String>[];
      for (final part in lines.split(',')) {
        final range = RegExp(
          r'^\s*(\d+)(?:\s*-\s*(\d+))?\s*$',
        ).firstMatch(part);
        if (range == null) throw const FormatException('invalid-lines');
        final first = int.parse(range[1]!);
        final last = int.parse(range[2] ?? range[1]!);
        if (first < 1 || last < first || last > input.length) {
          throw const FormatException('invalid-lines');
        }
        selected.addAll(input.sublist(first - 1, last));
      }
      return selected.join('\n');
    }
    if (symbol == null) return source;
    if (symbol.contains('.')) {
      final parts = symbol.split('.');
      var selected = source;
      for (final part in parts) {
        selected = select(selected, {...attributes, 'include-symbol': part});
      }
      return selected;
    }
    final language = (attributes['lang'] ?? attributes['language'] ?? '')
        .toLowerCase();
    if (language == 'python' || language == 'py') {
      return _python(source, symbol);
    }
    if (!{
      'java',
      'kotlin',
      'kt',
      'javascript',
      'js',
      'typescript',
      'ts',
      'jsx',
      'tsx',
      'dart',
      'c',
      'cpp',
      'c++',
      'csharp',
      'c#',
      'cs',
      'go',
      'rust',
      'rs',
      'swift',
      'php',
    }.contains(language)) {
      throw FormatException('unsupported-symbol-language: $language');
    }
    return _braced(source, symbol);
  }

  String _python(String source, String symbol) {
    final lines = source.split('\n');
    final name = RegExp.escape(symbol.split('.').last);
    final declaration = RegExp(
      '^(\\s*)(?:async\\s+)?(?:def|class)\\s+$name\\b',
    );
    final matches = <int>[];
    for (var i = 0; i < lines.length; i++) {
      if (declaration.hasMatch(lines[i])) matches.add(i);
    }
    if (matches.length != 1) {
      throw const FormatException('missing-or-ambiguous-symbol');
    }
    var start = matches.single;
    final indent = declaration.firstMatch(lines[start])![1]!.length;
    var end = start + 1;
    while (end < lines.length) {
      final line = lines[end];
      if (line.trim().isNotEmpty &&
          line.length - line.trimLeft().length <= indent) {
        break;
      }
      end++;
    }
    while (start > 0 && lines[start - 1].trimLeft().startsWith('@')) {
      start--;
    }
    return lines.sublist(start, end).join('\n').trimRight();
  }

  String _braced(String source, String symbol) {
    final masked = _mask(source);
    final name = RegExp.escape(symbol.split('.').last);
    final candidate = RegExp('\\b$name\\s*(?:<[^;{}]*>)?\\s*\\(');
    final matches = <(int, int)>[];
    for (final match in candidate.allMatches(masked)) {
      final lineStart = masked.lastIndexOf('\n', match.start) + 1;
      final prefix = masked.substring(lineStart, match.start).trim();
      // Calls and control flow are not declarations. A bare method name is
      // accepted for JavaScript/TypeScript class methods.
      if (prefix.contains('=') ||
          prefix.contains('.') ||
          prefix.contains('(') ||
          RegExp(r'\b(return|throw|new|await)\b').hasMatch(prefix)) {
        continue;
      }
      var cursor = masked.indexOf('(', match.start);
      var depth = 0;
      do {
        if (masked[cursor] == '(') depth++;
        if (masked[cursor] == ')') depth--;
        cursor++;
      } while (cursor < masked.length && depth > 0);
      final body = masked.indexOf('{', cursor);
      final terminator = masked.indexOf(';', cursor);
      final expression = masked.indexOf('=', cursor);
      if (body < 0 ||
          (terminator >= 0 && terminator < body) ||
          (expression >= 0 && expression < body)) {
        continue;
      }
      final between = masked.substring(cursor, body);
      if (between.contains('(') || between.contains('}')) continue;
      matches.add((lineStart, _closingBrace(masked, body)));
    }
    final typePattern = RegExp(
      '\\b(?:class|interface|enum|struct|object|trait)\\s+$name\\b[^;{]*\\{',
    );
    for (final match in typePattern.allMatches(masked)) {
      matches.add((
        masked.lastIndexOf('\n', match.start) + 1,
        _closingBrace(masked, match.end - 1),
      ));
    }
    if (matches.length != 1) {
      throw const FormatException('missing-or-ambiguous-symbol');
    }
    var (start, end) = matches.single;
    while (start > 0) {
      final previous = source.lastIndexOf('\n', start - 2) + 1;
      if (!source.substring(previous, start).trimLeft().startsWith('@')) break;
      start = previous;
    }
    return source.substring(start, end).trimRight();
  }

  int _closingBrace(String source, int start) {
    var depth = 0;
    for (var i = start; i < source.length; i++) {
      if (source[i] == '{') depth++;
      if (source[i] == '}' && --depth == 0) return i + 1;
    }
    throw const FormatException('unclosed-symbol');
  }

  String _mask(String source) {
    final result = source.split('');
    var i = 0;
    while (i < source.length) {
      final start = i;
      if (source.startsWith('//', i)) {
        while (i < source.length && source[i] != '\n') {
          i++;
        }
      } else if (source.startsWith('/*', i)) {
        final end = source.indexOf('*/', i + 2);
        i = end < 0 ? source.length : end + 2;
      } else if ('\'"`'.contains(source[i])) {
        final quote = source[i++];
        while (i < source.length) {
          if (source[i] == '\\') {
            i = (i + 2).clamp(0, source.length);
            continue;
          }
          if (source[i++] == quote) break;
        }
      } else {
        i++;
        continue;
      }
      for (var j = start; j < i; j++) {
        if (result[j] != '\n' && result[j] != '\r') result[j] = ' ';
      }
    }
    return result.join();
  }
}
