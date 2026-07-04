import 'source_document.dart';

class SourceSearchOptions {
  const SourceSearchOptions({
    this.query = '',
    this.caseSensitive = false,
    this.wholeWord = false,
    this.regex = false,
  });

  final String query;
  final bool caseSensitive;
  final bool wholeWord;
  final bool regex;

  SourceSearchOptions copyWith({
    String? query,
    bool? caseSensitive,
    bool? wholeWord,
    bool? regex,
  }) {
    return SourceSearchOptions(
      query: query ?? this.query,
      caseSensitive: caseSensitive ?? this.caseSensitive,
      wholeWord: wholeWord ?? this.wholeWord,
      regex: regex ?? this.regex,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SourceSearchOptions &&
        other.query == query &&
        other.caseSensitive == caseSensitive &&
        other.wholeWord == wholeWord &&
        other.regex == regex;
  }

  @override
  int get hashCode => Object.hash(query, caseSensitive, wholeWord, regex);
}

class SourceSearchMatch {
  const SourceSearchMatch({
    required this.fullStart,
    required this.fullEnd,
    required this.visibleStart,
    required this.visibleEnd,
    required this.hidden,
  });

  final int fullStart;
  final int fullEnd;
  final int visibleStart;
  final int visibleEnd;
  final bool hidden;

  int get length => fullEnd - fullStart;
}

class SourceSearchResult {
  const SourceSearchResult({
    required this.options,
    required this.matches,
    this.currentMatchIndex,
    this.invalidRegex = false,
  });

  static const empty = SourceSearchResult(
    options: SourceSearchOptions(),
    matches: [],
  );

  final SourceSearchOptions options;
  final List<SourceSearchMatch> matches;
  final int? currentMatchIndex;
  final bool invalidRegex;

  int get totalMatchCount => matches.length;

  SourceSearchMatch? get currentMatch {
    final index = currentMatchIndex;
    if (index == null || index < 0 || index >= matches.length) {
      return null;
    }
    return matches[index];
  }

  SourceSearchResult copyWith({int? currentMatchIndex}) {
    return SourceSearchResult(
      options: options,
      matches: matches,
      currentMatchIndex: currentMatchIndex,
      invalidRegex: invalidRegex,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SourceSearchResult &&
        other.options == options &&
        other.currentMatchIndex == currentMatchIndex &&
        other.invalidRegex == invalidRegex &&
        _matchesEqual(other.matches, matches);
  }

  @override
  int get hashCode => Object.hash(
    options,
    currentMatchIndex,
    invalidRegex,
    Object.hashAll(matches.map(_matchHash)),
  );
}

class SourceSearchController {
  SourceSearchController({
    SourceSearchOptions options = const SourceSearchOptions(),
  }) : _options = options;

  SourceSearchOptions _options;
  SourceSearchResult _result = SourceSearchResult.empty;
  var _version = 0;

  SourceSearchOptions get options => _options;

  SourceSearchResult get result => _result;

  int get version => _version;

  void setOptions(SourceSearchOptions options, SourceDocument document) {
    _options = options;
    refresh(document);
  }

  void refresh(SourceDocument document) {
    _version++;
    _result = searchSourceDocument(document, _options);
  }

  void refreshCurrent(SourceDocument document) {
    final current = _result.currentMatchIndex;
    _version++;
    _result = searchSourceDocument(
      document,
      _options,
      currentMatchIndex: current,
    );
  }

  void setCurrentMatchIndex(int? index) {
    final safeIndex =
        index != null && index >= 0 && index < _result.matches.length
        ? index
        : null;
    _result = _result.copyWith(currentMatchIndex: safeIndex);
  }

  SourceSearchMatch? next(SourceDocument document) {
    if (_result.options != _options) {
      refresh(document);
    }
    if (_result.matches.isEmpty) {
      _result = _result.copyWith(currentMatchIndex: null);
      return null;
    }
    final nextIndex = _result.currentMatchIndex == null
        ? 0
        : (_result.currentMatchIndex! + 1) % _result.matches.length;
    _result = _result.copyWith(currentMatchIndex: nextIndex);
    return _result.currentMatch;
  }

  SourceSearchMatch? previous(SourceDocument document) {
    if (_result.options != _options) {
      refresh(document);
    }
    if (_result.matches.isEmpty) {
      _result = _result.copyWith(currentMatchIndex: null);
      return null;
    }
    final previousIndex = _result.currentMatchIndex == null
        ? _result.matches.length - 1
        : (_result.currentMatchIndex! - 1 + _result.matches.length) %
              _result.matches.length;
    _result = _result.copyWith(currentMatchIndex: previousIndex);
    return _result.currentMatch;
  }

  void discardIfStale(int documentVersion, int resultVersion) {
    if (resultVersion < documentVersion) {
      _result = SourceSearchResult(options: _options, matches: const []);
    }
  }
}

class SourceWorkspaceSearchFileResult {
  const SourceWorkspaceSearchFileResult({
    required this.filePath,
    required this.matches,
  });

  final String filePath;
  final List<SourceSearchMatch> matches;
}

List<SourceWorkspaceSearchFileResult> searchWorkspaceSources({
  required Map<String, String> files,
  required SourceSearchOptions options,
  int maxFiles = 80,
}) {
  final results = <SourceWorkspaceSearchFileResult>[];
  final sortedPaths = files.keys.toList()..sort();
  for (final path in sortedPaths) {
    if (!_isAuthoringContentPath(path)) {
      continue;
    }
    final document = SourceDocument(fullText: files[path]!);
    final result = searchSourceDocument(document, options);
    if (result.matches.isEmpty) {
      continue;
    }
    results.add(
      SourceWorkspaceSearchFileResult(filePath: path, matches: result.matches),
    );
    if (results.length >= maxFiles) {
      break;
    }
  }
  return List.unmodifiable(results);
}

SourceSearchResult searchSourceDocument(
  SourceDocument document,
  SourceSearchOptions options, {
  int? currentMatchIndex,
}) {
  final query = options.query;
  if (query.isEmpty) {
    return SourceSearchResult(options: options, matches: const []);
  }

  late final Iterable<({int start, int end})> rawMatches;
  if (options.regex) {
    try {
      rawMatches =
          RegExp(query, caseSensitive: options.caseSensitive, multiLine: true)
              .allMatches(document.fullText)
              .map((match) => (start: match.start, end: match.end));
    } on FormatException {
      return SourceSearchResult(
        options: options,
        matches: const [],
        invalidRegex: true,
      );
    }
  } else {
    rawMatches = _plainMatches(document.fullText, query, options.caseSensitive);
  }

  final matches = <SourceSearchMatch>[];
  for (final match in rawMatches) {
    if (match.start == match.end) {
      continue;
    }
    if (options.wholeWord &&
        !_isWholeWord(document.fullText, match.start, match.end)) {
      continue;
    }
    final visible = document.fullRangeToVisibleRange(match.start, match.end);
    matches.add(
      SourceSearchMatch(
        fullStart: match.start,
        fullEnd: match.end,
        visibleStart: visible.range.start,
        visibleEnd: visible.range.end,
        hidden:
            visible.clippedByHiddenRange ||
            visible.range.start == visible.range.end,
      ),
    );
  }
  return SourceSearchResult(
    options: options,
    matches: List.unmodifiable(matches),
    currentMatchIndex:
        currentMatchIndex != null && currentMatchIndex < matches.length
        ? currentMatchIndex
        : null,
  );
}

Iterable<({int start, int end})> _plainMatches(
  String source,
  String query,
  bool caseSensitive,
) sync* {
  final haystack = caseSensitive ? source : source.toLowerCase();
  final needle = caseSensitive ? query : query.toLowerCase();
  var index = 0;
  while (index <= haystack.length - needle.length) {
    final found = haystack.indexOf(needle, index);
    if (found < 0) {
      break;
    }
    yield (start: found, end: found + needle.length);
    index = found + needle.length;
  }
}

bool _isWholeWord(String source, int start, int end) {
  final before = start <= 0 ? null : source.codeUnitAt(start - 1);
  final after = end >= source.length ? null : source.codeUnitAt(end);
  return !_isWordUnit(before) && !_isWordUnit(after);
}

bool _isWordUnit(int? unit) {
  if (unit == null) {
    return false;
  }
  return (unit >= 48 && unit <= 57) ||
      (unit >= 65 && unit <= 90) ||
      (unit >= 97 && unit <= 122) ||
      unit == 95;
}

bool _isAuthoringContentPath(String path) {
  final lower = path.toLowerCase();
  return lower.endsWith('.md') ||
      lower.endsWith('.topic') ||
      lower.endsWith('.tree') ||
      lower.endsWith('.cfg') ||
      lower.endsWith('.list') ||
      lower.endsWith('.xml') ||
      lower.endsWith('.properties') ||
      lower.endsWith('.yaml') ||
      lower.endsWith('.yml') ||
      lower.endsWith('.json');
}

bool _matchesEqual(
  List<SourceSearchMatch> left,
  List<SourceSearchMatch> right,
) {
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index++) {
    final a = left[index];
    final b = right[index];
    if (a.fullStart != b.fullStart ||
        a.fullEnd != b.fullEnd ||
        a.visibleStart != b.visibleStart ||
        a.visibleEnd != b.visibleEnd ||
        a.hidden != b.hidden) {
      return false;
    }
  }
  return true;
}

int _matchHash(SourceSearchMatch match) {
  return Object.hash(
    match.fullStart,
    match.fullEnd,
    match.visibleStart,
    match.visibleEnd,
    match.hidden,
  );
}
