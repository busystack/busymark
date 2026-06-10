import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/diagnostic.dart';
import '../core/path_utils.dart';
import '../markdown/markdown_model.dart';
import '../markdown/markdown_parser.dart';
import '../markdown/preview_export.dart';
import '../writerside/writerside_module_service.dart';
import '../writerside/writerside_model.dart';
import 'workspace_model.dart';

class WorkspaceService {
  const WorkspaceService({
    this.markdownParser = const MarkdownParser(),
    this.previewBuilder = const MarkdownPreviewBuilder(),
    this.writersideService = const WritersideModuleService(),
  });

  final MarkdownParser markdownParser;
  final MarkdownPreviewBuilder previewBuilder;
  final WritersideModuleService writersideService;

  Future<Workspace> openPath(String inputPath) async {
    final path = normalizePath(inputPath);
    final fileType = FileSystemEntity.typeSync(path);
    if (fileType == FileSystemEntityType.file) {
      return _openSingleMarkdown(path);
    }
    if (fileType != FileSystemEntityType.directory) {
      throw FileSystemException('Path does not exist', path);
    }
    if (File(p.join(path, 'writerside.cfg')).existsSync() ||
        File(p.join(path, 'project.ihp')).existsSync()) {
      return _openWriterside(path);
    }
    return _openMarkdownFolder(path);
  }

  Future<String> loadText(String path) => File(path).readAsString();

  Future<void> saveText(String path, String text) =>
      File(path).writeAsString(text);

  Future<Workspace> reparseActive(Workspace workspace, String source) async {
    final active = workspace.activeFilePath;
    if (active == null) {
      return workspace;
    }
    if (workspace.kind == WorkspaceKind.writersideModule) {
      return _openWriterside(workspace.rootPath, activeFilePath: active);
    }
    final markdown = markdownParser.parse(
      filePath: active,
      source: source,
      mode: MarkdownMode.commonMark,
      workspaceRoot: workspace.rootPath,
    );
    return workspace.copyWith(
      markdown: markdown,
      diagnostics: markdown.diagnostics,
    );
  }

  PreviewDocument? buildPreview(Workspace workspace, String source) {
    final active = workspace.activeFilePath;
    if (active == null) {
      return null;
    }
    if (workspace.kind == WorkspaceKind.writersideModule) {
      final module = workspace.writersideModule;
      if (module == null) {
        return null;
      }
      final topic = module.topics.firstWhere(
        (item) => item.filePath == active,
        orElse: () => module.topics.isEmpty
            ? throw StateError('No topics')
            : module.topics.first,
      );
      if (topic.format == WritersideTopicFormat.markdown) {
        final parsed = markdownParser.parse(
          filePath: active,
          source: source,
          mode: MarkdownMode.writersideMarkdown,
          workspaceRoot: p.join(module.rootPath, module.config.topicsDir),
        );
        return previewBuilder.build(parsed);
      }
      return PreviewDocument(
        title: topic.title ?? topic.fileName,
        modeLabel: 'Preview',
        compatibility: '',
        blocks: [
          for (final name in topic.semanticElementNames)
            if (_visibleSemanticElement(name))
              PreviewBlock(
                kind: _semanticKind(name),
                text: _semanticText(name, topic.title),
                attributes: {'element': name},
              ),
        ],
      );
    }
    final parsed = markdownParser.parse(
      filePath: active,
      source: source,
      mode: MarkdownMode.commonMark,
      workspaceRoot: workspace.rootPath,
    );
    return previewBuilder.build(parsed);
  }

  Future<Workspace> _openSingleMarkdown(String filePath) async {
    final source = await File(filePath).readAsString();
    final markdown = markdownParser.parse(filePath: filePath, source: source);
    return Workspace(
      id: filePath,
      rootPath: p.dirname(filePath),
      kind: WorkspaceKind.singleMarkdown,
      openedAt: DateTime.now(),
      activeFilePath: filePath,
      files: [await _documentFile(filePath, p.dirname(filePath))],
      diagnostics: markdown.diagnostics,
      markdown: markdown,
    );
  }

  Future<Workspace> _openMarkdownFolder(String rootPath) async {
    final entities = await listWorkspaceEntities(rootPath);
    final files = <DocumentFile>[];
    final diagnostics = <Diagnostic>[];
    ParsedMarkdownDocument? firstMarkdown;
    for (final entity in entities.whereType<File>()) {
      final document = await _documentFile(entity.path, rootPath);
      files.add(document);
      if (isMarkdownPath(entity.path)) {
        final parsed = markdownParser.parse(
          filePath: entity.path,
          source: await entity.readAsString(),
          workspaceRoot: rootPath,
        );
        diagnostics.addAll(parsed.diagnostics);
        firstMarkdown ??= parsed;
      }
    }
    return Workspace(
      id: rootPath,
      rootPath: rootPath,
      kind: WorkspaceKind.markdownFolder,
      openedAt: DateTime.now(),
      activeFilePath: firstMarkdown?.filePath,
      files: files,
      diagnostics: sortDiagnostics(diagnostics),
      markdown: firstMarkdown,
    );
  }

  Future<Workspace> _openWriterside(
    String rootPath, {
    String? activeFilePath,
  }) async {
    final module = await writersideService.load(rootPath);
    final entities = await listWorkspaceEntities(rootPath);
    final files = <DocumentFile>[];
    for (final entity in entities.whereType<File>()) {
      files.add(await _documentFile(entity.path, rootPath));
    }
    final firstTopic =
        activeFilePath ??
        _startTopicPath(module) ??
        (module.topics.isEmpty ? null : module.topics.first.filePath);
    return Workspace(
      id: rootPath,
      rootPath: rootPath,
      kind: WorkspaceKind.writersideModule,
      openedAt: DateTime.now(),
      activeFilePath: firstTopic,
      files: files,
      diagnostics: module.diagnostics,
      writersideModule: module,
      markdown: module.topics
          .where((topic) => topic.filePath == firstTopic)
          .map((topic) => topic.markdown)
          .whereType<ParsedMarkdownDocument>()
          .firstOrNull,
    );
  }

  String? _startTopicPath(WritersideModule module) {
    if (module.instances.isEmpty) {
      return null;
    }
    final startPage = module.instances.first.startPage;
    if (startPage == null) {
      return null;
    }
    return module.topicsByFileName[startPage]?.filePath;
  }

  Future<DocumentFile> _documentFile(String path, String rootPath) async {
    final stat = await File(path).stat();
    return DocumentFile(
      absolutePath: path,
      relativePath: normalizedRelative(rootPath, path),
      kind: _documentKind(path),
      size: stat.size,
      lastModified: stat.modified,
    );
  }

  DocumentKind _documentKind(String path) {
    final extension = p.extension(path).toLowerCase();
    if (extension == '.md' || extension == '.markdown') {
      return DocumentKind.markdown;
    }
    if (extension == '.topic') {
      return DocumentKind.writersideXmlTopic;
    }
    if (extension == '.tree') {
      return DocumentKind.tree;
    }
    if (extension == '.cfg' || p.basename(path) == 'writerside.cfg') {
      return DocumentKind.config;
    }
    if (p.basename(path) == 'v.list') {
      return DocumentKind.variables;
    }
    if (p.basename(path) == 'c.list') {
      return DocumentKind.categories;
    }
    if ({
      '.png',
      '.jpg',
      '.jpeg',
      '.gif',
      '.svg',
      '.webp',
    }.contains(extension)) {
      return DocumentKind.image;
    }
    return isTextDocumentationPath(path)
        ? DocumentKind.resource
        : DocumentKind.unknown;
  }

  bool _visibleSemanticElement(String name) {
    return {
      'topic',
      'chapter',
      'p',
      'procedure',
      'step',
      'note',
      'tip',
      'warning',
      'tabs',
      'tab',
      'code-block',
      'img',
      'a',
    }.contains(name);
  }

  PreviewBlockKind _semanticKind(String name) {
    return switch (name) {
      'chapter' => PreviewBlockKind.heading,
      'procedure' => PreviewBlockKind.procedure,
      'note' || 'tip' || 'warning' => PreviewBlockKind.admonition,
      'tabs' || 'tab' => PreviewBlockKind.tabs,
      'code-block' => PreviewBlockKind.code,
      'img' => PreviewBlockKind.image,
      _ => PreviewBlockKind.paragraph,
    };
  }

  String _semanticText(String name, String? title) {
    return switch (name) {
      'topic' => title ?? 'Topic',
      'chapter' => 'Chapter',
      'procedure' => 'Procedure',
      'step' => 'Step',
      'note' => 'Note',
      'tip' => 'Tip',
      'warning' => 'Warning',
      'tabs' => 'Tabs',
      'tab' => 'Tab',
      'code-block' => 'Code block',
      'img' => 'Image',
      'a' => 'Link',
      _ => name,
    };
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
