import 'package:html/parser.dart' as html;

import '../writerside/writerside_document.dart';
import '../writerside/writerside_document_parser.dart';
import '../writerside/writerside_schema.dart';
import 'spelling_projection.dart';
import 'spelling_text_patterns.dart';

final class WritersideXmlSpellingProjector {
  const WritersideXmlSpellingProjector({
    this.parser = const WritersideDocumentParser(),
  });

  final WritersideDocumentParser parser;

  SpellingProjectionResult project({
    required String filePath,
    required String source,
    required String languageId,
    required SpellingSnapshotIdentity snapshot,
  }) {
    final document = parser.parseXml(filePath: filePath, source: source);
    if (!document.isWellFormed) {
      return const SpellingProjectionResult(
        runs: [],
        complete: false,
        message: null,
      );
    }
    final builder = _XmlProjectionBuilder(
      filePath: filePath,
      source: source,
      languageId: languageId,
      snapshot: snapshot,
    );
    for (final node in document.nodes) {
      builder.visit(node, eligible: false);
    }
    builder.flush();
    return SpellingProjectionResult(
      runs: List.unmodifiable(
        builder.runs..sort(
          (left, right) => left.atoms.first.sourceStart.compareTo(
            right.atoms.first.sourceStart,
          ),
        ),
      ),
      complete: builder.complete,
      message: builder.complete
          ? null
          : 'Some XML prose could not be mapped exactly.',
    );
  }
}

final class _XmlProjectionBuilder {
  _XmlProjectionBuilder({
    required this.filePath,
    required this.source,
    required this.languageId,
    required this.snapshot,
  });

  final String filePath;
  final String source;
  final String languageId;
  final SpellingSnapshotIdentity snapshot;
  final List<SpellingProseRun> runs = [];
  var complete = true;
  var _sequence = 0;
  StringBuffer _text = StringBuffer();
  StringBuffer _tokenizationContext = StringBuffer();
  List<SpellingSourceAtom> _atoms = [];
  final List<_PendingXmlRun> _pendingRuns = [];
  int? _tokenizationContextStart;

  void visit(WritersideDocumentNode node, {required bool eligible}) {
    if (node is WritersideTextNode) {
      if (eligible) _appendTextNode(node);
      return;
    }
    if (node is WritersideRawNode) return;
    if (node is WritersideMarkdownBlockNode) {
      // XML topics are projected from physical XML nodes only. Reusable
      // Markdown snippets are parsed in their own physical document.
      return;
    }
    final element = node as WritersideElementNode;
    final kind = element.semanticKind;
    final elementEligible = _eligibleKinds.contains(kind);
    final inline = _inlineKinds.contains(kind);
    if (!inline) flush();
    _appendAttributes(element);
    if (kind == WritersideSemanticKind.lineBreak) {
      _emit(
        ' ',
        element.span.startOffset,
        element.span.endOffset,
        SpellingTransformationKind.lineBreak,
        SpellingSourceContext.xmlText,
        tokenizationLogical: '\n',
      );
      return;
    }
    if (elementEligible) {
      for (final child in element.children) {
        visit(child, eligible: true);
      }
    } else {
      // Excluded technical elements form hard barriers; their descendants do
      // not get joined to authored prose around them.
      if (inline) {
        _barrier();
      } else {
        flush();
      }
    }
    if (!inline) flush();
  }

  void _appendTextNode(WritersideTextNode node) {
    final raw = node.rawSource;
    if (raw.startsWith('<![CDATA[') && raw.endsWith(']]>')) {
      final contentStart = node.span.startOffset + '<![CDATA['.length;
      final contentEnd = node.span.endOffset - ']]>'.length;
      final content = source.substring(contentStart, contentEnd);
      _appendCdata(content, contentStart);
      if (content != node.text) complete = false;
      return;
    }
    _appendEncoded(
      raw: raw,
      sourceStart: node.span.startOffset,
      expected: node.text,
      context: SpellingSourceContext.xmlText,
    );
  }

  void _appendAttributes(WritersideElementNode element) {
    for (final name in _humanReadableAttributes) {
      final value = element.attributes[name];
      final span = element.attributeSpans[name];
      if (value == null || span == null || value.trim().isEmpty) continue;
      final quoteOffset = span.startOffset - 1;
      final quote = quoteOffset >= 0 ? source[quoteOffset] : '"';
      final attribute = _XmlProjectionBuilder(
        filePath: filePath,
        source: source,
        languageId: languageId,
        snapshot: snapshot,
      );
      attribute._appendEncoded(
        raw: source.substring(span.startOffset, span.endOffset),
        sourceStart: span.startOffset,
        expected: value,
        context: quote == "'"
            ? SpellingSourceContext.xmlSingleQuotedAttribute
            : SpellingSourceContext.xmlDoubleQuotedAttribute,
      );
      attribute.flush();
      complete = complete && attribute.complete;
      for (final run in attribute.runs) {
        runs.add(
          SpellingProseRun(
            id: 'writerside-xml:${_sequence++}',
            text: run.text,
            languageId: languageId,
            atoms: run.atoms,
            target: run.target,
            snapshot: snapshot,
            tokenizationContext: run.tokenizationContext,
            tokenizationContextStart: run.tokenizationContextStart,
          ),
        );
      }
    }
  }

  void _appendEncoded({
    required String raw,
    required int sourceStart,
    required String expected,
    required SpellingSourceContext context,
  }) {
    final decoded = html.parseFragment(raw).text ?? '';
    if (decoded != expected) {
      complete = false;
      return;
    }
    final units = <_EncodedUnit>[];
    final decodedText = StringBuffer();
    var cursor = 0;
    while (cursor < raw.length) {
      if (raw.codeUnitAt(cursor) == 0x26) {
        final match = _xmlEntity.matchAsPrefix(raw, cursor);
        if (match != null) {
          final encoded = match.group(0)!;
          final entityText = html.parseFragment(encoded).text ?? '';
          if (entityText != encoded && entityText.isNotEmpty) {
            final logicalStart = decodedText.length;
            decodedText.write(entityText);
            units.add(
              _EncodedUnit(
                logical: entityText,
                logicalStart: logicalStart,
                logicalEnd: decodedText.length,
                sourceStart: sourceStart + cursor,
                sourceEnd: sourceStart + match.end,
                transformation: SpellingTransformationKind.entity,
              ),
            );
            cursor = match.end;
            continue;
          }
        }
      }
      final rune = _codePointAt(raw, cursor);
      final width = rune > 0xffff ? 2 : 1;
      final logical = raw.substring(cursor, cursor + width);
      final logicalStart = decodedText.length;
      decodedText.write(logical);
      units.add(
        _EncodedUnit(
          logical: logical,
          logicalStart: logicalStart,
          logicalEnd: decodedText.length,
          sourceStart: sourceStart + cursor,
          sourceEnd: sourceStart + cursor + width,
          transformation: SpellingTransformationKind.identity,
        ),
      );
      cursor += width;
    }
    final excluded = _excludedTextIntervals(decodedText.toString());
    for (final unit in units) {
      final skip = excluded.any(
        (range) =>
            range.start < unit.logicalEnd && range.end > unit.logicalStart,
      );
      if (skip) {
        _barrier();
        continue;
      }
      _emit(
        unit.logical,
        unit.sourceStart,
        unit.sourceEnd,
        unit.transformation,
        context,
      );
    }
  }

  void _appendCdata(String content, int sourceStart) {
    var cursor = 0;
    for (final excluded in _excludedTextIntervals(content)) {
      if (excluded.start > cursor) {
        _emit(
          content.substring(cursor, excluded.start),
          sourceStart + cursor,
          sourceStart + excluded.start,
          SpellingTransformationKind.xmlCdata,
          SpellingSourceContext.xmlCdata,
        );
      }
      _barrier();
      cursor = excluded.end;
    }
    if (cursor < content.length) {
      _emit(
        content.substring(cursor),
        sourceStart + cursor,
        sourceStart + content.length,
        SpellingTransformationKind.xmlCdata,
        SpellingSourceContext.xmlCdata,
      );
    }
  }

  List<({int start, int end})> _excludedTextIntervals(String text) {
    final intervals = <({int start, int end})>[
      for (final match in _writersideVariable.allMatches(text))
        if (match.group(1) == null) (start: match.start, end: match.end),
      for (final match in spellingPlainAddress.allMatches(text))
        (start: match.start, end: match.end),
    ]..sort((left, right) => left.start.compareTo(right.start));
    final merged = <({int start, int end})>[];
    for (final interval in intervals) {
      if (merged.isNotEmpty && interval.start <= merged.last.end) {
        final previous = merged.removeLast();
        merged.add((
          start: previous.start,
          end: interval.end > previous.end ? interval.end : previous.end,
        ));
      } else {
        merged.add(interval);
      }
    }
    return merged;
  }

  void _emit(
    String logical,
    int sourceStart,
    int sourceEnd,
    SpellingTransformationKind transformation,
    SpellingSourceContext context, {
    String? tokenizationLogical,
  }) {
    if (logical.isEmpty) return;
    _tokenizationContextStart ??= _tokenizationContext.length;
    final logicalStart = _text.length;
    _text.write(logical);
    _tokenizationContext.write(tokenizationLogical ?? logical);
    _atoms.add(
      SpellingSourceAtom(
        logicalText: logical,
        logicalStart: logicalStart,
        logicalEnd: _text.length,
        sourceStart: sourceStart,
        sourceEnd: sourceEnd,
        transformation: transformation,
        context: context,
      ),
    );
  }

  void _flushRun() {
    if (_text.isNotEmpty && _text.toString().trim().isNotEmpty) {
      _pendingRuns.add(
        _PendingXmlRun(
          text: _text.toString(),
          atoms: List.unmodifiable(_atoms),
          tokenizationContextStart: _tokenizationContextStart!,
        ),
      );
    }
    _text = StringBuffer();
    _atoms = [];
    _tokenizationContextStart = null;
  }

  void _barrier() {
    _flushRun();
    if (_tokenizationContext.isNotEmpty &&
        !_tokenizationContext.toString().endsWith(' ')) {
      _tokenizationContext.write(' ');
    }
  }

  void flush() {
    _flushRun();
    final contextText = _tokenizationContext.toString();
    for (final pending in _pendingRuns) {
      final run = SpellingProseRun(
        id: 'writerside-xml:${_sequence++}',
        text: pending.text,
        languageId: languageId,
        atoms: pending.atoms,
        target: SpellingSourceTarget(filePath: filePath),
        snapshot: snapshot,
        tokenizationContext: contextText,
        tokenizationContextStart: pending.tokenizationContextStart,
      );
      if (run.hasValidMapping) {
        runs.add(run);
      } else {
        complete = false;
      }
    }
    _pendingRuns.clear();
    _tokenizationContext = StringBuffer();
  }
}

final class _PendingXmlRun {
  const _PendingXmlRun({
    required this.text,
    required this.atoms,
    required this.tokenizationContextStart,
  });

  final String text;
  final List<SpellingSourceAtom> atoms;
  final int tokenizationContextStart;
}

final class _EncodedUnit {
  const _EncodedUnit({
    required this.logical,
    required this.logicalStart,
    required this.logicalEnd,
    required this.sourceStart,
    required this.sourceEnd,
    required this.transformation,
  });

  final String logical;
  final int logicalStart;
  final int logicalEnd;
  final int sourceStart;
  final int sourceEnd;
  final SpellingTransformationKind transformation;
}

const _humanReadableAttributes = {
  'title',
  'alt',
  'summary',
  'tooltip',
  'switcher-label',
  'author',
};

const _inlineKinds = {
  WritersideSemanticKind.link,
  WritersideSemanticKind.strong,
  WritersideSemanticKind.emphasis,
  WritersideSemanticKind.control,
  WritersideSemanticKind.tooltip,
  WritersideSemanticKind.lineBreak,
};

const _eligibleKinds = {
  WritersideSemanticKind.topic,
  WritersideSemanticKind.paragraph,
  WritersideSemanticKind.chapter,
  WritersideSemanticKind.title,
  WritersideSemanticKind.list,
  WritersideSemanticKind.listItem,
  WritersideSemanticKind.table,
  WritersideSemanticKind.tableRow,
  WritersideSemanticKind.tableCell,
  WritersideSemanticKind.link,
  WritersideSemanticKind.control,
  WritersideSemanticKind.image,
  WritersideSemanticKind.procedure,
  WritersideSemanticKind.step,
  WritersideSemanticKind.note,
  WritersideSemanticKind.tip,
  WritersideSemanticKind.warning,
  WritersideSemanticKind.quote,
  WritersideSemanticKind.tabs,
  WritersideSemanticKind.tab,
  WritersideSemanticKind.definitionList,
  WritersideSemanticKind.definition,
  WritersideSemanticKind.tooltip,
  WritersideSemanticKind.strong,
  WritersideSemanticKind.emphasis,
  WritersideSemanticKind.snippet,
  WritersideSemanticKind.condition,
  WritersideSemanticKind.lineBreak,
  WritersideSemanticKind.container,
  WritersideSemanticKind.startingPage,
  WritersideSemanticKind.section,
  WritersideSemanticKind.card,
  WritersideSemanticKind.seealso,
};

final RegExp _xmlEntity = RegExp(
  r'&(?:#[0-9]{1,7}|#[xX][0-9A-Fa-f]{1,6}|[A-Za-z][A-Za-z0-9]{1,31});',
);
final RegExp _writersideVariable = RegExp(r'%(\\)?([A-Za-z_][A-Za-z0-9_.-]*)%');

int _codePointAt(String value, int offset) {
  final first = value.codeUnitAt(offset);
  if (first >= 0xd800 && first <= 0xdbff && offset + 1 < value.length) {
    final second = value.codeUnitAt(offset + 1);
    if (second >= 0xdc00 && second <= 0xdfff) {
      return 0x10000 + ((first - 0xd800) << 10) + second - 0xdc00;
    }
  }
  return first;
}
