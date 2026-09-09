import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:html/parser.dart' as html;
import '../core/path_utils.dart';
import '../markdown/busymark_document.dart';
import '../writerside/writerside_model.dart';
import '../writerside/writerside_document_resolver.dart';
import '../writerside/writerside_document_renderer.dart';
import 'html_export_models.dart';

class HtmlPage {
  HtmlPage({
    required this.document,
    required this.filename,
    required this.title,
    this.module,
    this.topic,
    this.workInProgress = false,
  });
  BusyDocument document;
  final String filename, title;
  final WritersideModule? module;
  final WritersideTopic? topic;
  bool workInProgress;
  final Set<String> ids = {};
  final List<({String id, String title, int level})> outline = [];
  String get sourcePath => document.filePath;
}

class HtmlNavigationEntry {
  const HtmlNavigationEntry({
    required this.title,
    this.page,
    this.href,
    this.hidden = false,
    this.workInProgress = false,
    this.children = const [],
  });
  final String title;
  final HtmlPage? page;
  final String? href;
  final bool hidden, workInProgress;
  final List<HtmlNavigationEntry> children;
}

class HtmlPublicationPlan {
  HtmlPublicationPlan({
    required this.pages,
    required this.startPage,
    this.navigation = const [],
    this.title,
  });
  final List<HtmlPage> pages;
  final HtmlPage startPage;
  final List<HtmlNavigationEntry> navigation;
  final String? title;

  static HtmlPublicationPlan writerside({
    required WritersideModule module,
    required WritersideInstance instance,
    required Map<String, WritersideModule> modulesByOrigin,
    required List<HtmlExportWarning> warnings,
    HtmlExportLimits limits = const HtmlExportLimits(),
  }) {
    if (instance.isLibrary) {
      throw const HtmlExportException('Library instances cannot be exported.');
    }
    final byIdentity = <String, HtmlPage>{};
    final filenames = <String, HtmlPage>{};
    var bytes = 0;
    HtmlPage? add(String? reference, WritersideModule origin) {
      if (reference == null) return null;
      final topic = origin.topicByReference(reference);
      if (topic == null) {
        throw HtmlExportException(
          'Missing TOC topic: $reference (${origin.rootPath}).',
        );
      }
      final identity = '${origin.rootPath}\u0000${topic.filePath}';
      if (byIdentity[identity] case final existing?) return existing;
      if (byIdentity.length >= limits.topics) {
        throw const HtmlExportException(
          'The instance exceeds the topic limit.',
        );
      }
      bytes += utf8.encode(topic.document.source).length;
      if (bytes > limits.sourceBytes) {
        throw const HtmlExportException(
          'The instance exceeds the source byte limit.',
        );
      }
      final resolved = const WritersideDocumentResolver().resolve(
        topic.document,
        WritersideResolveContext(
          module: origin,
          topic: topic,
          instance: instance,
          modulesByOrigin: modulesByOrigin,
        ),
      );
      warnings.addAll(
        resolved.diagnostics.map(
          (d) => HtmlExportWarning(
            d.code,
            '${d.code}: ${d.args.values.join(', ')}',
            sourcePath: d.filePath,
            line: d.line ?? 1,
          ),
        ),
      );
      final title = resolved.title ?? topic.title ?? topic.id;
      final customName =
          resolved.document.elements
              .where((e) => e.name == 'web-file-name')
              .firstOrNull
              ?.plainText
              .trim() ??
          topic.webFileName;
      final filename =
          customName ??
          '${p.basenameWithoutExtension(topic.fileName).toLowerCase().replaceAll(RegExp(r'[^\p{L}\p{N}-]', unicode: true), '-')}.html';
      if (!validFilename(filename)) {
        throw HtmlExportException(
          'Invalid web filename "$filename" in ${topic.filePath}.',
        );
      }
      var document = const WritersideDocumentRenderer().toBusyDocument(
        resolved.document,
        title: title,
        includeTitleHeading: topic.format == WritersideTopicFormat.xml,
      );
      // Markdown already supplies its H1. Apply a resolved instance title there.
      if (topic.format == WritersideTopicFormat.markdown) {
        var replaced = false;
        document = document.copyWith(
          blocks: [
            for (final b in document.blocks)
              if (!replaced &&
                  b.kind == BusyBlockKind.heading &&
                  b.attributes['level'] == '1')
                (() {
                  replaced = true;
                  return b.plainText == title
                      ? b
                      : b.copyWith(
                          inlines: [
                            BusyInline(kind: BusyInlineKind.text, text: title),
                          ],
                        );
                })()
              else
                b,
          ],
        );
      }
      document = document.copyWith(
        frontMatter: {
          ...?topic.markdown?.busyDocument.frontMatter,
          ...document.frontMatter,
          ...{
            for (final key in ['lang', 'dir'])
              if (resolved.document.rootElement?.attributes[key]
                  case final value?)
                key: value,
          },
        },
      );
      final page = HtmlPage(
        document: document,
        filename: filename,
        title: title,
        module: origin,
        topic: topic,
      );
      final collision = filenames[filename.toLowerCase()];
      if (collision != null) {
        throw HtmlExportException(
          'Web filename collision "$filename": ${collision.sourcePath} and ${topic.filePath}.',
        );
      }
      filenames[filename.toLowerCase()] = page;
      byIdentity[identity] = page;
      return page;
    }

    final requestedStart = add(instance.startPage, module);
    HtmlNavigationEntry entry(TocNode node, WritersideModule inherited) {
      final origin = node.origin == null
          ? inherited
          : modulesByOrigin[node.origin];
      if (origin == null) {
        throw HtmlExportException('Unknown TOC module origin: ${node.origin}.');
      }
      // References to another instance remain explicit navigation links, without
      // implicitly publishing that instance.
      final page =
          node.referenceInstanceId != null &&
              node.referenceInstanceId != instance.id
          ? null
          : add(node.topicReference, origin);
      if (page != null && node.workInProgress) page.workInProgress = true;
      if (node.includeResolutionError != null) {
        throw HtmlExportException(
          'TOC include failed: ${node.includeResolutionError}.',
        );
      }
      return HtmlNavigationEntry(
        title: node.tocTitle ?? page?.title ?? node.href ?? node.id ?? '',
        page: page,
        href: node.href,
        hidden: node.hidden,
        workInProgress: node.workInProgress,
        children: node.children.map((child) => entry(child, origin)).toList(),
      );
    }

    final navigation = instance.navigationTocRoots
        .map((node) => entry(node, module))
        .toList();
    if (byIdentity.isEmpty) {
      throw const HtmlExportException('The instance has no topics to export.');
    }
    final start = requestedStart ?? byIdentity.values.first;
    final index = filenames['index.html'];
    if (index != null && index != start) {
      throw HtmlExportException(
        'index.html is reserved for the start page, but is declared by ${index.sourcePath}.',
      );
    }
    final plan = HtmlPublicationPlan(
      pages: byIdentity.values.toList(),
      startPage: start,
      navigation: navigation,
      title: instance.name,
    );
    for (final page in plan.pages) {
      prepareHtmlPage(page, warnings, limits);
    }
    return plan;
  }

  static bool validFilename(String name) =>
      name.isNotEmpty &&
      utf8.encode(name).length <= 240 &&
      name.toLowerCase().endsWith('.html') &&
      !name.startsWith('.') &&
      !RegExp(r'[/\\\x00-\x1f\x7f?#:%]').hasMatch(name) &&
      p.basename(name) == name;

  HtmlPage? pageForSource(String source) =>
      pages.where((page) => p.equals(page.sourcePath, source)).firstOrNull;
}

void prepareHtmlPage(
  HtmlPage page,
  List<HtmlExportWarning> warnings,
  HtmlExportLimits limits,
) {
  final explicit = <String>{};
  void collect(Iterable<BusyBlock> blocks, int depth) {
    if (depth > limits.depth) {
      throw const HtmlExportException(
        'Document nesting exceeds the export limit.',
      );
    }
    for (final b in blocks) {
      final id = b.attributes['id'];
      if (id != null && b.attributes['generatedId'] != 'true') {
        if (!explicit.add(id)) {
          warnings.add(
            HtmlExportWarning(
              'anchor.duplicate',
              'Duplicate explicit ID "$id".',
              sourcePath: page.sourcePath,
              line: b.sourceSpan?.startLine ?? 1,
            ),
          );
        }
      }
      collect(b.children, depth + 1);
    }
  }

  collect(page.document.blocks, 0);
  final used = <String>{};
  var occurrence = 0;
  BusyBlock block(BusyBlock b) {
    var attributes = {...b.attributes};
    var id = attributes['id'];
    if (b.kind == BusyBlockKind.heading &&
        (id == null || attributes['generatedId'] == 'true')) {
      final slug = slugForHeading(b.plainText);
      final base = slug.isEmpty ? 'section' : slug;
      id = base;
      for (
        var suffix = 1;
        used.contains(id) || explicit.contains(id);
        suffix++
      ) {
        id = '$base-$suffix';
      }
    }
    if (id != null) {
      if (id.isEmpty ||
          RegExp(r'\s|[\x00-\x1f]').hasMatch(id) ||
          !used.add(id)) {
        warnings.add(
          HtmlExportWarning(
            'anchor.ambiguous',
            'Invalid or repeated ID "$id"; its duplicate anchor was omitted.',
            sourcePath: page.sourcePath,
            line: b.sourceSpan?.startLine ?? 1,
          ),
        );
        attributes.remove('id');
      } else {
        attributes['id'] = id;
        page.ids.add(id);
        if (b.kind == BusyBlockKind.heading) {
          page.outline.add((
            id: id,
            title: b.plainText,
            level: int.tryParse(attributes['level'] ?? '') ?? 1,
          ));
        }
      }
    }
    // IDs for render jobs describe occurrences, since included blocks may share IDs.
    final key = 'html-${occurrence++}';
    return b.copyWith(
      id: key,
      attributes: attributes,
      children: b.children.map(block).toList(),
    );
  }

  page.document = page.document.copyWith(
    blocks: page.document.blocks.map(block).toList(),
  );
  void rawIds(Iterable<BusyBlock> blocks) {
    for (final b in blocks) {
      final source =
          b.attributes['html-footnotes'] ??
          (b.kind == BusyBlockKind.htmlBlock ? b.rawSource : null);
      if (source != null) {
        for (final element
            in html.parseFragment(source).querySelectorAll('[id]')) {
          final id = element.id;
          if (!page.ids.add(id)) {
            warnings.add(
              HtmlExportWarning(
                'anchor.duplicate',
                'Duplicate explicit ID "$id".',
                sourcePath: page.sourcePath,
              ),
            );
          }
        }
      }
      void inlineIds(Iterable<BusyInline> values) {
        for (final value in values) {
          if (value.attributes['id'] case final id?) page.ids.add(id);
          inlineIds(value.children);
        }
      }

      inlineIds(b.inlines);
      rawIds(b.children);
    }
  }

  rawIds(page.document.blocks);
  if (page.topic?.document.rootElement?.attributes['id'] case final id?) {
    page.ids.add(id);
  }
}
