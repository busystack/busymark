import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'local_history_models.dart';
import '../workspace/text_format_metadata.dart';

abstract interface class LocalHistoryStore {
  Future<LocalHistorySnapshot> load();

  Future<LocalHistoryCaptureResult> capture(
    LocalHistoryCaptureRequest request,
    LocalHistoryPolicy policy,
  );

  Future<LocalHistoryRevision?> readRevision(String revisionId);

  Future<void> prune(LocalHistoryPolicy policy, DateTime now);

  /// Promotes an existing untitled history document to its first file path
  /// without requiring a content revision to be recorded.
  ///
  /// Returns the updated document, or `null` when the requested identity is
  /// missing or is no longer eligible for this transition.
  Future<LocalHistoryDocument?> promoteUntitledDocument({
    required String documentId,
    required String destinationPath,
    required String displayName,
    required DateTime updatedAt,
  });

  Future<void> remapPath(String sourcePath, String destinationPath);

  Future<void> markDeleted(String path, {required bool recursive});

  Future<void> clearDocument(String documentId);

  Future<void> clearAll();
}

class FileLocalHistoryStore implements LocalHistoryStore {
  FileLocalHistoryStore({
    Future<Directory> Function()? rootDirectory,
    String Function()? createId,
  }) : _rootDirectory = rootDirectory ?? _defaultRootDirectory,
       _createId = createId ?? const Uuid().v4;

  static const formatVersion = 1;
  final Future<Directory> Function() _rootDirectory;
  final String Function() _createId;
  Future<void> _queue = Future<void>.value();
  static final Map<String, Future<void>> _rootQueues = {};

  static Future<Directory> _defaultRootDirectory() async {
    final support = await getApplicationSupportDirectory();
    return Directory(p.join(support.path, 'local_history'));
  }

  @override
  Future<LocalHistorySnapshot> load() =>
      _serialized((root) => _withFileLock(root, () => _loadUnlocked(root)));

  @override
  Future<LocalHistoryCaptureResult> capture(
    LocalHistoryCaptureRequest request,
    LocalHistoryPolicy policy,
  ) => _serialized((root) async {
    policy.validate();
    return _withFileLock(root, () async {
      var index = await _loadIndexUnlocked(root, repair: true);
      var document = _resolveDocument(index.documents, request);
      document ??= LocalHistoryDocument(
        id: _safeNewId(),
        displayName: request.displayName,
        currentPath: request.path,
        historicalPaths: request.path == null ? const [] : [request.path!],
        updatedAt: request.capturedAt.toUtc(),
        untitled: request.untitled,
      );
      final identity = _captureIdentity(document, request);
      document = _updatedDocument(
        document,
        request,
        path: identity.path,
        preserveIdentityMetadata: identity.pathMismatchWasRejected,
      );
      final checksum = sourceChecksum(request.source);
      final adjacent = index.revisions
          .where((revision) => revision.documentId == document!.id)
          .fold<LocalHistoryRevisionSummary?>(
            null,
            (latest, revision) =>
                latest == null || revision.capturedAt.isAfter(latest.capturedAt)
                ? revision
                : latest,
          );
      if (!request.force && adjacent?.checksum == checksum) {
        index = index.withDocument(document);
        await _publishIndex(root, index);
        return LocalHistoryCaptureResult(
          document: document,
          revision: adjacent,
          deduplicated: true,
        );
      }
      final estimatedBytes = utf8.encode(request.source).length + 2048;
      if (estimatedBytes > policy.maximumBytes) {
        throw const LocalHistoryStorageException(
          'The revision is larger than the Local History storage limit.',
        );
      }
      final revisionId = _safeNewId();
      var summary = LocalHistoryRevisionSummary(
        id: revisionId,
        documentId: document.id,
        capturedAt: request.capturedAt.toUtc(),
        reason: request.reason,
        checksum: checksum,
        storageBytes: 0,
        sourceLength: request.source.length,
        historicalPath: identity.path,
      );
      final target = _revisionFile(root, document.id, revisionId);
      await target.parent.create(recursive: true);
      final encoded = _revisionJson(document, summary, request);
      await _publishNewFile(target, encoded);
      summary = LocalHistoryRevisionSummary(
        id: summary.id,
        documentId: summary.documentId,
        capturedAt: summary.capturedAt,
        reason: summary.reason,
        checksum: summary.checksum,
        storageBytes: await target.length(),
        sourceLength: summary.sourceLength,
        historicalPath: summary.historicalPath,
      );
      index = index.withCapture(document, summary);
      // A complete revision exists before the index points to it.
      await _publishIndex(root, index);
      final retained = await _applyRetention(
        root,
        index,
        policy,
        revisionId,
        request.capturedAt.toUtc(),
      );
      if (!identical(retained, index)) await _publishIndex(root, retained);
      return LocalHistoryCaptureResult(document: document, revision: summary);
    });
  });

  @override
  Future<LocalHistoryRevision?> readRevision(String revisionId) => _serialized(
    (root) => _withFileLock(root, () async {
      final index = await _loadIndexUnlocked(root, repair: true);
      final summary = index.revisions
          .where((candidate) => candidate.id == revisionId)
          .firstOrNull;
      if (summary == null) return null;
      final document = index.documents
          .where((candidate) => candidate.id == summary.documentId)
          .firstOrNull;
      if (document == null) return null;
      return _readRevisionFile(
        _revisionFile(root, document.id, summary.id),
        expected: summary,
      );
    }),
  );

  @override
  Future<void> prune(LocalHistoryPolicy policy, DateTime now) => _serialized(
    (root) => _withFileLock(root, () async {
      policy.validate();
      final index = await _loadIndexUnlocked(root, repair: true);
      final retained = await _applyRetention(
        root,
        index,
        policy,
        null,
        now.toUtc(),
      );
      if (!identical(retained, index)) await _publishIndex(root, retained);
    }),
  );

  @override
  Future<LocalHistoryDocument?> promoteUntitledDocument({
    required String documentId,
    required String destinationPath,
    required String displayName,
    required DateTime updatedAt,
  }) => _serialized((root) async {
    return _withFileLock(root, () async {
      final index = await _loadIndexUnlocked(root, repair: true);
      final document = index.documents
          .where((candidate) => candidate.id == documentId)
          .firstOrNull;
      if (document == null) return null;
      final destination = p.normalize(destinationPath);
      if (document.currentPath != null) {
        return p.equals(document.currentPath!, destination) ? document : null;
      }
      if (!document.untitled) return null;
      final destinationOwner = index.documents
          .where(
            (candidate) =>
                candidate.id != document.id &&
                candidate.currentPath != null &&
                p.equals(candidate.currentPath!, destination),
          )
          .firstOrNull;
      if (destinationOwner != null) return null;
      final promoted = document.copyWith(
        displayName: displayName,
        currentPath: destination,
        historicalPaths: _uniquePaths([
          ...document.historicalPaths,
          destination,
        ]),
        updatedAt: updatedAt.toUtc(),
        deleted: false,
        untitled: false,
      );
      await _publishIndex(root, index.withDocument(promoted));
      return promoted;
    });
  });

  @override
  Future<void> remapPath(String sourcePath, String destinationPath) =>
      _mutateDocuments((document) {
        final current = document.currentPath;
        if (current == null) return document;
        final mapped = _remap(current, sourcePath, destinationPath);
        if (mapped == null) return document;
        return document.copyWith(
          currentPath: mapped,
          displayName: p.basename(mapped),
          historicalPaths: _uniquePaths([
            ...document.historicalPaths,
            current,
            mapped,
          ]),
          deleted: false,
          updatedAt: DateTime.now().toUtc(),
        );
      });

  @override
  Future<void> markDeleted(String path, {required bool recursive}) =>
      _mutateDocuments((document) {
        final current = document.currentPath;
        if (current == null ||
            !(p.equals(current, path) ||
                (recursive && p.isWithin(path, current)))) {
          return document;
        }
        return document.copyWith(
          deleted: true,
          updatedAt: DateTime.now().toUtc(),
        );
      });

  Future<void> _mutateDocuments(
    LocalHistoryDocument Function(LocalHistoryDocument) mutate,
  ) => _serialized(
    (root) => _withFileLock(root, () async {
      final index = await _loadIndexUnlocked(root, repair: true);
      final documents = [
        for (final document in index.documents) mutate(document),
      ];
      await _publishIndex(root, index.copyWith(documents: documents));
    }),
  );

  @override
  Future<void> clearDocument(String documentId) => _serialized(
    (root) => _withFileLock(root, () async {
      var index = await _loadIndexUnlocked(root, repair: true);
      final removed = {
        for (final revision in index.revisions)
          if (revision.documentId == documentId) revision.id,
      };
      index = index.copyWith(
        documents: [
          for (final document in index.documents)
            if (document.id != documentId) document,
        ],
        revisions: [
          for (final revision in index.revisions)
            if (revision.documentId != documentId) revision,
        ],
        tombstones: {...index.tombstones, ...removed},
      );
      await _publishIndex(root, index);
      await _deleteDirectoryBestEffort(
        Directory(p.join(root.path, 'revisions', documentId)),
      );
    }),
  );

  @override
  Future<void> clearAll() => _serialized(
    (root) => _withFileLock(root, () async {
      final index = await _loadIndexUnlocked(root, repair: true);
      final cleared = _Index(
        documents: const [],
        revisions: const [],
        tombstones: {
          ...index.tombstones,
          for (final revision in index.revisions) revision.id,
        },
      );
      await _publishIndex(root, cleared);
      await _deleteDirectoryBestEffort(
        Directory(p.join(root.path, 'revisions')),
      );
    }),
  );

  Future<T> _serialized<T>(Future<T> Function(Directory root) operation) {
    final completer = Completer<T>();
    _queue = _queue.then<void>((_) async {
      try {
        final root = await _rootDirectory();
        await root.create(recursive: true);
        completer.complete(
          await _serializedForRoot(root, () => operation(root)),
        );
      } on Object catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  static Future<T> _serializedForRoot<T>(
    Directory root,
    Future<T> Function() operation,
  ) {
    final key = p.normalize(root.absolute.path);
    final prior = _rootQueues[key] ?? Future<void>.value();
    final completer = Completer<T>();
    late final Future<void> tail;
    tail = prior
        .then<void>((_) async {
          try {
            completer.complete(await operation());
          } on Object catch (error, stackTrace) {
            completer.completeError(error, stackTrace);
          }
        })
        .whenComplete(() {
          if (identical(_rootQueues[key], tail)) _rootQueues.remove(key);
        });
    _rootQueues[key] = tail;
    return completer.future;
  }

  Future<T> _withFileLock<T>(Directory root, Future<T> Function() body) async {
    final file = File(p.join(root.path, '.store.lock'));
    final lock = await file.open(mode: FileMode.append);
    try {
      await lock.lock(FileLock.exclusive);
      return await body();
    } finally {
      try {
        await lock.unlock();
      } on FileSystemException {
        // Closing releases the lock even after an interrupted lock request.
      }
      await lock.close();
    }
  }

  Future<LocalHistorySnapshot> _loadUnlocked(Directory root) async {
    final index = await _loadIndexUnlocked(root, repair: true);
    return LocalHistorySnapshot(
      documents: List.unmodifiable(index.documents),
      revisions: List.unmodifiable(index.revisions),
      warning: index.warning,
    );
  }

  Future<_Index> _loadIndexUnlocked(
    Directory root, {
    required bool repair,
  }) async {
    final file = File(p.join(root.path, 'index.json'));
    try {
      if (!await file.exists()) {
        return repair ? await _rebuildIndex(root) : const _Index();
      }
      final json = jsonDecode(await file.readAsString());
      if (json is! Map) throw const FormatException('Invalid history index');
      final map = json.cast<String, Object?>();
      if (map['version'] != formatVersion) {
        throw UnsupportedLocalHistoryFormat(map['version']);
      }
      return _Index.fromJson(map);
    } on UnsupportedLocalHistoryFormat {
      rethrow;
    } on Object {
      if (!repair) rethrow;
      final rebuilt = await _rebuildIndex(root);
      await _publishIndex(root, rebuilt);
      return rebuilt.copyWith(
        warning: 'The Local History index was damaged and rebuilt.',
      );
    }
  }

  Future<_Index> _rebuildIndex(Directory root) async {
    final existing = await _readIndexTombstones(root);
    final documents = <String, LocalHistoryDocument>{};
    final revisions = <LocalHistoryRevisionSummary>[];
    final directory = Directory(p.join(root.path, 'revisions'));
    if (!await directory.exists()) return _Index(tombstones: existing);
    await for (final entity in directory.list(recursive: true)) {
      if (entity is! File || p.extension(entity.path) != '.json') continue;
      final relative = p.relative(entity.path, from: directory.path);
      final parts = p.split(relative);
      if (parts.length != 2) continue;
      final documentId = parts[0];
      final revisionId = p.basenameWithoutExtension(parts[1]);
      if (!_validId(documentId) ||
          !_validId(revisionId) ||
          existing.contains(revisionId)) {
        continue;
      }
      try {
        final map = (jsonDecode(await entity.readAsString()) as Map)
            .cast<String, Object?>();
        if (map['version'] != formatVersion) continue;
        final document = LocalHistoryDocument.fromJson(
          (map['document'] as Map).cast<String, Object?>(),
        );
        final summary = LocalHistoryRevisionSummary.fromJson(
          (map['revision'] as Map).cast<String, Object?>(),
        );
        if (document.id != documentId ||
            summary.id != revisionId ||
            summary.documentId != documentId) {
          continue;
        }
        final source = map['source'];
        if (source is! String || sourceChecksum(source) != summary.checksum) {
          continue;
        }
        documents[document.id] = document;
        revisions.add(
          LocalHistoryRevisionSummary(
            id: summary.id,
            documentId: summary.documentId,
            capturedAt: summary.capturedAt,
            reason: summary.reason,
            checksum: summary.checksum,
            storageBytes: await entity.length(),
            sourceLength: summary.sourceLength,
            historicalPath: summary.historicalPath,
          ),
        );
      } on Object {
        // A malformed record cannot invalidate independently intact records.
      }
    }
    return _Index(
      documents: documents.values.toList(growable: false),
      revisions: revisions,
      tombstones: existing,
    );
  }

  Future<Set<String>> _readIndexTombstones(Directory root) async {
    final result = <String>{};
    final journal = File(p.join(root.path, 'tombstones.json'));
    try {
      final values = jsonDecode(await journal.readAsString());
      if (values is List) {
        result.addAll(values.whereType<String>().where(_validId));
      }
    } on Object {
      // A damaged journal does not make intact revision records unreadable.
    }
    final file = File(p.join(root.path, 'index.json'));
    try {
      final map = (jsonDecode(await file.readAsString()) as Map)
          .cast<String, Object?>();
      result.addAll(
        (map['tombstones'] as List?)?.whereType<String>().where(_validId) ??
            const [],
      );
    } on Object {
      // The independent journal remains usable when the index is damaged.
    }
    return result;
  }

  Future<LocalHistoryRevision?> _readRevisionFile(
    File file, {
    required LocalHistoryRevisionSummary expected,
  }) async {
    try {
      final map = (jsonDecode(await file.readAsString()) as Map)
          .cast<String, Object?>();
      if (map['version'] != formatVersion) {
        throw UnsupportedLocalHistoryFormat(map['version']);
      }
      final summary = LocalHistoryRevisionSummary.fromJson(
        (map['revision'] as Map).cast<String, Object?>(),
      );
      final source = map['source'];
      if (summary.id != expected.id ||
          summary.documentId != expected.documentId ||
          source is! String ||
          sourceChecksum(source) != expected.checksum) {
        return null;
      }
      return LocalHistoryRevision(
        summary: expected,
        source: source,
        format: TextFormatMetadata.fromJson(
          (map['format'] as Map).cast<String, Object?>(),
        ),
      );
    } on UnsupportedLocalHistoryFormat {
      rethrow;
    } on Object {
      return null;
    }
  }

  Future<_Index> _applyRetention(
    Directory root,
    _Index index,
    LocalHistoryPolicy policy,
    String? protectedRevisionId,
    DateTime now,
  ) async {
    final cutoff = now.subtract(policy.retentionAge);
    final ordered = [...index.revisions]
      ..sort((left, right) => left.capturedAt.compareTo(right.capturedAt));
    var total = ordered.fold<int>(
      0,
      (value, revision) => value + revision.storageBytes,
    );
    final removed = <String>{};
    for (final revision in ordered) {
      if (revision.id == protectedRevisionId) continue;
      if (revision.capturedAt.isBefore(cutoff) || total > policy.maximumBytes) {
        removed.add(revision.id);
        total -= revision.storageBytes;
      }
    }
    final revisions = [
      for (final revision in index.revisions)
        if (!removed.contains(revision.id)) revision,
    ];
    final retainedDocumentIds = {
      for (final revision in revisions) revision.documentId,
    };
    final documents = [
      for (final document in index.documents)
        if (retainedDocumentIds.contains(document.id)) document,
    ];
    if (removed.isEmpty && documents.length == index.documents.length) {
      return index;
    }
    final retained = index.copyWith(
      documents: documents,
      revisions: revisions,
      tombstones: {...index.tombstones, ...removed},
    );
    // Publish tombstones before cleanup, preventing repair from resurrecting
    // an intentionally evicted record after an interrupted deletion.
    await _publishIndex(root, retained);
    for (final revision in index.revisions) {
      if (!removed.contains(revision.id)) continue;
      await _deleteFileBestEffort(
        _revisionFile(root, revision.documentId, revision.id),
      );
    }
    return retained;
  }

  Future<void> _publishIndex(Directory root, _Index index) async {
    await _publishReplacingFile(
      File(p.join(root.path, 'tombstones.json')),
      const JsonEncoder.withIndent(
        ' ',
      ).convert(index.tombstones.toList()..sort()),
    );
    await _publishReplacingFile(
      File(p.join(root.path, 'index.json')),
      const JsonEncoder.withIndent(' ').convert(index.toJson()),
    );
  }

  Future<void> _publishNewFile(File target, String content) async {
    if (await target.exists()) {
      throw LocalHistoryStorageException('Revision identity collision.');
    }
    final staging = File('${target.path}.staging-${_safeNewId()}');
    try {
      await staging.writeAsString(content, flush: true);
      if (await target.exists()) {
        throw LocalHistoryStorageException('Revision identity collision.');
      }
      await staging.rename(target.path);
    } finally {
      await _deleteFileBestEffort(staging);
    }
  }

  Future<void> _publishReplacingFile(File target, String content) async {
    await target.parent.create(recursive: true);
    final staging = File('${target.path}.staging-${_safeNewId()}');
    try {
      await staging.writeAsString(content, flush: true);
      await staging.rename(target.path);
    } finally {
      await _deleteFileBestEffort(staging);
    }
  }

  String _revisionJson(
    LocalHistoryDocument document,
    LocalHistoryRevisionSummary summary,
    LocalHistoryCaptureRequest request,
  ) => const JsonEncoder.withIndent(' ').convert({
    'version': formatVersion,
    'document': document.toJson(),
    'revision': summary.toJson(),
    'format': request.format.toJson(),
    'source': request.source,
  });

  File _revisionFile(Directory root, String documentId, String revisionId) {
    if (!_validId(documentId) || !_validId(revisionId)) {
      throw const FormatException('Invalid Local History path identity');
    }
    final revisionsRoot = p.normalize(p.join(root.path, 'revisions'));
    final path = p.normalize(
      p.join(revisionsRoot, documentId, '$revisionId.json'),
    );
    if (!p.isWithin(revisionsRoot, path)) {
      throw const FormatException('Local History path escaped its root');
    }
    return File(path);
  }

  String _safeNewId() {
    final value = _createId().replaceAll(RegExp('[^A-Za-z0-9_-]'), '');
    if (!_validId(value)) {
      throw const LocalHistoryStorageException(
        'The Local History identity generator returned an invalid value.',
      );
    }
    return value;
  }
}

class _Index {
  const _Index({
    this.documents = const [],
    this.revisions = const [],
    this.tombstones = const {},
    this.warning,
  });

  final List<LocalHistoryDocument> documents;
  final List<LocalHistoryRevisionSummary> revisions;
  final Set<String> tombstones;
  final String? warning;

  factory _Index.fromJson(Map<String, Object?> json) => _Index(
    documents: [
      for (final value in (json['documents'] as List? ?? const []))
        LocalHistoryDocument.fromJson((value as Map).cast<String, Object?>()),
    ],
    revisions: [
      for (final value in (json['revisions'] as List? ?? const []))
        LocalHistoryRevisionSummary.fromJson(
          (value as Map).cast<String, Object?>(),
        ),
    ],
    tombstones:
        (json['tombstones'] as List?)
            ?.whereType<String>()
            .where(_validId)
            .toSet() ??
        const {},
  );

  _Index copyWith({
    List<LocalHistoryDocument>? documents,
    List<LocalHistoryRevisionSummary>? revisions,
    Set<String>? tombstones,
    String? warning,
  }) => _Index(
    documents: documents ?? this.documents,
    revisions: revisions ?? this.revisions,
    tombstones: tombstones ?? this.tombstones,
    warning: warning ?? this.warning,
  );

  _Index withDocument(LocalHistoryDocument document) => copyWith(
    documents: [
      for (final existing in documents)
        if (existing.id != document.id) existing,
      document,
    ],
  );

  _Index withCapture(
    LocalHistoryDocument document,
    LocalHistoryRevisionSummary revision,
  ) => copyWith(
    documents: [
      for (final existing in documents)
        if (existing.id != document.id) existing,
      document,
    ],
    revisions: [...revisions, revision],
  );

  Map<String, Object?> toJson() => {
    'version': FileLocalHistoryStore.formatVersion,
    'documents': [for (final document in documents) document.toJson()],
    'revisions': [for (final revision in revisions) revision.toJson()],
    'tombstones': tombstones.toList()..sort(),
  };
}

LocalHistoryDocument? _resolveDocument(
  List<LocalHistoryDocument> documents,
  LocalHistoryCaptureRequest request,
) {
  final requestedId = request.documentId;
  if (requestedId != null) {
    final byId = documents.where((document) => document.id == requestedId);
    if (byId.isNotEmpty) return byId.first;
  }
  final path = request.path;
  if (path == null) return null;
  return documents
      .where(
        (document) =>
            document.currentPath != null &&
            p.equals(document.currentPath!, path),
      )
      .firstOrNull;
}

LocalHistoryDocument _updatedDocument(
  LocalHistoryDocument document,
  LocalHistoryCaptureRequest request, {
  required String? path,
  required bool preserveIdentityMetadata,
}) {
  return document.copyWith(
    displayName: preserveIdentityMetadata
        ? document.displayName
        : request.displayName,
    currentPath: path,
    historicalPaths: path == null
        ? document.historicalPaths
        : _uniquePaths([...document.historicalPaths, path]),
    updatedAt: request.capturedAt.toUtc(),
    deleted: false,
    untitled: preserveIdentityMetadata
        ? document.untitled
        : request.untitled && path == null,
  );
}

_CaptureIdentity _captureIdentity(
  LocalHistoryDocument document,
  LocalHistoryCaptureRequest request,
) {
  final boundById =
      request.documentId != null && request.documentId == document.id;
  final pathMismatch = !_sameOptionalPath(document.currentPath, request.path);
  final rejectPathChange =
      boundById && pathMismatch && !request.allowPathChange;
  return _CaptureIdentity(
    path: rejectPathChange ? document.currentPath : request.path,
    pathMismatchWasRejected: rejectPathChange,
  );
}

class _CaptureIdentity {
  const _CaptureIdentity({
    required this.path,
    required this.pathMismatchWasRejected,
  });

  final String? path;
  final bool pathMismatchWasRejected;
}

bool _sameOptionalPath(String? first, String? second) {
  if (first == null || second == null) return first == second;
  return p.equals(first, second);
}

String? _remap(String current, String source, String destination) {
  if (p.equals(current, source)) return p.normalize(destination);
  if (!p.isWithin(source, current)) return null;
  return p.normalize(p.join(destination, p.relative(current, from: source)));
}

List<String> _uniquePaths(Iterable<String> values) {
  final result = <String>[];
  for (final value in values) {
    if (result.every((existing) => !p.equals(existing, value))) {
      result.add(value);
    }
  }
  return List.unmodifiable(result);
}

bool _validId(String value) => RegExp(r'^[A-Za-z0-9_-]{8,80}$').hasMatch(value);

Future<void> _deleteFileBestEffort(File file) async {
  try {
    if (await file.exists()) await file.delete();
  } on FileSystemException {
    // A tombstone prevents a later repair from restoring this entry.
  }
}

Future<void> _deleteDirectoryBestEffort(Directory directory) async {
  try {
    if (await directory.exists()) await directory.delete(recursive: true);
  } on FileSystemException {
    // A tombstone prevents a later repair from restoring these entries.
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class MemoryLocalHistoryStore implements LocalHistoryStore {
  final _documents = <String, LocalHistoryDocument>{};
  final _revisions = <String, LocalHistoryRevision>{};
  var _sequence = 0;

  String _id(String prefix) =>
      '$prefix${(++_sequence).toString().padLeft(12, '0')}';

  @override
  Future<LocalHistorySnapshot> load() async => LocalHistorySnapshot(
    documents: List.unmodifiable(_documents.values),
    revisions: List.unmodifiable(
      _revisions.values.map((revision) => revision.summary),
    ),
  );

  @override
  Future<LocalHistoryCaptureResult> capture(
    LocalHistoryCaptureRequest request,
    LocalHistoryPolicy policy,
  ) async {
    policy.validate();
    var document = _resolveDocument(_documents.values.toList(), request);
    document ??= LocalHistoryDocument(
      id: _id('document_'),
      displayName: request.displayName,
      currentPath: request.path,
      historicalPaths: request.path == null ? const [] : [request.path!],
      updatedAt: request.capturedAt.toUtc(),
      untitled: request.untitled,
    );
    final identity = _captureIdentity(document, request);
    document = _updatedDocument(
      document,
      request,
      path: identity.path,
      preserveIdentityMetadata: identity.pathMismatchWasRejected,
    );
    _documents[document.id] = document;
    final checksum = sourceChecksum(request.source);
    final adjacent = _revisions.values
        .where((revision) => revision.summary.documentId == document!.id)
        .map((revision) => revision.summary)
        .fold<LocalHistoryRevisionSummary?>(
          null,
          (latest, revision) =>
              latest == null || revision.capturedAt.isAfter(latest.capturedAt)
              ? revision
              : latest,
        );
    if (!request.force && adjacent?.checksum == checksum) {
      return LocalHistoryCaptureResult(
        document: document,
        revision: adjacent,
        deduplicated: true,
      );
    }
    final bytes = utf8.encode(request.source).length + 256;
    if (bytes > policy.maximumBytes) {
      throw const LocalHistoryStorageException(
        'The revision is larger than the Local History storage limit.',
      );
    }
    final summary = LocalHistoryRevisionSummary(
      id: _id('revision_'),
      documentId: document.id,
      capturedAt: request.capturedAt.toUtc(),
      reason: request.reason,
      checksum: checksum,
      storageBytes: bytes,
      sourceLength: request.source.length,
      historicalPath: identity.path,
    );
    _revisions[summary.id] = LocalHistoryRevision(
      summary: summary,
      source: request.source,
      format: request.format,
    );
    _applyMemoryRetention(policy, request.capturedAt.toUtc(), summary.id);
    return LocalHistoryCaptureResult(document: document, revision: summary);
  }

  void _applyMemoryRetention(
    LocalHistoryPolicy policy,
    DateTime now,
    String protectedId,
  ) {
    final ordered = _revisions.values.toList()
      ..sort(
        (left, right) =>
            left.summary.capturedAt.compareTo(right.summary.capturedAt),
      );
    var total = ordered.fold<int>(
      0,
      (value, revision) => value + revision.summary.storageBytes,
    );
    final cutoff = now.subtract(policy.retentionAge);
    for (final revision in ordered) {
      final summary = revision.summary;
      if (summary.id == protectedId) continue;
      if (summary.capturedAt.isBefore(cutoff) || total > policy.maximumBytes) {
        _revisions.remove(summary.id);
        total -= summary.storageBytes;
      }
    }
  }

  @override
  Future<LocalHistoryRevision?> readRevision(String revisionId) async =>
      _revisions[revisionId];

  @override
  Future<void> prune(LocalHistoryPolicy policy, DateTime now) async {
    policy.validate();
    _applyMemoryRetention(policy, now.toUtc(), '');
    final retainedDocumentIds = {
      for (final revision in _revisions.values) revision.summary.documentId,
    };
    _documents.removeWhere((id, _) => !retainedDocumentIds.contains(id));
  }

  @override
  Future<LocalHistoryDocument?> promoteUntitledDocument({
    required String documentId,
    required String destinationPath,
    required String displayName,
    required DateTime updatedAt,
  }) async {
    final document = _documents[documentId];
    if (document == null) return null;
    final destination = p.normalize(destinationPath);
    if (document.currentPath != null) {
      return p.equals(document.currentPath!, destination) ? document : null;
    }
    if (!document.untitled) return null;
    final destinationOwner = _documents.values
        .where(
          (candidate) =>
              candidate.id != document.id &&
              candidate.currentPath != null &&
              p.equals(candidate.currentPath!, destination),
        )
        .firstOrNull;
    if (destinationOwner != null) return null;
    final promoted = document.copyWith(
      displayName: displayName,
      currentPath: destination,
      historicalPaths: _uniquePaths([...document.historicalPaths, destination]),
      updatedAt: updatedAt.toUtc(),
      deleted: false,
      untitled: false,
    );
    _documents[documentId] = promoted;
    return promoted;
  }

  @override
  Future<void> remapPath(String sourcePath, String destinationPath) async {
    for (final entry in _documents.entries.toList()) {
      final current = entry.value.currentPath;
      final mapped = current == null
          ? null
          : _remap(current, sourcePath, destinationPath);
      if (mapped != null) {
        _documents[entry.key] = entry.value.copyWith(
          currentPath: mapped,
          displayName: p.basename(mapped),
          historicalPaths: _uniquePaths([
            ...entry.value.historicalPaths,
            current!,
            mapped,
          ]),
          deleted: false,
        );
      }
    }
  }

  @override
  Future<void> markDeleted(String path, {required bool recursive}) async {
    for (final entry in _documents.entries.toList()) {
      final current = entry.value.currentPath;
      if (current != null &&
          (p.equals(current, path) ||
              (recursive && p.isWithin(path, current)))) {
        _documents[entry.key] = entry.value.copyWith(deleted: true);
      }
    }
  }

  @override
  Future<void> clearDocument(String documentId) async {
    _documents.remove(documentId);
    _revisions.removeWhere(
      (_, revision) => revision.summary.documentId == documentId,
    );
  }

  @override
  Future<void> clearAll() async {
    _documents.clear();
    _revisions.clear();
  }
}
