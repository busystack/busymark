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
    this.scanOptions = const WorkspaceScanOptions(),
  });

  final MarkdownParser markdownParser;
  final MarkdownPreviewBuilder previewBuilder;
  final WritersideModuleService writersideService;
  final WorkspaceScanOptions scanOptions;

  Workspace createUntitledMarkdown({String source = ''}) {
    const fileName = 'Untitled.md';
    final now = DateTime.now();
    final markdown = markdownParser.parse(filePath: fileName, source: source);
    return Workspace(
      id: 'untitled:${now.microsecondsSinceEpoch}',
      rootPath: '',
      kind: WorkspaceKind.untitledMarkdown,
      openedAt: now,
      files: const [],
      diagnostics: markdown.diagnostics,
      markdown: markdown,
    );
  }

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

  Future<DateTime> fileModifiedAt(String path) async {
    return (await File(path).stat()).modified;
  }

  Future<bool> fileChangedSince(String path, DateTime? knownModifiedAt) async {
    if (knownModifiedAt == null) {
      return false;
    }
    try {
      final current = await fileModifiedAt(path);
      return current.isAfter(knownModifiedAt);
    } on Object {
      return false;
    }
  }

  Future<DateTime> saveText(String path, String text) async {
    final file = File(path);
    await file.writeAsString(text);
    return (await file.stat()).modified;
  }

  Future<Workspace> reparseActive(Workspace workspace, String source) async {
    final active = workspace.activeFilePath ?? workspace.markdown?.filePath;
    if (active == null) {
      return workspace;
    }
    if (workspace.kind == WorkspaceKind.writersideModule) {
      final module = workspace.writersideModule;
      final topic = module?.topics
          .where((item) => item.filePath == active)
          .firstOrNull;
      if (topic?.format == WritersideTopicFormat.markdown) {
        final markdown = markdownParser.parse(
          filePath: active,
          source: source,
          mode: MarkdownMode.writersideMarkdown,
          workspaceRoot: p.join(module!.rootPath, module.config.topicsDir),
        );
        return workspace.copyWith(
          markdown: markdown,
          diagnostics: sortDiagnostics([
            ...module.diagnostics,
            ...markdown.diagnostics,
          ]),
        );
      }
      if (topic?.format == WritersideTopicFormat.xml) {
        final parsed = writersideService.topicParser.parseXml(
          filePath: active,
          source: source,
        );
        return workspace.copyWith(
          diagnostics: sortDiagnostics([
            ...module!.diagnostics,
            ...parsed.diagnostics,
          ]),
        );
      }
      return workspace.copyWith(diagnostics: module?.diagnostics);
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
    final active = workspace.activeFilePath ?? workspace.markdown?.filePath;
    if (active == null) {
      return null;
    }
    if (workspace.kind == WorkspaceKind.writersideModule) {
      final module = workspace.writersideModule;
      if (module == null) {
        return null;
      }
      final topic = module.topics
          .where((item) => item.filePath == active)
          .firstOrNull;
      if (topic == null) {
        return PreviewDocument(
          title: p.basename(active),
          modeLabel: 'Preview',
          compatibility: '',
          blocks: [PreviewBlock(kind: PreviewBlockKind.code, text: source)],
        );
      }
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
        blocks: _xmlPreviewBlocks(source, topic.title),
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
      activeFileModifiedAt: await fileModifiedAt(filePath),
      files: [await _documentFile(filePath, p.dirname(filePath))],
      diagnostics: markdown.diagnostics,
      markdown: markdown,
    );
  }

  Future<Workspace> _openMarkdownFolder(String rootPath) async {
    final scan = await scanWorkspaceEntities(rootPath, options: scanOptions);
    final entities = scan.entities;
    final files = <DocumentFile>[];
    final diagnostics = <Diagnostic>[...scan.diagnostics];
    ParsedMarkdownDocument? firstMarkdown;
    var parsedDocuments = 0;
    for (final entity in entities.whereType<File>()) {
      final document = await _safeDocumentFile(
        entity.path,
        rootPath,
        diagnostics,
      );
      if (document == null) {
        continue;
      }
      files.add(document);
      if (isMarkdownPath(entity.path)) {
        final parsed = await _parseMarkdownFileIfSafe(
          entity,
          rootPath,
          diagnostics,
          parsedDocuments,
        );
        if (parsed == null) {
          continue;
        }
        parsedDocuments++;
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
      activeFileModifiedAt: firstMarkdown == null
          ? null
          : await fileModifiedAt(firstMarkdown.filePath),
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
    final scan = await scanWorkspaceEntities(rootPath, options: scanOptions);
    final entities = scan.entities;
    final files = <DocumentFile>[];
    final diagnostics = <Diagnostic>[
      ...module.diagnostics,
      ...scan.diagnostics,
    ];
    for (final entity in entities.whereType<File>()) {
      final file = await _safeDocumentFile(entity.path, rootPath, diagnostics);
      if (file != null) {
        files.add(file);
      }
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
      activeFileModifiedAt: firstTopic == null
          ? null
          : await fileModifiedAt(firstTopic),
      files: files,
      diagnostics: sortDiagnostics(diagnostics),
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

  Future<DocumentFile?> _safeDocumentFile(
    String path,
    String rootPath,
    List<Diagnostic> diagnostics,
  ) async {
    try {
      return _documentFile(path, rootPath);
    } on Object catch (error) {
      diagnostics.add(
        Diagnostic(
          code: 'workspace.file.stat-failed',
          severity: DiagnosticSeverity.warning,
          message: 'Could not read file metadata: $error',
          filePath: path,
        ),
      );
      return null;
    }
  }

  Future<ParsedMarkdownDocument?> _parseMarkdownFileIfSafe(
    File file,
    String workspaceRoot,
    List<Diagnostic> diagnostics,
    int parsedDocuments,
  ) async {
    if (parsedDocuments >= scanOptions.maxParsedDocuments) {
      diagnostics.add(
        Diagnostic(
          code: 'workspace.scan.document-limit',
          severity: DiagnosticSeverity.warning,
          message:
              'Large workspace detected. Some files were skipped to keep the app responsive.',
          filePath: file.path,
        ),
      );
      return null;
    }
    final stat = await file.stat();
    if (stat.size > scanOptions.maxParsedFileBytes) {
      diagnostics.add(
        Diagnostic(
          code: 'workspace.file.too-large',
          severity: DiagnosticSeverity.warning,
          message: 'File is larger than the beta auto-parse limit.',
          filePath: file.path,
        ),
      );
      return null;
    }
    try {
      return markdownParser.parse(
        filePath: file.path,
        source: await file.readAsString(),
        workspaceRoot: workspaceRoot,
      );
    } on Object catch (error) {
      diagnostics.add(
        Diagnostic(
          code: 'workspace.file.read-failed',
          severity: DiagnosticSeverity.warning,
          message: 'Could not read Markdown file: $error',
          filePath: file.path,
        ),
      );
      return null;
    }
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

  List<PreviewBlock> _xmlPreviewBlocks(String source, String? title) {
    final names = RegExp(
      r'<\s*([A-Za-z][A-Za-z0-9_-]*)\b',
    ).allMatches(source).map((match) => match.group(1)!).toList();
    if (names.isEmpty) {
      return [PreviewBlock(kind: PreviewBlockKind.code, text: source)];
    }
    return [
      for (final name in names)
        if (_visibleSemanticElement(name))
          PreviewBlock(
            kind: _semanticKind(name),
            text: _semanticText(name, title),
            attributes: {'element': name},
          ),
    ];
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
