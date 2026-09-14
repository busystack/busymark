import 'package:xml/xml.dart';

import '../core/busymark_exception.dart';
import '../markdown/busymark_document.dart';
import 'writerside_document.dart';
import 'writerside_document_parser.dart';
import 'writerside_model.dart';
import 'writerside_toc_navigation.dart';
import 'writerside_topic_creator.dart';

class WritersideTitleEdit {
  const WritersideTitleEdit({this.title, this.instanceTitle, this.tocTitle});

  /// Null leaves the source untouched; blank override values remove overrides.
  final String? title;
  final String? instanceTitle;
  final String? tocTitle;
}

class WritersideTitleEditResult {
  const WritersideTitleEditResult({
    required this.topicSource,
    required this.treeSource,
  });
  final String topicSource;
  final String treeSource;
}

/// Prepares source-range edits. Publication belongs to the workspace's guarded
/// multi-file transaction, so a dialog can never publish half a title change.
class WritersideTitleEditor {
  const WritersideTitleEditor();

  WritersideTitleEditResult prepare({
    required WritersideTopic topic,
    required String instanceId,
    required String treePath,
    required String treeSource,
    required List<int> tocPath,
    required WritersideTocNodeIdentity tocIdentity,
    required WritersideTitleEdit edit,
  }) {
    final document = topic.document;
    if (!document.isWellFormed) {
      throw const BusyMarkException('writerside.toc.path-invalid');
    }
    if (writersideTocSourceSpan(
          filePath: treePath,
          source: treeSource,
          path: tocPath,
          identity: tocIdentity,
        ) ==
        null) {
      throw const BusyMarkException('writerside.toc.tree-changed');
    }
    final source = document.source;
    final changes = <({int start, int end, String text})>[];
    final title = edit.title;
    if (title != null) {
      if (title.trim().isEmpty ||
          title.contains('\n') ||
          title.contains('\r')) {
        throw const BusyMarkException('writerside.toc.path-invalid');
      }
      if (topic.format == WritersideTopicFormat.xml) {
        final root = document.rootElement!;
        final span = root.attributeSpans['title'];
        if (span != null) {
          changes.add((
            start: span.startOffset,
            end: span.endOffset,
            text: _attribute(title),
          ));
        } else {
          final offset =
              source.indexOf(root.qualifiedName, root.span.startOffset) +
              root.qualifiedName.length;
          changes.add((
            start: offset,
            end: offset,
            text: ' title="${_attribute(title)}"',
          ));
        }
      } else {
        // Front-matter titles are a BusyMark Markdown extension, not the
        // Writerside H1 representation edited by this action. Do not change an
        // H1 while leaving a higher-precedence authored title unchanged.
        if (document.nodes.whereType<WritersideMarkdownBlockNode>().any(
          (node) =>
              node.block.kind == BusyBlockKind.frontMatter &&
              node.block.attributes.containsKey('title'),
        )) {
          throw const BusyMarkException('writerside.toc.path-invalid');
        }
        final heading = document.nodes
            .whereType<WritersideMarkdownBlockNode>()
            .where(
              (node) =>
                  node.block.kind == BusyBlockKind.heading &&
                  node.block.attributes['level'] == '1',
            )
            .firstOrNull;
        if (heading == null) {
          throw const BusyMarkException('writerside.toc.path-invalid');
        }
        // Only the parsed top-level heading is replaced, never fenced text or
        // another heading with the same spelling. Preserve explicit attributes.
        final raw = source.substring(
          heading.span.startOffset,
          heading.span.endOffset,
        );
        final attributes = RegExp(
          r'\s+(\{[^\r\n]*\})\s*$',
        ).firstMatch(raw.trimRight())?.group(1);
        final ending = raw.endsWith('\r\n')
            ? '\r\n'
            : raw.endsWith('\n')
            ? '\n'
            : '';
        changes.add((
          start: heading.span.startOffset,
          end: heading.span.endOffset,
          text:
              '# ${_markdownText(title)}${attributes == null ? '' : ' $attributes'}$ending',
        ));
      }
    }
    if (edit.instanceTitle != null) {
      final scope = topic.format == WritersideTopicFormat.xml
          ? document.rootElement!.children
          : document.nodes;
      final overrides = scope
          .whereType<WritersideElementNode>()
          .where(
            (node) =>
                node.name == 'title' &&
                node.attributes['instance'] == instanceId,
          )
          .toList();
      if (overrides.length > 1) {
        throw const BusyMarkException('writerside.toc.path-invalid');
      }
      final value = edit.instanceTitle!;
      final replacement = value.trim().isEmpty
          ? ''
          : XmlElement(
              XmlName.parts('title'),
              [XmlAttribute(XmlName.parts('instance'), instanceId)],
              [XmlText(value)],
            ).toXmlString();
      if (overrides.isNotEmpty) {
        final node = overrides.single;
        changes.add((
          start: node.span.startOffset,
          end: node.span.endOffset,
          text: replacement,
        ));
      } else if (replacement.isNotEmpty) {
        final offset = topic.format == WritersideTopicFormat.xml
            ? _openingEnd(source, document.rootElement!.span.startOffset) + 1
            : document.nodes
                      .whereType<WritersideMarkdownBlockNode>()
                      .where(
                        (node) =>
                            node.block.kind == BusyBlockKind.heading &&
                            node.block.attributes['level'] == '1',
                      )
                      .firstOrNull
                      ?.span
                      .endOffset ??
                  0;
        final newline = source.contains('\r\n') ? '\r\n' : '\n';
        if (topic.format == WritersideTopicFormat.xml &&
            source[offset - 2] == '/') {
          changes.add((
            start: offset - 2,
            end: offset,
            text:
                '>$newline$replacement$newline</${document.rootElement!.qualifiedName}>',
          ));
        } else {
          changes.add((
            start: offset,
            end: offset,
            text: '$newline$replacement$newline',
          ));
        }
      }
    }
    changes.sort((a, b) => b.start.compareTo(a.start));
    var topicSource = source;
    for (final change in changes) {
      topicSource = topicSource.replaceRange(
        change.start,
        change.end,
        change.text,
      );
    }

    var resultTree = treeSource;
    if (edit.tocTitle != null) {
      final span = writersideTocSourceSpan(
        filePath: treePath,
        source: treeSource,
        path: tocPath,
        identity: tocIdentity,
      );
      if (span == null) {
        throw const BusyMarkException('writerside.toc.tree-changed');
      }
      final fragment = treeSource.substring(span.startOffset, span.endOffset);
      final parsed = const WritersideDocumentParser().parseXml(
        filePath: treePath,
        source: fragment,
      );
      final root = parsed.rootElement!;
      final valueSpan = root.attributeSpans['toc-title'];
      final value = edit.tocTitle!;
      if (valueSpan != null) {
        if (value.trim().isEmpty) {
          final attributeStart = fragment.lastIndexOf(
            'toc-title',
            valueSpan.startOffset,
          );
          resultTree = treeSource.replaceRange(
            span.startOffset + attributeStart,
            span.startOffset + valueSpan.endOffset + 1,
            '',
          );
        } else {
          resultTree = treeSource.replaceRange(
            span.startOffset + valueSpan.startOffset,
            span.startOffset + valueSpan.endOffset,
            _attribute(value),
          );
        }
      } else if (value.trim().isNotEmpty) {
        final offset = span.startOffset + '<toc-element'.length;
        resultTree = treeSource.replaceRange(
          offset,
          offset,
          ' toc-title="${_attribute(value)}"',
        );
      }
    }
    return WritersideTitleEditResult(
      topicSource: topicSource,
      treeSource: resultTree,
    );
  }

  static String _attribute(String text) => text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
  static String _markdownText(String text) => text
      .replaceAll('&', '&amp;')
      .replaceAllMapped(
        RegExp(r'[\\`*_\[\]<>#{}]'),
        (match) => '\\${match[0]}',
      );

  static int _openingEnd(String source, int start) {
    int? quote;
    for (var i = start; i < source.length; i++) {
      final character = source.codeUnitAt(i);
      if (quote != null) {
        if (character == quote) quote = null;
      } else if (character == 34 || character == 39) {
        quote = character;
      } else if (character == 62) {
        return i;
      }
    }
    throw const BusyMarkException('writerside.toc.path-invalid');
  }
}
