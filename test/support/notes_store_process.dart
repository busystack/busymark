import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:busymark/src/nextcloud_notes/data/notes_store.dart';
import 'package:busymark/src/nextcloud_notes/domain/notes_models.dart';

Future<void> main(List<String> arguments) async {
  final store = await NotesStore.open(path: arguments.single);
  var cached = (await store.notes()).single;
  final account = (await store.accounts()).single;
  Completer<void>? release;
  Future<void>? request;
  void reply(Object value) => stdout.writeln(jsonEncode(value));
  reply({'ready': true, 'note': cached.toJson()});
  await for (final line
      in stdin.transform(utf8.decoder).transform(const LineSplitter())) {
    final command = jsonDecode(line) as Map;
    try {
      switch (command['action']) {
        case 'save':
          final next = cached.copyWith(
            content: command['content'] as String,
            revision: cached.revision + 1,
            syncState: NoteSyncState.pending,
          );
          await store.saveNote(next);
          cached = next;
        case 'ack':
          final next = cached.copyWith(
            ackRevision: cached.revision,
            syncState: NoteSyncState.synced,
          );
          await store.saveNote(next);
          cached = next;
        case 'hold':
          release = Completer<void>();
          final started = Completer<void>();
          request = store.withRequestOwnership(account.id, () async {
            cached = cached.copyWith(syncState: NoteSyncState.syncing);
            await store.saveNote(cached);
            started.complete();
            await release!.future;
          });
          request.catchError((Object error, StackTrace stack) {
            if (!started.isCompleted) started.completeError(error, stack);
          });
          await started.future;
        case 'release':
          release!.complete();
          await request;
        case 'read':
          reply({'note': (await store.notes()).single.toJson()});
          continue;
        case 'close':
          await store.close();
          reply({'ok': true});
          return;
      }
      reply({'ok': true});
    } on NotesException catch (error) {
      reply({'conflict': error.code == NotesFailureCode.conflict});
    }
  }
  await store.close();
}
