import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/uri_utils.dart';
import '../markdown/busymark_document.dart';
import '../markdown/markdown_model.dart';
import '../writerside/writerside_document_renderer.dart';
import '../writerside/writerside_document_resolver.dart';
import '../writerside/writerside_model.dart';
import '../writerside/writerside_module_service.dart';
import '../writerside/writerside_project.dart';
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
    this.documentResolver = const WritersideDocumentResolver(),
    this.documentRenderer = const WritersideDocumentRenderer(),
    this.maximumTopics = 2000,
    this.maximumCombinedSourceBytes = 64 * 1024 * 1024,
  });

  final WritersideModuleService moduleService;
  final MarkdownPdfExportService markdownExporter;
  final WritersideDocumentResolver documentResolver;
  final WritersideDocumentRenderer documentRenderer;
  final int maximumTopics;
  final int maximumCombinedSourceBytes;

  Future<WritersidePdfExportResult> export(
    WritersidePdfExportRequest request, {
    WritersidePdfCancellationToken? cancellationToken,
  }) async {
    final token = cancellationToken ?? WritersidePdfCancellationToken();
    token.throwIfCancelled();
    final moduleRoot = await _validatedModuleRoot(request.moduleRoot);
    WritersideModule module;
    Map<String, WritersideModule> modulesByOrigin;
    if (request.projectRoot case final requestedProjectRoot?) {
      final projectRoot = await _validatedProjectRoot(
        requestedProjectRoot,
        moduleRoot,
      );
      final project = await WritersideProjectService(
        moduleService: moduleService,
        scanOptions: moduleService.scanOptions,
      ).load(projectRoot, preferredModuleRoot: moduleRoot);
      final selectedModule = project.modules
          .where((candidate) => p.equals(candidate.rootPath, moduleRoot))
          .firstOrNull;
      if (selectedModule == null) {
        throw const WritersidePdfExportException(
          WritersidePdfFailureCode.invalidRequest,
          detail: 'The selected module is not part of the Writerside project.',
        );
      }
      module = selectedModule;
      modulesByOrigin = project.modulesByOrigin;
    } else {
      module = await moduleService.load(moduleRoot);
      modulesByOrigin = {
        if (module.config.moduleName case final name?) name: module,
      };
    }
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
    final document = await _composeInstanceDocument(
      module,
      instance,
      modulesByOrigin,
      token,
    );
    if (document.blocks.isEmpty) {
      throw const WritersidePdfExportException(
        WritersidePdfFailureCode.invalidRequest,
        detail: 'The selected instance contains no exportable topics.',
      );
    }
    final markdownToken = MarkdownPdfCancellationToken();
    token.attach(markdownToken.cancel);
    try {
      final result = await markdownExporter.export(
        MarkdownPdfExportRequest(
          source: '',
          filePath: p.join(moduleRoot, '.busymark-writerside-export.md'),
          workspaceRoot: moduleRoot,
          destinationPath: request.destinationPath,
          options: request.options,
          overwrite: request.overwrite,
          mode: MarkdownMode.writersideMarkdown,
          document: document,
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

  Future<String> _validatedProjectRoot(String value, String moduleRoot) async {
    final root = await _validatedModuleRoot(value);
    if (!p.equals(root, moduleRoot) && !p.isWithin(root, moduleRoot)) {
      throw const WritersidePdfExportException(
        WritersidePdfFailureCode.invalidRequest,
        detail: 'The Writerside project does not contain the selected module.',
      );
    }
    return root;
  }

  Future<BusyDocument> _composeInstanceDocument(
    WritersideModule module,
    WritersideInstance instance,
    Map<String, WritersideModule> modulesByOrigin,
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

    final output = <BusyBlock>[];
    var combinedSourceBytes = 0;
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
      combinedSourceBytes += source.length;
      if (combinedSourceBytes > maximumCombinedSourceBytes) {
        throw const WritersidePdfExportException(
          WritersidePdfFailureCode.invalidRequest,
          detail: 'The selected instance is too large to export safely.',
        );
      }
      final parsedTopic = topic.format == WritersideTopicFormat.xml
          ? moduleService.topicParser.parseXml(
              filePath: topic.filePath,
              source: source,
              topicsRoot: topic.topicRoot,
            )
          : moduleService.topicParser.parseMarkdown(
              filePath: topic.filePath,
              source: source,
              topicsRoot: topic.topicRoot,
            );
      final resolved = documentResolver.resolve(
        parsedTopic.document,
        WritersideResolveContext(
          module: module,
          topic: parsedTopic,
          instance: instance,
          modulesByOrigin: modulesByOrigin,
        ),
      );
      if (index > 0) {
        output.add(
          BusyBlock(
            id: 'writerside-topic-break-$index',
            kind: BusyBlockKind.thematicBreak,
            isGenerated: true,
          ),
        );
      }
      final rendered = documentRenderer.toBusyDocument(
        resolved.document,
        title:
            selection.title ??
            resolved.title ??
            _topicTitle(parsedTopic, instance.id),
        includeTitleHeading: true,
      );
      final assets = await _resolveBusyAssets(module, parsedTopic, rendered);
      output.addAll(assets.blocks);
    }
    return BusyDocument(
      filePath: p.join(module.rootPath, '.busymark-writerside-export'),
      mode: MarkdownMode.writersideMarkdown,
      title: instance.name,
      blocks: List.unmodifiable(output),
    );
  }

  String? _topicTitle(WritersideTopic topic, String instanceId) {
    return topic.titleOverrides
            .where((override) => override.instance == instanceId)
            .map((override) => override.title)
            .firstOrNull ??
        topic.title;
  }

  Future<BusyDocument> _resolveBusyAssets(
    WritersideModule module,
    WritersideTopic topic,
    BusyDocument document,
  ) async {
    Future<BusyInline> resolveInline(BusyInline inline) async {
      var destination = inline.destination;
      if (inline.kind == BusyInlineKind.image && destination != null) {
        destination =
            await _resolvedAssetUri(module, topic, destination) ?? destination;
      }
      return inline.copyWith(
        destination: destination,
        children: await Future.wait(inline.children.map(resolveInline)),
      );
    }

    Future<BusyBlock> resolveBlock(BusyBlock block) async {
      final attributes = {...block.attributes};
      for (final name in ['src', 'preview-src']) {
        final value = attributes[name];
        if (value == null || value.trim().isEmpty) {
          continue;
        }
        attributes[name] =
            await _resolvedAssetUri(module, topic, value) ?? value;
      }
      return block.copyWith(
        inlines: await Future.wait(block.inlines.map(resolveInline)),
        children: await Future.wait(block.children.map(resolveBlock)),
        attributes: attributes,
      );
    }

    return document.copyWith(
      blocks: await Future.wait(document.blocks.map(resolveBlock)),
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

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
