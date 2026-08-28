import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import '../core/uri_utils.dart';
import '../markdown/markdown_model.dart';
import '../writerside/writerside_model.dart';
import '../writerside/writerside_module_service.dart';
import 'markdown_pdf_export_service.dart';
import 'markdown_pdf_models.dart';
import 'writerside_pdf_models.dart';

/// Exports one Writerside instance with BusyMark's bundled PDF toolchain.
///
/// This service deliberately has no container-runtime dependency. Writerside
/// topics are selected through the resolved instance TOC, composed in that
/// order, and handed to the same offline Typst, MathJax, and diagram pipeline
/// used for ordinary Markdown documents.
class WritersidePdfExportService {
  const WritersidePdfExportService({
    this.moduleService = const WritersideModuleService(),
    this.markdownExporter = const MarkdownPdfExportService(),
    this.maximumTopics = 2000,
    this.maximumCombinedSourceBytes = 64 * 1024 * 1024,
  });

  final WritersideModuleService moduleService;
  final MarkdownPdfExportService markdownExporter;
  final int maximumTopics;
  final int maximumCombinedSourceBytes;

  Future<WritersidePdfExportResult> export(
    WritersidePdfExportRequest request, {
    WritersidePdfCancellationToken? cancellationToken,
  }) async {
    final token = cancellationToken ?? WritersidePdfCancellationToken();
    token.throwIfCancelled();
    final moduleRoot = await _validatedModuleRoot(request.moduleRoot);
    final module = await moduleService.load(moduleRoot);
    token.throwIfCancelled();
    final instance = module.instances
        .where(
          (candidate) =>
              candidate.id == request.instanceId && !candidate.isLibrary,
        )
        .firstOrNull;
    if (instance == null) {
      throw WritersidePdfExportException(
        WritersidePdfFailureCode.invalidRequest,
        detail: 'Unknown or non-exportable instance: ${request.instanceId}',
      );
    }
    final source = await _composeInstanceSource(module, instance, token);
    if (source.trim().isEmpty) {
      throw const WritersidePdfExportException(
        WritersidePdfFailureCode.invalidRequest,
        detail: 'The selected instance contains no exportable topics.',
      );
    }
    if (source.length > maximumCombinedSourceBytes) {
      throw const WritersidePdfExportException(
        WritersidePdfFailureCode.invalidRequest,
        detail: 'The selected instance is too large to export safely.',
      );
    }

    final markdownToken = MarkdownPdfCancellationToken();
    token.attach(markdownToken.cancel);
    try {
      final result = await markdownExporter.export(
        MarkdownPdfExportRequest(
          source: source,
          filePath: p.join(moduleRoot, '.busymark-writerside-export.md'),
          workspaceRoot: moduleRoot,
          destinationPath: request.destinationPath,
          options: request.options,
          overwrite: request.overwrite,
          mode: MarkdownMode.writersideMarkdown,
        ),
        cancellationToken: markdownToken,
      );
      return WritersidePdfExportResult(
        destinationPath: result.destinationPath,
        pageCount: result.pageCount,
        warnings: result.warnings,
      );
    } on MarkdownPdfExportException catch (error) {
      throw WritersidePdfExportException(
        _failureCode(error.code),
        detail: error.detail,
        cause: error,
      );
    } finally {
      token.detach();
    }
  }

  Future<String> _validatedModuleRoot(String value) async {
    final requested = p.normalize(p.absolute(value));
    try {
      final root = await Directory(requested).resolveSymbolicLinks();
      if (await FileSystemEntity.type(root, followLinks: false) !=
          FileSystemEntityType.directory) {
        throw const WritersidePdfExportException(
          WritersidePdfFailureCode.invalidRequest,
          detail: 'The Writerside module directory does not exist.',
        );
      }
      return p.normalize(root);
    } on WritersidePdfExportException {
      rethrow;
    } on FileSystemException catch (error) {
      throw WritersidePdfExportException(
        WritersidePdfFailureCode.invalidRequest,
        detail: error.message,
        cause: error,
      );
    }
  }

  Future<String> _composeInstanceSource(
    WritersideModule module,
    WritersideInstance instance,
    WritersidePdfCancellationToken token,
  ) async {
    final selected = <({WritersideTopic topic, String? title})>[];
    final seen = <String>{};

    void addReference(String? reference, String? title) {
      if (reference == null) {
        return;
      }
      final topic = module.topicByReference(reference);
      if (topic != null && seen.add(topic.filePath)) {
        selected.add((topic: topic, title: title));
      }
    }

    void addNode(TocNode node) {
      if (!node.hidden && !node.workInProgress) {
        addReference(node.topicReference, node.tocTitle);
      }
      for (final child in node.children) {
        addNode(child);
      }
    }

    addReference(instance.startPage, null);
    for (final root in instance.navigationTocRoots) {
      addNode(root);
    }
    if (selected.isEmpty) {
      for (final reference in instance.topicFileSet) {
        addReference(reference, null);
      }
    }
    if (selected.length > maximumTopics) {
      throw const WritersidePdfExportException(
        WritersidePdfFailureCode.invalidRequest,
        detail: 'The selected instance contains too many topics.',
      );
    }

    final variables = {
      for (final variable in module.variables) variable.name: variable.value,
    };
    final output = StringBuffer();
    for (var index = 0; index < selected.length; index++) {
      token.throwIfCancelled();
      final selection = selected[index];
      final topic = selection.topic;
      String source;
      try {
        source =
            topic.markdown?.source ?? await File(topic.filePath).readAsString();
      } on FileSystemException catch (error) {
        throw WritersidePdfExportException(
          WritersidePdfFailureCode.fileSystem,
          detail: error.message,
          cause: error,
        );
      }
      source = await _prepareTopicSource(
        module: module,
        topic: topic,
        source: source,
        variables: variables,
      );
      if (topic.format == WritersideTopicFormat.xml) {
        source = _xmlTopicToMarkdown(
          source,
          fallbackTitle: selection.title ?? _topicTitle(topic, instance.id),
        );
      } else if (selection.title case final title?
          when title.trim().isNotEmpty) {
        source = _replaceFirstHeading(source, title.trim());
      }
      if (index > 0) {
        output.write('\n\n---\n\n');
      }
      output.write(source.trim());
    }
    if (output.isNotEmpty) {
      output.write('\n');
    }
    return output.toString();
  }

  String? _topicTitle(WritersideTopic topic, String instanceId) {
    return topic.titleOverrides
            .where((override) => override.instance == instanceId)
            .map((override) => override.title)
            .firstOrNull ??
        topic.title;
  }

  Future<String> _prepareTopicSource({
    required WritersideModule module,
    required WritersideTopic topic,
    required String source,
    required Map<String, String> variables,
  }) async {
    final replacements = <_SourceReplacement>[];
    final occupied = <({int start, int end})>[];

    for (final image in topic.images) {
      final replacement = await _assetReplacement(
        module: module,
        topic: topic,
        source: source,
        start: image.span.startOffset,
        end: image.span.endOffset,
        destination: image.destination,
      );
      if (replacement != null) {
        replacements.add(replacement);
        occupied.add((start: replacement.start, end: replacement.end));
      }
    }
    for (final video in topic.videos) {
      final initialSegment = _safeSubstring(
        source,
        video.span.startOffset,
        video.span.endOffset,
      );
      if (initialSegment == null) {
        continue;
      }
      var segment = initialSegment;
      var changed = false;
      for (final destination in [video.previewSource, video.source]) {
        if (destination == null || destination.trim().isEmpty) {
          continue;
        }
        final resolved = await _resolvedAssetUri(module, topic, destination);
        if (resolved != null && segment.contains(destination)) {
          segment = segment.replaceFirst(destination, resolved);
          changed = true;
        }
      }
      if (changed) {
        replacements.add(
          _SourceReplacement(
            video.span.startOffset,
            video.span.endOffset,
            segment,
          ),
        );
        occupied.add((
          start: video.span.startOffset,
          end: video.span.endOffset,
        ));
      }
    }
    for (final token in topic.variables) {
      final value = variables[token.name];
      if (token.escaped || value == null) {
        continue;
      }
      final start = token.span.startOffset;
      final end = token.span.endOffset;
      if (start < 0 || end > source.length || start > end) {
        continue;
      }
      if (occupied.any((range) => start < range.end && end > range.start)) {
        continue;
      }
      replacements.add(_SourceReplacement(start, end, value));
    }
    replacements.sort((left, right) => right.start.compareTo(left.start));
    var result = source;
    var rightBoundary = source.length;
    for (final replacement in replacements) {
      if (replacement.end > rightBoundary ||
          replacement.start < 0 ||
          replacement.end > result.length) {
        continue;
      }
      result = result.replaceRange(
        replacement.start,
        replacement.end,
        replacement.value,
      );
      rightBoundary = replacement.start;
    }
    return result;
  }

  Future<_SourceReplacement?> _assetReplacement({
    required WritersideModule module,
    required WritersideTopic topic,
    required String source,
    required int start,
    required int end,
    required String destination,
  }) async {
    final segment = _safeSubstring(source, start, end);
    if (segment == null || destination.trim().isEmpty) {
      return null;
    }
    final resolved = await _resolvedAssetUri(module, topic, destination);
    if (resolved == null || !segment.contains(destination)) {
      return null;
    }
    return _SourceReplacement(
      start,
      end,
      segment.replaceFirst(destination, resolved),
    );
  }

  Future<String?> _resolvedAssetUri(
    WritersideModule module,
    WritersideTopic topic,
    String value,
  ) async {
    final destination = value.trim();
    final uri = parseSchemedUri(destination);
    if (uri != null) {
      return isRemoteResourceUriScheme(uri.scheme) ? null : destination;
    }
    final relative = destination.startsWith('/')
        ? destination.substring(1)
        : destination;
    final candidates = <String>[
      p.join(p.dirname(topic.filePath), relative),
      p.join(module.rootPath, relative),
      p.join(module.rootPath, module.effectiveImagesDir, relative),
    ];
    for (final candidate in candidates) {
      try {
        final canonical = p.normalize(
          await File(candidate).resolveSymbolicLinks(),
        );
        if ((p.equals(module.rootPath, canonical) ||
                p.isWithin(module.rootPath, canonical)) &&
            await FileSystemEntity.type(canonical, followLinks: false) ==
                FileSystemEntityType.file) {
          return Uri.file(canonical).toString();
        }
      } on FileSystemException {
        // Try the next Writerside-compatible asset root.
      }
    }
    return null;
  }

  String? _safeSubstring(String source, int start, int end) {
    if (start < 0 || end < start || end > source.length) {
      return null;
    }
    return source.substring(start, end);
  }

  String _replaceFirstHeading(String source, String title) {
    final match = RegExp(
      r'^ {0,3}#{1,6}[ \t]+.*$',
      multiLine: true,
    ).firstMatch(source);
    if (match == null) {
      return '# $title\n\n$source';
    }
    return source.replaceRange(match.start, match.end, '# $title');
  }

  String _xmlTopicToMarkdown(String source, {String? fallbackTitle}) {
    try {
      final document = XmlDocument.parse(source);
      final root = document.rootElement;
      final title = root.getAttribute('title')?.trim();
      final output = StringBuffer();
      if ((title ?? fallbackTitle)?.trim() case final effective?
          when effective.isNotEmpty) {
        output.writeln('# ${_plain(effective)}');
        output.writeln();
      }
      for (final child in root.children) {
        _writeXmlBlock(output, child, headingLevel: 2);
      }
      return output.toString();
    } on XmlException {
      return '```xml\n$source\n```';
    }
  }

  void _writeXmlBlock(
    StringBuffer output,
    XmlNode node, {
    required int headingLevel,
  }) {
    if (node is XmlText) {
      final text = node.value.trim();
      if (text.isNotEmpty) {
        output.writeln(text);
        output.writeln();
      }
      return;
    }
    if (node is! XmlElement) {
      return;
    }
    final name = node.name.local.toLowerCase();
    switch (name) {
      case 'title' || 'web-file-name':
        return;
      case 'p':
        final text = _xmlInlineChildren(node).trim();
        if (text.isNotEmpty) {
          output.writeln(text);
          output.writeln();
        }
      case 'chapter' || 'procedure' || 'tab' || 'def':
        final title =
            node.getAttribute('title')?.trim() ??
            (name == 'tab'
                ? 'Tab'
                : name == 'def'
                ? 'Definition'
                : '');
        if (title.isNotEmpty) {
          output.writeln('${'#' * headingLevel} ${_plain(title)}');
          output.writeln();
        }
        for (final child in node.children) {
          _writeXmlBlock(output, child, headingLevel: headingLevel + 1);
        }
      case 'step':
        final text = _xmlInlineChildren(node).trim();
        if (text.isNotEmpty) {
          output.writeln('1. $text');
          output.writeln();
        }
      case 'note' || 'tip' || 'warning' || 'quote':
        final style = name == 'quote' ? 'NOTE' : name.toUpperCase();
        final body = _xmlInlineChildren(node).trim();
        output.writeln('> [!$style]');
        for (final line in body.split('\n')) {
          output.writeln('> $line');
        }
        output.writeln();
      case 'code-block':
        final language = node.getAttribute('lang')?.trim() ?? '';
        output.writeln('~~~$language');
        output.writeln(node.innerText.replaceFirst(RegExp(r'^\n'), ''));
        output.writeln('~~~');
        output.writeln();
      case 'math':
        output.writeln(r'$$');
        output.writeln(node.innerText);
        output.writeln(r'$$');
        output.writeln();
      case 'img':
        final src = node.getAttribute('src') ?? '';
        final alt = node.getAttribute('alt') ?? '';
        output.writeln('![${_plain(alt)}]($src)');
        output.writeln();
      case 'video':
        output.writeln(node.toXmlString());
        output.writeln();
      case 'list':
        for (final item in node.childElements) {
          final text = _xmlInlineChildren(item).trim();
          if (text.isNotEmpty) {
            output.writeln('- $text');
          }
        }
        output.writeln();
      case 'include':
        final from = node.getAttribute('from') ?? '';
        if (from.isNotEmpty) {
          output.writeln('> Included content: `$from`');
          output.writeln();
        }
      default:
        for (final child in node.children) {
          _writeXmlBlock(output, child, headingLevel: headingLevel);
        }
    }
  }

  String _xmlInlineChildren(XmlElement element) {
    return element.children
        .map(_xmlInline)
        .join()
        .replaceAll(RegExp(r'[ \t]+'), ' ');
  }

  String _xmlInline(XmlNode node) {
    if (node is XmlText) {
      return node.value;
    }
    if (node is! XmlElement) {
      return '';
    }
    final body = node.children.map(_xmlInline).join();
    return switch (node.name.local.toLowerCase()) {
      'b' || 'strong' => '**$body**',
      'i' || 'em' => '*$body*',
      'code' => '`${body.replaceAll('`', r'\`')}`',
      'a' => '[${body.trim()}](${node.getAttribute('href') ?? ''})',
      'img' =>
        '![${_plain(node.getAttribute('alt') ?? '')}]'
            '(${node.getAttribute('src') ?? ''})',
      'math' => '\$${body.trim()}\$',
      'br' => '  \n',
      'include' => '',
      _ => body,
    };
  }

  String _plain(String value) => value
      .replaceAll('\\', r'\\')
      .replaceAll('[', r'\[')
      .replaceAll(']', r'\]');

  WritersidePdfFailureCode _failureCode(MarkdownPdfFailureCode code) {
    return switch (code) {
      MarkdownPdfFailureCode.compilerUnavailable =>
        WritersidePdfFailureCode.exporterUnavailable,
      MarkdownPdfFailureCode.compilerFailed =>
        WritersidePdfFailureCode.buildFailed,
      MarkdownPdfFailureCode.timedOut => WritersidePdfFailureCode.timedOut,
      MarkdownPdfFailureCode.cancelled => WritersidePdfFailureCode.cancelled,
      MarkdownPdfFailureCode.invalidOutput =>
        WritersidePdfFailureCode.invalidOutput,
      MarkdownPdfFailureCode.destinationExists =>
        WritersidePdfFailureCode.destinationExists,
      MarkdownPdfFailureCode.fileSystem => WritersidePdfFailureCode.fileSystem,
    };
  }
}

class _SourceReplacement {
  const _SourceReplacement(this.start, this.end, this.value);

  final int start;
  final int end;
  final String value;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
