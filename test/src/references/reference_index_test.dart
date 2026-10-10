import 'package:busymark/src/references/reference_index.dart';
import 'package:busymark/src/editor/wysiwyg/writerside_editing_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ParsedReferenceDocument doc(
    String name,
    String source, {
    bool available = true,
  }) => ParsedReferenceDocument(
    ReferenceDocument(
      identity: '/workspace/$name',
      path: '/workspace/$name',
      title: name,
      source: source,
      available: available,
    ),
  );
  test(
    'actual parser heading IDs distinguish duplicate names and Unicode targets',
    () {
      final target = doc('café.md', '# Title\n## Repeated\n## Repeated\n');
      final anchors = target.headings.map((h) => h.id).toList();
      expect(anchors.toSet().length, anchors.length);
      final source = doc(
        'source.md',
        '[one](caf%C3%A9.md#${anchors[1]}) [two](café.md#${anchors[2]}) [broken](café.md#absent)',
      );
      final index = ReferenceIndex(
        parsed: [source, target],
        root: '/workspace',
      );
      expect(index.references.map((r) => r.resolution), [
        ReferenceResolution.resolved,
        ReferenceResolution.resolved,
        ReferenceResolution.missing,
      ]);
      expect(
        index
            .query(target.document.identity, incoming: true, anchor: anchors[1])
            .total,
        1,
      );
    },
  );
  test(
    'unavailable files and uncached note IDs do not imply nonexistent targets',
    () {
      final index = ReferenceIndex(
        parsed: [
          doc('source.md', '[one](unreadable.md) [two](missing.md)'),
          doc('unreadable.md', '', available: false),
        ],
        root: '/workspace',
      );
      expect(index.references.map((r) => r.resolution), [
        ReferenceResolution.unavailable,
        ReferenceResolution.missing,
      ]);
      final notes = ReferenceIndex(
        parsed: [
          ParsedReferenceDocument(
            ReferenceDocument(
              identity: 'note',
              title: 'Note',
              source:
                  '[uncached](https://cloud.example/nc/index.php/apps/notes/note/42)',
              localId: 'note',
              serverId: 1,
            ),
          ),
        ],
        server: Uri.parse('https://cloud.example/nc'),
      );
      expect(
        notes.references.single.resolution,
        ReferenceResolution.unavailable,
      );
    },
  );
  test('every reference remains reachable through explicit continuation', () {
    final source = doc(
      'source.md',
      List.generate(357, (i) => '[link $i](target.md)').join(' '),
    );
    final index = ReferenceIndex(
      parsed: [source, doc('target.md', '# Target')],
      root: '/workspace',
    );
    final offsets = <int>[];
    int? cursor = 0;
    while (cursor != null) {
      final page = index.query(source.document.identity, offset: cursor);
      offsets.addAll(page.values.map((r) => r.authored.occurrence.startOffset));
      cursor = page.nextOffset;
    }
    expect(offsets.length, 357);
    expect(offsets.toSet().length, 357);
  });
  test('incremental reuse refreshes repaired anchors and changed targets', () {
    final source = doc('source.md', '[missing](target.md#added)');
    final untouched = doc('untouched.md', '[target](target.md)');
    final target = doc('target.md', '# Target');
    final initial = ReferenceIndex(
      parsed: [source, untouched, target],
      root: '/workspace',
    );
    final updated = ReferenceIndex(
      parsed: [source, untouched, doc('target.md', '# Target\n## Added')],
      root: '/workspace',
      previous: initial,
    );
    expect(
      updated.query(source.document.identity).values.single.resolution,
      ReferenceResolution.resolved,
    );
    expect(updated.query(target.document.identity, incoming: true).total, 2);
    final unavailable = ReferenceIndex(
      parsed: [source, untouched, doc('target.md', '', available: false)],
      root: '/workspace',
      previous: updated,
    );
    expect(
      unavailable.references.map((r) => r.resolution),
      everyElement(ReferenceResolution.unavailable),
    );
  });
  test(
    'XML source link uses semantic adapter and preserves namespace and formatting',
    () {
      const source =
          '<w:topic xmlns:w="urn:writerside" id="a"><w:p>one <w:b>bold</w:b> two</w:p></w:topic>';
      final start = source.indexOf('<w:b>'), end = source.indexOf(' two');
      final result = const WritersideEditingAdapter().insertSourceLink(
        filePath: 'a.topic',
        source: source,
        start: start,
        end: end,
        destination: 'other.topic#id',
        placeholder: 'text',
      );
      expect(
        result,
        contains('<w:a href="other.topic#id"><w:b>bold</w:b></w:a>'),
      );
      expect(
        result,
        startsWith('<w:topic xmlns:w="urn:writerside" id="a"><w:p>one '),
      );
    },
  );
  test(
    'XML attribute and partial element selections cannot receive a link',
    () {
      const source = '<topic id="a"><p>text <b>bold</b></p></topic>';
      for (final range in [(start: 11, end: 12), (start: 23, end: 25)]) {
        expect(
          const WritersideEditingAdapter().insertSourceLink(
            filePath: 'a.topic',
            source: source,
            start: range.start,
            end: range.end,
            destination: 'b.topic',
            placeholder: 'text',
          ),
          isNull,
        );
      }
    },
  );
}
