import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;

import '../editor/source/source_document.dart';
import '../editor/source/source_search.dart';
import '../workspace/text_format_metadata.dart';
import '../workspace/workspace_model.dart';
import '../workspace/workspace_service.dart';

class TextReplacementMatch {
  const TextReplacementMatch({
    required this.id,
    required this.start,
    required this.end,
    required this.original,
    required this.replacement,
  });

  final String id;
  final int start;
  final int end;
  final String original;
  final String replacement;
}

class TextReplacementPreview {
  const TextReplacementPreview({
    required this.source,
    required this.options,
    required this.replacement,
    required this.matches,
    this.invalidRegex = false,
    this.truncated = false,
  });

  final String source;
  final SourceSearchOptions options;
  final String replacement;
  final List<TextReplacementMatch> matches;
  final bool invalidRegex;
  final bool truncated;

  String apply({Set<String>? selectedMatchIds}) {
    if (matches.isEmpty) {
      return source;
    }
    final output = StringBuffer();
    var sourceOffset = 0;
    for (final match in matches) {
      if (selectedMatchIds != null && !selectedMatchIds.contains(match.id)) {
        continue;
      }
      output
        ..write(source.substring(sourceOffset, match.start))
        ..write(match.replacement);
      sourceOffset = match.end;
    }
    if (sourceOffset == 0) {
      return source;
    }
    output.write(source.substring(sourceOffset));
    return output.toString();
  }
}

enum WorkspaceReplacementSourceKind { disk, dirtyBuffer }

enum WorkspaceReplacementIssueKind {
  oversized,
  unreadable,
  invalidUtf8,
  truncated,
  changedSincePreview,
  bufferRevisionChanged,
  normalizationRequired,
  partialApplicationConflict,
  applyFailed,
}

class WorkspaceReplacementIssue {
  const WorkspaceReplacementIssue({
    required this.kind,
    required this.filePath,
    this.preservedPath,
  });

  final WorkspaceReplacementIssueKind kind;
  final String filePath;
  final String? preservedPath;
}

class WorkspaceReplacementFilePreview {
  const WorkspaceReplacementFilePreview({
    required this.filePath,
    required this.relativePath,
    required this.sourceKind,
    required this.originalText,
    required this.matches,
    required this.format,
    this.bufferId,
    this.bufferRevision,
    this.diskSnapshot,
  });

  final String filePath;
  final String relativePath;
  final WorkspaceReplacementSourceKind sourceKind;
  final String originalText;
  final List<TextReplacementMatch> matches;
  final TextFormatMetadata format;
  final String? bufferId;
  final int? bufferRevision;
  final WorkspaceFileSnapshot? diskSnapshot;
}

class WorkspaceReplacementPreview {
  const WorkspaceReplacementPreview({
    required this.options,
    required this.replacement,
    required this.files,
    required this.issues,
  });

  final SourceSearchOptions options;
  final String replacement;
  final List<WorkspaceReplacementFilePreview> files;
  final List<WorkspaceReplacementIssue> issues;

  int get matchCount =>
      files.fold(0, (total, file) => total + file.matches.length);

  bool get isComplete => !issues.any(
    (issue) => issue.kind == WorkspaceReplacementIssueKind.truncated,
  );
}

class WorkspaceReplacementApplyResult {
  const WorkspaceReplacementApplyResult({
    required this.appliedFiles,
    required this.appliedMatches,
    required this.issues,
  });

  final int appliedFiles;
  final int appliedMatches;
  final List<WorkspaceReplacementIssue> issues;
}

class SearchReplacementService {
  const SearchReplacementService({
    this.maximumFileBytes = 1024 * 1024,
    this.maximumMatches = 5000,
  });

  final int maximumFileBytes;
  final int maximumMatches;

  TextReplacementPreview previewText({
    required String source,
    required SourceSearchOptions options,
    required String replacement,
    String idPrefix = 'match',
  }) {
    final matchLimit = maximumMatches.clamp(0, 0x7ffffffe).toInt();
    final search = searchSourceDocument(
      SourceDocument(fullText: source),
      options,
      maximumMatches: matchLimit + 1,
    );
    if (search.invalidRegex) {
      return TextReplacementPreview(
        source: source,
        options: options,
        replacement: replacement,
        matches: const [],
        invalidRegex: true,
      );
    }
    RegExp? expression;
    if (options.regex) {
      expression = RegExp(
        options.query,
        caseSensitive: options.caseSensitive,
        multiLine: true,
      );
    }
    final matches = <TextReplacementMatch>[];
    for (final (index, match) in search.matches.take(matchLimit).indexed) {
      final original = source.substring(match.fullStart, match.fullEnd);
      var renderedReplacement = replacement;
      if (expression != null) {
        final regexMatch = expression.matchAsPrefix(source, match.fullStart);
        if (regexMatch is RegExpMatch && regexMatch.end == match.fullEnd) {
          renderedReplacement = _expandRegexReplacement(
            replacement,
            regexMatch,
          );
        }
      }
      matches.add(
        TextReplacementMatch(
          id: '$idPrefix:$index:${match.fullStart}:${match.fullEnd}',
          start: match.fullStart,
          end: match.fullEnd,
          original: original,
          replacement: renderedReplacement,
        ),
      );
    }
    return TextReplacementPreview(
      source: source,
      options: options,
      replacement: replacement,
      matches: List.unmodifiable(matches),
      truncated: search.totalMatchCount > matchLimit,
    );
  }

  TextReplacementPreview previewMatch({
    required String source,
    required SourceSearchOptions options,
    required String replacement,
    required int start,
    required int end,
  }) {
    if (start < 0 || end <= start || end > source.length) {
      return TextReplacementPreview(
        source: source,
        options: options,
        replacement: replacement,
        matches: const [],
      );
    }
    var renderedReplacement = replacement;
    if (options.regex) {
      try {
        final expression = RegExp(
          options.query,
          caseSensitive: options.caseSensitive,
          multiLine: true,
        );
        final match = expression.matchAsPrefix(source, start);
        if (match is! RegExpMatch || match.end != end) {
          return TextReplacementPreview(
            source: source,
            options: options,
            replacement: replacement,
            matches: const [],
          );
        }
        renderedReplacement = _expandRegexReplacement(replacement, match);
      } on FormatException {
        return TextReplacementPreview(
          source: source,
          options: options,
          replacement: replacement,
          matches: const [],
          invalidRegex: true,
        );
      }
    }
    return TextReplacementPreview(
      source: source,
      options: options,
      replacement: replacement,
      matches: [
        TextReplacementMatch(
          id: 'match:0:$start:$end',
          start: start,
          end: end,
          original: source.substring(start, end),
          replacement: renderedReplacement,
        ),
      ],
    );
  }

  Future<WorkspaceReplacementPreview> previewWorkspace({
    required WorkspaceState state,
    required WorkspaceService workspaceService,
    required SourceSearchOptions options,
    required String replacement,
  }) async {
    final workspace = state.workspace;
    if (workspace == null || options.query.isEmpty) {
      return WorkspaceReplacementPreview(
        options: options,
        replacement: replacement,
        files: const [],
        issues: const [],
      );
    }
    final files = <WorkspaceReplacementFilePreview>[];
    final issues = <WorkspaceReplacementIssue>[];
    final candidates = <String, String>{
      for (final file in workspace.files)
        if (_isReplaceableTextPath(file.absolutePath))
          file.absolutePath: file.relativePath,
      for (final buffer in state.documentBuffers)
        if (buffer.filePath case final path?)
          path: p.relative(path, from: workspace.rootPath),
    };
    var remaining = maximumMatches;
    final sortedPaths = candidates.keys.toList()..sort();
    for (final path in sortedPaths) {
      final buffer = state.bufferForPath(path);
      late final String text;
      late final TextFormatMetadata format;
      WorkspaceFileSnapshot? snapshot;
      if (buffer != null) {
        text = buffer.text;
        format = buffer.format;
        snapshot = buffer.diskSnapshot;
      } else {
        final metadata = workspace.files
            .where((file) => p.equals(file.absolutePath, path))
            .firstOrNull;
        if (metadata != null && metadata.size > maximumFileBytes) {
          issues.add(
            WorkspaceReplacementIssue(
              kind: WorkspaceReplacementIssueKind.oversized,
              filePath: path,
            ),
          );
          continue;
        }
        try {
          final loaded = await workspaceService.loadTextWithSnapshot(path);
          text = loaded.text;
          format = loaded.format;
          snapshot = loaded.snapshot;
        } on FormatException {
          issues.add(
            WorkspaceReplacementIssue(
              kind: WorkspaceReplacementIssueKind.invalidUtf8,
              filePath: path,
            ),
          );
          continue;
        } on FileSystemException {
          issues.add(
            WorkspaceReplacementIssue(
              kind: WorkspaceReplacementIssueKind.unreadable,
              filePath: path,
            ),
          );
          continue;
        }
      }
      final preview = previewText(
        source: text,
        options: options,
        replacement: replacement,
        idPrefix: path,
      );
      if (preview.matches.isEmpty) {
        continue;
      }
      final retained = preview.matches.take(remaining).toList(growable: false);
      files.add(
        WorkspaceReplacementFilePreview(
          filePath: path,
          relativePath: candidates[path]!,
          sourceKind: buffer?.isDirty == true
              ? WorkspaceReplacementSourceKind.dirtyBuffer
              : WorkspaceReplacementSourceKind.disk,
          originalText: text,
          matches: retained,
          format: format,
          bufferId: buffer?.id,
          bufferRevision: buffer?.revision,
          diskSnapshot: snapshot,
        ),
      );
      remaining -= retained.length;
      if (remaining <= 0) {
        issues.add(
          WorkspaceReplacementIssue(
            kind: WorkspaceReplacementIssueKind.truncated,
            filePath: path,
          ),
        );
        break;
      }
    }
    return WorkspaceReplacementPreview(
      options: options,
      replacement: replacement,
      files: List.unmodifiable(files),
      issues: List.unmodifiable(issues),
    );
  }

  Future<WorkspaceReplacementApplyResult> applyWorkspace({
    required WorkspaceReplacementPreview preview,
    required Set<String> selectedMatchIds,
    required WorkspaceState Function() currentState,
    required void Function(String bufferId, String text) updateBuffer,
    required WorkspaceService workspaceService,
    Map<String, LineEndingNormalization> mixedLineEndingNormalizations =
        const {},
  }) async {
    final issues = <WorkspaceReplacementIssue>[];
    if (!preview.isComplete) {
      return WorkspaceReplacementApplyResult(
        appliedFiles: 0,
        appliedMatches: 0,
        issues: List.unmodifiable([
          for (final issue in preview.issues)
            if (issue.kind == WorkspaceReplacementIssueKind.truncated) issue,
        ]),
      );
    }
    final state = currentState();
    final operations = <_WorkspaceReplacementOperation>[];
    for (final file in preview.files) {
      final selected = {
        for (final match in file.matches)
          if (selectedMatchIds.contains(match.id)) match.id,
      };
      if (selected.isEmpty) {
        continue;
      }
      final currentBuffer = file.bufferId == null
          ? null
          : state.documentBuffers
                .where((buffer) => buffer.id == file.bufferId)
                .firstOrNull;
      if (file.bufferId != null) {
        if (currentBuffer == null ||
            currentBuffer.revision != file.bufferRevision ||
            currentBuffer.text != file.originalText) {
          issues.add(
            WorkspaceReplacementIssue(
              kind: WorkspaceReplacementIssueKind.bufferRevisionChanged,
              filePath: file.filePath,
            ),
          );
          continue;
        }
      } else if (await workspaceService.fileChangedSince(
        file.filePath,
        file.diskSnapshot,
      )) {
        issues.add(
          WorkspaceReplacementIssue(
            kind: WorkspaceReplacementIssueKind.changedSincePreview,
            filePath: file.filePath,
          ),
        );
        continue;
      }
      final normalization = mixedLineEndingNormalizations[file.filePath];
      if (file.bufferId == null &&
          file.format.hasMixedLineEndings &&
          normalization == null) {
        issues.add(
          WorkspaceReplacementIssue(
            kind: WorkspaceReplacementIssueKind.normalizationRequired,
            filePath: file.filePath,
          ),
        );
        continue;
      }
      final textPreview = TextReplacementPreview(
        source: file.originalText,
        options: preview.options,
        replacement: preview.replacement,
        matches: file.matches,
      );
      final nextText = textPreview.apply(selectedMatchIds: selected);
      operations.add(
        _WorkspaceReplacementOperation(
          file: file,
          nextText: nextText,
          selectedMatchCount: selected.length,
          normalization: normalization,
        ),
      );
    }
    if (issues.isNotEmpty) {
      return WorkspaceReplacementApplyResult(
        appliedFiles: 0,
        appliedMatches: 0,
        issues: List.unmodifiable(issues),
      );
    }
    final diskOperations = operations
        .where((operation) => operation.file.bufferId == null)
        .toList(growable: false);
    try {
      await workspaceService.saveFormattedTextBatch([
        for (final operation in diskOperations)
          WorkspaceBatchTextWrite(
            path: operation.file.filePath,
            text: operation.nextText,
            expectedSnapshot: operation.file.diskSnapshot!,
            format: operation.file.format,
            mixedNormalization: operation.normalization,
          ),
      ]);
    } on WorkspaceBatchWriteConflict catch (error) {
      return WorkspaceReplacementApplyResult(
        appliedFiles: 0,
        appliedMatches: 0,
        issues: [
          WorkspaceReplacementIssue(
            kind: WorkspaceReplacementIssueKind.changedSincePreview,
            filePath: error.path,
          ),
        ],
      );
    } on WorkspaceBatchPartialApplicationConflict catch (error) {
      return WorkspaceReplacementApplyResult(
        appliedFiles: 0,
        appliedMatches: 0,
        issues: [
          for (final file in error.files)
            WorkspaceReplacementIssue(
              kind: WorkspaceReplacementIssueKind.partialApplicationConflict,
              filePath: file.targetPath,
              preservedPath: file.preservedPath,
            ),
        ],
      );
    } on Object {
      return WorkspaceReplacementApplyResult(
        appliedFiles: 0,
        appliedMatches: 0,
        issues: [
          for (final operation in diskOperations)
            WorkspaceReplacementIssue(
              kind: WorkspaceReplacementIssueKind.applyFailed,
              filePath: operation.file.filePath,
            ),
        ],
      );
    }
    final postWriteState = currentState();
    final staleOpenOperations = <_WorkspaceReplacementOperation>[];
    for (final operation in operations) {
      final bufferId = operation.file.bufferId;
      if (bufferId == null) {
        continue;
      }
      final buffer = postWriteState.documentBuffers
          .where((candidate) => candidate.id == bufferId)
          .firstOrNull;
      if (buffer == null ||
          buffer.revision != operation.file.bufferRevision ||
          buffer.text != operation.file.originalText) {
        staleOpenOperations.add(operation);
      }
    }
    if (staleOpenOperations.isNotEmpty) {
      return WorkspaceReplacementApplyResult(
        appliedFiles: diskOperations.length,
        appliedMatches: diskOperations.fold(
          0,
          (total, operation) => total + operation.selectedMatchCount,
        ),
        issues: List.unmodifiable([
          for (final operation in staleOpenOperations)
            WorkspaceReplacementIssue(
              kind: WorkspaceReplacementIssueKind.bufferRevisionChanged,
              filePath: operation.file.filePath,
            ),
        ]),
      );
    }
    for (final operation in operations) {
      if (operation.file.bufferId case final bufferId?) {
        updateBuffer(bufferId, operation.nextText);
      }
    }
    return WorkspaceReplacementApplyResult(
      appliedFiles: operations.length,
      appliedMatches: operations.fold(
        0,
        (total, operation) => total + operation.selectedMatchCount,
      ),
      issues: List.unmodifiable(issues),
    );
  }

  String _expandRegexReplacement(String replacement, RegExpMatch match) {
    final output = StringBuffer();
    for (var index = 0; index < replacement.length; index++) {
      final character = replacement[index];
      if (character != r'$' || index + 1 >= replacement.length) {
        output.write(character);
        continue;
      }
      final next = replacement[index + 1];
      if (next == r'$') {
        output.write(r'$');
        index++;
        continue;
      }
      if (next == '&') {
        output.write(match.group(0) ?? '');
        index++;
        continue;
      }
      if (next == '{') {
        final close = replacement.indexOf('}', index + 2);
        if (close > index + 2) {
          final name = replacement.substring(index + 2, close);
          try {
            output.write(match.namedGroup(name) ?? '');
            index = close;
            continue;
          } on ArgumentError {
            // Preserve an unknown capture reference literally.
          }
        }
      }
      if (_isDigit(next)) {
        var end = index + 1;
        while (end < replacement.length &&
            end < index + 3 &&
            _isDigit(replacement[end])) {
          end++;
        }
        final group = int.parse(replacement.substring(index + 1, end));
        if (group <= match.groupCount) {
          output.write(match.group(group) ?? '');
          index = end - 1;
          continue;
        }
      }
      output.write(r'$');
    }
    return output.toString();
  }

  bool _isDigit(String value) {
    final unit = value.codeUnitAt(0);
    return unit >= 48 && unit <= 57;
  }

  bool _isReplaceableTextPath(String path) {
    return switch (p.extension(path).toLowerCase()) {
      '.md' || '.markdown' || '.xml' || '.topic' || '.tree' || '.html' => true,
      _ => false,
    };
  }
}

/// Plans Source-view replacements away from Flutter's UI isolate.
///
/// A newer request immediately invalidates and terminates the preceding one,
/// matching the cancellation contract used by interactive Source search.
class SearchReplacementWorker {
  Isolate? _isolate;
  ReceivePort? _receivePort;
  Completer<TextReplacementPreview?>? _completer;
  var _generation = 0;

  Future<TextReplacementPreview?> previewText({
    required String source,
    required SourceSearchOptions options,
    required String replacement,
    int maximumMatches = 5000,
    int? targetStart,
    int? targetEnd,
  }) {
    cancel();
    final generation = ++_generation;
    final receivePort = ReceivePort();
    final completer = Completer<TextReplacementPreview?>();
    _receivePort = receivePort;
    _completer = completer;
    receivePort.listen((message) {
      if (generation != _generation || completer.isCompleted) {
        return;
      }
      if (message is Map<Object?, Object?>) {
        completer.complete(
          _decodeReplacementPreview(
            message,
            source: source,
            options: options,
            replacement: replacement,
          ),
        );
      } else {
        completer.complete(null);
      }
      _releaseWorker(kill: true);
    });
    final request = <String, Object?>{
      'source': source,
      'query': options.query,
      'caseSensitive': options.caseSensitive,
      'wholeWord': options.wholeWord,
      'regex': options.regex,
      'replacement': replacement,
      'maximumMatches': maximumMatches,
      'targetStart': targetStart,
      'targetEnd': targetEnd,
    };
    Isolate.spawn<List<Object?>>(
          _replacementWorkerMain,
          <Object?>[receivePort.sendPort, request],
          debugName: 'BusyMark source replacement',
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

void _replacementWorkerMain(List<Object?> payload) {
  final sendPort = payload[0] as SendPort;
  final request = payload[1] as Map<Object?, Object?>;
  final options = SourceSearchOptions(
    query: request['query']! as String,
    caseSensitive: request['caseSensitive']! as bool,
    wholeWord: request['wholeWord']! as bool,
    regex: request['regex']! as bool,
  );
  final service = SearchReplacementService(
    maximumMatches: request['maximumMatches']! as int,
  );
  final source = request['source']! as String;
  final replacement = request['replacement']! as String;
  final targetStart = request['targetStart'] as int?;
  final targetEnd = request['targetEnd'] as int?;
  final preview = targetStart != null && targetEnd != null
      ? service.previewMatch(
          source: source,
          options: options,
          replacement: replacement,
          start: targetStart,
          end: targetEnd,
        )
      : service.previewText(
          source: source,
          options: options,
          replacement: replacement,
        );
  sendPort.send(<Object?, Object?>{
    'invalidRegex': preview.invalidRegex,
    'truncated': preview.truncated,
    'matches': [
      for (final match in preview.matches)
        <Object?>[
          match.id,
          match.start,
          match.end,
          match.original,
          match.replacement,
        ],
    ],
  });
}

TextReplacementPreview _decodeReplacementPreview(
  Map<Object?, Object?> payload, {
  required String source,
  required SourceSearchOptions options,
  required String replacement,
}) {
  final encodedMatches = payload['matches']! as List<Object?>;
  return TextReplacementPreview(
    source: source,
    options: options,
    replacement: replacement,
    matches: List.unmodifiable([
      for (final item in encodedMatches.cast<List<Object?>>())
        TextReplacementMatch(
          id: item[0]! as String,
          start: item[1]! as int,
          end: item[2]! as int,
          original: item[3]! as String,
          replacement: item[4]! as String,
        ),
    ]),
    invalidRegex: payload['invalidRegex']! as bool,
    truncated: payload['truncated']! as bool,
  );
}

class _WorkspaceReplacementOperation {
  const _WorkspaceReplacementOperation({
    required this.file,
    required this.nextText,
    required this.selectedMatchCount,
    required this.normalization,
  });

  final WorkspaceReplacementFilePreview file;
  final String nextText;
  final int selectedMatchCount;
  final LineEndingNormalization? normalization;
}
