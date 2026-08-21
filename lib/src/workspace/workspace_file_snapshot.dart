import 'text_format_metadata.dart';

class WorkspaceFileSnapshot {
  const WorkspaceFileSnapshot({
    required this.modifiedAt,
    required this.size,
    required this.contentHash,
  });

  final DateTime modifiedAt;
  final int size;
  final String contentHash;

  bool differsFrom(WorkspaceFileSnapshot other) {
    if (contentHash.isNotEmpty && other.contentHash.isNotEmpty) {
      return contentHash != other.contentHash;
    }
    return modifiedAt != other.modifiedAt || size != other.size;
  }

  Map<String, Object?> toJson() => {
    'modifiedAt': modifiedAt.toIso8601String(),
    'size': size,
    'contentHash': contentHash,
  };

  factory WorkspaceFileSnapshot.fromJson(Map<String, Object?> json) {
    return WorkspaceFileSnapshot(
      modifiedAt:
          DateTime.tryParse(json['modifiedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      size: (json['size'] as num?)?.toInt() ?? 0,
      contentHash: json['contentHash']?.toString() ?? '',
    );
  }
}

class WorkspaceFileLoad {
  const WorkspaceFileLoad({
    required this.text,
    required this.snapshot,
    this.format = TextFormatMetadata.utf8Lf,
  });

  final String text;
  final WorkspaceFileSnapshot snapshot;
  final TextFormatMetadata format;
}
