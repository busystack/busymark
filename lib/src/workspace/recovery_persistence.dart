import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'document_buffer.dart';
import 'session_persistence.dart';
import 'text_format_metadata.dart';
import 'workspace_file_snapshot.dart';

class DocumentRecoveryEntry {
  const DocumentRecoveryEntry({
    required this.id,
    required this.workspacePath,
    required this.filePath,
    required this.untitledName,
    required this.text,
    required this.lastSavedText,
    required this.diskSnapshot,
    required this.format,
    required this.editorState,
    required this.revision,
  });

  factory DocumentRecoveryEntry.fromBuffer(
    DocumentBuffer buffer, {
    required String? workspacePath,
  }) {
    return DocumentRecoveryEntry(
      id: buffer.id,
      workspacePath: workspacePath,
      filePath: buffer.filePath,
      untitledName: buffer.untitledName,
      text: buffer.text,
      lastSavedText: buffer.lastSavedText,
      diskSnapshot: buffer.diskSnapshot,
      format: buffer.format,
      editorState: buffer.editorState,
      revision: buffer.revision,
    );
  }

  final String id;
  final String? workspacePath;
  final String? filePath;
  final String? untitledName;
  final String text;
  final String lastSavedText;
  final WorkspaceFileSnapshot? diskSnapshot;
  final TextFormatMetadata format;
  final DocumentEditorState editorState;
  final int revision;

  Map<String, Object?> toJson() => {
    'id': id,
    'workspacePath': workspacePath,
    'filePath': filePath,
    'untitledName': untitledName,
    'text': text,
    'lastSavedText': lastSavedText,
    'diskSnapshot': diskSnapshot?.toJson(),
    'format': format.toJson(),
    'editorState': editorState.toJson(),
    'revision': revision,
  };

  factory DocumentRecoveryEntry.fromJson(Map<String, Object?> json) {
    final snapshot = json['diskSnapshot'];
    return DocumentRecoveryEntry(
      id: json['id']?.toString() ?? '',
      workspacePath: json['workspacePath']?.toString(),
      filePath: json['filePath']?.toString(),
      untitledName: json['untitledName']?.toString(),
      text: json['text']?.toString() ?? '',
      lastSavedText: json['lastSavedText']?.toString() ?? '',
      diskSnapshot: snapshot is Map
          ? WorkspaceFileSnapshot.fromJson(snapshot.cast<String, Object?>())
          : null,
      format: TextFormatMetadata.fromJson(
        (json['format'] as Map?)?.cast<String, Object?>() ?? const {},
      ),
      editorState: DocumentEditorState.fromJson(
        (json['editorState'] as Map?)?.cast<String, Object?>() ?? const {},
      ),
      revision: (json['revision'] as num?)?.toInt() ?? 0,
    );
  }
}

class RecoverySnapshot {
  const RecoverySnapshot({required this.cleanShutdown, required this.entries});

  final bool cleanShutdown;
  final List<DocumentRecoveryEntry> entries;
}

abstract interface class DocumentRecoveryStore {
  Future<RecoverySnapshot> beginRun();

  Future<void> writeEntries(List<DocumentRecoveryEntry> entries);

  Future<void> markCleanShutdown();

  Future<void> clear();
}

class MemoryDocumentRecoveryStore implements DocumentRecoveryStore {
  RecoverySnapshot value = const RecoverySnapshot(
    cleanShutdown: true,
    entries: [],
  );

  @override
  Future<RecoverySnapshot> beginRun() async {
    final previous = value;
    value = RecoverySnapshot(cleanShutdown: false, entries: previous.entries);
    return previous;
  }

  @override
  Future<void> writeEntries(List<DocumentRecoveryEntry> entries) async {
    value = RecoverySnapshot(cleanShutdown: false, entries: entries);
  }

  @override
  Future<void> markCleanShutdown() async {
    value = RecoverySnapshot(cleanShutdown: true, entries: value.entries);
  }

  @override
  Future<void> clear() async {
    value = const RecoverySnapshot(cleanShutdown: true, entries: []);
  }
}

class JsonDocumentRecoveryStore implements DocumentRecoveryStore {
  JsonDocumentRecoveryStore({this.filePathOverride})
    : _fallbackDirectory = Directory(
        p.join(
          Directory.systemTemp.path,
          'busymark-test-$pid-${DateTime.now().microsecondsSinceEpoch}',
        ),
      );

  final String? filePathOverride;
  final Directory _fallbackDirectory;

  @override
  Future<RecoverySnapshot> beginRun() async {
    final current = await _load();
    await _write(cleanShutdown: false, entries: current.entries);
    return current;
  }

  @override
  Future<void> writeEntries(List<DocumentRecoveryEntry> entries) {
    return _write(cleanShutdown: false, entries: entries);
  }

  @override
  Future<void> markCleanShutdown() async {
    final current = await _load();
    await _write(cleanShutdown: true, entries: current.entries);
  }

  @override
  Future<void> clear() => _write(cleanShutdown: true, entries: const []);

  Future<RecoverySnapshot> _load() async {
    final file = await _file();
    if (!await file.exists()) {
      return const RecoverySnapshot(cleanShutdown: true, entries: []);
    }
    try {
      final decoded = (jsonDecode(await file.readAsString()) as Map)
          .cast<String, Object?>();
      return RecoverySnapshot(
        cleanShutdown: decoded['cleanShutdown'] as bool? ?? false,
        entries:
            (decoded['entries'] as List?)
                ?.whereType<Map>()
                .map(
                  (entry) => DocumentRecoveryEntry.fromJson(
                    entry.cast<String, Object?>(),
                  ),
                )
                .where((entry) => entry.id.isNotEmpty)
                .toList() ??
            const [],
      );
    } on Object {
      return const RecoverySnapshot(cleanShutdown: false, entries: []);
    }
  }

  Future<void> _write({
    required bool cleanShutdown,
    required List<DocumentRecoveryEntry> entries,
  }) async {
    await writeAtomicJson(await _file(), {
      'version': 1,
      'cleanShutdown': cleanShutdown,
      'entries': entries.map((entry) => entry.toJson()).toList(),
    });
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
    return File(p.join(directory.path, 'recovery.json'));
  }
}
