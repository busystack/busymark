import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../workspace/document_origin.dart';
import '../workspace/text_format_metadata.dart';

enum LocalHistoryCaptureReason {
  baseline,
  saved,
  automaticCheckpoint,
  beforeReload,
  beforeDiscard,
  beforeRestore,
  beforeDelete,
  externalChange,
}

@immutable
class LocalHistoryPolicy {
  const LocalHistoryPolicy({
    this.recordingEnabled = true,
    this.checkpointInterval = const Duration(seconds: 60),
    this.retentionAge = const Duration(days: 30),
    this.maximumBytes = 512 * 1024 * 1024,
    this.excludedPaths = const [],
    this.pathContext,
  });

  final bool recordingEnabled;
  final Duration checkpointInterval;
  final Duration retentionAge;
  final int maximumBytes;
  final List<String> excludedPaths;
  final p.Context? pathContext;

  void validate() {
    if (checkpointInterval < const Duration(seconds: 10) ||
        checkpointInterval > const Duration(hours: 1)) {
      throw ArgumentError.value(checkpointInterval, 'checkpointInterval');
    }
    if (retentionAge < const Duration(days: 1) ||
        retentionAge > const Duration(days: 3650)) {
      throw ArgumentError.value(retentionAge, 'retentionAge');
    }
    if (maximumBytes < 16 * 1024 * 1024 ||
        maximumBytes > 4 * 1024 * 1024 * 1024) {
      throw ArgumentError.value(maximumBytes, 'maximumBytes');
    }
  }

  bool excludes(String? path) {
    if (path == null || path.isEmpty) return false;
    final paths = pathContext ?? p.context;
    final normalized = paths.normalize(paths.absolute(path));
    for (final excluded in excludedPaths) {
      final root = paths.normalize(paths.absolute(excluded));
      if (paths.equals(root, normalized) || paths.isWithin(root, normalized)) {
        return true;
      }
    }
    return false;
  }
}

@immutable
class LocalHistoryDocument {
  const LocalHistoryDocument({
    required this.id,
    required this.displayName,
    required this.updatedAt,
    this.currentPath,
    this.historicalPaths = const [],
    this.deleted = false,
    this.untitled = false,
    this.remoteNote,
  });

  final String id;
  final String displayName;
  final String? currentPath;
  final List<String> historicalPaths;
  final DateTime updatedAt;
  final bool deleted;
  final bool untitled;
  final NextcloudNoteReference? remoteNote;

  LocalHistoryDocument copyWith({
    String? displayName,
    Object? currentPath = _unset,
    List<String>? historicalPaths,
    DateTime? updatedAt,
    bool? deleted,
    bool? untitled,
    NextcloudNoteReference? remoteNote,
  }) => LocalHistoryDocument(
    id: id,
    displayName: displayName ?? this.displayName,
    currentPath: identical(currentPath, _unset)
        ? this.currentPath
        : currentPath as String?,
    historicalPaths: historicalPaths ?? this.historicalPaths,
    updatedAt: updatedAt ?? this.updatedAt,
    deleted: deleted ?? this.deleted,
    untitled: untitled ?? this.untitled,
    remoteNote: remoteNote ?? this.remoteNote,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'displayName': displayName,
    'currentPath': currentPath,
    'historicalPaths': historicalPaths,
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'deleted': deleted,
    'untitled': untitled,
    'remoteNote': remoteNote?.toJson(),
  };

  factory LocalHistoryDocument.fromJson(Map<String, Object?> json) {
    return LocalHistoryDocument(
      id: _requiredId(json['id']),
      displayName: json['displayName']?.toString() ?? '',
      currentPath: json['currentPath']?.toString(),
      historicalPaths:
          (json['historicalPaths'] as List?)?.whereType<String>().toList(
            growable: false,
          ) ??
          const [],
      updatedAt: DateTime.parse(json['updatedAt'].toString()).toUtc(),
      deleted: json['deleted'] as bool? ?? false,
      untitled: json['untitled'] as bool? ?? false,
      remoteNote: NextcloudNoteReference.fromJson(json['remoteNote']),
    );
  }
}

@immutable
class LocalHistoryRevisionSummary {
  const LocalHistoryRevisionSummary({
    required this.id,
    required this.documentId,
    required this.capturedAt,
    required this.reason,
    required this.checksum,
    required this.storageBytes,
    required this.sourceLength,
    this.historicalPath,
  });

  final String id;
  final String documentId;
  final DateTime capturedAt;
  final LocalHistoryCaptureReason reason;
  final String checksum;
  final int storageBytes;
  final int sourceLength;
  final String? historicalPath;

  Map<String, Object?> toJson() => {
    'id': id,
    'documentId': documentId,
    'capturedAt': capturedAt.toUtc().toIso8601String(),
    'reason': reason.name,
    'checksum': checksum,
    'storageBytes': storageBytes,
    'sourceLength': sourceLength,
    'historicalPath': historicalPath,
  };

  factory LocalHistoryRevisionSummary.fromJson(Map<String, Object?> json) {
    return LocalHistoryRevisionSummary(
      id: _requiredId(json['id']),
      documentId: _requiredId(json['documentId']),
      capturedAt: DateTime.parse(json['capturedAt'].toString()).toUtc(),
      reason: LocalHistoryCaptureReason.values.byName(
        json['reason'].toString(),
      ),
      checksum: json['checksum'].toString(),
      storageBytes: (json['storageBytes'] as num?)?.toInt() ?? 0,
      sourceLength: (json['sourceLength'] as num?)?.toInt() ?? 0,
      historicalPath: json['historicalPath']?.toString(),
    );
  }
}

@immutable
class LocalHistoryRevision {
  const LocalHistoryRevision({
    required this.summary,
    required this.source,
    required this.format,
  });

  final LocalHistoryRevisionSummary summary;
  final String source;
  final TextFormatMetadata format;

  bool get isIntact => sourceChecksum(source) == summary.checksum;
}

@immutable
class LocalHistorySnapshot {
  const LocalHistorySnapshot({
    this.documents = const [],
    this.revisions = const [],
    this.warning,
    this.clearEpoch = '',
  });

  final List<LocalHistoryDocument> documents;
  final List<LocalHistoryRevisionSummary> revisions;
  final String? warning;
  final String clearEpoch;

  List<LocalHistoryRevisionSummary> revisionsFor(String documentId) => [
    for (final revision in revisions)
      if (revision.documentId == documentId) revision,
  ]..sort((left, right) => right.capturedAt.compareTo(left.capturedAt));
}

@immutable
class LocalHistoryCaptureRequest {
  const LocalHistoryCaptureRequest({
    required this.displayName,
    required this.source,
    required this.format,
    required this.capturedAt,
    required this.reason,
    this.documentId,
    this.path,
    this.untitled = false,
    this.force = false,
    this.allowPathChange = false,
    this.requireVacantPath = false,
    this.createDetachedLineage = false,
    this.expectedTarget,
    this.captureId,
    this.acceptedClearEpoch,
    this.acceptedAt,
    this.acceptedDocumentId,
    this.commitGuard,
    this.remoteNote,
  });

  final String? documentId;
  final NextcloudNoteReference? remoteNote;
  String? get remoteDocumentId =>
      remoteNote == null ? null : 'nc_${sourceChecksum(remoteNote!.identity)}';
  final String? path;
  final String displayName;
  final String source;
  final TextFormatMetadata format;
  final DateTime capturedAt;
  final LocalHistoryCaptureReason reason;
  final bool untitled;
  final bool force;

  /// Path identity is normally immutable for an ID-bound capture. Save As
  /// from a new untitled document is the one capture operation that promotes
  /// that same identity to a filesystem path.
  final bool allowPathChange;

  /// Fails instead of attaching an unbound capture to an active path owner.
  /// Used by crash recovery when the original operation created a new path.
  final bool requireVacantPath;

  /// Creates a non-live document whose original path remains searchable.
  final bool createDetachedLineage;

  /// When supplied, the bound owner must still have this exact path/version
  /// at the instant the capture commits.
  final LocalHistoryPathTarget? expectedTarget;
  final String? captureId;
  final String? acceptedClearEpoch;
  final DateTime? acceptedAt;
  final String? acceptedDocumentId;

  /// Revalidates controller-owned policy/cancellation state at the store's
  /// mutation boundary. This callback is process-local and is never persisted.
  final bool Function()? commitGuard;
}

@immutable
class LocalHistoryCaptureResult {
  const LocalHistoryCaptureResult({
    required this.document,
    this.revision,
    this.deduplicated = false,
  });

  final LocalHistoryDocument document;
  final LocalHistoryRevisionSummary? revision;
  final bool deduplicated;
}

enum LocalHistoryPathReconciliationKind { remap, deletion }

enum LocalHistoryPathReconciliationPhase { prepared, executing, committed }

@immutable
class LocalHistoryPendingClear {
  const LocalHistoryPendingClear({required this.operationId, this.documentId});

  final String operationId;
  final String? documentId;
  bool get clearAll => documentId == null;

  Map<String, Object?> toJson() => {
    'operationId': operationId,
    'documentId': documentId,
  };

  factory LocalHistoryPendingClear.fromJson(Map<String, Object?> json) {
    final operationId = json['operationId']?.toString() ?? '';
    if (operationId.isEmpty) {
      throw const FormatException('Invalid Local History clear journal');
    }
    return LocalHistoryPendingClear(
      operationId: operationId,
      documentId: json['documentId']?.toString(),
    );
  }
}

@immutable
class LocalHistoryPathTarget {
  const LocalHistoryPathTarget({
    required this.documentId,
    required this.expectedPath,
    required this.versionToken,
  });

  final String documentId;
  final String expectedPath;
  final String versionToken;

  LocalHistoryPathTarget atPath(String path) => LocalHistoryPathTarget(
    documentId: documentId,
    expectedPath: path,
    versionToken: versionToken,
  );

  Map<String, Object?> toJson() => {
    'documentId': documentId,
    'expectedPath': expectedPath,
    'versionToken': versionToken,
  };

  factory LocalHistoryPathTarget.fromJson(Map<String, Object?> json) {
    final documentId = _requiredId(json['documentId']);
    final expectedPath = json['expectedPath']?.toString() ?? '';
    final versionToken = json['versionToken']?.toString() ?? '';
    if (expectedPath.isEmpty || versionToken.isEmpty) {
      throw const FormatException('Invalid Local History path target');
    }
    return LocalHistoryPathTarget(
      documentId: documentId,
      expectedPath: expectedPath,
      versionToken: versionToken,
    );
  }
}

String localHistoryDocumentVersionToken(
  LocalHistoryDocument document,
  Iterable<LocalHistoryRevisionSummary> revisions,
) {
  final revisionTokens =
      revisions
          .where((revision) => revision.documentId == document.id)
          .map(
            (revision) =>
                '${revision.id}:${revision.checksum}:'
                '${revision.capturedAt.toUtc().microsecondsSinceEpoch}',
          )
          .toList()
        ..sort();
  // A committed filesystem operation may outlive a failed index publish. A
  // later process can then append replacement content to the still-visible
  // identity at the old path. Include document and revision mutation state so
  // retry cannot consume that post-commit history merely because the ID and
  // path still match the originally frozen target.
  return sourceChecksum(
    '${document.id}\u0000${document.currentPath ?? ''}\u0000'
    '${document.deleted}\u0000${document.untitled}\u0000'
    '${document.updatedAt.toUtc().microsecondsSinceEpoch}\u0000'
    '${revisionTokens.join('\u0000')}',
  );
}

/// An ordered, durable request to reconcile a filesystem path operation with
/// the exact Local History documents that existed when it committed.
@immutable
class LocalHistoryPathReconciliation {
  const LocalHistoryPathReconciliation.remap({
    this.operationId = '',
    required this.sourcePath,
    required String destinationPath,
    required this.targets,
    this.ownerIds = const [],
    this.commitEvidenceOperationId,
    this.phase = LocalHistoryPathReconciliationPhase.committed,
  }) : kind = LocalHistoryPathReconciliationKind.remap,
       destinationPath = destinationPath,
       recursive = false;

  const LocalHistoryPathReconciliation.deletion({
    this.operationId = '',
    required this.sourcePath,
    required this.recursive,
    required this.targets,
    this.ownerIds = const [],
    this.commitEvidenceOperationId,
    this.phase = LocalHistoryPathReconciliationPhase.committed,
  }) : kind = LocalHistoryPathReconciliationKind.deletion,
       destinationPath = null;

  final LocalHistoryPathReconciliationKind kind;
  final String operationId;
  final String sourcePath;
  final String? destinationPath;
  final bool recursive;
  final List<LocalHistoryPathTarget> targets;
  final List<String> ownerIds;
  final String? commitEvidenceOperationId;
  final LocalHistoryPathReconciliationPhase phase;
  List<String> get documentIds =>
      List.unmodifiable(targets.map((target) => target.documentId));

  LocalHistoryPathReconciliation withTargets(
    Iterable<LocalHistoryPathTarget> values,
  ) => switch (kind) {
    LocalHistoryPathReconciliationKind.remap =>
      LocalHistoryPathReconciliation.remap(
        operationId: operationId,
        sourcePath: sourcePath,
        destinationPath: destinationPath!,
        targets: List.unmodifiable(values),
        ownerIds: ownerIds,
        commitEvidenceOperationId: commitEvidenceOperationId,
        phase: phase,
      ),
    LocalHistoryPathReconciliationKind.deletion =>
      LocalHistoryPathReconciliation.deletion(
        operationId: operationId,
        sourcePath: sourcePath,
        recursive: recursive,
        targets: List.unmodifiable(values),
        ownerIds: ownerIds,
        commitEvidenceOperationId: commitEvidenceOperationId,
        phase: phase,
      ),
  };

  LocalHistoryPathReconciliation withPhase(
    LocalHistoryPathReconciliationPhase value,
  ) => switch (kind) {
    LocalHistoryPathReconciliationKind.remap =>
      LocalHistoryPathReconciliation.remap(
        operationId: operationId,
        sourcePath: sourcePath,
        destinationPath: destinationPath!,
        targets: targets,
        ownerIds: ownerIds,
        commitEvidenceOperationId: commitEvidenceOperationId,
        phase: value,
      ),
    LocalHistoryPathReconciliationKind.deletion =>
      LocalHistoryPathReconciliation.deletion(
        operationId: operationId,
        sourcePath: sourcePath,
        recursive: recursive,
        targets: targets,
        ownerIds: ownerIds,
        commitEvidenceOperationId: commitEvidenceOperationId,
        phase: value,
      ),
  };

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'operationId': operationId,
    'sourcePath': sourcePath,
    'destinationPath': destinationPath,
    'recursive': recursive,
    'targets': targets.map((target) => target.toJson()).toList(),
    'ownerIds': ownerIds,
    'commitEvidenceOperationId': commitEvidenceOperationId,
    'phase': phase.name,
  };

  factory LocalHistoryPathReconciliation.fromJson(Map<String, Object?> json) {
    final kind = LocalHistoryPathReconciliationKind.values.byName(
      json['kind']?.toString() ?? '',
    );
    final sourcePath = json['sourcePath']?.toString() ?? '';
    final destinationPath = json['destinationPath']?.toString();
    final targets =
        (json['targets'] as List?)
            ?.whereType<Map>()
            .map(
              (value) => LocalHistoryPathTarget.fromJson(
                value.cast<String, Object?>(),
              ),
            )
            .toList(growable: false) ??
        const <LocalHistoryPathTarget>[];
    if (sourcePath.isEmpty ||
        kind == LocalHistoryPathReconciliationKind.remap &&
            (destinationPath == null || destinationPath.isEmpty)) {
      throw const FormatException('Invalid Local History reconciliation');
    }
    final operationId = json['operationId']?.toString() ?? '';
    final ownerIds =
        (json['ownerIds'] as List?)
            ?.map((value) => value.toString())
            .where((value) => value.isNotEmpty)
            .toList(growable: false) ??
        const <String>[];
    final commitEvidenceOperationId = json['commitEvidenceOperationId']
        ?.toString();
    final phase = LocalHistoryPathReconciliationPhase.values.byName(
      json['phase']?.toString() ??
          LocalHistoryPathReconciliationPhase.committed.name,
    );
    return switch (kind) {
      LocalHistoryPathReconciliationKind.remap =>
        LocalHistoryPathReconciliation.remap(
          operationId: operationId,
          sourcePath: sourcePath,
          destinationPath: destinationPath!,
          targets: List.unmodifiable(targets),
          ownerIds: ownerIds,
          commitEvidenceOperationId: commitEvidenceOperationId,
          phase: phase,
        ),
      LocalHistoryPathReconciliationKind.deletion =>
        LocalHistoryPathReconciliation.deletion(
          operationId: operationId,
          sourcePath: sourcePath,
          recursive: json['recursive'] == true,
          targets: List.unmodifiable(targets),
          ownerIds: ownerIds,
          commitEvidenceOperationId: commitEvidenceOperationId,
          phase: phase,
        ),
    };
  }
}

@immutable
class LocalHistoryRetainedSnapshot {
  const LocalHistoryRetainedSnapshot({
    required this.displayName,
    required this.source,
    required this.format,
    required this.revision,
    this.path,
    this.untitled = false,
    this.captureId,
    this.acceptedClearEpoch,
    this.acceptedAt,
    this.acceptedDocumentId,
    this.remoteNote,
  });

  final String displayName;
  final String source;
  final TextFormatMetadata format;
  final int revision;
  final String? path;
  final bool untitled;
  final String? captureId;
  final String? acceptedClearEpoch;
  final DateTime? acceptedAt;
  final String? acceptedDocumentId;
  final NextcloudNoteReference? remoteNote;

  Map<String, Object?> toJson() => {
    'displayName': displayName,
    'source': source,
    'format': format.toJson(),
    'revision': revision,
    'path': path,
    'untitled': untitled,
    'captureId': captureId,
    'acceptedClearEpoch': acceptedClearEpoch,
    'acceptedAt': acceptedAt?.toUtc().toIso8601String(),
    'acceptedDocumentId': acceptedDocumentId,
    'remoteNote': remoteNote?.toJson(),
  };

  factory LocalHistoryRetainedSnapshot.fromJson(Map<String, Object?> json) =>
      LocalHistoryRetainedSnapshot(
        displayName: json['displayName']?.toString() ?? '',
        source: json['source']?.toString() ?? '',
        format: TextFormatMetadata.fromJson(
          (json['format'] as Map? ?? const {}).cast<String, Object?>(),
        ),
        revision: (json['revision'] as num?)?.toInt() ?? 0,
        path: json['path']?.toString(),
        untitled: json['untitled'] == true,
        captureId: json['captureId']?.toString(),
        acceptedClearEpoch: json['acceptedClearEpoch']?.toString(),
        acceptedAt: json['acceptedAt'] == null
            ? null
            : DateTime.parse(json['acceptedAt'].toString()).toUtc(),
        acceptedDocumentId: json['acceptedDocumentId']?.toString(),
        remoteNote: NextcloudNoteReference.fromJson(json['remoteNote']),
      );
}

@immutable
class LocalHistoryPendingSaveAs {
  const LocalHistoryPendingSaveAs({
    required this.operationId,
    required this.bufferId,
    required this.sourceDocumentId,
    required this.destinationDocumentId,
    this.destinationTarget,
    required this.source,
    required this.destination,
    required this.destinationExisted,
    required this.phase,
    this.recoveryOwnerId,
    this.recordSourceHistory = true,
    this.recordDestinationHistory = true,
    this.historyCancelled = false,
    this.firstSaveLineageTransition = false,
  });

  final String operationId;
  final String bufferId;
  final String? sourceDocumentId;
  final String? destinationDocumentId;
  final LocalHistoryPathTarget? destinationTarget;
  final LocalHistoryRetainedSnapshot source;
  final LocalHistoryRetainedSnapshot destination;
  final bool destinationExisted;
  final LocalHistoryPathReconciliationPhase phase;

  /// Identifies the recovery-journal process that owned [bufferId].
  ///
  /// Buffer IDs are only process-local and can be reused by another BusyMark
  /// instance. Startup recovery must use this durable owner together with the
  /// buffer ID before applying a committed fork to a recovery entry.
  final String? recoveryOwnerId;
  final bool recordSourceHistory;
  final bool recordDestinationHistory;
  final bool historyCancelled;

  /// The filesystem operation was the first save of an established untitled
  /// lineage. This structural identity transition survives a recording toggle
  /// even when both optional revision captures are cancelled.
  final bool firstSaveLineageTransition;

  LocalHistoryPendingSaveAs withPhase(
    LocalHistoryPathReconciliationPhase value,
  ) => LocalHistoryPendingSaveAs(
    operationId: operationId,
    bufferId: bufferId,
    sourceDocumentId: sourceDocumentId,
    destinationDocumentId: destinationDocumentId,
    destinationTarget: destinationTarget,
    source: source,
    destination: destination,
    destinationExisted: destinationExisted,
    phase: value,
    recoveryOwnerId: recoveryOwnerId,
    recordSourceHistory: recordSourceHistory,
    recordDestinationHistory: recordDestinationHistory,
    historyCancelled: historyCancelled,
    firstSaveLineageTransition: firstSaveLineageTransition,
  );

  LocalHistoryPendingSaveAs withRecordedSides({
    required bool source,
    required bool destination,
  }) => LocalHistoryPendingSaveAs(
    operationId: operationId,
    bufferId: bufferId,
    sourceDocumentId: sourceDocumentId,
    destinationDocumentId: destinationDocumentId,
    destinationTarget: destinationTarget,
    source: this.source,
    destination: this.destination,
    destinationExisted: destinationExisted,
    phase: phase,
    recoveryOwnerId: recoveryOwnerId,
    recordSourceHistory: recordSourceHistory && source,
    recordDestinationHistory: recordDestinationHistory && destination,
    historyCancelled: historyCancelled,
    firstSaveLineageTransition: firstSaveLineageTransition,
  );

  LocalHistoryPendingSaveAs cancelHistory({
    bool cancelLineageTransition = false,
  }) => LocalHistoryPendingSaveAs(
    operationId: operationId,
    bufferId: bufferId,
    sourceDocumentId: sourceDocumentId,
    destinationDocumentId: destinationDocumentId,
    destinationTarget: destinationTarget,
    source: source,
    destination: destination,
    destinationExisted: destinationExisted,
    phase: phase,
    recoveryOwnerId: recoveryOwnerId,
    recordSourceHistory: false,
    recordDestinationHistory: false,
    historyCancelled: true,
    firstSaveLineageTransition:
        !cancelLineageTransition && firstSaveLineageTransition,
  );

  LocalHistoryPendingSaveAs withoutFirstSaveLineageTransition() =>
      withFirstSaveLineageTransition(false);

  LocalHistoryPendingSaveAs withFirstSaveLineageTransition(bool value) =>
      LocalHistoryPendingSaveAs(
        operationId: operationId,
        bufferId: bufferId,
        sourceDocumentId: sourceDocumentId,
        destinationDocumentId: destinationDocumentId,
        destinationTarget: destinationTarget,
        source: source,
        destination: destination,
        destinationExisted: destinationExisted,
        phase: phase,
        recoveryOwnerId: recoveryOwnerId,
        recordSourceHistory: recordSourceHistory,
        recordDestinationHistory: recordDestinationHistory,
        historyCancelled: historyCancelled,
        firstSaveLineageTransition: value,
      );

  LocalHistoryPendingSaveAs withRecoveryIdentity({
    required String recoveryOwnerId,
    required String bufferId,
  }) => LocalHistoryPendingSaveAs(
    operationId: operationId,
    bufferId: bufferId,
    sourceDocumentId: sourceDocumentId,
    destinationDocumentId: destinationDocumentId,
    destinationTarget: destinationTarget,
    source: source,
    destination: destination,
    destinationExisted: destinationExisted,
    phase: phase,
    recoveryOwnerId: recoveryOwnerId,
    recordSourceHistory: recordSourceHistory,
    recordDestinationHistory: recordDestinationHistory,
    historyCancelled: historyCancelled,
    firstSaveLineageTransition: firstSaveLineageTransition,
  );

  Map<String, Object?> toJson() => {
    'operationId': operationId,
    'bufferId': bufferId,
    'sourceDocumentId': sourceDocumentId,
    'destinationDocumentId': destinationDocumentId,
    'destinationTarget': destinationTarget?.toJson(),
    'source': source.toJson(),
    'destination': destination.toJson(),
    'destinationExisted': destinationExisted,
    'phase': phase.name,
    'recoveryOwnerId': recoveryOwnerId,
    'recordSourceHistory': recordSourceHistory,
    'recordDestinationHistory': recordDestinationHistory,
    'historyCancelled': historyCancelled,
    'firstSaveLineageTransition': firstSaveLineageTransition,
  };

  factory LocalHistoryPendingSaveAs.fromJson(Map<String, Object?> json) {
    final operationId = json['operationId']?.toString() ?? '';
    final bufferId = json['bufferId']?.toString() ?? '';
    final source = (json['source'] as Map?)?.cast<String, Object?>();
    final destination = (json['destination'] as Map?)?.cast<String, Object?>();
    if (operationId.isEmpty ||
        bufferId.isEmpty ||
        source == null ||
        destination == null) {
      throw const FormatException('Invalid Local History Save As journal');
    }
    return LocalHistoryPendingSaveAs(
      operationId: operationId,
      bufferId: bufferId,
      sourceDocumentId: json['sourceDocumentId']?.toString(),
      destinationDocumentId: json['destinationDocumentId']?.toString(),
      destinationTarget: json['destinationTarget'] is Map
          ? LocalHistoryPathTarget.fromJson(
              (json['destinationTarget'] as Map).cast<String, Object?>(),
            )
          : null,
      source: LocalHistoryRetainedSnapshot.fromJson(source),
      destination: LocalHistoryRetainedSnapshot.fromJson(destination),
      destinationExisted: json['destinationExisted'] == true,
      phase: LocalHistoryPathReconciliationPhase.values.byName(
        json['phase']?.toString() ??
            LocalHistoryPathReconciliationPhase.prepared.name,
      ),
      recoveryOwnerId: json['recoveryOwnerId']?.toString(),
      recordSourceHistory: json['recordSourceHistory'] != false,
      recordDestinationHistory: json['recordDestinationHistory'] != false,
      historyCancelled: json['historyCancelled'] == true,
      firstSaveLineageTransition:
          json['firstSaveLineageTransition'] == true ||
          json['firstSaveLineageTransition'] == null &&
              LocalHistoryRetainedSnapshot.fromJson(source).untitled &&
              json['destinationExisted'] != true,
    );
  }
}

@immutable
class LocalHistoryRetainedProtection {
  const LocalHistoryRetainedProtection({
    required this.snapshot,
    required this.reason,
    required this.force,
    required this.ignoreBinding,
    required this.allowPathChange,
    required this.bindResult,
    this.requireVacantPath = false,
    this.expectedTarget,
    this.captureId,
  });

  final LocalHistoryRetainedSnapshot snapshot;
  final LocalHistoryCaptureReason reason;
  final bool force;
  final bool ignoreBinding;
  final bool allowPathChange;
  final bool bindResult;
  final bool requireVacantPath;
  final LocalHistoryPathTarget? expectedTarget;
  final String? captureId;

  Map<String, Object?> toJson() => {
    'snapshot': snapshot.toJson(),
    'reason': reason.name,
    'force': force,
    'ignoreBinding': ignoreBinding,
    'allowPathChange': allowPathChange,
    'bindResult': bindResult,
    'requireVacantPath': requireVacantPath,
    'expectedTarget': expectedTarget?.toJson(),
    'captureId': captureId,
  };

  factory LocalHistoryRetainedProtection.fromJson(Map<String, Object?> json) =>
      LocalHistoryRetainedProtection(
        snapshot: LocalHistoryRetainedSnapshot.fromJson(
          (json['snapshot'] as Map).cast<String, Object?>(),
        ),
        reason: LocalHistoryCaptureReason.values.byName(
          json['reason']?.toString() ?? '',
        ),
        force: json['force'] == true,
        ignoreBinding: json['ignoreBinding'] == true,
        allowPathChange: json['allowPathChange'] == true,
        bindResult: json['bindResult'] == true,
        requireVacantPath: json['requireVacantPath'] == true,
        expectedTarget: json['expectedTarget'] is Map
            ? LocalHistoryPathTarget.fromJson(
                (json['expectedTarget'] as Map).cast<String, Object?>(),
              )
            : null,
        captureId: json['captureId']?.toString(),
      );
}

@immutable
class LocalHistoryRetainedCapture {
  const LocalHistoryRetainedCapture({
    required this.ownerId,
    this.documentId,
    this.baseline,
    this.pending,
    this.baselineSaveDestination,
    this.protection,
    this.baselineRequiresVacantPath = false,
  });

  final String ownerId;
  final String? documentId;
  final LocalHistoryRetainedSnapshot? baseline;
  final LocalHistoryRetainedSnapshot? pending;
  final LocalHistoryRetainedSnapshot? baselineSaveDestination;
  final LocalHistoryRetainedProtection? protection;
  final bool baselineRequiresVacantPath;

  Map<String, Object?> toJson() => {
    'ownerId': ownerId,
    'documentId': documentId,
    'baseline': baseline?.toJson(),
    'pending': pending?.toJson(),
    'baselineSaveDestination': baselineSaveDestination?.toJson(),
    'protection': protection?.toJson(),
    'baselineRequiresVacantPath': baselineRequiresVacantPath,
  };

  factory LocalHistoryRetainedCapture.fromJson(Map<String, Object?> json) {
    LocalHistoryRetainedSnapshot? snapshot(String key) {
      final value = json[key];
      return value is Map
          ? LocalHistoryRetainedSnapshot.fromJson(value.cast<String, Object?>())
          : null;
    }

    final ownerId = json['ownerId']?.toString() ?? '';
    if (!ownerId.startsWith('history-capture:') &&
        !ownerId.startsWith('history-promotion:')) {
      throw const FormatException('Invalid retained Local History owner');
    }
    final protectionJson = json['protection'];
    return LocalHistoryRetainedCapture(
      ownerId: ownerId,
      documentId: json['documentId']?.toString(),
      baseline: snapshot('baseline'),
      pending: snapshot('pending'),
      baselineSaveDestination: snapshot('baselineSaveDestination'),
      protection: protectionJson is Map
          ? LocalHistoryRetainedProtection.fromJson(
              protectionJson.cast<String, Object?>(),
            )
          : null,
      baselineRequiresVacantPath: json['baselineRequiresVacantPath'] == true,
    );
  }
}

String sourceChecksum(String source) =>
    sha256.convert(utf8.encode(source)).toString();

const Object _unset = Object();

String _requiredId(Object? value) {
  final id = value?.toString() ?? '';
  if (!RegExp(r'^[A-Za-z0-9_-]{8,80}$').hasMatch(id)) {
    throw const FormatException('Invalid Local History identity');
  }
  return id;
}

class UnsupportedLocalHistoryFormat implements Exception {
  const UnsupportedLocalHistoryFormat(this.version);

  final Object? version;

  @override
  String toString() => 'Unsupported Local History format $version';
}

class LocalHistoryStorageException implements Exception {
  const LocalHistoryStorageException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

class LocalHistoryReconciliationConflict extends LocalHistoryStorageException {
  const LocalHistoryReconciliationConflict()
    : super('Local History path reconciliation found a replacement owner.');
}

class LocalHistoryClearConflict extends LocalHistoryReconciliationConflict {
  const LocalHistoryClearConflict();

  @override
  String toString() =>
      'Local History was cleared after this capture was accepted.';
}

class LocalHistoryCaptureCancelled extends LocalHistoryStorageException {
  const LocalHistoryCaptureCancelled()
    : super('Local History capture was cancelled before commit.');
}
