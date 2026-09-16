import 'dart:io';

import 'package:busymark/src/core/busymark_exception.dart';
import 'package:busymark/src/editor/source/source_commands.dart';
import 'package:busymark/src/writerside/writerside_parsers.dart';
import 'package:busymark/src/writerside/writerside_title_editor.dart';
import 'package:busymark/src/writerside/writerside_toc_editor.dart';
import 'package:busymark/src/writerside/writerside_toc_navigation.dart';
import 'package:busymark/src/writerside/writerside_topic_creator.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

void main() {
  const parser = WritersideTopicParser();
  const titleEditor = WritersideTitleEditor();
  const identity = WritersideTocNodeIdentity(
    hidden: false,
    topicFileName: 'topic.md',
    id: 'second',
  );
  const tree =
      '<instance-profile id="guide"><toc-element topic="topic.md" id="first"/><toc-element topic="topic.md" id="second"/></instance-profile>';

  test('source navigation distinguishes repeated references on one line', () {
    final span = writersideTocSourceSpan(
      filePath: '/guide.tree',
      source: tree,
      path: [1],
      identity: identity,
    )!;
    expect(
      span.startOffset,
      tree.indexOf('<toc-element', tree.indexOf('<toc-element') + 1),
    );
    expect(span.startLine, 1);
    final changed = '\n\n$tree';
    expect(
      writersideTocSourceSpan(
        filePath: '/guide.tree',
        source: changed,
        path: [1],
        identity: identity,
      )!.startOffset,
      span.startOffset + 2,
    );
    expect(
      writersideTocSourceSpan(
        filePath: '/guide.tree',
        source: tree,
        path: [0],
        identity: identity,
      ),
      isNull,
    );
  });

  test(
    'explicit synchronization follows installed breadth-first topic matching',
    () {
      const source =
          '<instance-profile id="g"><toc-element toc-title="Group"><toc-element topic="same.md"/></toc-element><toc-element topic="same.md" id="custom"/></instance-profile>';
      final instance = const WritersideTreeParser().parse('/g.tree', source);
      expect(
        writersideTocBreadthFirstPath(
          instance.tocRoots,
          (node) => node.topicReference == 'same.md',
        ),
        [1],
      );
      expect(
        writersideTocEditorSyncKey(
          '/g.tree',
          source,
          source.indexOf('id="custom"'),
        ),
        'custom',
      );
      expect(
        writersideTocEditorSyncKey(
          '/g.tree',
          source,
          source.indexOf('topic="same.md"'),
        ),
        isNull,
      );
    },
  );

  test(
    'Markdown title edits preserve other instances, content and occurrence',
    () {
      const source =
          '# Authored {id="keep"}\n\n<title instance="other">Other</title>\n\nBody **unchanged**.\n';
      final topic = parser.parseMarkdown(
        filePath: '/topics/topic.md',
        source: source,
        topicsRoot: '/topics',
      );
      final result = titleEditor.prepare(
        topic: topic,
        instanceId: 'guide',
        treePath: '/guide.tree',
        treeSource: tree,
        tocPath: [1],
        tocIdentity: identity,
        edit: const WritersideTitleEdit(
          title: 'New *title* <text>',
          instanceTitle: 'Instance & title',
          tocTitle: 'Navigation "title"',
        ),
      );
      expect(
        result.topicSource,
        contains('# New \\*title\\* \\<text\\> {id="keep"}'),
      );
      expect(
        result.topicSource,
        contains('<title instance="other">Other</title>'),
      );
      expect(result.topicSource, contains('Body **unchanged**.\n'));
      expect(
        parser
            .parseMarkdown(
              filePath: '/topics/topic.md',
              source: result.topicSource,
              topicsRoot: '/topics',
            )
            .title,
        'New *title* <text>',
      );
      expect(
        result.topicSource,
        contains('<title instance="guide">Instance &amp; title</title>'),
      );
      final elements = XmlDocument.parse(
        result.treeSource,
      ).findAllElements('toc-element').toList();
      expect(elements.first.getAttribute('toc-title'), isNull);
      expect(elements.last.getAttribute('toc-title'), 'Navigation "title"');
    },
  );

  test('Markdown title edit changes H1 and preserves front matter title', () {
    final topic = parser.parseMarkdown(
      filePath: '/topics/topic.md',
      source: '---\ntitle: Metadata\n---\n\n# Old\n',
      topicsRoot: '/topics',
    );
    final result = titleEditor.prepare(
      topic: topic,
      instanceId: 'guide',
      treePath: '/guide.tree',
      treeSource: tree,
      tocPath: [1],
      tocIdentity: identity,
      edit: const WritersideTitleEdit(title: 'New'),
    );

    expect(result.topicSource, '---\ntitle: Metadata\n---\n\n# New\n');
    expect(
      parser
          .parseMarkdown(
            filePath: '/topics/topic.md',
            source: result.topicSource,
            topicsRoot: '/topics',
          )
          .title,
      'New',
    );
  });

  test(
    'Markdown title round trip preserves ampersands and entity spellings',
    () {
      final topic = parser.parseMarkdown(
        filePath: '/topics/topic.md',
        source: '# Heading\n',
        topicsRoot: '/topics',
      );
      final result = titleEditor.prepare(
        topic: topic,
        instanceId: 'guide',
        treePath: '/guide.tree',
        treeSource: tree,
        tocPath: [1],
        tocIdentity: identity,
        edit: const WritersideTitleEdit(title: 'A & B &amp; C'),
      );
      expect(
        parser
            .parseMarkdown(
              filePath: '/topics/topic.md',
              source: result.topicSource,
              topicsRoot: '/topics',
            )
            .title,
        'A & B &amp; C',
      );
    },
  );

  test('unchanged inherited values do not add overrides', () {
    const source = '# Authored\n\nBody\n';
    final topic = parser.parseMarkdown(
      filePath: '/topics/topic.md',
      source: source,
      topicsRoot: '/topics',
    );
    final result = titleEditor.prepare(
      topic: topic,
      instanceId: 'guide',
      treePath: '/guide.tree',
      treeSource: tree,
      tocPath: [1],
      tocIdentity: identity,
      edit: const WritersideTitleEdit(),
    );
    expect(result.topicSource, source);
    expect(result.treeSource, tree);
  });

  test('XML title edits escape attributes and expand self-closing root', () {
    const source = '<?xml version="1.0"?><topic id="keep" title="Old"/>';
    final topic = parser.parseXml(
      filePath: '/topics/topic.topic',
      source: source,
      topicsRoot: '/topics',
    );
    final result = titleEditor.prepare(
      topic: topic,
      instanceId: 'guide',
      treePath: '/guide.tree',
      treeSource: tree,
      tocPath: [1],
      tocIdentity: identity,
      edit: const WritersideTitleEdit(
        title: 'New " & <title>',
        instanceTitle: 'Scoped <title>',
      ),
    );
    final root = XmlDocument.parse(result.topicSource).rootElement;
    expect(root.getAttribute('id'), 'keep');
    expect(root.getAttribute('title'), 'New " & <title>');
    expect(root.getElement('title')!.innerText, 'Scoped <title>');
  });

  test('clearing overrides removes only the selected instance and occurrence', () {
    const source =
        '<topic id="keep" title="Base"><title instance="guide">Guide</title><title instance="other">Other</title><p>Body</p></topic>';
    final topic = parser.parseXml(
      filePath: '/topics/topic.topic',
      source: source,
      topicsRoot: '/topics',
    );
    const withTitle =
        '<instance-profile id="guide"><toc-element topic="topic.md" id="second" toc-title="Navigation"/></instance-profile>';
    const selected = WritersideTocNodeIdentity(
      hidden: false,
      topicFileName: 'topic.md',
      id: 'second',
      tocTitle: 'Navigation',
    );
    final result = titleEditor.prepare(
      topic: topic,
      instanceId: 'guide',
      treePath: '/guide.tree',
      treeSource: withTitle,
      tocPath: [0],
      tocIdentity: selected,
      edit: const WritersideTitleEdit(instanceTitle: '', tocTitle: ''),
    );
    expect(
      result.topicSource,
      '<topic id="keep" title="Base"><title instance="other">Other</title><p>Body</p></topic>',
    );
    expect(
      XmlDocument.parse(
        result.treeSource,
      ).findAllElements('toc-element').single.getAttribute('toc-title'),
      isNull,
    );
  });

  test(
    'before-drop preserves complete subtrees and returns all moved paths',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'busymark-toc-actions-',
      );
      addTearDown(() => root.delete(recursive: true));
      final file = File('${root.path}/guide.tree');
      await file.writeAsString(
        '<instance-profile id="guide"><toc-element id="a"/><toc-element id="b" hidden="true"><toc-element id="nested"/></toc-element><toc-element id="c"/></instance-profile>',
      );
      final result = await const WritersideTocEditor().moveSubtrees(
        WritersideTocEditTarget(rootPath: root.path, treePath: file.path),
        const WritersideTocBatchMoveRequest(
          sources: [
            WritersideTocMoveEntry(sourcePath: [1]),
            WritersideTocMoveEntry(sourcePath: [2]),
          ],
          placement: WritersideTopicCreatePlacement.sibling,
          referencePath: [0],
          beforeReference: true,
        ),
      );
      final xml = XmlDocument.parse(await file.readAsString());
      expect(xml.rootElement.childElements.map((e) => e.getAttribute('id')), [
        'b',
        'c',
        'a',
      ]);
      expect(
        xml.rootElement.childElements.first.getAttribute('hidden'),
        'true',
      );
      expect(
        xml
            .findAllElements('toc-element')
            .where((e) => e.getAttribute('id') == 'nested'),
        hasLength(1),
      );
      expect(result.entryPaths, [
        [0],
        [1],
      ]);
    },
  );

  test(
    'grouping uses source order and rejects cross-parent selections',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'busymark-toc-actions-',
      );
      addTearDown(() => root.delete(recursive: true));
      final file = File('${root.path}/guide.tree');
      const source =
          '<instance-profile id="guide"><toc-element id="a"/><toc-element id="b"/></instance-profile>';
      await file.writeAsString(source);
      final target = WritersideTocEditTarget(
        rootPath: root.path,
        treePath: file.path,
      );
      await const WritersideTocEditor().groupElements(
        target,
        title: 'Group & name',
        entries: const [
          WritersideTocMoveEntry(
            sourcePath: [1],
            sourceIdentity: WritersideTocNodeIdentity(hidden: false, id: 'b'),
          ),
          WritersideTocMoveEntry(
            sourcePath: [0],
            sourceIdentity: WritersideTocNodeIdentity(hidden: false, id: 'a'),
          ),
        ],
      );
      final xml = XmlDocument.parse(await file.readAsString());
      final group = xml.rootElement.childElements.single;
      expect(group.getAttribute('toc-title'), 'Group & name');
      expect(group.childElements.map((e) => e.getAttribute('id')), ['a', 'b']);
      final before = await file.readAsString();
      await expectLater(
        const WritersideTocEditor().groupElements(
          target,
          title: 'Invalid',
          entries: const [
            WritersideTocMoveEntry(
              sourcePath: [0, 0],
              sourceIdentity: WritersideTocNodeIdentity(hidden: false, id: 'a'),
            ),
            WritersideTocMoveEntry(
              sourcePath: [0],
              sourceIdentity: WritersideTocNodeIdentity(
                hidden: false,
                tocTitle: 'Group & name',
              ),
            ),
          ],
        ),
        throwsA(isA<BusyMarkException>()),
      );
      expect(await file.readAsString(), before);
    },
  );

  test('line moves retain CRLF, caret, reversed selection and boundaries', () {
    const value = TextEditingValue(
      text: 'first\r\nsecond\r\nthird',
      selection: TextSelection.collapsed(offset: 9),
    );
    final moved = SourceCommands.moveLines(value, down: false);
    expect(moved.text, 'second\r\nfirst\r\nthird');
    expect(moved.selection.baseOffset, 2);
    expect(SourceCommands.moveLines(moved, down: true), value);
    const reversed = TextEditingValue(
      text: 'a\nb\nc\nd',
      selection: TextSelection(baseOffset: 6, extentOffset: 2),
    );
    final block = SourceCommands.moveLines(reversed, down: false);
    expect(block.text, 'b\nc\na\nd');
    expect(
      block.selection,
      const TextSelection(baseOffset: 4, extentOffset: 0),
    );
    const start = TextEditingValue(
      text: 'a\nb',
      selection: TextSelection.collapsed(offset: 0),
    );
    expect(
      identical(SourceCommands.moveLines(start, down: false), start),
      isTrue,
    );
    const end = TextEditingValue(
      text: 'a\nb',
      selection: TextSelection.collapsed(offset: 3),
    );
    expect(identical(SourceCommands.moveLines(end, down: true), end), isTrue);
  });
}
