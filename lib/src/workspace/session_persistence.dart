import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../local_history/local_history_models.dart';
import 'document_buffer.dart';

class DocumentSessionEntry {
  const DocumentSessionEntry({
    required this.id,
    required this.filePath,
    required this.untitledName,
    required this.editorState,
    this.localHistoryDocumentId,
    this.pendingLocalHistorySaveAsOperationId,
    this.localHistoryPathReconciliationIds = const [],
    this.recoveryOwnerId,
    this.remoteNote,
  });

  final String id;
  final String? filePath;
  final String? untitledName;
  final DocumentEditorState editorState;
  final String? localHistoryDocumentId;
  final String? pendingLocalHistorySaveAsOperationId;
  final List<String> localHistoryPathReconciliationIds;
  final String? recoveryOwnerId;
  final NextcloudNoteReference? remoteNote;

  Map<String, Object?> toJson() => {
    'id': id,
    'filePath': filePath,
    'untitledName': untitledName,
    'editorState': editorState.toJson(),
    'localHistoryDocumentId': localHistoryDocumentId,
    'pendingLocalHistorySaveAsOperationId':
        pendingLocalHistorySaveAsOperationId,
    'localHistoryPathReconciliationIds': localHistoryPathReconciliationIds,
    'recoveryOwnerId': recoveryOwnerId,
    'origin': remoteNote != null
        ? DocumentOrigin.nextcloudNote.name
        : filePath != null
        ? DocumentOrigin.localFile.name
        : DocumentOrigin.untitled.name,
    'remoteNote': remoteNote?.toJson(),
  };

  factory DocumentSessionEntry.fromJson(Map<String, Object?> json) {
    return DocumentSessionEntry(
      id: json['id']?.toString() ?? '',
      filePath: json['filePath']?.toString(),
      untitledName: json['untitledName']?.toString(),
      editorState: DocumentEditorState.fromJson(
        (json['editorState'] as Map?)?.cast<String, Object?>() ?? const {},
      ),
      localHistoryDocumentId: json['localHistoryDocumentId']?.toString(),
      pendingLocalHistorySaveAsOperationId:
          json['pendingLocalHistorySaveAsOperationId']?.toString(),
      localHistoryPathReconciliationIds:
          (json['localHistoryPathReconciliationIds'] as List?)
              ?.map((value) => value.toString())
              .where((value) => value.isNotEmpty)
              .toList(growable: false) ??
          const [],
      recoveryOwnerId: json['recoveryOwnerId']?.toString(),
      remoteNote: NextcloudNoteReference.fromJson(json['remoteNote']),
    );
  }
}

class PendingLocalHistoryAssociation {
  const PendingLocalHistoryAssociation({
    required this.bufferId,
    required this.documentId,
    required this.destinationPath,
    required this.displayName,
    this.acceptedClearEpoch,
    this.operationOwnerId,
  });

  final String bufferId;
  final String documentId;
  final String destinationPath;
  final String displayName;
  final String? acceptedClearEpoch;
  final String? operationOwnerId;

  Map<String, Object?> toJson() => {
    'bufferId': bufferId,
    'documentId': documentId,
    'destinationPath': destinationPath,
    'displayName': displayName,
    'acceptedClearEpoch': acceptedClearEpoch,
    'operationOwnerId': operationOwnerId,
  };

  factory PendingLocalHistoryAssociation.fromJson(Map<String, Object?> json) {
    return PendingLocalHistoryAssociation(
      bufferId: json['bufferId']?.toString() ?? '',
      documentId: json['documentId']?.toString() ?? '',
      destinationPath: json['destinationPath']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      acceptedClearEpoch: json['acceptedClearEpoch']?.toString(),
      operationOwnerId: json['operationOwnerId']?.toString(),
    );
  }
}

class WorkspaceSessionSnapshot {
  const WorkspaceSessionSnapshot({
    required this.workspacePath,
    required this.tabs,
    required this.activeBufferId,
    this.pendingLocalHistoryAssociations = const [],
    this.pendingLocalHistoryReconciliations = const [],
    this.retiredLocalHistoryReconciliationIds = const [],
    this.retiredLocalHistoryWorkOwnerIds = const [],
    this.pendingLocalHistoryClears = const [],
    this.pendingLocalHistorySaveAs = const [],
    this.retainedLocalHistoryCaptures = const [],
    this.workspaceLocalHistoryReconciliationIds = const [],
    this.nextcloudAccountId,
  });

  final String? workspacePath;
  final List<DocumentSessionEntry> tabs;
  final String? activeBufferId;
  final List<PendingLocalHistoryAssociation> pendingLocalHistoryAssociations;
  final List<LocalHistoryPathReconciliation> pendingLocalHistoryReconciliations;
  final List<String> retiredLocalHistoryReconciliationIds;
  final List<String> retiredLocalHistoryWorkOwnerIds;
  final List<LocalHistoryPendingClear> pendingLocalHistoryClears;
  final List<LocalHistoryPendingSaveAs> pendingLocalHistorySaveAs;
  final List<LocalHistoryRetainedCapture> retainedLocalHistoryCaptures;
  final List<String> workspaceLocalHistoryReconciliationIds;
  final String? nextcloudAccountId;

  Map<String, Object?> toJson() => {
    'version': 2,
    'workspacePath': workspacePath,
    'activeBufferId': activeBufferId,
    'workspaceOrigin': nextcloudAccountId == null ? 'local' : 'nextcloudNotes',
    'nextcloudAccountId': nextcloudAccountId,
    'tabs': tabs.map((entry) => entry.toJson()).toList(),
    'pendingLocalHistoryAssociations': pendingLocalHistoryAssociations
        .map((entry) => entry.toJson())
        .toList(),
    'pendingLocalHistoryReconciliations': pendingLocalHistoryReconciliations
        .map((entry) => entry.toJson())
        .toList(),
    'retiredLocalHistoryReconciliationIds':
        retiredLocalHistoryReconciliationIds,
    'retiredLocalHistoryWorkOwnerIds': retiredLocalHistoryWorkOwnerIds,
    'pendingLocalHistoryClears': pendingLocalHistoryClears
        .map((entry) => entry.toJson())
        .toList(),
    'pendingLocalHistorySaveAs': pendingLocalHistorySaveAs
        .map((entry) => entry.toJson())
        .toList(),
    'retainedLocalHistoryCaptures': retainedLocalHistoryCaptures
        .map((entry) => entry.toJson())
        .toList(),
    'workspaceLocalHistoryReconciliationIds':
        workspaceLocalHistoryReconciliationIds,
  };

  factory WorkspaceSessionSnapshot.fromJson(Map<String, Object?> json) {
    return WorkspaceSessionSnapshot(
      workspacePath: json['workspacePath']?.toString(),
      nextcloudAccountId: json['nextcloudAccountId']?.toString(),
      tabs:
          (json['tabs'] as List?)
              ?.whereType<Map>()
              .map(
                (entry) => DocumentSessionEntry.fromJson(
                  entry.cast<String, Object?>(),
                ),
              )
              .where((entry) => entry.id.isNotEmpty)
              .toList() ??
          const [],
      activeBufferId: json['activeBufferId']?.toString(),
      pendingLocalHistoryAssociations:
          (json['pendingLocalHistoryAssociations'] as List?)
              ?.whereType<Map>()
              .map(
                (entry) => PendingLocalHistoryAssociation.fromJson(
                  entry.cast<String, Object?>(),
                ),
              )
              .where(
                (entry) =>
                    entry.bufferId.isNotEmpty &&
                    entry.documentId.isNotEmpty &&
                    entry.destinationPath.isNotEmpty,
              )
              .toList() ??
          const [],
      pendingLocalHistoryReconciliations:
          (json['pendingLocalHistoryReconciliations'] as List?)
              ?.whereType<Map>()
              .map(
                (entry) => LocalHistoryPathReconciliation.fromJson(
                  entry.cast<String, Object?>(),
                ),
              )
              .toList() ??
          const [],
      retiredLocalHistoryReconciliationIds:
          (json['retiredLocalHistoryReconciliationIds'] as List?)
              ?.map((entry) => entry.toString())
              .where((entry) => entry.isNotEmpty)
              .toList() ??
          const [],
      retiredLocalHistoryWorkOwnerIds:
          (json['retiredLocalHistoryWorkOwnerIds'] as List?)
              ?.map((entry) => entry.toString())
              .where((entry) => entry.isNotEmpty)
              .toList() ??
          const [],
      pendingLocalHistoryClears:
          (json['pendingLocalHistoryClears'] as List?)
              ?.whereType<Map>()
              .map(
                (entry) => LocalHistoryPendingClear.fromJson(
                  entry.cast<String, Object?>(),
                ),
              )
              .where((entry) => entry.operationId.isNotEmpty)
              .toList() ??
          const [],
      pendingLocalHistorySaveAs:
          (json['pendingLocalHistorySaveAs'] as List?)
              ?.whereType<Map>()
              .map(
                (entry) => LocalHistoryPendingSaveAs.fromJson(
                  entry.cast<String, Object?>(),
                ),
              )
              .toList() ??
          const [],
      retainedLocalHistoryCaptures:
          (json['retainedLocalHistoryCaptures'] as List?)
              ?.whereType<Map>()
              .map(
                (entry) => LocalHistoryRetainedCapture.fromJson(
                  entry.cast<String, Object?>(),
                ),
              )
              .toList() ??
          const [],
      workspaceLocalHistoryReconciliationIds:
          (json['workspaceLocalHistoryReconciliationIds'] as List?)
              ?.map((entry) => entry.toString())
              .where((entry) => entry.isNotEmpty)
              .toList() ??
          const [],
    );
  }
}

abstract interface class DocumentSessionStore {
  Future<WorkspaceSessionSnapshot?> load();

  Future<void> save(WorkspaceSessionSnapshot snapshot);

  Future<void> clear();

  Future<bool> markPendingLocalHistorySaveAsCommitted(String operationId);

  Future<bool> runIfNoPendingLocalHistoryWork(
    Future<void> Function() operation,
  );
}

class MemoryDocumentSessionStore implements DocumentSessionStore {
  WorkspaceSessionSnapshot? value;

  @override
  Future<WorkspaceSessionSnapshot?> load() async => value;

  @override
  Future<void> save(WorkspaceSessionSnapshot snapshot) async {
    value = _mergeLocalHistoryReconciliationJournal(value, snapshot);
  }

  @override
  Future<void> clear() async {
    final existing = value;
    if (existing == null) return;
    final retained = _journalOnlySnapshot(existing);
    value =
        retained.pendingLocalHistoryReconciliations.isEmpty &&
            retained.retiredLocalHistoryReconciliationIds.isEmpty &&
            retained.pendingLocalHistoryAssociations.isEmpty &&
            retained.retainedLocalHistoryCaptures.isEmpty &&
            retained.pendingLocalHistoryClears.isEmpty &&
            retained.pendingLocalHistorySaveAs.isEmpty &&
            retained.retiredLocalHistoryWorkOwnerIds.isEmpty
        ? null
        : retained;
  }

  @override
  Future<bool> markPendingLocalHistorySaveAsCommitted(
    String operationId,
  ) async {
    final current = value;
    if (current == null) return false;
    final updated = _markSaveAsCommitted(current, operationId);
    value = updated.$1;
    return updated.$2;
  }

  @override
  Future<bool> runIfNoPendingLocalHistoryWork(
    Future<void> Function() operation,
  ) async {
    if (_sessionHasPendingLocalHistoryWork(value)) return false;
    await operation();
    return true;
  }
}

class JsonDocumentSessionStore implements DocumentSessionStore {
  JsonDocumentSessionStore({
    this.filePathOverride,
    Duration lockBudget = const Duration(seconds: 30),
    Duration lockRetryDelay = const Duration(milliseconds: 25),
  }) : _lockBudget = lockBudget,
       _lockRetryDelay = lockRetryDelay,
       _fallbackDirectory = Directory(
         p.join(
           Directory.systemTemp.path,
           'busymark-test-$pid-${DateTime.now().microsecondsSinceEpoch}',
         ),
       );

  final String? filePathOverride;
  final Duration _lockBudget;
  final Duration _lockRetryDelay;
  final Directory _fallbackDirectory;
  Future<void> _queue = Future<void>.value();

  @override
  Future<WorkspaceSessionSnapshot?> load() async {
    final file = await _file();
    return _serialized(
      () => _withSessionLock(
        file,
        () => _readSession(file),
        budget: _lockBudget,
        retryDelay: _lockRetryDelay,
      ),
    );
  }

  @override
  Future<void> save(WorkspaceSessionSnapshot snapshot) async {
    final file = await _file();
    await _serialized(
      () => _withSessionLock(
        file,
        () async {
          final merged = _mergeLocalHistoryReconciliationJournal(
            await _readSession(file),
            snapshot,
          );
          await _writeAtomic(file, merged.toJson());
        },
        budget: _lockBudget,
        retryDelay: _lockRetryDelay,
      ),
    );
  }

  @override
  Future<void> clear() async {
    final file = await _file();
    await _serialized(
      () => _withSessionLock(
        file,
        () async {
          final existing = await _readSession(file);
          if (existing == null) return;
          final retained = _journalOnlySnapshot(existing);
          if (retained.pendingLocalHistoryReconciliations.isNotEmpty ||
              retained.retiredLocalHistoryReconciliationIds.isNotEmpty ||
              retained.pendingLocalHistoryAssociations.isNotEmpty ||
              retained.retainedLocalHistoryCaptures.isNotEmpty ||
              retained.pendingLocalHistoryClears.isNotEmpty ||
              retained.pendingLocalHistorySaveAs.isNotEmpty ||
              retained.retiredLocalHistoryWorkOwnerIds.isNotEmpty) {
            await _writeAtomic(file, retained.toJson());
          } else if (await file.exists()) {
            await file.delete();
          }
        },
        budget: _lockBudget,
        retryDelay: _lockRetryDelay,
      ),
    );
  }

  @override
  Future<bool> markPendingLocalHistorySaveAsCommitted(
    String operationId,
  ) async {
    final file = await _file();
    return _serialized(
      () => _withSessionLock(
        file,
        () async {
          final current = await _readSession(file);
          if (current == null) return false;
          final updated = _markSaveAsCommitted(current, operationId);
          if (updated.$2) await _writeAtomic(file, updated.$1.toJson());
          return updated.$2;
        },
        budget: _lockBudget,
        retryDelay: _lockRetryDelay,
      ),
    );
  }

  @override
  Future<bool> runIfNoPendingLocalHistoryWork(
    Future<void> Function() operation,
  ) async {
    final file = await _file();
    return _serialized(
      () => _withSessionLock(
        file,
        () async {
          if (_sessionHasPendingLocalHistoryWork(await _readSession(file))) {
            return false;
          }
          await operation();
          return true;
        },
        budget: _lockBudget,
        retryDelay: _lockRetryDelay,
      ),
    );
  }

  Future<T> _serialized<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _queue = _queue.then((_) async {
      try {
        completer.complete(await operation());
      } on Object catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Future<File> _file() async {
    if (filePathOverride case final path?) {
      return File(path);
    }
    late final Directory directory;
    try {
      directory = await getApplicationSupportDirectory();
    } on Object {
      directory = _fallbackDirectory;
    }
    return File(p.join(directory.path, 'session.json'));
  }
}

(WorkspaceSessionSnapshot, bool) _markSaveAsCommitted(
  WorkspaceSessionSnapshot snapshot,
  String operationId,
) {
  var changed = false;
  final operations = [
    for (final operation in snapshot.pendingLocalHistorySaveAs)
      if (operation.operationId == operationId &&
          (operation.firstSaveLineageTransition ||
              !operation.historyCancelled &&
                  (operation.recordSourceHistory ||
                      operation.recordDestinationHistory)))
        (() {
          changed = true;
          return operation.withPhase(
            LocalHistoryPathReconciliationPhase.committed,
          );
        })()
      else
        operation,
  ];
  if (!changed) return (snapshot, false);
  return (
    WorkspaceSessionSnapshot(
      workspacePath: snapshot.workspacePath,
      nextcloudAccountId: snapshot.nextcloudAccountId,
      tabs: snapshot.tabs,
      activeBufferId: snapshot.activeBufferId,
      pendingLocalHistoryAssociations: snapshot.pendingLocalHistoryAssociations,
      pendingLocalHistoryReconciliations:
          snapshot.pendingLocalHistoryReconciliations,
      retiredLocalHistoryReconciliationIds:
          snapshot.retiredLocalHistoryReconciliationIds,
      retiredLocalHistoryWorkOwnerIds: snapshot.retiredLocalHistoryWorkOwnerIds,
      pendingLocalHistoryClears: snapshot.pendingLocalHistoryClears,
      pendingLocalHistorySaveAs: List.unmodifiable(operations),
      retainedLocalHistoryCaptures: snapshot.retainedLocalHistoryCaptures,
      workspaceLocalHistoryReconciliationIds:
          snapshot.workspaceLocalHistoryReconciliationIds,
    ),
    true,
  );
}

WorkspaceSessionSnapshot _mergeLocalHistoryReconciliationJournal(
  WorkspaceSessionSnapshot? existing,
  WorkspaceSessionSnapshot incoming,
) {
  final retired = <String>{
    ...?existing?.retiredLocalHistoryReconciliationIds,
    ...incoming.retiredLocalHistoryReconciliationIds,
  };
  final retiredWork = <String>{
    ...?existing?.retiredLocalHistoryWorkOwnerIds,
    ...incoming.retiredLocalHistoryWorkOwnerIds,
  };
  final operations = <String, LocalHistoryPathReconciliation>{};
  var legacySerial = 0;
  for (final operation in [
    ...?existing?.pendingLocalHistoryReconciliations,
    ...incoming.pendingLocalHistoryReconciliations,
  ]) {
    final key = operation.operationId.isEmpty
        ? 'legacy-${legacySerial++}-${operation.kind.name}-${operation.sourcePath}'
        : operation.operationId;
    if (retired.contains(operation.operationId)) continue;
    final prior = operations[key];
    if (prior == null || operation.phase.index >= prior.phase.index) {
      operations[key] = operation;
    }
  }
  final associations = <String, PendingLocalHistoryAssociation>{
    for (final association in [
      ...?existing?.pendingLocalHistoryAssociations,
      ...incoming.pendingLocalHistoryAssociations,
    ])
      if (!retiredWork.contains(
        association.operationOwnerId ?? association.bufferId,
      ))
        association.operationOwnerId ?? association.bufferId: association,
  };
  final captures = <String, LocalHistoryRetainedCapture>{
    for (final capture in [
      ...?existing?.retainedLocalHistoryCaptures,
      ...incoming.retainedLocalHistoryCaptures,
    ])
      if (!retiredWork.contains(capture.ownerId)) capture.ownerId: capture,
  };
  final saveAsOperations = <String, LocalHistoryPendingSaveAs>{};
  for (final operation in [
    ...?existing?.pendingLocalHistorySaveAs,
    ...incoming.pendingLocalHistorySaveAs,
  ]) {
    if (retiredWork.contains(operation.operationId)) continue;
    final prior = saveAsOperations[operation.operationId];
    if (prior == null) {
      saveAsOperations[operation.operationId] = operation;
      continue;
    }
    final newest = operation.phase.index >= prior.phase.index
        ? operation
        : prior;
    final preserveFirstSaveLineage =
        operation.firstSaveLineageTransition &&
        prior.firstSaveLineageTransition;
    saveAsOperations[operation.operationId] =
        (operation.historyCancelled || prior.historyCancelled)
        ? newest.cancelHistory(
            cancelLineageTransition: !preserveFirstSaveLineage,
          )
        : newest
              .withRecordedSides(
                source:
                    operation.recordSourceHistory && prior.recordSourceHistory,
                destination:
                    operation.recordDestinationHistory &&
                    prior.recordDestinationHistory,
              )
              .withFirstSaveLineageTransition(preserveFirstSaveLineage);
  }
  final clearOperations = <String, LocalHistoryPendingClear>{
    for (final operation in [
      ...?existing?.pendingLocalHistoryClears,
      ...incoming.pendingLocalHistoryClears,
    ])
      if (!retiredWork.contains(operation.operationId))
        operation.operationId: operation,
  };
  return WorkspaceSessionSnapshot(
    workspacePath: incoming.workspacePath,
    nextcloudAccountId: incoming.nextcloudAccountId,
    tabs: incoming.tabs,
    activeBufferId: incoming.activeBufferId,
    pendingLocalHistoryAssociations: List.unmodifiable(associations.values),
    pendingLocalHistoryReconciliations: List.unmodifiable(operations.values),
    retiredLocalHistoryReconciliationIds: List.unmodifiable(retired),
    retiredLocalHistoryWorkOwnerIds: List.unmodifiable(retiredWork),
    pendingLocalHistoryClears: List.unmodifiable(clearOperations.values),
    pendingLocalHistorySaveAs: List.unmodifiable(saveAsOperations.values),
    retainedLocalHistoryCaptures: List.unmodifiable(captures.values),
    workspaceLocalHistoryReconciliationIds:
        incoming.workspaceLocalHistoryReconciliationIds,
  );
}

bool _sessionHasPendingLocalHistoryWork(WorkspaceSessionSnapshot? session) =>
    session != null &&
    (session.pendingLocalHistoryAssociations.isNotEmpty ||
        session.pendingLocalHistoryReconciliations.isNotEmpty ||
        session.pendingLocalHistoryClears.isNotEmpty ||
        session.pendingLocalHistorySaveAs.isNotEmpty ||
        session.retainedLocalHistoryCaptures.isNotEmpty);

WorkspaceSessionSnapshot _journalOnlySnapshot(
  WorkspaceSessionSnapshot existing,
) => WorkspaceSessionSnapshot(
  workspacePath: null,
  tabs: const [],
  activeBufferId: null,
  pendingLocalHistoryAssociations: existing.pendingLocalHistoryAssociations,
  pendingLocalHistoryReconciliations:
      existing.pendingLocalHistoryReconciliations,
  retiredLocalHistoryReconciliationIds:
      existing.retiredLocalHistoryReconciliationIds,
  retiredLocalHistoryWorkOwnerIds: existing.retiredLocalHistoryWorkOwnerIds,
  pendingLocalHistoryClears: existing.pendingLocalHistoryClears,
  retainedLocalHistoryCaptures: existing.retainedLocalHistoryCaptures,
  pendingLocalHistorySaveAs: existing.pendingLocalHistorySaveAs,
  workspaceLocalHistoryReconciliationIds: const [],
);

Future<WorkspaceSessionSnapshot?> _readSession(File file) async {
  if (!await file.exists()) return null;
  final source = await file.readAsString();
  if (source.trim().isEmpty) return null;
  return WorkspaceSessionSnapshot.fromJson(
    (jsonDecode(source) as Map).cast<String, Object?>(),
  );
}

Future<T> _withSessionLock<T>(
  File session,
  Future<T> Function() body, {
  required Duration budget,
  required Duration retryDelay,
}) async {
  await session.parent.create(recursive: true);
  await _setPrivatePermissions(session.parent, directory: true);
  final lockFile = File('${session.path}.lock');
  final handle = await lockFile.open(mode: FileMode.append);
  var acquired = false;
  Object? primaryError;
  try {
    await _setPrivatePermissions(lockFile, directory: false);
    final elapsed = Stopwatch()..start();
    while (true) {
      try {
        await handle.lock(FileLock.exclusive);
        acquired = true;
        break;
      } on FileSystemException catch (error) {
        if (!_isSessionLockContention(error)) rethrow;
        final remaining = budget - elapsed.elapsed;
        if (remaining <= Duration.zero) {
          throw FileSystemException(
            'Timed out waiting for the BusyMark session lock.',
            lockFile.path,
            error.osError,
          );
        }
        await Future<void>.delayed(
          remaining < retryDelay ? remaining : retryDelay,
        );
      }
    }
    return await body();
  } on Object catch (error) {
    primaryError = error;
    rethrow;
  } finally {
    Object? cleanupError;
    StackTrace? cleanupStack;
    try {
      if (acquired) await handle.unlock();
    } on Object catch (error, stack) {
      cleanupError = error;
      cleanupStack = stack;
    }
    try {
      await handle.close();
    } on Object catch (error, stack) {
      cleanupError ??= error;
      cleanupStack ??= stack;
    }
    if (primaryError == null && cleanupError != null) {
      Error.throwWithStackTrace(cleanupError, cleanupStack!);
    }
  }
}

bool _isSessionLockContention(FileSystemException error) {
  final code = error.osError?.errorCode;
  if (Platform.isLinux) return code == 11 || code == 13;
  if (Platform.isWindows) return code == 33;
  return false;
}

Future<void> writeAtomicJson(File target, Map<String, Object?> json) {
  return _writeAtomic(target, json);
}

Future<void> _writeAtomic(File target, Map<String, Object?> json) async {
  await target.parent.create(recursive: true);
  await _setPrivatePermissions(target.parent, directory: true);
  final staging = await target.parent.createTemp('.busymark-state-');
  await _setPrivatePermissions(staging, directory: true);
  final staged = File(p.join(staging.path, p.basename(target.path)));
  try {
    await staged.writeAsString(
      const JsonEncoder.withIndent('  ').convert(json),
      flush: true,
    );
    await _setPrivatePermissions(staged, directory: false);
    await staged.rename(target.path);
    await _setPrivatePermissions(target, directory: false);
  } finally {
    try {
      if (await staged.exists()) {
        await staged.delete();
      }
    } on Object {
      // Cleanup must not hide the persistence result.
    }
    try {
      if (await staging.exists()) {
        await staging.delete(recursive: true);
      }
    } on Object {
      // Cleanup must not hide the persistence result.
    }
  }
}

Future<void> _setPrivatePermissions(
  FileSystemEntity entity, {
  required bool directory,
}) async {
  if (Platform.isWindows) {
    return;
  }
  final result = await Process.run('chmod', [
    directory ? '700' : '600',
    entity.path,
  ]);
  if (result.exitCode != 0) {
    throw FileSystemException(
      'Could not restrict application state permissions: ${result.stderr}',
      entity.path,
    );
  }
}
