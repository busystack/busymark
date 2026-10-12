import 'dart:io';

import 'package:busymark/src/editor/wysiwyg/writerside_editing_adapter.dart';
import 'package:busymark/src/editor/wysiwyg/writerside_inspector_target.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_document_controller.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_inline_controller.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

BusyDocument parse(String source, bool xml) => xml
    ? const WritersideEditingAdapter().parseXml(
        filePath: 't.topic',
        source: source,
      )!
    : const MarkdownParser()
          .parse(
            filePath: 't.md',
            source: source,
            mode: MarkdownMode.writersideMarkdown,
            validateLocalReferences: false,
          )
          .busyDocument;

Iterable<BusyBlock> walk(List<BusyBlock> blocks) sync* {
  for (final b in blocks) {
    yield b;
    yield* walk(b.children);
  }
}

BusyBlock paragraph(BusyDocument document) => walk(document.blocks).firstWhere(
  (b) =>
      b.kind == BusyBlockKind.paragraph &&
      busyInlineReferenceRanges(
        b.inlines,
      ).any((r) => r.kind == BusyInlineKind.writersideVariable),
);

List<BusyInlineStyleRange> variables(BusyBlock block) =>
    busyInlineReferenceRanges(
      block.inlines,
    ).where((r) => r.kind == BusyInlineKind.writersideVariable).toList();

void verify(
  String source,
  bool xml,
  List<String> names, {
  String? alt,
  bool br = false,
}) {
  final doc = parse(source, xml);
  final model = BusyMarkWysiwygDocumentController(document: doc);
  try {
    final block = paragraph(model.document);
    final refs = variables(block);
    expect(refs.map((r) => r.attributes['reference']), names);
    var position = 0;
    var sourceCursor = source.indexOf('<p>');
    for (var i = 0; i < refs.length; i++) {
      final range = refs[i];
      expect(range.start, position);
      expect(range.end, position + names[i].length);
      final at = source.indexOf('%${names[i]}%', sourceCursor);
      expect(at, greaterThanOrEqualTo(0));
      sourceCursor = at + names[i].length + 2;
      final editorTarget = WritersideInspectorTarget.fromSelection(
        bufferId: 'b',
        revision: 1,
        source: source,
        document: doc,
        blockId: block.id,
        inline: range,
      );
      expect(editorTarget.sourceLocation, at, reason: 'Editor occurrence $i');
      final sourceTarget = WritersideInspectorTarget.fromSource(
        bufferId: 'b',
        revision: 1,
        source: source,
        document: doc,
        selection: TextSelection.collapsed(offset: at + 2),
      );
      expect(sourceTarget.inline?.kind, BusyInlineKind.writersideVariable);
      expect(
        sourceTarget.inline?.start,
        range.start,
        reason: 'Source occurrence $i',
      );
      expect(sourceTarget.inline?.end, range.end);
      expect(sourceTarget.inline?.referenceIndex, range.referenceIndex);
      expect(sourceTarget.sourceLocation, at);
      position += names[i].length;
      if (i == 0) position += alt?.length ?? (br ? 1 : 0);
    }
    expect(model.markdown, source);
  } finally {
    model.dispose();
  }
}

void main() {
  for (final xml in [true, false]) {
    for (final image in [true, false]) {
      test(
        '${xml ? 'XML' : 'embedded XML'} variables after ${image ? 'image' : 'break'} bind every occurrence and mutate only the selected occurrence',
        () async {
          final body = image
              ? '<p>%product%<img src="icon.svg" alt="Product"/>%product%%product%</p>'
              : '<p>%product%<br/>%product%</p>';
          final original = xml
              ? '<topic id="t" title="Topic">$body</topic>'
              : '# Topic\n\n<chapter title="Section">$body</chapter>\n';
          final names = List.filled(image ? 3 : 2, 'product');
          verify(
            original,
            xml,
            names,
            alt: image ? 'Product' : null,
            br: !image,
          );
          var source = original;
          String change(int ordinal, String value) {
            final doc = parse(source, xml);
            final model = BusyMarkWysiwygDocumentController(document: doc);
            try {
              final block = paragraph(model.document);
              final refs = variables(block);
              var cursor = source.indexOf('<p>');
              for (var i = 0; i <= ordinal; i++) {
                cursor = source.indexOf(
                  '%${refs[i].attributes['reference']}%',
                  cursor,
                );
                if (i != ordinal) cursor += refs[i].end - refs[i].start + 2;
              }
              final target = WritersideInspectorTarget.fromSource(
                bufferId: 'b',
                revision: 1,
                source: source,
                document: doc,
                selection: TextSelection.collapsed(offset: cursor + 2),
              );
              expect(
                target.inline?.referenceIndex,
                refs[ordinal].referenceIndex,
              );
              expect(
                model.updateInlineReference(
                  block.id,
                  target.inline!,
                  'reference',
                  value,
                ),
                isTrue,
              );
              return model.markdown;
            } finally {
              model.dispose();
            }
          }

          source = change(names.length - 1, 'target_product');
          names[names.length - 1] = 'target_product';
          // In the three-variable example, both preceding references must stay
          // unchanged; source selection must never retarget the second one.
          final expectedBody = body.replaceRange(
            body.lastIndexOf('%product%'),
            body.lastIndexOf('%product%') + '%product%'.length,
            '%target_product%',
          );
          expect(
            source.substring(source.indexOf('<p>'), source.indexOf('</p>') + 4),
            expectedBody,
          );
          verify(source, xml, names, alt: image ? 'Product' : null, br: !image);
          source = change(0, 'earlier_product_long');
          names[0] = 'earlier_product_long';
          verify(source, xml, names, alt: image ? 'Product' : null, br: !image);
          if (image) {
            final model = BusyMarkWysiwygDocumentController(
              document: parse(source, xml),
            );
            try {
              final block = paragraph(model.document);
              final image = busyInlineReferenceRanges(
                block.inlines,
              ).singleWhere((r) => r.kind == BusyInlineKind.image);
              expect(
                model.updateInlineReference(
                  block.id,
                  image,
                  'alt',
                  'Longer product alternative',
                ),
                isTrue,
              );
              source = model.markdown;
            } finally {
              model.dispose();
            }
            verify(source, xml, names, alt: 'Longer product alternative');
            source = change(2, 'final_product');
            names[2] = 'final_product';
            verify(source, xml, names, alt: 'Longer product alternative');
          } else {
            source = change(1, 'final_product');
            names[1] = 'final_product';
            verify(source, xml, names, br: true);
          }
          final dir = await Directory.systemTemp.createTemp(
            'variable-bindings-',
          );
          try {
            final file = File('${dir.path}/t.${xml ? 'topic' : 'md'}');
            await file.writeAsString(source);
            verify(
              await file.readAsString(),
              xml,
              names,
              alt: image ? 'Longer product alternative' : null,
              br: !image,
            );
          } finally {
            await dir.delete(recursive: true);
          }
        },
      );
    }
  }
  test(
    'XML variable bindings use authored text nodes across entities, CDATA, wrappers and comments',
    () {
      const source =
          '<topic id="t" title="Topic"><p>&amp; <!-- %product% --><b>%product%<img src="icon.svg" alt="Product"/></b><![CDATA[%product%]]><br/>&#37;product&#37;</p></topic>';
      final doc = parse(source, true);
      final block = paragraph(doc);
      final refs = variables(block);
      expect(refs, hasLength(3));
      final offsets = [
        source.indexOf('%product%', source.indexOf('<b>')),
        source.indexOf('%product%', source.indexOf('<![CDATA[')),
        source.indexOf('&#37;product'),
      ];
      for (var i = 0; i < refs.length; i++) {
        final editor = WritersideInspectorTarget.fromSelection(
          bufferId: 'b',
          revision: 1,
          source: source,
          document: doc,
          blockId: block.id,
          inline: refs[i],
        );
        expect(editor.sourceLocation, offsets[i]);
        final target = WritersideInspectorTarget.fromSource(
          bufferId: 'b',
          revision: 1,
          source: source,
          document: doc,
          selection: TextSelection.collapsed(offset: offsets[i] + 2),
        );
        expect(target.inline?.referenceIndex, refs[i].referenceIndex);
        expect(target.sourceLocation, offsets[i]);
      }
      expect(
        WritersideInspectorTarget.fromSource(
          bufferId: 'b',
          revision: 1,
          source: source,
          document: doc,
          selection: TextSelection.collapsed(
            offset: source.indexOf('%product%') + 2,
          ),
        ).inline,
        isNull,
      );
    },
  );
}
