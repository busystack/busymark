import 'package:html/dom.dart' as html;
import 'package:html/parser.dart' as html_parser;
// HtmlParser exposes its tokenizer, but does not re-export the token types.
// Inspect start tags before HTML tree construction can discard their attributes.
// ignore: implementation_imports
import 'package:html/src/token.dart' show StartTagToken;
import 'package:markdown/markdown.dart' as md;

import '../core/diagnostic.dart';
import '../core/source_span.dart';
import 'markdown_front_matter.dart';
import 'markdown_model.dart';
import 'math_syntax.dart';
import 'raw_html_policy.dart';

/// Parses authored HTML with locations captured before inline escaping and
/// normalization. Code nodes never enter the HTML diagnostic visitor.
List<Diagnostic> authoredHtmlDiagnostics({
  required String filePath,
  required String source,
  required MarkdownMode mode,
}) => _LocatedDocument(filePath, source, mode).diagnose();

class _LocatedDocument extends md.Document {
  _LocatedDocument(this.filePath, this.source, this.mode)
    : super(
        // Keep the standard syntax classes (and their type checks), adding
        // location tracking around their existing parse implementations.
        blockSyntaxes: const [
          _MathBlock(),
          _FencedCode(),
          _Header(),
          _SetextHeader(),
          _Table(),
          _UnorderedList(),
          _OrderedList(),
          _Footnote(),
          _Alert(),
          _Empty(),
          _HtmlBlock(),
          _Code(),
          _Blockquote(),
          _Rule(),
          _LinkDefinition(),
          _Paragraph(),
        ],
        inlineSyntaxes: [
          BusyDollarMathSyntax(),
          if (mode == MarkdownMode.writersideMarkdown)
            BusyWritersideMathSyntax(),
          _InlineHtml(),
          _Link(),
          _Image(),
          _Autolink(),
          ...md.ExtensionSet.gitHubWeb.inlineSyntaxes.where(
            (syntax) => syntax is! md.InlineHtmlSyntax,
          ),
        ],
        extensionSet: md.ExtensionSet.none,
        withDefaultBlockSyntaxes: false,
      );

  final String filePath;
  final String source;
  final MarkdownMode mode;
  final _lineMaps = Map<md.BlockParser, _Lines>.identity();
  final _contexts = <_BlockContext>[];
  final _locations = Map<md.Node, _LocatedText>.identity();
  final _html = Map<md.Node, _LocatedText>.identity();
  final _inlineHtml = Map<md.Node, _LocatedText>.identity();
  final _urls = Map<md.Node, _LocatedText>.identity();
  _LocatedText? _inlineSource;

  List<Diagnostic> diagnose() {
    final start = frontMatterEndOffset(source);
    final lines = <md.Line>[];
    final offsets = <int>[];
    var offset = start;
    for (final match in RegExp(
      r'[^\r\n]*(?:\r\n|\r|\n|$)',
    ).allMatches(source.substring(start))) {
      final raw = match[0]!;
      lines.add(md.Line(raw.replaceFirst(RegExp(r'[\r\n]+$'), '')));
      offsets.add(offset);
      offset += raw.length;
    }
    final parser = md.BlockParser(lines, this);
    _lineMaps[parser] = _Lines(lines, offsets);
    final nodes = parser.parseLines();
    final diagnostics = <Diagnostic>[];
    final inlineNodes = Map<md.Node, List<md.Node>>.identity();
    void prepareInlines(md.Node node) {
      if (node is md.UnparsedContent) {
        final mapped = _locations[node];
        if (mapped == null) return;
        _inlineSource = mapped;
        try {
          inlineNodes[node] = parseInline(mapped.text);
        } finally {
          _inlineSource = null;
        }
      } else if (node is md.Element) {
        for (final child in node.children ?? const <md.Node>[]) {
          prepareInlines(child);
        }
      }
    }

    // Footnote usage is known only after all inline content has been parsed.
    // Match Document's omission of unused definitions from the rendered tree.
    for (final node in nodes) {
      prepareInlines(node);
    }

    void warn(_LocatedText text, int start, int end) {
      final offsets = text.offsets;
      final hasLocation =
          offsets != null && start >= 0 && end > start && end <= offsets.length;
      diagnostics.add(
        Diagnostic(
          code: 'markdown.raw-html.unsafe',
          severity: DiagnosticSeverity.warning,
          filePath: filePath,
          // Location mapping is auxiliary to validation. If a source transform
          // cannot be mapped, retain the warning on the file without inventing
          // a location or preventing the Markdown document from being parsed.
          sourceSpan: !hasLocation
              ? null
              : SourceSpan.fromOffsets(
                  filePath: filePath,
                  source: source,
                  startOffset: offsets[start],
                  endOffset: offsets[end - 1] + 1,
                ),
        ),
      );
    }

    void warnHtmlTag(_LocatedText text, int? start, int? end) {
      if (start == null || end == null) {
        warn(text, 0, text.text.length);
        return;
      }
      // HTML token spans can exclude '<' after a malformed prefix such as
      // '<<img ...>'. Recover that adjacent character within this construct.
      if (start > 0 && text.text[start] != '<' && text.text[start - 1] == '<') {
        start--;
      }
      final name = RegExp(
        r'</?\s*[A-Za-z][A-Za-z0-9_-]*\b',
      ).matchAsPrefix(text.text, start);
      warn(text, start, name?.end ?? end);
    }

    void inspectInlineHtml(_LocatedText text) {
      // Markdown already identified a single authored HTML construct. Tokenize
      // it without a div-context tree, which would drop tags such as tr and td.
      // This still uses HTML's attribute decoding and duplicate-name rules.
      final tokens = html_parser.HtmlParser(
        text.text,
        generateSpans: true,
      ).tokenizer;
      while (tokens.moveNext()) {
        final token = tokens.current;
        if (token is! StartTagToken) continue;
        final tag = token.name ?? '';
        if (mode == MarkdownMode.writersideMarkdown && tag == 'video') continue;
        if (isUnsafeHtmlTag(tag) ||
            (isSafeHtmlTag(tag) &&
                sanitizeHtmlAttributes(tag, token.data) == null)) {
          warnHtmlTag(text, token.span?.start.offset, token.span?.end.offset);
        }
      }
    }

    void inspectHtml(_LocatedText text) {
      if (text.text.isEmpty) return;
      final fragment = html_parser.parseFragment(
        text.text,
        generateSpans: true,
      );
      var nodes = 0;
      var exceededLimit = false;
      void inspect(html.Node node, int depth) {
        if (exceededLimit) return;
        if (depth > maxRawHtmlDepth || nodes++ >= maxRawHtmlNodes) {
          exceededLimit = true;
          warn(text, 0, text.text.length);
          return;
        }
        if (node is html.Element) {
          final tag = node.localName ?? '';
          if (mode == MarkdownMode.writersideMarkdown && tag == 'video') return;
          if (isUnsafeHtmlTag(tag) ||
              (isSafeHtmlTag(tag) &&
                  sanitizeHtmlAttributes(tag, node.attributes) == null)) {
            final span = node.sourceSpan;
            warnHtmlTag(text, span?.start.offset, span?.end.offset);
            // One diagnostic covers the removed element and its descendants.
            return;
          }
        }
        for (final child in node.nodes) {
          inspect(child, depth + 1);
        }
      }

      inspect(fragment, 0);
    }

    void visit(md.Node node) {
      if (_inlineHtml[node] case final inlineHtml?) {
        inspectInlineHtml(inlineHtml);
      } else if (_html[node] case final html?) {
        inspectHtml(html);
      } else if (node is md.UnparsedContent) {
        for (final child in inlineNodes[node] ?? const <md.Node>[]) {
          visit(child);
        }
      } else if (node is md.Element) {
        if (_urls[node] case final location?) {
          final url = node.attributes[node.tag == 'img' ? 'src' : 'href'];
          if (url != null &&
              RegExp(
                r'^(?:javascript|vbscript|data):',
                caseSensitive: false,
              ).hasMatch(url.trim())) {
            warn(location, 0, location.text.length);
          }
        }
        if (node.tag == 'pre' ||
            node.tag == 'code' ||
            node.tag == busyMarkMathInlineTag ||
            node.tag == busyMarkMathBlockTag) {
          return;
        }
        for (final child in node.children ?? const <md.Node>[]) {
          visit(child);
        }
      }
    }

    for (final node in nodes) {
      if (node is md.Element &&
          node.tag == 'li' &&
          footnoteReferences[node.footnoteLabel] == 0) {
        continue;
      }
      visit(node);
    }
    return diagnostics;
  }

  md.Node? track(
    md.BlockParser parser,
    md.Node? Function() parse, {
    required bool html,
  }) {
    final lines = _lineMaps.putIfAbsent(parser, () {
      // Containers strip only prefixes from their child lines. Bind each child
      // line in order within its parent, never against another source block.
      final parent = _contexts.last;
      final offsets = <int?>[];
      for (final child in parser.lines) {
        while (parent.childLine < parent.lines.lines.length &&
            !parent.lines.lines[parent.childLine].content.endsWith(
              child.content,
            )) {
          parent.childLine++;
        }
        if (parent.childLine == parent.lines.lines.length) {
          offsets.add(null);
          continue;
        }
        final index = parent.childLine++;
        final parentOffset = parent.lines.offsets[index];
        offsets.add(
          parentOffset == null
              ? null
              : parentOffset +
                    parent.lines.lines[index].content.length -
                    child.content.length,
        );
      }
      return _Lines(parser.lines, offsets);
    });
    final start = lines.indices[parser.linesToConsume.first]!;
    _contexts.add(_BlockContext(lines, start));
    md.Node? node;
    try {
      node = parse();
    } finally {
      _contexts.removeLast();
    }
    if (node == null) return null;
    final end = parser.isDone
        ? lines.lines.length
        : lines.indices[parser.current]!;
    _LocatedText? block;
    _LocatedText blockSource() => block ??= lines.text(start, end);
    if (html) {
      _html[node] = blockSource();
    } else {
      var cursor = 0;
      void bind(md.Node node) {
        if (_locations.containsKey(node)) return;
        if (node is md.UnparsedContent) {
          final raw = blockSource();
          final mapped = raw.bind(node.textContent, cursor);
          _locations[node] = mapped;
          final mappedOffsets = mapped.offsets;
          final rawOffsets = raw.offsets;
          if (mappedOffsets != null &&
              mappedOffsets.isNotEmpty &&
              rawOffsets != null) {
            while (cursor < rawOffsets.length &&
                rawOffsets[cursor] <= mappedOffsets.last) {
              cursor++;
            }
          }
        } else if (node is md.Element) {
          for (final child in node.children ?? const <md.Node>[]) {
            bind(child);
          }
        }
      }

      if (node is md.Element && node.tag == 'table') {
        // Table syntax removes escaped pipes before parsing inline content.
        // Bind by cell boundaries, including discarded and synthetic cells;
        // decoded text must never be searched for across neighboring cells.
        var line = start;
        for (final section in node.children!.whereType<md.Element>()) {
          for (final row in section.children!.whereType<md.Element>()) {
            final cells = lines.text(line, line + 1).tableCells();
            final elements = row.children!.whereType<md.Element>().toList();
            for (var i = 0; i < elements.length; i++) {
              for (final content
                  in elements[i].children!.whereType<md.UnparsedContent>()) {
                final cell = i < cells.length ? cells[i] : null;
                _locations[content] = cell?.text == content.textContent
                    ? cell!
                    : _LocatedText(content.textContent, null);
              }
            }
            line += line == start ? 2 : 1; // Skip the delimiter row.
          }
        }
      } else {
        bind(node);
      }
    }
    return node;
  }
}

class _Lines {
  _Lines(this.lines, this.offsets)
    : indices = Map.identity()
        ..addEntries([
          for (var i = 0; i < lines.length; i++) MapEntry(lines[i], i),
        ]);
  final List<md.Line> lines;
  final List<int?> offsets;
  final Map<md.Line, int> indices;

  _LocatedText text(int start, int end) {
    final text = StringBuffer();
    List<int>? positions = <int>[];
    for (var i = start; i < end; i++) {
      if (i > start) {
        text.write('\n');
        final previousOffset = offsets[i - 1];
        if (previousOffset == null) {
          positions = null;
        } else {
          positions?.add(previousOffset + lines[i - 1].content.length);
        }
      }
      text.write(lines[i].content);
      final offset = offsets[i];
      if (offset == null) {
        positions = null;
      } else {
        positions?.addAll([
          for (var j = 0; j < lines[i].content.length; j++) offset + j,
        ]);
      }
    }
    return _LocatedText(text.toString(), positions);
  }
}

class _BlockContext {
  _BlockContext(this.lines, this.childLine);
  final _Lines lines;
  int childLine;
}

class _LocatedText {
  _LocatedText(this.text, this.offsets);
  final String text;
  final List<int>? offsets;
  _LocatedText slice(int start, int end) =>
      _LocatedText(text.substring(start, end), offsets?.sublist(start, end));

  List<_LocatedText> tableCells() {
    final cells = <_LocatedText>[];
    final sourceOffsets = offsets;
    var buffer = StringBuffer();
    var positions = <int>[];
    var index = 0;
    void skipWhitespace() {
      while (index < text.length &&
          (text.codeUnitAt(index) == 0x20 || text.codeUnitAt(index) == 0x09)) {
        index++;
      }
    }

    void append(int offset) {
      buffer.writeCharCode(text.codeUnitAt(offset));
      if (sourceOffsets != null) positions.add(sourceOffsets[offset]);
    }

    void finishCell() {
      final content = buffer.toString().trimRight();
      cells.add(
        _LocatedText(
          content,
          sourceOffsets == null ? null : positions.sublist(0, content.length),
        ),
      );
      buffer = StringBuffer();
      positions = <int>[];
    }

    skipWhitespace();
    if (index < text.length && text.codeUnitAt(index) == 0x7c) {
      index++;
      skipWhitespace();
    }
    while (index < text.length) {
      final unit = text.codeUnitAt(index);
      if (unit == 0x5c && index + 1 < text.length) {
        // Like Markdown's TableSyntax, consume backslash pairs before testing
        // delimiters. Only a backslash immediately escaping a pipe is removed.
        if (text.codeUnitAt(index + 1) != 0x7c) append(index);
        append(index + 1);
        index += 2;
      } else if (unit == 0x7c) {
        finishCell();
        index++;
        skipWhitespace();
        if (index == text.length) return cells;
      } else {
        append(index++);
      }
    }
    finishCell();
    return cells;
  }

  _LocatedText bind(String content, int cursor) {
    // This is *unparsed* inline source within the block that produced it,
    // before entity encoding or code-span normalization. Tables use their own
    // source boundaries and transformation map above.
    final start = text.indexOf(content, cursor);
    return start < 0
        ? _LocatedText(content, null)
        : slice(start, start + content.length);
  }
}

mixin _Track on md.BlockSyntax {
  @override
  md.Node? parse(md.BlockParser parser) =>
      (parser.document as _LocatedDocument).track(
        parser,
        () => super.parse(parser),
        html: this is md.HtmlBlockSyntax,
      );
}

mixin _TrackNonNull on md.BlockSyntax {
  @override
  md.Node parse(md.BlockParser parser) =>
      (parser.document as _LocatedDocument).track(
        parser,
        () => super.parse(parser),
        html: this is md.HtmlBlockSyntax,
      )!;
}

class _MathBlock extends BusyDisplayMathSyntax with _TrackNonNull {
  const _MathBlock();
}

class _FencedCode extends md.FencedCodeBlockSyntax with _TrackNonNull {
  const _FencedCode();
}

class _Empty extends md.EmptyBlockSyntax with _Track {
  const _Empty();
}

class _Code extends md.CodeBlockSyntax with _TrackNonNull {
  const _Code();
}

class _Rule extends md.HorizontalRuleSyntax with _TrackNonNull {
  const _Rule();
}

class _LinkDefinition extends md.LinkReferenceDefinitionSyntax with _Track {
  const _LinkDefinition();
}

class _Header extends md.HeaderWithIdSyntax with _TrackNonNull {
  const _Header();
}

class _SetextHeader extends md.SetextHeaderWithIdSyntax with _TrackNonNull {
  const _SetextHeader();
}

class _Table extends md.TableSyntax with _Track {
  const _Table();
}

class _UnorderedList extends md.UnorderedListWithCheckboxSyntax
    with _TrackNonNull {
  const _UnorderedList();
}

class _OrderedList extends md.OrderedListWithCheckboxSyntax with _TrackNonNull {
  const _OrderedList();
}

class _Footnote extends md.FootnoteDefSyntax with _Track {
  const _Footnote();
}

class _Alert extends md.AlertBlockSyntax with _TrackNonNull {
  const _Alert();
}

class _Blockquote extends md.BlockquoteSyntax with _TrackNonNull {
  const _Blockquote();
}

class _HtmlBlock extends md.HtmlBlockSyntax with _TrackNonNull {
  const _HtmlBlock();
}

class _Paragraph extends md.ParagraphSyntax with _Track {
  const _Paragraph();
}

class _InlineHtml extends md.InlineHtmlSyntax {
  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final document = parser.document as _LocatedDocument;
    // An element wrapper keeps this authored node separate from encoded prose
    // when the Markdown parser combines adjacent text nodes.
    final node = md.Element.text('busymark-authored-html', match[0]!);
    document._inlineHtml[node] = document._inlineSource!.slice(
      match.start,
      match.end,
    );
    parser.addNode(node);
    return true;
  }
}

mixin _TrackLink on md.LinkSyntax {
  @override
  Iterable<md.Node>? close(
    md.InlineParser parser,
    md.SimpleDelimiter opener,
    md.Delimiter? closer, {
    String? tag,
    required List<md.Node> Function() getChildren,
  }) {
    final nodes = super
        .close(parser, opener, closer, tag: tag, getChildren: getChildren)
        ?.toList();
    final document = parser.document as _LocatedDocument;
    if (nodes != null) {
      final location = document._inlineSource!.slice(
        opener.endPos - 1,
        parser.pos + 1,
      );
      for (final node in nodes) {
        document._urls[node] = location;
      }
    }
    return nodes;
  }
}

class _Link extends md.LinkSyntax with _TrackLink {}

class _Image extends md.ImageSyntax with _TrackLink {}

class _Autolink extends md.AutolinkSyntax {
  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final document = parser.document as _LocatedDocument;
    final node = md.Element.text('a', match[1]!)
      ..attributes['href'] = match[1]!;
    document._urls[node] = document._inlineSource!.slice(
      match.start,
      match.end,
    );
    parser.addNode(node);
    return true;
  }
}
