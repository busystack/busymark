import 'package:busymark/src/nextcloud_notes/domain/notes_conflict.dart';
import 'package:busymark/src/nextcloud_notes/domain/notes_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('identical changes do not need a choice', () {
    const merge = NotesAttributeMerge('base', 'same', 'same');
    expect(merge.conflicted, isFalse);
    expect(merge.resolve(), 'same');
  });
  test('boolean three-way truth table preserves all independent changes', () {
    // Two distinct changes from one boolean base cannot disagree: both must
    // equal !base. Missing base is the only genuinely ambiguous boolean case.
    for (final base in [false, true]) {
      for (final local in [false, true]) {
        for (final remote in [false, true]) {
          final merge = NotesAttributeMerge(base, local, remote);
          expect(merge.conflicted, isFalse);
          expect(merge.resolve(), local == base ? remote : local);
        }
      }
    }
  });
  test('favorite without a known base requires an explicit choice', () {
    const merge = NotesAttributeMerge<bool>(null, false, true);
    expect(merge.conflicted, isTrue);
    expect(merge.resolve, throwsA(isA<NotesException>()));
    expect(merge.resolve(NotesMergeChoice.local), isFalse);
    expect(merge.resolve(NotesMergeChoice.remote), isTrue);
  });
}
