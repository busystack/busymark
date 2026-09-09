import 'markdown_export_document.dart';
import 'markdown_pdf_models.dart';

class TypstPayloadBuilder {
  const TypstPayloadBuilder();

  Map<String, Object> build({
    required MarkdownExportDocument document,
    required PdfExportOptions options,
    required Map<String, String> assets,
  }) {
    options.validateOrThrow();
    return {
      'schemaVersion': 2,
      'metadata': document.metadata.toJson(),
      'options': {
        'page': options.geometry.toJson(),
        'typography': {
          'bodyFont': options.bodyFont,
          'codeFont': options.codeFont,
          'bodySizePt': options.bodyFontSize,
          'codeSizePt': options.codeFontSize,
          'headingSizesPt': [
            for (var level = 1; level <= 6; level++)
              options.headingFontSize(level),
          ],
        },
        'content': options.content.toJson(),
        'header': options.header.name,
        'footer': options.footer.name,
        'pageNumbers': options.pageNumbers.name,
        'showHeaderFooterOnFirstPage': options.showHeaderFooterOnFirstPage,
        'accentColor': options.accentColor.toLowerCase(),
      },
      'blocks': [for (final block in document.blocks) _block(block, assets)],
    };
  }

  Map<String, Object> _block(
    MarkdownExportBlock block,
    Map<String, String> assets,
  ) {
    return {
      'kind': block.kind.name,
      if (block.text.isNotEmpty) 'text': block.text,
      if (block.inlines.isNotEmpty)
        'inlines': [
          for (final inline in block.inlines) _inline(inline, assets),
        ],
      if (block.children.isNotEmpty)
        'children': [for (final child in block.children) _block(child, assets)],
      if (block.kind == MarkdownExportBlockKind.video)
        'asset': assets[block.attributes['preview']] ?? '',
      ...block.attributes,
    };
  }

  Map<String, Object> _inline(
    MarkdownExportInline inline,
    Map<String, String> assets,
  ) {
    return {
      'kind': inline.kind.name,
      if (inline.text.isNotEmpty) 'text': inline.text,
      if (inline.kind == MarkdownExportInlineKind.link &&
          inline.destination != null)
        'destination': inline.destination!,
      if (inline.kind == MarkdownExportInlineKind.image)
        'asset': assets[inline.destination] ?? '',
      if (inline.kind == MarkdownExportInlineKind.image) 'alt': inline.text,
      if (inline.children.isNotEmpty)
        'children': [
          for (final child in inline.children) _inline(child, assets),
        ],
      ...inline.attributes,
    };
  }
}
