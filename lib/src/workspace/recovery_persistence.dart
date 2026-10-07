import 'dart:async';
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
    this.ownerId,
  });

  factory DocumentRecoveryEntry.fromBuffer(
    DocumentBuffer buffer, {
    required String? workspacePath,
    String? ownerId,
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
      ownerId: ownerId,
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
  final String? ownerId;

  DocumentRecoveryEntry withIdentity({required String id, String? ownerId}) =>
      DocumentRecoveryEntry(
        id: id,
        workspacePath: workspacePath,
        filePath: filePath,
        untitledName: untitledName,
        text: text,
        lastSavedText: lastSavedText,
        diskSnapshot: diskSnapshot,
        format: format,
        editorState: editorState,
        revision: revision,
        ownerId: ownerId,
      );

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
    'ownerId': ownerId,
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
      ownerId: json['ownerId']?.toString(),
    );
  }
}

class DocumentRecoveryAdoption {
  const DocumentRecoveryAdoption({
    required this.sourceOwnerId,
    required this.sourceId,
    required this.entry,
  });

  final String? sourceOwnerId;
  final String sourceId;
  final DocumentRecoveryEntry entry;
}

class RecoverySnapshot {
  const RecoverySnapshot({
    required this.cleanShutdown,
    required this.entries,
    this.readErrors = 0,
  });

  final bool cleanShutdown;
  final List<DocumentRecoveryEntry> entries;
  final int readErrors;
}

abstract interface class DocumentRecoveryStore {
  String get ownerId;

  bool ownerIsLiveOtherProcess(String? candidateOwnerId);

  Future<RecoverySnapshot> beginRun();

  Future<List<DocumentRecoveryAdoption>> adoptEntries(
    List<DocumentRecoveryEntry> entries,
  );

  Future<void> releaseAdoptions(List<DocumentRecoveryAdoption> adoptions);

  Future<void> writeEntries(List<DocumentRecoveryEntry> entries);

  Future<void> markCleanShutdown();

  Future<void> clear();
}

class MemoryDocumentRecoveryStore implements DocumentRecoveryStore {
  MemoryDocumentRecoveryStore() : ownerId = 'memory-${++_memoryOwnerSerial}';

  static var _memoryOwnerSerial = 0;

  @override
  final String ownerId;

  @override
  bool ownerIsLiveOtherProcess(String? candidateOwnerId) => false;

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
  Future<List<DocumentRecoveryAdoption>> adoptEntries(
    List<DocumentRecoveryEntry> entries,
  ) async {
    final adopted = <DocumentRecoveryAdoption>[];
    final adoptedIds = <String>{};
    for (final entry in entries) {
      var adoptedId = entry.id;
      var suffix = 1;
      while (!adoptedIds.add(adoptedId)) {
        adoptedId = '${entry.id}:recovered:${suffix++}';
      }
      adopted.add(
        DocumentRecoveryAdoption(
          sourceOwnerId: entry.ownerId,
          sourceId: entry.id,
          entry: entry.withIdentity(id: adoptedId, ownerId: ownerId),
        ),
      );
    }
    value = RecoverySnapshot(
      cleanShutdown: false,
      entries: [for (final adoption in adopted) adoption.entry],
    );
    return List.unmodifiable(adopted);
  }

  @override
  Future<void> releaseAdoptions(
    List<DocumentRecoveryAdoption> adoptions,
  ) async {
    final byKey = <String, DocumentRecoveryEntry>{
      for (final entry in value.entries)
        '${entry.ownerId ?? 'legacy'}\u0000${entry.id}': entry,
    };
    for (final adoption in adoptions) {
      final adoptedKey =
          '${adoption.entry.ownerId ?? 'legacy'}\u0000${adoption.entry.id}';
      if (byKey.remove(adoptedKey) == null) continue;
      final original = adoption.entry.withIdentity(
        id: adoption.sourceId,
        ownerId: adoption.sourceOwnerId,
      );
      final originalKey = '${original.ownerId ?? 'legacy'}\u0000${original.id}';
      byKey.putIfAbsent(originalKey, () => original);
    }
    value = RecoverySnapshot(
      cleanShutdown: false,
      entries: List.unmodifiable(byKey.values),
    );
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
    : ownerId =
          'recovery:$pid:'
          '${_linuxProcessStartIdentity(pid) ?? DateTime.now().toUtc().microsecondsSinceEpoch}:'
          '${++_ownerSerial}',
      _fallbackDirectory = Directory(
        p.join(
          Directory.systemTemp.path,
          'busymark-test-$pid-${DateTime.now().microsecondsSinceEpoch}',
        ),
      );

  final String? filePathOverride;
  static var _ownerSerial = 0;

  @override
  final String ownerId;
  final Directory _fallbackDirectory;
  final _ownedEntryKeys = <String>{};
  Future<void> _queue = Future<void>.value();

  @override
  bool ownerIsLiveOtherProcess(String? candidateOwnerId) {
    if (candidateOwnerId == null || candidateOwnerId == ownerId) return false;
    final match = RegExp(
      r'^recovery:([0-9]+):([0-9]+):[0-9]+$',
    ).firstMatch(candidateOwnerId);
    if (match == null) return false;
    final ownerPid = int.tryParse(match.group(1)!);
    final expectedStart = int.tryParse(match.group(2)!);
    if (ownerPid == null || ownerPid == pid) return false;
    if (Platform.isLinux) {
      final actualStart = _linuxProcessStartIdentity(ownerPid);
      return actualStart != null && actualStart == expectedStart;
    }
    if (Platform.isMacOS) {
      return Process.runSync('kill', ['-0', '$ownerPid']).exitCode == 0;
    }
    if (Platform.isWindows) {
      final result = Process.runSync('tasklist', [
        '/FI',
        'PID eq $ownerPid',
        '/NH',
      ]);
      return result.exitCode == 0 &&
          result.stdout.toString().contains('$ownerPid');
    }
    return false;
  }

  @override
  Future<RecoverySnapshot> beginRun() async {
    final file = await _file();
    return _serialized(
      () => _withRecoveryLock(file, () async {
        final current = await _loadUnlocked(file);
        await _writeFile(file, cleanShutdown: false, entries: current.entries);
        return current;
      }),
    );
  }

  @override
  Future<List<DocumentRecoveryAdoption>> adoptEntries(
    List<DocumentRecoveryEntry> entries,
  ) async {
    final file = await _file();
    return _serialized(
      () => _withRecoveryLock(file, () async {
        final current = await _loadUnlocked(file);
        final byKey = <String, DocumentRecoveryEntry>{
          for (final entry in current.entries) _entryKey(entry): entry,
        };
        final adopted = <DocumentRecoveryAdoption>[];
        for (final requested in entries) {
          final sourceKey = _entryKey(requested);
          if (byKey.remove(sourceKey) == null) continue;
          var adoptedId = requested.id;
          var suffix = 1;
          while (byKey.containsKey('$ownerId\u0000$adoptedId')) {
            adoptedId = '${requested.id}:recovered:${suffix++}';
          }
          final entry = requested.withIdentity(id: adoptedId, ownerId: ownerId);
          byKey[_entryKey(entry)] = entry;
          _ownedEntryKeys.add(_entryKey(entry));
          adopted.add(
            DocumentRecoveryAdoption(
              sourceOwnerId: requested.ownerId,
              sourceId: requested.id,
              entry: entry,
            ),
          );
        }
        await _writeFile(
          file,
          cleanShutdown: false,
          entries: List.unmodifiable(byKey.values),
        );
        return List.unmodifiable(adopted);
      }),
    );
  }

  @override
  Future<void> releaseAdoptions(
    List<DocumentRecoveryAdoption> adoptions,
  ) async {
    if (adoptions.isEmpty) return;
    final file = await _file();
    await _serialized(
      () => _withRecoveryLock(file, () async {
        final current = await _loadUnlocked(file);
        final byKey = <String, DocumentRecoveryEntry>{
          for (final entry in current.entries) _entryKey(entry): entry,
        };
        for (final adoption in adoptions) {
          final adoptedKey = _entryKey(adoption.entry);
          final adopted = byKey.remove(adoptedKey);
          _ownedEntryKeys.remove(adoptedKey);
          if (adopted == null) continue;
          final original = adopted.withIdentity(
            id: adoption.sourceId,
            ownerId: adoption.sourceOwnerId,
          );
          byKey.putIfAbsent(_entryKey(original), () => original);
        }
        await _writeFile(
          file,
          cleanShutdown: false,
          entries: List.unmodifiable(byKey.values),
        );
      }),
    );
  }

  @override
  Future<void> writeEntries(List<DocumentRecoveryEntry> entries) async {
    final file = await _file();
    await _serialized(
      () => _withRecoveryLock(file, () async {
        final current = await _loadUnlocked(file);
        final ownedEntries = [
          for (final entry in entries)
            entry.ownerId == null
                ? DocumentRecoveryEntry(
                    id: entry.id,
                    workspacePath: entry.workspacePath,
                    filePath: entry.filePath,
                    untitledName: entry.untitledName,
                    text: entry.text,
                    lastSavedText: entry.lastSavedText,
                    diskSnapshot: entry.diskSnapshot,
                    format: entry.format,
                    editorState: entry.editorState,
                    revision: entry.revision,
                    ownerId: ownerId,
                  )
                : entry,
        ];
        final incomingIds = ownedEntries.map((entry) => entry.id).toSet();
        final incomingKeys = ownedEntries
            .where((entry) => entry.ownerId == ownerId)
            .map(_entryKey)
            .toSet();
        final merged = <String, DocumentRecoveryEntry>{
          for (final entry in current.entries)
            if (!_ownedEntryKeys.contains(_entryKey(entry)) &&
                !(entry.ownerId == null && incomingIds.contains(entry.id)))
              _entryKey(entry): entry,
          for (final entry in ownedEntries) _entryKey(entry): entry,
        };
        _ownedEntryKeys
          ..clear()
          ..addAll(incomingKeys);
        await _writeFile(
          file,
          cleanShutdown: false,
          entries: List.unmodifiable(merged.values),
        );
      }),
    );
  }

  @override
  Future<void> markCleanShutdown() async {
    final file = await _file();
    await _serialized(
      () => _withRecoveryLock(file, () async {
        final current = await _loadUnlocked(file);
        final remaining = [
          for (final entry in current.entries)
            if (!_ownedEntryKeys.contains(_entryKey(entry))) entry,
        ];
        _ownedEntryKeys.clear();
        await _writeFile(file, cleanShutdown: true, entries: remaining);
      }),
    );
  }

  @override
  Future<void> clear() async {
    final file = await _file();
    await _serialized(
      () => _withRecoveryLock(file, () async {
        final current = await _loadUnlocked(file);
        final remaining = [
          for (final entry in current.entries)
            if (!_ownedEntryKeys.contains(_entryKey(entry))) entry,
        ];
        _ownedEntryKeys.clear();
        await _writeFile(
          file,
          cleanShutdown: remaining.isEmpty,
          entries: remaining,
        );
      }),
    );
  }

  String _entryKey(DocumentRecoveryEntry entry) =>
      '${entry.ownerId ?? 'legacy'}\u0000${entry.id}';

  Future<RecoverySnapshot> _loadUnlocked(File file) async {
    if (!await file.exists()) {
      return const RecoverySnapshot(cleanShutdown: true, entries: []);
    }
    try {
      final decoded = (jsonDecode(await file.readAsString()) as Map)
          .cast<String, Object?>();
      final entries = <DocumentRecoveryEntry>[];
      var readErrors = 0;
      final encodedEntries = decoded['entries'];
      if (encodedEntries is List) {
        for (final encodedEntry in encodedEntries) {
          try {
            if (encodedEntry is! Map || encodedEntry['text'] is! String) {
              throw const FormatException('Invalid recovery entry');
            }
            final entry = DocumentRecoveryEntry.fromJson(
              encodedEntry.cast<String, Object?>(),
            );
            if (entry.id.isEmpty) {
              throw const FormatException('Recovery entry has no identity');
            }
            entries.add(entry);
          } on Object {
            readErrors++;
          }
        }
      } else if (encodedEntries != null) {
        readErrors++;
      }
      return RecoverySnapshot(
        cleanShutdown: decoded['cleanShutdown'] as bool? ?? false,
        entries: List.unmodifiable(entries),
        readErrors: readErrors,
      );
    } on Object {
      await _quarantineMalformedFile(file);
      return const RecoverySnapshot(
        cleanShutdown: false,
        entries: [],
        readErrors: 1,
      );
    }
  }

  Future<void> _quarantineMalformedFile(File file) async {
    final quarantine = File(
      '${file.path}.corrupt-${DateTime.now().microsecondsSinceEpoch}',
    );
    try {
      await file.rename(quarantine.path);
    } on Object {
      // The read error is still returned to the controller for user notice.
    }
  }

  Future<void> _writeFile(
    File file, {
    required bool cleanShutdown,
    required List<DocumentRecoveryEntry> entries,
  }) async {
    await writeAtomicJson(file, {
      'version': 1,
      'cleanShutdown': cleanShutdown,
      'entries': entries.map((entry) => entry.toJson()).toList(),
    });
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
    return File(p.join(directory.path, 'recovery.json'));
  }
}

int? _linuxProcessStartIdentity(int processId) {
  if (!Platform.isLinux) return null;
  try {
    final stat = File('/proc/$processId/stat').readAsStringSync();
    final commandEnd = stat.lastIndexOf(') ');
    if (commandEnd < 0) return null;
    final fields = stat.substring(commandEnd + 2).trim().split(' ');
    return fields.length > 19 ? int.tryParse(fields[19]) : null;
  } on Object {
    return null;
  }
}

Future<T> _withRecoveryLock<T>(File recovery, Future<T> Function() body) async {
  await recovery.parent.create(recursive: true);
  final lock = await File('${recovery.path}.lock').open(mode: FileMode.append);
  final deadline = DateTime.now().add(const Duration(seconds: 30));
  var acquired = false;
  try {
    while (!acquired) {
      try {
        await lock.lock(FileLock.exclusive);
        acquired = true;
      } on FileSystemException catch (error) {
        final code = error.osError?.errorCode;
        final contention = Platform.isLinux
            ? code == 11 || code == 13
            : Platform.isWindows
            ? code == 33
            : false;
        if (!contention || !DateTime.now().isBefore(deadline)) rethrow;
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
    }
    return await body();
  } finally {
    if (acquired) await lock.unlock();
    await lock.close();
  }
}
