import 'package:busymark/src/editor/wysiwyg/writerside_inspector_target.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_document_controller.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/writerside/writerside_effective_properties.dart';
import 'package:busymark/src/writerside/writerside_model.dart';
import 'package:busymark/src/writerside/writerside_schema.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_commands.dart';

BusyDocument parse(String text) => const MarkdownParser()
    .parse(
      filePath: 'lists.md',
      source: text,
      mode: MarkdownMode.writersideMarkdown,
      validateLocalReferences: false,
    )
    .busyDocument;
Iterable<BusyBlock> walk(Iterable<BusyBlock> blocks) sync* {
  for (final b in blocks) {
    yield b;
    yield* walk(b.children);
  }
}

List<BusyBlock> lists(BusyDocument d) =>
    walk(d.blocks).where((b) => b.attributes['element'] == 'list').toList();

void main() {
  for (final marker in ['-', '3.', '- [ ]']) {
    for (final clear in [false, true]) {
      test(
        'leading Enter retains native $marker parent ownership after publication clear=$clear',
        () {
          final indent = marker == '3.' ? '   ' : '  ';
          final c = BusyMarkWysiwygDocumentController(
            document: parse(
              '$marker Parent\n$indent- Child\n$indent  - Grandchild\n\n{id="owner"}\n',
            ),
          );
          addTearDown(c.dispose);
          final parent = walk(
            c.document.blocks,
          ).singleWhere((b) => b.plainText == 'Parent');
          final childIds = walk(parent.children).map((b) => b.id).toList();
          if (clear) {
            c.updateBlockText(parent.id, '');
            c.rebaseCommittedSource(c.markdown);
          }
          final result = c.applyEnterAt(parent.id, 0);
          expect(result?.blockId, parent.id);
          final published = c.markdown;
          c.rebaseCommittedSource(published);
          expect(c.markdown, published);
          final retained = c.blockById(parent.id)!;
          expect(retained.kind, parent.kind);
          if (marker == '3.') expect(retained.attributes['marker'], '4.');
          expect(
            walk(
              retained.children,
            ).where((b) => childIds.contains(b.id)).map((b) => b.id),
            childIds,
          );
          final owner = c.elementPath(parent.id).reversed.skip(1).first;
          expect(owner.attributes['busymark-list-form'], 'markdown');
          expect(owner.attributes['id'], 'owner');
          expect(owner.children.first.id, isNot(parent.id));
          expect(owner.children.first.children, isEmpty);
          final reopened = parse(published);
          expect(
            walk(reopened.blocks).where((b) => b.plainText == 'Child'),
            hasLength(1),
          );
          expect(
            walk(reopened.blocks).where((b) => b.plainText == 'Grandchild'),
            hasLength(1),
          );
        },
      );
    }
  }

  test('an authored empty paragraph is not discarded by heading Backspace', () {
    final c = BusyMarkWysiwygDocumentController(
      document: parse('# Topic\n\nClear\n{id="authored"}\n\n## Heading\n'),
    );
    addTearDown(c.dispose);
    final paragraph = c.document.blocks.singleWhere(
      (b) => b.kind == BusyBlockKind.paragraph,
    );
    final heading = c.document.blocks.last;
    c.updateBlockText(paragraph.id, '');
    final result = c.applyBackspaceAtStart(heading.id);
    expect(result?.blockId, paragraph.id);
    expect(c.blockById(paragraph.id)!.attributes['id'], 'authored');
    expect(c.markdown, contains('id="authored"'));
  });

  test(
    'block lookup follows edits and replacement revisions with reused IDs',
    () {
      final c = BusyMarkWysiwygDocumentController(
        document: parse('# One\n\n## Two\n\nParagraph\n'),
      );
      addTearDown(c.dispose);
      final target = c.document.blocks.last;
      expect(c.elementPath(target.id).map((b) => b.plainText), [
        'One',
        'Two',
        'Paragraph',
      ]);
      c.elementPath(target.id).clear();
      expect(c.elementPath(target.id).last.plainText, 'Paragraph');
      c.updateBlockText(target.id, 'Edited');
      expect(c.blockById(target.id)!.plainText, 'Edited');
      expect(c.elementPath(target.id).last.plainText, 'Edited');
      final next = parse('# New owner\n\nReplacement\n');
      c.replaceDocument(
        next.copyWith(
          blocks: [
            next.blocks.first,
            next.blocks.last.copyWith(id: target.id),
          ],
        ),
      );
      expect(c.blockById(target.id)!.plainText, 'Replacement');
      expect(c.elementPath(target.id).map((b) => b.plainText), [
        'New owner',
        'Replacement',
      ]);
      expect(c.blockById('missing'), isNull);
      expect(c.elementPath('missing'), isEmpty);
    },
  );

  test(
    'deleting list members removes their empty owner and rejects the captured target',
    () {
      const source = 'Before\n\n- First\n- Second\n\n{id="owner"}\n\nAfter\n';
      final c = BusyMarkWysiwygDocumentController(document: parse(source));
      addTearDown(c.dispose);
      final owner = lists(c.document).single;
      final captured = WritersideInspectorTarget.fromSelection(
        bufferId: 'b',
        revision: 1,
        source: source,
        document: c.document,
        blockId: owner.id,
      );
      final before = c.document.blocks.first;
      final after = c.document.blocks.last;
      expect(
        c.deleteTextSelection(
          firstBlockId: before.id,
          firstStartOffset: 0,
          lastBlockId: after.id,
          lastEndOffset: after.plainText.length,
          removedBlockIds: walk(c.document.blocks).map((b) => b.id),
        ),
        isNotNull,
      );
      expect(lists(c.document), isEmpty);
      expect(c.markdown, isNot(contains('owner')));
      expect(
        captured.refreshUnchangedElement(
          revision: 2,
          source: c.markdown,
          document: c.document,
        ),
        isNull,
      );
      expect(c.updateWritersideProperty(owner.id, 'id', 'unrelated'), isFalse);
      c.updateBlockText(c.document.blocks.first.id, 'New content');
      expect(c.markdown, contains('New content'));
    },
  );
  for (final marker in ['3)', '+', '*', '-']) {
    test(
      'ordinary caption editing retains native marker spelling ($marker)',
      () {
        final secondMarker = marker == '3)' ? '4)' : marker;
        final c = BusyMarkWysiwygDocumentController(
          document: parse('$marker First\n$secondMarker Second\n'),
        );
        addTearDown(c.dispose);
        final second = lists(c.document).single.children.last.id;
        c.updateBlockText(second, 'Second edited');
        c.rebaseCommittedSource(c.markdown);
        expect(
          c.markdown,
          contains('$marker First\n$secondMarker Second edited'),
        );
        expect(lists(c.document), hasLength(1));
        expect(lists(c.document).single.children.last.id, second);
      },
    );
  }
  test(
    'multi-item indent/outdent preserves order and each level numbering',
    () {
      final c = BusyMarkWysiwygDocumentController(
        document: parse('3. Parent\n4. Second\n5. Third\n'),
      );
      addTearDown(c.dispose);
      final ids = lists(
        c.document,
      ).single.children.skip(1).map((b) => b.id).toList();
      expect(c.indentListItems(ids), isTrue);
      c.rebaseCommittedSource(c.markdown);
      expect(
        lists(c.document).last.children.map((b) => b.attributes['marker']),
        ['1.', '2.'],
      );
      expect(c.outdentListItems(ids), isTrue);
      c.rebaseCommittedSource(c.markdown);
      expect(lists(c.document).single.children.map((b) => b.plainText), [
        'Parent',
        'Second',
        'Third',
      ]);
      expect(
        lists(c.document).single.children.map((b) => b.attributes['marker']),
        ['3.', '4.', '5.'],
      );
      expect(lists(c.document).single.children.skip(1).map((b) => b.id), ids);
    },
  );
  test('bulk promotion cannot discard the whole list settings', () {
    final c = BusyMarkWysiwygDocumentController(
      document: parse('- First\n- Second\n\n{id="owner"}\n'),
    );
    addTearDown(c.dispose);
    final original = c.markdown;
    c.applyBlockCommandToBlocks(
      lists(c.document).single.children.map((b) => b.id),
      BusyWysiwygBlockCommand.paragraph,
    );
    expect(c.markdown, original);
  });
  test(
    'list attribute edits rebind later embedded XML descendants to current source',
    () {
      const source =
          '- Item\n\n<chapter id="xml" title="XML"><p id="body">%product%<br/>%product%</p></chapter>\n';
      final c = BusyMarkWysiwygDocumentController(document: parse(source));
      addTearDown(c.dispose);
      expect(
        c.updateWritersideProperty(
          lists(c.document).single.id,
          'id',
          'whole-list',
        ),
        isTrue,
      );
      c.rebaseCommittedSource(c.markdown);
      final paragraph = walk(
        c.document.blocks,
      ).singleWhere((b) => b.attributes['id'] == 'body');
      expect(
        paragraph.sourceSpan!.startOffset,
        c.markdown.indexOf('<p id="body"'),
      );
      final target = WritersideInspectorTarget.fromSource(
        bufferId: 'b',
        revision: 2,
        source: c.markdown,
        document: c.document,
        selection: TextSelection.collapsed(
          offset: c.markdown.lastIndexOf('%product%') + 1,
        ),
      );
      expect(target.block?.id, paragraph.id);
      expect(target.inline?.start, 8);
    },
  );
  test('Backspace merges native members without dropping list properties', () {
    final c = BusyMarkWysiwygDocumentController(
      document: parse('- First\n- Second\n\n{id="owner"}\n'),
    );
    addTearDown(c.dispose);
    final second = lists(c.document).single.children.last.id;
    expect(c.applyBackspaceAtStart(second), isNotNull);
    c.rebaseCommittedSource(c.markdown);
    expect(lists(c.document).single.attributes['id'], 'owner');
    expect(lists(c.document).single.children.single.plainText, 'FirstSecond');
  });
  test(
    'promoting the last member cannot silently discard authored list state',
    () {
      final c = BusyMarkWysiwygDocumentController(
        document: parse('- Only\n\n{id="owner"}\n'),
      );
      addTearDown(c.dispose);
      final id = lists(c.document).single.children.single.id;
      final original = c.markdown;
      c.applyBlockCommand(id, BusyWysiwygBlockCommand.paragraph);
      expect(c.markdown, original);
    },
  );
  test('indent and outdent keep real owners and every authored item', () {
    const source = '- First\n- Second\n- Third\n';
    final c = BusyMarkWysiwygDocumentController(document: parse(source));
    addTearDown(c.dispose);
    final second = lists(c.document).single.children[1].id;
    expect(c.indentListItems([second]), isTrue);
    c.rebaseCommittedSource(c.markdown);
    expect(lists(c.document), hasLength(2));
    expect(lists(c.document).last.children.single.id, second);
    expect(c.outdentListItems([second]), isTrue);
    c.rebaseCommittedSource(c.markdown);
    expect(lists(c.document), hasLength(1));
    expect(lists(c.document).single.children.map((b) => b.plainText), [
      'First',
      'Second',
      'Third',
    ]);
  });

  test('quoted native lists have occurrence-specific source boundaries', () {
    const source = '> - First\n>   - Nested\n> - Second\n\nAfter.\n';
    final d = parse(source);
    final all = lists(d);
    expect(all, hasLength(2));
    expect(all.first.sourceSpan!.startOffset, source.indexOf('- First'));
    expect(all.last.sourceSpan!.startOffset, source.indexOf('- Nested'));
    final c = BusyMarkWysiwygDocumentController(document: d);
    addTearDown(c.dispose);
    expect(c.updateWritersideProperty(all.last.id, 'id', 'nested'), isTrue);
    final edited = c.markdown;
    expect(lists(parse(edited)).last.attributes['id'], 'nested');
    expect(lists(parse(edited)).first.attributes['id'], isNull);
    expect(edited, endsWith('\n\nAfter.\n'));
  });
  test(
    'newly typed and split lists acquire parser ownership without losing editing IDs',
    () {
      final c = BusyMarkWysiwygDocumentController(document: parse('Text\n'));
      addTearDown(c.dispose);
      final first = c.document.blocks.first.id;
      c.applyBlockCommand(first, BusyWysiwygBlockCommand.unorderedList);
      c.rebaseCommittedSource(c.markdown);
      expect(lists(c.document), hasLength(1));
      expect(lists(c.document).single.children.single.id, first);
      final second = c.applyEnterAt(first, 4)!.blockId;
      c.updateBlockText(second, 'Second');
      c.rebaseCommittedSource(c.markdown);
      expect(lists(c.document).single.children.map((b) => b.id), [
        first,
        second,
      ]);
      expect(c.elementPath(second).first.attributes['element'], 'list');
      expect(
        c.updateWritersideProperty(lists(c.document).single.id, 'columns', '2'),
        isTrue,
      );
      c.rebaseCommittedSource(c.markdown);
      c.updateBlockText(second, 'Second edited');
      c.rebaseCommittedSource(c.markdown);
      expect(c.markdown, contains('Second edited'));
      expect(parse(c.markdown).blocks.first.attributes['columns'], '2');
    },
  );

  test(
    'list splitting preserves list attributes and promotes ordinary content',
    () {
      final c = BusyMarkWysiwygDocumentController(
        document: parse('- First\n- Middle\n- Last\n\n{id="original-list"}\n'),
      );
      addTearDown(c.dispose);
      final middle = lists(c.document).single.children[1].id;
      c.applyBlockCommand(middle, BusyWysiwygBlockCommand.paragraph);
      c.rebaseCommittedSource(c.markdown);
      expect(lists(c.document), hasLength(2));
      expect(lists(c.document).first.attributes['id'], 'original-list');
      expect(lists(c.document).last.attributes['id'], isNull);
      expect(c.blockById(middle)!.kind, BusyBlockKind.paragraph);
      expect(c.blockById(middle)!.plainText, 'Middle');
      expect(
        c.elementPath(middle).any((b) => b.attributes['element'] == 'list'),
        isFalse,
      );
      expect(c.markdown, contains('Middle'));
    },
  );
  test(
    'parser owns loose, nested, mixed and adjacent distinct lists before attributes',
    () {
      const source =
          '# Topic\n\n## Chapter\n\n3. Parent **caption**\n\n   Second paragraph.\n\n   4. Nested first\n   5. Nested second\n\n4. Sibling\n\n+ [x] Done\n+ Pending\n\n- Separate first\n- Separate second\n';
      final d = parse(source);
      final c = BusyMarkWysiwygDocumentController(document: d);
      addTearDown(c.dispose);
      expect(lists(d), hasLength(4));
      final outer = lists(d).first;
      expect(outer.children.map((b) => b.plainText), [
        'Parent caption',
        'Sibling',
      ]);
      final parent = outer.children.first;
      expect(parent.children.first.plainText, 'Second paragraph.');
      final nested = parent.children.last;
      expect(nested.attributes['element'], 'list');
      expect(nested.sourceSpan!.startOffset, source.indexOf('4. Nested first'));
      final item = nested.children.last;
      expect(item.sourceSpan!.startOffset, source.indexOf('5. Nested second'));
      expect(c.elementPath(item.id).map((b) => b.id), [
        d.blocks[0].id,
        d.blocks[1].id,
        outer.id,
        parent.id,
        nested.id,
        item.id,
      ]);
      expect(lists(d)[2].children.map((b) => b.kind), [
        BusyBlockKind.taskListItem,
        BusyBlockKind.unorderedListItem,
      ]);
      expect(c.markdown, source);
      expect(walk(c.document.blocks).any((b) => b.dirty), isFalse);
      final fromSource = WritersideInspectorTarget.fromSource(
        bufferId: 'b',
        revision: 1,
        source: source,
        document: d,
        selection: TextSelection.collapsed(
          offset: source.indexOf('5. Nested second') + 3,
        ),
      );
      expect(fromSource.block?.id, item.id);
    },
  );

  for (final newline in ['\n', '\r\n']) {
    test('whole-list attributes preserve native source and reset ($newline)', () {
      final source =
          '# Topic\n\n3) Parent **caption** [guide](guide.md)\n\n   Second paragraph.\n\n   4) Nested first\n   5) Nested second\n\n1) Sibling\n\nAfter.\n'
              .replaceAll('\n', newline);
      final c = BusyMarkWysiwygDocumentController(document: parse(source));
      addTearDown(c.dispose);
      final list = lists(c.document).first;
      for (final field in {
        'id': 'whole-list',
        'start': '10',
        'columns': '2',
        'sorted': 'asc',
      }.entries) {
        expect(
          c.updateWritersideProperty(list.id, field.key, field.value),
          isTrue,
        );
      }
      final saved = c.markdown;
      expect(saved, isNot(contains('<list')));
      expect(saved, contains('3) Parent **caption** [guide](guide.md)'));
      expect(saved, contains('1) Sibling$newline$newline{id="whole-list"'));
      expect(
        saved,
        contains('Second paragraph.$newline$newline   4) Nested first'),
      );
      final reopened = parse(saved);
      expect(lists(reopened).first.attributes['start'], '10');
      expect(lists(reopened).first.attributes['sorted'], 'asc');
      expect(lists(reopened).last.attributes['start'], isNull);
      expect(
        lists(reopened).first.children.every((b) => b.attributes['id'] == null),
        isTrue,
      );
      for (final field in ['id', 'start', 'columns', 'sorted']) {
        expect(c.updateWritersideProperty(list.id, field, null), isTrue);
      }
      expect(c.markdown, source);
    });
  }

  test(
    'nested-list property edits preserve its parent and surrounding indentation',
    () {
      const source =
          '3. Parent\n\n   Extra paragraph.\n\n   4. Nested first\n   5. Nested second\n\n4. Sibling\n\nAfter.\n';
      final c = BusyMarkWysiwygDocumentController(document: parse(source));
      addTearDown(c.dispose);
      final nested = lists(c.document).last;
      expect(c.updateWritersideProperty(nested.id, 'id', 'nested'), isTrue);
      expect(c.updateWritersideProperty(nested.id, 'start', '12'), isTrue);
      final saved = c.markdown;
      expect(
        saved,
        startsWith(
          '3. Parent\n\n   Extra paragraph.\n\n   4. Nested first\n   5. Nested second',
        ),
      );
      expect(saved, contains('\n\n   {id="nested" start="12"}\n\n4. Sibling'));
      expect(saved, endsWith('\n\nAfter.\n'));
      final reopened = parse(saved);
      expect(lists(reopened).first.attributes['start'], isNull);
      expect(lists(reopened).last.attributes['start'], '12');
      expect(lists(reopened).last.attributes['id'], 'nested');
      expect(c.updateWritersideProperty(nested.id, 'id', null), isTrue);
      expect(c.updateWritersideProperty(nested.id, 'start', null), isTrue);
      expect(c.markdown, source);
    },
  );

  test(
    'mixed markers block lossy item conversion while whole-list edits remain native',
    () {
      const source =
          '- [x] Done **item**\n- Plain item\n- [ ] Pending\n\n{id="whole-list" columns="2"}\n';
      final c = BusyMarkWysiwygDocumentController(document: parse(source));
      addTearDown(c.dispose);
      final owner = lists(c.document).single;
      for (final item in owner.children) {
        expect(
          c.updateWritersideProperty(item.id, 'id', 'item-anchor'),
          isFalse,
        );
        expect(c.markdown, source);
      }
      expect(c.updateWritersideProperty(owner.id, 'columns', '3'), isTrue);
      final saved = parse(c.markdown);
      expect(lists(saved).single.attributes['columns'], '3');
      expect(lists(saved).single.children.map((b) => b.kind), [
        BusyBlockKind.taskListItem,
        BusyBlockKind.unorderedListItem,
        BusyBlockKind.taskListItem,
      ]);
      expect(lists(saved).single.children.first.attributes['task'], 'true');
      expect(lists(saved).single.children.last.attributes['task'], 'false');
      expect(c.markdown, isNot(contains('<list')));
    },
  );
  test(
    'homogeneous task item conversion preserves checked and unchecked editing states',
    () {
      const source =
          '+ [x] Done **item**\n+ [ ] Pending\n\n{id="whole-list" columns="2"}\n';
      final c = BusyMarkWysiwygDocumentController(document: parse(source));
      addTearDown(c.dispose);
      expect(
        c.updateWritersideProperty(
          lists(c.document).single.children.last.id,
          'id',
          'pending',
        ),
        isTrue,
      );
      final owner = lists(parse(c.markdown)).single;
      expect(owner.attributes['type'], 'checkbox');
      expect(owner.attributes['id'], 'whole-list');
      expect(owner.attributes['columns'], '2');
      final items = owner.children
          .where((b) => b.attributes['element'] == 'li')
          .toList();
      expect(items, hasLength(2));
      expect(
        items.map((b) => b.kind),
        everyElement(BusyBlockKind.taskListItem),
      );
      expect(items.first.attributes['task'], 'true');
      expect(items.last.attributes['task'], 'false');
      expect(items.last.attributes['id'], 'pending');
    },
  );

  test(
    'independent list eligibility includes narrowly supported checkbox and numeric domains',
    () {
      expect(WritersideSchema.valuesFor('list', 'type'), {
        'bullet',
        'decimal',
        'alpha-lower',
        'checkbox',
        'none',
      });
      expect(WritersideSchema.valuesFor('list', 'sorted'), {
        'none',
        'asc',
        'desc',
      });
      for (final value in ['0', '-1', '6', '1.5', 'text']) {
        expect(
          WritersideSchema.invalidAttributeValue('list', 'columns', value),
          isNotNull,
        );
      }
      for (final value in ['1', '2', '5']) {
        expect(
          WritersideSchema.invalidAttributeValue('list', 'columns', value),
          isNull,
        );
      }
      expect(
        WritersideSchema.invalidAttributeValue('list', 'start', '0'),
        isNotNull,
      );
      expect(
        WritersideSchema.invalidAttributeValue('list', 'start', '12'),
        isNull,
      );
      expect(
        WritersideSchema.invalidAttributeValue('list', 'type', 'invented'),
        isNotNull,
      );
    },
  );

  test(
    'marker-derived style/start and module defaults have builder-verified precedence',
    () {
      const r = WritersideEffectiveProperties(
        settings: WritersideSettingsConfig(
          defaultProperties: [
            WritersideDefaultProperty(
              elementName: 'list',
              propertyName: 'type',
              value: 'alpha-lower',
            ),
            WritersideDefaultProperty(
              elementName: 'list',
              propertyName: 'start',
              value: '5',
            ),
          ],
        ),
      );
      final seven = {
        'busymark-native-list-type': 'decimal',
        'busymark-native-list-start': '7',
      };
      expect(r.resolve('list', 'type', seven).value, 'decimal');
      expect(
        r.resolve('list', 'type', seven).origin,
        WritersidePropertyOrigin.markdownMarker,
      );
      expect(r.resolve('list', 'start', seven).value, '7');
      expect(r.resolve('list', 'start', {...seven, 'start': '9'}).value, '9');
      expect(
        r.resolve('list', 'start', {
          ...seven,
          'busymark-native-list-start': '1',
        }).value,
        '5',
      );
      expect(
        r.resolve('list', 'type', {
          'busymark-native-list-type': 'bullet',
        }).value,
        'alpha-lower',
      );
    },
  );
}
