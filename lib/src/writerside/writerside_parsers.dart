import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import '../core/diagnostic.dart';
import '../core/path_utils.dart';
import '../core/source_span.dart';
import '../markdown/markdown_model.dart';
import '../markdown/markdown_parser.dart';
import 'writerside_model.dart';

class WritersideConfigParser {
  const WritersideConfigParser();

  WritersideConfig parse(String filePath, String source) {
    final diagnostics = <Diagnostic>[];
    XmlDocument? document;
    try {
      document = XmlDocument.parse(source);
    } on Object catch (error) {
      diagnostics.add(
        _xmlError('writerside.config.invalid-xml', filePath, source, error),
      );
    }
    if (document == null) {
      return _emptyConfig(filePath, diagnostics);
    }
    final root = document.rootElement;
    if (root.name.local != 'ihp') {
      diagnostics.add(
        Diagnostic(
          code: 'writerside.config.invalid-root',
          severity: DiagnosticSeverity.error,
          filePath: filePath,
          sourceSpan: _elementSpan(filePath, source, root.name.local),
        ),
      );
    }
    final instances = <WritersideConfiguredInstance>[];
    String? moduleName;
    final topicRoots = <WritersideTopicRoot>[];
    final imageRoots = <WritersideImageRoot>[];
    String? snippetsDir;
    String? resourcesFile;
    String? resourcesDir;
    var apiSpecificationsDir = 'specifications';
    var apiSpecificationsExplicit = false;
    var buildConfigDir = 'cfg';
    var buildConfigExplicit = false;
    String? varsFile;
    String? categoriesFile;
    String? instanceGroupsFile;
    var settings = const WritersideSettingsConfig();
    for (final child in root.childElements) {
      switch (child.name.local) {
        case 'module':
          moduleName = child.getAttribute('name');
        case 'topics':
          topicRoots.add(
            WritersideTopicRoot(
              dir: child.getAttribute('dir') ?? 'topics',
              explicit: true,
            ),
          );
        case 'images':
          imageRoots.add(
            WritersideImageRoot(
              dir: child.getAttribute('dir') ?? 'images',
              version: child.getAttribute('version'),
              webPath: child.getAttribute('web-path'),
              explicit: true,
            ),
          );
        case 'snippets':
          snippetsDir = child.getAttribute('src') ?? child.getAttribute('dir');
          if (snippetsDir == null || snippetsDir.isEmpty) {
            diagnostics.add(
              Diagnostic(
                code: 'writerside.config.missing-snippets-src',
                severity: DiagnosticSeverity.warning,
                filePath: filePath,
                sourceSpan: _elementSpan(filePath, source, 'snippets'),
              ),
            );
            snippetsDir = null;
          }
        case 'resources':
          resourcesFile = child.getAttribute('src');
          resourcesDir = child.getAttribute('dir');
        case 'api-specifications':
          apiSpecificationsDir = child.getAttribute('dir') ?? 'specifications';
          apiSpecificationsExplicit = true;
        case 'build-config':
          buildConfigDir = child.getAttribute('dir') ?? 'cfg';
          buildConfigExplicit = true;
        case 'vars':
          varsFile = child.getAttribute('src') ?? 'v.list';
        case 'categories':
          categoriesFile = child.getAttribute('src') ?? 'c.list';
        case 'instance-groups':
          instanceGroupsFile = child.getAttribute('src');
          if (instanceGroupsFile == null || instanceGroupsFile.isEmpty) {
            diagnostics.add(
              Diagnostic(
                code: 'writerside.config.missing-instance-groups-src',
                severity: DiagnosticSeverity.warning,
                filePath: filePath,
                sourceSpan: _elementSpan(filePath, source, 'instance-groups'),
              ),
            );
            instanceGroupsFile = null;
          }
        case 'instance':
          final instanceSource = child.getAttribute('src');
          if (instanceSource != null && instanceSource.isNotEmpty) {
            final keymapsMode = child.getAttribute('keymaps-mode');
            if (keymapsMode != null &&
                !{'none', 'generated', 'provided'}.contains(keymapsMode)) {
              diagnostics.add(
                Diagnostic(
                  code: 'writerside.config.invalid-keymaps-mode',
                  severity: DiagnosticSeverity.warning,
                  filePath: filePath,
                  args: {'mode': keymapsMode},
                  sourceSpan: _elementSpan(
                    filePath,
                    source,
                    'instance',
                    keymapsMode,
                  ),
                ),
              );
            }
            instances.add(
              WritersideConfiguredInstance(
                src: instanceSource,
                version: child.getAttribute('version'),
                webPath: child.getAttribute('web-path'),
                keymapsMode: keymapsMode,
              ),
            );
          } else {
            diagnostics.add(
              Diagnostic(
                code: 'writerside.config.missing-instance-src',
                severity: DiagnosticSeverity.error,
                filePath: filePath,
                sourceSpan: _elementSpan(filePath, source, 'instance'),
              ),
            );
          }
        case 'settings':
          settings = _settingsConfig(filePath, source, child);
      }
    }
    if (topicRoots.isEmpty) {
      topicRoots.add(const WritersideTopicRoot(dir: 'topics', explicit: false));
    }
    if (imageRoots.isEmpty) {
      imageRoots.add(const WritersideImageRoot(dir: 'images', explicit: false));
    }
    if (instances.isEmpty) {
      diagnostics.add(
        Diagnostic(
          code: 'writerside.config.missing-instance',
          severity: DiagnosticSeverity.error,
          filePath: filePath,
          sourceSpan: SourceSpan.entireFile(filePath, source),
        ),
      );
    }
    return WritersideConfig(
      filePath: filePath,
      version: root.getAttribute('version'),
      moduleName: moduleName,
      topicRoots: topicRoots,
      imageRoots: imageRoots,
      apiSpecificationsDir: apiSpecificationsDir,
      apiSpecificationsExplicit: apiSpecificationsExplicit,
      buildConfigDir: buildConfigDir,
      buildConfigExplicit: buildConfigExplicit,
      snippetsDir: snippetsDir,
      resourcesFile: resourcesFile,
      resourcesDir: resourcesDir,
      varsFile: varsFile,
      categoriesFile: categoriesFile,
      instanceGroupsFile: instanceGroupsFile,
      instances: instances,
      settings: settings,
      diagnostics: diagnostics,
    );
  }

  WritersideConfig _emptyConfig(String filePath, List<Diagnostic> diagnostics) {
    return WritersideConfig(
      filePath: filePath,
      version: null,
      moduleName: null,
      topicRoots: const [WritersideTopicRoot(dir: 'topics', explicit: false)],
      imageRoots: const [WritersideImageRoot(dir: 'images', explicit: false)],
      apiSpecificationsDir: 'specifications',
      apiSpecificationsExplicit: false,
      buildConfigDir: 'cfg',
      buildConfigExplicit: false,
      snippetsDir: null,
      resourcesFile: null,
      resourcesDir: null,
      varsFile: null,
      categoriesFile: null,
      instanceGroupsFile: null,
      instances: const [],
      settings: const WritersideSettingsConfig(),
      diagnostics: diagnostics,
    );
  }

  WritersideSettingsConfig _settingsConfig(
    String filePath,
    String source,
    XmlElement settings,
  ) {
    final capsRules = <WritersideCapsRule>[];
    final defaultProperties = <WritersideDefaultProperty>[];
    bool? disableWebNamePreprocessing;
    bool? smartIgnoreVars;
    String? wrsSupernovaUseVersion;
    for (final child in settings.childElements) {
      switch (child.name.local) {
        case 'caps':
          capsRules.add(
            WritersideCapsRule(
              style: child.getAttribute('style'),
              target: child.getAttribute('for'),
            ),
          );
        case 'default-property':
          defaultProperties.add(
            WritersideDefaultProperty(
              elementName: child.getAttribute('element-name'),
              propertyName: child.getAttribute('property-name'),
              value: child.getAttribute('value'),
            ),
          );
        case 'disable-web-name-preprocessing':
          disableWebNamePreprocessing = child.innerText.trim() == 'true';
        case 'smart-ignore-vars':
          smartIgnoreVars = child.innerText.trim() == 'true';
        case 'wrs-supernova':
          wrsSupernovaUseVersion = child.getAttribute('use-version');
      }
    }
    return WritersideSettingsConfig(
      capsRules: capsRules,
      defaultProperties: defaultProperties,
      disableWebNamePreprocessing: disableWebNamePreprocessing,
      smartIgnoreVars: smartIgnoreVars,
      wrsSupernovaUseVersion: wrsSupernovaUseVersion,
    );
  }
}

class WritersideTreeParser {
  const WritersideTreeParser();

  WritersideInstance parse(String filePath, String source) {
    final diagnostics = <Diagnostic>[];
    XmlDocument? document;
    try {
      document = XmlDocument.parse(source);
    } on Object catch (error) {
      diagnostics.add(
        _xmlError('writerside.tree.invalid-xml', filePath, source, error),
      );
    }
    if (document == null) {
      return WritersideInstance(
        id: p.basenameWithoutExtension(filePath),
        name: p.basenameWithoutExtension(filePath),
        sourceTreePath: filePath,
        startPage: null,
        status: 'unknown',
        isLibrary: false,
        tocRoots: const [],
        diagnostics: diagnostics,
      );
    }
    final root = document.rootElement;
    if (root.name.local != 'instance-profile') {
      diagnostics.add(
        Diagnostic(
          code: 'writerside.tree.invalid-root',
          severity: DiagnosticSeverity.error,
          filePath: filePath,
          sourceSpan: _elementSpan(filePath, source, root.name.local),
        ),
      );
    }
    final id = root.getAttribute('id') ?? '';
    final name = root.getAttribute('name') ?? id;
    final startPage = root.getAttribute('start-page');
    if (id.isEmpty) {
      diagnostics.add(
        Diagnostic(
          code: 'writerside.tree.missing-id',
          severity: DiagnosticSeverity.error,
          filePath: filePath,
          sourceSpan: _elementSpan(filePath, source, root.name.local),
        ),
      );
    } else if (id != p.basenameWithoutExtension(filePath)) {
      diagnostics.add(
        Diagnostic(
          code: 'writerside.tree.id-mismatch',
          severity: DiagnosticSeverity.warning,
          filePath: filePath,
          args: {'id': id},
          sourceSpan: _elementSpan(filePath, source, root.name.local),
        ),
      );
    }
    if (startPage == null && root.getAttribute('is-library') != 'true') {
      diagnostics.add(
        Diagnostic(
          code: 'writerside.tree.missing-start-page',
          severity: DiagnosticSeverity.error,
          filePath: filePath,
          sourceSpan: _elementSpan(filePath, source, root.name.local),
        ),
      );
    }
    final tocRoots = root.childElements
        .where((element) => element.name.local == 'toc-element')
        .map((element) => _tocNode(filePath, source, element))
        .toList();
    final seen = <String, SourceSpan>{};
    for (final node in tocRoots.expand((node) => node.flatten())) {
      final topic = node.topicFileName;
      if (topic == null) {
        continue;
      }
      if (seen.containsKey(topic)) {
        diagnostics.add(
          Diagnostic(
            code: 'writerside.tree.duplicate-topic',
            severity: DiagnosticSeverity.error,
            filePath: filePath,
            args: {'topic': topic},
            sourceSpan: node.span,
            relatedSpans: [seen[topic]!],
          ),
        );
      } else {
        seen[topic] = node.span;
      }
    }
    return WritersideInstance(
      id: id.isEmpty ? p.basenameWithoutExtension(filePath) : id,
      name: name.isEmpty ? id : name,
      sourceTreePath: filePath,
      startPage: startPage,
      status: root.getAttribute('status') ?? 'release',
      isLibrary: root.getAttribute('is-library') == 'true',
      tocRoots: tocRoots,
      diagnostics: diagnostics,
    );
  }

  TocNode _tocNode(String filePath, String source, XmlElement element) {
    return TocNode(
      topicFileName: element.getAttribute('topic'),
      href: element.getAttribute('href'),
      tocTitle: element.getAttribute('toc-title'),
      id: element.getAttribute('id'),
      hidden: element.getAttribute('hidden') == 'true',
      span: _elementSpan(
        filePath,
        source,
        'toc-element',
        element.getAttribute('topic'),
      ),
      children: element.childElements
          .where((child) => child.name.local == 'toc-element')
          .map((child) => _tocNode(filePath, source, child))
          .toList(),
    );
  }
}

class WritersideVariablesParser {
  const WritersideVariablesParser();

  (List<WritersideVariable>, List<Diagnostic>) parse(
    String filePath,
    String source,
  ) {
    final diagnostics = <Diagnostic>[];
    final variables = <WritersideVariable>[];
    XmlDocument? document;
    try {
      document = XmlDocument.parse(source);
    } on Object catch (error) {
      diagnostics.add(
        _xmlError('writerside.variables.invalid-xml', filePath, source, error),
      );
    }
    if (document == null) {
      return (variables, diagnostics);
    }
    final seen = <String, SourceSpan>{};
    for (final element in document.findAllElements('var')) {
      final name = element.getAttribute('name');
      final value = element.getAttribute('value');
      final span = _elementSpan(filePath, source, 'var', name);
      if (name == null || value == null) {
        diagnostics.add(
          Diagnostic(
            code: 'writerside.variable.malformed-declaration',
            severity: DiagnosticSeverity.warning,
            filePath: filePath,
            sourceSpan: span,
          ),
        );
        continue;
      }
      if (seen.containsKey(name)) {
        diagnostics.add(
          Diagnostic(
            code: 'writerside.variable.duplicate-name',
            severity: DiagnosticSeverity.warning,
            filePath: filePath,
            args: {'name': name},
            sourceSpan: span,
            relatedSpans: [seen[name]!],
          ),
        );
      }
      seen[name] = span;
      variables.add(WritersideVariable(name: name, value: value, span: span));
    }
    return (variables, diagnostics);
  }
}

class WritersideCategoriesParser {
  const WritersideCategoriesParser();

  (List<WritersideCategory>, List<Diagnostic>) parse(
    String filePath,
    String source,
  ) {
    final diagnostics = <Diagnostic>[];
    final categories = <WritersideCategory>[];
    XmlDocument? document;
    try {
      document = XmlDocument.parse(source);
    } on Object catch (error) {
      diagnostics.add(
        _xmlError('writerside.categories.invalid-xml', filePath, source, error),
      );
    }
    if (document == null) {
      return (categories, diagnostics);
    }
    final ids = <String, SourceSpan>{};
    final orders = <int, SourceSpan>{};
    for (final element in document.findAllElements('category')) {
      final id = element.getAttribute('id') ?? '';
      final order = int.tryParse(element.getAttribute('order') ?? '');
      final span = _elementSpan(filePath, source, 'category', id);
      if (id.isEmpty) {
        diagnostics.add(
          Diagnostic(
            code: 'writerside.category.missing-id',
            severity: DiagnosticSeverity.error,
            filePath: filePath,
            sourceSpan: span,
          ),
        );
        continue;
      }
      if (ids.containsKey(id)) {
        diagnostics.add(
          Diagnostic(
            code: 'writerside.category.duplicate-id',
            severity: DiagnosticSeverity.error,
            filePath: filePath,
            args: {'id': id},
            sourceSpan: span,
            relatedSpans: [ids[id]!],
          ),
        );
      }
      if (order != null && orders.containsKey(order)) {
        diagnostics.add(
          Diagnostic(
            code: 'writerside.category.duplicate-order',
            severity: DiagnosticSeverity.warning,
            filePath: filePath,
            args: {'order': '$order'},
            sourceSpan: span,
            relatedSpans: [orders[order]!],
          ),
        );
      }
      ids[id] = span;
      if (order != null) {
        orders[order] = span;
      }
      categories.add(
        WritersideCategory(
          id: id,
          name:
              element.getAttribute('name') ??
              element.getAttribute('title') ??
              id,
          order: order,
          span: span,
        ),
      );
    }
    return (categories, diagnostics);
  }
}

class WritersideTopicParser {
  const WritersideTopicParser({this.markdownParser = const MarkdownParser()});

  final MarkdownParser markdownParser;

  WritersideTopic parseMarkdown({
    required String filePath,
    required String source,
    required String topicsRoot,
  }) {
    final parsed = markdownParser.parse(
      filePath: filePath,
      source: source,
      mode: MarkdownMode.writersideMarkdown,
      workspaceRoot: topicsRoot,
      validateLocalReferences: false,
    );
    final ids = parsed.headings
        .map(
          (heading) => WritersideElementId(id: heading.id, span: heading.span),
        )
        .toList();
    final includes = _includeRegex
        .allMatches(source)
        .map(
          (match) => WritersideInclude(
            from: match.namedGroup('from'),
            elementId: match.namedGroup('id'),
            nullable: match.group(0)!.contains('nullable="true"'),
            span: SourceSpan.fromOffsets(
              filePath: filePath,
              source: source,
              startOffset: match.start,
              endOffset: match.end,
            ),
          ),
        )
        .toList();
    final titleOverrides = _topicTitleOverrides(source);
    return WritersideTopic(
      id: p.basenameWithoutExtension(filePath),
      filePath: filePath,
      fileName: normalizedRelative(topicsRoot, filePath),
      topicRoot: topicsRoot,
      format: WritersideTopicFormat.markdown,
      title: parsed.title,
      elementIds: ids,
      links: parsed.links,
      images: parsed.images,
      variables: parsed.variables,
      includes: includes,
      diagnostics: _writersideMarkdownDiagnostics(parsed.diagnostics),
      webFileName: _webFileName(source),
      markdown: parsed,
      titleOverrides: titleOverrides,
      semanticElementNames: parsed.xmlBlocks
          .map((block) => block.elementName)
          .toList(),
    );
  }

  WritersideTopic parseXml({
    required String filePath,
    required String source,
    String? topicsRoot,
  }) {
    final diagnostics = <Diagnostic>[];
    final ids = <WritersideElementId>[];
    final links = <MarkdownLink>[];
    final images = <MarkdownImage>[];
    final variables = <MarkdownVariableToken>[];
    final includes = <WritersideInclude>[];
    final titleOverrides = <WritersideTopicTitleOverride>[];
    final semanticNames = <String>[];
    String? webFileName;
    XmlDocument? document;
    try {
      document = XmlDocument.parse(source);
    } on Object catch (error) {
      diagnostics.add(
        _xmlError('writerside.topic.invalid-xml', filePath, source, error),
      );
    }
    String? title;
    final expectedId = p.basenameWithoutExtension(filePath);
    var id = expectedId;
    if (document != null) {
      final root = document.rootElement;
      if (root.name.local != 'topic') {
        diagnostics.add(
          Diagnostic(
            code: 'writerside.topic.invalid-root',
            severity: DiagnosticSeverity.error,
            filePath: filePath,
            sourceSpan: _elementSpan(filePath, source, root.name.local),
          ),
        );
      }
      id = root.getAttribute('id') ?? '';
      title = root.getAttribute('title');
      if (id.isEmpty) {
        diagnostics.add(
          Diagnostic(
            code: 'writerside.topic.missing-root-id',
            severity: DiagnosticSeverity.error,
            filePath: filePath,
            sourceSpan: _elementSpan(filePath, source, root.name.local),
          ),
        );
        id = expectedId;
      } else if (id != expectedId) {
        diagnostics.add(
          Diagnostic(
            code: 'writerside.topic.root-id-mismatch',
            severity: DiagnosticSeverity.error,
            filePath: filePath,
            args: {'id': id, 'expectedId': expectedId},
            sourceSpan: _elementSpan(filePath, source, root.name.local, id),
          ),
        );
      }
      if (title == null || title.trim().isEmpty) {
        diagnostics.add(
          Diagnostic(
            code: 'writerside.topic.missing-title',
            severity: DiagnosticSeverity.warning,
            filePath: filePath,
            sourceSpan: _elementSpan(filePath, source, root.name.local),
          ),
        );
      }
      final seenIds = <String, SourceSpan>{};
      for (final element in document.descendants.whereType<XmlElement>()) {
        semanticNames.add(element.name.local);
        final elementId = element.getAttribute('id');
        if (elementId != null) {
          final span = _elementSpan(
            filePath,
            source,
            element.name.local,
            elementId,
          );
          ids.add(WritersideElementId(id: elementId, span: span));
          if (seenIds.containsKey(elementId)) {
            diagnostics.add(
              Diagnostic(
                code: 'writerside.topic.duplicate-element-id',
                severity: DiagnosticSeverity.error,
                filePath: filePath,
                args: {'elementId': elementId},
                sourceSpan: span,
                relatedSpans: [seenIds[elementId]!],
              ),
            );
          }
          seenIds[elementId] = span;
        }
        switch (element.name.local) {
          case 'title':
            final instance = element.getAttribute('instance');
            if (instance != null && instance.isNotEmpty) {
              titleOverrides.add(
                WritersideTopicTitleOverride(
                  instance: instance,
                  title: element.innerText.trim(),
                ),
              );
            }
          case 'web-file-name':
            webFileName = element.innerText.trim();
          case 'a':
            final href = element.getAttribute('href');
            if (href == null) {
              diagnostics.add(
                Diagnostic(
                  code: 'writerside.topic.missing-required-attribute',
                  severity: DiagnosticSeverity.warning,
                  filePath: filePath,
                  sourceSpan: _elementSpan(filePath, source, 'a'),
                ),
              );
            } else {
              links.add(
                MarkdownLink(
                  text: element.innerText.trim(),
                  destination: href,
                  span: _elementSpan(filePath, source, 'a', href),
                ),
              );
            }
          case 'img':
            final src = element.getAttribute('src') ?? '';
            images.add(
              MarkdownImage(
                alt: element.getAttribute('alt') ?? '',
                destination: src,
                span: _elementSpan(filePath, source, 'img', src),
              ),
            );
          case 'include':
            includes.add(
              WritersideInclude(
                from: element.getAttribute('from'),
                elementId: element.getAttribute('element-id'),
                nullable: element.getAttribute('nullable') == 'true',
                span: _elementSpan(
                  filePath,
                  source,
                  'include',
                  element.getAttribute('from'),
                ),
              ),
            );
        }
      }
    }
    for (final match in RegExp(
      r'(?<!\\)%([A-Za-z_][A-Za-z0-9_.-]*)%',
    ).allMatches(source)) {
      variables.add(
        MarkdownVariableToken(
          name: match.group(1)!,
          escaped: false,
          span: SourceSpan.fromOffsets(
            filePath: filePath,
            source: source,
            startOffset: match.start,
            endOffset: match.end,
          ),
        ),
      );
    }
    return WritersideTopic(
      id: id,
      filePath: filePath,
      fileName: topicsRoot == null
          ? p.basename(filePath)
          : normalizedRelative(topicsRoot, filePath),
      topicRoot: topicsRoot ?? p.dirname(filePath),
      format: WritersideTopicFormat.xml,
      title: title,
      elementIds: ids,
      links: links,
      images: images,
      variables: variables,
      includes: includes,
      diagnostics: sortDiagnostics(diagnostics),
      webFileName: webFileName,
      titleOverrides: titleOverrides,
      semanticElementNames: semanticNames,
    );
  }
}

final _includeRegex = RegExp(
  r'<include\b(?=[^>]*\bfrom="(?<from>[^"]+)")(?=[^>]*\belement-id="(?<id>[^"]+)")[^>]*/?>',
);

List<Diagnostic> _writersideMarkdownDiagnostics(List<Diagnostic> diagnostics) {
  return [
    for (final diagnostic in diagnostics)
      if (diagnostic.code != 'markdown.image.missing-file') diagnostic,
  ];
}

List<WritersideTopicTitleOverride> _topicTitleOverrides(String source) {
  return [
    for (final match in RegExp(
      r'<title\b(?=[^>]*\binstance="([^"]+)")[^>]*>(.*?)</title>',
      dotAll: true,
    ).allMatches(source))
      WritersideTopicTitleOverride(
        instance: match.group(1)!.trim(),
        title: match.group(2)!.trim(),
      ),
  ];
}

String? _webFileName(String source) {
  final match = RegExp(
    r'<web-file-name>\s*(.*?)\s*</web-file-name>',
    dotAll: true,
  ).firstMatch(source);
  final value = match?.group(1)?.trim();
  return value == null || value.isEmpty ? null : value;
}

Diagnostic _xmlError(
  String code,
  String filePath,
  String source,
  Object error,
) {
  final message = error.toString();
  final lineMatch = RegExp(r'at\s+(\d+):(\d+)').firstMatch(message);
  SourceSpan span;
  if (lineMatch != null) {
    final line = int.parse(lineMatch.group(1)!);
    final column = int.parse(lineMatch.group(2)!);
    var offset = 0;
    final lines = source.split('\n');
    for (var i = 0; i < line - 1 && i < lines.length; i++) {
      offset += lines[i].length + 1;
    }
    offset += column - 1;
    span = SourceSpan.fromOffsets(
      filePath: filePath,
      source: source,
      startOffset: offset,
      endOffset: offset + 1,
    );
  } else {
    span = SourceSpan.entireFile(filePath, source);
  }
  return Diagnostic(
    code: code,
    severity: DiagnosticSeverity.error,
    filePath: filePath,
    args: {'message': message},
    sourceSpan: span,
  );
}

SourceSpan _elementSpan(
  String filePath,
  String source,
  String elementName, [
  String? marker,
]) {
  var index = -1;
  if (marker != null && marker.isNotEmpty) {
    index = source.indexOf(marker);
  }
  index = index == -1 ? source.indexOf('<$elementName') : index;
  if (index == -1) {
    index = 0;
  }
  return SourceSpan.fromOffsets(
    filePath: filePath,
    source: source,
    startOffset: index,
    endOffset: (index + elementName.length + 2).clamp(0, source.length),
  );
}
