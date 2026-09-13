import 'package:html/parser.dart' as html;

import '../markdown/busymark_document.dart';
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
      final parsed = const RawHtmlAdapter().parseRawHtmlBlock(
        '<div>${definition.innerHtml}</div>',
        nextId,
      );
      definitions.add(
        BusyBlock(
          id: nextId(),
          kind: BusyBlockKind.unknown,
          attributes: {...origin, 'pdf-footnote-id': definition.id},
          children: parsed?.safe == true
              ? parsed!.blocks.map(withOrigin).toList()
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
