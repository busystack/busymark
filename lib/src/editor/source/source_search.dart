import 'dart:async';
import 'dart:isolate';

import 'source_document.dart';
import 'source_hidden_ranges.dart';

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

  void stageOptions(SourceSearchOptions options, {bool invalidRegex = false}) {
    _options = options;
    _version++;
    _result = SourceSearchResult(
      options: options,
      matches: const [],
      invalidRegex: invalidRegex,
    );
  }

  void acceptResult(SourceSearchResult result) {
    if (result.options != _options) {
      return;
    }
    _version++;
    _result = result;
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

/// Runs potentially expensive regular expressions away from Flutter's UI
/// isolate. Starting a newer request kills the preceding worker immediately.
class SourceSearchWorker {
  Isolate? _isolate;
  ReceivePort? _receivePort;
  Completer<SourceSearchResult?>? _completer;
  var _generation = 0;

  Future<SourceSearchResult?> search(
    SourceDocument document,
    SourceSearchOptions options, {
    int? currentMatchIndex,
  }) {
    cancel();
    final generation = ++_generation;
    final receivePort = ReceivePort();
    final completer = Completer<SourceSearchResult?>();
    _receivePort = receivePort;
    _completer = completer;
    receivePort.listen((message) {
      if (generation != _generation || completer.isCompleted) {
        return;
      }
      if (message is Map<Object?, Object?>) {
        completer.complete(_decodeSearchResult(message, options));
      } else {
        completer.complete(null);
      }
      _releaseWorker(kill: true);
    });
    final request = <String, Object?>{
      'text': document.fullText,
      'hidden': [
        for (final range in document.hiddenRanges.ranges)
          <Object?>[range.start, range.end, range.key],
      ],
      'query': options.query,
      'caseSensitive': options.caseSensitive,
      'wholeWord': options.wholeWord,
      'regex': options.regex,
      'currentMatchIndex': currentMatchIndex,
    };
    Isolate.spawn<List<Object?>>(
          _sourceSearchWorkerMain,
          <Object?>[receivePort.sendPort, request],
          debugName: 'BusyMark source search',
          onError: receivePort.sendPort,
          onExit: receivePort.sendPort,
        )
        .then((isolate) {
          if (generation != _generation || completer.isCompleted) {
            isolate.kill(priority: Isolate.immediate);
          } else {
            _isolate = isolate;
          }
        })
        .catchError((Object _) {
          if (generation == _generation && !completer.isCompleted) {
            completer.complete(null);
            _releaseWorker(kill: false);
          }
        });
    return completer.future;
  }

  void cancel() {
    _generation++;
    final completer = _completer;
    if (completer != null && !completer.isCompleted) {
      completer.complete(null);
    }
    _releaseWorker(kill: true);
  }

  void dispose() => cancel();

  void _releaseWorker({required bool kill}) {
    if (kill) {
      _isolate?.kill(priority: Isolate.immediate);
    }
    _isolate = null;
    _receivePort?.close();
    _receivePort = null;
    _completer = null;
  }
}

void _sourceSearchWorkerMain(List<Object?> payload) {
  final sendPort = payload[0] as SendPort;
  final request = payload[1] as Map<Object?, Object?>;
  final text = request['text']! as String;
  final hidden = request['hidden']! as List<Object?>;
  final options = SourceSearchOptions(
    query: request['query']! as String,
    caseSensitive: request['caseSensitive']! as bool,
    wholeWord: request['wholeWord']! as bool,
    regex: request['regex']! as bool,
  );
  final document = SourceDocument(
    fullText: text,
    hiddenRanges: SourceHiddenRanges(
      ranges: [
        for (final item in hidden.cast<List<Object?>>())
          SourceHiddenRange(
            start: item[0]! as int,
            end: item[1]! as int,
            key: item[2] as String?,
          ),
      ],
      textLength: text.length,
    ),
  );
  final result = searchSourceDocument(
    document,
    options,
    currentMatchIndex: request['currentMatchIndex'] as int?,
  );
  sendPort.send(<Object?, Object?>{
    'invalidRegex': result.invalidRegex,
    'currentMatchIndex': result.currentMatchIndex,
    'matches': [
      for (final match in result.matches)
        <Object?>[
          match.fullStart,
          match.fullEnd,
          match.visibleStart,
          match.visibleEnd,
          match.hidden,
        ],
    ],
  });
}

SourceSearchResult _decodeSearchResult(
  Map<Object?, Object?> payload,
  SourceSearchOptions options,
) {
  final encodedMatches = payload['matches']! as List<Object?>;
  return SourceSearchResult(
    options: options,
    matches: List.unmodifiable([
      for (final item in encodedMatches.cast<List<Object?>>())
        SourceSearchMatch(
          fullStart: item[0]! as int,
          fullEnd: item[1]! as int,
          visibleStart: item[2]! as int,
          visibleEnd: item[3]! as int,
          hidden: item[4]! as bool,
        ),
    ]),
    currentMatchIndex: payload['currentMatchIndex'] as int?,
    invalidRegex: payload['invalidRegex']! as bool,
  );
}

bool sourceSearchOptionsHaveInvalidRegex(SourceSearchOptions options) {
  if (!options.regex || options.query.isEmpty) {
    return false;
  }
  try {
    RegExp(
      options.query,
      caseSensitive: options.caseSensitive,
      multiLine: true,
    );
    return false;
  } on FormatException {
    return true;
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
  final expression = RegExp(
    RegExp.escape(query),
    caseSensitive: caseSensitive,
    unicode: true,
  );
  for (final match in expression.allMatches(source)) {
    yield (start: match.start, end: match.end);
  }
}

bool _isWholeWord(String source, int start, int end) {
  return !_isUnicodeWordCharacter(_characterBefore(source, start)) &&
      !_isUnicodeWordCharacter(_characterAt(source, end));
}

final _unicodeWordCharacter = RegExp(r'^[\p{L}\p{N}\p{M}_]$', unicode: true);

bool _isUnicodeWordCharacter(String? character) {
  if (character == null) {
    return false;
  }
  return _unicodeWordCharacter.hasMatch(character);
}

String? _characterBefore(String source, int offset) {
  if (offset <= 0 || source.isEmpty) {
    return null;
  }
  final end = offset.clamp(0, source.length).toInt();
  var start = end - 1;
  if (_isLowSurrogate(source.codeUnitAt(start)) &&
      start > 0 &&
      _isHighSurrogate(source.codeUnitAt(start - 1))) {
    start--;
  }
  return source.substring(start, end);
}

String? _characterAt(String source, int offset) {
  if (offset < 0 || offset >= source.length) {
    return null;
  }
  var end = offset + 1;
  if (_isHighSurrogate(source.codeUnitAt(offset)) &&
      end < source.length &&
      _isLowSurrogate(source.codeUnitAt(end))) {
    end++;
  }
  return source.substring(offset, end);
}

bool _isHighSurrogate(int unit) => unit >= 0xD800 && unit <= 0xDBFF;

bool _isLowSurrogate(int unit) => unit >= 0xDC00 && unit <= 0xDFFF;

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
