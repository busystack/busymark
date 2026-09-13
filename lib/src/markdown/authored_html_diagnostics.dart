import 'package:html/dom.dart' as html;
import 'package:html/parser.dart' as html_parser;
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
      diagnostics.add(
        Diagnostic(
          code: 'markdown.raw-html.unsafe',
          severity: DiagnosticSeverity.warning,
          filePath: filePath,
          sourceSpan: SourceSpan.fromOffsets(
            filePath: filePath,
            source: source,
            startOffset: text.offsets[start],
            endOffset: text.offsets[end - 1] + 1,
          ),
        ),
      );
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
            if (span != null) {
              var start = span.start.offset;
              // The HTML tokenizer can exclude the opening '<' when recovering
              // from a malformed prefix such as '<<img ...>'.
              if (!span.text.startsWith('<') &&
                  start > 0 &&
                  text.text[start - 1] == '<') {
                start--;
              }
              final name = RegExp(
                r'</?\s*[A-Za-z][A-Za-z0-9_-]*\b',
              ).matchAsPrefix(text.text, start);
              warn(text, start, name?.end ?? span.end.offset);
            } else {
              warn(text, 0, text.text.length);
            }
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
      if (_html[node] case final html?) {
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
      final offsets = <int>[];
      for (final child in parser.lines) {
        while (parent.childLine < parent.lines.lines.length &&
            !parent.lines.lines[parent.childLine].content.endsWith(
              child.content,
            )) {
          parent.childLine++;
        }
        if (parent.childLine == parent.lines.lines.length) {
          throw StateError('Cannot map Markdown container line');
        }
        final index = parent.childLine++;
        offsets.add(
          parent.lines.offsets[index] +
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
          if (mapped.offsets.isNotEmpty) {
            while (cursor < raw.offsets.length &&
                raw.offsets[cursor] <= mapped.offsets.last) {
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
        // Extra cells are discarded by Markdown. Bind each retained row to its
        // own source line so a later cell cannot match a discarded occurrence.
        var line = start;
        for (final section in node.children!.whereType<md.Element>()) {
          for (final row in section.children!.whereType<md.Element>()) {
            block = lines.text(line, line + 1);
            cursor = 0;
            bind(row);
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
  final List<int> offsets;
  final Map<md.Line, int> indices;

  _LocatedText text(int start, int end) {
    final text = StringBuffer();
    final positions = <int>[];
    for (var i = start; i < end; i++) {
      if (i > start) {
        text.write('\n');
        positions.add(offsets[i - 1] + lines[i - 1].content.length);
      }
      text.write(lines[i].content);
      positions.addAll([
        for (var j = 0; j < lines[i].content.length; j++) offsets[i] + j,
      ]);
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
  final List<int> offsets;
  _LocatedText slice(int start, int end) =>
      _LocatedText(text.substring(start, end), offsets.sublist(start, end));

  _LocatedText bind(String content, int cursor) {
    // This is *unparsed* inline source within the block that produced it,
    // before entity encoding or code-span normalization. Markdown tables can
    // additionally remove backslashes before pipes; map those as deletions.
    final start = text.indexOf(content, cursor);
    if (start >= 0) return slice(start, start + content.length);
    final positions = <int>[];
    for (final unit in content.codeUnits) {
      while (cursor < text.length && text.codeUnitAt(cursor) != unit) {
        cursor++;
      }
      if (cursor == text.length) {
        throw StateError('Cannot map Markdown inline source');
      }
      positions.add(offsets[cursor++]);
    }
    return _LocatedText(content, positions);
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
    document._html[node] = document._inlineSource!.slice(
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
