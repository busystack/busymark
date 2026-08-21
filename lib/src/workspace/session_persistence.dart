import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'document_buffer.dart';

class DocumentSessionEntry {
  const DocumentSessionEntry({
    required this.id,
    required this.filePath,
    required this.untitledName,
    required this.editorState,
  });

  final String id;
  final String? filePath;
  final String? untitledName;
  final DocumentEditorState editorState;

  Map<String, Object?> toJson() => {
    'id': id,
    'filePath': filePath,
    'untitledName': untitledName,
    'editorState': editorState.toJson(),
  };

  factory DocumentSessionEntry.fromJson(Map<String, Object?> json) {
    return DocumentSessionEntry(
      id: json['id']?.toString() ?? '',
      filePath: json['filePath']?.toString(),
      untitledName: json['untitledName']?.toString(),
      editorState: DocumentEditorState.fromJson(
        (json['editorState'] as Map?)?.cast<String, Object?>() ?? const {},
      ),
    );
  }
}

class WorkspaceSessionSnapshot {
  const WorkspaceSessionSnapshot({
    required this.workspacePath,
    required this.tabs,
    required this.activeBufferId,
  });

  final String? workspacePath;
  final List<DocumentSessionEntry> tabs;
  final String? activeBufferId;

  Map<String, Object?> toJson() => {
    'version': 1,
    'workspacePath': workspacePath,
    'activeBufferId': activeBufferId,
    'tabs': tabs.map((entry) => entry.toJson()).toList(),
  };

  factory WorkspaceSessionSnapshot.fromJson(Map<String, Object?> json) {
    return WorkspaceSessionSnapshot(
      workspacePath: json['workspacePath']?.toString(),
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
    );
  }
}

abstract interface class DocumentSessionStore {
  Future<WorkspaceSessionSnapshot?> load();

  Future<void> save(WorkspaceSessionSnapshot snapshot);

  Future<void> clear();
}

class MemoryDocumentSessionStore implements DocumentSessionStore {
  WorkspaceSessionSnapshot? value;

  @override
  Future<WorkspaceSessionSnapshot?> load() async => value;

  @override
  Future<void> save(WorkspaceSessionSnapshot snapshot) async {
    value = snapshot;
  }

  @override
  Future<void> clear() async {
    value = null;
  }
}

class JsonDocumentSessionStore implements DocumentSessionStore {
  JsonDocumentSessionStore({this.filePathOverride})
    : _fallbackDirectory = Directory(
        p.join(
          Directory.systemTemp.path,
          'busymark-test-$pid-${DateTime.now().microsecondsSinceEpoch}',
        ),
      );

  final String? filePathOverride;
  final Directory _fallbackDirectory;

  @override
  Future<WorkspaceSessionSnapshot?> load() async {
    final file = await _file();
    if (!await file.exists()) {
      return null;
    }
    final source = await file.readAsString();
    if (source.trim().isEmpty) {
      return null;
    }
    return WorkspaceSessionSnapshot.fromJson(
      (jsonDecode(source) as Map).cast<String, Object?>(),
    );
  }

  @override
  Future<void> save(WorkspaceSessionSnapshot snapshot) async {
    await _writeAtomic(await _file(), snapshot.toJson());
  }

  @override
  Future<void> clear() async {
    final file = await _file();
    if (await file.exists()) {
      await file.delete();
    }
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

Future<void> writeAtomicJson(File target, Map<String, Object?> json) {
  return _writeAtomic(target, json);
}

Future<void> _writeAtomic(File target, Map<String, Object?> json) async {
  await target.parent.create(recursive: true);
  final staging = await target.parent.createTemp('.busymark-state-');
  final staged = File(p.join(staging.path, p.basename(target.path)));
  try {
    await staged.writeAsString(
      const JsonEncoder.withIndent('  ').convert(json),
      flush: true,
    );
    await staged.rename(target.path);
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
