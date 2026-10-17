import 'dart:async';
import 'dart:isolate';

import 'source_document.dart';
import 'source_hidden_ranges.dart';

/// Maximum number of interactive matches transferred back to the UI isolate
/// at once. The worker still reports the complete match count so the search
/// panel can remain accurate and another window can be requested for
/// navigation.
const int sourceInteractiveSearchMatchLimit = 2048;

/// The literal query also identifies asynchronous matching/navigation requests.
class SourceSearchOptions {
  const SourceSearchOptions({this.query = ''});

  final String query;

  @override
  bool operator ==(Object other) =>
      other is SourceSearchOptions && other.query == query;

  @override
  int get hashCode => query.hashCode;
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
  SourceSearchResult({
    required this.options,
    required this.matches,
    this.currentMatchIndex,
    int? totalMatchCount,
    this.firstMatchIndex = 0,
  }) : totalMatchCount = totalMatchCount ?? matches.length;

  static final empty = SourceSearchResult(
    options: SourceSearchOptions(),
    matches: [],
  );

  final SourceSearchOptions options;
  final List<SourceSearchMatch> matches;

  /// The current match's index in the complete result set, not just [matches].
  final int? currentMatchIndex;
  final int totalMatchCount;

  /// The complete-result index represented by [matches.first].
  final int firstMatchIndex;

  SourceSearchMatch? get currentMatch {
    final index = currentMatchIndex;
    if (index == null) {
      return null;
    }
    final localIndex = index - firstMatchIndex;
    if (localIndex < 0 || localIndex >= matches.length) {
      return null;
    }
    return matches[localIndex];
  }

  SourceSearchResult copyWith({int? currentMatchIndex}) {
    return SourceSearchResult(
      options: options,
      matches: matches,
      currentMatchIndex: currentMatchIndex,
      totalMatchCount: totalMatchCount,
      firstMatchIndex: firstMatchIndex,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SourceSearchResult &&
        other.options == options &&
        other.currentMatchIndex == currentMatchIndex &&
        other.totalMatchCount == totalMatchCount &&
        other.firstMatchIndex == firstMatchIndex &&
        _matchesEqual(other.matches, matches);
  }

  @override
  int get hashCode => Object.hash(
    options,
    currentMatchIndex,
    totalMatchCount,
    firstMatchIndex,
    Object.hashAll(matches.map(_matchHash)),
  );
}

/// A source editor projects the window's matches through its folding map.
/// It does not start another search while this snapshot is supplied.
class SourceSearchSnapshot {
  const SourceSearchSnapshot({
    required this.source,
    required this.result,
    this.truncated = false,
    this.searching = false,
    this.navigationRequest = 0,
    this.appliedNavigation = 0,
    this.sourceRevision,
    this.sessionRevision = 0,
  });
  final String source;
  final SourceSearchResult result;
  final bool truncated;
  final bool searching;
  final int navigationRequest, appliedNavigation;
  final int? sourceRevision;
  final int sessionRevision;
}

/// A navigation request for the window's existing search session. The source
/// and identity must still match the active buffer before resolving an offset.
class SourceSearchNavigationRequest {
  const SourceSearchNavigationRequest({
    required this.documentId,
    required this.source,
    required this.options,
    this.matchIndex,
    this.minimumFullOffset,
    this.reveal = true,
  });
  final String? documentId;
  final String source;
  final SourceSearchOptions options;
  final int? matchIndex, minimumFullOffset;
  final bool reveal;
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

  void stageOptions(SourceSearchOptions options) {
    _options = options;
    _version++;
    _result = SourceSearchResult(options: options, matches: const []);
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
        index != null &&
            index >= _result.firstMatchIndex &&
            index < _result.firstMatchIndex + _result.matches.length
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
        ? _result.firstMatchIndex
        : (_result.currentMatchIndex! + 1) % _result.totalMatchCount;
    if (nextIndex < _result.firstMatchIndex ||
        nextIndex >= _result.firstMatchIndex + _result.matches.length) {
      return null;
    }
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
        ? _result.totalMatchCount - 1
        : (_result.currentMatchIndex! - 1 + _result.totalMatchCount) %
              _result.totalMatchCount;
    if (previousIndex < _result.firstMatchIndex ||
        previousIndex >= _result.firstMatchIndex + _result.matches.length) {
      return null;
    }
    _result = _result.copyWith(currentMatchIndex: previousIndex);
    return _result.currentMatch;
  }

  void discardIfStale(int documentVersion, int resultVersion) {
    if (resultVersion < documentVersion) {
      _result = SourceSearchResult(options: _options, matches: const []);
    }
  }
}

/// Runs literal matching and full-document counting away from Flutter's UI
/// isolate. Starting a newer request kills the preceding worker immediately.
class SourceSearchWorker {
  Isolate? _isolate;
  SendPort? _sessionPort;
  ReceivePort? _receivePort;
  Completer<SourceSearchResult?>? _completer;
  var _generation = 0;

  Future<SourceSearchResult?> search(
    SourceDocument document,
    SourceSearchOptions options, {
    int? currentMatchIndex,
    int firstMatchIndex = 0,
    int? minimumFullOffset,
    int maximumMatches = sourceInteractiveSearchMatchLimit,
    bool stopAfterMaximumMatches = false,
    bool reuseWorker = false,
  }) {
    final reuse = reuseWorker && _sessionPort != null && _completer == null;
    if (!reuse) cancel();
    final generation = ++_generation;
    final receivePort = ReceivePort();
    final completer = Completer<SourceSearchResult?>();
    _receivePort = receivePort;
    _completer = completer;
    late final Map<String, Object?> request;
    receivePort.listen((message) {
      if (generation != _generation || completer.isCompleted) {
        return;
      }
      if (message is SendPort && reuseWorker) {
        _sessionPort = message;
        message.send(<Object?>[receivePort.sendPort, request]);
        return;
      }
      if (message is Map<Object?, Object?>) {
        completer.complete(_decodeSearchResult(message, options));
      } else {
        completer.complete(null);
      }
      if (reuseWorker) {
        _receivePort?.close();
        _receivePort = null;
        _completer = null;
      } else {
        _releaseWorker(kill: true);
      }
    });
    request = <String, Object?>{
      'text': document.fullText,
      'hidden': [
        for (final range in document.hiddenRanges.ranges)
          <Object?>[range.start, range.end, range.key],
      ],
      'query': options.query,
      'currentMatchIndex': currentMatchIndex,
      'firstMatchIndex': firstMatchIndex,
      'minimumFullOffset': minimumFullOffset,
      'maximumMatches': maximumMatches,
      'stopAfterMaximumMatches': stopAfterMaximumMatches,
    };
    if (reuse) {
      _sessionPort!.send(<Object?>[receivePort.sendPort, request]);
      return completer.future;
    }
    Isolate.spawn<List<Object?>>(
          reuseWorker ? _sourceSearchSessionMain : _sourceSearchWorkerMain,
          <Object?>[receivePort.sendPort, request],
          debugName: 'BusyMark source search',
          onError: receivePort.sendPort,
          onExit: receivePort.sendPort,
        )
        .then((isolate) {
          if (generation != _generation ||
              completer.isCompleted && !reuseWorker) {
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
    _sessionPort = null;
    _receivePort?.close();
    _receivePort = null;
    _completer = null;
  }
}

// One explicitly scoped workspace query can reuse its worker for sequential
// files. Cancelling or changing the query still kills the isolate immediately.
void _sourceSearchSessionMain(List<Object?> payload) {
  final requests = ReceivePort();
  (payload[0] as SendPort).send(requests.sendPort);
  requests.listen((request) {
    final message = (request as List<Object?>);
    try {
      _sourceSearchWorkerMain(message);
    } on Object {
      (message[0] as SendPort).send(null);
    }
  });
}

void _sourceSearchWorkerMain(List<Object?> payload) {
  final sendPort = payload[0] as SendPort;
  final request = payload[1] as Map<Object?, Object?>;
  final text = request['text']! as String;
  final hidden = request['hidden']! as List<Object?>;
  final options = SourceSearchOptions(query: request['query']! as String);
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
    firstMatchIndex: request['firstMatchIndex']! as int,
    minimumFullOffset: request['minimumFullOffset'] as int?,
    maximumMatches: request['maximumMatches']! as int,
    stopAfterMaximumMatches: request['stopAfterMaximumMatches']! as bool,
  );
  sendPort.send(<Object?, Object?>{
    'currentMatchIndex': result.currentMatchIndex,
    'totalMatchCount': result.totalMatchCount,
    'firstMatchIndex': result.firstMatchIndex,
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
    totalMatchCount: payload['totalMatchCount']! as int,
    firstMatchIndex: payload['firstMatchIndex']! as int,
  );
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
  int firstMatchIndex = 0,
  int? minimumFullOffset,
  int? maximumMatches,
  bool stopAfterMaximumMatches = false,
}) {
  final query = options.query;
  if (query.isEmpty) {
    return SourceSearchResult(options: options, matches: const []);
  }

  final rawMatches = _plainMatches(document.fullText, query);

  final requestedFirstMatchIndex = firstMatchIndex < 0 ? 0 : firstMatchIndex;
  final matchLimit = maximumMatches?.clamp(0, 0x7fffffff).toInt();
  final matches = <SourceSearchMatch>[];
  var totalMatchCount = 0;
  var storedFirstMatchIndex = requestedFirstMatchIndex;
  var foundOffsetWindow = minimumFullOffset == null;
  for (final match in rawMatches) {
    if (!sourceSearchRangeHasSafeBoundaries(
      document.fullText,
      match.start,
      match.end,
    )) {
      continue;
    }
    final matchIndex = totalMatchCount++;
    if (!foundOffsetWindow) {
      if (match.start < minimumFullOffset!) {
        continue;
      }
      storedFirstMatchIndex = matchIndex;
      foundOffsetWindow = true;
    }
    if (minimumFullOffset == null && matchIndex < requestedFirstMatchIndex ||
        (matchLimit != null && matches.length >= matchLimit)) {
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
    if (stopAfterMaximumMatches &&
        matchLimit != null &&
        matches.length >= matchLimit) {
      break;
    }
  }
  if (!foundOffsetWindow) {
    storedFirstMatchIndex = totalMatchCount;
  }
  final storedEnd = storedFirstMatchIndex + matches.length;
  return SourceSearchResult(
    options: options,
    matches: List.unmodifiable(matches),
    currentMatchIndex:
        currentMatchIndex != null &&
            currentMatchIndex >= storedFirstMatchIndex &&
            currentMatchIndex < storedEnd &&
            currentMatchIndex < totalMatchCount
        ? currentMatchIndex
        : null,
    totalMatchCount: totalMatchCount,
    firstMatchIndex: storedFirstMatchIndex,
  );
}

/// Search and replacement offsets are UTF-16 offsets, but must never bisect
/// a character represented by a surrogate pair.
bool sourceSearchRangeHasSafeBoundaries(String source, int start, int end) {
  bool safe(int offset) =>
      offset >= 0 &&
      offset <= source.length &&
      (offset == 0 ||
          offset == source.length ||
          !_isHighSurrogate(source.codeUnitAt(offset - 1)) ||
          !_isLowSurrogate(source.codeUnitAt(offset)));
  return start <= end && safe(start) && safe(end);
}

Iterable<({int start, int end})> _plainMatches(
  String source,
  String query,
) sync* {
  final expression = RegExp(
    RegExp.escape(query),
    caseSensitive: false,
    unicode: true,
  );
  for (final match in expression.allMatches(source)) {
    yield (start: match.start, end: match.end);
  }
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
