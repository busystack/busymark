import 'dart:convert';
import 'dart:io';

import '../core/diagnostic.dart';
import '../markdown/busymark_document.dart';
import '../markdown/markdown_fence.dart';
import '../markdown/markdown_model.dart';
import '../markdown/markdown_parser.dart';
import 'ai_models.dart';

abstract final class AiPolicy {
  static const maxDocumentCharacters = 2 * 1024 * 1024;
  static const maxGeneratedOutputBytes = 512 * 1024;

  static Uri validateLocalOllamaEndpoint(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        !uri.hasScheme ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.userInfo.isNotEmpty ||
        uri.query.isNotEmpty ||
        uri.fragment.isNotEmpty ||
        (uri.path.isNotEmpty && uri.path != '/')) {
      throw const AiException(
        AiFailureCode.invalidConfiguration,
        'Enter an Ollama origin such as http://127.0.0.1:11434.',
      );
    }
    if (!_isLoopbackHost(uri.host)) {
      throw const AiException(
        AiFailureCode.invalidConfiguration,
        'Local AI permits loopback Ollama endpoints only.',
      );
    }
    return uri.replace(path: '/');
  }

  static void validateRequest(AiRequest request) {
    if (request.modelCandidates.isEmpty ||
        request.modelCandidates.any((model) => model.trim().isEmpty)) {
      throw const AiException(
        AiFailureCode.invalidConfiguration,
        'Choose an AI model in Settings.',
      );
    }
    if (!request.feature.spec.allowedScopes.contains(request.scope)) {
      throw const AiException(
        AiFailureCode.validation,
        'This AI action does not support the requested context.',
      );
    }
    if (request.input.trim().isEmpty &&
        request.feature == AiFeature.draftCommitMessage) {
      throw const AiException(
        AiFailureCode.validation,
        'Stage changes before drafting a commit message.',
      );
    }
    if (request.feature == AiFeature.editDocument &&
        (request.editTarget == null || request.editContext == null)) {
      throw const AiException(
        AiFailureCode.validation,
        'Choose both the AI change target and shared context.',
      );
    }
    if ((request.documentSource?.length ?? request.input.length) >
        maxDocumentCharacters) {
      throw const AiException(
        AiFailureCode.validation,
        'The document exceeds the AI safety limit.',
      );
    }
    if (request.maxInputTokens <= 0 ||
        request.maxTotalInputTokens < request.maxInputTokens ||
        request.maxOutputTokens <= 0 ||
        request.maxRetries < 0 ||
        request.deadline <= Duration.zero) {
      throw const AiException(
        AiFailureCode.invalidConfiguration,
        'The AI request limits are invalid.',
      );
    }
    if (request.estimatedPromptTokens > request.maxInputTokens) {
      throw AiException(
        AiFailureCode.validation,
        'The requested AI context exceeds the ${request.maxInputTokens}-token safety budget.',
      );
    }
    if (request.estimatedPromptTokens > request.maxTotalInputTokens) {
      throw AiException(
        AiFailureCode.validation,
        'The requested AI context exceeds the ${request.maxTotalInputTokens}-token total prompt budget.',
      );
    }
    final source = request.documentSource;
    final start = request.replacementStart;
    final end = request.replacementEnd;
    if ((source == null) != (start == null) ||
        (source == null) != (end == null) ||
        (source != null &&
            (start! < 0 || end! < start || end > source.length))) {
      throw const AiException(
        AiFailureCode.validation,
        'The AI edit range is invalid.',
      );
    }
  }

  static bool _isLoopbackHost(String host) {
    if (host.toLowerCase() == 'localhost') {
      return true;
    }
    return InternetAddress.tryParse(host)?.isLoopback ?? false;
  }
}

/// Rejects proposals that alter protected Markdown semantics.
///
/// The check is deliberately conservative: a valid prose edit may be rejected,
/// but a proposal is never accepted merely because it contains the same set of
/// URLs or identifiers in a different association. Validation runs against the
/// complete candidate document so a selection cannot hide surrounding syntax.
class AiMarkdownGuard {
  const AiMarkdownGuard({MarkdownParser parser = const MarkdownParser()})
    : _parser = parser;

  final MarkdownParser _parser;

  void validate(AiRequest request, String output) {
    final normalized = output.trim();
    if (normalized.isEmpty) {
      throw const AiException(
        AiFailureCode.validation,
        'The model returned an empty proposal.',
      );
    }
    if (utf8.encode(output).length > AiPolicy.maxGeneratedOutputBytes) {
      throw const AiException(
        AiFailureCode.responseTooLarge,
        'The AI proposal exceeds the output byte limit.',
      );
    }
    if (request.feature == AiFeature.draftCommitMessage) {
      _validateCommitMessage(normalized);
      return;
    }
    if (request.contentFormat != AiContentFormat.markdown) {
      return;
    }

    final before = request.documentSource ?? request.input;
    final after = request.candidateDocument(output) ?? output;
    final path = request.documentSource == null
        ? 'ai-proposal.md'
        : 'ai-candidate.md';
    final afterDocument = _parse(path, after);
    if (request.editTarget == AiEditTargetKind.insertAfterBlock) {
      return;
    }
    final beforeDocument = _parse(path, before);
    _requireSame(
      'Markdown block structure',
      _blockStructure(beforeDocument.busyDocument.blocks),
      _blockStructure(afterDocument.busyDocument.blocks),
    );
    _requireSame(
      'inline Markdown structure',
      _inlineStructure(beforeDocument.busyDocument.blocks),
      _inlineStructure(afterDocument.busyDocument.blocks),
    );
    _requireSame(
      'front matter',
      [if (beforeDocument.busyDocument.rawFrontMatter case final value?) value],
      [if (afterDocument.busyDocument.rawFrontMatter case final value?) value],
    );
    _requireSame(
      'link destination association',
      _destinations(beforeDocument),
      _destinations(afterDocument),
    );
    _requireSame(
      'reference-link identifier',
      _referenceIdentifiers(before),
      _referenceIdentifiers(after),
    );
    _requireSame(
      'footnote identifier',
      _footnoteIdentifiers(before),
      _footnoteIdentifiers(after),
    );
    _requireSame('autolink', _autolinks(before), _autolinks(after));
    _requireSame(
      'heading attribute',
      _headingAttributes(before),
      _headingAttributes(after),
    );
    _requireSame(
      'heading identifier',
      [for (final heading in beforeDocument.headings) heading.id],
      [for (final heading in afterDocument.headings) heading.id],
    );
    _requireSame(
      'Writerside variable',
      _variables(beforeDocument),
      _variables(afterDocument),
    );
    _requireSame(
      'raw HTML or Writerside markup',
      _rawMarkup(beforeDocument.busyDocument.blocks),
      _rawMarkup(afterDocument.busyDocument.blocks),
    );
    _requireSame(
      'table',
      _rawBlocks(beforeDocument.busyDocument.blocks, BusyBlockKind.table),
      _rawBlocks(afterDocument.busyDocument.blocks, BusyBlockKind.table),
    );

    _requireSame(
      'fenced code block',
      _fencedCodeBlocks(before),
      _fencedCodeBlocks(after),
    );
    _requireSame('inline code', _inlineCode(before), _inlineCode(after));
  }

  ParsedMarkdownDocument _parse(String path, String source) {
    final parsed = _parser.parse(
      filePath: path,
      source: source,
      mode: MarkdownMode.gfm,
      validateLocalReferences: false,
    );
    if (parsed.diagnostics.any(
      (diagnostic) => diagnostic.severity == DiagnosticSeverity.error,
    )) {
      throw const AiException(
        AiFailureCode.validation,
        'The proposal is not valid BusyMark Markdown.',
      );
    }
    return parsed;
  }

  void _validateCommitMessage(String value) {
    final lines = value.split('\n');
    if (lines.first.trim().isEmpty || lines.first.length > 72) {
      throw const AiException(
        AiFailureCode.validation,
        'The commit-message subject must contain 1–72 characters.',
      );
    }
    if (lines.length > 1 && lines[1].isNotEmpty) {
      throw const AiException(
        AiFailureCode.validation,
        'Separate the commit-message subject and body with a blank line.',
      );
    }
  }

  List<String> _blockStructure(List<BusyBlock> blocks) {
    final result = <String>[];
    void visit(BusyBlock block, int depth) {
      final semanticAttributes = <String, String>{};
      for (final key in const [
        'level',
        'language',
        'listDepth',
        'orderedStart',
        'checked',
      ]) {
        if (block.attributes[key] case final value?) {
          semanticAttributes[key] = value;
        }
      }
      result.add('$depth:${block.kind.name}:$semanticAttributes');
      for (final child in block.children) {
        visit(child, depth + 1);
      }
    }

    for (final block in blocks) {
      visit(block, 0);
    }
    return result;
  }

  List<String> _inlineStructure(List<BusyBlock> blocks) {
    final result = <String>[];
    void visitInline(BusyInline inline, String path) {
      if (inline.kind != BusyInlineKind.text &&
          inline.kind != BusyInlineKind.softBreak &&
          inline.kind != BusyInlineKind.hardBreak) {
        result.add('$path:${inline.kind.name}');
      }
      for (var index = 0; index < inline.children.length; index += 1) {
        visitInline(inline.children[index], '$path.$index');
      }
    }

    void visitBlock(BusyBlock block, String path) {
      for (var index = 0; index < block.inlines.length; index += 1) {
        visitInline(block.inlines[index], '$path.i$index');
      }
      for (var index = 0; index < block.children.length; index += 1) {
        visitBlock(block.children[index], '$path.b$index');
      }
    }

    for (var index = 0; index < blocks.length; index += 1) {
      visitBlock(blocks[index], 'b$index');
    }
    return result;
  }

  List<String> _destinations(ParsedMarkdownDocument document) => [
    for (final link in document.links) 'link:${link.destination}',
    for (final image in document.images) 'image:${image.destination}',
  ];

  List<String> _variables(ParsedMarkdownDocument document) => [
    for (final variable in document.variables)
      '${variable.escaped}:${variable.name}',
  ];

  List<String> _rawMarkup(List<BusyBlock> blocks) {
    final values = <String>[];
    void visitInline(BusyInline inline) {
      if (inline.kind == BusyInlineKind.html ||
          inline.kind == BusyInlineKind.writersideVariable) {
        values.add('${inline.kind.name}:${inline.text}');
      }
      inline.children.forEach(visitInline);
    }

    void visitBlock(BusyBlock block) {
      if (block.kind == BusyBlockKind.htmlBlock ||
          block.kind == BusyBlockKind.writersideRawXml ||
          block.kind == BusyBlockKind.writersideAdmonition ||
          block.kind == BusyBlockKind.writersideTabs ||
          block.kind == BusyBlockKind.writersideProcedure) {
        values.add('${block.kind.name}:${block.rawSource ?? ''}');
      }
      block.inlines.forEach(visitInline);
      block.children.forEach(visitBlock);
    }

    blocks.forEach(visitBlock);
    return values;
  }

  List<String> _rawBlocks(List<BusyBlock> blocks, BusyBlockKind kind) {
    final values = <String>[];
    void visit(BusyBlock block) {
      if (block.kind == kind) {
        values.add(block.rawSource ?? '');
      }
      block.children.forEach(visit);
    }

    blocks.forEach(visit);
    return values;
  }

  List<String> _referenceIdentifiers(String value) => [
    for (final match in RegExp(
      r'(?<!\!)\[[^\]\n]*\]\[([^\]\n]*)\]|^\s{0,3}\[([^\]\n]+)\]:\s*\S+',
      multiLine: true,
    ).allMatches(_withoutFencedCode(value)))
      _normalizedIdentifier(match.group(1) ?? match.group(2) ?? ''),
  ];

  List<String> _footnoteIdentifiers(String value) => [
    for (final match in RegExp(
      r'\[\^([^\]\n]+)\]',
    ).allMatches(_withoutFencedCode(value)))
      _normalizedIdentifier(match.group(1)!),
  ];

  List<String> _autolinks(String value) => [
    for (final match in RegExp(
      r'<(?:https?://[^<>\s]+|mailto:[^<>\s]+|[A-Za-z0-9.!#$%&\x27*+/=?^_`{|}~-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,})>',
    ).allMatches(_withoutFencedCode(value)))
      match.group(0)!,
  ];

  List<String> _headingAttributes(String value) => [
    for (final match in RegExp(
      r'^(?: {0,3}#{1,6}[^\n]*?|[^\n]+\n {0,3}(?:=+|-+))[ \t]*(\{[^}\n]+\})[ \t]*$',
      multiLine: true,
    ).allMatches(_withoutFencedCode(value)))
      match.group(1)!,
  ];

  List<String> _fencedCodeBlocks(String value) => [
    for (final span in _fencedCodeSpans(value))
      value.substring(span.start, span.end),
  ];

  List<String> _inlineCode(String value) {
    final source = _withoutFencedCode(value);
    final result = <String>[];
    var index = 0;
    while (index < source.length) {
      if (source.codeUnitAt(index) != 0x60) {
        index += 1;
        continue;
      }
      final start = index;
      while (index < source.length && source.codeUnitAt(index) == 0x60) {
        index += 1;
      }
      final length = index - start;
      final marker = '`' * length;
      final end = source.indexOf(marker, index);
      if (end < 0 || source.substring(index, end).contains('\n')) {
        continue;
      }
      result.add(source.substring(start, end + length));
      index = end + length;
    }
    return result;
  }

  String _withoutFencedCode(String value) {
    final buffer = StringBuffer();
    var cursor = 0;
    for (final span in _fencedCodeSpans(value)) {
      buffer.write(value.substring(cursor, span.start));
      buffer.write(
        '\n' * '\n'.allMatches(value.substring(span.start, span.end)).length,
      );
      cursor = span.end;
    }
    buffer.write(value.substring(cursor));
    return buffer.toString();
  }

  List<_AiFenceSpan> _fencedCodeSpans(String value) {
    final rawLines = value.split(RegExp('(?<=\n)'));
    final spans = <_AiFenceSpan>[];
    var lineIndex = 0;
    var offset = 0;
    while (lineIndex < rawLines.length) {
      final rawLine = rawLines[lineIndex];
      final line = rawLine.endsWith('\n')
          ? rawLine.substring(0, rawLine.length - 1)
          : rawLine;
      final fence = MarkdownFence.parse(line);
      if (fence == null) {
        offset += rawLine.length;
        lineIndex += 1;
        continue;
      }
      final start = offset;
      offset += rawLine.length;
      lineIndex += 1;
      while (lineIndex < rawLines.length) {
        final candidateRaw = rawLines[lineIndex];
        final candidate = candidateRaw.endsWith('\n')
            ? candidateRaw.substring(0, candidateRaw.length - 1)
            : candidateRaw;
        offset += candidateRaw.length;
        lineIndex += 1;
        if (fence.closes(candidate)) {
          break;
        }
      }
      spans.add(_AiFenceSpan(start, offset));
    }
    return spans;
  }

  String _normalizedIdentifier(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  void _requireSame(
    String protectedKind,
    List<String> before,
    List<String> after,
  ) {
    if (_listEquals(before, after)) {
      return;
    }
    throw AiException(
      AiFailureCode.validation,
      'The model changed protected $protectedKind content. The proposal was not applied.',
    );
  }

  bool _listEquals(List<String> first, List<String> second) {
    if (first.length != second.length) {
      return false;
    }
    for (var index = 0; index < first.length; index += 1) {
      if (first[index] != second[index]) {
        return false;
      }
    }
    return true;
  }
}

class _AiFenceSpan {
  const _AiFenceSpan(this.start, this.end);

  final int start;
  final int end;
}
