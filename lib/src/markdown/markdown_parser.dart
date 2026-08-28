import 'dart:io';
import 'dart:isolate';

import 'package:markdown/markdown.dart' as md;
import 'package:path/path.dart' as p;

import '../core/diagnostic.dart';
import '../core/local_image_resolver.dart';
import '../core/path_utils.dart';
import '../core/source_span.dart';
import '../core/uri_utils.dart';
import 'busymark_document.dart';
import 'markdown_ast_adapter.dart';
import 'markdown_fence.dart';
import 'markdown_model.dart';
import 'math_syntax.dart';
import 'raw_html_policy.dart';

// Cross-file diagnostics are intentionally scoped to Markdown files that
// resolve inside the opened workspace. Targets outside that root, unsupported
// file types, and oversized files are not inspected.
const int _maxLocalReferenceTargetBytes = 2 * 1024 * 1024;
const int _backgroundParseThresholdBytes = 64 * 1024;

class MarkdownParser {
  const MarkdownParser();

  Future<ParsedMarkdownDocument> parseAsync({
    required String filePath,
    required String source,
    MarkdownMode mode = MarkdownMode.commonMark,
    String? workspaceRoot,
    bool validateLocalReferences = true,
  }) async {
    final parsed =
        source.length < _backgroundParseThresholdBytes ||
            runtimeType != MarkdownParser
        ? parse(
            filePath: filePath,
            source: source,
            mode: mode,
            workspaceRoot: workspaceRoot,
            validateLocalReferences: false,
          )
        : await Isolate.run(
            () => parse(
              filePath: filePath,
              source: source,
              mode: mode,
              workspaceRoot: workspaceRoot,
              validateLocalReferences: false,
            ),
          );
    if (!validateLocalReferences) {
      return parsed;
    }
    final diagnostics = sortDiagnostics([
      ...parsed.diagnostics,
      ...await _validateLocalReferencesAsync(
        filePath: filePath,
        workspaceRoot: workspaceRoot,
        headings: parsed.headings,
        links: parsed.links,
        images: parsed.images,
      ),
    ]);
    return _withDiagnostics(parsed, diagnostics);
  }

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
    const astAdapter = MarkdownAstAdapter();
    var title = _frontMatterTitle(filePath, source, diagnostics);
    void inspectScannedHeadingAttributes({
      required String? attrText,
      required int startOffset,
      required int endOffset,
    }) {
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
            filePath: filePath,
            sourceSpan: SourceSpan.fromOffsets(
              filePath: filePath,
              source: source,
              startOffset: startOffset,
              endOffset: endOffset,
            ),
          ),
        );
      }
    }

    MarkdownFence? openFence;
    var fenceStart = 0;
    String? fenceLanguage;
    final fenceContent = StringBuffer();
    var offset = 0;
    String? previousSetextCandidateLine;
    int? previousSetextCandidateOffset;
    final lines = source.split(RegExp('(?<=\n)'));
    final scannedLines = <_ScannedSourceLine>[];
    var scannedOffset = 0;
    for (final rawLine in lines) {
      scannedLines.add(
        _ScannedSourceLine(rawLine: rawLine, offset: scannedOffset),
      );
      scannedOffset += rawLine.length;
    }
    var lineIndex = 0;
    var rawHtmlBlockEndOffset = 0;

    for (final rawLine in lines) {
      final line = rawLine.endsWith('\n')
          ? rawLine.substring(0, rawLine.length - 1)
          : rawLine;
      final trimmed = line.trimRight();
      final activeFence = openFence;
      if (activeFence != null) {
        previousSetextCandidateLine = null;
        previousSetextCandidateOffset = null;
        if (activeFence.closes(line)) {
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
          openFence = null;
        } else {
          fenceContent.write(rawLine);
        }
        offset += rawLine.length;
        lineIndex += 1;
        continue;
      }
      final openingFence = MarkdownFence.parse(line);
      if (openingFence != null) {
        previousSetextCandidateLine = null;
        previousSetextCandidateOffset = null;
        openFence = openingFence;
        fenceStart = offset;
        fenceLanguage = openingFence.language;
        offset += rawLine.length;
        lineIndex += 1;
        continue;
      }

      if (offset >= rawHtmlBlockEndOffset) {
        final htmlEndIndex = _rawHtmlContainerSourceEndIndex(
          scannedLines,
          lineIndex,
        );
        rawHtmlBlockEndOffset = htmlEndIndex == null
            ? 0
            : scannedLines[htmlEndIndex - 1].endOffset;
      }
      final inRawHtmlBlock = offset < rawHtmlBlockEndOffset;
      final heading = RegExp(
        r'^[ ]{0,3}(#{1,6})(?:[ \t]+(.*?))?[ \t]*$',
      ).firstMatch(inRawHtmlBlock ? '' : trimmed);
      if (heading != null) {
        final headingText = (heading.group(2) ?? '').replaceFirst(
          RegExp(r'[ \t]+#+[ \t]*$'),
          '',
        );
        final attributeMatch = RegExp(
          r'(\{[^}]+\})[ \t]*$',
        ).firstMatch(headingText);
        inspectScannedHeadingAttributes(
          attrText: attributeMatch?.group(1),
          startOffset: offset,
          endOffset: offset + line.length,
        );
        previousSetextCandidateLine = null;
        previousSetextCandidateOffset = null;
      } else if (_setextUnderlineLevel(trimmed) != null &&
          !inRawHtmlBlock &&
          previousSetextCandidateLine != null &&
          previousSetextCandidateOffset != null) {
        previousSetextCandidateLine = null;
        previousSetextCandidateOffset = null;
      }

      _extractVariableTokens(
        filePath: filePath,
        source: source,
        line: line,
        lineOffset: offset,
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
        mode: mode,
        diagnostics: diagnostics,
      );

      if (inRawHtmlBlock) {
        previousSetextCandidateLine = null;
        previousSetextCandidateOffset = null;
      } else if (_isSetextHeadingCandidate(trimmed)) {
        previousSetextCandidateLine = line;
        previousSetextCandidateOffset = offset;
      } else if (trimmed.isEmpty) {
        previousSetextCandidateLine = null;
        previousSetextCandidateOffset = null;
      } else if (trimmed.isNotEmpty) {
        previousSetextCandidateLine = null;
        previousSetextCandidateOffset = null;
      }

      offset += rawLine.length;
      lineIndex += 1;
    }

    final renderedDocument = astAdapter.parse(
      filePath: filePath,
      source: source,
      mode: mode,
      title: title,
    );
    var busyDocument = _withScannedSourceMetadata(
      renderedDocument,
      sortDiagnostics(diagnostics),
    );
    final canonicalHeadings = _canonicalizeHeadings(
      document: busyDocument,
      filePath: filePath,
      mode: mode,
      initialTitle: title,
    );
    busyDocument = canonicalHeadings.document;
    headings.addAll(canonicalHeadings.headings);
    diagnostics.addAll(canonicalHeadings.diagnostics);
    title = canonicalHeadings.title;
    if (mode == MarkdownMode.writersideMarkdown && title == null) {
      diagnostics.add(
        Diagnostic(
          code: 'writerside.topic.missing-title',
          severity: DiagnosticSeverity.warning,
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
    final inlineReferences = _extractAstInlineReferences(
      filePath: filePath,
      source: source,
      document: busyDocument,
    );
    links.addAll(inlineReferences.links);
    images.addAll(inlineReferences.images);
    diagnostics.addAll(
      _accessibilityDiagnostics(
        filePath: filePath,
        headings: headings,
        links: links,
        document: busyDocument,
      ),
    );

    if (validateLocalReferences) {
      diagnostics.addAll(
        _validateLocalReferences(
          filePath: filePath,
          workspaceRoot: workspaceRoot,
          headings: headings,
          links: links,
          images: images,
        ),
      );
    }

    busyDocument = busyDocument.copyWith(
      diagnostics: sortDiagnostics(diagnostics),
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

  List<Diagnostic> _accessibilityDiagnostics({
    required String filePath,
    required List<MarkdownHeading> headings,
    required List<MarkdownLink> links,
    required BusyDocument document,
  }) {
    final diagnostics = <Diagnostic>[];
    for (var index = 1; index < headings.length; index += 1) {
      final previous = headings[index - 1];
      final current = headings[index];
      if (current.level <= previous.level + 1) {
        continue;
      }
      diagnostics.add(
        Diagnostic(
          code: 'markdown.heading.skipped-level',
          severity: DiagnosticSeverity.warning,
          filePath: filePath,
          args: {'previousLevel': previous.level, 'level': current.level},
          sourceSpan: current.span,
          relatedSpans: [previous.span],
        ),
      );
    }

    const genericLinkLabels = {
      'click here',
      'here',
      'learn more',
      'more',
      'read more',
      'this link',
    };
    for (final link in links) {
      final text = link.text.trim();
      if (text.isEmpty) {
        diagnostics.add(
          Diagnostic(
            code: 'markdown.link.empty-text',
            severity: DiagnosticSeverity.warning,
            filePath: filePath,
            sourceSpan: link.span,
          ),
        );
        continue;
      }
      final normalized = text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      if (genericLinkLabels.contains(normalized) ||
          normalized == link.destination.trim().toLowerCase()) {
        diagnostics.add(
          Diagnostic(
            code: 'markdown.link.review-text',
            severity: DiagnosticSeverity.hint,
            filePath: filePath,
            args: {'text': text},
            sourceSpan: link.span,
          ),
        );
      }
    }

    for (final block in _walkBlocks(document.blocks)) {
      if (block.kind != BusyBlockKind.table) {
        continue;
      }
      final header = block.children.firstOrNull;
      if (header == null ||
          header.children.isEmpty ||
          header.children.any((cell) => cell.plainText.trim().isEmpty)) {
        diagnostics.add(
          Diagnostic(
            code: 'markdown.table.empty-header',
            severity: DiagnosticSeverity.warning,
            filePath: filePath,
            sourceSpan: block.sourceSpan,
          ),
        );
      }
    }
    return diagnostics;
  }

  Iterable<BusyBlock> _walkBlocks(Iterable<BusyBlock> roots) sync* {
    for (final block in roots) {
      yield block;
      yield* _walkBlocks(block.children);
    }
  }

  BusyDocument _withScannedSourceMetadata(
    BusyDocument document,
    List<Diagnostic> diagnostics,
  ) {
    final sourceChunks = document.source == null
        ? const <_ScannedBlockSource>[]
        : _scannedBlockSources(
            document.filePath,
            document.source!,
            mode: document.mode,
          );
    final contentBlocks = document.blocks
        .where(
          (block) =>
              block.kind != BusyBlockKind.frontMatter && !block.isGenerated,
        )
        .toList(growable: false);
    final generatedBlocks = document.blocks
        .where((block) => block.isGenerated)
        .toList(growable: false);
    final modeledSourceChunks = sourceChunks
        .where((chunk) => !chunk.sourceOnly)
        .toList(growable: false);
    final canAssignSource = modeledSourceChunks.length == contentBlocks.length;
    if (!canAssignSource) {
      // A complex construct can be modeled as a different number of blocks by
      // the AST and the lossless source scanner. Preserve top-level heading
      // spans independently: title and outline projection must not disappear
      // merely because unrelated content falls back to protected source.
      final headingSourceChunks = sourceChunks
          .where(_isScannedHeadingSource)
          .toList(growable: false);
      var headingSourceIndex = 0;
      final contentWithMetadata = [
        for (final block in contentBlocks)
          _blockWithScannedSourceMetadata(
            block,
            block.kind == BusyBlockKind.heading &&
                    headingSourceIndex < headingSourceChunks.length
                ? headingSourceChunks[headingSourceIndex++]
                : null,
          ),
      ];
      if (sourceChunks.any((chunk) => chunk.protectEdits)) {
        final source = document.source!;
        final sourceStart = _frontMatterEndOffset(source);
        final opaqueSource = _sourceOnlyBlock(
          _ScannedBlockSource.fromOffsets(
            filePath: document.filePath,
            source: source,
            startOffset: sourceStart,
            endOffset: source.length,
            sourceOnly: true,
          ),
        );
        return document.copyWith(
          diagnostics: diagnostics,
          blocks: [
            for (final block in document.blocks)
              if (block.kind == BusyBlockKind.frontMatter) block,
            opaqueSource,
            for (final block in contentWithMetadata)
              _sourceProtectedTree(block).copyWith(isGenerated: true),
            for (final block in generatedBlocks) _sourceProtectedTree(block),
          ],
        );
      }
      return document.copyWith(
        diagnostics: diagnostics,
        blocks: [
          for (final block in document.blocks)
            if (block.kind == BusyBlockKind.frontMatter) block,
          // A scanner mismatch must never discard source that the AST does
          // not model. Keep opaque chunks in source order ahead of modeled
          // content; the serializer can then retain them during its safe
          // full-serialization fallback.
          for (final chunk in sourceChunks)
            if (chunk.sourceOnly) _sourceOnlyBlock(chunk),
          ...contentWithMetadata,
          ...generatedBlocks,
        ],
      );
    }

    var blockIndex = 0;
    return document.copyWith(
      diagnostics: diagnostics,
      blocks: [
        for (final block in document.blocks)
          if (block.kind == BusyBlockKind.frontMatter) block,
        for (final chunk in sourceChunks)
          if (chunk.sourceOnly)
            _sourceOnlyBlock(chunk)
          else
            _blockWithScannedSourceMetadata(contentBlocks[blockIndex++], chunk),
        ...generatedBlocks,
      ],
    );
  }

  bool _isScannedHeadingSource(_ScannedBlockSource chunk) {
    final lines = chunk.rawSource.split('\n');
    if (lines.isEmpty) {
      return false;
    }
    if (_isAtxHeading(lines.first)) {
      return true;
    }
    return lines.length > 1 && _setextUnderlineLevel(lines[1].trim()) != null;
  }

  _CanonicalHeadingProjection _canonicalizeHeadings({
    required BusyDocument document,
    required String filePath,
    required MarkdownMode mode,
    required String? initialTitle,
  }) {
    final headings = <MarkdownHeading>[];
    final diagnostics = <Diagnostic>[];
    final generatedIdOccurrences = <String, int>{};
    final firstSpansById = <String, SourceSpan>{};
    var title = initialTitle;
    var levelOneCount = 0;
    final blocks = <BusyBlock>[];

    for (final block in document.blocks) {
      if (block.kind != BusyBlockKind.heading) {
        blocks.add(block);
        continue;
      }
      final level = (int.tryParse(block.attributes['level'] ?? '') ?? 1)
          .clamp(1, 6)
          .toInt();
      final generated = block.attributes['generatedId'] != 'false';
      final id = generated
          ? nextGeneratedHeadingId(
              slugForHeading(block.plainText),
              generatedIdOccurrences,
            )
          : block.attributes['id'] ?? block.id;
      blocks.add(
        block.copyWith(
          attributes: {
            ...block.attributes,
            'id': id,
            'level': '$level',
            'generatedId': '$generated',
          },
        ),
      );
      final span = block.sourceSpan;
      if (span == null) {
        continue;
      }
      final heading = MarkdownHeading(
        level: level,
        text: block.plainText,
        id: id,
        generatedId: generated,
        span: span,
      );
      headings.add(heading);
      if (level == 1) {
        title ??= heading.text;
        levelOneCount += 1;
        if (mode == MarkdownMode.writersideMarkdown && levelOneCount > 1) {
          diagnostics.add(
            Diagnostic(
              code: 'writerside.topic.h1-converted-to-chapter',
              severity: DiagnosticSeverity.warning,
              filePath: filePath,
              sourceSpan: span,
            ),
          );
        }
      }
      final firstSpan = firstSpansById[id];
      if (firstSpan == null) {
        firstSpansById[id] = span;
      } else {
        diagnostics.add(
          Diagnostic(
            code: 'markdown.heading.duplicate-id',
            severity: DiagnosticSeverity.warning,
            filePath: filePath,
            args: {'id': id},
            sourceSpan: span,
            relatedSpans: [firstSpan],
          ),
        );
      }
    }

    return _CanonicalHeadingProjection(
      document: document.copyWith(title: title, blocks: blocks),
      headings: List.unmodifiable(headings),
      diagnostics: List.unmodifiable(diagnostics),
      title: title,
    );
  }

  ParsedMarkdownDocument _withDiagnostics(
    ParsedMarkdownDocument parsed,
    List<Diagnostic> diagnostics,
  ) {
    return ParsedMarkdownDocument(
      filePath: parsed.filePath,
      source: parsed.source,
      mode: parsed.mode,
      title: parsed.title,
      headings: parsed.headings,
      links: parsed.links,
      images: parsed.images,
      codeBlocks: parsed.codeBlocks,
      xmlBlocks: parsed.xmlBlocks,
      variables: parsed.variables,
      diagnostics: diagnostics,
      busyDocument: parsed.busyDocument.copyWith(diagnostics: diagnostics),
    );
  }

  _AstInlineReferences _extractAstInlineReferences({
    required String filePath,
    required String source,
    required BusyDocument document,
  }) {
    final links = <MarkdownLink>[];
    final images = <MarkdownImage>[];
    final fallbackSpan = SourceSpan.entireFile(filePath, source);

    void visitInline(BusyInline inline, SourceSpan span) {
      final destination = inline.destination;
      if (destination != null && destination.trim().isNotEmpty) {
        switch (inline.kind) {
          case BusyInlineKind.link:
            links.add(
              MarkdownLink(
                text: inline.plainText,
                destination: destination,
                span: span,
              ),
            );
            break;
          case BusyInlineKind.image:
            images.add(
              MarkdownImage(
                alt: inline.text,
                destination: destination,
                span: span,
              ),
            );
            break;
          case BusyInlineKind.text:
          case BusyInlineKind.math:
          case BusyInlineKind.strong:
          case BusyInlineKind.emphasis:
          case BusyInlineKind.underline:
          case BusyInlineKind.strikethrough:
          case BusyInlineKind.code:
          case BusyInlineKind.softBreak:
          case BusyInlineKind.hardBreak:
          case BusyInlineKind.html:
          case BusyInlineKind.writersideVariable:
          case BusyInlineKind.unknown:
            break;
        }
      }
      for (final child in inline.children) {
        visitInline(child, span);
      }
    }

    void visitBlock(BusyBlock block, SourceSpan inheritedSpan) {
      final span = block.sourceSpan ?? inheritedSpan;
      for (final inline in block.inlines) {
        visitInline(inline, span);
      }
      for (final child in block.children) {
        visitBlock(child, span);
      }
    }

    for (final block in document.blocks) {
      visitBlock(block, fallbackSpan);
    }
    return _AstInlineReferences(links: links, images: images);
  }

  BusyBlock _blockWithScannedSourceMetadata(
    BusyBlock block,
    _ScannedBlockSource? sourceChunk,
  ) {
    var updated = block;
    if (updated.kind != BusyBlockKind.frontMatter && sourceChunk != null) {
      updated = updated.copyWith(
        rawSource: sourceChunk.rawSource,
        sourceSpan: sourceChunk.span,
      );
      if (sourceChunk.protectEdits) {
        updated = _sourceProtectedTree(updated);
      }
    }
    return updated;
  }

  BusyBlock _sourceProtectedTree(BusyBlock block) {
    return block.copyWith(
      children: [
        for (final child in block.children) _sourceProtectedTree(child),
      ],
      preserveRaw: true,
      isSourceProtected: true,
    );
  }

  BusyBlock _sourceOnlyBlock(_ScannedBlockSource chunk) {
    return BusyBlock(
      id: '\u0000source-only:${chunk.span.startOffset}',
      kind: BusyBlockKind.unknown,
      rawSource: chunk.rawSource,
      sourceSpan: chunk.span,
      preserveRaw: true,
      isSourceOnly: true,
      isSourceProtected: true,
    );
  }

  List<_ScannedBlockSource> _scannedBlockSources(
    String filePath,
    String source, {
    required MarkdownMode mode,
  }) {
    var scanOffset = _frontMatterEndOffset(source);
    final sourceLocationMapper = SourceLocationMapper(source);
    final chunks = <_ScannedBlockSource>[];
    final lines = source.substring(scanOffset).split(RegExp('(?<=\n)'));
    final indexedLines = <_ScannedSourceLine>[];
    for (final rawLine in lines) {
      indexedLines.add(
        _ScannedSourceLine(rawLine: rawLine, offset: scanOffset),
      );
      scanOffset += rawLine.length;
    }

    void addChunk(int startIndex, int endIndex, {bool sourceOnly = false}) {
      if (startIndex >= indexedLines.length || endIndex <= startIndex) {
        return;
      }
      final startOffset = indexedLines[startIndex].offset;
      final endOffset = indexedLines[endIndex - 1].endOffset;
      chunks.add(
        _ScannedBlockSource.fromOffsets(
          filePath: filePath,
          source: source,
          startOffset: startOffset,
          endOffset: endOffset,
          sourceOnly: sourceOnly,
          sourceLocationMapper: sourceLocationMapper,
          protectEdits:
              !sourceOnly &&
              _containsNestedDefinitions(
                source.substring(startOffset, endOffset),
              ),
        ),
      );
    }

    var index = 0;
    while (index < indexedLines.length) {
      if (indexedLines[index].trimmed.isEmpty) {
        index += 1;
        continue;
      }

      final startIndex = index;
      final footnoteDefinitionEnd = _footnoteDefinitionEndIndex(
        indexedLines,
        index,
      );
      if (footnoteDefinitionEnd != null) {
        addChunk(startIndex, footnoteDefinitionEnd, sourceOnly: true);
        index = footnoteDefinitionEnd;
        continue;
      }
      final referenceDefinitionEnd = _linkReferenceDefinitionEndIndex(
        indexedLines,
        index,
      );
      if (referenceDefinitionEnd != null) {
        addChunk(startIndex, referenceDefinitionEnd, sourceOnly: true);
        index = referenceDefinitionEnd;
        continue;
      }

      final fence = MarkdownFence.parse(indexedLines[index].line);
      if (fence != null) {
        index += 1;
        while (index < indexedLines.length) {
          if (fence.closes(indexedLines[index].line)) {
            index += 1;
            break;
          }
          index += 1;
        }
        if (mode == MarkdownMode.writersideMarkdown &&
            index < indexedLines.length &&
            _isWritersideCodeAttributeLine(indexedLines[index].trimmed)) {
          index += 1;
        }
        addChunk(startIndex, index);
        continue;
      }

      final displayMathEnd = _displayMathEndIndex(indexedLines, index);
      if (displayMathEnd != null) {
        addChunk(startIndex, displayMathEnd);
        index = displayMathEnd;
        continue;
      }

      final htmlEndIndex = _rawHtmlContainerSourceEndIndex(indexedLines, index);
      if (htmlEndIndex != null) {
        addChunk(startIndex, htmlEndIndex);
        index = htmlEndIndex;
        continue;
      }
      if (mode == MarkdownMode.writersideMarkdown) {
        final writersideEndIndex = _writersideContainerSourceEndIndex(
          indexedLines,
          index,
        );
        if (writersideEndIndex != null) {
          addChunk(startIndex, writersideEndIndex);
          index = writersideEndIndex;
          continue;
        }
      }

      if (_isAtxHeading(indexedLines[index].line) ||
          _isThematicBreak(indexedLines[index].trimmed)) {
        index += 1;
        addChunk(startIndex, index);
        continue;
      }

      final listIndent = _listItemIndent(indexedLines[index].line);
      if (listIndent != null) {
        index += 1;
        while (index < indexedLines.length) {
          final line = indexedLines[index];
          if (line.trimmed.isEmpty) {
            break;
          }
          final nextIndent = _listItemIndent(line.line);
          if (nextIndent != null && nextIndent <= listIndent) {
            break;
          }
          index += 1;
        }
        addChunk(startIndex, index);
        continue;
      }

      final startsWithBlockquote = _isBlockquoteStart(
        indexedLines[startIndex].line,
      );
      index += 1;
      while (index < indexedLines.length) {
        final line = indexedLines[index];
        if (line.trimmed.isEmpty ||
            MarkdownFence.parse(line.line) != null ||
            _startsDisplayMath(line.line) ||
            _isAtxHeading(line.line) ||
            (!startsWithBlockquote && _isBlockquoteStart(line.line)) ||
            _listItemIndent(line.line) != null) {
          break;
        }
        if (_setextUnderlineLevel(line.trimmed) != null &&
            index == startIndex + 1) {
          index += 1;
          break;
        }
        if (_isThematicBreak(line.trimmed)) {
          break;
        }
        index += 1;
      }
      addChunk(startIndex, index);
    }
    return chunks;
  }

  bool _isWritersideCodeAttributeLine(String line) {
    return RegExp(
      r'^\{[^{}]*(?:\bcollapsible\s*=\s*"true"|\bsrc\s*=\s*"[^"]+")[^{}]*\}\s*$',
      caseSensitive: false,
    ).hasMatch(line);
  }

  bool _containsNestedDefinitions(String source) {
    if (!source.contains(']:')) {
      return false;
    }
    final document = _markdownDocument();
    document.parse(source);
    return document.linkReferences.isNotEmpty ||
        document.footnoteReferences.isNotEmpty;
  }

  int? _footnoteDefinitionEndIndex(
    List<_ScannedSourceLine> lines,
    int startIndex,
  ) {
    const syntax = md.FootnoteDefSyntax();
    final firstLine = _withoutCarriageReturn(lines[startIndex].line);
    if (!syntax.pattern.hasMatch(firstLine)) {
      return null;
    }
    final markdownLines = _footnoteCandidateLines(lines, startIndex);
    if (markdownLines.isEmpty) {
      return null;
    }
    final document = _markdownDocument();
    final parser = md.BlockParser(markdownLines, document);
    if (!syntax.canParse(parser)) {
      return null;
    }
    syntax.parse(parser);
    if (document.footnoteReferences.isEmpty) {
      return null;
    }
    final consumedLines = _consumedLineCount(parser, markdownLines);
    if (consumedLines <= 0) {
      return null;
    }
    final verificationDocument = _markdownDocument();
    verificationDocument.parseLines([
      for (final line in markdownLines.take(consumedLines)) line.content,
    ]);
    if (verificationDocument.footnoteReferences.isEmpty) {
      return null;
    }
    return startIndex + consumedLines;
  }

  int? _linkReferenceDefinitionEndIndex(
    List<_ScannedSourceLine> lines,
    int startIndex,
  ) {
    const syntax = md.LinkReferenceDefinitionSyntax();
    final firstLine = _withoutCarriageReturn(lines[startIndex].line);
    if (!syntax.pattern.hasMatch(firstLine) ||
        !_hasPotentialLinkReferenceLabel(lines, startIndex)) {
      return null;
    }
    var endIndex = _nextLinkDefinitionBoundary(lines, startIndex + 1);
    var extendedToBlockEnd = false;
    while (true) {
      final markdownLines = [
        for (var index = startIndex; index < endIndex; index++)
          md.Line(_withoutCarriageReturn(lines[index].line)),
      ];
      if (markdownLines.isEmpty) {
        return null;
      }
      final document = _markdownDocument();
      final parser = md.BlockParser(markdownLines, document);
      if (!syntax.canParse(parser)) {
        return null;
      }
      syntax.parse(parser);
      if (document.linkReferences.isNotEmpty) {
        final consumedLines = _consumedLineCount(parser, markdownLines);
        if (consumedLines <= 0) {
          return null;
        }

        // Confirm the definition wins normal block-syntax precedence. Calling
        // the definition syntax directly is only used to learn its exact line
        // count.
        final verificationDocument = _markdownDocument();
        final nodes = verificationDocument.parseLines([
          for (final line in markdownLines.take(consumedLines)) line.content,
        ]);
        if (nodes.isNotEmpty || verificationDocument.linkReferences.isEmpty) {
          return null;
        }
        return startIndex + consumedLines;
      }
      if (endIndex >= lines.length || lines[endIndex].trimmed.isEmpty) {
        return null;
      }
      if (extendedToBlockEnd) {
        return null;
      }
      endIndex = _nextBlankLineBoundary(lines, endIndex + 1);
      extendedToBlockEnd = true;
    }
  }

  int _nextLinkDefinitionBoundary(
    List<_ScannedSourceLine> lines,
    int searchStart,
  ) {
    for (var index = searchStart; index < lines.length; index++) {
      final content = _withoutCarriageReturn(lines[index].line);
      if (content.trim().isEmpty || _startsDefinitionCandidate(content)) {
        return index;
      }
    }
    return lines.length;
  }

  int _nextBlankLineBoundary(List<_ScannedSourceLine> lines, int searchStart) {
    for (var index = searchStart; index < lines.length; index++) {
      if (lines[index].trimmed.isEmpty) {
        return index;
      }
    }
    return lines.length;
  }

  List<md.Line> _footnoteCandidateLines(
    List<_ScannedSourceLine> lines,
    int startIndex,
  ) {
    final result = <md.Line>[];
    for (var index = startIndex; index < lines.length; index++) {
      final content = _withoutCarriageReturn(lines[index].line);
      if (index > startIndex && _startsDefinitionCandidate(content)) {
        break;
      }
      result.add(md.Line(content));
    }
    return result;
  }

  bool _startsDefinitionCandidate(String line) {
    if (const md.FootnoteDefSyntax().pattern.hasMatch(line)) {
      return true;
    }
    return const md.LinkReferenceDefinitionSyntax().pattern.hasMatch(line) &&
        line.contains(']:');
  }

  bool _hasPotentialLinkReferenceLabel(
    List<_ScannedSourceLine> lines,
    int startIndex,
  ) {
    const maximumLabelLength = 999;
    var labelLength = 0;
    for (var lineIndex = startIndex; lineIndex < lines.length; lineIndex++) {
      final line = _withoutCarriageReturn(lines[lineIndex].line);
      if (lineIndex > startIndex && line.trim().isEmpty) {
        return false;
      }
      var characterIndex = lineIndex == startIndex ? line.indexOf('[') + 1 : 0;
      while (characterIndex < line.length) {
        final character = line.codeUnitAt(characterIndex);
        if (character == 0x5c) {
          characterIndex += 2;
          labelLength += 1;
        } else if (character == 0x5b) {
          return false;
        } else if (character == 0x5d) {
          return characterIndex + 1 < line.length &&
              line.codeUnitAt(characterIndex + 1) == 0x3a;
        } else {
          characterIndex += 1;
          labelLength += 1;
        }
        if (labelLength > maximumLabelLength) {
          return false;
        }
      }
      labelLength += 1;
      if (labelLength > maximumLabelLength) {
        return false;
      }
    }
    return false;
  }

  md.Document _markdownDocument() {
    return busyMarkMarkdownDocument(MarkdownMode.commonMark);
  }

  int? _displayMathEndIndex(List<_ScannedSourceLine> lines, int startIndex) {
    if (!_startsDisplayMath(lines[startIndex].line)) {
      return null;
    }
    final first = lines[startIndex].line;
    final opening = first.indexOf(r'$$');
    final tail = first.substring(opening + 2);
    final firstClose = _displayMathCloseIndex(tail);
    if (firstClose != null) {
      return tail.substring(0, firstClose).trim().isEmpty
          ? null
          : startIndex + 1;
    }
    final expression = StringBuffer(tail);
    for (var index = startIndex + 1; index < lines.length; index++) {
      final line = lines[index].line;
      final close = _displayMathCloseIndex(line);
      if (close != null) {
        if (expression.isNotEmpty) expression.writeln();
        expression.write(line.substring(0, close));
        return expression.toString().trim().isEmpty ? null : index + 1;
      }
      if (expression.isNotEmpty) expression.writeln();
      expression.write(line);
    }
    return null;
  }

  bool _startsDisplayMath(String line) {
    return RegExp(r'^ {0,3}\$\$(?!\$)').hasMatch(line);
  }

  int? _displayMathCloseIndex(String line) {
    for (var index = 0; index + 1 < line.length; index++) {
      if (!line.startsWith(r'$$', index)) {
        continue;
      }
      var backslashes = 0;
      for (
        var cursor = index - 1;
        cursor >= 0 && line.codeUnitAt(cursor) == 0x5c;
        cursor--
      ) {
        backslashes += 1;
      }
      if (backslashes.isEven && line.substring(index + 2).trim().isEmpty) {
        return index;
      }
    }
    return null;
  }

  int _consumedLineCount(md.BlockParser parser, List<md.Line> lines) {
    return parser.isDone
        ? lines.length
        : lines.indexWhere((line) => identical(line, parser.current));
  }

  String _withoutCarriageReturn(String line) {
    return line.endsWith('\r') ? line.substring(0, line.length - 1) : line;
  }

  bool _isAtxHeading(String line) {
    return RegExp(r'^[ ]{0,3}#{1,6}(?:[ \t]+|$)').hasMatch(line);
  }

  bool _isBlockquoteStart(String line) {
    return RegExp(r'^[ ]{0,3}>').hasMatch(line);
  }

  bool _isThematicBreak(String trimmedLine) {
    return RegExp(r'^([*\-_])(\s*\1){2,}\s*$').hasMatch(trimmedLine);
  }

  int? _listItemIndent(String line) {
    final match = RegExp(r'^(\s*)([-+*]|\d+[.)])\s+').firstMatch(line);
    return match?.group(1)!.length;
  }

  int? _rawHtmlContainerSourceEndIndex(
    List<_ScannedSourceLine> lines,
    int startIndex,
  ) {
    final tag = _rawHtmlContainerOpeningTag(lines[startIndex].line);
    if (tag == null) {
      return null;
    }

    var balance = 0;
    for (var index = startIndex; index < lines.length; index += 1) {
      balance += _rawHtmlTagBalance(lines[index].line, tag);
      if ((balance <= 0 && index > startIndex) || balance == 0) {
        return index + 1;
      }
    }
    return null;
  }

  int? _writersideContainerSourceEndIndex(
    List<_ScannedSourceLine> lines,
    int startIndex,
  ) {
    final match = RegExp(
      r'^\s{0,3}<([A-Za-z][A-Za-z0-9_-]*)\b',
    ).firstMatch(lines[startIndex].line);
    final tag = match?.group(1)?.toLowerCase();
    if (tag == null ||
        !{
          'note',
          'tip',
          'warning',
          'quote',
          'tabs',
          'tab',
          'procedure',
          'step',
          'chapter',
          'code-block',
          'deflist',
          'def',
          'video',
        }.contains(tag)) {
      return null;
    }
    var balance = 0;
    for (var index = startIndex; index < lines.length; index += 1) {
      balance += _rawHtmlTagBalance(lines[index].line, tag);
      if (balance <= 0) {
        return index + 1;
      }
    }
    return null;
  }

  String? _rawHtmlContainerOpeningTag(String line) {
    final match = RegExp(
      r'^\s{0,3}<([A-Za-z][A-Za-z0-9_-]*)\b',
    ).firstMatch(line);
    if (match == null) {
      return null;
    }
    final tag = match.group(1)!.toLowerCase();
    if (voidHtmlTags.contains(tag)) {
      return null;
    }
    if (!isSafeBlockHtmlTag(tag) && !isUnsafeHtmlTag(tag)) {
      return null;
    }
    return tag;
  }

  int _rawHtmlTagBalance(String line, String tag) {
    final pattern = RegExp(
      '</?\\s*${RegExp.escape(tag)}(?=\\s|>|/)',
      caseSensitive: false,
    );
    var balance = 0;
    for (final match in pattern.allMatches(line)) {
      if (line.startsWith('</', match.start)) {
        balance -= 1;
        continue;
      }
      if (_rawHtmlTagLooksSelfClosing(line, match.start)) {
        continue;
      }
      balance += 1;
    }
    return balance;
  }

  bool _rawHtmlTagLooksSelfClosing(String line, int start) {
    final end = line.indexOf('>', start);
    if (end == -1) {
      return false;
    }
    return line.substring(start, end + 1).trimRight().endsWith('/>');
  }

  int _frontMatterEndOffset(String source) {
    if (!source.startsWith('---')) {
      return 0;
    }
    final end = source.indexOf('\n---', 3);
    if (end == -1) {
      return 0;
    }
    final nextLine = source.indexOf('\n', end + 4);
    return nextLine == -1 ? source.length : nextLine + 1;
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

  int? _setextUnderlineLevel(String trimmedLine) {
    if (RegExp(r'^=+\s*$').hasMatch(trimmedLine)) {
      return 1;
    }
    if (RegExp(r'^-+\s*$').hasMatch(trimmedLine)) {
      return 2;
    }
    return null;
  }

  bool _isSetextHeadingCandidate(String trimmedLine) {
    if (trimmedLine.isEmpty) {
      return false;
    }
    if (RegExp(r'^#{1,6}(?:[ \t]+|$)').hasMatch(trimmedLine)) {
      return false;
    }
    if (RegExp(r'^([-+*]|\d+[.)])\s+').hasMatch(trimmedLine)) {
      return false;
    }
    if (trimmedLine.startsWith('>') || trimmedLine.startsWith('|')) {
      return false;
    }
    return _setextUnderlineLevel(trimmedLine) == null;
  }

  void _extractVariableTokens({
    required String filePath,
    required String source,
    required String line,
    required int lineOffset,
    required List<MarkdownVariableToken> variables,
  }) {
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
    final normalizedName = name.toLowerCase();
    if (!_writersideXmlTag(normalizedName) &&
        (isSafeHtmlTag(normalizedName) || isUnsafeHtmlTag(normalizedName))) {
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
    required MarkdownMode mode,
    required List<Diagnostic> diagnostics,
  }) {
    if (mode == MarkdownMode.writersideMarkdown &&
        RegExp(
          r'^\s{0,3}<video(?:\s|/?>)',
          caseSensitive: false,
        ).hasMatch(line)) {
      return;
    }
    if (!hasUnsafeHtml(line)) {
      return;
    }
    final unsafe =
        RegExp(
          r'</?\s*[A-Za-z][A-Za-z0-9_-]*\b|on[A-Za-z0-9_-]+\s*=|(?:java|vb)script:|data:',
          caseSensitive: false,
        ).firstMatch(line) ??
        RegExp(r'\S+').firstMatch(line);
    diagnostics.add(
      Diagnostic(
        code: 'markdown.raw-html.unsafe',
        severity: DiagnosticSeverity.warning,
        filePath: filePath,
        sourceSpan: SourceSpan.fromOffsets(
          filePath: filePath,
          source: source,
          startOffset: lineOffset + (unsafe?.start ?? 0),
          endOffset: lineOffset + (unsafe?.end ?? line.length),
        ),
      ),
    );
  }

  bool _writersideXmlTag(String tag) {
    return {
      'var',
      'tabs',
      'tab',
      'code-block',
      'chapter',
      'procedure',
      'note',
      'tip',
      'warning',
      'quote',
      'video',
    }.contains(tag);
  }

  List<Diagnostic> _validateLocalReferences({
    required String filePath,
    required String? workspaceRoot,
    required List<MarkdownHeading> headings,
    required List<MarkdownLink> links,
    required List<MarkdownImage> images,
  }) {
    final diagnostics = <Diagnostic>[];
    final anchors = headings.map((item) => item.id).toSet();
    for (final link in links) {
      final destination = link.destination.trim();
      if (hasUriScheme(destination)) {
        continue;
      }
      final fragmentIndex = destination.indexOf('#');
      final targetPath = fragmentIndex == -1
          ? destination
          : destination.substring(0, fragmentIndex);
      final anchor = fragmentIndex == -1
          ? null
          : destination.substring(fragmentIndex + 1);
      final decodedAnchor = anchor == null
          ? null
          : _decodeLocalReferenceAnchor(anchor);
      final target = _resolveLocalLinkTarget(
        filePath: filePath,
        workspaceRoot: workspaceRoot,
        targetPath: targetPath,
      );
      if (targetPath.isNotEmpty && target.blocksTargetValidation) {
        diagnostics.add(
          Diagnostic(
            code: 'markdown.link.unresolved-target',
            severity: DiagnosticSeverity.warning,
            filePath: filePath,
            args: {'targetPath': targetPath},
            sourceSpan: link.span,
          ),
        );
        continue;
      }
      if (decodedAnchor != null && decodedAnchor.isNotEmpty) {
        var targetAnchors = anchors;
        if (targetPath.isNotEmpty) {
          continue;
        }
        if (!targetAnchors.contains(decodedAnchor)) {
          diagnostics.add(
            Diagnostic(
              code: 'markdown.link.unresolved-anchor',
              severity: DiagnosticSeverity.warning,
              filePath: filePath,
              args: {'anchor': anchor},
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
            filePath: filePath,
            args: {'destination': image.destination},
            sourceSpan: image.span,
          ),
        );
      }
      final destination = image.destination.trim();
      if (hasUriScheme(destination)) {
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
            filePath: filePath,
            args: {'destination': destination},
            sourceSpan: image.span,
          ),
        );
      }
    }
    return diagnostics;
  }

  Future<List<Diagnostic>> _validateLocalReferencesAsync({
    required String filePath,
    required String? workspaceRoot,
    required List<MarkdownHeading> headings,
    required List<MarkdownLink> links,
    required List<MarkdownImage> images,
  }) async {
    final diagnostics = <Diagnostic>[];
    final anchors = headings.map((item) => item.id).toSet();
    for (final link in links) {
      final destination = link.destination.trim();
      if (hasUriScheme(destination)) {
        continue;
      }
      final fragmentIndex = destination.indexOf('#');
      final targetPath = fragmentIndex == -1
          ? destination
          : destination.substring(0, fragmentIndex);
      final anchor = fragmentIndex == -1
          ? null
          : destination.substring(fragmentIndex + 1);
      final decodedAnchor = anchor == null
          ? null
          : _decodeLocalReferenceAnchor(anchor);
      final target = await _resolveLocalLinkTargetAsync(
        filePath: filePath,
        workspaceRoot: workspaceRoot,
        targetPath: targetPath,
      );
      if (targetPath.isNotEmpty && target.blocksTargetValidation) {
        diagnostics.add(
          Diagnostic(
            code: 'markdown.link.unresolved-target',
            severity: DiagnosticSeverity.warning,
            filePath: filePath,
            args: {'targetPath': targetPath},
            sourceSpan: link.span,
          ),
        );
        continue;
      }
      if (decodedAnchor == null || decodedAnchor.isEmpty) {
        continue;
      }
      if (targetPath.isEmpty) {
        if (!anchors.contains(decodedAnchor)) {
          diagnostics.add(
            Diagnostic(
              code: 'markdown.link.unresolved-anchor',
              severity: DiagnosticSeverity.warning,
              filePath: filePath,
              args: {'anchor': anchor},
              sourceSpan: link.span,
            ),
          );
        }
        continue;
      }
      if (!target.canValidateAnchors || target.path == null) {
        continue;
      }
      try {
        final targetSource = await File(target.path!).readAsString();
        final targetAnchors = parse(
          filePath: target.path!,
          source: targetSource,
          workspaceRoot: workspaceRoot,
          validateLocalReferences: false,
        ).anchors;
        if (!targetAnchors.contains(decodedAnchor)) {
          diagnostics.add(
            Diagnostic(
              code: 'markdown.link.unresolved-anchor',
              severity: DiagnosticSeverity.warning,
              filePath: filePath,
              args: {'anchor': anchor},
              sourceSpan: link.span,
            ),
          );
        }
      } on Object {
        diagnostics.add(
          Diagnostic(
            code: 'markdown.link.unresolved-target',
            severity: DiagnosticSeverity.warning,
            filePath: filePath,
            args: {'targetPath': targetPath},
            sourceSpan: link.span,
          ),
        );
      }
    }
    for (final image in images) {
      if (image.alt.trim().isEmpty) {
        diagnostics.add(
          Diagnostic(
            code: 'markdown.image.missing-alt',
            severity: DiagnosticSeverity.warning,
            filePath: filePath,
            args: {'destination': image.destination},
            sourceSpan: image.span,
          ),
        );
      }
      final destination = image.destination.trim();
      if (hasUriScheme(destination)) {
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
            filePath: filePath,
            args: {'destination': destination},
            sourceSpan: image.span,
          ),
        );
      }
    }
    return diagnostics;
  }

  _LocalLinkTarget _resolveLocalLinkTarget({
    required String filePath,
    required String? workspaceRoot,
    required String targetPath,
  }) {
    if (targetPath.isEmpty) {
      return const _LocalLinkTarget.currentDocument();
    }
    if (hasUriScheme(targetPath)) {
      return const _LocalLinkTarget.blocked();
    }
    final localTargetPath = _decodeLocalReferencePath(targetPath);
    final root = _canonicalWorkspaceRootSync(workspaceRoot);
    if (root == null) {
      return const _LocalLinkTarget.unvalidated();
    }
    final resolved = p.isAbsolute(localTargetPath)
        ? p.normalize(localTargetPath)
        : p.normalize(p.join(p.dirname(filePath), localTargetPath));
    final absoluteTarget = p.normalize(p.absolute(resolved));
    final canonicalTarget = _canonicalExistingPathSync(absoluteTarget);
    if (canonicalTarget == null || !_isWithinDirectory(root, canonicalTarget)) {
      return const _LocalLinkTarget.blocked();
    }
    FileSystemEntityType type;
    try {
      type = FileSystemEntity.typeSync(canonicalTarget, followLinks: false);
    } on Object {
      return const _LocalLinkTarget.blocked();
    }
    if (type != FileSystemEntityType.file) {
      return const _LocalLinkTarget.blocked();
    }
    if (!isMarkdownPath(canonicalTarget)) {
      return _LocalLinkTarget.found(
        path: canonicalTarget,
        canValidateAnchors: false,
      );
    }
    FileStat stat;
    try {
      stat = File(canonicalTarget).statSync();
    } on Object {
      return const _LocalLinkTarget.blocked();
    }
    return _LocalLinkTarget.found(
      path: canonicalTarget,
      canValidateAnchors: stat.size <= _maxLocalReferenceTargetBytes,
    );
  }

  Future<_LocalLinkTarget> _resolveLocalLinkTargetAsync({
    required String filePath,
    required String? workspaceRoot,
    required String targetPath,
  }) async {
    if (targetPath.isEmpty) {
      return const _LocalLinkTarget.currentDocument();
    }
    if (hasUriScheme(targetPath)) {
      return const _LocalLinkTarget.blocked();
    }
    final localTargetPath = _decodeLocalReferencePath(targetPath);
    final root = await _canonicalWorkspaceRoot(workspaceRoot);
    if (root == null) {
      return const _LocalLinkTarget.unvalidated();
    }
    final resolved = p.isAbsolute(localTargetPath)
        ? p.normalize(localTargetPath)
        : p.normalize(p.join(p.dirname(filePath), localTargetPath));
    final absoluteTarget = p.normalize(p.absolute(resolved));
    final canonicalTarget = await _canonicalExistingPath(absoluteTarget);
    if (canonicalTarget == null || !_isWithinDirectory(root, canonicalTarget)) {
      return const _LocalLinkTarget.blocked();
    }
    FileSystemEntityType type;
    try {
      type = await FileSystemEntity.type(canonicalTarget, followLinks: false);
    } on Object {
      return const _LocalLinkTarget.blocked();
    }
    if (type != FileSystemEntityType.file) {
      return const _LocalLinkTarget.blocked();
    }
    if (!isMarkdownPath(canonicalTarget)) {
      return _LocalLinkTarget.found(
        path: canonicalTarget,
        canValidateAnchors: false,
      );
    }
    FileStat stat;
    try {
      stat = await File(canonicalTarget).stat();
    } on Object {
      return const _LocalLinkTarget.blocked();
    }
    return _LocalLinkTarget.found(
      path: canonicalTarget,
      canValidateAnchors: stat.size <= _maxLocalReferenceTargetBytes,
    );
  }

  String? _canonicalWorkspaceRootSync(String? workspaceRoot) {
    if (workspaceRoot == null || workspaceRoot.trim().isEmpty) {
      return null;
    }
    try {
      final directory = Directory(p.normalize(p.absolute(workspaceRoot)));
      if (!directory.existsSync()) {
        return null;
      }
      return p.normalize(directory.resolveSymbolicLinksSync());
    } on FileSystemException {
      return null;
    }
  }

  Future<String?> _canonicalWorkspaceRoot(String? workspaceRoot) async {
    if (workspaceRoot == null || workspaceRoot.trim().isEmpty) {
      return null;
    }
    try {
      final directory = Directory(p.normalize(p.absolute(workspaceRoot)));
      if (!await directory.exists()) {
        return null;
      }
      return p.normalize(await directory.resolveSymbolicLinks());
    } on FileSystemException {
      return null;
    }
  }

  String? _canonicalExistingPathSync(String path) {
    try {
      return p.normalize(File(path).resolveSymbolicLinksSync());
    } on FileSystemException {
      return null;
    }
  }

  Future<String?> _canonicalExistingPath(String path) async {
    try {
      return p.normalize(await File(path).resolveSymbolicLinks());
    } on FileSystemException {
      return null;
    }
  }

  bool _isWithinDirectory(String root, String candidate) {
    return p.equals(root, candidate) || p.isWithin(root, candidate);
  }
}

class _AstInlineReferences {
  const _AstInlineReferences({required this.links, required this.images});

  final List<MarkdownLink> links;
  final List<MarkdownImage> images;
}

class _CanonicalHeadingProjection {
  const _CanonicalHeadingProjection({
    required this.document,
    required this.headings,
    required this.diagnostics,
    required this.title,
  });

  final BusyDocument document;
  final List<MarkdownHeading> headings;
  final List<Diagnostic> diagnostics;
  final String? title;
}

String _decodeLocalReferencePath(String value) {
  try {
    return Uri.decodeComponent(value);
  } on FormatException {
    return value;
  }
}

String _decodeLocalReferenceAnchor(String value) {
  try {
    return Uri.decodeComponent(value);
  } on FormatException {
    return value;
  }
}

class _LocalLinkTarget {
  const _LocalLinkTarget._({
    required this.path,
    required this.blocksTargetValidation,
    required this.canValidateAnchors,
  });

  const _LocalLinkTarget.currentDocument()
    : this._(
        path: null,
        blocksTargetValidation: false,
        canValidateAnchors: true,
      );

  const _LocalLinkTarget.unvalidated()
    : this._(
        path: null,
        blocksTargetValidation: false,
        canValidateAnchors: false,
      );

  const _LocalLinkTarget.blocked()
    : this._(
        path: null,
        blocksTargetValidation: true,
        canValidateAnchors: false,
      );

  const _LocalLinkTarget.found({
    required String path,
    required bool canValidateAnchors,
  }) : this._(
         path: path,
         blocksTargetValidation: false,
         canValidateAnchors: canValidateAnchors,
       );

  final String? path;
  final bool blocksTargetValidation;
  final bool canValidateAnchors;
}

class _ScannedBlockSource {
  const _ScannedBlockSource({
    required this.rawSource,
    required this.span,
    required this.sourceOnly,
    required this.protectEdits,
  });

  factory _ScannedBlockSource.fromOffsets({
    required String filePath,
    required String source,
    required int startOffset,
    required int endOffset,
    bool sourceOnly = false,
    bool protectEdits = false,
    SourceLocationMapper? sourceLocationMapper,
  }) {
    final rawSource = source.substring(startOffset, endOffset).trimRight();
    final mapper = sourceLocationMapper ?? SourceLocationMapper(source);
    final rawEndOffset = startOffset + rawSource.length;
    final start = mapper.locationForOffset(startOffset);
    final end = mapper.locationForOffset(rawEndOffset);
    return _ScannedBlockSource(
      rawSource: rawSource,
      span: SourceSpan(
        filePath: filePath,
        startOffset: startOffset,
        endOffset: rawEndOffset,
        startLine: start.line,
        startColumn: start.column,
        endLine: end.line,
        endColumn: end.column,
      ),
      sourceOnly: sourceOnly,
      protectEdits: protectEdits,
    );
  }

  final String rawSource;
  final SourceSpan span;
  final bool sourceOnly;
  final bool protectEdits;
}

class _ScannedSourceLine {
  const _ScannedSourceLine({required this.rawLine, required this.offset});

  final String rawLine;
  final int offset;

  String get line => rawLine.endsWith('\n')
      ? rawLine.substring(0, rawLine.length - 1)
      : rawLine;

  String get trimmed => line.trim();

  int get endOffset => offset + rawLine.length;
}
