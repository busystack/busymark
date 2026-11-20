import 'dart:io';

import 'package:busymark/src/nextcloud_notes/data/notes_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('invalid generation metadata fails open and permits repair', () async {
    final directory = await Directory.systemTemp.createTemp(
      'notes-generation-open-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final path = '${directory.path}/notes.sqlite3';
    final store = await NotesStore.open(path: path);
    await store.close();
    final fixture = sqlite3.open(path);
    try {
      fixture.execute(
        "INSERT INTO store_versions VALUES ('notes', 'retired', 'invalid')",
      );
      fixture.execute('CREATE TABLE outbox (id TEXT PRIMARY KEY, data TEXT)');
      fixture.execute("INSERT INTO outbox VALUES ('pending', 'retain')");
      fixture.execute('PRAGMA user_version=6');
    } finally {
      fixture.close();
    }
    for (var cycle = 0; cycle < 3; cycle++) {
      await expectLater(
        NotesStore.open(path: path).timeout(const Duration(seconds: 5)),
        throwsStateError,
      );
      final inspection = sqlite3.open(path);
      try {
        expect(
          inspection.select('PRAGMA user_version').single.values.single,
          6,
        );
        expect(
          inspection.select('SELECT data FROM outbox').single['data'],
          'retain',
        );
        expect(inspection.select('SELECT * FROM store_sessions'), isEmpty);
        inspection.execute('BEGIN IMMEDIATE');
        if (cycle == 2) inspection.execute('DELETE FROM store_versions');
        inspection.execute('COMMIT');
      } finally {
        inspection.close();
      }
    }
    final repaired = await NotesStore.open(path: path);
    expect(await repaired.notes(), isEmpty);
    await repaired.close();
  });

  for (final schema in [3, 8]) {
    test('failed v$schema open releases SQLite before reporting failure', () async {
      final directory = await Directory.systemTemp.createTemp(
        'notes-failed-open-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final path = '${directory.path}/notes.sqlite3';
      final store = await NotesStore.open(path: path);
      await store.close();
      final fixture = sqlite3.open(path);
      try {
        fixture.execute("INSERT INTO accounts VALUES ('fixture', '{}')");
        fixture.execute(
          "INSERT INTO notes (id, account_id, data) VALUES ('fixture', 'fixture', '{}')",
        );
        fixture.execute('DROP TRIGGER IF EXISTS notes_search_delete');
        for (final table in [
          'note_search',
          'note_search_map',
          'offline_requirements',
          'import_items',
          'import_operations',
        ]) {
          fixture.execute('DROP TABLE IF EXISTS $table');
        }
        fixture.execute('PRAGMA user_version=$schema');
      } finally {
        fixture.close();
      }

      // Exercise the real isolate/SQLite race repeatedly, without a busy
      // timeout or retries. Once open fails, immediate inspection and writes
      // must work and the migration fence must remain unchanged.
      for (var cycle = 0; cycle < 80; cycle++) {
        await expectLater(NotesStore.open(path: path), throwsStateError);
        final inspection = sqlite3.open(path);
        try {
          expect(
            inspection.select('PRAGMA user_version').single.values.single,
            schema,
          );
          expect(
            inspection.select(
              "SELECT name FROM sqlite_master WHERE name IN ('note_search','offline_requirements','import_items','import_operations')",
            ),
            isEmpty,
          );
          inspection.execute('BEGIN IMMEDIATE');
          inspection.execute('ROLLBACK');
        } finally {
          inspection.close();
        }
      }
    });
  }
}
