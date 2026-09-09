import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:html/parser.dart' as html;
import 'package:path/path.dart' as p;
import '../markdown/busymark_document.dart';
import '../markdown/markdown_parser.dart';
import '../math/math_coordinator.dart';
import '../visualization/visualization_coordinator.dart';
import '../visualization/visualization_models.dart';
import '../writerside/writerside_project.dart';
import '../writerside/writerside_module_service.dart';
import '../writerside/writerside_parsers.dart';
import '../writerside/writerside_model.dart';
import 'html_export_assets.dart';
import 'html_export_links.dart';
import 'html_export_models.dart';
import 'html_export_publisher.dart';
import 'html_publication_plan.dart';
import 'html_document_writer.dart';
import 'html_rich_content.dart';
import 'html_export_styles.dart';

class HtmlExportService {
  const HtmlExportService({
    this.parser = const MarkdownParser(preserveHtmlSemantics: true),
    this.publisher = const HtmlExportPublisher(),
    this.limits = const HtmlExportLimits(),
    this.math,
    this.visualization,
    this.stylesheetLoader = _stylesheet,
  });
  final MarkdownParser parser;
  final HtmlExportPublisher publisher;
  final HtmlExportLimits limits;
  final MathCoordinator? math;
  final VisualizationCoordinator? visualization;
  final Future<String> Function() stylesheetLoader;
  static Future<String> _stylesheet() =>
      rootBundle.loadString('assets/export/html.css');

  Future<HtmlExportResult> exportMarkdown(
    MarkdownHtmlExportRequest request, {
    HtmlExportCancellationToken? cancellationToken,
    HtmlExportProgress? onProgress,
  }) async {
    final token = cancellationToken ?? HtmlExportCancellationToken();
    token.check();
    request.options.validateOrThrow();
    final customCss = await HtmlExportStyles.readCustomCss(request.options);
    token.check();
    if (utf8.encode(request.source).length > limits.sourceBytes) {
      throw const HtmlExportException(
        'The document exceeds the source byte limit.',
      );
    }
    final destination = p.normalize(p.absolute(request.destinationPath));
    if (!HtmlPublicationPlan.validFilename(p.basename(destination))) {
      throw const HtmlExportException('Choose a valid .html filename.');
    }
    final sourcePath = request.filePath.isEmpty
        ? p.join(
            request.workspaceRoot.isEmpty
                ? p.dirname(destination)
                : request.workspaceRoot,
            'untitled.md',
          )
        : request.filePath;
    final document =
        request.document ??
        (await parser.parseAsync(
          filePath: sourcePath,
          source: request.source,
          mode: request.mode,
          workspaceRoot: request.workspaceRoot.isEmpty
              ? null
              : request.workspaceRoot,
          validateLocalReferences: false,
        )).busyDocument;
    final warnings = <HtmlExportWarning>[];
    final page = HtmlPage(
      document: document,
      filename: p.basename(destination),
      title: document.title ?? p.basenameWithoutExtension(sourcePath),
    );
    prepareHtmlPage(page, warnings, limits);
    final plan = HtmlPublicationPlan(pages: [page], startPage: page);
    return _export(
      plan,
      destination,
      site: false,
      options: request.options,
      customCss: customCss,
      overwrite: request.overwrite,
      roots: [
        if (request.filePath.isNotEmpty) p.dirname(request.filePath),
        if (request.workspaceRoot.isNotEmpty) request.workspaceRoot,
      ],
      warnings: warnings,
      token: token,
      onProgress: onProgress,
    );
  }

  /// Capture all modules and source trees before preparing any output. Callers
  /// may pass a captured project when testing or exporting an already loaded snapshot.
  Future<HtmlExportResult> exportWriterside({
    required String projectRoot,
    required String moduleRoot,
    required String instanceId,
    required String destinationPath,
    bool overwrite = false,
    HtmlExportOptions options = const HtmlExportOptions(),
    WritersideProject? capturedProject,
    HtmlExportCancellationToken? cancellationToken,
    HtmlExportProgress? onProgress,
  }) async {
    final token = cancellationToken ?? HtmlExportCancellationToken();
    token.check();
    options.validateOrThrow();
    final customCss = await HtmlExportStyles.readCustomCss(options);
    token.check();
    final project =
        capturedProject ??
        await const WritersideProjectService(
          moduleService: WritersideModuleService(
            topicParser: WritersideTopicParser(
              markdownParser: MarkdownParser(preserveHtmlSemantics: true),
            ),
          ),
        ).load(projectRoot, preferredModuleRoot: moduleRoot);
    token.check();
    final module = project.modules
        .where((m) => p.equals(m.rootPath, moduleRoot))
        .firstOrNull;
    final instance = module?.instances
        .where((i) => i.id == instanceId && !i.isLibrary)
        .firstOrNull;
    if (module == null || instance == null) {
      throw const HtmlExportException(
        'Select a non-library Writerside instance.',
      );
    }
    final warnings = <HtmlExportWarning>[];
    final plan = HtmlPublicationPlan.writerside(
      module: module,
      instance: instance,
      modulesByOrigin: project.modulesByOrigin,
      warnings: warnings,
      limits: limits,
    );
    return _export(
      plan,
      p.normalize(p.absolute(destinationPath)),
      site: true,
      options: options,
      customCss: customCss,
      overwrite: overwrite,
      roots: project.modules.map((m) => m.rootPath).toList(),
      modules: project.modules,
      warnings: warnings,
      token: token,
      onProgress: onProgress,
    );
  }

  Future<HtmlExportResult> _export(
    HtmlPublicationPlan plan,
    String destination, {
    required bool site,
    required HtmlExportOptions options,
    required String customCss,
    required bool overwrite,
    required List<String> roots,
    List<WritersideModule> modules = const [],
    required List<HtmlExportWarning> warnings,
    required HtmlExportCancellationToken token,
    HtmlExportProgress? onProgress,
  }) async {
    final stage = await publisher.staging(destination);
    var retainStage = false;
    try {
      final canonicalRoots = <String>[];
      for (final root in roots.toSet()) {
        try {
          canonicalRoots.add(await Directory(root).resolveSymbolicLinks());
        } on FileSystemException {
          /* Missing roots cannot authorize assets. */
        }
      }
      final assetName = site
          ? 'assets'
          : '${p.basenameWithoutExtension(destination)}.assets';
      final assets = HtmlExportAssets(
        directory: Directory(p.join(stage.path, assetName)),
        urlDirectory: assetName,
        packaging: options.packaging,
        allowedRoots: canonicalRoots,
        token: token,
        warnings: warnings,
        limits: limits,
      );
      final links = HtmlExportLinks(
        plan: plan,
        assets: assets,
        warnings: warnings,
        modules: modules,
      );
      // Snapshot all local media before the first potentially long render job.
      for (final page in plan.pages) {
        await _captureAssets(page, links, page.document.blocks, token);
      }
      final css = await stylesheetLoader();
      token.check();
      final rich = HtmlRichContent(
        assets: assets,
        token: token,
        warnings: warnings,
        exportId: p.basename(stage.path),
        options: options,
        math: math,
        visualization: visualization,
        limits: limits,
      );
      Future<void> captureGraphics(
        HtmlPage page,
        List<BusyBlock> blocks,
      ) async {
        for (final block in blocks) {
          if (block.kind == BusyBlockKind.codeBlock &&
              VisualizationDescriptor.maybeForFenceLanguage(
                    block.attributes['language'],
                  ) !=
                  null) {
            final source = links.source(page, block.attributes);
            final roots = links.roots(page, block.attributes);
            await rich.captureDiagram(
              block,
              source,
              roots.isEmpty
                  ? (canonicalRoots.isEmpty
                        ? p.dirname(source)
                        : canonicalRoots.last)
                  : roots.last,
              '${page.filename}:${block.id}',
            );
          }
          await captureGraphics(page, block.children);
        }
      }

      for (final page in plan.pages) {
        await captureGraphics(page, page.document.blocks);
      }
      final outputs = <String, String>{};
      var outputBytes = 0;
      for (final (index, page) in plan.pages.indexed) {
        token.check();
        onProgress?.call(index, plan.pages.length);
        outputs[page.filename] = await HtmlDocumentWriter(
          page: page,
          plan: plan,
          links: links,
          rich: rich,
          stylesheet: css,
          options: options,
          customCss: customCss,
          warnings: warnings,
          limits: limits,
        ).write();
        outputBytes += utf8.encode(outputs[page.filename]!).length;
        if (outputBytes > limits.sourceBytes * 4) {
          throw const HtmlExportException(
            'Generated HTML exceeds the output byte limit.',
          );
        }
      }
      if (site) outputs['index.html'] = outputs[plan.startPage.filename]!;
      _validateOutputs(outputs, assets);
      token.check();
      if (site) {
        for (final entry in outputs.entries) {
          await File(
            p.join(stage.path, entry.key),
          ).writeAsString(entry.value, flush: true);
        }
        await publisher.publishSite(
          stage: stage,
          destination: destination,
          overwrite: overwrite,
          token: token,
        );
      } else {
        await publisher.publishDocument(
          stage: stage,
          destination: destination,
          html: outputs.values.single,
          assetsName: assetName,
          overwrite: overwrite,
          token: token,
        );
      }
      onProgress?.call(plan.pages.length, plan.pages.length);
      return HtmlExportResult(
        entryPointPath: site ? p.join(destination, 'index.html') : destination,
        assetsPath: !assets.hasExternalAssets
            ? null
            : p.join(site ? destination : p.dirname(destination), assetName),
        pageCount: plan.pages.length,
        warnings: List.unmodifiable(
          {
            for (final warning in warnings)
              '${warning.code}\u0000${warning.sourcePath}\u0000${warning.line}\u0000${warning.message}':
                  warning,
          }.values,
        ),
      );
    } on HtmlExportRecoveryException {
      retainStage = true;
      rethrow;
    } finally {
      if (!retainStage && await stage.exists()) {
        await stage.delete(recursive: true);
      }
    }
  }

  Future<void> _captureAssets(
    HtmlPage page,
    HtmlExportLinks links,
    List<BusyBlock> blocks,
    HtmlExportCancellationToken token,
  ) async {
    Future<void> capture(
      String? value,
      Map<String, String> attributes,
      int line, {
      bool download = false,
    }) async {
      if (value != null) {
        await links.assets.local(
          value,
          sourcePath: links.source(page, attributes),
          searchRoots: links.roots(page, attributes),
          line: line,
          download: download,
        );
      }
    }

    Future<void> inlines(
      List<BusyInline> values,
      Map<String, String> inherited,
      int line,
    ) async {
      for (final value in values) {
        final attrs = {...inherited, ...value.attributes};
        if (value.kind == BusyInlineKind.image) {
          await capture(value.destination, attrs, line);
        }
        if (value.kind == BusyInlineKind.link) {
          await links.resolve(value.destination, page, attrs, line: line);
        }
        await inlines(value.children, attrs, line);
      }
    }

    for (final block in blocks) {
      token.check();
      final line = block.sourceSpan?.startLine ?? 1;
      await inlines(block.inlines, block.attributes, line);
      if ({BusyBlockKind.video, BusyBlockKind.image}.contains(block.kind)) {
        await capture(block.attributes['src'], block.attributes, line);
      }
      final raw =
          block.attributes['html-footnotes'] ??
          (block.kind == BusyBlockKind.htmlBlock ? block.rawSource : null);
      if (raw != null) {
        for (final element
            in html.parseFragment(raw).querySelectorAll('img,a')) {
          final attrs = {
            ...block.attributes,
            ...element.attributes.map((k, v) => MapEntry(k.toString(), v)),
          };
          if (element.localName == 'img') {
            await capture(element.attributes['src'], attrs, line);
          } else {
            await links.resolve(
              element.attributes['href'],
              page,
              attrs,
              line: line,
            );
          }
        }
      }
      await _captureAssets(page, links, block.children, token);
    }
  }

  void _validateOutputs(Map<String, String> outputs, HtmlExportAssets assets) {
    final ids = {
      for (final entry in outputs.entries)
        entry.key: html
            .parse(entry.value)
            .querySelectorAll('[id]')
            .map((e) => e.id)
            .toSet(),
    };
    var bytes = 0;
    for (final entry in outputs.entries) {
      bytes += utf8.encode(entry.value).length;
      if (bytes > limits.sourceBytes * 4) {
        throw const HtmlExportException(
          'Generated HTML exceeds the output byte limit.',
        );
      }
      final doc = html.parse(entry.value);
      for (final element in doc.querySelectorAll('[href],[src]')) {
        final value = element.attributes['href'] ?? element.attributes['src']!;
        if (HtmlExportLinks.external(value) != null ||
            assets.ownsEmbeddedUrl(value)) {
          continue;
        }
        final uri = Uri.parse(value);
        final path = Uri.decodeComponent(uri.path);
        if (path.startsWith('${assets.urlDirectory}/')) {
          if (!assets.filenames.contains(p.posix.basename(path))) {
            throw const HtmlExportException(
              'An output resource was not packaged.',
            );
          }
        } else {
          final target = path.isEmpty ? entry.key : path;
          if (!ids.containsKey(target) ||
              (uri.fragment.isNotEmpty &&
                  !ids[target]!.contains(Uri.decodeComponent(uri.fragment)))) {
            throw HtmlExportException(
              'An output link does not resolve: $value.',
            );
          }
        }
      }
    }
  }
}
