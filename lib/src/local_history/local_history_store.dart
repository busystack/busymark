import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'local_history_models.dart';
import '../workspace/text_format_metadata.dart';

/// Identifies exhausted acquisition contention without confusing EACCES from
/// a contended Linux lock with a permission failure elsewhere in storage.
class LocalHistoryLockTimeout extends FileSystemException {
  LocalHistoryLockTimeout(FileSystemException contention)
    : super(
        'Timed out acquiring the Local History store lock',
        contention.path,
        contention.osError,
      );
}

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
  /// [staleDestinationOwner] is only supplied after verifying a retained
  /// successful save against the current file. Its identity and timestamp are
  /// rechecked under the store lock before retiring it in the same index write.
  Future<LocalHistoryDocument?> promoteUntitledDocument({
    required String documentId,
    required String destinationPath,
    required String displayName,
    required DateTime updatedAt,
    LocalHistoryDocument? staleDestinationOwner,
  });

  Future<void> remapPath(String sourcePath, String destinationPath);

  Future<void> markDeleted(String path, {required bool recursive});

  /// Resolves the exact live owners of a path while holding the shared store
  /// lock. The returned version tokens make a later mutation fail closed if
  /// another BusyMark process captures or replaces that lineage first.
  Future<List<LocalHistoryPathTarget>> resolvePathTargets(
    String path, {
    required bool recursive,
  });

  /// Freezes the current path owners under the shared store lock, keeps that
  /// lock while [operation] commits the corresponding filesystem mutation,
  /// and publishes the identity-targeted history mutation before releasing
  /// the lock. This prevents another BusyMark process from inserting a new
  /// owner between target discovery and the filesystem operation.
  Future<T> runPathReconciliation<T>({
    required LocalHistoryPathReconciliationKind kind,
    required String sourcePath,
    String? destinationPath,
    required bool recursive,
    Iterable<LocalHistoryPathTarget>? preparedTargets,
    required Future<T> Function(List<LocalHistoryPathTarget> targets) operation,
    required bool Function(T result) didCommit,
  }) async {
    final targets = List<LocalHistoryPathTarget>.unmodifiable(
      preparedTargets ??
          await resolvePathTargets(sourcePath, recursive: recursive),
    );
    final result = await operation(targets);
    if (!didCommit(result)) return result;
    await reconcilePath(switch (kind) {
      LocalHistoryPathReconciliationKind.remap =>
        LocalHistoryPathReconciliation.remap(
          sourcePath: sourcePath,
          destinationPath: destinationPath!,
          targets: targets,
        ),
      LocalHistoryPathReconciliationKind.deletion =>
        LocalHistoryPathReconciliation.deletion(
          sourcePath: sourcePath,
          recursive: recursive,
          targets: targets,
        ),
    });
    return result;
  }

  /// Applies a path mutation only to the stable document identities captured
  /// when the corresponding filesystem operation committed.
  Future<void> reconcilePath(LocalHistoryPathReconciliation reconciliation);

  Future<void> clearDocument(String documentId);

  Future<void> clearAll();

  /// Replays a durable clear journal without applying the same clear twice.
  ///
  /// Implementations backed by shared durable storage must make the operation
  /// identity check atomic with the clear. The default preserves compatibility
  /// for focused test stores that do not provide crash recovery.
  Future<void> clearDocumentOnce({
    required String operationId,
    required String documentId,
  }) => clearDocument(documentId);

  Future<void> clearAllOnce({required String operationId}) => clearAll();
}

class FileLocalHistoryStore implements LocalHistoryStore {
  FileLocalHistoryStore({
    Future<Directory> Function()? rootDirectory,
    String Function()? createId,
  }) : _rootDirectory = rootDirectory ?? _defaultRootDirectory,
       _createId = createId ?? const Uuid().v4,
       _lockBudget = const Duration(seconds: 30),
       _lockDelay = const Duration(milliseconds: 10),
       _acquireLock = _lockExclusive;

  /// Test seam for short deadlines and acquisition fault/progress injection.
  /// The transaction and handle lifecycle always use the production path.
  @visibleForTesting
  FileLocalHistoryStore.testing({
    required Future<Directory> Function() rootDirectory,
    String Function()? createId,
    Duration lockBudget = const Duration(seconds: 30),
    Duration lockDelay = const Duration(milliseconds: 10),
    Future<void> Function(RandomAccessFile)? acquireLock,
  }) : _rootDirectory = rootDirectory,
       _createId = createId ?? const Uuid().v4,
       _lockBudget = lockBudget,
       _lockDelay = lockDelay,
       _acquireLock = acquireLock ?? _lockExclusive;

  static const formatVersion = 1;
  final Future<Directory> Function() _rootDirectory;
  final String Function() _createId;
  final Duration _lockBudget;
  final Duration _lockDelay;
  final Future<void> Function(RandomAccessFile) _acquireLock;
  Future<void> _queue = Future<void>.value();
  static final Map<String, Future<void>> _rootQueues = {};

  static Future<Directory> _defaultRootDirectory() async {
    final support = await getApplicationSupportDirectory();
    return Directory(p.join(support.path, 'local_history'));
  }

  @override
  Future<LocalHistorySnapshot> load() => _serialized(
    (root) => _withFileLock(root, () async {
      return _loadUnlocked(root);
    }),
  );

  @override
  Future<LocalHistoryCaptureResult> capture(
    LocalHistoryCaptureRequest request,
    LocalHistoryPolicy policy,
  ) {
    return _serialized((root) async {
      policy.validate();
      return _withFileLock(root, () async {
        _requireCaptureStillAccepted(request);
        final currentClearEpoch = await _readClearEpoch(root);
        final acceptedEpoch = request.acceptedClearEpoch;
        final acceptedAt = request.acceptedAt;
        if (acceptedAt != null &&
            acceptedEpoch != currentClearEpoch &&
            await _hasRelevantClearAfter(root, request, acceptedAt)) {
          throw const LocalHistoryClearConflict();
        }
        if (acceptedAt == null &&
            acceptedEpoch != null &&
            acceptedEpoch != currentClearEpoch) {
          throw const LocalHistoryClearConflict();
        }
        var index = await _loadIndexUnlocked(root, repair: true);
        final originalIndex = index;
        final checksum = sourceChecksum(request.source);
        // A durable capture identity represents the already-accepted write.
        // Resolve it before path vacancy/ownership checks: after a successful
        // publication the capture itself may have occupied or detached the
        // path that the original request was required to validate.
        if (request.captureId case final captureId?) {
          if (!_validId(captureId)) {
            throw const LocalHistoryStorageException(
              'Invalid Local History capture identity.',
            );
          }
          if (index.tombstones.contains(captureId)) {
            throw const LocalHistoryClearConflict();
          }
          final existing = index.revisions
              .where((revision) => revision.id == captureId)
              .firstOrNull;
          if (existing != null) {
            final document = index.documents
                .where((candidate) => candidate.id == existing.documentId)
                .firstOrNull;
            final revision = await _readRevisionFile(
              _revisionFile(root, existing.documentId, existing.id),
              expected: existing,
            );
            if (document == null ||
                existing.checksum != checksum ||
                revision == null ||
                revision.source != request.source ||
                !_sameTextFormat(revision.format, request.format)) {
              throw const LocalHistoryStorageException(
                'Local History capture identity collision.',
              );
            }
            if (request.documentId case final documentId?
                when documentId != document.id) {
              throw const LocalHistoryReconciliationConflict();
            }
            if (request.expectedTarget case final target?
                when target.documentId != document.id) {
              throw const LocalHistoryReconciliationConflict();
            }
            _requireCaptureStillAccepted(request);
            return LocalHistoryCaptureResult(
              document: document,
              revision: existing,
              deduplicated: true,
            );
          }
        }
        if (request.expectedTarget case final target?) {
          final expected = index.documents
              .where((document) => document.id == target.documentId)
              .firstOrNull;
          if (expected == null ||
              expected.deleted ||
              expected.currentPath == null ||
              !p.equals(expected.currentPath!, target.expectedPath) ||
              _documentVersionToken(expected, index.revisions) !=
                  target.versionToken) {
            throw const LocalHistoryReconciliationConflict();
          }
        }
        var document = _resolveDocument(index.documents, request);
        document ??= LocalHistoryDocument(
          id: request.remoteDocumentId ?? _safeNewId(),
          displayName: request.displayName,
          currentPath: request.createDetachedLineage ? null : request.path,
          historicalPaths: request.path == null ? const [] : [request.path!],
          updatedAt: request.capturedAt.toUtc(),
          untitled: request.untitled,
          remoteNote: request.remoteNote,
        );
        final identity = _captureIdentity(document, request);
        document = _updatedDocument(
          document,
          request,
          path: identity.path,
          preserveIdentityMetadata: identity.pathMismatchWasRejected,
        );
        final adjacent = index.revisions
            .where((revision) => revision.documentId == document!.id)
            .fold<LocalHistoryRevisionSummary?>(
              null,
              (latest, revision) =>
                  latest == null ||
                      revision.capturedAt.isAfter(latest.capturedAt)
                  ? revision
                  : latest,
            );
        if (!request.force && adjacent?.checksum == checksum) {
          final adjacentRevision = await _readRevisionFile(
            _revisionFile(root, document.id, adjacent!.id),
            expected: adjacent,
          );
          if (adjacentRevision != null &&
              _sameTextFormat(adjacentRevision.format, request.format)) {
            _requireCaptureStillAccepted(request);
            index = index.withDocument(document);
            await _publishIndex(root, index);
            if (!_captureStillAccepted(request)) {
              await _publishIndex(root, originalIndex);
              throw const LocalHistoryCaptureCancelled();
            }
            return LocalHistoryCaptureResult(
              document: document,
              revision: adjacent,
              deduplicated: true,
            );
          }
        }
        final estimatedBytes = utf8.encode(request.source).length + 2048;
        if (estimatedBytes > policy.maximumBytes) {
          throw const LocalHistoryStorageException(
            'The revision is larger than the Local History storage limit.',
          );
        }
        final revisionId = request.captureId ?? _safeNewId();
        var summary = LocalHistoryRevisionSummary(
          id: revisionId,
          documentId: document.id,
          capturedAt: request.capturedAt.toUtc(),
          reason: request.reason,
          checksum: checksum,
          storageBytes: 0,
          sourceLength: request.source.length,
          historicalPath: request.createDetachedLineage
              ? request.path
              : identity.path,
        );
        final target = _revisionFile(root, document.id, revisionId);
        await target.parent.create(recursive: true);
        final encoded = _revisionJson(document, summary, request);
        _requireCaptureStillAccepted(request);
        await _publishNewFile(target, encoded);
        if (!_captureStillAccepted(request)) {
          await _publishIndex(
            root,
            originalIndex.copyWith(
              tombstones: {...originalIndex.tombstones, revisionId},
            ),
          );
          await _deleteFileBestEffort(target);
          throw const LocalHistoryCaptureCancelled();
        }
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
        if (!_captureStillAccepted(request)) {
          await _publishIndex(
            root,
            originalIndex.copyWith(
              tombstones: {...originalIndex.tombstones, revisionId},
            ),
          );
          await _deleteFileBestEffort(target);
          throw const LocalHistoryCaptureCancelled();
        }
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
  }

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
    LocalHistoryDocument? staleDestinationOwner,
  }) => _serialized((root) async {
    return _withFileLock(root, () async {
      var index = await _loadIndexUnlocked(root, repair: true);
      final document = index.documents
          .where((candidate) => candidate.id == documentId)
          .firstOrNull;
      if (document == null) return null;
      final destination = p.normalize(destinationPath);
      if (document.currentPath != null) {
        return p.equals(document.currentPath!, destination) ||
                !document.untitled &&
                    document.historicalPaths.any(
                      (path) => p.equals(path, destination),
                    )
            ? document
            : null;
      }
      if (!document.untitled) return null;
      final destinationOwner = index.documents
          .where(
            (candidate) =>
                candidate.id != document.id &&
                _ownsActivePath(candidate, destination),
          )
          .firstOrNull;
      if (destinationOwner != null) {
        if (!_canRetirePromotionOwner(
          document,
          destinationOwner,
          staleDestinationOwner,
        )) {
          return null;
        }
        index = index.withDocument(destinationOwner.copyWith(deleted: true));
      }
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
        if (document.deleted) return document;
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

  @override
  Future<List<LocalHistoryPathTarget>> resolvePathTargets(
    String path, {
    required bool recursive,
  }) => _serialized(
    (root) => _withFileLock(root, () async {
      final index = await _loadIndexUnlocked(root, repair: true);
      return _resolvePathTargets(index, path, recursive: recursive);
    }),
  );

  @override
  Future<T> runPathReconciliation<T>({
    required LocalHistoryPathReconciliationKind kind,
    required String sourcePath,
    String? destinationPath,
    required bool recursive,
    Iterable<LocalHistoryPathTarget>? preparedTargets,
    required Future<T> Function(List<LocalHistoryPathTarget> targets) operation,
    required bool Function(T result) didCommit,
  }) => _serialized(
    (root) => _withFileLock(root, () async {
      final index = await _loadIndexUnlocked(root, repair: true);
      final targets = List<LocalHistoryPathTarget>.unmodifiable(
        preparedTargets ??
            _resolvePathTargets(index, sourcePath, recursive: recursive),
      );
      if (preparedTargets != null) {
        final currentTargets = _resolvePathTargets(
          index,
          sourcePath,
          recursive: recursive,
        );
        final preparedById = {
          for (final target in targets) target.documentId: target,
        };
        if (targets.isNotEmpty &&
            currentTargets.any((current) {
              final prepared = preparedById[current.documentId];
              return prepared == null ||
                  !p.equals(prepared.expectedPath, current.expectedPath) ||
                  prepared.versionToken != current.versionToken;
            })) {
          throw const LocalHistoryReconciliationConflict();
        }
      }
      final reconciliation = switch (kind) {
        LocalHistoryPathReconciliationKind.remap =>
          LocalHistoryPathReconciliation.remap(
            sourcePath: sourcePath,
            destinationPath: destinationPath!,
            targets: targets,
          ),
        LocalHistoryPathReconciliationKind.deletion =>
          LocalHistoryPathReconciliation.deletion(
            sourcePath: sourcePath,
            recursive: recursive,
            targets: targets,
          ),
      };
      // Validate frozen identities while the lock is held. The shared
      // reconciliation helper also recognizes this exact operation when
      // another process already applied it, without accepting a replacement
      // owner at the source or destination.
      final documents = _reconcileDocuments(index, reconciliation);
      final result = await operation(targets);
      if (!didCommit(result)) return result;
      await _publishIndex(root, index.copyWith(documents: documents));
      return result;
    }),
  );

  @override
  Future<void> reconcilePath(LocalHistoryPathReconciliation reconciliation) =>
      _serialized(
        (root) => _withFileLock(root, () async {
          final index = await _loadIndexUnlocked(root, repair: true);
          final documents = _reconcileDocuments(index, reconciliation);
          await _publishIndex(root, index.copyWith(documents: documents));
        }),
      );

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
  Future<void> clearDocument(String documentId) =>
      clearDocumentOnce(operationId: _safeNewId(), documentId: documentId);

  @override
  Future<void> clearDocumentOnce({
    required String operationId,
    required String documentId,
  }) => _serialized(
    (root) => _withFileLock(root, () async {
      final intent = _ClearIntent(
        operationId: operationId,
        documentId: documentId,
      );
      if (await _clearCompletionMatches(root, intent)) return;
      await _writeClearIntent(root, intent);
      await _applyClearIntentUnlocked(root, intent);
    }),
  );

  @override
  Future<void> clearAll() => clearAllOnce(operationId: _safeNewId());

  @override
  Future<void> clearAllOnce({required String operationId}) => _serialized(
    (root) => _withFileLock(root, () async {
      final intent = _ClearIntent(operationId: operationId);
      if (await _clearCompletionMatches(root, intent)) return;
      await _writeClearIntent(root, intent);
      await _applyClearIntentUnlocked(root, intent);
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
    var acquired = false;
    Object? primaryError;
    try {
      final deadline = Stopwatch()..start();
      while (true) {
        try {
          await _acquireLock(lock);
          acquired = true;
          break;
        } on FileSystemException catch (error) {
          if (!_isLockContention(error)) rethrow;
          final remaining = _lockBudget - deadline.elapsed;
          if (remaining <= Duration.zero) throw LocalHistoryLockTimeout(error);
          await Future<void>.delayed(
            remaining < _lockDelay ? remaining : _lockDelay,
          );
          if (deadline.elapsed >= _lockBudget) {
            throw LocalHistoryLockTimeout(error);
          }
        }
      }
      await _recoverClearIntentUnlocked(root);
      return await body();
    } on Object catch (error) {
      primaryError = error;
      rethrow;
    } finally {
      Object? cleanupError;
      StackTrace? cleanupStack;
      try {
        if (acquired) await lock.unlock();
      } on Object catch (error, stack) {
        cleanupError = error;
        cleanupStack = stack;
      }
      try {
        await lock.close();
      } on Object catch (error, stack) {
        cleanupError ??= error;
        cleanupStack ??= stack;
      }
      if (primaryError == null && cleanupError != null) {
        Error.throwWithStackTrace(cleanupError, cleanupStack!);
      }
    }
  }

  Future<String> _readClearEpoch(Directory root) async {
    final file = File(p.join(root.path, '.clear-epoch'));
    try {
      final value = (await file.readAsString()).trim();
      if (value.isNotEmpty) return value;
    } on FileSystemException {
      // The initial epoch is established while the store lock is held.
    }
    return '';
  }

  Future<void> _writeClearEpoch(Directory root, String value) async {
    final file = File(p.join(root.path, '.clear-epoch'));
    await _publishReplacingFile(file, value);
  }

  File _clearIntentFile(Directory root) =>
      File(p.join(root.path, '.clear-intent.json'));

  File _clearCompletionFile(Directory root, String operationId) {
    final encoded = base64Url
        .encode(utf8.encode(operationId))
        .replaceAll('=', '');
    return File(p.join(root.path, '.clear-completions', '$encoded.done'));
  }

  Future<bool> _clearCompletionMatches(
    Directory root,
    _ClearIntent intent,
  ) async {
    final operationId = intent.operationId;
    if (!_validClearOperationId(operationId)) {
      throw const LocalHistoryStorageException(
        'Invalid Local History clear identity.',
      );
    }
    final file = _clearCompletionFile(root, operationId);
    if (!await file.exists()) return false;
    try {
      final value = jsonDecode(await file.readAsString());
      if (value is! Map) throw const FormatException();
      final completed = _ClearIntent.fromJson(value.cast<String, Object?>());
      if (completed.documentId != intent.documentId) {
        throw const LocalHistoryStorageException(
          'Local History clear identity collision.',
        );
      }
      return true;
    } on LocalHistoryStorageException {
      rethrow;
    } on Object {
      throw const LocalHistoryStorageException(
        'The Local History clear completion journal is damaged.',
      );
    }
  }

  Future<void> _writeClearCompletion(Directory root, _ClearIntent intent) =>
      _publishReplacingFile(
        _clearCompletionFile(root, intent.operationId),
        jsonEncode({
          ...intent.toJson(),
          'completedAt': DateTime.now().toUtc().toIso8601String(),
        }),
      );

  Future<bool> _hasRelevantClearAfter(
    Directory root,
    LocalHistoryCaptureRequest request,
    DateTime acceptedAt,
  ) async {
    final directory = Directory(p.join(root.path, '.clear-completions'));
    if (!await directory.exists()) return false;
    await for (final entity in directory.list()) {
      if (entity is! File) continue;
      try {
        final value = jsonDecode(await entity.readAsString());
        if (value is! Map) continue;
        final map = value.cast<String, Object?>();
        final completedAtValue = map['completedAt'];
        if (completedAtValue == null) continue;
        final completedAt = DateTime.parse(completedAtValue.toString()).toUtc();
        if (completedAt.isBefore(acceptedAt.toUtc())) continue;
        final intent = _ClearIntent.fromJson(map);
        if (intent.documentId == null ||
            intent.documentId == request.documentId ||
            intent.documentId == request.acceptedDocumentId ||
            (intent.path != null &&
                request.path != null &&
                p.equals(intent.path!, request.path!))) {
          return true;
        }
      } on Object {
        throw const LocalHistoryStorageException(
          'The Local History clear completion journal is damaged.',
        );
      }
    }
    return false;
  }

  Future<void> _writeClearIntent(Directory root, _ClearIntent intent) =>
      _publishReplacingFile(
        _clearIntentFile(root),
        jsonEncode(intent.toJson()),
      );

  Future<void> _recoverClearIntentUnlocked(Directory root) async {
    final file = _clearIntentFile(root);
    if (!await file.exists()) return;
    final value = jsonDecode(await file.readAsString());
    if (value is! Map) {
      throw const LocalHistoryStorageException(
        'The Local History clear journal is damaged.',
      );
    }
    final intent = _ClearIntent.fromJson(value.cast<String, Object?>());
    if (await _clearCompletionMatches(root, intent)) {
      await _deleteFileBestEffort(file);
      return;
    }
    await _applyClearIntentUnlocked(root, intent);
  }

  Future<void> _applyClearIntentUnlocked(
    Directory root,
    _ClearIntent intent,
  ) async {
    var index = await _loadIndexUnlocked(root, repair: true);
    var effectiveIntent = intent;
    final documentId = effectiveIntent.documentId;
    if (documentId != null && effectiveIntent.path == null) {
      final document = index.documents
          .where((candidate) => candidate.id == documentId)
          .firstOrNull;
      final documentPath = document?.currentPath;
      final pathHasReplacement =
          documentPath != null &&
          index.documents.any(
            (candidate) =>
                candidate.id != documentId &&
                !candidate.deleted &&
                candidate.currentPath != null &&
                p.equals(candidate.currentPath!, documentPath),
          );
      if (documentPath != null && !pathHasReplacement) {
        effectiveIntent = effectiveIntent.withPath(documentPath);
        await _writeClearIntent(root, effectiveIntent);
      }
    }
    await _writeClearEpoch(root, effectiveIntent.operationId);
    if (documentId == null) {
      index = _Index(
        documents: const [],
        revisions: const [],
        tombstones: {
          ...index.tombstones,
          for (final revision in index.revisions) revision.id,
        },
      );
      await _publishIndex(root, index);
      await _deleteDirectoryBestEffort(
        Directory(p.join(root.path, 'revisions')),
      );
    } else {
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
    }
    // Keep an operation-specific completion marker after the shared mutation
    // commits. A restored session may still contain the clear if the process
    // stopped before retiring its journal. The marker makes that replay a
    await _writeClearCompletion(root, effectiveIntent);
    await _deleteFileBestEffort(_clearIntentFile(root));
  }

  static Future<void> _lockExclusive(RandomAccessFile file) =>
      file.lock(FileLock.exclusive);

  static bool _isLockContention(FileSystemException error) {
    // Dart uses fcntl(F_SETLK) on Linux (EAGAIN/EACCES), and
    // LockFileEx(LOCKFILE_FAIL_IMMEDIATELY) on Windows (ERROR_LOCK_VIOLATION).
    // These codes are recognized only at acquisition, never in the body.
    final code = error.osError?.errorCode;
    if (Platform.isLinux) return code == 11 || code == 13;
    if (Platform.isWindows) return code == 33;
    return false;
  }

  Future<LocalHistorySnapshot> _loadUnlocked(Directory root) async {
    final index = await _loadIndexUnlocked(root, repair: true);
    return LocalHistorySnapshot(
      documents: List.unmodifiable(index.documents),
      revisions: List.unmodifiable(index.revisions),
      warning: index.warning,
      clearEpoch: await _readClearEpoch(root),
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

class _ClearIntent {
  const _ClearIntent({required this.operationId, this.documentId, this.path});

  final String operationId;
  final String? documentId;
  final String? path;

  _ClearIntent withPath(String value) => _ClearIntent(
    operationId: operationId,
    documentId: documentId,
    path: p.normalize(value),
  );

  Map<String, Object?> toJson() => {
    'operationId': operationId,
    'documentId': documentId,
    'path': path,
  };

  factory _ClearIntent.fromJson(Map<String, Object?> json) {
    final operationId = json['operationId']?.toString() ?? '';
    final documentId = json['documentId']?.toString();
    final path = json['path']?.toString();
    if (!_validClearOperationId(operationId) ||
        (documentId != null && !_validId(documentId))) {
      throw const LocalHistoryStorageException(
        'The Local History clear journal is damaged.',
      );
    }
    return _ClearIntent(
      operationId: operationId,
      documentId: documentId,
      path: path,
    );
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
  if (request.createDetachedLineage) return null;
  final requestedId = request.documentId;
  if (requestedId != null) {
    final byId = documents.where((document) => document.id == requestedId);
    if (byId.isEmpty) {
      throw const LocalHistoryReconciliationConflict();
    }
    return byId.first;
  }
  if (request.remoteDocumentId case final remoteDocumentId?) {
    return documents
        .where((document) => document.id == remoteDocumentId)
        .firstOrNull;
  }
  final path = request.path;
  if (path == null) return null;
  final pathOwner = documents
      .where((document) => _ownsActivePath(document, path))
      .firstOrNull;
  if (request.requireVacantPath && pathOwner != null) {
    throw const LocalHistoryReconciliationConflict();
  }
  return pathOwner;
}

// The controller verifies the successfully saved bytes before requesting this
// repair. Recheck the exact owner under the store lock: a later capture or a
// different owner must not be retired by an old session's promotion retry.
bool _canRetirePromotionOwner(
  LocalHistoryDocument document,
  LocalHistoryDocument owner,
  LocalHistoryDocument? expectedOwner,
) =>
    expectedOwner != null &&
    owner.id == expectedOwner.id &&
    owner.updatedAt == expectedOwner.updatedAt &&
    owner.updatedAt.isBefore(document.updatedAt);

bool _ownsActivePath(LocalHistoryDocument document, String path) =>
    !document.deleted &&
    document.currentPath != null &&
    p.equals(document.currentPath!, path);

bool _sameTextFormat(TextFormatMetadata left, TextFormatMetadata right) =>
    left.hasUtf8Bom == right.hasUtf8Bom &&
    left.lineEnding == right.lineEnding &&
    left.hasFinalNewline == right.hasFinalNewline &&
    left.lfCount == right.lfCount &&
    left.crlfCount == right.crlfCount &&
    left.crCount == right.crCount;

LocalHistoryDocument _updatedDocument(
  LocalHistoryDocument document,
  LocalHistoryCaptureRequest request, {
  required String? path,
  required bool preserveIdentityMetadata,
}) {
  final preserveDeletedIdentity =
      document.deleted && request.documentId == document.id;
  return document.copyWith(
    displayName: preserveIdentityMetadata || preserveDeletedIdentity
        ? document.displayName
        : request.displayName,
    currentPath: preserveDeletedIdentity ? document.currentPath : path,
    historicalPaths: path == null || preserveDeletedIdentity
        ? document.historicalPaths
        : _uniquePaths([...document.historicalPaths, path]),
    updatedAt: request.capturedAt.toUtc(),
    deleted: preserveDeletedIdentity,
    untitled: preserveIdentityMetadata || preserveDeletedIdentity
        ? document.untitled
        : request.untitled && path == null,
  );
}

_CaptureIdentity _captureIdentity(
  LocalHistoryDocument document,
  LocalHistoryCaptureRequest request,
) {
  if (request.createDetachedLineage) {
    return const _CaptureIdentity(path: null, pathMismatchWasRejected: true);
  }
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

LocalHistoryDocument _reconcileRemap(
  LocalHistoryDocument document,
  String source,
  String destination,
) {
  if (document.deleted || document.currentPath == null) return document;
  final mapped = _remap(document.currentPath!, source, destination);
  if (mapped == null) return document;
  return document.copyWith(
    currentPath: mapped,
    displayName: p.basename(mapped),
    historicalPaths: _uniquePaths([
      ...document.historicalPaths,
      document.currentPath!,
      mapped,
    ]),
  );
}

LocalHistoryDocument _reconcileDeletion(
  LocalHistoryDocument document,
  String path,
  bool recursive,
) {
  final current = document.currentPath;
  if (current == null ||
      !(p.equals(current, path) || recursive && p.isWithin(path, current))) {
    return document;
  }
  return document.copyWith(deleted: true);
}

List<LocalHistoryPathTarget> _resolvePathTargets(
  _Index index,
  String path, {
  required bool recursive,
}) {
  final normalized = p.normalize(path);
  return List.unmodifiable([
    for (final document in index.documents)
      if (!document.deleted &&
          document.currentPath != null &&
          (p.equals(document.currentPath!, normalized) ||
              recursive && p.isWithin(normalized, document.currentPath!)))
        LocalHistoryPathTarget(
          documentId: document.id,
          expectedPath: document.currentPath!,
          versionToken: _documentVersionToken(document, index.revisions),
        ),
  ]);
}

String _documentVersionToken(
  LocalHistoryDocument document,
  Iterable<LocalHistoryRevisionSummary> revisions,
) => localHistoryDocumentVersionToken(document, revisions);

List<LocalHistoryDocument> _reconcileDocuments(
  _Index index,
  LocalHistoryPathReconciliation reconciliation,
) {
  final current = index.documents.toList(growable: false);
  final targets = {
    for (final target in reconciliation.targets) target.documentId: target,
  };
  final targetIds = targets.keys.toSet();
  for (final target in targets.values) {
    final document = current
        .where((candidate) => candidate.id == target.documentId)
        .firstOrNull;
    if (document == null) continue;
    final alreadyApplied = switch (reconciliation.kind) {
      LocalHistoryPathReconciliationKind.remap => _remapTargetWasApplied(
        document,
        target,
        reconciliation,
      ),
      LocalHistoryPathReconciliationKind.deletion => document.deleted,
    };
    if (alreadyApplied) continue;
    if (document.deleted ||
        document.currentPath == null ||
        !p.equals(document.currentPath!, target.expectedPath) ||
        _documentVersionToken(document, index.revisions) !=
            target.versionToken) {
      throw const LocalHistoryReconciliationConflict();
    }
  }
  if (reconciliation.kind == LocalHistoryPathReconciliationKind.remap) {
    final mappedDestinations = <String>{};
    for (final document in current) {
      if (!targetIds.contains(document.id) ||
          document.deleted ||
          document.currentPath == null) {
        continue;
      }
      final mapped = _remap(
        document.currentPath!,
        reconciliation.sourcePath,
        reconciliation.destinationPath!,
      );
      if (mapped != null) mappedDestinations.add(mapped);
    }
    final replacementOwnsDestination = current.any(
      (document) =>
          !targetIds.contains(document.id) &&
          !document.deleted &&
          document.currentPath != null &&
          mappedDestinations.any(
            (destination) => p.equals(document.currentPath!, destination),
          ),
    );
    if (replacementOwnsDestination) {
      throw const LocalHistoryReconciliationConflict();
    }
  }
  return [
    for (final document in current)
      if (!targetIds.contains(document.id))
        document
      else
        switch (reconciliation.kind) {
          LocalHistoryPathReconciliationKind.remap => _reconcileRemap(
            document,
            targets[document.id]!.expectedPath,
            _remap(
                  targets[document.id]!.expectedPath,
                  reconciliation.sourcePath,
                  reconciliation.destinationPath!,
                ) ??
                targets[document.id]!.expectedPath,
          ),
          LocalHistoryPathReconciliationKind.deletion => _reconcileDeletion(
            document,
            targets[document.id]!.expectedPath,
            false,
          ),
        },
  ];
}

bool _remapTargetWasApplied(
  LocalHistoryDocument document,
  LocalHistoryPathTarget target,
  LocalHistoryPathReconciliation reconciliation,
) {
  final destination = _remap(
    target.expectedPath,
    reconciliation.sourcePath,
    reconciliation.destinationPath!,
  );
  if (destination == null) return false;
  final current = document.currentPath;
  if (!document.deleted && current != null && p.equals(current, destination)) {
    return true;
  }
  // A later identity-targeted move or deletion may already have advanced the
  // same lineage. Its historical destination proves this older operation
  // committed; the stable document ID prevents a replacement lineage from
  // satisfying that evidence.
  return (document.deleted ||
          current == null ||
          !p.equals(current, target.expectedPath)) &&
      document.historicalPaths.any((path) => p.equals(path, destination));
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

bool _validClearOperationId(String value) =>
    value.isNotEmpty &&
    value.length <= 160 &&
    !value.codeUnits.any((unit) => unit < 0x20 || unit == 0x7f);

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

void _requireCaptureStillAccepted(LocalHistoryCaptureRequest request) {
  if (!_captureStillAccepted(request)) {
    throw const LocalHistoryCaptureCancelled();
  }
}

bool _captureStillAccepted(LocalHistoryCaptureRequest request) =>
    request.commitGuard?.call() ?? true;

class MemoryLocalHistoryStore implements LocalHistoryStore {
  final _documents = <String, LocalHistoryDocument>{};
  final _revisions = <String, LocalHistoryRevision>{};
  final _tombstones = <String>{};
  final _clearEvents = <_MemoryClearEvent>[];
  var _clearEpoch = '';
  var _sequence = 0;

  String _id(String prefix) =>
      '$prefix${(++_sequence).toString().padLeft(12, '0')}';

  @override
  Future<LocalHistorySnapshot> load() async => LocalHistorySnapshot(
    documents: List.unmodifiable(_documents.values),
    revisions: List.unmodifiable(
      _revisions.values.map((revision) => revision.summary),
    ),
    clearEpoch: _clearEpoch,
  );

  @override
  Future<LocalHistoryCaptureResult> capture(
    LocalHistoryCaptureRequest request,
    LocalHistoryPolicy policy,
  ) async {
    policy.validate();
    _requireCaptureStillAccepted(request);
    final checksum = sourceChecksum(request.source);
    final acceptedEpoch = request.acceptedClearEpoch;
    final acceptedAt = request.acceptedAt;
    if (acceptedAt != null && acceptedEpoch != _clearEpoch) {
      final relevant = _clearEvents.any(
        (event) =>
            !event.completedAt.isBefore(acceptedAt.toUtc()) &&
            (event.documentId == null ||
                event.documentId == request.documentId ||
                event.documentId == request.acceptedDocumentId ||
                (event.path != null &&
                    request.path != null &&
                    p.equals(event.path!, request.path!))),
      );
      if (relevant) throw const LocalHistoryClearConflict();
    } else if (acceptedAt == null &&
        acceptedEpoch != null &&
        acceptedEpoch != _clearEpoch) {
      throw const LocalHistoryClearConflict();
    }
    if (request.captureId case final captureId?) {
      if (_tombstones.contains(captureId)) {
        throw const LocalHistoryClearConflict();
      }
      final existing = _revisions[captureId];
      if (existing != null) {
        final document = _documents[existing.summary.documentId];
        if (document == null ||
            existing.summary.checksum != checksum ||
            existing.source != request.source ||
            !_sameTextFormat(existing.format, request.format)) {
          throw const LocalHistoryStorageException(
            'Local History capture identity collision.',
          );
        }
        if (request.documentId case final documentId?
            when documentId != document.id) {
          throw const LocalHistoryReconciliationConflict();
        }
        if (request.expectedTarget case final target?
            when target.documentId != document.id) {
          throw const LocalHistoryReconciliationConflict();
        }
        _requireCaptureStillAccepted(request);
        return LocalHistoryCaptureResult(
          document: document,
          revision: existing.summary,
          deduplicated: true,
        );
      }
    }
    if (request.expectedTarget case final target?) {
      final expected = _documents[target.documentId];
      final snapshot = await load();
      if (expected == null ||
          expected.deleted ||
          expected.currentPath == null ||
          !p.equals(expected.currentPath!, target.expectedPath) ||
          localHistoryDocumentVersionToken(
                expected,
                snapshot.revisionsFor(expected.id),
              ) !=
              target.versionToken) {
        throw const LocalHistoryReconciliationConflict();
      }
    }
    var document = _resolveDocument(_documents.values.toList(), request);
    document ??= LocalHistoryDocument(
      id: request.remoteDocumentId ?? _id('document_'),
      displayName: request.displayName,
      currentPath: request.createDetachedLineage ? null : request.path,
      historicalPaths: request.path == null ? const [] : [request.path!],
      updatedAt: request.capturedAt.toUtc(),
      untitled: request.untitled,
      remoteNote: request.remoteNote,
    );
    final identity = _captureIdentity(document, request);
    document = _updatedDocument(
      document,
      request,
      path: identity.path,
      preserveIdentityMetadata: identity.pathMismatchWasRejected,
    );
    _requireCaptureStillAccepted(request);
    _documents[document.id] = document;
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
      final adjacentRevision = _revisions[adjacent!.id];
      if (adjacentRevision != null &&
          _sameTextFormat(adjacentRevision.format, request.format)) {
        return LocalHistoryCaptureResult(
          document: document,
          revision: adjacent,
          deduplicated: true,
        );
      }
    }
    final bytes = utf8.encode(request.source).length + 256;
    if (bytes > policy.maximumBytes) {
      throw const LocalHistoryStorageException(
        'The revision is larger than the Local History storage limit.',
      );
    }
    final summary = LocalHistoryRevisionSummary(
      id: request.captureId ?? _id('revision_'),
      documentId: document.id,
      capturedAt: request.capturedAt.toUtc(),
      reason: request.reason,
      checksum: checksum,
      storageBytes: bytes,
      sourceLength: request.source.length,
      historicalPath: request.createDetachedLineage
          ? request.path
          : identity.path,
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
    LocalHistoryDocument? staleDestinationOwner,
  }) async {
    final document = _documents[documentId];
    if (document == null) return null;
    final destination = p.normalize(destinationPath);
    if (document.currentPath != null) {
      return p.equals(document.currentPath!, destination) ||
              !document.untitled &&
                  document.historicalPaths.any(
                    (path) => p.equals(path, destination),
                  )
          ? document
          : null;
    }
    if (!document.untitled) return null;
    final destinationOwner = _documents.values
        .where(
          (candidate) =>
              candidate.id != document.id &&
              _ownsActivePath(candidate, destination),
        )
        .firstOrNull;
    if (destinationOwner != null) {
      if (!_canRetirePromotionOwner(
        document,
        destinationOwner,
        staleDestinationOwner,
      )) {
        return null;
      }
      _documents[destinationOwner.id] = destinationOwner.copyWith(
        deleted: true,
      );
    }
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
      if (entry.value.deleted) continue;
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
  Future<List<LocalHistoryPathTarget>> resolvePathTargets(
    String path, {
    required bool recursive,
  }) async => _resolvePathTargets(
    _Index(
      documents: _documents.values.toList(growable: false),
      revisions: [for (final revision in _revisions.values) revision.summary],
    ),
    path,
    recursive: recursive,
  );

  @override
  Future<T> runPathReconciliation<T>({
    required LocalHistoryPathReconciliationKind kind,
    required String sourcePath,
    String? destinationPath,
    required bool recursive,
    Iterable<LocalHistoryPathTarget>? preparedTargets,
    required Future<T> Function(List<LocalHistoryPathTarget> targets) operation,
    required bool Function(T result) didCommit,
  }) async {
    final targets = List<LocalHistoryPathTarget>.unmodifiable(
      preparedTargets ??
          _resolvePathTargets(
            _Index(
              documents: _documents.values.toList(growable: false),
              revisions: [
                for (final revision in _revisions.values) revision.summary,
              ],
            ),
            sourcePath,
            recursive: recursive,
          ),
    );
    final reconciliation = switch (kind) {
      LocalHistoryPathReconciliationKind.remap =>
        LocalHistoryPathReconciliation.remap(
          sourcePath: sourcePath,
          destinationPath: destinationPath!,
          targets: targets,
        ),
      LocalHistoryPathReconciliationKind.deletion =>
        LocalHistoryPathReconciliation.deletion(
          sourcePath: sourcePath,
          recursive: recursive,
          targets: targets,
        ),
    };
    if (preparedTargets != null) {
      final index = _Index(
        documents: _documents.values.toList(growable: false),
        revisions: [for (final revision in _revisions.values) revision.summary],
      );
      final preparedIds = targets.map((target) => target.documentId).toSet();
      if (targets.isNotEmpty &&
          _resolvePathTargets(
            index,
            sourcePath,
            recursive: recursive,
          ).any((target) => !preparedIds.contains(target.documentId))) {
        throw const LocalHistoryReconciliationConflict();
      }
      _reconcileDocuments(index, reconciliation);
    }
    final result = await operation(targets);
    if (!didCommit(result)) return result;
    await reconcilePath(reconciliation);
    return result;
  }

  @override
  Future<void> reconcilePath(
    LocalHistoryPathReconciliation reconciliation,
  ) async {
    final reconciled = _reconcileDocuments(
      _Index(
        documents: _documents.values.toList(growable: false),
        revisions: [for (final revision in _revisions.values) revision.summary],
      ),
      reconciliation,
    );
    for (final document in reconciled) {
      _documents[document.id] = document;
    }
  }

  @override
  Future<void> clearDocument(String documentId) =>
      clearDocumentOnce(operationId: const Uuid().v4(), documentId: documentId);

  final Map<String, String?> _completedClearOperations = {};

  @override
  Future<void> clearDocumentOnce({
    required String operationId,
    required String documentId,
  }) async {
    if (_completedClearOperations.containsKey(operationId)) {
      if (_completedClearOperations[operationId] != documentId) {
        throw const LocalHistoryStorageException(
          'Local History clear identity collision.',
        );
      }
      return;
    }
    _completedClearOperations[operationId] = documentId;
    final path = _documents[documentId]?.currentPath;
    final pathHasReplacement =
        path != null &&
        _documents.values.any(
          (candidate) =>
              candidate.id != documentId &&
              !candidate.deleted &&
              candidate.currentPath != null &&
              p.equals(candidate.currentPath!, path),
        );
    _clearEpoch = operationId;
    _clearEvents.add(
      _MemoryClearEvent(
        completedAt: DateTime.now().toUtc(),
        documentId: documentId,
        path: pathHasReplacement ? null : path,
      ),
    );
    _tombstones.addAll(
      _revisions.values
          .where((revision) => revision.summary.documentId == documentId)
          .map((revision) => revision.summary.id),
    );
    _documents.remove(documentId);
    _revisions.removeWhere(
      (_, revision) => revision.summary.documentId == documentId,
    );
  }

  @override
  Future<void> clearAll() => clearAllOnce(operationId: const Uuid().v4());

  @override
  Future<void> clearAllOnce({required String operationId}) async {
    if (_completedClearOperations.containsKey(operationId)) {
      if (_completedClearOperations[operationId] != null) {
        throw const LocalHistoryStorageException(
          'Local History clear identity collision.',
        );
      }
      return;
    }
    _completedClearOperations[operationId] = null;
    _clearEpoch = operationId;
    _clearEvents.add(_MemoryClearEvent(completedAt: DateTime.now().toUtc()));
    _tombstones.addAll(_revisions.keys);
    _documents.clear();
    _revisions.clear();
  }
}

class _MemoryClearEvent {
  const _MemoryClearEvent({
    required this.completedAt,
    this.documentId,
    this.path,
  });

  final DateTime completedAt;
  final String? documentId;
  final String? path;
}
