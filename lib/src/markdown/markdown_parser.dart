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
    void addScannedHeading({
      required int level,
      required String rawText,
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
              startOffset: startOffset + rawText.length,
              endOffset: endOffset,
            ),
          ),
        );
      }
      final text = _stripTrailingAttributeBlock(rawText).trim();
      final baseId = explicitId ?? slugForHeading(text);
      final generated = explicitId == null;
      final id = generated ? _deduplicatedId(baseId, generatedIds) : baseId;
      final span = SourceSpan.fromOffsets(
        filePath: filePath,
        source: source,
        startOffset: startOffset,
        endOffset: endOffset,
      );
      headings.add(
        MarkdownHeading(
          level: level,
          text: text,
          id: id,
          generatedId: generated,
          span: span,
        ),
      );
      title ??= level == 1 ? text : null;
      if (ids.containsKey(id)) {
        diagnostics.add(
          Diagnostic(
            code: 'markdown.heading.duplicate-id',
            severity: DiagnosticSeverity.warning,
            filePath: filePath,
            args: {'id': id},
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
            filePath: filePath,
            sourceSpan: span,
          ),
        );
      }
    }

    var inFence = false;
    var fenceStart = 0;
    String? fenceLanguage;
    final fenceContent = StringBuffer();
    var offset = 0;
    String? previousSetextCandidateLine;
    int? previousSetextCandidateOffset;
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
        previousSetextCandidateLine = null;
        previousSetextCandidateOffset = null;
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
        addScannedHeading(
          level: heading.group(1)!.length,
          rawText: heading.group(2)!.trim(),
          attrText: heading.group(3),
          startOffset: offset,
          endOffset: offset + line.length,
        );
        previousSetextCandidateLine = null;
        previousSetextCandidateOffset = null;
      } else if (_setextUnderlineLevel(trimmed) case final level?
          when previousSetextCandidateLine != null &&
              previousSetextCandidateOffset != null) {
        addScannedHeading(
          level: level,
          rawText: previousSetextCandidateLine.trim(),
          attrText: null,
          startOffset: previousSetextCandidateOffset,
          endOffset: offset + line.length,
        );
        previousSetextCandidateLine = null;
        previousSetextCandidateOffset = null;
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

      if (_isSetextHeadingCandidate(trimmed)) {
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
    }

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
    final sourceChunks = document.source == null
        ? const <_ScannedBlockSource>[]
        : _scannedBlockSources(document.filePath, document.source!);
    final nonFrontMatterBlockCount = document.blocks
        .where((block) => block.kind != BusyBlockKind.frontMatter)
        .length;
    final canAssignSource = sourceChunks.length == nonFrontMatterBlockCount;
    var sourceIndex = 0;
    return document.copyWith(
      diagnostics: diagnostics,
      blocks: [
        for (final block in document.blocks)
          _blockWithScannedMetadata(
            block,
            headings,
            canAssignSource ? sourceChunks : const <_ScannedBlockSource>[],
            headingIndexRef: () => headingIndex++,
            sourceIndexRef: () => sourceIndex++,
          ),
      ],
    );
  }

  BusyBlock _blockWithScannedMetadata(
    BusyBlock block,
    List<MarkdownHeading> headings,
    List<_ScannedBlockSource> sourceChunks, {
    required int Function() headingIndexRef,
    required int Function() sourceIndexRef,
  }) {
    var updated = block;
    if (updated.kind == BusyBlockKind.heading) {
      final headingIndex = headingIndexRef();
      if (headingIndex < headings.length) {
        updated = _headingWithScannedMetadata(updated, headings[headingIndex]);
      }
    }
    if (updated.kind != BusyBlockKind.frontMatter && sourceChunks.isNotEmpty) {
      final sourceIndex = sourceIndexRef();
      if (sourceIndex < sourceChunks.length) {
        final chunk = sourceChunks[sourceIndex];
        updated = updated.copyWith(
          rawSource: chunk.rawSource,
          sourceSpan: chunk.span,
        );
      }
    }
    return updated;
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

  List<_ScannedBlockSource> _scannedBlockSources(
    String filePath,
    String source,
  ) {
    var scanOffset = _frontMatterEndOffset(source);
    final chunks = <_ScannedBlockSource>[];
    final lines = source.substring(scanOffset).split(RegExp('(?<=\n)'));
    final indexedLines = <_ScannedSourceLine>[];
    for (final rawLine in lines) {
      indexedLines.add(
        _ScannedSourceLine(rawLine: rawLine, offset: scanOffset),
      );
      scanOffset += rawLine.length;
    }

    void addChunk(int startIndex, int endIndex) {
      if (startIndex >= indexedLines.length || endIndex <= startIndex) {
        return;
      }
      chunks.add(
        _ScannedBlockSource.fromOffsets(
          filePath: filePath,
          source: source,
          startOffset: indexedLines[startIndex].offset,
          endOffset: indexedLines[endIndex - 1].endOffset,
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
      final fence = _fenceMarker(indexedLines[index].line);
      if (fence != null) {
        index += 1;
        while (index < indexedLines.length) {
          if (_isClosingFence(indexedLines[index].line, fence)) {
            index += 1;
            break;
          }
          index += 1;
        }
        addChunk(startIndex, index);
        continue;
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

      index += 1;
      while (index < indexedLines.length) {
        final line = indexedLines[index];
        if (line.trimmed.isEmpty ||
            _fenceMarker(line.line) != null ||
            _isAtxHeading(line.line) ||
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

  bool _isAtxHeading(String line) {
    return RegExp(r'^\s{0,3}#{1,6}\s+').hasMatch(line);
  }

  bool _isThematicBreak(String trimmedLine) {
    return RegExp(r'^([*\-_])(\s*\1){2,}\s*$').hasMatch(trimmedLine);
  }

  String? _fenceMarker(String line) {
    final match = RegExp(r'^\s*(`{3,}|~{3,})').firstMatch(line);
    return match?.group(1);
  }

  bool _isClosingFence(String line, String opener) {
    final marker = _fenceMarker(line);
    if (marker == null || marker.codeUnitAt(0) != opener.codeUnitAt(0)) {
      return false;
    }
    return marker.length >= opener.length;
  }

  int? _listItemIndent(String line) {
    final match = RegExp(r'^(\s*)([-+*]|\d+[.)])\s+').firstMatch(line);
    return match?.group(1)!.length;
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

  String _stripTrailingAttributeBlock(String value) {
    return value.replaceFirst(RegExp(r'\s*\{[^}]+\}\s*$'), '').trimRight();
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
    if (RegExp(r'^(#{1,6})\s+').hasMatch(trimmedLine)) {
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
            filePath: filePath,
            args: {'targetPath': targetPath},
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
            filePath: filePath,
            args: {'destination': destination},
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

class _ScannedBlockSource {
  const _ScannedBlockSource({required this.rawSource, required this.span});

  factory _ScannedBlockSource.fromOffsets({
    required String filePath,
    required String source,
    required int startOffset,
    required int endOffset,
  }) {
    final rawSource = source.substring(startOffset, endOffset).trimRight();
    return _ScannedBlockSource(
      rawSource: rawSource,
      span: SourceSpan.fromOffsets(
        filePath: filePath,
        source: source,
        startOffset: startOffset,
        endOffset: startOffset + rawSource.length,
      ),
    );
  }

  final String rawSource;
  final SourceSpan span;
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
