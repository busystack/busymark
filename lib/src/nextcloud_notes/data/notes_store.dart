import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';

import '../../assets/asset_limits.dart';
import '../domain/notes_models.dart';
import '../domain/notes_search.dart';

/// Focused durable Notes store. All synchronous SQLite work runs in one isolate.
class NotesStore {
  NotesStore._(this.path, this._isolate, this._commands, this._replies) {
    _subscription = _replies.listen((dynamic message) {
      final result = message as List<dynamic>;
      final pending = _pending.remove(result[0]);
      if (result[1] == true) {
        pending?.complete(result[2]);
      } else {
        pending?.completeError(
          result[3] == true
              ? const NotesException(
                  NotesFailureCode.conflict,
                  'Another BusyMark window changed this Notes state or owns a request. Your editor changes are retained. Use Save As to preserve them before reopening this window.',
                )
              : StateError(result[2] as String),
        );
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

  Future<void> validateNote(String id) => _call('validateNote', id);

  Future<void> saveNote(NextcloudNote note) => commit(notes: [note]);

  /// Content, exact revision, reference state and checkpoint commit together.
  Future<void> commit({
    List<NextcloudAccount> accounts = const [],
    List<NextcloudNote> notes = const [],
    List<String> removeNotes = const [],
  }) async {
    await _call('commit', {
      'accounts': accounts.map((a) => [a.id, jsonEncode(a.toJson())]).toList(),
      'notes': notes.map((n) => n.encode()).toList(),
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
    String? importKey,
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
      importKey,
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

  Future<int?> attachmentSize(String id) async =>
      await _call('attachmentSize', id) as int?;

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

  /// Each step is bounded so queued durable saves can run between steps.
  Future<int> indexStep() async => await _call('indexStep') as int;
  Future<void> rebuildIndex() async => await _call('rebuildIndex');
  Future<Map<String, dynamic>> searchChunk(
    String accountId,
    NotesSearchQuery query, {
    int after = 0,
    Map<String, dynamic>? continuation,
    bool recovery = false,
    int limit = 80,
    Set<String> exclude = const {},
  }) async => Map<String, dynamic>.from(
    await _call('searchChunk', {
          'account': accountId,
          'query': query.text,
          'after': after,
          'continuation': continuation,
          'recovery': recovery,
          'limit': limit.clamp(1, 200),
          'exclude': exclude.toList(),
        })
        as Map,
  );
  Future<List<Map<String, dynamic>>> offlineRequirements(
    String accountId,
  ) async => (await _call('offlineRequirements', accountId) as List)
      .map((v) => Map<String, dynamic>.from(v as Map))
      .toList();
  Future<void> setOfflineRequirement(
    String accountId,
    String kind,
    String target, {
    bool required = true,
    bool paused = false,
  }) async => await _call('setOfflineRequirement', [
    accountId,
    kind,
    target,
    required,
    paused,
  ]);
  Future<void> beginImportOperation(
    String accountId,
    String operationId,
    String root,
    String review,
  ) async => await _call('beginImportOperation', [
    accountId,
    operationId,
    root,
    review,
  ]);
  Future<List<Map<String, dynamic>>> importOperations(String accountId) async =>
      (await _call('importOperations', accountId) as List)
          .map((r) => Map<String, dynamic>.from(r as Map))
          .toList();
  Future<Map<String, dynamic>?> importOperation(
    String accountId,
    String operationId,
  ) async {
    final row = await _call('importOperation', [accountId, operationId]);
    return row == null ? null : Map<String, dynamic>.from(row as Map);
  }

  Future<void> completeImportOperation(
    String accountId,
    String operationId,
    List<String> keys,
  ) async =>
      await _call('completeImportOperation', [accountId, operationId, keys]);
  Future<String?> importedNote(String accountId, String sourceKey) async =>
      await _call('importedNote', [accountId, sourceKey]) as String?;

  final _requestDepth = <String, int>{};
  final _requests = <Completer<void>>{};

  /// SQLite owns the claim; the network operation never holds a DB transaction.
  /// Nested operations in this repository share the claim, foreign stores cannot.
  Future<T> withRequestOwnership<T>(
    String accountId,
    Future<T> Function() action,
  ) async {
    if (_closing != null && !_requestDepth.containsKey(accountId)) {
      throw StateError('The Notes store is closing.');
    }
    final finished = Completer<void>();
    _requests.add(finished);
    try {
      await _call('beginRequest', accountId);
      _requestDepth[accountId] = (_requestDepth[accountId] ?? 0) + 1;
      try {
        return await action();
      } finally {
        final depth = _requestDepth[accountId]! - 1;
        if (depth == 0) {
          _requestDepth.remove(accountId);
          await _call('endRequest', accountId);
        } else {
          _requestDepth[accountId] = depth;
        }
      }
    } finally {
      _requests.remove(finished);
      finished.complete();
    }
  }

  Future<void> close() => _closing ??= _close();

  Future<void> _close() async {
    if (_closed) return;
    while (_requests.isNotEmpty) {
      await Future.wait(_requests.map((request) => request.future));
    }
    await _call('close');
    _closed = true;
    await _subscription.cancel();
    _replies.close();
    _isolate.kill(priority: Isolate.immediate);
  }
}

class _NotesStoreConflict implements Exception {}

/// Expected storage generations belong to this repository's cache, not to the
/// last read from SQLite. Reads for search/media must not authorize stale edits.
class _NotesStoreSession {
  _NotesStoreSession(this.id);
  final String id;
  final _expected = <(String, String), int>{};
  final _rowAccounts = <(String, String), String>{};

  static String? _processStart(int process) {
    try {
      final stat = File('/proc/$process/stat').readAsStringSync();
      return stat.substring(stat.lastIndexOf(')') + 2).split(' ')[19];
    } on FileSystemException catch (error) {
      // Access denial or an I/O failure is not evidence that an owner died.
      // Keep its claim rather than reclassifying a potentially live request.
      if (error.osError?.errorCode == 2 || error.osError?.errorCode == 3) {
        return null;
      }
      rethrow;
    }
  }

  void _retireDeadSessions(Database db) {
    for (final row in db.select('SELECT * FROM store_sessions')) {
      if (_processStart(row['process'] as int) != row['start']) {
        db.execute('DELETE FROM store_sessions WHERE id=?', [row['id']]);
      }
    }
  }

  void open(Database db) {
    db.execute(
      'CREATE TABLE IF NOT EXISTS store_versions (kind TEXT NOT NULL, id TEXT NOT NULL, generation INTEGER NOT NULL, PRIMARY KEY(kind,id))',
    );
    db.execute(
      'CREATE TABLE IF NOT EXISTS store_sessions (id TEXT PRIMARY KEY, process INTEGER NOT NULL, start TEXT NOT NULL)',
    );
    db.execute(
      'CREATE TABLE IF NOT EXISTS request_owners (account_id TEXT PRIMARY KEY REFERENCES accounts(id) ON DELETE CASCADE, session TEXT NOT NULL REFERENCES store_sessions(id) ON DELETE CASCADE)',
    );
    _retireDeadSessions(db);
    db.execute('INSERT INTO store_sessions VALUES(?,?,?)', [
      id,
      pid,
      _processStart(pid) ??
          (throw StateError('Cannot establish Notes process identity.')),
    ]);
  }

  bool requestIsLive(Database db, String account) => db.select(
    'SELECT 1 FROM request_owners WHERE account_id=?',
    [account],
  ).isNotEmpty;

  void capture(Database db) {
    for (final row in db.select('SELECT id,account_id FROM notes')) {
      _rowAccounts[('notes', row['id'] as String)] =
          row['account_id'] as String;
    }
    for (final row in db.select(
      'SELECT a.id,n.account_id FROM attachments a JOIN notes n ON n.id=a.note_id',
    )) {
      _rowAccounts[('attachments', row['id'] as String)] =
          row['account_id'] as String;
    }

    for (final row in db.select('SELECT * FROM store_versions')) {
      _expected[(row['kind'] as String, row['id'] as String)] =
          row['generation'] as int;
    }
  }

  int _generation(Database db, (String, String) key) {
    final rows = db.select(
      'SELECT generation FROM store_versions WHERE kind=? AND id=?',
      [key.$1, key.$2],
    );
    return rows.isEmpty ? 0 : rows.single['generation'] as int;
  }

  void _advance(Database db, (String, String) key) => db.execute(
    'INSERT INTO store_versions VALUES(?,?,1) ON CONFLICT(kind,id) DO UPDATE SET generation=generation+1',
    [key.$1, key.$2],
  );

  Object? execute(Database db, String action, dynamic argument) {
    if (action == 'close') {
      db.execute('DELETE FROM store_sessions WHERE id=?', [id]);
      db.close();
      return null;
    }
    if (const {
      'accounts',
      'notes',
      'attachments',
      'attachmentSize',
      'attachmentBytes',
      'writeAttachmentFile',
      'searchChunk',
      'offlineRequirements',
      'importOperations',
      'importOperation',
      'importedNote',
    }.contains(action)) {
      return _execute(db, action, argument);
    }
    final checked = <(String, String)>{}, changed = <(String, String)>{};
    final accounts = <String>{};
    final rowAccounts = <(String, String), String>{};
    void account(String value, {bool write = false}) {
      accounts.add(value);
      checked.add(('accounts', value));
      if (write) changed.add(('accounts', value));
    }

    void note(String value, {bool write = false, String? accountId}) {
      checked.add(('notes', value));
      if (write) changed.add(('notes', value));
      final rows = db.select('SELECT account_id FROM notes WHERE id=?', [
        value,
      ]);
      final owner =
          accountId ??
          (rows.isEmpty ? null : rows.single['account_id'] as String);
      if (owner != null) {
        account(owner);
        rowAccounts[('notes', value)] = owner;
      }
    }

    void attachment(String value, {bool write = false, String? noteId}) {
      checked.add(('attachments', value));
      if (write) changed.add(('attachments', value));
      final rows = db.select('SELECT note_id FROM attachments WHERE id=?', [
        value,
      ]);
      final owner =
          noteId ?? (rows.isEmpty ? null : rows.single['note_id'] as String);
      if (owner != null) {
        note(owner);
        final accountId = rowAccounts[('notes', owner)];
        if (accountId != null) rowAccounts[('attachments', value)] = accountId;
      }
    }

    void noteJson(Map value) => note(
      value['localId'] as String,
      write: true,
      accountId: value['accountId'] as String,
    );
    db.execute('BEGIN IMMEDIATE');
    try {
      _retireDeadSessions(db);
      switch (action) {
        case 'validateNote':
          note(argument as String);
        case 'commit':
          final data = argument as Map;
          for (final a in data['accounts'] as List) {
            account(a[0] as String, write: true);
          }
          for (final n in data['notes'] as List) {
            noteJson(jsonDecode(n as String) as Map);
          }
          for (final n in data['removeNotes'] as List) {
            note(n as String, write: true);
            for (final row in db.select(
              'SELECT id FROM attachments WHERE note_id=?',
              [n],
            )) {
              attachment(row['id'] as String, write: true);
            }
          }
        case 'removeAccount':
          account(argument as String, write: true);
          for (final row in db.select(
            'SELECT id FROM notes WHERE account_id=?',
            [argument],
          )) {
            final noteId = row['id'] as String;
            note(noteId, write: true);
            for (final a in db.select(
              'SELECT id FROM attachments WHERE note_id=?',
              [noteId],
            )) {
              attachment(a['id'] as String, write: true);
            }
          }
        case 'createWithAttachments':
          final a = argument as List;
          noteJson(a[0] as Map);
          for (final n in a[2] as List) {
            noteJson(n as Map);
          }
          for (final value in a[1] as List) {
            attachment(
              value[0] as String,
              write: true,
              noteId: value[1] as String,
            );
          }
        case 'saveAttachment' || 'saveAttachmentFile':
          final a = argument as List;
          attachment(a[0] as String, write: true, noteId: a[1] as String);
        case 'stageAttachments':
          for (final a in argument as List) {
            attachment(a[0] as String, write: true, noteId: a[1] as String);
          }
        case 'updateAttachment':
          final a = argument as List;
          attachment(a[0] as String, write: true);
          if (a[2] != null) noteJson(a[2] as Map);
        case 'removeAttachment':
          attachment(argument as String, write: true);
        case 'setOfflineRequirement' ||
            'beginImportOperation' ||
            'completeImportOperation':
          final a = argument as List;
          account(a[0] as String);
          final key = (
            action == 'setOfflineRequirement' ? 'offline' : 'import',
            jsonEncode(
              a.take(action == 'setOfflineRequirement' ? 3 : 2).toList(),
            ),
          );
          checked.add(key);
          changed.add(key);
        case 'beginRequest':
          account(argument as String);
          // Include cached identities deleted by another process, not just
          // rows still present. A stale cache must not send a remote DELETE.
          checked.addAll(
            _rowAccounts.entries
                .where((entry) => entry.value == argument)
                .map((entry) => entry.key),
          );
          // A stale cache must not send a remote DELETE or request based on
          // another process's superseded note, identity, settings or attachment.
          for (final row in db.select(
            'SELECT id FROM notes WHERE account_id=?',
            [argument],
          )) {
            final noteId = row['id'] as String;
            note(noteId);
            for (final a in db.select(
              'SELECT id FROM attachments WHERE note_id=?',
              [noteId],
            )) {
              attachment(a['id'] as String);
            }
          }
      }
      for (final key in checked) {
        if (_generation(db, key) != (_expected[key] ?? 0)) {
          throw _NotesStoreConflict();
        }
      }
      for (final value in accounts) {
        final owners = db.select(
          'SELECT session FROM request_owners WHERE account_id=?',
          [value],
        );
        if (owners.isNotEmpty && owners.single['session'] != id) {
          throw _NotesStoreConflict();
        }
      }
      Object? result;
      if (action == 'validateNote') {
        // Validation uses the same persisted generation as writes.
      } else if (action == 'beginRequest') {
        db.execute(
          'INSERT INTO request_owners VALUES(?,?) ON CONFLICT(account_id) DO NOTHING',
          [argument, id],
        );
      } else if (action == 'endRequest') {
        db.execute(
          'DELETE FROM request_owners WHERE account_id=? AND session=?',
          [argument, id],
        );
      } else {
        result = _execute(db, action, argument);
      }
      for (final key in changed) {
        _advance(db, key);
      }
      // Capture before COMMIT, publish the cache baseline only after COMMIT.
      final versions = {for (final key in changed) key: _generation(db, key)};
      db.execute('COMMIT');
      _expected.addAll(versions);
      _rowAccounts.addAll(rowAccounts);
      return result;
    } catch (_) {
      db.execute('ROLLBACK');
      rethrow;
    }
  }
}

void _worker(List<dynamic> arguments) {
  final path = arguments[0] as String;
  final ready = arguments[1] as SendPort;
  final replies = arguments[2] as SendPort;
  Database? openedDatabase;
  late final Database db;
  final session = _NotesStoreSession(const Uuid().v4());
  try {
    db = sqlite3.open(path);
    openedDatabase = db;
    if (Platform.isLinux &&
        Process.runSync('chmod', ['600', path]).exitCode != 0) {
      throw StateError('Cannot protect the Nextcloud Notes database.');
    }
    db.execute('PRAGMA foreign_keys = ON');
    db.execute('PRAGMA busy_timeout = 5000');
    db.execute('PRAGMA journal_mode = WAL');
    db.execute('PRAGMA synchronous = FULL');
    db.execute('BEGIN IMMEDIATE');
    final version = db.select('PRAGMA user_version').first.values.first as int;
    if (version > 7) {
      throw StateError(
        'The Notes database was created by a newer BusyMark version.',
      );
    }
    if (version == 0) {
      db.execute(
        'CREATE TABLE accounts (id TEXT PRIMARY KEY, data TEXT NOT NULL)',
      );
      db.execute(
        'CREATE TABLE notes (id TEXT PRIMARY KEY, account_id TEXT NOT NULL REFERENCES accounts(id) ON DELETE CASCADE, server_id INTEGER, data TEXT NOT NULL, UNIQUE(account_id, server_id))',
      );
      db.execute(
        'CREATE TABLE attachments (id TEXT PRIMARY KEY, note_id TEXT NOT NULL REFERENCES notes(id) ON DELETE CASCADE, data TEXT NOT NULL, bytes BLOB NOT NULL)',
      );
    }
    // v2 stores durable creation attempts in the existing versioned note JSON.
    // Older uncertain operations have no attempt and remain explicitly unresolved.
    // Prevent old clients from opening and losing this new safety metadata.
    // v3 fences durable retry/error provenance, edit times and settings attempts.
    // v4 fences competing local metadata evidence from older clients.
    // Advance only inside the recovery transaction; malformed rows roll back.

    // A request interrupted by a crash has an uncertain creation/upload outcome.
    try {
      _createWorkspaceSchema(db);
      session.open(db);
      db.execute('DROP TABLE IF EXISTS outbox');
      for (final row in db.select('SELECT data FROM notes')) {
        final note = NextcloudNote.fromJson(
          jsonDecode(row['data'] as String) as Map<String, dynamic>,
        );
        if (note.syncState == NoteSyncState.syncing &&
            !session.requestIsLive(db, note.accountId)) {
          _writeNote(
            db,
            note.copyWith(
              syncState: note.serverId == null
                  ? NoteSyncState.creationUncertain
                  : NoteSyncState.pending,
            ),
          );
          session._advance(db, ('notes', note.localId));
        }
      }
      if (version < 7) db.execute('PRAGMA user_version = 7');
      db.execute('COMMIT');
    } catch (_) {
      db.execute('ROLLBACK');
      rethrow;
    }
  } catch (_) {
    // Release database and WAL checkpoint locks before the caller observes
    // failure and can immediately inspect or reopen the same store. Killing
    // the isolate after notification does not await SQLite finalizers.
    openedDatabase?.close();
    ready.send([false, 'Cannot open or migrate the Nextcloud Notes database.']);
    return;
  }
  session.capture(db);
  final commands = ReceivePort();
  ready.send([true, commands.sendPort]);
  commands.listen((dynamic message) {
    final request = message as List<dynamic>;
    try {
      final result = session.execute(db, request[1] as String, request[2]);
      replies.send([request[0], true, result]);
      if (request[1] == 'close') commands.close();
    } catch (error) {
      // Never include note contents, SQL parameters or credentials in errors/logs.
      replies.send([
        request[0],
        false,
        'The durable Nextcloud Notes transaction failed.',
        error is _NotesStoreConflict,
      ]);
    }
  });
}

void _writeNote(Database db, NextcloudNote note) {
  db.execute(
    'INSERT INTO notes(id,account_id,server_id,data) VALUES(?,?,?,?) ON CONFLICT(id) DO UPDATE SET server_id=excluded.server_id,data=excluded.data',
    [note.localId, note.accountId, note.serverId, note.encode()],
  );
  _indexNote(db, note);
}

Object? _execute(Database db, String action, dynamic argument) {
  switch (action) {
    case 'indexStep':
      final rows = db.select(
        "SELECT n.data FROM notes n LEFT JOIN note_search_map s ON s.id=n.id WHERE s.id IS NULL OR s.revision!=json_extract(n.data,'\$.revision') LIMIT 32",
      );
      for (final row in rows) {
        _indexNote(
          db,
          NextcloudNote.fromJson(
            jsonDecode(row['data'] as String) as Map<String, dynamic>,
          ),
        );
      }
      return rows.length;
    case 'rebuildIndex':
      db.execute('DELETE FROM note_search');
      db.execute('DELETE FROM note_search_map');
      return null;
    case 'searchChunk':
      final a = argument as Map;
      final query = NotesSearchQuery(a['query'] as String);
      final expression = query.ftsCandidates;
      final recovery = a['recovery'] == true;
      final rows = db.select(
        recovery
            ? 'SELECT rowid AS cursor,data FROM notes WHERE account_id=? AND rowid>? ORDER BY rowid LIMIT 32'
            : 'SELECT note_search.rowid AS cursor,n.data FROM note_search JOIN notes n ON n.id=note_search.id WHERE note_search.account=? AND note_search.rowid>? '
                  "${expression == null ? '' : 'AND note_search MATCH ? '}ORDER BY note_search.rowid LIMIT 32",
        [
          a['account'],
          a['after'],
          if (!recovery && expression != null) expression,
        ],
      );
      final hits = <Map<String, Object?>>[];
      final exclude = (a['exclude'] as List).cast<String>().toSet();
      final limit = a['limit'] as int;
      var after = a['after'] as int;
      Map? continuation = a['continuation'] as Map?;
      for (var index = 0; index < rows.length; index++) {
        final row = rows[index];
        final note = NextcloudNote.fromJson(
          jsonDecode(row['data'] as String) as Map<String, dynamic>,
        );
        if (continuation != null &&
            (continuation['id'] != note.localId ||
                continuation['revision'] != note.revision ||
                continuation['title'] != note.title ||
                continuation['category'] != note.category ||
                continuation['digest'] != notesSearchDigest(note.content))) {
          throw StateError('Search continuation changed; refresh the query.');
        }
        final deleted =
            note.syncState == NoteSyncState.deletedRemotely &&
            !note.hasPendingChanges;
        if (!exclude.contains(note.localId) && deleted == recovery) {
          final remaining = limit - hits.length;
          final page = matchNotesDocument(
            query: query,
            localId: note.localId,
            revision: note.revision,
            title: note.title,
            category: note.category,
            source: note.content,
            limit: remaining + 1,
            afterStart: continuation?['start'] as int? ?? -1,
            afterEnd: continuation?['end'] as int? ?? -1,
          );
          hits.addAll(page.take(remaining).map((h) => h.toJson()));
          if (page.length > remaining) {
            final last = page[remaining - 1];
            return {
              'hits': hits,
              'after': after,
              'more': true,
              'continuation': {
                'id': note.localId,
                'revision': note.revision,
                'title': note.title,
                'category': note.category,
                'digest': last.digest,
                'start': last.start,
                'end': last.end,
              },
            };
          }
        }
        // Advance only after the complete document has been consumed.
        after = row['cursor'] as int;
        continuation = null;
        if (hits.length == limit) {
          return {
            'hits': hits,
            'after': after,
            'continuation': null,
            'more': index < rows.length - 1 || rows.length == 32,
          };
        }
      }
      if (continuation != null) throw StateError('Search continuation lost.');
      return {
        'hits': hits,
        'after': after,
        'continuation': null,
        'more': rows.length == 32,
      };
    case 'beginImportOperation':
      final a = argument as List;
      db.execute(
        "INSERT INTO import_operations(account_id,id,root,review,state) VALUES(?,?,?,?,'pending') ON CONFLICT(account_id,id) DO UPDATE SET review=excluded.review WHERE import_operations.state='pending' AND import_operations.root=excluded.root",
        a,
      );
      return null;
    case 'importOperations':
      return db
          .select(
            "SELECT id,root,state,created_at FROM import_operations WHERE account_id=? AND state='pending' ORDER BY rowid DESC",
            [argument],
          )
          .map((r) => Map<String, Object?>.from(r))
          .toList();
    case 'importOperation':
      final a = argument as List;
      final rows = db.select(
        'SELECT id,root,review,state FROM import_operations WHERE account_id=? AND id=?',
        a,
      );
      return rows.isEmpty ? null : Map<String, Object?>.from(rows.single);
    case 'completeImportOperation':
      final a = argument as List;
      for (final key in a[2] as List) {
        if (db.select(
          'SELECT note_id FROM import_items WHERE account_id=? AND source_key=?',
          [a[0], key],
        ).isEmpty) {
          throw StateError('An import item is not durable.');
        }
      }
      db.execute(
        "UPDATE import_operations SET state='completed' WHERE account_id=? AND id=?",
        [a[0], a[1]],
      );
      return null;
    case 'offlineRequirements':
      return db
          .select(
            'SELECT kind,target,paused FROM offline_requirements WHERE account_id=? ORDER BY kind,target',
            [argument],
          )
          .map((r) => Map<String, Object?>.from(r))
          .toList();
    case 'setOfflineRequirement':
      final a = argument as List;
      if (a[3] == true) {
        db.execute(
          'INSERT INTO offline_requirements(account_id,kind,target,paused) VALUES(?,?,?,?) ON CONFLICT(account_id,kind,target) DO UPDATE SET paused=excluded.paused',
          [a[0], a[1], a[2], a[4] == true ? 1 : 0],
        );
      } else {
        db.execute(
          'DELETE FROM offline_requirements WHERE account_id=? AND kind=? AND target=?',
          [a[0], a[1], a[2]],
        );
      }
      return null;
    case 'importedNote':
      final a = argument as List;
      final rows = db.select(
        'SELECT note_id FROM import_items WHERE account_id=? AND source_key=?',
        [a[0], a[1]],
      );
      return rows.isEmpty ? null : rows.single['note_id'];
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
            jsonDecode(n as String) as Map<String, dynamic>,
          ),
        );
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
      if (a.length > 3 && a[3] != null) {
        final note = NextcloudNote.fromJson(
          Map<String, dynamic>.from(a[0] as Map),
        );
        db.execute(
          'INSERT INTO import_items(account_id,source_key,note_id) VALUES(?,?,?)',
          [note.accountId, a[3], note.localId],
        );
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
      for (final attachment in argument as List) {
        db.execute(
          'INSERT INTO attachments(id,note_id,data,bytes) VALUES(?,?,?,?)',
          (attachment as List).cast<Object?>(),
        );
      }
      return null;
    case 'attachmentSize':
      final rows = db.select(
        'SELECT length(bytes) AS size FROM attachments WHERE id=?',
        [argument],
      );
      return rows.isEmpty ? null : rows.single['size'];
    case 'attachmentBytes':
      final rows = db.select('SELECT bytes FROM attachments WHERE id=?', [
        argument,
      ]);
      return rows.isEmpty ? null : rows.first['bytes'];
    case 'updateAttachment':
      final a = argument as List;
      db.execute('UPDATE attachments SET data=? WHERE id=?', [a[1], a[0]]);
      if (a[2] != null) {
        _writeNote(
          db,
          NextcloudNote.fromJson(Map<String, dynamic>.from(a[2] as Map)),
        );
      }
      return null;
    case 'removeAttachment':
      db.execute('DELETE FROM attachments WHERE id=?', [argument]);
      return null;
    case 'close':
      return null;
    default:
      throw StateError('Unknown Notes storage operation.');
  }
}

void _createWorkspaceSchema(Database db) {
  // A runtime FTS5/trigram capability check uses the same native library as
  // durable notes. A lost derived index is recreated without touching outbox.
  final hadIndex = db
      .select("SELECT name FROM sqlite_master WHERE name='note_search'")
      .isNotEmpty;
  db.execute(
    'CREATE TABLE IF NOT EXISTS note_search_map(id TEXT PRIMARY KEY REFERENCES notes(id) ON DELETE CASCADE, docid INTEGER UNIQUE, revision INTEGER NOT NULL)',
  );
  db.execute(
    'CREATE VIRTUAL TABLE IF NOT EXISTS note_search USING fts5(id UNINDEXED, account UNINDEXED, revision UNINDEXED, title, category, body, tokenize="trigram")',
  );
  db.execute(
    'CREATE TRIGGER IF NOT EXISTS notes_search_delete BEFORE DELETE ON notes BEGIN DELETE FROM note_search WHERE rowid=(SELECT docid FROM note_search_map WHERE id=old.id); END',
  );
  if (!hadIndex ||
      db.select('SELECT count(*) AS n FROM note_search').single['n'] !=
          db
              .select('SELECT count(docid) AS n FROM note_search_map')
              .single['n']) {
    db.execute('DELETE FROM note_search');
    db.execute('DELETE FROM note_search_map');
  }
  db.execute(
    "CREATE TABLE IF NOT EXISTS offline_requirements(account_id TEXT NOT NULL REFERENCES accounts(id) ON DELETE CASCADE, kind TEXT NOT NULL CHECK(kind IN ('note','category','pause')), target TEXT NOT NULL, paused INTEGER NOT NULL DEFAULT 0, PRIMARY KEY(account_id,kind,target))",
  );
  db.execute(
    'CREATE TABLE IF NOT EXISTS import_items(account_id TEXT NOT NULL REFERENCES accounts(id) ON DELETE CASCADE, source_key TEXT NOT NULL, note_id TEXT NOT NULL REFERENCES notes(id), PRIMARY KEY(account_id,source_key))',
  ); // v6 namespaces imports by a durable reviewed operation. Existing v5 item
  // associations remain intact; they cannot suppress a deliberately new import.
  db.execute(
    "CREATE TABLE IF NOT EXISTS import_operations(account_id TEXT NOT NULL REFERENCES accounts(id) ON DELETE CASCADE, id TEXT NOT NULL, root TEXT NOT NULL, review TEXT NOT NULL, created_at INTEGER NOT NULL DEFAULT(unixepoch()), state TEXT NOT NULL CHECK(state IN ('pending','completed')), PRIMARY KEY(account_id,id))",
  );
}

void _indexNote(Database db, NextcloudNote note) {
  final existing = db.select(
    'SELECT s.rowid,s.revision,s.title,s.category,s.body FROM note_search s JOIN note_search_map m ON s.rowid=m.docid WHERE m.id=?',
    [note.localId],
  );
  if (note.syncState == NoteSyncState.deletedRemotely &&
      !note.hasPendingChanges) {
    if (existing.isNotEmpty) {
      db.execute('DELETE FROM note_search WHERE rowid=?', [
        existing.single['rowid'],
      ]);
    }
    db.execute(
      'INSERT INTO note_search_map(id,docid,revision) VALUES(?,NULL,?) ON CONFLICT(id) DO UPDATE SET docid=NULL,revision=excluded.revision',
      [note.localId, note.revision],
    );
    return;
  }
  final title = normalizeNotesSearch(note.title);
  final category = normalizeNotesSearch(note.category);
  final body = normalizeNotesSearch(note.content);
  if (existing.isNotEmpty &&
      existing.single['revision'] == note.revision &&
      existing.single['title'] == title &&
      existing.single['category'] == category &&
      existing.single['body'] == body) {
    return;
  }
  final rowid = existing.isEmpty ? null : existing.single['rowid'];
  if (rowid != null) {
    db.execute('DELETE FROM note_search WHERE rowid=?', [rowid]);
  }
  db.execute(
    'INSERT INTO note_search(rowid,id,account,revision,title,category,body) VALUES(?,?,?,?,?,?,?)',
    [rowid, note.localId, note.accountId, note.revision, title, category, body],
  );
  final docid = rowid ?? db.lastInsertRowId;
  db.execute(
    'INSERT INTO note_search_map(id,docid,revision) VALUES(?,?,?) ON CONFLICT(id) DO UPDATE SET docid=excluded.docid,revision=excluded.revision',
    [note.localId, docid, note.revision],
  );
}
