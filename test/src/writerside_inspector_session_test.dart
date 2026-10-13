import 'package:busymark/src/editor/wysiwyg/writerside_editing_adapter.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_document_controller.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_inline_controller.dart';
import 'package:busymark/src/editor/wysiwyg/writerside_inspector_target.dart';
import 'package:busymark/src/editor/wysiwyg/writerside_property_session.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/writerside/writerside_effective_properties.dart';
import 'package:busymark/src/writerside/writerside_model.dart';
import 'package:busymark/src/writerside/writerside_property_validation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final xml in [true, false]) {
    test(
      '${xml ? "XML" : "Markdown"} off-caret refresh preserves property ownership and rejects replacement',
      () {
        String source(String anchor) => xml
            ? '<topic id="t" title="Topic"><p>Caret A</p><chapter title="Chapter" id="$anchor"><p>Body</p></chapter></topic>'
            : '# Topic\n\nCaret A\n\n## Chapter {id="$anchor"}\n\nBody\n';
        BusyDocument parse(String text) => xml
            ? const WritersideEditingAdapter().parseXml(
                filePath: 't.topic',
                source: text,
              )!
            : const MarkdownParser()
                  .parse(
                    filePath: 't.md',
                    source: text,
                    mode: MarkdownMode.writersideMarkdown,
                  )
                  .busyDocument;
        final original = source('original');
        final doc = parse(original);
        final b = xml
            ? doc.blocks.first.children.last
            : doc.blocks.firstWhere((b) => b.plainText == 'Chapter');
        final target = WritersideInspectorTarget.fromSelection(
          bufferId: 'b',
          revision: 1,
          source: original,
          document: doc,
          blockId: b.id,
        );
        final changed = source('changed');
        final refreshed = target.refreshUnchangedElement(
          revision: 2,
          source: changed,
          document: parse(changed),
        )!;
        expect(refreshed.block?.attributes['id'], 'changed');
        expect(refreshed.matches('b', 2, changed), isTrue);
        expect(target.matches('b', 2, changed), isFalse);
        expect(target.sameElement(refreshed), isFalse);
        final restored = refreshed.refreshUnchangedElement(
          revision: 3,
          source: original,
          document: parse(original),
        )!;
        expect(restored.block?.attributes['id'], 'original');
        final removed = xml
            ? '<topic id="t" title="Topic"><p>Caret A</p></topic>'
            : '# Topic\n\nCaret A\n';
        final replaced = xml
            ? changed.replaceFirst('Body', 'Different body')
            : changed.replaceFirst('## Chapter', '## Other Chapter');
        for (final text in [removed, replaced]) {
          expect(
            target.refreshUnchangedElement(
              revision: 2,
              source: text,
              document: parse(text),
            ),
            isNull,
          );
        }
        expect(
          target.refreshUnchangedElement(
            revision: 2,
            source: changed,
            document: doc,
          ),
          isNull,
        );
        if (xml) {
          final title = original.replaceFirst(
            'title="Chapter"',
            'title="Renamed"',
          );
          expect(
            target
                .refreshUnchangedElement(
                  revision: 2,
                  source: title,
                  document: parse(title),
                )!
                .block
                ?.plainText,
            'Renamed',
          );
        }
      },
    );
  }
  for (final xml in [true, false]) {
    test(
      '${xml ? "XML" : "Markdown"} Show in Source locates the inspected inline markup',
      () {
        final source = xml
            ? '<topic id="t" title="Topic"><p>Before <a href="one.topic">Read <b>guide</b></a> and <a href="two.topic">Guide</a>.</p><code-block src="sample.dart"/></topic>'
            : 'Before [Read **guide**][ref] and [Guide][ref].\n\n[ref]: target.md\n';
        final doc = xml
            ? const WritersideEditingAdapter().parseXml(
                filePath: 'a.topic',
                source: source,
              )!
            : const MarkdownParser()
                  .parse(
                    filePath: 'a.md',
                    source: source,
                    mode: MarkdownMode.writersideMarkdown,
                  )
                  .busyDocument;
        final offsets = xml
            ? [
                source.indexOf('<a href'),
                source.indexOf('<a href', source.indexOf('<a href') + 1),
              ]
            : [source.indexOf('[Read'), source.indexOf('[Guide]')];
        for (final offset in offsets) {
          final target = WritersideInspectorTarget.fromSource(
            bufferId: 'b',
            revision: 1,
            source: source,
            document: doc,
            selection: TextSelection.collapsed(offset: offset + 2),
          );
          expect(target.inline?.kind, BusyInlineKind.link);
          expect(target.sourceLocation, offset);
        }
        if (xml) {
          final code = WritersideInspectorTarget.fromSource(
            bufferId: 'b',
            revision: 1,
            source: source,
            document: doc,
            selection: TextSelection.collapsed(
              offset: source.indexOf('<code-block') + 2,
            ),
          );
          expect(code.sourceLocation, source.indexOf('<code-block'));
        }
      },
    );
  }
  for (final xml in [true, false]) {
    for (final shortcut in [false, true]) {
      test(
        '${xml ? "XML" : "Markdown"} repeated ${shortcut ? "shortcuts" : "variables"} have distinct source occurrences after an earlier edit',
        () {
          final token = shortcut
              ? '<shortcut key="\$Copy">Copy</shortcut>'
              : '%product%';
          final original = xml
              ? '<topic id="t" title="Topic"><p>Before $token and $token.</p></topic>'
              : '# Topic\n\nBefore $token and $token.\n';
          BusyDocument parse(String source) => xml
              ? const WritersideEditingAdapter().parseXml(
                  filePath: 't.topic',
                  source: source,
                )!
              : const MarkdownParser()
                    .parse(
                      filePath: 't.md',
                      source: source,
                      mode: MarkdownMode.writersideMarkdown,
                    )
                    .busyDocument;
          final model = BusyMarkWysiwygDocumentController(
            document: parse(original),
          );
          addTearDown(model.dispose);
          final kind = shortcut
              ? BusyInlineKind.writersideShortcut
              : BusyInlineKind.writersideVariable;
          void verify(String source) {
            final doc = parse(source);
            final editor = BusyMarkWysiwygDocumentController(document: doc);
            try {
              Iterable<BusyBlock> walk(List<BusyBlock> blocks) sync* {
                for (final b in blocks) {
                  yield b;
                  yield* walk(b.children);
                }
              }

              final block = walk(editor.document.blocks).firstWhere(
                (b) => busyInlineReferenceRanges(
                  b.inlines,
                ).any((r) => r.kind == kind),
              );
              final refs = busyInlineReferenceRanges(
                block.inlines,
              ).where((r) => r.kind == kind).toList();
              expect(refs, hasLength(2));
              var cursor = 0;
              for (final range in refs) {
                final fragment = shortcut
                    ? '<shortcut'
                    : '%${range.attributes['reference']}%';
                final offset = source.indexOf(fragment, cursor);
                expect(offset, greaterThanOrEqualTo(0));
                cursor = offset + fragment.length;
                final fromEditor = WritersideInspectorTarget.fromSelection(
                  bufferId: 'b',
                  revision: 1,
                  source: source,
                  document: doc,
                  blockId: block.id,
                  inline: range,
                );
                expect(fromEditor.sourceLocation, offset);
                final fromSource = WritersideInspectorTarget.fromSource(
                  bufferId: 'b',
                  revision: 1,
                  source: source,
                  document: doc,
                  selection: TextSelection.collapsed(offset: offset + 2),
                );
                expect(fromSource.inline?.kind, kind);
                expect(fromSource.inline?.start, range.start);
                expect(fromSource.inline?.end, range.end);
                expect(fromSource.sourceLocation, offset);
              }
            } finally {
              editor.dispose();
            }
          }

          verify(original);
          final block = xml
              ? model.document.blocks.first.children.single
              : model.document.blocks.firstWhere(
                  (b) => b.plainText.startsWith('Before'),
                );
          final first = busyInlineReferenceRanges(block.inlines).first;
          expect(
            model.updateInlineReference(
              block.id,
              first,
              shortcut ? 'key' : 'reference',
              shortcut ? '\$VeryLongActionIdentifier' : 'long_product_name',
            ),
            isTrue,
          );
          final changed = model.markdown;
          expect(changed, contains(token));
          expect(changed, isNot(original));
          verify(changed);
        },
      );
    }
  }
  test(
    'Markdown variable mappings exclude code and escaped literals and preserve formatting',
    () {
      const source =
          '# Topic\n\nCode `%product%` escaped %\\product% and %product% then **%product%**.\n';
      final doc = const MarkdownParser()
          .parse(
            filePath: 't.md',
            source: source,
            mode: MarkdownMode.writersideMarkdown,
          )
          .busyDocument;
      final model = BusyMarkWysiwygDocumentController(document: doc);
      addTearDown(model.dispose);
      final block = model.document.blocks.firstWhere(
        (b) => b.plainText.startsWith('Code'),
      );
      final refs = busyInlineReferenceRanges(block.inlines);
      expect(refs, hasLength(2));
      final firstOffset = source.indexOf('%product%', source.indexOf(' and '));
      final secondOffset = source.indexOf('%product%', firstOffset + 1);
      for (final pair in [(refs[0], firstOffset), (refs[1], secondOffset)]) {
        final target = WritersideInspectorTarget.fromSource(
          bufferId: 'b',
          revision: 1,
          source: source,
          document: doc,
          selection: TextSelection.collapsed(offset: pair.$2 + 2),
        );
        expect(target.inline?.start, pair.$1.start);
        expect(target.sourceLocation, pair.$2);
      }
      final literal = WritersideInspectorTarget.fromSource(
        bufferId: 'b',
        revision: 1,
        source: source,
        document: doc,
        selection: TextSelection.collapsed(
          offset: source.indexOf('%product%') + 2,
        ),
      );
      expect(literal.inline, isNull);
      expect(model.markdown, source);
    },
  );
  test(
    'Markdown XML-island bindings retain repeated occurrences and mutation identities',
    () {
      const source =
          '# Topic\n\n<chapter title="Section"><p>Vars %product% and %product%, <shortcut key="\$Save">Save</shortcut> and <shortcut key="\$Save">Save</shortcut>. <a href="old.topic">Read <b>guide</b></a></p></chapter>\n';
      final doc = const MarkdownParser()
          .parse(
            filePath: 't.md',
            source: source,
            mode: MarkdownMode.writersideMarkdown,
          )
          .busyDocument;
      final model = BusyMarkWysiwygDocumentController(document: doc);
      addTearDown(model.dispose);
      for (final token in ['%product%', '<shortcut', '<a href']) {
        final offsets = <int>[];
        for (
          var at = source.indexOf(token);
          at >= 0;
          at = source.indexOf(token, at + token.length)
        ) {
          offsets.add(at);
        }
        for (final offset in offsets) {
          final target = WritersideInspectorTarget.fromSource(
            bufferId: 'b',
            revision: 1,
            source: source,
            document: doc,
            selection: TextSelection.collapsed(offset: offset + 2),
          );
          expect(
            target.inline,
            isNotNull,
            reason: 'token=$token offset=$offset',
          );
          expect(target.sourceLocation, offset);
          if (token == '<a href') {
            expect(
              model.updateInlineReference(
                target.block!.id,
                target.inline!,
                'href',
                'new.topic',
              ),
              isTrue,
            );
          }
        }
      }
      expect(model.markdown, contains('Read <b>guide</b>'));
      expect(model.markdown, contains('href="new.topic"'));
    },
  );
  for (final xml in [true, false]) {
    test(
      '${xml ? "XML" : "Markdown"} adjacent empty shortcuts retain distinct owning identities',
      () {
        final source = xml
            ? '<topic id="t" title="Topic"><p>Keys <shortcut key="\$Save"/><shortcut key="\$Save"/>.</p></topic>'
            : '# Topic\n\nKeys <shortcut key="\$Save"/><shortcut key="\$Save"/>.\n';
        BusyDocument parse(String text) => xml
            ? const WritersideEditingAdapter().parseXml(
                filePath: 't.topic',
                source: text,
              )!
            : const MarkdownParser()
                  .parse(
                    filePath: 't.md',
                    source: text,
                    mode: MarkdownMode.writersideMarkdown,
                  )
                  .busyDocument;
        final model = BusyMarkWysiwygDocumentController(
          document: parse(source),
        );
        addTearDown(model.dispose);
        final first = source.indexOf('<shortcut');
        final second = source.indexOf('<shortcut', first + 1);
        final target = WritersideInspectorTarget.fromSource(
          bufferId: 'b',
          revision: 1,
          source: source,
          document: parse(source),
          selection: TextSelection.collapsed(offset: second + 2),
        );
        expect(target.sourceLocation, second);
        expect(target.inline?.referenceIndex, 1);
        expect(
          model.updateInlineReference(
            target.block!.id,
            target.inline!,
            'key',
            '\$Copy',
          ),
          isTrue,
        );
        final changed = model.markdown;
        expect(changed, contains('<shortcut key="\$Save"'));
        expect(
          changed.indexOf('key="\$Copy"'),
          greaterThan(changed.indexOf('key="\$Save"')),
        );
        final reopened = WritersideInspectorTarget.fromSource(
          bufferId: 'b',
          revision: 2,
          source: changed,
          document: parse(changed),
          selection: TextSelection.collapsed(
            offset: changed.indexOf('key="\$Copy"'),
          ),
        );
        expect(
          reopened.sourceLocation,
          changed.indexOf('<shortcut', changed.indexOf('<shortcut') + 1),
        );
        expect(reopened.inline?.referenceIndex, 1);
      },
    );
  }
  test(
    'authored-state comparison distinguishes no-ops and serialization loss',
    () {
      const source =
          '<topic id="t" title="Topic"><show-structure/><p>Body</p></topic>';
      final doc = const WritersideEditingAdapter().parseXml(
        filePath: 't.topic',
        source: source,
      )!;
      final target = WritersideInspectorTarget.fromTopic(
        bufferId: 'b',
        revision: 1,
        source: source,
        document: doc,
      );
      final c = BusyMarkWysiwygDocumentController(document: doc);
      addTearDown(c.dispose);
      expect(
        c.resetTopicNavigation() && c.updateTopicNavigation('for', ''),
        isTrue,
      );
      expect(target.hasSameAuthoredState(c.document), isTrue);
      expect(c.updateTopicNavigation('for', 'none'), isTrue);
      expect(target.hasSameAuthoredState(c.document), isFalse);
      final paragraph = c.document.blocks.first.children.firstWhere(
        (b) => b.kind == BusyBlockKind.paragraph,
      );
      expect(c.updateWritersideProperty(paragraph.id, 'id', 'body'), isTrue);
      expect(target.hasSameAuthoredState(c.document), isFalse);
    },
  );
  test(
    'semantic target address survives XML whitespace after native item conversion',
    () {
      const source = '# Topic\n\n- One\n- Two\n';
      final doc = const MarkdownParser()
          .parse(
            filePath: 't.md',
            source: source,
            mode: MarkdownMode.writersideMarkdown,
          )
          .busyDocument;
      final c = BusyMarkWysiwygDocumentController(document: doc);
      addTearDown(c.dispose);
      final item = c.document.blocks
          .singleWhere((b) => b.attributes['element'] == 'list')
          .children
          .singleWhere((b) => b.plainText == 'Two');
      expect(c.updateWritersideProperty(item.id, 'id', 'two'), isTrue);
      final before = WritersideInspectorTarget.fromSelection(
        bufferId: 'b',
        revision: 1,
        source: source,
        document: c.document,
        blockId: item.id,
      );
      final saved = c.markdown;
      final reopened = const MarkdownParser()
          .parse(
            filePath: 't.md',
            source: saved,
            mode: MarkdownMode.writersideMarkdown,
          )
          .busyDocument;
      final list = reopened.blocks.firstWhere(
        (b) => b.attributes['element'] == 'list',
      );
      final second = list.children.firstWhere(
        (b) => b.attributes['id'] == 'two',
      );
      final after = WritersideInspectorTarget.fromSelection(
        bufferId: 'b',
        revision: 2,
        source: saved,
        document: reopened,
        blockId: second.id,
      );
      expect(before.semanticAddress, after.semanticAddress);
      expect(before.address, isNot(after.address));
    },
  );
  test(
    'unchanged buffer generation does not authorize another inspected element',
    () {
      const source = '<topic id="t" title="Topic"><p>A</p><p>B</p></topic>';
      final doc = const WritersideEditingAdapter().parseXml(
        filePath: 't.topic',
        source: source,
      )!;
      WritersideInspectorTarget target(int index) =>
          WritersideInspectorTarget.fromSelection(
            bufferId: 'b',
            revision: 1,
            source: source,
            document: doc,
            blockId: doc.blocks.first.children[index].id,
          );
      final delayed = target(0);
      expect(delayed.matches('b', 1, source), isTrue);
      expect(target(1).matches('b', 1, source), isTrue);
      expect(delayed.sameElement(target(1)), isFalse);
      expect(delayed.sameElement(target(0)), isTrue);
      expect(delayed.sameElement(null), isFalse);
    },
  );
  test(
    'Source identifies an inline image override through its attribute range',
    () {
      const source =
          'Before ![Logo][logo]{src="other.png" alt="Different" width="80"} after.\n\n[logo]: logo.png\n';
      final doc = const MarkdownParser()
          .parse(
            filePath: 'a.md',
            source: source,
            mode: MarkdownMode.writersideMarkdown,
          )
          .busyDocument;
      final target = WritersideInspectorTarget.fromSource(
        bufferId: 'b',
        revision: 1,
        source: source,
        document: doc,
        selection: TextSelection.collapsed(offset: source.indexOf('width') + 2),
      );
      expect(target.inline?.kind, BusyInlineKind.image);
      expect(target.inline?.destination, 'other.png');
      expect(target.inline?.attributes['alt'], 'Different');
    },
  );
  test(
    'a stale model cannot be rebound by supplying a newer source generation',
    () {
      const old = '<topic id="t" title="Topic"><p>A</p></topic>';
      final document = const WritersideEditingAdapter().parseXml(
        filePath: 't.topic',
        source: old,
      )!;
      final newer = old.replaceFirst('>A</p>', '>B</p>');
      final target = WritersideInspectorTarget.fromSelection(
        bufferId: 'b',
        revision: 2,
        source: newer,
        document: document,
        blockId: document.blocks.first.children.first.id,
      );
      expect(target.matches('b', 2, newer), isFalse);
    },
  );

  test(
    'Source reference-style image and link targets use existing occurrence mappings',
    () {
      const source =
          'Before ![Logo][asset] and [guide][ref].\n\n[asset]: logo.png\n[ref]: guide.md\n';
      final doc = const MarkdownParser()
          .parse(
            filePath: 't.md',
            source: source,
            mode: MarkdownMode.writersideMarkdown,
          )
          .busyDocument;
      final image = WritersideInspectorTarget.fromSource(
        bufferId: 'b',
        revision: 1,
        source: source,
        document: doc,
        selection: TextSelection.collapsed(offset: source.indexOf('Logo')),
      );
      expect(image.inline?.kind, BusyInlineKind.image);
      expect(image.inline?.destination, 'logo.png');
      final link = WritersideInspectorTarget.fromSource(
        bufferId: 'b',
        revision: 1,
        source: source,
        document: doc,
        selection: TextSelection.collapsed(
          offset: source.indexOf('[guide]') + 2,
        ),
      );
      expect(link.inline?.kind, BusyInlineKind.link);
      expect(link.inline?.destination, 'guide.md');
    },
  );
  test('Topic without an H1 remains a document-bound logical entry', () {
    const source = '---\nswitcher-label: OS\n---\n\nText.\n';
    final doc = const MarkdownParser()
        .parse(
          filePath: 't.md',
          source: source,
          mode: MarkdownMode.writersideMarkdown,
        )
        .busyDocument;
    final target = WritersideInspectorTarget.fromTopic(
      bufferId: 'b',
      revision: 1,
      source: source,
      document: doc,
    );
    expect(target.topic, isTrue);
    expect(target.block, isNull);
    expect(target.matches('b', 1, source), isTrue);
    expect(target.document.frontMatter['switcher-label'], 'OS');
  });

  test(
    'smart variable defaults are contextual and explicit false resets them',
    () {
      const smart = WritersideEffectiveProperties(
        settings: WritersideSettingsConfig(smartIgnoreVars: true),
      );
      expect(smart.resolve('code-block', 'ignore-vars', {}).value, 'true');
      expect(
        smart.resolve('img', 'ignore-vars', {'src': 'local.png'}).value,
        'false',
      );
      expect(
        smart.resolve('img', 'ignore-vars', {
          'src': 'https://example.test/%name%.png',
        }).value,
        'true',
      );
      expect(
        smart.resolve('a', 'ignore-vars', {'href': 'other.topic'}).value,
        'false',
      );
      expect(
        smart.resolve('a', 'ignore-vars', {
          'href': 'https://example.test/%path%',
          'ignore-vars': 'false',
        }).value,
        'false',
      );
      const ancestor = WritersideEffectiveProperties(
        inheritedIgnoreVars: 'true',
      );
      expect(
        ancestor.resolve('p', 'ignore-vars', {}).origin,
        WritersidePropertyOrigin.ancestor,
      );
      expect(
        ancestor.resolve('p', 'ignore-vars', {'ignore-vars': 'false'}).value,
        'false',
      );
    },
  );

  test(
    'draft retains captured mutation when field is rebuilt or target changes',
    () {
      final session = WritersidePropertySession();
      var a = '';
      var b = '';
      final draft = session.bind('A-id', 'old', (v) {
        a = v;
        return true;
      });
      session.edit(draft, 'new');
      session.bind('A-id', 'replacement', (v) {
        b = v;
        return true;
      });
      expect(session.transition(), isTrue);
      expect(a, 'new');
      expect(b, isEmpty);
    },
  );
  for (final reason in WritersidePropertyRejection.values) {
    test(
      '$reason blocks transition and preserves draft until explicit reversion',
      () {
        final session = WritersidePropertySession();
        final draft = session.bind(
          'generation-1',
          'old',
          (v) => session.reject(reason),
        );
        session.edit(draft, 'pending');
        expect(session.transition(), isFalse);
        expect(draft.text, 'pending');
        expect(draft.error, reason);
        session.revert(draft);
        expect(draft.text, 'old');
        expect(session.transition(), isTrue);
      },
    );
  }
  test('valid no-op does not call mutation or report invalid input', () {
    final session = WritersidePropertySession();
    final draft = session.bind(
      'A',
      'same',
      (_) => throw StateError('no mutation'),
    );
    expect(session.commit(draft), isTrue);
    expect(draft.error, isNull);
  });
  test('inspected B has B ancestry independently of caret in A', () {
    const source =
        '<topic id="t" title="Topic"><chapter title="A"><p>A</p></chapter><chapter title="B"><procedure title="Procedure"><step>B</step></procedure></chapter></topic>';
    final doc = const WritersideEditingAdapter().parseXml(
      filePath: 't.topic',
      source: source,
    )!;
    final b = doc.blocks.single.children.last;
    final target = WritersideInspectorTarget.fromSelection(
      bufferId: 'buffer',
      revision: 1,
      source: source,
      document: doc,
      blockId: b.children.single.children.single.id,
    );
    expect(target.path.map((b) => b.attributes['element']), [
      'topic',
      'chapter',
      'procedure',
      'step',
    ]);
    expect(target.path[1].plainText, 'B');
    expect(target.address, [0, 1, 0, 0]);
    expect(target.matches('buffer', 2, source), isFalse);
    expect(target.matches('other', 1, source), isFalse);
    expect(target.matches('buffer', 1, source.replaceFirst('B', 'C')), isFalse);
  });
  test(
    'Markdown chapter ancestry is structural while address locates flat authored blocks',
    () {
      const source = '# Topic\n\n## Parent\n\n### Child\n\nText\n\n## Next\n';
      final doc = const MarkdownParser()
          .parse(
            filePath: 't.md',
            source: source,
            mode: MarkdownMode.writersideMarkdown,
          )
          .busyDocument;
      final text = doc.blocks.firstWhere((b) => b.plainText == 'Text');
      final target = WritersideInspectorTarget.fromSelection(
        bufferId: 'b',
        revision: 0,
        source: source,
        document: doc,
        blockId: text.id,
      );
      expect(target.path.map((b) => b.plainText), [
        'Topic',
        'Parent',
        'Child',
        'Text',
      ]);
      expect(target.address, [doc.blocks.indexOf(text)]);
    },
  );
  test(
    'Source boundaries are half-open and multi-element selections are explicit',
    () {
      const source = '<topic id="t" title="Topic"><p>A</p><p>B</p></topic>';
      final doc = const WritersideEditingAdapter().parseXml(
        filePath: 't.topic',
        source: source,
      )!;
      WritersideInspectorTarget locate(TextSelection s) =>
          WritersideInspectorTarget.fromSource(
            bufferId: 'b',
            revision: 0,
            source: source,
            document: doc,
            selection: s,
          );
      final start = source.indexOf('<p>B');
      expect(
        locate(TextSelection.collapsed(offset: start)).block!.plainText,
        'B',
      );
      expect(
        locate(
          TextSelection(
            baseOffset: source.indexOf('<p>A'),
            extentOffset: start + 5,
          ),
        ).multiple,
        isTrue,
      );
    },
  );
  for (final tag in ['chapter', 'procedure', 'code-block', 'deflist']) {
    test('$tag state-only and explicit false follow pinned builder', () {
      const resolver = WritersideEffectiveProperties();
      expect(
        resolver.resolve(tag, 'collapsible', {
          'default-state': 'expanded',
        }).value,
        'false',
      );
      expect(
        resolver.resolve(tag, 'collapsible', {
          'collapsible': 'false',
          'default-state': 'collapsed',
        }).value,
        'false',
      );
      expect(
        resolver.resolve(tag, 'default-state', {'collapsible': 'true'}).value,
        'collapsed',
      );
    });
  }
  test(
    'absent item state and literal inherited have distinct module-default behavior',
    () {
      const resolver = WritersideEffectiveProperties(
        settings: WritersideSettingsConfig(
          defaultProperties: [
            WritersideDefaultProperty(
              elementName: 'def',
              propertyName: 'default-state',
              value: 'collapsed',
            ),
          ],
        ),
      );
      const list = {'collapsible': 'true', 'default-state': 'expanded'};
      final absent = resolver.resolve(
        'def',
        'default-state',
        {},
        definitionList: list,
      );
      final inherited = resolver.resolve('def', 'default-state', {
        'default-state': 'inherited',
      }, definitionList: list);
      expect(absent.value, 'collapsed');
      expect(absent.origin, WritersidePropertyOrigin.module);
      expect(inherited.value, 'expanded');
      expect(inherited.authored, 'inherited');
      expect(inherited.origin, WritersidePropertyOrigin.ancestor);
      expect(
        resolver.resolve('def', 'collapsible', {
          'collapsible': 'false',
        }, definitionList: list).value,
        'true',
      );
    },
  );
  test(
    'module defaults and reset preserve authored absence and unresolved expressions',
    () {
      const resolver = WritersideEffectiveProperties(
        settings: WritersideSettingsConfig(
          defaultProperties: [
            WritersideDefaultProperty(
              elementName: 'code-block',
              propertyName: 'collapsible',
              value: 'true',
            ),
          ],
        ),
      );
      final attrs = <String, String>{};
      expect(
        resolver.resolve('code-block', 'collapsible', attrs).value,
        'true',
      );
      expect(attrs, isEmpty);
      final variable = resolver.resolve('code-block', 'collapsible', {
        'collapsible': '%unknown%',
      });
      expect(variable.authored, '%unknown%');
      expect(variable.unresolved, isTrue);
      expect(variable.origin, WritersidePropertyOrigin.unresolved);
      expect(
        const WritersideEffectiveProperties(variables: {'collapse': 'false'})
            .resolve('chapter', 'collapsible', {'collapsible': '%collapse%'})
            .value,
        'false',
      );
    },
  );
  test(
    'emphasis validates against displayed extraction and extraction tuples conflict',
    () {
      expect(
        validateWritersideProperty(
          'code-block',
          'emphasize-lines',
          '2',
          attributes: {'include-lines': '2-3'},
          codeSource: 'one\ntwo\nthree',
        ),
        isNull,
      );
      expect(
        validateWritersideProperty(
          'code-block',
          'emphasize-lines',
          '3',
          attributes: {'include-lines': '2-3'},
          codeSource: 'one\ntwo\nthree',
        ),
        contains('invalid-lines'),
      );
      expect(
        validateWritersideProperty(
          'code-block',
          'include-lines',
          '1',
          attributes: {'include-symbol': 'main'},
        ),
        contains('conflicts'),
      );
      expect(
        validateWritersideProperty('chapter', 'default-state', null),
        isNull,
      );
      expect(
        validateWritersideProperty('def', 'default-state', 'inherited'),
        isNull,
      );
      expect(
        validateWritersideProperty('chapter', 'default-state', 'inherited'),
        contains('allowed'),
      );
    },
  );
}
