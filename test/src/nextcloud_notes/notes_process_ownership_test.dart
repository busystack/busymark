import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:busymark/src/nextcloud_notes/application/notes_repository.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_store.dart';
import 'package:busymark/src/nextcloud_notes/domain/notes_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'notes_api_test.dart' show testAccount, testNote;

void main() {
  late Directory root;
  late String path;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('notes-process-cas-');
    path = p.join(root.path, 'notes.db');
    final store = await NotesStore.open(path: path);
    await store.saveAccount(testAccount());
    await store.saveNote(testNote(serverId: null));
    await store.close();
  });
  tearDown(() => root.delete(recursive: true));
  final conflict = throwsA(
    isA<NotesException>().having(
      (e) => e.code,
      'code',
      NotesFailureCode.conflict,
    ),
  );

  Future<NotesRepository> repository() async {
    final r = NotesRepository(
      store: await NotesStore.open(path: path),
      clientForAccount: (_) async =>
          throw StateError('No network in local save test'),
    );
    await r.initialize();
    addTearDown(r.dispose);
    return r;
  }

  test(
    'independent repository caches reject stale content and retain the editor proposal',
    () async {
      final a = await repository(), b = await repository();
      final original = b.notes.single;
      await a.save(original.localId, content: 'A');
      await expectLater(b.save(original.localId, content: 'B'), conflict);
      await expectLater(
        b.save(original.localId, content: original.content),
        conflict,
      );
      expect(a.notes.single.content, 'A');
      expect(
        b.notes.single.content,
        original.content,
        reason: 'Failed durability never advances the cache',
      );
      expect((await b.store.notes()).single.content, 'A');
      // Even a fresh observational read cannot authorize the stale cached edit.
      await expectLater(b.save(original.localId, content: 'B'), conflict);
    },
  );

  test(
    'deleted cached identities block remote requests before any network operation',
    () async {
      final r = await repository();
      final external = await NotesStore.open(path: path);
      addTearDown(external.close);
      await external.commit(removeNotes: [r.notes.single.localId]);
      await expectLater(r.delete(r.notes.single.localId), conflict);
      expect(await external.notes(), isEmpty);
    },
  );

  test(
    'independent processes reject stale edits and acknowledgments without revision changes',
    () async {
      final a = await _Peer.open(path), b = await _Peer.open(path);
      addTearDown(a.stop);
      addTearDown(b.stop);
      expect(await a.call({'action': 'ack'}), {'ok': true});
      expect(await b.call({'action': 'save', 'content': 'B'}), {
        'conflict': true,
      });
      // The acknowledgment changed durable state without incrementing revision.
      expect(await b.call({'action': 'ack'}), {'conflict': true});
      final current = (await a.call({'action': 'read'}))['note'] as Map;
      expect(current['content'], 'body');
      expect(current['ackRevision'], current['revision']);
    },
  );

  test(
    'startup leaves a live request alone; process death permits crash recovery',
    () async {
      final owner = await _Peer.open(path);
      addTearDown(owner.stop);
      expect(await owner.call({'action': 'hold'}), {'ok': true});
      final observer = await NotesStore.open(path: path);
      expect((await observer.notes()).single.syncState, NoteSyncState.syncing);
      await expectLater(
        observer.withRequestOwnership(testAccount().id, () async {}),
        conflict,
      );
      await expectLater(
        observer.saveNote(testNote(serverId: null, content: 'foreign')),
        conflict,
      );
      await observer.close();
      owner.process.kill(ProcessSignal.sigkill);
      await owner.process.exitCode;
      final recovered = await NotesStore.open(path: path);
      addTearDown(recovered.close);
      expect(
        (await recovered.notes()).single.syncState,
        NoteSyncState.creationUncertain,
      );
      expect((await recovered.notes()).single.content, 'body');
    },
  );

  test(
    'closing a store drains active requests before releasing their claim',
    () async {
      final owner = await NotesStore.open(path: path);
      final observer = await NotesStore.open(path: path);
      addTearDown(observer.close);
      final entered = Completer<void>(), release = Completer<void>();
      final request = owner.withRequestOwnership(testAccount().id, () async {
        entered.complete();
        await release.future;
      });
      await entered.future;
      var closed = false;
      final closing = owner.close().then((_) {
        closed = true;
      });
      await Future<void>.delayed(Duration.zero);
      expect(closed, isFalse);
      await expectLater(
        observer.withRequestOwnership(testAccount().id, () async {}),
        conflict,
      );
      release.complete();
      await request;
      await closing;
      await observer.withRequestOwnership(testAccount().id, () async {});
    },
  );

  test(
    'attachment metadata and bytes plus removals share the persisted fence',
    () async {
      final a = await NotesStore.open(path: path);
      final note = (await a.notes()).single;
      final attachment = NotesAttachment(
        id: 'attachment',
        noteId: note.localId,
        filename: 'a.bin',
        reference: 'busymark-attachment:fixture',
      );
      await a.saveAttachment(attachment, Uint8List.fromList([1, 2]));
      final b = await NotesStore.open(path: path);
      addTearDown(a.close);
      addTearDown(b.close);
      final old = (await b.attachments()).single;
      await a.updateAttachment(
        NotesAttachment(
          id: old.id,
          noteId: old.noteId,
          filename: old.filename,
          reference: old.reference,
          state: 'uploading',
        ),
      );
      await a.saveNote(note.copyWith(syncState: NoteSyncState.syncing));
      await expectLater(b.updateAttachment(old), conflict);
      await expectLater(b.removeAccount(note.accountId), conflict);
      expect(await b.attachmentBytes(old.id), [1, 2]);
      expect((await b.attachments()).single.state, 'uploading');
      await expectLater(
        b.createWithAttachments(
          note.copyWith(content: 'stale'),
          [],
          additionalNotes: [note],
        ),
        conflict,
      );
      expect((await b.notes()).single.content, 'body');
    },
  );
}

class _Peer {
  _Peer(this.process, this.messages);
  final Process process;
  final StreamIterator<String> messages;
  bool _stopped = false;
  static Future<_Peer> open(String path) async {
    final dart = p.join(
      Platform.environment['FLUTTER_ROOT']!,
      'bin',
      'cache',
      'dart-sdk',
      'bin',
      'dart',
    );
    final process = await Process.start(dart, [
      'run',
      'test/support/notes_store_process.dart',
      path,
    ]);
    final errors = <String>[];
    process.stderr.transform(utf8.decoder).listen(errors.add);
    final messages = StreamIterator(
      process.stdout.transform(utf8.decoder).transform(const LineSplitter()),
    );
    if (!await messages.moveNext().timeout(const Duration(seconds: 90))) {
      throw StateError('Notes peer failed: ${errors.join()}');
    }
    expect(jsonDecode(messages.current)['ready'], isTrue);
    return _Peer(process, messages);
  }

  Future<Map<String, dynamic>> call(Map<String, Object?> command) async {
    process.stdin.writeln(jsonEncode(command));
    await process.stdin.flush();
    if (!await messages.moveNext().timeout(const Duration(seconds: 30))) {
      throw StateError('Notes peer exited');
    }
    return jsonDecode(messages.current) as Map<String, dynamic>;
  }

  Future<void> stop() async {
    if (_stopped) return;
    _stopped = true;
    process.kill();
    await process.exitCode;
    await messages.cancel();
  }
}
