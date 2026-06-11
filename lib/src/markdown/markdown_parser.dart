import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/diagnostic.dart';
import '../core/local_image_resolver.dart';
import '../core/path_utils.dart';
import '../core/source_span.dart';
import 'busymark_document.dart';
import 'markdown_ast_adapter.dart';
import 'markdown_model.dart';

class MarkdownParser {
  const MarkdownParser();

  ParsedMarkdownDocument parse({
    required String filePath,
    required String source,
    MarkdownMode mode = MarkdownMode.commonMark,
    String? workspaceRoot,
    bool validateLocalReferences = true,
  }) {
    final diagnostics = <Diagnostic>[];
    final headings = <MarkdownHeading>[];
    final links = <MarkdownLink>[];
    final images = <MarkdownImage>[];
    final codeBlocks = <MarkdownCodeBlock>[];
    final xmlBlocks = <MarkdownXmlBlock>[];
    final variables = <MarkdownVariableToken>[];
    final ids = <String, SourceSpan>{};
    final generatedIds = <String, int>{};
    final mapper = SourceLocationMapper(source);
    var title = _frontMatterTitle(filePath, source, diagnostics);
    var inFence = false;
    var fenceStart = 0;
    String? fenceLanguage;
    final fenceContent = StringBuffer();
    var offset = 0;
    final lines = source.split(RegExp('(?<=\n)'));

    for (final rawLine in lines) {
      final line = rawLine.endsWith('\n')
          ? rawLine.substring(0, rawLine.length - 1)
          : rawLine;
      final trimmed = line.trimRight();
      final fence = RegExp(
        r'^\s*(```|~~~)\s*([A-Za-z0-9_+\-#.]*)',
      ).firstMatch(line);
      if (fence != null) {
        if (!inFence) {
          inFence = true;
          fenceStart = offset;
          fenceLanguage = fence.group(2)?.trim();
          if (fenceLanguage != null && fenceLanguage.isEmpty) {
            fenceLanguage = null;
          }
        } else {
          inFence = false;
          codeBlocks.add(
            MarkdownCodeBlock(
              language: fenceLanguage,
              content: fenceContent.toString(),
              span: SourceSpan.fromOffsets(
                filePath: filePath,
                source: source,
                startOffset: fenceStart,
                endOffset: offset + rawLine.length,
              ),
            ),
          );
          fenceContent.clear();
          fenceLanguage = null;
        }
        offset += rawLine.length;
        continue;
      }
      if (inFence) {
        fenceContent.write(rawLine);
        offset += rawLine.length;
        continue;
      }

      final heading = RegExp(
        r'^(#{1,6})\s+(.+?)\s*(\{[^}]+\})?\s*$',
      ).firstMatch(trimmed);
      if (heading != null) {
        final level = heading.group(1)!.length;
        final rawText = heading.group(2)!.trim();
        final attrText = heading.group(3);
        final explicitId = attrText == null
            ? null
            : _attributeValue(attrText, 'id');
        if (attrText != null &&
            explicitId == null &&
            mode == MarkdownMode.writersideMarkdown) {
          diagnostics.add(
            Diagnostic(
              code: 'markdown.attribute.malformed',
              severity: DiagnosticSeverity.warning,
              message: 'Malformed Writerside heading attribute block.',
              filePath: filePath,
              sourceSpan: SourceSpan.fromOffsets(
                filePath: filePath,
                source: source,
                startOffset: offset + line.indexOf(attrText),
                endOffset: offset + line.indexOf(attrText) + attrText.length,
              ),
            ),
          );
        }
        final baseId = explicitId ?? slugForHeading(rawText);
        final generated = explicitId == null;
        final id = generated ? _deduplicatedId(baseId, generatedIds) : baseId;
        final span = SourceSpan.fromOffsets(
          filePath: filePath,
          source: source,
          startOffset: offset,
          endOffset: offset + line.length,
        );
        headings.add(
          MarkdownHeading(
            level: level,
            text: rawText,
            id: id,
            generatedId: generated,
            span: span,
          ),
        );
        title ??= level == 1 ? rawText : null;
        if (ids.containsKey(id)) {
          diagnostics.add(
            Diagnostic(
              code: 'markdown.heading.duplicate-id',
              severity: DiagnosticSeverity.warning,
              message: 'Duplicate heading ID "$id".',
              filePath: filePath,
              sourceSpan: span,
              relatedSpans: [ids[id]!],
            ),
          );
        } else {
          ids[id] = span;
        }
        if (mode == MarkdownMode.writersideMarkdown &&
            level == 1 &&
            headings.where((item) => item.level == 1).length > 1) {
          diagnostics.add(
            Diagnostic(
              code: 'writerside.topic.h1-converted-to-chapter',
              severity: DiagnosticSeverity.warning,
              message:
                  'Additional top-level H1 headings are treated as chapters.',
              filePath: filePath,
              sourceSpan: span,
            ),
          );
        }
      }

      _extractInlineItems(
        filePath: filePath,
        source: source,
        line: line,
        lineOffset: offset,
        links: links,
        images: images,
        variables: variables,
      );
      _extractXmlBlocks(
        filePath: filePath,
        source: source,
        line: line,
        lineOffset: offset,
        xmlBlocks: xmlBlocks,
      );
      _extractUnsafeHtml(
        filePath: filePath,
        source: source,
        line: line,
        lineOffset: offset,
        diagnostics: diagnostics,
      );

      offset += rawLine.length;
    }

    if (mode == MarkdownMode.writersideMarkdown && title == null) {
      diagnostics.add(
        Diagnostic(
          code: 'writerside.topic.missing-title',
          severity: DiagnosticSeverity.warning,
          message: 'Writerside Markdown topic has no H1 or front matter title.',
          filePath: filePath,
          sourceSpan: SourceSpan.fromOffsets(
            filePath: filePath,
            source: source,
            startOffset: 0,
            endOffset: source.isEmpty ? 0 : source.length.clamp(0, 1),
          ),
        ),
      );
    }

    if (validateLocalReferences) {
      diagnostics.addAll(
        _validateLocalReferences(
          filePath: filePath,
          source: source,
          workspaceRoot: workspaceRoot,
          headings: headings,
          links: links,
          images: images,
          mapper: mapper,
        ),
      );
    }

    final busyDocument = _withScannedMetadata(
      const MarkdownAstAdapter().parse(
        filePath: filePath,
        source: source,
        mode: mode,
        title: title,
      ),
      headings,
      sortDiagnostics(diagnostics),
    );

    return ParsedMarkdownDocument(
      filePath: filePath,
      source: source,
      mode: mode,
      title: title,
      headings: headings,
      links: links,
      images: images,
      codeBlocks: codeBlocks,
      xmlBlocks: xmlBlocks,
      variables: variables,
      diagnostics: sortDiagnostics(diagnostics),
      busyDocument: busyDocument,
    );
  }

  BusyDocument _withScannedMetadata(
    BusyDocument document,
    List<MarkdownHeading> headings,
    List<Diagnostic> diagnostics,
  ) {
    var headingIndex = 0;
    return document.copyWith(
      diagnostics: diagnostics,
      blocks: [
        for (final block in document.blocks)
          if (block.kind == BusyBlockKind.heading &&
              headingIndex < headings.length)
            _headingWithScannedMetadata(block, headings[headingIndex++])
          else
            block,
      ],
    );
  }

  BusyBlock _headingWithScannedMetadata(
    BusyBlock block,
    MarkdownHeading heading,
  ) {
    return block.copyWith(
      id: heading.id,
      attributes: {
        ...block.attributes,
        'id': heading.id,
        'level': '${heading.level}',
        'generatedId': '${heading.generatedId}',
      },
      sourceSpan: heading.span,
    );
  }

  String? _frontMatterTitle(
    String filePath,
    String source,
    List<Diagnostic> diagnostics,
  ) {
    if (!source.startsWith('---')) {
      return null;
    }
    final end = source.indexOf('\n---', 3);
    if (end == -1) {
      diagnostics.add(
        Diagnostic(
          code: 'markdown.front-matter.malformed',
          severity: DiagnosticSeverity.warning,
          message: 'Front matter is not closed.',
          filePath: filePath,
          sourceSpan: SourceSpan.fromOffsets(
            filePath: filePath,
            source: source,
            startOffset: 0,
            endOffset: source.length,
          ),
        ),
      );
      return null;
    }
    final block = source.substring(3, end);
    for (final line in block.split('\n')) {
      final match = RegExp(r'^\s*title\s*:\s*(.+?)\s*$').firstMatch(line);
      if (match != null) {
        return match.group(1)!.replaceAll(RegExp(r'''^["']|["']$'''), '');
      }
    }
    return null;
  }

  String? _attributeValue(String raw, String key) {
    final match = RegExp('$key\\s*=\\s*"([^"]+)"').firstMatch(raw);
    return match?.group(1);
  }

  String _deduplicatedId(String baseId, Map<String, int> counts) {
    final base = baseId.isEmpty ? 'section' : baseId;
    final count = counts[base] ?? 0;
    counts[base] = count + 1;
    return count == 0 ? base : '$base-$count';
  }

  void _extractInlineItems({
    required String filePath,
    required String source,
    required String line,
    required int lineOffset,
    required List<MarkdownLink> links,
    required List<MarkdownImage> images,
    required List<MarkdownVariableToken> variables,
  }) {
    final imageRegex = RegExp(r'!\[([^\]]*)\]\(([^)]+)\)');
    for (final match in imageRegex.allMatches(line)) {
      images.add(
        MarkdownImage(
          alt: match.group(1)!,
          destination: match.group(2)!,
          span: SourceSpan.fromOffsets(
            filePath: filePath,
            source: source,
            startOffset: lineOffset + match.start,
            endOffset: lineOffset + match.end,
          ),
        ),
      );
    }
    final linkRegex = RegExp(r'(?<!!)\[([^\]]+)\]\(([^)]+)\)');
    for (final match in linkRegex.allMatches(line)) {
      links.add(
        MarkdownLink(
          text: match.group(1)!,
          destination: match.group(2)!,
          span: SourceSpan.fromOffsets(
            filePath: filePath,
            source: source,
            startOffset: lineOffset + match.start,
            endOffset: lineOffset + match.end,
          ),
        ),
      );
    }
    final variableRegex = RegExp(r'(?<!\\)%([A-Za-z_][A-Za-z0-9_.-]*)%');
    for (final match in variableRegex.allMatches(line)) {
      variables.add(
        MarkdownVariableToken(
          name: match.group(1)!,
          escaped: false,
          span: SourceSpan.fromOffsets(
            filePath: filePath,
            source: source,
            startOffset: lineOffset + match.start,
            endOffset: lineOffset + match.end,
          ),
        ),
      );
    }
  }

  void _extractXmlBlocks({
    required String filePath,
    required String source,
    required String line,
    required int lineOffset,
    required List<MarkdownXmlBlock> xmlBlocks,
  }) {
    final match = RegExp(r'<([A-Za-z][A-Za-z0-9_-]*)(\s|>|/)').firstMatch(line);
    if (match == null) {
      return;
    }
    final name = match.group(1)!;
    if (_inlineHtmlNames.contains(name.toLowerCase())) {
      return;
    }
    xmlBlocks.add(
      MarkdownXmlBlock(
        rawXml: line.trim(),
        elementName: name,
        span: SourceSpan.fromOffsets(
          filePath: filePath,
          source: source,
          startOffset: lineOffset + match.start,
          endOffset: lineOffset + line.length,
        ),
      ),
    );
  }

  void _extractUnsafeHtml({
    required String filePath,
    required String source,
    required String line,
    required int lineOffset,
    required List<Diagnostic> diagnostics,
  }) {
    final unsafe = RegExp(
      r'<script\b|on[a-z]+\s*=|javascript:',
      caseSensitive: false,
    ).firstMatch(line);
    if (unsafe == null) {
      return;
    }
    diagnostics.add(
      Diagnostic(
        code: 'markdown.raw-html.unsafe',
        severity: DiagnosticSeverity.warning,
        message: 'Unsafe raw HTML is blocked in preview.',
        filePath: filePath,
        sourceSpan: SourceSpan.fromOffsets(
          filePath: filePath,
          source: source,
          startOffset: lineOffset + unsafe.start,
          endOffset: lineOffset + unsafe.end,
        ),
      ),
    );
  }

  List<Diagnostic> _validateLocalReferences({
    required String filePath,
    required String source,
    required String? workspaceRoot,
    required List<MarkdownHeading> headings,
    required List<MarkdownLink> links,
    required List<MarkdownImage> images,
    required SourceLocationMapper mapper,
  }) {
    final diagnostics = <Diagnostic>[];
    final anchors = headings.map((item) => item.id).toSet();
    for (final link in links) {
      final destination = link.destination.trim();
      if (_isExternal(destination)) {
        continue;
      }
      final parts = destination.split('#');
      final targetPath = parts.first;
      final anchor = parts.length > 1 ? parts.sublist(1).join('#') : null;
      final resolved = targetPath.isEmpty
          ? filePath
          : p.normalize(p.join(p.dirname(filePath), targetPath));
      if (targetPath.isNotEmpty && !File(resolved).existsSync()) {
        diagnostics.add(
          Diagnostic(
            code: 'markdown.link.unresolved-target',
            severity: DiagnosticSeverity.warning,
            message: 'Local link target "$targetPath" does not exist.',
            filePath: filePath,
            sourceSpan: link.span,
          ),
        );
        continue;
      }
      if (anchor != null && anchor.isNotEmpty) {
        var targetAnchors = anchors;
        if (targetPath.isNotEmpty && File(resolved).existsSync()) {
          final targetSource = File(resolved).readAsStringSync();
          targetAnchors = parse(
            filePath: resolved,
            source: targetSource,
            workspaceRoot: workspaceRoot,
            validateLocalReferences: false,
          ).anchors;
        }
        if (!targetAnchors.contains(anchor)) {
          diagnostics.add(
            Diagnostic(
              code: 'markdown.link.unresolved-anchor',
              severity: DiagnosticSeverity.warning,
              message: 'Anchor "$anchor" was not found.',
              filePath: filePath,
              sourceSpan: link.span,
            ),
          );
        }
      }
    }
    for (final image in images) {
      if (image.alt.trim().isEmpty) {
        diagnostics.add(
          Diagnostic(
            code: 'markdown.image.missing-alt',
            severity: DiagnosticSeverity.warning,
            message: 'Image "$image.destination" is missing alt text.',
            filePath: filePath,
            sourceSpan: image.span,
          ),
        );
      }
      final destination = image.destination.trim();
      if (_isExternal(destination)) {
        continue;
      }
      if (!localImageExists(
        activeFilePath: filePath,
        destination: destination,
        workspaceRoot: workspaceRoot,
      )) {
        diagnostics.add(
          Diagnostic(
            code: 'markdown.image.missing-file',
            severity: DiagnosticSeverity.warning,
            message: 'Local image "$destination" does not exist.',
            filePath: filePath,
            sourceSpan: image.span,
          ),
        );
      }
    }
    return diagnostics;
  }

  bool _isExternal(String destination) {
    return destination.startsWith('http://') ||
        destination.startsWith('https://') ||
        destination.startsWith('mailto:');
  }
}

const _inlineHtmlNames = {
  'a',
  'abbr',
  'b',
  'br',
  'code',
  'div',
  'em',
  'i',
  'img',
  'p',
  'span',
  'strong',
};
