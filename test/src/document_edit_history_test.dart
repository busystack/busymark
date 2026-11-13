import 'package:flutter/services.dart';
import 'package:busymark/src/editor/document_edit_history.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'save acknowledgements preserve content ownership and ABA traversal invalidates it',
    () {
      final history = Object();
      final accepted = DocumentEditBase('same source', 1, history);
      expect(
        DocumentEditBase(
          'same source',
          1,
          Object(),
        ).sameDocumentVersion(accepted),
        isTrue,
        reason: 'Closing a group preserves the accepted content revision',
      );
      expect(
        DocumentEditBase(
          'same source',
          2,
          history,
        ).sameDocumentVersion(accepted),
        isTrue,
      );
      expect(
        DocumentEditBase(
          'same source',
          3,
          Object(),
        ).sameDocumentVersion(accepted),
        isFalse,
      );
      expect(
        DocumentEditBase(
          'different source',
          1,
          history,
        ).sameDocumentVersion(accepted),
        isFalse,
      );
    },
  );

  test('single-unit classification uses actual carets in repeated text', () {
    DocumentSimpleEditKind? kind(
      String before,
      String after,
      int oldCaret,
      int caret,
    ) => documentSimpleEditKind(
      before: before,
      after: after,
      previousSelection: TextSelection.collapsed(offset: oldCaret),
      selection: TextSelection.collapsed(offset: caret),
    );
    expect(kind('aaaa', 'aaaaa', 2, 3), DocumentSimpleEditKind.typing);
    expect(kind('aaaaaa', 'aaaaa', 4, 3), DocumentSimpleEditKind.backspace);
    expect(kind('aaaaaa', 'aaaaa', 3, 3), DocumentSimpleEditKind.delete);
    expect(kind('abc', 'ab\nc', 2, 3), isNull);
    expect(kind('ab\nc', 'abc', 3, 2), isNull);
    expect(kind('abc', 'abcx', 0, 4), isNull);
    expect(
      documentSimpleEditKind(
        before: 'aaaa',
        after: 'aaaaa',
        previousSelection: const TextSelection(baseOffset: 1, extentOffset: 3),
        selection: const TextSelection.collapsed(offset: 4),
      ),
      isNull,
    );
  });

  test('typing group has exact idle, total-age and size bounds', () {
    var now = Duration.zero;
    final groups = DocumentUndoGrouping(clock: () => now);
    String edit({bool continues = true}) =>
        groups.next(owner: 'document', continues: continues, size: 1);
    final first = edit(continues: false);
    now += const Duration(microseconds: 1999999);
    expect(edit(), first);
    now += DocumentUndoGrouping.idleLimit;
    final afterIdle = edit();
    expect(afterIdle, isNot(first));
    final start = now;
    for (var i = 1; i < 10; i++) {
      now = start + Duration(seconds: i);
      expect(edit(), afterIdle);
    }
    now = start + DocumentUndoGrouping.ageLimit;
    final afterAge = edit();
    expect(afterAge, isNot(afterIdle));
    for (var i = 1; i < DocumentUndoGrouping.sizeLimit; i++) {
      expect(edit(), afterAge);
    }
    expect(edit(), isNot(afterAge));
  });

  test('clock reversal, operation boundary and new lifetime close groups', () {
    var now = const Duration(seconds: 10);
    final groups = DocumentUndoGrouping(clock: () => now);
    String edit({bool continues = true}) =>
        groups.next(owner: 'document', continues: continues, size: 1);
    final first = edit();
    now -= const Duration(microseconds: 1);
    final reversed = edit();
    expect(reversed, isNot(first));
    expect(edit(continues: false), isNot(reversed));
    final recreated = DocumentUndoGrouping(clock: () => now);
    expect(
      recreated.next(owner: 'document', continues: false, size: 1),
      isNot(first),
    );
  });
}
