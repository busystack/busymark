import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

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
  });

  final String id;
  final String displayName;
  final String? currentPath;
  final List<String> historicalPaths;
  final DateTime updatedAt;
  final bool deleted;
  final bool untitled;

  LocalHistoryDocument copyWith({
    String? displayName,
    Object? currentPath = _unset,
    List<String>? historicalPaths,
    DateTime? updatedAt,
    bool? deleted,
    bool? untitled,
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
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'displayName': displayName,
    'currentPath': currentPath,
    'historicalPaths': historicalPaths,
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'deleted': deleted,
    'untitled': untitled,
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
  });

  final List<LocalHistoryDocument> documents;
  final List<LocalHistoryRevisionSummary> revisions;
  final String? warning;

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
  });

  final String? documentId;
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
