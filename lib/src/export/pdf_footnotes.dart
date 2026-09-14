import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;

import '../markdown/busymark_document.dart';
import '../markdown/math_syntax.dart';
import '../markdown/raw_html_adapter.dart';
import '../writerside/writerside_document.dart';

/// Recover the parser's structured definitions before PDF assets and links are
/// resolved. HTML keeps using the original structure on its own export path.
BusyDocument preparePdfFootnotes(BusyDocument document) {
  var occurrence = 0;
  String nextId() => 'pdf-footnote-${occurrence++}';
  BusyBlock convert(BusyBlock block) {
    final source = block.attributes['html-footnotes'];
    if (source == null) {
      return block.copyWith(children: block.children.map(convert).toList());
    }
    final origin = {
      for (final name in [
        writersideSourceModuleRootAttribute,
        writersideSourceTopicPathAttribute,
        writersideSourceOccurrenceAttribute,
      ])
        if (block.attributes[name] case final value?) name: value,
    };
    BusyInline withInlineOrigin(BusyInline inline) => inline.copyWith(
      attributes: {...origin, ...inline.attributes},
      children: inline.children.map(withInlineOrigin).toList(),
    );
    BusyBlock withOrigin(BusyBlock block) => block.copyWith(
      attributes: {...origin, ...block.attributes},
      inlines: block.inlines.map(withInlineOrigin).toList(),
      children: block.children.map(withOrigin).toList(),
    );
    final definitions = <BusyBlock>[];
    for (final definition
        in html.parseFragment(source).querySelectorAll('ol > li[id]')) {
      for (final backlink in definition.querySelectorAll('.footnote-backref')) {
        backlink.remove();
      }
      final parsed = _definitionBlocks(definition, nextId);
      definitions.add(
        BusyBlock(
          id: nextId(),
          kind: BusyBlockKind.unknown,
          attributes: {...origin, 'pdf-footnote-id': definition.id},
          children: parsed != null
              ? parsed.map(withOrigin).toList()
              : [
                  BusyBlock(
                    id: nextId(),
                    kind: BusyBlockKind.paragraph,
                    inlines: [
                      BusyInline(
                        kind: BusyInlineKind.text,
                        text: definition.text,
                      ),
                    ],
                  ),
                ],
        ),
      );
    }
    return block.copyWith(
      inlines: const [],
      children: definitions,
      attributes: {...block.attributes}..remove('html-footnotes'),
    );
  }

  return document.copyWith(blocks: document.blocks.map(convert).toList());
}

List<BusyBlock>? _definitionBlocks(
  dom.Element definition,
  String Function() nextId,
) {
  final body = definition.clone(true);
  // These nodes came from the Markdown parser's math syntax. Extract them
  // before applying the authored-HTML allowlist, then restore semantic math
  // through placeholders which cannot collide with any authored content.
  var prefix = 'busymark-footnote-math';
  final source = definition.outerHtml;
  while (source.contains(prefix)) {
    prefix += '-';
  }
  final math =
      <String, ({String expression, String sourceForm, bool display})>{};
  for (final node in body.querySelectorAll(
    '$busyMarkMathInlineTag, $busyMarkMathBlockTag',
  )) {
    // The HTML parser folds attribute names to lower case. Only recover the
    // complete signature emitted by Markdown math syntax; authored custom tags
    // still pass through the ordinary raw-HTML policy.
    final expression =
        node.attributes[busyMarkMathExpressionAttribute.toLowerCase()];
    final sourceForm =
        node.attributes[busyMarkMathSourceFormAttribute.toLowerCase()];
    final display = node.localName == busyMarkMathBlockTag;
    if (expression == null ||
        sourceForm == null ||
        !BusyMathSourceForm.values.any((form) => form.name == sourceForm) ||
        node.attributes[busyMarkMathDisplayAttribute.toLowerCase()] !=
            '$display') {
      continue;
    }
    final marker = '$prefix-${math.length}';
    math[marker] = (
      expression: expression,
      sourceForm: sourceForm,
      display: display,
    );
    node.replaceWith(dom.Element.tag(display ? 'pre' : 'code')..text = marker);
  }
  final parsed = const RawHtmlAdapter().parseRawHtmlBlock(
    '<div>${body.innerHtml}</div>',
    nextId,
  );
  if (parsed?.safe != true) return null;

  BusyInline inline(BusyInline value) {
    final item = value.kind == BusyInlineKind.code ? math[value.text] : null;
    if (item != null && !item.display) {
      return BusyInline(
        kind: BusyInlineKind.math,
        text: item.expression,
        attributes: {busyMarkMathSourceFormAttribute: item.sourceForm},
      );
    }
    return value.copyWith(children: value.children.map(inline).toList());
  }

  BusyBlock block(BusyBlock value) {
    final item = value.kind == BusyBlockKind.codeBlock
        ? math[value.plainText]
        : null;
    if (item != null && item.display) {
      return value.copyWith(
        kind: BusyBlockKind.math,
        inlines: [BusyInline(kind: BusyInlineKind.math, text: item.expression)],
        attributes: {busyMarkMathSourceFormAttribute: item.sourceForm},
      );
    }
    return value.copyWith(
      inlines: value.inlines.map(inline).toList(),
      children: value.children.map(block).toList(),
    );
  }

  return parsed!.blocks.map(block).toList();
}
