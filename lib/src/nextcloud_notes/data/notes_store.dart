import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import '../../assets/asset_limits.dart';
import '../domain/notes_models.dart';

/// Focused durable Notes store. All synchronous SQLite work runs in one isolate.
class NotesStore {
  NotesStore._(this.path, this._isolate, this._commands, this._replies) {
    _subscription = _replies.listen((dynamic message) {
      final result = message as List<dynamic>;
      final pending = _pending.remove(result[0]);
      if (result[1] == true) {
        pending?.complete(result[2]);
      } else {
        pending?.completeError(StateError(result[2] as String));
      }
    });
  }

  final String path;
  final Isolate _isolate;
  final SendPort _commands;
  final ReceivePort _replies;
  late final StreamSubscription<dynamic> _subscription;
  final Map<int, Completer<dynamic>> _pending = {};
  int _serial = 0;
  bool _closed = false;
  Future<void>? _closing;

  static Future<NotesStore> open({required String path}) async {
    final directory = Directory(p.dirname(path));
    await directory.create(recursive: true);
    if (await FileSystemEntity.isLink(directory.path) ||
        await FileSystemEntity.isLink(path)) {
      throw StateError('Nextcloud Notes storage must not be a symbolic link.');
    }
    if (Platform.isLinux) {
      final permission = await Process.run('chmod', ['700', directory.path]);
      if (permission.exitCode != 0) {
        throw StateError('Cannot protect Nextcloud Notes storage.');
      }
    }
    final ready = ReceivePort();
    final replies = ReceivePort();
    final isolate = await Isolate.spawn(_worker, [
      path,
      ready.sendPort,
      replies.sendPort,
    ]);
    final result = await ready.first as List<dynamic>;
    ready.close();
    if (result[0] != true) {
      isolate.kill(priority: Isolate.immediate);
      replies.close();
      throw StateError(result[1] as String);
    }
    return NotesStore._(path, isolate, result[1] as SendPort, replies);
  }

  Future<dynamic> _call(String action, [Object? argument]) {
    if (_closed) return Future.error(StateError('The Notes store is closed.'));
    final id = ++_serial;
    final completer = Completer<dynamic>();
    _pending[id] = completer;
    _commands.send([id, action, argument]);
    return completer.future;
  }

  Future<List<NextcloudAccount>> accounts() async =>
      (await _call('accounts') as List)
          .map(
            (json) => NextcloudAccount.fromJson(
              jsonDecode(json as String) as Map<String, dynamic>,
            ),
          )
          .toList();

  Future<List<NextcloudNote>> notes() async => (await _call('notes') as List)
      .map(
        (json) => NextcloudNote.fromJson(
          jsonDecode(json as String) as Map<String, dynamic>,
        ),
      )
      .toList();

  Future<void> saveAccount(NextcloudAccount account) =>
      commit(accounts: [account]);

  Future<void> saveNote(NextcloudNote note) => commit(notes: [note]);

  /// Content, exact revision, reference state, outbox and checkpoint commit together.
  Future<void> commit({
    List<NextcloudAccount> accounts = const [],
    List<NextcloudNote> notes = const [],
    List<String> removeNotes = const [],
  }) async {
    await _call('commit', {
      'accounts': accounts.map((a) => [a.id, jsonEncode(a.toJson())]).toList(),
      'notes': notes
          .map(
            (n) => [
              n.localId,
              n.accountId,
              n.serverId,
              n.encode(),
              n.hasPendingChanges,
              n.revision,
              n.serverId == null ? 'create' : 'update',
            ],
          )
          .toList(),
      'removeNotes': removeNotes,
    });
  }

  Future<void> removeAccount(String id) async {
    await _call('removeAccount', id);
  }

  Future<void> saveAttachment(
    NotesAttachment attachment,
    Uint8List bytes,
  ) async {
    await _call('saveAttachment', [
      attachment.id,
      attachment.noteId,
      jsonEncode(attachment.toJson()),
      bytes,
    ]);
  }

  /// Import/export bounded blobs on the storage isolate, not the UI isolate.
  Future<void> saveAttachmentFile(NotesAttachment attachment, File file) =>
      _call('saveAttachmentFile', [
        attachment.id,
        attachment.noteId,
        jsonEncode(attachment.toJson()),
        file.path,
      ]);

  Future<void> writeAttachmentFile(String id, File file) =>
      _call('writeAttachmentFile', [id, file.path]);

  Future<void> createWithAttachments(
    NextcloudNote note,
    List<({NotesAttachment attachment, Uint8List bytes})> attachments, {
    List<NextcloudNote> additionalNotes = const [],
  }) async {
    await _call('createWithAttachments', [
      note.toJson(),
      attachments
          .map(
            (a) => [
              a.attachment.id,
              a.attachment.noteId,
              jsonEncode(a.attachment.toJson()),
              a.bytes,
            ],
          )
          .toList(),
      additionalNotes.map((n) => n.toJson()).toList(),
    ]);
  }

  /// Staging is durable before an editor inserts the resulting reference. It
  /// deliberately does not change the note revision or create an HTTP outbox.
  Future<void> stageAttachments(
    List<({NotesAttachment attachment, Uint8List bytes})> attachments,
  ) async {
    await _call(
      'stageAttachments',
      attachments
          .map(
            (a) => [
              a.attachment.id,
              a.attachment.noteId,
              jsonEncode(a.attachment.toJson()),
              a.bytes,
            ],
          )
          .toList(),
    );
  }

  Future<List<NotesAttachment>> attachments([String? noteId]) async =>
      (await _call('attachments', noteId) as List)
          .map(
            (json) => NotesAttachment.fromJson(
              jsonDecode(json as String) as Map<String, dynamic>,
            ),
          )
          .toList();

  Future<Uint8List?> attachmentBytes(String id) async =>
      await _call('attachmentBytes', id) as Uint8List?;

  Future<void> updateAttachment(
    NotesAttachment attachment, {
    NextcloudNote? note,
  }) async {
    await _call('updateAttachment', [
      attachment.id,
      jsonEncode(attachment.toJson()),
      note?.toJson(),
    ]);
  }

  Future<void> removeAttachment(String id) async {
    await _call('removeAttachment', id);
  }

  Future<void> close() => _closing ??= _close();

  Future<void> _close() async {
    if (_closed) return;
    await _call('close');
    _closed = true;
    await _subscription.cancel();
    _replies.close();
    _isolate.kill(priority: Isolate.immediate);
  }
}

void _worker(List<dynamic> arguments) {
  final path = arguments[0] as String;
  final ready = arguments[1] as SendPort;
  final replies = arguments[2] as SendPort;
  late Database db;
  try {
    db = sqlite3.open(path);
    if (Platform.isLinux &&
        Process.runSync('chmod', ['600', path]).exitCode != 0) {
      throw StateError('Cannot protect the Nextcloud Notes database.');
    }
    db.execute('PRAGMA foreign_keys = ON');
    db.execute('PRAGMA journal_mode = WAL');
    db.execute('PRAGMA synchronous = FULL');
    db.execute('PRAGMA busy_timeout = 5000');
    final version = db.select('PRAGMA user_version').first.values.first as int;
    if (version > 4) {
      throw StateError(
        'The Notes database was created by a newer BusyMark version.',
      );
    }
    if (version == 0) {
      db.execute('BEGIN IMMEDIATE');
      try {
        db.execute(
          'CREATE TABLE accounts (id TEXT PRIMARY KEY, data TEXT NOT NULL)',
        );
        db.execute(
          'CREATE TABLE notes (id TEXT PRIMARY KEY, account_id TEXT NOT NULL REFERENCES accounts(id) ON DELETE CASCADE, server_id INTEGER, data TEXT NOT NULL, UNIQUE(account_id, server_id))',
        );
        db.execute(
          'CREATE TABLE outbox (note_id TEXT PRIMARY KEY REFERENCES notes(id) ON DELETE CASCADE, revision INTEGER NOT NULL, operation TEXT NOT NULL, data TEXT NOT NULL)',
        );
        db.execute(
          'CREATE TABLE attachments (id TEXT PRIMARY KEY, note_id TEXT NOT NULL REFERENCES notes(id) ON DELETE CASCADE, data TEXT NOT NULL, bytes BLOB NOT NULL)',
        );
        db.execute('PRAGMA user_version = 1');
        db.execute('COMMIT');
      } catch (_) {
        db.execute('ROLLBACK');
        rethrow;
      }
    }
    // v2 stores durable creation attempts in the existing versioned note JSON.
    // Older uncertain operations have no attempt and remain explicitly unresolved.
    // Prevent old clients from opening and losing this new safety metadata.
    // v3 fences durable retry/error provenance, edit times and settings attempts.
    // v4 fences competing local metadata evidence from older clients.
    // Advance only inside the recovery transaction; malformed rows roll back.

    // A request interrupted by a crash has an uncertain creation/upload outcome.
    db.execute('BEGIN IMMEDIATE');
    try {
      for (final row in db.select('SELECT data FROM notes')) {
        final note = NextcloudNote.fromJson(
          jsonDecode(row['data'] as String) as Map<String, dynamic>,
        );
        if (note.syncState == NoteSyncState.syncing) {
          _writeNote(
            db,
            note.copyWith(
              syncState: note.serverId == null
                  ? NoteSyncState.creationUncertain
                  : NoteSyncState.pending,
            ),
          );
        }
      }
      if (version < 4) db.execute('PRAGMA user_version = 4');
      db.execute('COMMIT');
    } catch (_) {
      db.execute('ROLLBACK');
      rethrow;
    }
  } catch (_) {
    ready.send([false, 'Cannot open or migrate the Nextcloud Notes database.']);
    return;
  }
  final commands = ReceivePort();
  ready.send([true, commands.sendPort]);
  commands.listen((dynamic message) {
    final request = message as List<dynamic>;
    try {
      final result = _execute(db, request[1] as String, request[2]);
      replies.send([request[0], true, result]);
      if (request[1] == 'close') commands.close();
    } catch (_) {
      // Never include note contents, SQL parameters or credentials in errors/logs.
      replies.send([
        request[0],
        false,
        'The durable Nextcloud Notes transaction failed.',
      ]);
    }
  });
}

void _writeNote(Database db, NextcloudNote note) {
  db.execute(
    'INSERT INTO notes(id,account_id,server_id,data) VALUES(?,?,?,?) ON CONFLICT(id) DO UPDATE SET server_id=excluded.server_id,data=excluded.data',
    [note.localId, note.accountId, note.serverId, note.encode()],
  );
  if (note.hasPendingChanges) {
    db.execute(
      'INSERT INTO outbox(note_id,revision,operation,data) VALUES(?,?,?,?) ON CONFLICT(note_id) DO UPDATE SET revision=excluded.revision,operation=excluded.operation,data=excluded.data',
      [
        note.localId,
        note.revision,
        note.serverId == null ? 'create' : 'update',
        note.encode(),
      ],
    );
  } else {
    db.execute('DELETE FROM outbox WHERE note_id=?', [note.localId]);
  }
}

Object? _execute(Database db, String action, dynamic argument) {
  switch (action) {
    case 'accounts':
      return db
          .select('SELECT data FROM accounts ORDER BY id')
          .map((r) => r['data'])
          .toList();
    case 'notes':
      return db
          .select('SELECT data FROM notes ORDER BY id')
          .map((r) => r['data'])
          .toList();
    case 'commit':
      final data = argument as Map;
      db.execute('BEGIN IMMEDIATE');
      try {
        for (final id in data['removeNotes'] as List) {
          db.execute('DELETE FROM notes WHERE id=?', [id]);
        }
        for (final a in data['accounts'] as List) {
          db.execute(
            'INSERT INTO accounts(id,data) VALUES(?,?) ON CONFLICT(id) DO UPDATE SET data=excluded.data',
            a as List<Object?>,
          );
        }
        for (final n in data['notes'] as List) {
          _writeNote(
            db,
            NextcloudNote.fromJson(
              jsonDecode(n[3] as String) as Map<String, dynamic>,
            ),
          );
        }
        db.execute('COMMIT');
      } catch (_) {
        db.execute('ROLLBACK');
        rethrow;
      }
      return null;
    case 'removeAccount':
      db.execute('DELETE FROM accounts WHERE id=?', [argument]);
      return null;
    case 'saveAttachmentFile':
      final a = argument as List;
      final file = File(a[3] as String);
      if (file.lengthSync() > maximumManagedAssetBytes ||
          FileSystemEntity.isLinkSync(file.path)) {
        throw StateError('Unsafe attachment import.');
      }
      final bytes = file.readAsBytesSync();
      if (bytes.length > maximumManagedAssetBytes) {
        throw StateError('Attachment too large.');
      }
      db.execute(
        'INSERT INTO attachments(id,note_id,data,bytes) VALUES(?,?,?,?) ON CONFLICT(id) DO UPDATE SET data=excluded.data,bytes=excluded.bytes',
        [a[0], a[1], a[2], bytes],
      );
      return null;
    case 'writeAttachmentFile':
      final a = argument as List;
      final bytes =
          db.select('SELECT bytes FROM attachments WHERE id=?', [
                a[0],
              ]).single['bytes']
              as Uint8List;
      if (bytes.length > maximumManagedAssetBytes) {
        throw StateError('Attachment too large.');
      }
      final file = File(a[1] as String);
      if (FileSystemEntity.isLinkSync(file.path)) {
        throw StateError('Unsafe cache.');
      }
      file.writeAsBytesSync(bytes, flush: true);
      return null;
    case 'saveAttachment':
      final a = argument as List;
      db.execute(
        'INSERT INTO attachments(id,note_id,data,bytes) VALUES(?,?,?,?)',
        a.cast<Object?>(),
      );
      return null;
    case 'createWithAttachments':
      final a = argument as List;
      db.execute('BEGIN IMMEDIATE');
      try {
        for (final note in a[2] as List) {
          _writeNote(
            db,
            NextcloudNote.fromJson(Map<String, dynamic>.from(note as Map)),
          );
        }
        _writeNote(
          db,
          NextcloudNote.fromJson(Map<String, dynamic>.from(a[0] as Map)),
        );
        for (final attachment in a[1] as List) {
          db.execute(
            'INSERT INTO attachments(id,note_id,data,bytes) VALUES(?,?,?,?)',
            (attachment as List).cast<Object?>(),
          );
        }
        db.execute('COMMIT');
      } catch (_) {
        db.execute('ROLLBACK');
        rethrow;
      }
      return null;
    case 'attachments':
      return (argument == null
              ? db.select('SELECT data FROM attachments ORDER BY id')
              : db.select(
                  'SELECT data FROM attachments WHERE note_id=? ORDER BY id',
                  [argument],
                ))
          .map((r) => r['data'])
          .toList();
    case 'stageAttachments':
      db.execute('BEGIN IMMEDIATE');
      try {
        for (final attachment in argument as List) {
          db.execute(
            'INSERT INTO attachments(id,note_id,data,bytes) VALUES(?,?,?,?)',
            (attachment as List).cast<Object?>(),
          );
        }
        db.execute('COMMIT');
      } catch (_) {
        db.execute('ROLLBACK');
        rethrow;
      }
      return null;
    case 'attachmentBytes':
      final rows = db.select('SELECT bytes FROM attachments WHERE id=?', [
        argument,
      ]);
      return rows.isEmpty ? null : rows.first['bytes'];
    case 'updateAttachment':
      final a = argument as List;
      db.execute('BEGIN IMMEDIATE');
      try {
        db.execute('UPDATE attachments SET data=? WHERE id=?', [a[1], a[0]]);
        if (a[2] != null) {
          _writeNote(
            db,
            NextcloudNote.fromJson(Map<String, dynamic>.from(a[2] as Map)),
          );
        }
        db.execute('COMMIT');
      } catch (_) {
        db.execute('ROLLBACK');
        rethrow;
      }
      return null;
    case 'removeAttachment':
      db.execute('DELETE FROM attachments WHERE id=?', [argument]);
      return null;
    case 'close':
      db.close();
      return null;
    default:
      throw StateError('Unknown Notes storage operation.');
  }
}
